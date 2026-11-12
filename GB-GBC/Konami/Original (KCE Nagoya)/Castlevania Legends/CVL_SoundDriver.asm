; ==========================================================================
; Castlevania Legends (UE) - Konami sound driver (ROM0, banks 14 and 15)
; Byte-exact RGBDS disassembly of the driver code and all sound data. A late descendant of
; Raging Fighter's driver: ROM0 PlaySound and FarRead, two sound banks, a reworked command set.
;   ROM0: SndUpdateFar ($0098-$00AA), the sound code ($0875-$0BC0)
;   bank 14: tables, headers, drum hits ($4000-$465B), the track code ($465C-$5353), SFX ($5354-)
;   bank 15: table, headers, songs
; Build: rgbasm -Wall -o cvl.o CVL_SoundDriver.asm && rgblink -o cvl.gb cvl.o
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
DEF wTrkSfx1 EQU $D0A0 ; 96 bytes
DEF wTrkSfx2 EQU $D1A0 ; 96 bytes
DEF wTrkSfxN EQU $D2A0 ; 96 bytes
DEF wTrkCh1 EQU $D3A0 ; 96 bytes
DEF wTrkCh2 EQU $D4A0 ; 96 bytes
DEF wTrkCh3 EQU $D5A0 ; 96 bytes
DEF wTrkDrm EQU $D6A0 ; 96 bytes
DEF wTrackDesc EQU $D7C1
DEF wTempo EQU $D7C5
DEF wTempoAcc EQU $D7C6
DEF wReqPrio EQU $D7C7
DEF wReqId EQU $D7C8
DEF wFadeDir EQU $D7C9
DEF wFadeRate EQU $D7CA
DEF wFadeTimer EQU $D7CB
DEF wFadeStep EQU $D7CC
DEF wWaveId EQU $D7CE
DEF wD7CF EQU $D7CF
DEF wReadBuf EQU $D7D1 ; 4 bytes
DEF wWobbleMin EQU $D7D5
DEF wWobbleOn EQU $D7D6
DEF wWobbleRate EQU $D7D7
DEF wWobbleTimer EQU $D7D8
DEF wSndDim EQU $D7D9
DEF wReqHold EQU $D7DA
DEF wHeldReq EQU $D7DB
DEF wPauseFlag EQU $D7DC
DEF wRomBank EQU $C522
DEF wSndBusy EQU $C523
DEF rROMB EQU $2000

; per-track fields: track n lives at $D0A0 + n*$100, so H = $D0 + n and L = field
DEF TRK_PRIO EQU $A0
DEF TRK_ID EQU $A1
DEF TRK_PTR EQU $A2
DEF TRK_LEN EQU $A4
DEF TRK_FLAGS EQU $A5
DEF TRK_PANFLAGS EQU $A6
DEF TRK_FLOW EQU $A7
DEF TRK_A8 EQU $A8
DEF TRK_LOOPPTR EQU $A9
DEF TRK_LOOPCNT EQU $AB
DEF TRK_LOOP2PTR EQU $AC
DEF TRK_LOOP2CNT EQU $AE
DEF TRK_SEGNO EQU $AF
DEF TRK_RET EQU $B1
DEF TRK_UNIT EQU $B3
DEF TRK_ATTEN EQU $B4
DEF TRK_PERIOD EQU $B5
DEF TRK_OUTPERIOD EQU $B7
DEF TRK_VOL EQU $B9
DEF TRK_LASTVOL EQU $BA
DEF TRK_REG_NRX1 EQU $BB
DEF TRK_REG_NRX2 EQU $BC
DEF TRK_REG_NRX3 EQU $BD
DEF TRK_REG_NRX4 EQU $BE
DEF TRK_GATE EQU $BF
DEF TRK_RELTICK EQU $C0
DEF TRK_ENV EQU $C1
DEF TRK_C2 EQU $C2
DEF TRK_PAN EQU $C3
DEF TRK_VIB EQU $C4
DEF TRK_ENVNO EQU $C5
DEF TRK_DETUNE EQU $C6
DEF TRK_TRANSP EQU $C8
DEF TRK_DUTYCNT EQU $C9
DEF TRK_DUTYTICKS EQU $CA
DEF TRK_DUTYSTART EQU $CB
DEF TRK_OCTAVE EQU $CC
DEF TRK_DUTY EQU $CD
DEF TRK_CURDUTY EQU $CE
DEF TRK_VIBPTR EQU $CF
DEF TRK_ENVPTR EQU $DD
DEF TRK_ENVPOS EQU $DF
DEF TRK_ENVTIMER EQU $E1
DEF TRK_ENVLOOPPTR EQU $E2
DEF TRK_ENVLOOPCNT EQU $E4
DEF TRK_ENVMARK EQU $E5
DEF TRK_RELVOL EQU $E7
DEF TRK_SAVEPERIOD EQU $E8
DEF TRK_BREAK EQU $EA
DEF TRK_EXIT EQU $EB
DEF TRK_BREAK2 EQU $ED
DEF TRK_EXIT2 EQU $EE
DEF TRK_PITCHIDX EQU $F0
DEF TRK_SLIDEPTR EQU $F1
DEF TRK_SLIDECNT EQU $F3
DEF TRK_F4 EQU $F4
DEF TRK_SLIDEATTCNT EQU $F5
DEF TRK_SLIDEOFS EQU $F6
DEF TRK_MUTE EQU $FF

; TRK_FLAGS: 1 note-volume mode, 2/5 channel given back, 4 tempo skip, 6/7 noise volume pending
; TRK_PANFLAGS: 0 autopan, 1 autopan side, 3 envelope running, 5 note-volume slide, 6 autopan both,
;   7 set by $EA Cx
; TRK_FLOW: 0 loop 1, 1 loop 2, 2 in a call, 3 mark set, 6 envelope loop, 7 envelope mark

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
; drum track: hi = bank-14 drum hit id 1-13, lo = length multiplier
MACRO DRUM
	db (\1 << 4) | \2
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
; $EA Bx: wReqHold = x (bit 0: requests are dropped)
MACRO HOLD_REQ
	db $EA, $B0 | \1
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
MACRO TEMPO
	db $EE, \1
ENDM
; note-volume mode: $EE marks; $EE x y n goes back to the mark until the n-th pass, sliding the pitch by
; x and the attenuation by y each pass (x, y, n are read from bank 14)
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

SECTION "SndUpdateFar", ROM0[$0098]

; SndUpdateFar (from the VBlank handler): SndUpdate unless wSndBusy bit 0 or 1 is set.
SndUpdateFar:
	ld hl, wSndBusy
	ld a, [hl]
	and $03
	jr nz, .l00AA
	set 0, [hl]
	call SndUpdate
	ld hl, wSndBusy
	res 0, [hl]
.l00AA:
	ret

SECTION "Sound ROM0", ROM0[$0875]

; PlaySoundFar: A = sound id (0 = stop all). Sets wSndBusy bit 1, PlaySound, maps the game's
; bank again (wRomBank).
PlaySoundFar:
	push hl
	ld hl, wSndBusy
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
	ld hl, wSndBusy
	res 1, [hl]
	pop hl
	ret

; FarRead: map bank 15 (TRK_ID >= $50) or 14 and copy 4 stream bytes from DE into wReadBuf;
; bank 14 is mapped again. Every stream read of the track code goes through here.
FarRead:
	push af
	ld l, TRK_ID
	ld a, [hl]
	cp $50
	jp c, .l08A2
	ld a, $0F
	ld [rROMB], a
	pop af
	jr FarReadCopy
.l08A2:
	ld a, $0E
	ld [rROMB], a
	pop af

FarReadCopy:
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
	ld a, $0E
	ld [rROMB], a
	pop de
	ret

; SndInit: NR50 = $77, NR51 = $FF, NR52 = $80, and the register addresses of tracks 0-5
; (the drum track keeps 0, so its register writes go to $FF00).
SndInit:
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

; PlaySound: wReqId = id. 0: StopAll (bank 14). While wReqHold bit 0 is set the id goes to
; wHeldReq (never read) and nothing happens. Else NR50 = $77 unless wSndDim is set or a fade
; runs; the header comes from bank 14 (ids < $50, SoundTable) or bank 15 (SoundTable15, index
; id - $50). If any SFX track of the mask holds a higher priority nothing starts. Music needs
; the Ch1 bit and a priority >= Ch1's; it resets the tempo and (unless a fade runs) the fade.
PlaySound:
	ld [wReqId], a
	or a
	jr nz, .l0906
	ld a, $0E
	ld [rROMB], a
	jp StopAll
.l0906:
	ld hl, wReqHold
	bit 0, [hl]
	jr z, PlaySoundGo
	ld [wHeldReq], a
	ret

PlaySoundGo:
	xor a
	ld [wWobbleOn], a
	ld a, [wSndDim]
	bit 0, a
	jr nz, .l0939
	ld a, [wFadeDir]
	or a
	jr z, .l092F
	bit 0, a
	jr z, .l0939
	res 0, a
	set 0, a
	ld [wFadeDir], a
	jr .l0939
.l092F:
	ld c, $24
	ldh a, [c]
	cp $77
	jr z, .l0939
	ld a, $77
	ldh [c], a
.l0939:
	ld a, [wReqId]
	ld b, a
	cp $50
	jr nc, PlaySound15
	ld a, $0E
	ld [rROMB], a
	ld a, b
	ld hl, SoundTable - 2
	jp ReadHeader

PlaySound15:
	ld a, $0F
	ld [rROMB], a
	ld a, b
	ld hl, SoundTable15 - 2
	sub $50

ReadHeader:
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
	ld [wD7CF], a
	srl b
	ret nc
	ld hl, wTrkCh1
	ld a, [wReqPrio]
	cp [hl]
	ret c
	ld a, [wFadeDir]
	or a
	ld a, $00
	jr nz, .l09B1
	ld [wFadeRate], a
	ld [wFadeTimer], a
.l09B1:
	ld [wFadeStep], a
	ld [wTempo], a
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

; StartTrack: priority, id, pointer, LEN 1, and the flag, flow, envelope, loop-break and
; slide fields cleared; wWaveId, wHeldReq, wReqHold = 0. No register writes (Sfx1: NR10 = 8,
; SfxN: NR51 |= $88).
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
	ld [wWaveId], a
	ld [wHeldReq], a
	ld [wReqHold], a
	ret

CheckSfxPrio:
	cp [hl]
	ret nc
	ld b, $00
	ret

StartSfxTrack:
	call StartTrack
	ld a, $D0
	cp h
	jr nz, .l0A27
	ld a, $08
	ld c, $10
	ldh [c], a
.l0A27:
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

; SndUpdate (once per VBlank): while wPauseFlag is 1 only CH2 is muted and the SFX tracks run.
; Else FadeCheck/FadeTick, WobbleTick, TempoTick, then Ch1, Ch2, Ch3, Drm, SfxN, Sfx2, Sfx1, each
; through RunTrack (bank 14, TrackTick); last the game's bank (wRomBank).
SndUpdate:
	ld a, [wPauseFlag]
	cp $01
	jp nz, UpdateAll
	call PauseMuteCh2
	jp UpdateSfx

UpdateAll:
	call FadeCheck
	call WobbleTick
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
	ld a, [wRomBank]
	ld [rROMB], a
	ret

RunTrack:
	ld [wTrackDesc], a
	ld l, TRK_ID
	ld a, [hl]
	or a
	ret z
	ld a, $0E
	ld [rROMB], a
	jp TrackTick

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
	jp c, .l0AB7
	res 4, [hl]
	inc h
	res 4, [hl]
	inc h
	res 4, [hl]
	inc h
	res 4, [hl]
	ret
.l0AB7:
	set 4, [hl]
	inc h
	set 4, [hl]
	inc h
	set 4, [hl]
	inc h
	set 4, [hl]
	ret

; FadeCheck: nothing while music Ch3 is idle; wReqHold bit 2 ends a fade. FadeTick: every
; wFadeRate updates NR50 + $11 up to $77 (wFadeDir bit 0, a fade-in) or - $11 down to $11, then
; wFadeStep counts: $10 stops Drm, $18 Ch1, $1C Ch2, $20 Ch3. Nothing in the driver's live code
; starts a fade (only StartFadeOut/StartFadeIn and EndFadeIn, none of them reached, set wFadeRate).
FadeCheck:
	ld h, HIGH(wTrkCh3)
	ld l, TRK_ID
	ld a, [hl]
	or a
	ret z
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
	jr z, FadeStopDrm
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
	jr nz, .l0B36
	ld c, $1A
	ldh [c], a
	ld c, $1C
	ldh [c], a
.l0B36:
	ld h, HIGH(wTrkCh3)
	ld [wFadeStep], a
	ld [wFadeRate], a
	ld [wFadeTimer], a
	jr FadeStopTrack

FadeStopCh1:
	ld h, HIGH(wTrkSfx1)
	ld l, TRK_ID
	ld a, [hl]
	or a
	jr nz, .l0B55
	ld a, $08
	ld c, $12
	ldh [c], a
	ld a, $80
	ld c, $14
	ldh [c], a
.l0B55:
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

FadeStopDrm:
	ld h, HIGH(wTrkDrm)

FadeStopTrack:
	ld l, TRK_ID
	xor a
	ld [hl-], a
	ld [hl], a
	ret

; WobbleTick ($EA Ax y): every wWobbleRate updates NR50 moves one step: the right volume down
; to wWobbleMin, then back up, then the left one, and so on.
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
	ld l, $D6
	bit 1, [hl]
	ld c, $24
	ldh a, [c]
	jr nz, .l0B93
	dec l
	and $0F
	cp [hl]
	jr nz, .l0B9E
	inc l
	set 1, [hl]
.l0B8E:
	ldh a, [c]
	sub $0F
	ldh [c], a
	ret
.l0B93:
	swap a
	dec l
	and $0F
	cp [hl]
	jr nz, .l0B8E
	inc l
	res 1, [hl]
.l0B9E:
	ldh a, [c]
	add a, $0F
	cp $80
	jr c, .l0BA7
	sub $10
.l0BA7:
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

PauseMuteCh2:
	xor a
	ld a, $08
	ld c, $17
	ldh [c], a
	ld a, $80
	ld c, $19
	ldh [c], a
	ret

SECTION "Sound bank 14", ROMX[$4000], BANK[14]

; SoundTable: bank-14 ids $01-$42 (the code adds 2 * id to $3FFE).
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
	SND_HEADER $20, $05 ; tracks: Sfx1, SfxN
	dw Snd06_Sfx1
	dw Snd06_SfxN

SndHdr07:
	SND_HEADER $20, $05 ; tracks: Sfx1, SfxN
	dw Snd07_Sfx1
	dw Snd07_SfxN

SndHdr08:
	SND_HEADER $20, $05 ; tracks: Sfx1, SfxN
	dw Snd08_Sfx1
	dw Snd08_SfxN

SndHdr09:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd09_SfxN

SndHdr0A:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd0A_SfxN

SndHdr0B:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd0B_SfxN

SndHdr0C:
	SND_HEADER $20, $04 ; tracks: SfxN
	dw Snd0C_SfxN

SndHdr0D:
	SND_HEADER $FF, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd0D_Sfx1
	dw Snd0D_Sfx2
	dw Snd0D_Sfx2

SndHdr0E:
	SND_HEADER $A0, $04 ; tracks: SfxN
	dw Snd0E_SfxN

SndHdr0F:
	SND_HEADER $A0, $04 ; tracks: SfxN
	dw Snd0F_SfxN

SndHdr16:
	SND_HEADER $B0, $01 ; tracks: Sfx1
	dw Snd16_Sfx1

SndHdr18:
	SND_HEADER $A8, $05 ; tracks: Sfx1, SfxN
	dw Snd18_Sfx1
	dw Snd18_SfxN

SndHdr22:
	SND_HEADER $C0, $01 ; tracks: Sfx1
	dw Snd22_Sfx1

SndHdr17:
	SND_HEADER $C0, $38 ; tracks: Ch1, Ch2, Ch3
	dw Snd17_Ch1
	dw Snd17_Ch2
	dw Snd17_Ch3

SndHdr19:
	SND_HEADER $A8, $04 ; tracks: SfxN
	dw Snd19_SfxN

SndHdr10:
	SND_HEADER $A0, $04 ; tracks: SfxN
	dw Snd10_SfxN

SndHdr1A:
	SND_HEADER $C0, $04 ; tracks: SfxN
	dw Snd1A_SfxN

SndHdr11:
	SND_HEADER $C0, $01 ; tracks: Sfx1
	dw Snd11_Sfx1

SndHdr12:
	SND_HEADER $C0, $01 ; tracks: Sfx1
	dw Snd12_Sfx1

SndHdr13:
	SND_HEADER $C0, $01 ; tracks: Sfx1
	dw Snd13_Sfx1

SndHdr14:
	SND_HEADER $C0, $01 ; tracks: Sfx1
	dw Snd14_Sfx1

SndHdr15:
	SND_HEADER $C0, $01 ; tracks: Sfx1
	dw Snd15_Sfx1

SndHdr1B:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd1B_Sfx1
	dw Snd1B_SfxN

SndHdr1C:
	SND_HEADER $90, $05 ; tracks: Sfx1, SfxN
	dw Snd1C_Sfx1
	dw Snd1C_SfxN

SndHdr1D:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw Snd1D_Sfx1
	dw Snd1D_SfxN

SndHdr1E:
	SND_HEADER $B0, $05 ; tracks: Sfx1, SfxN
	dw Snd1E_Sfx1
	dw Snd1E_SfxN

SndHdr1F:
	SND_HEADER $C0, $05 ; tracks: Sfx1, SfxN
	dw Snd1F_Sfx1
	dw Snd1F_SfxN

SndHdr20:
	SND_HEADER $C0, $05 ; tracks: Sfx1, SfxN
	dw Snd20_Sfx1
	dw Snd20_SfxN

SndHdr21:
	SND_HEADER $C0, $05 ; tracks: Sfx1, SfxN
	dw Snd21_Sfx1
	dw Snd21_SfxN

SndHdr23:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd23_Sfx1

; An unreferenced header (prio $A0, Sfx1 + Sfx2).
	db $A0, $03, $BB, $55, $CE, $55

SndHdr24:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw Snd24_Sfx1
	dw Snd24_Sfx1

SndHdr25:
	SND_HEADER $A0, $04 ; tracks: SfxN
	dw Snd25_SfxN

SndHdr26:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd26_Sfx1

SndHdr27:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd27_Sfx1

SndHdr28:
	SND_HEADER $B0, $04 ; tracks: SfxN
	dw Snd28_SfxN

SndHdr29:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd29_Sfx1

SndHdr2A:
	SND_HEADER $A0, $04 ; tracks: SfxN
	dw Snd2A_SfxN

SndHdr2B:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd2B_Sfx1

SndHdr2C:
	SND_HEADER $A0, $04 ; tracks: SfxN
	dw Snd2C_SfxN

SndHdr2D:
	SND_HEADER $C0, $05 ; tracks: Sfx1, SfxN
	dw Snd2D_Sfx1
	dw Snd2D_SfxN

SndHdr2E:
	SND_HEADER $A0, $04 ; tracks: SfxN
	dw Snd2E_SfxN

SndHdr2F:
	SND_HEADER $C0, $01 ; tracks: Sfx1
	dw Snd2F_Sfx1

SndHdr30:
	SND_HEADER $A0, $04 ; tracks: SfxN
	dw Snd30_SfxN

SndHdr31:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd31_Sfx1

SndHdr32:
	SND_HEADER $A0, $01 ; tracks: Sfx1
	dw Snd32_Sfx1

SndHdr33:
	SND_HEADER $C0, $03 ; tracks: Sfx1, Sfx2
	dw Snd33_Sfx1
	dw Snd33_Sfx2

SndHdr34:
	SND_HEADER $A0, $04 ; tracks: SfxN
	dw Snd34_SfxN

SndHdr35:
	SND_HEADER $C0, $04 ; tracks: SfxN
	dw Snd35_SfxN

SndHdr36:
	SND_HEADER $A0, $04 ; tracks: SfxN
	dw Snd36_SfxN

SndHdr37:
	SND_HEADER $A0, $05 ; tracks: Sfx1, SfxN
	dw Snd37_Sfx1
	dw Snd37_SfxN

SndHdr38:
	SND_HEADER $A0, $04 ; tracks: SfxN
	dw Snd38_SfxN

SndHdr39:
	SND_HEADER $B0, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd39_Sfx1
	dw Snd39_Sfx2
	dw Snd39_SfxN

SndHdr3A:
	SND_HEADER $D0, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd3A_Sfx1
	dw Snd3A_Sfx2
	dw Snd3A_SfxN

SndHdr3B:
	SND_HEADER $D0, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd3B_Sfx1
	dw Snd3B_Sfx2
	dw Snd3B_SfxN

SndHdr3C:
	SND_HEADER $D0, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd3C_Sfx1
	dw Snd3C_Sfx2
	dw Snd3C_SfxN

SndHdr3D:
	SND_HEADER $D0, $04 ; tracks: SfxN
	dw Snd3D_SfxN

SndHdr41:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd41_Ch1
	dw Snd41_Ch2
	dw Snd41_Ch3
	dw Snd41_Drm

SndHdr42:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd42_Ch1
	dw Snd42_Ch2
	dw Snd42_Ch3
	dw Snd42_Drm

SndHdr3E:
	SND_HEADER $A0, $04 ; tracks: SfxN
	dw Snd3E_SfxN

; An unreferenced header (prio $A0, Ch1-Ch3).
	db $A0, $38, $08, $5C, $27, $5C, $3A, $5C

SndHdr3F:
	SND_HEADER $F0, $07 ; tracks: Sfx1, Sfx2, SfxN
	dw Snd0D_Sfx2
	dw Snd0D_Sfx2
	dw Snd0D_Sfx2

SndHdr40:
	SND_HEADER $F0, $02 ; tracks: Sfx2
	dw Snd0D_Sfx2

; WaveTable: 15 waves (wave n = the high nibble of the duty byte; from WaveTable - 2).
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
	dw Wave11 ; wave 11
	dw Wave12 ; wave 12
	dw Wave13 ; wave 13
	dw Wave14 ; wave 14
	dw Wave15 ; wave 15
Wave1:
	db $13, $57, $9B, $97, $53, $11, $35, $79, $BD, $FD, $B9, $75, $31, $13, $53, $10
Wave2:
	db $13, $57, $9B, $DF, $FD, $B9, $75, $31, $13, $57, $9B, $DF, $FD, $B9, $75, $31
Wave3:
	db $88, $88, $88, $88, $88, $88, $88, $88, $00, $00, $00, $00, $00, $00, $00, $00
Wave4:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $01, $23, $45, $67, $89, $AB, $CD, $EF
Wave5:
	db $88, $80, $8F, $FF, $88, $80, $88, $80, $00, $08, $08, $88, $80, $00, $80, $00
Wave6:
	db $23, $34, $56, $67, $89, $9A, $BC, $DE, $23, $34, $56, $67, $89, $9A, $BC, $DE
Wave7:
	db $7E, $C9, $CE, $A7, $CF, $E8, $AB, $72, $8D, $75, $72, $03, $85, $13, $63, $17
Wave8:
	db $99, $99, $99, $99, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Wave9:
	db $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
Wave10:
	db $03, $34, $56, $67, $89, $9A, $BC, $DF, $03, $34, $56, $67, $89, $9A, $BC, $DF
Wave11:
	db $BD, $DB, $98, $9C, $EF, $EB, $76, $68, $AA, $94, $21, $24, $88, $53, $35, $8B
Wave12:
	db $23, $34, $56, $67, $89, $9A, $BC, $DE, $23, $34, $56, $67, $89, $9A, $BC, $DE
Wave13:
	db $7E, $C9, $CE, $A7, $CF, $E8, $AB, $72, $8D, $75, $72, $03, $85, $13, $63, $17
Wave14:
	db $88, $80, $8F, $FF, $88, $80, $88, $80, $00, $08, $08, $88, $80, $00, $80, $00
Wave15:
	db $9B, $B9, $76, $7A, $CD, $C9, $54, $46, $66, $74, $21, $24, $66, $53, $35, $69

; PeriodTable: 85 periods (from PeriodTable - 26 by 2 * pitch + TRK_OCTAVE + TRK_TRANSP).
PeriodTable:
	dw $020, $092, $0FE, $164, $1C4, $21E, $273, $2C3, $30F, $357, $39A, $3D9 ; octave index 0
	dw $415, $44D, $483, $4B5, $4E4, $511, $53B, $563, $588, $5AC, $5CD, $5ED ; octave index 1
	dw $60B, $627, $642, $65B, $673, $68A, $69F, $6B3, $6C6, $6D8, $6E9, $6F8 ; octave index 2
	dw $707, $715, $722, $72F, $73A, $745, $750, $75A, $763, $76C, $774, $77C ; octave index 3
	dw $784, $78B, $791, $797, $79D, $7A3, $7A9, $7AD, $7B2, $7B6, $7BA, $7BE ; octave index 4
	dw $7C2, $7C4, $7C8, $7CB, $7CE, $7D1, $7D3, $7D6, $7D8, $7DA, $7DC, $7DE ; octave index 5
	dw $7E0, $7E2, $7E4, $7E5, $7E7, $7E8, $7E9, $7EB, $7EC, $7ED, $7EE, $7EF ; octave index 6
	dw $7F0 ; octave index 7

; VibratoTable: 15 pointers (EB n uses entry n; from VibratoTable - 2). No data uses them.
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
	VIB_LOOP_START
	VIB_STEP 10, 0, 0
	VIB_STEP 0, 0, 0
	VIB_STEP 10, 0, 0
	VIB_STEP 1, 1, 7
	VIB_MARK
	VIB_END
	db $FF ; unreachable

Vib02:
	VIB_STEP 1, 0, 0
	VIB_STEP 0, 0, 6
	VIB_END

Vib03:
	VIB_STEP 14, 0, 0
	VIB_STEP 0, 0, 0
	VIB_STEP 10, 0, 0
	VIB_STEP 0, 0, 1
	VIB_STEP 10, 0, 0
	VIB_STEP 0, 0, 0
	VIB_LOOP_START
	VIB_STEP 7, 0, 0
	VIB_STEP 0, 0, 2
	VIB_STEP 7, 0, 0
	VIB_STEP 0, 0, 0
	VIB_MARK
	VIB_END

Vib0E:
	VIB_STEP 1, 0, 0
	VIB_STEP 0, 0, 1
	VIB_END

Vib04:
	VIB_STEP 14, 0, 0
	VIB_STEP 0, 0, 0
	VIB_STEP 1, 0, 0
	VIB_STEP 0, 0, 1
	VIB_STEP 1, 0, 0
	VIB_STEP 0, 0, 0
	VIB_LOOP_START
	VIB_STEP 6, 0, 0
	VIB_STEP 0, 0, 3
	VIB_STEP 6, 0, 0
	VIB_STEP 0, 0, 0
	VIB_MARK
	VIB_END

Vib06:
	VIB_STEP 1, 0, 0
	VIB_STEP 0, 0, 3
	VIB_END

Vib08:
	VIB_STEP 14, 0, 0
	VIB_STEP 0, 0, 0
	VIB_STEP 10, 0, 0
	VIB_STEP 0, 0, 0
	VIB_STEP 10, 0, 0
	VIB_STEP 0, 0, 0
	VIB_LOOP_START
	VIB_STEP 7, 0, 0
	VIB_STEP 0, 0, 1
	VIB_STEP 7, 0, 0
	VIB_STEP 0, 0, 0
	VIB_MARK
	VIB_END

Vib07:
	VIB_STEP 14, 0, 0
	VIB_STEP 0, 0, 0
	VIB_STEP 7, 0, 0
	VIB_STEP 0, 0, 1
	VIB_STEP 7, 0, 0
	VIB_STEP 0, 0, 0
	VIB_LOOP_START
	VIB_STEP 8, 0, 0
	VIB_STEP 0, 1, 7
	VIB_STEP 8, 0, 0
	VIB_STEP 0, 0, 0
	VIB_MARK
	VIB_END

Vib0C:
	VIB_STEP 14, 0, 0
	VIB_STEP 0, 0, 0
	VIB_STEP 7, 0, 0
	VIB_STEP 0, 0, 1
	VIB_STEP 7, 0, 0
	VIB_STEP 0, 0, 0
	VIB_LOOP_START
	VIB_STEP 8, 0, 0
	VIB_STEP 0, 1, 0
	VIB_STEP 8, 0, 0
	VIB_STEP 0, 0, 0
	VIB_MARK
	VIB_END

; Vibrato2Table: semitone-step tables (EB n | $80; from Vibrato2Table - 2). No data uses them.
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
	dw VibSemi0C ; 12 (EB 12 | $80)
	dw EnvelopeTable ; 13 (EB 13 | $80) (points at EnvelopeTable)
	dw EnvelopeTable ; 14 (EB 14 | $80) (points at EnvelopeTable)
	dw EnvelopeTable ; 15 (EB 15 | $80) (points at EnvelopeTable)
	dw EnvelopeTable ; 16 (EB 16 | $80) (points at EnvelopeTable)
VibSemi01:
	VIB_SEMI_STEP 1, $0C
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi02:
	VIB_SEMI_STEP 2, $0C
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi03:
	VIB_SEMI_STEP 2, $0E
	VIB_SEMI_STEP 2, 0
	VIB_END
VibSemi04:
	VIB_MARK
	VIB_SEMI_STEP 2, $0C
	VIB_SEMI_STEP 2, 7
	VIB_SEMI_STEP 2, 0
	VIB_MARK
VibSemi05:
	VIB_MARK
	VIB_SEMI_STEP 3, 0
	VIB_SEMI_STEP 1, 9
	VIB_MARK
VibSemi06:
	VIB_MARK
	VIB_SEMI_STEP 3, 0
	VIB_SEMI_STEP 1, $0A
	VIB_MARK
