; =====================================================================
; The Adventures of Pinocchio (J) - 1993 prototype, internal title "INFREY QUEST" - Game Boy
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 3 (early variant)
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o pinocchio.o Pinocchio_SoundDriver.asm
;   rgblink -o pinocchio.gb pinocchio.o
;   python tools/cmp_banked.py pinocchio.gb "Adventures of Pinocchio, The (J).gb" <ranges listed in the doc>
; (the driver lives in ROM bank 2; the linked file only matches in the listed ranges)
;
; Documentation: Pinocchio_SoundDriver.md / AJG_SoundEngine_Family.md
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
; notes are bytes $00-$5F
MACRO LEN       ; note length in ticks, 1-51
	db $CC + \1
ENDM
MACRO VOL       ; start volume of following notes, 0-15 (software envelope mode)
	db $AD + \1
ENDM
MACRO VOLENV    ; start volume + envelope: atk (lo=count hi=step), dec (lo=count hi=step), rates (hi=atk lo=dec)
	db $BD + \1, \2, \3, \4
ENDM
MACRO INSTR     ; instrument n = entry n + 1 of the current song's instrument table
	db $84 + \1
ENDM
MACRO ARP       ; arpeggio n of the current song's arpeggio table
	db $9E + \1
ENDM
MACRO HWENV     ; HWENV env, 0 | HWENV env, ticks, env2  (hardware envelope mode)
	db $75, \1, \2
	IF _NARG > 2
		db \3
	ENDC
ENDM
MACRO RELEASE   ; RELEASE 0 = off | RELEASE minlen << 4 | ticks_left, env
	db $7E, \1
	IF _NARG > 1
		db \2
	ENDC
ENDM
MACRO GLIDE
	db $60
	db \1
ENDM
MACRO GLIDE_OFF
	db $61
ENDM
MACRO WAIT2
	db $62
ENDM
MACRO VIBRATO
	db $63
	db \1
	db \2
	db \3
ENDM
MACRO VIB_OFF
	db $64
ENDM
MACRO WAIT
	db $65
ENDM
MACRO REST
	db $66
ENDM
MACRO STOP_ALL
	db $67
ENDM
MACRO END
	db $68
ENDM
MACRO TRANSPOSE
	db $69
	db \1
ENDM
MACRO NEXT
	db $6A
ENDM
MACRO ORDER_JUMP
	db $6B
	dw \1
ENDM
MACRO LENGTH
	db $6C
	db \1
ENDM
MACRO DRUMS
	db $6D
	db \1
	dw \2
ENDM
MACRO DRUMS_OFF
	db $6E
ENDM
MACRO PAN_C
	db $6F
ENDM
MACRO PAN_R
	db $70
ENDM
MACRO PAN_L
	db $71
ENDM
MACRO DUTY_50
	db $72
ENDM
MACRO DUTY_75
	db $73
ENDM
MACRO DUTY_12
	db $74
ENDM
MACRO AUTOPAN
	db $76
	db \1
ENDM
MACRO AUTODUTY
	db $77
	db \1
ENDM
MACRO FADE
	db $78
	db \1
	dw \2
ENDM
MACRO FADE_OFF
	db $79
ENDM
MACRO WAVE
	db $7A
	dw \1
ENDM
MACRO PORTA
	db $7B
	db \1
	db \2
ENDM
MACRO PORTA_OFF
	db $7C
ENDM
MACRO CH_TRANSPOSE
	db $7D
	db \1
ENDM
MACRO ARP_OFF
	db $7F
ENDM
MACRO PAT_GOTO
	db $80
	dw \1
ENDM
MACRO PAT_CALL
	db $81
	dw \1
ENDM
MACRO CALL_CODE
	db $82
	dw \1
ENDM
MACRO ENV_DIV
	db $83
	db \1
ENDM
; ---- order lists ----
MACRO ORDER_LOOP  ; end of an order list: 0, then the order position to continue from
	dw 0, \1
ENDM
; ---- arpeggio and NR50 tables ----
DEF ARP_LOOP EQU $6A   ; restart the table
DEF ARP_HOLD EQU $FF   ; stay on the previous entry
DEF FADE_LOOP EQU $6A
DEF FADE_END EQU $FF
; ---- drum patterns (one step per drum tick) ----
DEF DRUM_LOOP EQU $FF

; ---- RAM / HRAM ----
DEF wCh1 EQU $C100
DEF wCh2 EQU $C200
DEF wCh3 EQU $C300
DEF wSfx EQU $C400
DEF wShFreqHi1 EQU $FF91
DEF wShFreqHi2 EQU $FF92
DEF wShFreqHi3 EQU $FF93
DEF wShNR32 EQU $FF94
DEF wInInstr EQU $FF95
DEF wTranspose EQU $FF96
DEF wNoisePan EQU $FF97
DEF wDrumHold EQU $FF98
DEF wInstrTable EQU $FF99
DEF wInstrTableHi EQU $FF9A
DEF wArpTable EQU $FF9B
DEF wArpTableHi EQU $FF9C
DEF wMusicWave EQU $FF9D
DEF wMusicWaveHi EQU $FF9E
DEF wPaused EQU $FF9F
DEF wStereo EQU $FFA0
DEF wDrumPatHi EQU $FFA1
DEF wDrumPatLo EQU $FFA2
DEF wDrumPos EQU $FFA3
DEF wDrumsOn EQU $FFA4
DEF wDrumTempo EQU $FFA5
DEF wDrumTimer EQU $FFA6
DEF wNoiseNR43Hi EQU $FFA7
DEF wNoiseNR43Lo EQU $FFA8
DEF wNoiseNR42Hi EQU $FFA9
DEF wNoiseNR42Lo EQU $FFAA
DEF wNoisePos EQU $FFAB
DEF wNoiseOn EQU $FFAC
DEF wNoiseAtten EQU $FFAD
DEF wNoiseTimer EQU $FFAE
DEF wNoiseSpeed EQU $FFAF
DEF wFadePtr EQU $FFB0
DEF wFadePtrHi EQU $FFB1
DEF wFadePos EQU $FFB2
DEF wFadeTimer EQU $FFB3
DEF wFadeSpeed EQU $FFB4
DEF wFadeOn EQU $FFB5



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


; rst $00: jp MemCopy (game code; copy bc bytes hl -> de)
SECTION "RST00", ROM0[$0000]

Rst00_MemCopy:
	jp MemCopy

; rst $08: hl = [hl] (read a word)
SECTION "RST08", ROM0[$0008]

Rst08_ReadWord:
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ret

; rst $18: hl += a
SECTION "RST18", ROM0[$0018]

Rst18_AddHLA:
	add a, l
	ld l, a
	adc a, h
	sub l
	ld h, a
	ret

; Game MemCopy: copy bc bytes hl -> de
SECTION "MemCopy", ROM0[$0BA4]

MemCopy:
	ld a, [hli]
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, MemCopy
	ret

; Game helper: push bc / ret (jump to bc); the driver calls it to run a command handler
SECTION "CallBC", ROM0[$0BE7]

CallBC_Bank0:
	push bc
	ret

SECTION "SoundDriver", ROMX[$4000], BANK[2]


; SndResume / SndPause: wPaused = 0 / 1. Pausing silences CH1-CH4 (NRx2 = 0, trigger)
; and jumps to RestoreMusicWave with whatever H the caller left (see the doc, quirks).
; While paused only the SFX page is ticked and output.
SndResume:
	xor a
	ldh [wPaused], a
	ret
SndPause:
	ld a, $01
	ldh [wPaused], a
	dec a
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR32], a
	ldh [rNR42], a
	ld a, $80
	ldh [rNR14], a
	ldh [rNR24], a
	ldh [rNR34], a
	ldh [rNR44], a
	jp RestoreMusicWave

; SndUpdate (timer interrupt, 53.89 Hz): NR50 fade, then tick the four pages (or only
; the SFX page while paused), drums + noise sequence, output; finally NR51 from the
; pages' pan bytes and wNoisePan - or $FF while wStereo = 0 (always, in this game).
SndUpdate:
	call DoFade
	ldh a, [wPaused]
	and a
	jr z, TickMusic
	ld h, $C4
	call ChannelTick
	ld h, $C4
	call OutputChannel
	jr SetNR51
TickMusic:
	ld hl, wCh1
	call ChannelTick
	inc h
	call ChannelTick
	inc h
	call ChannelTick
	inc h
	call ChannelTick
	call DrumTick
	call OutputAll
SetNR51:
	ld hl, $C13D
	ld a, [hl]
	ld c, a
	inc h
	ld a, [hl]
	rlc a
	or c
	ld c, a
	inc h
	inc h
	ld l, $10
	ld a, [hl]
	and a
	jr nz, SetNR51_Ch3
	dec h
SetNR51_Ch3:
	ld l, $3D
	ld a, [hl]
	rlc a
	rlc a
	or c
	ld c, a
	ldh a, [wNoisePan]
	or c
	ld c, a
	ldh a, [wStereo]
	and a
	ld a, c
	jr nz, WriteNR51
	ld a, $FF
WriteNR51:
	ldh [rNR51], a
	ret

; EnvDivider (called from SoftEnvelope): field $3E = reload (hi) / counter (lo).
; While the counter is non-zero it is decremented and the caller's caller resumes
; (pop af): the software envelope then runs once every reload + 1 ticks.
EnvDivider:
	ld l, $3E
	ld a, [hl]
	ld b, a
	and $0F
	jr z, EnvDividerReload
	dec a
	ld c, a
	ld a, b
	and $F0
	or c
	ld [hl], a
	pop af
	ret
EnvDividerReload:
	ld a, b
	and $F0
	ld c, a
	swap a
	or c
	ld [hl], a
	ret

; DrumTick: wDrumHold counts down; wDrumTimer - 1, at 0 one drum step; then the
; noise sequence.
DrumTick:
	ldh a, [wDrumHold]
	and a
	jr z, DrumTimerTick
	dec a
	ldh [wDrumHold], a
DrumTimerTick:
	ld hl, wDrumTimer
	dec [hl]
	call z, DrumStep
	jp NoiseSeqTick

; ChannelTick (h = page, skipped while field $10 = 0): auto-duty, auto-pan, glide,
; envelope, arpeggio, vibrato, portamento, release check; then len - 1 and the
; stream when it reaches 0. (No note-pan in this version.)
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
	call DoPorta
	ld l, $02
	ld e, [hl]
	inc l
	ld d, [hl]
	call CheckRelease
	ld l, $05
	dec [hl]
	ret nz

; ReadStream (de = stream). Notes store the note and pointer, set the period,
; restart the arpeggio, the hardware envelope and the portamento, reload the length,
; reload vibrato, clear the released flag, volume = start volume, split the
; attack/decay bytes. Commands go through StreamCommand and loop.
ReadStream:
	ldh a, [wInInstr]
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
	call PortaNoteOn
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
	ld a, [hli]
	ld c, a
	and $0F
	ld [hli], a
	ld a, c
	swap a
	and $0F
	ld [hl], a
	ret

; StreamCommand: LEN / VOLENV / VOL / ARP / INSTR ranges, else CmdTable.
StreamCommand:
	cp $CD
	jr nc, Cmd_Len
	cp $BD
	jr nc, Cmd_VolEnv
	cp $AD
	jr nc, Cmd_Vol
	cp $9E
	jr nc, Cmd_Arp
	cp $84
	jr nc, Cmd_Instrument
	sub $60
	add a, a
	ld c, a
	add a, $12
	ld c, a
	adc a, $42
	sub c
	ld b, a
	ld a, [bc]
	ld l, a
	inc bc
	ld a, [bc]
	ld b, a
	ld c, l
	call CallBC_Bank0
	jp ReadStream
Cmd_Len:
	sub $CC
	ld l, $0D
	ld [hl], a
	jp ReadStream
Cmd_VolEnv:
	ld l, $27
	ld [hl], $00
	ld l, $3E
	ld [hl], $00
	sub $BD
	ld l, $17
	ld [hl], a
	ld a, [de]
	inc de
	ld l, $11
	ld [hl], a
	ld a, [de]
	inc de
	ld l, $14
	ld [hl], a
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
	sub $AD
	ld l, $17
	ld [hl], a
	jp ReadStream
Cmd_Arp:
	sub $9E
	add a, a
	ld c, a
	ldh a, [wArpTable]
	add a, c
	ld c, a
	ld b, a
	ldh a, [wArpTableHi]
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

