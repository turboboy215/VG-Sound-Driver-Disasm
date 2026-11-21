; =====================================================================
; Asterix (UE) (M5) - Game Boy
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 3
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o asterix.o Asterix_SoundDriver.asm
;   rgblink -o asterix.gb asterix.o
;   python tools/cmp_banked.py asterix.gb "Asterix (UE) (M5) [!].gb" <ranges listed in the doc>
; (the driver lives in ROM bank 3; the linked file only matches in the listed ranges)
;
; Documentation: Asterix_SoundDriver.md / AJG_SoundEngine_Family.md
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
	db $85 + \1
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
MACRO NOTE_PAN
	db $84
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
DEF wShFreqHi1 EQU $DB46
DEF wShFreqHi2 EQU $DB47
DEF wShFreqHi3 EQU $DB48
DEF wShNR32 EQU $DB49
DEF wInInstr EQU $DB4A
DEF wTranspose EQU $DB4B
DEF wNoisePan EQU $DB4C
DEF wDrumHold EQU $DB4D
DEF wInstrTable EQU $DB4E
DEF wInstrTableHi EQU $DB4F
DEF wArpTable EQU $DB50
DEF wArpTableHi EQU $DB51
DEF wMusicWave EQU $DB52
DEF wMusicWaveHi EQU $DB53
DEF wPaused EQU $DB54
DEF wStereo EQU $DB55
DEF wNoiseAutoPan EQU $DB56
DEF wDrumPatHi EQU $DB57
DEF wDrumPatLo EQU $DB58
DEF wDrumPos EQU $DB59
DEF wDrumsOn EQU $DB5A
DEF wDrumTempo EQU $DB5B
DEF wDrumTimer EQU $DB5C
DEF wNoiseNR43Hi EQU $DB5D
DEF wNoiseNR43Lo EQU $DB5E
DEF wNoiseNR42Hi EQU $DB5F
DEF wNoiseNR42Lo EQU $DB60
DEF wNoisePos EQU $DB61
DEF wNoiseOn EQU $DB62
DEF wNoiseAtten EQU $DB63
DEF wNoiseTimer EQU $DB64
DEF wNoiseSpeed EQU $DB65
DEF wFadePtr EQU $DB66
DEF wFadePtrHi EQU $DB67
DEF wFadePos EQU $DB68
DEF wFadeTimer EQU $DB69
DEF wFadeSpeed EQU $DB6A
DEF wFadeOn EQU $DB6B
DEF wCh1 EQU $DC00
DEF wCh2 EQU $DD00
DEF wCh3 EQU $DE00
DEF wSfx EQU $DF00



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
SECTION "MemCopy", ROM0[$1A90]

MemCopy:
	ld a, [hli]
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, MemCopy
	ret

SECTION "SoundDriver", ROMX[$4A8C], BANK[3]


; SndResume / SndPause: wPaused = 0 / 1. Pausing silences CH1-CH4 (NRx2 = 0, trigger)
; and jumps to RestoreMusicWave with whatever H the caller left (see the doc, quirks).
; While paused only the SFX page is ticked and output.
SndResume:
	xor a
	ld [wPaused], a
	ret
SndPause:
	ld a, $01
	ld [wPaused], a
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

; SndUpdate (once per frame): NR50 fade, then tick the four pages (or only the SFX
; page while paused), drums + noise sequence, output; finally NR51 from the pages'
; pan bytes (field $3D) and wNoisePan - or $FF while wStereo = 0.
SndUpdate:
	call DoFade
	ld a, [wPaused]
	and a
	jr z, TickMusic
	ld h, $DF
	call ChannelTick
	ld h, $DF
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
	ld hl, $DC3D
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
	ld a, [wNoisePan]
	or c
	ld c, a
	ld a, [wStereo]
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
	ld a, [wDrumHold]
	and a
	jr z, DrumTimerTick
	dec a
	ld [wDrumHold], a
DrumTimerTick:
	ld hl, wDrumTimer
	dec [hl]
	call z, DrumStep
	jp NoiseSeqTick

; ChannelTick (h = page, skipped while field $10 = 0): auto-duty, auto-pan, glide,
; envelope, arpeggio, vibrato, portamento, release check, note-pan; then len - 1
; and the stream when it reaches 0.
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
	call DoNotePan
	ld l, $05
	dec [hl]
	jr z, ReadStream
	ret

; DoNotePan (NOTE_PAN n, field $3F = $80 + n while a note runs): elapsed = length - len;
; elapsed 0 -> centre, n -> left, 2n -> right, 3n -> centre and stop.
DoNotePan:
	ld l, $3F
	bit 7, [hl]
	ret z
	ld a, [hl]
	sub $80
	ret z
	ld b, a
	ld l, $05
	ld a, [hl]
	ld c, a
	ld l, $0D
	ld a, [hl]
	sub c
	and a
	jr nz, NotePanLeft
	call Cmd_PanC
NotePanLeft:
	sub b
	jr nz, NotePanRight
	jp Cmd_PanL
NotePanRight:
	sub b
	jr nz, NotePanEnd
	jp Cmd_PanR
NotePanEnd:
	sub b
	ret nz
	ld l, $3F
	res 7, [hl]
	jp Cmd_PanC

; ReadStream (de = stream). Notes store the note and pointer, set the period,
; restart the arpeggio, the hardware envelope and the portamento, reload the length,
; arm the note-pan, reload vibrato, clear the released flag, volume = start volume,
; split the attack/decay bytes. Commands go through StreamCommand and loop.
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
	call PortaNoteOn
	ld l, $0D
	ld a, [hl]
	ld l, $05
	ld [hl], a
	ld l, $3F
	set 7, [hl]
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
	cp $85
	jr nc, Cmd_Instrument
	sub $60
	add a, a
	ld c, a
	add a, $E8
	ld c, a
	adc a, $4C
	sub c
	ld b, a
	ld a, [bc]
	ld l, a
	inc bc
	ld a, [bc]
	ld b, a
	ld c, l
	call CallBC
	jp ReadStream
CallBC:
	push bc
	ret
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

