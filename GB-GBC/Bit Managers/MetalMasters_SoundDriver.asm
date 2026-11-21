; =====================================================================
; Metal Masters (U) - Game Boy
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 3 (late variant)
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o metalmasters.o MetalMasters_SoundDriver.asm
;   rgblink -o metalmasters.gb metalmasters.o
;   python tools/cmp_banked.py metalmasters.gb "Metal Masters (U).gb" <ranges listed in the doc>
; (the driver lives in ROM bank 2; the linked file only matches in the listed ranges)
;
; Documentation: MetalMasters_SoundDriver.md / AJG_SoundEngine_Family.md
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
; notes are bytes $00-$5D
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
	db $73, \1, \2
	IF _NARG > 2
		db \3
	ENDC
ENDM
MACRO RELEASE   ; RELEASE 0 = off | RELEASE minlen << 4 | ticks_left, env
	db $7C, \1
	IF _NARG > 1
		db \2
	ENDC
ENDM
MACRO GLIDE
	db $5E
	db \1
ENDM
MACRO GLIDE_OFF
	db $5F
ENDM
MACRO WAIT2
	db $60
ENDM
MACRO VIBRATO
	db $61
	db \1
	db \2
	db \3
ENDM
MACRO VIB_OFF
	db $62
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
MACRO DRUMS
	db $6B
	db \1
	dw \2
ENDM
MACRO DRUMS_OFF
	db $6C
ENDM
MACRO PAN_C
	db $6D
ENDM
MACRO PAN_R
	db $6E
ENDM
MACRO PAN_L
	db $6F
ENDM
MACRO DUTY_50
	db $70
ENDM
MACRO DUTY_75
	db $71
ENDM
MACRO DUTY_12
	db $72
ENDM
MACRO AUTOPAN
	db $74
	db \1
ENDM
MACRO AUTODUTY
	db $75
	db \1
ENDM
MACRO FADE
	db $76
	db \1
	dw \2
ENDM
MACRO FADE_OFF
	db $77
ENDM
MACRO WAVE
	db $78
	dw \1
ENDM
MACRO PORTA
	db $79
	db \1
	db \2
ENDM
MACRO PORTA_OFF
	db $7A
ENDM
MACRO CH_TRANSPOSE
	db $7B
	db \1
ENDM
MACRO ARP_OFF
	db $7D
ENDM
MACRO PAT_GOTO
	db $7E
	dw \1
ENDM
MACRO PAT_CALL
	db $7F
	dw \1
ENDM
MACRO CALL_CODE
	db $80
	dw \1
ENDM
MACRO ENV_DIV
	db $81
	db \1
ENDM
MACRO NOTE_PAN
	db $82
	db \1
ENDM
MACRO ECHO_ON
	db $83
ENDM
MACRO ECHO_OFF
	db $84
ENDM
; ---- order lists ----
MACRO ORDER_LOOP  ; end of an order list: 0, then the order position to continue from
	dw 0, \1
ENDM
; ---- arpeggio and NR50 tables ----
DEF ARP_LOOP EQU $68   ; restart the table
DEF ARP_HOLD EQU $FF   ; stay on the previous entry
DEF FADE_LOOP EQU $68
DEF FADE_END EQU $FF
; ---- drum patterns (one step per drum tick) ----
DEF DRUM_LOOP EQU $FF

; ---- RAM / HRAM ----
DEF wShFreqHi1 EQU $C5C0
DEF wShFreqHi2 EQU $C5C1
DEF wShFreqHi3 EQU $C5C2
DEF wShNR32 EQU $C5C3
DEF wInInstr EQU $C5C4
DEF wTranspose EQU $C5C5
DEF wNoisePan EQU $C5C6
DEF wDrumHold EQU $C5C7
DEF wInstrTable EQU $C5C8
DEF wInstrTableHi EQU $C5C9
DEF wArpTable EQU $C5CA
DEF wArpTableHi EQU $C5CB
DEF wMusicWave EQU $C5CC
DEF wMusicWaveHi EQU $C5CD
DEF wPaused EQU $C5CE
DEF wStereo EQU $C5CF
DEF wNoiseAutoPan EQU $C5D0
DEF wDrumPatHi EQU $C5D1
DEF wDrumPatLo EQU $C5D2
DEF wDrumPos EQU $C5D3
DEF wDrumsOn EQU $C5D4
DEF wDrumTempo EQU $C5D5
DEF wDrumTimer EQU $C5D6
DEF wNoiseNR43Hi EQU $C5D7
DEF wNoiseNR43Lo EQU $C5D8
DEF wNoiseNR42Hi EQU $C5D9
DEF wNoiseNR42Lo EQU $C5DA
DEF wNoisePos EQU $C5DB
DEF wNoiseOn EQU $C5DC
DEF wNoiseAtten EQU $C5DD
DEF wNoiseTimer EQU $C5DE
DEF wNoiseSpeed EQU $C5DF
DEF wFadePtr EQU $C5E0
DEF wFadePtrHi EQU $C5E1
DEF wFadePos EQU $C5E2
DEF wFadeTimer EQU $C5E3
DEF wFadeSpeed EQU $C5E4
DEF wFadeOn EQU $C5E5
DEF wCh1 EQU $C600
DEF wCh2 EQU $C700
DEF wCh3 EQU $C800
DEF wSfx EQU $C900



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
SECTION "MemCopy", ROM0[$1719]

MemCopy:
	ld a, [hli]
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, MemCopy
	ret

SECTION "SoundDriver", ROMX[$5A1C], BANK[2]


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
	ld h, $C9
	call ChannelTick
	ld h, $C9
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
	ld hl, $C63D
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
	jp Cmd_PanR
NotePanRight:
	sub b
	jr nz, NotePanEnd
	jp Cmd_PanL
NotePanEnd:
	sub b
	ret nz
	ld l, $3F
	res 7, [hl]
	jp Cmd_PanC

; ReadStream (de = stream). Notes are first stored in the echo buffer (EchoStore),
; then as in Asterix: note and pointer, period, arpeggio, hardware envelope,
; portamento, length, note-pan, vibrato, released flag, start volume, envelope.
ReadStream:
	ld a, [wInInstr]
	cp $C9
	ret z
	ld a, [de]
	inc de
	cp $5E
	jr nc, StreamCommand
	ld l, $0C
	ld [hl], a
	ld l, $02
	ld [hl], e
	inc l
	ld [hl], d
	call EchoStore
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
	sub $5E
	add a, a
	ld c, a
	add a, $7B
	ld c, a
	adc a, $5C
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
	cp $66
	jr z, InstrDone
	cp $68
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
	sub $5E
	add a, a
	ld c, a
	add a, $7B
	ld c, a
	adc a, $5C
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
	dw Cmd_EchoOn
	dw Cmd_EchoOff