VibSemi07:
	VIB_MARK
	VIB_SEMI_STEP 2, 0
	VIB_SEMI_STEP 2, 9
	VIB_SEMI_STEP 2, $0A
	VIB_SEMI_STEP 2, 9
	VIB_SEMI_STEP 2, 0
	VIB_SEMI_STEP 2, 1
	VIB_SEMI_STEP 2, 2
	VIB_SEMI_STEP 2, 1
	VIB_MARK
VibSemi08:
	VIB_SEMI_STEP 1, $0A
	VIB_SEMI_STEP $0F, 0
	VIB_SEMI_STEP 8, 0
	VIB_MARK
	VIB_SEMI_STEP 1, 0
	VIB_SEMI_STEP 1, 9
	VIB_SEMI_STEP 1, $0A
	VIB_SEMI_STEP 1, 9
	VIB_SEMI_STEP 2, 0
	VIB_SEMI_STEP 1, 1
	VIB_SEMI_STEP 1, 2
	VIB_SEMI_STEP 2, 1
	VIB_MARK
VibSemi09:
	VIB_SEMI_STEP 1, $0D
	VIB_SEMI_STEP 1, 0
	VIB_END
VibSemi0A:
	VIB_SEMI_STEP 1, $0A
	VIB_SEMI_STEP $0F, 0
	VIB_SEMI_STEP 5, 0
	VIB_MARK
	VIB_SEMI_STEP 1, 0
	VIB_SEMI_STEP 2, 9
	VIB_SEMI_STEP 1, $0A
	VIB_SEMI_STEP 1, 9
	VIB_SEMI_STEP 1, 0
	VIB_SEMI_STEP 1, 1
	VIB_SEMI_STEP 2, 2
	VIB_SEMI_STEP 1, 1
	VIB_MARK
VibSemi0B:
	VIB_SEMI_STEP 2, $0F
	VIB_SEMI_STEP 2, $0E
	VIB_SEMI_STEP 2, $0D
	VIB_SEMI_STEP 2, $0C
	VIB_SEMI_STEP 2, $0B
	VIB_SEMI_STEP 2, $0A
	VIB_SEMI_STEP 1, 9
	VIB_SEMI_STEP 1, 8
	VIB_SEMI_STEP $0F, 0
	VIB_MARK
	VIB_SEMI_STEP 1, 0
	VIB_SEMI_STEP 1, 1
	VIB_SEMI_STEP 1, 2
	VIB_SEMI_STEP 1, 1
	VIB_SEMI_STEP 1, 0
	VIB_SEMI_STEP 1, 9
	VIB_SEMI_STEP 1, $0A
	VIB_SEMI_STEP 1, 9
	VIB_MARK
VibSemi0C:
	VIB_SEMI_STEP 1, $0A
	VIB_SEMI_STEP $0E, 0
	VIB_SEMI_STEP $0A, 0
	VIB_MARK
	VIB_SEMI_STEP 1, 0
	VIB_SEMI_STEP 2, 1
	VIB_SEMI_STEP 1, 2
	VIB_SEMI_STEP 1, 1
	VIB_SEMI_STEP 2, 0
	VIB_SEMI_STEP 1, 9
	VIB_SEMI_STEP 2, $0A
	VIB_SEMI_STEP 1, 9
	VIB_MARK

; EnvelopeTable: 23 volume envelopes (EC n, or a voice with volume 0; from EnvelopeTable - 2).
; No data uses them.
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
Env01:
	ENV_STEP 4, 5
	ENV_STEP 3, 2
	ENV_STEP 4, 3
	ENV_STEP 3, 1
	VIB_END
Env02:
	ENV_STEP 1, 7
	ENV_STEP 5, 5
	ENV_STEP 2, 1
	ENV_STEP 1, 2
	ENV_STEP 1, 1
	VIB_END
Env03:
	ENV_STEP $0A, 6
	ENV_STEP 8, 2
	ENV_STEP $0A, 4
	ENV_STEP 8, 2
	ENV_STEP $0A, 3
	ENV_STEP 8, 1
	ENV_STEP $0A, 2
	ENV_STEP 8, 1
	ENV_STEP $0A, 2
	ENV_STEP $0A, 1
	ENV_STEP $0A, 2
	ENV_STEP $0A, 1
	ENV_STEP $0A, 2
	ENV_STEP $0A, 1
	ENV_STEP $0A, 2
	ENV_STEP 8, 1
	VIB_END
Env04:
	ENV_STEP 1, 7
	ENV_STEP 3, 6
	ENV_STEP 2, 3
	ENV_STEP 5, 1
	ENV_STEP 5, 3
	ENV_STEP 7, 1
	ENV_STEP 6, 2
	ENV_STEP 6, 1
	VIB_END
Env05:
	ENV_STEP 1, 5
	ENV_STEP $0C, 4
	ENV_STEP 6, 1
	ENV_STEP 6, 3
	VIB_END
Env06:
	ENV_STEP 8, 6
	ENV_STEP 8, 3
	VIB_END
Env07:
	ENV_STEP 5, 8
	ENV_STEP 4, 1
	ENV_STEP 3, 2
	VIB_END
Env08:
	ENV_STEP 6, 8
	ENV_STEP 6, 3
	VIB_END
Env09:
	ENV_STEP $0E, 5
	ENV_STEP $0E, 5
	ENV_STEP $0E, 5
	ENV_STEP $0E, 1
	VIB_END
Env0A:
	ENV_STEP 8, 4
	ENV_STEP 8, 2
	VIB_END
Env0B:
	ENV_STEP $0C, 5
	ENV_STEP $0C, 2
	ENV_STEP $0A, 1
	VIB_END
Env0C:
	ENV_STEP $0E, 6
	ENV_STEP $0A, 2
	ENV_STEP $0C, 1
	VIB_END
Env0D:
	ENV_STEP 3, 2
	ENV_STEP 3, 3
	ENV_STEP 3, 4
	ENV_STEP $0A, 5
	ENV_STEP 3, 4
	ENV_STEP 1, 3
	VIB_END
Env0E:
	ENV_STEP $0E, 2
	ENV_STEP $0D, 4
	ENV_STEP $0E, 6
	VIB_END
Env0F:
	ENV_STEP 2, 2
	ENV_STEP 3, 3
	ENV_STEP 5, 4
	ENV_STEP 5, 5
	VIB_END
Env10:
	ENV_STEP 1, $0D
	ENV_STEP 4, $0B
	ENV_STEP 5, 4
	ENV_STEP 5, 5
	ENV_STEP 5, 2
	VIB_END
Env11:
	ENV_STEP 3, 7
	ENV_STEP 3, 6
	ENV_STEP 4, 2
	ENV_STEP 2, 1
	ENV_STEP 6, 0
	VIB_END
Env12:
	ENV_STEP 2, 5
	ENV_STEP 1, 1
	ENV_STEP 3, 2
	ENV_STEP 1, 1
	VIB_END
Env13:
	ENV_STEP 6, 2
	ENV_STEP 6, 3
	ENV_STEP $0C, 4
	ENV_STEP $0C, 5
	ENV_STEP 6, 6
	ENV_STEP 6, 7
	ENV_STEP $0C, 8
	VIB_END
Env14:
	ENV_STEP 1, 7
	ENV_STEP 4, 6
	ENV_STEP 4, 1
	ENV_STEP 3, 2
	VIB_END
Env15:
	ENV_STEP 1, 9
	ENV_STEP 7, 7
	ENV_STEP 4, 2
	ENV_STEP 8, 7
	ENV_STEP 4, 2
	ENV_STEP 6, 1
	ENV_STEP 6, 0
	VIB_END
Env16:
	ENV_STEP 1, 5
	ENV_STEP 3, 4
	ENV_STEP 2, 1
	ENV_STEP 2, 3
	ENV_STEP 8, 0
	VIB_END
Env17:
	ENV_STEP 1, 3
	ENV_STEP 1, 4
	ENV_STEP 1, 5
	ENV_STEP 2, 7
	ENV_STEP 2, 8
	ENV_STEP 4, 9
	ENV_STEP 4, 8
	VIB_END

; Drum hits (bank-14 ids $01-$0D).

Snd01_SfxN:
	NVOICE $01, $60
	NOISE $14
	NVOICE $02, $20
	NOISE $14
	NVOICE $02, $10
	NOISE $15
	SND_END

Snd02_SfxN:
	NVOICE $01, $40
	NOISE $15
	NVOICE $02, $10
	NOISE $14
	SND_END

Snd03_SfxN:
	NVOICE $02, $80
	NOISE $25
	NVOICE $02, $26
	NOISE $25
	NVOICE $01, $10
	NOISE $26
	NOISE $27
	NOISE $26
	SND_END

Snd04_SfxN:
	NVOICE $02, $50
	NOISE $25
	NVOICE $02, $16
	NOISE $25
	NVOICE $01, $10
	NOISE $26
	NOISE $27
	NOISE $26
	SND_END

Snd05_SfxN:
	NVOICE $02, $61
	NOISE $25
	NVOICE $02, $21
	NOISE $26
	NVOICE $02, $10
	NOISE $25
	NVOICE $01, $20
	NOISE $27
	NVOICE $01, $10
	NOISE $25
	NOISE $00
	NOISE $27
	NOISE $00
	NOISE $25
	NOISE $24
	SND_END

Snd06_SfxN:
	NVOICE $02, $A0
	NOISE $37
	NVOICE $01, $20
	NOISE $47
	SND_END

Snd06_Sfx1:
	VOICE $01, 8, 3, 0, 0
	OCTAVE 4
	NOTE D#, 3
	ATTEN 0
	VOICE $01, 8, 6, 0, 0
	OCTAVE 3
	NOTE B_, 1
	ATTEN 2
	NOTE A#, 1
	ATTEN 4
	NOTE F#, 2
	SND_END

Snd07_SfxN:
	NVOICE $02, $80
	NOISE $37
	NVOICE $01, $20
	NOISE $47
	SND_END

Snd07_Sfx1:
	VOICE $01, 8, 4, 0, 0
	OCTAVE 3
	NOTE A_, 3
	ATTEN 0
	VOICE $01, 8, 6, 0, 0
	NOTE F#, 1
	ATTEN 2
	NOTE D#, 1
	ATTEN 4
	NOTE D_, 2
	SND_END

Snd08_SfxN:
	NVOICE $02, $80
	NOISE $47
	NVOICE $01, $20
	NOISE $47
	SND_END

Snd08_Sfx1:
	VOICE $01, 8, 4, 0, 0
	OCTAVE 3
	NOTE D_, 3
	ATTEN 0
	VOICE $01, 8, 6, 0, 0
	OCTAVE 2
	NOTE B_, 1
	ATTEN 2
	NOTE F#, 1
	ATTEN 4
	NOTE E_, 2
	SND_END

Snd09_SfxN:
	NVOICE $01, $80
	NOISE $12
	NOISE_VOL 2
	NOISE $13
	NOISE_VOL 4
	NOISE_VOLNOTE 4
	NOISE_VOLNOTE 4
	NOISE_VOLNOTE 4
	NOISE_VOLNOTE 4
	NOISE $10
	NOISE_VOLNOTE 3
	NOISE_VOLNOTE 3
	NOISE_VOLNOTE 3
	NOISE_VOLNOTE 3
	NOISE_VOLNOTE 2
	NOISE_VOLNOTE 1
	SND_END

Snd0A_SfxN:
	NVOICE $01, $80
	NOISE $15
	NVOICE $02, $20
	NOISE $14
	NVOICE $02, $14
	NOISE $14
	SND_END

Snd0B_SfxN:
	NVOICE $01, $40
	NVOICE $01, $60
	NOISE $10
	NOISE_REST
	NOISE_VOLNOTE 8
	NOISE_VOLNOTE 6
	NVOICE $01, $10
	NOISE $25
	NOISE_VOLNOTE 2
	NOISE_VOLNOTE 1
	NOISE_VOLNOTE 1
	NOISE $15
	NOISE_VOLNOTE 1
	NOISE_VOLNOTE 1
	NOISE_VOLNOTE 1
	SND_END

; Orphan SfxN stream (no header points here).
Data_460F:
	NVOICE $08, $60
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
	NOISE $08
	NOISE $09
	NOISE $0A
	NOISE $0B
	NOISE $0C
	NOISE $0D
	NOISE $0E
	NOISE $0F
	NOISE $18
	NOISE $19
	NOISE $1A
	NOISE $1B
	NOISE $1C
	NOISE $1D
	NOISE $1E
	NOISE $1F
	NOISE $28
	NOISE $29
	NOISE $2A
	NOISE $2B
	NOISE $2C
	NOISE $2D
	NOISE $2E
	NOISE $2F
	NOISE $38
	NOISE $39
	NOISE $3A
	NOISE $3B
	NOISE $3C
	NOISE $3D
	NOISE $3E
	NOISE $3F
	SND_END

Snd0C_SfxN:
	NVOICE $01, $80
	NOISE $36
	NVOICE $01, $40
	NOISE $56
	SND_END

; TrackTick: tempo skip; a pending duty reload; LEN - 1; at 0 FarRead and read commands,
; else Sustain. With TRK_MUTE bit 7 (never set) every byte only mutes the channel.
TrackTick:
	ld l, TRK_FLAGS
	bit 4, [hl]
	ret nz
	bit 5, [hl]
	jp z, .l466E
	res 5, [hl]
	ld l, TRK_CURDUTY
	ld a, [hl]
	call WriteDuty
.l466E:
	ld l, TRK_LEN
	dec [hl]
	jp nz, Sustain
	ld l, TRK_PTR
	ld e, [hl]
	inc l
	ld d, [hl]

; ReadCmds: FarRead, then $E0-$FF commands, SfxN: NoiseNote. Notes (every other track): hi =
; pitch, lo x unit (0: (unit & 15) x 16); in note-volume mode (TRK_FLAGS bit 1) lo is the
; volume and the note lasts one unit.
ReadCmds:
	call FarRead
	ld l, TRK_MUTE
	bit 7, [hl]
	jp nz, MutedByte
	ld a, [wReadBuf]
	cp $E0
	jp nc, Command
	ld a, [wTrackDesc]
	cp $63
	jp z, NoiseNote

MusicNote:
	res 2, [hl]
	call SavePtr
	ld l, TRK_UNIT
	ld c, [hl]
	ld a, [wReadBuf]
	ld l, TRK_FLAGS
	bit 1, [hl]
	jr z, .l46AF
	ld l, TRK_VOL
	and $0F
	swap a
	ld [hl], a
	ld a, $01
	jr .l46B4
.l46AF:
	and $0F
	jp z, .l46C6
.l46B4:
	ld b, a
	xor a
	bit 0, b
	jp nz, .l46CE
	rrc b
.l46BD:
	add a, c
	dec b
	jp nz, .l46BD
	add a, a
	jp NoteLen
.l46C6:
	swap c
	ld a, c
	and $F0
	jp NoteLen
.l46CE:
	add a, c
	dec b
	jp nz, .l46CE

; NoteLen: LEN = A. A rest mutes (NRx2 = 8; on the drum track the write goes to $FF00).
NoteLen:
	ld l, TRK_LEN
	ld [hl+], a
	ld c, a
	ld a, [wReadBuf]
	and $F0
	jp nz, Note
	set 0, [hl]
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
	jp z, .l470A
	ld e, a
	ld b, $00
	ld hl, $0000
.l46FF:
	add hl, bc
	dec e
	jp nz, .l46FF
	ld a, l
	and $F0
	or h
	swap a
.l470A:
	pop hl
	pop de
	ld l, TRK_RELTICK
	ld [hl], a
	ld l, TRK_DUTYCNT
	ld a, [hl+]
	or a
	jp z, .l471B
	ld [hl+], a
	ld a, [hl]
	call WriteDuty
.l471B:
	ld l, TRK_PANFLAGS
	bit 0, [hl]
	call nz, AutoPan
	ld a, [wReadBuf]
	and $F0
	cp $D0
	jp nz, .l4738
	ld l, TRK_OCTAVE
	ld a, [hl]
	add a, $18
	ld c, a
	ld l, $DC
	ld a, [hl]
	jp .l4741
.l4738:
	swap a
	rlca
	ld l, $DC
	ld [hl], a
	ld l, TRK_OCTAVE
	ld c, [hl]
.l4741:
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
	jp z, .l4764
	ld c, [hl]
	push hl
	ld l, a
	ld h, c
	add hl, de
	ld e, l
	ld d, h
	pop hl
.l4764:
	ld l, TRK_PANFLAGS
	bit 5, [hl]
	jr z, .l4777
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
	jr .l478C
.l4777:
	ld l, TRK_PANFLAGS
	bit 7, [hl]
	jr z, .l478C
	ld a, [wTrackDesc]
	cp $22
	jr z, .l478C
	ld l, TRK_PERIOD
	ld a, [hl+]
	ld b, [hl]
	ld l, TRK_SAVEPERIOD
	ld [hl+], a
	ld [hl], b
.l478C:
	ld l, TRK_PERIOD
	ld [hl], e
	inc l
	ld [hl], d
	ld l, TRK_VIB
	ld a, [hl]
	or a
	jp z, .l47BF
	rlca
	ld l, TRK_FLOW
	res 4, [hl]
	res 5, [hl]
	ld l, TRK_PANFLAGS
	jp nc, .l47A9
	set 4, [hl]
	jp .l47AB
.l47A9:
	res 4, [hl]
.l47AB:
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
.l47BF:
	call WritePeriod
	ld l, TRK_ENVNO
	ld a, [hl]
	or a
	jp z, .l47DE
	ld l, TRK_FLOW
	res 6, [hl]
	res 7, [hl]
	ld l, TRK_PANFLAGS
	set 3, [hl]
	ld l, TRK_ENVPTR
	ld a, [hl+]
	ld b, [hl]
	inc l
	ld [hl+], a
	ld [hl], b
	ld c, a
	jp EnvelopeStep
.l47DE:
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
	jr z, .l4807
	res 7, [hl]
	ld l, TRK_GATE
	ld [hl], $08
	ld l, TRK_ENV
	ld [hl], $00
.l4807:
	xor a
	ld l, TRK_RELVOL
	ld [hl], a
	ld a, [wTrackDesc]
	and $0F
	cp $02
	ld a, [wFadeStep]
	ld c, a
	ld a, b
	jp nz, .l482A
	add a, c
	jp c, .l4823
	cp $70
	jp c, WriteVolume
.l4823:
	xor a
	ld l, TRK_ID
	ld [hl], a
	jp WriteVolume
.l482A:
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
	ld l, TRK_DUTYCNT
	ld a, [hl+]
	or a
	jp z, .l4850
	dec [hl]
	jp nz, .l4850
	ld l, TRK_DUTY
	ld a, [hl]
	call WriteDuty
.l4850:
	ld l, TRK_VIB
	ld a, [hl]
	or a
	jp z, .l487A
	ld l, TRK_PANFLAGS
	bit 2, [hl]
	jp z, .l487A
	ld l, $D5
	ld a, [hl]
	or a
	jp z, .l4869
	dec [hl]
	jp .l487A
.l4869:
	ld l, $D3
	dec [hl]
	jp nz, .l487A
	ld l, $D1
	ld c, [hl]
	inc l
	ld b, [hl]
	call VibratoStep
	call WritePeriod
.l487A:
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
	jp z, .l48F0
	cp $FE
	jp z, .l4928
	cp $FB
	jp z, .l48FA
	ld l, $D3
	and $F0
	swap a
	ld [hl], a
	ld a, [bc]
	ld l, $D1
	inc bc
	ld [hl], c
	inc l
	ld [hl], b
	and $0F
	jp z, .l48EA
	ld l, TRK_PANFLAGS
	bit 4, [hl]
	jp nz, VibratoSemitone
	ld l, $D6
	ld e, a
	ld d, $00
	bit 3, a
	jp z, .l48D2
	and $07
	jp z, .l48EA
	cpl
	inc a
	ld e, a
	ld d, $FF
.l48D2:
	ld a, [hl]
	or a
	jp z, .l48DF
	ld b, a
	xor a
.l48D9:
	add a, e
	dec b
	jp nz, .l48D9
	ld e, a
.l48DF:
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
.l48EA:
	ld l, TRK_PERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ret
.l48F0:
	ld l, TRK_PANFLAGS
	res 2, [hl]
	ld l, TRK_OUTPERIOD
	ld e, [hl]
	inc l
	ld d, [hl]
	ret
.l48FA:
	ld l, TRK_FLOW
	inc bc
	bit 4, [hl]
	jp nz, .l490F
	set 4, [hl]
	ld l, $D7
	ld [hl], c
	inc l
	ld [hl], b
	inc l
	ld [hl], $00
	jp VibratoStep
.l490F:
	ld a, [bc]
	ld l, $D9
	inc [hl]
	cp [hl]
	jp z, .l491E
	dec l
	ld b, [hl]
	dec l
	ld c, [hl]
	jp VibratoStep
.l491E:
	ld [hl], $00
	ld l, TRK_FLOW
	res 4, [hl]
	inc bc
	jp VibratoStep
.l4928:
	ld l, TRK_FLOW
	bit 5, [hl]
	jp nz, .l493A
	set 5, [hl]
	inc bc
	ld l, $DA
	ld [hl], c
	inc l
	ld [hl], b
	jp VibratoStep
.l493A:
	ld l, $DA
	ld c, [hl]
	inc l
	ld b, [hl]
	jp VibratoStep

VibratoSemitone:
	cp $0D
	jr c, .l4953
	sub $0D
	jr z, .l4951
	dec a
	jr z, .l494F
	add a, $0B
.l494F:
	add a, $05
.l4951:
	add a, $13
.l4953:
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
	jp z, .l49C6
	cp $FE
	jp z, .l49F9
	cp $FB
	jp z, .l49CB
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
	jp c, .l49C1
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
	jp nz, .l49BD
	add a, c
	jp c, .l49B8
	cp $70
	jp c, WriteVolume
.l49B8:
	ld a, $00
	jp WriteVolume
.l49BD:
	sub c
	jp nc, WriteVolume
.l49C1:
	ld a, $08
	jp WriteVolume
.l49C6:
	ld l, TRK_PANFLAGS
	res 3, [hl]
	ret
.l49CB:
	ld l, TRK_FLOW
	inc bc
	bit 6, [hl]
	jp nz, .l49E0
	set 6, [hl]
	ld l, TRK_ENVLOOPPTR
	ld [hl], c
	inc l
	ld [hl], b
	inc l
	ld [hl], $00
	jp EnvelopeStep
.l49E0:
	ld a, [bc]
	ld l, TRK_ENVLOOPCNT
	inc [hl]
	cp [hl]
	jp z, .l49EF
	dec l
	ld b, [hl]
	dec l
	ld c, [hl]
	jp EnvelopeStep
.l49EF:
	ld [hl], $00
	ld l, TRK_FLOW
	res 6, [hl]
	inc bc
	jp EnvelopeStep
.l49F9:
	ld l, TRK_FLOW
	bit 7, [hl]
	jp nz, .l4A0B
	set 7, [hl]
	inc bc
	ld l, TRK_ENVMARK
	ld [hl], c
	inc l
	ld [hl], b
	jp EnvelopeStep
.l4A0B:
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
	jp z, .l4A32
	ret c
	ld l, TRK_FLAGS
	bit 2, [hl]
	ret z
	res 2, [hl]
	ld l, TRK_LASTVOL
	ld a, [hl]
	jp WriteVolume
.l4A32:
	ld l, TRK_PANFLAGS
	bit 7, [hl]
	jr z, .l4A6C
	ld l, TRK_ENV
	ld a, [hl]
	or a
	jp z, .l4A92
	bit 3, [hl]
	jr z, .l4A47
	and $0F
	jr .l4A4E
.l4A47:
	ld b, a
	ld l, TRK_LASTVOL
	ld a, [hl]
	and $F0
	or b
.l4A4E:
	ld l, TRK_REG_NRX2
	ld c, [hl]
	call WriteRegChecked
	ret nc
	ld l, TRK_SAVEPERIOD + 1
	ld a, [hl]
	or a
	jr z, .l4A88
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
	ret
.l4A6C:
	ld l, TRK_RELVOL
	ld a, [hl]
	or a
	jp nz, WriteVolume
	ld l, TRK_ENV
	ld a, [hl]
	or a
	jp z, .l4A92
	ld b, a
	ld l, TRK_LASTVOL
	ld a, [hl]
	and $F0
	or b
	ld l, TRK_REG_NRX2
	ld c, [hl]
	call WriteRegChecked
	ret nc
.l4A88:
	ld l, TRK_REG_NRX4
	ld c, [hl]
	ld l, TRK_OUTPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ret
.l4A92:
	ld a, $08
	jp WriteVolume

ReleaseCh3:
	cp [hl]
	inc hl
	jp c, .l4AAF
	jp z, .l4AAC
	ld l, TRK_FLAGS
	bit 2, [hl]
	ret z
	res 2, [hl]
	ld l, TRK_LASTVOL
	ld a, [hl]
	jp WriteVolume
.l4AAC:
	ld a, [hl+]
	ld [hl], a
	ret
.l4AAF:
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

; DrumNote: the drum hit id = the note's high nibble (bank 14), started on the SFX tracks of
; its header, each with its own priority test.
DrumNote:
	ld a, [wReadBuf]
	and $F0
	swap a
	ld [wReqId], a
	ld hl, SoundTable - 2
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
	jp c, DrumHitRefused
	ld b, a
	push hl
	ld h, HIGH(wTrkSfx1)
	ld l, TRK_ID
	ld a, [hl]
	pop hl
	ld a, b
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
	jp nz, .l4B37
	ld a, $08
	ld c, $10
	ldh [c], a
.l4B37:
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

; NoiseNote: LEN = unit. < $C0: NR43 = byte; $C0-$CF set the volume nibble (no time);
; $D0 mutes for a unit; $D1-$DF set the volume nibble and play a unit.
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
	jp WriteVolumeNow

NoiseVolume:
	cp $D0
	jp nc, .l4B87
	ld l, TRK_FLAGS
	set 6, [hl]
	call SetNoiseVol
	call WriteVolumeNoise
	jp ReadCmds
.l4B87:
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
	ld a, [hl]
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
	set 2, [hl]
	set 5, [hl]
	ld b, $EE
	ld a, [wTrackDesc]
	and $0F
	jp z, .l4BBB
.l4BB5:
	rlc b
	dec a
	jp nz, .l4BB5
.l4BBB:
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
	ret

MuteChannel:
	ld a, [wTrackDesc]
	and $0F
	cp $02
	jp z, .l4BFB
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
.l4BFB:
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
	jp nz, WriteVolumeNow0

WriteVolume:
	ld l, TRK_REG_NRX2
	ld c, [hl]
	ld l, TRK_LASTVOL
	ld [hl], a
	ldh a, [c]
	cp [hl]
	jp nz, .l4C2B
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
.l4C2B:
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
	ret

WriteVolumeNow0:
	res 6, [hl]

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
	ret

WriteDuty:
	ld b, a
	ld a, [wTrackDesc]
	and $0F
	cp $02
	jp z, WriteWave
	ld a, b
	ld l, TRK_CURDUTY
	ld [hl], a
	ld l, TRK_REG_NRX1
	ld c, [hl]
	jp WriteRegChecked

WriteWave:
	ld a, [wTrackDesc]
	cp $22
	jp nz, LoadWave
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
	ld c, $1A
	xor a
	ldh [c], a
	ld a, b
	swap a
	ld hl, WaveTable - 2
	call LoadPtrIndexed
	ld c, $30
	ld b, $10
.l4C9C:
	ld a, [hl+]
	ldh [c], a
	inc c
	dec b
	jp nz, .l4C9C
	pop hl
	ld c, $1C
	xor a
	ldh [c], a
	ld a, $80
	ld c, $1A
	ldh [c], a
	ld l, TRK_REG_NRX4
	ld c, [hl]
	ld l, TRK_OUTPERIOD + 1
	ld a, [hl]
	or $80
	ldh [c], a
	ret

WriteRegChecked:
	ld b, a
	push hl
	ld a, [wTrackDesc]
	cp $00
	jp z, .l4CD2
	cp $22
	jp nz, .l4CDE
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
.l4CD2:
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
.l4CDE:
	pop hl
	ld a, b
	ldh [c], a
	scf
	ret

; StopAll: priority and id of all tracks cleared (note-volume mode off on Sfx1/Sfx2), the
; wobble and wReqHold off, NRx2 = 8 on all channels, NR10 = 8, NR50 = $77.
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
	ld [wWobbleOn], a
	ld [wReqHold], a
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
	ld a, $08
	ld c, $10
	ldh [c], a
	ld c, $24
	ld a, $77
	ldh [c], a
	ret

; StartFadeOut, StopAndFadeIn, StartFadeIn, SndUndim (NR50 = $77), SndDim (NR50 = $44):
; nothing calls these (the game writes wSndDim itself).
StartFadeOut:
	ld [wFadeRate], a
	dec a
	ld [wFadeTimer], a
	xor a
	ld [wFadeDir], a
	ld a, [wWobbleOn]
	or a
	ld c, $24
	jr nz, .l4D50
	ldh a, [c]
	cp $77
	ret z
.l4D50:
	xor a
	ld [wWobbleOn], a
	ret

StopAndFadeIn:
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
	ret

SndUndim:
	ld a, [wFadeRate]
	or a
	ret nz
	ld hl, wSndDim
	res 0, [hl]
	ld a, $77
	ld c, $24
	ldh [c], a
	ret

SndDim:
	ld a, [wFadeRate]
	or a
	ret nz
	ld hl, wSndDim
	set 0, [hl]
	ld a, $44
	ld c, $24
	ldh [c], a
	ret