; Cmd_Instrument: clears vibrato, arpeggio, glide, auto-pan, auto-duty, hardware
; envelope (and the note-pan), centre pan, 50 % duty; then runs instrument macro n
; (entry n + 1 of the song's table) until END or NEXT with wInInstr = $C9.
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
	ld l, $3F
	ld [hl], a
	call Cmd_PanC
	call Cmd_Duty50
	pop af
	sub $84
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
	jp nc, Cmd_Vol
	cp $9E
	jr nc, Cmd_Arp
	sub $60
	add a, a
	ld c, a
	add a, $E8
	ld c, a
	adc a, $4C
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
	dw Cmd_NotePan
Cmd_NotePan:
	ld a, [de]
	inc de
	ld l, $3F
	ld [hl], a
	ret
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
Unused_Ret:
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
	cp $DE
	jr z, ReleaseCh3
	cp $DF
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
	cp $DE
	jr z, Cmd_Wait
	cp $DF
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
	ld [wFadeOn], a
	ld [wDrumsOn], a
	ld [wNoiseOn], a
	ld h, $DC
	call ResetChannel
	inc h
	call ResetChannel
	inc h
	call ResetChannel
	inc h
	call ResetChannel
	xor a
	ld [wTranspose], a
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
	cp $DF
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
	ld l, $3F
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
	cp $DF
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
	cp $DF
	jr z, BumpNR32Shadow
	ld a, h
	cp $DE
	ret nz
BumpNR32Shadow:
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
	ld [wDrumsOn], a
	ret

; DRUMS t, pattern: one pattern byte every t ticks (DrumStep).
Cmd_Drums:
	ld a, [de]
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
	ld [wNoiseAtten], a
	ld [wNoiseTimer], a
	ld [wNoiseSpeed], a
	ld [wNoiseAutoPan], a
	inc a
	ld [wDrumsOn], a
	ld [wDrumTimer], a
	ret
NoisePanCentre:
	ld a, $88
	ld [wNoisePan], a
	ret

; DrumStep: read pattern bytes. $FF loops, 0 = nothing; $32/$33/$34 noise pan
; centre/right/left, $35 n noise auto-pan, $64-$73 noise attenuation, $74+ noise
; sequence speed (these modify and read on); others = drum sound n from DrumTable
; (skipped while wDrumHold is running).
DrumStep:
	ld a, [wDrumsOn]
	and a
	ret z
	ld a, [wDrumTempo]
	ld [wDrumTimer], a
DrumRead:
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
	cp $35
	jr z, DrumAutoPan
	cp $74
	jr nc, DrumNoiseSpeed
	cp $64
	jr nc, DrumAtten
	push af
	ld a, [wDrumHold]
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
	dw Drum10
DrumLoop:
	xor a
	ld [wDrumPos], a
	jr DrumRead
DrumAtten:
	sub $64
	ld c, a
	ld a, $0F
	sub c
	ld [wNoiseAtten], a
DrumNextByte:
	ld a, [wDrumPos]
DrumNextByte2:
	inc a
	ld [wDrumPos], a
	inc hl
	ld a, [hl]
	jr DrumByte
DrumPanC:
	ld a, $88
	ld [wNoisePan], a
	jr DrumNextByte
DrumPanR:
	ld a, [wDrumHold]
	and a
	jr nz, DrumNextByte
	ld a, $08
	ld [wNoisePan], a
	jr DrumNextByte
DrumPanL:
	ld a, [wDrumHold]
	and a
	jr nz, DrumNextByte
	ld a, $80
	ld [wNoisePan], a
	jr DrumNextByte
DrumNoiseSpeed:
	sub $74
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	jr DrumNextByte
DrumAutoPan:
	inc hl
	ld a, [hl]
	ld [wNoiseAutoPan], a
	ld a, [wDrumPos]
	inc a
	jr DrumNextByte2

; NoiseSeqTick: every wNoiseSpeed + 1 ticks one step: NR43 = seq43[i]; if an NR42
; table is set, NR42 = seq42[i] - attenuation << 4, NR44 = $80. $FF ends.
NoiseSeqTick:
	ld a, [wNoiseOn]
	and a
	ret z
	ld a, [wNoiseTimer]
	and a
	jr z, NoiseSeqStep
	dec a
	ld [wNoiseTimer], a
	ret
NoiseSeqStep:
	ld a, [wNoiseSpeed]
	ld [wNoiseTimer], a
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
	jr z, NoiseSeqEnd
	ldh [rNR43], a
	ld a, [wNoiseNR42Hi]
	and a
	jr z, NoiseSeqNext
	ld h, a
	ld a, [wNoiseNR42Lo]
	ld l, a
	add hl, de
	ld a, [wNoiseAtten]
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
	ld a, [wNoisePos]
	inc a
	ld [wNoisePos], a
	ld a, [wDrumHold]
	and a
	ret nz
	ld a, [wNoiseAutoPan]
	and a
	ret z
	ld b, a
	ld a, [wNoisePos]
	dec a
	jr nz, NoiseAutoPan2
	ld a, $88
	ld [wNoisePan], a
	ret
NoiseAutoPan2:
	sub b
	jr nz, NoiseAutoPan3
	ld a, $08
	ld [wNoisePan], a
	ret
NoiseAutoPan3:
	sub b
	jr nz, NoiseAutoPan4
	ld a, $80
	ld [wNoisePan], a
	ret
NoiseAutoPan4:
	sub b
	ret nz
	ld a, $88
	ld [wNoisePan], a
	ret
NoiseSeqEnd:
	pop de
	pop hl
	xor a
	ld [wNoisePos], a
	ld [wNoiseOn], a
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
Unused_50B7:
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
Unused_510F:
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
	jp z, Cmd_PanL
	dec a
	jp z, Cmd_PanR
	dec a
	jp z, Cmd_PanL
	dec a
	jp z, Cmd_PanR
	ld [hl], $00
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
	jr z, Cmd_Duty50
	dec a
	jr z, Cmd_Duty12
	dec a
	jr z, Cmd_Duty50
	dec a
	jr z, Cmd_Duty12
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
	cp $DD
	jr z, SetDutyCh2
	cp $DC
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
	ld [wFadeSpeed], a
	ld a, l
	ld [wFadePtr], a
	ld a, h
	ld [wFadePtrHi], a
	jr FadeInit
Cmd_Fade:
	ld a, [de]
	ld [wFadeSpeed], a
	inc de
	ld a, [de]
	ld [wFadePtr], a
	inc de
	ld a, [de]
	ld [wFadePtrHi], a
	inc de
FadeInit:
	xor a
	ld [wFadePos], a
	ld [wFadeTimer], a
	inc a
	ld [wFadeOn], a
	ret
Cmd_FadeOff:
	xor a
	ld [wFadeOn], a
	ret

; DoFade: while no fade runs, NR50 is forced back to $77 every tick (unless it is 0).
DoFade:
	ld a, [wFadeOn]
	and a
	jr nz, FadeRun
	ldh a, [rNR50]
	and a
	ret z
	ld a, $77
	ldh [rNR50], a
	ret
FadeRun:
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
	cp $6A
	jr z, FadeLoop
	cp $FF
	jr z, Cmd_FadeOff
	ldh [rNR50], a
	ld a, [wFadePos]
	inc a
	ld [wFadePos], a
	ld a, [wFadeSpeed]
	ld [wFadeTimer], a
	ret
FadeLoop:
	xor a
	ld [wFadePos], a
	jr FadeStep

; NR50 tables (only FadeOutTable is referenced).
Unused_FadeTables:
	db $44, $53, $62, $71, $62, $53, $44, $35
	db $26, $17, $26, $35, $6A
	db $77, $67, $57, $47, $37, $47, $57, $67
	db $77, $76, $75, $74, $73, $74, $75, $76
	db $6A
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
	cp $DE
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
	ld a, [wShFreqHi3]
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
	ld a, [wMusicWave]
	ld l, a
	ld a, [wMusicWaveHi]
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
	ld a, [wShFreqHi3]
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
	ld [wNoisePan], a
	call StopAll
	ret
ClearChannelRest:
	ld l, e
	ld h, d
	dec hl
	ld bc, $0034
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
	cp $DF
	jr nz, AddTranspose
	pop af
	jr SetFreqIndex
AddTranspose:
	pop af
	ld a, [wTranspose]
	add a, c
SetFreqIndex:
	ld l, $0F
	ld c, [hl]
	add a, c
	add a, a
	add a, $50
	ld c, a
	adc a, $53
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
	ld h, $DC
	jr StartMusicCh
StartMusicCh2:
	ld h, $DD
	jr StartMusicCh
StartMusicCh3:
	ld h, $DE
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
	ld h, $DC
	call OutputChannel
	inc h
	call OutputChannel
	ld hl, $DF10
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
	sub $DC
	add a, $46
	ld l, a
	adc a, $DB
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
	cp $DC
	jr nz, RetrigCh2
	ld a, [wShFreqHi1]
	or $80
	ldh [rNR14], a
	ret
RetrigCh2:
	ld a, [wShFreqHi2]
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
	cp $DC
	jr nz, WriteVolumeCh2
	ld a, [wShFreqHi1]
	or $80
	ldh [rNR14], a
	ret
WriteVolumeCh2:
	ld a, [wShFreqHi2]
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
	add a, $78
	ld l, a
	adc a, $55
	sub l
	ld h, a
	ld c, [hl]
	ld a, [wShNR32]
	cp c
	jr z, WriteCh3VolDone
	ld a, c
	ld [wShNR32], a
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
Unused_55F0:
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
	cp $DF
	jr nz, PortaAddTranspose
	pop af
	jr PortaFreqIndex
PortaAddTranspose:
	pop af
	ld a, [wTranspose]
	add a, c
PortaFreqIndex:
	ld l, $0F
	ld a, [hl]
	add a, c
	add a, a
	add a, $50
	ld c, a
	adc a, $53
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
	ld hl, $DF10
	ld a, [hl]
	and a
	call nz, ResetChannel
	pop af
	ld l, $10
	ld [hl], a
	ld de, $DF02
	add a, a
	add a, $0A
	ld l, a
	adc a, $70
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
	ld h, $DC
	jr PlayOnCh
PlayOnCh2:
	ld h, $DD
	jr PlayOnCh
PlayOnCh3:
	ld h, $DE
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
	add a, $0A
	ld l, a
	adc a, $70
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

; Song 1: instrument table 1, arpeggio table 1
PlaySong1:
	ld a, $77
	ldh [rNR50], a
	xor a
	ld [wFadeOn], a
	push hl
	push de
	push bc
	ld a, HIGH(InstrTable1_1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable1_1 - 2)
	ld [wInstrTable], a
	ld a, HIGH(ArpTable)
	ld [wArpTableHi], a
	ld a, LOW(ArpTable)
	ld [wArpTable], a
	ld de, Song1_Ch1
	call StartMusicCh1
	ld de, Song1_Ch2
	call StartMusicCh2
	ld de, Song1_Ch3
	call StartMusicCh3
	pop bc
	pop de
	pop hl
	ret
Song1_Ch1:
	dw Pat_574D
Song1_Ch3:
	dw Pat_5798
Song1_Ch2:
	dw Pat_5803
Pat_574D:
	LEN 9
	HWENV $F2, $00
	DUTY_12
	ARP 0
	VIBRATO $09, $01, $05
	NOTE D_, 2
	WAIT
	NOTE A_, 3
	WAIT
	NOTE D_, 2
	WAIT
	NOTE A_, 3
	WAIT
	NOTE F_, 2
	WAIT
	NOTE C_, 4
	NOTE C_, 4
	NOTE F_, 2
	WAIT
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 2
	WAIT
	NOTE A_, 3
	WAIT
	NOTE D_, 2
	WAIT
	NOTE A_, 3
	WAIT
	NOTE F_, 2
	WAIT
	NOTE A_, 3
	NOTE A_, 3
	NOTE F_, 2
	WAIT
	NOTE A_, 3
	NOTE A_, 3
	NOTE D_, 2
	WAIT
	NOTE A_, 3
	WAIT
	NOTE D_, 2
	WAIT
	NOTE A_, 3
	WAIT
	NOTE F_, 2
	WAIT
	NOTE C_, 4
	NOTE C_, 4
	NOTE F_, 2
	WAIT
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 2
	WAIT
	NOTE A_, 3
	WAIT
	NOTE D_, 2
	WAIT
	NOTE A_, 3
	WAIT
	NOTE D_, 2
	WAIT
	NOTE A_, 2
	WAIT
	NOTE D_, 2
	WAIT
	WAIT
	WAIT
	END
Pat_5798:
	LEN 9
	VOLENV 15, $11, $1A, $12
	ARP 0
	VIBRATO $09, $01, $05
	WAVE Wave_72C3
	INSTR 9
	NOTE D_, 3
	WAIT
	INSTR 8
	NOTE D_, 4
	WAIT
	INSTR 9
	NOTE D_, 3
	WAIT
	INSTR 8
	NOTE D_, 4
	WAIT
	INSTR 9
	NOTE F_, 3
	WAIT
	INSTR 8
	NOTE F_, 4
	NOTE F_, 4
	INSTR 9
	NOTE F_, 3
	WAIT
	INSTR 8
	NOTE F_, 4
	NOTE F_, 4
	INSTR 9
	NOTE D_, 3
	WAIT
	INSTR 8
	NOTE D_, 4
	WAIT
	INSTR 9
	NOTE D_, 3
	WAIT
	INSTR 8
	NOTE D_, 4
	WAIT
	INSTR 9
	NOTE F_, 3
	WAIT
	INSTR 8
	NOTE C_, 4
	NOTE C_, 4
	INSTR 9
	NOTE F_, 3
	WAIT
	INSTR 8
	NOTE C_, 4
	NOTE C_, 4
	INSTR 9
	NOTE D_, 3
	WAIT
	INSTR 8
	NOTE D_, 4
	WAIT
	INSTR 9
	NOTE D_, 3
	WAIT
	INSTR 8
	NOTE D_, 4
	WAIT
	INSTR 9
	NOTE F_, 3
	WAIT
	INSTR 8
	NOTE F_, 4
	NOTE F_, 4
	INSTR 9
	NOTE F_, 3
	WAIT
	INSTR 8
	NOTE F_, 4
	NOTE F_, 4
	INSTR 9
	NOTE D_, 3
	WAIT
	INSTR 8
	NOTE D_, 4
	WAIT
	INSTR 9
	NOTE D_, 3
	WAIT
	INSTR 8
	NOTE G_, 4
	NOTE Fsh, 4
	INSTR 9
	NOTE D_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE D_, 3
	WAIT
	WAIT
	WAIT
	END
Pat_5803:
	LEN 9
	HWENV $F2, $00
	DUTY_12
	ARP 0
	VIBRATO $09, $01, $05
	DRUMS $09, DrumPat_5856
	REST
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE A_, 4
	WAIT
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE C_, 4
	WAIT
	NOTE A_, 4
	NOTE A_, 4
	WAIT
	WAIT
	NOTE A_, 4
	NOTE A_, 4
	WAIT
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE A_, 4
	WAIT
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE C_, 5
	WAIT
	NOTE F_, 4
	NOTE F_, 4
	WAIT
	WAIT
	NOTE F_, 4
	NOTE F_, 4
	WAIT
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE A_, 4
	WAIT
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE C_, 4
	WAIT
	NOTE A_, 4
	NOTE A_, 4
	WAIT
	WAIT
	NOTE A_, 4
	NOTE A_, 4
	WAIT
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	NOTE A_, 4
	NOTE D_, 5
	WAIT
	WAIT
	WAIT
	DRUMS_OFF
	CALL_CODE Drum7
	WAIT
	WAIT
	WAIT
	WAIT
	END
DrumPat_5856:
	db $01, $00, $06, $00, $02, $00, $06, $00
	db DRUM_LOOP

; Song 2: instrument table 1, arpeggio table 1
PlaySong2:
	ld a, $77
	ldh [rNR50], a
	xor a
	ld [wFadeOn], a
	push hl
	push de
	push bc
	ld a, HIGH(InstrTable1_1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable1_1 - 2)
	ld [wInstrTable], a
	ld a, HIGH(ArpTable)
	ld [wArpTableHi], a
	ld a, LOW(ArpTable)
	ld [wArpTable], a
	ld de, Song2_Ch1
	call StartMusicCh1
	ld de, Song2_Ch2
	call StartMusicCh2
	ld de, Song2_Ch3
	call StartMusicCh3
	pop bc
	pop de
	pop hl
	ret
Song2_Ch1:
	dw Pat_58C4
	dw Pat_58FA
	dw Pat_58FA
	dw Pat_59D3
	dw Pat_5B80
	dw Pat_59D3
	ORDER_LOOP Song2_Ch1
Song2_Ch2:
	dw Pat_58D4
	dw Pat_593B
	dw Pat_593B
	dw Pat_5A52
	dw Pat_5BA4
	dw Pat_5A52
	ORDER_LOOP Song2_Ch2
Song2_Ch3:
	dw Pat_58E7
	dw Pat_5985
	dw Pat_5985
	dw Pat_5AEE
	dw Pat_5BEA
	dw Pat_5C35
	ORDER_LOOP Song2_Ch3
Pat_58C4:
	LEN 16
	INSTR 0
	DRUMS $08, DrumPat_5CBB
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	WAIT
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	NEXT
Pat_58D4:
	LEN 8
	INSTR 2
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE B_, 4
	WAIT
	NOTE B_, 4
	WAIT
	WAIT
	WAIT
	NEXT
Pat_58E7:
	LEN 8
	INSTR 1
	NOTE E_, 4
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	NEXT
Pat_58FA:
	INSTR 0
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE G_, 4
	NEXT
Pat_593B:
	INSTR 3
	PAN_R
	NOTE E_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	PAN_C
	NOTE E_, 4
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	WAIT
	NOTE C_, 4
	WAIT
	PAN_L
	NOTE B_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	PAN_C
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	PAN_R
	NOTE E_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	PAN_C
	NOTE E_, 4
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	WAIT
	NOTE C_, 4
	WAIT
	PAN_L
	NOTE B_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE G_, 4
	WAIT
	PAN_C
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NEXT
Pat_5985:
	DRUMS $08, DrumPat_5CCE
	INSTR 6
	NOTE C_, 7
	WAIT
	WAIT
	WAIT
	NOTE G_, 6
	WAIT
	WAIT
	WAIT
	INSTR 7
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE E_, 4
	WAIT
	INSTR 6
	NOTE B_, 6
	WAIT
	NOTE A_, 6
	WAIT
	NOTE G_, 6
	WAIT
	WAIT
	WAIT
	INSTR 7
	NOTE B_, 4
	WAIT
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	INSTR 6
	NOTE C_, 7
	WAIT
	WAIT
	WAIT
	NOTE G_, 6
	WAIT
	WAIT
	WAIT
	INSTR 7
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE E_, 4
	WAIT
	INSTR 6
	NOTE B_, 6
	WAIT
	NOTE A_, 6
	WAIT
	NOTE G_, 6
	WAIT
	INSTR 7
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	WAIT
	INSTR 6
	NOTE G_, 6
	NOTE A_, 6
	NOTE G_, 6
	NOTE F_, 6
	NOTE E_, 6
	NOTE D_, 6
	NEXT
Pat_59D3:
	INSTR 0
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE Dsh, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	NEXT
Pat_5A52:
	INSTR 3
	PAN_L
	NOTE F_, 4
	WAIT
	PAN_R
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	PAN_L
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	PAN_C
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	WAIT
	INSTR 2
	PAN_R
	NOTE D_, 4
	NOTE F_, 4
	NOTE E_, 4
	WAIT
	INSTR 3
	PAN_C
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE D_, 4
	WAIT
	PAN_R
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	WAIT
	PAN_L
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	WAIT
	PAN_C
	NOTE D_, 4
	NOTE F_, 4
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	WAIT
	PAN_R
	NOTE E_, 4
	WAIT
	PAN_C
	NOTE D_, 4
	WAIT
	PAN_R
	NOTE F_, 4
	WAIT
	PAN_C
	NOTE Dsh, 4
	WAIT
	PAN_R
	NOTE Fsh, 4
	WAIT
	PAN_C
	NOTE E_, 4
	WAIT
	NOTE G_, 4
	NOTE B_, 4
	PAN_L
	NOTE F_, 4
	WAIT
	PAN_R
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	PAN_L
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	PAN_C
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	WAIT
	INSTR 2
	PAN_R
	NOTE D_, 4
	NOTE F_, 4
	NOTE E_, 4
	WAIT
	INSTR 3
	PAN_C
	NOTE C_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	NOTE D_, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE B_, 4
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	INSTR 2
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NEXT
Pat_5AEE:
	INSTR 7
	NOTE A_, 4
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 4
	WAIT
	INSTR 1
	PAN_L
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	WAIT
	INSTR 7
	PAN_C
	NOTE G_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE E_, 4
	WAIT
	PAN_L
	NOTE C_, 4
	WAIT
	PAN_C
	NOTE F_, 4
	WAIT
	PAN_L
	NOTE D_, 4
	WAIT
	PAN_C
	NOTE Fsh, 4
	WAIT
	PAN_L
	NOTE Dsh, 4
	WAIT
	PAN_C
	NOTE G_, 4
	WAIT
	NOTE E_, 4
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 4
	WAIT
	INSTR 1
	PAN_L
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	WAIT
	INSTR 7
	PAN_C
	NOTE E_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE B_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE E_, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE C_, 5
	WAIT
	INSTR 6
	NOTE G_, 5
	NOTE E_, 5
	NOTE C_, 5
	WAIT
	INSTR 1
	NOTE B_, 4
	NOTE G_, 4
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NEXT
Pat_5B80:
	PAT_CALL Pat_5B83
Pat_5B83:
	INSTR 0
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE G_, 4
	NEXT
Pat_5BA4:
	HWENV $69, $00
	DUTY_12
	ARP_OFF
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NEXT
Pat_5BEA:
	VOLENV 10, $15, $1F, $18
	ARP_OFF
	WAVE Wave_72A3
	CH_TRANSPOSE $0C
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	NEXT
Pat_5C35:
	WAVE Wave_7253
	NOTE F_, 5
	WAIT
	NOTE F_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 5
	NOTE F_, 5
	WAIT
	NOTE C_, 5
	NOTE F_, 5
	NOTE G_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 4
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE B_, 4
	NOTE G_, 5
	NOTE B_, 4
	NOTE G_, 5
	NOTE A_, 4
	NOTE F_, 5
	NOTE A_, 4
	NOTE F_, 5
	NOTE G_, 4
	NOTE E_, 5
	NOTE G_, 4
	NOTE E_, 5
	NOTE F_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	WAIT
	NOTE C_, 4
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	NOTE C_, 4
	NOTE F_, 4
	NOTE Fsh, 4
	WAIT
	NOTE C_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE F_, 5
	WAIT
	NOTE F_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 5
	NOTE F_, 5
	WAIT
	NOTE C_, 5
	NOTE F_, 5
	NOTE G_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 4
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE F_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE B_, 4
	NOTE D_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	WAIT
	NOTE B_, 4
	NOTE G_, 4
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	CH_TRANSPOSE $00
	NEXT
DrumPat_5CBB:
	db $35, $01, $01, $00, $01, $01, $01, $00
	db $01, $00, $02, $00, $02, $00, $02, $00
	db $04, $00, $00
DrumPat_5CCE:
	db $35, $01, $01, $00, $06, $06, $02, $00
	db $06, $06, DRUM_LOOP

; Unreferenced (5 bytes)
	db $01, $00, $02, $00, $FF

; Instrument table 1, entries 1..10 (the song routines point 2 bytes before:
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
Instr1_0:
	DUTY_50
	HWENV $F3, $00
	ARP 0
	NOTE_PAN $01
	END
Instr1_1:
	VOLENV 10, $11, $1F, $15
	RELEASE $02, $55
	WAVE Wave_7213
	END
Instr1_2:
	HWENV $A5, $00
	DUTY_50
	RELEASE $02, $55
	END
Instr1_3:
	AUTODUTY $04
	ARP 12
	HWENV $A2, $09, $44
	END
Instr1_4:
	HWENV $F1, $00
	ARP 8
	END
Instr1_5:
	HWENV $F1, $00
	ARP 9
	END
Instr1_6:
	VOLENV 15, $11, $1F, $14
	WAVE Wave_7253
	END
Instr1_7:
	VOLENV 15, $14, $1A, $11
	ARP 12
	WAVE Wave_72C3
	NEXT
Instr1_8:
	VOLENV 15, $00, $1F, $12
	WAVE Wave_72C3
	END
Instr1_9:
	VOLENV 15, $11, $1F, $13
	NOTE_PAN $01
	WAVE Wave_7263
	END

; Song 3: instrument table 3, arpeggio table 1
PlaySong3:
	ld a, $77
	ldh [rNR50], a
	xor a
	ld [wFadeOn], a
	push hl
	push de
	push bc
	ld a, HIGH(InstrTable3_1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable3_1 - 2)
	ld [wInstrTable], a
	ld a, HIGH(ArpTable)
	ld [wArpTableHi], a
	ld a, LOW(ArpTable)
	ld [wArpTable], a
	ld de, Song3_Ch1
	call StartMusicCh1
	ld de, Song3_Ch2
	call StartMusicCh2
	ld de, Song3_Ch3
	call StartMusicCh3
	pop bc
	pop de
	pop hl
	ret
Song3_Ch3:
	dw Pat_5D7F
Loop_5D79:
	dw Pat_5D8B
	ORDER_LOOP Loop_5D79
Pat_5D7F:
	LEN 10
	RELEASE $02, $00
	DRUMS $05, DrumPat_5E2F
	WAVE Wave_7203
	INSTR 0
Pat_5D8B:
	NOTE A_, 2
	NOTE A_, 3
	INSTR 1
	NOTE A_, 4
	INSTR 0
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	INSTR 1
	NOTE A_, 4
	INSTR 0
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	INSTR 1
	NOTE A_, 4
	INSTR 0
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	INSTR 1
	NOTE A_, 4
	INSTR 0
	NOTE A_, 3
	NOTE G_, 2
	NOTE G_, 3
	INSTR 1
	NOTE A_, 4
	INSTR 0
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	INSTR 1
	NOTE A_, 4
	INSTR 0
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	INSTR 1
	NOTE A_, 4
	INSTR 0
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	INSTR 1
	NOTE A_, 4
	INSTR 0
	NOTE G_, 3
	NEXT
Song3_Ch2:
	dw Pat_5DC4
Loop_5DBE:
	dw Pat_5DCB
	ORDER_LOOP Loop_5DBE
Pat_5DC4:
	LEN 10
	HWENV $F1, $05, $A7
	ARP 0
	DUTY_50
Pat_5DCB:
	NOTE A_, 3
	NOTE Csh, 4
	NOTE B_, 3
	NOTE D_, 4
	NOTE Csh, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE Csh, 5
	NOTE G_, 3
	NOTE B_, 3
	NOTE A_, 3
	NOTE Csh, 4
	NOTE B_, 3
	NOTE D_, 4
	NOTE Csh, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE B_, 4
	NEXT
Song3_Ch1:
	dw Pat_5E03
	dw Pat_5E06
Loop_5DF0:
	dw Pat_5E0E
	dw Pat_5E00
	dw Pat_5E0E
	dw Pat_5E0E
	dw Pat_5E03
	dw Pat_5E0E
	ORDER_LOOP Loop_5DF0
Pat_5E00:
	TRANSPOSE $05
	NEXT
Pat_5E03:
	TRANSPOSE $00
	NEXT
Pat_5E06:
	LEN 10
	HWENV $B1, $00
	ARP 2
	DUTY_50
	AUTOPAN $03
Pat_5E0E:
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE D_, 4
	NEXT
DrumPat_5E2F:
	db $32, $01, $00, $33, $06, $06, $32, $02
	db $00, $34, $06, $06, DRUM_LOOP

; Song 4: instrument table 3, arpeggio table 1
PlaySong4:
	ld a, $77
	ldh [rNR50], a
	xor a
	ld [wFadeOn], a
	ld a, HIGH(InstrTable3_1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable3_1 - 2)
	ld [wInstrTable], a
	ld a, HIGH(ArpTable)
	ld [wArpTableHi], a
	ld a, LOW(ArpTable)
	ld [wArpTable], a
	ld de, Song4_Ch1
	call StartMusicCh1
	ld de, Song4_Ch2
	call StartMusicCh2
	ld de, Song4_Ch3
	call StartMusicCh3
	ret
Song4_Ch1:
	dw Pat_5E89
	dw Pat_5E89
	dw Pat_5E89
	dw Pat_5E89
	dw Pat_5ED9
	dw Pat_5ED9
	ORDER_LOOP Song4_Ch1

; Unreferenced (14 bytes)
	db $6C, $40, $75, $00, $00, $66, $66, $66, $66, $66, $66, $66, $66, $6A
Pat_5E89:
	LEN 8
	HWENV $F3, $0C, $50
	DUTY_50
	ARP 0
	VIBRATO $08, $04, $06
	DUTY_50
	RELEASE $02, $50
	NOTE D_, 2
	WAIT
	NOTE A_, 2
	NOTE A_, 2
	NOTE D_, 3
	WAIT
	NOTE A_, 2
	WAIT
	NOTE C_, 3
	WAIT
	NOTE G_, 2
	WAIT
	WAIT
	WAIT
	NOTE F_, 2
	WAIT
	NOTE D_, 2
	WAIT
	NOTE A_, 2
	NOTE A_, 2
	NOTE D_, 3
	WAIT
	NOTE A_, 2
	WAIT
	NOTE F_, 2
	WAIT
	NOTE C_, 3
	WAIT
	NOTE G_, 2
	WAIT
	NOTE D_, 3
	WAIT
	NOTE D_, 2
	WAIT
	NOTE A_, 2
	NOTE A_, 2
	NOTE D_, 3
	WAIT
	NOTE A_, 2
	WAIT
	NOTE C_, 3
	WAIT
	NOTE G_, 2
	WAIT
	WAIT
	WAIT
	NOTE F_, 2
	WAIT
	NOTE D_, 2
	WAIT
	NOTE A_, 2
	NOTE A_, 2
	NOTE D_, 3
	WAIT
	NOTE A_, 2
	WAIT
	NOTE C_, 2
	WAIT
	NOTE C_, 3
	NOTE C_, 2
	NOTE Csh, 2
	WAIT
	NOTE Csh, 3
	NOTE Csh, 2
	NEXT
Pat_5ED9:
	NOTE D_, 2
	WAIT
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 3
	WAIT
	NOTE D_, 2
	WAIT
	NOTE D_, 3
	WAIT
	NOTE D_, 2
	WAIT
	NOTE D_, 3
	WAIT
	NOTE E_, 2
	WAIT
	NOTE E_, 3
	NOTE E_, 2
	NOTE E_, 2
	WAIT
	NOTE E_, 3
	WAIT
	NOTE E_, 2
	WAIT
	NOTE E_, 3
	WAIT
	NOTE E_, 2
	WAIT
	NOTE E_, 3
	WAIT
	NOTE F_, 2
	WAIT
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 2
	WAIT
	NOTE F_, 3
	WAIT
	NOTE F_, 2
	WAIT
	NOTE F_, 3
	WAIT
	NOTE F_, 2
	WAIT
	NOTE F_, 3
	WAIT
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	WAIT
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	NOTE G_, 2
	NEXT
Song4_Ch2:
	dw Pat_5F2A
	dw Pat_5F2A
	dw Pat_5F2A
	dw Pat_5F2A
	dw Pat_5F73
	dw Pat_5F73
	ORDER_LOOP Song4_Ch2
Pat_5F2A:
	LEN 16
	DRUMS $08, DrumPat_6075
	INSTR 2
	NOTE E_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 3
	NOTE A_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 3
	NOTE A_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 3
	NOTE A_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 5
	NOTE E_, 4
	INSTR 3
	NOTE A_, 3
	INSTR 5
	NOTE E_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 3
	NOTE A_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 3
	NOTE A_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 3
	NOTE A_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 3
	NOTE A_, 3
	LEN 8
	INSTR 4
	NOTE C_, 4
	INSTR 3
	NOTE A_, 3
	NEXT
Pat_5F73:
	LEN 16
	INSTR 2
	NOTE E_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 3
	NOTE A_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 3
	NOTE A_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 4
	NOTE E_, 4
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE E_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 4
	NOTE E_, 4
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE E_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 3
	NOTE A_, 3
	LEN 8
	INSTR 4
	NOTE G_, 4
	INSTR 3
	NOTE A_, 3
	NEXT
Song4_Ch3:
	dw Pat_6069
	dw Pat_6069
	dw Pat_5FC8
	dw Pat_5FC8
	dw Pat_601D
	dw Pat_6061
	ORDER_LOOP Song4_Ch3
Pat_5FC8:
	LEN 8
	VOLENV 15, $11, $18, $15
	RELEASE $42, $44
	NOTE_PAN $01
	ARP 0
	WAVE Wave_72A3
	CH_TRANSPOSE $0C
	VIBRATO $10, $01, $06
	NOTE D_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE G_, 3
	WAIT
	WAIT
	WAIT
	NOTE A_, 3
	WAIT
	WAIT
	WAIT
	NOTE A_, 3
	WAIT
	NOTE D_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE G_, 3
	WAIT
	WAIT
	WAIT
	NOTE A_, 3
	WAIT
	WAIT
	WAIT
	NOTE A_, 3
	WAIT
	NOTE D_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE C_, 5
	WAIT
	WAIT
	WAIT
	NOTE B_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NEXT
Pat_601D:
	WAVE Wave_7273
	NOTE D_, 4
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
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Gsh, 4
	WAIT
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	NOTE B_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE F_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE B_, 4
	WAIT
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	NOTE D_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NEXT
Pat_6061:
	CH_TRANSPOSE $18
	PAT_CALL Pat_601D
	CH_TRANSPOSE $0C
	NEXT
Pat_6069:
	LENGTH $40
	VOL 0
	REST
	REST
	REST
	REST
	REST
	REST
	REST
	REST
	NEXT
DrumPat_6075:
	db $35, $01, $01, $06, $06, $06, $02, $06
	db $06, $06, $01, $06, $06, $06, $02, $06
	db $06, $06, $01, $06, $06, $06, $02, $06
	db $05, $06, $01, $06, $04, $06, $02, $06
	db $04, $06, $01, $06, $06, $06, $02, $06
	db $06, $06, $01, $06, $06, $06, $02, $06
	db $06, $06, $01, $06, $06, $06, $02, $06
	db $05, $06, $01, $06, $04, $06, $02, $06
	db $04, $02, DRUM_LOOP

; Song 5: instrument table 3, arpeggio table 1
PlaySong5:
	ld a, $77
	ldh [rNR50], a
	xor a
	ld [wFadeOn], a
	ld a, HIGH(InstrTable3_1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable3_1 - 2)
	ld [wInstrTable], a
	ld a, HIGH(ArpTable)
	ld [wArpTableHi], a
	ld a, LOW(ArpTable)
	ld [wArpTable], a
	ld de, Song5_Ch1
	call StartMusicCh1
	ld de, Song5_Ch2
	call StartMusicCh2
	ld de, Song5_Ch3
	call StartMusicCh3
	ret
Song5_Ch1:
	dw Pat_60E9
Pat_60E9:
	LEN 20
	HWENV $F2, $00
	ARP 0
	DUTY_50
	PAN_R
Pat_60F0:
	NOTE G_, 2
	DUTY_12
	NOTE B_, 3
	DUTY_50
	NOTE G_, 2
	DUTY_12
	NOTE B_, 3
	DUTY_50
	NOTE G_, 2
	DUTY_12
	NOTE Ash, 3
	DUTY_50
	NOTE G_, 2
	DUTY_12
	NOTE Ash, 3
	DUTY_50
	NOTE D_, 2
	DUTY_12
	NOTE A_, 3
	DUTY_50
	NOTE D_, 2
	DUTY_12
	NOTE A_, 3
	DUTY_50
	NOTE G_, 2
	DUTY_12
	NOTE Ash, 3
	DUTY_50
	NOTE G_, 2
	DUTY_12
	NOTE Ash, 3
	DUTY_50
	NOTE G_, 2
	DUTY_12
	NOTE B_, 3
	DUTY_50
	NOTE G_, 2
	DUTY_12
	NOTE B_, 3
	DUTY_50
	NOTE G_, 2
	DUTY_12
	NOTE Ash, 3
	DUTY_50
	NOTE G_, 2
	DUTY_12
	NOTE Ash, 3
	DUTY_50
	NOTE D_, 2
	DUTY_12
	NOTE A_, 3
	DUTY_50
	NOTE D_, 2
	DUTY_12
	NOTE A_, 3
	DUTY_50
	NOTE G_, 2
	DUTY_12
	NOTE Ash, 3
	NOTE G_, 3
	DUTY_50
	NOTE D_, 2
	PAT_GOTO Pat_60F0
Song5_Ch2:
	dw Pat_6133
Pat_6133:
	LEN 20
	HWENV $F2, $00
	DUTY_12
	ARP 0
	PAN_L
	DUTY_50
Pat_613B:
	NOTE G_, 3
	DUTY_12
	NOTE D_, 4
	DUTY_50
	NOTE G_, 3
	DUTY_12
	NOTE D_, 4
	DUTY_50
	NOTE G_, 3
	DUTY_12
	NOTE D_, 4
	DUTY_50
	NOTE G_, 3
	DUTY_12
	NOTE D_, 4
	DUTY_50
	NOTE D_, 3
	DUTY_12
	NOTE D_, 4
	DUTY_50
	NOTE D_, 3
	DUTY_12
	NOTE D_, 4
	DUTY_50
	NOTE G_, 3
	DUTY_12
	NOTE D_, 4
	DUTY_50
	NOTE G_, 3
	DUTY_12
	NOTE D_, 4
	DUTY_50
	NOTE G_, 3
	DUTY_12
	NOTE D_, 4
	DUTY_50
	NOTE G_, 3
	DUTY_12
	NOTE D_, 4
	DUTY_50
	NOTE G_, 3
	DUTY_12
	NOTE D_, 4
	DUTY_50
	NOTE G_, 3
	DUTY_12
	NOTE D_, 4
	DUTY_50
	NOTE D_, 3
	DUTY_12
	NOTE D_, 4
	DUTY_50
	NOTE D_, 3
	DUTY_12
	NOTE D_, 4
	DUTY_50
	NOTE G_, 3
	DUTY_12
	NOTE D_, 4
	NOTE Ash, 3
	DUTY_50
	NOTE D_, 3
	PAT_GOTO Pat_613B
Song5_Ch3:
	dw Pat_617E
Pat_617E:
	LEN 10
	VOLENV 13, $1F, $11, $11
	RELEASE $64, $44
	WAVE Wave_7293
	VIBRATO $0A, $01, $05
	DRUMS $0A, DrumPat_61D9
Pat_6191:
	NOTE B_, 4
	WAIT
	NOTE C_, 5
	NOTE D_, 5
	NOTE G_, 4
	WAIT
	WAIT
	NOTE A_, 4
	NOTE Ash, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE Ash, 4
	WAIT
	WAIT
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 5
	NOTE D_, 5
	NOTE G_, 4
	WAIT
	WAIT
	NOTE A_, 4
	NOTE Ash, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE G_, 4
	WAIT
	LEN 3
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 11
	NOTE Fsh, 4
	LEN 10
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	PAT_GOTO Pat_6191
DrumPat_61D9:
	db $35, $01, $01, $00, $06, $00, $04, $00
	db $06, $00, $01, $00, $06, $00, $04, $00
	db $06, $00, $01, $00, $06, $00, $04, $00
	db $06, $00, $01, $00, $06, $00, $04, $00
	db $06, $06, DRUM_LOOP

; Song 6: instrument table 3, arpeggio table 1
PlaySong6:
	ld a, $77
	ldh [rNR50], a
	xor a
	ld [wFadeOn], a
	ld a, HIGH(InstrTable3_1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable3_1 - 2)
	ld [wInstrTable], a
	ld a, HIGH(ArpTable)
	ld [wArpTableHi], a
	ld a, LOW(ArpTable)
	ld [wArpTable], a
	ld de, Song6_Ch1
	call StartMusicCh1
	ld de, Song6_Ch2
	call StartMusicCh2
	ld de, Song6_Ch3
	call StartMusicCh3
	ret
Song6_Ch1:
	dw Pat_625C
Loop_622D:
	dw Pat_626A
	dw Pat_628E
	dw Pat_623B
	dw Pat_623B
	dw Pat_626A
	ORDER_LOOP Loop_622D
Pat_623B:
	NOTE C_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE C_, 3
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE C_, 3
	NOTE F_, 3
	NEXT
Pat_625C:
	LEN 16
	HWENV $F0, $08, $51
	ARP 0
	VIBRATO $08, $06, $06
	AUTODUTY $10
	NOTE_PAN $01
Pat_626A:
	PAT_CALL Pat_623B
	NOTE G_, 2
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Dsh, 3
	NOTE Gsh, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	NEXT
Pat_628E:
	NOTE F_, 2
	NOTE F_, 3
	NOTE C_, 3
	NOTE F_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE C_, 3
	NOTE F_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE C_, 3
	NOTE F_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	HWENV $F2, $08, $80
	DRUMS_OFF
	CALL_CODE Drum1
	NOTE Gsh, 2
	WAIT
	WAIT
	WAIT
	CALL_CODE Drum1
	NOTE G_, 2
	WAIT
	WAIT
	WAIT
	HWENV $F0, $08, $51
	DRUMS $08, DrumPat_6515
	NOTE C_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	NEXT
Song6_Ch2:
	dw Pat_6316
	dw Pat_6336
	dw Pat_6340
	dw Pat_6340
	dw Pat_62F6
	dw Pat_6336
	dw Pat_6340
	dw Pat_6340
	ORDER_LOOP Song6_Ch2
Pat_62F6:
	LEN 8
	HWENV $82, $08, $60
	DUTY_12
	AUTOPAN $08
	ARP 0
	VIBRATO $14, $02, $06
	PAT_CALL Pat_63C9
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	PAT_CALL Pat_63C9
	WAIT
	WAIT
	NOTE G_, 3
	WAIT
	NOTE Gsh, 3
	WAIT
	NEXT
Pat_6316:
	LEN 8
	HWENV $82, $08, $60
	DUTY_50
	AUTOPAN $08
	ARP 0
	VIBRATO $14, $02, $06
	PAT_CALL Pat_63C9
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	PAT_CALL Pat_63C9
	WAIT
	WAIT
	NOTE G_, 3
	WAIT
	NOTE Gsh, 3
	WAIT
	NEXT
Pat_6336:
	PAT_CALL Pat_6450
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NEXT
Pat_6340:
	LEN 16
	INSTR 2
	NOTE E_, 3
	INSTR 7
	NOTE C_, 4
	INSTR 6
	NOTE C_, 5
	INSTR 7
	NOTE C_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 7
	NOTE C_, 4
	INSTR 6
	NOTE C_, 5
	INSTR 7
	NOTE C_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 7
	NOTE C_, 4
	INSTR 6
	NOTE C_, 5
	INSTR 7
	NOTE C_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 7
	NOTE C_, 4
	INSTR 6
	NOTE C_, 5
	INSTR 7
	NOTE C_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 7
	NOTE C_, 4
	INSTR 6
	NOTE C_, 5
	INSTR 7
	NOTE C_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 7
	NOTE C_, 4
	INSTR 6
	NOTE C_, 5
	INSTR 7
	NOTE C_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 7
	NOTE F_, 4
	INSTR 6
	NOTE C_, 5
	INSTR 7
	NOTE F_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 7
	NOTE F_, 4
	INSTR 6
	NOTE C_, 5
	INSTR 7
	NOTE F_, 4
	NEXT
Song6_Ch3:
	dw Pat_6396
Loop_6384:
	dw Pat_63A8
	dw Pat_63AC
	dw Pat_6444
	dw Pat_64CB
	dw Pat_63AC
	dw Pat_6444
	dw Pat_64CB
	ORDER_LOOP Loop_6384
Pat_6396:
	LEN 8
	VOLENV 15, $11, $11, $11
	RELEASE $04, $AA
	VIBRATO $0A, $02, $06
	ARP 0
	NEXT

; Unreferenced (4 bytes)
	db $7A, $A3, $72, $6A
Pat_63A8:
	WAVE Wave_7253
	NEXT
Pat_63AC:
	CH_TRANSPOSE $0C
	DRUMS $08, DrumPat_6515
	PAT_CALL Pat_63CB
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	PAT_CALL Pat_63CB
	WAIT
	WAIT
	NOTE G_, 3
	WAIT
	NOTE Gsh, 3
	WAIT
	NOTE Ash, 3
	WAIT
	NEXT
Pat_63C9:
	WAIT
	WAIT
Pat_63CB:
	NOTE C_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE B_, 4
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE G_, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	NOTE Gsh, 4
	WAIT
	WAIT
	WAIT
	NOTE F_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	NOTE B_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Ash, 4
	NOTE B_, 4
	WAIT
	NOTE B_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE B_, 3
	WAIT
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	WAIT
	NOTE B_, 3
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NEXT
Pat_6444:
	PAT_CALL Pat_6452
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NEXT
Pat_6450:
	WAIT
	WAIT
Pat_6452:
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	NOTE C_, 4
	NOTE B_, 3
	WAIT
	NOTE D_, 4
	WAIT
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE Fsh, 3
	NOTE G_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Gsh, 3
	WAIT
	NOTE Ash, 3
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 4
	WAIT
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	NOTE F_, 4
	WAIT
	WAIT
	WAIT
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
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
	NOTE G_, 4
	WAIT
	NOTE Gsh, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	NOTE F_, 4
	WAIT
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	NOTE Gsh, 4
	WAIT
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE B_, 3
	WAIT
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	WAIT
	NOTE B_, 3
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NEXT
Pat_64CB:
	WAVE Wave_72A3
	PAT_CALL Pat_64D4
	PAT_GOTO Pat_64D4
Pat_64D4:
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 4
	NOTE Csh, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE Csh, 4
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 4
	NOTE Csh, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE Csh, 4
	NOTE C_, 4
	WAIT
	NOTE G_, 3
	NOTE Ash, 3
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 4
	NOTE Csh, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE C_, 5
	WAIT
	NOTE Ash, 4
	NOTE F_, 4
	NOTE F_, 3
	WAIT
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	NOTE Gsh, 3
	WAIT
	NOTE Dsh, 4
	WAIT
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	NEXT
DrumPat_6515:
	db $32, $01, $06, $33, $06, $32, $06, $32
	db $02, $06, $34, $06, $32, $06, $01, $06
	db $33, $06, $32, $06, $32, $02, $06, $34
	db $05, $32, $06, $01, $06, $33, $06, $32
	db $06, $32, $02, $06, $34, $06, $32, $06
	db $01, $06, $33, $04, $32, $06, $32, $02
	db $06, $34, $04, $32, $06, DRUM_LOOP

; Song 7: instrument table 3, arpeggio table 1
PlaySong7:
	ld a, $77
	ldh [rNR50], a
	xor a
	ld [wFadeOn], a
	ld a, HIGH(InstrTable3_1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable3_1 - 2)
	ld [wInstrTable], a
	ld a, HIGH(ArpTable)
	ld [wArpTableHi], a
	ld a, LOW(ArpTable)
	ld [wArpTable], a
	ld de, Song7_Ch1
	call StartMusicCh1
	ld de, Song7_Ch2
	call StartMusicCh2
	ld de, Song7_Ch3
	call StartMusicCh3
	ret
Song7_Ch1:
	dw Pat_6580
Song7_Ch2:
	dw Pat_6620
Song7_Ch3:
	dw Pat_65B1
Pat_6580:
	LEN 14
	ARP 0
	HWENV $F2, $07, $50
	VIBRATO $07, $04, $06
	DUTY_50
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 3
	NOTE E_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE Fsh, 2
	NOTE Fsh, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE Gsh, 2
	NOTE Gsh, 3
	HWENV $F2, $07, $54
	LEN 48
	NOTE A_, 2
	WAIT
	END
Pat_65B1:
	LEN 7
	DRUMS $07, DrumPat_6639
	VOLENV 15, $11, $1F, $11
	INSTR 8
	NOTE D_, 5
	INSTR 9
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE Fsh, 4
	INSTR 8
	NOTE A_, 4
	INSTR 9
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE Fsh, 4
	INSTR 8
	NOTE D_, 5
	INSTR 9
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE Fsh, 4
	INSTR 8
	NOTE A_, 4
	INSTR 9
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE Fsh, 4
	INSTR 8
	NOTE D_, 5
	INSTR 9
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	INSTR 8
	NOTE Ash, 4
	INSTR 9
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	INSTR 8
	NOTE D_, 5
	INSTR 9
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	INSTR 8
	NOTE Ash, 4
	INSTR 9
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	INSTR 8
	NOTE D_, 5
	INSTR 9
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE Gsh, 4
	INSTR 8
	NOTE B_, 4
	INSTR 9
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE Gsh, 4
	INSTR 8
	NOTE D_, 5
	INSTR 9
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	INSTR 8
	NOTE B_, 4
	INSTR 9
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	INSTR 8
	NOTE D_, 5
	INSTR 9
	NOTE Ash, 4
	INSTR 8
	NOTE B_, 4
	INSTR 9
	NOTE Ash, 4
	INSTR 8
	NOTE D_, 5
	INSTR 9
	NOTE B_, 4
	INSTR 8
	NOTE B_, 4
	INSTR 9
	NOTE B_, 4
	INSTR 8
	NOTE D_, 5
	INSTR 9
	NOTE C_, 5
	INSTR 8
	NOTE B_, 4
	INSTR 9
	NOTE C_, 5
	INSTR 8
	LEN 48
	NOTE D_, 5
	DRUMS_OFF
	WAIT
	END
Pat_6620:
	ARP 8
	HWENV $F4, $15, $50
	AUTODUTY $02
	LENGTH $70
	NOTE D_, 4
	NOTE Dsh, 4
	LENGTH $38
	NOTE E_, 4
	NOTE F_, 4
	LEN 28
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	HWENV $F3, $00
	LEN 48
	NOTE A_, 4
	END
DrumPat_6639:
	db $32, $01, $33, $06, $32, $01, $34, $06
	db $32, $02, $33, $06, $32, $01, $34, $06
	db $32, $01, $33, $06, $32, $01, $34, $06
	db $32, $02, $33, $06, $32, $01, $34, $06
	db $32, $01, $33, $06, $32, $01, $34, $06
	db $32, $02, $33, $06, $32, $01, $34, $06
	db $32, $01, $33, $06, $32, $01, $34, $06
	db $32, $02, $33, $06, $32, $01, $34, $06
	db $32, $01, $33, $06, $33, $01, $01, $32
	db $02, $33, $06, $34, $01, $01, $32, $01
	db $33, $06, $33, $01, $01, $32, $02, $33
	db $06, $34, $01, $01, $33, $01, $01, $01
	db $01, $32, $02, $01, $01, $01, $34, $01
	db $01, $01, $01, $32, $07, $00, $00, $00
	db $00, $00, $00, $00, $00, DRUM_LOOP

; Song 8: instrument table 3, arpeggio table 1
PlaySong8:
	ld a, $77
	ldh [rNR50], a
	xor a
	ld [wFadeOn], a
	ld a, HIGH(InstrTable3_1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable3_1 - 2)
	ld [wInstrTable], a
	ld a, HIGH(ArpTable)
	ld [wArpTableHi], a
	ld a, LOW(ArpTable)
	ld [wArpTable], a
	ld de, Song8_Ch1
	call StartMusicCh1
	ld de, Song8_Ch2
	call StartMusicCh2
	ld de, Song8_Ch3
	call StartMusicCh3
	ret
Song8_Ch1:
	dw Pat_66E4
Song8_Ch2:
	dw Pat_6731
Song8_Ch3:
	dw Pat_6705
Pat_66E4:
	LEN 6
	ARP 0
	HWENV $F2, $07, $54
	VIBRATO $07, $04, $06
	DUTY_50
	NOTE_PAN $01
	NOTE D_, 2
	WAIT
	WAIT
	NOTE A_, 2
	WAIT
	NOTE D_, 2
	NOTE E_, 2
	WAIT
	WAIT
	NOTE B_, 2
	WAIT
	NOTE E_, 2
	NOTE Fsh, 2
	WAIT
	NOTE G_, 2
	NOTE A_, 2
	WAIT
	LEN 30
	NOTE D_, 2
	END
Pat_6705:
	LEN 6
	VOLENV 15, $11, $1F, $12
	ARP 0
	VIBRATO $0C, $01, $05
	CH_TRANSPOSE $0C
	NOTE_PAN $01
	WAVE Wave_7263
	DRUMS $06, DrumPat_674B
	NOTE Fsh, 4
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	NOTE Csh, 5
	WAIT
	LEN 6
	NOTE D_, 5
	DRUMS_OFF
	LEN 24
	WAIT
	END
Pat_6731:
	LEN 18
	ARP 8
	HWENV $F2, $00
	AUTODUTY $02
	PAN_R
	NOTE D_, 4
	PAN_L
	NOTE D_, 4
	PAN_R
	ARP 9
	NOTE E_, 4
	PAN_L
	NOTE E_, 4
	PAN_R
	NOTE Fsh, 4
	PAN_L
	LEN 12
	NOTE Fsh, 4
	PAN_C
	ARP 8
	LEN 30
	NOTE D_, 4
	END
DrumPat_674B:
	db $32, $01, $34, $06, $06, $32, $02, $33
	db $06, $32, $01, $01, $34, $06, $06, $32
	db $02, $33, $06, $32, $01, $01, $34, $06
	db $32, $01, $01, $33, $06, $32, $04, DRUM_LOOP

; Song 9: instrument table 3, arpeggio table 1
PlaySong9:
	ld a, $77
	ldh [rNR50], a
	xor a
	ld [wFadeOn], a
	ld a, HIGH(InstrTable3_1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable3_1 - 2)
	ld [wInstrTable], a
	ld a, HIGH(ArpTable)
	ld [wArpTableHi], a
	ld a, LOW(ArpTable)
	ld [wArpTable], a
	ld de, Song9_Ch1
	call StartMusicCh1
	ld de, Song9_Ch3
	call StartMusicCh3
	ld de, Song9_Ch2
	call StartMusicCh2
	ret
Song9_Ch1:
	dw Pat_6824
Loop_679C:
	dw Pat_67DE
	dw Pat_6852
	dw Pat_6863
	dw Pat_6852
	dw Pat_68D4
	dw Pat_691A
	dw Pat_692B
	dw Pat_691A
	dw Pat_6995
	dw Pat_6852
	dw Pat_6863
	dw Pat_6852
	dw Pat_6863
	dw Pat_6A2B
	dw Pat_67E1
	dw Pat_6A2B
	dw Pat_6852
	dw Pat_6863
	dw Pat_6852
	dw Pat_68D4
	dw Pat_691A
	dw Pat_692B
	dw Pat_691A
	dw Pat_6995
	dw Pat_6852
	dw Pat_6863
	dw Pat_6852
	dw Pat_6863
	dw Pat_6A2B
	dw Pat_67DE
	dw Pat_6A2B
	ORDER_LOOP Loop_679C
Pat_67DE:
	TRANSPOSE $00
	NEXT
Pat_67E1:
	TRANSPOSE $02
	NEXT
Song9_Ch3:
	dw Pat_6834
Loop_67E6:
	dw Pat_6874
	dw Pat_688F
	dw Pat_6874
	dw Pat_68E5
	dw Pat_6939
	dw Pat_6954
	dw Pat_6939
	dw Pat_69A6
	dw Pat_6874
	dw Pat_688F
	dw Pat_6874
	dw Pat_688F
	dw Pat_6A40
	dw Pat_6A40
	ORDER_LOOP Loop_67E6
Song9_Ch2:
	dw Pat_6845
	dw Pat_68AA
	dw Pat_68C1
	dw Pat_68AA
	dw Pat_6907
	dw Pat_696F
	dw Pat_6984
	dw Pat_696F
	dw Pat_69C7
	dw Pat_69DA
	dw Pat_69DA
	dw Pat_6A5C
	dw Pat_6A5C
	ORDER_LOOP Song9_Ch2
Pat_6824:
	DUTY_50
	HWENV $F2, $00
	ARP 0
	VIBRATO $0A, $06, $04
	NOTE_PAN $01
	DRUMS $0A, DrumPat_6A7A
	NEXT
Pat_6834:
	VOLENV 15, $10, $1F, $13
	LEN 10
	DUTY_75
	ARP 11
	VIBRATO $14, $01, $04
	WAVE Wave_7253
	CH_TRANSPOSE $0C
	NEXT
Pat_6845:
	DUTY_75
	HWENV $F2, $0F, $70
	ARP 0
	VIBRATO $14, $02, $04
	CH_TRANSPOSE $F4
	NEXT
Pat_6852:
	LEN 30
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	LEN 10
	NOTE G_, 2
	WAIT
	NOTE C_, 3
	LEN 30
	NOTE Gsh, 2
	NOTE Dsh, 2
	NOTE Gsh, 2
	LEN 10
	NOTE Dsh, 2
	WAIT
	NOTE Gsh, 2
	NEXT
Pat_6863:
	LEN 30
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	LEN 10
	NOTE D_, 2
	WAIT
	NOTE G_, 2
	LEN 30
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	LEN 10
	NOTE G_, 2
	WAIT
	NOTE B_, 2
	NEXT
Pat_6874:
	PAN_R
	NOTE C_, 4
	WAIT
	NOTE E_, 4
	NOTE G_, 4
	WAIT
	NOTE E_, 4
	NOTE G_, 4
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	PAN_L
	NOTE Dsh, 4
	WAIT
	NOTE Gsh, 4
	NOTE C_, 5
	WAIT
	NOTE Gsh, 4
	NOTE C_, 5
	WAIT
	NOTE Gsh, 4
	WAIT
	WAIT
	WAIT
	NEXT
Pat_688F:
	PAN_R
	NOTE G_, 3
	WAIT
	NOTE B_, 3
	NOTE D_, 4
	WAIT
	NOTE B_, 3
	NOTE D_, 4
	WAIT
	NOTE B_, 3
	WAIT
	WAIT
	WAIT
	PAN_L
	NOTE C_, 4
	WAIT
	NOTE E_, 4
	NOTE G_, 4
	WAIT
	NOTE E_, 4
	NOTE G_, 4
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	NEXT
Pat_68AA:
	LEN 10
	NOTE G_, 5
	WAIT
	WAIT
	NOTE F_, 5
	WAIT
	NOTE E_, 5
	NOTE C_, 5
	WAIT
	WAIT
	NOTE C_, 5
	WAIT
	NOTE D_, 5
	NOTE Dsh, 5
	WAIT
	NOTE Dsh, 5
	NOTE D_, 5
	WAIT
	NOTE C_, 5
	LENGTH $3C
	NOTE Gsh, 4
	NEXT
Pat_68C1:
	LEN 10
	NOTE G_, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE G_, 5
	WAIT
	NOTE A_, 5
	NOTE G_, 5
	WAIT
	NOTE F_, 5
	NOTE E_, 5
	WAIT
	NOTE D_, 5
	LEN 30
	NOTE C_, 5
	NOTE A_, 5
	NOTE G_, 5
	WAIT
	NEXT
Pat_68D4:
	LEN 30
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	LEN 10
	NOTE D_, 2
	WAIT
	NOTE G_, 2
	LEN 30
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	LEN 10
	NOTE C_, 3
	WAIT
	NOTE C_, 3
	NEXT
Pat_68E5:
	PAN_R
	NOTE G_, 3
	WAIT
	NOTE B_, 3
	NOTE D_, 4
	WAIT
	NOTE B_, 3
	NOTE D_, 4
	WAIT
	NOTE B_, 3
	WAIT
	WAIT
	WAIT
	PAN_L
	NOTE C_, 4
	WAIT
	NOTE E_, 4
	NOTE G_, 4
	WAIT
	NOTE E_, 4
	NOTE C_, 4
	WAIT
	WAIT
	PAN_C
	WAVE Wave_7213
	NOTE C_, 1
	WAIT
	WAIT
	WAVE Wave_7253
	NEXT
Pat_6907:
	LEN 10
	NOTE G_, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE G_, 5
	WAIT
	NOTE A_, 5
	NOTE G_, 5
	WAIT
	NOTE A_, 5
	NOTE G_, 5
	WAIT
	NOTE A_, 5
	LEN 30
	NOTE C_, 6
	NOTE G_, 5
	NOTE C_, 5
	WAIT
	NEXT
Pat_691A:
	LEN 30
	NOTE A_, 2
	NOTE E_, 2
	NOTE A_, 2
	LEN 10
	NOTE E_, 2
	WAIT
	NOTE A_, 2
	LEN 30
	NOTE F_, 2
	NOTE C_, 2
	NOTE F_, 2
	LEN 10
	NOTE C_, 2
	WAIT
	NOTE F_, 2
	NEXT
Pat_692B:
	LEN 30
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	LEN 10
	NOTE D_, 2
	WAIT
	NOTE G_, 2
	LEN 30
	NOTE C_, 3
	NOTE C_, 3
	NOTE B_, 2
	NOTE Ash, 2
	NEXT
Pat_6939:
	PAN_R
	NOTE Csh, 4
	WAIT
	NOTE E_, 4
	NOTE A_, 4
	WAIT
	NOTE E_, 4
	NOTE A_, 4
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	PAN_L
	NOTE F_, 4
	WAIT
	NOTE A_, 4
	NOTE C_, 5
	WAIT
	NOTE A_, 4
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	NOTE B_, 4
	WAIT
	NOTE A_, 4
	NEXT
Pat_6954:
	PAN_C
	NOTE G_, 5
	WAIT
	PAN_R
	NOTE A_, 5
	NOTE G_, 5
	WAIT
	PAN_L
	NOTE A_, 5
	NOTE G_, 5
	WAIT
	PAN_R
	NOTE F_, 5
	NOTE E_, 5
	WAIT
	PAN_L
	NOTE F_, 5
	LEN 30
	NOTE G_, 5
	PAN_R
	NOTE E_, 4
	PAN_C
	NOTE Dsh, 4
	PAN_L
	NOTE D_, 4
	LEN 10
	NEXT
Pat_696F:
	LEN 10
	NOTE E_, 5
	WAIT
	WAIT
	NOTE Csh, 5
	WAIT
	NOTE D_, 5
	LEN 30
	NOTE E_, 5
	NOTE A_, 5
	LEN 10
	NOTE A_, 5
	WAIT
	NOTE G_, 5
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	LEN 30
	NOTE A_, 5
	WAIT
	NEXT
Pat_6984:
	LEN 10
	NOTE G_, 5
	WAIT
	NOTE A_, 5
	NOTE G_, 5
	WAIT
	NOTE A_, 5
	NOTE G_, 5
	WAIT
	NOTE F_, 5
	NOTE E_, 5
	WAIT
	NOTE F_, 5
	LENGTH $78
	NOTE G_, 5
	NEXT
Pat_6995:
	LEN 30
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	LEN 10
	NOTE D_, 2
	WAIT
	NOTE G_, 2
	LEN 30
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	LEN 10
	NOTE C_, 3
	WAIT
	NOTE G_, 2
	NEXT
Pat_69A6:
	PAN_C
	NOTE G_, 5
	WAIT
	PAN_R
	NOTE A_, 5
	NOTE G_, 5
	WAIT
	PAN_L
	NOTE A_, 5
	NOTE G_, 5
	WAIT
	PAN_R
	NOTE A_, 5
	NOTE G_, 5
	WAIT
	PAN_L
	NOTE A_, 5
	LEN 30
	NOTE C_, 6
	PAN_R
	NOTE G_, 3
	PAN_L
	NOTE C_, 4
	PAN_C
	WAVE Wave_7213
	NOTE C_, 1
	LEN 10
	WAVE Wave_7253
	NEXT
Pat_69C7:
	LEN 10
	NOTE G_, 5
	WAIT
	NOTE A_, 5
	NOTE G_, 5
	WAIT
	NOTE A_, 5
	NOTE G_, 5
	WAIT
	NOTE A_, 5
	NOTE G_, 5
	WAIT
	NOTE A_, 5
	LEN 30
	NOTE C_, 6
	NOTE G_, 5
	NOTE C_, 5
	WAIT
	NEXT
Pat_69DA:
	HWENV $F1, $0A, $D1
	DUTY_12
	CH_TRANSPOSE $F4
	ARP_OFF
	LEN 10
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	WAIT
	LEN 2
	NOTE E_, 5
	NOTE G_, 5
	LEN 6
	NOTE E_, 5
	LEN 10
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE Gsh, 5
	NOTE C_, 6
	NOTE Dsh, 5
	NOTE Gsh, 5
	NOTE C_, 6
	NOTE Dsh, 5
	NOTE Gsh, 5
	NOTE C_, 6
	WAIT
	LEN 2
	NOTE Gsh, 5
	NOTE C_, 6
	LEN 6
	NOTE Gsh, 5
	LEN 10
	NOTE Dsh, 5
	NOTE B_, 4
	NOTE D_, 5
	NOTE G_, 5
	NOTE B_, 4
	NOTE D_, 5
	NOTE G_, 5
	NOTE B_, 4
	NOTE D_, 5
	NOTE G_, 5
	WAIT
	LEN 2
	NOTE D_, 5
	NOTE G_, 5
	LEN 6
	NOTE D_, 5
	LEN 10
	NOTE B_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	WAIT
	LEN 2
	NOTE E_, 5
	NOTE G_, 5
	LEN 6
	NOTE E_, 5
	LEN 10
	NOTE B_, 4
	DUTY_75
	CH_TRANSPOSE $00
	NEXT
Pat_6A2B:
	LEN 10
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	NOTE C_, 3
	WAIT
	WAIT
	NOTE Dsh, 2
	WAIT
	NOTE Dsh, 2
	NOTE Dsh, 3
	WAIT
	WAIT
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	LEN 30
	NOTE F_, 3
	NOTE G_, 2
	NOTE G_, 3
	NEXT
Pat_6A40:
	PAN_R
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	WAIT
	WAIT
	PAN_L
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	WAIT
	WAIT
	PAN_C
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	WAIT
	NOTE D_, 5
	NOTE B_, 4
	WAIT
	WAIT
	NEXT
Pat_6A5C:
	DUTY_50
	HWENV $F2, $00
	ARP 0
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	WAIT
	WAIT
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	WAIT
	WAIT
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	WAIT
	NOTE G_, 5
	NOTE D_, 5
	WAIT
	WAIT
	NEXT
DrumPat_6A7A:
	db $35, $01, $01, $06, $06, $02, $06, $06
	db $01, $06, $06, $02, $06, $01, $01, $06
	db $06, $02, $06, $06, $01, $06, $06, $02
	db $05, $01, DRUM_LOOP

; Song 10: instrument table 2, arpeggio table 1
PlaySong10:
	ld a, $77
	ldh [rNR50], a
	xor a
	ld [wFadeOn], a
	ld a, HIGH(InstrTable2_1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable2_1 - 2)
	ld [wInstrTable], a
	ld a, HIGH(ArpTable)
	ld [wArpTableHi], a
	ld a, LOW(ArpTable)
	ld [wArpTable], a
	ld de, Song10_Ch1
	call StartMusicCh1
	ld de, Song10_Ch3
	call StartMusicCh3
	ld de, Song10_Ch2
	call StartMusicCh2
	ret
Song10_Ch1:
	dw Pat_6B28
Loop_6AC6:
	dw Pat_6B43
	dw Pat_6B43
	dw Pat_6B87
	dw Pat_6B87
	dw Pat_6BA0
	dw Pat_6BA0
	dw Pat_6BC9
	dw Pat_6BC9
	dw Pat_6B79
	dw Pat_6B79
	dw Pat_6B79
	dw Pat_6B79
	dw Pat_6B79
	dw Pat_6B79
	dw Pat_6B79
	dw Pat_6B79
	ORDER_LOOP Loop_6AC6
Song10_Ch3:
	dw Pat_6C0A
	dw Pat_6C0A
	dw Pat_6C63
	dw Pat_6C63
	dw Pat_6C94
	dw Pat_6BF2
	dw Pat_6BF2
	dw Pat_6BF2
	dw Pat_6BF2
	dw Pat_6BF2
	dw Pat_6BF2
	dw Pat_6BF2
	dw Pat_6BF2
	ORDER_LOOP Song10_Ch3
Song10_Ch2:
	dw Pat_6B37
	dw Pat_6CFB
	dw Pat_6CFB
	dw Pat_6D3C
	dw Pat_6D3C
	dw Pat_6D7E
	dw Pat_6DEA
	dw Pat_6DEA
	dw Pat_6E16
	dw Pat_6E16
	dw Pat_6DEA
	dw Pat_6DEA
	dw Pat_6E16
	dw Pat_6E16
	ORDER_LOOP Song10_Ch2
Pat_6B28:
	LEN 18
	VIBRATO $09, $06, $05
	NEXT

; Unreferenced (9 bytes)
	db $D5, $CC, $11, $1F, $11, $7A, $13, $72, $6A
Pat_6B37:
	ARP 0
	DUTY_75
	HWENV $F3, $12, $A6
	VIBRATO $09, $01, $05
	PAN_C
	NEXT
Pat_6B43:
	INSTR 3
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	WAIT
	NOTE D_, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	DRUMS_OFF
	WAIT
	CALL_CODE Drum1
	NOTE G_, 2
	NEXT
Pat_6B79:
	INSTR 3
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NEXT
Pat_6B87:
	NOTE C_, 3
	WAIT
	NOTE C_, 3
	NOTE B_, 2
	WAIT
	NOTE B_, 2
	NOTE Ash, 2
	WAIT
	NOTE Ash, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE Gsh, 2
	WAIT
	NOTE Gsh, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE Fsh, 2
	WAIT
	NOTE Fsh, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	NEXT
Pat_6BA0:
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 3
	NOTE C_, 2
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 3
	NOTE C_, 3
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 3
	NOTE C_, 2
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 3
	NOTE C_, 3
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 3
	NOTE F_, 2
	NOTE F_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 3
	NOTE F_, 3
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 3
	NOTE F_, 2
	NOTE F_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 3
	NOTE F_, 3
	NEXT
Pat_6BC9:
	INSTR 3
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 3
	NOTE C_, 2
	NOTE D_, 2
	INSTR 5
	NOTE D_, 4
	INSTR 3
	NOTE D_, 2
	NOTE E_, 2
	INSTR 5
	NOTE E_, 4
	INSTR 3
	NOTE E_, 2
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 3
	NOTE F_, 2
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 3
	NOTE C_, 2
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 3
	NOTE F_, 2
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	NOTE C_, 4
	NEXT
Pat_6BF2:
	CH_TRANSPOSE $0C
	LEN 18
	INSTR 0
	NOTE E_, 4
	INSTR 1
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE F_, 4
	INSTR 2
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE G_, 4
	INSTR 2
	NOTE E_, 4
	NOTE E_, 4
	INSTR 0
	NOTE F_, 4
	INSTR 2
	NOTE D_, 4
	NOTE D_, 4
	NEXT
Pat_6C0A:
	LEN 18
	CH_TRANSPOSE $0C
	INSTR 0
	NOTE E_, 3
	INSTR 1
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE G_, 3
	INSTR 2
	NOTE E_, 4
	NOTE E_, 4
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE E_, 3
	INSTR 1
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 3
	INSTR 1
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE B_, 3
	INSTR 1
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	NOTE B_, 3
	LEN 9
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE A_, 3
	LEN 18
	NOTE A_, 3
	INSTR 2
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE B_, 3
	INSTR 2
	NOTE E_, 4
	NOTE E_, 4
	INSTR 0
	NOTE G_, 3
	INSTR 1
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 1
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	NOTE D_, 4
	INSTR 1
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	NOTE E_, 3
	INSTR 1
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE E_, 3
	NOTE F_, 3
	NEXT
Pat_6C63:
	LEN 18
	VOLENV 10, $15, $1F, $18
	ARP_OFF
	PAN_C
	VIBRATO $12, $01, $06
	WAVE Wave_7273
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 2
	NOTE A_, 4
	LEN 16
	NOTE C_, 5
	LEN 18
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE C_, 4
	WAIT
	WAIT
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	LEN 2
	NOTE F_, 4
	LEN 7
	NOTE A_, 4
	LEN 9
	NOTE B_, 4
	LEN 18
	NOTE G_, 4
	WAIT
	NEXT
Pat_6C94:
	WAVE Wave_72B3
	LEN 9
	CH_TRANSPOSE $00
	ARP 0
	VOLENV 15, $11, $1F, $16
	PAT_CALL Pat_6CD0
	NOTE G_, 4
	NOTE D_, 4
	PAT_CALL Pat_6CD0
	NOTE B_, 4
	NOTE A_, 4
	PAT_CALL Pat_6CEB
	NOTE C_, 5
	WAIT
	WAIT
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 9
	WAIT
	NOTE G_, 4
	LEN 18
	NOTE F_, 4
	NOTE E_, 4
	WAIT
	WAIT
	CH_TRANSPOSE $F4
	PAT_CALL Pat_6CEB
	CH_TRANSPOSE $00
	NOTE G_, 4
	NOTE F_, 4
	LEN 9
	WAIT
	NOTE E_, 4
	LEN 18
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	LENGTH $36
	NOTE F_, 4
	NOTE E_, 4
	NEXT
Pat_6CD0:
	LEN 18
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE E_, 4
	WAIT
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	LEN 9
	WAIT
	NOTE F_, 4
	LEN 18
	NOTE A_, 4
	NOTE F_, 4
	WAIT
	NOTE A_, 4
	NEXT
Pat_6CEB:
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	NOTE D_, 5
	LEN 9
	WAIT
	NOTE C_, 5
	LEN 18
	NOTE D_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE F_, 5
	WAIT
	WAIT
	NEXT
Pat_6CFB:
	DRUMS $09, DrumPat_6E3B
	LEN 18
	NOTE C_, 4
	WAIT
	NOTE G_, 3
	NOTE D_, 4
	WAIT
	NOTE G_, 3
	NOTE G_, 4
	NOTE F_, 4
	LEN 9
	WAIT
	NOTE E_, 4
	LEN 18
	NOTE F_, 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	WAIT
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	NOTE G_, 3
	NOTE D_, 4
	LEN 9
	WAIT
	NOTE D_, 4
	LEN 18
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	WAIT
	NOTE B_, 3
	NOTE G_, 3
	NOTE A_, 3
	LEN 9
	WAIT
	NOTE D_, 4
	NOTE C_, 4
	WAIT
	NOTE B_, 3
	LEN 4
	NOTE C_, 4
	LEN 5
	NOTE B_, 3
	LEN 18
	NOTE A_, 3
	NOTE B_, 3
	LENGTH $6C
	NOTE C_, 4
	NEXT
Pat_6D3C:
	HWENV $78, $03, $F1
	ARP 4
	DUTY_75
	LEN 9
	DRUMS $12, DrumPat_6E55
	PAN_R
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE E_, 5
	PAN_C
	NOTE B_, 4
	NOTE E_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE E_, 5
	PAN_L
	NOTE Ash, 4
	NOTE E_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE G_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE C_, 5
	WAIT
	PAN_L
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	PAN_C
	NOTE G_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE C_, 5
	PAN_R
	NOTE Fsh, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE G_, 4
	WAIT
	NEXT
Pat_6D7E:
	DRUMS $09, DrumPat_6E3B
	HWENV $F3, $12, $A6
	PAN_C
	ARP 0
	PAT_CALL Pat_6DBB
	NOTE B_, 4
	NOTE G_, 4
	PAT_CALL Pat_6DBB
	NOTE D_, 5
	NOTE C_, 5
	PAT_CALL Pat_6DD9
	LEN 18
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	LENGTH $36
	NOTE A_, 4
	NOTE G_, 4
	CH_TRANSPOSE $F4
	PAT_CALL Pat_6DD9
	CH_TRANSPOSE $00
	LEN 18
	NOTE E_, 4
	NOTE D_, 4
	LEN 9
	WAIT
	NOTE C_, 4
	LEN 18
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE D_, 4
	LEN 9
	WAIT
	NOTE E_, 4
	NOTE D_, 4
	WAIT
	LENGTH $36
	NOTE C_, 4
	NEXT
Pat_6DBB:
	LEN 18
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE B_, 4
	LEN 9
	WAIT
	NOTE E_, 4
	LENGTH $6C
	NOTE G_, 4
	LEN 18
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE F_, 5
	NOTE E_, 5
	LEN 9
	WAIT
	NOTE A_, 4
	NOTE C_, 5
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	NOTE D_, 5
	LEN 18
	NOTE C_, 5
	NEXT
Pat_6DD9:
	LEN 18
	NOTE E_, 5
	WAIT
	NOTE E_, 5
	NOTE F_, 5
	LEN 9
	WAIT
	NOTE E_, 5
	LEN 18
	NOTE F_, 5
	NOTE G_, 5
	NOTE B_, 5
	NOTE C_, 6
	LENGTH $36
	NOTE A_, 5
	NEXT
Pat_6DEA:
	HWENV $F1, $09, $91
	ARP 4
	DUTY_12
	LEN 9
	PAN_L
	NOTE G_, 3
	WAIT
	PAN_C
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	PAN_L
	NOTE A_, 3
	WAIT
	PAN_C
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	PAN_L
	NOTE B_, 3
	WAIT
	PAN_C
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	WAIT
	ARP 0
	LEN 3
	NOTE E_, 4
	LEN 6
	NOTE G_, 4
	LEN 9
	WAIT
	ARP 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	WAIT
	NEXT
Pat_6E16:
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	ARP 0
	LEN 3
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	LEN 9
	WAIT
	ARP 4
	NOTE C_, 5
	WAIT
	NOTE A_, 4
	NOTE B_, 4
	ARP 0
	LEN 3
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 4
	LEN 9
	WAIT
	ARP 4
	NOTE B_, 4
	WAIT
	NEXT
DrumPat_6E3B:
	db $32, $01, $00, $06, $00, $01, $00, $02
	db $00, $06, $00, $01, $00, $01, $00, $06
	db $00, $01, $00, $02, $00, $06, $00, $01
	db $00, DRUM_LOOP
DrumPat_6E55:
	db $07, $00, $01, $07, $00, $01, $07, $00
	db $01, $01, $01, $01, DRUM_LOOP

; Song 11: instrument table 2, arpeggio table 1; also starts SFX 12
PlaySong11:
	ld a, $77
	ldh [rNR50], a
	xor a
	ld [wFadeOn], a
	ld a, HIGH(InstrTable2_1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable2_1 - 2)
	ld [wInstrTable], a
	ld a, HIGH(ArpTable)
	ld [wArpTableHi], a
	ld a, LOW(ArpTable)
	ld [wArpTable], a
	ld de, Song11_Ch1
	call StartMusicCh1
	ld de, Song11_Ch3
	call StartMusicCh3
	ld de, Song11_Ch2
	call StartMusicCh2
	ld a, $0C
	call PlaySfx
	ret
Song11_Ch1:
	dw Pat_6E9C
Song11_Ch3:
	dw Pat_6EDD
Song11_Ch2:
	dw Pat_6F31
Pat_6E9C:
	LEN 14
	REST
	INSTR 3
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 3
	NOTE C_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 3
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 3
	NOTE C_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 3
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 3
	NOTE C_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 3
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 3
	NOTE C_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 3
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 3
	NOTE C_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 3
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 3
	NOTE C_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 3
	NOTE Ash, 2
	INSTR 5
	NOTE G_, 4
	INSTR 3
	NOTE C_, 3
	INSTR 5
	NOTE A_, 4
	INSTR 3
	NOTE F_, 2
	NOTE C_, 2
	NOTE F_, 2
	WAIT
	WAIT
	END
Pat_6EDD:
	LEN 7
	CH_TRANSPOSE $18
	REST
	REST
	INSTR 0
	PAN_C
	AUTOPAN $07
	DRUMS $07, DrumPat_6F80
	NOTE F_, 3
	WAIT
	NOTE A_, 3
	NOTE F_, 3
	NOTE C_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE F_, 3
	WAIT
	NOTE A_, 3
	NOTE F_, 3
	NOTE C_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE F_, 3
	WAIT
	NOTE A_, 3
	NOTE F_, 3
	NOTE C_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE F_, 3
	WAIT
	NOTE A_, 3
	NOTE F_, 3
	NOTE C_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE F_, 3
	WAIT
	NOTE A_, 3
	NOTE F_, 3
	NOTE C_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE F_, 3
	WAIT
	NOTE A_, 3
	NOTE F_, 3
	NOTE C_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE Ash, 2
	WAIT
	NOTE F_, 3
	NOTE Ash, 2
	NOTE C_, 3
	WAIT
	NOTE G_, 3
	NOTE C_, 3
	DRUMS $07, DrumPat_6F8D
	NOTE F_, 3
	WAIT
	NOTE C_, 3
	WAIT
	NOTE F_, 2
	DRUMS_OFF
	WAIT
	WAIT
	WAIT
	WAIT
	END
Pat_6F31:
	ARP 0
	DUTY_75
	LEN 7
	HWENV $F2, $07, $82
	VIBRATO $09, $01, $05
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	WAIT
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	WAIT
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE F_, 5
	WAIT
	WAIT
	NOTE G_, 5
	NOTE A_, 5
	WAIT
	NOTE A_, 5
	WAIT
	NOTE A_, 5
	WAIT
	WAIT
	NOTE G_, 5
	NOTE G_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	WAIT
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	WAIT
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE F_, 5
	WAIT
	WAIT
	NOTE G_, 5
	NOTE A_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE F_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	END
DrumPat_6F80:
	db $32, $01, $00, $33, $06, $06, $32, $02
	db $00, $34, $06, $06, DRUM_LOOP
DrumPat_6F8D:
	db $32, $01, $00, $01, $00, $02, $00
Stub_Sfx01:
	ld a, $01
	jp PlaySfx
Stub_Sfx20:
	ld a, $14
	jp PlaySfx
Stub_Sfx12:
	ld a, $0C
	jp PlaySfx
Stub_Sfx02:
	ld a, $02
	jp PlaySfx
Stub_Sfx18:
	ld a, $12
	jp PlaySfx
Stub_Sfx17:
	ld a, $11
	jp PlaySfx
Stub_Sfx16:
	ld a, $10
	jp PlaySfx
Stub_Sfx13:
	ld a, $0D
	jp PlaySfx
Stub_Sfx03:
	ld a, $03
	jp PlaySfx
Stub_Sfx19:
	ld a, $13
	jp PlaySfx
Stub_Sfx05:
	ld a, $05
	jp PlaySfx
Stub_Sfx15:
	ld a, $0F
	jp PlaySfx
Stub_Sfx06:
	ld a, $06
	jp PlaySfx
Stub_Sfx04:
	ld a, $04
	jp PlaySfx
Stub_Sfx09:
	ld a, $09
	jp PlaySfx
Stub_Sfx07:
	ld a, $07
	jp PlaySfx
Stub_Sfx08:
	ld a, $08
	jp PlaySfx
Stub_Sfx10:
	ld a, $0A
	jp PlaySfx
Stub_Sfx14:
	ld a, $0E
	jp PlaySfx
Stub_Sfx11:
	ld a, $0B
	jp PlaySfx
Stub_Sfx21:
	ld a, $15
	jp PlaySfx
Stub_Sfx22:
	ld a, $16
	jp PlaySfx
Stub_Sfx23:
	ld a, $17
	jp PlaySfx
Stub_Sfx24:
	ld a, $18
	jp PlaySfx
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
	dw Sfx12
	dw Sfx13
	dw Sfx14
	dw Sfx15
	dw Sfx16
	dw Sfx17
	dw Sfx18
	dw Sfx19
	dw Sfx20
	dw Sfx21
	dw Sfx22
	dw Sfx23
	dw Sfx24

; Sound effect 24
Sfx24:
	VOLENV 15, $00, $1F, $11
	ARP 0
	WAVE Wave_72A3
	LEN 5
	NOTE E_, 6
	NOTE Csh, 6
	WAIT
	VOLENV 5, $11, $1F, $11
	LEN 5
	NOTE E_, 6
	NOTE Csh, 6
	WAIT
	END

; Sound effect 21
Sfx21:
	VOLENV 15, $11, $1F, $11
	ARP 0
	WAVE Wave_7213
	LEN 5
	GLIDE $02
	NOTE Csh, 3
	WAIT
	END

; Sound effect 22
Sfx22:
	VOLENV 15, $11, $1F, $12
	WAVE Wave_7213
	LEN 8
	GLIDE $FE
	CALL_CODE Code_73A8
	NOTE C_, 3
	END

; Sound effect 23
Sfx23:
	VOLENV 15, $11, $1F, $11
	WAVE Wave_7213
	LEN 7
	GLIDE $FE
	CALL_CODE Code_73A8
	NOTE B_, 2
	VOLENV 15, $11, $1F, $16
	WAVE Wave_7263
	GLIDE_OFF
	LENGTH $2D
	PORTA $04, $46
	NOTE C_, 5
	VOLENV 0, $00, $00, $00
	LEN 1
	NOTE A_, 7
	END

; Sound effect 11
Sfx11:
	VOLENV 15, $11, $23, $11
	LEN 5
	ARP 11
	WAVE Wave_72B3
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

; Sound effect 14
Sfx14:
	VOLENV 15, $00, $3F, $11
	WAVE Wave_7213
	LEN 4
	NOTE A_, 3
	END

; Sound effect 10
Sfx10:
	VOLENV 10, $11, $1F, $15
	WAVE Wave_7263
	CALL_CODE Code_7561
	LEN 15
	PORTA $01, $0F
	GLIDE $FF
	NOTE Dsh, 5
	END

; Sound effect 8
Sfx08:
	VOLENV 15, $11, $1F, $13
	WAVE Wave_7263
	CALL_CODE Code_7383
	LEN 5
	NOTE C_, 4
	CALL_CODE Code_74F2
	LEN 1
	REST
	LEN 10
	GLIDE $FE
	NOTE Dsh, 5
	END

; Sound effect 7
Sfx07:
	CALL_CODE Code_7534
	WAVE Wave_7213
	VOLENV 10, $11, $1F, $12
	LEN 7
	GLIDE $01
	NOTE C_, 3
	NOTE G_, 2
	END

; Sound effect 9
Sfx09:
	VOLENV 15, $11, $1F, $12
	ARP 0
	WAVE Wave_7213
	LEN 4
	GLIDE $04
	NOTE Fsh, 2
	LEN 4
	GLIDE $FF
	WAIT
	LEN 4
	GLIDE $01
	WAIT
	GLIDE $FF
	WAIT
	LEN 4
	GLIDE $01
	WAIT
	END

; Sound effect 18
Sfx18:
	CALL_CODE Code_74C5
	END

; Sound effect 4
Sfx04:
	VOLENV 10, $11, $10, $00
	WAVE Wave_71F3
	GLIDE $02
	LEN 5
	NOTE A_, 2
	GLIDE_OFF
	LEN 3
	WAIT
	GLIDE $02
	WAIT
	END

; Sound effect 5
Sfx05:
	CALL_CODE Code_74F2
	END

; Sound effect 20
Sfx20:
	LEN 16
	VOLENV 15, $15, $1F, $11
	GLIDE $01
	WAVE Wave_7213
	NOTE E_, 3
	END

; Sound effect 12
Sfx12:
	LEN 8
	VOLENV 15, $11, $1F, $12
	WAVE Wave_7213
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

; Sound effect 1
Sfx01:
	LEN 5
	ARP 0
	WAVE Wave_7273
	VOLENV 15, $10, $1F, $12
	RELEASE $02, $55
	NOTE C_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	END

; Sound effect 2
Sfx02:
	VOLENV 15, $11, $1F, $16
	LEN 6
	WAVE Wave_72F3
	GLIDE $02
	NOTE E_, 5
	GLIDE_OFF
	LENGTH $2C
	PORTA $01, $3C
	NOTE E_, 6
	PORTA_OFF
	LEN 1
	NOTE E_, 4
	CALL_CODE Code_7383
	VOLENV 15, $11, $1F, $11
	WAVE Wave_7213
	LEN 3
	GLIDE $FE
	NOTE B_, 2
	CALL_CODE Code_7383
	LEN 7
	NOTE B_, 2
	END

; Sound effect 17
Sfx17:
	LEN 5
	VOLENV 15, $00, $00, $00
	WAVE Wave_7213
	CALL_CODE Code_73F9
	GLIDE $03
	NOTE A_, 2
	GLIDE $FC
	WAIT
	END

; Sound effect 16
Sfx16:
	LEN 3
	VOLENV 15, $11, $1F, $11
	WAVE Wave_7213
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

; Sound effect 15
Sfx15:
	LEN 2
	VOLENV 15, $11, $1F, $11
	WAVE Wave_7213
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
	VOL 5
	NOTE C_, 6
	NOTE E_, 6
	NOTE G_, 6
	NOTE C_, 7
	END

; Sound effect 13
Sfx13:
	LEN 26
	VOLENV 15, $11, $1F, $13
	WAVE Wave_7213
	ARP 1
	GLIDE $02
	NOTE C_, 3
	END

; Sound effect 3
Sfx03:
	LEN 6
	VOLENV 15, $11, $1F, $13
	WAVE Wave_72F3
	GLIDE $06
	NOTE E_, 3
	GLIDE $FF
	WAIT
	WAIT
	END

; Sound effect 19
Sfx19:
	LEN 4
	VOLENV 15, $11, $2F, $11
	WAVE Wave_7213
	GLIDE $F8
	NOTE A_, 5
	END

; Sound effect 6
Sfx06:
	LEN 4
	VOLENV 15, $11, $2F, $11
	WAVE Wave_7213
	GLIDE $02
	NOTE A_, 4
	NOTE D_, 4
	END
Wave_71F3:
	db $0F, $00, $F0, $F0, $F0, $F0, $00, $0F
	db $0F, $FF, $FF, $00, $FF, $F0, $0F, $0F
Wave_7203:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $00, $00, $00, $77, $77, $00, $00, $00
Wave_7213:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF

; Unreferenced (48 bytes)
	db $00, $00, $00, $CD, $EF, $FF, $FF, $FF, $04, $8C, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $FF, $FF, $FF
	db $FF, $FE, $ED, $B8, $53, $21, $10, $00, $00, $01, $12, $35, $8B, $DE, $EF, $FF
Wave_7253:
	db $8C, $FE, $ED, $B8, $53, $21, $10, $24
	db $84, $01, $12, $35, $8B, $DE, $EF, $8C
Wave_7263:
	db $63, $10, $00, $00, $00, $00, $01, $36
	db $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9
Wave_7273:
	db $63, $10, $01, $47, $74, $10, $01, $36
	db $9C, $EF, $FE, $B8, $8B, $EF, $FE, $C9

; Unreferenced (16 bytes)
	db $63, $1F, $01, $47, $74, $10, $01, $36, $9C, $E0, $FE, $B8, $8B, $EF, $FE, $C9
Wave_7293:
	db $B7, $40, $04, $7B, $CD, $FF, $FE, $DC
	db $02, $46, $8A, $BD, $FD, $BA, $64, $20
Wave_72A3:
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $ED, $CB, $A9, $87, $65, $43, $21, $00
Wave_72B3:
	db $22, $22, $22, $22, $22, $22, $EE, $EE
	db $22, $22, $22, $22, $22, $22, $EE, $EE
Wave_72C3:
	db $22, $22, $22, $22, $22, $22, $EE, $22
	db $22, $22, $22, $22, $22, $22, $EE, $22
Wave_72D3:
	db $04, $8B, $DE, $FF, $ED, $CB, $A9, $87
	db $65, $44, $44, $32, $11, $24, $7A, $74
Wave_72E3:
	db $20, $13, $69, $BD, $FD, $B9, $64, $20
	db $13, $68, $B8, $64, $20, $24, $68, $64
Wave_72F3:
	db $20, $24, $68, $AC, $EC, $A8, $64, $20
	db $24, $68, $A8, $64, $20, $24, $68, $64
Noise43_7303:
	db $02, $51, $61, $71, $91, $71, $60, $FF
Noise42_730B:
	db $F0, $F0, $D0, $90, $70, $50, $41
Noise43_7312:
	db $60, $52, $42, $41, $22, $11, $21, $FF

; Unreferenced (14 bytes)
	db $F0, $E0, $D0, $B0, $A0, $90, $61, $F0, $E0, $D0, $B0, $A0, $70, $41
Noise43_7328:
	db $06, $04, $03, $03, $07, $FF
Noise42_732E:
	db $F0, $F0, $D0, $C0, $85
Noise43_7333:
	db $04, $02, $01, $01, $FF
Noise42_7338:
	db $80, $60, $40, $23
Noise43_733C:
	db $04, $02, $01, $01, $04, $02, $01, $FF
Noise42_7344:
	db $A0, $60, $33, $23, $A0, $60, $33
Noise43_734B:
	db $04, $02, $06, $06, $FF
Noise42_7350:
	db $C0, $80, $60, $54
Noise43_7354:
	db $50, $41, $50, $51, $52, $53, $51, $FF
Noise42_735C:
	db $F0, $70, $F0, $70, $D0, $70, $83

; Unreferenced (32 bytes)
	db $00, $00, $00, $FF, $2F, $F7, $20, $00, $00, $FF, $08, $00, $00, $00, $08, $00
	db $00, $00, $08, $00, $00, $00, $00, $08, $00, $00, $00, $09, $00, $00, $00, $FF
Code_7383:
	ld a, $08
	ld [wDrumHold], a
	call NoisePanCentre
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7303)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_7303)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_730B)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_730B)
	ld [wNoiseNR42Lo], a
	ret