; Cmd_Instrument: clears vibrato, arpeggio, glide, auto-pan, auto-duty and the
; hardware envelope, centre pan, 50 % duty; then runs instrument macro n (entry
; n + 1 of the song's table) until END or NEXT with wInInstr = $C9.
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
	sub $83
	add a, a
	push af
	ldh a, [wInstrTable]
	ld l, a
	ldh a, [wInstrTableHi]
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
	ldh [wInInstr], a
InstrLoop:
	ld a, [de]
	inc de
	cp $68
	jr z, InstrDone
	cp $6A
	jr z, InstrDone
	call InstrCommand
	jr InstrLoop
InstrCommand:
	cp $CD
	jp nc, Cmd_Len
	cp $BD
	jp nc, Cmd_VolEnv
	cp $AD
	jr nc, Cmd_Vol
	cp $9E
	jr nc, Cmd_Arp
	sub $60
	add a, a
	ld c, a
	add a, $12
	ld c, a
	adc a, $42
	sub c
	ld b, a
	ld a, [bc]
	ld l, a
	inc bc
	ld a, [bc]
	ld b, a
	ld c, l
	jp CallBC_Bank0
InstrDone:
	xor a
	ldh [wInInstr], a
	pop de
	jp ReadStream

; Command jump table.
CmdTable:
	dw Cmd_Glide
	dw Cmd_GlideOff
	dw Cmd_Wait2
	dw Cmd_Vibrato
	dw Cmd_VibOff
	dw Cmd_Wait
	dw Cmd_Rest
	dw StopAll
	dw Cmd_End
	dw Cmd_Transpose
	dw Cmd_Next
	dw Cmd_OrderJump
	dw Cmd_Length
	dw Cmd_Drums
	dw Cmd_DrumsOff
	dw Cmd_PanC
	dw Cmd_PanR
	dw Cmd_PanL
	dw Cmd_Duty50
	dw Cmd_Duty75
	dw Cmd_Duty12
	dw Cmd_HwEnv
	dw Cmd_AutoPan
	dw Cmd_AutoDuty
	dw Cmd_Fade
	dw Cmd_FadeOff
	dw Cmd_Wave
	dw Cmd_Porta
	dw Cmd_PortaOff
	dw Cmd_ChTranspose
	dw Cmd_Release
	dw Cmd_ArpOff
	dw Cmd_PatGoto
	dw Cmd_PatCall
	dw Cmd_CallCode
	dw Cmd_EnvDiv
Cmd_EnvDiv:
	ld a, [de]
	ld l, $3E
	ld [hl], a
	inc de
	ret

; CALL_CODE w: push w and return into it, i.e. call machine code at w (it returns
; to StreamCommand's loop). The songs use it to start one-shot noise sounds.
Cmd_CallCode:
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	inc de
	ld b, a
	push bc
	ret

; Unreferenced (1 bytes)
	db $C9

; PatReturn (from Cmd_Next while field $3C is set): continue after the PAT_CALL.
PatReturn:
	ld l, $3B
	ld e, [hl]
	inc l
	ld d, [hl]
	ld [hl], $00
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
	inc de
	ld [hli], a
	ld a, [de]
	ld [hld], a
	ld e, [hl]
	inc l
	ld d, [hl]
	ret
Cmd_ArpOff:
	ld l, $04
	res 0, [hl]
	ret

; CheckRelease (RELEASE t, env; t = min length (hi) / ticks left (lo)): skipped for
; notes shorter than the minimum; on the tick where len = ticks left, unless the
; next byte is WAIT: pulse NRx2 = env (via $31/$32); CH3/SFX: volume = env >> 4.
CheckRelease:
	ld l, $39
	ld a, [hl]
	and $F0
	jr z, CheckRelease2
	swap a
	ld c, a
	ld l, $0D
	ld a, [hl]
	cp c
	ret c
CheckRelease2:
	ld l, $04
	bit 1, [hl]
	ret z
	bit 2, [hl]
	ret nz
	ld l, $05
	ld c, [hl]
	ld l, $39
	ld a, [hl]
	and $0F
	cp c
	ret nz
	ld a, [de]
	cp $65
	ret z
	ld l, $3A
	ld a, h
	cp $C3
	jr z, ReleaseCh3
	cp $C4
	jr z, ReleaseCh3
	ld a, [hl]
	ld l, $31
	ld [hli], a
	ld [hl], $01
SetReleased:
	ld l, $04
	set 2, [hl]
	ret
ReleaseCh3:
	ld a, [hl]
	and $F0
	swap a
	ld l, $0B
	ld [hl], a
	jr SetReleased
Cmd_Release:
	ld l, $39
	ld a, [de]
	inc de
	and a
	jr z, ReleaseOff
	ld [hli], a
	ld a, [de]
	ld [hl], a
	inc de
	ld l, $04
	set 1, [hl]
	ret
ReleaseOff:
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
Cmd_GlideOff:
	ld l, $0E
	ld [hl], $00
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
	ld a, [de]
	inc de
	ld l, $22
	ld [hli], a
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	inc de
	ld [hli], a
	ld [hl], a
	ld l, $22
	ld a, [hl]
	ld l, $26
	ld [hl], a
	ld l, $04
	set 3, [hl]
	set 6, [hl]
	ret
Cmd_VibOff:
	ld l, $04
	res 3, [hl]
	ret

; DoVibrato: after the delay, +/- depth on the period low byte every tick (with carry
; into the high byte), switching direction every speed ticks.
DoVibrato:
	ld l, $04
	bit 3, [hl]
	ret z
	ld l, $22
	ld a, [hl]
	and a
	jr z, VibStep
	dec a
	ld [hl], a
	ret
VibStep:
	ld l, $04
	bit 6, [hl]
	jr z, VibDownPhase
	ld l, $24
	dec [hl]
	jr nz, VibUp
	inc l
	ld a, [hld]
	ld [hl], a
	ld l, $04
	res 6, [hl]
	ret
VibUp:
	ld l, $23
	ld a, [hl]
	ld l, $07
	add a, [hl]
	ld [hl], a
	ret nc
	ld l, $09
	inc [hl]
	ret
VibDownPhase:
	ld l, $24
	dec [hl]
	jr nz, VibDown
	inc l
	ld a, [hld]
	ld [hl], a
	ld l, $04
	set 6, [hl]
	ret
VibDown:
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

; REST: volume 0 (pulse pages also NRx2 = 0 through $31/$32), then wait one length.
Cmd_Rest:
	ld l, $0B
	ld [hl], $00
	ld a, h
	cp $C3
	jr z, Cmd_Wait
	cp $C4
	jr z, Cmd_Wait
	ld l, $31
	ld [hl], $00
	inc l
	ld [hl], $01
	jr Cmd_Wait

; StopAll: drums, noise sequence and fade off, reset all four pages, NR42 = 0,
; wTranspose = 0, noise pan centre.
StopAll:
	push af
	push de
	push bc
	push hl
	xor a
	ldh [wFadeOn], a
	ldh [wDrumsOn], a
	ldh [wNoiseOn], a
	ld h, $C1
	call ResetChannel
	inc h
	call ResetChannel
	inc h
	call ResetChannel
	inc h
	call ResetChannel
	xor a
	ldh [wTranspose], a
	ldh [rNR42], a
	call NoisePanCentre
	pop hl
	pop bc
	pop de
	pop af
	ret

; END: centre pan; SFX page: reload the music wave; then reset the page.
Cmd_End:
	pop af
	call Cmd_PanC
	ld a, h
	cp $C4
	jr nz, ResetChannel
	call RestoreMusicWave

; ResetChannel: clear the fields, silence the channel (NRx2 = 0, NRx4 = $80).
; On the SFX page the silence is meant to be skipped while Ch3 plays, but the test
; reuses the Z flag of an earlier compare, so it is always done (as in Bomb Jack).
ResetChannel:
	call Cmd_PanC
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
	ld l, $3C
	ld [hl], a
	ld l, $31
	ld [hli], a
	inc a
	ld [hl], a
	ld l, $05
	ld [hl], a
	ld a, h
	cp $C4
	jr nz, ResetSilence
	dec h
	ld l, $10
	ld a, [hl]
	jr z, ResetSilence0
	inc h
	jr ResetBumpNR32
ResetSilence0:
	inc h
ResetSilence:
	xor a
	ld l, $0A
	ld c, [hl]
	ldh [c], a
	inc c
	inc c
	or $80
	ldh [c], a
ResetBumpNR32:
	ld a, h
	cp $C4
	jr z, BumpNR32Shadow
	ld a, h
	cp $C3
	ret nz
BumpNR32Shadow:
	ldh a, [wShNR32]
	inc a
	ldh [wShNR32], a
	ret
Cmd_Transpose:
	ld a, [de]
	ldh [wTranspose], a
	inc de
	ret
Cmd_OrderJump:
	ld l, $00
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	inc de
	ld [hl], a

; NEXT: return from a PAT_CALL if one is pending, else the next order-list entry;
; a 0 entry is followed by the loop position (handled as ORDER_JUMP).
Cmd_Next:
	ld l, $3C
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
	ld a, $6B
	jp StreamCommand
Cmd_Length:
	ld a, [de]
	ld l, $0D
	ld [hl], a
	inc de
	ret
Cmd_DrumsOff:
	xor a
	ldh [wDrumsOn], a
	ret

; DRUMS t, pattern: one pattern byte every t ticks (DrumStep).
Cmd_Drums:
	ld a, [de]
	ldh [wDrumTempo], a
	inc de
	ld a, [de]
	ldh [wDrumPatLo], a
	inc de
	ld a, [de]
	ldh [wDrumPatHi], a
	inc de
	xor a
	ldh [wDrumPos], a
	ldh [wNoiseAtten], a
	ldh [wNoiseTimer], a
	ldh [wNoiseSpeed], a
	inc a
	ldh [wDrumsOn], a
	ldh [wDrumTimer], a
	ret
NoisePanCentre:
	ld a, $88
	ldh [wNoisePan], a
	ret

; DrumStep: read pattern bytes. $FF loops, 0 = nothing; $32/$33/$34 noise pan
; centre/right/left, $64-$73 noise attenuation, $74+ noise sequence speed (these
; modify and read on); others = drum sound n from DrumTable (skipped while
; wDrumHold is running). No $35 auto-pan in this version.
DrumStep:
	ldh a, [wDrumsOn]
	and a
	ret z
	ldh a, [wDrumTempo]
	ldh [wDrumTimer], a
DrumRead:
	ldh a, [wDrumPatHi]
	ld h, a
	ldh a, [wDrumPatLo]
	ld l, a
	ldh a, [wDrumPos]
	ld e, a
	ld d, $00
	add hl, de
	inc a
	ldh [wDrumPos], a
	ld a, [hl]
DrumByte:
	cp $FF
	jr z, DrumLoop
	and a
	ret z
	cp $32
	jr z, DrumPanC
	cp $33
	jr z, DrumPanR
	cp $34
	jr z, DrumPanL
	cp $74
	jr nc, DrumNoiseSpeed
	cp $64
	jr nc, DrumAtten
	push af
	ldh a, [wDrumHold]
	and a
	jr z, DrumSound
	pop af
	ret
DrumSound:
	pop af
	add a, a
	ld hl, DrumTable_m2
	rst $18

; Drum sound table (indexed from 2 bytes before; drum 1 is the first entry).
DrumTable_m2:
	rst $08
	jp hl
DrumTable:
	dw Drum1
	dw Drum2
	dw Drum3
	dw Drum4
	dw Drum5
	dw Drum6
	dw Drum7
	dw Drum8
	dw Drum9
DrumLoop:
	xor a
	ldh [wDrumPos], a
	jr DrumRead
DrumAtten:
	sub $64
	ld c, a
	ld a, $0F
	sub c
	ldh [wNoiseAtten], a
DrumNextByte:
	ldh a, [wDrumPos]
DrumNextByte2:
	inc a
	ldh [wDrumPos], a
	inc hl
	ld a, [hl]
	jr DrumByte
DrumPanC:
	ld a, $88
	ldh [wNoisePan], a
	jr DrumNextByte
DrumPanR:
	ldh a, [wDrumHold]
	and a
	jr nz, DrumNextByte
	ld a, $08
	ldh [wNoisePan], a
	jr DrumNextByte
DrumPanL:
	ldh a, [wDrumHold]
	and a
	jr nz, DrumNextByte
	ld a, $80
	ldh [wNoisePan], a
	jr DrumNextByte
DrumNoiseSpeed:
	sub $74
	ldh [wNoiseSpeed], a
	xor a
	ldh [wNoiseTimer], a
	jr DrumNextByte

; NoiseSeqTick: every wNoiseSpeed + 1 ticks one step: NR43 = seq43[i]; if an NR42
; table is set, NR42 = seq42[i] - attenuation << 4, NR44 = $80. $FF ends.
NoiseSeqTick:
	ldh a, [wNoiseOn]
	and a
	ret z
	ldh a, [wNoiseTimer]
	and a
	jr z, NoiseSeqStep
	dec a
	ldh [wNoiseTimer], a
	ret
NoiseSeqStep:
	ldh a, [wNoiseSpeed]
	ldh [wNoiseTimer], a
	push hl
	push de
	ldh a, [wNoiseNR43Hi]
	ld h, a
	ldh a, [wNoiseNR43Lo]
	ld l, a
	ldh a, [wNoisePos]
	ld e, a
	ld d, $00
	add hl, de
	ld a, [hl]
	cp $FF
	jr z, NoiseSeqEnd
	ldh [rNR43], a
	ldh a, [wNoiseNR42Hi]
	and a
	jr z, NoiseSeqNext
	ld h, a
	ldh a, [wNoiseNR42Lo]
	ld l, a
	add hl, de
	ldh a, [wNoiseAtten]
	ld c, a
	ld a, [hl]
	swap c
	sub c
	jr nc, NoiseWriteNR42
	and $0F
NoiseWriteNR42:
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
NoiseSeqNext:
	pop de
	pop hl
	ldh a, [wNoisePos]
	inc a
	ldh [wNoisePos], a
	ret
NoiseSeqEnd:
	pop de
	pop hl
	xor a
	ldh [wNoisePos], a
	ldh [wNoiseOn], a
	ret
Cmd_PanC:
	ld l, $3D
	ld [hl], $11
	ret
Cmd_PanR:
	ld l, $3D
	ld [hl], $01
	ret
Cmd_PanL:
	ld l, $3D
	ld [hl], $10
	ret

; Unreferenced (31 bytes)
	db $F0, $25, $B1, $A0, $E0, $25, $C9, $CB, $00, $CB, $01, $F0, $25, $B1, $A0, $18
	db $F3, $CB, $00, $CB, $00, $CB, $01, $CB, $01, $F0, $25, $B1, $A0, $18, $E5
Cmd_HwEnv:
	ld a, [de]
	ld l, $31
	ld [hli], a
	ld [hl], $01
	ld l, $27
	ld [hl], a
	inc de
	ld a, [de]
	and a
	jr z, HwEnvNoEnv2
	ld l, $28
	ld [hli], a
	ld [hli], a
	inc de
	ld a, [de]
	ld [hl], a
	inc de
	ret
HwEnvNoEnv2:
	ld l, $28
	ld [hli], a
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
	ld [hli], a
	ld [hl], $01
	ld l, $28
	ld a, [hli]
	ld [hl], a
	ret
Cmd_AutoPan:
	ld a, [de]
	inc de
	ld l, $2B
	ld [hli], a
	ld [hli], a
	xor a
	ld [hl], a
	jr AutoPanStep

; Unreferenced (1 bytes)
	db $C9
DoAutoPan:
	ld l, $2B
	ld a, [hl]
	and a
	ret z
	ld l, $2C
	ld a, [hl]
	dec a
	jr z, AutoPanStep
	ld [hl], a
	ret
AutoPanStep:
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
Cmd_AutoDuty:
	ld a, [de]
	inc de
	ld l, $2E
	ld [hli], a
	ld [hli], a
	xor a
	ld [hl], a
	jr AutoDutyStep
DoAutoDuty:
	ld l, $2E
	ld a, [hl]
	and a
	ret z
	ld l, $2F
	ld a, [hl]
	dec a
	jr z, AutoDutyStep
	ld [hl], a
	ret
AutoDutyStep:
	ld l, $2E
	ld a, [hli]
	ld [hli], a
	ld a, [hl]
	inc a
	ld [hl], a
	dec a
	jr z, Cmd_Duty75
	dec a
	jr z, Cmd_Duty12
	dec a
	jr z, Cmd_Duty75
	ld [hl], $01
Cmd_Duty50:
	ld c, $80
	jr SetDuty
Cmd_Duty75:
	ld c, $C0
	jr SetDuty
Cmd_Duty12:
	ld c, $00

; SetDuty: CH1/CH2 only, written straight to NR11/NR21.
SetDuty:
	ld a, h
	cp $C2
	jr z, SetDutyCh2
	cp $C1
	jr z, SetDutyCh1
	ret
SetDutyCh1:
	ld a, c
	ldh [rNR11], a
	ret
SetDutyCh2:
	ld a, c
	ldh [rNR21], a
	ret

; StartFade (A = speed, HL = table) / FADE speed, table: one byte into NR50 every
; speed + 1 ticks; the NEXT byte loops, $FF ends.
StartFade:
	ldh [wFadeSpeed], a
	ld a, l
	ldh [wFadePtr], a
	ld a, h
	ldh [wFadePtrHi], a
	jr FadeInit
Cmd_Fade:
	ld a, [de]
	ldh [wFadeSpeed], a
	inc de
	ld a, [de]
	ldh [wFadePtr], a
	inc de
	ld a, [de]
	ldh [wFadePtrHi], a
	inc de
FadeInit:
	xor a
	ldh [wFadePos], a
	ldh [wFadeTimer], a
	inc a
	ldh [wFadeOn], a
	ret
Cmd_FadeOff:
	xor a
	ldh [wFadeOn], a
	ret

; DoFade: while no fade runs, NR50 is forced back to $77 every tick (unless it is 0).
DoFade:
	ldh a, [wFadeOn]
	and a
	jr nz, FadeRun
	ldh a, [rNR50]
	and a
	ret z
	ld a, $77
	ldh [rNR50], a
	ret
FadeRun:
	ldh a, [wFadeTimer]
	and a
	jr z, FadeStep
	dec a
	ldh [wFadeTimer], a
	ret
FadeStep:
	ldh a, [wFadePtr]
	ld l, a
	ldh a, [wFadePtrHi]
	ld h, a
	ldh a, [wFadePos]
	rst $18
	ld a, [hl]
	cp $6A
	jr z, FadeLoop
	cp $FF
	jr z, Cmd_FadeOff
	ldh [rNR50], a
	ldh a, [wFadePos]
	inc a
	ldh [wFadePos], a
	ldh a, [wFadeSpeed]
	ldh [wFadeTimer], a
	ret
FadeLoop:
	xor a
	ldh [wFadePos], a
	jr FadeStep

; NR50 tables (only FadeOutTable is referenced).
Unused_FadeTables:
	db $44, $53, $62, $71, $62, $53, $44, $35
	db $26, $17, $26, $35, $6A
FadeTable_4690:
	db $77, $67, $57, $47, $37, $47, $57, $67
	db $77, $76, $75, $74, $73, $74, $75, $76
	db FADE_LOOP
	db $00, $01, $02, $03, $04, $05, $06, $07
	db $17, $27, $36, $46, $55, $64, $73, $72
	db $71, $70, $60, $50, $40, $30, $20, $10
	db $00, $00, $6A
FadeOutTable:
	db $77, $66, $55, $44, $33, $22, $11, $00
	db FADE_END

; WAVE w: Ch3 page: remember w and load it unless an SFX plays. SFX page: load w.
Cmd_Wave:
	ld a, h
	cp $C3
	jr nz, LoadWave
	ld a, [de]
	ldh [wMusicWave], a
	inc de
	ld a, [de]
	ldh [wMusicWaveHi], a
	inc h
	ld l, $10
	ld a, [hl]
	dec h
	and a
	jr z, WaveNow
	inc de
	ret
WaveNow:
	dec de

; LoadWave: NR30 = 0, copy 16 bytes, NR30 = NR34 = Ch3 period-hi shadow | $80.
LoadWave:
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
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hl]
	ldh [c], a
	pop hl
	ldh a, [wShFreqHi3]
	or $80
	ldh [rNR30], a
	ldh [rNR34], a
	ret

; RestoreMusicWave: reload the music wave, NR32 = raw volume field of page h - 1.
RestoreMusicWave:
	push hl
	xor a
	ldh [rNR30], a
	ld c, $30
	ldh a, [wMusicWave]
	ld l, a
	ldh a, [wMusicWaveHi]
	ld h, a
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hli]
	ldh [c], a
	inc c
	ld a, [hl]
	ldh [c], a
	pop hl
	dec h
	ld l, $0B
	ld a, [hl]
	ldh [rNR32], a
	inc h
	ldh a, [wShFreqHi3]
	or $80
	ldh [rNR30], a
	ldh [rNR34], a
	ret

