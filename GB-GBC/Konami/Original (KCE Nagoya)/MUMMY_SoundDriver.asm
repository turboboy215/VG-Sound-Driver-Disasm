; ==========================================================================
; The Mummy (E) (M3) - Konami sound driver (ROM0, banks $0C-$0F)
; Byte-exact RGBDS disassembly of the driver code and all sound data. Cyborg Kuro-chan's driver with
; the track pages in CGB WRAM bank 1, music from id $65, a game-set period offset for the Sfx2 track,
; and a request to ask whether a sound is playing.
;   ROM0: the sound code ($1733-$1CF5), every entry point mapping WRAM bank 1 (SVBK) first
;   bank $0C: table sets, SoundTable, headers, the drum set 1 table and headers ($4000-$4487),
;             the track code ($4488-$5316), tables ($5317-$624A), SFX and songs ($624B-$75B3)
;   banks $0D-$0F: songs (stream bank = $0C + the priority byte's high nibble)
; Build: rgbasm -Wall -o mummy.o MUMMY_SoundDriver.asm && rgblink -o mummy.gbc mummy.o
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
DEF wRomBank EQU $C00A
DEF wWramBank EQU $C00B
DEF wSndBusy EQU $C017
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
DEF wPeriodOfs EQU $D72D
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

SECTION "Sound ROM0", ROM0[$1733]

; SndInit (from the boot code): Cyborg Kuro-chan's, with WRAM bank 1. Every entry point below
; maps WRAM bank 1 first (wWramBank is the game's copy of SVBK).
SndInit:
	ld hl, wSndBusy
	set 2, [hl]
	ld a, [wWramBank]
	push af
	ld a, $01
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
	ld a, $01
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
	ld a, $01
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

; PlaySound: as Cyborg Kuro-chan's, music from id $65.
PlaySound:
	ld [wReqId], a
	or a
	jr nz, HoldRequest.l187B
	ld [wMusicId], a
	ld a, $0C
	ld [wRomBank], a
	ld [rROMB], a
	jp $4C78

HoldRequest:
	ld [wHeldReq], a
	ret
.l187B:
	ld hl, wReqHold
	bit 0, [hl]
	jr nz, HoldRequest
	cp $65
	jr c, PlaySoundGo
	ld b, a
	ld a, [wMusicId]
	cp b
	jr nz, .l188E
	ret
.l188E:
	ld a, b
	ld [wMusicId], a
	xor a
	ld [wNoiseAtten], a

PlaySoundGo:
	xor a
	ld [wWobbleOn], a
	ld a, [wSndDim]
	bit 0, a
	jr nz, .l18BE
	ld a, [wFadeDir]
	or a
	jr z, .l18B4
	bit 0, a
	jr z, .l18BE
	res 0, a
	set 0, a
	ld [wFadeDir], a
	jr .l18BE
.l18B4:
	ld c, $24
	ldh a, [c]
	cp $77
	jr z, .l18BE
	ld a, $77
	ldh [c], a
.l18BE:
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
	jr c, .l191B
	ret
.l191B:
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
	jr nz, .l1935
	ld [wFadeRate], a
	ld [wFadeTimer], a
.l1935:
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
	ld [wPeriodOfs], a
	ld [wPeriodOfs + $01], a
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
	jr nz, .l19BE
	ld a, $08
	ld c, $10
	ldh [c], a
	ret
.l19BE:
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

; SndUpdate (from the VBlank handler, $00B2): as Cyborg Kuro-chan's.
SndUpdate:
	di
	ld a, [wWramBank]
	push af
	ld a, $01
	ld [wWramBank], a
	ldh [rSVBK], a
	pop af
	ld [wGameWramBank], a
	ei
	ld a, [wRomBank]
	ld [wGameBank], a
	ld a, [wPauseFlag]
	and a
	jr z, .l1A02
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
.l1A02:
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
.l1A3E:
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
	jp $4488

SkipSfx1:
	ld a, $0C
	ld [wRomBank], a
	ld [rROMB], a
	jr UpdateSfx.l1A3E

; SpeedTick ($EE $80|n): every n updates one tick off the LEN of all four music tracks, put
; off while one of them is about to read; wSpeedRate 0: TempoTick instead.
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
	jr c, .l1AD2
	res 4, [hl]
	inc h
	res 4, [hl]
	inc h
	res 4, [hl]
	inc h
	res 4, [hl]
	ret
.l1AD2:
	set 4, [hl]
	inc h
	set 4, [hl]
	inc h
	set 4, [hl]
	inc h
	set 4, [hl]
	ret

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
	jr z, FadeStopCh2.l1B84
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
	jr nz, .l1B4A
	ld c, $1A
	ldh [c], a
	ld c, $1C
	ldh [c], a
.l1B4A:
	ld h, HIGH(wTrkCh3)
	ld [wFadeStep], a
	ld [wFadeRate], a
	ld [wFadeTimer], a
	ld a, $0C
	ld [wRomBank], a
	ld [rROMB], a
	jp $4C78

FadeStopCh1:
	ld h, HIGH(wTrkSfx1)
	ld l, TRK_ID
	ld a, [hl]
	or a
	jr nz, .l1B72
	ld a, $08
	ld c, $12
	ldh [c], a
	ld a, $80
	ld c, $14
	ldh [c], a
.l1B72:
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
.l1B84:
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
	jr nz, .l1BB8
	dec l
	and $0F
	cp [hl]
	jr nz, .l1BC3
	inc l
	set 1, [hl]
.l1BB3:
	ldh a, [c]
	sub $0F
	ldh [c], a
	ret
.l1BB8:
	swap a
	dec l
	and $0F
	cp [hl]
	jr nz, .l1BB3
	inc l
	res 1, [hl]
.l1BC3:
	ldh a, [c]
	add a, $0F
	cp $80
	jr c, .l1BCC
	sub $10
.l1BCC:
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

; IsSoundPlaying (new): A = sound id; returns A = the page (high byte) of the first track
; playing it, or 0. Called by the game.
IsSoundPlaying:
	push hl
	push af
	di
	ld a, [wWramBank]
	push af
	ld a, $01
	ld [wWramBank], a
	ldh [rSVBK], a
	pop af
	ld [wGameWramBank], a
	ei
	pop af
	ld hl, wTrkSfx1 + $01
	cp [hl]
	jr z, .l1C0D
	inc h
	cp [hl]
	jr z, .l1C0D
	inc h
	cp [hl]
	jr z, .l1C0D
	inc h
	cp [hl]
	jr z, .l1C0D
	inc h
	cp [hl]
	jr z, .l1C0D
	inc h
	cp [hl]
	jr z, .l1C0D
	inc h
	cp [hl]
	jr z, .l1C0D
	xor a
.l1C0D:
	ld h, a
	ld a, [wGameWramBank]
	ld [wWramBank], a
	ldh [rSVBK], a
	ld a, h
	pop hl
	ret

; SetPeriodOffset (new): wPeriodOfs = HL, added to every period the Sfx2 track writes
; (WritePeriodOfs).
SetPeriodOffset:
	di
	ld a, [wWramBank]
	push af
	ld a, $01
	ld [wWramBank], a
	ldh [rSVBK], a
	pop af
	ld [wGameWramBank], a
	ei
	ld a, l
	ld [wPeriodOfs], a
	ld a, h
	ld [wPeriodOfs + $01], a
	ld a, [wGameWramBank]
	ld [wWramBank], a
	ldh [rSVBK], a
	ret

; StartFadeOut, StopAndFadeIn (with StartFadeIn), SndUndim, SndDim: the game's entry points,
; each mapping WRAM bank 1 first.
StartFadeOut:
	push af
	di
	ld a, [wWramBank]
	push af
	ld a, $01
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
	jr nz, .l1C66
	ldh a, [c]
	cp $77
	jr z, .l1C6A
.l1C66:
	xor a
	ld [wWobbleOn], a
.l1C6A:
	ld a, [wGameWramBank]
	ld [wWramBank], a
	ldh [rSVBK], a
	ret

StopAndFadeIn:
	di
	ld a, [wWramBank]
	push af
	ld a, $01
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
	ld a, $01
	ld [wWramBank], a
	ldh [rSVBK], a
	pop af
	ld [wGameWramBank], a
	ei
	ld a, [wFadeRate]
	or a
	jr nz, .l1CC3
	ld hl, wSndDim
	res 0, [hl]
	ld a, $77
	ld c, $24
	ldh [c], a
.l1CC3:
	ld a, [wGameWramBank]
	ld [wWramBank], a
	ldh [rSVBK], a
	ret

SndDim:
	di
	ld a, [wWramBank]
	push af
	ld a, $01
	ld [wWramBank], a
	ldh [rSVBK], a
	pop af
	ld [wGameWramBank], a
	ei
	ld a, [wFadeRate]
	or a
	jr nz, .l1CED
	ld hl, wSndDim
	set 0, [hl]
	ld a, $44
	ld c, $24
	ldh [c], a
.l1CED:
	ld a, [wGameWramBank]
	ld [wWramBank], a
	ldh [rSVBK], a
	ret

SECTION "Sound bank $0C", ROMX[$4000], BANK[$0C]

; SoundTableSets: [SoundTableSets + 2 * wTableSet] is the table PlaySound reads: set 0 =
; SoundTable, set 1 = DrumSet1Table (its pointer is also SoundTable entry 0). The drum
; track reads its hits from set wDrumSet ($EA Fx, which no stream uses).
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
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd10_SfxN

SndHdr11:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd11_SfxN

SndHdr12:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd12_SfxN

SndHdr13:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd13_SfxN

SndHdr14:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd14_SfxN

SndHdr15:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd15_SfxN

SndHdr16:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd16_SfxN

SndHdr17:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd17_SfxN

SndHdr18:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd18_SfxN

SndHdr19:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd19_SfxN

SndHdr1A:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd1A_SfxN

SndHdr1B:
	SND_HEADER $02, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd1B_SfxN

SndHdr64:
	SND_HEADER $0E, $07 ; tracks: Sfx1, Sfx2, SfxN (streams in bank $0C)
	dw Snd64_Sfx1
	dw Snd64_Sfx2
	dw Snd64_Sfx2

SndHdr1C:
	SND_HEADER $0F, $07 ; tracks: Sfx1, Sfx2, SfxN (streams in bank $0C)
	dw Snd1C_Sfx1
	dw Snd1C_Sfx1
	dw Snd1C_Sfx1

SndHdr1D:
	SND_HEADER $0E, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd1D_SfxN

SndHdr1E:
	SND_HEADER $0E, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd1E_SfxN

SndHdr20:
	SND_HEADER $0E, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd20_Sfx1

SndHdr1F:
	SND_HEADER $0E, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd1F_Sfx1

SndHdr21:
	SND_HEADER $0F, $06 ; tracks: Sfx2, SfxN (streams in bank $0C)
	dw Snd21_Sfx2
	dw Snd21_SfxN

SndHdr22:
	SND_HEADER $0F, $07 ; tracks: Sfx1, Sfx2, SfxN (streams in bank $0C)
	dw Snd1C_Sfx1
	dw Snd22_Sfx2
	dw Snd22_SfxN

SndHdr23:
	SND_HEADER $0F, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd23_SfxN

SndHdr24:
	SND_HEADER $0F, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd24_SfxN

SndHdr25:
	SND_HEADER $0F, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd25_SfxN

SndHdr26:
	SND_HEADER $0F, $03 ; tracks: Sfx1, Sfx2 (streams in bank $0C)
	dw Snd26_Sfx1
	dw Snd26_Sfx2

SndHdr27:
	SND_HEADER $0E, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd27_Sfx1

SndHdr28:
	SND_HEADER $0E, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd28_Sfx1

SndHdr29:
	SND_HEADER $0E, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd29_Sfx1

SndHdr2A:
	SND_HEADER $0F, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd2A_Sfx1
	dw Snd2A_SfxN

SndHdr2B:
	SND_HEADER $0E, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd2B_SfxN

SndHdr2C:
	SND_HEADER $0E, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd2C_SfxN

SndHdr2D:
	SND_HEADER $0E, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd2D_SfxN

SndHdr2E:
	SND_HEADER $0E, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd2E_SfxN

SndHdr2F:
	SND_HEADER $0E, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd2F_SfxN

SndHdr30:
	SND_HEADER $0E, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd30_Sfx1
	dw Snd30_SfxN

SndHdr32:
	SND_HEADER $0E, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd32_Sfx1
	dw Snd32_SfxN

SndHdr34:
	SND_HEADER $0E, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd34_Sfx1
	dw Snd34_SfxN

SndHdr35:
	SND_HEADER $0E, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd35_Sfx1
	dw Snd35_SfxN

SndHdr33:
	SND_HEADER $0E, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd33_Sfx1
	dw Snd33_SfxN

SndHdr36:
	SND_HEADER $0E, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd36_SfxN

SndHdr37:
	SND_HEADER $0E, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd37_SfxN

SndHdr38:
	SND_HEADER $0E, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd38_Sfx1

SndHdr39:
	SND_HEADER $0E, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd39_Sfx1

SndHdr3A:
	SND_HEADER $0E, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd3A_Sfx1
	dw Snd3A_SfxN

SndHdr3B:
	SND_HEADER $0E, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd3B_SfxN

SndHdr3C:
	SND_HEADER $0E, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd3C_SfxN

SndHdr3D:
	SND_HEADER $0E, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd3D_Sfx1

SndHdr3E:
	SND_HEADER $0D, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd3E_Sfx1

SndHdr3F:
	SND_HEADER $0D, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd3F_Sfx1
	dw Snd3F_SfxN

SndHdr40:
	SND_HEADER $0E, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd40_SfxN

SndHdr31:
	SND_HEADER $0E, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd31_SfxN

SndHdr41:
	SND_HEADER $0D, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd41_SfxN

SndHdr42:
	SND_HEADER $0D, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd42_SfxN

SndHdr43:
	SND_HEADER $0E, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd43_SfxN

SndHdr44:
	SND_HEADER $0E, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd44_SfxN

SndHdr45:
	SND_HEADER $0E, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd45_SfxN

SndHdr46:
	SND_HEADER $0F, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd46_Sfx1

SndHdr47:
	SND_HEADER $0E, $03 ; tracks: Sfx1, Sfx2 (streams in bank $0C)
	dw Snd47_Sfx1
	dw Snd47_Sfx2

SndHdr48:
	SND_HEADER $0E, $03 ; tracks: Sfx1, Sfx2 (streams in bank $0C)
	dw Snd48_Sfx1
	dw Snd48_Sfx2

SndHdr49:
	SND_HEADER $0E, $03 ; tracks: Sfx1, Sfx2 (streams in bank $0C)
	dw Snd49_Sfx1
	dw Snd49_Sfx2

SndHdr4A:
	SND_HEADER $0E, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd4A_Sfx1

SndHdr4B:
	SND_HEADER $0E, $06 ; tracks: Sfx2, SfxN (streams in bank $0C)
	dw Snd4B_Sfx2
	dw Snd4B_SfxN

SndHdr4C:
	SND_HEADER $0E, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd4C_SfxN

SndHdr4D:
	SND_HEADER $0E, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd4D_SfxN

SndHdr4E:
	SND_HEADER $0E, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd4E_SfxN

SndHdr4F:
	SND_HEADER $0E, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd4F_SfxN

SndHdr50:
	SND_HEADER $0D, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd50_SfxN

SndHdr51:
	SND_HEADER $0D, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd51_Sfx1
	dw Snd51_SfxN

SndHdr52:
	SND_HEADER $0D, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd52_SfxN

SndHdr53:
	SND_HEADER $0D, $06 ; tracks: Sfx2, SfxN (streams in bank $0C)
	dw Snd53_Sfx2
	dw Snd53_SfxN

SndHdr54:
	SND_HEADER $0D, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd54_SfxN

SndHdr55:
	SND_HEADER $0E, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd55_Sfx1
	dw Snd55_SfxN

SndHdr56:
	SND_HEADER $0E, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd56_Sfx1
	dw Snd56_SfxN

SndHdr58:
	SND_HEADER $0F, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd58_Sfx1
	dw Snd58_SfxN

SndHdr57:
	SND_HEADER $0F, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd57_Sfx1
	dw Snd57_SfxN

SndHdr59:
	SND_HEADER $0E, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd59_SfxN

SndHdr5A:
	SND_HEADER $0E, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd5A_Sfx1
	dw Snd5A_SfxN

SndHdr5B:
	SND_HEADER $0E, $05 ; tracks: Sfx1, SfxN (streams in bank $0C)
	dw Snd5B_Sfx1
	dw Snd5B_SfxN

SndHdr5C:
	SND_HEADER $0E, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd5C_SfxN

SndHdr5D:
	SND_HEADER $0E, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd5D_SfxN

SndHdr5E:
	SND_HEADER $0E, $04 ; tracks: SfxN (streams in bank $0C)
	dw Snd5E_SfxN

SndHdr5F:
	SND_HEADER $0F, $03 ; tracks: Sfx1, Sfx2 (streams in bank $0C)
	dw Snd5F_Sfx1
	dw Snd5F_Sfx2

SndHdr60:
	SND_HEADER $0E, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd60_Sfx1

SndHdr61:
	SND_HEADER $0E, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd61_Sfx1

SndHdr62:
	SND_HEADER $0E, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd62_Sfx1

SndHdr63:
	SND_HEADER $0E, $01 ; tracks: Sfx1 (streams in bank $0C)
	dw Snd63_Sfx1

SndHdr86:
	SND_HEADER $38, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0F)
	dw Snd86_Ch1
	dw Snd86_Ch2
	dw Snd86_Ch3
	dw Snd86_Drm

SndHdr6D:
	SND_HEADER $18, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0D)
	dw Snd6D_Ch1
	dw Snd6D_Ch2
	dw Snd6D_Ch3
	dw Snd6D_Drm

SndHdr82:
	SND_HEADER $38, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0F)
	dw Snd82_Ch1
	dw Snd82_Ch2
	dw Snd82_Ch3
	dw Snd82_Drm

SndHdr81:
	SND_HEADER $38, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0F)
	dw Snd81_Ch1
	dw Snd81_Ch2
	dw Snd81_Ch3
	dw Snd81_Drm

SndHdr6E:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw Snd6E_Ch1
	dw Snd6E_Ch2
	dw Snd6E_Ch3
	dw Snd6E_Drm

SndHdr72:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw Snd72_Ch1
	dw Snd72_Ch2
	dw Snd72_Ch3
	dw Snd72_Drm

SndHdr71:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw Snd71_Ch1
	dw Snd71_Ch2
	dw Snd71_Ch3
	dw Snd71_Drm

SndHdr6F:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw Snd6F_Ch1
	dw Snd6F_Ch2
	dw Snd6F_Ch3
	dw Snd6F_Drm

SndHdr70:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw Snd70_Ch1
	dw Snd70_Ch2
	dw Snd70_Ch3
	dw Snd70_Drm

SndHdr76:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw Snd76_Ch1
	dw Snd76_Ch2
	dw Snd76_Ch3
	dw Snd76_Drm

SndHdr74:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw Snd74_Ch1
	dw Snd74_Ch2
	dw Snd74_Ch3
	dw Snd74_Drm

SndHdr84:
	SND_HEADER $38, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0F)
	dw Snd84_Ch1
	dw Snd84_Ch2
	dw Snd84_Ch3
	dw Snd84_Drm

SndHdr77:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw Snd77_Ch1
	dw Snd77_Ch2
	dw Snd77_Ch3
	dw Snd77_Drm

SndHdr7C:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw Snd7C_Ch1
	dw Snd7C_Ch2
	dw Snd7C_Ch3
	dw Snd7C_Drm

SndHdr7F:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw Snd7F_Ch1
	dw Snd7F_Ch2
	dw Snd7F_Ch3
	dw Snd7F_Drm

SndHdr7E:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw Snd7E_Ch1
	dw Snd7E_Ch2
	dw Snd7E_Ch3
	dw Snd7E_Drm

SndHdr7D:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw Snd7D_Ch1
	dw Snd7D_Ch2
	dw Snd7D_Ch3
	dw Snd7D_Drm

SndHdr7B:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw Snd7B_Ch1
	dw Snd7B_Ch2
	dw Snd7B_Ch3
	dw Snd7B_Drm

SndHdr78:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw Snd78_Ch1
	dw Snd78_Ch2
	dw Snd78_Ch3
	dw Snd78_Drm

SndHdr85:
	SND_HEADER $38, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0F)
	dw Snd85_Ch1
	dw Snd85_Ch2
	dw Snd85_Ch3
	dw Snd85_Drm

SndHdr83:
	SND_HEADER $38, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0F)
	dw Snd83_Ch1
	dw Snd83_Ch1
	dw Snd83_Ch3
	dw Snd83_Ch1

SndHdr7A:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw Snd7A_Ch1
	dw Snd7A_Ch2
	dw Snd7A_Ch3
	dw Snd7A_Drm

SndHdr87:
	SND_HEADER $38, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0F)
	dw Snd87_Ch1
	dw Snd87_Ch2
	dw Snd87_Ch3
	dw Snd87_Drm

SndHdr88:
	SND_HEADER $38, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0F)
	dw Snd88_Ch1
	dw Snd88_Ch2
	dw Snd88_Ch3
	dw Snd88_Drm

SndHdr79:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw Snd79_Ch1
	dw Snd79_Ch2
	dw Snd79_Ch3
	dw Snd79_Drm

SndHdr73:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw Snd73_Ch1
	dw Snd73_Ch2
	dw Snd73_Ch3
	dw Snd73_Drm

SndHdr65:
	SND_HEADER $18, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0D)
	dw Snd65_Ch1
	dw Snd65_Ch2
	dw Snd65_Ch3
	dw Snd65_Drm

SndHdr66:
	SND_HEADER $18, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0D)
	dw Snd66_Ch1
	dw Snd66_Ch2
	dw Snd66_Ch3
	dw Snd66_Drm

SndHdr67:
	SND_HEADER $18, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0D)
	dw Snd67_Ch1
	dw Snd67_Ch2
	dw Snd67_Ch3
	dw Snd67_Drm

SndHdr68:
	SND_HEADER $18, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0D)
	dw Snd68_Ch1
	dw Snd68_Ch2
	dw Snd68_Ch3
	dw Snd68_Drm

SndHdr69:
	SND_HEADER $18, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0D)
	dw Snd69_Ch1
	dw Snd69_Ch2
	dw Snd69_Ch3
	dw Snd69_Drm

SndHdr75:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw Snd75_Ch1
	dw Snd75_Ch2
	dw Snd75_Ch3
	dw Snd75_Drm

SndHdr6A:
	SND_HEADER $18, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0D)
	dw Snd6A_Ch1
	dw Snd6A_Ch2
	dw Snd6A_Ch3
	dw Snd6A_Drm

SndHdr6B:
	SND_HEADER $18, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0D)
	dw Snd6B_Ch1
	dw Snd6B_Ch2
	dw Snd6B_Ch3
	dw Snd6B_Drm

SndHdr80:
	SND_HEADER $28, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0E)
	dw Snd80_Ch1
	dw Snd80_Ch2
	dw Snd80_Ch3
	dw Snd80_Drm

SndHdr6C:
	SND_HEADER $18, $78 ; tracks: Ch1, Ch2, Ch3, Drm (streams in bank $0D)
	dw Snd6C_Ch1
	dw Snd6C_Ch2
	dw Snd6C_Ch3 ; the next pointer is the first word of DrumSet1Table

; DrumSet1Table: a second drum set, 11 hits (unused: no stream selects it).
DrumSet1Table:
	dw $797E ; id $00 (never read)
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

TrackTick:
	ld l, TRK_FLAGS
	bit 4, [hl]
	ret nz
	bit 5, [hl]
	jr z, .l4499
	res 5, [hl]
	ld l, TRK_CURDUTY
	ld a, [hl]
	call WriteDuty
.l4499:
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
	jr z, .l44D5
	ld l, TRK_VOL
	and $0F
	swap a
	ld [hl], a
	ld a, $01
	jr .l44D9
.l44D5:
	and $0F
	jr z, .l44E9
.l44D9:
	ld b, a
	xor a
	bit 0, b
	jr nz, .l44F0
	rrc b
.l44E1:
	add a, c
	dec b
	jr nz, .l44E1
	add a, a
	jp NoteLen
.l44E9:
	swap c
	ld a, c
	and $F0
	jr NoteLen
.l44F0:
	add a, c
	dec b
	jr nz, .l44F0

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
	jr z, .l452D
	ld e, a
	ld b, $00
	ld l, b
	ld h, b
.l4523:
	add hl, bc
	dec e
	jr nz, .l4523
	ld a, l
	and $F0
	or h
	swap a
.l452D:
	pop hl
	pop de
	ld l, TRK_RELTICK
	ld [hl], a
	ld l, TRK_DUTYCNT
	ld a, [hl+]
	or a
	jr z, .l453D
	ld [hl+], a
	ld a, [hl]
	call WriteDuty
.l453D:
	ld l, TRK_INSTR
	ld a, [hl]
	and a
	jr z, .l455A
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
.l455A:
	ld l, TRK_PANFLAGS
	bit 0, [hl]
	call nz, AutoPan
	ld a, [wReadBuf]
	and $F0
	cp $D0
	jr nz, .l4575
	ld l, TRK_OCTAVE
	ld a, [hl]
	add a, $18
	ld c, a
	ld l, $3C
	ld a, [hl]
	jr .l457E
.l4575:
	swap a
	rlca
	ld l, $3C
	ld [hl], a
	ld l, TRK_OCTAVE
	ld c, [hl]
.l457E:
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
	jr z, .l45A0
	ld c, [hl]
	push hl
	ld l, a
	ld h, c
	add hl, de
	ld e, l
	ld d, h
	pop hl
.l45A0:
	ld l, TRK_PANFLAGS
	bit 5, [hl]
	jr z, .l45B3
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
	jr .l45C8
.l45B3:
	ld l, TRK_PANFLAGS
	bit 7, [hl]
	jr z, .l45C8
	ld a, [wTrackDesc]
	cp $22
	jr z, .l45C8
	ld l, TRK_PERIOD
	ld a, [hl+]
	ld b, [hl]
	ld l, TRK_SAVEPERIOD
	ld [hl+], a
	ld [hl], b
.l45C8:
	ld l, TRK_PERIOD
	ld [hl], e
	inc l
	ld [hl], d
	ld l, TRK_VIB
	ld a, [hl]
	or a
	jr z, .l45F8
	rlca
	ld l, TRK_FLOW
	res 4, [hl]
	res 5, [hl]
	ld l, TRK_PANFLAGS
	jr nc, .l45E2
	set 4, [hl]
	jr .l45E4
.l45E2:
	res 4, [hl]
.l45E4:
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
.l45F8:
	call WritePeriodOfs
	ld l, TRK_ENVNO
	ld a, [hl]
	or a
	jr z, .l4614
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
	jp VibratoSemitone.l4867
.l4614:
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
	jr z, .l463D
	res 7, [hl]
	ld l, TRK_GATE
	ld [hl], $08
	ld l, TRK_ENV
	ld [hl], $00
.l463D:
	xor a
	ld l, TRK_RELVOL
	ld [hl], a
	ld a, [wTrackDesc]
	and $0F
	cp $02
	ld a, [wFadeStep]
	ld c, a
	ld a, b
	jr nz, .l465E
	add a, c
	jr c, .l4657
	cp $70
	jp c, WriteVolume
.l4657:
	xor a
	ld l, TRK_ID
	ld [hl], a
	jp WriteVolume
.l465E:
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

InstrumentTick:
	ld l, TRK_INSFLAGS
	ld a, [hl]
	and a
	jr z, InstrumentWaveBug.l46EB
	ld l, TRK_INSTIMER
	dec [hl]
	jr nz, InstrumentWaveBug.l46EB
	inc l
	ld c, [hl]
	inc l
	ld b, [hl]
.l4682:
	ld a, [bc]
	cp $FF
	jr z, InstrumentWaveBug.l46E7
	cp $FE
	jr z, .l46B2
	ld l, TRK_INSTIMER
	ld [hl], a
	inc bc
	ld a, [bc]
	inc bc
	push af
	ld a, $D1
	cp h
	jr z, .l46A0
	push hl
	ld h, a
	ld l, TRK_ID
	ld a, [hl]
	pop hl
	or a
	jr nz, InstrumentWaveBug
.l46A0:
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
	jr InstrumentWaveBug.l46D2
.l46B2:
	ld l, TRK_INSFLAGS
	ld a, [hl]
	and $08
	jr nz, .l46C7
	inc bc
	ld l, TRK_INSMARK
	ld [hl], c
	inc l
	ld [hl], b
	ld l, TRK_INSFLAGS
	ld a, $08
	or [hl]
	ld [hl], a
	jr .l4682
.l46C7:
	ld l, TRK_INSMARK
	ld c, [hl]
	inc l
	ld b, [hl]
	jr .l4682

InstrumentWaveBug:
	pop af
	ld [$0065], a
.l46D2:
	ld a, [bc]
	inc bc
	ld l, TRK_INSOFS
	ld [hl+], a
	bit 7, a
	ld a, $00
	jr z, .l46DF
	ld a, $FF
.l46DF:
	ld [hl], a
	ld l, TRK_INSPTR
	ld [hl], c
	inc l
	ld [hl], b
	jr .l46EB
.l46E7:
	xor a
	ld l, TRK_INSFLAGS
	ld [hl], a
.l46EB:
	ld l, TRK_DUTYCNT
	ld a, [hl+]
	or a
	jr z, .l46FA
	dec [hl]
	jr nz, .l46FA
	ld l, TRK_DUTY
	ld a, [hl]
	call WriteDuty
.l46FA:
	ld l, TRK_VIB
	ld a, [hl]
	or a
	jr z, .l4731
	ld l, TRK_PANFLAGS
	bit 2, [hl]
	jr z, .l4731
	ld l, $35
	ld a, [hl]
	or a
	jr z, .l470F
	dec [hl]
	jr .l4731
.l470F:
	ld l, $33
	dec [hl]
	jr nz, .l4731
	ld l, $31
	ld c, [hl]
	inc l
	ld b, [hl]
	call VibratoStep
	ld l, TRK_INSFLAGS
	ld a, [hl]
	and a
	jr z, .l472C
	push hl
	ld l, TRK_INSOFS
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	add hl, de
	ld e, l
	ld d, h
	pop hl
.l472C:
	call WritePeriodOfs
	jr .l4749
.l4731:
	ld l, TRK_INSFLAGS
	ld a, [hl]
	and a
	jr z, .l4749
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
	call WritePeriodOfs
.l4749:
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
	jp VibratoSemitone.l4867

VibratoStep:
	ld a, [bc]
	cp $FF
	jp z, VibratoStep2.l47EB
	cp $FE
	jp z, VibratoStep2.l4821
	cp $FB
	jp z, VibratoStep2.l47F5

VibratoStep2:
	ld l, $33
	cp $F0
	jr c, .l47A8
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
	jr z, .l478B
	dec d
.l478B:
	ld e, a
	ld l, $36
	ld a, [hl]
	or a
	jr z, .l47E5
	ld b, h
	ld hl, $0000
.l4796:
	add hl, de
	dec a
	jr nz, .l4796
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
.l47A8:
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
	jr z, .l47E5
	ld l, TRK_PANFLAGS
	bit 4, [hl]
	jr nz, VibratoSemitone
	ld l, $36
	ld e, a
	ld d, $00
	bit 3, a
	jr z, .l47CF
	and $07
	jr z, .l47E5
	cpl
	inc a
	ld e, a
	dec d
.l47CF:
	ld a, [hl]
	or a
	jr z, .l47DA
	ld b, a
	xor a
.l47D5:
	add a, e
	dec b
	jr nz, .l47D5
	ld e, a
.l47DA:
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
.l47E5:
	ld l, TRK_PERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ret
.l47EB:
	ld l, TRK_PANFLAGS
	res 2, [hl]
	ld l, TRK_OUTPERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ret
.l47F5:
	ld l, TRK_FLOW
	inc bc
	bit 4, [hl]
	jr nz, .l4809
	set 4, [hl]
	ld l, $37
	ld [hl], c
	inc l
	ld [hl], b
	inc l
	ld [hl], $00
	jp VibratoStep
.l4809:
	ld a, [bc]
	ld l, $39
	inc [hl]
	cp [hl]
	jr z, .l4817
	dec l
	ld b, [hl]
	dec l
	ld c, [hl]
	jp VibratoStep
.l4817:
	ld [hl], $00
	ld l, TRK_FLOW
	res 4, [hl]
	inc bc
	jp VibratoStep
.l4821:
	ld l, TRK_FLOW
	bit 5, [hl]
	jr nz, .l4832
	set 5, [hl]
	inc bc
	ld l, $3A
	ld [hl], c
	inc l
	ld [hl], b
	jp VibratoStep
.l4832:
	ld l, $3A
	ld c, [hl]
	inc l
	ld b, [hl]
	jp VibratoStep

VibratoSemitone:
	cp $0D
	jr c, .l484B
	sub $0D
	jr z, .l4849
	dec a
	jr z, .l4847
	add a, $0B
.l4847:
	add a, $05
.l4849:
	add a, $13
.l484B:
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
.l4867:
	ld a, [bc]
	cp $FF
	jr z, .l48B7
	cp $FE
	jr z, .l48E7
	cp $FB
	jr z, .l48BC
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
	jr c, .l48B2
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
	jr nz, .l48AE
	add a, c
	jr c, .l48AA
	cp $70
	jp c, WriteVolume
.l48AA:
	xor a
	jp WriteVolume
.l48AE:
	sub c
	jp nc, WriteVolume
.l48B2:
	ld a, $08
	jp WriteVolume
.l48B7:
	ld l, TRK_PANFLAGS
	res 3, [hl]
	ret
.l48BC:
	ld l, TRK_FLOW
	inc bc
	bit 6, [hl]
	jr nz, .l48CF
	set 6, [hl]
	ld l, TRK_ENVLOOPPTR
	ld [hl], c
	inc l
	ld [hl], b
	inc l
	ld [hl], $00
	jr .l4867
.l48CF:
	ld a, [bc]
	ld l, TRK_ENVLOOPCNT
	inc [hl]
	cp [hl]
	jr z, .l48DD
	dec l
	ld b, [hl]
	dec l
	ld c, [hl]
	jp .l4867
.l48DD:
	ld [hl], $00
	ld l, TRK_FLOW
	res 6, [hl]
	inc bc
	jp .l4867
.l48E7:
	ld l, TRK_FLOW
	bit 7, [hl]
	jr nz, .l48F8
	set 7, [hl]
	inc bc
	ld l, TRK_ENVMARK
	ld [hl], c
	inc l
	ld [hl], b
	jp .l4867
.l48F8:
	ld l, TRK_ENVMARK
	ld c, [hl]
	inc l
	ld b, [hl]
	jp .l4867

ReleaseTick:
	ld l, TRK_LEN
	ld a, [wTrackDesc]
	cp $22
	ld a, [hl]
	ld l, TRK_RELTICK
	jp z, ReleaseCh3
	cp [hl]
	jr z, .l491E
	ret c
	ld l, TRK_FLAGS
	bit 2, [hl]
	ret z
	res 2, [hl]
	ld l, TRK_LASTVOL
	ld a, [hl]
	jp WriteVolume
.l491E:
	ld l, TRK_PANFLAGS
	bit 7, [hl]
	jr z, .l495E
	ld l, TRK_ENV
	ld a, [hl]
	or a
	jr z, .l498B
	bit 3, [hl]
	jr z, .l4932
	and $0F
	jr .l4939
.l4932:
	ld b, a
	ld l, TRK_LASTVOL
	ld a, [hl]
	and $F0
	or b
.l4939:
	ld l, TRK_REG_NRX2
	ld c, [hl]
	call WriteRegChecked
	ret nc
	ld l, TRK_SAVEPERIOD + 1
	ld a, [hl]
	or a
	jr z, .l497A
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
.l495E:
	ld l, TRK_RELVOL
	ld a, [hl]
	or a
	jp nz, WriteVolume
	ld l, TRK_ENV
	ld a, [hl]
	or a
	jp z, .l498B
	ld b, a
	ld l, TRK_LASTVOL
	ld a, [hl]
	and $F0
	or b
	ld l, TRK_REG_NRX2
	ld c, [hl]
	call WriteRegChecked
	ret nc
.l497A:
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
.l498B:
	ld a, $08
	jp WriteVolume

ReleaseCh3:
	cp [hl]
	inc hl
	jr c, .l49A6
	jr z, .l49A3
	ld l, TRK_FLAGS
	bit 2, [hl]
	ret z
	res 2, [hl]
	ld l, TRK_LASTVOL
	ld a, [hl]
	jp WriteVolume
.l49A3:
	ld a, [hl+]
	ld [hl], a
	ret
.l49A6:
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

DrumNote:
	ld a, [wReadBuf]
	and $F0
	swap a
	cp $0D
	jr nz, .l49DB
	ld a, [wReadBuf + $01]
	inc de
	ld l, TRK_PTR
	ld [hl], e
	ld l, TRK_PTR + 1
	ld [hl], d
.l49DB:
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
	jr nz, .l4A46
	ld a, $08
	ld c, $10
	ldh [c], a
.l4A46:
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
	call WritePeriodOfs
	ld l, TRK_PANFLAGS
	bit 0, [hl]
	call nz, AutoPan
	ld l, TRK_FLAGS
	bit 7, [hl]
	ld l, TRK_LASTVOL
	ld a, [hl]
	jp z, WriteVolumeNoise
	jp WriteVolumeNow0.l4B7F

NoiseVolume:
	cp $D0
	jr nc, .l4A95
	ld l, TRK_FLAGS
	set 6, [hl]
	call SetNoiseVol
	call WriteVolumeNoise
	jp ReadCmds
.l4A95:
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
	jr z, .l4AC6
.l4AC1:
	rlc b
	dec a
	jr nz, .l4AC1
.l4AC6:
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
	jp WritePeriodOfs

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

; WritePeriodOfs: on the Sfx2 track (descriptor $52) wPeriodOfs is added first; then
; WritePeriod. Every period write goes through here.
WritePeriodOfs:
	ld a, [wTrackDesc]
	cp $52
	jr nz, WritePeriod
	push hl
	ld hl, wPeriodOfs
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	add hl, de
	ld e, l
	ld d, h
	pop hl

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
	jr z, .l4B31
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
.l4B31:
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
	jr nz, .l4B5F
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
.l4B5F:
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
.l4B7F:
	push af
	ld a, [wTrackDesc]
	cp $63
	jr nz, .l4BA7
	ld l, TRK_PRIO
	ld a, [hl]
	and $0F
	cp $02
	jr nz, .l4BA7
	ld a, [wNoiseAtten]
	ld b, a
	pop af
	ld l, a
	and $F0
	swap a
	sub b
	jr nc, .l4B9E
	xor a
.l4B9E:
	swap a
	ld b, a
	ld a, l
	and $0F
	or b
	jr WriteVolumeNow
.l4BA7:
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
	jr z, .l4C68
	cp $22
	jr nz, .l4C73
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
.l4C68:
	ld hl, wTrkSfx1 + $01
	ld a, [hl]
	or a
	pop hl
	ret nz
	ld a, b
	ldh [c], a
	scf
	ret
.l4C73:
	pop hl
	ld a, b
	ldh [c], a
	scf
	ret

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
	call WriteVolumeNow0.l4B7F
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
	jp nz, .l4E1B
	ld c, $10
	ld a, [wReadBuf + $03]
	ldh [c], a
.l4E1B:
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
	jr nz, .l4E9A
	ld a, [wReadBuf + $02]
	inc de
.l4E9A:
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

Ext_Instrument:
	pop hl
	inc de
	ld a, [wReadBuf + $02]
	inc de
	ld l, TRK_INSTR
	ld [hl+], a
	and a
	jr nz, .l4EC6
	ld [hl], a
	jp ReadCmds
.l4EC6:
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
	jr z, .l4EFF
.l4EFA:
	sla b
	dec a
	jr nz, .l4EFA
.l4EFF:
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
	jp nz, .l4F28
	bit 1, [hl]
	jp nz, PanRight.l4F55
	set 1, [hl]
	jp PanRight
.l4F28:
	bit 1, [hl]
	jp z, .l4F32
	res 1, [hl]
	jp PanBoth
.l4F32:
	set 1, [hl]

PanRight:
	ld b, $EE
	ld l, TRK_ID
	ld a, [wTrackDesc]
	and $0F
	or a
	jp z, .l4F49
.l4F41:
	rlc b
	rlc l
	dec a
	jp nz, .l4F41
.l4F49:
	ld c, $25
	ldh a, [c]
	and b
	or l
	ld b, l
	ld l, TRK_PAN
	ld [hl], b
	jp WriteRegChecked
.l4F55:
	res 1, [hl]

PanLeft:
	ld b, $EE
	ld l, TRK_SEGNO + 1
	ld a, [wTrackDesc]
	and $0F
	or a
	jr z, .l4F6A
.l4F63:
	rlc b
	rlc l
	dec a
	jr nz, .l4F63
.l4F6A:
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
	jp z, .l4FB0
	rlca
	cpl
	inc a
.l4FB0:
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
	jr z, .l4FF9
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
.l4FF9:
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
	jr z, .l5016
	ld l, TRK_PANFLAGS
	set 7, [hl]
	inc de
	jp ReadCmds
.l5016:
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
	jp z, .l5075
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
	jp z, .l506B
	ld b, a
	xor a
	bit 0, b
	jp nz, .l5066
	rrc b
.l505D:
	add a, c
	dec b
	jp nz, .l505D
	add a, a
	jp .l506B
.l5066:
	add a, c
	dec b
	jp nz, .l5066
.l506B:
	ld l, $34
	ld [hl+], a
	ld a, [wReadBuf + $02]
	and $0F
	inc l
	ld [hl], a
.l5075:
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
	jr z, .l50A7
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
.l50A7:
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
	jr nz, .l50D7
	set 5, [hl]
	ld l, TRK_SLIDEPTR
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	ld [hl], $00
	jp ReadCmds
.l50D7:
	ld b, $00
	ld a, [wReadBuf + $01]
	bit 7, a
	ld c, a
	ld l, TRK_F4
	jr nz, .l50E5
	jr .l50E6
.l50E5:
	dec b
.l50E6:
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
	jr nz, .l5114
	bit 6, a
	jr nz, .l5108
	sub $01
	cpl
	jr .l5122
.l5108:
	and $0F
	inc [hl]
	cp [hl]
	jr nz, .l512A
	ld [hl], $00
	ld a, $0F
	jr .l5122
.l5114:
	bit 6, a
	jr z, .l5122
	and $0F
	inc [hl]
	cp [hl]
	jr nz, .l512A
	ld [hl], $00
	ld a, $01
.l5122:
	and $0F
	swap a
	ld l, TRK_ATTEN
	add a, [hl]
	ld [hl], a
.l512A:
	inc de
	ld a, [wReadBuf + $03]
	ld l, TRK_SLIDECNT
	inc [hl]
	cp [hl]
	jp z, .l513D
	ld l, TRK_SLIDEPTR
	ld e, [hl]
	inc l
	ld d, [hl]
	jp ReadCmds
.l513D:
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

Cmd_Tempo:
	pop hl
	inc de
	bit 7, a
	jr z, .l5162
	and $7F
	ld [wSpeedRate], a
	ld [wSpeedTimer], a
	jp ReadCmds
.l5162:
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
	jp z, .l517C
	ld a, $FF
.l517C:
	ld [hl], a
	inc de
	jp ReadCmds

Cmd_Atten:
	pop hl
	dec de
	ld a, [wReadBuf]
	and $0F
	swap a
	jr z, .l519A
	ld b, a
	ld a, [wTrackDesc]
	and $0F
	cp $02
	ld a, b
	jr nz, .l519A
	sla a
	cpl
.l519A:
	ld l, TRK_ATTEN
	ld [hl], a
	inc de
	jp ReadCmds

Cmd_LoopBreak:
	pop hl
	bit 0, a
	jr z, .l51BD
	ld l, TRK_FLOW
	bit 0, [hl]
	jr z, .l51D6
	ld l, TRK_BREAK
	dec [hl]
	jr nz, .l51D6
	ld l, TRK_FLOW
	res 0, [hl]
	ld l, TRK_EXIT
	ld a, [hl+]
	ld d, [hl]
	ld e, a
	jp ReadCmds
.l51BD:
	ld l, TRK_FLOW
	bit 1, [hl]
	jr z, .l51D6
	ld l, TRK_BREAK2
	dec [hl]
	jr nz, .l51D6
	ld l, TRK_FLOW
	res 1, [hl]
	res 0, [hl]
	ld l, TRK_EXIT2
	ld a, [hl+]
	ld d, [hl]
	ld e, a
	jp ReadCmds
.l51D6:
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
	jp nz, .l51FA
	set 0, [hl]
	ld l, TRK_LOOPPTR
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	xor a
	ld [hl], a
	jp ReadCmds
.l51FA:
	ld l, TRK_BREAK
	ld a, [hl]
	cp $FF
	jr nz, .l520F
	ld a, [wReadBuf + $01]
	ld l, TRK_BREAK
	ld [hl], a
	dec [hl]
	inc de
	ld l, TRK_EXIT
	ld [hl], e
	ld l, TRK_EXIT + 1
	ld [hl], d
.l520F:
	ld a, [wReadBuf + $01]
	ld l, TRK_LOOPCNT
	inc [hl]
	cp [hl]
	jp z, .l5220
	dec l
	ld d, [hl]
	dec l
	ld e, [hl]
	jp ReadCmds
.l5220:
	ld [hl], $00
	ld l, TRK_FLOW
	res 0, [hl]
	inc de
	jp ReadCmds

Cmd_Loop2:
	pop hl
	ld l, TRK_FLOW
	bit 1, [hl]
	jp nz, .l523F
	set 1, [hl]
	ld l, TRK_LOOP2PTR
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	xor a
	ld [hl], a
	jp ReadCmds
.l523F:
	ld l, TRK_BREAK2
	ld a, [hl]
	cp $FF
	jr nz, .l5254
	ld a, [wReadBuf + $01]
	ld l, TRK_BREAK2
	ld [hl], a
	dec [hl]
	inc de
	ld l, TRK_EXIT2
	ld [hl], e
	ld l, TRK_EXIT2 + 1
	ld [hl], d
.l5254:
	ld a, [wReadBuf + $01]
	ld l, TRK_LOOP2CNT
	inc [hl]
	cp [hl]
	jp z, .l5265
	dec l
	ld d, [hl]
	dec l
	ld e, [hl]
	jp ReadCmds
.l5265:
	ld [hl], $00
	ld l, TRK_FLOW
	res 1, [hl]
	inc de
	jp ReadCmds

Cmd_CallRet:
	pop hl
	ld l, TRK_FLOW
	bit 2, [hl]
	jp nz, .l5289
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
.l5289:
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
	jp nz, .l52A5
	set 3, [hl]
	ld l, TRK_SEGNO
	ld [hl], e
	inc l
	ld [hl], d
	jp ReadCmds
.l52A5:
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
	jp z, .l52E7
	cp $40
	jp z, .l52D0
	cp $63
	jp nz, MuteChannel
	ld l, TRK_FLAGS
	res 3, [hl]
	jp MuteChannel
.l52D0:
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
.l52E7:
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

Ext_DrumSet:
	and $03
	ld [wDrumSet], a
	inc de
	pop hl
	jp ReadCmds

; WaveTable: 119 pointers (the wave byte swapped, x 2).
WaveTable:
	dw Wave_5405 ; wave 0
	dw Wave_5415 ; wave 1
	dw Wave_5425 ; wave 2
	dw Wave_5435 ; wave 3
	dw Wave_5445 ; wave 4
	dw Wave_5455 ; wave 5
	dw Wave_5465 ; wave 6
	dw Wave_5475 ; wave 7
	dw Wave_5485 ; wave 8
	dw Wave_5495 ; wave 9
	dw Wave_54A5 ; wave 10
	dw Wave_54B5 ; wave 11
	dw Wave_54C5 ; wave 12
	dw Wave_54D5 ; wave 13
	dw Wave_54E5 ; wave 14
	dw Wave_54F5 ; wave 15
	dw Wave_5505 ; wave 16
	dw Wave_5515 ; wave 17
	dw Wave_5525 ; wave 18
	dw Wave_5535 ; wave 19
	dw Wave_5545 ; wave 20
	dw Wave_5555 ; wave 21
	dw Wave_5565 ; wave 22
	dw Wave_5575 ; wave 23
	dw Wave_5585 ; wave 24
	dw Wave_5595 ; wave 25
	dw Wave_55A5 ; wave 26
	dw Wave_55B5 ; wave 27
	dw Wave_55C5 ; wave 28
	dw Wave_55D5 ; wave 29
	dw Wave_55D5 ; wave 30
	dw Wave_55F5 ; wave 31
	dw Wave_5605 ; wave 32
	dw Wave_5615 ; wave 33
	dw Wave_5625 ; wave 34
	dw Wave_5635 ; wave 35
	dw Wave_5645 ; wave 36
	dw Wave_5655 ; wave 37
	dw Wave_5665 ; wave 38
	dw Wave_5675 ; wave 39
	dw Wave_5685 ; wave 40
	dw Wave_5695 ; wave 41
	dw Wave_56A5 ; wave 42
	dw Wave_56B5 ; wave 43
	dw Wave_56C5 ; wave 44
	dw Wave_56D5 ; wave 45
	dw Wave_56E5 ; wave 46
	dw Wave_56F5 ; wave 47
	dw Wave_5705 ; wave 48
	dw Wave_5715 ; wave 49
	dw Wave_5725 ; wave 50
	dw Wave_5735 ; wave 51
	dw Wave_5745 ; wave 52
	dw Wave_5755 ; wave 53
	dw Wave_5765 ; wave 54
	dw Wave_5775 ; wave 55
	dw Wave_5785 ; wave 56
	dw Wave_5795 ; wave 57
	dw Wave_57A5 ; wave 58
	dw Wave_57B5 ; wave 59
	dw Wave_57C5 ; wave 60
	dw Wave_57D5 ; wave 61
	dw Wave_57E5 ; wave 62
	dw Wave_57F5 ; wave 63
	dw Wave_5805 ; wave 64
	dw Wave_5815 ; wave 65
	dw Wave_5825 ; wave 66
	dw Wave_5835 ; wave 67
	dw Wave_5845 ; wave 68
	dw Wave_5855 ; wave 69
	dw Wave_5865 ; wave 70
	dw Wave_5875 ; wave 71
	dw Wave_5885 ; wave 72
	dw Wave_5895 ; wave 73
	dw Wave_58A5 ; wave 74
	dw Wave_58B5 ; wave 75
	dw Wave_58C5 ; wave 76
	dw Wave_58D5 ; wave 77
	dw Wave_58E5 ; wave 78
	dw Wave_58F5 ; wave 79
	dw Wave_5905 ; wave 80
	dw Wave_5915 ; wave 81
	dw Wave_5925 ; wave 82
	dw Wave_5935 ; wave 83
	dw Wave_5945 ; wave 84
	dw Wave_5955 ; wave 85
	dw Wave_5965 ; wave 86
	dw Wave_5975 ; wave 87
	dw Wave_5985 ; wave 88
	dw Wave_5995 ; wave 89
	dw Wave_59A5 ; wave 90
	dw Wave_59B5 ; wave 91
	dw Wave_59C5 ; wave 92
	dw Wave_59D5 ; wave 93
	dw Wave_59E5 ; wave 94
	dw Wave_59F5 ; wave 95
	dw Wave_5A05 ; wave 96
	dw Wave_5A15 ; wave 97
	dw Wave_5A25 ; wave 98
	dw Wave_5A35 ; wave 99
	dw Wave_5A45 ; wave 100
	dw Wave_5A55 ; wave 101
	dw Wave_5A65 ; wave 102
	dw Wave_5A75 ; wave 103
	dw Wave_5A85 ; wave 104
	dw Wave_5A95 ; wave 105
	dw Wave_5AA5 ; wave 106
	dw Wave_5AB5 ; wave 107
	dw Wave_5AC5 ; wave 108
	dw Wave_5AD5 ; wave 109
	dw Wave_5AE5 ; wave 110
	dw Wave_5AF5 ; wave 111
	dw Wave_5B05 ; wave 112
	dw Wave_5B15 ; wave 113
	dw Wave_5B25 ; wave 114
	dw Wave_5B35 ; wave 115
	dw Wave_5B45 ; wave 116
	dw Wave_5B55 ; wave 117
	dw Wave_5B65 ; wave 118
Wave_5405:
	db $14, $7A, $FE, $CA, $97, $54, $35, $68, $9F, $ED, $CB, $AB, $DB, $97, $54, $62
Wave_5415:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $10, $00, $00, $00, $00, $00, $00, $01
Wave_5425:
	db $E7, $1E, $18, $D6, $A1, $99, $19, $51, $97, $C1, $79, $8C, $37, $57, $71, $77
Wave_5435:
	db $F0, $FF, $C0, $CF, $80, $8F, $40, $4F, $00, $0F, $40, $4F, $80, $8F, $C0, $CF
Wave_5445:
	db $EE, $EE, $DC, $CB, $B9, $AA, $99, $98, $88, $87, $77, $77, $55, $54, $43, $21
Wave_5455:
	db $35, $79, $BD, $BA, $87, $75, $E6, $78, $AC, $DE, $DC, $BA, $98, $87, $76, $54
Wave_5465:
	db $58, $BD, $FE, $CA, $A8, $B5, $D4, $E2, $D1, $B2, $94, $76, $94, $C2, $E3, $C6
Wave_5475:
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF
Wave_5485:
	db $48, $BF, $ED, $B9, $75, $36, $9C, $FF, $ED, $DC, $BB, $AA, $99, $98, $76, $54
Wave_5495:
	db $0E, $F0, $80, $FC, $06, $42, $01, $F3, $43, $05, $46, $70, $89, $0B, $C0, $EF
Wave_54A5:
	db $FE, $DC, $BA, $9A, $98, $78, $9A, $BA, $98, $76, $76, $78, $98, $AB, $CD, $EF
Wave_54B5:
	db $BD, $DB, $98, $9C, $EF, $EB, $76, $68, $AA, $94, $21, $24, $88, $53, $35, $8B
Wave_54C5:
	db $AC, $CA, $88, $8B, $DE, $DA, $77, $78, $99, $85, $32, $35, $88, $64, $46, $8A
Wave_54D5:
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $CC, $CC, $CC, $CC
Wave_54E5:
	db $FF, $FF, $00, $00, $69, $CC, $96, $23, $58, $A8, $65, $24, $68, $63, $56, $54
Wave_54F5:
	db $B0, $BB, $80, $8B, $50, $5B, $10, $1B, $00, $0B, $10, $1B, $50, $5B, $80, $8B
Wave_5505:
	db $F0, $F2, $F4, $F6, $F8, $F9, $FA, $FB, $FC, $FD, $FE, $FE, $FF, $00, $00, $6A
Wave_5515:
	db $F0, $8F, $29, $F4, $AF, $6B, $F8, $CF, $AC, $FB, $EF, $CE, $FF, $00, $00, $6A
Wave_5525:
	db $F8, $08, $F9, $39, $FA, $6A, $FB, $8B, $FC, $AC, $FB, $DF, $FF, $00, $00, $6A
Wave_5535:
	db $F8, $05, $AF, $A4, $6B, $FB, $79, $CF, $C8, $AC, $FC, $AC, $FF, $00, $00, $6A
Wave_5545:
	db $FB, $60, $6B, $FC, $95, $9C, $FD, $A7, $AD, $FE, $BA, $BE, $FF, $00, $00, $6A
Wave_5555:
	db $FC, $84, $04, $8C, $FD, $A7, $47, $AD, $FE, $BA, $9A, $BE, $FF, $80, $00, $6A
Wave_5565:
	db $FC, $96, $30, $36, $9C, $FD, $B9, $76, $79, $BD, $FE, $DE, $FF, $92, $00, $6A
Wave_5575:
	db $FD, $B9, $63, $03, $69, $BD, $FE, $DB, $98, $9B, $DE, $FE, $FF, $A3, $00, $6A
Wave_5585:
	db $FE, $CA, $85, $20, $25, $8A, $CE, $FE, $DC, $B9, $89, $BD, $FF, $B4, $00, $6A
Wave_5595:
	db $FE, $DC, $B8, $53, $10, $13, $58, $BC, $EF, $ED, $BC, $DE, $FF, $B6, $04, $9B
Wave_55A5:
	db $FE, $DC, $B9, $75, $32, $10, $12, $35, $78, $9A, $BC, $DE, $FE, $B6, $04, $9B
Wave_55B5:
	db $FE, $DC, $B9, $75, $32, $10, $12, $35, $78, $9A, $BA, $98, $9A, $BC, $DE, $EF
Wave_55C5:
	db $FE, $DC, $BA, $97, $54, $32, $10, $12, $34, $57, $9A, $AB, $AB, $CD, $DE, $FF
Wave_55D5:
	db $99, $99, $99, $99, $99, $99, $99, $99, $00, $00, $00, $00, $00, $00, $00, $00
	db $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $00, $00, $00, $00, $00, $00, $00, $00
Wave_55F5:
	db $BB, $BB, $BB, $BB, $BB, $BB, $BB, $BB, $00, $00, $00, $00, $00, $00, $00, $00
Wave_5605:
	db $E1, $E3, $E5, $E7, $E8, $E8, $E9, $EA, $EB, $EC, $ED, $ED, $EE, $11, $11, $79
Wave_5615:
	db $E1, $8E, $38, $E5, $9E, $7A, $E8, $BE, $9B, $EA, $DE, $BD, $EE, $11, $11, $79
Wave_5625:
	db $E8, $18, $E8, $48, $E9, $79, $EA, $8A, $EB, $9B, $EA, $CE, $EE, $11, $11, $79
Wave_5635:
	db $E8, $16, $9E, $95, $7A, $EA, $78, $BE, $B8, $9B, $EB, $9B, $EE, $11, $11, $79
Wave_5645:
	db $EA, $71, $7A, $EB, $86, $8B, $EC, $97, $9C, $ED, $A9, $AD, $EE, $11, $11, $79
Wave_5655:
	db $EB, $85, $15, $8B, $EC, $97, $57, $9C, $ED, $A9, $89, $AD, $EE, $81, $11, $79
Wave_5665:
	db $EB, $87, $41, $47, $8B, $EC, $A8, $77, $78, $AC, $ED, $CD, $EE, $83, $11, $79
Wave_5675:
	db $EC, $A8, $74, $14, $78, $AC, $ED, $CA, $88, $8A, $CD, $ED, $EE, $94, $11, $79
Wave_5685:
	db $ED, $B9, $86, $31, $36, $89, $BD, $ED, $CB, $A8, $88, $AC, $EE, $A5, $11, $79
Wave_5695:
	db $ED, $CB, $A8, $64, $21, $24, $68, $AB, $DE, $DC, $AB, $CD, $EE, $A7, $15, $8A
Wave_56A5:
	db $ED, $CB, $A8, $76, $43, $21, $23, $46, $78, $89, $AB, $CD, $ED, $A7, $15, $8A
Wave_56B5:
	db $ED, $CB, $A8, $76, $43, $21, $23, $46, $78, $89, $A9, $88, $89, $AB, $CD, $DE
Wave_56C5:
	db $ED, $CB, $A9, $87, $65, $43, $21, $23, $45, $67, $89, $9A, $9A, $BC, $CD, $EE
Wave_56D5:
	db $CC, $CC, $CC, $CC, $CC, $CC, $CC, $CC, $00, $00, $00, $00, $00, $00, $00, $00
Wave_56E5:
	db $DD, $DD, $DD, $DD, $DD, $DD, $DD, $DD, $00, $00, $00, $00, $00, $00, $00, $00
Wave_56F5:
	db $EE, $EE, $EE, $EE, $EE, $EE, $EE, $EE, $00, $00, $00, $00, $00, $00, $00, $00
Wave_5705:
	db $94, $39, $45, $94, $39, $45, $43, $FF, $49, $39, $49, $59, $43, $94, $59, $43
Wave_5715:
	db $A4, $53, $A4, $3F, $B4, $A3, $A4, $59, $43, $94, $59, $43, $A4, $54, $3B, $43
Wave_5725:
	db $92, $34, $3B, $49, $3B, $4B, $39, $45, $49, $3A, $4A, $3B, $4A, $3B, $4A, $3A
Wave_5735:
	db $4B, $3A, $4B, $39, $4A, $3A, $49, $32, $39, $43, $C4, $54, $39, $4C, $39, $4B
Wave_5745:
	db $3B, $49, $3C, $43, $F4, $54, $39, $45, $94, $93, $94, $54, $3A, $49, $3F, $B4
Wave_5755:
	db $3B, $4A, $39, $45, $A4, $A5, $94, $93, $4B, $3A, $23, $A2, $A3, $D4, $A3, $4D
Wave_5765:
	db $5A, $4F, $93, $D2, $3F, $B4, $A3, $94, $59, $4B, $54, $F9, $32, $93, $B2, $3E
Wave_5775:
	db $49, $39, $4F, $FA, $3F, $C4, $3A, $49, $34, $F9, $54, $93, $94, $A3, $F9, $23
Wave_5785:
	db $94, $93, $23, $94, $A3, $94, $F9, $34, $B3, $43, $A4, $A2, $A4, $A3, $29, $4B
Wave_5795:
	db $39, $49, $54, $93, $4C, $3A, $43, $B4, $93, $B4, $93, $A4, $B3, $94, $FB, $39
Wave_57A5:
	db $49, $3A, $43, $D4, $3A, $4A, $34, $F3, $4C, $3A, $4A, $3D, $49, $3B, $4A, $39
Wave_57B5:
	db $4B, $39, $4A, $34, $93, $C4, $93, $B4, $3D, $49, $3A, $4F, $A3, $94, $A3, $A4
Wave_57C5:
	db $A3, $23, $4A, $32, $93, $49, $3B, $4A, $39, $4C, $39, $4A, $3A, $4A, $3A, $4A
Wave_57D5:
	db $3A, $43, $D4, $A3, $94, $C3, $94, $C3, $A4, $B3, $A4, $A3, $A4, $A3, $A4, $F9
Wave_57E5:
	db $39, $4A, $3B, $4A, $3A, $49, $3B, $4A, $39, $49, $34, $D3, $94, $B3, $A4, $A3
Wave_57F5:
	db $A4, $A3, $B4, $93, $A4, $C3, $4A, $3A, $4A, $3A, $4A, $3A, $49, $3C, $49, $39
Wave_5805:
	db $C4, $C5, $C6, $C7, $C8, $C9, $C9, $CA, $CB, $CB, $CB, $CB, $CC, $44, $44, $79
Wave_5815:
	db $C4, $8C, $59, $C6, $9C, $6A, $C8, $BC, $9B, $CA, $BC, $CB, $CC, $44, $44, $69
Wave_5825:
	db $C8, $48, $C9, $59, $CA, $7A, $CA, $8A, $CB, $9B, $CB, $BC, $CC, $44, $44, $69
Wave_5835:
	db $C8, $46, $9C, $94, $7A, $CB, $79, $BC, $B8, $9B, $CB, $9B, $CC, $44, $44, $79
Wave_5845:
	db $CA, $64, $6A, $CB, $95, $9B, $CB, $97, $9B, $CB, $A9, $AB, $CC, $44, $44, $69
Wave_5855:
	db $CA, $85, $45, $8A, $CB, $97, $57, $9B, $CB, $A9, $99, $AB, $CC, $84, $44, $69
Wave_5865:
	db $CA, $96, $54, $57, $9A, $CB, $A9, $76, $79, $AB, $CB, $AB, $CC, $94, $44, $69
Wave_5875:
	db $CA, $A9, $75, $45, $79, $AB, $CB, $A9, $98, $9A, $AB, $CB, $CC, $95, $44, $79
Wave_5885:
	db $CB, $A9, $86, $54, $56, $89, $AB, $CB, $AB, $99, $89, $AB, $CC, $A5, $44, $69
Wave_5895:
	db $CB, $A9, $98, $76, $54, $45, $68, $9A, $BC, $BA, $9A, $BC, $CC, $A6, $45, $9A
Wave_58A5:
	db $CB, $A9, $98, $76, $55, $44, $45, $56, $78, $99, $AB, $CC, $CB, $A6, $45, $9A
Wave_58B5:
	db $CB, $A9, $A9, $76, $54, $44, $44, $56, $78, $9A, $A9, $98, $99, $AA, $BC, $CC
Wave_58C5:
	db $CB, $A9, $89, $97, $65, $44, $44, $45, $56, $67, $99, $AB, $AB, $BC, $BC, $CC
Wave_58D5:
	db $95, $3B, $4C, $34, $93, $C5, $4A, $34, $A3, $43, $94, $93, $A4, $B3, $A4, $34
Wave_58E5:
	db $39, $4A, $3B, $4A, $3A, $4A, $3A, $49, $39, $43, $4A, $3A, $49, $53, $B4, $A3
Wave_58F5:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $01, $23, $45, $67, $89, $AB, $CD, $EF
Wave_5905:
	db $7C, $DC, $BB, $A9, $DC, $A5, $43, $33, $21, $00, $01, $26, $BE, $DA, $84, $45
Wave_5915:
	db $7B, $EF, $DB, $86, $55, $9A, $99, $8B, $BA, $65, $44, $44, $32, $11, $05, $24
Wave_5925:
	db $7C, $DF, $EB, $88, $68, $A6, $89, $87, $43, $53, $54, $43, $23, $23, $81, $56
Wave_5935:
	db $7B, $FE, $DC, $B9, $9B, $86, $98, $34, $42, $34, $33, $31, $33, $48, $52, $57
Wave_5945:
	db $7B, $DC, $CF, $EC, $DB, $79, $84, $1A, $42, $13, $30, $13, $34, $86, $34, $76
Wave_5955:
	db $79, $BB, $CE, $FF, $EB, $99, $84, $23, $42, $12, $30, $02, $45, $65, $44, $66
Wave_5965:
	db $79, $9A, $CF, $FF, $EC, $CA, $73, $24, $31, $12, $20, $13, $56, $54, $45, $55
Wave_5975:
	db $78, $89, $CE, $FF, $EE, $DB, $64, $45, $31, $22, $10, $13, $55, $33, $45, $55
Wave_5985:
	db $77, $79, $BE, $FF, $EE, $DB, $64, $45, $22, $22, $11, $24, $54, $34, $55, $45
Wave_5995:
	db $78, $AD, $ED, $DF, $EB, $87, $76, $32, $32, $11, $24, $54, $34, $55, $45, $67
Wave_59A5:
	db $78, $AC, $DC, $DE, $DB, $98, $86, $43, $32, $12, $34, $53, $34, $55, $45, $66
Wave_59B5:
	db $78, $9B, $CB, $CD, $CB, $99, $97, $54, $32, $22, $34, $43, $34, $55, $55, $66
Wave_59C5:
	db $77, $9A, $BA, $BC, $DA, $9A, $A8, $65, $43, $22, $34, $43, $34, $55, $55, $56
Wave_59D5:
	db $77, $8A, $AA, $AC, $BA, $9A, $A9, $76, $54, $33, $34, $33, $23, $45, $55, $56
Wave_59E5:
	db $77, $89, $99, $AB, $AA, $9A, $A9, $87, $65, $44, $44, $32, $23, $44, $45, $56
Wave_59F5:
	db $77, $89, $99, $AA, $A9, $9A, $A9, $87, $66, $55, $44, $32, $23, $44, $44, $56
Wave_5A05:
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF
Wave_5A15:
	db $EE, $EE, $11, $11, $69, $CC, $96, $23, $58, $A8, $65, $24, $68, $63, $56, $54
Wave_5A25:
	db $DD, $DD, $22, $22, $69, $CC, $96, $23, $58, $A8, $65, $24, $68, $63, $56, $54
Wave_5A35:
	db $CC, $CC, $33, $33, $69, $CC, $96, $33, $58, $A8, $65, $34, $68, $63, $56, $54
Wave_5A45:
	db $BB, $BB, $44, $44, $69, $BB, $96, $44, $58, $A8, $65, $44, $68, $64, $56, $54
Wave_5A55:
	db $AA, $AA, $55, $55, $69, $AA, $96, $55, $58, $A8, $65, $55, $68, $65, $56, $55
Wave_5A65:
	db $99, $99, $66, $66, $69, $99, $96, $66, $68, $98, $66, $66, $68, $66, $66, $66
Wave_5A75:
	db $FC, $2F, $59, $AB, $CD, $EF, $EC, $BA, $BA, $54, $21, $2E, $2E, $25, $E0, $EF
Wave_5A85:
	db $FF, $62, $6F, $FF, $FE, $FC, $AF, $FF, $91, $5A, $A5, $00, $00, $1C, $A0, $00
Wave_5A95:
	db $C8, $7A, $DE, $EF, $FC, $78, $A8, $66, $68, $9A, $BD, $C9, $99, $64, $F1, $05
Wave_5AA5:
	db $31, $01, $22, $10, $04, $89, $EF, $D9, $61, $00, $26, $78, $AA, $9A, $BA, $B6
Wave_5AB5:
	db $EC, $2E, $59, $AB, $CD, $EE, $EC, $BA, $BA, $54, $21, $2E, $2E, $25, $E0, $EE
Wave_5AC5:
	db $EC, $2E, $59, $AB, $CD, $EE, $EC, $BA, $BA, $54, $21, $2E, $2E, $25, $E1, $EE
Wave_5AD5:
	db $DC, $2D, $59, $AB, $CD, $DD, $DC, $BA, $BA, $54, $21, $2D, $2D, $25, $D1, $DD
Wave_5AE5:
	db $DC, $2D, $59, $AB, $CD, $DD, $DC, $BA, $BA, $54, $22, $2D, $2D, $25, $D2, $DD
Wave_5AF5:
	db $CC, $2C, $59, $AB, $CC, $CC, $CC, $BA, $BA, $54, $22, $2C, $2C, $25, $C2, $CC
Wave_5B05:
	db $CC, $3C, $59, $AB, $CC, $CC, $CC, $BA, $BA, $54, $33, $3C, $3C, $35, $C3, $CC
Wave_5B15:
	db $BB, $3B, $59, $AB, $BB, $BB, $BB, $BA, $BA, $54, $33, $3B, $3B, $35, $B3, $BB
Wave_5B25:
	db $BB, $4B, $59, $AB, $BB, $BB, $BB, $BA, $BA, $54, $44, $4B, $4B, $45, $B4, $BB
Wave_5B35:
	db $AA, $4A, $59, $AA, $AA, $AA, $AA, $AA, $AA, $54, $44, $4A, $4A, $45, $A4, $AA
Wave_5B45:
	db $AA, $5A, $59, $AA, $AA, $AA, $AA, $AA, $AA, $55, $55, $5A, $5A, $55, $A5, $AA
Wave_5B55:
	db $99, $59, $59, $99, $99, $99, $99, $99, $99, $55, $55, $59, $59, $55, $95, $99
Wave_5B65:
	db $99, $69, $69, $99, $99, $99, $99, $99, $99, $66, $66, $69, $69, $66, $96, $99

; PeriodTable: 96 periods (from PeriodTable - 26).
PeriodTable:
	dw $02C, $09D, $107, $16B, $1C9, $223, $277, $2C7, $312, $358, $39B, $3DA ; octave index 0
	dw $416, $44E, $483, $4B5, $4E5, $511, $53B, $563, $589, $5AC, $5CE, $5ED ; octave index 1
	dw $60B, $627, $642, $65B, $672, $689, $69E, $6B2, $6C4, $6D6, $6E7, $6F7 ; octave index 2
	dw $706, $714, $721, $72D, $739, $744, $74F, $759, $762, $76B, $773, $77B ; octave index 3
	dw $783, $78A, $790, $797, $79D, $7A2, $7A7, $7AC, $7B1, $7B6, $7BA, $7BE ; octave index 4
	dw $7C1, $7C5, $7C8, $7CB, $7CE, $7D1, $7D4, $7D6, $7D9, $7DB, $7DD, $7DF ; octave index 5
	dw $7E1, $7E2, $7E4, $7E6, $7E7, $7E9, $7EA, $7EB, $7EC, $7ED, $7EE, $7EF ; octave index 6
	dw $7F0, $7F1, $7F2, $7F3, $7F4, $7F5, $7F6, $7F7, $7F8, $7F9, $7FA, $7FB ; octave index 7

; Credit text between the tables.
Credit:
	db "Sound Programmed By Jun Yamaguchi."

; VibratoTable: 16 pointers (EB n uses entry n; from VibratoTable - 2).
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
	dw Vib10 ; 16

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

Vib0E:
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

Vib0F:
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

Vib10:
	VIB_MARK
	VIB_STEP 2, 0, 0
	VIB_STEP 1, 0, 1
	VIB_STEP 2, 0, 2
	VIB_STEP 2, 0, 1
	VIB_STEP 2, 0, 0
	VIB_STEP 1, 1, 1
	VIB_STEP 2, 1, 2
	VIB_STEP 2, 1, 1
	VIB_MARK

; Vibrato2Table: 11 semitone-step tables (EB n | $80).
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
	VIB_SEMI_STEP 5, 1
	VIB_SEMI_STEP 5, 2
	VIB_SEMI_STEP 5, 1
	VIB_SEMI_STEP 6, 0
	VIB_MARK
	VIB_SEMI_STEP 1, 1
	VIB_MARK
VibSemi02:
	VIB_SEMI_STEP 5, 0
	VIB_SEMI_STEP 1, 1
	VIB_END
VibSemi03:
	VIB_SEMI_STEP 5, 1
	VIB_SEMI_STEP 5, 3
	VIB_SEMI_STEP 5, 1
	VIB_SEMI_STEP 6, 0
	VIB_SEMI_STEP 1, 1
	VIB_END
VibSemi04:
	VIB_SEMI_STEP 3, 0
	VIB_SEMI_STEP 1, 1
	VIB_END
VibSemi05:
	VIB_SEMI_STEP 5, 0
	VIB_SEMI_STEP 5, 1
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi06:
	VIB_SEMI_STEP 5, 2
	VIB_SEMI_STEP 5, 4
	VIB_SEMI_STEP 5, 2
	VIB_SEMI_STEP 6, 1
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi07:
	VIB_SEMI_STEP 5, 1
	VIB_SEMI_STEP 5, 3
	VIB_SEMI_STEP 5, 1
	VIB_SEMI_STEP 6, 0
	VIB_END
VibSemi08:
	VIB_SEMI_STEP 4, 0
	VIB_SEMI_STEP 4, 2
	VIB_SEMI_STEP 4, 3
	VIB_SEMI_STEP 4, 6
	VIB_SEMI_STEP 4, 7
	VIB_SEMI_STEP 4, 8
	VIB_SEMI_STEP 4, $0B
	VIB_MARK
	VIB_SEMI_STEP 4, $0C
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

; EnvelopeTable: 30 volume envelopes (EC n, or a voice with volume 0).
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
Env01:
	ENV_STEP 4, $0B
	ENV_STEP 4, $0C
	ENV_STEP 5, $0D
	ENV_STEP 4, $0E
	ENV_STEP 4, $0F
	VIB_END
Env02:
	ENV_STEP $0A, $0C
	ENV_STEP $0A, $0A
	ENV_STEP $0A, 9
	ENV_STEP $0A, 8
	ENV_STEP $0A, 7
	ENV_STEP $0A, 6
	VIB_MARK
	ENV_STEP $0A, 5
	VIB_MARK
Env03:
	ENV_STEP $0F, 6
	ENV_STEP $0F, 7
	ENV_STEP 8, 7
	ENV_STEP $0F, 8
	ENV_STEP 8, 8
	ENV_STEP $0F, 9
	ENV_STEP 8, 9
	ENV_STEP 4, $0A
	ENV_STEP $0F, $0A
	ENV_STEP 8, $0B
	VIB_LOOP_START
	ENV_STEP 4, $0C
	ENV_STEP $0F, $0C
	ENV_STEP $0F, $0D
	ENV_STEP 8, $0D
	VIB_MARK
	ENV_STEP 4, $0E
	VIB_MARK
	db $1F ; unreachable (after the envelope's end)
	db $FE
Env04:
	ENV_STEP $0F, 3
	ENV_STEP $0F, 4
	ENV_STEP $0F, 4
	ENV_STEP $0F, 5
	ENV_STEP $0F, 5
	ENV_STEP $0F, 6
	ENV_STEP $0F, 6
	ENV_STEP $0F, 7
	ENV_STEP $0F, 7
	ENV_STEP $0F, 8
	VIB_END
Env05:
	ENV_STEP 2, 7
	ENV_STEP 2, 8
	ENV_STEP 2, 9
	ENV_STEP 2, $0A
	ENV_STEP 2, $0B
	ENV_STEP 2, $0C
	VIB_END
Env06:
	ENV_STEP 6, 7
	ENV_STEP 6, 8
	ENV_STEP $0A, 9
	ENV_STEP $0A, $0A
	ENV_STEP $0C, $0B
	VIB_END
Env07:
	VIB_MARK
	ENV_STEP 1, $0A
	VIB_MARK
Env08:
	ENV_STEP 3, 6
	ENV_STEP 3, 7
	ENV_STEP 3, 8
	ENV_STEP 3, 9
	ENV_STEP 3, $0A
	ENV_STEP 3, $0B
	ENV_STEP 3, $0C
	ENV_STEP 3, $0D
	ENV_STEP 3, $0E
	ENV_STEP 3, $0F
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
	VIB_MARK
	ENV_STEP 1, $0A
	VIB_MARK
Env0B:
	ENV_STEP 6, 4
	ENV_STEP 6, 4
	ENV_STEP 6, 5
	ENV_STEP 6, 5
	ENV_STEP 6, 6
	ENV_STEP 6, 6
	ENV_STEP 6, 7
	ENV_STEP 6, 7
	ENV_STEP 6, 8
	VIB_END
Env0C:
	VIB_MARK
	ENV_STEP 0, $0C
	VIB_MARK
Env0D:
	ENV_STEP $0F, 7
	ENV_STEP $0F, 7
	ENV_STEP $0F, 8
	ENV_STEP $0F, 8
	VIB_MARK
	ENV_STEP $0F, 9
	VIB_MARK
Env0E:
	ENV_STEP 6, 5
	ENV_STEP 6, 6
	ENV_STEP $0A, 7
	ENV_STEP $0A, 8
	VIB_MARK
	ENV_STEP $0C, 9
	VIB_MARK
Env0F:
	VIB_MARK
	ENV_STEP 1, 9
	VIB_MARK
Env10:
	ENV_STEP $0F, 9
	ENV_STEP $0F, 9
	ENV_STEP $0F, 8
	ENV_STEP $0F, 7
	ENV_STEP $0F, 6
	ENV_STEP $0F, 5
	ENV_STEP $0F, 4
	ENV_STEP $0F, 3
	ENV_STEP $0F, 2
	VIB_END
Env11:
	ENV_STEP 2, $0C
	ENV_STEP 1, $0A
	ENV_STEP 2, 7
	ENV_STEP 2, 5
	ENV_STEP 1, 3
	ENV_STEP 2, 2
	VIB_END
Env12:
	ENV_STEP 2, 8
	ENV_STEP 2, 7
	ENV_STEP 2, 6
	ENV_STEP 2, 5
	ENV_STEP $0A, 4
	ENV_STEP $0A, 5
	ENV_STEP $0A, 6
	ENV_STEP $0A, 7
	ENV_STEP $0A, 8
	ENV_STEP $0C, 9
	ENV_STEP $0C, $0A
	ENV_STEP $0C, $0B
	VIB_END
Env13:
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
	VIB_END
Env14:
	ENV_STEP 6, 6
	ENV_STEP 6, 6
	ENV_STEP 4, 5
	ENV_STEP 4, 5
	ENV_STEP 4, 4
	ENV_STEP 4, 4
	ENV_STEP 4, 3
	ENV_STEP 4, 3
	ENV_STEP 4, 2
	ENV_STEP 4, 2
	ENV_STEP 4, 1
	ENV_STEP 4, 1
	VIB_END
Env15:
	ENV_STEP 4, 4
	ENV_STEP 4, 5
	ENV_STEP 5, 6
	ENV_STEP 4, 7
	ENV_STEP 4, 8
	VIB_END
Env16:
	ENV_STEP 2, $0C
	ENV_STEP 2, $0B
	ENV_STEP 2, $0A
	ENV_STEP 2, 9
	ENV_STEP $0A, $0A
	ENV_STEP $0A, $0B
	ENV_STEP $0A, $0C
	ENV_STEP $0C, $0D
	ENV_STEP $0C, $0E
	ENV_STEP $0C, $0F
	VIB_END
Env17:
	ENV_STEP $0F, 9
	ENV_STEP $0F, $0A
	VIB_LOOP_START
	ENV_STEP $0F, $0C
	ENV_STEP $0F, $0D
	VIB_MARK
	ENV_STEP 1, $0E
	VIB_MARK
	db $FF ; unreachable end
Env18:
	ENV_STEP $0F, 7
	ENV_STEP $0D, 6
	ENV_STEP $0D, 5
	ENV_STEP $0D, 4
	ENV_STEP $0D, 3
	ENV_STEP $0D, 2
	ENV_STEP $0D, 1
	VIB_END
Env19:
	ENV_STEP $0D, 7
	ENV_STEP $0D, 8
	ENV_STEP $0D, 9
	ENV_STEP $0D, $0A
	ENV_STEP $0D, $0B
	ENV_STEP $0D, $0C
	ENV_STEP $0F, $0D
	ENV_STEP $0D, $0E
	VIB_MARK
	ENV_STEP 1, $0F
	VIB_MARK
Env1A:
	ENV_STEP $0F, 9
	ENV_STEP 8, 9
	ENV_STEP 4, $0A
	ENV_STEP $0F, $0A
	ENV_STEP 8, $0B
	VIB_LOOP_START
	ENV_STEP 4, $0C
	ENV_STEP $0F, $0C
	ENV_STEP $0F, $0D
	ENV_STEP 8, $0D
	VIB_MARK
	ENV_STEP 4, $0E
	VIB_MARK
	db $1F ; unreachable (after the envelope's end)
	db $FE
Env1B:
	ENV_STEP 3, 9
	ENV_STEP 3, $0A
	VIB_MARK
	ENV_STEP 1, $0B
	VIB_MARK
Env1C:
	ENV_STEP 2, $0F
	ENV_STEP 2, $0E
	ENV_STEP 2, $0D
	ENV_STEP 2, $0C
	ENV_STEP 2, $0B
	ENV_STEP 2, $0A
	VIB_END
Env1D:
	ENV_STEP 8, $0B
	VIB_LOOP_START
	ENV_STEP $0F, $0C
	ENV_STEP $0F, $0C
	ENV_STEP $0F, $0D
	ENV_STEP 8, $0D
	VIB_MARK
	ENV_STEP 4, $0E
	VIB_MARK
	db $1F ; unreachable (after the envelope's end)
	db $FE
Env1E:
	ENV_STEP $0F, 7
	ENV_STEP $0F, 7
	ENV_STEP $0F, 6
	ENV_STEP $0F, 6
	VIB_MARK
	ENV_STEP $0F, 5
	VIB_MARK

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
	INS_STEP 4, $1D, $00
	INS_STEP 4, $1E, $00
	INS_STEP 4, $1F, $00
	INS_STEP 4, $2D, $00
	INS_STEP 4, $2E, $00
	INS_STEP 4, $2F, $00
	INS_MARK
	INS_STEP 1, $01, $00
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
	INS_STEP 4, $01, $00
	INS_STEP 4, $2F, $00
	INS_STEP 4, $2E, $00
	INS_STEP 4, $2D, $00
	INS_STEP 4, $1F, $00
	INS_STEP 4, $1E, $00
	INS_STEP 4, $1D, $00
	INS_END
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
	INS_STEP 1, $1C, $00
	INS_MARK
	INS_STEP 1, $10, $00
	INS_STEP 1, $14, $00
	INS_MARK

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
	NVOICE $02, $E3
	LEN_UNIT $2A
	NOISE $11
	SND_END

Snd0D_SfxN:
	NVOICE $02, $F3
	NOISE $58
	NOISE $82
	NOISE $93
	NOISE $A5
	SND_END

Snd0E_SfxN:
	NVOICE $02, $F2
	NOISE $13
	NOISE $14
	NOISE $21
	NOISE $23
	NOISE $33
	NOISE $32
	NOISE $34
	NOISE $41
	NOISE $31
	NOISE $42
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $54
	NVOICE $02, $F0
	NOISE $65
	NOISE $61
	NOISE $63
	NOISE $61
	NOISE $63
	NOISE $62
	NOISE $61
	NVOICE $02, $D0
	NOISE $52
	NOISE $51
	NOISE $43
	NOISE $56
	NOISE $62
	NOISE $54
	NOISE $53
	NOISE $51
	NOISE $43
	NOISE $51
	NOISE $53
	NVOICE $02, $B0
	NOISE $45
	NOISE $31
	NOISE $43
	NOISE $33
	NOISE $42
	NOISE $41
	NOISE $53
	NOISE $42
	NOISE $41
	NVOICE $02, $90
	NOISE $35
	NOISE $31
	NOISE $23
	NOISE $34
	NOISE $32
	NOISE $31
	NOISE $23
	NOISE $32
	NOISE $31
	NVOICE $02, $70
	NOISE $25
	NOISE $21
	NOISE $23
	NOISE $24
	NOISE $22
	NOISE $11
	NOISE $23
	NOISE $22
	NOISE $21
	NVOICE $02, $55
	NOISE $15
	NOISE $11
	NOISE $13
	NOISE $14
	NOISE $12
	NOISE $11
	NOISE $13
	NOISE $12
	NOISE $11
	SND_END

Snd0F_SfxN:
	NVOICE $02, $F1
	NOISE $52
	NOISE $52
	NOISE $54
	NOISE $55
	NOISE $62
	NOISE $54
	NOISE $55
	NOISE $42
	NVOICE $02, $C1
	NOISE $52
	NOISE $52
	NOISE $54
	NOISE $55
	NOISE $62
	NOISE $54
	NOISE $55
	NOISE $42
	NVOICE $02, $91
	NOISE $52
	NOISE $52
	NOISE $54
	NOISE $55
	NOISE $62
	NOISE $54
	NOISE $55
	NOISE $42
	NVOICE $02, $71
	NOISE $52
	NOISE $52
	NOISE $54
	NOISE $55
	NOISE $62
	NOISE $54
	NOISE $55
	NOISE $42
	NVOICE $01, $41
	NOISE $52
	NOISE $52
	NOISE $54
	NOISE $55
	NOISE $62
	NOISE $54
	NOISE $55
	NOISE $42
	NOISE $54
	NOISE $55
	SND_END

Snd10_SfxN:
	NVOICE $0E, $F1
	NOISE $5D
	NVOICE $0E, $C1
	NOISE $5D
	NVOICE $0E, $91
	NOISE $5D
	NVOICE $0E, $71
	NOISE $5D
	NVOICE $0E, $41
	NOISE $5D
	SND_END

Snd11_SfxN:
	LOOP_START
	NVOICE $01, $11
	NOISE $13
	NOISE $22
	NOISE $12
	NOISE $33
	NOISE $41
	LOOP_END $04
	LOOP_START
	NVOICE $01, $21
	NOISE $13
	NOISE $22
	NOISE $12
	NOISE $33
	NOISE $41
	LOOP_END $04
	LOOP_START
	NVOICE $01, $31
	NOISE $13
	NOISE $22
	NOISE $12
	NOISE $33
	NOISE $41
	LOOP_END $04
	LOOP_START
	NVOICE $01, $41
	NOISE $13
	NOISE $22
	NOISE $12
	NOISE $33
	NOISE $41
	LOOP_END $04
	LOOP_START
	NVOICE $01, $51
	NOISE $13
	NOISE $22
	NOISE $12
	NOISE $33
	NOISE $41
	LOOP_END $04
	LOOP_START
	NVOICE $01, $61
	NOISE $13
	NOISE $22
	NOISE $12
	NOISE $33
	NOISE $41
	LOOP_END $04
	LOOP_START
	NVOICE $01, $71
	NOISE $13
	NOISE $22
	NOISE $12
	NOISE $33
	NOISE $41
	LOOP_END $04
	LOOP_START
	NVOICE $01, $81
	NOISE $13
	NOISE $22
	NOISE $12
	NOISE $33
	NOISE $41
	LOOP_END $04
	LOOP_START
	NVOICE $01, $91
	NOISE $13
	NOISE $22
	NOISE $12
	NOISE $33
	NOISE $41
	LOOP_END $04
	LOOP_START
	NVOICE $01, $A1
	NOISE $13
	NOISE $22
	NOISE $12
	NOISE $33
	NOISE $41
	LOOP_END $04
	LOOP_START
	NVOICE $01, $A1
	NOISE $13
	NOISE $22
	NOISE $12
	NOISE $33
	NOISE $41
	NVOICE $01, $A1
	NOISE $14
	NOISE $22
	NOISE $13
	NOISE $33
	NOISE $41
	NVOICE $01, $A1
	NOISE $14
	NOISE $22
	NOISE $13
	NOISE $33
	NOISE $41
	LOOP_END $28
	LOOP_START
	NVOICE $01, $B1
	NOISE $13
	NOISE $22
	NOISE $12
	NOISE $33
	NOISE $41
	LOOP_END $04
	LOOP_START
	NVOICE $01, $A1
	NOISE $13
	NOISE $22
	NOISE $12
	NOISE $33
	NOISE $41
	LOOP_END $04
	LOOP_START
	NVOICE $01, $91
	NOISE $13
	NOISE $22
	NOISE $12
	NOISE $33
	NOISE $41
	LOOP_END $04
	LOOP_START
	NVOICE $01, $81
	NOISE $13
	NOISE $22
	NOISE $12
	NOISE $33
	NOISE $41
	LOOP_END $04
	LOOP_START
	NVOICE $01, $71
	NOISE $13
	NOISE $22
	NOISE $12
	NOISE $33
	NOISE $41
	LOOP_END $04
	LOOP_START
	NVOICE $01, $61
	NOISE $13
	NOISE $22
	NOISE $12
	NOISE $33
	NOISE $41
	LOOP_END $04
	LOOP_START
	NVOICE $01, $51
	NOISE $13
	NOISE $22
	NOISE $12
	NOISE $33
	NOISE $41
	LOOP_END $04
	LOOP_START
	NVOICE $01, $41
	NOISE $13
	NOISE $22
	NOISE $12
	NOISE $33
	NOISE $41
	LOOP_END $04
	LOOP_START
	NVOICE $01, $31
	NOISE $13
	NOISE $22
	NOISE $12
	NOISE $33
	NOISE $41
	LOOP_END $04
	SND_END

Snd12_SfxN:
	NVOICE $03, $F3
	NOISE $45
	NOISE $47
	NOISE $45
	NOISE $43
	NOISE $42
	NOISE $41
	NVOICE $03, $C3
	NOISE $45
	NOISE $47
	NOISE $45
	NOISE $43
	NOISE $42
	NOISE $41
	NVOICE $03, $A3
	NOISE $45
	NOISE $47
	NOISE $45
	NOISE $43
	NOISE $42
	NOISE $41
	NVOICE $03, $83
	NOISE $45
	NOISE $47
	NOISE $45
	NOISE $43
	NOISE $42
	NOISE $41
	NVOICE $03, $53
	NOISE $45
	NOISE $47
	NOISE $45
	NOISE $43
	NOISE $42
	NOISE $41
	NVOICE $03, $33
	NOISE $45
	NOISE $47
	NOISE $45
	NOISE $43
	NOISE $42
	NOISE $41
	SND_END

Snd13_SfxN:
	NVOICE $0E, $F0
	NOISE $11
	NVOICE $0E, $E3
	NOISE $11
	NVOICE $0E, $D0
	NOISE $11
	NVOICE $0E, $C3
	NOISE $11
	NVOICE $0E, $B0
	NOISE $11
	NVOICE $0E, $A3
	NOISE $11
	NVOICE $0E, $90
	NOISE $11
	NVOICE $0E, $83
	NOISE $11
	NVOICE $0E, $70
	NOISE $11
	NVOICE $0E, $63
	NOISE $11
	NVOICE $0E, $50
	NOISE $11
	NVOICE $0E, $43
	NOISE $11
	NVOICE $0E, $30
	NOISE $11
	NVOICE $0E, $23
	NOISE $11
	NVOICE $0E, $10
	NOISE $11
	SND_END

Snd14_SfxN:
	NVOICE $02, $E0
	NOISE $58
	NVOICE $0D, $A2
	NOISE $5E
	NOISE $5E
	SND_END

Snd15_SfxN:
	NVOICE $02, $E0
	NOISE $58
	NVOICE $0D, $A2
	NOISE $5D
	NOISE $5D
	SND_END

Snd16_SfxN:
	NVOICE $02, $E0
	NOISE $58
	NVOICE $0D, $A2
	NOISE $5C
	NOISE $5C
	SND_END

Snd17_SfxN:
	NVOICE $01, $D2
	NOISE $43
	NOISE_VOL 8
	NOISE $32
	NOISE_VOL 5
	NOISE $41
	NOISE $42
	NVOICE $01, $D0
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

Snd18_SfxN:
	NVOICE $01, $80
	NOISE $41
	NOISE_VOL $0A
	NOISE $32
	NOISE_VOL 7
	NOISE $23
	NVOICE $08, $23
	NOISE $11
	SND_END

Snd19_SfxN:
	NVOICE $01, $F1
	NOISE $32
	NOISE $44
	NOISE $51
	NOISE $51
	NOISE $45
	NOISE $53
	NVOICE $01, $D1
	PAN_LEFT 0
	NOISE $45
	NOISE $53
	NOISE $44
	NOISE $51
	NOISE $45
	NOISE $53
	NVOICE $01, $B1
	PAN_RIGHT 0
	NOISE $32
	NOISE $44
	NOISE $51
	NOISE $51
	NOISE $45
	NOISE $53
	PAN_BOTH 0
	NVOICE $01, $91
	PAN_BOTH 0
	NOISE $32
	NOISE $44
	NOISE $51
	NOISE $51
	NOISE $45
	NOISE $53
	NVOICE $01, $71
	PAN_LEFT 0
	NOISE $45
	NOISE $53
	NOISE $44
	NOISE $51
	NOISE $45
	NOISE $53
	NVOICE $01, $51
	PAN_RIGHT 0
	NOISE $32
	NOISE $44
	NOISE $51
	NOISE $51
	NOISE $45
	NOISE $53
	PAN_BOTH 0
	NVOICE $01, $31
	PAN_BOTH 0
	NOISE $32
	NOISE $44
	NOISE $51
	NOISE $51
	NOISE $45
	NOISE $53
	NVOICE $01, $11
	PAN_LEFT 0
	NOISE $45
	NOISE $53
	NOISE $44
	NOISE $51
	NOISE $45
	NOISE $53
	SND_END

Snd1A_SfxN:
	NVOICE $01, $F1
	NOISE $33
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $45
	NOISE $54
	NVOICE $01, $D1
	PAN_LEFT 0
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $45
	NOISE $54
	NOISE $53
	NVOICE $01, $B1
	PAN_RIGHT 0
	NOISE $45
	NOISE $53
	NOISE $44
	NOISE $51
	NOISE $45
	NOISE $53
	PAN_BOTH 0
	NVOICE $01, $91
	PAN_BOTH 0
	NOISE $33
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $45
	NOISE $54
	NVOICE $01, $71
	PAN_LEFT 0
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $45
	NOISE $54
	NOISE $53
	NVOICE $01, $51
	PAN_RIGHT 0
	NOISE $45
	NOISE $53
	NOISE $44
	NOISE $51
	NOISE $45
	NOISE $53
	PAN_BOTH 0
	NVOICE $01, $31
	PAN_BOTH 0
	NOISE $33
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $45
	NOISE $54
	NVOICE $01, $11
	PAN_LEFT 0
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $45
	NOISE $54
	NOISE $53
	SND_END

Snd1B_SfxN:
	NVOICE $01, $F1
	NOISE $31
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $45
	NOISE $53
	NVOICE $01, $D1
	PAN_LEFT 0
	NOISE $31
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $45
	NOISE $54
	NVOICE $01, $B1
	PAN_RIGHT 0
	NOISE $45
	NOISE $53
	NOISE $44
	NOISE $51
	NOISE $45
	NOISE $53
	PAN_BOTH 0
	NVOICE $01, $91
	PAN_BOTH 0
	NOISE $31
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $45
	NOISE $53
	NVOICE $01, $71
	PAN_LEFT 0
	NOISE $31
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $45
	NOISE $54
	NVOICE $01, $51
	PAN_RIGHT 0
	NOISE $45
	NOISE $53
	NOISE $44
	NOISE $51
	NOISE $45
	NOISE $53
	PAN_BOTH 0
	NVOICE $01, $31
	PAN_BOTH 0
	NOISE $31
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $45
	NOISE $53
	NVOICE $01, $11
	PAN_LEFT 0
	NOISE $31
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $45
	NOISE $54
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

Snd64_Sfx1:
	VOICE $01, 8, 11, 8, 6
	OCTAVE 5
	NOTE E_, 1
	ATTEN 2
	NOTE E_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 0
	NOTE C_, 1
	ATTEN 2
	NOTE C_, 1
	ATTEN 4
	NOTE C_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 2
	NOTE E_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 0
	NOTE C_, 1
	ATTEN 2
	NOTE C_, 1
	ATTEN 4
	NOTE C_, 1
	ATTEN 5
	NOTE E_, 1
	ATTEN 6
	NOTE G_, 1
	OCTAVE 5
	ATTEN 7
	NOTE C_, 1
	ATTEN 8
	NOTE E_, 1
	SND_END

Snd1C_Sfx1:
	SND_END

Snd1D_SfxN:
	NVOICE $04, $C4
	NOISE $25
	NOISE $24
	NOISE $25
	NOISE $24
	NOISE $24
	NOISE $25
	NOISE $24
	NOISE $25
	NOISE $24
	NOISE $24
	SND_END

Snd1E_SfxN:
	NVOICE $82, $F0
	NOISE $43
	NOISE $42
	NVOICE $81, $01
	NOISE $11
	NVOICE $82, $C1
	NOISE $43
	NOISE $42
	NOISE $41
	SND_END

Snd20_Sfx1:
	VOICE $01, 8, 15, 0, 0
	DETUNE $04
	DUTY_STEP 4, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	VOICE $03, 8, 15, 15, 2
	OCTAVE 4
	VIBRATO $0B, 0, 5
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A#, 1
	RELEASE $0F, 1
	NOTE C_HI, 1
	NOTE A#, 4
	SND_END

Snd1F_Sfx1:
	VOICE $02, 8, 15, 15, 1
	DETUNE $02
	TRANSPOSE_DOWN 1
	OCTAVE 5
	NOTE D#, 1
	NOTE G_, 1
	ATTEN 2
	NOTE A#, 1
	NOTE D#, 1
	NOTE G_, 1
	ATTEN 2
	NOTE A#, 1
	OCTAVE 6
	NOTE D#, 2
	VOICE $04, 8, 15, 15, 2
	OCTAVE 5
	NOTE A#, 8
	SND_END

Snd21_Sfx2:
	VOICE $01, 4, 2, 0, 0
	WAVE_X $67
	TRANSPOSE_DOWN 3
	OCTAVE 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
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
	NOTE A#, 1
	NOTE B_, 1
	VOICE $01, 4, 2, 0, 0
	WAVE_X $67
	TRANSPOSE_DOWN 3
	OCTAVE 3
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	SND_END

Snd21_SfxN:
	NVOICE $01, $F8
	NOISE $33
	NOISE $75
	NOISE $37
	NOISE $75
	NOISE $35
	NOISE $75
	NOISE $36
	NOISE $75
	NOISE $37
	NOISE $75
	NOISE $67
	NOISE $68
	NOISE $66
	NOISE $62
	NOISE $56
	NOISE $55
	NOISE $54
	NOISE $45
	NOISE $56
	NOISE $65
	NOISE $46
	NOISE $55
	SND_END

Snd22_Sfx2:
	VOICE $01, 4, 2, 0, 0
	WAVE_X $67
	TRANSPOSE_DOWN 3
	OCTAVE 2
	LOOP_START
	NOTE C_, 1
	NOTE D#, 1
	LOOP_END $1E
	DETUNE $02
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $04
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $06
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $08
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $0A
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $0C
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $0E
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $10
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $12
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $14
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $16
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $18
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $1A
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $1C
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $1E
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $20
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $22
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $24
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $26
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $28
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $2A
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $2C
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $2E
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $30
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $32
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $34
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $36
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $38
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $3A
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $3C
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $3E
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $40
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $42
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $44
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $46
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $48
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $4A
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $4C
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $4E
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $50
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $52
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $54
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $56
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $58
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $5A
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $5C
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $5E
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $60
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $62
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $64
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $66
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $68
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $6A
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $6C
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $6E
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $70
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $72
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $74
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $76
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $78
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $7A
	NOTE C_, 1
	NOTE D#, 1
	TRANSPOSE_DOWN 1
	WAVE_X $6B
	DETUNE $00
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $02
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $04
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $06
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $08
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $0A
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $0C
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $0E
	NOTE C_, 1
	NOTE D#, 1
	WAVE_X $6C
	DETUNE $10
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $12
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $14
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $16
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $18
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $1A
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $1C
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $1E
	NOTE C_, 1
	NOTE D#, 1
	WAVE_X $6D
	DETUNE $20
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $22
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $24
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $26
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $28
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $2A
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $2C
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $2E
	NOTE C_, 1
	NOTE D#, 1
	WAVE_X $6E
	DETUNE $30
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $32
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $34
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $36
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $38
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $3A
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $3C
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $3E
	NOTE C_, 1
	NOTE D#, 1
	WAVE_X $6F
	DETUNE $40
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $42
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $44
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $46
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $48
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $4A
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $4C
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $4E
	NOTE C_, 1
	NOTE D#, 1
	WAVE_X $70
	DETUNE $50
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $52
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $54
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $56
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $58
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $5A
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $5C
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $5E
	NOTE C_, 1
	NOTE D#, 1
	WAVE_X $71
	DETUNE $60
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $62
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $64
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $66
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $68
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $6A
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $6C
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $6E
	NOTE C_, 1
	NOTE D#, 1
	WAVE_X $72
	DETUNE $70
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $72
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $74
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $76
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $78
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $7A
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $7C
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $7E
	NOTE C_, 1
	NOTE D#, 1
	TRANSPOSE_UP 1
	WAVE_X $73
	DETUNE $10
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $12
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $14
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $16
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $18
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $1A
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $1C
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $1E
	NOTE C_, 1
	NOTE D#, 1
	WAVE_X $74
	DETUNE $20
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $22
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $24
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $26
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $28
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $2A
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $2C
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $2E
	NOTE C_, 1
	NOTE D#, 1
	WAVE_X $75
	DETUNE $30
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $32
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $34
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $36
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $38
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $3A
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $3C
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $3E
	NOTE C_, 1
	NOTE D#, 1
	WAVE_X $76
	DETUNE $40
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $42
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $44
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $46
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $48
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $4A
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $4C
	NOTE C_, 1
	NOTE D#, 1
	DETUNE $4E
	NOTE C_, 1
	NOTE D#, 1
	SND_END

Snd22_SfxN:
	NVOICE $01, $F8
	NOISE $33
	NOISE $75
	NOISE $37
	NOISE $75
	NOISE $35
	NOISE $75
	NOISE $36
	NOISE $75
	NOISE $37
	NOISE $75
	NOISE $67
	NOISE $68
	NOISE $66
	NOISE $62
	NOISE $56
	NOISE $55
	NOISE $54
	NOISE $45
	NOISE $56
	NOISE $65
	NOISE $46
	NOISE $55
	SND_END

Snd23_SfxN:
	SND_SEGNO
	LOOP_START
	NVOICE $01, $F1
	NOISE $32
	NOISE $44
	NOISE $51
	NOISE $51
	NOISE $45
	NOISE $53
	NVOICE $01, $D1
	PAN_LEFT 0
	NOISE $45
	NOISE $53
	NOISE $44
	NOISE $51
	NOISE $45
	NOISE $53
	NVOICE $01, $B1
	PAN_RIGHT 0
	NOISE $32
	NOISE $44
	NOISE $51
	NOISE $51
	NOISE $45
	NOISE $53
	PAN_BOTH 0
	NVOICE $01, $91
	PAN_BOTH 0
	NOISE $32
	NOISE $44
	NOISE $51
	NOISE $51
	NOISE $45
	NOISE $53
	NVOICE $01, $71
	PAN_LEFT 0
	NOISE $45
	NOISE $53
	NOISE $44
	NOISE $51
	NOISE $45
	NOISE $53
	NVOICE $01, $51
	PAN_RIGHT 0
	NOISE $32
	NOISE $44
	NOISE $51
	NOISE $51
	NOISE $45
	NOISE $53
	PAN_BOTH 0
	NVOICE $01, $31
	PAN_BOTH 0
	NOISE $32
	NOISE $44
	NOISE $51
	NOISE $51
	NOISE $45
	NOISE $53
	NVOICE $01, $11
	PAN_LEFT 0
	NOISE $45
	NOISE $53
	NOISE $44
	NOISE $51
	NOISE $45
	NOISE $53
	NVOICE $0F, $00
	NVOICE $01, $F1
	NOISE $33
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $45
	NOISE $54
	NVOICE $01, $D1
	PAN_LEFT 0
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $45
	NOISE $54
	NOISE $53
	NVOICE $01, $B1
	PAN_RIGHT 0
	NOISE $45
	NOISE $53
	NOISE $44
	NOISE $51
	NOISE $45
	NOISE $53
	PAN_BOTH 0
	NVOICE $01, $91
	PAN_BOTH 0
	NOISE $33
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $45
	NOISE $54
	NVOICE $01, $71
	PAN_LEFT 0
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $45
	NOISE $54
	NOISE $53
	NVOICE $01, $51
	PAN_RIGHT 0
	NOISE $45
	NOISE $53
	NOISE $44
	NOISE $51
	NOISE $45
	NOISE $53
	PAN_BOTH 0
	NVOICE $01, $31
	PAN_BOTH 0
	NOISE $33
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $45
	NOISE $54
	NVOICE $01, $11
	PAN_LEFT 0
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $45
	NOISE $54
	NOISE $53
	NVOICE $0F, $00
	LOOP_BREAK $FB
	NVOICE $01, $F1
	NOISE $31
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $45
	NOISE $53
	NVOICE $01, $D1
	PAN_LEFT 0
	NOISE $31
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $45
	NOISE $54
	NVOICE $01, $B1
	PAN_RIGHT 0
	NOISE $45
	NOISE $53
	NOISE $44
	NOISE $51
	NOISE $45
	NOISE $53
	PAN_BOTH 0
	NVOICE $01, $91
	PAN_BOTH 0
	NOISE $31
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $45
	NOISE $53
	NVOICE $01, $71
	PAN_LEFT 0
	NOISE $31
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $45
	NOISE $54
	NVOICE $01, $51
	PAN_RIGHT 0
	NOISE $45
	NOISE $53
	NOISE $44
	NOISE $51
	NOISE $45
	NOISE $53
	PAN_BOTH 0
	NVOICE $01, $31
	PAN_BOTH 0
	NOISE $31
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $45
	NOISE $53
	NVOICE $01, $11
	PAN_LEFT 0
	NOISE $31
	NOISE $44
	NOISE $51
	NOISE $52
	NOISE $45
	NOISE $54
	NVOICE $0F, $00
	LOOP_END $02
	SND_LOOP

Snd24_SfxN:
	SND_SEGNO
	LOOP_START
	NVOICE $01, $10
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $20
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $30
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $40
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $50
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $60
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $70
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $80
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $90
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $A0
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $B0
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $C0
	LOOP2_START
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	LOOP2_END $05
	NVOICE $01, $B0
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $A0
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $90
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $80
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $70
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $60
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $50
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $40
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $30
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $20
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $10
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $0F, $10
	NOISE $00
	NOISE $00
	LOOP_BREAK $FB
	NVOICE $01, $10
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $20
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $30
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $40
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $50
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $60
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $50
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $40
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $30
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $20
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NVOICE $01, $10
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	NOISE $11
	LOOP_END $02
	SND_LOOP

Snd25_SfxN:
	NVOICE $03, $F3
	NOISE $45
	NOISE $47
	NOISE $45
	NOISE $43
	NOISE $42
	NOISE $41
	NVOICE $03, $D3
	NOISE $45
	NOISE $47
	NOISE $45
	NOISE $43
	NOISE $42
	NOISE $41
	NVOICE $03, $B3
	NOISE $45
	NOISE $47
	NOISE $45
	NOISE $43
	NOISE $42
	NOISE $41
	NVOICE $03, $93
	NOISE $45
	NOISE $47
	NOISE $45
	NOISE $43
	NOISE $42
	NOISE $41
	NVOICE $03, $73
	NOISE $45
	NOISE $47
	NOISE $45
	NOISE $43
	NOISE $42
	NOISE $41
	NVOICE $03, $53
	NOISE $45
	NOISE $47
	NOISE $45
	NOISE $43
	NOISE $42
	NOISE $41
	SND_END

Snd26_Sfx1:
	VVOICE $01, $80, $00
	DETUNE $10
	TRANSPOSE_UP 2
	LOOP_START
	OCTAVE 2
	VNOTE C_, 11
	OCTAVE 1
	VNOTE F_, 11
	LOOP_END $30
	VVOICE $01, $80, $00
	DETUNE $10
	DETUNE $FC
	ATTEN 0
	LOOP_START
	OCTAVE 2
	VNOTE C_, 11
	OCTAVE 1
	VNOTE F_, 11
	LOOP_END $04
	DETUNE $F8
	ATTEN 1
	LOOP_START
	OCTAVE 2
	VNOTE C_, 11
	OCTAVE 1
	VNOTE F_, 11
	LOOP_END $04
	DETUNE $F4
	ATTEN 2
	LOOP_START
	OCTAVE 2
	VNOTE C_, 11
	OCTAVE 1
	VNOTE F_, 11
	LOOP_END $04
	DETUNE $F0
	ATTEN 3
	LOOP_START
	OCTAVE 2
	VNOTE C_, 11
	OCTAVE 1
	VNOTE F_, 11
	LOOP_END $04
	DETUNE $EC
	ATTEN 4
	LOOP_START
	OCTAVE 2
	VNOTE C_, 11
	OCTAVE 1
	VNOTE F_, 11
	LOOP_END $04
	DETUNE $E8
	ATTEN 5
	LOOP_START
	OCTAVE 2
	VNOTE C_, 11
	OCTAVE 1
	VNOTE F_, 11
	LOOP_END $04
	SND_END

Snd26_Sfx2:
	VVOICE $01, $E0, $00
	TRANSPOSE_UP 7
	LOOP_START
	OCTAVE 2
	VNOTE G#, 2
	VNOTE D_, 2
	LOOP_END $30
	VVOICE $01, $E0, $00
	DETUNE $FE
	LOOP_START
	OCTAVE 2
	VNOTE G#, 2
	VNOTE D_, 2
	LOOP_END $02
	DETUNE $FC
	WAVE_X $61
	LOOP_START
	VNOTE G#, 2
	VNOTE D_, 2
	LOOP_END $02
	DETUNE $FA
	WAVE_X $62
	LOOP_START
	VNOTE G#, 2
	VNOTE D_, 2
	LOOP_END $02
	DETUNE $F8
	WAVE_X $63
	LOOP_START
	VNOTE G#, 2
	VNOTE D_, 2
	LOOP_END $02
	DETUNE $F6
	WAVE_X $64
	LOOP_START
	VNOTE G#, 2
	VNOTE D_, 2
	LOOP_END $02
	DETUNE $F4
	WAVE_X $65
	LOOP_START
	VNOTE G#, 2
	VNOTE D_, 2
	LOOP_END $02
	DETUNE $F2
	WAVE_X $66
	LOOP_START
	VNOTE G#, 2
	VNOTE D_, 2
	LOOP_END $02
	DETUNE $F0
	ATTEN 1
	WAVE $0E
	LOOP_START
	VNOTE G#, 2
	VNOTE D_, 2
	LOOP_END $02
	DETUNE $EE
	WAVE_X $61
	LOOP_START
	VNOTE G#, 2
	VNOTE D_, 2
	LOOP_END $02
	DETUNE $EC
	WAVE_X $62
	LOOP_START
	VNOTE G#, 2
	VNOTE D_, 2
	LOOP_END $02
	DETUNE $EA
	WAVE_X $63
	LOOP_START
	VNOTE G#, 2
	VNOTE D_, 2
	LOOP_END $02
	DETUNE $E8
	WAVE_X $64
	LOOP_START
	VNOTE G#, 2
	VNOTE D_, 2
	LOOP_END $02
	DETUNE $E6
	WAVE_X $65
	LOOP_START
	VNOTE G#, 2
	VNOTE D_, 2
	LOOP_END $02
	SND_END

Snd3E_Sfx1:
	VOICE $03, 8, 13, 15, 1
	VIBRATO $03, 0, 8
	DUTY_STEP 0, 1
	DETUNE $FF
	OCTAVE 4
	NOTE G_, 2
	SND_END

Snd3F_Sfx1:
	VOICE $01, 8, 15, 15, 1
	DETUNE $FF
	OCTAVE 3
	NOTE C_, 2
	NOTE G_, 2
	SND_END

Snd3F_SfxN:
	NVOICE $02, $F1
	NOISE $12
	NOISE $2E
	SND_END

Snd27_Sfx1:
	VOICE $04, 12, 15, 15, 1
	DUTY_STEP 8, 1
	DETUNE $02
	OCTAVE 5
	NOTE D#, 1
	NOTE G_, 1
	ATTEN 2
	NOTE A#, 1
	RELEASE $0F, 2
	OCTAVE 6
	NOTE D#, 8
	SND_END

Snd28_Sfx1:
	VOICE $04, 12, 15, 15, 1
	DUTY_STEP 8, 1
	DETUNE $02
	OCTAVE 5
	NOTE D#, 1
	NOTE G_, 1
	ATTEN 2
	NOTE A#, 1
	OCTAVE 6
	NOTE D#, 1
	ATTEN 4
	OCTAVE 5
	NOTE D#, 1
	NOTE G_, 1
	ATTEN 6
	NOTE A#, 1
	OCTAVE 6
	NOTE D#, 1
	VOICE $04, 12, 7, 15, 1
	ATTEN 0
	OCTAVE 5
	NOTE D#, 1
	NOTE G_, 1
	ATTEN 2
	NOTE A#, 1
	OCTAVE 6
	NOTE D#, 1
	SND_END

Snd29_Sfx1:
	VOICE $04, 0, 15, 15, 1
	DUTY_STEP 8, 1
	DETUNE $02
	OCTAVE 6
	NOTE D#, 1
	OCTAVE 5
	NOTE B_, 1
	ATTEN 2
	NOTE A#, 1
	NOTE D#, 1
	TRANSPOSE_DOWN 1
	ATTEN 4
	OCTAVE 6
	NOTE D#, 1
	OCTAVE 5
	NOTE B_, 1
	ATTEN 6
	NOTE A#, 1
	NOTE D#, 1
	VOICE $04, 12, 7, 15, 1
	TRANSPOSE_DOWN 2
	ATTEN 0
	OCTAVE 6
	NOTE D#, 1
	OCTAVE 5
	NOTE B_, 1
	ATTEN 2
	NOTE A#, 1
	NOTE D#, 1
	SND_END

Snd2A_Sfx1:
	VOICE $02, 4, 15, 0, 0
	TRANSPOSE_UP $0C
	DETUNE $02
	OCTAVE 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	VOICE $02, 4, 12, 0, 0
	OCTAVE 2
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	VOICE $02, 4, 11, 0, 0
	TRANSPOSE_UP $0C
	OCTAVE 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	VOICE $02, 4, 8, 0, 0
	OCTAVE 2
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	VOICE $02, 4, 7, 0, 0
	TRANSPOSE_UP $0C
	OCTAVE 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	VOICE $02, 4, 4, 0, 0
	OCTAVE 2
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	SND_END

Snd2A_SfxN:
	NVOICE $02, $F0
	NOISE $51
	NOISE $62
	NOISE $55
	NVOICE $02, $F1
	NOISE $31
	NOISE $22
	NOISE $13
	NOISE $11
	NVOICE $02, $C0
	NOISE $51
	NOISE $62
	NOISE $55
	NVOICE $02, $C1
	NOISE $31
	NOISE $22
	NOISE $13
	NOISE $11
	NVOICE $02, $90
	NOISE $51
	NOISE $62
	NOISE $55
	NVOICE $02, $91
	NOISE $31
	NOISE $22
	NOISE $13
	NOISE $11
	NVOICE $02, $60
	NOISE $51
	NOISE $62
	NOISE $55
	NVOICE $02, $61
	NOISE $31
	NOISE $22
	NOISE $13
	NOISE $11
	SND_END

Snd2B_SfxN:
	NVOICE $02, $F0
	NOISE $51
	NOISE $42
	NOISE $55
	NVOICE $01, $D3
	NOISE $42
	NOISE $41
	NVOICE $11, $B2
	NOISE $21
	SND_END

Snd2C_SfxN:
	NVOICE $02, $E0
	NOISE $11
	NOISE $12
	SND_END

Snd2D_SfxN:
	NVOICE $02, $E1
	NOISE $59
	NOISE $2D
	NOISE $58
	NOISE $3D
	NOISE $0F
	NOISE $0F
	LOOP_START
	NVOICE $01, $D1
	NOISE $59
	NOISE $2D
	NOISE $58
	NOISE $3D
	NOISE $59
	NOISE $2C
	NOISE $3B
	NOISE $0F
	NOISE $0F
	LOOP2_START
	NOISE $0F
	NVOICE $02, $F1
	NOISE $49
	NOISE $4D
	NOISE $48
	NOISE $2D
	NOISE $00
	NOISE $08
	NVOICE $01, $B1
	NOISE $3B
	NOISE $2C
	NOISE $58
	NOISE $5D
	NOISE $59
	NOISE $2D
	NOISE $59
	LOOP2_END $02
	NVOICE $04, $D1
	NOISE $48
	NOISE $2D
	NVOICE $01, $C1
	NOISE_VOL 9
	NOISE $59
	NOISE $3D
	NOISE $38
	NOISE $4D
	NOISE $59
	NOISE $2C
	NOISE $3B
	NOISE $05
	NOISE $0F
	LOOP_END $02
	SND_END

Snd2E_SfxN:
	NVOICE $01, $F0
	NOISE $42
	NOISE $53
	NOISE $65
	NOISE $63
	NOISE $44
	NOISE $64
	NVOICE $03, $F2
	NOISE $61
	NOISE $63
	NOISE $75
	NVOICE $03, $92
	NOISE $61
	NOISE $63
	NOISE $75
	NVOICE $03, $42
	NOISE $61
	NOISE $63
	NOISE $75
	SND_END

Snd2F_SfxN:
	NVOICE $01, $F0
	NOISE $42
	NOISE $53
	NOISE $65
	NOISE $63
	NOISE $44
	NOISE $64
	NVOICE $11, $D2
	NOISE $51
	NOISE $42
	SND_END

Snd30_Sfx1:
	VOICE $01, 4, 15, 0, 0
	TRANSPOSE_UP 4
	OCTAVE 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	ATTEN 2
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	ATTEN 4
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	ATTEN 6
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	VOICE $01, 4, 6, 0, 0
	ATTEN 0
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	ATTEN 2
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	SND_END

Snd30_SfxN:
	NVOICE $04, $F3
	NOISE $23
	NOISE $63
	NOISE $63
	NOISE $64
	NOISE $55
	NOISE $63
	NOISE $63
	NOISE $64
	NOISE $55
	SND_END

Snd32_Sfx1:
	VOICE $01, 4, 11, 15, 1
	DUTY_STEP 8, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	ATTEN 2
	NOTE G_, 1
	NOTE A_, 1
	ATTEN 4
	NOTE G_, 1
	NOTE A_, 1
	SND_END

Snd32_SfxN:
	NVOICE $02, $F0
	NOISE $53
	NOISE $63
	NVOICE $02, $F1
	NOISE $23
	NVOICE $02, $D0
	NOISE $53
	NOISE $63
	NVOICE $02, $D1
	NOISE $23
	NVOICE $02, $B1
	NOISE $53
	NOISE $63
	SND_END

Snd34_Sfx1:
	VOICE $01, 0, 15, 15, 1
	DETUNE $FF
	OCTAVE 5
	NOTE F#, 2
	NOTE A_, 4
	VOICE $02, 0, 13, 15, 1
	OCTAVE 6
	NOTE C_, 2
	NOTE D#, 4
	VOICE $02, 0, 11, 15, 1
	OCTAVE 5
	NOTE D#, 2
	NOTE F#, 4
	VOICE $02, 0, 9, 15, 2
	NOTE A_, 2
	OCTAVE 6
	NOTE C_, 4
	VOICE $02, 0, 7, 15, 2
	OCTAVE 5
	NOTE C_, 2
	NOTE D#, 4
	VOICE $02, 0, 5, 15, 2
	NOTE F#, 2
	NOTE A_, 4
	SND_END

Snd34_SfxN:
	NVOICE $04, $F0
	NOISE $08
	NOISE $06
	NOISE $09
	NOISE_VOL 9
	NOISE $08
	NOISE_VOL 5
	NOISE $09
	NVOICE $04, $80
	NOISE $08
	NOISE $06
	NOISE $09
	NOISE_VOL 9
	NOISE $08
	NOISE_VOL 5
	NOISE $09
	NVOICE $04, $40
	NOISE $08
	NOISE $06
	NOISE $09
	NOISE_VOL 9
	NOISE $08
	NOISE_VOL 5
	NOISE $09
	SND_END

Snd35_Sfx1:
	VOICE $01, 0, 15, 15, 1
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 6
	NOTE C_, 4
	VOICE $02, 0, 13, 15, 1
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 6
	NOTE C_, 4
	VOICE $01, 0, 11, 15, 1
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 6
	NOTE C_, 4
	VOICE $02, 0, 9, 15, 1
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 6
	NOTE C_, 4
	VOICE $01, 0, 7, 15, 1
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 6
	NOTE C_, 4
	VOICE $02, 0, 5, 15, 1
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 6
	NOTE C_, 4
	SND_END

Snd35_SfxN:
	NVOICE $04, $F0
	NOISE $08
	NOISE $06
	NOISE $09
	NOISE_VOL 9
	NOISE $08
	NOISE_VOL 5
	NOISE $09
	NVOICE $04, $80
	NOISE $08
	NOISE $06
	NOISE $09
	NOISE_VOL 9
	NOISE $08
	NOISE_VOL 5
	NOISE $09
	NVOICE $04, $40
	NOISE $08
	NOISE $06
	NOISE $09
	NOISE_VOL 9
	NOISE $08
	NOISE_VOL 5
	NOISE $09
	SND_END

Snd33_Sfx1:
	VOICE $01, 0, 15, 15, 1
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 6
	NOTE C_, 4
	VOICE $02, 0, 13, 15, 1
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 6
	NOTE C_, 4
	SND_END

Snd33_SfxN:
	NVOICE $04, $F0
	NOISE $08
	NOISE $06
	NOISE $09
	NOISE_VOL 9
	NOISE $08
	NOISE_VOL 5
	NOISE $09
	NVOICE $04, $80
	NOISE_VOL 9
	NOISE $08
	NOISE_VOL 5
	NOISE $09
	SND_END

Snd36_SfxN:
	NVOICE $03, $B1
	NOISE $2E
	NVOICE $01, $D1
	NOISE $13
	NOISE $12
	SND_END

Snd37_SfxN:
	NVOICE $03, $F4
	NOISE $69
	NOISE $68
	NOISE $69
	NOISE $67
	NOISE $56
	NOISE $55
	NOISE $54
	NOISE $53
	NOISE $44
	NOISE $34
	NOISE $41
	NOISE $34
	NOISE $24
	NOISE $22
	NOISE $21
	NOISE $13
	NOISE $12
	NOISE $11
	NOISE $12
	NOISE $11
	SND_END

Snd38_Sfx1:
	VOICE $01, 4, 15, 13, 3
	DETUNE $FA
	DUTY_STEP 0, 1
	TRANSPOSE_UP 2
	OCTAVE 3
	NOTE E_, 1
	ATTEN 1
	NOTE D#, 1
	ATTEN 2
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	DETUNE $00
	SND_END

Snd39_Sfx1:
	VOICE $01, 4, 15, 13, 2
	VIBRATO $03, 0, 13
	DUTY_STEP 0, 1
	TRANSPOSE_UP 4
	OCTAVE 2
	NOTE E_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE G_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 2
	NOTE F_, 1
	VIBRATO_OFF
	SND_END

Snd3A_Sfx1:
	VOICE $01, 4, 15, 13, 2
	DETUNE $FA
	TRANSPOSE_UP 3
	OCTAVE 2
	LOOP_START
	NOTE A_, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	LOOP_END $02
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	ATTEN 1
	NOTE D#, 1
	NOTE D_, 1
	ATTEN 2
	NOTE C#, 1
	NOTE C_, 1
	ATTEN 3
	OCTAVE 1
	NOTE B_, 1
	NOTE A#, 1
	ATTEN 4
	NOTE A_, 1
	NOTE G#, 1
	ATTEN 5
	NOTE G_, 1
	NOTE F#, 1
	ATTEN 6
	NOTE F_, 1
	NOTE E_, 1
	ATTEN 7
	NOTE D#, 1
	NOTE D_, 1
	ATTEN 8
	NOTE C#, 1
	NOTE C_, 1
	DETUNE $00
	SND_END

Snd3A_SfxN:
	NVOICE $01, $F0
	NOISE $42
	NOISE $51
	NOISE $52
	NVOICE $01, $F1
	NOISE $61
	NOISE $64
	NOISE $71
	NOISE $73
	NOISE $74
	NOISE $81
	NOISE $82
	SND_END

Snd3B_SfxN:
	NVOICE $02, $80
	NOISE $25
	NVOICE $02, $B0
	NOISE $24
	NVOICE $02, $D1
	NOISE $23
	NOISE $25
	NOISE $31
	NOISE $32
	SND_END

Snd3C_SfxN:
	NVOICE $82, $F0
	NOISE $41
	NOISE $42
	NVOICE $01, $F1
	NOISE $41
	NOISE $32
	NOISE $31
	SND_END

Snd3D_Sfx1:
	VOICE $03, 0, 15, 15, 1
	DETUNE $FA
	DUTY_STEP 8, 1
	OCTAVE 6
	NOTE G_, 1
	NOTE G_, 5
	SND_END

Snd40_SfxN:
	NVOICE $04, $F2
	NOISE $12
	NOISE $22
	NOISE $23
	NOISE $11
	NOISE $24
	NOISE $12
	NOISE $22
	NOISE $25
	SND_END

Snd31_SfxN:
	NVOICE $03, $F3
	NOISE $45
	NOISE $47
	NOISE $45
	NOISE $43
	NOISE $42
	NOISE $41
	NVOICE $03, $A3
	NOISE $45
	NOISE $47
	NOISE $45
	NOISE $43
	NOISE $42
	NOISE $41
	NVOICE $03, $53
	NOISE $45
	NOISE $47
	NOISE $45
	NOISE $43
	NOISE $42
	NOISE $41
	SND_END

Snd41_SfxN:
	NVOICE $01, $F0
	NOISE $33
	SND_END

Snd42_SfxN:
	NVOICE $01, $F0
	NOISE $55
	NOISE $44
	NOISE $33
	NOISE $22
	NOISE $11
	NOISE_VOLNOTE $0C
	NOISE $11
	NOISE_VOLNOTE $0A
	NOISE $11
	NOISE_VOLNOTE 8
	NOISE $11
	NOISE_VOLNOTE 5
	NOISE $11
	SND_END

Snd43_SfxN:
	NVOICE $03, $F0
	NOISE $21
	NVOICE $01, $D0
	NOISE $35
	NOISE_VOLNOTE $0B
	NOISE $41
	NOISE_VOLNOTE $0A
	NOISE $42
	NVOICE $02, $91
	NOISE $53
	SND_END

Snd44_SfxN:
	NVOICE $01, $F1
	NOISE $2F
	NOISE $2D
	NOISE $11
	SND_END

Snd45_SfxN:
	NVOICE $01, $F1
	NOISE $12
	NOISE $13
	NOISE $11
	NOISE $24
	NOISE_VOLNOTE $0D
	NOISE $34
	NOISE_VOLNOTE $0C
	NOISE $42
	NOISE_VOLNOTE $0B
	NOISE $44
	NOISE_VOLNOTE 6
	NOISE $54
	SND_END

Snd46_Sfx1:
	VOICE $01, 12, 11, 0, 0
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	ATTEN 4
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	ATTEN 8
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_HI, 1
	SND_END

Snd47_Sfx1:
	VOICE $01, 12, 15, 0, 0
	VIBRATO $0D, 0, 15
	OCTAVE 3
	NOTE C_, 0
	VOICE $01, 12, 12, 0, 0
	OCTAVE 3
	NOTE F_, 0
	VOICE $01, 12, 9, 15, 3
	OCTAVE 4
	NOTE C_, 8
	SND_END

Snd47_Sfx2:
	VOICE $01, 4, 2, 0, 0
	VIBRATO $0D, 0, 15
	DETUNE $FE
	OCTAVE 3
	NOTE C_, 0
	VOICE $01, 4, 2, 0, 0
	OCTAVE 3
	NOTE F_, 0
	VOICE $01, 4, 4, 15, 3
	OCTAVE 4
	NOTE C_, 8
	SND_END

Snd48_Sfx1:
	VOICE $01, 8, 15, 15, 2
	DUTY_STEP $0C, 1
	DETUNE $FF
	VIBRATO $0D, 0, 12
	OCTAVE 3
	NOTE C_, 4
	ATTEN 3
	NOTE C_HI, 4
	ATTEN 6
	OCTAVE 5
	NOTE C_, 4
	ATTEN 8
	OCTAVE 6
	NOTE C_, 4
	VOICE $01, 8, 12, 15, 2
	ATTEN 0
	OCTAVE 3
	NOTE C_, 4
	ATTEN 2
	NOTE C_HI, 4
	ATTEN 4
	OCTAVE 5
	NOTE C_, 4
	ATTEN 6
	OCTAVE 6
	NOTE C_, 4
	VOICE $01, 8, 10, 15, 2
	ATTEN 0
	OCTAVE 3
	NOTE C_, 4
	ATTEN 2
	NOTE C_HI, 4
	ATTEN 4
	OCTAVE 5
	NOTE C_, 4
	ATTEN 6
	OCTAVE 6
	NOTE C_, 4
	SND_END

Snd48_Sfx2:
	VOICE $04, 1, 2, 15, 1
	VIBRATO $0D, 0, 12
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 6
	NOTE C_, 1
	SND_END

Snd49_Sfx1:
	VOICE $02, 8, 10, 0, 0
	DETUNE $FF
	OCTAVE 4
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	ATTEN 3
	OCTAVE 4
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	ATTEN 6
	OCTAVE 4
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	ATTEN 8
	OCTAVE 4
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	SND_END

Snd49_Sfx2:
	VOICE $02, 1, 2, 0, 0
	REST 1
	OCTAVE 5
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	ATTEN 1
	OCTAVE 5
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	ATTEN 2
	OCTAVE 5
	NOTE E_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	SND_END

Snd4A_Sfx1:
	VOICE $01, 0, 15, 0, 0
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	VOICE $01, 0, 15, 0, 0
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	SND_END

Snd4B_Sfx2:
	VOICE $05, 14, 2, 8, 6
	OCTAVE 4
	NOTE C_, 1
	NOTE C_HI, 1
	ATTEN 1
	NOTE C_, 1
	NOTE C_HI, 1
	ATTEN 2
	NOTE C_, 1
	NOTE C_HI, 1
	SND_END

Snd4B_SfxN:
	NVOICE $05, $F1
	NOISE $48
	NOISE $38
	NVOICE $05, $A1
	NOISE $48
	NOISE $38
	NVOICE $05, $51
	NOISE $48
	NOISE $38
	SND_END

Snd4C_SfxN:
	NVOICE $03, $90
	LOOP_START
	NOISE $65
	NOISE $63
	NOISE $61
	NOISE $63
	NOISE $65
	NOISE $45
	NOISE $43
	NOISE $41
	NOISE $43
	NOISE $45
	LOOP_END $03
	SND_END

Snd4D_SfxN:
	NVOICE $03, $96
	NOISE $25
	NOISE $22
	NOISE $21
	NOISE $23
	NOISE $24
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $23
	NOISE $21
	NOISE $23
	NOISE $25
	NOISE $21
	NOISE $22
	NOISE $21
	NOISE $25
	NOISE $22
	NOISE $21
	NOISE $23
	NOISE $24
	SND_END

Snd4E_SfxN:
	NVOICE $06, $F5
	NOISE $57
	NOISE $68
	NVOICE $03, $F1
	NOISE $47
	NOISE $44
	NOISE $42
	NOISE $41
	SND_END

Snd4F_SfxN:
	NVOICE $06, $F5
	NOISE $57
	NOISE $68
	NOISE $47
	NOISE $44
	NOISE $42
	NOISE $41
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $36
	NOISE $33
	NOISE $31
	SND_END

Snd50_SfxN:
	NVOICE $06, $F2
	NOISE $45
	NOISE $47
	NOISE $45
	NOISE $43
	SND_END

Snd51_Sfx1:
	VOICE $01, 8, 15, 15, 1
	TRANSPOSE_UP $0C
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	ATTEN 2
	NOTE A#, 1
	ATTEN 2
	NOTE A_, 1
	SND_END

Snd51_SfxN:
	NVOICE $11, $F1
	NOISE $37
	SND_END

Snd52_SfxN:
	NVOICE $01, $F1
	NOISE $42
	NOISE $53
	NOISE $52
	NOISE $44
	NVOICE $11, $F1
	NOISE $11
	SND_END

Snd53_Sfx2:
	VOICE $04, 14, 2, 14, 1
	OCTAVE 3
	NOTE G_, 1
	SND_END

Snd53_SfxN:
	NVOICE $01, $F0
	NOISE $13
	NOISE_VOL $0C
	NOISE $22
	NOISE_VOL 9
	NOISE $11
	NVOICE $02, $72
	NOISE $21
	NOISE_VOLNOTE 2
	NOISE_VOLNOTE 1
	SND_END

Snd54_SfxN:
	NVOICE $01, $F0
	NOISE $27
	NOISE_VOL $0D
	NOISE $37
	NOISE_VOL $0B
	NOISE $25
	NVOICE $02, $92
	NOISE $27
	NOISE_VOLNOTE 2
	NOISE_VOLNOTE 1
	SND_END

Snd55_SfxN:
	NVOICE $03, $A0
	NOISE $38
	SND_END

Snd55_Sfx1:
	VOICE $03, 4, 15, 0, 0
	VIBRATO $03, 0, 3
	OCTAVE 4
	NOTE C_, 1
	VOICE $02, 4, 9, 15, 3
	OCTAVE 3
	NOTE B_, 1
	SND_END

Snd56_SfxN:
	NVOICE $03, $A0
	NOISE $38
	SND_END

Snd56_Sfx1:
	VOICE $03, 4, 15, 0, 0
	VIBRATO $03, 0, 3
	OCTAVE 3
	NOTE C_, 1
	VOICE $02, 4, 9, 15, 3
	OCTAVE 2
	NOTE B_, 1
	SND_END

Snd58_SfxN:
	NVOICE $06, $B2
	NOISE $48
	NOISE $48
	NOISE $48
	NOISE $48
	NVOICE $06, $92
	NOISE $48
	NOISE $48
	NOISE $48
	NOISE $48
	NVOICE $06, $62
	NOISE $48
	NOISE $48
	NOISE $48
	NOISE $48
	NVOICE $06, $32
	NOISE $48
	NOISE $48
	NOISE $48
	SND_END

Snd58_Sfx1:
	VOICE $06, 4, 15, 0, 0
	VIBRATO $03, 0, 3
	OCTAVE 3
	NOTE C_, 1
	VOICE $06, 4, 15, 15, 1
	OCTAVE 2
	NOTE B_, 3
	VOICE $06, 4, 12, 0, 0
	VIBRATO $03, 0, 3
	OCTAVE 3
	NOTE C_, 1
	VOICE $06, 4, 12, 15, 1
	OCTAVE 2
	NOTE B_, 3
	VOICE $06, 4, 9, 0, 0
	VIBRATO $03, 0, 3
	OCTAVE 3
	NOTE C_, 1
	VOICE $06, 4, 9, 15, 1
	OCTAVE 2
	NOTE B_, 3
	VOICE $06, 4, 6, 0, 0
	VIBRATO $03, 0, 3
	OCTAVE 3
	NOTE C_, 1
	VOICE $06, 4, 6, 15, 1
	OCTAVE 2
	NOTE B_, 2
	SND_END

Snd57_SfxN:
	NVOICE $06, $B2
	NOISE $38
	NOISE $38
	NOISE $38
	NOISE $38
	NVOICE $06, $92
	NOISE $38
	NOISE $38
	NOISE $38
	NOISE $38
	NVOICE $06, $62
	NOISE $38
	NOISE $38
	NOISE $38
	NOISE $38
	NVOICE $06, $32
	NOISE $38
	NOISE $38
	NOISE $38
	SND_END

Snd57_Sfx1:
	VOICE $06, 4, 15, 0, 0
	VIBRATO $03, 0, 3
	OCTAVE 4
	NOTE C_, 1
	VOICE $06, 4, 15, 15, 1
	OCTAVE 3
	NOTE B_, 3
	VOICE $06, 4, 12, 0, 0
	VIBRATO $03, 0, 3
	OCTAVE 4
	NOTE C_, 1
	VOICE $06, 4, 12, 15, 1
	OCTAVE 3
	NOTE B_, 3
	VOICE $06, 4, 9, 0, 0
	VIBRATO $03, 0, 3
	OCTAVE 4
	NOTE C_, 1
	VOICE $06, 4, 9, 15, 1
	OCTAVE 3
	NOTE B_, 3
	VOICE $06, 4, 6, 0, 0
	VIBRATO $03, 0, 3
	OCTAVE 4
	NOTE C_, 1
	VOICE $06, 4, 6, 15, 1
	OCTAVE 3
	NOTE B_, 2
	SND_END

Snd59_SfxN:
	NVOICE $01, $F0
	NOISE $74
	NOISE $63
	NOISE $84
	NOISE $61
	NOISE $65
	NOISE $63
	NOISE $61
	NOISE $12
	NOISE $14
	NOISE $12
	NOISE $13
	NOISE $11
	NOISE $11
	NOISE_VOLNOTE $0B
	NOISE $12
	NOISE $14
	NOISE $12
	NOISE $13
	NOISE $11
	NOISE_VOLNOTE 8
	NOISE $12
	NOISE $14
	NOISE $12
	NOISE $13
	NOISE $11
	NOISE_VOLNOTE 5
	NOISE $12
	NOISE $14
	NOISE $12
	NOISE $13
	NOISE $11
	NOISE_VOLNOTE 3
	NOISE $12
	NOISE $14
	NOISE $12
	NOISE $13
	NOISE $11
	SND_END

Snd5A_Sfx1:
	VOICE $01, 0, 15, 15, 1
	DETUNE $19
	VIBRATO $01, 0, 10
	OCTAVE 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	NOTE C_, 1
	NOTE C_HI, 1
	ATTEN 1
	NOTE C_, 1
	NOTE C#, 1
	ATTEN 2
	NOTE C_, 1
	NOTE C#, 1
	ATTEN 3
	NOTE C_, 1
	NOTE C#, 1
	ATTEN 4
	NOTE C_, 1
	NOTE C#, 1
	ATTEN 5
	NOTE C_, 1
	NOTE C#, 1
	ATTEN 6
	NOTE C_, 1
	NOTE C#, 1
	ATTEN 7
	NOTE C_, 1
	NOTE C#, 1
	ATTEN 8
	NOTE C_, 1
	NOTE C#, 1
	SND_END

Snd5A_SfxN:
	NVOICE $05, $F4
	NOISE $57
	NOISE $56
	NOISE $55
	NOISE $54
	NOISE $55
	NOISE $54
	NOISE $55
	NOISE $54
	SND_END

Snd5B_Sfx1:
	LOOP_START
	VOICE $01, 8, 15, 0, 0
	DETUNE $FA
	OCTAVE 2
	NOTE C_, 1
	NOTE C_HI, 1
	ATTEN 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_HI, 1
	ATTEN 3
	OCTAVE 2
	NOTE C_, 1
	NOTE C_HI, 1
	ATTEN 5
	OCTAVE 2
	NOTE C_, 1
	NOTE C_HI, 1
	ATTEN 7
	OCTAVE 2
	NOTE C_, 1
	NOTE C_HI, 1
	VOICE $01, 8, 6, 0, 0
	DETUNE $FA
	OCTAVE 2
	NOTE C_, 1
	NOTE C_HI, 1
	LOOP_END $05
	SND_END

Snd5B_SfxN:
	NVOICE $02, $F0
	NOISE $74
	NOISE $63
	NVOICE $01, $F2
	NOISE $42
	NOISE $44
	NOISE $52
	NOISE $53
	NOISE $54
	NOISE $51
	NOISE $55
	NVOICE $02, $E0
	NOISE $74
	NOISE $63
	NVOICE $01, $E2
	NOISE $42
	NOISE $44
	NOISE $52
	NOISE $53
	NOISE $54
	NOISE $51
	NOISE $55
	NVOICE $02, $D0
	NOISE $74
	NOISE $63
	NVOICE $01, $D2
	NOISE $52
	NOISE $53
	NOISE $54
	NOISE $51
	NOISE $55
	NVOICE $02, $B0
	NOISE $74
	NOISE $63
	NVOICE $01, $B2
	NOISE $52
	NOISE $53
	NOISE $54
	NOISE $51
	NOISE $55
	NVOICE $02, $A0
	NOISE $74
	NOISE $63
	NVOICE $01, $A2
	NOISE $52
	NOISE $53
	NOISE $54
	NOISE $51
	NOISE $55
	NVOICE $02, $91
	NOISE $41
	NOISE $33
	NOISE $32
	NOISE $23
	SND_END

Snd5C_SfxN:
	NVOICE $02, $D0
	NOISE $74
	NOISE $63
	NOISE $84
	NOISE $61
	NOISE $65
	NOISE $63
	NOISE $61
	NOISE $52
	NOISE $53
	NOISE $54
	NOISE_VOL $0C
	NOISE $51
	NOISE $55
	NOISE_VOL $0B
	NOISE $41
	NOISE $42
	NOISE $41
	NOISE_VOL $0A
	NOISE $42
	NOISE $44
	NOISE_VOL 9
	NOISE $34
	NOISE $32
	NOISE $33
	NOISE_VOL 8
	NOISE $31
	NOISE $34
	NOISE_VOL 7
	NOISE $34
	NOISE $32
	NOISE $33
	NOISE_VOL 6
	NOISE $31
	NOISE $34
	NOISE_VOL 5
	NOISE $21
	NOISE $42
	NOISE $21
	NOISE_VOL 4
	NOISE $22
	NOISE $24
	NOISE_VOL 3
	NOISE $12
	NOISE $13
	NOISE $14
	NOISE_VOL 2
	NOISE $11
	NOISE $15
	SND_END

Snd5D_SfxN:
	NVOICE $01, $F1
	NOISE $12
	NOISE $22
	NOISE $33
	NOISE $22
	NOISE $11
	NVOICE $01, $D1
	NOISE $12
	NOISE $22
	NOISE $33
	NOISE $22
	NOISE $11
	NVOICE $01, $B1
	NOISE $12
	NOISE $22
	NOISE $33
	NOISE $22
	NOISE $11
	SND_END

Snd5E_SfxN:
	NVOICE $01, $B1
	NOISE $12
	NOISE $22
	NOISE $33
	NOISE $22
	NOISE $11
	NVOICE $01, $D1
	NOISE $12
	NOISE $22
	NOISE $33
	NOISE $22
	NOISE $11
	NVOICE $01, $F1
	NOISE $12
	NOISE $22
	NOISE $33
	NOISE $22
	NOISE $11
	SND_END

Snd5F_Sfx1:
	VOICE $01, 12, 14, 0, 0
	TRANSPOSE_UP 1
	OCTAVE 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	REST 2
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	SND_END

Snd5F_Sfx2:
	VOICE $01, 9, 2, 0, 0
	TRANSPOSE_UP $0C
	DETUNE $30
	OCTAVE 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	REST 2
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	SND_END

Snd60_Sfx1:
	VOICE $01, 8, 15, 0, 0
	TRANSPOSE_DOWN 2
	OCTAVE 4
	NOTE G_, 1
	ATTEN 2
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE E_, 1
	ATTEN 4
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	SND_END

Snd61_Sfx1:
	VOICE $01, 8, 9, 15, 1
	OCTAVE 4
	NOTE G_, 2
	OCTAVE 5
	NOTE C_, 2
	NOTE G_, 2
	SND_END

Snd62_Sfx1:
	VOICE $01, 8, 12, 14, 1
	DETUNE $FE
	OCTAVE 4
	NOTE C_, 1
	NOTE C_HI, 1
	ATTEN 2
	NOTE C_, 1
	NOTE C_HI, 1
	ATTEN 4
	NOTE C_, 1
	NOTE C_HI, 1
	ATTEN 6
	NOTE C_, 1
	NOTE C_HI, 1
	ATTEN 8
	NOTE C_, 1
	NOTE C_HI, 1
	VOICE $01, 8, 2, 14, 1
	ATTEN 0
	NOTE C_, 1
	NOTE C_HI, 1
	DETUNE $00
	SND_END

Snd63_Sfx1:
	VOICE $03, 8, 15, 15, 1
	DETUNE $F0
	TRANSPOSE_UP 5
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	ATTEN 4
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	ATTEN 7
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	VOICE $03, 8, 5, 14, 1
	ATTEN 0
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	ATTEN 2
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	DETUNE $00
	SND_END

Snd64_Sfx2:
	SND_END

SECTION "Sound bank $0D", ROMX[$4000], BANK[$0D]

Snd6D_Ch2:
	SND_SEGNO
	VOICE $08, 8, 7, 0, 0
	DETUNE $01
	VIBRATO $01, 2, 3
	ENVELOPE $09
	OCTAVE 3
	NOTE F#, 12
	ENVELOPE $00
	RELEASE 7, 5
	NOTE G#, 12
	RELEASE 0, 0
	ENVELOPE $09
	NOTE A#, 12
	ENVELOPE $00
	NOTE B_, 4
	NOTE A#, 4
	ATTEN 1
	NOTE G#, 4
	LOOP_START
	VOICE $08, 8, 6, 9, 2
	DETUNE $00
	VIBRATO_OFF
	ENVELOPE $0C
	OCTAVE 2
	NOTE A#, 2
	ENVELOPE $00
	RELEASE 0, 0
	OCTAVE 4
	VIBRATO $04, 0, 1
	NOTE A#, 2
	VIBRATO_OFF
	NOTE G#, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 2
	RELEASE 9, 2
	NOTE F_, 4
	VIBRATO $01, 2, 2
	RELEASE 0, 0
	NOTE A#, 8
	RELEASE 9, 2
	NOTE D#, 4
	RELEASE 0, 0
	NOTE A#, 8
	NOTE G#, 2
	RELEASE 9, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 2
	RELEASE 7, 1
	NOTE D_, 4
	RELEASE 0, 0
	VIBRATO $04, 0, 1
	NOTE B_, 2
	VIBRATO $01, 0, 2
	NOTE B_, 2
	VIBRATO $01, 2, 2
	NOTE A#, 4
	NOTE G#, 4
	LOOP_BREAK $FB
	RELEASE 5, 4
	NOTE F#, 8
	RELEASE 0, 0
	VIBRATO $01, 2, 2
	NOTE A#, 4
	VIBRATO $04, 0, 1
	NOTE A_, 2
	VIBRATO $01, 0, 2
	NOTE A_, 2
	VIBRATO $01, 2, 2
	NOTE F_, 4
	NOTE C_, 4
	NOTE D#, 4
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 4
	LOOP_END $02
	NOTE F#, 4
	NOTE G#, 4
	NOTE A#, 4
	NOTE A_, 4
	NOTE F_, 4
	VIBRATO $04, 0, 1
	OCTAVE 5
	NOTE D#, 2
	VIBRATO $01, 0, 2
	NOTE D#, 2
	VIBRATO_OFF
	RELEASE 9, 1
	NOTE D_, 2
	RELEASE 0, 0
	OCTAVE 4
	NOTE B_, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE F_, 2
	VOICE $08, 8, 8, 0, 0
	ATTEN 2
	VIBRATO $01, 2, 3
	ENVELOPE $1A
	OCTAVE 3
	NOTE D#, 8
	ENVELOPE $00
	NOTE A#, 4
	ATTEN 0
	ATTEN 1
	VIBRATO $01, 2, 3
	ENVELOPE $1A
	OCTAVE 3
	NOTE G#, 8
	ENVELOPE $00
	VIBRATO $01, 2, 2
	OCTAVE 4
	NOTE C#, 4
	ATTEN 0
	VIBRATO $01, 2, 3
	ENVELOPE $1A
	OCTAVE 3
	NOTE A#, 8
	ENVELOPE $00
	VIBRATO $01, 2, 2
	OCTAVE 4
	NOTE D#, 4
	ATTEN 1
	ENVELOPE $1A
	NOTE F_, 8
	ATTEN 0
	ENVELOPE $00
	VIBRATO_OFF
	NOTE D#, 2
	NOTE F_, 2
	VIBRATO $01, 2, 2
	NOTE F#, 4
	NOTE G#, 4
	NOTE A#, 4
	NOTE F_, 8
	ATTEN 2
	NOTE C#, 4
	NOTE D#, 8
	NOTE C_, 4
	ATTEN 2
	NOTE D_, 4
	ATTEN 1
	NOTE D#, 4
	ATTEN 0
	NOTE F_, 4
	NOTE F#, 8
	NOTE D#, 4
	NOTE A#, 8
	NOTE C#, 4
	NOTE D#, 4
	NOTE C#, 4
	OCTAVE 3
	NOTE G#, 4
	RELEASE 5, 5
	NOTE A#, 12
	RELEASE 0, 0
	OCTAVE 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE F#, 4
	NOTE F_, 8
	NOTE C#, 4
	NOTE D#, 12
	RELEASE 5, 5
	VIBRATO $01, 0, 2
	NOTE D#, 12
	VIBRATO_OFF
	SND_LOOP

Snd6D_Ch1:
	SND_SEGNO
	VOICE $08, 8, 8, 0, 0
	DETUNE $FF
	VIBRATO $01, 2, 3
	ENVELOPE $09
	OCTAVE 3
	NOTE D#, 12
	ENVELOPE $00
	RELEASE 7, 5
	NOTE F_, 12
	RELEASE 0, 0
	ENVELOPE $09
	NOTE F#, 12
	ENVELOPE $00
	NOTE G#, 4
	ATTEN 1
	NOTE F#, 4
	NOTE F_, 4
	LOOP_START
	VOICE $08, 0, 10, 0, 0
	DETUNE $00
	VIBRATO $01, 2, 4
	OCTAVE 2
	NOTE F#, 4
	DUTY 8
	VIBRATO $01, 2, 3
	NOTE A#, 8
	OCTAVE 3
	NOTE C#, 2
	RELEASE 9, 2
	NOTE D#, 2
	RELEASE 0, 0
	NOTE F_, 8
	OCTAVE 2
	NOTE B_, 2
	RELEASE 9, 2
	OCTAVE 3
	NOTE C#, 2
	RELEASE 0, 0
	NOTE D#, 8
	VIBRATO $04, 0, 1
	NOTE F_, 2
	VIBRATO_OFF
	RELEASE 9, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	RELEASE 7, 1
	VIBRATO $01, 2, 4
	OCTAVE 2
	NOTE A#, 4
	RELEASE 0, 0
	VIBRATO $04, 0, 1
	OCTAVE 4
	NOTE D#, 2
	VIBRATO $01, 0, 2
	NOTE D#, 2
	VIBRATO $01, 2, 2
	NOTE C#, 4
	OCTAVE 3
	NOTE B_, 4
	VIBRATO $01, 2, 3
	NOTE A#, 4
	VIBRATO_OFF
	RELEASE 9, 2
	DUTY 0
	NOTE C#, 4
	NOTE C#, 4
	RELEASE 0, 0
	DUTY 8
	VIBRATO $04, 0, 1
	OCTAVE 4
	NOTE C_, 2
	VIBRATO $01, 0, 2
	NOTE C_, 2
	VIBRATO $01, 2, 3
	OCTAVE 3
	NOTE A_, 4
	NOTE F_, 4
	NOTE A#, 4
	LOOP_BREAK $FB
	NOTE A#, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 4
	LOOP_END $02
	VIBRATO_OFF
	OCTAVE 4
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A#, 2
	VOICE $08, 8, 10, 0, 0
	ENVELOPE $1A
	VIBRATO $01, 2, 4
	OCTAVE 2
	NOTE F#, 12
	NOTE F_, 12
	ENVELOPE $00
	RELEASE 7, 2
	NOTE F#, 4
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	ATTEN 2
	OCTAVE 3
	NOTE F#, 2
	VIBRATO $01, 0, 3
	NOTE F#, 2
	VIBRATO $01, 2, 3
	ATTEN 1
	NOTE F_, 4
	ATTEN 0
	NOTE D#, 4
	NOTE C#, 4
	VIBRATO $04, 0, 2
	ATTEN 1
	NOTE A#, 2
	VIBRATO_OFF
	NOTE G#, 2
	NOTE D#, 2
	NOTE F_, 2
	VIBRATO $04, 0, 2
	ATTEN 0
	NOTE F#, 2
	VIBRATO_OFF
	NOTE F_, 2
	VIBRATO $01, 2, 2
	ATTEN 2
	RELEASE 7, 2
	NOTE F#, 4
	ATTEN 0
	RELEASE 0, 0
	ENVELOPE $19
	NOTE G#, 8
	ENVELOPE $00
	NOTE F_, 4
	ENVELOPE $19
	NOTE A#, 8
	ENVELOPE $00
	DETUNE $FF
	NOTE G#, 4
	ATTEN 2
	NOTE F_, 4
	DETUNE $00
	ATTEN 1
	NOTE F#, 4
	ATTEN 0
	NOTE G#, 4
	ATTEN 1
	VIBRATO $01, 2, 3
	NOTE A#, 4
	VIBRATO_OFF
	RELEASE 9, 2
	DUTY 0
	ATTEN 0
	OCTAVE 2
	NOTE A#, 4
	NOTE F#, 4
	RELEASE 0, 0
	NOTE F_, 4
	ATTEN 2
	DUTY 8
	VIBRATO $04, 0, 2
	OCTAVE 3
	NOTE F_, 2
	VIBRATO_OFF
	NOTE F#, 2
	VIBRATO $01, 2, 3
	NOTE G#, 4
	ATTEN 0
	ENVELOPE $1A
	OCTAVE 3
	NOTE F#, 12
	ENVELOPE $19
	NOTE C#, 8
	ENVELOPE $00
	ATTEN 2
	NOTE F_, 4
	ATTEN 1
	VIBRATO $04, 0, 1
	NOTE F#, 2
	ATTEN 2
	VIBRATO_OFF
	RELEASE 9, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C#, 2
	RELEASE 7, 1
	ATTEN 1
	VIBRATO $01, 2, 4
	NOTE D#, 4
	RELEASE 0, 0
	ATTEN 0
	ENVELOPE $19
	NOTE C#, 8
	ENVELOPE $00
	ATTEN 2
	NOTE F_, 4
	ENVELOPE $19
	NOTE G#, 12
	ATTEN 0
	ENVELOPE $00
	RELEASE 5, 5
	NOTE F#, 12
	SND_LOOP

Snd6D_Ch3:
	SND_SEGNO
	VOICE $08, 1, 2, 0, 0
	VIBRATO $01, 2, 5
	OCTAVE 2
	NOTE D#, 4
	RELEASE 9, 3
	NOTE C_HI, 4
	NOTE C_HI, 4
	RELEASE 0, 0
	NOTE A#, 4
	OCTAVE 3
	NOTE C#, 4
	NOTE F_, 4
	OCTAVE 2
	NOTE D#, 4
	RELEASE 9, 3
	NOTE C_HI, 4
	NOTE C_HI, 4
	RELEASE 0, 0
	NOTE A#, 4
	RELEASE 6, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE F_, 2
	RELEASE 0, 0
	NOTE A#, 4
	LOOP_START
	VOICE $08, 1, 2, 0, 0
	VIBRATO $01, 2, 5
	OCTAVE 2
	NOTE D#, 4
	RELEASE 9, 2
	VIBRATO_OFF
	NOTE C_HI, 2
	WAVE 0
	OCTAVE 4
	NOTE A#, 2
	WAVE 1
	OCTAVE 3
	NOTE D#, 2
	WAVE 0
	OCTAVE 4
	NOTE F#, 2
	WAVE 1
	VIBRATO $01, 2, 5
	RELEASE 0, 0
	OCTAVE 3
	NOTE C#, 4
	RELEASE 9, 2
	VIBRATO_OFF
	NOTE C_HI, 2
	WAVE 0
	OCTAVE 5
	NOTE C#, 2
	WAVE 1
	OCTAVE 4
	NOTE C#, 2
	WAVE 0
	NOTE A#, 2
	WAVE 1
	VIBRATO $01, 2, 5
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 4
	RELEASE 9, 2
	VIBRATO_OFF
	NOTE C_HI, 2
	WAVE 0
	OCTAVE 4
	NOTE B_, 2
	WAVE 1
	OCTAVE 3
	NOTE B_, 2
	WAVE 0
	OCTAVE 4
	NOTE F#, 2
	WAVE 1
	VIBRATO $01, 2, 5
	RELEASE 0, 0
	OCTAVE 2
	NOTE A#, 4
	RELEASE 9, 2
	VIBRATO_OFF
	NOTE C_HI, 2
	WAVE 0
	OCTAVE 4
	NOTE F_, 2
	WAVE 1
	OCTAVE 3
	NOTE F_, 2
	WAVE 0
	OCTAVE 4
	NOTE A#, 2
	WAVE 1
	VIBRATO $01, 2, 5
	RELEASE 0, 0
	OCTAVE 2
	NOTE G#, 4
	RELEASE 9, 2
	VIBRATO_OFF
	NOTE C_HI, 2
	WAVE 0
	OCTAVE 4
	NOTE F#, 2
	WAVE 1
	OCTAVE 3
	NOTE G#, 2
	WAVE 0
	OCTAVE 5
	NOTE D#, 2
	WAVE 1
	VIBRATO $01, 2, 5
	RELEASE 0, 0
	OCTAVE 2
	NOTE F#, 4
	RELEASE 9, 2
	VIBRATO_OFF
	NOTE C_HI, 2
	WAVE 0
	OCTAVE 4
	NOTE A#, 2
	WAVE 1
	OCTAVE 3
	NOTE F#, 2
	WAVE 0
	OCTAVE 5
	NOTE E_, 2
	VIBRATO $01, 2, 5
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE F_, 4
	VIBRATO_OFF
	RELEASE 6, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE F_, 2
	RELEASE 0, 0
	NOTE A_, 2
	OCTAVE 4
	NOTE C_, 2
	VIBRATO $01, 2, 5
	OCTAVE 2
	NOTE A#, 4
	RELEASE 9, 2
	VIBRATO_OFF
	OCTAVE 3
	NOTE F_, 2
	LOOP_BREAK $FB
	WAVE 0
	NOTE C_HI, 2
	WAVE 1
	NOTE A#, 2
	WAVE 0
	OCTAVE 4
	NOTE D_, 2
	LOOP_END $02
	RELEASE 0, 0
	OCTAVE 4
	VIBRATO $05, 0, 3
	NOTE F_, 2
	VIBRATO_OFF
	NOTE D#, 2
	NOTE D_, 2
	VIBRATO $01, 3, 6
	OCTAVE 3
	NOTE D#, 12
	NOTE C#, 12
	OCTAVE 2
	NOTE B_, 12
	NOTE A#, 12
	VIBRATO $01, 2, 5
	NOTE G#, 4
	RELEASE 7, 3
	NOTE C_HI, 4
	OCTAVE 3
	NOTE D#, 4
	RELEASE 0, 0
	OCTAVE 2
	NOTE A#, 8
	NOTE G#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE F_, 4
	VIBRATO_OFF
	RELEASE 6, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C_, 2
	VIBRATO $01, 2, 5
	RELEASE 0, 0
	NOTE F_, 4
	OCTAVE 2
	NOTE A#, 4
	VIBRATO_OFF
	OCTAVE 3
	NOTE C_, 2
	RELEASE 7, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 2
	VOICE $08, 1, 2, 0, 0
	WAVE 1
	VIBRATO $01, 2, 5
	RELEASE 0, 0
	OCTAVE 2
	NOTE D#, 4
	RELEASE 9, 2
	VIBRATO_OFF
	NOTE C_HI, 2
	WAVE 0
	OCTAVE 4
	NOTE A#, 2
	WAVE 1
	OCTAVE 3
	NOTE D#, 2
	WAVE 0
	OCTAVE 4
	NOTE F#, 2
	WAVE 1
	VIBRATO $01, 2, 5
	RELEASE 0, 0
	OCTAVE 3
	NOTE C#, 4
	RELEASE 9, 3
	NOTE C_HI, 4
	NOTE C_HI, 4
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 4
	RELEASE 9, 3
	NOTE C_HI, 4
	NOTE C_HI, 4
	RELEASE 0, 0
	NOTE A#, 4
	VIBRATO_OFF
	OCTAVE 3
	NOTE A#, 2
	RELEASE 7, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE F_, 2
	WAVE 1
	VIBRATO $01, 2, 5
	RELEASE 0, 0
	OCTAVE 2
	NOTE G#, 4
	RELEASE 9, 2
	VIBRATO_OFF
	NOTE C_HI, 2
	WAVE 0
	OCTAVE 4
	NOTE G#, 2
	WAVE 1
	OCTAVE 3
	NOTE D#, 2
	WAVE 0
	OCTAVE 4
	NOTE A#, 2
	WAVE 1
	VIBRATO $01, 2, 5
	RELEASE 0, 0
	OCTAVE 2
	NOTE A#, 4
	RELEASE 9, 2
	VIBRATO_OFF
	NOTE G#, 2
	WAVE 0
	OCTAVE 4
	NOTE G#, 2
	WAVE 1
	OCTAVE 2
	NOTE A#, 2
	WAVE 0
	OCTAVE 4
	NOTE A#, 2
	WAVE 1
	VIBRATO $01, 2, 5
	RELEASE 0, 0
	OCTAVE 2
	NOTE D#, 4
	VIBRATO_OFF
	OCTAVE 3
	NOTE D#, 2
	RELEASE 7, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE G_, 2
	RELEASE 0, 0
	VIBRATO $01, 3, 6
	NOTE D#, 8
	VIBRATO $01, 0, 6
	RELEASE 9, 3
	NOTE D#, 4
	VIBRATO_OFF
	SND_LOOP

Snd6D_Drm:
	SND_SEGNO
	LEN_UNIT $08
	LOOP_START
	DRUM $0C, 2
	SND_CALL Snd6D_Drm_445C
	LOOP_END $02
	DRUM 9, 2
	LOOP_START
	SND_CALL Snd6D_Drm_445C
	LOOP_BREAK $FB
	DRUM $0C, 2
	LOOP_END $02
	DRUM 9, 2
	DRUM 7, 2
	DRUM 3, 2
	DRUM 7, 2
	DRUM $0A, 4
	DRUM 9, 2
	DRUM 7, 2
	DRUM 9, 4
	DRUM 3, 4
	DRUM 9, 2
	DRUM 7, 2
	DRUM $0A, 4
	DRUM 3, 4
	DRUM 9, 2
	DRUM 7, 2
	DRUM 3, 2
	DRUM 5, 2
	DRUM 3, 1
	DRUM 5, 1
	DRUM 3, 2
	DRUM $0C, $0C
	DRUM 9, $0C
	DRUM 9, 8
	DRUM 3, 4
	DRUM 9, 6
	DRUM 3, 2
	DRUM 3, 4
	DRUM 9, 2
	DRUM 7, 2
	DRUM $0A, 8
	DRUM 9, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM $0A, 4
	DRUM 9, 2
	DRUM 7, 2
	DRUM $0A, 4
	DRUM 3, 4
	DRUM 9, 2
	DRUM 7, 2
	DRUM 3, 2
	DRUM 7, 2
	DRUM $0A, 4
	DRUM $0C, 2
	SND_CALL Snd6D_Drm_445C
	DRUM 9, 2
	DRUM 7, 2
	DRUM 3, 2
	DRUM 7, 2
	DRUM $0A, 4
	DRUM 9, 2
	DRUM 7, 2
	DRUM 9, 4
	DRUM 3, 4
	DRUM 9, 2
	DRUM 7, 2
	DRUM $0A, 4
	DRUM 3, 4
	DRUM 9, 2
	DRUM 7, 2
	DRUM $0A, 8
	SND_LOOP
Snd6D_Drm_445C:
	DRUM 7, 2
	DRUM 3, 2
	DRUM 7, 2
	DRUM $0A, 4
	DRUM 9, 2
	DRUM 7, 2
	DRUM 9, 4
	DRUM 3, 4
	DRUM 9, 2
	DRUM 7, 2
	DRUM $0A, 4
	DRUM 3, 4
	DRUM 9, 2
	DRUM 7, 2
	DRUM 3, 2
	DRUM 5, 2
	DRUM 3, 2
	DRUM 7, 2
	SND_RET

Snd67_Ch2:
	SND_SEGNO
	LOOP_START
	VOICE $06, 8, 11, 10, 2
	DUTY_STEP 8, 1
	ATTEN 5
	OCTAVE 4
	NOTE A_, 2
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 3
	NOTE D_, 1
	ATTEN 5
	DUTY 8
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G_, 2
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 3
	NOTE C_, 1
	ATTEN 5
	DUTY 8
	RELEASE 0, 0
	VIBRATO $01, 1, 1
	OCTAVE 4
	NOTE F_, 2
	VIBRATO_OFF
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 2
	NOTE A_, 1
	ATTEN 5
	DUTY 8
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G_, 2
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE F_, 1
	ATTEN 5
	DUTY 8
	RELEASE 0, 0
	VIBRATO $05, 0, 1
	OCTAVE 4
	NOTE A_, 2
	VIBRATO_OFF
	ATTEN 5
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G_, 2
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 3
	NOTE D#, 1
	ATTEN 5
	DUTY 8
	RELEASE $0A, 2
	OCTAVE 4
	NOTE F_, 2
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 3
	NOTE C#, 1
	ATTEN 5
	DUTY 8
	RELEASE 0, 0
	VIBRATO $01, 1, 1
	OCTAVE 4
	NOTE D#, 2
	VIBRATO_OFF
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 3
	NOTE C_, 1
	ATTEN 5
	DUTY 8
	RELEASE $0A, 2
	OCTAVE 4
	NOTE F_, 2
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE G_, 1
	ATTEN 5
	DUTY 8
	RELEASE 0, 0
	OCTAVE 4
	NOTE G_, 2
	LOOP_BREAK $FB
	VIBRATO $05, 0, 1
	NOTE F#, 2
	VIBRATO_OFF
	RELEASE $0A, 2
	NOTE D#, 3
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 3
	NOTE C_, 1
	ATTEN 5
	DUTY 8
	RELEASE 5, 5
	VIBRATO $01, 3, 2
	OCTAVE 4
	NOTE D_, 10
	ATTEN 0
	RELEASE 0, 0
	ATTEN 2
	ENVELOPE $08
	NOTE A#, 8
	ATTEN 0
	ENVELOPE $00
	VIBRATO $04, 0, 1
	ATTEN 3
	OCTAVE 5
	NOTE C_, 4
	VIBRATO_OFF
	ATTEN 5
	OCTAVE 4
	NOTE A#, 4
	LOOP_END $02
	NOTE F#, 2
	VIBRATO $04, 0, 1
	RELEASE 8, 3
	NOTE G_, 3
	VIBRATO_OFF
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 3
	NOTE C_, 1
	ATTEN 5
	DUTY 8
	RELEASE 5, 5
	VIBRATO $01, 3, 2
	OCTAVE 4
	NOTE F#, 6
	ATTEN 4
	VIBRATO_OFF
	RELEASE 0, 0
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	LOOP_START
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE G_, 1
	NOTE A#, 1
	LOOP_END $02
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE C_, 1
	VOICE $06, 8, 9, 0, 0
	SND_CALL Snd67_Ch1_45D8
	NOTE G_, 2
	VIBRATO $01, 3, 2
	NOTE A_, 12
	VIBRATO_OFF
	NOTE A#, 4
	VIBRATO $01, 4, 2
	NOTE G_, 10
	VIBRATO $01, 0, 2
	RELEASE $0E, 7
	NOTE G_, 6
	RELEASE 0, 0
	SND_CALL Snd67_Ch1_45D8
	NOTE G_, 2
	VIBRATO $01, 4, 2
	NOTE F_, 0
	VIBRATO $01, 3, 2
	NOTE E_, 8
	VIBRATO $01, 0, 2
	RELEASE $0F, 7
	NOTE E_, 8
	VOICE $06, 8, 8, 0, 0
	NOTE D_, 0
	VIBRATO $01, 0, 1
	NOTE D_, 0
	VIBRATO $01, 0, 2
	NOTE D_, 0
	NOTE D_, 8
	VIBRATO $03, 0, 1
	ATTEN 4
	ENVELOPE $02
	NOTE D_, 8
	ENVELOPE $00
	ATTEN 0
	OCTAVE 3
	VIBRATO $01, 4, 3
	NOTE D_, 0
	NOTE A_, 0
	NOTE G_, 0
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE C_, 6
	VIBRATO $01, 0, 3
	NOTE C_, 10
	VIBRATO_OFF
	VOICE $06, 8, 9, 0, 0
	SND_CALL Snd67_Ch1_4626
	NOTE G_, 4
	VIBRATO $01, 4, 2
	NOTE E_, 0
	VIBRATO $01, 4, 2
	NOTE D_, 10
	VIBRATO $03, 0, 1
	RELEASE $0F, 6
	NOTE D_, 6
	VIBRATO_OFF
	SND_LOOP
Snd67_Ch1_45D8:
	VIBRATO $01, 4, 2
	OCTAVE 4
	NOTE A_, 12
	VIBRATO $01, 0, 2
	RELEASE $0F, 7
	NOTE A_, 6
	RELEASE 0, 0
	VIBRATO $01, 1, 1
	NOTE G_, 3
	VIBRATO_OFF
	NOTE F_, 3
	NOTE E_, 3
	VIBRATO $04, 0, 2
	NOTE A_, 3
	VIBRATO_OFF
	OCTAVE 3
	NOTE A_, 2
	VIBRATO $01, 4, 2
	NOTE A#, 0
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE F_, 6
	VIBRATO $01, 0, 2
	RELEASE 7, 7
	NOTE F_, 10
	RELEASE 0, 0
	VIBRATO $01, 4, 2
	OCTAVE 3
	NOTE B_, 14
	VIBRATO $01, 0, 2
	RELEASE $0F, 6
	NOTE B_, 5
	RELEASE 0, 0
	VIBRATO $01, 1, 1
	OCTAVE 4
	NOTE C_, 3
	VIBRATO_OFF
	NOTE D_, 2
	VIBRATO $05, 0, 2
	NOTE G_, 3
	VIBRATO $01, 1, 1
	NOTE F_, 3
	VIBRATO_OFF
	SND_RET
Snd67_Ch1_4626:
	VIBRATO $01, 4, 2
	OCTAVE 4
	NOTE A_, 12
	VIBRATO $01, 0, 2
	RELEASE $0F, 7
	NOTE A_, 6
	RELEASE 0, 0
	VIBRATO $01, 1, 1
	NOTE G_, 3
	VIBRATO_OFF
	NOTE F_, 3
	NOTE E_, 3
	VIBRATO $04, 0, 2
	NOTE A_, 3
	VIBRATO_OFF
	NOTE G_, 2
	VIBRATO $01, 4, 2
	NOTE E_, 0
	VIBRATO $04, 0, 2
	RELEASE 7, 7
	OCTAVE 4
	NOTE F_, 10
	RELEASE 0, 0
	VIBRATO_OFF
	ATTEN 2
	NOTE E_, 2
	ATTEN 1
	NOTE F_, 2
	ATTEN 0
	NOTE G_, 2
	VIBRATO $01, 4, 2
	OCTAVE 4
	NOTE A_, 12
	VIBRATO $01, 0, 2
	RELEASE $0F, 6
	NOTE A_, 4
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	NOTE G_, 6
	VIBRATO $01, 3, 2
	NOTE E_, 6
	VIBRATO_OFF
	NOTE C_, 4
	VIBRATO $01, 4, 2
	NOTE D_, 12
	VIBRATO_OFF
	NOTE E_, 4
	RELEASE 7, 5
	VIBRATO $01, 3, 2
	NOTE D_, 10
	RELEASE 0, 0
	VIBRATO_OFF
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE G_, 2
	VIBRATO $01, 4, 2
	NOTE A_, 12
	VIBRATO $01, 0, 2
	RELEASE $0F, 7
	NOTE A_, 6
	RELEASE 0, 0
	VIBRATO $01, 1, 1
	NOTE G_, 3
	VIBRATO_OFF
	OCTAVE 4
	VIBRATO $04, 0, 2
	NOTE C_, 3
	VIBRATO_OFF
	RELEASE 8, 3
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 2
	RELEASE 0, 0
	NOTE E_, 2
	VIBRATO $04, 0, 1
	NOTE F_, 4
	VIBRATO $01, 2, 2
	NOTE D_, 6
	VIBRATO_OFF
	NOTE C_, 2
	RELEASE 8, 4
	VIBRATO $01, 2, 2
	NOTE D_, 4
	RELEASE 8, 3
	NOTE A_, 3
	NOTE A_, 3
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	NOTE A_, 3
	VIBRATO $01, 2, 2
	NOTE G_, 3
	VIBRATO_OFF
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	VIBRATO $01, 3, 2
	OCTAVE 4
	NOTE D_, 4
	RELEASE 7, 7
	NOTE G_, 10
	RELEASE 0, 0
	VIBRATO_OFF
	NOTE C_, 2
	VIBRATO $01, 3, 2
	OCTAVE 4
	NOTE E_, 4
	VIBRATO $04, 0, 2
	NOTE A_, 6
	VIBRATO_OFF
	SND_RET

Snd67_Ch1:
	SND_SEGNO
	LOOP_START
	VOICE $06, 8, 11, 10, 2
	DUTY_STEP 8, 1
	ATTEN 5
	OCTAVE 4
	NOTE F_, 2
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 3
	NOTE F_, 1
	ATTEN 5
	DUTY 8
	RELEASE $0A, 2
	OCTAVE 4
	NOTE E_, 2
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 3
	NOTE E_, 1
	ATTEN 5
	DUTY 8
	RELEASE 0, 0
	VIBRATO $01, 1, 1
	OCTAVE 4
	NOTE D_, 2
	VIBRATO_OFF
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 3
	NOTE D_, 1
	ATTEN 5
	DUTY 8
	RELEASE $0A, 2
	OCTAVE 4
	NOTE E_, 2
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 1
	ATTEN 5
	DUTY 8
	RELEASE 0, 0
	VIBRATO $05, 0, 1
	OCTAVE 4
	NOTE F_, 2
	VIBRATO_OFF
	ATTEN 5
	RELEASE $0A, 2
	OCTAVE 4
	NOTE D#, 2
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 3
	NOTE G_, 1
	ATTEN 5
	DUTY 8
	RELEASE $0A, 2
	OCTAVE 4
	NOTE D_, 2
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 3
	NOTE F_, 1
	ATTEN 5
	DUTY 8
	RELEASE 0, 0
	VIBRATO $01, 1, 1
	NOTE A#, 2
	VIBRATO_OFF
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 3
	NOTE D#, 1
	ATTEN 5
	DUTY 8
	RELEASE $0A, 2
	OCTAVE 4
	NOTE D_, 2
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE A#, 1
	ATTEN 5
	DUTY 8
	RELEASE 0, 0
	OCTAVE 4
	NOTE D#, 2
	LOOP_BREAK $FB
	VIBRATO $05, 0, 1
	NOTE D_, 2
	VIBRATO_OFF
	RELEASE $0A, 2
	NOTE C_, 3
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 3
	NOTE E_, 1
	ATTEN 5
	DUTY 8
	RELEASE 0, 0
	NOTE A_, 2
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	NOTE D_, 2
	ATTEN 5
	RELEASE 0, 0
	DUTY 8
	VIBRATO $05, 0, 1
	DUTY_STEP 0, 0
	OCTAVE 4
	NOTE G_, 2
	ATTEN 5
	VIBRATO_OFF
	NOTE G#, 2
	ATTEN 4
	NOTE A_, 2
	DUTY_STEP 8, 1
	ATTEN 5
	OCTAVE 4
	NOTE D#, 2
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 3
	NOTE G_, 1
	ATTEN 5
	DUTY 8
	RELEASE $0A, 2
	OCTAVE 4
	NOTE F_, 2
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 3
	NOTE F_, 1
	ATTEN 5
	DUTY 8
	RELEASE 0, 0
	VIBRATO $01, 1, 1
	OCTAVE 4
	NOTE G_, 2
	VIBRATO_OFF
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 3
	NOTE D#, 1
	ATTEN 5
	DUTY 8
	RELEASE $0A, 2
	OCTAVE 4
	NOTE F_, 2
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE A#, 1
	ATTEN 5
	DUTY 8
	RELEASE 0, 0
	OCTAVE 4
	NOTE G_, 2
	LOOP_END $02
	NOTE D_, 2
	RELEASE 8, 3
	VIBRATO $07, 0, 1
	NOTE E_, 3
	VIBRATO_OFF
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 3
	NOTE E_, 1
	ATTEN 5
	DUTY 8
	RELEASE 0, 0
	OCTAVE 4
	NOTE D_, 2
	ATTEN 0
	DUTY 4
	RELEASE $0F, 2
	OCTAVE 3
	NOTE D_, 3
	NOTE C#, 1
	ATTEN 4
	RELEASE 0, 0
	DUTY 8
	OCTAVE 4
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	LOOP_START
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 3
	LOOP_END $02
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	VOICE $06, 8, 6, 0, 0
	DETUNE $FF
	REST 2
	SND_CALL Snd67_Ch1_45D8
	NOTE G_, 2
	VIBRATO $01, 3, 2
	NOTE A_, 12
	VIBRATO_OFF
	NOTE A#, 4
	VIBRATO $01, 4, 2
	NOTE G_, 10
	VIBRATO $01, 0, 2
	RELEASE $0E, 7
	NOTE G_, 6
	RELEASE 0, 0
	SND_CALL Snd67_Ch1_45D8
	VOICE $06, 8, 10, 0, 0
	VIBRATO $01, 4, 2
	OCTAVE 3
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 12
	OCTAVE 3
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G#, 1
	VIBRATO $01, 3, 2
	NOTE A_, 8
	ATTEN 2
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE G_, 1
	NOTE A#, 1
	VOICE $06, 8, 10, 0, 0
	DETUNE $FB
	VIBRATO $01, 5, 3
	OCTAVE 2
	NOTE D_, 0
	NOTE A_, 0
	NOTE G_, 0
	VIBRATO $04, 0, 3
	OCTAVE 3
	ENVELOPE $0E
	NOTE C_, 8
	VIBRATO $01, 0, 3
	ATTEN 1
	ENVELOPE $01
	NOTE C_, 8
	ATTEN 0
	ENVELOPE $00
	VIBRATO $01, 5, 3
	OCTAVE 2
	NOTE A_, 0
	OCTAVE 3
	NOTE D_, 0
	OCTAVE 2
	NOTE A#, 0
	VIBRATO $01, 0, 3
	NOTE A#, 9
	VIBRATO_OFF
	OCTAVE 3
	NOTE G_, 1
	LOOP_START
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE G_, 1
	LOOP_END $03
	VOICE $06, 8, 6, 0, 0
	DETUNE $FF
	REST 2
	SND_CALL Snd67_Ch1_4626
	NOTE G_, 2
	VOICE $06, 8, 10, 0, 0
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	VIBRATO $01, 4, 2
	NOTE G_, 12
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE F#, 6
	RELEASE $0F, 6
	VIBRATO $03, 0, 1
	NOTE F#, 6
	VIBRATO_OFF
	SND_LOOP

Snd67_Ch3:
	SND_SEGNO
	LOOP2_START
	VOICE $06, 1, 2, 13, 1
	OCTAVE 3
	NOTE D_, 1
	RELEASE 0, 0
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE A_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G_, 1
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 3
	NOTE D_, 1
	RELEASE 0, 0
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE F_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE E_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	RELEASE $0A, 2
	WAVE 4
	OCTAVE 4
	NOTE D_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	SND_CALL Snd67_Ch3_4F83
	PAN_BOTH 0
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 3
	NOTE D_, 1
	RELEASE 0, 0
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE A_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G_, 1
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 3
	NOTE D_, 1
	RELEASE 0, 0
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE F#, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE E_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	RELEASE $0A, 2
	WAVE 4
	OCTAVE 4
	NOTE D_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	LOOP_BREAK $FC
	SND_CALL Snd67_Ch3_4F83
	LOOP2_END $02
	PAN_BOTH 0
	WAVE 1
	RELEASE 0, 0
	LOOP_START
	OCTAVE 3
	NOTE D#, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	LOOP_END $02
	OCTAVE 3
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	LOOP_START
	VOICE $06, 1, 2, 13, 1
	SND_CALL Snd67_Ch3_51EB
	PAN_BOTH 0
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 3
	NOTE D_, 1
	RELEASE 0, 0
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE A_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G_, 1
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 3
	NOTE D_, 1
	RELEASE 0, 0
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE F_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE E_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	RELEASE $0A, 2
	WAVE 4
	OCTAVE 4
	NOTE C_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 2
	NOTE A#, 1
	RELEASE 0, 0
	NOTE A#, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE F_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A#, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE E_, 1
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 2
	NOTE A#, 1
	RELEASE 0, 0
	NOTE A#, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE D_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 2
	NOTE A#, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE C_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	RELEASE $0A, 2
	WAVE 4
	OCTAVE 4
	NOTE D_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 2
	NOTE A#, 1
	RELEASE 0, 0
	NOTE A#, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE F_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A#, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G_, 1
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 2
	NOTE A#, 1
	RELEASE 0, 0
	NOTE A#, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE A_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 2
	NOTE A#, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	RELEASE $0A, 2
	WAVE 4
	OCTAVE 4
	NOTE F_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 2
	NOTE G_, 1
	RELEASE 0, 0
	NOTE G_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE G_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE F_, 1
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 2
	NOTE G_, 1
	RELEASE 0, 0
	NOTE G_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE E_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 2
	NOTE G_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE D_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0A, 2
	WAVE 4
	OCTAVE 4
	NOTE E_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 2
	NOTE G_, 1
	RELEASE 0, 0
	NOTE G_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE G_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE A_, 1
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 2
	NOTE G_, 1
	RELEASE 0, 0
	NOTE G_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE A_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE G_, 1
	RELEASE $0A, 2
	WAVE 4
	OCTAVE 4
	NOTE G_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE G_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 0, 0
	NOTE A_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	LOOP_BREAK $FB
	NOTE A_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G_, 1
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 0, 0
	NOTE A_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE E_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE D_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0A, 2
	WAVE 4
	OCTAVE 4
	NOTE C#, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 0, 0
	NOTE A_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE A_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE C#, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G_, 1
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 0, 0
	NOTE A_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE E_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE C#, 1
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE D_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0A, 2
	WAVE 4
	OCTAVE 4
	NOTE C#, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE C#, 1
	LOOP_END $02
	NOTE E_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE F_, 1
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 0, 0
	NOTE A_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE E_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE D_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0A, 2
	WAVE 4
	OCTAVE 4
	NOTE C#, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	WAVE 1
	RELEASE 0, 0
	LOOP_START
	OCTAVE 2
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	LOOP_END $02
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE A_, 1
	VOICE $06, 1, 2, 0, 0
	VIBRATO $01, 5, 4
	OCTAVE 2
	NOTE D_, 0
	NOTE A_, 0
	NOTE G_, 0
	OCTAVE 3
	VIBRATO $04, 0, 4
	NOTE C_, 8
	VIBRATO $01, 0, 4
	NOTE C_, 8
	VIBRATO $01, 5, 4
	NOTE D_, 0
	NOTE F_, 0
	NOTE D#, 0
	VIBRATO $01, 0, 5
	NOTE D#, 9
	VIBRATO_OFF
	NOTE C_HI, 1
	LOOP_START
	NOTE D#, 1
	NOTE C_HI, 1
	LOOP_END $03
	VOICE $06, 1, 2, 13, 1
	SND_CALL Snd67_Ch3_4FEA
	SND_CALL Snd67_Ch3_5051
	SND_CALL Snd67_Ch3_50B8
	PAN_BOTH 0
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 0, 0
	NOTE A_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE A_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G_, 1
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 0, 0
	NOTE A_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE F_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE E_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE G_, 1
	RELEASE $0A, 2
	WAVE 4
	OCTAVE 4
	NOTE C_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	LOOP_START
	SND_CALL Snd67_Ch3_4FEA
	SND_CALL Snd67_Ch3_5051
	LOOP_END $02
	SND_CALL Snd67_Ch3_50B8
	PAN_BOTH 0
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 0, 0
	NOTE A_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE A_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G_, 1
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 0, 0
	NOTE A_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE F_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE E_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE B_, 1
	RELEASE $0A, 2
	WAVE 4
	OCTAVE 4
	NOTE C_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	SND_CALL Snd67_Ch3_51EB
	PAN_BOTH 0
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 3
	NOTE D_, 1
	RELEASE 0, 0
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE A_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G_, 1
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 3
	NOTE D_, 1
	RELEASE 0, 0
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE F#, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE E_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 1
	RELEASE $0A, 2
	WAVE 4
	OCTAVE 4
	NOTE D_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	SND_LOOP

Snd67_Drm:
	LEN_UNIT $06
	SND_SEGNO
	DRUM $0C, 2
	DRUM $0A, 2
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
	LOOP_END $04
	DRUM 9, 1
	DRUM 3, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 7, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 9, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 7, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 7, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM $0C, 2
	DRUM $0A, 2
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
	LOOP_END $05
	DRUM 9, 1
	DRUM 3, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 3, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 3, 1
	DRUM 3, 1
	LOOP2_START
	DRUM $0C, 2
	DRUM $0A, 2
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
	LOOP_END $05
	LOOP_START
	DRUM 9, 1
	DRUM 3, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP_END $02
	DRUM $0C, 2
	DRUM $0A, 2
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
	LOOP_END $05
	LOOP_BREAK $FC
	LOOP_START
	DRUM 9, 1
	DRUM 3, 1
	DRUM $0A, 2
	LOOP_END $02
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 7, 1
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
	DRUM 9, 1
	DRUM 3, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 3, 1
	LOOP_START
	DRUM 3, 1
	DRUM 9, 1
	LOOP_END $03
	DRUM $0C, 2
	DRUM $0A, 2
	LOOP_START
	DRUM 9, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP_END $0B
	LOOP_START
	DRUM 3, 1
	LOOP_END $08
	LOOP_START
	DRUM 9, 1
	DRUM 3, 1
	LOOP_END $04
	DRUM $0C, 2
	DRUM $0A, 2
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
	LOOP_END $02
	DRUM 9, 1
	DRUM 3, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP2_START
	LOOP_START
	DRUM 9, 1
	DRUM 7, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP_END $03
	DRUM 9, 1
	DRUM 3, 1
	LOOP_BREAK $FC
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP2_END $03
	DRUM 3, 2
	DRUM 3, 1
	DRUM 7, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM $0C, 2
	DRUM $0A, 2
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
	LOOP_END $02
	DRUM 9, 1
	DRUM 3, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP2_START
	LOOP_START
	DRUM 9, 1
	DRUM 7, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP_END $03
	DRUM 9, 1
	DRUM 3, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 7, 1
	DRUM $0A, 2
	LOOP2_END $02
	LOOP_START
	DRUM 9, 1
	DRUM 3, 1
	DRUM $0A, 2
	LOOP_END $02
	DRUM 3, 1
	DRUM 3, 1
	LOOP_START
	DRUM 3, 1
	DRUM 9, 1
	LOOP_END $03
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	SND_LOOP
Snd67_Ch3_4F83:
	PAN_BOTH 0
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 3
	NOTE D#, 1
	RELEASE 0, 0
	NOTE D#, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE A#, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D#, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE D#, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G#, 1
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 3
	NOTE D#, 1
	RELEASE 0, 0
	NOTE D#, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D#, 1
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE D#, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE F_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C#, 1
	RELEASE $0A, 2
	WAVE 4
	OCTAVE 4
	NOTE D#, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C#, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D#, 1
	SND_RET
Snd67_Ch3_4FEA:
	PAN_BOTH 0
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 2
	NOTE A#, 1
	RELEASE 0, 0
	NOTE A#, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE A_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A#, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G_, 1
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 2
	NOTE A#, 1
	RELEASE 0, 0
	NOTE A#, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE F_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 2
	NOTE A#, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE E_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A#, 1
	RELEASE $0A, 2
	WAVE 4
	OCTAVE 4
	NOTE C_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A#, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	SND_RET
Snd67_Ch3_5051:
	PAN_BOTH 0
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 3
	NOTE C_, 1
	RELEASE 0, 0
	NOTE C_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE A_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G_, 1
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 3
	NOTE C_, 1
	RELEASE 0, 0
	NOTE C_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE F_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE C_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE E_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	RELEASE $0A, 2
	WAVE 4
	OCTAVE 4
	NOTE C_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	SND_RET
Snd67_Ch3_50B8:
	PAN_BOTH 0
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 3
	NOTE D_, 1
	RELEASE 0, 0
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE A_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G_, 1
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 3
	NOTE D_, 1
	RELEASE 0, 0
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE F_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE E_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 1
	RELEASE $0A, 2
	WAVE 4
	OCTAVE 4
	NOTE C_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 3
	NOTE D#, 1
	RELEASE 0, 0
	NOTE D#, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE A_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE D#, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G_, 1
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 3
	NOTE D#, 1
	RELEASE 0, 0
	NOTE D#, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE F_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE D#, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE E_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	RELEASE $0A, 2
	WAVE 4
	OCTAVE 4
	NOTE C_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A#, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 2
	NOTE G_, 1
	RELEASE 0, 0
	NOTE G_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE A_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE G_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G_, 1
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 2
	NOTE G_, 1
	RELEASE 0, 0
	NOTE G_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE F_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 2
	NOTE G_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE E_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE G_, 1
	RELEASE $0A, 2
	WAVE 4
	OCTAVE 4
	NOTE C_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE G_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	SND_RET
Snd67_Ch3_51EB:
	PAN_BOTH 0
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 3
	NOTE D_, 1
	RELEASE 0, 0
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE A_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G_, 1
	WAVE 1
	RELEASE $0D, 1
	OCTAVE 3
	NOTE D_, 1
	RELEASE 0, 0
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE F_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE D_, 1
	WAVE 4
	RELEASE $0A, 2
	OCTAVE 4
	NOTE E_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	RELEASE $0A, 2
	WAVE 4
	OCTAVE 4
	NOTE C_, 1
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	WAVE $0E
	RELEASE $0F, 3
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 1
	SND_RET

Snd65_Ch2:
	SND_SEGNO
	VOICE $07, 8, 13, 9, 1
	LOOP_START
	RELEASE 9, 1
	ATTEN 3
	OCTAVE 3
	NOTE D_, 2
	ATTEN 0
	DUTY 4
	OCTAVE 2
	NOTE D_, 2
	DUTY 8
	RELEASE 0, 0
	VIBRATO $01, 3, 3
	OCTAVE 3
	ENVELOPE $09
	NOTE G_, 8
	ATTEN 2
	ENVELOPE $02
	NOTE C#, 8
	ENVELOPE $00
	VIBRATO_OFF
	ATTEN 7
	OCTAVE 2
	NOTE B_, 4
	LOOP_END $03
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	ATTEN 7
	OCTAVE 3
	NOTE C#, 4
	RELEASE 9, 1
	VIBRATO_OFF
	ATTEN 6
	NOTE C_, 2
	ATTEN 0
	DUTY 4
	OCTAVE 2
	NOTE D_, 2
	DUTY 8
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	ATTEN 5
	OCTAVE 3
	NOTE F_, 4
	RELEASE 9, 1
	VIBRATO_OFF
	ATTEN 4
	NOTE C#, 2
	ATTEN 0
	DUTY 4
	OCTAVE 2
	NOTE D#, 2
	DUTY 8
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	ATTEN 3
	OCTAVE 3
	NOTE G#, 4
	RELEASE 9, 1
	VIBRATO_OFF
	ATTEN 2
	NOTE E_, 2
	ATTEN 0
	DUTY 4
	OCTAVE 2
	NOTE E_, 2
	DUTY 8
	LOOP_START
	RELEASE 9, 1
	ATTEN 5
	OCTAVE 3
	NOTE A#, 2
	ATTEN 0
	DUTY 4
	OCTAVE 2
	NOTE D_, 2
	DUTY 8
	RELEASE 0, 0
	VIBRATO $01, 3, 3
	OCTAVE 4
	ENVELOPE $09
	NOTE D_, 8
	ATTEN 2
	ENVELOPE $02
	NOTE C#, 8
	ENVELOPE $00
	VIBRATO_OFF
	ATTEN 7
	NOTE D#, 4
	LOOP_END $03
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	ATTEN 7
	NOTE D_, 4
	RELEASE 9, 1
	VIBRATO_OFF
	ATTEN 6
	OCTAVE 3
	NOTE B_, 2
	ATTEN 0
	DUTY 4
	OCTAVE 3
	NOTE C_, 2
	DUTY 8
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	ATTEN 5
	OCTAVE 4
	NOTE C_, 4
	RELEASE 9, 1
	VIBRATO_OFF
	ATTEN 4
	OCTAVE 3
	NOTE G#, 2
	ATTEN 0
	DUTY 4
	OCTAVE 2
	NOTE A#, 2
	DUTY 8
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	ATTEN 3
	OCTAVE 3
	NOTE B_, 4
	RELEASE 9, 1
	VIBRATO_OFF
	ATTEN 2
	NOTE F#, 2
	ATTEN 0
	DUTY 4
	OCTAVE 2
	NOTE G#, 2
	DUTY 8
	LOOP_START
	SND_CALL Snd65_Ch2_5653
	LOOP_END $02
	DUTY 0
	RELEASE 0, 0
	VIBRATO $01, 2, 5
	REST 4
	OCTAVE 3
	NOTE G_, 12
	RELEASE $0E, 5
	NOTE G#, 4
	REST 4
	RELEASE 0, 0
	REST 4
	NOTE G_, 8
	VIBRATO_OFF
	NOTE A#, 4
	NOTE G#, 4
	RELEASE $0E, 5
	NOTE E_, 4
	RELEASE 0, 0
	VIBRATO $01, 2, 5
	REST 4
	NOTE G_, 12
	VIBRATO_OFF
	NOTE G#, 4
	NOTE F#, 4
	VIBRATO $01, 2, 5
	NOTE G_, 12
	RELEASE $0E, 5
	VIBRATO $01, 0, 5
	NOTE G_, 4
	REST 8
	SND_CALL Snd65_Ch2_5653
	SND_LOOP

Snd65_Ch1:
	SND_SEGNO
	VOICE $07, 8, 15, 9, 1
	LOOP_START
	RELEASE 9, 1
	ATTEN 5
	OCTAVE 2
	NOTE A#, 2
	ATTEN 0
	DUTY 4
	OCTAVE 1
	NOTE A#, 2
	DUTY 8
	RELEASE 0, 0
	VIBRATO $01, 3, 3
	OCTAVE 3
	ENVELOPE $06
	NOTE D_, 8
	OCTAVE 2
	ENVELOPE $02
	NOTE A#, 8
	ENVELOPE $00
	VIBRATO_OFF
	ATTEN 7
	NOTE G_, 4
	LOOP_END $03
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	ATTEN 7
	NOTE G#, 4
	RELEASE 9, 1
	VIBRATO_OFF
	ATTEN 6
	NOTE G_, 2
	ATTEN 0
	DUTY 4
	OCTAVE 1
	NOTE A#, 2
	DUTY 8
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	ATTEN 5
	OCTAVE 3
	NOTE C_, 4
	RELEASE 9, 1
	VIBRATO_OFF
	ATTEN 4
	OCTAVE 2
	NOTE G#, 2
	ATTEN 0
	DUTY 4
	OCTAVE 1
	NOTE B_, 2
	DUTY 8
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	ATTEN 3
	OCTAVE 3
	NOTE D#, 4
	RELEASE 9, 1
	VIBRATO_OFF
	ATTEN 2
	OCTAVE 2
	NOTE B_, 2
	ATTEN 0
	DUTY 4
	NOTE C_, 2
	DUTY 8
	LOOP_START
	RELEASE 9, 1
	ATTEN 5
	OCTAVE 3
	NOTE D_, 2
	ATTEN 0
	DUTY 4
	OCTAVE 1
	NOTE A#, 2
	DUTY 8
	RELEASE 0, 0
	VIBRATO $01, 3, 3
	OCTAVE 3
	ENVELOPE $06
	NOTE A#, 8
	ENVELOPE $02
	NOTE A_, 8
	ENVELOPE $00
	VIBRATO_OFF
	ATTEN 7
	NOTE B_, 4
	LOOP_END $03
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	ATTEN 7
	NOTE B_, 4
	RELEASE 9, 1
	VIBRATO_OFF
	ATTEN 6
	NOTE G_, 2
	ATTEN 0
	DUTY 4
	OCTAVE 2
	NOTE G#, 2
	DUTY 8
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	ATTEN 5
	OCTAVE 3
	NOTE G#, 4
	RELEASE 9, 1
	VIBRATO_OFF
	ATTEN 4
	NOTE E_, 2
	ATTEN 0
	DUTY 4
	OCTAVE 2
	NOTE G_, 2
	DUTY 8
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	ATTEN 3
	OCTAVE 3
	NOTE G_, 4
	RELEASE 9, 1
	VIBRATO_OFF
	ATTEN 2
	NOTE C#, 2
	ATTEN 0
	DUTY 4
	OCTAVE 2
	NOTE F#, 2
	DUTY 8
	VOICE $07, 0, 11, 0, 0
	VIBRATO $01, 3, 4
	OCTAVE 2
	NOTE D_, 8
	VIBRATO $01, 0, 5
	NOTE D_, 8
	VIBRATO $01, 0, 6
	NOTE D_, 8
	VIBRATO $01, 3, 4
	OCTAVE 2
	NOTE D#, 8
	VIBRATO $01, 0, 5
	NOTE D#, 8
	VIBRATO $01, 0, 6
	RELEASE 5, 4
	NOTE D#, 8
	RELEASE 0, 0
	VIBRATO $01, 3, 4
	OCTAVE 2
	NOTE D#, 8
	VIBRATO $01, 0, 5
	NOTE D#, 8
	VIBRATO $01, 0, 6
	NOTE D#, 8
	VIBRATO $01, 3, 4
	OCTAVE 2
	NOTE D_, 8
	VIBRATO $01, 0, 5
	NOTE D_, 10
	VIBRATO_OFF
	ATTEN 3
	OCTAVE 3
	DUTY 8
	NOTE D#, 2
	NOTE D_, 2
	NOTE C#, 2
	ATTEN 0
	ATTEN 2
	VIBRATO $01, 3, 6
	OCTAVE 3
	NOTE D_, 8
	OCTAVE 2
	NOTE A#, 8
	OCTAVE 3
	NOTE C#, 8
	NOTE D_, 10
	NOTE D#, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE D#, 10
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE G#, 2
	NOTE F#, 8
	OCTAVE 3
	VIBRATO $04, 0, 2
	NOTE D_, 2
	VIBRATO $01, 3, 6
	NOTE D_, 6
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 6
	OCTAVE 2
	NOTE A#, 0
	LOOP_START
	VOICE $07, 0, 11, 0, 0
	VIBRATO $01, 2, 6
	REST 4
	OCTAVE 3
	NOTE D_, 12
	RELEASE $0E, 5
	NOTE D#, 4
	REST 4
	RELEASE 0, 0
	REST 4
	NOTE D_, 8
	VIBRATO_OFF
	NOTE F_, 4
	NOTE D#, 4
	RELEASE $0E, 5
	NOTE C_, 4
	RELEASE 0, 0
	VIBRATO $01, 2, 6
	REST 4
	NOTE D_, 12
	VIBRATO_OFF
	NOTE D#, 4
	NOTE C#, 4
	VIBRATO $01, 2, 6
	LOOP_BREAK $FB
	NOTE D_, 12
	RELEASE $0E, 5
	VIBRATO $01, 0, 6
	NOTE D_, 4
	REST 8
	LOOP_END $02
	NOTE D#, 8
	NOTE D_, 0
	SND_LOOP

Snd65_Ch3:
	SND_SEGNO
	VOICE $07, 1, 2, 0, 0
	DETUNE $FE
	LOOP_START
	OCTAVE 2
	NOTE G_, 2
	RELEASE $0A, 1
	WAVE 5
	NOTE C_HI, 2
	WAVE 1
	RELEASE 0, 0
	NOTE G_, 2
	ATTEN 1
	OCTAVE 4
	VIBRATO $01, 3, 3
	NOTE G_, 8
	NOTE C#, 8
	WAVE_X $1D
	OCTAVE 3
	NOTE B_, 2
	VIBRATO_OFF
	ATTEN 0
	LOOP_END $03
	OCTAVE 2
	WAVE 1
	NOTE G_, 2
	ATTEN 1
	VIBRATO $01, 1, 3
	OCTAVE 4
	NOTE C#, 2
	VIBRATO_OFF
	ATTEN 0
	OCTAVE 2
	NOTE G_, 2
	ATTEN 1
	RELEASE $0A, 1
	OCTAVE 4
	NOTE C_, 4
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	NOTE F_, 4
	VIBRATO_OFF
	ATTEN 0
	OCTAVE 3
	NOTE G_, 2
	NOTE F#, 2
	NOTE C#, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE G#, 2
	DETUNE $FF
	LOOP_START
	OCTAVE 2
	NOTE G_, 2
	RELEASE $0A, 1
	WAVE 5
	NOTE C_HI, 2
	WAVE 1
	RELEASE 0, 0
	NOTE G_, 2
	ATTEN 1
	OCTAVE 5
	VIBRATO $01, 3, 3
	NOTE D_, 8
	NOTE C#, 8
	WAVE_X $1D
	NOTE D#, 2
	VIBRATO_OFF
	ATTEN 0
	LOOP_END $03
	OCTAVE 2
	WAVE 1
	NOTE G_, 2
	ATTEN 1
	VIBRATO $01, 1, 3
	OCTAVE 5
	NOTE D_, 2
	VIBRATO_OFF
	ATTEN 0
	OCTAVE 2
	NOTE G_, 2
	ATTEN 1
	RELEASE $0A, 1
	OCTAVE 4
	NOTE B_, 4
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	OCTAVE 5
	NOTE C_, 4
	VIBRATO_OFF
	ATTEN 0
	OCTAVE 3
	NOTE G_, 2
	NOTE F#, 2
	NOTE C#, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE G#, 2
	LOOP_START
	VOICE $07, 1, 2, 0, 0
	DETUNE $FF
	OCTAVE 2
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	ATTEN 1
	WAVE_X $1D
	VIBRATO $01, 2, 3
	OCTAVE 4
	NOTE G_, 6
	OCTAVE 5
	NOTE D_, 8
	VIBRATO $04, 0, 2
	NOTE G_, 2
	VIBRATO $01, 2, 3
	NOTE G_, 2
	VIBRATO_OFF
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE G#, 2
	ATTEN 1
	WAVE_X $1D
	OCTAVE 5
	VIBRATO $01, 0, 3
	NOTE G_, 2
	VIBRATO_OFF
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE G#, 2
	ATTEN 1
	WAVE_X $1D
	OCTAVE 5
	NOTE A#, 1
	NOTE G_, 1
	VIBRATO $01, 4, 3
	NOTE F#, 12
	VIBRATO_OFF
	NOTE D#, 2
	NOTE D_, 2
	VIBRATO_OFF
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE G#, 2
	ATTEN 1
	WAVE_X $1D
	OCTAVE 4
	NOTE A_, 2
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE G#, 2
	ATTEN 1
	WAVE_X $1D
	VIBRATO $01, 0, 3
	OCTAVE 5
	NOTE C_, 6
	OCTAVE 4
	VIBRATO $01, 3, 3
	NOTE A#, 8
	NOTE F#, 4
	VIBRATO_OFF
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE G_, 2
	ATTEN 1
	WAVE_X $1D
	OCTAVE 4
	NOTE F#, 2
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE G_, 2
	ATTEN 1
	WAVE_X $1D
	VIBRATO $01, 0, 3
	OCTAVE 4
	NOTE G#, 6
	VIBRATO_OFF
	NOTE G_, 2
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE G_, 2
	NOTE F#, 2
	NOTE C#, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE G#, 2
	LOOP_END $02
	DETUNE $00
	LOOP_START
	VOICE $07, 1, 2, 0, 0
	OCTAVE 2
	NOTE G_, 2
	NOTE C_HI, 2
	WAVE 4
	OCTAVE 3
	VIBRATO $01, 2, 6
	NOTE A#, 12
	RELEASE $0A, 7
	NOTE B_, 4
	RELEASE 0, 0
	WAVE 1
	VIBRATO_OFF
	OCTAVE 2
	NOTE F_, 2
	NOTE F#, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE C_HI, 2
	WAVE 4
	OCTAVE 3
	VIBRATO $01, 2, 6
	NOTE A#, 8
	VIBRATO_OFF
	OCTAVE 4
	NOTE C#, 4
	OCTAVE 3
	NOTE B_, 4
	RELEASE $0A, 7
	NOTE G_, 4
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE G_, 2
	NOTE F#, 2
	WAVE 4
	OCTAVE 3
	VIBRATO $01, 2, 6
	NOTE A#, 12
	NOTE B_, 4
	NOTE A_, 4
	WAVE 1
	OCTAVE 2
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	REST 2
	VIBRATO $01, 2, 7
	WAVE 4
	OCTAVE 3
	NOTE A#, 6
	WAVE 1
	VIBRATO_OFF
	NOTE G_, 2
	NOTE F#, 2
	NOTE C#, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE G#, 2
	LOOP_END $02
	SND_LOOP

Snd65_Drm:
	LEN_UNIT $07
	SND_SEGNO
	DRUM $0C, 4
	DRUM 9, 4
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 4
	DRUM 3, 4
	DRUM 9, 4
	DRUM 9, 4
	DRUM 3, 4
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 4
	DRUM 9, 4
	DRUM 9, 4
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 4
	DRUM 9, 4
	DRUM 9, 4
	DRUM 3, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 3, 2
	SND_LOOP
Snd65_Ch2_5653:
	VOICE $07, 8, 8, 0, 0
	VIBRATO $01, 2, 3
	OCTAVE 3
	NOTE G_, 8
	OCTAVE 4
	NOTE D_, 8
	VIBRATO $04, 0, 2
	NOTE G_, 2
	VIBRATO $01, 2, 3
	NOTE G_, 6
	VIBRATO_OFF
	NOTE F#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G_, 1
	VIBRATO $01, 4, 3
	NOTE F#, 12
	VIBRATO_OFF
	NOTE D#, 2
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 2
	VIBRATO $01, 3, 3
	OCTAVE 4
	NOTE C_, 8
	OCTAVE 3
	NOTE A#, 8
	NOTE F#, 8
	VIBRATO $04, 0, 2
	NOTE G#, 3
	VIBRATO $01, 0, 3
	NOTE G#, 5
	VIBRATO $01, 4, 3
	NOTE G_, 12
	RELEASE 8, 5
	VIBRATO $01, 0, 3
	NOTE G_, 4
	SND_RET

Snd66_Ch2:
	LOOP_START
	VOICE $07, 8, 15, 6, 2
	OCTAVE 1
	NOTE G#, 4
	ATTEN 7
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 12
	ATTEN 0
	ENVELOPE $12
	NOTE B_, 14
	ENVELOPE $00
	OCTAVE 1
	NOTE G#, 2
	RELEASE 8, 2
	NOTE A#, 4
	RELEASE 0, 0
	OCTAVE 3
	ATTEN 7
	VIBRATO $04, 0, 3
	NOTE C#, 2
	VIBRATO $01, 3, 3
	NOTE C#, 8
	VIBRATO_OFF
	ATTEN 0
	OCTAVE 1
	NOTE A#, 2
	RELEASE 8, 2
	OCTAVE 2
	NOTE E_, 4
	RELEASE 0, 0
	OCTAVE 2
	ATTEN 7
	VIBRATO $04, 0, 3
	NOTE B_, 2
	VIBRATO $01, 3, 3
	NOTE B_, 6
	VIBRATO_OFF
	ATTEN 0
	RELEASE $0A, 2
	OCTAVE 2
	NOTE E_, 2
	RELEASE 0, 0
	LOOP_BREAK $FB
	NOTE E_, 2
	LOOP_END $02
	ENVELOPE $02
	NOTE E_, 8
	VIBRATO $01, 3, 4
	ENVELOPE $08
	NOTE E_, 10
	VIBRATO_OFF
	ENVELOPE $00
	SND_SEGNO
	VOICE $05, 8, 9, 10, 2
	LOOP_START
	ATTEN 0
	DUTY 8
	RELEASE $0A, 2
	OCTAVE 2
	NOTE F#, 2
	DUTY 0
	ATTEN 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	LOOP_END $04
	RELEASE 4, 1
	DUTY 8
	OCTAVE 3
	NOTE G_, 4
	NOTE G_, 4
	LOOP_START
	ATTEN 0
	DUTY 8
	RELEASE $0A, 2
	OCTAVE 2
	NOTE A_, 2
	DUTY 0
	ATTEN 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	LOOP_END $04
	LOOP_START
	ATTEN 0
	DUTY 8
	RELEASE 0, 0
	OCTAVE 2
	NOTE G_, 2
	DUTY 0
	RELEASE $0A, 2
	ATTEN 2
	NOTE C_HI, 2
	LOOP_END $02
	DUTY 8
	RELEASE 0, 0
	ENVELOPE $0C
	VIBRATO $01, 4, 4
	OCTAVE 3
	NOTE F#, 0
	OCTAVE 3
	VIBRATO $04, 0, 2
	NOTE B_, 4
	VIBRATO $01, 0, 3
	NOTE B_, 4
	VIBRATO_OFF
	NOTE A_, 4
	NOTE G_, 4
	VIBRATO_SEMI 1
	NOTE F_, 4
	VIBRATO $01, 2, 3
	NOTE F#, 8
	VIBRATO_OFF
	ENVELOPE $00
	LOOP_START
	ATTEN 0
	DUTY 8
	RELEASE $0A, 2
	OCTAVE 2
	NOTE A_, 2
	DUTY 0
	ATTEN 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	LOOP_END $02
	LOOP_START
	ATTEN 0
	DUTY 8
	RELEASE 0, 0
	OCTAVE 2
	NOTE G_, 2
	DUTY 0
	RELEASE $0A, 2
	ATTEN 2
	NOTE C_HI, 2
	LOOP_END $02
	VOICE $05, 8, 8, 0, 0
	LOOP_START
	ATTEN 2
	OCTAVE 4
	NOTE F#, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE E_, 2
	VIBRATO $01, 3, 2
	NOTE F#, 10
	REST 2
	VIBRATO $04, 0, 2
	NOTE A_, 2
	VIBRATO_OFF
	NOTE G_, 2
	VIBRATO $01, 3, 2
	NOTE F#, 3
	VIBRATO_OFF
	NOTE E_, 3
	NOTE G_, 2
	LOOP_BREAK $FB
	VIBRATO $01, 1, 1
	NOTE F#, 4
	VIBRATO_OFF
	OCTAVE 5
	DUTY 4
	PAN_RIGHT 0
	ATTEN 0
	VIBRATO $04, 0, 1
	NOTE A_, 2
	VIBRATO_OFF
	NOTE G_, 2
	NOTE F#, 3
	NOTE E_, 3
	NOTE G_, 2
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F_, 1
	VIBRATO $01, 1, 1
	NOTE F#, 4
	DUTY 8
	PAN_BOTH 0
	ATTEN 2
	VIBRATO_OFF
	OCTAVE 4
	NOTE F#, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	VIBRATO $01, 4, 3
	OCTAVE 3
	NOTE B_, 8
	PAN_RIGHT 0
	ATTEN 0
	VIBRATO_OFF
	DUTY 4
	OCTAVE 5
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	VIBRATO $01, 1, 2
	OCTAVE 4
	NOTE B_, 4
	PAN_BOTH 0
	ATTEN 2
	DUTY 8
	VIBRATO $04, 0, 1
	NOTE E_, 4
	VIBRATO_OFF
	NOTE D_, 3
	NOTE C#, 3
	VIBRATO_OFF
	OCTAVE 3
	NOTE B_, 2
	VIBRATO $01, 4, 3
	OCTAVE 4
	NOTE C#, 6
	NOTE D_, 6
	NOTE E_, 6
	NOTE F#, 6
	VIBRATO_OFF
	NOTE G_, 4
	NOTE F_, 4
	LOOP_END $02
	VIBRATO $01, 4, 3
	NOTE F#, 8
	VIBRATO_OFF
	DUTY 4
	PAN_LEFT 0
	ATTEN 0
	OCTAVE 4
	NOTE B_, 2
	OCTAVE 5
	NOTE D#, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE F#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	VIBRATO $01, 1, 1
	NOTE F#, 4
	DUTY 8
	PAN_BOTH 0
	ATTEN 2
	OCTAVE 4
	VIBRATO $01, 4, 3
	NOTE F#, 2
	VIBRATO_OFF
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 4
	PAN_LEFT 0
	ATTEN 0
	VIBRATO $01, 2, 1
	DUTY 4
	OCTAVE 4
	RELEASE $0F, 5
	NOTE B_, 4
	RELEASE 0, 0
	VIBRATO $05, 0, 1
	OCTAVE 5
	NOTE C#, 4
	VIBRATO $01, 2, 1
	NOTE D_, 4
	NOTE E_, 4
	PAN_BOTH 0
	ATTEN 2
	DUTY 8
	VIBRATO_OFF
	OCTAVE 4
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 3
	VIBRATO $04, 0, 1
	NOTE A#, 3
	VIBRATO_OFF
	NOTE B_, 2
	VIBRATO $04, 0, 2
	NOTE A#, 3
	VIBRATO $01, 0, 2
	NOTE A#, 3
	VIBRATO $01, 3, 2
	NOTE G_, 6
	NOTE F#, 6
	NOTE G_, 6
	VIBRATO_OFF
	RELEASE $0F, 4
	NOTE A#, 4
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	ENVELOPE $08
	OCTAVE 5
	NOTE D_, 4
	ENVELOPE $00
	VIBRATO_OFF
	VOICE $05, 8, 6, 0, 0
	OCTAVE 4
	NOTE B_, 8
	VIBRATO $01, 0, 1
	NOTE B_, 8
	VIBRATO $01, 0, 2
	NOTE B_, 8
	VIBRATO $01, 0, 3
	NOTE B_, 6
	VIBRATO $03, 0, 1
	RELEASE 5, 5
	NOTE B_, 2
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	NOTE A#, 3
	VIBRATO $01, 3, 2
	NOTE A#, 13
	VIBRATO_OFF
	NOTE F#, 8
	NOTE E_, 8
	VIBRATO $01, 3, 2
	RELEASE 7, 7
	NOTE D_, 0
	RELEASE 0, 0
	NOTE C#, 8
	VIBRATO $04, 0, 2
	NOTE E_, 8
	VIBRATO_OFF
	OCTAVE 3
	NOTE B_, 8
	VIBRATO $01, 0, 1
	NOTE B_, 8
	VIBRATO $01, 0, 2
	NOTE B_, 8
	VIBRATO $05, 0, 1
	NOTE B_, 2
	VIBRATO_OFF
	ATTEN 2
	OCTAVE 4
	NOTE C#, 2
	ATTEN 1
	NOTE D_, 2
	ATTEN 0
	NOTE F_, 2
	VIBRATO $04, 0, 2
	NOTE B_, 4
	VIBRATO $01, 0, 1
	NOTE B_, 4
	VIBRATO $01, 0, 2
	NOTE B_, 4
	RELEASE 4, 7
	VIBRATO $03, 0, 1
	NOTE B_, 4
	RELEASE 0, 0
	VIBRATO $01, 3, 2
	OCTAVE 3
	NOTE B_, 8
	OCTAVE 4
	NOTE C#, 8
	NOTE D_, 0
	RELEASE 7, 7
	NOTE C#, 0
	RELEASE 0, 0
	VIBRATO $01, 3, 1
	OCTAVE 3
	NOTE B_, 8
	VIBRATO $01, 0, 2
	NOTE B_, 8
	VIBRATO $01, 0, 3
	NOTE B_, 4
	VIBRATO_OFF
	OCTAVE 4
	ATTEN 2
	ENVELOPE $0A
	NOTE C#, 4
	ATTEN 1
	NOTE D_, 4
	ENVELOPE $00
	ATTEN 0
	NOTE E_, 4
	VIBRATO $04, 0, 1
	NOTE D_, 3
	VIBRATO $01, 3, 2
	NOTE D_, 13
	OCTAVE 3
	NOTE A#, 8
	VIBRATO_OFF
	RELEASE 3, 1
	NOTE D_, 4
	NOTE C#, 4
	SND_LOOP

Snd66_Ch1:
	LOOP_START
	VOICE $07, 8, 10, 5, 2
	OCTAVE 2
	NOTE D#, 4
	ATTEN 3
	RELEASE 0, 0
	NOTE C_HI, 12
	ATTEN 0
	ENVELOPE $12
	NOTE C_HI, 0
	ENVELOPE $00
	RELEASE 7, 2
	NOTE D#, 4
	RELEASE 0, 0
	OCTAVE 3
	ATTEN 3
	VIBRATO $04, 0, 3
	NOTE G#, 4
	VIBRATO $01, 3, 4
	NOTE G#, 8
	VIBRATO_OFF
	RELEASE 7, 2
	OCTAVE 2
	NOTE G_, 4
	RELEASE 0, 0
	ATTEN 3
	LOOP_BREAK $FB
	VIBRATO $04, 0, 2
	NOTE C_HI, 4
	VIBRATO $01, 3, 4
	NOTE C_HI, 8
	VIBRATO_OFF
	ATTEN 0
	LOOP_END $02
	ATTEN 3
	VIBRATO $01, 3, 4
	NOTE C_HI, 12
	VIBRATO $01, 0, 4
	ATTEN 2
	ENVELOPE $03
	NOTE C_HI, 0
	VIBRATO_OFF
	ENVELOPE $00
	ATTEN 0
	SND_SEGNO
	VOICE $05, 8, 11, 10, 1
	LOOP_START
	ATTEN 0
	DUTY 8
	OCTAVE 2
	NOTE D#, 2
	DUTY 0
	ATTEN 3
	NOTE C_HI, 2
	NOTE C_HI, 2
	LOOP_END $04
	RELEASE 4, 1
	DUTY 8
	OCTAVE 3
	NOTE E_, 4
	NOTE E_, 4
	LOOP_START
	ATTEN 0
	DUTY 8
	RELEASE $0A, 1
	OCTAVE 2
	NOTE F#, 2
	DUTY 0
	ATTEN 3
	NOTE C_HI, 2
	NOTE C_HI, 2
	LOOP_END $04
	LOOP_START
	ATTEN 0
	DUTY 8
	RELEASE 0, 0
	OCTAVE 2
	NOTE E_, 2
	DUTY 0
	RELEASE $0A, 1
	ATTEN 3
	NOTE C_HI, 2
	LOOP_END $02
	LOOP_START
	RELEASE $0A, 1
	ATTEN 0
	DUTY 8
	OCTAVE 2
	NOTE F#, 2
	DUTY 0
	ATTEN 3
	OCTAVE 3
	NOTE D#, 2
	NOTE D#, 2
	LOOP_END $04
	RELEASE 4, 1
	DUTY 8
	NOTE E_, 4
	NOTE E_, 4
	LOOP_START
	RELEASE $0A, 1
	ATTEN 0
	DUTY 8
	OCTAVE 2
	NOTE A_, 2
	DUTY 0
	ATTEN 3
	NOTE C_HI, 2
	NOTE C_HI, 2
	LOOP_END $02
	LOOP_START
	ATTEN 0
	DUTY 8
	OCTAVE 2
	NOTE F#, 2
	DUTY 0
	ATTEN 3
	NOTE C_HI, 2
	NOTE C_HI, 2
	LOOP_END $02
	LOOP_START
	ATTEN 0
	DUTY 8
	RELEASE 0, 0
	OCTAVE 2
	NOTE E_, 2
	DUTY 0
	RELEASE $0A, 1
	ATTEN 3
	NOTE C_HI, 2
	LOOP_END $02
	VOICE $05, 8, 11, 10, 1
	SND_CALL Snd66_Ch1_5F48
	LOOP_START
	RELEASE $0A, 1
	ATTEN 0
	DUTY 8
	OCTAVE 2
	NOTE E_, 2
	DUTY 0
	ATTEN 3
	OCTAVE 3
	LOOP_BREAK $FB
	NOTE E_, 2
	NOTE C#, 2
	LOOP_END $02
	NOTE C#, 2
	NOTE E_, 2
	LOOP_START
	ATTEN 0
	DUTY 8
	OCTAVE 2
	NOTE E_, 2
	DUTY 0
	ATTEN 3
	OCTAVE 3
	LOOP_BREAK $FB
	NOTE E_, 2
	NOTE G_, 2
	LOOP_END $02
	NOTE E_, 2
	NOTE C#, 2
	RELEASE 6, 1
	DUTY 8
	ATTEN 0
	OCTAVE 2
	NOTE F#, 4
	NOTE G_, 4
	SND_CALL Snd66_Ch1_5F48
	LOOP_START
	RELEASE $0A, 1
	ATTEN 0
	DUTY 8
	OCTAVE 2
	NOTE F#, 2
	DUTY 0
	ATTEN 3
	RELEASE 0, 0
	VIBRATO $01, 2, 2
	OCTAVE 4
	LOOP_BREAK $FB
	NOTE E_, 4
	LOOP_END $02
	NOTE C#, 4
	LOOP_START
	RELEASE $0A, 1
	ATTEN 0
	DUTY 8
	OCTAVE 2
	NOTE F#, 2
	DUTY 0
	ATTEN 3
	VIBRATO $01, 2, 2
	RELEASE 0, 0
	OCTAVE 4
	LOOP_BREAK $FB
	NOTE C_, 4
	LOOP_END $02
	NOTE C#, 4
	DUTY 8
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 2
	NOTE F#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	VOICE $05, 8, 15, 10, 1
	ATTEN 0
	PAN_LEFT 0
	OCTAVE 2
	NOTE G_, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	ATTEN 3
	PAN_RIGHT 0
	DUTY 8
	NOTE B_, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 5
	PAN_LEFT 0
	DUTY 8
	OCTAVE 4
	NOTE F#, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	PAN_RIGHT 0
	DUTY 8
	OCTAVE 5
	NOTE D_, 2
	DUTY 0
	PAN_BOTH 0
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 2
	DUTY 8
	RELEASE 0, 0
	OCTAVE 4
	NOTE G_, 2
	RELEASE $0A, 1
	NOTE F#, 2
	NOTE E_, 2
	NOTE D_, 2
	ATTEN 3
	PAN_LEFT 0
	OCTAVE 4
	NOTE C#, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 2
	PAN_RIGHT 0
	DUTY 8
	NOTE C#, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 5
	PAN_LEFT 0
	DUTY 8
	OCTAVE 4
	NOTE G_, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	PAN_RIGHT 0
	DUTY 8
	OCTAVE 5
	NOTE E_, 2
	DUTY 0
	PAN_BOTH 0
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 2
	DUTY 8
	RELEASE 0, 0
	OCTAVE 4
	NOTE C#, 2
	RELEASE $0A, 1
	OCTAVE 3
	NOTE B_, 2
	NOTE A#, 2
	NOTE G_, 2
	ATTEN 0
	PAN_LEFT 0
	NOTE F#, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 0
	PAN_RIGHT 0
	DUTY 8
	NOTE F#, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 3
	PAN_LEFT 0
	DUTY 8
	OCTAVE 4
	NOTE F#, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	ATTEN 5
	PAN_RIGHT 0
	DUTY 8
	OCTAVE 5
	NOTE D_, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 2
	DUTY 8
	RELEASE 0, 0
	NOTE F#, 2
	RELEASE $0A, 1
	NOTE F_, 2
	NOTE D_, 2
	NOTE C#, 2
	ATTEN 0
	PAN_LEFT 0
	OCTAVE 2
	NOTE B_, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 0
	PAN_RIGHT 0
	DUTY 8
	OCTAVE 2
	NOTE B_, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 3
	PAN_LEFT 0
	DUTY 8
	OCTAVE 4
	NOTE F#, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 5
	PAN_RIGHT 0
	DUTY 8
	OCTAVE 4
	NOTE B_, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 4
	DUTY 8
	RELEASE 0, 0
	DETUNE $FE
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE D_, 2
	NOTE F_, 2
	RELEASE $0A, 1
	DETUNE $00
	ATTEN 3
	PAN_LEFT 0
	OCTAVE 3
	NOTE G_, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE F_, 2
	NOTE F_, 2
	ATTEN 0
	PAN_RIGHT 0
	DUTY 8
	OCTAVE 2
	NOTE G_, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE F_, 2
	NOTE F_, 2
	ATTEN 3
	PAN_LEFT 0
	DUTY 8
	OCTAVE 3
	NOTE G_, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 3
	PAN_RIGHT 0
	DUTY 8
	OCTAVE 4
	NOTE G_, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE F_, 2
	NOTE F_, 2
	DUTY 8
	RELEASE 0, 0
	OCTAVE 4
	NOTE B_, 2
	OCTAVE 5
	NOTE C#, 2
	VIBRATO $01, 1, 2
	NOTE D_, 4
	VIBRATO_OFF
	RELEASE $0A, 1
	ATTEN 5
	PAN_LEFT 0
	OCTAVE 4
	NOTE B_, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE F#, 2
	NOTE B_, 2
	ATTEN 5
	PAN_RIGHT 0
	DUTY 8
	OCTAVE 4
	NOTE B_, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 5
	PAN_LEFT 0
	DUTY 8
	OCTAVE 5
	NOTE D_, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 5
	PAN_RIGHT 0
	DUTY 8
	OCTAVE 4
	NOTE A#, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	DUTY 8
	RELEASE 0, 0
	OCTAVE 4
	VIBRATO $01, 1, 2
	NOTE A#, 4
	VIBRATO_OFF
	NOTE B_, 2
	OCTAVE 5
	NOTE C#, 2
	RELEASE $0A, 1
	ATTEN 5
	PAN_LEFT 0
	OCTAVE 5
	NOTE D_, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 5
	PAN_RIGHT 0
	DUTY 8
	OCTAVE 4
	NOTE G#, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 3
	PAN_LEFT 0
	DUTY 8
	OCTAVE 4
	NOTE E_, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 0
	PAN_RIGHT 0
	DUTY 8
	NOTE E_, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 4
	DUTY 8
	RELEASE 4, 1
	OCTAVE 2
	VIBRATO $01, 1, 2
	NOTE B_, 4
	NOTE G#, 4
	VIBRATO_OFF
	RELEASE $0A, 1
	ATTEN 0
	PAN_LEFT 0
	OCTAVE 2
	NOTE F#, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	ATTEN 1
	PAN_RIGHT 0
	DUTY 8
	OCTAVE 3
	NOTE E_, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	ATTEN 3
	PAN_LEFT 0
	DUTY 8
	OCTAVE 4
	NOTE F#, 2
	DUTY 0
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE G_, 2
	NOTE E_, 2
	ATTEN 4
	DUTY 8
	RELEASE 0, 0
	OCTAVE 3
	NOTE F#, 1
	NOTE G_, 1
	VIBRATO $01, 1, 2
	NOTE F#, 4
	RELEASE 4, 1
	OCTAVE 2
	NOTE G_, 4
	NOTE F#, 4
	VIBRATO_OFF
	SND_LOOP

Snd66_Ch3:
	VOICE $07, 1, 2, 6, 2
	OCTAVE 3
	NOTE G#, 4
	RELEASE 0, 0
	WAVE 9
	ATTEN 1
	VIBRATO $04, 0, 2
	OCTAVE 5
	NOTE G#, 4
	VIBRATO_OFF
	NOTE G_, 4
	NOTE E_, 4
	VIBRATO $01, 2, 2
	NOTE D#, 6
	NOTE E_, 6
	NOTE D#, 4
	NOTE D_, 0
	VIBRATO $01, 0, 3
	NOTE D_, 11
	VIBRATO $03, 0, 1
	RELEASE 5, 5
	NOTE D_, 5
	VIBRATO_OFF
	ATTEN 0
	WAVE 1
	VIBRATO_OFF
	RELEASE 6, 2
	OCTAVE 3
	NOTE G#, 4
	RELEASE 0, 0
	WAVE 9
	ATTEN 1
	VIBRATO $04, 0, 2
	OCTAVE 5
	NOTE B_, 4
	VIBRATO_OFF
	NOTE A#, 4
	NOTE G#, 4
	VIBRATO $01, 2, 2
	NOTE D#, 6
	NOTE E_, 6
	NOTE D#, 4
	NOTE D_, 0
	VIBRATO_OFF
	WAVE $0C
	ATTEN 0
	RELEASE $0F, 5
	NOTE B_, 2
	NOTE A#, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 4
	NOTE B_, 2
	RELEASE 0, 0
	NOTE A#, 4
	VIBRATO $01, 4, 2
	NOTE A#, 14
	SND_SEGNO
	LOOP2_START
	VOICE $05, 1, 2, 8, 2
	LOOP_START
	RELEASE 8, 2
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE B_, 2
	WAVE 7
	ATTEN 1
	NOTE C_HI, 2
	NOTE C_HI, 2
	LOOP_END $04
	RELEASE 4, 1
	WAVE 1
	OCTAVE 4
	NOTE C_, 4
	NOTE C_, 4
	LOOP_START
	RELEASE 8, 2
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE B_, 2
	WAVE 7
	ATTEN 1
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	LOOP_END $04
	LOOP_START
	RELEASE 0, 0
	WAVE 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	RELEASE 8, 2
	WAVE 7
	ATTEN 1
	OCTAVE 4
	NOTE D_, 2
	LOOP_END $02
	ATTEN 0
	LOOP2_END $02
	VOICE $05, 1, 2, 8, 2
	SND_CALL Snd66_Ch3_5FAD
	RELEASE 8, 2
	ATTEN 0
	OCTAVE 2
	NOTE A#, 2
	RELEASE 0, 0
	ATTEN 2
	DETUNE $FF
	OCTAVE 5
	NOTE C#, 4
	DETUNE $00
	RELEASE 8, 2
	ATTEN 0
	OCTAVE 2
	NOTE A#, 2
	RELEASE 0, 0
	ATTEN 2
	DETUNE $FF
	OCTAVE 5
	NOTE D_, 4
	DETUNE $00
	RELEASE 8, 2
	ATTEN 0
	OCTAVE 2
	NOTE A#, 2
	RELEASE 0, 0
	ATTEN 2
	DETUNE $FF
	OCTAVE 5
	NOTE E_, 4
	DETUNE $00
	RELEASE 8, 2
	ATTEN 0
	OCTAVE 2
	NOTE A#, 2
	RELEASE 0, 0
	ATTEN 2
	DETUNE $FF
	OCTAVE 5
	NOTE F#, 4
	DETUNE $00
	RELEASE 4, 1
	ATTEN 0
	OCTAVE 2
	NOTE B_, 4
	OCTAVE 3
	NOTE C#, 4
	SND_CALL Snd66_Ch3_5FAD
	LOOP_START
	RELEASE 8, 2
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE A#, 2
	WAVE 7
	ATTEN 1
	OCTAVE 4
	LOOP_BREAK $FB
	NOTE F#, 2
	NOTE F#, 2
	LOOP_END $03
	NOTE F_, 2
	NOTE F_, 2
	RELEASE 8, 2
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE A#, 2
	WAVE 7
	ATTEN 1
	OCTAVE 4
	NOTE F#, 2
	NOTE F#, 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	ATTEN 0
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE B_, 1
	VOICE $05, 1, 2, 8, 2
	LOOP_START
	RELEASE 8, 2
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE G_, 2
	WAVE 7
	ATTEN 1
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	LOOP_END $04
	RELEASE 4, 1
	WAVE 1
	OCTAVE 2
	ATTEN 0
	NOTE G_, 4
	NOTE G_, 4
	LOOP_START
	RELEASE 8, 2
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE G#, 2
	WAVE 7
	ATTEN 1
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 2
	LOOP_END $03
	RELEASE 8, 2
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 2
	WAVE 7
	ATTEN 1
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 2
	RELEASE 4, 1
	WAVE 1
	OCTAVE 2
	ATTEN 0
	NOTE A_, 4
	OCTAVE 3
	NOTE C#, 4
	LOOP_START
	RELEASE 8, 2
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE B_, 2
	WAVE 7
	ATTEN 1
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	LOOP_END $03
	RELEASE 8, 2
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 2
	WAVE 7
	ATTEN 1
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	RELEASE 4, 1
	WAVE 1
	OCTAVE 2
	ATTEN 0
	NOTE A_, 4
	NOTE A_, 4
	LOOP_START
	RELEASE 8, 2
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE G#, 2
	WAVE 7
	ATTEN 1
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	LOOP_END $03
	RELEASE 8, 2
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE G_, 2
	WAVE 7
	ATTEN 1
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	RELEASE 4, 1
	WAVE 1
	OCTAVE 2
	ATTEN 0
	NOTE G_, 4
	NOTE G_, 4
	LOOP_START
	RELEASE 8, 2
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE F_, 2
	WAVE 7
	ATTEN 1
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	LOOP_END $04
	RELEASE 4, 1
	WAVE 1
	OCTAVE 2
	ATTEN 0
	NOTE F_, 4
	NOTE F_, 4
	LOOP_START
	RELEASE 8, 2
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE F#, 2
	WAVE 7
	ATTEN 1
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	LOOP_END $04
	RELEASE 4, 1
	WAVE 1
	OCTAVE 2
	ATTEN 0
	NOTE F#, 4
	NOTE C_HI, 4
	LOOP_START
	RELEASE 8, 2
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE E_, 2
	WAVE 7
	ATTEN 1
	NOTE B_, 2
	NOTE B_, 2
	LOOP_END $02
	RELEASE 8, 2
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE B_, 2
	WAVE 7
	ATTEN 1
	NOTE C_HI, 2
	NOTE C_HI, 2
	RELEASE 8, 2
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE G#, 2
	WAVE 7
	ATTEN 1
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	RELEASE 4, 1
	WAVE 1
	OCTAVE 2
	ATTEN 0
	NOTE A#, 4
	NOTE A#, 4
	LOOP_START
	RELEASE 8, 2
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE F#, 2
	WAVE 7
	ATTEN 1
	OCTAVE 4
	NOTE C#, 2
	NOTE C#, 2
	LOOP_END $04
	RELEASE 4, 1
	WAVE 1
	OCTAVE 2
	ATTEN 0
	NOTE G#, 4
	NOTE A#, 4
	SND_LOOP

Snd66_Drm:
	LEN_UNIT $07
	DRUM 9, 0
	REST 0
	REST 4
	DRUM $0C, 0
	DRUM $0C, $0C
	DRUM 9, 0
	REST 0
	REST 4
	DRUM $0A, 0
	DRUM $0C, $0C
	REST 0
	LEN_UNIT $05
	DRUM $0C, 2
	LOOP_START
	DRUM 7, 2
	DRUM 8, 2
	DRUM 9, 2
	LOOP_END $03
	LOOP_START
	DRUM 9, 2
	DRUM 8, 2
	LOOP_END $03
	DRUM 9, 2
	LOOP_START
	DRUM 7, 2
	DRUM 8, 2
	DRUM 9, 2
	LOOP_END $03
	LOOP_START
	DRUM 9, 2
	DRUM 8, 2
	LOOP_END $03
	SND_SEGNO
	SND_CALL Snd66_Drm_5FE5
	DRUM 3, 2
	DRUM $0A, 2
	LOOP2_START
	DRUM $0C, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 3, 2
	LOOP_START
	DRUM 9, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 3, 2
	LOOP_END $02
	LOOP_BREAK $FC
	DRUM 9, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	LOOP2_END $02
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 2
	DRUM 3, 2
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 2
	DRUM 3, 2
	DRUM 7, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 9, 2
	LOOP_START
	DRUM 3, 1
	LOOP_END $08
	DRUM $0C, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 8, 2
	LOOP_START
	DRUM 9, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 8, 2
	LOOP_END $02
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 2
	DRUM 3, 3
	DRUM 5, 1
	DRUM 9, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 2
	DRUM 2, 2
	DRUM 2, 2
	DRUM 9, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 2
	LOOP_START
	DRUM $0C, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 9, 2
	LOOP_BREAK $FB
	DRUM 8, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 8, 2
	LOOP_END $02
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	SND_CALL Snd66_Drm_5FE5
	DRUM $0C, 4
	SND_LOOP
Snd66_Ch1_5F48:
	LOOP2_START
	VIBRATO_OFF
	LOOP_START
	RELEASE $0A, 1
	ATTEN 0
	DUTY 8
	OCTAVE 2
	NOTE F#, 2
	DUTY 0
	ATTEN 3
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 2
	LOOP_END $02
	RELEASE $0A, 1
	ATTEN 0
	DUTY 8
	OCTAVE 2
	NOTE F#, 2
	DUTY 0
	ATTEN 3
	OCTAVE 3
	NOTE F_, 2
	NOTE F_, 2
	RELEASE $0A, 1
	ATTEN 0
	DUTY 8
	OCTAVE 2
	NOTE F#, 2
	DUTY 0
	ATTEN 3
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 2
	RELEASE 6, 1
	DUTY 8
	ATTEN 0
	OCTAVE 2
	LOOP_BREAK $FC
	NOTE G_, 4
	NOTE G_, 4
	LOOP2_END $02
	NOTE A_, 4
	NOTE G#, 4
	LOOP_START
	RELEASE $0A, 1
	ATTEN 0
	DUTY 8
	OCTAVE 2
	NOTE D_, 2
	DUTY 0
	ATTEN 3
	OCTAVE 3
	LOOP_BREAK $FB
	NOTE F#, 2
	NOTE F#, 2
	LOOP_END $03
	NOTE G_, 2
	NOTE G_, 2
	RELEASE $0A, 1
	ATTEN 0
	DUTY 8
	OCTAVE 2
	NOTE D_, 2
	DUTY 0
	ATTEN 3
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 2
	RELEASE 6, 1
	DUTY 8
	ATTEN 0
	OCTAVE 2
	NOTE D_, 4
	NOTE D#, 4
	SND_RET
Snd66_Ch3_5FAD:
	LOOP2_START
	LOOP_START
	RELEASE 8, 2
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE B_, 2
	WAVE 7
	ATTEN 1
	OCTAVE 4
	NOTE D#, 2
	NOTE D#, 2
	LOOP_END $04
	RELEASE 4, 1
	WAVE 1
	OCTAVE 3
	ATTEN 0
	LOOP_BREAK $FC
	NOTE C_, 4
	NOTE C_, 4
	LOOP2_END $02
	NOTE D_, 4
	NOTE C#, 4
	LOOP_START
	RELEASE 8, 2
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE G_, 2
	WAVE 7
	ATTEN 1
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	LOOP_END $04
	RELEASE 4, 1
	WAVE 1
	OCTAVE 2
	ATTEN 0
	NOTE G_, 4
	NOTE G#, 4
	SND_RET
Snd66_Drm_5FE5:
	DRUM $0C, 2
	DRUM 8, 2
	DRUM $0A, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM $0A, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	SND_RET

Snd68_Ch2:
	SND_SEGNO
	VOICE $06, 0, 8, 0, 0
	LOOP_START
	VIBRATO $01, 3, 2
	RELEASE 0, 0
	OCTAVE 4
	ENVELOPE $12
	NOTE D_, 0
	DUTY 8
	OCTAVE 3
	ATTEN 2
	ENVELOPE $06
	NOTE G_, 4
	ATTEN 1
	NOTE A_, 4
	ATTEN 0
	NOTE A#, 4
	ATTEN 1
	OCTAVE 4
	NOTE C#, 4
	ATTEN 0
	ENVELOPE $0E
	NOTE D_, 6
	ENVELOPE $00
	NOTE D#, 2
	ENVELOPE $03
	NOTE F#, 6
	ENVELOPE $00
	NOTE D#, 2
	ENVELOPE $03
	NOTE D_, 12
	ENVELOPE $00
	DUTY 0
	RELEASE 9, 1
	NOTE D#, 2
	NOTE D#, 2
	RELEASE 0, 0
	ENVELOPE $12
	NOTE D#, 0
	DUTY 8
	OCTAVE 3
	ATTEN 2
	ENVELOPE $06
	NOTE G#, 4
	ATTEN 1
	NOTE A#, 4
	ATTEN 0
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 4
	ENVELOPE $0E
	NOTE D#, 6
	ENVELOPE $00
	NOTE E_, 2
	VIBRATO $01, 1, 3
	NOTE G_, 6
	ENVELOPE $00
	VIBRATO_OFF
	NOTE G#, 2
	LOOP_BREAK $FB
	VIBRATO $05, 0, 2
	NOTE A#, 4
	VIBRATO $01, 1, 3
	NOTE G#, 4
	NOTE G_, 4
	DUTY 0
	VIBRATO_OFF
	RELEASE 9, 1
	NOTE D_, 2
	NOTE D_, 2
	LOOP_END $02
	VIBRATO $01, 3, 3
	NOTE A#, 8
	NOTE G_, 8
	VOICE $06, 8, 7, 0, 0
	LOOP2_START
	VIBRATO $01, 2, 3
	LOOP_START
	OCTAVE 3
	NOTE A#, 4
	NOTE A_, 4
	OCTAVE 4
	NOTE C#, 4
	LOOP_END $04
	LOOP_START
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 4
	NOTE D#, 4
	LOOP_END $03
	LOOP_BREAK $FC
	VIBRATO_OFF
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 2
	VIBRATO $01, 1, 3
	OCTAVE 3
	NOTE B_, 4
	LOOP2_END $02
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 4
	VOICE $06, 8, 8, 0, 0
	VIBRATO_OFF
	OCTAVE 3
	NOTE F#, 2
	ATTEN 4
	NOTE F#, 2
	ATTEN 0
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	NOTE A#, 2
	ATTEN 4
	NOTE A#, 2
	ATTEN 0
	NOTE B_, 2
	ATTEN 4
	NOTE B_, 2
	ATTEN 0
	OCTAVE 4
	NOTE C#, 2
	ATTEN 4
	NOTE C#, 2
	ATTEN 0
	OCTAVE 3
	NOTE B_, 2
	ATTEN 4
	NOTE B_, 2
	ATTEN 0
	NOTE A#, 2
	ATTEN 4
	NOTE A#, 2
	ATTEN 0
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	NOTE F#, 2
	ATTEN 2
	NOTE F#, 2
	ATTEN 4
	NOTE F#, 2
	ATTEN 6
	NOTE F#, 2
	ATTEN 3
	ENVELOPE $08
	VIBRATO $01, 2, 3
	DUTY 0
	NOTE A#, 8
	NOTE B_, 8
	OCTAVE 4
	NOTE D_, 8
	ENVELOPE $00
	ATTEN 0
	NOTE C#, 4
	DUTY 8
	VIBRATO_OFF
	OCTAVE 3
	NOTE F#, 2
	ATTEN 4
	NOTE F#, 2
	ATTEN 0
	NOTE A#, 2
	ATTEN 4
	NOTE A#, 2
	ATTEN 0
	NOTE B_, 2
	ATTEN 4
	NOTE B_, 2
	ATTEN 0
	OCTAVE 4
	NOTE C#, 2
	ATTEN 4
	NOTE C#, 2
	ATTEN 0
	NOTE D_, 2
	ATTEN 4
	NOTE D_, 2
	ATTEN 0
	NOTE C#, 2
	ATTEN 4
	NOTE C#, 2
	ATTEN 0
	OCTAVE 3
	NOTE B_, 2
	ATTEN 4
	NOTE B_, 2
	ATTEN 0
	NOTE A#, 2
	ATTEN 2
	NOTE A#, 2
	ATTEN 4
	NOTE A#, 2
	ATTEN 6
	NOTE A#, 2
	ATTEN 3
	DUTY 0
	ENVELOPE $08
	NOTE F#, 8
	VIBRATO $01, 2, 3
	NOTE G_, 8
	NOTE A#, 8
	ENVELOPE $00
	ATTEN 0
	VIBRATO_OFF
	DUTY 8
	LOOP_START
	NOTE B_, 2
	ATTEN 4
	NOTE B_, 2
	ATTEN 0
	OCTAVE 4
	NOTE C_, 2
	ATTEN 4
	NOTE C_, 2
	ATTEN 0
	NOTE D#, 2
	ATTEN 4
	NOTE D#, 2
	ATTEN 0
	NOTE E_, 2
	ATTEN 4
	NOTE E_, 2
	ATTEN 0
	NOTE F#, 2
	ATTEN 4
	NOTE F#, 2
	ATTEN 0
	NOTE E_, 2
	ATTEN 4
	NOTE E_, 2
	ATTEN 0
	NOTE D#, 2
	ATTEN 4
	NOTE D#, 2
	ATTEN 0
	NOTE C_, 2
	ATTEN 4
	NOTE C_, 2
	ATTEN 0
	OCTAVE 3
	NOTE B_, 2
	ATTEN 2
	NOTE B_, 2
	ATTEN 4
	LOOP_BREAK $FB
	NOTE B_, 2
	ATTEN 0
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	ATTEN 2
	NOTE B_, 2
	ATTEN 4
	NOTE B_, 2
	ATTEN 0
	NOTE A#, 2
	NOTE B_, 2
	ATTEN 2
	NOTE B_, 2
	ATTEN 4
	NOTE B_, 2
	ATTEN 6
	NOTE B_, 2
	ATTEN 0
	RELEASE 7, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	RELEASE 0, 0
	LOOP_END $02
	ATTEN 0
	DUTY 0
	VIBRATO $01, 2, 3
	NOTE A#, 4
	ATTEN 3
	ENVELOPE $08
	NOTE B_, 8
	OCTAVE 4
	NOTE C_, 8
	NOTE D#, 8
	ENVELOPE $00
	VIBRATO_OFF
	ATTEN 0
	DUTY 0
	VIBRATO $01, 1, 3
	OCTAVE 4
	NOTE D#, 8
	VIBRATO $03, 0, 3
	NOTE D#, 8
	VIBRATO_OFF
	SND_LOOP

Snd68_Ch1:
	SND_SEGNO
	VOICE $06, 0, 10, 0, 0
	LOOP2_START
	LOOP_START
	SND_CALL Snd68_Ch1_6425
	LOOP_END $02
	TRANSPOSE_UP 1
	SND_CALL Snd68_Ch1_6425
	TRANSPOSE_UP 0
	VIBRATO $01, 3, 3
	PAN_BOTH 0
	DUTY 0
	ENVELOPE $12
	OCTAVE 3
	NOTE B_, 0
	ENVELOPE $00
	DUTY 4
	PAN_BOTH 0
	NOTE D#, 2
	ATTEN 6
	NOTE D#, 2
	ATTEN 0
	LOOP_BREAK $FC
	DUTY 0
	OCTAVE 4
	VIBRATO $05, 0, 2
	NOTE D#, 2
	VIBRATO_OFF
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE G#, 2
	NOTE A_, 2
	LOOP2_END $02
	PAN_LEFT 0
	OCTAVE 4
	NOTE D#, 2
	ATTEN 6
	NOTE D#, 2
	PAN_RIGHT 0
	OCTAVE 5
	ATTEN 0
	NOTE D#, 2
	ATTEN 6
	NOTE D#, 2
	OCTAVE 3
	PAN_LEFT 0
	ATTEN 0
	NOTE B_, 2
	ATTEN 6
	NOTE B_, 2
	ATTEN 0
	VOICE $06, 0, 11, 9, 2
	DETUNE $FF
	REST 2
	LOOP2_START
	OCTAVE 3
	NOTE D_, 2
	LOOP_START
	RELEASE 0, 0
	DUTY 8
	ATTEN 6
	NOTE A#, 2
	RELEASE 9, 2
	DUTY 0
	ATTEN 0
	NOTE C#, 2
	RELEASE 0, 0
	DUTY 8
	ATTEN 6
	NOTE A_, 2
	RELEASE 9, 2
	DUTY 0
	ATTEN 0
	NOTE F_, 2
	RELEASE 0, 0
	DUTY 8
	ATTEN 6
	OCTAVE 4
	NOTE C#, 2
	RELEASE 9, 2
	DUTY 0
	ATTEN 0
	OCTAVE 3
	LOOP_BREAK $FB
	NOTE D_, 2
	LOOP_END $04
	NOTE D#, 2
	LOOP_START
	RELEASE 0, 0
	DUTY 8
	ATTEN 6
	NOTE B_, 2
	RELEASE 9, 2
	DUTY 0
	ATTEN 0
	NOTE F_, 2
	RELEASE 0, 0
	DUTY 8
	ATTEN 6
	OCTAVE 4
	NOTE D_, 2
	RELEASE 9, 2
	DUTY 0
	ATTEN 0
	OCTAVE 3
	NOTE F#, 2
	RELEASE 0, 0
	DUTY 8
	ATTEN 6
	OCTAVE 4
	NOTE D#, 2
	RELEASE 9, 2
	DUTY 0
	ATTEN 0
	OCTAVE 3
	NOTE D#, 2
	LOOP_END $03
	RELEASE 0, 0
	DUTY 8
	ATTEN 6
	OCTAVE 4
	NOTE D_, 2
	RELEASE 9, 2
	DUTY 0
	ATTEN 0
	OCTAVE 3
	NOTE F_, 2
	RELEASE 0, 0
	DUTY 8
	ATTEN 6
	LOOP_BREAK $FC
	OCTAVE 4
	NOTE D_, 2
	RELEASE 9, 2
	DUTY 0
	ATTEN 0
	OCTAVE 3
	NOTE F#, 2
	RELEASE 0, 0
	DUTY 8
	ATTEN 6
	NOTE B_, 2
	RELEASE 9, 2
	DUTY 0
	ATTEN 0
	LOOP2_END $02
	NOTE B_, 2
	RELEASE 9, 2
	DUTY 0
	ATTEN 0
	OCTAVE 3
	NOTE F#, 2
	VOICE $06, 8, 10, 0, 0
	DETUNE $00
	LOOP_START
	OCTAVE 2
	VIBRATO $01, 4, 4
	NOTE A#, 0
	NOTE G_, 0
	NOTE F#, 0
	NOTE G_, 0
	LOOP_END $02
	LOOP_START
	OCTAVE 3
	VIBRATO $04, 0, 3
	NOTE D#, 4
	VIBRATO $01, 0, 4
	NOTE D#, 12
	VIBRATO $01, 4, 4
	NOTE C_, 0
	OCTAVE 2
	NOTE B_, 0
	LOOP_BREAK $FB
	OCTAVE 3
	NOTE C_, 0
	LOOP_END $02
	NOTE G#, 8
	NOTE G_, 8
	DUTY 0
	DETUNE $FF
	VIBRATO $01, 1, 3
	REST 2
	ATTEN 6
	OCTAVE 4
	NOTE D#, 8
	VIBRATO $03, 0, 3
	NOTE D#, 6
	ATTEN 0
	VIBRATO_OFF
	SND_LOOP

Snd68_Ch3:
	SND_SEGNO
	VOICE $06, 1, 2, 9, 5
	LOOP2_START
	SND_CALL Snd68_Ch3_6492
	SND_CALL Snd68_Ch3_64D5
	TRANSPOSE_UP 1
	SND_CALL Snd68_Ch3_6492
	LOOP_BREAK $FC
	SND_CALL Snd68_Ch3_64D5
	TRANSPOSE_UP 0
	LOOP2_END $02
	TRANSPOSE_UP 0
	WAVE 1
	ATTEN 0
	RELEASE 0, 0
	NOTE F#, 2
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE A_, 2
	VOICE $06, 1, 2, 0, 0
	OCTAVE 2
	VIBRATO $01, 3, 2
	NOTE G_, 0
	VIBRATO $01, 0, 4
	NOTE G_, 0
	VIBRATO $01, 0, 6
	NOTE G_, 0
	VIBRATO $01, 3, 2
	NOTE G#, 0
	VIBRATO $01, 0, 4
	NOTE G#, 0
	VIBRATO $01, 0, 6
	NOTE G#, 0
	VIBRATO $01, 3, 3
	NOTE G_, 0
	VIBRATO $01, 0, 6
	NOTE G_, 12
	VIBRATO_OFF
	NOTE G#, 2
	NOTE G_, 2
	NOTE F_, 2
	RELEASE 9, 2
	NOTE C_HI, 4
	RELEASE 0, 0
	NOTE F#, 2
	RELEASE 9, 2
	NOTE C_HI, 2
	RELEASE 0, 0
	NOTE G_, 2
	VIBRATO $01, 0, 4
	NOTE A_, 4
	VIBRATO $01, 2, 4
	NOTE G#, 6
	VIBRATO_OFF
	RELEASE 9, 2
	NOTE G#, 4
	RELEASE 0, 0
	NOTE A_, 2
	NOTE B_, 4
	RELEASE 5, 3
	NOTE G#, 4
	NOTE G#, 4
	RELEASE 0, 0
	NOTE G_, 2
	RELEASE 9, 2
	NOTE G#, 4
	RELEASE 0, 0
	NOTE G_, 2
	NOTE G#, 4
	NOTE G_, 2
	RELEASE 9, 2
	NOTE G#, 4
	RELEASE 0, 0
	NOTE G_, 2
	NOTE G#, 2
	NOTE F#, 2
	VOICE $06, 1, 2, 0, 0
	SND_CALL Snd68_Ch3_6452
	SND_CALL Snd68_Ch3_6452
	TRANSPOSE_UP 5
	SND_CALL Snd68_Ch3_6452
	SND_CALL Snd68_Ch3_6452
	TRANSPOSE_UP 0
	REST 0
	ATTEN 0
	SND_LOOP

Snd68_Drm:
	LEN_UNIT $06
	SND_SEGNO
	LOOP_START
	DRUM $0C, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM $0A, 4
	DRUM 7, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM $0A, 4
	DRUM 7, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 9, 2
	LOOP_END $02
	LOOP_START
	DRUM $0C, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 3, 2
	DRUM 9, 2
	LOOP_BREAK $FB
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 8, 2
	LOOP_END $02
	DRUM 3, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM $0A, 4
	DRUM 3, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM $0A, 4
	DRUM 9, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM $0C, 4
	DRUM 9, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 3, 2
	LOOP2_START
	DRUM 9, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 3, 2
	LOOP_BREAK $FC
	DRUM 8, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM $0A, 4
	DRUM 9, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM $0A, 2
	LOOP_START
	DRUM 9, 2
	DRUM 3, 2
	DRUM 3, 2
	LOOP_END $02
	LOOP2_END $02
	DRUM 8, 1
	DRUM 3, 1
	DRUM 3, 2
	DRUM 8, 2
	LOOP_START
	DRUM $0A, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM $0A, 4
	DRUM 7, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM $0A, 4
	DRUM 7, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 2
	DRUM 7, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM $0A, 4
	DRUM 7, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM $0A, 4
	DRUM 3, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 7, 2
	DRUM 8, 1
	DRUM 3, 1
	DRUM 5, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 3, 2
	LOOP_END $02
	DRUM 3, 4
	DRUM 9, 4
	DRUM $0A, 8
	SND_LOOP
Snd68_Ch1_6425:
	VIBRATO $01, 3, 3
	PAN_BOTH 0
	DUTY 0
	OCTAVE 3
	ENVELOPE $12
	NOTE A#, 0
	ENVELOPE $00
	DUTY 4
	DETUNE $FF
	NOTE D_, 2
	ATTEN 6
	NOTE D_, 2
	DETUNE $00
	ATTEN 0
	PAN_LEFT 0
	OCTAVE 4
	NOTE G_, 2
	ATTEN 6
	NOTE G_, 2
	PAN_RIGHT 0
	OCTAVE 5
	ATTEN 0
	NOTE D_, 2
	ATTEN 6
	NOTE D_, 2
	OCTAVE 4
	PAN_LEFT 0
	ATTEN 0
	NOTE G_, 2
	ATTEN 6
	NOTE G_, 2
	ATTEN 0
	SND_RET
Snd68_Ch3_6452:
	LOOP2_START
	WAVE 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 2
	NOTE F#, 2
	WAVE 9
	RELEASE 8, 2
	ATTEN 1
	OCTAVE 3
	NOTE C#, 2
	WAVE 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 2
	NOTE F#, 2
	LOOP_START
	WAVE 9
	RELEASE 8, 2
	ATTEN 1
	OCTAVE 3
	NOTE C#, 2
	WAVE 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 2
	NOTE E_, 2
	NOTE F#, 2
	LOOP_END $03
	WAVE 9
	RELEASE 8, 2
	ATTEN 1
	OCTAVE 3
	NOTE C#, 2
	LOOP_BREAK $FC
	WAVE 1
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE E_, 2
	LOOP2_END $02
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	SND_RET
Snd68_Ch3_6492:
	OCTAVE 2
	NOTE G_, 4
	WAVE 9
	ATTEN 1
	OCTAVE 3
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	RELEASE 5, 5
	VIBRATO $01, 2, 4
	NOTE D_, 6
	VIBRATO_OFF
	ATTEN 0
	WAVE 1
	RELEASE 9, 5
	OCTAVE 2
	NOTE G_, 4
	WAVE 9
	ATTEN 1
	OCTAVE 3
	NOTE G_, 2
	NOTE D_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE D_, 2
	WAVE 1
	ATTEN 0
	OCTAVE 2
	NOTE G_, 4
	WAVE 9
	ATTEN 1
	OCTAVE 3
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	RELEASE 5, 5
	VIBRATO $01, 2, 4
	NOTE D_, 6
	VIBRATO_OFF
	ATTEN 0
	WAVE 1
	RELEASE 9, 5
	OCTAVE 2
	NOTE G_, 4
	WAVE 9
	ATTEN 1
	OCTAVE 3
	NOTE G_, 2
	SND_RET
Snd68_Ch3_64D5:
	NOTE D_, 2
	OCTAVE 4
	NOTE D_, 2
	WAVE 1
	ATTEN 0
	OCTAVE 3
	NOTE D_, 2
	WAVE 9
	ATTEN 1
	OCTAVE 4
	NOTE C_, 2
	WAVE 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	SND_RET

Snd69_Ch2:
	SND_SEGNO
	VOICE $07, 8, 15, 0, 0
	LOOP2_START
	LOOP_START
	RELEASE 0, 0
	DUTY 8
	ATTEN 0
	OCTAVE 1
	NOTE G_, 4
	OCTAVE 2
	RELEASE $0B, 2
	NOTE D_, 2
	DUTY 0
	ATTEN 4
	NOTE B_, 2
	DUTY 8
	ATTEN 0
	NOTE G_, 2
	DUTY 0
	ATTEN 4
	NOTE B_, 2
	LOOP_END $02
	LOOP_START
	DUTY 8
	RELEASE 0, 0
	ATTEN 0
	OCTAVE 1
	NOTE G#, 4
	OCTAVE 2
	RELEASE $0B, 2
	NOTE D#, 2
	DUTY 0
	ATTEN 4
	OCTAVE 3
	NOTE C_, 2
	DUTY 8
	ATTEN 0
	OCTAVE 2
	NOTE G#, 2
	DUTY 0
	ATTEN 4
	OCTAVE 3
	NOTE C_, 2
	LOOP_END $02
	LOOP2_END $02
	LOOP2_START
	LOOP_START
	RELEASE 0, 0
	DUTY 8
	ATTEN 0
	OCTAVE 1
	NOTE G_, 4
	OCTAVE 2
	RELEASE $0B, 2
	NOTE D_, 2
	DUTY 0
	ATTEN 4
	OCTAVE 3
	NOTE D_, 2
	DUTY 8
	ATTEN 0
	OCTAVE 2
	NOTE G_, 2
	DUTY 0
	ATTEN 4
	OCTAVE 3
	NOTE D_, 2
	LOOP_END $02
	LOOP_START
	RELEASE 0, 0
	DUTY 8
	ATTEN 0
	OCTAVE 1
	NOTE G#, 4
	OCTAVE 2
	RELEASE $0B, 2
	NOTE D#, 2
	DUTY 0
	ATTEN 4
	OCTAVE 3
	NOTE D#, 2
	DUTY 8
	ATTEN 0
	OCTAVE 2
	NOTE G#, 2
	DUTY 0
	ATTEN 4
	OCTAVE 3
	NOTE D#, 2
	LOOP_END $02
	LOOP_START
	RELEASE 0, 0
	DUTY 8
	ATTEN 0
	OCTAVE 1
	NOTE G_, 4
	OCTAVE 2
	RELEASE $0B, 2
	NOTE D_, 2
	DUTY 0
	ATTEN 4
	OCTAVE 3
	NOTE D_, 2
	DUTY 8
	ATTEN 0
	OCTAVE 2
	NOTE G_, 2
	DUTY 0
	ATTEN 4
	OCTAVE 3
	NOTE D_, 2
	LOOP_END $04
	LOOP2_END $02
	VOICE $07, 8, 15, 7, 2
	LOOP_START
	OCTAVE 1
	NOTE G_, 4
	RELEASE 0, 0
	DUTY $0C
	VIBRATO $01, 1, 4
	ATTEN 1
	OCTAVE 2
	NOTE G_, 4
	NOTE G#, 4
	ATTEN 0
	VIBRATO_OFF
	DUTY 8
	RELEASE 6, 2
	OCTAVE 1
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE G#, 2
	LOOP_END $02
	OCTAVE 1
	NOTE G_, 4
	RELEASE 0, 0
	DUTY $0C
	VIBRATO $01, 1, 4
	ATTEN 1
	OCTAVE 2
	NOTE G_, 4
	NOTE F#, 4
	ATTEN 0
	VIBRATO_OFF
	DUTY 8
	RELEASE 6, 2
	OCTAVE 1
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE G#, 2
	OCTAVE 1
	NOTE G_, 4
	RELEASE 0, 0
	DUTY $0C
	VIBRATO $01, 1, 4
	ATTEN 1
	OCTAVE 2
	NOTE G_, 4
	NOTE G#, 4
	ATTEN 0
	VIBRATO_OFF
	DUTY 8
	RELEASE 6, 2
	OCTAVE 1
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE G#, 2
	DETUNE $02
	OCTAVE 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE B_, 2
	NOTE G#, 2
	NOTE G_, 4
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D#, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 4
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F#, 4
	DETUNE $00
	SND_LOOP

Snd69_Ch1:
	SND_SEGNO
	VOICE $07, 8, 9, 11, 2
	DETUNE $FF
	LOOP2_START
	LOOP_START
	RELEASE $0B, 2
	VIBRATO_OFF
	OCTAVE 2
	NOTE G_, 4
	RELEASE 0, 0
	VIBRATO $01, 2, 4
	NOTE C_HI, 8
	LOOP_END $02
	LOOP_START
	RELEASE $0B, 2
	VIBRATO_OFF
	OCTAVE 2
	NOTE G#, 4
	RELEASE 0, 0
	VIBRATO $01, 2, 4
	NOTE C_HI, 8
	LOOP_END $02
	LOOP2_END $02
	VIBRATO_OFF
	LOOP2_START
	OCTAVE 3
	NOTE D_, 2
	RELEASE $0F, 3
	OCTAVE 4
	AUTOPAN 0
	NOTE D_, 2
	NOTE C_HI, 2
	PAN_BOTH 0
	RELEASE $0B, 2
	DUTY 0
	OCTAVE 3
	NOTE C_, 2
	DUTY 8
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	VIBRATO $01, 2, 3
	RELEASE 0, 0
	OCTAVE 3
	NOTE A#, 4
	VIBRATO_OFF
	RELEASE $0B, 2
	NOTE A_, 2
	DUTY 0
	NOTE C_, 2
	DUTY 8
	NOTE G_, 2
	DUTY 0
	NOTE C_, 2
	LOOP_BREAK $FC
	DUTY 8
	OCTAVE 3
	NOTE D#, 2
	NOTE G_, 2
	LOOP_START
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	LOOP_END $02
	VIBRATO $01, 2, 3
	RELEASE 0, 0
	OCTAVE 4
	NOTE C_, 4
	VIBRATO_OFF
	RELEASE $0B, 2
	OCTAVE 3
	NOTE A#, 2
	DUTY 0
	NOTE C#, 2
	DUTY 8
	NOTE G#, 2
	DUTY 0
	NOTE C#, 2
	SND_CALL Snd69_Ch1_692B
	OCTAVE 3
	NOTE G_, 2
	DUTY 0
	OCTAVE 2
	NOTE A#, 2
	DUTY 8
	OCTAVE 3
	NOTE F_, 2
	RELEASE $0F, 3
	OCTAVE 4
	AUTOPAN 0
	NOTE F_, 2
	NOTE C_HI, 2
	DUTY 0
	PAN_BOTH 0
	OCTAVE 3
	NOTE C_, 2
	DUTY 8
	PAN_LEFT 0
	OCTAVE 4
	NOTE F_, 2
	PAN_BOTH 0
	DUTY 0
	OCTAVE 3
	NOTE C_, 2
	LOOP2_END $02
	DUTY 8
	OCTAVE 3
	NOTE D#, 2
	RELEASE $0F, 3
	OCTAVE 4
	AUTOPAN 0
	NOTE G#, 2
	OCTAVE 5
	NOTE D#, 2
	PAN_BOTH 0
	RELEASE $0B, 2
	DUTY 0
	OCTAVE 3
	NOTE C_, 2
	DUTY 8
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	VIBRATO $01, 2, 3
	RELEASE 0, 0
	OCTAVE 4
	NOTE C_, 4
	VIBRATO_OFF
	RELEASE $0B, 2
	OCTAVE 3
	NOTE A#, 2
	DUTY 0
	NOTE C#, 2
	DUTY 8
	NOTE G#, 2
	DUTY 0
	NOTE C#, 2
	SND_CALL Snd69_Ch1_692B
	OCTAVE 4
	NOTE D_, 2
	DUTY 0
	OCTAVE 2
	NOTE A#, 2
	DUTY 8
	RELEASE 0, 0
	OCTAVE 4
	NOTE D#, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE G#, 2
	VOICE $07, 8, 10, 0, 0
	DETUNE $FE
	OCTAVE 3
	VIBRATO $01, 2, 4
	ENVELOPE $08
	NOTE D_, 8
	ENVELOPE $00
	NOTE C#, 4
	VIBRATO_OFF
	RELEASE 8, 2
	NOTE D#, 4
	DUTY 0
	DUTY_STEP 8, 1
	RELEASE $0B, 2
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C#, 2
	DUTY 8
	RELEASE 0, 0
	VIBRATO $01, 2, 4
	DUTY_STEP 0, 0
	ENVELOPE $08
	NOTE D_, 8
	ENVELOPE $00
	NOTE D#, 4
	RELEASE 8, 2
	VIBRATO_OFF
	NOTE D_, 4
	DUTY 0
	DUTY_STEP 8, 1
	RELEASE $0B, 2
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C#, 2
	DUTY 8
	DUTY_STEP 0, 0
	VIBRATO $01, 2, 5
	ENVELOPE $08
	NOTE D_, 4
	ENVELOPE $00
	NOTE D#, 4
	ENVELOPE $0C
	NOTE G_, 4
	RELEASE 8, 2
	NOTE F#, 4
	DUTY 0
	DUTY_STEP 8, 1
	RELEASE $0B, 2
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C#, 2
	DUTY 8
	DUTY_STEP 0, 0
	VIBRATO $01, 2, 4
	ENVELOPE $08
	NOTE G_, 4
	ENVELOPE $00
	NOTE F#, 4
	NOTE D#, 4
	RELEASE 0, 0
	VIBRATO $01, 0, 3
	NOTE D_, 4
	VIBRATO_OFF
	DUTY 0
	DUTY_STEP 8, 1
	RELEASE $0B, 2
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE B_, 2
	NOTE G#, 2
	NOTE G_, 4
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D#, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 4
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F#, 4
	SND_LOOP

Snd69_Ch3:
	VOICE $07, 9, 4, 0, 0
	LOOP2_START
	LOOP_START
	OCTAVE 4
	WAVE 9
	RELEASE 0, 0
	NOTE G_, 2
	ATTEN 1
	NOTE G_, 2
	RELEASE $0D, 2
	ATTEN 0
	OCTAVE 5
	NOTE D_, 2
	WAVE 7
	OCTAVE 4
	NOTE D_, 2
	REST 2
	NOTE D_, 2
	LOOP_END $02
	OCTAVE 4
	WAVE 9
	RELEASE 0, 0
	NOTE G#, 2
	ATTEN 1
	NOTE G#, 2
	ATTEN 0
	RELEASE $0D, 2
	OCTAVE 5
	NOTE C_, 2
	WAVE 7
	OCTAVE 4
	NOTE D#, 2
	REST 2
	NOTE D#, 2
	OCTAVE 5
	WAVE 9
	RELEASE 0, 0
	NOTE D#, 2
	ATTEN 1
	NOTE D#, 2
	ATTEN 0
	RELEASE $0D, 2
	OCTAVE 5
	LOOP_BREAK $FC
	NOTE D_, 2
	WAVE 7
	OCTAVE 4
	NOTE D#, 2
	WAVE 9
	OCTAVE 5
	NOTE C_, 2
	WAVE 7
	OCTAVE 4
	NOTE D#, 2
	LOOP2_END $02
	NOTE F#, 2
	WAVE 7
	OCTAVE 4
	NOTE D#, 2
	WAVE 9
	OCTAVE 5
	NOTE G_, 2
	WAVE 7
	OCTAVE 4
	NOTE D#, 2
	SND_SEGNO
	LOOP_START
	VOICE $07, 9, 2, 0, 0
	ATTEN 1
	VIBRATO $01, 2, 3
	OCTAVE 4
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 12
	RELEASE $0B, 1
	NOTE C_, 4
	OCTAVE 4
	NOTE A#, 4
	RELEASE 0, 0
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 12
	VIBRATO_OFF
	NOTE F_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE G#, 1
	NOTE G_, 4
	RELEASE $0B, 2
	WAVE $0B
	PAN_LEFT 0
	ATTEN 0
	OCTAVE 5
	NOTE B_, 1
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 5
	NOTE B_, 1
	NOTE G#, 1
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	NOTE G_, 8
	VIBRATO_OFF
	RELEASE $0B, 2
	PAN_RIGHT 0
	OCTAVE 6
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 5
	NOTE B_, 1
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 5
	NOTE B_, 1
	NOTE G#, 1
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	NOTE G_, 12
	VIBRATO_OFF
	PAN_BOTH 0
	ATTEN 1
	WAVE 9
	OCTAVE 5
	NOTE F_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	LOOP_END $02
	VOICE $07, 1, 4, 0, 0
	INSTRUMENT $03
	VIBRATO $01, 2, 3
	OCTAVE 4
	NOTE G_, 4
	NOTE A#, 4
	NOTE F#, 4
	NOTE G#, 4
	NOTE G_, 8
	NOTE G_, 4
	NOTE F#, 4
	NOTE G#, 4
	NOTE G_, 12
	NOTE G_, 4
	NOTE G#, 4
	NOTE B_, 4
	OCTAVE 5
	NOTE C_, 4
	NOTE D_, 8
	NOTE D#, 4
	NOTE D_, 4
	NOTE C_, 4
	OCTAVE 4
	NOTE B_, 12
	OCTAVE 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE B_, 2
	NOTE G#, 2
	NOTE G_, 4
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D#, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 4
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F#, 4
	INSTRUMENT $00
	LOOP_START
	OCTAVE 4
	WAVE 9
	RELEASE 0, 0
	NOTE D_, 2
	ATTEN 1
	NOTE D_, 2
	ATTEN 2
	NOTE D_, 2
	ATTEN 0
	RELEASE $0D, 2
	WAVE 7
	OCTAVE 4
	NOTE D_, 2
	REST 2
	NOTE D_, 2
	LOOP_END $02
	LOOP_START
	OCTAVE 4
	WAVE 9
	RELEASE 0, 0
	NOTE D#, 2
	ATTEN 1
	NOTE D#, 2
	ATTEN 2
	NOTE D#, 2
	ATTEN 0
	RELEASE $0D, 2
	WAVE 7
	OCTAVE 4
	NOTE D#, 2
	REST 2
	NOTE D#, 2
	LOOP_END $02
	LOOP_START
	OCTAVE 4
	WAVE 9
	RELEASE 0, 0
	NOTE G_, 2
	ATTEN 1
	NOTE G_, 2
	RELEASE $0D, 2
	ATTEN 0
	OCTAVE 5
	NOTE D_, 2
	WAVE 7
	OCTAVE 4
	NOTE D_, 2
	REST 2
	NOTE D_, 2
	LOOP_END $02
	OCTAVE 4
	WAVE 9
	RELEASE 0, 0
	NOTE G#, 2
	ATTEN 1
	NOTE G#, 2
	ATTEN 0
	RELEASE $0D, 2
	OCTAVE 5
	NOTE C_, 2
	WAVE 7
	OCTAVE 4
	NOTE D#, 2
	REST 2
	NOTE D#, 2
	OCTAVE 5
	WAVE 9
	RELEASE 0, 0
	NOTE D#, 2
	ATTEN 1
	NOTE D#, 2
	ATTEN 0
	RELEASE $0D, 2
	OCTAVE 5
	NOTE F#, 2
	WAVE 7
	OCTAVE 4
	NOTE D#, 2
	WAVE 9
	OCTAVE 5
	NOTE G_, 2
	WAVE 7
	OCTAVE 4
	NOTE D#, 2
	SND_LOOP

Snd69_Drm:
	LEN_UNIT $07
	SND_SEGNO
	LOOP_START
	DRUM $0C, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 9, 4
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 4
	DRUM 9, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 9, 4
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	LOOP_END $02
	LOOP_START
	DRUM $0C, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 9, 4
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 4
	DRUM 9, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 9, 4
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 9, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 9, 4
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 4
	DRUM 9, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM 9, 2
	DRUM 3, 2
	DRUM 3, 4
	DRUM 3, 2
	DRUM 3, 2
	LOOP_END $02
	DRUM $0C, $0C
	DRUM 9, 4
	DRUM 9, 8
	DRUM 9, $0C
	DRUM 9, 4
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 4
	DRUM $0C, $0C
	DRUM 9, 4
	DRUM 9, 8
	DRUM 9, $0A
	DRUM 9, 2
	DRUM 9, 4
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 9, $0C
	DRUM 9, 4
	DRUM 9, 2
	DRUM 3, 6
	DRUM 9, 2
	DRUM 3, 6
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	SND_LOOP
Snd69_Ch1_692B:
	RELEASE 0, 0
	DUTY 8
	OCTAVE 4
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	VIBRATO $01, 0, 2
	NOTE D_, 2
	VIBRATO_OFF
	DUTY 0
	RELEASE $0B, 2
	OCTAVE 2
	NOTE A#, 2
	DUTY 8
	OCTAVE 4
	NOTE C_, 2
	DUTY 0
	OCTAVE 2
	NOTE A#, 2
	RELEASE 0, 0
	DUTY 8
	OCTAVE 3
	NOTE A#, 4
	RELEASE $0B, 2
	NOTE G#, 2
	DUTY 0
	NOTE C_, 2
	DUTY 8
	NOTE F#, 2
	DUTY 0
	NOTE C_, 2
	DUTY 8
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	NOTE G_, 6
	RELEASE $0B, 2
	DUTY 0
	OCTAVE 2
	NOTE A#, 2
	DUTY 8
	SND_RET

Snd6A_Ch2:
	SND_SEGNO
	VOICE $06, 8, 9, 15, 3
	LOOP_START
	OCTAVE 5
	PAN_LEFT 0
	REST 2
	NOTE F#, 3
	NOTE F#, 3
	LOOP_BREAK $FB
	PAN_RIGHT 0
	REST 2
	NOTE F#, 3
	NOTE F#, 3
	LOOP_END $04
	PAN_BOTH 0
	LOOP_START
	DUTY 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE A_, 1
	RELEASE $0E, 1
	DUTY 8
	NOTE C_HI, 1
	LOOP_END $02
	LOOP_START
	DUTY 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE A#, 1
	DUTY 8
	RELEASE $0E, 1
	NOTE C_HI, 1
	LOOP_END $02
	SND_CALL Snd6A_Ch1_6F90
	NOTE C_HI, 1
	LOOP_START
	VOICE $06, 8, 12, 15, 2
	ATTEN 0
	DUTY 0
	RELEASE $0F, 1
	OCTAVE 3
	NOTE F#, 2
	ATTEN 3
	RELEASE 0, 0
	DUTY 8
	VIBRATO $01, 2, 2
	NOTE B_, 4
	VIBRATO_OFF
	OCTAVE 4
	NOTE F#, 2
	RELEASE $0F, 2
	NOTE E_, 2
	ATTEN 0
	DUTY 0
	RELEASE $0F, 1
	OCTAVE 3
	NOTE F#, 2
	ATTEN 3
	DUTY 8
	RELEASE 0, 0
	OCTAVE 4
	NOTE A_, 2
	RELEASE $0F, 2
	NOTE F#, 2
	DUTY 0
	RELEASE $0F, 1
	ATTEN 0
	OCTAVE 3
	NOTE F#, 2
	ATTEN 3
	RELEASE $0F, 2
	DUTY 8
	OCTAVE 4
	NOTE D_, 2
	ATTEN 0
	DUTY 0
	RELEASE $0F, 1
	OCTAVE 3
	NOTE F#, 2
	ATTEN 3
	RELEASE 0, 0
	DUTY 8
	OCTAVE 4
	NOTE E_, 2
	DUTY 0
	RELEASE $0F, 1
	ATTEN 0
	OCTAVE 3
	NOTE F#, 2
	RELEASE 0, 0
	ATTEN 3
	DUTY 8
	OCTAVE 4
	NOTE D_, 2
	RELEASE $0F, 2
	NOTE C#, 2
	DUTY 0
	ATTEN 0
	RELEASE $0F, 1
	OCTAVE 3
	NOTE F#, 2
	ATTEN 3
	RELEASE $0F, 2
	DUTY 8
	NOTE B_, 2
	DUTY 0
	ATTEN 0
	RELEASE $0F, 1
	OCTAVE 3
	NOTE F#, 2
	ATTEN 3
	RELEASE 0, 0
	DUTY 8
	OCTAVE 4
	NOTE F#, 2
	RELEASE $0F, 2
	NOTE E_, 2
	ATTEN 0
	DUTY 0
	RELEASE $0F, 1
	OCTAVE 3
	NOTE F#, 2
	ATTEN 3
	RELEASE $0F, 2
	OCTAVE 4
	DUTY 8
	NOTE A_, 2
	ATTEN 0
	RELEASE $0F, 2
	DUTY 0
	RELEASE $0F, 1
	OCTAVE 3
	NOTE F#, 2
	RELEASE $0F, 2
	DUTY 8
	ATTEN 3
	OCTAVE 4
	LOOP_BREAK $FB
	NOTE F#, 2
	DUTY 0
	ATTEN 0
	RELEASE $0F, 1
	OCTAVE 3
	NOTE F#, 2
	ATTEN 3
	RELEASE 0, 0
	DUTY 0
	VIBRATO $01, 2, 2
	ENVELOPE $05
	OCTAVE 4
	NOTE E_, 4
	ENVELOPE $00
	VIBRATO_OFF
	RELEASE $0F, 2
	ATTEN 0
	OCTAVE 3
	NOTE F#, 2
	ATTEN 3
	RELEASE 0, 0
	DUTY 0
	VIBRATO $01, 2, 2
	OCTAVE 4
	NOTE D_, 4
	NOTE C#, 4
	VIBRATO_OFF
	LOOP_END $02
	NOTE B_, 2
	DUTY 0
	ATTEN 0
	RELEASE $0F, 1
	OCTAVE 3
	NOTE F#, 2
	ATTEN 3
	RELEASE 0, 0
	DUTY 0
	VIBRATO $01, 2, 2
	ENVELOPE $05
	OCTAVE 4
	NOTE E_, 4
	VIBRATO_OFF
	ENVELOPE $00
	RELEASE $0F, 2
	ATTEN 0
	OCTAVE 3
	NOTE F#, 2
	ATTEN 3
	RELEASE 0, 0
	DUTY 0
	VIBRATO $01, 2, 2
	OCTAVE 4
	NOTE D_, 4
	NOTE C#, 4
	VIBRATO_OFF
	ATTEN 0
	SND_CALL Snd6A_Ch1_7027
	RELEASE $0F, 2
	REST 1
	ATTEN 3
	OCTAVE 2
	NOTE B_, 2
	SND_CALL Snd6A_Ch1_7027
	REST 1
	RELEASE 0, 0
	ATTEN 3
	NOTE F#, 2
	NOTE G_, 2
	NOTE F#, 1
	VIBRATO $01, 2, 3
	NOTE G_, 3
	NOTE A_, 4
	VIBRATO_OFF
	RELEASE $0F, 2
	ATTEN 4
	NOTE B_, 2
	ATTEN 0
	SND_CALL Snd6A_Ch1_7027
	REST 1
	RELEASE 0, 0
	ATTEN 5
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 1
	VIBRATO $01, 2, 3
	NOTE D_, 3
	NOTE C#, 4
	VIBRATO_OFF
	RELEASE $0F, 2
	ATTEN 4
	OCTAVE 3
	NOTE B_, 2
	ATTEN 0
	SND_CALL Snd6A_Ch1_7027
	REST 1
	RELEASE 0, 0
	OCTAVE 4
	ATTEN 5
	NOTE F#, 2
	NOTE G_, 2
	NOTE F#, 1
	VIBRATO $01, 2, 3
	NOTE G_, 3
	NOTE A_, 2
	VIBRATO_OFF
	RELEASE $0F, 2
	NOTE B_, 2
	ATTEN 0
	SND_CALL Snd6A_Ch1_703B
	SND_CALL Snd6A_Ch1_7027
	SND_CALL Snd6A_Ch1_703B
	REST 1
	SND_CALL Snd6A_Ch1_7027
	ATTEN 7
	REST 1
	RELEASE 0, 0
	DUTY 4
	OCTAVE 5
	VIBRATO $03, 0, 1
	NOTE C_, 8
	VIBRATO_OFF
	ATTEN 0
	VOICE $06, 8, 8, 0, 0
	VIBRATO $01, 2, 3
	OCTAVE 4
	NOTE C_, 6
	VIBRATO_OFF
	RELEASE 8, 3
	OCTAVE 3
	NOTE B_, 10
	VIBRATO $01, 2, 3
	RELEASE 0, 0
	OCTAVE 4
	NOTE D#, 6
	VIBRATO_OFF
	RELEASE 8, 3
	OCTAVE 3
	NOTE B_, 10
	VIBRATO $01, 2, 3
	RELEASE 0, 0
	OCTAVE 4
	NOTE C_, 4
	VIBRATO_OFF
	RELEASE $0E, 5
	OCTAVE 3
	NOTE B_, 4
	VIBRATO $01, 2, 3
	RELEASE 0, 0
	OCTAVE 4
	NOTE D#, 4
	VIBRATO_OFF
	RELEASE $0E, 5
	OCTAVE 3
	NOTE B_, 4
	RELEASE 0, 0
	ATTEN 4
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	ATTEN 2
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE B_, 2
	ATTEN 0
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	ENVELOPE $0A
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE B_, 2
	VOICE $06, 8, 6, 0, 0
	ENVELOPE $00
	LOOP_START
	VIBRATO $01, 2, 3
	RELEASE 0, 0
	OCTAVE 4
	NOTE F#, 3
	NOTE D#, 3
	LOOP_BREAK $FB
	NOTE E_, 3
	RELEASE 8, 3
	NOTE D#, 7
	LOOP_END $03
	NOTE E_, 2
	NOTE D#, 3
	NOTE E_, 3
	NOTE F#, 2
	ATTEN 2
	NOTE G_, 3
	ATTEN 0
	NOTE F#, 3
	NOTE G_, 2
	ATTEN 1
	ENVELOPE $0F
	NOTE A#, 3
	ATTEN 0
	ENVELOPE $0A
	NOTE B_, 3
	VIBRATO_OFF
	NOTE A#, 2
	ENVELOPE $00
	VIBRATO $01, 4, 2
	NOTE B_, 0
	VIBRATO $01, 0, 3
	NOTE B_, 0
	NOTE B_, 0
	VIBRATO_OFF
	RELEASE $0F, 2
	NOTE B_, 2
	REST 6
	DUTY 0
	RELEASE 0, 0
	NOTE B_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	SND_LOOP

Snd6A_Ch1:
	SND_SEGNO
	VOICE $06, 8, 9, 15, 3
	DETUNE $FF
	ATTEN 6
	REST 1
	LOOP_START
	OCTAVE 5
	PAN_LEFT 0
	REST 2
	NOTE F#, 3
	LOOP_BREAK $FB
	NOTE F#, 3
	PAN_RIGHT 0
	REST 2
	NOTE F#, 3
	NOTE F#, 3
	LOOP_END $04
	NOTE F#, 2
	ATTEN 0
	PAN_BOTH 0
	LOOP_START
	DUTY 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE C#, 1
	RELEASE $0E, 1
	DUTY 8
	NOTE C_HI, 1
	LOOP_END $02
	LOOP_START
	DUTY 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE D_, 1
	DUTY 8
	RELEASE $0E, 1
	NOTE C_HI, 1
	LOOP_END $02
	ATTEN 3
	REST 1
	SND_CALL Snd6A_Ch1_6F90
	LOOP_START
	VOICE $06, 8, 12, 15, 2
	ATTEN 0
	DUTY 0
	RELEASE $0F, 1
	OCTAVE 3
	NOTE D_, 2
	ATTEN 3
	DUTY 8
	VIBRATO $01, 2, 3
	RELEASE 0, 0
	NOTE F#, 4
	VIBRATO_OFF
	OCTAVE 4
	NOTE D_, 2
	RELEASE $0F, 2
	OCTAVE 4
	NOTE C#, 2
	ATTEN 0
	DUTY 0
	RELEASE $0F, 1
	OCTAVE 3
	NOTE D_, 2
	ATTEN 3
	RELEASE $0F, 2
	OCTAVE 4
	DUTY 8
	NOTE E_, 2
	NOTE D_, 2
	DUTY 0
	RELEASE $0F, 1
	ATTEN 0
	OCTAVE 3
	NOTE D_, 2
	ATTEN 3
	RELEASE $0F, 2
	DUTY 8
	NOTE B_, 2
	ATTEN 0
	DUTY 0
	RELEASE $0F, 1
	NOTE D_, 2
	ATTEN 3
	RELEASE 0, 0
	DUTY 8
	OCTAVE 4
	NOTE C#, 2
	ATTEN 0
	ATTEN 3
	DUTY 0
	ATTEN 0
	OCTAVE 3
	NOTE D_, 2
	ATTEN 3
	DUTY 8
	RELEASE 0, 0
	OCTAVE 3
	NOTE A_, 2
	RELEASE $0F, 2
	NOTE G_, 2
	ATTEN 0
	DUTY 0
	RELEASE $0F, 1
	OCTAVE 3
	NOTE D_, 2
	ATTEN 3
	DUTY 8
	RELEASE $0F, 2
	NOTE F#, 2
	DUTY 0
	ATTEN 0
	RELEASE $0F, 1
	OCTAVE 3
	NOTE D_, 2
	ATTEN 3
	DUTY 8
	RELEASE 0, 0
	OCTAVE 4
	NOTE D_, 2
	RELEASE $0F, 2
	NOTE C#, 2
	ATTEN 0
	DUTY 0
	RELEASE $0F, 1
	OCTAVE 3
	NOTE D_, 2
	ATTEN 3
	RELEASE $0F, 2
	DUTY 8
	OCTAVE 4
	NOTE E_, 2
	ATTEN 0
	RELEASE $0F, 1
	DUTY 0
	OCTAVE 3
	NOTE D_, 2
	RELEASE $0F, 2
	DUTY 8
	ATTEN 3
	OCTAVE 4
	LOOP_BREAK $FB
	NOTE D_, 2
	DUTY 0
	ATTEN 0
	RELEASE $0F, 1
	OCTAVE 3
	NOTE D_, 2
	ATTEN 3
	RELEASE 0, 0
	DUTY 0
	VIBRATO $01, 2, 2
	ENVELOPE $05
	OCTAVE 3
	NOTE B_, 4
	ENVELOPE $00
	VIBRATO_OFF
	RELEASE $0F, 2
	ATTEN 0
	NOTE D_, 2
	ATTEN 3
	RELEASE 0, 0
	DUTY 0
	VIBRATO $01, 2, 2
	OCTAVE 3
	NOTE A_, 4
	NOTE G_, 4
	VIBRATO_OFF
	LOOP_END $02
	NOTE F#, 2
	DUTY 0
	ATTEN 0
	OCTAVE 3
	NOTE D_, 2
	ATTEN 3
	RELEASE 0, 0
	DUTY 0
	VIBRATO $01, 2, 2
	ENVELOPE $05
	OCTAVE 3
	NOTE B_, 4
	ENVELOPE $00
	VIBRATO_OFF
	RELEASE $0F, 2
	ATTEN 0
	NOTE D_, 2
	ATTEN 5
	RELEASE 0, 0
	DUTY 0
	VIBRATO $01, 2, 2
	OCTAVE 3
	NOTE A_, 4
	NOTE G_, 4
	VIBRATO_OFF
	ATTEN 0
	SND_CALL Snd6A_Ch1_7027
	DETUNE $00
	RELEASE $0F, 2
	REST 1
	ATTEN 3
	OCTAVE 2
	NOTE F#, 2
	DETUNE $FB
	ATTEN 0
	SND_CALL Snd6A_Ch1_7027
	DETUNE $00
	REST 1
	RELEASE 0, 0
	ATTEN 3
	NOTE C#, 2
	NOTE D_, 2
	NOTE C#, 1
	VIBRATO $01, 2, 3
	NOTE D_, 3
	NOTE E_, 4
	VIBRATO_OFF
	RELEASE $0F, 2
	ATTEN 4
	NOTE F#, 2
	ATTEN 0
	DETUNE $FB
	SND_CALL Snd6A_Ch1_7027
	DETUNE $00
	REST 1
	RELEASE 0, 0
	ATTEN 5
	NOTE G#, 2
	NOTE A_, 2
	NOTE B_, 1
	VIBRATO $01, 2, 3
	NOTE A_, 3
	NOTE G#, 4
	VIBRATO_OFF
	RELEASE $0F, 2
	ATTEN 4
	NOTE F#, 2
	ATTEN 0
	DETUNE $FB
	SND_CALL Snd6A_Ch1_7027
	DETUNE $00
	REST 1
	RELEASE 0, 0
	OCTAVE 4
	ATTEN 5
	NOTE C#, 2
	NOTE D_, 2
	NOTE C#, 1
	VIBRATO $01, 2, 3
	NOTE D_, 3
	NOTE E_, 2
	VIBRATO_OFF
	RELEASE $0F, 2
	NOTE F#, 2
	ATTEN 0
	DETUNE $FB
	SND_CALL Snd6A_Ch1_703B
	SND_CALL Snd6A_Ch1_7027
	SND_CALL Snd6A_Ch1_703B
	REST 1
	SND_CALL Snd6A_Ch1_7027
	ATTEN 7
	DETUNE $00
	REST 1
	RELEASE 0, 0
	DUTY 4
	OCTAVE 4
	VIBRATO $03, 0, 2
	NOTE F#, 8
	VIBRATO_OFF
	ATTEN 0
	VOICE $06, 8, 5, 0, 0
	DETUNE $FF
	REST 2
	VIBRATO $01, 2, 3
	OCTAVE 4
	NOTE C_, 6
	VIBRATO_OFF
	RELEASE 8, 3
	OCTAVE 3
	NOTE B_, 10
	VIBRATO $01, 2, 3
	RELEASE 0, 0
	OCTAVE 4
	NOTE D#, 6
	VIBRATO_OFF
	RELEASE 8, 3
	OCTAVE 3
	NOTE B_, 10
	VIBRATO $01, 2, 3
	RELEASE 0, 0
	OCTAVE 4
	NOTE C_, 4
	VIBRATO_OFF
	RELEASE $0E, 5
	OCTAVE 3
	NOTE B_, 4
	VIBRATO $01, 2, 3
	RELEASE 0, 0
	OCTAVE 4
	NOTE D#, 4
	VIBRATO_OFF
	RELEASE $0E, 5
	OCTAVE 3
	NOTE B_, 4
	RELEASE 0, 0
	ATTEN 4
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	ATTEN 2
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE B_, 2
	ATTEN 0
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	ENVELOPE $07
	OCTAVE 4
	NOTE D#, 2
	VOICE $06, 8, 8, 0, 0
	ENVELOPE $00
	LOOP_START
	VIBRATO $01, 2, 3
	RELEASE 0, 0
	OCTAVE 4
	NOTE D#, 3
	OCTAVE 3
	NOTE B_, 3
	OCTAVE 4
	LOOP_BREAK $FB
	NOTE C_, 3
	RELEASE 8, 3
	OCTAVE 3
	NOTE B_, 7
	LOOP_END $03
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 3
	OCTAVE 4
	NOTE C_, 3
	NOTE D#, 2
	ATTEN 2
	NOTE E_, 3
	ATTEN 0
	NOTE D#, 3
	NOTE E_, 2
	ENVELOPE $0A
	NOTE F#, 3
	ENVELOPE $0C
	NOTE G_, 3
	VIBRATO_OFF
	NOTE F#, 2
	ENVELOPE $00
	VOICE $06, 8, 12, 13, 2
	DUTY $0C
	VIBRATO_OFF
	DUTY_STEP 8, 1
	RELEASE $0F, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE A#, 2
	NOTE G_, 2
	NOTE F#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE F#, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	RELEASE $0F, 2
	NOTE F#, 2
	REST 6
	DUTY 0
	RELEASE 0, 0
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE F#, 1
	SND_LOOP

Snd6A_Ch3:
	SND_SEGNO
	VOICE $06, 1, 2, 10, 5
	LOOP_START
	OCTAVE 2
	NOTE B_, 3
	OCTAVE 3
	NOTE D_, 3
	NOTE F#, 2
	OCTAVE 2
	NOTE A_, 3
	OCTAVE 3
	NOTE C#, 3
	NOTE E_, 2
	OCTAVE 2
	NOTE G_, 3
	NOTE B_, 3
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 3
	OCTAVE 3
	NOTE C#, 3
	NOTE E_, 2
	LOOP_END $08
	LOOP_START
	OCTAVE 2
	NOTE B_, 3
	OCTAVE 3
	NOTE D_, 3
	NOTE F#, 2
	LOOP_END $02
	LOOP_START
	OCTAVE 2
	NOTE G_, 3
	NOTE B_, 3
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 3
	OCTAVE 3
	NOTE C#, 3
	NOTE E_, 2
	LOOP_END $02
	OCTAVE 2
	NOTE B_, 4
	NOTE C_HI, 4
	VIBRATO $03, 0, 3
	ATTEN 1
	RELEASE 0, 0
	NOTE C_HI, 8
	VIBRATO_OFF
	ATTEN 0
	LOOP_START
	VOICE $06, 1, 2, 10, 5
	OCTAVE 2
	NOTE B_, 3
	NOTE B_, 1
	PAN_LEFT 0
	ATTEN 1
	RELEASE $0F, 4
	OCTAVE 6
	NOTE F#, 3
	NOTE F#, 3
	PAN_BOTH 0
	ATTEN 0
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 2
	REST 1
	NOTE A#, 3
	LOOP_BREAK $FB
	RELEASE $0A, 5
	NOTE B_, 3
	NOTE B_, 1
	ATTEN 1
	PAN_RIGHT 0
	RELEASE $0F, 4
	OCTAVE 6
	NOTE F#, 3
	NOTE F#, 3
	PAN_BOTH 0
	ATTEN 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE D_, 2
	REST 1
	NOTE C_, 3
	LOOP_END $02
	LOOP_START
	OCTAVE 2
	NOTE B_, 2
	ATTEN 1
	PAN_RIGHT 0
	RELEASE $0F, 4
	OCTAVE 6
	NOTE F#, 2
	PAN_BOTH 0
	ATTEN 0
	RELEASE 0, 0
	LOOP_END $02
	LOOP_START
	OCTAVE 3
	NOTE E_, 1
	NOTE C_HI, 1
	LOOP_END $02
	LOOP_START
	OCTAVE 3
	NOTE F_, 1
	NOTE C_HI, 1
	LOOP_END $02
	LOOP_START
	RELEASE $0A, 5
	OCTAVE 2
	NOTE B_, 3
	NOTE B_, 1
	PAN_LEFT 0
	ATTEN 1
	RELEASE $0F, 4
	OCTAVE 6
	NOTE F#, 3
	NOTE F#, 3
	PAN_BOTH 0
	ATTEN 0
	RELEASE 0, 0
	LOOP_BREAK $FB
	OCTAVE 2
	NOTE A_, 2
	REST 1
	NOTE A#, 3
	RELEASE $0A, 5
	OCTAVE 2
	NOTE B_, 3
	NOTE B_, 1
	PAN_RIGHT 0
	ATTEN 1
	RELEASE $0F, 4
	OCTAVE 6
	NOTE F#, 3
	NOTE F#, 3
	PAN_BOTH 0
	ATTEN 0
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 2
	REST 1
	NOTE A#, 3
	LOOP_END $02
	OCTAVE 3
	NOTE F#, 2
	REST 1
	NOTE D#, 3
	RELEASE $0A, 5
	OCTAVE 2
	NOTE B_, 3
	OCTAVE 3
	NOTE D#, 3
	NOTE F#, 2
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 2
	LOOP_START
	OCTAVE 2
	NOTE B_, 3
	OCTAVE 3
	NOTE D#, 3
	NOTE F#, 2
	NOTE A_, 3
	NOTE F#, 3
	NOTE D#, 2
	LOOP_END $03
	RELEASE $0F, 2
	OCTAVE 2
	NOTE B_, 2
	REST 6
	RELEASE 0, 0
	OCTAVE 4
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE C#, 1
	SND_LOOP

Snd6A_Drm:
	LEN_UNIT $06
	SND_SEGNO
	DRUM $0A, 2
	SND_CALL Snd6A_Drm_6F81
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	SND_CALL Snd6A_Drm_6F81
	LOOP_END $02
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 2
	SND_CALL Snd6A_Drm_6F81
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	SND_CALL Snd6A_Drm_6F81
	LOOP_END $03
	DRUM $0C, 2
	SND_CALL Snd6A_Drm_6F81
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	SND_CALL Snd6A_Drm_6F81
	LOOP_END $02
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP2_START
	DRUM $0C, 2
	SND_CALL Snd6A_Drm_6F81
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	SND_CALL Snd6A_Drm_6F81
	LOOP_END $02
	LOOP_BREAK $FC
	DRUM 9, 1
	DRUM 3, 1
	DRUM 5, 1
	LOOP_START
	DRUM 9, 1
	DRUM 3, 1
	LOOP_BREAK $FB
	DRUM 3, 1
	DRUM 5, 1
	LOOP_END $03
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP2_END $02
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 4
	LOOP_START
	DRUM 9, 1
	DRUM 3, 1
	LOOP_END $04
	DRUM $0A, 2
	LOOP_START
	DRUM 7, 1
	DRUM 8, 1
	LOOP_END $1D
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0C, 2
	DRUM 7, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	LOOP_END $0C
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0C, 2
	SND_CALL Snd6A_Drm_6F81
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	SND_CALL Snd6A_Drm_6F81
	LOOP_END $02
	LOOP_START
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	LOOP_END $02
	LOOP_START
	DRUM 3, 1
	LOOP_END $08
	SND_LOOP
Snd6A_Drm_6F81:
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	SND_RET
Snd6A_Ch1_6F90:
	LOOP_START
	RELEASE 0, 0
	DUTY 0
	OCTAVE 3
	NOTE F#, 1
	NOTE C_HI, 1
	DUTY 8
	PAN_LEFT 0
	OCTAVE 5
	NOTE F#, 1
	DUTY 0
	PAN_BOTH 0
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 1
	DUTY 8
	PAN_LEFT 0
	OCTAVE 5
	NOTE F#, 1
	DUTY 0
	PAN_BOTH 0
	OCTAVE 4
	NOTE D_, 1
	NOTE C_HI, 1
	RELEASE 0, 0
	DUTY 0
	OCTAVE 3
	NOTE E_, 1
	NOTE C_HI, 1
	DUTY 8
	PAN_RIGHT 0
	OCTAVE 5
	NOTE F#, 1
	DUTY 0
	PAN_BOTH 0
	OCTAVE 3
	NOTE A_, 1
	NOTE C_HI, 1
	DUTY 8
	PAN_RIGHT 0
	OCTAVE 5
	NOTE F#, 1
	DUTY 0
	PAN_BOTH 0
	OCTAVE 4
	NOTE C#, 1
	NOTE C_HI, 1
	RELEASE 0, 0
	DUTY 0
	OCTAVE 3
	NOTE D_, 1
	NOTE C_HI, 1
	DUTY 8
	PAN_LEFT 0
	OCTAVE 5
	NOTE F#, 1
	DUTY 0
	PAN_BOTH 0
	OCTAVE 3
	NOTE G_, 1
	NOTE C_HI, 1
	DUTY 8
	PAN_LEFT 0
	OCTAVE 5
	NOTE F#, 1
	DUTY 0
	PAN_BOTH 0
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 1
	LOOP_BREAK $FB
	RELEASE 0, 0
	DUTY 0
	OCTAVE 3
	NOTE E_, 1
	NOTE C_HI, 1
	DUTY 8
	PAN_RIGHT 0
	OCTAVE 5
	NOTE F#, 1
	DUTY 0
	PAN_BOTH 0
	OCTAVE 3
	NOTE A_, 1
	NOTE C_HI, 1
	DUTY 8
	PAN_RIGHT 0
	OCTAVE 5
	NOTE F#, 1
	DUTY 0
	PAN_BOTH 0
	OCTAVE 4
	NOTE C#, 1
	NOTE C_HI, 1
	LOOP_END $02
	RELEASE 0, 0
	DUTY 0
	OCTAVE 3
	NOTE C#, 1
	NOTE C_HI, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE C_HI, 1
	NOTE B_, 1
	NOTE A_, 1
	SND_RET
Snd6A_Ch1_7027:
	RELEASE $0F, 1
	DUTY 8
	PAN_LEFT 0
	OCTAVE 3
	VIBRATO $03, 0, 7
	ENVELOPE $11
	NOTE G_, 1
	VIBRATO_OFF
	PAN_BOTH 0
	ENVELOPE $00
	SND_RET
Snd6A_Ch1_703B:
	RELEASE $0F, 1
	DUTY 8
	PAN_RIGHT 0
	OCTAVE 3
	VIBRATO $03, 0, 7
	ENVELOPE $11
	NOTE B_, 1
	VIBRATO_OFF
	PAN_BOTH 0
	ENVELOPE $00
	SND_RET

Snd6B_Ch2:
	SND_SEGNO
	VOICE $09, 8, 6, 0, 0
	REST $0A
	OCTAVE 4
	NOTE A#, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE F_, 10
	NOTE G#, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 10
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE D_, 10
	OCTAVE 3
	NOTE B_, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE F#, 2
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D#, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE F_, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE F#, 2
	NOTE D#, 2
	NOTE G_, 2
	NOTE D#, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE D_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G#, 1
	NOTE D_, 1
	NOTE B_, 1
	NOTE D_, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE D_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE D_, 1
	NOTE F#, 8
	NOTE F_, 8
	OCTAVE 4
	NOTE D#, 8
	NOTE B_, 8
	NOTE D#, 1
	NOTE F#, 1
	NOTE A#, 2
	NOTE C#, 1
	NOTE D#, 1
	NOTE G#, 2
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE F#, 2
	OCTAVE 3
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 2
	NOTE D_, 12
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE A#, 8
	OCTAVE 4
	NOTE F#, 4
	VOICE $03, 8, 6, 0, 0
	NOTE F#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	VOICE $09, 8, 6, 0, 0
	NOTE D#, 0
	REST 2
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
	NOTE D_, 0
	REST 2
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	LOOP_START
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE G#, 1
	LOOP_END $02
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE D#, 0
	REST 2
	NOTE F#, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE D_, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE D_, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE G#, 1
	NOTE D_, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE D#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE D_, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE F#, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE F#, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE D_, 8
	OCTAVE 3
	NOTE A#, 4
	NOTE G#, 4
	OCTAVE 3
	NOTE F#, 1
	NOTE C_HI, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE D#, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	NOTE A#, 1
	RELEASE 8, 3
	NOTE F#, 4
	NOTE F#, 4
	REST 1
	RELEASE 0, 0
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE F#, 1
	RELEASE 8, 3
	NOTE F_, 4
	NOTE F_, 4
	REST 1
	RELEASE 0, 0
	LOOP_START
	NOTE G#, 1
	NOTE F#, 1
	LOOP_END $03
	NOTE F_, 1
	RELEASE 8, 3
	NOTE D#, 4
	NOTE D#, 4
	REST 1
	RELEASE 0, 0
	LOOP_START
	NOTE F#, 1
	NOTE F_, 1
	LOOP_END $03
	NOTE D#, 1
	NOTE D_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE G#, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE A#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE A_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	VOICE $06, 8, 6, 0, 0
	LOOP_START
	OCTAVE 4
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	LOOP_END $02
	LOOP_START
	OCTAVE 4
	NOTE G#, 1
	NOTE A#, 1
	NOTE B_, 1
	LOOP_END $02
	LOOP_START
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	LOOP_END $02
	LOOP_START
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	LOOP_END $02
	LOOP_START
	NOTE D#, 1
	NOTE E_, 1
	NOTE F#, 1
	LOOP_END $02
	LOOP_START
	NOTE C#, 1
	NOTE D#, 1
	NOTE E_, 1
	LOOP_END $02
	LOOP_START
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D#, 1
	LOOP_END $02
	LOOP_START
	OCTAVE 3
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	LOOP_END $02
	VOICE $09, 8, 6, 0, 0
	NOTE D_, 0
	NOTE F#, 8
	NOTE F_, 8
	RELEASE 4, 6
	NOTE F_, 8
	SND_LOOP

Snd6B_Ch1:
	SND_SEGNO
	VOICE $09, 8, 10, 0, 0
	REST $0A
	OCTAVE 4
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE D_, 10
	NOTE F_, 2
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 10
	OCTAVE 4
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 10
	NOTE G#, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE A#, 2
	NOTE D_, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE F#, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE F_, 2
	LOOP_START
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE A#, 2
	LOOP_END $02
	OCTAVE 4
	NOTE F_, 2
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE F_, 2
	NOTE G#, 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D#, 8
	NOTE D_, 8
	NOTE D#, 1
	NOTE F#, 1
	NOTE A#, 2
	NOTE F_, 1
	NOTE G#, 1
	NOTE B_, 2
	NOTE F#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE F_, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE D#, 0
	NOTE A#, 12
	NOTE G#, 2
	NOTE F_, 2
	NOTE D#, 8
	NOTE D_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE G#, 2
	NOTE F#, 1
	NOTE F_, 1
	NOTE F#, 14
	NOTE F#, 0
	NOTE F#, 0
	REST 2
	RELEASE 8, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE G#, 2
	RELEASE 0, 0
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE B_, 8
	NOTE G#, 8
	NOTE F#, 4
	NOTE F_, 4
	NOTE D_, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE F_, 2
	NOTE D#, 4
	NOTE F_, 4
	NOTE F#, 4
	OCTAVE 3
	NOTE F_, 4
	NOTE D#, 4
	NOTE C#, 4
	OCTAVE 2
	NOTE B_, 4
	NOTE G#, 4
	NOTE A#, 8
	NOTE G#, 4
	NOTE B_, 4
	NOTE G#, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_HI, 2
	NOTE F_, 2
	OCTAVE 3
	NOTE D_, 2
	RELEASE 8, 3
	NOTE A#, 4
	NOTE A#, 4
	REST 8
	LOOP_START
	NOTE B_, 4
	NOTE B_, 4
	REST 8
	LOOP_END $02
	RELEASE 5, 2
	OCTAVE 2
	NOTE G#, 2
	NOTE G#, 2
	REST 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE F#, 2
	REST 2
	NOTE F#, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE C_, 2
	REST 2
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	REST 2
	NOTE A_, 2
	VOICE $06, 8, 4, 0, 0
	DETUNE $FE
	REST 1
	LOOP_START
	OCTAVE 4
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	LOOP_END $02
	LOOP_START
	OCTAVE 4
	NOTE G#, 1
	NOTE A#, 1
	NOTE B_, 1
	LOOP_END $02
	LOOP_START
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	LOOP_END $02
	LOOP_START
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	LOOP_END $02
	LOOP_START
	NOTE D#, 1
	NOTE E_, 1
	NOTE F#, 1
	LOOP_END $02
	LOOP_START
	NOTE C#, 1
	NOTE D#, 1
	NOTE E_, 1
	LOOP_END $02
	LOOP_START
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D#, 1
	LOOP_END $02
	OCTAVE 3
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE B_, 1
	VOICE $09, 8, 10, 0, 0
	DETUNE $00
	OCTAVE 3
	NOTE G#, 0
	NOTE B_, 8
	NOTE F#, 8
	RELEASE 4, 6
	NOTE F#, 8
	SND_LOOP

Snd6B_Ch3:
	SND_SEGNO
	VOICE $09, 1, 2, 3, 4
	LOOP_START
	OCTAVE 3
	NOTE D#, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE D#, 8
	LOOP_END $04
	RELEASE 0, 0
	NOTE D#, 4
	NOTE F_, 4
	NOTE F#, 4
	NOTE F_, 4
	NOTE D#, 4
	NOTE C#, 4
	OCTAVE 2
	NOTE B_, 4
	NOTE G#, 4
	NOTE A#, 12
	NOTE A_, 2
	RELEASE 8, 2
	NOTE A#, 2
	RELEASE 0, 0
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE A#, 2
	NOTE F_, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE F#, 2
	NOTE D#, 2
	NOTE G_, 2
	NOTE D#, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE G#, 2
	NOTE B_, 2
	NOTE F#, 2
	NOTE A#, 2
	NOTE F_, 2
	NOTE G#, 2
	NOTE F#, 8
	NOTE F_, 8
	NOTE D#, 0
	NOTE D#, 0
	NOTE G#, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE D_, 0
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE G#, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 4
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A#, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE A#, 8
	OCTAVE 2
	NOTE A#, 0
	NOTE F#, 2
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE G#, 2
	NOTE B_, 2
	NOTE F#, 2
	NOTE A#, 2
	NOTE F_, 2
	NOTE G#, 2
	NOTE B_, 8
	NOTE A#, 8
	RELEASE 8, 3
	OCTAVE 3
	NOTE D#, 4
	NOTE D#, 4
	ATTEN 2
	REST 2
	DETUNE $FE
	RELEASE 0, 0
	OCTAVE 5
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	NOTE G#, 1
	DETUNE $00
	ATTEN 0
	RELEASE 8, 3
	OCTAVE 3
	NOTE D#, 4
	NOTE D#, 4
	ATTEN 2
	REST 2
	DETUNE $FE
	RELEASE 0, 0
	OCTAVE 5
	LOOP_START
	NOTE G#, 1
	NOTE F#, 1
	LOOP_END $03
	DETUNE $00
	ATTEN 0
	RELEASE 8, 3
	OCTAVE 3
	NOTE D#, 4
	NOTE D#, 4
	ATTEN 2
	REST 2
	DETUNE $FE
	RELEASE 0, 0
	OCTAVE 5
	LOOP_START
	NOTE F#, 1
	NOTE F_, 1
	LOOP_END $03
	DETUNE $00
	ATTEN 0
	RELEASE 5, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 2
	REST 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE D#, 2
	REST 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE F_, 2
	REST 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE F#, 2
	REST 2
	NOTE F#, 2
	RELEASE 0, 0
	OCTAVE 4
	NOTE D#, 4
	NOTE C#, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE A#, 4
	NOTE G#, 4
	NOTE F#, 4
	NOTE F_, 4
	NOTE D_, 4
	REST 2
	NOTE B_, 2
	NOTE G#, 2
	NOTE A#, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE A#, 8
	OCTAVE 2
	NOTE A#, 8
	RELEASE 4, 6
	NOTE A#, 8
	SND_LOOP

Snd6B_Drm:
	SND_END

Snd6C_Ch2:
	SND_SEGNO
	VOICE $08, 8, 15, 0, 0
	ENVELOPE $09
	VIBRATO $01, 4, 5
	OCTAVE 1
	NOTE G_, 0
	ENVELOPE $00
	VIBRATO $01, 0, 8
	NOTE G_, 0
	VIBRATO $03, 5, 1
	RELEASE 7, 7
	NOTE G_, 0
	RELEASE 0, 0
	ENVELOPE $08
	VIBRATO $01, 0, 8
	NOTE F_, 8
	ENVELOPE $00
	VIBRATO $07, 0, 8
	NOTE C_HI, 2
	VIBRATO $01, 3, 8
	NOTE C_HI, 6
	VIBRATO $01, 4, 8
	OCTAVE 2
	NOTE D#, 8
	RELEASE $0D, 6
	NOTE D#, 8
	RELEASE 0, 0
	ENVELOPE $09
	NOTE C_, 0
	ENVELOPE $00
	OCTAVE 1
	NOTE A_, 10
	RELEASE $0B, 6
	NOTE A_, 6
	RELEASE 0, 0
	VIBRATO $04, 0, 7
	ENVELOPE $09
	OCTAVE 2
	NOTE D_, 8
	ENVELOPE $00
	VIBRATO_OFF
	RELEASE $0D, 5
	ATTEN 3
	OCTAVE 1
	NOTE A_, 2
	ATTEN 2
	NOTE A#, 2
	ATTEN 1
	OCTAVE 2
	NOTE C_, 2
	ATTEN 0
	NOTE D_, 2
	VOICE $08, 8, 6, 0, 0
	VIBRATO_SEMI 1
	OCTAVE 4
	NOTE F#, 4
	VIBRATO $01, 0, 2
	ENVELOPE $06
	NOTE G_, 8
	VIBRATO $01, 0, 3
	ENVELOPE $00
	RELEASE 9, 5
	NOTE G_, 4
	VIBRATO $01, 2, 2
	RELEASE 0, 0
	ATTEN 1
	NOTE F#, 4
	ATTEN 0
	NOTE D#, 4
	NOTE D_, 4
	ATTEN 1
	NOTE C_, 4
	ATTEN 0
	VIBRATO_SEMI 3
	OCTAVE 3
	NOTE A_, 4
	VIBRATO $01, 0, 2
	NOTE A#, 8
	VIBRATO $01, 0, 3
	RELEASE 9, 3
	NOTE A#, 4
	ENVELOPE $06
	RELEASE 0, 0
	NOTE A_, 8
	VIBRATO_SEMI 2
	OCTAVE 4
	NOTE A_, 8
	VIBRATO_SEMI 1
	OCTAVE 4
	NOTE F#, 4
	VIBRATO $01, 0, 2
	NOTE G_, 6
	ENVELOPE $00
	VIBRATO_OFF
	RELEASE $0B, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE A_, 2
	RELEASE 0, 0
	VIBRATO $01, 2, 2
	ENVELOPE $06
	NOTE A#, 4
	ENVELOPE $00
	OCTAVE 5
	NOTE C#, 4
	OCTAVE 4
	NOTE A#, 4
	ATTEN 1
	NOTE A_, 4
	ATTEN 0
	VIBRATO_SEMI 1
	OCTAVE 5
	NOTE C_, 4
	VIBRATO $01, 0, 2
	ENVELOPE $06
	NOTE C#, 6
	DUTY 0
	RELEASE $0D, 2
	VIBRATO_OFF
	ENVELOPE $00
	OCTAVE 4
	NOTE D_, 2
	NOTE D#, 2
	NOTE G_, 2
	DUTY 8
	RELEASE 0, 0
	ENVELOPE $06
	VIBRATO $01, 2, 2
	OCTAVE 5
	NOTE D_, 8
	VIBRATO_OFF
	ENVELOPE $00
	DUTY 0
	RELEASE $0D, 2
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE F#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	VOICE $08, 8, 6, 0, 0
	VIBRATO $01, 3, 3
	ENVELOPE $06
	OCTAVE 3
	NOTE G_, 10
	VIBRATO_OFF
	ENVELOPE $00
	NOTE F#, 2
	NOTE G_, 2
	NOTE A_, 2
	VIBRATO $01, 3, 3
	RELEASE 0, 0
	ENVELOPE $06
	NOTE A#, 8
	ENVELOPE $00
	VIBRATO_OFF
	DUTY 0
	RELEASE $0B, 3
	OCTAVE 4
	NOTE G_, 2
	NOTE F#, 2
	NOTE D#, 2
	NOTE D_, 2
	VIBRATO $01, 3, 3
	DUTY 8
	RELEASE 0, 0
	ENVELOPE $06
	NOTE D#, 10
	ENVELOPE $00
	VIBRATO_OFF
	NOTE D_, 2
	NOTE C_, 2
	NOTE D#, 2
	VIBRATO $01, 3, 3
	ENVELOPE $06
	NOTE C#, 8
	ENVELOPE $10
	NOTE D_, 8
	ENVELOPE $06
	NOTE C_, 8
	ENVELOPE $00
	VIBRATO_OFF
	OCTAVE 3
	NOTE A#, 2
	NOTE A_, 4
	NOTE F#, 2
	VIBRATO $01, 2, 2
	NOTE G_, 4
	ATTEN 1
	NOTE A_, 4
	ATTEN 0
	NOTE A#, 4
	ENVELOPE $0F
	OCTAVE 4
	NOTE C_, 4
	VIBRATO $01, 3, 3
	ENVELOPE $06
	NOTE D_, 10
	ENVELOPE $00
	VIBRATO_OFF
	NOTE D#, 2
	NOTE F#, 2
	NOTE G_, 2
	VIBRATO_SEMI 4
	NOTE G#, 2
	RELEASE $0B, 2
	VIBRATO_OFF
	NOTE G_, 2
	NOTE F#, 2
	NOTE D#, 2
	RELEASE 0, 0
	VIBRATO $01, 3, 3
	NOTE D_, 8
	VOICE $08, 8, 6, 0, 0
	VIBRATO $01, 3, 3
	ENVELOPE $06
	OCTAVE 2
	NOTE G_, 8
	VIBRATO $04, 0, 2
	OCTAVE 3
	NOTE G_, 8
	VIBRATO_OFF
	NOTE F#, 8
	VIBRATO $04, 0, 2
	NOTE A#, 8
	VIBRATO_OFF
	NOTE G_, 8
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE G_, 8
	VIBRATO_OFF
	NOTE F#, 8
	VIBRATO $04, 0, 2
	NOTE A#, 8
	VIBRATO_SEMI 1
	ENVELOPE $00
	NOTE C#, 4
	VIBRATO $01, 0, 2
	NOTE D_, 8
	VIBRATO $01, 0, 3
	RELEASE 9, 4
	NOTE D_, 4
	RELEASE 0, 0
	ENVELOPE $00
	VIBRATO $04, 0, 1
	NOTE C_HI, 4
	VIBRATO $01, 0, 2
	NOTE C_HI, 6
	VIBRATO $03, 0, 1
	NOTE C_HI, 6
	SND_LOOP

Snd6C_Ch1:
	SND_SEGNO
	VOICE $08, 4, 6, 0, 0
	DETUNE $FC
	REST 1
	LOOP_START
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	LOOP_END $07
	NOTE F#, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE A#, 1
	VOICE $08, 8, 8, 13, 5
	DETUNE $00
	ATTEN 3
	OCTAVE 2
	NOTE A_, 2
	ATTEN 2
	NOTE A#, 2
	ATTEN 1
	OCTAVE 3
	NOTE C_, 2
	ATTEN 0
	NOTE D_, 2
	VOICE $08, 4, 10, 13, 5
	DETUNE $FE
	LOOP_START
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	LOOP_END $07
	RELEASE 0, 0
	ATTEN 3
	OCTAVE 2
	NOTE A_, 2
	ATTEN 2
	NOTE A#, 2
	ATTEN 1
	OCTAVE 3
	NOTE C_, 2
	ATTEN 0
	NOTE C#, 2
	VIBRATO $04, 0, 2
	NOTE D#, 4
	VIBRATO $01, 2, 2
	NOTE D_, 4
	VOICE $08, 8, 10, 0, 0
	VIBRATO $01, 3, 3
	ENVELOPE $06
	OCTAVE 3
	NOTE D#, 8
	NOTE D_, 8
	VIBRATO $01, 2, 2
	NOTE C_, 4
	ENVELOPE $00
	NOTE D_, 4
	VIBRATO_OFF
	DUTY 0
	RELEASE $0B, 3
	NOTE A#, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F#, 2
	DUTY 8
	VIBRATO $01, 2, 3
	RELEASE 0, 0
	ATTEN 1
	NOTE C_, 2
	ATTEN 0
	NOTE D_, 2
	NOTE F#, 2
	ENVELOPE $0F
	NOTE G_, 2
	NOTE A_, 2
	ENVELOPE $00
	NOTE G_, 2
	NOTE F#, 4
	VIBRATO $01, 3, 3
	ENVELOPE $06
	OCTAVE 3
	NOTE G_, 8
	ENVELOPE $00
	VIBRATO_OFF
	DUTY 0
	RELEASE $0B, 3
	NOTE F_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	VIBRATO $01, 3, 3
	RELEASE 0, 0
	ENVELOPE $06
	NOTE G_, 8
	ENVELOPE $00
	NOTE F#, 4
	NOTE C_, 4
	VIBRATO_OFF
	DUTY 8
	ATTEN 2
	REST 1
	LOOP_START
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	TRANSPOSE_DOWN 1
	LOOP_END $02
	TRANSPOSE_DOWN 0
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 1
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	ATTEN 0
	DUTY 8
	OCTAVE 3
	VIBRATO $01, 3, 3
	ENVELOPE $06
	NOTE A#, 8
	ENVELOPE $00
	VIBRATO_OFF
	OCTAVE 2
	NOTE A#, 2
	NOTE B_, 2
	ENVELOPE $0A
	OCTAVE 3
	NOTE C_, 2
	NOTE C#, 2
	VIBRATO $01, 2, 2
	ENVELOPE $00
	NOTE D_, 4
	NOTE C#, 4
	VIBRATO_OFF
	DUTY 0
	RELEASE $0D, 2
	NOTE D_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	VOICE $08, 8, 10, 0, 0
	VIBRATO_SEMI 1
	OCTAVE 3
	NOTE C#, 6
	ENVELOPE $06
	VIBRATO $01, 0, 3
	NOTE D_, 6
	RELEASE 9, 5
	ENVELOPE $00
	NOTE D_, 4
	RELEASE 0, 0
	ENVELOPE $06
	VIBRATO $01, 3, 3
	NOTE D#, 8
	VIBRATO $01, 2, 2
	ENVELOPE $00
	NOTE C_, 4
	NOTE D#, 4
	VIBRATO $01, 3, 3
	NOTE D_, 8
	VIBRATO $01, 2, 4
	NOTE C_, 4
	ATTEN 1
	NOTE D_, 4
	ATTEN 0
	NOTE D#, 4
	ATTEN 1
	NOTE D_, 4
	ATTEN 0
	NOTE C#, 4
	ENVELOPE $0A
	NOTE D#, 4
	ENVELOPE $00
	VIBRATO $01, 3, 4
	NOTE F#, 6
	NOTE D#, 4
	VIBRATO_OFF
	RELEASE 9, 1
	NOTE C#, 2
	NOTE D#, 2
	NOTE F#, 2
	VIBRATO $01, 1, 1
	LOOP_START
	RELEASE 9, 1
	NOTE D_, 2
	RELEASE 0, 0
	NOTE C_HI, 2
	TRANSPOSE_DOWN 2
	LOOP_END $02
	TRANSPOSE_DOWN 0
	LOOP_START
	RELEASE 9, 1
	OCTAVE 2
	NOTE A#, 2
	RELEASE 0, 0
	NOTE C_HI, 2
	TRANSPOSE_DOWN 2
	LOOP_END $02
	TRANSPOSE_DOWN 0
	SND_LOOP

Snd6C_Ch3:
	SND_SEGNO
	VOICE $08, 9, 4, 14, 7
	TRANSPOSE_UP $0C
	LOOP_START
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	LOOP_END $07
	NOTE F#, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE F#, 2
	VOICE $08, 1, 2, 6, 1
	TRANSPOSE_UP 0
	LOOP_START
	RELEASE 6, 1
	OCTAVE 2
	NOTE G_, 2
	RELEASE $0A, 1
	NOTE G_, 2
	RELEASE $0D, 2
	PAN_LEFT 0
	WAVE 9
	OCTAVE 6
	NOTE G_, 2
	PAN_BOTH 0
	WAVE 1
	RELEASE 5, 1
	OCTAVE 2
	NOTE G_, 4
	RELEASE 9, 1
	NOTE G_, 2
	PAN_LEFT 0
	WAVE 9
	RELEASE $0D, 2
	OCTAVE 6
	NOTE G_, 2
	WAVE 1
	PAN_BOTH 0
	RELEASE 6, 1
	OCTAVE 2
	NOTE G_, 2
	LOOP_BREAK $FB
	OCTAVE 2
	NOTE G_, 2
	RELEASE $0A, 1
	NOTE G_, 2
	RELEASE $0D, 2
	PAN_RIGHT 0
	WAVE 9
	OCTAVE 6
	NOTE G_, 2
	PAN_BOTH 0
	WAVE 1
	RELEASE 5, 1
	OCTAVE 2
	NOTE G#, 4
	RELEASE 9, 1
	NOTE G_, 2
	PAN_RIGHT 0
	WAVE 9
	RELEASE $0D, 2
	OCTAVE 6
	NOTE G_, 2
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 2
	NOTE F#, 2
	LOOP_END $02
	OCTAVE 2
	NOTE F_, 2
	RELEASE $0A, 1
	OCTAVE 3
	NOTE D_, 2
	RELEASE $0D, 2
	PAN_RIGHT 0
	WAVE 9
	OCTAVE 6
	NOTE G_, 2
	PAN_BOTH 0
	WAVE 1
	RELEASE 5, 1
	OCTAVE 3
	NOTE F_, 4
	RELEASE 9, 1
	NOTE F#, 2
	PAN_RIGHT 0
	WAVE 9
	RELEASE $0D, 2
	OCTAVE 6
	NOTE G_, 2
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 3
	RELEASE 6, 1
	NOTE D#, 2
	RELEASE $0A, 1
	NOTE D#, 2
	RELEASE $0D, 2
	PAN_LEFT 0
	WAVE 9
	OCTAVE 6
	NOTE G_, 2
	PAN_BOTH 0
	WAVE 1
	RELEASE 5, 1
	OCTAVE 3
	NOTE D#, 4
	RELEASE 9, 1
	NOTE D#, 2
	PAN_LEFT 0
	WAVE 9
	RELEASE $0D, 2
	OCTAVE 6
	NOTE G_, 2
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE D_, 2
	RELEASE 6, 1
	OCTAVE 3
	NOTE C_, 2
	RELEASE $0A, 1
	NOTE C_, 2
	RELEASE $0D, 2
	PAN_RIGHT 0
	WAVE 9
	OCTAVE 6
	NOTE G_, 2
	PAN_BOTH 0
	WAVE 1
	RELEASE 5, 1
	OCTAVE 3
	NOTE C_, 4
	RELEASE 9, 1
	NOTE C_, 2
	PAN_RIGHT 0
	WAVE 9
	RELEASE $0D, 2
	OCTAVE 6
	NOTE G_, 2
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 2
	NOTE A#, 2
	RELEASE 6, 1
	OCTAVE 2
	NOTE A_, 2
	RELEASE $0A, 1
	NOTE A_, 2
	RELEASE $0D, 2
	PAN_LEFT 0
	WAVE 9
	OCTAVE 6
	NOTE G_, 2
	PAN_BOTH 0
	WAVE 1
	RELEASE 5, 1
	OCTAVE 2
	NOTE A_, 4
	RELEASE 9, 1
	OCTAVE 3
	NOTE D#, 2
	PAN_LEFT 0
	WAVE 9
	RELEASE $0D, 2
	OCTAVE 6
	NOTE G_, 2
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 2
	VIBRATO $01, 2, 4
	OCTAVE 3
	NOTE D_, 8
	VIBRATO $04, 0, 3
	NOTE G_, 4
	VIBRATO $01, 3, 3
	NOTE F#, 4
	VIBRATO_OFF
	RELEASE 6, 1
	OCTAVE 3
	NOTE D#, 3
	RELEASE 0, 0
	NOTE D#, 1
	REST 2
	NOTE D#, 2
	REST 2
	NOTE F#, 2
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE G_, 6
	RELEASE 6, 1
	VIBRATO $04, 0, 4
	OCTAVE 3
	NOTE G_, 2
	VIBRATO_OFF
	RELEASE $0B, 2
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE A_, 2
	RELEASE 0, 0
	OCTAVE 3
	NOTE C_, 4
	VIBRATO $04, 0, 2
	RELEASE 9, 1
	NOTE C_HI, 2
	RELEASE 0, 0
	VIBRATO_OFF
	NOTE C_, 2
	VIBRATO $04, 0, 3
	RELEASE 6, 1
	NOTE C_HI, 2
	RELEASE 0, 0
	VIBRATO_OFF
	NOTE D#, 2
	NOTE A_, 2
	NOTE F#, 2
	RELEASE 6, 1
	NOTE G_, 2
	RELEASE 9, 1
	NOTE G_, 2
	REST 2
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	NOTE G_, 4
	VIBRATO_OFF
	NOTE F_, 2
	NOTE G_, 2
	NOTE F_, 2
	RELEASE 6, 1
	NOTE D#, 2
	RELEASE 0, 0
	NOTE D#, 2
	WAVE $0B
	RELEASE $0C, 4
	PAN_LEFT 0
	OCTAVE 5
	NOTE A#, 2
	WAVE 1
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE D#, 2
	WAVE $0B
	RELEASE $0C, 4
	PAN_RIGHT 0
	OCTAVE 6
	NOTE C_, 2
	PAN_BOTH 0
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 2
	WAVE $0B
	RELEASE $0C, 4
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 2
	PAN_BOTH 0
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 2
	LOOP_START
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	TRANSPOSE_DOWN 1
	LOOP_END $02
	TRANSPOSE_DOWN 0
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 2
	VIBRATO $04, 0, 2
	RELEASE 9, 1
	NOTE C_HI, 2
	VIBRATO_OFF
	WAVE $0B
	RELEASE $0C, 4
	PAN_RIGHT 0
	OCTAVE 5
	NOTE A#, 2
	PAN_BOTH 0
	WAVE 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE C_, 2
	WAVE $0B
	RELEASE $0C, 4
	PAN_LEFT 0
	OCTAVE 6
	NOTE C_, 2
	PAN_BOTH 0
	WAVE 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE C#, 2
	WAVE $0B
	RELEASE $0C, 4
	PAN_RIGHT 0
	OCTAVE 6
	NOTE C#, 2
	PAN_BOTH 0
	WAVE 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE C#, 2
	WAVE $0B
	RELEASE $0C, 4
	PAN_LEFT 0
	OCTAVE 6
	NOTE D_, 2
	PAN_BOTH 0
	RELEASE 9, 1
	WAVE 1
	OCTAVE 3
	NOTE D_, 2
	RELEASE 6, 1
	NOTE D_, 2
	RELEASE 9, 1
	NOTE D_, 2
	WAVE $0B
	RELEASE $0C, 4
	PAN_RIGHT 0
	OCTAVE 5
	NOTE A_, 2
	PAN_BOTH 0
	WAVE 1
	RELEASE 6, 1
	OCTAVE 3
	NOTE D_, 2
	RELEASE 9, 1
	NOTE D_, 2
	RELEASE 0, 0
	NOTE D_, 2
	VOICE $08, 1, 2, 0, 0
	VIBRATO $01, 4, 6
	OCTAVE 2
	NOTE G_, 0
	WAVE 9
	ATTEN 1
	RELEASE 9, 5
	VIBRATO_SEMI 4
	OCTAVE 3
	NOTE A_, 3
	VIBRATO_OFF
	NOTE A_, 3
	NOTE F#, 2
	VIBRATO_SEMI 4
	NOTE D_, 4
	VIBRATO_OFF
	NOTE D_, 2
	NOTE C_, 2
	ATTEN 0
	RELEASE 0, 0
	WAVE 1
	VIBRATO $01, 4, 6
	OCTAVE 2
	NOTE A#, 0
	VIBRATO $04, 0, 5
	OCTAVE 3
	NOTE C_, 4
	VIBRATO $01, 0, 6
	NOTE C_, 12
	VIBRATO $04, 0, 5
	NOTE D_, 4
	VIBRATO $01, 0, 6
	NOTE D_, 6
	VIBRATO_OFF
	RELEASE 9, 4
	NOTE D#, 2
	NOTE F#, 2
	NOTE A#, 2
	RELEASE 0, 0
	VIBRATO $01, 2, 6
	NOTE F#, 4
	NOTE D#, 4
	NOTE D_, 4
	NOTE C_, 4
	ATTEN 0
	VIBRATO_OFF
	SND_LOOP

Snd6C_Drm:
	LEN_UNIT $08
	SND_SEGNO
	DRUM $0C, 0
	DRUM 9, 6
	DRUM 9, $0A
	REST 6
	DRUM 9, $0A
	DRUM 9, 6
	DRUM 9, 6
	DRUM 9, 4
	DRUM $0C, $0A
	DRUM 9, 6
	DRUM 9, 6
	DRUM 9, $0A
	DRUM 9, 8
	DRUM 9, 2
	DRUM 7, 2
	DRUM $0A, 4
	DRUM 9, 8
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM $0C, 8
	DRUM 9, 4
	DRUM 7, 2
	DRUM 7, 2
	DRUM $0A, $0E
	DRUM 7, 2
	LOOP_START
	DRUM 9, 8
	DRUM 9, 4
	DRUM 7, 2
	DRUM 7, 2
	DRUM $0A, 6
	LOOP_BREAK $FB
	REST 8
	DRUM 7, 2
	LOOP_END $03
	DRUM 9, 2
	DRUM 7, 1
	DRUM 7, 1
	DRUM $0A, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM $0C, 2
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
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0A, 2
	LOOP2_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 3, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 3, 1
	LOOP2_END $02
	DRUM $0C, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM $0C, 2
	DRUM $0A, 2
	DRUM 9, 1
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
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM $0A, 2
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
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0A, 2
	DRUM 9, 1
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
	DRUM 9, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM $0A, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 3, 1
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
	DRUM 3, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	SND_LOOP

SECTION "Sound bank $0E", ROMX[$4000], BANK[$0E]

Snd6E_Ch2:
	SND_SEGNO
	VOICE $04, 8, 8, 15, 1
	DETUNE $FC
	OCTAVE 1
	REST 1
	RELEASE 5, 2
	NOTE D_, 6
	RELEASE $0D, 1
	NOTE D_, 2
	RELEASE 5, 3
	NOTE D_, 8
	RELEASE 7, 7
	NOTE D_, 0
	SND_LOOP
	db $FF ; unreachable end

Snd6E_Ch1:
	SND_SEGNO
	VOICE $04, 8, 4, 15, 1
	DETUNE $14
	OCTAVE 1
	REST 2
	RELEASE 5, 2
	NOTE D_, 6
	RELEASE $0D, 1
	NOTE D_, 2
	RELEASE 5, 3
	NOTE D_, 8
	RELEASE 7, 7
	NOTE D_, 0
	SND_LOOP
	db $FF ; unreachable end

Snd6E_Ch3:
	SND_SEGNO
	VOICE $04, 1, 2, 15, 1
	TRANSPOSE_UP $0C
	WAVE_X $68
	RELEASE 5, 2
	OCTAVE 1
	NOTE D_, 6
	WAVE 1
	RELEASE $0D, 1
	NOTE D_, 2
	WAVE_X $6A
	RELEASE 5, 3
	NOTE D_, 8
	WAVE_X $6A
	RELEASE 7, 7
	NOTE D_, 0
	SND_LOOP

Snd6E_Drm:
	SND_SEGNO
	LEN_UNIT $04
	DRUM_SND $19, 13
	DRUM_SND $1A, 13
	DRUM_SND $1B, 13
	DRUM_SND $19, 13
	DRUM_SND $1A, 13
	SND_LOOP

Snd6F_Ch2:
	VOICE $06, 0, 13, 15, 2
	OCTAVE 3
	NOTE G_, 2
	LOOP_START
	NOTE G#, 2
	OCTAVE 3
	DUTY 1
	NOTE D#, 2
	DUTY 4
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	ATTEN 5
	OCTAVE 4
	NOTE D_, 2
	RELEASE $0F, 2
	VIBRATO_OFF
	NOTE D#, 2
	ATTEN 0
	DUTY 1
	OCTAVE 3
	NOTE E_, 2
	DUTY 4
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	ATTEN 5
	OCTAVE 4
	NOTE E_, 2
	RELEASE $0F, 2
	VIBRATO_OFF
	NOTE D#, 2
	DUTY 1
	ATTEN 0
	OCTAVE 3
	NOTE F_, 2
	DUTY 4
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	ATTEN 5
	OCTAVE 4
	NOTE D_, 2
	RELEASE $0F, 2
	VIBRATO_OFF
	NOTE D#, 2
	ATTEN 0
	DUTY 1
	OCTAVE 3
	NOTE E_, 2
	DUTY 4
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	ATTEN 5
	OCTAVE 4
	NOTE D_, 2
	RELEASE $0F, 2
	VIBRATO_OFF
	NOTE D#, 2
	ATTEN 0
	DUTY 1
	OCTAVE 3
	NOTE E_, 2
	DUTY 8
	NOTE G_, 2
	NOTE G#, 2
	TRANSPOSE_UP 1
	LOOP_END $02
	TRANSPOSE_UP 0
	VIBRATO $01, 3, 2
	RELEASE 0, 0
	OCTAVE 3
	ENVELOPE $08
	NOTE A#, 6
	ENVELOPE $00
	ATTEN 2
	NOTE G#, 6
	NOTE A#, 4
	ATTEN 0
	ENVELOPE $08
	NOTE B_, 6
	ENVELOPE $00
	ATTEN 2
	NOTE A_, 6
	NOTE B_, 4
	VOICE $06, 8, 8, 15, 1
	OCTAVE 4
	NOTE G#, 2
	NOTE G#, 2
	ATTEN 4
	NOTE G#, 2
	ATTEN 0
	NOTE G_, 2
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 4
	NOTE F#, 2
	ATTEN 0
	NOTE F_, 2
	NOTE F_, 2
	ATTEN 4
	NOTE F_, 2
	ATTEN 0
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 4
	NOTE E_, 2
	ATTEN 0
	NOTE D#, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE D_, 2
	ATTEN 4
	NOTE D_, 2
	ATTEN 0
	NOTE C#, 2
	NOTE C#, 2
	ATTEN 4
	NOTE C#, 2
	ATTEN 0
	NOTE C_, 2
	NOTE C_, 2
	ATTEN 4
	NOTE C_, 2
	ATTEN 0
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE A_, 2
	SND_END

Snd6F_Ch1:
	VOICE $06, 0, 13, 15, 2
	OCTAVE 3
	NOTE D_, 2
	LOOP_START
	NOTE D#, 2
	OCTAVE 2
	DUTY 1
	NOTE A#, 2
	DUTY 4
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	ATTEN 4
	OCTAVE 3
	NOTE G#, 2
	RELEASE $0F, 2
	VIBRATO_OFF
	NOTE A_, 2
	ATTEN 0
	DUTY 1
	NOTE C_, 2
	DUTY 4
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	ATTEN 4
	NOTE A#, 2
	RELEASE $0F, 2
	VIBRATO_OFF
	NOTE A_, 2
	DUTY 1
	ATTEN 0
	NOTE C#, 2
	DUTY 4
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	ATTEN 4
	NOTE G#, 2
	RELEASE $0F, 2
	VIBRATO_OFF
	NOTE A_, 2
	ATTEN 0
	DUTY 1
	NOTE C_, 2
	DUTY 4
	RELEASE 0, 0
	VIBRATO $01, 1, 3
	ATTEN 4
	NOTE G#, 2
	RELEASE $0F, 2
	VIBRATO_OFF
	NOTE A_, 2
	ATTEN 0
	DUTY 1
	NOTE C_, 2
	DUTY 8
	NOTE C#, 2
	NOTE D#, 2
	TRANSPOSE_UP 1
	LOOP_END $02
	TRANSPOSE_UP 0
	VIBRATO $01, 3, 3
	RELEASE 0, 0
	OCTAVE 3
	ENVELOPE $08
	NOTE F#, 6
	ATTEN 4
	ENVELOPE $00
	NOTE D#, 6
	NOTE F#, 4
	ENVELOPE $08
	ATTEN 0
	NOTE G_, 6
	ATTEN 4
	ENVELOPE $00
	NOTE E_, 6
	NOTE G_, 4
	VOICE $06, 8, 10, 15, 1
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 2
	ATTEN 4
	NOTE E_, 2
	ATTEN 0
	NOTE D#, 2
	NOTE D#, 2
	ATTEN 4
	NOTE D#, 2
	ATTEN 0
	NOTE D_, 2
	NOTE D_, 2
	ATTEN 4
	NOTE D_, 2
	ATTEN 0
	NOTE C#, 2
	NOTE C#, 2
	ATTEN 4
	NOTE C#, 2
	ATTEN 0
	NOTE C_, 2
	NOTE C_, 2
	ATTEN 4
	NOTE C_, 2
	ATTEN 0
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE A#, 2
	ATTEN 4
	NOTE A#, 2
	ATTEN 0
	NOTE A_, 2
	NOTE A_, 2
	ATTEN 4
	NOTE A_, 2
	ATTEN 0
	NOTE G#, 2
	NOTE G#, 2
	ATTEN 4
	NOTE G#, 2
	ATTEN 0
	NOTE G_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE F_, 2
	SND_END

Snd6F_Ch3:
	VOICE $06, 1, 2, 15, 3
	OCTAVE 2
	NOTE A_, 2
	LOOP2_START
	LOOP_START
	RELEASE 0, 0
	WAVE 1
	NOTE G#, 2
	RELEASE $0F, 2
	WAVE 7
	NOTE C_HI, 2
	REST 2
	LOOP_END $02
	RELEASE 0, 0
	WAVE 1
	NOTE G#, 2
	RELEASE $0F, 2
	WAVE 7
	OCTAVE 3
	NOTE A_, 2
	REST 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE G#, 2
	RELEASE $0F, 2
	WAVE 7
	NOTE C_HI, 2
	REST 2
	RELEASE 0, 0
	WAVE 1
	NOTE F#, 2
	RELEASE $0F, 2
	WAVE 7
	OCTAVE 3
	NOTE A_, 2
	RELEASE $0F, 3
	WAVE 1
	OCTAVE 2
	NOTE G#, 2
	NOTE A#, 2
	TRANSPOSE_UP 1
	LOOP2_END $02
	TRANSPOSE_UP 0
	OCTAVE 2
	RELEASE 0, 0
	VIBRATO $01, 3, 4
	NOTE A_, 0
	NOTE A#, 0
	RELEASE $0F, 3
	VIBRATO_OFF
	WAVE 9
	OCTAVE 3
	NOTE F_, 2
	RELEASE 0, 0
	WAVE $0B
	VIBRATO $05, 0, 2
	NOTE C_HI, 1
	VIBRATO $01, 0, 4
	NOTE C_HI, 3
	RELEASE $0F, 3
	VIBRATO_OFF
	WAVE 9
	NOTE E_, 2
	RELEASE 0, 0
	WAVE $0B
	VIBRATO $05, 0, 2
	NOTE C_HI, 1
	VIBRATO $01, 0, 4
	NOTE C_HI, 3
	RELEASE $0F, 3
	VIBRATO_OFF
	WAVE 9
	NOTE D#, 2
	RELEASE 0, 0
	WAVE $0B
	VIBRATO $05, 0, 2
	NOTE C_HI, 1
	VIBRATO $01, 0, 4
	NOTE C_HI, 3
	RELEASE $0F, 3
	VIBRATO_OFF
	WAVE 9
	NOTE D_, 2
	RELEASE 0, 0
	WAVE $0B
	VIBRATO $05, 0, 2
	NOTE C_HI, 1
	VIBRATO $01, 0, 4
	NOTE C_HI, 3
	RELEASE $0F, 3
	VIBRATO_OFF
	WAVE 9
	NOTE C#, 2
	RELEASE 0, 0
	WAVE $0B
	VIBRATO $05, 0, 2
	NOTE C_HI, 1
	VIBRATO $01, 0, 4
	NOTE C_HI, 3
	RELEASE $0F, 3
	VIBRATO_OFF
	WAVE 9
	NOTE C_, 2
	RELEASE 0, 0
	WAVE $0B
	VIBRATO $01, 0, 4
	NOTE C_HI, 2
	RELEASE $0F, 3
	VIBRATO_OFF
	WAVE 9
	OCTAVE 2
	NOTE B_, 2
	RELEASE 0, 0
	WAVE $0B
	VIBRATO $05, 0, 2
	NOTE C_HI, 1
	VIBRATO $01, 0, 4
	NOTE C_HI, 3
	RELEASE $0F, 3
	VIBRATO_OFF
	WAVE 9
	NOTE A#, 2
	RELEASE 0, 0
	WAVE $0B
	VIBRATO $05, 0, 2
	NOTE C_HI, 1
	VIBRATO $01, 0, 4
	NOTE C_HI, 3
	RELEASE $0F, 3
	VIBRATO_OFF
	WAVE 9
	NOTE A_, 2
	RELEASE 0, 0
	WAVE $0B
	VIBRATO $05, 0, 2
	NOTE C_HI, 1
	VIBRATO $01, 0, 4
	NOTE C_HI, 3
	RELEASE $0F, 3
	VIBRATO_OFF
	WAVE 9
	NOTE G#, 2
	RELEASE 0, 0
	WAVE $0B
	VIBRATO $01, 0, 4
	NOTE C_HI, 2
	RELEASE $0F, 3
	VIBRATO_OFF
	WAVE 9
	NOTE G_, 2
	RELEASE 0, 0
	WAVE $0B
	VIBRATO $01, 0, 4
	NOTE C_HI, 2
	RELEASE $0F, 3
	VIBRATO_OFF
	WAVE 9
	NOTE F#, 2
	RELEASE 0, 0
	WAVE $0B
	VIBRATO $01, 0, 4
	NOTE C_HI, 2
	SND_END

Snd6F_Drm:
	LEN_UNIT $06
	REST 2
	DRUM $0C, 4
	LOOP_START
	DRUM_SND $0D, 2
	DRUM_SND $0D, 2
	DRUM 3, 2
	LOOP_END $03
	DRUM_SND $0D, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM $0C, 4
	DRUM_SND $0D, 2
	DRUM 3, 2
	LOOP_START
	DRUM_SND $0D, 2
	DRUM_SND $0D, 2
	DRUM 3, 2
	LOOP_END $02
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM_SND $0D, 2
	DRUM $0C, $0E
	DRUM_SND $0D, 2
	DRUM $0C, $0A
	DRUM_SND $0D, 2
	DRUM_SND $0D, 2
	DRUM_SND $0D, 2
	DRUM $0C, 0
	REST 0
	REST 0
	REST $0C
	DRUM_SND $0E, 1
	SND_END

Snd70_Ch2:
	VOICE $06, 4, 9, 15, 1
	DUTY_STEP 8, 1
	DETUNE $02
	REST 0
	REST 3
	PAN_LEFT 0
	OCTAVE 2
	ATTEN 3
	NOTE G#, 1
	NOTE F#, 1
	ATTEN 2
	NOTE G#, 1
	NOTE F#, 1
	ATTEN 1
	NOTE G#, 1
	NOTE F#, 1
	ATTEN 0
	NOTE G#, 1
	NOTE F#, 1
	VOICE $06, 4, 13, 15, 1
	PAN_LEFT 0
	ATTEN 3
	NOTE A_, 1
	NOTE G_, 1
	ATTEN 2
	NOTE A_, 1
	NOTE G_, 1
	ATTEN 1
	NOTE A_, 1
	NOTE G_, 1
	ATTEN 0
	NOTE A_, 1
	NOTE G_, 1
	VOICE $06, 4, 15, 15, 1
	PAN_RIGHT 0
	ATTEN 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	ATTEN 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	ATTEN 2
	NOTE A#, 1
	NOTE G_, 1
	ATTEN 3
	NOTE A#, 1
	NOTE G_, 1
	ATTEN 4
	NOTE A#, 1
	NOTE G_, 1
	ATTEN 5
	NOTE A#, 1
	NOTE G_, 1
	VOICE $06, 4, 9, 15, 1
	PAN_BOTH 0
	OCTAVE 2
	ATTEN 0
	NOTE G#, 1
	NOTE F#, 1
	ATTEN 1
	NOTE G#, 1
	NOTE F#, 1
	ATTEN 2
	NOTE G#, 1
	NOTE F#, 1
	ATTEN 3
	NOTE G#, 1
	NOTE F#, 1
	ATTEN 3
	NOTE A_, 1
	NOTE G_, 1
	ATTEN 2
	NOTE A_, 1
	NOTE G_, 1
	ATTEN 1
	NOTE A_, 1
	NOTE G_, 1
	ATTEN 0
	NOTE A_, 1
	NOTE G_, 1
	VOICE $06, 4, 13, 15, 1
	PAN_LEFT 0
	ATTEN 3
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	ATTEN 2
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	ATTEN 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	VOICE $06, 4, 15, 15, 1
	PAN_LEFT 0
	ATTEN 1
	NOTE A#, 1
	NOTE G_, 1
	ATTEN 0
	NOTE A#, 1
	NOTE G_, 1
	ATTEN 0
	NOTE A#, 1
	NOTE G_, 1
	ATTEN 1
	NOTE A#, 1
	NOTE G_, 1
	PAN_RIGHT 0
	OCTAVE 2
	ATTEN 2
	NOTE G#, 1
	NOTE F#, 1
	ATTEN 3
	NOTE G#, 1
	NOTE F#, 1
	ATTEN 4
	NOTE G#, 1
	NOTE F#, 1
	ATTEN 5
	NOTE G#, 1
	NOTE F#, 1
	VOICE $06, 4, 13, 15, 1
	PAN_RIGHT 0
	ATTEN 4
	NOTE A_, 1
	NOTE G_, 1
	ATTEN 5
	NOTE A_, 1
	NOTE G_, 1
	ATTEN 6
	NOTE A_, 1
	NOTE G_, 1
	ATTEN 7
	NOTE A_, 1
	NOTE G_, 1
	PAN_BOTH 0
	ATTEN 7
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	ATTEN 6
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	ATTEN 5
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	ATTEN 4
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	ATTEN 3
	NOTE A#, 1
	NOTE G_, 1
	ATTEN 2
	NOTE A#, 1
	NOTE G_, 1
	ATTEN 1
	NOTE A#, 1
	NOTE G_, 1
	ATTEN 0
	NOTE A#, 1
	NOTE G_, 1
	VOICE $06, 4, 15, 15, 1
	PAN_LEFT 0
	OCTAVE 2
	ATTEN 2
	NOTE G#, 1
	NOTE F#, 1
	ATTEN 1
	NOTE G#, 1
	NOTE F#, 1
	ATTEN 0
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 1
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
	VOICE $06, 8, 15, 0, 0
	PAN_LEFT 0
	DUTY 8
	ATTEN 4
	REST 1
	VIBRATO $05, 0, 2
	OCTAVE 5
	NOTE E_, 1
	VIBRATO $03, 5, 1
	RELEASE $0D, 7
	NOTE E_, 9
	ATTEN 7
	VIBRATO $05, 0, 2
	RELEASE 0, 0
	NOTE E_, 1
	VIBRATO $03, 5, 1
	RELEASE $0D, 7
	OCTAVE 5
	NOTE E_, 9
	VOICE $06, 8, 4, 0, 0
	PAN_LEFT 0
	ATTEN 0
	VIBRATO $05, 0, 2
	OCTAVE 5
	NOTE E_, 1
	VIBRATO $03, 5, 1
	RELEASE $0C, 5
	OCTAVE 5
	NOTE E_, 8
	SND_END

Snd70_Ch1:
	VOICE $06, 8, 13, 0, 0
	DETUNE $FE
	REST 0
	REST 3
	ENVELOPE $0E
	VIBRATO $01, 3, 5
	OCTAVE 2
	NOTE F#, 8
	VIBRATO $04, 0, 3
	ENVELOPE $08
	NOTE C_HI, 4
	VIBRATO $01, 0, 4
	ENVELOPE $00
	NOTE C_HI, 4
	VIBRATO $01, 3, 5
	OCTAVE 3
	ENVELOPE $0E
	NOTE E_, 8
	ENVELOPE $00
	ATTEN 6
	NOTE C_, 8
	ATTEN 0
	VIBRATO $04, 0, 4
	ENVELOPE $0E
	NOTE D#, 4
	VIBRATO $01, 0, 4
	ENVELOPE $00
	ATTEN 4
	NOTE D#, 4
	ATTEN 6
	OCTAVE 2
	NOTE B_, 8
	ATTEN 0
	ENVELOPE $0E
	NOTE G_, 8
	ENVELOPE $08
	NOTE D#, 8
	ENVELOPE $00
	RELEASE 8, 5
	NOTE F#, 8
	RELEASE 0, 0
	ENVELOPE $08
	VIBRATO $04, 0, 3
	NOTE C_HI, 4
	ENVELOPE $00
	ATTEN 2
	VIBRATO $01, 0, 4
	NOTE C_HI, 4
	VIBRATO $01, 3, 3
	ENVELOPE $08
	ATTEN 0
	OCTAVE 3
	NOTE G_, 8
	ENVELOPE $0E
	NOTE G#, 8
	ATTEN 0
	ENVELOPE $08
	NOTE A_, 8
	RELEASE 9, 5
	ENVELOPE $0E
	NOTE A#, 8
	VOICE $06, 8, 13, 0, 0
	PAN_RIGHT 0
	ATTEN 4
	REST 2
	VIBRATO $05, 0, 2
	OCTAVE 5
	NOTE E_, 1
	RELEASE $0D, 7
	VIBRATO $03, 5, 1
	NOTE E_, 9
	ATTEN 7
	VIBRATO $05, 0, 2
	RELEASE 0, 0
	NOTE E_, 1
	VIBRATO $03, 5, 1
	RELEASE $0D, 7
	OCTAVE 5
	NOTE E_, 9
	VOICE $06, 8, 3, 0, 0
	PAN_RIGHT 0
	ATTEN 0
	VIBRATO $05, 0, 2
	OCTAVE 5
	NOTE E_, 1
	VIBRATO $03, 5, 1
	RELEASE $0C, 5
	OCTAVE 5
	NOTE E_, 7
	SND_END

Snd70_Ch3:
	VOICE $06, 1, 2, 0, 0
	REST 0
	REST 3
	VIBRATO $01, 4, 7
	OCTAVE 2
	NOTE F#, 0
	OCTAVE 3
	NOTE C#, 0
	NOTE C_, 0
	OCTAVE 2
	NOTE G#, 0
	NOTE F#, 0
	OCTAVE 3
	NOTE C#, 0
	NOTE C_, 0
	VOICE $06, 1, 2, 10, 7
	INSTRUMENT $0A
	VIBRATO $05, 0, 2
	RELEASE 0, 0
	NOTE E_, 1
	VIBRATO $03, 5, 1
	RELEASE $0A, 7
	OCTAVE 6
	NOTE E_, 9
	ATTEN 1
	VIBRATO $05, 0, 2
	RELEASE 0, 0
	NOTE E_, 1
	VIBRATO $03, 5, 1
	RELEASE $0A, 7
	OCTAVE 6
	NOTE E_, 9
	ATTEN 2
	VIBRATO $05, 0, 2
	RELEASE 0, 0
	NOTE E_, 1
	VIBRATO $03, 5, 1
	RELEASE $0F, 6
	OCTAVE 6
	NOTE E_, 9
	SND_END

Snd70_Drm:
	LEN_UNIT $06
	DRUM_SND $11, 1
	SND_END

Snd71_Ch2:
	VOICE $06, 8, 8, 0, 0
	VIBRATO $01, 2, 4
	ENVELOPE $15
	OCTAVE 3
	NOTE E_, 8
	ENVELOPE $00
	ATTEN 2
	NOTE C_, 8
	ATTEN 0
	ENVELOPE $03
	OCTAVE 2
	NOTE B_, 8
	ENVELOPE $19
	NOTE G_, 8
	ENVELOPE $00
	ATTEN 2
	NOTE E_, 8
	ATTEN 0
	VIBRATO $01, 0, 4
	ENVELOPE $03
	NOTE E_, 0
	VIBRATO $01, 2, 4
	ATTEN 2
	ENVELOPE $00
	NOTE F#, 8
	ATTEN 0
	VIBRATO $01, 0, 4
	ENVELOPE $03
	NOTE F#, 0
	ENVELOPE $00
	VOICE $06, 8, 10, 11, 5
	VIBRATO $01, 0, 4
	NOTE F#, 0
	SND_END

Snd71_Ch1:
	VOICE $06, 8, 11, 0, 0
	VIBRATO $01, 2, 5
	ENVELOPE $01
	ATTEN 4
	OCTAVE 3
	NOTE C_, 8
	ENVELOPE $00
	ATTEN 2
	OCTAVE 2
	NOTE G#, 8
	ENVELOPE $17
	NOTE D#, 8
	ATTEN 0
	ENVELOPE $01
	NOTE D_, 8
	ENVELOPE $00
	OCTAVE 1
	ATTEN 2
	NOTE A#, 8
	VIBRATO $01, 0, 5
	ATTEN 0
	ENVELOPE $1A
	NOTE A#, 0
	ENVELOPE $00
	ATTEN 2
	VIBRATO $01, 2, 5
	OCTAVE 2
	NOTE C_, 8
	ATTEN 0
	ENVELOPE $1A
	VIBRATO $01, 0, 5
	NOTE C_, 0
	VOICE $06, 8, 13, 11, 4
	VIBRATO $01, 0, 5
	NOTE C_, 0
	SND_END

Snd71_Ch3:
	VOICE $06, 1, 2, 0, 0
	VIBRATO $01, 2, 6
	OCTAVE 3
	NOTE F#, 8
	NOTE D_, 8
	NOTE C_, 8
	OCTAVE 2
	NOTE G#, 8
	VIBRATO_OFF
	NOTE G#, 4
	RELEASE $0F, 5
	WAVE_X $13
	PAN_RIGHT 0
	NOTE C_HI, 4
	PAN_LEFT 0
	OCTAVE 4
	NOTE D_, 4
	NOTE G#, 4
	PAN_RIGHT 0
	NOTE D_, 4
	OCTAVE 3
	NOTE G#, 4
	PAN_BOTH 0
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 4
	WAVE_X $13
	RELEASE $0F, 5
	PAN_LEFT 0
	NOTE C_HI, 4
	OCTAVE 4
	NOTE E_, 4
	PAN_RIGHT 0
	NOTE A_, 4
	NOTE E_, 4
	PAN_BOTH 0
	RELEASE 4, 7
	WAVE 1
	OCTAVE 2
	NOTE A_, 0
	SND_END

Snd71_Drm:
	LEN_UNIT $06
	LOOP_START
	REST 0
	LOOP_END $04
	REST $0C
	DRUM_SND $12, 1
	SND_END

Snd72_Ch2:
	VOICE $06, 12, 15, 15, 1
	OCTAVE 1
	NOTE G_, 2
	LOOP2_START
	LOOP_START
	DUTY $0C
	ATTEN 0
	OCTAVE 1
	NOTE G#, 2
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 2
	DUTY $0C
	ATTEN 0
	OCTAVE 1
	NOTE G#, 2
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE D#, 2
	NOTE D#, 2
	DUTY $0C
	ATTEN 0
	OCTAVE 1
	NOTE G#, 2
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE D#, 2
	DUTY $0C
	ATTEN 0
	OCTAVE 1
	NOTE A_, 2
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	DUTY $0C
	ATTEN 0
	OCTAVE 1
	NOTE A_, 2
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	DUTY $0C
	ATTEN 0
	OCTAVE 1
	NOTE G_, 2
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE D_, 2
	DUTY $0C
	ATTEN 0
	OCTAVE 1
	NOTE G#, 2
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 2
	DUTY $0C
	ATTEN 0
	OCTAVE 1
	NOTE G#, 2
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE D#, 2
	NOTE D#, 2
	DUTY $0C
	ATTEN 0
	OCTAVE 1
	NOTE G#, 2
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE D#, 2
	DUTY $0C
	ATTEN 0
	OCTAVE 1
	NOTE A_, 2
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	DUTY $0C
	ATTEN 0
	OCTAVE 1
	NOTE A_, 2
	LOOP_BREAK $FB
	LOOP_BREAK $FC
	RELEASE 0, 0
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE E_, 1
	ATTEN 7
	NOTE E_, 1
	ATTEN 3
	NOTE E_, 1
	ATTEN 7
	NOTE E_, 1
	ATTEN 3
	NOTE F#, 1
	ATTEN 7
	NOTE F#, 1
	ATTEN 3
	NOTE G#, 1
	ATTEN 7
	NOTE G#, 1
	RELEASE $0F, 1
	LOOP_END $02
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	DUTY $0C
	ATTEN 0
	NOTE C#, 2
	DUTY 8
	ATTEN 3
	NOTE G#, 2
	LOOP2_END $02
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	DUTY $0C
	ATTEN 0
	NOTE C#, 2
	DUTY 8
	ATTEN 3
	NOTE C_HI, 2
	DUTY $0C
	ATTEN 0
	OCTAVE 1
	NOTE G#, 2
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 2
	DUTY $0C
	ATTEN 0
	OCTAVE 1
	NOTE G#, 2
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE D#, 2
	NOTE D#, 2
	DUTY $0C
	ATTEN 0
	OCTAVE 1
	NOTE G#, 2
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE D#, 2
	DUTY $0C
	ATTEN 0
	OCTAVE 1
	NOTE A_, 2
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	DUTY $0C
	ATTEN 0
	OCTAVE 1
	NOTE A_, 2
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	DUTY $0C
	ATTEN 0
	OCTAVE 1
	NOTE G_, 2
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE D_, 2
	LOOP_START
	DUTY $0C
	ATTEN 0
	OCTAVE 1
	NOTE G#, 2
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 2
	DUTY $0C
	ATTEN 0
	OCTAVE 1
	NOTE G#, 2
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE D#, 2
	NOTE D#, 2
	DUTY $0C
	ATTEN 0
	OCTAVE 1
	NOTE A_, 2
	DUTY 8
	ATTEN 3
	OCTAVE 2
	NOTE E_, 2
	DUTY $0C
	ATTEN 0
	RELEASE $0B, 3
	OCTAVE 1
	NOTE G#, 4
	SND_END

Snd72_Ch1:
	VOICE $06, 12, 11, 13, 1
	OCTAVE 2
	NOTE D_, 2
	LOOP_START
	DUTY $0C
	ATTEN 0
	NOTE D#, 2
	DUTY 8
	ATTEN 2
	RELEASE $0E, 1
	NOTE B_, 1
	NOTE B_, 1
	RELEASE $0D, 1
	NOTE B_, 2
	DUTY $0C
	ATTEN 0
	NOTE D#, 2
	DUTY 8
	ATTEN 2
	NOTE B_, 2
	NOTE B_, 2
	DUTY $0C
	ATTEN 0
	NOTE D#, 2
	DUTY 8
	ATTEN 2
	NOTE B_, 2
	DUTY $0C
	ATTEN 0
	NOTE E_, 2
	DUTY 8
	ATTEN 2
	RELEASE $0E, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE C#, 1
	RELEASE $0D, 1
	NOTE C#, 2
	DUTY $0C
	ATTEN 0
	OCTAVE 2
	NOTE E_, 2
	LOOP_BREAK $FB
	DUTY 8
	ATTEN 2
	OCTAVE 3
	NOTE C#, 2
	NOTE C#, 2
	DUTY $0C
	ATTEN 0
	OCTAVE 2
	NOTE D_, 2
	DUTY 8
	ATTEN 2
	NOTE B_, 2
	LOOP_END $02
	RELEASE 0, 0
	DUTY 8
	ATTEN 2
	OCTAVE 3
	NOTE C#, 1
	ATTEN 6
	NOTE C#, 1
	ATTEN 2
	NOTE C#, 1
	ATTEN 6
	NOTE C#, 1
	ATTEN 2
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 6
	NOTE F_, 1
	LOOP_START
	VOICE $06, 8, 15, 15, 1
	ATTEN 0
	PAN_LEFT 0
	OCTAVE 3
	NOTE G#, 2
	PAN_BOTH 0
	ATTEN 6
	RELEASE $0E, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE G#, 1
	RELEASE $0D, 1
	NOTE G#, 2
	RELEASE $0F, 1
	ATTEN 0
	PAN_LEFT 0
	NOTE C_HI, 2
	PAN_BOTH 0
	ATTEN 6
	RELEASE $0D, 1
	NOTE G#, 2
	NOTE G#, 2
	RELEASE $0F, 1
	ATTEN 0
	PAN_LEFT 0
	NOTE C_HI, 2
	PAN_BOTH 0
	ATTEN 6
	RELEASE $0D, 1
	NOTE G#, 2
	ATTEN 0
	PAN_LEFT 0
	RELEASE $0F, 1
	OCTAVE 3
	NOTE A_, 2
	PAN_BOTH 0
	ATTEN 6
	RELEASE $0E, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	RELEASE $0D, 1
	NOTE A_, 2
	RELEASE $0F, 1
	ATTEN 0
	PAN_LEFT 0
	OCTAVE 3
	LOOP_BREAK $FB
	NOTE G#, 2
	PAN_BOTH 0
	ATTEN 6
	RELEASE $0D, 1
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	RELEASE $0F, 1
	ATTEN 0
	PAN_LEFT 0
	OCTAVE 3
	NOTE F#, 2
	PAN_BOTH 0
	ATTEN 6
	RELEASE $0D, 1
	OCTAVE 2
	NOTE G_, 2
	LOOP_END $02
	NOTE B_, 2
	PAN_BOTH 0
	ATTEN 6
	RELEASE $0D, 1
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	RELEASE $0F, 1
	ATTEN 0
	PAN_LEFT 0
	OCTAVE 4
	NOTE C#, 2
	PAN_BOTH 0
	ATTEN 6
	RELEASE $0D, 1
	OCTAVE 3
	NOTE C#, 2
	VOICE $06, 0, 7, 0, 0
	VIBRATO_SEMI 1
	OCTAVE 4
	NOTE G_, 8
	VIBRATO $01, 0, 1
	NOTE G#, 8
	VIBRATO $01, 0, 2
	NOTE G#, 0
	VIBRATO $01, 0, 3
	NOTE G#, 0
	VIBRATO $01, 0, 4
	NOTE G#, 4
	VIBRATO $03, 0, 1
	RELEASE $0F, 7
	NOTE G#, 8
	RELEASE 0, 0
	VIBRATO_SEMI 4
	NOTE F#, 4
	VIBRATO_OFF
	LOOP_START
	VOICE $06, 0, 13, 15, 1
	ATTEN 0
	OCTAVE 3
	NOTE B_, 2
	ATTEN 3
	RELEASE $0E, 1
	DUTY 8
	OCTAVE 2
	NOTE G#, 1
	NOTE G#, 1
	RELEASE $0D, 1
	NOTE G#, 2
	RELEASE $0F, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE B_, 2
	ATTEN 3
	RELEASE $0D, 1
	DUTY 8
	OCTAVE 2
	NOTE G#, 2
	NOTE G#, 2
	RELEASE $0F, 1
	ATTEN 0
	DUTY 0
	LOOP_BREAK $FB
	OCTAVE 3
	NOTE B_, 2
	ATTEN 3
	RELEASE $0D, 1
	DUTY 8
	OCTAVE 2
	NOTE G#, 2
	RELEASE $0F, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE B_, 2
	ATTEN 3
	RELEASE $0E, 1
	DUTY 8
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	RELEASE $0D, 1
	NOTE A_, 2
	RELEASE $0F, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE B_, 2
	ATTEN 3
	RELEASE $0D, 1
	DUTY 8
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	RELEASE $0F, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE B_, 2
	ATTEN 3
	RELEASE $0D, 1
	DUTY 8
	OCTAVE 2
	NOTE G_, 2
	LOOP_END $02
	OCTAVE 4
	NOTE C_, 2
	ATTEN 3
	RELEASE $0D, 1
	DUTY 8
	OCTAVE 2
	NOTE A_, 2
	ATTEN 0
	DUTY 0
	RELEASE $0F, 3
	NOTE B_, 4
	SND_END

Snd72_Ch3:
	VOICE $06, 9, 2, 13, 2
	OCTAVE 3
	NOTE G_, 2
	LOOP_START
	WAVE 9
	NOTE G#, 2
	WAVE 5
	RELEASE $0F, 2
	NOTE C_HI, 1
	NOTE C_HI, 1
	RELEASE $0D, 2
	NOTE C_HI, 2
	WAVE 9
	NOTE G#, 2
	WAVE 5
	NOTE C_HI, 2
	NOTE C_HI, 2
	WAVE 9
	NOTE G#, 2
	WAVE 5
	NOTE C_HI, 2
	WAVE 9
	NOTE A_, 2
	WAVE 5
	RELEASE $0F, 2
	NOTE C_HI, 1
	NOTE C_HI, 1
	RELEASE $0D, 2
	NOTE C_HI, 2
	WAVE 9
	NOTE A_, 2
	LOOP_BREAK $FB
	WAVE 5
	NOTE C_HI, 2
	NOTE C_HI, 2
	WAVE 9
	NOTE G_, 2
	WAVE 5
	NOTE C_HI, 2
	LOOP_END $02
	WAVE 5
	RELEASE $0F, 3
	OCTAVE 4
	NOTE A_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 5
	NOTE C#, 2
	LOOP_START
	VOICE $06, 3, 2, 13, 3
	WAVE_X $12
	PAN_RIGHT 0
	OCTAVE 5
	NOTE D#, 2
	WAVE 5
	PAN_BOTH 0
	RELEASE $0F, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	RELEASE $0E, 2
	NOTE B_, 2
	RELEASE $0D, 3
	PAN_RIGHT 0
	WAVE_X $12
	OCTAVE 5
	NOTE D#, 2
	PAN_BOTH 0
	WAVE 5
	RELEASE $0E, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	RELEASE $0D, 3
	PAN_RIGHT 0
	WAVE_X $12
	OCTAVE 5
	NOTE D#, 2
	PAN_BOTH 0
	WAVE 5
	RELEASE $0E, 2
	OCTAVE 3
	NOTE B_, 2
	PAN_RIGHT 0
	RELEASE $0D, 3
	WAVE_X $12
	OCTAVE 5
	NOTE E_, 2
	WAVE 5
	PAN_BOTH 0
	RELEASE $0F, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE C#, 1
	RELEASE $0E, 2
	NOTE C#, 2
	RELEASE $0D, 3
	PAN_RIGHT 0
	WAVE_X $12
	OCTAVE 5
	LOOP_BREAK $FB
	NOTE D#, 2
	PAN_BOTH 0
	WAVE 5
	RELEASE $0E, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE C#, 2
	RELEASE $0D, 3
	PAN_RIGHT 0
	WAVE_X $12
	OCTAVE 5
	NOTE C#, 2
	PAN_BOTH 0
	WAVE 5
	RELEASE $0E, 2
	OCTAVE 4
	NOTE C#, 2
	LOOP_END $02
	NOTE F#, 2
	PAN_BOTH 0
	WAVE 5
	RELEASE $0E, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE C#, 2
	RELEASE $0D, 3
	PAN_RIGHT 0
	WAVE_X $12
	OCTAVE 5
	NOTE G#, 2
	PAN_BOTH 0
	WAVE 5
	RELEASE $0E, 2
	OCTAVE 4
	NOTE F_, 2
	VOICE $06, 9, 2, 13, 3
	OCTAVE 5
	NOTE D#, 2
	WAVE 5
	RELEASE $0F, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	RELEASE $0E, 2
	NOTE B_, 2
	RELEASE $0D, 3
	WAVE 9
	OCTAVE 5
	NOTE C#, 2
	WAVE 5
	RELEASE $0E, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	RELEASE $0D, 3
	WAVE 9
	OCTAVE 4
	NOTE B_, 2
	WAVE 5
	RELEASE $0E, 2
	OCTAVE 3
	NOTE B_, 2
	RELEASE $0D, 3
	WAVE 9
	OCTAVE 5
	NOTE C#, 2
	WAVE 5
	RELEASE $0F, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE C#, 1
	RELEASE $0E, 2
	NOTE C#, 2
	RELEASE $0D, 3
	WAVE 9
	OCTAVE 4
	NOTE B_, 2
	WAVE 5
	RELEASE $0E, 2
	NOTE C#, 2
	NOTE C#, 2
	RELEASE $0D, 3
	WAVE 9
	NOTE A_, 2
	WAVE 5
	RELEASE $0E, 2
	NOTE C#, 2
	RELEASE $0D, 3
	WAVE 9
	OCTAVE 4
	NOTE B_, 2
	WAVE 5
	RELEASE $0F, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	RELEASE $0E, 2
	NOTE B_, 2
	RELEASE $0D, 3
	WAVE 9
	OCTAVE 4
	NOTE A_, 2
	WAVE 5
	RELEASE $0E, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	RELEASE $0D, 3
	WAVE 9
	OCTAVE 4
	NOTE G#, 2
	WAVE 5
	RELEASE $0E, 2
	OCTAVE 3
	NOTE B_, 2
	RELEASE $0D, 3
	WAVE 9
	OCTAVE 4
	NOTE A_, 2
	WAVE 5
	RELEASE $0F, 1
	NOTE C#, 1
	NOTE C#, 1
	RELEASE $0E, 2
	NOTE C#, 2
	RELEASE $0D, 3
	WAVE 9
	NOTE G#, 2
	WAVE 5
	RELEASE $0E, 2
	NOTE C#, 2
	NOTE C#, 2
	RELEASE $0D, 3
	WAVE 9
	NOTE A_, 2
	WAVE 5
	RELEASE $0E, 2
	NOTE F_, 2
	LOOP_START
	VOICE $06, 7, 2, 13, 3
	OCTAVE 5
	ATTEN 1
	NOTE G#, 2
	WAVE 5
	RELEASE $0F, 1
	OCTAVE 3
	ATTEN 0
	NOTE B_, 1
	NOTE B_, 1
	RELEASE $0E, 2
	NOTE B_, 2
	RELEASE $0D, 3
	WAVE 7
	OCTAVE 5
	ATTEN 1
	NOTE G#, 2
	WAVE 5
	RELEASE $0E, 2
	OCTAVE 3
	ATTEN 0
	NOTE B_, 2
	NOTE B_, 2
	RELEASE $0D, 3
	WAVE 7
	OCTAVE 5
	ATTEN 1
	LOOP_BREAK $FB
	NOTE G#, 2
	WAVE 5
	RELEASE $0E, 2
	OCTAVE 3
	ATTEN 0
	NOTE B_, 2
	RELEASE $0D, 3
	WAVE 7
	OCTAVE 5
	ATTEN 1
	NOTE G#, 2
	WAVE 5
	RELEASE $0F, 1
	OCTAVE 4
	ATTEN 0
	NOTE C#, 1
	NOTE C#, 1
	RELEASE $0E, 2
	NOTE C#, 2
	RELEASE $0D, 3
	WAVE 7
	OCTAVE 5
	ATTEN 1
	NOTE G#, 2
	WAVE 5
	RELEASE $0E, 2
	OCTAVE 4
	ATTEN 0
	NOTE C#, 2
	NOTE C#, 2
	RELEASE $0D, 3
	WAVE 7
	OCTAVE 5
	ATTEN 1
	NOTE G_, 2
	WAVE 5
	RELEASE $0E, 2
	OCTAVE 4
	ATTEN 0
	NOTE C#, 2
	LOOP_END $02
	NOTE A_, 2
	WAVE 5
	RELEASE $0E, 2
	OCTAVE 4
	ATTEN 0
	NOTE C_, 2
	RELEASE $0E, 3
	WAVE 7
	NOTE D#, 4
	SND_END

Snd72_Drm:
	LEN_UNIT $06
	DRUM 9, 2
	LOOP_START
	DRUM $0C, 4
	DRUM 3, 2
	DRUM 9, 4
	DRUM 3, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 3, 1
	DRUM 5, 3
	DRUM 9, 2
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 2
	DRUM 9, 2
	LOOP_BREAK $FB
	DRUM 9, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 3, 2
	DRUM 3, 1
	DRUM 5, 1
	LOOP_END $04
	DRUM 9, 2
	DRUM 3, 1
	DRUM 5, 3
	DRUM 9, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 1
	DRUM 5, 1
	DRUM $0C, 1
	SND_END

Snd73_Ch2:
	SND_SEGNO
	VOICE $07, 4, 11, 0, 0
	VIBRATO_SEMI 1
	OCTAVE 3
	NOTE F#, 10
	VIBRATO $01, 0, 3
	NOTE G_, 10
	VIBRATO $01, 0, 4
	NOTE G_, 10
	VIBRATO $01, 0, 5
	NOTE G_, 10
	VIBRATO $01, 0, 6
	NOTE G_, 4
	RELEASE 7, 6
	VIBRATO $0C, 0, 1
	NOTE G_, 0
	VIBRATO $04, 0, 2
	RELEASE 0, 0
	DUTY 8
	ATTEN 4
	OCTAVE 4
	NOTE F#, 4
	VIBRATO $01, 2, 3
	NOTE F#, 6
	NOTE D_, 8
	VIBRATO $03, 0, 2
	RELEASE $0E, 5
	NOTE D_, 2
	ATTEN 0
	SND_CALL Snd73_Ch2_53A7
	NOTE C#, 2
	NOTE D_, 8
	VIBRATO $04, 0, 2
	ATTEN 2
	NOTE B_, 2
	ATTEN 1
	OCTAVE 5
	NOTE C_, 10
	VIBRATO $01, 0, 1
	NOTE C_, 10
	VIBRATO $01, 0, 2
	NOTE C_, 10
	VIBRATO $01, 0, 3
	NOTE C_, 7
	RELEASE $0F, 5
	VIBRATO $03, 0, 1
	NOTE C_, 3
	ATTEN 0
	DUTY 0
	RELEASE 0, 0
	OCTAVE 4
	VIBRATO $01, 2, 4
	ENVELOPE $0A
	NOTE C_, 3
	NOTE D_, 3
	VIBRATO_OFF
	NOTE D#, 2
	DUTY 8
	OCTAVE 3
	NOTE C_, 2
	DUTY 0
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE G#, 4
	VIBRATO $01, 2, 2
	NOTE G_, 4
	VIBRATO_OFF
	NOTE F#, 2
	VIBRATO $01, 3, 3
	NOTE G_, 8
	DUTY 8
	OCTAVE 3
	VIBRATO_OFF
	NOTE C_, 2
	ENVELOPE $00
	VOICE $07, 8, 9, 0, 0
	OCTAVE 2
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE G_, 1
	VOICE $07, 8, 11, 0, 0
	LOOP2_START
	LOOP_START
	OCTAVE 3
	NOTE C_, 2
	ATTEN 1
	VIBRATO $04, 0, 3
	NOTE G_, 1
	VIBRATO $01, 1, 3
	NOTE G_, 2
	NOTE F#, 3
	VIBRATO_OFF
	NOTE D#, 2
	ATTEN 0
	LOOP_END $02
	TRANSPOSE_UP 1
	LOOP2_END $02
	SND_CALL Snd73_Ch2_53A7
	TRANSPOSE_UP 0
	ATTEN 2
	OCTAVE 5
	NOTE C#, 2
	NOTE C_, 8
	VIBRATO $04, 0, 2
	NOTE E_, 2
	VOICE $07, 0, 9, 0, 0
	ATTEN 1
	VIBRATO $01, 3, 2
	OCTAVE 5
	ENVELOPE $06
	NOTE C#, 10
	NOTE C_, 10
	VIBRATO $01, 2, 2
	ENVELOPE $00
	ATTEN 1
	NOTE C#, 4
	ATTEN 2
	NOTE C_, 4
	OCTAVE 4
	VIBRATO_OFF
	NOTE A_, 2
	VIBRATO $01, 3, 2
	ATTEN 2
	ENVELOPE $06
	NOTE G#, 10
	ENVELOPE $00
	ATTEN 1
	VIBRATO_OFF
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D#, 1
	VIBRATO $01, 3, 3
	NOTE E_, 6
	VIBRATO $01, 2, 2
	ATTEN 2
	NOTE G_, 4
	ATTEN 1
	NOTE G#, 4
	ENVELOPE $00
	VIBRATO_OFF
	ATTEN 0
	NOTE A_, 2
	ATTEN 1
	VIBRATO $01, 3, 3
	NOTE G#, 7
	RELEASE $0F, 5
	VIBRATO_OFF
	NOTE G#, 3
	ATTEN 0
	RELEASE 0, 0
	DUTY 8
	OCTAVE 2
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE B_, 1
	ATTEN 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	ATTEN 2
	NOTE G#, 1
	NOTE B_, 1
	DUTY 0
	VIBRATO $01, 3, 2
	ATTEN 1
	OCTAVE 5
	ENVELOPE $06
	NOTE C#, 10
	NOTE C_, 8
	ENVELOPE $00
	VIBRATO_OFF
	ATTEN 2
	OCTAVE 4
	NOTE A_, 2
	ATTEN 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE G_, 1
	ENVELOPE $06
	ATTEN 0
	VIBRATO $01, 3, 3
	NOTE G#, 6
	VIBRATO $01, 2, 2
	ATTEN 0
	NOTE A_, 4
	ATTEN 2
	NOTE E_, 4
	ENVELOPE $00
	VIBRATO_OFF
	ATTEN 1
	NOTE C_, 2
	VIBRATO $01, 3, 3
	ATTEN 0
	NOTE C#, 7
	VIBRATO_OFF
	VIBRATO $01, 0, 3
	RELEASE $0F, 5
	NOTE C#, 3
	RELEASE 0, 0
	VIBRATO $01, 3, 3
	ENVELOPE $06
	NOTE C_, 8
	ENVELOPE $00
	VIBRATO_OFF
	ATTEN 2
	NOTE D#, 2
	VIBRATO $01, 3, 3
	NOTE C#, 10
	VIBRATO $01, 0, 4
	NOTE C#, 10
	RELEASE $0F, 7
	NOTE C#, 10
	VIBRATO_OFF
	REST $0A
	SND_LOOP

Snd73_Ch1:
	SND_SEGNO
	VOICE $07, 8, 15, 10, 2
	LOOP_START
	REST $0A
	LOOP_END $04
	SND_CALL Snd73_Ch1_5312
	SND_CALL Snd73_Ch1_5312
	SND_CALL Snd73_Ch1_53E9
	VOICE $07, 0, 8, 0, 0
	OCTAVE 4
	VIBRATO $04, 0, 3
	NOTE G_, 3
	VIBRATO $01, 2, 4
	NOTE F#, 3
	VIBRATO_OFF
	NOTE D#, 2
	DUTY 8
	ENVELOPE $0C
	OCTAVE 2
	NOTE G_, 2
	ENVELOPE $00
	OCTAVE 4
	DUTY 0
	VIBRATO $01, 2, 4
	NOTE D#, 4
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 2
	ENVELOPE $0A
	OCTAVE 3
	VIBRATO $04, 0, 3
	NOTE G_, 3
	VIBRATO $01, 2, 4
	NOTE F#, 3
	VIBRATO_OFF
	NOTE D#, 2
	DUTY 8
	ENVELOPE $0C
	OCTAVE 2
	NOTE G_, 2
	ENVELOPE $0A
	OCTAVE 3
	DUTY 0
	VIBRATO $01, 2, 4
	NOTE D#, 4
	NOTE D_, 4
	OCTAVE 2
	NOTE B_, 2
	ENVELOPE $00
	OCTAVE 3
	VIBRATO $04, 0, 3
	NOTE D#, 3
	VIBRATO $01, 2, 4
	NOTE F#, 3
	VIBRATO_OFF
	NOTE G_, 2
	DUTY 8
	OCTAVE 2
	NOTE G_, 2
	DUTY 0
	OCTAVE 3
	NOTE F#, 2
	NOTE D_, 2
	NOTE D#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 2
	VIBRATO $01, 2, 3
	NOTE D#, 8
	VIBRATO_OFF
	RELEASE $0F, 1
	DUTY 8
	OCTAVE 2
	NOTE G_, 2
	RELEASE 0, 0
	NOTE D#, 1
	NOTE F#, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	NOTE D#, 1
	DETUNE $FE
	LOOP2_START
	LOOP_START
	OCTAVE 2
	NOTE G_, 2
	REST 1
	ATTEN 5
	VIBRATO $04, 0, 3
	OCTAVE 3
	NOTE G_, 1
	VIBRATO $01, 1, 3
	NOTE G_, 2
	NOTE F#, 3
	VIBRATO_OFF
	NOTE D#, 1
	ATTEN 0
	LOOP_END $02
	TRANSPOSE_UP 1
	LOOP2_END $02
	DETUNE $00
	SND_CALL Snd73_Ch1_53E9
	TRANSPOSE_UP 0
	VOICE $07, 8, 10, 13, 1
	LOOP2_START
	RELEASE $0D, 1
	OCTAVE 2
	NOTE C#, 1
	DUTY $0C
	OCTAVE 3
	NOTE E_, 1
	DUTY 8
	OCTAVE 2
	NOTE E_, 1
	DUTY $0C
	NOTE C_HI, 1
	DUTY 8
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 1
	DUTY 0
	NOTE E_, 1
	DUTY 8
	OCTAVE 4
	NOTE C#, 1
	RELEASE 0, 0
	NOTE E_, 2
	RELEASE $0D, 1
	OCTAVE 2
	NOTE D#, 1
	DUTY $0C
	OCTAVE 3
	NOTE G_, 1
	DUTY 8
	OCTAVE 2
	NOTE G#, 1
	DUTY $0C
	OCTAVE 3
	NOTE G_, 1
	DUTY 8
	NOTE C_, 1
	NOTE D#, 1
	DUTY 0
	NOTE G_, 1
	DUTY 8
	OCTAVE 4
	NOTE C_, 1
	RELEASE 0, 0
	NOTE D#, 2
	RELEASE $0D, 1
	OCTAVE 2
	NOTE E_, 1
	DUTY $0C
	NOTE C_HI, 1
	DUTY 8
	NOTE G#, 1
	DUTY $0C
	OCTAVE 3
	NOTE E_, 1
	DUTY 8
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	DUTY 0
	NOTE E_, 1
	DUTY 8
	NOTE G#, 1
	RELEASE 0, 0
	OCTAVE 4
	NOTE C#, 2
	LOOP_BREAK $FC
	RELEASE $0D, 1
	OCTAVE 2
	NOTE G_, 1
	DUTY $0C
	OCTAVE 3
	NOTE D_, 1
	DUTY 8
	OCTAVE 2
	NOTE A_, 1
	DUTY $0C
	OCTAVE 3
	NOTE D_, 1
	DUTY 8
	NOTE G_, 1
	NOTE A_, 1
	DUTY 0
	NOTE D_, 1
	DUTY 8
	NOTE C_HI, 1
	RELEASE 0, 0
	NOTE A_, 2
	RELEASE $0D, 1
	OCTAVE 2
	NOTE E_, 1
	DUTY $0C
	NOTE C_HI, 1
	DUTY 8
	NOTE A_, 1
	DUTY $0C
	OCTAVE 3
	NOTE E_, 1
	DUTY 8
	NOTE C#, 1
	NOTE G#, 1
	DUTY 0
	NOTE E_, 1
	DUTY 8
	OCTAVE 4
	NOTE C#, 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE A_, 2
	RELEASE $0D, 1
	OCTAVE 2
	NOTE G#, 1
	DUTY $0C
	OCTAVE 3
	NOTE E_, 1
	DUTY 8
	NOTE D#, 1
	DUTY $0C
	OCTAVE 3
	NOTE E_, 1
	DUTY 8
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	DUTY 0
	OCTAVE 3
	NOTE E_, 1
	DUTY 8
	OCTAVE 4
	NOTE C_, 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE G#, 2
	RELEASE $0D, 1
	OCTAVE 2
	NOTE G#, 1
	DUTY $0C
	OCTAVE 3
	NOTE E_, 1
	DUTY 8
	NOTE C#, 1
	DUTY $0C
	OCTAVE 3
	NOTE E_, 1
	DUTY 8
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	DUTY 0
	OCTAVE 3
	NOTE E_, 1
	DUTY 8
	NOTE C_HI, 1
	RELEASE 0, 0
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 2
	NOTE F_, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	NOTE G#, 1
	LOOP2_END $02
	RELEASE $0D, 1
	ATTEN 2
	OCTAVE 4
	NOTE D_, 1
	DUTY $0C
	ATTEN 0
	OCTAVE 3
	NOTE G_, 1
	DUTY 8
	ATTEN 1
	NOTE A_, 1
	DUTY $0C
	ATTEN 0
	NOTE G_, 1
	DUTY 8
	NOTE G_, 1
	NOTE D_, 1
	DUTY 0
	NOTE G_, 1
	DUTY 8
	OCTAVE 2
	NOTE A_, 1
	RELEASE 0, 0
	NOTE G_, 2
	RELEASE $0D, 1
	OCTAVE 2
	NOTE C#, 1
	DUTY $0C
	OCTAVE 3
	NOTE E_, 1
	DUTY 8
	OCTAVE 2
	NOTE E_, 1
	DUTY $0C
	NOTE C_HI, 1
	DUTY 8
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 1
	DUTY 0
	NOTE E_, 1
	DUTY 8
	ATTEN 2
	OCTAVE 4
	NOTE E_, 1
	ATTEN 3
	RELEASE 0, 0
	NOTE G#, 1
	OCTAVE 5
	NOTE C#, 1
	RELEASE $0D, 1
	NOTE C_, 1
	DUTY $0C
	ATTEN 0
	OCTAVE 3
	NOTE G_, 1
	DUTY 8
	ATTEN 3
	OCTAVE 4
	NOTE G#, 1
	DUTY $0C
	ATTEN 0
	OCTAVE 3
	NOTE G_, 1
	DUTY 8
	ATTEN 2
	OCTAVE 4
	NOTE F#, 1
	NOTE E_, 1
	ATTEN 0
	DUTY 0
	OCTAVE 3
	NOTE G_, 1
	DUTY 8
	NOTE G#, 1
	RELEASE 0, 0
	NOTE A_, 2
	VIBRATO $01, 3, 3
	NOTE G#, 10
	VIBRATO $01, 0, 4
	NOTE G#, 10
	RELEASE $0F, 7
	NOTE G#, 10
	VIBRATO_OFF
	REST $0A
	SND_LOOP

Snd73_Ch3:
	SND_SEGNO
	VOICE $07, 1, 2, 10, 2
	SND_CALL Snd73_Ch3_52EB
	SND_CALL Snd73_Ch3_52EB
	RELEASE $0F, 2
	WAVE_X $10
	OCTAVE 4
	NOTE G_, 1
	WAVE_X $11
	OCTAVE 4
	NOTE G_, 1
	WAVE_X $12
	NOTE G_, 1
	WAVE_X $13
	NOTE G_, 1
	WAVE_X $14
	NOTE G_, 1
	WAVE_X $15
	NOTE G_, 1
	WAVE_X $16
	NOTE G_, 1
	WAVE_X $17
	NOTE G_, 1
	WAVE_X $18
	NOTE G_, 1
	WAVE_X $19
	NOTE G_, 1
	WAVE_X $1A
	NOTE G_, 1
	WAVE_X $1B
	NOTE G_, 1
	WAVE_X $1C
	NOTE G_, 1
	WAVE_X $1B
	NOTE G_, 1
	WAVE_X $1A
	NOTE G_, 1
	WAVE_X $19
	NOTE G_, 1
	WAVE_X $18
	NOTE G_, 1
	WAVE_X $17
	NOTE G_, 1
	WAVE_X $16
	NOTE G_, 1
	WAVE_X $15
	NOTE G_, 1
	WAVE_X $14
	NOTE G_, 1
	WAVE_X $13
	NOTE G_, 1
	WAVE_X $12
	NOTE G_, 1
	WAVE_X $11
	NOTE G_, 1
	WAVE_X $10
	NOTE G_, 1
	WAVE_X $11
	NOTE G_, 1
	WAVE_X $12
	NOTE G_, 1
	WAVE_X $13
	NOTE G_, 1
	WAVE_X $14
	NOTE G_, 1
	WAVE_X $15
	NOTE G_, 1
	WAVE_X $16
	NOTE F#, 1
	WAVE_X $17
	NOTE F#, 1
	WAVE_X $18
	NOTE F#, 1
	WAVE_X $19
	NOTE F#, 1
	WAVE_X $1A
	NOTE F#, 1
	WAVE_X $1B
	NOTE F#, 1
	WAVE_X $1C
	NOTE F#, 1
	WAVE_X $1B
	NOTE F#, 1
	WAVE_X $1A
	NOTE F#, 1
	WAVE_X $19
	NOTE F#, 1
	VOICE $07, 1, 2, 10, 2
	SND_CALL Snd73_Ch3_5339
	SND_CALL Snd73_Ch3_5360
	RELEASE $0A, 2
	LOOP_START
	OCTAVE 3
	NOTE F_, 1
	ATTEN 1
	WAVE 9
	NOTE C_HI, 1
	ATTEN 0
	WAVE 1
	LOOP_END $02
	NOTE F_, 1
	NOTE F_, 1
	ATTEN 1
	WAVE 9
	NOTE C_HI, 1
	ATTEN 0
	WAVE 1
	NOTE F_, 1
	RELEASE 0, 0
	NOTE G#, 2
	RELEASE $0A, 2
	LOOP_START
	OCTAVE 3
	NOTE D#, 1
	ATTEN 1
	WAVE 9
	NOTE C_HI, 1
	ATTEN 0
	WAVE 1
	LOOP_END $02
	NOTE D#, 1
	NOTE D#, 1
	ATTEN 1
	WAVE 9
	NOTE C_HI, 1
	ATTEN 0
	WAVE 1
	NOTE D#, 1
	RELEASE 0, 0
	NOTE G#, 2
	RELEASE $0A, 2
	LOOP_START
	OCTAVE 3
	NOTE D_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE D_, 1
	ATTEN 0
	WAVE 1
	LOOP_END $02
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE D_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 1
	RELEASE 0, 0
	NOTE F#, 2
	RELEASE $0A, 2
	OCTAVE 3
	NOTE B_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE D_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE G#, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE D_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE G_, 1
	NOTE F#, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE D_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE D#, 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 2
	SND_CALL Snd73_Ch3_5339
	SND_CALL Snd73_Ch3_5360
	SND_CALL Snd73_Ch3_54B4
	RELEASE $0A, 2
	LOOP_START
	OCTAVE 2
	NOTE G_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 3
	NOTE B_, 1
	ATTEN 0
	WAVE 1
	LOOP_END $02
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	ATTEN 1
	WAVE 9
	NOTE B_, 1
	ATTEN 0
	WAVE 1
	NOTE G_, 1
	RELEASE 0, 0
	NOTE G#, 2
	SND_CALL Snd73_Ch3_5339
	SND_CALL Snd73_Ch3_5339
	RELEASE $0A, 2
	OCTAVE 2
	NOTE G#, 1
	ATTEN 1
	WAVE 9
	NOTE C_HI, 1
	ATTEN 0
	WAVE 1
	NOTE G#, 1
	ATTEN 1
	WAVE 9
	OCTAVE 3
	NOTE B_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE G#, 1
	NOTE G#, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE C_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE G#, 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE C_, 2
	RELEASE $0A, 2
	OCTAVE 2
	NOTE A#, 1
	ATTEN 1
	WAVE 9
	NOTE C_HI, 1
	ATTEN 0
	WAVE 1
	NOTE A#, 1
	ATTEN 1
	WAVE 9
	OCTAVE 3
	NOTE G#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE A#, 1
	NOTE A#, 1
	ATTEN 1
	WAVE 9
	OCTAVE 3
	NOTE A#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE A#, 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE D_, 2
	RELEASE $0A, 2
	LOOP_START
	OCTAVE 3
	NOTE C_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE C_, 1
	ATTEN 0
	WAVE 1
	LOOP_END $02
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE C_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 2
	RELEASE $0A, 2
	OCTAVE 3
	NOTE C_, 1
	ATTEN 1
	WAVE 9
	NOTE D#, 1
	ATTEN 0
	WAVE 1
	NOTE C_, 1
	ATTEN 1
	WAVE 9
	NOTE G_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE D#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	RELEASE 0, 0
	NOTE D_, 2
	LOOP2_START
	SND_CALL Snd73_Ch3_5386
	LOOP2_END $02
	TRANSPOSE_UP 1
	LOOP2_START
	SND_CALL Snd73_Ch3_5386
	LOOP2_END $02
	TRANSPOSE_UP 0
	VIBRATO $01, 3, 5
	OCTAVE 3
	NOTE C#, 8
	RELEASE $0E, 4
	NOTE C#, 2
	RELEASE 0, 0
	VIBRATO $01, 2, 5
	NOTE C#, 4
	VIBRATO $04, 0, 4
	RELEASE 9, 5
	NOTE G#, 4
	VIBRATO_OFF
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 2
	VIBRATO $01, 3, 5
	NOTE A_, 0
	NOTE G#, 4
	DETUNE $FF
	VIBRATO $04, 0, 3
	OCTAVE 3
	NOTE F#, 2
	VIBRATO $01, 2, 4
	NOTE F#, 8
	NOTE E_, 10
	NOTE D#, 10
	DETUNE $00
	VIBRATO $04, 0, 3
	NOTE G#, 1
	VIBRATO $01, 0, 3
	RELEASE 9, 5
	NOTE G#, 3
	RELEASE 0, 0
	VIBRATO_OFF
	NOTE F#, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE B_, 2
	TRANSPOSE_UP 1
	SND_CALL Snd73_Ch3_5339
	SND_CALL Snd73_Ch3_5360
	SND_CALL Snd73_Ch3_54B4
	RELEASE $0A, 2
	LOOP_START
	OCTAVE 2
	NOTE G_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE D_, 1
	ATTEN 0
	WAVE 1
	LOOP_END $02
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE D_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE G_, 1
	RELEASE 0, 0
	NOTE G#, 2
	TRANSPOSE_UP 0
	VOICE $07, 1, 2, 10, 2
	LOOP2_START
	RELEASE $0A, 2
	LOOP_START
	OCTAVE 2
	NOTE A_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE G#, 1
	ATTEN 0
	WAVE 1
	LOOP_END $02
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE G#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE C#, 2
	RELEASE $0A, 2
	LOOP_START
	OCTAVE 2
	NOTE G#, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE A_, 1
	ATTEN 0
	WAVE 1
	LOOP_END $02
	OCTAVE 2
	NOTE G#, 1
	NOTE G#, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE A_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE G#, 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE C_, 2
	RELEASE $0A, 2
	LOOP_START
	OCTAVE 3
	NOTE C#, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE G#, 1
	ATTEN 0
	WAVE 1
	LOOP_END $02
	OCTAVE 3
	NOTE C#, 1
	NOTE C#, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE G#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE C#, 1
	RELEASE 0, 0
	NOTE E_, 2
	RELEASE $0A, 2
	LOOP_START
	OCTAVE 3
	NOTE D_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE A_, 1
	ATTEN 0
	WAVE 1
	LOOP_END $02
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE A_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 1
	RELEASE 0, 0
	NOTE C_, 2
	LOOP_BREAK $FC
	RELEASE $0A, 2
	LOOP_START
	OCTAVE 2
	NOTE A_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE A_, 1
	ATTEN 0
	WAVE 1
	LOOP_END $02
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE A_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE C#, 2
	RELEASE $0A, 2
	LOOP_START
	OCTAVE 3
	NOTE C_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE G#, 1
	ATTEN 0
	WAVE 1
	LOOP_END $02
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE G#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	RELEASE 0, 0
	NOTE D#, 2
	RELEASE $0A, 2
	LOOP_START
	OCTAVE 3
	NOTE C#, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE G#, 1
	ATTEN 0
	WAVE 1
	LOOP_END $02
	OCTAVE 3
	NOTE C#, 1
	NOTE C#, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE G#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE C#, 1
	RELEASE 0, 0
	NOTE E_, 2
	RELEASE $0A, 2
	OCTAVE 3
	NOTE D_, 1
	ATTEN 1
	WAVE 9
	NOTE F_, 1
	ATTEN 0
	WAVE 1
	NOTE D_, 1
	ATTEN 1
	WAVE 9
	NOTE B_, 1
	ATTEN 0
	WAVE 1
	NOTE D_, 1
	NOTE D_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE G#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 1
	RELEASE 0, 0
	NOTE C_, 2
	LOOP2_END $02
	RELEASE $0A, 2
	LOOP_START
	OCTAVE 2
	NOTE A_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE G#, 1
	ATTEN 0
	WAVE 1
	LOOP_END $02
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE G#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 0, 0
	OCTAVE 3
	NOTE C#, 2
	RELEASE $0A, 2
	LOOP_START
	OCTAVE 3
	NOTE C_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE A_, 1
	ATTEN 0
	WAVE 1
	LOOP_END $02
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE A_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	RELEASE 0, 0
	NOTE D#, 2
	TRANSPOSE_UP 1
	SND_CALL Snd73_Ch3_52EB
	SND_CALL Snd73_Ch3_52EB
	TRANSPOSE_UP 0
	SND_LOOP

Snd73_Drm:
	LEN_UNIT $07
	SND_SEGNO
	LOOP2_START
	DRUM $0C, 2
	LOOP_START
	DRUM 7, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM 3, 2
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 2
	LOOP_END $06
	DRUM 9, 1
	DRUM 8, 1
	LOOP_BREAK $FC
	LOOP_START
	DRUM $0B, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM 3, 1
	DRUM 8, 1
	LOOP2_END $02
	LOOP_START
	DRUM 7, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM 3, 1
	DRUM 3, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	LOOP_BREAK $FB
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 2
	LOOP_END $08
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0C, 2
	LOOP_START
	DRUM 7, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM 3, 2
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 2
	LOOP_END $06
	DRUM 9, 1
	LOOP_START
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 8, 1
	LOOP_END $02
	DRUM $0B, 1
	DRUM 3, 2
	DRUM $0C, 2
	LOOP_START
	DRUM 7, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM 3, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM $0C, 2
	LOOP_START
	DRUM 7, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM 3, 2
	DRUM 9, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM $0C, 2
	LOOP_START
	DRUM 7, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM 3, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 2
	LOOP2_START
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 7, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM 3, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 2
	LOOP2_END $03
	DRUM $0C, 2
	LOOP_START
	DRUM 7, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM 3, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 2
	LOOP2_START
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 7, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM 3, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 2
	LOOP2_END $02
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 2
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 2
	DRUM $0C, 2
	LOOP_START
	DRUM 7, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM 3, 2
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 2
	LOOP_END $07
	DRUM $0C, 2
	LOOP_START
	DRUM 7, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM 3, 2
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 2
	LOOP_END $05
	DRUM $0C, 2
	LOOP_START
	DRUM 7, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM 3, 2
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 2
	LOOP_END $02
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	LOOP_START
	DRUM 3, 1
	LOOP_END $06
	SND_LOOP
Snd73_Ch3_52EB:
	LOOP2_START
	RELEASE $0A, 2
	LOOP_START
	OCTAVE 3
	NOTE C_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE D#, 1
	ATTEN 0
	WAVE 1
	LOOP_END $02
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE D#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	RELEASE 0, 0
	LOOP_BREAK $FC
	OCTAVE 2
	NOTE B_, 2
	LOOP2_END $02
	NOTE C#, 2
	SND_RET
Snd73_Ch1_5312:
	LOOP2_START
	RELEASE $0A, 2
	LOOP_START
	OCTAVE 2
	NOTE C_, 1
	ATTEN 5
	DUTY $0C
	OCTAVE 3
	NOTE D#, 1
	ATTEN 0
	DUTY 8
	LOOP_END $02
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	ATTEN 5
	DUTY $0C
	OCTAVE 3
	NOTE D#, 1
	ATTEN 0
	DUTY 8
	OCTAVE 2
	NOTE C_, 1
	RELEASE 0, 0
	LOOP_BREAK $FC
	OCTAVE 1
	NOTE B_, 2
	LOOP2_END $02
	NOTE C#, 2
	SND_RET
Snd73_Ch3_5339:
	LOOP2_START
	RELEASE $0A, 2
	LOOP_START
	OCTAVE 3
	NOTE C_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE C_, 1
	ATTEN 0
	WAVE 1
	LOOP_END $02
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE C_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	RELEASE 0, 0
	LOOP_BREAK $FC
	OCTAVE 2
	NOTE B_, 2
	LOOP2_END $02
	NOTE D_, 2
	SND_RET
Snd73_Ch3_5360:
	LOOP2_START
	RELEASE $0A, 2
	LOOP_START
	OCTAVE 2
	NOTE G#, 1
	ATTEN 1
	WAVE 9
	OCTAVE 3
	NOTE G#, 1
	ATTEN 0
	WAVE 1
	LOOP_END $02
	OCTAVE 2
	NOTE G#, 1
	NOTE G#, 1
	ATTEN 1
	WAVE 9
	OCTAVE 3
	NOTE G#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 2
	NOTE G#, 1
	RELEASE 0, 0
	LOOP_BREAK $FC
	NOTE G_, 2
	LOOP2_END $02
	NOTE B_, 2
	SND_RET
Snd73_Ch3_5386:
	RELEASE $0A, 2
	LOOP_START
	OCTAVE 3
	NOTE C_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE D#, 1
	ATTEN 0
	WAVE 1
	LOOP_END $02
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE D#, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE C_, 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 2
	SND_RET
Snd73_Ch2_53A7:
	LOOP_START
	VOICE $07, 8, 7, 0, 0
	VIBRATO $01, 4, 3
	OCTAVE 4
	NOTE D#, 10
	NOTE D_, 8
	VIBRATO_OFF
	OCTAVE 3
	NOTE B_, 2
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE C_, 3
	VIBRATO $01, 4, 4
	RELEASE 7, 5
	OCTAVE 3
	NOTE G_, 7
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE F#, 2
	VIBRATO $01, 0, 2
	NOTE F#, 4
	VIBRATO_OFF
	NOTE G_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE D_, 1
	VIBRATO $01, 4, 3
	NOTE C_, 10
	VIBRATO_SEMI 6
	NOTE F#, 4
	VIBRATO $01, 0, 3
	NOTE F#, 6
	VIBRATO $01, 3, 3
	LOOP_BREAK $FB
	NOTE D#, 10
	NOTE D_, 10
	LOOP_END $02
	NOTE D#, 8
	SND_RET
Snd73_Ch1_53E9:
	VOICE $07, 8, 12, 0, 0
	VIBRATO $01, 3, 4
	OCTAVE 3
	NOTE G_, 8
	RELEASE $0E, 3
	NOTE G_, 2
	RELEASE 0, 0
	NOTE G_, 8
	NOTE F#, 2
	VIBRATO $01, 3, 4
	NOTE D#, 8
	RELEASE $0E, 3
	NOTE D#, 2
	RELEASE 0, 0
	NOTE D#, 8
	NOTE G_, 2
	VIBRATO $04, 0, 2
	NOTE G#, 2
	VIBRATO $01, 2, 3
	NOTE G#, 6
	VIBRATO_OFF
	NOTE G_, 2
	VIBRATO $01, 3, 4
	NOTE C_, 6
	RELEASE $0E, 2
	NOTE C_, 2
	RELEASE 0, 0
	NOTE D_, 2
	NOTE F#, 8
	VIBRATO $04, 0, 3
	NOTE G#, 2
	VIBRATO $01, 3, 4
	NOTE G_, 8
	NOTE G#, 2
	VOICE $07, 8, 12, 0, 0
	RELEASE $0D, 2
	PAN_LEFT 0
	OCTAVE 3
	NOTE G_, 2
	PAN_BOTH 0
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 2
	PAN_RIGHT 0
	NOTE C_HI, 2
	PAN_BOTH 0
	NOTE C_, 2
	PAN_LEFT 0
	NOTE G_, 2
	RELEASE 0, 0
	PAN_BOTH 0
	NOTE D#, 1
	NOTE F#, 1
	RELEASE $0D, 2
	NOTE G_, 2
	PAN_RIGHT 0
	NOTE C_HI, 2
	PAN_BOTH 0
	NOTE F#, 2
	PAN_LEFT 0
	NOTE D#, 2
	PAN_BOTH 0
	OCTAVE 2
	NOTE D#, 2
	NOTE C_HI, 2
	PAN_RIGHT 0
	OCTAVE 4
	NOTE D#, 2
	PAN_LEFT 0
	NOTE D_, 2
	PAN_RIGHT 0
	OCTAVE 3
	NOTE D#, 2
	PAN_BOTH 0
	OCTAVE 2
	NOTE D#, 2
	PAN_LEFT 0
	NOTE C_HI, 1
	PAN_BOTH 0
	ATTEN 3
	RELEASE 0, 0
	OCTAVE 4
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	ATTEN 0
	RELEASE $0D, 2
	OCTAVE 3
	NOTE G_, 2
	PAN_LEFT 0
	NOTE G#, 2
	PAN_BOTH 0
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE G#, 2
	PAN_RIGHT 0
	NOTE C_HI, 2
	PAN_BOTH 0
	NOTE F#, 2
	ATTEN 3
	RELEASE 0, 0
	VIBRATO_SEMI 7
	NOTE B_, 4
	VIBRATO_OFF
	RELEASE $0D, 2
	OCTAVE 4
	NOTE C_, 2
	ATTEN 0
	PAN_RIGHT 0
	NOTE C_HI, 2
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 2
	PAN_LEFT 0
	NOTE F#, 2
	PAN_BOTH 0
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 3
	NOTE F#, 2
	PAN_RIGHT 0
	NOTE C_HI, 2
	PAN_BOTH 0
	NOTE F#, 2
	RELEASE 0, 0
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F#, 1
	VIBRATO $01, 0, 3
	NOTE G_, 2
	NOTE G#, 2
	NOTE F#, 2
	VIBRATO_OFF
	SND_RET
Snd73_Ch3_54B4:
	RELEASE $0A, 2
	LOOP_START
	OCTAVE 3
	NOTE F_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE C_, 1
	ATTEN 0
	WAVE 1
	LOOP_END $02
	OCTAVE 3
	NOTE F_, 1
	NOTE F_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE C_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE F_, 1
	RELEASE 0, 0
	NOTE G#, 2
	RELEASE $0A, 2
	LOOP_START
	OCTAVE 3
	NOTE D#, 1
	ATTEN 1
	WAVE 9
	NOTE B_, 1
	ATTEN 0
	WAVE 1
	LOOP_END $02
	NOTE D#, 1
	NOTE D#, 1
	ATTEN 1
	WAVE 9
	NOTE B_, 1
	ATTEN 0
	WAVE 1
	NOTE D#, 1
	RELEASE 0, 0
	NOTE G#, 2
	RELEASE $0A, 2
	LOOP_START
	OCTAVE 3
	NOTE D_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE C_, 1
	ATTEN 0
	WAVE 1
	LOOP_END $02
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 1
	ATTEN 1
	WAVE 9
	OCTAVE 4
	NOTE C_, 1
	ATTEN 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE G#, 2
	SND_RET

Snd74_Ch2:
	VOICE $06, 8, 15, 0, 0
	REST 4
	OCTAVE 1
	NOTE G#, 1
	ATTEN 3
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 4
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	ATTEN 2
	NOTE G#, 1
	ATTEN 5
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	RELEASE $0E, 3
	NOTE G#, 2
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	NOTE F#, 2
	VIBRATO_OFF
	VIBRATO $01, 4, 3
	NOTE F#, 0
	SND_SEGNO
	LOOP_START
	PAN_LEFT 0
	DUTY 8
	VIBRATO $01, 2, 2
	ATTEN 2
	NOTE G#, 8
	RELEASE $0A, 7
	VIBRATO $03, 3, 3
	NOTE G#, 8
	VIBRATO_OFF
	PAN_BOTH 0
	OCTAVE 4
	ATTEN 7
	RELEASE $0F, 1
	NOTE D#, 1
	NOTE D#, 3
	NOTE C#, 2
	NOTE D#, 1
	NOTE C#, 3
	NOTE C_, 2
	NOTE C#, 2
	NOTE C_, 2
	VIBRATO $01, 2, 2
	PAN_RIGHT 0
	RELEASE 0, 0
	ATTEN 3
	NOTE G#, 8
	RELEASE $0A, 7
	VIBRATO $03, 3, 3
	NOTE G#, 8
	VIBRATO_OFF
	PAN_BOTH 0
	OCTAVE 4
	ATTEN 7
	RELEASE $0F, 1
	NOTE E_, 1
	NOTE E_, 3
	NOTE D#, 2
	NOTE E_, 1
	NOTE D#, 3
	NOTE C#, 2
	NOTE D#, 2
	NOTE E_, 2
	RELEASE 0, 0
	LOOP_END $02
	ATTEN 3
	VIBRATO $01, 4, 2
	OCTAVE 3
	ENVELOPE $08
	NOTE G#, 0
	VIBRATO $01, 0, 3
	ENVELOPE $00
	RELEASE 7, 7
	NOTE G#, 0
	RELEASE 0, 0
	VIBRATO $01, 4, 2
	ENVELOPE $08
	NOTE A_, 0
	VIBRATO $01, 0, 3
	ENVELOPE $00
	RELEASE 7, 7
	NOTE A_, 0
	RELEASE 0, 0
	ENVELOPE $08
	VIBRATO $01, 4, 2
	OCTAVE 3
	ATTEN 5
	NOTE B_, 0
	OCTAVE 4
	NOTE D#, 0
	NOTE C#, 0
	NOTE F#, 0
	ENVELOPE $00
	RELEASE $0F, 7
	ATTEN 4
	VIBRATO $01, 0, 2
	NOTE F#, 0
	VIBRATO_OFF
	RELEASE 0, 0
	REST 0
	SND_LOOP

Snd74_Ch1:
	VOICE $06, 8, 12, 0, 0
	DETUNE $FE
	REST 4
	REST 2
	OCTAVE 1
	NOTE G#, 1
	ATTEN 3
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 4
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	ATTEN 2
	NOTE G#, 1
	ATTEN 5
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	ATTEN 0
	VIBRATO $04, 0, 2
	OCTAVE 3
	NOTE A#, 2
	VIBRATO $01, 4, 3
	NOTE A#, 12
	VIBRATO_OFF
	VOICE $03, 0, 10, 0, 0
	DETUNE $00
	OCTAVE 3
	NOTE A#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE C#, 1
	SND_SEGNO
	LOOP2_START
	VOICE $06, 8, 12, 15, 1
	OCTAVE 2
	NOTE D#, 1
	RELEASE 0, 0
	NOTE D#, 1
	RELEASE $0F, 1
	DUTY $0C
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	DUTY 8
	RELEASE 0, 0
	OCTAVE 2
	NOTE D#, 1
	RELEASE $0F, 1
	DUTY $0C
	OCTAVE 3
	NOTE C_, 1
	DUTY 8
	OCTAVE 2
	NOTE D#, 1
	RELEASE 0, 0
	NOTE D#, 1
	RELEASE $0F, 1
	DUTY $0C
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	LOOP_START
	DUTY 8
	RELEASE 0, 0
	OCTAVE 2
	NOTE D#, 1
	RELEASE $0F, 1
	DUTY $0C
	OCTAVE 3
	NOTE C_, 1
	LOOP_END $03
	OCTAVE 4
	DUTY 0
	NOTE C_, 1
	NOTE C_, 1
	DUTY $0C
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	DUTY 0
	LOOP_BREAK $FC
	NOTE A#, 1
	DUTY $0C
	NOTE C_, 1
	DUTY 0
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	DUTY $0C
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	DUTY 0
	NOTE G#, 1
	DUTY $0C
	NOTE C_, 1
	DUTY 0
	NOTE A#, 1
	DUTY $0C
	NOTE C_, 1
	DUTY 0
	NOTE G#, 1
	DUTY $0C
	NOTE C_, 1
	TRANSPOSE_UP 1
	LOOP2_END $02
	TRANSPOSE_UP 0
	OCTAVE 4
	NOTE C_, 1
	DUTY $0C
	OCTAVE 3
	NOTE C#, 1
	DUTY 0
	OCTAVE 4
	NOTE C#, 1
	NOTE C_, 1
	DUTY $0C
	OCTAVE 3
	NOTE C#, 1
	NOTE C#, 1
	DUTY 0
	NOTE A_, 1
	DUTY $0C
	NOTE C#, 1
	DUTY 0
	NOTE B_, 1
	DUTY $0C
	NOTE C#, 1
	DUTY 0
	OCTAVE 4
	NOTE C#, 1
	DUTY $0C
	OCTAVE 3
	NOTE C#, 1
	DUTY 8
	RELEASE 0, 0
	OCTAVE 2
	NOTE D#, 2
	RELEASE $0F, 1
	DUTY $0C
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	DUTY 8
	OCTAVE 2
	NOTE G#, 1
	DUTY $0C
	OCTAVE 3
	NOTE C_, 1
	DUTY 8
	RELEASE 0, 0
	VIBRATO $05, 0, 2
	OCTAVE 3
	NOTE G#, 2
	VIBRATO_OFF
	RELEASE $0F, 1
	DUTY $0C
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	DUTY 8
	NOTE F#, 1
	DUTY $0C
	NOTE C_, 1
	DUTY 8
	NOTE G#, 1
	DUTY $0C
	NOTE C_, 1
	DUTY 8
	NOTE A#, 1
	DUTY $0C
	NOTE C_, 1
	OCTAVE 4
	DUTY 0
	NOTE C_, 1
	NOTE C_, 1
	DUTY $0C
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	DUTY 0
	LOOP_BREAK $FC
	NOTE A#, 1
	DUTY $0C
	NOTE C_, 1
	DUTY 0
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	DUTY $0C
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	DUTY 0
	NOTE G#, 1
	DUTY $0C
	NOTE C_, 1
	DUTY 0
	NOTE A#, 1
	DUTY $0C
	NOTE C_, 1
	DUTY 0
	NOTE G#, 1
	DUTY $0C
	NOTE C_, 1
	DUTY 8
	RELEASE 0, 0
	OCTAVE 2
	NOTE E_, 2
	RELEASE $0F, 1
	DUTY $0C
	OCTAVE 3
	NOTE C#, 1
	NOTE C#, 1
	DUTY 8
	OCTAVE 2
	NOTE E_, 1
	DUTY $0C
	OCTAVE 3
	NOTE C#, 1
	DUTY 8
	RELEASE 0, 0
	VIBRATO $05, 0, 2
	OCTAVE 4
	NOTE E_, 2
	VIBRATO_OFF
	RELEASE $0F, 1
	DUTY $0C
	OCTAVE 3
	NOTE C#, 1
	NOTE C#, 1
	DUTY 8
	OCTAVE 4
	NOTE D#, 1
	DUTY $0C
	OCTAVE 3
	NOTE C#, 1
	DUTY 8
	OCTAVE 4
	NOTE C#, 1
	DUTY $0C
	OCTAVE 3
	NOTE C#, 1
	DUTY 8
	NOTE A_, 1
	DUTY $0C
	NOTE C#, 1
	OCTAVE 4
	DUTY 0
	NOTE C#, 1
	NOTE C#, 1
	DUTY $0C
	OCTAVE 3
	NOTE C#, 1
	NOTE C#, 1
	DUTY 0
	OCTAVE 4
	NOTE C_, 1
	DUTY $0C
	NOTE C#, 1
	DUTY 0
	OCTAVE 4
	NOTE C#, 1
	NOTE C_, 1
	DUTY $0C
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	DUTY 0
	NOTE A_, 1
	DUTY $0C
	NOTE E_, 1
	DUTY 0
	NOTE B_, 1
	DUTY $0C
	NOTE E_, 1
	DUTY 0
	OCTAVE 4
	NOTE C#, 1
	DUTY $0C
	OCTAVE 3
	NOTE E_, 1
	VOICE $06, 8, 12, 15, 7
	AUTOPAN 0
	DETUNE $FE
	DUTY_STEP 4, 1
	OCTAVE 3
	NOTE G#, 8
	DETUNE $FF
	OCTAVE 4
	NOTE G#, 8
	NOTE C_HI, 8
	NOTE G#, 8
	DETUNE $FE
	OCTAVE 3
	NOTE A_, 8
	DETUNE $FF
	OCTAVE 4
	NOTE A_, 8
	NOTE C_HI, 8
	NOTE A_, 8
	DUTY_STEP 0, 0
	PAN_BOTH 0
	DETUNE $FE
	RELEASE 0, 0
	ATTEN 3
	VIBRATO $01, 4, 2
	OCTAVE 3
	ENVELOPE $08
	NOTE B_, 0
	VIBRATO $01, 0, 3
	ATTEN 0
	ENVELOPE $00
	RELEASE 7, 7
	NOTE B_, 0
	DETUNE $00
	ATTEN 3
	RELEASE 0, 0
	VIBRATO $01, 4, 2
	ENVELOPE $08
	NOTE A_, 0
	VIBRATO $01, 0, 3
	ATTEN 0
	ENVELOPE $00
	NOTE A_, 0
	RELEASE 9, 7
	NOTE A_, 0
	VIBRATO_OFF
	REST 0
	SND_LOOP

Snd74_Ch3:
	VOICE $06, 1, 2, 0, 0
	DETUNE $FF
	REST 4
	OCTAVE 2
	NOTE D#, 1
	WAVE_X $2D
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	WAVE_X $2F
	NOTE D#, 1
	WAVE_X $1F
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	WAVE_X $2E
	NOTE D#, 1
	WAVE_X $1E
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE C_, 1
	WAVE_X $2D
	RELEASE $0E, 3
	NOTE D#, 2
	RELEASE 0, 0
	DETUNE $00
	ATTEN 0
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE C#, 2
	VIBRATO $01, 4, 3
	NOTE C#, 12
	VIBRATO_OFF
	VOICE $03, 4, 2, 0, 0
	DETUNE $00
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G#, 1
	NOTE F#, 1
	SND_SEGNO
	LOOP2_START
	LOOP_START
	VOICE $06, 1, 2, 13, 1
	OCTAVE 2
	NOTE G#, 1
	RELEASE 0, 0
	NOTE G#, 1
	RELEASE $0D, 1
	WAVE 7
	OCTAVE 4
	NOTE D#, 1
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE G#, 1
	RELEASE $0D, 1
	WAVE 7
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	OCTAVE 2
	NOTE G#, 1
	RELEASE 0, 0
	NOTE G#, 1
	RELEASE $0D, 1
	WAVE 7
	OCTAVE 4
	NOTE D#, 1
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE G#, 1
	RELEASE $0D, 1
	WAVE 7
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE G#, 1
	RELEASE $0D, 1
	WAVE 7
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE G#, 1
	RELEASE $0D, 1
	WAVE 7
	OCTAVE 4
	NOTE D#, 1
	LOOP_END $02
	LOOP_START
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 0, 0
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE 7
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE 7
	OCTAVE 4
	NOTE E_, 1
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 0, 0
	NOTE A_, 1
	LOOP_BREAK $FB
	RELEASE $0D, 1
	WAVE 7
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE 7
	OCTAVE 4
	NOTE E_, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE 7
	OCTAVE 4
	NOTE E_, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE 7
	OCTAVE 4
	NOTE E_, 1
	LOOP_END $02
	LOOP_BREAK $FC
	RELEASE $0D, 1
	WAVE 7
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE 7
	OCTAVE 4
	NOTE E_, 1
	LOOP_START
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE F#, 1
	RELEASE $0D, 1
	WAVE 7
	OCTAVE 4
	NOTE E_, 1
	LOOP_END $02
	LOOP2_END $02
	RELEASE 0, 0
	OCTAVE 3
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	RELEASE $0D, 1
	OCTAVE 2
	NOTE G#, 1
	RELEASE 0, 0
	NOTE G#, 1
	RELEASE $0D, 1
	WAVE_X $10
	OCTAVE 4
	NOTE D#, 1
	WAVE_X $10
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE G#, 1
	RELEASE $0D, 1
	WAVE_X $11
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	OCTAVE 2
	NOTE G#, 1
	RELEASE 0, 0
	NOTE G#, 1
	RELEASE $0D, 1
	WAVE_X $12
	OCTAVE 4
	NOTE D#, 1
	WAVE_X $13
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE G#, 1
	RELEASE $0D, 1
	WAVE_X $14
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE G#, 1
	RELEASE $0D, 1
	WAVE_X $15
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE G#, 1
	RELEASE $0D, 1
	WAVE_X $16
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	OCTAVE 2
	NOTE G#, 1
	RELEASE 0, 0
	NOTE G#, 1
	RELEASE $0D, 1
	WAVE_X $17
	OCTAVE 4
	NOTE D#, 1
	WAVE_X $18
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE G#, 1
	RELEASE $0D, 1
	WAVE_X $19
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	OCTAVE 2
	NOTE G#, 1
	RELEASE 0, 0
	NOTE G#, 1
	RELEASE $0D, 1
	WAVE_X $1A
	OCTAVE 4
	NOTE D#, 1
	WAVE_X $1B
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE G#, 1
	RELEASE $0D, 1
	WAVE_X $1C
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE G#, 1
	RELEASE $0D, 1
	WAVE_X $1C
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE G#, 1
	RELEASE $0D, 1
	WAVE_X $1B
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 0, 0
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE_X $1A
	OCTAVE 4
	NOTE D#, 1
	WAVE_X $19
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE_X $18
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 0, 0
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE_X $17
	OCTAVE 4
	NOTE D#, 1
	WAVE_X $16
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE_X $15
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE_X $14
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE_X $13
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 0, 0
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE_X $12
	OCTAVE 4
	NOTE D#, 1
	WAVE_X $11
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE_X $10
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 0, 0
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE_X $10
	OCTAVE 4
	NOTE D#, 1
	WAVE_X $11
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE_X $12
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE_X $13
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE_X $14
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	OCTAVE 2
	NOTE B_, 1
	RELEASE 0, 0
	NOTE B_, 1
	RELEASE $0D, 1
	WAVE_X $15
	OCTAVE 4
	NOTE D#, 1
	WAVE_X $16
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 1
	RELEASE $0D, 1
	WAVE_X $17
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	OCTAVE 2
	NOTE B_, 1
	RELEASE 0, 0
	NOTE B_, 1
	RELEASE $0D, 1
	WAVE_X $18
	OCTAVE 4
	NOTE D#, 1
	WAVE_X $19
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 1
	RELEASE $0D, 1
	WAVE_X $1A
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 1
	RELEASE $0D, 1
	WAVE_X $1B
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 1
	RELEASE $0D, 1
	WAVE_X $1C
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	OCTAVE 2
	NOTE B_, 1
	RELEASE 0, 0
	NOTE B_, 1
	RELEASE $0D, 1
	WAVE_X $1C
	OCTAVE 4
	NOTE D#, 1
	WAVE_X $1B
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 1
	RELEASE $0D, 1
	WAVE_X $1A
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	OCTAVE 2
	NOTE B_, 1
	RELEASE 0, 0
	NOTE B_, 1
	RELEASE $0D, 1
	WAVE_X $19
	OCTAVE 4
	NOTE D#, 1
	WAVE_X $17
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 1
	RELEASE $0D, 1
	WAVE_X $18
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 1
	RELEASE $0D, 1
	WAVE_X $17
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 1
	RELEASE $0D, 1
	WAVE_X $16
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 0, 0
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE_X $15
	OCTAVE 4
	NOTE D#, 1
	WAVE_X $14
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE_X $13
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 0, 0
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE_X $12
	OCTAVE 4
	NOTE D#, 1
	WAVE_X $11
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE_X $10
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE_X $10
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE_X $11
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 0, 0
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE_X $12
	OCTAVE 4
	NOTE D#, 1
	WAVE_X $13
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE_X $14
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	OCTAVE 2
	NOTE A_, 1
	RELEASE 0, 0
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE_X $15
	OCTAVE 4
	NOTE D#, 1
	WAVE_X $16
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE_X $17
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE_X $18
	OCTAVE 4
	NOTE D#, 1
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0D, 1
	WAVE_X $19
	OCTAVE 4
	NOTE D#, 1
	WAVE_X $1A
	NOTE D#, 1
	WAVE_X $1B
	NOTE D#, 2
	WAVE_X $1C
	NOTE D#, 1
	WAVE_X $1C
	NOTE D#, 2
	WAVE_X $1B
	NOTE D#, 1
	WAVE_X $1A
	NOTE D#, 2
	WAVE_X $19
	NOTE D#, 1
	WAVE_X $18
	NOTE D#, 2
	WAVE_X $17
	NOTE D#, 1
	WAVE_X $16
	NOTE D#, 2
	WAVE_X $15
	NOTE D#, 1
	WAVE_X $14
	NOTE D#, 1
	WAVE_X $13
	NOTE D#, 2
	WAVE_X $12
	NOTE D#, 1
	WAVE_X $11
	NOTE D#, 2
	WAVE_X $10
	NOTE D#, 1
	WAVE_X $10
	NOTE D#, 2
	WAVE_X $11
	NOTE D#, 1
	WAVE_X $12
	NOTE D#, 2
	WAVE_X $13
	NOTE D#, 1
	WAVE_X $14
	NOTE D#, 2
	WAVE_X $15
	NOTE D#, 1
	SND_LOOP

Snd74_Drm:
	LEN_UNIT $03
	REST 8
	REST 0
	REST 0
	REST 4
	DRUM $0A, 4
	DRUM $0A, 4
	DRUM $0A, 4
	LOOP_START
	DRUM $0B, 2
	LOOP_END $08
	SND_SEGNO
	LOOP2_START
	DRUM $0C, 4
	DRUM 7, 2
	DRUM $0B, 2
	DRUM 3, 2
	DRUM 7, 2
	DRUM 9, 4
	DRUM 7, 2
	DRUM $0B, 2
	DRUM 3, 4
	DRUM 7, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 7, 2
	LOOP_START
	DRUM 9, 4
	DRUM 7, 2
	DRUM $0B, 2
	DRUM 3, 2
	DRUM 7, 2
	DRUM 9, 4
	LOOP_BREAK $FB
	DRUM 7, 2
	DRUM $0B, 2
	DRUM 3, 4
	DRUM 7, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 7, 2
	LOOP_END $03
	DRUM 3, 2
	DRUM $0B, 2
	DRUM 7, 4
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 2
	DRUM $0B, 2
	DRUM 7, 2
	LOOP_START
	DRUM 9, 4
	DRUM 7, 2
	DRUM 3, 2
	DRUM $0B, 2
	DRUM 7, 2
	DRUM 9, 4
	DRUM 7, 2
	DRUM 3, 2
	DRUM $0B, 4
	DRUM 7, 2
	DRUM 8, 2
	DRUM 9, 2
	DRUM 7, 2
	DRUM 9, 4
	DRUM 7, 2
	DRUM 3, 2
	DRUM $0B, 2
	DRUM 7, 2
	DRUM 9, 4
	LOOP_BREAK $FB
	DRUM 7, 2
	DRUM 3, 2
	DRUM $0B, 4
	DRUM 7, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 7, 2
	LOOP_END $02
	DRUM $0B, 2
	DRUM 3, 2
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM 7, 2
	DRUM $0B, 2
	DRUM 7, 2
	LOOP2_END $02
	DRUM $0A, 4
	DRUM 7, 2
	DRUM 3, 2
	DRUM $0B, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 9, 4
	DRUM 7, 2
	DRUM 3, 2
	DRUM $0B, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	LOOP_START
	DRUM 3, 1
	LOOP_END $08
	SND_LOOP

Snd75_Ch2:
	VOICE $0B, 0, 8, 0, 0
	ATTEN 4
	VIBRATO $01, 5, 2
	OCTAVE 2
	ENVELOPE $0B
	NOTE B_, 12
	ATTEN 0
	VOICE $0B, 8, 6, 0, 0
	VIBRATO $01, 3, 1
	OCTAVE 5
	ENVELOPE $0B
	NOTE E_, 8
	ENVELOPE $00
	VIBRATO_OFF
	NOTE D_, 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE D_, 2
	ENVELOPE $0B
	VIBRATO $01, 2, 1
	NOTE C_, 8
	ENVELOPE $00
	OCTAVE 4
	NOTE B_, 2
	VIBRATO_OFF
	ENVELOPE $14
	NOTE B_, 6
	ENVELOPE $00
	VOICE $0B, 8, 15, 0, 0
	ENVELOPE $03
	VIBRATO $01, 3, 5
	OCTAVE 1
	NOTE E_, 0
	VIBRATO $01, 0, 5
	NOTE F_, 0
	VIBRATO_OFF
	VOICE $0B, 8, 8, 0, 0
	REST 4
	OCTAVE 4
	VIBRATO $01, 3, 1
	ATTEN 2
	ENVELOPE $04
	NOTE E_, 0
	VIBRATO $01, 0, 1
	ENVELOPE $00
	NOTE E_, 12
	ENVELOPE $0B
	ATTEN 2
	VIBRATO $01, 3, 1
	NOTE G_, 8
	ATTEN 1
	NOTE A#, 8
	ENVELOPE $00
	VIBRATO $01, 3, 1
	ATTEN 0
	ENVELOPE $04
	NOTE F_, 0
	VIBRATO $01, 0, 1
	ENVELOPE $00
	ATTEN 0
	NOTE F_, 4
	VIBRATO $01, 1, 2
	ATTEN 0
	NOTE G_, 4
	ATTEN 1
	NOTE G#, 4
	ATTEN 0
	OCTAVE 5
	NOTE C_, 4
	ATTEN 1
	NOTE C#, 10
	RELEASE $0F, 5
	NOTE C#, 4
	VOICE $0B, 8, 4, 0, 0
	DETUNE $FF
	ATTEN 0
	LOOP_START
	VIBRATO $01, 2, 2
	RELEASE 0, 0
	OCTAVE 4
	NOTE C#, 8
	VIBRATO_OFF
	RELEASE $0E, 4
	NOTE C_, 6
	LOOP_END $02
	LOOP_START
	VIBRATO $01, 2, 2
	RELEASE 0, 0
	OCTAVE 3
	NOTE A#, 8
	VIBRATO_OFF
	RELEASE $0E, 4
	NOTE B_, 6
	LOOP_END $02
	LOOP_START
	VIBRATO $01, 2, 2
	RELEASE 0, 0
	OCTAVE 4
	NOTE C#, 8
	VIBRATO_OFF
	RELEASE $0E, 4
	NOTE C_, 6
	LOOP_END $02
	VIBRATO $01, 2, 2
	RELEASE 0, 0
	OCTAVE 4
	NOTE C#, 8
	VIBRATO_OFF
	RELEASE $0E, 4
	NOTE C#, 2
	RELEASE 0, 0
	NOTE C_, 2
	NOTE C#, 2
	VIBRATO $01, 2, 2
	RELEASE 0, 0
	ATTEN 2
	ENVELOPE $0E
	NOTE D#, 9
	ENVELOPE $00
	VIBRATO_OFF
	ATTEN 0
	RELEASE $0E, 1
	NOTE D#, 1
	RELEASE 0, 0
	ATTEN 1
	NOTE C#, 2
	ATTEN 0
	NOTE D#, 2
	VOICE $0B, 8, 6, 0, 0
	VIBRATO $01, 1, 2
	OCTAVE 4
	NOTE E_, 4
	RELEASE 5, 5
	NOTE D#, 4
	ATTEN 1
	RELEASE 0, 0
	NOTE D#, 4
	OCTAVE 3
	NOTE B_, 2
	ATTEN 2
	OCTAVE 4
	NOTE C_, 10
	RELEASE $0E, 4
	NOTE C_, 4
	VIBRATO_OFF
	DETUNE $00
	ATTEN 0
	SND_END

Snd75_Ch1:
	VOICE $0B, 0, 4, 10, 7
	DETUNE $FE
	PAN_LEFT 0
	REST 1
	OCTAVE 3
	NOTE E_, 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 1
	PAN_BOTH 0
	VOICE $0B, 0, 4, 0, 0
	VIBRATO $01, 0, 2
	OCTAVE 2
	NOTE B_, 12
	VIBRATO_OFF
	VOICE $0B, 0, 4, 0, 0
	VIBRATO $01, 0, 2
	ATTEN 1
	OCTAVE 2
	NOTE B_, 8
	RELEASE 6, 7
	NOTE B_, 0
	RELEASE 0, 0
	VIBRATO_OFF
	REST $0C
	REST 0
	VOICE $0B, 8, 15, 0, 0
	VIBRATO $01, 0, 5
	OCTAVE 1
	NOTE F_, 0
	VIBRATO $01, 3, 4
	ATTEN 2
	ENVELOPE $03
	NOTE G_, 0
	VIBRATO $01, 0, 5
	ENVELOPE $00
	NOTE G_, 0
	VIBRATO $01, 3, 4
	ENVELOPE $03
	NOTE G#, 0
	VIBRATO $01, 0, 5
	ENVELOPE $00
	NOTE G#, 0
	ENVELOPE $00
	VOICE $0B, 8, 10, 0, 0
	DETUNE $01
	LOOP_START
	VIBRATO $01, 2, 3
	RELEASE 0, 0
	OCTAVE 2
	NOTE G#, 8
	VIBRATO_OFF
	RELEASE $0E, 4
	NOTE A_, 6
	LOOP_END $03
	LOOP_START
	VIBRATO $01, 2, 3
	RELEASE 0, 0
	NOTE D#, 8
	VIBRATO_OFF
	RELEASE $0E, 4
	NOTE E_, 6
	LOOP_END $02
	LOOP_START
	VIBRATO $01, 2, 3
	RELEASE 0, 0
	OCTAVE 2
	NOTE G#, 8
	VIBRATO_OFF
	RELEASE $0E, 4
	NOTE A_, 6
	LOOP_END $03
	VIBRATO $01, 2, 3
	RELEASE 0, 0
	ENVELOPE $05
	NOTE A#, 9
	VIBRATO_OFF
	RELEASE $0E, 4
	ENVELOPE $00
	NOTE A#, 1
	RELEASE 0, 0
	ATTEN 1
	NOTE A_, 2
	ATTEN 0
	NOTE A#, 2
	VOICE $0B, 8, 12, 0, 0
	VIBRATO $01, 1, 3
	OCTAVE 3
	NOTE C#, 4
	RELEASE 5, 5
	OCTAVE 2
	NOTE A#, 4
	RELEASE 0, 0
	ATTEN 1
	NOTE G#, 4
	NOTE G_, 2
	ATTEN 3
	NOTE G#, 10
	RELEASE $0E, 4
	NOTE G#, 4
	VIBRATO_OFF
	DETUNE $00
	ATTEN 0
	SND_END

Snd75_Ch3:
	VOICE $0B, 9, 2, 13, 7
	PAN_LEFT 0
	OCTAVE 4
	NOTE E_, 4
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	RELEASE $0F, 6
	OCTAVE 3
	NOTE B_, 0
	PAN_BOTH 0
	VOICE $0B, 1, 4, 0, 0
	VIBRATO $01, 1, 1
	OCTAVE 3
	WAVE_X $1D
	NOTE G#, 4
	WAVE_X $1E
	NOTE G_, 4
	WAVE_X $2D
	NOTE G#, 4
	WAVE_X $2E
	NOTE G_, 4
	WAVE 1
	NOTE G#, 4
	WAVE_X $2F
	NOTE G_, 4
	WAVE_X $2E
	NOTE G#, 4
	WAVE_X $2D
	NOTE G_, 4
	WAVE_X $1E
	NOTE G#, 4
	WAVE_X $1D
	NOTE G_, 4
	WAVE_X $1E
	NOTE G#, 4
	WAVE_X $1F
	NOTE G_, 4
	WAVE_X $2D
	NOTE G#, 4
	WAVE_X $2E
	NOTE G_, 4
	WAVE 1
	NOTE G#, 4
	WAVE_X $2F
	NOTE G_, 4
	WAVE_X $2E
	NOTE A#, 4
	WAVE_X $2D
	NOTE A_, 4
	WAVE_X $1F
	NOTE A#, 4
	WAVE_X $1E
	NOTE A_, 4
	WAVE_X $1D
	NOTE A#, 4
	WAVE_X $1E
	NOTE A_, 4
	WAVE_X $2D
	VIBRATO $01, 2, 2
	RELEASE 5, 4
	NOTE A#, 12
	VIBRATO $01, 1, 1
	RELEASE 0, 0
	WAVE_X $1D
	NOTE G_, 4
	WAVE_X $1E
	NOTE G#, 4
	WAVE_X $2D
	NOTE G_, 4
	WAVE_X $2E
	NOTE G#, 4
	WAVE_X $2F
	NOTE G_, 4
	RELEASE 5, 4
	VIBRATO $03, 5, 1
	WAVE 1
	NOTE F_, 8
	VIBRATO_OFF
	VOICE $0B, 4, 2, 3, 6
	TRANSPOSE_UP $0C
	VIBRATO $01, 3, 5
	OCTAVE 3
	NOTE C#, 10
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE G#, 10
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE C#, 10
	OCTAVE 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE G_, 10
	NOTE E_, 2
	NOTE D#, 2
	VOICE $0B, 1, 4, 0, 0
	PAN_RIGHT 0
	VIBRATO_OFF
	OCTAVE 5
	REST 6
	NOTE G_, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	VOICE $0B, 4, 2, 3, 6
	PAN_BOTH 0
	VIBRATO $01, 3, 5
	OCTAVE 3
	NOTE C#, 10
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE G#, 10
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE C#, 10
	NOTE D#, 2
	NOTE E_, 2
	NOTE G_, 10
	NOTE E_, 2
	NOTE G_, 2
	NOTE G#, 4
	NOTE G_, 4
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	RELEASE 0, 0
	NOTE D#, 10
	RELEASE $0E, 4
	NOTE D#, 4
	VIBRATO_OFF
	TRANSPOSE_UP 0
	SND_END

Snd75_Drm:
	LEN_UNIT $0B
	LOOP_START
	REST $0C
	LOOP_END $0D
	DRUM_SND $0D, 3
	DRUM 5, 1
	DRUM 5, 4
	DRUM_SND $0D, 3
	DRUM 5, 1
	DRUM_SND $0D, 2
	DRUM_SND $0D, 3
	DRUM 5, 1
	DRUM 5, 4
	DRUM_SND $0D, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM_SND $0D, 1
	DRUM 5, 1
	DRUM_SND $0D, 3
	DRUM 5, 1
	DRUM 5, 4
	DRUM_SND $0D, 3
	DRUM 5, 1
	DRUM_SND $0D, 2
	DRUM_SND $0D, 3
	DRUM 5, 1
	DRUM 5, 3
	DRUM 5, 1
	DRUM_SND $0D, 3
	DRUM 5, 1
	DRUM_SND $0D, 1
	DRUM 5, 1
	DRUM_SND $0D, 3
	DRUM 5, 1
	DRUM 5, 4
	DRUM_SND $0D, 4
	DRUM_SND $0D, 1
	DRUM 5, 1
	LOOP_START
	DRUM_SND $0D, 3
	DRUM 5, 1
	DRUM 5, 4
	DRUM_SND $0D, 3
	DRUM 5, 1
	DRUM_SND $0D, 1
	DRUM 5, 1
	LOOP_END $02
	DRUM_SND $0D, 3
	DRUM 5, 1
	DRUM 5, 3
	DRUM 5, 1
	DRUM_SND $0D, 3
	DRUM 5, 1
	DRUM_SND $0D, 1
	DRUM 5, 1
	DRUM_SND $0D, 3
	DRUM 5, 1
	DRUM 5, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM_SND $0D, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM_SND $0D, 2
	DRUM_SND $0D, 3
	DRUM 5, 1
	DRUM 5, 4
	DRUM_SND $0D, 2
	DRUM 5, 1
	DRUM 5, 1
	DRUM_SND $0D, 1
	DRUM 5, 1
	DRUM_SND $0D, 3
	DRUM 5, 1
	DRUM 5, 3
	DRUM 5, 1
	DRUM_SND $0D, 3
	DRUM 5, 1
	DRUM_SND $0D, 2
	SND_END

Snd76_Ch2:
	VOICE $07, 12, 5, 0, 0
	DETUNE $FF
	OCTAVE 2
	VIBRATO $01, 4, 3
	ATTEN 4
	NOTE G#, 8
	VIBRATO $01, 0, 3
	ATTEN 3
	NOTE G#, 0
	ATTEN 2
	NOTE G#, 0
	ATTEN 1
	NOTE G#, 0
	ATTEN 0
	NOTE G#, 0
	RELEASE 4, 7
	NOTE G#, 0
	RELEASE 0, 0
	VIBRATO $01, 4, 3
	ENVELOPE $02
	NOTE D#, 0
	ENVELOPE $00
	VIBRATO $01, 0, 3
	LOOP_START
	NOTE D#, 0
	LOOP_END $03
	NOTE D#, 12
	NOTE D#, 12
	VIBRATO $01, 4, 3
	NOTE E_, 0
	VOICE $07, 12, 10, 0, 0
	DETUNE $FF
	VIBRATO $01, 4, 3
	ATTEN 5
	OCTAVE 2
	NOTE D#, 0
	VIBRATO $01, 0, 3
	NOTE D#, 0
	VIBRATO $01, 0, 4
	NOTE D#, 0
	NOTE D#, 0
	VIBRATO $01, 0, 3
	NOTE D#, 0
	RELEASE 1, 7
	NOTE D#, 0
	RELEASE 0, 0
	VIBRATO $01, 4, 3
	NOTE C#, 0
	VIBRATO $01, 0, 4
	ATTEN 4
	NOTE C#, 0
	ATTEN 3
	NOTE C#, 0
	VIBRATO $01, 0, 3
	ATTEN 2
	NOTE C#, 0
	ATTEN 0
	VOICE $07, 8, 4, 0, 0
	OCTAVE 4
	VIBRATO $01, 3, 1
	NOTE D#, 8
	VIBRATO_OFF
	NOTE G_, 4
	NOTE G#, 4
	VIBRATO $01, 4, 1
	NOTE A#, 0
	RELEASE 7, 7
	NOTE A#, 8
	VOICE $07, 12, 10, 0, 0
	VIBRATO $01, 0, 2
	ATTEN 2
	OCTAVE 2
	NOTE D#, 0
	VIBRATO $01, 0, 3
	NOTE D#, 0
	VOICE $07, 8, 4, 0, 0
	OCTAVE 4
	VIBRATO_OFF
	NOTE G_, 4
	NOTE G#, 4
	VIBRATO $01, 2, 1
	NOTE A#, 8
	NOTE G_, 8
	VIBRATO_OFF
	ENVELOPE $0D
	ATTEN 5
	NOTE G#, 0
	VIBRATO $01, 0, 2
	ENVELOPE $17
	ATTEN 5
	NOTE G#, 0
	VIBRATO $01, 0, 2
	ATTEN 4
	ENVELOPE $0C
	NOTE G#, 8
	ENVELOPE $00
	VOICE $07, 8, 11, 0, 0
	VIBRATO_OFF
	OCTAVE 5
	ATTEN 3
	NOTE C_, 4
	ATTEN 2
	NOTE C#, 4
	ATTEN 0
	VOICE $07, 8, 8, 0, 0
	VIBRATO $0F, 4, 2
	NOTE D#, 0
	VIBRATO $01, 0, 2
	RELEASE 5, 5
	NOTE D#, 0
	SND_END

Snd76_Ch1:
	VOICE $07, 12, 5, 0, 0
	DETUNE $02
	OCTAVE 3
	VIBRATO $01, 4, 3
	ATTEN 4
	NOTE D#, 0
	VIBRATO $01, 0, 3
	ATTEN 3
	NOTE D#, 0
	ATTEN 2
	NOTE D#, 0
	ATTEN 1
	NOTE D#, 0
	ATTEN 0
	NOTE D#, 12
	RELEASE 4, 7
	NOTE D#, 12
	RELEASE 0, 0
	VIBRATO $01, 4, 3
	OCTAVE 2
	NOTE A#, 0
	VIBRATO $01, 0, 3
	LOOP_START
	NOTE A#, 0
	LOOP_END $03
	NOTE A#, 12
	NOTE A#, 12
	VIBRATO $01, 4, 3
	NOTE B_, 0
	LOOP_START
	VOICE $07, 0, 12, 0, 0
	DETUNE $00
	VIBRATO $01, 2, 3
	ENVELOPE $0E
	OCTAVE 3
	NOTE D#, 8
	ENVELOPE $00
	ATTEN 3
	NOTE G_, 4
	ATTEN 2
	NOTE G#, 4
	ATTEN 1
	NOTE A#, 8
	VIBRATO $01, 0, 2
	RELEASE 7, 7
	NOTE A#, 0
	VIBRATO_OFF
	DUTY $0C
	RELEASE $0F, 4
	PAN_RIGHT 0
	DUTY_STEP 8, 1
	OCTAVE 4
	NOTE G_, 4
	NOTE G#, 4
	NOTE A#, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE D#, 8
	DUTY 0
	PAN_BOTH 0
	RELEASE 0, 0
	DUTY_STEP 0, 0
	OCTAVE 3
	VIBRATO $01, 2, 3
	ENVELOPE $06
	NOTE G_, 4
	ATTEN 2
	ENVELOPE $01
	NOTE G#, 4
	ATTEN 0
	ENVELOPE $06
	VIBRATO $01, 4, 3
	NOTE A#, 8
	LOOP_BREAK $FB
	OCTAVE 4
	ENVELOPE $08
	NOTE C#, 8
	ENVELOPE $00
	OCTAVE 3
	NOTE B_, 0
	RELEASE $0C, 7
	NOTE B_, 8
	RELEASE 0, 0
	VIBRATO_OFF
	ATTEN 2
	NOTE A#, 4
	ATTEN 3
	NOTE G#, 4
	VIBRATO $01, 4, 3
	ATTEN 0
	ENVELOPE $03
	NOTE B_, 0
	RELEASE 7, 7
	ENVELOPE $00
	ATTEN 2
	NOTE E_, 0
	LOOP_END $02
	ENVELOPE $00
	ATTEN 3
	NOTE G_, 8
	VIBRATO_OFF
	ATTEN 0
	ENVELOPE $0D
	NOTE G#, 0
	VIBRATO $0F, 4, 2
	ENVELOPE $17
	NOTE G#, 0
	VIBRATO $10, 0, 3
	ENVELOPE $00
	NOTE G#, 0
	NOTE G#, 0
	RELEASE $0A, 7
	NOTE G#, 0
	VIBRATO_OFF
	SND_END

Snd76_Ch3:
	VOICE $07, 10, 2, 0, 0
	REST 4
	VIBRATO $01, 3, 1
	OCTAVE 5
	NOTE G#, 8
	VIBRATO_OFF
	NOTE G_, 4
	NOTE E_, 4
	VIBRATO $01, 3, 1
	NOTE D#, 0
	NOTE D_, 8
	OCTAVE 4
	NOTE B_, 8
	OCTAVE 5
	NOTE D_, 8
	NOTE D#, 0
	VIBRATO_OFF
	NOTE D#, 4
	VIBRATO_OFF
	NOTE D_, 4
	OCTAVE 4
	NOTE B_, 4
	VOICE $07, 4, 2, 0, 0
	VIBRATO $01, 4, 2
	OCTAVE 4
	NOTE A#, 0
	VIBRATO $01, 0, 2
	NOTE A#, 0
	NOTE A#, 4
	RELEASE 8, 7
	NOTE A#, 4
	VIBRATO_OFF
	RELEASE 0, 0
	NOTE G#, 4
	RELEASE 7, 7
	NOTE G#, 4
	RELEASE 0, 0
	NOTE E_, 4
	RELEASE 7, 7
	NOTE E_, 4
	RELEASE 0, 0
	NOTE G#, 4
	RELEASE 7, 7
	NOTE G#, 4
	REST 6
	VIBRATO $05, 0, 1
	RELEASE $0A, 7
	OCTAVE 5
	NOTE D#, 2
	VIBRATO $01, 4, 3
	OCTAVE 4
	RELEASE 0, 0
	NOTE A#, 8
	RELEASE 5, 7
	NOTE A#, 4
	VIBRATO_OFF
	NOTE G#, 4
	NOTE E_, 4
	NOTE D#, 4
	RELEASE 5, 7
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 4
	RELEASE 0, 0
	NOTE A#, 8
	RELEASE 0, 0
	VIBRATO $01, 0, 2
	NOTE A#, 0
	VIBRATO_OFF
	VOICE $07, 9, 2, 0, 0
	WAVE_X $1A
	ATTEN 2
	VIBRATO $01, 0, 2
	RELEASE 7, 7
	OCTAVE 4
	NOTE A#, 0
	VIBRATO_OFF
	ATTEN 1
	WAVE 9
	RELEASE $0D, 7
	PAN_LEFT 0
	OCTAVE 4
	NOTE G_, 4
	NOTE G#, 4
	NOTE A#, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE D#, 8
	ATTEN 2
	WAVE_X $1A
	PAN_BOTH 0
	RELEASE 0, 0
	REST 2
	OCTAVE 4
	VIBRATO $01, 2, 2
	NOTE G_, 4
	NOTE G#, 4
	VIBRATO $01, 4, 2
	NOTE A#, 8
	LOOP_BREAK $FB
	OCTAVE 5
	NOTE C#, 8
	OCTAVE 4
	NOTE B_, 6
	ATTEN 0
	WAVE 9
	RELEASE $0D, 7
	PAN_LEFT 0
	VIBRATO_OFF
	OCTAVE 4
	NOTE E_, 4
	NOTE F#, 4
	RELEASE $0F, 7
	NOTE G#, 10
	ATTEN 2
	WAVE_X $1A
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 4
	NOTE A#, 4
	NOTE G#, 4
	VIBRATO $01, 4, 2
	NOTE B_, 0
	RELEASE 7, 7
	NOTE E_, 14
	VIBRATO_OFF
	VOICE $07, 7, 2, 0, 0
	ATTEN 1
	WAVE_X $60
	OCTAVE 3
	NOTE D#, 0
	VIBRATO $01, 0, 1
	NOTE D#, 0
	NOTE D#, 8
	VIBRATO_OFF
	WAVE 9
	RELEASE $0D, 7
	PAN_LEFT 0
	ATTEN 1
	OCTAVE 4
	NOTE G_, 4
	NOTE G#, 4
	NOTE A#, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE D#, 8
	WAVE_X $60
	PAN_BOTH 0
	RELEASE 0, 0
	ATTEN 1
	VIBRATO $01, 0, 3
	OCTAVE 3
	NOTE D#, 8
	RELEASE 3, 7
	NOTE D#, 0
	RELEASE 0, 0
	VIBRATO_OFF
	OCTAVE 2
	NOTE B_, 0
	VIBRATO $10, 0, 2
	OCTAVE 3
	NOTE C#, 0
	VIBRATO $10, 0, 2
	NOTE D#, 0
	NOTE D#, 0
	RELEASE 5, 7
	NOTE D#, 0
	VIBRATO_OFF
	SND_END

Snd76_Drm:
	LEN_UNIT $07
	REST 0
	REST 8
	DRUM_SND $0D, 4
	DRUM_SND $0D, 0
	REST $0C
	DRUM_SND $0D, 4
	DRUM_SND $0D, 0
	REST 8
	LOOP_START
	DRUM_SND $0D, 4
	DRUM_SND $10, 0
	REST $0C
	LOOP_END $02
	DRUM_SND $0D, 4
	DRUM_SND $10, 0
	REST 4
	DRUM_SND $0D, 4
	DRUM_SND $10, 12
	DRUM_SND $0D, 0
	SND_END

Snd77_Ch2:
	VOICE $06, 8, 15, 15, 2
	DETUNE $03
	LOOP_START
	OCTAVE 1
	NOTE G_, 0
	REST 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 1
	NOTE G_, 1
	LOOP_END $03
	NOTE F_, 0
	REST 4
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 4
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 0
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 4
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	RELEASE 0, 0
	OCTAVE 4
	DUTY 0
	ENVELOPE $09
	PAN_LEFT 0
	NOTE G#, 14
	ENVELOPE $00
	VOICE $06, 8, 15, 15, 2
	DETUNE $03
	OCTAVE 1
	NOTE G_, 0
	NOTE G_, 6
	NOTE G_, 2
	NOTE D#, 4
	NOTE D#, 2
	NOTE G_, 0
	NOTE G_, 6
	NOTE G_, 2
	NOTE D#, 6
	NOTE D#, 2
	NOTE G_, 0
	NOTE G_, 6
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE A_, 0
	NOTE G_, 4
	NOTE A_, 12
	NOTE G_, 0
	NOTE D#, 6
	NOTE D#, 2
	NOTE D#, 4
	NOTE D#, 2
	NOTE A_, 4
	VOICE $06, 0, 14, 0, 0
	DETUNE $00
	REST 4
	OCTAVE 3
	ATTEN 6
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	NOTE C_, 2
	ATTEN 0
	ENVELOPE $19
	VIBRATO $01, 3, 3
	NOTE E_, 0
	VIBRATO_OFF
	RELEASE 9, 5
	RELEASE $0F, 3
	NOTE D#, 8
	ATTEN 6
	RELEASE 0, 0
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	NOTE C_, 2
	ATTEN 0
	VIBRATO $01, 3, 3
	ENVELOPE $19
	NOTE E_, 0
	ENVELOPE $00
	VIBRATO $01, 0, 3
	NOTE E_, 2
	VIBRATO_OFF
	RELEASE 9, 5
	NOTE D#, 2
	ATTEN 6
	NOTE C_, 2
	NOTE D#, 2
	NOTE E_, 2
	VOICE $06, 8, 15, 15, 1
	DUTY_STEP 4, 1
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	RELEASE $0F, 2
	OCTAVE 2
	NOTE C_, 4
	RELEASE $0F, 1
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	RELEASE $0F, 2
	NOTE B_, 4
	OCTAVE 2
	RELEASE $0F, 1
	NOTE D_, 2
	RELEASE $0D, 2
	NOTE C#, 6
	RELEASE $0F, 1
	NOTE C#, 2
	VOICE $06, 8, 15, 13, 2
	DUTY_STEP 0, 0
	OCTAVE 1
	NOTE G#, 2
	VOICE $06, 8, 6, 15, 1
	OCTAVE 3
	NOTE G#, 2
	LOOP_START
	NOTE C_HI, 2
	NOTE G#, 2
	LOOP_END $06
	LOOP_START
	OCTAVE 4
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	LOOP_END $08
	LOOP_START
	OCTAVE 4
	NOTE G#, 2
	OCTAVE 3
	NOTE G#, 2
	LOOP_END $08
	LOOP_START
	OCTAVE 4
	NOTE A_, 2
	OCTAVE 3
	NOTE A_, 2
	LOOP_END $08
	LOOP_START
	OCTAVE 4
	NOTE B_, 2
	OCTAVE 3
	NOTE B_, 2
	LOOP_END $02
	NOTE B_, 2
	VOICE $04, 8, 10, 0, 0
	OCTAVE 3
	ATTEN 2
	NOTE B_, 1
	ATTEN 1
	OCTAVE 4
	NOTE C#, 1
	ATTEN 0
	NOTE D_, 1
	VOICE $06, 8, 14, 0, 0
	ATTEN 3
	NOTE E_, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	NOTE G#, 1
	VOICE $06, 8, 15, 15, 1
	DUTY_STEP 4, 1
	TRANSPOSE_DOWN 1
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	RELEASE $0F, 2
	OCTAVE 2
	NOTE C_, 4
	RELEASE $0F, 1
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	RELEASE $0F, 2
	NOTE B_, 4
	OCTAVE 2
	RELEASE $0F, 1
	NOTE D_, 2
	RELEASE $0D, 2
	NOTE C#, 6
	RELEASE $0F, 1
	NOTE C#, 2
	TRANSPOSE_DOWN 0
	OCTAVE 1
	NOTE G_, 8
	SND_END

Snd77_Ch1:
	VOICE $06, 8, 6, 0, 0
	DETUNE $FE
	REST 1
	VIBRATO $01, 4, 5
	OCTAVE 2
	NOTE G_, 8
	VIBRATO_OFF
	NOTE B_, 4
	OCTAVE 3
	NOTE C_, 4
	VIBRATO $01, 5, 5
	NOTE D_, 0
	VIBRATO_OFF
	RELEASE 7, 7
	NOTE D_, 8
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 4
	OCTAVE 3
	NOTE C_, 4
	VIBRATO $01, 5, 5
	NOTE D_, 0
	VIBRATO_OFF
	RELEASE 7, 5
	NOTE D_, 6
	RELEASE 0, 0
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE G_, 4
	RELEASE 7, 7
	NOTE G#, 6
	RELEASE 0, 0
	VIBRATO_OFF
	NOTE B_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE G_, 2
	VIBRATO $01, 5, 3
	NOTE G#, 0
	VIBRATO $01, 0, 3
	NOTE G#, 2
	VIBRATO_OFF
	NOTE G_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 4
	VIBRATO $01, 0, 3
	NOTE C_, 0
	VIBRATO_OFF
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE G#, 3
	VOICE $06, 4, 15, 0, 0
	DETUNE $FF
	SND_CALL Snd77_Ch1_6759
	NOTE G_, 2
	SND_CALL Snd77_Ch1_6759
	REST 2
	NOTE G_, 2
	SND_CALL Snd77_Ch1_6759
	NOTE G_, 2
	ATTEN 7
	PAN_BOTH 0
	DUTY 4
	OCTAVE 4
	NOTE A_, 1
	DUTY 0
	PAN_LEFT 0
	ATTEN 6
	NOTE A#, 1
	ATTEN 4
	NOTE A_, 1
	ATTEN 6
	NOTE A#, 1
	ATTEN 0
	OCTAVE 5
	NOTE C#, 1
	ATTEN 6
	NOTE D_, 1
	ATTEN 4
	NOTE C#, 1
	ATTEN 6
	NOTE D_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 6
	NOTE F_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 6
	NOTE F_, 1
	ATTEN 0
	NOTE E_, 1
	ATTEN 6
	NOTE D_, 1
	ATTEN 4
	NOTE C#, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 7
	DUTY 4
	PAN_BOTH 0
	OCTAVE 4
	NOTE G_, 1
	DUTY 0
	PAN_LEFT 0
	ATTEN 6
	OCTAVE 5
	NOTE E_, 1
	ATTEN 4
	NOTE D_, 1
	ATTEN 6
	NOTE E_, 1
	ATTEN 7
	DUTY 4
	PAN_BOTH 0
	OCTAVE 4
	NOTE A_, 1
	DUTY 0
	PAN_LEFT 0
	ATTEN 6
	OCTAVE 5
	NOTE D_, 1
	ATTEN 4
	NOTE C#, 1
	ATTEN 6
	OCTAVE 4
	NOTE A#, 1
	DUTY 8
	PAN_BOTH 0
	ATTEN 7
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE A#, 1
	DUTY 4
	OCTAVE 4
	NOTE G_, 1
	DUTY 0
	PAN_LEFT 0
	ATTEN 6
	NOTE G#, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 6
	NOTE G#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 6
	OCTAVE 5
	NOTE C_, 1
	ATTEN 4
	OCTAVE 4
	NOTE A#, 1
	ATTEN 6
	NOTE G#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 6
	NOTE G#, 1
	ATTEN 4
	NOTE A#, 1
	ATTEN 6
	NOTE G#, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 6
	NOTE F#, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 6
	NOTE G#, 1
	ATTEN 7
	PAN_BOTH 0
	DUTY 4
	OCTAVE 4
	NOTE G_, 1
	DUTY 0
	PAN_LEFT 0
	ATTEN 6
	OCTAVE 4
	NOTE A_, 1
	ATTEN 4
	NOTE A#, 1
	ATTEN 6
	OCTAVE 5
	NOTE C_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 7
	PAN_BOTH 0
	DUTY 4
	OCTAVE 4
	NOTE G_, 1
	DUTY 0
	PAN_LEFT 0
	ATTEN 6
	OCTAVE 5
	NOTE G_, 1
	PAN_BOTH 0
	RELEASE 5, 2
	NOTE A_, 4
	RELEASE 8, 2
	NOTE A#, 2
	OCTAVE 6
	NOTE C_, 4
	VOICE $06, 4, 4, 0, 0
	DETUNE $00
	VIBRATO $0E, 2, 3
	OCTAVE 3
	NOTE E_, 12
	VIBRATO $0E, 0, 3
	NOTE E_, 0
	NOTE E_, 0
	NOTE E_, 0
	RELEASE 5, 4
	NOTE E_, 10
	VIBRATO_OFF
	VOICE $06, 4, 15, 13, 1
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE G_, 4
	NOTE G_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 4
	NOTE A_, 2
	NOTE G#, 6
	NOTE G#, 2
	VOICE $06, 4, 15, 15, 1
	OCTAVE 3
	NOTE D#, 2
	VOICE $06, 8, 6, 15, 1
	OCTAVE 3
	NOTE D#, 2
	LOOP_START
	NOTE C_HI, 2
	NOTE D#, 2
	LOOP_END $06
	LOOP_START
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	LOOP_END $08
	LOOP2_START
	VOICE $06, 8, 15, 14, 2
	OCTAVE 1
	NOTE G#, 2
	VOICE $06, 8, 6, 15, 1
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 4
	NOTE D#, 2
	VOICE $06, 8, 15, 14, 2
	OCTAVE 1
	NOTE G#, 2
	LOOP_START
	VOICE $06, 8, 6, 15, 1
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE D#, 2
	LOOP_END $02
	LOOP2_END $02
	LOOP2_START
	VOICE $06, 8, 15, 14, 2
	OCTAVE 1
	NOTE A_, 2
	VOICE $06, 8, 6, 15, 1
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	NOTE E_, 2
	VOICE $06, 8, 15, 14, 2
	OCTAVE 1
	NOTE A_, 2
	LOOP_START
	VOICE $06, 8, 6, 15, 1
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	LOOP_END $02
	LOOP2_END $02
	VOICE $06, 8, 15, 14, 2
	OCTAVE 1
	NOTE B_, 2
	VOICE $06, 8, 6, 15, 1
	OCTAVE 3
	NOTE F#, 2
	NOTE C_HI, 2
	NOTE F#, 2
	VOICE $06, 8, 6, 15, 1
	OCTAVE 2
	NOTE B_, 2
	VOICE $04, 8, 10, 0, 0
	DETUNE $FF
	OCTAVE 2
	ATTEN 2
	NOTE B_, 1
	ATTEN 1
	OCTAVE 3
	NOTE C#, 1
	ATTEN 0
	NOTE D_, 1
	VOICE $06, 8, 14, 0, 0
	ATTEN 3
	NOTE E_, 1
	ATTEN 2
	NOTE F_, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	NOTE G#, 1
	DETUNE $00
	VOICE $06, 4, 15, 13, 1
	TRANSPOSE_DOWN 1
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE G_, 4
	NOTE G_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 4
	NOTE A_, 2
	NOTE G#, 6
	NOTE G#, 2
	TRANSPOSE_DOWN 0
	NOTE D_, 8
	SND_END

Snd77_Ch3:
	VOICE $06, 4, 2, 0, 0
	VIBRATO $01, 4, 5
	OCTAVE 3
	NOTE G_, 8
	VIBRATO_OFF
	NOTE B_, 4
	OCTAVE 4
	NOTE C_, 4
	VIBRATO $01, 5, 5
	NOTE D_, 0
	VIBRATO_OFF
	RELEASE 7, 7
	NOTE D_, 8
	RELEASE 0, 0
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE C_, 4
	VIBRATO $01, 5, 5
	NOTE D_, 0
	VIBRATO_OFF
	RELEASE 7, 5
	NOTE D_, 6
	RELEASE 0, 0
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE G_, 4
	RELEASE 7, 7
	NOTE G#, 6
	RELEASE 0, 0
	VIBRATO_OFF
	NOTE B_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE G_, 2
	VIBRATO $01, 5, 3
	NOTE G#, 0
	VIBRATO $01, 0, 3
	NOTE G#, 2
	VIBRATO_OFF
	NOTE G_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE B_, 2
	OCTAVE 5
	NOTE C_, 4
	VIBRATO $01, 0, 3
	NOTE C_, 0
	VIBRATO_OFF
	OCTAVE 4
	NOTE B_, 4
	OCTAVE 5
	NOTE C_, 4
	OCTAVE 4
	NOTE G#, 4
	VOICE $06, 7, 2, 0, 0
	VIBRATO $01, 5, 3
	OCTAVE 4
	NOTE G_, 0
	VIBRATO $01, 0, 3
	RELEASE 7, 7
	NOTE G_, 10
	RELEASE 5, 2
	VIBRATO_OFF
	NOTE F#, 2
	NOTE D#, 2
	RELEASE 0, 0
	VIBRATO $01, 5, 3
	NOTE D_, 0
	VIBRATO $01, 0, 3
	RELEASE 7, 7
	NOTE D_, 8
	VIBRATO_OFF
	RELEASE 4, 3
	NOTE D#, 4
	NOTE F#, 4
	VIBRATO $01, 5, 3
	RELEASE 0, 0
	NOTE G_, 0
	VIBRATO $01, 0, 3
	RELEASE 7, 7
	NOTE G_, 10
	VIBRATO_OFF
	RELEASE 5, 2
	NOTE D#, 2
	NOTE D_, 2
	VIBRATO $01, 5, 3
	RELEASE 0, 0
	NOTE C#, 0
	VIBRATO_OFF
	RELEASE 4, 3
	OCTAVE 3
	NOTE A#, 4
	NOTE A_, 4
	REST 4
	OCTAVE 4
	NOTE C#, 4
	VIBRATO $01, 5, 3
	RELEASE 0, 0
	NOTE D_, 10
	RELEASE 8, 2
	NOTE D_, 2
	RELEASE 7, 7
	NOTE D#, 8
	VIBRATO_OFF
	RELEASE 4, 3
	NOTE G_, 4
	NOTE A_, 4
	RELEASE $0C, 3
	NOTE A#, 2
	VOICE $06, 7, 4, 0, 0
	VIBRATO $0E, 2, 4
	OCTAVE 5
	NOTE C_, 0
	VIBRATO $0E, 0, 2
	NOTE C_, 0
	NOTE C_, 0
	NOTE C_, 0
	RELEASE 5, 3
	NOTE C_, 10
	VOICE $06, 4, 2, 0, 0
	WAVE_X $1A
	VIBRATO $01, 2, 1
	OCTAVE 5
	NOTE B_, 10
	VIBRATO_OFF
	NOTE A#, 2
	RELEASE 5, 1
	NOTE G_, 2
	VIBRATO $01, 2, 1
	RELEASE 0, 0
	NOTE F#, 10
	RELEASE 5, 1
	VIBRATO_OFF
	NOTE F_, 2
	NOTE D_, 2
	RELEASE 0, 0
	NOTE C#, 2
	RELEASE 5, 1
	NOTE D_, 2
	RELEASE 0, 0
	NOTE F_, 2
	RELEASE 5, 1
	NOTE F#, 2
	RELEASE $0D, 3
	OCTAVE 5
	NOTE G#, 2
	VOICE $06, 1, 2, 13, 3
	REST 4
	OCTAVE 2
	NOTE G#, 6
	NOTE G#, 6
	NOTE G#, 10
	LOOP_START
	NOTE A_, 6
	NOTE A_, 10
	LOOP_END $02
	VOICE $06, 1, 2, 0, 0
	WAVE_X $17
	ATTEN 1
	OCTAVE 5
	NOTE E_, 2
	VIBRATO $01, 5, 2
	NOTE D#, 14
	VIBRATO_OFF
	NOTE C#, 2
	VIBRATO $01, 1, 1
	NOTE C_, 4
	VIBRATO_OFF
	NOTE D#, 2
	RELEASE $0F, 1
	NOTE G#, 1
	REST 7
	RELEASE 0, 0
	NOTE D#, 2
	VIBRATO $01, 5, 2
	NOTE E_, 14
	VIBRATO_OFF
	NOTE D#, 2
	VIBRATO $01, 1, 1
	NOTE C#, 4
	VIBRATO_OFF
	RELEASE $0D, 3
	NOTE C_, 2
	RELEASE 0, 0
	REST 6
	NOTE E_, 2
	NOTE G_, 2
	RELEASE 7, 4
	NOTE F#, 6
	ATTEN 0
	WAVE 1
	OCTAVE 2
	RELEASE $0F, 1
	NOTE B_, 2
	VOICE $04, 1, 2, 0, 0
	DETUNE $02
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D_, 1
	VOICE $06, 1, 2, 0, 0
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G#, 1
	DETUNE $00
	VOICE $06, 4, 2, 0, 0
	WAVE_X $1A
	TRANSPOSE_DOWN 1
	VIBRATO $01, 2, 1
	OCTAVE 5
	NOTE B_, 10
	VIBRATO_OFF
	NOTE A#, 2
	RELEASE 5, 1
	NOTE G_, 2
	VIBRATO $01, 2, 1
	RELEASE 0, 0
	NOTE F#, 10
	RELEASE 5, 1
	VIBRATO_OFF
	NOTE F_, 2
	NOTE D_, 2
	RELEASE 0, 0
	NOTE C#, 2
	RELEASE 5, 1
	NOTE D_, 2
	RELEASE 0, 0
	NOTE F_, 2
	RELEASE 5, 1
	NOTE F#, 2
	TRANSPOSE_DOWN 0
	RELEASE $0F, 3
	OCTAVE 5
	NOTE G_, 8
	SND_END

Snd77_Drm:
	LEN_UNIT $06
	LOOP_START
	OCTAVE 1
	DRUM 3, 0
	REST 4
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 4
	DRUM 3, 1
	DRUM 3, 1
	LOOP_END $03
	DRUM 3, 0
	REST 4
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 4
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 0
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 4
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 0
	DRUM 9, 0
	DRUM 9, 6
	DRUM 9, 2
	DRUM 9, 4
	DRUM 9, 2
	DRUM 9, 0
	DRUM 9, 6
	DRUM 9, 2
	DRUM 9, 6
	DRUM 9, 2
	DRUM 9, 0
	DRUM 9, 6
	DRUM 9, 2
	DRUM 9, 4
	DRUM 9, 2
	DRUM 9, 0
	DRUM 9, 4
	DRUM 9, $0C
	DRUM 9, 0
	DRUM 9, 6
	DRUM 9, 2
	DRUM 9, 4
	DRUM 9, 2
	DRUM $0C, 4
	LEN_UNIT $06
	REST $0C
	REST 0
	DRUM $0C, 0
	REST 0
	REST $0A
	DRUM_SND $0D, 6
	DRUM_SND $0D, 2
	DRUM_SND $0D, 4
	DRUM_SND $0D, 2
	DRUM_SND $0D, 12
	DRUM_SND $0D, 2
	DRUM_SND $0D, 6
	DRUM_SND $0D, 2
	DRUM_SND $0D, 2
	LOOP_START
	DRUM 4, 2
	DRUM 4, 2
	DRUM 3, 2
	LOOP_END $02
	DRUM 4, 2
	DRUM 4, 2
	DRUM 3, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 2
	DRUM 3, 2
	DRUM 4, 2
	DRUM 4, 3
	DRUM 4, 1
	DRUM 3, 4
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 3, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 3, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 4, 4
	DRUM 4, 1
	DRUM 4, 1
	DRUM 3, 3
	DRUM 4, 1
	DRUM 3, 3
	DRUM 4, 1
	DRUM 3, 2
	DRUM 4, 2
	DRUM 4, 5
	DRUM 4, 1
	DRUM 3, 3
	DRUM 4, 1
	DRUM 3, 2
	DRUM 3, 3
	DRUM 4, 3
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 3
	DRUM 4, 1
	DRUM 3, 2
	DRUM 4, 4
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 4
	DRUM 4, 2
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 2
	DRUM_SND $0D, 14
	DRUM_SND $0D, 14
	DRUM_SND $0D, 6
	DRUM_SND $0D, 2
	DRUM $0C, 1
	SND_END
Snd77_Ch1_6759:
	ATTEN 7
	PAN_BOTH 0
	DUTY 4
	OCTAVE 4
	NOTE G_, 1
	DUTY 0
	PAN_LEFT 0
	ATTEN 6
	NOTE G#, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 6
	NOTE G#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 6
	OCTAVE 5
	NOTE C_, 1
	ATTEN 4
	OCTAVE 4
	NOTE A#, 1
	ATTEN 6
	NOTE G#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 6
	NOTE G#, 1
	ATTEN 4
	NOTE A#, 1
	ATTEN 6
	NOTE G#, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 6
	NOTE F#, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 6
	NOTE G#, 1
	ATTEN 7
	DUTY 4
	PAN_BOTH 0
	OCTAVE 4
	NOTE G_, 1
	DUTY 0
	PAN_LEFT 0
	ATTEN 6
	NOTE G#, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 6
	NOTE G#, 1
	ATTEN 0
	NOTE A#, 1
	ATTEN 6
	OCTAVE 5
	NOTE C_, 1
	ATTEN 7
	DUTY 4
	PAN_BOTH 0
	OCTAVE 4
	NOTE G_, 1
	DUTY 0
	PAN_LEFT 0
	ATTEN 6
	NOTE G#, 1
	ATTEN 7
	DUTY 4
	PAN_BOTH 0
	RELEASE $0A, 2
	OCTAVE 4
	NOTE G_, 2
	REST 2
	SND_RET

Snd78_Ch2:
	SND_SEGNO
	VOICE $07, 8, 11, 0, 0
	SND_CALL Snd78_Ch2_6992
	TRANSPOSE_UP 1
	SND_CALL Snd78_Ch2_6992
	TRANSPOSE_DOWN 2
	SND_CALL Snd78_Ch2_6992
	TRANSPOSE_DOWN 0
	SND_CALL Snd78_Ch2_6992
	SND_LOOP

Snd78_Ch1:
	VOICE $07, 8, 9, 0, 0
	REST 3
	SND_SEGNO
	SND_CALL Snd78_Ch1_69E8
	DETUNE $FD
	RELEASE $0F, 2
	ATTEN 3
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 1
	LOOP_START
	DETUNE $00
	PAN_BOTH 0
	DUTY 0
	RELEASE $0E, 2
	ATTEN 0
	OCTAVE 3
	NOTE B_, 2
	RELEASE $0F, 2
	DUTY 8
	PAN_LEFT 0
	ATTEN 3
	DETUNE $FF
	OCTAVE 5
	REST 1
	LOOP_BREAK $FB
	NOTE D_, 1
	LOOP_END $02
	RELEASE 0, 0
	NOTE D_, 2
	ATTEN 7
	NOTE D_, 1
	DETUNE $00
	REST 1
	DETUNE $FD
	RELEASE $0F, 2
	ATTEN 3
	PAN_BOTH 0
	OCTAVE 3
	NOTE D_, 1
	LOOP_START
	DETUNE $00
	PAN_BOTH 0
	DUTY 0
	RELEASE $0E, 2
	ATTEN 0
	OCTAVE 3
	NOTE B_, 2
	RELEASE $0F, 2
	DUTY 8
	PAN_RIGHT 0
	ATTEN 3
	DETUNE $FF
	REST 1
	OCTAVE 5
	LOOP_BREAK $FB
	NOTE D_, 1
	LOOP_END $02
	RELEASE 0, 0
	NOTE D_, 2
	ATTEN 7
	NOTE D_, 1
	REST 1
	ATTEN 3
	PAN_BOTH 0
	DETUNE $FD
	RELEASE $0F, 2
	OCTAVE 3
	NOTE D_, 1
	DETUNE $00
	DUTY 0
	ATTEN 0
	RELEASE $0E, 2
	OCTAVE 3
	NOTE B_, 2
	ATTEN 0
	DUTY 8
	DETUNE $FD
	REST 1
	ATTEN 3
	RELEASE 0, 0
	NOTE D_, 2
	ATTEN 7
	NOTE D_, 2
	DETUNE $00
	TRANSPOSE_DOWN 2
	SND_CALL Snd78_Ch1_69E8
	TRANSPOSE_DOWN 0
	SND_CALL Snd78_Ch1_69E8
	SND_LOOP

Snd78_Ch3:
	SND_SEGNO
	VOICE $07, 1, 2, 0, 0
	OCTAVE 2
	NOTE F#, 4
	RELEASE $0C, 4
	WAVE 7
	OCTAVE 4
	NOTE F#, 2
	WAVE 1
	VIBRATO $04, 0, 3
	OCTAVE 3
	NOTE F#, 2
	VIBRATO_OFF
	WAVE 7
	NOTE C_HI, 2
	REST 2
	RELEASE $0C, 6
	WAVE 1
	OCTAVE 2
	NOTE F#, 4
	LOOP_START
	WAVE 7
	RELEASE $0C, 4
	OCTAVE 4
	NOTE F#, 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	LOOP_BREAK $FB
	NOTE F#, 2
	LOOP_END $02
	REST 2
	VIBRATO $01, 2, 7
	NOTE F#, 4
	VIBRATO_OFF
	WAVE 7
	RELEASE $0C, 4
	OCTAVE 4
	NOTE F#, 2
	REST 2
	VOICE $07, 1, 2, 0, 0
	OCTAVE 2
	NOTE G_, 4
	RELEASE $0C, 4
	WAVE 7
	OCTAVE 4
	NOTE G_, 2
	WAVE 1
	VIBRATO $04, 0, 3
	OCTAVE 3
	NOTE G_, 2
	VIBRATO_OFF
	WAVE 7
	NOTE C_HI, 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE D_, 2
	VIBRATO $01, 2, 7
	OCTAVE 2
	NOTE G_, 4
	VIBRATO_OFF
	LOOP_START
	WAVE 7
	RELEASE $0C, 4
	OCTAVE 4
	NOTE G_, 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	LOOP_BREAK $FB
	NOTE G_, 2
	LOOP_END $02
	REST 2
	NOTE G_, 4
	WAVE 7
	RELEASE $0C, 4
	OCTAVE 4
	NOTE G_, 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE A_, 2
	VOICE $07, 1, 2, 0, 0
	OCTAVE 2
	NOTE G_, 4
	RELEASE $0C, 4
	WAVE 7
	OCTAVE 4
	NOTE D_, 2
	WAVE 1
	VIBRATO $04, 0, 3
	OCTAVE 3
	NOTE G_, 2
	VIBRATO_OFF
	WAVE 7
	OCTAVE 4
	NOTE D_, 2
	REST 2
	RELEASE 0, 0
	WAVE 1
	VIBRATO $01, 2, 7
	OCTAVE 2
	NOTE G_, 4
	VIBRATO_OFF
	LOOP_START
	WAVE 7
	RELEASE $0C, 4
	OCTAVE 4
	NOTE D_, 2
	RELEASE 0, 0
	WAVE 1
	LOOP_BREAK $FB
	OCTAVE 2
	NOTE G_, 2
	LOOP_END $02
	REST 2
	VIBRATO $07, 0, 5
	OCTAVE 3
	NOTE G_, 4
	VIBRATO_OFF
	WAVE 7
	RELEASE $0C, 4
	OCTAVE 4
	NOTE D_, 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE G_, 2
	VOICE $07, 1, 2, 0, 0
	VIBRATO $01, 2, 3
	OCTAVE 2
	NOTE F#, 4
	VIBRATO_OFF
	RELEASE $0C, 4
	WAVE 7
	OCTAVE 4
	NOTE F#, 2
	WAVE 1
	OCTAVE 3
	NOTE C#, 2
	WAVE 7
	OCTAVE 4
	NOTE F#, 2
	REST 2
	WAVE 1
	VIBRATO $01, 2, 5
	OCTAVE 3
	NOTE C_, 4
	VIBRATO_OFF
	LOOP_START
	WAVE 7
	RELEASE $0C, 4
	OCTAVE 4
	NOTE F#, 2
	WAVE 1
	OCTAVE 2
	LOOP_BREAK $FB
	NOTE A_, 2
	LOOP_END $02
	RELEASE 0, 0
	NOTE A_, 2
	NOTE G#, 2
	NOTE G_, 2
	WAVE 7
	RELEASE $0C, 4
	OCTAVE 4
	NOTE F#, 2
	WAVE 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE F_, 2
	SND_LOOP

Snd78_Drm:
	LEN_UNIT $07
	SND_SEGNO
	LOOP_START
	DRUM $0C, 4
	DRUM 3, 4
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 4
	DRUM 3, 4
	DRUM_SND $0D, 8
	DRUM_SND $0D, 4
	LOOP_BREAK $FB
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 4
	DRUM 3, 4
	DRUM 3, 4
	DRUM_SND $0D, 8
	LOOP_END $02
	REST 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 4
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 4
	DRUM_SND $0D, 4
	DRUM 3, 2
	DRUM 3, 2
	SND_LOOP
Snd78_Ch2_6992:
	REST 2
	OCTAVE 3
	NOTE C#, 2
	DUTY 0
	ATTEN 3
	RELEASE $0E, 2
	OCTAVE 4
	NOTE C#, 2
	ATTEN 0
	RELEASE 0, 0
	DUTY 8
	PAN_LEFT 0
	NOTE C_HI, 2
	PAN_BOTH 0
	DUTY 0
	RELEASE $0E, 2
	ATTEN 3
	NOTE C#, 2
	ATTEN 0
	RELEASE 0, 0
	DUTY 8
	PAN_LEFT 0
	NOTE C_HI, 2
	ATTEN 4
	NOTE C_HI, 2
	ATTEN 0
	DUTY 8
	PAN_BOTH 0
	OCTAVE 3
	NOTE C#, 2
	LOOP_START
	PAN_BOTH 0
	RELEASE $0E, 2
	DUTY 0
	ATTEN 3
	OCTAVE 4
	NOTE C#, 2
	ATTEN 0
	RELEASE 0, 0
	DUTY 8
	PAN_RIGHT 0
	NOTE C_HI, 2
	LOOP_END $02
	ATTEN 4
	NOTE C_HI, 2
	ATTEN 0
	DUTY 8
	PAN_BOTH 0
	OCTAVE 3
	NOTE C#, 2
	DUTY 0
	ATTEN 3
	RELEASE $0E, 2
	NOTE C_HI, 2
	ATTEN 0
	DUTY 8
	RELEASE 0, 0
	OCTAVE 3
	NOTE C#, 2
	SND_RET
Snd78_Ch1_69E8:
	DETUNE $FD
	ATTEN 3
	RELEASE $0F, 2
	PAN_BOTH 0
	OCTAVE 3
	NOTE C#, 1
	LOOP_START
	DETUNE $00
	PAN_BOTH 0
	DUTY 0
	RELEASE $0E, 2
	ATTEN 0
	OCTAVE 3
	NOTE A_, 2
	DUTY 8
	PAN_LEFT 0
	ATTEN 3
	DETUNE $FF
	OCTAVE 5
	REST 1
	LOOP_BREAK $FB
	RELEASE $0F, 2
	NOTE C#, 1
	LOOP_END $02
	RELEASE 0, 0
	NOTE C#, 2
	ATTEN 7
	NOTE C#, 1
	DETUNE $00
	REST 1
	DETUNE $FD
	RELEASE $0F, 2
	ATTEN 3
	PAN_BOTH 0
	OCTAVE 3
	NOTE C#, 1
	LOOP_START
	DETUNE $00
	PAN_BOTH 0
	DUTY 0
	RELEASE $0E, 2
	ATTEN 0
	OCTAVE 3
	NOTE A_, 2
	DUTY 8
	PAN_RIGHT 0
	ATTEN 3
	DETUNE $FF
	REST 1
	OCTAVE 5
	LOOP_BREAK $FB
	RELEASE $0F, 2
	NOTE C#, 1
	LOOP_END $02
	RELEASE 0, 0
	NOTE C#, 2
	ATTEN 7
	NOTE C#, 1
	REST 1
	ATTEN 3
	PAN_BOTH 0
	DETUNE $FD
	RELEASE $0F, 2
	OCTAVE 3
	NOTE C#, 1
	DETUNE $00
	DUTY 0
	ATTEN 0
	RELEASE $0E, 2
	OCTAVE 3
	NOTE A_, 2
	ATTEN 0
	DUTY 8
	DETUNE $FD
	REST 1
	ATTEN 3
	RELEASE 0, 0
	NOTE C#, 2
	ATTEN 7
	NOTE C#, 2
	DETUNE $00
	SND_RET

Snd79_Ch2:
	SND_SEGNO
	VOICE $06, 0, 9, 0, 0
	DUTY_STEP 4, 1
	DETUNE $FF
	ENVELOPE $01
	ATTEN 6
	VIBRATO $01, 2, 4
	OCTAVE 3
	NOTE G#, 6
	ENVELOPE $00
	ATTEN 1
	NOTE A#, 2
	ATTEN 0
	OCTAVE 4
	NOTE C_, 2
	ENVELOPE $06
	NOTE D_, 12
	ENVELOPE $0A
	RELEASE 7, 7
	NOTE D#, 6
	RELEASE 0, 0
	ENVELOPE $00
	NOTE C#, 2
	ATTEN 1
	NOTE D#, 2
	ATTEN 2
	NOTE F_, 4
	ENVELOPE $16
	NOTE C#, 8
	RELEASE 0, 0
	ATTEN 0
	ENVELOPE $15
	RELEASE 7, 7
	NOTE D#, 6
	ENVELOPE $00
	ATTEN 1
	NOTE F_, 2
	ATTEN 0
	NOTE F#, 2
	NOTE G#, 4
	NOTE F_, 4
	ATTEN 2
	ENVELOPE $05
	NOTE G#, 4
	ATTEN 0
	ENVELOPE $00
	NOTE G_, 10
	VOICE $06, 8, 15, 0, 0
	OCTAVE 2
	NOTE D#, 2
	RELEASE $0F, 1
	DUTY 4
	ATTEN 3
	NOTE C_HI, 1
	NOTE C_HI, 1
	RELEASE 0, 0
	ATTEN 0
	DUTY 8
	NOTE F_, 2
	RELEASE $0F, 1
	DUTY 4
	ATTEN 3
	NOTE C_HI, 1
	NOTE C_HI, 1
	RELEASE 0, 0
	ATTEN 0
	DUTY 8
	NOTE D#, 2
	RELEASE $0F, 2
	DUTY 4
	ATTEN 3
	NOTE C_HI, 2
	ATTEN 0
	SND_LOOP

Snd79_Ch1:
	SND_SEGNO
	VOICE $06, 4, 10, 15, 2
	OCTAVE 3
	NOTE D#, 2
	RELEASE $0F, 1
	NOTE D#, 1
	NOTE D#, 1
	RELEASE $0F, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE F_, 2
	RELEASE $0F, 1
	NOTE F_, 1
	NOTE F_, 1
	RELEASE $0F, 2
	NOTE F_, 2
	RELEASE 0, 0
	DUTY 8
	NOTE F_, 1
	RELEASE $0F, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	LOOP_START
	RELEASE $0F, 2
	DUTY 4
	NOTE F#, 2
	RELEASE $0F, 1
	NOTE F#, 1
	NOTE F#, 1
	RELEASE $0F, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE G#, 2
	RELEASE $0F, 1
	NOTE G#, 1
	NOTE G#, 1
	RELEASE $0F, 2
	NOTE G#, 2
	RELEASE 0, 0
	DUTY 8
	NOTE G#, 1
	RELEASE $0F, 1
	LOOP_BREAK $FB
	NOTE G_, 1
	NOTE F_, 1
	NOTE G#, 1
	LOOP_END $02
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE F_, 1
	RELEASE $0F, 2
	DUTY 4
	OCTAVE 3
	NOTE A#, 2
	RELEASE $0F, 1
	NOTE A#, 1
	NOTE A#, 1
	RELEASE $0F, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	RELEASE $0F, 1
	NOTE A#, 1
	RELEASE $0F, 3
	NOTE A#, 3
	RELEASE $0F, 1
	NOTE A#, 1
	NOTE A#, 1
	RELEASE $0F, 2
	NOTE A#, 2
	NOTE A#, 2
	SND_LOOP

Snd79_Ch3:
	SND_SEGNO
	VOICE $06, 1, 2, 0, 0
	OCTAVE 2
	NOTE G#, 2
	RELEASE $0E, 3
	WAVE 4
	NOTE C_HI, 1
	NOTE C_HI, 1
	RELEASE $0D, 4
	NOTE C_HI, 2
	RELEASE 0, 0
	WAVE 1
	NOTE G#, 2
	WAVE 4
	RELEASE $0D, 4
	NOTE C_HI, 2
	RELEASE 0, 0
	WAVE 1
	NOTE A#, 2
	NOTE G#, 2
	OCTAVE 3
	RELEASE $0E, 3
	WAVE 4
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	RELEASE 0, 0
	WAVE 1
	NOTE A#, 2
	RELEASE $0D, 4
	WAVE 4
	NOTE C_HI, 2
	RELEASE 0, 0
	WAVE 1
	NOTE A#, 2
	LOOP_START
	RELEASE 0, 0
	WAVE 1
	OCTAVE 2
	NOTE B_, 2
	RELEASE $0E, 3
	WAVE 4
	NOTE C_HI, 1
	NOTE C_HI, 1
	RELEASE $0D, 4
	NOTE C_HI, 2
	RELEASE 0, 0
	WAVE 1
	NOTE B_, 2
	WAVE 4
	RELEASE $0D, 4
	NOTE C_HI, 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	RELEASE $0E, 3
	WAVE 4
	OCTAVE 4
	NOTE C#, 1
	NOTE C#, 1
	OCTAVE 2
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE C#, 2
	RELEASE $0D, 4
	WAVE 4
	NOTE C_HI, 2
	RELEASE 0, 0
	WAVE 1
	NOTE C#, 2
	LOOP_END $02
	RELEASE 0, 0
	WAVE 1
	OCTAVE 3
	NOTE D#, 2
	RELEASE $0E, 3
	WAVE 4
	NOTE C_HI, 1
	NOTE C_HI, 1
	RELEASE $0D, 4
	NOTE C_HI, 2
	RELEASE 0, 0
	WAVE 1
	NOTE D#, 2
	WAVE 4
	RELEASE $0D, 4
	NOTE C_HI, 2
	VOICE $06, 12, 2, 14, 4
	PAN_LEFT 0
	WAVE $0B
	OCTAVE 6
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	WAVE $0C
	PAN_BOTH 0
	NOTE C_, 1
	OCTAVE 5
	NOTE A#, 1
	NOTE G#, 1
	WAVE $0B
	PAN_RIGHT 0
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	SND_LOOP

Snd79_Drm:
	LEN_UNIT $06
	SND_SEGNO
	DRUM $0C, 6
	DRUM 9, 4
	DRUM $0C, 6
	DRUM 9, 2
	DRUM $0C, 4
	DRUM $0C, 6
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0C, 4
	DRUM $0C, 4
	DRUM $0C, 4
	DRUM $0C, 6
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 2
	DRUM $0C, 6
	DRUM 9, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0C, 6
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0C, 6
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	SND_LOOP

Snd7A_Ch2:
	VOICE $0D, 8, 9, 0, 0
	SND_SEGNO
	OCTAVE 3
	LOOP_START
	NOTE A_, 2
	ATTEN 2
	NOTE A_, 1
	ATTEN 4
	NOTE A_, 1
	ATTEN 0
	LOOP_END $03
	NOTE A#, 2
	ATTEN 2
	NOTE A#, 1
	ATTEN 4
	NOTE A#, 1
	ATTEN 0
	NOTE A_, 2
	ATTEN 2
	NOTE A_, 1
	ATTEN 4
	NOTE A_, 1
	ATTEN 0
	NOTE G_, 2
	ATTEN 2
	NOTE G_, 1
	ATTEN 4
	NOTE G_, 1
	ATTEN 0
	VIBRATO $01, 4, 3
	RELEASE 5, 6
	NOTE F#, 8
	VIBRATO_OFF
	RELEASE 0, 0
	OCTAVE 4
	LOOP_START
	NOTE C_, 2
	ATTEN 2
	NOTE C_, 1
	ATTEN 4
	NOTE C_, 1
	ATTEN 0
	LOOP_END $03
	NOTE C#, 2
	ATTEN 2
	NOTE C#, 1
	ATTEN 4
	NOTE C#, 1
	ATTEN 0
	NOTE C_, 2
	ATTEN 2
	NOTE C_, 1
	ATTEN 4
	NOTE C_, 1
	ATTEN 0
	OCTAVE 3
	NOTE A#, 2
	ATTEN 2
	NOTE A#, 1
	ATTEN 4
	NOTE A#, 1
	ATTEN 0
	VIBRATO $01, 4, 3
	RELEASE 5, 6
	NOTE A_, 8
	VIBRATO_OFF
	RELEASE 0, 0
	SND_LOOP

Snd7A_Ch1:
	VOICE $0D, 8, 11, 0, 0
	SND_SEGNO
	OCTAVE 3
	LOOP_START
	NOTE C#, 2
	ATTEN 2
	NOTE C#, 1
	ATTEN 4
	NOTE C#, 1
	ATTEN 0
	LOOP_END $03
	NOTE D_, 2
	ATTEN 2
	NOTE D_, 1
	ATTEN 4
	NOTE D_, 1
	ATTEN 0
	NOTE C#, 2
	ATTEN 2
	NOTE C#, 1
	ATTEN 4
	NOTE C#, 1
	ATTEN 0
	OCTAVE 2
	NOTE A#, 2
	ATTEN 2
	NOTE A#, 1
	ATTEN 4
	NOTE A#, 1
	ATTEN 0
	VIBRATO $01, 4, 3
	RELEASE 5, 6
	NOTE A#, 8
	VIBRATO_OFF
	RELEASE 0, 0
	OCTAVE 3
	LOOP_START
	NOTE D#, 2
	ATTEN 2
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	LOOP_END $03
	NOTE E_, 2
	ATTEN 2
	NOTE E_, 1
	ATTEN 4
	NOTE E_, 1
	ATTEN 0
	NOTE D#, 2
	ATTEN 2
	NOTE D#, 1
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	NOTE D_, 2
	ATTEN 2
	NOTE D_, 1
	ATTEN 4
	NOTE D_, 1
	ATTEN 0
	VIBRATO $01, 4, 3
	RELEASE 5, 6
	NOTE C#, 8
	VIBRATO_OFF
	RELEASE 0, 0
	SND_LOOP

Snd7A_Ch3:
	SND_SEGNO
	VOICE $0D, 1, 2, 3, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	RELEASE 5, 7
	WAVE_X $1D
	OCTAVE 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D#, 4
	RELEASE 5, 6
	VIBRATO $01, 3, 3
	NOTE D_, 4
	WAVE 1
	VIBRATO_OFF
	RELEASE 0, 0
	OCTAVE 2
	NOTE A#, 4
	RELEASE 3, 2
	NOTE A_, 2
	NOTE A_, 2
	RELEASE 5, 7
	WAVE_X $1D
	OCTAVE 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G#, 4
	NOTE G_, 4
	NOTE F_, 4
	RELEASE 5, 6
	VIBRATO $01, 3, 3
	NOTE E_, 4
	WAVE 1
	VIBRATO_OFF
	RELEASE 0, 0
	OCTAVE 2
	NOTE A#, 4
	SND_LOOP

Snd7A_Drm:
	LEN_UNIT $0D
	SND_SEGNO
	DRUM_SND $0D, 4
	DRUM $0C, $0C
	DRUM_SND $0D, 8
	DRUM_SND $0D, 4
	DRUM_SND $0D, 4
	DRUM_SND $0D, 4
	DRUM $0C, $0C
	DRUM_SND $0D, 8
	DRUM_SND $0D, 4
	DRUM_SND $0D, 4
	SND_LOOP

Snd7B_Ch2:
	SND_SEGNO
	VOICE $06, 0, 15, 14, 4
	DETUNE $0C
	PAN_BOTH 0
	OCTAVE 1
	NOTE G#, 2
	PAN_LEFT 0
	NOTE G#, 6
	PAN_BOTH 0
	NOTE G#, 2
	PAN_LEFT 0
	NOTE G#, 14
	PAN_BOTH 0
	NOTE G_, 2
	PAN_LEFT 0
	NOTE G_, 2
	PAN_BOTH 0
	NOTE A_, 2
	PAN_LEFT 0
	NOTE A_, 2
	PAN_BOTH 0
	NOTE G#, 2
	PAN_LEFT 0
	NOTE G#, 6
	PAN_BOTH 0
	NOTE G#, 2
	PAN_LEFT 0
	NOTE G#, 14
	PAN_BOTH 0
	VIBRATO $04, 0, 4
	NOTE B_, 2
	VIBRATO_OFF
	PAN_LEFT 0
	NOTE B_, 2
	PAN_BOTH 0
	NOTE A_, 2
	PAN_LEFT 0
	NOTE A_, 2
	PAN_BOTH 0
	NOTE G#, 2
	PAN_LEFT 0
	NOTE G#, 6
	PAN_BOTH 0
	NOTE G#, 2
	PAN_LEFT 0
	NOTE G#, 14
	PAN_BOTH 0
	NOTE G#, 2
	PAN_LEFT 0
	NOTE G#, 2
	PAN_BOTH 0
	NOTE A_, 2
	PAN_LEFT 0
	NOTE A_, 2
	PAN_BOTH 0
	NOTE G#, 2
	PAN_LEFT 0
	NOTE G#, 6
	PAN_BOTH 0
	NOTE G#, 2
	PAN_LEFT 0
	NOTE G#, 6
	PAN_BOTH 0
	NOTE G#, 2
	PAN_LEFT 0
	NOTE G#, 2
	PAN_BOTH 0
	NOTE A_, 2
	PAN_LEFT 0
	NOTE A_, 2
	PAN_BOTH 0
	NOTE G#, 2
	PAN_LEFT 0
	NOTE G#, 2
	PAN_BOTH 0
	NOTE G_, 2
	PAN_LEFT 0
	NOTE G_, 2
	PAN_BOTH 0
	NOTE G#, 2
	PAN_LEFT 0
	NOTE G#, 6
	PAN_BOTH 0
	NOTE G#, 2
	PAN_LEFT 0
	NOTE G#, 14
	PAN_BOTH 0
	NOTE A_, 2
	PAN_LEFT 0
	NOTE A_, 2
	PAN_BOTH 0
	NOTE G_, 2
	PAN_LEFT 0
	NOTE G_, 2
	PAN_BOTH 0
	NOTE G#, 2
	PAN_LEFT 0
	NOTE G#, 6
	PAN_BOTH 0
	NOTE G#, 2
	PAN_LEFT 0
	NOTE G#, 14
	PAN_BOTH 0
	NOTE B_, 2
	PAN_LEFT 0
	NOTE B_, 2
	PAN_BOTH 0
	NOTE A_, 2
	PAN_LEFT 0
	NOTE A_, 2
	PAN_BOTH 0
	NOTE G#, 2
	PAN_LEFT 0
	NOTE G#, 6
	PAN_BOTH 0
	NOTE G#, 2
	PAN_LEFT 0
	NOTE G#, 14
	NOTE A_, 2
	PAN_LEFT 0
	VIBRATO $01, 2, 3
	NOTE A_, 6
	VIBRATO_OFF
	PAN_BOTH 0
	NOTE G#, 2
	PAN_LEFT 0
	NOTE G#, 14
	PAN_BOTH 0
	NOTE B_, 2
	PAN_LEFT 0
	NOTE B_, 2
	PAN_BOTH 0
	NOTE A#, 2
	PAN_LEFT 0
	NOTE A#, 2
	PAN_BOTH 0
	NOTE G#, 2
	PAN_LEFT 0
	NOTE G#, 2
	PAN_BOTH 0
	NOTE G_, 2
	PAN_LEFT 0
	NOTE G_, 2
	SND_LOOP

Snd7B_Ch1:
	VOICE $06, 8, 13, 14, 4
	DETUNE $F4
	REST 1
	SND_SEGNO
	PAN_BOTH 0
	OCTAVE 1
	NOTE G#, 2
	PAN_RIGHT 0
	NOTE G#, 6
	PAN_BOTH 0
	NOTE G#, 2
	PAN_RIGHT 0
	NOTE G#, 14
	PAN_BOTH 0
	NOTE G_, 2
	PAN_RIGHT 0
	NOTE G_, 2
	PAN_BOTH 0
	NOTE A_, 2
	PAN_RIGHT 0
	NOTE A_, 2
	PAN_BOTH 0
	NOTE G#, 2
	PAN_RIGHT 0
	NOTE G#, 6
	PAN_BOTH 0
	NOTE G#, 2
	PAN_RIGHT 0
	NOTE G#, 14
	PAN_BOTH 0
	VIBRATO $04, 0, 4
	NOTE B_, 2
	PAN_RIGHT 0
	VIBRATO_OFF
	NOTE B_, 2
	PAN_BOTH 0
	NOTE A_, 2
	PAN_RIGHT 0
	NOTE A_, 2
	PAN_BOTH 0
	NOTE G#, 2
	PAN_RIGHT 0
	NOTE G#, 6
	PAN_BOTH 0
	NOTE G#, 2
	PAN_RIGHT 0
	NOTE G#, 14
	PAN_BOTH 0
	NOTE G#, 2
	PAN_RIGHT 0
	NOTE G#, 2
	PAN_BOTH 0
	NOTE A_, 2
	PAN_RIGHT 0
	NOTE A_, 2
	PAN_BOTH 0
	NOTE G#, 2
	PAN_RIGHT 0
	NOTE G#, 6
	PAN_BOTH 0
	NOTE G#, 2
	PAN_RIGHT 0
	NOTE G#, 6
	PAN_BOTH 0
	NOTE G#, 2
	PAN_RIGHT 0
	NOTE G#, 2
	PAN_BOTH 0
	NOTE A_, 2
	PAN_RIGHT 0
	NOTE A_, 2
	PAN_BOTH 0
	NOTE G#, 2
	PAN_RIGHT 0
	NOTE G#, 2
	PAN_BOTH 0
	NOTE G_, 2
	PAN_RIGHT 0
	NOTE G_, 2
	PAN_BOTH 0
	NOTE G#, 2
	PAN_RIGHT 0
	NOTE G#, 6
	PAN_BOTH 0
	NOTE G#, 2
	PAN_RIGHT 0
	NOTE G#, 14
	PAN_BOTH 0
	NOTE A_, 2
	PAN_RIGHT 0
	NOTE A_, 2
	PAN_BOTH 0
	NOTE G_, 2
	PAN_RIGHT 0
	NOTE G_, 2
	PAN_BOTH 0
	NOTE G#, 2
	PAN_RIGHT 0
	NOTE G#, 6
	PAN_BOTH 0
	NOTE G#, 2
	PAN_RIGHT 0
	NOTE G#, 14
	PAN_BOTH 0
	NOTE B_, 2
	PAN_RIGHT 0
	NOTE B_, 2
	PAN_BOTH 0
	NOTE A_, 2
	PAN_RIGHT 0
	NOTE A_, 2
	PAN_BOTH 0
	NOTE G#, 2
	PAN_RIGHT 0
	NOTE G#, 6
	PAN_BOTH 0
	NOTE G#, 2
	PAN_RIGHT 0
	NOTE G#, 14
	PAN_BOTH 0
	NOTE A_, 2
	PAN_RIGHT 0
	VIBRATO $01, 2, 3
	NOTE A_, 6
	VIBRATO_OFF
	PAN_BOTH 0
	NOTE G#, 2
	PAN_RIGHT 0
	NOTE G#, 14
	PAN_BOTH 0
	NOTE B_, 2
	PAN_RIGHT 0
	NOTE B_, 2
	PAN_BOTH 0
	NOTE A#, 2
	PAN_RIGHT 0
	NOTE A#, 2
	PAN_BOTH 0
	NOTE G#, 2
	PAN_RIGHT 0
	NOTE G#, 2
	PAN_BOTH 0
	NOTE G_, 2
	PAN_RIGHT 0
	NOTE G_, 2
	SND_LOOP

Snd7B_Ch3:
	LEN_UNIT $03
	REST 1
	SND_SEGNO
	LOOP_START
	VOICE $06, 10, 2, 0, 0
	WAVE_X $18
	VIBRATO $01, 3, 5
	OCTAVE 3
	NOTE G#, 0
	RELEASE 8, 7
	NOTE A_, 0
	VIBRATO $01, 3, 5
	RELEASE 0, 0
	OCTAVE 4
	NOTE C_, 0
	RELEASE 8, 7
	NOTE D#, 0
	RELEASE 0, 0
	VIBRATO $07, 0, 3
	NOTE F#, 8
	VIBRATO $01, 2, 5
	LOOP_BREAK $FB
	NOTE E_, 8
	NOTE D#, 8
	NOTE E_, 8
	VIBRATO $01, 3, 5
	NOTE D#, 0
	OCTAVE 3
	RELEASE 5, 6
	NOTE A_, 0
	LOOP_END $02
	NOTE G_, 8
	VIBRATO $04, 0, 3
	NOTE A_, 4
	VIBRATO $01, 0, 5
	NOTE A_, 4
	VIBRATO $01, 2, 5
	VIBRATO_OFF
	NOTE G_, 8
	VIBRATO $01, 4, 3
	NOTE F#, 8
	VIBRATO $01, 0, 4
	NOTE F#, 8
	VIBRATO $10, 0, 5
	NOTE F#, 6
	RELEASE $0A, 6
	VIBRATO $03, 0, 2
	NOTE F#, 10
	SND_LOOP

Snd7B_Drm:
	LEN_UNIT $03
	REST 1
	LEN_UNIT $06
	SND_SEGNO
	DRUM $0C, 0
	REST 0
	LOOP_START
	DRUM_SND $0D, 0
	REST 0
	LOOP_END $06
	DRUM_SND $0D, 0
	REST 8
	DRUM_SND $0D, 8
	SND_LOOP

Snd7D_Ch2:
	SND_SEGNO
	VOICE $07, 8, 11, 0, 0
	VIBRATO $01, 3, 5
	ENVELOPE $03
	OCTAVE 1
	NOTE B_, 12
	ENVELOPE $16
	OCTAVE 2
	NOTE F#, 12
	ENVELOPE $00
	VIBRATO $07, 0, 3
	NOTE G_, 8
	ATTEN 2
	VIBRATO $01, 2, 4
	ATTEN 1
	NOTE F#, 8
	ATTEN 0
	NOTE E_, 4
	ATTEN 1
	ENVELOPE $05
	NOTE A#, 4
	ATTEN 0
	ENVELOPE $00
	VIBRATO $01, 2, 4
	NOTE B_, 12
	ENVELOPE $16
	OCTAVE 3
	NOTE F#, 12
	ENVELOPE $00
	VIBRATO $07, 0, 3
	NOTE G_, 8
	ATTEN 2
	VIBRATO $01, 2, 3
	ATTEN 1
	NOTE F#, 8
	ATTEN 0
	NOTE E_, 4
	ATTEN 1
	ENVELOPE $05
	NOTE A#, 4
	LOOP_START
	OCTAVE 3
	NOTE B_, 4
	ATTEN 3
	RELEASE $0C, 5
	NOTE B_, 4
	ATTEN 0
	RELEASE 0, 0
	LOOP_END $02
	VIBRATO $07, 0, 2
	OCTAVE 4
	NOTE D_, 4
	VIBRATO $01, 2, 3
	NOTE C_, 4
	VIBRATO_OFF
	LOOP_START
	OCTAVE 3
	NOTE B_, 4
	ATTEN 3
	RELEASE $0C, 5
	NOTE B_, 4
	ATTEN 0
	RELEASE 0, 0
	LOOP_END $02
	VIBRATO $01, 4, 5
	NOTE G_, 8
	VIBRATO_OFF
	LOOP_START
	OCTAVE 3
	NOTE B_, 4
	ATTEN 3
	RELEASE $0C, 5
	NOTE B_, 4
	ATTEN 0
	RELEASE 0, 0
	LOOP_END $02
	VIBRATO $07, 0, 2
	OCTAVE 4
	NOTE C_, 4
	VIBRATO_OFF
	OCTAVE 3
	NOTE A#, 4
	VIBRATO $01, 4, 5
	RELEASE 7, 7
	OCTAVE 3
	NOTE B_, 0
	REST 4
	VIBRATO_OFF
	RELEASE 0, 0
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	SND_LOOP

Snd7D_Ch1:
	SND_SEGNO
	VOICE $07, 8, 11, 0, 0
	DETUNE $F6
	REST 2
	VIBRATO $01, 3, 5
	ATTEN 4
	ENVELOPE $03
	OCTAVE 1
	NOTE B_, 12
	ATTEN 4
	ENVELOPE $16
	OCTAVE 2
	NOTE F#, 12
	ATTEN 0
	ATTEN 4
	ENVELOPE $00
	VIBRATO $07, 0, 3
	NOTE G_, 8
	ATTEN 6
	VIBRATO $01, 2, 4
	ATTEN 5
	NOTE F#, 8
	ATTEN 4
	NOTE E_, 4
	ATTEN 6
	ENVELOPE $05
	NOTE A#, 2
	DETUNE $00
	ATTEN 0
	ENVELOPE $00
	VIBRATO $01, 2, 4
	NOTE F#, 12
	ATTEN 4
	ENVELOPE $16
	NOTE B_, 12
	ATTEN 0
	ENVELOPE $00
	VIBRATO $07, 0, 3
	OCTAVE 3
	NOTE C_, 8
	ATTEN 2
	VIBRATO $01, 2, 3
	ATTEN 1
	OCTAVE 2
	NOTE B_, 8
	ATTEN 0
	VIBRATO_OFF
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE A#, 2
	LOOP_START
	OCTAVE 3
	NOTE D#, 4
	ATTEN 3
	RELEASE $0C, 5
	NOTE D#, 4
	ATTEN 0
	RELEASE 0, 0
	LOOP_END $02
	VIBRATO $07, 0, 3
	NOTE E_, 4
	VIBRATO $01, 2, 4
	NOTE D#, 4
	VIBRATO_OFF
	LOOP_START
	NOTE D#, 4
	ATTEN 3
	RELEASE $0C, 5
	NOTE D#, 4
	ATTEN 0
	RELEASE 0, 0
	LOOP_END $02
	VIBRATO $01, 4, 4
	NOTE C_, 8
	VIBRATO_OFF
	LOOP_START
	NOTE D#, 4
	ATTEN 3
	RELEASE $0C, 5
	NOTE D#, 4
	ATTEN 0
	RELEASE 0, 0
	LOOP_END $02
	NOTE E_, 4
	NOTE F_, 4
	VIBRATO $01, 4, 5
	DETUNE $FF
	RELEASE 7, 7
	NOTE F#, 0
	REST 4
	VIBRATO_OFF
	RELEASE 0, 0
	DETUNE $00
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE F#, 1
	SND_LOOP

Snd7D_Ch3:
	SND_SEGNO
	VOICE $07, 14, 2, 0, 0
	VIBRATO $01, 3, 7
	OCTAVE 2
	NOTE F#, 12
	NOTE B_, 12
	OCTAVE 3
	NOTE C_, 12
	VIBRATO $01, 0, 8
	NOTE C_, 12
	VIBRATO $01, 3, 7
	NOTE D_, 12
	VIBRATO $01, 0, 8
	NOTE D_, 12
	VIBRATO $01, 2, 7
	NOTE E_, 8
	NOTE D#, 8
	NOTE C_, 8
	VIBRATO_OFF
	VOICE $07, 1, 2, 0, 0
	LOOP_START
	OCTAVE 2
	NOTE B_, 4
	ATTEN 1
	RELEASE 9, 7
	NOTE B_, 4
	ATTEN 0
	RELEASE 0, 0
	LOOP_END $02
	VIBRATO $07, 0, 5
	OCTAVE 3
	NOTE C_, 4
	VIBRATO $01, 2, 7
	OCTAVE 2
	NOTE A#, 4
	VIBRATO_OFF
	LOOP_START
	OCTAVE 2
	NOTE B_, 4
	ATTEN 1
	RELEASE 9, 7
	NOTE B_, 4
	ATTEN 0
	RELEASE 0, 0
	LOOP_END $02
	VIBRATO $01, 4, 7
	NOTE A#, 8
	VIBRATO_OFF
	LOOP_START
	OCTAVE 2
	NOTE B_, 4
	ATTEN 1
	RELEASE 9, 7
	NOTE B_, 4
	ATTEN 0
	RELEASE 0, 0
	LOOP_END $02
	NOTE B_, 4
	VIBRATO $07, 0, 5
	OCTAVE 3
	NOTE C_, 4
	VIBRATO_OFF
	VIBRATO $01, 4, 7
	RELEASE 7, 7
	OCTAVE 2
	NOTE B_, 0
	REST 4
	VIBRATO_OFF
	RELEASE 0, 0
	WAVE $0E
	OCTAVE 3
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	SND_LOOP

Snd7D_Drm:
	LEN_UNIT $07
	SND_SEGNO
	DRUM_SND $0D, 4
	DRUM_SND $0D, 4
	DRUM $0C, 6
	DRUM $0B, 2
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM $0B, 8
	DRUM_SND $0D, 4
	DRUM_SND $0D, 4
	DRUM $0C, 8
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM_SND $0D, 4
	DRUM_SND $0D, 4
	DRUM $0C, 8
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM_SND $0D, 4
	DRUM_SND $0D, 4
	DRUM $0C, 6
	DRUM $0B, 2
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 2
	DRUM $0B, 4
	DRUM $0B, 4
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 2
	DRUM $0B, 2
	SND_LOOP

Snd7C_Ch2:
	VOICE $06, 12, 10, 15, 1
	OCTAVE 4
	SND_SEGNO
	NOTE F#, 2
	ATTEN 1
	NOTE F#, 2
	ATTEN 2
	NOTE F#, 2
	ATTEN 3
	NOTE F#, 2
	ATTEN 4
	NOTE F#, 2
	ATTEN 5
	NOTE F#, 2
	ATTEN 6
	NOTE F#, 2
	ATTEN 7
	NOTE F#, 2
	VOICE $06, 12, 2, 15, 1
	ATTEN 0
	NOTE F#, 2
	VOICE $06, 12, 10, 15, 1
	ATTEN 7
	NOTE F#, 2
	ATTEN 6
	NOTE F#, 2
	ATTEN 5
	NOTE F#, 2
	ATTEN 4
	NOTE F#, 2
	ATTEN 3
	NOTE F#, 2
	ATTEN 2
	NOTE F#, 2
	ATTEN 1
	NOTE F#, 2
	ATTEN 0
	SND_LOOP

Snd7C_Ch1:
	SND_SEGNO
	VOICE $06, 12, 11, 15, 1
	OCTAVE 4
	ATTEN 0
	NOTE E_, 2
	ATTEN 1
	NOTE E_, 2
	ATTEN 0
	DUTY 0
	RELEASE $0E, 2
	OCTAVE 3
	NOTE C#, 2
	DUTY $0C
	RELEASE $0F, 1
	ATTEN 3
	OCTAVE 4
	NOTE E_, 2
	ATTEN 4
	NOTE E_, 2
	ATTEN 0
	DUTY 0
	RELEASE $0E, 2
	OCTAVE 3
	NOTE C#, 2
	DUTY $0C
	RELEASE $0F, 1
	ATTEN 6
	OCTAVE 4
	NOTE E_, 2
	ATTEN 7
	NOTE E_, 2
	ATTEN 0
	DUTY 0
	RELEASE $0E, 2
	OCTAVE 3
	NOTE C#, 2
	DUTY $0C
	RELEASE $0F, 1
	ATTEN 7
	OCTAVE 4
	NOTE E_, 2
	ATTEN 6
	NOTE E_, 2
	ATTEN 0
	DUTY 0
	RELEASE $0E, 2
	OCTAVE 3
	NOTE C#, 2
	DUTY $0C
	RELEASE $0F, 1
	ATTEN 4
	OCTAVE 4
	NOTE E_, 2
	ATTEN 0
	DUTY 0
	RELEASE $0E, 2
	OCTAVE 3
	NOTE C#, 2
	DUTY $0C
	RELEASE $0F, 1
	ATTEN 2
	OCTAVE 4
	NOTE E_, 2
	ATTEN 0
	DUTY 0
	RELEASE $0E, 2
	OCTAVE 3
	NOTE C#, 2
	DUTY $0C
	RELEASE $0F, 1
	VOICE $06, 12, 11, 15, 1
	OCTAVE 4
	NOTE E_, 2
	ATTEN 1
	NOTE E_, 2
	ATTEN 0
	DUTY 0
	RELEASE $0E, 2
	OCTAVE 3
	NOTE D_, 2
	DUTY $0C
	RELEASE $0F, 1
	ATTEN 3
	OCTAVE 4
	NOTE E_, 2
	ATTEN 4
	NOTE E_, 2
	ATTEN 0
	DUTY 0
	RELEASE $0E, 2
	OCTAVE 3
	NOTE D_, 2
	DUTY $0C
	RELEASE $0F, 1
	ATTEN 6
	OCTAVE 4
	NOTE E_, 2
	ATTEN 7
	NOTE E_, 2
	ATTEN 0
	DUTY 0
	RELEASE $0E, 2
	OCTAVE 3
	NOTE D_, 2
	DUTY $0C
	RELEASE $0F, 1
	ATTEN 7
	OCTAVE 4
	NOTE E_, 2
	ATTEN 6
	NOTE E_, 2
	ATTEN 0
	DUTY 0
	RELEASE $0E, 2
	OCTAVE 3
	NOTE D_, 2
	DUTY $0C
	RELEASE $0F, 1
	ATTEN 4
	OCTAVE 4
	NOTE E_, 2
	ATTEN 0
	DUTY 0
	RELEASE $0E, 2
	OCTAVE 3
	NOTE D_, 2
	DUTY $0C
	RELEASE $0F, 1
	ATTEN 2
	OCTAVE 4
	NOTE E_, 2
	ATTEN 0
	DUTY 0
	RELEASE $0E, 2
	OCTAVE 3
	NOTE D_, 2
	DUTY $0C
	RELEASE $0F, 1
	SND_LOOP

Snd7C_Ch3:
	SND_SEGNO
	VOICE $06, 1, 2, 0, 0
	LOOP_START
	RELEASE 8, 5
	OCTAVE 2
	NOTE B_, 4
	RELEASE 0, 0
	WAVE 7
	RELEASE 8, 3
	NOTE C_HI, 2
	RELEASE 8, 5
	WAVE 1
	LOOP_END $04
	RELEASE 8, 5
	NOTE B_, 2
	RELEASE 0, 0
	WAVE 7
	RELEASE 8, 3
	NOTE C_HI, 2
	RELEASE 8, 5
	WAVE 1
	RELEASE 8, 5
	NOTE B_, 2
	RELEASE 0, 0
	WAVE 7
	RELEASE 8, 3
	NOTE C_HI, 2
	RELEASE 8, 5
	WAVE 1
	LOOP_START
	RELEASE 8, 5
	OCTAVE 3
	NOTE C_, 4
	RELEASE 0, 0
	WAVE 7
	RELEASE 8, 3
	NOTE C_HI, 2
	RELEASE 8, 5
	WAVE 1
	LOOP_END $04
	RELEASE 8, 5
	NOTE C_, 2
	RELEASE 0, 0
	WAVE 7
	RELEASE 8, 3
	NOTE C_HI, 2
	RELEASE 8, 5
	WAVE 1
	RELEASE 8, 5
	NOTE C_, 2
	RELEASE 0, 0
	WAVE 7
	RELEASE 8, 3
	NOTE C_HI, 2
	RELEASE 8, 5
	WAVE 1
	SND_LOOP

Snd7C_Drm:
	LEN_UNIT $06
	SND_SEGNO
	LOOP2_START
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_END $04
	LOOP_BREAK $FC
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 3, 1
	DRUM 8, 1
	LOOP_END $03
	LOOP2_END $02
	DRUM 3, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	SND_LOOP

Snd7E_Ch2:
	VOICE $07, 8, 14, 13, 3
	DUTY_STEP 8, 1
	SND_SEGNO
	TRANSPOSE_DOWN $0C
	LOOP2_START
	LOOP_START
	OCTAVE 3
	NOTE D_, 2
	DUTY 0
	RELEASE $0F, 3
	ATTEN 4
	OCTAVE 4
	NOTE F#, 2
	NOTE F#, 2
	DUTY 8
	RELEASE $0D, 3
	ATTEN 0
	LOOP_END $04
	LOOP_START
	OCTAVE 3
	NOTE D_, 2
	DUTY 0
	RELEASE $0F, 3
	ATTEN 4
	OCTAVE 4
	NOTE F#, 2
	DUTY 8
	RELEASE $0D, 3
	ATTEN 0
	LOOP_END $02
	LOOP_BREAK $FC
	LOOP_START
	OCTAVE 3
	NOTE C_, 2
	DUTY 0
	RELEASE $0F, 3
	ATTEN 4
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 2
	DUTY 8
	RELEASE $0D, 3
	ATTEN 0
	LOOP_END $04
	LOOP_START
	OCTAVE 3
	NOTE E_, 2
	DUTY 0
	RELEASE $0F, 3
	ATTEN 4
	OCTAVE 4
	NOTE A_, 2
	DUTY 8
	RELEASE $0D, 3
	ATTEN 0
	LOOP_END $02
	LOOP2_END $02
	LOOP_START
	OCTAVE 3
	NOTE D#, 2
	DUTY 0
	RELEASE $0F, 3
	ATTEN 4
	OCTAVE 4
	NOTE G_, 2
	NOTE G_, 2
	DUTY 8
	RELEASE $0D, 3
	ATTEN 0
	LOOP_END $04
	LOOP_START
	OCTAVE 3
	NOTE C_, 2
	DUTY 0
	RELEASE $0F, 3
	ATTEN 4
	OCTAVE 4
	NOTE E_, 2
	DUTY 8
	RELEASE $0D, 3
	ATTEN 0
	LOOP_END $02
	SND_LOOP

Snd7E_Ch1:
	VOICE $07, 8, 14, 14, 3
	DUTY_STEP 8, 1
	SND_SEGNO
	LOOP2_START
	LOOP_START
	DUTY 8
	ATTEN 0
	OCTAVE 2
	NOTE A_, 2
	DUTY 0
	ATTEN 4
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	LOOP_END $05
	NOTE E_, 2
	LOOP_START
	DUTY 8
	ATTEN 0
	OCTAVE 2
	NOTE G_, 2
	DUTY 0
	ATTEN 4
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 2
	LOOP_END $04
	LOOP_BREAK $FC
	DUTY 8
	ATTEN 0
	OCTAVE 3
	NOTE C_, 2
	DUTY 0
	ATTEN 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LOOP2_END $02
	LOOP_START
	DUTY 8
	ATTEN 0
	OCTAVE 2
	NOTE G_, 2
	DUTY 0
	ATTEN 4
	OCTAVE 3
	NOTE D_, 2
	LOOP_END $02
	SND_LOOP

Snd7E_Ch3:
	VOICE $07, 12, 2, 12, 5
	SND_SEGNO
	LOOP_START
	PAN_LEFT 0
	WAVE 9
	OCTAVE 4
	NOTE F#, 2
	PAN_BOTH 0
	WAVE 4
	NOTE A_, 2
	NOTE A_, 2
	PAN_RIGHT 0
	WAVE 9
	OCTAVE 5
	NOTE F#, 2
	PAN_BOTH 0
	WAVE 4
	OCTAVE 4
	NOTE A_, 2
	NOTE A_, 2
	PAN_LEFT 0
	WAVE 9
	OCTAVE 6
	NOTE F#, 2
	PAN_BOTH 0
	WAVE 4
	OCTAVE 4
	NOTE A_, 2
	NOTE A_, 2
	PAN_RIGHT 0
	WAVE 9
	OCTAVE 5
	NOTE F#, 2
	PAN_BOTH 0
	WAVE 4
	OCTAVE 4
	NOTE A_, 2
	NOTE A_, 2
	PAN_LEFT 0
	WAVE 9
	OCTAVE 4
	NOTE F#, 2
	PAN_BOTH 0
	WAVE 4
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	LOOP_BREAK $FB
	PAN_LEFT 0
	WAVE 9
	OCTAVE 4
	NOTE E_, 2
	PAN_BOTH 0
	WAVE 4
	NOTE G_, 2
	NOTE G_, 2
	PAN_RIGHT 0
	WAVE 9
	OCTAVE 5
	NOTE E_, 2
	PAN_BOTH 0
	WAVE 4
	OCTAVE 4
	NOTE G_, 2
	NOTE G_, 2
	PAN_LEFT 0
	WAVE 9
	OCTAVE 6
	NOTE E_, 2
	PAN_BOTH 0
	WAVE 4
	OCTAVE 4
	NOTE G_, 2
	NOTE G_, 2
	PAN_RIGHT 0
	WAVE 9
	OCTAVE 5
	NOTE E_, 2
	PAN_BOTH 0
	WAVE 4
	OCTAVE 4
	NOTE G_, 2
	NOTE G_, 2
	PAN_LEFT 0
	WAVE 9
	OCTAVE 4
	NOTE E_, 2
	PAN_BOTH 0
	WAVE 4
	OCTAVE 5
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	LOOP_END $02
	PAN_LEFT 0
	WAVE 9
	OCTAVE 4
	NOTE D#, 2
	PAN_BOTH 0
	WAVE 4
	NOTE A#, 2
	NOTE A#, 2
	PAN_RIGHT 0
	WAVE 9
	OCTAVE 5
	NOTE D#, 2
	PAN_BOTH 0
	WAVE 4
	OCTAVE 4
	NOTE A#, 2
	NOTE A#, 2
	PAN_LEFT 0
	WAVE 9
	OCTAVE 6
	NOTE D#, 2
	PAN_BOTH 0
	WAVE 4
	OCTAVE 4
	NOTE A#, 2
	NOTE A#, 2
	PAN_RIGHT 0
	WAVE 9
	OCTAVE 5
	NOTE D#, 2
	PAN_BOTH 0
	WAVE 4
	OCTAVE 4
	NOTE A_, 2
	NOTE A_, 2
	PAN_LEFT 0
	WAVE 9
	OCTAVE 4
	NOTE E_, 2
	PAN_BOTH 0
	WAVE 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	SND_LOOP

Snd7E_Drm:
	SND_SEGNO
	LEN_UNIT $07
	SND_CALL Snd7E_Drm_74BD
	SND_LOOP

Snd7F_Ch2:
	VOICE $06, 0, 11, 15, 1
	SND_SEGNO
	LOOP_START
	OCTAVE 3
	NOTE A_, 2
	LOOP_END $10
	LOOP_START
	NOTE G_, 2
	LOOP_END $0C
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	LOOP_START
	OCTAVE 3
	NOTE A_, 2
	LOOP_END $10
	LOOP_START
	NOTE A#, 2
	LOOP_END $09
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	SND_LOOP

Snd7F_Ch1:
	VOICE $06, 0, 11, 15, 1
	DUTY_STEP 8, 1
	SND_SEGNO
	LOOP2_START
	LOOP_START
	OCTAVE 3
	NOTE E_, 2
	LOOP_END $10
	LOOP_START
	NOTE D_, 2
	LOOP_END $0C
	LOOP_BREAK $FC
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LOOP2_END $02
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	SND_LOOP

Snd7F_Ch3:
	VOICE $06, 9, 2, 13, 3
	SND_SEGNO
	LOOP2_START
	LOOP_START
	OCTAVE 3
	NOTE D_, 2
	WAVE $0C
	RELEASE $0F, 3
	OCTAVE 4
	NOTE F#, 2
	NOTE F#, 2
	WAVE 9
	RELEASE $0D, 3
	LOOP_END $04
	LOOP_START
	OCTAVE 3
	NOTE D_, 2
	WAVE $0C
	RELEASE $0F, 3
	OCTAVE 4
	NOTE F#, 2
	WAVE 9
	RELEASE $0D, 3
	LOOP_END $02
	LOOP_BREAK $FC
	LOOP_START
	OCTAVE 3
	NOTE C_, 2
	WAVE $0C
	RELEASE $0F, 3
	OCTAVE 4
	NOTE E_, 2
	NOTE E_, 2
	WAVE 9
	RELEASE $0D, 3
	LOOP_END $04
	LOOP_START
	OCTAVE 3
	NOTE E_, 2
	WAVE $0C
	RELEASE $0F, 3
	OCTAVE 4
	NOTE A_, 2
	WAVE 9
	RELEASE $0D, 3
	LOOP_END $02
	LOOP2_END $02
	LOOP_START
	OCTAVE 3
	NOTE D#, 2
	WAVE $0C
	RELEASE $0F, 3
	OCTAVE 4
	NOTE G_, 2
	NOTE G_, 2
	WAVE 9
	RELEASE $0D, 3
	LOOP_END $04
	LOOP_START
	OCTAVE 3
	NOTE C_, 2
	WAVE $0C
	RELEASE $0F, 3
	OCTAVE 4
	NOTE E_, 2
	WAVE 9
	RELEASE $0D, 3
	LOOP_END $02
	SND_LOOP

Snd7F_Drm:
	SND_SEGNO
	LEN_UNIT $06
	SND_CALL Snd7E_Drm_74BD
	SND_LOOP
Snd7E_Drm_74BD:
	LOOP2_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM $0C, 2
	DRUM 7, 1
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
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_BREAK $FC
	DRUM 7, 1
	DRUM 8, 1
	DRUM $0C, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_BREAK $FB
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP2_END $02
	DRUM 9, 1
	DRUM 8, 1
	DRUM $0C, 2
	DRUM 7, 1
	DRUM 8, 1
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
	DRUM $0C, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	SND_RET

Snd80_Ch2:
	VOICE $05, 8, 15, 14, 3
	OCTAVE 2
	ATTEN 8
	NOTE F#, 2
	ATTEN 7
	NOTE F#, 2
	ATTEN 5
	NOTE F#, 2
	ATTEN 4
	NOTE F#, 2
	ATTEN 2
	NOTE F#, 2
	ATTEN 1
	NOTE F#, 2
	ATTEN 0
	NOTE F#, 2
	SND_SEGNO
	VOICE $05, 8, 15, 14, 3
	LOOP2_START
	LOOP_START
	RELEASE 0, 0
	OCTAVE 2
	NOTE C#, 2
	RELEASE 8, 0
	NOTE C_HI, 1
	RELEASE $0F, 1
	NOTE C_HI, 1
	LOOP_END $08
	LOOP_START
	RELEASE 0, 0
	OCTAVE 1
	NOTE B_, 2
	RELEASE 8, 0
	NOTE C_HI, 1
	RELEASE $0F, 1
	NOTE C_HI, 1
	LOOP_END $08
	LOOP_START
	RELEASE 0, 0
	OCTAVE 1
	NOTE F#, 2
	RELEASE 8, 0
	OCTAVE 2
	NOTE A_, 1
	RELEASE $0F, 1
	NOTE A_, 1
	LOOP_END $08
	LOOP_START
	RELEASE 0, 0
	OCTAVE 1
	NOTE G#, 2
	RELEASE 8, 0
	NOTE C_HI, 1
	RELEASE $0F, 1
	NOTE C_HI, 1
	LOOP_END $08
	LOOP2_END $02
	VOICE $05, 8, 12, 11, 2
	PAN_LEFT 0
	OCTAVE 4
	NOTE C#, 2
	LOOP_START
	PAN_RIGHT 0
	NOTE C#, 2
	DUTY_STEP 8, 1
	DUTY 0
	PAN_BOTH 0
	OCTAVE 3
	NOTE C#, 2
	PAN_LEFT 0
	OCTAVE 4
	DUTY_STEP 0, 0
	DUTY 8
	NOTE C#, 2
	PAN_BOTH 0
	DUTY_STEP 8, 1
	DUTY 0
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 4
	PAN_RIGHT 0
	DUTY_STEP 0, 0
	DUTY 8
	NOTE C#, 2
	PAN_BOTH 0
	DUTY_STEP 8, 1
	DUTY 0
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	PAN_LEFT 0
	DUTY_STEP 0, 0
	DUTY 8
	NOTE C#, 2
	PAN_BOTH 0
	DUTY_STEP 8, 1
	DUTY 0
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 4
	PAN_RIGHT 0
	DUTY_STEP 0, 0
	DUTY 8
	NOTE C#, 2
	PAN_LEFT 0
	NOTE C#, 2
	PAN_BOTH 0
	DUTY_STEP 8, 1
	DUTY 0
	OCTAVE 3
	NOTE C#, 2
	RELEASE 0, 0
	VIBRATO $01, 3, 2
	DUTY 8
	ATTEN 4
	OCTAVE 4
	NOTE G#, 4
	NOTE F#, 4
	VIBRATO_OFF
	RELEASE $0B, 2
	OCTAVE 4
	PAN_LEFT 0
	DUTY_STEP 0, 0
	ATTEN 0
	NOTE E_, 2
	PAN_RIGHT 0
	NOTE E_, 2
	PAN_BOTH 0
	DUTY_STEP 8, 1
	DUTY 0
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 4
	PAN_LEFT 0
	DUTY_STEP 0, 0
	DUTY 8
	NOTE E_, 2
	PAN_BOTH 0
	DUTY_STEP 8, 1
	DUTY 0
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 4
	PAN_RIGHT 0
	DUTY_STEP 0, 0
	DUTY 8
	NOTE E_, 2
	PAN_BOTH 0
	DUTY_STEP 8, 1
	DUTY 0
	OCTAVE 3
	NOTE G#, 2
	OCTAVE 4
	PAN_LEFT 0
	DUTY_STEP 0, 0
	DUTY 8
	NOTE D#, 2
	PAN_BOTH 0
	DUTY_STEP 8, 1
	DUTY 0
	OCTAVE 3
	NOTE F#, 2
	OCTAVE 4
	PAN_RIGHT 0
	DUTY_STEP 0, 0
	DUTY 8
	NOTE D#, 2
	PAN_LEFT 0
	NOTE D#, 2
	PAN_BOTH 0
	DUTY_STEP 8, 1
	DUTY 0
	OCTAVE 3
	NOTE G#, 2
	OCTAVE 4
	PAN_RIGHT 0
	DUTY_STEP 0, 0
	DUTY 8
	NOTE D#, 2
	RELEASE 0, 0
	PAN_BOTH 0
	ATTEN 4
	NOTE D#, 2
	RELEASE $0E, 1
	NOTE E_, 2
	NOTE F#, 2
	RELEASE 0, 0
	VIBRATO $04, 0, 1
	NOTE G#, 4
	VIBRATO $01, 0, 2
	NOTE G#, 4
	VIBRATO $01, 2, 2
	LOOP_BREAK $FB
	NOTE F#, 8
	NOTE E_, 8
	NOTE D#, 6
	VIBRATO $0D, 0, 1
	NOTE D#, 2
	VIBRATO_OFF
	NOTE E_, 2
	RELEASE $0F, 1
	NOTE C#, 2
	ATTEN 0
	RELEASE $0E, 2
	PAN_LEFT 0
	DUTY_STEP 0, 0
	NOTE C_HI, 2
	ATTEN 4
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	ATTEN 0
	RELEASE $0E, 2
	PAN_RIGHT 0
	DUTY_STEP 0, 0
	NOTE C_HI, 2
	PAN_BOTH 0
	ATTEN 4
	RELEASE 0, 0
	NOTE E_, 2
	RELEASE $0F, 1
	NOTE C#, 2
	ATTEN 0
	RELEASE $0E, 2
	PAN_LEFT 0
	DUTY_STEP 0, 0
	NOTE C_HI, 2
	ATTEN 4
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	RELEASE $0E, 2
	ATTEN 0
	PAN_RIGHT 0
	DUTY_STEP 0, 0
	NOTE C_HI, 2
	PAN_BOTH 0
	DUTY_STEP 8, 1
	DUTY 0
	RELEASE $0B, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C#, 2
	DUTY_STEP 0, 0
	DUTY 8
	OCTAVE 4
	LOOP_END $02
	NOTE A_, 8
	OCTAVE 5
	NOTE C_, 8
	NOTE C#, 6
	VIBRATO $0D, 0, 1
	NOTE C#, 2
	VIBRATO_OFF
	VIBRATO $01, 2, 2
	NOTE D#, 4
	NOTE C#, 4
	NOTE C_, 4
	OCTAVE 4
	NOTE A_, 4
	NOTE G#, 10
	VIBRATO_OFF
	NOTE F#, 2
	RELEASE $0B, 1
	NOTE E_, 2
	NOTE D_, 2
	ATTEN 0
	VOICE $05, 8, 8, 11, 1
	LOOP_START
	DUTY 8
	PAN_BOTH 0
	OCTAVE 4
	NOTE C#, 2
	DUTY 0
	AUTOPAN 0
	NOTE C#, 2
	NOTE C_HI, 2
	LOOP_END $02
	DUTY 8
	PAN_BOTH 0
	OCTAVE 3
	NOTE B_, 2
	AUTOPAN 0
	DUTY 0
	OCTAVE 4
	NOTE C#, 2
	NOTE C_HI, 2
	PAN_BOTH 0
	DUTY 8
	RELEASE 4, 1
	VIBRATO $01, 2, 3
	OCTAVE 3
	NOTE B_, 6
	RELEASE 6, 1
	NOTE B_, 4
	NOTE B_, 4
	VIBRATO_OFF
	RELEASE $0B, 1
	LOOP_START
	DUTY 8
	PAN_BOTH 0
	OCTAVE 4
	NOTE E_, 2
	DUTY 0
	AUTOPAN 0
	NOTE C#, 2
	NOTE C_HI, 2
	LOOP_END $02
	DUTY 8
	PAN_BOTH 0
	NOTE D_, 2
	AUTOPAN 0
	DUTY 0
	NOTE C#, 2
	NOTE C_HI, 2
	PAN_BOTH 0
	DUTY 8
	RELEASE 4, 1
	VIBRATO $01, 2, 3
	NOTE D_, 6
	RELEASE 6, 1
	NOTE D_, 4
	NOTE D_, 4
	VIBRATO_OFF
	RELEASE $0B, 1
	LOOP_START
	DUTY 8
	PAN_BOTH 0
	OCTAVE 4
	NOTE G#, 2
	DUTY 0
	AUTOPAN 0
	NOTE C#, 2
	NOTE C_HI, 2
	LOOP_END $02
	DUTY 8
	PAN_BOTH 0
	NOTE F#, 2
	AUTOPAN 0
	DUTY 0
	NOTE C#, 2
	NOTE C_HI, 2
	PAN_BOTH 0
	DUTY 8
	RELEASE 4, 1
	VIBRATO $01, 2, 3
	NOTE F#, 6
	RELEASE $0A, 1
	VIBRATO_OFF
	OCTAVE 5
	NOTE C#, 4
	OCTAVE 4
	NOTE B_, 4
	RELEASE 0, 0
	VIBRATO $01, 2, 2
	OCTAVE 5
	ATTEN 4
	ENVELOPE $06
	NOTE C#, 8
	OCTAVE 4
	NOTE G#, 8
	NOTE A_, 8
	NOTE D_, 8
	VIBRATO_OFF
	RELEASE $0B, 1
	ENVELOPE $00
	ATTEN 0
	LOOP_START
	DUTY 8
	PAN_BOTH 0
	OCTAVE 4
	NOTE C#, 2
	DUTY 0
	AUTOPAN 0
	NOTE C#, 2
	NOTE C_HI, 2
	LOOP_END $02
	DUTY 8
	PAN_BOTH 0
	OCTAVE 3
	NOTE B_, 2
	AUTOPAN 0
	DUTY 0
	OCTAVE 4
	NOTE C#, 2
	NOTE C_HI, 2
	PAN_BOTH 0
	DUTY 8
	RELEASE 4, 1
	VIBRATO $01, 2, 3
	OCTAVE 3
	NOTE B_, 6
	RELEASE 6, 1
	NOTE B_, 4
	OCTAVE 4
	NOTE D_, 4
	VIBRATO_OFF
	RELEASE $0B, 1
	NOTE C#, 2
	REST 6
	OCTAVE 3
	RELEASE 0, 0
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	REST 2
	RELEASE $0B, 1
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	RELEASE 0, 0
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	OCTAVE 5
	NOTE C_, 1
	SND_LOOP

Snd80_Ch1:
	VOICE $05, 8, 12, 14, 3
	OCTAVE 4
	ATTEN 8
	NOTE G#, 2
	ATTEN 7
	NOTE G#, 2
	ATTEN 5
	NOTE G#, 2
	ATTEN 4
	NOTE G#, 2
	ATTEN 2
	NOTE G#, 2
	ATTEN 1
	NOTE G#, 2
	ATTEN 0
	NOTE G#, 2
	SND_SEGNO
	LOOP2_START
	LOOP_START
	VOICE $05, 8, 9, 11, 2
	DUTY 8
	OCTAVE 4
	NOTE E_, 2
	DUTY 0
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	DUTY 8
	OCTAVE 4
	NOTE C#, 2
	DUTY 0
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	DUTY 8
	NOTE B_, 2
	DUTY 0
	NOTE E_, 2
	NOTE E_, 2
	DUTY 8
	OCTAVE 4
	NOTE C#, 2
	DUTY 0
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	DUTY 8
	NOTE B_, 2
	DUTY 0
	NOTE E_, 2
	DUTY 8
	OCTAVE 4
	NOTE C#, 2
	DUTY 0
	OCTAVE 3
	NOTE E_, 2
	LOOP_BREAK $FB
	DUTY 8
	NOTE B_, 2
	DUTY 0
	NOTE E_, 2
	NOTE E_, 2
	DUTY 8
	NOTE F#, 2
	DUTY 0
	NOTE E_, 2
	NOTE E_, 2
	DUTY 8
	NOTE F#, 2
	DUTY 0
	NOTE E_, 2
	DUTY 8
	RELEASE 0, 0
	VIBRATO $01, 2, 4
	OCTAVE 4
	ATTEN 2
	NOTE G#, 8
	NOTE F#, 8
	ATTEN 0
	VIBRATO_OFF
	LOOP_END $02
	DUTY 8
	OCTAVE 4
	NOTE D#, 2
	DUTY 0
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	DUTY 8
	OCTAVE 4
	NOTE C#, 2
	DUTY 0
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	DUTY 8
	OCTAVE 4
	NOTE C_, 2
	DUTY 0
	OCTAVE 3
	NOTE E_, 2
	LOOP_BREAK $FC
	VOICE $05, 8, 15, 0, 0
	LOOP_START
	OCTAVE 2
	NOTE D#, 2
	RELEASE $0F, 2
	OCTAVE 3
	NOTE C_, 2
	LOOP_END $04
	LOOP2_END $02
	RELEASE 0, 0
	DUTY 8
	VIBRATO $01, 2, 2
	OCTAVE 5
	NOTE E_, 8
	NOTE D#, 8
	VIBRATO_OFF
	VOICE $05, 8, 12, 11, 1
	PAN_LEFT 0
	OCTAVE 3
	NOTE G#, 2
	LOOP_START
	PAN_RIGHT 0
	NOTE G#, 2
	DUTY_STEP 8, 1
	DUTY 0
	PAN_BOTH 0
	OCTAVE 2
	NOTE A_, 2
	PAN_LEFT 0
	DUTY_STEP 0, 0
	DUTY 8
	OCTAVE 3
	NOTE G#, 2
	PAN_BOTH 0
	DUTY_STEP 8, 1
	DUTY 0
	OCTAVE 2
	NOTE B_, 2
	PAN_RIGHT 0
	DUTY_STEP 0, 0
	DUTY 8
	OCTAVE 3
	NOTE G#, 2
	PAN_BOTH 0
	DUTY_STEP 8, 1
	DUTY 0
	OCTAVE 3
	NOTE C#, 2
	PAN_LEFT 0
	DUTY_STEP 0, 0
	DUTY 8
	NOTE G#, 2
	PAN_BOTH 0
	DUTY_STEP 8, 1
	DUTY 0
	OCTAVE 2
	NOTE B_, 2
	PAN_RIGHT 0
	DUTY_STEP 0, 0
	DUTY 8
	OCTAVE 3
	NOTE G#, 2
	PAN_LEFT 0
	NOTE G#, 2
	PAN_BOTH 0
	DUTY_STEP 8, 1
	DUTY 0
	OCTAVE 2
	NOTE A_, 2
	RELEASE 0, 0
	VIBRATO $01, 0, 2
	DUTY 8
	ATTEN 2
	OCTAVE 4
	NOTE C#, 2
	VIBRATO_OFF
	RELEASE $0B, 1
	OCTAVE 3
	NOTE D#, 2
	NOTE E_, 2
	NOTE F#, 2
	OCTAVE 4
	PAN_LEFT 0
	DUTY_STEP 0, 0
	ATTEN 0
	OCTAVE 4
	NOTE C_, 2
	PAN_RIGHT 0
	NOTE C_, 2
	PAN_BOTH 0
	DUTY_STEP 8, 1
	DUTY 0
	OCTAVE 3
	NOTE C_, 2
	PAN_LEFT 0
	DUTY_STEP 0, 0
	DUTY 8
	OCTAVE 4
	NOTE C_, 2
	PAN_BOTH 0
	DUTY_STEP 8, 1
	DUTY 0
	OCTAVE 3
	NOTE D#, 2
	PAN_RIGHT 0
	DUTY_STEP 0, 0
	DUTY 8
	OCTAVE 4
	NOTE C_, 2
	PAN_BOTH 0
	DUTY_STEP 8, 1
	DUTY 0
	OCTAVE 3
	NOTE D#, 2
	PAN_LEFT 0
	DUTY_STEP 0, 0
	DUTY 8
	OCTAVE 4
	NOTE C_, 2
	PAN_BOTH 0
	DUTY_STEP 8, 1
	DUTY 0
	OCTAVE 3
	NOTE D#, 2
	PAN_RIGHT 0
	DUTY_STEP 0, 0
	DUTY 8
	OCTAVE 4
	NOTE C_, 2
	PAN_LEFT 0
	NOTE C_, 2
	PAN_BOTH 0
	DUTY_STEP 8, 1
	DUTY 0
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 4
	PAN_RIGHT 0
	DUTY_STEP 0, 0
	DUTY 8
	OCTAVE 4
	NOTE C_, 2
	RELEASE 0, 0
	PAN_BOTH 0
	ATTEN 2
	OCTAVE 3
	NOTE G#, 2
	RELEASE $0E, 1
	NOTE F#, 2
	NOTE D#, 2
	LOOP_BREAK $FB
	REST 2
	RELEASE $0B, 1
	NOTE C#, 2
	RELEASE 0, 0
	NOTE G#, 2
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE C#, 2
	VIBRATO_OFF
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	OCTAVE 3
	NOTE B_, 2
	RELEASE $0B, 1
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE C#, 2
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	OCTAVE 3
	NOTE C#, 2
	NOTE D#, 4
	NOTE E_, 4
	NOTE F#, 4
	VIBRATO_OFF
	NOTE G#, 2
	RELEASE $0F, 1
	NOTE D#, 2
	ATTEN 0
	RELEASE $0E, 2
	PAN_LEFT 0
	OCTAVE 4
	NOTE G#, 2
	ATTEN 2
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE D#, 2
	RELEASE $0F, 1
	NOTE E_, 2
	ATTEN 0
	RELEASE $0E, 2
	PAN_RIGHT 0
	OCTAVE 4
	NOTE G#, 2
	PAN_BOTH 0
	ATTEN 2
	RELEASE 0, 0
	OCTAVE 3
	NOTE G#, 2
	RELEASE $0F, 1
	NOTE D#, 2
	ATTEN 0
	RELEASE $0E, 2
	PAN_LEFT 0
	OCTAVE 4
	NOTE G#, 2
	ATTEN 2
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE D#, 2
	RELEASE $0F, 1
	NOTE E_, 2
	RELEASE $0E, 2
	ATTEN 0
	PAN_RIGHT 0
	OCTAVE 4
	NOTE G#, 2
	PAN_BOTH 0
	DUTY_STEP 8, 1
	DUTY 0
	RELEASE $0B, 2
	OCTAVE 3
	NOTE G#, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	DUTY_STEP 0, 0
	DUTY 8
	OCTAVE 4
	LOOP_END $02
	DUTY 0
	DUTY_STEP 4, 1
	ATTEN 3
	RELEASE 0, 0
	OCTAVE 3
	NOTE E_, 2
	RELEASE $0F, 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	RELEASE 0, 0
	NOTE E_, 2
	RELEASE $0F, 2
	OCTAVE 4
	NOTE F#, 2
	NOTE F#, 2
	RELEASE 0, 0
	OCTAVE 3
	NOTE E_, 2
	RELEASE $0F, 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	RELEASE 0, 0
	OCTAVE 3
	NOTE E_, 2
	RELEASE $0F, 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	RELEASE 0, 0
	OCTAVE 3
	NOTE F#, 2
	RELEASE $0F, 2
	NOTE C_HI, 2
	NOTE C_HI, 2
	RELEASE 0, 0
	NOTE F#, 2
	OCTAVE 4
	VIBRATO $01, 2, 2
	NOTE C_, 4
	OCTAVE 3
	NOTE A#, 4
	RELEASE $0F, 1
	NOTE A_, 2
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE D#, 2
	VIBRATO_OFF
	NOTE E_, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE G#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE A_, 2
	RELEASE $0B, 1
	NOTE G_, 2
	NOTE F#, 2
	VOICE $05, 8, 10, 11, 1
	LOOP_START
	DETUNE $00
	DUTY 8
	PAN_BOTH 0
	OCTAVE 3
	NOTE E_, 2
	DETUNE $FF
	ATTEN 3
	DUTY 0
	AUTOPAN 0
	OCTAVE 4
	NOTE C#, 2
	NOTE C_HI, 2
	ATTEN 0
	LOOP_END $02
	DETUNE $00
	DUTY 8
	PAN_BOTH 0
	OCTAVE 3
	NOTE F#, 2
	DETUNE $FF
	AUTOPAN 0
	DUTY 0
	OCTAVE 4
	NOTE C#, 2
	NOTE C_HI, 2
	DETUNE $00
	PAN_BOTH 0
	DUTY 8
	OCTAVE 3
	RELEASE 4, 1
	VIBRATO $01, 2, 3
	NOTE F#, 6
	RELEASE 6, 1
	NOTE F#, 4
	NOTE F#, 4
	VIBRATO_OFF
	RELEASE $0B, 1
	LOOP_START
	DETUNE $00
	DUTY 8
	PAN_BOTH 0
	OCTAVE 3
	NOTE G#, 2
	DETUNE $FF
	ATTEN 3
	DUTY 0
	AUTOPAN 0
	OCTAVE 4
	NOTE C#, 2
	NOTE C_HI, 2
	ATTEN 0
	LOOP_END $02
	DETUNE $00
	DUTY 8
	PAN_BOTH 0
	OCTAVE 3
	NOTE F#, 2
	DETUNE $FF
	AUTOPAN 0
	DUTY 0
	OCTAVE 4
	NOTE C#, 2
	NOTE C_HI, 2
	DETUNE $00
	PAN_BOTH 0
	DUTY 8
	OCTAVE 3
	RELEASE 4, 1
	VIBRATO $01, 2, 3
	NOTE F#, 6
	RELEASE 6, 1
	NOTE F#, 4
	NOTE F#, 4
	VIBRATO_OFF
	RELEASE $0B, 1
	LOOP_START
	DETUNE $00
	DUTY 8
	PAN_BOTH 0
	OCTAVE 3
	NOTE E_, 2
	DETUNE $FF
	ATTEN 3
	DUTY 0
	AUTOPAN 0
	OCTAVE 4
	NOTE C#, 2
	NOTE C_HI, 2
	ATTEN 0
	LOOP_END $02
	DETUNE $00
	DUTY 8
	PAN_BOTH 0
	OCTAVE 3
	NOTE B_, 2
	DETUNE $FF
	AUTOPAN 0
	DUTY 0
	OCTAVE 4
	NOTE C#, 2
	NOTE C_HI, 2
	DETUNE $00
	PAN_BOTH 0
	DUTY 8
	OCTAVE 3
	RELEASE 4, 1
	VIBRATO $01, 2, 3
	NOTE B_, 6
	RELEASE $0A, 1
	VIBRATO_OFF
	OCTAVE 4
	NOTE E_, 4
	NOTE D_, 4
	RELEASE 0, 0
	VIBRATO $01, 2, 2
	OCTAVE 4
	ATTEN 4
	ENVELOPE $06
	NOTE E_, 8
	NOTE C#, 8
	NOTE D_, 8
	OCTAVE 3
	NOTE A_, 8
	VIBRATO_OFF
	RELEASE $0B, 1
	ENVELOPE $00
	ATTEN 0
	LOOP_START
	DETUNE $00
	DUTY 8
	PAN_BOTH 0
	OCTAVE 3
	NOTE E_, 2
	DETUNE $FF
	ATTEN 3
	DUTY 0
	AUTOPAN 0
	OCTAVE 4
	NOTE C#, 2
	NOTE C_HI, 2
	ATTEN 0
	LOOP_END $02
	DETUNE $00
	DUTY 8
	PAN_BOTH 0
	OCTAVE 3
	NOTE F#, 2
	DETUNE $FF
	AUTOPAN 0
	DUTY 0
	OCTAVE 4
	NOTE C#, 2
	NOTE C_HI, 2
	DETUNE $00
	PAN_BOTH 0
	DUTY 8
	OCTAVE 3
	RELEASE 4, 1
	VIBRATO $01, 2, 3
	NOTE F#, 6
	RELEASE 6, 1
	NOTE F#, 4
	NOTE F#, 4
	VIBRATO_OFF
	RELEASE $0B, 1
	RELEASE $0B, 1
	NOTE E_, 2
	REST 8
	OCTAVE 3
	ATTEN 5
	RELEASE 0, 0
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	ATTEN 0
	RELEASE $0B, 1
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE E_, 2
	RELEASE 0, 0
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE C_, 1
	SND_LOOP

Snd80_Ch3:
	VOICE $05, 0, 2, 14, 3
	OCTAVE 6
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	SND_SEGNO
	LOOP2_START
	LOOP_START
	WAVE 0
	RELEASE $0B, 3
	OCTAVE 6
	NOTE C#, 2
	WAVE 8
	OCTAVE 4
	NOTE G#, 2
	NOTE G#, 2
	WAVE 0
	OCTAVE 5
	NOTE B_, 2
	WAVE 8
	OCTAVE 4
	NOTE G#, 2
	NOTE G#, 2
	WAVE 0
	OCTAVE 5
	NOTE G#, 2
	WAVE 8
	OCTAVE 4
	NOTE G#, 2
	NOTE G#, 2
	WAVE 0
	OCTAVE 5
	NOTE F#, 2
	WAVE 8
	OCTAVE 4
	NOTE G#, 2
	NOTE G#, 2
	WAVE 0
	OCTAVE 5
	NOTE E_, 2
	WAVE 8
	OCTAVE 4
	NOTE G#, 2
	WAVE 0
	OCTAVE 5
	NOTE F#, 2
	WAVE 8
	OCTAVE 4
	NOTE G#, 2
	LOOP_BREAK $FB
	WAVE 0
	OCTAVE 5
	NOTE E_, 2
	WAVE 8
	OCTAVE 4
	NOTE G#, 2
	NOTE G#, 2
	WAVE 0
	OCTAVE 4
	NOTE B_, 2
	WAVE 8
	OCTAVE 4
	NOTE G#, 2
	NOTE G#, 2
	WAVE 0
	OCTAVE 5
	NOTE C#, 2
	WAVE 8
	OCTAVE 4
	NOTE G#, 2
	RELEASE $0E, 2
	WAVE 3
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE G#, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE E_, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE B_, 1
	LOOP_END $02
	WAVE 0
	RELEASE $0B, 3
	OCTAVE 5
	NOTE G#, 2
	WAVE 8
	OCTAVE 4
	NOTE G#, 2
	NOTE G#, 2
	WAVE 0
	OCTAVE 5
	NOTE F#, 2
	WAVE 8
	OCTAVE 4
	NOTE G#, 2
	NOTE G#, 2
	WAVE 0
	OCTAVE 5
	NOTE E_, 2
	WAVE 8
	OCTAVE 4
	NOTE G#, 2
	LOOP_BREAK $FC
	RELEASE $0E, 2
	WAVE 3
	OCTAVE 6
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 5
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	LOOP2_END $02
	RELEASE $0E, 2
	WAVE 3
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 6
	NOTE C_, 1
	TRANSPOSE_UP $0C
	WAVE 1
	LOOP_START
	RELEASE 0, 0
	OCTAVE 1
	NOTE A_, 2
	RELEASE 8, 0
	OCTAVE 2
	NOTE E_, 1
	RELEASE $0F, 1
	NOTE E_, 1
	LOOP_END $08
	LOOP_START
	RELEASE 0, 0
	NOTE C_, 2
	RELEASE 8, 0
	NOTE G#, 1
	RELEASE $0F, 1
	NOTE G#, 1
	LOOP_END $08
	LOOP_START
	RELEASE 0, 0
	NOTE C#, 2
	RELEASE 8, 0
	NOTE G#, 1
	RELEASE $0F, 1
	NOTE G#, 1
	LOOP_END $08
	LOOP_START
	RELEASE 0, 0
	OCTAVE 1
	NOTE B_, 2
	RELEASE 8, 0
	OCTAVE 2
	NOTE G#, 1
	RELEASE $0F, 1
	NOTE G#, 1
	LOOP_END $04
	LOOP_START
	RELEASE 0, 0
	OCTAVE 1
	NOTE A#, 2
	RELEASE 8, 0
	OCTAVE 2
	NOTE G#, 1
	RELEASE $0F, 1
	NOTE G#, 1
	LOOP_END $04
	LOOP_START
	RELEASE 0, 0
	OCTAVE 1
	NOTE A_, 2
	RELEASE 8, 0
	OCTAVE 2
	NOTE E_, 1
	RELEASE $0F, 1
	NOTE E_, 1
	LOOP_END $08
	LOOP_START
	RELEASE 0, 0
	OCTAVE 1
	NOTE G#, 2
	RELEASE 8, 0
	OCTAVE 2
	NOTE E_, 1
	RELEASE $0F, 1
	NOTE E_, 1
	LOOP_END $04
	LOOP_START
	RELEASE 0, 0
	NOTE C_, 2
	RELEASE 8, 0
	NOTE G#, 1
	RELEASE $0F, 1
	NOTE G#, 1
	LOOP_END $04
	LOOP_START
	RELEASE 0, 0
	NOTE C#, 2
	RELEASE 8, 0
	NOTE G#, 1
	RELEASE $0F, 1
	NOTE G#, 1
	LOOP_END $04
	LOOP_START
	RELEASE 0, 0
	NOTE C_, 2
	RELEASE 8, 0
	NOTE G#, 1
	RELEASE $0F, 1
	NOTE G#, 1
	LOOP_END $02
	LOOP_START
	RELEASE 0, 0
	OCTAVE 1
	NOTE A_, 2
	RELEASE 8, 0
	OCTAVE 2
	NOTE F#, 1
	RELEASE $0F, 1
	NOTE F#, 1
	LOOP_END $02
	RELEASE 0, 0
	OCTAVE 1
	NOTE G#, 2
	RELEASE 8, 0
	NOTE C_HI, 1
	RELEASE $0F, 1
	NOTE C_HI, 1
	RELEASE 0, 0
	NOTE A#, 2
	RELEASE 8, 0
	NOTE C_HI, 1
	RELEASE $0F, 1
	NOTE C_HI, 1
	RELEASE 0, 0
	OCTAVE 2
	NOTE C_, 2
	RELEASE 8, 0
	NOTE G#, 1
	RELEASE $0F, 1
	NOTE G#, 1
	RELEASE 0, 0
	NOTE C#, 2
	RELEASE 8, 0
	NOTE A_, 1
	RELEASE $0F, 1
	NOTE A_, 1
	RELEASE 0, 0
	NOTE D#, 2
	RELEASE 8, 0
	NOTE G#, 1
	RELEASE $0F, 1
	NOTE G#, 1
	RELEASE 0, 0
	NOTE E_, 2
	RELEASE 8, 0
	NOTE A_, 1
	RELEASE $0F, 1
	NOTE A_, 1
	RELEASE 0, 0
	NOTE F#, 2
	RELEASE $0B, 1
	NOTE B_, 2
	NOTE G#, 2
	RELEASE 0, 0
	OCTAVE 1
	NOTE B_, 2
	VOICE $05, 1, 2, 0, 0
	TRANSPOSE_UP 0
	LOOP_START
	RELEASE $0B, 2
	OCTAVE 3
	NOTE C#, 2
	REST 4
	NOTE C#, 2
	REST 4
	NOTE D_, 2
	REST 4
	RELEASE 4, 1
	VIBRATO $01, 2, 3
	NOTE D_, 6
	RELEASE 6, 1
	NOTE D_, 4
	NOTE D_, 4
	VIBRATO_OFF
	LOOP_END $02
	LOOP_START
	RELEASE 7, 1
	OCTAVE 2
	NOTE C#, 2
	RELEASE $0D, 1
	NOTE C#, 2
	LOOP_END $03
	LOOP_START
	RELEASE 7, 1
	OCTAVE 2
	NOTE D_, 2
	RELEASE $0D, 1
	NOTE D_, 2
	LOOP_END $02
	RELEASE 7, 1
	OCTAVE 2
	NOTE F#, 2
	RELEASE $0D, 1
	NOTE F#, 2
	RELEASE 7, 1
	OCTAVE 2
	NOTE A_, 2
	RELEASE $0D, 1
	NOTE A_, 2
	RELEASE 7, 1
	OCTAVE 3
	NOTE D_, 2
	RELEASE $0D, 1
	NOTE D_, 2
	RELEASE 0, 0
	VIBRATO $01, 2, 2
	WAVE_X $2D
	OCTAVE 4
	NOTE G#, 8
	NOTE E_, 8
	NOTE F#, 8
	NOTE D_, 8
	VIBRATO_OFF
	RELEASE $0B, 1
	WAVE 1
	RELEASE $0B, 2
	OCTAVE 3
	NOTE C#, 2
	REST 4
	NOTE C#, 2
	REST 4
	NOTE D_, 2
	REST 4
	RELEASE 4, 1
	VIBRATO $01, 2, 3
	NOTE D_, 6
	RELEASE 6, 1
	NOTE D_, 4
	NOTE D_, 4
	VIBRATO_OFF
	RELEASE $0B, 1
	NOTE C#, 2
	REST 7
	ATTEN 1
	OCTAVE 4
	RELEASE 0, 0
	DETUNE $FF
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	REST 1
	DETUNE $00
	RELEASE $0B, 1
	ATTEN 0
	OCTAVE 3
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE F#, 2
	RELEASE 0, 0
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	SND_LOOP

Snd80_Drm:
	LEN_UNIT $05
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	LOOP_START
	DRUM 3, 1
	LOOP_END $08
	SND_SEGNO
	LOOP2_START
	DRUM $0C, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	LOOP_END $03
	LOOP_BREAK $FC
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	LOOP_END $03
	LOOP_START
	DRUM 9, 1
	DRUM 3, 1
	DRUM 7, 1
	LOOP_END $04
	DRUM 3, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	LOOP2_END $02
	DRUM $0C, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	LOOP_END $02
	DRUM 3, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 5, 1
	LOOP_START
	DRUM 3, 1
	DRUM 8, 1
	LOOP_END $04
	DRUM $0C, 2
	SND_CALL Snd80_Drm_7E52
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	SND_CALL Snd80_Drm_7E52
	LOOP_END $02
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 7, 1
	DRUM 8, 1
	LOOP_START
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_END $02
	DRUM 3, 1
	DRUM 5, 1
	LOOP_START
	DRUM 3, 1
	DRUM 8, 1
	LOOP_END $03
	DRUM 3, 1
	DRUM 9, 1
	DRUM $0C, 2
	SND_CALL Snd80_Drm_7E52
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	SND_CALL Snd80_Drm_7E52
	LOOP_END $02
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	LOOP_END $04
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM $0C, 2
	SND_CALL Snd80_Drm_7E52
	LOOP_START
	DRUM 9, 1
	DRUM 8, 1
	SND_CALL Snd80_Drm_7E52
	LOOP_END $02
	LOOP_START
	DRUM $0C, 2
	SND_CALL Snd80_Drm_7E52
	LOOP_END $02
	DRUM $0C, 4
	DRUM 9, 4
	DRUM 3, 1
	DRUM 5, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 5, 1
	DRUM 8, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM 8, 1
	LOOP_START
	DRUM 3, 1
	DRUM 8, 1
	LOOP_END $05
	DRUM 3, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	SND_LOOP
Snd80_Drm_7E52:
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
	DRUM 9, 1
	DRUM 8, 1
	DRUM 9, 1
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
	DRUM 3, 1
	DRUM 8, 1
	SND_RET

SECTION "Sound bank $0F", ROMX[$4000], BANK[$0F]

Snd81_Ch2:
	VOICE $0E, 8, 11, 0, 0
	VIBRATO $01, 2, 3
	ATTEN 4
	OCTAVE 3
	NOTE F#, 4
	ATTEN 0
	ENVELOPE $19
	NOTE F_, 4
	ENVELOPE $00
	ATTEN 4
	NOTE A_, 2
	ATTEN 0
	ENVELOPE $19
	NOTE A#, 2
	ATTEN 5
	ENVELOPE $00
	RELEASE 2, 5
	OCTAVE 4
	NOTE C_, 12
	ENVELOPE $1B
	ATTEN 5
	OCTAVE 3
	NOTE A_, 2
	ATTEN 0
	ENVELOPE $19
	NOTE A#, 2
	OCTAVE 4
	ATTEN 3
	ENVELOPE $1B
	NOTE C_, 4
	ENVELOPE $1B
	ATTEN 5
	NOTE D#, 4
	ATTEN 4
	NOTE C#, 8
	VIBRATO $01, 0, 3
	ENVELOPE $00
	RELEASE 5, 5
	NOTE C#, 4
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	ENVELOPE $1B
	NOTE C_, 2
	ATTEN 0
	ENVELOPE $19
	OCTAVE 3
	NOTE A#, 2
	VIBRATO $01, 2, 3
	ATTEN 4
	ENVELOPE $1B
	OCTAVE 4
	NOTE C#, 4
	VIBRATO $01, 0, 3
	ENVELOPE $00
	RELEASE $0C, 7
	NOTE C#, 4
	VIBRATO $01, 2, 3
	ENVELOPE $1B
	OCTAVE 3
	NOTE F#, 4
	ENVELOPE $00
	VIBRATO $01, 0, 3
	RELEASE 7, 7
	NOTE F#, 4
	VOICE $0E, 8, 11, 0, 0
	VIBRATO $01, 2, 3
	ENVELOPE $06
	ATTEN 2
	OCTAVE 3
	NOTE F_, 4
	ENVELOPE $06
	ATTEN 0
	NOTE A_, 2
	ATTEN 2
	ENVELOPE $05
	NOTE A#, 2
	ATTEN 3
	ENVELOPE $1B
	OCTAVE 4
	NOTE C_, 8
	ENVELOPE $00
	VIBRATO $01, 0, 3
	RELEASE 9, 5
	NOTE C_, 4
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	ENVELOPE $1B
	ATTEN 5
	OCTAVE 3
	NOTE A_, 2
	ATTEN 0
	ENVELOPE $19
	NOTE A#, 2
	OCTAVE 4
	ATTEN 4
	ENVELOPE $05
	NOTE C_, 2
	ENVELOPE $00
	RELEASE 5, 5
	ATTEN 3
	VIBRATO $01, 0, 3
	NOTE C_, 2
	RELEASE 0, 0
	ENVELOPE $17
	ATTEN 1
	VIBRATO $01, 2, 3
	OCTAVE 3
	NOTE A_, 4
	ENVELOPE $1B
	NOTE A#, 2
	ENVELOPE $00
	RELEASE 7, 7
	NOTE A#, 6
	RELEASE 0, 0
	ENVELOPE $1B
	ATTEN 2
	NOTE G#, 4
	ATTEN 3
	NOTE D#, 4
	ATTEN 4
	NOTE F_, 6
	ENVELOPE $00
	RELEASE 7, 7
	VIBRATO $01, 0, 3
	NOTE F_, 6
	VOICE $0E, 0, 8, 0, 0
	DUTY_STEP 4, 1
	VIBRATO $01, 2, 3
	ENVELOPE $1B
	ATTEN 3
	OCTAVE 3
	NOTE D_, 4
	NOTE F_, 4
	VIBRATO $01, 0, 3
	ATTEN 0
	DUTY_STEP 0, 0
	ENVELOPE $00
	RELEASE 5, 6
	NOTE F_, 8
	VOICE $0E, 8, 11, 0, 0
	VIBRATO $01, 2, 3
	ENVELOPE $0E
	OCTAVE 3
	NOTE F#, 4
	ATTEN 0
	ENVELOPE $19
	NOTE F_, 4
	ENVELOPE $05
	NOTE A_, 2
	ENVELOPE $1B
	ATTEN 1
	NOTE A#, 2
	ATTEN 2
	OCTAVE 4
	NOTE C_, 8
	ENVELOPE $00
	VIBRATO $01, 0, 3
	RELEASE 5, 5
	NOTE C_, 4
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	ATTEN 1
	ENVELOPE $1B
	OCTAVE 3
	NOTE A_, 2
	ATTEN 0
	ENVELOPE $19
	NOTE A#, 2
	OCTAVE 4
	ATTEN 2
	ENVELOPE $1B
	NOTE C_, 4
	ATTEN 0
	ENVELOPE $19
	NOTE D#, 4
	ENVELOPE $1B
	ATTEN 2
	NOTE C#, 8
	VIBRATO $01, 0, 3
	ENVELOPE $00
	RELEASE 5, 7
	NOTE C#, 4
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	ENVELOPE $1B
	ATTEN 1
	NOTE C_, 2
	ATTEN 0
	ENVELOPE $19
	OCTAVE 3
	NOTE A#, 2
	VIBRATO $01, 2, 3
	ATTEN 2
	ENVELOPE $1B
	OCTAVE 4
	NOTE C#, 4
	ATTEN 1
	ENVELOPE $19
	NOTE F#, 4
	VIBRATO $01, 2, 2
	NOTE F_, 6
	ENVELOPE $00
	ATTEN 0
	RELEASE 5, 7
	VIBRATO $01, 0, 2
	NOTE F_, 6
	VIBRATO $01, 2, 3
	ATTEN 3
	ENVELOPE $1B
	NOTE D#, 2
	NOTE C#, 2
	ATTEN 3
	OCTAVE 4
	NOTE C_, 6
	ENVELOPE $00
	VIBRATO $01, 0, 3
	RELEASE 5, 5
	NOTE C_, 4
	RELEASE 0, 0
	VIBRATO $01, 2, 3
	ATTEN 4
	ENVELOPE $1B
	NOTE D#, 2
	NOTE C#, 2
	NOTE C_, 2
	NOTE D#, 8
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	ATTEN 5
	NOTE C#, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 4
	ENVELOPE $00
	VIBRATO $01, 0, 3
	RELEASE 5, 5
	NOTE A#, 12
	SND_END

Snd81_Ch1:
	VOICE $0E, 8, 15, 15, 1
	ATTEN 7
	OCTAVE 2
	NOTE F_, 4
	ATTEN 0
	DUTY_STEP 0, 1
	RELEASE 0, 0
	VIBRATO $01, 2, 4
	ENVELOPE $16
	OCTAVE 1
	NOTE F_, 8
	ENVELOPE $00
	RELEASE $0F, 7
	VIBRATO $01, 0, 3
	DUTY_STEP 0, 0
	NOTE F_, 4
	DUTY 0
	VIBRATO_OFF
	ENVELOPE $1B
	OCTAVE 2
	NOTE C_, 1
	NOTE F_, 1
	ENVELOPE $01
	NOTE G_, 1
	NOTE A_, 1
	RELEASE $0F, 6
	DUTY 8
	DUTY_STEP 0, 1
	ENVELOPE $00
	OCTAVE 1
	NOTE F_, 4
	DUTY_STEP 0, 0
	VIBRATO $01, 2, 4
	RELEASE 5, 7
	ATTEN 5
	NOTE F_, 8
	DUTY 0
	VIBRATO_OFF
	ENVELOPE $1B
	ATTEN 0
	OCTAVE 2
	NOTE F_, 1
	NOTE G_, 1
	ENVELOPE $01
	NOTE A_, 1
	NOTE F_, 1
	DUTY_STEP 0, 1
	RELEASE $0F, 5
	DUTY 8
	ENVELOPE $00
	OCTAVE 1
	NOTE D#, 4
	DUTY_STEP 0, 0
	VIBRATO $01, 2, 4
	ATTEN 5
	DUTY 0
	OCTAVE 3
	ENVELOPE $1B
	ATTEN 4
	NOTE C_, 2
	ENVELOPE $01
	NOTE C#, 2
	ATTEN 5
	NOTE D#, 8
	ENVELOPE $00
	VIBRATO $01, 0, 4
	RELEASE $0F, 7
	NOTE D#, 4
	ATTEN 3
	VIBRATO $01, 2, 4
	ENVELOPE $1B
	NOTE D#, 4
	RELEASE $0F, 7
	ATTEN 7
	VIBRATO $01, 0, 4
	NOTE D#, 4
	ATTEN 3
	VIBRATO $01, 2, 4
	ENVELOPE $1B
	NOTE C#, 2
	OCTAVE 2
	NOTE A#, 2
	VOICE $0E, 8, 15, 15, 6
	DUTY_STEP 0, 1
	VIBRATO $01, 2, 4
	ENVELOPE $00
	OCTAVE 1
	NOTE F_, 4
	DUTY_STEP 0, 0
	VIBRATO $01, 0, 4
	RELEASE 5, 7
	ATTEN 5
	NOTE F_, 8
	DUTY_STEP 0, 1
	RELEASE $0F, 6
	ATTEN 0
	NOTE C_, 4
	RELEASE 0, 0
	ENVELOPE $1C
	NOTE F_, 12
	DUTY_STEP 0, 0
	ENVELOPE $00
	VOICE $0E, 8, 11, 0, 0
	VIBRATO_OFF
	ENVELOPE $1B
	ATTEN 2
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	ENVELOPE $01
	NOTE D#, 1
	NOTE C_, 1
	ATTEN 2
	VIBRATO $01, 2, 4
	ENVELOPE $1B
	NOTE C#, 2
	ENVELOPE $00
	VIBRATO $01, 0, 4
	RELEASE 7, 7
	NOTE C#, 6
	VIBRATO $01, 2, 4
	RELEASE 0, 0
	ENVELOPE $1B
	ATTEN 2
	NOTE D#, 4
	ATTEN 1
	NOTE C_, 4
	VIBRATO $01, 2, 4
	ATTEN 2
	NOTE D_, 6
	ENVELOPE $00
	RELEASE 7, 7
	VIBRATO $01, 0, 4
	NOTE D_, 6
	RELEASE 0, 0
	VIBRATO $01, 2, 4
	ENVELOPE $01
	ATTEN 4
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE C#, 6
	ENVELOPE $00
	RELEASE $0F, 7
	ATTEN 0
	VIBRATO $01, 0, 4
	NOTE C#, 6
	VOICE $0E, 8, 11, 0, 0
	ATTEN 3
	VIBRATO $01, 2, 4
	ENVELOPE $1B
	OCTAVE 2
	NOTE A#, 4
	VOICE $0E, 8, 15, 0, 0
	OCTAVE 1
	ENVELOPE $01
	ATTEN 4
	VIBRATO $01, 2, 6
	NOTE F_, 14
	ATTEN 0
	ENVELOPE $1D
	VIBRATO $01, 0, 6
	NOTE F_, 14
	ENVELOPE $00
	RELEASE $0F, 5
	NOTE F_, 4
	ENVELOPE $01
	ATTEN 4
	VIBRATO $01, 2, 6
	NOTE D#, 4
	ATTEN 0
	ENVELOPE $1D
	VIBRATO $01, 0, 6
	NOTE D#, 0
	ENVELOPE $00
	RELEASE $0F, 5
	NOTE D#, 4
	VIBRATO $01, 2, 6
	RELEASE 0, 0
	ENVELOPE $01
	NOTE C#, 0
	VIBRATO $01, 2, 5
	NOTE G#, 0
	VIBRATO $01, 2, 6
	NOTE D#, 12
	ATTEN 0
	VIBRATO $01, 0, 6
	ENVELOPE $00
	RELEASE $0F, 5
	NOTE D#, 4
	RELEASE 0, 0
	ATTEN 3
	ENVELOPE $01
	VIBRATO $01, 2, 5
	NOTE A#, 10
	VIBRATO $01, 0, 5
	RELEASE $0F, 7
	NOTE A#, 6
	SND_END

Snd81_Ch3:
	VOICE $0E, 4, 4, 13, 4
	WAVE_X $40
	OCTAVE 3
	NOTE A#, 4
	VOICE $0E, 4, 4, 0, 0
	DETUNE $FF
	WAVE_X $04
	VIBRATO $01, 2, 3
	OCTAVE 4
	NOTE C_, 0
	VIBRATO $01, 0, 3
	NOTE C_, 0
	VIBRATO $01, 2, 3
	NOTE F#, 0
	RELEASE 5, 5
	VIBRATO $01, 0, 3
	NOTE F#, 4
	VIBRATO $01, 2, 3
	RELEASE 4, 7
	OCTAVE 3
	NOTE F#, 12
	VOICE $0E, 4, 2, 0, 0
	VIBRATO $01, 2, 3
	ATTEN 1
	OCTAVE 4
	NOTE C_, 0
	VIBRATO $01, 0, 3
	NOTE C_, 12
	INSTRUMENT $08
	ATTEN 1
	OCTAVE 2
	NOTE F_, 4
	VIBRATO_OFF
	INSTRUMENT $00
	ATTEN 0
	VOICE $0E, 1, 2, 15, 7
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE A#, 2
	ATTEN 1
	NOTE A#, 2
	ATTEN 0
	OCTAVE 2
	NOTE G#, 2
	ATTEN 1
	NOTE G#, 2
	ATTEN 0
	NOTE C_HI, 2
	ATTEN 1
	NOTE C_HI, 2
	ATTEN 0
	NOTE A#, 2
	OCTAVE 3
	NOTE F_, 2
	VOICE $0E, 5, 2, 0, 0
	OCTAVE 3
	NOTE D_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE A#, 1
	VIBRATO $01, 0, 3
	RELEASE $0A, 7
	NOTE D_, 4
	VOICE $0E, 1, 2, 15, 7
	VIBRATO_OFF
	OCTAVE 2
	NOTE F_, 2
	ATTEN 1
	NOTE F_, 2
	ATTEN 0
	OCTAVE 1
	NOTE A#, 2
	ATTEN 1
	NOTE A#, 2
	ATTEN 0
	VOICE $0E, 5, 2, 0, 0
	OCTAVE 3
	NOTE C#, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE A#, 1
	VIBRATO $01, 0, 3
	RELEASE $0A, 7
	NOTE C#, 4
	VOICE $0E, 1, 2, 15, 7
	VIBRATO_OFF
	OCTAVE 2
	NOTE F#, 2
	ATTEN 1
	NOTE F#, 2
	ATTEN 0
	VOICE $0E, 4, 2, 0, 0
	VIBRATO $01, 2, 3
	OCTAVE 4
	NOTE C_, 8
	OCTAVE 3
	NOTE A_, 8
	VIBRATO $01, 0, 3
	NOTE A_, 0
	VIBRATO $01, 2, 3
	NOTE A#, 0
	VIBRATO $01, 0, 3
	NOTE A#, 2
	VIBRATO $01, 2, 3
	OCTAVE 4
	NOTE C_, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE G#, 4
	NOTE G_, 8
	NOTE F_, 4
	NOTE D#, 0
	OCTAVE 3
	NOTE A#, 0
	NOTE D_, 4
	VOICE $0E, 1, 2, 15, 7
	WAVE_X $2E
	VIBRATO_OFF
	OCTAVE 3
	NOTE F_, 2
	WAVE_X $1F
	NOTE A#, 2
	WAVE_X $1D
	OCTAVE 4
	NOTE D_, 2
	ATTEN 1
	NOTE D_, 2
	ATTEN 2
	NOTE D_, 4
	SND_END

Snd81_Drm:
	LEN_UNIT $0E
	LOOP_START
	REST 0
	LOOP_END $0C
	REST $0C
	DRUM_SND $13, 0
	REST 0
	DRUM_SND $13, 0
	SND_END

Snd82_Ch2:
	VOICE $05, 0, 10, 15, 2
	TEMPO $20
	DETUNE $01
	LOOP_START
	OCTAVE 4
	NOTE D#, 6
	NOTE D#, 6
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	LOOP_END $02
	NOTE D#, 6
	REST 6
	LOOP_START
	OCTAVE 3
	NOTE A#, 6
	NOTE A#, 6
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE A#, 6
	LOOP_END $02
	LOOP_START
	NOTE A#, 6
	NOTE A#, 6
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 6
	LOOP_END $02
	LOOP_START
	NOTE B_, 6
	NOTE B_, 6
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 6
	LOOP_END $02
	VIBRATO $01, 1, 2
	RELEASE $0E, 7
	OCTAVE 2
	NOTE B_, 6
	OCTAVE 3
	NOTE C_, 6
	NOTE C#, 6
	OCTAVE 2
	NOTE F#, 6
	VIBRATO_OFF
	RELEASE $0F, 2
	OCTAVE 4
	NOTE A#, 6
	NOTE B_, 6
	RELEASE $0F, 3
	NOTE A#, 2
	ATTEN 3
	NOTE A_, 2
	NOTE F#, 2
	ATTEN 0
	NOTE F_, 2
	ATTEN 3
	NOTE D#, 2
	OCTAVE 3
	NOTE B_, 2
	ATTEN 0
	NOTE A#, 6
	NOTE A#, 6
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 6
	VOICE $05, 8, 10, 7, 4
	TEMPO $20
	DETUNE $01
	DUTY_STEP 0, 1
	VIBRATO $01, 2, 2
	OCTAVE 3
	NOTE B_, 8
	RELEASE $0B, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	RELEASE 0, 0
	NOTE F_, 6
	RELEASE $0A, 2
	NOTE F#, 4
	RELEASE $0D, 2
	OCTAVE 3
	NOTE F#, 2
	RELEASE 0, 0
	NOTE B_, 8
	OCTAVE 4
	RELEASE $0B, 2
	NOTE C#, 2
	NOTE D#, 2
	RELEASE 0, 0
	NOTE F_, 6
	RELEASE $0A, 2
	NOTE F#, 4
	RELEASE $0D, 2
	NOTE F#, 2
	RELEASE 3, 4
	NOTE B_, 8
	RELEASE $0B, 2
	NOTE A_, 2
	NOTE G_, 2
	RELEASE 7, 3
	NOTE F#, 10
	RELEASE $0D, 2
	OCTAVE 3
	NOTE B_, 2
	RELEASE 3, 4
	OCTAVE 4
	NOTE B_, 8
	RELEASE $0B, 2
	NOTE A_, 2
	NOTE G_, 2
	RELEASE 7, 3
	NOTE F#, 6
	REST 4
	RELEASE $0D, 2
	NOTE F#, 2
	RELEASE $0C, 3
	NOTE A_, 6
	RELEASE $0B, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE G_, 2
	RELEASE $0C, 7
	NOTE F#, 6
	RELEASE $0A, 2
	OCTAVE 3
	NOTE B_, 4
	RELEASE $0D, 2
	OCTAVE 4
	NOTE F#, 2
	RELEASE $0C, 3
	NOTE A_, 6
	RELEASE $0B, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE G_, 2
	RELEASE 7, 3
	NOTE F#, 10
	RELEASE $0D, 2
	NOTE F#, 2
	RELEASE $0C, 7
	NOTE A_, 6
	ATTEN 1
	NOTE G#, 6
	ATTEN 2
	NOTE G_, 6
	ATTEN 3
	NOTE D#, 6
	ATTEN 0
	VOICE $05, 8, 8, 2, 7
	TEMPO $20
	DETUNE $01
	DUTY_STEP 0, 0
	VIBRATO $01, 3, 2
	OCTAVE 3
	NOTE B_, 0
	VIBRATO $01, 0, 2
	RELEASE 0, 0
	ATTEN 2
	NOTE B_, 0
	RELEASE 5, 5
	NOTE B_, 0
	ATTEN 7
	RELEASE 0, 0
	VIBRATO $01, 3, 2
	OCTAVE 4
	ENVELOPE $1D
	NOTE C_, 0
	ENVELOPE $00
	ATTEN 0
	VIBRATO $01, 0, 2
	NOTE C_, 0
	RELEASE 2, 5
	NOTE C_, 0
	VIBRATO $01, 3, 2
	RELEASE 0, 0
	ENVELOPE $1B
	ATTEN 3
	NOTE D_, 0
	ATTEN 0
	ENVELOPE $00
	VIBRATO $01, 0, 2
	NOTE D_, 4
	RELEASE 0, 0
	NOTE D_, 0
	VIBRATO_OFF
	VOICE $0C, 8, 15, 0, 0
	DETUNE $00
	TEMPO $19
	VIBRATO $01, 3, 6
	LOOP_START
	RELEASE 0, 0
	ENVELOPE $16
	OCTAVE 1
	NOTE E_, 9
	RELEASE $0F, 2
	NOTE E_, 3
	LOOP_BREAK $FB
	RELEASE 8, 1
	NOTE E_, 2
	LOOP_END $03
	RELEASE 5, 2
	NOTE E_, 2
	RELEASE 0, 0
	ENVELOPE $16
	NOTE G_, 9
	RELEASE $0F, 2
	NOTE G_, 3
	RELEASE 5, 2
	NOTE G_, 2
	RELEASE 0, 0
	ENVELOPE $16
	OCTAVE 1
	NOTE E_, 9
	RELEASE $0F, 2
	NOTE E_, 3
	RELEASE 5, 2
	NOTE E_, 2
	ENVELOPE $00
	RELEASE 0, 0
	NOTE E_, 12
	RELEASE 6, 4
	OCTAVE 1
	NOTE C_, 8
	REST 4
	VOICE $0B, 8, 9, 0, 0
	DETUNE $00
	TEMPO $00
	ENVELOPE $1D
	ATTEN 6
	VIBRATO $01, 3, 2
	OCTAVE 4
	NOTE F#, 0
	ATTEN 2
	ENVELOPE $1B
	NOTE F_, 3
	ATTEN 0
	ENVELOPE $00
	RELEASE 5, 5
	VIBRATO $01, 0, 2
	NOTE F_, 9
	VIBRATO $01, 3, 2
	ATTEN 4
	ENVELOPE $1B
	NOTE D#, 2
	ATTEN 2
	NOTE C#, 2
	ATTEN 1
	ENVELOPE $1B
	NOTE C_, 8
	VIBRATO $01, 0, 2
	ENVELOPE $18
	NOTE C_, 2
	VIBRATO $01, 3, 2
	ENVELOPE $1B
	ATTEN 2
	NOTE D#, 2
	NOTE C#, 2
	NOTE C_, 2
	ATTEN 0
	ENVELOPE $00
	VIBRATO_OFF
	VOICE $06, 8, 6, 13, 2
	DETUNE $FF
	OCTAVE 4
	NOTE A#, 6
	NOTE A#, 6
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE F#, 6
	VOICE $06, 8, 8, 0, 0
	VIBRATO $01, 1, 1
	ENVELOPE $15
	OCTAVE 3
	NOTE A#, 12
	OCTAVE 4
	ENVELOPE $1B
	ATTEN 2
	NOTE D_, 6
	ATTEN 0
	NOTE D#, 6
	VIBRATO $01, 2, 1
	ENVELOPE $15
	NOTE F_, 8
	VIBRATO $01, 0, 1
	ENVELOPE $1E
	NOTE F_, 12
	ENVELOPE $0B
	NOTE F_, 0
	ENVELOPE $00
	ATTEN 0
	VIBRATO_OFF
	VIBRATO $01, 3, 1
	NOTE D_, 6
	NOTE F_, 6
	ENVELOPE $12
	VIBRATO $01, 1, 2
	ATTEN 0
	NOTE D#, 0
	ENVELOPE $0C
	ATTEN 2
	VIBRATO $01, 0, 1
	NOTE D#, 6
	ENVELOPE $00
	ATTEN 0
	VIBRATO $01, 1, 1
	NOTE F_, 2
	VIBRATO $01, 3, 1
	ATTEN 2
	ENVELOPE $1B
	NOTE F#, 12
	NOTE F_, 12
	ENVELOPE $00
	VIBRATO_OFF
	ATTEN 0
	VOICE $06, 8, 8, 13, 2
	OCTAVE 4
	NOTE D#, 6
	NOTE D#, 6
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 6
	NOTE D#, 6
	NOTE D#, 6
	NOTE D#, 6
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 0
	SND_END

Snd82_Ch1:
	VOICE $05, 0, 10, 13, 3
	TEMPO $20
	LOOP_START
	OCTAVE 2
	NOTE D#, 6
	NOTE D#, 6
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	LOOP_END $02
	OCTAVE 1
	NOTE D#, 6
	REST 6
	LOOP_START
	NOTE A#, 6
	NOTE A#, 6
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE A#, 6
	LOOP_END $02
	LOOP_START
	NOTE F#, 6
	NOTE F#, 6
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 6
	LOOP_END $02
	LOOP_START
	NOTE E_, 6
	NOTE E_, 6
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 6
	LOOP_END $02
	VIBRATO $01, 2, 5
	RELEASE $0E, 7
	NOTE E_, 6
	NOTE C_, 6
	NOTE F#, 6
	NOTE D_, 6
	VIBRATO_OFF
	LOOP_START
	RELEASE $0D, 3
	NOTE A#, 6
	NOTE A#, 6
	NOTE A#, 4
	NOTE A#, 2
	NOTE A#, 6
	LOOP_END $02
	VOICE $05, 0, 10, 13, 2
	TEMPO $20
	LOOP_START
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	LOOP_END $02
	LOOP2_START
	LOOP_START
	NOTE G_, 2
	LOOP_END $06
	LOOP_START
	NOTE F#, 2
	LOOP_END $06
	LOOP2_END $02
	LOOP2_START
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE G_, 2
	LOOP_START
	NOTE F#, 2
	LOOP_END $06
	LOOP2_END $02
	VIBRATO $01, 2, 5
	RELEASE $0E, 7
	NOTE C_, 6
	NOTE C#, 6
	NOTE D_, 6
	NOTE D#, 6
	VIBRATO_OFF
	RELEASE $0D, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 1
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 3
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	ATTEN 4
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	RELEASE 8, 5
	NOTE F#, 6
	NOTE F#, 6
	RELEASE 0, 0
	VIBRATO $01, 3, 2
	ENVELOPE $15
	ATTEN 2
	NOTE F_, 0
	VIBRATO $01, 0, 2
	ENVELOPE $00
	ATTEN 4
	NOTE F_, 0
	RELEASE 2, 7
	NOTE F_, 0
	RELEASE 0, 0
	VIBRATO $01, 3, 2
	ENVELOPE $15
	ATTEN 2
	NOTE F#, 0
	VIBRATO $01, 0, 2
	ENVELOPE $00
	ATTEN 4
	NOTE F#, 4
	RELEASE 0, 0
	NOTE F#, 0
	ATTEN 0
	VOICE $0C, 0, 10, 0, 0
	DETUNE $FD
	TEMPO $19
	REST 1
	VIBRATO $01, 3, 3
	ENVELOPE $15
	OCTAVE 3
	NOTE E_, 5
	DETUNE $00
	DUTY 4
	ENVELOPE $15
	OCTAVE 4
	NOTE B_, 2
	ENVELOPE $00
	RELEASE $0F, 5
	OCTAVE 5
	NOTE C_, 2
	ATTEN 1
	DUTY 0
	DETUNE $FD
	RELEASE 7, 7
	OCTAVE 3
	NOTE E_, 1
	ATTEN 2
	ENVELOPE $1B
	NOTE D#, 2
	NOTE C_, 2
	ATTEN 3
	RELEASE 0, 0
	OCTAVE 2
	NOTE B_, 5
	ENVELOPE $00
	ATTEN 0
	DETUNE $00
	DUTY 4
	ENVELOPE $15
	OCTAVE 4
	NOTE B_, 2
	ENVELOPE $00
	RELEASE $0F, 6
	NOTE A#, 2
	ATTEN 2
	DUTY 0
	DETUNE $FD
	RELEASE 7, 7
	ENVELOPE $1B
	OCTAVE 2
	NOTE A#, 1
	NOTE G_, 2
	NOTE A#, 2
	ATTEN 0
	RELEASE 0, 0
	ENVELOPE $15
	NOTE B_, 5
	DETUNE $00
	DUTY 4
	ENVELOPE $15
	OCTAVE 4
	NOTE B_, 2
	ENVELOPE $00
	RELEASE $0F, 5
	OCTAVE 5
	NOTE C_, 2
	ATTEN 1
	DUTY 0
	DETUNE $FD
	RELEASE 7, 7
	OCTAVE 2
	NOTE B_, 1
	ATTEN 0
	ENVELOPE $1B
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	ATTEN 0
	RELEASE 0, 0
	ENVELOPE $15
	NOTE A#, 5
	DETUNE $00
	DUTY 4
	ENVELOPE $15
	ATTEN 1
	OCTAVE 5
	NOTE F#, 2
	ENVELOPE $00
	RELEASE $0F, 4
	NOTE G_, 2
	ATTEN 1
	DUTY 0
	DETUNE $FD
	RELEASE 7, 7
	OCTAVE 2
	NOTE A#, 1
	ATTEN 2
	ENVELOPE $1B
	NOTE G_, 2
	NOTE A#, 2
	NOTE B_, 5
	ATTEN 0
	DETUNE $00
	DUTY 4
	ENVELOPE $15
	OCTAVE 4
	NOTE B_, 2
	ENVELOPE $00
	RELEASE $0F, 5
	OCTAVE 5
	NOTE C_, 2
	ATTEN 3
	DUTY 0
	DETUNE $FD
	RELEASE 7, 7
	OCTAVE 2
	NOTE B_, 1
	ATTEN 1
	ENVELOPE $1B
	OCTAVE 3
	NOTE C_, 2
	NOTE D#, 2
	ATTEN 2
	NOTE E_, 2
	RELEASE 8, 7
	ENVELOPE $00
	ATTEN 1
	VIBRATO $01, 0, 3
	NOTE E_, 2
	ATTEN 2
	VIBRATO_OFF
	ENVELOPE $1B
	NOTE F#, 2
	VIBRATO $01, 0, 3
	RELEASE $0A, 7
	ATTEN 1
	NOTE F#, 4
	ATTEN 2
	VIBRATO_OFF
	ENVELOPE $1B
	NOTE G_, 2
	ATTEN 5
	DUTY 8
	ENVELOPE $00
	RELEASE 0, 0
	VIBRATO $01, 2, 2
	OCTAVE 4
	NOTE G#, 11
	VOICE $0B, 8, 10, 0, 0
	TEMPO $00
	ENVELOPE $1D
	ATTEN 6
	VIBRATO $01, 3, 3
	OCTAVE 3
	NOTE C#, 0
	VOICE $0B, 8, 15, 0, 0
	DETUNE $00
	ENVELOPE $01
	VIBRATO $01, 3, 5
	OCTAVE 1
	NOTE C#, 0
	NOTE G#, 0
	VOICE $06, 8, 15, 13, 2
	LOOP_START
	OCTAVE 1
	NOTE A#, 6
	NOTE A#, 6
	RELEASE $0B, 1
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	RELEASE $0D, 2
	NOTE A#, 6
	LOOP_END $04
	NOTE B_, 6
	NOTE B_, 6
	RELEASE $0B, 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	RELEASE $0D, 2
	NOTE B_, 6
	OCTAVE 2
	NOTE C#, 6
	NOTE C#, 6
	RELEASE $0B, 1
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	RELEASE $0D, 2
	NOTE C#, 6
	NOTE D#, 6
	NOTE D#, 6
	RELEASE $0B, 1
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	RELEASE $0D, 2
	NOTE D#, 6
	NOTE D#, 6
	NOTE D#, 6
	NOTE D#, 6
	RELEASE $0B, 1
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	RELEASE $0D, 2
	NOTE D#, 0
	SND_END

Snd82_Ch3:
	VOICE $05, 10, 2, 14, 3
	TEMPO $20
	WAVE_X $19
	OCTAVE 3
	NOTE G_, 6
	NOTE G#, 6
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 6
	NOTE G_, 6
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	VOICE $05, 4, 2, 11, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE B_, 2
	VOICE $05, 4, 2, 7, 4
	VIBRATO $01, 2, 2
	NOTE A#, 8
	OCTAVE 4
	RELEASE $0B, 2
	NOTE C_, 2
	NOTE D_, 2
	RELEASE 0, 0
	NOTE E_, 6
	RELEASE $0A, 2
	NOTE F_, 4
	RELEASE $0D, 2
	OCTAVE 3
	NOTE F_, 2
	RELEASE 7, 3
	NOTE A#, 8
	RELEASE $0B, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	RELEASE 0, 0
	NOTE E_, 6
	RELEASE $0A, 2
	NOTE F_, 4
	RELEASE $0D, 2
	OCTAVE 3
	NOTE A#, 2
	RELEASE 3, 4
	OCTAVE 4
	NOTE A#, 8
	RELEASE $0B, 2
	NOTE G#, 2
	NOTE F#, 2
	RELEASE 7, 3
	NOTE F_, 10
	RELEASE $0D, 2
	OCTAVE 3
	NOTE A#, 2
	RELEASE 3, 4
	OCTAVE 4
	NOTE A#, 8
	RELEASE $0B, 2
	NOTE G#, 2
	NOTE F#, 2
	RELEASE 7, 3
	NOTE F_, 6
	REST 4
	RELEASE $0D, 2
	NOTE F_, 2
	RELEASE $0C, 3
	NOTE G#, 6
	RELEASE $0B, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F#, 2
	RELEASE $0C, 7
	NOTE F_, 6
	OCTAVE 3
	RELEASE $0A, 2
	NOTE A#, 4
	RELEASE $0D, 2
	OCTAVE 4
	NOTE F_, 2
	RELEASE $0C, 3
	NOTE G#, 6
	RELEASE $0B, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F#, 2
	RELEASE 7, 3
	NOTE F_, 10
	RELEASE $0D, 2
	NOTE F_, 2
	RELEASE $0C, 7
	NOTE G#, 6
	NOTE G_, 6
	NOTE F#, 6
	NOTE D_, 6
	RELEASE 3, 3
	OCTAVE 3
	NOTE A#, 12
	VIBRATO_OFF
	RELEASE $0E, 3
	WAVE_X $19
	RELEASE $0D, 4
	OCTAVE 4
	NOTE A#, 2
	ATTEN 1
	NOTE A_, 2
	NOTE F#, 2
	ATTEN 0
	NOTE F_, 2
	ATTEN 1
	NOTE D#, 2
	OCTAVE 3
	NOTE B_, 2
	ATTEN 0
	RELEASE $0E, 3
	OCTAVE 4
	NOTE D_, 6
	NOTE D_, 6
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	VOICE $01, 1, 4, 0, 0
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE D#, 3
	NOTE F_, 4
	NOTE F#, 4
	NOTE G#, 4
	NOTE A#, 3
	LOOP2_START
	VOICE $05, 1, 2, 14, 4
	TEMPO $20
	LOOP_START
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 2
	WAVE 4
	RELEASE $0C, 3
	OCTAVE 4
	NOTE D#, 2
	WAVE 1
	RELEASE $0E, 4
	LOOP_END $02
	OCTAVE 3
	NOTE F_, 2
	WAVE 4
	RELEASE $0C, 3
	NOTE C_HI, 2
	NOTE C_HI, 2
	WAVE 1
	RELEASE $0E, 4
	OCTAVE 2
	NOTE B_, 2
	WAVE 4
	RELEASE $0C, 3
	OCTAVE 4
	NOTE D#, 2
	NOTE D#, 2
	LOOP2_END $02
	LOOP2_START
	WAVE 1
	RELEASE $0E, 4
	OCTAVE 2
	NOTE G_, 2
	WAVE 4
	RELEASE $0C, 3
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	LOOP_START
	WAVE 1
	RELEASE $0E, 4
	OCTAVE 2
	NOTE B_, 2
	WAVE 4
	RELEASE $0C, 3
	OCTAVE 4
	NOTE D#, 2
	NOTE D#, 2
	LOOP_END $02
	LOOP2_END $02
	WAVE 1
	RELEASE $0E, 4
	OCTAVE 2
	NOTE F_, 2
	WAVE 4
	RELEASE $0C, 3
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	WAVE 1
	RELEASE $0E, 4
	OCTAVE 2
	NOTE G_, 2
	WAVE 1
	RELEASE $0E, 4
	OCTAVE 2
	NOTE B_, 2
	WAVE 4
	RELEASE $0C, 3
	OCTAVE 4
	NOTE D#, 2
	NOTE D#, 2
	WAVE 1
	RELEASE $0E, 4
	OCTAVE 2
	NOTE B_, 2
	WAVE 4
	RELEASE $0C, 3
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	WAVE 1
	RELEASE $0E, 4
	OCTAVE 2
	NOTE F_, 2
	WAVE 4
	RELEASE $0C, 3
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	WAVE 1
	RELEASE $0E, 4
	OCTAVE 2
	NOTE F_, 2
	WAVE 4
	RELEASE $0C, 3
	OCTAVE 4
	NOTE D_, 2
	WAVE 1
	RELEASE $0E, 4
	OCTAVE 2
	NOTE G_, 2
	WAVE 1
	RELEASE $0E, 4
	OCTAVE 2
	NOTE B_, 2
	WAVE 4
	RELEASE $0C, 3
	OCTAVE 4
	NOTE D#, 2
	NOTE D#, 2
	WAVE 1
	RELEASE $0E, 4
	OCTAVE 2
	NOTE B_, 2
	WAVE 4
	RELEASE $0C, 3
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	WAVE 1
	RELEASE $0C, 7
	OCTAVE 2
	NOTE F_, 6
	WAVE_X $2F
	NOTE C#, 6
	WAVE_X $2E
	NOTE G_, 6
	WAVE_X $2D
	NOTE D#, 6
	WAVE_X $1F
	RELEASE $0A, 7
	NOTE B_, 6
	NOTE B_, 6
	NOTE B_, 6
	NOTE B_, 6
	VOICE $05, 1, 2, 10, 7
	TEMPO $20
	WAVE_X $1F
	OCTAVE 2
	NOTE B_, 6
	NOTE B_, 6
	NOTE B_, 6
	NOTE F#, 6
	NOTE F_, 6
	NOTE F_, 6
	NOTE F_, 4
	RELEASE $0E, 7
	NOTE F_, 2
	RELEASE $0A, 7
	NOTE F_, 6
	NOTE F_, 6
	NOTE F_, 6
	NOTE F_, 4
	RELEASE $0E, 7
	NOTE F_, 2
	RELEASE $0A, 7
	NOTE G_, 6
	NOTE D_, 6
	NOTE D_, 12
	NOTE D_, 6
	VIBRATO $01, 3, 5
	RELEASE 9, 7
	NOTE D_, 12
	VIBRATO_OFF
	VOICE $0C, 7, 2, 3, 7
	TEMPO $19
	VIBRATO $01, 3, 2
	OCTAVE 4
	NOTE E_, 10
	RELEASE 7, 7
	NOTE D#, 2
	NOTE C_, 2
	RELEASE 3, 7
	OCTAVE 3
	NOTE B_, 8
	RELEASE 7, 7
	NOTE A#, 2
	NOTE G_, 2
	NOTE A#, 2
	RELEASE 1, 7
	NOTE B_, 10
	RELEASE 7, 7
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	RELEASE 3, 7
	NOTE A#, 10
	RELEASE 7, 7
	NOTE G_, 2
	NOTE A#, 2
	RELEASE 3, 7
	NOTE B_, 10
	RELEASE 7, 7
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 2
	RELEASE 5, 7
	NOTE E_, 4
	RELEASE 3, 7
	NOTE F#, 6
	RELEASE 7, 7
	NOTE G_, 2
	RELEASE 2, 7
	NOTE G#, 8
	REST 4
	VIBRATO_OFF
	VOICE $0B, 1, 2, 12, 7
	TEMPO $00
	REST 0
	VOICE $0B, 4, 2, 0, 0
	VIBRATO $01, 3, 2
	OCTAVE 4
	NOTE G#, 12
	RELEASE 4, 3
	NOTE F#, 2
	NOTE F_, 2
	RELEASE 0, 0
	NOTE D#, 0
	VIBRATO_OFF
	VOICE $06, 4, 2, 4, 7
	VIBRATO $01, 4, 2
	OCTAVE 3
	NOTE A#, 12
	OCTAVE 4
	NOTE D_, 6
	RELEASE 8, 4
	NOTE D#, 6
	RELEASE 0, 0
	NOTE F_, 12
	VIBRATO $01, 0, 2
	NOTE F_, 12
	RELEASE 4, 7
	NOTE F_, 12
	VIBRATO $01, 4, 2
	RELEASE 4, 6
	NOTE D_, 6
	RELEASE 8, 4
	NOTE D#, 6
	RELEASE 4, 7
	NOTE F_, 12
	RELEASE 2, 7
	NOTE G#, 12
	RELEASE 0, 0
	NOTE F#, 12
	VIBRATO $01, 0, 2
	NOTE F#, 12
	VIBRATO_OFF
	VOICE $06, 4, 2, 11, 3
	DETUNE $01
	OCTAVE 4
	NOTE F#, 6
	NOTE F#, 6
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 6
	OCTAVE 3
	NOTE A#, 6
	NOTE A#, 6
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 6
	NOTE A#, 6
	NOTE A#, 6
	OCTAVE 4
	NOTE G_, 6
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	RELEASE $0D, 2
	NOTE G_, 0
	SND_END

Snd82_Drm:
	LEN_UNIT $05
	TEMPO $20
	DRUM $0C, 6
	DRUM $0C, 6
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM $0C, 6
	DRUM 3, 6
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM_SND $0D, 12
	DRUM $0C, 6
	DRUM 3, 6
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 6
	DRUM 3, 6
	DRUM 3, 6
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 6
	DRUM 3, 6
	DRUM 3, 6
	DRUM 3, 4
	DRUM_SND $0D, 2
	DRUM_SND $0D, 6
	DRUM $0C, 6
	DRUM 3, 6
	DRUM 3, 4
	DRUM_SND $0D, 2
	DRUM_SND $0D, 6
	DRUM 3, 6
	DRUM 3, 6
	DRUM 3, 4
	DRUM_SND $0D, 2
	DRUM_SND $0D, 6
	LOOP_START
	DRUM 3, 1
	LOOP_END $06
	DRUM 3, $0A
	DRUM_SND $0D, 2
	DRUM_SND $0D, 6
	REST $0C
	REST $0C
	DRUM $0C, 6
	DRUM 3, 6
	DRUM $0C, 4
	DRUM $0C, 2
	DRUM $0C, 6
	DRUM 3, 6
	DRUM 3, 6
	DRUM 3, 4
	DRUM 3, 2
	DRUM_SND $0D, 6
	DRUM $0C, 6
	DRUM_SND $16, 2
	DRUM_SND $16, 2
	REST 2
	DRUM_SND $15, 6
	DRUM_SND $16, 6
	LOOP_START
	DRUM_SND $16, 2
	DRUM_SND $16, 2
	REST 2
	LOOP_END $02
	DRUM_SND $15, 6
	DRUM_SND $16, 6
	DRUM_SND $14, 12
	DRUM_SND $15, 6
	DRUM_SND $15, 6
	DRUM_SND $14, 12
	DRUM_SND $15, 6
	DRUM_SND $0D, 6
	DRUM_SND $15, 6
	DRUM_SND $15, 4
	DRUM_SND $16, 2
	DRUM_SND $16, 6
	DRUM_SND $0D, 6
	DRUM $0C, 6
	DRUM $0C, 4
	DRUM $0C, 2
	DRUM $0C, 6
	DRUM_SND $0D, 6
	DRUM $0C, 6
	DRUM_SND $15, 6
	DRUM_SND $16, 6
	DRUM_SND $16, 6
	DRUM_SND $16, 12
	LOOP_START
	REST $0C
	LOOP_END $0A
	LEN_UNIT $0C
	TEMPO $19
	DRUM_SND $0D, 4
	DRUM 3, 4
	DRUM 3, 2
	DRUM_SND $18, 2
	DRUM_SND $18, 2
	DRUM_SND $0D, 3
	DRUM_SND $18, 1
	DRUM 3, 2
	DRUM_SND $18, 2
	DRUM 3, 1
	DRUM_SND $18, 1
	DRUM_SND $18, 1
	DRUM_SND $18, 2
	DRUM_SND $18, 1
	DRUM_SND $0D, 3
	DRUM_SND $18, 1
	DRUM 3, 4
	DRUM_SND $18, 1
	DRUM 3, 1
	DRUM_SND $18, 1
	DRUM_SND $17, 1
	DRUM_SND $18, 1
	DRUM_SND $18, 1
	DRUM_SND $0D, 4
	DRUM 3, 2
	DRUM 3, 1
	DRUM_SND $18, 1
	DRUM 3, 1
	LOOP_START
	DRUM_SND $18, 1
	LOOP_END $05
	DRUM_SND $0D, 3
	DRUM 5, 1
	DRUM 3, 4
	DRUM 3, 1
	DRUM 5, 1
	DRUM 5, 1
	DRUM 3, 1
	DRUM 5, 2
	DRUM_SND $0D, 4
	DRUM 3, 2
	DRUM_SND $0D, 2
	DRUM_SND $0D, 4
	DRUM_SND $0D, 4
	DRUM_SND $0D, 8
	LEN_UNIT $0B
	TEMPO $00
	REST 0
	LOOP_START
	REST 8
	LOOP_END $04
	LEN_UNIT $06
	LOOP_START
	DRUM 3, 6
	DRUM 3, 6
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 6
	LOOP_END $06
	DRUM_SND $0D, 6
	DRUM 3, 6
	DRUM_SND $0D, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM_SND $0D, 6
	DRUM_SND $0D, 6
	DRUM 3, 6
	LOOP_START
	DRUM_SND $0D, 2
	DRUM 3, 2
	DRUM 3, 2
	LOOP_END $02
	DRUM $0C, 0
	SND_END

Snd83_Ch1:
	SND_END

Snd83_Ch3:
	VOICE $0A, 3, 2, 15, 1
	SND_SEGNO
	OCTAVE 4
	NOTE C_, 1
	REST 2
	OCTAVE 3
	NOTE C_, 1
	REST 2
	SND_LOOP

Snd84_Ch2:
	VOICE $03, 8, 12, 0, 0
	OCTAVE 2
	NOTE G#, 1
	ATTEN 4
	NOTE B_, 1
	ATTEN 2
	OCTAVE 3
	NOTE E_, 1
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	OCTAVE 2
	NOTE A#, 1
	ATTEN 4
	OCTAVE 3
	NOTE C#, 1
	ATTEN 2
	NOTE F#, 1
	ATTEN 4
	NOTE A#, 1
	ATTEN 0
	OCTAVE 2
	NOTE B_, 1
	ATTEN 4
	OCTAVE 3
	NOTE E_, 1
	ATTEN 2
	NOTE G#, 1
	ATTEN 4
	NOTE B_, 1
	ATTEN 0
	OCTAVE 3
	ATTEN 4
	NOTE C#, 1
	ATTEN 2
	NOTE F#, 1
	NOTE A#, 1
	OCTAVE 4
	ATTEN 4
	NOTE C#, 1
	ATTEN 2
	VIBRATO $01, 3, 4
	RELEASE $0A, 3
	NOTE D#, 0
	SND_END

Snd84_Ch1:
	VOICE $03, 8, 14, 0, 0
	OCTAVE 2
	NOTE E_, 1
	ATTEN 4
	NOTE G#, 1
	ATTEN 2
	NOTE B_, 1
	ATTEN 4
	OCTAVE 3
	NOTE E_, 1
	ATTEN 0
	OCTAVE 2
	NOTE F#, 1
	ATTEN 4
	NOTE A#, 1
	ATTEN 2
	OCTAVE 3
	NOTE C#, 1
	ATTEN 4
	NOTE F#, 1
	ATTEN 0
	OCTAVE 2
	NOTE G#, 1
	ATTEN 4
	NOTE B_, 1
	ATTEN 2
	OCTAVE 3
	NOTE E_, 1
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	OCTAVE 2
	NOTE A#, 1
	ATTEN 4
	OCTAVE 3
	NOTE C#, 1
	ATTEN 2
	NOTE F#, 1
	ATTEN 4
	NOTE A#, 1
	ATTEN 3
	VIBRATO $01, 3, 4
	RELEASE 9, 3
	NOTE F#, 0
	SND_END

Snd84_Ch3:
	VOICE $03, 1, 2, 0, 0
	OCTAVE 3
	NOTE E_, 4
	NOTE F#, 4
	NOTE G#, 4
	NOTE A#, 4
	VIBRATO $01, 3, 5
	RELEASE 5, 4
	OCTAVE 2
	NOTE B_, 0
	SND_END

Snd84_Drm:
	LEN_UNIT $03
	DRUM $0C, 0
	REST 4
	DRUM_SND $0F, 0
	SND_END

Snd85_Ch2:
	VOICE $07, 8, 15, 10, 2
	TRANSPOSE_UP 2
	SND_SEGNO
	OCTAVE 2
	NOTE C_, 1
	ATTEN 6
	NOTE C_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 6
	NOTE G_, 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 1
	ATTEN 6
	NOTE C_, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 6
	NOTE G_, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 0
	NOTE C_, 1
	ATTEN 6
	NOTE C_, 1
	ATTEN 0
	OCTAVE 2
	NOTE G_, 1
	ATTEN 6
	NOTE G_, 1
	ATTEN 0
	OCTAVE 1
	NOTE B_, 1
	ATTEN 6
	NOTE B_, 1
	ATTEN 0
	OCTAVE 2
	NOTE G_, 1
	ATTEN 6
	NOTE G_, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 6
	NOTE B_, 1
	ATTEN 0
	OCTAVE 3
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 6
	NOTE G_, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 0
	OCTAVE 2
	NOTE B_, 1
	ATTEN 6
	NOTE B_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 6
	NOTE G_, 1
	ATTEN 0
	OCTAVE 1
	NOTE A#, 1
	ATTEN 6
	NOTE A#, 1
	ATTEN 0
	LOOP_START
	OCTAVE 2
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 6
	NOTE G_, 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 1
	ATTEN 6
	NOTE C_, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 0
	NOTE C_, 1
	ATTEN 6
	NOTE C_, 1
	ATTEN 0
	OCTAVE 2
	NOTE G_, 1
	ATTEN 6
	NOTE G_, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 0
	LOOP_BREAK $FB
	OCTAVE 1
	NOTE A_, 1
	ATTEN 6
	NOTE A_, 1
	ATTEN 0
	LOOP_END $02
	OCTAVE 1
	NOTE F_, 1
	ATTEN 6
	NOTE F_, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 6
	NOTE B_, 1
	ATTEN 0
	OCTAVE 2
	NOTE F_, 1
	ATTEN 6
	NOTE F_, 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 1
	ATTEN 6
	NOTE C_, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 0
	NOTE C_, 1
	ATTEN 6
	NOTE C_, 1
	ATTEN 0
	OCTAVE 2
	NOTE F_, 1
	ATTEN 6
	NOTE F_, 1
	ATTEN 0
	OCTAVE 1
	NOTE B_, 1
	ATTEN 6
	NOTE B_, 1
	ATTEN 0
	OCTAVE 1
	NOTE G_, 1
	ATTEN 6
	NOTE G_, 1
	ATTEN 0
	OCTAVE 2
	NOTE D_, 1
	ATTEN 6
	NOTE D_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 6
	NOTE G_, 1
	ATTEN 0
	OCTAVE 3
	NOTE D_, 1
	ATTEN 6
	NOTE D_, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 6
	NOTE D_, 1
	ATTEN 0
	OCTAVE 2
	NOTE G_, 1
	ATTEN 6
	NOTE G_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 6
	NOTE D_, 1
	ATTEN 0
	OCTAVE 1
	NOTE G#, 1
	ATTEN 6
	NOTE G#, 1
	ATTEN 0
	OCTAVE 2
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 0
	NOTE G#, 1
	ATTEN 6
	NOTE G#, 1
	ATTEN 0
	OCTAVE 3
	NOTE C_, 1
	ATTEN 6
	NOTE C_, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 0
	NOTE C_, 1
	ATTEN 6
	NOTE C_, 1
	ATTEN 0
	OCTAVE 2
	NOTE G#, 1
	ATTEN 6
	NOTE G#, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 6
	NOTE D#, 1
	ATTEN 0
	OCTAVE 1
	NOTE G_, 1
	ATTEN 6
	NOTE G_, 1
	ATTEN 0
	OCTAVE 2
	NOTE D_, 1
	ATTEN 6
	NOTE D_, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 6
	NOTE F_, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 6
	NOTE B_, 1
	ATTEN 0
	OCTAVE 3
	NOTE D_, 1
	ATTEN 6
	NOTE D_, 1
	ATTEN 0
	OCTAVE 2
	NOTE G#, 1
	ATTEN 6
	NOTE G#, 1
	ATTEN 0
	NOTE F_, 1
	ATTEN 6
	NOTE F_, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 6
	NOTE D_, 1
	ATTEN 0
	SND_LOOP

Snd85_Ch1:
	SND_SEGNO
	VOICE $07, 0, 8, 10, 2
	TRANSPOSE_UP 2
	OCTAVE 4
	NOTE D#, 2
	PAN_LEFT 0
	DETUNE $FE
	DUTY 8
	OCTAVE 4
	NOTE D#, 2
	PAN_RIGHT 0
	NOTE C_HI, 2
	DETUNE $00
	PAN_BOTH 0
	DUTY 0
	LOOP_START
	VIBRATO $04, 0, 1
	RELEASE 0, 0
	NOTE D#, 1
	VIBRATO $01, 0, 2
	NOTE D#, 3
	VIBRATO_OFF
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	LOOP_BREAK $FB
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE G#, 2
	NOTE G_, 2
	DUTY 8
	ATTEN 2
	OCTAVE 4
	VIBRATO $01, 2, 3
	NOTE G_, 4
	VIBRATO $04, 0, 1
	OCTAVE 5
	NOTE D_, 4
	VIBRATO $01, 4, 2
	NOTE D#, 0
	NOTE D_, 0
	VIBRATO_OFF
	RELEASE 5, 5
	NOTE C_, 6
	DUTY 0
	ATTEN 0
	OCTAVE 4
	LOOP_END $02
	VIBRATO $01, 1, 5
	NOTE G_, 4
	VIBRATO $04, 0, 2
	NOTE G#, 2
	VIBRATO_OFF
	NOTE G_, 2
	NOTE G#, 2
	NOTE B_, 2
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE C_, 2
	VIBRATO_OFF
	OCTAVE 3
	NOTE B_, 2
	RELEASE $0A, 2
	NOTE G#, 2
	PAN_LEFT 0
	DUTY 8
	DETUNE $FE
	OCTAVE 4
	NOTE D#, 2
	PAN_RIGHT 0
	OCTAVE 5
	NOTE C_, 2
	DETUNE $00
	PAN_BOTH 0
	DUTY 0
	RELEASE 0, 0
	VIBRATO $04, 0, 2
	OCTAVE 4
	NOTE D#, 2
	VIBRATO $01, 3, 3
	NOTE D#, 10
	VIBRATO_OFF
	NOTE D_, 2
	VIBRATO $01, 1, 2
	NOTE D#, 4
	VIBRATO_OFF
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE G#, 2
	SND_LOOP

Snd85_Ch3:
	SND_SEGNO
	LOOP_START
	VOICE $07, 5, 2, 10, 2
	TRANSPOSE_UP 2
	OCTAVE 5
	NOTE G_, 2
	WAVE $0B
	ATTEN 0
	PAN_LEFT 0
	NOTE D#, 2
	PAN_RIGHT 0
	NOTE C_HI, 2
	RELEASE 0, 0
	PAN_BOTH 0
	WAVE 5
	VIBRATO $04, 0, 1
	NOTE G_, 1
	VIBRATO $01, 0, 1
	NOTE G_, 3
	VIBRATO_OFF
	NOTE F#, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 4
	NOTE B_, 2
	OCTAVE 5
	NOTE C_, 2
	NOTE D_, 2
	VIBRATO $04, 0, 1
	NOTE D#, 2
	VIBRATO_OFF
	NOTE D_, 2
	RELEASE $0A, 2
	NOTE C_, 2
	ATTEN 0
	PAN_LEFT 0
	WAVE $0B
	NOTE D#, 2
	PAN_RIGHT 0
	OCTAVE 6
	NOTE C_, 2
	OCTAVE 5
	RELEASE 0, 0
	PAN_BOTH 0
	WAVE 5
	VIBRATO $04, 0, 2
	NOTE G_, 2
	VIBRATO $01, 3, 2
	NOTE G_, 8
	LOOP_BREAK $FB
	VIBRATO_OFF
	ATTEN 0
	WAVE $0B
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 1
	NOTE D#, 1
	ATTEN 0
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	OCTAVE 4
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 0
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	LOOP_END $02
	VIBRATO $04, 0, 1
	NOTE G#, 2
	VIBRATO $01, 2, 2
	NOTE G#, 6
	VIBRATO $01, 2, 2
	NOTE B_, 6
	VIBRATO $03, 0, 1
	RELEASE $0F, 6
	NOTE B_, 2
	VIBRATO_OFF
	SND_LOOP

Snd85_Drm:
	LEN_UNIT $07
	SND_SEGNO
	LOOP2_START
	DRUM $0C, 2
	DRUM 7, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 7, 2
	DRUM $0A, 4
	LOOP_START
	DRUM 9, 2
	DRUM 7, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM $0B, 2
	DRUM 7, 2
	DRUM $0A, 4
	LOOP_END $02
	DRUM 9, 2
	DRUM 7, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM $0B, 2
	LOOP_BREAK $FC
	DRUM 7, 2
	DRUM $0A, 4
	LOOP2_END $02
	DRUM $0B, 2
	DRUM $0B, 1
	DRUM $0B, 1
	DRUM $0B, 2
	SND_LOOP

Snd86_Ch2:
	SND_SEGNO
	VOICE $08, 4, 10, 9, 3
	OCTAVE 4
	NOTE C_, 2
	PAN_RIGHT 0
	ATTEN 4
	NOTE C_, 2
	ATTEN 0
	PAN_BOTH 0
	NOTE D_, 2
	PAN_RIGHT 0
	ATTEN 4
	NOTE D_, 2
	ATTEN 0
	PAN_BOTH 0
	NOTE D#, 2
	PAN_RIGHT 0
	ATTEN 4
	NOTE D#, 2
	ATTEN 0
	PAN_BOTH 0
	RELEASE $0D, 2
	NOTE F#, 1
	PAN_RIGHT 0
	ATTEN 4
	NOTE F#, 1
	ATTEN 0
	PAN_BOTH 0
	RELEASE 0, 0
	VIBRATO $01, 3, 2
	NOTE G_, 12
	RELEASE $0C, 2
	VIBRATO_OFF
	RELEASE 0, 0
	NOTE F#, 1
	PAN_RIGHT 0
	ATTEN 4
	NOTE F#, 1
	ATTEN 0
	PAN_BOTH 0
	NOTE D#, 1
	PAN_RIGHT 0
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	PAN_BOTH 0
	NOTE C_, 1
	PAN_RIGHT 0
	ATTEN 4
	NOTE C_, 1
	ATTEN 0
	PAN_BOTH 0
	RELEASE 9, 3
	OCTAVE 3
	NOTE A_, 2
	PAN_RIGHT 0
	ATTEN 4
	NOTE A_, 2
	ATTEN 0
	PAN_BOTH 0
	NOTE F#, 2
	PAN_RIGHT 0
	ATTEN 4
	NOTE F#, 2
	ATTEN 0
	PAN_BOTH 0
	NOTE A_, 2
	PAN_RIGHT 0
	ATTEN 4
	NOTE A_, 2
	ATTEN 0
	PAN_BOTH 0
	OCTAVE 4
	NOTE D_, 2
	PAN_RIGHT 0
	ATTEN 4
	NOTE D_, 2
	ATTEN 0
	PAN_BOTH 0
	NOTE C_, 2
	PAN_RIGHT 0
	ATTEN 4
	NOTE C_, 2
	ATTEN 0
	PAN_BOTH 0
	OCTAVE 3
	NOTE B_, 2
	PAN_RIGHT 0
	ATTEN 4
	NOTE B_, 2
	ATTEN 0
	PAN_BOTH 0
	NOTE A#, 2
	PAN_RIGHT 0
	ATTEN 4
	NOTE A#, 2
	ATTEN 0
	PAN_BOTH 0
	NOTE B_, 2
	PAN_RIGHT 0
	ATTEN 4
	NOTE B_, 2
	ATTEN 0
	PAN_BOTH 0
	SND_LOOP

Snd86_Ch1:
	SND_SEGNO
	VOICE $08, 4, 8, 9, 3
	OCTAVE 3
	NOTE G_, 2
	PAN_LEFT 0
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	PAN_BOTH 0
	NOTE B_, 2
	PAN_LEFT 0
	ATTEN 4
	NOTE B_, 2
	ATTEN 0
	PAN_BOTH 0
	OCTAVE 4
	NOTE C_, 2
	PAN_LEFT 0
	ATTEN 4
	NOTE C_, 2
	ATTEN 0
	PAN_BOTH 0
	RELEASE 0, 0
	NOTE D_, 1
	PAN_LEFT 0
	ATTEN 4
	NOTE D_, 1
	ATTEN 0
	PAN_BOTH 0
	NOTE D#, 1
	PAN_LEFT 0
	ATTEN 4
	NOTE D#, 1
	ATTEN 0
	PAN_BOTH 0
	RELEASE 9, 3
	DUTY 8
	OCTAVE 4
	NOTE C_, 2
	PAN_RIGHT 0
	ATTEN 4
	NOTE C_, 2
	ATTEN 0
	PAN_BOTH 0
	OCTAVE 3
	NOTE B_, 2
	PAN_RIGHT 0
	ATTEN 4
	NOTE B_, 2
	ATTEN 0
	PAN_BOTH 0
	OCTAVE 4
	NOTE C_, 2
	PAN_RIGHT 0
	ATTEN 4
	NOTE C_, 2
	ATTEN 0
	PAN_BOTH 0
	RELEASE 0, 0
	OCTAVE 3
	NOTE B_, 1
	PAN_RIGHT 0
	ATTEN 4
	NOTE B_, 1
	ATTEN 0
	PAN_BOTH 0
	NOTE G#, 1
	PAN_LEFT 0
	ATTEN 4
	NOTE G#, 1
	ATTEN 0
	PAN_BOTH 0
	RELEASE 9, 3
	NOTE F#, 2
	PAN_LEFT 0
	ATTEN 4
	NOTE F#, 2
	ATTEN 0
	PAN_BOTH 0
	RELEASE 0, 0
	VIBRATO $01, 3, 3
	NOTE D_, 8
	RELEASE $0C, 2
	VIBRATO_OFF
	RELEASE 0, 0
	NOTE F#, 1
	PAN_LEFT 0
	ATTEN 4
	NOTE F#, 1
	ATTEN 0
	PAN_BOTH 0
	NOTE A_, 1
	PAN_LEFT 0
	ATTEN 4
	NOTE A_, 1
	ATTEN 0
	PAN_BOTH 0
	RELEASE 9, 3
	NOTE G_, 2
	PAN_LEFT 0
	ATTEN 4
	NOTE G_, 2
	ATTEN 0
	PAN_BOTH 0
	DUTY 8
	ATTEN 1
	NOTE C_HI, 2
	PAN_LEFT 0
	ATTEN 4
	NOTE C_HI, 2
	ATTEN 0
	PAN_BOTH 0
	ATTEN 1
	OCTAVE 4
	NOTE F#, 2
	PAN_LEFT 0
	ATTEN 4
	NOTE F#, 2
	ATTEN 0
	PAN_BOTH 0
	ATTEN 1
	NOTE F_, 2
	PAN_LEFT 0
	ATTEN 4
	NOTE F_, 2
	ATTEN 0
	PAN_BOTH 0
	SND_LOOP

Snd86_Ch3:
	SND_SEGNO
	VOICE $08, 1, 2, 11, 3
	WAVE 3
	OCTAVE 2
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	WAVE $0B
	OCTAVE 3
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	OCTAVE 4
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 1
	NOTE D#, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 1
	NOTE D#, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	WAVE 3
	OCTAVE 2
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	WAVE $0B
	OCTAVE 3
	NOTE D#, 1
	ATTEN 1
	NOTE D#, 1
	ATTEN 0
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	OCTAVE 4
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	NOTE D#, 1
	ATTEN 1
	NOTE D#, 1
	ATTEN 0
	NOTE G#, 1
	ATTEN 1
	NOTE G#, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	OCTAVE 4
	NOTE D#, 1
	ATTEN 1
	NOTE D#, 1
	ATTEN 0
	WAVE 3
	OCTAVE 2
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	WAVE $0B
	OCTAVE 3
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	OCTAVE 4
	NOTE C_, 1
	ATTEN 1
	NOTE C_, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	NOTE A_, 1
	ATTEN 1
	NOTE A_, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	WAVE 3
	OCTAVE 2
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	WAVE $0B
	OCTAVE 3
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	NOTE B_, 1
	ATTEN 1
	NOTE B_, 1
	ATTEN 0
	OCTAVE 4
	NOTE D_, 1
	ATTEN 1
	NOTE D_, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	NOTE F#, 1
	ATTEN 1
	NOTE F#, 1
	ATTEN 0
	NOTE G_, 1
	ATTEN 1
	NOTE G_, 1
	ATTEN 0
	SND_LOOP

Snd86_Drm:
	LEN_UNIT $08
	SND_SEGNO
	DRUM $0C, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM $0A, 4
	DRUM 3, 2
	DRUM 9, 2
	DRUM 8, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 7, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 8, 2
	DRUM 7, 2
	DRUM 7, 1
	DRUM 8, 1
	DRUM 3, 2
	DRUM 3, 2
	SND_LOOP

Snd87_Ch2:
	VOICE $05, 0, 10, 0, 0
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	RELEASE $0A, 5
	VIBRATO $01, 2, 3
	NOTE C_HI, 0
	SND_END

Snd87_Ch1:
	VOICE $05, 0, 10, 0, 0
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE C_HI, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	RELEASE $0A, 5
	VIBRATO $01, 2, 4
	NOTE C_HI, 0
	SND_END

Snd87_Ch3:
	VOICE $05, 7, 2, 0, 0
	OCTAVE 5
	NOTE F#, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE C_HI, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE C_HI, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE F#, 1
	RELEASE 6, 7
	VIBRATO $01, 2, 5
	NOTE C_HI, 0
	SND_END

Snd87_Drm:
	LEN_UNIT $05
	DRUM_SND $0E, 0
	SND_END

Snd88_Ch2:
	VOICE $07, 8, 13, 0, 0
	DETUNE $04
	SND_SEGNO
	VIBRATO $01, 6, 5
	OCTAVE 2
	NOTE C_, 13
	VIBRATO $01, 0, 5
	RELEASE $0F, 5
	NOTE C_, 7
	VIBRATO $07, 0, 6
	RELEASE 0, 0
	NOTE C#, 4
	VIBRATO $01, 2, 5
	NOTE C_, 4
	OCTAVE 1
	NOTE B_, 4
	VIBRATO $01, 6, 6
	NOTE G#, 13
	VIBRATO $01, 0, 5
	RELEASE $0F, 5
	NOTE G#, 7
	VIBRATO $01, 2, 5
	RELEASE 0, 0
	NOTE B_, 4
	OCTAVE 2
	NOTE C_, 4
	NOTE C#, 4
	VIBRATO $01, 6, 5
	OCTAVE 2
	NOTE C_, 13
	VIBRATO $01, 0, 5
	RELEASE $0F, 5
	NOTE C_, 7
	VIBRATO $01, 2, 5
	RELEASE 0, 0
	NOTE C_, 4
	NOTE C#, 4
	OCTAVE 1
	NOTE B_, 4
	VIBRATO $01, 5, 7
	NOTE G#, 8
	ATTEN 2
	NOTE G_, 8
	ATTEN 0
	NOTE F#, 8
	OCTAVE 2
	VIBRATO $07, 0, 5
	ENVELOPE $01
	ATTEN 5
	NOTE D_, 4
	ATTEN 0
	VIBRATO $01, 0, 5
	NOTE D_, 4
	ENVELOPE $00
	SND_LOOP

Snd88_Ch1:
	VOICE $07, 8, 6, 0, 0
	DETUNE $FC
	REST 2
	SND_SEGNO
	VIBRATO $01, 6, 5
	OCTAVE 2
	NOTE C_, 13
	VIBRATO $01, 0, 5
	RELEASE $0F, 5
	NOTE C_, 7
	VIBRATO $07, 0, 6
	RELEASE 0, 0
	NOTE C#, 4
	VIBRATO $01, 2, 5
	NOTE C_, 4
	OCTAVE 1
	NOTE B_, 4
	VIBRATO $01, 6, 6
	NOTE G#, 13
	VIBRATO $01, 0, 5
	RELEASE $0F, 5
	NOTE G#, 7
	VIBRATO $01, 2, 5
	RELEASE 0, 0
	NOTE B_, 4
	OCTAVE 2
	NOTE C_, 4
	NOTE C#, 4
	VIBRATO $01, 6, 5
	OCTAVE 2
	NOTE C_, 13
	VIBRATO $01, 0, 5
	RELEASE $0F, 5
	NOTE C_, 7
	VIBRATO $01, 2, 5
	RELEASE 0, 0
	NOTE C_, 4
	NOTE C#, 4
	OCTAVE 1
	NOTE B_, 4
	VIBRATO $01, 5, 7
	NOTE G#, 8
	ATTEN 2
	NOTE G_, 8
	ATTEN 0
	NOTE F#, 8
	OCTAVE 2
	VIBRATO $07, 0, 5
	ENVELOPE $01
	ATTEN 5
	NOTE D_, 4
	ATTEN 0
	VIBRATO $01, 0, 5
	NOTE D_, 4
	ENVELOPE $00
	SND_LOOP

Snd88_Ch3:
	VOICE $07, 12, 2, 13, 5
	SND_SEGNO
	OCTAVE 5
	NOTE G_, 2
	ATTEN 1
	NOTE G_, 2
	ATTEN 0
	NOTE F#, 2
	ATTEN 1
	NOTE F#, 2
	ATTEN 0
	NOTE D#, 2
	ATTEN 1
	NOTE D#, 2
	ATTEN 0
	NOTE F#, 2
	ATTEN 1
	NOTE F#, 2
	ATTEN 0
	SND_LOOP

Snd88_Drm:
	SND_END