Code_73A8:
	ld a, $0A
	ld [wDrumHold], a
	call NoisePanCentre
Drum8:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_73CD)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_73CD)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_73D5)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_73D5)
	ld [wNoiseNR42Lo], a
	ret
Noise43_73CD:
	db $02, $51, $61, $71, $91, $71, $60, $FF
Noise42_73D5:
	db $F0, $F0, $F0, $F0, $F0, $70, $52
Drum2:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_741E)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_741E)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_7426)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_7426)
	ld [wNoiseNR42Lo], a
	ret
Code_73F9:
	ld a, $08
	ld [wDrumHold], a
	call NoisePanCentre
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7312)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_7312)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_742D)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_742D)
	ld [wNoiseNR42Lo], a
	ret
Noise43_741E:
	db $60, $52, $42, $41, $22, $11, $04, $FF
Noise42_7426:
	db $F0, $F0, $F0, $A0, $30, $40, $53
Noise42_742D:
	db $F0, $F0, $F0, $F0, $F0, $F0, $61
Drum3:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7354)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_7354)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_735C)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_735C)
	ld [wNoiseNR42Lo], a
	ret
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_734B)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_734B)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_7350)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_7350)
	ld [wNoiseNR42Lo], a
	ret
Drum5:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_733C)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_733C)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_7344)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_7344)
	ld [wNoiseNR42Lo], a
	ret
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7333)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_7333)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_7338)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_7338)
	ld [wNoiseNR42Lo], a
	ret