; Command: $E0 voice, $E1-$E6 octave (OctaveCodes), $E7-$FF through CommandTable (from
; CommandTable - 14) or, in note-volume mode, CommandTableVol (only $EE differs).
Command:
	inc de
	sub $E0
	jp z, Cmd_Voice
	cp $07
	jp c, Cmd_Octave
	ld l, TRK_FLAGS
	bit 1, [hl]
	jp nz, CommandVol
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

; Cmd_Voice: SfxN: $E0 u v (unit, NR42; u bit 7: write it at once). Other tracks, u bit 7
; clear: $E0 u v g (duty, vol; g = gate|env, or with vol 0 the envelope number), note-volume
; mode off. u bit 7 set: $E0 u v x (duty; x = NR10 on CH1), note-volume mode on.
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
	call WriteVolumeNow
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
	jp z, VoiceEnvelope
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
	jp VoiceEnd

VoiceVol:
	set 1, [hl]
	ld a, [wReadBuf + $02]
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	inc de
	ld a, [wTrackDesc]
	and $0F
	jp nz, .l4EB6
	ld c, $10
	ld a, [wReadBuf + $03]
	ldh [c], a
.l4EB6:
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

; Cmd_Ext: $EA xy through ExtTable (13 entries; x >= $D runs into the code).
Cmd_Ext:
	swap a
	and $0F
	ld hl, ExtTable
	call LoadPtrIndexed
	ld a, [wReadBuf + $01]
	jp hl
ExtTable:
	dw Ext_Duty
	dw Ext_PanBoth
	dw Ext_PanLeft
	dw Ext_PanRight
	dw Ext_Autopan
	dw Ext_AutopanBoth
	dw Ext_PanBoth2
	dw Ext_TransposeUp
	dw Ext_TransposeDown
	dw Ext_ReleaseVol
	dw Ext_Wobble
	dw Ext_HoldReq
	dw Ext_Flag7

Ext_Duty:
	pop hl
	and $0F
	swap a
	ld l, TRK_DUTY
	ld [hl], a
	call WriteDuty
	inc de
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
	jp z, .l4F52
.l4F4C:
	sla b
	dec a
	jp nz, .l4F4C
.l4F52:
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
	jp nz, .l4F7B
	bit 1, [hl]
	jp nz, PanRight.l4FA8
	set 1, [hl]
	jp PanRight
.l4F7B:
	bit 1, [hl]
	jp z, .l4F85
	res 1, [hl]
	jp PanBoth
.l4F85:
	set 1, [hl]

PanRight:
	ld b, $EE
	ld l, $01
	ld a, [wTrackDesc]
	and $0F
	or a
	jp z, .l4F9C
.l4F94:
	rlc b
	rlc l
	dec a
	jp nz, .l4F94
.l4F9C:
	ld c, $25
	ldh a, [c]
	and b
	or l
	ld b, l
	ld l, TRK_PAN
	ld [hl], b
	jp WriteRegChecked
.l4FA8:
	res 1, [hl]

PanLeft:
	ld b, $EE
	ld l, $10
	ld a, [wTrackDesc]
	and $0F
	or a
	jp z, .l4FBF
.l4FB7:
	rlc b
	rlc l
	dec a
	jp nz, .l4FB7
.l4FBF:
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
	jp z, .l5005
	rlca
	cpl
	inc a
.l5005:
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

; Ext_Wobble: $EA Ax y (3 bytes). Unless a fade runs: y = 0 ends the wobble (NR50 = $77);
; else wWobbleMin = 7 - (y & 7), wWobbleRate = y >> 4.
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
	jr z, .l504E
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
.l504E:
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
	jr z, .l506B
	ld l, TRK_PANFLAGS
	set 7, [hl]
	inc de
	jp ReadCmds
.l506B:
	ld l, TRK_PANFLAGS
	res 7, [hl]
	inc de
	jp ReadCmds

Cmd_Vibrato:
	pop hl
	ld l, TRK_VIB
	ld [hl], a
	or a
	jp z, .l50C0
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
	jp z, .l50B6
	ld b, a
	xor a
	bit 0, b
	jp nz, .l50B1
	rrc b
.l50A8:
	add a, c
	dec b
	jp nz, .l50A8
	add a, a
	jp .l50B6
.l50B1:
	add a, c
	dec b
	jp nz, .l50B1
.l50B6:
	ld l, $D4
	ld [hl+], a
	ld a, [wReadBuf + $02]
	and $0F
	inc l
	ld [hl], a
.l50C0:
	inc de
	jp ReadCmds

VibratoSemi:
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
	ld l, $D4
	ld [hl], $00
	inc de
	jp ReadCmds

Cmd_Envelope:
	pop hl
	ld l, TRK_ENVNO
	ld [hl], a
	or a
	jp z, .l50F4
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
.l50F4:
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

; Cmd_Slide (note-volume mode $EE): the first marks; the next one, $EE x y n, adds x to the
; pitch offset and steps the attenuation by y, and goes back to the mark until the n-th pass.
; x, y and n are read with `ld a, [de]`, so from bank 14 whatever the stream's bank.
Cmd_Slide:
	pop hl
	ld l, TRK_PANFLAGS
	bit 5, [hl]
	jr nz, .l5124
	set 5, [hl]
	ld l, TRK_SLIDEPTR
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	ld [hl], $00
	jp ReadCmds
.l5124:
	ld a, [de]
	bit 7, a
	ld c, a
	ld l, TRK_F4
	jr nz, .l5130
	ld b, $00
	jr .l5132
.l5130:
	ld b, $FF
.l5132:
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
	ld a, [de]
	bit 7, a
	ld l, TRK_SLIDEATTCNT
	jr nz, .l515E
	bit 6, a
	jr nz, .l5152
	sub $01
	cpl
	jr .l516C
.l5152:
	and $0F
	inc [hl]
	cp [hl]
	jr nz, .l5174
	ld [hl], $00
	ld a, $0F
	jr .l516C
.l515E:
	bit 6, a
	jr z, .l516C
	and $0F
	inc [hl]
	cp [hl]
	jr nz, .l5174
	ld [hl], $00
	ld a, $01
.l516C:
	and $0F
	swap a
	ld l, TRK_ATTEN
	add a, [hl]
	ld [hl], a
.l5174:
	inc de
	ld a, [de]
	ld l, TRK_SLIDECNT
	inc [hl]
	cp [hl]
	jp z, .l5185
	ld l, TRK_SLIDEPTR
	ld e, [hl]
	inc l
	ld d, [hl]
	jp ReadCmds
.l5185:
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
	ld [wTempo], a
	xor a
	ld [wTempoAcc], a
	inc de
	jp ReadCmds

Cmd_Detune:
	pop hl
	ld l, TRK_DETUNE
	ld [hl+], a
	bit 7, a
	ld a, $00
	jp z, .l51B2
	ld a, $FF
.l51B2:
	ld [hl], a
	inc de
	jp ReadCmds

Cmd_Atten:
	pop hl
	dec de
	ld a, [wReadBuf]
	and $0F
	swap a
	jr z, .l51D0
	ld b, a
	ld a, [wTrackDesc]
	and $0F
	cp $02
	ld a, b
	jr nz, .l51D0
	sla a
	cpl
.l51D0:
	ld l, TRK_ATTEN
	ld [hl], a
	inc de
	jp ReadCmds

; Cmd_LoopBreak: $F9 x. x odd: on the last pass of loop 1 jump to the byte after its $FB n;
; x even: the same for loop 2 (also ends loop 1). The pass counter is set at the first $FB n
; after the first $F9.
Cmd_LoopBreak:
	pop hl
	bit 0, a
	jr z, .l51F3
	ld l, TRK_FLOW
	bit 0, [hl]
	jr z, .l520C
	ld l, TRK_BREAK
	dec [hl]
	jr nz, .l520C
	ld l, TRK_FLOW
	res 0, [hl]
	ld l, TRK_EXIT
	ld a, [hl+]
	ld d, [hl]
	ld e, a
	jp ReadCmds
.l51F3:
	ld l, TRK_FLOW
	bit 1, [hl]
	jr z, .l520C
	ld l, TRK_BREAK2
	dec [hl]
	jr nz, .l520C
	ld l, TRK_FLOW
	res 1, [hl]
	res 0, [hl]
	ld l, TRK_EXIT2
	ld a, [hl+]
	ld d, [hl]
	ld e, a
	jp ReadCmds
.l520C:
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

; Cmd_Loop1 / Cmd_Loop2: the first $FB (FC) marks, the next one $FB n loops n times. When a
; $F9 has armed the break, the end also stores the exit address, and if that same end is the
; last pass it skips one byte too many.
Cmd_Loop1:
	pop hl
	ld l, TRK_FLOW
	bit 0, [hl]
	jp nz, .l5230
	set 0, [hl]
	ld l, TRK_LOOPPTR
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	xor a
	ld [hl], a
	jp ReadCmds
.l5230:
	ld l, TRK_BREAK
	ld a, [hl]
	cp $FF
	jr nz, .l5245
	ld a, [wReadBuf + $01]
	ld l, TRK_BREAK
	ld [hl], a
	dec [hl]
	inc de
	ld l, TRK_EXIT
	ld [hl], e
	ld l, TRK_EXIT + 1
	ld [hl], d
.l5245:
	ld a, [wReadBuf + $01]
	ld l, TRK_LOOPCNT
	inc [hl]
	cp [hl]
	jp z, .l5256
	dec l
	ld d, [hl]
	dec l
	ld e, [hl]
	jp ReadCmds
.l5256:
	ld [hl], $00
	ld l, TRK_FLOW
	res 0, [hl]
	inc de
	jp ReadCmds

Cmd_Loop2:
	pop hl
	ld l, TRK_FLOW
	bit 1, [hl]
	jp nz, .l5275
	set 1, [hl]
	ld l, TRK_LOOP2PTR
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	xor a
	ld [hl], a
	jp ReadCmds
.l5275:
	ld l, TRK_BREAK2
	ld a, [hl]
	cp $FF
	jr nz, .l528A
	ld a, [wReadBuf + $01]
	ld l, TRK_BREAK2
	ld [hl], a
	dec [hl]
	inc de
	ld l, TRK_EXIT2
	ld [hl], e
	ld l, TRK_EXIT2 + 1
	ld [hl], d
.l528A:
	ld a, [wReadBuf + $01]
	ld l, TRK_LOOP2CNT
	inc [hl]
	cp [hl]
	jp z, .l529B
	dec l
	ld d, [hl]
	dec l
	ld e, [hl]
	jp ReadCmds
.l529B:
	ld [hl], $00
	ld l, TRK_FLOW
	res 1, [hl]
	inc de
	jp ReadCmds

Cmd_CallRet:
	pop hl
	ld l, TRK_FLOW
	bit 2, [hl]
	jp nz, .l52BF
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
.l52BF:
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
	jp nz, .l52DB
	set 3, [hl]
	ld l, TRK_SEGNO
	ld [hl], e
	inc l
	ld [hl], d
	jp ReadCmds
.l52DB:
	ld l, TRK_SEGNO
	ld e, [hl]
	inc l
	ld d, [hl]
	jp ReadCmds

; Cmd_End: NR51 = $FF, clear priority and id; Drm: nothing else. Sfx2 / Sfx1 (NR10 = 8, note-
; volume mode off) give CH3 / CH1 back to a playing music track; then the channel is muted.
Cmd_End:
	pop hl
	ld l, TRK_ID
	ld a, [hl]
	ld c, $25
	ld a, $FF
	ldh [c], a
	jr EndTrack

; EndFadeIn: unreachable (Cmd_End jumps over it).
EndFadeIn:
	ld a, [wTrkCh2 + $01]
	or a
	jr z, EndTrack
	ld c, $25
	ld a, $FF
	ldh [c], a
	ld a, $10
	ld [wFadeRate], a
	call StartFadeIn

EndTrack:
	xor a
	ld [hl-], a
	ld [hl], a
	ld a, [wTrackDesc]
	cp $34
	ret z
	cp $52
	jp z, .l5337
	cp $40
	jp z, .l5320
	cp $63
	jp nz, MuteChannel
	ld l, TRK_FLAGS
	res 3, [hl]
	jp MuteChannel
.l5320:
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
.l5337:
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

Ext_HoldReq:
	and $0F
	ld hl, wReqHold
	ld [hl], a
	inc de
	pop hl
	jp ReadCmds

Snd0D_Sfx2:
	SND_END

Snd0E_SfxN:
	NVOICE $02, $83
	NOISE $01
	NOISE $11
	NOISE $21
	NOISE $31
	NOISE $41
	NOISE $51
	NOISE $61
	NOISE $71
	NOISE $81
	NOISE $71
	NOISE $61
	NOISE $51
	NOISE $41
	NOISE $31
	NOISE $21
	NOISE $11
	NOISE $01
	NOISE $BF
	NOISE $B8
	NOISE $B1
	SND_END

Snd0F_SfxN:
	NVOICE $02, $85
	NOISE $01
	NOISE $31
	NOISE $51
	NOISE $01
	NOISE $71
	NOISE $21
	NOISE $01
	NOISE $01
	NOISE $81
	NOISE $01
	NOISE $61
	SND_END

Snd0D_Sfx1:
	VOICE $03, 8, 8, 6, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE G_, 2
	OCTAVE 5
	NOTE C_, 6
	SND_END

Snd16_Sfx1:
	TRANSPOSE_UP 5
	VOICE $01, 4, 15, 0, 15
	OCTAVE 2
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	ATTEN 8
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	SND_END

Snd18_Sfx1:
	VOICE $01, 4, 13, 15, 0
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
	ATTEN 8
	NOTE G_, 2
	NOTE C_, 4
	SND_END

Snd18_SfxN:
	NVOICE $03, $E8
	NOISE $51
	NVOICE $05, $C4
	NOISE $56
	NOISE $41
	NOISE $52
	SND_END

Snd22_Sfx1:
	VOICE $01, 8, 15, 0, 15
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE F_, 1
	ATTEN 8
	NOTE B_, 1
	NOTE F_, 1
	VOICE $01, 8, 5, 0, 15
	NOTE B_, 1
	NOTE F_, 1
	REST 1
	NOTE B_, 1
	NOTE F_, 1
	SND_END

Snd17_Ch1:
	TEMPO $10
	TRANSPOSE_DOWN $0C
	VOICE $03, 4, 12, 11, 1
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
	RELEASE 9, 1
	NOTE C#, 4
	ATTEN 8
	NOTE C#, 4
	VOICE $03, 4, 3, 11, 1
	NOTE C#, 4
	VOICE $03, 4, 2, 11, 1
	NOTE C#, 4
	NOTE C#, 4
	SND_END

Snd17_Ch2:
	VOICE $03, 8, 3, 0, 15
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

Snd17_Ch3:
	VOICE $03, 6, 2, 15, 4
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

Snd19_SfxN:
	NVOICE $05, $F8
	NOISE $71
	NOISE $51
	NOISE $31
	NOISE $11
	NVOICE $05, $88
	NOISE $11
	NVOICE $05, $48
	NOISE $11
	SND_END

Snd10_SfxN:
	NVOICE $01, $F8
	NOISE $41
	NOISE $11
	SND_END

Snd1A_SfxN:
	NVOICE $18, $F1
	NOISE $5E
	NVOICE $18, $91
	NOISE $5E
	NVOICE $18, $71
	NOISE $5E
	NVOICE $18, $52
	NOISE $5E
	SND_END

Snd11_Sfx1:
	VOICE $02, 0, 15, 0, 15
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

Snd12_Sfx1:
	VOICE $01, 0, 15, 14, 1
	SND_CALL Snd12_Sfx1_546E
	VOICE $01, 0, 6, 14, 1
	SND_CALL Snd12_Sfx1_546E
	SND_END
Snd12_Sfx1_546E:
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

Snd13_Sfx1:
	VOICE $03, 4, 15, 6, 7
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 5
	NOTE G#, 1
	NOTE D_, 1
	PAN_RIGHT 0
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 5
	NOTE G#, 1
	NOTE D_, 1
	PAN_LEFT 0
	OCTAVE 6
	NOTE C_, 1
	OCTAVE 5
	NOTE G#, 1
	NOTE D_, 1
	LEN_UNIT $01
	PAN_RIGHT 0
	ATTEN 3
	NOTE C_, 1
	NOTE C#, 1
	ATTEN 4
	NOTE C_, 1
	NOTE C#, 1
	PAN_LEFT 0
	ATTEN 3
	NOTE C_, 1
	NOTE D_, 1
	ATTEN 4
	NOTE C_, 1
	NOTE D#, 1
	PAN_RIGHT 0
	ATTEN 3
	NOTE C_, 1
	NOTE E_, 1
	ATTEN 4
	NOTE C_, 1
	NOTE F_, 1
	PAN_LEFT 0
	ATTEN 5
	NOTE C_, 1
	NOTE F#, 1
	ATTEN 6
	NOTE C_, 1
	NOTE G_, 1
	PAN_RIGHT 0
	ATTEN 7
	NOTE C_, 1
	NOTE E_, 1
	NOTE G#, 1
	ATTEN 8
	NOTE C#, 1
	NOTE F_, 1
	NOTE A_, 1
	PAN_LEFT 0
	ATTEN 8
	NOTE D_, 1
	NOTE F#, 1
	NOTE A#, 1
	ATTEN 8
	NOTE D#, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 6
	PAN_RIGHT 0
	ATTEN 7
	NOTE C_, 1
	NOTE E_, 1
	NOTE G#, 1
	ATTEN 8
	NOTE C#, 1
	NOTE F_, 1
	NOTE A_, 1
	PAN_LEFT 0
	ATTEN 8
	NOTE D_, 1
	NOTE F#, 1
	NOTE A#, 1
	ATTEN 8
	NOTE D#, 1
	NOTE G_, 1
	NOTE B_, 1
	PAN_BOTH 0
	SND_END

Snd14_Sfx1:
	TRANSPOSE_UP 8
	VOICE $02, 8, 8, 6, 5
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

Snd15_Sfx1:
	VOICE $05, 12, 15, 12, 1
	DUTY_STEP 8, 1
	TRANSPOSE_UP $0A
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE A_, 1
	NOTE F#, 1
	VOICE $05, 12, 3, 12, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE F#, 1
	SND_END

Snd1B_Sfx1:
	SND_END

Snd1B_SfxN:
	NVOICE $01, $60
	NOISE $21
	NOISE_VOL 1
	NOISE $21
	NOISE_VOL 6
	NOISE $22
	NOISE $23
	NOISE_VOL 4
	NOISE $24
	NOISE_VOL 3
	NOISE $25
	NOISE_VOL 2
	NOISE $26
	NOISE_VOL 1
	NOISE $26
	NOISE $27
	NOISE $27
	NOISE $27
	NOISE $27
	SND_END

Snd1C_Sfx1:
	SND_END

Snd1C_SfxN:
	NVOICE $01, $20
	NOISE $26
	NOISE $22
	NVOICE $01, $00
	NOISE $21
	NOISE $22
	NVOICE $01, $80
	NOISE $25
	NOISE $20
	SND_END

Snd1D_Sfx1:
	SND_END

Snd1D_SfxN:
	NVOICE $02, $80
	NOISE_VOL 2
	NOISE $24
	NOISE_VOL 4
	NOISE $26
	NOISE_VOL 6
	NOISE $35
	NOISE_VOL 8
	NOISE $34
	NOISE_VOLNOTE 1
	NOISE_VOL 3
	NOISE $24
	NOISE $22
	NOISE $26
	NOISE $27
	NOISE $27
	NOISE_VOL 1
	NOISE $27
	NOISE $27
	NOISE $27
	SND_END

Snd1E_Sfx1:
	SND_END

Snd1E_SfxN:
	NVOICE $01, $70
	NOISE $31
	NOISE $32
	NOISE $33
	NOISE $34
	NOISE $35
	NOISE $36
	NOISE $37
	NVOICE $04, $85
	NOISE $21
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	NOISE $27
	SND_END

Snd1F_Sfx1:
	SND_END

Snd1F_SfxN:
	LOOP_START
	NVOICE $08, $86
	NOISE $5C
	NOISE $5B
	NVOICE $06, $86
	NOISE $57
	NOISE $51
	NOISE $52
	NOISE $53
	LOOP_END $03
	LOOP_START
	NVOICE $03, $86
	NOISE $5C
	NOISE $5B
	NOISE $5C
	LOOP_END $03
	NVOICE $02, $86
	NOISE $5C
	NVOICE $06, $86
	NOISE $57
	NOISE $51
	NOISE $52
	NOISE $53
	NOISE $54
	NVOICE $06, $36
	NOISE $52
	NOISE $53
	NOISE $54
	NOISE $55
	NOISE $56
	SND_END

Snd20_Sfx1:
	SND_END

Snd20_SfxN:
	SND_END

Snd21_Sfx1:
	SND_END

Snd21_SfxN:
	SND_END

Snd23_Sfx1:
	VOICE $01, 0, 15, 0, 15
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE E_, 1
	ATTEN 8
	NOTE C_, 1
	NOTE E_, 1
	SND_END

; Orphan stream (decoded as Sfx1; no header or call reaches it)
Data_55BB:
	DUTY_STEP 2, 8
	PAN_BOTH 6
	VOICE $07, 4, 8, 13, 2
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

; Orphan stream (decoded as Sfx2; no header or call reaches it)
Data_55CE:
	PAN_LEFT $0E
	PAN_BOTH 6
	VOICE $07, 8, 3, 8, 1
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

; Id $24 points Sfx1 and SfxN at the same bytes: SfxN reads them as noise (below), Sfx1 as a
; tone stream ($E0 01 80 00: a voice with volume 0, then 191 notes, 1616 updates).

Snd24_Sfx1:
	NVOICE $01, $80
	NOISE $00
	NOISE $01
	NOISE $02
	NOISE $03
	NOISE $04
	NOISE $05
	NOISE $06
	NOISE $07
	NOISE $08
	NOISE $09
	NOISE $0A
	NOISE $0B
	NOISE $0C
	NOISE $0D
	NOISE $0E
	NOISE $0F
	NOISE $10
	NOISE $11
	NOISE $12
	NOISE $13
	NOISE $14
	NOISE $15
	NOISE $16
	NOISE $17
	NOISE $18
	NOISE $19
	NOISE $1A
	NOISE $1B
	NOISE $1C
	NOISE $1D
	NOISE $1E
	NOISE $1F
	NOISE $20
	NOISE $21
	NOISE $22
	NOISE $23
	NOISE $24
	NOISE $25
	NOISE $26
	NOISE $27
	NOISE $28
	NOISE $29
	NOISE $2A
	NOISE $2B
	NOISE $2C
	NOISE $2D
	NOISE $2E
	NOISE $2F
	NOISE $30
	NOISE $31
	NOISE $32
	NOISE $33
	NOISE $34
	NOISE $35
	NOISE $36
	NOISE $37
	NOISE $38
	NOISE $39
	NOISE $3A
	NOISE $3B
	NOISE $3C
	NOISE $3D
	NOISE $3E
	NOISE $3F
	NOISE $40
	NOISE $41
	NOISE $42
	NOISE $43
	NOISE $44
	NOISE $45
	NOISE $46
	NOISE $47
	NOISE $48
	NOISE $49
	NOISE $4A
	NOISE $4B
	NOISE $4C
	NOISE $4D
	NOISE $4E
	NOISE $4F
	NOISE $50
	NOISE $51
	NOISE $52
	NOISE $53
	NOISE $54
	NOISE $55
	NOISE $56
	NOISE $57
	NOISE $58
	NOISE $59
	NOISE $5A
	NOISE $5B
	NOISE $5C
	NOISE $5D
	NOISE $5E
	NOISE $5F
	NOISE $60
	NOISE $61
	NOISE $62
	NOISE $63
	NOISE $64
	NOISE $65
	NOISE $66
	NOISE $67
	NOISE $68
	NOISE $69
	NOISE $6A
	NOISE $6B
	NOISE $6C
	NOISE $6D
	NOISE $6E
	NOISE $6F
	NOISE $70
	NOISE $71
	NOISE $72
	NOISE $73
	NOISE $74
	NOISE $75
	NOISE $76
	NOISE $77
	NOISE $78
	NOISE $79
	NOISE $7A
	NOISE $7B
	NOISE $7C
	NOISE $7D
	NOISE $7E
	NOISE $7F
	NOISE $80
	NOISE $81
	NOISE $82
	NOISE $83
	NOISE $84
	NOISE $85
	NOISE $86
	NOISE $87
	NOISE $88
	NOISE $89
	NOISE $8A
	NOISE $8B
	NOISE $8C
	NOISE $8D
	NOISE $8E
	NOISE $8F
	NOISE $90
	NOISE $91
	NOISE $92
	NOISE $93
	NOISE $94
	NOISE $95
	NOISE $96
	NOISE $97
	NOISE $98
	NOISE $99
	NOISE $9A
	NOISE $9B
	NOISE $9C
	NOISE $9D
	NOISE $9E
	NOISE $9F
	NOISE $A0
	NOISE $A1
	NOISE $A2
	NOISE $A3
	NOISE $A4
	NOISE $A5
	NOISE $A6
	NOISE $A7
	NOISE $A8
	NOISE $A9
	NOISE $AA
	NOISE $AB
	NOISE $AC
	NOISE $AD
	NOISE $AE
	NOISE $AF
	NOISE $B0
	NOISE $B1
	NOISE $B2
	NOISE $B3
	NOISE $B4
	NOISE $B5
	NOISE $B6
	NOISE $B7
	NOISE $B8
	NOISE $B9
	NOISE $BA
	NOISE $BB
	NOISE $BC
	NOISE $BD
	NOISE $BE
	NOISE $BF
	SND_END

Snd25_SfxN:
	NVOICE $04, $80
	NOISE $07
	NOISE $65
	NOISE $63
	NOISE $52
	NOISE $56
	SND_END

Snd26_Sfx1:
	VVOICE $01, $80, $00
	OCTAVE 3
	VNOTE G_, 8
	VNOTE G#, 8
	VNOTE A_, 8
	VNOTE B_, 8
	OCTAVE 4
	VNOTE C#, 8
	VNOTE C#, 8
	VNOTE D_, 8
	VNOTE D#, 8
	VNOTE E_, 8
	VNOTE F_, 8
	VNOTE F#, 8
	VNOTE G_, 8
	SND_END

Snd27_Sfx1:
	VVOICE $01, $80, $00
	OCTAVE 4
	VNOTE C#, 9
	VNOTE E_, 9
	VNOTE G#, 9
	VNOTE B_, 9
	OCTAVE 5
	VNOTE D#, 9
	OCTAVE 4
	VNOTE B_, 9
	OCTAVE 4
	VNOTE C#, 8
	VNOTE E_, 8
	VNOTE G#, 8
	VNOTE B_, 8
	OCTAVE 5
	VNOTE D#, 8
	OCTAVE 4
	VNOTE B_, 8
	OCTAVE 4
	VNOTE C#, 7
	VNOTE E_, 7
	VNOTE G#, 7
	VNOTE B_, 7
	OCTAVE 5
	VNOTE D#, 7
	OCTAVE 4
	VNOTE B_, 7
	OCTAVE 4
	VNOTE C#, 5
	VNOTE E_, 5
	VNOTE G#, 5
	VNOTE B_, 5
	OCTAVE 5
	VNOTE D#, 5
	OCTAVE 4
	VNOTE B_, 5
	OCTAVE 4
	VNOTE C#, 4
	VNOTE E_, 4
	VNOTE G#, 4
	VNOTE B_, 4
	OCTAVE 5
	VNOTE D#, 4
	OCTAVE 4
	VNOTE B_, 4
	OCTAVE 4
	VNOTE C#, 3
	VNOTE E_, 3
	VNOTE G#, 3
	VNOTE B_, 3
	OCTAVE 5
	VNOTE D#, 3
	OCTAVE 4
	VNOTE B_, 3
	OCTAVE 4
	VNOTE C#, 1
	VNOTE E_, 1
	VNOTE G#, 1
	VNOTE B_, 1
	OCTAVE 5
	VNOTE D#, 1
	OCTAVE 4
	VNOTE B_, 1
	SND_END

; Orphan stream (decoded as SfxN; no header or call reaches it)
Data_5705:
	NVOICE $04, $80
	SND_END

Snd28_SfxN:
	NVOICE $05, $86
	NOISE $5C
	NOISE $5B
	NOISE $5C
	NOISE $5D
	SND_END

Snd29_Sfx1:
	VVOICE $02, $80, $00
	OCTAVE 4
	VNOTE E_, 9
	VNOTE G#, 9
	VNOTE B_, 9
	OCTAVE 5
	VNOTE D#, 9
	VNOTE F#, 9
	VNOTE D#, 9
	OCTAVE 4
	VNOTE E_, 8
	VNOTE G#, 8
	VNOTE B_, 8
	OCTAVE 5
	VNOTE D#, 8
	VNOTE F#, 8
	VNOTE D#, 8
	OCTAVE 4
	VNOTE E_, 7
	VNOTE G#, 7
	VNOTE B_, 7
	OCTAVE 5
	VNOTE D#, 7
	VNOTE F#, 7
	VNOTE D#, 7
	OCTAVE 4
	VNOTE E_, 6
	VNOTE G#, 6
	VNOTE B_, 6
	OCTAVE 5
	VNOTE D#, 6
	VNOTE F#, 6
	VNOTE D#, 6
	OCTAVE 4
	VNOTE E_, 5
	VNOTE G#, 5
	VNOTE B_, 5
	OCTAVE 5
	VNOTE D#, 5
	VNOTE F#, 5
	VNOTE D#, 5
	OCTAVE 4
	VNOTE E_, 4
	VNOTE G#, 4
	VNOTE B_, 4
	OCTAVE 5
	VNOTE D#, 4
	VNOTE F#, 4
	VNOTE D#, 4
	OCTAVE 4
	VNOTE E_, 3
	VNOTE G#, 3
	VNOTE B_, 3
	OCTAVE 5
	VNOTE D#, 3
	VNOTE F#, 3
	VNOTE D#, 3
	OCTAVE 4
	VNOTE E_, 2
	VNOTE G#, 2
	VNOTE B_, 2
	OCTAVE 5
	VNOTE D#, 2
	VNOTE F#, 2
	VNOTE D#, 2
	OCTAVE 4
	VNOTE E_, 1
	VNOTE G#, 1
	VNOTE B_, 1
	OCTAVE 5
	VNOTE D#, 1
	VNOTE F#, 1
	VNOTE D#, 1
	SND_END