; SndInit: init blocks into each page (fields $00-$0B, NRx3/NRx4/NRx2 addresses),
; clear the rest, NR52 = $FF, noise pan centre, StopAll.
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
	ldh [rNR52], a
	ld a, $88
	ldh [wNoisePan], a
	call StopAll
	ret
ClearChannelRest:
	ld l, e
	ld h, d
	dec hl
	ld bc, $0033
	rst $00
	ret
ChInit1:
	db $00, $00, $00, $00, $00, $00, $13, $00
	db $14, $00, $12, $00
ChInit2:
	db $00, $00, $00, $00, $00, $00, $18, $00
	db $19, $00, $17, $00
ChInit3:
	db $00, $00, $00, $00, $00, $00, $1D, $00
	db $1E, $00, $1C, $00

; Period table: 81 entries from C2 (same values as versions 1 and 2).
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

; DoArp: next arpeggio byte added to the note; NEXT byte = loop, $FF = hold.
DoArp:
	ld l, $04
	bit 0, [hl]
	ret z
ArpRead:
	ld l, $1F
	ld a, [hli]
	ld b, [hl]
	inc l
	add a, [hl]
	ld c, a
	jr nc, ArpByte
	inc b
ArpByte:
	ld a, [bc]
	cp $6A
	jr nz, ArpNotLoop
	ld [hl], $00
	jr ArpRead
ArpNotLoop:
	cp $FF
	jr nz, ArpApply
	dec [hl]
	jr ArpRead
ArpApply:
	inc [hl]
	ld l, $0C
	add a, [hl]

; SetNoteFreq: index = note - 12 + wTranspose (not on the SFX page) + field $0F.
SetNoteFreq:
	add a, $F4
	ld c, a
	push af
	ld a, h
	cp $C4
	jr nz, AddTranspose
	pop af
	jr SetFreqIndex
AddTranspose:
	pop af
	ldh a, [wTranspose]
	add a, c
SetFreqIndex:
	ld l, $0F
	ld c, [hl]
	add a, c
	add a, a
	add a, $D9
	ld c, a
	adc a, $47
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

; DoEnvelope: hardware mode: count down to the 2nd envelope value. Software mode
; (through EnvDivider): attack, then decay; the release phase ($18/$19) is dead.
DoEnvelope:
	ld l, $27
	ld a, [hl]
	and a
	jr z, SoftEnvelope
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
SoftEnvelope:
	call EnvDivider
	ld l, $12
	ld a, [hl]
	or a
	jr z, EnvDecay
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
	jr nc, ClampVol
StoreVol:
	ld [hl], a
	ret
ClampVol:
	ld a, $0F
	jr StoreVol
EnvDecay:
	ld l, $15
	ld a, [hl]
	or a
	jr z, EnvReleasePhase
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
	jr nc, StoreVol2
	xor a
StoreVol2:
	ld l, $0B
	ld [hl], a
	ret
EnvReleasePhase:
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
	jr nc, StoreVol3
	xor a
StoreVol3:
	ld l, $0B
	ld [hl], a
	ret

; StartMusicChN (de = order list): reset the page, start its first pattern.
StartMusicCh1:
	ld h, $C1
	jr StartMusicCh
StartMusicCh2:
	ld h, $C2
	jr StartMusicCh
StartMusicCh3:
	ld h, $C3
StartMusicCh:
	call ResetChannel
	ld l, $10
	ld [hl], $01
	ld l, $02
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	ld [hl], a
	ld l, $00
	inc de
	ld [hl], e
	inc l
	ld [hl], d
	ret

; OutputAll: Ch1, Ch2, then the SFX page if it plays, otherwise Ch3.
OutputAll:
	ld h, $C1
	call OutputChannel
	inc h
	call OutputChannel
	ld hl, $C410
	ld a, [hl]
	and a
	jr nz, OutputChannel
	dec h

; OutputChannel: NRx3 = period low; NRx4 = period high (no trigger) when it changed.
; Software volume: pulse NRx2 = vol << 4 + retrigger only when the register value
; differs; CH3 NR32 from Ch3VolTable when it changed. Hardware envelope: write
; field $31 + retrigger when field $32 is set.
OutputChannel:
	ld l, $10
	ld a, [hl]
	and a
	ret z
	ld l, $06
	ld c, [hl]
	inc l
	ld a, [hli]
	ldh [c], a
	ld c, [hl]
	inc l
	ld a, [hli]
	and $07
	ld b, a
	push hl
	ld a, h
	sub $C1
	add a, $91
	ld l, a
	adc a, $FF
	sub l
	ld h, a
	ld a, [hl]
	cp b
	jr z, OutputVolume
	ld a, b
	ldh [c], a
	ld [hl], a
OutputVolume:
	pop hl
	ld a, [hli]
	ld c, [hl]
	push af
	ld l, $27
	ld a, [hl]
	and a
	jr nz, OutputHwEnv
	pop af
	call WriteVolume
	ret
OutputHwEnv:
	pop af
	ld c, a
	ld l, $32
	ld a, [hl]
	and a
	jr z, OutputDone
	ld [hl], $00
	dec l
	ld a, [hl]
	ldh [c], a
	ld a, h
	cp $C1
	jr nz, RetrigCh2
	ldh a, [wShFreqHi1]
	or $80
	ldh [rNR14], a
	ret
RetrigCh2:
	ldh a, [wShFreqHi2]
	or $80
	ldh [rNR24], a
	ret
OutputDone:
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
	ld c, [hl]
	cp c
	jr z, WriteVolumeSame
	ld [hl], a
	pop hl
	ld a, h
	cp $C1
	jr nz, WriteVolumeCh2
	ldh a, [wShFreqHi1]
	or $80
	ldh [rNR14], a
	ret
WriteVolumeCh2:
	ldh a, [wShFreqHi2]
	or $80
	ldh [rNR24], a
	ret
WriteVolumeSame:
	pop hl
	ret
WriteCh3Vol:
	push hl
	ld a, c
	and $0F
	add a, $FA
	ld l, a
	adc a, $49
	sub l
	ld h, a
	ld c, [hl]
	ldh a, [wShNR32]
	cp c
	jr z, WriteCh3VolDone
	ld a, c
	ldh [wShNR32], a
	ldh [rNR32], a
WriteCh3VolDone:
	pop hl
	ret

; CH3 volume table (0-15 -> NR32).
Ch3VolTable:
	db $00, $00, $00, $00, $60, $60, $60, $60
	db $40, $40, $40, $40, $20, $20, $20, $20

; DoPorta (PORTA speed, delay): after the delay, slide the period by speed per tick
; towards the next note's period, then stay on it.
DoPorta:
	ld l, $04
	bit 4, [hl]
	ret z
	ld l, $35
	ld a, [hl]
	and a
	jr z, PortaRun
	dec a
	ld [hl], a
	ret
PortaRun:
	ld l, $36
	ld a, [hl]
	and a
	ret z
	ld l, $33
	ld b, [hl]
	cp $01
	jr z, PortaDown
	ld l, $07
	ld a, [hl]
	add a, b
	ld [hl], a
	jr nc, PortaUpCheck
	inc l
	inc l
	inc [hl]
PortaUpCheck:
	ld l, $07
	ld c, [hl]
	inc l
	inc l
	ld b, [hl]
	ld l, $38
	ld a, [hl]
	cp b
	jr z, PortaUpLo
	ret nc
	jr PortaArrive
PortaUpLo:
	dec l
	ld a, [hl]
	cp c
	ret nc
PortaArrive:
	ld l, $37
	ld c, [hl]
	inc l
	ld b, [hl]
	ld l, $07
	ld [hl], c
	inc l
	inc l
	ld [hl], b
	ld l, $36
	ld [hl], $00
	ret
PortaDown:
	ld l, $07
	ld a, [hl]
	sub b
	ld [hl], a
	jr nc, PortaDownCheck
	inc l
	inc l
	dec [hl]
PortaDownCheck:
	ld l, $07
	ld c, [hl]
	inc l
	inc l
	ld b, [hl]
	ld l, $38
	ld a, b
	cp [hl]
	jr c, PortaArrive
	jr z, PortaDownLo
	ret
PortaDownLo:
	dec l
	ld a, c
	cp [hl]
	jr z, PortaArrive
	ret nc
	jr PortaArrive

; Unreferenced (4 bytes)
	db $2D, $36, $00, $C9
Cmd_Porta:
	ld a, [de]
	inc de
	ld l, $33
	ld [hli], a
	ld a, [de]
	inc de
	ld [hl], a
	ld l, $04
	set 4, [hl]
	ret
Cmd_PortaOff:
	ld l, $04
	res 4, [hl]
	ret

; PortaNoteOn: look ahead in the stream for the next note: delay = this note's
; length (+ one length per WAIT/REST) - the PORTA delay; direction and target from
; the next note. NEXT/END stop the search (no slide). Only PORTA and VOLENV
; arguments are skipped; other commands with arguments are misread.
PortaNoteOn:
	ld l, $04
	bit 4, [hl]
	ret z
	ld l, $35
	ld [hl], $00
	push de
	jr PortaAddLength
PortaScan:
	ld a, [de]
	inc de
	cp $60
	jr nc, PortaScanCmd
	ld c, a
	ld l, $34
	ld b, [hl]
	ld l, $35
	ld a, [hl]
	sub b
	jr c, PortaNoDelay
	ld [hl], a
	jr PortaTarget
PortaNoDelay:
	xor a
	ld [hl], a
	jr PortaTarget
PortaScanCmd:
	cp $65
	jr z, PortaAddLength
	cp $66
	jr z, PortaAddLength
	cp $7B
	jr z, PortaSkip2
	cp $BD
	jr c, PortaScanEnd
	cp $CD
	jr nc, PortaScanEnd
	jr PortaSkip3
PortaScanEnd:
	cp $6A
	jr z, PortaNone
	cp $68
	jr z, PortaNone
	jr PortaScan
PortaSkip2:
	inc de
	inc de
	jr PortaScan
PortaSkip3:
	inc de
	inc de
	inc de
	jr PortaScan
PortaAddLength:
	ld l, $0D
	ld b, [hl]
	ld l, $35
	ld a, [hl]
	add a, b
	ld [hl], a
	jr PortaScan
PortaTarget:
	ld l, $0C
	ld b, [hl]
	ld a, c
	ld l, $36
	cp b
	jr c, PortaSetDown
	jr z, PortaNoneDir
	ld [hl], $02
	jr PortaSetTarget
PortaSetDown:
	ld [hl], $01
PortaSetTarget:
	ld a, c
	call SetPortaTarget
	jr PortaScanDone
PortaNone:
	ld l, $35
	ld [hl], $00
	inc l
PortaNoneDir:
	ld [hl], $00
PortaScanDone:
	pop de
	ret
SetPortaTarget:
	add a, $F4
	ld c, a
	push af
	ld a, h
	cp $C4
	jr nz, PortaAddTranspose
	pop af
	jr PortaFreqIndex
PortaAddTranspose:
	pop af
	ldh a, [wTranspose]
	add a, c
PortaFreqIndex:
	ld l, $0F
	ld a, [hl]
	add a, c
	add a, a
	add a, $D9
	ld c, a
	adc a, $47
	sub c
	ld b, a
	push de
	ld a, [bc]
	inc bc
	ld e, a
	ld a, [bc]
	ld d, a
	ld l, $37
	ld [hl], e
	inc l
	ld [hl], d
	pop de
	ret

; PlaySfx (A = id): reset the SFX page if busy (no priority test: the game's mailbox
; does that), start the stream and run its first tick and output at once.
PlaySfx:
	push de
	push bc
	push hl
	push af
	ld hl, $C410
	ld a, [hl]
	and a
	call nz, ResetChannel
	pop af
	ld l, $10
	ld [hl], a
	ld de, $C402
	add a, a
	add a, $91
	ld l, a
	adc a, $4B
	sub l
	ld h, a
	ld a, [hli]
	ld [de], a
	inc de
	push hl
	push de
	pop hl
	pop de
	ld a, [de]
	ld [hld], a
	ld d, a
	ld e, [hl]
	call ReadStream
	call OutputChannel
	pop hl
	pop bc
	pop de
	ret

; PlayOnChN (A = id): the same, but the SFX stream replaces the music on page N.
PlayOnCh1:
	ld h, $C1
	jr PlayOnCh
PlayOnCh2:
	ld h, $C2
	jr PlayOnCh
PlayOnCh3:
	ld h, $C3
PlayOnCh:
	push af
	ld l, $10
	ld a, [hl]
	and a
	call nz, ResetChannel
	pop af
	ld l, $10
	ld [hl], a
	ld d, h
	ld e, $02
	add a, a
	add a, $91
	ld l, a
	adc a, $4B
	sub l
	ld h, a
	ld a, [hli]
	ld [de], a
	inc de
	push hl
	push de
	pop hl
	pop de
	ld a, [de]
	ld [hld], a
	ld d, a
	ld e, [hl]
	call ReadStream
	call OutputChannel
	ret

; Fade the music out (speed 4, FadeOutTable).
SongFadeOut:
	ld a, $04
	ld hl, FadeOutTable
	call StartFade
	ret
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
	dw Sfx10
	dw Sfx11