Drum7:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7328)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_7328)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_732E)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_732E)
	ld [wNoiseNR42Lo], a
	ret
Code_74C5:
	call NoisePanCentre
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $0B
	ld [wDrumHold], a
	ld a, $C1
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ld a, HIGH(Noise43_751F)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_751F)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Rst00_MemCopy)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Rst00_MemCopy)
	ld [wNoiseNR42Lo], a
	ret
Code_74F2:
	call NoisePanCentre
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $0A
	ld [wDrumHold], a
	ld a, $F1
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ld a, HIGH(Noise43_752B)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_752B)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Rst00_MemCopy)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Rst00_MemCopy)
	ld [wNoiseNR42Lo], a
	ret
Noise43_751F:
	db $36, $35, $34, $33, $32, $31, $20, $20
	db $10, $10, $00, $FF
Noise43_752B:
	db $10, $10, $20, $31, $33, $34, $35, $36
	db $FF
Code_7534:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $13
	ld [wDrumHold], a
	call NoisePanCentre
	ld a, $F2
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ld a, HIGH(Noise43_75A6)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_75A6)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Rst00_MemCopy)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Rst00_MemCopy)
	ld [wNoiseNR42Lo], a
	ret
Code_7561:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $13
	ld [wDrumHold], a
	call NoisePanCentre
	ld a, $C2
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ld a, HIGH(Noise43_758E)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_758E)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Rst00_MemCopy)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Rst00_MemCopy)
	ld [wNoiseNR42Lo], a
	ret