Snd2A_SfxN:
	NVOICE $08, $70
	NOISE $2F
	NOISE $2E
	NOISE $2D
	NOISE $2C
	NOISE $2B
	NOISE $2A
	NOISE $29
	NOISE $28
	NOISE $27
	NOISE $26
	NOISE $25
	NOISE $24
	NOISE $23
	NOISE $22
	NOISE $21
	NOISE $20
	NOISE $3F
	NOISE $3E
	NOISE $3D
	NOISE $3C
	NOISE $3B
	NOISE $3A
	NOISE $39
	NOISE $38
	NOISE $37
	NOISE $36
	NOISE $35
	NOISE $34
	NOISE $33
	NOISE $32
	NOISE $31
	NOISE $30
	NOISE $4F
	NOISE $4E
	NOISE $4D
	NOISE $4C
	NOISE $4B
	NOISE $4A
	NOISE $49
	NOISE $48
	NOISE $47
	NOISE $46
	NOISE $45
	NOISE $44
	NOISE $43
	NOISE $42
	NOISE $41
	NOISE $40
	SND_END

Snd2B_Sfx1:
	VVOICE $02, $80, $00
	OCTAVE 3
	VNOTE A_, 9
	VNOTE B_, 9
	OCTAVE 4
	VNOTE C_, 9
	VNOTE E_, 9
	OCTAVE 5
	VNOTE D_, 9
	VNOTE B_, 9
	OCTAVE 3
	VNOTE A_, 8
	VNOTE B_, 8
	OCTAVE 4
	VNOTE C_, 8
	VNOTE E_, 8
	OCTAVE 5
	VNOTE D_, 8
	VNOTE B_, 8
	OCTAVE 3
	VNOTE A_, 7
	VNOTE B_, 7
	OCTAVE 4
	VNOTE C_, 7
	VNOTE E_, 7
	OCTAVE 5
	VNOTE D_, 7
	VNOTE B_, 7
	OCTAVE 3
	VNOTE A_, 6
	VNOTE B_, 6
	OCTAVE 4
	VNOTE C_, 6
	VNOTE E_, 6
	OCTAVE 5
	VNOTE D_, 6
	VNOTE B_, 6
	SND_END

Snd2C_SfxN:
	NVOICE $04, $70
	NOISE $51
	NOISE $57
	NOISE $52
	NOISE $53
	NOISE $37
	NOISE $36
	NOISE $34
	NOISE $66
	NOISE $63
	NOISE $62
	NOISE $61
	NOISE $41
	NOISE $47
	NOISE $42
	NOISE $43
	NOISE $27
	NOISE $26
	NOISE $24
	NOISE $55
	NOISE $53
	NOISE $52
	NOISE $51
	NOISE $53
	NOISE $56
	NOISE $52
	NOISE $51
	NOISE $51
	NOISE $53
	NOISE $56
	NOISE $52
	NOISE $51
	NOISE $51
	NOISE $00
	NOISE $00
	NOISE $00
	NOISE $01
	NOISE $01
	NOISE $01
	NOISE $02
	NOISE $02
	NOISE $02
	NOISE $03
	NOISE $03
	NOISE $03
	NOISE $04
	NOISE $04
	NOISE $04
	NOISE $05
	NOISE $05
	NOISE $05
	SND_END

Snd2D_Sfx1:
	VVOICE $02, $80, $00
	OCTAVE 4
	VNOTE E_, 9
	VNOTE E_, 7
	VNOTE G#, 9
	VNOTE G#, 7
	VNOTE B_, 9
	VNOTE B_, 7
	OCTAVE 5
	VNOTE D#, 9
	VNOTE D#, 7
	VNOTE F#, 9
	VNOTE F#, 8
	VNOTE D#, 9
	VNOTE D#, 7
	OCTAVE 4
	VNOTE E_, 7
	VNOTE E_, 5
	VNOTE G#, 7
	VNOTE G#, 5
	VNOTE B_, 7
	VNOTE B_, 5
	OCTAVE 5
	VNOTE D#, 7
	VNOTE D#, 5
	VNOTE F#, 7
	VNOTE F#, 6
	VNOTE D#, 7
	VNOTE D#, 5
	OCTAVE 4
	VNOTE E_, 5
	VNOTE E_, 3
	VNOTE G#, 5
	VNOTE G#, 3
	VNOTE B_, 5
	VNOTE B_, 3
	OCTAVE 5
	VNOTE D#, 5
	VNOTE D#, 3
	VNOTE F#, 5
	VNOTE F#, 4
	VNOTE D#, 5
	VNOTE D#, 3
	VNOTE D#, 2
	VNOTE D#, 1
	VNOTE D#, 1
	SND_END

Snd2D_SfxN:
	NVOICE $04, $70
	NOISE $00
	NOISE $00
	NOISE $03
	NOISE $03
	NOISE $03
	NOISE $06
	NOISE $06
	NOISE $06
	NOISE $09
	NOISE $09
	NOISE $09
	NOISE $56
	NOISE $54
	NOISE $52
	NOISE $64
	NOISE $52
	NOISE $53
	NOISE $56
	NOISE $53
	NOISE $53
	NOISE $52
	NOISE $51
	NOISE $51
	NOISE $51
	NOISE $56
	NOISE $51
	NOISE $53
	NOISE $59
	NOISE $53
	NOISE $51
	NOISE $55
	NOISE $57
	NOISE $52
	NOISE $54
	NOISE $54
	NOISE $51
	NOISE $51
	NOISE $41
	NOISE $41
	NOISE $31
	NOISE $31
	NOISE $21
	NOISE $21
	NOISE $11
	NOISE $11
	NOISE $10
	NOISE $01
	SND_END

Snd2E_SfxN:
	NVOICE $0F, $83
	NOISE $56
	NOISE $52
	NOISE $54
	NOISE $56
	NOISE $52
	NOISE $54
	NOISE $51
	NOISE $56
	NOISE $53
	NOISE $01
	NOISE $11
	NOISE $06
	NOISE $0F
	NOISE $0E
	NOISE $0D
	NOISE $0C
	NOISE $0B
	NOISE $0A
	NOISE $09
	NOISE $08
	NOISE $07
	NOISE $06
	NOISE $05
	NOISE $04
	NOISE $03
	NOISE $02
	NOISE $01
	NOISE $00
	NOISE $08
	NOISE $07
	NOISE $06
	NOISE $05
	NOISE $04
	NOISE $03
	NOISE $02
	NOISE $01
	NOISE $09
	NOISE $08
	NOISE $07
	NOISE $06
	NOISE $05
	NOISE $04
	NOISE $03
	NOISE $02
	NOISE $01
	NOISE $00
	SND_END

Snd2F_Sfx1:
	VVOICE $02, $80, $00
	OCTAVE 4
	VNOTE C#, 7
	VNOTE C#, 2
	VNOTE D#, 7
	VNOTE D#, 2
	VNOTE E_, 7
	VNOTE E_, 2
	VNOTE F#, 7
	VNOTE F#, 2
	VNOTE G#, 7
	VNOTE G#, 2
	VNOTE A_, 7
	VNOTE A_, 2
	VNOTE B_, 7
	VNOTE B_, 2
	OCTAVE 5
	VNOTE C#, 7
	VNOTE C#, 2
	VNOTE D_, 9
	OCTAVE 4
	VNOTE B_, 9
	VNOTE G_, 9
	VNOTE E_, 9
	OCTAVE 5
	VNOTE F#, 9
	VNOTE D_, 9
	OCTAVE 4
	VNOTE B_, 9
	VNOTE G_, 9
	OCTAVE 5
	VNOTE F#, 5
	VNOTE D_, 5
	OCTAVE 4
	VNOTE B_, 5
	VNOTE G_, 5
	OCTAVE 5
	VNOTE F#, 3
	VNOTE D_, 3
	OCTAVE 4
	VNOTE B_, 3
	VNOTE G_, 3
	OCTAVE 5
	VNOTE A_, 9
	VNOTE F_, 9
	VNOTE D_, 9
	OCTAVE 4
	VNOTE A#, 9
	OCTAVE 5
	VNOTE A_, 5
	VNOTE F_, 5
	VNOTE D_, 5
	OCTAVE 4
	VNOTE A#, 5
	OCTAVE 5
	VNOTE A_, 3
	VNOTE F_, 3
	VNOTE D_, 3
	OCTAVE 4
	VNOTE A#, 3
	OCTAVE 5
	VNOTE A_, 1
	VNOTE F_, 1
	VNOTE D_, 1
	OCTAVE 4
	VNOTE A#, 1
	OCTAVE 5
	VNOTE C#, 9
	VNOTE A_, 9
	VNOTE F#, 9
	VNOTE D_, 9
	VNOTE C#, 9
	OCTAVE 4
	VNOTE A_, 7
	OCTAVE 5
	VNOTE C#, 7
	VNOTE A_, 7
	VNOTE F#, 7
	VNOTE D_, 7
	VNOTE C#, 7
	OCTAVE 4
	VNOTE A_, 5
	OCTAVE 5
	VNOTE C#, 5
	VNOTE A_, 5
	VNOTE F#, 5
	VNOTE D_, 5
	VNOTE C#, 5
	OCTAVE 4
	VNOTE A_, 3
	OCTAVE 5
	VNOTE C#, 2
	VNOTE A_, 2
	VNOTE F#, 2
	VNOTE D_, 2
	VNOTE C#, 2
	OCTAVE 4
	VNOTE A_, 1
	SND_END

Snd30_SfxN:
	NVOICE $05, $70
	NOISE $36
	NOISE $25
	NOISE $12
	NOISE $07
	NOISE $07
	NOISE $06
	NOISE $06
	NOISE $05
	NOISE $05
	NOISE $04
	NOISE $04
	NOISE $03
	NOISE $03
	NOISE $02
	NOISE $02
	NOISE $01
	NOISE $01
	NOISE $00
	NOISE $00
	SND_END

Snd31_Sfx1:
	VVOICE $01, $80, $00
	OCTAVE 3
	VNOTE C#, 9
	VNOTE C#, 7
	VNOTE C#, 4
	VNOTE E_, 9
	VNOTE E_, 7
	VNOTE E_, 4
	VNOTE G_, 9
	VNOTE G_, 7
	VNOTE G_, 4
	VNOTE B_, 9
	VNOTE B_, 7
	VNOTE B_, 4
	VNOTE A#, 9
	VNOTE A#, 7
	VNOTE A#, 4
	VNOTE G_, 9
	VNOTE E_, 9
	VNOTE C#, 9
	VNOTE D_, 9
	VNOTE F_, 9
	VNOTE G#, 9
	OCTAVE 4
	VNOTE B_, 9
	OCTAVE 3
	VNOTE B_, 9
	VNOTE G#, 9
	VNOTE F_, 9
	VNOTE D_, 9
	VNOTE D#, 9
	VNOTE F#, 9
	VNOTE A_, 9
	OCTAVE 4
	VNOTE B_, 9
	VNOTE D#, 9
	OCTAVE 3
	VNOTE F#, 9
	VNOTE A_, 9
	OCTAVE 4
	VNOTE C_, 9
	VNOTE D#, 9
	VNOTE F#, 9
	OCTAVE 3
	VNOTE A_, 9
	OCTAVE 4
	VNOTE C_, 9
	VNOTE D#, 9
	VNOTE F#, 9
	VNOTE A_, 9
	VNOTE C_, 9
	VNOTE D#, 9
	VNOTE F#, 9
	VNOTE A_, 9
	OCTAVE 5
	VNOTE C_, 9
	SND_END

Snd32_Sfx1:
	VVOICE $01, $80, $00
	OCTAVE 2
	VNOTE A_, 9
	VNOTE A#, 9
	VNOTE B_, 9
	OCTAVE 3
	VNOTE C_, 9
	VNOTE C#, 9
	VNOTE D_, 9
	VNOTE D#, 9
	VNOTE E_, 9
	VNOTE F_, 9
	VNOTE F#, 9
	VNOTE G_, 9
	VNOTE G#, 9
	VNOTE A_, 9
	VNOTE A#, 9
	VNOTE B_, 9
	OCTAVE 4
	VNOTE C_, 9
	VNOTE C#, 9
	VNOTE D_, 9
	VNOTE D#, 9
	VNOTE E_, 9
	VNOTE F_, 9
	SND_END

Snd33_Sfx1:
	VVOICE $06, $80, $00
	OCTAVE 1
	VNOTE B_, 15
	OCTAVE 2
	VNOTE D_, 15
	VNOTE G#, 15
	VNOTE D_, 15
	VNOTE G#, 15
	VNOTE B_, 15
	VNOTE D_, 15
	VNOTE D_, 2
	VNOTE D_, 2
	VNOTE D_, 2
	VNOTE D_, 2
	VNOTE D_, 1
	VNOTE D_, 1
	VNOTE D_, 1
	VNOTE D_, 1
	VNOTE D_, 1
	VNOTE D_, 1
	VNOTE D_, 1
	SND_END

Snd33_Sfx2:
	VVOICE $06, $80, $00
	TRANSPOSE_UP $0C
	OCTAVE 4
	VNOTE D_, 2
	VNOTE C_, 2
	OCTAVE 3
	VNOTE B_, 2
	VNOTE F_, 2
	VNOTE E_, 2
	VNOTE D#, 2
	VNOTE D_, 2
	VNOTE D_, 6
	VNOTE D_, 6
	VNOTE D_, 6
	VNOTE D_, 6
	VNOTE D_, 8
	VNOTE D_, 8
	VNOTE D_, 8
	VNOTE D_, 8
	VNOTE D_, 8
	VNOTE D_, 8
	VNOTE D_, 8
	SND_END

Snd34_SfxN:
	NVOICE $08, $70
	NOISE $2F
	NOISE $2F
	NOISE $4F
	NOISE $56
	NOISE $52
	NOISE $56
	NOISE $52
	NOISE $56
	NOISE $55
	NOISE $52
	NVOICE $08, $73
	NOISE $51
	NOISE $50
	NOISE $50
	SND_END

Snd35_SfxN:
	NVOICE $01, $80
	NOISE $00
	NOISE $01
	NOISE $01
	NOISE $01
	NOISE $05
	NOISE $05
	NOISE $06
	NOISE $05
	NOISE $03
	NOISE $06
	NOISE $90
	NOISE $98
	NOISE $90
	NOISE $98
	NOISE $80
	NOISE $85
	NOISE $80
	NOISE $86
	NOISE $70
	NOISE $74
	NOISE $70
	NOISE $76
	NOISE $60
	NOISE $65
	NOISE $60
	NOISE $53
	NOISE $44
	NOISE $34
	NOISE $25
	NOISE $17
	NOISE $96
	NOISE $86
	NOISE $76
	NOISE $66
	NOISE $56
	NOISE $46
	NOISE $36
	NOISE $26
	NOISE $16
	NOISE $06
	SND_END

Snd36_SfxN:
	NVOICE $01, $80
	NOISE $00
	NOISE $11
	NOISE $22
	NOISE $33
	NOISE $44
	NOISE $55
	NOISE $96
	NOISE $86
	NOISE $76
	NOISE $66
	NOISE $56
	NOISE $46
	NOISE $36
	NOISE $26
	NOISE $16
	NOISE $06
	SND_END

Snd37_Sfx1:
	SND_END

; Orphan stream (decoded as Sfx1; no header or call reaches it)
Data_59E7:
	VVOICE $02, $80, $00
	OCTAVE 1
	VNOTE C_, 6
	VNOTE C_, 5
	VNOTE C_, 4
	VNOTE C_, 3
	VNOTE C_, 2
	VNOTE E_, 9
	VNOTE D#, 9
	VNOTE E_, 8
	VNOTE D#, 8
	VNOTE E_, 8
	VNOTE E_, 8
	VNOTE E_, 7
	VNOTE F_, 7
	VNOTE E_, 7
	VNOTE E_, 6
	VNOTE E_, 6
	VNOTE E_, 4
	VNOTE F#, 4
	VNOTE E_, 2
	VNOTE E_, 2
	SND_END

Snd37_SfxN:
	NVOICE $08, $80
	NOISE $00
	NOISE $94
	NOISE $95
	NOISE $97
	NOISE $98
	NOISE $94
	NOISE $98
	NOISE $99
	NOISE $94
	NOISE $95
	NOISE $9F
	NOISE $94
	NOISE $97
	NOISE $96
	NOISE $95
	NOISE $94
	NOISE $94
	NOISE $93
	NOISE $98
	NOISE $95
	NOISE $92
	NOISE $9F
	NOISE $94
	NOISE $97
	NOISE $96
	NOISE $95
	NOISE $94
	NOISE $94
	NOISE $93
	NOISE $98
	NOISE $95
	NOISE $92
	NOISE $9F
	NOISE $94
	NOISE $97
	NOISE $96
	NOISE $95
	NOISE $94
	NOISE $94
	NOISE $93
	NOISE $98
	NOISE $95
	NOISE $92
	NOISE $94
	NOISE $95
	NOISE $97
	NOISE $98
	NOISE $94
	NOISE $98
	NOISE $99
	NOISE $94
	NOISE $95
	NOISE $9F
	NOISE $94
	NOISE $97
	NOISE $96
	NOISE $95
	NOISE $94
	NOISE $94
	NOISE $93
	NOISE $98
	NOISE $95
	NOISE $92
	NOISE $9F
	NOISE $94
	NOISE $97
	NOISE $96
	NOISE $95
	NOISE $94
	NOISE $94
	NOISE $93
	NOISE $98
	NOISE $95
	NOISE $92
	NOISE $9F
	NOISE $94
	NOISE $97
	NOISE $96
	NOISE $95
	NOISE $94
	NOISE $94
	NOISE $93
	NOISE $98
	NOISE $95
	NOISE $92
	NOISE $56
	NOISE $60
	NOISE $02
	NOISE $02
	NOISE $01
	NOISE $01
	NOISE $01
	NOISE $01
	NOISE $01
	NOISE $01
	NOISE $01
	SND_END

Snd38_SfxN:
	NVOICE $08, $80
	NOISE $00
	LOOP_BREAK $F9
	LOOP_BREAK $01
	NOISE $01
	NOISE $00
	NOISE $00
	SND_END

Snd39_Sfx1:
	SND_END

; Orphan stream (decoded as Sfx1; no header or call reaches it)
Data_5A72:
	VVOICE $01, $05, $00
	VNOTE G_, 15
	VNOTE G#, 15
	VNOTE G_, 15
	VNOTE F#, 15
	VNOTE G_, 15
	VNOTE F#, 15
	VNOTE G_, 15
	VNOTE G_, 15
	VNOTE G_, 15
	VNOTE F#, 15
	VNOTE F#, 15
	VNOTE G_, 15
	VNOTE F#, 15
	VNOTE F#, 15
	VNOTE E_, 15
	VNOTE F_, 15
	VNOTE F_, 15
	VNOTE F#, 15
	VNOTE F_, 15
	VNOTE F_, 15
	VNOTE E_, 15
	VNOTE F_, 15
	VNOTE E_, 15
	VNOTE E_, 15
	VNOTE D#, 15
	VNOTE E_, 15
	VNOTE D#, 15
	VNOTE D_, 15
	VNOTE D#, 15
	VNOTE D_, 15
	VNOTE D#, 15
	VNOTE D_, 15
	VNOTE D#, 15
	VNOTE D_, 15
	VNOTE C#, 15
	VNOTE D_, 15
	VNOTE C#, 15
	VNOTE C#, 15
	VNOTE C_, 15
	VNOTE C#, 15
	VNOTE C_, 15
	VNOTE C_, 15
	VNOTE C#, 15
	VNOTE C_, 15
	VNOTE C_, 15
	VNOTE C_, 15
	VNOTE C_, 9
	VNOTE C_, 5
	VNOTE C_, 4
	VNOTE C_, 2
	VNOTE C_, 0
	SND_END

Snd39_Sfx2:
	VVOICE $01, $E0, $00
	OCTAVE 2
	VNOTE B_, 2
	VNOTE B_, 2
	VNOTE A#, 2
	VNOTE A#, 2
	VNOTE B_, 2
	VNOTE B_, 2
	VNOTE A#, 2
	VNOTE B_, 2
	VNOTE C_, 2
	VNOTE C#, 2
	VNOTE C_, 2
	VNOTE C#, 2
	VNOTE B_, 2
	VNOTE B_, 2
	VNOTE B_, 2
	VNOTE A#, 2
	VNOTE A#, 2
	VNOTE A#, 2
	VNOTE A#, 2
	VNOTE A#, 2
	VNOTE A_, 2
	VNOTE A#, 2
	VNOTE A_, 2
	VNOTE A#, 2
	VNOTE G#, 2
	VNOTE G_, 2
	VNOTE G#, 2
	VNOTE G#, 2
	VNOTE F#, 2
	VNOTE F#, 2
	VNOTE G_, 2
	VNOTE G#, 2
	VNOTE G_, 2
	VNOTE F#, 2
	VNOTE G_, 2
	VNOTE F#, 2
	VNOTE F_, 2
	VNOTE G_, 2
	VNOTE F#, 3
	VNOTE F#, 2
	VNOTE G_, 2
	VNOTE F#, 2
	VNOTE F#, 2
	VNOTE F_, 2
	VNOTE F#, 2
	VNOTE F_, 2
	VNOTE F_, 2
	VNOTE E_, 2
	VNOTE E_, 2
	VNOTE F_, 2
	VNOTE E_, 2
	VNOTE D#, 2
	VNOTE E_, 2
	VNOTE D#, 2
	VNOTE D#, 2
	VNOTE D#, 2
	VNOTE D_, 2
	VNOTE D#, 2
	VNOTE D_, 2
	VNOTE D#, 2
	VNOTE D_, 2
	VNOTE C#, 2
	VNOTE D_, 2
	VNOTE C#, 2
	VNOTE C#, 2
	VNOTE C_, 2
	VNOTE C#, 2
	VNOTE C_, 2
	VNOTE C_, 2
	VNOTE C_, 4
	VNOTE C#, 4
	VNOTE C#, 4
	VNOTE C#, 6
	VNOTE C_, 6
	VNOTE C_, 6
	VNOTE C_, 6
	VNOTE C_, 6
	VNOTE C_, 6
	SND_END

Snd39_SfxN:
	SND_END

; Orphan stream (decoded as SfxN; no header or call reaches it)
Data_5AFF:
	NVOICE $05, $80
	NOISE $96
	NOISE $56
	NOISE $41
	NOISE $33
	NOISE $52
	NOISE $45
	NOISE $43
	NOISE $03
	NOISE $01
	NOISE $04
	NOISE $01
	NOISE $07
	NOISE $01
	NOISE $02
	NOISE $02
	NOISE $02
	NOISE $03
	NOISE $56
	NOISE $56
	NOISE $51
	NOISE $50
	NOISE $54
	SND_END

Snd3A_Sfx1:
	SND_END

; Orphan stream (decoded as Sfx1; no header or call reaches it)
Data_5B1A:
	SND_SEGNO
	VVOICE $01, $80, $00
	OCTAVE 4
	VNOTE G_, 2
	VNOTE G_, 1
	VNOTE G_, 3
	VNOTE G_, 2
	VNOTE G_, 1
	VNOTE G_, 4
	VNOTE G_, 1
	VNOTE G_, 3
	VNOTE G_, 2
	VNOTE G_, 1
	VVOICE $20, $80, $00
	VREST 0
	SND_LOOP

Snd3A_Sfx2:
	SND_SEGNO
	VVOICE $01, $80, $00
	OCTAVE 5
	VNOTE G_, 4
	VNOTE G_, 6
	VNOTE G_, 2
	VNOTE G_, 4
	VNOTE G_, 6
	VNOTE G_, 2
	VNOTE G_, 6
	VNOTE G_, 4
	VNOTE G_, 4
	VNOTE G_, 6
	VVOICE $20, $80, $00
	VREST 0
	SND_LOOP
	db $FF ; unreachable

Snd3A_SfxN:
	SND_END

Snd3B_Sfx1:
	VVOICE $01, $0A, $00
	TRANSPOSE_DOWN 5
	OCTAVE 3
	VNOTE A_, 2
	VNOTE A#, 6
	VNOTE G#, 6
	VNOTE A_, 7
	VNOTE A#, 9
	VNOTE A_, 5
	VNOTE A#, 8
	VNOTE C#, 2
	VNOTE C_, 2
	VNOTE A#, 8
	VNOTE A#, 8
	OCTAVE 4
	VNOTE F_, 8
	VNOTE F#, 8
	VNOTE F_, 8
	VNOTE F#, 8
	VNOTE F#, 8
	VNOTE F_, 8
	VNOTE F_, 8
	VNOTE D#, 2
	VNOTE E_, 2
	VNOTE D#, 2
	VNOTE E_, 2
	VNOTE D#, 2
	VNOTE D_, 2
	VNOTE C#, 2
	VNOTE D_, 2
	VNOTE D_, 2
	VNOTE C#, 2
	VNOTE D_, 2
	VNOTE C#, 2
	VNOTE C#, 2
	VNOTE C_, 2
	VNOTE C_, 2
	VNOTE C_, 2
	VNOTE C_, 2
	OCTAVE 3
	VNOTE B_, 2
	VNOTE C_, 2
	VNOTE B_, 2
	VNOTE A#, 2
	VNOTE A#, 2
	VNOTE A#, 2
	VNOTE A#, 2
	VNOTE A_, 2
	VNOTE A_, 2
	VNOTE A_, 2
	VNOTE G#, 2
	VNOTE G#, 2
	VNOTE G_, 2
	VNOTE F#, 2
	VNOTE G_, 2
	VNOTE F#, 2
	SND_END

Snd3B_Sfx2:
	VVOICE $01, $E0, $00
	TRANSPOSE_DOWN 5
	OCTAVE 4
	VNOTE A_, 15
	VNOTE A#, 15
	VNOTE G#, 15
	VNOTE A_, 15
	VNOTE A#, 15
	VNOTE A_, 15
	VNOTE A#, 15
	VNOTE C#, 15
	VNOTE C_, 15
	VNOTE A#, 15
	VNOTE A#, 15
	OCTAVE 5
	VNOTE F_, 15
	VNOTE F#, 15
	VNOTE F_, 15
	VNOTE F#, 15
	VNOTE F#, 15
	VNOTE F_, 15
	VNOTE F_, 15
	VNOTE D#, 2
	VNOTE E_, 2
	VNOTE D#, 2
	VNOTE E_, 2
	VNOTE D#, 2
	VNOTE D_, 2
	VNOTE C#, 2
	VNOTE D_, 2
	VNOTE D_, 2
	VNOTE C#, 2
	VNOTE D_, 2
	VNOTE C#, 2
	VNOTE C#, 2
	VNOTE C_, 2
	VNOTE C_, 15
	VNOTE C_, 15
	VNOTE C_, 15
	OCTAVE 4
	VNOTE B_, 15
	VNOTE C_, 15
	VNOTE B_, 15
	VNOTE A#, 15
	VNOTE A#, 15
	VNOTE A#, 15
	VNOTE A#, 15
	VNOTE A_, 15
	VNOTE A_, 15
	VNOTE A_, 15
	VNOTE G#, 15
	VNOTE G#, 15
	VNOTE G_, 15
	VNOTE F#, 15
	VNOTE G_, 15
	VNOTE F#, 15
	SND_END

Snd3B_SfxN:
	SND_END

; Orphan stream (decoded as SfxN; no header or call reaches it)
Data_5BC3:
	NVOICE $05, $80
	NOISE $96
	NOISE $56
	NOISE $41
	NOISE $33
	NOISE $52
	NOISE $45
	NOISE $43
	NOISE $03
	NOISE $01
	NOISE $04
	NOISE $01
	NOISE $07
	NOISE $01
	NOISE $02
	NOISE $02
	NOISE $02
	NOISE $03
	NOISE $56
	NOISE $56
	NOISE $51
	NOISE $50
	NOISE $54
	SND_END

Snd3C_Sfx1:
	SND_END

; Orphan stream (decoded as Sfx1; no header or call reaches it)
Data_5BDE:
	VVOICE $01, $82, $00
	OCTAVE 5
	VNOTE C#, 8
	VNOTE D#, 5
	VNOTE D_, 5
	VNOTE G_, 4
	VNOTE E_, 4
	VNOTE D_, 1
	VNOTE F_, 5
	VNOTE F_, 2
	VNOTE D_, 4
	VNOTE C_, 8
	VNOTE F#, 5
	VNOTE E_, 4
	VNOTE D_, 5
	VNOTE G#, 5
	VNOTE G#, 4
	VNOTE C#, 5
	SND_END

Snd3C_Sfx2:
	SND_END

Snd3C_SfxN:
	NVOICE $01, $9F
	NOISE $0F
	NOISE $1F
	NOISE $1F
	NOISE $0E
	NOISE $1D
	NOISE $1E
	NOISE $0F
	SND_END

Snd3D_SfxN:
	NVOICE $0A, $85
	NOISE $46
	NOISE $46
	NOISE $46
	NOISE $46
	SND_END

; Orphan stream (decoded as Ch1; no header or call reaches it)
Data_5C08:
	VOICE $0A, 8, 12, 0, 3
	REST 1
	ATTEN 3
	OCTAVE 1
	NOTE D_, 1
	ATTEN 3
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
	RELEASE 6, 4
	NOTE A#, 4
	SND_END

; Orphan stream (decoded as Ch2; no header or call reaches it)
Data_5C27:
	PAN_LEFT $0E
	VOICE $0A, 8, 5, 0, 15
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