; Sound effect 1
Sfx01:
	WAVE Wave_6582
	VOL 15
	LEN 4
	NOTE G_, 6
	NOTE G_, 5
	NOTE D_, 7
	NOTE D_, 6
	END

; Sound effect 2
Sfx02:
	WAVE Wave_6582
	VOL 15
	LEN 4
	NOTE D_, 7
	NOTE D_, 6
	NOTE G_, 6
	NOTE G_, 5
	END

; Sound effect 3
Sfx03:
	LEN 6
	WAVE Wave_6532
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

; Sound effect 4
Sfx04:
	LEN 14
	VOLENV 15, $13, $1F, $11
	GLIDE $01
	WAVE Wave_6532
	NOTE C_, 3
	END

; Sound effect 5
Sfx05:
	LEN 20
	VOLENV 15, $11, $1F, $12
	GLIDE $FE
	WAVE Wave_6542
	NOTE C_, 3
	WAIT
	END

; Sound effect 6
Sfx06:
	LEN 8
	VOLENV 15, $11, $1F, $12
	WAVE Wave_6572
	GLIDE $02
	NOTE A_, 3
	GLIDE $02
	NOTE C_, 4
	GLIDE $02
	NOTE E_, 4
	GLIDE $02
	NOTE G_, 4
	GLIDE $02
	NOTE B_, 4
	END

; Sound effect 7
Sfx07:
	LEN 30
	VOLENV 15, $00, $00, $00
	WAVE Wave_6562
	VIBRATO $00, $05, $03
	PORTA $02, $1E
	NOTE A_, 5
	NOTE F_, 6
	LEN 1
	NOTE A_, 5
	END

; Sound effect 8
Sfx08:
	WAVE Wave_6532
	VOLENV 15, $00, $1F, $11
	LEN 7
	NOTE C_, 5
	END

; Sound effect 9
Sfx09:
	WAVE Wave_6532
	VOLENV 15, $00, $1F, $15
	LEN 1
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	VOL 13
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	VOL 11
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	VOL 9
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	VOL 7
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	VOL 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	END

; Sound effect 10
Sfx10:
	WAVE Wave_6532
	VOLENV 15, $00, $1F, $15
	LEN 1
	NOTE C_, 7
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	VOL 13
	NOTE C_, 7
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	VOL 11
	NOTE C_, 7
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	VOL 9
	NOTE C_, 7
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	VOL 7
	NOTE C_, 7
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	VOL 5
	NOTE C_, 7
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	END

; Sound effect 11
Sfx11:
	WAVE Wave_6532
	VOLENV 15, $00, $1F, $19
	LEN 1
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	END

; Song 1: instrument table 1, arpeggio table 1
PlaySong1:
	push hl
	push de
	push bc
	call StopAll
	ld de, Song1_Ch1
	call StartMusicCh1
	ld de, Song1_Ch2
	call StartMusicCh2
	ld de, Song1_Ch3
	call StartMusicCh3
	ld a, HIGH(InstrTable1_1 - 2)
	ldh [wInstrTableHi], a
	ld a, LOW(InstrTable1_1 - 2)
	ldh [wInstrTable], a
	ld a, HIGH(ArpTable)
	ldh [wArpTableHi], a
	ld a, LOW(ArpTable)
	ldh [wArpTable], a
	pop bc
	pop de
	pop hl
	ret
Song1_Ch1:
	dw Pat_4DDF
	dw Pat_4DDF
	dw Pat_4E7F
	dw Pat_4EB3
	dw Pat_4EB3
	dw Pat_4EB3
	dw Pat_4EB3
	dw Pat_505A
	dw Pat_505A
	dw Pat_50F4
	dw Pat_51C0
	dw Pat_50F4
	dw Pat_51C0
	dw Pat_4ECB
	dw Pat_4ECB
	dw Pat_505A
	dw Pat_505A
	dw Pat_5058
	dw Pat_505A
	dw Pat_527E
	dw Pat_527E
	dw Pat_527E
	dw Pat_527E
	dw Pat_527E
	dw Pat_527E
	dw Pat_527E
	dw Pat_527E
	dw Pat_53B2
	dw Pat_53B2
	dw Pat_53B2
	dw Pat_53B2
	dw Pat_50F4
	dw Pat_51C0
	dw Pat_5499
	ORDER_LOOP Song1_Ch1
Song1_Ch2:
	dw Pat_4DA3
	dw Pat_4DA3
	dw Pat_4E4D
	dw Pat_4F1C
	dw Pat_4F1C
	dw Pat_5018
	dw Pat_5018
	dw Pat_5084
	dw Pat_508A
	dw Pat_5142
	dw Pat_5211
	dw Pat_5142
	dw Pat_5211
	dw Pat_5018
	dw Pat_5018
	dw Pat_5084
	dw Pat_508A
	dw Pat_5084
	dw Pat_508A
	dw Pat_529F
	dw Pat_52AC
	dw Pat_5336
	dw Pat_536A
	dw Pat_5404
	dw Pat_5404
	dw Pat_5404
	dw Pat_5404
	dw Pat_5142
	dw Pat_5211
	dw Pat_54DE
	ORDER_LOOP Song1_Ch2
Song1_Ch3:
	dw Pat_4D6D
	dw Pat_4D6D
	dw Pat_4E1F
	dw Pat_4E1F
	dw Pat_4F37
	dw Pat_4F8F
	dw Pat_4FE5
	dw Pat_4FE5
	dw Pat_50C5
	dw Pat_50C5
	dw Pat_5188
	dw Pat_5233
	dw Pat_5188
	dw Pat_5233
	dw Pat_4FEA
	dw Pat_4FEA
	dw Pat_50C5
	dw Pat_50C5
	dw Pat_50BD
	dw Pat_50BD
	dw Pat_52E2
	dw Pat_52E2
	dw Pat_537A
	dw Pat_537A
	dw Pat_5411
	dw Pat_546D
	dw Pat_5411
	dw Pat_546D
	dw Pat_5188
	dw Pat_5233
	dw Pat_5502
	ORDER_LOOP Song1_Ch3
Pat_4D6D:
	CH_TRANSPOSE $00
	WAVE Wave_6542
	RELEASE $02, $00
	DRUMS $0A, DrumPat_63B9
	INSTR 0
	LEN 10
	NOTE G_, 3
	WAIT
	WAIT
	NOTE G_, 3
	WAIT
	NOTE D_, 3
	LEN 30
	NOTE G_, 2
	WAIT
	LEN 10
	NOTE F_, 3
	WAIT
	WAIT
	NOTE F_, 3
	WAIT
	NOTE C_, 3
	LEN 30
	NOTE F_, 2
	WAIT
	LEN 10
	NOTE Dsh, 3
	WAIT
	WAIT
	NOTE Dsh, 3
	WAIT
	NOTE Ash, 2
	LEN 30
	NOTE Dsh, 2
	WAIT
	LEN 10
	NOTE D_, 3
	WAIT
	WAIT
	NOTE D_, 3
	WAIT
	NOTE A_, 2
	LEN 30
	NOTE D_, 2
	WAIT
	NEXT
Pat_4DA3:
	INSTR 9
	DUTY_75
	LEN 10
	HWENV $F2, $14, $56
	VIBRATO $09, $01, $06
	NOTE G_, 4
	WAIT
	NOTE D_, 4
	NOTE G_, 4
	WAIT
	NOTE D_, 4
	NOTE G_, 4
	WAIT
	NOTE D_, 4
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	NOTE F_, 4
	WAIT
	NOTE C_, 4
	NOTE F_, 4
	WAIT
	NOTE C_, 4
	NOTE F_, 4
	WAIT
	NOTE C_, 4
	NOTE F_, 4
	WAIT
	NOTE G_, 4
	NOTE Dsh, 4
	WAIT
	NOTE Ash, 3
	NOTE Dsh, 4
	WAIT
	NOTE Ash, 3
	NOTE Dsh, 4
	WAIT
	NOTE Ash, 3
	NOTE Dsh, 4
	WAIT
	NOTE F_, 4
	NOTE D_, 4
	WAIT
	NOTE A_, 3
	NOTE D_, 4
	WAIT
	NOTE A_, 3
	NOTE D_, 4
	WAIT
	NOTE A_, 3
	NOTE E_, 4
	WAIT
	NOTE Fsh, 4
	NEXT
Pat_4DDF:
	TRANSPOSE $00
	INSTR 9
	DUTY_75
	LEN 11
	HWENV $F2, $14, $56
	VIBRATO $09, $01, $06
	NOTE B_, 4
	LEN 10
	WAIT
	WAIT
	NOTE B_, 4
	WAIT
	WAIT
	NOTE B_, 4
	WAIT
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 5
	NOTE A_, 4
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	NOTE Ash, 4
	NOTE G_, 4
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	NOTE Fsh, 4
	WAIT
	WAIT
	NOTE Fsh, 4
	WAIT
	WAIT
	NOTE Fsh, 4
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	LEN 9
	NOTE A_, 4
	NEXT
Pat_4E1F:
	DRUMS $0A, DrumPat_63C6
	LEN 10
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	WAIT
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	WAIT
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	WAIT
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	WAIT
	INSTR 4
	NOTE G_, 4
	NEXT
Pat_4E4D:
	LEN 10
	NOTE G_, 4
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	WAIT
	NOTE D_, 3
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	WAIT
	NOTE D_, 3
	WAIT
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	WAIT
	NOTE G_, 3
	WAIT
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	WAIT
	NOTE D_, 3
	WAIT
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	WAIT
	NOTE G_, 3
	WAIT
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NEXT
Pat_4E7F:
	LEN 11
	NOTE B_, 4
	LEN 10
	WAIT
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 5
	NOTE B_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE B_, 4
	WAIT
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 5
	NOTE B_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE B_, 3
	WAIT
	WAIT
	NOTE B_, 3
	WAIT
	NOTE C_, 4
	NOTE B_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE B_, 3
	WAIT
	WAIT
	NOTE B_, 3
	WAIT
	NOTE C_, 4
	NOTE B_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	LEN 9
	WAIT
	NEXT
Pat_4EB3:
	INSTR 3
	LEN 30
	RELEASE $A2, $00
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 3
	NOTE D_, 3
	NOTE F_, 2
	NOTE F_, 2
	NOTE C_, 3
	NOTE C_, 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 3
	NOTE D_, 3
	NOTE E_, 2
	NOTE B_, 2
	NOTE D_, 2
	NOTE A_, 2
	RELEASE $00
	NEXT
Pat_4ECB:
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE E_, 2
	WAIT
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE B_, 2
	WAIT
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE D_, 4
	NEXT
Pat_4F1C:
	LEN 30
	DUTY_50
	HWENV $F1, $0A, $66
	ARP 2
	NOTE G_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE D_, 4
	ARP 3
	NOTE E_, 4
	NOTE E_, 4
	ARP 2
	NOTE D_, 4
	NOTE D_, 4
	ARP_OFF
	NEXT
Pat_4F37:
	LEN 10
	ARP_OFF
	CH_TRANSPOSE $18
	VOLENV 15, $00, $00, $00
	VIBRATO $0A, $01, $02
	WAVE Wave_6562
	RELEASE $A2, $00
	DRUMS $1E, DrumPat_6436
	NOTE D_, 5
	WAIT
	LEN 7
	NOTE D_, 5
	LEN 3
	NOTE E_, 5
	LEN 10
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	NOTE C_, 5
	WAIT
	LEN 7
	NOTE C_, 5
	LEN 3
	NOTE D_, 5
	LEN 10
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	REST
	NOTE D_, 5
	WAIT
	LEN 7
	NOTE D_, 5
	LEN 3
	NOTE E_, 5
	LEN 10
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	WAIT
	NOTE A_, 4
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	LEN 3
	NOTE E_, 4
	LEN 10
	NOTE G_, 4
	LEN 7
	REST
	LEN 10
	NOTE E_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	REST
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	REST
	NEXT
Pat_4F8F:
	NOTE D_, 5
	LEN 3
	NOTE C_, 5
	NOTE D_, 5
	LEN 4
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	NOTE C_, 5
	LEN 3
	NOTE B_, 4
	NOTE C_, 5
	LEN 4
	NOTE B_, 4
	LEN 10
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 3
	NOTE A_, 4
	LEN 17
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	LEN 3
	NOTE A_, 4
	LEN 7
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE C_, 4
	WAIT
	REST
	NOTE D_, 5
	LEN 3
	NOTE C_, 5
	NOTE D_, 5
	LEN 4
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	NOTE C_, 5
	LEN 3
	NOTE B_, 4
	NOTE C_, 5
	LEN 4
	NOTE B_, 4
	LEN 10
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 3
	NOTE A_, 4
	LEN 7
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	NOTE A_, 4
	LEN 3
	NOTE A_, 4
	LEN 7
	NOTE B_, 4
	LEN 10
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE D_, 4
	WAIT
	REST
	CH_TRANSPOSE $00
	NEXT
Pat_4FE5:
	INSTR 6
	DRUMS $05, DrumPat_63D3
Pat_4FEA:
	CH_TRANSPOSE $0C
	RELEASE $00
	PORTA $06, $04
	LEN 20
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	LEN 10
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	LEN 20
	NOTE G_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	NOTE D_, 4
	WAIT
	PORTA_OFF
	CH_TRANSPOSE $00
	NEXT
Pat_5018:
	LEN 10
	DUTY_12
	ARP 0
	HWENV $F2, $00
	NOTE G_, 4
	NOTE G_, 3
	NOTE A_, 4
	NOTE G_, 3
	NOTE B_, 4
	NOTE G_, 3
	NOTE D_, 5
	NOTE D_, 4
	NOTE C_, 5
	NOTE D_, 4
	NOTE B_, 4
	NOTE D_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE B_, 4
	LEN 3
	NOTE C_, 5
	NOTE B_, 4
	LEN 4
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 5
	NOTE D_, 5
	NOTE A_, 5
	NOTE D_, 5
	NOTE B_, 5
	NOTE D_, 5
	NOTE D_, 6
	NOTE D_, 5
	NOTE C_, 6
	NOTE D_, 5
	NOTE B_, 5
	NOTE D_, 5
	NOTE C_, 6
	NOTE E_, 5
	LEN 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE B_, 5
	NOTE C_, 6
	LEN 10
	NOTE B_, 5
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE D_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE D_, 5
	WAIT
	NEXT
Pat_5058:
	TRANSPOSE $01
Pat_505A:
	LEN 10
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	NEXT
Pat_5084:
	PAT_CALL Pat_5090
	PAT_GOTO Pat_50B7
Pat_508A:
	PAT_CALL Pat_5090
	PAT_GOTO Pat_50BA
Pat_5090:
	INSTR 7
	VIBRATO $0A, $04, $04
	LEN 2
	NOTE D_, 4
	NOTE F_, 4
	LEN 16
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	LEN 10
	NOTE F_, 4
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	NOTE F_, 4
	LEN 2
	NOTE D_, 4
	NOTE F_, 4
	LEN 16
	NOTE G_, 4
	LEN 5
	NOTE G_, 4
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NEXT
Pat_50B7:
	NOTE D_, 4
	NOTE F_, 4
	NEXT
Pat_50BA:
	WAIT
	WAIT
	NEXT
Pat_50BD:
	WAVE Wave_6592
	CH_TRANSPOSE $0C
	PAT_GOTO Pat_50D2
Pat_50C5:
	CH_TRANSPOSE $0C
	INSTR 6
	RELEASE $00
	VIBRATO $14, $01, $05
	DRUMS $05, DrumPat_6404
Pat_50D2:
	LENGTH $78
	NOTE D_, 5
	LEN 10
	NOTE F_, 5
	LEN 3
	NOTE E_, 5
	NOTE F_, 5
	LEN 4
	NOTE E_, 5
	LEN 10
	NOTE D_, 5
	NOTE E_, 5
	LEN 3
	NOTE D_, 5
	NOTE E_, 5
	LEN 4
	NOTE D_, 5
	LEN 10
	NOTE C_, 5
	NOTE D_, 5
	LEN 3
	NOTE C_, 5
	NOTE D_, 5
	LEN 4
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	CH_TRANSPOSE $00
	NEXT
Pat_50F4:
	LEN 10
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE C_, 3
	WAIT
	NOTE B_, 2
	WAIT
	NOTE A_, 2
	WAIT
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	NEXT
Pat_5142:
	LEN 10
	DUTY_50
	ARP 0
	HWENV $F2, $14, $60
	NOTE B_, 4
	WAIT
	LEN 5
	NOTE B_, 4
	NOTE B_, 4
	LEN 10
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	WAIT
	NOTE Fsh, 4
	NOTE Fsh, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	LEN 5
	NOTE A_, 4
	NOTE A_, 4
	LEN 10
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE G_, 4
	WAIT
	WAIT
	NOTE B_, 4
	WAIT
	LEN 5
	NOTE B_, 4
	NOTE B_, 4
	LEN 10
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	WAIT
	NOTE Fsh, 4
	NOTE Fsh, 4
	WAIT
	NOTE G_, 4
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE B_, 3
	LEN 3
	NOTE C_, 4
	NOTE B_, 3
	LEN 4
	NOTE C_, 4
	LEN 10
	NOTE B_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NEXT
Pat_5188:
	INSTR 5
	LEN 10
	CH_TRANSPOSE $0C
	NOTE D_, 5
	WAIT
	LEN 5
	NOTE D_, 5
	NOTE D_, 5
	LEN 10
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	WAIT
	NOTE A_, 4
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE D_, 5
	WAIT
	NOTE D_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	WAIT
	NOTE A_, 4
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	NOTE G_, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NEXT
Pat_51C0:
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 5
	INSTR 3
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 5
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 5
	INSTR 3
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 5
	NEXT
Pat_5211:
	NOTE B_, 3
	WAIT
	LEN 5
	NOTE B_, 3
	NOTE B_, 3
	LEN 10
	NOTE B_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE Fsh, 3
	WAIT
	NOTE Fsh, 3
	NOTE Fsh, 3
	WAIT
	NOTE G_, 3
	NOTE A_, 3
	WAIT
	LEN 5
	NOTE A_, 3
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	DUTY_75
	CH_TRANSPOSE $F4
	PAT_GOTO Pat_524F
Pat_5233:
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	NOTE A_, 3
	WAIT
	NOTE B_, 3
	NOTE C_, 4
	WAIT
	NOTE C_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	INSTR 6
	RELEASE $A2, $00
	CH_TRANSPOSE $18
Pat_524F:
	NOTE D_, 4
	NOTE E_, 4
	LEN 3
	NOTE G_, 4
	NOTE A_, 4
	LEN 14
	NOTE G_, 4
	LEN 10
	NOTE D_, 4
	WAIT
	NOTE B_, 4
	NOTE G_, 4
	LEN 3
	NOTE A_, 4
	NOTE B_, 4
	LEN 14
	NOTE A_, 4
	LEN 10
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	LEN 3
	NOTE A_, 4
	NOTE B_, 4
	LEN 14
	NOTE A_, 4
	LEN 10
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	LEN 5
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE E_, 4
	LEN 10
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	CH_TRANSPOSE $00
	RELEASE $00
	NEXT
Pat_527E:
	INSTR 3
	NOTE F_, 2
	WAIT
	WAIT
	INSTR 8
	NOTE F_, 4
	WAIT
	WAIT
	INSTR 3
	NOTE F_, 2
	WAIT
	WAIT
	INSTR 8
	NOTE F_, 4
	WAIT
	WAIT
	INSTR 3
	NOTE G_, 2
	WAIT
	WAIT
	INSTR 8
	NOTE G_, 4
	WAIT
	WAIT
	INSTR 3
	NOTE G_, 2
	WAIT
	WAIT
	INSTR 8
	NOTE G_, 4
	WAIT
	WAIT
	NEXT
Pat_529F:
	ARP 1
	DUTY_50
	HWENV $F2, $0F, $4C
	VIBRATO $14, $04, $04
	PAT_GOTO Pat_52AF
Pat_52AC:
	CH_TRANSPOSE $0C
	DUTY_75
Pat_52AF:
	NOTE F_, 4
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	NOTE E_, 4
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	WAIT
	NOTE B_, 3
	WAIT
	NOTE G_, 3
	WAIT
	NOTE D_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE F_, 4
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	NOTE E_, 4
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	CH_TRANSPOSE $00
	NEXT
Pat_52E2:
	CH_TRANSPOSE $00
	VIBRATO $0A, $01, $04
	VOLENV 15, $11, $18, $12
	ARP 0
	WAVE Wave_6582
	DRUMS $05, DrumPat_641D
	NOTE A_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 6
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	LEN 3
	NOTE B_, 5
	NOTE C_, 6
	LEN 4
	NOTE B_, 5
	LEN 10
	NOTE C_, 6
	NOTE D_, 6
	WAIT
	LEN 3
	NOTE G_, 5
	NOTE A_, 5
	LEN 4
	NOTE G_, 5
	LEN 10
	NOTE A_, 5
	NOTE B_, 5
	WAIT
	WAIT
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE A_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 6
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	LEN 3
	NOTE B_, 5
	NOTE C_, 6
	LEN 4
	NOTE B_, 5
	LEN 10
	NOTE C_, 6
	NOTE D_, 6
	NOTE B_, 5
	NOTE C_, 6
	NOTE B_, 5
	NOTE G_, 5
	WAIT
	NOTE D_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	CH_TRANSPOSE $00
	NEXT
Pat_5336:
	CH_TRANSPOSE $00
	DUTY_50
	PAT_CALL Pat_533F
	PAT_GOTO Pat_5371
Pat_533F:
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	WAIT
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE D_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE D_, 3
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NEXT
Pat_536A:
	CH_TRANSPOSE $0C
	DUTY_75
	PAT_CALL Pat_533F
	DRUMS_OFF
Pat_5371:
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	CH_TRANSPOSE $00
	NEXT
Pat_537A:
	DRUMS $05, DrumPat_63D3
	NOTE A_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 6
	NOTE A_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE D_, 6
	WAIT
	NOTE G_, 5
	NOTE A_, 5
	NOTE B_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE A_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 6
	NOTE A_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE D_, 6
	NOTE B_, 5
	NOTE C_, 6
	NOTE B_, 5
	NOTE G_, 5
	WAIT
	WAIT
	CALL_CODE Drum3
	WAIT
	WAIT
	WAIT
	NEXT
Pat_53B2:
	LEN 10
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE C_, 2
	WAIT
	INSTR 1
	NOTE C_, 5
	INSTR 3
	NOTE C_, 2
	WAIT
	INSTR 1
	NOTE C_, 5
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 5
	INSTR 3
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 5
	INSTR 3
	NOTE C_, 2
	WAIT
	INSTR 1
	NOTE C_, 5
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	NEXT
Pat_5404:
	LEN 10
	INSTR 7
	CH_TRANSPOSE $F4
	PAT_CALL Pat_544A
	PAT_CALL Pat_5427
	CH_TRANSPOSE $00
	NEXT
Pat_5411:
	LEN 10
	CH_TRANSPOSE $18
	VIBRATO $0A, $01, $04
	VOLENV 15, $11, $18, $12
	ARP 0
	WAVE Wave_6582
	DRUMS $05, DrumPat_6404
	PAT_CALL Pat_544A
Pat_5427:
	NOTE B_, 4
	WAIT
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE A_, 4
	WAIT
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	LEN 3
	NOTE G_, 4
	NOTE A_, 4
	LEN 4
	NOTE G_, 4
	LEN 10
	NOTE E_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	LEN 3
	NOTE A_, 4
	NOTE B_, 4
	LEN 4
	NOTE A_, 4
	LEN 10
	NOTE F_, 4
	NEXT
Pat_544A:
	NOTE B_, 4
	WAIT
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE A_, 4
	WAIT
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	LEN 3
	NOTE G_, 4
	NOTE A_, 4
	LEN 4
	NOTE G_, 4
	LEN 10
	NOTE E_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	LEN 3
	NOTE A_, 4
	NOTE B_, 4
	LEN 4
	NOTE A_, 4
	LEN 10
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NEXT
Pat_546D:
	CH_TRANSPOSE $18
	RELEASE $A2, $00
	VOLENV 15, $00, $00, $00
	WAVE Wave_6592
	PAT_CALL Pat_544A
	CH_TRANSPOSE $0C
	NOTE B_, 5
	WAIT
	NOTE G_, 5
	NOTE D_, 5
	NOTE G_, 5
	NOTE B_, 5
	NOTE A_, 5
	WAIT
	NOTE F_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 5
	NOTE F_, 6
	NOTE C_, 6
	NOTE G_, 5
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE C_, 6
	RELEASE $00
	NEXT
Pat_5499:
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 5
	INSTR 3
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 5
	INSTR 3
	NOTE C_, 2
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	LENGTH $3C
	DRUMS $FE, DrumPat_646A
	NOTE G_, 2
	NEXT
Pat_54DE:
	CH_TRANSPOSE $00
	LEN 3
	NOTE B_, 3
	NOTE C_, 4
	LEN 14
	NOTE B_, 3
	LEN 10
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE B_, 3
	LEN 3
	NOTE A_, 3
	NOTE B_, 3
	LEN 14
	NOTE A_, 3
	LEN 10
	NOTE Fsh, 3
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE E_, 3
	NOTE Fsh, 3
	NOTE G_, 3
	NOTE A_, 3
	VOLENV 15, $10, $1F, $1D
	LENGTH $F0
	NOTE B_, 3
	NEXT
Pat_5502:
	CH_TRANSPOSE $18
	RELEASE $A2, $00
	LEN 3
	NOTE B_, 4
	NOTE C_, 5
	LEN 14
	NOTE B_, 4
	LEN 10
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	LEN 3
	NOTE A_, 4
	NOTE B_, 4
	LEN 14
	NOTE A_, 4
	LEN 10
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE Fsh, 4
	VOLENV 15, $10, $1F, $1F
	LENGTH $F0
	NOTE G_, 4
	RELEASE $00
	NEXT

; Song 2: instrument table 1, arpeggio table 1
PlaySong2:
	push de
	push bc
	push hl
	call StopAll
	ld de, Song2_Ch1
	call StartMusicCh1
	ld de, Song2_Ch2
	call StartMusicCh2
	ld de, Song2_Ch3
	call StartMusicCh3
	ld a, LOW(InstrTable1_1 - 2)
	ldh [wInstrTable], a
	ld a, HIGH(InstrTable1_1 - 2)
	ldh [wInstrTableHi], a
	ld a, LOW(ArpTable)
	ldh [wArpTable], a
	ld a, HIGH(ArpTable)
	ldh [wArpTableHi], a
	ld a, $77
	ldh [rNR50], a
	pop hl
	pop bc
	pop de
	ret
Song2_Ch1:
	dw Pat_55E0
	dw Pat_5675
	dw Pat_5675
	dw Pat_5740
	dw Pat_57E0
	dw Pat_5843
	ORDER_LOOP Song2_Ch1
Song2_Ch2:
	dw Pat_55B8
	dw Pat_564C
	dw Pat_564C
	dw Pat_5703
	dw Pat_57B9
	dw Pat_5837
	ORDER_LOOP Song2_Ch2
Song2_Ch3:
	dw Pat_558B
	dw Pat_5619
	dw Pat_5619
	dw Pat_56B6
	dw Pat_5793
	dw Pat_5822
	ORDER_LOOP Song2_Ch3
Pat_558B:
	VOLENV 15, $00, $00, $00
	ARP_OFF
	RELEASE $00
	DRUMS $0C, DrumPat_6438
	CH_TRANSPOSE $24
	WAVE Wave_6562
	VIBRATO $00, $01, $06
	LENGTH $60
	PORTA $02, $0A
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	PORTA $03, $0A
	NOTE D_, 2
	NOTE G_, 2
	PORTA $04, $14
	NOTE A_, 2
	VOLENV 15, $1F, $1F, $17
	NOTE A_, 3
	PORTA_OFF
	NEXT
Pat_55B8:
	LENGTH $30
	DUTY_75
	HWENV $72, $0F, $17
	VIBRATO $09, $01, $06
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	HWENV $82, $0F, $27
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	HWENV $92, $0F, $37
	NOTE F_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE G_, 4
	HWENV $A2, $0F, $47
	NOTE A_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NEXT
Pat_55E0:
	LEN 24
	DUTY_75
	HWENV $72, $0F, $17
	VIBRATO $09, $01, $06
	LEN 25
	NOTE C_, 5
	LEN 24
	NOTE E_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE C_, 5
	NOTE E_, 4
	HWENV $82, $0F, $27
	NOTE C_, 5
	NOTE F_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE C_, 5
	NOTE E_, 4
	HWENV $92, $0F, $37
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE B_, 4
	NOTE D_, 4
	NOTE B_, 4
	NOTE D_, 4
	HWENV $A2, $0F, $47
	NOTE C_, 5
	NOTE E_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE D_, 5
	NOTE E_, 4
	NOTE E_, 5
	NOTE E_, 4
	NEXT
Pat_5619:
	LEN 24
	CH_TRANSPOSE $00
	WAVE Wave_6542
	VIBRATO $0C, $0A, $06
	RELEASE $02, $00
	VOLENV 15, $11, $18, $17
	ARP 0
	NOTE A_, 2
	WAIT
	WAIT
	NOTE A_, 2
	NOTE G_, 2
	WAIT
	WAIT
	NOTE G_, 2
	NOTE F_, 2
	WAIT
	WAIT
	NOTE F_, 2
	NOTE D_, 2
	WAIT
	NOTE G_, 2
	WAIT
	NOTE A_, 2
	WAIT
	WAIT
	NOTE A_, 2
	NOTE G_, 2
	WAIT
	WAIT
	NOTE G_, 2
	NOTE F_, 2
	WAIT
	WAIT
	NOTE F_, 2
	NOTE E_, 2
	WAIT
	NOTE G_, 2
	WAIT
	NEXT
Pat_564C:
	HWENV $C2, $0F, $37
	LEN 24
	NOTE A_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE B_, 3
	LEN 12
	NOTE A_, 3
	NOTE B_, 3
	WAIT
	NOTE G_, 3
	NEXT
Pat_5675:
	HWENV $C2, $0F, $37
	LEN 12
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE D_, 5
	NOTE E_, 5
	NOTE B_, 4
	WAIT
	NOTE B_, 4
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 5
	NOTE D_, 5
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	NOTE A_, 4
	LEN 24
	NOTE E_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	LEN 12
	NOTE G_, 4
	NOTE A_, 4
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	NOTE D_, 4
	WAIT
	WAIT
	NEXT