Noise43_758E:
	db $10, $10, $20, $31, $33, $34, $35, $34
	db $32, $31, $82, $64, $02, $37, $47, $24
	db $55, $71, $07, $44, $60, $36, $84, $FF
Noise43_75A6:
	db $82, $64, $02, $37, $47, $24, $55, $71
	db $07, $44, $60, $36, $84, $82, $64, $02
	db $37, $47, $24, $55, $71, $07, $44, $60
	db $36, $86, $32, $FF

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
	VOLENV 15, $14, $18, $11
	ARP 4
	PAN_L
	WAVE Wave_72D3
	END
Instr2_1:
	VOLENV 15, $13, $18, $11
	ARP 5
	PAN_R
	WAVE Wave_72E3
	END
Instr2_2:
	VOLENV 15, $13, $18, $11
	ARP 6
	PAN_R
	WAVE Wave_72E3
	END
Instr2_3:
	DUTY_50
	HWENV $F3, $00
	ARP 0
	NOTE_PAN $01
	END
Instr2_4:
	HWENV $F1, $04, $92
	ARP 5
	DUTY_50
	END
Instr2_5:
	HWENV $F1, $04, $92
	ARP 6
	DUTY_50
	END

; Instrument table 3, entries 1..10 (the song routines point 2 bytes before:
; entry 0 is never read)
InstrTable3_1:
	dw Instr3_0
	dw Instr3_1
	dw Instr3_2
	dw Instr3_3
	dw Instr3_4
	dw Instr3_5
	dw Instr3_6
	dw Instr3_7
	dw Instr3_8
	dw Instr3_9
Instr3_0:
	VOLENV 15, $11, $1F, $12
	ARP 0
	END
Instr3_1:
	VOLENV 15, $11, $1F, $13
	GLIDE $FE
	END
Instr3_2:
	HWENV $F2, $08, $11
	GLIDE $FD
	NOTE_PAN $01
	END
Instr3_3:
	HWENV $F2, $08, $21
	GLIDE $FE
	NOTE_PAN $01
	END
Instr3_4:
	HWENV $F1, $00
	ARP 5
	AUTODUTY $03
	END
Instr3_5:
	HWENV $F1, $00
	ARP 6
	AUTODUTY $03
	END
Instr3_6:
	HWENV $F2, $07, $54
	DUTY_50
	NOTE_PAN $01
	END
Instr3_7:
	HWENV $F2, $08, $40
	ARP 7
	DUTY_12
	AUTOPAN $02
	END
Instr3_8:
	VOLENV 15, $11, $2F, $11
	ARP 0
	PAN_R
	WAVE Wave_7213
	END
Instr3_9:
	VOLENV 15, $11, $1F, $11
	ARP 0
	PAN_L
	WAVE Wave_72A3
	END
ArpTable:
	dw Arp0
	dw Arp1
	dw Arp2
	dw Arp3
	dw Arp4
	dw Arp5
	dw Arp6
	dw Arp7
	dw Arp8
	dw Arp9
	dw Arp10
	dw Arp11
	dw Arp12