; Orphan stream (decoded as Ch3; no header or call reaches it)
Data_5C3A:
	DETUNE $0F
	AUTOPAN 2
	VOICE $0A, 6, 4, 0, 15
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

Snd3E_SfxN:
	NVOICE $01, $47
	NOISE $51
	NOISE $41
	SND_END

Snd41_Ch2:
	SND_SEGNO
	VOICE $09, 4, 7, 2, 2
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 4
	NOTE C#, 4
	NOTE E_, 4
	NOTE E_, 8
	NOTE D_, 4
	NOTE C#, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE G#, 4
	NOTE A_, 4
	NOTE E_, 8
	OCTAVE 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE G#, 4
	NOTE C#, 8
	NOTE F#, 4
	NOTE D#, 4
	NOTE C#, 4
	NOTE D#, 4
	NOTE E_, 12
	NOTE D_, 8
	NOTE C#, 4
	OCTAVE 3
	NOTE B_, 8
	OCTAVE 4
	NOTE F#, 4
	NOTE D#, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE A_, 8
	NOTE C#, 4
	NOTE C#, 4
	OCTAVE 3
	NOTE A#, 4
	NOTE B_, 4
	OCTAVE 4
	NOTE F#, 4
	NOTE E_, 4
	OCTAVE 3
	NOTE G#, 4
	NOTE A_, 12
	NOTE F#, 4
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 4
	SND_LOOP

Snd41_Ch1:
	SND_SEGNO
	VOICE $09, 4, 3, 3, 6
	DETUNE $01
	REST 1
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 4
	NOTE C#, 4
	NOTE E_, 4
	NOTE E_, 8
	NOTE D_, 4
	NOTE C#, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE G#, 4
	NOTE A_, 4
	NOTE E_, 8
	OCTAVE 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE G#, 4
	NOTE C#, 8
	NOTE F#, 4
	NOTE D#, 4
	NOTE C#, 4
	NOTE D#, 4
	NOTE E_, 12
	NOTE D_, 8
	NOTE C#, 4
	OCTAVE 3
	NOTE B_, 8
	OCTAVE 4
	NOTE F#, 4
	NOTE D#, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE A_, 8
	NOTE C#, 4
	NOTE C#, 4
	OCTAVE 3
	NOTE A#, 4
	NOTE B_, 4
	OCTAVE 4
	NOTE F#, 4
	NOTE E_, 4
	OCTAVE 3
	NOTE G#, 4
	NOTE A_, 12
	NOTE F#, 4
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE B_, 3
	SND_LOOP

Snd41_Ch3:
	SND_SEGNO
	VOICE $09, 6, 4, 3, 4
	OCTAVE 2
	NOTE C#, 2
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE F#, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE G#, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE F#, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE F#, 2
	NOTE C#, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE F#, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE F#, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE F#, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 2
	NOTE G#, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE G#, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE G#, 2
	NOTE B_, 2
	NOTE G#, 2
	NOTE D_, 2
	NOTE B_, 2
	NOTE C#, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 2
	NOTE F#, 2
	NOTE C#, 2
	NOTE A_, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE B_, 2
	NOTE F#, 2
	NOTE B_, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE E_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE E_, 2
	OCTAVE 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE B_, 2
	SND_LOOP

Snd41_Drm:
	SND_END

Snd42_Ch2:
	SND_SEGNO
	VOICE $05, 8, 8, 12, 4
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE F_, 2
	NOTE D_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE A#, 2
	SND_LOOP

Snd42_Ch1:
	SND_SEGNO
	VOICE $05, 8, 6, 12, 4
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C#, 2
	NOTE C#, 2
	SND_LOOP

Snd42_Ch3:
	SND_SEGNO
	VOICE $05, 14, 2, 11, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE G#, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE G#, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	SND_LOOP

Snd42_Drm:
	SND_SEGNO
	LEN_UNIT $05
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 9, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 9, 2
	DRUM $0C, 2
	DRUM 9, 2
	DRUM $0C, 2
	DRUM 9, 2
	SND_LOOP

; Unused ($FF) to the end of the bank.
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

SECTION "Sound bank 15", ROMX[$4000], BANK[15]

; SoundTable15: bank-15 ids $51-$66 (the code adds 2 * (id - $50) to $3FFE; id $50 reads
; ROM0 $3FFE).
SoundTable15:
	dw SndHdr51 ; $51
	dw SndHdr52 ; $52
	dw SndHdr53 ; $53
	dw SndHdr54 ; $54
	dw SndHdr55 ; $55
	dw SndHdr56 ; $56
	dw SndHdr57 ; $57
	dw SndHdr58 ; $58
	dw SndHdr59 ; $59
	dw SndHdr57 ; $5A
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

SndHdr51:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd51_Ch1
	dw Snd51_Ch2
	dw Snd51_Ch3
	dw Snd51_Drm

SndHdr52:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd52_Ch1
	dw Snd52_Ch2
	dw Snd52_Ch3
	dw Snd52_Drm

SndHdr53:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd53_Ch1
	dw Snd53_Ch2
	dw Snd53_Ch3
	dw Snd53_Drm

SndHdr54:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd54_Ch1
	dw Snd54_Ch2
	dw Snd54_Ch3
	dw Snd54_Drm

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

SndHdr58:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd58_Ch1
	dw Snd58_Ch2
	dw Snd58_Ch3
	dw Snd58_Drm

SndHdr59:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd59_Ch1
	dw Snd59_Ch2
	dw Snd59_Ch3
	dw Snd59_Drm

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

SndHdr66:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd66_Ch1
	dw Snd66_Ch2
	dw Snd66_Ch3
	dw Snd66_Drm

SndHdr57:
	SND_HEADER $40, $78 ; tracks: Ch1, Ch2, Ch3, Drm
	dw Snd57_Ch1
	dw Snd57_Ch1
	dw Snd57_Ch1
	dw Snd57_Ch1

Snd57_Ch1:
	SND_END

Snd51_Ch2:
	TEMPO $08
	VOICE $06, 4, 8, 6, 1
	RELEASE_VOL 2
	SND_SEGNO
	OCTAVE 4
	NOTE D_, 8
	NOTE C_, 4
	OCTAVE 3
	NOTE A#, 4
	NOTE A_, 3
	NOTE D_, 1
	NOTE D_, 8
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D#, 3
	NOTE A#, 1
	NOTE A#, 8
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 3
	NOTE D_, 1
	NOTE D_, 8
	REST 4
	OCTAVE 4
	NOTE D_, 8
	NOTE C_, 4
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 3
	NOTE D_, 1
	NOTE D_, 8
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D#, 3
	NOTE A#, 1
	NOTE A#, 8
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 3
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 8
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 8
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 8
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE D#, 2
	NOTE F_, 1
	NOTE D_, 3
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 8
	NOTE G_, 1
	NOTE A_, 2
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 3
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 8
	REST 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 6
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE G_, 2
	NOTE D_, 8
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 3
	NOTE G_, 1
	NOTE G_, 7
	NOTE F_, 1
	NOTE F_, 1
	NOTE A#, 2
	NOTE G#, 1
	NOTE G_, 0
	SND_LOOP
	db $FF ; unreachable

Snd51_Ch3:
	SND_SEGNO
	VOICE $06, 14, 4, 6, 2
	OCTAVE 2
	NOTE D_, 4
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 2
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 4
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE C_, 4
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 4
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 2
	NOTE A_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE D_, 4
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE A#, 2
	REST 1
	NOTE D#, 1
	NOTE D#, 2
	NOTE D_, 4
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 2
	NOTE C#, 1
	NOTE C_, 4
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE G_, 2
	NOTE C_, 1
	NOTE D_, 4
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE C_, 4
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 4
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE D#, 4
	NOTE D#, 1
	NOTE D#, 2
	NOTE D#, 1
	NOTE D#, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE C_, 4
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE A#, 4
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G_, 4
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D_, 1
	SND_LOOP
	db $FF ; unreachable

Snd51_Ch1:
	SND_SEGNO
	VOICE $06, 8, 4, 8, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F_, 1
	NOTE D_, 1
	REST 1
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE D#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE D#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F_, 1
	REST 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
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
	SND_LOOP
	db $FF ; unreachable

Snd51_Drm:
	SND_SEGNO
	LEN_UNIT $06
	DRUM $0C, 4
	LEN_UNIT $02
	DRUM 9, 4
	DRUM 9, 4
	DRUM 9, 4
	LEN_UNIT $06
	DRUM 3, 2
	DRUM 3, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0C, 4
	LEN_UNIT $02
	DRUM 9, 4
	DRUM 9, 4
	DRUM 9, 4
	LEN_UNIT $06
	DRUM 3, 2
	DRUM 3, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	LEN_UNIT $06
	DRUM $0C, 4
	LEN_UNIT $02
	DRUM 9, 4
	DRUM 9, 4
	DRUM 9, 4
	LEN_UNIT $06
	DRUM 3, 2
	DRUM 3, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0C, 4
	LEN_UNIT $02
	DRUM 9, 4
	DRUM 9, 4
	DRUM 9, 4
	LEN_UNIT $06
	DRUM 3, 2
	DRUM 3, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0C, 4
	LEN_UNIT $02
	DRUM 9, 4
	DRUM 9, 4
	DRUM 9, 4
	LEN_UNIT $06
	DRUM 3, 2
	DRUM 3, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0C, 4
	LEN_UNIT $02
	DRUM 9, 4
	DRUM 9, 4
	DRUM 9, 4
	LEN_UNIT $06
	DRUM 3, 2
	DRUM 3, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	LEN_UNIT $06
	DRUM $0C, 4
	LEN_UNIT $02
	DRUM 9, 4
	DRUM 9, 4
	DRUM 9, 4
	LEN_UNIT $06
	DRUM 3, 2
	DRUM 3, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0C, 4
	LEN_UNIT $02
	DRUM 9, 4
	DRUM 9, 4
	DRUM 9, 4
	LEN_UNIT $06
	DRUM 3, 2
	DRUM 3, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 3, 2
	DRUM 3, 2
	DRUM $0C, 2
	DRUM 2, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 3, 2
	DRUM 3, 2
	DRUM $0C, 2
	DRUM 2, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 3, 2
	DRUM 3, 2
	DRUM $0C, 2
	DRUM 2, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 3, 2
	DRUM 3, 2
	DRUM $0C, 2
	DRUM 2, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 3, 2
	DRUM 3, 2
	DRUM $0C, 2
	DRUM 2, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 2
	DRUM 4, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 2, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0C, 4
	LEN_UNIT $02
	DRUM 9, 4
	DRUM 9, 4
	DRUM 9, 4
	LEN_UNIT $06
	DRUM 3, 2
	DRUM 3, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	SND_LOOP

Snd52_Ch2:
	SND_SEGNO
	TEMPO $20
	VOICE $06, 4, 8, 8, 5
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE D#, 2
	NOTE G#, 1
	NOTE F_, 9
	NOTE D#, 2
	NOTE C#, 2
	NOTE D#, 3
	NOTE G#, 3
	NOTE F_, 6
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE A#, 3
	OCTAVE 4
	NOTE F_, 3
	NOTE D#, 6
	NOTE C#, 2
	NOTE D#, 2
	LEN_UNIT $02
	NOTE F_, 8
	NOTE D#, 8
	NOTE A#, 8
	NOTE F_, 8
	NOTE D#, 8
	NOTE C#, 8
	LEN_UNIT $06
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 1
	NOTE F_, 4
	OCTAVE 3
	NOTE A#, 3
	OCTAVE 4
	NOTE D#, 4
	NOTE C#, 2
	REST 1
	NOTE C_, 3
	NOTE C#, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE A#, 4
	NOTE G#, 4
	OCTAVE 5
	NOTE C#, 2
	OCTAVE 4
	NOTE B_, 2
	NOTE A#, 2
	NOTE G#, 2
	OCTAVE 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 3
	OCTAVE 3
	NOTE A#, 3
	OCTAVE 4
	NOTE A#, 2
	NOTE C_, 3
	OCTAVE 3
	NOTE A#, 3
	OCTAVE 4
	NOTE A#, 2
	NOTE C_, 3
	OCTAVE 3
	NOTE A#, 3
	OCTAVE 4
	NOTE A#, 2
	NOTE C_, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE C_, 3
	OCTAVE 3
	NOTE A#, 3
	OCTAVE 4
	NOTE A#, 2
	NOTE C_, 3
	OCTAVE 3
	NOTE A#, 3
	OCTAVE 4
	NOTE A#, 2
	NOTE C_, 3
	OCTAVE 3
	NOTE A#, 3
	OCTAVE 4
	NOTE A#, 2
	NOTE C_, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE F#, 1
	NOTE F_, 1
	OCTAVE 5
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 5
	NOTE D#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 5
	NOTE F#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE C_, 1
	REST 4
	REST 4
	SND_LOOP

Snd52_Ch1:
	SND_SEGNO
	VOICE $06, 4, 4, 8, 5
	REST 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE C#, 2
	NOTE C_, 2
	NOTE C#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C#, 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE C#, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE G#, 2
	REST 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE C#, 2
	NOTE C_, 2
	NOTE C#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C#, 2
	NOTE C_, 2
	NOTE D#, 2
	NOTE C#, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE F_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE F_, 1
	REST 1
	OCTAVE 3
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE G#, 1
	NOTE C_, 1
	NOTE D#, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 4
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE F#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE C#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE A#, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE A_, 1
	SND_LOOP

Snd52_Ch3:
	SND_SEGNO
	VOICE $06, 13, 2, 8, 2
	OCTAVE 1
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
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
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
	NOTE G_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE G#, 1
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
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 1
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
	NOTE G_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE C#, 1
	OCTAVE 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 1
	NOTE G#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D#, 1
	OCTAVE 1
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
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE B_, 4
	NOTE A#, 4
	NOTE A_, 4
	NOTE G#, 4
	NOTE F_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE C_, 1
	SND_LOOP

Snd52_Drm:
	SND_SEGNO
	LEN_UNIT $06
	DRUM $0C, 4
	REST 4
	REST 4
	REST 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 4
	REST 4
	REST 4
	REST 4
	DRUM $0C, 4
	REST 4
	REST 4
	REST 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 4
	REST 4
	DRUM 2, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM $0C, 1
	LOOP_START
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	LOOP_END $0E
	DRUM 2, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	LOOP_START
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	LOOP_END $0E
	SND_LOOP

Snd53_Ch2:
	SND_SEGNO
	VOICE $05, 4, 8, 6, 1
	RELEASE_VOL 7
	OCTAVE 3
	NOTE G#, 1
	REST 1
	NOTE G#, 1
	REST 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F_, 8
	NOTE G#, 1
	REST 1
	NOTE G#, 1
	REST 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F_, 8
	NOTE A#, 1
	REST 1
	NOTE A#, 1
	REST 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G#, 8
	NOTE G_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE G#, 1
	REST 1
	NOTE G#, 1
	REST 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F_, 6
	NOTE G_, 2
	NOTE G#, 1
	REST 1
	NOTE G#, 1
	REST 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F_, 6
	NOTE G#, 2
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 4
	OCTAVE 3
	NOTE F_, 4
	OCTAVE 4
	NOTE C_, 6
	NOTE C#, 2
	NOTE C_, 2
	NOTE F_, 4
	OCTAVE 3
	NOTE G#, 2
	OCTAVE 4
	NOTE C_, 6
	OCTAVE 3
	NOTE A#, 1
	NOTE G#, 1
	NOTE G_, 4
	REST 1
	NOTE G#, 2
	NOTE A#, 1
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 12
	REST 2
	NOTE C_, 2
	NOTE F_, 6
	NOTE G_, 2
	NOTE G#, 3
	NOTE A#, 3
	OCTAVE 4
	NOTE C_, 2
	NOTE C#, 6
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 3
	OCTAVE 4
	NOTE G#, 3
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 4
	REST 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 4
	REST 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 4
	REST 2
	NOTE C_, 2
	NOTE C_, 8
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE A#, 2
	NOTE F_, 6
	OCTAVE 5
	NOTE C_, 2
	REST 1
	OCTAVE 4
	NOTE A#, 1
	NOTE F_, 2
	OCTAVE 5
	NOTE C_, 2
	OCTAVE 4
	NOTE A#, 2
	NOTE F_, 8
	OCTAVE 5
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE A#, 2
	OCTAVE 5
	NOTE C_, 10
	OCTAVE 4
	NOTE G_, 4
	NOTE A#, 2
	NOTE G#, 3
	NOTE A#, 3
	OCTAVE 5
	NOTE C_, 2
	NOTE C_, 8
	OCTAVE 4
	NOTE G#, 3
	NOTE A#, 3
	NOTE B_, 2
	OCTAVE 5
	NOTE C#, 3
	NOTE D#, 3
	NOTE F_, 2
	NOTE E_, 4
	REST 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 4
	REST 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 3
	NOTE C_, 1
	REST 2
	NOTE C_, 2
	REST 2
	NOTE C_, 2
	REST 1
	NOTE C_, 1
	REST 2
	NOTE E_, 4
	REST 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 4
	REST 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 3
	NOTE C_, 1
	REST 2
	NOTE C_, 2
	REST 2
	NOTE C_, 2
	REST 1
	NOTE C_, 1
	REST 2
	SND_LOOP

Snd53_Ch1:
	SND_SEGNO
	VOICE $05, 7, 6, 6, 2
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
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
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 4
	NOTE G#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE F_, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE G#, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE G#, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE G#, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE G#, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE G#, 1
	NOTE C_, 2
	NOTE F_, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE G_, 1
	NOTE F_, 1
	OCTAVE 5
	NOTE F_, 1
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE F_, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 5
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE F#, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE F#, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C_, 8
	NOTE F_, 8
	REST 2
	OCTAVE 3
	NOTE C_, 2
	REST 1
	NOTE C#, 3
	NOTE D#, 3
	NOTE F_, 3
	NOTE G#, 2
	NOTE A#, 6
	OCTAVE 4
	NOTE D#, 4
	NOTE A#, 4
	NOTE G_, 2
	NOTE G#, 3
	NOTE G_, 3
	NOTE C_, 4
	OCTAVE 3
	NOTE A#, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE F_, 3
	NOTE G_, 3
	NOTE G#, 5
	NOTE A#, 3
	OCTAVE 4
	NOTE F_, 2
	REST 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 5
	NOTE C_, 1
	REST 2
	NOTE C_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 4
	NOTE C_, 1
	REST 2
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 5
	NOTE C_, 1
	REST 2
	NOTE C_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	REST 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 5
	NOTE C_, 1
	REST 2
	NOTE C_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 4
	NOTE C_, 1
	REST 2
	NOTE C_, 1
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 5
	NOTE C_, 1
	REST 2
	NOTE C_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE E_, 1
	NOTE C_, 1
	SND_LOOP

; Orphan music stream (no header points here; decoded as Ch1).
B15_Data_4B3C:
	VOICE $06, 8, 8, 8, 2
	OCTAVE 2
	REST 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C_, 8
	OCTAVE 2
	REST 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C#, 8
	REST 2
	OCTAVE 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D#, 8
	REST 4
	REST 4
	NOTE G_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE G_, 1
	REST 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C_, 8
	REST 2
	OCTAVE 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C#, 8
	REST 2
	OCTAVE 2
	NOTE G_, 2
	NOTE A#, 4
	OCTAVE 3
	NOTE D#, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE G#, 4
	REST 4
	NOTE G#, 6
	NOTE G_, 2
	NOTE G#, 2
	NOTE F_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE G#, 2
	NOTE F_, 3
	NOTE G_, 3
	NOTE G#, 2
	NOTE A#, 8
	OCTAVE 3
	NOTE G_, 4
	NOTE E_, 4
	REST 4
	OCTAVE 2
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE F_, 6
	REST 2
	NOTE G_, 1
	NOTE G#, 2
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 4
	OCTAVE 2
	NOTE C#, 3
	NOTE D#, 3
	NOTE F_, 2
	NOTE G_, 3
	NOTE G#, 3
	NOTE G_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	OCTAVE 3
	REST 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE G#, 4
	OCTAVE 4
	NOTE C_, 8
	NOTE F_, 3
	NOTE C_, 3
	OCTAVE 3
	NOTE G#, 2
	NOTE A#, 10
	NOTE G_, 2
	REST 1
	NOTE D#, 3
	NOTE F_, 3
	NOTE C_, 3
	OCTAVE 2
	NOTE G#, 4
	NOTE G_, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C#, 3
	NOTE F_, 3
	NOTE G#, 2
	NOTE A#, 3
	NOTE G#, 3
	NOTE F_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	SND_SEGNO

Snd53_Ch3:
	SND_SEGNO ; loop byte read both as a start and as an end (see doc)
	VOICE $05, 6, 2, 6, 2
	RELEASE_VOL 6
	OCTAVE 1
	NOTE F_, 0
	REST 2
	NOTE F_, 2
	REST 2
	NOTE F_, 2
	REST 2
	NOTE F_, 2
	NOTE F_, 4
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 4
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 4
	REST 2
	NOTE C_, 2
	REST 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 4
	OCTAVE 3
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 4
	OCTAVE 3
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 1
	NOTE D#, 1
	NOTE C#, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 4
	OCTAVE 3
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 1
	REST 2
	NOTE F_, 2
	REST 1
	NOTE F_, 1
	REST 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 4
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 4
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 4
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 4
	NOTE C_, 4
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE A#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 4
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 4
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 4
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	REST 2
	NOTE F#, 1
	NOTE F#, 1
	REST 2
	NOTE F#, 2
	REST 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	REST 2
	NOTE F#, 1
	NOTE F#, 1
	REST 2
	NOTE F#, 2
	REST 2
	NOTE C_, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	REST 2
	NOTE C_, 1
	NOTE C_, 1
	REST 2
	NOTE C_, 2
	REST 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE C_, 4
	REST 2
	NOTE C_, 1
	NOTE C_, 1
	REST 2
	NOTE C_, 2
	REST 2
	NOTE F#, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	REST 2
	NOTE C_, 1
	NOTE C_, 1
	REST 2
	NOTE C_, 2
	REST 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE C_, 4
	REST 2
	NOTE C_, 1
	NOTE C_, 1
	REST 2
	NOTE C_, 2
	REST 2
	NOTE F#, 2
	SND_LOOP

Snd53_Drm:
	SND_SEGNO
	LEN_UNIT $05
	DRUM $0C, 4
	DRUM 4, 4
	DRUM $0C, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM $0C, 4
	DRUM 4, 4
	DRUM $0C, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM $0C, 4
	DRUM 4, 4
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 4, 4
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 4
	DRUM $0C, 4
	DRUM 4, 4
	DRUM $0C, 4
	DRUM 4, 4
	DRUM $0C, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM $0C, 4
	DRUM 4, 4
	DRUM $0C, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0C, 4
	DRUM 4, 4
	REST 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM $0C, 4
	DRUM 4, 4
	REST 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM $0C, 4
	DRUM 4, 4
	REST 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM $0C, 4
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0C, 4
	DRUM 4, 4
	REST 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM $0C, 4
	DRUM 4, 4
	REST 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM 4, 2
	DRUM $0C, 4
	REST 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0C, 4
	REST 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 4, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 4, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 4, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 4, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 4, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 4, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 4, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 4, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 4, 2
	DRUM $0C, 2
	DRUM $0C, 4
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 4
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0C, 4
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 4
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0C, 4
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 4
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0C, 4
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 4
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	SND_LOOP

Snd54_Ch2:
	SND_SEGNO
	VOICE $06, 4, 8, 8, 4
	RELEASE_VOL 7
	OCTAVE 4
	REST 4
	NOTE C#, 4
	OCTAVE 3
	NOTE F#, 4
	OCTAVE 4
	NOTE F#, 8
	NOTE F_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE B_, 6
	NOTE A_, 2
	NOTE G#, 2
	NOTE A_, 4
	OCTAVE 4
	NOTE C#, 8
	OCTAVE 3
	NOTE B_, 2
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE F#, 2
	NOTE F#, 4
	NOTE F_, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE C#, 2
	NOTE B_, 6
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE A_, 8
	NOTE G#, 6
	NOTE A_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE G#, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE F_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE A#, 4
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE F_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE B_, 2
	NOTE D_, 2
	REST 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE C_, 2
	NOTE C_, 4
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	REST 4
	NOTE F_, 4
	NOTE E_, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE G#, 2
	NOTE A_, 12
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 12
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	REST 2
	OCTAVE 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE A_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE A#, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE G#, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 5
	NOTE C#, 2
	NOTE D_, 2
	OCTAVE 4
	NOTE F_, 2
	OCTAVE 5
	NOTE C#, 2
	OCTAVE 4
	NOTE F_, 2
	NOTE B_, 2
	NOTE F_, 2
	OCTAVE 5
	NOTE C#, 2
	OCTAVE 4
	NOTE F_, 2
	SND_LOOP

Snd54_Ch1:
	SND_SEGNO
	VOICE $06, 4, 8, 8, 4
	RELEASE_VOL 8
	OCTAVE 1
	NOTE F#, 4
	OCTAVE 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE F#, 2
	NOTE B_, 4
	NOTE G#, 4
	OCTAVE 3
	NOTE C#, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE G#, 2
	NOTE G#, 4
	NOTE F#, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE G#, 6
	NOTE A_, 2
	OCTAVE 4
	NOTE C#, 4
	REST 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE C#, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE C_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE G#, 2
	REST 2
	OCTAVE 3
	NOTE E_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE B_, 2
	NOTE G#, 2
	NOTE E_, 2
	OCTAVE 4
	NOTE E_, 6
	NOTE D_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 4
	NOTE F_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE D_, 2
	NOTE F_, 6
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	REST 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE F_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE A_, 2
	NOTE C#, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE G#, 2
	OCTAVE 3
	NOTE G#, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE B_, 2
	SND_LOOP

Snd54_Ch3:
	SND_SEGNO
	VOICE $06, 6, 2, 8, 4
	OCTAVE 3
	REST 4
	NOTE C#, 4
	NOTE F#, 4
	NOTE F#, 4
	NOTE F#, 4
	NOTE F_, 2
	NOTE F#, 2
	NOTE G#, 6
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 4
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE D_, 4
	OCTAVE 1
	NOTE B_, 6
	OCTAVE 2
	NOTE C#, 2
	NOTE D_, 4
	NOTE C#, 10
	NOTE B_, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE F#, 2
	NOTE B_, 4
	LEN_UNIT $02
	OCTAVE 1
	NOTE B_, 4
	OCTAVE 2
	NOTE C#, 4
	NOTE D_, 4
	LEN_UNIT $06
	OCTAVE 2
	NOTE E_, 10
	NOTE F#, 2
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE A#, 2
	NOTE G_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE A_, 2
	NOTE G_, 4
	OCTAVE 1
	NOTE G_, 4
	OCTAVE 2
	NOTE C_, 4
	LEN_UNIT $02
	OCTAVE 1
	NOTE A_, 4
	NOTE B_, 4
	OCTAVE 2
	NOTE C_, 4
	LEN_UNIT $06
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE A_, 2
	NOTE G_, 0
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	OCTAVE 1
	NOTE E_, 4
	NOTE A_, 4
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
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 10
	NOTE B_, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE E_, 4
	OCTAVE 1
	NOTE A_, 2
	NOTE G#, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 4
	OCTAVE 1
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE C#, 2
	NOTE D_, 4
	OCTAVE 1
	NOTE A_, 4
	NOTE D_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE F#, 2
	NOTE C#, 2
	NOTE F#, 2
	OCTAVE 1
	NOTE B_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE A_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE G#, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE C#, 2
	OCTAVE 2
	NOTE F_, 2
	SND_LOOP

Snd54_Drm:
	SND_END

Snd55_Ch2:
	TEMPO $10
	SND_SEGNO
	VOICE $05, 8, 9, 8, 5
	TRANSPOSE_DOWN 1
	OCTAVE 4
	NOTE E_, 6
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE G_, 6
	NOTE F#, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F#, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 6
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 4
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 6
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D#, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE F#, 8
	NOTE G_, 8
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 8
	NOTE D#, 4
	PAN_RIGHT 0
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	PAN_LEFT 0
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE B_, 2
	PAN_BOTH 0
	OCTAVE 3
	NOTE E_, 6
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE G_, 6
	NOTE F#, 1
	NOTE E_, 1
	NOTE D#, 2
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 2
	OCTAVE 4
	NOTE D_, 4
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE B_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE E_, 4
	NOTE D_, 1
	NOTE C#, 1
	NOTE C#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE F#, 2
	REST 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G#, 3
	NOTE F#, 1
	NOTE F_, 2
	NOTE F#, 1
	NOTE G#, 1
	RELEASE_VOL 5
	NOTE A_, 2
	NOTE C#, 2
	NOTE A_, 2
	NOTE C#, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE G#, 2
	NOTE D_, 2
	NOTE G#, 2
	NOTE D_, 2
	NOTE G#, 2
	NOTE C#, 2
	NOTE G#, 2
	NOTE C#, 2
	RELEASE_VOL 8
	NOTE F#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 4
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 1
	NOTE D#, 1
	NOTE E_, 4
	NOTE D#, 2
	NOTE C#, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE B_, 6
	OCTAVE 4
	NOTE D_, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 6
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	OCTAVE 4
	NOTE E_, 2
	REST 2
	NOTE E_, 4
	NOTE D#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE E_, 2
	REST 2
	NOTE E_, 4
	NOTE D#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE G_, 2
	REST 2
	NOTE G_, 4
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE B_, 1
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE B_, 1
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE F#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D#, 1
	SND_LOOP