Pat_56B6:
	DRUMS $0C, DrumPat_6449
	PAT_CALL Pat_56E4
	PAT_CALL Pat_56E4
	PAT_CALL Pat_56E4
	LEN 12
	NOTE F_, 2
	WAIT
	WAIT
	INSTR 11
	NOTE F_, 5
	NOTE A_, 5
	NOTE C_, 6
	INSTR 10
	NOTE F_, 2
	WAIT
	NOTE G_, 2
	WAIT
	WAIT
	NOTE A_, 2
	WAIT
	WAIT
	NOTE B_, 2
	WAIT
	LEN 24
	NOTE F_, 2
	WAIT
	WAIT
	NOTE F_, 2
	VOLENV 15, $11, $14, $1E
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	WAIT
	NEXT
Pat_56E4:
	LEN 12
	NOTE F_, 2
	WAIT
	WAIT
	INSTR 11
	NOTE F_, 5
	NOTE A_, 5
	NOTE C_, 6
	INSTR 10
	NOTE F_, 2
	WAIT
	NOTE G_, 2
	WAIT
	WAIT
	INSTR 11
	NOTE G_, 5
	NOTE B_, 5
	NOTE D_, 6
	INSTR 10
	NOTE G_, 2
	WAIT
	LEN 24
	NOTE C_, 3
	WAIT
	WAIT
	NOTE C_, 3
	NOTE C_, 3
	WAIT
	NOTE G_, 2
	WAIT
	NEXT
Pat_5703:
	HWENV $E2, $0F, $67
	PAT_CALL Pat_572E
	PAT_CALL Pat_572E
	PAT_CALL Pat_572E
	NOTE A_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE F_, 3
	NOTE B_, 3
	LEN 12
	NOTE G_, 3
	NOTE A_, 3
	WAIT
	NOTE G_, 3
	LEN 24
	NOTE G_, 3
	NOTE F_, 3
	NOTE C_, 3
	NOTE F_, 3
	NOTE C_, 3
	LEN 12
	WAIT
	LEN 24
	NOTE F_, 3
	NOTE C_, 4
	HWENV $F3, $0F, $97
	NOTE A_, 4
	LEN 12
	NOTE F_, 5
	LEN 24
	NEXT
Pat_572E:
	LEN 24
	NOTE A_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE F_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NEXT
Pat_5740:
	HWENV $E2, $0F, $67
	PAT_CALL Pat_5772
	PAT_CALL Pat_5772
	PAT_CALL Pat_5772
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	NOTE B_, 3
	WAIT
	NOTE A_, 3
	WAIT
	WAIT
	WAIT
	NOTE A_, 3
	WAIT
	WAIT
	WAIT
	NOTE C_, 3
	WAIT
	NOTE A_, 3
	WAIT
	HWENV $F3, $0F, $97
	NOTE F_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NEXT
Pat_5772:
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE F_, 4
	NOTE E_, 4
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	NEXT
Pat_5793:
	LEN 24
	NOTE C_, 3
	WAIT
	WAIT
	NOTE C_, 3
	NOTE Ash, 2
	WAIT
	WAIT
	NOTE Ash, 2
	NOTE F_, 2
	WAIT
	WAIT
	NOTE F_, 2
	NOTE G_, 2
	WAIT
	NOTE Ash, 2
	WAIT
	NOTE C_, 3
	WAIT
	WAIT
	NOTE C_, 3
	NOTE Ash, 2
	WAIT
	WAIT
	NOTE Ash, 2
	NOTE F_, 2
	WAIT
	WAIT
	NOTE F_, 2
	VOLENV 15, $11, $14, $1A
	NOTE G_, 2
	WAIT
	NOTE Ash, 2
	WAIT
	NEXT
Pat_57B9:
	NOTE E_, 5
	NOTE G_, 4
	NOTE E_, 5
	NOTE G_, 4
	NOTE D_, 5
	NOTE F_, 4
	NOTE D_, 5
	NOTE F_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE D_, 5
	NOTE G_, 4
	NOTE D_, 5
	NOTE D_, 5
	NOTE G_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE Ash, 3
	NOTE F_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE F_, 3
	NOTE C_, 4
	NOTE D_, 4
	LEN 12
	NOTE B_, 3
	WAIT
	NOTE G_, 3
	WAIT
	LEN 16
	NOTE Ash, 3
	NOTE F_, 4
	WAIT
	LEN 24
	NEXT
Pat_57E0:
	NOTE G_, 5
	WAIT
	WAIT
	WAIT
	NOTE G_, 5
	WAIT
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	WAIT
	WAIT
	WAIT
	NOTE G_, 5
	WAIT
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE A_, 5
	NOTE G_, 5
	WAIT
	WAIT
	NOTE E_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE E_, 5
	WAIT
	WAIT
	WAIT
	NOTE E_, 5
	WAIT
	NOTE F_, 5
	NOTE G_, 5
	NOTE E_, 5
	WAIT
	WAIT
	WAIT
	NOTE E_, 5
	WAIT
	NOTE F_, 5
	NOTE G_, 5
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE D_, 5
	NOTE E_, 5
	NOTE D_, 5
	WAIT
	WAIT
	WAIT
	LEN 16
	NOTE D_, 5
	NOTE C_, 5
	NOTE G_, 4
	LEN 12
	NEXT
Pat_5822:
	LEN 24
	NOTE C_, 2
	WAIT
	WAIT
	NOTE C_, 2
	NOTE C_, 2
	WAIT
	WAIT
	WAIT
	VOLENV 15, $12, $1F, $15
	DRUMS $FA, DrumPat_646A
	LENGTH $C0
	NOTE C_, 2
	NEXT
Pat_5837:
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	LENGTH $C0
	NOTE C_, 4
	NEXT
Pat_5843:
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	LEN 8
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	LENGTH $BF
	NOTE E_, 4
	NEXT

; Song 3: instrument table 1, arpeggio table 1
PlaySong3:
	push hl
	push de
	push bc
	call StopAll
	ld de, Song3_Ch1
	call StartMusicCh1
	ld de, Song3_Ch3
	call StartMusicCh3
	ld de, Song3_Ch2
	call StartMusicCh2
	ld a, HIGH(InstrTable1_1 - 2)
	ldh [wInstrTableHi], a
	ld a, LOW(InstrTable1_1 - 2)
	ldh [wInstrTable], a
	ld a, HIGH(ArpTable)
	ldh [wArpTableHi], a
	ld a, LOW(ArpTable)
	ldh [wArpTable], a
	pop bc
	pop de
	pop hl
	ret
Song3_Ch1:
	dw Pat_5891
	dw Pat_5891
	dw Pat_5918
	dw Pat_5918
	ORDER_LOOP Song3_Ch1
Pat_5891:
	LEN 16
	INSTR 3
	DRUMS $08, DrumPat_646D
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 3
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 3
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 3
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 3
	INSTR 1
	NOTE G_, 4
	NEXT
Pat_5918:
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE E_, 2
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE B_, 2
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE E_, 2
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE B_, 2
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE E_, 2
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE B_, 2
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE E_, 2
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE B_, 2
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	NEXT
Song3_Ch3:
	dw Pat_59A5
	dw Pat_59A5
	dw Pat_5A3B
	dw Pat_5A3B
	ORDER_LOOP Song3_Ch3
Pat_59A5:
	LEN 8
	INSTR 12
	INSTR 12
	NOTE G_, 4
	WAIT
	INSTR 5
	NOTE Fsh, 6
	NOTE D_, 6
	NOTE B_, 5
	WAIT
	INSTR 12
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	INSTR 5
	NOTE Fsh, 6
	NOTE D_, 6
	NOTE B_, 5
	WAIT
	INSTR 12
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE B_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE G_, 3
	WAIT
	INSTR 5
	NOTE Fsh, 5
	NOTE D_, 5
	NOTE B_, 4
	WAIT
	INSTR 12
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	INSTR 5
	NOTE Fsh, 5
	NOTE D_, 5
	NOTE B_, 4
	WAIT
	INSTR 12
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	NOTE D_, 3
	WAIT
	NOTE G_, 3
	WAIT
	NOTE B_, 3
	WAIT
	NOTE C_, 4
	WAIT
	INSTR 13
	NOTE E_, 6
	NOTE D_, 6
	NOTE E_, 6
	REST
	NOTE E_, 6
	NOTE D_, 6
	NOTE C_, 6
	WAIT
	INSTR 12
	NOTE E_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE C_, 4
	WAIT
	NOTE D_, 4
	WAIT
	INSTR 13
	NOTE Fsh, 6
	NOTE E_, 6
	NOTE Fsh, 6
	REST
	NOTE Fsh, 6
	NOTE E_, 6
	NOTE D_, 6
	WAIT
	INSTR 12
	NOTE A_, 3
	WAIT
	NOTE D_, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE G_, 4
	WAIT
	INSTR 13
	PORTA $05, $04
	NOTE G_, 5
	WAIT
	NOTE B_, 5
	WAIT
	NOTE D_, 6
	WAIT
	NOTE G_, 6
	WAIT
	NOTE B_, 5
	WAIT
	NOTE D_, 6
	PORTA_OFF
	WAIT
	INSTR 12
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	WAIT
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	WAIT
	NOTE B_, 3
	NOTE B_, 3
	NOTE B_, 3
	WAIT
	NOTE G_, 3
	NOTE Fsh, 3
	NEXT
Pat_5A3B:
	VOLENV 15, $00, $1F, $12
	ARP 4
	WAVE Wave_65A2
	NOTE B_, 3
	WAIT
	NOTE B_, 3
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 4
	WAIT
	NOTE B_, 3
	WAIT
	NOTE B_, 3
	WAIT
	NOTE B_, 4
	WAIT
	NOTE G_, 3
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	NOTE G_, 3
	NOTE B_, 3
	WAIT
	NOTE B_, 3
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 4
	WAIT
	NOTE B_, 3
	WAIT
	NOTE B_, 3
	WAIT
	NOTE B_, 4
	WAIT
	NOTE G_, 3
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	NOTE G_, 3
	NOTE G_, 3
	WAIT
	NOTE G_, 3
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 4
	WAIT
	NOTE Fsh, 3
	WAIT
	NOTE Fsh, 3
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE G_, 3
	WAIT
	NOTE G_, 3
	WAIT
	NOTE G_, 4
	WAIT
	NOTE E_, 3
	WAIT
	NOTE E_, 4
	WAIT
	NOTE Fsh, 3
	WAIT
	NOTE Fsh, 3
	NOTE E_, 3
	INSTR 13
	RELEASE $02, $00
	VIBRATO $08, $01, $05
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
	NOTE E_, 6
	NOTE Fsh, 6
	NOTE G_, 6
	NOTE A_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE Fsh, 6
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	RELEASE $00
	VOLENV 15, $11, $1F, $12
	ARP 4
	WAVE Wave_65A2
	NOTE A_, 3
	WAIT
	NOTE D_, 4
	WAIT
	NOTE Fsh, 4
	NOTE Fsh, 4
	NEXT
Song3_Ch2:
	dw Pat_5AE2
	dw Pat_5AE2
	dw Pat_5B6E
	dw Pat_5B6E
	ORDER_LOOP Song3_Ch2
Pat_5AE2:
	DUTY_50
	LEN 8
	HWENV $F3, $08, $85
	VIBRATO $08, $02, $05
	ARP 4
	NOTE B_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	NOTE C_, 5
	NOTE B_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	NOTE C_, 5
	NOTE B_, 4
	WAIT
	NOTE A_, 4
	NOTE C_, 5
	NOTE B_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE B_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE B_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	NOTE B_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	NOTE B_, 3
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	NOTE B_, 3
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	NOTE B_, 3
	WAIT
	NOTE G_, 3
	WAIT
	NOTE B_, 3
	WAIT
	NOTE D_, 4
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE A_, 3
	WAIT
	NOTE C_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE B_, 4
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
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	WAIT
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	WAIT
	NOTE B_, 3
	NOTE A_, 3
	NEXT
Pat_5B6E:
	DUTY_75
	HWENV $F2, $00
	ARP 4
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE E_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE E_, 5
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE B_, 3
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 4
	NOTE B_, 3
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE E_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE E_, 5
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE B_, 3
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 4
	NOTE B_, 3
	NOTE B_, 3
	WAIT
	NOTE B_, 3
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 4
	WAIT
	NOTE B_, 3
	WAIT
	NOTE B_, 3
	WAIT
	NOTE B_, 4
	WAIT
	NOTE G_, 3
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	NOTE G_, 3
	NOTE B_, 3
	WAIT
	NOTE B_, 3
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	NOTE G_, 3
	WAIT
	NOTE G_, 3
	NOTE Fsh, 3
	NOTE E_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	NOTE G_, 3
	NOTE Fsh, 3
	WAIT
	NOTE Fsh, 3
	WAIT
	NOTE Fsh, 3
	NOTE E_, 3
	NOTE D_, 3
	WAIT
	NOTE G_, 3
	WAIT
	NOTE D_, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE A_, 4
	NOTE A_, 4
	NEXT

; Song 4: instrument table 2, arpeggio table 1
PlaySong4:
	push hl
	push de
	push bc
	call StopAll
	ld de, Song4_Ch1
	call StartMusicCh1
	ld de, Song4_Ch2
	call StartMusicCh2
	ld de, Song4_Ch3
	call StartMusicCh3
	ld a, HIGH(InstrTable2_1 - 2)
	ldh [wInstrTableHi], a
	ld a, LOW(InstrTable2_1 - 2)
	ldh [wInstrTable], a
	ld a, HIGH(ArpTable)
	ldh [wArpTableHi], a
	ld a, LOW(ArpTable)
	ldh [wArpTable], a
	pop bc
	pop de
	pop hl
	ret
Song4_Ch1:
	dw Pat_5D58
	dw Pat_5C36
	dw Pat_5CF7
	dw Pat_5D58
	dw Pat_5C36
	dw Pat_5CF7
	dw Pat_5CF7
	dw Pat_5D58
	dw Pat_5D58
	ORDER_LOOP Song4_Ch1
Pat_5C36:
	LEN 12
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 3
	WAIT
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 3
	WAIT
	INSTR 0
	NOTE E_, 2
	WAIT
	INSTR 1
	NOTE E_, 3
	WAIT
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 3
	NOTE A_, 3
	INSTR 0
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 3
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE Gsh, 2
	WAIT
	INSTR 1
	NOTE Gsh, 3
	NOTE Gsh, 3
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 3
	WAIT
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 3
	WAIT
	INSTR 0
	NOTE E_, 2
	WAIT
	INSTR 1
	NOTE E_, 3
	WAIT
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 3
	NOTE A_, 3
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 3
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE Dsh, 3
	WAIT
	INSTR 1
	NOTE Dsh, 4
	NOTE Dsh, 4
	INSTR 0
	NOTE E_, 3
	WAIT
	INSTR 1
	NOTE E_, 4
	NOTE E_, 4
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 3
	WAIT
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 3
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 3
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 3
	WAIT
	INSTR 0
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE D_, 3
	WAIT
	INSTR 0
	NOTE E_, 2
	WAIT
	INSTR 1
	NOTE E_, 3
	NOTE E_, 3
	INSTR 0
	NOTE E_, 2
	WAIT
	INSTR 1
	NOTE E_, 3
	NOTE E_, 3
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 3
	WAIT
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 3
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 3
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 3
	WAIT
	INSTR 0
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE D_, 3
	WAIT
	INSTR 0
	NOTE E_, 2
	WAIT
	INSTR 1
	NOTE E_, 3
	WAIT
	INSTR 0
	NOTE A_, 2
	WAIT
	NOTE E_, 2
	NOTE G_, 2
	NEXT