Arp0:
	db $0C, $00, ARP_HOLD
Arp1:
	db $00, $0C, ARP_LOOP
Arp2:
	db $0C, $00, $00, $00, $00, $0C, ARP_HOLD
Arp3:
	db $0C, $0C, $00, $00, $00, $00, $00, $00
	db $00, ARP_LOOP
Arp4:
	db $0C, $00, $00, $00, $00, $00, $00, $00
	db $00, ARP_LOOP
Arp5:
	db $00, $04, $07, ARP_LOOP
Arp6:
	db $00, $03, $07, ARP_LOOP
Arp7:
	db $0C, $07, $00, $13, ARP_LOOP
Arp8:
	db $00, $00, $04, $04, $07, $07, ARP_LOOP
Arp9:
	db $00, $00, $03, $03, $07, $07, ARP_LOOP
Arp10:
	db $18, $0C, $00, $00, ARP_LOOP
Arp11:
	db $18, $0C, $00, ARP_HOLD
Arp12:
	db $0C, $0C, $00, ARP_HOLD

; Song 12: instrument table 1, arpeggio table 1
PlaySong12:
	ld a, $77
	ldh [rNR50], a
	xor a
	ld [wFadeOn], a
	push hl
	push de
	push bc
	ld a, HIGH(InstrTable1_1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable1_1 - 2)
	ld [wInstrTable], a
	ld a, HIGH(ArpTable)
	ld [wArpTableHi], a
	ld a, LOW(ArpTable)
	ld [wArpTable], a
	ld de, Song12_Ch1
	call StartMusicCh1
	ld de, Song12_Ch2
	call StartMusicCh2
	ld de, Song12_Ch3
	call StartMusicCh3
	pop bc
	pop de
	pop hl
	ret
Song12_Ch1:
	dw Pat_7730
Loop_7702:
	dw Pat_77CB
	dw Pat_77CB
	dw Pat_7991
	dw Pat_7991
	dw Pat_7A83
	ORDER_LOOP Loop_7702
Song12_Ch2:
	dw Pat_776A
Loop_7712:
	dw Pat_788A
	dw Pat_788A
	dw Pat_79F1
	dw Pat_79FD
	dw Pat_7B42
	ORDER_LOOP Loop_7712
Song12_Ch3:
	dw Pat_7795
Loop_7722:
	dw Pat_7910
	dw Pat_7910
	dw Pat_7A42
	dw Pat_7A42
	dw Pat_7BC3
	ORDER_LOOP Loop_7722
Pat_7730:
	LEN 7
	HWENV $F3, $00
	ARP 0
	VIBRATO $08, $04, $05
	DUTY_50
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	NOTE Ash, 2
	WAIT
	NEXT
Pat_776A:
	LEN 7
	HWENV $F1, $00
	ARP 0
	VIBRATO $10, $01, $05
	DUTY_12
	NOTE C_, 4
	WAIT
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 3
	WAIT
	NOTE E_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 3
	WAIT
	NOTE E_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 3
	WAIT
	NOTE E_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 3
	WAIT
	NOTE E_, 4
	WAIT
	NEXT
Pat_7795:
	WAVE Wave_7273
	VOLENV 9, $1F, $1F, $1A
	VIBRATO $10, $01, $05
	CH_TRANSPOSE $0C
	LEN 7
	RELEASE $02, $AA
	DRUMS $07, DrumPat_7C44
	REST
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
	WAIT
	NEXT
Pat_77CB:
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE Ash, 2
	WAIT
	INSTR 4
	NOTE Ash, 3
	WAIT
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 4
	NOTE Ash, 3
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	NOTE Ash, 2
	WAIT
	INSTR 0
	NOTE F_, 3
	WAIT
	INSTR 4
	NOTE F_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE F_, 4
	WAIT
	INSTR 0
	NOTE F_, 3
	WAIT
	INSTR 4
	NOTE F_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE F_, 4
	WAIT
	INSTR 0
	NOTE F_, 3
	WAIT
	INSTR 4
	NOTE F_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE F_, 4
	WAIT
	INSTR 0
	NOTE F_, 3
	WAIT
	INSTR 4
	NOTE F_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE F_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE Gsh, 2
	WAIT
	INSTR 4
	NOTE Csh, 4
	WAIT
	INSTR 0
	NOTE Ash, 2
	WAIT
	INSTR 4
	NOTE Dsh, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	NOTE Ash, 2
	WAIT
	NEXT
Pat_788A:
	DUTY_50
	HWENV $F2, $0E, $60
	NOTE E_, 4
	WAIT
	WAIT
	NOTE F_, 4
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	NOTE F_, 4
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE G_, 3
	WAIT
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	NOTE F_, 4
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE Ash, 4
	WAIT
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	NOTE Ash, 4
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	NOTE Ash, 4
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	NOTE F_, 4
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE G_, 3
	WAIT
	NOTE Gsh, 3
	WAIT
	NOTE C_, 4
	WAIT
	NOTE Ash, 3
	WAIT
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	NEXT
Pat_7910:
	NOTE E_, 5
	WAIT
	WAIT
	NOTE F_, 5
	NOTE E_, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE A_, 5
	WAIT
	NOTE E_, 5
	WAIT
	WAIT
	NOTE F_, 5
	NOTE E_, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	NOTE E_, 5
	WAIT
	WAIT
	NOTE F_, 5
	NOTE E_, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE A_, 5
	WAIT
	NOTE Ash, 5
	WAIT
	WAIT
	NOTE A_, 5
	NOTE G_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	WAIT
	WAIT
	WAIT
	NOTE G_, 5
	WAIT
	WAIT
	WAIT
	NOTE A_, 5
	WAIT
	WAIT
	NOTE Ash, 5
	NOTE A_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE A_, 5
	WAIT
	NOTE Ash, 5
	WAIT
	NOTE C_, 6
	WAIT
	NOTE D_, 6
	WAIT
	NOTE A_, 5
	WAIT
	WAIT
	NOTE Ash, 5
	NOTE A_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE A_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE C_, 5
	WAIT
	WAIT
	WAIT
	NOTE E_, 5
	WAIT
	WAIT
	NOTE F_, 5
	NOTE E_, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE G_, 4
	WAIT
	NOTE Gsh, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	WAIT
	WAIT
	WAIT
	NEXT
Pat_7991:
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE Ash, 2
	WAIT
	INSTR 4
	NOTE Ash, 3
	WAIT
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 4
	NOTE Ash, 3
	WAIT
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 4
	NOTE F_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE F_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	NOTE Ash, 2
	WAIT
	NEXT
Pat_79F1:
	PAT_CALL Pat_7A09
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NEXT
Pat_79FD:
	PAT_CALL Pat_7A09
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NEXT
Pat_7A09:
	NOTE E_, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	NOTE F_, 4
	WAIT
	NOTE E_, 4
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
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	NOTE Ash, 4
	WAIT
	WAIT
	WAIT
	NOTE F_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	NOTE F_, 4
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	NEXT
Pat_7A42:
	NOTE G_, 4
	WAIT
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE C_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE Ash, 4
	WAIT
	WAIT
	WAIT
	NOTE D_, 5
	WAIT
	WAIT
	WAIT
	NOTE C_, 5
	WAIT
	WAIT
	WAIT
	NOTE F_, 4
	WAIT
	WAIT
	NOTE A_, 4
	NOTE C_, 5
	WAIT
	NOTE A_, 4
	WAIT
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
	NEXT
Pat_7A83:
	INSTR 0
	NOTE Gsh, 2
	WAIT
	INSTR 4
	NOTE Gsh, 3
	WAIT
	INSTR 0
	NOTE Gsh, 2
	WAIT
	INSTR 4
	NOTE Gsh, 3
	WAIT
	INSTR 0
	NOTE Ash, 2
	WAIT
	INSTR 4
	NOTE Ash, 3
	WAIT
	INSTR 0
	NOTE Ash, 2
	WAIT
	INSTR 4
	NOTE Ash, 3
	WAIT
	INSTR 0
	NOTE C_, 2
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE C_, 2
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE Gsh, 2
	WAIT
	INSTR 4
	NOTE Gsh, 3
	WAIT
	INSTR 0
	NOTE Gsh, 2
	WAIT
	INSTR 4
	NOTE Gsh, 3
	WAIT
	INSTR 0
	NOTE Ash, 2
	WAIT
	INSTR 4
	NOTE Ash, 3
	WAIT
	INSTR 0
	NOTE Ash, 2
	WAIT
	INSTR 4
	NOTE Ash, 3
	WAIT
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 4
	NOTE F_, 3
	WAIT
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 4
	NOTE F_, 3
	WAIT
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 4
	NOTE F_, 3
	WAIT
	INSTR 0
	NOTE F_, 2
	WAIT
	NOTE G_, 2
	WAIT
	INSTR 0
	NOTE Gsh, 2
	WAIT
	INSTR 4
	NOTE Gsh, 3
	WAIT
	INSTR 0
	NOTE Gsh, 2
	WAIT
	INSTR 4
	NOTE Gsh, 3
	WAIT
	INSTR 0
	NOTE Ash, 2
	WAIT
	INSTR 4
	NOTE Ash, 3
	WAIT
	INSTR 0
	NOTE Ash, 2
	WAIT
	INSTR 4
	NOTE Ash, 3
	WAIT
	INSTR 0
	NOTE C_, 2
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE C_, 2
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE Gsh, 2
	WAIT
	INSTR 4
	NOTE Gsh, 3
	WAIT
	INSTR 0
	NOTE Gsh, 2
	WAIT
	INSTR 4
	NOTE Gsh, 3
	WAIT
	INSTR 0
	NOTE Ash, 2
	WAIT
	INSTR 4
	NOTE Ash, 3
	WAIT
	INSTR 0
	NOTE Ash, 2
	WAIT
	INSTR 4
	NOTE Ash, 3
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 4
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	NOTE Ash, 2
	WAIT
	NEXT
Pat_7B42:
	NOTE Dsh, 4
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 4
	WAIT
	WAIT
	NOTE D_, 4
	NOTE Dsh, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE Ash, 3
	WAIT
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 4
	WAIT
	WAIT
	NOTE D_, 4
	NOTE Dsh, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE F_, 4
	WAIT
	WAIT
	NOTE C_, 4
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 4
	WAIT
	WAIT
	NOTE D_, 4
	NOTE Dsh, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE Ash, 3
	WAIT
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 4
	WAIT
	WAIT
	NOTE Dsh, 4
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE Dsh, 4
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
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NEXT
Pat_7BC3:
	NOTE Gsh, 4
	WAIT
	WAIT
	WAIT
	NOTE C_, 5
	WAIT
	WAIT
	WAIT
	NOTE Ash, 4
	WAIT
	WAIT
	WAIT
	NOTE D_, 5
	WAIT
	WAIT
	WAIT
	NOTE C_, 5
	WAIT
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 4
	NOTE A_, 4
	NOTE Gsh, 4
	WAIT
	WAIT
	WAIT
	NOTE C_, 5
	WAIT
	WAIT
	WAIT
	NOTE Ash, 4
	WAIT
	WAIT
	WAIT
	NOTE D_, 5
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE Gsh, 4
	WAIT
	WAIT
	WAIT
	NOTE C_, 5
	WAIT
	WAIT
	WAIT
	NOTE Ash, 4
	WAIT
	WAIT
	WAIT
	NOTE D_, 5
	WAIT
	WAIT
	WAIT
	NOTE C_, 5
	WAIT
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 4
	NOTE A_, 4
	NOTE Gsh, 4
	WAIT
	WAIT
	WAIT
	NOTE C_, 5
	WAIT
	WAIT
	WAIT
	NOTE D_, 5
	WAIT
	WAIT
	WAIT
	NOTE F_, 5
	WAIT
	WAIT
	WAIT
	NOTE E_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE E_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NEXT
DrumPat_7C44:
	db $01, $00, $06, $06, $02, $00, $06, $06
	db $01, $00, $06, $06, $02, $00, $06, $06
	db $01, $00, $06, $06, $02, $00, $06, $06
	db $01, $00, $06, $06, $02, $00, $01, $06
	db DRUM_LOOP

; Song 13: instrument table 1, arpeggio table 1
PlaySong13:
	ld a, $77
	ldh [rNR50], a
	xor a
	ld [wFadeOn], a
	push hl
	push de
	push bc
	ld a, HIGH(InstrTable1_1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable1_1 - 2)
	ld [wInstrTable], a
	ld a, HIGH(ArpTable)
	ld [wArpTableHi], a
	ld a, LOW(ArpTable)
	ld [wArpTable], a
	ld de, Song13_Ch1
	call StartMusicCh1
	ld de, Song13_Ch2
	call StartMusicCh2
	ld de, Song13_Ch3
	call StartMusicCh3
	pop bc
	pop de
	pop hl
	ret
Song13_Ch1:
	dw Pat_7CD0
Loop_7C9C:
	dw Pat_7D3D
	dw Pat_7D3D
	dw Pat_7DFB
	dw Pat_7DFB
	ORDER_LOOP Loop_7C9C
Song13_Ch2:
	dw Pat_7D05
	dw Pat_7D05
Loop_7CAC:
	dw Pat_7D7C
	dw Pat_7D7C
	dw Pat_7E2C
	dw Pat_7E2C
	ORDER_LOOP Loop_7CAC
Song13_Ch3:
	dw Pat_7CC6
Loop_7CBA:
	dw Pat_7DB9
	dw Pat_7DB9
	dw Pat_7E60
	dw Pat_7E60
	ORDER_LOOP Loop_7CBA
Pat_7CC6:
	VOLENV 0, $00, $00, $00
	LENGTH $A0
	REST
	REST
	REST
	NEXT
Pat_7CD0:
	DRUMS $05, DrumPat_7E96
	VOLENV 0, $00, $00, $00
	LENGTH $A0
	REST
	LENGTH $50
	REST
	LEN 10
	HWENV $F1, $05, $84
	ARP 0
	VIBRATO $0A, $04, $05
	DUTY_75
	RELEASE $04, $51
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NEXT
Pat_7D05:
	LEN 5
	HWENV $51, $00
	TRANSPOSE $02
	DUTY_75
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NEXT
Pat_7D3D:
	LEN 10
	HWENV $F1, $05, $94
	ARP 0
	VIBRATO $0A, $04, $05
	DRUMS $05, DrumPat_7E96
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NEXT
Pat_7D7C:
	LEN 10
	HWENV $C2, $00
	ARP 6
	VIBRATO $0A, $01, $05
	AUTODUTY $02
	NOTE D_, 4
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	ARP 5
	NOTE C_, 4
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	NOTE F_, 4
	WAIT
	WAIT
	NOTE F_, 4
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	NEXT
Pat_7DB9:
	LEN 10
	VOLENV 10, $15, $1F, $18
	VIBRATO $14, $01, $05
	RELEASE $02, $55
	CH_TRANSPOSE $0C
	WAVE Wave_72A3
	NOTE D_, 4
	WAIT
	WAIT
	NOTE A_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE A_, 3
	NOTE D_, 4
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	NOTE E_, 4
	NOTE D_, 4
	WAIT
	NOTE F_, 4
	NOTE A_, 3
	WAIT
	WAIT
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE E_, 3
	NOTE F_, 3
	WAIT
	NOTE E_, 3
	NOTE C_, 4
	WAIT
	NOTE D_, 4
	NOTE A_, 3
	WAIT
	WAIT
	WAIT
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NEXT
Pat_7DFB:
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	WAIT
	WAIT
	NOTE D_, 2
	WAIT
	WAIT
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	WAIT
	WAIT
	NOTE F_, 2
	WAIT
	WAIT
	NOTE A_, 2
	WAIT
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	WAIT
	WAIT
	NOTE A_, 2
	WAIT
	WAIT
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	WAIT
	WAIT
	NOTE D_, 2
	WAIT
	WAIT
	NEXT
Pat_7E2C:
	ARP 6
	NOTE D_, 3
	WAIT
	WAIT
	NOTE D_, 3
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	WAIT
	WAIT
	NOTE D_, 3
	WAIT
	WAIT
	ARP 5
	NOTE F_, 3
	WAIT
	WAIT
	NOTE F_, 3
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	WAIT
	WAIT
	NOTE F_, 3
	WAIT
	WAIT
	ARP 6
	NOTE A_, 3
	WAIT
	WAIT
	NOTE A_, 3
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	WAIT
	WAIT
	NOTE A_, 3
	WAIT
	WAIT
	NOTE D_, 3
	WAIT
	WAIT
	NOTE D_, 3
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	WAIT
	WAIT
	NOTE D_, 3
	WAIT
	WAIT
	NEXT
Pat_7E60:
	WAVE Wave_7F0B
	CH_TRANSPOSE $00
	NOTE A_, 4
	REST
	NOTE A_, 4
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	REST
	NOTE C_, 5
	NOTE C_, 5
	WAIT
	WAIT
	WAIT
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE E_, 5
	WAIT
	NOTE C_, 5
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	NOTE G_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE A_, 3
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NEXT
DrumPat_7E96:
	db $09, $00, $0A, $00, $0A, $00, $09, $00
	db $0A, $00, $09, $00, $09, $00, $0A, $00
	db $0A, $0A, $09, $00, $09, $00, $09, $00
	db $09, $00, $0A, $00, $0A, $00, $09, $00
	db $0A, $00, $09, $00, $09, $00, $0A, $00
	db $09, $0A, $0A, $0A, $09, $00, $09, $00
	db DRUM_LOOP
Drum9:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7EE4)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_7EE4)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_7EE7)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_7EE7)
	ld [wNoiseNR42Lo], a
	ret
Noise43_7EE4:
	db $51, $32, $FF
Noise42_7EE7:
	db $F0, $81
Drum10:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7F06)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_7F06)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_7F09)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_7F09)
	ld [wNoiseNR42Lo], a
	ret
Noise43_7F06:
	db $51, $32, $FF
Noise42_7F09:
	db $90, $51
Wave_7F0B:
	db $FE, $DB, $97, $53, $13, $54, $32, $10
	db $FE, $DC, $BC, $EF, $DB, $85, $32, $10