Snd55_Ch1:
	SND_SEGNO
	RELEASE_VOL 6
	VOICE $05, 6, 8, 8, 7
	TRANSPOSE_DOWN 1
	OCTAVE 4
	NOTE G_, 1
	REST 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	REST 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE B_, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE B_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G#, 1
	NOTE B_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE C#, 1
	REST 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D#, 1
	REST 2
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 5
	NOTE E_, 2
	OCTAVE 4
	NOTE B_, 2
	NOTE G_, 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE E_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE F#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE A#, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE E_, 1
	NOTE G_, 2
	NOTE F#, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE F#, 1
	NOTE D_, 1
	REST 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 2
	REST 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 4
	NOTE G#, 1
	REST 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 2
	NOTE F#, 2
	NOTE E_, 4
	REST 1
	OCTAVE 3
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 6
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 6
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE F#, 1
	NOTE D_, 1
	NOTE B_, 1
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE A_, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE G#, 1
	OCTAVE 5
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE F#, 1
	NOTE D_, 1
	REST 1
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE A_, 6
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE C_, 2
	NOTE E_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE E_, 1
	NOTE B_, 4
	NOTE B_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE B_, 4
	NOTE B_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE B_, 1
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE B_, 1
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 4
	OCTAVE 3
	REST 1
	NOTE C_, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F#, 1
	SND_LOOP

Snd55_Ch3:
	SND_SEGNO
	VOICE $05, 6, 2, 10, 4
	TRANSPOSE_DOWN 1
	OCTAVE 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE C#, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE E_, 4
	REST 2
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	REST 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE E_, 4
	REST 2
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	REST 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE E_, 4
	REST 2
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	REST 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 4
	REST 2
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	REST 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE F#, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE B_, 4
	REST 2
	NOTE G#, 2
	NOTE B_, 2
	NOTE D_, 2
	NOTE C#, 4
	NOTE C#, 4
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE D_, 4
	REST 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE G#, 4
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	NOTE D_, 1
	NOTE C#, 6
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 4
	REST 1
	NOTE G#, 2
	NOTE A#, 1
	NOTE B_, 4
	NOTE B_, 4
	NOTE C#, 4
	NOTE C#, 4
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE C_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE C_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE F#, 2
	SND_LOOP

Snd55_Drm:
	LEN_UNIT $05
	SND_SEGNO
	DRUM 3, 2
	DRUM 4, 1
	DRUM 4, 1
	SND_LOOP

Snd56_Ch2:
	SND_SEGNO
	VOICE $07, 8, 8, 4, 10
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE G_, 4
	NOTE F_, 2
	NOTE D#, 4
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D#, 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 6
	NOTE G#, 6
	NOTE A_, 6
	NOTE B_, 2
	OCTAVE 3
	NOTE B_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE G_, 4
	NOTE F_, 2
	NOTE D#, 4
	NOTE D_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE A#, 3
	NOTE G#, 1
	NOTE G_, 0
	REST 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 3
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 3
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 6
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 6
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE G#, 3
	NOTE G_, 1
	NOTE G_, 6
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 6
	NOTE C_, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE G_, 3
	NOTE F_, 1
	NOTE A#, 6
	NOTE G#, 2
	NOTE G_, 3
	NOTE F_, 1
	NOTE A#, 6
	NOTE G#, 2
	NOTE G_, 4
	NOTE C_, 3
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 3
	NOTE D_, 1
	NOTE F_, 3
	NOTE D#, 1
	NOTE G#, 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE D_, 1
	SND_LOOP

Snd56_Ch1:
	SND_SEGNO
	VOICE $07, 8, 5, 4, 10
	OCTAVE 2
	REST 2
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	REST 2
	NOTE D_, 2
	NOTE D_, 4
	NOTE G_, 2
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	REST 2
	NOTE F_, 2
	NOTE F_, 4
	NOTE G_, 2
	NOTE G_, 2
	REST 2
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	REST 2
	NOTE F_, 2
	NOTE F_, 2
	REST 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D_, 2
	REST 2
	NOTE D_, 2
	NOTE D_, 4
	OCTAVE 2
	NOTE A#, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE F_, 4
	NOTE C#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 2
	NOTE A#, 2
	REST 2
	NOTE G#, 2
	NOTE G#, 4
	NOTE G#, 2
	NOTE G#, 2
	REST 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D#, 4
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 2
	REST 2
	OCTAVE 3
	NOTE F_, 2
	NOTE F_, 4
	NOTE D#, 2
	NOTE D#, 2
	REST 2
	NOTE D#, 2
	NOTE D#, 4
	NOTE D#, 2
	NOTE D#, 2
	REST 2
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	REST 2
	NOTE F_, 2
	NOTE F_, 4
	NOTE F_, 2
	NOTE F_, 2
	REST 4
	REST 4
	OCTAVE 2
	NOTE B_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE B_, 1
	SND_LOOP

Snd56_Ch3:
	SND_SEGNO
	VOICE $07, 4, 2, 6, 2
	TRANSPOSE_DOWN $0C
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE D#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	NOTE C_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE D#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	NOTE C_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE D#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE D#, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE D#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE C_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE D#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE G_, 12
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	SND_LOOP

Snd56_Drm:
	SND_SEGNO
	LOOP_START
	LEN_UNIT $07
	DRUM $0C, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM $0C, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM $0C, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM $0C, 2
	DRUM 1, 2
	DRUM 1, 2
	LOOP_END $07
	DRUM $0C, 4
	DRUM $0C, 4
	DRUM $0C, 4
	DRUM 1, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	DRUM 1, 1
	SND_LOOP

Snd58_Ch2:
	SND_SEGNO
	VOICE $07, 8, 8, 5, 6
	RELEASE_VOL 6
	OCTAVE 3
	REST 2
	NOTE F_, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 4
	REST 2
	NOTE G_, 2
	NOTE A#, 6
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G#, 4
	NOTE F_, 4
	REST 2
	NOTE F_, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE F_, 4
	OCTAVE 3
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 6
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 4
	OCTAVE 4
	NOTE C#, 2
	NOTE C_, 2
	REST 2
	OCTAVE 3
	NOTE F_, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 6
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 4
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE G#, 4
	NOTE F_, 4
	REST 2
	NOTE F_, 2
	NOTE G#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE F_, 4
	OCTAVE 3
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE G_, 1
	NOTE G#, 1
	NOTE F_, 4
	REST 4
	OCTAVE 4
	NOTE F_, 5
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE D#, 4
	REST 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE G#, 2
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE A#, 2
	NOTE G#, 1
	NOTE G_, 4
	NOTE D#, 2
	NOTE D#, 2
	NOTE F_, 4
	REST 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE D#, 4
	REST 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 6
	NOTE G_, 2
	NOTE C#, 1
	NOTE D_, 1
	NOTE F_, 2
	NOTE F_, 6
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 13
	REST 5
	REST 4
	REST 2
	SND_LOOP

Snd58_Ch1:
	SND_SEGNO
	VOICE $07, 6, 7, 4, 6
	OCTAVE 3
	REST 2
	NOTE G#, 2
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE F_, 2
	NOTE C_, 1
	NOTE D_, 3
	OCTAVE 4
	NOTE D_, 5
	NOTE C#, 4
	REST 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE G#, 3
	NOTE G_, 1
	REST 1
	NOTE F_, 2
	NOTE D#, 1
	NOTE F_, 4
	REST 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE G#, 5
	REST 1
	NOTE G#, 1
	NOTE G_, 2
	NOTE F_, 4
	REST 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE G_, 1
	REST 1
	NOTE G#, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE G#, 2
	NOTE G_, 1
	NOTE F_, 1
	NOTE D_, 4
	REST 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 4
	NOTE A#, 1
	NOTE G#, 2
	NOTE G_, 1
	NOTE F_, 4
	NOTE C_, 8
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE A#, 2
	NOTE G#, 1
	NOTE D_, 4
	REST 1
	OCTAVE 3
	NOTE G#, 1
	NOTE A#, 2
	NOTE G#, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	REST 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE F_, 8
	OCTAVE 4
	NOTE C_, 8
	OCTAVE 3
	NOTE A#, 4
	NOTE G#, 4
	OCTAVE 4
	NOTE C#, 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	REST 1
	OCTAVE 3
	NOTE G_, 2
	NOTE A#, 1
	NOTE G#, 4
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A#, 4
	NOTE G_, 4
	NOTE G#, 6
	OCTAVE 4
	NOTE F_, 2
	OCTAVE 3
	NOTE A#, 0
	OCTAVE 4
	NOTE C_, 4
	REST 1
	NOTE E_, 2
	NOTE F_, 1
	NOTE G_, 6
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 4
	OCTAVE 5
	NOTE C#, 4
	SND_LOOP

Snd58_Ch3:
	SND_SEGNO
	VOICE $07, 4, 4, 3, 3
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE D_, 1
	REST 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 1
	REST 1
	OCTAVE 1
	NOTE F_, 2
	NOTE D#, 1
	OCTAVE 1
	NOTE C#, 2
	NOTE G#, 1
	NOTE C#, 4
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 2
	NOTE F_, 1
	NOTE B_, 1
	REST 1
	NOTE B_, 2
	OCTAVE 1
	NOTE G#, 1
	NOTE C_, 2
	OCTAVE 1
	NOTE G#, 1
	OCTAVE 1
	NOTE C_, 1
	REST 1
	NOTE C_, 1
	NOTE G#, 2
	NOTE C_, 2
	NOTE G_, 1
	NOTE C_, 1
	REST 1
	NOTE C_, 2
	NOTE G_, 1
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE D_, 1
	REST 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE F_, 2
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE C#, 2
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 1
	REST 1
	OCTAVE 1
	NOTE F_, 2
	NOTE D#, 1
	OCTAVE 1
	NOTE C#, 2
	NOTE G#, 1
	NOTE C#, 1
	REST 1
	NOTE C_, 2
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 2
	NOTE F_, 1
	NOTE B_, 1
	REST 1
	NOTE B_, 2
	OCTAVE 1
	NOTE G#, 1
	NOTE C_, 2
	OCTAVE 1
	NOTE G#, 1
	OCTAVE 1
	NOTE C_, 1
	REST 1
	NOTE C_, 1
	NOTE G_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE F_, 1
	REST 1
	NOTE F_, 2
	NOTE C_, 1
	NOTE C#, 2
	NOTE G#, 1
	NOTE C_, 1
	REST 1
	NOTE C#, 1
	NOTE A#, 2
	NOTE C_, 2
	NOTE A#, 1
	NOTE C_, 1
	REST 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE C#, 2
	NOTE G#, 1
	NOTE C#, 1
	REST 1
	NOTE C#, 1
	NOTE A#, 2
	NOTE C_, 2
	NOTE A#, 1
	NOTE C_, 1
	REST 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE C_, 1
	NOTE C#, 2
	NOTE G#, 1
	NOTE C#, 1
	REST 1
	NOTE C#, 1
	NOTE A#, 2
	NOTE C_, 2
	NOTE G_, 1
	NOTE C_, 1
	REST 1
	NOTE C_, 1
	NOTE G_, 2
	NOTE C#, 2
	NOTE G#, 1
	NOTE C_, 1
	REST 1
	NOTE C#, 1
	NOTE G#, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE C_, 1
	REST 1
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE C_, 1
	OCTAVE 1
	REST 1
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE C_, 1
	REST 1
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE C_, 1
	REST 1
	OCTAVE 1
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE C_, 1
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE C_, 1
	REST 1
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE C_, 1
	REST 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A#, 1
	SND_LOOP

Snd58_Drm:
	SND_SEGNO
	LEN_UNIT $07
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 4, 1
	DRUM 9, 2
	DRUM 4, 1
	DRUM $0C, 2
	DRUM 4, 1
	DRUM 9, 2
	DRUM 4, 1
	DRUM 9, 2
	SND_LOOP

Snd59_Ch2:
	SND_SEGNO
	VOICE $05, 4, 9, 0, 6
	RELEASE_VOL 2
	OCTAVE 3
	NOTE E_, 4
	REST 4
	REST 4
	REST 2
	NOTE B_, 2
	REST 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 4
	NOTE F#, 2
	NOTE D_, 2
	NOTE E_, 0
	NOTE B_, 2
	REST 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 4
	NOTE F#, 2
	NOTE D_, 2
	NOTE E_, 12
	NOTE F#, 2
	NOTE G_, 2
	OCTAVE 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A_, 2
	NOTE B_, 2
	NOTE B_, 0
	NOTE B_, 12
	REST 2
	NOTE E_, 8
	REST 4
	REST 4
	NOTE B_, 2
	REST 2
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 2
	NOTE E_, 0
	NOTE B_, 2
	REST 2
	NOTE A_, 4
	NOTE G_, 4
	NOTE F#, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE E_, 1
	REST 1
	NOTE E_, 1
	REST 1
	NOTE E_, 1
	REST 1
	NOTE E_, 1
	REST 1
	REST 2
	NOTE E_, 1
	REST 1
	NOTE E_, 1
	REST 1
	NOTE F#, 4
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	REST 1
	NOTE F#, 1
	REST 1
	NOTE G_, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE D_, 4
	NOTE E_, 2
	NOTE E_, 12
	NOTE E_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	OCTAVE 4
	NOTE D_, 2
	NOTE C_, 12
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 6
	REST 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	REST 2
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 12
	NOTE B_, 8
	REST 2
	NOTE E_, 2
	OCTAVE 4
	NOTE D_, 1
	REST 1
	NOTE D_, 12
	NOTE C_, 2
	REST 2
	NOTE D_, 6
	NOTE E_, 2
	OCTAVE 3
	NOTE G_, 4
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 0
	REST 4
	REST 4
	REST 4
	REST 4
	SND_LOOP

Snd59_Ch1:
	SND_SEGNO
	VOICE $05, 4, 8, 0, 6
	RELEASE_VOL 8
	OCTAVE 3
	REST 2
	NOTE F#, 2
	NOTE G_, 2
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE G_, 1
	NOTE B_, 2
	OCTAVE 4
	NOTE G_, 3
	NOTE F#, 2
	NOTE F#, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 3
	OCTAVE 3
	NOTE A#, 1
	REST 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE G_, 3
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 4
	NOTE C_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 3
	NOTE G_, 4
	REST 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 4
	OCTAVE 4
	NOTE E_, 8
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE D#, 4
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE B_, 2
	NOTE A_, 2
	NOTE F#, 2
	NOTE D#, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE G_, 10
	REST 6
	OCTAVE 4
	NOTE D_, 10
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 4
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE G_, 1
	NOTE F#, 3
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE B_, 4
	OCTAVE 3
	NOTE E_, 2
	NOTE G_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 1
	NOTE D_, 2
	NOTE E_, 11
	NOTE C_, 4
	NOTE D_, 12
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 12
	NOTE E_, 2
	NOTE D_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 3
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE E_, 12
	NOTE F#, 2
	NOTE E_, 2
	NOTE E_, 6
	REST 6
	NOTE A_, 2
	NOTE A#, 2
	NOTE B_, 2
	REST 2
	OCTAVE 3
	NOTE B_, 1
	REST 1
	OCTAVE 4
	NOTE D_, 1
	REST 1
	OCTAVE 3
	NOTE B_, 1
	REST 1
	OCTAVE 4
	NOTE D_, 2
	REST 2
	OCTAVE 3
	NOTE B_, 1
	REST 1
	OCTAVE 4
	NOTE D_, 1
	REST 1
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE B_, 7
	REST 7
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 8
	NOTE D_, 10
	NOTE G_, 4
	NOTE F#, 2
	NOTE D#, 2
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 2
	NOTE F#, 2
	SND_LOOP

Snd59_Ch3:
	SND_SEGNO
	VOICE $05, 5, 4, 6, 2
	OCTAVE 1
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE E_, 2
	REST 2
	OCTAVE 1
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 4
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE D_, 2
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE C_, 1
	REST 2
	OCTAVE 1
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE A_, 4
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 4
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 4
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 4
	NOTE A_, 2
	NOTE A#, 2
	NOTE B_, 4
	NOTE B_, 4
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 1
	NOTE C_, 2
	NOTE C#, 2
	NOTE D#, 4
	NOTE D#, 2
	NOTE E_, 2
	NOTE F#, 4
	NOTE B_, 2
	NOTE B_, 2
	NOTE E_, 2
	REST 2
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 3
	OCTAVE 1
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 4
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE D_, 1
	NOTE E_, 3
	OCTAVE 1
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	REST 2
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 3
	NOTE C_, 1
	REST 2
	OCTAVE 1
	NOTE G_, 4
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE B_, 4
	NOTE B_, 2
	NOTE B_, 2
	NOTE A_, 4
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	REST 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE B_, 4
	NOTE B_, 2
	NOTE B_, 2
	NOTE D_, 4
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE D_, 2
	NOTE E_, 4
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 2
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
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE E_, 3
	NOTE D_, 1
	NOTE D_, 2
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE C_, 2
	NOTE C_, 4
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE C_, 2
	NOTE C_, 4
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE D_, 2
	NOTE E_, 4
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE E_, 2
	REST 2
	OCTAVE 1
	NOTE E_, 4
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 4
	OCTAVE 1
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE D_, 2
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 4
	NOTE C_, 4
	OCTAVE 1
	NOTE B_, 2
	NOTE C_, 4
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE C_, 2
	NOTE D_, 4
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE D_, 4
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE D#, 4
	NOTE D#, 2
	NOTE F#, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE D#, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE F#, 2
	NOTE D#, 2

Snd59_Drm:
	SND_LOOP ; loop byte read both as a start and as an end (see doc)
	LEN_UNIT $05
	DRUM $0C, 4
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 4, 2
	DRUM $0C, 2
	DRUM $0C, 4
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 4, 2
	DRUM $0C, 2
	DRUM $0C, 4
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 4, 2
	DRUM $0C, 2
	DRUM $0C, 4
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 4, 2
	DRUM $0C, 2
	DRUM $0C, 4
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 4, 2
	DRUM $0C, 2
	DRUM $0C, 4
	DRUM 4, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 4, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 4, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 4, 2
	DRUM $0C, 2
	DRUM 4, 2
	SND_LOOP

Snd5B_Ch2:
	SND_SEGNO
	VOICE $05, 4, 6, 8, 6
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE F#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE G#, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE B_, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE B_, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE D#, 1
	NOTE A_, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE C#, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE G#, 1
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE C#, 1
	NOTE B_, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE B_, 1
	NOTE C#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE B_, 1
	NOTE F#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 4
	NOTE G#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 4
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE C#, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE C#, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 4
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE B_, 1
	NOTE C#, 1
	NOTE A#, 1
	NOTE C#, 1
	NOTE A_, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE B_, 1
	NOTE C#, 1
	NOTE A#, 1
	NOTE C#, 1
	NOTE A_, 1
	NOTE C#, 1
	SND_LOOP

Snd5B_Ch1:
	SND_SEGNO
	VOICE $05, 4, 7, 8, 5
	OCTAVE 5
	NOTE C#, 2
	OCTAVE 4
	NOTE B_, 2
	NOTE G#, 2
	NOTE F#, 6
	NOTE G#, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE G#, 6
	REST 2
	OCTAVE 2
	NOTE G#, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C#, 2
	REST 2
	NOTE C#, 2
	NOTE E_, 2
	NOTE C#, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE F#, 4
	NOTE E_, 2
	NOTE G#, 4
	NOTE F#, 2
	NOTE E_, 2
	NOTE C#, 2
	REST 2
	NOTE C#, 2
	NOTE E_, 2
	NOTE C#, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE C#, 4
	NOTE B_, 4
	NOTE A_, 2
	NOTE G#, 2
	NOTE C#, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE G#, 2
	NOTE C#, 2
	NOTE A#, 2
	NOTE C#, 2
	NOTE B_, 2
	NOTE C#, 2
	NOTE A#, 2
	NOTE G#, 2
	REST 2
	NOTE G#, 2
	NOTE A#, 2
	NOTE C#, 2
	NOTE B_, 2
	NOTE C#, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE A_, 4
	NOTE G#, 2
	NOTE F#, 2
	NOTE G#, 4
	NOTE F#, 2
	NOTE E_, 2
	NOTE F#, 6
	OCTAVE 2
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE A_, 4
	NOTE G#, 2
	NOTE F#, 2
	NOTE F#, 4
	NOTE E_, 2
	NOTE D#, 2
	NOTE E_, 4
	NOTE E_, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE C#, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE D#, 4
	NOTE E_, 2
	NOTE F#, 2
	NOTE E_, 4
	NOTE F#, 2
	NOTE G#, 2
	NOTE F#, 4
	NOTE B_, 2
	NOTE A_, 2
	NOTE G#, 4
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE A_, 2
	OCTAVE 3
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 2
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 4
	NOTE F#, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE G#, 4
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE G#, 6
	REST 4
	OCTAVE 3
	NOTE C#, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE F#, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE G#, 4
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE E_, 2
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 3
	NOTE G#, 6
	REST 4
	REST 2
	OCTAVE 4
	NOTE C#, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE G#, 6
	NOTE G#, 0
	REST $0C
	SND_LOOP

Snd5B_Ch3:
	SND_SEGNO
	VOICE $05, 5, 4, 8, 4
	OCTAVE 1
	NOTE A_, 2
	NOTE B_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE G#, 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE B_, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE B_, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE G#, 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE G#, 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE D#, 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE G#, 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE B_, 1
	NOTE C#, 1
	REST 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE B_, 1
	NOTE C_, 1
	REST 1
	NOTE C#, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE E_, 1
	SND_LOOP

Snd5B_Drm:
	SND_SEGNO
	LEN_UNIT $05
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 9, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM 4, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	LOOP_START
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	LOOP_END $07
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	LOOP_START
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	LOOP_END $03
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	LOOP_START
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	LOOP_END $07
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	SND_LOOP

Snd5C_Ch2:
	TEMPO $58
	VOICE $02, 8, 7, 7, 8
	ATTEN 3
	OCTAVE 2
	NOTE D#, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE G#, 4
	NOTE G_, 4
	NOTE F_, 4
	ATTEN 2
	LEN_UNIT $06
	NOTE G_, 2
	OCTAVE 3
	NOTE C_, 2
	LEN_UNIT $02
	NOTE D#, 4
	NOTE G_, 4
	OCTAVE 4
	NOTE C_, 4
	ATTEN 1
	LEN_UNIT $06
	OCTAVE 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE C_, 4
	LEN_UNIT $03
	ATTEN 0
	OCTAVE 3
	NOTE F_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE F_, 1
	LEN_UNIT $06
	NOTE G_, 8
	NOTE F_, 4
	NOTE C_, 4
	ATTEN 3
	NOTE G_, 2
	ATTEN 4
	NOTE G_, 2
	ATTEN 5
	NOTE G_, 2
	ATTEN 6
	NOTE G_, 2
	SND_END

Snd5C_Ch1:
	VOICE $02, 8, 5, 8, 8
	OCTAVE 2
	NOTE C_, 4
	NOTE D_, 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE D#, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE D#, 4
	NOTE G_, 4
	OCTAVE 3
	NOTE C_, 4
	NOTE D#, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE D#, 4
	LEN_UNIT $03
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	LEN_UNIT $06
	DETUNE $01
	NOTE F_, 8
	OCTAVE 5
	ATTEN 2
	LEN_UNIT $02
	NOTE C_, 4
	OCTAVE 4
	NOTE A#, 4
	NOTE F_, 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE C_, 4
	ATTEN 3
	OCTAVE 5
	NOTE C_, 4
	OCTAVE 4
	NOTE A#, 4
	NOTE F_, 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE C_, 4
	ATTEN 4
	OCTAVE 5
	NOTE C_, 4
	OCTAVE 4
	NOTE A#, 4
	NOTE F_, 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE C_, 4
	SND_END

Snd5C_Ch3:
	VOICE $06, 3, 2, 4, 15
	OCTAVE 2
	NOTE C_, 8
	OCTAVE 1
	NOTE A#, 8
	OCTAVE 1
	NOTE A_, 8
	NOTE G#, 8
	NOTE C#, 8
	ATTEN 1
	NOTE C#, 8
	ATTEN 2
	NOTE C#, 8
	ATTEN 3
	NOTE C#, 8
	SND_END

Snd5C_Drm:
	LEN_UNIT $02
	REST 4
	REST 4
	REST 4
	DRUM 2, 4
	DRUM 2, 4
	DRUM 2, 4
	DRUM 2, 4
	DRUM 2, 4
	DRUM 2, 4
	DRUM 2, 4
	DRUM 2, 4
	DRUM 2, 4
	REST 4
	REST 4
	REST 4
	DRUM 2, 4
	DRUM 2, 4
	DRUM 2, 4
	DRUM 2, 4
	DRUM 2, 4
	DRUM 2, 4
	DRUM 2, 4
	DRUM 2, 4
	DRUM 2, 4
	DRUM 9, 0
	SND_END

Snd5D_Ch2:
	VOICE $0F, 4, 7, 2, 2
	OCTAVE 3
	NOTE A_, 6
	OCTAVE 4
	NOTE E_, 4
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 3
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 4
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 4
	NOTE F_, 2
	NOTE E_, 2
	NOTE A_, 10
	OCTAVE 4
	NOTE A_, 4
	NOTE G_, 2
	NOTE E_, 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 4
	NOTE C_, 2
	NOTE D_, 6
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 6
	NOTE A_, 8
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE D#, 6
	REST 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE G_, 4
	NOTE A#, 2
	VOICE $0F, 6, 3, 3, 2
	OCTAVE 5
	REST 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE C#, 1
	SND_END

Snd5D_Ch1:
	VOICE $0F, 4, 3, 3, 6
	DETUNE $01
	REST 1
	OCTAVE 3
	NOTE A_, 6
	OCTAVE 4
	NOTE E_, 4
	OCTAVE 3
	NOTE B_, 2
	OCTAVE 4
	NOTE D_, 3
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 2
	NOTE A_, 4
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 4
	NOTE F_, 2
	NOTE E_, 2
	NOTE A_, 10
	OCTAVE 4
	NOTE A_, 4
	NOTE G_, 2
	NOTE E_, 4
	NOTE C_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 4
	NOTE C_, 2
	NOTE D_, 6
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 5
	NOTE C#, 6
	VOICE $0F, 6, 5, 3, 2
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 5
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE C#, 1
	LEN_UNIT $08
	NOTE A_, 2
	ATTEN 3
	NOTE A_, 2
	ATTEN 4
	NOTE A_, 2
	ATTEN 5
	NOTE A_, 2
	SND_END

Snd5D_Ch3:
	SND_SEGNO
	VOICE $0F, 4, 4, 3, 4
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F#, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 1
	NOTE C_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 1
	NOTE E_, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE D#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 1
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
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE D_, 10
	NOTE A_, 1
	NOTE A_, 1
	NOTE D_, 15
	SND_END

Snd5D_Drm:
	SND_END

Snd5E_Ch2:
	TEMPO $08
	VOICE $06, 4, 8, 6, 6
	RELEASE_VOL 2
	SND_SEGNO
	OCTAVE 4
	NOTE D_, 8
	NOTE C_, 4
	OCTAVE 3
	NOTE A#, 4
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE D_, 8
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D#, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE A#, 8
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 8
	NOTE E_, 1
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 8
	NOTE C_, 4
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 3
	NOTE D_, 1
	NOTE D_, 8
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D#, 3
	NOTE A#, 1
	NOTE A#, 8
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE A#, 1
	NOTE A_, 3
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 8
	NOTE D_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 8
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 8
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE D#, 2
	NOTE F_, 1
	NOTE D_, 3
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 8
	NOTE G_, 1
	NOTE A_, 2
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 3
	OCTAVE 3
	NOTE G_, 1
	NOTE G_, 8
	REST 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 6
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE G_, 2
	NOTE D_, 8
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 3
	NOTE G_, 1
	NOTE G_, 7
	NOTE F_, 1
	NOTE F_, 1
	NOTE A#, 2
	NOTE G#, 1
	NOTE G_, 12
	OCTAVE 3
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	SND_LOOP

Snd5E_Ch1:
	SND_SEGNO
	VOICE $06, 4, 4, 6, 3
	OCTAVE 3
	NOTE F_, 6
	NOTE D_, 2
	NOTE D#, 3
	NOTE G_, 3
	NOTE D#, 2
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	REST 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE F_, 8
	LEN_UNIT $02
	NOTE D#, 8
	NOTE F_, 8
	NOTE D#, 8
	LEN_UNIT $06
	OCTAVE 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 4
	NOTE D_, 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE D_, 3
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE A#, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE D_, 3
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE D_, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE A#, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 1
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE A#, 1
	NOTE G_, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE G#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE G#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D#, 1
	NOTE G_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G_, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE G_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE F_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	SND_LOOP

Snd5E_Ch3:
	SND_SEGNO
	VOICE $06, 14, 4, 10, 4
	OCTAVE 1
	NOTE D_, 4
	LEN_UNIT $02
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN_UNIT $06
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 4
	LEN_UNIT $02
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN_UNIT $06
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE C_, 4
	LEN_UNIT $02
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	LEN_UNIT $06
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE D_, 4
	LEN_UNIT $02
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN_UNIT $06
	NOTE A#, 2
	NOTE A#, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE D_, 4
	LEN_UNIT $02
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN_UNIT $06
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 4
	LEN_UNIT $02
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN_UNIT $06
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE C_, 4
	LEN_UNIT $02
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	LEN_UNIT $06
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE G_, 4
	LEN_UNIT $02
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN_UNIT $06
	NOTE F_, 4
	LEN_UNIT $02
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	LEN_UNIT $06
	NOTE D#, 4
	LEN_UNIT $02
	NOTE D#, 4
	NOTE D#, 4
	NOTE D#, 4
	LEN_UNIT $06
	NOTE D_, 4
	LEN_UNIT $02
	NOTE D_, 4
	NOTE D#, 4
	NOTE D_, 4
	LEN_UNIT $06
	NOTE C_, 4
	LEN_UNIT $02
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	LEN_UNIT $06
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE G#, 4
	LEN_UNIT $02
	NOTE G#, 4
	NOTE G#, 4
	NOTE G#, 4
	LEN_UNIT $06
	NOTE G#, 2
	NOTE D#, 2
	NOTE G#, 2
	NOTE D#, 2
	NOTE G_, 4
	REST 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	LEN_UNIT $02
	NOTE C_, 4
	NOTE D#, 4
	NOTE G#, 4
	LEN_UNIT $06
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN_UNIT $02
	NOTE G_, 4
	NOTE F_, 4
	NOTE D#, 4
	SND_LOOP