Pat_5CF7:
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 3
	WAIT
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 3
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 3
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 3
	WAIT
	INSTR 0
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE D_, 3
	WAIT
	INSTR 0
	NOTE E_, 2
	WAIT
	INSTR 1
	NOTE E_, 3
	NOTE E_, 3
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 3
	NOTE A_, 3
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 3
	WAIT
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 3
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 3
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 3
	WAIT
	INSTR 0
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE D_, 3
	WAIT
	INSTR 0
	NOTE E_, 2
	WAIT
	INSTR 1
	NOTE E_, 3
	NOTE E_, 3
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 3
	WAIT
	NEXT
Pat_5D58:
	LEN 12
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE E_, 2
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 0
	NOTE E_, 2
	WAIT
	INSTR 1
	NOTE B_, 3
	WAIT
	NOTE B_, 3
	WAIT
	INSTR 0
	NOTE E_, 2
	WAIT
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE E_, 2
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 0
	NOTE E_, 2
	WAIT
	INSTR 1
	NOTE B_, 3
	WAIT
	NOTE B_, 3
	WAIT
	INSTR 0
	NOTE E_, 2
	WAIT
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE E_, 2
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 0
	NOTE B_, 2
	WAIT
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE Fsh, 2
	NOTE B_, 2
	WAIT
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE B_, 2
	INSTR 0
	NOTE E_, 2
	WAIT
	INSTR 1
	NOTE E_, 4
	WAIT
	NOTE E_, 4
	WAIT
	INSTR 0
	NOTE E_, 2
	WAIT
	NEXT
Song4_Ch2:
	dw Pat_5E80
	dw Pat_5DD2
	dw Pat_5E1E
	dw Pat_5E80
	dw Pat_5DD2
	dw Pat_5E1E
	dw Pat_5E1E
	dw Pat_5EE8
	dw Pat_5EE8
	ORDER_LOOP Song4_Ch2
Pat_5DD2:
	LEN 24
	REST
	INSTR 1
	LEN 48
	NOTE C_, 4
	NOTE A_, 3
	NOTE Gsh, 3
	LEN 12
	NOTE C_, 4
	LEN 36
	NOTE C_, 4
	LEN 48
	NOTE F_, 4
	NOTE B_, 3
	LEN 12
	NOTE G_, 3
	NOTE G_, 3
	WAIT
	WAIT
	NOTE D_, 4
	LEN 36
	NOTE D_, 4
	LEN 48
	NOTE C_, 4
	NOTE A_, 3
	NOTE Gsh, 3
	LEN 12
	NOTE C_, 4
	LEN 36
	NOTE C_, 4
	LEN 48
	NOTE B_, 3
	NOTE E_, 4
	LEN 12
	NOTE Fsh, 4
	NOTE Fsh, 4
	WAIT
	WAIT
	NOTE Gsh, 4
	LEN 36
	NOTE Gsh, 4
	LEN 48
	NOTE C_, 4
	NOTE A_, 3
	NOTE B_, 3
	LEN 12
	NOTE E_, 4
	LEN 36
	NOTE E_, 4
	LEN 48
	NOTE C_, 4
	NOTE A_, 3
	LEN 12
	NOTE Gsh, 3
	NOTE Gsh, 3
	WAIT
	WAIT
	NOTE Gsh, 3
	LEN 36
	NOTE Gsh, 3
	LEN 48
	NOTE C_, 4
	NOTE A_, 3
	NOTE B_, 3
	LEN 12
	NOTE E_, 4
	LEN 36
	NOTE E_, 4
	LEN 48
	NOTE C_, 4
	NOTE D_, 4
	LEN 24
	NOTE B_, 3
	LEN 48
	NOTE E_, 4
	NEXT
Pat_5E1E:
	LEN 12
	INSTR 2
	NOTE C_, 4
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE B_, 3
	NOTE A_, 3
	WAIT
	INSTR 1
	NOTE A_, 3
	INSTR 2
	NOTE C_, 4
	NOTE B_, 3
	WAIT
	INSTR 1
	NOTE B_, 3
	INSTR 2
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	INSTR 1
	NOTE E_, 4
	NOTE E_, 4
	INSTR 2
	NOTE A_, 3
	WAIT
	INSTR 1
	NOTE A_, 3
	INSTR 2
	NOTE G_, 3
	NOTE F_, 3
	WAIT
	INSTR 1
	NOTE B_, 3
	INSTR 2
	NOTE A_, 3
	NOTE Gsh, 3
	WAIT
	INSTR 1
	NOTE Gsh, 3
	NOTE Gsh, 3
	INSTR 2
	NOTE A_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	NOTE C_, 4
	INSTR 2
	NOTE C_, 4
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE B_, 3
	NOTE A_, 3
	WAIT
	INSTR 1
	NOTE A_, 3
	INSTR 2
	NOTE C_, 4
	NOTE B_, 3
	WAIT
	INSTR 1
	NOTE B_, 3
	INSTR 2
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	INSTR 1
	NOTE E_, 4
	NOTE E_, 4
	INSTR 2
	NOTE A_, 3
	WAIT
	INSTR 1
	NOTE A_, 3
	INSTR 2
	NOTE G_, 3
	NOTE F_, 3
	WAIT
	INSTR 1
	NOTE B_, 3
	INSTR 2
	NOTE A_, 3
	NOTE Gsh, 3
	WAIT
	INSTR 1
	NOTE Gsh, 3
	NOTE Gsh, 3
	INSTR 2
	NOTE E_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	WAIT
	NEXT
Pat_5E80:
	LEN 12
	INSTR 5
	NOTE A_, 4
	WAIT
	INSTR 1
	NOTE E_, 4
	INSTR 5
	NOTE A_, 4
	WAIT
	WAIT
	INSTR 1
	NOTE E_, 4
	INSTR 5
	NOTE A_, 4
	INSTR 5
	NOTE Gsh, 4
	WAIT
	INSTR 1
	NOTE Dsh, 4
	INSTR 5
	NOTE Gsh, 4
	INSTR 1
	NOTE Dsh, 4
	INSTR 5
	NOTE Gsh, 4
	WAIT
	WAIT
	INSTR 5
	NOTE A_, 4
	WAIT
	INSTR 1
	NOTE E_, 4
	INSTR 5
	NOTE A_, 4
	WAIT
	WAIT
	INSTR 1
	NOTE E_, 4
	INSTR 5
	NOTE A_, 4
	INSTR 5
	NOTE Gsh, 4
	WAIT
	INSTR 1
	NOTE Dsh, 4
	INSTR 5
	NOTE Gsh, 4
	INSTR 1
	NOTE Dsh, 4
	INSTR 5
	NOTE Gsh, 4
	WAIT
	WAIT
	INSTR 5
	NOTE A_, 4
	WAIT
	INSTR 1
	NOTE E_, 4
	INSTR 5
	NOTE A_, 4
	WAIT
	WAIT
	INSTR 1
	NOTE E_, 4
	INSTR 5
	NOTE A_, 4
	WAIT
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 5
	NOTE A_, 4
	WAIT
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 5
	NOTE A_, 4
	INSTR 5
	NOTE B_, 4
	WAIT
	INSTR 1
	NOTE Fsh, 4
	INSTR 5
	NOTE B_, 4
	WAIT
	WAIT
	INSTR 1
	NOTE Fsh, 4
	INSTR 5
	NOTE B_, 4
	WAIT
	WAIT
	INSTR 1
	NOTE Gsh, 4
	INSTR 5
	NOTE B_, 4
	INSTR 1
	NOTE Gsh, 4
	INSTR 5
	NOTE B_, 4
	WAIT
	WAIT
	NEXT
Pat_5EE8:
	LEN 48
	DUTY_50
	HWENV $70, $00
	VIBRATO $00, $02, $05
	PORTA $0E, $08
	ARP_OFF
	NOTE E_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE B_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE B_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE C_, 5
	NOTE Fsh, 4
	NOTE Dsh, 5
	PORTA_OFF
	LEN 12
	NOTE Gsh, 4
	WAIT
	INSTR 1
	NOTE E_, 4
	NOTE F_, 4
	LEN 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 12
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NEXT
Song4_Ch3:
	dw Pat_603A
	dw Pat_5F27
	dw Pat_5FD8
	dw Pat_6033
	dw Pat_5F2F
	dw Pat_5FD8
	dw Pat_5FD8
	dw Pat_60AA
	ORDER_LOOP Song4_Ch3
Pat_5F27:
	CH_TRANSPOSE $18
	WAVE Wave_6572
	PAT_GOTO Pat_5F34
Pat_5F2F:
	CH_TRANSPOSE $0C
	WAVE Wave_6582
Pat_5F34:
	VOLENV 11, $14, $00, $11
	RELEASE $C2, $60
	LEN 12
	VIBRATO $0C, $01, $05
	DRUMS $0C, DrumPat_647E
	NOTE E_, 4
	WAIT
	WAIT
	NOTE C_, 4
	NOTE A_, 3
	WAIT
	WAIT
	NOTE C_, 4
	NOTE B_, 3
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE A_, 3
	PORTA $02, $0C
	NOTE E_, 4
	WAIT
	PORTA_OFF
	NOTE D_, 4
	WAIT
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 16
	NOTE E_, 4
	LEN 12
	NOTE B_, 3
	WAIT
	NOTE E_, 4
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	NOTE C_, 4
	NOTE A_, 3
	WAIT
	WAIT
	NOTE C_, 4
	NOTE B_, 3
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE A_, 3
	PORTA $02, $0C
	NOTE A_, 4
	WAIT
	PORTA_OFF
	NOTE G_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 12
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE B_, 4
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	LEN 4
	NOTE B_, 3
	NOTE C_, 4
	LEN 40
	NOTE B_, 3
	LEN 12
	NOTE A_, 4
	WAIT
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	LEN 4
	NOTE B_, 4
	NOTE C_, 5
	LEN 16
	NOTE B_, 4
	LEN 48
	NOTE A_, 4
	NEXT
Pat_5FD8:
	LEN 12
	DRUMS $06, DrumPat_649F
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 12
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 12
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	LEN 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 12
	NOTE C_, 4
	WAIT
	WAIT
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 12
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 12
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE Gsh, 3
	WAIT
	LEN 4
	NOTE A_, 3
	NOTE B_, 3
	LEN 40
	NOTE A_, 3
	NEXT
Pat_6033:
	DRUMS $06, DrumPat_64F1
	PAT_GOTO Pat_603E
Pat_603A:
	DRUMS $0C, DrumPat_64E0
Pat_603E:
	LEN 12
	CH_TRANSPOSE $00
	INSTR 4
	NOTE E_, 4
	WAIT
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE E_, 4
	WAIT
	WAIT
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE E_, 4
	INSTR 4
	NOTE Dsh, 4
	WAIT
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 4
	WAIT
	WAIT
	INSTR 4
	NOTE E_, 4
	WAIT
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE E_, 4
	WAIT
	WAIT
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE E_, 4
	INSTR 4
	NOTE Dsh, 4
	WAIT
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 4
	WAIT
	WAIT
	INSTR 4
	NOTE E_, 4
	WAIT
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE E_, 4
	WAIT
	WAIT
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE E_, 4
	INSTR 4
	NOTE F_, 4
	WAIT
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE F_, 4
	WAIT
	WAIT
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 4
	NOTE Fsh, 4
	WAIT
	INSTR 3
	NOTE B_, 3
	INSTR 4
	NOTE Fsh, 4
	WAIT
	WAIT
	INSTR 3
	NOTE B_, 3
	INSTR 4
	NOTE Fsh, 4
	INSTR 4
	NOTE Gsh, 4
	WAIT
	INSTR 3
	NOTE B_, 3
	INSTR 4
	NOTE Gsh, 4
	INSTR 3
	NOTE B_, 3
	INSTR 4
	NOTE Gsh, 4
	WAIT
	WAIT
	NEXT
Pat_60AA:
	DRUMS $06, DrumPat_64F1
	VIBRATO $00, $01, $06
	VOLENV 15, $00, $00, $00
	WAVE Wave_6562
	RELEASE $00
	PORTA $01, $12
	LENGTH $60
	CH_TRANSPOSE $0C
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE B_, 4
	PORTA $03, $06
	LEN 12
	NOTE E_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 5
	WAIT
	WAIT
	WAIT
	NOTE Gsh, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE E_, 5
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 5
	WAIT
	WAIT
	WAIT
	NOTE Ash, 5
	WAIT
	NOTE B_, 5
	WAIT
	NOTE E_, 6
	WAIT
	WAIT
	WAIT
	NOTE C_, 6
	WAIT
	WAIT
	WAIT
	NOTE A_, 5
	WAIT
	WAIT
	WAIT
	NOTE C_, 6
	WAIT
	WAIT
	WAIT
	NOTE A_, 5
	WAIT
	NOTE F_, 5
	NOTE E_, 5
	NOTE Dsh, 5
	WAIT
	NOTE Fsh, 5
	WAIT
	NOTE A_, 5
	WAIT
	NOTE C_, 6
	WAIT
	NOTE B_, 5
	WAIT
	NOTE Gsh, 5
	WAIT
	NOTE E_, 5
	WAIT
	WAIT
	WAIT
	PORTA_OFF
	NEXT

; Song 5: instrument table 2, arpeggio table 1
PlaySong5:
	push hl
	push de
	push bc
	call StopAll
	ld de, Song5_Ch1
	call StartMusicCh1
	ld de, Song5_Ch2
	call StartMusicCh2
	ld de, Song5_Ch3
	call StartMusicCh3
	ld a, HIGH(InstrTable2_1 - 2)
	ldh [wInstrTableHi], a
	ld a, LOW(InstrTable2_1 - 2)
	ldh [wInstrTable], a
	ld a, HIGH(ArpTable)
	ldh [wArpTableHi], a
	ld a, LOW(ArpTable)
	ldh [wArpTable], a
	pop bc
	pop de
	pop hl
	ret
Song5_Ch1:
	dw Pat_614D
	dw Pat_614D
	dw Pat_6183

; Unreferenced (4 bytes)
	db $00, $00, $43, $61
Pat_614D:
	LEN 11
	DUTY_50
	HWENV $D1, $00
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE E_, 6
	NOTE G_, 6
	NOTE Ash, 2
	NOTE D_, 3
	NOTE F_, 3
	NOTE Ash, 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE Ash, 5
	NOTE D_, 6
	NOTE F_, 6
	NOTE Gsh, 2
	NOTE C_, 3
	NOTE Dsh, 3
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE Gsh, 5
	NOTE C_, 6
	NOTE Dsh, 6
	NOTE G_, 2
	NOTE B_, 2
	NOTE D_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE G_, 5
	NOTE B_, 5
	NOTE D_, 6
	NEXT
Pat_6183:
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE E_, 6
	NOTE G_, 6
	NOTE C_, 7
	WAIT
	WAIT
	WAIT
	VIBRATO $16, $03, $05
	WAIT
	WAIT
	LENGTH $74
	HWENV $19, $0B, $F7
	NOTE C_, 3
	END

; Unreferenced (1 bytes)
	db $6A
Song5_Ch2:
	dw Pat_61AC
	dw Pat_61AC
	dw Pat_61E5

; Unreferenced (4 bytes)
	db $00, $00, $A2, $61
Pat_61AC:
	LEN 11
	DUTY_50
	HWENV $0F, $05, $62
	AUTOPAN $06
	NOTE D_, 6
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE E_, 6
	NOTE G_, 6
	NOTE Ash, 2
	NOTE D_, 3
	NOTE F_, 3
	NOTE Ash, 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE Ash, 5
	NOTE D_, 6
	NOTE F_, 6
	NOTE Gsh, 2
	NOTE C_, 3
	NOTE Dsh, 3
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE Gsh, 5
	NOTE C_, 6
	NOTE Dsh, 6
	NOTE G_, 2
	NOTE B_, 2
	NOTE D_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE G_, 5
	NOTE B_, 5
	NEXT
Pat_61E5:
	NOTE D_, 6
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE E_, 6
	NOTE G_, 6
	NOTE C_, 7
	AUTOPAN $00
	WAIT
	WAIT
	VIBRATO $16, $01, $05
	WAIT
	WAIT
	LENGTH $74
	HWENV $19, $11, $F7
	NOTE D_, 5
	END

; Unreferenced (1 bytes)
	db $6A
Song5_Ch3:
	dw Pat_6210
	dw Pat_625A
	dw Pat_6297

; Unreferenced (4 bytes)
	db $00, $00, $06, $62
Pat_6210:
	FADE $0B, FadeTable_4690
	LEN 11
	VOLENV 5, $5F, $00, $11
	CH_TRANSPOSE $0C
	VIBRATO $28, $02, $05
	PORTA $03, $04
	DRUMS $46, DrumPat_6620
	WAVE Wave_6572
	NOTE B_, 4
	WAIT
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NEXT
Pat_625A:
	PORTA $04, $0A
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE D_, 5
	PORTA $02, $0A
	WAIT
	WAIT
	WAIT
	NOTE E_, 5
	WAIT
	NOTE C_, 5
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
	WAIT
	PORTA $04, $0A
	NOTE Gsh, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE D_, 5
	PORTA $04, $04
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE G_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NEXT
Pat_6297:
	NOTE E_, 4
	NOTE F_, 4
	VOLENV 15, $1F, $1F, $1F
	NOTE G_, 4
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
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	DRUMS_OFF
	FADE_OFF
	VIBRATO $28, $01, $05
	LENGTH $74
	VOLENV 0, $1F, $1F, $18
	NOTE B_, 4
	END

; Instrument table 1, entries 1..14 (the song routines point 2 bytes before:
; entry 0 is never read)
InstrTable1_1:
	dw Instr1_0
	dw Instr1_1
	dw Instr1_2
	dw Instr1_3
	dw Instr1_4
	dw Instr1_5
	dw Instr1_6
	dw Instr1_7
	dw Instr1_8
	dw Instr1_9
	dw Instr1_10
	dw Instr1_11
	dw Instr1_12
	dw Instr1_13
Instr1_0:
	WAVE Wave_6542
	VOLENV 15, $11, $18, $14
	ARP 0
	VIBRATO $0A, $08, $04
	END
Instr1_1:
	AUTODUTY $03
	HWENV $F1, $00
	ARP 2
	END
Instr1_2:
	AUTODUTY $03
	HWENV $F1, $00
	ARP 3
	END
Instr1_3:
	DUTY_50
	HWENV $F3, $00
	ARP 0
	END
Instr1_4:
	WAVE Wave_6532
	VOLENV 15, $00, $1F, $11
	ARP 2
	END
Instr1_5:
	VOLENV 15, $11, $15, $12
	ARP 0
	VIBRATO $0A, $02, $04
	WAVE Wave_6582
	END
Instr1_6:
	VOLENV 15, $00, $00, $00
	WAVE Wave_6572
	END
Instr1_7:
	DUTY_12
	ARP 0
	HWENV $F2, $00
	END
Instr1_8:
	DUTY_50
	AUTODUTY $03
	HWENV $F1, $00
	ARP 2
	END
Instr1_9:
	DUTY_50
	END
Instr1_10:
	WAVE Wave_6542
	VIBRATO $0C, $0A, $06
	VOLENV 15, $11, $16, $18
	ARP 0
	END
Instr1_11:
	WAVE Wave_6562
	VOLENV 15, $11, $18, $12
	ARP 0
	END
Instr1_12:
	WAVE Wave_65A2
	VOLENV 15, $11, $15, $11
	ARP 0
	END
Instr1_13:
	VOLENV 15, $00, $00, $00
	WAVE Wave_6572
	END

; Instrument table 2, entries 1..6 (the song routines point 2 bytes before:
; entry 0 is never read)
InstrTable2_1:
	dw Instr2_0
	dw Instr2_1
	dw Instr2_2
	dw Instr2_3
	dw Instr2_4
	dw Instr2_5
Instr2_0:
	DUTY_50
	HWENV $F2, $00
	VIBRATO $06, $08, $05
	ARP 0
	END
Instr2_1:
	DUTY_12
	HWENV $F1, $05, $A2
	VIBRATO $04, $02, $05
	ARP 4
	END
Instr2_2:
	DUTY_75
	HWENV $F2, $00
	END
Instr2_3:
	WAVE Wave_65B2
	VOLENV 15, $00, $1F, $11
	VIBRATO $04, $02, $05
	ARP 4
	END
Instr2_4:
	WAVE Wave_6532
	VOLENV 4, $00, $00, $00
	VIBRATO $00, $04, $05
	END
Instr2_5:
	DUTY_50
	HWENV $40, $00
	VIBRATO $00, $04, $05
	END
ArpTable:
	dw Arp0
	dw Arp1
	dw Arp2
	dw Arp3
	dw Arp4
Arp0:
	db $0C, $00, ARP_HOLD
Arp1:
	db $00, $0C, $00, $00, $00, $00, $00, $00
	db $00, $00, ARP_LOOP
Arp2:
	db $00, $04, $07, ARP_LOOP
Arp3:
	db $00, $03, $07, ARP_LOOP
Arp4:
	db $00, $0C, $00, ARP_HOLD
DrumPat_63B9:
	db $06, $00, $00, $06, $00, $06, $06, $00
	db $00, $03, $00, $00, DRUM_LOOP
DrumPat_63C6:
	db $06, $00, $06, $03, $00, $06, $06, $00
	db $06, $03, $00, $06, DRUM_LOOP
DrumPat_63D3:
	db $01, $00, $06, $00, $06, $00, $04, $00
	db $06, $00, $06, $00, $01, $00, $06, $00
	db $06, $00, $04, $00, $06, $00, $06, $06
	db $01, $00, $06, $00, $06, $00, $04, $00
	db $06, $00, $06, $00, $01, $00, $06, $00
	db $06, $00, $04, $00, $06, $00, $04, $00
	db DRUM_LOOP
DrumPat_6404:
	db $01, $00, $06, $00, $06, $00, $02, $00
	db $06, $00, $06, $00, $01, $00, $06, $00
	db $06, $00, $02, $00, $06, $00, $06, $06
	db DRUM_LOOP
DrumPat_641D:
	db $06, $00, $00, $00, $06, $00, $04, $00
	db $00, $00, $00, $00, $06, $00, $00, $00
	db $06, $00, $04, $00, $00, $00, $06, $00
	db DRUM_LOOP
DrumPat_6436:
	db $01, DRUM_LOOP
DrumPat_6438:
	db $01, $00, $06, $00, $04, $00, $06, $00
	db $01, $00, $06, $00, $04, $00, $01, $00
	db DRUM_LOOP
DrumPat_6449:
	db $07, $00, $00, $06, $02, $06, $04, $06
	db $01, $06, $04, $06, $02, $06, $01, $06
	db $01, $06, $04, $06, $02, $06, $04, $06
	db $01, $06, $04, $06, $02, $06, $01, $06
	db DRUM_LOOP
DrumPat_646A:
	db $75, $07, DRUM_LOOP
DrumPat_646D:
	db $06, $00, $06, $06, $04, $00, $06, $06
	db $06, $00, $06, $06, $04, $06, $06, $06
	db DRUM_LOOP
DrumPat_647E:
	db $06, $06, $04, $06, $06, $06, $04, $06
	db $06, $06, $04, $06, $06, $06, $04, $04
	db $06, $06, $04, $06, $06, $06, $04, $06
	db $06, $06, $04, $04, $06, $06, $04, $04
	db DRUM_LOOP
DrumPat_649F:
	db $07, $00, $00, $00, $04, $00, $06, $00
	db $01, $00, $06, $00, $04, $00, $06, $06
	db $01, $00, $06, $00, $04, $00, $06, $00
	db $01, $00, $06, $00, $04, $00, $04, $06
	db $01, $00, $06, $00, $04, $00, $06, $00
	db $01, $00, $06, $00, $04, $00, $06, $06
	db $01, $00, $06, $00, $04, $00, $04, $00
	db $01, $00, $06, $00, $04, $00, $04, $06
	db DRUM_LOOP
DrumPat_64E0:
	db $01, $00, $06, $01, $01, $00, $06, $01
	db $01, $00, $06, $06, $06, $06, $04, $00
	db DRUM_LOOP
DrumPat_64F1:
	db $07, $00, $00, $00, $04, $00, $01, $00
	db $01, $00, $06, $00, $04, $00, $01, $06
	db $01, $00, $06, $00, $04, $00, $06, $00
	db $04, $00, $06, $00, $01, $06, $06, $06
	db $01, $00, $06, $00, $04, $00, $01, $00
	db $01, $00, $06, $00, $04, $00, $01, $06
	db $01, $00, $06, $00, $04, $00, $06, $00
	db $04, $00, $06, $00, $01, $06, $06, $06
	db DRUM_LOOP
Wave_6532:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
Wave_6542:
	db $00, $00, $00, $FF, $FF, $FF, $FF, $FF
	db $00, $00, $00, $FF, $FF, $FF, $FF, $FF

; Unreferenced (16 bytes)
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $FF, $FF, $FF
Wave_6562:
	db $12, $34, $56, $78, $9A, $BC, $DE, $FF
	db $ED, $CB, $A9, $87, $65, $43, $21, $00
Wave_6572:
	db $FF, $FE, $ED, $B8, $53, $21, $10, $00
	db $00, $01, $12, $35, $8B, $DE, $EF, $FF
Wave_6582:
	db $B7, $40, $04, $7B, $CD, $FF, $FE, $DC
	db $02, $46, $8A, $BD, $FD, $BA, $64, $20
Wave_6592:
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $ED, $CB, $A9, $87, $65, $43, $21, $00
Wave_65A2:
	db $00, $00, $00, $00, $00, $00, $FF, $FF
	db $00, $00, $00, $00, $00, $00, $FF, $FF
Wave_65B2:
	db $00, $00, $00, $00, $00, $00, $00, $FF
	db $00, $00, $00, $00, $00, $00, $00, $FF
Noise43_65C2:
	db $02, $51, $61, $71, $91, $71, $60, $FF
Noise42_65CA:
	db $F0, $F0, $D0, $90, $00, $50, $43

; Unreferenced (7 bytes)
	db $F0, $F0, $D0, $90, $80, $50, $41
Noise43_65D8:
	db $60, $52, $42, $41, $22, $11, $04, $FF

; Unreferenced (14 bytes)
	db $F0, $E0, $D0, $B0, $A0, $90, $81, $F0, $E0, $D0, $B0, $A0, $70, $41
Noise43_65EE:
	db $06, $04, $03, $03, $07, $FF
Noise42_65F4:
	db $F0, $F0, $D0, $C0, $85
Noise43_65F9:
	db $04, $02, $01, $FF
Noise42_65FD:
	db $80, $50, $33
Noise43_6600:
	db $04, $02, $06, $FF
Noise42_6604:
	db $A0, $50, $54
Noise43_6607:
	db $50, $41, $50, $51, $52, $53, $51, $FF
Noise42_660F:
	db $F0, $60, $F0, $60, $D0, $50, $72
Noise43_6616:
	db $00, $00, $00, $FF
Noise42_661A:
	db $2F, $F7, $20
Noise43_661D:
	db $00, $00, $FF
DrumPat_6620:
	db $08, $00, $00, $00, $08, $00, $00, $00
	db $08, $00, $00, $00, $00, $08, $00, $00
	db $00, $09, $00, $00, $00, DRUM_LOOP
Drum1:
	xor a
	ldh [wNoisePos], a
	inc a
	ldh [wNoiseOn], a
	ld a, HIGH(Noise43_65C2)
	ldh [wNoiseNR43Hi], a
	ld a, LOW(Noise43_65C2)
	ldh [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_65CA)
	ldh [wNoiseNR42Hi], a
	ld a, LOW(Noise42_65CA)
	ldh [wNoiseNR42Lo], a
	ret
Drum2:
	xor a
	ldh [wNoisePos], a
	inc a
	ldh [wNoiseOn], a
	ld a, HIGH(Noise43_65D8)
	ldh [wNoiseNR43Hi], a
	ld a, LOW(Noise43_65D8)
	ldh [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_65CA)
	ldh [wNoiseNR42Hi], a
	ld a, LOW(Noise42_65CA)
	ldh [wNoiseNR42Lo], a
	ret
Drum3:
	xor a
	ldh [wNoisePos], a
	inc a
	ldh [wNoiseOn], a
	ld a, HIGH(Noise43_6607)
	ldh [wNoiseNR43Hi], a
	ld a, LOW(Noise43_6607)
	ldh [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_660F)
	ldh [wNoiseNR42Hi], a
	ld a, LOW(Noise42_660F)
	ldh [wNoiseNR42Lo], a
	ret
Drum4:
	xor a
	ldh [wNoisePos], a
	inc a
	ldh [wNoiseOn], a
	ld a, HIGH(Noise43_6600)
	ldh [wNoiseNR43Hi], a
	ld a, LOW(Noise43_6600)
	ldh [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_6604)
	ldh [wNoiseNR42Hi], a
	ld a, LOW(Noise42_6604)
	ldh [wNoiseNR42Lo], a
	ret
Drum5:
	ret
Drum6:
	xor a
	ldh [wNoisePos], a
	inc a
	ldh [wNoiseOn], a
	ld a, HIGH(Noise43_65F9)
	ldh [wNoiseNR43Hi], a
	ld a, LOW(Noise43_65F9)
	ldh [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_65FD)
	ldh [wNoiseNR42Hi], a
	ld a, LOW(Noise42_65FD)
	ldh [wNoiseNR42Lo], a
	ret
Drum7:
	xor a
	ldh [wNoisePos], a
	inc a
	ldh [wNoiseOn], a
	ld a, HIGH(Noise43_65EE)
	ldh [wNoiseNR43Hi], a
	ld a, LOW(Noise43_65EE)
	ldh [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_65F4)
	ldh [wNoiseNR42Hi], a
	ld a, LOW(Noise42_65F4)
	ldh [wNoiseNR42Lo], a
	ret
Drum8:
	xor a
	ldh [wNoisePos], a
	inc a
	ldh [wNoiseOn], a
	ld a, $55
	ldh [wNoiseSpeed], a
	xor a
	ldh [wNoiseTimer], a
	ld a, HIGH(Noise43_6616)
	ldh [wNoiseNR43Hi], a
	ld a, LOW(Noise43_6616)
	ldh [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_661A)
	ldh [wNoiseNR42Hi], a
	ld a, LOW(Noise42_661A)
	ldh [wNoiseNR42Lo], a
	ret
Drum9:
	xor a
	ldh [wNoisePos], a
	inc a
	ldh [wNoiseOn], a
	ld a, $55
	ldh [wNoiseSpeed], a
	xor a
	ldh [wNoiseTimer], a
	ld a, HIGH(Noise43_661D)
	ldh [wNoiseNR43Hi], a
	ld a, LOW(Noise43_661D)
	ldh [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_661A)
	ldh [wNoiseNR42Hi], a
	ld a, LOW(Noise42_661A)
	ldh [wNoiseNR42Lo], a
	ret
