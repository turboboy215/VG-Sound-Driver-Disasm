; ==========================================================================
; Cyborg Kuro-chan - Devil Fukkatsu (J) - Konami sound driver (ROM0, banks $0C-$0F)
; Byte-exact RGBDS disassembly of the driver code and all sound data. World Soccer GB2's driver
; moved to bank $0C with the track pages in CGB WRAM bank 7, instrument macros ($EA 11 n), a
; speed-up tempo ($EE $80|n), a second drum set ($EA Fx); no PCM, no pitch drift.
;   ROM0: the sound code ($1FD6-$2531), every entry point mapping WRAM bank 7 (SVBK) first
;   bank $0C: table sets, SoundTable, headers, the drum set 1 table and headers ($4000-$4789),
;             the track code ($478A-$5606), tables ($5607-$62AC), SFX and songs ($62AD-$7E84)
;   banks $0D-$0F: songs (stream bank = $0C + the priority byte's high nibble)
; Build: rgbasm -Wall -o kuro.o KURO_SoundDriver.asm && rgblink -o kuro.gbc kuro.o
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
DEF rSVBK EQU $FF70

; ---------------------------------------------------------------- RAM
DEF wRomBank EQU $C005
DEF wWramBank EQU $C006
DEF wSndBusy EQU $C012
DEF wTrkSfx1 EQU $D000 ; 104 bytes
DEF wTrkSfx2 EQU $D100 ; 104 bytes
DEF wTrkSfxN EQU $D200 ; 104 bytes
DEF wTrkCh1 EQU $D300 ; 104 bytes
DEF wTrkCh2 EQU $D400 ; 104 bytes
DEF wTrkCh3 EQU $D500 ; 104 bytes
DEF wTrkDrm EQU $D600 ; 104 bytes
DEF wTrackDesc EQU $D702
DEF wTempo EQU $D706
DEF wTempoAcc EQU $D707
DEF wReqPrio EQU $D708
DEF wReqId EQU $D709
DEF wFadeDir EQU $D70A
DEF wFadeRate EQU $D70B
DEF wFadeTimer EQU $D70C
DEF wFadeStep EQU $D70D
DEF wWaveId EQU $D70F
DEF wD710 EQU $D710
DEF wReadBuf EQU $D712 ; 4 bytes
DEF wWobbleMin EQU $D716
DEF wWobbleOn EQU $D717
DEF wWobbleRate EQU $D718
DEF wWobbleTimer EQU $D719
DEF wSndDim EQU $D71A
DEF wReqHold EQU $D71B
DEF wHeldReq EQU $D71C
DEF wPauseFlag EQU $D71D
DEF wPauseMuted EQU $D71E
DEF wNoiseAtten EQU $D71F
DEF wNR51Copy EQU $D723
DEF wGameBank EQU $D725
DEF wMusicId EQU $D726
DEF wTableSet EQU $D727
DEF wDrumSet EQU $D728
DEF wGameWramBank EQU $D729
DEF wSpeedRate EQU $D72B
DEF wSpeedTimer EQU $D72C
DEF wSndVars2 EQU $D780 ; 81 bytes
DEF rROMB EQU $2000

; per-track fields: track n lives at $D000 + n*$100 (CGB WRAM, see the header), so H = $D0 + n and
; L = field
DEF TRK_PRIO EQU $00
DEF TRK_ID EQU $01
DEF TRK_PTR EQU $02
DEF TRK_LEN EQU $04
DEF TRK_FLAGS EQU $05
DEF TRK_PANFLAGS EQU $06
DEF TRK_FLOW EQU $07
DEF TRK_A8 EQU $08
DEF TRK_LOOPPTR EQU $09
DEF TRK_LOOPCNT EQU $0B
DEF TRK_LOOP2PTR EQU $0C
DEF TRK_LOOP2CNT EQU $0E
DEF TRK_SEGNO EQU $0F
DEF TRK_RET EQU $11
DEF TRK_UNIT EQU $13
DEF TRK_ATTEN EQU $14
DEF TRK_PERIOD EQU $15
DEF TRK_OUTPERIOD EQU $17
DEF TRK_VOL EQU $19
DEF TRK_LASTVOL EQU $1A
DEF TRK_REG_NRX1 EQU $1B
DEF TRK_REG_NRX2 EQU $1C
DEF TRK_REG_NRX3 EQU $1D
DEF TRK_REG_NRX4 EQU $1E
DEF TRK_GATE EQU $1F
DEF TRK_RELTICK EQU $20
DEF TRK_ENV EQU $21
DEF TRK_C2 EQU $22
DEF TRK_PAN EQU $23
DEF TRK_VIB EQU $24
DEF TRK_ENVNO EQU $25
DEF TRK_DETUNE EQU $26
DEF TRK_TRANSP EQU $28
DEF TRK_DUTYCNT EQU $29
DEF TRK_DUTYTICKS EQU $2A
DEF TRK_DUTYSTART EQU $2B
DEF TRK_OCTAVE EQU $2C
DEF TRK_DUTY EQU $2D
DEF TRK_CURDUTY EQU $2E
DEF TRK_VIBPTR EQU $2F
DEF TRK_ENVPTR EQU $3D
DEF TRK_ENVPOS EQU $3F
DEF TRK_ENVTIMER EQU $41
DEF TRK_ENVLOOPPTR EQU $42
DEF TRK_ENVLOOPCNT EQU $44
DEF TRK_ENVMARK EQU $45
DEF TRK_RELVOL EQU $47
DEF TRK_SAVEPERIOD EQU $48
DEF TRK_BREAK EQU $4A
DEF TRK_EXIT EQU $4B
DEF TRK_BREAK2 EQU $4D
DEF TRK_EXIT2 EQU $4E
DEF TRK_PITCHIDX EQU $50
DEF TRK_SLIDEPTR EQU $51
DEF TRK_SLIDECNT EQU $53
DEF TRK_F4 EQU $54
DEF TRK_SLIDEATTCNT EQU $55
DEF TRK_SLIDEOFS EQU $56
DEF TRK_MUTE EQU $5F
DEF TRK_INSTR EQU $58
DEF TRK_INSFLAGS EQU $59
DEF TRK_INSTIMER EQU $5A
DEF TRK_INSPTR EQU $5B
DEF TRK_INSMARK EQU $63
DEF TRK_INS65 EQU $65
DEF TRK_INSOFS EQU $66

; TRK_PRIO: low nibble = priority, high nibble = bank of the streams - $0C
; TRK_FLAGS: 1 note-volume mode, 2/5 channel given back, 4 tempo skip, 6/7 noise volume pending
; TRK_PANFLAGS: 0 autopan, 1 autopan side, 3 envelope running, 5 note-volume slide, 6 autopan both,
;   7 set by $EA Cx
; TRK_FLOW: 0 loop 1, 1 loop 2, 2 in a call, 3 mark set, 6 envelope loop, 7 envelope mark
; TRK_INSTR: instrument macro number (0 = none); TRK_INSFLAGS: 0 running ($01), 3 mark set;
;   TRK_INSOFS: the signed period offset of the current step

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

; sound header: priority, track mask (Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm), one dw per set bit
MACRO SND_HEADER
	db \1, \2
ENDM
; note: hi = pitch 1-13 (0 = rest), lo = length multiplier (x unit; 0 = (unit & 15) x 16)
MACRO NOTE
	db (\1 << 4) | \2
ENDM
MACRO REST
	db \1
ENDM
; drum track: hi = bank-14 drum hit id 1-12, lo = length multiplier
MACRO DRUM
	db (\1 << 4) | \2
ENDM
; drum track $Dx n: start bank-14 sound n (any id), x = length multiplier
MACRO DRUM_SND
	db $D0 | \2, \1
ENDM
MACRO VDRUM_SND
	db $D0 | \2, \1
ENDM
; note-volume mode (after VVOICE): hi = pitch, lo = volume; every note lasts one unit
MACRO VNOTE
	db (\1 << 4) | \2
ENDM
MACRO VREST
	db \1
ENDM
MACRO VDRUM
	db (\1 << 4) | \2
ENDM
; SfxN: NR43 value, one unit
MACRO NOISE
	db \1
ENDM
; SfxN $C0-$CF: volume nibble (no time); $D0 a muted unit; $D1-$DF volume nibble and a unit
MACRO NOISE_VOL
	db $C0 | \1
ENDM
MACRO NOISE_REST
	db $D0
ENDM
MACRO NOISE_VOLNOTE
	db $D0 | \1
ENDM
; $E0 unit, duty<<4|vol, gate<<4|env (CH3: duty = wave); leaves note-volume mode
MACRO VOICE
	db $E0, \1, (\2 << 4) | \3, (\4 << 4) | \5
ENDM
; $E0 unit, duty<<4|0, n: volume 0, so the last byte is volume envelope n
MACRO VOICE_ENV
	db $E0, \1, \2 << 4, \3
ENDM
; $E0 unit | $80, duty byte, x (NR10 on CH1, ignored otherwise): note-volume mode
MACRO VVOICE
	db $E0, \1 | $80, \2, \3
ENDM
; SfxN: $E0 unit (bit 7: NR42 at once), NR42 value
MACRO NVOICE
	db $E0, \1, \2
ENDM
MACRO OCTAVE
	db $E0 | \1
ENDM
MACRO LEN_UNIT
	db $E7, \1
ENDM
; $E8 xy: gate x, env y (release volume 0, envelope off)
MACRO RELEASE
	db $E8, (\1 << 4) | \2
ENDM
; $E9 x: NR10 = x
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
; $EA 0F n: duty / wave n (any value; $EA 0x only reaches 0-14)
MACRO DUTY_X
	db $EA, $0F, \1
ENDM
MACRO WAVE_X
	db $EA, $0F, \1
ENDM
MACRO PAN_BOTH
	db $EA, $10 | \1
ENDM
MACRO PAN_LEFT
	db $EA, $20 | \1
ENDM
MACRO PAN_RIGHT
	db $EA, $30 | \1
ENDM
MACRO AUTOPAN
	db $EA, $40 | \1
ENDM
MACRO AUTOPAN_BOTH
	db $EA, $50 | \1
ENDM
MACRO PAN_BOTH2
	db $EA, $60 | \1
ENDM
MACRO TRANSPOSE_UP
	db $EA, $70 | \1
ENDM
MACRO TRANSPOSE_DOWN
	db $EA, $80 | \1
ENDM
MACRO RELEASE_VOL
	db $EA, $90 | \1
ENDM
; $EA Ax y: NR50 wobble (y = 0: off)
MACRO WOBBLE
	db $EA, $A0 | \1, \2
ENDM
; $EA 10: pan both (Kuro-chan / The Mummy: only with x = 0); $EA 11 n: instrument macro n
MACRO INSTRUMENT
	db $EA, $11, \1
ENDM
; $EA Dx: wNoiseAtten = x (off the noise volume of SfxN sounds whose priority nibble is 2)
MACRO NOISE_ATTEN
	db $EA, $D0 | \1
ENDM
; $EA Fx: wDrumSet = x & 3 (table set of the drum hits: 0 SoundTable, 1 DrumSet1Table)
MACRO DRUM_SET
	db $EA, $F0 | \1
ENDM
; vibrato table step $Fx d: x ticks, offset = signed d x depth
MACRO VIB_STEP2
	db $F0 | \1, \2
ENDM
; instrument macro steps: ticks, wave byte (swapped: the duty / CH3 wave), signed period offset;
; $FE marks (first time) / jumps back to the mark; $FF ends
MACRO INS_STEP
	db \1, \2, \3
ENDM
MACRO INS_MARK
	db $FE
ENDM
MACRO INS_END
	db $FF
ENDM
; $EA Bx / $EA Ex: wReqHold |= $Bx / &= $Ex (the whole byte is the mask; bit 0 drops requests, bit 3 runs
; the game-driven tone on CH1 instead of Sfx1)
MACRO HOLD_SET
	db $EA, \1
ENDM
MACRO HOLD_CLR
	db $EA, \1
ENDM
; $EA Cx: TRK_PANFLAGS bit 7 = (x != 0)
MACRO FLAG7
	db $EA, $C0 | \1
ENDM
; $EB n xy: vibrato table n, delay x * unit, depth y; $EB n | $80: semitone table n; $EB 0 off
MACRO VIBRATO
	db $EB, \1, (\2 << 4) | \3
ENDM
MACRO VIBRATO_SEMI
	db $EB, $80 | \1
ENDM
MACRO VIBRATO_OFF
	db $EB, $00
ENDM
; $EC n: volume envelope n (0 = off)
MACRO ENVELOPE
	db $EC, \1
ENDM
; $ED xy: duty step
MACRO DUTY_STEP
	db $ED, (\1 << 4) | \2
ENDM
; $EE x: tempo x; $EE $80 | n: speed-up - one tick off every music track's length every n updates
MACRO TEMPO
	db $EE, \1
ENDM
; note-volume mode: $EE marks; $EE x y n goes back to the mark until the n-th pass, sliding the pitch by
; x and the attenuation by y each pass
MACRO EE_MARK
	db $EE
ENDM
MACRO EE_REPEAT
	db $EE, \1, \2, \3
ENDM
MACRO DETUNE
	db $EF, \1
ENDM
MACRO ATTEN
	db $F0 | \1
ENDM
; $F9 x: on the last pass of loop 1 (x odd) or loop 2 (x even), jump past its end
MACRO LOOP_BREAK
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
; vibrato / semitone / envelope tables: 1-byte steps, $FB / $FB n loop, $FE mark / jump, $FF end
MACRO VIB_STEP
	db (\1 << 4) | (\2 << 3) | \3
ENDM
MACRO VIB_SEMI_STEP
	db (\1 << 4) | \2
ENDM
MACRO ENV_STEP
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

SECTION "Sound ROM0", ROM0[$1FD6]

; SndInit (from the boot code): wSndBusy bit 2; map WRAM bank 7 (wGameWramBank keeps the
; game's); SndClearRAM; NR50 = $77, NR51 = $FF, wWaveId = $FF, NR52 = $80; the register
; addresses of tracks 0-5; the game's WRAM bank again. Every entry point below maps WRAM bank
; 7 the same way (wWramBank is the game's copy of SVBK).
SndInit:
	ld hl, wSndBusy
	set 2, [hl]
	ld a, [wWramBank]
	push af
	ld a, $07
	ld [wWramBank], a
	ldh [rSVBK], a
	pop af
	ld [wGameWramBank], a
	call SndClearRAM
	ld c, $24
	ld a, $77
	ldh [c], a
	inc c
	ld a, $FF
	ldh [c], a
	ld [wWaveId], a
	inc c
	ld a, $80
	ldh [c], a
	ld h, HIGH(wTrkSfx1)
	ld a, $11
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
	ld a, [wGameWramBank]
	ld [wWramBank], a
	ldh [rSVBK], a
	ld hl, wSndBusy
	res 2, [hl]
	ret

SetRegAddrs:
	ld l, TRK_REG_NRX1
	ld [hl+], a
	inc a
	ld [hl+], a
	inc a
	ld [hl+], a
	inc a
	ld [hl+], a
	inc h
	ret

SndClearRAM:
	ld hl, wTrkSfx1
	call ClearPage
	ld hl, wTrkSfx2
	call ClearPage
	ld hl, wTrkSfxN
	call ClearPage
	ld hl, wTrkCh1
	call ClearPage
	ld hl, wTrkCh2
	call ClearPage
	ld hl, wTrkCh3
	call ClearPage
	ld hl, wTrkDrm
	call ClearPage
	ld hl, $D700
	call ClearPage
	ld hl, wSndVars2
	ld c, $51
	call ClearBytes
	ret

ClearPage:
	ld c, $70

ClearBytes:
	xor a
	jp $CE53

; PlaySoundFarSet1 / PlaySoundFar: A = sound id (0 = stop all) with wTableSet = 1 / 0 (the
; first is never called). Sets wSndBusy bit 1, saves the game's ROM bank, PlaySound, maps it
; again.
PlaySoundFarSet1:
	di
	push hl
	push af
	ld hl, wSndBusy
	set 1, [hl]
	ei
	di
	ld a, [wWramBank]
	push af
	ld a, $07
	ld [wWramBank], a
	ldh [rSVBK], a
	pop af
	ld [wGameWramBank], a
	ei
	ld a, $01
	jr PlaySoundFarGo

PlaySoundFar:
	di
	push hl
	push af
	ld hl, wSndBusy
	set 1, [hl]
	ei
	di
	ld a, [wWramBank]
	push af
	ld a, $07
	ld [wWramBank], a
	ldh [rSVBK], a
	pop af
	ld [wGameWramBank], a
	ei
	xor a

PlaySoundFarGo:
	ld [wTableSet], a
	ld a, [wRomBank]
	ld [wGameBank], a
	pop af
	push de
	push bc
	call PlaySound
	ld a, [wGameBank]
	ld [wRomBank], a
	ld [rROMB], a
	pop bc
	pop de
	ld hl, wSndBusy
	di
	res 1, [hl]
	pop hl
	ld a, [wGameWramBank]
	ld [wWramBank], a
	ldh [rSVBK], a
	ei
	ret

; FarRead: map bank $0C + (TRK_PRIO >> 4) and copy 4 stream bytes from DE into wReadBuf;
; bank $0C again.
FarRead:
	ld l, TRK_PRIO
	ld a, [hl]
	swap a
	and $0F
	add a, $0C
	ld [wRomBank], a
	ld [rROMB], a
	push de
	ld a, [de]
	ld [wReadBuf], a
	inc de
	ld a, [de]
	ld [wReadBuf + $01], a
	inc de
	ld a, [de]
	ld [wReadBuf + $02], a
	inc de
	ld a, [de]
	ld [wReadBuf + $03], a
	ld a, $0C
	ld [wRomBank], a
	ld [rROMB], a
	pop de
	ret

; PlaySound: wReqId = id. 0: wMusicId = 0, StopAll. While wReqHold bit 0 is set the id goes
; to wHeldReq (never read). Ids >= $D7 are music: one equal to wMusicId is ignored. Header
; from [[SoundTableSets + 2 * wTableSet] + 2 * id]: priority (low nibble; high nibble = stream
; bank - $0C), track mask, pointers. Music resets the fade, tempo and speed-up.
PlaySound:
	ld [wReqId], a
	or a
	jr nz, HoldRequest.l211E
	ld [wMusicId], a
	ld a, $0C
	ld [wRomBank], a
	ld [rROMB], a
	jp $4F68

HoldRequest:
	ld [wHeldReq], a
	ret
.l211E:
	ld hl, wReqHold
	bit 0, [hl]
	jr nz, HoldRequest
	cp $D7
	jr c, PlaySoundGo
	ld b, a
	ld a, [wMusicId]
	cp b
	jr nz, .l2131
	ret
.l2131:
	ld a, b
	ld [wMusicId], a
	xor a
	ld [wNoiseAtten], a

PlaySoundGo:
	xor a
	ld [wWobbleOn], a
	ld a, [wSndDim]
	bit 0, a
	jr nz, .l2161
	ld a, [wFadeDir]
	or a
	jr z, .l2157
	bit 0, a
	jr z, .l2161
	res 0, a
	set 0, a
	ld [wFadeDir], a
	jr .l2161
.l2157:
	ld c, $24
	ldh a, [c]
	cp $77
	jr z, .l2161
	ld a, $77
	ldh [c], a
.l2161:
	ld a, $0C
	ld [wRomBank], a
	ld [rROMB], a
	ld a, [wTableSet]
	ld hl, SoundTableSets
	call LoadPtrIndexed
	ld a, [wReqId]

ReadHeader:
	call LoadPtrIndexed
	ld a, [hl+]
	ld [wReqPrio], a
	and $0F
	ld b, [hl]
	inc hl
	ld e, l
	ld d, h
	ld c, a
	inc c
	ld hl, wTrkSfx1
	rrc b
	call c, CheckSfxPrio
	inc h
	rrc b
	call c, CheckSfxPrio
	inc h
	rrc b
	call c, CheckSfxPrio
	ld a, b
	rlca
	rlca
	rlca
	ld b, a
	ld hl, wTrkSfx1
	srl b
	call c, StartSfxTrack
	ld hl, wTrkSfx2
	srl b
	call c, StartSfxTrack
	ld hl, wTrkSfxN
	srl b
	call c, StartSfxTrack
	xor a
	ld [wD710], a
	srl b
	jr c, .l21BE
	ret
.l21BE:
	ld hl, wTrkCh1
	ld a, [hl]
	and $0F
	ld c, a
	ld a, [wReqPrio]
	and $0F
	cp c
	ret c
	ld a, [wFadeDir]
	or a
	jr nz, .l21D8
	ld [wFadeRate], a
	ld [wFadeTimer], a
.l21D8:
	xor a
	ld [wFadeStep], a
	ld [wTempo], a
	ld [wSpeedRate], a
	call StartTrack
	srl b
	ld hl, wTrkCh2
	call c, StartTrack
	srl b
	ld hl, wTrkCh3
	call c, StartTrack
	srl b
	ld hl, wTrkDrm
	ret nc

; StartTrack: priority, id, pointer, LEN 1; clears the flags, attenuation, vibrato, envelope,
; release, slide and the instrument fields; wWaveId = $FF.
StartTrack:
	ld a, [wReqPrio]
	ld [hl+], a
	ld a, [wReqId]
	ld [hl+], a

StartTrackPtr:
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
	ld [hl], a
	ld l, TRK_ATTEN
	ld [hl], a
	ld l, TRK_VIB
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl], a
	ld l, TRK_SAVEPERIOD
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl], a
	ld l, TRK_GATE
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl], a
	ld l, TRK_SLIDEPTR
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl], a
	ld [wHeldReq], a
	ld [wReqHold], a
	ld l, TRK_INSTR
	ld [hl+], a
	ld [hl], a
	dec a
	ld [wWaveId], a
	ret

CheckSfxPrio:
	ld a, [hl]
	and $0F
	cp c
	ret c
	ld b, $00
	ret

StartSfxTrack:
	call StartTrack
	ld a, $D0
	cp h
	jr nz, .l225B
	ld a, $08
	ld c, $10
	ldh [c], a
	ret
.l225B:
	ld a, $D2
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

; SndUpdate (from the VBlank handler, $00AE): the pause (CH2 muted once), FadeCheck,
; WobbleTick, SpeedTick, then Ch1, Ch2, Ch3, Drm (not while paused), SfxN, Sfx2, Sfx1; the
; game's ROM and WRAM banks again.
SndUpdate:
	di
	ld a, [wWramBank]
	push af
	ld a, $07
	ld [wWramBank], a
	ldh [rSVBK], a
	pop af
	ld [wGameWramBank], a
	ei
	ld a, [wRomBank]
	ld [wGameBank], a
	ld a, [wPauseFlag]
	and a
	jr z, .l229F
	ld a, [wPauseMuted]
	and a
	jp nz, UpdateSfx
	ld a, $08
	ld c, $17
	ldh [c], a
	ld a, $80
	ld c, $19
	ldh [c], a
	ld [wPauseMuted], a
	jr UpdateSfx
.l229F:
	ld [wPauseMuted], a

UpdateAll:
	call FadeCheck
	call WobbleTick
	call SpeedTick
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
.l22DB:
	ld a, [wGameBank]
	ld [wRomBank], a
	ld [rROMB], a
	ld a, [wGameWramBank]
	ld [wWramBank], a
	ldh [rSVBK], a
	ret

RunTrack:
	ld [wTrackDesc], a
	ld l, TRK_ID
	ld a, [hl]
	or a
	ret z
	ld a, $0C
	ld [wRomBank], a
	ld [rROMB], a
	jp $478A

SkipSfx1:
	ld a, $0C
	ld [wRomBank], a
	ld [rROMB], a
	jr UpdateSfx.l22DB

; SpeedTick ($EE $80|n set wSpeedRate = wSpeedTimer = n): every n updates one tick comes off
; the LEN of all four music tracks; while any of them is about to read (LEN < 2) the step is
; put off to the next update. wSpeedRate 0: TempoTick (the tempo skip) instead.
SpeedTick:
	ld a, [wSpeedRate]
	and a
	jr z, TempoTick
	ld a, [wSpeedTimer]
	dec a
	jr z, SpeedStep
	ld [wSpeedTimer], a
	ret

SpeedStep:
	ld b, a
	ld h, HIGH(wTrkCh1)
	call SpeedCheckTrack
	inc h
	call SpeedCheckTrack
	inc h
	call SpeedCheckTrack
	inc h
	call SpeedCheckTrack
	ld a, b
	and a
	ret nz
	ld l, TRK_LEN
	dec [hl]
	dec h
	dec [hl]
	dec h
	dec [hl]
	dec h
	dec [hl]
	ld a, $FF
	ld a, [wSpeedRate]
	ld [wSpeedTimer], a
	ret

SpeedCheckTrack:
	ld l, TRK_ID
	ld a, [hl]
	and a
	ret z
	ld l, TRK_LEN
	ld a, [hl]
	cp $02
	ret nc
	ld b, $01
	ret

; TempoTick: wTempoAcc += wTempo; the carry sets (else clears) the skip flag of the four
; music tracks.
TempoTick:
	ld hl, wTempo
	ld a, [hl]
	ld b, a
	or a
	ret z
	ld h, HIGH(wTrkCh1)
	ld a, [wTempoAcc]
	add a, b
	ld [wTempoAcc], a
	ld l, TRK_FLAGS
	jr c, .l236F
	res 4, [hl]
	inc h
	res 4, [hl]
	inc h
	res 4, [hl]
	inc h
	res 4, [hl]
	ret
.l236F:
	set 4, [hl]
	inc h
	set 4, [hl]
	inc h
	set 4, [hl]
	inc h
	set 4, [hl]
	ret

; FadeCheck / FadeTick: World Soccer GB2's fade (in and out by $11 steps of NR50, stopping
; Drm, Ch1, Ch2 and Ch3 at the end of a fade-out).
FadeCheck:
	ld a, [wReqHold]
	bit 2, a
	jr nz, FadeEnd

FadeTick:
	ld a, [wFadeRate]
	or a
	ret z
	ld hl, wFadeTimer
	inc [hl]
	cp [hl]
	ret nz
	ld [hl], $00
	ld a, [wFadeDir]
	bit 0, a
	jr z, FadeOut
	ld c, $24
	ldh a, [c]
	cp $77
	jr z, FadeEnd
	add a, $11
	ldh [c], a
	ret

FadeEnd:
	xor a
	ld [wFadeDir], a
	ld [wFadeRate], a
	ld [wFadeTimer], a
	ld [wFadeStep], a
	ret

FadeOut:
	ld c, $24
	ldh a, [c]
	cp $11
	jr z, FadeStep
	sub $11
	jr z, FadeStep
	ldh [c], a
	ret

FadeStep:
	ld a, $01
	ld [wFadeRate], a
	ld a, [wFadeStep]
	inc a
	ld [wFadeStep], a
	cp $10
	jr z, FadeStopCh2.l2421
	cp $18
	jr z, FadeStopCh1
	cp $1C
	jr z, FadeStopCh2
	cp $20
	ret nz

FadeStopCh3:
	ld h, HIGH(wTrkSfx2)
	ld l, TRK_ID
	ld a, [hl]
	or a
	ld a, $00
	jr nz, .l23E7
	ld c, $1A
	ldh [c], a
	ld c, $1C
	ldh [c], a
.l23E7:
	ld h, HIGH(wTrkCh3)
	ld [wFadeStep], a
	ld [wFadeRate], a
	ld [wFadeTimer], a
	ld a, $0C
	ld [wRomBank], a
	ld [rROMB], a
	jp $4F68

FadeStopCh1:
	ld h, HIGH(wTrkSfx1)
	ld l, TRK_ID
	ld a, [hl]
	or a
	jr nz, .l240F
	ld a, $08
	ld c, $12
	ldh [c], a
	ld a, $80
	ld c, $14
	ldh [c], a
.l240F:
	ld h, HIGH(wTrkCh1)
	jr FadeStopTrack

FadeStopCh2:
	ld h, HIGH(wTrkCh2)
	ld a, $08
	ld c, $17
	ldh [c], a
	ld a, $80
	ld c, $19
	ldh [c], a
	jr FadeStopTrack
.l2421:
	ld h, HIGH(wTrkSfxN)
	call FadeStopTrack
	xor a
	ldh [rNR42], a

FadeStopDrm:
	ld h, HIGH(wTrkDrm)

FadeStopTrack:
	ld l, TRK_ID
	xor a
	ld [hl-], a
	ld [hl], a
	ret

WobbleTick:
	ld hl, wWobbleOn
	bit 0, [hl]
	ret z
	inc l
	ld a, [hl+]
	inc [hl]
	cp [hl]
	ret nz
	ld [hl], $00
	ld l, TRK_OUTPERIOD
	bit 1, [hl]
	ld c, $24
	ldh a, [c]
	jr nz, .l2455
	dec l
	and $0F
	cp [hl]
	jr nz, .l2460
	inc l
	set 1, [hl]
.l2450:
	ldh a, [c]
	sub $0F
	ldh [c], a
	ret
.l2455:
	swap a
	dec l
	and $0F
	cp [hl]
	jr nz, .l2450
	inc l
	res 1, [hl]
.l2460:
	ldh a, [c]
	add a, $0F
	cp $80
	jr c, .l2469
	sub $10
.l2469:
	ldh [c], a
	ret

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

; StartFadeOut, StopAndFadeIn (with StartFadeIn), SndUndim, SndDim: the game's entry points,
; each mapping WRAM bank 7 first.
StartFadeOut:
	push af
	di
	ld a, [wWramBank]
	push af
	ld a, $07
	ld [wWramBank], a
	ldh [rSVBK], a
	pop af
	ld [wGameWramBank], a
	ei
	pop af
	ld [wFadeRate], a
	dec a
	ld [wFadeTimer], a
	xor a
	ld [wFadeDir], a
	ld a, [wWobbleOn]
	or a
	ld c, $24
	jr nz, .l24A2
	ldh a, [c]
	cp $77
	jr z, .l24A6
.l24A2:
	xor a
	ld [wWobbleOn], a
.l24A6:
	ld a, [wGameWramBank]
	ld [wWramBank], a
	ldh [rSVBK], a
	ret

StopAndFadeIn:
	di
	ld a, [wWramBank]
	push af
	ld a, $07
	ld [wWramBank], a
	ldh [rSVBK], a
	pop af
	ld [wGameWramBank], a
	ei
	xor a
	call PlaySoundFar

StartFadeIn:
	xor a
	push hl
	ld hl, wFadeDir
	set 0, [hl]
	inc l
	inc l
	ld [hl+], a
	ld [hl], a
	ld c, $24
	ld a, $00
	ldh [c], a
	pop hl
	ld a, [wGameWramBank]
	ld [wWramBank], a
	ldh [rSVBK], a
	ret

SndUndim:
	di
	ld a, [wWramBank]
	push af
	ld a, $07
	ld [wWramBank], a
	ldh [rSVBK], a
	pop af
	ld [wGameWramBank], a
	ei
	ld a, [wFadeRate]
	or a
	jr nz, .l24FF
	ld hl, wSndDim
	res 0, [hl]
	ld a, $77
	ld c, $24
	ldh [c], a
.l24FF:
	ld a, [wGameWramBank]
	ld [wWramBank], a
	ldh [rSVBK], a
	ret

SndDim:
	di
	ld a, [wWramBank]
	push af
	ld a, $07
	ld [wWramBank], a
	ldh [rSVBK], a
	pop af
	ld [wGameWramBank], a
	ei
	ld a, [wFadeRate]
	or a
	jr nz, .l2529
	ld hl, wSndDim
	set 0, [hl]
	ld a, $44
	ld c, $24
	ldh [c], a
.l2529:
	ld a, [wGameWramBank]
	ld [wWramBank], a
	ldh [rSVBK], a
	ret

SECTION "Sound bank $0C", ROMX[$4000], BANK[$0C]

; SoundTableSets: [SoundTableSets + 2 * wTableSet] is the table PlaySound reads: set 0 =
; SoundTable, set 1 = DrumSet1Table (its pointer is also SoundTable entry 0). The drum
; track reads its hits from set wDrumSet ($EA Fx).
SoundTableSets:
	dw SoundTable ; table set 0 (wTableSet 0)
SoundTable:
	dw DrumSet1Table ; table set 1 (DrumSet1Table); also id $00 (never read)
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
	dw SndHdr9F ; $9F
	dw SndHdrA0 ; $A0
	dw SndHdrA1 ; $A1
	dw SndHdrA2 ; $A2
	dw SndHdrA3 ; $A3
	dw SndHdrA4 ; $A4
	dw SndHdrA5 ; $A5
	dw SndHdrA6 ; $A6
	dw SndHdrA7 ; $A7
	dw SndHdrA8 ; $A8
	dw SndHdrA9 ; $A9
	dw SndHdrAA ; $AA
	dw SndHdrAB ; $AB
	dw SndHdrAC ; $AC
	dw SndHdrAD ; $AD
	dw SndHdrAE ; $AE
	dw SndHdrAF ; $AF
	dw SndHdrB0 ; $B0
	dw SndHdrB1 ; $B1
	dw SndHdrB2 ; $B2
	dw SndHdrB3 ; $B3
	dw SndHdrB4 ; $B4
	dw SndHdrB5 ; $B5
	dw SndHdrB6 ; $B6
	dw SndHdrB7 ; $B7
	dw SndHdrB8 ; $B8
	dw SndHdrB9 ; $B9
	dw SndHdrBA ; $BA
	dw SndHdrBB ; $BB
	dw SndHdrBC ; $BC
	dw SndHdrBD ; $BD
	dw SndHdrBE ; $BE
	dw SndHdrBF ; $BF
	dw SndHdrC0 ; $C0
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
	dw SndHdrF4 ; $F4
	dw SndHdrF5 ; $F5
	dw SndHdrF6 ; $F6

SndHdr01:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd01_SfxN

SndHdr02:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd02_SfxN

SndHdr03:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd03_SfxN

SndHdr04:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd04_SfxN

SndHdr05:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd05_SfxN

SndHdr06:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd06_SfxN

SndHdr07:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd07_SfxN

SndHdr08:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd08_SfxN

SndHdr09:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd09_SfxN

SndHdr0A:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd0A_SfxN

SndHdr0B:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd0B_SfxN

SndHdr0C:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd0C_SfxN

SndHdr0D:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd0D_SfxN

SndHdr0E:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd0E_SfxN

SndHdr0F:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd0F_SfxN

SndHdr10:
	SND_HEADER $0F, $07 ; tracks: Sfx1, Sfx2, SfxN (streams in bank $0C)
	dw Snd10_Sfx1
	dw Snd10_Sfx2
	dw Snd10_Sfx2

SndHdr11:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd11_Sfx1

SndHdr12:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd12_Sfx1

SndHdr13:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd13_Sfx1

SndHdr14:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd14_Sfx1

SndHdr15:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd15_Sfx1

SndHdr16:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd16_Sfx1

SndHdr17:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd17_Sfx1

SndHdr18:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd18_Sfx1
	dw Snd18_SfxN

SndHdr19:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd19_SfxN

SndHdr1A:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd1A_Sfx1

SndHdr1B:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd1B_Sfx1

SndHdr1C:
	SND_HEADER $0B, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd1C_Sfx1
	dw Snd1C_SfxN

SndHdr1D:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd1D_Sfx1

SndHdr1E:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd1E_Sfx1

SndHdr1F:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd1F_Sfx1

SndHdr20:
	SND_HEADER $09, $07 ; tracks: Sfx1, Sfx2, SfxN (streams in bank $0C)
	dw Snd20_Sfx1
	dw Snd20_Sfx2
	dw Snd20_SfxN

SndHdr21:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd21_Sfx1
	dw Snd21_SfxN

SndHdr22:
	SND_HEADER $09, $03 ; tracks: Sfx1, Sfx2 (streams in bank $0C)
	dw Snd22_Sfx1
	dw Snd22_Sfx2

SndHdr23:
	SND_HEADER $09, $02 ; tracks: Sfx2 (streams in bank $0C)
	dw Snd23_Sfx2

SndHdr24:
	SND_HEADER $09, $02 ; tracks: Sfx2 (streams in bank $0C)
	dw Snd10_Sfx2

SndHdr25:
	SND_HEADER $09, $03 ; tracks: Sfx1, Sfx2 (streams in bank $0C)
	dw Snd25_Sfx1
	dw Snd25_Sfx2

SndHdr26:
	SND_HEADER $09, $03 ; tracks: Sfx1, Sfx2 (streams in bank $0C)
	dw Snd26_Sfx1
	dw Snd26_Sfx2

SndHdr27:
	SND_HEADER $09, $03 ; tracks: Sfx1, Sfx2 (streams in bank $0C)
	dw Snd27_Sfx1
	dw Snd27_Sfx2

SndHdr28:
	SND_HEADER $09, $03 ; tracks: Sfx1, Sfx2 (streams in bank $0C)
	dw Snd28_Sfx1
	dw Snd28_Sfx2

SndHdr29:
	SND_HEADER $09, $03 ; tracks: Sfx1, Sfx2 (streams in bank $0C)
	dw Snd29_Sfx1
	dw Snd29_Sfx2

SndHdr2A:
	SND_HEADER $09, $03 ; tracks: Sfx1, Sfx2 (streams in bank $0C)
	dw Snd2A_Sfx1
	dw Snd2A_Sfx2

SndHdr2B:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd2B_Sfx1

SndHdr2C:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd2C_Sfx1

SndHdr2D:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd2D_Sfx1

SndHdr2E:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd2E_Sfx1

SndHdr2F:
	SND_HEADER $07, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd2F_Sfx1

SndHdr30:
	SND_HEADER $0B, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd30_Sfx1

SndHdr31:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd31_Sfx1

SndHdr32:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd32_Sfx1

SndHdr33:
	SND_HEADER $0B, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd33_Sfx1

SndHdr34:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd34_Sfx1

SndHdr35:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd35_SfxN

SndHdr36:
	SND_HEADER $0B, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd36_SfxN

SndHdr37:
	SND_HEADER $0B, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd37_SfxN

SndHdr38:
	SND_HEADER $0B, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd38_SfxN

SndHdr39:
	SND_HEADER $0B, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd39_SfxN

SndHdr3A:
	SND_HEADER $0B, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd3A_SfxN

SndHdr3B:
	SND_HEADER $0B, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd3B_SfxN

SndHdr3C:
	SND_HEADER $0B, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd3C_Sfx1

SndHdr3D:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd3D_Sfx1

SndHdr3E:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd3E_Sfx1

SndHdr3F:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd3F_Sfx1

SndHdr40:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd40_Sfx1

SndHdr41:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd41_Sfx1

SndHdr42:
	SND_HEADER $0B, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd42_Sfx1

SndHdr43:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd43_Sfx1

SndHdr44:
	SND_HEADER $0B, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd44_Sfx1

SndHdr45:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd45_Sfx1

SndHdr46:
	SND_HEADER $0B, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd46_Sfx1

SndHdr47:
	SND_HEADER $0A, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd47_Sfx1

SndHdr48:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd48_SfxN

SndHdr49:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd49_Sfx1

SndHdr4A:
	SND_HEADER $0B, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd4A_Sfx1

SndHdr4B:
	SND_HEADER $0B, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd4B_Sfx1

SndHdr4C:
	SND_HEADER $0B, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd4C_Sfx1

SndHdr4D:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd4D_SfxN

SndHdr4E:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd4E_Sfx1
	dw Snd4E_SfxN

SndHdr4F:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd4F_SfxN

SndHdr50:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd50_SfxN

SndHdr51:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd51_Sfx1

SndHdr52:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd52_Sfx1
	dw Snd52_SfxN

SndHdr53:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd53_SfxN

SndHdr54:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd54_SfxN

SndHdr55:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd55_SfxN

SndHdr56:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd56_Sfx1
	dw Snd56_SfxN

SndHdr57:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd57_Sfx1

SndHdr58:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd58_SfxN

SndHdr59:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd59_Sfx1
	dw Snd59_SfxN

SndHdr5A:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd5A_Sfx1

SndHdr5B:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd5B_SfxN

SndHdr5C:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd5C_Sfx1
	dw Snd5C_SfxN

SndHdr5D:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd5D_Sfx1
	dw Snd5D_SfxN

SndHdr5E:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd5E_Sfx1
	dw Snd5E_SfxN

SndHdr5F:
	SND_HEADER $0A, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd5F_Sfx1

SndHdr60:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd60_Sfx1

SndHdr61:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd61_Sfx1
	dw Snd61_SfxN

SndHdr62:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd62_Sfx1
	dw Snd62_SfxN

SndHdr63:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd63_Sfx1
	dw Snd63_SfxN

SndHdr64:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd64_Sfx1
	dw Snd64_SfxN

SndHdr65:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd65_Sfx1
	dw Snd65_SfxN

SndHdr66:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd66_SfxN

SndHdr67:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd67_Sfx1
	dw Snd67_SfxN

SndHdr68:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd68_SfxN

SndHdr69:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd69_Sfx1

SndHdr6A:
	SND_HEADER $0B, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd6A_SfxN

SndHdr6B:
	SND_HEADER $0B, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd6B_Sfx1
	dw Snd6B_SfxN

SndHdr6C:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd6C_SfxN

SndHdr6D:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd6D_SfxN

SndHdr6E:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd6E_SfxN

SndHdr6F:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd6F_SfxN

SndHdr70:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd70_SfxN

SndHdr71:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd71_Sfx1

SndHdr72:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd72_SfxN

SndHdr73:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd73_SfxN

SndHdr74:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd74_SfxN

SndHdr75:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd75_SfxN

SndHdr76:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd76_Sfx1

SndHdr77:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd77_Sfx1

SndHdr78:
	SND_HEADER $09, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd78_Sfx1

SndHdr79:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd79_SfxN

SndHdr7A:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd7A_Sfx1
	dw Snd7A_SfxN

SndHdr7B:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd7B_SfxN

SndHdr7C:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd7C_Sfx1
	dw Snd7C_SfxN

SndHdr7D:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd7D_SfxN

SndHdr7E:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd7E_Sfx1
	dw Snd7E_SfxN

SndHdr7F:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd7F_SfxN

SndHdr80:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd80_SfxN

SndHdr81:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd81_Sfx1
	dw Snd81_SfxN

SndHdr82:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd82_Sfx1
	dw Snd82_SfxN

SndHdr83:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd83_Sfx1
	dw Snd83_SfxN

SndHdr84:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd84_SfxN

SndHdr85:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd85_SfxN

SndHdr86:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd86_Sfx1
	dw Snd86_SfxN

SndHdr87:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd87_Sfx1
	dw Snd87_SfxN

SndHdr88:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd88_Sfx1
	dw Snd88_SfxN

SndHdr89:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd89_Sfx1
	dw Snd89_SfxN

SndHdr8A:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd8A_Sfx1
	dw Snd8A_SfxN

SndHdr8B:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd8B_Sfx1
	dw Snd8B_SfxN

SndHdr8C:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd8C_Sfx1
	dw Snd8C_SfxN

SndHdr8D:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd8D_Sfx1
	dw Snd8D_SfxN

SndHdr8E:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd8E_Sfx1
	dw Snd8E_SfxN

SndHdr8F:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd8F_Sfx1
	dw Snd8F_SfxN

SndHdr90:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd90_Sfx1
	dw Snd90_SfxN

SndHdr91:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd91_Sfx1
	dw Snd91_SfxN

SndHdr92:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd92_Sfx1
	dw Snd92_SfxN

SndHdr93:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd93_Sfx1
	dw Snd93_SfxN

SndHdr94:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd94_Sfx1
	dw Snd94_SfxN

SndHdr95:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd95_Sfx1
	dw Snd95_SfxN

SndHdr96:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd96_SfxN

SndHdr97:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd97_SfxN

SndHdr98:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd98_SfxN

SndHdr99:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd99_SfxN

SndHdr9A:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd9A_SfxN

SndHdr9B:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd9B_Sfx1
	dw Snd9B_SfxN

SndHdr9C:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd9C_Sfx1
	dw Snd9C_SfxN

SndHdr9D:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd9D_SfxN

SndHdr9E:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd9E_Sfx1
	dw Snd9E_SfxN

SndHdr9F:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd9F_Sfx1
	dw Snd9F_SfxN

SndHdrA0:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw SndA0_SfxN

SndHdrA1:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw SndA1_Sfx1
	dw SndA1_SfxN

SndHdrA2:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw SndA2_Sfx1
	dw SndA2_SfxN

SndHdrA3:
	SND_HEADER $09, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw SndA3_Sfx1
	dw SndA3_SfxN

SndHdrA4:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw SndA4_SfxN

SndHdrA5:
	SND_HEADER $09, $04 ; tracks: SfxN (streams in bank $0C)
	dw SndA5_SfxN

SndHdrA6:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndA6_Sfx1
	dw SndA6_SfxN

SndHdrA7:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndA7_Sfx1
	dw SndA7_SfxN

SndHdrA8:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndA8_Sfx1
	dw SndA8_SfxN

SndHdrA9:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndA9_Sfx1
	dw SndA9_SfxN

SndHdrAA:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndAA_Sfx1
	dw SndAA_SfxN

SndHdrAB:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndAB_Sfx1
	dw SndAB_SfxN

SndHdrAC:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndAC_Sfx1
	dw SndAC_SfxN

SndHdrAD:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndAD_Sfx1
	dw SndAD_SfxN

SndHdrAE:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndAE_Sfx1
	dw SndAE_SfxN

SndHdrAF:
	SND_HEADER $19, $04 ; tracks: SfxN (streams in bank $0D)
	dw SndAF_SfxN

SndHdrB0:
	SND_HEADER $19, $04 ; tracks: SfxN (streams in bank $0D)
	dw SndB0_SfxN

SndHdrB1:
	SND_HEADER $19, $04 ; tracks: SfxN (streams in bank $0D)
	dw SndB1_SfxN

SndHdrB2:
	SND_HEADER $19, $04 ; tracks: SfxN (streams in bank $0D)
	dw SndB2_SfxN

SndHdrB3:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndB3_Sfx1
	dw SndB3_SfxN

SndHdrB4:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndB4_Sfx1
	dw SndB4_SfxN

SndHdrB5:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndB5_Sfx1
	dw SndB5_SfxN

SndHdrB6:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndB6_Sfx1
	dw SndB6_SfxN

SndHdrB7:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndB7_Sfx1
	dw SndB7_SfxN

SndHdrB8:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndB8_Sfx1
	dw SndB8_SfxN

SndHdrB9:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndB9_Sfx1
	dw SndB9_SfxN

SndHdrBA:
	SND_HEADER $19, $04 ; tracks: SfxN (streams in bank $0D)
	dw SndBA_SfxN

SndHdrBB:
	SND_HEADER $19, $04 ; tracks: SfxN (streams in bank $0D)
	dw SndBB_SfxN

SndHdrBC:
	SND_HEADER $19, $04 ; tracks: SfxN (streams in bank $0D)
	dw SndBC_SfxN

SndHdrBD:
	SND_HEADER $19, $04 ; tracks: SfxN (streams in bank $0D)
	dw SndBD_SfxN

SndHdrBE:
	SND_HEADER $19, $04 ; tracks: SfxN (streams in bank $0D)
	dw SndBE_SfxN

SndHdrBF:
	SND_HEADER $19, $04 ; tracks: SfxN (streams in bank $0D)
	dw SndBF_SfxN

SndHdrC0:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndC0_Sfx1
	dw SndC0_SfxN

SndHdrC1:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndC1_Sfx1
	dw SndC1_SfxN

SndHdrC2:
	SND_HEADER $19, $04 ; tracks: SfxN (streams in bank $0D)
	dw SndC2_SfxN

SndHdrC3:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndC3_Sfx1
	dw SndC3_SfxN

SndHdrC4:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndC4_Sfx1
	dw SndC4_SfxN

SndHdrC5:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndC5_Sfx1
	dw SndC5_SfxN

SndHdrC6:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndC6_Sfx1
	dw SndC6_SfxN

SndHdrC7:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndC7_Sfx1
	dw SndC7_SfxN

SndHdrC8:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndC8_Sfx1
	dw SndC8_SfxN

SndHdrC9:
	SND_HEADER $19, $04 ; tracks: SfxN (streams in bank $0D)
	dw SndC9_SfxN

SndHdrCA:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndCA_Sfx1
	dw SndCA_SfxN

SndHdrCB:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndCB_Sfx1
	dw SndCB_SfxN

SndHdrCC:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndCC_Sfx1
	dw SndCC_SfxN

SndHdrCD:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndCD_Sfx1
	dw SndCD_SfxN

SndHdrCE:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndCE_Sfx1
	dw SndCE_SfxN

SndHdrCF:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndCF_Sfx1
	dw SndCF_SfxN

SndHdrD0:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndD0_Sfx1
	dw SndD0_SfxN

SndHdrD1:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndD1_Sfx1
	dw SndD1_SfxN

SndHdrD2:
	SND_HEADER $19, $05 ; tracks: Sfx1, SfxN (streams in bank $0D)
	dw SndD2_Sfx1
	dw SndD2_SfxN

SndHdrD3:
	SND_HEADER $19, $07 ; tracks: Sfx1, Sfx2, SfxN (streams in bank $0D)
	dw SndD3_Sfx1
	dw SndD3_Sfx2
	dw SndD3_SfxN

SndHdrD4:
	SND_HEADER $19, $07 ; tracks: Sfx1, Sfx2, SfxN (streams in bank $0D)
	dw SndD4_Sfx1
	dw SndD4_Sfx2
	dw SndD4_SfxN

SndHdrD5:
	SND_HEADER $19, $04 ; tracks: SfxN (streams in bank $0D)
	dw SndD5_SfxN

SndHdrD6:
	SND_HEADER $19, $07 ; tracks: Sfx1, Sfx2, SfxN (streams in bank $0D)
	dw SndD6_Sfx1
	dw SndD6_Sfx2
	dw SndD6_SfxN

SndHdrD7:
	SND_HEADER $18, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0D)
	dw SndD7_Ch1
	dw SndD7_Ch2
	dw SndD7_Ch3
	dw SndD7_Drm

SndHdrD8:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw SndD8_Ch1
	dw SndD8_Ch2
	dw SndD8_Ch3
	dw SndD8_Drm

SndHdrD9:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw SndD9_Ch1
	dw SndD9_Ch2
	dw SndD9_Ch3
	dw SndD9_Drm

SndHdrDA:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw SndDA_Ch1
	dw SndDA_Ch2
	dw SndDA_Ch3
	dw SndDA_Drm

SndHdrE0:
	SND_HEADER $18, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0D)
	dw SndE0_Ch1
	dw SndE0_Ch2
	dw SndE0_Ch3
	dw SndE0_Drm

SndHdrE1:
	SND_HEADER $18, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0D)
	dw SndE1_Ch1
	dw SndE1_Ch2
	dw SndE1_Ch3
	dw SndE1_Drm

SndHdrE3:
	SND_HEADER $18, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0D)
	dw SndE3_Ch1
	dw SndE3_Ch2
	dw SndE3_Ch3
	dw SndE3_Drm

SndHdrE6:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw SndE6_Ch1
	dw SndE6_Ch2
	dw SndE6_Ch3
	dw SndE6_Drm

SndHdrE7:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw SndE7_Ch1
	dw SndE7_Ch2
	dw SndE7_Ch3
	dw SndE7_Drm

SndHdrEA:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw SndEA_Ch1
	dw SndEA_Ch2
	dw SndEA_Ch3
	dw SndEA_Drm

SndHdrEB:
	SND_HEADER $38, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0F)
	dw SndEB_Ch1
	dw SndEB_Ch2
	dw SndEB_Ch3
	dw SndEB_Drm

SndHdrE4:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw SndE4_Ch1
	dw SndE4_Ch2
	dw SndE4_Ch3
	dw SndE4_Drm

SndHdrDC:
	SND_HEADER $18, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0D)
	dw SndDC_Ch1
	dw SndDC_Ch2
	dw SndDC_Ch3
	dw SndDC_Drm

SndHdrE8:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw SndE8_Ch1
	dw SndE8_Ch2
	dw SndE8_Ch3
	dw SndE8_Drm

SndHdrE5:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw SndE5_Ch1
	dw SndE5_Ch2
	dw SndE5_Ch3
	dw SndE5_Drm

SndHdrE2:
	SND_HEADER $18, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0D)
	dw SndE2_Ch1
	dw SndE2_Ch2
	dw SndE2_Ch3
	dw SndE2_Drm

SndHdrE9:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw SndE9_Ch1
	dw SndE9_Ch2
	dw SndE9_Ch3
	dw SndE9_Drm

SndHdrEE:
	SND_HEADER $38, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0F)
	dw SndEE_Ch1
	dw SndEE_Ch2
	dw SndEE_Ch3
	dw SndEE_Drm

SndHdrDB:
	SND_HEADER $18, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0D)
	dw SndDB_Ch1
	dw SndDB_Ch2
	dw SndDB_Ch3
	dw SndDB_Drm

SndHdrF2:
	SND_HEADER $38, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0F)
	dw SndF2_Ch1
	dw SndF2_Ch2
	dw SndF2_Ch3
	dw SndF2_Drm

SndHdrF3:
	SND_HEADER $38, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0F)
	dw SndF3_Ch1
	dw SndF3_Ch2
	dw SndF3_Ch3
	dw SndF3_Drm

SndHdrF4:
	SND_HEADER $38, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0F)
	dw SndF4_Ch1
	dw SndF4_Ch2
	dw SndF4_Ch3
	dw SndF4_Drm

SndHdrDE:
	SND_HEADER $18, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0D)
	dw SndDE_Ch1
	dw SndDE_Ch2
	dw SndDE_Ch3
	dw SndDE_Drm

SndHdrEF:
	SND_HEADER $38, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0F)
	dw SndEF_Ch1
	dw SndEF_Ch2
	dw SndEF_Ch3
	dw SndEF_Drm

SndHdrEC:
	SND_HEADER $38, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0F)
	dw SndEC_Ch1
	dw SndEC_Ch2
	dw SndEC_Ch3
	dw SndEC_Drm

SndHdrF0:
	SND_HEADER $38, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0F)
	dw SndF0_Ch1
	dw SndF0_Ch2
	dw SndF0_Ch3
	dw SndF0_Drm

SndHdrED:
	SND_HEADER $38, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0F)
	dw SndED_Ch1
	dw SndED_Ch2
	dw SndED_Ch3
	dw SndED_Drm

SndHdrF5:
	SND_HEADER $38, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0F)
	dw SndF5_Ch1
	dw SndF5_Ch2
	dw SndF5_Ch3
	dw SndF5_Drm

SndHdrF1:
	SND_HEADER $38, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0F)
	dw SndF1_Ch1
	dw SndF1_Ch2
	dw SndF1_Ch3
	dw SndF1_Drm

SndHdrDD:
	SND_HEADER $18, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0D)
	dw SndDD_Ch1
	dw SndDD_Ch2
	dw SndDD_Ch3
	dw SndDD_Drm

SndHdrDF:
	SND_HEADER $18, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0D)
	dw SndDF_Ch1
	dw SndDF_Ch2
	dw SndDF_Ch3
	dw SndDF_Drm

SndHdrF6:
	SND_HEADER $38, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0F)
	dw SndF6_Ch1
	dw SndF6_Ch2
	dw SndF6_Ch3 ; the next pointer is the first word of DrumSet1Table

; DrumSet1Table: the second drum set (drum notes after $EA F1), 11 hits.
DrumSet1Table:
	dw $6414 ; id $00 (never read)
	dw SndHdr101 ; drum set 1 hit 1
	dw SndHdr102 ; drum set 1 hit 2
	dw SndHdr103 ; drum set 1 hit 3
	dw SndHdr104 ; drum set 1 hit 4
	dw SndHdr105 ; drum set 1 hit 5
	dw SndHdr106 ; drum set 1 hit 6
	dw SndHdr107 ; drum set 1 hit 7
	dw SndHdr108 ; drum set 1 hit 8
	dw SndHdr109 ; drum set 1 hit 9
	dw SndHdr10A ; drum set 1 hit 10
	dw SndHdr10B ; drum set 1 hit 11

SndHdr101:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd101_SfxN

SndHdr102:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd102_SfxN

SndHdr103:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd103_SfxN

SndHdr104:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd104_SfxN

SndHdr105:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd105_SfxN

SndHdr106:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd106_SfxN

SndHdr107:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd107_SfxN

SndHdr108:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd108_SfxN

SndHdr109:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd109_SfxN

SndHdr10A:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd10A_SfxN

SndHdr10B:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd10B_SfxN

; TrackTick: tempo skip; a pending duty reload; LEN - 1; at 0 FarRead and read commands,
; else Sustain.
TrackTick:
	ld l, TRK_FLAGS
	bit 4, [hl]
	ret nz
	bit 5, [hl]
	jr z, .l479B
	res 5, [hl]
	ld l, TRK_CURDUTY
	ld a, [hl]
	call WriteDuty
.l479B:
	ld l, TRK_LEN
	dec [hl]
	jp nz, Sustain
	ld l, TRK_PTR
	ld e, [hl]
	inc l
	ld d, [hl]

ReadCmds:
	call FarRead
	ld a, [wReadBuf]
	cp $E0
	jp nc, Command
	ld a, [wTrackDesc]
	cp $63
	jp z, NoiseNote
	ld l, TRK_FLAGS

MusicNote:
	res 2, [hl]
	call SavePtr
	ld l, TRK_UNIT
	ld c, [hl]
	ld a, [wReadBuf]
	ld l, TRK_FLAGS
	bit 1, [hl]
	jr z, .l47D7
	ld l, TRK_VOL
	and $0F
	swap a
	ld [hl], a
	ld a, $01
	jr .l47DB
.l47D7:
	and $0F
	jr z, .l47EB
.l47DB:
	ld b, a
	xor a
	bit 0, b
	jr nz, .l47F2
	rrc b
.l47E3:
	add a, c
	dec b
	jr nz, .l47E3
	add a, a
	jp NoteLen
.l47EB:
	swap c
	ld a, c
	and $F0
	jr NoteLen
.l47F2:
	add a, c
	dec b
	jr nz, .l47F2

NoteLen:
	ld l, TRK_LEN
	ld [hl+], a
	ld c, a
	ld a, [wReadBuf]
	and $F0
	jr nz, Note
	set 0, [hl]
	ld a, [wTrackDesc]
	cp $34
	ret z
	ld a, $08
	jp WriteVolume

; Note: World Soccer GB2's, and with an instrument (TRK_INSTR) its macro restarts from the
; first step (TRK_INSTIMER 1, so the first step is read on the next tick).
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
	jr z, .l482F
	ld e, a
	ld b, $00
	ld l, b
	ld h, b
.l4825:
	add hl, bc
	dec e
	jr nz, .l4825
	ld a, l
	and $F0
	or h
	swap a
.l482F:
	pop hl
	pop de
	ld l, TRK_RELTICK
	ld [hl], a
	ld l, TRK_DUTYCNT
	ld a, [hl+]
	or a
	jr z, .l483F
	ld [hl+], a
	ld a, [hl]
	call WriteDuty
.l483F:
	ld l, TRK_INSTR
	ld a, [hl]
	and a
	jr z, .l485C
	push hl
	ld hl, MacroTable - 2
	call LoadPtrIndexed
	ld c, l
	ld b, h
	pop hl
	ld l, TRK_INSPTR
	ld [hl], c
	inc l
	ld [hl], b
	ld l, TRK_INSTIMER
	ld a, $01
	ld [hl], a
	ld l, TRK_INSFLAGS
	ld [hl], a
.l485C:
	ld l, TRK_PANFLAGS
	bit 0, [hl]
	call nz, AutoPan
	ld a, [wReadBuf]
	and $F0
	cp $D0
	jr nz, .l4877
	ld l, TRK_OCTAVE
	ld a, [hl]
	add a, $18
	ld c, a
	ld l, $3C
	ld a, [hl]
	jr .l4880
.l4877:
	swap a
	rlca
	ld l, $3C
	ld [hl], a
	ld l, TRK_OCTAVE
	ld c, [hl]
.l4880:
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
	jr z, .l48A2
	ld c, [hl]
	push hl
	ld l, a
	ld h, c
	add hl, de
	ld e, l
	ld d, h
	pop hl
.l48A2:
	ld l, TRK_PANFLAGS
	bit 5, [hl]
	jr z, .l48B5
	ld l, TRK_SLIDEOFS
	ld a, [hl+]
	ld c, [hl]
	push hl
	ld l, a
	ld h, c
	add hl, de
	ld e, l
	ld d, h
	pop hl
	jr .l48CA
.l48B5:
	ld l, TRK_PANFLAGS
	bit 7, [hl]
	jr z, .l48CA
	ld a, [wTrackDesc]
	cp $22
	jr z, .l48CA
	ld l, TRK_PERIOD
	ld a, [hl+]
	ld b, [hl]
	ld l, TRK_SAVEPERIOD
	ld [hl+], a
	ld [hl], b
.l48CA:
	ld l, TRK_PERIOD
	ld [hl], e
	inc l
	ld [hl], d
	ld l, TRK_VIB
	ld a, [hl]
	or a
	jr z, .l48FA
	rlca
	ld l, TRK_FLOW
	res 4, [hl]
	res 5, [hl]
	ld l, TRK_PANFLAGS
	jr nc, .l48E4
	set 4, [hl]
	jr .l48E6
.l48E4:
	res 4, [hl]
.l48E6:
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
.l48FA:
	call WritePeriod
	ld l, TRK_ENVNO
	ld a, [hl]
	or a
	jr z, .l4916
	ld l, TRK_FLOW
	ld a, [hl]
	and $3F
	ld [hl-], a
	set 3, [hl]
	ld l, TRK_ENVPTR
	ld a, [hl+]
	ld b, [hl]
	inc l
	ld [hl+], a
	ld [hl], b
	ld c, a
	jp EnvelopeStep
.l4916:
	ld l, TRK_VOL
	ld a, [hl]
	ld l, TRK_ATTEN
	sub [hl]
	ld b, a
	ld a, [wTrackDesc]
	bit 6, a
	ld a, b
	jp nz, WriteVolume
	ld b, a
	ld a, [wFadeStep]
	or a
	ld a, b
	jp z, WriteVolume
	ld l, TRK_PANFLAGS
	bit 7, [hl]
	jr z, .l493F
	res 7, [hl]
	ld l, TRK_GATE
	ld [hl], $08
	ld l, TRK_ENV
	ld [hl], $00
.l493F:
	xor a
	ld l, TRK_RELVOL
	ld [hl], a
	ld a, [wTrackDesc]
	and $0F
	cp $02
	ld a, [wFadeStep]
	ld c, a
	ld a, b
	jr nz, .l4960
	add a, c
	jr c, .l4959
	cp $70
	jp c, WriteVolume
.l4959:
	xor a
	ld l, TRK_ID
	ld [hl], a
	jp WriteVolume
.l4960:
	sub c
	jp nc, WriteVolume
	jp MutedByte

Sustain:
	ld a, [wTrackDesc]
	cp $63
	ret z
	cp $34
	ret z
	ld l, TRK_FLAGS
	bit 0, [hl]
	ret nz

; InstrumentTick (Sustain, notes only): when TRK_INSTIMER runs out, read the next step:
; ticks, a wave byte (swapped and written as the duty; on CH3 the wave, keeping NR32, and
; only while Sfx2 is idle), and a signed period offset (TRK_INSOFS, added to every period
; written while the macro runs). $FE marks / jumps back to the mark, $FF ends the macro.
; Bug: for a music track while Sfx2 plays, the skipped wave byte is stored to $0065 (a ROM
; address - an MBC register write) instead of the track field $65.
InstrumentTick:
	ld l, TRK_INSFLAGS
	ld a, [hl]
	and a
	jr z, InstrumentWaveBug.l49ED
	ld l, TRK_INSTIMER
	dec [hl]
	jr nz, InstrumentWaveBug.l49ED
	inc l
	ld c, [hl]
	inc l
	ld b, [hl]
.l4984:
	ld a, [bc]
	cp $FF
	jr z, InstrumentWaveBug.l49E9
	cp $FE
	jr z, .l49B4
	ld l, TRK_INSTIMER
	ld [hl], a
	inc bc
	ld a, [bc]
	inc bc
	push af
	ld a, $D1
	cp h
	jr z, .l49A2
	push hl
	ld h, a
	ld l, TRK_ID
	ld a, [hl]
	pop hl
	or a
	jr nz, InstrumentWaveBug
.l49A2:
	pop af
	push bc
	swap a
	ld b, a
	ldh a, [rNR32]
	push af
	ld a, b
	call WriteDuty
	pop af
	ldh [rNR32], a
	pop bc
	jr InstrumentWaveBug.l49D4
.l49B4:
	ld l, TRK_INSFLAGS
	ld a, [hl]
	and $08
	jr nz, .l49C9
	inc bc
	ld l, TRK_INSMARK
	ld [hl], c
	inc l
	ld [hl], b
	ld l, TRK_INSFLAGS
	ld a, $08
	or [hl]
	ld [hl], a
	jr .l4984
.l49C9:
	ld l, TRK_INSMARK
	ld c, [hl]
	inc l
	ld b, [hl]
	jr .l4984

InstrumentWaveBug:
	pop af
	ld [$0065], a
.l49D4:
	ld a, [bc]
	inc bc
	ld l, TRK_INSOFS
	ld [hl+], a
	bit 7, a
	ld a, $00
	jr z, .l49E1
	ld a, $FF
.l49E1:
	ld [hl], a
	ld l, TRK_INSPTR
	ld [hl], c
	inc l
	ld [hl], b
	jr .l49ED
.l49E9:
	xor a
	ld l, TRK_INSFLAGS
	ld [hl], a
.l49ED:
	ld l, TRK_DUTYCNT
	ld a, [hl+]
	or a
	jr z, .l49FC
	dec [hl]
	jr nz, .l49FC
	ld l, TRK_DUTY
	ld a, [hl]
	call WriteDuty
.l49FC:
	ld l, TRK_VIB
	ld a, [hl]
	or a
	jr z, .l4A33
	ld l, TRK_PANFLAGS
	bit 2, [hl]
	jr z, .l4A33
	ld l, $35
	ld a, [hl]
	or a
	jr z, .l4A11
	dec [hl]
	jr .l4A33
.l4A11:
	ld l, $33
	dec [hl]
	jr nz, .l4A33
	ld l, $31
	ld c, [hl]
	inc l
	ld b, [hl]
	call VibratoStep
	ld l, TRK_INSFLAGS
	ld a, [hl]
	and a
	jr z, .l4A2E
	push hl
	ld l, TRK_INSOFS
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	add hl, de
	ld e, l
	ld d, h
	pop hl
.l4A2E:
	call WritePeriod
	jr .l4A4B
.l4A33:
	ld l, TRK_INSFLAGS
	ld a, [hl]
	and a
	jr z, .l4A4B
	push hl
	ld l, TRK_PERIOD + 1
	ld d, [hl]
	dec l
	ld e, [hl]
	ld l, TRK_INSOFS
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	add hl, de
	ld e, l
	ld d, h
	pop hl
	call WritePeriod
.l4A4B:
	ld l, TRK_ENVNO
	ld a, [hl]
	or a
	jp z, ReleaseTick
	ld l, TRK_PANFLAGS
	bit 3, [hl]
	jp z, ReleaseTick
	ld l, TRK_ENVTIMER
	dec [hl]
	ret nz
	ld l, TRK_ENVPOS
	ld c, [hl]
	inc l
	ld b, [hl]
	jp EnvelopeStep

VibratoStep:
	ld a, [bc]
	cp $FF
	jp z, VibratoStep2.l4AED
	cp $FE
	jp z, VibratoStep2.l4B23
	cp $FB
	jp z, VibratoStep2.l4AF7

VibratoStep2:
	ld l, $33
	cp $F0
	jr c, .l4AAA
	and $0F
	ld [hl], a
	inc bc
	ld a, [bc]
	inc bc
	ld l, $31
	ld [hl], c
	inc l
	ld [hl], b
	ld d, $00
	bit 7, a
	jr z, .l4A8D
	dec d
.l4A8D:
	ld e, a
	ld l, $36
	ld a, [hl]
	or a
	jr z, .l4AE7
	ld b, h
	ld hl, $0000
.l4A98:
	add hl, de
	dec a
	jr nz, .l4A98
	ld e, l
	ld d, h
	ld h, b
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
.l4AAA:
	and $F0
	swap a
	ld [hl], a
	ld a, [bc]
	ld l, $31
	inc bc
	ld [hl], c
	inc l
	ld [hl], b
	and $0F
	jr z, .l4AE7
	ld l, TRK_PANFLAGS
	bit 4, [hl]
	jr nz, VibratoSemitone
	ld l, $36
	ld e, a
	ld d, $00
	bit 3, a
	jr z, .l4AD1
	and $07
	jr z, .l4AE7
	cpl
	inc a
	ld e, a
	dec d
.l4AD1:
	ld a, [hl]
	or a
	jr z, .l4ADC
	ld b, a
	xor a
.l4AD7:
	add a, e
	dec b
	jr nz, .l4AD7
	ld e, a
.l4ADC:
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
.l4AE7:
	ld l, TRK_PERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ret
.l4AED:
	ld l, TRK_PANFLAGS
	res 2, [hl]
	ld l, TRK_OUTPERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ret
.l4AF7:
	ld l, TRK_FLOW
	inc bc
	bit 4, [hl]
	jr nz, .l4B0B
	set 4, [hl]
	ld l, $37
	ld [hl], c
	inc l
	ld [hl], b
	inc l
	ld [hl], $00
	jp VibratoStep
.l4B0B:
	ld a, [bc]
	ld l, $39
	inc [hl]
	cp [hl]
	jr z, .l4B19
	dec l
	ld b, [hl]
	dec l
	ld c, [hl]
	jp VibratoStep
.l4B19:
	ld [hl], $00
	ld l, TRK_FLOW
	res 4, [hl]
	inc bc
	jp VibratoStep
.l4B23:
	ld l, TRK_FLOW
	bit 5, [hl]
	jr nz, .l4B34
	set 5, [hl]
	inc bc
	ld l, $3A
	ld [hl], c
	inc l
	ld [hl], b
	jp VibratoStep
.l4B34:
	ld l, $3A
	ld c, [hl]
	inc l
	ld b, [hl]
	jp VibratoStep

VibratoSemitone:
	cp $0D
	jr c, .l4B4D
	sub $0D
	jr z, .l4B4B
	dec a
	jr z, .l4B49
	add a, $0B
.l4B49:
	add a, $05
.l4B4B:
	add a, $13
.l4B4D:
	rlca
	ld c, a
	ld l, TRK_PITCHIDX
	ld a, [hl]
	add a, c
	ld e, a
	ld d, $00
	ld l, TRK_DETUNE
	ld a, [hl+]
	ld c, [hl]
	push hl
	ld hl, PeriodTable - 26
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld h, c
	ld l, a
	add hl, de
	ld e, l
	ld d, h
	pop hl
	ret

EnvelopeStep:
	ld a, [bc]
	cp $FF
	jr z, .l4BB9
	cp $FE
	jr z, .l4BE9
	cp $FB
	jr z, .l4BBE
	ld l, TRK_ENVTIMER
	and $F0
	swap a
	ld [hl], a
	ld a, [bc]
	ld l, TRK_ENVPOS
	inc bc
	ld [hl], c
	inc l
	ld [hl], b
	and $0F
	swap a
	ld l, TRK_ATTEN
	sub [hl]
	jr c, .l4BB4
	ld b, a
	ld a, [wFadeStep]
	or a
	ld a, b
	jp z, WriteVolume
	ld a, [wTrackDesc]
	and $0F
	cp $02
	ld a, [wFadeStep]
	ld c, a
	ld a, b
	jr nz, .l4BB0
	add a, c
	jr c, .l4BAC
	cp $70
	jp c, WriteVolume
.l4BAC:
	xor a
	jp WriteVolume
.l4BB0:
	sub c
	jp nc, WriteVolume
.l4BB4:
	ld a, $08
	jp WriteVolume
.l4BB9:
	ld l, TRK_PANFLAGS
	res 3, [hl]
	ret
.l4BBE:
	ld l, TRK_FLOW
	inc bc
	bit 6, [hl]
	jr nz, .l4BD1
	set 6, [hl]
	ld l, TRK_ENVLOOPPTR
	ld [hl], c
	inc l
	ld [hl], b
	inc l
	ld [hl], $00
	jr EnvelopeStep
.l4BD1:
	ld a, [bc]
	ld l, TRK_ENVLOOPCNT
	inc [hl]
	cp [hl]
	jr z, .l4BDF
	dec l
	ld b, [hl]
	dec l
	ld c, [hl]
	jp EnvelopeStep
.l4BDF:
	ld [hl], $00
	ld l, TRK_FLOW
	res 6, [hl]
	inc bc
	jp EnvelopeStep
.l4BE9:
	ld l, TRK_FLOW
	bit 7, [hl]
	jr nz, .l4BFA
	set 7, [hl]
	inc bc
	ld l, TRK_ENVMARK
	ld [hl], c
	inc l
	ld [hl], b
	jp EnvelopeStep
.l4BFA:
	ld l, TRK_ENVMARK
	ld c, [hl]
	inc l
	ld b, [hl]
	jp EnvelopeStep

ReleaseTick:
	ld l, TRK_LEN
	ld a, [wTrackDesc]
	cp $22
	ld a, [hl]
	ld l, TRK_RELTICK
	jp z, ReleaseCh3
	cp [hl]
	jr z, .l4C20
	ret c
	ld l, TRK_FLAGS
	bit 2, [hl]
	ret z
	res 2, [hl]
	ld l, TRK_LASTVOL
	ld a, [hl]
	jp WriteVolume
.l4C20:
	ld l, TRK_PANFLAGS
	bit 7, [hl]
	jr z, .l4C60
	ld l, TRK_ENV
	ld a, [hl]
	or a
	jr z, .l4C8D
	bit 3, [hl]
	jr z, .l4C34
	and $0F
	jr .l4C3B
.l4C34:
	ld b, a
	ld l, TRK_LASTVOL
	ld a, [hl]
	and $F0
	or b
.l4C3B:
	ld l, TRK_REG_NRX2
	ld c, [hl]
	call WriteRegChecked
	ret nc
	ld l, TRK_SAVEPERIOD + 1
	ld a, [hl]
	or a
	jr z, .l4C7C
	ld l, TRK_REG_NRX3
	ld c, [hl]
	ld l, TRK_SAVEPERIOD
	ld a, [hl]
	ldh [c], a
	ld l, TRK_REG_NRX4
	ld c, [hl]
	ld l, TRK_SAVEPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ld l, TRK_REG_NRX1
	ld c, [hl]
	ldh a, [c]
	and $C0
	ldh [c], a
	ret
.l4C60:
	ld l, TRK_RELVOL
	ld a, [hl]
	or a
	jp nz, WriteVolume
	ld l, TRK_ENV
	ld a, [hl]
	or a
	jp z, .l4C8D
	ld b, a
	ld l, TRK_LASTVOL
	ld a, [hl]
	and $F0
	or b
	ld l, TRK_REG_NRX2
	ld c, [hl]
	call WriteRegChecked
	ret nc
.l4C7C:
	ld l, TRK_REG_NRX4
	ld c, [hl]
	ld l, TRK_OUTPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ld l, TRK_REG_NRX1
	ld c, [hl]
	ldh a, [c]
	and $C0
	ldh [c], a
	ret
.l4C8D:
	ld a, $08
	jp WriteVolume

ReleaseCh3:
	cp [hl]
	inc hl
	jr c, .l4CA8
	jr z, .l4CA5
	ld l, TRK_FLAGS
	bit 2, [hl]
	ret z
	res 2, [hl]
	ld l, TRK_LASTVOL
	ld a, [hl]
	jp WriteVolume
.l4CA5:
	ld a, [hl+]
	ld [hl], a
	ret
.l4CA8:
	ld l, TRK_RELVOL
	ld a, [hl]
	or a
	jp nz, WriteVolume
	ld l, TRK_ENV
	ld a, [hl+]
	or a
	jp z, WriteVolume
	dec [hl]
	ret nz
	dec l
	ld a, [hl+]
	ld [hl], a
	ld l, TRK_LASTVOL
	ld a, [hl]
	and $F0
	cp $61
	ret nc
	add a, $20
	jp WriteVolume

; DrumNote: hi nibble = hit id (13: the next byte is the id), read from table set
; wDrumSet, started on the SFX tracks of its header with the priority test.
DrumNote:
	ld a, [wReadBuf]
	and $F0
	swap a
	cp $0D
	jr nz, .l4CDD
	ld a, [wReadBuf + $01]
	inc de
	ld l, TRK_PTR
	ld [hl], e
	ld l, TRK_PTR + 1
	ld [hl], d
.l4CDD:
	ld [wReqId], a
	ld a, [wDrumSet]
	ld hl, SoundTableSets
	call LoadPtrIndexed
	ld a, [wReqId]
	call LoadPtrIndexed
	ld a, [hl+]
	ld [wReqPrio], a
	ld b, [hl]
	inc hl
	ld d, h
	ld e, l
	srl b
	ld hl, wTrkSfx1
	call c, DrumHitTrack
	srl b
	ld hl, wTrkSfx2
	call c, DrumHitTrack
	srl b
	ld hl, wTrkSfxN
	ret nc

DrumHitTrack:
	push bc
	ld a, [hl]
	and $0F
	ld b, a

StartDrumHit:
	ld a, [wReqPrio]
	and $0F
	cp b
	pop bc
	jp c, DrumHitRefused
	ld a, [wReqPrio]
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
	ld [hl], a
	ld l, TRK_ATTEN
	ld [hl], a
	ld l, TRK_VIB
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl], a
	ld a, $D0
	cp h
	jr nz, .l4D48
	ld a, $08
	ld c, $10
	ldh [c], a
.l4D48:
	ld a, $D2
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

DrumHitRefused:
	inc de
	inc de
	ret

NoiseNote:
	ld l, TRK_UNIT
	ld a, [hl]
	ld l, TRK_LEN
	ld [hl], a
	ld a, [wReadBuf]
	call SavePtr
	cp $C0
	jr nc, NoiseVolume
	ld e, a
	ld d, $00
	call WritePeriod
	ld l, TRK_PANFLAGS
	bit 0, [hl]
	call nz, AutoPan
	ld l, TRK_FLAGS
	bit 7, [hl]
	ld l, TRK_LASTVOL
	ld a, [hl]
	jp z, WriteVolumeNoise
	jp WriteVolumeNow0.l4E6F

NoiseVolume:
	cp $D0
	jr nc, .l4D97
	ld l, TRK_FLAGS
	set 6, [hl]
	call SetNoiseVol
	call WriteVolumeNoise
	jp ReadCmds
.l4D97:
	jp z, WriteVolume8
	call SetNoiseVol
	jp WriteVolume

SetNoiseVol:
	and $0F
	swap a
	ld b, a
	ld l, TRK_LASTVOL
	ld a, [hl]
	and $0F
	or b
	ld [hl], a
	ret

SavePtr:
	inc de
	ld l, TRK_PTR
	ld [hl], e
	inc l
	ld [hl], d
	ret

GiveBack:
	ld l, TRK_FLAGS
	ld a, $24
	or [hl]
	ld [hl], a
	ld b, $EE
	ld a, [wTrackDesc]
	and $0F
	jr z, .l4DC8
.l4DC3:
	rlc b
	dec a
	jr nz, .l4DC3
.l4DC8:
	ld c, $25
	ldh a, [c]
	and b
	ld l, TRK_PAN
	or [hl]
	ldh [c], a
	ld l, TRK_OUTPERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	jp WritePeriod

LoadPtrIndexedB:
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
	ld l, TRK_OUTPERIOD
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
	ld l, TRK_REG_NRX1
	ld c, [hl]
	ldh a, [c]
	and $C0
	ldh [c], a
	ret

MuteChannel:
	ld a, [wTrackDesc]
	and $0F
	cp $02
	jr z, .l4E21
	ld a, $08
	ld l, TRK_REG_NRX2
	ld c, [hl]
	call WriteRegChecked
	ret nc
	ld l, TRK_REG_NRX4
	ld a, $80
	ld c, [hl]
	ldh [c], a
	ld l, TRK_REG_NRX1
	ld c, [hl]
	ldh a, [c]
	and $C0
	ldh [c], a
	ret
.l4E21:
	xor a
	ld c, $1C
	jp WriteRegChecked

MutedByte:
	call SavePtr

WriteVolume8:
	ld a, $08

WriteVolumeNoise:
	ld l, TRK_FLAGS
	bit 6, [hl]
	jr nz, WriteVolumeNow0

WriteVolume:
	ld l, TRK_REG_NRX2
	ld c, [hl]
	ld l, TRK_LASTVOL
	ld [hl], a
	ldh a, [c]
	cp [hl]
	jr nz, .l4E4F
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
.l4E4F:
	ld a, [hl]
	call WriteRegChecked
	ret nc
	ld a, [wTrackDesc]
	and $0F
	cp $02
	ret z
	ld l, TRK_REG_NRX4
	ld c, [hl]
	ld l, TRK_OUTPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ld l, TRK_REG_NRX1
	ld c, [hl]
	ldh a, [c]
	and $C0
	ldh [c], a
	ret

WriteVolumeNow0:
	res 6, [hl]
.l4E6F:
	push af
	ld a, [wTrackDesc]
	cp $63
	jr nz, .l4E97
	ld l, TRK_PRIO
	ld a, [hl]
	and $0F
	cp $02
	jr nz, .l4E97
	ld a, [wNoiseAtten]
	ld b, a
	pop af
	ld l, a
	and $F0
	swap a
	sub b
	jr nc, .l4E8E
	xor a
.l4E8E:
	swap a
	ld b, a
	ld a, l
	and $0F
	or b
	jr WriteVolumeNow
.l4E97:
	pop af

WriteVolumeNow:
	ld l, TRK_REG_NRX2
	ld c, [hl]
	ld l, TRK_LASTVOL
	ld [hl], a
	ldh [c], a
	ld l, TRK_REG_NRX4
	ld c, [hl]
	ld l, TRK_OUTPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	xor a
	ldh [rNR41], a
	ret

WriteDuty:
	ld b, a
	ld a, [wTrackDesc]
	and $0F
	cp $02
	jr z, WriteWave
	ld a, b
	ld l, TRK_CURDUTY
	ld [hl], a
	ld l, TRK_REG_NRX1
	ld c, [hl]
	jp WriteRegChecked

WriteWave:
	ld a, [wTrackDesc]
	cp $22
	jr nz, LoadWave
	push hl
	ld h, HIGH(wTrkSfx2)
	ld l, TRK_ID
	ld a, [hl]
	or a
	pop hl
	ld l, TRK_CURDUTY
	ld [hl], b
	ret nz

LoadWave:
	ld a, [wWaveId]
	cp b
	ret z
	ld a, b
	ld l, TRK_CURDUTY
	ld [hl], a
	ld [wWaveId], a
	push hl
	xor a
	ld c, $1A
	ldh [c], a
	ld c, $1C
	ldh [c], a
	ld a, b
	swap a
	ld hl, WaveTable
	sla a
	ld b, $00
	rl b
	ld c, a
	add hl, bc
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ld a, [hl+]
	ldh [_AUD3WAVERAM], a
	ld a, [hl+]
	ldh [$FF31], a
	ld a, [hl+]
	ldh [$FF32], a
	ld a, [hl+]
	ldh [$FF33], a
	ld a, [hl+]
	ldh [$FF34], a
	ld a, [hl+]
	ldh [$FF35], a
	ld a, [hl+]
	ldh [$FF36], a
	ld a, [hl+]
	ldh [$FF37], a
	ld a, [hl+]
	ldh [$FF38], a
	ld a, [hl+]
	ldh [$FF39], a
	ld a, [hl+]
	ldh [$FF3A], a
	ld a, [hl+]
	ldh [$FF3B], a
	ld a, [hl+]
	ldh [$FF3C], a
	ld a, [hl+]
	ldh [$FF3D], a
	ld a, [hl+]
	ldh [$FF3E], a
	ld a, [hl]
	ldh [$FF3F], a
	pop hl
	ld a, $80
	ld c, $1A
	ldh [c], a
	ld l, TRK_REG_NRX4
	ld c, [hl]
	ld l, TRK_OUTPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ld l, TRK_REG_NRX1
	ld c, [hl]
	ldh a, [c]
	and $C0
	ldh [c], a
	ret

WriteRegChecked:
	ld b, a
	push hl
	ld a, [wTrackDesc]
	cp $00
	jr z, .l4F58
	cp $22
	jr nz, .l4F63
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
.l4F58:
	ld hl, wTrkSfx1 + $01
	ld a, [hl]
	or a
	pop hl
	ret nz
	ld a, b
	ldh [c], a
	scf
	ret
.l4F63:
	pop hl
	ld a, b
	ldh [c], a
	scf
	ret

; StopAll: fade, wobble and all track ids cleared; the channels muted; NR51 = $FF; NR50 =
; $77.
StopAll:
	xor a
	ld [wFadeStep], a
	ld [wFadeRate], a
	ld [wFadeTimer], a
	ld [wFadeDir], a
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
	ld [wWobbleOn], a
	ld [wReqHold], a
	ld hl, wTrkCh3 + $59
	ld [hl], a
	ld h, HIGH(wTrkSfx2)
	ld [hl], a
	ld a, $08
	ld c, $12
	ldh [c], a
	ld c, $17
	ldh [c], a
	ld c, $21
	ldh [c], a
	xor a
	ld c, $1A
	ldh [c], a
	ld c, $1C
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
	ld [wNR51Copy], a
	ld a, $08
	ld c, $10
	ldh [c], a
	ld c, $24
	ld a, $77
	ldh [c], a
	ret

Command:
	inc de
	sub $E0
	jp z, Cmd_Voice
	cp $07
	jp c, Cmd_Octave
	ld l, TRK_FLAGS
	bit 1, [hl]
	jr nz, CommandVol
	push hl
	ld hl, CommandTable - 14
	call LoadPtrIndexed
	ld a, [wReadBuf + $01]
	jp hl
CommandTable:
	dw Cmd_LenUnit
	dw Cmd_Release
	dw Cmd_Sweep
	dw Cmd_Ext
	dw Cmd_Vibrato
	dw Cmd_Envelope
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
	dw Cmd_LoopBreak
	dw Cmd_Jump
	dw Cmd_Loop1
	dw Cmd_Loop2
	dw Cmd_CallRet
	dw Cmd_Mark
	dw Cmd_End

CommandVol:
	cp $07
	jp c, Cmd_Octave
	push hl
	ld hl, CommandTableVol - 14
	call LoadPtrIndexed
	ld a, [wReadBuf + $01]
	jp hl
CommandTableVol:
	dw Cmd_LenUnit
	dw Cmd_Release
	dw Cmd_Sweep
	dw Cmd_Ext
	dw Cmd_Vibrato
	dw Cmd_Envelope
	dw Cmd_DutyStep
	dw Cmd_Slide
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
	dw Cmd_LoopBreak
	dw Cmd_Jump
	dw Cmd_Loop1
	dw Cmd_Loop2
	dw Cmd_CallRet
	dw Cmd_Mark
	dw Cmd_End

Cmd_Voice:
	ld a, [wReadBuf + $01]
	and $7F
	ld l, TRK_UNIT
	ld [hl], a
	ld a, [wTrackDesc]
	cp $63
	ld a, [wReadBuf + $01]
	jp nz, VoiceTone
	bit 7, a
	ld l, TRK_FLAGS
	jr z, VoiceNoiseVol
	set 7, [hl]
	jr VoiceNoiseArg

VoiceNoiseVol:
	res 7, [hl]
	set 6, [hl]

VoiceNoiseArg:
	inc de
	ld a, [wReadBuf + $02]
	ld l, TRK_LASTVOL
	ld [hl], a
	call WriteVolumeNow0.l4E6F
	inc de
	jp ReadCmds

VoiceTone:
	bit 7, a
	ld l, TRK_FLAGS
	inc de
	jp nz, VoiceVol
	res 1, [hl]
	ld a, [wReadBuf + $02]
	and $F0
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	ld a, [wReadBuf + $02]
	and $0F
	swap a
	ld l, TRK_VOL
	ld [hl], a
	inc de
	or a
	jr z, VoiceEnvelope
	ld a, [wReadBuf + $03]
	and $F0
	swap a
	ld l, TRK_GATE
	ld [hl], a
	ld a, [wReadBuf + $03]
	and $0F
	ld l, TRK_ENV
	ld [hl], a
	xor a
	ld l, TRK_ENVNO
	ld [hl], a

VoiceEnd:
	call PanBoth
	xor a
	ld l, TRK_ATTEN
	ld [hl], a
	ld l, TRK_RELVOL
	ld [hl], a
	inc de
	jp ReadCmds

VoiceEnvelope:
	ld a, [wReadBuf + $03]
	ld l, TRK_ENVNO
	ld [hl], a
	push hl
	ld hl, EnvelopeTable - 2
	call LoadPtrIndexed
	ld b, h
	ld a, l
	pop hl
	ld l, TRK_ENVPTR
	ld [hl+], a
	ld [hl], b
	jr VoiceEnd

VoiceVol:
	set 1, [hl]
	ld a, [wReadBuf + $02]
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	inc de
	ld a, [wTrackDesc]
	and $0F
	jp nz, .l510B
	ld c, $10
	ld a, [wReadBuf + $03]
	ldh [c], a
.l510B:
	call PanBoth
	inc de
	jp ReadCmds

Cmd_Octave:
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
	inc de
	jp ReadCmds

Cmd_Release:
	pop hl
	ld l, TRK_ENV
	and $0F
	ld [hl], a
	ld a, [wReadBuf + $01]
	and $F0
	swap a
	ld l, TRK_GATE
	ld [hl], a
	xor a
	ld l, TRK_RELVOL
	ld [hl], a
	ld l, TRK_ENVNO
	ld [hl], a
	inc de
	jp ReadCmds

Cmd_Sweep:
	pop hl
	ld c, $10
	ldh [c], a
	inc de
	jp ReadCmds

Cmd_Ext:
	swap a
	and $0F
	ld hl, ExtTable
	call LoadPtrIndexed
	ld a, [wReadBuf + $01]
	jp hl

; ExtTable: $EA xy, 16 entries: 1 = pan both ($EA 10) / instrument ($EA 11 n), 6 = pan
; both, D = noise attenuation, F = drum set.
ExtTable:
	dw Ext_Duty
	dw Ext_Sub1
	dw Ext_PanLeft
	dw Ext_PanRight
	dw Ext_Autopan
	dw Ext_AutopanBoth
	dw Ext_PanBoth2
	dw Ext_TransposeUp
	dw Ext_TransposeDown
	dw Ext_ReleaseVol
	dw Ext_Wobble
	dw Ext_HoldSet
	dw Ext_Flag7
	dw Ext_NoiseAtten
	dw Ext_HoldClr
	dw Ext_DrumSet

Ext_Duty:
	pop hl
	cp $0F
	jr nz, .l518A
	ld a, [wReadBuf + $02]
	inc de
.l518A:
	swap a
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	inc de
	jp ReadCmds

Ext_Sub1:
	and $0F
	ld hl, ExtSub1Table
	call LoadPtrIndexed
	ld a, [wReadBuf + $01]
	jp hl
ExtSub1Table:
	dw Ext_PanBoth
	dw Ext_Instrument

; Ext_Instrument: $EA 11 n: TRK_INSTR = n (0 = off), TRK_INSFLAGS/TIMER = 1, the macro
; pointer from MacroTable, the rest of the macro fields cleared (3 bytes).
Ext_Instrument:
	pop hl
	inc de
	ld a, [wReadBuf + $02]
	inc de
	ld l, TRK_INSTR
	ld [hl+], a
	and a
	jr nz, .l51B6
	ld [hl], a
	jp ReadCmds
.l51B6:
	ld a, $01
	ld [hl+], a
	ld [hl+], a
	push hl
	ld hl, MacroTable - 2
	call LoadPtrIndexed
	ld b, h
	ld c, l
	pop hl
	ld a, c
	ld [hl+], a
	ld a, b
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
	jp ReadCmds

Ext_PanBoth:
	pop hl
	ld l, TRK_PANFLAGS
	res 0, [hl]
	call PanBoth
	inc de
	jp ReadCmds

PanBoth:
	ld b, $11
	ld a, [wTrackDesc]
	and $0F
	or a
	jr z, .l51EF
.l51EA:
	sla b
	dec a
	jr nz, .l51EA
.l51EF:
	ld c, $25
	ldh a, [c]
	ld l, TRK_PAN
	ld [hl], b
	or b
	jp WriteRegChecked

Ext_PanLeft:
	pop hl
	call PanLeft
	inc de
	jp ReadCmds

Ext_PanRight:
	pop hl
	call PanRight
	inc de
	jp ReadCmds

AutoPan:
	bit 6, [hl]
	jp nz, .l5218
	bit 1, [hl]
	jp nz, PanRight.l5245
	set 1, [hl]
	jp PanRight
.l5218:
	bit 1, [hl]
	jp z, .l5222
	res 1, [hl]
	jp PanBoth
.l5222:
	set 1, [hl]

PanRight:
	ld b, $EE
	ld l, TRK_ID
	ld a, [wTrackDesc]
	and $0F
	or a
	jp z, .l5239
.l5231:
	rlc b
	rlc l
	dec a
	jp nz, .l5231
.l5239:
	ld c, $25
	ldh a, [c]
	and b
	or l
	ld b, l
	ld l, TRK_PAN
	ld [hl], b
	jp WriteRegChecked
.l5245:
	res 1, [hl]

PanLeft:
	ld b, $EE
	ld l, TRK_SEGNO + 1
	ld a, [wTrackDesc]
	and $0F
	or a
	jr z, .l525A
.l5253:
	rlc b
	rlc l
	dec a
	jr nz, .l5253
.l525A:
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
	ld l, TRK_PANFLAGS
	set 0, [hl]
	res 1, [hl]
	res 6, [hl]
	inc de
	jp ReadCmds

Ext_AutopanBoth:
	pop hl
	ld l, TRK_PANFLAGS
	set 0, [hl]
	set 6, [hl]
	set 1, [hl]
	inc de
	jp ReadCmds

Ext_PanBoth2:
	pop hl
	ld l, TRK_PANFLAGS
	res 0, [hl]
	call PanBoth
	inc de
	jp ReadCmds

Ext_TransposeUp:
	pop hl
	and $0F
	rlca
	ld l, TRK_TRANSP
	ld [hl], a
	inc de
	jp ReadCmds

Ext_TransposeDown:
	pop hl
	and $0F
	jp z, .l52A0
	rlca
	cpl
	inc a
.l52A0:
	ld l, TRK_TRANSP
	ld [hl], a
	inc de
	jp ReadCmds

Ext_ReleaseVol:
	pop hl
	and $0F
	swap a
	ld l, TRK_RELVOL
	ld [hl], a
	inc de
	jp ReadCmds

Ext_Wobble:
	pop hl
	inc de
	inc de
	ld a, [wFadeRate]
	or a
	jp nz, ReadCmds
	ld a, [wSndDim]
	set 0, a
	ld a, [wReadBuf + $02]
	or a
	jr z, .l52E9
	and $0F
	res 3, a
	ld b, a
	ld a, $07
	sub b
	ld [wWobbleMin], a
	ld a, [wReadBuf + $02]
	and $F0
	swap a
	ld [wWobbleRate], a
	dec a
	ld [wWobbleTimer], a
	ld a, $01
	ld [wWobbleOn], a
	jp ReadCmds
.l52E9:
	ld a, [wSndDim]
	res 0, a
	ld [wWobbleOn], a
	ld c, $24
	ld a, $77
	ldh [c], a
	jp ReadCmds

Ext_Flag7:
	pop hl
	and $0F
	jr z, .l5306
	ld l, TRK_PANFLAGS
	set 7, [hl]
	inc de
	jp ReadCmds
.l5306:
	ld l, TRK_PANFLAGS
	res 7, [hl]
	inc de
	jp ReadCmds

Ext_NoiseAtten:
	pop hl
	and $0F
	ld [wNoiseAtten], a
	inc de
	jp ReadCmds

Cmd_Vibrato:
	pop hl
	ld l, TRK_VIB
	ld [hl], a
	or a
	jp z, .l5365
	bit 7, [hl]
	jp nz, VibratoSemi
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
	ld a, [wReadBuf + $02]
	and $F0
	swap a
	ld l, TRK_UNIT
	ld c, [hl]
	jp z, .l535B
	ld b, a
	xor a
	bit 0, b
	jp nz, .l5356
	rrc b
.l534D:
	add a, c
	dec b
	jp nz, .l534D
	add a, a
	jp .l535B
.l5356:
	add a, c
	dec b
	jp nz, .l5356
.l535B:
	ld l, $34
	ld [hl+], a
	ld a, [wReadBuf + $02]
	and $0F
	inc l
	ld [hl], a
.l5365:
	inc de
	jp ReadCmds

VibratoSemi:
	and $7F
	push hl
	ld hl, Vibrato2Table - 2
	call LoadPtrIndexed
	ld b, h
	ld a, l
	pop hl
	ld l, TRK_VIBPTR
	ld [hl+], a
	ld [hl], b
	ld l, $34
	ld [hl], $00
	inc de
	jp ReadCmds

Cmd_Envelope:
	pop hl
	ld l, TRK_ENVNO
	ld [hl], a
	or a
	jr z, .l5397
	push hl
	ld hl, EnvelopeTable - 2
	call LoadPtrIndexed
	ld b, h
	ld c, l
	pop hl
	ld l, TRK_ENVPTR
	ld [hl], c
	inc l
	ld [hl], b
.l5397:
	inc de
	jp ReadCmds

Cmd_DutyStep:
	pop hl
	and $F0
	ld l, TRK_DUTYSTART
	ld [hl-], a
	ld a, [wReadBuf + $01]
	and $0F
	ld [hl-], a
	ld [hl], a
	or a
	ld l, TRK_DUTY
	ld a, [hl]
	call z, WriteDuty
	inc de
	jp ReadCmds

Cmd_Slide:
	pop hl
	ld l, TRK_PANFLAGS
	bit 5, [hl]
	jr nz, .l53C7
	set 5, [hl]
	ld l, TRK_SLIDEPTR
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	ld [hl], $00
	jp ReadCmds
.l53C7:
	ld b, $00
	ld a, [wReadBuf + $01]
	bit 7, a
	ld c, a
	ld l, TRK_F4
	jr nz, .l53D5
	jr .l53D6
.l53D5:
	dec b
.l53D6:
	push hl
	ld l, TRK_SLIDEOFS
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	add hl, bc
	ld c, l
	ld b, h
	pop hl
	ld l, TRK_SLIDEOFS
	ld [hl], c
	inc l
	ld [hl], b
	inc de
	ld a, [wReadBuf + $02]
	bit 7, a
	ld l, TRK_SLIDEATTCNT
	jr nz, .l5404
	bit 6, a
	jr nz, .l53F8
	sub $01
	cpl
	jr .l5412
.l53F8:
	and $0F
	inc [hl]
	cp [hl]
	jr nz, .l541A
	ld [hl], $00
	ld a, $0F
	jr .l5412
.l5404:
	bit 6, a
	jr z, .l5412
	and $0F
	inc [hl]
	cp [hl]
	jr nz, .l541A
	ld [hl], $00
	ld a, $01
.l5412:
	and $0F
	swap a
	ld l, TRK_ATTEN
	add a, [hl]
	ld [hl], a
.l541A:
	inc de
	ld a, [wReadBuf + $03]
	ld l, TRK_SLIDECNT
	inc [hl]
	cp [hl]
	jp z, .l542D
	ld l, TRK_SLIDEPTR
	ld e, [hl]
	inc l
	ld d, [hl]
	jp ReadCmds
.l542D:
	xor a
	ld [hl], a
	ld l, TRK_PANFLAGS
	res 5, [hl]
	ld l, TRK_ATTEN
	ld [hl], a
	ld l, TRK_SLIDECNT
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl], a
	inc de
	jp ReadCmds

; Cmd_Tempo: $EE x: wTempo = x (the accumulator and the speed-up cleared); $EE $80|n:
; wSpeedRate = wSpeedTimer = n.
Cmd_Tempo:
	pop hl
	inc de
	bit 7, a
	jr z, .l5452
	and $7F
	ld [wSpeedRate], a
	ld [wSpeedTimer], a
	jp ReadCmds
.l5452:
	ld [wTempo], a
	xor a
	ld [wTempoAcc], a
	ld [wSpeedRate], a
	jp ReadCmds

Cmd_Detune:
	pop hl
	ld l, TRK_DETUNE
	ld [hl+], a
	bit 7, a
	ld a, $00
	jp z, .l546C
	ld a, $FF
.l546C:
	ld [hl], a
	inc de
	jp ReadCmds

Cmd_Atten:
	pop hl
	dec de
	ld a, [wReadBuf]
	and $0F
	swap a
	jr z, .l548A
	ld b, a
	ld a, [wTrackDesc]
	and $0F
	cp $02
	ld a, b
	jr nz, .l548A
	sla a
	cpl
.l548A:
	ld l, TRK_ATTEN
	ld [hl], a
	inc de
	jp ReadCmds

Cmd_LoopBreak:
	pop hl
	bit 0, a
	jr z, .l54AD
	ld l, TRK_FLOW
	bit 0, [hl]
	jr z, .l54C6
	ld l, TRK_BREAK
	dec [hl]
	jr nz, .l54C6
	ld l, TRK_FLOW
	res 0, [hl]
	ld l, TRK_EXIT
	ld a, [hl+]
	ld d, [hl]
	ld e, a
	jp ReadCmds
.l54AD:
	ld l, TRK_FLOW
	bit 1, [hl]
	jr z, .l54C6
	ld l, TRK_BREAK2
	dec [hl]
	jr nz, .l54C6
	ld l, TRK_FLOW
	res 1, [hl]
	res 0, [hl]
	ld l, TRK_EXIT2
	ld a, [hl+]
	ld d, [hl]
	ld e, a
	jp ReadCmds
.l54C6:
	inc de
	jp ReadCmds

Cmd_Jump:
	pop hl
	inc de
	ld c, a
	ld a, [wReadBuf + $02]
	ld d, a
	ld e, c
	jp ReadCmds

Cmd_Loop1:
	pop hl
	ld l, TRK_FLOW
	bit 0, [hl]
	jp nz, .l54EA
	set 0, [hl]
	ld l, TRK_LOOPPTR
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	xor a
	ld [hl], a
	jp ReadCmds
.l54EA:
	ld l, TRK_BREAK
	ld a, [hl]
	cp $FF
	jr nz, .l54FF
	ld a, [wReadBuf + $01]
	ld l, TRK_BREAK
	ld [hl], a
	dec [hl]
	inc de
	ld l, TRK_EXIT
	ld [hl], e
	ld l, TRK_EXIT + 1
	ld [hl], d
.l54FF:
	ld a, [wReadBuf + $01]
	ld l, TRK_LOOPCNT
	inc [hl]
	cp [hl]
	jp z, .l5510
	dec l
	ld d, [hl]
	dec l
	ld e, [hl]
	jp ReadCmds
.l5510:
	ld [hl], $00
	ld l, TRK_FLOW
	res 0, [hl]
	inc de
	jp ReadCmds

Cmd_Loop2:
	pop hl
	ld l, TRK_FLOW
	bit 1, [hl]
	jp nz, .l552F
	set 1, [hl]
	ld l, TRK_LOOP2PTR
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	xor a
	ld [hl], a
	jp ReadCmds
.l552F:
	ld l, TRK_BREAK2
	ld a, [hl]
	cp $FF
	jr nz, .l5544
	ld a, [wReadBuf + $01]
	ld l, TRK_BREAK2
	ld [hl], a
	dec [hl]
	inc de
	ld l, TRK_EXIT2
	ld [hl], e
	ld l, TRK_EXIT2 + 1
	ld [hl], d
.l5544:
	ld a, [wReadBuf + $01]
	ld l, TRK_LOOP2CNT
	inc [hl]
	cp [hl]
	jp z, .l5555
	dec l
	ld d, [hl]
	dec l
	ld e, [hl]
	jp ReadCmds
.l5555:
	ld [hl], $00
	ld l, TRK_FLOW
	res 1, [hl]
	inc de
	jp ReadCmds

Cmd_CallRet:
	pop hl
	ld l, TRK_FLOW
	bit 2, [hl]
	jp nz, .l5579
	set 2, [hl]
	inc de
	ld c, a
	ld a, [wReadBuf + $02]
	inc de
	ld l, TRK_RET
	ld [hl], e
	inc l
	ld [hl], d
	ld e, c
	ld d, a
	jp ReadCmds
.l5579:
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
	jp nz, .l5595
	set 3, [hl]
	ld l, TRK_SEGNO
	ld [hl], e
	inc l
	ld [hl], d
	jp ReadCmds
.l5595:
	ld l, TRK_SEGNO
	ld e, [hl]
	inc l
	ld d, [hl]
	jp ReadCmds

Cmd_End:
	pop hl
	ld l, TRK_ID
	ld a, [hl]

EndTrack:
	xor a
	ld [hl-], a
	ld [hl], a
	ld a, [wTrackDesc]
	cp $34
	ret z
	cp $52
	jp z, .l55D7
	cp $40
	jp z, .l55C0
	cp $63
	jp nz, MuteChannel
	ld l, TRK_FLAGS
	res 3, [hl]
	jp MuteChannel
.l55C0:
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
.l55D7:
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

Ext_HoldSet:
	ld hl, wReqHold
	or [hl]
	ld [hl], a
	inc de
	pop hl
	jp ReadCmds

Ext_HoldClr:
	ld hl, wReqHold
	and [hl]
	ld [hl], a
	inc de
	pop hl
	jp ReadCmds

; Ext_DrumSet: $EA Fx: wDrumSet = x & 3.
Ext_DrumSet:
	and $03
	ld [wDrumSet], a
	inc de
	pop hl
	jp ReadCmds

; WaveTable: 96 pointers (the wave byte swapped, x 2), 90 waves.
WaveTable:
	dw Wave_56C7 ; wave 0
	dw Wave_56D7 ; wave 1
	dw Wave_56E7 ; wave 2
	dw Wave_56F7 ; wave 3
	dw Wave_5707 ; wave 4
	dw Wave_5717 ; wave 5
	dw Wave_5727 ; wave 6
	dw Wave_5737 ; wave 7
	dw Wave_5747 ; wave 8
	dw Wave_5757 ; wave 9
	dw Wave_5767 ; wave 10
	dw Wave_5777 ; wave 11
	dw Wave_5787 ; wave 12
	dw Wave_5797 ; wave 13
	dw Wave_57A7 ; wave 14
	dw Wave_57B7 ; wave 15
	dw Wave_57C7 ; wave 16
	dw Wave_57D7 ; wave 17
	dw Wave_57E7 ; wave 18
	dw Wave_57F7 ; wave 19
	dw Wave_5807 ; wave 20
	dw Wave_5817 ; wave 21
	dw Wave_5827 ; wave 22
	dw Wave_5837 ; wave 23
	dw Wave_5847 ; wave 24
	dw Wave_5857 ; wave 25
	dw Wave_5867 ; wave 26
	dw Wave_5877 ; wave 27
	dw Wave_5887 ; wave 28
	dw Wave_56C7 ; wave 29
	dw Wave_56C7 ; wave 30
	dw Wave_56C7 ; wave 31
	dw Wave_5897 ; wave 32
	dw Wave_58A7 ; wave 33
	dw Wave_58B7 ; wave 34
	dw Wave_58C7 ; wave 35
	dw Wave_58D7 ; wave 36
	dw Wave_58E7 ; wave 37
	dw Wave_58F7 ; wave 38
	dw Wave_5907 ; wave 39
	dw Wave_5917 ; wave 40
	dw Wave_5927 ; wave 41
	dw Wave_5937 ; wave 42
	dw Wave_5947 ; wave 43
	dw Wave_5957 ; wave 44
	dw Wave_56C7 ; wave 45
	dw Wave_56C7 ; wave 46
	dw Wave_56C7 ; wave 47
	dw Wave_5967 ; wave 48
	dw Wave_5977 ; wave 49
	dw Wave_5987 ; wave 50
	dw Wave_5997 ; wave 51
	dw Wave_59A7 ; wave 52
	dw Wave_59B7 ; wave 53
	dw Wave_59C7 ; wave 54
	dw Wave_59D7 ; wave 55
	dw Wave_59E7 ; wave 56
	dw Wave_59F7 ; wave 57
	dw Wave_5A07 ; wave 58
	dw Wave_5A17 ; wave 59
	dw Wave_5A27 ; wave 60
	dw Wave_5A37 ; wave 61
	dw Wave_5A47 ; wave 62
	dw Wave_5A57 ; wave 63
	dw Wave_5A67 ; wave 64
	dw Wave_5A77 ; wave 65
	dw Wave_5A87 ; wave 66
	dw Wave_5A97 ; wave 67
	dw Wave_5AA7 ; wave 68
	dw Wave_5AB7 ; wave 69
	dw Wave_5AC7 ; wave 70
	dw Wave_5AD7 ; wave 71
	dw Wave_5AE7 ; wave 72
	dw Wave_5AF7 ; wave 73
	dw Wave_5B07 ; wave 74
	dw Wave_5B17 ; wave 75
	dw Wave_5B27 ; wave 76
	dw Wave_5B37 ; wave 77
	dw Wave_5B47 ; wave 78
	dw Wave_5B57 ; wave 79
	dw Wave_5B67 ; wave 80
	dw Wave_5B77 ; wave 81
	dw Wave_5B87 ; wave 82
	dw Wave_5B97 ; wave 83
	dw Wave_5BA7 ; wave 84
	dw Wave_5BB7 ; wave 85
	dw Wave_5BC7 ; wave 86
	dw Wave_5BD7 ; wave 87
	dw Wave_5BE7 ; wave 88
	dw Wave_5BF7 ; wave 89
	dw Wave_5C07 ; wave 90
	dw Wave_5C17 ; wave 91
	dw Wave_5C27 ; wave 92
	dw Wave_5C37 ; wave 93
	dw Wave_5C47 ; wave 94
	dw Wave_5C57 ; wave 95
Wave_56C7:
	db $14, $7A, $FE, $CA, $97, $54, $35, $68, $9F, $ED, $CB, $AB, $DB, $97, $54, $62
Wave_56D7:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $10, $00, $00, $00, $00, $00, $00, $01
Wave_56E7:
	db $E7, $1E, $18, $D6, $A1, $99, $19, $51, $97, $C1, $79, $8C, $37, $57, $71, $77
Wave_56F7:
	db $F0, $FF, $C0, $CF, $80, $8F, $40, $4F, $00, $0F, $40, $4F, $80, $8F, $C0, $CF
Wave_5707:
	db $EE, $EE, $DC, $CB, $B9, $AA, $99, $98, $88, $87, $77, $77, $55, $54, $43, $21
Wave_5717:
	db $35, $79, $BD, $BA, $87, $75, $E6, $78, $AC, $DE, $DC, $BA, $98, $87, $76, $54
Wave_5727:
	db $58, $BD, $FE, $CA, $A8, $B5, $D4, $E2, $D1, $B2, $94, $76, $94, $C2, $E3, $C6
Wave_5737:
	db $DE, $FF, $FF, $FF, $FF, $FF, $FF, $ED, $21, $00, $00, $00, $00, $00, $00, $12
Wave_5747:
	db $48, $BF, $ED, $B9, $75, $36, $9C, $FF, $ED, $DC, $BB, $AA, $99, $98, $76, $54
Wave_5757:
	db $FF, $FF, $FF, $FF, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $00, $00, $00, $00
Wave_5767:
	db $FE, $DC, $BA, $9A, $98, $78, $9A, $BA, $98, $76, $76, $78, $98, $AB, $CD, $EF
Wave_5777:
	db $BD, $DB, $98, $9C, $EF, $EB, $76, $68, $AA, $94, $21, $24, $88, $53, $35, $8B
Wave_5787:
	db $AC, $CA, $88, $8B, $DE, $DA, $77, $78, $99, $85, $32, $35, $88, $64, $46, $8A
Wave_5797:
	db $A9, $88, $77, $67, $7A, $89, $AB, $CB, $A9, $88, $76, $54, $32, $47, $78, $9B
Wave_57A7:
	db $FF, $FF, $00, $00, $69, $CC, $96, $23, $58, $A8, $65, $24, $68, $63, $56, $54
Wave_57B7:
	db $B0, $BB, $80, $8B, $50, $5B, $10, $1B, $00, $0B, $10, $1B, $50, $5B, $80, $8B
Wave_57C7:
	db $F0, $F2, $F4, $F6, $F8, $F9, $FA, $FB, $FC, $FD, $FE, $FE, $FF, $00, $00, $6A
Wave_57D7:
	db $F0, $8F, $29, $F4, $AF, $6B, $F8, $CF, $AC, $FB, $EF, $CE, $FF, $00, $00, $6A
Wave_57E7:
	db $F8, $08, $F9, $39, $FA, $6A, $FB, $8B, $FC, $AC, $FB, $DF, $FF, $00, $00, $6A
Wave_57F7:
	db $F8, $05, $AF, $A4, $6B, $FB, $79, $CF, $C8, $AC, $FC, $AC, $FF, $00, $00, $6A
Wave_5807:
	db $FB, $60, $6B, $FC, $95, $9C, $FD, $A7, $AD, $FE, $BA, $BE, $FF, $00, $00, $6A
Wave_5817:
	db $FC, $84, $04, $8C, $FD, $A7, $47, $AD, $FE, $BA, $9A, $BE, $FF, $80, $00, $6A
Wave_5827:
	db $FC, $96, $30, $36, $9C, $FD, $B9, $76, $79, $BD, $FE, $DE, $FF, $92, $00, $6A
Wave_5837:
	db $FD, $B9, $63, $03, $69, $BD, $FE, $DB, $98, $9B, $DE, $FE, $FF, $A3, $00, $6A
Wave_5847:
	db $FE, $CA, $85, $20, $25, $8A, $CE, $FE, $DC, $B9, $89, $BD, $FF, $B4, $00, $6A
Wave_5857:
	db $FE, $DC, $B8, $53, $10, $13, $58, $BC, $EF, $ED, $BC, $DE, $FF, $B6, $04, $9B
Wave_5867:
	db $FE, $DC, $B9, $75, $32, $10, $12, $35, $78, $9A, $BC, $DE, $FE, $B6, $04, $9B
Wave_5877:
	db $FE, $DC, $B9, $75, $32, $10, $12, $35, $78, $9A, $BA, $98, $9A, $BC, $DE, $EF
Wave_5887:
	db $FE, $DC, $BA, $97, $54, $32, $10, $12, $34, $57, $9A, $AB, $AB, $CD, $DE, $FF
Wave_5897:
	db $E1, $E3, $E5, $E7, $E8, $E8, $E9, $EA, $EB, $EC, $ED, $ED, $EE, $11, $11, $79
Wave_58A7:
	db $E1, $8E, $38, $E5, $9E, $7A, $E8, $BE, $9B, $EA, $DE, $BD, $EE, $11, $11, $79
Wave_58B7:
	db $E8, $18, $E8, $48, $E9, $79, $EA, $8A, $EB, $9B, $EA, $CE, $EE, $11, $11, $79
Wave_58C7:
	db $E8, $16, $9E, $95, $7A, $EA, $78, $BE, $B8, $9B, $EB, $9B, $EE, $11, $11, $79
Wave_58D7:
	db $EA, $71, $7A, $EB, $86, $8B, $EC, $97, $9C, $ED, $A9, $AD, $EE, $11, $11, $79
Wave_58E7:
	db $EB, $85, $15, $8B, $EC, $97, $57, $9C, $ED, $A9, $89, $AD, $EE, $81, $11, $79
Wave_58F7:
	db $EB, $87, $41, $47, $8B, $EC, $A8, $77, $78, $AC, $ED, $CD, $EE, $83, $11, $79
Wave_5907:
	db $EC, $A8, $74, $14, $78, $AC, $ED, $CA, $88, $8A, $CD, $ED, $EE, $94, $11, $79
Wave_5917:
	db $ED, $B9, $86, $31, $36, $89, $BD, $ED, $CB, $A8, $88, $AC, $EE, $A5, $11, $79
Wave_5927:
	db $ED, $CB, $A8, $64, $21, $24, $68, $AB, $DE, $DC, $AB, $CD, $EE, $A7, $15, $8A
Wave_5937:
	db $ED, $CB, $A8, $76, $43, $21, $23, $46, $78, $89, $AB, $CD, $ED, $A7, $15, $8A
Wave_5947:
	db $ED, $CB, $A8, $76, $43, $21, $23, $46, $78, $89, $A9, $88, $89, $AB, $CD, $DE
Wave_5957:
	db $ED, $CB, $A9, $87, $65, $43, $21, $23, $45, $67, $89, $9A, $9A, $BC, $CD, $EE
Wave_5967:
	db $94, $39, $45, $94, $39, $45, $43, $FF, $49, $39, $49, $59, $43, $94, $59, $43
Wave_5977:
	db $A4, $53, $A4, $3F, $B4, $A3, $A4, $59, $43, $94, $59, $43, $A4, $54, $3B, $43
Wave_5987:
	db $92, $34, $3B, $49, $3B, $4B, $39, $45, $49, $3A, $4A, $3B, $4A, $3B, $4A, $3A
Wave_5997:
	db $4B, $3A, $4B, $39, $4A, $3A, $49, $32, $39, $43, $C4, $54, $39, $4C, $39, $4B
Wave_59A7:
	db $3B, $49, $3C, $43, $F4, $54, $39, $45, $94, $93, $94, $54, $3A, $49, $3F, $B4
Wave_59B7:
	db $3B, $4A, $39, $45, $A4, $A5, $94, $93, $4B, $3A, $23, $A2, $A3, $D4, $A3, $4D
Wave_59C7:
	db $5A, $4F, $93, $D2, $3F, $B4, $A3, $94, $59, $4B, $54, $F9, $32, $93, $B2, $3E
Wave_59D7:
	db $49, $39, $4F, $FA, $3F, $C4, $3A, $49, $34, $F9, $54, $93, $94, $A3, $F9, $23
Wave_59E7:
	db $94, $93, $23, $94, $A3, $94, $F9, $34, $B3, $43, $A4, $A2, $A4, $A3, $29, $4B
Wave_59F7:
	db $39, $49, $54, $93, $4C, $3A, $43, $B4, $93, $B4, $93, $A4, $B3, $94, $FB, $39
Wave_5A07:
	db $49, $3A, $43, $D4, $3A, $4A, $34, $F3, $4C, $3A, $4A, $3D, $49, $3B, $4A, $39
Wave_5A17:
	db $4B, $39, $4A, $34, $93, $C4, $93, $B4, $3D, $49, $3A, $4F, $A3, $94, $A3, $A4
Wave_5A27:
	db $A3, $23, $4A, $32, $93, $49, $3B, $4A, $39, $4C, $39, $4A, $3A, $4A, $3A, $4A
Wave_5A37:
	db $3A, $43, $D4, $A3, $94, $C3, $94, $C3, $A4, $B3, $A4, $A3, $A4, $A3, $A4, $F9
Wave_5A47:
	db $39, $4A, $3B, $4A, $3A, $49, $3B, $4A, $39, $49, $34, $D3, $94, $B3, $A4, $A3
Wave_5A57:
	db $A4, $A3, $B4, $93, $A4, $C3, $4A, $3A, $4A, $3A, $4A, $3A, $49, $3C, $49, $39
Wave_5A67:
	db $C4, $C5, $C6, $C7, $C8, $C9, $C9, $CA, $CB, $CB, $CB, $CB, $CC, $44, $44, $79
Wave_5A77:
	db $C4, $8C, $59, $C6, $9C, $6A, $C8, $BC, $9B, $CA, $BC, $CB, $CC, $44, $44, $69
Wave_5A87:
	db $C8, $48, $C9, $59, $CA, $7A, $CA, $8A, $CB, $9B, $CB, $BC, $CC, $44, $44, $69
Wave_5A97:
	db $C8, $46, $9C, $94, $7A, $CB, $79, $BC, $B8, $9B, $CB, $9B, $CC, $44, $44, $79
Wave_5AA7:
	db $CA, $64, $6A, $CB, $95, $9B, $CB, $97, $9B, $CB, $A9, $AB, $CC, $44, $44, $69
Wave_5AB7:
	db $CA, $85, $45, $8A, $CB, $97, $57, $9B, $CB, $A9, $99, $AB, $CC, $84, $44, $69
Wave_5AC7:
	db $CA, $96, $54, $57, $9A, $CB, $A9, $76, $79, $AB, $CB, $AB, $CC, $94, $44, $69
Wave_5AD7:
	db $CA, $A9, $75, $45, $79, $AB, $CB, $A9, $98, $9A, $AB, $CB, $CC, $95, $44, $79
Wave_5AE7:
	db $CB, $A9, $86, $54, $56, $89, $AB, $CB, $AB, $99, $89, $AB, $CC, $A5, $44, $69
Wave_5AF7:
	db $CB, $A9, $98, $76, $54, $45, $68, $9A, $BC, $BA, $9A, $BC, $CC, $A6, $45, $9A
Wave_5B07:
	db $CB, $A9, $98, $76, $55, $44, $45, $56, $78, $99, $AB, $CC, $CB, $A6, $45, $9A
Wave_5B17:
	db $CB, $A9, $A9, $76, $54, $44, $44, $56, $78, $9A, $A9, $98, $99, $AA, $BC, $CC
Wave_5B27:
	db $CB, $A9, $89, $97, $65, $44, $44, $45, $56, $67, $99, $AB, $AB, $BC, $BC, $CC
Wave_5B37:
	db $95, $3B, $4C, $34, $93, $C5, $4A, $34, $A3, $43, $94, $93, $A4, $B3, $A4, $34
Wave_5B47:
	db $39, $4A, $3B, $4A, $3A, $4A, $3A, $49, $39, $43, $4A, $3A, $49, $53, $B4, $A3
Wave_5B57:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $01, $23, $45, $67, $89, $AB, $CD, $EF
Wave_5B67:
	db $7C, $DC, $BB, $A9, $DC, $A5, $43, $33, $21, $00, $01, $26, $BE, $DA, $84, $45
Wave_5B77:
	db $7B, $EF, $DB, $86, $55, $9A, $99, $8B, $BA, $65, $44, $44, $32, $11, $05, $24
Wave_5B87:
	db $7C, $DF, $EB, $88, $68, $A6, $89, $87, $43, $53, $54, $43, $23, $23, $81, $56
Wave_5B97:
	db $7B, $FE, $DC, $B9, $9B, $86, $98, $34, $42, $34, $33, $31, $33, $48, $52, $57
Wave_5BA7:
	db $7B, $DC, $CF, $EC, $DB, $79, $84, $1A, $42, $13, $30, $13, $34, $86, $34, $76
Wave_5BB7:
	db $79, $BB, $CE, $FF, $EB, $99, $84, $23, $42, $12, $30, $02, $45, $65, $44, $66
Wave_5BC7:
	db $79, $9A, $CF, $FF, $EC, $CA, $73, $24, $31, $12, $20, $13, $56, $54, $45, $55
Wave_5BD7:
	db $78, $89, $CE, $FF, $EE, $DB, $64, $45, $31, $22, $10, $13, $55, $33, $45, $55
Wave_5BE7:
	db $77, $79, $BE, $FF, $EE, $DB, $64, $45, $22, $22, $11, $24, $54, $34, $55, $45
Wave_5BF7:
	db $78, $AD, $ED, $DF, $EB, $87, $76, $32, $32, $11, $24, $54, $34, $55, $45, $67
Wave_5C07:
	db $78, $AC, $DC, $DE, $DB, $98, $86, $43, $32, $12, $34, $53, $34, $55, $45, $66
Wave_5C17:
	db $78, $9B, $CB, $CD, $CB, $99, $97, $54, $32, $22, $34, $43, $34, $55, $55, $66
Wave_5C27:
	db $77, $9A, $BA, $BC, $DA, $9A, $A8, $65, $43, $22, $34, $43, $34, $55, $55, $56
Wave_5C37:
	db $77, $8A, $AA, $AC, $BA, $9A, $A9, $76, $54, $33, $34, $33, $23, $45, $55, $56
Wave_5C47:
	db $77, $89, $99, $AB, $AA, $9A, $A9, $87, $65, $44, $44, $32, $23, $44, $45, $56
Wave_5C57:
	db $77, $89, $99, $AA, $A9, $9A, $A9, $87, $66, $55, $44, $32, $23, $44, $44, $56

; PeriodTable: 96 periods (from PeriodTable - 26 by 2 * pitch + TRK_OCTAVE + TRK_TRANSP);
; the last is also VibratoTable entry 0.
PeriodTable:
	dw $02C, $09D, $107, $16B, $1C9, $223, $277, $2C7, $312, $358, $39B, $3DA ; octave index 0
	dw $416, $44E, $483, $4B5, $4E5, $511, $53B, $563, $589, $5AC, $5CE, $5ED ; octave index 1
	dw $60B, $627, $642, $65B, $672, $689, $69E, $6B2, $6C4, $6D6, $6E7, $6F7 ; octave index 2
	dw $706, $714, $721, $72D, $739, $744, $74F, $759, $762, $76B, $773, $77B ; octave index 3
	dw $783, $78A, $790, $797, $79D, $7A2, $7A7, $7AC, $7B1, $7B6, $7BA, $7BE ; octave index 4
	dw $7C1, $7C5, $7C8, $7CB, $7CE, $7D1, $7D4, $7D6, $7D9, $7DB, $7DD, $7DF ; octave index 5
	dw $7E1, $7E2, $7E4, $7E6, $7E7, $7E9, $7EA, $7EB, $7EC, $7ED, $7EE, $7EF ; octave index 6
	dw $7F0, $7F1, $7F2, $7F3, $7F4, $7F5, $7F6, $7F7, $7F8, $7F9, $7FA, $7FB ; octave index 7

; VibratoTable: 13 pointers (EB n uses entry n; from VibratoTable - 2).
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
	VIB_MARK
	VIB_STEP 2, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 2, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 2, 1, 2
	VIB_STEP 1, 1, 1
	VIB_MARK

Vib02:
	VIB_STEP 2, 1, 7
	VIB_STEP 1, 1, 6
	VIB_STEP 2, 1, 5
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 3
	VIB_STEP 2, 1, 2
	VIB_STEP 3, 1, 1
	VIB_STEP 1, 1, 0
	VIB_STEP 14, 0, 0
	VIB_STEP 8, 0, 0
	VIB_STEP 8, 0, 0
	VIB_STEP2 1, $FF
	VIB_STEP2 1, $FE
	VIB_STEP2 1, $FD
	VIB_STEP2 1, $FC
	VIB_STEP2 1, $FB
	VIB_STEP2 1, $FA
	VIB_STEP2 1, $F9
	VIB_STEP2 1, $F8
	VIB_STEP2 1, $F7
	VIB_STEP2 1, $F6
	VIB_STEP2 1, $F5
	VIB_STEP2 1, $F4
	VIB_STEP2 1, $F3
	VIB_STEP2 1, $F2
	VIB_STEP2 1, $F1
	VIB_STEP2 1, $F0
	VIB_STEP2 1, $EF
	VIB_STEP2 1, $EE
	VIB_STEP2 1, $ED
	VIB_STEP2 1, $EC
	VIB_STEP2 1, $EB
	VIB_STEP2 1, $EA
	VIB_STEP2 1, $E9
	VIB_STEP2 1, $E8
	VIB_STEP2 1, $E7
	VIB_END

Vib03:
	VIB_STEP2 1, $FF
	VIB_STEP2 1, $FE
	VIB_STEP2 1, $FD
	VIB_STEP2 1, $FC
	VIB_STEP2 1, $FB
	VIB_STEP2 1, $FA
	VIB_STEP2 1, $F9
	VIB_STEP2 1, $F8
	VIB_STEP2 1, $F7
	VIB_STEP2 1, $F6
	VIB_STEP2 1, $F5
	VIB_STEP2 1, $F4
	VIB_STEP2 1, $F3
	VIB_STEP2 1, $F2
	VIB_STEP2 1, $F1
	VIB_STEP2 1, $F0
	VIB_STEP2 1, $EF
	VIB_STEP2 1, $EE
	VIB_STEP2 1, $ED
	VIB_STEP2 1, $EC
	VIB_STEP2 1, $EB
	VIB_STEP2 1, $EA
	VIB_STEP2 1, $E9
	VIB_STEP2 1, $E8
	VIB_STEP2 1, $E7
	VIB_STEP2 1, $E6
	VIB_STEP2 1, $E5
	VIB_STEP2 1, $E4
	VIB_STEP2 1, $E3
	VIB_STEP2 1, $E2
	VIB_STEP2 1, $E1
	VIB_STEP2 1, $E0
	VIB_STEP2 1, $DF
	VIB_STEP2 1, $DE
	VIB_STEP2 1, $DD
	VIB_STEP2 1, $DC
	VIB_STEP2 1, $DB
	VIB_STEP2 1, $DA
	VIB_STEP2 1, $D9
	VIB_STEP2 1, $D8
	VIB_STEP2 1, $D7
	VIB_STEP2 1, $D6
	VIB_STEP2 1, $D5
	VIB_STEP2 1, $D4
	VIB_STEP2 1, $D3
	VIB_STEP2 1, $D2
	VIB_STEP2 1, $D1
	VIB_STEP2 1, $D0
	VIB_STEP2 1, $CF
	VIB_STEP2 1, $CE
	VIB_STEP2 1, $CD
	VIB_STEP2 1, $CC
	VIB_STEP2 1, $CB
	VIB_STEP2 1, $CA
	VIB_STEP2 1, $C9
	VIB_STEP2 1, $C8
	VIB_STEP2 1, $C7
	VIB_STEP2 1, $C6
	VIB_STEP2 1, $C5
	VIB_STEP2 1, $C4
	VIB_STEP2 1, $C3
	VIB_STEP2 1, $C2
	VIB_STEP2 1, $C1
	VIB_STEP2 1, $C0
	VIB_STEP2 1, $BF
	VIB_STEP2 1, $BE
	VIB_STEP2 1, $BD
	VIB_STEP2 1, $BC
	VIB_STEP2 1, $BB
	VIB_STEP2 1, $C4
	VIB_END

Vib04:
	VIB_STEP 2, 1, 7
	VIB_STEP 1, 1, 6
	VIB_STEP 2, 1, 5
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 3
	VIB_STEP 2, 1, 2
	VIB_STEP 3, 1, 1
	VIB_STEP 1, 1, 0
	VIB_STEP 1, 0, 0
	VIB_END

Vib05:
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 0
	VIB_STEP 1, 0, 0
	VIB_END

Vib06:
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 7
	VIB_END

Vib07:
	VIB_STEP 4, 1, 7
	VIB_STEP 3, 1, 6
	VIB_STEP 3, 1, 5
	VIB_STEP 2, 1, 4
	VIB_STEP 3, 1, 3
	VIB_STEP 4, 1, 2
	VIB_STEP 5, 1, 1
	VIB_STEP 2, 1, 0
	VIB_STEP 3, 0, 0
	VIB_END

Vib08:
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 6, 0, 0
	VIB_STEP 10, 0, 0
	VIB_STEP 10, 0, 0
	VIB_STEP 2, 1, 1
	VIB_STEP 2, 1, 2
	VIB_STEP 2, 1, 3
	VIB_STEP 2, 1, 4
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 6
	VIB_END

Vib09:
	VIB_STEP 2, 1, 5
	VIB_STEP 2, 1, 4
	VIB_STEP 2, 1, 3
	VIB_STEP 2, 1, 2
	VIB_STEP 2, 1, 1
	VIB_STEP 4, 1, 0
	VIB_MARK
	VIB_STEP 2, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 2, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 2, 1, 2
	VIB_STEP 1, 1, 1
	VIB_MARK

Vib0A:
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 2
	VIB_STEP 1, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 0, 0
	VIB_END

Vib0B:
	VIB_STEP 1, 1, 1
	VIB_STEP 1, 1, 2
	VIB_STEP 1, 1, 3
	VIB_STEP 1, 1, 4
	VIB_STEP 1, 1, 5
	VIB_STEP 1, 1, 6
	VIB_STEP 1, 1, 7
	VIB_END

Vib0C:
	VIB_STEP2 2, $FF
	VIB_STEP2 2, $FE
	VIB_STEP2 2, $FD
	VIB_STEP2 2, $FC
	VIB_STEP2 2, $FB
	VIB_STEP2 2, $FA
	VIB_STEP2 2, $F9
	VIB_STEP2 2, $F8
	VIB_STEP2 2, $F7
	VIB_STEP2 2, $F6
	VIB_STEP2 2, $F5
	VIB_STEP2 2, $F4
	VIB_STEP2 2, $F3
	VIB_STEP2 2, $F2
	VIB_STEP2 2, $F1
	VIB_STEP2 2, $F0
	VIB_STEP2 2, $EF
	VIB_STEP2 2, $EE
	VIB_STEP2 2, $ED
	VIB_STEP2 2, $EC
	VIB_STEP2 2, $EB
	VIB_STEP2 2, $EA
	VIB_STEP2 2, $E9
	VIB_STEP2 2, $E8
	VIB_STEP2 2, $E7
	VIB_STEP2 2, $E6
	VIB_STEP2 2, $E5
	VIB_STEP2 2, $E4
	VIB_STEP2 2, $E3
	VIB_STEP2 2, $E2
	VIB_STEP2 2, $E1
	VIB_STEP2 2, $E0
	VIB_STEP2 2, $DF
	VIB_STEP2 2, $DE
	VIB_STEP2 2, $DD
	VIB_STEP2 2, $DC
	VIB_STEP2 2, $DB
	VIB_STEP2 2, $DA
	VIB_STEP2 2, $D9
	VIB_STEP2 2, $D8
	VIB_STEP2 2, $D7
	VIB_STEP2 2, $D6
	VIB_STEP2 2, $D5
	VIB_STEP2 2, $D4
	VIB_STEP2 2, $D3
	VIB_STEP2 2, $D2
	VIB_STEP2 2, $D1
	VIB_STEP2 2, $D0
	VIB_STEP2 2, $CF
	VIB_STEP2 2, $CE
	VIB_STEP2 2, $CD
	VIB_STEP2 2, $CC
	VIB_STEP2 2, $CB
	VIB_STEP2 2, $CA
	VIB_STEP2 2, $C9
	VIB_STEP2 2, $C8
	VIB_STEP2 2, $C7
	VIB_STEP2 2, $C6
	VIB_STEP2 2, $C5
	VIB_STEP2 2, $C4
	VIB_STEP2 2, $C3
	VIB_STEP2 2, $C2
	VIB_STEP2 2, $C1
	VIB_STEP2 2, $C0
	VIB_STEP2 2, $BF
	VIB_STEP2 2, $BE
	VIB_STEP2 2, $BD
	VIB_STEP2 2, $BC
	VIB_STEP2 2, $BB
	VIB_STEP2 2, $C4
	VIB_END

Vib0D:
	VIB_STEP2 2, $01
	VIB_STEP2 2, $02
	VIB_STEP2 2, $03
	VIB_STEP2 2, $04
	VIB_STEP2 2, $05
	VIB_STEP2 2, $06
	VIB_STEP2 2, $07
	VIB_STEP2 2, $08
	VIB_STEP2 2, $09
	VIB_STEP2 2, $0A
	VIB_STEP2 2, $0B
	VIB_STEP2 2, $0C
	VIB_STEP2 2, $0D
	VIB_STEP2 2, $0E
	VIB_STEP2 2, $0F
	VIB_STEP2 2, $10
	VIB_STEP2 2, $11
	VIB_STEP2 2, $12
	VIB_STEP2 2, $13
	VIB_STEP2 2, $14
	VIB_STEP2 2, $15
	VIB_STEP2 2, $16
	VIB_STEP2 2, $17
	VIB_STEP2 2, $18
	VIB_STEP2 2, $19
	VIB_STEP2 2, $1A
	VIB_STEP2 2, $1B
	VIB_STEP2 2, $1C
	VIB_STEP2 2, $1D
	VIB_STEP2 2, $1E
	VIB_STEP2 2, $1F
	VIB_STEP2 2, $20
	VIB_STEP2 2, $21
	VIB_STEP2 2, $22
	VIB_STEP2 2, $23
	VIB_STEP2 2, $24
	VIB_STEP2 2, $25
	VIB_STEP2 2, $26
	VIB_STEP2 2, $27
	VIB_STEP2 2, $28
	VIB_STEP2 2, $29
	VIB_STEP2 2, $2A
	VIB_STEP2 2, $2B
	VIB_STEP2 2, $2C
	VIB_STEP2 2, $2D
	VIB_STEP2 2, $2E
	VIB_STEP2 2, $2F
	VIB_STEP2 2, $30
	VIB_STEP2 2, $31
	VIB_STEP2 2, $32
	VIB_STEP2 2, $33
	VIB_STEP2 2, $34
	VIB_STEP2 2, $35
	VIB_STEP2 2, $36
	VIB_STEP2 2, $37
	VIB_STEP2 2, $38
	VIB_STEP2 2, $39
	VIB_STEP2 2, $3A
	VIB_STEP2 2, $3B
	VIB_STEP2 2, $3C
	VIB_STEP2 2, $3D
	VIB_STEP2 2, $3E
	VIB_STEP2 2, $3F
	VIB_STEP2 2, $40
	VIB_STEP2 2, $41
	VIB_STEP2 2, $42
	VIB_STEP2 2, $43
	VIB_STEP2 2, $44
	VIB_STEP2 2, $45
	VIB_STEP2 2, $46
	VIB_STEP2 2, $47
	VIB_STEP2 2, $48
	VIB_STEP2 2, $49
	VIB_STEP2 2, $4A
	VIB_STEP2 2, $4B
	VIB_STEP2 2, $4C
	VIB_STEP2 2, $4D
	VIB_STEP2 2, $4E
	VIB_STEP2 2, $4F
	VIB_STEP2 2, $50
	VIB_STEP2 2, $51
	VIB_STEP2 2, $52
	VIB_STEP2 2, $53
	VIB_STEP2 2, $54
	VIB_STEP2 2, $55
	VIB_STEP2 2, $56
	VIB_STEP2 2, $57
	VIB_STEP2 2, $58
	VIB_STEP2 2, $59
	VIB_STEP2 2, $5A
	VIB_END

; Vibrato data no table entry points at.
	db $FE, $28, $20, $27, $29, $26, $2A, $25, $2B, $24, $2C, $23, $2D, $22, $2E, $21
	db $2F, $22, $2E, $23, $2D, $24, $2C, $25, $2B, $26, $2A, $27, $29, $28, $20, $FE

; Vibrato2Table: 11 semitone-step tables (EB n | $80; from Vibrato2Table - 2).
Vibrato2Table:
	dw VibSemi01 ; 1 (EB 1 | $80)
	dw VibSemi02 ; 2 (EB 2 | $80)
	dw VibSemi03 ; 3 (EB 3 | $80)
	dw VibSemi04 ; 4 (EB 4 | $80)
	dw VibSemi05 ; 5 (EB 5 | $80)
	dw VibSemi06 ; 6 (EB 6 | $80)
	dw VibSemi07 ; 7 (EB 7 | $80)
	dw VibSemi08 ; 8 (EB 8 | $80)
	dw VibSemi09 ; 9 (EB 9 | $80)
	dw VibSemi0A ; 10 (EB 10 | $80)
	dw VibSemi0B ; 11 (EB 11 | $80)
VibSemi01:
	VIB_SEMI_STEP 9, 1
	VIB_SEMI_STEP 4, 0
	VIB_END
VibSemi02:
	VIB_SEMI_STEP 9, 2
	VIB_SEMI_STEP 4, 0
	VIB_END
VibSemi03:
	VIB_SEMI_STEP 7, 0
	VIB_SEMI_STEP 7, 2
	VIB_END
VibSemi04:
	VIB_SEMI_STEP 4, 0
	VIB_SEMI_STEP 4, 1
	VIB_END
VibSemi05:
	VIB_SEMI_STEP 2, 0
	VIB_SEMI_STEP 2, 3
	VIB_SEMI_STEP 2, 6
	VIB_END
VibSemi06:
	VIB_SEMI_STEP 2, 0
	VIB_SEMI_STEP 2, 4
	VIB_SEMI_STEP 2, 9
	VIB_END
VibSemi07:
	VIB_SEMI_STEP 2, 0
	VIB_SEMI_STEP 2, 2
	VIB_SEMI_STEP 2, 5
	VIB_END
VibSemi08:
	VIB_MARK
	VIB_SEMI_STEP 2, 0
	VIB_SEMI_STEP 2, 5
	VIB_SEMI_STEP 2, 8
	VIB_MARK
VibSemi09:
	VIB_MARK
	VIB_SEMI_STEP 2, 0
	VIB_SEMI_STEP 2, 2
	VIB_SEMI_STEP 2, 5
	VIB_MARK
VibSemi0A:
	VIB_MARK
	VIB_SEMI_STEP 2, 0
	VIB_SEMI_STEP 2, 4
	VIB_SEMI_STEP 2, 7
	VIB_MARK
VibSemi0B:
	VIB_MARK
	VIB_SEMI_STEP 2, 0
	VIB_SEMI_STEP 2, 2
	VIB_SEMI_STEP 2, 7
	VIB_MARK

; EnvelopeTable: 24 volume envelopes (EC n, or a voice with volume 0).
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
Env01:
	ENV_STEP 1, 6
	ENV_STEP 1, 4
	ENV_STEP 4, 6
	ENV_STEP 0, 0
	VIB_END
Env02:
	ENV_STEP 1, 7
	ENV_STEP 1, 3
	ENV_STEP 1, 2
	ENV_STEP 1, 4
	ENV_STEP 1, 2
	ENV_STEP 1, 1
	VIB_END
Env03:
	ENV_STEP 1, 7
	ENV_STEP 1, 4
	VIB_END
Env04:
	ENV_STEP 1, 8
	ENV_STEP 1, 4
	ENV_STEP 1, 3
	ENV_STEP 1, 5
	ENV_STEP 1, 2
	ENV_STEP 1, 1
	VIB_END
Env05:
	ENV_STEP 1, $0A
	ENV_STEP 1, 5
	ENV_STEP 1, 4
	ENV_STEP 1, 5
	ENV_STEP 1, 3
	ENV_STEP 1, 2
	VIB_END
Env06:
	ENV_STEP 6, 7
	ENV_STEP 6, 8
	ENV_STEP $0A, 9
	ENV_STEP $0A, $0A
	ENV_STEP $0C, $0B
	VIB_END
Env07:
	ENV_STEP $0A, $0F
	ENV_STEP $0A, $0F
	ENV_STEP $0A, $0E
	ENV_STEP $0A, $0D
	ENV_STEP $0A, $0C
	ENV_STEP $0A, $0B
	ENV_STEP $0A, $0A
	ENV_STEP $0A, 9
	ENV_STEP $0A, 8
	ENV_STEP $0A, 7
	ENV_STEP $0A, 6
	ENV_STEP $0A, 5
Env08:
	ENV_STEP $0A, 4
	ENV_STEP $0A, 5
	ENV_STEP $0A, 6
	ENV_STEP $0A, 7
	ENV_STEP $0A, 8
	ENV_STEP $0C, 9
	ENV_STEP $0A, $0A
	ENV_STEP $0A, $0B
	ENV_STEP $0A, $0C
	ENV_STEP $0A, $0D
	ENV_STEP $0A, $0E
	ENV_STEP $0A, $0F
	VIB_END
Env09:
	ENV_STEP 8, 4
	ENV_STEP 8, 5
	ENV_STEP 9, 6
	ENV_STEP 9, 7
	ENV_STEP $0A, 8
	ENV_STEP $0A, 9
	ENV_STEP $0B, $0A
	ENV_STEP $0B, $0B
	ENV_STEP $0C, $0C
	ENV_STEP $0C, $0D
	ENV_STEP $0D, $0E
	ENV_STEP $0D, $0F
	VIB_END
Env0A:
	ENV_STEP 3, 8
	ENV_STEP 3, 7
	ENV_STEP 3, 6
	ENV_STEP 3, 5
	ENV_STEP 6, 6
	ENV_STEP 6, 7
	ENV_STEP 8, 8
	VIB_END
Env0B:
	ENV_STEP 6, 5
	ENV_STEP 6, 6
	ENV_STEP 6, 7
	ENV_STEP 6, 8
	VIB_END
Env0C:
	ENV_STEP 8, 4
	ENV_STEP $0A, 4
	ENV_STEP $0A, 5
	ENV_STEP $0A, 6
	ENV_STEP $0A, 7
	ENV_STEP $0A, 8
	ENV_STEP $0C, 9
	VIB_END
Env0D:
	ENV_STEP 6, 9
	ENV_STEP 6, $0A
	ENV_STEP 6, $0B
	ENV_STEP $0F, $0C
	ENV_STEP $0F, $0D
	VIB_MARK
	VIB_END
Env0E:
	ENV_STEP 6, 5
	ENV_STEP 6, 6
	ENV_STEP $0A, 7
	ENV_STEP $0A, 8
	ENV_STEP $0C, 9
	VIB_END
Env0F:
	VIB_MARK
	ENV_STEP 1, 9
	VIB_MARK
Env10:
	ENV_STEP 9, 6
	ENV_STEP 8, 6
	ENV_STEP 7, 6
	ENV_STEP 6, 6
	ENV_STEP 5, 6
	ENV_STEP 4, 6
	ENV_STEP 3, 6
	ENV_STEP 2, 6
	ENV_STEP 1, 6
	VIB_END
Env11:
	ENV_STEP 5, 7
	ENV_STEP 5, 6
	ENV_STEP 4, 5
	ENV_STEP 4, 4
Env12:
	VIB_MARK
	ENV_STEP 0, $0C
	VIB_MARK
Env13:
	ENV_STEP 3, 2
	ENV_STEP 0, 6
	VIB_END
Env14:
	ENV_STEP 1, 5
	ENV_STEP 2, 3
	ENV_STEP $0F, 2
	VIB_END
Env15:
	ENV_STEP 1, 8
	ENV_STEP 1, 4
	ENV_STEP 1, 3
	VIB_END
Env16:
	ENV_STEP 1, $0E
	ENV_STEP 1, 7
	ENV_STEP 1, 4
	VIB_END
Env17:
	ENV_STEP 1, 2
	ENV_STEP 1, 4
	ENV_STEP 1, 6
	VIB_END
Env18:
	ENV_STEP 2, 5
	ENV_STEP 2, 3
	ENV_STEP 2, 2
	ENV_STEP 0, 1
	VIB_END

; MacroTable: 10 instrument macros ($EA 11 n; from MacroTable - 2).
MacroTable:
	dw Instrument01 ; 1
	dw Instrument02 ; 2
	dw Instrument03 ; 3
	dw Instrument04 ; 4
	dw Instrument05 ; 5
	dw Instrument06 ; 6
	dw Instrument07 ; 7
	dw Instrument08 ; 8
	dw Instrument09 ; 9
	dw Instrument0A ; 10
Instrument01:
	INS_STEP 4, $10, $00
	INS_STEP 2, $11, $00
	INS_STEP 2, $12, $00
	INS_STEP 2, $13, $00
	INS_STEP 2, $14, $00
	INS_STEP 2, $15, $00
	INS_STEP 2, $16, $00
	INS_STEP 2, $17, $00
	INS_STEP 2, $18, $00
	INS_STEP 2, $19, $00
	INS_STEP 2, $1A, $00
	INS_STEP 2, $1B, $00
	INS_STEP 2, $1C, $00
	INS_END
Instrument02:
	INS_STEP 2, $10, $00
	INS_STEP 1, $11, $00
	INS_STEP 1, $12, $00
	INS_STEP 1, $13, $00
	INS_STEP 1, $14, $00
	INS_STEP 1, $15, $00
	INS_STEP 1, $16, $00
	INS_STEP 1, $17, $00
	INS_STEP 1, $18, $00
	INS_STEP 1, $19, $00
	INS_STEP 1, $1A, $00
	INS_STEP 1, $1B, $00
	INS_STEP 1, $1C, $00
	INS_END
Instrument03:
	INS_STEP 4, $10, $00
	INS_STEP 2, $11, $00
	INS_STEP 2, $12, $00
	INS_STEP 2, $13, $00
	INS_STEP 2, $14, $00
	INS_STEP 2, $15, $00
	INS_STEP 2, $16, $00
	INS_STEP 2, $17, $00
	INS_STEP 2, $18, $00
	INS_STEP 2, $19, $00
	INS_STEP 2, $1A, $00
	INS_STEP 2, $1B, $00
	INS_STEP 2, $1C, $00
	INS_MARK
	INS_STEP 1, $1C, $FA
	INS_STEP 1, $1C, $FE
	INS_STEP 1, $1C, $02
	INS_STEP 1, $1C, $06
	INS_STEP 1, $1C, $02
	INS_STEP 1, $1C, $FE
	INS_MARK
Instrument04:
	INS_STEP 4, $10, $00
	INS_MARK
Instrument05:
	INS_STEP 4, $20, $00
	INS_STEP 2, $21, $00
	INS_STEP 2, $22, $00
	INS_STEP 2, $23, $00
	INS_STEP 2, $24, $00
	INS_STEP 2, $25, $00
	INS_STEP 2, $26, $00
	INS_STEP 2, $27, $00
	INS_STEP 2, $28, $00
	INS_STEP 2, $29, $00
	INS_STEP 2, $2A, $00
	INS_STEP 2, $2B, $00
	INS_STEP 2, $2C, $00
	INS_END
Instrument06:
	INS_STEP 1, $40, $09
	INS_STEP 1, $41, $07
	INS_STEP 1, $42, $05
	INS_STEP 1, $43, $03
	INS_STEP 1, $44, $01
	INS_STEP 1, $45, $FF
	INS_STEP 1, $46, $FD
	INS_STEP 1, $47, $FE
	INS_STEP 1, $48, $00
	INS_STEP 1, $49, $00
	INS_STEP 1, $4A, $00
	INS_STEP 1, $4B, $00
	INS_STEP 1, $4C, $00
	INS_END
Instrument07:
	INS_MARK
	INS_STEP 2, $3F, $00
	INS_STEP 2, $3E, $00
	INS_STEP 2, $3D, $00
	INS_STEP 2, $3C, $00
	INS_STEP 2, $3B, $00
	INS_STEP 2, $3A, $00
	INS_STEP 2, $39, $00
	INS_STEP 2, $38, $00
	INS_STEP 2, $37, $00
	INS_STEP 2, $36, $00
	INS_STEP 2, $35, $00
	INS_STEP 2, $34, $00
	INS_STEP 2, $33, $00
	INS_STEP 2, $32, $00
	INS_STEP 2, $31, $00
	INS_STEP 2, $30, $00
	INS_STEP 2, $31, $00
	INS_STEP 2, $32, $00
	INS_STEP 2, $33, $00
	INS_STEP 2, $34, $00
	INS_STEP 2, $35, $00
	INS_STEP 2, $36, $00
	INS_STEP 2, $37, $00
	INS_STEP 2, $38, $00
	INS_STEP 2, $39, $00
	INS_STEP 2, $3A, $00
	INS_STEP 2, $3B, $00
	INS_STEP 2, $3C, $00
	INS_STEP 2, $3D, $00
	INS_STEP 2, $3E, $00
	INS_MARK
Instrument08:
	INS_MARK
	INS_STEP 1, $30, $00
	INS_STEP 1, $31, $02
	INS_STEP 1, $32, $04
	INS_STEP 1, $33, $06
	INS_STEP 1, $34, $04
	INS_STEP 1, $35, $02
	INS_STEP 1, $36, $00
	INS_STEP 1, $37, $FE
	INS_STEP 1, $38, $FC
	INS_STEP 1, $39, $FA
	INS_STEP 1, $3A, $FC
	INS_STEP 1, $3B, $FE
	INS_MARK
Instrument09:
	INS_STEP 2, $10, $00
	INS_STEP 2, $11, $02
	INS_STEP 2, $12, $04
	INS_STEP 2, $13, $06
	INS_STEP 2, $14, $08
	INS_STEP 2, $15, $08
	INS_STEP 2, $16, $08
	INS_STEP 2, $17, $07
	INS_STEP 2, $18, $06
	INS_STEP 2, $19, $07
	INS_STEP 2, $1A, $08
	INS_STEP 2, $1B, $07
	INS_STEP 2, $1C, $06
	INS_END
Instrument0A:
	INS_STEP 4, $50, $00
	INS_STEP 2, $51, $00
	INS_STEP 2, $52, $00
	INS_STEP 2, $53, $00
	INS_STEP 2, $54, $00
	INS_STEP 2, $55, $00
	INS_STEP 2, $56, $00
	INS_STEP 2, $57, $00
	INS_STEP 2, $58, $00
	INS_STEP 2, $59, $00
	INS_STEP 2, $5A, $00
	INS_STEP 2, $5B, $00
	INS_STEP 2, $5C, $00
	INS_STEP 2, $5D, $00
	INS_STEP 2, $5E, $00
	INS_STEP 2, $5F, $00
	INS_END

Snd01_SfxN:
	NVOICE $01, $F0
	NOISE $43
	NOISE_VOL 8
	NOISE $32
	NOISE_VOL 5
	NOISE $41
	NVOICE $03, $32
	SND_END

Snd02_SfxN:
	NVOICE $01, $81
	NOISE $34
	ATTEN 2
	NOISE $35
	SND_END

Snd03_SfxN:
	NVOICE $01, $C0
	NOISE $41
	NOISE_VOL $0A
	NOISE $32
	NOISE_VOL 7
	NOISE $23
	NVOICE $08, $43
	NOISE $11
	SND_END

Snd04_SfxN:
	NVOICE $01, $82
	NOISE $31
	ATTEN 2
	NOISE $32
	SND_END

Snd05_SfxN:
	NVOICE $01, $B0
	NOISE $43
	NOISE_VOL 8
	NOISE $32
	NOISE_VOL 5
	NOISE $41
	NVOICE $03, $32
	NOISE $12
	NOISE_VOLNOTE 2
	NOISE_VOLNOTE 1
	SND_END

Snd06_SfxN:
	NVOICE $01, $52
	NOISE $31
	ATTEN 2
	NOISE $32
	SND_END

Snd07_SfxN:
	NVOICE $1F, $61
	NOISE $13
	NOISE $12
	NOISE $11
	SND_END

Snd08_SfxN:
	NVOICE $84, $61
	NOISE $02
	SND_END

Snd09_SfxN:
	NVOICE $01, $A1
	NOISE $58
	NOISE $82
	NOISE $93
	NOISE $A5
	SND_END

Snd0A_SfxN:
	NVOICE $02, $84
	LEN_UNIT $3A
	NOISE $11
	SND_END

Snd0B_SfxN:
	NVOICE $01, $F8
	NOISE $44
	NOISE_VOL $0A
	NOISE $26
	NOISE_VOL 9
	NOISE $43
	NVOICE $14, $71
	NOISE $34
	SND_END

Snd0C_SfxN:
	NVOICE $02, $E4
	LEN_UNIT $2A
	NOISE $11
	SND_END

Snd0D_SfxN:
	NVOICE $02, $D0
	NOISE $14
	NOISE $21
	NOISE $13
	NOISE $21
	NOISE $14
	NOISE $21
	NOISE $13
	NOISE $21
	NOISE $14
	NOISE $21
	NOISE $13
	NOISE $21
	NOISE $14
	NOISE $21
	NOISE $13
	NOISE $21
	NVOICE $02, $C0
	NOISE $14
	NOISE $21
	NOISE $13
	NOISE $21
	NOISE $14
	NOISE $21
	NOISE $13
	NOISE $21
	NOISE $14
	NOISE $21
	NOISE $13
	NOISE $21
	NOISE $14
	NOISE $21
	NOISE $13
	NOISE $21
	NVOICE $02, $B0
	NOISE $14
	NOISE $21
	NOISE $13
	NOISE $21
	NOISE $14
	NOISE $21
	NOISE $13
	NOISE $21
	NOISE $14
	NOISE $21
	NVOICE $02, $A0
	NOISE $14
	NOISE $21
	NOISE $13
	NOISE $21
	NOISE $14
	NOISE $21
	NOISE $13
	NOISE $21
	NOISE $14
	NOISE $21
	NVOICE $02, $80
	NOISE $14
	NOISE $21
	NOISE $13
	NOISE $21
	NOISE $14
	NOISE $21
	NOISE $13
	NOISE $21
	NOISE $14
	NOISE $21
	NVOICE $02, $70
	NOISE $14
	NOISE $21
	NOISE $13
	NOISE $21
	NOISE $14
	NOISE $21
	NOISE $13
	NOISE $21
	NOISE $14
	NOISE $21
	NVOICE $02, $50
	NOISE $14
	NOISE $21
	NOISE $13
	NOISE $21
	NOISE $14
	NOISE $21
	NOISE $13
	NOISE $21
	NOISE $14
	NOISE $21
	NVOICE $02, $40
	NOISE $14
	NOISE $21
	NOISE $13
	NOISE $21
	NOISE $14
	NOISE $21
	NOISE $13
	NOISE $21
	NOISE $14
	NOISE $21
	NVOICE $02, $20
	NOISE $14
	NOISE $21
	NOISE $13
	NOISE $21
	NOISE $14
	NOISE $21
	NOISE $13
	NOISE $21
	NOISE $14
	NOISE $21
	SND_END

Snd0E_SfxN:
	NVOICE $02, $F2
	NOISE $35
	NOISE $41
	NOISE $33
	NOISE $24
	NOISE $22
	NOISE $21
	NOISE $13
	NOISE $12
	NOISE $11
	NVOICE $02, $E2
	NOISE $35
	NOISE $41
	NOISE $33
	NOISE $24
	NOISE $22
	NOISE $21
	NOISE $13
	NOISE $12
	NOISE $11
	NVOICE $02, $A2
	NOISE $35
	NOISE $41
	NOISE $33
	NOISE $24
	NOISE $22
	NOISE $21
	NOISE $13
	NOISE $12
	NOISE $11
	NVOICE $02, $92
	NOISE $35
	NOISE $41
	NOISE $33
	NOISE $24
	NOISE $22
	NOISE $21
	NOISE $13
	NOISE $12
	NOISE $11
	NVOICE $02, $72
	NOISE $35
	NOISE $41
	NOISE $33
	NOISE $24
	NOISE $22
	NOISE $21
	NOISE $13
	NOISE $12
	NOISE $11
	NVOICE $02, $62
	NOISE $35
	NOISE $41
	NOISE $33
	NOISE $24
	NOISE $22
	NOISE $21
	NOISE $13
	NOISE $12
	NOISE $11
	NVOICE $02, $42
	NOISE $35
	NOISE $41
	NOISE $33
	NOISE $24
	NOISE $22
	NOISE $21
	NOISE $13
	NOISE $12
	NOISE $11
	NVOICE $02, $22
	NOISE $35
	NOISE $41
	NOISE $33
	NOISE $24
	NOISE $22
	NOISE $21
	NOISE $13
	NOISE $12
	NOISE $11
	SND_END

Snd0F_SfxN:
	SND_END

Snd101_SfxN:
	NVOICE $40, $41
	NOISE $21
	SND_END

Snd102_SfxN:
	NVOICE $40, $21
	NOISE $21
	SND_END

Snd103_SfxN:
	NVOICE $01, $81
	NOISE $46
	NVOICE $7F, $81
	NOISE $24
	SND_END

Snd104_SfxN:
	NVOICE $02, $50
	NOISE $25
	NVOICE $02, $16
	NOISE $25
	NVOICE $01, $10
	NOISE $26
	NOISE $27
	NOISE $26
	SND_END

Snd105_SfxN:
	NVOICE $7F, $51
	PAN_LEFT 0
	NOISE $21
	SND_END

Snd106_SfxN:
	NVOICE $7F, $51
	PAN_RIGHT 0
	NOISE $21
	SND_END

Snd107_SfxN:
	NVOICE $01, $61
	NOISE $46
	NVOICE $7F, $61
	NOISE $24
	SND_END

Snd108_SfxN:
	NVOICE $81, $58
	NOISE $07
	NVOICE $7F, $53
	NOISE $05
	SND_END

Snd109_SfxN:
	NVOICE $01, $71
	NOISE $58
	NOISE $81
	NOISE $93
	NOISE $A5
	NOISE $B7
	SND_END

Snd10A_SfxN:
	NVOICE $81, $68
	NOISE $07
	NVOICE $7F, $63
	NOISE $27
	SND_END

Snd10B_SfxN:
	NVOICE $81, $78
	NOISE $07
	NVOICE $7F, $73
	NOISE $15
	SND_END

Snd10_Sfx1:
	VVOICE $02, $00, $08
	OCTAVE 6
	VNOTE D_, 14
	VVOICE $03, $40, $08
	OCTAVE 5
	VNOTE D_, 13
	VNOTE A_, 13
	VNOTE D_, 13
	VNOTE A_, 13
	VNOTE D_, 13
	VNOTE A_, 13
	VNOTE D_, 6
	VNOTE A_, 6
	VNOTE D_, 6
	VNOTE A_, 6
	SND_END

Snd11_Sfx1:
	VVOICE $07, $40, $4C
	OCTAVE 5
	VNOTE E_, 12
	VNOTE E_, 6
	SND_END

Snd12_Sfx1:
	VVOICE $02, $80, $00
	OCTAVE 4
	VNOTE D#, 11
	VNOTE G_, 11
	VNOTE A#, 11
	OCTAVE 5
	VNOTE D_, 11
	VNOTE D#, 11
	VNOTE G_, 11
	VNOTE A#, 11
	OCTAVE 4
	VNOTE D#, 6
	VNOTE G_, 6
	VNOTE A#, 6
	OCTAVE 5
	VNOTE D_, 6
	VNOTE D#, 6
	VNOTE G_, 6
	VNOTE A#, 6
	OCTAVE 4
	VNOTE D#, 3
	VNOTE G_, 3
	VNOTE A#, 3
	OCTAVE 5
	VNOTE D#, 2
	VNOTE G_, 2
	VNOTE A#, 1
	SND_END

Snd13_Sfx1:
	VVOICE $01, $80, $44
	OCTAVE 4
	VNOTE E_, 15
	OCTAVE 3
	VNOTE B_, 15
	OCTAVE 4
	VNOTE E_, 15
	OCTAVE 3
	VNOTE B_, 15
	VREST 0
	VREST 0
	OCTAVE 4
	VNOTE E_, 15
	OCTAVE 3
	VNOTE B_, 15
	OCTAVE 4
	VNOTE E_, 15
	OCTAVE 3
	VNOTE B_, 15
	VREST 0
	VREST 0
	OCTAVE 4
	VNOTE E_, 15
	OCTAVE 3
	VNOTE B_, 15
	OCTAVE 4
	VNOTE E_, 15
	OCTAVE 3
	VNOTE B_, 15
	OCTAVE 4
	VNOTE E_, 15
	OCTAVE 3
	VNOTE B_, 15
	OCTAVE 4
	VNOTE E_, 15
	OCTAVE 3
	VNOTE B_, 15
	OCTAVE 4
	VNOTE E_, 15
	OCTAVE 3
	VNOTE B_, 15
	SND_END

Snd14_Sfx1:
	VVOICE $01, $80, $08
	OCTAVE 5
	VNOTE B_, 12
	OCTAVE 4
	VNOTE B_, 12
	OCTAVE 3
	VNOTE B_, 12
	VVOICE $07, $80, $65
	VNOTE B_, 12
	VNOTE B_, 6
	SND_END

Snd15_Sfx1:
	VVOICE $02, $80, $00
	OCTAVE 5
	VNOTE B_, 11
	VREST 0
	OCTAVE 4
	VNOTE B_, 11
	OCTAVE 3
	VNOTE B_, 6
	VREST 0
	OCTAVE 4
	VNOTE B_, 6
	SND_END

Snd16_Sfx1:
	VVOICE $01, $80, $08
	OCTAVE 5
	VNOTE E_, 11
	VNOTE A#, 11
	VNOTE A#, 11
	VNOTE E_, 6
	VNOTE A#, 6
	VNOTE A#, 6
	VNOTE A#, 3
	VNOTE A#, 3
	SND_END

Snd17_Sfx1:
	VVOICE $02, $80, $00
	OCTAVE 6
	VNOTE A_, 11
	VNOTE B_, 11
	OCTAVE 5
	VNOTE A_, 11
	OCTAVE 4
	VNOTE B_, 11
	OCTAVE 3
	VNOTE A_, 11
	OCTAVE 2
	VNOTE B_, 11
	OCTAVE 6
	VNOTE B_, 6
	OCTAVE 5
	VNOTE A_, 6
	OCTAVE 4
	VNOTE B_, 6
	OCTAVE 3
	VNOTE A_, 6
	OCTAVE 2
	VNOTE B_, 6
	OCTAVE 6
	VNOTE B_, 3
	OCTAVE 5
	VNOTE A_, 3
	OCTAVE 4
	VNOTE B_, 3
	OCTAVE 3
	VNOTE A_, 2
	OCTAVE 2
	VNOTE B_, 2
	SND_END

Snd18_Sfx1:
	VVOICE $01, $00, $08
	OCTAVE 2
	VNOTE E_, 15
	OCTAVE 3
	VNOTE E_, 15
	OCTAVE 2
	VNOTE E_, 15
	OCTAVE 3
	VNOTE E_, 15
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	LOOP_START
	OCTAVE 2
	VNOTE E_, 15
	OCTAVE 3
	VNOTE E_, 15
	OCTAVE 2
	VNOTE E_, 15
	OCTAVE 3
	VNOTE E_, 15
	OCTAVE 2
	VNOTE E_, 15
	OCTAVE 3
	VNOTE E_, 15
	LOOP_END $04
	SND_END

Snd18_SfxN:
	NVOICE $81, $80
	NOISE $3C
	NOISE $3C
	NOISE $3C
	NOISE $3C
	NOISE $00
	NOISE $00
	NOISE $00
	NOISE $00
	LOOP_START
	NOISE $3B
	NOISE $3B
	NOISE $3B
	LOOP_END $08
	SND_END

Snd19_SfxN:
	NVOICE $82, $F0
	NOISE $19
	NOISE $00
	NOISE $00
	NOISE $29
	NOISE $18
	SND_END

Snd1A_Sfx1:
	VVOICE $06, $40, $2D
	OCTAVE 5
	VNOTE F_, 12
	VVOICE $06, $00, $00
	VNOTE F_, 12
	OCTAVE 6
	VNOTE F_, 7
	VVOICE $06, $40, $2D
	OCTAVE 5
	VNOTE F_, 6
	VVOICE $06, $00, $00
	VNOTE F_, 6
	OCTAVE 6
	VNOTE F_, 3
	VNOTE F_, 2
	SND_END

Snd1B_Sfx1:
	VVOICE $02, $00, $37
	OCTAVE 6
	VNOTE F#, 14
	VNOTE F#, 8
	SND_END

Snd1C_Sfx1:
	VVOICE $01, $00, $00
	OCTAVE 5
	VNOTE F#, 14
	OCTAVE 6
	VNOTE F#, 14
	VNOTE F#, 9
	OCTAVE 5
	VNOTE F#, 9
	OCTAVE 6
	VNOTE F#, 9
	VNOTE F#, 5
	DUTY 4
	OCTAVE 5
	VNOTE F#, 14
	OCTAVE 6
	VNOTE F#, 14
	VNOTE F#, 9
	OCTAVE 5
	VNOTE F#, 9
	OCTAVE 6
	VNOTE F#, 9
	VNOTE F#, 5
	OCTAVE 5
	VNOTE F#, 8
	OCTAVE 6
	VNOTE F#, 8
	VNOTE F#, 4
	OCTAVE 5
	VNOTE F#, 4
	OCTAVE 6
	VNOTE F#, 4
	VNOTE F#, 3
	SND_END

Snd1C_SfxN:
	NVOICE $82, $F0
	NOISE $59
	NOISE $6A
	NOISE $79
	NOISE $00
	NOISE $6A
	NOISE $79
	NOISE_VOL 8
	NOISE $6F
	NOISE $6F
	SND_END

Snd1D_Sfx1:
	VVOICE $01, $00, $08
	OCTAVE 3
	VNOTE E_, 15
	OCTAVE 4
	VNOTE E_, 15
	OCTAVE 3
	VNOTE E_, 15
	OCTAVE 4
	VNOTE E_, 15
	OCTAVE 3
	VNOTE E_, 15
	SND_END

Snd1E_Sfx1:
	VVOICE $02, $80, $2E
	OCTAVE 5
	VNOTE C_, 14
	VVOICE $02, $80, $08
	OCTAVE 6
	VNOTE C_, 11
	OCTAVE 5
	VNOTE A_, 11
	VNOTE G_, 11
	VNOTE E_, 11
	VNOTE C_, 11
	OCTAVE 4
	VNOTE G_, 11
	VNOTE E_, 11
	VNOTE C_, 11
	OCTAVE 6
	VNOTE C_, 6
	OCTAVE 5
	VNOTE A_, 6
	VNOTE G_, 6
	VNOTE E_, 6
	VNOTE C_, 6
	OCTAVE 4
	VNOTE G_, 6
	VNOTE E_, 6
	VNOTE C_, 6
	OCTAVE 6
	VNOTE C_, 3
	OCTAVE 5
	VNOTE A_, 3
	VNOTE G_, 3
	VNOTE E_, 3
	VNOTE C_, 3
	OCTAVE 4
	VNOTE G_, 3
	VNOTE E_, 3
	VNOTE C_, 3
	OCTAVE 6
	VNOTE C_, 2
	OCTAVE 5
	VNOTE A_, 2
	VNOTE G_, 2
	VNOTE E_, 2
	VNOTE C_, 2
	OCTAVE 4
	VNOTE G_, 1
	VNOTE E_, 1
	VNOTE C_, 1
	SND_END

Snd1F_Sfx1:
	VVOICE $01, $80, $08
	OCTAVE 3
	VNOTE B_, 10
	OCTAVE 4
	VNOTE B_, 11
	OCTAVE 5
	VNOTE B_, 12
	VVOICE $07, $80, $5D
	VNOTE B_, 12
	VNOTE B_, 5
	SND_END

Snd20_Sfx1:
	VVOICE $01, $80, $00
	OCTAVE 4
	VNOTE D#, 7
	VNOTE E_, 8
	VNOTE F_, 9
	VNOTE F#, 9
	VNOTE G_, 9
	VNOTE G#, 9
	VVOICE $08, $80, $00
	VNOTE A_, 12
	VNOTE A_, 12
	VNOTE A_, 6
	VNOTE B_, 12
	VNOTE B_, 12
	VNOTE B_, 6
	VNOTE G_, 12
	VNOTE G_, 6
	VNOTE D_, 12
	VNOTE D_, 12
	VNOTE D_, 6
	VNOTE D_, 3
	VNOTE A_, 12
	VNOTE A_, 6
	VVOICE $04, $80, $00
	VNOTE F#, 12
	VNOTE A_, 12
	VVOICE $08, $80, $00
	OCTAVE 5
	VNOTE D_, 12
	VNOTE D_, 12
	VNOTE D_, 11
	VNOTE D_, 9
	VVOICE $04, $80, $00
	VNOTE D_, 7
	VNOTE D#, 5
	VNOTE D_, 6
	VNOTE D#, 7
	VNOTE D_, 8
	VNOTE D#, 9
	VNOTE D_, 11
	VNOTE D#, 12
	VNOTE D_, 6
	VNOTE D#, 6
	VNOTE D_, 6
	VNOTE D#, 6
	SND_END

Snd20_Sfx2:
	VVOICE $01, $30, $00
	WAVE_X $0F
	OCTAVE 3
	VNOTE C_, 2
	VNOTE C#, 2
	VNOTE D_, 2
	VNOTE D#, 2
	VNOTE E_, 2
	VNOTE F_, 2
	VVOICE $08, $30, $00
	WAVE_X $0F
	OCTAVE 2
	VNOTE F#, 2
	OCTAVE 3
	VNOTE F#, 2
	VNOTE F#, 4
	OCTAVE 2
	VNOTE G_, 2
	OCTAVE 3
	VNOTE G_, 2
	VNOTE G_, 4
	VNOTE D_, 2
	VNOTE D_, 4
	OCTAVE 2
	VNOTE B_, 2
	VVOICE $04, $30, $00
	WAVE_X $0F
	OCTAVE 3
	VNOTE B_, 2
	OCTAVE 4
	VNOTE D_, 2
	VNOTE G_, 2
	VNOTE B_, 2
	OCTAVE 5
	VNOTE D_, 2
	VNOTE G_, 2
	VVOICE $08, $30, $00
	WAVE_X $0F
	OCTAVE 2
	VNOTE C#, 2
	VNOTE C#, 4
	VVOICE $04, $30, $00
	WAVE_X $0F
	OCTAVE 2
	VNOTE A_, 2
	OCTAVE 3
	VNOTE C#, 2
	VVOICE $08, $30, $00
	WAVE_X $0F
	VNOTE F#, 2
	VNOTE F#, 2
	VNOTE F#, 2
	VNOTE F#, 2
	VNOTE F#, 2
	VNOTE F#, 2
	VNOTE F#, 2
	VNOTE F#, 2
	VNOTE F#, 4
	VNOTE F#, 4
	SND_END

Snd20_SfxN:
	NVOICE $01, $61
	NOISE $13
	NOISE $12
	NOISE $11
	NOISE_VOL 1
	NOISE $11
	NOISE $10
	NOISE $10
	LOOP_START
	NVOICE $01, $A1
	NOISE $58
	NOISE $82
	NOISE $93
	NOISE $A5
	NVOICE $04, $10
	NOISE $77
	NVOICE $01, $61
	NOISE $13
	NOISE $12
	NOISE $11
	NOISE_VOL 1
	NOISE $11
	NVOICE $04, $10
	NOISE $77
	NVOICE $01, $C0
	NOISE $41
	NOISE_VOL $0A
	NOISE $32
	NOISE_VOL 7
	NOISE $23
	NVOICE $05, $43
	NOISE $11
	LOOP_END $03
	NVOICE $02, $84
	NOISE $3A
	NOISE $11
	NVOICE $04, $10
	NOISE $77
	LOOP2_START
	NVOICE $01, $C0
	NOISE $41
	NOISE_VOL $0A
	NOISE $32
	NOISE_VOL 7
	NOISE $23
	NVOICE $05, $43
	NOISE $11
	LOOP2_END $03
	NVOICE $06, $10
	NOISE $77
	NVOICE $01, $61
	NOISE $13
	NOISE $12
	NOISE $11
	NOISE_VOL 1
	NOISE $11
	NVOICE $01, $61
	NOISE $13
	NOISE $12
	NOISE $11
	NOISE_VOL 1
	NOISE $11
	NVOICE $01, $C0
	NOISE $41
	NOISE_VOL $0A
	NOISE $32
	NOISE_VOL 7
	NOISE $23
	NVOICE $05, $43
	NOISE $11
	NVOICE $03, $40
	NOISE_VOL 1
	NOISE $35
	NOISE_VOL 2
	NOISE $35
	NOISE_VOL 3
	NOISE $35
	NOISE_VOL 4
	NOISE $35
	NOISE_VOL 5
	NOISE $35
	NOISE_VOL 6
	NOISE $36
	NOISE $36
	NOISE_VOL 7
	NOISE $36
	NOISE $36
	NOISE_VOL 8
	NOISE $36
	NOISE $36
	NOISE $36
	NOISE $36
	NOISE_VOL 9
	NOISE $36
	NOISE $36
	NOISE $36
	NOISE_VOL 8
	NOISE $36
	NOISE $36
	NOISE_VOL 7
	NOISE $36
	NOISE $36
	NOISE $36
	NOISE $36
	NOISE_VOL 6
	NOISE $36
	NOISE $36
	NOISE $36
	NOISE $36
	NOISE_VOL 5
	NOISE $36
	NOISE $36
	NOISE $36
	NOISE $36
	NOISE_VOL 4
	NOISE $36
	NOISE $36
	NOISE $36
	NVOICE $30, $47
	NOISE $36
	SND_END

Snd21_Sfx1:
	VVOICE $02, $40, $00
	OCTAVE 5
	VNOTE A_, 12
	VNOTE E_, 12
	VVOICE $01, $40, $00
	VREST 0
	VVOICE $02, $40, $00
	VNOTE B_, 12
	VNOTE F#, 12
	VNOTE B_, 12
	VNOTE F#, 12
	VVOICE $01, $40, $00
	VREST 0
	VVOICE $02, $40, $00
	VNOTE B_, 7
	VNOTE F#, 7
	VNOTE B_, 7
	VNOTE F#, 7
	VVOICE $01, $40, $00
	VREST 0
	VVOICE $02, $40, $00
	VNOTE B_, 4
	VNOTE F#, 4
	VNOTE B_, 4
	VNOTE F#, 4
	SND_END

Snd21_SfxN:
	NVOICE $02, $C0
	NOISE $37
	NOISE $23
	NVOICE $01, $C0
	NOISE $00
	NVOICE $02, $C0
	NOISE $20
	NOISE $23
	NOISE $25
	NOISE $26
	NVOICE $01, $70
	NOISE $00
	NVOICE $02, $70
	NOISE $30
	NOISE $33
	NOISE $35
	NOISE $36
	NVOICE $01, $40
	NOISE $00
	NVOICE $02, $40
	NOISE $40
	NOISE $43
	NOISE $45
	NOISE $46
	SND_END

Snd22_Sfx1:
	VVOICE $06, $80, $08
	OCTAVE 5
	VNOTE D#, 12
	VREST 4
	VNOTE E_, 12
	VREST 0
	VNOTE F#, 12
	VREST 0
	VNOTE D#, 12
	VREST 0
	VNOTE F#, 12
	VREST 0
	VNOTE E_, 12
	VREST 0
	VNOTE D#, 12
	VREST 0
	VNOTE D#, 12
	VREST 0
	VNOTE E_, 12
	VREST 0
	VNOTE F#, 12
	SND_END

Snd22_Sfx2:
	VVOICE $06, $20, $08
	OCTAVE 4
	VNOTE F_, 2
	VREST 0
	VNOTE F_, 2
	VREST 0
	VNOTE F_, 2
	VREST 0
	VNOTE G_, 2
	VREST 0
	VNOTE G_, 2
	VREST 0
	VNOTE G_, 2
	VREST 0
	VNOTE G#, 2
	VREST 7
	VNOTE F_, 2
	VREST 0
	VNOTE F_, 2
	VREST 0
	VNOTE F_, 2
	SND_END

Snd23_Sfx2:
	VVOICE $16, $10, $08
	SND_SEGNO
	LOOP_END $E4 ; loop byte read both as a start and as an end (see doc)
	VNOTE G_, 10
	VREST 0
	VREST 0
	SND_LOOP

Snd25_Sfx1:
	VVOICE $01, $40, $2F
	OCTAVE 5
	VNOTE C_, 10
	VNOTE C#, 11
	VNOTE D_, 12
	VNOTE D#, 12
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE D#, 10
	VNOTE D_, 7
	VNOTE C#, 4
	OCTAVE 4
	VNOTE C#, 4
	OCTAVE 3
	VNOTE C#, 4
	OCTAVE 2
	VNOTE C#, 4
	OCTAVE 3
	VNOTE C#, 4
	OCTAVE 4
	VNOTE C#, 4
	OCTAVE 5
	VNOTE C_, 10
	VNOTE C#, 11
	VNOTE D_, 12
	VNOTE D#, 12
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE D#, 10
	VNOTE D_, 7
	VNOTE C#, 4
	VNOTE E_, 7
	VNOTE F_, 7
	VNOTE E_, 7
	VNOTE F_, 7
	VNOTE E_, 7
	VNOTE F_, 7
	VNOTE E_, 7
	VNOTE D#, 6
	VNOTE D_, 5
	VNOTE C#, 4
	SND_END

Snd25_Sfx2:
	VVOICE $01, $00, $08
	INSTRUMENT $07
	OCTAVE 5
	VNOTE C_, 6
	VNOTE C#, 4
	VNOTE D_, 2
	VNOTE D#, 2
	VNOTE E_, 2
	VNOTE F_, 2
	VNOTE F_, 2
	VNOTE E_, 2
	VNOTE F_, 2
	VNOTE E_, 2
	VNOTE F_, 2
	VNOTE E_, 2
	VNOTE F_, 2
	VNOTE E_, 2
	VNOTE F_, 2
	VNOTE E_, 2
	VNOTE D#, 2
	VNOTE D_, 4
	VNOTE C#, 6
	OCTAVE 4
	VNOTE C#, 4
	OCTAVE 3
	VNOTE C#, 4
	OCTAVE 2
	VNOTE C#, 4
	OCTAVE 3
	VNOTE C#, 4
	OCTAVE 4
	VNOTE C#, 4
	OCTAVE 5
	VNOTE C_, 6
	VNOTE C#, 4
	VNOTE D_, 2
	VNOTE D#, 2
	VNOTE E_, 2
	VNOTE F_, 2
	VNOTE F_, 2
	VNOTE E_, 2
	VNOTE F_, 2
	VNOTE E_, 2
	VNOTE F_, 2
	VNOTE E_, 2
	VNOTE F_, 2
	VNOTE E_, 2
	VNOTE F_, 2
	VNOTE E_, 2
	VNOTE F_, 2
	VNOTE E_, 2
	VNOTE F_, 2
	VNOTE E_, 2
	VNOTE F_, 2
	VNOTE E_, 2
	VNOTE D#, 2
	VNOTE D_, 4
	VNOTE C#, 6
	INSTRUMENT $00
	SND_END

Snd26_Sfx1:
	VVOICE $04, $40, $08
	OCTAVE 3
	VNOTE A_, 14
	VVOICE $01, $40, $08
	VNOTE B_, 8
	OCTAVE 4
	VNOTE C_, 10
	VNOTE C#, 12
	VVOICE $04, $40, $08
	VNOTE D_, 13
	VVOICE $04, $40, $08
	OCTAVE 3
	VNOTE A_, 14
	TRANSPOSE_DOWN 2
	VVOICE $01, $40, $08
	OCTAVE 3
	VNOTE B_, 8
	OCTAVE 4
	VNOTE C_, 10
	VNOTE C#, 12
	VVOICE $04, $40, $08
	VNOTE D_, 13
	VVOICE $01, $40, $08
	VNOTE C#, 10
	VNOTE C_, 7
	VVOICE $04, $40, $08
	VNOTE D_, 7
	VVOICE $01, $40, $08
	VNOTE C#, 5
	VNOTE C_, 4
	SND_END

Snd26_Sfx2:
	VVOICE $04, $30, $00
	INSTRUMENT $07
	OCTAVE 3
	VNOTE A_, 2
	VVOICE $01, $30, $00
	VNOTE B_, 4
	OCTAVE 4
	VNOTE C_, 6
	VNOTE C#, 4
	VVOICE $04, $30, $00
	VNOTE D_, 2
	VVOICE $04, $30, $00
	OCTAVE 3
	VNOTE A_, 2
	TRANSPOSE_DOWN 2
	VVOICE $01, $40, $08
	OCTAVE 3
	VNOTE B_, 2
	OCTAVE 4
	VNOTE C_, 2
	VNOTE C#, 2
	VVOICE $04, $40, $08
	VNOTE D_, 2
	VVOICE $01, $40, $08
	VNOTE C#, 4
	VNOTE C_, 6
	TRANSPOSE_UP 0
	INSTRUMENT $00
	SND_END

Snd27_Sfx1:
	VVOICE $02, $40, $08
	OCTAVE 4
	VNOTE D_, 8
	VNOTE D_, 10
	VNOTE D#, 12
	VREST 0
	OCTAVE 4
	DUTY 0
	VNOTE F_, 12
	VNOTE F_, 12
	VNOTE F_, 12
	VREST 0
	VNOTE F_, 15
	VNOTE F_, 10
	VNOTE F_, 12
	VREST 0
	DUTY 8
	VNOTE F_, 8
	VNOTE F_, 10
	VREST 0
	DUTY 0
	VNOTE D#, 8
	VNOTE E_, 10
	VNOTE F_, 12
	VNOTE F_, 12
	VNOTE F#, 12
	VNOTE F_, 12
	VNOTE F#, 12
	VNOTE F_, 12
	SND_END

Snd27_Sfx2:
	VVOICE $02, $00, $08
	INSTRUMENT $07
	OCTAVE 3
	VNOTE D_, 2
	VNOTE D_, 2
	VNOTE D#, 2
	VREST 0
	OCTAVE 3
	VNOTE F_, 6
	VNOTE F_, 4
	VNOTE F_, 2
	VREST 0
	VNOTE F_, 2
	VNOTE F_, 2
	VNOTE F_, 2
	VREST 0
	VNOTE F_, 2
	VNOTE F_, 4
	VREST 0
	VNOTE D#, 2
	VNOTE E_, 2
	VNOTE F_, 2
	VNOTE F_, 2
	VNOTE F#, 2
	VNOTE F_, 2
	VNOTE F#, 2
	VNOTE F_, 2
	INSTRUMENT $00
	SND_END

Snd28_Sfx1:
	VVOICE $01, $00, $08
	OCTAVE 6
	VNOTE G_, 13
	VVOICE $0C, $00, $24
	OCTAVE 5
	VNOTE F_, 13
	VVOICE $01, $00, $33
	OCTAVE 3
	VNOTE G_, 13
	VVOICE $04, $40, $08
	VNOTE A_, 13
	VVOICE $01, $40, $08
	VREST 0
	OCTAVE 3
	VNOTE B_, 15
	OCTAVE 4
	VNOTE D_, 11
	VNOTE C#, 13
	VNOTE C#, 13
	VNOTE C#, 13
	VNOTE C#, 13
	VNOTE C#, 13
	VNOTE C_, 13
	VNOTE C_, 13
	VNOTE C_, 13
	OCTAVE 3
	VNOTE F_, 10
	VNOTE E_, 11
	VNOTE D#, 12
	VNOTE D_, 13
	VNOTE D_, 13
	VNOTE D_, 8
	SND_END

Snd28_Sfx2:
	VVOICE $01, $00, $08
	INSTRUMENT $06
	VREST 0
	VVOICE $05, $00, $08
	OCTAVE 5
	VNOTE D_, 2
	VVOICE $07, $00, $08
	VREST 0
	VVOICE $01, $00, $33
	INSTRUMENT $07
	VNOTE G_, 2
	VVOICE $04, $40, $08
	VNOTE A_, 2
	VVOICE $01, $40, $08
	VREST 0
	OCTAVE 2
	VNOTE B_, 2
	OCTAVE 3
	VNOTE D_, 6
	VNOTE C#, 4
	VNOTE C#, 2
	VNOTE C#, 2
	VNOTE C#, 2
	VNOTE C#, 2
	VNOTE C_, 4
	VNOTE C_, 6
	VNOTE C_, 6
	OCTAVE 2
	VNOTE F_, 6
	VNOTE E_, 4
	VNOTE D#, 2
	VNOTE D_, 2
	VNOTE D_, 2
	VNOTE D_, 2
	INSTRUMENT $00
	SND_END

Snd29_Sfx1:
	TRANSPOSE_UP 3
	VVOICE $02, $00, $08
	OCTAVE 3
	VNOTE E_, 6
	VNOTE F_, 9
	VNOTE F#, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE D#, 12
	VNOTE D_, 9
	VNOTE C#, 6
	VNOTE D_, 6
	VNOTE D#, 9
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE F_, 13
	VNOTE D#, 4
	VNOTE E_, 5
	VNOTE F_, 6
	VNOTE F_, 6
	TRANSPOSE_UP 0
	SND_END

Snd29_Sfx2:
	TRANSPOSE_UP 3
	VVOICE $02, $00, $08
	INSTRUMENT $06
	OCTAVE 4
	VNOTE E_, 2
	VNOTE F_, 2
	VNOTE F#, 2
	VNOTE F_, 2
	VNOTE E_, 2
	VNOTE D#, 2
	VNOTE D_, 4
	VNOTE C#, 6
	VNOTE D_, 6
	VNOTE D#, 4
	VNOTE E_, 2
	VNOTE F_, 2
	VNOTE F_, 2
	TRANSPOSE_UP 0
	INSTRUMENT $00
	SND_END

Snd2A_Sfx1:
	TRANSPOSE_DOWN 3
	VVOICE $01, $40, $2F
	OCTAVE 5
	VNOTE C_, 10
	VNOTE C#, 11
	VNOTE D_, 12
	VNOTE D#, 12
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE D#, 10
	VNOTE D_, 7
	VNOTE C#, 4
	VNOTE E_, 7
	VNOTE F_, 7
	VNOTE E_, 7
	VNOTE F_, 7
	VNOTE E_, 7
	VNOTE F_, 7
	VNOTE E_, 7
	VNOTE D#, 6
	VNOTE D_, 5
	VNOTE C#, 4
	TRANSPOSE_UP 0
	SND_END

Snd2A_Sfx2:
	TRANSPOSE_DOWN 3
	VVOICE $01, $00, $08
	INSTRUMENT $07
	OCTAVE 5
	VNOTE C_, 10
	VNOTE C#, 11
	VNOTE D_, 12
	VNOTE D#, 12
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE D#, 10
	VNOTE D_, 7
	VNOTE C#, 4
	TRANSPOSE_UP 0
	INSTRUMENT $00
	SND_END

Snd2B_Sfx1:
	VVOICE $02, $80, $00
	OCTAVE 5
	VNOTE B_, 11
	VREST 0
	OCTAVE 4
	VNOTE B_, 11
	OCTAVE 3
	VNOTE B_, 6
	VREST 0
	OCTAVE 4
	VNOTE B_, 6
	SND_SEGNO
	VVOICE $25, $00, $08
	VREST 0
	VVOICE $01, $00, $27
	OCTAVE 5
	VNOTE D_, 6
	VNOTE F_, 7
	VNOTE F#, 7
	VNOTE G_, 7
	VNOTE G#, 7
	VNOTE G#, 6
	VNOTE A_, 6
	VNOTE G#, 6
	VNOTE A_, 5
	VNOTE G#, 4
	VNOTE A_, 3
	VNOTE G#, 2
	LOOP_START
	VVOICE $01, $00, $08
	OCTAVE 4
	VNOTE F_, 5
	DUTY 4
	VNOTE F#, 5
	DUTY 0
	VNOTE G_, 5
	VNOTE F_, 3
	DUTY 4
	VNOTE F#, 3
	DUTY 0
	VNOTE G_, 3
	VVOICE $10, $00, $08
	VREST 0
	LOOP_END $02
	VVOICE $1F, $00, $08
	VREST 0
	VVOICE $09, $00, $27
	VREST 0
	VVOICE $01, $00, $27
	OCTAVE 5
	VNOTE C#, 6
	VNOTE D_, 6
	VNOTE D#, 6
	VNOTE E_, 6
	VNOTE F_, 6
	VNOTE F_, 6
	VNOTE F#, 6
	VNOTE F_, 6
	VNOTE F#, 5
	VNOTE F_, 4
	VNOTE F#, 3
	VNOTE F_, 2
	OCTAVE 5
	VNOTE C#, 3
	VNOTE D_, 3
	VNOTE D#, 3
	VNOTE E_, 3
	VNOTE F_, 3
	VNOTE F_, 3
	VNOTE F#, 3
	VNOTE F_, 3
	VNOTE F#, 2
	VNOTE F_, 2
	VNOTE F#, 1
	VNOTE F_, 1
	VVOICE $29, $00, $27
	VREST 0
	VVOICE $01, $00, $27
	OCTAVE 3
	VNOTE G_, 6
	DUTY 8
	VNOTE G_, 8
	VNOTE G_, 10
	VNOTE G_, 11
	VNOTE G_, 11
	VNOTE F#, 11
	VNOTE F_, 12
	VNOTE E_, 9
	VNOTE D#, 6
	VNOTE G_, 3
	VNOTE G_, 4
	VNOTE G_, 6
	VNOTE G_, 7
	VNOTE G_, 7
	VNOTE F#, 7
	VNOTE F_, 6
	VNOTE E_, 4
	VNOTE D#, 3
	VVOICE $01, $00, $08
	OCTAVE 4
	VNOTE A_, 9
	VNOTE A_, 9
	DUTY 4
	VNOTE A#, 9
	DUTY 0
	VNOTE B_, 9
	OCTAVE 5
	DUTY 4
	VNOTE C_, 9
	VNOTE C_, 9
	VNOTE C#, 9
	VNOTE C_, 9
	VNOTE C#, 9
	VNOTE C_, 9
	VNOTE C#, 9
	VNOTE C_, 9
	VNOTE C#, 9
	DUTY 0
	VNOTE C_, 9
	OCTAVE 4
	VNOTE B_, 9
	VNOTE A#, 7
	VNOTE A_, 6
	VNOTE G#, 4
	OCTAVE 5
	DUTY 4
	VNOTE C_, 5
	VNOTE C_, 5
	VNOTE C#, 5
	VNOTE C_, 5
	VNOTE C#, 5
	VNOTE C_, 5
	VNOTE C#, 5
	VNOTE C_, 5
	VNOTE C#, 5
	DUTY 0
	VNOTE C_, 5
	OCTAVE 4
	VNOTE B_, 5
	VNOTE A#, 10
	VNOTE A_, 4
	VNOTE G#, 3
	VVOICE $07, $00, $27
	VREST 0
	VREST 0
	VVOICE $01, $00, $08
	OCTAVE 2
	VNOTE F_, 6
	VNOTE E_, 6
	OCTAVE 3
	VNOTE F#, 7
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G_, 8
	VNOTE F#, 6
	OCTAVE 3
	VNOTE G#, 6
	VNOTE G_, 6
	OCTAVE 2
	VNOTE A_, 3
	VNOTE G#, 3
	VREST 0
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G#, 6
	OCTAVE 2
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G#, 6
	OCTAVE 2
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G#, 6
	OCTAVE 2
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G#, 6
	VNOTE F_, 4
	OCTAVE 4
	VNOTE G#, 4
	OCTAVE 2
	VNOTE F_, 4
	OCTAVE 4
	VNOTE G#, 4
	OCTAVE 2
	VNOTE F_, 4
	OCTAVE 4
	VNOTE G#, 4
	OCTAVE 2
	VNOTE F_, 4
	OCTAVE 4
	VNOTE G#, 4
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VNOTE F_, 6
	VNOTE E_, 6
	OCTAVE 3
	VNOTE F#, 7
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G_, 8
	VNOTE F#, 6
	OCTAVE 3
	VNOTE G#, 6
	VNOTE G_, 6
	OCTAVE 2
	VNOTE A_, 3
	VNOTE G#, 3
	VREST 0
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G#, 6
	OCTAVE 2
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G#, 6
	OCTAVE 2
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G#, 6
	OCTAVE 2
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G#, 6
	VNOTE F_, 4
	OCTAVE 4
	VNOTE G#, 4
	OCTAVE 2
	VNOTE F_, 4
	OCTAVE 4
	VNOTE G#, 4
	OCTAVE 2
	VNOTE F_, 4
	OCTAVE 4
	VNOTE G#, 4
	OCTAVE 2
	VNOTE F_, 4
	OCTAVE 4
	VNOTE G#, 4
	LOOP_START
	VVOICE $01, $00, $08
	OCTAVE 4
	VNOTE F_, 5
	DUTY 4
	VNOTE F#, 5
	DUTY 0
	VNOTE G_, 5
	VNOTE F_, 3
	DUTY 4
	VNOTE F#, 3
	DUTY 0
	VNOTE G_, 3
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	LOOP_END $02
	VVOICE $28, $00, $08
	VREST 0
	VVOICE $01, $00, $08
	TRANSPOSE_DOWN 1
	VNOTE F_, 6
	VNOTE E_, 6
	OCTAVE 3
	VNOTE F#, 7
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G_, 8
	VNOTE F#, 6
	OCTAVE 3
	VNOTE G#, 6
	VNOTE G_, 6
	OCTAVE 2
	VNOTE A_, 3
	VNOTE G#, 3
	VREST 0
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G#, 6
	OCTAVE 2
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G#, 6
	OCTAVE 2
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G#, 6
	OCTAVE 2
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G#, 6
	VNOTE F_, 4
	OCTAVE 4
	VNOTE G#, 4
	OCTAVE 2
	VNOTE F_, 4
	OCTAVE 4
	VNOTE G#, 4
	OCTAVE 2
	VNOTE F_, 4
	OCTAVE 4
	VNOTE G#, 4
	OCTAVE 2
	VNOTE F_, 4
	OCTAVE 4
	VNOTE G#, 4
	TRANSPOSE_UP 0
	VVOICE $01, $00, $08
	OCTAVE 4
	VNOTE F_, 5
	DUTY 4
	VNOTE F#, 5
	DUTY 0
	VNOTE G_, 5
	VNOTE F_, 3
	DUTY 4
	VNOTE F#, 3
	DUTY 0
	VNOTE G_, 3
	VVOICE $2D, $00, $08
	VREST 0
	SND_LOOP
	db $FF ; unreachable end

Snd2C_Sfx1:
	VVOICE $02, $00, $1C
	OCTAVE 3
	VNOTE A_, 7
	VVOICE $08, $80, $26
	OCTAVE 4
	VNOTE C#, 11
	VNOTE C#, 6
	SND_END

Snd2D_Sfx1:
	VVOICE $04, $00, $55
	OCTAVE 3
	VNOTE A_, 15
	VVOICE $08, $00, $4E
	OCTAVE 5
	VNOTE B_, 15
	OCTAVE 6
	VNOTE C#, 8
	VNOTE D_, 7
	VNOTE E_, 6
	OCTAVE 5
	VNOTE B_, 8
	OCTAVE 6
	VNOTE C#, 5
	VNOTE D_, 4
	VNOTE E_, 3
	SND_END

Snd2E_Sfx1:
	VVOICE $02, $80, $00
	OCTAVE 3
	VNOTE B_, 9
	OCTAVE 4
	VNOTE C_, 10
	VNOTE C#, 11
	VNOTE D_, 12
	VNOTE D#, 13
	VNOTE D_, 13
	VNOTE D#, 13
	VNOTE E_, 13
	VNOTE F_, 13
	VNOTE F#, 13
	OCTAVE 3
	VNOTE B_, 4
	OCTAVE 4
	VNOTE C_, 5
	VNOTE C#, 5
	VNOTE D_, 6
	VNOTE D#, 6
	OCTAVE 4
	VNOTE E_, 6
	VNOTE F_, 6
	VNOTE F#, 6
	OCTAVE 4
	VNOTE C_, 4
	VNOTE C#, 4
	VNOTE D_, 5
	VNOTE D#, 5
	OCTAVE 4
	VNOTE E_, 5
	VNOTE F_, 5
	VNOTE F#, 5
	SND_END

Snd2F_Sfx1:
	VVOICE $02, $40, $08
	OCTAVE 6
	VNOTE E_, 10
	VNOTE F_, 10
	OCTAVE 5
	VNOTE E_, 10
	VNOTE F_, 10
	VNOTE E_, 10
	VNOTE F_, 10
	VNOTE E_, 10
	VNOTE F_, 10
	VNOTE E_, 5
	VNOTE F_, 5
	VNOTE E_, 5
	VNOTE F_, 5
	VNOTE E_, 5
	VNOTE F_, 5
	SND_END

Snd30_Sfx1:
	VVOICE $01, $00, $08
	OCTAVE 6
	VNOTE C#, 11
	VNOTE D_, 12
	VNOTE D#, 13
	VNOTE E_, 14
	VNOTE F_, 14
	VNOTE E_, 14
	VNOTE F_, 14
	VNOTE D#, 13
	VNOTE E_, 13
	VNOTE D#, 13
	VNOTE E_, 13
	VNOTE D_, 13
	VNOTE D#, 13
	VNOTE D_, 13
	VNOTE D#, 13
	VNOTE C#, 12
	VNOTE D_, 12
	VNOTE C#, 12
	VNOTE D_, 12
	VNOTE C_, 12
	VNOTE C#, 12
	VNOTE C_, 12
	VNOTE C#, 12
	DUTY 4
	VNOTE C#, 11
	VNOTE D_, 11
	VNOTE C#, 11
	VNOTE D_, 11
	VNOTE C_, 10
	VNOTE C#, 10
	VNOTE C_, 10
	VNOTE C#, 10
	OCTAVE 5
	VNOTE B_, 10
	OCTAVE 6
	VNOTE C_, 10
	OCTAVE 5
	VNOTE B_, 10
	OCTAVE 6
	VNOTE C_, 10
	OCTAVE 5
	VNOTE A#, 10
	VNOTE B_, 10
	VNOTE A#, 10
	VNOTE B_, 10
	VNOTE A_, 9
	VNOTE A#, 9
	VNOTE A_, 9
	VNOTE A#, 9
	DUTY 8
	VNOTE A#, 10
	VNOTE B_, 10
	VNOTE A#, 10
	VNOTE B_, 10
	VNOTE A_, 9
	VNOTE A#, 9
	VNOTE A_, 9
	VNOTE A#, 9
	VNOTE G#, 8
	VNOTE A_, 8
	VNOTE G#, 8
	VNOTE A_, 8
	VNOTE G_, 8
	VNOTE G#, 8
	VNOTE G_, 8
	VNOTE G#, 8
	VNOTE F#, 7
	VNOTE G_, 7
	VNOTE F#, 7
	VNOTE G_, 7
	VNOTE G#, 5
	VNOTE A_, 5
	VNOTE G#, 5
	VNOTE A_, 5
	VNOTE G_, 4
	VNOTE G#, 4
	VNOTE G_, 4
	VNOTE G#, 4
	VNOTE F#, 3
	VNOTE G_, 3
	VNOTE F#, 3
	VNOTE G_, 3
	VNOTE G#, 1
	VNOTE A_, 1
	VNOTE G#, 1
	VNOTE A_, 1
	SND_END

Snd31_Sfx1:
	VVOICE $01, $80, $3E
	VNOTE G_, 6
	OCTAVE 6
	VNOTE D_, 13
	VNOTE D#, 13
	VNOTE E_, 13
	VNOTE F#, 9
	VNOTE G#, 8
	VNOTE A_, 7
	VNOTE B_, 6
	VVOICE $02, $80, $26
	OCTAVE 4
	VNOTE A_, 13
	OCTAVE 5
	VNOTE E_, 13
	VVOICE $02, $80, $3E
	OCTAVE 6
	VNOTE D#, 13
	VNOTE E_, 13
	VNOTE D#, 9
	VNOTE D_, 8
	VNOTE C#, 7
	VNOTE C_, 7
	OCTAVE 5
	VNOTE B_, 6
	VVOICE $02, $80, $26
	OCTAVE 4
	VNOTE A#, 6
	OCTAVE 5
	VNOTE F_, 6
	VVOICE $02, $80, $3E
	OCTAVE 6
	VNOTE E_, 7
	VNOTE D#, 6
	VNOTE D_, 5
	VNOTE C#, 5
	VNOTE C_, 4
	OCTAVE 5
	VNOTE B_, 3
	OCTAVE 6
	VNOTE D_, 4
	VNOTE C#, 3
	VNOTE C_, 2
	OCTAVE 5
	VNOTE B_, 1
	VNOTE F#, 0
	SND_END

Snd32_Sfx1:
	VVOICE $01, $80, $00
	OCTAVE 5
	VNOTE A_, 9
	OCTAVE 6
	VNOTE A#, 9
	VREST 0
	VREST 0
	VREST 0
	OCTAVE 4
	VNOTE A_, 9
	OCTAVE 5
	VNOTE A#, 9
	OCTAVE 5
	VNOTE A_, 5
	OCTAVE 6
	VNOTE A#, 5
	VREST 0
	VREST 0
	OCTAVE 4
	VNOTE A_, 5
	OCTAVE 5
	VNOTE A#, 5
	SND_END

Snd33_Sfx1:
	VVOICE $01, $80, $08
	OCTAVE 6
	VNOTE F#, 12
	OCTAVE 4
	VNOTE D_, 12
	OCTAVE 5
	VNOTE A_, 12
	OCTAVE 6
	VNOTE F#, 12
	VNOTE D_, 12
	VNOTE D_, 12
	VNOTE F#, 6
	OCTAVE 4
	VNOTE D_, 6
	OCTAVE 5
	VNOTE A_, 6
	OCTAVE 6
	VNOTE F#, 6
	VNOTE D_, 6
	VNOTE D_, 6
	VNOTE F#, 3
	OCTAVE 4
	VNOTE D_, 3
	OCTAVE 5
	VNOTE A_, 3
	OCTAVE 6
	VNOTE F#, 3
	VNOTE D_, 3
	VNOTE D_, 3
	SND_END

Snd34_Sfx1:
	VVOICE $01, $00, $00
	OCTAVE 6
	VNOTE G#, 14
	VVOICE $04, $40, $00
	VNOTE G#, 12
	SND_END

Snd35_SfxN:
	NVOICE $01, $E0
	NOISE $34
	NOISE $35
	NOISE $36
	NOISE $00
	NVOICE $02, $A3
	NOISE $27
	NOISE $25
	NOISE $23
	NOISE $34
	NOISE $35
	NOISE $36
	NOISE $43
	NOISE $42
	NOISE $41
	SND_END

Snd36_SfxN:
	NVOICE $82, $D0
	NOISE $2F
	NOISE $1E
	NVOICE $81, $D0
	NOISE $00
	NVOICE $82, $D0
	NOISE $39
	NOISE $4B
	NOISE $00
	NVOICE $82, $90
	NOISE $4A
	NOISE $4B
	NOISE $4C
	NOISE $4D
	NOISE $4E
	NOISE $4F
	NVOICE $81, $60
	NOISE $4B
	NOISE $4C
	NOISE $4D
	NOISE $4E
	NOISE $4F
	SND_END

Snd37_SfxN:
	NVOICE $02, $C0
	NOISE $13
	NOISE $00
	NOISE $4A
	NOISE $00
	NOISE $23
	NOISE $00
	NOISE $24
	NOISE $33
	NOISE $34
	NOISE $43
	NOISE $44
	NOISE_VOL 6
	NOISE $33
	NOISE $34
	NOISE $43
	NOISE $44
	NOISE $53
	NOISE $54
	SND_END

Snd38_SfxN:
	NVOICE $01, $C0
	NOISE $3A
	NOISE $3F
	NOISE $4A
	NOISE $4F
	NOISE $5A
	NOISE $5F
	NVOICE $02, $B0
	NOISE $16
	NOISE $26
	NOISE $36
	NOISE $46
	NOISE $45
	NOISE $44
	NOISE_VOL 6
	NOISE $46
	NOISE $45
	NOISE $44
	SND_END

Snd39_SfxN:
	NVOICE $02, $D0
	NOISE $2A
	NOISE $3F
	NOISE $4A
	NOISE $4F
	NOISE $4C
	NOISE $4E
	NOISE $3C
	NOISE $3E
	NOISE $4C
	NOISE $4D
	NOISE $5C
	NOISE $5D
	NOISE_VOL 7
	NOISE $4B
	NOISE $4E
	NOISE $4C
	NOISE $4D
	NOISE $5C
	NOISE $5D
	SND_END

Snd3A_SfxN:
	NVOICE $02, $C0
	NOISE $40
	NOISE $44
	NOISE $00
	NOISE $24
	NOISE $00
	NOISE $44
	NOISE $43
	NOISE $23
	NOISE $2B
	NOISE $2C
	NOISE $3D
	NOISE $3E
	NOISE $4E
	NOISE $4F
	NOISE $4C
	NOISE $4C
	NOISE $5C
	NOISE $5D
	NOISE $6D
	NOISE $6E
	NOISE $6F
	SND_END

Snd3B_SfxN:
	NVOICE $02, $E0
	NOISE $3B
	NOISE $00
	NOISE $4B
	NOISE $4C
	NOISE $3C
	NOISE $3D
	NOISE $4E
	NOISE $4F
	NOISE_VOL 8
	NOISE $13
	NOISE $1B
	NOISE $1C
	NOISE $2D
	NOISE $2E
	NOISE $3F
	NOISE $3E
	NOISE $23
	NOISE $2B
	NOISE $2C
	NOISE $3D
	NOISE $3E
	NOISE $4F
	NOISE $4E
	NOISE $4D
	SND_END

Snd3C_Sfx1:
	VVOICE $01, $00, $27
	OCTAVE 4
	VNOTE F_, 15
	VVOICE $03, $00, $2F
	OCTAVE 5
	VNOTE F_, 15
	VNOTE F_, 8
	SND_END

Snd3D_Sfx1:
	VVOICE $01, $00, $08
	OCTAVE 4
	VNOTE A#, 11
	OCTAVE 5
	VNOTE A#, 11
	OCTAVE 6
	VNOTE A#, 11
	VREST 0
	VNOTE A#, 11
	OCTAVE 5
	VNOTE A#, 11
	OCTAVE 4
	VNOTE A#, 11
	OCTAVE 3
	VNOTE A#, 12
	OCTAVE 4
	VNOTE A#, 12
	OCTAVE 3
	VNOTE A#, 12
	VNOTE A#, 7
	OCTAVE 4
	VNOTE A#, 7
	OCTAVE 3
	VNOTE A#, 7
	SND_END

Snd3E_Sfx1:
	VVOICE $02, $00, $34
	OCTAVE 4
	VNOTE C_, 15
	VNOTE E_, 15
	VVOICE $01, $00, $00
	VNOTE G_, 15
	VNOTE A_, 15
	VNOTE G_, 15
	VNOTE A_, 15
	VNOTE G_, 15
	VVOICE $02, $00, $34
	VNOTE C_, 8
	VNOTE E_, 8
	VVOICE $01, $00, $00
	VNOTE G_, 7
	VNOTE A_, 7
	VNOTE G_, 7
	VNOTE F#, 7
	VNOTE F_, 7
	SND_END

Snd3F_Sfx1:
	VVOICE $02, $80, $08
	OCTAVE 4
	VNOTE D_, 13
	VREST 0
	VVOICE $02, $40, $3E
	VNOTE D_, 13
	VVOICE $02, $40, $36
	OCTAVE 5
	VNOTE D_, 13
	VVOICE $02, $40, $3E
	OCTAVE 4
	VNOTE D_, 7
	VVOICE $02, $40, $36
	OCTAVE 5
	VNOTE D_, 7
	SND_END

Snd40_Sfx1:
	VVOICE $03, $00, $2E
	OCTAVE 3
	VNOTE B_, 10
	VVOICE $02, $00, $08
	OCTAVE 2
	VNOTE B_, 9
	OCTAVE 3
	VNOTE C_, 10
	OCTAVE 2
	VNOTE B_, 11
	OCTAVE 3
	VNOTE C_, 12
	OCTAVE 2
	VNOTE B_, 11
	OCTAVE 3
	VNOTE C_, 12
	VNOTE C#, 13
	VNOTE C_, 14
	VNOTE C#, 15
	VNOTE D_, 15
	VNOTE D#, 15
	VNOTE D_, 15
	VNOTE D#, 15
	VNOTE E_, 15
	VNOTE F_, 15
	VNOTE F#, 15
	VNOTE G_, 15
	VNOTE G#, 15
	VNOTE A_, 15
	VNOTE F#, 7
	VNOTE G_, 7
	VNOTE G#, 7
	VNOTE A_, 7
	VNOTE G_, 3
	VNOTE G#, 3
	VNOTE A_, 3
	SND_END

Snd41_Sfx1:
	VVOICE $01, $80, $00
	OCTAVE 5
	VNOTE A_, 10
	OCTAVE 6
	VNOTE C#, 10
	VREST 0
	VREST 0
	VREST 0
	OCTAVE 4
	VNOTE A_, 10
	OCTAVE 5
	VNOTE C#, 10
	OCTAVE 5
	VNOTE A_, 6
	OCTAVE 6
	VNOTE C#, 6
	VREST 0
	VREST 0
	OCTAVE 4
	VNOTE A_, 6
	OCTAVE 5
	VNOTE C#, 6
	SND_END

Snd42_Sfx1:
	VVOICE $01, $80, $08
	OCTAVE 6
	VNOTE F#, 11
	OCTAVE 4
	VNOTE D_, 11
	OCTAVE 5
	VNOTE A_, 11
	OCTAVE 6
	VNOTE F#, 11
	VNOTE D_, 11
	VNOTE D_, 11
	VVOICE $01, $80, $08
	OCTAVE 5
	VNOTE E_, 12
	VVOICE $06, $80, $08
	VNOTE A_, 12
	VVOICE $01, $80, $08
	VNOTE E_, 6
	VVOICE $06, $80, $08
	VNOTE A_, 6
	VVOICE $01, $80, $08
	VNOTE E_, 3
	VVOICE $06, $80, $08
	VNOTE A_, 3
	SND_END

Snd43_Sfx1:
	VVOICE $01, $80, $00
	OCTAVE 5
	VNOTE A_, 10
	OCTAVE 6
	VNOTE E_, 10
	VREST 0
	VREST 0
	VREST 0
	OCTAVE 4
	VNOTE A_, 10
	OCTAVE 5
	VNOTE E_, 10
	OCTAVE 5
	VNOTE A_, 6
	OCTAVE 6
	VNOTE E_, 6
	VREST 0
	VREST 0
	OCTAVE 4
	VNOTE A_, 6
	OCTAVE 5
	VNOTE E_, 6
	SND_END

Snd44_Sfx1:
	VVOICE $01, $80, $08
	OCTAVE 6
	VNOTE F#, 11
	OCTAVE 4
	VNOTE D_, 11
	OCTAVE 5
	VNOTE A_, 11
	OCTAVE 6
	VNOTE F#, 11
	VNOTE D_, 11
	VNOTE D_, 11
	VVOICE $01, $80, $08
	OCTAVE 5
	VNOTE E_, 12
	VVOICE $04, $80, $08
	VNOTE A_, 12
	VVOICE $01, $80, $08
	VNOTE B_, 12
	VVOICE $06, $80, $08
	OCTAVE 6
	VNOTE E_, 12
	VVOICE $01, $80, $08
	OCTAVE 5
	VNOTE B_, 6
	VVOICE $06, $80, $08
	OCTAVE 6
	VNOTE E_, 6
	VVOICE $01, $80, $08
	OCTAVE 5
	VNOTE B_, 3
	VVOICE $06, $80, $08
	OCTAVE 6
	VNOTE E_, 3
	VVOICE $01, $80, $08
	OCTAVE 5
	VNOTE B_, 2
	VVOICE $06, $80, $08
	OCTAVE 6
	VNOTE E_, 2
	SND_END

Snd45_Sfx1:
	VVOICE $01, $80, $00
	OCTAVE 6
	VNOTE E_, 10
	OCTAVE 5
	VNOTE A_, 10
	OCTAVE 4
	VNOTE E_, 10
	VREST 0
	VREST 0
	VREST 0
	OCTAVE 6
	VNOTE A_, 10
	OCTAVE 5
	VNOTE E_, 10
	OCTAVE 6
	VNOTE E_, 6
	OCTAVE 5
	VNOTE A_, 6
	OCTAVE 4
	VNOTE E_, 6
	VREST 0
	VREST 0
	OCTAVE 6
	VNOTE A_, 6
	OCTAVE 5
	VNOTE E_, 6
	SND_END

Snd46_Sfx1:
	VVOICE $01, $80, $08
	OCTAVE 6
	VNOTE F#, 11
	OCTAVE 4
	VNOTE D_, 11
	OCTAVE 5
	VNOTE A_, 11
	OCTAVE 6
	VNOTE F#, 11
	VNOTE D_, 11
	VNOTE D_, 11
	VVOICE $01, $80, $08
	OCTAVE 5
	VNOTE E_, 12
	VVOICE $03, $80, $08
	VNOTE A_, 12
	VVOICE $01, $80, $08
	VNOTE B_, 12
	VVOICE $05, $80, $08
	OCTAVE 6
	VNOTE E_, 12
	VVOICE $01, $80, $08
	VNOTE C#, 12
	VVOICE $03, $80, $08
	VNOTE A_, 12
	VVOICE $01, $80, $08
	OCTAVE 5
	VNOTE B_, 12
	VVOICE $05, $80, $08
	OCTAVE 6
	VNOTE E_, 12
	VVOICE $01, $80, $08
	VNOTE C#, 6
	VVOICE $03, $80, $08
	VNOTE A_, 6
	VVOICE $01, $80, $08
	OCTAVE 5
	VNOTE B_, 6
	VVOICE $05, $80, $08
	OCTAVE 6
	VNOTE E_, 6
	VVOICE $01, $80, $08
	VNOTE C#, 3
	VVOICE $03, $80, $08
	VNOTE A_, 3
	VVOICE $01, $80, $08
	OCTAVE 5
	VNOTE B_, 3
	VVOICE $05, $80, $08
	OCTAVE 6
	VNOTE E_, 3
	VVOICE $01, $80, $08
	VNOTE C#, 2
	VVOICE $03, $80, $08
	VNOTE A_, 2
	VVOICE $01, $80, $08
	OCTAVE 5
	VNOTE B_, 2
	VVOICE $05, $80, $08
	OCTAVE 6
	VNOTE E_, 2
	SND_END

Snd47_Sfx1:
	VVOICE $05, $80, $08
	OCTAVE 5
	VNOTE F_, 9
	VNOTE A#, 9
	VVOICE $02, $80, $08
	VREST 0
	VVOICE $05, $80, $08
	OCTAVE 5
	VNOTE A#, 9
	VNOTE F_, 9
	SND_END

Snd48_SfxN:
	NVOICE $82, $F0
	NOISE $12
	NOISE $37
	NOISE $00
	NOISE $46
	NOISE $47
	NOISE_VOL $0A
	NOISE $46
	NOISE $45
	NOISE_VOL 6
	NOISE $46
	NOISE $46
	SND_END

Snd49_Sfx1:
	VVOICE $01, $80, $00
	OCTAVE 5
	VNOTE A_, 10
	OCTAVE 6
	VNOTE A#, 10
	VREST 0
	VREST 0
	VREST 0
	OCTAVE 4
	VNOTE A_, 10
	OCTAVE 5
	VNOTE A#, 10
	OCTAVE 5
	VNOTE A_, 6
	OCTAVE 6
	VNOTE A#, 6
	VREST 0
	VREST 0
	OCTAVE 4
	VNOTE A_, 6
	OCTAVE 5
	VNOTE A#, 6
	SND_END

Snd4A_Sfx1:
	VVOICE $01, $00, $00
	OCTAVE 5
	VNOTE G#, 12
	VVOICE $02, $80, $00
	VNOTE G_, 12
	VNOTE G_, 7
	VVOICE $01, $00, $00
	OCTAVE 6
	VNOTE C_, 12
	VVOICE $02, $80, $00
	OCTAVE 5
	VNOTE B_, 12
	VNOTE B_, 7
	VVOICE $01, $00, $00
	OCTAVE 5
	VNOTE G#, 12
	VVOICE $02, $80, $00
	VNOTE G_, 12
	VNOTE G_, 7
	VVOICE $01, $00, $00
	OCTAVE 6
	VNOTE D#, 12
	VVOICE $02, $80, $00
	VNOTE D_, 12
	VNOTE D_, 7
	VNOTE D_, 4
	VVOICE $01, $00, $00
	OCTAVE 6
	VNOTE D#, 7
	VVOICE $03, $80, $00
	VNOTE D_, 7
	VNOTE D_, 4
	VNOTE D_, 2
	SND_END

Snd4B_Sfx1:
	VVOICE $03, $40, $08
	OCTAVE 4
	VNOTE C_, 12
	OCTAVE 5
	VNOTE C_, 12
	OCTAVE 6
	VNOTE C_, 12
	OCTAVE 4
	VNOTE C_, 6
	OCTAVE 5
	VNOTE C_, 6
	OCTAVE 4
	VNOTE G_, 12
	VNOTE G_, 6
	VNOTE G_, 12
	SND_END

Snd4C_Sfx1:
	VVOICE $01, $40, $08
	OCTAVE 6
	VNOTE A#, 12
	VNOTE A#, 7
	VNOTE A#, 4
	VVOICE $01, $40, $08
	OCTAVE 5
	VNOTE A_, 11
	VNOTE A#, 7
	VNOTE B_, 4
	VVOICE $02, $40, $08
	OCTAVE 6
	VNOTE C_, 13
	VNOTE C_, 7
	VVOICE $01, $40, $08
	VREST 0
	VVOICE $03, $40, $08
	OCTAVE 6
	VNOTE C_, 13
	VNOTE C_, 8
	VNOTE C_, 5
	VNOTE C_, 3
	SND_END

Snd4D_SfxN:
	NVOICE $82, $B0
	NOISE $49
	NOISE $52
	NOISE $3C
	NOISE $3F
	NOISE $4C
	NOISE $4F
	NVOICE $8A, $92
	NOISE $27
	NOISE $45
	SND_END

Snd4E_Sfx1:
	VVOICE $01, $40, $27
	OCTAVE 5
	VNOTE E_, 8
	VREST 0
	OCTAVE 6
	VNOTE E_, 8
	OCTAVE 5
	VNOTE E_, 8
	OCTAVE 4
	VNOTE F_, 8
	VNOTE F_, 8
	VNOTE E_, 8
	VNOTE D#, 8
	VNOTE D_, 8
	VNOTE C#, 8
	VNOTE F_, 4
	VNOTE F_, 4
	VNOTE E_, 4
	VNOTE D#, 4
	VNOTE D_, 4
	VNOTE C#, 4
	VNOTE F_, 2
	VNOTE F_, 2
	VNOTE E_, 2
	VNOTE D#, 2
	VNOTE D_, 2
	VNOTE C#, 2
	SND_END

Snd4E_SfxN:
	NVOICE $01, $90
	NOISE $37
	NOISE $00
	NOISE $04
	NOISE $37
	NVOICE $02, $90
	NOISE $26
	NOISE $25
	NOISE $24
	NOISE $23
	NOISE $22
	NOISE $21
	NOISE $20
	SND_END

Snd4F_SfxN:
	NVOICE $82, $90
	NOISE $5A
	NOISE $4B
	NOISE $3C
	NOISE $00
	NOISE $2C
	NOISE $00
	NOISE $2D
	NOISE $2E
	NOISE $17
	NOISE $26
	NOISE $35
	NOISE $44
	NOISE $53
	NOISE $62
	NOISE_VOL 5
	NOISE $27
	NOISE $36
	NOISE $45
	NOISE $54
	NOISE $63
	NOISE $72
	SND_END

Snd50_SfxN:
	NVOICE $01, $A0
	NOISE $45
	LOOP_START
	NOISE $07
	NOISE $15
	NOISE $33
	NOISE $51
	NOISE $70
	LOOP_END $03
	NOISE_VOL 6
	NOISE $26
	NOISE $25
	NOISE $24
	NOISE $23
	NOISE $22
	NOISE $21
	NOISE $20
	NOISE_VOL 4
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $33
	NOISE $32
	NOISE $31
	NOISE $30
	SND_END

Snd51_Sfx1:
	VVOICE $01, $00, $08
	OCTAVE 6
	VNOTE A_, 4
	VNOTE G#, 5
	VNOTE G_, 6
	VNOTE F#, 7
	VNOTE F_, 8
	VNOTE E_, 9
	VNOTE F_, 10
	VNOTE E_, 11
	VNOTE D#, 12
	VNOTE E_, 13
	VNOTE D#, 13
	VNOTE D_, 12
	VNOTE D#, 11
	VNOTE D_, 10
	VNOTE C#, 9
	VNOTE D_, 8
	VNOTE C#, 7
	VNOTE C_, 6
	VNOTE D_, 7
	VNOTE D#, 6
	VNOTE D_, 5
	VNOTE C#, 4
	VNOTE D_, 3
	VNOTE C#, 2
	VNOTE C_, 1
	SND_END

Snd52_Sfx1:
	VVOICE $01, $80, $17
	OCTAVE 4
	VNOTE B_, 8
	OCTAVE 5
	VNOTE C_, 9
	DUTY 4
	VNOTE D_, 10
	DUTY 0
	VNOTE D#, 10
	VVOICE $01, $80, $27
	VNOTE E_, 10
	VNOTE F_, 10
	VNOTE F#, 10
	VNOTE G_, 10
	VNOTE G#, 10
	VNOTE G_, 10
	VNOTE G#, 10
	VNOTE G_, 10
	VNOTE G#, 10
	VNOTE G_, 10
	VNOTE G#, 10
	VNOTE G_, 10
	VNOTE F#, 10
	VNOTE F_, 10
	VNOTE F#, 7
	VNOTE G_, 8
	VNOTE G#, 9
	VNOTE A_, 10
	VNOTE G#, 10
	VNOTE A_, 10
	VNOTE G#, 10
	VNOTE G_, 10
	VNOTE F#, 9
	VNOTE F_, 7
	VNOTE E_, 5
	VNOTE D#, 3
	VVOICE $0E, $00, $5C
	OCTAVE 5
	VNOTE E_, 10
	SND_END

Snd52_SfxN:
	NVOICE $82, $43
	NOISE $3E
	NOISE_VOL 5
	NOISE $3D
	NOISE_VOL 6
	NOISE $2E
	NOISE_VOL 7
	NOISE $2D
	NOISE_VOL 8
	NOISE $1E
	NOISE_VOL 9
	NOISE $1D
	NOISE $0E
	NOISE $0D
	NOISE $1C
	NOISE $1D
	NOISE $2C
	NOISE $2B
	NOISE $3C
	NOISE $3B
	NOISE $4A
	NOISE $49
	NOISE $5A
	NVOICE $82, $A0
	LOOP_START
	NOISE $2A
	NOISE $3F
	NOISE $4A
	NOISE $4F
	NOISE $00
	LOOP_END $03
	NOISE $4C
	NOISE $4E
	NOISE $3C
	NOISE $3E
	NOISE $4C
	NOISE $4D
	NOISE $5C
	NOISE $5D
	NOISE_VOL 6
	NOISE $4B
	NOISE $4E
	NOISE $4C
	NOISE $4D
	NOISE $5C
	NOISE $5D
	SND_END

Snd53_SfxN:
	NVOICE $02, $D0
	NOISE $22
	NOISE $26
	NOISE $00
	NOISE $47
	NOISE $46
	NOISE $45
	NOISE $44
	NOISE $43
	NOISE_VOL 7
	NOISE $57
	NOISE $56
	NOISE $55
	NOISE $54
	NOISE $53
	SND_END

Snd54_SfxN:
	NVOICE $81, $80
	NOISE $11
	NOISE_VOL $0A
	NOISE $22
	NOISE_VOL $0C
	NOISE $46
	NOISE $00
	NVOICE $82, $F0
	NOISE $47
	NOISE $36
	NOISE $25
	NOISE $14
	NOISE $03
	NOISE $02
	NOISE $01
	NOISE_VOL 7
	NOISE $57
	NOISE $46
	NOISE $35
	NOISE $24
	NOISE $13
	NOISE $02
	NOISE $01
	SND_END

Snd55_SfxN:
	NVOICE $02, $E0
	NOISE $66
	NOISE $67
	NOISE $56
	NOISE $46
	NOISE $36
	NOISE $26
	NOISE $36
	NOISE $46
	NOISE $56
	NOISE $66
	NOISE $76
	NVOICE $01, $80
	NOISE $66
	NOISE $67
	NOISE $56
	NOISE $46
	NOISE $36
	NOISE $26
	NOISE $36
	NOISE $46
	NOISE $56
	NOISE $66
	SND_END

Snd56_Sfx1:
	VVOICE $01, $40, $17
	OCTAVE 2
	VNOTE B_, 12
	OCTAVE 3
	VNOTE B_, 12
	OCTAVE 4
	VNOTE B_, 12
	OCTAVE 5
	VNOTE B_, 12
	OCTAVE 6
	VNOTE B_, 12
	VREST 0
	OCTAVE 4
	VNOTE B_, 12
	VREST 0
	OCTAVE 5
	VNOTE D_, 12
	VNOTE D#, 12
	VNOTE E_, 12
	VNOTE D_, 12
	VNOTE D#, 12
	VNOTE E_, 12
	VNOTE D_, 12
	VNOTE D#, 12
	VNOTE E_, 12
	VNOTE D_, 12
	VNOTE D#, 12
	VNOTE E_, 12
	VNOTE D_, 6
	VNOTE D#, 6
	VNOTE E_, 6
	VNOTE D_, 6
	VNOTE D#, 6
	VNOTE E_, 6
	VNOTE D_, 6
	VNOTE D#, 6
	VNOTE E_, 6
	VNOTE D_, 6
	VNOTE D#, 6
	VNOTE E_, 6
	OCTAVE 4
	VNOTE A_, 7
	VNOTE A#, 8
	VNOTE B_, 9
	VNOTE A_, 10
	VNOTE A#, 11
	VNOTE B_, 12
	VNOTE A_, 12
	VNOTE A#, 12
	VNOTE B_, 12
	VNOTE A_, 12
	VNOTE A#, 12
	VNOTE B_, 12
	VNOTE A_, 6
	VNOTE A#, 6
	VNOTE B_, 6
	VNOTE A_, 6
	VNOTE A#, 6
	VNOTE B_, 6
	VNOTE G#, 6
	VNOTE A_, 6
	VNOTE A#, 6
	VNOTE G#, 4
	VNOTE A_, 4
	VNOTE A#, 4
	VNOTE G_, 2
	VNOTE G#, 2
	VNOTE A_, 2
	SND_END

Snd56_SfxN:
	NVOICE $82, $C0
	NOISE $57
	NOISE $53
	NOISE $5F
	NOISE $4F
	NOISE $3F
	NOISE $2F
	NOISE $2E
	NOISE_VOL 9
	NOISE $1F
	NOISE $1E
	NOISE $0D
	NOISE_VOL 6
	NOISE $0C
	NOISE $0B
	NOISE_VOL 3
	NOISE $1C
	NOISE $1B
	NOISE $2C
	NOISE $2B
	NOISE $3F
	NOISE $2F
	NOISE $2E
	NOISE_VOL 9
	NOISE $1F
	NOISE $1E
	NOISE $0D
	NOISE_VOL 6
	NOISE $0C
	NOISE $0B
	NOISE_VOL 3
	NOISE $1C
	NOISE $1B
	NOISE $2C
	NOISE $2B
	SND_END

Snd57_Sfx1:
	VVOICE $03, $00, $4D
	OCTAVE 6
	VNOTE C_, 10
	VVOICE $01, $80, $08
	OCTAVE 5
	VNOTE E_, 10
	VNOTE F#, 10
	VNOTE G#, 10
	VVOICE $03, $80, $08
	VNOTE A#, 10
	VVOICE $01, $80, $08
	VNOTE E_, 5
	VNOTE F#, 5
	VNOTE G#, 5
	VVOICE $03, $80, $08
	VNOTE A#, 5
	SND_END

Snd58_SfxN:
	NVOICE $02, $B0
	NOISE $59
	NVOICE $04, $90
	NOISE $6A
	NOISE $79
	NOISE $6F
	SND_END

Snd59_Sfx1:
	VVOICE $01, $00, $08
	OCTAVE 3
	VNOTE D_, 15
	OCTAVE 4
	VNOTE C#, 15
	OCTAVE 3
	VNOTE G_, 15
	OCTAVE 4
	VNOTE F#, 15
	VNOTE C_, 15
	VNOTE B_, 15
	VNOTE F_, 15
	OCTAVE 5
	VNOTE E_, 15
	VNOTE C#, 15
	VNOTE C_, 15
	VNOTE D#, 15
	VNOTE C_, 15
	OCTAVE 4
	VNOTE B_, 15
	OCTAVE 5
	VNOTE D_, 14
	OCTAVE 4
	VNOTE B_, 12
	VNOTE A#, 10
	VVOICE $01, $40, $2F
	OCTAVE 5
	VNOTE C#, 4
	OCTAVE 4
	VNOTE C#, 4
	OCTAVE 3
	VNOTE C#, 4
	OCTAVE 4
	VNOTE C#, 4
	OCTAVE 5
	VNOTE C#, 4
	OCTAVE 5
	VNOTE C_, 10
	VNOTE C#, 11
	VNOTE D_, 12
	VNOTE D#, 12
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE F_, 13
	VNOTE E_, 12
	VNOTE D#, 10
	VNOTE D_, 7
	VNOTE C#, 4
	VNOTE E_, 7
	VNOTE F_, 7
	VNOTE E_, 7
	VNOTE F_, 7
	VNOTE E_, 7
	VNOTE F_, 7
	VNOTE E_, 7
	VNOTE D#, 6
	VNOTE D_, 5
	VNOTE C#, 4
	SND_END

Snd59_SfxN:
	NVOICE $90, $B0
	NOISE $2F
	NVOICE $83, $B0
	NOISE $3E
	NOISE $4D
	NOISE $5C
	NOISE $4D
	NOISE $3E
	NOISE $2F
	NVOICE $82, $C0
	LOOP_START
	NOISE $2A
	NOISE $3F
	NOISE $4A
	NOISE $4F
	NOISE $00
	LOOP_END $02
	NOISE $2A
	NOISE $3F
	NOISE $4A
	NOISE $4F
	NOISE $4E
	NOISE $4D
	NVOICE $83, $C0
	NOISE $4C
	NOISE $4E
	NOISE $3C
	NOISE $3E
	NOISE $4C
	NOISE $4D
	NOISE $5C
	NOISE $5D
	NOISE_VOL 6
	NOISE $4B
	NOISE $4E
	NOISE $4C
	NOISE $4D
	NOISE $5C
	NOISE $5D
	SND_END

Snd5A_Sfx1:
	VVOICE $01, $00, $08
	OCTAVE 6
	VNOTE D_, 11
	VNOTE G#, 11
	VNOTE D#, 11
	VNOTE G_, 11
	VNOTE E_, 11
	VNOTE F#, 11
	VNOTE C_, 7
	VNOTE F#, 7
	VNOTE C#, 7
	VNOTE F_, 7
	VNOTE D_, 7
	VNOTE E_, 7
	VNOTE C_, 4
	VNOTE F#, 4
	VNOTE C#, 4
	VNOTE F_, 4
	VNOTE D_, 4
	VNOTE E_, 4
	SND_END

Snd5B_SfxN:
	NVOICE $01, $B0
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $25
	NOISE $26
	NOISE $27
	NOISE $26
	NOISE $25
	NOISE_VOL 9
	NOISE $15
	NOISE_VOL 7
	NOISE $16
	NOISE_VOL 6
	NOISE $17
	NOISE_VOL 5
	NOISE $16
	NOISE_VOL 5
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $25
	NOISE $26
	NOISE $27
	NOISE $26
	NOISE $25
	NOISE_VOL 4
	NOISE $15
	NOISE_VOL 3
	NOISE $16
	NOISE_VOL 2
	NOISE $17
	NOISE_VOL 1
	NOISE $16
	SND_END

Snd5C_Sfx1:
	VVOICE $01, $00, $08
	VREST 0
	OCTAVE 3
	VNOTE D_, 7
	OCTAVE 6
	VNOTE D_, 7
	VVOICE $05, $80, $36
	OCTAVE 4
	VNOTE D_, 6
	VNOTE D_, 3
	SND_END

Snd5C_SfxN:
	NVOICE $81, $A0
	NOISE $7F
	NOISE $00
	NOISE $59
	NOISE $69
	NOISE $5A
	NOISE $00
	NOISE $00
	NOISE $7F
	NOISE $00
	NVOICE $82, $A0
	NOISE $59
	NOISE $69
	NOISE $5A
	NOISE $47
	SND_END

Snd5D_Sfx1:
	VVOICE $01, $00, $08
	OCTAVE 3
	VNOTE A#, 12
	OCTAVE 6
	VNOTE D#, 12
	VVOICE $09, $00, $4F
	VNOTE F_, 11
	VNOTE D#, 6
	SND_END

Snd5D_SfxN:
	NVOICE $02, $C0
	NOISE $69
	NOISE $00
	NVOICE $03, $C0
	NOISE $79
	NOISE $7A
	NOISE $69
	NOISE $6A
	NOISE $59
	NOISE $5A
	NVOICE $02, $B0
	NOISE $7D
	NOISE $00
	NVOICE $03, $B0
	NOISE $7A
	NOISE $7B
	NOISE $6C
	NOISE $6D
	SND_END

Snd5E_Sfx1:
	VVOICE $02, $00, $08
	OCTAVE 6
	VNOTE C_, 10
	OCTAVE 5
	VNOTE C#, 10
	OCTAVE 4
	VNOTE D_, 10
	VNOTE E_, 10
	VNOTE D_, 10
	VNOTE E_, 10
	VNOTE D_, 10
	VNOTE E_, 5
	VNOTE D_, 5
	VNOTE E_, 4
	VNOTE D_, 4
	VNOTE E_, 3
	VNOTE D_, 3
	VNOTE E_, 2
	VNOTE D_, 2
	SND_END

Snd5E_SfxN:
	NVOICE $81, $A0
	NOISE $44
	NOISE $34
	NOISE $33
	NOISE $3C
	NOISE $4C
	NOISE $4D
	NVOICE $83, $60
	NOISE $2C
	NOISE $2C
	NOISE $3C
	NOISE $3D
	NOISE $4D
	NOISE $4D
	NOISE $4E
	NOISE $5F
	SND_END

Snd5F_Sfx1:
	VVOICE $02, $80, $00
	OCTAVE 4
	VNOTE D#, 8
	VNOTE E_, 8
	VNOTE F_, 8
	VNOTE F#, 8
	VNOTE E_, 4
	VNOTE F_, 4
	VNOTE F#, 4
	SND_END

Snd60_Sfx1:
	VVOICE $01, $80, $08
	OCTAVE 4
	VNOTE D_, 7
	OCTAVE 5
	VNOTE D_, 7
	VNOTE D#, 7
	VNOTE E_, 6
	VNOTE F_, 6
	VNOTE D_, 3
	VNOTE D#, 3
	VNOTE E_, 3
	VNOTE F_, 3
	SND_END

Snd61_Sfx1:
	VVOICE $06, $00, $2F
	OCTAVE 5
	VNOTE D_, 6
	VVOICE $04, $40, $00
	VNOTE A_, 10
	OCTAVE 3
	VNOTE A_, 5
	OCTAVE 4
	VNOTE A_, 4
	OCTAVE 3
	VNOTE A_, 3
	OCTAVE 4
	VNOTE A_, 2
	OCTAVE 3
	VNOTE A_, 1
	DUTY 0
	VNOTE A_, 6
	OCTAVE 3
	VNOTE A_, 5
	OCTAVE 4
	VNOTE A_, 4
	OCTAVE 3
	VNOTE A_, 3
	OCTAVE 4
	VNOTE A_, 2
	OCTAVE 3
	VNOTE A_, 1
	SND_END

Snd61_SfxN:
	NVOICE $01, $C0
	NOISE $3A
	NOISE $3C
	NOISE $00
	NOISE $44
	NOISE $34
	NOISE $24
	NOISE $00
	NOISE $44
	NOISE $34
	NOISE $33
	NOISE $3B
	NOISE $4B
	NOISE $4C
	NVOICE $03, $80
	NOISE $3B
	NOISE $3B
	NOISE $4B
	NOISE $4C
	NOISE $5C
	NOISE $5C
	NOISE $5D
	NOISE $6E
	SND_END

Snd62_Sfx1:
	VVOICE $02, $00, $08
	OCTAVE 2
	VNOTE C_, 12
	OCTAVE 3
	VNOTE C_, 12
	OCTAVE 4
	VNOTE C_, 12
	VVOICE $04, $40, $36
	OCTAVE 5
	VNOTE C_, 13
	OCTAVE 3
	VNOTE C_, 10
	OCTAVE 4
	VNOTE C_, 9
	OCTAVE 3
	VNOTE C_, 8
	OCTAVE 4
	VNOTE C_, 6
	OCTAVE 3
	VNOTE C_, 5
	VVOICE $04, $00, $36
	VNOTE C_, 7
	OCTAVE 3
	VNOTE C_, 6
	OCTAVE 4
	VNOTE C_, 5
	OCTAVE 3
	VNOTE C_, 4
	OCTAVE 4
	VNOTE C_, 3
	OCTAVE 3
	VNOTE C_, 2
	SND_END

Snd62_SfxN:
	NVOICE $81, $C0
	NOISE $34
	NOISE $24
	NOISE $14
	NOISE $00
	NOISE $3A
	NOISE $3C
	NOISE $00
	NOISE $24
	NOISE $34
	NOISE $44
	NOISE $00
	NOISE $44
	NOISE $34
	NOISE $33
	NOISE $3C
	NOISE $4C
	NOISE $4D
	NVOICE $83, $80
	NOISE $2C
	NOISE $2D
	NOISE $3D
	NOISE $3E
	NOISE $4E
	NOISE $4F
	NOISE $5F
	NVOICE $82, $C0
	LOOP_START
	NOISE $3F
	NOISE $4A
	NOISE $4F
	NOISE $00
	LOOP_END $02
	NOISE $2A
	NOISE $3F
	NOISE $4A
	NOISE $4F
	NOISE $4E
	NOISE $4D
	NVOICE $83, $C0
	NOISE $4C
	NOISE $4E
	NOISE $3C
	NOISE $3E
	NOISE $4C
	NOISE $4D
	NOISE $5C
	NOISE $5D
	NOISE_VOL 6
	NOISE $4B
	NOISE $4E
	NOISE $4C
	NOISE $4D
	NOISE $5C
	NOISE $5D
	SND_END

Snd63_Sfx1:
	VVOICE $02, $00, $27
	OCTAVE 3
	VNOTE C_, 11
	VVOICE $03, $00, $47
	OCTAVE 5
	VNOTE C_, 11
	VVOICE $01, $00, $27
	VREST 0
	VVOICE $0C, $00, $37
	OCTAVE 5
	VNOTE A_, 13
	VVOICE $04, $00, $36
	OCTAVE 5
	VNOTE A_, 7
	VVOICE $02, $00, $3E
	OCTAVE 5
	VNOTE A_, 7
	VNOTE A#, 8
	VNOTE B_, 9
	OCTAVE 6
	VNOTE C_, 10
	VNOTE C#, 10
	VNOTE C_, 10
	VNOTE C#, 9
	VNOTE C_, 8
	OCTAVE 5
	VNOTE B_, 7
	VNOTE A#, 7
	VNOTE A_, 6
	VNOTE G#, 5
	OCTAVE 6
	VNOTE C_, 5
	VNOTE C#, 5
	VNOTE C_, 5
	VNOTE C#, 5
	VNOTE C_, 4
	OCTAVE 5
	VNOTE B_, 4
	VNOTE A#, 3
	VNOTE A_, 2
	VNOTE G#, 1
	SND_END

Snd63_SfxN:
	NVOICE $01, $C0
	NOISE $57
	NOISE $47
	NOISE $58
	NOISE $47
	NOISE $57
	NOISE $47
	NOISE_VOL $0B
	NOISE $48
	NOISE $58
	NOISE $49
	NOISE $59
	NOISE $00
	NOISE $38
	NOISE $48
	NOISE $39
	NOISE $49
	NOISE $3A
	NOISE $4A
	NOISE $3B
	NOISE $4B
	NOISE $3C
	NOISE $4C
	NOISE $3D
	NVOICE $02, $B0
	NOISE $4E
	NOISE $3D
	NOISE $2C
	NOISE $1B
	NOISE $1C
	NOISE $1B
	NOISE $1C
	NOISE $1B
	NOISE $1A
	NOISE $0B
	NOISE $0A
	NOISE $09
	NOISE_VOL 6
	NOISE $2A
	NOISE $1B
	NOISE $1A
	NOISE $19
	SND_END

Snd64_Sfx1:
	VVOICE $02, $00, $16
	OCTAVE 3
	VNOTE G_, 12
	VVOICE $01, $00, $08
	OCTAVE 6
	VNOTE F_, 12
	VNOTE F#, 12
	VNOTE F_, 12
	VNOTE F#, 12
	VVOICE $02, $00, $2F
	VNOTE A_, 12
	VREST 0
	LOOP_START
	VVOICE $01, $00, $08
	OCTAVE 5
	VNOTE F#, 12
	VNOTE G_, 12
	VNOTE F#, 12
	VVOICE $02, $00, $2F
	VNOTE G_, 12
	VNOTE G_, 6
	VREST 0
	LOOP_END $03
	VVOICE $01, $00, $08
	OCTAVE 5
	VNOTE F#, 6
	VNOTE G_, 6
	VNOTE F#, 6
	VVOICE $02, $00, $2F
	VNOTE G_, 6
	VNOTE G_, 3
	SND_END

Snd64_SfxN:
	NVOICE $02, $C0
	NOISE $20
	NOISE $40
	NOISE $30
	NOISE $00
	NOISE $00
	LOOP2_START
	NVOICE $01, $A0
	NOISE $30
	NOISE $30
	NOISE $30
	NVOICE $02, $A0
	NOISE $20
	NOISE $20
	NOISE $00
	LOOP2_END $03
	NVOICE $01, $50
	NOISE $30
	NOISE $30
	NOISE $30
	NVOICE $02, $40
	NOISE $20
	NOISE $20
	NOISE $00
	SND_END

Snd65_Sfx1:
	VVOICE $02, $40, $2E
	OCTAVE 5
	VNOTE A_, 10
	OCTAVE 6
	VNOTE A_, 10
	OCTAVE 5
	VNOTE A_, 10
	OCTAVE 4
	VNOTE A_, 10
	OCTAVE 3
	VNOTE A_, 10
	OCTAVE 5
	VNOTE B_, 10
	VNOTE A#, 10
	VNOTE B_, 10
	VNOTE A#, 10
	VNOTE B_, 10
	VNOTE A#, 10
	VNOTE A_, 10
	OCTAVE 5
	VNOTE B_, 5
	VNOTE A#, 5
	VNOTE B_, 5
	VNOTE A#, 5
	VNOTE B_, 5
	VNOTE A#, 5
	VNOTE A_, 5
	SND_END

Snd65_SfxN:
	NVOICE $82, $A0
	NOISE $38
	NOISE $39
	NOISE $49
	NOISE $59
	NOISE $00
	NVOICE $83, $A0
	NOISE $59
	NOISE $4A
	NOISE $39
	NOISE_VOL 9
	NOISE $2A
	NOISE_VOL 8
	NOISE $19
	NOISE_VOL 7
	NOISE $0A
	SND_END

Snd66_SfxN:
	NVOICE $01, $C0
	NOISE $3A
	NOISE $3C
	NOISE $00
	NOISE $44
	NOISE $34
	NOISE $24
	NOISE $00
	NOISE $44
	NOISE $34
	NOISE $33
	NOISE $3B
	NOISE $4B
	NOISE $4C
	NVOICE $03, $80
	NOISE $3B
	NOISE $3B
	NOISE $4B
	NOISE $4C
	NOISE $5C
	NOISE $5C
	NOISE $5D
	NOISE $6E
	SND_END

Snd67_Sfx1:
	VVOICE $01, $80, $08
	OCTAVE 4
	VNOTE B_, 2
	VNOTE A#, 2
	VNOTE A_, 2
	VNOTE G#, 2
	VNOTE B_, 4
	VNOTE A#, 4
	VNOTE A_, 4
	VNOTE G#, 4
	VNOTE B_, 8
	VNOTE A#, 8
	VNOTE A_, 8
	VNOTE G#, 8
	VNOTE B_, 13
	VNOTE A#, 13
	VNOTE A_, 13
	VNOTE G#, 13
	VNOTE B_, 8
	VNOTE A#, 8
	VNOTE A_, 8
	VNOTE G#, 8
	VNOTE B_, 4
	VNOTE A#, 4
	VNOTE A_, 4
	VNOTE G#, 4
	VNOTE B_, 2
	VNOTE A#, 2
	VNOTE A_, 2
	VNOTE G#, 2
	SND_END

Snd67_SfxN:
	NVOICE $81, $C0
	NOISE $00
	NOISE $01
	NOISE $02
	NOISE $03
	NOISE $04
	NOISE $05
	NOISE $06
	NOISE $07
	NOISE $10
	NOISE $11
	NOISE $12
	NOISE $13
	NOISE $14
	NOISE $15
	NOISE $16
	NOISE $17
	NOISE $20
	NOISE $21
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	NOISE $27
	NOISE $30
	NOISE $31
	NOISE $32
	NOISE $33
	NOISE $34
	NOISE $35
	NOISE $36
	NOISE $37
	NOISE_VOL 6
	NOISE $20
	NOISE $21
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	NOISE $27
	NOISE $30
	NOISE $31
	NOISE $32
	NOISE $33
	NOISE $34
	NOISE $35
	NOISE $36
	NOISE $37
	NOISE_VOL 6
	NOISE $40
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE_VOL 3
	NOISE $50
	NOISE $51
	NOISE $52
	NOISE $53
	SND_END

Snd68_SfxN:
	NVOICE $01, $60
	NOISE $70
	NOISE $51
	NOISE $33
	NOISE $15
	NOISE $07
	NOISE_VOL 9
	NOISE $70
	NOISE $51
	NOISE $33
	NOISE $15
	NOISE $07
	NOISE_VOL $0C
	NOISE $70
	NOISE $51
	NOISE $33
	NOISE $15
	NOISE $07
	NOISE_VOL 7
	NOISE $26
	NOISE $25
	NOISE $24
	NOISE $23
	NOISE $22
	NOISE $21
	NOISE $20
	NOISE_VOL 4
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $33
	NOISE $32
	NOISE $31
	NOISE $30
	SND_END

Snd69_Sfx1:
	VVOICE $02, $40, $08
	OCTAVE 6
	VNOTE A#, 6
	VVOICE $04, $00, $08
	VNOTE A_, 7
	VVOICE $01, $40, $08
	VNOTE A#, 4
	VVOICE $04, $00, $08
	VNOTE A_, 4
	VVOICE $01, $40, $08
	VNOTE A#, 2
	VVOICE $04, $00, $08
	VNOTE A_, 2
	SND_END

Snd6A_SfxN:
	NVOICE $01, $E0
	NOISE $06
	NOISE $16
	NOISE $16
	NOISE $26
	NOISE $26
	NOISE $27
	NOISE $26
	NOISE $25
	NOISE $15
	NOISE $16
	NOISE $17
	NOISE $16
	NOISE $15
	NOISE_VOL $0B
	NOISE $05
	NOISE $06
	NOISE $07
	NOISE_VOL $0B
	NOISE $06
	NOISE_VOL $0A
	NOISE $27
	NOISE $26
	NOISE $25
	NOISE $15
	NOISE $16
	NOISE $17
	NOISE $16
	NOISE $15
	NOISE_VOL 9
	NOISE $05
	NOISE $16
	NOISE_VOL $0B
	NOISE $27
	NOISE $36
	NOISE_VOL $0D
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $25
	NOISE $26
	NOISE $27
	NOISE $26
	NOISE $25
	NOISE_VOL $0B
	NOISE $15
	NOISE $16
	NOISE $17
	NOISE_VOL $0B
	NOISE $16
	NOISE_VOL $0A
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $25
	NOISE $26
	NOISE $27
	NOISE $26
	NOISE $25
	NOISE_VOL 9
	NOISE $15
	NOISE $26
	NOISE_VOL $0B
	NOISE $37
	NOISE $46
	NOISE_VOL $0D
	NOISE $47
	NOISE $46
	NOISE $45
	NOISE $35
	NOISE $36
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE_VOL $0B
	NOISE $25
	NOISE $26
	NOISE $27
	NOISE_VOL $0B
	NOISE $26
	NOISE_VOL $0A
	NOISE $47
	NOISE $46
	NOISE $45
	NOISE $35
	NOISE $36
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE_VOL 9
	NOISE $25
	NOISE $36
	NOISE_VOL $0B
	NOISE $47
	NOISE $56
	NOISE_VOL $0D
	NOISE $57
	NOISE $56
	NOISE $55
	NOISE $45
	NOISE $46
	NOISE $47
	NOISE $46
	NOISE $45
	NOISE_VOL $0B
	NOISE $35
	NOISE $36
	NOISE $37
	NOISE_VOL $0B
	NOISE $36
	NOISE_VOL $0A
	NOISE $57
	NOISE $56
	NOISE $55
	NOISE $45
	NOISE $46
	NOISE $47
	NOISE $46
	NOISE $45
	NOISE_VOL 5
	NOISE $35
	NOISE $36
	NOISE_VOL 4
	NOISE $37
	NOISE $36
	SND_END

Snd6B_Sfx1:
	VVOICE $02, $40, $08
	OCTAVE 6
	VNOTE G#, 1
	VNOTE G#, 2
	VNOTE G#, 3
	VNOTE G#, 4
	VVOICE $02, $40, $08
	VNOTE G#, 4
	VNOTE A_, 4
	VNOTE G#, 4
	VNOTE A_, 4
	VNOTE A#, 4
	VNOTE A_, 3
	VNOTE A#, 2
	VNOTE B_, 1
	SND_END

Snd6B_SfxN:
	NVOICE $82, $A0
	NOISE $4A
	NOISE $00
	NOISE $49
	NOISE $4A
	NOISE_VOL 8
	NOISE $4B
	NOISE $3B
	NVOICE $8A, $60
	NOISE $2C
	NVOICE $84, $30
	NOISE $2C
	SND_END

Snd6C_SfxN:
	NVOICE $02, $D0
	NOISE $37
	NOISE $43
	NOISE_VOL $0A
	NOISE $43
	NOISE_VOL 9
	NOISE $43
	NOISE_VOL 7
	NOISE $43
	NOISE_VOL 5
	NOISE $43
	NOISE_VOL 4
	NOISE $43
	NOISE_VOL 3
	NOISE $43
	NOISE_VOL 2
	NOISE $43
	NOISE_VOL 1
	NOISE $43
	SND_END

Snd6D_SfxN:
	NVOICE $02, $C0
	NOISE $17
	NOISE $11
	NOISE $27
	NOISE $21
	NVOICE $0A, $A2
	NOISE $27
	NOISE $45
	SND_END

Snd6E_SfxN:
	NVOICE $02, $B0
	NOISE $4C
	NOISE $1E
	NVOICE $02, $90
	NOISE $37
	NOISE $17
	NOISE $27
	NVOICE $02, $90
	NOISE $2D
	NVOICE $09, $82
	NOISE $27
	NOISE $45
	SND_END

Snd6F_SfxN:
	NVOICE $01, $D0
	NOISE $36
	NOISE $47
	NVOICE $02, $C0
	NOISE $24
	NVOICE $02, $A0
	NOISE $44
	NOISE_VOL 9
	NOISE $44
	NOISE_VOL 8
	NOISE $44
	NOISE_VOL 4
	NOISE $44
	SND_END

Snd70_SfxN:
	NVOICE $02, $F0
	NOISE $37
	NVOICE $02, $F0
	NOISE $00
	NVOICE $02, $C0
	NOISE $3D
	NVOICE $02, $B0
	NOISE $42
	NOISE_VOL 9
	NOISE $42
	NOISE_VOL 7
	NOISE $42
	NOISE_VOL 5
	NOISE $42
	NOISE_VOL 4
	NOISE $42
	NOISE_VOL 3
	NOISE $42
	NOISE_VOL 2
	NOISE $42
	SND_END

Snd71_Sfx1:
	VVOICE $01, $80, $27
	OCTAVE 6
	VNOTE F_, 10
	DUTY 4
	OCTAVE 5
	VNOTE F_, 9
	VNOTE E_, 9
	VNOTE D#, 9
	VNOTE D_, 9
	VNOTE C#, 9
	VNOTE F_, 5
	VNOTE E_, 5
	VNOTE D#, 5
	VNOTE D_, 5
	VNOTE C#, 5
	VNOTE F_, 3
	VNOTE E_, 3
	VNOTE D#, 3
	VNOTE D_, 3
	VNOTE C#, 3
	SND_END

Snd72_SfxN:
	NVOICE $81, $D0
	NOISE $27
	NOISE $07
	NOISE $00
	NVOICE $81, $D0
	NOISE $3E
	NVOICE $8A, $B2
	NOISE $4F
	NOISE $5F
	SND_END

Snd73_SfxN:
	NVOICE $82, $C0
	NOISE $0E
	NOISE $0F
	NOISE $0D
	NOISE $0E
	NOISE $0C
	NOISE $0D
	NOISE $0B
	NOISE $0C
	SND_END

Snd74_SfxN:
	NVOICE $82, $E0
	NOISE $39
	NOISE $29
	NOISE $28
	NOISE $19
	NOISE $29
	NOISE $18
	NOISE $28
	NOISE $19
	NOISE_VOL $0A
	NOISE $29
	NOISE $28
	NOISE $19
	NOISE $29
	SND_END

Snd75_SfxN:
	NVOICE $82, $B0
	NOISE $2B
	NOISE $0F
	NOISE $2B
	NOISE $0F
	NOISE $2B
	NOISE_VOL 8
	NOISE $2B
	NOISE $0F
	NOISE $2B
	NOISE $0F
	NOISE $2B
	SND_END

Snd76_Sfx1:
	VVOICE $02, $40, $08
	OCTAVE 5
	VNOTE D#, 11
	OCTAVE 4
	VNOTE G_, 10
	VNOTE F#, 10
	VNOTE D_, 10
	VNOTE D#, 10
	VNOTE G_, 10
	VNOTE F#, 10
	VNOTE D_, 10
	VNOTE D#, 10
	SND_END

Snd77_Sfx1:
	VVOICE $01, $00, $08
	OCTAVE 6
	VNOTE A_, 12
	VNOTE C#, 11
	OCTAVE 5
	VNOTE E_, 11
	VNOTE F#, 11
	OCTAVE 6
	VNOTE G#, 11
	VNOTE A_, 11
	VNOTE A_, 12
	VNOTE C#, 11
	OCTAVE 5
	VNOTE E_, 11
	VNOTE F#, 11
	OCTAVE 6
	VNOTE G#, 11
	VNOTE A_, 11
	VNOTE A_, 12
	VNOTE C#, 11
	OCTAVE 5
	VNOTE E_, 11
	VNOTE F#, 11
	OCTAVE 6
	VNOTE G#, 11
	VNOTE A_, 11
	SND_END

Snd78_Sfx1:
	VVOICE $01, $C0, $3D
	OCTAVE 4
	VNOTE D#, 10
	VNOTE G_, 10
	VNOTE G#, 10
	OCTAVE 5
	VNOTE G_, 10
	VNOTE G#, 10
	VNOTE D_, 10
	OCTAVE 4
	VNOTE D#, 10
	VNOTE G_, 10
	VNOTE G#, 10
	OCTAVE 5
	VNOTE G_, 10
	VNOTE G#, 10
	VNOTE D_, 10
	OCTAVE 4
	VNOTE D#, 10
	VNOTE G_, 10
	VNOTE G#, 10
	OCTAVE 5
	VNOTE G_, 10
	VNOTE G#, 10
	VNOTE D_, 10
	SND_END

Snd79_SfxN:
	NVOICE $01, $80
	NOISE $3B
	NOISE $3A
	NOISE $2B
	NOISE $2C
	NOISE $2D
	NVOICE $02, $80
	NOISE $2E
	NOISE $2F
	NOISE $1F
	NOISE $1E
	NOISE $1D
	NOISE $1C
	NOISE $1B
	NOISE $1A
	NOISE $19
	SND_END

Snd7A_Sfx1:
	VVOICE $02, $00, $27
	OCTAVE 5
	VNOTE B_, 13
	VNOTE F#, 12
	VNOTE B_, 7
	VNOTE F#, 6
	VNOTE B_, 5
	VNOTE F#, 4
	SND_END

Snd7A_SfxN:
	NVOICE $81, $90
	NOISE $0E
	NOISE $1E
	NOISE $2E
	NOISE $3E
	NOISE $4E
	NOISE $5E
	NOISE $6E
	NVOICE $82, $60
	NOISE $60
	NOISE $50
	NOISE $40
	NOISE $30
	NOISE $20
	NOISE $10
	NOISE $00
	SND_END

Snd7B_SfxN:
	NVOICE $01, $D0
	NOISE $49
	NVOICE $01, $D0
	NOISE $15
	NVOICE $02, $D0
	NOISE $34
	NOISE_VOL 9
	NOISE $43
	NOISE_VOL 8
	NOISE $43
	NOISE_VOL 6
	NOISE $43
	SND_END

Snd7C_Sfx1:
	VVOICE $03, $40, $35
	VREST 0
	VVOICE $08, $40, $35
	OCTAVE 4
	VNOTE F_, 9
	VNOTE F_, 5
	VNOTE F_, 3
	SND_END

Snd7C_SfxN:
	NVOICE $02, $80
	NOISE $3C
	NOISE $3D
	NOISE_VOL 7
	NOISE $2B
	NOISE $2C
	NOISE $3B
	NOISE $3C
	NOISE $4B
	NOISE $4C
	NOISE_VOL 4
	NOISE $3B
	NOISE $3C
	NOISE $4B
	NOISE $4C
	NOISE_VOL 2
	NOISE $3C
	NOISE $4B
	NOISE $4C
	SND_END

Snd7D_SfxN:
	NVOICE $81, $C0
	NOISE $49
	NVOICE $81, $C0
	NOISE $3B
	NVOICE $81, $90
	NOISE $35
	NOISE $36
	NOISE $45
	NOISE $46
	NOISE_VOL 5
	NOISE $25
	NOISE $26
	NOISE $35
	NOISE $36
	SND_END

Snd7E_Sfx1:
	VVOICE $02, $40, $08
	OCTAVE 2
	VNOTE C_, 9
	OCTAVE 3
	VNOTE G_, 8
	VNOTE C#, 8
	OCTAVE 4
	VNOTE G_, 8
	VNOTE C#, 8
	OCTAVE 5
	VNOTE G_, 8
	VNOTE C#, 8
	VNOTE C_, 8
	OCTAVE 4
	VNOTE B_, 7
	VNOTE A#, 6
	VNOTE A_, 5
	VNOTE G#, 4
	SND_END

Snd7E_SfxN:
	NVOICE $03, $90
	NOISE $10
	NOISE $32
	NOISE $44
	SND_END

Snd7F_SfxN:
	NVOICE $01, $B0
	NOISE $47
	NOISE $37
	NOISE $27
	NOISE $17
	NOISE $07
	NVOICE $05, $B2
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $34
	SND_END

Snd80_SfxN:
	NVOICE $01, $B0
	NOISE $47
	NOISE $37
	NOISE $27
	NOISE $17
	NOISE $07
	NOISE $00
	NOISE $47
	NOISE $37
	NOISE $27
	NOISE $17
	NOISE $07
	NVOICE $05, $B2
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $34
	SND_END

Snd81_Sfx1:
	VVOICE $03, $00, $2F
	OCTAVE 5
	VNOTE F#, 11
	VVOICE $01, $00, $2F
	VREST 0
	VVOICE $05, $40, $2F
	VNOTE D_, 7
	VVOICE $04, $80, $2F
	VNOTE A_, 6
	OCTAVE 4
	VNOTE A_, 5
	OCTAVE 5
	VNOTE A_, 4
	OCTAVE 4
	VNOTE A_, 3
	OCTAVE 5
	VNOTE A_, 2
	SND_END

Snd81_SfxN:
	NVOICE $01, $A0
	NOISE $27
	NOISE $16
	NOISE $00
	NOISE $00
	NVOICE $02, $90
	NOISE $37
	NOISE $35
	NOISE $33
	NOISE $31
	SND_END

Snd82_Sfx1:
	VVOICE $01, $00, $08
	OCTAVE 5
	VNOTE F#, 11
	VVOICE $03, $00, $37
	OCTAVE 4
	VNOTE F#, 7
	VVOICE $01, $00, $08
	VREST 0
	OCTAVE 5
	VNOTE F#, 11
	VVOICE $03, $00, $2F
	VNOTE F#, 11
	VVOICE $01, $00, $08
	VREST 0
	VVOICE $05, $40, $2F
	VNOTE D_, 7
	VVOICE $04, $80, $2F
	VNOTE A_, 6
	OCTAVE 4
	VNOTE A_, 5
	OCTAVE 5
	VNOTE A_, 4
	OCTAVE 4
	VNOTE A_, 3
	OCTAVE 5
	VNOTE A_, 2
	SND_END

Snd82_SfxN:
	NVOICE $01, $A0
	NOISE $27
	NOISE $16
	NOISE $04
	NOISE $02
	NOISE $00
	NOISE $27
	NOISE $16
	NOISE $04
	NOISE $02
	NOISE $00
	NVOICE $02, $90
	NOISE $37
	NOISE $35
	NOISE $33
	NOISE $31
	SND_END

Snd83_Sfx1:
	VVOICE $01, $80, $08
	OCTAVE 3
	VNOTE A_, 8
	OCTAVE 4
	VNOTE E_, 8
	VNOTE A_, 8
	OCTAVE 5
	VNOTE A_, 8
	VVOICE $02, $80, $08
	VNOTE A#, 7
	VNOTE A_, 7
	VNOTE A#, 7
	VNOTE G_, 7
	VNOTE G#, 6
	VNOTE G_, 5
	VNOTE F#, 4
	VNOTE F_, 3
	VNOTE E_, 2
	VNOTE A#, 4
	VNOTE A_, 4
	VNOTE A#, 4
	VNOTE G_, 4
	VNOTE G#, 3
	VNOTE G_, 2
	VNOTE F#, 1
	SND_END

Snd83_SfxN:
	NVOICE $03, $90
	NOISE $02
	NOISE $13
	NOISE $24
	NOISE_VOL 5
	NOISE $02
	NOISE $13
	NOISE $24
	SND_END

Snd84_SfxN:
	NVOICE $81, $B0
	NOISE $37
	NOISE $25
	NVOICE $82, $E0
	NOISE $28
	NOISE $00
	NOISE_VOL 6
	NOISE $28
	SND_END

Snd85_SfxN:
	NVOICE $81, $D0
	NOISE $25
	NOISE $13
	NOISE $14
	NOISE $00
	NOISE $00
	NVOICE $82, $D0
	NOISE $28
	NOISE $00
	NOISE_VOL 6
	NOISE $28
	SND_END

Snd86_Sfx1:
	VVOICE $01, $80, $37
	OCTAVE 5
	VNOTE F_, 9
	VNOTE F_, 5
	VREST 0
	VNOTE F_, 6
	VNOTE F_, 3
	SND_END

Snd86_SfxN:
	NVOICE $81, $A0
	NOISE $14
	NOISE $23
	NOISE $32
	NOISE $00
	NOISE $00
	NVOICE $82, $D0
	NOISE $0B
	NOISE $00
	NOISE_VOL 6
	NOISE $0B
	SND_END

Snd87_Sfx1:
	VVOICE $02, $40, $27
	OCTAVE 6
	VNOTE D_, 9
	VNOTE D#, 4
	VREST 0
	VNOTE E_, 5
	VNOTE F_, 3
	SND_END

Snd87_SfxN:
	NVOICE $81, $70
	NOISE $00
	NOISE $14
	NOISE $23
	NOISE $32
	NOISE $00
	NOISE $00
	NVOICE $82, $A0
	NOISE $0C
	NOISE $00
	NOISE_VOL 5
	NOISE $0C
	SND_END

Snd88_Sfx1:
	VVOICE $03, $00, $27
	OCTAVE 5
	VNOTE F_, 12
	VNOTE F_, 6
	VREST 0
	VNOTE F_, 7
	VNOTE F_, 4
	SND_END

Snd88_SfxN:
	NVOICE $81, $A0
	NOISE $14
	NOISE $23
	NOISE $32
	NOISE $00
	NOISE $00
	NOISE $00
	NOISE $00
	NVOICE $82, $D0
	NOISE $0C
	NOISE $00
	NOISE_VOL 6
	NOISE $0D
	SND_END

Snd89_Sfx1:
	VVOICE $05, $40, $47
	OCTAVE 6
	VNOTE F_, 6
	VNOTE F_, 3
	SND_END

Snd89_SfxN:
	NVOICE $82, $70
	NOISE $1B
	NOISE $2C
	NOISE $3D
	NOISE $00
	NOISE $00
	NVOICE $82, $B0
	NOISE $30
	NOISE $00
	NOISE_VOL 6
	NOISE $31
	SND_END

Snd8A_Sfx1:
	VVOICE $05, $40, $47
	OCTAVE 6
	VNOTE B_, 7
	VNOTE B_, 4
	SND_END

Snd8A_SfxN:
	NVOICE $82, $70
	NOISE $1A
	NOISE $2D
	NOISE $3E
	NOISE $00
	NOISE $00
	NVOICE $82, $A0
	NOISE $20
	NOISE $00
	NOISE_VOL 5
	NOISE $21
	SND_END

Snd8B_Sfx1:
	VVOICE $02, $40, $37
	OCTAVE 6
	VNOTE B_, 7
	VVOICE $02, $40, $3F
	OCTAVE 4
	VNOTE B_, 7
	VVOICE $02, $40, $37
	OCTAVE 6
	VNOTE B_, 4
	VVOICE $02, $40, $3F
	OCTAVE 4
	VNOTE B_, 4
	SND_END

Snd8B_SfxN:
	NVOICE $82, $80
	NOISE $11
	NOISE $14
	NOISE $17
	NVOICE $82, $B0
	NOISE $1A
	NOISE $00
	NOISE_VOL 5
	NOISE $1A
	SND_END

Snd8C_Sfx1:
	VVOICE $01, $00, $08
	OCTAVE 5
	VNOTE A#, 3
	VNOTE A#, 4
	VNOTE A#, 5
	VREST 0
	DUTY 4
	VNOTE B_, 6
	VNOTE A#, 6
	VNOTE B_, 6
	VNOTE A#, 6
	VNOTE B_, 6
	VNOTE B_, 3
	VNOTE A#, 3
	VNOTE B_, 3
	VNOTE A#, 3
	VNOTE B_, 3
	VNOTE B_, 2
	VNOTE A#, 2
	SND_END

Snd8C_SfxN:
	NVOICE $82, $90
	NOISE $11
	NOISE $14
	NOISE $17
	NVOICE $82, $C0
	NOISE $1A
	NOISE $00
	NOISE_VOL 6
	NOISE $1A
	NOISE $2B
	SND_END

Snd8D_Sfx1:
	VVOICE $02, $00, $00
	OCTAVE 6
	VNOTE A#, 8
	VNOTE B_, 8
	OCTAVE 5
	VNOTE B_, 8
	OCTAVE 4
	VNOTE B_, 8
	OCTAVE 3
	VNOTE B_, 8
	OCTAVE 2
	VNOTE B_, 8
	OCTAVE 6
	VNOTE B_, 4
	OCTAVE 5
	VNOTE B_, 4
	OCTAVE 4
	VNOTE B_, 4
	OCTAVE 3
	VNOTE B_, 4
	OCTAVE 2
	VNOTE B_, 4
	OCTAVE 6
	VNOTE B_, 2
	OCTAVE 5
	VNOTE B_, 2
	OCTAVE 4
	VNOTE B_, 2
	OCTAVE 3
	VNOTE B_, 2
	OCTAVE 2
	VNOTE B_, 2
	SND_END

Snd8D_SfxN:
	NVOICE $01, $90
	NOISE $30
	NOISE $00
	NOISE $04
	NOISE_VOL $0B
	NOISE $05
	NOISE_VOL 9
	NOISE $06
	NVOICE $01, $90
	NOISE $0F
	NVOICE $01, $60
	NOISE $16
	NVOICE $01, $60
	NOISE $1F
	NVOICE $01, $30
	NOISE $26
	NVOICE $01, $30
	NOISE $2F
	NVOICE $01, $30
	NOISE $36
	NVOICE $01, $30
	NOISE $3F
	NVOICE $01, $20
	NOISE $26
	NVOICE $01, $30
	NOISE $2F
	NVOICE $01, $30
	NOISE $16
	NVOICE $01, $30
	NOISE $1F
	SND_END

Snd8E_Sfx1:
	VVOICE $02, $00, $45
	OCTAVE 6
	VNOTE A#, 10
	OCTAVE 5
	VNOTE G_, 9
	VNOTE A#, 9
	OCTAVE 4
	VNOTE G_, 9
	VNOTE A#, 9
	OCTAVE 3
	VNOTE G_, 9
	VNOTE A#, 9
	OCTAVE 2
	VNOTE G_, 9
	VNOTE A#, 9
	OCTAVE 6
	VNOTE A#, 4
	OCTAVE 5
	VNOTE G_, 4
	VNOTE A#, 4
	OCTAVE 4
	VNOTE G_, 4
	VNOTE A#, 4
	OCTAVE 3
	VNOTE G_, 4
	VNOTE A#, 4
	OCTAVE 2
	VNOTE G_, 4
	VNOTE A#, 4
	SND_END

Snd8E_SfxN:
	NVOICE $01, $80
	NOISE $20
	NOISE $00
	NOISE_VOL 7
	NOISE $21
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	NOISE $27
	NVOICE $01, $80
	NOISE $28
	NVOICE $01, $80
	NOISE $29
	NVOICE $01, $80
	NOISE $2A
	NOISE $2B
	NOISE $2C
	NOISE $2D
	NOISE $2E
	NOISE $2F
	NVOICE $02, $40
	NOISE $3A
	NOISE $3B
	NOISE $3C
	NOISE $3D
	NOISE $3E
	NOISE $3F
	SND_END

Snd8F_Sfx1:
	VVOICE $01, $00, $46
	SND_END

Snd8F_SfxN:
	NVOICE $81, $90
	NOISE $3C
	NVOICE $81, $90
	NOISE $3D
	NVOICE $81, $90
	NOISE $3E
	NVOICE $01, $90
	NOISE $1F
	NOISE $1E
	NOISE $1D
	NOISE $1C
	NOISE $1B
	NOISE $1A
	NVOICE $01, $90
	NOISE $09
	NVOICE $01, $90
	NOISE $08
	NVOICE $01, $90
	NOISE $07
	NOISE $06
	NOISE $05
	NOISE $04
	NOISE $03
	NOISE $01
	NOISE $02
	NOISE $00
	SND_END

Snd90_Sfx1:
	VVOICE $02, $80, $55
	VREST 0
	OCTAVE 4
	VNOTE G_, 8
	VNOTE G_, 4
	VNOTE G#, 2
	SND_END

Snd90_SfxN:
	NVOICE $01, $B0
	NOISE $00
	NOISE $30
	NOISE $50
	SND_END

Snd91_Sfx1:
	VVOICE $02, $80, $08
	OCTAVE 6
	VNOTE C_, 4
	VNOTE C_, 8
	VVOICE $05, $80, $08
	VNOTE C_, 14
	VNOTE C_, 8
	VNOTE C_, 4
	VNOTE C_, 2
	VNOTE C_, 8
	VNOTE C_, 5
	VNOTE C_, 4
	VNOTE C_, 2
	VNOTE C_, 6
	VNOTE C_, 3
	VNOTE C_, 1
	SND_END

Snd91_SfxN:
	NVOICE $82, $30
	NOISE $08
	NOISE $0B
	NOISE_VOL 6
	NOISE $A0
	NVOICE $84, $E0
	NOISE $08
	NOISE $09
	NOISE_VOL 5
	NOISE $08
	NOISE $09
	NOISE_VOL 8
	NOISE $08
	NOISE $09
	NOISE_VOL 3
	NOISE $08
	NOISE $09
	NOISE_VOL 5
	NOISE $08
	NOISE $09
	NOISE_VOL 2
	NOISE $08
	NOISE $09
	SND_END

Snd92_Sfx1:
	VVOICE $02, $00, $08
	OCTAVE 5
	VNOTE C_, 2
	VNOTE F#, 3
	VNOTE E_, 4
	VNOTE D_, 5
	VNOTE C_, 6
	VNOTE F#, 7
	VNOTE E_, 8
	VNOTE D_, 9
	VNOTE C_, 10
	VNOTE F#, 11
	VNOTE E_, 11
	VNOTE D_, 11
	VNOTE C_, 11
	VNOTE F#, 11
	VNOTE E_, 11
	VNOTE D_, 11
	VNOTE C_, 11
	VNOTE F#, 11
	VNOTE E_, 11
	VNOTE D_, 11
	VNOTE C_, 7
	VNOTE F#, 7
	VNOTE E_, 7
	VNOTE D_, 7
	VNOTE C_, 4
	VNOTE F#, 4
	VNOTE E_, 4
	VNOTE D_, 4
	VNOTE C_, 7
	VNOTE F#, 7
	VNOTE E_, 7
	VNOTE D_, 7
	VNOTE C_, 7
	VNOTE F#, 7
	VNOTE E_, 7
	VNOTE D_, 7
	VNOTE C_, 4
	VNOTE F#, 4
	VNOTE E_, 4
	VNOTE D_, 4
	VNOTE C_, 2
	VNOTE F#, 2
	VNOTE E_, 2
	VNOTE D_, 2
	VNOTE C_, 4
	VNOTE F#, 4
	VNOTE E_, 4
	VNOTE D_, 4
	VNOTE C_, 4
	VNOTE F#, 4
	VNOTE E_, 4
	VNOTE D_, 4
	VNOTE C_, 2
	VNOTE F#, 2
	VNOTE E_, 2
	VNOTE D_, 2
	SND_END

Snd92_SfxN:
	NVOICE $82, $C0
	NOISE $67
	NOISE $57
	NOISE $47
	NOISE $37
	NOISE $27
	NOISE $17
	NOISE $07
	NOISE $06
	NOISE $05
	NOISE $04
	NOISE $03
	NOISE $02
	NOISE $01
	NOISE $00
	NOISE_VOL 6
	NOISE $17
	NOISE $16
	NOISE $15
	NOISE $14
	NOISE $13
	NOISE $12
	NOISE $11
	NOISE $10
	NOISE_VOL 3
	NOISE $25
	NOISE $24
	NOISE $23
	NOISE $22
	NOISE $21
	NOISE $20
	NOISE_VOL 2
	NOISE $33
	NOISE $32
	NOISE $31
	NOISE $30
	SND_END

Snd93_Sfx1:
	VVOICE $01, $40, $2F
	OCTAVE 6
	VNOTE G_, 9
	OCTAVE 5
	VNOTE B_, 9
	VNOTE D#, 9
	VVOICE $02, $80, $3E
	VNOTE B_, 9
	VNOTE D#, 9
	VNOTE D#, 9
	VNOTE B_, 5
	VNOTE D#, 5
	VNOTE D#, 5
	VNOTE B_, 3
	VNOTE D#, 3
	VNOTE D#, 3
	VNOTE B_, 2
	VNOTE D#, 2
	VNOTE D#, 2
	VNOTE B_, 4
	VNOTE D#, 4
	VNOTE D#, 4
	VNOTE B_, 2
	VNOTE D#, 2
	VNOTE D#, 2
	SND_END

Snd93_SfxN:
	NVOICE $81, $80
	NOISE $0C
	NOISE $0F
	NOISE $1C
	NOISE $1F
	NOISE $2C
	NOISE $2F
	NOISE $3C
	NOISE $3F
	NOISE $6D
	NOISE $6E
	NOISE $6F
	NOISE $5D
	NOISE $5E
	NOISE $5F
	NOISE $4D
	NOISE $4E
	NOISE $4F
	NOISE $3D
	NOISE $3E
	NOISE $3F
	NOISE $2D
	NOISE $2E
	NOISE $2F
	NOISE $1D
	NOISE $1E
	NOISE $1F
	NOISE $0D
	NOISE $0E
	NOISE $0F
	NVOICE $81, $80
	NOISE $10
	NOISE $11
	NOISE $12
	NOISE $13
	NOISE $14
	NOISE $15
	NOISE $16
	NOISE $17
	NOISE_VOL 4
	NOISE $21
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	NOISE $27
	NOISE_VOL 2
	NOISE $32
	NOISE $33
	NOISE $34
	NOISE $35
	NOISE $36
	NOISE $37
	SND_END

Snd94_Sfx1:
	VVOICE $02, $00, $08
	OCTAVE 6
	VNOTE A_, 12
	OCTAVE 5
	VNOTE A#, 12
	OCTAVE 6
	VNOTE D_, 12
	OCTAVE 5
	VNOTE D#, 12
	OCTAVE 4
	VNOTE E_, 12
	OCTAVE 6
	VNOTE D_, 12
	OCTAVE 5
	VNOTE D#, 12
	OCTAVE 4
	VNOTE E_, 12
	OCTAVE 6
	VNOTE A_, 6
	OCTAVE 5
	VNOTE A#, 6
	VREST 0
	OCTAVE 6
	VNOTE D_, 6
	OCTAVE 5
	VNOTE D#, 6
	OCTAVE 4
	VNOTE E_, 6
	OCTAVE 6
	VNOTE D_, 3
	OCTAVE 5
	VNOTE D#, 3
	OCTAVE 4
	VNOTE E_, 3
	SND_END

Snd94_SfxN:
	NVOICE $82, $A0
	NOISE $49
	NOISE $37
	NVOICE $81, $A0
	NOISE $1C
	NOISE $2D
	NOISE $1D
	NOISE $2E
	NOISE $1E
	NOISE $2F
	NVOICE $81, $A0
	NOISE $20
	NOISE $21
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	NOISE $27
	NOISE $37
	NOISE $36
	NOISE $47
	NOISE $46
	NOISE $57
	NOISE $56
	NOISE $67
	SND_END

Snd95_Sfx1:
	VVOICE $01, $00, $08
	OCTAVE 5
	VNOTE F_, 12
	OCTAVE 4
	VNOTE F_, 12
	OCTAVE 5
	VNOTE F_, 12
	VREST 0
	OCTAVE 6
	VNOTE F_, 12
	OCTAVE 5
	VNOTE F_, 12
	OCTAVE 4
	VNOTE F_, 12
	OCTAVE 3
	VNOTE F_, 12
	OCTAVE 2
	VNOTE F_, 12
	VREST 0
	VVOICE $02, $00, $08
	OCTAVE 5
	VNOTE A#, 12
	VNOTE E_, 12
	VNOTE F_, 12
	VNOTE A#, 12
	VNOTE F_, 12
	VNOTE F_, 12
	VNOTE A#, 6
	VNOTE F_, 6
	VNOTE F_, 6
	VNOTE A#, 3
	VNOTE F_, 3
	VNOTE F_, 3
	VREST 0
	VNOTE A#, 5
	VNOTE F_, 5
	VNOTE F_, 5
	VNOTE A#, 5
	VNOTE F_, 5
	VNOTE F_, 5
	VNOTE A#, 3
	VNOTE F_, 3
	VNOTE F_, 3
	SND_END

Snd95_SfxN:
	NVOICE $81, $A0
	NOISE $25
	NOISE $14
	NOISE $03
	NOISE $02
	NOISE $57
	NOISE $46
	NOISE $35
	NOISE $24
	NOISE $13
	NOISE $00
	NVOICE $82, $A0
	NOISE $0D
	NOISE $0E
	NOISE $0F
	NOISE $1E
	NOISE $1F
	NOISE $2F
	NOISE_VOL 6
	NOISE $0D
	NOISE $0E
	NOISE $0F
	NOISE $1E
	NOISE $1F
	NOISE $2F
	NOISE_VOL 3
	NOISE $0D
	NOISE $0E
	NOISE $0F
	NOISE $1E
	NOISE $1F
	NOISE $2F
	SND_END

Snd96_SfxN:
	NVOICE $82, $C0
	NOISE $00
	NOISE $13
	NOISE $26
	NVOICE $83, $60
	NOISE $16
	NOISE $24
	NOISE $30
	SND_END

Snd97_SfxN:
	NVOICE $82, $C0
	NOISE $14
	NOISE $25
	NOISE $36
	NVOICE $83, $60
	NOISE $06
	NOISE $14
	NOISE $20
	SND_END

Snd98_SfxN:
	NVOICE $81, $C0
	NOISE $20
	NOISE $22
	NOISE $24
	NOISE $26
	NOISE $36
	NOISE $46
	NOISE $56
	NOISE $76
	NVOICE $82, $60
	NOISE $06
	NOISE $14
	NOISE $22
	NOISE $30
	NOISE_VOL 5
	NOISE $16
	NOISE $24
	NOISE $32
	NOISE $40
	SND_END

Snd99_SfxN:
	NVOICE $81, $C0
	NOISE $31
	NOISE $24
	NOISE $15
	NOISE $07
	NVOICE $83, $60
	NOISE $14
	NOISE $25
	NOISE $36
	NOISE $47
	NOISE_VOL 5
	NOISE $24
	NOISE $35
	NOISE $46
	NOISE $57
	SND_END

Snd9A_SfxN:
	NVOICE $81, $C0
	NOISE $36
	NOISE $25
	NOISE $14
	NOISE $02
	NVOICE $82, $C0
	NOISE $02
	NOISE $14
	NOISE $25
	NOISE $36
	NVOICE $83, $60
	NOISE $16
	NOISE $24
	NOISE $32
	NOISE $40
	SND_END

Snd9B_Sfx1:
	VVOICE $02, $00, $08
	OCTAVE 6
	VNOTE F#, 2
	VNOTE F#, 5
	VNOTE F#, 7
	VNOTE G_, 9
	VNOTE G_, 8
	VNOTE G_, 7
	VNOTE G_, 6
	VNOTE G_, 5
	VNOTE G_, 3
	VNOTE G_, 2
	SND_END

Snd9B_SfxN:
	NVOICE $81, $C0
	NOISE $31
	NOISE $24
	NOISE $15
	NOISE $07
	NVOICE $83, $60
	NOISE $14
	NOISE $25
	NOISE $36
	NOISE $47
	NOISE_VOL 5
	NOISE $24
	NOISE $35
	NOISE $46
	NOISE $57
	SND_END

Snd9C_Sfx1:
	VVOICE $01, $80, $08
	VREST 0
	OCTAVE 6
	VNOTE A_, 6
	DUTY 0
	VNOTE A_, 6
	VNOTE A_, 3
	DUTY 8
	VNOTE B_, 6
	VVOICE $03, $00, $08
	VNOTE B_, 6
	VNOTE B_, 5
	VNOTE B_, 3
	VNOTE B_, 2
	VVOICE $01, $80, $08
	VNOTE B_, 3
	VVOICE $03, $00, $08
	VNOTE B_, 3
	VNOTE B_, 3
	VNOTE B_, 2
	SND_END

Snd9C_SfxN:
	NVOICE $81, $B0
	NOISE $36
	NOISE $25
	NOISE $14
	NOISE $02
	NVOICE $82, $B0
	NOISE $02
	NOISE $14
	NOISE $25
	NOISE $36
	NVOICE $83, $60
	NOISE $16
	NOISE $24
	NOISE $32
	NOISE $40
	SND_END

Snd9D_SfxN:
	NVOICE $81, $B0
	NOISE $0A
	NOISE $0B
	NOISE $0C
	NVOICE $81, $B0
	NOISE $02
	NOISE $22
	NOISE $32
	NOISE $42
	NOISE $52
	NOISE $62
	NOISE $32
	NOISE $22
	NOISE $12
	NOISE $02
	SND_END

Snd9E_Sfx1:
	VVOICE $01, $00, $08
	OCTAVE 6
	VNOTE G_, 9
	OCTAVE 5
	VNOTE G_, 9
	VNOTE D#, 9
	VNOTE B_, 9
	OCTAVE 4
	VNOTE G_, 9
	VNOTE D#, 9
	VNOTE B_, 9
	OCTAVE 3
	VNOTE G_, 9
	VNOTE D#, 9
	VNOTE B_, 9
	OCTAVE 5
	VNOTE G_, 5
	VNOTE D#, 5
	VNOTE B_, 5
	OCTAVE 4
	VNOTE G_, 5
	VNOTE D#, 5
	VNOTE B_, 5
	OCTAVE 3
	VNOTE G_, 5
	VNOTE D#, 5
	VNOTE B_, 5
	OCTAVE 5
	VNOTE G_, 3
	VNOTE D#, 3
	VNOTE B_, 3
	OCTAVE 4
	VNOTE G_, 3
	VNOTE D#, 3
	VNOTE B_, 3
	OCTAVE 3
	VNOTE G_, 3
	VNOTE D#, 3
	VNOTE B_, 3
	SND_END

Snd9E_SfxN:
	NVOICE $81, $B0
	NOISE $02
	NOISE $12
	NOISE $22
	NOISE $32
	NOISE $42
	NOISE $52
	NOISE $62
	NOISE $72
	NOISE $82
	NOISE $32
	NOISE $22
	NOISE $12
	NOISE $02
	SND_END

Snd9F_Sfx1:
	VVOICE $01, $00, $08
	OCTAVE 6
	VNOTE C_, 2
	OCTAVE 4
	VNOTE C_, 3
	OCTAVE 5
	VNOTE C_, 4
	OCTAVE 3
	VNOTE C_, 5
	OCTAVE 4
	VNOTE C_, 6
	OCTAVE 6
	VNOTE C_, 7
	OCTAVE 5
	VNOTE C_, 8
	OCTAVE 3
	VNOTE C_, 9
	OCTAVE 6
	VNOTE C_, 9
	OCTAVE 4
	VNOTE C_, 9
	OCTAVE 5
	VNOTE C_, 9
	OCTAVE 3
	VNOTE C_, 9
	OCTAVE 4
	VNOTE C_, 9
	OCTAVE 6
	VNOTE C_, 9
	OCTAVE 5
	VNOTE C_, 9
	OCTAVE 3
	VNOTE C_, 9
	OCTAVE 6
	VNOTE C_, 5
	OCTAVE 4
	VNOTE C_, 5
	OCTAVE 5
	VNOTE C_, 5
	OCTAVE 3
	VNOTE C_, 5
	OCTAVE 4
	VNOTE C_, 5
	OCTAVE 6
	VNOTE C_, 5
	OCTAVE 5
	VNOTE C_, 5
	OCTAVE 3
	VNOTE C_, 5
	OCTAVE 6
	VNOTE C_, 3
	OCTAVE 4
	VNOTE C_, 3
	OCTAVE 5
	VNOTE C_, 3
	OCTAVE 3
	VNOTE C_, 3
	OCTAVE 4
	VNOTE C_, 3
	OCTAVE 6
	VNOTE C_, 3
	OCTAVE 5
	VNOTE C_, 3
	OCTAVE 3
	VNOTE C_, 3
	SND_END

Snd9F_SfxN:
	NVOICE $82, $E0
	NOISE $00
	NOISE $02
	NOISE $04
	NOISE $15
	NOISE $26
	NVOICE $83, $80
	NOISE $1E
	NOISE $2D
	NOISE $1C
	NOISE $2B
	NOISE $1C
	NOISE $2D
	NOISE $1E
	NOISE $2F
	SND_END

SndA0_SfxN:
	NVOICE $81, $D0
	NOISE $03
	NOISE $23
	NOISE $44
	NOISE $64
	NOISE $55
	NOISE $54
	NOISE $53
	NOISE $52
	NOISE $51
	NOISE $50
	NOISE_VOL 7
	NOISE $55
	NOISE $54
	NOISE $53
	NOISE $52
	NOISE $51
	NOISE $50
	NOISE_VOL 4
	NOISE $65
	NOISE $64
	NOISE $63
	NOISE $62
	NOISE $61
	NOISE $60
	SND_END

SndA1_Sfx1:
	VVOICE $02, $00, $08
	OCTAVE 6
	VNOTE A_, 8
	OCTAVE 4
	VNOTE A_, 8
	OCTAVE 5
	VNOTE C#, 8
	VNOTE D_, 8
	VNOTE F#, 8
	VNOTE A_, 8
	OCTAVE 6
	VNOTE C#, 8
	VNOTE D_, 8
	VNOTE F#, 8
	VNOTE A_, 8
	OCTAVE 4
	VNOTE A_, 6
	OCTAVE 5
	VNOTE C#, 6
	VNOTE D_, 6
	VNOTE F#, 6
	VNOTE A_, 6
	OCTAVE 6
	VNOTE C#, 6
	VNOTE D_, 6
	VNOTE F#, 6
	VNOTE A_, 6
	OCTAVE 4
	VNOTE A_, 3
	OCTAVE 5
	VNOTE C#, 3
	VNOTE D_, 3
	VNOTE F#, 3
	VNOTE A_, 3
	VNOTE C#, 2
	VNOTE D_, 2
	VNOTE F#, 2
	VNOTE A_, 2
	SND_END

SndA1_SfxN:
	NVOICE $82, $B0
	NOISE $02
	NOISE $03
	NOISE $12
	NOISE $13
	NOISE $32
	NOISE $33
	NOISE $42
	NOISE $43
	NOISE $32
	NOISE $33
	NOISE $34
	NOISE $35
	NOISE $36
	NOISE $37
	NOISE_VOL 6
	NOISE $32
	NOISE $33
	NOISE $34
	NOISE $35
	NOISE $36
	NOISE $37
	NOISE_VOL 4
	NOISE $32
	NOISE $33
	NOISE $34
	NOISE_VOL 2
	NOISE $35
	NOISE $36
	NOISE $37
	SND_END

SndA2_Sfx1:
	VVOICE $01, $80, $27
	OCTAVE 4
	VNOTE F_, 3
	VNOTE D_, 4
	VNOTE F_, 6
	VNOTE D_, 7
	VNOTE F_, 7
	VNOTE D_, 7
	VNOTE F#, 7
	VNOTE D#, 7
	VNOTE G_, 7
	VNOTE E_, 7
	VNOTE F#, 7
	VNOTE D#, 6
	VNOTE F_, 6
	VNOTE D_, 6
	VNOTE E_, 4
	VNOTE C#, 4
	OCTAVE 3
	VNOTE G_, 8
	OCTAVE 2
	VNOTE E_, 8
	OCTAVE 3
	VNOTE F#, 7
	OCTAVE 4
	VNOTE D#, 7
	OCTAVE 3
	VNOTE F_, 6
	OCTAVE 2
	VNOTE D_, 6
	VNOTE E_, 4
	VNOTE C#, 3
	SND_END

SndA2_SfxN:
	NVOICE $81, $90
	NOISE $01
	NOISE $03
	NOISE $05
	NVOICE $84, $90
	NOISE $2D
	NOISE $3D
	NOISE $4D
	NOISE_VOL 6
	NOISE $4D
	NOISE $5D
	SND_END

SndA3_Sfx1:
	VVOICE $01, $80, $08
	OCTAVE 4
	VNOTE F_, 4
	VNOTE F_, 5
	VNOTE F_, 6
	VNOTE F_, 7
	VNOTE F_, 7
	VVOICE $07, $80, $46
	VNOTE F_, 7
	VVOICE $01, $80, $08
	VNOTE F_, 6
	VNOTE F_, 6
	VNOTE F_, 5
	VNOTE F_, 4
	VNOTE F_, 3
	VNOTE F_, 2
	VVOICE $07, $80, $46
	VNOTE F_, 6
	VVOICE $01, $80, $08
	VNOTE F_, 5
	VNOTE F_, 4
	VNOTE F_, 3
	VNOTE F_, 2
	SND_END

SndA3_SfxN:
	NVOICE $81, $B0
	NOISE $01
	NOISE $65
	NOISE $55
	NOISE $45
	NOISE $35
	NOISE $25
	NOISE $15
	NOISE $05
	SND_END

SndA4_SfxN:
	NVOICE $81, $A0
	NOISE $20
	NVOICE $85, $A0
	NOISE $3F
	NVOICE $81, $A0
	NOISE $00
	NVOICE $81, $A0
	NOISE $2F
	NVOICE $85, $A0
	NOISE $3F
	SND_END

SndA5_SfxN:
	NVOICE $82, $80
	NOISE $2B
	NVOICE $8D, $80
	NOISE $2D
	NVOICE $82, $80
	NOISE $3D
	NOISE $4D
	NOISE_VOL 7
	NOISE $5D
	SND_END

Snd10_Sfx2:
	SND_END

SECTION "Sound bank $0D", ROMX[$4000], BANK[$0D]

SndA6_Sfx1:
	VVOICE $07, $00, $26
	OCTAVE 4
	VNOTE B_, 11
	VNOTE B_, 5
	SND_END

SndA6_SfxN:
	NVOICE $81, $C0
	NOISE $02
	NOISE $12
	SND_END

SndA7_Sfx1:
	VVOICE $02, $00, $27
	OCTAVE 5
	VNOTE D_, 11
	VNOTE G#, 11
	VVOICE $02, $40, $27
	OCTAVE 4
	VNOTE D_, 8
	VNOTE G#, 8
	VNOTE A_, 8
	VNOTE D_, 4
	VNOTE G#, 4
	VNOTE A_, 4
	SND_END

SndA7_SfxN:
	NVOICE $81, $C0
	NOISE $05
	NOISE $15
	NOISE $25
	SND_END

SndA8_Sfx1:
	VVOICE $04, $00, $36
	OCTAVE 4
	VNOTE D_, 11
	VNOTE F#, 11
	VNOTE A_, 11
	VVOICE $03, $00, $26
	VNOTE D_, 6
	VNOTE F#, 6
	VNOTE A_, 6
	SND_END

SndA8_SfxN:
	NVOICE $81, $C0
	NOISE $03
	NOISE $13
	NOISE $23
	SND_END

SndA9_Sfx1:
	VVOICE $04, $00, $27
	OCTAVE 5
	VNOTE E_, 10
	VNOTE G#, 10
	OCTAVE 6
	VNOTE E_, 10
	VVOICE $02, $00, $27
	OCTAVE 5
	VNOTE E_, 5
	VNOTE G#, 5
	VNOTE B_, 5
	VNOTE E_, 3
	VNOTE G#, 3
	VNOTE B_, 3
	SND_END

SndA9_SfxN:
	NVOICE $81, $B0
	NOISE $05
	NOISE $15
	NOISE $25
	NOISE $35
	NOISE $45
	NOISE $55
	NOISE $65
	SND_END

SndAA_Sfx1:
	VVOICE $02, $00, $27
	OCTAVE 6
	VNOTE E_, 11
	VNOTE G_, 11
	VNOTE D_, 11
	OCTAVE 5
	VNOTE E_, 7
	VNOTE G_, 7
	VNOTE B_, 7
	VNOTE E_, 4
	VNOTE G_, 4
	VNOTE B_, 4
	SND_END

SndAA_SfxN:
	NVOICE $82, $C0
	NOISE $10
	NOISE $13
	NOISE $15
	NOISE_VOL 6
	NOISE $10
	NOISE $13
	NOISE $15
	SND_END

SndAB_Sfx1:
	VVOICE $02, $C0, $08
	OCTAVE 3
	VNOTE C_, 5
	OCTAVE 4
	VNOTE C#, 8
	OCTAVE 5
	VNOTE D_, 9
	OCTAVE 6
	VNOTE D#, 10
	OCTAVE 3
	VNOTE C_, 5
	OCTAVE 4
	VNOTE C#, 5
	OCTAVE 5
	VNOTE D_, 5
	OCTAVE 6
	VNOTE D#, 5
	OCTAVE 3
	VNOTE C_, 3
	OCTAVE 4
	VNOTE C#, 3
	OCTAVE 5
	VNOTE D_, 3
	OCTAVE 6
	VNOTE D#, 3
	SND_END

SndAB_SfxN:
	NVOICE $82, $B0
	NOISE $30
	NOISE $33
	NOISE $35
	NOISE_VOL 5
	NOISE $30
	NOISE $33
	NOISE $35
	SND_END

SndAC_Sfx1:
	VVOICE $01, $00, $08
	OCTAVE 6
	VNOTE D_, 6
	VNOTE C#, 9
	VNOTE A_, 10
	VNOTE G#, 11
	VREST 0
	VNOTE D_, 10
	VNOTE C#, 10
	VNOTE A_, 10
	VNOTE G#, 7
	VREST 0
	VNOTE D_, 6
	VNOTE C#, 6
	VNOTE A_, 6
	VNOTE G#, 6
	VREST 0
	VNOTE D_, 5
	VNOTE C#, 5
	VNOTE A_, 5
	VNOTE G#, 5
	VREST 0
	VNOTE D_, 3
	VNOTE C#, 3
	VNOTE A_, 3
	VNOTE G#, 3
	SND_END

SndAC_SfxN:
	NVOICE $82, $A0
	NOISE $2F
	NOISE $2D
	NOISE $2B
	NOISE $29
	SND_END

SndAD_Sfx1:
	VVOICE $02, $00, $08
	OCTAVE 6
	VNOTE E_, 11
	OCTAVE 5
	VNOTE F_, 11
	OCTAVE 4
	VNOTE F#, 11
	OCTAVE 3
	VNOTE G_, 11
	OCTAVE 2
	VNOTE G#, 11
	OCTAVE 6
	VNOTE E_, 6
	OCTAVE 5
	VNOTE F_, 6
	OCTAVE 4
	VNOTE F#, 6
	OCTAVE 3
	VNOTE G_, 6
	OCTAVE 2
	VNOTE G#, 6
	OCTAVE 6
	VNOTE E_, 3
	OCTAVE 5
	VNOTE F_, 3
	OCTAVE 4
	VNOTE F#, 3
	OCTAVE 3
	VNOTE G_, 2
	OCTAVE 2
	VNOTE G#, 2
	SND_END

SndAD_SfxN:
	NVOICE $81, $B0
	NOISE $0B
	NOISE $0C
	NOISE $0D
	NOISE $0E
	NVOICE $82, $B0
	NOISE $0F
	NOISE $0D
	NOISE $0B
	NOISE $09
	NOISE $19
	NOISE $29
	NOISE $39
	NOISE $49
	NOISE $59
	SND_END

SndAE_Sfx1:
	VVOICE $01, $00, $08
	OCTAVE 2
	VNOTE C_, 10
	OCTAVE 3
	VNOTE C_, 10
	OCTAVE 4
	VNOTE C_, 10
	OCTAVE 5
	VNOTE C_, 10
	OCTAVE 6
	VNOTE C_, 10
	OCTAVE 5
	VNOTE C_, 10
	VVOICE $04, $00, $08
	OCTAVE 6
	VNOTE C_, 10
	VNOTE C_, 6
	VNOTE C_, 3
	SND_END

SndAE_SfxN:
	NVOICE $81, $B0
	NOISE $0F
	NOISE $1F
	NOISE $2F
	NOISE $0D
	NOISE $1D
	NOISE $2D
	NOISE $0B
	NOISE $1B
	NOISE $2B
	NOISE $3B
	NOISE $4B
	NOISE $5B
	NVOICE $81, $B0
	NOISE $57
	NOISE $56
	NOISE $55
	NOISE $54
	NOISE $53
	NOISE $52
	NOISE $51
	NOISE $50
	SND_END

SndAF_SfxN:
	NVOICE $82, $B0
	NOISE $02
	NOISE $1C
	NOISE $24
	NOISE $3C
	NVOICE $81, $B0
	NOISE $46
	NOISE $47
	NVOICE $81, $B0
	NOISE $4B
	NOISE $4D
	NOISE $5D
	NOISE_VOL 7
	NOISE $4D
	NOISE $5D
	NVOICE $81, $70
	NOISE $37
	NOISE $35
	NOISE $33
	NOISE $31
	NOISE $30
	SND_END

SndB0_SfxN:
	NVOICE $83, $A0
	NOISE $4A
	NOISE $5A
	NVOICE $81, $A0
	NOISE $00
	NVOICE $85, $A0
	NOISE $5B
	SND_END

SndB1_SfxN:
	NVOICE $83, $A0
	NOISE $59
	NOISE $69
	NVOICE $81, $A0
	NOISE $00
	NVOICE $85, $A0
	NOISE $59
	SND_END

SndB2_SfxN:
	NVOICE $81, $C0
	NOISE $0D
	NVOICE $84, $A0
	NOISE $3E
	NVOICE $81, $A0
	NOISE $00
	NVOICE $85, $A0
	NOISE $3A
	SND_END

SndB3_Sfx1:
	VVOICE $01, $00, $2F
	OCTAVE 4
	VNOTE A#, 13
	VNOTE B_, 13
	VNOTE A#, 8
	VNOTE B_, 8
	SND_END

SndB3_SfxN:
	NVOICE $83, $A0
	NOISE $50
	NVOICE $83, $A0
	NOISE $69
	NVOICE $81, $A0
	NOISE $00
	NVOICE $85, $A0
	NOISE $58
	SND_END

SndB4_Sfx1:
	VVOICE $02, $00, $08
	OCTAVE 4
	VNOTE D_, 12
	OCTAVE 3
	VNOTE D_, 12
	OCTAVE 4
	VNOTE D_, 11
	OCTAVE 3
	VNOTE D_, 11
	SND_END

SndB4_SfxN:
	NVOICE $85, $90
	NOISE $3E
	NVOICE $81, $90
	NOISE $00
	NVOICE $83, $90
	NOISE $2B
	NOISE $3A
	SND_END

SndB5_Sfx1:
	VVOICE $05, $40, $08
	OCTAVE 5
	VNOTE E_, 7
	VNOTE E_, 4
	SND_END

SndB5_SfxN:
	NVOICE $85, $70
	NOISE $2F
	NVOICE $81, $70
	NOISE $00
	NVOICE $85, $70
	NOISE $3B
	SND_END

SndB6_Sfx1:
	VVOICE $06, $80, $2F
	OCTAVE 5
	VNOTE D_, 6
	VNOTE D_, 3
	VNOTE D_, 2
	SND_END

SndB6_SfxN:
	NVOICE $83, $60
	NOISE $4B
	NOISE $4A
	NVOICE $81, $60
	NOISE $00
	NOISE $4B
	NOISE $4A
	NOISE $4B
	NOISE $4A
	NOISE $4B
	NOISE $4A
	NOISE $4B
	NOISE $4A
	SND_END

SndB7_Sfx1:
	VVOICE $01, $00, $08
	OCTAVE 3
	VNOTE A_, 8
	VNOTE A#, 9
	VNOTE B_, 10
	OCTAVE 4
	VNOTE C_, 11
	VNOTE C#, 12
	VVOICE $05, $00, $26
	OCTAVE 3
	VNOTE D_, 12
	VNOTE D#, 9
	VNOTE E_, 5
	SND_END

SndB7_SfxN:
	NVOICE $83, $B0
	NOISE $1C
	NOISE $1A
	NVOICE $81, $70
	NOISE $00
	NOISE $1B
	NOISE $1A
	NOISE $1C
	NOISE $1B
	NOISE $1A
	NOISE $1C
	NOISE $1B
	NOISE $1A
	SND_END

SndB8_Sfx1:
	VVOICE $02, $40, $08
	OCTAVE 5
	VNOTE A_, 5
	OCTAVE 4
	VNOTE G#, 6
	VNOTE A_, 7
	VNOTE E_, 8
	OCTAVE 5
	VNOTE A_, 8
	OCTAVE 4
	VNOTE G#, 8
	VNOTE A_, 8
	VNOTE E_, 8
	OCTAVE 5
	VNOTE A_, 5
	OCTAVE 4
	VNOTE G#, 5
	VNOTE A_, 5
	VNOTE E_, 5
	OCTAVE 5
	VNOTE A_, 3
	OCTAVE 4
	VNOTE G#, 3
	VNOTE A_, 3
	VNOTE E_, 3
	OCTAVE 5
	VNOTE A_, 2
	SND_END

SndB8_SfxN:
	NVOICE $81, $A0
	NOISE $11
	NOISE $13
	NOISE $15
	NVOICE $81, $A0
	NOISE $00
	NOISE $55
	NOISE $45
	NOISE $35
	NOISE $25
	NOISE $15
	NOISE $05
	NOISE $04
	NOISE $03
	NOISE $02
	NOISE $01
	SND_END

SndB9_Sfx1:
	VVOICE $01, $40, $36
	VREST 0
	VREST 0
	OCTAVE 4
	VNOTE E_, 6
	VNOTE A#, 11
	VNOTE E_, 6
	VNOTE A#, 3
	SND_END

SndB9_SfxN:
	NVOICE $82, $90
	NOISE $14
	NOISE $24
	SND_END

SndBA_SfxN:
	NVOICE $83, $C0
	NOISE $59
	NVOICE $83, $C0
	NOISE $5A
	NVOICE $83, $C0
	NOISE $40
	NVOICE $83, $60
	NOISE $49
	NVOICE $83, $60
	NOISE $5A
	NVOICE $83, $60
	NOISE $40
	SND_END

SndBB_SfxN:
	NVOICE $81, $B0
	NOISE $39
	NVOICE $81, $B0
	NOISE $38
	NVOICE $81, $B0
	NOISE $36
	NOISE $23
	NOISE $24
	NOISE $13
	NOISE $14
	NOISE $15
	NOISE $00
	NVOICE $81, $B0
	NOISE $2F
	NOISE $2E
	NOISE $3F
	NOISE $3E
	NOISE $4F
	NOISE $4E
	NOISE $4D
	NOISE $4C
	SND_END

SndBC_SfxN:
	NVOICE $81, $C0
	NOISE $30
	NOISE_VOL $0E
	NOISE $13
	NOISE_VOL $0B
	NOISE $24
	NOISE_VOL 7
	NOISE $35
	NOISE $46
	SND_END

SndBD_SfxN:
	NVOICE $81, $E0
	NOISE $30
	NOISE_VOL $0F
	NOISE $24
	NOISE_VOL $0D
	NOISE $25
	NOISE_VOL 7
	NOISE $26
	NOISE $46
	SND_END

SndBE_SfxN:
	NVOICE $81, $C0
	NOISE $30
	NVOICE $81, $E0
	NOISE $3C
	NOISE_VOL $0B
	NOISE $3D
	NOISE_VOL 7
	NOISE $3E
	NVOICE $81, $70
	NOISE $46
	SND_END

SndBF_SfxN:
	NVOICE $81, $E0
	NOISE $22
	NOISE $47
	NOISE $36
	NOISE $25
	NOISE $24
	NOISE $00
	NOISE $13
	NOISE $00
	NOISE $01
	NOISE $00
	NOISE $17
	SND_END

SndC0_Sfx1:
	VVOICE $01, $80, $08
	VREST 0
	OCTAVE 5
	VNOTE A_, 7
	VNOTE A#, 8
	VNOTE B_, 9
	VREST 0
	VNOTE B_, 6
	VNOTE B_, 5
	VNOTE B_, 4
	SND_END

SndC0_SfxN:
	NVOICE $81, $E0
	NOISE $30
	NOISE $07
	NOISE $16
	NOISE $25
	NOISE $34
	NOISE $00
	NOISE $00
	NOISE $00
	NOISE $01
	NOISE $00
	NOISE $17
	SND_END

SndC1_Sfx1:
	VVOICE $01, $80, $17
	VREST 0
	OCTAVE 5
	VNOTE A_, 7
	VNOTE A#, 8
	VNOTE B_, 10
	VREST 0
	VNOTE B_, 6
	VNOTE B_, 5
	VNOTE B_, 4
	SND_END

SndC1_SfxN:
	NVOICE $81, $D0
	NOISE $30
	NOISE $15
	NOISE $25
	NOISE $35
	NOISE $45
	NOISE $00
	NOISE $00
	NOISE $00
	NOISE $01
	NOISE $00
	NOISE $05
	SND_END

SndC2_SfxN:
	NVOICE $81, $D0
	NOISE $30
	NVOICE $81, $D0
	NOISE $1F
	NOISE $2F
	NOISE $3F
	NOISE $4F
	NVOICE $81, $D0
	NOISE $00
	NVOICE $81, $D0
	NOISE $0F
	NOISE $0E
	NVOICE $81, $D0
	NOISE $00
	NVOICE $81, $D0
	NOISE $05
	SND_END

SndC3_Sfx1:
	VVOICE $01, $00, $08
	OCTAVE 2
	VNOTE D_, 5
	VNOTE E_, 8
	VNOTE F#, 11
	OCTAVE 2
	VNOTE G#, 13
	OCTAVE 3
	VNOTE G#, 12
	OCTAVE 4
	VNOTE G#, 12
	OCTAVE 5
	VNOTE G#, 12
	OCTAVE 6
	VNOTE G#, 12
	VNOTE G#, 12
	VNOTE G#, 6
	VNOTE G#, 3
	OCTAVE 2
	VNOTE G#, 6
	OCTAVE 3
	VNOTE G#, 6
	OCTAVE 4
	VNOTE G#, 6
	OCTAVE 5
	VNOTE G#, 6
	VNOTE G#, 6
	VNOTE G#, 6
	VNOTE G#, 3
	VNOTE G#, 3
	SND_END

SndC3_SfxN:
	NVOICE $81, $B0
	NOISE $30
	NVOICE $81, $E0
	NOISE $3C
	NOISE_VOL $0A
	NOISE $3D
	NOISE_VOL 6
	NOISE $3E
	NVOICE $81, $60
	NOISE $46
	SND_END

SndC4_Sfx1:
	VVOICE $01, $00, $08
	VREST 0
	VREST 0
	VREST 0
	OCTAVE 2
	VNOTE G#, 13
	OCTAVE 3
	VNOTE G#, 13
	OCTAVE 4
	VNOTE G#, 13
	OCTAVE 5
	VNOTE G#, 13
	VNOTE G#, 13
	VNOTE A_, 13
	VNOTE A#, 7
	VNOTE B_, 4
	OCTAVE 2
	VNOTE G#, 7
	OCTAVE 3
	VNOTE G#, 7
	OCTAVE 4
	VNOTE G#, 7
	OCTAVE 5
	VNOTE G#, 7
	VNOTE G#, 7
	VNOTE A_, 7
	VNOTE A#, 4
	VNOTE B_, 3
	SND_END

SndC4_SfxN:
	NVOICE $81, $B0
	NOISE $30
	NOISE_VOL $0F
	NOISE $34
	NOISE_VOL $0C
	NOISE $35
	NOISE_VOL 9
	NOISE $36
	NVOICE $81, $90
	NOISE $2F
	NOISE $2E
	NOISE $2F
	NOISE $2E
	NOISE $2F
	NOISE $2E
	NOISE_VOL 5
	NOISE $2F
	NOISE $2E
	NOISE $2F
	NOISE $2E
	SND_END

SndC5_Sfx1:
	VVOICE $01, $00, $08
	VREST 0
	VREST 0
	VREST 0
	OCTAVE 2
	VNOTE G#, 13
	OCTAVE 3
	VNOTE G#, 13
	OCTAVE 4
	VNOTE G#, 13
	OCTAVE 5
	VNOTE G#, 13
	VNOTE A_, 13
	OCTAVE 4
	VNOTE G#, 13
	VNOTE A_, 12
	VNOTE G#, 12
	VNOTE A_, 12
	VNOTE G#, 6
	VNOTE A_, 6
	VNOTE G#, 3
	VNOTE A_, 3
	OCTAVE 2
	VNOTE G#, 6
	OCTAVE 3
	VNOTE G#, 6
	OCTAVE 4
	VNOTE G#, 6
	OCTAVE 5
	VNOTE G#, 6
	VNOTE A_, 6
	OCTAVE 4
	VNOTE G#, 6
	VNOTE A_, 6
	VNOTE G#, 6
	VNOTE A_, 6
	VNOTE G#, 3
	VNOTE A_, 3
	VNOTE G#, 2
	VNOTE A_, 2
	SND_END

SndC5_SfxN:
	NVOICE $81, $F0
	NOISE $11
	NOISE_VOL $0C
	NOISE $13
	NOISE_VOL 8
	NOISE $16
	NVOICE $82, $A0
	NOISE $2F
	NOISE $0E
	NOISE $2F
	NOISE $0E
	NOISE $2F
	NOISE $0E
	NOISE_VOL 5
	NOISE $2F
	NOISE $0E
	NOISE $2F
	NOISE $0E
	SND_END

SndC6_Sfx1:
	VVOICE $01, $40, $2F
	VREST 0
	VREST 0
	VREST 0
	OCTAVE 2
	VNOTE G#, 11
	OCTAVE 3
	VNOTE G#, 11
	OCTAVE 4
	VNOTE G#, 11
	OCTAVE 5
	VNOTE G#, 10
	VNOTE A_, 10
	OCTAVE 6
	VNOTE G#, 9
	VNOTE A_, 9
	VNOTE A#, 9
	OCTAVE 5
	VNOTE G#, 9
	VNOTE A_, 9
	VNOTE A#, 9
	OCTAVE 4
	VNOTE G#, 9
	VNOTE A_, 9
	VNOTE A#, 9
	VNOTE G#, 9
	VNOTE A_, 9
	VNOTE A#, 9
	VNOTE G#, 5
	VNOTE A_, 5
	VNOTE A#, 5
	VNOTE G#, 3
	VNOTE A_, 3
	VNOTE A#, 3
	OCTAVE 6
	VNOTE G#, 3
	VNOTE A_, 3
	VNOTE A#, 3
	OCTAVE 5
	VNOTE G#, 3
	VNOTE A_, 3
	VNOTE A#, 3
	OCTAVE 4
	VNOTE G#, 3
	VNOTE A_, 3
	VNOTE A#, 3
	VNOTE G#, 3
	VNOTE A_, 3
	VNOTE A#, 3
	VNOTE G#, 2
	VNOTE A_, 2
	VNOTE A#, 1
	VNOTE G#, 1
	SND_END

SndC6_SfxN:
	NVOICE $81, $C0
	NOISE $30
	NOISE_VOL $0D
	NOISE $32
	NOISE_VOL $0A
	NOISE $33
	NOISE_VOL 9
	NOISE $34
	NVOICE $82, $80
	NOISE $2F
	NOISE $0E
	NOISE $2F
	NOISE $0E
	NOISE $2F
	NOISE $0E
	NOISE_VOL 4
	NOISE $0D
	NOISE $0C
	NOISE $0B
	NVOICE $82, $40
	NOISE $07
	NOISE $06
	NOISE $05
	NOISE $04
	NOISE $03
	NOISE $02
	NOISE $01
	NOISE $00
	SND_END

SndC7_Sfx1:
	VVOICE $01, $40, $08
	OCTAVE 6
	VNOTE G#, 11
	OCTAVE 5
	VNOTE G#, 11
	OCTAVE 4
	VNOTE G#, 11
	OCTAVE 3
	VNOTE G#, 11
	VVOICE $01, $40, $08
	OCTAVE 2
	VNOTE G#, 11
	OCTAVE 3
	VNOTE G#, 11
	OCTAVE 4
	VNOTE G#, 10
	OCTAVE 5
	VNOTE G#, 9
	VNOTE A_, 8
	OCTAVE 6
	VNOTE G#, 7
	VNOTE A_, 7
	VNOTE A#, 7
	VNOTE G#, 6
	VNOTE A_, 6
	VNOTE A#, 6
	VNOTE G#, 6
	VNOTE A_, 6
	VNOTE A#, 6
	VNOTE G#, 3
	VNOTE A_, 3
	VNOTE A#, 3
	VNOTE G#, 2
	VNOTE A_, 2
	VNOTE A#, 2
	OCTAVE 6
	VNOTE G#, 3
	VNOTE A_, 3
	VNOTE A#, 3
	VNOTE G#, 3
	VNOTE A_, 3
	VNOTE A#, 3
	VNOTE G#, 3
	VNOTE A_, 3
	VNOTE A#, 3
	VNOTE G#, 2
	VNOTE A_, 2
	VNOTE A#, 2
	VNOTE G#, 1
	VNOTE A_, 1
	VNOTE A#, 1
	SND_END

SndC7_SfxN:
	NVOICE $81, $B0
	NOISE $20
	NOISE_VOL $0E
	NOISE $22
	NOISE_VOL $0B
	NOISE $23
	NOISE_VOL 7
	NOISE $24
	NVOICE $82, $80
	NOISE $2D
	NOISE $1E
	NOISE $2D
	NOISE $1E
	NOISE $2D
	NOISE $1E
	NOISE_VOL 4
	NOISE $1D
	NOISE $1C
	NOISE $1B
	NVOICE $82, $40
	NOISE $17
	NOISE $16
	NOISE $15
	NOISE $14
	NOISE $13
	NOISE $12
	NOISE $11
	NOISE $10
	SND_END

SndC8_Sfx1:
	VVOICE $01, $00, $08
	OCTAVE 6
	VNOTE G_, 13
	VREST 0
	OCTAVE 2
	VNOTE D_, 13
	OCTAVE 6
	VNOTE D_, 13
	OCTAVE 2
	VNOTE G_, 13
	OCTAVE 5
	VNOTE G_, 13
	OCTAVE 3
	VNOTE D_, 13
	OCTAVE 5
	VNOTE D_, 12
	OCTAVE 3
	VNOTE G_, 12
	OCTAVE 4
	VNOTE G_, 8
	VNOTE D_, 8
	OCTAVE 3
	VNOTE G_, 7
	OCTAVE 4
	VNOTE G_, 6
	OCTAVE 3
	VNOTE D_, 5
	OCTAVE 5
	VNOTE D_, 4
	OCTAVE 2
	VNOTE G_, 3
	SND_END

SndC8_SfxN:
	NVOICE $81, $C0
	NOISE $3E
	NVOICE $81, $C0
	NOISE $00
	NVOICE $81, $C0
	NOISE $2F
	NOISE $1F
	NOISE $0F
	NVOICE $81, $C0
	NOISE $07
	NVOICE $83, $90
	NOISE $46
	NOISE $36
	NOISE $26
	NOISE $16
	NOISE_VOL 5
	NOISE $46
	NOISE $36
	NOISE $26
	NOISE $16
	SND_END

SndC9_SfxN:
	NVOICE $82, $B0
	NOISE $2F
	NOISE $1E
	NVOICE $82, $80
	NOISE $00
	NVOICE $82, $80
	NOISE $07
	NOISE $17
	NOISE $27
	NOISE $37
	SND_END

SndCA_Sfx1:
	VVOICE $01, $40, $08
	OCTAVE 5
	VNOTE D_, 12
	OCTAVE 4
	VNOTE A_, 10
	OCTAVE 5
	VNOTE C#, 9
	OCTAVE 4
	VNOTE A_, 8
	OCTAVE 5
	VNOTE C_, 8
	OCTAVE 4
	VNOTE A_, 8
	SND_END

SndCA_SfxN:
	NVOICE $04, $A0
	NOISE $3C
	NOISE_VOL 6
	NOISE $3D
	NOISE $2C
	NOISE $2D
	NOISE_VOL 4
	NOISE $1C
	NOISE $1D
	NOISE $0C
	NOISE $0D
	SND_END

SndCB_Sfx1:
	VVOICE $02, $00, $27
	OCTAVE 6
	VNOTE D_, 12
	OCTAVE 5
	VNOTE D_, 12
	VVOICE $02, $00, $08
	OCTAVE 4
	VNOTE D_, 11
	VNOTE F#, 11
	VNOTE A#, 11
	OCTAVE 5
	VNOTE D_, 11
	VNOTE F#, 11
	VNOTE A#, 11
	VNOTE A#, 10
	VNOTE F#, 9
	VNOTE D_, 7
	VNOTE A#, 7
	VNOTE F#, 4
	VNOTE D_, 4
	OCTAVE 4
	VNOTE D_, 6
	VNOTE F#, 6
	VNOTE A#, 6
	OCTAVE 5
	VNOTE D_, 6
	VNOTE F#, 6
	VNOTE A#, 6
	VNOTE A#, 4
	VNOTE F#, 4
	VNOTE D_, 3
	VNOTE A#, 3
	VNOTE F#, 2
	VNOTE D_, 2
	SND_END

SndCB_SfxN:
	NVOICE $81, $B0
	NOISE $3A
	NOISE $3B
	NOISE $4A
	NOISE $00
	NOISE_VOL 9
	NOISE $5F
	NOISE $4F
	NOISE $5E
	NOISE $3E
	NOISE $3D
	NOISE $3C
	NOISE $3B
	NOISE $3A
	NOISE $39
	NVOICE $81, $90
	NOISE $37
	NOISE $35
	NOISE $33
	NVOICE $81, $50
	NOISE $4F
	NOISE $4E
	NOISE $4D
	NOISE $4C
	NOISE $4B
	NOISE $4A
	NOISE_VOL 3
	NOISE $5F
	NOISE $5E
	NOISE $5D
	NOISE $5C
	NOISE $5B
	NOISE $5A
	SND_END

SndCC_Sfx1:
	VVOICE $01, $00, $08
	OCTAVE 6
	VNOTE G#, 15
	OCTAVE 5
	VNOTE G#, 15
	VVOICE $02, $00, $08
	OCTAVE 6
	VREST 0
	VNOTE A#, 15
	VNOTE A#, 9
	VNOTE A#, 5
	VVOICE $01, $00, $08
	VNOTE G#, 8
	OCTAVE 5
	VNOTE G#, 8
	VVOICE $02, $00, $08
	OCTAVE 6
	VREST 0
	VNOTE A#, 8
	VNOTE A#, 5
	VNOTE A#, 3
	VVOICE $01, $00, $08
	VNOTE G#, 4
	OCTAVE 5
	VNOTE G#, 4
	VVOICE $02, $00, $08
	OCTAVE 6
	VREST 0
	VNOTE A#, 4
	VNOTE A#, 2
	VNOTE A#, 1
	VVOICE $08, $40, $37
	OCTAVE 5
	VNOTE F_, 12
	VNOTE C#, 12
	OCTAVE 4
	VNOTE G_, 12
	VNOTE D#, 12
	OCTAVE 3
	VNOTE F_, 12
	VNOTE A#, 12
	OCTAVE 4
	VNOTE D#, 12
	VNOTE G#, 12
	VVOICE $05, $40, $37
	OCTAVE 5
	VNOTE F_, 7
	VNOTE C#, 7
	OCTAVE 4
	VNOTE G_, 7
	VNOTE D#, 7
	OCTAVE 3
	VNOTE F_, 7
	VNOTE A#, 7
	OCTAVE 4
	VNOTE D#, 7
	VNOTE G#, 7
	VVOICE $05, $40, $37
	OCTAVE 5
	VNOTE F_, 4
	VNOTE C#, 4
	OCTAVE 4
	VNOTE G_, 4
	VNOTE D#, 4
	OCTAVE 3
	VNOTE F_, 4
	VNOTE A#, 4
	OCTAVE 4
	VNOTE D#, 4
	VNOTE G#, 4
	SND_END

SndCC_SfxN:
	NVOICE $04, $F0
	NOISE $08
	NOISE $00
	NOISE $09
	NOISE_VOL 9
	NOISE $08
	NOISE_VOL 5
	NOISE $09
	NVOICE $04, $80
	NOISE $08
	NOISE $00
	NOISE $09
	NOISE_VOL 9
	NOISE $08
	NOISE_VOL 5
	NOISE $09
	NVOICE $04, $40
	NOISE $08
	NOISE $00
	NOISE $09
	NOISE_VOL 9
	NOISE $08
	NOISE_VOL 5
	NOISE $09
	NVOICE $02, $D0
	NOISE $00
	NOISE $03
	NOISE $05
	NVOICE $02, $D0
	NOISE $0F
	NOISE $0D
	NOISE $1E
	NOISE $1C
	NOISE $2D
	NOISE $2B
	NOISE $0F
	NOISE $1E
	NOISE $2D
	NOISE $3C
	NOISE $4B
	NOISE $5A
	NOISE $69
	NOISE $6A
	NOISE $6B
	NOISE $6C
	NOISE $6D
	NOISE $6E
	NOISE $6F
	NOISE_VOL 8
	NOISE $6A
	NOISE $6B
	NOISE $6C
	NOISE $6D
	NOISE $6E
	NOISE $6F
	NOISE_VOL $0A
	NOISE $0F
	NOISE $1E
	NOISE $2D
	NOISE $3C
	NOISE $4B
	NOISE $5A
	NOISE $69
	NOISE $6A
	NOISE $6B
	NOISE $6C
	NOISE $6D
	NOISE $6E
	NOISE $6F
	NOISE_VOL 8
	NOISE $6A
	NOISE $6B
	NOISE $6C
	NOISE $6D
	NOISE $6E
	NOISE $6F
	NOISE_VOL $0F
	NOISE $5F
	NOISE $5E
	NOISE $4F
	NOISE $4E
	NOISE $3F
	NOISE $3E
	NOISE $2F
	NOISE $2E
	NOISE $1F
	NOISE $1E
	NOISE_VOL 8
	NOISE $5D
	NOISE $5C
	NOISE $4D
	NOISE $4C
	NOISE $3D
	NOISE $3C
	NOISE $2D
	NOISE $2C
	NOISE $1D
	NOISE $1C
	NOISE_VOL 4
	NOISE $5B
	NOISE $5A
	NOISE $4B
	NOISE $4A
	NOISE $3B
	NOISE $3A
	NOISE $2B
	NOISE $2A
	NOISE $1B
	NOISE $1A
	SND_END

SndCD_Sfx1:
	VVOICE $02, $00, $17
	OCTAVE 5
	VNOTE C_, 13
	VREST 0
	OCTAVE 2
	VNOTE C_, 11
	VREST 0
	VNOTE D_, 10
	VREST 0
	OCTAVE 4
	VNOTE D_, 10
	VREST 0
	VNOTE E_, 10
	VREST 0
	OCTAVE 2
	VNOTE E_, 11
	VREST 0
	OCTAVE 3
	VNOTE F_, 10
	VREST 0
	OCTAVE 4
	VNOTE F_, 11
	OCTAVE 5
	VNOTE C_, 10
	VREST 0
	OCTAVE 3
	VNOTE C_, 10
	VREST 0
	OCTAVE 5
	VNOTE D_, 11
	VREST 0
	OCTAVE 4
	VNOTE D_, 12
	VREST 0
	VNOTE E_, 13
	VREST 0
	OCTAVE 5
	VNOTE E_, 14
	VVOICE $0F, $00, $4D
	VNOTE C_, 14
	VNOTE C_, 8
	VNOTE C_, 4
	SND_END

SndCD_SfxN:
	NVOICE $81, $F0
	NOISE $4B
	NVOICE $82, $A0
	NOISE $47
	NOISE $00
	NOISE $00
	NVOICE $81, $F0
	NOISE $59
	NVOICE $82, $A0
	NOISE $47
	NOISE $00
	NOISE $00
	NVOICE $81, $F0
	NOISE $4B
	NVOICE $82, $A0
	NOISE $47
	NOISE $00
	NOISE $00
	NVOICE $81, $F0
	NOISE $17
	NVOICE $82, $A0
	NOISE $27
	NOISE $37
	NOISE $47
	NVOICE $81, $F0
	NOISE $17
	NVOICE $82, $A0
	NOISE $27
	NOISE $37
	NOISE $47
	NOISE $00
	NVOICE $81, $F0
	NOISE $3C
	NVOICE $82, $A0
	NOISE $33
	NOISE $23
	NOISE $00
	NOISE $00
	NVOICE $81, $F0
	NOISE $4A
	NVOICE $82, $A0
	NOISE $47
	NOISE $00
	NOISE $00
	NVOICE $81, $F0
	NOISE $00
	NOISE $3B
	NVOICE $82, $A0
	NOISE $40
	NOISE $30
	SND_END

SndCE_Sfx1:
	VVOICE $04, $00, $36
	OCTAVE 5
	VNOTE C_, 15
	VVOICE $01, $00, $08
	OCTAVE 5
	VNOTE C_, 15
	VNOTE C#, 15
	VNOTE C_, 15
	VNOTE C#, 15
	VNOTE C_, 15
	VNOTE C#, 15
	VNOTE C_, 15
	VNOTE C#, 15
	VNOTE C_, 15
	VNOTE C#, 15
	VNOTE C_, 15
	VNOTE C#, 15
	VNOTE C_, 14
	VNOTE C_, 12
	OCTAVE 4
	VNOTE B_, 8
	VNOTE A#, 4
	VREST 0
	VREST 0
	VREST 0
	VVOICE $04, $00, $25
	OCTAVE 5
	VNOTE D_, 15
	VVOICE $04, $04, $36
	OCTAVE 4
	VNOTE A#, 15
	VVOICE $01, $00, $08
	VNOTE A#, 15
	VNOTE B_, 15
	VNOTE A#, 15
	VNOTE B_, 15
	VNOTE A#, 15
	VNOTE B_, 15
	VNOTE A#, 15
	VNOTE B_, 15
	VNOTE A#, 14
	VNOTE B_, 12
	VNOTE A#, 8
	VNOTE A_, 4
	VREST 0
	VVOICE $04, $00, $25
	OCTAVE 5
	VNOTE D_, 12
	VVOICE $04, $04, $36
	OCTAVE 4
	VNOTE A_, 12
	VVOICE $01, $00, $08
	VNOTE A_, 12
	VNOTE A#, 12
	VNOTE A_, 12
	VNOTE A#, 12
	VNOTE A_, 12
	VNOTE A#, 12
	VREST 0
	VVOICE $04, $00, $25
	OCTAVE 5
	VNOTE D_, 9
	VVOICE $04, $04, $36
	OCTAVE 4
	VNOTE G#, 9
	VVOICE $01, $00, $08
	VNOTE G#, 9
	VNOTE A_, 9
	VNOTE G#, 9
	VNOTE A_, 9
	VNOTE A#, 9
	VREST 0
	VVOICE $04, $00, $25
	OCTAVE 5
	VNOTE D_, 7
	VVOICE $04, $00, $36
	OCTAVE 4
	VNOTE F_, 7
	VVOICE $01, $00, $08
	VNOTE G_, 7
	VNOTE G#, 7
	VNOTE A_, 7
	VNOTE G#, 7
	VREST 0
	VVOICE $04, $00, $25
	OCTAVE 5
	VNOTE D_, 4
	VVOICE $04, $00, $36
	VNOTE E_, 4
	VVOICE $01, $00, $08
	VNOTE F#, 4
	VNOTE G_, 4
	VNOTE G#, 4
	VNOTE G_, 4
	SND_END

SndCE_SfxN:
	NVOICE $02, $B0
	NOISE $07
	NOISE $03
	NOISE $13
	NOISE $23
	NOISE $33
	NOISE $43
	NOISE $53
	NOISE $63
	NOISE $64
	NOISE $54
	NOISE $55
	NOISE $44
	NOISE $45
	NOISE $34
	NOISE $35
	NOISE $24
	NOISE $25
	NOISE $14
	NOISE $15
	NOISE $04
	NOISE_VOL 7
	NOISE $63
	NOISE $53
	NOISE $54
	NOISE $43
	NOISE $44
	NOISE $33
	NOISE $34
	NOISE $23
	NOISE $24
	NOISE $13
	NOISE $14
	NOISE $03
	NOISE_VOL 5
	NOISE $62
	NOISE $52
	NOISE $53
	NOISE $42
	NOISE $43
	NOISE $32
	NOISE $33
	NOISE $22
	NOISE $23
	NOISE $12
	NOISE $13
	NOISE $02
	NOISE_VOL 3
	NOISE $61
	NOISE $51
	NOISE $52
	NOISE $41
	NOISE $42
	NOISE $31
	NOISE $32
	NOISE $21
	NOISE $22
	NOISE $11
	NOISE $12
	NOISE $01
	SND_END

SndCF_Sfx1:
	SND_SEGNO
	VVOICE $01, $00, $08
	VREST 0
	VREST 0
	VREST 0
	OCTAVE 4
	VNOTE F_, 6
	DUTY 4
	VNOTE F#, 6
	DUTY 0
	VNOTE G_, 6
	VNOTE F_, 3
	DUTY 4
	VNOTE F#, 3
	DUTY 0
	VNOTE G_, 3
	OCTAVE 4
	VNOTE A_, 12
	VNOTE A_, 12
	DUTY 4
	VNOTE A#, 12
	DUTY 0
	VNOTE B_, 12
	OCTAVE 5
	DUTY 4
	VNOTE C_, 12
	VNOTE C_, 12
	VNOTE C#, 12
	VNOTE C_, 12
	VNOTE C#, 12
	VNOTE C_, 12
	VNOTE C#, 12
	VNOTE C_, 12
	VNOTE C#, 12
	DUTY 0
	VNOTE C_, 12
	OCTAVE 4
	VNOTE B_, 12
	VNOTE A#, 10
	VNOTE A_, 7
	VNOTE G#, 4
	OCTAVE 5
	DUTY 4
	VNOTE C_, 5
	VNOTE C_, 5
	VNOTE C#, 5
	VNOTE C_, 5
	VNOTE C#, 5
	VNOTE C_, 5
	VNOTE C#, 5
	VNOTE C_, 5
	VNOTE C#, 5
	DUTY 0
	VNOTE C_, 5
	OCTAVE 4
	VNOTE B_, 5
	VNOTE A#, 10
	VNOTE A_, 4
	VNOTE G#, 3
	VVOICE $0F, $00, $08
	VREST 0
	VREST 0
	VREST 0
	LOOP_START
	VVOICE $01, $00, $08
	OCTAVE 4
	VNOTE F_, 5
	DUTY 4
	VNOTE F#, 5
	DUTY 0
	VNOTE G_, 5
	VNOTE F_, 3
	DUTY 4
	VNOTE F#, 3
	DUTY 0
	VNOTE G_, 3
	VREST 0
	VREST 0
	VREST 0
	LOOP_END $03
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VNOTE F_, 4
	DUTY 4
	VNOTE F#, 4
	DUTY 0
	VNOTE G_, 4
	VNOTE F_, 3
	DUTY 4
	VNOTE F#, 3
	DUTY 0
	VNOTE G_, 3
	VREST 0
	VREST 0
	OCTAVE 2
	VNOTE A_, 6
	DUTY 4
	VNOTE A_, 8
	DUTY 0
	VNOTE A_, 10
	VNOTE A_, 11
	VNOTE A_, 11
	VNOTE A_, 11
	VNOTE G#, 12
	DUTY 4
	VNOTE G_, 9
	DUTY 0
	VNOTE F#, 6
	VNOTE A_, 3
	DUTY 4
	VNOTE A_, 4
	DUTY 0
	VNOTE A_, 6
	VNOTE A_, 7
	VNOTE A_, 7
	VNOTE A_, 7
	VNOTE G#, 6
	DUTY 4
	VNOTE G_, 4
	DUTY 0
	VNOTE F#, 3
	VVOICE $01, $00, $27
	OCTAVE 5
	VNOTE D#, 12
	VNOTE E_, 12
	VNOTE F_, 12
	VNOTE F#, 12
	VNOTE G_, 12
	VNOTE G_, 12
	VNOTE G#, 12
	VNOTE G_, 12
	VNOTE G#, 11
	VNOTE G_, 9
	VNOTE G#, 7
	VNOTE G_, 5
	VNOTE D#, 6
	VNOTE E_, 6
	VNOTE F_, 6
	VNOTE F#, 6
	VNOTE G_, 6
	VNOTE G_, 6
	VNOTE G#, 6
	VNOTE G_, 6
	VNOTE G#, 5
	VNOTE G_, 4
	VNOTE G#, 3
	VNOTE G_, 2
	VVOICE $07, $00, $27
	VREST 0
	VREST 0
	VREST 0
	VVOICE $01, $00, $27
	OCTAVE 5
	VNOTE D_, 6
	VNOTE F_, 7
	VNOTE F#, 7
	VNOTE G_, 7
	VNOTE G#, 7
	VNOTE G#, 6
	VNOTE A_, 6
	VNOTE G#, 6
	VNOTE A_, 5
	VNOTE G#, 4
	VNOTE A_, 3
	VNOTE G#, 2
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	OCTAVE 3
	VNOTE G_, 6
	DUTY 8
	VNOTE G_, 8
	VNOTE G_, 10
	VNOTE G_, 11
	VNOTE G_, 11
	VNOTE F#, 11
	VNOTE F_, 12
	VNOTE E_, 9
	VNOTE D#, 6
	VNOTE G_, 3
	VNOTE G_, 4
	VNOTE G_, 6
	VNOTE G_, 7
	VNOTE G_, 7
	VNOTE F#, 7
	VNOTE F_, 6
	VNOTE E_, 4
	VNOTE D#, 3
	VVOICE $01, $00, $08
	OCTAVE 4
	VNOTE A_, 9
	VNOTE A_, 9
	DUTY 4
	VNOTE A#, 9
	DUTY 0
	VNOTE B_, 9
	OCTAVE 5
	DUTY 4
	VNOTE C_, 9
	VNOTE C_, 9
	VNOTE C#, 9
	VNOTE C_, 9
	VNOTE C#, 9
	VNOTE C_, 9
	VNOTE C#, 9
	VNOTE C_, 9
	VNOTE C#, 9
	DUTY 0
	VNOTE C_, 9
	OCTAVE 4
	VNOTE B_, 9
	VNOTE A#, 7
	VNOTE A_, 6
	VNOTE G#, 4
	OCTAVE 5
	DUTY 4
	VNOTE C_, 5
	VNOTE C_, 5
	VNOTE C#, 5
	VNOTE C_, 5
	VNOTE C#, 5
	VNOTE C_, 5
	VNOTE C#, 5
	VNOTE C_, 5
	VNOTE C#, 5
	DUTY 0
	VNOTE C_, 5
	OCTAVE 4
	VNOTE B_, 5
	VNOTE A#, 10
	VNOTE A_, 4
	VNOTE G#, 3
	VVOICE $07, $00, $27
	VREST 0
	VREST 0
	VVOICE $01, $00, $08
	OCTAVE 2
	VNOTE F_, 6
	VNOTE E_, 6
	OCTAVE 3
	VNOTE F#, 7
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G_, 8
	VNOTE F#, 6
	OCTAVE 3
	VNOTE G#, 6
	VNOTE G_, 6
	OCTAVE 2
	VNOTE A_, 3
	VNOTE G#, 3
	VREST 0
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G#, 6
	OCTAVE 2
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G#, 6
	OCTAVE 2
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G#, 6
	OCTAVE 2
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G#, 6
	VNOTE F_, 4
	OCTAVE 4
	VNOTE G#, 4
	OCTAVE 2
	VNOTE F_, 4
	OCTAVE 4
	VNOTE G#, 4
	OCTAVE 2
	VNOTE F_, 4
	OCTAVE 4
	VNOTE G#, 4
	OCTAVE 2
	VNOTE F_, 4
	OCTAVE 4
	VNOTE G#, 4
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VNOTE F_, 6
	VNOTE E_, 6
	OCTAVE 3
	VNOTE F#, 7
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G_, 8
	VNOTE F#, 6
	OCTAVE 3
	VNOTE G#, 6
	VNOTE G_, 6
	OCTAVE 2
	VNOTE A_, 3
	VNOTE G#, 3
	VREST 0
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G#, 6
	OCTAVE 2
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G#, 6
	OCTAVE 2
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G#, 6
	OCTAVE 2
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G#, 6
	VNOTE F_, 4
	OCTAVE 4
	VNOTE G#, 4
	OCTAVE 2
	VNOTE F_, 4
	OCTAVE 4
	VNOTE G#, 4
	OCTAVE 2
	VNOTE F_, 4
	OCTAVE 4
	VNOTE G#, 4
	OCTAVE 2
	VNOTE F_, 4
	OCTAVE 4
	VNOTE G#, 4
	LOOP_START
	OCTAVE 4
	VNOTE F_, 5
	DUTY 4
	VNOTE F#, 5
	DUTY 0
	VNOTE G_, 5
	VNOTE F_, 3
	DUTY 4
	VNOTE F#, 3
	DUTY 0
	VNOTE G_, 3
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	LOOP_END $02
	VVOICE $0E, $00, $08
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	SND_LOOP

SndCF_SfxN:
	NVOICE $07, $10
	NOISE $50
	NOISE_VOL 2
	NOISE $50
	NOISE $50
	NOISE_VOL 3
	NOISE $50
	NOISE_VOL 4
	NOISE $50
	LOOP_START
	NOISE $50
	LOOP_END $0D
	NVOICE $01, $50
	NOISE $54
	NOISE $44
	NOISE $24
	NOISE $00
	NOISE_VOL 5
	NOISE $53
	NOISE $43
	NOISE_VOL 7
	NOISE $21
	NOISE $16
	NOISE_VOL 9
	NOISE $26
	NOISE $46
	NOISE $66
	NOISE $00
	NOISE_VOL 5
	NOISE $54
	NOISE $44
	NOISE $24
	NOISE $17
	NOISE $27
	NOISE $47
	NOISE_VOL 8
	NOISE $53
	NOISE $41
	NOISE $16
	NOISE $26
	NOISE $46
	NOISE $00
	NOISE_VOL 4
	NOISE $53
	NOISE $43
	NOISE $33
	NOISE $27
	NOISE $37
	NOISE_VOL 3
	NOISE $53
	NOISE $41
	NOISE $16
	NOISE $26
	NOISE $46
	NOISE $00
	NOISE_VOL 2
	NOISE $54
	NOISE $44
	NOISE $24
	NOISE $17
	NOISE $27
	NVOICE $08, $10
	NOISE $50
	NOISE_VOL 2
	NOISE $50
	NOISE $50
	NOISE_VOL 3
	NOISE $50
	NOISE_VOL 4
	NOISE $50
	SND_SEGNO
	NOISE $50
	SND_LOOP
	db $FF ; unreachable end

SndD0_Sfx1:
	VVOICE $02, $80, $08
	OCTAVE 2
	VNOTE G_, 14
	VNOTE D_, 14
	VVOICE $01, $80, $08
	VREST 0
	VVOICE $02, $80, $08
	OCTAVE 4
	VNOTE G_, 14
	VNOTE D_, 8
	VNOTE D_, 4
	OCTAVE 2
	VNOTE G_, 8
	VNOTE D_, 8
	VREST 0
	OCTAVE 4
	VNOTE G_, 8
	VNOTE D_, 4
	VNOTE D_, 2
	OCTAVE 2
	VNOTE G_, 4
	VNOTE D_, 4
	VREST 0
	OCTAVE 4
	VNOTE G_, 4
	VNOTE D_, 2
	VNOTE D_, 1
	SND_END

SndD0_SfxN:
	NVOICE $02, $F0
	NOISE $59
	NOISE $22
	NVOICE $01, $F0
	NOISE $00
	NVOICE $02, $F0
	NOISE $69
	NVOICE $02, $F0
	NOISE $6B
	NOISE $00
	NVOICE $03, $B0
	NOISE $5A
	NOISE $5B
	NOISE $5C
	NOISE $5D
	NOISE $5E
	NOISE $5F
	NOISE_VOL 7
	NOISE $6A
	NOISE $6B
	NOISE $6C
	NOISE $6D
	NOISE $6E
	NOISE $6F
	SND_END

SndD1_Sfx1:
	SND_SEGNO
	VVOICE $0F, $00, $08
	VREST 0
	VVOICE $01, $00, $08
	OCTAVE 6
	VNOTE F#, 11
	VNOTE F_, 11
	VNOTE E_, 10
	VNOTE D#, 9
	VNOTE D_, 8
	VREST 0
	VNOTE F#, 7
	VNOTE F_, 7
	VNOTE E_, 6
	VNOTE D#, 5
	VNOTE D_, 4
	VVOICE $15, $00, $08
	VREST 0
	VVOICE $01, $00, $08
	VNOTE F#, 6
	VNOTE F_, 6
	VNOTE E_, 5
	VNOTE D#, 4
	VNOTE D_, 3
	VREST 0
	VNOTE F#, 4
	VNOTE F_, 4
	VNOTE E_, 3
	VNOTE D#, 2
	VNOTE D_, 1
	VVOICE $08, $00, $08
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VVOICE $01, $00, $08
	VNOTE D#, 11
	VNOTE D_, 11
	VNOTE C#, 10
	VNOTE C_, 9
	OCTAVE 5
	VNOTE B_, 8
	VREST 0
	VNOTE D#, 7
	VNOTE D_, 7
	VNOTE C#, 6
	VNOTE C_, 5
	OCTAVE 5
	VNOTE B_, 4
	VVOICE $2F, $00, $08
	VREST 0
	VREST 0
	VVOICE $01, $00, $08
	OCTAVE 6
	VNOTE D#, 11
	VNOTE D_, 11
	VNOTE C#, 10
	VNOTE C_, 9
	VREST 0
	VNOTE D#, 11
	VNOTE D_, 11
	VNOTE C#, 10
	VNOTE C_, 9
	OCTAVE 5
	VNOTE B_, 8
	VREST 0
	OCTAVE 6
	VNOTE D#, 7
	VNOTE D_, 7
	VNOTE C#, 6
	VNOTE C_, 5
	OCTAVE 5
	VNOTE B_, 4
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	OCTAVE 6
	VNOTE D#, 9
	VNOTE D_, 9
	VNOTE C#, 8
	VNOTE C_, 7
	OCTAVE 5
	VNOTE B_, 4
	VREST 0
	OCTAVE 6
	VNOTE D#, 5
	VNOTE D_, 5
	VNOTE C#, 4
	VNOTE C_, 3
	OCTAVE 5
	VNOTE B_, 2
	VVOICE $4F, $00, $08
	VREST 0
	SND_LOOP

SndD1_SfxN:
	SND_SEGNO
	NVOICE $03, $20
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE_VOL 4
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE_VOL 5
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE_VOL 6
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE_VOL 8
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE_VOL 9
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE_VOL $0A
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE_VOL 9
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE_VOL 7
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE_VOL 5
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE_VOL 3
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE_VOL 2
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE_VOL 1
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $26
	NOISE $26
	NOISE $36
	NOISE $36
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE_VOL 4
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE_VOL 5
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE_VOL 6
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE_VOL 8
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE_VOL 9
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE_VOL 7
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE_VOL 5
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE_VOL 3
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE_VOL 2
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE_VOL 1
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $55
	NOISE $56
	NOISE $57
	NOISE $57
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE_VOL 4
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE_VOL 5
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE_VOL 6
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE_VOL 8
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE_VOL 9
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE_VOL $0A
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE_VOL 9
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE_VOL 7
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE_VOL 5
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE_VOL 3
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE $16
	NOISE_VOL 2
	NOISE $16
	NOISE $26
	NOISE $36
	NOISE $46
	NOISE $56
	NOISE_VOL 3
	NOISE $55
	NOISE $46
	NOISE_VOL 5
	NOISE $45
	NOISE $36
	NOISE_VOL 7
	NOISE $35
	NOISE $36
	NOISE $37
	NOISE $47
	NOISE $57
	NOISE $37
	NOISE $27
	NOISE $25
	NOISE $25
	NOISE $25
	NOISE $25
	NOISE $24
	NOISE $24
	NOISE $23
	NOISE $23
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	NOISE $27
	NOISE_VOL 4
	NOISE $43
	NOISE $43
	NOISE $44
	NOISE $44
	NOISE $44
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $46
	NOISE $46
	NOISE $46
	NOISE $47
	NOISE $47
	NOISE_VOL 2
	NOISE $53
	NOISE $53
	NOISE $54
	NOISE $54
	NOISE $54
	NOISE $55
	NOISE $55
	NOISE $55
	NOISE $55
	NOISE_VOL 1
	NOISE $56
	NOISE $56
	NOISE $56
	NOISE $57
	NOISE $57
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE_VOL 4
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE_VOL 5
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE_VOL 6
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE_VOL 8
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE_VOL 9
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE_VOL 7
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE_VOL 5
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE_VOL 3
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE_VOL 2
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE_VOL 1
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $45
	NOISE $55
	NOISE $56
	NOISE $57
	NOISE $57
	SND_LOOP

SndD2_Sfx1:
	VVOICE $02, $80, $00
	OCTAVE 6
	VNOTE C_, 11
	OCTAVE 4
	VNOTE D#, 11
	OCTAVE 6
	VNOTE D#, 11
	OCTAVE 4
	VNOTE F_, 11
	OCTAVE 6
	VNOTE F_, 11
	OCTAVE 4
	VNOTE G#, 11
	OCTAVE 6
	VNOTE G#, 11
	OCTAVE 4
	VNOTE C#, 11
	OCTAVE 6
	VNOTE C#, 11
	OCTAVE 4
	VNOTE E_, 11
	OCTAVE 6
	VNOTE E_, 11
	OCTAVE 4
	VNOTE F#, 11
	OCTAVE 6
	VNOTE F#, 11
	OCTAVE 4
	VNOTE A_, 11
	OCTAVE 6
	VNOTE A_, 11
	OCTAVE 4
	VNOTE F_, 11
	OCTAVE 6
	VNOTE F_, 11
	OCTAVE 4
	VNOTE G#, 11
	OCTAVE 6
	VNOTE G#, 11
	OCTAVE 4
	VNOTE A#, 11
	OCTAVE 6
	VNOTE A#, 11
	OCTAVE 5
	VNOTE C#, 11
	OCTAVE 6
	VNOTE C#, 11
	OCTAVE 4
	VNOTE F#, 11
	OCTAVE 6
	VNOTE F#, 11
	OCTAVE 4
	VNOTE A_, 11
	OCTAVE 6
	VNOTE A_, 11
	OCTAVE 4
	VNOTE B_, 11
	OCTAVE 6
	VNOTE B_, 11
	OCTAVE 5
	VNOTE D_, 11
	OCTAVE 6
	VNOTE D_, 11
	OCTAVE 4
	VNOTE F_, 6
	OCTAVE 6
	VNOTE F_, 6
	OCTAVE 4
	VNOTE G#, 6
	OCTAVE 6
	VNOTE G#, 6
	OCTAVE 4
	VNOTE A#, 6
	OCTAVE 6
	VNOTE A#, 6
	OCTAVE 5
	VNOTE C#, 6
	OCTAVE 6
	VNOTE C#, 6
	OCTAVE 4
	VNOTE F#, 3
	OCTAVE 6
	VNOTE F#, 3
	OCTAVE 4
	VNOTE A_, 3
	OCTAVE 6
	VNOTE A_, 3
	OCTAVE 4
	VNOTE B_, 3
	OCTAVE 6
	VNOTE B_, 3
	OCTAVE 5
	VNOTE D_, 3
	OCTAVE 6
	VNOTE D_, 3
	OCTAVE 4
	VNOTE F#, 2
	OCTAVE 6
	VNOTE F#, 2
	OCTAVE 4
	VNOTE A_, 2
	OCTAVE 6
	VNOTE A_, 2
	OCTAVE 4
	VNOTE B_, 1
	OCTAVE 6
	VNOTE B_, 1
	OCTAVE 5
	VNOTE D_, 1
	OCTAVE 6
	VNOTE D_, 1
	SND_END

SndD2_SfxN:
	NVOICE $02, $C0
	NOISE $5B
	NOISE $4A
	NVOICE $02, $C0
	NOISE $39
	NVOICE $02, $C0
	NOISE $28
	NVOICE $02, $C0
	NOISE $27
	NOISE $26
	NOISE $25
	NOISE $24
	NOISE $23
	NOISE $22
	NOISE $21
	NOISE $20
	NOISE $31
	NOISE $32
	NOISE $33
	NOISE $43
	NOISE $53
	NOISE $63
	NOISE_VOL 7
	NOISE $27
	NOISE $26
	NOISE $25
	NOISE $24
	NOISE $23
	NOISE $22
	NOISE $21
	NOISE $20
	NOISE $31
	NOISE $32
	NOISE $33
	NOISE $43
	NOISE $53
	NOISE $63
	NOISE_VOL 4
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $33
	NOISE $32
	NOISE $31
	NOISE $30
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $53
	NOISE $63
	NOISE $73
	NOISE_VOL 2
	NOISE $63
	NOISE $53
	NOISE $64
	NOISE $54
	NOISE $65
	NOISE $55
	NOISE $66
	NOISE $56
	NOISE $67
	NOISE $57
	SND_END

SndD3_Sfx1:
	VVOICE $02, $00, $00
	OCTAVE 4
	VNOTE F_, 12
	VNOTE D_, 12
	VREST 0
	OCTAVE 6
	VNOTE D_, 12
	OCTAVE 5
	VREST 0
	VNOTE A_, 12
	OCTAVE 6
	VNOTE C#, 12
	OCTAVE 5
	VNOTE A_, 12
	VNOTE F_, 12
	VNOTE A_, 12
	VNOTE D_, 12
	OCTAVE 4
	VNOTE F_, 6
	VNOTE D_, 6
	VREST 0
	OCTAVE 6
	VNOTE D_, 6
	OCTAVE 5
	VREST 0
	VNOTE A_, 6
	OCTAVE 6
	VNOTE C#, 6
	OCTAVE 5
	VNOTE A_, 6
	VNOTE F_, 6
	VNOTE A_, 6
	VNOTE D_, 6
	OCTAVE 4
	VNOTE F_, 3
	VNOTE D_, 3
	VREST 0
	OCTAVE 6
	VNOTE D_, 3
	OCTAVE 5
	VREST 0
	VNOTE A_, 3
	OCTAVE 6
	VNOTE C#, 3
	OCTAVE 5
	VNOTE A_, 3
	VNOTE F_, 3
	VNOTE A_, 3
	VNOTE D_, 3
	SND_END

SndD3_Sfx2:
	VVOICE $3D, $00, $00
	VREST 0
	VVOICE $10, $00, $08
	INSTRUMENT $07
	OCTAVE 1
	VNOTE F_, 6
	VNOTE F_, 4
	VVOICE $50, $00, $08
	INSTRUMENT $07
	LOOP_START
	OCTAVE 1
	VNOTE F_, 2
	LOOP_END $04
	VVOICE $10, $00, $08
	INSTRUMENT $07
	OCTAVE 1
	VNOTE F_, 4
	VNOTE F_, 6
	INSTRUMENT $00
	SND_END

SndD3_SfxN:
	NVOICE $02, $F0
	NOISE $4C
	NVOICE $02, $F0
	NOISE $44
	NVOICE $02, $F0
	NOISE $00
	NVOICE $02, $F0
	NOISE $25
	NVOICE $02, $F0
	NOISE $00
	NVOICE $02, $F0
	NOISE $45
	NOISE $46
	NVOICE $02, $F0
	NOISE $3B
	NOISE $3C
	NOISE $4D
	NOISE $4D
	NVOICE $03, $80
	NOISE $23
	NVOICE $03, $80
	NOISE $2B
	NOISE $2C
	NOISE $3D
	NOISE $3E
	NOISE $4E
	NOISE $4E
	NOISE $4F
	NOISE_VOL $0A
	NOISE $4C
	NOISE $4C
	NOISE $5C
	NOISE $5D
	NOISE $6D
	NOISE $6D
	NOISE $6E
	NOISE $6F
	NOISE $7F
	NOISE_VOL $0C
	NOISE $7E
	NOISE $7D
	NOISE $7C
	NOISE $7B
	NOISE $7A
	NOISE $7B
	NOISE $7A
	NOISE $7B
	NOISE $7C
	SND_END

SndD4_Sfx1:
	VVOICE $08, $80, $37
	OCTAVE 5
	VNOTE G_, 14
	VVOICE $0D, $80, $5F
	VNOTE G_, 14
	OCTAVE 4
	VNOTE G_, 14
	VVOICE $08, $80, $37
	OCTAVE 5
	VNOTE D_, 9
	VVOICE $0D, $80, $5F
	VNOTE D_, 9
	OCTAVE 4
	VNOTE D_, 9
	VVOICE $08, $80, $37
	OCTAVE 4
	VNOTE A_, 7
	VVOICE $0D, $80, $5F
	VNOTE A_, 7
	OCTAVE 3
	VNOTE A_, 7
	VVOICE $06, $80, $5F
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VREST 0
	VVOICE $02, $80, $55
	OCTAVE 4
	VNOTE G_, 13
	VNOTE G_, 7
	VNOTE G#, 4
	VNOTE G_, 8
	VNOTE G_, 4
	VNOTE G#, 2
	SND_END

SndD4_Sfx2:
	VVOICE $08, $80, $08
	VREST 0
	SND_END

SndD4_SfxN:
	NVOICE $02, $90
	NOISE $50
	NOISE $40
	NOISE $30
	NOISE $20
	NOISE $10
	NOISE $11
	NOISE $12
	NOISE $13
	NOISE $14
	NOISE $15
	NOISE $16
	NOISE $17
	NOISE $27
	NOISE $37
	NOISE $47
	NOISE $57
	NOISE $56
	NOISE $55
	NOISE $54
	NOISE $53
	NOISE $52
	NOISE $51
	NOISE $41
	NOISE $31
	NOISE $21
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	NOISE $36
	NOISE $46
	NOISE $45
	NOISE $44
	NOISE $43
	NOISE $42
	NOISE $41
	NOISE $40
	NOISE_VOL 6
	NOISE $55
	NOISE $54
	NOISE $53
	NOISE $52
	NOISE $51
	NOISE $50
	NOISE_VOL 3
	NOISE $65
	NOISE $64
	NOISE $63
	NOISE $62
	NOISE $61
	NOISE $60
	NOISE $00
	NVOICE $06, $90
	NOISE $00
	NOISE $00
	NOISE $00
	NOISE $00
	NVOICE $01, $D0
	NOISE $00
	NOISE $30
	NOISE $50
	SND_END

SndD5_SfxN:
	NVOICE $01, $C0
	NOISE $72
	NOISE $63
	NOISE $54
	NOISE $45
	NOISE $36
	NOISE $27
	NOISE $00
	LOOP_START
	NOISE $70
	NOISE $60
	NOISE $50
	NOISE $41
	NOISE $32
	NOISE $23
	NOISE $14
	NOISE $05
	NOISE $00
	LOOP_END $04
	NOISE_VOL 9
	NOISE $70
	NOISE $60
	NOISE $51
	NOISE $42
	NOISE $33
	NOISE $24
	NOISE $15
	NOISE $06
	NOISE $00
	NOISE_VOL 6
	NOISE $70
	NOISE $61
	NOISE $52
	NOISE $43
	NOISE $34
	NOISE $25
	NOISE $16
	NOISE $07
	NOISE $00
	NOISE_VOL 3
	NOISE $71
	NOISE $62
	NOISE $53
	NOISE $44
	NOISE $35
	NOISE $26
	NOISE $17
	NOISE $07
	NOISE $00
	NOISE_VOL 2
	NOISE $72
	NOISE $63
	NOISE $54
	NOISE $45
	NOISE $36
	NOISE $27
	NOISE $17
	NOISE_VOL 1
	NOISE $73
	NOISE $64
	NOISE $55
	NOISE $46
	NOISE $37
	NOISE $27
	SND_END

SndD6_Sfx1:
	VVOICE $02, $00, $1E
	OCTAVE 6
	VNOTE E_, 13
	VNOTE D_, 13
	VREST 0
	OCTAVE 5
	VNOTE A_, 13
	VNOTE D_, 13
	VREST 0
	VNOTE A_, 13
	VNOTE C_, 13
	OCTAVE 4
	VNOTE A_, 13
	VNOTE E_, 13
	VNOTE A_, 13
	VNOTE D_, 13
	OCTAVE 6
	VNOTE E_, 7
	VNOTE D_, 7
	VREST 0
	OCTAVE 5
	VNOTE A_, 7
	VNOTE D_, 7
	VREST 0
	VNOTE A_, 7
	VNOTE C_, 7
	OCTAVE 4
	VNOTE A_, 7
	VNOTE E_, 7
	VNOTE A_, 7
	VNOTE D_, 7
	OCTAVE 6
	VNOTE E_, 4
	VNOTE D_, 4
	VREST 0
	OCTAVE 5
	VNOTE A_, 4
	VNOTE D_, 4
	VREST 0
	VNOTE A_, 4
	VNOTE C_, 4
	OCTAVE 4
	VNOTE A_, 4
	VNOTE E_, 4
	VNOTE A_, 4
	VNOTE D_, 4
	SND_END

SndD6_Sfx2:
	VVOICE $02, $30, $00
	OCTAVE 6
	VNOTE D#, 2
	VNOTE C#, 2
	VREST 0
	OCTAVE 5
	VNOTE G#, 2
	VNOTE C#, 2
	VREST 0
	VNOTE G#, 2
	OCTAVE 4
	VNOTE B_, 2
	VNOTE G#, 2
	VNOTE D#, 2
	VNOTE G#, 2
	VNOTE C#, 2
	OCTAVE 6
	VNOTE D#, 4
	VNOTE C#, 4
	VREST 0
	OCTAVE 5
	VNOTE G#, 4
	VNOTE C#, 4
	VREST 0
	VNOTE G#, 4
	OCTAVE 4
	VNOTE B_, 4
	VNOTE G#, 4
	VNOTE D#, 4
	VNOTE G#, 4
	VNOTE C#, 4
	OCTAVE 6
	VNOTE D#, 6
	VNOTE C#, 6
	VREST 0
	OCTAVE 5
	VNOTE G#, 6
	VNOTE C#, 6
	VREST 0
	VNOTE G#, 6
	OCTAVE 4
	VNOTE B_, 6
	VNOTE G#, 6
	VNOTE D#, 6
	VNOTE G#, 6
	VNOTE C#, 6
	OCTAVE 6
	VNOTE D#, 2
	VNOTE C#, 2
	VREST 0
	OCTAVE 5
	VNOTE G#, 2
	VNOTE C#, 2
	VREST 0
	VNOTE G#, 2
	OCTAVE 4
	VNOTE B_, 2
	VNOTE G#, 2
	VNOTE D#, 2
	VNOTE G#, 2
	VNOTE C#, 2
	OCTAVE 6
	VNOTE D#, 4
	VNOTE C#, 4
	VREST 0
	OCTAVE 5
	VNOTE G#, 4
	VNOTE C#, 4
	VREST 0
	VNOTE G#, 4
	OCTAVE 4
	VNOTE B_, 4
	VNOTE G#, 4
	VNOTE D#, 4
	VNOTE G#, 4
	VNOTE C#, 4
	OCTAVE 6
	VNOTE D#, 6
	VNOTE C#, 6
	VREST 0
	OCTAVE 5
	VNOTE G#, 6
	VNOTE C#, 6
	VREST 0
	VNOTE G#, 6
	OCTAVE 4
	VNOTE B_, 6
	VNOTE G#, 6
	VNOTE D#, 6
	VVOICE $10, $00, $08
	INSTRUMENT $07
	OCTAVE 2
	VNOTE F_, 6
	VNOTE F_, 4
	VVOICE $50, $00, $08
	INSTRUMENT $07
	LOOP_START
	VNOTE F_, 2
	LOOP_END $05
	VVOICE $10, $00, $08
	INSTRUMENT $07
	VNOTE F_, 4
	VNOTE F_, 6
	VVOICE $02, $00, $08
	VNOTE F_, 6
	VNOTE E_, 4
	VNOTE D#, 2
	VNOTE D_, 2
	VNOTE C#, 2
	VNOTE C_, 2
	OCTAVE 1
	VNOTE B_, 2
	VNOTE A#, 2
	VNOTE A_, 2
	VNOTE G#, 2
	VNOTE G_, 2
	VNOTE F#, 2
	VNOTE F_, 2
	VVOICE $03, $00, $08
	VNOTE F_, 2
	VNOTE E_, 2
	VNOTE F_, 4
	VNOTE E_, 4
	VNOTE F_, 6
	VNOTE E_, 6
	INSTRUMENT $00
	SND_END

SndD6_SfxN:
	NVOICE $02, $F0
	NOISE $4C
	NVOICE $02, $F0
	NOISE $44
	NOISE $00
	NOISE $26
	NOISE $25
	NOISE $00
	NOISE $45
	NOISE $46
	NVOICE $02, $F0
	NOISE $3B
	NOISE $3C
	NOISE $4D
	NOISE $4D
	NVOICE $03, $80
	NOISE $23
	NOISE $2B
	NOISE $2C
	NOISE $3D
	NOISE $3E
	NOISE $4E
	NOISE $4E
	NOISE $4F
	NVOICE $02, $E0
	NOISE $13
	NVOICE $02, $E0
	NOISE $00
	NVOICE $02, $E0
	NOISE $4A
	NOISE $00
	NOISE $4B
	NOISE $3A
	NOISE $3B
	NOISE $2A
	NOISE $2B
	NOISE $1A
	NOISE $1B
	NOISE $0B
	NOISE $0A
	NOISE $09
	NVOICE $05, $F0
	NOISE $08
	NOISE $19
	NOISE $2A
	NOISE $3B
	NOISE $4C
	NOISE $5D
	NOISE $6E
	NOISE $7F
	NOISE $6F
	NOISE $5E
	NOISE $4D
	NOISE $3C
	NOISE $2B
	NOISE $1A
	NOISE $09
	NOISE $5F
	NOISE $4E
	NOISE $3D
	NOISE $2C
	NOISE $1B
	NOISE $0A
	NOISE $4F
	NOISE $3E
	NOISE $2D
	NOISE $1C
	NOISE $0B
	NOISE $3F
	NOISE $2E
	NOISE $1D
	NOISE $0C
	NOISE $2F
	NOISE $1E
	NOISE $0D
	NOISE $1F
	NOISE $0E
	NOISE $0F
	NOISE $1E
	NOISE $2D
	NOISE $3C
	NOISE $4B
	NOISE $5A
	NOISE $69
	NOISE $78
	NVOICE $03, $F0
	LOOP_START
	NOISE $7A
	NOISE $7B
	NOISE $7C
	NOISE $7B
	LOOP_END $06
	LOOP_START
	NOISE $6B
	NOISE $6C
	NOISE $6D
	NOISE $6C
	LOOP_END $05
	LOOP_START
	NOISE $5C
	NOISE $5D
	NOISE $5E
	NOISE $5D
	LOOP_END $04
	LOOP_START
	NOISE $4D
	NOISE $4E
	NOISE $4F
	NOISE $4E
	LOOP_END $04
	LOOP_START
	NOISE $3D
	NOISE $3E
	NOISE $3F
	NOISE $3E
	LOOP_END $03
	LOOP_START
	NOISE $2D
	NOISE $2E
	NOISE $2F
	NOISE $2E
	LOOP_END $03
	NOISE $3F
	NOISE $2E
	NOISE $1D
	NOISE $2F
	NOISE $1E
	NOISE $1F
	NOISE_VOL 7
	NOISE $4F
	NOISE $3E
	NOISE $1D
	NOISE $3F
	NOISE $2E
	NOISE $2F
	NOISE_VOL 3
	NOISE $5F
	NOISE $4E
	NOISE $2D
	NOISE $4F
	NOISE $3E
	NOISE $3F
	NOISE_VOL 5
	NOISE $3F
	NOISE_VOL 7
	NOISE $3F
	NOISE_VOL 8
	LOOP_START
	NOISE $3F
	NOISE $2F
	NOISE $1F
	NOISE $2F
	LOOP_END $06
	LOOP_START
	NOISE $2F
	NOISE $1F
	NOISE $0F
	NOISE $1E
	LOOP_END $06
	NOISE_VOL 4
	NOISE $2F
	NOISE $1F
	NOISE $0F
	NOISE $1E
	NOISE_VOL 2
	NOISE $2F
	NOISE $1F
	NOISE $0F
	NOISE $1E
	SND_END

SndD7_Ch1:
	SND_SEGNO
	VOICE $04, 4, 7, 0, 0
	VIBRATO_OFF
	OCTAVE 3
	REST 4
	NOTE G_, 4
	NOTE A#, 2
	ATTEN 4
	NOTE A#, 2
	ATTEN 0
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	VOICE $04, 8, 9, 0, 0
	REST 4
	OCTAVE 4
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	ATTEN 0
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	ATTEN 0
	REST 4
	VOICE $04, 4, 7, 0, 0
	OCTAVE 3
	REST 4
	NOTE G_, 4
	NOTE A#, 2
	ATTEN 4
	NOTE A#, 2
	ATTEN 0
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	VOICE $04, 8, 9, 0, 0
	REST 4
	OCTAVE 4
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	ATTEN 0
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	ATTEN 0
	REST 4
	VOICE $04, 4, 7, 0, 0
	OCTAVE 3
	REST 4
	NOTE G_, 4
	NOTE A#, 2
	ATTEN 4
	NOTE A#, 2
	ATTEN 0
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	VOICE $04, 8, 9, 0, 0
	REST 4
	OCTAVE 4
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	NOTE F#, 4
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	REST 1
	VOICE $04, 8, 10, 0, 0
	REST 8
	REST 8
	VIBRATO $01, 0, 2
	REST 4
	OCTAVE 4
	NOTE F_, 2
	ATTEN 5
	NOTE F_, 2
	ATTEN 0
	NOTE F_, 2
	ATTEN 5
	NOTE F_, 4
	ATTEN 0
	REST 2
	VIBRATO_OFF
	VOICE $04, 4, 7, 0, 0
	OCTAVE 3
	REST 4
	NOTE G_, 4
	NOTE A#, 2
	ATTEN 4
	NOTE A#, 2
	ATTEN 0
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	VOICE $04, 8, 9, 0, 0
	REST 4
	OCTAVE 4
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	ATTEN 0
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	ATTEN 0
	REST 4
	VOICE $04, 4, 7, 0, 0
	OCTAVE 3
	REST 4
	NOTE G_, 4
	NOTE A#, 2
	ATTEN 4
	NOTE A#, 2
	ATTEN 0
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	VOICE $04, 8, 9, 0, 0
	REST 4
	OCTAVE 4
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	ATTEN 0
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	ATTEN 0
	REST 4
	VOICE $04, 4, 7, 0, 0
	OCTAVE 3
	REST 4
	NOTE G_, 4
	NOTE A#, 2
	ATTEN 4
	NOTE A#, 2
	ATTEN 0
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	VOICE $04, 8, 9, 0, 0
	REST 4
	OCTAVE 4
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	NOTE F#, 4
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	REST 1
	REST 8
	REST 8
	REST 8
	SND_CALL SndD7_Ch1_52E8
	VOICE $04, 8, 9, 0, 0
	VIBRATO $01, 0, 4
	REST 8
	REST 8
	REST 8
	REST 8
	OCTAVE 3
	ATTEN 0
	NOTE G#, 4
	NOTE G_, 2
	REST 2
	ATTEN 3
	NOTE G#, 4
	NOTE G_, 2
	REST 2
	ATTEN 4
	NOTE G#, 4
	NOTE G_, 2
	REST 2
	ATTEN 6
	NOTE G#, 4
	NOTE G_, 2
	REST 2
	REST 8
	REST 8
	REST 8
	REST 8
	OCTAVE 3
	ATTEN 0
	NOTE G#, 4
	NOTE G_, 2
	REST 2
	ATTEN 3
	NOTE G#, 4
	NOTE G_, 2
	REST 2
	ATTEN 4
	NOTE G#, 4
	NOTE G_, 2
	REST 2
	ATTEN 6
	NOTE G#, 4
	NOTE G_, 2
	REST 2
	SND_LOOP

SndD7_Ch2:
	SND_SEGNO
	VOICE $04, 8, 11, 0, 0
	VIBRATO_OFF
	OCTAVE 2
	NOTE C_, 3
	ATTEN 4
	NOTE C_, 1
	REST 4
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	ATTEN 4
	NOTE C_, 2
	REST 4
	ATTEN 0
	OCTAVE 2
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	VOICE $04, 8, 7, 0, 0
	VIBRATO_OFF
	OCTAVE 4
	NOTE D_, 2
	ATTEN 3
	NOTE D_, 2
	ATTEN 0
	NOTE D_, 2
	ATTEN 3
	NOTE D_, 2
	ATTEN 0
	VOICE $04, 8, 10, 0, 0
	VIBRATO_OFF
	ATTEN 0
	OCTAVE 1
	NOTE A_, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE C_, 3
	ATTEN 4
	NOTE C_, 1
	REST 4
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	ATTEN 4
	NOTE C_, 2
	REST 4
	ATTEN 0
	OCTAVE 2
	NOTE A#, 3
	DETUNE $07
	NOTE A#, 1
	DETUNE $00
	NOTE B_, 4
	VIBRATO_OFF
	NOTE F#, 4
	OCTAVE 1
	NOTE A_, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE C_, 3
	ATTEN 4
	NOTE C_, 1
	REST 4
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	ATTEN 4
	NOTE C_, 2
	REST 4
	ATTEN 0
	OCTAVE 2
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	VOICE $04, 8, 7, 0, 0
	OCTAVE 4
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	NOTE C#, 4
	NOTE D_, 2
	ATTEN 3
	NOTE D_, 2
	ATTEN 0
	VOICE $04, 8, 11, 0, 0
	VIBRATO_OFF
	OCTAVE 2
	NOTE D#, 3
	ATTEN 4
	NOTE D#, 1
	REST 4
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	ATTEN 4
	NOTE C_, 2
	REST 4
	ATTEN 0
	OCTAVE 2
	NOTE F_, 2
	ATTEN 4
	NOTE F_, 2
	ATTEN 0
	VOICE $04, 8, 9, 0, 0
	VIBRATO $01, 0, 2
	OCTAVE 4
	NOTE E_, 2
	ATTEN 3
	NOTE E_, 2
	ATTEN 0
	NOTE E_, 2
	ATTEN 3
	NOTE E_, 4
	ATTEN 0
	REST 2
	VIBRATO_OFF
	VOICE $04, 8, 11, 0, 0
	VIBRATO_OFF
	OCTAVE 2
	NOTE C_, 3
	ATTEN 4
	NOTE C_, 1
	REST 4
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	ATTEN 4
	NOTE C_, 2
	REST 4
	ATTEN 0
	OCTAVE 2
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	VOICE $04, 8, 7, 0, 0
	VIBRATO_OFF
	OCTAVE 4
	NOTE D_, 2
	ATTEN 3
	NOTE D_, 2
	ATTEN 0
	NOTE D_, 2
	ATTEN 3
	NOTE D_, 2
	ATTEN 0
	VOICE $04, 8, 11, 0, 0
	VIBRATO_OFF
	ATTEN 0
	OCTAVE 1
	NOTE A_, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE C_, 3
	ATTEN 4
	NOTE C_, 1
	REST 4
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	ATTEN 4
	NOTE C_, 2
	REST 4
	ATTEN 0
	OCTAVE 2
	NOTE A#, 3
	DETUNE $07
	NOTE A#, 1
	DETUNE $00
	NOTE B_, 4
	VIBRATO_OFF
	NOTE F#, 4
	OCTAVE 1
	NOTE A_, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE C_, 3
	ATTEN 4
	NOTE C_, 1
	REST 4
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	ATTEN 4
	NOTE C_, 2
	REST 4
	ATTEN 0
	OCTAVE 2
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	VOICE $04, 8, 7, 0, 0
	OCTAVE 4
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	NOTE C#, 4
	NOTE D_, 2
	ATTEN 3
	NOTE D_, 2
	ATTEN 0
	VOICE $04, 8, 11, 0, 0
	VIBRATO_OFF
	OCTAVE 2
	NOTE D#, 3
	ATTEN 4
	NOTE D#, 1
	REST 4
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	ATTEN 4
	NOTE C_, 2
	REST 4
	ATTEN 0
	OCTAVE 2
	NOTE F_, 2
	ATTEN 4
	NOTE F_, 2
	ATTEN 0
	REST 4
	OCTAVE 1
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	NOTE B_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 2
	NOTE C_, 2
	ATTEN 4
	NOTE C_, 2
	ATTEN 0
	REST 4
	REST 8
	REST 8
	REST 8
	VOICE $04, 8, 4, 0, 0
	VIBRATO $01, 0, 4
	DETUNE $03
	PAN_LEFT 0
	REST 3
	OCTAVE 3
	NOTE G#, 4
	NOTE G_, 2
	REST 1
	PAN_BOTH 0
	REST 1
	NOTE G#, 4
	NOTE G_, 2
	REST 1
	PAN_RIGHT 0
	REST 1
	NOTE G#, 4
	NOTE G_, 2
	REST 2
	NOTE G#, 4
	NOTE G_, 1
	VOICE $04, 8, 11, 0, 0
	VIBRATO_OFF
	OCTAVE 2
	NOTE C_, 2
	ATTEN 4
	NOTE C_, 2
	ATTEN 0
	REST 4
	REST 8
	REST 8
	REST 8
	VOICE $04, 8, 4, 0, 0
	VIBRATO $01, 0, 4
	DETUNE $03
	PAN_RIGHT 0
	REST 3
	OCTAVE 3
	NOTE G#, 4
	NOTE G_, 2
	REST 1
	PAN_BOTH 0
	REST 1
	NOTE G#, 4
	NOTE G_, 2
	REST 1
	PAN_LEFT 0
	REST 1
	NOTE G#, 4
	NOTE G_, 2
	REST 2
	NOTE G#, 4
	NOTE G_, 1
	SND_LOOP

SndD7_Ch3:
	SND_SEGNO
	VOICE $04, 10, 2, 0, 0
	VIBRATO_OFF
	OCTAVE 4
	NOTE G_, 4
	OCTAVE 5
	NOTE C_, 2
	NOTE D#, 2
	NOTE E_, 2
	REST 2
	NOTE G_, 2
	REST 2
	VIBRATO $01, 5, 2
	NOTE A#, 10
	ATTEN 2
	NOTE A#, 6
	ATTEN 0
	VIBRATO_OFF
	OCTAVE 4
	NOTE G_, 4
	OCTAVE 5
	NOTE C_, 2
	NOTE D#, 2
	NOTE E_, 2
	REST 2
	NOTE G_, 2
	REST 2
	VIBRATO $01, 5, 2
	NOTE F#, 10
	ATTEN 2
	NOTE F#, 6
	ATTEN 0
	VIBRATO_OFF
	OCTAVE 4
	NOTE G_, 4
	OCTAVE 5
	NOTE C_, 2
	NOTE D#, 2
	NOTE E_, 2
	REST 2
	NOTE G_, 2
	REST 2
	VIBRATO $01, 5, 2
	NOTE A#, 10
	ATTEN 2
	NOTE A#, 3
	ATTEN 0
	REST 3
	VIBRATO_OFF
	NOTE A#, 4
	NOTE G_, 2
	REST 2
	NOTE D#, 2
	REST 2
	OCTAVE 4
	NOTE A#, 2
	REST 2
	NOTE A_, 2
	REST 6
	REST 8
	OCTAVE 4
	NOTE G_, 4
	OCTAVE 5
	NOTE C_, 2
	NOTE D#, 2
	NOTE E_, 2
	REST 2
	NOTE G_, 2
	REST 2
	VIBRATO $01, 5, 2
	NOTE A#, 10
	ATTEN 2
	NOTE A#, 6
	ATTEN 0
	VIBRATO_OFF
	OCTAVE 4
	NOTE G_, 4
	OCTAVE 5
	NOTE C_, 2
	NOTE D#, 2
	NOTE E_, 2
	REST 2
	NOTE G_, 2
	REST 2
	VIBRATO $01, 5, 2
	NOTE F#, 10
	ATTEN 2
	NOTE F#, 6
	ATTEN 0
	VIBRATO_OFF
	OCTAVE 4
	NOTE G_, 4
	OCTAVE 5
	NOTE C_, 2
	NOTE D#, 2
	NOTE E_, 2
	REST 2
	NOTE G_, 2
	REST 2
	VIBRATO $01, 5, 2
	NOTE A#, 10
	ATTEN 2
	NOTE A#, 3
	ATTEN 0
	REST 3
	VIBRATO_OFF
	NOTE A#, 4
	NOTE G_, 2
	REST 2
	NOTE D#, 2
	REST 2
	OCTAVE 4
	NOTE A#, 2
	REST 2
	NOTE A_, 4
	ATTEN 2
	NOTE A_, 4
	ATTEN 0
	NOTE B_, 8
	VOICE $04, 3, 2, 0, 0
	INSTRUMENT $01
	PAN_LEFT 0
	OCTAVE 3
	NOTE C_, 2
	REST 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE F#, 2
	REST 2
	NOTE G_, 2
	REST 2
	PAN_RIGHT 0
	OCTAVE 3
	NOTE C_, 2
	REST 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE F#, 2
	REST 2
	NOTE G_, 2
	REST 2
	REST 8
	REST 8
	REST 8
	REST 8
	PAN_LEFT 0
	OCTAVE 3
	NOTE C_, 2
	REST 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE F#, 2
	REST 2
	NOTE G_, 2
	REST 2
	PAN_RIGHT 0
	OCTAVE 3
	NOTE C_, 2
	REST 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE F#, 2
	REST 2
	NOTE G_, 2
	REST 2
	REST 8
	REST 8
	REST 8
	REST 8
	INSTRUMENT $00
	SND_LOOP

SndD7_Drm:
	SND_SEGNO
	LEN_UNIT $04
	DRUM 9, 8
	DRUM 1, 4
	DRUM 9, 4
	DRUM 1, 4
	DRUM 9, 4
	DRUM 7, 4
	DRUM 9, 4
	DRUM 9, 4
	DRUM 7, 4
	DRUM 1, 4
	DRUM 7, 4
	DRUM 1, 4
	DRUM 9, 4
	DRUM 7, 4
	DRUM 9, 4
	DRUM 9, 8
	DRUM 1, 4
	DRUM 9, 4
	DRUM 1, 4
	DRUM 9, 4
	DRUM 7, 4
	DRUM 9, 4
	DRUM 9, 4
	DRUM 7, 4
	DRUM 1, 4
	DRUM 7, 4
	DRUM 1, 8
	REST 8
	DRUM 9, 8
	DRUM 1, 4
	DRUM 9, 4
	DRUM 1, 4
	DRUM 9, 4
	DRUM 7, 4
	DRUM 9, 4
	DRUM 9, 4
	DRUM 7, 4
	DRUM 1, 4
	DRUM 7, 4
	DRUM 1, 4
	DRUM 9, 4
	DRUM 7, 4
	DRUM 9, 4
	DRUM 9, 8
	DRUM 1, 4
	DRUM 9, 4
	DRUM 1, 4
	DRUM 9, 4
	DRUM 7, 4
	DRUM 9, 4
	DRUM 9, 4
	DRUM 7, 4
	DRUM 1, 4
	DRUM 7, 4
	DRUM 1, 4
	DRUM 7, 4
	DRUM 7, 4
	DRUM 9, 4
	DRUM 9, 8
	DRUM 1, 4
	DRUM 9, 4
	DRUM 1, 4
	DRUM 9, 4
	DRUM 7, 4
	DRUM 9, 4
	DRUM 9, 4
	DRUM 7, 4
	REST 4
	DRUM 7, 4
	REST 4
	DRUM 9, 4
	DRUM 7, 4
	DRUM 9, 4
	DRUM 9, 8
	DRUM 1, 4
	DRUM 9, 4
	DRUM 1, 4
	DRUM 9, 4
	DRUM 7, 4
	DRUM 9, 4
	DRUM 9, 4
	DRUM 7, 4
	REST 4
	DRUM 7, 4
	REST 4
	DRUM 9, 4
	DRUM 7, 4
	DRUM 9, 4
	SND_LOOP
SndD7_Ch1_52E8:
	VOICE $01, 8, 10, 0, 0
	TRANSPOSE_UP 5
	PAN_BOTH 0
	OCTAVE 2
	NOTE B_, 3
	NOTE A#, 3
	ATTEN 1
	NOTE A_, 2
	ATTEN 2
	NOTE G#, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 6
	NOTE F#, 2
	ATTEN 8
	NOTE F_, 2
	REST 8
	REST 8
	LEN_UNIT $04
	TRANSPOSE_DOWN 0
	SND_RET

SndDB_Ch2:
	VOICE $06, 4, 8, 11, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 2
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D#, 1
	NOTE D#, 2
	NOTE D#, 1
	NOTE D#, 2
	NOTE D#, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	RELEASE 0, 0
	NOTE E_, 3
	SND_SEGNO
	VOICE $06, 4, 14, 0, 0
	LOOP2_START
	OCTAVE 2
	LOOP_START
	NOTE D_, 2
	RELEASE $0B, 1
	DUTY 8
	NOTE C_HI, 1
	DUTY 4
	RELEASE 0, 0
	REST 1
	LOOP_END $03
	NOTE C#, 2
	RELEASE $0B, 1
	DUTY 8
	NOTE C_HI, 1
	DUTY 4
	RELEASE 0, 0
	REST 1
	OCTAVE 1
	LOOP_START
	NOTE B_, 2
	RELEASE $0B, 1
	DUTY 8
	NOTE C_HI, 1
	DUTY 4
	RELEASE 0, 0
	REST 1
	LOOP_END $03
	OCTAVE 2
	NOTE F#, 2
	RELEASE $0B, 1
	DUTY 8
	NOTE C_HI, 1
	DUTY 4
	RELEASE 0, 0
	REST 1
	LOOP_START
	NOTE E_, 2
	RELEASE $0B, 1
	DUTY 8
	NOTE C_HI, 1
	DUTY 4
	RELEASE 0, 0
	REST 1
	LOOP_END $02
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	RELEASE $0B, 1
	DUTY 8
	NOTE C_HI, 1
	DUTY 4
	RELEASE 0, 0
	REST 1
	LOOP_END $02
	OCTAVE 2
	NOTE D_, 2
	RELEASE $0B, 1
	DUTY 8
	NOTE C_HI, 1
	DUTY 4
	RELEASE 0, 0
	REST 1
	LOOP_BREAK $FC
	NOTE C#, 2
	RELEASE $0B, 1
	DUTY 8
	NOTE C_HI, 1
	DUTY 4
	RELEASE 0, 0
	REST 1
	OCTAVE 2
	NOTE C_, 2
	RELEASE $0B, 1
	DUTY 8
	NOTE C_HI, 1
	DUTY 4
	RELEASE 0, 0
	REST 1
	OCTAVE 1
	NOTE B_, 2
	RELEASE $0B, 1
	DUTY 8
	NOTE C_HI, 1
	DUTY 4
	RELEASE 0, 0
	REST 1
	LOOP2_END $02
	NOTE D_, 2
	RELEASE $0B, 1
	DUTY 8
	NOTE C_HI, 1
	DUTY 4
	REST 1
	RELEASE 9, 1
	NOTE D_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	SND_LOOP

SndDB_Ch1:
	VOICE $06, 8, 7, 11, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 2
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 2
	NOTE G_, 1
	NOTE G_, 2
	NOTE G_, 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	RELEASE 0, 0
	NOTE A_, 3
	SND_SEGNO
	LOOP2_START
	RELEASE $0B, 1
	REST 2
	OCTAVE 2
	NOTE A_, 1
	REST 3
	NOTE A_, 1
	REST 1
	OCTAVE 4
	RELEASE 0, 0
	NOTE F_, 1
	NOTE F#, 1
	RELEASE $0B, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 4
	RELEASE 0, 0
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	RELEASE $0B, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 4
	RELEASE 0, 0
	NOTE C_, 1
	RELEASE $0B, 1
	REST 2
	OCTAVE 2
	NOTE F#, 1
	REST 3
	NOTE F#, 1
	REST 1
	OCTAVE 4
	RELEASE 0, 0
	NOTE F_, 1
	NOTE F#, 1
	RELEASE $0B, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 4
	RELEASE 0, 0
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	RELEASE $0B, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	RELEASE 0, 0
	NOTE F#, 1
	OCTAVE 3
	NOTE B_, 2
	RELEASE $0B, 1
	OCTAVE 2
	NOTE B_, 1
	REST 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE A_, 2
	RELEASE $0B, 1
	OCTAVE 2
	NOTE B_, 1
	REST 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE G#, 2
	RELEASE $0B, 1
	OCTAVE 2
	NOTE B_, 1
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	OCTAVE 3
	NOTE A_, 3
	VIBRATO_OFF
	RELEASE $0B, 1
	OCTAVE 2
	NOTE B_, 1
	REST 1
	LOOP_BREAK $FC
	OCTAVE 4
	NOTE D_, 2
	RELEASE $0B, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE F_, 1
	NOTE F#, 1
	RELEASE $0B, 1
	OCTAVE 2
	NOTE G#, 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	RELEASE $0B, 1
	OCTAVE 2
	NOTE G_, 1
	RELEASE 0, 0
	OCTAVE 4
	NOTE C#, 1
	NOTE A_, 1
	NOTE B_, 1
	RELEASE $0B, 1
	OCTAVE 2
	NOTE G_, 1
	RELEASE 0, 0
	OCTAVE 4
	NOTE A_, 1
	LOOP2_END $02
	OCTAVE 4
	NOTE C#, 2
	RELEASE $0B, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE C_HI, 1
	REST 2
	NOTE A_, 1
	REST 1
	OCTAVE 3
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE G#, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE C_HI, 1
	SND_LOOP

SndDB_Ch3:
	VOICE $06, 4, 2, 11, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 2
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 5
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	RELEASE 0, 0
	NOTE C#, 3
	INSTRUMENT $03
	RELEASE 0, 0
	ATTEN 1
	SND_SEGNO
	LOOP_START
	OCTAVE 5
	NOTE C#, 3
	RELEASE $0B, 1
	NOTE D_, 3
	RELEASE 0, 0
	VIBRATO $01, 2, 1
	OCTAVE 4
	NOTE A_, 6
	OCTAVE 5
	NOTE F#, 4
	VIBRATO_OFF
	OCTAVE 5
	NOTE F_, 3
	RELEASE $0B, 1
	NOTE F#, 3
	RELEASE 0, 0
	OCTAVE 4
	VIBRATO $01, 2, 2
	NOTE B_, 10
	VIBRATO_OFF
	OCTAVE 5
	NOTE D_, 4
	NOTE C#, 4
	NOTE C_, 3
	NOTE C#, 3
	LOOP_BREAK $FB
	NOTE E_, 2
	NOTE F#, 3
	RELEASE $0B, 1
	NOTE F_, 3
	RELEASE 0, 0
	OCTAVE 4
	VIBRATO $01, 2, 2
	NOTE A_, 10
	VIBRATO_OFF
	LOOP_END $02
	NOTE F#, 2
	NOTE E_, 3
	RELEASE $0B, 1
	NOTE D_, 3
	RELEASE 0, 0
	VIBRATO $01, 2, 2
	NOTE D_, 10
	SND_LOOP

SndDB_Drm:
	LEN_UNIT $06
	DRUM $0C, 4
	DRUM 3, 2
	DRUM 3, 2
	LOOP_START
	DRUM $0C, 3
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 2
	LOOP_END $02
	LOOP_START
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	LOOP_END $02
	SND_SEGNO
	LOOP2_START
	DRUM $0C, 2
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 7, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP_START
	DRUM 9, 1
	DRUM 7, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 7, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP_END $02
	LOOP_BREAK $FC
	LOOP_START
	DRUM 9, 1
	DRUM 7, 1
	DRUM 3, 1
	DRUM 7, 1
	LOOP_END $02
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 7, 1
	LOOP2_END $02
	DRUM 9, 1
	DRUM 7, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP_START
	DRUM 9, 1
	DRUM 3, 1
	LOOP_END $04
	SND_LOOP

SndDC_Ch2:
	VOICE $06, 4, 14, 10, 1
	DUTY_STEP 8, 1
	SND_SEGNO
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	NOTE G_, 2
	LOOP_BREAK $FB
	OCTAVE 3
	NOTE C_, 2
	LOOP_END $03
	LOOP_START
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE E_, 2
	LOOP_BREAK $FB
	NOTE A#, 2
	LOOP_END $03
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE A_, 2
	LOOP_END $02
	OCTAVE 1
	NOTE A_, 2
	LOOP_BREAK $FC
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE F_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE G#, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE D_, 2
	LOOP2_END $02
	RELEASE 0, 0
	OCTAVE 2
	VIBRATO $01, 0, 5
	NOTE F_, 4
	VIBRATO_OFF
	RELEASE $0A, 1
	OCTAVE 1
	NOTE G_, 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	REST 2
	RELEASE 0, 0
	OCTAVE 2
	NOTE F_, 2
	RELEASE $0A, 1
	NOTE F#, 2
	OCTAVE 1
	NOTE G_, 2
	SND_LOOP

SndDC_Ch1:
	VOICE $06, 8, 7, 9, 1
	SND_SEGNO
	LOOP_START
	OCTAVE 4
	NOTE E_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	ATTEN 4
	NOTE E_, 2
	ATTEN 0
	NOTE F_, 2
	ATTEN 4
	NOTE F_, 2
	ATTEN 0
	NOTE E_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	ATTEN 4
	NOTE D_, 2
	ATTEN 0
	RELEASE 0, 0
	VIBRATO $01, 5, 2
	NOTE C_, 6
	RELEASE 9, 1
	VIBRATO_OFF
	OCTAVE 3
	NOTE A_, 2
	ATTEN 4
	NOTE A_, 2
	ATTEN 0
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE F_, 2
	ATTEN 4
	NOTE F_, 2
	ATTEN 0
	NOTE A_, 2
	ATTEN 4
	NOTE A_, 2
	ATTEN 0
	RELEASE 0, 0
	VIBRATO $01, 5, 2
	NOTE A_, 4
	RELEASE 9, 1
	VIBRATO_OFF
	NOTE A#, 2
	NOTE B_, 2
	NOTE B_, 2
	ATTEN 4
	NOTE B_, 2
	ATTEN 0
	LOOP_BREAK $FB
	RELEASE 0, 0
	VIBRATO $01, 2, 2
	OCTAVE 4
	NOTE C_, 6
	RELEASE 9, 1
	VIBRATO_OFF
	LOOP_END $02
	NOTE G#, 2
	NOTE A_, 2
	NOTE B_, 2
	SND_LOOP

SndDC_Ch3:
	VOICE $06, 12, 2, 9, 1
	SND_SEGNO
	LOOP_START
	OCTAVE 5
	NOTE G_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	ATTEN 1
	NOTE G_, 2
	ATTEN 0
	NOTE A_, 2
	ATTEN 1
	NOTE A_, 2
	ATTEN 0
	RELEASE 0, 0
	VIBRATO $01, 5, 2
	NOTE G_, 12
	RELEASE 9, 1
	VIBRATO_OFF
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 1
	NOTE E_, 2
	ATTEN 0
	NOTE F_, 2
	OCTAVE 4
	NOTE A_, 2
	ATTEN 1
	NOTE A_, 2
	ATTEN 0
	OCTAVE 5
	NOTE C_, 2
	ATTEN 1
	NOTE C_, 2
	ATTEN 0
	RELEASE 0, 0
	VIBRATO $01, 2, 2
	LOOP_BREAK $FB
	NOTE C_, 4
	RELEASE 9, 1
	VIBRATO_OFF
	NOTE C#, 2
	NOTE D_, 2
	NOTE D_, 2
	ATTEN 1
	NOTE D_, 2
	ATTEN 0
	RELEASE 0, 0
	VIBRATO $01, 2, 2
	NOTE G#, 6
	RELEASE 9, 1
	VIBRATO_OFF
	LOOP_END $02
	NOTE E_, 4
	RELEASE 9, 1
	VIBRATO_OFF
	NOTE C#, 2
	NOTE D_, 2
	NOTE D_, 2
	ATTEN 1
	NOTE D_, 2
	ATTEN 0
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	SND_LOOP

SndDC_Drm:
	LEN_UNIT $06
	SND_SEGNO
	DRUM $0A, 2
	DRUM 7, 2
	DRUM $0A, 3
	DRUM 9, 1
	DRUM 8, 2
	DRUM 7, 2
	DRUM $0A, 2
	DRUM 8, 2
	LOOP2_START
	DRUM 9, 2
	DRUM 7, 2
	DRUM $0A, 3
	DRUM 9, 1
	DRUM 8, 2
	DRUM 7, 2
	DRUM $0A, 2
	DRUM 8, 2
	LOOP2_END $02
	DRUM 9, 2
	DRUM 7, 2
	DRUM 4, 3
	DRUM 4, 1
	DRUM 8, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM 8, 2
	LOOP2_START
	DRUM 9, 2
	DRUM 7, 2
	DRUM $0A, 3
	DRUM 9, 1
	DRUM 8, 2
	DRUM 7, 2
	DRUM $0A, 2
	DRUM 8, 2
	LOOP2_END $03
	DRUM 9, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 7, 2
	DRUM $0A, 4
	DRUM 9, 2
	SND_LOOP

SndDD_Ch2:
	VOICE $07, 8, 10, 0, 0
	TRANSPOSE_DOWN 5
	ATTEN 2
	PAN_LEFT 0
	VIBRATO $01, 3, 1
	REST 2
	OCTAVE 3
	NOTE A_, 4
	NOTE G#, 4
	NOTE D_, 4
	NOTE C#, 4
	NOTE C_, 14
	RELEASE 9, 6
	NOTE C_, 0
	SND_END

SndDD_Ch1:
	VOICE $07, 8, 8, 0, 0
	DETUNE $FE
	TRANSPOSE_DOWN 5
	REST 4
	PAN_RIGHT 0
	VIBRATO $01, 3, 1
	OCTAVE 3
	NOTE A_, 4
	NOTE G#, 4
	NOTE D_, 4
	NOTE C#, 4
	NOTE C_, 12
	VOICE $07, 12, 8, 7, 1
	VIBRATO $01, 0, 2
	DETUNE $05
	OCTAVE 5
	NOTE B_, 4
	DETUNE $03
	RELEASE $0D, 1
	NOTE B_, 2
	DETUNE $00
	ATTEN 1
	NOTE B_, 2
	DETUNE $FE
	ATTEN 2
	NOTE B_, 2
	DETUNE $FB
	ATTEN 3
	NOTE B_, 2
	DETUNE $F7
	ATTEN 4
	NOTE B_, 2
	DETUNE $F5
	ATTEN 5
	NOTE B_, 2
	DETUNE $F3
	ATTEN 6
	NOTE B_, 2
	DETUNE $F0
	ATTEN 7
	NOTE B_, 2
	SND_END

SndDD_Ch3:
	VOICE $07, 1, 2, 0, 0
	DETUNE $02
	TRANSPOSE_DOWN 5
	OCTAVE 4
	VIBRATO $01, 3, 1
	NOTE A_, 4
	NOTE G#, 4
	NOTE D_, 4
	NOTE C#, 4
	NOTE C_, 0
	RELEASE 9, 6
	NOTE C_, 0
	DETUNE $00
	SND_END

SndDD_Drm:
	LEN_UNIT $07
	REST 0
	REST $0A
	DRUM_SND $0E, 0
	SND_END

SndDE_Ch2:
	VOICE $08, 4, 15, 11, 1
	REST 0
	SND_SEGNO
	LOOP_START
	SND_CALL SndDE_Ch2_5B02
	OCTAVE 1
	NOTE A_, 1
	ATTEN 3
	DUTY 8
	OCTAVE 3
	NOTE G_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	ATTEN 3
	DUTY 8
	OCTAVE 3
	NOTE G_, 1
	ATTEN 5
	PAN_LEFT 0
	OCTAVE 4
	NOTE A_, 1
	DUTY 4
	ATTEN 0
	PAN_BOTH 0
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 1
	ATTEN 3
	DUTY 8
	OCTAVE 3
	NOTE G_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 1
	NOTE A_, 1
	ATTEN 5
	DUTY 8
	PAN_RIGHT 0
	OCTAVE 4
	NOTE A_, 1
	PAN_BOTH 0
	DUTY 4
	ATTEN 0
	OCTAVE 1
	NOTE A_, 1
	ATTEN 3
	DUTY 8
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	DUTY 4
	ATTEN 0
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	ATTEN 3
	DUTY 8
	OCTAVE 3
	NOTE F_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	ATTEN 3
	DUTY 8
	OCTAVE 3
	NOTE F_, 1
	ATTEN 5
	PAN_LEFT 0
	OCTAVE 4
	NOTE A_, 1
	DUTY 4
	ATTEN 0
	PAN_BOTH 0
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 1
	ATTEN 3
	DUTY 8
	OCTAVE 3
	NOTE F_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 1
	NOTE A_, 1
	ATTEN 5
	DUTY 8
	PAN_RIGHT 0
	OCTAVE 4
	NOTE A_, 1
	PAN_BOTH 0
	DUTY 4
	ATTEN 0
	OCTAVE 1
	NOTE A_, 1
	ATTEN 3
	DUTY 8
	OCTAVE 3
	NOTE F_, 1
	NOTE F_, 1
	DUTY 4
	ATTEN 0
	OCTAVE 1
	NOTE A_, 1
	SND_CALL SndDE_Ch2_5B02
	TRANSPOSE_UP 1
	LOOP_END $02
	TRANSPOSE_UP 0
	SND_LOOP

SndDE_Ch1:
	VOICE $08, 4, 15, 11, 1
	REST 0
	SND_SEGNO
	LOOP_START
	SND_CALL SndDE_Ch1_5AB5
	OCTAVE 2
	NOTE E_, 1
	ATTEN 3
	DUTY 0
	OCTAVE 3
	NOTE D_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 3
	DUTY 0
	OCTAVE 3
	NOTE D_, 1
	ATTEN 5
	DUTY 8
	DETUNE $FE
	PAN_LEFT 0
	OCTAVE 4
	NOTE A_, 1
	PAN_BOTH 0
	DETUNE $00
	DUTY 4
	ATTEN 0
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 1
	ATTEN 3
	DUTY 0
	OCTAVE 3
	NOTE D_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 2
	NOTE E_, 1
	ATTEN 5
	DUTY 8
	DETUNE $FE
	PAN_RIGHT 0
	OCTAVE 4
	NOTE A_, 1
	PAN_BOTH 0
	DETUNE $00
	DUTY 4
	ATTEN 0
	OCTAVE 2
	NOTE E_, 1
	ATTEN 3
	DUTY 0
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	ATTEN 3
	DUTY 0
	OCTAVE 3
	NOTE C_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 3
	DUTY 0
	OCTAVE 3
	NOTE C_, 1
	ATTEN 5
	DUTY 8
	DETUNE $FE
	PAN_LEFT 0
	OCTAVE 4
	NOTE A_, 1
	PAN_BOTH 0
	DETUNE $00
	DUTY 4
	ATTEN 0
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 1
	ATTEN 3
	DUTY 0
	OCTAVE 3
	NOTE C_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 2
	NOTE E_, 1
	ATTEN 5
	DUTY 8
	DETUNE $FE
	PAN_RIGHT 0
	OCTAVE 4
	NOTE A_, 1
	PAN_BOTH 0
	DETUNE $00
	DUTY 4
	ATTEN 0
	OCTAVE 2
	NOTE E_, 1
	ATTEN 3
	DUTY 0
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 2
	NOTE E_, 1
	SND_CALL SndDE_Ch1_5AB5
	TRANSPOSE_UP 1
	LOOP_END $02
	TRANSPOSE_UP 0
	SND_LOOP

SndDE_Ch3:
	VOICE $08, 12, 2, 11, 1
	REST 0
	SND_SEGNO
	WAVE_X $2C
	OCTAVE 4
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $2B
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $2A
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $29
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $28
	NOTE E_, 1
	WAVE_X $27
	NOTE E_, 1
	WAVE_X $26
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $25
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $24
	NOTE E_, 1
	WAVE_X $23
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	WAVE_X $22
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $21
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE B_, 1
	WAVE_X $20
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $21
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE B_, 1
	WAVE_X $22
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $23
	NOTE E_, 1
	WAVE_X $24
	NOTE E_, 1
	WAVE_X $25
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE B_, 1
	WAVE_X $26
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $27
	NOTE E_, 1
	WAVE_X $28
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	WAVE_X $29
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $2A
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $2B
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $2C
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $2B
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $2A
	NOTE E_, 1
	WAVE_X $29
	NOTE E_, 1
	WAVE_X $28
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $27
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $26
	NOTE E_, 1
	WAVE_X $25
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	WAVE_X $24
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $23
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $22
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $21
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $20
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $21
	NOTE E_, 1
	WAVE_X $22
	NOTE E_, 1
	WAVE_X $23
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $24
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $25
	NOTE E_, 1
	LOOP_BREAK $FC
	WAVE_X $26
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	WAVE_X $27
	OCTAVE 4
	NOTE E_, 1
	TRANSPOSE_UP 1
	WAVE_X $28
	OCTAVE 4
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $29
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $2A
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $2B
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $2C
	NOTE E_, 1
	WAVE_X $2B
	NOTE E_, 1
	WAVE_X $2A
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $29
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $28
	NOTE E_, 1
	WAVE_X $27
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	WAVE_X $26
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $25
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE B_, 1
	WAVE_X $24
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $23
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE B_, 1
	WAVE_X $22
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $21
	NOTE E_, 1
	WAVE_X $20
	NOTE E_, 1
	WAVE_X $21
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE B_, 1
	WAVE_X $22
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $23
	NOTE E_, 1
	WAVE_X $24
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	WAVE_X $25
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $26
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $27
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $28
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $29
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $2A
	NOTE E_, 1
	WAVE_X $2B
	NOTE E_, 1
	WAVE_X $2C
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $2B
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $2A
	NOTE E_, 1
	WAVE_X $29
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	WAVE_X $28
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $27
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $26
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $25
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $24
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $23
	NOTE E_, 1
	WAVE_X $22
	NOTE E_, 1
	WAVE_X $21
	NOTE E_, 1
	WAVE 0
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $20
	OCTAVE 4
	NOTE E_, 1
	WAVE_X $21
	NOTE E_, 1
	TRANSPOSE_UP 0
	WAVE_X $22
	NOTE F_, 1
	WAVE 0
	OCTAVE 3
	NOTE A#, 1
	NOTE A#, 1
	WAVE_X $23
	OCTAVE 4
	NOTE F_, 1
	SND_LOOP

SndDE_Drm:
	LEN_UNIT $08
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM $0B, 1
	SND_SEGNO
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $02
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM $0B, 1
	LOOP_END $02
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM $0B, 1
	SND_LOOP
SndDE_Ch1_5AB5:
	OCTAVE 2
	NOTE E_, 1
	ATTEN 3
	DUTY 0
	OCTAVE 3
	NOTE C#, 1
	ATTEN 0
	DUTY 4
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 3
	DUTY 0
	OCTAVE 3
	NOTE C#, 1
	ATTEN 5
	DUTY 8
	DETUNE $FE
	PAN_LEFT 0
	OCTAVE 4
	NOTE A_, 1
	PAN_BOTH 0
	DETUNE $00
	DUTY 4
	ATTEN 0
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 1
	ATTEN 3
	DUTY 0
	OCTAVE 3
	NOTE C#, 1
	ATTEN 0
	DUTY 4
	OCTAVE 2
	NOTE E_, 1
	ATTEN 5
	DUTY 8
	DETUNE $FE
	PAN_RIGHT 0
	OCTAVE 4
	NOTE A_, 1
	PAN_BOTH 0
	DETUNE $00
	DUTY 4
	ATTEN 0
	OCTAVE 2
	NOTE E_, 1
	ATTEN 3
	DUTY 0
	OCTAVE 3
	NOTE C#, 1
	NOTE C#, 1
	ATTEN 0
	DUTY 4
	OCTAVE 2
	NOTE E_, 1
	SND_RET
SndDE_Ch2_5B02:
	OCTAVE 1
	NOTE A_, 1
	ATTEN 3
	DUTY 8
	OCTAVE 3
	NOTE E_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	ATTEN 3
	DUTY 8
	OCTAVE 3
	NOTE E_, 1
	ATTEN 5
	PAN_LEFT 0
	OCTAVE 4
	NOTE A_, 1
	DUTY 4
	ATTEN 0
	PAN_BOTH 0
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 1
	ATTEN 3
	DUTY 8
	OCTAVE 3
	NOTE E_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 1
	NOTE A_, 1
	ATTEN 5
	DUTY 8
	PAN_RIGHT 0
	OCTAVE 4
	NOTE A_, 1
	PAN_BOTH 0
	DUTY 4
	ATTEN 0
	OCTAVE 1
	NOTE A_, 1
	ATTEN 3
	DUTY 8
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	DUTY 4
	ATTEN 0
	OCTAVE 1
	NOTE A_, 1
	SND_RET

SndDF_Ch2:
	VOICE $04, 8, 8, 0, 0
	VIBRATO $01, 1, 1
	OCTAVE 4
	NOTE C#, 6
	RELEASE $0B, 1
	NOTE D_, 6
	RELEASE 0, 0
	VIBRATO $01, 2, 2
	OCTAVE 3
	NOTE A_, 8
	RELEASE $0B, 1
	NOTE F#, 4
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE F#, 8
	VIBRATO_OFF
	NOTE F_, 6
	RELEASE $0B, 1
	NOTE F#, 6
	RELEASE 0, 0
	OCTAVE 3
	VIBRATO $01, 4, 3
	NOTE B_, 4
	VIBRATO $01, 0, 3
	NOTE B_, 0
	NOTE B_, 0
	SND_END

SndDF_Ch1:
	VOICE $04, 8, 13, 13, 1
	TRANSPOSE_DOWN $0C
	OCTAVE 3
	NOTE D_, 2
	ATTEN 4
	NOTE D_, 2
	ATTEN 0
	NOTE F#, 2
	ATTEN 4
	NOTE F#, 2
	ATTEN 0
	NOTE A_, 2
	ATTEN 4
	NOTE A_, 2
	OCTAVE 4
	ATTEN 0
	NOTE D_, 2
	ATTEN 4
	NOTE D_, 2
	ATTEN 0
	OCTAVE 3
	NOTE C#, 2
	ATTEN 4
	NOTE C#, 2
	ATTEN 0
	NOTE F#, 2
	ATTEN 4
	NOTE F#, 2
	ATTEN 0
	NOTE A_, 2
	ATTEN 4
	NOTE A_, 2
	OCTAVE 4
	ATTEN 0
	NOTE D_, 2
	ATTEN 4
	NOTE D_, 2
	ATTEN 0
	OCTAVE 2
	NOTE B_, 2
	ATTEN 4
	NOTE B_, 2
	ATTEN 0
	OCTAVE 3
	NOTE F_, 2
	ATTEN 4
	NOTE F_, 2
	ATTEN 0
	NOTE G#, 2
	ATTEN 4
	NOTE G#, 2
	ATTEN 0
	NOTE B_, 2
	ATTEN 4
	NOTE B_, 2
	ATTEN 0
	RELEASE 0, 0
	VIBRATO $01, 4, 4
	NOTE D#, 0
	VIBRATO $01, 0, 4
	NOTE D#, 0
	SND_END

SndDF_Ch3:
	VOICE $04, 1, 2, 11, 1
	TRANSPOSE_UP $0C
	LOOP_START
	OCTAVE 2
	NOTE F#, 2
	ATTEN 1
	NOTE F#, 2
	ATTEN 0
	NOTE A_, 2
	ATTEN 1
	NOTE A_, 2
	ATTEN 0
	OCTAVE 3
	NOTE D_, 2
	ATTEN 1
	NOTE D_, 2
	ATTEN 0
	NOTE F#, 2
	ATTEN 1
	NOTE F#, 2
	ATTEN 0
	LOOP_END $02
	OCTAVE 2
	NOTE F#, 2
	ATTEN 1
	NOTE F#, 2
	ATTEN 0
	NOTE B_, 2
	ATTEN 1
	NOTE B_, 2
	ATTEN 0
	OCTAVE 3
	NOTE D_, 2
	ATTEN 1
	NOTE D_, 2
	ATTEN 0
	NOTE F#, 2
	ATTEN 1
	NOTE F#, 2
	ATTEN 0
	WAVE $0B
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	RELEASE 0, 0
	VIBRATO $01, 1, 1
	NOTE G_, 8
	TRANSPOSE_UP 0
	ATTEN 1
	INSTRUMENT $01
	RELEASE 0, 0
	DETUNE $02
	VIBRATO $02, 0, 1
	OCTAVE 5
	NOTE A#, 0
	SND_END

SndDF_Drm:
	SND_END

SndE0_Ch2:
	SND_SEGNO
	VOICE $05, 4, 8, 6, 4
	LOOP_START
	RELEASE 6, 4
	OCTAVE 3
	NOTE A_, 6
	RELEASE 0, 0
	OCTAVE 4
	VIBRATO $04, 0, 2
	NOTE E_, 2
	VIBRATO $01, 3, 3
	NOTE E_, 0
	VIBRATO_OFF
	NOTE D_, 2
	REST 2
	NOTE C#, 2
	REST 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE A_, 2
	VIBRATO $01, 2, 3
	NOTE A_, 0
	VIBRATO_OFF
	RELEASE 7, 2
	NOTE B_, 4
	NOTE B_, 4
	OCTAVE 3
	NOTE A_, 6
	RELEASE 0, 0
	OCTAVE 4
	VIBRATO $04, 0, 2
	NOTE E_, 2
	VIBRATO $01, 3, 3
	NOTE E_, 0
	VIBRATO_OFF
	RELEASE 6, 4
	NOTE D_, 2
	REST 2
	NOTE C_, 2
	REST 2
	RELEASE 0, 0
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	OCTAVE 3
	VIBRATO $01, 1, 3
	NOTE G_, 6
	VIBRATO_OFF
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	VIBRATO $01, 1, 3
	NOTE E_, 6
	NOTE F_, 2
	RELEASE 8, 1
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	LOOP_END $02
	DUTY 8
	RELEASE 0, 0
	VIBRATO $04, 0, 1
	NOTE G_, 6
	RELEASE 7, 1
	NOTE C_, 2
	RELEASE 0, 0
	NOTE C_, 2
	VIBRATO $01, 3, 4
	NOTE C_, 0
	NOTE D_, 2
	RELEASE 8, 1
	NOTE E_, 2
	NOTE F_, 2
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	NOTE G_, 3
	VIBRATO_OFF
	NOTE F_, 3
	RELEASE 6, 2
	NOTE E_, 2
	REST 2
	RELEASE 0, 0
	VIBRATO $01, 1, 2
	NOTE D_, 3
	VIBRATO_OFF
	NOTE C_, 3
	VIBRATO $01, 2, 3
	OCTAVE 3
	NOTE B_, 0
	OCTAVE 4
	VIBRATO_OFF
	NOTE G_, 6
	RELEASE 7, 1
	NOTE C_, 2
	RELEASE 0, 0
	NOTE C_, 2
	VIBRATO $01, 3, 4
	NOTE C_, 0
	NOTE D_, 2
	RELEASE 8, 1
	NOTE E_, 2
	NOTE F_, 2
	RELEASE 4, 0
	OCTAVE 4
	NOTE G_, 2
	RELEASE 8, 1
	NOTE G_, 2
	RELEASE 2, 0
	DUTY 0
	OCTAVE 3
	NOTE B_, 2
	DUTY 8
	OCTAVE 4
	NOTE G_, 2
	RELEASE 8, 1
	NOTE G_, 2
	RELEASE 2, 0
	DUTY 0
	OCTAVE 3
	NOTE B_, 2
	RELEASE 0, 0
	OCTAVE 4
	DUTY 8
	NOTE G_, 2
	RELEASE 8, 1
	NOTE E_, 2
	RELEASE 2, 0
	DUTY 0
	OCTAVE 3
	NOTE B_, 2
	RELEASE 0, 0
	DUTY 8
	OCTAVE 4
	NOTE E_, 2
	RELEASE 8, 1
	NOTE G#, 2
	RELEASE 0, 0
	NOTE G#, 2
	RELEASE 8, 1
	NOTE B_, 2
	DUTY 0
	RELEASE 2, 0
	OCTAVE 3
	NOTE B_, 2
	DUTY 8
	OCTAVE 4
	RELEASE 0, 0
	NOTE E_, 2
	DUTY 0
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	DUTY 8
	RELEASE 0, 0
	VIBRATO $04, 0, 1
	NOTE G_, 6
	RELEASE 7, 1
	NOTE C_, 2
	RELEASE 0, 0
	NOTE C_, 2
	VIBRATO $01, 3, 4
	NOTE C_, 0
	NOTE D_, 2
	RELEASE 8, 1
	NOTE E_, 2
	NOTE F_, 2
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	NOTE G_, 3
	VIBRATO_OFF
	NOTE F_, 3
	RELEASE 6, 2
	NOTE E_, 2
	REST 2
	RELEASE 0, 0
	VIBRATO $01, 1, 2
	NOTE D_, 3
	VIBRATO_OFF
	NOTE C_, 3
	VIBRATO $01, 2, 3
	OCTAVE 3
	NOTE B_, 0
	OCTAVE 4
	VIBRATO_OFF
	NOTE G_, 6
	RELEASE 7, 1
	NOTE C_, 2
	RELEASE 0, 0
	NOTE C_, 2
	VIBRATO $01, 3, 4
	NOTE C_, 0
	NOTE D_, 2
	RELEASE 8, 1
	NOTE E_, 2
	NOTE F_, 2
	RELEASE 4, 0
	OCTAVE 4
	NOTE G_, 2
	RELEASE 8, 1
	NOTE G_, 2
	RELEASE 2, 0
	DUTY 0
	OCTAVE 3
	NOTE B_, 2
	DUTY 8
	OCTAVE 4
	NOTE G_, 2
	RELEASE 8, 1
	NOTE G_, 2
	RELEASE 2, 0
	DUTY 0
	OCTAVE 3
	NOTE B_, 2
	RELEASE 0, 0
	OCTAVE 4
	DUTY 8
	NOTE G_, 2
	RELEASE 8, 1
	NOTE G#, 2
	RELEASE 2, 0
	DUTY 0
	OCTAVE 3
	NOTE B_, 2
	DUTY 8
	OCTAVE 4
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	RELEASE 8, 1
	NOTE G#, 2
	REST 2
	RELEASE 0, 0
	VIBRATO $03, 3, 3
	NOTE B_, 4
	LOOP_START
	DUTY 8
	OCTAVE 3
	NOTE C_, 2
	RELEASE 8, 1
	DUTY 4
	NOTE A_, 2
	NOTE A_, 2
	RELEASE 0, 0
	LOOP_END $02
	DUTY 8
	OCTAVE 3
	NOTE C_, 2
	DUTY 4
	VIBRATO $01, 3, 3
	NOTE A_, 4
	NOTE G_, 1
	REST 1
	NOTE G_, 9
	REST 1
	NOTE E_, 1
	NOTE G_, 1
	LOOP_START
	DUTY 8
	OCTAVE 3
	NOTE C_, 2
	RELEASE 8, 1
	DUTY 4
	NOTE A_, 2
	NOTE A_, 2
	RELEASE 0, 0
	LOOP_END $02
	DUTY 8
	OCTAVE 3
	NOTE C_, 2
	DUTY 4
	VIBRATO $05, 0, 2
	OCTAVE 4
	NOTE E_, 1
	VIBRATO $01, 0, 2
	NOTE E_, 3
	VIBRATO_OFF
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	RELEASE 8, 1
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	TRANSPOSE_UP 1
	RELEASE 0, 0
	LOOP_START
	DUTY 8
	OCTAVE 3
	NOTE C_, 2
	RELEASE 8, 1
	DUTY 4
	NOTE A_, 2
	NOTE A_, 2
	RELEASE 0, 0
	LOOP_END $02
	DUTY 8
	OCTAVE 3
	NOTE C_, 2
	DUTY 4
	VIBRATO $01, 3, 3
	NOTE A_, 4
	NOTE G_, 1
	REST 1
	NOTE G_, 9
	REST 1
	NOTE E_, 1
	NOTE G_, 1
	LOOP_START
	DUTY 8
	OCTAVE 3
	NOTE C_, 2
	RELEASE 8, 1
	DUTY 4
	NOTE A_, 2
	NOTE A_, 2
	RELEASE 0, 0
	LOOP_END $02
	TRANSPOSE_UP 0
	DUTY 8
	OCTAVE 3
	NOTE C#, 2
	DUTY 4
	VIBRATO $01, 2, 3
	NOTE F_, 4
	REST 2
	RELEASE 8, 2
	NOTE F#, 2
	REST 2
	NOTE G_, 2
	REST 2
	NOTE G#, 2
	REST 2
	SND_LOOP

SndE0_Ch1:
	SND_SEGNO
	VOICE $05, 0, 8, 0, 0
	RELEASE 6, 4
	OCTAVE 3
	NOTE E_, 6
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	NOTE A_, 2
	VIBRATO $01, 3, 3
	NOTE A_, 6
	RELEASE 8, 2
	PAN_LEFT 0
	DUTY 8
	OCTAVE 2
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 4
	NOTE E_, 1
	PAN_RIGHT 0
	ATTEN 0
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 0
	PAN_LEFT 0
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 0
	PAN_BOTH 0
	RELEASE 0, 0
	DUTY 0
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	VIBRATO $01, 2, 3
	NOTE E_, 4
	DUTY 8
	PAN_RIGHT 0
	OCTAVE 4
	NOTE B_, 2
	OCTAVE 5
	NOTE C#, 2
	NOTE D_, 2
	OCTAVE 4
	VIBRATO $01, 2, 3
	NOTE A_, 8
	PAN_BOTH 0
	DUTY 0
	VIBRATO_OFF
	RELEASE 7, 2
	OCTAVE 3
	NOTE F#, 4
	NOTE F#, 4
	RELEASE 7, 2
	OCTAVE 3
	NOTE C_, 6
	RELEASE 0, 0
	VIBRATO $04, 0, 3
	NOTE C_HI, 4
	VIBRATO_OFF
	OCTAVE 4
	RELEASE 8, 1
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	NOTE G_, 2
	VIBRATO $01, 2, 3
	NOTE G_, 6
	OCTAVE 3
	VIBRATO_OFF
	RELEASE 6, 4
	NOTE F_, 2
	REST 2
	NOTE E_, 2
	REST 2
	RELEASE 0, 0
	OCTAVE 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	RELEASE 8, 2
	DUTY_STEP 1, 8
	AUTOPAN 0
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	DUTY_STEP 0, 0
	RELEASE 0, 0
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	RELEASE 8, 2
	DUTY_STEP 8, 1
	AUTOPAN 0
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	DUTY_STEP 0, 0
	RELEASE 0, 0
	OCTAVE 4
	NOTE D_, 2
	RELEASE 8, 1
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	RELEASE 6, 4
	OCTAVE 3
	NOTE E_, 6
	RELEASE 0, 0
	VIBRATO $04, 0, 3
	OCTAVE 4
	NOTE C#, 4
	VIBRATO_OFF
	RELEASE 8, 1
	OCTAVE 3
	NOTE C#, 2
	NOTE E_, 2
	NOTE A_, 2
	RELEASE 0, 0
	OCTAVE 4
	VIBRATO $01, 3, 3
	NOTE C#, 8
	VIBRATO_OFF
	OCTAVE 3
	NOTE B_, 2
	REST 2
	NOTE A_, 2
	REST 2
	PAN_BOTH 0
	RELEASE 0, 0
	DUTY 0
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	VIBRATO $01, 2, 3
	NOTE E_, 4
	DUTY 8
	PAN_RIGHT 0
	OCTAVE 4
	NOTE B_, 2
	OCTAVE 5
	NOTE C#, 2
	NOTE D_, 2
	OCTAVE 4
	VIBRATO $01, 2, 3
	NOTE A_, 8
	PAN_BOTH 0
	DUTY 0
	VIBRATO_OFF
	RELEASE 7, 2
	OCTAVE 3
	NOTE F#, 4
	NOTE F#, 4
	RELEASE 7, 2
	OCTAVE 3
	NOTE C_, 6
	RELEASE 0, 0
	VIBRATO $04, 0, 3
	NOTE C_HI, 4
	VIBRATO_OFF
	OCTAVE 4
	RELEASE 8, 1
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	NOTE G_, 2
	VIBRATO $01, 2, 3
	NOTE G_, 6
	OCTAVE 3
	VIBRATO_OFF
	RELEASE 6, 4
	NOTE F_, 2
	REST 2
	NOTE E_, 2
	REST 2
	RELEASE 0, 0
	OCTAVE 2
	RELEASE 3, 0
	NOTE G_, 2
	RELEASE 0, 0
	NOTE G_, 2
	NOTE A_, 2
	VIBRATO $01, 1, 3
	NOTE B_, 6
	VIBRATO_OFF
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	VIBRATO $01, 1, 3
	NOTE G_, 6
	VIBRATO_OFF
	OCTAVE 4
	NOTE D_, 2
	RELEASE 8, 1
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	DUTY 8
	RELEASE $0D, 1
	OCTAVE 2
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	OCTAVE 3
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 2
	NOTE F#, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	RELEASE $0D, 1
	NOTE E_, 1
	ATTEN 2
	NOTE E_, 1
	ATTEN 0
	OCTAVE 3
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 2
	NOTE F#, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	RELEASE 0, 0
	DUTY 4
	OCTAVE 4
	VIBRATO $01, 2, 3
	NOTE D_, 6
	VIBRATO_OFF
	RELEASE 6, 2
	NOTE C_, 2
	REST 2
	RELEASE 0, 0
	VIBRATO $01, 1, 2
	OCTAVE 3
	NOTE B_, 3
	VIBRATO_OFF
	NOTE A_, 3
	RELEASE 8, 2
	DUTY 0
	OCTAVE 4
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	RELEASE $0B, 2
	NOTE G_, 2
	NOTE A_, 2
	TRANSPOSE_UP 4
	RELEASE 8, 2
	OCTAVE 4
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	RELEASE $0B, 2
	NOTE G_, 2
	TRANSPOSE_UP 0
	OCTAVE 5
	NOTE D_, 2
	DUTY 8
	RELEASE $0D, 1
	OCTAVE 2
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	OCTAVE 3
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 2
	NOTE F#, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	RELEASE $0D, 1
	NOTE E_, 1
	ATTEN 2
	NOTE E_, 1
	ATTEN 0
	OCTAVE 3
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 2
	NOTE F#, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	DUTY 4
	OCTAVE 4
	NOTE D_, 2
	RELEASE 8, 1
	NOTE D_, 2
	RELEASE 2, 0
	DUTY 0
	OCTAVE 3
	NOTE D_, 2
	DUTY 4
	OCTAVE 4
	NOTE D_, 2
	RELEASE 8, 1
	NOTE D_, 2
	RELEASE 2, 0
	DUTY 0
	OCTAVE 3
	NOTE D_, 2
	RELEASE 0, 0
	OCTAVE 4
	DUTY 4
	NOTE D_, 2
	RELEASE 8, 1
	OCTAVE 3
	NOTE B_, 2
	RELEASE 2, 0
	DUTY 0
	OCTAVE 3
	NOTE E_, 2
	RELEASE 0, 0
	DUTY 4
	OCTAVE 3
	NOTE B_, 2
	RELEASE 8, 1
	OCTAVE 4
	NOTE E_, 2
	RELEASE 0, 0
	NOTE E_, 2
	RELEASE 8, 1
	NOTE G#, 2
	DUTY 0
	RELEASE 2, 0
	OCTAVE 3
	NOTE E_, 2
	DUTY 4
	RELEASE 0, 0
	NOTE B_, 2
	DUTY 0
	OCTAVE 3
	NOTE E_, 2
	DUTY 8
	RELEASE $0D, 1
	OCTAVE 2
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	OCTAVE 3
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 2
	NOTE F#, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	RELEASE $0D, 1
	NOTE E_, 1
	ATTEN 2
	NOTE E_, 1
	ATTEN 0
	OCTAVE 3
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 2
	NOTE F#, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	RELEASE 0, 0
	DUTY 4
	OCTAVE 4
	VIBRATO $01, 2, 3
	NOTE D_, 6
	VIBRATO_OFF
	RELEASE 6, 2
	NOTE C_, 2
	REST 2
	RELEASE 0, 0
	VIBRATO $01, 1, 2
	OCTAVE 3
	NOTE B_, 3
	VIBRATO_OFF
	NOTE A_, 3
	RELEASE 0, 0
	OCTAVE 3
	NOTE B_, 2
	RELEASE $0B, 1
	ATTEN 4
	OCTAVE 4
	NOTE G_, 1
	NOTE B_, 1
	RELEASE 0, 0
	ATTEN 0
	NOTE C_, 2
	RELEASE $0B, 1
	ATTEN 4
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	ATTEN 0
	RELEASE 0, 0
	OCTAVE 4
	NOTE C#, 2
	RELEASE $0B, 1
	ATTEN 4
	NOTE G_, 1
	OCTAVE 5
	NOTE C#, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 4
	NOTE D_, 2
	RELEASE $0B, 1
	ATTEN 4
	NOTE G_, 1
	OCTAVE 5
	NOTE D_, 1
	ATTEN 0
	DUTY 8
	RELEASE $0D, 1
	OCTAVE 2
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	OCTAVE 3
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 2
	NOTE F#, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	RELEASE $0D, 1
	NOTE E_, 1
	ATTEN 2
	NOTE E_, 1
	ATTEN 0
	OCTAVE 3
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 2
	NOTE F#, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	DUTY 4
	OCTAVE 4
	NOTE D_, 2
	RELEASE 8, 1
	NOTE D_, 2
	RELEASE 2, 0
	DUTY 0
	OCTAVE 3
	NOTE D_, 2
	DUTY 4
	OCTAVE 4
	NOTE D_, 2
	RELEASE 8, 1
	NOTE D_, 2
	RELEASE 2, 0
	DUTY 0
	OCTAVE 3
	NOTE D_, 2
	RELEASE 0, 0
	OCTAVE 4
	DUTY 4
	NOTE D_, 2
	RELEASE 8, 1
	NOTE D_, 2
	RELEASE 2, 0
	DUTY 0
	OCTAVE 3
	NOTE D_, 2
	DUTY 4
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	RELEASE 8, 1
	NOTE D_, 2
	REST 2
	RELEASE 0, 0
	VIBRATO $03, 3, 3
	NOTE F_, 4
	LOOP_START
	DUTY 8
	OCTAVE 3
	NOTE E_, 2
	RELEASE 8, 1
	DUTY 4
	NOTE C_, 2
	NOTE C_, 2
	RELEASE 0, 0
	LOOP_END $02
	DUTY 8
	NOTE E_, 2
	DUTY 4
	VIBRATO $01, 3, 4
	NOTE C_, 4
	OCTAVE 2
	NOTE B_, 1
	REST 1
	NOTE B_, 9
	REST 1
	NOTE G_, 1
	NOTE B_, 1
	LOOP_START
	DUTY 8
	OCTAVE 3
	NOTE E_, 2
	RELEASE 8, 1
	DUTY 4
	NOTE C_, 2
	NOTE C_, 2
	RELEASE 0, 0
	LOOP_END $02
	DUTY 8
	NOTE E_, 2
	DUTY 4
	VIBRATO $05, 0, 2
	NOTE G_, 1
	VIBRATO $01, 0, 2
	NOTE G_, 3
	VIBRATO_OFF
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	RELEASE 8, 1
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	TRANSPOSE_UP 1
	RELEASE 0, 0
	LOOP_START
	DUTY 8
	OCTAVE 3
	NOTE E_, 2
	RELEASE 8, 1
	DUTY 4
	NOTE C_, 2
	NOTE C_, 2
	RELEASE 0, 0
	LOOP_END $02
	DUTY 8
	NOTE E_, 2
	DUTY 4
	VIBRATO $01, 3, 4
	NOTE C_, 4
	OCTAVE 2
	NOTE B_, 1
	REST 1
	NOTE B_, 9
	REST 1
	NOTE G_, 1
	NOTE B_, 1
	LOOP_START
	DUTY 8
	OCTAVE 3
	NOTE E_, 2
	RELEASE 8, 1
	DUTY 4
	NOTE C_, 2
	NOTE C_, 2
	RELEASE 0, 0
	LOOP_END $02
	TRANSPOSE_UP 0
	DUTY 8
	NOTE F_, 2
	DUTY 4
	VIBRATO $01, 2, 3
	OCTAVE 2
	NOTE G#, 4
	REST 2
	RELEASE 8, 2
	NOTE A_, 2
	REST 2
	NOTE A#, 2
	REST 2
	NOTE B_, 2
	REST 2
	SND_LOOP
	db $FF ; unreachable end

SndE0_Ch3:
	VOICE $05, 1, 2, 0, 0
	TRANSPOSE_UP $0C
	SND_SEGNO
	LOOP2_START
	LOOP_START
	RELEASE 0, 0
	OCTAVE 1
	NOTE A_, 2
	RELEASE $0D, 2
	NOTE C_HI, 2
	LOOP_END $08
	LOOP_START
	RELEASE 0, 0
	NOTE G_, 2
	RELEASE $0D, 2
	NOTE C_HI, 2
	LOOP_END $08
	LOOP_START
	RELEASE 0, 0
	NOTE F_, 2
	RELEASE $0D, 2
	NOTE C_HI, 2
	LOOP_END $08
	LOOP_START
	RELEASE 0, 0
	NOTE G_, 2
	RELEASE $0D, 2
	NOTE C_HI, 2
	LOOP_END $08
	LOOP2_END $02
	LOOP2_START
	OCTAVE 1
	LOOP_START
	RELEASE 0, 0
	NOTE F_, 2
	RELEASE $0D, 2
	NOTE C_HI, 2
	LOOP_END $08
	LOOP_START
	RELEASE 0, 0
	NOTE G_, 2
	RELEASE $0D, 2
	NOTE C_HI, 2
	LOOP_END $05
	RELEASE 0, 0
	NOTE A_, 2
	RELEASE $0D, 2
	NOTE C_HI, 2
	RELEASE 0, 0
	NOTE A#, 2
	RELEASE $0D, 2
	NOTE C_HI, 2
	RELEASE 0, 0
	NOTE B_, 2
	RELEASE $0D, 2
	NOTE C_HI, 2
	LOOP_START
	RELEASE 0, 0
	NOTE F_, 2
	RELEASE $0D, 2
	NOTE C_HI, 2
	LOOP_END $08
	LOOP_START
	RELEASE 0, 0
	NOTE G_, 2
	RELEASE $0D, 2
	NOTE C_HI, 2
	LOOP_END $04
	RELEASE 0, 0
	NOTE E_, 2
	RELEASE $0D, 2
	NOTE C_HI, 2
	RELEASE 0, 0
	NOTE G#, 2
	RELEASE $0D, 2
	NOTE C_HI, 2
	RELEASE 0, 0
	NOTE B_, 2
	RELEASE $0D, 2
	NOTE C_HI, 2
	OCTAVE 2
	RELEASE 0, 0
	NOTE E_, 2
	RELEASE $0D, 2
	NOTE C_HI, 2
	LOOP2_END $02
	OCTAVE 1
	RELEASE 5, 0
	NOTE A_, 2
	RELEASE 8, 1
	NOTE A_, 2
	NOTE C_HI, 2
	RELEASE 0, 0
	NOTE A_, 2
	REST 2
	NOTE A_, 2
	RELEASE $0D, 2
	NOTE C_HI, 2
	RELEASE 5, 0
	NOTE A_, 2
	NOTE A_, 2
	RELEASE 8, 1
	NOTE A_, 2
	RELEASE $0D, 2
	NOTE C_HI, 2
	RELEASE 0, 0
	NOTE A_, 2
	REST 2
	NOTE A_, 2
	VIBRATO $01, 3, 2
	NOTE C_HI, 4
	VIBRATO_OFF
	RELEASE 5, 0
	NOTE A_, 2
	RELEASE 8, 1
	NOTE A_, 2
	NOTE C_HI, 2
	RELEASE 0, 0
	NOTE A_, 2
	REST 2
	NOTE A_, 2
	RELEASE $0D, 2
	NOTE C_HI, 2
	NOTE A_, 2
	RELEASE 5, 2
	OCTAVE 3
	NOTE C_, 2
	VIBRATO_OFF
	OCTAVE 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	TRANSPOSE_UP $0D
	OCTAVE 1
	RELEASE 5, 0
	NOTE A_, 2
	RELEASE 8, 1
	NOTE A_, 2
	NOTE C_HI, 2
	RELEASE 0, 0
	NOTE A_, 2
	REST 2
	NOTE A_, 2
	RELEASE $0D, 2
	NOTE C_HI, 2
	RELEASE 5, 0
	NOTE A_, 2
	NOTE A_, 2
	RELEASE 8, 1
	NOTE A_, 2
	RELEASE $0D, 2
	NOTE C_HI, 2
	RELEASE 0, 0
	NOTE A_, 2
	REST 2
	NOTE A_, 2
	VIBRATO $01, 3, 2
	NOTE C_HI, 4
	VIBRATO_OFF
	RELEASE 5, 0
	NOTE A_, 2
	RELEASE 8, 1
	NOTE A_, 2
	NOTE C_HI, 2
	RELEASE 0, 0
	NOTE A_, 2
	REST 2
	NOTE A_, 2
	RELEASE $0D, 2
	NOTE C_HI, 2
	NOTE A_, 2
	TRANSPOSE_UP $0C
	RELEASE 0, 0
	OCTAVE 3
	NOTE C#, 2
	REST 2
	NOTE D#, 2
	REST 2
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	REST 2
	SND_LOOP

SndE0_Drm:
	LEN_UNIT $05
	SND_SEGNO
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $05
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $02
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $06
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM 3, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $05
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_END $02
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_START
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $02
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM $0A, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $02
	DRUM $0A, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM $0A, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM $0A, 1
	REST 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $02
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 2, 1
	SND_LOOP

SndE1_Ch2:
	VOICE $05, 8, 10, 9, 1
	REST 0
	REST 0
	LOOP2_START
	LOOP_START
	RELEASE 9, 1
	REST 2
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 2
	REST 2
	NOTE F_, 2
	NOTE F_, 2
	LOOP_END $02
	REST 2
	RELEASE 0, 0
	VIBRATO $01, 4, 3
	NOTE F#, 6
	VIBRATO_OFF
	LOOP2_END $02
	VOICE $05, 0, 10, 0, 0
	SND_SEGNO
	LOOP_START
	RELEASE 0, 0
	DUTY 0
	OCTAVE 3
	NOTE F_, 2
	REST 4
	NOTE F_, 2
	REST 4
	NOTE F_, 2
	REST 4
	NOTE F_, 2
	REST 4
	NOTE D_, 2
	VIBRATO $04, 0, 2
	NOTE A_, 4
	VIBRATO_OFF
	LOOP_BREAK $FB
	NOTE G#, 2
	LOOP_END $02
	NOTE B_, 2
	LOOP2_START
	LOOP_START
	DUTY 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE F_, 2
	DUTY 8
	RELEASE 9, 2
	OCTAVE 4
	NOTE C#, 2
	REST 2
	LOOP_END $04
	DUTY 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE D_, 2
	DUTY 8
	VIBRATO $01, 2, 3
	NOTE B_, 6
	VIBRATO_OFF
	LOOP2_END $02
	VOICE $05, 8, 9, 9, 1
	LOOP_START
	REST 2
	RELEASE 9, 1
	OCTAVE 3
	NOTE B_, 2
	RELEASE 0, 0
	VIBRATO $01, 1, 4
	NOTE B_, 4
	VIBRATO_OFF
	NOTE A#, 2
	NOTE B_, 2
	NOTE A#, 2
	VIBRATO $01, 3, 4
	NOTE G#, 11
	REST 1
	VIBRATO_OFF
	NOTE A#, 2
	RELEASE 9, 1
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	REST 2
	NOTE C#, 2
	RELEASE 0, 0
	VIBRATO $01, 1, 4
	NOTE C#, 4
	VIBRATO_OFF
	OCTAVE 3
	NOTE B_, 2
	RELEASE 9, 1
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	RELEASE 0, 0
	LOOP_BREAK $FB
	NOTE C#, 2
	VIBRATO $01, 3, 4
	NOTE C#, 0
	LOOP_END $02
	VIBRATO $01, 3, 4
	NOTE F_, 0
	VIBRATO $03, 0, 3
	NOTE F_, 2
	VIBRATO_OFF
	DETUNE $FF
	LOOP_START
	DUTY 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE C#, 2
	DUTY 8
	RELEASE 9, 2
	OCTAVE 4
	NOTE C#, 2
	REST 2
	DUTY 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE C#, 2
	DUTY 8
	RELEASE 9, 2
	NOTE B_, 2
	REST 2
	DUTY 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE C#, 2
	DUTY 8
	RELEASE 9, 2
	OCTAVE 4
	NOTE C#, 2
	REST 2
	DUTY 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE C#, 2
	DUTY 8
	RELEASE 9, 2
	OCTAVE 4
	NOTE D#, 2
	REST 2
	DUTY 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE D_, 2
	DUTY 8
	VIBRATO $01, 2, 4
	NOTE B_, 6
	VIBRATO_OFF
	DUTY 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE C#, 2
	DUTY 8
	RELEASE 9, 2
	OCTAVE 4
	NOTE C#, 2
	REST 2
	DUTY 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE C#, 2
	DUTY 8
	RELEASE 9, 2
	OCTAVE 4
	NOTE G#, 2
	REST 2
	DUTY 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE C#, 2
	DUTY 8
	RELEASE 9, 2
	OCTAVE 4
	NOTE F#, 2
	REST 2
	DUTY 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE C#, 2
	DUTY 8
	RELEASE 9, 2
	OCTAVE 4
	NOTE F_, 2
	REST 2
	DUTY 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE D_, 2
	DUTY 8
	VIBRATO $01, 2, 4
	OCTAVE 4
	NOTE F#, 6
	VIBRATO_OFF
	LOOP_END $02
	DETUNE $00
	REST 2
	RELEASE 9, 1
	OCTAVE 3
	NOTE B_, 2
	RELEASE 0, 0
	VIBRATO $01, 1, 4
	NOTE B_, 4
	VIBRATO_OFF
	NOTE A#, 2
	NOTE B_, 2
	NOTE A#, 2
	VIBRATO $01, 1, 4
	NOTE G#, 4
	DUTY 0
	OCTAVE 4
	RELEASE 9, 1
	ATTEN 1
	NOTE B_, 2
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	NOTE B_, 4
	VIBRATO_OFF
	NOTE A#, 2
	ATTEN 0
	DUTY 8
	OCTAVE 3
	NOTE A#, 2
	RELEASE 9, 1
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	REST 2
	NOTE C#, 2
	RELEASE 0, 0
	VIBRATO $01, 1, 4
	NOTE C#, 4
	VIBRATO_OFF
	OCTAVE 3
	NOTE B_, 2
	RELEASE 9, 1
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	RELEASE 0, 0
	LOOP_BREAK $FB
	VIBRATO $01, 1, 4
	NOTE C#, 4
	DUTY 0
	RELEASE $0B, 1
	ATTEN 1
	NOTE G#, 2
	NOTE G#, 2
	NOTE A#, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE F#, 2
	RELEASE 0, 0
	VIBRATO $03, 2, 3
	NOTE G#, 2
	ATTEN 0
	VIBRATO_OFF
	RELEASE 9, 1
	DUTY 8
	OCTAVE 3
	NOTE B_, 2
	RELEASE 0, 0
	VIBRATO $01, 1, 4
	NOTE B_, 4
	VIBRATO_OFF
	NOTE A#, 2
	NOTE B_, 2
	NOTE A#, 2
	VIBRATO $01, 1, 4
	NOTE G#, 4
	DUTY 0
	OCTAVE 4
	RELEASE 9, 1
	ATTEN 1
	NOTE G#, 2
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	NOTE G#, 4
	VIBRATO_OFF
	NOTE F#, 2
	ATTEN 0
	DUTY 8
	OCTAVE 3
	NOTE A#, 2
	RELEASE 9, 1
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	REST 2
	NOTE C#, 2
	RELEASE 0, 0
	VIBRATO $01, 1, 4
	NOTE C#, 4
	VIBRATO_OFF
	OCTAVE 3
	NOTE B_, 2
	RELEASE 9, 1
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	RELEASE 0, 0
	LOOP_BREAK $FB
	VIBRATO $01, 1, 4
	NOTE F_, 4
	DUTY 0
	RELEASE $0B, 1
	ATTEN 1
	OCTAVE 5
	NOTE C#, 2
	NOTE C#, 2
	OCTAVE 4
	NOTE B_, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE G#, 2
	ATTEN 0
	RELEASE 0, 0
	VIBRATO $03, 2, 3
	NOTE G#, 2
	VIBRATO_OFF
	DUTY 8
	RELEASE 9, 1
	OCTAVE 4
	NOTE E_, 2
	RELEASE 0, 0
	VIBRATO $01, 1, 4
	NOTE E_, 4
	VIBRATO_OFF
	NOTE D#, 2
	NOTE E_, 2
	NOTE F#, 2
	VIBRATO $01, 3, 4
	NOTE E_, 10
	VIBRATO_OFF
	NOTE C#, 2
	NOTE D#, 2
	RELEASE 9, 1
	NOTE E_, 2
	NOTE F#, 2
	REST 2
	OCTAVE 4
	NOTE E_, 2
	RELEASE 0, 0
	VIBRATO $01, 1, 4
	NOTE E_, 4
	VIBRATO_OFF
	NOTE D#, 2
	NOTE E_, 2
	NOTE F#, 2
	VIBRATO $01, 3, 4
	NOTE E_, 10
	DUTY 0
	VIBRATO_OFF
	OCTAVE 5
	NOTE C#, 2
	OCTAVE 4
	NOTE B_, 2
	RELEASE 9, 1
	NOTE A_, 2
	NOTE G#, 2
	DUTY 8
	REST 2
	OCTAVE 4
	NOTE E_, 2
	RELEASE 0, 0
	VIBRATO $01, 1, 4
	NOTE E_, 4
	VIBRATO_OFF
	NOTE D#, 2
	NOTE E_, 2
	NOTE F#, 2
	VIBRATO $01, 3, 4
	NOTE G#, 12
	DUTY 0
	VIBRATO_OFF
	RELEASE 9, 1
	OCTAVE 5
	NOTE D#, 2
	NOTE E_, 2
	NOTE F#, 2
	DUTY 8
	REST 2
	OCTAVE 4
	NOTE E_, 2
	RELEASE 0, 0
	VIBRATO $01, 1, 4
	NOTE E_, 4
	VIBRATO_OFF
	NOTE D#, 2
	NOTE E_, 2
	NOTE F#, 2
	VIBRATO $04, 0, 3
	NOTE G#, 6
	VIBRATO $01, 1, 3
	OCTAVE 4
	NOTE F#, 4
	NOTE D#, 4
	VIBRATO $03, 2, 3
	NOTE C_, 4
	VIBRATO_OFF
	SND_LOOP

SndE1_Ch1:
	VOICE $05, 12, 11, 10, 2
	REST 0
	REST 0
	LOOP2_START
	LOOP_START
	RELEASE 9, 1
	REST 2
	OCTAVE 3
	NOTE C#, 2
	NOTE C#, 2
	LOOP_END $04
	REST 2
	RELEASE 0, 0
	VIBRATO $01, 4, 4
	NOTE C#, 6
	VIBRATO_OFF
	LOOP2_END $02
	SND_SEGNO
	LOOP2_START
	SND_CALL SndE1_Ch1_6A48
	LOOP2_END $0C
	LOOP_START
	RELEASE 0, 0
	DUTY 4
	OCTAVE 2
	NOTE G#, 2
	DUTY $0C
	RELEASE 9, 1
	OCTAVE 3
	NOTE C#, 2
	NOTE C#, 2
	LOOP_END $04
	RELEASE 0, 0
	DUTY 4
	OCTAVE 2
	NOTE A_, 2
	DUTY 0
	RELEASE 9, 1
	ATTEN 3
	OCTAVE 4
	NOTE G#, 2
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	NOTE G#, 4
	VIBRATO_OFF
	ATTEN 0
	SND_CALL SndE1_Ch1_6A48
	LOOP_START
	RELEASE 0, 0
	DUTY 4
	OCTAVE 2
	NOTE G#, 2
	DUTY $0C
	RELEASE 9, 1
	OCTAVE 3
	NOTE C#, 2
	NOTE C#, 2
	LOOP_END $04
	RELEASE 0, 0
	DUTY 4
	OCTAVE 2
	NOTE A_, 2
	DUTY 0
	ATTEN 3
	OCTAVE 4
	VIBRATO $01, 1, 3
	NOTE F_, 6
	VIBRATO_OFF
	ATTEN 0
	LOOP_START
	RELEASE 0, 0
	DUTY 4
	OCTAVE 2
	NOTE G#, 2
	DUTY $0C
	RELEASE 9, 1
	OCTAVE 3
	NOTE C#, 2
	NOTE C#, 2
	LOOP_END $04
	RELEASE 0, 0
	DUTY 4
	OCTAVE 2
	NOTE G#, 2
	DUTY 0
	RELEASE 9, 1
	OCTAVE 3
	NOTE D#, 2
	NOTE D#, 2
	NOTE C#, 2
	VOICE $05, 0, 10, 9, 1
	LOOP2_START
	ATTEN 0
	OCTAVE 2
	NOTE A_, 1
	ATTEN 4
	NOTE A_, 1
	ATTEN 0
	DUTY 8
	RELEASE 9, 1
	OCTAVE 4
	NOTE C#, 2
	RELEASE 0, 0
	NOTE C#, 2
	DUTY 0
	ATTEN 3
	NOTE G#, 1
	ATTEN 6
	NOTE G#, 1
	ATTEN 0
	DUTY 8
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE A_, 1
	ATTEN 4
	NOTE A_, 1
	ATTEN 0
	OCTAVE 4
	VIBRATO $04, 0, 2
	NOTE E_, 2
	VIBRATO_OFF
	NOTE D#, 2
	VIBRATO $01, 2, 3
	NOTE C#, 10
	VIBRATO_OFF
	LOOP2_END $02
	ATTEN 0
	OCTAVE 2
	NOTE F#, 1
	ATTEN 4
	NOTE F#, 1
	ATTEN 0
	DUTY 8
	RELEASE 9, 1
	OCTAVE 4
	NOTE C#, 2
	RELEASE 0, 0
	NOTE C#, 2
	DUTY 0
	ATTEN 3
	NOTE F#, 1
	ATTEN 6
	NOTE F#, 1
	ATTEN 0
	DUTY 8
	OCTAVE 4
	NOTE C#, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE F#, 1
	ATTEN 4
	NOTE F#, 1
	ATTEN 0
	OCTAVE 4
	VIBRATO $04, 0, 2
	NOTE F#, 2
	VIBRATO_OFF
	NOTE E_, 2
	VIBRATO $01, 2, 3
	NOTE D#, 10
	VIBRATO_OFF
	ATTEN 0
	OCTAVE 2
	NOTE G#, 1
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	DUTY 8
	RELEASE 9, 1
	OCTAVE 4
	NOTE C_, 2
	RELEASE 0, 0
	NOTE C_, 2
	DUTY 0
	ATTEN 3
	NOTE G#, 1
	ATTEN 6
	NOTE G#, 1
	ATTEN 0
	DUTY 8
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	VIBRATO $01, 2, 3
	NOTE E_, 10
	NOTE C_, 4
	OCTAVE 3
	NOTE G#, 4
	VIBRATO_OFF
	VOICE $05, 8, 11, 0, 0
	SND_LOOP

SndE1_Ch3:
	VOICE $05, 1, 2, 2, 0
	LOOP_START
	OCTAVE 3
	NOTE C#, 6
	NOTE D_, 2
	REST 4
	OCTAVE 2
	NOTE B_, 4
	OCTAVE 3
	NOTE C#, 6
	NOTE D_, 6
	NOTE E_, 4
	LOOP_END $03
	SND_SEGNO
	LOOP2_START
	LOOP_START
	WAVE 1
	RELEASE 2, 0
	OCTAVE 3
	NOTE C#, 2
	WAVE 4
	RELEASE 9, 2
	OCTAVE 4
	NOTE F#, 2
	NOTE F#, 2
	WAVE 1
	RELEASE 2, 0
	OCTAVE 3
	NOTE C#, 2
	WAVE 4
	RELEASE 9, 2
	OCTAVE 4
	NOTE F_, 2
	NOTE F_, 2
	WAVE 1
	RELEASE 2, 0
	OCTAVE 3
	LOOP_END $02
	NOTE D_, 2
	VIBRATO $01, 1, 3
	WAVE 4
	RELEASE 0, 0
	OCTAVE 4
	NOTE F#, 6
	VIBRATO_OFF
	LOOP2_END $0F
	LOOP_START
	WAVE 1
	RELEASE 2, 0
	OCTAVE 3
	NOTE C#, 2
	WAVE 4
	RELEASE 9, 2
	OCTAVE 4
	NOTE F#, 2
	NOTE F#, 2
	WAVE 1
	RELEASE 2, 0
	OCTAVE 3
	NOTE C#, 2
	WAVE 4
	RELEASE 9, 2
	OCTAVE 4
	NOTE F_, 2
	NOTE F_, 2
	WAVE 1
	RELEASE 2, 0
	OCTAVE 3
	LOOP_END $02
	NOTE C#, 2
	WAVE 4
	OCTAVE 4
	RELEASE 9, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F_, 2
	LOOP_START
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 2
	WAVE 8
	OCTAVE 4
	NOTE C#, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 2
	WAVE 8
	OCTAVE 6
	NOTE C#, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	OCTAVE 5
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	OCTAVE 4
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	NOTE C#, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 2
	WAVE 8
	OCTAVE 4
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	OCTAVE 6
	NOTE C#, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE E_, 2
	VIBRATO $01, 4, 4
	NOTE A_, 8
	VIBRATO_OFF
	LOOP_END $02
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE B_, 2
	WAVE 8
	OCTAVE 4
	NOTE C#, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE B_, 2
	WAVE 8
	OCTAVE 5
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	OCTAVE 4
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	NOTE C#, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE B_, 2
	WAVE 8
	OCTAVE 4
	NOTE C#, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	OCTAVE 5
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE F#, 2
	VIBRATO $01, 4, 4
	NOTE B_, 8
	VIBRATO_OFF
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 2
	WAVE 8
	OCTAVE 4
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 2
	WAVE 8
	OCTAVE 6
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	OCTAVE 5
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	OCTAVE 4
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	OCTAVE 3
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	OCTAVE 4
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 2
	REST 2
	NOTE C_, 2
	NOTE A_, 4
	OCTAVE 4
	NOTE C_, 4
	SND_LOOP

SndE1_Drm:
	LEN_UNIT $05
	DRUM 9, 6
	DRUM 9, 4
	DRUM 9, 6
	REST 2
	DRUM 9, 6
	DRUM 9, 4
	DRUM 9, 4
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 7, 1
	DRUM 8, 1
	LOOP_END $04
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 7, 1
	DRUM 8, 1
	LOOP_END $04
	DRUM 9, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 3, 1
	DRUM 8, 1
	LOOP_END $07
	SND_SEGNO
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	SND_CALL SndE1_Drm_6A68
	LOOP_END $06
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_END $02
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	SND_CALL SndE1_Drm_6A68
	LOOP_END $03
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	SND_CALL SndE1_Drm_6A68
	LOOP_END $02
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 2, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	SND_CALL SndE1_Drm_6A68
	LOOP_END $03
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_END $09
	DRUM 3, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	SND_CALL SndE1_Drm_6A68
	LOOP_END $06
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	SND_CALL SndE1_Drm_6A68
	LOOP_END $03
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	SND_CALL SndE1_Drm_6A68
	LOOP_END $02
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	SND_LOOP
SndE1_Ch1_6A48:
	LOOP_START
	RELEASE 0, 0
	DUTY 4
	OCTAVE 2
	NOTE G#, 2
	DUTY $0C
	RELEASE 9, 1
	OCTAVE 3
	NOTE C#, 2
	NOTE C#, 2
	LOOP_END $04
	RELEASE 0, 0
	DUTY 4
	OCTAVE 2
	NOTE A_, 2
	DUTY $0C
	VIBRATO $01, 4, 4
	OCTAVE 3
	NOTE C#, 6
	VIBRATO_OFF
	SND_RET
SndE1_Drm_6A68:
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	SND_RET

SndE2_Ch2:
	VOICE $06, 4, 11, 10, 1
	TRANSPOSE_DOWN 1
	LOOP_START
	REST 0
	REST 2
	OCTAVE 3
	NOTE C_, 2
	RELEASE 0, 0
	NOTE C_, 3
	REST 1
	LOOP_BREAK $FB
	OCTAVE 2
	NOTE B_, 3
	RELEASE 9, 1
	NOTE A_, 3
	NOTE A_, 2
	LOOP_END $02
	NOTE D_, 2
	REST 1
	RELEASE $0A, 1
	NOTE D_, 3
	NOTE D_, 2
	SND_SEGNO
	RELEASE 9, 1
	LOOP_START
	DUTY 0
	AUTOPAN 0
	OCTAVE 4
	NOTE E_, 1
	NOTE A_, 2
	NOTE D_, 2
	REST 1
	NOTE G_, 1
	NOTE C_, 2
	REST 1
	NOTE F#, 2
	NOTE D_, 1
	NOTE G_, 2
	NOTE F#, 1
	AUTOPAN 0
	NOTE E_, 1
	NOTE A_, 1
	DUTY 4
	PAN_BOTH 0
	OCTAVE 3
	NOTE C_, 1
	DUTY 0
	PAN_LEFT 0
	OCTAVE 4
	NOTE D_, 1
	DUTY 4
	RELEASE 0, 0
	PAN_BOTH 0
	OCTAVE 3
	NOTE C_, 2
	RELEASE 9, 1
	DUTY 0
	PAN_RIGHT 0
	OCTAVE 4
	NOTE G_, 1
	PAN_LEFT 0
	NOTE C_, 1
	PAN_BOTH 0
	DUTY 4
	RELEASE 0, 0
	LOOP_BREAK $FB
	OCTAVE 2
	NOTE B_, 2
	DUTY 0
	OCTAVE 4
	RELEASE 9, 1
	PAN_RIGHT 0
	NOTE F#, 1
	DUTY 4
	PAN_BOTH 0
	OCTAVE 2
	NOTE A_, 1
	DUTY 0
	AUTOPAN 0
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	DUTY 4
	PAN_BOTH 0
	OCTAVE 2
	NOTE A_, 1
	DUTY 0
	PAN_LEFT 0
	OCTAVE 4
	NOTE F#, 1
	LOOP_END $02
	OCTAVE 3
	NOTE D_, 2
	DUTY 0
	OCTAVE 4
	RELEASE 9, 1
	PAN_RIGHT 0
	NOTE F#, 1
	DUTY 4
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 1
	DUTY 0
	AUTOPAN 0
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	DUTY 4
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 1
	DUTY 0
	PAN_LEFT 0
	OCTAVE 4
	NOTE F#, 1
	DUTY 0
	AUTOPAN 0
	OCTAVE 4
	NOTE E_, 1
	NOTE A_, 2
	NOTE D_, 2
	REST 1
	NOTE G_, 1
	NOTE C_, 2
	REST 1
	NOTE F#, 2
	NOTE D_, 1
	NOTE G_, 2
	NOTE F#, 1
	AUTOPAN 0
	NOTE E_, 1
	NOTE A_, 1
	DUTY 4
	PAN_BOTH 0
	OCTAVE 3
	NOTE C_, 1
	DUTY 0
	PAN_LEFT 0
	OCTAVE 4
	NOTE D_, 1
	DUTY 4
	RELEASE 0, 0
	PAN_BOTH 0
	OCTAVE 3
	NOTE C_, 2
	RELEASE 9, 1
	DUTY 0
	PAN_RIGHT 0
	OCTAVE 4
	NOTE G_, 1
	PAN_LEFT 0
	NOTE C_, 1
	PAN_BOTH 0
	DUTY 4
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 2
	DUTY 0
	OCTAVE 4
	RELEASE 9, 1
	PAN_RIGHT 0
	NOTE F#, 1
	DUTY 4
	PAN_BOTH 0
	OCTAVE 2
	NOTE A_, 1
	DUTY 0
	AUTOPAN 0
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	DUTY 4
	PAN_BOTH 0
	OCTAVE 2
	NOTE A_, 1
	DUTY 0
	PAN_LEFT 0
	OCTAVE 4
	NOTE F#, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE C_, 1
	NOTE C_HI, 2
	NOTE D_, 1
	NOTE C_HI, 2
	NOTE E_, 1
	NOTE C_HI, 2
	NOTE F#, 1
	NOTE C_HI, 2
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	DUTY 4
	OCTAVE 3
	NOTE C_, 1
	DUTY 0
	OCTAVE 4
	NOTE C_, 1
	DUTY 4
	RELEASE 0, 0
	OCTAVE 3
	NOTE C_, 2
	RELEASE 9, 1
	DUTY 0
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE D_, 1
	DUTY 4
	RELEASE 0, 0
	OCTAVE 3
	NOTE D_, 2
	RELEASE 9, 1
	DUTY 0
	OCTAVE 5
	NOTE D_, 1
	DUTY 4
	OCTAVE 3
	NOTE D_, 1
	DUTY 0
	OCTAVE 4
	NOTE D_, 1
	NOTE C_HI, 1
	DUTY 4
	OCTAVE 3
	NOTE D_, 1
	DUTY 0
	NOTE C_HI, 1
	VOICE $06, 8, 9, 0, 0
	PAN_BOTH 0
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	OCTAVE 4
	NOTE E_, 0
	VIBRATO_OFF
	NOTE D_, 2
	RELEASE 9, 1
	NOTE E_, 2
	NOTE F#, 2
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	NOTE G_, 4
	VIBRATO_OFF
	RELEASE 9, 1
	NOTE F#, 2
	NOTE E_, 2
	RELEASE 0, 0
	NOTE D_, 2
	VIBRATO $01, 5, 2
	NOTE E_, 0
	RELEASE 1, 1
	NOTE F#, 8
	RELEASE 0, 0
	VIBRATO_OFF
	NOTE E_, 4
	NOTE F#, 4
	VIBRATO $01, 4, 2
	NOTE G_, 0
	VIBRATO_OFF
	NOTE F#, 2
	NOTE G_, 2
	NOTE A_, 2
	VIBRATO $04, 0, 2
	NOTE B_, 4
	VIBRATO_OFF
	NOTE A_, 2
	RELEASE 9, 1
	NOTE F#, 2
	NOTE A_, 2
	RELEASE 0, 0
	VIBRATO $01, 5, 2
	NOTE G_, 0
	NOTE A_, 8
	VIBRATO_OFF
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 4
	VIBRATO $01, 5, 2
	NOTE B_, 0
	VIBRATO $01, 0, 3
	NOTE B_, 0
	NOTE B_, 0
	NOTE B_, 8
	VIBRATO_OFF
	NOTE A_, 8
	VIBRATO $01, 5, 2
	NOTE B_, 0
	VIBRATO $01, 0, 3
	NOTE B_, 0
	VIBRATO $04, 0, 2
	NOTE A_, 8
	VIBRATO $01, 2, 2
	NOTE G_, 8
	NOTE F#, 8
	VIBRATO_OFF
	NOTE D_, 8
	REST 1
	LOOP_START
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE A#, 1
	NOTE F#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE A#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE G#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	LOOP_BREAK $FB
	NOTE G#, 1
	LOOP_END $04
	SND_LOOP

SndE2_Ch1:
	VOICE $06, 4, 11, 9, 1
	TRANSPOSE_DOWN 1
	LOOP2_START
	LOOP_START
	REST 0
	REST 2
	OCTAVE 3
	NOTE E_, 2
	RELEASE 0, 0
	NOTE E_, 3
	REST 1
	LOOP_BREAK $FB
	NOTE D_, 3
	RELEASE 9, 1
	NOTE C_, 3
	NOTE C_, 2
	LOOP_END $02
	NOTE F#, 2
	REST 1
	RELEASE 9, 1
	NOTE F#, 3
	NOTE F#, 2
	LOOP2_END $02
	SND_SEGNO
	REST 1
	LOOP_START
	REST 1
	TRANSPOSE_DOWN 0
	SND_CALL SndE2_Ch1_7121
	REST 1
	TRANSPOSE_DOWN 3
	SND_CALL SndE2_Ch1_7121
	LOOP_END $02
	REST 3
	TRANSPOSE_DOWN 1
	REST 2
	DUTY 4
	RELEASE 9, 1
	OCTAVE 3
	NOTE E_, 2
	RELEASE 0, 0
	NOTE E_, 3
	REST 1
	NOTE D_, 3
	RELEASE 9, 1
	NOTE C_, 3
	NOTE C_, 2
	REST 1
	SND_CALL SndE2_Ch1_7121
	REST 1
	TRANSPOSE_DOWN 3
	LOOP_START
	SND_CALL SndE2_Ch1_7121
	LOOP_END $02
	REST 1
	SND_CALL SndE2_Ch1_713E
	TRANSPOSE_DOWN 5
	SND_CALL SndE2_Ch1_7121
	TRANSPOSE_DOWN 7
	SND_CALL SndE2_Ch1_7121
	TRANSPOSE_DOWN 2
	LOOP_START
	SND_CALL SndE2_Ch1_713E
	LOOP_END $02
	TRANSPOSE_DOWN 1
	DUTY 4
	REST 2
	OCTAVE 3
	NOTE E_, 2
	RELEASE 0, 0
	NOTE E_, 3
	REST 1
	NOTE F#, 2
	REST 1
	RELEASE 9, 1
	NOTE F#, 3
	NOTE F#, 2
	VOICE $06, 4, 13, 9, 1
	REST 2
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 2
	NOTE E_, 3
	REST 2
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	REST 2
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 2
	NOTE E_, 3
	REST 2
	NOTE F#, 3
	NOTE F#, 3
	VOICE $06, 8, 10, 0, 0
	OCTAVE 4
	NOTE C_, 4
	NOTE D_, 4
	VIBRATO $01, 4, 2
	NOTE E_, 0
	NOTE D_, 8
	VIBRATO_OFF
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 4
	VIBRATO $01, 5, 2
	NOTE E_, 0
	NOTE F#, 8
	VIBRATO_OFF
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	LOOP_START
	OCTAVE 4
	NOTE G#, 3
	VIBRATO $01, 2, 3
	NOTE F#, 3
	VIBRATO_OFF
	NOTE E_, 2
	VIBRATO $01, 2, 3
	NOTE F#, 3
	NOTE E_, 3
	VIBRATO_OFF
	NOTE D_, 2
	NOTE E_, 3
	NOTE D_, 3
	NOTE C_, 2
	VIBRATO $04, 0, 2
	NOTE D_, 3
	VIBRATO_OFF
	NOTE C_, 3
	OCTAVE 3
	NOTE B_, 2
	LOOP_BREAK $FB
	VIBRATO $01, 4, 3
	NOTE A_, 8
	OCTAVE 4
	NOTE C_, 8
	NOTE D_, 8
	VIBRATO_OFF
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	LOOP_END $02
	VIBRATO $01, 4, 2
	OCTAVE 4
	NOTE C_, 0
	NOTE D_, 8
	VOICE $06, 4, 12, 0, 0
	ENVELOPE $0F
	ATTEN 0
	OCTAVE 2
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	ENVELOPE $00
	ATTEN 6
	DUTY 8
	RELEASE 0, 0
	REST 2
	LOOP_START
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE A#, 1
	NOTE F#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE A#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE G#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE E_, 1
	OCTAVE 3
	LOOP_BREAK $FB
	NOTE A#, 1
	OCTAVE 4
	NOTE G#, 1
	LOOP_END $04
	ATTEN 0
	VOICE $06, 4, 11, 9, 1
	LOOP_START
	REST 0
	REST 2
	OCTAVE 3
	NOTE E_, 2
	RELEASE 0, 0
	NOTE E_, 3
	REST 1
	LOOP_BREAK $FB
	NOTE D_, 3
	RELEASE 9, 1
	NOTE C_, 3
	NOTE C_, 2
	LOOP_END $02
	NOTE F#, 2
	REST 1
	RELEASE 9, 1
	NOTE F#, 3
	NOTE F#, 2
	SND_LOOP

SndE2_Ch3:
	VOICE $06, 1, 2, 0, 0
	TRANSPOSE_DOWN 1
	LOOP2_START
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 3
	NOTE G_, 3
	RELEASE 9, 2
	NOTE A_, 2
	REST $0A
	WAVE 0
	OCTAVE 4
	NOTE G_, 2
	RELEASE 0, 0
	NOTE G_, 3
	REST 1
	LOOP_BREAK $FB
	NOTE F#, 3
	RELEASE 9, 2
	NOTE E_, 3
	NOTE E_, 2
	LOOP_END $02
	NOTE A_, 2
	REST 1
	RELEASE 9, 2
	NOTE A_, 3
	NOTE A_, 2
	LOOP2_END $02
	SND_SEGNO
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 3
	NOTE G_, 3
	RELEASE 9, 2
	NOTE A_, 2
	LOOP_BREAK $FB
	REST $0A
	WAVE 0
	OCTAVE 4
	NOTE G_, 2
	RELEASE 0, 0
	NOTE G_, 3
	REST 1
	NOTE F#, 3
	RELEASE 9, 2
	NOTE E_, 3
	NOTE E_, 2
	LOOP_END $02
	RELEASE 0, 0
	NOTE A_, 3
	NOTE B_, 3
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 3
	NOTE A_, 3
	RELEASE 9, 1
	NOTE B_, 2
	RELEASE 0, 0
	NOTE B_, 3
	OCTAVE 3
	NOTE C_, 3
	NOTE D_, 2
	LOOP_START
	NOTE C_, 2
	RELEASE 9, 2
	WAVE 0
	OCTAVE 4
	NOTE G_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE G_, 2
	RELEASE 9, 2
	WAVE 0
	OCTAVE 4
	NOTE G_, 1
	RELEASE 0, 0
	WAVE 1
	NOTE C_, 2
	RELEASE 9, 2
	WAVE 0
	NOTE G_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 2
	RELEASE 9, 2
	WAVE 0
	OCTAVE 4
	NOTE G_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE G_, 1
	RELEASE 9, 2
	WAVE 0
	OCTAVE 4
	NOTE G_, 1
	RELEASE 0, 0
	WAVE 1
	NOTE C_, 2
	LOOP_BREAK $FB
	OCTAVE 2
	NOTE B_, 2
	RELEASE 9, 2
	WAVE 0
	OCTAVE 4
	NOTE F#, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE F#, 2
	RELEASE 9, 2
	WAVE 0
	OCTAVE 4
	NOTE F#, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE B_, 2
	RELEASE 9, 2
	WAVE 0
	OCTAVE 4
	NOTE F#, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE B_, 2
	RELEASE 9, 2
	WAVE 0
	OCTAVE 4
	NOTE F#, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE F#, 1
	RELEASE 9, 2
	WAVE 0
	OCTAVE 4
	NOTE F#, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE B_, 2
	LOOP_END $02
	OCTAVE 3
	NOTE D_, 2
	RELEASE 9, 2
	WAVE 0
	OCTAVE 4
	NOTE A_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE A_, 2
	RELEASE 9, 2
	WAVE 0
	OCTAVE 4
	NOTE A_, 1
	RELEASE 0, 0
	WAVE 1
	NOTE D_, 2
	RELEASE 9, 2
	WAVE 0
	NOTE A_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 2
	RELEASE 9, 2
	WAVE 0
	OCTAVE 4
	NOTE A_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE A_, 1
	RELEASE 9, 2
	WAVE 0
	OCTAVE 4
	NOTE A_, 1
	RELEASE 0, 0
	WAVE 1
	NOTE D_, 2
	OCTAVE 3
	NOTE C_, 2
	RELEASE 9, 1
	WAVE $0B
	OCTAVE 4
	NOTE C_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE G_, 2
	RELEASE 9, 1
	WAVE $0B
	OCTAVE 4
	NOTE E_, 1
	RELEASE 0, 0
	WAVE 1
	NOTE C_, 2
	RELEASE 9, 1
	WAVE $0B
	NOTE G_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 2
	RELEASE 9, 1
	WAVE $0B
	OCTAVE 4
	NOTE E_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE G_, 1
	RELEASE 9, 1
	WAVE $0B
	OCTAVE 4
	NOTE C_, 1
	RELEASE 0, 0
	WAVE 1
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	RELEASE 9, 1
	WAVE $0B
	OCTAVE 4
	NOTE D_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE F#, 2
	RELEASE 9, 1
	WAVE $0B
	OCTAVE 4
	NOTE F#, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE B_, 2
	RELEASE 9, 1
	WAVE $0B
	OCTAVE 4
	NOTE A_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE B_, 2
	RELEASE 9, 1
	WAVE $0B
	OCTAVE 4
	NOTE F#, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE F#, 1
	RELEASE 9, 1
	WAVE $0B
	OCTAVE 4
	NOTE D_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE B_, 2
	NOTE C_, 2
	RELEASE 9, 1
	WAVE $0B
	OCTAVE 4
	NOTE E_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE G_, 2
	RELEASE 9, 1
	WAVE $0B
	OCTAVE 4
	NOTE G_, 1
	RELEASE 0, 0
	WAVE 1
	NOTE C_, 2
	RELEASE 9, 1
	WAVE $0B
	NOTE B_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 2
	RELEASE 9, 1
	WAVE $0B
	OCTAVE 4
	NOTE G_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE G_, 1
	RELEASE 9, 1
	WAVE $0B
	OCTAVE 4
	NOTE E_, 1
	RELEASE 0, 0
	WAVE 1
	NOTE C_, 2
	OCTAVE 3
	NOTE D_, 2
	RELEASE 9, 1
	WAVE $0B
	OCTAVE 4
	NOTE F#, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE A_, 2
	RELEASE 9, 1
	WAVE $0B
	OCTAVE 4
	NOTE A_, 1
	RELEASE 0, 0
	WAVE 1
	NOTE D_, 2
	RELEASE 9, 1
	WAVE $0B
	NOTE F#, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 2
	RELEASE 9, 1
	WAVE $0B
	OCTAVE 4
	NOTE A_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE A_, 1
	RELEASE 9, 1
	WAVE $0B
	OCTAVE 4
	NOTE F#, 1
	RELEASE 0, 0
	WAVE 1
	NOTE D_, 2
	LOOP_START
	OCTAVE 3
	NOTE E_, 2
	RELEASE 9, 1
	WAVE 6
	PAN_LEFT 0
	OCTAVE 4
	NOTE G#, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE B_, 2
	RELEASE 9, 1
	WAVE 6
	PAN_RIGHT 0
	OCTAVE 5
	NOTE G#, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 4
	NOTE E_, 2
	RELEASE 9, 1
	WAVE 6
	PAN_LEFT 0
	NOTE G#, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE E_, 2
	RELEASE 9, 1
	WAVE 6
	PAN_RIGHT 0
	OCTAVE 5
	NOTE G#, 1
	RELEASE 0, 0
	WAVE 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE B_, 1
	RELEASE 9, 1
	WAVE 6
	PAN_LEFT 0
	OCTAVE 4
	NOTE G#, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	NOTE E_, 2
	SND_CALL SndE2_Ch3_7151
	OCTAVE 3
	NOTE C_, 2
	RELEASE 9, 1
	WAVE 6
	PAN_LEFT 0
	OCTAVE 4
	NOTE E_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE G_, 2
	RELEASE 9, 1
	WAVE 6
	PAN_RIGHT 0
	OCTAVE 5
	NOTE E_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 4
	NOTE C_, 2
	RELEASE 9, 1
	WAVE 6
	PAN_LEFT 0
	NOTE E_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 2
	RELEASE 9, 1
	WAVE 6
	PAN_RIGHT 0
	OCTAVE 5
	NOTE E_, 1
	RELEASE 0, 0
	WAVE 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE G_, 1
	RELEASE 9, 1
	WAVE 6
	PAN_LEFT 0
	OCTAVE 4
	NOTE E_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	NOTE C_, 2
	LOOP_BREAK $FB
	SND_CALL SndE2_Ch3_7151
	LOOP_END $02
	OCTAVE 3
	NOTE D_, 2
	RELEASE 9, 1
	WAVE 6
	PAN_LEFT 0
	OCTAVE 4
	NOTE F#, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE A_, 2
	RELEASE 9, 1
	WAVE 6
	PAN_RIGHT 0
	OCTAVE 4
	NOTE A_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	NOTE D_, 2
	RELEASE 4, 0
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	RELEASE 0, 0
	RELEASE 9, 1
	WAVE 3
	ATTEN 1
	LOOP_START
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	NOTE A#, 1
	NOTE F#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 5
	NOTE E_, 1
	NOTE A#, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 5
	NOTE G#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE G#, 1
	LOOP_END $04
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 2
	NOTE A_, 3
	NOTE G_, 3
	RELEASE 9, 1
	NOTE A_, 2
	REST $0A
	WAVE 0
	OCTAVE 4
	NOTE G_, 2
	RELEASE 0, 0
	NOTE G_, 3
	REST 1
	LOOP_BREAK $FB
	NOTE F#, 3
	RELEASE 9, 1
	NOTE E_, 3
	NOTE E_, 2
	LOOP_END $02
	NOTE A_, 2
	REST 1
	RELEASE 9, 1
	NOTE A_, 3
	NOTE A_, 2
	SND_LOOP

SndE2_Drm:
	LEN_UNIT $06
	LOOP_START
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	LOOP_END $10
	SND_SEGNO
	LOOP_START
	DRUM 9, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP_END $0C
	LOOP_START
	DRUM 3, 1
	LOOP_END $10
	DRUM $0C, 2
	DRUM $0A, 2
	LOOP_START
	DRUM 9, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP_END $0F
	DRUM $0C, 2
	DRUM $0A, 2
	LOOP_START
	DRUM 9, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP_END $0B
	DRUM 9, 1
	DRUM 7, 1
	DRUM 3, 2
	DRUM 9, 1
	DRUM 3, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 7, 1
	DRUM 3, 2
	DRUM 3, 1
	DRUM 2, 1
	DRUM 9, 2
	DRUM $0C, 2
	DRUM $0A, 2
	LOOP_START
	DRUM 9, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP_END $0C
	DRUM 9, 1
	DRUM 3, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 7, 1
	DRUM $0A, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM $0C, 2
	DRUM $0A, 2
	LOOP_START
	DRUM 9, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP_END $0B
	DRUM 9, 1
	DRUM 3, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM $0A, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM $0C, 2
	DRUM $0A, 2
	LOOP_START
	DRUM 9, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP_END $0B
	LOOP_START
	DRUM 3, 1
	LOOP_END $10
	DRUM $0C, 2
	DRUM $0A, 2
	LOOP_START
	DRUM 9, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP_END $0F
	SND_LOOP
SndE2_Ch1_7121:
	LEN_UNIT $01
	DUTY 8
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	ATTEN 1
	NOTE A_, 1
	NOTE G#, 1
	ATTEN 2
	NOTE G_, 1
	NOTE F#, 1
	ATTEN 3
	NOTE F_, 1
	NOTE E_, 1
	ATTEN 4
	NOTE D_, 1
	ATTEN 5
	NOTE C_, 1
	ATTEN 6
	OCTAVE 2
	NOTE A#, 1
	ATTEN 7
	NOTE G#, 1
	ATTEN 0
	LEN_UNIT $06
	SND_RET
SndE2_Ch1_713E:
	LEN_UNIT $01
	OCTAVE 3
	ATTEN 0
	NOTE G#, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 2
	NOTE F#, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 5
	NOTE D#, 1
	ATTEN 6
	NOTE C#, 1
	ATTEN 0
	LEN_UNIT $06
	SND_RET
SndE2_Ch3_7151:
	OCTAVE 3
	NOTE D_, 2
	RELEASE 9, 1
	WAVE 6
	PAN_LEFT 0
	OCTAVE 4
	NOTE F#, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE A_, 2
	RELEASE 9, 1
	WAVE 6
	PAN_RIGHT 0
	OCTAVE 5
	NOTE F#, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 4
	NOTE D_, 2
	RELEASE 9, 1
	WAVE 6
	PAN_LEFT 0
	NOTE F#, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 2
	RELEASE 9, 1
	WAVE 6
	PAN_RIGHT 0
	OCTAVE 5
	NOTE F#, 1
	RELEASE 0, 0
	WAVE 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE A_, 1
	RELEASE 9, 1
	WAVE 6
	PAN_LEFT 0
	OCTAVE 4
	NOTE F#, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	NOTE D_, 2
	SND_RET

SndE3_Ch2:
	TEMPO $90
	SND_SEGNO
	VOICE $07, 8, 10, 0, 0
	DETUNE $FC
	RELEASE $0B, 1
	ATTEN 4
	REST 1
	DUTY 8
	OCTAVE 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	RELEASE 0, 0
	NOTE C_, 1
	RELEASE $0B, 1
	NOTE D_, 1
	REST 1
	RELEASE 0, 0
	NOTE C_, 2
	DUTY 4
	DUTY_STEP 8, 1
	ATTEN 0
	DETUNE $00
	OCTAVE 3
	RELEASE $0A, 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	RELEASE $0B, 1
	DUTY_STEP 0, 0
	ATTEN 4
	REST 1
	DUTY 8
	OCTAVE 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	RELEASE 0, 0
	NOTE C_, 1
	RELEASE $0B, 1
	NOTE D_, 1
	REST 1
	RELEASE 0, 0
	NOTE C_, 2
	DUTY 4
	DUTY_STEP 8, 1
	ATTEN 0
	DETUNE $00
	RELEASE 9, 1
	OCTAVE 3
	NOTE G_, 2
	RELEASE $0A, 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE A_, 1
	REST 1
	DUTY_STEP 0, 0
	VOICE $07, 0, 7, 0, 0
	OCTAVE 4
	NOTE D_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 5
	VIBRATO $01, 5, 3
	NOTE D_, 0
	NOTE C_, 0
	OCTAVE 4
	NOTE A#, 0
	NOTE A_, 12
	VIBRATO $03, 0, 2
	NOTE A_, 4
	VIBRATO_OFF
	VOICE $07, 0, 10, 9, 1
	DUTY_STEP 8, 1
	LOOP2_START
	LOOP_START
	REST 2
	NOTE G_, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 3
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 6
	NOTE F_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 4
	NOTE D_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 3
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 3
	NOTE A#, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 3
	NOTE A_, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 3
	NOTE A#, 1
	ATTEN 0
	OCTAVE 5
	NOTE C_, 1
	ATTEN 3
	NOTE C_, 1
	LOOP_BREAK $FB
	ATTEN 0
	OCTAVE 4
	NOTE A_, 1
	ATTEN 3
	NOTE A_, 1
	ATTEN 4
	NOTE A_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 3
	NOTE F_, 1
	ATTEN 0
	LOOP_END $02
	ATTEN 0
	OCTAVE 4
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	NOTE C_HI, 1
	ATTEN 3
	NOTE C_HI, 1
	LOOP_BREAK $FC
	ATTEN 0
	NOTE A_, 1
	ATTEN 3
	NOTE A_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 3
	NOTE F_, 1
	ATTEN 0
	LOOP2_END $02
	ATTEN 0
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	NOTE C_HI, 1
	ATTEN 3
	NOTE C_HI, 1
	ATTEN 0
	VOICE $07, 8, 11, 10, 1
	SND_CALL SndE3_Ch1_78AE
	REST 4
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE F_, 2
	SND_CALL SndE3_Ch1_78D9
	DUTY 0
	REST 4
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE F_, 2
	SND_CALL SndE3_Ch1_78AE
	ATTEN 2
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE C_HI, 1
	ATTEN 0
	SND_CALL SndE3_Ch1_78D9
	REST 2
	RELEASE 9, 1
	NOTE C_HI, 2
	DUTY 8
	REST 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE A_, 1
	VOICE $07, 8, 10, 0, 0
	DUTY_STEP 0, 0
	VIBRATO $01, 3, 3
	ATTEN 3
	OCTAVE 4
	NOTE G_, 10
	NOTE F_, 4
	VIBRATO_OFF
	NOTE G_, 2
	VIBRATO $04, 0, 2
	NOTE A_, 3
	VIBRATO_OFF
	NOTE G_, 3
	NOTE A_, 2
	VIBRATO $01, 3, 3
	RELEASE 3, 2
	NOTE A#, 8
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	OCTAVE 5
	NOTE D_, 2
	VIBRATO $01, 3, 3
	NOTE D_, 8
	VIBRATO_OFF
	NOTE C_, 4
	OCTAVE 4
	NOTE A#, 2
	OCTAVE 5
	NOTE C_, 3
	OCTAVE 4
	NOTE A#, 3
	NOTE A_, 2
	VIBRATO $01, 3, 3
	RELEASE 3, 2
	NOTE G_, 8
	RELEASE 0, 0
	VIBRATO_OFF
	OCTAVE 5
	NOTE D_, 2
	VIBRATO $01, 3, 3
	NOTE D_, 8
	VIBRATO_OFF
	NOTE C_, 4
	NOTE D_, 2
	VIBRATO $04, 0, 1
	NOTE D#, 3
	VIBRATO_OFF
	NOTE D_, 3
	NOTE C_, 2
	OCTAVE 4
	VIBRATO $01, 5, 3
	RELEASE 3, 2
	NOTE A#, 8
	RELEASE 0, 0
	NOTE G_, 10
	VIBRATO_OFF
	NOTE F_, 4
	NOTE G_, 2
	NOTE A_, 3
	NOTE G_, 3
	NOTE F_, 2
	VIBRATO $01, 3, 3
	NOTE G_, 5
	VIBRATO $03, 0, 2
	NOTE G_, 3
	VIBRATO_OFF
	ATTEN 0
	SND_LOOP

SndE3_Ch1:
	SND_SEGNO
	VOICE $07, 4, 11, 9, 1
	REST 0
	REST 0
	REST 0
	REST $0B
	DUTY_STEP 8, 1
	ATTEN 2
	OCTAVE 3
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	LOOP_START
	ATTEN 0
	RELEASE $0B, 1
	DUTY_STEP 0, 0
	DETUNE $03
	ATTEN 0
	OCTAVE 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	RELEASE 0, 0
	NOTE C_, 1
	RELEASE $0B, 1
	NOTE D_, 1
	REST 1
	RELEASE 0, 0
	NOTE C_, 3
	RELEASE 9, 1
	DUTY_STEP 8, 1
	ATTEN 2
	OCTAVE 3
	DETUNE $00
	LOOP_BREAK $FB
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	LOOP_END $02
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	ATTEN 0
	VOICE $07, 8, 14, 11, 1
	LOOP_START
	DUTY $0C
	ATTEN 5
	DUTY_STEP 0, 0
	RELEASE $0B, 1
	NOTE G_, 1
	DUTY 8
	ATTEN 0
	OCTAVE 2
	NOTE A#, 1
	DUTY $0C
	ATTEN 5
	OCTAVE 3
	NOTE G_, 1
	DUTY 8
	ATTEN 0
	OCTAVE 2
	NOTE A#, 1
	DUTY $0C
	ATTEN 5
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	DUTY 8
	ATTEN 0
	NOTE C_, 1
	DUTY $0C
	ATTEN 5
	NOTE G_, 1
	NOTE G_, 1
	DUTY 8
	ATTEN 0
	NOTE D_, 1
	DUTY $0C
	ATTEN 5
	NOTE G_, 1
	NOTE G_, 1
	DUTY 8
	ATTEN 0
	NOTE C_, 1
	DUTY $0C
	ATTEN 5
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	DUTY 8
	ATTEN 0
	OCTAVE 2
	NOTE A#, 1
	DUTY $0C
	ATTEN 5
	OCTAVE 3
	NOTE G_, 1
	DUTY 8
	ATTEN 0
	OCTAVE 2
	NOTE A#, 1
	DUTY $0C
	ATTEN 5
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 1
	DUTY 8
	ATTEN 0
	NOTE C_, 2
	LOOP_BREAK $FB
	DUTY $0C
	ATTEN 5
	NOTE A_, 1
	DUTY 8
	ATTEN 0
	NOTE C_, 1
	DUTY $0C
	ATTEN 5
	NOTE A_, 1
	NOTE A_, 1
	DUTY 8
	ATTEN 0
	NOTE C_, 1
	DUTY $0C
	ATTEN 5
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	LOOP_END $04
	REST 1
	DUTY 8
	ATTEN 0
	NOTE C_, 1
	RELEASE 0, 0
	DUTY $0C
	ATTEN 5
	NOTE A_, 2
	DUTY 8
	ATTEN 0
	NOTE C_, 2
	DUTY $0C
	ATTEN 5
	NOTE A_, 2
	ATTEN 3
	RELEASE 9, 1
	DUTY_STEP 8, 1
	TRANSPOSE_DOWN 5
	SND_CALL SndE3_Ch1_78AE
	REST 4
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE F_, 2
	SND_CALL SndE3_Ch1_78D9
	DUTY 0
	REST 4
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE F_, 2
	SND_CALL SndE3_Ch1_78AE
	TRANSPOSE_DOWN 0
	ATTEN 6
	OCTAVE 3
	NOTE D#, 1
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE C_HI, 1
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE C#, 1
	NOTE C_HI, 1
	NOTE C#, 1
	NOTE C_HI, 1
	ATTEN 3
	TRANSPOSE_DOWN 5
	SND_CALL SndE3_Ch1_78D9
	REST 2
	NOTE C_HI, 2
	TRANSPOSE_DOWN 0
	DUTY 4
	DUTY_STEP 0, 0
	RELEASE 0, 0
	REST 1
	OCTAVE 2
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A_, 1
	RELEASE $0B, 1
	DUTY $0C
	ATTEN 4
	OCTAVE 3
	NOTE D#, 1
	DUTY 8
	ATTEN 0
	OCTAVE 2
	NOTE A#, 1
	DUTY $0C
	ATTEN 4
	OCTAVE 3
	NOTE G_, 1
	DUTY 8
	ATTEN 0
	OCTAVE 2
	NOTE A#, 1
	DUTY $0C
	ATTEN 4
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	DUTY 8
	ATTEN 0
	OCTAVE 2
	NOTE A#, 2
	DUTY $0C
	ATTEN 4
	OCTAVE 3
	NOTE D#, 1
	DUTY 8
	ATTEN 0
	NOTE D_, 1
	DUTY $0C
	ATTEN 4
	NOTE F_, 1
	NOTE G_, 1
	DUTY 8
	ATTEN 0
	OCTAVE 2
	NOTE A#, 1
	DUTY $0C
	ATTEN 4
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	DUTY $0C
	ATTEN 4
	OCTAVE 3
	NOTE F_, 1
	DUTY 8
	ATTEN 0
	NOTE C_, 1
	DUTY $0C
	ATTEN 4
	OCTAVE 4
	NOTE F_, 1
	DUTY 8
	ATTEN 0
	OCTAVE 3
	NOTE C_, 1
	DUTY $0C
	ATTEN 4
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	DUTY 8
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	DUTY $0C
	ATTEN 4
	OCTAVE 4
	NOTE D_, 1
	DUTY 8
	ATTEN 0
	OCTAVE 3
	NOTE D_, 1
	DUTY $0C
	ATTEN 4
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	DUTY 8
	ATTEN 0
	NOTE D_, 1
	DUTY $0C
	ATTEN 4
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	DUTY $0C
	ATTEN 4
	OCTAVE 3
	NOTE A#, 1
	DUTY 8
	ATTEN 0
	OCTAVE 2
	NOTE A#, 1
	DUTY $0C
	ATTEN 4
	OCTAVE 3
	NOTE A#, 1
	DUTY 8
	ATTEN 0
	OCTAVE 2
	NOTE A#, 1
	DUTY $0C
	ATTEN 4
	OCTAVE 3
	NOTE A_, 1
	NOTE A#, 1
	DUTY 8
	ATTEN 0
	OCTAVE 2
	NOTE A#, 2
	DUTY $0C
	ATTEN 4
	OCTAVE 3
	NOTE A#, 1
	DUTY 8
	ATTEN 0
	NOTE D_, 1
	DUTY $0C
	ATTEN 4
	NOTE A_, 1
	NOTE A#, 1
	DUTY 8
	ATTEN 0
	OCTAVE 2
	NOTE A#, 1
	DUTY $0C
	ATTEN 4
	RELEASE 0, 0
	VIBRATO $01, 0, 2
	OCTAVE 3
	NOTE G_, 3
	VIBRATO_OFF
	RELEASE $0B, 1
	DUTY $0C
	ATTEN 4
	OCTAVE 3
	NOTE A_, 1
	DUTY 8
	ATTEN 0
	NOTE C_, 1
	DUTY $0C
	ATTEN 4
	NOTE A_, 1
	DUTY 8
	ATTEN 0
	NOTE C_, 1
	DUTY $0C
	ATTEN 4
	NOTE G_, 1
	NOTE A_, 1
	DUTY 8
	ATTEN 0
	NOTE C_, 2
	DUTY $0C
	ATTEN 4
	NOTE G_, 1
	DUTY 8
	ATTEN 0
	NOTE D_, 1
	DUTY $0C
	ATTEN 4
	NOTE A_, 1
	NOTE A#, 1
	DUTY 8
	ATTEN 0
	NOTE D_, 1
	DUTY $0C
	ATTEN 4
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	LOOP_START
	DUTY $0C
	ATTEN 4
	RELEASE 0, 0
	VIBRATO $01, 4, 3
	OCTAVE 3
	NOTE A#, 9
	VIBRATO_OFF
	RELEASE $0B, 1
	DUTY 8
	ATTEN 0
	NOTE D_, 1
	DUTY $0C
	ATTEN 4
	RELEASE 0, 0
	NOTE A_, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 0
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D_, 1
	DUTY $0C
	ATTEN 4
	RELEASE 0, 0
	LOOP_BREAK $FB
	NOTE G_, 2
	RELEASE $0B, 1
	DUTY $0C
	ATTEN 4
	NOTE A_, 1
	DUTY 8
	ATTEN 0
	NOTE C_, 1
	DUTY $0C
	ATTEN 4
	NOTE A#, 1
	DUTY 8
	ATTEN 0
	NOTE C_, 1
	DUTY $0C
	ATTEN 4
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	DUTY 8
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	DUTY $0C
	ATTEN 4
	NOTE G_, 1
	DUTY 8
	ATTEN 0
	OCTAVE 3
	NOTE D_, 1
	DUTY $0C
	ATTEN 4
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	DUTY 8
	ATTEN 0
	NOTE D_, 1
	DUTY $0C
	ATTEN 4
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE C_HI, 1
	LOOP_END $02
	NOTE A#, 2
	RELEASE $0B, 1
	DUTY $0C
	ATTEN 4
	OCTAVE 4
	NOTE C_, 1
	DUTY 8
	ATTEN 0
	OCTAVE 3
	NOTE C_, 1
	DUTY $0C
	ATTEN 4
	NOTE A#, 1
	DUTY 8
	ATTEN 0
	NOTE C_, 1
	DUTY $0C
	ATTEN 4
	RELEASE 0, 0
	NOTE A_, 2
	DUTY 8
	ATTEN 0
	RELEASE $0B, 1
	NOTE C_, 2
	DUTY 8
	ATTEN 4
	RELEASE 0, 0
	VIBRATO $04, 0, 1
	OCTAVE 4
	NOTE D_, 1
	RELEASE $0D, 1
	VIBRATO_OFF
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	RELEASE 0, 0
	NOTE A#, 1
	RELEASE $0D, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	ATTEN 0
	SND_LOOP

SndE3_Ch3:
	SND_SEGNO
	VOICE $07, 1, 2, 0, 0
	LOOP_START
	RELEASE $0B, 1
	WAVE 1
	OCTAVE 3
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	RELEASE 0, 0
	NOTE C_, 1
	RELEASE $0B, 1
	NOTE D_, 1
	REST 1
	RELEASE 0, 0
	NOTE C_, 3
	RELEASE $0B, 1
	WAVE 4
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	LOOP_BREAK $FB
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	LOOP_END $02
	NOTE D#, 2
	NOTE D#, 1
	NOTE D#, 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	LOOP_START
	RELEASE $0B, 1
	WAVE 1
	OCTAVE 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	RELEASE 0, 0
	NOTE C_, 1
	RELEASE $0B, 1
	NOTE D_, 1
	REST 1
	RELEASE 0, 0
	NOTE C_, 3
	RELEASE $0B, 1
	WAVE 4
	OCTAVE 4
	LOOP_BREAK $FB
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	LOOP_END $02
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	LOOP_START
	OCTAVE 2
	NOTE G_, 1
	WAVE 0
	OCTAVE 4
	NOTE D_, 1
	WAVE 1
	OCTAVE 2
	NOTE G_, 1
	WAVE 0
	OCTAVE 4
	NOTE D_, 1
	WAVE 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	WAVE 0
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	WAVE 0
	OCTAVE 4
	NOTE F_, 1
	WAVE 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	WAVE 0
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	OCTAVE 2
	NOTE G_, 1
	RELEASE 0, 0
	NOTE C_HI, 2
	RELEASE $0B, 1
	OCTAVE 2
	NOTE D#, 1
	WAVE 0
	OCTAVE 4
	NOTE D_, 1
	WAVE 1
	OCTAVE 2
	NOTE D#, 1
	WAVE 0
	OCTAVE 4
	NOTE D_, 1
	WAVE 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	WAVE 0
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	LOOP_BREAK $FB
	NOTE F_, 1
	WAVE 0
	OCTAVE 4
	NOTE F_, 1
	WAVE 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	WAVE 0
	OCTAVE 4
	NOTE F_, 1
	WAVE 1
	OCTAVE 2
	NOTE F_, 1
	RELEASE 0, 0
	NOTE C_HI, 2
	RELEASE $0B, 1
	LOOP_END $04
	NOTE F#, 1
	WAVE 0
	OCTAVE 4
	NOTE F_, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 2
	NOTE C_HI, 2
	WAVE 4
	VIBRATO $01, 4, 4
	OCTAVE 5
	NOTE G_, 0
	VIBRATO_OFF
	WAVE 3
	RELEASE $0B, 1
	AUTOPAN 0
	OCTAVE 3
	NOTE C#, 1
	NOTE G#, 2
	NOTE D_, 1
	NOTE A_, 2
	NOTE D#, 1
	NOTE A#, 2
	NOTE F_, 1
	NOTE B_, 2
	NOTE F#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C#, 1
	PAN_BOTH 0
	WAVE $0D
	RELEASE 0, 0
	VIBRATO $0C, 0, 1
	OCTAVE 6
	NOTE G_, 0
	VIBRATO $0D, 0, 1
	OCTAVE 4
	NOTE A#, 0
	VIBRATO_OFF
	WAVE 1
	RELEASE $0B, 1
	OCTAVE 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 1
	NOTE D_, 1
	REST 1
	NOTE D_, 2
	NOTE C_, 1
	REST 1
	RELEASE 0, 0
	NOTE C_, 3
	RELEASE $0B, 1
	NOTE D_, 2
	NOTE D_, 1
	NOTE C_, 1
	REST 1
	NOTE D_, 2
	NOTE C_, 1
	NOTE D_, 2
	NOTE C_, 1
	NOTE D_, 1
	REST 1
	RELEASE 0, 0
	NOTE C_, 3
	RELEASE $0B, 1
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE C_, 1
	NOTE D_, 1
	REST 1
	NOTE D_, 2
	NOTE C_, 1
	NOTE D_, 2
	NOTE A#, 2
	RELEASE 0, 0
	OCTAVE 3
	NOTE C_, 3
	RELEASE $0B, 1
	OCTAVE 2
	NOTE G_, 1
	REST 2
	NOTE G_, 2
	WAVE $0B
	REST 1
	RELEASE 0, 0
	OCTAVE 4
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	RELEASE $0B, 1
	LOOP_START
	OCTAVE 2
	WAVE 1
	NOTE D#, 1
	WAVE 0
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	OCTAVE 2
	NOTE D#, 1
	WAVE 0
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	WAVE 0
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	WAVE 0
	OCTAVE 4
	NOTE F_, 1
	WAVE 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	WAVE 0
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	OCTAVE 2
	NOTE D#, 1
	RELEASE 0, 0
	NOTE C_HI, 2
	RELEASE $0B, 1
	OCTAVE 2
	WAVE 1
	NOTE F_, 1
	WAVE 0
	OCTAVE 4
	NOTE F_, 1
	WAVE 1
	OCTAVE 2
	NOTE F_, 1
	WAVE 0
	OCTAVE 4
	NOTE F_, 1
	WAVE 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	WAVE 0
	OCTAVE 4
	NOTE F_, 1
	WAVE 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE G_, 1
	WAVE 0
	OCTAVE 4
	NOTE F_, 1
	WAVE 1
	OCTAVE 3
	LOOP_BREAK $FB
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	WAVE 0
	OCTAVE 4
	NOTE F_, 1
	WAVE 1
	OCTAVE 2
	NOTE G_, 1
	RELEASE 0, 0
	NOTE C_HI, 2
	RELEASE $0B, 1
	LOOP_END $04
	RELEASE 0, 0
	NOTE G_, 2
	RELEASE $0B, 1
	OCTAVE 2
	NOTE G_, 1
	WAVE 0
	OCTAVE 4
	NOTE F_, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE G_, 2
	SND_LOOP

SndE3_Drm:
	LEN_UNIT $07
	SND_SEGNO
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 7, 1
	LOOP_BREAK $FB
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_END $07
	DRUM 3, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_BREAK $FB
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_END $03
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_BREAK $FB
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_END $03
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_BREAK $FB
	DRUM 9, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_END $07
	DRUM $0A, 2
	REST 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	LOOP_BREAK $FB
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_END $03
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_END $03
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	SND_LOOP
SndE3_Ch1_78AE:
	DUTY 8
	RELEASE $0A, 1
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	RELEASE 0, 0
	NOTE F_, 2
	NOTE C_, 1
	VIBRATO $01, 1, 3
	NOTE D_, 2
	VIBRATO $04, 0, 3
	RELEASE 9, 1
	NOTE G_, 2
	VIBRATO_OFF
	NOTE G_, 1
	NOTE F_, 2
	LOOP_BREAK $FB
	NOTE C_, 2
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	NOTE D_, 3
	VIBRATO_OFF
	RELEASE 9, 1
	OCTAVE 2
	NOTE G_, 1
	DUTY 0
	SND_RET
SndE3_Ch1_78D9:
	DUTY 8
	RELEASE 9, 1
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	RELEASE 0, 0
	NOTE F_, 2
	NOTE C_, 1
	VIBRATO $01, 1, 3
	NOTE D_, 2
	VIBRATO $04, 0, 3
	RELEASE 9, 1
	NOTE G_, 2
	VIBRATO_OFF
	NOTE G_, 1
	NOTE F_, 2
	LOOP_BREAK $FB
	NOTE A#, 2
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	OCTAVE 4
	NOTE C_, 3
	VIBRATO_OFF
	RELEASE 9, 1
	OCTAVE 3
	NOTE G_, 1
	SND_RET

SECTION "Sound bank $0E", ROMX[$4000], BANK[$0E]

SndD8_Ch1:
	VOICE $04, 0, 9, 0, 0
	VIBRATO_OFF
	TRANSPOSE_UP $0C
	REST 4
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE B_, 2
	REST 4
	OCTAVE 1
	NOTE C#, 2
	REST 4
	NOTE C#, 2
	REST 4
	NOTE C#, 2
	REST 2
	REST 4
	OCTAVE 3
	NOTE E_, 2
	REST 4
	NOTE E_, 2
	REST 4
	NOTE E_, 2
	REST 6
	REST 8
	SND_SEGNO
	OCTAVE 3
	NOTE C#, 2
	REST 2
	NOTE C#, 2
	REST 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 2
	REST 2
	OCTAVE 2
	NOTE B_, 2
	REST 2
	OCTAVE 3
	NOTE C#, 2
	REST 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 2
	REST 2
	NOTE C#, 2
	REST 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 2
	REST 2
	OCTAVE 2
	NOTE B_, 2
	REST 2
	OCTAVE 3
	NOTE C#, 2
	REST 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 4
	OCTAVE 2
	NOTE B_, 4
	OCTAVE 3
	NOTE D_, 2
	REST 2
	NOTE D_, 2
	REST 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	REST 2
	OCTAVE 2
	NOTE B_, 2
	REST 2
	OCTAVE 3
	NOTE D_, 2
	REST 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE F_, 2
	REST 2
	NOTE F_, 2
	REST 2
	NOTE E_, 2
	NOTE E_, 2
	REST 2
	NOTE C#, 2
	REST 2
	OCTAVE 2
	NOTE A#, 2
	REST 2
	NOTE A#, 2
	NOTE A_, 2
	REST 2
	NOTE A_, 2
	REST 2
	OCTAVE 3
	NOTE C#, 2
	REST 2
	NOTE C#, 2
	REST 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 2
	REST 2
	OCTAVE 2
	NOTE B_, 2
	REST 2
	OCTAVE 3
	NOTE C#, 2
	REST 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 2
	REST 2
	NOTE C#, 2
	REST 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 2
	REST 2
	OCTAVE 2
	NOTE B_, 2
	REST 2
	OCTAVE 3
	NOTE C#, 2
	REST 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C#, 2
	REST 2
	OCTAVE 2
	NOTE B_, 2
	REST 2
	OCTAVE 3
	NOTE D_, 2
	REST 2
	NOTE D_, 2
	REST 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	REST 2
	OCTAVE 2
	NOTE F#, 2
	REST 2
	OCTAVE 3
	NOTE D_, 2
	REST 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 2
	REST 2
	SND_CALL SndD8_Ch1_453C
	SND_CALL SndD8_Ch1_453C
	SND_CALL SndD8_Ch1_453C
	REST 2
	SND_CALL SndD8_Ch1_4552
	REST 2
	SND_CALL SndD8_Ch1_4552
	REST 2
	SND_CALL SndD8_Ch1_4568
	SND_CALL SndD8_Ch1_4568
	SND_CALL SndD8_Ch1_4552
	REST 8
	VOICE $04, 8, 10, 0, 0
	VIBRATO_OFF
	TRANSPOSE_UP 0
	ATTEN 3
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE C_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE C_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE A#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D_, 2
	ATTEN 0
	VOICE $04, 8, 12, 0, 0
	PAN_RIGHT 0
	OCTAVE 4
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	OCTAVE 3
	NOTE A#, 1
	ATTEN 3
	NOTE A#, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 3
	NOTE F_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	PAN_LEFT 0
	OCTAVE 4
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	OCTAVE 3
	NOTE A#, 1
	ATTEN 3
	NOTE A#, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 3
	NOTE F_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	VOICE $04, 8, 10, 0, 0
	PAN_BOTH 0
	ATTEN 3
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE C#, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE C#, 2
	REST 2
	ATTEN 0
	OCTAVE 4
	NOTE A_, 1
	ATTEN 3
	NOTE A_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 0
	NOTE C#, 1
	ATTEN 3
	NOTE C#, 1
	ATTEN 0
	OCTAVE 3
	NOTE B_, 1
	ATTEN 3
	NOTE B_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 3
	NOTE A_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 0
	VOICE $04, 0, 9, 0, 0
	VIBRATO_OFF
	TRANSPOSE_UP $0C
	SND_LOOP

SndD8_Ch2:
	VOICE $04, 8, 11, 0, 0
	VIBRATO_OFF
	REST 4
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE D_, 2
	REST 4
	OCTAVE 2
	NOTE A_, 2
	REST 4
	NOTE A_, 2
	REST 4
	NOTE A_, 2
	REST 2
	REST 4
	OCTAVE 3
	NOTE A_, 2
	REST 4
	NOTE A_, 2
	REST 4
	NOTE A_, 2
	REST 6
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	SND_SEGNO
	OCTAVE 3
	NOTE A_, 3
	ATTEN 3
	NOTE A_, 1
	ATTEN 0
	NOTE B_, 2
	NOTE A_, 2
	REST 2
	NOTE G_, 2
	REST 2
	VIBRATO $01, 6, 1
	NOTE F#, 8
	VIBRATO_OFF
	ATTEN 4
	NOTE F#, 2
	ATTEN 0
	NOTE F#, 4
	NOTE G_, 4
	NOTE A_, 3
	ATTEN 3
	NOTE A_, 1
	ATTEN 0
	NOTE B_, 2
	NOTE A_, 2
	REST 2
	NOTE G_, 2
	REST 2
	VIBRATO $01, 6, 1
	NOTE F#, 8
	VIBRATO_OFF
	ATTEN 4
	NOTE F#, 2
	ATTEN 0
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 2
	REST 2
	OCTAVE 4
	NOTE D_, 2
	REST 2
	NOTE D_, 2
	REST 2
	NOTE D_, 2
	REST 2
	NOTE D_, 4
	NOTE C#, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 4
	NOTE A_, 8
	VIBRATO $01, 0, 2
	NOTE A_, 8
	ATTEN 2
	NOTE A_, 2
	ATTEN 3
	NOTE A_, 2
	ATTEN 4
	NOTE A_, 2
	ATTEN 5
	NOTE A_, 2
	ATTEN 0
	VIBRATO_OFF
	NOTE F#, 4
	NOTE G_, 4
	NOTE A_, 3
	ATTEN 3
	NOTE A_, 1
	ATTEN 0
	NOTE B_, 2
	NOTE A_, 2
	REST 2
	NOTE G_, 2
	REST 2
	VIBRATO $01, 6, 1
	NOTE F#, 8
	VIBRATO_OFF
	ATTEN 4
	NOTE F#, 2
	ATTEN 0
	NOTE F#, 4
	NOTE G_, 4
	NOTE A_, 3
	ATTEN 3
	NOTE A_, 1
	ATTEN 0
	NOTE B_, 2
	NOTE A_, 2
	REST 2
	NOTE G_, 2
	REST 2
	VIBRATO $01, 6, 1
	NOTE F#, 8
	VIBRATO_OFF
	ATTEN 4
	NOTE F#, 2
	ATTEN 0
	NOTE G_, 8
	NOTE F#, 3
	ATTEN 3
	NOTE F#, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 10
	ATTEN 5
	NOTE D_, 4
	ATTEN 0
	NOTE C#, 2
	REST 2
	NOTE D_, 2
	NOTE E_, 6
	NOTE D_, 8
	VIBRATO $01, 0, 1
	ATTEN 2
	NOTE D_, 2
	ATTEN 3
	NOTE D_, 2
	ATTEN 4
	NOTE D_, 2
	ATTEN 5
	NOTE D_, 2
	ATTEN 0
	VIBRATO_OFF
	REST 8
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 4
	VIBRATO $01, 5, 2
	NOTE A_, 6
	ATTEN 5
	NOTE A_, 2
	VIBRATO_OFF
	ATTEN 0
	NOTE A_, 3
	ATTEN 3
	NOTE A_, 1
	ATTEN 0
	NOTE A_, 4
	ATTEN 3
	NOTE A_, 2
	ATTEN 0
	NOTE A#, 4
	ATTEN 3
	NOTE A#, 2
	ATTEN 0
	OCTAVE 4
	NOTE C_, 4
	NOTE D_, 4
	VIBRATO $01, 3, 2
	NOTE D_, 6
	ATTEN 4
	NOTE D_, 2
	VIBRATO_OFF
	ATTEN 0
	NOTE C_, 3
	ATTEN 5
	NOTE C_, 1
	ATTEN 0
	VIBRATO $01, 8, 1
	NOTE C_, 12
	ATTEN 5
	NOTE C_, 2
	VIBRATO_OFF
	ATTEN 0
	REST 2
	NOTE C_, 4
	VIBRATO $01, 5, 2
	NOTE C_, 6
	ATTEN 5
	NOTE C_, 2
	VIBRATO_OFF
	ATTEN 0
	NOTE C_, 3
	ATTEN 3
	NOTE C_, 1
	ATTEN 0
	NOTE C_, 4
	ATTEN 3
	NOTE C_, 2
	ATTEN 0
	OCTAVE 3
	NOTE A#, 4
	ATTEN 3
	NOTE A#, 2
	ATTEN 0
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A#, 8
	VIBRATO $01, 0, 2
	ATTEN 2
	NOTE A#, 2
	ATTEN 3
	NOTE A#, 2
	ATTEN 4
	NOTE A#, 2
	ATTEN 5
	NOTE A#, 2
	ATTEN 0
	VIBRATO_OFF
	NOTE F_, 6
	ATTEN 3
	NOTE F_, 2
	ATTEN 0
	NOTE G_, 6
	ATTEN 3
	NOTE G_, 2
	ATTEN 0
	NOTE G_, 4
	VIBRATO $01, 3, 2
	NOTE G_, 4
	ATTEN 3
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	VIBRATO_OFF
	ATTEN 0
	NOTE G_, 3
	ATTEN 3
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 4
	ATTEN 3
	NOTE G_, 2
	ATTEN 0
	NOTE A_, 4
	ATTEN 3
	NOTE A_, 2
	ATTEN 0
	NOTE A#, 4
	NOTE A_, 4
	VIBRATO $01, 3, 2
	NOTE A_, 4
	ATTEN 3
	NOTE A_, 2
	ATTEN 5
	NOTE A_, 2
	VIBRATO_OFF
	ATTEN 0
	NOTE A_, 3
	ATTEN 3
	NOTE A_, 1
	ATTEN 0
	NOTE A_, 4
	ATTEN 3
	NOTE A_, 2
	ATTEN 0
	NOTE A#, 4
	ATTEN 3
	NOTE A#, 2
	ATTEN 0
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 8
	VIBRATO $01, 0, 2
	ATTEN 2
	NOTE B_, 2
	ATTEN 3
	NOTE B_, 2
	ATTEN 4
	NOTE B_, 2
	ATTEN 5
	NOTE B_, 2
	ATTEN 0
	VIBRATO_OFF
	NOTE B_, 4
	ATTEN 3
	NOTE B_, 2
	ATTEN 0
	OCTAVE 4
	NOTE C_, 4
	ATTEN 3
	NOTE C_, 2
	ATTEN 0
	OCTAVE 4
	NOTE D_, 4
	NOTE C#, 8
	VIBRATO $01, 0, 2
	ATTEN 2
	NOTE C#, 2
	ATTEN 3
	NOTE C#, 2
	ATTEN 4
	NOTE C#, 2
	ATTEN 0
	VIBRATO_OFF
	NOTE D_, 8
	ATTEN 3
	NOTE D_, 2
	ATTEN 0
	NOTE E_, 6
	ATTEN 3
	NOTE E_, 2
	ATTEN 0
	SND_LOOP

SndD8_Ch3:
	VOICE $04, 0, 2, 5, 3
	VIBRATO_OFF
	REST 4
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	REST 4
	OCTAVE 1
	NOTE A_, 2
	REST 4
	NOTE A_, 2
	REST 4
	NOTE A_, 2
	REST 2
	REST 4
	NOTE A_, 2
	REST 4
	NOTE A_, 2
	REST 4
	NOTE A_, 2
	REST 6
	REST 8
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 4
	REST 2
	NOTE A_, 1
	REST 1
	NOTE A_, 5
	REST 1
	NOTE D_, 2
	REST 2
	NOTE D_, 2
	REST 2
	NOTE A_, 1
	REST 1
	NOTE A_, 3
	REST 1
	NOTE F#, 3
	REST 1
	NOTE D_, 4
	REST 2
	NOTE A_, 1
	REST 1
	NOTE A_, 5
	REST 1
	NOTE D_, 2
	REST 2
	NOTE D_, 2
	REST 2
	NOTE A_, 1
	REST 1
	NOTE A_, 3
	REST 1
	NOTE D_, 3
	REST 1
	OCTAVE 2
	NOTE G_, 4
	REST 2
	NOTE D_, 1
	REST 1
	NOTE D_, 5
	REST 1
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	REST 2
	NOTE D_, 1
	REST 1
	NOTE G_, 3
	REST 1
	NOTE D_, 3
	REST 1
	NOTE A_, 4
	REST 2
	NOTE E_, 1
	REST 1
	NOTE E_, 5
	REST 1
	NOTE A_, 2
	REST 2
	NOTE A_, 2
	REST 2
	NOTE E_, 1
	REST 1
	NOTE A_, 2
	REST 2
	NOTE A_, 2
	REST 2
	OCTAVE 2
	NOTE D_, 4
	REST 2
	NOTE A_, 1
	REST 1
	NOTE A_, 5
	REST 1
	NOTE D_, 2
	REST 2
	NOTE D_, 2
	REST 2
	NOTE A_, 1
	REST 1
	NOTE A_, 3
	REST 1
	NOTE F#, 3
	REST 1
	NOTE D_, 4
	REST 2
	NOTE A_, 1
	REST 1
	NOTE A_, 5
	REST 1
	NOTE D_, 2
	REST 2
	NOTE D_, 2
	REST 2
	NOTE A_, 1
	REST 1
	NOTE A_, 3
	REST 1
	NOTE D_, 3
	REST 1
	OCTAVE 1
	NOTE B_, 4
	REST 2
	OCTAVE 2
	NOTE F#, 1
	REST 1
	NOTE F#, 5
	REST 1
	OCTAVE 1
	NOTE B_, 2
	REST 2
	NOTE B_, 2
	REST 2
	NOTE B_, 1
	REST 1
	OCTAVE 2
	NOTE D_, 3
	REST 1
	NOTE F#, 3
	REST 1
	OCTAVE 2
	NOTE D_, 4
	REST 2
	OCTAVE 1
	NOTE A_, 1
	REST 1
	NOTE A_, 5
	REST 1
	OCTAVE 2
	NOTE D_, 2
	REST 2
	NOTE D_, 2
	REST 2
	OCTAVE 1
	NOTE A_, 1
	REST 1
	OCTAVE 2
	NOTE D_, 3
	REST 1
	NOTE E_, 3
	REST 1
	OCTAVE 2
	NOTE F_, 4
	REST 2
	NOTE C_, 1
	REST 1
	NOTE C_, 5
	REST 1
	NOTE F_, 2
	REST 2
	NOTE F_, 2
	REST 2
	NOTE C_, 1
	REST 1
	NOTE F_, 3
	REST 1
	NOTE C_, 3
	REST 1
	OCTAVE 2
	NOTE E_, 4
	REST 2
	NOTE C_, 1
	REST 1
	NOTE C_, 5
	REST 1
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	REST 2
	NOTE C_, 1
	REST 1
	NOTE E_, 3
	REST 1
	NOTE G_, 3
	REST 1
	OCTAVE 2
	NOTE D#, 4
	REST 2
	NOTE A#, 1
	REST 1
	NOTE A#, 5
	REST 1
	NOTE D#, 2
	REST 2
	NOTE D#, 2
	REST 2
	NOTE D#, 1
	REST 1
	NOTE G_, 3
	REST 1
	NOTE D#, 3
	REST 1
	OCTAVE 2
	NOTE D_, 4
	REST 2
	NOTE A#, 1
	REST 1
	NOTE A#, 5
	REST 1
	NOTE D_, 2
	REST 2
	NOTE D_, 2
	REST 2
	NOTE D_, 1
	REST 1
	NOTE D_, 3
	REST 1
	NOTE F_, 3
	REST 1
	OCTAVE 2
	NOTE G_, 4
	REST 2
	NOTE D_, 1
	REST 1
	NOTE D_, 5
	REST 1
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	REST 2
	NOTE D_, 1
	REST 1
	NOTE A#, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE D_, 4
	REST 2
	NOTE A_, 1
	REST 1
	NOTE A_, 5
	REST 1
	NOTE D_, 2
	REST 2
	NOTE D_, 2
	REST 2
	NOTE A_, 1
	REST 1
	NOTE F_, 3
	REST 1
	NOTE A_, 3
	REST 1
	OCTAVE 2
	NOTE G_, 4
	REST 2
	NOTE D_, 1
	REST 1
	NOTE D_, 5
	REST 1
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	REST 2
	NOTE G_, 1
	REST 1
	NOTE B_, 3
	REST 1
	OCTAVE 3
	NOTE D_, 3
	REST 1
	OCTAVE 2
	NOTE A_, 4
	REST 2
	NOTE E_, 1
	REST 1
	NOTE E_, 5
	REST 1
	NOTE A_, 2
	REST 2
	NOTE A_, 2
	REST 2
	NOTE E_, 1
	REST 1
	NOTE A_, 3
	REST 1
	OCTAVE 3
	NOTE E_, 3
	REST 1
	SND_LOOP

SndD8_Drm:
	LEN_UNIT $04
	REST 4
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	REST 4
	DRUM 3, 6
	DRUM 3, 2
	REST 4
	DRUM 7, 4
	REST 4
	DRUM 3, 4
	REST 2
	DRUM 3, 2
	REST 4
	DRUM 3, 6
	DRUM 9, 2
	DRUM 3, 8
	SND_SEGNO
	LOOP_START
	DRUM $0A, 4
	DRUM 8, 2
	DRUM 7, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 8, 2
	LOOP_END $FC
	DRUM $0A, 4
	DRUM 8, 2
	DRUM 8, 2
	DRUM 3, 4
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 9, 4
	DRUM 8, 2
	DRUM 8, 2
	DRUM 3, 4
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 3, 4
	DRUM 8, 2
	DRUM 3, 2
	DRUM 9, 4
	DRUM 8, 2
	DRUM 8, 2
	DRUM 3, 4
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 9, 4
	DRUM 8, 2
	DRUM 8, 2
	DRUM 3, 4
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 3, 4
	DRUM 8, 2
	DRUM 3, 2
	LOOP2_END $FE ; loop byte read both as a start and as an end (see doc)

; Song $D8's drum track ends its last loop (LOOP2_END $FE at $453A, read as a start the
; first time) and runs on into these Ch1 subroutines: the notes are read as drum hits and the
; closing $FD as a call to $01E0 in ROM0 (never reached in practice; see the doc).
SndD8_Ch1_453C:
	VOICE $01, 8, 11, 0, 0
	TRANSPOSE_UP $0A
	OCTAVE 2
	NOTE B_, 2 ; also read as a drum note by song $D8's drum track
	NOTE A#, 2 ; also read as a drum note by song $D8's drum track
	ATTEN 1
	NOTE A_, 1 ; also read as a drum note by song $D8's drum track
	ATTEN 2
	NOTE G#, 1 ; also read as a drum note by song $D8's drum track
	ATTEN 4
	NOTE G_, 1 ; also read as a drum note by song $D8's drum track
	ATTEN 6
	NOTE F#, 1 ; also read as a drum note by song $D8's drum track
	LEN_UNIT $04
	TRANSPOSE_DOWN 0
	SND_RET ; read by song $D8's drum track as a call to $01E0 (ROM0), see the doc
SndD8_Ch1_4552:
	VOICE $01, 8, 11, 0, 0
	TRANSPOSE_UP 7
	OCTAVE 2
	NOTE B_, 2
	NOTE A#, 2
	ATTEN 1
	NOTE A_, 1
	ATTEN 2
	NOTE G#, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 6
	NOTE F#, 1
	LEN_UNIT $04
	TRANSPOSE_UP 0
	SND_RET
SndD8_Ch1_4568:
	VOICE $01, 8, 11, 0, 0
	TRANSPOSE_UP 4
	OCTAVE 2
	NOTE B_, 2
	NOTE A#, 2
	ATTEN 1
	NOTE A_, 1
	ATTEN 2
	NOTE G#, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 6
	NOTE F#, 1
	LEN_UNIT $04
	TRANSPOSE_UP 0
	SND_RET

SndD9_Ch1:
	VOICE $03, 8, 9, 0, 0
	VIBRATO_OFF
	REST 4
	OCTAVE 2
	NOTE A_, 3
	ATTEN 5
	NOTE A_, 1
	ATTEN 0
	NOTE A_, 3
	ATTEN 5
	NOTE A_, 1
	ATTEN 0
	NOTE A_, 3
	ATTEN 5
	NOTE A_, 1
	ATTEN 0
	NOTE A_, 3
	ATTEN 5
	NOTE A_, 1
	ATTEN 0
	NOTE A_, 3
	ATTEN 5
	NOTE A_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 5
	NOTE A_, 1
	ATTEN 0
	NOTE A_, 4
	ATTEN 4
	NOTE A_, 2
	ATTEN 0
	SND_SEGNO
	LOOP_START
	VOICE $03, 12, 10, 0, 0
	PAN_RIGHT 0
	OCTAVE 3
	ATTEN 0
	NOTE G#, 2
	ATTEN 3
	NOTE G#, 2
	ATTEN 0
	NOTE G_, 2
	ATTEN 3
	NOTE G_, 2
	ATTEN 1
	NOTE G#, 2
	ATTEN 4
	NOTE G#, 2
	ATTEN 1
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	OCTAVE 3
	ATTEN 2
	NOTE G#, 2
	ATTEN 5
	NOTE G#, 2
	ATTEN 2
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	ATTEN 3
	NOTE G#, 2
	ATTEN 6
	NOTE G#, 2
	ATTEN 3
	NOTE G_, 2
	ATTEN 6
	NOTE G_, 2
	PAN_LEFT 0
	ATTEN 0
	LOOP2_START
	OCTAVE 2
	NOTE G#, 1
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	OCTAVE 3
	NOTE G#, 1
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	OCTAVE 4
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	LOOP2_END $02
	LOOP_END $02
	PAN_BOTH 0
	LOOP_START
	LEN_UNIT $03
	REST 8
	REST 8
	REST 8
	REST 8
	LEN_UNIT $04
	ATTEN 6
	OCTAVE 2
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	ATTEN 4
	OCTAVE 2
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	ATTEN 2
	OCTAVE 2
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	ATTEN 0
	OCTAVE 2
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	LOOP_END $02
	LOOP_START
	LEN_UNIT $03
	PAN_RIGHT 0
	OCTAVE 3
	ATTEN 0
	NOTE G#, 2
	ATTEN 3
	NOTE G#, 2
	ATTEN 0
	NOTE G_, 2
	ATTEN 3
	NOTE G_, 2
	ATTEN 1
	NOTE G#, 2
	ATTEN 4
	NOTE G#, 2
	ATTEN 1
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	OCTAVE 3
	ATTEN 2
	NOTE G#, 2
	ATTEN 5
	NOTE G#, 2
	ATTEN 2
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	ATTEN 3
	NOTE G#, 2
	ATTEN 6
	NOTE G#, 2
	ATTEN 3
	NOTE G_, 2
	ATTEN 6
	NOTE G_, 2
	PAN_LEFT 0
	ATTEN 0
	LOOP2_START
	OCTAVE 2
	NOTE G#, 1
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	OCTAVE 3
	NOTE G#, 1
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	OCTAVE 4
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	LOOP2_END $02
	LOOP_END $02
	SND_LOOP

SndD9_Ch2:
	VOICE $03, 12, 11, 0, 0
	VIBRATO_OFF
	REST 4
	OCTAVE 3
	NOTE F_, 3
	ATTEN 5
	NOTE F_, 1
	ATTEN 0
	NOTE F_, 3
	ATTEN 5
	NOTE F_, 1
	ATTEN 0
	NOTE F_, 3
	ATTEN 5
	NOTE F_, 1
	ATTEN 0
	NOTE F_, 3
	ATTEN 5
	NOTE F_, 1
	ATTEN 0
	NOTE F_, 3
	ATTEN 5
	NOTE F_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 5
	NOTE F_, 1
	ATTEN 0
	NOTE F_, 4
	ATTEN 4
	NOTE F_, 2
	ATTEN 0
	SND_SEGNO
	VOICE $03, 8, 11, 0, 0
	VIBRATO_OFF
	OCTAVE 3
	DETUNE $FD
	ATTEN 3
	NOTE G#, 2
	DETUNE $FF
	ATTEN 2
	NOTE G#, 2
	DETUNE $00
	ATTEN 1
	NOTE G#, 2
	ATTEN 0
	NOTE G#, 10
	VIBRATO $01, 0, 3
	ATTEN 1
	NOTE G#, 2
	ATTEN 2
	NOTE G#, 2
	ATTEN 3
	NOTE G#, 2
	ATTEN 4
	NOTE G#, 2
	ATTEN 0
	VIBRATO_OFF
	NOTE F#, 6
	DETUNE $FE
	NOTE F#, 1
	DETUNE $FB
	NOTE F#, 1
	ATTEN 0
	DETUNE $00
	NOTE G_, 8
	NOTE G_, 8
	VIBRATO $01, 0, 2
	NOTE G_, 8
	ATTEN 1
	NOTE G_, 2
	ATTEN 2
	NOTE G_, 2
	ATTEN 3
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	VIBRATO_OFF
	TRANSPOSE_UP 7
	OCTAVE 3
	DETUNE $FF
	ATTEN 3
	NOTE G#, 2
	ATTEN 2
	NOTE G#, 2
	DETUNE $00
	ATTEN 1
	NOTE G#, 2
	ATTEN 0
	NOTE G#, 10
	VIBRATO $01, 0, 3
	ATTEN 1
	NOTE G#, 2
	ATTEN 2
	NOTE G#, 2
	DETUNE $FF
	ATTEN 3
	NOTE G#, 2
	ATTEN 4
	DETUNE $FE
	NOTE G#, 2
	ATTEN 0
	VIBRATO_OFF
	NOTE F#, 6
	DETUNE $FF
	NOTE F#, 1
	DETUNE $FE
	NOTE F#, 1
	ATTEN 0
	DETUNE $00
	NOTE G_, 8
	NOTE G_, 8
	VIBRATO $01, 0, 2
	NOTE G_, 8
	ATTEN 1
	NOTE G_, 2
	ATTEN 2
	NOTE G_, 2
	ATTEN 3
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	VIBRATO_OFF
	TRANSPOSE_UP 0
	LOOP_START
	ATTEN 2
	OCTAVE 3
	NOTE G_, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE D#, 2
	NOTE D_, 2
	ATTEN 6
	OCTAVE 3
	NOTE G#, 2
	OCTAVE 4
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 2
	ATTEN 0
	REST 8
	REST 8
	REST 8
	REST 8
	LOOP_END $02
	LOOP_START
	REST 8
	REST 8
	RELEASE 0, 2
	VIBRATO $01, 0, 3
	OCTAVE 3
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	ATTEN 5
	NOTE G_, 1
	ATTEN 0
	REST 2
	VIBRATO_OFF
	RELEASE 0, 0
	REST 2
	OCTAVE 6
	NOTE G#, 2
	ATTEN 5
	NOTE G#, 2
	ATTEN 0
	NOTE G#, 2
	ATTEN 5
	NOTE G#, 2
	ATTEN 0
	ATTEN 0
	NOTE G#, 2
	ATTEN 5
	NOTE G#, 2
	ATTEN 0
	REST 2
	REST 8
	RELEASE 0, 2
	VIBRATO $01, 0, 6
	OCTAVE 3
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	ATTEN 5
	NOTE G_, 1
	ATTEN 0
	REST 2
	REST 8
	RELEASE 0, 0
	VIBRATO_OFF
	LOOP_END $02
	SND_LOOP

SndD9_Ch3:
	VOICE $03, 0, 2, 5, 3
	VIBRATO_OFF
	OCTAVE 2
	NOTE D_, 3
	ATTEN 2
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 3
	ATTEN 2
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 3
	ATTEN 2
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 3
	ATTEN 2
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 3
	ATTEN 2
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 3
	ATTEN 2
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 2
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 4
	ATTEN 2
	NOTE D_, 2
	ATTEN 0
	SND_SEGNO
	NOTE D#, 2
	ATTEN 2
	NOTE D#, 2
	ATTEN 0
	NOTE D_, 2
	ATTEN 2
	NOTE D_, 2
	ATTEN 0
	SND_LOOP

SndD9_Drm:
	LEN_UNIT $03
	DRUM 9, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 9, 2
	DRUM $0A, 6
	SND_SEGNO
	LOOP_START
	DRUM 6, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	LOOP_END $1C
	LOOP_START
	DRUM 6, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	LOOP_END $03
	DRUM 6, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	LOOP_START
	DRUM 6, 2
	DRUM 8, 2
	DRUM 8, 2
	DRUM 8, 2
	LOOP_END $10
	SND_LOOP

SndDA_Ch1:
	VOICE $05, 8, 8, 0, 0
	VIBRATO_OFF
	REST 6
	SND_SEGNO
	LOOP_START
	REST 6
	OCTAVE 2
	NOTE G_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE B_, 3
	ATTEN 5
	NOTE B_, 3
	ATTEN 0
	OCTAVE 2
	NOTE D_, 1
	NOTE G#, 1
	NOTE D_, 1
	NOTE G#, 1
	NOTE D_, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE C_, 4
	NOTE D_, 1
	NOTE D#, 1
	NOTE G_, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE B_, 2
	LOOP_END $02
	LOOP_START
	OCTAVE 2
	NOTE C_, 12
	OCTAVE 1
	NOTE B_, 12
	LOOP_END $02
	VIBRATO $01, 0, 4
	ATTEN 4
	OCTAVE 3
	NOTE G_, 6
	NOTE G#, 6
	ATTEN 2
	NOTE G_, 6
	NOTE G#, 6
	VIBRATO $01, 0, 5
	ATTEN 1
	OCTAVE 3
	NOTE G_, 6
	NOTE G#, 6
	VIBRATO $01, 0, 6
	ATTEN 0
	NOTE G_, 6
	NOTE G#, 6
	VIBRATO_OFF
	SND_LOOP

SndDA_Ch2:
	VOICE $05, 8, 11, 0, 0
	VIBRATO_OFF
	REST 6
	SND_SEGNO
	LOOP_START
	REST 6
	OCTAVE 3
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	VIBRATO $01, 5, 4
	NOTE D_, 10
	VIBRATO_OFF
	ATTEN 4
	NOTE D_, 2
	ATTEN 0
	REST 6
	OCTAVE 2
	NOTE B_, 1
	ATTEN 4
	NOTE B_, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 4
	NOTE B_, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 4
	NOTE B_, 1
	ATTEN 0
	VIBRATO $01, 3, 2
	OCTAVE 3
	NOTE C_, 5
	ATTEN 4
	NOTE C_, 1
	ATTEN 0
	OCTAVE 2
	NOTE B_, 5
	ATTEN 4
	NOTE B_, 1
	ATTEN 0
	VIBRATO_OFF
	LOOP_END $02
	LOOP_START
	OCTAVE 3
	NOTE G_, 4
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	OCTAVE 3
	NOTE G#, 4
	ATTEN 4
	NOTE G#, 2
	ATTEN 0
	NOTE G#, 1
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	NOTE G#, 1
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	NOTE G#, 1
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	LOOP_END $02
	VOICE $05, 12, 7, 8, 7
	VIBRATO_OFF
	LOOP_START
	OCTAVE 4
	PAN_BOTH 0
	NOTE A_, 1
	PAN_RIGHT 0
	ATTEN 4
	NOTE A_, 1
	PAN_BOTH 0
	NOTE F#, 1
	PAN_RIGHT 0
	ATTEN 4
	NOTE F#, 1
	PAN_BOTH 0
	NOTE D#, 1
	PAN_RIGHT 0
	ATTEN 4
	NOTE D#, 1
	LOOP_END $08
	VOICE $05, 8, 11, 0, 0
	VIBRATO_OFF
	SND_LOOP

SndDA_Ch3:
	VOICE $05, 0, 2, 0, 0
	VIBRATO_OFF
	REST 6
	SND_SEGNO
	LOOP_START
	OCTAVE 2
	NOTE C_, 3
	ATTEN 2
	NOTE C_, 3
	ATTEN 0
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 0
	OCTAVE 2
	NOTE C_, 3
	ATTEN 2
	NOTE C_, 3
	ATTEN 0
	OCTAVE 2
	NOTE F#, 3
	ATTEN 2
	NOTE F#, 3
	ATTEN 0
	OCTAVE 1
	NOTE B_, 3
	ATTEN 2
	NOTE B_, 3
	ATTEN 0
	OCTAVE 1
	NOTE G_, 3
	ATTEN 2
	NOTE G_, 3
	ATTEN 0
	OCTAVE 2
	NOTE C_, 3
	ATTEN 2
	NOTE C_, 3
	ATTEN 0
	OCTAVE 1
	NOTE G_, 3
	ATTEN 2
	NOTE G_, 3
	ATTEN 0
	LOOP_END $02
	VOICE $05, 5, 2, 0, 0
	VIBRATO_OFF
	LOOP_START
	OCTAVE 3
	NOTE D#, 4
	ATTEN 2
	NOTE D#, 2
	ATTEN 0
	NOTE D#, 1
	ATTEN 2
	NOTE D#, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 2
	NOTE D#, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 2
	NOTE D#, 1
	ATTEN 0
	LOOP_END $04
	VOICE $05, 0, 2, 5, 3
	VIBRATO_OFF
	LOOP_START
	OCTAVE 2
	NOTE C_, 4
	ATTEN 2
	NOTE C_, 2
	ATTEN 0
	OCTAVE 1
	NOTE B_, 4
	ATTEN 2
	NOTE B_, 2
	ATTEN 0
	LOOP_END $03
	OCTAVE 2
	NOTE C_, 4
	ATTEN 2
	NOTE C_, 2
	ATTEN 0
	NOTE D_, 4
	ATTEN 2
	NOTE D_, 2
	ATTEN 0
	SND_LOOP

SndDA_Drm:
	LEN_UNIT $05
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	SND_SEGNO
	LOOP_START
	DRUM $0A, 6
	DRUM 3, 6
	DRUM 3, 6
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 6
	DRUM 3, 6
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 2
	DRUM 9, 2
	DRUM 3, 2
	LOOP_END $02
	DRUM $0A, 6
	DRUM 3, 6
	DRUM 9, 6
	DRUM 3, 6
	DRUM 9, 6
	DRUM 3, 6
	DRUM 9, 6
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 6
	DRUM 3, 6
	DRUM 3, 6
	DRUM 3, 6
	DRUM 3, 6
	DRUM 3, 6
	DRUM 3, 3
	REST 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	SND_LOOP

SndE4_Ch2:
	SND_SEGNO
	VOICE $06, 0, 10, 9, 1
	DUTY_STEP 8, 1
	OCTAVE 3
	LOOP_START
	REST 2
	NOTE G_, 2
	LOOP_END $10
	LOOP2_START
	DUTY 4
	OCTAVE 5
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 5
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 1
	DUTY 4
	OCTAVE 4
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 2
	NOTE B_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 1
	DUTY 4
	OCTAVE 4
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 2
	NOTE B_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	DUTY 4
	OCTAVE 5
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 5
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 1
	DUTY 4
	OCTAVE 4
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 2
	NOTE B_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 5
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 1
	DUTY 4
	OCTAVE 4
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 2
	NOTE B_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 5
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 1
	DUTY 4
	OCTAVE 4
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 1
	DUTY 4
	OCTAVE 4
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 2
	NOTE E_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 1
	DUTY 4
	OCTAVE 4
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 2
	NOTE E_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	LOOP2_END $02
	VOICE $06, 0, 12, 0, 0
	DUTY_STEP 0, 0
	VIBRATO $01, 4, 5
	OCTAVE 3
	NOTE B_, 0
	NOTE A_, 0
	NOTE G_, 0
	NOTE F#, 7
	REST 1
	VIBRATO $04, 0, 3
	NOTE A_, 3
	VIBRATO $01, 1, 4
	NOTE G_, 3
	VIBRATO_OFF
	RELEASE $0B, 1
	NOTE F#, 2
	RELEASE 0, 0
	NOTE F#, 3
	NOTE E_, 3
	VIBRATO $04, 0, 3
	NOTE B_, 2
	VIBRATO $01, 2, 4
	NOTE B_, 7
	REST 1
	NOTE F#, 3
	NOTE E_, 3
	VIBRATO $04, 0, 3
	NOTE B_, 2
	VIBRATO_OFF
	NOTE B_, 2
	VIBRATO $03, 2, 3
	NOTE B_, 2
	VIBRATO_OFF
	NOTE D_, 2
	NOTE F#, 4
	RELEASE 9, 2
	NOTE E_, 1
	RELEASE 0, 0
	REST 1
	VIBRATO $01, 2, 4
	NOTE E_, 8
	REST 2
	VIBRATO $04, 0, 3
	OCTAVE 4
	NOTE C_, 4
	RELEASE 9, 2
	VIBRATO_OFF
	OCTAVE 3
	NOTE B_, 1
	REST 1
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	VOICE $06, 4, 10, 9, 1
	LOOP_START
	DUTY_STEP 8, 1
	RELEASE 9, 1
	DUTY 4
	OCTAVE 5
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 2
	NOTE E_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 5
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 5
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 1
	DUTY 4
	OCTAVE 5
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	NOTE D_, 1
	ATTEN 2
	NOTE D_, 1
	NOTE D_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 5
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	REST 2
	NOTE G_, 2
	OCTAVE 4
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 1
	DUTY 4
	OCTAVE 4
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 2
	NOTE B_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	LOOP_BREAK $FB
	REST 2
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	LOOP_END $02
	DUTY 4
	OCTAVE 4
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	DUTY 4
	OCTAVE 4
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	DUTY 4
	OCTAVE 4
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	REST 2
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	REST 2
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	REST 2
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 1
	DUTY 4
	DUTY 4
	OCTAVE 4
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 2
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 1
	DUTY 4
	DUTY 4
	OCTAVE 4
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 2
	NOTE B_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	DUTY 4
	OCTAVE 4
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	DUTY 4
	OCTAVE 4
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	DUTY 4
	OCTAVE 4
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 2
	NOTE E_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 1
	DUTY 4
	DUTY 4
	OCTAVE 4
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 2
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 1
	DUTY 4
	OCTAVE 4
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 2
	NOTE E_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	DUTY 4
	OCTAVE 5
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	OCTAVE 5
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	SND_LOOP

SndE4_Ch1:
	SND_SEGNO
	VOICE $06, 8, 15, 0, 0
	LOOP_START
	SND_CALL SndE4_Ch1_4F45
	LOOP_END $0D
	SND_CALL SndE4_Ch1_501B
	SND_CALL SndE4_Ch1_4F45
	SND_CALL SndE4_Ch1_50F1
	LOOP_START
	SND_CALL SndE4_Ch1_4F45
	LOOP_END $03
	SND_CALL SndE4_Ch1_501B
	LOOP_START
	VOICE $06, 8, 11, 0, 0
	REST 1
	VOICE $01, 8, 9, 2, 7
	VIBRATO_OFF
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	VOICE $06, 0, 12, 9, 1
	REST 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	TRANSPOSE_DOWN 2
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	VOICE $06, 8, 12, 0, 0
	TRANSPOSE_DOWN 0
	REST 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	VOICE $06, 0, 12, 9, 1
	REST 2
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	TRANSPOSE_DOWN 2
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	VOICE $06, 8, 12, 0, 0
	TRANSPOSE_UP 0
	REST 2
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	VOICE $06, 8, 12, 0, 0
	REST 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	VOICE $06, 0, 12, 9, 1
	REST 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	TRANSPOSE_DOWN 2
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	TRANSPOSE_DOWN 0
	LOOP_END $08
	LOOP_START
	SND_CALL SndE4_Ch1_4F45
	LOOP_END $10
	SND_LOOP

SndE4_Ch3:
	VOICE $06, 1, 2, 4, 2
	SND_SEGNO
	LOOP_START
	OCTAVE 2
	RELEASE 4, 2
	NOTE E_, 6
	NOTE E_, 10
	NOTE E_, 6
	RELEASE 0, 0
	NOTE E_, 6
	NOTE B_, 4
	LOOP_END $04
	RELEASE 4, 2
	NOTE C_, 6
	NOTE C_, 10
	NOTE C_, 6
	RELEASE 0, 0
	NOTE C_, 6
	NOTE B_, 4
	RELEASE 4, 2
	NOTE E_, 6
	NOTE E_, 10
	NOTE E_, 6
	RELEASE 0, 0
	NOTE E_, 6
	NOTE B_, 4
	LOOP_START
	RELEASE 4, 2
	NOTE E_, 6
	NOTE E_, 10
	NOTE F_, 6
	RELEASE 0, 0
	NOTE F_, 6
	NOTE A_, 4
	RELEASE 4, 2
	NOTE E_, 6
	NOTE E_, 10
	NOTE D_, 6
	RELEASE 0, 0
	NOTE D_, 6
	NOTE G_, 4
	RELEASE 4, 2
	NOTE C_, 6
	NOTE C_, 10
	NOTE D_, 6
	RELEASE 0, 0
	NOTE D_, 6
	NOTE G_, 4
	RELEASE 4, 2
	NOTE E_, 6
	NOTE E_, 10
	LOOP_BREAK $FB
	NOTE F_, 6
	NOTE F_, 6
	NOTE F_, 4
	LOOP_END $02
	NOTE D_, 6
	RELEASE 0, 0
	NOTE D_, 6
	NOTE G_, 4
	LOOP_START
	OCTAVE 2
	RELEASE 4, 2
	NOTE C_, 6
	NOTE C_, 10
	NOTE C_, 6
	RELEASE 0, 0
	NOTE C_, 6
	NOTE D_, 4
	RELEASE 4, 2
	NOTE E_, 6
	NOTE E_, 10
	NOTE D_, 6
	RELEASE 0, 0
	NOTE D_, 6
	NOTE G_, 4
	LOOP_END $02
	RELEASE 4, 2
	NOTE C_, 6
	NOTE C_, 10
	NOTE D_, 6
	RELEASE 0, 0
	NOTE D_, 6
	NOTE G_, 4
	RELEASE 4, 2
	NOTE E_, 6
	NOTE E_, 10
	NOTE D_, 6
	RELEASE 0, 0
	NOTE D_, 6
	NOTE G_, 4
	RELEASE 4, 2
	NOTE C_, 6
	NOTE C_, 10
	NOTE D_, 6
	RELEASE 0, 0
	NOTE D_, 6
	NOTE G_, 4
	RELEASE 4, 2
	NOTE E_, 6
	NOTE E_, 10
	NOTE E_, 6
	RELEASE 0, 0
	NOTE E_, 6
	NOTE B_, 4
	SND_LOOP

SndE4_Drm:
	LEN_UNIT $06
	SND_SEGNO
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_END $02
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_END $06
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_END $06
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_END $06
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_END $0E
	DRUM 9, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	SND_LOOP

; Orphan subroutine (no stream calls it; decoded as Ch1).
B0E_Data_4F35:
	LEN_UNIT $01
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	SND_RET
SndE4_Ch1_4F45:
	VOICE $06, 8, 12, 0, 0
	OCTAVE 2
	NOTE E_, 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	VOICE $06, 0, 12, 9, 1
	OCTAVE 3
	NOTE E_, 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	TRANSPOSE_DOWN 2
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	VOICE $06, 8, 12, 0, 0
	TRANSPOSE_DOWN 0
	OCTAVE 2
	NOTE G_, 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	VOICE $06, 0, 12, 9, 1
	OCTAVE 3
	NOTE E_, 1
	DUTY 8
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	TRANSPOSE_DOWN 2
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	VOICE $06, 8, 12, 0, 0
	TRANSPOSE_UP 0
	OCTAVE 2
	NOTE A_, 1
	DUTY 0
	RELEASE 9, 1
	OCTAVE 3
	NOTE E_, 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	VOICE $06, 8, 12, 0, 0
	OCTAVE 2
	NOTE D_, 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	VOICE $06, 0, 12, 9, 1
	OCTAVE 3
	NOTE E_, 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	TRANSPOSE_DOWN 2
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	TRANSPOSE_DOWN 0
	SND_RET
SndE4_Ch1_501B:
	VOICE $06, 8, 12, 0, 0
	OCTAVE 2
	NOTE F_, 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	VOICE $06, 0, 12, 9, 1
	OCTAVE 3
	NOTE D_, 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	TRANSPOSE_DOWN 2
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	VOICE $06, 8, 12, 0, 0
	TRANSPOSE_DOWN 0
	OCTAVE 2
	NOTE A_, 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	VOICE $06, 0, 12, 9, 1
	OCTAVE 3
	NOTE D_, 1
	DUTY 8
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	TRANSPOSE_DOWN 2
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	VOICE $06, 8, 12, 0, 0
	TRANSPOSE_UP 0
	OCTAVE 2
	NOTE B_, 1
	DUTY 0
	RELEASE 9, 1
	OCTAVE 3
	NOTE D_, 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	VOICE $06, 8, 12, 0, 0
	OCTAVE 2
	NOTE F_, 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	VOICE $06, 0, 12, 9, 1
	OCTAVE 3
	NOTE D_, 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	TRANSPOSE_DOWN 2
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	TRANSPOSE_DOWN 0
	SND_RET
SndE4_Ch1_50F1:
	VOICE $06, 8, 12, 0, 0
	OCTAVE 2
	NOTE E_, 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	VOICE $06, 0, 12, 9, 1
	OCTAVE 3
	NOTE D_, 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	TRANSPOSE_DOWN 2
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	VOICE $06, 8, 12, 0, 0
	TRANSPOSE_DOWN 0
	OCTAVE 2
	NOTE G_, 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	VOICE $06, 0, 12, 9, 1
	OCTAVE 3
	NOTE D_, 1
	DUTY 8
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	TRANSPOSE_DOWN 2
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	VOICE $06, 8, 12, 0, 0
	TRANSPOSE_UP 0
	OCTAVE 2
	NOTE A_, 1
	DUTY 0
	RELEASE 9, 1
	OCTAVE 3
	NOTE D_, 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	VOICE $06, 8, 12, 0, 0
	OCTAVE 2
	NOTE D_, 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	VOICE $06, 0, 12, 9, 1
	OCTAVE 3
	NOTE D_, 1
	VOICE $01, 8, 12, 2, 7
	VIBRATO_OFF
	TRANSPOSE_DOWN 2
	DUTY_STEP 8, 0
	OCTAVE 3
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 5
	NOTE D_, 1
	ATTEN 6
	NOTE C_, 1
	TRANSPOSE_DOWN 0
	SND_RET

SndE5_Ch2:
	SND_SEGNO
	VOICE $07, 8, 10, 4, 2
	REST 0
	REST 0
	TRANSPOSE_UP 1
	OCTAVE 4
	LOOP_START
	NOTE D#, 2
	REST 2
	ATTEN 2
	NOTE D#, 2
	REST 2
	ATTEN 4
	NOTE D#, 2
	REST 2
	ATTEN 6
	NOTE D#, 2
	REST 2
	ATTEN 0
	OCTAVE 5
	LOOP_END $02
	VOICE $07, 8, 10, 0, 0
	VIBRATO $01, 2, 3
	OCTAVE 4
	NOTE D#, 8
	OCTAVE 3
	NOTE G#, 8
	NOTE G_, 8
	NOTE G#, 8
	VIBRATO $04, 0, 2
	NOTE B_, 2
	VIBRATO $01, 2, 3
	NOTE B_, 6
	NOTE A#, 8
	NOTE A_, 8
	NOTE D_, 8
	NOTE D#, 8
	OCTAVE 4
	VIBRATO $04, 0, 2
	NOTE D#, 2
	VIBRATO $01, 2, 3
	NOTE D#, 6
	NOTE D_, 8
	OCTAVE 3
	NOTE A#, 8
	OCTAVE 4
	NOTE C#, 8
	OCTAVE 3
	NOTE B_, 8
	NOTE A_, 8
	NOTE G_, 8
	VIBRATO_OFF
	NOTE G#, 2
	LOOP_START
	RELEASE 9, 1
	DUTY 4
	OCTAVE 4
	NOTE G#, 2
	NOTE G#, 2
	RELEASE 0, 0
	DUTY 8
	ATTEN 2
	OCTAVE 3
	NOTE D#, 4
	NOTE D_, 4
	NOTE C#, 4
	ATTEN 0
	OCTAVE 4
	RELEASE 9, 1
	DUTY 4
	NOTE A#, 2
	NOTE A#, 2
	NOTE B_, 2
	REST 2
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	NOTE G_, 6
	VIBRATO_OFF
	REST 2
	RELEASE 9, 1
	NOTE G#, 2
	NOTE G#, 2
	RELEASE 0, 0
	DUTY 8
	ATTEN 2
	OCTAVE 3
	NOTE D#, 4
	NOTE E_, 4
	NOTE F_, 4
	ATTEN 0
	OCTAVE 4
	RELEASE 9, 1
	DUTY 4
	NOTE A#, 2
	NOTE A#, 2
	NOTE B_, 2
	LOOP_BREAK $FB
	REST 2
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	NOTE G_, 6
	VIBRATO_OFF
	REST 2
	LOOP_END $02
	OCTAVE 5
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	RELEASE 0, 0
	DUTY 8
	VIBRATO $01, 2, 3
	OCTAVE 4
	NOTE D#, 0
	VIBRATO $04, 0, 1
	NOTE F#, 4
	VIBRATO $01, 1, 3
	NOTE E_, 8
	VIBRATO_OFF
	NOTE D_, 4
	VIBRATO $01, 2, 3
	NOTE D#, 0
	VIBRATO_OFF
	DUTY 4
	NOTE C#, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE G#, 2
	DUTY 8
	RELEASE 0, 0
	DUTY 8
	VIBRATO $01, 2, 3
	OCTAVE 4
	NOTE D#, 0
	VIBRATO_OFF
	NOTE F#, 4
	VIBRATO $04, 0, 1
	NOTE G_, 2
	VIBRATO $01, 1, 3
	NOTE G_, 6
	VIBRATO_OFF
	NOTE F#, 4
	VIBRATO $01, 2, 3
	NOTE D#, 0
	VIBRATO_OFF
	DUTY 4
	NOTE C#, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	VOICE $07, 8, 10, 4, 2
	OCTAVE 3
	NOTE D#, 2
	REST 2
	ATTEN 2
	NOTE D#, 2
	REST 2
	ATTEN 4
	NOTE D#, 2
	REST 2
	ATTEN 6
	NOTE D#, 2
	REST 2
	ATTEN 0
	OCTAVE 4
	NOTE E_, 2
	REST 2
	ATTEN 2
	NOTE E_, 2
	REST 2
	ATTEN 4
	NOTE E_, 2
	REST 2
	ATTEN 6
	NOTE E_, 2
	REST 2
	ATTEN 0
	NOTE D#, 2
	REST 2
	ATTEN 2
	NOTE D#, 2
	REST 2
	ATTEN 4
	NOTE D#, 2
	REST 2
	ATTEN 6
	NOTE D#, 2
	REST 2
	ATTEN 0
	OCTAVE 3
	NOTE A_, 2
	REST 2
	ATTEN 2
	NOTE A_, 2
	REST 2
	ATTEN 4
	NOTE A_, 2
	REST 2
	ATTEN 6
	NOTE A_, 2
	REST 2
	ATTEN 0
	SND_LOOP

SndE5_Ch1:
	SND_SEGNO
	VOICE $07, 8, 10, 4, 2
	REST 0
	REST 0
	TRANSPOSE_UP 1
	REST 2
	AUTOPAN 0
	OCTAVE 4
	LOOP_START
	NOTE D#, 2
	REST 2
	ATTEN 2
	NOTE D#, 2
	REST 2
	ATTEN 4
	NOTE D#, 2
	REST 2
	ATTEN 6
	NOTE D#, 2
	REST 2
	ATTEN 0
	OCTAVE 5
	LOOP_END $02
	VOICE $07, 8, 7, 0, 0
	PAN_BOTH 0
	DETUNE $FF
	VIBRATO $01, 2, 3
	OCTAVE 4
	NOTE D#, 8
	OCTAVE 3
	NOTE G#, 8
	NOTE G_, 8
	NOTE G#, 8
	VIBRATO $04, 0, 2
	NOTE B_, 2
	VIBRATO $01, 2, 3
	NOTE B_, 6
	NOTE A#, 8
	NOTE A_, 8
	NOTE D_, 8
	NOTE D#, 8
	OCTAVE 4
	VIBRATO $04, 0, 2
	NOTE D#, 2
	VIBRATO $01, 2, 3
	NOTE D#, 6
	NOTE D_, 8
	OCTAVE 3
	NOTE A#, 8
	OCTAVE 4
	NOTE C#, 8
	OCTAVE 3
	NOTE B_, 8
	NOTE A_, 8
	NOTE G_, 8
	VIBRATO_OFF
	VOICE $07, 0, 8, 9, 1
	DETUNE $00
	LOOP_START
	RELEASE 9, 1
	OCTAVE 4
	NOTE D#, 2
	NOTE D#, 3
	RELEASE 0, 0
	DETUNE $FE
	DUTY 8
	OCTAVE 3
	NOTE D#, 4
	NOTE D_, 4
	NOTE C#, 3
	DETUNE $00
	OCTAVE 4
	RELEASE 9, 1
	DUTY 0
	NOTE D#, 2
	NOTE D#, 2
	NOTE F_, 2
	REST 2
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	NOTE C#, 6
	VIBRATO_OFF
	REST 2
	RELEASE 9, 1
	NOTE D#, 2
	NOTE D#, 3
	RELEASE 0, 0
	DETUNE $FE
	DUTY 8
	OCTAVE 3
	NOTE D#, 4
	NOTE E_, 4
	NOTE F_, 3
	DETUNE $00
	OCTAVE 4
	RELEASE 9, 1
	DUTY 0
	NOTE E_, 2
	NOTE E_, 2
	NOTE F_, 2
	LOOP_BREAK $FB
	REST 2
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	NOTE C#, 6
	VIBRATO_OFF
	REST 2
	LOOP_END $02
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	DETUNE $FF
	RELEASE 0, 0
	DUTY 8
	VIBRATO $01, 2, 3
	REST 2
	OCTAVE 4
	NOTE D#, 0
	NOTE F#, 4
	NOTE E_, 8
	VIBRATO_OFF
	NOTE D_, 4
	DETUNE $00
	DUTY 4
	RELEASE $0A, 1
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	RELEASE 0, 0
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	RELEASE $0A, 1
	NOTE F#, 2
	NOTE G_, 2
	NOTE D_, 2
	RELEASE 0, 0
	NOTE G#, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE D#, 2
	DUTY 8
	DETUNE $FF
	RELEASE 0, 0
	DUTY 8
	VIBRATO $01, 2, 3
	REST 2
	OCTAVE 4
	NOTE D#, 0
	VIBRATO_OFF
	NOTE F#, 4
	NOTE G_, 8
	VIBRATO_OFF
	NOTE F#, 4
	DETUNE $00
	DUTY 4
	RELEASE $0A, 1
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	RELEASE 0, 0
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	RELEASE $0A, 1
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	RELEASE 0, 0
	NOTE G#, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	DUTY 8
	VOICE $07, 8, 10, 4, 2
	AUTOPAN 0
	OCTAVE 3
	REST 2
	NOTE D#, 2
	REST 2
	ATTEN 2
	NOTE D#, 2
	REST 2
	ATTEN 4
	NOTE D#, 2
	REST 2
	ATTEN 6
	NOTE D#, 2
	REST 2
	ATTEN 0
	OCTAVE 4
	NOTE E_, 2
	REST 2
	ATTEN 2
	NOTE E_, 2
	REST 2
	ATTEN 4
	NOTE E_, 2
	REST 2
	ATTEN 6
	NOTE E_, 2
	REST 2
	ATTEN 0
	NOTE D#, 2
	REST 2
	ATTEN 2
	NOTE D#, 2
	REST 2
	ATTEN 4
	NOTE D#, 2
	REST 2
	ATTEN 6
	NOTE D#, 2
	REST 2
	ATTEN 0
	OCTAVE 3
	NOTE A_, 2
	REST 2
	ATTEN 2
	NOTE A_, 2
	REST 2
	ATTEN 4
	NOTE A_, 2
	REST 2
	ATTEN 6
	NOTE A_, 2
	ATTEN 0
	SND_LOOP

SndE5_Ch3:
	VOICE $07, 1, 2, 0, 0
	TRANSPOSE_UP 1
	SND_SEGNO
	LOOP_START
	SND_CALL SndE5_Ch3_54EF
	LOOP_END $13
	OCTAVE 2
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	ATTEN 1
	NOTE D#, 1
	ATTEN 0
	NOTE C#, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 1
	NOTE D#, 1
	ATTEN 0
	NOTE C_HI, 1
	ATTEN 1
	NOTE C_HI, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	NOTE C_HI, 1
	ATTEN 1
	NOTE C_HI, 1
	ATTEN 0
	LOOP_START
	SND_CALL SndE5_Ch3_54EF
	LOOP_BREAK $FB
	TRANSPOSE_UP 2
	SND_CALL SndE5_Ch3_54EF
	TRANSPOSE_UP 1
	LOOP_END $04
	OCTAVE 2
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	OCTAVE 3
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	NOTE C_HI, 1
	ATTEN 1
	NOTE C_HI, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 1
	NOTE F_, 1
	ATTEN 0
	NOTE C_HI, 1
	ATTEN 1
	NOTE C_HI, 1
	ATTEN 0
	VIBRATO $01, 2, 4
	NOTE D#, 0
	OCTAVE 2
	NOTE D#, 0
	NOTE B_, 0
	OCTAVE 3
	NOTE D_, 0
	VIBRATO_OFF
	SND_LOOP

SndE5_Drm:
	LEN_UNIT $07
	SND_SEGNO
	LOOP2_START
	DRUM $0C, 2
	DRUM 7, 2
	DRUM $0A, 2
	DRUM 7, 4
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	LOOP_START
	DRUM 7, 2
	DRUM 7, 2
	DRUM $0A, 2
	DRUM 7, 4
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	LOOP_END $03
	LOOP2_END $02
	LOOP_START
	DRUM 7, 2
	DRUM 7, 2
	DRUM $0A, 2
	DRUM 7, 4
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	LOOP_END $0B
	DRUM 7, 2
	DRUM 7, 2
	DRUM $0A, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM $0A, 2
	DRUM 7, 2
	DRUM $0A, 2
	DRUM $0C, 2
	DRUM 7, 2
	DRUM $0A, 2
	DRUM 7, 4
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	LOOP_START
	DRUM 7, 2
	DRUM 7, 2
	DRUM $0A, 2
	DRUM 7, 4
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	LOOP_END $06
	DRUM 7, 2
	DRUM 7, 2
	DRUM $0A, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM $0A, 2
	DRUM 7, 2
	DRUM $0A, 2
	DRUM $0C, 2
	DRUM 7, 2
	DRUM $0A, 2
	DRUM 7, 4
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	LOOP_START
	DRUM 7, 2
	DRUM 7, 2
	DRUM $0A, 2
	DRUM 7, 4
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	LOOP_END $02
	DRUM 7, 2
	DRUM 7, 2
	DRUM $0A, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM $0A, 2
	DRUM 7, 2
	DRUM $0A, 2
	SND_LOOP
SndE5_Ch3_54EF:
	OCTAVE 2
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	ATTEN 1
	NOTE D#, 1
	ATTEN 0
	NOTE C#, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 1
	NOTE D#, 1
	ATTEN 0
	OCTAVE 2
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 0
	OCTAVE 3
	NOTE C#, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	OCTAVE 2
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	SND_RET

SndE6_Ch2:
	SND_SEGNO
	VOICE $06, 4, 9, 0, 0
	TRANSPOSE_UP 3
	LOOP_START
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	VIBRATO $01, 5, 3
	ENVELOPE $0A
	NOTE B_, 8
	ENVELOPE $00
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 2
	VIBRATO $04, 0, 2
	NOTE E_, 4
	VIBRATO $01, 1, 2
	NOTE D#, 4
	OCTAVE 3
	NOTE B_, 4
	VIBRATO_OFF
	RELEASE 4, 1
	NOTE A#, 4
	RELEASE 0, 0
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	ENVELOPE $06
	NOTE B_, 12
	ENVELOPE $00
	VIBRATO $01, 0, 3
	NOTE B_, 15
	REST 1
	VIBRATO_OFF
	VIBRATO $01, 5, 3
	ENVELOPE $06
	OCTAVE 3
	NOTE A#, 0
	ENVELOPE $00
	VIBRATO_OFF
	NOTE A_, 4
	VIBRATO $01, 1, 3
	NOTE G_, 4
	NOTE F_, 4
	VIBRATO_OFF
	RELEASE 4, 1
	NOTE C_, 4
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	ENVELOPE $0A
	VIBRATO $01, 5, 4
	NOTE B_, 14
	ENVELOPE $00
	LOOP_BREAK $FB
	VIBRATO $01, 0, 4
	NOTE B_, 13
	REST 1
	VIBRATO_OFF
	LOOP_END $02
	VIBRATO_OFF
	AUTOPAN 0
	DUTY 8
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	PAN_BOTH 0
	DUTY 4
	OCTAVE 3
	NOTE C_, 2
	AUTOPAN 0
	DUTY 8
	OCTAVE 4
	NOTE C_, 1
	NOTE F_, 1
	PAN_BOTH 0
	DUTY 4
	OCTAVE 3
	NOTE D_, 2
	AUTOPAN 0
	DUTY 8
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	PAN_BOTH 0
	DUTY 4
	OCTAVE 3
	NOTE E_, 2
	AUTOPAN 0
	DUTY 8
	OCTAVE 4
	NOTE E_, 1
	NOTE A_, 1
	PAN_BOTH 0
	DUTY 4
	OCTAVE 3
	REST 4
	NOTE B_, 2
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	VIBRATO $04, 0, 1
	NOTE D#, 2
	VIBRATO_OFF
	NOTE D_, 2
	OCTAVE 3
	RELEASE 8, 2
	NOTE B_, 2
	DUTY 8
	VIBRATO_OFF
	OCTAVE 4
	RELEASE 9, 1
	NOTE B_, 2
	RELEASE 0, 0
	NOTE B_, 2
	RELEASE 9, 1
	NOTE A#, 2
	RELEASE 0, 0
	NOTE A#, 2
	RELEASE 9, 1
	NOTE G_, 2
	RELEASE 0, 0
	NOTE G_, 2
	VIBRATO $01, 1, 3
	NOTE F#, 6
	VIBRATO_OFF
	DUTY 4
	OCTAVE 3
	NOTE B_, 2
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	VIBRATO $04, 0, 1
	NOTE D#, 2
	VIBRATO $01, 1, 3
	NOTE D_, 4
	VIBRATO_OFF
	DUTY 8
	OCTAVE 4
	NOTE A_, 2
	NOTE A#, 2
	VIBRATO $01, 2, 3
	NOTE B_, 10
	VIBRATO_OFF
	DUTY 4
	OCTAVE 3
	REST 4
	NOTE B_, 2
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	VIBRATO $04, 0, 1
	NOTE D#, 2
	VIBRATO_OFF
	NOTE D_, 2
	OCTAVE 3
	RELEASE 8, 2
	NOTE B_, 2
	DUTY 8
	RELEASE 0, 0
	VIBRATO_OFF
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	VIBRATO $01, 2, 3
	OCTAVE 3
	NOTE B_, 8
	VIBRATO_OFF
	DUTY 4
	OCTAVE 3
	REST 4
	NOTE B_, 2
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	VIBRATO $04, 0, 1
	NOTE D#, 2
	VIBRATO_OFF
	NOTE D_, 2
	DUTY 8
	OCTAVE 4
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 2
	VIBRATO $01, 2, 3
	NOTE E_, 4
	NOTE D#, 4
	VIBRATO $01, 5, 3
	ENVELOPE $06
	OCTAVE 3
	NOTE B_, 10
	ENVELOPE $00
	VIBRATO_OFF
	RELEASE 9, 1
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	NOTE D#, 6
	VIBRATO $01, 2, 3
	OCTAVE 3
	NOTE B_, 6
	NOTE A_, 4
	VIBRATO_OFF
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	VIBRATO $01, 1, 3
	NOTE G_, 4
	REST 2
	VIBRATO_OFF
	RELEASE 9, 1
	NOTE A_, 2
	NOTE A#, 2
	RELEASE 0, 0
	ENVELOPE $06
	VIBRATO $01, 5, 3
	NOTE B_, 10
	ENVELOPE $00
	DUTY 4
	RELEASE 9, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	RELEASE 0, 0
	DUTY 8
	VIBRATO $01, 2, 3
	OCTAVE 3
	NOTE A_, 6
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE E_, 1
	VIBRATO $01, 5, 3
	ENVELOPE $0A
	NOTE E_, 9
	ENVELOPE $00
	VIBRATO $01, 2, 3
	OCTAVE 4
	NOTE C_, 6
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE F#, 6
	VIBRATO $01, 2, 3
	NOTE E_, 4
	VIBRATO_OFF
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	VIBRATO $01, 1, 3
	NOTE B_, 4
	REST 2
	VIBRATO_OFF
	RELEASE 9, 1
	OCTAVE 4
	NOTE C_, 2
	NOTE C#, 2
	RELEASE 0, 0
	ENVELOPE $0A
	VIBRATO $01, 5, 3
	NOTE D#, 10
	ENVELOPE $00
	VIBRATO_OFF
	AUTOPAN 0
	DUTY 4
	OCTAVE 3
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE D#, 1
	NOTE C_HI, 1
	DUTY 8
	PAN_BOTH 0
	VIBRATO $01, 5, 3
	ENVELOPE $06
	OCTAVE 4
	NOTE E_, 10
	ENVELOPE $00
	VIBRATO_OFF
	RELEASE 9, 1
	OCTAVE 3
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	NOTE D#, 6
	VIBRATO $01, 2, 3
	OCTAVE 3
	NOTE B_, 6
	NOTE A_, 4
	VIBRATO_OFF
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	VIBRATO $01, 1, 3
	NOTE G_, 4
	REST 2
	VIBRATO_OFF
	RELEASE 9, 1
	NOTE A_, 2
	NOTE A#, 2
	RELEASE 0, 0
	ENVELOPE $0A
	VIBRATO $01, 5, 3
	NOTE B_, 10
	ENVELOPE $00
	DUTY 4
	RELEASE 9, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	RELEASE 0, 0
	DUTY 8
	VIBRATO $01, 2, 3
	OCTAVE 3
	NOTE A_, 6
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE E_, 1
	VIBRATO $01, 5, 3
	ENVELOPE $06
	NOTE E_, 9
	ENVELOPE $00
	VIBRATO $01, 2, 3
	OCTAVE 4
	NOTE F#, 6
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE G_, 6
	VIBRATO_OFF
	NOTE A_, 4
	VIBRATO $01, 5, 3
	ENVELOPE $06
	NOTE G_, 0
	NOTE F#, 0
	ENVELOPE $00
	VIBRATO_OFF
	SND_LOOP

SndE6_Ch1:
	SND_SEGNO
	VOICE $06, 4, 13, 0, 0
	TRANSPOSE_UP 3
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	VIBRATO $01, 5, 3
	ENVELOPE $06
	NOTE G_, 8
	ENVELOPE $00
	VIBRATO $01, 0, 3
	NOTE G_, 12
	VIBRATO $01, 2, 4
	NOTE E_, 8
	VIBRATO_OFF
	DUTY 8
	OCTAVE 2
	RELEASE $0A, 1
	NOTE F_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE C_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE C_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE G_, 2
	RELEASE 0, 0
	VIBRATO $01, 1, 5
	NOTE A_, 4
	VIBRATO_OFF
	ATTEN 4
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	VIBRATO $01, 1, 3
	NOTE E_, 4
	ATTEN 0
	REST 2
	OCTAVE 2
	VIBRATO_OFF
	NOTE C_, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE C_, 2
	VIBRATO $04, 0, 2
	NOTE F#, 3
	VIBRATO $01, 0, 3
	NOTE F#, 5
	VIBRATO $01, 2, 4
	NOTE C_, 8
	OCTAVE 2
	NOTE A_, 8
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 8
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 8
	ATTEN 4
	OCTAVE 4
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 4
	VIBRATO_OFF
	ATTEN 0
	DUTY 4
	OCTAVE 3
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	RELEASE 4, 1
	NOTE G_, 4
	RELEASE 0, 0
	VIBRATO $01, 2, 4
	NOTE F_, 8
	NOTE E_, 4
	VIBRATO $01, 1, 3
	NOTE F#, 4
	NOTE G_, 4
	VIBRATO_OFF
	NOTE F#, 4
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	RELEASE 4, 1
	VIBRATO $01, 1, 4
	NOTE E_, 4
	RELEASE 0, 0
	VIBRATO_OFF
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 4
	VIBRATO $01, 1, 3
	NOTE F#, 4
	NOTE D#, 4
	VIBRATO_OFF
	NOTE E_, 4
	DUTY 8
	REST 2
	OCTAVE 2
	VIBRATO_OFF
	NOTE C_, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE C_, 2
	VIBRATO $04, 0, 2
	NOTE F#, 3
	VIBRATO $01, 0, 3
	NOTE F#, 5
	VIBRATO $01, 2, 4
	NOTE C_, 8
	OCTAVE 2
	NOTE A_, 8
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 4
	VIBRATO $04, 0, 2
	DUTY 4
	OCTAVE 3
	NOTE B_, 2
	VIBRATO_OFF
	NOTE A#, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	REST 1
	DUTY 8
	ATTEN 3
	NOTE B_, 1
	ATTEN 0
	DUTY 4
	NOTE F_, 2
	REST 1
	DUTY 8
	ATTEN 3
	OCTAVE 4
	NOTE C_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 3
	NOTE G_, 2
	REST 1
	DUTY 8
	ATTEN 3
	OCTAVE 4
	NOTE D_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 3
	NOTE A_, 2
	REST 1
	DUTY 8
	ATTEN 3
	OCTAVE 4
	NOTE E_, 1
	REST 2
	DETUNE $FF
	ATTEN 5
	OCTAVE 3
	REST 4
	NOTE B_, 2
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE B_, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F#, 6
	OCTAVE 3
	NOTE B_, 2
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 4
	NOTE A_, 2
	NOTE A#, 2
	NOTE B_, 10
	OCTAVE 3
	REST 4
	NOTE B_, 2
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 8
	OCTAVE 3
	REST 4
	NOTE B_, 2
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 4
	NOTE D#, 2
	ATTEN 0
	DETUNE $00
	VOICE $06, 0, 15, 8, 1
	LOOP2_START
	OCTAVE 2
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE G_, 1
	NOTE E_, 1
	LOOP_START
	NOTE A_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F#, 1
	LOOP_END $02
	LOOP_START
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE G_, 1
	NOTE E_, 1
	LOOP_END $02
	LOOP_START
	NOTE G#, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE G#, 1
	NOTE E_, 1
	LOOP_END $02
	LOOP_START
	NOTE A_, 1
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE E_, 1
	LOOP_END $02
	LOOP_START
	NOTE A#, 1
	NOTE F#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE F#, 1
	LOOP_END $02
	LOOP_BREAK $FC
	LOOP_START
	NOTE B_, 1
	NOTE F#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE F#, 1
	LOOP_END $02
	NOTE F#, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE F#, 1
	NOTE D#, 1
	AUTOPAN 0
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE A_, 1
	NOTE C_HI, 1
	NOTE G_, 1
	NOTE C_HI, 1
	NOTE F#, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	LOOP2_END $02
	OCTAVE 3
	NOTE D#, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE B_, 1
	ATTEN 3
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	OCTAVE 3
	NOTE A_, 6
	VIBRATO $01, 2, 3
	NOTE G_, 6
	NOTE F#, 4
	VIBRATO_OFF
	ATTEN 0
	SND_LOOP

SndE6_Ch3:
	SND_SEGNO
	VOICE $06, 1, 2, 4, 1
	TRANSPOSE_UP 3
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 2
	NOTE E_, 3
	NOTE E_, 3
	NOTE B_, 2
	LOOP_END $02
	LOOP_START
	OCTAVE 2
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 3
	OCTAVE 3
	NOTE C_, 2
	LOOP_END $02
	OCTAVE 2
	NOTE F#, 3
	NOTE F#, 3
	NOTE F#, 2
	NOTE F#, 3
	NOTE F#, 3
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 3
	OCTAVE 3
	NOTE C_, 2
	LOOP_START
	OCTAVE 2
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 2
	NOTE E_, 3
	NOTE E_, 3
	LOOP_BREAK $FB
	NOTE D#, 2
	LOOP_END $02
	NOTE B_, 2
	LOOP2_END $02
	RELEASE 2, 2
	LOOP_START
	RELEASE 1, 2
	NOTE B_, 0
	RELEASE 2, 1
	NOTE B_, 6
	RELEASE 1, 1
	NOTE B_, 10
	LOOP_END $03
	NOTE B_, 0
	RELEASE 4, 1
	NOTE B_, 3
	NOTE B_, 3
	LOOP_START
	NOTE B_, 2
	LOOP_END $05
	LOOP_START
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 2
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 2
	NOTE F#, 3
	NOTE F#, 3
	NOTE F#, 2
	NOTE F#, 3
	NOTE F#, 3
	NOTE F#, 2
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 2
	NOTE G#, 3
	NOTE G#, 3
	NOTE G#, 2
	NOTE G#, 3
	NOTE G#, 3
	NOTE G#, 2
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 2
	NOTE A#, 3
	NOTE A#, 3
	NOTE A#, 2
	NOTE A#, 3
	NOTE A#, 3
	NOTE A#, 2
	NOTE B_, 3
	NOTE B_, 3
	NOTE B_, 2
	NOTE B_, 3
	NOTE B_, 3
	NOTE B_, 2
	LOOP_BREAK $FB
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 2
	LOOP_END $02
	NOTE B_, 3
	NOTE B_, 3
	NOTE B_, 2
	NOTE B_, 3
	NOTE B_, 3
	NOTE B_, 2
	SND_LOOP

SndE6_Drm:
	LEN_UNIT $06
	SND_SEGNO
	LOOP2_START
	DRUM $0C, 2
	DRUM $0A, 2
	DRUM $0B, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP_START
	DRUM 9, 1
	DRUM 7, 1
	DRUM $0A, 2
	DRUM $0B, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP_END $0D
	LOOP_BREAK $FC
	DRUM 9, 1
	DRUM 7, 1
	DRUM $0A, 2
	DRUM $0B, 1
	DRUM 7, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM 2, 1
	DRUM 8, 1
	LOOP2_END $02
	LOOP_START
	DRUM 9, 1
	DRUM 2, 1
	DRUM $0B, 1
	DRUM 8, 1
	LOOP_END $02
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0C, 2
	DRUM $0A, 2
	LOOP_START
	DRUM 7, 1
	DRUM 8, 1
	DRUM $0A, 2
	LOOP_END $07
	LOOP2_START
	DRUM $0C, 2
	DRUM $0A, 2
	LOOP_START
	DRUM 7, 1
	DRUM 8, 1
	DRUM $0A, 2
	LOOP_END $03
	LOOP2_END $02
	DRUM $0C, 2
	DRUM $0A, 2
	LOOP_START
	DRUM 7, 1
	DRUM 8, 1
	DRUM $0A, 2
	LOOP_END $07
	LOOP_START
	DRUM 9, 1
	DRUM 7, 1
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM $0A, 2
	LOOP_END $02
	DRUM $0C, 2
	DRUM $0B, 1
	DRUM 8, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM 2, 1
	DRUM 8, 1
	DRUM $0C, 2
	DRUM $0A, 2
	DRUM $0B, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP_START
	DRUM 9, 1
	DRUM 7, 1
	DRUM $0A, 2
	DRUM $0B, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP_END $06
	DRUM 9, 1
	DRUM 7, 1
	DRUM $0A, 2
	DRUM $0B, 1
	DRUM 7, 1
	DRUM $0A, 1
	DRUM $0B, 1
	LOOP_START
	DRUM 9, 1
	DRUM 7, 1
	DRUM $0A, 2
	DRUM $0B, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP_END $06
	DRUM 9, 1
	DRUM 7, 1
	DRUM $0A, 2
	DRUM $0B, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 9, 1
	DRUM 2, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM $0C, 2
	DRUM $0A, 2
	DRUM $0B, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP_START
	DRUM 9, 1
	DRUM 7, 1
	DRUM $0A, 2
	DRUM $0B, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP_END $0D
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 2, 1
	DRUM 2, 1
	SND_LOOP

SndE7_Ch2:
	SND_SEGNO
	VOICE $06, 8, 8, 9, 1
	DUTY_STEP 8, 1
	REST 2
	OCTAVE 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LOOP_START
	NOTE G_, 2
	NOTE F#, 2
	NOTE F_, 2
	RELEASE 0, 0
	VIBRATO $01, 1, 2
	NOTE E_, 4
	DUTY 0
	RELEASE 9, 1
	VIBRATO_OFF
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	REST 1
	OCTAVE 4
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE A_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	VIBRATO_OFF
	OCTAVE 4
	RELEASE 9, 1
	DUTY 8
	NOTE G_, 1
	NOTE G_, 2
	NOTE G_, 2
	LOOP_END $02
	VIBRATO $04, 0, 3
	RELEASE 0, 0
	NOTE A_, 3
	RELEASE 9, 1
	VIBRATO_OFF
	NOTE G_, 1
	REST 2
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	NOTE E_, 4
	DUTY 0
	VIBRATO_OFF
	RELEASE 9, 1
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G#, 2
	LOOP_START
	NOTE A_, 2
	REST 1
	OCTAVE 4
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE A_, 2
	NOTE B_, 2
	REST 1
	LOOP_BREAK $FB
	OCTAVE 4
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE B_, 2
	LOOP_END $02
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	REST 2
	RELEASE 0, 0
	DUTY 8
	DUTY_STEP 0, 0
	VIBRATO $04, 0, 2
	NOTE C_, 2
	VIBRATO_OFF
	NOTE D_, 2
	NOTE E_, 2
	VIBRATO $01, 2, 3
	ENVELOPE $0E
	NOTE F_, 6
	NOTE G_, 6
	VIBRATO_OFF
	ENVELOPE $00
	NOTE A_, 4
	VIBRATO $04, 0, 2
	ENVELOPE $0E
	NOTE B_, 8
	VIBRATO $01, 3, 2
	NOTE A_, 8
	NOTE G_, 6
	VIBRATO_OFF
	NOTE E_, 6
	ENVELOPE $00
	VIBRATO $04, 0, 2
	OCTAVE 5
	NOTE D_, 4
	VIBRATO $01, 3, 2
	ENVELOPE $0E
	NOTE C#, 0
	VIBRATO_OFF
	NOTE C_, 6
	OCTAVE 4
	NOTE A_, 6
	ENVELOPE $00
	NOTE F_, 4
	VIBRATO $01, 3, 2
	ENVELOPE $0E
	NOTE E_, 8
	NOTE F_, 8
	VIBRATO $01, 3, 2
	NOTE G_, 0
	NOTE F#, 0
	NOTE F_, 6
	VIBRATO_OFF
	NOTE G_, 6
	ENVELOPE $00
	NOTE A_, 4
	VIBRATO $01, 3, 2
	ENVELOPE $0E
	NOTE B_, 0
	VIBRATO $04, 0, 2
	OCTAVE 5
	NOTE D_, 6
	VIBRATO_OFF
	OCTAVE 4
	NOTE B_, 6
	ENVELOPE $00
	VIBRATO $01, 3, 2
	OCTAVE 5
	NOTE D_, 4
	ENVELOPE $0E
	NOTE C#, 0
	OCTAVE 4
	NOTE A_, 6
	ENVELOPE $00
	VIBRATO_OFF
	NOTE G_, 6
	NOTE A_, 4
	VIBRATO $04, 0, 2
	NOTE B_, 6
	VIBRATO_OFF
	NOTE A#, 6
	VIBRATO $01, 3, 2
	NOTE B_, 4
	ENVELOPE $0E
	OCTAVE 5
	NOTE C_, 0
	ENVELOPE $00
	VIBRATO_OFF
	OCTAVE 4
	NOTE B_, 4
	NOTE A#, 4
	NOTE A_, 4
	NOTE G_, 4
	LOOP_START
	NOTE C_, 3
	NOTE D_, 3
	NOTE E_, 2
	VIBRATO $01, 2, 3
	NOTE C_, 8
	VIBRATO_OFF
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 2
	VIBRATO $01, 1, 1
	NOTE F#, 4
	NOTE A_, 4
	LOOP_BREAK $FB
	VIBRATO_OFF
	NOTE B_, 3
	OCTAVE 5
	NOTE C_, 3
	NOTE C#, 2
	NOTE D_, 8
	VIBRATO $01, 0, 2
	NOTE D_, 0
	OCTAVE 4
	VIBRATO_OFF
	LOOP_END $02
	VIBRATO_OFF
	NOTE B_, 3
	NOTE A#, 3
	NOTE A_, 2
	VIBRATO $01, 3, 2
	NOTE G_, 12
	REST 4
	SND_LOOP

SndE7_Ch1:
	SND_SEGNO
	VOICE $06, 8, 8, 9, 1
	REST 2
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	LOOP_START
	OCTAVE 4
	NOTE E_, 1
	DUTY 4
	OCTAVE 3
	NOTE E_, 1
	DUTY 8
	OCTAVE 4
	NOTE D#, 2
	NOTE D_, 1
	DUTY 4
	OCTAVE 3
	NOTE E_, 1
	DUTY 8
	RELEASE 0, 0
	VIBRATO $01, 1, 2
	OCTAVE 4
	NOTE C_, 4
	VIBRATO_OFF
	RELEASE 9, 1
	DUTY 4
	PAN_LEFT 0
	OCTAVE 5
	NOTE C_, 1
	REST 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE E_, 1
	PAN_RIGHT 0
	OCTAVE 5
	NOTE C_, 1
	PAN_BOTH 0
	REST 1
	OCTAVE 3
	NOTE E_, 1
	REST 1
	NOTE C_, 1
	PAN_LEFT 0
	OCTAVE 5
	NOTE C_, 1
	REST 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE C_, 1
	PAN_RIGHT 0
	OCTAVE 5
	NOTE C_, 1
	REST 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE F_, 2
	PAN_LEFT 0
	OCTAVE 5
	NOTE D_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 1
	DUTY 8
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 1
	DUTY 4
	OCTAVE 3
	NOTE D_, 1
	DUTY 8
	OCTAVE 4
	NOTE E_, 1
	DUTY 4
	OCTAVE 3
	NOTE G_, 1
	DUTY 8
	LOOP_END $02
	DUTY 8
	OCTAVE 4
	VIBRATO $04, 0, 3
	RELEASE 0, 0
	NOTE F#, 3
	RELEASE 9, 1
	VIBRATO_OFF
	NOTE E_, 1
	REST 1
	DUTY 4
	OCTAVE 3
	NOTE E_, 1
	DUTY 8
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	OCTAVE 4
	NOTE C_, 4
	VIBRATO_OFF
	RELEASE 9, 1
	DUTY 4
	PAN_LEFT 0
	OCTAVE 5
	NOTE C_, 1
	REST 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE E_, 1
	PAN_RIGHT 0
	OCTAVE 5
	NOTE C_, 1
	PAN_BOTH 0
	REST 1
	OCTAVE 3
	NOTE E_, 1
	REST 1
	NOTE C_, 1
	PAN_LEFT 0
	OCTAVE 5
	NOTE C_, 1
	REST 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE C_, 1
	PAN_RIGHT 0
	OCTAVE 5
	NOTE C_, 1
	REST 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE F_, 2
	PAN_LEFT 0
	OCTAVE 5
	NOTE D_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 1
	PAN_RIGHT 0
	OCTAVE 5
	NOTE D_, 1
	PAN_BOTH 0
	REST 1
	OCTAVE 3
	NOTE D_, 1
	PAN_LEFT 0
	OCTAVE 5
	NOTE D_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE G_, 1
	VIBRATO $01, 3, 2
	RELEASE 0, 0
	OCTAVE 5
	NOTE C_, 8
	NOTE D_, 8
	RELEASE 9, 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	REST 2
	RELEASE 0, 0
	OCTAVE 3
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	RELEASE 9, 1
	NOTE F_, 1
	PAN_RIGHT 0
	OCTAVE 5
	NOTE C_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE F_, 2
	AUTOPAN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE F_, 2
	AUTOPAN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE F_, 2
	AUTOPAN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	RELEASE 9, 1
	OCTAVE 3
	NOTE F_, 1
	PAN_RIGHT 0
	OCTAVE 5
	NOTE D_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE F_, 2
	AUTOPAN 0
	OCTAVE 4
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE D_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE F_, 2
	AUTOPAN 0
	OCTAVE 4
	NOTE D_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE F_, 2
	AUTOPAN 0
	OCTAVE 4
	NOTE D_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	RELEASE 9, 1
	OCTAVE 3
	NOTE G_, 1
	PAN_RIGHT 0
	OCTAVE 4
	NOTE B_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE G_, 2
	AUTOPAN 0
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	NOTE G_, 2
	AUTOPAN 0
	NOTE B_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	NOTE G_, 2
	AUTOPAN 0
	NOTE B_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	RELEASE 9, 1
	OCTAVE 3
	NOTE G_, 1
	PAN_RIGHT 0
	OCTAVE 4
	NOTE A#, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE G_, 2
	AUTOPAN 0
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	NOTE G_, 2
	AUTOPAN 0
	NOTE A#, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	NOTE G_, 2
	AUTOPAN 0
	NOTE A#, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	RELEASE 9, 1
	OCTAVE 3
	NOTE F_, 1
	PAN_RIGHT 0
	OCTAVE 4
	NOTE A_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE F_, 2
	AUTOPAN 0
	NOTE A_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE F_, 2
	AUTOPAN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE F_, 2
	AUTOPAN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	RELEASE 9, 1
	OCTAVE 3
	NOTE G#, 1
	PAN_RIGHT 0
	OCTAVE 5
	NOTE D_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE G#, 2
	AUTOPAN 0
	OCTAVE 4
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE D_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE G#, 2
	AUTOPAN 0
	OCTAVE 4
	NOTE D_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE G#, 2
	AUTOPAN 0
	OCTAVE 4
	NOTE D_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	RELEASE 9, 1
	OCTAVE 3
	NOTE G_, 1
	PAN_RIGHT 0
	OCTAVE 4
	NOTE B_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE G_, 2
	AUTOPAN 0
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	NOTE G_, 2
	AUTOPAN 0
	NOTE B_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	NOTE G_, 2
	AUTOPAN 0
	NOTE B_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	RELEASE 9, 1
	OCTAVE 3
	NOTE F#, 1
	PAN_RIGHT 0
	OCTAVE 5
	NOTE C_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE F#, 2
	AUTOPAN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	RELEASE 0, 0
	PAN_BOTH 0
	DUTY 8
	OCTAVE 3
	NOTE A#, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE G_, 2
	ENVELOPE $0E
	VIBRATO $01, 3, 3
	NOTE A_, 0
	NOTE F_, 8
	ENVELOPE $00
	VIBRATO_OFF
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	ENVELOPE $0E
	VIBRATO $01, 3, 3
	NOTE E_, 0
	ENVELOPE $00
	VIBRATO_OFF
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE E_, 2
	VIBRATO $04, 0, 3
	NOTE G_, 4
	VIBRATO_OFF
	NOTE F_, 2
	VIBRATO $01, 2, 3
	NOTE E_, 4
	ENVELOPE $0E
	VIBRATO $01, 3, 3
	NOTE F_, 0
	NOTE G_, 0
	NOTE A_, 8
	NOTE F#, 8
	ENVELOPE $00
	VIBRATO_OFF
	NOTE G_, 2
	RELEASE 9, 1
	NOTE C_HI, 2
	RELEASE 0, 0
	NOTE F#, 2
	RELEASE 9, 1
	NOTE C_HI, 2
	RELEASE 0, 0
	NOTE F_, 2
	RELEASE 9, 1
	NOTE C_HI, 2
	RELEASE 0, 0
	NOTE D_, 2
	RELEASE 9, 1
	NOTE C_HI, 2
	RELEASE 0, 0
	LOOP_START
	OCTAVE 3
	NOTE E_, 3
	NOTE F#, 3
	NOTE G_, 2
	VIBRATO $01, 2, 3
	NOTE E_, 8
	VIBRATO_OFF
	NOTE F#, 3
	NOTE G_, 3
	NOTE G#, 2
	VIBRATO $01, 1, 1
	NOTE A_, 4
	OCTAVE 4
	NOTE C_, 4
	LOOP_BREAK $FB
	VIBRATO_OFF
	NOTE D_, 3
	NOTE D#, 3
	NOTE E_, 2
	NOTE F_, 8
	DUTY 4
	DUTY_STEP 8, 1
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 2
	NOTE B_, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 2
	NOTE A#, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 2
	NOTE A_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 2
	NOTE G_, 1
	ATTEN 0
	RELEASE 9, 1
	NOTE F#, 2
	NOTE D_, 2
	DUTY_STEP 0, 0
	DUTY 8
	RELEASE 0, 0
	LOOP_END $02
	VIBRATO_OFF
	NOTE D_, 3
	NOTE C#, 3
	NOTE C_, 2
	VIBRATO $01, 3, 2
	OCTAVE 3
	NOTE B_, 12
	REST 4
	VIBRATO_OFF
	SND_LOOP

SndE7_Ch3:
	SND_SEGNO
	VOICE $06, 1, 2, 0, 0
	TRANSPOSE_UP $0C
	VIBRATO $01, 2, 4
	OCTAVE 1
	NOTE G_, 8
	LOOP_START
	OCTAVE 2
	NOTE C_, 1
	RELEASE 9, 1
	WAVE 0
	NOTE C_HI, 2
	WAVE 1
	RELEASE 0, 0
	NOTE G_, 2
	RELEASE 9, 1
	WAVE 0
	OCTAVE 3
	NOTE C_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	REST 1
	NOTE G_, 1
	RELEASE 9, 1
	WAVE 0
	OCTAVE 3
	NOTE C_, 2
	WAVE 1
	RELEASE 0, 0
	OCTAVE 1
	NOTE G_, 1
	WAVE 0
	RELEASE 9, 1
	OCTAVE 3
	NOTE C_, 1
	RELEASE 0, 0
	SND_CALL SndE7_Ch3_61E8
	LOOP_END $03
	SND_CALL SndE7_Ch3_61E8
	OCTAVE 2
	RELEASE 9, 1
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	REST 2
	RELEASE 0, 0
	NOTE G#, 2
	NOTE G_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE F_, 2
	RELEASE 9, 1
	WAVE 0
	OCTAVE 3
	NOTE C_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE C_, 3
	OCTAVE 1
	NOTE F_, 2
	RELEASE 9, 1
	WAVE 0
	OCTAVE 3
	NOTE C_, 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE C_, 2
	RELEASE 9, 1
	WAVE 0
	NOTE C_HI, 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 1
	NOTE G_, 2
	RELEASE 9, 1
	WAVE 0
	OCTAVE 2
	NOTE B_, 1
	RELEASE 0, 0
	WAVE 1
	NOTE D_, 3
	OCTAVE 1
	NOTE G_, 2
	RELEASE 9, 1
	WAVE 0
	OCTAVE 2
	NOTE B_, 2
	RELEASE 0, 0
	WAVE 1
	NOTE D_, 2
	RELEASE 9, 1
	WAVE 0
	NOTE B_, 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE E_, 2
	RELEASE 9, 1
	WAVE 0
	OCTAVE 3
	NOTE D_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 1
	NOTE B_, 3
	OCTAVE 2
	NOTE E_, 2
	RELEASE 9, 1
	WAVE 0
	OCTAVE 3
	NOTE D_, 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 1
	NOTE B_, 2
	RELEASE 9, 1
	WAVE 0
	OCTAVE 3
	NOTE D_, 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 2
	NOTE D#, 2
	RELEASE 9, 1
	WAVE 0
	OCTAVE 3
	NOTE D#, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 1
	NOTE A#, 3
	OCTAVE 2
	NOTE D#, 2
	RELEASE 9, 1
	WAVE 0
	OCTAVE 3
	NOTE D#, 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 1
	NOTE A#, 2
	RELEASE 9, 1
	WAVE 0
	OCTAVE 3
	NOTE D#, 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE D#, 2
	OCTAVE 2
	NOTE D_, 2
	RELEASE 9, 1
	WAVE 0
	OCTAVE 3
	NOTE C_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 1
	NOTE A_, 3
	OCTAVE 2
	NOTE D_, 2
	RELEASE 9, 1
	WAVE 0
	OCTAVE 3
	NOTE C_, 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 1
	NOTE A_, 2
	RELEASE 9, 1
	WAVE 0
	OCTAVE 3
	NOTE C_, 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE G#, 2
	RELEASE 9, 1
	WAVE 0
	OCTAVE 3
	NOTE D_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE D_, 3
	OCTAVE 1
	NOTE G#, 2
	RELEASE 9, 1
	WAVE 0
	OCTAVE 3
	NOTE D_, 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE D_, 2
	RELEASE 9, 1
	WAVE 0
	NOTE C_HI, 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 2
	NOTE E_, 2
	RELEASE 9, 1
	WAVE 0
	OCTAVE 3
	NOTE D_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 1
	NOTE B_, 3
	OCTAVE 2
	NOTE E_, 2
	RELEASE 9, 1
	WAVE 0
	OCTAVE 3
	NOTE D_, 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 1
	NOTE B_, 2
	RELEASE 9, 1
	WAVE 0
	OCTAVE 3
	NOTE D_, 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 2
	NOTE D#, 2
	RELEASE 9, 1
	WAVE 0
	OCTAVE 3
	NOTE D#, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 1
	NOTE A_, 3
	OCTAVE 2
	NOTE D#, 2
	RELEASE 9, 1
	WAVE 0
	OCTAVE 3
	NOTE E_, 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 1
	NOTE A_, 2
	RELEASE 9, 1
	WAVE 0
	OCTAVE 3
	NOTE D#, 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE D#, 2
	SND_CALL SndE7_Ch3_6231
	ATTEN 0
	OCTAVE 1
	NOTE G_, 1
	ATTEN 1
	RELEASE 9, 1
	AUTOPAN 0
	OCTAVE 4
	NOTE D_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 2
	NOTE D_, 1
	ATTEN 1
	RELEASE 9, 1
	AUTOPAN 0
	OCTAVE 4
	NOTE D_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 1
	RELEASE 0, 0
	NOTE G_, 1
	AUTOPAN 0
	ATTEN 1
	OCTAVE 4
	RELEASE 9, 1
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE D_, 1
	RELEASE 0, 0
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	NOTE D_, 2
	ATTEN 1
	AUTOPAN 0
	OCTAVE 4
	RELEASE 9, 1
	NOTE D_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 1
	RELEASE 0, 0
	NOTE G_, 2
	ATTEN 0
	OCTAVE 2
	NOTE E_, 1
	ATTEN 1
	RELEASE 9, 1
	AUTOPAN 0
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 1
	NOTE B_, 1
	ATTEN 1
	RELEASE 9, 1
	AUTOPAN 0
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	RELEASE 0, 0
	NOTE E_, 1
	AUTOPAN 0
	ATTEN 1
	OCTAVE 3
	RELEASE 9, 1
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	RELEASE 0, 0
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 1
	NOTE B_, 2
	ATTEN 1
	AUTOPAN 0
	OCTAVE 3
	RELEASE 9, 1
	NOTE B_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	RELEASE 0, 0
	NOTE E_, 2
	ATTEN 0
	OCTAVE 2
	NOTE D#, 1
	ATTEN 1
	RELEASE 9, 1
	AUTOPAN 0
	OCTAVE 3
	NOTE A#, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 1
	NOTE A#, 1
	ATTEN 1
	RELEASE 9, 1
	AUTOPAN 0
	OCTAVE 3
	NOTE A#, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	RELEASE 0, 0
	NOTE D#, 1
	AUTOPAN 0
	ATTEN 1
	OCTAVE 3
	RELEASE 9, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	RELEASE 0, 0
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 1
	NOTE A#, 2
	ATTEN 1
	AUTOPAN 0
	OCTAVE 3
	RELEASE 9, 1
	NOTE A#, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	RELEASE 0, 0
	NOTE D#, 2
	ATTEN 0
	OCTAVE 2
	NOTE D_, 1
	ATTEN 1
	RELEASE 9, 1
	AUTOPAN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 1
	NOTE A_, 1
	ATTEN 1
	RELEASE 9, 1
	AUTOPAN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	RELEASE 0, 0
	NOTE D_, 1
	AUTOPAN 0
	ATTEN 1
	OCTAVE 4
	RELEASE 9, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	RELEASE 0, 0
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 1
	NOTE A_, 2
	ATTEN 1
	AUTOPAN 0
	OCTAVE 4
	RELEASE 9, 1
	NOTE C_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	RELEASE 0, 0
	NOTE D_, 2
	ATTEN 0
	OCTAVE 2
	NOTE E_, 1
	ATTEN 1
	RELEASE 9, 1
	AUTOPAN 0
	OCTAVE 4
	NOTE D_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 1
	NOTE B_, 1
	ATTEN 1
	RELEASE 9, 1
	AUTOPAN 0
	OCTAVE 4
	NOTE D_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	RELEASE 0, 0
	NOTE E_, 1
	AUTOPAN 0
	ATTEN 1
	OCTAVE 4
	RELEASE 9, 1
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE D_, 1
	RELEASE 0, 0
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 1
	NOTE B_, 2
	ATTEN 1
	AUTOPAN 0
	OCTAVE 4
	RELEASE 9, 1
	NOTE D_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	RELEASE 0, 0
	NOTE E_, 2
	SND_CALL SndE7_Ch3_6231
	OCTAVE 1
	NOTE G_, 3
	OCTAVE 2
	NOTE D_, 3
	NOTE G_, 2
	NOTE D_, 4
	OCTAVE 1
	NOTE G_, 4
	OCTAVE 1
	NOTE C_, 0
	NOTE D_, 0
	NOTE G_, 0
	NOTE G_, 8
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 0
	NOTE D_, 0
	NOTE G_, 0
	NOTE G_, 4
	RELEASE 9, 2
	NOTE C_HI, 2
	REST 2
	SND_LOOP

SndE7_Drm:
	LEN_UNIT $06
	SND_SEGNO
	DRUM 9, 8
	LOOP2_START
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $02
	LOOP_BREAK $FC
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP2_END $02
	DRUM 3, 1
	DRUM 5, 2
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 2
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $0B
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $02
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 9, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $07
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 9, 1
	SND_LOOP
SndE7_Ch3_61E8:
	WAVE 1
	OCTAVE 1
	NOTE F_, 1
	RELEASE 9, 1
	WAVE 0
	OCTAVE 2
	NOTE A_, 2
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE C_, 1
	WAVE 0
	RELEASE 9, 1
	OCTAVE 2
	NOTE A_, 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 1
	NOTE F_, 1
	WAVE 0
	RELEASE 9, 1
	OCTAVE 3
	NOTE C_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 1
	NOTE G_, 2
	RELEASE 9, 1
	WAVE 0
	OCTAVE 2
	NOTE B_, 1
	RELEASE 0, 0
	WAVE 1
	NOTE D_, 2
	RELEASE 9, 1
	WAVE 0
	NOTE B_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 1
	NOTE G_, 1
	RELEASE 9, 1
	WAVE 0
	OCTAVE 3
	NOTE D_, 1
	WAVE 1
	RELEASE 0, 0
	SND_RET
SndE7_Ch3_6231:
	ATTEN 0
	OCTAVE 1
	NOTE F_, 1
	ATTEN 1
	RELEASE 9, 1
	AUTOPAN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 2
	NOTE C_, 1
	ATTEN 1
	RELEASE 9, 1
	AUTOPAN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 1
	RELEASE 0, 0
	NOTE F_, 1
	AUTOPAN 0
	ATTEN 1
	OCTAVE 4
	RELEASE 9, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	RELEASE 0, 0
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 2
	NOTE C_, 2
	ATTEN 1
	AUTOPAN 0
	OCTAVE 4
	RELEASE 9, 1
	NOTE C_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 1
	RELEASE 0, 0
	NOTE F_, 2
	SND_RET

SndE8_Ch2:
	TEMPO $90
	SND_SEGNO
	VOICE $06, 4, 8, 0, 0
	ENVELOPE $0C
	VIBRATO $01, 5, 2
	OCTAVE 4
	NOTE A#, 0
	NOTE G#, 0
	NOTE G_, 0
	NOTE F_, 0
	NOTE D_, 0
	NOTE D#, 0
	ENVELOPE $00
	NOTE F_, 8
	NOTE G_, 8
	NOTE G#, 8
	NOTE A#, 8
	VIBRATO_OFF
	DUTY 4
	NOTE G_, 1
	ATTEN 4
	DUTY 8
	NOTE G_, 1
	ATTEN 0
	OCTAVE 3
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE D#, 1
	DUTY 8
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	OCTAVE 3
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE G_, 1
	DUTY 8
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	DUTY 4
	NOTE A#, 1
	DUTY 8
	ATTEN 4
	NOTE A#, 1
	ATTEN 0
	OCTAVE 3
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE G#, 1
	ATTEN 4
	DUTY 8
	NOTE G#, 1
	ATTEN 0
	OCTAVE 3
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE F_, 1
	DUTY 8
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	OCTAVE 3
	NOTE G#, 1
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE G#, 1
	DUTY 8
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	OCTAVE 5
	DUTY 4
	NOTE C_, 1
	DUTY 8
	ATTEN 4
	NOTE C_, 1
	ATTEN 0
	OCTAVE 3
	NOTE G#, 1
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	VIBRATO $01, 5, 2
	DUTY 4
	OCTAVE 4
	NOTE A#, 10
	OCTAVE 5
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	OCTAVE 4
	NOTE D#, 8
	NOTE C#, 8
	VIBRATO_OFF
	SND_CALL SndE8_Ch2_6AC9
	DUTY 4
	OCTAVE 4
	NOTE D_, 1
	ATTEN 4
	DUTY 8
	NOTE D_, 1
	ATTEN 0
	OCTAVE 3
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE D#, 1
	DUTY 8
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	OCTAVE 3
	NOTE G#, 1
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE D#, 1
	DUTY 8
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	DUTY 4
	NOTE F_, 1
	DUTY 8
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	OCTAVE 3
	NOTE G#, 1
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE G_, 1
	ATTEN 4
	DUTY 8
	NOTE G_, 1
	ATTEN 0
	OCTAVE 3
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	DUTY 4
	VIBRATO $01, 2, 2
	OCTAVE 4
	NOTE D_, 4
	NOTE F_, 4
	VIBRATO $05, 0, 1
	NOTE A#, 4
	VIBRATO $01, 3, 2
	NOTE G_, 4
	VIBRATO_OFF
	NOTE F_, 4
	NOTE D#, 4
	NOTE D_, 4
	SND_CALL SndE8_Ch2_6AC9
	DUTY 4
	OCTAVE 4
	NOTE F_, 1
	ATTEN 4
	DUTY 8
	NOTE F_, 1
	ATTEN 0
	OCTAVE 3
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE G_, 1
	DUTY 8
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	OCTAVE 3
	NOTE G#, 1
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE G_, 1
	DUTY 8
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	DUTY 4
	NOTE G#, 1
	DUTY 8
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	OCTAVE 3
	NOTE G#, 1
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	DUTY 4
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE B_, 4
	VIBRATO $01, 2, 2
	NOTE G_, 4
	NOTE B_, 4
	VIBRATO_OFF
	NOTE D_, 4
	VIBRATO $01, 2, 2
	NOTE F_, 8
	NOTE D#, 8
	VIBRATO_OFF
	DUTY 4
	NOTE G_, 1
	ATTEN 4
	DUTY 8
	NOTE G_, 1
	ATTEN 0
	OCTAVE 3
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	DUTY 4
	VIBRATO $01, 4, 2
	OCTAVE 4
	NOTE D#, 10
	VIBRATO_OFF
	DUTY 4
	OCTAVE 4
	NOTE F_, 1
	ATTEN 4
	DUTY 8
	NOTE F_, 1
	ATTEN 0
	OCTAVE 3
	NOTE A_, 1
	ATTEN 4
	NOTE A_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 4
	NOTE A_, 1
	ATTEN 0
	DUTY 4
	VIBRATO $01, 4, 2
	OCTAVE 4
	NOTE A_, 10
	VIBRATO_OFF
	OCTAVE 5
	VIBRATO $04, 0, 2
	NOTE C_, 2
	VIBRATO $01, 5, 2
	NOTE C_, 14
	OCTAVE 4
	NOTE A#, 0
	VIBRATO_OFF
	OCTAVE 3
	DUTY 8
	REST 2
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 6
	NOTE G_, 1
	ATTEN 0
	REST 1
	NOTE G_, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 6
	NOTE G_, 1
	ATTEN 0
	REST 3
	NOTE G_, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 6
	NOTE G_, 1
	ATTEN 0
	REST 1
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 3
	NOTE F_, 1
	ATTEN 6
	NOTE F_, 1
	ATTEN 0
	REST 1
	NOTE G#, 1
	ATTEN 3
	NOTE G#, 1
	ATTEN 6
	NOTE G#, 1
	ATTEN 0
	REST 3
	NOTE G#, 1
	ATTEN 3
	NOTE G#, 1
	ATTEN 6
	NOTE G#, 1
	ATTEN 0
	REST 1
	OCTAVE 3
	DUTY 8
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 6
	NOTE G_, 1
	ATTEN 0
	REST 1
	NOTE G_, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 6
	NOTE G_, 1
	ATTEN 0
	REST 3
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 4
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
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	VIBRATO $01, 0, 3
	NOTE F_, 2
	VIBRATO_OFF
	LOOP_START
	OCTAVE 3
	DUTY 8
	RELEASE $0B, 1
	NOTE A#, 1
	NOTE C_HI, 1
	RELEASE 0, 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	RELEASE $0B, 1
	NOTE A#, 1
	NOTE C_HI, 1
	RELEASE 0, 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	RELEASE $0B, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE C_HI, 1
	RELEASE 0, 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	RELEASE $0B, 1
	NOTE A#, 1
	NOTE C_HI, 1
	RELEASE 0, 0
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	RELEASE $0B, 1
	NOTE A#, 1
	NOTE C_HI, 1
	RELEASE 0, 0
	NOTE G#, 1
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	RELEASE $0B, 1
	NOTE A#, 1
	NOTE C_HI, 1
	NOTE A#, 1
	NOTE C_HI, 1
	RELEASE 0, 0
	NOTE G#, 1
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	LOOP_END $02
	SND_LOOP

SndE8_Ch1:
	SND_SEGNO
	VOICE $06, 12, 8, 0, 0
	ENVELOPE $0C
	VIBRATO $01, 5, 2
	OCTAVE 4
	NOTE D_, 0
	NOTE D#, 0
	NOTE E_, 0
	NOTE D_, 0
	ENVELOPE $00
	RELEASE 9, 1
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE F_, 2
	NOTE A#, 2
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	OCTAVE 3
	NOTE A#, 10
	VIBRATO_OFF
	RELEASE 9, 1
	OCTAVE 4
	NOTE C_, 2
	NOTE F_, 2
	NOTE A#, 2
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	NOTE C_, 10
	VIBRATO_OFF
	RELEASE 9, 1
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	NOTE D_, 4
	VIBRATO_OFF
	RELEASE 9, 1
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	NOTE D#, 4
	VIBRATO_OFF
	RELEASE 9, 1
	OCTAVE 4
	NOTE D_, 2
	NOTE D#, 2
	NOTE F_, 2
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	NOTE D#, 4
	NOTE D_, 6
	VIBRATO_OFF
	DUTY 4
	NOTE D#, 1
	ATTEN 4
	DUTY 8
	NOTE D#, 1
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	DUTY 4
	NOTE A#, 1
	DUTY 8
	ATTEN 4
	NOTE A#, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE D#, 1
	DUTY 8
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	DUTY 4
	NOTE G_, 1
	DUTY 8
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE F_, 1
	ATTEN 4
	DUTY 8
	NOTE F_, 1
	ATTEN 0
	OCTAVE 3
	NOTE D_, 1
	ATTEN 4
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 4
	NOTE D_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE D_, 1
	DUTY 8
	ATTEN 4
	NOTE D_, 1
	ATTEN 0
	OCTAVE 3
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE F_, 1
	DUTY 8
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	DUTY 4
	NOTE G#, 1
	DUTY 8
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	OCTAVE 3
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	RELEASE $0B, 1
	DUTY 0
	NOTE G_, 2
	DUTY 8
	RELEASE 0, 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	RELEASE $0B, 1
	DUTY 0
	NOTE D#, 2
	RELEASE 0, 0
	DUTY 8
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	RELEASE $0B, 1
	DUTY 0
	NOTE F_, 2
	NOTE G_, 2
	DUTY 8
	RELEASE 0, 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	RELEASE $0B, 1
	DUTY 0
	NOTE F#, 2
	DUTY 8
	RELEASE 0, 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	RELEASE $0B, 1
	DUTY 0
	NOTE F_, 2
	RELEASE 0, 0
	DUTY 8
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	RELEASE $0B, 1
	DUTY 0
	NOTE G_, 2
	NOTE G#, 2
	DUTY 8
	RELEASE 0, 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	SND_CALL SndE8_Ch1_6AFF
	DUTY 4
	NOTE A#, 1
	ATTEN 4
	DUTY 8
	NOTE A#, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 4
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 4
	NOTE D_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE C_, 1
	DUTY 8
	ATTEN 4
	NOTE C_, 1
	ATTEN 0
	OCTAVE 3
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE C_, 1
	DUTY 8
	ATTEN 4
	NOTE C_, 1
	ATTEN 0
	DUTY 4
	NOTE D_, 1
	DUTY 8
	ATTEN 4
	NOTE D_, 1
	ATTEN 0
	OCTAVE 3
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE D#, 1
	ATTEN 4
	DUTY 8
	NOTE D#, 1
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	DUTY 0
	NOTE G#, 2
	DUTY 8
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	DUTY 0
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	DUTY 8
	OCTAVE 3
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	DUTY 0
	NOTE D#, 2
	DUTY 8
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	DUTY 0
	NOTE D_, 2
	DUTY 8
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	DUTY 0
	NOTE G_, 2
	NOTE F_, 2
	DUTY 8
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	SND_CALL SndE8_Ch1_6AFF
	DUTY 4
	OCTAVE 4
	NOTE D_, 1
	ATTEN 4
	DUTY 8
	NOTE D_, 1
	ATTEN 0
	OCTAVE 3
	NOTE D_, 1
	ATTEN 4
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 4
	NOTE D_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE D#, 1
	DUTY 8
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	OCTAVE 3
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE D#, 1
	DUTY 8
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE F_, 1
	DUTY 8
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	OCTAVE 3
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	DUTY 0
	NOTE B_, 2
	DUTY 8
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	DUTY 0
	NOTE A_, 2
	DUTY 8
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	DUTY 0
	NOTE A_, 2
	NOTE B_, 2
	DUTY 8
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 4
	NOTE C_, 2
	DUTY 8
	OCTAVE 3
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	DUTY 0
	NOTE A#, 2
	DUTY 8
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	DUTY 8
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE D#, 1
	ATTEN 4
	DUTY 8
	NOTE D#, 1
	ATTEN 0
	DUTY 8
	OCTAVE 3
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE C_, 1
	DUTY 8
	ATTEN 4
	NOTE C_, 1
	ATTEN 0
	DUTY 8
	OCTAVE 3
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	VIBRATO $01, 1, 2
	OCTAVE 4
	NOTE C_, 4
	VIBRATO_OFF
	OCTAVE 3
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE C_, 1
	ATTEN 4
	DUTY 8
	NOTE C_, 1
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE F_, 1
	DUTY 8
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	DUTY 8
	OCTAVE 3
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	VIBRATO $01, 1, 2
	OCTAVE 4
	NOTE F_, 4
	VIBRATO_OFF
	OCTAVE 3
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	DUTY 0
	NOTE D#, 2
	DUTY 8
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 4
	NOTE D#, 2
	DUTY 8
	OCTAVE 3
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	DUTY 0
	NOTE D#, 2
	OCTAVE 4
	NOTE D#, 2
	DUTY 8
	OCTAVE 3
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	DUTY 0
	NOTE D_, 2
	DUTY 8
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	DUTY 0
	NOTE A#, 2
	DUTY 8
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	NOTE D_, 2
	NOTE D#, 2
	NOTE F_, 2
	OCTAVE 3
	REST 2
	LOOP_START
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 3
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 0
	REST 1
	NOTE D#, 1
	ATTEN 3
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 0
	REST 3
	NOTE D#, 1
	ATTEN 3
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 0
	REST 1
	NOTE D_, 1
	ATTEN 4
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 6
	NOTE D_, 1
	ATTEN 0
	REST 1
	NOTE F_, 1
	ATTEN 3
	NOTE F_, 1
	ATTEN 6
	NOTE F_, 1
	ATTEN 0
	REST 3
	NOTE F_, 1
	ATTEN 3
	NOTE F_, 1
	ATTEN 6
	NOTE F_, 1
	ATTEN 0
	REST 1
	OCTAVE 3
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 3
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 0
	REST 1
	NOTE D#, 1
	ATTEN 3
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 0
	REST 3
	NOTE D#, 1
	ATTEN 3
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 0
	REST 1
	LOOP_BREAK $FB
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 3
	NOTE F_, 1
	ATTEN 6
	NOTE F_, 1
	ATTEN 0
	REST 1
	NOTE F_, 1
	ATTEN 3
	NOTE F_, 1
	ATTEN 6
	NOTE F_, 1
	ATTEN 0
	REST 3
	NOTE G#, 1
	ATTEN 3
	NOTE G#, 1
	ATTEN 6
	NOTE G#, 1
	ATTEN 0
	REST 1
	LOOP_END $02
	NOTE D_, 1
	ATTEN 4
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 6
	NOTE D_, 1
	ATTEN 0
	REST 1
	NOTE F_, 1
	ATTEN 3
	NOTE F_, 1
	ATTEN 6
	NOTE F_, 1
	ATTEN 0
	REST 3
	NOTE F_, 1
	ATTEN 4
	NOTE F_, 1
	ATTEN 0
	SND_LOOP

SndE8_Ch3:
	SND_SEGNO
	VOICE $06, 1, 2, 0, 0
	LOOP_START
	OCTAVE 2
	NOTE A#, 2
	NOTE C_HI, 2
	OCTAVE 4
	NOTE F_, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE C_HI, 2
	RELEASE 6, 2
	NOTE A#, 2
	NOTE A#, 2
	RELEASE 0, 0
	OCTAVE 4
	NOTE F_, 2
	LOOP_END $07
	OCTAVE 3
	NOTE C_, 2
	NOTE C_HI, 2
	OCTAVE 4
	NOTE F_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 4
	NOTE D_, 2
	RELEASE 6, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 2
	RELEASE 0, 0
	OCTAVE 4
	NOTE F_, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	NOTE D#, 2
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	RELEASE 6, 2
	NOTE D#, 2
	RELEASE 0, 0
	NOTE D#, 2
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	OCTAVE 3
	NOTE F_, 2
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	NOTE F_, 2
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	RELEASE 6, 2
	NOTE F_, 2
	RELEASE 0, 0
	NOTE F_, 2
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE D#, 1
	ATTEN 1
	NOTE D#, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 1
	NOTE D#, 1
	ATTEN 0
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE D#, 1
	ATTEN 1
	NOTE D#, 1
	ATTEN 0
	RELEASE 6, 2
	OCTAVE 3
	NOTE G_, 2
	RELEASE 0, 0
	NOTE G_, 2
	OCTAVE 4
	NOTE D#, 1
	ATTEN 1
	NOTE D#, 1
	ATTEN 0
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 4
	NOTE C#, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	NOTE C#, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 4
	NOTE C#, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	RELEASE 6, 2
	OCTAVE 3
	NOTE C#, 2
	RELEASE 0, 0
	NOTE C#, 2
	OCTAVE 4
	NOTE C#, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	LOOP_START
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	RELEASE 6, 2
	OCTAVE 2
	NOTE G#, 2
	RELEASE 0, 0
	NOTE G#, 2
	OCTAVE 3
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	RELEASE 6, 2
	OCTAVE 2
	NOTE A#, 2
	RELEASE 0, 0
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	LOOP_BREAK $FB
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 0
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 0
	RELEASE 6, 2
	OCTAVE 2
	NOTE B_, 2
	RELEASE 0, 0
	NOTE B_, 2
	OCTAVE 3
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 4
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 4
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	RELEASE 6, 2
	OCTAVE 2
	NOTE A#, 2
	RELEASE 0, 0
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	LOOP_END $02
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	RELEASE 6, 2
	OCTAVE 2
	NOTE B_, 2
	RELEASE 0, 0
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 4
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 4
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	RELEASE 6, 2
	OCTAVE 3
	NOTE C_, 2
	RELEASE 0, 0
	NOTE C_, 2
	OCTAVE 4
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	RELEASE 6, 2
	OCTAVE 2
	NOTE A_, 2
	RELEASE 0, 0
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	RELEASE 6, 2
	OCTAVE 3
	NOTE F_, 2
	RELEASE 0, 0
	NOTE F_, 2
	OCTAVE 4
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	RELEASE 6, 2
	OCTAVE 2
	NOTE A_, 2
	RELEASE 0, 0
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 2
	LOOP_START
	OCTAVE 3
	NOTE D#, 2
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	NOTE D#, 2
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	RELEASE 6, 2
	NOTE D#, 2
	RELEASE 0, 0
	NOTE D#, 2
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	LOOP_END $08
	SND_LOOP

SndE8_Drm:
	LEN_UNIT $06
	SND_SEGNO
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $05
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $06
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $05
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $02
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	SND_LOOP
SndE8_Ch2_6AC9:
	DUTY 4
	NOTE C_, 1
	ATTEN 4
	DUTY 8
	NOTE C_, 1
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE D_, 1
	DUTY 8
	ATTEN 4
	NOTE D_, 1
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE D_, 1
	DUTY 8
	ATTEN 4
	NOTE D_, 1
	ATTEN 0
	DUTY 4
	NOTE D#, 1
	DUTY 8
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	SND_RET
SndE8_Ch1_6AFF:
	DUTY 4
	NOTE G#, 1
	ATTEN 4
	DUTY 8
	NOTE G#, 1
	ATTEN 0
	NOTE C_, 1
	ATTEN 4
	NOTE C_, 1
	ATTEN 0
	NOTE C_, 1
	ATTEN 4
	NOTE C_, 1
	ATTEN 0
	DUTY 4
	NOTE A#, 1
	DUTY 8
	ATTEN 4
	NOTE A#, 1
	ATTEN 0
	NOTE C_, 1
	ATTEN 4
	NOTE C_, 1
	ATTEN 0
	DUTY 4
	NOTE A#, 1
	DUTY 8
	ATTEN 4
	NOTE A#, 1
	ATTEN 0
	DUTY 4
	OCTAVE 4
	NOTE C_, 1
	DUTY 8
	ATTEN 4
	NOTE C_, 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 1
	ATTEN 4
	NOTE C_, 1
	ATTEN 0
	SND_RET

SndE9_Ch2:
	VOICE $04, 4, 15, 7, 0
	DUTY_STEP 0, 1
	LOOP_START
	SND_CALL SndE9_Ch2_6EE5
	ATTEN 4
	RELEASE 0, 0
	NOTE A#, 4
	ATTEN 0
	RELEASE 7, 0
	NOTE C_, 2
	ATTEN 4
	VIBRATO $05, 0, 4
	RELEASE 0, 0
	NOTE A#, 4
	VIBRATO_OFF
	RELEASE 7, 0
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	LOOP_END $02
	SND_SEGNO
	LOOP2_START
	SND_CALL SndE9_Ch2_6EE5
	ATTEN 4
	RELEASE 0, 0
	NOTE B_, 4
	LOOP_START
	ATTEN 0
	RELEASE 7, 0
	OCTAVE 1
	NOTE B_, 2
	ATTEN 4
	VIBRATO $05, 0, 4
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 4
	LOOP_END $02
	VIBRATO_OFF
	OCTAVE 1
	RELEASE 7, 0
	ATTEN 0
	NOTE A#, 2
	NOTE A#, 2
	RELEASE 0, 0
	ATTEN 4
	VIBRATO $05, 0, 4
	OCTAVE 3
	NOTE C_, 4
	ATTEN 0
	VIBRATO_OFF
	RELEASE 7, 0
	OCTAVE 1
	NOTE A#, 2
	ATTEN 4
	RELEASE 0, 0
	OCTAVE 3
	NOTE C_, 4
	ATTEN 0
	RELEASE 7, 0
	OCTAVE 1
	NOTE A#, 2
	ATTEN 4
	RELEASE 0, 0
	OCTAVE 3
	NOTE C_, 4
	LOOP_START
	ATTEN 0
	RELEASE 7, 0
	OCTAVE 1
	NOTE A_, 2
	ATTEN 4
	VIBRATO $05, 0, 4
	RELEASE 0, 0
	OCTAVE 3
	NOTE C_, 4
	LOOP_END $02
	VIBRATO_OFF
	OCTAVE 1
	RELEASE 7, 0
	ATTEN 0
	NOTE G#, 2
	NOTE G#, 2
	RELEASE 0, 0
	ATTEN 4
	VIBRATO $05, 0, 4
	NOTE C_HI, 4
	ATTEN 0
	VIBRATO_OFF
	RELEASE 7, 0
	OCTAVE 1
	NOTE G#, 2
	ATTEN 4
	RELEASE 0, 0
	NOTE C_HI, 4
	ATTEN 0
	RELEASE 7, 0
	OCTAVE 1
	NOTE G#, 2
	ATTEN 4
	RELEASE 0, 0
	OCTAVE 2
	NOTE A#, 4
	ATTEN 0
	RELEASE 7, 0
	OCTAVE 1
	NOTE A#, 2
	ATTEN 4
	VIBRATO $05, 0, 4
	RELEASE 0, 0
	NOTE C_HI, 4
	VIBRATO_OFF
	RELEASE 7, 0
	OCTAVE 2
	NOTE G#, 2
	NOTE A#, 2
	NOTE B_, 2
	SND_CALL SndE9_Ch2_6EE5
	ATTEN 4
	RELEASE 0, 0
	NOTE A#, 4
	ATTEN 0
	RELEASE 7, 0
	NOTE C_, 2
	ATTEN 4
	VIBRATO $05, 0, 4
	RELEASE 0, 0
	NOTE A#, 4
	VIBRATO_OFF
	RELEASE 7, 0
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	LOOP2_END $02
	LOOP_START
	SND_CALL SndE9_Ch2_6EE5
	ATTEN 4
	RELEASE 0, 0
	NOTE A#, 4
	ATTEN 0
	RELEASE 7, 0
	NOTE C_, 2
	ATTEN 4
	VIBRATO $05, 0, 4
	RELEASE 0, 0
	NOTE A#, 4
	VIBRATO_OFF
	RELEASE 7, 0
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	LOOP_END $05
	SND_LOOP
	db $FF ; unreachable end

SndE9_Ch1:
	VOICE $04, 4, 10, 7, 0
	DUTY_STEP 0, 1
	REST 0
	REST 0
	SND_CALL SndE9_Ch1_6EFE
	RELEASE 0, 0
	NOTE G_, 4
	RELEASE 7, 0
	NOTE G_, 2
	RELEASE 0, 0
	NOTE G_, 4
	RELEASE 7, 0
	NOTE F_, 2
	NOTE D#, 2
	NOTE F_, 2
	SND_SEGNO
	SND_CALL SndE9_Ch1_6EFE
	RELEASE 0, 0
	NOTE G_, 4
	LOOP_START
	RELEASE 7, 0
	NOTE G_, 2
	RELEASE 0, 0
	NOTE G_, 4
	LOOP_END $02
	SND_CALL SndE9_Ch1_6EFE
	RELEASE 0, 0
	NOTE F_, 4
	LOOP_START
	RELEASE 7, 0
	NOTE F_, 2
	RELEASE 0, 0
	NOTE F_, 4
	LOOP_END $02
	TRANSPOSE_DOWN 4
	SND_CALL SndE9_Ch1_6EFE
	TRANSPOSE_DOWN 0
	RELEASE 0, 0
	NOTE F_, 4
	RELEASE 7, 0
	NOTE F_, 2
	RELEASE 0, 0
	NOTE F_, 4
	RELEASE 7, 0
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	SND_CALL SndE9_Ch1_6EFE
	RELEASE 0, 0
	NOTE G_, 4
	RELEASE 7, 0
	NOTE G_, 2
	RELEASE 0, 0
	NOTE G_, 4
	RELEASE 7, 0
	NOTE F_, 2
	NOTE D#, 2
	NOTE F_, 2
	RELEASE 0, 0
	OCTAVE 2
	NOTE G_, 2
	DUTY 8
	DUTY_STEP 0, 0
	NOTE C_HI, 2
	DUTY 4
	DUTY_STEP 0, 1
	NOTE G_, 4
	DUTY 8
	DUTY_STEP 0, 0
	NOTE C_HI, 2
	DUTY 4
	DUTY_STEP 0, 1
	NOTE G_, 4
	DUTY 8
	DUTY_STEP 0, 0
	NOTE C_HI, 2
	DUTY 4
	DUTY_STEP 0, 1
	NOTE G_, 4
	LOOP_START
	DUTY 8
	DUTY_STEP 0, 0
	OCTAVE 3
	NOTE G#, 2
	DUTY 4
	DUTY_STEP 0, 1
	OCTAVE 2
	NOTE G_, 4
	LOOP_END $02
	OCTAVE 2
	NOTE G_, 2
	DUTY 8
	DUTY_STEP 0, 0
	OCTAVE 3
	NOTE A#, 2
	DUTY 4
	DUTY_STEP 0, 1
	OCTAVE 2
	NOTE G_, 4
	DUTY 8
	DUTY_STEP 0, 0
	RELEASE $0B, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	DUTY 4
	RELEASE 0, 0
	DUTY_STEP 0, 1
	OCTAVE 2
	NOTE F_, 4
	DUTY 8
	DUTY_STEP 0, 0
	OCTAVE 3
	NOTE A_, 2
	DUTY 4
	DUTY_STEP 0, 1
	OCTAVE 2
	NOTE F_, 3
	DUTY 8
	DUTY_STEP 0, 0
	RELEASE $0B, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE D#, 2
	DUTY 8
	DUTY_STEP 0, 0
	NOTE C_HI, 2
	DUTY 4
	DUTY_STEP 0, 1
	NOTE D#, 4
	DUTY 8
	DUTY_STEP 0, 0
	OCTAVE 3
	NOTE F_, 2
	DUTY 4
	DUTY_STEP 0, 1
	OCTAVE 2
	NOTE D#, 4
	DUTY 8
	DUTY_STEP 0, 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 4
	DUTY_STEP 0, 1
	OCTAVE 2
	NOTE F_, 4
	DUTY 8
	DUTY_STEP 0, 0
	OCTAVE 3
	NOTE G#, 2
	DUTY 4
	DUTY_STEP 0, 1
	OCTAVE 2
	NOTE F_, 4
	RELEASE 7, 0
	NOTE F_, 2
	NOTE F#, 2
	NOTE G_, 2
	RELEASE 0, 0
	LOOP2_START
	SND_CALL SndE9_Ch1_6EFE
	RELEASE 0, 0
	NOTE G_, 4
	RELEASE 7, 0
	NOTE G_, 2
	RELEASE 0, 0
	NOTE G_, 4
	RELEASE 7, 0
	NOTE F_, 2
	NOTE D#, 2
	NOTE F_, 2
	LOOP2_END $06
	SND_LOOP

SndE9_Ch3:
	VOICE $04, 4, 2, 8, 0
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	RELEASE 0, 0
	NOTE G_, 4
	RELEASE 8, 0
	NOTE G_, 2
	RELEASE 0, 0
	NOTE G_, 4
	RELEASE 7, 0
	NOTE G_, 2
	RELEASE 0, 0
	NOTE G_, 4
	RELEASE 7, 0
	NOTE G_, 2
	RELEASE 0, 0
	NOTE G_, 4
	RELEASE 8, 0
	NOTE F_, 2
	NOTE D#, 2
	NOTE F_, 2
	WAVE 5
	RELEASE 0, 0
	OCTAVE 6
	NOTE C_, 4
	VIBRATO $01, 0, 2
	NOTE C_, 0
	VIBRATO $03, 0, 1
	RELEASE 1, 1
	NOTE C_, 12
	VIBRATO_OFF
	SND_SEGNO
	RELEASE 0, 0
	OCTAVE 5
	VIBRATO $04, 0, 1
	NOTE G_, 6
	VIBRATO $01, 2, 3
	NOTE C_, 10
	VIBRATO_OFF
	NOTE D_, 6
	NOTE D#, 6
	NOTE F_, 4
	VIBRATO $04, 0, 1
	NOTE G_, 2
	VIBRATO $01, 3, 2
	NOTE G_, 14
	VIBRATO $03, 4, 2
	RELEASE 3, 1
	NOTE F_, 8
	VIBRATO_OFF
	RELEASE 0, 0
	NOTE C_, 4
	NOTE D_, 4
	NOTE D#, 6
	VIBRATO $04, 0, 1
	NOTE F_, 6
	VIBRATO_OFF
	NOTE G_, 4
	NOTE F_, 8
	VIBRATO $01, 3, 2
	NOTE D_, 8
	NOTE C_, 13
	VIBRATO $03, 0, 3
	NOTE C_, 3
	VIBRATO_OFF
	ATTEN 0
	PAN_LEFT 0
	WAVE 3
	RELEASE $0B, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D#, 1
	PAN_RIGHT 0
	OCTAVE 4
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE G_, 1
	NOTE B_, 1
	PAN_BOTH 0
	WAVE 5
	RELEASE 0, 0
	OCTAVE 5
	VIBRATO $04, 0, 1
	NOTE G_, 6
	VIBRATO $01, 2, 3
	NOTE C_, 10
	VIBRATO_OFF
	NOTE D_, 6
	NOTE D#, 6
	NOTE F_, 4
	NOTE G_, 6
	OCTAVE 6
	VIBRATO $04, 0, 2
	NOTE C_, 6
	VIBRATO_OFF
	OCTAVE 5
	NOTE G_, 4
	VIBRATO $03, 4, 2
	RELEASE 3, 1
	NOTE F_, 8
	RELEASE 0, 0
	VIBRATO_OFF
	NOTE D#, 4
	NOTE D_, 4
	NOTE C_, 6
	VIBRATO $01, 2, 3
	NOTE G_, 10
	VIBRATO_OFF
	NOTE F_, 8
	VIBRATO $04, 0, 1
	NOTE A#, 8
	VIBRATO $01, 6, 2
	OCTAVE 6
	NOTE C_, 0
	VIBRATO $01, 0, 2
	NOTE C_, 13
	VIBRATO $03, 0, 2
	NOTE C_, 3
	VIBRATO_OFF
	REST 8
	ATTEN 0
	PAN_LEFT 0
	WAVE 3
	RELEASE $0B, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE D#, 1
	REST 8
	PAN_RIGHT 0
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE F_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 5
	OCTAVE 5
	NOTE G_, 0
	VIBRATO $01, 0, 1
	NOTE G_, 0
	VIBRATO $01, 0, 2
	NOTE G_, 0
	VIBRATO $01, 0, 3
	NOTE G_, 13
	VIBRATO $03, 0, 2
	NOTE G_, 3
	OCTAVE 4
	VIBRATO_OFF
	NOTE C_, 6
	VIBRATO $04, 0, 1
	NOTE G_, 2
	VIBRATO $01, 2, 2
	NOTE G_, 8
	NOTE F_, 6
	NOTE A#, 6
	VIBRATO_OFF
	NOTE B_, 4
	OCTAVE 5
	NOTE C_, 6
	VIBRATO $04, 0, 1
	NOTE G_, 2
	VIBRATO $01, 2, 2
	NOTE G_, 8
	NOTE F_, 6
	NOTE A#, 6
	VIBRATO $03, 4, 1
	NOTE B_, 4
	SND_LOOP

SndE9_Drm:
	LEN_UNIT $04
	DRUM $0A, 6
	DRUM $0A, $0A
	REST $0A
	DRUM $0A, 6
	DRUM 9, 2
	DRUM 3, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM $0B, 4
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	SND_SEGNO
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $0D
	LOOP_START
	DRUM 9, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	LOOP_END $02
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $11
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	LOOP_START
	DRUM 9, 2
	DRUM 7, 2
	DRUM $0A, 4
	DRUM 3, 2
	DRUM 7, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM $0A, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 7, 2
	LOOP_END $03
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 2
	DRUM $0A, 2
	DRUM 3, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	SND_LOOP
	db $FF ; unreachable end
SndE9_Ch2_6EE5:
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	RELEASE 0, 0
	ATTEN 4
	VIBRATO $05, 0, 4
	NOTE C_HI, 4
	ATTEN 0
	VIBRATO_OFF
	RELEASE 7, 0
	NOTE C_, 2
	ATTEN 4
	RELEASE 0, 0
	NOTE C_HI, 4
	ATTEN 0
	RELEASE 7, 0
	NOTE C_, 2
	SND_RET
SndE9_Ch1_6EFE:
	RELEASE 7, 0
	OCTAVE 2
	NOTE G_, 2
	NOTE G_, 2
	RELEASE 0, 0
	NOTE G_, 4
	RELEASE 7, 0
	NOTE G_, 2
	RELEASE 0, 0
	NOTE G_, 4
	RELEASE 7, 0
	NOTE G_, 2
	SND_RET

SndEA_Ch2:
	VOICE $06, 8, 9, 9, 2
	LOOP_START
	AUTOPAN 0
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE E_, 2
	OCTAVE 4
	NOTE A_, 1
	NOTE G_, 2
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE A_, 2
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE A_, 2
	NOTE G_, 1
	OCTAVE 5
	NOTE D_, 1
	REST 1
	NOTE D_, 1
	LOOP_END $04
	PAN_BOTH 0
	SND_SEGNO
	VOICE $06, 8, 15, 0, 0
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	RELEASE $0B, 1
	ATTEN 5
	OCTAVE 3
	NOTE G_, 1
	RELEASE 0, 0
	ATTEN 0
	LOOP_END $02
	OCTAVE 1
	NOTE A_, 2
	ATTEN 5
	OCTAVE 3
	NOTE G_, 2
	ATTEN 0
	OCTAVE 1
	NOTE A_, 1
	RELEASE $0B, 1
	ATTEN 5
	OCTAVE 3
	NOTE G_, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 1
	NOTE A_, 2
	RELEASE $0B, 1
	ATTEN 5
	OCTAVE 3
	NOTE G_, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 1
	NOTE G_, 1
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	RELEASE $0B, 1
	ATTEN 5
	OCTAVE 3
	NOTE A_, 1
	RELEASE 0, 0
	ATTEN 0
	LOOP_END $02
	OCTAVE 1
	NOTE A_, 2
	ATTEN 5
	OCTAVE 3
	NOTE A_, 2
	ATTEN 0
	OCTAVE 1
	NOTE A_, 1
	RELEASE $0B, 1
	ATTEN 5
	OCTAVE 3
	NOTE A_, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 1
	NOTE A#, 2
	RELEASE $0B, 1
	ATTEN 5
	OCTAVE 3
	NOTE A_, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 2
	NOTE C_, 1
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	RELEASE $0B, 1
	ATTEN 5
	OCTAVE 3
	NOTE A#, 1
	RELEASE 0, 0
	ATTEN 0
	LOOP_END $02
	OCTAVE 1
	NOTE A_, 2
	ATTEN 5
	OCTAVE 3
	NOTE A#, 2
	ATTEN 0
	OCTAVE 1
	NOTE A_, 1
	RELEASE $0B, 1
	ATTEN 5
	OCTAVE 3
	NOTE A#, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 1
	NOTE A#, 2
	RELEASE $0B, 1
	ATTEN 5
	OCTAVE 3
	NOTE A#, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 2
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 2
	RELEASE $0B, 1
	ATTEN 5
	OCTAVE 3
	NOTE A_, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 2
	NOTE E_, 2
	RELEASE $0B, 1
	ATTEN 5
	OCTAVE 3
	NOTE A_, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 2
	NOTE D#, 2
	ATTEN 5
	OCTAVE 3
	NOTE G_, 2
	ATTEN 0
	OCTAVE 2
	NOTE D_, 1
	RELEASE $0B, 1
	ATTEN 5
	OCTAVE 3
	NOTE G_, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 1
	NOTE G_, 2
	RELEASE $0B, 1
	ATTEN 5
	OCTAVE 3
	NOTE G_, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 1
	NOTE G#, 1
	VOICE $06, 8, 10, 0, 0
	ENVELOPE $06
	VIBRATO $01, 3, 3
	OCTAVE 3
	NOTE A_, 0
	NOTE B_, 0
	OCTAVE 4
	NOTE E_, 6
	NOTE F_, 6
	VIBRATO_OFF
	ENVELOPE $00
	NOTE E_, 4
	ENVELOPE $06
	VIBRATO $01, 4, 3
	RELEASE 3, 2
	NOTE D_, 0
	RELEASE 0, 0
	ENVELOPE $00
	VIBRATO $04, 0, 2
	NOTE F_, 6
	ENVELOPE $06
	VIBRATO $01, 4, 3
	NOTE E_, 6
	VIBRATO_OFF
	ENVELOPE $00
	NOTE D_, 4
	ENVELOPE $06
	RELEASE 4, 4
	VIBRATO $01, 4, 3
	NOTE C_, 10
	RELEASE 0, 0
	VIBRATO $04, 0, 1
	ENVELOPE $00
	NOTE E_, 2
	VIBRATO_OFF
	NOTE D_, 2
	NOTE C_, 2
	ENVELOPE $06
	VIBRATO $01, 4, 3
	NOTE D_, 6
	ENVELOPE $00
	OCTAVE 3
	NOTE A_, 6
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE D_, 4
	VIBRATO $01, 4, 3
	NOTE C_, 8
	OCTAVE 3
	NOTE B_, 8
	LOOP2_START
	DUTY 4
	RELEASE 0, 0
	VIBRATO_OFF
	ENVELOPE $00
	OCTAVE 3
	REST 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	VIBRATO $01, 2, 3
	NOTE B_, 6
	NOTE A_, 6
	VIBRATO_OFF
	NOTE B_, 4
	VIBRATO $01, 2, 3
	OCTAVE 4
	NOTE C_, 6
	RELEASE 9, 1
	LOOP_BREAK $FC
	OCTAVE 3
	NOTE B_, 2
	RELEASE 0, 0
	NOTE B_, 8
	ENVELOPE $12
	VIBRATO_OFF
	RELEASE $0E, 1
	DUTY 8
	OCTAVE 3
	REST 2
	LOOP_START
	NOTE B_, 2
	REST 1
	LOOP_END $04
	NOTE B_, 2
	ENVELOPE $00
	LOOP2_END $02
	NOTE D_, 2
	RELEASE 0, 0
	NOTE D_, 8
	REST 4
	VIBRATO $04, 0, 2
	NOTE D_, 4
	VIBRATO_OFF
	NOTE C_, 4
	NOTE D_, 4
	VIBRATO $01, 3, 3
	NOTE E_, 0
	ENVELOPE $08
	DUTY 8
	OCTAVE 3
	NOTE F_, 0
	NOTE G_, 0
	NOTE G#, 0
	ENVELOPE $00
	VIBRATO_OFF
	VOICE $06, 8, 12, 11, 1
	LOOP_START
	REST 2
	OCTAVE 3
	NOTE E_, 1
	LOOP_END $02
	REST 2
	RELEASE 0, 0
	LOOP_BREAK $FC
	NOTE E_, 2
	REST 1
	RELEASE $0B, 1
	NOTE E_, 1
	REST 2
	NOTE E_, 1
	REST 1
	RELEASE $0B, 1
	LOOP_START
	REST 2
	NOTE F_, 1
	LOOP_END $02
	REST 2
	RELEASE 0, 0
	LOOP_BREAK $FC
	NOTE F_, 2
	REST 1
	RELEASE $0B, 1
	NOTE F_, 1
	REST 2
	NOTE F_, 1
	REST 1
	RELEASE $0B, 1
	LOOP_START
	REST 2
	NOTE G_, 1
	LOOP_END $02
	REST 2
	RELEASE 0, 0
	LOOP_BREAK $FC
	NOTE G_, 2
	REST 1
	RELEASE $0B, 1
	NOTE G_, 1
	REST 2
	NOTE G_, 1
	REST 1
	RELEASE $0B, 1
	LOOP_START
	REST 2
	NOTE G#, 1
	LOOP_END $02
	REST 2
	RELEASE 0, 0
	LOOP_BREAK $FC
	NOTE G#, 2
	REST 1
	RELEASE $0B, 1
	NOTE G#, 1
	REST 2
	NOTE G#, 1
	REST 1
	VOICE $06, 8, 11, 9, 1
	LOOP_START
	AUTOPAN 0
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A_, 1
	LOOP_BREAK $FB
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE G#, 1
	LOOP_END $02
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A#, 1
	LOOP_START
	AUTOPAN 0
	OCTAVE 5
	NOTE E_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A_, 1
	LOOP_BREAK $FB
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE G#, 1
	LOOP_END $02
	NOTE A#, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A#, 1
	PAN_BOTH 0
	SND_LOOP
	db $FF ; unreachable end

SndEA_Ch1:
	VOICE $06, 8, 7, 9, 2
	DETUNE $FF
	REST 1
	LOOP_START
	AUTOPAN 0
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE E_, 2
	OCTAVE 4
	NOTE A_, 1
	NOTE G_, 2
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE A_, 2
	OCTAVE 5
	NOTE E_, 1
	OCTAVE 4
	NOTE A_, 2
	NOTE G_, 1
	OCTAVE 5
	NOTE D_, 2
	LOOP_BREAK $FB
	NOTE D_, 1
	LOOP_END $04
	DETUNE $00
	PAN_BOTH 0
	SND_SEGNO
	VOICE $06, 8, 13, 11, 1
	LOOP2_START
	RELEASE $0B, 1
	LOOP_START
	REST 2
	OCTAVE 3
	NOTE E_, 1
	LOOP_END $02
	REST 2
	RELEASE 0, 0
	LOOP_BREAK $FC
	NOTE E_, 2
	REST 1
	RELEASE $0B, 1
	NOTE E_, 1
	REST 2
	NOTE E_, 1
	REST 1
	LOOP2_END $04
	NOTE D#, 2
	REST 1
	RELEASE $0B, 1
	NOTE D#, 1
	REST 2
	NOTE D#, 1
	REST 1
	VOICE $06, 0, 12, 0, 0
	ATTEN 2
	OCTAVE 3
	NOTE E_, 8
	ATTEN 0
	ENVELOPE $06
	VIBRATO $01, 3, 3
	OCTAVE 4
	NOTE E_, 8
	NOTE D_, 8
	OCTAVE 3
	NOTE G#, 8
	ATTEN 2
	ENVELOPE $00
	NOTE A_, 5
	ATTEN 0
	RELEASE $0B, 1
	NOTE E_, 1
	ATTEN 2
	RELEASE 0, 0
	NOTE B_, 5
	ATTEN 0
	RELEASE $0B, 1
	NOTE E_, 1
	ATTEN 2
	RELEASE 0, 0
	OCTAVE 4
	NOTE C#, 4
	RELEASE $0B, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	DUTY 8
	NOTE F#, 1
	DUTY 0
	NOTE C_HI, 1
	NOTE C_HI, 1
	DUTY 8
	NOTE F#, 1
	DUTY 0
	OCTAVE 4
	NOTE A_, 1
	NOTE A_, 1
	DUTY 8
	OCTAVE 3
	NOTE F#, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE F#, 1
	DUTY 0
	NOTE C_HI, 1
	NOTE C_HI, 1
	DUTY 8
	NOTE F#, 1
	DUTY 0
	OCTAVE 4
	NOTE A_, 1
	ATTEN 0
	VOICE $06, 8, 15, 0, 0
	LOOP_START
	OCTAVE 1
	NOTE F_, 2
	RELEASE $0B, 1
	ATTEN 2
	OCTAVE 3
	NOTE F_, 1
	RELEASE 0, 0
	ATTEN 0
	LOOP_END $04
	OCTAVE 1
	NOTE G#, 2
	ATTEN 2
	OCTAVE 3
	NOTE F_, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 1
	NOTE G#, 1
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	RELEASE $0B, 1
	ATTEN 2
	OCTAVE 3
	NOTE G_, 1
	RELEASE 0, 0
	ATTEN 0
	LOOP_END $03
	OCTAVE 1
	NOTE G_, 1
	VOICE $06, 0, 13, 0, 0
	ATTEN 3
	OCTAVE 4
	NOTE G_, 2
	NOTE F#, 2
	ATTEN 2
	NOTE G_, 2
	ENVELOPE $06
	VIBRATO $01, 1, 3
	ATTEN 0
	NOTE A_, 8
	ENVELOPE $00
	VIBRATO_OFF
	RELEASE $0B, 1
	DUTY 8
	OCTAVE 3
	NOTE F#, 1
	DUTY 0
	RELEASE 0, 0
	ATTEN 4
	OCTAVE 4
	NOTE D_, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 0
	OCTAVE 3
	NOTE F#, 1
	DUTY 0
	RELEASE 0, 0
	ATTEN 4
	OCTAVE 4
	NOTE F#, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 0
	OCTAVE 3
	NOTE F#, 1
	DUTY 0
	RELEASE 9, 1
	ATTEN 4
	OCTAVE 4
	NOTE A_, 1
	DUTY 0
	RELEASE 0, 0
	OCTAVE 4
	NOTE D#, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 0
	OCTAVE 3
	NOTE F#, 1
	DUTY 0
	RELEASE 0, 0
	ATTEN 4
	OCTAVE 4
	NOTE F#, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 0
	OCTAVE 3
	NOTE F#, 1
	DUTY 0
	RELEASE 0, 0
	ATTEN 4
	OCTAVE 4
	NOTE G#, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 0
	OCTAVE 3
	NOTE G#, 1
	DUTY 0
	RELEASE 0, 0
	ATTEN 5
	OCTAVE 4
	NOTE A_, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 0
	OCTAVE 3
	NOTE G#, 1
	DUTY 0
	RELEASE 0, 0
	VIBRATO $01, 1, 2
	ATTEN 5
	OCTAVE 4
	NOTE B_, 4
	VIBRATO_OFF
	ATTEN 0
	VOICE $06, 8, 13, 11, 1
	AUTOPAN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE F_, 1
	SND_CALL SndEA_Ch1_7B30
	AUTOPAN 0
	OCTAVE 4
	NOTE F_, 1
	NOTE A_, 1
	SND_CALL SndEA_Ch1_7B30
	SND_CALL SndEA_Ch1_7B5D
	AUTOPAN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE F_, 1
	SND_CALL SndEA_Ch1_7B30
	AUTOPAN 0
	OCTAVE 3
	NOTE G_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	NOTE C_, 1
	AUTOPAN 0
	NOTE A_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	NOTE C_, 1
	AUTOPAN 0
	NOTE B_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	NOTE C_, 1
	AUTOPAN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE C_, 1
	AUTOPAN 0
	OCTAVE 4
	NOTE D_, 1
	NOTE C_HI, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE C_, 1
	PAN_RIGHT 0
	OCTAVE 4
	NOTE D_, 1
	SND_CALL SndEA_Ch1_7B5D
	VOICE $06, 8, 15, 0, 0
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	RELEASE $0B, 1
	ATTEN 2
	OCTAVE 3
	NOTE C#, 1
	RELEASE 0, 0
	ATTEN 0
	LOOP_END $02
	OCTAVE 1
	NOTE A_, 2
	ATTEN 2
	OCTAVE 3
	NOTE C#, 2
	ATTEN 0
	OCTAVE 1
	NOTE A_, 1
	RELEASE $0B, 1
	ATTEN 2
	OCTAVE 3
	NOTE C#, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 1
	NOTE A_, 2
	RELEASE $0B, 1
	ATTEN 2
	OCTAVE 3
	NOTE C#, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 1
	NOTE G_, 1
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	RELEASE $0B, 1
	ATTEN 2
	OCTAVE 3
	NOTE C#, 1
	RELEASE 0, 0
	ATTEN 0
	LOOP_END $02
	OCTAVE 1
	NOTE A_, 2
	ATTEN 2
	OCTAVE 3
	NOTE C#, 2
	ATTEN 0
	OCTAVE 1
	NOTE A_, 1
	RELEASE $0B, 1
	ATTEN 2
	OCTAVE 3
	NOTE C#, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 1
	NOTE A#, 2
	RELEASE $0B, 1
	ATTEN 2
	OCTAVE 3
	NOTE C#, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 2
	NOTE C_, 1
	SND_CALL SndEA_Ch1_7BBE
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	RELEASE $0B, 1
	ATTEN 2
	OCTAVE 3
	NOTE C_, 1
	RELEASE 0, 0
	ATTEN 0
	LOOP_END $02
	OCTAVE 1
	NOTE A_, 2
	ATTEN 2
	OCTAVE 3
	NOTE C_, 2
	ATTEN 0
	OCTAVE 1
	NOTE A_, 1
	RELEASE $0B, 1
	ATTEN 2
	OCTAVE 3
	NOTE C_, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 1
	NOTE A_, 2
	RELEASE $0B, 1
	ATTEN 2
	OCTAVE 3
	NOTE C_, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 1
	NOTE G_, 1
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	RELEASE $0B, 1
	ATTEN 2
	OCTAVE 3
	NOTE C_, 1
	RELEASE 0, 0
	ATTEN 0
	LOOP_END $02
	OCTAVE 1
	NOTE A_, 2
	ATTEN 2
	OCTAVE 3
	NOTE C_, 2
	ATTEN 0
	OCTAVE 1
	NOTE A_, 1
	RELEASE $0B, 1
	ATTEN 2
	OCTAVE 3
	NOTE C_, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 1
	NOTE A#, 2
	RELEASE $0B, 1
	ATTEN 2
	OCTAVE 3
	NOTE C_, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 2
	NOTE C_, 1
	SND_CALL SndEA_Ch1_7BBE
	DETUNE $FF
	REST 1
	AUTOPAN 0
	LOOP_START
	ATTEN 3
	RELEASE 9, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A_, 1
	LOOP_BREAK $FB
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE G#, 1
	LOOP_END $02
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A#, 1
	LOOP_START
	AUTOPAN 0
	OCTAVE 5
	NOTE E_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A_, 1
	LOOP_BREAK $FB
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE G#, 1
	LOOP_END $02
	NOTE A#, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	PAN_BOTH 0
	ATTEN 0
	DETUNE $00
	SND_LOOP

SndEA_Ch3:
	VOICE $06, 1, 2, 0, 0
	REST 0
	REST 0
	OCTAVE 2
	VIBRATO $01, 4, 5
	NOTE F_, 0
	VIBRATO $04, 0, 2
	NOTE A#, 2
	VIBRATO $01, 2, 4
	NOTE A#, 10
	VIBRATO $03, 0, 3
	NOTE A#, 4
	VIBRATO_OFF
	RELEASE $0B, 1
	SND_SEGNO
	VOICE $06, 1, 2, 11, 1
	WAVE_X $1C
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $1B
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE C_, 1
	WAVE_X $1A
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $19
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE C_, 1
	WAVE_X $18
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $17
	NOTE A_, 1
	WAVE 0
	RELEASE 0, 0
	OCTAVE 4
	NOTE C_, 2
	RELEASE $0B, 1
	WAVE_X $16
	OCTAVE 3
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE C_, 1
	WAVE_X $15
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $14
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE C_, 1
	WAVE_X $13
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $12
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $11
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE D_, 1
	WAVE_X $10
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $11
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE D_, 1
	WAVE_X $12
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $13
	NOTE A_, 1
	WAVE 0
	RELEASE 0, 0
	OCTAVE 4
	NOTE D_, 2
	RELEASE $0B, 1
	WAVE_X $14
	OCTAVE 3
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE D_, 1
	WAVE_X $15
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $16
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE D_, 1
	WAVE_X $17
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $18
	NOTE A_, 1
	WAVE_X $19
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE C#, 1
	WAVE_X $1A
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $1B
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE C#, 1
	WAVE_X $1C
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $1B
	NOTE A_, 1
	WAVE 0
	RELEASE 0, 0
	OCTAVE 4
	NOTE C#, 2
	RELEASE $0B, 1
	WAVE_X $1A
	OCTAVE 3
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE C#, 1
	WAVE_X $19
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $18
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE C#, 1
	WAVE_X $17
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $16
	NOTE A_, 1
	WAVE_X $15
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE D_, 1
	WAVE_X $14
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $13
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE D_, 1
	WAVE_X $12
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $11
	NOTE A_, 1
	WAVE 0
	RELEASE 0, 0
	OCTAVE 4
	NOTE C#, 2
	RELEASE $0B, 1
	WAVE_X $10
	OCTAVE 3
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE C#, 1
	WAVE_X $11
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $12
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE C#, 1
	WAVE_X $13
	OCTAVE 3
	NOTE A_, 1
	VOICE $06, 1, 2, 0, 0
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 2
	WAVE 0
	RELEASE 9, 1
	OCTAVE 4
	NOTE C_, 1
	WAVE 1
	LOOP_END $04
	RELEASE 0, 0
	OCTAVE 3
	NOTE C_, 2
	WAVE 0
	RELEASE 9, 1
	NOTE C_HI, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE G#, 2
	WAVE 0
	RELEASE 9, 1
	OCTAVE 3
	NOTE B_, 1
	WAVE 1
	LOOP_END $04
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 2
	WAVE 0
	RELEASE 9, 1
	OCTAVE 3
	NOTE B_, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 1
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE G_, 2
	WAVE 0
	RELEASE 9, 1
	OCTAVE 3
	NOTE A#, 1
	WAVE 1
	LOOP_END $04
	RELEASE 0, 0
	OCTAVE 3
	NOTE G_, 2
	WAVE 0
	RELEASE 9, 1
	NOTE A#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE G_, 1
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE F#, 2
	WAVE 0
	RELEASE 9, 1
	OCTAVE 3
	NOTE A_, 1
	WAVE 1
	LOOP_END $04
	RELEASE 0, 0
	OCTAVE 3
	NOTE D_, 2
	WAVE 0
	RELEASE 9, 1
	NOTE A_, 1
	WAVE 1
	RELEASE 0, 0
	NOTE F#, 1
	RELEASE $0B, 1
	WAVE_X $1C
	NOTE B_, 1
	WAVE_X $1B
	NOTE B_, 1
	WAVE 0
	NOTE G#, 1
	WAVE_X $1A
	NOTE B_, 1
	WAVE_X $19
	NOTE B_, 1
	WAVE 0
	NOTE G#, 1
	WAVE_X $18
	NOTE B_, 1
	WAVE_X $17
	NOTE B_, 1
	WAVE 0
	NOTE G#, 1
	WAVE_X $16
	NOTE B_, 1
	WAVE_X $15
	NOTE B_, 1
	WAVE 0
	NOTE G#, 1
	WAVE_X $14
	NOTE B_, 1
	WAVE_X $13
	NOTE B_, 1
	WAVE 0
	NOTE G#, 1
	WAVE_X $12
	NOTE B_, 1
	WAVE_X $11
	NOTE A_, 1
	WAVE_X $10
	NOTE A_, 1
	WAVE 0
	NOTE A_, 1
	WAVE_X $11
	NOTE A_, 1
	WAVE_X $12
	NOTE A_, 1
	WAVE 0
	NOTE A_, 1
	WAVE_X $13
	NOTE A_, 1
	WAVE_X $14
	NOTE A_, 1
	WAVE 0
	NOTE A_, 1
	WAVE_X $15
	NOTE A_, 1
	WAVE 0
	RELEASE 9, 1
	NOTE A_, 2
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE G_, 2
	WAVE 0
	RELEASE 9, 1
	OCTAVE 3
	NOTE A_, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE G_, 1
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE F#, 2
	WAVE 0
	RELEASE 9, 1
	OCTAVE 3
	NOTE A_, 1
	LOOP_END $03
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	NOTE F#, 2
	WAVE 0
	RELEASE 9, 1
	NOTE A_, 1
	LOOP_END $02
	WAVE 1
	RELEASE 0, 0
	NOTE F#, 1
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	NOTE D#, 2
	WAVE 0
	RELEASE 9, 1
	NOTE A#, 1
	LOOP_END $02
	WAVE 1
	RELEASE 0, 0
	NOTE D#, 2
	WAVE 0
	RELEASE 9, 1
	NOTE G#, 1
	WAVE 1
	RELEASE 0, 0
	NOTE E_, 2
	WAVE 0
	RELEASE 9, 1
	NOTE G#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 2
	WAVE 0
	RELEASE 9, 1
	OCTAVE 3
	NOTE G#, 1
	WAVE 1
	RELEASE 0, 0
	NOTE E_, 1
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE F_, 2
	WAVE 0
	RELEASE 9, 1
	NOTE C_HI, 1
	LOOP_END $04
	WAVE 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE C_, 2
	WAVE 0
	RELEASE 9, 1
	NOTE F_, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE F_, 2
	WAVE 0
	RELEASE 9, 1
	NOTE C_HI, 1
	LOOP_END $05
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE G_, 2
	WAVE 0
	RELEASE 9, 1
	NOTE C_HI, 1
	LOOP_END $05
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE G_, 2
	WAVE 0
	RELEASE 9, 1
	NOTE C_HI, 1
	LOOP_END $04
	WAVE 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE G_, 2
	WAVE 0
	RELEASE 9, 1
	NOTE G_, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE G_, 1
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE F_, 2
	WAVE 0
	RELEASE 9, 1
	NOTE C_HI, 1
	LOOP_END $04
	WAVE 1
	RELEASE 0, 0
	NOTE A_, 2
	WAVE 0
	RELEASE 9, 1
	OCTAVE 3
	NOTE F_, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE C_, 2
	WAVE 0
	RELEASE 9, 1
	NOTE F_, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 2
	WAVE 0
	RELEASE 9, 1
	OCTAVE 3
	NOTE F_, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE F_, 2
	WAVE 0
	RELEASE 9, 1
	NOTE C_HI, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE C_, 2
	WAVE 0
	RELEASE 9, 1
	NOTE F_, 1
	WAVE 1
	RELEASE 0, 0
	NOTE D_, 2
	WAVE 0
	RELEASE 9, 1
	NOTE F_, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE G_, 2
	WAVE 0
	RELEASE 9, 1
	NOTE C_HI, 1
	LOOP_END $05
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	NOTE G_, 2
	WAVE 0
	RELEASE 9, 1
	NOTE C_HI, 1
	LOOP_END $02
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 2
	WAVE 0
	RELEASE 9, 1
	OCTAVE 3
	NOTE G_, 1
	LOOP_END $02
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 2
	WAVE 0
	RELEASE 9, 1
	OCTAVE 3
	NOTE G_, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 1
	RELEASE $0B, 1
	WAVE_X $1C
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $1B
	NOTE A_, 1
	WAVE 0
	NOTE A_, 1
	WAVE_X $1A
	NOTE A_, 1
	WAVE_X $19
	NOTE A_, 1
	WAVE 0
	NOTE A_, 1
	WAVE_X $18
	NOTE A_, 1
	WAVE_X $17
	NOTE A_, 1
	WAVE 0
	RELEASE 0, 0
	NOTE A_, 2
	RELEASE $0B, 1
	WAVE_X $16
	NOTE A_, 1
	WAVE 0
	NOTE A_, 1
	WAVE_X $15
	NOTE A_, 1
	WAVE_X $14
	NOTE A_, 1
	WAVE 0
	NOTE A_, 1
	WAVE_X $13
	NOTE A_, 1
	WAVE_X $12
	NOTE A_, 1
	WAVE_X $11
	NOTE A_, 1
	WAVE 0
	NOTE A#, 1
	WAVE_X $10
	NOTE A_, 1
	WAVE_X $11
	NOTE A_, 1
	WAVE 0
	NOTE A#, 1
	WAVE_X $12
	NOTE A_, 1
	WAVE_X $13
	NOTE A_, 1
	WAVE 0
	RELEASE 0, 0
	NOTE A#, 2
	RELEASE $0B, 1
	WAVE_X $14
	NOTE A_, 1
	WAVE 0
	NOTE A#, 1
	WAVE_X $15
	NOTE A_, 1
	WAVE_X $16
	NOTE A_, 1
	WAVE 0
	NOTE A#, 1
	WAVE_X $17
	NOTE A_, 1
	WAVE_X $18
	NOTE A_, 1
	WAVE_X $19
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE C_, 1
	WAVE_X $1A
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $1B
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE C_, 1
	WAVE_X $1C
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $1B
	NOTE A_, 1
	WAVE 0
	RELEASE 0, 0
	OCTAVE 4
	NOTE C_, 2
	RELEASE $0B, 1
	WAVE_X $1A
	OCTAVE 3
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE C_, 1
	WAVE_X $19
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $18
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE C_, 1
	WAVE_X $17
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $16
	NOTE A_, 1
	WAVE_X $15
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE D_, 1
	WAVE_X $14
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $13
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE D_, 1
	WAVE_X $12
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $11
	NOTE A_, 1
	WAVE 0
	RELEASE 0, 0
	OCTAVE 4
	NOTE D_, 2
	RELEASE $0B, 1
	WAVE_X $10
	OCTAVE 3
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE D_, 1
	WAVE_X $11
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $12
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE D_, 1
	WAVE_X $13
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $14
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $15
	NOTE A_, 1
	WAVE 0
	NOTE A_, 1
	WAVE_X $16
	NOTE A_, 1
	WAVE_X $17
	NOTE A_, 1
	WAVE 0
	NOTE A_, 1
	WAVE_X $18
	NOTE A_, 1
	WAVE_X $19
	NOTE A_, 1
	WAVE 0
	RELEASE 0, 0
	NOTE A_, 2
	RELEASE $0B, 1
	WAVE_X $1A
	NOTE A_, 1
	WAVE 0
	NOTE A_, 1
	WAVE_X $1B
	NOTE A_, 1
	WAVE_X $1C
	NOTE A_, 1
	WAVE 0
	NOTE A_, 1
	WAVE_X $1B
	NOTE A_, 1
	WAVE_X $1A
	NOTE A_, 1
	WAVE_X $19
	NOTE A_, 1
	WAVE 0
	NOTE A#, 1
	WAVE_X $18
	NOTE A_, 1
	WAVE_X $17
	NOTE A_, 1
	WAVE 0
	NOTE A#, 1
	WAVE_X $16
	NOTE A_, 1
	WAVE_X $15
	NOTE A_, 1
	WAVE 0
	RELEASE 0, 0
	NOTE A#, 2
	RELEASE $0B, 1
	WAVE_X $14
	NOTE A_, 1
	WAVE 0
	NOTE A#, 1
	WAVE_X $13
	NOTE A_, 1
	WAVE_X $12
	NOTE A_, 1
	WAVE 0
	NOTE A#, 1
	WAVE_X $11
	NOTE A_, 1
	WAVE_X $10
	NOTE A_, 1
	WAVE_X $11
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE C_, 1
	WAVE_X $12
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $13
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE C_, 1
	WAVE_X $14
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $15
	NOTE A_, 1
	WAVE 0
	RELEASE 0, 0
	OCTAVE 4
	NOTE C_, 2
	RELEASE $0B, 1
	WAVE_X $16
	OCTAVE 3
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE C_, 1
	WAVE_X $17
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $18
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE C_, 1
	WAVE_X $19
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $1A
	NOTE A_, 1
	WAVE_X $1B
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE D_, 1
	WAVE_X $1C
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $1B
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE D_, 1
	WAVE_X $1A
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $19
	NOTE A_, 1
	WAVE 0
	RELEASE 0, 0
	OCTAVE 4
	NOTE D_, 2
	RELEASE $0B, 1
	WAVE_X $18
	OCTAVE 3
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE D_, 1
	WAVE_X $17
	OCTAVE 3
	NOTE A_, 1
	WAVE_X $16
	NOTE A_, 1
	WAVE 0
	OCTAVE 4
	NOTE D_, 1
	WAVE_X $15
	OCTAVE 3
	NOTE A_, 1
	RELEASE 0, 0
	VIBRATO $01, 2, 5
	WAVE 1
	OCTAVE 1
	NOTE A_, 0
	VIBRATO $04, 0, 3
	OCTAVE 2
	NOTE E_, 2
	VIBRATO $01, 2, 5
	NOTE E_, 14
	NOTE F_, 0
	VIBRATO $04, 0, 3
	NOTE A#, 2
	VIBRATO $01, 2, 3
	NOTE A#, 6
	NOTE F#, 8
	NOTE A_, 0
	VIBRATO $04, 0, 3
	OCTAVE 3
	NOTE E_, 2
	VIBRATO $01, 2, 4
	NOTE E_, 14
	NOTE F_, 0
	VIBRATO $04, 0, 3
	NOTE A#, 4
	VIBRATO $03, 6, 5
	NOTE A#, 12
	VIBRATO_OFF
	SND_LOOP

SndEA_Drm:
	LEN_UNIT $06
	DRUM $0A, 4
	REST $0A
	DRUM 9, 2
	DRUM 9, $0C
	DRUM 9, 4
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM $0A, 2
	LOOP_END $02
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 2
	LOOP_END $02
	LOOP_START
	DRUM $0B, 1
	LOOP_END $08
	SND_SEGNO
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $02
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $07
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $06
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $02
	LOOP_START
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	LOOP_END $02
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 9, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $02
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	LOOP_START
	DRUM 3, 1
	LOOP_END $08
	SND_LOOP
SndEA_Ch1_7B30:
	PAN_BOTH 0
	OCTAVE 3
	NOTE C_, 1
	AUTOPAN 0
	OCTAVE 4
	NOTE A_, 1
	NOTE F_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE C_, 1
	AUTOPAN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE A_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE C_, 1
	AUTOPAN 0
	OCTAVE 4
	NOTE F_, 1
	NOTE A_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE C_, 1
	AUTOPAN 0
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE C_, 1
	PAN_RIGHT 0
	OCTAVE 4
	NOTE A_, 1
	SND_RET
SndEA_Ch1_7B5D:
	AUTOPAN 0
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 1
	AUTOPAN 0
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 1
	AUTOPAN 0
	OCTAVE 4
	NOTE G_, 1
	NOTE B_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 1
	AUTOPAN 0
	OCTAVE 4
	NOTE B_, 1
	NOTE G_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 1
	AUTOPAN 0
	OCTAVE 4
	NOTE G_, 1
	NOTE D_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 1
	PAN_RIGHT 0
	OCTAVE 3
	NOTE B_, 1
	AUTOPAN 0
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	PAN_BOTH 0
	NOTE D_, 1
	AUTOPAN 0
	NOTE A_, 1
	NOTE B_, 1
	PAN_BOTH 0
	NOTE D_, 1
	AUTOPAN 0
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 1
	AUTOPAN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 1
	AUTOPAN 0
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 1
	PAN_RIGHT 0
	OCTAVE 4
	NOTE F_, 1
	SND_RET
SndEA_Ch1_7BBE:
	LOOP_START
	OCTAVE 1
	NOTE A_, 2
	RELEASE $0B, 1
	ATTEN 2
	OCTAVE 3
	NOTE E_, 1
	RELEASE 0, 0
	ATTEN 0
	LOOP_END $02
	OCTAVE 1
	NOTE A_, 2
	ATTEN 2
	OCTAVE 3
	NOTE E_, 2
	ATTEN 0
	OCTAVE 1
	NOTE A_, 1
	RELEASE $0B, 1
	ATTEN 2
	OCTAVE 3
	NOTE E_, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 1
	NOTE A#, 2
	RELEASE $0B, 1
	ATTEN 2
	OCTAVE 3
	NOTE E_, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 2
	NOTE C#, 1
	OCTAVE 1
	NOTE A_, 2
	RELEASE $0B, 1
	ATTEN 2
	OCTAVE 3
	NOTE E_, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 2
	NOTE E_, 2
	RELEASE $0B, 1
	ATTEN 2
	OCTAVE 3
	NOTE E_, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 2
	NOTE D#, 2
	ATTEN 2
	OCTAVE 3
	NOTE E_, 2
	ATTEN 0
	OCTAVE 2
	NOTE D_, 1
	RELEASE $0B, 1
	ATTEN 2
	OCTAVE 3
	NOTE E_, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 1
	NOTE G_, 2
	RELEASE $0B, 1
	ATTEN 2
	OCTAVE 3
	NOTE E_, 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 1
	NOTE G#, 1
	SND_RET

SECTION "Sound bank $0F", ROMX[$4000], BANK[$0F]

SndEB_Ch2:
	VOICE $06, 8, 9, 0, 0
	VIBRATO $01, 3, 3
	ATTEN 3
	OCTAVE 4
	NOTE G_, 0
	NOTE F_, 0
	ATTEN 0
	OCTAVE 3
	NOTE D_, 6
	OCTAVE 2
	NOTE G_, 1
	REST 1
	NOTE G_, 8
	ATTEN 3
	OCTAVE 4
	NOTE D#, 8
	NOTE F_, 8
	NOTE G_, 0
	NOTE F_, 0
	NOTE D#, 0
	NOTE D_, 0
	REST 0
	ATTEN 0
	SND_SEGNO
	VOICE $06, 8, 11, 9, 1
	REST 2
	OCTAVE 3
	NOTE G_, 3
	NOTE G_, 3
	RELEASE 0, 0
	NOTE G_, 2
	REST 1
	RELEASE 9, 1
	NOTE G_, 3
	NOTE G_, 2
	SND_CALL SndEB_Ch2_4351
	SND_CALL SndEB_Ch2_4371
	VOICE $06, 8, 9, 0, 0
	LOOP_START
	DUTY 8
	OCTAVE 4
	NOTE G#, 4
	VIBRATO_OFF
	NOTE F#, 2
	VIBRATO $01, 3, 3
	NOTE E_, 4
	RELEASE 0, 0
	VIBRATO $04, 0, 1
	NOTE F#, 4
	VIBRATO_OFF
	NOTE G#, 4
	VIBRATO $01, 3, 3
	NOTE C#, 14
	VIBRATO $04, 0, 2
	OCTAVE 5
	NOTE C#, 4
	OCTAVE 4
	VIBRATO $01, 3, 2
	NOTE B_, 4
	VIBRATO_OFF
	NOTE A_, 4
	NOTE G#, 4
	NOTE A_, 4
	VIBRATO $01, 2, 2
	NOTE G#, 4
	NOTE F#, 4
	NOTE E_, 4
	VIBRATO $04, 0, 2
	NOTE G#, 6
	VIBRATO $01, 3, 3
	NOTE C#, 10
	VIBRATO $04, 0, 2
	NOTE E_, 6
	VIBRATO $01, 3, 3
	NOTE D#, 6
	VIBRATO_OFF
	OCTAVE 3
	NOTE A#, 4
	VIBRATO $01, 4, 4
	OCTAVE 4
	NOTE C#, 0
	NOTE C_, 8
	VIBRATO_OFF
	LOOP_BREAK $FB
	NOTE C#, 4
	NOTE D#, 4
	LOOP_END $02
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	NOTE C_, 4
	VIBRATO $01, 4, 4
	NOTE C#, 0
	VOICE $06, 8, 11, 9, 1
	OCTAVE 3
	TRANSPOSE_UP 1
	SND_CALL SndEB_Ch2_4351
	TRANSPOSE_UP 0
	SND_CALL SndEB_Ch2_4371
	VOICE $06, 4, 15, 0, 0
	OCTAVE 2
	NOTE C_, 0
	VIBRATO $01, 0, 3
	NOTE C_, 0
	OCTAVE 1
	NOTE A#, 0
	VIBRATO $01, 0, 3
	NOTE A#, 0
	NOTE G#, 0
	VIBRATO $01, 0, 3
	NOTE G#, 0
	NOTE F_, 0
	NOTE G_, 0
	REST 0
	VIBRATO_OFF
	SND_LOOP

SndEB_Ch1:
	VOICE $06, 4, 15, 0, 0
	OCTAVE 2
	NOTE C_, 0
	VIBRATO $01, 0, 3
	NOTE C_, 0
	OCTAVE 1
	NOTE A#, 0
	VIBRATO $01, 0, 3
	NOTE A#, 0
	NOTE G#, 0
	VIBRATO $01, 0, 3
	NOTE G#, 0
	NOTE F_, 0
	NOTE G_, 0
	REST 0
	VIBRATO_OFF
	SND_SEGNO
	VOICE $06, 0, 13, 9, 1
	DUTY_STEP 8, 1
	LOOP2_START
	SND_CALL SndEB_Ch1_439B
	LOOP2_END $02
	VOICE $06, 0, 13, 0, 0
	OCTAVE 3
	VIBRATO $01, 2, 3
	NOTE E_, 10
	VIBRATO_OFF
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	VIBRATO $01, 2, 3
	NOTE G#, 7
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 12
	VIBRATO $04, 0, 2
	NOTE C#, 4
	OCTAVE 3
	VIBRATO $01, 2, 3
	NOTE B_, 4
	NOTE A_, 4
	NOTE G#, 4
	OCTAVE 2
	NOTE F#, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C#, 2
	VIBRATO $04, 0, 2
	NOTE A#, 2
	VIBRATO $01, 2, 3
	NOTE A#, 8
	VIBRATO_OFF
	OCTAVE 2
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE D#, 1
	LOOP_START
	NOTE G#, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE C_, 1
	LOOP_BREAK $FB
	NOTE D#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE D#, 1
	LOOP_END $02
	VIBRATO $01, 1, 3
	NOTE E_, 4
	NOTE F#, 4
	VIBRATO_OFF
	LOOP_START
	NOTE G#, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE G#, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE G#, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE E_, 1
	LOOP_END $02
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE C#, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE G_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE G_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE C#, 1
	NOTE G_, 1
	NOTE C#, 1
	LOOP_START
	NOTE G#, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE C_, 1
	LOOP_BREAK $FB
	NOTE D#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE D#, 1
	LOOP_END $02
	VIBRATO $01, 1, 3
	NOTE E_, 4
	NOTE F#, 4
	VIBRATO_OFF
	VOICE $06, 0, 13, 9, 1
	TRANSPOSE_UP 1
	LOOP2_START
	SND_CALL SndEB_Ch1_439B
	TRANSPOSE_UP 0
	LOOP2_END $02
	LOOP2_START
	LOOP_START
	AUTOPAN 0
	NOTE G_, 1
	NOTE G_, 1
	REST 1
	LOOP_END $05
	NOTE G_, 1
	LOOP2_END $09
	PAN_BOTH 0
	SND_LOOP

SndEB_Ch3:
	SND_SEGNO
	VOICE $06, 0, 2, 0, 0
	LOOP_START
	VIBRATO $04, 0, 3
	OCTAVE 5
	NOTE C_, 4
	VIBRATO_OFF
	OCTAVE 4
	NOTE A#, 2
	NOTE G#, 4
	NOTE G_, 4
	NOTE G#, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE D#, 6
	VIBRATO $04, 0, 3
	NOTE G_, 6
	LOOP_BREAK $FB
	NOTE C_, 1
	REST 1
	VIBRATO $01, 2, 4
	NOTE C_, 8
	PAN_LEFT 0
	WAVE 3
	RELEASE 9, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	PAN_RIGHT 0
	OCTAVE 3
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	NOTE G_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 0
	LOOP_END $02
	NOTE F_, 1
	REST 1
	VIBRATO $01, 2, 4
	NOTE F_, 8
	PAN_LEFT 0
	WAVE 3
	RELEASE 9, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE B_, 1
	PAN_RIGHT 0
	NOTE F_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE G_, 1
	PAN_BOTH 0
	REST 0
	VOICE $06, 1, 2, 6, 2
	LOOP2_START
	SND_CALL SndEB_Ch3_4468
	LOOP2_END $02
	LOOP_START
	OCTAVE 3
	NOTE C#, 3
	OCTAVE 2
	NOTE B_, 3
	OCTAVE 3
	NOTE C#, 3
	NOTE C#, 3
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE B_, 3
	NOTE B_, 3
	NOTE B_, 3
	OCTAVE 3
	NOTE C#, 3
	NOTE D#, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE G#, 3
	NOTE G#, 3
	NOTE G#, 3
	NOTE G#, 3
	NOTE A_, 2
	NOTE G#, 2
	NOTE F#, 3
	NOTE F#, 3
	NOTE F#, 3
	NOTE F#, 3
	NOTE A_, 2
	NOTE F#, 2
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE A_, 2
	NOTE G_, 2
	NOTE G#, 3
	NOTE G#, 3
	NOTE G#, 3
	NOTE G#, 3
	NOTE A_, 2
	NOTE F#, 2
	NOTE G#, 3
	NOTE G#, 3
	NOTE G#, 3
	NOTE G#, 3
	NOTE A_, 2
	NOTE B_, 2
	LOOP_END $02
	TRANSPOSE_UP 1
	LOOP2_START
	SND_CALL SndEB_Ch3_4468
	TRANSPOSE_UP 0
	LOOP2_END $02
	SND_LOOP

SndEB_Drm:
	LEN_UNIT $06
	DRUM $0C, 6
	DRUM 9, 6
	DRUM 9, 4
	DRUM 9, 6
	DRUM 9, 6
	DRUM 9, 4
	DRUM 9, 6
	DRUM 9, $0A
	DRUM 9, 6
	DRUM 9, 4
	DRUM 9, 2
	DRUM 9, 4
	DRUM $0C, 6
	DRUM 9, 6
	DRUM 9, 4
	DRUM 9, 6
	DRUM 9, 6
	DRUM 9, 4
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM $0A, 2
	LOOP_END $02
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 2
	LOOP_END $04
	SND_SEGNO
	DRUM 9, 8
	DRUM 7, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM $0C, 2
	DRUM $0A, 2
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 2
	LOOP_END $0D
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM $0C, 2
	DRUM $0A, 2
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 2
	LOOP_END $0B
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	LOOP2_START
	DRUM $0C, 2
	DRUM $0A, 2
	LOOP_START
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 2
	LOOP_END $07
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 1
	DRUM 5, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 2
	LOOP_END $06
	DRUM 9, 1
	DRUM 3, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 2
	LOOP_BREAK $FC
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP2_END $02
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM $0C, 2
	DRUM $0A, 2
	LOOP_START
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 2
	LOOP_END $07
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 1
	DRUM 5, 1
	DRUM $0C, 2
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 2
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 2
	LOOP_END $05
	LOOP_START
	DRUM 3, 1
	LOOP_END $10
	LOOP2_START
	DRUM $0C, 2
	DRUM $0A, 2
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 2
	LOOP_END $0F
	LOOP2_END $02
	SND_LOOP
SndEB_Ch2_4351:
	REST 2
	NOTE A#, 3
	NOTE A#, 3
	RELEASE 0, 0
	OCTAVE 4
	NOTE C_, 2
	REST 1
	RELEASE 9, 1
	NOTE C_, 3
	NOTE C_, 2
	REST 2
	OCTAVE 3
	NOTE G_, 3
	NOTE G_, 3
	RELEASE 0, 0
	NOTE G_, 2
	REST 1
	RELEASE 9, 1
	NOTE G_, 3
	NOTE G_, 2
	REST 2
	NOTE D#, 3
	NOTE D#, 3
	NOTE F_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	SND_RET
SndEB_Ch2_4371:
	RELEASE 0, 0
	VIBRATO $04, 0, 3
	DUTY 4
	NOTE G_, 6
	VIBRATO $01, 2, 4
	NOTE C_, 10
	VIBRATO_OFF
	RELEASE 9, 1
	DUTY 8
	REST 2
	NOTE A#, 3
	NOTE A#, 3
	OCTAVE 4
	RELEASE 0, 0
	NOTE C_, 2
	REST 1
	RELEASE 9, 1
	NOTE C_, 3
	NOTE C_, 2
	VIBRATO $01, 4, 3
	RELEASE 0, 0
	ATTEN 3
	OCTAVE 5
	NOTE C_, 0
	OCTAVE 4
	NOTE A#, 0
	ATTEN 0
	SND_RET
SndEB_Ch1_439B:
	LOOP_START
	AUTOPAN 0
	OCTAVE 4
	NOTE G_, 1
	NOTE G_, 1
	PAN_BOTH 0
	DUTY 8
	OCTAVE 3
	LOOP_BREAK $FB
	NOTE D#, 1
	DUTY 0
	LOOP_END $03
	RELEASE 0, 0
	NOTE D#, 2
	RELEASE 9, 1
	DUTY 0
	PAN_LEFT 0
	OCTAVE 4
	NOTE G_, 1
	PAN_BOTH 0
	DUTY 8
	OCTAVE 3
	NOTE D#, 1
	DUTY 0
	AUTOPAN 0
	OCTAVE 4
	NOTE G_, 1
	NOTE G_, 1
	DUTY 8
	PAN_BOTH 0
	OCTAVE 3
	NOTE D#, 1
	DUTY 0
	PAN_RIGHT 0
	OCTAVE 4
	NOTE G_, 1
	LOOP_START
	AUTOPAN 0
	OCTAVE 4
	NOTE G_, 1
	NOTE G_, 1
	PAN_BOTH 0
	DUTY 8
	OCTAVE 3
	LOOP_BREAK $FB
	NOTE G_, 1
	DUTY 0
	LOOP_END $03
	RELEASE 0, 0
	NOTE A_, 2
	RELEASE 9, 1
	DUTY 0
	PAN_LEFT 0
	OCTAVE 4
	NOTE G_, 1
	DUTY 8
	PAN_BOTH 0
	OCTAVE 3
	NOTE A_, 1
	DUTY 0
	AUTOPAN 0
	OCTAVE 4
	NOTE G_, 1
	NOTE G_, 1
	DUTY 8
	PAN_BOTH 0
	OCTAVE 3
	NOTE A_, 1
	DUTY 0
	PAN_RIGHT 0
	OCTAVE 4
	NOTE G_, 1
	LOOP_START
	AUTOPAN 0
	OCTAVE 4
	NOTE G_, 1
	NOTE G_, 1
	PAN_BOTH 0
	DUTY 8
	OCTAVE 3
	LOOP_BREAK $FB
	NOTE D#, 1
	DUTY 0
	LOOP_END $03
	RELEASE 0, 0
	NOTE D#, 2
	RELEASE 9, 1
	DUTY 0
	PAN_LEFT 0
	OCTAVE 4
	NOTE G_, 1
	DUTY 8
	PAN_BOTH 0
	OCTAVE 3
	NOTE D#, 1
	DUTY 0
	AUTOPAN 0
	OCTAVE 4
	NOTE G_, 1
	NOTE G_, 1
	DUTY 8
	PAN_BOTH 0
	OCTAVE 3
	NOTE D#, 1
	DUTY 0
	PAN_RIGHT 0
	OCTAVE 4
	NOTE G_, 1
	LOOP_START
	AUTOPAN 0
	OCTAVE 4
	NOTE G_, 1
	NOTE G_, 1
	PAN_BOTH 0
	DUTY 8
	OCTAVE 3
	LOOP_BREAK $FB
	NOTE C_, 1
	DUTY 0
	LOOP_END $03
	LOOP_START
	NOTE D_, 1
	DUTY 0
	PAN_LEFT 0
	OCTAVE 4
	NOTE G_, 1
	DUTY 8
	PAN_BOTH 0
	OCTAVE 3
	LOOP_END $03
	NOTE D#, 1
	DUTY 0
	PAN_RIGHT 0
	OCTAVE 4
	NOTE G_, 1
	PAN_BOTH 0
	SND_RET
SndEB_Ch3_4468:
	OCTAVE 3
	NOTE C_, 3
	OCTAVE 2
	NOTE A#, 3
	OCTAVE 3
	NOTE C_, 3
	OCTAVE 2
	NOTE A#, 3
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 3
	NOTE D#, 3
	NOTE D#, 3
	NOTE F_, 3
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE C_, 3
	OCTAVE 2
	NOTE A#, 3
	OCTAVE 3
	NOTE C_, 3
	OCTAVE 2
	NOTE A#, 3
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE G#, 3
	NOTE G#, 3
	NOTE G#, 2
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 2
	SND_RET

SndEC_Ch2:
	VOICE $08, 8, 8, 0, 0
	VIBRATO $01, 2, 3
	ENVELOPE $08
	OCTAVE 4
	NOTE F_, 8
	NOTE E_, 8
	NOTE C#, 8
	OCTAVE 3
	NOTE A#, 8
	NOTE F_, 8
	NOTE E_, 8
	NOTE C#, 8
	VIBRATO $01, 5, 4
	OCTAVE 2
	NOTE A#, 0
	OCTAVE 3
	NOTE C_, 0
	VIBRATO_OFF
	ENVELOPE $00
	VOICE $04, 4, 8, 0, 0
	LOOP_START
	SND_CALL SndEC_Ch1_4A1E
	LOOP_END $02
	ATTEN 1
	NOTE F_, 3
	ATTEN 2
	NOTE F_, 3
	ATTEN 3
	NOTE F_, 3
	ATTEN 4
	NOTE F_, 3
	ATTEN 3
	NOTE F_, 3
	ATTEN 2
	NOTE F_, 3
	ATTEN 1
	NOTE F_, 3
	ATTEN 0
	NOTE F_, 3
	VIBRATO $03, 0, 2
	ENVELOPE $0F
	NOTE F_, 8
	VIBRATO_OFF
	ENVELOPE $00
	SND_SEGNO
	VOICE $04, 0, 8, 0, 0
	LOOP_START
	OCTAVE 3
	NOTE A_, 2
	RELEASE $0B, 1
	DUTY 8
	NOTE C_, 2
	DUTY 0
	SND_CALL SndEC_Ch2_4A45
	NOTE A_, 2
	NOTE A#, 2
	RELEASE $0B, 1
	SND_CALL SndEC_Ch2_4A45
	LOOP_END $02
	VOICE $04, 4, 7, 0, 0
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE A_, 3
	VIBRATO $01, 1, 1
	OCTAVE 4
	NOTE A_, 9
	RELEASE 0, 0
	VIBRATO $04, 0, 1
	NOTE A#, 4
	VIBRATO_OFF
	NOTE A_, 6
	VIBRATO $01, 3, 2
	NOTE G_, 10
	VIBRATO $04, 0, 2
	NOTE A_, 6
	VIBRATO_OFF
	NOTE A#, 4
	VIBRATO_OFF
	NOTE A_, 4
	NOTE G_, 2
	VIBRATO $01, 3, 3
	NOTE D_, 13
	VIBRATO $03, 0, 2
	RELEASE 4, 0
	NOTE D_, 3
	VIBRATO_OFF
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	NOTE F_, 6
	VIBRATO_OFF
	NOTE E_, 6
	VIBRATO $03, 5, 2
	NOTE F_, 4
	VIBRATO $01, 2, 2
	RELEASE 4, 0
	OCTAVE 3
	NOTE B_, 8
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE G_, 4
	VIBRATO_OFF
	RELEASE 4, 2
	NOTE F_, 4
	VIBRATO $01, 3, 3
	RELEASE 0, 0
	NOTE F_, 14
	VIBRATO_OFF
	NOTE E_, 1
	NOTE D_, 1
	RELEASE 5, 2
	NOTE C#, 4
	VIBRATO $04, 0, 2
	RELEASE 0, 0
	NOTE E_, 4
	VIBRATO_OFF
	NOTE F_, 4
	VIBRATO $03, 3, 2
	NOTE G_, 4
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE A_, 3
	VIBRATO $01, 1, 1
	OCTAVE 4
	NOTE A_, 9
	RELEASE 0, 0
	VIBRATO $04, 0, 1
	NOTE A#, 4
	VIBRATO_OFF
	NOTE A_, 6
	VIBRATO $01, 3, 2
	NOTE G_, 10
	VIBRATO $04, 0, 2
	NOTE A_, 6
	VIBRATO_OFF
	NOTE A#, 4
	VIBRATO_OFF
	OCTAVE 5
	NOTE C_, 4
	NOTE D_, 2
	VIBRATO $01, 3, 3
	OCTAVE 4
	NOTE D_, 13
	VIBRATO $03, 0, 2
	RELEASE 4, 0
	NOTE D_, 3
	VIBRATO_OFF
	RELEASE 0, 0
	NOTE F_, 6
	NOTE E_, 6
	NOTE F_, 4
	VIBRATO $01, 3, 2
	NOTE G_, 8
	VIBRATO $04, 0, 2
	NOTE B_, 3
	VIBRATO $01, 3, 1
	NOTE B_, 5
	VIBRATO $09, 0, 2
	OCTAVE 5
	NOTE D_, 4
	VIBRATO $01, 2, 2
	NOTE D_, 12
	VIBRATO $01, 2, 2
	NOTE C#, 12
	VIBRATO $03, 0, 2
	RELEASE 3, 0
	NOTE C#, 4
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	NOTE D_, 0
	VIBRATO $01, 0, 2
	NOTE D_, 0
	VIBRATO $01, 0, 3
	NOTE D_, 8
	VIBRATO $03, 0, 2
	RELEASE 2, 0
	NOTE D_, 8
	RELEASE 0, 0
	OCTAVE 4
	VIBRATO $04, 0, 2
	NOTE A_, 6
	VIBRATO_OFF
	NOTE G_, 6
	NOTE F_, 4
	VIBRATO $01, 4, 2
	NOTE D_, 13
	VIBRATO $03, 0, 2
	RELEASE 3, 0
	NOTE D_, 3
	VIBRATO_OFF
	RELEASE 0, 0
	OCTAVE 3
	NOTE B_, 8
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE E_, 8
	VIBRATO $01, 6, 2
	NOTE D_, 0
	VIBRATO $01, 5, 2
	NOTE C#, 0
	VIBRATO $04, 0, 2
	RELEASE 3, 0
	NOTE D_, 8
	VIBRATO_OFF
	NOTE E_, 2
	RELEASE $0B, 1
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	VIBRATO $04, 0, 2
	RELEASE 0, 0
	NOTE A_, 6
	VIBRATO_OFF
	NOTE G_, 6
	NOTE F_, 4
	RELEASE 4, 0
	NOTE C_, 6
	VIBRATO $04, 0, 2
	RELEASE 0, 0
	NOTE A#, 6
	VIBRATO_OFF
	NOTE A_, 4
	VIBRATO $01, 3, 2
	NOTE D_, 8
	NOTE E_, 8
	VIBRATO_OFF
	NOTE F_, 8
	VIBRATO $01, 0, 1
	NOTE F_, 8
	VIBRATO $01, 0, 2
	NOTE F_, 8
	RELEASE 3, 0
	VIBRATO $01, 0, 3
	NOTE F_, 8
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	NOTE B_, 0
	VIBRATO $04, 0, 1
	OCTAVE 5
	NOTE C#, 10
	VIBRATO $03, 0, 3
	NOTE C#, 6
	VIBRATO_OFF
	SND_LOOP

SndEC_Ch1:
	VOICE $08, 8, 8, 0, 0
	VIBRATO $01, 2, 3
	ENVELOPE $08
	OCTAVE 4
	NOTE C#, 8
	NOTE C_, 8
	OCTAVE 3
	NOTE A_, 8
	NOTE F#, 8
	NOTE C#, 8
	NOTE C_, 8
	OCTAVE 2
	NOTE A_, 8
	VIBRATO $01, 5, 4
	NOTE F#, 0
	NOTE G#, 0
	VIBRATO_OFF
	ENVELOPE $00
	VOICE $04, 4, 8, 0, 0
	TRANSPOSE_DOWN 5
	SND_CALL SndEC_Ch1_4A1E
	TRANSPOSE_DOWN 0
	RELEASE 4, 0
	OCTAVE 3
	NOTE D_, 6
	RELEASE $0B, 1
	NOTE D_, 2
	REST 4
	RELEASE 0, 0
	NOTE D_, 4
	VIBRATO $01, 0, 3
	NOTE D_, 0
	VIBRATO_OFF
	RELEASE 4, 0
	OCTAVE 3
	NOTE C_, 6
	RELEASE $0B, 1
	NOTE C_, 2
	REST 4
	RELEASE 0, 0
	VIBRATO $01, 3, 3
	NOTE C_, 12
	NOTE C_, 8
	ATTEN 1
	NOTE C_, 3
	ATTEN 2
	NOTE C_, 3
	ATTEN 3
	NOTE C_, 3
	ATTEN 4
	NOTE C_, 3
	ATTEN 3
	NOTE C_, 3
	ATTEN 2
	NOTE C_, 3
	ATTEN 1
	NOTE C_, 3
	ATTEN 0
	NOTE C_, 3
	VIBRATO $03, 0, 2
	ENVELOPE $0F
	NOTE C_, 8
	VIBRATO_OFF
	ENVELOPE $00
	SND_SEGNO
	VOICE $04, 0, 8, 0, 0
	LOOP_START
	DUTY 0
	OCTAVE 3
	NOTE E_, 2
	RELEASE $0B, 1
	DUTY 8
	OCTAVE 2
	NOTE A_, 2
	DUTY 0
	OCTAVE 3
	NOTE E_, 2
	DUTY 8
	OCTAVE 2
	NOTE A_, 2
	RELEASE 0, 0
	DUTY 0
	VIBRATO $01, 2, 3
	OCTAVE 3
	NOTE D_, 6
	VIBRATO_OFF
	RELEASE $0B, 1
	DUTY 8
	OCTAVE 2
	NOTE A_, 2
	RELEASE 0, 0
	DUTY 0
	OCTAVE 3
	NOTE C_, 4
	RELEASE $0B, 1
	DUTY 8
	OCTAVE 2
	NOTE A_, 2
	RELEASE 0, 0
	DUTY 0
	NOTE B_, 4
	RELEASE $0B, 1
	DUTY 8
	NOTE A_, 2
	DUTY 0
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	OCTAVE 3
	NOTE C_, 4
	VIBRATO_OFF
	OCTAVE 3
	NOTE D_, 2
	NOTE F_, 2
	RELEASE $0B, 1
	NOTE D_, 2
	DUTY 8
	OCTAVE 2
	NOTE A_, 2
	RELEASE 0, 0
	DUTY 0
	VIBRATO $01, 2, 3
	OCTAVE 3
	NOTE D_, 6
	VIBRATO_OFF
	RELEASE $0B, 1
	DUTY 8
	OCTAVE 2
	NOTE A_, 2
	RELEASE 0, 0
	DUTY 0
	OCTAVE 3
	NOTE C_, 4
	RELEASE $0B, 1
	DUTY 8
	OCTAVE 2
	NOTE A_, 2
	RELEASE 0, 0
	DUTY 0
	OCTAVE 3
	NOTE C_, 2
	DUTY 8
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	LOOP_END $02
	VOICE $04, 0, 12, 0, 0
	SND_CALL SndEC_Ch1_4A77
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	ATTEN 0
	NOTE A_, 2
	DUTY 8
	RELEASE $0B, 1
	ATTEN 1
	OCTAVE 3
	NOTE D_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 2
	RELEASE 0, 0
	NOTE F_, 2
	RELEASE $0B, 1
	OCTAVE 3
	NOTE D_, 2
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	ATTEN 0
	NOTE A_, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 1
	OCTAVE 3
	NOTE D_, 2
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	ATTEN 0
	NOTE A_, 2
	DUTY 8
	RELEASE $0B, 1
	ATTEN 1
	OCTAVE 3
	NOTE C#, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 2
	RELEASE 0, 0
	NOTE F_, 2
	RELEASE $0B, 1
	OCTAVE 3
	NOTE C_, 2
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	ATTEN 0
	NOTE A_, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 1
	OCTAVE 3
	NOTE C_, 2
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	ATTEN 0
	NOTE A_, 2
	DUTY 8
	RELEASE $0B, 1
	ATTEN 1
	OCTAVE 3
	NOTE D_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 2
	RELEASE 0, 0
	NOTE F#, 2
	RELEASE $0B, 1
	OCTAVE 3
	NOTE D_, 2
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	ATTEN 0
	NOTE A_, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 1
	OCTAVE 3
	NOTE D_, 2
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	ATTEN 0
	NOTE G_, 2
	DUTY 8
	RELEASE $0B, 1
	ATTEN 1
	OCTAVE 3
	NOTE D_, 2
	NOTE B_, 2
	NOTE G_, 2
	RELEASE 0, 0
	NOTE B_, 2
	OCTAVE 4
	NOTE G_, 2
	DUTY 0
	OCTAVE 2
	ATTEN 0
	NOTE A_, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 1
	OCTAVE 3
	NOTE D_, 2
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	ATTEN 0
	NOTE F_, 2
	DUTY 8
	RELEASE $0B, 1
	ATTEN 1
	OCTAVE 3
	NOTE D_, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	RELEASE 0, 0
	OCTAVE 3
	NOTE A#, 2
	RELEASE $0B, 1
	OCTAVE 3
	NOTE D_, 2
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	ATTEN 0
	NOTE F_, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 1
	OCTAVE 3
	NOTE D_, 2
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	ATTEN 0
	NOTE G#, 2
	DUTY 8
	RELEASE $0B, 1
	ATTEN 1
	OCTAVE 3
	NOTE D_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	RELEASE 0, 0
	NOTE G_, 2
	RELEASE $0B, 1
	OCTAVE 3
	NOTE D_, 2
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	ATTEN 0
	NOTE A_, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 1
	OCTAVE 3
	NOTE D_, 2
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	ATTEN 0
	NOTE E_, 2
	DUTY 8
	RELEASE $0B, 1
	ATTEN 1
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 2
	RELEASE 0, 0
	NOTE F_, 2
	RELEASE $0B, 1
	OCTAVE 3
	NOTE D_, 2
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	ATTEN 0
	NOTE E_, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 1
	OCTAVE 3
	NOTE D_, 2
	ATTEN 0
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	NOTE E_, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 1
	OCTAVE 3
	NOTE C#, 2
	ATTEN 0
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	NOTE E_, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 1
	NOTE A#, 2
	ATTEN 0
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	NOTE E_, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 1
	NOTE B_, 2
	ATTEN 0
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	NOTE E_, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 1
	OCTAVE 3
	NOTE C#, 2
	LOOP2_START
	SND_CALL SndEC_Ch1_4A77
	LOOP2_END $02
	SND_LOOP

SndEC_Ch3:
	VOICE $08, 1, 2, 0, 0
	VIBRATO $01, 2, 4
	OCTAVE 4
	NOTE G_, 8
	NOTE F#, 8
	NOTE D#, 8
	NOTE C_, 8
	OCTAVE 3
	NOTE G_, 8
	NOTE F#, 8
	NOTE D#, 8
	VIBRATO_OFF
	NOTE D_, 0
	VIBRATO $01, 0, 5
	NOTE D_, 0
	VIBRATO_OFF
	ENVELOPE $00
	VOICE $04, 1, 2, 0, 0
	OCTAVE 3
	NOTE D_, 0
	VIBRATO $01, 0, 2
	NOTE D_, 0
	VIBRATO $01, 0, 4
	NOTE D_, 0
	NOTE D_, 0
	VIBRATO_OFF
	NOTE D#, 0
	VIBRATO $01, 0, 4
	NOTE D#, 0
	VIBRATO_OFF
	NOTE G#, 0
	VIBRATO $01, 0, 4
	NOTE G#, 0
	NOTE G#, 0
	NOTE G#, 8
	VIBRATO $03, 0, 2
	NOTE G#, 8
	VIBRATO_OFF
	SND_SEGNO
	LOOP2_START
	LOOP_START
	OCTAVE 3
	NOTE D_, 4
	PAN_LEFT 0
	RELEASE $0D, 1
	OCTAVE 5
	NOTE D_, 2
	RELEASE 0, 0
	PAN_BOTH 0
	LOOP_END $02
	OCTAVE 3
	NOTE C_, 4
	LOOP_START
	OCTAVE 3
	NOTE D_, 4
	PAN_RIGHT 0
	RELEASE $0D, 1
	OCTAVE 5
	NOTE D_, 2
	RELEASE 0, 0
	PAN_BOTH 0
	LOOP_END $02
	OCTAVE 3
	NOTE C_, 4
	LOOP_START
	OCTAVE 2
	NOTE A#, 4
	PAN_LEFT 0
	RELEASE $0D, 1
	OCTAVE 5
	NOTE D_, 2
	RELEASE 0, 0
	PAN_BOTH 0
	LOOP_END $02
	OCTAVE 2
	NOTE A#, 4
	LOOP_START
	OCTAVE 3
	NOTE C_, 4
	PAN_RIGHT 0
	RELEASE $0D, 1
	OCTAVE 5
	NOTE D_, 2
	RELEASE 0, 0
	PAN_BOTH 0
	LOOP_END $02
	OCTAVE 3
	NOTE C_, 4
	LOOP2_END $02
	LOOP2_START
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE D_, 2
	WAVE $0B
	RELEASE $0B, 1
	OCTAVE 4
	NOTE F_, 2
	LOOP_BREAK $FB
	NOTE F_, 2
	LOOP_END $03
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE C#, 2
	WAVE $0B
	RELEASE $0B, 1
	OCTAVE 4
	NOTE F_, 2
	LOOP_BREAK $FB
	NOTE F_, 2
	LOOP_END $03
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE C_, 2
	WAVE $0B
	RELEASE $0B, 1
	OCTAVE 4
	NOTE F#, 2
	LOOP_BREAK $FB
	NOTE F#, 2
	LOOP_END $03
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 2
	WAVE $0B
	RELEASE $0B, 1
	OCTAVE 4
	NOTE G_, 2
	LOOP_BREAK $FB
	NOTE G_, 2
	LOOP_END $03
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A#, 2
	WAVE $0B
	RELEASE $0B, 1
	OCTAVE 4
	NOTE G_, 2
	LOOP_BREAK $FB
	NOTE G_, 2
	LOOP_END $03
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 2
	WAVE $0B
	RELEASE $0B, 1
	OCTAVE 4
	NOTE G_, 2
	LOOP_BREAK $FB
	NOTE G_, 2
	LOOP_END $03
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 2
	WAVE $0B
	RELEASE $0B, 1
	OCTAVE 4
	NOTE F_, 2
	LOOP_BREAK $FB
	NOTE F_, 2
	LOOP_END $03
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 2
	WAVE $0B
	RELEASE $0B, 1
	OCTAVE 4
	NOTE E_, 2
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 2
	WAVE $0B
	RELEASE $0B, 1
	OCTAVE 4
	NOTE C#, 2
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 2
	WAVE $0B
	RELEASE $0B, 1
	OCTAVE 4
	NOTE D_, 2
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 2
	WAVE $0B
	RELEASE $0B, 1
	OCTAVE 4
	NOTE E_, 2
	LOOP2_END $04
	WAVE 1
	RELEASE 0, 0
	SND_LOOP

SndEC_Drm:
	LEN_UNIT $04
	LOOP_START
	REST 0
	LOOP_END $0B
	LOOP_START
	REST 0
	LOOP_END $08
	DRUM 9, 4
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 2
	LOOP_START
	DRUM $0B, 1
	LOOP_END $08
	SND_SEGNO
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $0D
	LOOP_START
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0B, 1
	DRUM $0B, 1
	LOOP_END $02
	DRUM 9, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 5, 1
	LOOP2_START
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $0D
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	LOOP_END $02
	DRUM 9, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $0D
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	LOOP_START
	DRUM $0B, 1
	LOOP_END $08
	LOOP2_END $02
	SND_LOOP
SndEC_Ch1_4A1E:
	RELEASE 4, 0
	OCTAVE 3
	NOTE A_, 6
	RELEASE $0B, 1
	NOTE A_, 2
	REST 4
	RELEASE 0, 0
	NOTE G_, 4
	VIBRATO $01, 0, 3
	NOTE G_, 0
	VIBRATO_OFF
	RELEASE 4, 0
	OCTAVE 3
	NOTE F_, 6
	RELEASE $0B, 1
	NOTE F_, 2
	REST 4
	RELEASE 0, 0
	VIBRATO $01, 3, 3
	ENVELOPE $0E
	NOTE E_, 12
	ENVELOPE $00
	NOTE F_, 8
	VIBRATO_OFF
	SND_RET
SndEC_Ch2_4A45:
	NOTE A_, 2
	DUTY 8
	NOTE C_, 2
	RELEASE 0, 0
	DUTY 0
	VIBRATO $01, 2, 3
	NOTE G_, 6
	VIBRATO_OFF
	RELEASE $0B, 1
	DUTY 8
	NOTE C_, 2
	RELEASE 0, 0
	DUTY 0
	NOTE F_, 4
	RELEASE $0B, 1
	DUTY 8
	NOTE C_, 2
	RELEASE 0, 0
	DUTY 0
	NOTE E_, 4
	RELEASE $0B, 1
	DUTY 8
	NOTE C_, 2
	DUTY 0
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	NOTE F_, 4
	VIBRATO_OFF
	SND_RET
SndEC_Ch1_4A77:
	LOOP_START
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	ATTEN 0
	NOTE A_, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 1
	OCTAVE 3
	NOTE D_, 2
	LOOP_BREAK $FB
	NOTE D_, 2
	LOOP_END $03
	LOOP_START
	RELEASE 0, 0
	DUTY 0
	ATTEN 0
	OCTAVE 2
	NOTE A_, 2
	RELEASE $0B, 1
	ATTEN 1
	DUTY 8
	OCTAVE 3
	NOTE C#, 2
	LOOP_BREAK $FB
	NOTE C#, 2
	LOOP_END $03
	LOOP_START
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	ATTEN 0
	NOTE A_, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 1
	OCTAVE 3
	NOTE D_, 2
	LOOP_BREAK $FB
	NOTE D_, 2
	LOOP_END $03
	LOOP_START
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	ATTEN 0
	NOTE G_, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 1
	OCTAVE 3
	NOTE D_, 2
	LOOP_BREAK $FB
	NOTE D_, 2
	LOOP_END $03
	LOOP_START
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	ATTEN 0
	NOTE F_, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 1
	OCTAVE 3
	NOTE D_, 2
	LOOP_BREAK $FB
	NOTE D_, 2
	LOOP_END $03
	LOOP_START
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	ATTEN 0
	NOTE G#, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 1
	OCTAVE 3
	NOTE D_, 2
	LOOP_BREAK $FB
	NOTE D_, 2
	LOOP_END $03
	LOOP_START
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	ATTEN 0
	NOTE E_, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 1
	OCTAVE 3
	NOTE D_, 2
	LOOP_BREAK $FB
	NOTE D_, 2
	LOOP_END $03
	ATTEN 0
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	NOTE E_, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 1
	OCTAVE 3
	NOTE C#, 2
	ATTEN 0
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	NOTE E_, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 1
	NOTE A#, 2
	ATTEN 0
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	NOTE E_, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 1
	NOTE B_, 2
	ATTEN 0
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	NOTE E_, 2
	RELEASE $0B, 1
	DUTY 8
	ATTEN 1
	OCTAVE 3
	NOTE C#, 2
	SND_RET

SndED_Ch2:
	SND_SEGNO
	VOICE $06, 8, 8, 0, 0
	LOOP2_START
	LOOP_START
	RELEASE $0A, 1
	OCTAVE 4
	NOTE C_, 1
	RELEASE 0, 0
	REST 2
	VIBRATO $01, 1, 2
	NOTE C_, 5
	VIBRATO_OFF
	RELEASE $0A, 1
	NOTE D_, 1
	RELEASE 0, 0
	REST 2
	VIBRATO $01, 1, 2
	NOTE D_, 5
	VIBRATO_OFF
	LOOP_END $02
	TRANSPOSE_UP 3
	LOOP2_END $02
	TRANSPOSE_UP 0
	LOOP2_START
	LOOP_START
	RELEASE $0A, 1
	OCTAVE 4
	NOTE D#, 1
	RELEASE 0, 0
	REST 2
	VIBRATO $01, 1, 2
	NOTE D#, 5
	VIBRATO_OFF
	RELEASE $0A, 1
	NOTE F_, 1
	RELEASE 0, 0
	REST 2
	VIBRATO $01, 1, 2
	NOTE F_, 5
	VIBRATO_OFF
	LOOP_END $02
	TRANSPOSE_UP 3
	LOOP2_END $02
	TRANSPOSE_UP 0
	SND_LOOP

SndED_Ch1:
	SND_SEGNO
	VOICE $06, 8, 12, 10, 1
	LOOP2_START
	LOOP_START
	SND_CALL SndED_Ch1_4CBE
	LOOP_END $02
	TRANSPOSE_UP 3
	LOOP2_END $02
	LOOP_START
	SND_CALL SndED_Ch1_4CBE
	LOOP_END $02
	TRANSPOSE_UP 6
	SND_CALL SndED_Ch1_4CBE
	RELEASE $0A, 1
	DUTY 8
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	RELEASE 0, 0
	DUTY 0
	AUTOPAN 0
	NOTE G#, 1
	OCTAVE 4
	NOTE D#, 1
	RELEASE $0A, 1
	DUTY 8
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	RELEASE 0, 0
	DUTY 0
	AUTOPAN 0
	OCTAVE 4
	NOTE G#, 1
	NOTE D#, 1
	RELEASE $0A, 1
	DUTY 8
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	RELEASE 0, 0
	DUTY 0
	PAN_LEFT 0
	NOTE G#, 1
	TRANSPOSE_UP 0
	RELEASE $0A, 1
	DUTY 8
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE B_, 1
	RELEASE 0, 0
	DUTY 0
	PAN_RIGHT 0
	OCTAVE 5
	NOTE E_, 1
	PAN_LEFT 0
	OCTAVE 4
	NOTE B_, 1
	RELEASE $0A, 1
	DUTY 8
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE B_, 1
	RELEASE 0, 0
	DUTY 0
	PAN_RIGHT 0
	OCTAVE 4
	NOTE E_, 1
	PAN_LEFT 0
	NOTE B_, 1
	RELEASE $0A, 1
	DUTY 8
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE B_, 1
	RELEASE 0, 0
	DUTY 0
	PAN_RIGHT 0
	OCTAVE 4
	NOTE E_, 1
	SND_LOOP

SndED_Ch3:
	SND_SEGNO
	VOICE $06, 1, 2, 0, 0
	SND_CALL SndED_Ch3_4D2A
	LOOP_START
	RELEASE $0A, 1
	WAVE_X $15
	OCTAVE 4
	NOTE C#, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C#, 2
	LOOP_END $02
	RELEASE $0A, 1
	WAVE_X $15
	OCTAVE 4
	NOTE C#, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C#, 1
	TRANSPOSE_UP 3
	SND_CALL SndED_Ch3_4D2A
	TRANSPOSE_UP 0
	RELEASE $0A, 1
	WAVE_X $15
	OCTAVE 4
	NOTE E_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE E_, 2
	RELEASE $0A, 1
	WAVE_X $15
	OCTAVE 4
	NOTE E_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 2
	RELEASE $0A, 1
	WAVE_X $15
	OCTAVE 4
	NOTE E_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C#, 1
	SND_LOOP

SndED_Drm:
	LEN_UNIT $06
	SND_SEGNO
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_BREAK $FB
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_END $03
	LOOP_START
	DRUM 9, 1
	DRUM 3, 1
	LOOP_END $04
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	LOOP_BREAK $FB
	DRUM 8, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 8, 1
	SND_LOOP
SndED_Ch1_4CBE:
	RELEASE $0A, 1
	DUTY 8
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	RELEASE 0, 0
	DUTY 0
	AUTOPAN 0
	NOTE G#, 1
	OCTAVE 4
	NOTE D#, 1
	RELEASE $0A, 1
	DUTY 8
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	RELEASE 0, 0
	DUTY 0
	AUTOPAN 0
	OCTAVE 4
	NOTE G#, 1
	NOTE D#, 1
	RELEASE $0A, 1
	DUTY 8
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	RELEASE 0, 0
	DUTY 0
	PAN_LEFT 0
	NOTE G#, 1
	RELEASE $0A, 1
	DUTY 8
	PAN_BOTH 0
	ATTEN 0
	NOTE F_, 1
	RELEASE 0, 0
	DUTY 0
	PAN_RIGHT 0
	NOTE A#, 1
	PAN_LEFT 0
	OCTAVE 4
	NOTE F_, 1
	RELEASE $0A, 1
	DUTY 8
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE F_, 1
	RELEASE 0, 0
	DUTY 0
	PAN_RIGHT 0
	OCTAVE 4
	NOTE A#, 1
	PAN_LEFT 0
	NOTE F_, 1
	RELEASE $0A, 1
	DUTY 8
	PAN_BOTH 0
	ATTEN 0
	OCTAVE 3
	NOTE F_, 1
	RELEASE 0, 0
	DUTY 0
	PAN_RIGHT 0
	NOTE A#, 1
	SND_RET
SndED_Ch3_4D2A:
	LOOP2_START
	LOOP_START
	RELEASE $0A, 1
	WAVE_X $15
	OCTAVE 3
	NOTE G#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE G#, 2
	LOOP_END $02
	RELEASE $0A, 1
	WAVE_X $15
	NOTE C_HI, 1
	WAVE 1
	RELEASE 0, 0
	NOTE G#, 1
	LOOP_START
	RELEASE $0A, 1
	WAVE_X $15
	OCTAVE 3
	NOTE A#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE G#, 2
	LOOP_END $02
	RELEASE $0A, 1
	WAVE_X $15
	OCTAVE 3
	NOTE A#, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE G#, 1
	LOOP2_END $02
	LOOP2_START
	LOOP_START
	RELEASE $0A, 1
	WAVE_X $15
	OCTAVE 3
	NOTE B_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE G#, 2
	LOOP_END $02
	RELEASE $0A, 1
	WAVE_X $15
	OCTAVE 3
	NOTE B_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE G#, 1
	LOOP_BREAK $FC
	LOOP_START
	RELEASE $0A, 1
	WAVE_X $15
	OCTAVE 4
	NOTE C#, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE G#, 2
	LOOP_END $02
	RELEASE $0A, 1
	WAVE_X $15
	OCTAVE 4
	NOTE C#, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE G#, 1
	LOOP2_END $02
	SND_RET

SndEE_Ch2:
	VOICE $03, 8, 11, 15, 1
	PAN_LEFT 0
	REST 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	VOICE $06, 4, 14, 0, 0
	SND_SEGNO
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE C_, 2
	NOTE C_HI, 1
	ATTEN 7
	OCTAVE 5
	NOTE C_, 1
	ATTEN 0
	LOOP_END $04
	LOOP_BREAK $FC
	LOOP_START
	OCTAVE 1
	NOTE A#, 2
	NOTE C_HI, 1
	ATTEN 7
	OCTAVE 5
	NOTE C_, 1
	ATTEN 0
	LOOP_END $04
	LOOP2_END $02
	LOOP_START
	OCTAVE 2
	NOTE D_, 2
	NOTE C_HI, 1
	ATTEN 7
	OCTAVE 5
	NOTE C_, 1
	ATTEN 0
	LOOP_END $03
	OCTAVE 2
	NOTE D_, 1
	NOTE C_HI, 1
	NOTE D_, 1
	NOTE C_HI, 1
	SND_LOOP

SndEE_Ch1:
	VOICE $03, 8, 11, 15, 1
	PAN_RIGHT 0
	REST 2
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	VOICE $06, 8, 8, 0, 0
	SND_SEGNO
	OCTAVE 3
	VIBRATO $01, 2, 1
	NOTE G_, 4
	NOTE F_, 4
	VIBRATO_OFF
	RELEASE $0B, 1
	NOTE G_, 2
	NOTE F_, 2
	NOTE G_, 2
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	NOTE A#, 4
	RELEASE $0B, 1
	VIBRATO_OFF
	NOTE A#, 2
	RELEASE 0, 0
	VIBRATO $01, 2, 2
	NOTE A_, 4
	DUTY 0
	NOTE D_, 4
	VIBRATO $04, 0, 3
	NOTE C_HI, 4
	DUTY 8
	VIBRATO $01, 2, 1
	NOTE G_, 4
	NOTE F_, 4
	RELEASE $0B, 1
	VIBRATO_OFF
	NOTE G_, 2
	NOTE A_, 2
	NOTE A#, 2
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE C_, 4
	RELEASE $0B, 1
	VIBRATO_OFF
	OCTAVE 3
	NOTE A_, 2
	RELEASE 0, 0
	OCTAVE 4
	NOTE C_, 2
	VIBRATO $01, 2, 1
	OCTAVE 3
	NOTE A_, 4
	RELEASE $0B, 1
	OCTAVE 4
	NOTE C_, 2
	RELEASE 0, 0
	NOTE D_, 4
	SND_LOOP

SndEE_Ch3:
	VOICE $03, 11, 2, 15, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	VOICE $06, 5, 2, 0, 0
	SND_SEGNO
	OCTAVE 5
	VIBRATO $01, 2, 1
	NOTE E_, 4
	NOTE D_, 4
	VIBRATO_OFF
	RELEASE $0B, 1
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	NOTE F_, 4
	RELEASE $0B, 1
	VIBRATO_OFF
	NOTE E_, 2
	RELEASE 0, 0
	VIBRATO $01, 2, 2
	NOTE C_, 4
	VIBRATO_OFF
	WAVE 3
	RELEASE $0B, 1
	PAN_LEFT 0
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	PAN_RIGHT 0
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 5
	OCTAVE 5
	VIBRATO $01, 2, 1
	NOTE E_, 4
	NOTE D_, 4
	RELEASE $0B, 1
	VIBRATO_OFF
	NOTE E_, 2
	NOTE F_, 2
	NOTE F#, 2
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	NOTE G_, 4
	RELEASE $0B, 1
	VIBRATO_OFF
	NOTE E_, 2
	RELEASE 0, 0
	NOTE G_, 2
	VIBRATO $01, 2, 1
	NOTE F#, 4
	RELEASE $0B, 1
	NOTE G_, 2
	RELEASE 0, 0
	NOTE A_, 4
	SND_LOOP

SndEE_Drm:
	LEN_UNIT $06
	REST 8
	SND_SEGNO
	DRUM $0C, 2
	DRUM 3, 2
	LOOP_START
	DRUM 9, 2
	DRUM 3, 2
	LOOP_END $05
	DRUM 9, 2
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM $0C, 2
	LOOP_START
	DRUM 3, 2
	DRUM 9, 2
	LOOP_END $05
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 2
	DRUM 3, 2
	SND_LOOP

SndEF_Ch2:
	VOICE $04, 8, 8, 0, 0
	DETUNE $FF
	OCTAVE 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	RELEASE $0B, 1
	NOTE G_, 4
	REST 2
	DETUNE $00
	RELEASE 0, 0
	NOTE F#, 6
	RELEASE $0B, 1
	NOTE G_, 3
	REST 3
	OCTAVE 3
	NOTE G_, 4
	NOTE G_, 2
	RELEASE 0, 0
	VIBRATO $01, 2, 2
	NOTE G_, 12
	SND_END

SndEF_Ch1:
	VOICE $04, 8, 10, 0, 0
	OCTAVE 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 4
	RELEASE $0B, 1
	NOTE D_, 4
	REST 2
	RELEASE 0, 0
	NOTE C_, 6
	RELEASE $0B, 1
	NOTE D_, 3
	REST 3
	OCTAVE 3
	NOTE D_, 4
	NOTE D_, 2
	RELEASE 0, 0
	VIBRATO $01, 2, 2
	NOTE D_, 12
	SND_END

SndEF_Ch3:
	VOICE $04, 0, 2, 0, 0
	OCTAVE 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	RELEASE $0B, 1
	NOTE G_, 4
	REST 2
	RELEASE 0, 0
	NOTE G#, 6
	RELEASE $0B, 1
	NOTE B_, 3
	REST 3
	OCTAVE 3
	NOTE B_, 4
	NOTE B_, 2
	RELEASE 0, 0
	VIBRATO $01, 2, 2
	NOTE B_, 12
	SND_END

SndEF_Drm:
	LEN_UNIT $04
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 6
	DRUM 3, 6
	DRUM 3, 3
	DRUM 3, 3
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM $0C, $0C
	SND_END

SndF0_Ch1:
	SND_SEGNO
	VOICE $07, 0, 6, 4, 0
	DETUNE $06
	TRANSPOSE_DOWN $0C
	SND_CALL SndF0_Ch1_4F81 ; Ch1 calls the part it shares with Ch2

SndF0_Ch2:
	SND_LOOP ; Ch1 loops to its segno here; Ch2 starts on this byte (its segno)
	VOICE $07, 4, 15, 4, 0
	DUTY_STEP 0, 1
SndF0_Ch1_4F81:
	OCTAVE 2
	NOTE D_, 1
	RELEASE $0B, 1
	NOTE D_, 1
	REST 3
	VIBRATO $05, 0, 5
	NOTE D_, 1
	REST 1
	VIBRATO_OFF
	RELEASE 9, 1
	NOTE D_, 1
	REST 3
	VIBRATO $01, 2, 5
	RELEASE 3, 0
	NOTE C_, 5
	REST 1
	VIBRATO $04, 0, 3
	NOTE D_, 3
	REST 1
	VIBRATO_SEMI 2
	NOTE C_, 2
	VIBRATO_OFF
	NOTE D_, 1
	REST 1
	VIBRATO_SEMI 1
	NOTE G_, 2
	VIBRATO_OFF
	RELEASE $0E, 1
	NOTE F_, 1
	REST 1
	RELEASE 3, 0
	VIBRATO $03, 1, 3
	NOTE C_, 3
	VIBRATO_OFF
	RELEASE 4, 0
	OCTAVE 2
	NOTE D_, 1
	RELEASE $0B, 1
	NOTE D_, 1
	REST 3
	VIBRATO $05, 0, 5
	NOTE D_, 1
	REST 1
	RELEASE 0, 0
	VIBRATO $07, 0, 4
	NOTE D_, 2
	VIBRATO $01, 0, 4
	NOTE D_, 2
	RELEASE $0B, 1
	VIBRATO_OFF
	NOTE C_, 1
	REST 1
	NOTE D_, 1
	REST 1
	NOTE D#, 1
	RELEASE 4, 0
	OCTAVE 2
	NOTE D_, 1
	RELEASE $0B, 1
	NOTE D_, 1
	REST 1
	VIBRATO $05, 0, 7
	NOTE F_, 1
	VIBRATO_OFF
	REST 2
	RELEASE 7, 1
	VIBRATO_SEMI 3
	NOTE C_, 2
	REST 1
	RELEASE 0, 0
	VIBRATO $07, 0, 4
	NOTE D#, 1
	VIBRATO $01, 0, 5
	NOTE D#, 2
	RELEASE $0F, 1
	VIBRATO_OFF
	NOTE D_, 1
	REST 1
	NOTE C_, 1
	REST 1
	RELEASE 4, 0
	OCTAVE 2
	NOTE D_, 1
	RELEASE $0B, 1
	NOTE D_, 1
	REST 3
	VIBRATO $05, 0, 5
	NOTE D_, 1
	REST 1
	VIBRATO_OFF
	RELEASE 9, 1
	NOTE D_, 1
	REST 3
	VIBRATO $01, 2, 5
	RELEASE 3, 0
	NOTE C_, 5
	RELEASE 0, 0
	VIBRATO $04, 0, 5
	NOTE F_, 2
	VIBRATO_OFF
	RELEASE $0F, 1
	NOTE D#, 1
	REST 2
	NOTE D_, 1
	REST 1
	NOTE C_, 1
	REST 1
	RELEASE 0, 0
	VIBRATO $04, 0, 4
	NOTE G#, 1
	VIBRATO $01, 0, 5
	NOTE G#, 2
	RELEASE $0F, 1
	VIBRATO_OFF
	NOTE G_, 1
	REST 1
	NOTE F_, 1
	REST 1
	RELEASE 0, 0
	NOTE D_, 1
	RELEASE $0F, 1
	NOTE C_HI, 1
	REST 1
	RELEASE 0, 0
	VIBRATO $01, 0, 4
	NOTE D_, 2
	VIBRATO_OFF
	RELEASE $0F, 1
	REST 1
	NOTE D_, 1
	REST 1
	REST 1
	NOTE D_, 1
	REST 1
	VIBRATO $03, 3, 8
	RELEASE 3, 0
	NOTE C_, 5
	RELEASE 4, 0
	OCTAVE 2
	NOTE D_, 1
	RELEASE $0B, 1
	NOTE D_, 1
	REST 3
	VIBRATO $05, 0, 5
	NOTE D_, 1
	REST 1
	VIBRATO_OFF
	RELEASE 9, 1
	NOTE D_, 1
	REST 1
	RELEASE 0, 0
	VIBRATO $07, 0, 4
	NOTE F_, 1
	VIBRATO $01, 0, 5
	NOTE F_, 2
	RELEASE 3, 0
	VIBRATO_SEMI 1
	NOTE D#, 2
	VIBRATO_SEMI 2
	NOTE C_, 2
	VIBRATO_OFF
	SND_LOOP
	db $FD ; unreachable return

SndF0_Ch3:
	VOICE $07, 2, 2, 15, 1
	DETUNE $F8
	TRANSPOSE_DOWN 7
	SND_SEGNO
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	REST 3
	NOTE D_, 1
	REST 1
	NOTE D_, 1
	REST 8
	REST 1
	NOTE D_, 1
	REST 3
	NOTE D_, 2
	NOTE D_, 1
	REST 1
	NOTE G#, 1
	REST 3
	NOTE C_, 1
	REST 2
	NOTE D_, 1
	NOTE D_, 1
	REST 3
	NOTE D_, 1
	REST 1
	VIBRATO $07, 0, 4
	NOTE D_, 1
	REST 3
	VIBRATO_OFF
	NOTE C_, 1
	REST 1
	NOTE D_, 1
	REST 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE D_, 1
	REST 1
	VIBRATO $05, 0, 7
	NOTE F_, 1
	VIBRATO_OFF
	REST 2
	NOTE C_, 1
	REST 2
	VIBRATO $07, 0, 4
	NOTE D#, 3
	VIBRATO_OFF
	NOTE D_, 1
	REST 1
	NOTE C_, 1
	REST 1
	NOTE D_, 1
	NOTE D_, 1
	REST 3
	NOTE D_, 1
	REST 1
	NOTE D_, 1
	REST 8
	VIBRATO $04, 0, 5
	NOTE F_, 2
	VIBRATO_OFF
	NOTE D#, 1
	REST 2
	NOTE D_, 1
	REST 1
	NOTE C_, 1
	REST 1
	VIBRATO $07, 0, 4
	NOTE G#, 3
	VIBRATO_OFF
	NOTE G_, 1
	REST 1
	NOTE F_, 1
	REST 1
	NOTE D_, 1
	NOTE C_HI, 1
	REST 1
	NOTE D_, 1
	REST 2
	NOTE D_, 1
	REST 2
	NOTE D_, 1
	REST 6
	NOTE D_, 1
	NOTE D_, 1
	REST 3
	NOTE D_, 1
	REST 1
	NOTE D_, 1
	REST 1
	VIBRATO $07, 0, 4
	NOTE F_, 3
	VIBRATO_OFF
	NOTE E_, 1
	REST 1
	NOTE D_, 1
	REST 1
	SND_LOOP

SndF0_Drm:
	LEN_UNIT $07
	SND_SEGNO
	DRUM $0A, 2
	DRUM 7, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	LOOP_BREAK $FB
	DRUM 8, 1
	LOOP_END $03
	DRUM 3, 1
	DRUM $0A, 2
	DRUM 7, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	LOOP_BREAK $FB
	DRUM 7, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM 3, 1
	DRUM 5, 1
	DRUM 4, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	SND_LOOP

SndF1_Ch2:
	SND_SEGNO
	VOICE $07, 4, 9, 11, 1
	LOOP2_START
	DUTY 4
	RELEASE $0B, 1
	ATTEN 0
	OCTAVE 3
	NOTE D_, 2
	DUTY 8
	ATTEN 2
	OCTAVE 4
	NOTE D_, 2
	RELEASE 0, 0
	NOTE C_, 1
	RELEASE $0B, 1
	NOTE D_, 1
	DUTY 4
	ATTEN 0
	OCTAVE 3
	NOTE D_, 1
	LOOP_START
	DUTY 8
	ATTEN 2
	OCTAVE 4
	NOTE F_, 1
	DUTY 4
	ATTEN 0
	OCTAVE 3
	NOTE D_, 1
	LOOP_END $02
	DUTY 8
	RELEASE 0, 0
	ATTEN 3
	OCTAVE 4
	VIBRATO $04, 0, 1
	NOTE G_, 2
	VIBRATO_OFF
	NOTE F_, 2
	NOTE G_, 1
	ATTEN 2
	VIBRATO $04, 0, 1
	ATTEN 4
	NOTE A_, 3
	VIBRATO $01, 2, 2
	NOTE G_, 5
	NOTE F_, 3
	LOOP_BREAK $FC
	NOTE G_, 4
	VIBRATO $03, 0, 3
	NOTE G_, 1
	VIBRATO_OFF
	LOOP2_END $02
	NOTE E_, 4
	VIBRATO $03, 0, 3
	NOTE E_, 1
	VOICE $07, 8, 6, 0, 0
	ATTEN 0
	VIBRATO $01, 3, 2
	OCTAVE 4
	NOTE D_, 10
	RELEASE $0B, 1
	VIBRATO_OFF
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	RELEASE 0, 0
	ATTEN 1
	NOTE F_, 3
	VIBRATO $01, 2, 2
	NOTE E_, 5
	VIBRATO_OFF
	NOTE F_, 3
	VIBRATO $01, 2, 3
	NOTE G_, 5
	VIBRATO $01, 3, 3
	NOTE F_, 10
	RELEASE $0B, 1
	VIBRATO_OFF
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	RELEASE 0, 0
	NOTE A_, 3
	VIBRATO $01, 2, 2
	NOTE G_, 5
	VIBRATO $04, 0, 2
	NOTE A#, 3
	VIBRATO $01, 2, 2
	NOTE A_, 5
	VIBRATO $01, 3, 2
	ATTEN 0
	OCTAVE 4
	NOTE D_, 10
	RELEASE $0B, 1
	VIBRATO_OFF
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	RELEASE 0, 0
	NOTE F_, 1
	NOTE E_, 1
	RELEASE $0B, 1
	NOTE F_, 1
	RELEASE 0, 0
	NOTE G_, 1
	NOTE F_, 1
	RELEASE $0B, 1
	NOTE G_, 1
	RELEASE 0, 0
	NOTE A_, 1
	NOTE G_, 1
	RELEASE $0B, 1
	NOTE A_, 1
	RELEASE 0, 0
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
	RELEASE $0B, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	VIBRATO $01, 3, 3
	RELEASE 0, 0
	ATTEN 1
	NOTE F_, 10
	RELEASE $0B, 1
	VIBRATO_OFF
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	RELEASE 0, 0
	VIBRATO $04, 0, 1
	NOTE A_, 4
	VIBRATO $01, 2, 3
	NOTE G_, 4
	VIBRATO $04, 0, 2
	NOTE A#, 4
	VIBRATO $01, 2, 2
	NOTE A_, 4
	VOICE $07, 4, 9, 11, 1
	ATTEN 0
	OCTAVE 3
	NOTE D_, 2
	LOOP2_START
	DUTY 8
	ATTEN 4
	OCTAVE 4
	NOTE D_, 2
	RELEASE 0, 0
	NOTE C_, 1
	LOOP_START
	RELEASE $0B, 1
	OCTAVE 4
	NOTE D_, 1
	DUTY 4
	ATTEN 0
	OCTAVE 3
	NOTE D_, 1
	DUTY 8
	ATTEN 4
	LOOP_END $03
	RELEASE 0, 0
	OCTAVE 4
	VIBRATO $04, 0, 1
	NOTE D_, 2
	VIBRATO_OFF
	RELEASE $0B, 1
	NOTE C_, 1
	REST 1
	NOTE D_, 1
	LOOP_BREAK $FC
	ATTEN 3
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	DUTY $0C
	NOTE A_, 8
	NOTE A#, 8
	VIBRATO_OFF
	NOTE A_, 2
	RELEASE $0B, 1
	LOOP2_END $02
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	DUTY $0C
	ATTEN 3
	NOTE F_, 8
	NOTE G_, 8
	VIBRATO $04, 0, 2
	NOTE A_, 4
	VIBRATO $01, 0, 1
	NOTE A_, 4
	VIBRATO $01, 0, 2
	NOTE A_, 8
	VIBRATO $01, 0, 3
	NOTE A_, 4
	VIBRATO $03, 0, 1
	NOTE A_, 4
	VIBRATO_OFF
	RELEASE $0A, 1
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
	NOTE G#, 1
	ATTEN 0
	NOTE G#, 1
	NOTE G#, 1
	SND_LOOP

SndF1_Ch1:
	SND_SEGNO
	VOICE $07, 4, 10, 11, 1
	LOOP_START
	SND_CALL SndF1_Ch1_550E
	SND_CALL SndF1_Ch1_5540
	LOOP_END $02
	LOOP_START
	DUTY 8
	RELEASE 0, 0
	ATTEN 3
	VIBRATO $01, 3, 2
	OCTAVE 3
	NOTE F_, 10
	RELEASE $0B, 1
	VIBRATO_OFF
	NOTE A_, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	RELEASE $0B, 1
	SND_CALL SndF1_Ch1_5540
	DUTY 8
	RELEASE 0, 0
	ATTEN 3
	VIBRATO $01, 3, 3
	OCTAVE 4
	NOTE D_, 10
	RELEASE $0B, 1
	VIBRATO_OFF
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	RELEASE $0B, 1
	SND_CALL SndF1_Ch1_5540
	LOOP_END $02
	LOOP_START
	SND_CALL SndF1_Ch1_550E
	SND_CALL SndF1_Ch1_5540
	LOOP_END $02
	DUTY 8
	RELEASE 0, 0
	ATTEN 2
	VIBRATO $04, 0, 2
	OCTAVE 3
	NOTE F_, 4
	VIBRATO $01, 0, 1
	NOTE F_, 4
	VIBRATO $01, 0, 2
	NOTE F_, 8
	VIBRATO $01, 0, 3
	NOTE F_, 4
	VIBRATO $03, 0, 1
	NOTE F_, 4
	VIBRATO_OFF
	RELEASE $0A, 1
	ATTEN 5
	NOTE E_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 2
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	NOTE E_, 1
	ATTEN 0
	NOTE E_, 1
	SND_LOOP

SndF1_Ch3:
	SND_SEGNO
	VOICE $07, 1, 2, 0, 0
	LOOP2_START
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 2
	RELEASE $0B, 1
	WAVE 4
	OCTAVE 4
	NOTE A_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 1
	WAVE 4
	OCTAVE 4
	NOTE G_, 1
	LOOP_START
	RELEASE $0B, 1
	NOTE A_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 4
	WAVE 4
	LOOP_END $03
	VIBRATO $04, 0, 2
	OCTAVE 5
	NOTE C_, 1
	VIBRATO_OFF
	WAVE 1
	OCTAVE 3
	NOTE F_, 1
	WAVE 4
	OCTAVE 4
	NOTE A_, 1
	WAVE 1
	OCTAVE 3
	NOTE D_, 1
	WAVE 4
	OCTAVE 5
	NOTE C_, 1
	SND_CALL SndF1_Ch3_558E
	LOOP2_END $02
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A#, 2
	WAVE $0B
	RELEASE $0B, 1
	OCTAVE 4
	NOTE D_, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A#, 1
	WAVE $0B
	RELEASE $0B, 1
	OCTAVE 4
	NOTE A#, 1
	PAN_LEFT 0
	OCTAVE 5
	NOTE F_, 1
	PAN_BOTH 0
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A#, 1
	WAVE $0B
	RELEASE $0B, 1
	PAN_RIGHT 0
	OCTAVE 5
	NOTE A#, 1
	PAN_BOTH 0
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A#, 1
	WAVE 4
	RELEASE $0B, 1
	OCTAVE 4
	NOTE F_, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A#, 1
	WAVE 4
	RELEASE $0B, 1
	NOTE C_HI, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE C_, 1
	WAVE 4
	RELEASE $0B, 1
	OCTAVE 4
	NOTE D_, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A#, 1
	WAVE 4
	RELEASE $0B, 1
	NOTE C_HI, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE C_, 2
	RELEASE $0B, 1
	WAVE 4
	OCTAVE 4
	NOTE F_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	WAVE 4
	OCTAVE 4
	NOTE F_, 1
	RELEASE $0B, 1
	NOTE E_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	WAVE 4
	RELEASE $0B, 1
	OCTAVE 4
	NOTE F_, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 2
	RELEASE $0B, 1
	WAVE 4
	OCTAVE 4
	NOTE F_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	WAVE 4
	OCTAVE 4
	NOTE F_, 1
	RELEASE $0B, 1
	NOTE E_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	WAVE 4
	RELEASE $0B, 1
	OCTAVE 4
	NOTE F_, 1
	LOOP_END $04
	LOOP2_START
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 2
	RELEASE $0B, 1
	WAVE 4
	OCTAVE 4
	NOTE A_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 1
	WAVE 4
	OCTAVE 4
	NOTE G_, 1
	LOOP_START
	RELEASE $0B, 1
	NOTE A_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 4
	WAVE 4
	LOOP_END $03
	VIBRATO $04, 0, 2
	NOTE A_, 1
	VIBRATO_OFF
	WAVE 1
	OCTAVE 3
	NOTE F_, 1
	RELEASE $0B, 1
	WAVE 4
	OCTAVE 4
	NOTE G_, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE D_, 1
	WAVE 4
	RELEASE $0B, 1
	OCTAVE 4
	NOTE A_, 1
	RELEASE 0, 0
	SND_CALL SndF1_Ch3_558E
	LOOP2_END $02
	LOOP_START
	RELEASE 9, 1
	WAVE 1
	OCTAVE 3
	NOTE D_, 1
	RELEASE $0E, 1
	NOTE D_, 1
	LOOP_END $08
	LOOP_START
	RELEASE 9, 1
	OCTAVE 2
	NOTE A#, 1
	RELEASE $0E, 1
	NOTE A#, 1
	LOOP_END $04
	RELEASE $0A, 1
	ATTEN 2
	NOTE C_HI, 1
	NOTE C_HI, 1
	ATTEN 1
	NOTE C_HI, 1
	NOTE C_HI, 1
	ATTEN 0
	NOTE C_HI, 1
	NOTE C_HI, 1
	NOTE C_HI, 1
	NOTE C_HI, 1
	SND_LOOP

SndF1_Drm:
	SND_SEGNO
	LEN_UNIT $07
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	LOOP_START
	DRUM 9, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	LOOP_END $03
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	LOOP_START
	DRUM 9, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 9, 1
	LOOP_BREAK $FB
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	LOOP_END $03
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	LOOP_START
	DRUM 9, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 9, 1
	LOOP_BREAK $FB
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	LOOP_END $03
	DRUM 6, 1
	DRUM 6, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	LOOP_START
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	LOOP_END $02
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 9, 1
	LOOP_START
	DRUM 9, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	LOOP_END $05
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	LEN_UNIT $04
	LOOP_START
	DRUM 3, 1
	LOOP_END $07
	SND_LOOP
SndF1_Ch1_550E:
	DUTY 4
	ATTEN 2
	OCTAVE 3
	NOTE F_, 1
	DUTY 0
	ATTEN 0
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	REST 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	DUTY 4
	ATTEN 2
	OCTAVE 3
	NOTE F_, 1
	DUTY 0
	ATTEN 0
	NOTE C_, 1
	DUTY 4
	ATTEN 2
	NOTE F_, 1
	DUTY 0
	ATTEN 0
	OCTAVE 2
	NOTE A_, 1
	DUTY 4
	ATTEN 2
	OCTAVE 3
	NOTE F_, 1
	DUTY 0
	ATTEN 0
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	SND_RET
SndF1_Ch1_5540:
	ATTEN 0
	DUTY 0
	AUTOPAN 0
	OCTAVE 4
	NOTE D_, 1
	NOTE C_, 1
	DUTY 4
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 1
	DUTY 0
	PAN_LEFT 0
	OCTAVE 4
	NOTE D_, 1
	DUTY 4
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 1
	NOTE C_, 1
	DUTY 0
	PAN_RIGHT 0
	OCTAVE 4
	NOTE C_, 1
	DUTY 4
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 1
	DUTY 0
	AUTOPAN 0
	OCTAVE 4
	NOTE D_, 1
	NOTE C_, 1
	DUTY 4
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 1
	DUTY 0
	PAN_LEFT 0
	OCTAVE 4
	NOTE C_, 1
	DUTY 4
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 1
	NOTE C_, 1
	DUTY 0
	PAN_RIGHT 0
	OCTAVE 4
	NOTE D_, 1
	DUTY 4
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 1
	SND_RET
SndF1_Ch3_558E:
	WAVE 1
	OCTAVE 2
	NOTE A#, 2
	RELEASE $0B, 1
	WAVE 4
	OCTAVE 4
	NOTE F_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A#, 1
	WAVE 4
	OCTAVE 4
	NOTE F_, 1
	RELEASE $0B, 1
	NOTE E_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A#, 1
	WAVE 4
	RELEASE $0B, 1
	OCTAVE 4
	NOTE F_, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE C_, 2
	RELEASE $0B, 1
	WAVE 4
	OCTAVE 4
	NOTE G_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	WAVE 4
	OCTAVE 4
	NOTE F_, 1
	RELEASE $0B, 1
	NOTE G_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	WAVE 4
	RELEASE $0B, 1
	OCTAVE 4
	NOTE G_, 1
	SND_RET

SndF2_Ch2:
	VOICE $03, 8, 8, 0, 0
	REST 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	VOICE $06, 8, 8, 11, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	REST 1
	NOTE E_, 1
	NOTE E_, 1
	REST 1
	RELEASE 0, 0
	NOTE G_, 2
	RELEASE $0B, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	REST 1
	NOTE C_, 1
	NOTE C_, 1
	REST 1
	RELEASE 0, 0
	NOTE D_, 2
	RELEASE $0B, 1
	NOTE E_, 1
	RELEASE 0, 0
	RELEASE 0, 0
	OCTAVE 2
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	RELEASE $0B, 1
	DUTY 8
	OCTAVE 4
	NOTE F#, 1
	RELEASE 0, 0
	RELEASE 0, 0
	OCTAVE 2
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	RELEASE $0B, 1
	DUTY 8
	RELEASE 0, 0
	VIBRATO $04, 0, 1
	OCTAVE 4
	NOTE G#, 2
	VIBRATO_OFF
	NOTE G#, 2
	VIBRATO $01, 3, 2
	NOTE G#, 0
	SND_END

SndF2_Ch1:
	VOICE $03, 8, 8, 0, 0
	REST 2
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	VOICE $06, 8, 8, 11, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	REST 1
	NOTE G_, 1
	NOTE G_, 1
	REST 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE E_, 2
	RELEASE $0B, 1
	NOTE E_, 1
	NOTE E_, 1
	REST 1
	NOTE E_, 1
	NOTE E_, 1
	REST 1
	RELEASE 0, 0
	NOTE F#, 2
	RELEASE $0B, 1
	NOTE G_, 1
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE G_, 1
	RELEASE $0B, 1
	DUTY 8
	OCTAVE 3
	NOTE A_, 1
	DUTY 0
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE A_, 1
	VIBRATO $04, 0, 2
	DUTY 8
	OCTAVE 3
	NOTE B_, 2
	VIBRATO $01, 3, 2
	NOTE B_, 6
	DUTY 0
	NOTE G#, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE B_, 10
	SND_END

SndF2_Ch3:
	VOICE $03, 12, 2, 0, 0
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	VOICE $06, 1, 2, 11, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 1
	REST 1
	NOTE C_, 1
	NOTE C_, 1
	REST 1
	RELEASE 0, 0
	NOTE C_, 2
	RELEASE $0B, 1
	NOTE G_, 1
	NOTE G_, 1
	REST 1
	NOTE G_, 1
	NOTE G_, 1
	REST 1
	RELEASE 0, 0
	NOTE A_, 2
	RELEASE $0B, 1
	LOOP_START
	OCTAVE 3
	NOTE C_, 1
	WAVE $0B
	RELEASE 0, 0
	OCTAVE 4
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	TRANSPOSE_UP 2
	WAVE 1
	RELEASE $0B, 1
	LOOP_END $02
	TRANSPOSE_UP 0
	OCTAVE 3
	NOTE E_, 1
	WAVE $0B
	RELEASE 0, 0
	OCTAVE 4
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE E_, 1
	WAVE 1
	VIBRATO $01, 1, 2
	OCTAVE 4
	NOTE E_, 0
	SND_END

SndF2_Drm:
	LEN_UNIT $06
	REST 6
	LOOP_START
	DRUM $0C, 3
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 2
	LOOP_END $02
	DRUM $0C, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 9, 1
	DRUM 3, 2
	DRUM 3, 1
	DRUM $0C, 4
	DRUM 9, $0A
	DRUM $0B, 1
	DRUM 3, 1
	DRUM 5, $0E
	SND_END

SndF3_Ch2:
	VOICE $07, 0, 8, 4, 0
	OCTAVE 4
	NOTE E_, 2
	RELEASE $0B, 1
	NOTE E_, 1
	REST 1
	NOTE D_, 1
	REST 1
	NOTE C_, 1
	REST 1
	RELEASE 4, 0
	OCTAVE 3
	NOTE B_, 2
	RELEASE $0B, 1
	OCTAVE 4
	NOTE C_, 1
	REST 1
	NOTE D_, 1
	REST 1
	NOTE E_, 1
	REST 1
	OCTAVE 3
	RELEASE 0, 0
	NOTE A_, 1
	REST 1
	DUTY 8
	OCTAVE 4
	NOTE A_, 1
	NOTE E_, 1
	OCTAVE 3
	RELEASE 0, 0
	NOTE E_, 1
	REST 1
	DUTY 8
	OCTAVE 4
	NOTE E_, 1
	NOTE C_, 1
	VIBRATO $01, 2, 3
	OCTAVE 2
	NOTE A_, 8
	SND_END

SndF3_Ch1:
	VOICE $07, 0, 8, 4, 0
	OCTAVE 3
	NOTE G#, 2
	RELEASE $0B, 1
	NOTE G#, 1
	REST 1
	NOTE F#, 1
	REST 1
	NOTE F_, 1
	REST 1
	RELEASE 4, 0
	NOTE F_, 2
	RELEASE $0B, 1
	NOTE F#, 1
	REST 1
	NOTE G_, 1
	REST 1
	NOTE G#, 1
	REST 1
	RELEASE 0, 0
	NOTE E_, 1
	REST 2
	DUTY 8
	ATTEN 2
	OCTAVE 4
	NOTE A_, 1
	ATTEN 0
	OCTAVE 3
	RELEASE 0, 0
	NOTE C_, 1
	DUTY 8
	ATTEN 2
	OCTAVE 4
	NOTE C_, 1
	REST 1
	NOTE E_, 1
	ATTEN 0
	VIBRATO $01, 2, 4
	OCTAVE 2
	NOTE E_, 8
	SND_END

SndF3_Ch3:
	VOICE $07, 1, 2, 4, 0
	OCTAVE 3
	NOTE B_, 2
	RELEASE $0B, 1
	NOTE B_, 1
	REST 1
	NOTE A_, 1
	REST 1
	NOTE G#, 1
	REST 1
	RELEASE 4, 0
	NOTE E_, 2
	RELEASE $0B, 1
	NOTE E_, 1
	REST 1
	NOTE F_, 1
	REST 1
	NOTE G_, 1
	REST 1
	RELEASE 0, 0
	NOTE A_, 1
	WAVE 5
	OCTAVE 5
	NOTE A_, 1
	NOTE E_, 1
	NOTE C_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	WAVE 5
	OCTAVE 5
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE A_, 1
	RELEASE 0, 0
	WAVE 1
	VIBRATO $01, 2, 4
	ATTEN 0
	OCTAVE 2
	NOTE A_, 8
	SND_END

SndF3_Drm:
	LEN_UNIT $07
	DRUM $0A, 4
	DRUM 3, 5
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 9, 1
	DRUM 3, 3
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 2
	DRUM $0A, 1
	SND_END

SndF4_Ch2:
	VOICE $06, 8, 8, 11, 1
	OCTAVE 3
	REST 9
	NOTE B_, 1
	REST 2
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	NOTE B_, 4
	REST 1
	NOTE A_, 1
	REST 2
	RELEASE 0, 0
	NOTE A_, 4
	NOTE G#, 1
	NOTE G_, 1
	VIBRATO $01, 3, 3
	NOTE G#, 14
	SND_END

SndF4_Ch1:
	VOICE $06, 4, 14, 11, 1
	OCTAVE 2
	REST 9
	NOTE F#, 1
	REST 2
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	NOTE F#, 4
	REST 1
	NOTE E_, 1
	REST 2
	RELEASE 0, 0
	NOTE E_, 4
	NOTE E_, 1
	NOTE D#, 1
	VIBRATO $01, 2, 4
	NOTE E_, 6
	VIBRATO $04, 0, 2
	NOTE C_HI, 2
	VIBRATO $01, 2, 3
	NOTE C_HI, 6
	SND_END

SndF4_Ch3:
	VOICE $06, 1, 2, 11, 1
	REST 9
	OCTAVE 4
	NOTE D#, 1
	REST 2
	RELEASE 0, 0
	NOTE D#, 1
	WAVE $0B
	NOTE F#, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE F#, 1
	REST 1
	RELEASE $0B, 1
	WAVE 1
	OCTAVE 4
	NOTE C_, 1
	REST 2
	RELEASE 0, 0
	NOTE C_, 1
	WAVE $0B
	NOTE E_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	WAVE 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE B_, 2
	WAVE $0B
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A#, 1
	VIBRATO $01, 2, 2
	NOTE B_, 8
	SND_END

SndF4_Drm:
	LEN_UNIT $06
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM $0A, 4
	DRUM 3, 2
	DRUM 3, 2
	DRUM 9, 1
	DRUM 3, 2
	DRUM 9, 1
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM $0A, 2
	DRUM 3, 2
	DRUM 9, 1
	DRUM 3, 1
	DRUM 2, 1
	DRUM 9, 1
	DRUM $0A, 6
	DRUM $0B, 1
	DRUM 2, 1
	DRUM 9, 1
	SND_END

SndF5_Ch1:
	VOICE $07, 4, 13, 11, 1
	TRANSPOSE_DOWN 3
	REST 0
	REST 0
	SND_SEGNO
	OCTAVE 2
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 0
	NOTE E_, 1
	NOTE A_, 1
	ATTEN 3
	NOTE A_, 1
	ATTEN 6
	NOTE A_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 3
	NOTE F#, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 6
	NOTE D_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 0
	REST 1
	DUTY 8
	ATTEN 4
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	OCTAVE 3
	NOTE G_, 3
	VIBRATO_OFF
	RELEASE $0B, 1
	NOTE F#, 2
	NOTE D_, 2
	ATTEN 0
	DUTY 4
	OCTAVE 2
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 3
	NOTE G_, 1
	ATTEN 0
	NOTE E_, 1
	NOTE A_, 1
	ATTEN 3
	NOTE A_, 1
	ATTEN 6
	NOTE A_, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 3
	NOTE A#, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 3
	NOTE A_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 6
	NOTE D_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	DUTY 8
	ATTEN 4
	REST 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE G_, 1
	VIBRATO $04, 0, 1
	NOTE A#, 1
	VIBRATO_OFF
	NOTE B_, 1
	ATTEN 0
	DUTY 4
	RELEASE $0B, 1
	SND_LOOP
	db $FF ; unreachable end

SndF5_Ch3:
	VOICE $07, 4, 2, 7, 1
	TRANSPOSE_UP 9
	REST 0
	REST $0E
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	SND_SEGNO
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	REST $0C
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	REST $0E
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	LOOP_START
	REST $0C
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	LOOP_END $02
	LOOP_START
	REST 1
	WAVE 6
	RELEASE $0F, 1
	ATTEN 0
	OCTAVE 3
	NOTE E_, 1
	NOTE C_HI, 1
	REST 1
	NOTE E_, 1
	REST 1
	NOTE E_, 1
	NOTE C_HI, 1
	LOOP_BREAK $FB
	REST 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE C_HI, 1
	WAVE 4
	RELEASE 7, 1
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	LOOP_END $02
	REST 6
	LOOP_START
	WAVE 4
	RELEASE $0C, 1
	OCTAVE 4
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	WAVE 6
	RELEASE $0F, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE C_HI, 1
	REST 1
	NOTE E_, 2
	NOTE E_, 1
	LOOP_BREAK $FB
	NOTE C_HI, 2
	NOTE D_, 1
	NOTE D_, 2
	OCTAVE 4
	NOTE E_, 1
	WAVE 4
	RELEASE 7, 1
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	LOOP_END $02
	NOTE E_, 1
	NOTE C_HI, 1
	REST 2
	NOTE E_, 1
	NOTE C_HI, 1
	WAVE 4
	RELEASE 7, 1
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	SND_LOOP

SndF5_Ch2:
	VOICE $07, 4, 13, 11, 1
	TRANSPOSE_DOWN 3
	REST 0
	REST 0
	SND_SEGNO
	OCTAVE 2
	NOTE B_, 1
	ATTEN 3
	NOTE B_, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 3
	NOTE B_, 1
	ATTEN 0
	OCTAVE 3
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	NOTE C#, 1
	ATTEN 3
	NOTE C#, 1
	ATTEN 0
	OCTAVE 2
	NOTE A_, 1
	ATTEN 3
	NOTE A_, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 3
	NOTE B_, 1
	ATTEN 6
	NOTE B_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 3
	NOTE A_, 1
	ATTEN 6
	NOTE A_, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 3
	NOTE B_, 1
	ATTEN 0
	REST 1
	RELEASE 0, 0
	DUTY 8
	ATTEN 4
	VIBRATO $04, 0, 2
	OCTAVE 3
	NOTE B_, 3
	VIBRATO_OFF
	RELEASE 9, 1
	NOTE A_, 2
	NOTE G_, 2
	DUTY 4
	ATTEN 0
	RELEASE $0B, 1
	OCTAVE 2
	NOTE B_, 1
	ATTEN 3
	NOTE B_, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 3
	NOTE B_, 1
	ATTEN 0
	OCTAVE 3
	NOTE D_, 1
	ATTEN 3
	NOTE D_, 1
	ATTEN 0
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 3
	NOTE F_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 0
	OCTAVE 2
	NOTE A_, 1
	ATTEN 3
	NOTE A_, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 3
	NOTE B_, 1
	ATTEN 6
	NOTE B_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 3
	NOTE A_, 1
	ATTEN 6
	NOTE A_, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 3
	NOTE B_, 1
	ATTEN 0
	DUTY 8
	REST 1
	ATTEN 4
	RELEASE 0, 0
	OCTAVE 2
	NOTE F#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	VIBRATO $04, 0, 1
	NOTE F#, 1
	VIBRATO_OFF
	NOTE G_, 1
	ATTEN 0
	DUTY 4
	RELEASE $0B, 1
	SND_LOOP

SndF5_Drm:
	LEN_UNIT $07
	SND_CALL SndF5_Drm_5A37
	SND_SEGNO
	SND_CALL SndF5_Drm_5A37
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	LOOP_BREAK $FB
	DRUM 8, 1
	LOOP_END $02
	DRUM 3, 1
	SND_CALL SndF5_Drm_5A37
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	LOOP_BREAK $FB
	DRUM 7, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $02
	DRUM 6, 1
	DRUM 4, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	SND_LOOP
SndF5_Drm_5A37:
	DRUM $0A, 2
	DRUM 7, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	SND_RET

SndF6_Ch2:
	VOICE $06, 0, 9, 9, 1
	LOOP_START
	SND_CALL SndF6_Ch2_6560
	REST 2
	LOOP_BREAK $FB
	NOTE G_, 2
	RELEASE 0, 0
	DUTY $0C
	ATTEN 1
	VIBRATO $01, 1, 2
	OCTAVE 4
	NOTE F#, 4
	VIBRATO_OFF
	ATTEN 0
	DUTY 0
	RELEASE 9, 1
	LOOP_END $02
	DUTY $0C
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	NOTE A_, 2
	VIBRATO_OFF
	NOTE G#, 2
	NOTE G_, 2
	LOOP_START
	VOICE $06, 4, 7, 0, 0
	OCTAVE 4
	NOTE C#, 3
	RELEASE $0B, 1
	NOTE D_, 3
	RELEASE 0, 0
	VIBRATO $01, 1, 4
	OCTAVE 3
	NOTE A_, 6
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE F#, 4
	VIBRATO_OFF
	NOTE F_, 3
	RELEASE $0B, 1
	NOTE F#, 3
	RELEASE 2, 1
	OCTAVE 3
	VIBRATO $01, 3, 5
	NOTE B_, 10
	RELEASE 0, 0
	VIBRATO_OFF
	OCTAVE 4
	NOTE D_, 4
	NOTE C#, 4
	NOTE C_, 3
	NOTE C#, 3
	LOOP_BREAK $FB
	NOTE E_, 2
	VIBRATO $04, 0, 2
	NOTE F#, 3
	RELEASE $0B, 1
	VIBRATO_OFF
	NOTE F_, 3
	RELEASE 0, 0
	OCTAVE 3
	VIBRATO $01, 3, 5
	RELEASE 2, 1
	NOTE A_, 10
	VIBRATO_OFF
	LOOP_END $02
	NOTE F#, 2
	NOTE E_, 3
	RELEASE $0B, 1
	NOTE D_, 3
	RELEASE 0, 0
	VIBRATO $01, 3, 5
	NOTE D_, 10
	SND_SEGNO
	ATTEN 1
	SND_CALL SndF6_Ch2_65F8
	ENVELOPE $0E
	VIBRATO $01, 3, 3
	NOTE E_, 10
	ENVELOPE $00
	VIBRATO_OFF
	RELEASE $0A, 1
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	ATTEN 0
	VOICE $06, 8, 7, 0, 0
	LOOP_START
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE F#, 3
	VIBRATO_OFF
	NOTE F_, 3
	NOTE F#, 2
	VIBRATO $01, 1, 2
	NOTE D_, 4
	RELEASE $0B, 1
	NOTE F_, 2
	NOTE F#, 2
	RELEASE 0, 0
	LOOP_END $02
	VOICE $06, 8, 8, 2, 2
	VIBRATO $01, 1, 3
	OCTAVE 3
	NOTE G_, 8
	VIBRATO_OFF
	RELEASE 0, 0
	NOTE D_, 2
	NOTE D#, 4
	NOTE G#, 2
	VIBRATO $01, 1, 3
	NOTE E_, 6
	RELEASE $0C, 1
	VIBRATO_OFF
	NOTE A_, 2
	RELEASE 0, 0
	OCTAVE 4
	NOTE C#, 3
	OCTAVE 3
	RELEASE 9, 2
	NOTE A#, 3
	NOTE F_, 2
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE F#, 3
	VIBRATO_OFF
	NOTE F_, 3
	NOTE F#, 2
	VIBRATO $01, 1, 2
	NOTE D_, 2
	RELEASE $0B, 1
	OCTAVE 5
	NOTE C#, 2
	RELEASE 0, 0
	OCTAVE 4
	NOTE G_, 2
	RELEASE $0B, 1
	OCTAVE 5
	NOTE C#, 2
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE F#, 3
	VIBRATO_OFF
	NOTE F_, 3
	NOTE F#, 2
	VIBRATO $01, 1, 2
	NOTE D_, 2
	RELEASE $0B, 1
	OCTAVE 5
	NOTE C#, 2
	NOTE C#, 2
	RELEASE 0, 0
	OCTAVE 4
	NOTE C#, 2
	VIBRATO $07, 0, 1
	OCTAVE 4
	NOTE D_, 6
	VIBRATO $01, 1, 2
	OCTAVE 3
	NOTE B_, 6
	VIBRATO_OFF
	NOTE G#, 4
	RELEASE $0A, 1
	DUTY 8
	OCTAVE 4
	NOTE A_, 1
	ATTEN 4
	NOTE A_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 2
	DUTY 8
	OCTAVE 4
	NOTE G#, 1
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	DUTY 8
	OCTAVE 4
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE E_, 2
	VOICE $06, 0, 9, 9, 1
	LOOP_START
	SND_CALL SndF6_Ch2_6560
	LOOP_BREAK $FB
	REST 2
	NOTE G_, 2
	RELEASE 0, 0
	DUTY $0C
	ATTEN 1
	VIBRATO $01, 1, 2
	OCTAVE 4
	NOTE F#, 4
	VIBRATO_OFF
	ATTEN 0
	DUTY 0
	RELEASE 9, 1
	LOOP_END $02
	VOICE $03, 4, 8, 15, 1
	DUTY_STEP 8, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	DUTY_STEP 0, 0
	VOICE $06, 8, 7, 0, 0
	SND_CALL SndF6_Ch2_65F8
	RELEASE 9, 1
	NOTE E_, 2
	ATTEN 2
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 0
	REST 4
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	NOTE G_, 8
	VIBRATO $01, 5, 4
	ENVELOPE $09
	NOTE G_, 0
	ENVELOPE $00
	VIBRATO_OFF
	VOICE $06, 8, 8, 0, 0
	TRANSPOSE_DOWN $0B
	LOOP_START
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE A_, 3
	VIBRATO_OFF
	NOTE G#, 3
	NOTE A_, 2
	NOTE F#, 2
	VIBRATO $04, 0, 1
	OCTAVE 5
	NOTE F#, 2
	RELEASE $0B, 1
	VIBRATO_OFF
	NOTE F_, 2
	NOTE F#, 2
	LOOP_END $02
	RELEASE 0, 0
	VIBRATO $04, 0, 1
	OCTAVE 4
	NOTE G_, 2
	RELEASE 2, 2
	VIBRATO $01, 1, 3
	NOTE G_, 6
	RELEASE 0, 0
	VIBRATO_OFF
	NOTE D_, 2
	NOTE D#, 4
	NOTE G#, 2
	NOTE E_, 6
	RELEASE $0C, 1
	NOTE A_, 2
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	OCTAVE 5
	NOTE C#, 3
	VIBRATO_OFF
	OCTAVE 4
	RELEASE 9, 2
	NOTE A#, 3
	NOTE F_, 2
	VIBRATO $04, 0, 2
	RELEASE 0, 0
	OCTAVE 4
	NOTE A_, 3
	VIBRATO_OFF
	NOTE G#, 3
	NOTE A_, 2
	NOTE F#, 2
	RELEASE $0B, 1
	ATTEN 2
	OCTAVE 6
	NOTE C#, 2
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 4
	NOTE A_, 2
	RELEASE $0B, 1
	ATTEN 2
	OCTAVE 6
	NOTE C#, 2
	ATTEN 0
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE A_, 3
	VIBRATO_OFF
	NOTE G#, 3
	NOTE A_, 2
	NOTE F#, 2
	RELEASE $0B, 1
	ATTEN 2
	OCTAVE 6
	NOTE C#, 2
	NOTE C#, 2
	ATTEN 0
	RELEASE 0, 0
	DUTY $0B
	OCTAVE 5
	NOTE C#, 2
	VIBRATO $04, 0, 1
	OCTAVE 5
	NOTE D_, 6
	VIBRATO $01, 1, 2
	OCTAVE 4
	NOTE B_, 6
	VIBRATO_OFF
	NOTE G#, 4
	TRANSPOSE_DOWN 0
	VIBRATO $01, 4, 4
	OCTAVE 3
	NOTE G_, 8
	NOTE F_, 8
	VIBRATO_OFF
	VOICE $06, 0, 9, 9, 1
	TRANSPOSE_UP 1
	LOOP_START
	SND_CALL SndF6_Ch2_6560
	LOOP_BREAK $FB
	REST 2
	NOTE G_, 2
	RELEASE 0, 0
	DUTY $0C
	ATTEN 1
	VIBRATO $01, 1, 2
	OCTAVE 4
	NOTE F#, 4
	VIBRATO_OFF
	ATTEN 0
	DUTY 0
	RELEASE 9, 1
	LOOP_END $02
	VOICE $03, 4, 8, 15, 1
	DUTY_STEP 8, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	TRANSPOSE_UP 0
	DUTY_STEP 0, 0
	VOICE $06, 8, 6, 0, 0
	VIBRATO $01, 4, 3
	OCTAVE 4
	NOTE D#, 0
	NOTE F_, 0
	VIBRATO $01, 4, 3
	NOTE G_, 0
	VIBRATO $01, 0, 3
	NOTE G_, 0
	SND_END

SndF6_Ch1:
	VOICE $06, 8, 15, 0, 0
	SND_CALL SndF6_Ch1_6589
	VIBRATO $01, 3, 4
	OCTAVE 2
	NOTE D_, 4
	ATTEN 0
	VIBRATO_OFF
	NOTE C#, 2
	RELEASE 9, 3
	NOTE D_, 2
	RELEASE 0, 0
	ATTEN 5
	NOTE D_, 2
	ATTEN 0
	VIBRATO $04, 0, 2
	OCTAVE 1
	NOTE B_, 4
	VIBRATO_OFF
	OCTAVE 2
	NOTE C#, 2
	RELEASE $0B, 1
	OCTAVE 1
	NOTE A_, 2
	RELEASE 0, 0
	NOTE A_, 2
	RELEASE $0B, 1
	NOTE B_, 2
	RELEASE 9, 1
	NOTE B_, 2
	RELEASE 0, 0
	OCTAVE 2
	NOTE C#, 2
	RELEASE 0, 0
	NOTE D_, 2
	NOTE E_, 2
	NOTE C#, 2
	LOOP2_START
	LOOP_START
	VOICE $06, 8, 8, 10, 1
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	DUTY 0
	NOTE F#, 2
	NOTE F#, 2
	LOOP_END $02
	DUTY 8
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	DUTY 0
	NOTE F#, 2
	LOOP_START
	DUTY 8
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 3
	DUTY 0
	NOTE F#, 2
	NOTE F#, 2
	LOOP_END $02
	DUTY 8
	OCTAVE 3
	NOTE C_, 2
	DUTY 0
	NOTE F_, 2
	DUTY 8
	OCTAVE 2
	NOTE B_, 2
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	DUTY 8
	OCTAVE 2
	NOTE A#, 2
	DUTY 0
	OCTAVE 3
	NOTE G#, 2
	NOTE G#, 2
	DUTY 8
	OCTAVE 2
	NOTE G_, 2
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 8
	OCTAVE 2
	NOTE A_, 2
	DUTY 0
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 2
	DUTY 8
	LOOP_BREAK $FC
	NOTE C#, 2
	DUTY 0
	NOTE F#, 2
	NOTE F#, 2
	DUTY 8
	NOTE E_, 2
	DUTY 0
	NOTE F_, 2
	LOOP2_END $02
	OCTAVE 2
	NOTE A_, 2
	DUTY 0
	OCTAVE 3
	NOTE A_, 2
	NOTE G#, 2
	DUTY 8
	OCTAVE 2
	NOTE A_, 2
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	VOICE $06, 8, 7, 0, 0
	ENVELOPE $0E
	VIBRATO $01, 2, 2
	OCTAVE 4
	NOTE C#, 8
	OCTAVE 3
	NOTE A#, 8
	ENVELOPE $00
	NOTE B_, 8
	VIBRATO_OFF
	OCTAVE 4
	NOTE D_, 4
	RELEASE $0A, 1
	OCTAVE 3
	NOTE F#, 1
	ATTEN 3
	NOTE F#, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 3
	NOTE F#, 1
	ATTEN 0
	RELEASE 0, 0
	ENVELOPE $0E
	VIBRATO $01, 2, 2
	NOTE B_, 8
	NOTE G#, 8
	NOTE A_, 8
	NOTE A#, 8
	ENVELOPE $00
	VIBRATO_OFF
	VOICE $06, 8, 10, 0, 0
	SND_CALL SndF6_Ch1_6649
	RELEASE $0A, 1
	ATTEN 3
	LOOP_START
	DUTY 8
	OCTAVE 2
	NOTE G_, 2
	DUTY 0
	NOTE C_HI, 2
	LOOP_END $02
	LOOP_START
	DUTY 8
	OCTAVE 2
	NOTE A#, 2
	DUTY 0
	OCTAVE 3
	NOTE B_, 2
	LOOP_END $02
	DUTY_STEP 0, 0
	ATTEN 0
	VOICE $06, 8, 15, 9, 1
	OCTAVE 2
	NOTE D_, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 3
	NOTE C_HI, 2
	NOTE C_HI, 2
	RELEASE 9, 1
	DUTY 8
	ATTEN 0
	NOTE D_, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 3
	NOTE C_HI, 2
	RELEASE 0, 0
	DUTY 8
	OCTAVE 4
	NOTE F#, 2
	RELEASE 9, 1
	ATTEN 0
	OCTAVE 2
	NOTE C#, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 3
	NOTE C_HI, 2
	ATTEN 0
	RELEASE 9, 1
	DUTY 8
	OCTAVE 1
	NOTE B_, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 3
	NOTE C_HI, 2
	NOTE C_HI, 2
	RELEASE 9, 1
	DUTY 8
	ATTEN 0
	NOTE B_, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 3
	NOTE C_HI, 2
	RELEASE 0, 0
	DUTY 8
	OCTAVE 4
	NOTE F#, 2
	RELEASE 9, 1
	ATTEN 0
	OCTAVE 1
	NOTE A_, 2
	DUTY 0
	RELEASE 9, 1
	ATTEN 3
	NOTE C_HI, 2
	LOOP_START
	ATTEN 0
	RELEASE 9, 1
	DUTY 8
	OCTAVE 1
	NOTE G_, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 3
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 2
	LOOP_END $02
	ATTEN 0
	RELEASE 9, 1
	DUTY 8
	OCTAVE 1
	NOTE G#, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 3
	NOTE C_HI, 2
	ATTEN 0
	RELEASE 9, 1
	DUTY 8
	NOTE A_, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 3
	NOTE C_HI, 2
	NOTE C_HI, 2
	ATTEN 0
	RELEASE 9, 1
	DUTY 8
	OCTAVE 2
	NOTE C#, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 3
	NOTE A_, 2
	NOTE A_, 2
	ATTEN 0
	RELEASE 9, 1
	DUTY 8
	OCTAVE 1
	NOTE A_, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 3
	OCTAVE 3
	NOTE C#, 2
	SND_CALL SndF6_Ch1_66B4
	ATTEN 0
	RELEASE 9, 1
	DUTY 8
	OCTAVE 1
	NOTE A_, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 3
	NOTE C_HI, 2
	NOTE C_HI, 2
	ATTEN 0
	RELEASE 9, 1
	DUTY 8
	OCTAVE 2
	NOTE C#, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 3
	NOTE A_, 2
	NOTE A_, 2
	ATTEN 0
	RELEASE 9, 1
	DUTY 8
	NOTE A_, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 3
	OCTAVE 3
	NOTE C#, 2
	VOICE $06, 8, 15, 0, 0
	SND_CALL SndF6_Ch1_6589
	VIBRATO $01, 3, 4
	OCTAVE 2
	NOTE D_, 4
	ATTEN 0
	VIBRATO_OFF
	NOTE C#, 2
	RELEASE 9, 3
	NOTE D_, 2
	RELEASE 0, 0
	ATTEN 5
	NOTE D_, 2
	ATTEN 0
	VIBRATO $04, 0, 2
	OCTAVE 1
	NOTE B_, 4
	VIBRATO_OFF
	OCTAVE 2
	NOTE C#, 2
	RELEASE $0C, 1
	OCTAVE 2
	NOTE D_, 2
	RELEASE 0, 0
	NOTE D_, 2
	ATTEN 0
	NOTE E_, 2
	RELEASE 9, 3
	NOTE D_, 2
	RELEASE 0, 0
	RELEASE 9, 1
	NOTE E_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C#, 2
	VOICE $06, 8, 7, 0, 0
	VIBRATO $01, 4, 3
	ENVELOPE $0E
	OCTAVE 3
	NOTE E_, 12
	VIBRATO_OFF
	ENVELOPE $00
	OCTAVE 4
	NOTE C#, 4
	VIBRATO $01, 3, 3
	DETUNE $FF
	OCTAVE 3
	NOTE B_, 12
	DETUNE $00
	VIBRATO_OFF
	NOTE A_, 4
	VIBRATO $01, 2, 2
	ENVELOPE $0E
	NOTE B_, 8
	VIBRATO_OFF
	ENVELOPE $00
	NOTE E_, 4
	VIBRATO $04, 0, 2
	NOTE G#, 4
	VIBRATO $01, 3, 2
	ENVELOPE $0E
	NOTE G_, 8
	ENVELOPE $00
	NOTE F#, 8
	VIBRATO_OFF
	VOICE $06, 8, 10, 0, 0
	SND_CALL SndF6_Ch1_6649
	RELEASE 9, 1
	ATTEN 3
	DUTY 8
	OCTAVE 3
	NOTE G_, 4
	REST 4
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	NOTE B_, 8
	ATTEN 0
	VIBRATO $01, 5, 4
	ENVELOPE $09
	NOTE B_, 0
	ENVELOPE $00
	VIBRATO_OFF
	VOICE $06, 8, 15, 9, 1
	TRANSPOSE_UP 1
	SND_CALL SndF6_Ch1_66B4
	TRANSPOSE_UP 0
	ATTEN 0
	RELEASE 9, 1
	DUTY 8
	OCTAVE 1
	NOTE A#, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 3
	NOTE C_HI, 2
	NOTE C_HI, 2
	ATTEN 0
	RELEASE 9, 1
	DUTY 8
	OCTAVE 2
	NOTE D_, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 3
	NOTE A#, 2
	NOTE A#, 2
	ATTEN 0
	RELEASE 9, 1
	DUTY 8
	OCTAVE 1
	NOTE A#, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 3
	OCTAVE 3
	NOTE D_, 2
	TRANSPOSE_UP 1
	SND_CALL SndF6_Ch1_66B4
	TRANSPOSE_UP 0
	ATTEN 0
	RELEASE 9, 1
	DUTY 8
	OCTAVE 1
	NOTE A#, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 3
	NOTE C_HI, 2
	NOTE C_HI, 2
	ATTEN 0
	RELEASE 9, 1
	DUTY 8
	OCTAVE 2
	NOTE D_, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 3
	NOTE A#, 2
	NOTE A#, 2
	ATTEN 0
	RELEASE 9, 1
	DUTY 8
	NOTE A#, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 3
	OCTAVE 3
	NOTE D_, 2
	VOICE $06, 8, 15, 0, 0
	TRANSPOSE_UP 1
	SND_CALL SndF6_Ch1_6589
	VIBRATO $01, 3, 4
	OCTAVE 2
	NOTE D_, 4
	ATTEN 0
	VIBRATO_OFF
	NOTE C#, 2
	RELEASE 9, 3
	NOTE D_, 2
	RELEASE 0, 0
	ATTEN 5
	NOTE D_, 2
	ATTEN 0
	VIBRATO $04, 0, 2
	OCTAVE 1
	NOTE B_, 4
	VIBRATO_OFF
	OCTAVE 2
	NOTE C#, 2
	RELEASE $0C, 1
	OCTAVE 2
	NOTE D_, 2
	RELEASE 0, 0
	NOTE D_, 2
	ATTEN 0
	NOTE E_, 2
	RELEASE 9, 3
	NOTE D_, 2
	RELEASE 0, 0
	RELEASE 9, 1
	NOTE E_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C#, 2
	TRANSPOSE_UP 0
	VOICE $06, 8, 7, 0, 0
	VIBRATO $01, 4, 3
	OCTAVE 3
	NOTE C_, 0
	NOTE D_, 0
	VIBRATO $01, 4, 3
	NOTE E_, 0
	VIBRATO $01, 0, 3
	NOTE E_, 0
	SND_END

SndF6_Ch3:
	VOICE $06, 4, 2, 9, 1
	LOOP_START
	SND_CALL SndF6_Ch3_65BC
	LOOP_BREAK $FB
	DETUNE $FE
	WAVE $0B
	OCTAVE 4
	NOTE D_, 1
	DETUNE $00
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	WAVE 4
	OCTAVE 3
	NOTE B_, 2
	WAVE $0B
	OCTAVE 5
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	OCTAVE 4
	NOTE C#, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	LOOP_END $02
	WAVE $0B
	OCTAVE 5
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	WAVE 4
	RELEASE 0, 0
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C#, 2
	LOOP2_START
	LOOP_START
	VOICE $06, 1, 2, 10, 1
	OCTAVE 3
	NOTE D_, 2
	WAVE 4
	NOTE C_HI, 2
	NOTE C_HI, 2
	LOOP_END $02
	WAVE 1
	OCTAVE 3
	NOTE C#, 2
	WAVE 4
	OCTAVE 4
	NOTE D_, 2
	LOOP_START
	WAVE 1
	OCTAVE 2
	NOTE B_, 2
	WAVE 4
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	LOOP_END $02
	WAVE 1
	OCTAVE 3
	NOTE F_, 2
	WAVE 4
	OCTAVE 4
	NOTE C_, 2
	WAVE 1
	OCTAVE 3
	NOTE E_, 2
	WAVE 4
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 2
	WAVE 1
	OCTAVE 2
	NOTE A_, 2
	WAVE 4
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 2
	WAVE 1
	OCTAVE 3
	NOTE C#, 2
	WAVE 4
	OCTAVE 4
	NOTE E_, 2
	WAVE 1
	OCTAVE 3
	NOTE D_, 2
	WAVE 4
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	WAVE 1
	OCTAVE 3
	LOOP_BREAK $FC
	NOTE C_, 2
	WAVE 4
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	WAVE 1
	OCTAVE 3
	NOTE C#, 2
	WAVE 4
	OCTAVE 4
	NOTE C#, 2
	LOOP2_END $02
	NOTE D_, 2
	WAVE 4
	OCTAVE 4
	NOTE F#, 2
	NOTE E_, 2
	WAVE 1
	OCTAVE 3
	NOTE D_, 2
	WAVE 4
	OCTAVE 4
	NOTE D#, 2
	VOICE $06, 1, 2, 9, 1
	OCTAVE 2
	NOTE A_, 2
	WAVE $0B
	OCTAVE 3
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	OCTAVE 4
	NOTE C#, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 2
	WAVE $0B
	OCTAVE 4
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	NOTE C#, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE A#, 2
	WAVE $0B
	OCTAVE 3
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE B_, 2
	WAVE $0B
	OCTAVE 3
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE B_, 2
	WAVE $0B
	OCTAVE 3
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 0
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 2
	WAVE $0B
	OCTAVE 4
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE G_, 2
	WAVE $0B
	OCTAVE 3
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE G_, 2
	WAVE $0B
	OCTAVE 3
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 0
	OCTAVE 4
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE G#, 2
	WAVE $0B
	OCTAVE 3
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 2
	WAVE $0B
	OCTAVE 3
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	OCTAVE 4
	NOTE C#, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 2
	WAVE $0B
	OCTAVE 4
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE A#, 2
	WAVE $0B
	OCTAVE 4
	NOTE E_, 1
	ATTEN 1
	NOTE E_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE B_, 2
	WAVE $0B
	OCTAVE 3
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE B_, 2
	WAVE $0B
	OCTAVE 3
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE F#, 2
	WAVE $0B
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE F#, 2
	WAVE $0B
	OCTAVE 3
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 2
	WAVE $0B
	OCTAVE 3
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE F#, 2
	WAVE $0B
	OCTAVE 4
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE A#, 2
	WAVE $0B
	OCTAVE 4
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 1
	NOTE F_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE A#, 2
	WAVE $0B
	OCTAVE 3
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	OCTAVE 4
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE F_, 2
	WAVE $0B
	OCTAVE 4
	NOTE F_, 1
	ATTEN 1
	NOTE F_, 1
	ATTEN 0
	LOOP_START
	WAVE 1
	OCTAVE 3
	NOTE C_, 2
	WAVE 4
	NOTE C_HI, 2
	LOOP_END $02
	LOOP_START
	WAVE 1
	OCTAVE 3
	NOTE C#, 2
	WAVE 4
	NOTE C_HI, 2
	LOOP_END $02
	LOOP_START
	ATTEN 0
	WAVE 5
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE A_, 3
	VIBRATO_OFF
	NOTE G#, 3
	NOTE A_, 2
	NOTE F#, 2
	INSTRUMENT $03
	ATTEN 1
	VIBRATO $04, 0, 1
	OCTAVE 5
	NOTE A_, 2
	RELEASE $0B, 1
	VIBRATO_OFF
	NOTE G#, 2
	NOTE A_, 2
	INSTRUMENT $00
	LOOP_END $02
	INSTRUMENT $03
	RELEASE 0, 0
	VIBRATO $04, 0, 1
	OCTAVE 5
	NOTE A_, 6
	VIBRATO_OFF
	NOTE G_, 6
	OCTAVE 4
	NOTE B_, 4
	OCTAVE 5
	NOTE D_, 6
	RELEASE $0C, 1
	NOTE E_, 2
	VIBRATO $04, 0, 1
	RELEASE 0, 0
	NOTE E_, 3
	RELEASE 9, 2
	VIBRATO_OFF
	INSTRUMENT $00
	WAVE 1
	NOTE C#, 3
	OCTAVE 4
	NOTE A_, 2
	VOICE $06, 5, 2, 0, 0
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE A_, 3
	VIBRATO_OFF
	NOTE G#, 3
	NOTE A_, 2
	NOTE F#, 2
	INSTRUMENT $03
	ATTEN 1
	RELEASE $0B, 1
	OCTAVE 6
	NOTE D_, 2
	INSTRUMENT $00
	ATTEN 0
	WAVE 5
	RELEASE 0, 0
	OCTAVE 4
	NOTE A_, 2
	INSTRUMENT $03
	ATTEN 1
	RELEASE $0B, 1
	OCTAVE 6
	NOTE D_, 2
	INSTRUMENT $00
	WAVE 5
	RELEASE 0, 0
	ATTEN 0
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE A_, 3
	VIBRATO_OFF
	NOTE G#, 3
	NOTE A_, 2
	NOTE F#, 2
	INSTRUMENT $03
	ATTEN 1
	RELEASE $0B, 1
	OCTAVE 6
	NOTE D_, 2
	NOTE D_, 2
	INSTRUMENT $00
	ATTEN 0
	WAVE 5
	RELEASE 0, 0
	INSTRUMENT $03
	ATTEN 1
	OCTAVE 5
	NOTE G_, 2
	VIBRATO $04, 0, 1
	NOTE A_, 6
	VIBRATO_OFF
	NOTE G_, 6
	OCTAVE 4
	NOTE B_, 4
	OCTAVE 5
	NOTE D_, 6
	RELEASE $0C, 1
	NOTE C#, 2
	RELEASE 0, 0
	NOTE C#, 8
	INSTRUMENT $00
	ATTEN 0
	VOICE $06, 4, 2, 9, 1
	LOOP_START
	SND_CALL SndF6_Ch3_65BC
	DETUNE $FE
	WAVE $0B
	OCTAVE 4
	NOTE D_, 1
	DETUNE $00
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	WAVE 4
	OCTAVE 3
	NOTE B_, 2
	WAVE $0B
	OCTAVE 5
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	OCTAVE 4
	NOTE C#, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	LOOP_END $02
	VOICE $06, 4, 2, 0, 0
	VIBRATO $01, 3, 3
	OCTAVE 3
	NOTE A_, 8
	NOTE A#, 8
	NOTE B_, 8
	NOTE A_, 8
	NOTE G_, 8
	NOTE G#, 8
	NOTE A_, 8
	NOTE A#, 8
	NOTE B_, 0
	NOTE A_, 10
	WAVE 1
	VIBRATO_OFF
	NOTE D_, 2
	NOTE C#, 2
	NOTE C_, 2
	VIBRATO $01, 3, 4
	OCTAVE 2
	NOTE A#, 0
	VIBRATO_OFF
	RELEASE 9, 1
	OCTAVE 3
	NOTE C_, 4
	REST 4
	VIBRATO $01, 3, 2
	RELEASE 0, 0
	NOTE C#, 8
	VIBRATO_OFF
	RELEASE $0B, 1
	WAVE 6
	OCTAVE 2
	PAN_BOTH 0
	NOTE A_, 1
	PAN_LEFT 0
	NOTE C_HI, 1
	PAN_BOTH 0
	NOTE B_, 1
	PAN_RIGHT 0
	NOTE C_HI, 1
	OCTAVE 3
	PAN_BOTH 0
	NOTE C#, 1
	PAN_LEFT 0
	NOTE C_HI, 1
	PAN_BOTH 0
	NOTE D#, 1
	PAN_RIGHT 0
	NOTE C_HI, 1
	PAN_BOTH 0
	NOTE F_, 1
	PAN_LEFT 0
	NOTE C_HI, 1
	PAN_BOTH 0
	NOTE G_, 1
	PAN_RIGHT 0
	NOTE C_HI, 1
	PAN_BOTH 0
	NOTE A_, 1
	PAN_LEFT 0
	NOTE C_HI, 1
	PAN_BOTH 0
	NOTE B_, 1
	PAN_RIGHT 0
	NOTE C_HI, 1
	VOICE $06, 1, 4, 0, 0
	TRANSPOSE_UP $0D
	INSTRUMENT $03
	PAN_BOTH 0
	LOOP_START
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE F#, 3
	VIBRATO_OFF
	NOTE F_, 3
	NOTE F#, 2
	NOTE D_, 2
	VIBRATO $04, 0, 1
	NOTE A_, 2
	RELEASE $0B, 1
	VIBRATO_OFF
	NOTE G#, 2
	NOTE A_, 2
	RELEASE 0, 0
	LOOP_END $02
	VIBRATO $04, 0, 1
	OCTAVE 4
	NOTE A_, 6
	VIBRATO_OFF
	NOTE G_, 6
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 6
	RELEASE $0C, 1
	NOTE E_, 2
	VIBRATO $04, 0, 1
	RELEASE 0, 0
	NOTE E_, 3
	RELEASE 9, 2
	VIBRATO_OFF
	INSTRUMENT $00
	WAVE 1
	NOTE C#, 3
	OCTAVE 3
	NOTE A_, 2
	RELEASE 0, 0
	INSTRUMENT $03
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE F#, 3
	VIBRATO_OFF
	NOTE F_, 3
	NOTE F#, 2
	NOTE D_, 2
	RELEASE $0B, 1
	OCTAVE 5
	NOTE D_, 2
	RELEASE 0, 0
	OCTAVE 4
	NOTE G_, 2
	RELEASE $0B, 1
	OCTAVE 5
	NOTE D_, 2
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE F#, 3
	VIBRATO_OFF
	NOTE F_, 3
	NOTE F#, 2
	NOTE D_, 2
	RELEASE $0B, 1
	OCTAVE 5
	NOTE D_, 2
	NOTE D_, 2
	RELEASE 0, 0
	OCTAVE 4
	NOTE G_, 2
	VIBRATO $04, 0, 1
	NOTE A_, 6
	VIBRATO_OFF
	NOTE G_, 6
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 6
	RELEASE $0C, 1
	NOTE C#, 2
	RELEASE 0, 0
	NOTE C#, 8
	INSTRUMENT $00
	VOICE $06, 4, 2, 9, 1
	TRANSPOSE_UP 1
	LOOP_START
	SND_CALL SndF6_Ch3_65BC
	DETUNE $FE
	WAVE $0B
	OCTAVE 4
	NOTE D_, 1
	DETUNE $00
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	WAVE 4
	OCTAVE 3
	NOTE B_, 2
	WAVE $0B
	OCTAVE 5
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	OCTAVE 4
	NOTE C#, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	LOOP_END $02
	VOICE $06, 1, 2, 9, 1
	TRANSPOSE_UP 0
	OCTAVE 2
	NOTE G#, 2
	WAVE $0B
	OCTAVE 3
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	OCTAVE 4
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE G#, 2
	WAVE $0B
	OCTAVE 4
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 2
	WAVE $0B
	OCTAVE 3
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE A#, 2
	WAVE $0B
	OCTAVE 3
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	OCTAVE 4
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE A#, 2
	WAVE $0B
	OCTAVE 4
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 2
	WAVE $0B
	OCTAVE 3
	NOTE A#, 1
	ATTEN 1
	NOTE A#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 2
	WAVE $0B
	OCTAVE 4
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	OCTAVE 4
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 2
	WAVE $0B
	OCTAVE 5
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	OCTAVE 4
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE G_, 2
	WAVE $0B
	OCTAVE 4
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	RELEASE 0, 0
	VIBRATO $01, 4, 6
	WAVE 1
	OCTAVE 2
	NOTE C_, 0
	SND_END

SndF6_Drm:
	LEN_UNIT $06
	SND_CALL SndF6_Drm_670E
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 2
	LOOP_START
	DRUM 3, 1
	DRUM 8, 1
	LOOP_END $06
	SND_CALL SndF6_Drm_670E
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 1
	LOOP_START
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 1
	LOOP_END $02
	DRUM 3, 1
	SND_CALL SndF6_Drm_670E
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 3, 1
	DRUM 8, 1
	LOOP_END $04
	LOOP_START
	DRUM $0C, 2
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	LOOP_BREAK $FB
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_END $02
	DRUM 3, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	SND_CALL SndF6_Drm_670E
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 2
	LOOP_END $04
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0C, 2
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 2
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_END $04
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM $0C, 2
	DRUM 7, 2
	DRUM 7, 4
	DRUM 7, 2
	DRUM 8, 4
	DRUM 7, 2
	DRUM 7, 4
	DRUM 8, 4
	DRUM 7, 3
	DRUM 7, 3
	DRUM 8, 2
	DRUM 7, 4
	DRUM 8, 4
	DRUM 7, 2
	DRUM 8, 4
	DRUM 7, 2
	DRUM 7, 4
	DRUM 7, 4
	DRUM 7, 3
	DRUM 8, 3
	DRUM 8, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM $0A, 4
	DRUM 8, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM $0A, 4
	DRUM 9, 3
	DRUM 8, 1
	DRUM 9, 2
	DRUM 7, 2
	DRUM 9, 4
	DRUM 7, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 8, 4
	DRUM 7, 2
	DRUM 9, 4
	DRUM $0A, 4
	DRUM $0C, 8
	DRUM 9, 6
	DRUM 9, 2
	LOOP_START
	DRUM 3, 1
	LOOP_END $08
	SND_CALL SndF6_Drm_670E
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	LOOP_BREAK $FB
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 2
	LOOP_END $05
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 5, 1
	SND_CALL SndF6_Drm_670E
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 3, 1
	LOOP_END $08
	DRUM $0C, 2
	DRUM 9, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 2
	DRUM 3, 1
	DRUM 7, 1
	DRUM $0A, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0C, 4
	DRUM $0C, 1
	SND_END
SndF6_Ch2_6560:
	OCTAVE 3
	NOTE F#, 2
	DUTY $0C
	RELEASE 0, 0
	ATTEN 1
	OCTAVE 4
	NOTE C#, 2
	RELEASE $0A, 1
	VIBRATO $04, 0, 1
	NOTE D_, 2
	ATTEN 0
	VIBRATO_OFF
	DUTY 0
	OCTAVE 3
	NOTE G_, 2
	RELEASE 0, 0
	REST 2
	DUTY $0C
	ATTEN 1
	VIBRATO $01, 5, 3
	NOTE A_, 12
	ATTEN 0
	VIBRATO_OFF
	RELEASE 9, 1
	DUTY 0
	NOTE G_, 2
	SND_RET
SndF6_Ch1_6589:
	VIBRATO $01, 3, 4
	OCTAVE 2
	NOTE D_, 4
	ATTEN 0
	VIBRATO_OFF
	NOTE C#, 2
	RELEASE 9, 3
	NOTE D_, 2
	RELEASE 0, 0
	ATTEN 5
	NOTE D_, 2
	ATTEN 0
	VIBRATO $04, 0, 2
	OCTAVE 1
	NOTE B_, 4
	VIBRATO_OFF
	OCTAVE 2
	NOTE C#, 2
	RELEASE $0C, 1
	OCTAVE 2
	NOTE D_, 2
	RELEASE 0, 0
	NOTE D_, 2
	ATTEN 0
	NOTE E_, 2
	RELEASE 9, 3
	NOTE D_, 2
	RELEASE 0, 0
	ATTEN 5
	NOTE D_, 2
	ATTEN 0
	VIBRATO $04, 0, 2
	NOTE D_, 4
	VIBRATO_OFF
	NOTE E_, 2
	SND_RET
SndF6_Ch3_65BC:
	WAVE 4
	OCTAVE 3
	NOTE A_, 2
	WAVE $0B
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	WAVE 4
	OCTAVE 3
	NOTE B_, 2
	WAVE $0B
	OCTAVE 5
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	OCTAVE 5
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	WAVE 4
	OCTAVE 4
	NOTE C#, 2
	WAVE $0B
	NOTE C#, 1
	ATTEN 1
	NOTE C#, 1
	ATTEN 0
	OCTAVE 5
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	WAVE 4
	OCTAVE 3
	NOTE B_, 2
	SND_RET
SndF6_Ch2_65F8:
	DUTY 8
	ENVELOPE $0E
	VIBRATO $01, 2, 2
	OCTAVE 4
	NOTE A_, 8
	RELEASE 2, 1
	NOTE G_, 8
	RELEASE 0, 0
	ENVELOPE $00
	VIBRATO_SEMI 4
	NOTE F#, 3
	VIBRATO_OFF
	NOTE F#, 3
	NOTE F_, 2
	VIBRATO $01, 2, 2
	RELEASE 2, 1
	ENVELOPE $0E
	NOTE F#, 8
	RELEASE 0, 0
	ENVELOPE $00
	OCTAVE 4
	NOTE E_, 6
	NOTE D_, 6
	RELEASE 8, 2
	NOTE E_, 4
	RELEASE 0, 0
	VIBRATO_SEMI 4
	NOTE C#, 3
	VIBRATO_OFF
	NOTE C#, 3
	NOTE C_, 2
	VIBRATO $01, 3, 2
	NOTE C#, 8
	LOOP_START
	RELEASE 8, 1
	NOTE D_, 2
	REST 4
	RELEASE 0, 0
	ENVELOPE $0E
	NOTE A_, 10
	ENVELOPE $00
	LOOP_END $02
	RELEASE 8, 1
	NOTE D_, 2
	REST 4
	RELEASE 0, 0
	VIBRATO_SEMI 4
	NOTE E_, 6
	VIBRATO_OFF
	NOTE A_, 4
	SND_RET
SndF6_Ch1_6649:
	ATTEN 3
	NOTE B_, 2
	DUTY 0
	AUTOPAN 0
	ATTEN 0
	DUTY_STEP 8, 1
	RELEASE $0D, 2
	NOTE F#, 2
	NOTE C_HI, 2
	DUTY 8
	RELEASE 0, 0
	PAN_BOTH 0
	ATTEN 3
	OCTAVE 4
	NOTE D_, 6
	OCTAVE 3
	AUTOPAN 0
	ATTEN 0
	DUTY 0
	RELEASE $0D, 2
	NOTE F#, 2
	NOTE C_HI, 2
	PAN_BOTH 0
	ATTEN 3
	DUTY 8
	RELEASE 0, 0
	NOTE A_, 2
	DUTY 0
	AUTOPAN 0
	ATTEN 0
	RELEASE $0D, 2
	NOTE F#, 2
	NOTE C_HI, 2
	DUTY 8
	RELEASE 0, 0
	PAN_BOTH 0
	ATTEN 3
	OCTAVE 4
	NOTE D_, 6
	OCTAVE 3
	AUTOPAN 0
	ATTEN 0
	DUTY 0
	RELEASE $0D, 2
	NOTE F#, 2
	NOTE C_HI, 2
	PAN_BOTH 0
	ATTEN 3
	DUTY 8
	RELEASE 0, 0
	NOTE A_, 2
	DUTY 0
	ATTEN 0
	RELEASE $0D, 2
	AUTOPAN 0
	NOTE A_, 2
	NOTE C_HI, 2
	DUTY 8
	RELEASE 0, 0
	PAN_BOTH 0
	ATTEN 3
	NOTE A_, 4
	DUTY 0
	ATTEN 0
	RELEASE $0D, 2
	AUTOPAN 0
	NOTE F_, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE D_, 2
	PAN_BOTH 0
	SND_RET
SndF6_Ch1_66B4:
	LOOP_START
	ATTEN 0
	RELEASE 9, 1
	DUTY 8
	OCTAVE 2
	NOTE D_, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 5
	NOTE C_HI, 2
	NOTE C_HI, 2
	LOOP_END $02
	ATTEN 0
	RELEASE 9, 1
	DUTY 8
	NOTE C#, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 5
	NOTE C_HI, 2
	LOOP_START
	ATTEN 0
	RELEASE 9, 1
	DUTY 8
	OCTAVE 1
	NOTE B_, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 5
	NOTE C_HI, 2
	NOTE C_HI, 2
	LOOP_END $02
	ATTEN 0
	RELEASE 9, 1
	DUTY 8
	NOTE A_, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 5
	NOTE C_HI, 2
	LOOP_START
	ATTEN 0
	RELEASE 9, 1
	DUTY 8
	OCTAVE 1
	NOTE G_, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 5
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 2
	LOOP_END $02
	ATTEN 0
	RELEASE 9, 1
	DUTY 8
	OCTAVE 1
	NOTE G#, 2
	DUTY 0
	RELEASE $0D, 1
	ATTEN 5
	NOTE C_HI, 2
	SND_RET
SndF6_Drm_670E:
	DRUM $0C, 2
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 2
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 2
	LOOP_END $02
	SND_RET
