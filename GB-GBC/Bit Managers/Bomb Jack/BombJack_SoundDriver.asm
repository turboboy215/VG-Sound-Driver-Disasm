; =====================================================================
; Bomb Jack (U) - Game Boy, Infogrames 1992
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 2
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o bombjack.o BombJack_SoundDriver.asm
;   rgblink -t -o bombjack.gb bombjack.o
;   python tools/cmp_ranges.py bombjack.gb "Bomb Jack (U).gb" <ranges listed in the doc>
; (-t: 32 KB ROM without MBC, so $4000-$7FFF is plain ROM.)
;
; Documentation: BombJack_SoundDriver.md / AJG_SoundEngine_Family.md
; =====================================================================


; ---- pitch names: NOTE <pitch>, <octave> ; byte = (octave - 1) * 12 + pitch
; note byte 12 = C2 = first entry of the period table (65.4 Hz on CH1/CH2).
DEF C_ EQU 0
DEF Csh EQU 1
DEF D_ EQU 2
DEF Dsh EQU 3
DEF E_ EQU 4
DEF F_ EQU 5
DEF Fsh EQU 6
DEF G_ EQU 7
DEF Gsh EQU 8
DEF A_ EQU 9
DEF Ash EQU 10
DEF B_ EQU 11

MACRO NOTE
	db (\2 - 1) * 12 + \1
ENDM

; ---- stream commands (patterns, SFX streams and instrument macros) ----
MACRO LEN       ; note length in ticks, 1-57
	db $C6 + \1
ENDM
MACRO VOL       ; start volume of following notes, 0-15 (software envelope mode)
	db $A7 + \1
ENDM
MACRO VOLENV    ; start volume + envelope: atk (lo=count hi=step), dec (lo=count hi=step), rates (hi=atk lo=dec)
	db $B7 + \1, \2, \3, \4
ENDM
MACRO INSTR     ; instrument 0-25 from the current song's instrument table
	db $7E + \1
ENDM
MACRO ARP       ; arpeggio 0-14 from the current song's arpeggio table
	db $98 + \1
ENDM
MACRO DRUMS     ; DRUMS 0 = off, DRUMS tempo, pattern
	db $6B, \1
	IF _NARG > 1
		dw \2
	ENDC
ENDM
MACRO HWENV     ; HWENV env | HWENV env, 0 | HWENV env, ticks, env2  (hardware envelope mode)
	db $72, \1
	IF _NARG > 1
		db \2
	ENDC
	IF _NARG > 2
		db \3
	ENDC
ENDM
MACRO RELEASE   ; RELEASE 0 = off | RELEASE ticks_left, env
	db $77, \1
	IF _NARG > 1
		db \2
	ENDC
ENDM
MACRO GLIDE
	db $60
	db \1
ENDM
MACRO WAIT2
	db $61
ENDM
MACRO VIBRATO
	db $62
	db \1
	db \2
	db \3
ENDM
MACRO WAIT
	db $63
ENDM
MACRO REST
	db $64
ENDM
MACRO STOP_ALL
	db $65
ENDM
MACRO END
	db $66
ENDM
MACRO TRANSPOSE
	db $67
	db \1
ENDM
MACRO NEXT
	db $68
ENDM
MACRO ORDER_JUMP
	db $69
	dw \1
ENDM
MACRO LENGTH
	db $6A
	db \1
ENDM
MACRO PAN_C
	db $6C
ENDM
MACRO PAN_R
	db $6D
ENDM
MACRO PAN_L
	db $6E
ENDM
MACRO DUTY_50
	db $6F
ENDM
MACRO DUTY_75
	db $70
ENDM
MACRO DUTY_12
	db $71
ENDM
MACRO AUTOPAN
	db $73
	db \1
ENDM
MACRO AUTODUTY
	db $74
	db \1
ENDM
MACRO WAVE
	db $75
	dw \1
ENDM
MACRO CH_TRANSPOSE
	db $76
	db \1
ENDM
MACRO ARP_OFF
	db $78
ENDM
MACRO PAT_GOTO
	db $79
	dw \1
ENDM
MACRO PAT_CALL
	db $7A
	dw \1
ENDM
MACRO NOISE_SEQ2
	db $7B
ENDM
MACRO NOISE_SEQ3
	db $7C
ENDM
MACRO NOISE_HIT7
	db $7D
ENDM
; ---- order lists ----
MACRO ORDER_LOOP  ; end of an order list: 0, then the order position to continue from
	dw 0, \1
ENDM
; ---- arpeggio tables ----
DEF ARP_LOOP EQU $68   ; restart the table
DEF ARP_HOLD EQU $FF   ; stay on the previous entry
; ---- drum patterns (one step per drum tick) ----
DEF DRUM_LOOP EQU $FF

; ---- RAM / HRAM ----
DEF wGameC001 EQU $C001
DEF wShFreqHi EQU $C318
DEF wShFreqHi2 EQU $C319
DEF wShFreqHi3 EQU $C31A
DEF wShNR32 EQU $C31B
DEF wInInstr EQU $C31C
DEF wTranspose EQU $C31D
DEF wShNR51 EQU $C31E
DEF wInstrTable EQU $C31F
DEF wInstrTableHi EQU $C320
DEF wArpTable EQU $C321
DEF wArpTableHi EQU $C322
DEF wMusicWave EQU $C323
DEF wMusicWaveHi EQU $C324
DEF wFadePtr EQU $C325
DEF wFadePtrHi EQU $C326
DEF wDrumPatHi EQU $C327
DEF wDrumPatLo EQU $C328
DEF wDrumPos EQU $C329
DEF wDrumsOn EQU $C32A
DEF wDrumTempo EQU $C32B
DEF wDrumTimer EQU $C32C
DEF wNoiseNR43Hi EQU $C32D
DEF wNoiseNR43Lo EQU $C32E
DEF wNoiseNR42Hi EQU $C32F
DEF wNoiseNR42Lo EQU $C330
DEF wNoisePos EQU $C331
DEF wNoiseOn EQU $C332
DEF wFadePos EQU $C335
DEF wFadeTimer EQU $C336
DEF wFadeSpeed EQU $C337
DEF wFadeOn EQU $C338
DEF wCh1 EQU $C400
DEF wCh1Ptr EQU $C402
DEF wCh2 EQU $C500
DEF wCh2On EQU $C510
DEF wCh3 EQU $C600
DEF wCh3On EQU $C610
DEF wSfx EQU $C700
DEF wSfxPtr EQU $C702
DEF wSfxId EQU $C710
DEF hGameFF82 EQU $FF82
DEF hGameFF99 EQU $FF99
DEF hGameFFC0 EQU $FFC0

; ---- hardware registers (subset of hardware.inc) ----
DEF rTIMA EQU $FF05
DEF rTMA EQU $FF06
DEF rTAC EQU $FF07
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
DEF rLCDC EQU $FF40
DEF rSTAT EQU $FF41
DEF rLY EQU $FF44
DEF rBGP EQU $FF47
DEF rOBP0 EQU $FF48
DEF rOBP1 EQU $FF49
DEF rIE EQU $FFFF


; rst $00: jp MemCopy (game code, used by SndInit)
SECTION "RST00_MemCopy", ROM0[$0000]

Rst00_MemCopy:
	jp MemCopy

; rst $18: hl += a
SECTION "RST18_AddHLA", ROM0[$0018]

Rst18_AddHLA:
	add a, l
	ld l, a
	adc a, h
	sub l
	ld h, a
	ret

; rst $20: [de++] = [hl++], bc-- (flags/af kept)
SECTION "RST20_CopyByte", ROM0[$0020]

Rst20_CopyByte:
	push af
	ld a, [hli]
	ld [de], a
	inc de
	pop af
	dec bc
	ret

; Game VBlank handler: calls SndUpdate every frame
SECTION "VBlankSndHook", ROM0[$0316]


; Game VBlank handler (from $025F): SndUpdate runs once per frame (59.73 Hz).
VBlankSndHook:
	call SndUpdate

; Game MemCopy: copy bc bytes hl -> de
SECTION "MemCopy", ROM0[$1470]

MemCopy:
	ld a, [hli]
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, MemCopy
	ret

SECTION "SoundDriver", ROMX[$54EE], BANK[1]


; SndUpdate: NR52 = $80, NR50 fade, tick the four pages (Ch1 $C4xx, Ch2 $C5xx,
; Ch3 $C6xx, Sfx $C7xx), drum sequencer, noise sequence, then output.
SndUpdate:
	ld a, $80
	ldh [rNR52], a
	call DoFade
	ld hl, wCh1
	call ChannelTick
	inc h
	ld hl, wCh2
	call ChannelTick
	inc h
	ld hl, wCh3
	call ChannelTick
	inc h
	ld hl, wSfx
	call ChannelTick
	call DrumTick
	call OutputAll
	ret

; DrumTick: every wDrumTempo ticks one drum pattern step; then the noise sequence.
DrumTick:
	ld hl, wDrumTimer
	dec [hl]
	call z, DrumStep
	jp NoiseSeqTick

; ChannelTick (h = page): skipped while field $10 = 0. Effects run before the
; length counter; ReadStream runs when it reaches 0.
ChannelTick:
	ld l, $10
	ld a, [hl]
	and a
	ret z
	call DoAutoDuty
	call DoAutoPan
	call DoGlide
	call DoEnvelope
	call DoArp
	call DoVibrato
	ld l, $02
	ld e, [hl]
	inc l
	ld d, [hl]
	call CheckRelease
	ld l, $05
	dec [hl]
	ret nz

; ReadStream (de = stream): wInInstr = $C9 while an instrument macro runs.
; Bytes < $60 are notes: store the note, the stream pointer, set the period, restart
; the arpeggio, hardware envelope, length, vibrato, flags and volume, split the envelope.
ReadStream:
	ld a, [wInInstr]
	cp $C9
	ret z
	ld a, [de]
	inc de
	cp $60
	jr nc, StreamCommand
	ld l, $0C
	ld [hl], a
	ld l, $02
	ld [hl], e
	inc l
	ld [hl], d
	call SetNoteFreq
	ld l, $21
	ld [hl], $00
	call DoArp
	call HwEnvNoteOn
	ld l, $0D
	ld a, [hl]
	ld l, $05
	ld [hl], a
	ld l, $25
	ld a, [hld]
	srl a
	ld [hl], a
	ld l, $26
	ld a, [hl]
	ld l, $22
	ld [hl], a
	ld l, $04
	res 6, [hl]
	res 2, [hl]
	ld l, $17
	ld a, [hl]
	ld l, $0B
	ld [hl], a
	ld l, $11
	call SplitNibbles
	inc l
SplitNibbles:
	ld a, [hl]
	ld c, a
	and $0F
	inc l
	ld [hl], a
	ld a, c
	swap a
	and $0F
	inc l
	ld [hl], a
	ret

; Command ranges: $C7+ length, $B7+ vol/env, $A7+ volume, $98+ arpeggio,
; $7E+ instrument, $60-$7D table.
StreamCommand:
	cp $C7
	jr nc, Cmd_Len
	cp $B7
	jr nc, Cmd_VolEnv
	cp $A7
	jr nc, Cmd_Vol
	cp $98
	jr nc, Cmd_Arp
	cp $7E
	jr nc, Cmd_Instrument
	sub $60
	add a, a
	ld c, a
	add a, LOW(CmdTable)
	ld c, a
	adc a, HIGH(CmdTable)
	sub c
	ld b, a
	ld a, [bc]
	ld l, a
	inc bc
	ld a, [bc]
	ld b, a
	ld c, l
	call CallBC
	jr ReadStream
CallBC:
	push bc
	ret
Cmd_Len:
	sub $C6
	ld l, $0D
	ld [hl], a
	jp ReadStream
Cmd_VolEnv:
	ld l, $27
	ld [hl], $00
	sub $B7
	ld l, $17
	ld [hl], a
	push hl
	push de
	pop hl
	pop de
	ld e, $11
	rst $20
	ld e, $14
	rst $20
	push hl
	push de
	pop hl
	pop de
	ld a, [de]
	swap a
	and $0F
	ld l, $1A
	ld [hli], a
	ld [hl], a
	ld a, [de]
	and $0F
	ld l, $1C
	ld [hli], a
	ld [hl], a
	inc de
	jp ReadStream
Cmd_Vol:
	sub $A7
	ld l, $17
	ld [hl], a
	jp ReadStream
Cmd_Arp:
	sub $98
	add a, a
	ld c, a
	ld a, [wArpTable]
	add a, c
	ld c, a
	ld b, a
	ld a, [wArpTableHi]
	adc a, b
	sub c
	ld b, a
	ld a, [bc]
	ld l, $1F
	ld [hli], a
	inc bc
	ld a, [bc]
	ld [hl], a
	ld l, $21
	ld [hl], $00
	ld l, $04
	set 0, [hl]
	jp ReadStream

; Cmd_Instrument ($7E-$97): clears vibrato/arpeggio/glide/auto-pan/auto-duty/
; hw envelope, centres the pan and sets 50 % duty, then runs the macro from the
; song's instrument table (wInstrTable - 2 + 2*(byte - $7D)) until $66 or $68.
Cmd_Instrument:
	push de
	push hl
	push af
	ld l, $04
	res 3, [hl]
	res 0, [hl]
	xor a
	ld l, $0E
	ld [hl], a
	ld l, $2B
	ld [hl], a
	ld l, $2E
	ld [hl], a
	ld l, $27
	ld [hl], a
	call Cmd_PanC
	call Cmd_Duty50
	pop af
	sub $7D
	add a, a
	push af
	ld a, [wInstrTable]
	ld l, a
	ld a, [wInstrTableHi]
	ld h, a
	pop af
	add a, l
	ld l, a
	adc a, h
	sub l
	ld h, a
	ld e, [hl]
	inc hl
	ld d, [hl]
	pop hl
	ld a, $C9
	ld [wInInstr], a
InstrLoop:
	ld a, [de]
	inc de
	cp $66
	jr z, InstrDone
	cp $68
	jr z, InstrDone
	call InstrCommand
	jr InstrLoop
InstrCommand:
	cp $C7
	jp nc, Cmd_Len
	cp $B7
	jp nc, Cmd_VolEnv
	cp $A7
	jp nc, Cmd_Vol
	cp $98
	jp nc, Cmd_Arp
	sub $60
	add a, a
	ld c, a
	add a, LOW(CmdTable)
	ld c, a
	adc a, HIGH(CmdTable)
	sub c
	ld b, a
	ld a, [bc]
	ld l, a
	inc bc
	ld a, [bc]
	ld b, a
	ld c, l
	jp CallBC
InstrDone:
	xor a
	ld [wInInstr], a
	pop de
	jp ReadStream
CmdTable:
	dw Cmd_Glide
	dw Cmd_Wait2
	dw Cmd_Vibrato
	dw Cmd_Wait
	dw Cmd_Rest
	dw StopAll
	dw Cmd_End
	dw Cmd_Transpose
	dw Cmd_Next
	dw Cmd_OrderJump
	dw Cmd_Length
	dw Cmd_Drums
	dw Cmd_PanC
	dw Cmd_PanR
	dw Cmd_PanL
	dw Cmd_Duty50
	dw Cmd_Duty75
	dw Cmd_Duty12
	dw Cmd_HwEnv
	dw Cmd_AutoPan
	dw Cmd_AutoDuty
	dw Cmd_Wave
	dw Cmd_ChTranspose
	dw Cmd_Release
	dw Cmd_ArpOff
	dw Cmd_PatGoto
	dw Cmd_PatCall
	dw Cmd_NoiseSeq2
	dw Cmd_NoiseSeq3
	dw Cmd_NoiseHit7

; Not in CmdTable (left over from version 1: CHORUS_ON / CHORUS_OFF). The
; byte at Unused_ChorusOff-1 is the last byte of Unused_ChorusOn.
Unused_ChorusOn:
	ld l, $04
	set 5, [hl]
	ret
Unused_ChorusOff:
	ld l, $04
	res 5, [hl]
	ret

; PatReturn: NEXT inside a PAT_CALL returns to the saved pointer (fields $3B/$3C, one level).
PatReturn:
	ld l, $3B
	ld e, [hl]
	ld [hl], $00
	inc l
	ld d, [hl]
	ld l, $02
	ld [hl], e
	inc l
	ld [hl], d
	ret
Cmd_PatCall:
	ld l, $3B
	inc de
	inc de
	ld [hl], e
	inc l
	ld [hl], d
	dec de
	dec de
Cmd_PatGoto:
	ld l, $02
	ld a, [de]
	ld [hl], a
	inc de
	inc l
	ld a, [de]
	ld [hl], a
	dec l
	ld e, [hl]
	inc l
	ld d, [hl]
	ret
Cmd_ArpOff:
	ld l, $04
	res 0, [hl]
	ret