Snd5E_Drm:
	SND_SEGNO
	LEN_UNIT $06
	DRUM $0C, 4
	LEN_UNIT $02
	DRUM 9, 4
	DRUM 9, 4
	DRUM 9, 4
	LEN_UNIT $06
	DRUM 3, 2
	DRUM 3, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0C, 4
	LEN_UNIT $02
	DRUM 9, 4
	DRUM 9, 4
	DRUM 9, 4
	LEN_UNIT $06
	DRUM 3, 2
	DRUM 3, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	LEN_UNIT $06
	DRUM $0C, 4
	LEN_UNIT $02
	DRUM 9, 4
	DRUM 9, 4
	DRUM 9, 4
	LEN_UNIT $06
	DRUM 3, 2
	DRUM 3, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0C, 4
	LEN_UNIT $02
	DRUM 9, 4
	DRUM 9, 4
	DRUM 9, 4
	LEN_UNIT $06
	DRUM 3, 2
	DRUM 3, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0C, 4
	LEN_UNIT $02
	DRUM 9, 4
	DRUM 9, 4
	DRUM 9, 4
	LEN_UNIT $06
	DRUM 3, 2
	DRUM 3, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0C, 4
	LEN_UNIT $02
	DRUM 9, 4
	DRUM 9, 4
	DRUM 9, 4
	LEN_UNIT $06
	DRUM 3, 2
	DRUM 3, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	LEN_UNIT $06
	DRUM $0C, 4
	LEN_UNIT $02
	DRUM 9, 4
	DRUM 9, 4
	DRUM 9, 4
	LEN_UNIT $06
	DRUM 3, 2
	DRUM 3, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM $0C, 4
	LEN_UNIT $02
	DRUM 9, 4
	DRUM 9, 4
	DRUM 9, 4
	LEN_UNIT $06
	DRUM 3, 2
	DRUM 3, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 3, 2
	DRUM 3, 2
	DRUM $0C, 2
	DRUM 2, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 3, 2
	DRUM 3, 2
	DRUM $0C, 2
	DRUM 2, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 3, 2
	DRUM 3, 2
	DRUM $0C, 2
	DRUM 2, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 3, 2
	DRUM 3, 2
	DRUM $0C, 2
	DRUM 2, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 3, 2
	DRUM 3, 2
	DRUM $0C, 2
	DRUM 2, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 4, 2
	DRUM 4, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 2, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0C, 4
	LEN_UNIT $02
	DRUM 9, 4
	DRUM 9, 4
	DRUM 9, 4
	LEN_UNIT $06
	DRUM 3, 2
	DRUM 3, 2
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	DRUM 4, 1
	AUTOPAN 0
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	PAN_BOTH 0
	SND_LOOP

Snd5F_Ch2:
	SND_SEGNO
	VOICE $06, 8, 8, 12, 5
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D_, 2
	NOTE D_, 6
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE D_, 4
	LEN_UNIT $02
	NOTE C#, 8
	NOTE D_, 8
	NOTE E_, 8
	LEN_UNIT $06
	NOTE F_, 2
	NOTE A#, 2
	NOTE A#, 6
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 2
	NOTE F#, 2
	NOTE F_, 2
	OCTAVE 3
	NOTE A#, 2
	NOTE A#, 4
	LEN_UNIT $02
	NOTE A_, 8
	NOTE A#, 8
	OCTAVE 4
	NOTE C_, 8
	LEN_UNIT $06
	NOTE G#, 2
	NOTE C#, 2
	NOTE G#, 6
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	OCTAVE 4
	NOTE B_, 2
	NOTE A#, 1
	NOTE G#, 1
	NOTE G_, 2
	NOTE D#, 2
	NOTE D#, 8
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 2
	NOTE D#, 2
	OCTAVE 5
	NOTE D#, 2
	NOTE C#, 2
	LEN_UNIT $02
	NOTE C_, 8
	NOTE C#, 8
	NOTE D#, 8
	LEN_UNIT $06
	OCTAVE 4
	NOTE F_, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE F_, 6
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 2
	NOTE G#, 1
	NOTE F#, 1
	OCTAVE 4
	NOTE F_, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE F_, 6
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 2
	NOTE G#, 1
	NOTE F#, 1
	NOTE A_, 2
	NOTE D_, 2
	NOTE A_, 6
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 2
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE A#, 1
	NOTE A_, 2
	NOTE D_, 2
	NOTE A_, 6
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 2
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE A#, 1
	LEN_UNIT $02
	OCTAVE 5
	NOTE D_, 8
	NOTE C#, 8
	OCTAVE 4
	NOTE A_, 8
	OCTAVE 5
	NOTE C_, 8
	OCTAVE 4
	NOTE A#, 8
	NOTE G_, 8
	LEN_UNIT $06
	NOTE A_, 2
	NOTE A_, 2
	LEN_UNIT $02
	OCTAVE 5
	NOTE D_, 8
	NOTE C#, 8
	OCTAVE 4
	NOTE A_, 8
	OCTAVE 5
	NOTE C_, 8
	OCTAVE 4
	NOTE A#, 8
	NOTE G_, 8
	OCTAVE 3
	NOTE F#, 8
	NOTE F_, 8
	NOTE D#, 8
	NOTE A#, 8
	NOTE A_, 8
	NOTE G_, 8
	LEN_UNIT $06
	OCTAVE 3
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C#, 2
	NOTE F_, 2
	NOTE A#, 2
	NOTE G#, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE G#, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 2
	NOTE G#, 2
	NOTE F#, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE F#, 2
	NOTE G#, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE F#, 2
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE C#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C#, 2
	NOTE F_, 2
	NOTE A#, 2
	NOTE G#, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE G#, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE D#, 2
	NOTE G#, 2
	NOTE F#, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE F#, 2
	NOTE G#, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE C#, 2
	NOTE F#, 2
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	NOTE F#, 2
	NOTE C#, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	NOTE F#, 2
	NOTE C#, 2
	NOTE F#, 2
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	SND_LOOP

Snd5F_Ch1:
	SND_SEGNO
	VOICE $06, 8, 7, 9, 5
	OCTAVE 2
	NOTE F_, 2
	NOTE A_, 2
	NOTE A_, 4
	NOTE G_, 2
	NOTE A_, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 4
	NOTE G_, 2
	NOTE A_, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE F_, 2
	NOTE C#, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE C#, 1
	NOTE D#, 1
	NOTE C#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE F#, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE G#, 2
	OCTAVE 3
	NOTE C#, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE E_, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE G_, 2
	NOTE A#, 2
	OCTAVE 4
	NOTE D#, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE F#, 2
	OCTAVE 2
	NOTE F#, 2
	NOTE A_, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE D#, 2
	NOTE F#, 2
	NOTE C#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	LEN_UNIT $02
	NOTE D_, 8
	NOTE C#, 8
	OCTAVE 1
	NOTE A_, 8
	OCTAVE 2
	NOTE C_, 8
	OCTAVE 1
	NOTE A#, 8
	NOTE G_, 8
	LEN_UNIT $06
	NOTE A_, 2
	NOTE A_, 2
	LEN_UNIT $02
	OCTAVE 2
	NOTE D_, 8
	NOTE C#, 8
	OCTAVE 1
	NOTE A_, 8
	OCTAVE 2
	NOTE C_, 8
	OCTAVE 1
	NOTE A#, 8
	NOTE G_, 8
	LEN_UNIT $06
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE F#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE F#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE C#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 1
	NOTE C#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 1
	NOTE C#, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE D#, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE F#, 1
	OCTAVE 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE C_, 1
	NOTE C#, 1
	SND_LOOP

Snd5F_Ch3:
	SND_SEGNO
	VOICE $06, 6, 2, 10, 3
	OCTAVE 1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 1
	NOTE A#, 1
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 1
	NOTE C#, 1
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE C#, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE C#, 6
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 2
	NOTE F_, 1
	NOTE D#, 1
	NOTE C#, 2
	OCTAVE 3
	NOTE F_, 2
	OCTAVE 4
	NOTE C#, 6
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 2
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE F_, 6
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 2
	NOTE A_, 1
	NOTE G_, 1
	NOTE F_, 2
	OCTAVE 3
	NOTE A_, 2
	OCTAVE 4
	NOTE F_, 6
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 2
	NOTE A_, 1
	NOTE G_, 1
	LEN_UNIT $02
	OCTAVE 2
	NOTE A_, 8
	NOTE G#, 8
	NOTE E_, 8
	NOTE G_, 8
	NOTE F_, 8
	NOTE C#, 8
	LEN_UNIT $06
	OCTAVE 3
	NOTE C_, 2
	NOTE C_, 2
	LEN_UNIT $02
	OCTAVE 2
	NOTE A_, 8
	NOTE G#, 8
	NOTE E_, 8
	NOTE G_, 8
	NOTE F#, 8
	NOTE C#, 8
	LEN_UNIT $06
	NOTE F#, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE F_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE F#, 1
	NOTE A#, 1
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A#, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE F_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE F_, 4
	REST 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE F#, 1
	OCTAVE 1
	NOTE F_, 4
	REST 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE F#, 1
	OCTAVE 1
	NOTE F_, 4
	REST 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE F#, 1
	OCTAVE 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE C#, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F_, 1
	SND_LOOP

Snd5F_Drm:
	SND_SEGNO
	LEN_UNIT $06
	LOOP_START
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM 3, 1
	LOOP_END $07
	LOOP_START
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 3, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 3, 2
	DRUM $0C, 1
	DRUM $0C, 1
	LOOP_END $04
	LEN_UNIT $02
	DRUM 3, 8
	DRUM 2, 8
	DRUM $0C, 8
	DRUM 3, 8
	DRUM 2, 8
	DRUM $0C, 8
	LEN_UNIT $06
	DRUM $0C, 2
	DRUM $0C, 2
	LEN_UNIT $02
	DRUM 3, 8
	DRUM 2, 8
	DRUM $0C, 8
	DRUM 3, 8
	DRUM 2, 8
	DRUM $0C, 8
	LEN_UNIT $06
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 3, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0C, 4
	DRUM $0C, 4
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	LOOP_START
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	LOOP_END $07
	LOOP_START
	DRUM $0C, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 2
	DRUM $0C, 2
	DRUM 2, 2
	DRUM $0C, 2
	LOOP_END $03
	DRUM $0C, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 2
	DRUM 3, 1
	DRUM 3, 1
	SND_LOOP

Snd60_Ch2:
	SND_SEGNO
	VOICE $06, 4, 10, 6, 6
	TEMPO $10
	RELEASE_VOL 5
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 2
	NOTE C_, 1
	REST 1
	OCTAVE 3
	NOTE B_, 7
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	LEN_UNIT $02
	NOTE A_, 8
	NOTE D_, 8
	NOTE A_, 8
	NOTE G_, 8
	OCTAVE 4
	NOTE C_, 8
	OCTAVE 3
	NOTE G_, 8
	LEN_UNIT $06
	OCTAVE 4
	NOTE D_, 1
	NOTE D_, 2
	NOTE C_, 1
	REST 1
	OCTAVE 3
	NOTE B_, 7
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	LEN_UNIT $02
	NOTE A_, 8
	NOTE D_, 8
	NOTE A_, 8
	NOTE G_, 8
	OCTAVE 4
	NOTE C_, 8
	OCTAVE 3
	NOTE G_, 8
	NOTE A#, 8
	NOTE D#, 8
	NOTE A#, 8
	NOTE G#, 8
	OCTAVE 4
	NOTE C#, 8
	NOTE C#, 8
	LEN_UNIT $06
	NOTE D#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE D#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	REST 2
	OCTAVE 4
	NOTE D#, 2
	REST 1
	NOTE F#, 1
	REST 2
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	REST 2
	NOTE D#, 2
	REST 2
	OCTAVE 5
	NOTE C#, 2
	REST 1
	OCTAVE 4
	NOTE A_, 1
	REST 2
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	REST 1
	NOTE C#, 1
	REST 2
	LEN_UNIT $02
	NOTE G#, 8
	NOTE F#, 8
	NOTE F_, 8
	LEN_UNIT $06
	NOTE F#, 4
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 4
	NOTE D#, 4
	REST 4
	LEN_UNIT $02
	NOTE D_, 8
	NOTE D#, 8
	NOTE F_, 8
	LEN_UNIT $06
	NOTE F_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE A#, 6
	LEN_UNIT $02
	NOTE F#, 8
	NOTE G#, 8
	NOTE A#, 8
	NOTE B_, 8
	OCTAVE 4
	NOTE C#, 8
	NOTE D_, 8
	LEN_UNIT $06
	NOTE E_, 4
	NOTE B_, 4
	NOTE A_, 4
	OCTAVE 5
	NOTE D_, 4
	OCTAVE 4
	NOTE E_, 4
	REST 4
	REST 2
	NOTE B_, 2
	NOTE A_, 2
	OCTAVE 5
	NOTE D_, 2
	OCTAVE 4
	NOTE E_, 4
	NOTE B_, 4
	NOTE A_, 4
	OCTAVE 5
	NOTE D_, 4
	OCTAVE 4
	NOTE E_, 4
	REST 4
	REST 2
	NOTE G_, 2
	NOTE F#, 2
	NOTE D_, 2
	LEN_UNIT $02
	NOTE C_, 8
	NOTE D_, 8
	NOTE E_, 8
	LEN_UNIT $06
	NOTE E_, 4
	REST 4
	LEN_UNIT $02
	NOTE D#, 8
	NOTE E_, 8
	NOTE F#, 8
	NOTE A_, 8
	NOTE G_, 8
	NOTE F#, 8
	NOTE F#, 8
	NOTE G_, 8
	NOTE A_, 8
	NOTE B_, 8
	OCTAVE 5
	NOTE C#, 8
	NOTE D#, 8
	OCTAVE 4
	NOTE A_, 8
	NOTE G_, 8
	NOTE F#, 8
	LEN_UNIT $06
	NOTE G_, 4
	OCTAVE 3
	NOTE B_, 4
	LEN_UNIT $02
	OCTAVE 4
	NOTE A_, 8
	NOTE G_, 8
	NOTE F#, 8
	LEN_UNIT $06
	NOTE G_, 4
	NOTE B_, 4
	LEN_UNIT $02
	NOTE F_, 8
	NOTE D#, 8
	NOTE D_, 8
	LEN_UNIT $06
	NOTE D#, 4
	OCTAVE 3
	NOTE G_, 4
	LEN_UNIT $02
	OCTAVE 4
	NOTE F_, 8
	NOTE D#, 8
	NOTE D_, 8
	LEN_UNIT $06
	NOTE D#, 4
	NOTE G_, 4
	LEN_UNIT $02
	OCTAVE 5
	NOTE C#, 8
	NOTE C_, 8
	OCTAVE 4
	NOTE A#, 8
	NOTE F#, 8
	NOTE G_, 8
	NOTE C_, 8
	NOTE A#, 8
	NOTE G#, 8
	NOTE G_, 8
	NOTE G#, 8
	NOTE A#, 8
	OCTAVE 5
	NOTE C_, 8
	OCTAVE 3
	NOTE A_, 8
	NOTE D_, 8
	NOTE A_, 8
	NOTE A#, 8
	NOTE E_, 8
	NOTE A#, 8
	NOTE B_, 8
	NOTE E_, 8
	NOTE B_, 8
	OCTAVE 4
	NOTE C#, 8
	OCTAVE 3
	NOTE E_, 8
	OCTAVE 4
	NOTE C#, 8
	LEN_UNIT $06
	SND_LOOP

Snd60_Ch1:
	SND_SEGNO
	VOICE $06, 8, 9, 4, 8
	OCTAVE 3
	NOTE F_, 1
	NOTE F_, 2
	NOTE A_, 1
	REST 1
	NOTE G_, 3
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	LEN_UNIT $02
	OCTAVE 3
	NOTE F_, 8
	OCTAVE 2
	NOTE A_, 8
	OCTAVE 3
	NOTE D_, 8
	NOTE C_, 8
	NOTE E_, 8
	NOTE C_, 8
	LEN_UNIT $06
	OCTAVE 3
	NOTE F_, 1
	NOTE F_, 2
	NOTE A_, 1
	REST 1
	NOTE G_, 3
	OCTAVE 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	LEN_UNIT $02
	OCTAVE 3
	NOTE F_, 8
	OCTAVE 2
	NOTE A_, 8
	OCTAVE 3
	NOTE D_, 8
	NOTE C_, 8
	NOTE E_, 8
	NOTE C_, 8
	NOTE D#, 8
	OCTAVE 2
	NOTE A#, 8
	NOTE F#, 8
	NOTE G#, 8
	NOTE F_, 8
	NOTE G#, 8
	LEN_UNIT $06
	OCTAVE 3
	NOTE D#, 2
	NOTE F#, 1
	NOTE D#, 1
	REST 1
	NOTE F#, 1
	NOTE D#, 2
	NOTE F#, 1
	NOTE D#, 2
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE D#, 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 1
	REST 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 2
	NOTE B_, 4
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE D#, 2
	NOTE F#, 1
	NOTE D#, 1
	REST 1
	NOTE F#, 1
	NOTE D#, 2
	NOTE F#, 1
	NOTE D#, 2
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE D#, 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 1
	REST 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 2
	OCTAVE 2
	NOTE B_, 4
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE D#, 1
	NOTE A_, 1
	NOTE D#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	LEN_UNIT $02
	NOTE D#, 8
	NOTE F_, 8
	NOTE F#, 8
	NOTE A#, 8
	OCTAVE 3
	NOTE D#, 8
	NOTE F_, 8
	OCTAVE 2
	NOTE B_, 8
	OCTAVE 3
	NOTE D#, 8
	OCTAVE 2
	NOTE G#, 8
	NOTE B_, 8
	NOTE A#, 8
	NOTE G#, 8
	LEN_UNIT $06
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE F#, 1
	LEN_UNIT $02
	NOTE E_, 8
	NOTE F#, 8
	NOTE G_, 8
	NOTE G_, 8
	NOTE A_, 8
	NOTE B_, 8
	NOTE A_, 8
	NOTE B_, 8
	OCTAVE 4
	NOTE C_, 8
	NOTE D#, 8
	NOTE E_, 8
	NOTE F#, 8
	NOTE D#, 8
	NOTE E_, 8
	NOTE F#, 8
	NOTE G_, 8
	NOTE A_, 8
	NOTE B_, 8
	LEN_UNIT $06
	OCTAVE 3
	NOTE F#, 8
	NOTE G_, 4
	NOTE A_, 4
	NOTE F#, 8
	NOTE G_, 4
	NOTE A_, 4
	NOTE D_, 8
	NOTE D#, 4
	NOTE F_, 4
	NOTE D_, 8
	NOTE D#, 4
	OCTAVE 2
	NOTE G_, 4
	LEN_UNIT $02
	OCTAVE 3
	NOTE G_, 8
	NOTE G#, 8
	NOTE A#, 8
	NOTE E_, 8
	NOTE F_, 8
	NOTE G_, 8
	NOTE C_, 8
	NOTE D_, 8
	NOTE E_, 8
	NOTE F_, 8
	NOTE G_, 8
	NOTE G#, 8
	NOTE F_, 8
	OCTAVE 2
	NOTE F_, 8
	OCTAVE 3
	NOTE F_, 8
	NOTE E_, 8
	OCTAVE 2
	NOTE E_, 8
	OCTAVE 3
	NOTE E_, 8
	NOTE E_, 8
	OCTAVE 2
	NOTE E_, 8
	OCTAVE 3
	NOTE E_, 8
	NOTE G_, 8
	OCTAVE 2
	NOTE C#, 8
	OCTAVE 3
	NOTE G_, 8
	SND_LOOP

Snd60_Ch3:
	SND_SEGNO
	VOICE $06, 14, 2, 6, 0
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 2
	NOTE F_, 1
	REST 1
	NOTE G_, 1
	REST 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 1
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
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 2
	NOTE F_, 1
	REST 1
	NOTE G_, 1
	REST 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	OCTAVE 1
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
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE D#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	LEN_UNIT $02
	NOTE E_, 8
	NOTE D#, 8
	NOTE D_, 8
	LEN_UNIT $06
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
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
	OCTAVE 2
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
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
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
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
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
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C#, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 3
	NOTE D#, 1
	LEN_UNIT $02
	OCTAVE 2
	NOTE D#, 8
	NOTE E_, 8
	NOTE F#, 8
	NOTE G_, 8
	NOTE A_, 8
	NOTE B_, 8
	LEN_UNIT $06
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
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
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
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
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
	NOTE A#, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 1
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
	LEN_UNIT $02
	NOTE G_, 8
	NOTE G#, 8
	NOTE A#, 8
	OCTAVE 3
	NOTE C_, 8
	NOTE D_, 8
	NOTE E_, 8
	OCTAVE 2
	NOTE F_, 8
	OCTAVE 3
	NOTE F_, 8
	OCTAVE 2
	NOTE F_, 8
	NOTE D#, 8
	OCTAVE 3
	NOTE D#, 8
	OCTAVE 2
	NOTE D#, 8
	NOTE A_, 8
	OCTAVE 3
	NOTE A_, 8
	OCTAVE 2
	NOTE A_, 8
	NOTE G#, 8
	OCTAVE 3
	NOTE G#, 8
	OCTAVE 2
	NOTE G#, 8
	NOTE G_, 8
	OCTAVE 3
	NOTE G_, 8
	OCTAVE 2
	NOTE G_, 8
	NOTE E_, 8
	OCTAVE 3
	NOTE E_, 8
	OCTAVE 2
	NOTE E_, 8
	LEN_UNIT $06
	SND_LOOP

Snd60_Drm:
	SND_SEGNO
	LEN_UNIT $06
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM 3, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM 3, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM $0C, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	LOOP_START
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM 2, 1
	LOOP_END $09
	DRUM $0C, 2
	DRUM 3, 1
	DRUM 2, 1
	REST 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM $0C, 2
	DRUM 3, 1
	DRUM 2, 1
	REST 1
	DRUM 3, 1
	DRUM $0C, 2
	DRUM 2, 1
	DRUM $0C, 2
	DRUM 3, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM 2, 1
	DRUM $0C, 1
	DRUM 2, 1
	LEN_UNIT $02
	DRUM $0C, 8
	DRUM $0C, 8
	DRUM $0C, 8
	DRUM 3, 8
	DRUM $0C, 8
	DRUM 3, 8
	DRUM $0C, 8
	DRUM $0C, 8
	DRUM $0C, 8
	DRUM 3, 8
	DRUM $0C, 8
	DRUM 3, 8
	DRUM $0C, 8
	DRUM $0C, 8
	DRUM $0C, 8
	DRUM 3, 8
	DRUM $0C, 8
	DRUM 3, 8
	DRUM 3, 8
	DRUM $0C, 8
	DRUM 3, 8
	LEN_UNIT $06
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	SND_LOOP

Snd61_Ch2:
	TEMPO $10
	VOICE $09, 8, 7, 8, 4
	OCTAVE 3
	NOTE E_, 3
	NOTE B_, 3
	NOTE A_, 4
	NOTE G_, 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE G_, 3
	NOTE F#, 3
	NOTE F_, 4
	OCTAVE 4
	NOTE D_, 2
	NOTE C#, 2
	NOTE C_, 2
	OCTAVE 3
	NOTE E_, 3
	NOTE B_, 3
	NOTE A_, 4
	NOTE B_, 2
	OCTAVE 4
	NOTE C_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE G_, 8
	NOTE F#, 4
	NOTE F_, 4
	SND_SEGNO
	OCTAVE 3
	NOTE B_, 8
	LEN_UNIT $03
	REST 8
	NOTE E_, 8
	OCTAVE 4
	NOTE C_, 8
	LEN_UNIT $09
	OCTAVE 3
	NOTE B_, 8
	LEN_UNIT $03
	NOTE A_, 8
	NOTE B_, 8
	OCTAVE 4
	NOTE C_, 8
	LEN_UNIT $09
	OCTAVE 4
	NOTE E_, 4
	LEN_UNIT $03
	REST 4
	NOTE G_, 4
	NOTE F_, 4
	LEN_UNIT $09
	NOTE E_, 4
	LEN_UNIT $03
	REST 4
	NOTE G_, 4
	NOTE F_, 4
	LEN_UNIT $09
	NOTE E_, 8
	NOTE D_, 4
	NOTE C_, 4
	OCTAVE 3
	NOTE B_, 8
	LEN_UNIT $03
	REST 8
	NOTE E_, 8
	OCTAVE 4
	NOTE C_, 8
	LEN_UNIT $09
	OCTAVE 3
	NOTE B_, 8
	LEN_UNIT $03
	REST 8
	NOTE E_, 8
	NOTE G_, 8
	LEN_UNIT $09
	NOTE C_, 3
	NOTE A_, 5
	REST 1
	OCTAVE 5
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE G#, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE F_, 1
	LEN_UNIT $03
	NOTE A_, 8
	NOTE B_, 8
	OCTAVE 4
	NOTE C_, 8
	LEN_UNIT $09
	NOTE G_, 14
	NOTE F_, 2
	NOTE E_, 8
	LEN_UNIT $03
	NOTE E_, 8
	OCTAVE 3
	NOTE B_, 8
	OCTAVE 4
	NOTE F_, 8
	LEN_UNIT $09
	NOTE E_, 4
	OCTAVE 3
	NOTE A_, 4
	LEN_UNIT $03
	NOTE A_, 8
	NOTE B_, 8
	OCTAVE 4
	NOTE C_, 8
	OCTAVE 3
	NOTE G_, 8
	NOTE F_, 8
	NOTE A_, 8
	NOTE E_, 8
	NOTE D_, 8
	NOTE A_, 8
	LEN_UNIT $09
	OCTAVE 4
	NOTE E_, 4
	NOTE D_, 8
	OCTAVE 3
	NOTE F_, 4
	OCTAVE 4
	NOTE C_, 8
	NOTE D_, 8
	NOTE E_, 0
	REST 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE G#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 4
	OCTAVE 3
	NOTE D_, 8
	OCTAVE 4
	NOTE D_, 4
	NOTE C#, 8
	LEN_UNIT $03
	NOTE G_, 8
	NOTE F_, 8
	NOTE D#, 8
	LEN_UNIT $09
	NOTE E_, 2
	NOTE F_, 1
	NOTE E_, 2
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 2
	LEN_UNIT $03
	NOTE A_, 8
	NOTE E_, 8
	NOTE F_, 8
	LEN_UNIT $09
	NOTE G_, 4
	NOTE F#, 4
	NOTE G_, 4
	NOTE A_, 4
	OCTAVE 4
	NOTE D_, 4
	OCTAVE 3
	NOTE D_, 8
	OCTAVE 4
	NOTE D_, 4
	NOTE C#, 8
	NOTE G_, 4
	NOTE F_, 4
	NOTE A_, 0
	NOTE A#, 8
	NOTE A_, 8
	NOTE A_, 8
	LEN_UNIT $03
	NOTE A_, 8
	NOTE F_, 8
	NOTE D_, 8
	LEN_UNIT $09
	NOTE F_, 8
	LEN_UNIT $03
	NOTE F_, 8
	NOTE G_, 8
	NOTE F_, 8
	NOTE E_, 8
	NOTE F_, 8
	NOTE A_, 8
	OCTAVE 5
	NOTE E_, 8
	NOTE D_, 8
	NOTE E_, 8
	LEN_UNIT $09
	NOTE F_, 4
	OCTAVE 4
	NOTE F_, 4
	LEN_UNIT $03
	NOTE F_, 8
	NOTE G_, 8
	NOTE A_, 8
	OCTAVE 5
	NOTE E_, 8
	NOTE D_, 8
	NOTE E_, 8
	NOTE F_, 8
	NOTE D_, 8
	OCTAVE 4
	NOTE A_, 8
	LEN_UNIT $09
	OCTAVE 5
	NOTE C_, 4
	OCTAVE 4
	NOTE B_, 4
	OCTAVE 5
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	REST 4
	OCTAVE 4
	NOTE E_, 1
	NOTE E_, 1
	REST 2
	REST 4
	NOTE E_, 1
	NOTE E_, 1
	REST 4
	REST 2
	LEN_UNIT $03
	NOTE A_, 8
	NOTE E_, 8
	NOTE D_, 8
	LEN_UNIT $09
	NOTE E_, 8
	OCTAVE 2
	LEN_UNIT $03
	NOTE E_, 8
	NOTE F_, 8
	NOTE A_, 8
	OCTAVE 3
	NOTE E_, 8
	NOTE F_, 8
	NOTE G_, 8
	NOTE E_, 8
	NOTE D_, 8
	NOTE C_, 8
	NOTE E_, 8
	NOTE B_, 8
	NOTE A_, 8
	NOTE B_, 8
	NOTE E_, 8
	NOTE G_, 8
	NOTE A_, 8
	NOTE C_, 8
	NOTE F_, 8
	NOTE A_, 8
	NOTE B_, 8
	OCTAVE 4
	NOTE C_, 8
	LEN_UNIT $09
	NOTE D_, 3
	NOTE E_, 7
	REST 0
	REST 6
	SND_LOOP