Cmd_EchoOn:
	ld l, $40
	ld [hl], $08
	inc l
	ld [hl], $04
	ret
Cmd_EchoOff:
	ld l, $40
	ld [hl], $00
	inc l
	ld [hl], $00
	ret
Cmd_NotePan:
	ld a, [de]
	inc de
	ld l, $3F
	ld [hl], a
	ld l, $2B
	ld [hl], $00
	ret

; Echo (ECHO_ON): notes go into an 8-entry ring buffer (fields $42-$49, write
; index $41); on every WAIT/WAIT2 the note is stored again and the channel plays the
; entry at read index $40 (4 ahead: the note stored three steps earlier).
EchoStore:
	ld l, $41
	ld b, a
	ld a, [hl]
	and a
	jr nz, EchoPut
	ld a, b
	ret
EchoPut:
	add a, l
	ld l, a
	ld a, b
	ld [hl], a
	ld l, $41
	dec [hl]
	jr nz, EchoAdvance
	ld [hl], $08
EchoAdvance:
	ld l, $40
	dec [hl]
	ret nz
	ld [hl], $08
	ret
EchoTick:
	ld l, $0C
	ld a, [hl]
	ld b, a
	ld l, $41
	ld a, [hl]
	and a
	ret z
	call EchoPut
	ld l, $40
	ld a, [hl]
	inc a
	add a, l
	ld l, a
	ld a, [hl]
	ld l, $0C
	ld [hl], a
	and a
	ret z
	jp SetNoteFreq

; Unreferenced (1 bytes)
	db $C9
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
	cp $63
	ret z
	ld l, $3A
	ld a, h
	cp $C8
	jr z, ReleaseCh3
	cp $C9
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
	call EchoTick
WaitReload:
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
	cp $C8
	jr z, Cmd_Wait
	cp $C9
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
	ld h, $C6
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
	cp $C9
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
	ld l, $40
	ld [hl], a
	inc l
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
	cp $C9
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
	cp $C9
	jr z, BumpNR32Shadow
	ld a, h
	cp $C8
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
	ld a, $69
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
	dw Drum11
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
AutoDutyStep2:
	dec a
	jr z, Cmd_Duty50
	dec a
	jr z, Cmd_Duty75
	dec a
	jr z, Cmd_Duty12
	ld [hl], $01
	jr AutoDutyStep2
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
	cp $C7
	jr z, SetDutyCh2
	cp $C6
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
	cp $68
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
FadeOutTable:
	db $77, $66, $55, $44, $33, $22, $11, $00
	db FADE_END

; WAVE w: Ch3 page: remember w and load it unless an SFX plays. SFX page: load w.
Cmd_Wave:
	ld a, h
	cp $C8
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
	ld bc, $003E
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

; Unreferenced (2 bytes)
	db $BF, $FF

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
	cp $68
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
	cp $C9
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
	add a, $02
	ld c, a
	adc a, $63
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
	ld h, $C6
	jr StartMusicCh
StartMusicCh2:
	ld h, $C7
	jr StartMusicCh
StartMusicCh3:
	ld h, $C8
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
	ld h, $C6
	call OutputChannel
	inc h
	call OutputChannel
	ld hl, $C910
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
	sub $C6
	add a, $C0
	ld l, a
	adc a, $C5
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
	cp $C6
	jr nz, RetrigCh2
	ld a, [wShFreqHi1]
	or $80
	ldh [rNR14], a
	ret
RetrigCh2:
	ld a, [wShFreqHi2]
	or $80
	ldh [rNR24], a
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
	cp $C6
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
	add a, $2B
	ld l, a
	adc a, $65
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
	cp $5E
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
	cp $63
	jr z, PortaAddLength
	cp $64
	jr z, PortaAddLength
	cp $79
	jr z, PortaSkip2
	cp $BD
	jr c, PortaScanEnd
	cp $CD
	jr nc, PortaScanEnd
	jr PortaSkip3
PortaScanEnd:
	cp $68
	jr z, PortaNone
	cp $66
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
	cp $C9
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
	add a, $02
	ld c, a
	adc a, $63
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
	ld hl, $C910
	ld a, [hl]
	and a
	call nz, ResetChannel
	pop af
	ld l, $10
	ld [hl], a
	ld de, $C902
	add a, a
	add a, $B0
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
	ld h, $C6
	jr PlayOnCh
PlayOnCh2:
	ld h, $C7
	jr PlayOnCh
PlayOnCh3:
	ld h, $C8
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
	add a, $B0
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
	ret

; Song 2: instrument table 1, arpeggio table 1
PlaySong2:
	ld a, $77
	ldh [rNR50], a
	xor a
	ld [wFadeOn], a
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
	ret
Song2_Ch1:
	dw Pat_6872
	dw Pat_672F
Song2_Ch2:
	dw Pat_68B4
	dw Pat_6732
Song2_Ch3:
	dw Pat_68E6
	dw Pat_6735
Pat_672F:
	ORDER_JUMP Loop_6784
Pat_6732:
	ORDER_JUMP Loop_67C4
Pat_6735:
	ORDER_JUMP Loop_67EE

; Song 3: instrument table 1, arpeggio table 1
PlaySong3:
	ld a, $77
	ldh [rNR50], a
	xor a
	ld [wFadeOn], a
	ld a, HIGH(InstrTable1_1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable1_1 - 2)
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
	ret
Song3_Ch1:
	dw Pat_6A00
	dw Pat_6773
Song3_Ch2:
	dw Pat_6B68
	dw Pat_6776
Song3_Ch3:
	dw Pat_682F
	dw Pat_6779
Pat_6773:
	ORDER_JUMP Loop_6786
Pat_6776:
	ORDER_JUMP Loop_67C6
Pat_6779:
	ORDER_JUMP Loop_67F0
Pat_677C:
	TRANSPOSE $02
	NEXT
Pat_677F:
	TRANSPOSE $00
	NEXT
Song1_Ch1:
	dw Pat_685B
Loop_6784:
	dw Pat_6851
Loop_6786:
	dw Pat_69BE
Loop_6788:
	dw Pat_677F
	dw Pat_69BE
	dw Pat_677C
	dw Pat_69BE
	dw Pat_677F
	dw Pat_6A4B
	dw Pat_6A4B
	dw Pat_6AB0
	dw Pat_6AB0
	dw Pat_677F
	dw Pat_69BE
	dw Pat_677C
	dw Pat_69BE
	dw Pat_677F
	dw Pat_69BE
	dw Pat_677C
	dw Pat_6A37
	dw Pat_677F
	dw Pat_6A4B
	dw Pat_6A4B
	dw Pat_6AB0
	dw Pat_6AB0
	dw Pat_677F
	dw Pat_69BE
	dw Pat_677C
	dw Pat_69BE
	dw Pat_677F
	ORDER_LOOP Loop_6788
Song1_Ch2:
	dw Pat_689C
Loop_67C4:
	dw Pat_69BE
Loop_67C6:
	dw Pat_6B15
Loop_67C8:
	dw Pat_6B15
	dw Pat_6B15
	dw Pat_6BD8
	dw Pat_6BD8
	dw Pat_6C95
	dw Pat_6C95
	dw Pat_6B15
	dw Pat_6B15
	dw Pat_6B15
	dw Pat_684B
	dw Pat_6BD8
	dw Pat_6BD8
	dw Pat_6C95
	dw Pat_6C95
	dw Pat_6B15
	dw Pat_6B15
	ORDER_LOOP Loop_67C8
Song1_Ch3:
	dw Pat_68CD
Loop_67EE:
	dw Pat_6816
Loop_67F0:
	dw Pat_681F
Loop_67F2:
	dw Pat_6B85
	dw Pat_6B85
	dw Pat_6C19
	dw Pat_6C60
	dw Pat_6CD6
	dw Pat_6CD6
	dw Pat_6B85
	dw Pat_6B85
	dw Pat_6BD2
	dw Pat_6BD2
	dw Pat_6C19
	dw Pat_6C60
	dw Pat_6CD6
	dw Pat_6CD6
	dw Pat_6B85
	dw Pat_6B85
	ORDER_LOOP Loop_67F2
Pat_6816:
	LENGTH $E0
	VOLENV 10, $00, $00, $00
	NOTE D_, 4
	NOTE D_, 4
	NEXT
Pat_681F:
	LENGTH $E0
	VOLENV 15, $13, $1F, $1F
	VIBRATO $15, $06, $06
	WAVE Wave_6DEA
	NOTE D_, 3
	WAIT
	NEXT
Pat_682F:
	LEN 7
	VOLENV 15, $13, $1F, $1F
	CH_TRANSPOSE $00
	ECHO_OFF
	WAVE Wave_6DEA
	NOTE D_, 3
	WAIT
	WAIT
	REST
	NOTE D_, 3
	WAIT
	WAIT
	REST
	NOTE D_, 3
	WAIT
	REST
	NOTE D_, 3
	WAIT
	REST
	NOTE D_, 3
	REST
	NEXT
Pat_684B:
	LENGTH $E0
	REST
	REST
	LEN 7
	NEXT
Pat_6851:
	LENGTH $E0
	HWENV $20, $00
	NOTE D_, 3
	WAIT
	AUTOPAN $00
	NEXT
Pat_685B:
	DUTY_50
	PAN_R
	HWENV $40, $00
	LENGTH $D2
	VIBRATO $01, $04, $08
	PORTA $05, $19
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	PORTA_OFF
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
Pat_6872:
	PAN_R
	VIBRATO $01, $04, $08
	LEN 10
	VOLENV 5, $1F, $00, $11
	NOTE D_, 2
	HWENV $F6, $00
	DUTY_50
	AUTOPAN $02
	LEN 10
	CALL_CODE Code_6913
	NOTE A_, 8
	WAIT
	WAIT
	WAIT
	WAIT
	PAN_C
	CALL_CODE Code_693D
	HWENV $60, $00
	PORTA $26, $0A
	LENGTH $E6
	NOTE D_, 2
	PORTA_OFF
	NOTE D_, 3
	NEXT
Pat_689C:
	LENGTH $D2
	HWENV $20, $00
	DUTY_50
	PAN_L
	VIBRATO $01, $04, $08
	PORTA $05, $19
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	PORTA_OFF
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	VIB_OFF
Pat_68B4:
	LEN 10
	VOLENV 5, $1F, $00, $11
	NOTE D_, 2
	PAN_L
	LENGTH $FF
	HWENV $20, $00
	ARP 1
	AUTODUTY $05
	AUTOPAN $05
	NOTE D_, 2
	NOTE D_, 2
	AUTODUTY $00
	AUTOPAN $00
	ARP_OFF
	NEXT
Pat_68CD:
	LENGTH $D2
	VOLENV 5, $00, $00, $00
	VIBRATO $01, $04, $08
	WAVE Wave_6DAA
	PORTA $03, $19
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	PORTA_OFF
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
Pat_68E6:
	VIBRATO $01, $04, $08
	WAVE Wave_6DCA
	LEN 10
	VOLENV 5, $1F, $00, $11
	NOTE D_, 3
	LEN 10
	VOLENV 15, $11, $1F, $15
	GLIDE $FE
	PAN_C
	NOTE C_, 5
	WAIT
	DRUMS $08, DrumPat_6950
	WAIT
	LENGTH $F0
	GLIDE_OFF
	VOLENV 15, $00, $00, $00
	PORTA $26, $0A
	WAVE Wave_6DAA
	NOTE D_, 3
	PORTA_OFF
	NOTE D_, 4
	NEXT
Code_6913:
	ld a, $1E
	ldh [rNR10], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $02
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_6941)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_6941)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_6949)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_6949)
	ld [wNoiseNR42Lo], a
	ret
Code_693D:
	xor a
	ldh [rNR10], a
	ret
Noise43_6941:
	db $02, $51, $61, $71, $71, $61, $64, $FF
Noise42_6949:
	db $F0, $F0, $F0, $F0, $F0, $F0, $F4
DrumPat_6950:
	db $33, $00, $34, $00, $33, $00, $34, $00
	db $32, $00, $00, $00, $00, $00, $00, $09
	db $00, $00, $00, $09, $00, $00, $00, $00
	db $00, $00, $00, $09, $09, $09, $09, $09
	db $09, $00, $00, DRUM_LOOP

; Unreferenced (28 bytes)
	db $01, $00, $00, $00, $00, $00, $00, $09, $00, $00, $00, $09, $00, $00, $00, $00
	db $00, $00, $00, $09, $09, $09, $09, $09, $09, $00, $00, $FF
Drum9:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_69AD)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_69AD)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_69B6)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_69B6)
	ld [wNoiseNR42Lo], a
	ret
Noise43_69AD:
	db $70, $71, $72, $73, $71, $72, $73, $74
	db $FF
Noise42_69B6:
	db $80, $60, $40, $20, $80, $60, $40, $21
Pat_69BE:
	LEN 7
	ARP_OFF
	PAN_C
	DUTY_50
	DRUMS $07, DrumPat_6D0D
	PAT_CALL Pat_69C9
Pat_69C9:
	INSTR 0
	NOTE F_, 3
	WAIT
	INSTR 1
	NOTE D_, 5
	WAIT
	INSTR 0
	NOTE F_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE F_, 3
	WAIT
	INSTR 1
	NOTE D_, 5
	WAIT
	INSTR 0
	NOTE F_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	WAIT
	INSTR 0
	NOTE F_, 3
	WAIT
	INSTR 1
	NOTE D_, 5
	WAIT
	INSTR 0
	NOTE F_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE F_, 3
	WAIT
	INSTR 1
	NOTE D_, 5
	WAIT
	INSTR 0
	NOTE F_, 3
	WAIT
	NOTE F_, 3
	INSTR 1
	NOTE D_, 5
	NEXT

; Unreferenced (6 bytes)
	db $7F, $00, $6A, $7E, $E1, $69
Pat_6A00:
	LEN 7
	DRUMS $07, DrumPat_6D0D
	INSTR 0
	NOTE F_, 3
	WAIT
	INSTR 1
	NOTE D_, 5
	WAIT
	DRUMS $07, DrumPat_6D0D
	INSTR 0
	NOTE F_, 3
	WAIT
	INSTR 1
	NOTE D_, 5
	WAIT
	DRUMS $07, DrumPat_6D0D
	INSTR 0
	NOTE F_, 3
	WAIT
	INSTR 1
	NOTE D_, 5
	TRANSPOSE $01
	DRUMS $07, DrumPat_6D0D
	INSTR 0
	NOTE F_, 3
	WAIT
	INSTR 1
	NOTE D_, 5
	DRUMS $07, DrumPat_6D0D
	INSTR 0
	NOTE F_, 3
	WAIT
	TRANSPOSE $00
	DRUMS $07, DrumPat_6D0D
	NEXT
Pat_6A37:
	PAT_CALL Pat_69C9
	DRUMS_OFF
	LENGTH $38
	CALL_CODE Code_6EE6
	INSTR 0
	NOTE F_, 3
	REST
	REST
	REST
	LEN 7
	DRUMS $07, DrumPat_6D0D
	NEXT
Pat_6A4B:
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE B_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE B_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE B_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE B_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE G_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE G_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE G_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE G_, 3
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE G_, 3
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE A_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE A_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE A_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE A_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE B_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE B_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE B_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE B_, 3
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE B_, 3
	NEXT
Pat_6AB0:
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE G_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE G_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE A_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE A_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE D_, 4
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE D_, 4
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE B_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE B_, 3
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE A_, 3
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE G_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE G_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE A_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE A_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE B_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE B_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE B_, 3
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE A_, 3
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE A_, 3
	NEXT
Pat_6B15:
	CH_TRANSPOSE $00
	LEN 7
	HWENV $F2, $06, $50
	ARP 0
	AUTODUTY $07
	VIBRATO $01, $08, $05
	NOTE_PAN $00
	PAN_C
	GLIDE_OFF
	NOTE D_, 3
	NOTE D_, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE Dsh, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE Dsh, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE Dsh, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE Dsh, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NEXT
Pat_6B68:
	LEN 7
	HWENV $F2, $06, $50
	ARP 0
	AUTODUTY $07
	VIBRATO $01, $08, $05
	NOTE D_, 3
	NOTE D_, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 2
	NEXT
Pat_6B85:
	LEN 7
	VOLENV 15, $16, $51, $11
	VIB_OFF
	ECHO_ON
	WAVE Wave_6DFA
	CH_TRANSPOSE $0C
Pat_6B91:
	NOTE D_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE A_, 4
	NOTE F_, 5
	WAIT
	NOTE F_, 5
	NOTE E_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE A_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE A_, 4
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	NOTE Ash, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE A_, 4
	NOTE F_, 5
	WAIT
	NOTE F_, 5
	NOTE E_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE A_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE A_, 4
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	NOTE Ash, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NEXT
Pat_6BD2:
	WAVE Wave_6D8A
	PAT_GOTO Pat_6B91
Pat_6BD8:
	NOTE E_, 3
	NOTE E_, 2
	NOTE D_, 3
	NOTE E_, 3
	NOTE E_, 2
	NOTE D_, 3
	NOTE E_, 3
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 3
	NOTE E_, 2
	NOTE D_, 3
	NOTE E_, 2
	NOTE E_, 3
	NOTE E_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE B_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE B_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE B_, 2
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE E_, 3
	NOTE E_, 2
	NOTE B_, 2
	NOTE E_, 3
	NOTE E_, 2
	NOTE B_, 2
	NOTE E_, 3
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE G_, 2
	NOTE E_, 3
	NOTE D_, 2
	NEXT
Pat_6C19:
	VOLENV 15, $11, $1F, $1A
	RELEASE $01, $AA
	VIBRATO $14, $01, $05
	WAVE Wave_6DCA
	NOTE E_, 4
	WAIT2
	NOTE B_, 4
	WAIT2
	NOTE E_, 5
	WAIT2
	NOTE B_, 4
	NOTE G_, 5
	WAIT2
	NOTE G_, 5
	NOTE Fsh, 5
	WAIT2
	NOTE E_, 5
	WAIT2
	NOTE D_, 5
	WAIT2
	LEN 14
	NOTE E_, 5
	LEN 7
	WAIT2
	LEN 14
	NOTE C_, 5
	LEN 7
	WAIT2
	LENGTH $46
	NOTE G_, 4
	LEN 7
	NOTE D_, 4
	WAIT2
	NOTE Fsh, 4
	WAIT2
	NOTE A_, 4
	WAIT2
	NOTE Fsh, 4
	NOTE D_, 5
	WAIT2
	NOTE D_, 5
	NOTE C_, 5
	WAIT2
	NOTE B_, 4
	WAIT2
	NOTE A_, 4
	WAIT2
	LEN 14
	NOTE B_, 4
	LEN 7
	WAIT2
	LEN 14
	NOTE G_, 4
	LEN 7
	WAIT2
	LENGTH $46
	NOTE E_, 4
	LEN 7
	NEXT
Pat_6C60:
	NOTE E_, 4
	WAIT2
	NOTE B_, 4
	WAIT2
	NOTE E_, 5
	WAIT2
	NOTE B_, 4
	NOTE G_, 5
	WAIT2
	NOTE G_, 5
	NOTE Fsh, 5
	WAIT2
	NOTE E_, 5
	WAIT2
	NOTE D_, 5
	WAIT2
	LEN 14
	NOTE E_, 5
	LEN 7
	WAIT2
	LEN 14
	NOTE C_, 5
	LEN 7
	WAIT2
	LENGTH $46
	NOTE G_, 4
	LEN 7
	NOTE D_, 5
	WAIT2
	NOTE A_, 4
	WAIT2
	NOTE D_, 5
	WAIT2
	NOTE E_, 5
	NOTE Fsh, 5
	WAIT2
	NOTE D_, 5
	WAIT2
	NOTE E_, 5
	NOTE Fsh, 5
	WAIT2
	NOTE G_, 5
	WAIT2
	LEN 14
	NOTE Fsh, 5
	LEN 7
	WAIT2
	LENGTH $5B
	NOTE E_, 5
	LEN 7
	NEXT
Pat_6C95:
	NOTE C_, 3
	NOTE C_, 2
	NOTE B_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE B_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE D_, 3
	NOTE G_, 3
	NOTE G_, 2
	NOTE D_, 3
	NOTE G_, 3
	NOTE G_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 3
	NOTE E_, 2
	NOTE B_, 2
	NOTE E_, 2
	NOTE E_, 3
	NOTE E_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE B_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE B_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE E_, 3
	NOTE E_, 2
	NOTE D_, 3
	NOTE E_, 3
	NOTE E_, 2
	NOTE D_, 3
	NOTE E_, 3
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 3
	NOTE E_, 2
	NOTE D_, 3
	NOTE E_, 2
	NOTE E_, 3
	NOTE E_, 2
	NEXT
Pat_6CD6:
	NOTE G_, 4
	WAIT2
	NOTE E_, 4
	WAIT2
	NOTE A_, 4
	WAIT2
	NOTE G_, 4
	LEN 14
	NOTE Fsh, 4
	LEN 7
	WAIT2
	NOTE D_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE A_, 4
	WAIT2
	NOTE B_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 5
	NOTE C_, 5
	WAIT2
	NOTE B_, 4
	WAIT2
	NOTE A_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE Fsh, 4
	NOTE E_, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE A_, 4
	LEN 14
	NOTE Fsh, 4
	LEN 7
	WAIT2
	NOTE D_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE Fsh, 4
	WAIT2
	LENGTH $70
	NOTE E_, 4
	LEN 7
	NEXT
DrumPat_6D0D:
	db $32, $71, $01, $06, $04, $06, $02, $06
	db $04, $06, $01, $06, $04, $06, $02, $06
	db $04, $06, $01, $06, $04, $06, $02, $06
	db $04, $06, $01, $06, $04, $06, $02, $06
	db $01, $06, DRUM_LOOP

; Unreferenced (12 bytes)
	db $71, $02, $06, $04, $02, $FF, $71, $02, $06, $01, $06, $FF

; Instrument table 1, entries 1..3 (the song routines point 2 bytes before:
; entry 0 is never read)
InstrTable1_1:
	dw Instr1_0
	dw Instr1_1
	dw Instr1_2
Instr1_0:
	NOTE_PAN $01
	HWENV $F4, $07, $00
	GLIDE $FD
	END
Instr1_1:
	NOTE_PAN $01
	ARP 0
	DUTY_75
	HWENV $91, $04, $41
	END
Instr1_2:
	DUTY_75
	ARP 2
	HWENV $50, $00
	END

; Unreferenced (16 bytes)
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $77, $77, $00, $00, $00
Wave_6D6A:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF

; Unreferenced (16 bytes)
	db $00, $00, $00, $CD, $EF, $FF, $FF, $FF, $04, $8C, $FF, $FF, $FF, $FF, $FF, $FF
Wave_6D8A:
	db $EE, $EE, $EE, $EF, $FF, $FE, $EE, $EE
	db $EE, $EE, $11, $10, $00, $01, $11, $EE
Wave_6D9A:
	db $FF, $FE, $ED, $B8, $53, $21, $10, $00
	db $00, $01, $12, $35, $8B, $DE, $EF, $FF
Wave_6DAA:
	db $8C, $FE, $ED, $B8, $53, $21, $10, $24
	db $84, $01, $12, $35, $8B, $DE, $EF, $8C
Wave_6DBA:
	db $63, $10, $00, $00, $00, $00, $01, $36
	db $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9
Wave_6DCA:
	db $63, $1F, $01, $47, $74, $10, $01, $36
	db $9C, $E0, $FE, $B8, $8B, $EF, $FE, $C9

; Unreferenced (16 bytes)
	db $B7, $40, $04, $7B, $CD, $FF, $FE, $DC, $02, $46, $8A, $BD, $FD, $BA, $64, $20
Wave_6DEA:
	db $57, $40, $F4, $7B, $FD, $FF, $FE, $DA
	db $02, $46, $8A, $BD, $FD, $BA, $6F, $21
Wave_6DFA:
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $ED, $CB, $A9, $87, $65, $43, $21, $00

; Unreferenced (16 bytes)
	db $22, $22, $22, $22, $22, $22, $EE, $EE, $22, $22, $22, $22, $22, $22, $EE, $EE
Wave_6E1A:
	db $22, $22, $22, $22, $22, $22, $EE, $22
	db $22, $22, $22, $22, $22, $22, $EE, $22

; Unreferenced (48 bytes)
	db $04, $8B, $DE, $FF, $ED, $CB, $A9, $87, $65, $44, $44, $32, $11, $24, $7A, $74
	db $20, $13, $69, $BD, $FD, $B9, $64, $20, $13, $68, $B8, $64, $20, $24, $68, $64
	db $20, $24, $68, $AC, $EC, $A8, $64, $20, $24, $68, $A8, $64, $20, $24, $68, $64
Noise43_6E5A:
	db $02, $51, $61, $71, $91, $71, $60, $FF
Noise42_6E62:
	db $F0, $F0, $D0, $90, $70, $50, $41
Noise42_6E69:
	db $F0, $F0, $D0, $A0, $80, $80, $87

; Unreferenced (22 bytes)
	db $60, $52, $42, $41, $22, $11, $21, $FF, $F0, $E0, $D0, $B0, $A0, $90, $61, $F0
	db $E0, $D0, $B0, $A0, $70, $41
Noise43_6E86:
	db $06, $04, $03, $03, $07, $FF
Noise42_6E8C:
	db $F0, $F0, $D0, $C0, $85
Noise43_6E91:
	db $04, $02, $01, $01, $FF
Noise42_6E96:
	db $80, $60, $40, $23
Noise43_6E9A:
	db $04, $02, $01, $01, $04, $02, $01, $FF
Noise42_6EA2:
	db $A0, $60, $33, $23, $A0, $60, $33
Noise43_6EA9:
	db $04, $02, $06, $03, $FF
Noise42_6EAE:
	db $B0, $A0, $50, $54
Noise43_6EB2:
	db $50, $41, $50, $51, $52, $53, $51, $FF
Noise42_6EBA:
	db $F0, $70, $F0, $70, $D0, $70, $83
Code_6EC1:
	ld a, $08
	ld [wDrumHold], a
	call NoisePanCentre
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6E5A)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_6E5A)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_6E62)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_6E62)
	ld [wNoiseNR42Lo], a
	ret
Code_6EE6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6E5A)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_6E5A)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_6E69)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_6E69)
	ld [wNoiseNR42Lo], a
	ret
Code_6F03:
	ld a, $0A
	ld [wDrumHold], a
	call NoisePanCentre
Drum8:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6F28)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_6F28)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_6F30)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_6F30)
	ld [wNoiseNR42Lo], a
	ret
Noise43_6F28:
	db $02, $51, $61, $71, $91, $71, $60, $FF
Noise42_6F30:
	db $F0, $F0, $F0, $F0, $F0, $70, $52
Drum2:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6F79)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_6F79)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_6F81)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_6F81)
	ld [wNoiseNR42Lo], a
	ret

; Unreferenced (37 bytes)
	db $3E, $08, $EA, $C7, $C5, $CD, $49, $5F, $AF, $EA, $DB, $C5, $3C, $EA, $DC, $C5
	db $3E, $6E, $EA, $D7, $C5, $3E, $70, $EA, $D8, $C5, $3E, $6F, $EA, $D9, $C5, $3E
	db $88, $EA, $DA, $C5, $C9
Noise43_6F79:
	db $60, $52, $42, $41, $22, $11, $04, $FF
Noise42_6F81:
	db $F0, $F0, $F0, $A0, $30, $40, $53

; Unreferenced (7 bytes)
	db $F0, $F0, $F0, $F0, $F0, $F0, $61
Drum3:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6EB2)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_6EB2)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_6EBA)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_6EBA)
	ld [wNoiseNR42Lo], a
	ret
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6EA9)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_6EA9)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_6EAE)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_6EAE)
	ld [wNoiseNR42Lo], a
	ret
Drum5:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6E9A)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_6E9A)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_6EA2)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_6EA2)
	ld [wNoiseNR42Lo], a
	ret
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6E91)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_6E91)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_6E96)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_6E96)
	ld [wNoiseNR42Lo], a
	ret
Drum7:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6E86)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_6E86)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_6E8C)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_6E8C)
	ld [wNoiseNR42Lo], a
	ret
ArpTable:
	dw Arp0
	dw PeriodTable
	dw Arp2
Arp0:
	db $0C, $00, ARP_HOLD
Arp2:
	db $0C, ARP_HOLD
Stub_Ch1Sfx01:
	ld a, $01
	jp PlayOnCh1
Stub_Ch1Sfx02:
	ld a, $02
	jp PlayOnCh1
Stub_Ch2Sfx01:
	ld a, $01
	jp PlayOnCh2
Stub_Ch2Sfx02:
	ld a, $02
	jp PlayOnCh2
Stub_Ch3Sfx03:
	ld a, $03
	jp PlayOnCh3
Stub_Ch3Sfx04:
	ld a, $04
	jp PlayOnCh3
Stub_Ch1Sfx05:
	ld a, $05
	call PlayOnCh1
Stub_Ch3Sfx06:
	ld a, $06
	jp PlayOnCh3
Stub_Ch3Sfx07:
	ld a, $07
	jp PlayOnCh3
Stub_Ch3Sfx08:
	ld a, $08
	jp PlayOnCh3
Stub_Sfx09:
	ld a, $09
	jp PlaySfx
Stub_Sfx10:
	ld a, $0A
	jp PlaySfx
Stub_Ch1Sfx11:
	ld a, $0B
	jp PlayOnCh1
Stub_Ch3Sfx12:
	ld a, $0C
	jp PlayOnCh3
Stub_Ch3Sfx13:
	ld a, $0D
	jp PlayOnCh3
Stub_Ch3Sfx14:
	ld a, $0E
	jp PlayOnCh3
Stub_Ch3Sfx15:
	ld a, $0F
	jp PlayOnCh3
Stub_Ch3Sfx16:
	ld a, $10
	jp PlayOnCh3
Stub_Ch3Sfx17:
	ld a, $11
	jp PlayOnCh3
Stub_Ch2Sfx18:
	ld a, $12
	jp PlayOnCh2
Stub_Ch1Sfx19:
	ld a, $13
	jp PlayOnCh1
Stub_Ch1Sfx20:
	ld a, $14
	jp PlayOnCh1
Stub_Ch2Sfx20:
	ld a, $14
	jp PlayOnCh2
Stub_Sfx21:
	ld a, $15
	jp PlaySfx
Stub_Sfx22:
	ld a, $16
	jp PlaySfx
Stub_Sfx23:
	ld a, $17
	call PlaySfx
Stub_Ch1Sfx24:
	ld a, $18
	jp PlayOnCh1
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

; Sound effect 23
Sfx23:
	VOLENV 15, $00, $00, $00
	WAVE Wave_6DCA
	LEN 3
	NOTE C_, 6
	NOTE Dsh, 6
	NOTE G_, 6
	VOLENV 10, $00, $00, $00
	CH_TRANSPOSE $FF
	NOTE C_, 6
	NOTE Dsh, 6
	NOTE G_, 6
	VOLENV 5, $00, $00, $00
	CH_TRANSPOSE $FE
	NOTE C_, 6
	NOTE Dsh, 6
	NOTE G_, 6
	END

; Sound effect 24
Sfx24:
	DUTY_50
	VOLENV 15, $00, $00, $00
	LEN 3
	NOTE C_, 6
	NOTE Dsh, 6
	NOTE G_, 6
	VOLENV 10, $00, $00, $00
	CH_TRANSPOSE $01
	NOTE C_, 6
	NOTE Dsh, 6
	NOTE G_, 6
	VOLENV 5, $00, $00, $00
	CH_TRANSPOSE $02
	NOTE C_, 6
	NOTE Dsh, 6
	NOTE G_, 6
	END

; Sound effect 20
Sfx20:
	HWENV $20, $00
	DUTY_12
	LEN 7
	PORTA $05, $50
	CALL_CODE Code_7313
	NOTE C_, 6
	NOTE E_, 6
	PORTA_OFF
	LENGTH $01
	NOTE G_, 5
	CALL_CODE Code_7347
	END

; Sound effect 19
Sfx19:
	HWENV $94, $00
	DUTY_75
	CALL_CODE Code_74BC
	LEN 10
	GLIDE $FF
	NOTE C_, 4
	END

; Sound effect 18
Sfx18:
	HWENV $F2, $00
	DUTY_50
	GLIDE $FD
	CALL_CODE Code_7494
	LEN 9
	NOTE E_, 3
	LEN 7
	NOTE E_, 3
	NOTE D_, 3
	END

; Sound effect 16
Sfx16:
	WAVE Wave_6D6A
	VOLENV 10, $00, $1F, $12
	GLIDE $FD
	LEN 3
	CALL_CODE Code_6F03
	NOTE C_, 4
	CALL_CODE Code_6F03
	NOTE C_, 4
	LEN 6
	CALL_CODE Code_6F03
	NOTE C_, 4
	GLIDE $FF
	WAIT
	END

; Sound effect 17
Sfx17:
	WAVE Wave_6D9A
	VOLENV 10, $00, $1F, $11
	GLIDE $FD
	LEN 3
	CALL_CODE Drum3
	NOTE E_, 4
	CALL_CODE Drum3
	NOTE E_, 4
	LEN 4
	CALL_CODE Drum1
	NOTE C_, 4
	GLIDE $FF
	WAIT
	END

; Sound effect 13
Sfx13:
	VOLENV 5, $00, $00, $00
	WAVE Wave_6E1A
	LEN 2
	CALL_CODE Code_7320
	PORTA $08, $14
	NOTE A_, 3
	PORTA_OFF
	NOTE F_, 4
	WAVE Wave_6D9A
	VOLENV 15, $11, $1F, $11
	LEN 3
	GLIDE $FE
	CALL_CODE Code_743A
	NOTE F_, 3
	CALL_CODE Code_6EC1
	LEN 8
	NOTE A_, 3
	END

; Sound effect 12
Sfx12:
	VOLENV 5, $00, $00, $00
	WAVE Wave_6E1A
	LEN 2
	CALL_CODE Code_7320
	PORTA $08, $14
	NOTE A_, 3
	PORTA_OFF
	NOTE F_, 4
	WAVE Wave_6DBA
	VOLENV 15, $11, $1F, $11
	CALL_CODE Code_7416
	LEN 10
	GLIDE $FE
	NOTE F_, 3
	END

; Sound effect 11
Sfx11:
	GLIDE $FD
	DUTY_50
	HWENV $C1, $05, $00
	CALL_CODE Code_7306
	LEN 5
	NOTE C_, 3
	END

; Unreferenced (15 bytes)
	db $78, $6A, $6D, $CC, $00, $00, $00, $80, $06, $73, $D1, $5E, $FD, $18, $66

; Sound effect 9
Sfx09:
	VOLENV 15, $00, $00, $00
	LEN 5
	WAVE Wave_6DBA
	NOTE Csh, 6
	END

; Sound effect 10
Sfx10:
	VOLENV 15, $00, $00, $00
	LEN 5
	WAVE Wave_6DBA
	NOTE Csh, 7
	END

; Sound effect 21
Sfx21:
	VOLENV 15, $00, $00, $00
	LEN 10
	WAVE Wave_6DEA
	NOTE Csh, 5
	END

; Sound effect 7
Sfx07:
	WAVE Wave_6DBA
	VOLENV 5, $00, $00, $00
	LEN 7
	PORTA $1E, $50
	CALL_CODE Code_733A
	NOTE A_, 2
	PORTA_OFF
	LENGTH $FF
	NOTE D_, 3
	END

; Sound effect 8
Sfx08:
	WAVE Wave_6DBA
	CALL_CODE Code_73F6
	VOLENV 5, $00, $00, $00
	LEN 7
	PORTA $1E, $50
	NOTE D_, 3
	NOTE F_, 2
	END

; Sound effect 5
Sfx05:
	HWENV $F1, $00
	LEN 4
	CALL_CODE Code_7320
	REST
	LEN 10
	GLIDE $FE
	DUTY_50
	LEN 5
	NOTE C_, 3
	LEN 5
	NOTE E_, 3
	END

; Sound effect 6
Sfx06:
	WAVE Wave_6DEA
	VOLENV 5, $00, $00, $00
	LEN 3
	PORTA $05, $50
	NOTE A_, 5
	PORTA_OFF
	NOTE B_, 5
	VOLENV 15, $11, $1F, $12
	GLIDE $FE
	CALL_CODE Code_6F03
	WAVE Wave_6DBA
	LEN 10
	NOTE C_, 4
	END

; Sound effect 3
Sfx03:
	WAVE Wave_6D9A
	LEN 2
	VOLENV 5, $00, $00, $00
	CALL_CODE Code_7320
	PORTA $0A, $14
	NOTE A_, 5
	PORTA_OFF
	NOTE Csh, 5
	VOLENV 15, $00, $1F, $11
	CALL_CODE Code_7350
	LEN 8
	PORTA $14, $14
	NOTE A_, 3
	NOTE D_, 5
	NOTE A_, 2
	WAIT
	END

; Sound effect 14
Sfx14:
	WAVE Wave_6D9A
	LEN 2
	VOLENV 5, $00, $00, $00
	CALL_CODE Code_7320
	PORTA $0A, $14
	NOTE A_, 5
	PORTA_OFF
	NOTE Csh, 5
	VOLENV 15, $00, $1F, $11
	CALL_CODE Code_7390
	LEN 8
	GLIDE $FF
	NOTE A_, 3
	NOTE A_, 3
	END

; Sound effect 4
Sfx04:
	WAVE Wave_6DEA
	VOLENV 5, $00, $00, $00
	LEN 2
	PORTA $05, $50
	CALL_CODE Code_7320
	NOTE D_, 6
	PORTA_OFF
	NOTE G_, 6
	VOLENV 15, $00, $1F, $13
	CALL_CODE Code_73C0
	LEN 32
	NOTE C_, 3
	END

; Sound effect 15
Sfx15:
	WAVE Wave_6D6A
	VOLENV 15, $11, $1F, $11
	CALL_CODE Code_7416
	LEN 5
	GLIDE $FE
	NOTE C_, 3
	GLIDE_OFF
	WAVE Wave_6DEA
	VOLENV 5, $1F, $00, $20
	CALL_CODE Code_7460
	LEN 21
	NOTE E_, 3
	END

; Sound effect 1
Sfx01:
	CALL_CODE Code_693D
	HWENV $20, $00
	DUTY_12
	LEN 7
	PORTA $03, $50
	CALL_CODE Code_7313
	NOTE A_, 6
	PORTA_OFF
	NOTE D_, 7
	GLIDE $FD
	DUTY_50
	HWENV $C1, $05, $00
	CALL_CODE Code_7306
	LEN 5
	NOTE C_, 3
	END

; Sound effect 2
Sfx02:
	CALL_CODE Code_693D
	HWENV $20, $00
	DUTY_12
	LEN 7
	PORTA $03, $50
	CALL_CODE Code_7313
	NOTE G_, 6
	PORTA_OFF
	NOTE B_, 6
	GLIDE $FD
	DUTY_50
	HWENV $C1, $05, $00
	CALL_CODE Code_7306
	LEN 5
	NOTE C_, 3
	END
Code_7306:
	ld a, $91
	ldh [rNR42], a
	ld a, $61
	ldh [rNR43], a
	ld a, $80
	ldh [rNR44], a
	ret
Code_7313:
	ld a, $20
	ldh [rNR42], a
	ld a, $04
	ldh [rNR43], a
	ld a, $80
	ldh [rNR44], a
	ret
Code_7320:
	ld a, $2A
	ldh [rNR42], a
	ld a, $14
	ldh [rNR43], a
	ld a, $80
	ldh [rNR44], a
	ret

; Unreferenced (13 bytes)
	db $3E, $84, $E0, $21, $3E, $32, $E0, $22, $3E, $80, $E0, $23, $C9
Code_733A:
	ld a, $30
	ldh [rNR42], a
	ld a, $10
	ldh [rNR43], a
	ld a, $80
	ldh [rNR44], a
	ret
Code_7347:
	xor a
	ldh [rNR42], a
	ldh [rNR44], a
	ld [wNoiseOn], a
	ret
Code_7350:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_736D)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_736D)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_737F)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_737F)
	ld [wNoiseNR42Lo], a
	ret
Noise43_736D:
	db $57, $78, $59, $5A, $5B, $5C, $5D, $5E
	db $5F, $5E, $5D, $5C, $5B, $5A, $59, $58
	db $50, $FF
Noise42_737F:
	db $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
	db $F0, $E0, $D0, $C0, $A0, $80, $50, $40
	db $21
Code_7390:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_73AD)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_73AD)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_73B7)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_73B7)
	ld [wNoiseNR42Lo], a
	ret
Noise43_73AD:
	db $57, $78, $59, $5A, $5B, $5C, $5D, $5E
	db $5F, $FF
Noise42_73B7:
	db $F0, $F0, $F0, $F0, $F0, $F0, $D0, $A0
	db $91
Code_73C0:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_73DD)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_73DD)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_73EA)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_73EA)
	ld [wNoiseNR42Lo], a
	ret
Noise43_73DD:
	db $6F, $6E, $6D, $6C, $6B, $6A, $69, $68
	db $68, $68, $68, $68, $FF
Noise42_73EA:
	db $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
	db $F0, $F0, $F0, $C1
Code_73F6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7413)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_7413)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_7415)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_7415)
	ld [wNoiseNR42Lo], a
	ret
Noise43_7413:
	db $4E, $FF
Noise42_7415:
	db $C1
Code_7416:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7433)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_7433)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_7437)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_7437)
	ld [wNoiseNR42Lo], a
	ret
Noise43_7433:
	db $4A, $5A, $50, $FF
Noise42_7437:
	db $F0, $D0, $B1
Code_743A:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7457)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_7457)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_745C)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_745C)
	ld [wNoiseNR42Lo], a
	ret
Noise43_7457:
	db $24, $22, $21, $21, $FF
Noise42_745C:
	db $F0, $80, $60, $41
Code_7460:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $D2
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ld a, HIGH(Noise43_7485)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_7485)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Rst00_MemCopy)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Rst00_MemCopy)
	ld [wNoiseNR42Lo], a
	ret
Noise43_7485:
	db $18, $3A, $47, $49, $2E, $2D, $1C, $28
	db $4A, $57, $39, $4E, $1D, $0C, $FF
Code_7494:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_74B1)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_74B1)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_74B7)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_74B7)
	ld [wNoiseNR42Lo], a
	ret
Noise43_74B1:
	db $57, $56, $54, $53, $47, $FF
Noise42_74B7:
	db $F0, $F0, $60, $70, $F3
Code_74BC:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $A2
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ld a, HIGH(Noise43_74E1)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_74E1)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Rst00_MemCopy)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Rst00_MemCopy)
	ld [wNoiseNR42Lo], a
	ret
Noise43_74E1:
	db $46, $45, $44, $43, $42, $41, $32, $30
	db $FF

; Unreferenced (9 bytes)
	db $10, $10, $20, $31, $33, $34, $35, $36, $FF

; Sound effect 22
Sfx22:
	DRUMS $19, DrumPat_74FC
	LENGTH $C8
	WAIT
	DRUMS_OFF
	END
DrumPat_74FC:
	db $0A, $00, $00, $00, $0B, $00, $00, $00
	db DRUM_LOOP
Drum10:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_753F)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_753F)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_7541)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_7541)
	ld [wNoiseNR42Lo], a
	ret
Drum11:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7542)
	ld [wNoiseNR43Hi], a
	ld a, LOW(Noise43_7542)
	ld [wNoiseNR43Lo], a
	ld a, HIGH(Noise42_7544)
	ld [wNoiseNR42Hi], a
	ld a, LOW(Noise42_7544)
	ld [wNoiseNR42Lo], a
	ret
Noise43_753F:
	db $61, $FF
Noise42_7541:
	db $0F
Noise43_7542:
	db $61, $FF
Noise42_7544:
	db $F7