; CheckRelease: when RELEASE is set and the ticks left = field $39 (and the next
; byte isn't WAIT): pulse channels load env2 = field $3A into NRx2 (via $31/$32);
; CH3 takes the hi nibble of $3A as its volume. Happens once per note (flag bit 2).
CheckRelease:
	ld l, $04
	bit 1, [hl]
	ret z
	bit 2, [hl]
	ret nz
	ld l, $05
	ld c, [hl]
	ld l, $39
	ld a, [hl]
	cp c
	ret nz
	ld a, [de]
	cp $63
	ret z
	ld l, $3A
	ld a, h
	cp $C6
	jr z, L572F
	cp $C7
	jr z, L572F
	ld a, [hl]
	ld l, $31
	ld [hli], a
	ld [hl], $01
L572A:
	ld l, $04
	set 2, [hl]
	ret
L572F:
	ld a, [hl]
	and $F0
	swap a
	ld l, $0B
	ld [hl], a
	jr L572A
Cmd_Release:
	ld l, $39
	ld a, [de]
	inc de
	and a
	jr z, L574A
	ld [hl], a
	inc l
	ld a, [de]
	ld [hl], a
	inc de
	ld l, $04
	set 1, [hl]
	ret
L574A:
	ld l, $04
	res 1, [hl]
	ret
Cmd_ChTranspose:
	ld l, $0F
	ld a, [de]
	ld [hl], a
	inc de
	ret
Cmd_Glide:
	ld l, $0E
	ld a, [de]
	ld [hl], a
	inc de
	ret
DoGlide:
	ld l, $0E
	ld a, [hl]
	and a
	ret z
	ld l, $0C
	add a, [hl]
	ld [hl], a
	jp SetNoteFreq
Cmd_Wait2:
	jr Cmd_Wait
Cmd_Vibrato:
	push hl
	push de
	pop hl
	pop de
	ld e, $22
	rst $20
	rst $20
	ld a, [hl]
	rst $20
	ld [de], a
	push hl
	push de
	pop hl
	pop de
	ld l, $22
	ld a, [hl]
	ld l, $26
	ld [hl], a
	ld l, $04
	set 3, [hl]
	set 6, [hl]
	ret
DoVibrato:
	ld l, $04
	bit 3, [hl]
	ret z
	ld l, $22
	ld a, [hl]
	and a
	jr z, L5793
	dec a
	ld [hl], a
	ret
L5793:
	ld l, $04
	bit 6, [hl]
	jr z, L57B2
	ld l, $24
	dec [hl]
	jr nz, L57A6
	inc l
	ld a, [hld]
	ld [hl], a
	ld l, $04
	res 6, [hl]
	ret
L57A6:
	ld l, $23
	ld a, [hl]
	ld l, $07
	add a, [hl]
	ld [hl], a
	ret nc
	ld l, $09
	inc [hl]
	ret
L57B2:
	ld l, $24
	dec [hl]
	jr nz, L57BF
	inc l
	ld a, [hld]
	ld [hl], a
	ld l, $04
	set 6, [hl]
	ret
L57BF:
	ld l, $07
	ld a, [hl]
	ld l, $23
	sub [hl]
	ld l, $07
	ld [hl], a
	ret nc
	ld l, $09
	dec [hl]
	ret
Cmd_Wait:
	pop af
	ld l, $0D
	ld a, [hl]
	ld l, $05
	ld [hl], a
	ld l, $02
	ld [hl], e
	inc l
	ld [hl], d
	ret
Cmd_Rest:
	ld l, $0B
	ld [hl], $00
	ld a, h
	cp $C6
	jr z, Cmd_Wait
	cp $C7
	jr z, Cmd_Wait
	ld l, $31
	ld [hl], $00
	inc l
	ld [hl], $01
	jr Cmd_Wait

; StopAll: drums, noise sequence and fade off, reset all four pages, wTranspose = 0, NR42 = 0.
StopAll:
	push af
	push de
	push bc
	push hl
	xor a
	ld [wFadeOn], a
	ld [wDrumsOn], a
	ld [wNoiseOn], a
	ld h, $C4
	call ResetChannel
	inc h
	call ResetChannel
	inc h
	call ResetChannel
	inc h
	call ResetChannel
	xor a
	ld [wTranspose], a
	xor a
	ldh [rNR42], a
	pop hl
	pop bc
	pop de
	pop af
	ret

; Cmd_End ($66): centre pan, reload the music wave if this is the SFX page, reset the page.
Cmd_End:
	pop af
	call Cmd_PanC
	ld a, h
	cp $C7
	jr nz, ResetChannel
	call RestoreMusicWave

; ResetChannel (h = page): clear the page and write NRx2 = 0 / NRx4 = $80.
; The test at $584A-$5853 was meant to skip the write on the SFX page while Ch3
; plays, but "ld a,[hl]" sets no flags: Z still holds "h = $C7", so it never skips.
; Resetting Ch3 or Sfx bumps wShNR32 (so the next CH3 volume write isn't skipped).
ResetChannel:
	xor a
	ld l, $10
	ld [hl], a
	ld l, $0B
	ld [hl], a
	ld l, $04
	ld [hl], a
	ld l, $0E
	ld [hl], a
	ld l, $2E
	ld [hl], a
	ld l, $2B
	ld [hl], a
	ld l, $0F
	ld [hl], a
	ld l, $05
	ld [hl], $01
	ld l, $31
	ld [hl], a
	inc l
	ld [hl], $01
	ld l, $3B
	ld [hl], a
	ld a, h
	cp $C7
	jr nz, L5859
	dec h
	ld l, $10
	ld a, [hl]
	jr z, L5858
	inc h
	jr L5865
L5858:
	inc h
L5859:
	xor a
	ld l, $0A
	ld c, [hl]
	ld b, $FF
	ld [bc], a
	inc c
	inc c
	or $80
	ld [bc], a
L5865:
	ld a, h
	cp $C7
	jr z, L586E
	ld a, h
	cp $C6
	ret nz
L586E:
	ld a, [wShNR32]
	inc a
	ld [wShNR32], a
	ret
Cmd_Transpose:
	ld a, [de]
	ld [wTranspose], a
	inc de
	ret
Cmd_OrderJump:
	ld l, $00
	push hl
	push de
	pop hl
	pop de
	rst $20
	rst $20
	push hl
	push de
	pop hl
	pop de
Cmd_Next:
	ld l, $3B
	ld a, [hl]
	and a
	jp nz, PatReturn
	ld l, $00
	ld c, [hl]
	inc l
	ld b, [hl]
	ld a, [bc]
	ld e, a
	inc bc
	ld a, [bc]
	inc bc
	ld d, a
	or e
	jr z, Next_OrderEnd
	ld [hl], b
	dec l
	ld [hl], c
	inc l
	inc l
	ld [hl], e
	inc l
	ld [hl], d
	ret
Next_OrderEnd:
	ld d, b
	ld e, c
	pop bc
	ld a, $69
	jp StreamCommand
Cmd_Length:
	ld a, [de]
	ld l, $0D
	ld [hl], a
	inc de
	ret
L58B4:
	inc de
	xor a
	ld [wDrumsOn], a
	ret
Cmd_Drums:
	ld a, [de]
	and a
	jr z, L58B4
	ld [wDrumTempo], a
	inc de
	ld a, [de]
	ld [wDrumPatLo], a
	inc de
	ld a, [de]
	ld [wDrumPatHi], a
	inc de
	xor a
	ld [wDrumPos], a
	ld a, $01
	ld [wDrumsOn], a
	ld a, $01
	ld [wDrumTimer], a
	ret

; DrumStep: next byte of the drum pattern: $FF loops, 0 = nothing,
; 1-7 = drum sounds (1-3 noise sequences, 4-7 single noise hits).
DrumStep:
	ld a, [wDrumsOn]
	and a
	ret z
	push hl
	push de
	ld a, [wDrumTempo]
	ld [wDrumTimer], a
	ld a, [wDrumPatHi]
	ld h, a
	ld a, [wDrumPatLo]
	ld l, a
	ld a, [wDrumPos]
	ld e, a
	ld d, $00
	add hl, de
	inc a
	ld [wDrumPos], a
	ld a, [hl]
	pop de
	pop hl
	cp $FF
	jr z, DrumLoop
	ret z
	dec a
	jp z, Drum1_NoiseSeq1
	dec a
	jp z, Cmd_NoiseSeq2
	dec a
	jp z, Cmd_NoiseSeq3
	dec a
	jp z, Drum4
	dec a
	jp z, Drum5
	dec a
	jp z, Drum6
	dec a
	jp z, Cmd_NoiseHit7
	ret
DrumLoop:
	xor a
	ld [wDrumPos], a
	jp DrumStep

; NoiseSeqTick: one step per tick of a noise sequence (NR43 / NR42 pairs,
; $FF ends), NR44 = $80 each step.
NoiseSeqTick:
	ld a, [wNoiseOn]
	and a
	ret z
	push hl
	push de
	ld a, [wNoiseNR43Hi]
	ld h, a
	ld a, [wNoiseNR43Lo]
	ld l, a
	ld a, [wNoisePos]
	ld e, a
	ld d, $00
	add hl, de
	ld a, [hl]
	cp $FF
	jr z, L595E
	ldh [rNR43], a
	ld a, [wNoiseNR42Hi]
	ld h, a
	ld a, [wNoiseNR42Lo]
	ld l, a
	add hl, de
	ld a, [hl]
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	pop de
	pop hl
	ld a, [wNoisePos]
	inc a
	ld [wNoisePos], a
	ret
L595E:
	pop de
	pop hl
	xor a
	ld [wNoisePos], a
	ld [wNoiseOn], a
	ret
NoiseSeq1_NR43:
	db $00, $51, $61, $71, $91, $71, $60, $FF
NoiseSeq1_NR42:
	db $F0, $F0, $D0, $90, $80, $50, $23
NoiseSeq2_NR43:
	db $60, $52, $42, $41, $12, $11, $03, $FF
NoiseSeq2_NR42:
	db $F0, $E0, $D0, $B0, $A0, $90, $81
NoiseSeq3_NR43:
	db $07, $16, $FF
NoiseSeq3_NR42:
	db $F0, $A1

; Unused (looks like a 4th noise sequence: NR43 07 03 00 FF, NR42 70 60 41).
NoiseSeq4_unused:
	db $07, $03, $00, $FF, $70, $60, $41
Drum1_NoiseSeq1:
	ld a, $01
	ld [wNoiseOn], a
	ld a, HIGH(NoiseSeq1_NR43)
	ld [wNoiseNR43Hi], a
	ld a, LOW(NoiseSeq1_NR43)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(NoiseSeq1_NR42)
	ld [wNoiseNR42Hi], a
	ld a, LOW(NoiseSeq1_NR42)
	jr L59C0
Cmd_NoiseSeq2:
	ld a, $01
	ld [wNoiseOn], a
	ld a, HIGH(NoiseSeq2_NR43)
	ld [wNoiseNR43Hi], a
	ld a, LOW(NoiseSeq2_NR43)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(NoiseSeq2_NR42)
	ld [wNoiseNR42Hi], a
	ld a, LOW(NoiseSeq2_NR42)
L59C0:
	ld [wNoiseNR42Lo], a
	xor a
	ld [wNoisePos], a
	ret
Cmd_NoiseSeq3:
	ld a, $01
	ld [wNoiseOn], a
	ld a, HIGH(NoiseSeq3_NR43)
	ld [wNoiseNR43Hi], a
	ld a, LOW(NoiseSeq3_NR43)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(NoiseSeq3_NR42)
	ld [wNoiseNR42Hi], a
	ld a, LOW(NoiseSeq3_NR42)
	jr L59C0
Drum4:
	xor a
	ldh [rNR41], a
	ld a, $A2
	ldh [rNR42], a
	ld a, $03
	jr NoiseTrigger
Drum5:
	xor a
	ldh [rNR41], a
	ld a, $C1
	ldh [rNR42], a
	ld a, $00
	jr NoiseTrigger
Drum6:
	ld a, $40
	ldh [rNR41], a
	ld a, $D1
	ldh [rNR42], a
	ld a, $01
	jr NoiseTrigger
Cmd_NoiseHit7:
	ld a, $3A
	ldh [rNR41], a
	ld a, $F1
	ldh [rNR42], a
	ld a, $00
	ldh [rNR43], a
	ld a, $C0
	ldh [rNR44], a
	ret
NoiseTrigger:
	ldh [rNR43], a
	ld a, $80
	ldh [rNR44], a
	ret
Cmd_PanC:
	ld bc, $FF11
	jr SetPan
Cmd_PanR:
	ld bc, $EF01
	jr SetPan
Cmd_PanL:
	ld bc, $FE10
SetPan:
	ld a, h
	cp $C5
	jr z, L5A3E
	cp $C6
	jr z, L5A49
	cp $C7
	ret z
	ld a, [wShNR51]
	or c
	and b
L5A38:
	ld [wShNR51], a
	ldh [rNR51], a
	ret
L5A3E:
	rlc b
	rlc c
	ld a, [wShNR51]
	or c
	and b
	jr L5A38
L5A49:
	rlc b
	rlc b
	rlc c
	rlc c
	ld a, [wShNR51]
	or c
	and b
	jr L5A38
Cmd_Duty50:
	ld c, $80
	jr SetDuty
Cmd_Duty75:
	ld c, $C0
	jr SetDuty
Cmd_Duty12:
	ld c, $00
SetDuty:
	ld a, h
	cp $C5
	jr z, L5A70
	cp $C4
	jr z, L5A6C
	ret
L5A6C:
	ld a, c
	ldh [rNR11], a
	ret
L5A70:
	ld a, c
	ldh [rNR21], a
	ret

; Cmd_HwEnv ($72): hardware envelope mode: env is written to NRx2 at note on;
; optionally after `ticks` ticks env2 is written.
Cmd_HwEnv:
	ld a, [de]
	ld l, $31
	ld [hl], a
	inc l
	ld [hl], $01
	ld l, $27
	ld [hl], a
	inc de
	ld a, [de]
	and a
	jr z, L5A8E
	ld l, $28
	ld [hl], a
	inc l
	ld [hl], a
	inc de
	ld a, [de]
	inc l
	ld [hl], a
	inc de
	ret
L5A8E:
	ld l, $28
	ld [hl], a
	inc l
	ld [hl], a
	inc de
	ret
HwEnvNoteOn:
	ld l, $27
	ld a, [hl]
	and a
	ret z
	ld l, $27
	ld a, [hl]
	ld l, $31
	ld [hl], a
	inc l
	ld [hl], $01
	ld l, $28
	ld a, [hli]
	ld [hl], a
	ret

; Cmd_AutoPan ($73 n): every n ticks cycle the pan C, R, C, L.
Cmd_AutoPan:
	ld a, [de]
	inc de
	ld l, $2B
	ld [hl], a
	inc l
	ld [hl], a
	inc l
	xor a
	ld [hl], a
	ret
DoAutoPan:
	ld l, $2B
	ld a, [hl]
	and a
	ret z
	ld l, $2C
	ld a, [hl]
	dec a
	jr z, L5AC0
	ld [hl], a
	ret
L5AC0:
	ld l, $2B
	ld a, [hli]
	ld [hli], a
	ld a, [hl]
	inc a
	ld [hl], a
	dec a
	jp z, Cmd_PanC
	dec a
	jp z, Cmd_PanR
	dec a
	jp z, Cmd_PanC
	dec a
	jp z, Cmd_PanL
	ld a, $01
	ld [hl], a
	jp Cmd_PanC

; Cmd_AutoDuty ($74 n): every n ticks cycle the duty 75, 12.5, 75, 50 %.
Cmd_AutoDuty:
	ld a, [de]
	inc de
	ld l, $2E
	ld [hl], a
	inc l
	ld [hl], a
	inc l
	xor a
	ld [hl], a
	ret
DoAutoDuty:
	ld l, $2E
	ld a, [hl]
	and a
	ret z
	ld l, $2F
	ld a, [hl]
	dec a
	jr z, L5AF5
	ld [hl], a
	ret
L5AF5:
	ld l, $2E
	ld a, [hli]
	ld [hli], a
	ld a, [hl]
	inc a
	ld [hl], a
	dec a
	jp z, Cmd_Duty75
	dec a
	jp z, Cmd_Duty12
	dec a
	jp z, Cmd_Duty75
	ld a, $01
	ld [hl], a
	jp Cmd_Duty50

; StartFade (a = speed, hl = NR50 table): one table byte every speed+1 ticks,
; $68 loops, $FF ends. While no fade runs (and hGameFF99 = 0) NR50 is forced back
; to $77 every tick unless it is 0.
StartFade:
	ld [wFadeSpeed], a
	ld a, l
	ld [wFadePtr], a
	ld a, h
	ld [wFadePtrHi], a
	jr L5B1B
L5B1B:
	xor a
	ld [wFadePos], a
	ld [wFadeTimer], a
	inc a
	ld [wFadeOn], a
	ret
FadeEnd:
	xor a
	ld [wFadeOn], a
	ret
DoFade:
	ldh a, [hGameFF99]
	and a
	ret nz
	ld a, [wFadeOn]
	and a
	jr nz, L5B3F
	ldh a, [rNR50]
	and a
	ret z
	ld a, $77
	ldh [rNR50], a
	ret
L5B3F:
	ld a, [wFadeTimer]
	and a
	jr z, FadeStep
	dec a
	ld [wFadeTimer], a
	ret
FadeStep:
	ld a, [wFadePtr]
	ld l, a
	ld a, [wFadePtrHi]
	ld h, a
	ld a, [wFadePos]
	rst $18
	ld a, [hl]
	cp $68
	jr z, L5B6F
	cp $FF
	jr z, FadeEnd
	ldh [rNR50], a
	ld a, [wFadePos]
	inc a
	ld [wFadePos], a
	ld a, [wFadeSpeed]
	ld [wFadeTimer], a
	ret
L5B6F:
	xor a
	ld [wFadePos], a
	jr FadeStep
FadeOutTable:
	db $77, $66, $55, $44, $33, $22, $11, $00, $FF

; Cmd_Wave ($75 w): Ch3: remember the wave, load it unless the SFX page is playing.
; SFX page: load it. The load turns the DAC off, copies 16 bytes, and restarts
; CH3 with wShFreqHi3 | $80.
Cmd_Wave:
	ld a, h
	cp $C6
	jr nz, LoadWave
	ld a, [de]
	ld [wMusicWave], a
	inc de
	ld a, [de]
	ld [wMusicWaveHi], a
	inc h
	ld l, $10
	ld a, [hl]
	dec h
	and a
	jr z, L5B96
	inc de
	ret
L5B96:
	dec de
LoadWave:
	push bc
	push hl
	xor a
	ldh [rNR30], a
	ld c, $30
	ld a, [de]
	ld l, a
	inc de
	ld a, [de]
	ld h, a
	inc de
	ld b, $10
L5BA6:
	ld a, [hli]
	ldh [c], a
	inc c
	dec b
	jr nz, L5BA6
	pop hl
	pop bc
	ld a, [wShFreqHi3]
	or $80
	ldh [rNR30], a
	ldh [rNR34], a
	ret
RestoreMusicWave:
	push bc
	push hl
	xor a
	ldh [rNR30], a
	ld c, $30
	ld a, [wMusicWave]
	ld l, a
	ld a, [wMusicWaveHi]
	ld h, a
	ld b, $10
L5BC9:
	ld a, [hli]
	ldh [c], a
	inc c
	dec b
	jr nz, L5BC9
	pop hl
	pop bc
	dec h
	ld l, $0B
	ld a, [hl]
	ldh [rNR32], a
	inc h
	ld a, [wShFreqHi3]
	or $80
	ldh [rNR30], a
	ldh [rNR34], a
	ret

; SndInit: copy the register indices into the pages, clear the rest, NR51 = $FF, StopAll.
SndInit:
	ld hl, ChInit1
	ld de, wCh1
	ld bc, $000C
	rst $00
	call ClearChannelRest
	ld hl, ChInit2
	ld de, wCh2
	ld bc, $000C
	rst $00
	call ClearChannelRest
	ld hl, ChInit3
	ld de, wCh3
	ld bc, $000C
	rst $00
	call ClearChannelRest
	ld hl, ChInit3
	ld de, wSfx
	ld bc, $000C
	rst $00
	call ClearChannelRest
	ld a, $FF
	ldh [rNR51], a
	ld [wShNR51], a
	call StopAll
	ret
ClearChannelRest:
	ld l, e
	ld h, d
	dec hl
	ld bc, $0031
	rst $00
	ret

; Period table: 81 entries from C2 (same as version 1).
PeriodTable:
	dw $002D
	dw $009D
	dw $0107
	dw $016B
	dw $01CA
	dw $0223
	dw $0277
	dw $02C7
	dw $0312
	dw $0359
	dw $039C
	dw $03DB
	dw $0417
	dw $044F
	dw $0484
	dw $04B6
	dw $04E5
	dw $0512
	dw $053C
	dw $0564
	dw $0589
	dw $05AD
	dw $05CE
	dw $05EE
	dw $060C
	dw $0628
	dw $0642
	dw $065B
	dw $0673
	dw $0689
	dw $069E
	dw $06B2
	dw $06C5
	dw $06D7
	dw $06E7
	dw $06F7
	dw $0706
	dw $0714
	dw $0721
	dw $072E
	dw $073A
	dw $0745
	dw $074F
	dw $0759
	dw $0763
	dw $076C
	dw $0774
	dw $077C
	dw $0783
	dw $078A
	dw $0791
	dw $0797
	dw $079D
	dw $07A3
	dw $07A8
	dw $07AD
	dw $07B2
	dw $07B6
	dw $07BA
	dw $07BE
	dw $07C2
	dw $07C5
	dw $07C9
	dw $07CC
	dw $07CF
	dw $07D2
	dw $07D4
	dw $07D7
	dw $07D9
	dw $07DB
	dw $07DD
	dw $07DF
	dw $07E1
	dw $07E3
	dw $07E5
	dw $07E6
	dw $07E2
	dw $07E9
	dw $07EA
	dw $07EC
	dw $07ED

; DoArp: next arpeggio table entry added to the note; $68 restarts, $FF holds.
DoArp:
	ld l, $04
	bit 0, [hl]
	ret z
L5CD0:
	ld l, $1F
	ld a, [hli]
	ld b, [hl]
	inc l
	add a, [hl]
	ld c, a
	jr nc, L5CDA
	inc b
L5CDA:
	ld a, [bc]
	cp $68
	jr nz, L5CE3
	ld [hl], $00
	jr L5CD0
L5CE3:
	cp $FF
	jr nz, L5CEA
	dec [hl]
	jr L5CD0
L5CEA:
	inc [hl]
	ld l, $0C
	add a, [hl]

; SetNoteFreq (a = note): index = note - 12 + wTranspose (not on the SFX page) +
; field $0F (channel transpose) -> PeriodTable.
SetNoteFreq:
	add a, $F4
	ld c, a
	push af
	ld a, h
	cp $C7
	jr nz, L5CFA
	pop af
	jr L5CFF
L5CFA:
	pop af
	ld a, [wTranspose]
	add a, c
L5CFF:
	ld l, $0F
	ld c, [hl]
	add a, c
	add a, a
	add a, LOW(PeriodTable)
	ld c, a
	adc a, HIGH(PeriodTable)
	sub c
	ld b, a
	push de
	ld a, [bc]
	inc bc
	ld e, a
	ld a, [bc]
	ld d, a
	ld l, $07
	ld [hl], e
	inc l
	inc l
	ld [hl], d
	pop de
	ret

; DoEnvelope: hardware mode: count down field $29 then write env2. Software mode:
; attack ($12/$13/$1A/$1B), decay ($15/$16/$1C/$1D), release ($19/$18/$1E/$1F).
DoEnvelope:
	ld l, $27
	ld a, [hl]
	and a
	jr z, L5D30
	ld l, $29
	ld a, [hl]
	and a
	ret z
	dec a
	ld [hl], a
	ret nz
	ld l, $2A
	ld a, [hl]
	ld l, $31
	ld [hli], a
	ld [hl], $01
	ret
L5D30:
	ld l, $12
	ld a, [hl]
	or a
	jr z, L5D4F
	ld l, $1A
	dec [hl]
	ret nz
	inc l
	ld a, [hld]
	ld [hl], a
	ld l, $12
	dec [hl]
	inc l
	ld a, [hl]
	ld l, $0B
	add a, [hl]
	cp $0F
	jr nc, L5D4B
L5D49:
	ld [hl], a
	ret
L5D4B:
	ld a, $0F
	jr L5D49
L5D4F:
	ld l, $15
	ld a, [hl]
	or a
	jr z, L5D6C
	ld l, $1C
	dec [hl]
	ret nz
	inc l
	ld a, [hld]
	ld [hl], a
	ld l, $15
	dec [hl]
	ld l, $0B
	ld a, [hl]
	ld l, $16
	sub [hl]
	jr nc, L5D68
	xor a
L5D68:
	ld l, $0B
	ld [hl], a
	ret
L5D6C:
	ld l, $19
	ld a, [hl]
	or a
	ret z
	ld l, $1E
	dec [hl]
	ret nz
	inc l
	ld a, [hld]
	ld [hl], a
	ld l, $0B
	ld a, [hl]
	ld l, $18
	sub [hl]
	jr nc, L5D81
	xor a
L5D81:
	ld l, $0B
	ld [hl], a
	ret

; StartMusicChN (de = order list).
StartMusicCh1:
	ld h, $C4
	jr StartMusicCh
StartMusicCh2:
	ld h, $C5
	jr StartMusicCh
StartMusicCh3:
	ld h, $C6
StartMusicCh:
	call ResetChannel
	ld l, $10
	ld [hl], $01
	ld l, $02
	ld a, [de]
	ld [hl], a
	inc de
	ld a, [de]
	inc l
	ld [hl], a
	ld l, $00
	inc de
	ld [hl], e
	inc l
	ld [hl], d
	ret

; OutputAll: Ch1, Ch2, then the SFX page if active, else Ch3 - all to the register
; addresses in fields $06/$08/$0A (CH1/CH2/CH3 only).
OutputAll:
	ld h, $C4
	call OutputChannel
	ld h, $C5
	call OutputChannel
	ld h, $C7
	ld l, $10
	ld a, [hl]
	and a
	jr nz, OutputChannel
	ld h, $C6

; OutputChannel: NRx3 = period lo; NRx4 = period hi (no trigger) when it changed
; (shadow wShFreqHi + page - $C4; the SFX page uses wShNR32 as its shadow!).
; Software volume: pulse channels get NRx2 = vol << 4 and a retrigger on EVERY tick;
; CH3 gets NR32 from Ch3VolTable when it changed. Hardware envelope: NRx2 and a
; trigger only when field $32 is set.
OutputChannel:
	ld l, $10
	ld a, [hl]
	and a
	ret z
	ld l, $06
	ld c, [hl]
	inc l
	ld a, [hli]
	ld b, $FF
	ld [bc], a
	ld c, [hl]
	inc l
	ld a, [hli]
	and $07
	ld b, a
	push hl
	push de
	ld a, h
	sub $C4
	ld d, $00
	ld e, a
	ld hl, wShFreqHi
	add hl, de
	pop de
	ld a, [hl]
	cp b
	jr z, L5DE2
	ld a, b
	ld b, $FF
	ld [bc], a
	ld [hl], a
L5DE2:
	pop hl
	ld a, [hli]
	ld c, [hl]
	push af
	ld l, $27
	ld a, [hl]
	and a
	jr nz, L5DF1
	pop af
	call WriteVolume
	ret
L5DF1:
	pop af
	push de
	ld d, $FF
	ld e, a
	ld l, $32
	ld a, [hl]
	and a
	jr z, L5E17
	ld [hl], $00
	dec l
	ld a, [hl]
	ld [de], a
	pop de
	ld a, h
	cp $C4
	jr nz, L5E0F
	ld a, [wShFreqHi]
	or $80
	ldh [rNR14], a
	ret
L5E0F:
	ld a, [wShFreqHi2]
	or $80
	ldh [rNR24], a
	ret
L5E17:
	pop de
	ret
WriteVolume:
	cp $1C
	jr z, WriteCh3Vol
	push hl
	ld h, $FF
	ld l, a
	ld a, c
	and $0F
	swap a
	ld [hl], a
	pop hl
	ld a, h
	cp $C4
	jr nz, WriteVolume_Ch2
	ld a, [wShFreqHi]
	or $80
	ldh [rNR14], a
	ret
WriteVolume_Ch2:
	ld a, [wShFreqHi2]
	or $80
	ldh [rNR24], a
	ret

; Dead bytes (pop hl / ret).
Unused_5E3D:
	db $E1, $C9
WriteCh3Vol:
	push hl
	ld a, c
	and $0F
	add a, LOW(Ch3VolTable)
	ld l, a
	adc a, HIGH(Ch3VolTable)
	sub l
	ld h, a
	ld c, [hl]
	ld a, [wShNR32]
	cp c
	jr z, L5E57
	ld a, c
	ld [wShNR32], a
	ldh [rNR32], a
L5E57:
	pop hl
	ret
Ch3VolTable:
	db $00, $00, $00, $00, $60, $60, $60, $60, $40, $40, $40, $40, $20, $20, $20, $20

; PlaySfx (a = id 1-14): lower ids have priority (a request is ignored while a
; lower id plays). Ids 1 and 4 pan with NR50 by an object position when hGameFF82 != 0;
; ids $0B, $0C, $0E (and 1/4 when hGameFF82 = 0) set NR50 = $77. The stream starts
; on the SFX page and its first tick is parsed inside the call.
PlaySfx:
	push af
	push de
	push bc
	push hl
	ld b, a
	ld a, [wSfxId]
	and a
	jr z, L5E77
	cp b
	jr c, PlaySfx_Done
L5E77:
	ld a, b
	push af
	cp $0B
	jr z, L5EB2
	cp $0C
	jr z, L5EB2
	cp $0E
	jr z, L5EB2
	cp $01
	jr z, L5E8F
	cp $04
	jr z, L5E8F
	jr L5E98
L5E8F:
	ldh a, [hGameFF82]
	and a
	jr z, L5EB2
	ldh a, [hGameFFC0]
	jr L5EA0
L5E98:
	ldh a, [hGameFF82]
	and a
	jr z, L5EB6
	ld a, [wGameC001]
L5EA0:
	srl a
	srl a
	srl a
	ld hl, StereoNR50Table
	ld d, $00
	ld e, a
	add hl, de
	ld a, [hl]
	ldh [rNR50], a
	jr L5EB6
L5EB2:
	ld a, $77
	ldh [rNR50], a
L5EB6:
	ld hl, wSfxId
	ld a, [hl]
	and a
	call nz, ResetChannel
	pop af
	ld l, $10
	ld [hl], a
	ld de, wSfxPtr
	add a, a
	add a, LOW(SfxTable - 2)
	ld l, a
	adc a, HIGH(SfxTable - 2)
	sub l
	ld h, a
	rst $20
	push hl
	push de
	pop hl
	pop de
	ld a, [de]
	ld [hl], a
	ld d, a
	dec l
	ld e, [hl]
	call ReadStream
PlaySfx_Done:
	pop hl
	pop bc
	pop de
	pop af
	ret

; Wave tables (16 bytes each).
Wave_5EDF:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
Wave_5EEF:
	db $00, $00, $00, $FF, $FF, $FF, $FF, $FF
	db $00, $00, $00, $FF, $FF, $FF, $FF, $FF
Wave_5EFF:
	db $12, $34, $56, $78, $9A, $BC, $DE, $FE
	db $DC, $BA, $98, $76, $54, $32, $10, $00
Wave_5F0F:
	db $02, $46, $8A, $BD, $FD, $BA, $64, $20
	db $02, $46, $8A, $BD, $FD, $BA, $64, $20
Wave_5F1F:
	db $FF, $00, $FF, $00, $FF, $00, $FF, $00
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

; NR50 values by position for the panned SFX (left .. right).
StereoNR50Table:
	db $71, $71, $72, $72, $73, $74, $75, $76, $77, $67, $57, $47, $37, $27, $27, $17
	db $17, $66

; Sound table: ids 1-14 (code reads SfxTable - 2 + 2*id).
SfxTable:
	dw Sfx01
	dw Sfx02
	dw Sfx03
	dw Sfx04
	dw Sfx05
	dw Sfx06
	dw Sfx07
	dw Sfx08
	dw Sfx09
	dw Sfx0A
	dw Sfx0B
	dw Sfx0C
	dw Sfx0D
	dw Sfx0E
Sfx0B:
	LEN 6
	WAVE Wave_5EDF
	VOLENV 15, $16, $1F, $11
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	WAIT
	WAIT
	WAIT
	END
Sfx0C:
	LEN 7
	VOLENV 10, $11, $1F, $11
	WAVE Wave_5F1F
	NOTE C_, 7
	END
Sfx08:
	VOLENV 13, $11, $1F, $11
	WAVE Wave_5EDF
	GLIDE $FC
	LEN 4
	NOTE C_, 5
	GLIDE $05
	NOTE C_, 3
	WAIT
	VOLENV 5, $11, $1F, $14
	GLIDE $FC
	LEN 4
	NOTE C_, 5
	GLIDE $05
	NOTE C_, 3
	WAIT
	END
Sfx0A:
	VOLENV 15, $11, $1F, $14
	WAVE Wave_5EDF
	GLIDE $FF
	GLIDE $01
	LEN 14
	NOTE C_, 4
	WAIT
	END
Sfx09:
	VOLENV 15, $11, $1F, $11
	WAVE Wave_5EDF
	GLIDE $FF
	GLIDE $FF
	LEN 3
	NOTE C_, 5
	END
Sfx07:
	VOLENV 13, $11, $1F, $11
	WAVE Wave_5EEF
	ARP 3
	GLIDE $FC
	LEN 4
	NOTE C_, 6
	GLIDE $05
	NOTE C_, 4
	WAIT
	VOLENV 5, $11, $1F, $14
	GLIDE $FC
	LEN 4
	NOTE C_, 6
	GLIDE $05
	NOTE C_, 4
	WAIT
	END
Sfx03:
	VOLENV 15, $00, $00, $00
	WAVE Wave_5EDF
	ARP 4
	LEN 6
	NOTE C_, 5
	VOL 13
	NOTE E_, 5
	VOL 11
	NOTE G_, 5
	VOL 10
	NOTE B_, 5
	VOL 8
	NOTE D_, 6
	VOL 6
	NOTE F_, 6
	VOL 4
	NOTE A_, 6
	VOL 3
	NOTE C_, 7
	END
Sfx0E:
	LEN 5
	VOLENV 15, $00, $00, $00
	WAVE Wave_5EEF
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	VOL 10
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	VOL 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	VOL 1
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	END
Sfx0D:
	LEN 5
	VOLENV 15, $11, $1F, $11
	WAVE Wave_5EDF
	GLIDE $FF
	NOTE A_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	END
Sfx02:
	VOLENV 15, $11, $23, $11
	LEN 5
	ARP 3
	WAVE Wave_5EDF
	NOTE G_, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE B_, 4
	NOTE D_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE G_, 5
	NOTE B_, 5
	NOTE G_, 5
	NOTE B_, 5
	NOTE D_, 6
	NOTE G_, 6
	WAIT
	WAIT
	END
Sfx01:
	VOLENV 15, $11, $1F, $15
	WAVE Wave_5F1F
	LEN 4
	GLIDE $FE
	NOTE C_, 5
	GLIDE $02
	WAIT
	GLIDE $00
	VIBRATO $00, $0A, $04
	LEN 20
	WAIT
	END
Sfx05:
	VOLENV 15, $11, $1F, $12
	WAVE Wave_5EDF
	LEN 20
	VIBRATO $00, $03, $04
	ARP 2
	NOTE A_, 5
	END
Sfx06:
	VOLENV 15, $11, $1F, $15
	WAVE Wave_5EDF
	LEN 20
	GLIDE $01
	ARP 2
	NOTE C_, 5
	END
Sfx04:
	VOLENV 15, $11, $1F, $11
	WAVE Wave_5EEF
	ARP 3
	LEN 5
	NOTE C_, 5
	NOTE G_, 5
	NOTE E_, 5
	END

; Channel init blocks copied to fields $00-$0B: fields $06/$08/$0A = register
; addresses of NRx3/NRx4/NRx2. Ch3's block is used for the SFX page too.
ChInit1:
	db $00, $00, $00, $00, $00, $00, $13, $00, $14, $00, $12, $00
ChInit2:
	db $00, $00, $00, $00, $00, $00, $18, $00, $19, $00, $17, $00
ChInit3:
	db $00, $00, $00, $00, $00, $00, $1D, $00, $1E, $00, $1C, $00

; Shared tail of PlaySong1-4: instrument table 1, arpeggio table 1, NR50 = $77.
SetSongTables:
	ld a, LOW(InstrTable1 - 2)
	ld [wInstrTable], a
	ld a, HIGH(InstrTable1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(ArpTable1)
	ld [wArpTable], a
	ld a, HIGH(ArpTable1)
	ld [wArpTableHi], a
	ld a, $77
	ldh [rNR50], a
	pop hl
	pop bc
	pop de
	ret
Drums_60A9:
	db $00
	db $00
	db $05
	db $00
	db $01
	db $00
	db $05
	db $00
	db DRUM_LOOP
Drums_60B2:
	db $01
	db $00
	db $05
	db $00
	db $01
	db $00
	db $05
	db $00
	db $01
	db $00
	db $05
	db $00
	db $01
	db $00
	db $05
	db $00
	db $01
	db $00
	db $05
	db $00
	db $01
	db $00
	db $05
	db $00
	db $01
	db $00
	db $01
	db $01
	db $01
	db $00
	db $05
	db $01
	db DRUM_LOOP
Drums_60D3:
	db $01
	db $00
	db $05
	db $00
	db $02
	db $00
	db $05
	db $00
	db DRUM_LOOP
Drums_60DC:
	db $01
	db $05
	db $05
	db $01
	db $01
	db $05
	db $05
	db $01
	db $05
	db $01
	db $05
	db $01
	db $01
	db $05
	db $05
	db $05
	db DRUM_LOOP
Drums_60ED:
	db $01
	db $05
	db $01
	db $05
	db DRUM_LOOP

; Song entry points used by the game.
JpPlaySong4:
	jp PlaySong4
JpPlaySong3:
	jp PlaySong3
JpPlaySong2:
	jp PlaySong2

; PlaySong1: StopAll (twice); the channels only start while hGameFF82 = 0.
PlaySong1:
	push de
	push bc
	push hl
	call StopAll
	ldh a, [hGameFF82]
	and a
	jr nz, L611B
	call StopAll
	ld de, Song1_Ch3
	call StartMusicCh3
	ld de, Song1_Ch1
	call StartMusicCh1
	ld de, Song1_Ch2
	call StartMusicCh2
L611B:
	jp SetSongTables
Song1_Ch3:
	dw Pat_615C
Ord_6120:
	dw Pat_623F
	dw Pat_623F
	dw Pat_633C
	dw Pat_633C
	dw Pat_633C
	dw Pat_633C
	dw Pat_638C
	dw Pat_638C
	ORDER_LOOP Ord_6120
Song1_Ch1:
	dw Pat_61A9
Ord_6136:
	dw Pat_6288
	dw Pat_6288
	dw Pat_634D
	dw Pat_634D
	dw Pat_634D
	dw Pat_634D
	dw Pat_63CD
	dw Pat_63CD
	ORDER_LOOP Ord_6136
Song1_Ch2:
	dw Pat_61F0
Ord_614C:
	dw Pat_62EE
	dw Pat_62EE
	dw Pat_6366
	dw Pat_6366
	dw Pat_61F0
	dw Pat_61F0
	ORDER_LOOP Ord_614C
Pat_615C:
	PAN_C
	LEN 10
	VOLENV 10, $11, $1F, $11
	WAVE Wave_5EDF
	ARP 2
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	ARP 1
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	WAIT
	ARP 2
	NOTE Gsh, 4
	WAIT
	NOTE Gsh, 4
	WAIT
	NOTE Gsh, 4
	WAIT
	NOTE Gsh, 4
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE Ash, 4
	WAIT
	NEXT
Pat_61A9:
	LEN 10
	INSTR 2
	DRUMS $0A, Drums_60ED
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE Ash, 2
	NOTE Ash, 3
	NEXT
Pat_61F0:
	PAN_C
	AUTODUTY $00
	PAN_C
	LEN 10
	DUTY_50
	HWENV $93, $00
	ARP 0
	VIBRATO $0A, $01, $05
	NOTE Ash, 3
	NOTE Ash, 3
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE Ash, 4
	WAIT
	NOTE Gsh, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE F_, 4
	NOTE C_, 4
	NOTE C_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE Ash, 4
	WAIT
	NOTE Gsh, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE D_, 4
	NOTE D_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Dsh, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE Ash, 4
	NOTE D_, 5
	NOTE D_, 5
	WAIT
	NOTE Gsh, 5
	WAIT
	NOTE G_, 5
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE F_, 5
	WAIT
	WAIT
	WAIT
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NEXT
Pat_623F:
	ARP 0
	VOLENV 10, $11, $1F, $11
	WAVE Wave_5F0F
	NOTE Dsh, 5
	NOTE Ash, 5
	NOTE Dsh, 6
	NOTE Dsh, 5
	NOTE Ash, 5
	NOTE D_, 6
	NOTE Dsh, 5
	NOTE Ash, 5
	NOTE C_, 6
	NOTE Dsh, 5
	NOTE Gsh, 5
	NOTE Ash, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE Dsh, 5
	NOTE Ash, 5
	NOTE Dsh, 6
	NOTE Dsh, 5
	NOTE Ash, 5
	NOTE D_, 6
	NOTE Dsh, 5
	NOTE Ash, 5
	NOTE C_, 6
	NOTE Dsh, 5
	NOTE Gsh, 5
	NOTE Ash, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE C_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE C_, 5
	NOTE G_, 5
	NOTE Ash, 5
	NOTE C_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE C_, 5
	NOTE G_, 5
	NOTE Ash, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE Ash, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE Ash, 5
	NOTE D_, 6
	NOTE Dsh, 6
	NOTE D_, 6
	NOTE Ash, 5
	NEXT
Pat_6288:
	DRUMS $0A, Drums_60DC
	INSTR 2
	NOTE Dsh, 2
	NOTE Dsh, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Gsh, 2
	WAIT
	NOTE Gsh, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Gsh, 2
	NOTE Ash, 2
	NOTE Ash, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Ash, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Gsh, 2
	WAIT
	NOTE Gsh, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Gsh, 2
	NOTE Ash, 2
	NOTE Ash, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Ash, 3
	NOTE C_, 3
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE C_, 3
	WAIT
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Ash, 3
	NOTE Gsh, 2
	NOTE Gsh, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Ash, 2
	WAIT
	NOTE Ash, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Ash, 3
	NEXT
Pat_62EE:
	AUTODUTY $02
	HWENV $D1, $0A, $20
	VIBRATO $0A, $02, $04
	ARP 2
	NOTE Dsh, 4
	WAIT
	WAIT
	NOTE Dsh, 4
	NOTE Dsh, 4
	WAIT
	WAIT
	NOTE Gsh, 4
	WAIT
	NOTE Gsh, 4
	WAIT
	NOTE Ash, 4
	NOTE Ash, 4
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 4
	WAIT
	WAIT
	NOTE Dsh, 4
	NOTE Dsh, 4
	WAIT
	WAIT
	NOTE Gsh, 4
	WAIT
	NOTE Gsh, 4
	WAIT
	NOTE Ash, 4
	NOTE Ash, 4
	WAIT
	NOTE Ash, 4
	WAIT
	ARP 1
	NOTE C_, 5
	WAIT
	WAIT
	NOTE C_, 5
	NOTE C_, 5
	WAIT
	WAIT
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	NOTE C_, 5
	WAIT
	ARP 2
	NOTE Ash, 4
	WAIT
	NOTE Gsh, 4
	WAIT
	WAIT
	NOTE Gsh, 4
	NOTE Gsh, 4
	WAIT
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE Ash, 4
	NOTE Ash, 4
	WAIT
	NOTE Ash, 4
	WAIT
	NEXT
Pat_633C:
	NOTE Dsh, 5
	NOTE Ash, 5
	NOTE Dsh, 6
	NOTE Dsh, 5
	NOTE Ash, 5
	NOTE Dsh, 6
	NOTE Dsh, 5
	NOTE Ash, 5
	NOTE Dsh, 6
	NOTE Dsh, 5
	NOTE Ash, 5
	NOTE Dsh, 6
	NOTE Dsh, 5
	NOTE Ash, 5
	NOTE Dsh, 6
	NOTE Ash, 5
	NEXT
Pat_634D:
	NOTE Dsh, 2
	NOTE Dsh, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Dsh, 2
	WAIT
	NOTE Dsh, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Dsh, 3
	NEXT
Pat_6366:
	ARP 2
	NOTE Dsh, 4
	WAIT
	WAIT
	NOTE Dsh, 4
	NOTE Csh, 4
	WAIT
	WAIT
	ARP 1
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	WAIT
	ARP 2
	NOTE Dsh, 4
	NOTE Dsh, 4
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 4
	WAIT
	WAIT
	NOTE Dsh, 4
	NOTE Csh, 4
	WAIT
	WAIT
	ARP 1
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	WAIT
	ARP 2
	NOTE Dsh, 4
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NEXT
Pat_638C:
	NOTE Dsh, 5
	NOTE Ash, 5
	NOTE Dsh, 6
	NOTE Dsh, 5
	NOTE Ash, 5
	NOTE Dsh, 6
	NOTE Dsh, 5
	NOTE Ash, 5
	NOTE Dsh, 6
	NOTE Dsh, 5
	NOTE Ash, 5
	NOTE Dsh, 6
	NOTE Dsh, 5
	NOTE Ash, 5
	NOTE Dsh, 6
	NOTE Ash, 5
	NOTE F_, 5
	NOTE C_, 6
	NOTE F_, 6
	NOTE F_, 5
	NOTE C_, 6
	NOTE F_, 6
	NOTE F_, 5
	NOTE C_, 6
	NOTE F_, 6
	NOTE F_, 5
	NOTE C_, 6
	NOTE F_, 6
	NOTE F_, 5
	NOTE C_, 6
	NOTE F_, 6
	NOTE C_, 6
	NOTE G_, 5
	NOTE D_, 6
	NOTE G_, 6
	NOTE G_, 5
	NOTE D_, 6
	NOTE G_, 6
	NOTE G_, 5
	NOTE Ash, 5
	NOTE Gsh, 5
	NOTE Dsh, 6
	NOTE Gsh, 6
	NOTE Gsh, 5
	NOTE Dsh, 6
	NOTE Gsh, 6
	NOTE Gsh, 5
	NOTE C_, 6
	NOTE Ash, 5
	NOTE D_, 6
	NOTE F_, 6
	NOTE Ash, 5
	NOTE D_, 6
	NOTE F_, 6
	NOTE Ash, 5
	NOTE D_, 6
	NOTE F_, 6
	NOTE Ash, 5
	NOTE D_, 6
	NOTE F_, 6
	NOTE Ash, 5
	NOTE D_, 6
	NOTE F_, 6
	NOTE Ash, 5
	NEXT
Pat_63CD:
	NOTE Dsh, 2
	NOTE Dsh, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Dsh, 2
	WAIT
	NOTE Dsh, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Dsh, 3
	NOTE F_, 2
	NOTE F_, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE F_, 2
	WAIT
	NOTE F_, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE F_, 3
	NOTE G_, 2
	NOTE G_, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Gsh, 2
	WAIT
	NOTE Gsh, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Gsh, 3
	NOTE Ash, 2
	NOTE Ash, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Ash, 2
	WAIT
	NOTE Ash, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Ash, 3
	NEXT
PlaySong2:
	push de
	push bc
	push hl
	call StopAll
	ld de, Song2_Ch3
	call StartMusicCh3
	ld de, Song2_Ch1
	call StartMusicCh1
	ld de, Song2_Ch2
	call StartMusicCh2
	jp SetSongTables
Song2_Ch3:
	dw Pat_64A0
	dw Pat_64CE
	ORDER_LOOP Song2_Ch3
Song2_Ch1:
	dw Pat_647B
	dw Pat_652B
	ORDER_LOOP Song2_Ch1
Song2_Ch2:
	dw Pat_6461
	dw Pat_6551
	ORDER_LOOP Song2_Ch2
Pat_6461:
	AUTODUTY $03
	LEN 28
	ARP 2
	HWENV $E2, $00
	AUTOPAN $01
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	LEN 4
	HWENV $C2, $00
	DUTY_12
	ARP_OFF
	AUTOPAN $01
	NEXT
Pat_647B:
	LEN 14
	INSTR 8
	INSTR 8
	NOTE C_, 4
	INSTR 10
	NOTE C_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 10
	NOTE C_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 10
	NOTE C_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 10
	NOTE C_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 10
	NOTE C_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 10
	NOTE C_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 10
	NOTE C_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 10
	NOTE C_, 5
	CH_TRANSPOSE $18
	NEXT
Pat_64A0:
	DRUMS $07, Drums_60D3
	INSTR 11
	LEN 28
	NOTE C_, 2
	LEN 14
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE C_, 2
	INSTR 12
	NOTE C_, 2
	INSTR 11
	LEN 14
	NOTE C_, 2
	INSTR 12
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 12
	NOTE C_, 3
	INSTR 11
	NOTE C_, 2
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE C_, 2
	INSTR 12
	NOTE C_, 2
	LEN 14
	INSTR 11
	NOTE C_, 2
	INSTR 12
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 12
	NOTE C_, 3
	TRANSPOSE $F9
	NEXT
Pat_64CE:
	INSTR 12
	LEN 14
	DRUMS $07, Drums_60D3
	NOTE G_, 2
	NOTE D_, 3
	NOTE G_, 2
	NOTE D_, 3
	NOTE Ash, 2
	NOTE F_, 3
	NOTE Ash, 2
	NOTE F_, 3
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 3
	NOTE G_, 3
	LEN 28
	INSTR 11
	NOTE D_, 3
	DRUMS $00
	END
PlaySong3:
	push de
	push bc
	push hl
	call StopAll
	ld de, Song3_Ch3
	call StartMusicCh3
	ld de, Song3_Ch1
	call StartMusicCh1
	ld de, Song3_Ch2
	call StartMusicCh2
	jp SetSongTables
Song3_Ch3:
	dw Pat_6513
	ORDER_LOOP Song3_Ch3
Song3_Ch1:
	dw Pat_652B
	ORDER_LOOP Song3_Ch1
Song3_Ch2:
	dw Pat_654A
	ORDER_LOOP Song3_Ch2
Pat_6513:
	INSTR 12
	LEN 14
	DRUMS $07, Drums_60D3
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE Ash, 2
	NOTE F_, 2
	NOTE Ash, 2
	NOTE F_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	NOTE G_, 2
	LEN 28
	INSTR 11
	NOTE D_, 2
	DRUMS $00
	END
Pat_652B:
	INSTR 23
	VIBRATO $0E, $02, $04
	ARP 3
	LEN 14
	NOTE G_, 3
	WAIT
	REST
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE Ash, 3
	WAIT
	REST
	LEN 7
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE C_, 4
	WAIT
	REST
	NOTE Ash, 3
	WAIT
	REST
	NOTE C_, 4
	REST
	LEN 28
	NOTE D_, 4
	END
Pat_654A:
	LEN 4
	HWENV $91, $00
	DUTY_75
	AUTOPAN $04
Pat_6551:
	NOTE G_, 4
	NOTE Ash, 4
	NOTE D_, 5
	NOTE G_, 5
	NOTE Ash, 5
	NOTE D_, 5
	NOTE G_, 6
	NOTE Ash, 6
	NOTE G_, 6
	NOTE D_, 6
	NOTE Ash, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE Ash, 5
	NOTE D_, 6
	NOTE F_, 6
	NOTE Ash, 6
	NOTE D_, 7
	NOTE Ash, 6
	NOTE F_, 6
	NOTE D_, 6
	NOTE Ash, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE E_, 6
	NOTE G_, 6
	NOTE C_, 7
	NOTE E_, 7
	NOTE G_, 7
	NOTE C_, 8
	NOTE G_, 7
	NOTE E_, 7
	NOTE C_, 7
	NOTE G_, 6
	NOTE E_, 6
	HWENV $94, $00
	LEN 28
	AUTOPAN $00
	PAN_C
	NOTE D_, 6
	END
PlaySong4:
	push de
	push bc
	push hl
	call StopAll
	ld de, Song4_Ch3
	call StartMusicCh3
	ld de, Song4_Ch1
	call StartMusicCh1
	ld de, Song4_Ch2
	call StartMusicCh2
	jp SetSongTables
Song4_Ch3:
	dw Pat_666B
Ord_65A1:
	dw Pat_68F7
	dw Pat_68F7
	dw Pat_6793
	dw Pat_668C
	dw Pat_668C
	dw Pat_66CB
	dw Pat_66EA
	dw Pat_6729
	dw Pat_6763
	dw Pat_668C
	dw Pat_668C
	dw Pat_66CB
	dw Pat_694D
	dw Pat_698C
	dw Pat_694D
	dw Pat_698C
	dw Pat_69C7
	dw Pat_668C
	dw Pat_668C
	dw Pat_66CB
	dw Pat_68F7
	dw Pat_68F7
	dw Pat_6793
	dw Pat_67EE
	dw Pat_67EE
	dw Pat_67EE
	dw Pat_67EE
	dw Pat_6843
	dw Pat_6843
	dw Pat_689D
	dw Pat_689D
	ORDER_LOOP Ord_65A1
Song4_Ch1:
	dw Pat_6685
Ord_65E5:
	dw Pat_6DD6
	dw Pat_6DD6
	dw Pat_6C1F
	dw Pat_6A02
	dw Pat_6A02
	dw Pat_6A83
	dw Pat_6AC1
	dw Pat_6B3E
	dw Pat_6BBF
	dw Pat_6A02
	dw Pat_6A02
	dw Pat_6A83
	dw Pat_6E58
	dw Pat_6ED5
	dw Pat_6E58
	dw Pat_6ED5
	dw Pat_6F56
	dw Pat_6A02
	dw Pat_6A02
	dw Pat_6A83
	dw Pat_6DD6
	dw Pat_6DD6
	dw Pat_6C1F
	dw Pat_6C77
	dw Pat_6C77
	dw Pat_6CB9
	dw Pat_6CB9
	dw Pat_6CFA
	dw Pat_6CFA
	dw Pat_6D73
	dw Pat_6D73
	ORDER_LOOP Ord_65E5
Song4_Ch2:
	dw Pat_6685
Ord_6629:
	dw Pat_728F
	dw Pat_728F
	dw Pat_7069
	dw Pat_6FD7
	dw Pat_6FD7
	dw Pat_6FFD
	dw Pat_7009
	dw Pat_7029
	dw Pat_7049
	dw Pat_6FD7
	dw Pat_6FD7
	dw Pat_6FFD
	dw Pat_72D4
	dw Pat_72F7
	dw Pat_72D4
	dw Pat_72F7
	dw Pat_7323
	dw Pat_6FD7
	dw Pat_6FD7
	dw Pat_6FFD
	dw Pat_728F
	dw Pat_728F
	dw Pat_7069
	dw Pat_70B9
	dw Pat_70B9
	dw Pat_7135
	dw Pat_7135
	dw Pat_71B1
	dw Pat_71B1
	dw Pat_722B
	dw Pat_722B
	ORDER_LOOP Ord_6629
Pat_666B:
	DRUMS $07, Drums_60B2
	WAVE Wave_5EFF
	LEN 28
	GLIDE $FE
	VOLENV 15, $12, $5F, $11
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 14
	NOTE A_, 3
	LEN 7
	NOTE A_, 3
	NOTE A_, 3
	NEXT
Pat_6685:
	LENGTH $C4
	HWENV $11, $00
	NOTE A_, 2
	NEXT
Pat_668C:
	LEN 7
	INSTR 1
	NOTE C_, 4
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	LEN 14
	INSTR 11
	NOTE C_, 2
	INSTR 12
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	NOTE G_, 2
	INSTR 12
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE Ash, 2
	INSTR 12
	NOTE Ash, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE Ash, 2
	NOTE F_, 2
	INSTR 12
	NOTE F_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE F_, 2
	NOTE Gsh, 2
	INSTR 12
	NOTE Gsh, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE Gsh, 2
	NOTE C_, 3
	INSTR 12
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE C_, 3
	NOTE G_, 2
	INSTR 12
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	NEXT
Pat_66CB:
	INSTR 1
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	INSTR 12
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	NOTE C_, 2
	INSTR 12
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	NOTE C_, 2
	INSTR 12
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	INSTR 12
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	NEXT
Pat_66EA:
	LEN 7
	INSTR 1
	NOTE C_, 4
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	LEN 14
	INSTR 11
	NOTE C_, 2
	INSTR 12
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	NOTE G_, 2
	INSTR 12
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE C_, 2
	INSTR 12
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	NOTE G_, 2
	INSTR 12
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE C_, 2
	INSTR 12
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	NOTE G_, 2
	INSTR 12
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE C_, 2
	INSTR 12
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	NOTE G_, 2
	INSTR 12
	NOTE G_, 2
	NEXT
Pat_6729:
	LEN 14
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE F_, 2
	INSTR 12
	NOTE F_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE F_, 2
	NOTE C_, 3
	INSTR 12
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE C_, 3
	NOTE C_, 2
	INSTR 12
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	NOTE G_, 2
	INSTR 12
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE G_, 2
	INSTR 12
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE D_, 3
	INSTR 12
	NOTE D_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE D_, 3
	NOTE G_, 2
	INSTR 12
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE D_, 3
	INSTR 12
	NOTE D_, 3
	NEXT
Pat_6763:
	LEN 14
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE C_, 3
	INSTR 12
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE C_, 3
	NOTE G_, 2
	INSTR 12
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE D_, 2
	INSTR 12
	NOTE D_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE D_, 2
	NOTE G_, 2
	INSTR 12
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE C_, 3
	INSTR 1
	LEN 7
	NOTE C_, 4
	INSTR 11
	NOTE C_, 3
	LEN 14
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	NEXT
Pat_6793:
	LEN 7
	INSTR 1
	NOTE C_, 4
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	WAIT
	WAIT
	WAIT
	INSTR 1
	NOTE C_, 4
	WAIT
	INSTR 12
	NOTE C_, 2
	NOTE C_, 2
	INSTR 11
	NOTE Dsh, 2
	WAIT
	WAIT
	WAIT
	INSTR 1
	NOTE C_, 4
	WAIT
	INSTR 12
	NOTE Dsh, 2
	NOTE Dsh, 2
	INSTR 11
	NOTE F_, 2
	WAIT
	WAIT
	WAIT
	INSTR 1
	NOTE C_, 4
	WAIT
	INSTR 11
	NOTE F_, 2
	WAIT
	NOTE G_, 2
	WAIT
	WAIT
	WAIT
	INSTR 1
	NOTE C_, 4
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE F_, 2
	WAIT
	NOTE F_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	WAIT
	INSTR 12
	NOTE F_, 2
	NOTE F_, 2
	INSTR 11
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	WAIT
	INSTR 12
	NOTE G_, 2
	NOTE G_, 2
	INSTR 11
	NOTE A_, 2
	WAIT
	NOTE A_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	WAIT
	INSTR 11
	NOTE A_, 3
	WAIT
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE C_, 4
	WAIT
	NEXT
Pat_67EE:
	LEN 14
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE G_, 3
	NOTE C_, 2
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE C_, 3
	INSTR 12
	NOTE C_, 2
	INSTR 11
	LEN 14
	NOTE C_, 2
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE C_, 3
	INSTR 12
	NOTE C_, 2
	INSTR 11
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE G_, 3
	INSTR 12
	NOTE G_, 2
	INSTR 11
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE G_, 3
	INSTR 12
	NOTE G_, 2
	INSTR 11
	LEN 14
	NOTE C_, 2
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE C_, 3
	INSTR 12
	NOTE C_, 2
	INSTR 11
	LEN 14
	NOTE C_, 2
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE C_, 3
	INSTR 12
	NOTE C_, 2
	INSTR 11
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE G_, 3
	INSTR 12
	NOTE G_, 2
	INSTR 11
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	NEXT
Pat_6843:
	LEN 14
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE C_, 3
	INSTR 12
	NOTE C_, 2
	INSTR 11
	LEN 14
	NOTE C_, 2
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE C_, 3
	INSTR 12
	NOTE C_, 2
	INSTR 11
	LEN 14
	NOTE C_, 2
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE C_, 3
	INSTR 12
	NOTE G_, 2
	INSTR 11
	LEN 14
	NOTE G_, 2
	NOTE G_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE G_, 3
	INSTR 12
	NOTE G_, 2
	INSTR 11
	LEN 14
	NOTE G_, 2
	NOTE G_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE G_, 3
	INSTR 12
	NOTE G_, 2
	INSTR 11
	LEN 14
	NOTE Gsh, 2
	NOTE Gsh, 3
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE Gsh, 3
	INSTR 12
	NOTE Gsh, 2
	INSTR 11
	LEN 14
	NOTE Gsh, 2
	NOTE Gsh, 3
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE Gsh, 3
	INSTR 12
	NOTE Gsh, 2
	INSTR 11
	LEN 14
	NOTE G_, 2
	NOTE G_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE G_, 3
	INSTR 12
	NOTE G_, 2
	INSTR 11
	LEN 14
	NOTE G_, 2
	NOTE G_, 3
	NEXT
Pat_689D:
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE C_, 3
	INSTR 12
	NOTE C_, 2
	INSTR 11
	LEN 14
	NOTE C_, 2
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE C_, 3
	INSTR 12
	NOTE C_, 2
	INSTR 11
	LEN 14
	NOTE C_, 2
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE C_, 3
	INSTR 12
	NOTE G_, 2
	INSTR 11
	LEN 14
	NOTE G_, 2
	NOTE G_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE G_, 3
	INSTR 12
	NOTE G_, 2
	INSTR 11
	LEN 14
	NOTE G_, 2
	NOTE G_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE G_, 3
	INSTR 12
	NOTE G_, 2
	INSTR 11
	LEN 14
	NOTE Gsh, 2
	INSTR 12
	NOTE Gsh, 3
	INSTR 1
	NOTE C_, 4
	INSTR 12
	LEN 7
	NOTE Gsh, 3
	NOTE Gsh, 2
	INSTR 11
	LEN 14
	NOTE Gsh, 2
	INSTR 12
	NOTE Gsh, 3
	INSTR 1
	NOTE C_, 4
	INSTR 12
	LEN 7
	NOTE Gsh, 3
	NOTE Gsh, 2
	INSTR 11
	LEN 14
	NOTE G_, 2
	INSTR 12
	NOTE G_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 12
	LEN 7
	NOTE G_, 3
	NOTE G_, 2
	INSTR 11
	LEN 14
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	NEXT
Pat_68F7:
	DRUMS $07, Drums_60A9
	LEN 14
	INSTR 1
	NOTE C_, 4
	INSTR 1
	LEN 7
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 28
	NOTE C_, 2
	LEN 14
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE C_, 2
	INSTR 12
	NOTE C_, 2
	INSTR 11
	LEN 14
	NOTE C_, 2
	INSTR 12
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 12
	NOTE C_, 3
	INSTR 11
	NOTE C_, 2
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE C_, 2
	INSTR 12
	NOTE C_, 2
	LEN 14
	INSTR 11
	NOTE C_, 2
	INSTR 12
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 12
	NOTE C_, 3
	INSTR 11
	NOTE C_, 2
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE C_, 2
	INSTR 12
	NOTE C_, 2
	INSTR 11
	LEN 14
	NOTE C_, 2
	INSTR 12
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 12
	NOTE C_, 3
	INSTR 11
	NOTE C_, 2
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE C_, 2
	INSTR 12
	NOTE C_, 2
	INSTR 11
	LEN 14
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	NEXT
Pat_694D:
	LEN 14
	INSTR 1
	NOTE C_, 4
	INSTR 1
	LEN 7
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 11
	LEN 14
	NOTE C_, 2
	INSTR 12
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	NOTE G_, 2
	INSTR 12
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE C_, 2
	INSTR 12
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	NOTE G_, 2
	INSTR 12
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE C_, 2
	INSTR 12
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	NOTE G_, 2
	INSTR 12
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE G_, 2
	INSTR 12
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE D_, 3
	INSTR 12
	NOTE D_, 3
	NEXT
Pat_698C:
	LEN 14
	INSTR 1
	NOTE C_, 4
	INSTR 12
	NOTE D_, 3
	INSTR 11
	NOTE G_, 2
	INSTR 12
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE D_, 3
	INSTR 12
	NOTE D_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE F_, 2
	INSTR 12
	NOTE F_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE F_, 2
	NOTE C_, 3
	INSTR 12
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE E_, 2
	NOTE D_, 2
	INSTR 12
	NOTE D_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE D_, 2
	NOTE G_, 2
	INSTR 12
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE C_, 3
	INSTR 12
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE C_, 3
	INSTR 12
	NOTE C_, 3
	NEXT
Pat_69C7:
	LEN 14
	INSTR 1
	NOTE C_, 4
	INSTR 12
	NOTE C_, 3
	INSTR 11
	NOTE F_, 2
	INSTR 12
	NOTE F_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE F_, 2
	NOTE C_, 3
	INSTR 12
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE C_, 3
	NOTE C_, 2
	INSTR 12
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	NOTE G_, 2
	INSTR 12
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE D_, 2
	INSTR 12
	NOTE D_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE D_, 2
	NOTE G_, 2
	INSTR 12
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE C_, 3
	INSTR 12
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 11
	NOTE C_, 3
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	NEXT
Pat_6A02:
	INSTR 9
	NOTE B_, 4
	INSTR 16
	NOTE E_, 5
	INSTR 10
	NOTE D_, 5
	INSTR 16
	NOTE E_, 5
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE C_, 6
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE C_, 6
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE E_, 5
	INSTR 21
	NOTE G_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 8
	NOTE G_, 4
	INSTR 16
	NOTE B_, 5
	INSTR 9
	NOTE B_, 4
	INSTR 16
	NOTE B_, 5
	INSTR 10
	NOTE D_, 5
	INSTR 16
	NOTE E_, 5
	INSTR 21
	NOTE Ash, 4
	INSTR 16
	NOTE G_, 5
	INSTR 8
	NOTE Ash, 4
	INSTR 16
	NOTE Ash, 5
	INSTR 9
	NOTE D_, 5
	INSTR 16
	NOTE Ash, 5
	INSTR 10
	NOTE F_, 5
	INSTR 16
	NOTE C_, 6
	INSTR 21
	NOTE F_, 4
	INSTR 16
	NOTE A_, 5
	INSTR 8
	NOTE F_, 4
	INSTR 16
	NOTE A_, 5
	INSTR 9
	NOTE A_, 4
	INSTR 16
	NOTE A_, 5
	INSTR 10
	NOTE C_, 5
	INSTR 16
	NOTE F_, 5
	INSTR 21
	NOTE Gsh, 4
	INSTR 16
	NOTE G_, 5
	INSTR 8
	NOTE Gsh, 4
	INSTR 16
	NOTE Gsh, 5
	INSTR 9
	NOTE C_, 5
	INSTR 16
	NOTE Gsh, 5
	INSTR 10
	NOTE Dsh, 5
	INSTR 16
	NOTE Ash, 5
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE F_, 5
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE E_, 5
	INSTR 21
	NOTE G_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 8
	NOTE G_, 4
	INSTR 16
	NOTE D_, 5
	INSTR 9
	NOTE B_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 10
	NOTE D_, 5
	INSTR 16
	NOTE A_, 5
	INSTR 21
	NOTE G_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 8
	NOTE G_, 4
	INSTR 16
	NOTE G_, 5
	NEXT
Pat_6A83:
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE F_, 5
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE E_, 5
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE D_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 21
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	NEXT
Pat_6AC1:
	WAIT
	WAIT
	WAIT
	WAIT
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE E_, 5
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE E_, 5
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE D_, 5
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE F_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE E_, 5
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE E_, 5
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE E_, 5
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE D_, 5
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE F_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE E_, 5
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE E_, 5
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE E_, 5
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE E_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE E_, 5
	NEXT
Pat_6B3E:
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE E_, 5
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE E_, 5
	INSTR 21
	NOTE F_, 4
	INSTR 16
	NOTE E_, 5
	INSTR 8
	NOTE F_, 4
	INSTR 16
	NOTE A_, 5
	INSTR 9
	NOTE A_, 4
	INSTR 16
	NOTE C_, 6
	INSTR 10
	NOTE C_, 5
	INSTR 16
	NOTE C_, 6
	INSTR 21
	NOTE F_, 4
	INSTR 16
	NOTE C_, 6
	INSTR 8
	NOTE F_, 4
	INSTR 16
	NOTE C_, 6
	INSTR 9
	NOTE A_, 4
	INSTR 16
	NOTE B_, 5
	INSTR 10
	NOTE C_, 5
	INSTR 16
	NOTE A_, 5
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE B_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE A_, 5
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE E_, 5
	INSTR 21
	NOTE G_, 4
	INSTR 16
	NOTE F_, 5
	INSTR 8
	NOTE G_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 9
	NOTE B_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 10
	NOTE D_, 5
	INSTR 16
	NOTE A_, 5
	INSTR 21
	NOTE G_, 4
	INSTR 16
	NOTE A_, 5
	INSTR 8
	NOTE G_, 4
	INSTR 16
	NOTE B_, 5
	INSTR 9
	NOTE B_, 4
	INSTR 16
	NOTE B_, 5
	INSTR 10
	NOTE D_, 5
	INSTR 16
	NOTE C_, 6
	INSTR 21
	NOTE G_, 4
	INSTR 16
	NOTE C_, 6
	INSTR 8
	NOTE G_, 4
	INSTR 16
	NOTE D_, 6
	INSTR 9
	NOTE B_, 4
	INSTR 16
	NOTE D_, 6
	INSTR 10
	NOTE D_, 5
	INSTR 16
	NOTE D_, 6
	INSTR 21
	NOTE G_, 4
	INSTR 16
	NOTE D_, 6
	INSTR 8
	NOTE G_, 4
	INSTR 16
	NOTE D_, 6
	NEXT
Pat_6BBF:
	INSTR 9
	NOTE A_, 4
	INSTR 16
	NOTE E_, 6
	INSTR 10
	NOTE C_, 5
	INSTR 16
	NOTE F_, 6
	INSTR 21
	NOTE C_, 5
	INSTR 16
	NOTE E_, 6
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE E_, 6
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE C_, 6
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 21
	NOTE C_, 5
	INSTR 16
	NOTE G_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE F_, 5
	INSTR 20
	NOTE D_, 4
	INSTR 16
	NOTE E_, 5
	INSTR 8
	NOTE D_, 4
	INSTR 16
	NOTE F_, 5
	INSTR 9
	NOTE F_, 4
	INSTR 16
	NOTE A_, 5
	INSTR 10
	NOTE A_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 21
	NOTE G_, 4
	INSTR 16
	NOTE C_, 6
	INSTR 8
	NOTE G_, 4
	INSTR 16
	NOTE B_, 5
	INSTR 9
	NOTE B_, 4
	INSTR 16
	NOTE G_, 5
	INSTR 10
	NOTE D_, 5
	INSTR 16
	NOTE E_, 6
	INSTR 21
	NOTE C_, 5
	INSTR 16
	NOTE D_, 6
	INSTR 8
	NOTE E_, 4
	INSTR 16
	NOTE C_, 6
	INSTR 21
	NOTE C_, 5
	INSTR 16
	NOTE C_, 6
	INSTR 10
	NOTE E_, 4
	INSTR 21
	NOTE C_, 5
	NOTE C_, 5
	INSTR 16
	NOTE C_, 6
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE C_, 6
	NEXT
Pat_6C1F:
	WAIT
	WAIT
	WAIT
	WAIT
	INSTR 23
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	INSTR 17
	NOTE G_, 4
	WAIT
	INSTR 23
	NOTE G_, 4
	NOTE G_, 4
	NOTE Ash, 4
	WAIT
	WAIT
	WAIT
	INSTR 17
	NOTE Ash, 4
	WAIT
	INSTR 23
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE C_, 5
	WAIT
	INSTR 17
	NOTE C_, 5
	INSTR 23
	NOTE Ash, 4
	WAIT
	INSTR 17
	NOTE Ash, 4
	INSTR 23
	NOTE C_, 5
	INSTR 17
	NOTE C_, 5
	INSTR 23
	NOTE D_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	INSTR 17
	NOTE D_, 5
	WAIT
	INSTR 23
	NOTE F_, 5
	WAIT
	WAIT
	WAIT
	INSTR 17
	NOTE F_, 5
	WAIT
	INSTR 23
	NOTE F_, 5
	NOTE F_, 5
	NOTE G_, 5
	WAIT
	WAIT
	WAIT
	INSTR 17
	NOTE G_, 5
	WAIT
	INSTR 23
	NOTE G_, 5
	NOTE G_, 5
	NOTE A_, 5
	WAIT
	INSTR 17
	NOTE A_, 5
	INSTR 23
	NOTE G_, 5
	WAIT
	INSTR 17
	NOTE G_, 5
	INSTR 23
	NOTE A_, 5
	INSTR 17
	NOTE A_, 5
	INSTR 23
	NOTE B_, 5
	WAIT
	WAIT
	WAIT
	NEXT
Pat_6C77:
	INSTR 13
	NOTE F_, 6
	WAIT
	WAIT
	WAIT
	NOTE C_, 6
	NOTE E_, 6
	NOTE G_, 6
	NOTE B_, 6
	NOTE C_, 7
	NOTE B_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	NOTE E_, 6
	NOTE G_, 6
	NOTE B_, 6
	NOTE C_, 7
	NOTE B_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE Ash, 5
	NOTE D_, 6
	NOTE F_, 6
	NOTE A_, 6
	NOTE Ash, 6
	NOTE A_, 6
	NOTE F_, 6
	NOTE D_, 6
	NOTE Ash, 5
	NOTE D_, 6
	NOTE F_, 6
	NOTE A_, 6
	NOTE Ash, 6
	NOTE A_, 6
	NOTE F_, 6
	NOTE D_, 6
	NOTE C_, 6
	NOTE E_, 6
	NOTE G_, 6
	NOTE B_, 6
	NOTE C_, 7
	NOTE B_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	NOTE E_, 6
	NOTE G_, 6
	NOTE B_, 6
	NOTE C_, 7
	NOTE B_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE Ash, 5
	NOTE D_, 6
	NOTE F_, 6
	NOTE A_, 6
	NOTE Ash, 6
	NOTE A_, 6
	NOTE F_, 6
	NOTE D_, 6
	NOTE Ash, 5
	NOTE D_, 6
	NOTE F_, 6
	NOTE A_, 6
	NEXT
Pat_6CB9:
	NOTE F_, 5
	WAIT
	WAIT
	WAIT
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE B_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE B_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE Ash, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE Ash, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE B_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE B_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE Ash, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE Ash, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE A_, 5
	NEXT
Pat_6CFA:
	INSTR 13
	NOTE F_, 5
	WAIT
	WAIT
	INSTR 17
	NOTE F_, 5
	INSTR 13
	NOTE G_, 5
	INSTR 17
	NOTE F_, 5
	INSTR 13
	NOTE E_, 5
	INSTR 17
	NOTE G_, 5
	INSTR 13
	NOTE C_, 5
	INSTR 17
	NOTE E_, 5
	INSTR 13
	NOTE G_, 4
	INSTR 17
	NOTE C_, 5
	INSTR 13
	NOTE C_, 5
	INSTR 17
	NOTE G_, 4
	INSTR 13
	NOTE E_, 5
	INSTR 17
	NOTE C_, 5
	INSTR 13
	NOTE G_, 5
	WAIT
	INSTR 17
	NOTE E_, 5
	INSTR 13
	NOTE Gsh, 5
	NOTE F_, 5
	INSTR 17
	NOTE G_, 5
	INSTR 13
	NOTE D_, 5
	INSTR 17
	NOTE F_, 5
	INSTR 13
	NOTE Ash, 4
	INSTR 17
	NOTE D_, 5
	INSTR 13
	NOTE F_, 4
	INSTR 17
	NOTE Ash, 4
	INSTR 13
	NOTE Ash, 4
	INSTR 17
	NOTE F_, 4
	INSTR 13
	NOTE D_, 5
	INSTR 17
	NOTE Ash, 4
	INSTR 13
	NOTE F_, 5
	WAIT
	INSTR 17
	NOTE D_, 5
	INSTR 13
	NOTE Fsh, 5
	NOTE Dsh, 5
	INSTR 17
	NOTE Fsh, 5
	INSTR 13
	NOTE C_, 5
	INSTR 17
	NOTE Dsh, 5
	INSTR 13
	NOTE Gsh, 4
	INSTR 17
	NOTE C_, 5
	INSTR 13
	NOTE Dsh, 4
	INSTR 17
	NOTE Gsh, 4
	INSTR 13
	NOTE Gsh, 4
	INSTR 17
	NOTE Dsh, 5
	INSTR 13
	NOTE C_, 5
	INSTR 17
	NOTE Gsh, 4
	INSTR 13
	NOTE Dsh, 5
	WAIT
	INSTR 17
	NOTE C_, 5
	INSTR 13
	NOTE F_, 5
	NOTE D_, 5
	INSTR 17
	NOTE F_, 5
	INSTR 13
	NOTE B_, 4
	INSTR 17
	NOTE D_, 5
	INSTR 13
	NOTE G_, 4
	INSTR 17
	NOTE B_, 4
	INSTR 13
	NOTE D_, 4
	INSTR 17
	NOTE G_, 4
	INSTR 13
	NOTE F_, 4
	INSTR 17
	NOTE D_, 4
	INSTR 13
	NOTE B_, 4
	INSTR 17
	NOTE F_, 4
	NEXT
Pat_6D73:
	INSTR 13
	NOTE F_, 5
	WAIT
	WAIT
	INSTR 17
	NOTE F_, 5
	INSTR 13
	NOTE G_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	INSTR 17
	NOTE G_, 5
	INSTR 13
	NOTE G_, 5
	WAIT
	WAIT
	INSTR 17
	NOTE G_, 5
	INSTR 13
	NOTE F_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	INSTR 17
	NOTE F_, 5
	INSTR 13
	NOTE F_, 5
	WAIT
	WAIT
	INSTR 17
	NOTE F_, 5
	INSTR 13
	NOTE C_, 6
	INSTR 17
	NOTE F_, 5
	INSTR 13
	NOTE Ash, 5
	INSTR 17
	NOTE C_, 6
	INSTR 13
	NOTE Gsh, 5
	INSTR 17
	NOTE Ash, 5
	INSTR 13
	NOTE Ash, 5
	INSTR 17
	NOTE Gsh, 5
	INSTR 13
	NOTE C_, 6
	INSTR 17
	NOTE Ash, 5
	INSTR 13
	NOTE D_, 6
	INSTR 17
	NOTE C_, 6
	INSTR 13
	NOTE Dsh, 6
	WAIT
	WAIT
	INSTR 17
	NOTE Dsh, 6
	INSTR 13
	NOTE B_, 5
	INSTR 17
	NOTE Dsh, 6
	INSTR 13
	NOTE C_, 6
	INSTR 17
	NOTE B_, 5
	INSTR 13
	NOTE B_, 5
	INSTR 17
	NOTE C_, 6
	INSTR 13
	NOTE C_, 6
	INSTR 17
	NOTE B_, 5
	INSTR 13
	NOTE B_, 5
	WAIT
	WAIT
	INSTR 17
	NOTE B_, 5
	NEXT
Pat_6DD6:
	LEN 7
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE G_, 4
	INSTR 10
	NOTE C_, 5
	INSTR 16
	NOTE G_, 4
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE C_, 4
	INSTR 10
	NOTE C_, 5
	INSTR 16
	NOTE C_, 4
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE C_, 4
	INSTR 10
	NOTE C_, 5
	INSTR 16
	NOTE C_, 4
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE C_, 4
	INSTR 10
	NOTE C_, 5
	INSTR 16
	NOTE Dsh, 4
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE Dsh, 4
	INSTR 10
	NOTE C_, 5
	INSTR 16
	NOTE Dsh, 4
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE Dsh, 4
	INSTR 10
	NOTE C_, 5
	INSTR 16
	NOTE C_, 4
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE C_, 4
	INSTR 10
	NOTE C_, 5
	INSTR 16
	NOTE C_, 4
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE C_, 4
	INSTR 10
	NOTE C_, 5
	INSTR 16
	NOTE Dsh, 4
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE Dsh, 4
	INSTR 10
	NOTE C_, 5
	INSTR 16
	NOTE Dsh, 4
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE Dsh, 4
	INSTR 10
	NOTE C_, 5
	INSTR 16
	NOTE E_, 4
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE E_, 4
	INSTR 10
	NOTE C_, 5
	INSTR 16
	NOTE E_, 4
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE E_, 4
	INSTR 10
	NOTE C_, 5
	INSTR 16
	NOTE G_, 4
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE G_, 4
	INSTR 10
	NOTE C_, 5
	INSTR 16
	NOTE G_, 4
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE G_, 4
	INSTR 10
	NOTE C_, 5
	INSTR 16
	NOTE E_, 4
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE E_, 4
	INSTR 10
	NOTE C_, 5
	INSTR 16
	NOTE E_, 4
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE E_, 4
	INSTR 10
	NOTE C_, 5
	INSTR 16
	NOTE G_, 4
	NEXT
Pat_6E58:
	WAIT
	WAIT
	WAIT
	WAIT
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE A_, 4
	INSTR 9
	NOTE C_, 4
	INSTR 16
	NOTE A_, 4
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE A_, 4
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE A_, 4
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE G_, 4
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE E_, 4
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE E_, 4
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE G_, 4
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE A_, 4
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE A_, 4
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE A_, 4
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE G_, 4
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE E_, 4
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE E_, 4
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE G_, 4
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE A_, 4
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE A_, 4
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE A_, 4
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE G_, 4
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE E_, 4
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE E_, 4
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE G_, 4
	INSTR 21
	NOTE G_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 8
	NOTE G_, 4
	INSTR 16
	NOTE B_, 4
	INSTR 9
	NOTE B_, 4
	INSTR 16
	NOTE B_, 4
	INSTR 10
	NOTE D_, 5
	INSTR 16
	NOTE B_, 4
	INSTR 21
	NOTE G_, 4
	INSTR 16
	NOTE B_, 4
	INSTR 8
	NOTE G_, 4
	INSTR 16
	NOTE B_, 4
	NEXT
Pat_6ED5:
	INSTR 9
	NOTE B_, 4
	INSTR 16
	NOTE B_, 4
	INSTR 10
	NOTE D_, 5
	INSTR 16
	NOTE C_, 5
	INSTR 21
	NOTE G_, 4
	INSTR 16
	NOTE Csh, 5
	INSTR 8
	NOTE G_, 4
	INSTR 16
	NOTE D_, 5
	INSTR 9
	NOTE B_, 4
	INSTR 16
	NOTE E_, 5
	INSTR 10
	NOTE D_, 5
	INSTR 16
	NOTE D_, 5
	INSTR 21
	NOTE G_, 4
	INSTR 16
	NOTE G_, 4
	INSTR 8
	NOTE G_, 4
	INSTR 16
	NOTE B_, 4
	INSTR 9
	NOTE B_, 4
	INSTR 16
	NOTE B_, 4
	INSTR 10
	NOTE D_, 5
	INSTR 16
	NOTE A_, 4
	INSTR 21
	NOTE F_, 4
	INSTR 16
	NOTE B_, 4
	INSTR 8
	NOTE F_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 9
	NOTE A_, 4
	INSTR 16
	NOTE D_, 5
	INSTR 10
	NOTE C_, 5
	INSTR 16
	NOTE C_, 5
	INSTR 21
	NOTE F_, 4
	INSTR 16
	NOTE F_, 4
	INSTR 8
	NOTE F_, 4
	INSTR 16
	NOTE A_, 4
	INSTR 9
	NOTE A_, 4
	INSTR 16
	NOTE A_, 4
	INSTR 10
	NOTE C_, 5
	INSTR 16
	NOTE D_, 4
	INSTR 21
	NOTE D_, 4
	INSTR 16
	NOTE E_, 4
	INSTR 8
	NOTE D_, 4
	INSTR 16
	NOTE F_, 4
	INSTR 9
	NOTE F_, 4
	INSTR 16
	NOTE G_, 4
	INSTR 10
	NOTE A_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 21
	NOTE G_, 4
	INSTR 16
	NOTE A_, 4
	INSTR 8
	NOTE G_, 4
	INSTR 16
	NOTE B_, 4
	INSTR 9
	NOTE B_, 4
	INSTR 16
	NOTE A_, 4
	INSTR 10
	NOTE D_, 5
	INSTR 16
	NOTE G_, 4
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE D_, 4
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE F_, 4
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE E_, 4
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE E_, 4
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE E_, 4
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE E_, 4
	NEXT
Pat_6F56:
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE E_, 4
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE E_, 4
	INSTR 21
	NOTE F_, 4
	INSTR 16
	NOTE G_, 4
	INSTR 8
	NOTE F_, 4
	INSTR 16
	NOTE Gsh, 4
	INSTR 9
	NOTE Gsh, 4
	INSTR 16
	NOTE Gsh, 4
	INSTR 10
	NOTE C_, 5
	INSTR 16
	NOTE Gsh, 4
	INSTR 21
	NOTE F_, 4
	INSTR 16
	NOTE G_, 4
	INSTR 8
	NOTE F_, 4
	INSTR 16
	NOTE F_, 4
	INSTR 9
	NOTE Gsh, 4
	INSTR 16
	NOTE F_, 4
	INSTR 10
	NOTE C_, 5
	INSTR 16
	NOTE F_, 4
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE F_, 4
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE G_, 4
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE G_, 4
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE G_, 4
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE F_, 4
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE E_, 4
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE E_, 4
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE E_, 4
	INSTR 20
	NOTE D_, 4
	INSTR 16
	NOTE E_, 4
	INSTR 8
	NOTE D_, 4
	INSTR 16
	NOTE F_, 4
	INSTR 9
	NOTE F_, 4
	INSTR 16
	NOTE G_, 4
	INSTR 10
	NOTE A_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 20
	NOTE E_, 4
	INSTR 16
	NOTE A_, 4
	INSTR 8
	NOTE G_, 4
	INSTR 16
	NOTE B_, 4
	INSTR 9
	NOTE B_, 4
	INSTR 16
	NOTE G_, 4
	INSTR 10
	NOTE D_, 5
	INSTR 16
	NOTE E_, 5
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE D_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 9
	NOTE E_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 10
	NOTE G_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 21
	NOTE C_, 4
	INSTR 16
	NOTE C_, 5
	INSTR 8
	NOTE C_, 4
	INSTR 16
	NOTE C_, 5
	NEXT
Pat_6FD7:
	RELEASE $05, $D1
	INSTR 23
	LEN 14
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	WAIT
	NOTE E_, 5
	NOTE G_, 5
	NOTE B_, 5
	WAIT
	NOTE E_, 5
	NOTE G_, 5
	NOTE Ash, 5
	WAIT
	NOTE C_, 6
	NOTE A_, 5
	WAIT
	WAIT
	NOTE F_, 5
	NOTE G_, 5
	NOTE Gsh, 5
	WAIT
	NOTE Ash, 5
	NOTE G_, 5
	WAIT
	NOTE F_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE G_, 5
	WAIT
	NOTE F_, 5
	NEXT
Pat_6FFD:
	INSTR 23
	NOTE E_, 5
	NOTE D_, 5
	LENGTH $B6
	RELEASE $00
	NOTE C_, 5
	LEN 14
	INSTR 15
	NOTE C_, 5
	NEXT
Pat_7009:
	LEN 14
	WAIT
	WAIT
	RELEASE $05, $D1
	INSTR 23
	NOTE E_, 5
	LENGTH $38
	NOTE G_, 5
	LEN 14
	NOTE E_, 5
	NOTE D_, 5
	NOTE F_, 5
	NOTE E_, 5
	LENGTH $62
	NOTE C_, 5
	LEN 14
	NOTE E_, 5
	LENGTH $38
	NOTE G_, 5
	LEN 14
	NOTE E_, 5
	NOTE D_, 5
	NOTE F_, 5
	LENGTH $70
	NOTE E_, 5
	NEXT
Pat_7029:
	LEN 14
	INSTR 23
	NOTE A_, 5
	LENGTH $38
	NOTE C_, 6
	LEN 14
	NOTE B_, 5
	LEN 7
	NOTE A_, 5
	WAIT
	WAIT
	NOTE B_, 5
	LEN 14
	NOTE A_, 5
	LENGTH $46
	NOTE G_, 5
	LEN 14
	NOTE E_, 5
	NOTE F_, 5
	LEN 28
	NOTE G_, 5
	NOTE A_, 5
	NOTE B_, 5
	NOTE C_, 6
	LENGTH $4D
	NOTE D_, 6
	LEN 7
	NOTE E_, 6
	NEXT
Pat_7049:
	LEN 7
	INSTR 23
	NOTE F_, 6
	WAIT
	NOTE E_, 6
	NOTE D_, 6
	LEN 14
	NOTE E_, 6
	NOTE C_, 6
	LEN 14
	NOTE G_, 5
	WAIT
	WAIT
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE B_, 5
	NOTE G_, 5
	NOTE E_, 6
	LEN 7
	WAIT
	NOTE D_, 6
	LENGTH $46
	NOTE C_, 6
	LEN 14
	NOTE D_, 5
	NEXT
Pat_7069:
	LEN 7
	WAIT
	WAIT
	WAIT
	REST
	INSTR 23
	LEN 28
	NOTE C_, 5
	LEN 7
	INSTR 16
	NOTE C_, 5
	WAIT
	INSTR 23
	NOTE C_, 5
	NOTE C_, 5
	LEN 28
	NOTE Dsh, 5
	LEN 7
	INSTR 16
	NOTE Dsh, 5
	WAIT
	INSTR 23
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE F_, 5
	WAIT
	INSTR 16
	NOTE F_, 5
	INSTR 23
	NOTE Dsh, 5
	WAIT
	INSTR 16
	NOTE Dsh, 5
	INSTR 23
	NOTE F_, 5
	INSTR 16
	NOTE F_, 5
	INSTR 23
	LEN 28
	NOTE G_, 5
	LEN 14
	WAIT
	INSTR 16
	NOTE G_, 5
	INSTR 23
	LEN 28
	NOTE A_, 5
	LEN 7
	INSTR 16
	NOTE A_, 5
	WAIT
	INSTR 23
	NOTE A_, 5
	NOTE A_, 5
	LEN 28
	NOTE B_, 5
	LEN 7
	INSTR 16
	NOTE B_, 5
	WAIT
	INSTR 23
	NOTE B_, 5
	NOTE B_, 5
	NOTE C_, 6
	WAIT
	INSTR 16
	NOTE C_, 6
	INSTR 23
	NOTE B_, 5
	WAIT
	INSTR 16
	NOTE B_, 5
	INSTR 23
	NOTE C_, 6
	INSTR 16
	NOTE C_, 6
	INSTR 23
	LEN 28
	NOTE D_, 6
	NEXT
Pat_70B9:
	LEN 28
	INSTR 24
	NOTE D_, 6
	LEN 7
	NOTE C_, 6
	INSTR 16
	NOTE D_, 6
	INSTR 24
	NOTE G_, 5
	INSTR 16
	NOTE C_, 6
	INSTR 24
	NOTE C_, 6
	INSTR 16
	NOTE G_, 5
	INSTR 24
	NOTE G_, 5
	INSTR 17
	NOTE C_, 6
	INSTR 24
	NOTE C_, 6
	INSTR 16
	NOTE G_, 5
	INSTR 24
	NOTE G_, 5
	INSTR 17
	NOTE C_, 6
	INSTR 24
	NOTE C_, 6
	INSTR 16
	NOTE G_, 5
	INSTR 24
	NOTE B_, 5
	INSTR 17
	NOTE C_, 6
	INSTR 24
	NOTE Ash, 5
	INSTR 16
	NOTE B_, 5
	INSTR 24
	NOTE F_, 5
	INSTR 17
	NOTE Ash, 5
	INSTR 24
	NOTE Ash, 5
	INSTR 16
	NOTE F_, 5
	INSTR 24
	NOTE F_, 5
	INSTR 17
	NOTE Ash, 5
	INSTR 24
	NOTE Ash, 5
	INSTR 16
	NOTE F_, 5
	INSTR 24
	NOTE F_, 5
	INSTR 17
	NOTE Ash, 5
	INSTR 24
	NOTE Ash, 5
	INSTR 16
	NOTE F_, 5
	INSTR 24
	NOTE B_, 5
	INSTR 17
	NOTE Ash, 5
	INSTR 24
	NOTE C_, 6
	INSTR 16
	NOTE B_, 5
	INSTR 24
	NOTE G_, 5
	INSTR 17
	NOTE C_, 6
	INSTR 24
	NOTE C_, 6
	INSTR 16
	NOTE G_, 5
	INSTR 24
	NOTE G_, 5
	INSTR 17
	NOTE C_, 6
	INSTR 24
	NOTE C_, 6
	INSTR 16
	NOTE G_, 5
	INSTR 24
	NOTE G_, 5
	INSTR 17
	NOTE C_, 6
	INSTR 24
	NOTE C_, 6
	INSTR 16
	NOTE G_, 5
	INSTR 24
	NOTE B_, 5
	INSTR 17
	NOTE C_, 6
	INSTR 24
	NOTE Ash, 5
	INSTR 16
	NOTE B_, 5
	INSTR 24
	NOTE F_, 5
	INSTR 17
	NOTE Ash, 5
	INSTR 24
	NOTE Ash, 5
	INSTR 16
	NOTE F_, 5
	INSTR 24
	NOTE F_, 5
	INSTR 17
	NOTE Ash, 5
	INSTR 24
	NOTE Ash, 5
	INSTR 16
	NOTE F_, 5
	INSTR 24
	NOTE F_, 5
	INSTR 17
	NOTE Ash, 5
	NEXT
Pat_7135:
	LEN 28
	INSTR 24
	NOTE D_, 6
	LEN 7
	NOTE C_, 5
	INSTR 9
	NOTE C_, 4
	INSTR 24
	NOTE G_, 4
	INSTR 9
	NOTE G_, 3
	INSTR 24
	NOTE C_, 5
	INSTR 9
	NOTE C_, 4
	INSTR 24
	NOTE G_, 4
	INSTR 9
	NOTE G_, 3
	INSTR 24
	NOTE C_, 5
	INSTR 9
	NOTE C_, 4
	INSTR 24
	NOTE G_, 4
	INSTR 9
	NOTE G_, 3
	INSTR 24
	NOTE C_, 5
	INSTR 9
	NOTE C_, 4
	INSTR 24
	NOTE B_, 4
	INSTR 9
	NOTE B_, 3
	INSTR 24
	NOTE Ash, 4
	INSTR 9
	NOTE Ash, 3
	INSTR 24
	NOTE F_, 4
	INSTR 9
	NOTE F_, 3
	INSTR 24
	NOTE Ash, 4
	INSTR 9
	NOTE Ash, 3
	INSTR 24
	NOTE F_, 4
	INSTR 9
	NOTE F_, 3
	INSTR 24
	NOTE Ash, 4
	INSTR 9
	NOTE Ash, 3
	INSTR 24
	NOTE F_, 4
	INSTR 9
	NOTE F_, 3
	INSTR 24
	NOTE Ash, 4
	INSTR 9
	NOTE Ash, 3
	INSTR 24
	NOTE B_, 4
	INSTR 9
	NOTE B_, 3
	INSTR 24
	NOTE C_, 5
	INSTR 9
	NOTE C_, 4
	INSTR 24
	NOTE G_, 4
	INSTR 9
	NOTE G_, 3
	INSTR 24
	NOTE C_, 5
	INSTR 9
	NOTE C_, 4
	INSTR 24
	NOTE G_, 4
	INSTR 9
	NOTE G_, 3
	INSTR 24
	NOTE C_, 5
	INSTR 9
	NOTE C_, 4
	INSTR 24
	NOTE G_, 4
	INSTR 9
	NOTE G_, 3
	INSTR 24
	NOTE C_, 5
	INSTR 9
	NOTE C_, 4
	INSTR 24
	NOTE B_, 4
	INSTR 9
	NOTE B_, 3
	INSTR 24
	NOTE Ash, 4
	INSTR 9
	NOTE Ash, 3
	INSTR 24
	NOTE F_, 4
	INSTR 9
	NOTE F_, 3
	INSTR 24
	NOTE Ash, 4
	INSTR 9
	NOTE Ash, 3
	INSTR 24
	NOTE F_, 4
	INSTR 9
	NOTE F_, 3
	INSTR 24
	NOTE Ash, 4
	INSTR 9
	NOTE Ash, 3
	INSTR 24
	NOTE F_, 4
	INSTR 9
	NOTE F_, 3
	NEXT
Pat_71B1:
	LEN 7
	INSTR 24
	NOTE D_, 6
	WAIT
	WAIT
	INSTR 16
	NOTE D_, 6
	INSTR 24
	NOTE E_, 6
	INSTR 16
	NOTE D_, 6
	INSTR 24
	NOTE C_, 6
	INSTR 16
	NOTE E_, 6
	INSTR 24
	NOTE G_, 5
	INSTR 16
	NOTE C_, 6
	INSTR 24
	NOTE E_, 5
	INSTR 16
	NOTE G_, 5
	INSTR 24
	NOTE G_, 5
	INSTR 16
	NOTE E_, 5
	INSTR 24
	NOTE C_, 6
	INSTR 16
	NOTE G_, 5
	INSTR 24
	NOTE E_, 6
	WAIT
	INSTR 16
	NOTE C_, 6
	INSTR 24
	NOTE F_, 6
	NOTE D_, 6
	INSTR 16
	NOTE F_, 6
	INSTR 24
	NOTE Ash, 5
	INSTR 16
	NOTE D_, 6
	INSTR 24
	NOTE F_, 5
	INSTR 16
	NOTE Ash, 5
	INSTR 24
	NOTE D_, 5
	INSTR 16
	NOTE F_, 5
	INSTR 24
	NOTE F_, 5
	INSTR 16
	NOTE D_, 5
	INSTR 24
	NOTE Ash, 5
	INSTR 16
	NOTE F_, 5
	INSTR 24
	NOTE D_, 6
	WAIT
	INSTR 16
	NOTE Ash, 5
	INSTR 24
	NOTE Dsh, 6
	NOTE C_, 6
	INSTR 16
	NOTE Dsh, 6
	INSTR 24
	NOTE Gsh, 5
	INSTR 16
	NOTE C_, 6
	INSTR 24
	NOTE Dsh, 5
	INSTR 16
	NOTE Gsh, 5
	INSTR 24
	NOTE C_, 5
	INSTR 16
	NOTE Dsh, 5
	INSTR 24
	NOTE Dsh, 5
	INSTR 16
	NOTE C_, 5
	INSTR 24
	NOTE Gsh, 5
	INSTR 16
	NOTE Dsh, 5
	INSTR 24
	NOTE C_, 6
	WAIT
	INSTR 16
	NOTE Gsh, 5
	INSTR 24
	NOTE D_, 6
	NOTE B_, 5
	INSTR 16
	NOTE D_, 6
	INSTR 24
	NOTE G_, 5
	INSTR 16
	NOTE B_, 5
	INSTR 24
	NOTE B_, 5
	INSTR 16
	NOTE G_, 5
	INSTR 24
	NOTE G_, 5
	INSTR 16
	NOTE B_, 5
	INSTR 24
	NOTE F_, 5
	INSTR 16
	NOTE G_, 5
	INSTR 24
	NOTE G_, 5
	INSTR 16
	NOTE F_, 5
	NEXT
Pat_722B:
	LEN 7
	INSTR 24
	NOTE D_, 6
	WAIT
	WAIT
	INSTR 16
	NOTE D_, 6
	INSTR 24
	NOTE E_, 6
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	INSTR 16
	NOTE E_, 6
	INSTR 24
	NOTE E_, 6
	WAIT
	WAIT
	INSTR 16
	NOTE E_, 6
	INSTR 24
	NOTE D_, 6
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	INSTR 16
	NOTE D_, 6
	INSTR 24
	NOTE D_, 6
	WAIT
	WAIT
	INSTR 16
	NOTE D_, 6
	INSTR 24
	NOTE Dsh, 6
	INSTR 16
	NOTE D_, 6
	INSTR 24
	NOTE D_, 6
	INSTR 16
	NOTE Dsh, 6
	INSTR 24
	NOTE C_, 6
	INSTR 16
	NOTE D_, 6
	INSTR 24
	NOTE D_, 6
	INSTR 16
	NOTE C_, 6
	INSTR 24
	NOTE Dsh, 6
	INSTR 16
	NOTE D_, 6
	INSTR 24
	NOTE F_, 6
	INSTR 16
	NOTE Dsh, 6
	INSTR 24
	NOTE G_, 6
	WAIT
	WAIT
	INSTR 16
	NOTE G_, 6
	INSTR 24
	NOTE D_, 6
	INSTR 16
	NOTE G_, 6
	INSTR 24
	NOTE Dsh, 6
	INSTR 16
	NOTE D_, 6
	INSTR 24
	NOTE D_, 6
	INSTR 16
	NOTE Dsh, 6
	INSTR 24
	NOTE Dsh, 6
	INSTR 16
	NOTE D_, 6
	INSTR 24
	NOTE D_, 6
	WAIT
	WAIT
	INSTR 16
	NOTE D_, 6
	NEXT
Pat_728F:
	RELEASE $00
	LEN 7
	WAIT
	WAIT
	WAIT
	REST
	INSTR 23
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	REST
	NOTE C_, 4
	NOTE C_, 4
	NOTE Dsh, 4
	WAIT
	WAIT
	WAIT
	WAIT
	REST
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	REST
	NOTE C_, 4
	NOTE C_, 4
	NOTE Dsh, 4
	WAIT
	WAIT
	WAIT
	WAIT
	REST
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	REST
	NOTE E_, 4
	NOTE E_, 4
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	REST
	NOTE G_, 4
	NOTE G_, 4
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	REST
	NOTE E_, 4
	NOTE E_, 4
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	NEXT
Pat_72D4:
	LEN 14
	WAIT
	WAIT
	RELEASE $05, $D1
	INSTR 23
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE E_, 4
	WAIT
	NOTE G_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE E_, 4
	WAIT
	NOTE G_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE E_, 4
	WAIT
	NOTE G_, 4
	NOTE C_, 5
	LENGTH $54
	NOTE B_, 4
	NEXT
Pat_72F7:
	LEN 14
	INSTR 23
	NOTE C_, 5
	NOTE Csh, 5
	NOTE D_, 5
	LEN 7
	WAIT
	NOTE E_, 5
	LEN 14
	NOTE D_, 5
	NOTE G_, 4
	NOTE B_, 4
	WAIT
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	LEN 7
	WAIT
	NOTE D_, 5
	LEN 14
	NOTE C_, 5
	NOTE F_, 4
	NOTE A_, 4
	WAIT
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 7
	NOTE C_, 5
	WAIT
	WAIT
	NOTE A_, 4
	LEN 14
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE E_, 4
	LENGTH $38
	NOTE E_, 4
	NEXT
Pat_7323:
	LEN 14
	WAIT
	INSTR 23
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	WAIT
	WAIT
	NOTE F_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	WAIT
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE B_, 4
	NOTE G_, 4
	LEN 7
	NOTE E_, 5
	WAIT
	WAIT
	NOTE D_, 5
	LENGTH $54
	NOTE C_, 5
	NEXT

; Instrument table 1 (songs 1-4): instrument n = entry n.
InstrTable1:
	dw Instr_737A
	dw Instr_7381
	dw Instr_738C
	dw Instr_737A
	dw Instr_737A
	dw Instr_737A
	dw Instr_737A
	dw Instr_737A
	dw Instr_7396
	dw Instr_739D
	dw Instr_73A4
	dw Instr_73AB
	dw Instr_73B8
	dw Instr_73C5
	dw Instr_737A
	dw Instr_73CF
	dw Instr_73D3
	dw Instr_73DC
	dw Instr_737A
	dw Instr_737A
	dw Instr_73E5
	dw Instr_73EF
	dw Instr_737A
	dw Instr_73F9
	dw Instr_7402
	dw Instr_737A
Instr_737A:
	NOISE_SEQ2
	HWENV $D1, $00
	GLIDE $FE
	END
Instr_7381:
	NOISE_SEQ2
	VOLENV 15, $15, $2F, $11
	GLIDE $FE
	WAVE Wave_5EDF
	END
Instr_738C:
	DUTY_75
	HWENV $F1, $00
	ARP 0
	VIBRATO $0A, $03, $05
	END
Instr_7396:
	PAN_L
	ARP 0
	DUTY_12
	HWENV $F1, $00
	END
Instr_739D:
	PAN_C
	ARP 0
	DUTY_12
	HWENV $F1, $00
	END
Instr_73A4:
	PAN_R
	ARP 0
	DUTY_12
	HWENV $F1, $00
	END
Instr_73AB:
	VOLENV 15, $11, $1F, $15
	VIBRATO $0E, $06, $04
	ARP 3
	WAVE Wave_5EEF
	END
Instr_73B8:
	VOLENV 15, $10, $1E, $12
	VIBRATO $0E, $06, $05
	ARP 3
	WAVE Wave_5EEF
	END
Instr_73C5:
	HWENV $90, $00
	AUTOPAN $07
	VIBRATO $1C, $01, $05
	END
Instr_73CF:
	HWENV $D2, $00
	END
Instr_73D3:
	VIBRATO $1C, $01, $05
	PAN_R
	HWENV $30, $00
	END
Instr_73DC:
	VIBRATO $1C, $01, $05
	PAN_L
	HWENV $30, $00
	END
Instr_73E5:
	DUTY_75
	AUTOPAN $01
	AUTODUTY $02
	HWENV $F2, $00
	ARP 1
	END
Instr_73EF:
	DUTY_75
	AUTOPAN $01
	AUTODUTY $02
	HWENV $F2, $00
	ARP 2
	END
Instr_73F9:
	VIBRATO $05, $01, $04
	ARP 3
	HWENV $D0, $00
	END
Instr_7402:
	DUTY_75
	VIBRATO $05, $01, $04
	ARP 3
	HWENV $D0, $00
	END

; Arpeggio table 1.
ArpTable1:
	dw Arp_7416
	dw Arp_7419
	dw Arp_741D
	dw Arp_7421
	dw Arp_7425
Arp_7416:
	db $0C
	db $00
	db ARP_HOLD
Arp_7419:
	db $00
	db $03
	db $07
	db ARP_LOOP
Arp_741D:
	db $00
	db $04
	db $07
	db ARP_LOOP
Arp_7421:
	db $18
	db $0C
	db $00
	db ARP_HOLD
Arp_7425:
	db $00
	db $00
	db $00
	db $0C
	db $0C
	db $0C
	db ARP_LOOP
Drums_742C:
	db $05
	db $04
	db $01
	db $05
	db $05
	db $01
	db $01
	db $05
	db DRUM_LOOP

; Drum pattern that nothing uses.
Drums_7435_unused:
	db $02
	db $04
	db $01
	db $05
	db $02
	db $01
	db $01
	db $05
	db DRUM_LOOP

; PlaySong5: uses instrument table 2 / arpeggio table 2.
PlaySong5:
	push de
	push bc
	push hl
	call StopAll
	ld de, Song5_Ch3
	call StartMusicCh3
	ld de, Song5_Ch2
	call StartMusicCh2
	ld de, Song5_Ch1
	call StartMusicCh1
	ld a, LOW(InstrTable2 - 2)
	ld [wInstrTable], a
	ld a, HIGH(InstrTable2 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(ArpTable2)
	ld [wArpTable], a
	ld a, HIGH(ArpTable2)
	ld [wArpTableHi], a
	ld a, $77
	ldh [rNR50], a
	pop hl
	pop bc
	pop de
	ret
Song5_Ch3:
	dw Pat_74C9
	dw Pat_754C
	dw Pat_7581
	dw Pat_75B3
	dw Pat_75BD
	dw Pat_74CE
	dw Pat_74CE
	dw Pat_74CE
	dw Pat_74CE
	dw Pat_7633
	dw Pat_75F5
Ord_7488:
	dw Pat_74CE
	ORDER_LOOP Ord_7488
Song5_Ch2:
	dw Pat_770D
	dw Pat_7671
	dw Pat_7695
	dw Pat_76BC
	dw Pat_76E5
	dw Pat_7671
	dw Pat_7695
	dw Pat_76BC
	dw Pat_76E5
	dw Pat_7808
	dw Pat_771B
	dw Pat_7735
	dw Pat_779F
Ord_74A8:
	dw Pat_7735
	dw Pat_779F
	ORDER_LOOP Ord_74A8
Song5_Ch1:
	dw Pat_7826
	dw Pat_7826
	dw Pat_7826
	dw Pat_7911
	dw Pat_78E4
	dw Pat_78FE
	dw Pat_78FE
Ord_74BE:
	dw Pat_74C6
	dw Pat_7826
	ORDER_LOOP Ord_74BE
Pat_74C6:
	TRANSPOSE $02
	NEXT
Pat_74C9:
	DRUMS $12, Drums_742C
	NEXT
Pat_74CE:
	LEN 9
	INSTR 3
	NOTE B_, 3
	WAIT
	INSTR 3
	NOTE G_, 3
	INSTR 3
	NOTE F_, 3
	INSTR 11
	LEN 18
	NOTE F_, 2
	INSTR 12
	NOTE F_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 11
	NOTE F_, 2
	NOTE F_, 2
	INSTR 12
	NOTE F_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 12
	NOTE F_, 3
	INSTR 11
	NOTE E_, 2
	INSTR 12
	NOTE E_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 11
	NOTE E_, 2
	NOTE E_, 2
	INSTR 12
	NOTE E_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 12
	NOTE E_, 3
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 11
	NOTE D_, 2
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 12
	NOTE D_, 3
	INSTR 11
	NOTE C_, 2
	INSTR 12
	NOTE C_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 11
	NOTE C_, 2
	NOTE C_, 2
	INSTR 12
	NOTE C_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 12
	NOTE C_, 3
	INSTR 11
	NOTE G_, 2
	INSTR 12
	NOTE G_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 11
	NOTE G_, 2
	NOTE G_, 2
	INSTR 12
	NOTE G_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 12
	NOTE G_, 3
	INSTR 11
	NOTE F_, 2
	INSTR 12
	NOTE F_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 11
	NOTE F_, 2
	NOTE F_, 2
	INSTR 12
	NOTE F_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 12
	NOTE F_, 3
	INSTR 11
	NOTE C_, 2
	INSTR 12
	NOTE C_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 11
	NOTE C_, 2
	NOTE C_, 2
	INSTR 12
	NOTE C_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 12
	NOTE C_, 3
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE C_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 11
	NOTE C_, 3
	NOTE C_, 3
	INSTR 3
	NOTE B_, 3
	NEXT
Pat_754C:
	LEN 9
	WAIT
	WAIT
	WAIT
Pat_7550:
	WAIT
	INSTR 11
	LEN 18
	NOTE F_, 2
	WAIT
	INSTR 0
	NOTE A_, 3
	INSTR 11
	NOTE F_, 2
	NOTE F_, 2
	WAIT
	INSTR 0
	NOTE A_, 3
	WAIT
	INSTR 11
	NOTE E_, 2
	WAIT
	INSTR 0
	NOTE A_, 3
	INSTR 11
	NOTE E_, 2
	NOTE E_, 2
	WAIT
	INSTR 0
	NOTE A_, 3
	WAIT
	INSTR 11
	NOTE D_, 2
	WAIT
	INSTR 0
	NOTE A_, 3
	INSTR 11
	NOTE D_, 2
	NOTE D_, 2
	WAIT
	INSTR 0
	NOTE A_, 3
	WAIT
	INSTR 11
	NOTE C_, 2
	WAIT
	INSTR 0
	NOTE A_, 3
	INSTR 11
	NOTE C_, 2
	NOTE C_, 2
	INSTR 0
	NOTE A_, 3
	NEXT
Pat_7581:
	INSTR 0
	NOTE A_, 3
	WAIT
	INSTR 11
	NOTE G_, 2
	WAIT
	INSTR 0
	NOTE A_, 3
	INSTR 11
	NOTE G_, 2
	NOTE G_, 2
	WAIT
	INSTR 0
	NOTE A_, 3
	WAIT
	INSTR 11
	NOTE F_, 2
	WAIT
	INSTR 0
	NOTE A_, 3
	INSTR 11
	NOTE F_, 2
	NOTE F_, 2
	WAIT
	INSTR 0
	NOTE A_, 3
	WAIT
	INSTR 11
	NOTE C_, 2
	WAIT
	INSTR 0
	NOTE A_, 3
	INSTR 11
	NOTE C_, 2
	NOTE C_, 2
	WAIT
	INSTR 0
	NOTE A_, 3
	WAIT
	INSTR 11
	NOTE C_, 2
	WAIT
	INSTR 0
	NOTE A_, 3
	INSTR 11
	NOTE C_, 2
	NOTE C_, 2
	INSTR 0
	NOTE A_, 3
	NEXT
Pat_75B3:
	LEN 9
	INSTR 0
	NOTE A_, 3
	INSTR 0
	NOTE A_, 3
	INSTR 0
	NOTE A_, 3
	PAT_GOTO Pat_7550
Pat_75BD:
	LEN 9
	INSTR 0
	NOTE A_, 3
	WAIT
	INSTR 0
	NOTE A_, 3
	INSTR 0
	NOTE A_, 3
	INSTR 11
	LEN 18
	NOTE G_, 2
	WAIT
	INSTR 0
	NOTE A_, 3
	INSTR 11
	NOTE G_, 2
	NOTE G_, 2
	WAIT
	INSTR 0
	NOTE A_, 3
	WAIT
	INSTR 11
	NOTE F_, 2
	WAIT
	INSTR 0
	NOTE A_, 3
	INSTR 11
	NOTE F_, 2
	NOTE F_, 2
	WAIT
	INSTR 0
	NOTE A_, 3
	WAIT
	INSTR 11
	NOTE C_, 2
	WAIT
	INSTR 0
	NOTE A_, 3
	INSTR 11
	NOTE C_, 2
	NOTE C_, 2
	WAIT
	INSTR 0
	NOTE A_, 3
	WAIT
	INSTR 11
	NOTE C_, 2
	WAIT
	INSTR 0
	NOTE A_, 3
	INSTR 11
	NOTE C_, 2
	NOTE C_, 2
	INSTR 3
	NOTE B_, 3
	NEXT
Pat_75F5:
	LEN 18
	INSTR 1
	NOTE A_, 3
	INSTR 12
	NOTE C_, 3
	INSTR 11
	NOTE G_, 2
	INSTR 12
	NOTE G_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 11
	NOTE G_, 2
	NOTE G_, 2
	INSTR 12
	NOTE G_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 12
	NOTE G_, 3
	INSTR 11
	NOTE C_, 2
	INSTR 12
	NOTE C_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 11
	NOTE C_, 2
	NOTE C_, 2
	INSTR 12
	NOTE C_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 12
	NOTE C_, 3
	INSTR 11
	NOTE F_, 2
	INSTR 12
	NOTE F_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 11
	NOTE F_, 2
	NOTE F_, 2
	INSTR 12
	NOTE F_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 12
	NOTE F_, 3
	INSTR 11
	NOTE C_, 2
	INSTR 12
	NOTE C_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 11
	NOTE C_, 2
	NOTE C_, 2
	INSTR 3
	NOTE B_, 3
	NEXT
Pat_7633:
	LEN 18
	INSTR 1
	NOTE A_, 3
	INSTR 12
	NOTE C_, 3
	INSTR 11
	NOTE G_, 2
	INSTR 12
	NOTE G_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 11
	NOTE G_, 2
	NOTE G_, 2
	INSTR 12
	NOTE G_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 12
	NOTE G_, 3
	INSTR 11
	NOTE C_, 2
	INSTR 12
	NOTE C_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 11
	NOTE C_, 2
	NOTE C_, 2
	INSTR 12
	NOTE C_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 12
	NOTE C_, 3
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 11
	NOTE D_, 2
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 12
	NOTE D_, 3
	INSTR 11
	NOTE F_, 2
	INSTR 12
	NOTE F_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 11
	NOTE F_, 2
	NOTE F_, 2
	INSTR 12
	NOTE F_, 3
	NEXT
Pat_7671:
	RELEASE $09, $93
	LENGTH $24
	INSTR 18
	NOTE C_, 5
	NOTE C_, 6
	WAIT
	NOTE A_, 5
	WAIT
	LEN 9
	NOTE A_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE C_, 6
	NOTE D_, 6
	NOTE C_, 6
	NOTE D_, 6
	NOTE E_, 6
	LEN 18
	NOTE F_, 6
	NOTE E_, 6
	NOTE D_, 6
	NOTE C_, 6
	LENGTH $5A
	NOTE A_, 5
	LEN 18
	NOTE G_, 5
	NOTE A_, 5
	NOTE C_, 6
	LENGTH $6C
	NOTE G_, 5
	NEXT
Pat_7695:
	INSTR 18
	LENGTH $24
	NOTE D_, 5
	INSTR 19
	NOTE C_, 6
	WAIT
	INSTR 18
	NOTE Ash, 5
	WAIT
	INSTR 19
	NOTE Ash, 5
	WAIT
	INSTR 18
	NOTE A_, 5
	WAIT
	INSTR 19
	NOTE Ash, 5
	WAIT
	INSTR 18
	NOTE G_, 5
	LEN 9
	WAIT
	WAIT
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NEXT
Pat_76BC:
	LEN 18
	INSTR 18
	NOTE Ash, 4
	NOTE A_, 4
	INSTR 19
	LENGTH $24
	NOTE Ash, 4
	WAIT
	INSTR 18
	NOTE A_, 4
	WAIT
	INSTR 19
	NOTE Ash, 4
	WAIT
	INSTR 18
	NOTE G_, 4
	WAIT
	LEN 9
	NOTE A_, 4
	NOTE G_, 4
	LENGTH $48
	NOTE A_, 4
	LEN 9
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	LENGTH $36
	NOTE G_, 4
	LEN 18
	NOTE D_, 4
	NEXT
Pat_76E5:
	NOTE F_, 4
	NOTE G_, 4
	LENGTH $24
	NOTE D_, 4
	NOTE Ash, 4
	INSTR 19
	NOTE Ash, 4
	INSTR 18
	NOTE D_, 5
	INSTR 19
	NOTE Dsh, 5
	INSTR 18
	NOTE E_, 5
	NOTE D_, 5
	NOTE E_, 5
	INSTR 19
	NOTE F_, 5
	WAIT
	INSTR 18
	NOTE E_, 5
	LEN 9
	WAIT
	WAIT
	NOTE E_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	WAIT
	NOTE E_, 4
	WAIT
	INSTR 18
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE C_, 4
	NEXT
Pat_770D:
	CH_TRANSPOSE $F4
	DUTY_50
	HWENV $F1, $06, $50
	VIBRATO $1C, $03, $05
	PAT_GOTO Pat_782A
Pat_771B:
	INSTR 18
	LENGTH $48
	NOTE C_, 5
	LENGTH $24
	NOTE Ash, 4
	INSTR 19
	NOTE Ash, 4
	INSTR 18
	NOTE D_, 5
	NOTE C_, 5
	NOTE D_, 5
	INSTR 19
	NOTE Dsh, 5
	INSTR 18
	NOTE E_, 5
	LENGTH $90
	NOTE A_, 4
	LENGTH $5A
	NOTE G_, 4
	LEN 18
	WAIT2
	NEXT
Pat_7735:
	LEN 9
	RELEASE $00
	WAIT
	WAIT
	WAIT
	WAIT
	INSTR 4
	NOTE F_, 4
	INSTR 17
	NOTE C_, 4
	WAIT
	WAIT
	INSTR 4
	NOTE F_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 4
	NOTE F_, 4
	INSTR 17
	NOTE C_, 4
	WAIT
	WAIT
	INSTR 4
	NOTE F_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 4
	NOTE F_, 4
	INSTR 17
	NOTE C_, 4
	WAIT
	WAIT
	INSTR 4
	NOTE F_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 4
	NOTE F_, 4
	INSTR 17
	NOTE C_, 4
	WAIT
	WAIT
	INSTR 4
	NOTE F_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 5
	NOTE D_, 4
	INSTR 17
	NOTE A_, 3
	WAIT
	WAIT
	INSTR 5
	NOTE D_, 4
	INSTR 17
	NOTE A_, 3
	INSTR 5
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 17
	NOTE A_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 17
	NOTE A_, 3
	WAIT
	WAIT
	INSTR 5
	NOTE D_, 4
	INSTR 17
	NOTE A_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 17
	NOTE G_, 3
	WAIT
	WAIT
	INSTR 4
	NOTE C_, 4
	INSTR 17
	NOTE G_, 3
	INSTR 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	INSTR 17
	NOTE G_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 17
	NOTE G_, 3
	NEXT
Pat_779F:
	WAIT
	WAIT
	INSTR 4
	NOTE C_, 4
	INSTR 17
	NOTE G_, 3
	INSTR 5
	NOTE G_, 4
	INSTR 17
	NOTE D_, 4
	WAIT
	WAIT
	INSTR 5
	NOTE G_, 4
	INSTR 17
	NOTE D_, 4
	INSTR 5
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	INSTR 17
	NOTE D_, 4
	INSTR 5
	NOTE G_, 4
	INSTR 17
	NOTE D_, 4
	WAIT
	WAIT
	INSTR 5
	NOTE G_, 4
	INSTR 17
	NOTE D_, 4
	INSTR 4
	NOTE F_, 4
	INSTR 17
	NOTE C_, 4
	WAIT
	WAIT
	INSTR 4
	NOTE F_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 4
	NOTE F_, 4
	INSTR 17
	NOTE C_, 4
	WAIT
	WAIT
	INSTR 4
	NOTE F_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 4
	NOTE C_, 4
	INSTR 17
	NOTE G_, 3
	WAIT
	WAIT
	INSTR 4
	NOTE C_, 4
	INSTR 17
	NOTE G_, 3
	INSTR 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	INSTR 17
	NOTE G_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 17
	NOTE G_, 3
	WAIT
	WAIT
	INSTR 4
	NOTE C_, 4
	INSTR 17
	NOTE G_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 17
	NOTE G_, 3
	WAIT
	WAIT
	INSTR 4
	NOTE C_, 4
	INSTR 17
	NOTE G_, 3
	INSTR 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	INSTR 17
	NOTE G_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 17
	NOTE G_, 3
	NEXT
Pat_7808:
	LEN 18
	INSTR 18
	NOTE F_, 4
	NOTE G_, 4
	LENGTH $24
	NOTE D_, 4
	NOTE Ash, 4
	INSTR 19
	NOTE Ash, 4
	INSTR 18
	NOTE D_, 5
	NOTE C_, 5
	NOTE D_, 5
	INSTR 19
	NOTE Dsh, 5
	INSTR 18
	NOTE E_, 5
	WAIT
	NOTE D_, 5
	INSTR 19
	NOTE D_, 5
	INSTR 18
	NOTE F_, 5
	INSTR 19
	NOTE G_, 5
	INSTR 18
	NOTE G_, 5
	NOTE F_, 5
	NEXT
Pat_7826:
	RELEASE $09, $F3
	INSTR 13
Pat_782A:
	LENGTH $24
	NOTE C_, 4
	ARP 4
	LENGTH $5A
	NOTE G_, 4
	ARP_OFF
	LEN 18
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	LENGTH $5A
	NOTE G_, 4
	LEN 18
	NOTE F_, 4
	NOTE G_, 4
	NOTE C_, 5
	LENGTH $5A
	NOTE F_, 4
	LEN 18
	NOTE E_, 4
	NOTE F_, 4
	NOTE A_, 4
	LENGTH $5A
	NOTE E_, 4
	LEN 18
	WAIT2
	NOTE D_, 4
	WAIT2
	ARP 4
	LENGTH $5A
	NOTE Gsh, 4
	LEN 18
	ARP_OFF
	NOTE A_, 4
	NOTE Ash, 4
	NOTE D_, 5
	LENGTH $5A
	NOTE A_, 4
	LEN 18
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	LENGTH $EA
	NOTE G_, 4
	LEN 18
	WAIT2
	NOTE C_, 5
	WAIT
	LEN 9
	NOTE A_, 5
	NOTE G_, 5
	LENGTH $48
	NOTE A_, 5
	LEN 18
	NOTE G_, 5
	NOTE A_, 5
	NOTE C_, 6
	LEN 9
	NOTE G_, 5
	NOTE F_, 5
	LENGTH $48
	NOTE G_, 5
	LEN 18
	NOTE F_, 5
	NOTE G_, 5
	NOTE C_, 6
	LEN 9
	NOTE F_, 5
	NOTE E_, 5
	LENGTH $48
	NOTE F_, 5
	LEN 9
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE E_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT2
	NOTE D_, 5
	WAIT2
	NOTE A_, 4
	WAIT2
	LENGTH $36
	NOTE Ash, 4
	LENGTH $24
	NOTE D_, 5
	ARP 4
	NOTE D_, 5
	ARP_OFF
	NOTE F_, 5
	ARP 4
	NOTE G_, 5
	ARP_OFF
	NOTE G_, 5
	NOTE F_, 5
	NOTE G_, 5
	ARP 4
	LENGTH $6C
	NOTE Ash, 5
	LEN 9
	WAIT2
	WAIT
	ARP_OFF
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	WAIT
	WAIT
	WAIT2
	NOTE C_, 5
	WAIT
	WAIT2
	WAIT
	CH_TRANSPOSE $00
	NEXT

; Pattern that no order list uses.
Pat_78BA_unused:
	LEN 9
	INSTR 13
	NOTE A_, 4
	WAIT2
	LENGTH $24
	NOTE Ash, 4
	LEN 18
	WAIT2
	LENGTH $24
	NOTE D_, 5
	INSTR 14
	NOTE D_, 5
	INSTR 13
	NOTE F_, 5
	INSTR 14
	NOTE G_, 5
	INSTR 13
	NOTE G_, 5
	NOTE F_, 5
	NOTE G_, 5
	INSTR 14
	LENGTH $6C
	NOTE Ash, 5
	LEN 9
	INSTR 13
	NOTE C_, 6
	WAIT
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	LEN 18
	NOTE E_, 5
	WAIT2
	NOTE C_, 5
	WAIT2
	NEXT
Pat_78E4:
	LENGTH $48
	INSTR 13
	NOTE F_, 5
	LENGTH $24
	NOTE D_, 5
	INSTR 14
	NOTE D_, 5
	INSTR 13
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	INSTR 14
	NOTE G_, 5
	INSTR 13
	NOTE G_, 5
	LENGTH $90
	NOTE F_, 5
	LENGTH $5A
	NOTE E_, 5
	LEN 18
	WAIT2
	NEXT
Pat_78FE:
	RELEASE $00
	LENGTH $24
	WAIT
	INSTR 17
	LENGTH $90
	NOTE A_, 3
	NOTE A_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE E_, 3
	LENGTH $6C
	WAIT
	NEXT
Pat_7911:
	LEN 9
	INSTR 13
	NOTE A_, 4
	WAIT2
	LEN 18
	NOTE Ash, 4
	WAIT
	WAIT2
	LENGTH $24
	NOTE D_, 5
	INSTR 14
	NOTE D_, 5
	INSTR 13
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	INSTR 14
	NOTE G_, 5
	INSTR 13
	NOTE G_, 5
	WAIT
	NOTE F_, 5
	INSTR 14
	NOTE F_, 5
	INSTR 13
	NOTE A_, 5
	INSTR 14
	NOTE Ash, 5
	INSTR 13
	NOTE Ash, 5
	NOTE A_, 5
	NEXT

; Instrument table 2 (song 5).
InstrTable2:
	dw Instr_7966
	dw Instr_796F
	dw Instr_7966
	dw Instr_797A
	dw Instr_7985
	dw Instr_798C
	dw Instr_7966
	dw Instr_7966
	dw Instr_7966
	dw Instr_7966
	dw Instr_7966
	dw Instr_7993
	dw Instr_79A0
	dw Instr_79AD
	dw Instr_79B5
	dw Instr_7966
	dw Instr_79BE
	dw Instr_79C6
	dw Instr_79CF
	dw Instr_79D8
	dw Instr_7966
	dw Instr_7966
	dw Instr_7966
	dw Instr_7966
	dw Instr_7966
	dw Instr_7966
Instr_7966:
	NOISE_SEQ3
	VOLENV 10, $11, $2F, $11
	WAVE Wave_5EDF
	END
Instr_796F:
	NOISE_SEQ2
	VOLENV 15, $03, $1F, $11
	GLIDE $FF
	WAVE Wave_5EDF
	END
Instr_797A:
	NOISE_SEQ2
	VOLENV 15, $00, $1F, $12
	GLIDE $FF
	WAVE Wave_5EDF
	END
Instr_7985:
	HWENV $F1, $00
	AUTOPAN $01
	ARP 2
	END
Instr_798C:
	HWENV $F1, $00
	AUTOPAN $01
	ARP 1
	END
Instr_7993:
	VOLENV 15, $11, $1F, $15
	VIBRATO $0E, $06, $04
	ARP 0
	WAVE Wave_5EEF
	END
Instr_79A0:
	VOLENV 15, $10, $1E, $12
	VIBRATO $0E, $06, $05
	ARP 0
	WAVE Wave_5EEF
	END
Instr_79AD:
	HWENV $99, $00
	VIBRATO $1C, $01, $06
	END
Instr_79B5:
	HWENV $99, $00
	VIBRATO $1C, $01, $06
	ARP 4
	END
Instr_79BE:
	VIBRATO $1C, $01, $05
	HWENV $20, $00
	END
Instr_79C6:
	DUTY_75
	VIBRATO $1C, $01, $05
	HWENV $60, $00
	END
Instr_79CF:
	HWENV $98, $09, $90
	VIBRATO $1C, $01, $05
	END
Instr_79D8:
	HWENV $98, $09, $90
	VIBRATO $1C, $01, $05
	ARP 4
	END

; Arpeggio table 2.
ArpTable2:
	dw Arp_79EC
	dw Arp_79EF
	dw Arp_79F3
	dw Arp_79F7
	dw Arp_79F7
Arp_79EC:
	db $0C
	db $00
	db ARP_HOLD
Arp_79EF:
	db $00
	db $03
	db $07
	db ARP_LOOP
Arp_79F3:
	db $00
	db $04
	db $07
	db ARP_LOOP
Arp_79F7:
	db $00
	db $00
	db $00
	db $01
	db $01
	db $01
	db $01
	db $02
	db $02
	db ARP_HOLD