Snd61_Ch1:
	VOICE $09, 4, 6, 8, 5
	OCTAVE 2
	NOTE E_, 4
	NOTE B_, 4
	LEN_UNIT $03
	OCTAVE 3
	NOTE C_, 8
	NOTE D_, 8
	NOTE E_, 8
	OCTAVE 2
	NOTE B_, 8
	OCTAVE 3
	NOTE C_, 8
	NOTE D_, 8
	LEN_UNIT $09
	NOTE F_, 4
	NOTE D#, 4
	OCTAVE 2
	NOTE E_, 4
	NOTE B_, 4
	LEN_UNIT $03
	OCTAVE 3
	NOTE C_, 8
	NOTE D_, 8
	NOTE E_, 8
	LEN_UNIT $09
	NOTE D_, 8
	NOTE C#, 4
	NOTE C_, 4
	SND_SEGNO
	LEN_UNIT $03
	OCTAVE 2
	NOTE B_, 8
	OCTAVE 3
	NOTE C_, 8
	NOTE E_, 8
	LEN_UNIT $09
	OCTAVE 3
	NOTE B_, 4
	NOTE A_, 4
	LEN_UNIT $03
	OCTAVE 2
	NOTE B_, 8
	OCTAVE 3
	NOTE C_, 8
	NOTE E_, 8
	LEN_UNIT $09
	OCTAVE 4
	NOTE E_, 4
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE C_, 4
	LEN_UNIT $03
	NOTE C_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN_UNIT $09
	NOTE C_, 4
	LEN_UNIT $03
	NOTE C_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN_UNIT $09
	OCTAVE 3
	NOTE A_, 8
	NOTE F#, 4
	NOTE F_, 4
	LEN_UNIT $03
	OCTAVE 2
	NOTE B_, 8
	OCTAVE 3
	NOTE C_, 8
	NOTE E_, 8
	LEN_UNIT $09
	NOTE B_, 4
	NOTE A_, 4
	LEN_UNIT $03
	OCTAVE 2
	NOTE B_, 8
	OCTAVE 3
	NOTE C_, 8
	NOTE E_, 8
	LEN_UNIT $09
	NOTE A_, 4
	NOTE G_, 4
	OCTAVE 2
	NOTE A_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE E_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE A_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 8
	NOTE E_, 2
	NOTE A_, 2
	LEN_UNIT $03
	NOTE G#, 8
	NOTE B_, 8
	NOTE F_, 8
	NOTE E_, 8
	NOTE D_, 8
	OCTAVE 2
	NOTE B_, 8
	NOTE B_, 8
	OCTAVE 3
	NOTE C_, 8
	NOTE E_, 8
	NOTE B_, 8
	NOTE A_, 8
	NOTE E_, 8
	NOTE E_, 8
	NOTE F_, 8
	OCTAVE 2
	NOTE A_, 8
	OCTAVE 3
	NOTE C_, 8
	OCTAVE 2
	NOTE B_, 8
	OCTAVE 3
	NOTE D_, 8
	OCTAVE 2
	NOTE D_, 8
	NOTE E_, 8
	NOTE F_, 8
	OCTAVE 3
	NOTE E_, 8
	NOTE D_, 8
	NOTE A_, 8
	NOTE E_, 8
	NOTE D_, 8
	NOTE F_, 8
	NOTE E_, 8
	NOTE D_, 8
	OCTAVE 2
	NOTE F_, 8
	LEN_UNIT $09
	NOTE G#, 4
	NOTE A_, 4
	NOTE B_, 4
	OCTAVE 3
	NOTE C_, 4
	NOTE A_, 1
	OCTAVE 4
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 2
	NOTE A#, 4
	LEN_UNIT $03
	OCTAVE 3
	NOTE D_, 8
	NOTE E_, 8
	NOTE F_, 8
	LEN_UNIT $09
	NOTE F#, 4
	NOTE G_, 4
	LEN_UNIT $03
	NOTE G_, 8
	NOTE A#, 8
	NOTE G_, 8
	NOTE A_, 8
	NOTE E_, 8
	NOTE C_, 8
	NOTE A_, 8
	NOTE E_, 8
	NOTE C_, 8
	NOTE A#, 8
	NOTE D#, 8
	NOTE C_, 8
	OCTAVE 4
	NOTE C_, 8
	OCTAVE 3
	NOTE F#, 8
	OCTAVE 4
	NOTE D#, 8
	LEN_UNIT $09
	OCTAVE 3
	NOTE A#, 4
	OCTAVE 2
	NOTE A#, 4
	LEN_UNIT $03
	OCTAVE 3
	NOTE D_, 8
	NOTE E_, 8
	NOTE F_, 8
	LEN_UNIT $09
	NOTE F#, 4
	NOTE G_, 4
	LEN_UNIT $03
	NOTE G_, 8
	NOTE A#, 8
	NOTE G_, 8
	NOTE D#, 8
	NOTE G_, 8
	OCTAVE 4
	NOTE C_, 8
	NOTE D#, 8
	NOTE D_, 8
	NOTE C_, 8
	OCTAVE 3
	NOTE G_, 8
	NOTE G_, 8
	NOTE D#, 8
	NOTE D_, 8
	NOTE F#, 8
	NOTE D_, 8
	OCTAVE 2
	NOTE B_, 8
	OCTAVE 3
	NOTE D_, 8
	NOTE F_, 8
	NOTE A_, 8
	NOTE F_, 8
	NOTE D_, 8
	OCTAVE 2
	NOTE A#, 8
	OCTAVE 3
	NOTE C#, 8
	NOTE F_, 8
	NOTE A_, 8
	NOTE F_, 8
	NOTE C#, 8
	OCTAVE 2
	NOTE A_, 8
	OCTAVE 3
	NOTE D_, 8
	NOTE E_, 8
	NOTE F_, 8
	NOTE E_, 8
	NOTE C_, 8
	OCTAVE 2
	NOTE D_, 8
	NOTE A_, 8
	OCTAVE 3
	NOTE D_, 8
	NOTE F_, 8
	NOTE D_, 8
	OCTAVE 2
	NOTE A_, 8
	OCTAVE 2
	NOTE F_, 8
	NOTE A_, 8
	OCTAVE 3
	NOTE D_, 8
	NOTE F_, 8
	NOTE D_, 8
	OCTAVE 2
	NOTE A_, 8
	LEN_UNIT $09
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE C_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE A_, 1
	NOTE F_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	SND_LOOP

Snd61_Ch3:
	VOICE $09, 5, 4, 4, 0
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 1
	REST 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 1
	REST 2
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 1
	REST 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 1
	REST 2
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	SND_SEGNO
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 1
	REST 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 1
	REST 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 1
	REST 2
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 1
	REST 2
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE A_, 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 2
	NOTE A_, 1
	REST 2
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 1
	REST 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 1
	REST 2
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 1
	REST 2
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE D_, 2
	NOTE D_, 1
	REST 2
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE D_, 2
	NOTE D_, 1
	REST 2
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE C_, 2
	NOTE C_, 1
	REST 2
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE D_, 2
	NOTE D_, 1
	REST 2
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 1
	REST 2
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE E_, 8
	OCTAVE 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	NOTE E_, 1
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
	NOTE A_, 2
	NOTE A_, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 1
	REST 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE C_, 2
	NOTE C_, 1
	REST 2
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE F_, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 1
	REST 2
	NOTE F_, 2
	OCTAVE 2
	NOTE F_, 2
	OCTAVE 1
	NOTE F_, 1
	NOTE F_, 1
	NOTE D#, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 1
	NOTE D#, 2
	NOTE D#, 1
	REST 2
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	OCTAVE 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 1
	REST 2
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 1
	NOTE C_, 2
	NOTE C_, 1
	REST 2
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	OCTAVE 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE D#, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 1
	NOTE D#, 2
	NOTE D#, 1
	REST 2
	NOTE D#, 2
	OCTAVE 2
	NOTE D#, 2
	OCTAVE 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE D_, 2
	NOTE D_, 1
	REST 1
	NOTE D_, 1
	NOTE F#, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 1
	REST 2
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 1
	NOTE A#, 2
	NOTE A#, 1
	REST 2
	NOTE A#, 2
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE D_, 2
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 1
	NOTE D_, 2
	NOTE D_, 1
	REST 2
	NOTE C_, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE C_, 1
	NOTE C_, 1
	NOTE B_, 2
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 1
	REST 2
	NOTE B_, 2
	OCTAVE 2
	NOTE B_, 2
	OCTAVE 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE D_, 8
	LEN_UNIT $03
	NOTE A_, 8
	OCTAVE 2
	NOTE E_, 8
	NOTE D_, 8
	LEN_UNIT $09
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE G_, 1
	NOTE A_, 1
	REST 1
	OCTAVE 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 2
	OCTAVE 2
	NOTE A_, 2
	NOTE G_, 1
	NOTE A_, 1
	REST 1
	OCTAVE 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE C_, 1
	NOTE D_, 1
	REST 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 2
	OCTAVE 2
	NOTE D_, 2
	NOTE C_, 1
	NOTE D_, 1
	REST 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE F_, 1
	NOTE G_, 1
	REST 1
	OCTAVE 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE A#, 1
	OCTAVE 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 2
	OCTAVE 2
	NOTE G_, 2
	NOTE F_, 1
	NOTE G_, 1
	REST 1
	OCTAVE 1
	NOTE D_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE C_, 1
	NOTE A#, 1
	LEN_UNIT $03
	NOTE A_, 8
	NOTE G#, 8
	NOTE G_, 8
	NOTE F_, 8
	NOTE E_, 8
	NOTE D_, 8
	LEN_UNIT $09
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	SND_LOOP

Snd61_Drm:
	SND_SEGNO
	LEN_UNIT $09
	LOOP_START
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 9, 1
	DRUM $0C, 1
	DRUM 9, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	LOOP_END $0F
	LOOP_START
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 9, 1
	DRUM $0C, 1
	DRUM 9, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	LOOP_END $0B
	DRUM $0A, 2
	DRUM $0A, 2
	DRUM $0A, 2
	DRUM $0A, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	LOOP_START
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 9, 1
	DRUM $0C, 1
	DRUM 9, 2
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 3, 1
	LOOP_END $0E
	SND_LOOP

Snd62_Ch2:
	SND_SEGNO
	TEMPO $10
	RELEASE_VOL 8
	VOICE $06, 8, 10, 15, 4
	OCTAVE 3
	NOTE E_, 8
	NOTE G_, 8
	NOTE A#, 8
	NOTE A_, 4
	NOTE G_, 4
	OCTAVE 4
	NOTE C_, 8
	NOTE D_, 8
	NOTE E_, 4
	NOTE B_, 4
	NOTE A_, 2
	NOTE B_, 2
	OCTAVE 5
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	REST 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	OCTAVE 4
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	REST 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE G_, 1
	NOTE E_, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	OCTAVE 5
	NOTE D_, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE B_, 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE B_, 1
	NOTE D#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE F#, 1
	NOTE D#, 1
	NOTE C_, 1
	OCTAVE 3
	NOTE B_, 1
	NOTE A_, 1
	NOTE F#, 1
	OCTAVE 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 2
	NOTE G_, 2
	NOTE F#, 0
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 2
	NOTE G_, 2
	OCTAVE 5
	NOTE D_, 0
	REST 1
	OCTAVE 4
	NOTE G_, 1
	NOTE A_, 1
	NOTE B_, 1
	REST 1
	NOTE F#, 1
	NOTE G_, 1
	NOTE A_, 1
	REST 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	REST 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 2
	NOTE F#, 1
	NOTE E_, 1
	NOTE D#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE B_, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE D#, 1
	SND_LOOP

Snd62_Ch1:
	SND_SEGNO
	VOICE $06, 6, 9, 14, 4
	OCTAVE 2
	NOTE G_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
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
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C#, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
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
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE B_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE G_, 1
	NOTE B_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE D_, 1
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
	OCTAVE 3
	NOTE E_, 1
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
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE G_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE C_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE C_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE D#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE D#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE D#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE D#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE E_, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE C_, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE F#, 1
	NOTE G_, 1
	OCTAVE 2
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F#, 1
	OCTAVE 2
	NOTE C_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE D_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE C_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE A_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE F#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE D#, 1
	NOTE F#, 1
	NOTE B_, 1
	OCTAVE 4
	NOTE D#, 1
	SND_LOOP

Snd62_Ch3:
	SND_SEGNO
	VOICE $06, 5, 2, 14, 4
	LOOP_START
	OCTAVE 2
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
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	LOOP_END $03
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE D_, 1
	NOTE B_, 1
	NOTE A#, 1
	NOTE A_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE D_, 1
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
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
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
	NOTE D_, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	NOTE D#, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE D#, 1
	NOTE B_, 1
	NOTE F#, 1
	NOTE B_, 1
	NOTE D#, 1
	NOTE B_, 1
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
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
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
	NOTE E_, 1
	NOTE F#, 1
	NOTE D_, 1
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
	NOTE G_, 1
	OCTAVE 3
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE F#, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE F#, 1
	OCTAVE 1
	NOTE E_, 1
	OCTAVE 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	OCTAVE 1
	NOTE D_, 1
	OCTAVE 2
	NOTE D_, 1
	NOTE D_, 1
	NOTE D_, 1
	OCTAVE 1
	NOTE C_, 1
	OCTAVE 2
	NOTE C_, 1
	NOTE C_, 1
	NOTE C_, 1
	OCTAVE 1
	NOTE B_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 1
	NOTE A_, 1
	OCTAVE 2
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	NOTE B_, 1
	SND_LOOP

Snd62_Drm:
	SND_SEGNO
	LEN_UNIT $06
	LOOP_START
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 9, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 9, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 9, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 9, 1
	DRUM $0C, 1
	LOOP_END $07
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 9, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 9, 1
	DRUM $0C, 1
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	DRUM 9, 2
	LOOP_START
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 9, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 9, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 9, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM $0C, 1
	DRUM 9, 1
	DRUM $0C, 1
	LOOP_END $04
	DRUM $0C, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0C, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0C, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0C, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0C, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM 3, 1
	DRUM $0C, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 3, 1
	DRUM 9, 1
	DRUM $0C, 1
	DRUM 9, 1
	DRUM $0C, 1
	SND_LOOP

Snd63_Ch2:
	SND_SEGNO
	VOICE $07, 8, 8, 8, 6
	OCTAVE 3
	NOTE F#, 8
	OCTAVE 4
	NOTE C#, 4
	OCTAVE 3
	NOTE A_, 8
	NOTE B_, 2
	NOTE A_, 2
	NOTE G#, 6
	NOTE F#, 2
	NOTE E_, 4
	NOTE F#, 8
	REST 4
	OCTAVE 4
	NOTE C#, 8
	NOTE E_, 4
	NOTE D#, 6
	NOTE C#, 2
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 4
	NOTE C#, 12
	REST $0C
	NOTE C#, 8
	NOTE E_, 4
	OCTAVE 3
	NOTE G#, 12
	NOTE B_, 4
	OCTAVE 4
	NOTE C#, 4
	OCTAVE 3
	NOTE A_, 4
	NOTE F#, 12
	NOTE F#, 4
	NOTE G#, 4
	NOTE A_, 4
	NOTE G#, 4
	NOTE E_, 4
	NOTE F#, 4
	NOTE G#, 12
	NOTE C#, 12
	SND_LOOP

Snd63_Ch1:
	SND_SEGNO
	VOICE $07, 8, 6, 4, 6
	OCTAVE 3
	NOTE C#, 8
	NOTE F#, 4
	NOTE C#, 8
	OCTAVE 2
	NOTE A_, 4
	NOTE B_, 8
	OCTAVE 3
	NOTE G#, 4
	NOTE D_, 4
	NOTE C#, 4
	OCTAVE 2
	NOTE B_, 4
	OCTAVE 3
	NOTE C#, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F#, 4
	NOTE B_, 4
	OCTAVE 4
	NOTE D#, 4
	NOTE F#, 12
	NOTE F_, 12
	NOTE F#, 4
	OCTAVE 3
	NOTE A_, 4
	OCTAVE 4
	NOTE C#, 4
	OCTAVE 3
	NOTE E_, 8
	OCTAVE 4
	NOTE C#, 4
	OCTAVE 3
	NOTE D#, 4
	NOTE F#, 4
	OCTAVE 3
	NOTE D#, 4
	OCTAVE 2
	NOTE B_, 8
	OCTAVE 3
	NOTE B_, 4
	OCTAVE 2
	NOTE A_, 4
	OCTAVE 3
	NOTE D_, 4
	NOTE F#, 4
	NOTE E_, 4
	OCTAVE 2
	NOTE B_, 4
	OCTAVE 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE D#, 4
	NOTE F_, 4
	NOTE F_, 4
	OCTAVE 3
	NOTE B_, 4
	NOTE F_, 4
	SND_LOOP

Snd63_Ch3:
	SND_SEGNO
	VOICE $07, 6, 2, 8, 8
	OCTAVE 2
	NOTE F#, 12
	NOTE F#, 12
	NOTE G#, 8
	NOTE E_, 4
	NOTE F#, 4
	NOTE F#, 4
	NOTE G#, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE F#, 4
	NOTE B_, 4
	NOTE C#, 8
	NOTE G#, 4
	OCTAVE 3
	NOTE C#, 4
	OCTAVE 2
	NOTE G#, 4
	NOTE C#, 4
	NOTE F#, 12
	NOTE E_, 8
	NOTE G#, 4
	NOTE D#, 8
	NOTE B_, 4
	OCTAVE 1
	NOTE B_, 4
	OCTAVE 2
	NOTE C#, 4
	NOTE D#, 4
	NOTE D_, 12
	NOTE E_, 4
	NOTE F#, 4
	NOTE G#, 4
	NOTE C#, 4
	NOTE G#, 4
	OCTAVE 3
	NOTE C#, 4
	OCTAVE 2
	NOTE G#, 4
	NOTE B_, 4
	NOTE G#, 4
	SND_LOOP

Snd63_Drm:
	SND_END

; Orphan drum stream (no header points here).
B15_Data_7B3E:
	LEN_UNIT $07
	DRUM 1, 4
	DRUM 1, 4
	DRUM 1, 4
	DRUM 1, 4
	DRUM 1, 4
	DRUM 1, 4
	SND_END

Snd64_Ch2:
	VOICE $07, 8, 10, 4, 6
	RELEASE_VOL 6
	OCTAVE 3
	NOTE F_, 4
	NOTE E_, 4
	NOTE A#, 4
	NOTE G#, 4
	NOTE G_, 8
	OCTAVE 4
	NOTE C#, 4
	NOTE C_, 4
	SND_SEGNO
	OCTAVE 3
	NOTE D_, 1
	NOTE E_, 1
	NOTE F_, 1
	NOTE G_, 1
	NOTE A_, 6
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE D#, 4
	OCTAVE 4
	NOTE C_, 4
	OCTAVE 3
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 1
	REST 1
	NOTE F#, 2
	NOTE G_, 1
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE D_, 6
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE D_, 2
	OCTAVE 3
	NOTE G_, 2
	LOOP_START
	OCTAVE 4
	NOTE F_, 8
	NOTE E_, 4
	NOTE D_, 4
	LOOP_END $03
	NOTE C#, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	REST 1
	NOTE G_, 1
	NOTE A_, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE F_, 2
	OCTAVE 3
	NOTE A#, 2
	OCTAVE 4
	NOTE E_, 2
	OCTAVE 3
	NOTE G_, 2
	OCTAVE 4
	NOTE F_, 2
	OCTAVE 3
	NOTE A_, 2
	SND_LOOP

Snd64_Ch1:
	VOICE $07, 8, 8, 14, 6
	RELEASE_VOL 6
	OCTAVE 2
	NOTE A#, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE C#, 2
	OCTAVE 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE A#, 2
	OCTAVE 3
	NOTE C_, 2
	NOTE C#, 2
	NOTE E_, 2
	SND_SEGNO
	LOOP_START
	NOTE F_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE D_, 1
	LOOP_END $04
	NOTE C_, 1
	OCTAVE 2
	NOTE G_, 1
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE C_, 1
	NOTE G_, 1
	NOTE C_, 1
	NOTE F#, 1
	NOTE D_, 1
	NOTE G_, 1
	NOTE E_, 1
	NOTE A_, 1
	NOTE F#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A_, 1
	OCTAVE 3
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE A_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE A#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE A_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE B_, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	NOTE G#, 1
	NOTE D_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE D_, 1
	LOOP_START
	NOTE A_, 1
	NOTE F_, 1
	NOTE D_, 1
	NOTE F_, 1
	LOOP_END $04
	NOTE A#, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE D_, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE D_, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE G_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 4
	NOTE F_, 1
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE E_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE D_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE E_, 1
	SND_LOOP

Snd64_Ch3:
	VOICE $07, 14, 2, 4, 6
	RELEASE_VOL 5
	OCTAVE 1
	NOTE G_, 2
	NOTE G_, 2
	OCTAVE 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE C#, 2
	NOTE C_, 2
	NOTE C#, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE A#, 2
	OCTAVE 2
	NOTE C_, 2
	OCTAVE 1
	NOTE A#, 2
	NOTE G#, 2
	NOTE A_, 2
	SND_SEGNO
	LOOP_START
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	LOOP_END $03
	NOTE E_, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	SND_LOOP

Snd64_Drm:
	LEN_UNIT $07
	REST 0
	REST 0
	SND_SEGNO
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	SND_LOOP

Snd65_Ch2:
	SND_SEGNO
	VOICE $07, 8, 11, 8, 4
	OCTAVE 2
	NOTE A#, 2
	OCTAVE 3
	NOTE D#, 2
	NOTE D#, 12
	REST 4
	NOTE F_, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE D#, 12
	REST 2
	NOTE C#, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE A#, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE C#, 2
	OCTAVE 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE A#, 12
	NOTE A#, 2
	NOTE A_, 2
	NOTE A_, 12
	NOTE A_, 2
	NOTE G#, 2
	NOTE B_, 2
	OCTAVE 3
	NOTE E_, 2
	NOTE E_, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE G#, 2
	NOTE D#, 2
	NOTE A#, 2
	NOTE D_, 2
	NOTE A#, 2
	NOTE C_, 2
	NOTE A#, 2
	NOTE D_, 2
	NOTE A#, 2
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
	NOTE D_, 1
	NOTE A#, 1
	NOTE D#, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE F#, 1
	NOTE A#, 1
	NOTE F_, 1
	NOTE A#, 1
	NOTE F#, 1
	NOTE A#, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE B_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE A_, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE G#, 1
	NOTE C#, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE B_, 1
	NOTE C#, 1
	NOTE A_, 1
	NOTE D_, 1
	NOTE B_, 1
	NOTE F#, 1
	OCTAVE 4
	NOTE D_, 1
	NOTE C#, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE D_, 1
	OCTAVE 3
	NOTE F#, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE F_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE F_, 1
	NOTE B_, 1
	NOTE C#, 1
	NOTE B_, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE G#, 1
	NOTE C#, 1
	SND_LOOP

Snd65_Ch1:
	SND_SEGNO
	VOICE $07, 6, 9, 4, 6
	LOOP_START
	OCTAVE 2
	NOTE D#, 1
	OCTAVE 3
	NOTE F#, 1
	LOOP_END $04
	LOOP_START
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE D#, 1
	LOOP_END $08
	LOOP_START
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D_, 1
	LOOP_END $03
	OCTAVE 2
	NOTE G#, 1
	OCTAVE 3
	NOTE D_, 1
	LOOP_START
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE D#, 1
	LOOP_END $04
	LOOP_START
	OCTAVE 2
	NOTE A#, 1
	OCTAVE 3
	NOTE F#, 1
	LOOP_END $04
	LOOP_START
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE D#, 1
	LOOP_END $04
	LOOP_START
	OCTAVE 2
	NOTE F_, 1
	OCTAVE 3
	NOTE C#, 1
	LOOP_END $04
	LOOP_START
	OCTAVE 2
	NOTE F#, 1
	OCTAVE 3
	NOTE E_, 1
	LOOP_END $04
	LOOP_START
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE C#, 1
	LOOP_END $04
	LOOP_START
	OCTAVE 2
	NOTE E_, 1
	OCTAVE 3
	NOTE C_, 1
	LOOP_END $04
	OCTAVE 2
	NOTE D#, 1
	NOTE A_, 1
	NOTE D#, 1
	NOTE A_, 1
	NOTE D#, 1
	NOTE A_, 1
	NOTE D#, 1
	NOTE A_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	OCTAVE 2
	NOTE G#, 1
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE G#, 1
	OCTAVE 2
	NOTE B_, 1
	OCTAVE 3
	NOTE E_, 1
	NOTE G#, 1
	NOTE B_, 1
	NOTE E_, 1
	NOTE G#, 1
	NOTE B_, 1
	NOTE E_, 1
	LOOP_START
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE G#, 1
	NOTE A#, 1
	LOOP_END $02
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE A#, 1
	NOTE G#, 1
	OCTAVE 1
	NOTE A#, 1
	OCTAVE 2
	NOTE F_, 1
	NOTE G#, 1
	NOTE F_, 1
	LOOP_START
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE A#, 1
	LOOP_END $04
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	OCTAVE 3
	NOTE D#, 1
	OCTAVE 2
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE C#, 1
	NOTE F#, 1
	NOTE C#, 1
	OCTAVE 2
	NOTE A_, 1
	NOTE G#, 1
	LOOP_START
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE A_, 1
	LOOP_END $04
	OCTAVE 2
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE B_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE B_, 1
	SND_LOOP

Snd65_Ch3:
	SND_SEGNO
	VOICE $07, 5, 2, 9, 6
	OCTAVE 1
	NOTE D#, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE A#, 2
	NOTE G#, 2
	NOTE F#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE G#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE D#, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE F_, 2
	NOTE D#, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE B_, 2
	NOTE B_, 2
	NOTE G#, 2
	NOTE G#, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE C#, 2
	OCTAVE 1
	NOTE C#, 2
	NOTE C#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	OCTAVE 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE A#, 2
	NOTE A#, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE D#, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE F#, 2
	NOTE F#, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	NOTE C#, 2
	SND_LOOP

Snd65_Drm:
	SND_SEGNO
	LEN_UNIT $07
	DRUM $0C, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 1, 2
	DRUM 1, 2
	SND_LOOP

Snd66_Ch2:
	VOICE $06, 8, 9, 15, 4
	OCTAVE 5
	NOTE F_, 1
	NOTE G_, 1
	NOTE G#, 1
	NOTE A#, 1
	NOTE C_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 5
	NOTE C_, 1
	OCTAVE 4
	NOTE C#, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 2
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE F#, 1
	NOTE A#, 2
	OCTAVE 4
	NOTE C_, 2
	NOTE C#, 4
	NOTE D#, 4
	NOTE D#, 2
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 2
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	REST 1
	NOTE G#, 1
	NOTE G#, 1
	REST 1
	NOTE F#, 1
	OCTAVE 3
	NOTE G_, 1
	OCTAVE 4
	NOTE G_, 2
	NOTE G#, 2
	NOTE A_, 2
	OCTAVE 5
	NOTE F#, 2
	NOTE C_, 2
	NOTE C_, 1
	NOTE C#, 1
	NOTE D_, 1
	NOTE D#, 1
	NOTE E_, 2
	NOTE F#, 2
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	NOTE G_, 1
	SND_END

Snd66_Ch1:
	VOICE $06, 6, 8, 15, 6
	OCTAVE 3
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE E_, 1
	NOTE C#, 1
	NOTE C_, 1
	NOTE D#, 1
	NOTE E_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	OCTAVE 3
	NOTE F#, 3
	NOTE F#, 1
	NOTE D#, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE A_, 1
	OCTAVE 4
	NOTE C_, 1
	OCTAVE 3
	NOTE F#, 1
	NOTE C#, 1
	NOTE F#, 1
	NOTE C#, 1
	NOTE D#, 1
	OCTAVE 5
	NOTE C#, 6
	OCTAVE 4
	NOTE A_, 1
	NOTE F_, 1
	OCTAVE 5
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	NOTE G#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE A_, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE D#, 1
	NOTE F_, 1
	NOTE F#, 1
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE G#, 1
	NOTE A_, 1
	NOTE G#, 1
	OCTAVE 3
	NOTE G#, 1
	OCTAVE 4
	NOTE G#, 1
	NOTE F_, 1
	OCTAVE 5
	NOTE C#, 1
	NOTE G#, 1
	NOTE C#, 1
	NOTE C#, 1
	OCTAVE 4
	NOTE D#, 1
	NOTE G_, 1
	OCTAVE 3
	NOTE D#, 1
	NOTE A#, 1
	OCTAVE 4
	NOTE C_, 1
	NOTE C#, 1
	NOTE C#, 2
	NOTE C#, 2
	SND_END

Snd66_Ch3:
	VOICE $06, 5, 2, 7, 3
	REST 4
	OCTAVE 2
	NOTE C#, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE F#, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE C_, 2
	OCTAVE 1
	NOTE F#, 2
	NOTE G#, 2
	NOTE G_, 2
	NOTE D#, 2
	OCTAVE 2
	NOTE C#, 2
	NOTE C_, 2
	NOTE C#, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE G#, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE D#, 2
	NOTE D_, 2
	OCTAVE 1
	NOTE G#, 2
	NOTE B_, 2
	NOTE A#, 2
	NOTE F_, 2
	OCTAVE 2
	NOTE D#, 2
	NOTE D_, 2
	NOTE D#, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 1
	NOTE F#, 2
	NOTE F#, 2
	SND_END

Snd66_Drm:
	LEN_UNIT $06
	DRUM 3, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 9, 2
	DRUM $0C, 2
	DRUM 9, 2
	DRUM $0C, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM 9, 2
	DRUM 3, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 9, 2
	DRUM $0C, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM $0C, 2
	DRUM $0C, 2
	DRUM 9, 2
	DRUM $0C, 2
	DRUM 9, 2
	DRUM $0C, 2
	DRUM 3, 2
	DRUM $0C, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM $0C, 2
	DRUM 3, 2
	DRUM 3, 2
	DRUM $0C, 2
	DRUM 3, 2
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	DRUM 9, 1
	SND_END

; Unused ($FF) to the end of the bank.
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF
