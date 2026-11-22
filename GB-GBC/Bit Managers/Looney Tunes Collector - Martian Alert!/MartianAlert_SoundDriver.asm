; =====================================================================
; Looney Tunes Collector: Martian Alert! (E) (M6) [C] - Game Boy Color
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o martian.o MartianAlert_SoundDriver.asm
;   rgblink -o martian.gb martian.o
;   python tools/cmp_banked.py martian.gb "Looney Tunes Collector - Martian Alert! (E) (M6) [C][!].gbc" 48:4000-7FFF
; (driver and data fill ROM bank 48; the linked file only matches in that range)
;
; Documentation: MartianAlert_SoundDriver.md / AJG_SoundEngine_Family.md
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
MACRO REPEAT    ; play the following bytes n times (up to REPEAT_END), n = 2-9
	db $F6 + \1
ENDM
MACRO LEN       ; note length in ticks, 1-48
	db $C7 + \1
ENDM
MACRO VOLENV    ; start volume + envelope (CH3/SFX): atk (lo=count hi=step), dec (lo=count hi=step), rates (hi=atk lo=dec)
	db $B8 + \1, \2, \3, \4
ENDM
MACRO INSTR     ; instrument n = entry n + 1 of the current instrument table
	db $8B + \1
ENDM
MACRO ARP       ; arpeggio n of the current arpeggio table
	db $A0 + \1
ENDM
MACRO HWENV     ; HWENV env, 0 | HWENV env, ticks, env2  (pulse NRx2 at note on, env2 after ticks)
	db $75, \1, \2
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
MACRO LENGTH
	db $6B
	db \1
ENDM
MACRO DRUMS
	db $6C
	db \1
	dw \2
ENDM
MACRO DRUMS_OFF
	db $6D
ENDM
MACRO PAN_C
	db $6E
ENDM
MACRO PAN_R
	db $6F
ENDM
MACRO PAN_L
	db $70
ENDM
MACRO DUTY_50
	db $71
ENDM
MACRO DUTY_75
	db $72
ENDM
MACRO DUTY_12
	db $73
ENDM
MACRO DUTY_25
	db $74
ENDM
MACRO AUTOPAN
	db $76
	db \1
ENDM
MACRO AUTODUTY  ; pulse/SFX pages: next duty every n ticks
	db $77
	db \1
ENDM
MACRO WAVE_SEQ  ; the same byte on the Ch3 page: a wave list (each note loads the next wave)
	db $77
	dw \1
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
MACRO REPEAT_END
	db $81
ENDM
MACRO VOL
	db $82
	db \1
ENDM
MACRO SLIDE_UP
	db $83
	db \1
ENDM
MACRO SLIDE_DOWN
	db $84
	db \1
ENDM
MACRO PINGPONG
	db $85
ENDM
MACRO PINGPONG_OFF
	db $86
ENDM
MACRO GLISS_1
	db $87
ENDM
MACRO GLISS_2
	db $88
ENDM
MACRO GLISS_3
	db $89
ENDM
MACRO GLISS_OFF
	db $8A
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
; ---- drum patterns: one step per drum tick, read up to a 0 or a drum sound (1-49) ----
DEF DRUM_PAN_C EQU $32          ; noise pan centre / right / left
DEF DRUM_PAN_R EQU $33
DEF DRUM_PAN_L EQU $34
DEF DRUM_PINGPONG EQU $35       ; noise pan left/right alternately on the first step of each noise sequence
DEF DRUM_PINGPONG_OFF EQU $36
DEF DRUM_REPEAT_END EQU $37
DEF DRUM_LEVEL EQU $38          ; + 0-15: noise level (attenuation 15 - n)
DEF DRUM_SPEED EQU $48          ; + 0-19: noise sequence speed
DEF DRUM_REPEAT EQU $5B         ; + n: repeat the following bytes up to DRUM_REPEAT_END
DEF DRUM_TEMPO EQU $C7         ; + n: one step every n ticks
DEF DRUM_LOOP EQU $FF           ; restart the pattern

; ---- RAM / HRAM ----
DEF wCh1 EQU $D200
DEF wPaused EQU $D240
DEF wShNR32 EQU $D241
DEF wInInstr EQU $D242
DEF wNoisePan EQU $D243
DEF wDrumHold EQU $D244
DEF wInstrTable EQU $D245
DEF wInstrTableHi EQU $D246
DEF wArpTable EQU $D247
DEF wArpTableHi EQU $D248
DEF wMusicWave EQU $D249
DEF wMusicWaveHi EQU $D24A
DEF wNoisePingPong EQU $D24B
DEF wDrumPatHi EQU $D24C
DEF wDrumPat EQU $D24D
DEF wDrumPos EQU $D24E
DEF wDrumsOn EQU $D24F
DEF wDrumTempo EQU $D250
DEF wDrumTimer EQU $D251
DEF wDrumLoopCount EQU $D252
DEF wDrumLoopPos EQU $D253
DEF wNoise43Hi EQU $D254
DEF wNoise43 EQU $D255
DEF wNoise42Hi EQU $D256
DEF wNoise42 EQU $D257
DEF wNoisePos EQU $D258
DEF wNoiseOn EQU $D259
DEF wNoiseAtten EQU $D25A
DEF wNoiseTimer EQU $D25B
DEF wNoiseSpeed EQU $D25C
DEF wFadeTable EQU $D25D
DEF wFadeTableHi EQU $D25E
DEF wFadePos EQU $D25F
DEF wFadeTimer EQU $D260
DEF wFadeSpeed EQU $D261
DEF wFadeOn EQU $D262
DEF wDutyCh1 EQU $D263
DEF wDutyCh2 EQU $D264
DEF wCurSong EQU $D265
DEF wCh2 EQU $D300
DEF wCh3 EQU $D400
DEF wSfx EQU $D500

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


SECTION "SoundDriver", ROMX[$4000], BANK[48]


; Command jump table ($60-...).
CmdTable:
	dw Cmd_Glide
	dw Cmd_GlideOff
	dw Cmd_Wait
	dw Cmd_Vibrato
	dw Cmd_VibOff
	dw Cmd_Wait
	dw Cmd_Rest
	dw StopAll
	dw Cmd_End
	dw Cmd_Transpose
	dw Cmd_Next
	dw Cmd_Length
	dw Cmd_Drums
	dw Cmd_DrumsOff
	dw Cmd_PanC
	dw Cmd_PanR
	dw Cmd_PanL
	dw Cmd_Duty50
	dw Cmd_Duty75
	dw Cmd_Duty12
	dw Cmd_Duty25
	dw Cmd_HwEnv
	dw Cmd_AutoPan
	dw Cmd_AutoDuty
	dw Cmd_Fade
	dw FadeStop
	dw WaveNoSeq
	dw Cmd_ChTranspose
	dw Cmd_Release
	dw Cmd_ArpOff
	dw Cmd_PatGoto
	dw Cmd_PatCall
	dw Cmd_CallCode
	dw Cmd_RepeatEnd
	dw Cmd_Vol
	dw Cmd_SlideUp
	dw Cmd_SlideDown
	dw Cmd_PingPong
	dw Cmd_PingPongOff
	dw Cmd_Gliss1
	dw Cmd_Gliss2
	dw Cmd_Gliss3
	dw Cmd_GlissOff
	jp SndUpdate                       ; SndUpdate
	jp SndPause                        ; SndPause
	jp SndResume                       ; SndResume
	jp StopAll                         ; StopAll
	jp PlaySong                        ; PlaySong (A = song number; sets the default instrument table)
	jp PlaySfx                         ; PlaySfx (A = id)
	jp SndInit                         ; SndInit
	jp SongFadeIn                      ; SongFadeIn (A = speed)
	jp SongFadeOut                     ; SongFadeOut (A = speed)
PlaySong:
	push af
	call StopAll
	ld a, $73
	ld [wInstrTableHi], a
	ld a, $7C
	ld [wInstrTable], a
	pop af
	cp $0C
	ret nc
	ld [wCurSong], a
	add a, a
	add a, $C2
	ld l, a
	adc a, $74
	sub l
	ld h, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl
Cmd_PingPong:
	ld l, $04
	set 5, [hl]
	ld l, $3C
	xor a
	ld [hli], a
	ld [hli], a
	ret
Cmd_PingPongOff:
	ld l, $04
	res 5, [hl]
	ret
Cmd_Gliss1:
	ld a, $01
	ld l, $3F
	ld [hl], a
	ret
Cmd_Gliss2:
	ld a, $02
	ld l, $3F
	ld [hl], a
	ret
Cmd_Gliss3:
	ld a, $03
	ld l, $3F
	ld [hl], a
	ret
Cmd_GlissOff:
	xor a
	ld l, $3F
	ld [hl], a
	ret

; Unreferenced (3 bytes)
	db $C3, $22, $4A

; SndResume / SndPause: wPaused = 0 / 1; both silence CH1-CH4 and reset the SFX
; page (which reloads the music wave). StopAll and SongFadeIn call SndResume.
SndResume:
	xor a
	ld [wPaused], a
	jp SilenceAll
SndPause:
	ld a, $01
	ld [wPaused], a
	dec a
SilenceAll:
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR32], a
	ldh [rNR42], a
PauseTrigger:
	ld a, $80
	ldh [rNR14], a
	ldh [rNR24], a
	ldh [rNR34], a
	ldh [rNR44], a
	jp ResetSfxPage

; SndUpdate (once per frame): tick the four pages (or only the SFX page while paused),
; drums + noise sequence, output, NR51, then the NR50 fade.
SndUpdate:
	ld a, [wPaused]
	and a
	jp nz, UpdatePaused
	ld h, $D2
	call ChannelTick
	inc h
	call ChannelTick
	inc h
	call ChannelTick
	call DrumTick
	ld h, $D5
	call ChannelTick

; Output, pulse pages: NRx3 = period low + pitch offset; when the high byte changed
; or the envelope flag ($33) is set: with the flag NRx2 = field $32 and NRx4 =
; high | $80, else NRx4 = high. (Obelix GBC's duty shadows are gone: duty goes
; straight to NR11/NR21.)
OutputCh1:
	ld hl, $D225
	ld a, [wDutyCh1]
	ldh [rNR11], a
	ld l, $25
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, $05
	ld a, [hli]
	add a, e
	ldh [rNR13], a
	ld a, [hli]
	adc a, d
	ld b, [hl]
	cp b
	jr z, OutputCh1Env
	ld b, a
	ld [hl], a
	ld l, $29
	ld a, b
	ld c, [hl]
	inc c
	dec c
	jr z, OutputCh1Hi
	jp OutputCh1Retrig
OutputCh1Env:
	ld l, $29
	ld a, [hl]
	and a
	jr z, OutputCh2
OutputCh1Retrig:
	ld [hl], $00
	dec l
	ld a, [hl]
	ldh [rNR12], a
	ld a, b
	or $80
OutputCh1Hi:
	ldh [rNR14], a
OutputCh2:
	inc h
	ld a, [wDutyCh2]
	ldh [rNR21], a
	ld l, $25
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, $05
	ld a, [hli]
	add a, e
	ldh [rNR23], a
	ld a, [hli]
	adc a, d
	ld b, [hl]
	cp b
	jr z, OutputCh2Env
	ld b, a
	ld [hl], a
	ld l, $29
	ld a, b
	ld c, [hl]
	inc c
	dec c
	jr z, OutputCh2Hi
	jp OutputCh2Retrig
OutputCh2Env:
	ld l, $29
	ld a, [hl]
	and a
	jr z, OutputCh3
OutputCh2Retrig:
	ld [hl], $00
	dec l
	ld a, [hl]
	ldh [rNR22], a
	ld a, b
	or $80
OutputCh2Hi:
	ldh [rNR24], a

; Output, wave channel: the SFX page if an SFX plays, else Ch3. Period as above;
; NR32 = Ch3VolTable[volume] when it differs from wShNR32.
OutputCh3:
	ld hl, $D527
	ld a, [hl]
	and a
	jr nz, OutputWaveCh
	dec h
OutputWaveCh:
	ld l, $25
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, $05
	xor a
	ldh [rNR31], a
	ld a, [hli]
	add a, e
	ldh [rNR33], a
	ld a, [hli]
	adc a, d
	cp [hl]
	jr z, WriteCh3Vol
	ld [hl], a
	ldh [rNR34], a
WriteCh3Vol:
	inc l
	ld a, [hl]
	add a, $C9
	ld l, a
	adc a, $41
	sub l
	ld h, a
	ld a, [wShNR32]
	cp [hl]
	jr z, SetNR51
	ld a, [hl]
	ld [wShNR32], a
	ldh [rNR32], a

; NR51 = Ch1 pan | Ch2 pan << 1 | (SFX or Ch3) pan << 2 | wNoisePan; $FF while
; wStereo = 0 (the game sets it).
SetNR51:
	ld hl, $D238
	ld c, [hl]
	inc h
	ld a, [hl]
	rlc a
	or c
	ld c, a
	inc h
	ld a, [$D527]
	and a
	jr z, SetNR51_Ch3
	inc h
SetNR51_Ch3:
	ld l, $38
	ld a, [hl]
	rlc a
	rlc a
	or c
	ld c, a
	ld a, [wNoisePan]
	or c
WriteNR51:
	ldh [rNR51], a
	jp DoFade

; Paused: NR50 fade, tick and output only the SFX page.
UpdatePaused:
	call DoFade
	ld h, $D5
	call ChannelTick
	call OutputWaveCh
	jr SetNR51

; CH3 volume table (0-15 -> NR32).
Ch3VolTable:
	db $00, $00, $00, $00, $60, $60, $60, $60
	db $40, $40, $40, $40, $20, $20, $20, $20

; ChannelTick (h = page, skipped while field $27 = 0): auto-duty, auto-pan; ticks
; left - 1, at 0 read the stream; then arpeggio, glide + note -> period, envelope,
; release check, vibrato / slide.
ChannelTick:
	ld l, $27
	ld a, [hl]
	and a
	ret z
	ld l, $31
	ld a, [hl]
	and a
	call nz, DoAutoDuty
	ld l, $2E
	ld a, [hl]
	and a
	call nz, DoAutoPan
	ld l, $02
	ld e, [hl]
	inc l
	ld d, [hl]
	ld l, $0A
	dec [hl]
	call z, ReadStream
	ld l, $04
	bit 5, [hl]
	jr z, ChannelTickArp
	ld l, $3C
	ld a, [hl]
	and a
	jr nz, PingPongCentre
	inc [hl]
	inc l
	ld a, [hl]
	and a
	jr nz, PingPongRight
	inc a
	ld [hl], a
	ld l, $38
	ld [hl], $10
	jr PingPongDone
PingPongRight:
	dec a
	ld [hl], a
	ld l, $38
	ld [hl], $01
	jr PingPongDone
PingPongCentre:
	ld l, $38
	ld [hl], $11
PingPongDone:
	ld l, $04
ChannelTickArp:
	bit 0, [hl]
	jp nz, DoArp
GlissStep:
	ld l, $3E
	ld a, [hli]
	and a
	jr z, UpdatePeriod
	bit 7, a
	jr nz, GlissUp
	sub [hl]
	jr nc, GlissStore
	xor a
GlissStore:
	dec l
	ld [hl], a
	jr UpdatePeriod
GlissUp:
	add a, [hl]
	jr nc, GlissStoreUp
	xor a
GlissStoreUp:
	dec l
	ld [hl], a

; UpdatePeriod: note += glide (field $0B, every tick); index = note + channel
; transpose ($0D, default -12) + arpeggio offset ($0E) + global transpose ($0F);
; indexes of 80 and above wrap to 0.
UpdatePeriod:
	ld l, $0B
	ld a, [hli]
	add a, [hl]
	ld [hli], a
	add a, [hl]
	inc l
	add a, [hl]
	inc l
	add a, [hl]
	ld l, $3E
	add a, [hl]
	cp $5F
	jr c, SetPeriod
	sub $5F
SetPeriod:
	add a, a
	ld c, a
	ld b, $49
	ld l, $05
	ld a, [bc]
	inc c
	ld [hli], a
	ld a, [bc]
	ld [hl], a
	call DoEnvelope
	call CheckRelease
	ld l, $04
	bit 3, [hl]
	ret z
	ld l, $21
	ld a, [hl]
	and a
	jr z, VibStep
	dec [hl]
	ret

; Vibrato / slide (flag b3): after the delay ($21), the pitch offset ($25/$26) moves
; by depth ($22) per tick, up while b4 is set and down while it is clear; the
; direction flips every speed ($24) ticks (counter $23, half a speed after a note).
VibStep:
	ld l, $04
	bit 4, [hl]
	jr z, VibDownPhase
	ld l, $23
	dec [hl]
	jr nz, VibUp
	inc l
	ld a, [hld]
	ld [hl], a
	ld l, $04
	res 4, [hl]
	ret
VibUp:
	ld l, $22
	ld a, [hl]
	ld l, $25
	add a, [hl]
	ld [hli], a
	ret nc
	inc [hl]
	ret
VibDownPhase:
	ld l, $23
	dec [hl]
	jr nz, VibDown
	inc l
	ld a, [hld]
	ld [hl], a
	ld l, $04
	set 4, [hl]
	ret
VibDown:
	ld l, $22
	ld c, [hl]
	ld l, $25
	ld a, [hl]
	sub c
	ld [hli], a
	ret nc
	dec [hl]
	ret
ArpLoop:
	ld [hl], $00

; DoArp: next arpeggio byte into field $0E; $6A (the NEXT byte) loops, $FF holds.
DoArp:
	ld l, $1D
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
	jr z, ArpLoop
	cp $FF
	jp z, GlissStep
	inc [hl]
	ld l, $0E
	ld [hl], a
	jp GlissStep

; ReadStream (de = stream). A note: store the pointer and the note, restart the
; arpeggio, ticks left = length, clear the pitch offset, restart vibrato (direction
; down unless a slide is set), re-arm the release; CH3/SFX page: split the
; envelope bytes and volume = start volume; pulse pages: NRx2 = HWENV value and
; start the 2nd-envelope timer. The note ends the read.
ReadStream:
	ld a, [wInInstr]
	and a
	jp nz, InstrLoop
ReadByte:
	ld a, [de]
	inc de
	cp $60
	jp nc, StreamCommand
NoteOn:
	ld l, $02
	ld [hl], e
	inc l
	ld [hl], d
	ld c, a
	ld l, $3F
	ld a, [hl]
	and a
	jr z, NoteOnNoGliss
	ld l, $0C
	ld a, [hl]
	sub c
	ld l, $3E
	ld [hl], a
NoteOnNoGliss:
	ld a, c
	ld l, $0C
	ld [hl], a
	xor a
	ld l, $1F
	ld [hl], a
	ld l, $3C
	ld [hl], a
	ld l, $09
	ld a, [hli]
	ld [hl], a
	xor a
	ld l, $26
	ld [hld], a
	ld [hld], a
	ld a, [hld]
	srl a
	ld [hl], a
	ld l, $20
	ld a, [hli]
	ld [hl], a
	ld l, $04
	res 4, [hl]
NoteOnRelease:
	bit 1, [hl]
	jr z, NoteOnEnvelope
	res 2, [hl]
	ld l, $17
	ld a, [hl]
	ld l, $1A
	ld [hli], a
	ld [hli], a
NoteOnEnvelope:
	ld a, h
	cp $D4
	jr c, NoteOnPulse
	call z, WaveSeqNoteOn
	ld l, $10
	ld a, [hli]
	ld c, a
	and $0F
	ld [hli], a
	ld a, c
	swap a
	and $0F
	ld [hli], a
	ld a, [hli]
	ld c, a
	and $0F
	ld [hli], a
	ld a, c
	swap a
	and $0F
	ld [hli], a
	ld a, [hl]
	ld l, $08
	ld [hl], a
	ret
NoteOnPulse:
	ld l, $2A
	ld a, [hl]
NoteOnHwEnv:
	ld l, $28
	ld [hli], a
	ld [hl], $01
	ld l, $2B
	ld a, [hli]
	ld [hl], a
	ret

; REPEAT_END: count - 1; while not 0, jump back to the REPEAT position.
Cmd_RepeatEnd:
	ld l, $39
	ld a, [hl]
	dec a
	ret z
	ld [hli], a
	ld a, [hli]
	ld e, a
	ld d, [hl]
	ret

; REPEAT n (bytes from the top of the range): play the following bytes n times
; (count field $39, position $3A/$3B; one level).
Cmd_Repeat:
	sub $F6
	ld l, $39
	ld [hli], a
	ld [hl], e
	inc l
	ld [hl], d
	jp ReadByte

; StreamCommand: REPEAT / LEN / VOLENV / ARP / INSTR ranges, else CmdTable.
StreamCommand:
	cp $F8
	jr nc, Cmd_Repeat
	cp $C8
	jr nc, Cmd_Len
	cp $B8
	jr nc, Cmd_VolEnv
	cp $A0
	jr nc, Cmd_Arp
	cp $8B
	jp nc, Cmd_Instrument
	sub $60
	add a, a
	ld c, a
	ld b, $40
	ld a, [bc]
	ld l, a
	inc c
	ld a, [bc]
	ld c, $BF
	ld b, $42
	push bc
	ld b, a
	ld c, l
CallBC:
	push bc
	ret

; LEN n: note length in ticks.
Cmd_Len:
	sub $C7
	ld l, $09
	ld [hl], a
	jp ReadStream

; VOLENV v, atk, dec, rates: start volume v; attack = lo nibble steps of hi nibble;
; decay likewise; rates hi = ticks per attack step, lo = ticks per decay step.
; Only the CH3 and SFX pages use it.
Cmd_VolEnv:
	sub $B8
	ld l, $16
	ld [hl], a
	ld a, [de]
	inc de
	ld l, $10
	ld [hl], a
	ld a, [de]
	inc de
	ld l, $13
	ld [hl], a
	ld a, [de]
	swap a
	and $0F
	ld l, $18
	ld [hli], a
	ld [hl], a
	ld a, [de]
	and $0F
	ld l, $1A
	ld [hli], a
	ld [hl], a
	ld l, $17
	ld [hl], a
	inc de
	xor a
	ld l, $11
	ld [hl], a
	jp ReadStream

; Unreferenced (39 bytes)
	db $0A, $03, $2E, $16, $77, $0A, $03, $2E, $10, $77, $0A, $03, $2E, $13, $77, $0A
	db $CB, $37, $E6, $0F, $2E, $18, $22, $77, $0A, $E6, $0F, $2E, $1A, $22, $77, $2E
	db $17, $77, $AF, $2E, $11, $77, $C9

; ARP n: arpeggio n of wArpTable.
Cmd_Arp:
	sub $A0
	add a, a
	ld c, a
	ld a, [wArpTable]
	add a, c
	ld c, a
	ld a, [wArpTableHi]
	adc a, c
	sub c
	ld b, a
	ld a, [bc]
	inc bc
	ld l, $1D
	ld [hli], a
	ld a, [bc]
	ld [hli], a
	ld [hl], $00
	ld l, $04
	set 0, [hl]
	jp ReadStream

; INSTR n: clear arpeggio, glide and arpeggio offset (auto-duty keeps running);
; pulse pages: NR11/NR21 = 50 % duty; then run macro n (entry n + 1 of
; wInstrTable) up to END with wInInstr = $C9.
Cmd_Instrument:
	push de
	ld b, a
	xor a
	ld l, $04
	res 0, [hl]
	ld l, $0B
	ld [hl], a
	ld l, $0E
	ld [hl], a
	ld l, $2E
	ld [hl], a
	ld l, $31
	ld [hl], a
	ld l, $38
	ld [hl], $11
	ld a, h
	cp $D4
	jr nc, InstrLookup
	cp $D2
	jr nz, InstrDutyCh2
	ld a, $80
	ld [wDutyCh1], a
	jr InstrLookup
InstrDutyCh2:
	ld a, $80
	ld [wDutyCh2], a
InstrLookup:
	ld a, b
	sub $8A
	add a, a
	ld c, h
	ld b, a
	ld a, [wInstrTable]
	ld l, a
	ld a, [wInstrTableHi]
	ld h, a
	ld a, b
	add a, l
	ld l, a
	adc a, h
	sub l
	ld h, a
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld h, c
	ld a, $C9
	ld [wInInstr], a
InstrLoop:
	ld a, [de]
	inc de
	cp $68
	jp nz, StreamCommand
	xor a
	ld [wInInstr], a
	pop de
	jp ReadByte

; SLIDE_UP n / SLIDE_DOWN n: as in The Smurfs, but a note on always resets the
; direction to down, so after the first note both slide down.
Cmd_SlideUp:
	xor a
	ld l, $20
	ld [hli], a
	ld [hli], a
	ld a, [de]
	inc de
	ld [hli], a
	ld a, $01
	ld [hli], a
	ld [hli], a
	ld l, $04
	ld a, [hl]
	or $18
	ld [hl], a
	ret
Cmd_SlideDown:
	xor a
	ld l, $20
	ld [hli], a
	ld [hli], a
	ld a, [de]
	inc de
	ld [hli], a
	ld a, $01
	ld [hli], a
	ld [hli], a
	ld l, $04
	ld a, [hl]
	or $18
	and $EF
	ld [hl], a
	ret

; VOL n: start volume (CH3/SFX pages).
Cmd_Vol:
	ld a, [de]
	inc de
	ld l, $16
	ld [hl], a
	ret

; CALL_CODE w: call machine code at w; it returns into the command loop.
Cmd_CallCode:
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	inc de
	ld b, a
	push bc
	ret
Cmd_ArpOff:
	ld l, $04
	res 0, [hl]
	ld l, $0E
	ld [hl], $00
	ret

; CheckRelease (RELEASE t, env; t = min length (hi) / ticks left (lo)): new early
; exit when RELEASE is off (bit 1 of $04; CheckRelease2 tests it again). Then as
; before: skipped for notes shorter than the minimum; on the tick where ticks
; left = lo nibble, unless the next byte is WAIT: pulse NRx2 = env; CH3/SFX page:
; decay rate = env & $0F and, if env >> 4 is not 0, volume = env >> 4.
CheckRelease:
	ld l, $04
	bit 1, [hl]
	ret z
	ld l, $34
	ld a, [hl]
	and $F0
	jr z, CheckRelease2
	swap a
	ld c, a
	ld l, $09
	ld a, [hl]
	cp c
	ret c
CheckRelease2:
	ld l, $04
	bit 1, [hl]
	ret z
	bit 2, [hl]
	ret nz
	ld l, $0A
	ld c, [hl]
	ld l, $34
	ld a, [hl]
	and $0F
	cp c
	ret nz
	ld a, [de]
	cp $65
	ret z
	ld l, $35
	ld a, h
	cp $D4
	jr z, ReleaseCh3
	cp $D5
	jr z, ReleaseSfx
	ld a, [hl]
	ld l, $28
	ld [hli], a
	ld [hl], $01
SetReleased:
	ld l, $04
	set 2, [hl]
	ret
ReleaseCh3:
	ld a, [hl]
	and $0F
	ld [$D41B], a
	ld [$D41A], a
	ld a, [hl]
	and $F0
	swap a
	jr z, SetReleased
	ld [$D408], a
	jr SetReleased
ReleaseSfx:
	ld a, [hl]
	and $0F
	ld [$D51B], a
	ld [$D51A], a
	ld a, [hl]
	and $F0
	swap a
	jr z, SetReleased
	ld [$D508], a
	jr SetReleased
Cmd_Release:
	ld l, $34
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
	ld l, $0D
	ld a, [de]
	add a, $F4
	ld [hl], a
	inc de
	ret
Cmd_Glide:
	ld l, $0B
	ld a, [de]
	ld [hl], a
	inc de
	ret
Cmd_GlideOff:
	ld l, $0B
	ld [hl], $00
	ret
Cmd_Vibrato:
	ld a, [de]
	inc de
	ld l, $20
	ld [hli], a
	ld [hli], a
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	inc de
	ld [hli], a
	ld [hli], a
	ld l, $04
	ld a, [hl]
	or $18
	ld [hl], a
	ret
Cmd_VibOff:
	ld l, $04
	ld a, [hl]
	and $E7
	ld [hl], a
	ret

; REST: volume 0 (pulse pages also NRx2 = 0), then wait one length.
Cmd_Rest:
	pop af
	ld l, $08
	ld [hl], $00
	ld a, h
	cp $D4
	jr nc, WaitReload
	ld l, $28
	xor a
	ld [hli], a
	inc a
	ld [hl], a
	jp WaitReload

; WAIT / WAIT2: wait one length (ends the read). The release check looks for WAIT
; only, so WAIT2 is a tie that lets the release happen.
Cmd_Wait:
	pop af
WaitReload:
	ld l, $09
	ld a, [hli]
	ld [hl], a
	ld l, $02
	ld [hl], e
	inc l
	ld [hl], d
	ret

; SndInit: NR52 = $FF, default arpeggio table, clear flags; falls into StopAll.
SndInit:
	ld a, $FF
	ldh [rNR52], a
	ld a, HIGH(ArpTable)
	ld [wArpTableHi], a
	ld a, LOW(ArpTable)
	ld [wArpTable], a
	xor a
	ld [wInInstr], a
	ld [wPaused], a
	ld [wDrumHold], a
	ld [wNoiseAtten], a

; StopAll: silence CH1-CH4, fade, drums and noise sequence off, noise pan centre,
; reset the four pages.
StopAll:
	call SndResume
	ld a, $08
	ldh [rNR10], a
	xor a
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR32], a
	ldh [rNR42], a
	ldh [rNR14], a
	ldh [rNR24], a
	ldh [rNR34], a
	ldh [rNR44], a
	ld [wFadeOn], a
	ld [wDrumsOn], a
	ld [wNoiseOn], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $77
	ldh [rNR50], a
	ld h, $D2
	call ResetChannel
	inc h
	call ResetChannel
	inc h
	call ResetChannel
	inc h
	jr ResetChannel

; END: reset the page (the channel stops).
Cmd_End:
	pop af

; ResetChannel: centre pan, inactive, volume 0, flags, auto-pan/duty off, transposes
; (channel transpose -12), glide, ticks left 1, NRx2 = 0 at the next output.
; SFX page: id 0, volume 0, noise timers, NR32 shadow $FF, reload the music wave.
ResetChannel:
	ld a, h
	cp $D5
	jr z, ResetSfxPage
ResetMusicPage:
	xor a
	ld l, $38
	ld [hl], $11
	dec l
	ld [hl], a
	ld l, $27
	ld [hl], a
	ld l, $08
	ld [hl], a
	ld l, $04
	ld [hl], a
	ld l, $31
	ld [hl], a
	ld l, $2E
	ld [hl], a
	ld l, $37
	ld [hl], a
	ld l, $3E
	ld [hli], a
	ld [hli], a
	ld l, $0F
	ld [hld], a
	ld [hld], a
	ld [hl], $F4
	dec l
	dec l
	ld [hld], a
	inc a
	ld [hl], a
	ld l, $29
	ld [hld], a
	dec a
	ld [hl], a
	ret
ResetSfxPage:
	xor a
	ld [$D527], a
	ld [$D508], a
	ld [wNoiseTimer], a
	ld [wNoiseSpeed], a
	dec a
	ld [wShNR32], a
	jp RestoreMusicWave
Cmd_Transpose:
	ld a, [de]
	ld [$D20F], a
	ld [$D30F], a
	ld [$D40F], a
	inc de
	ret
PatReturn:
	ld l, $36
	ld e, [hl]
	inc l
	ld d, [hl]
	ld [hl], $00
	ret
Cmd_PatCall:
	ld l, $36
	ld a, [de]
	inc de
	ld b, a
	ld a, [de]
	inc de
	ld [hl], e
	inc l
	ld [hl], d
	ld e, b
	ld d, a
	ret
Cmd_PatGoto:
	ld a, [de]
	inc de
	ld l, a
	ld a, [de]
	ld d, a
	ld e, l
	ret

; NEXT: return from a PAT_CALL if one is pending, else the next order-list entry;
; a 0 entry is followed by the loop position.
Cmd_Next:
	ld l, $37
	ld a, [hl]
	and a
	jr nz, PatReturn
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
	jr z, NextOrderEnd
	ld [hl], b
	dec l
	ld [hl], c
	ret
NextOrderEnd:
	ld l, $00
	ld a, [bc]
	inc bc
	ld [hli], a
	ld a, [bc]
	inc bc
	ld [hl], a
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
	ld [hl], b
	dec l
	ld [hl], c
	ret
Cmd_Length:
	ld a, [de]
	ld l, $09
	ld [hl], a
	inc de
	ret

; HWENV env, t, env2: NRx2 value at each note on (pulse pages); if t is not 0,
; NRx2 = env2 t ticks into the note. HWENV env, 0: no second value.
Cmd_HwEnv:
	ld a, [de]
	ld l, $28
	ld [hli], a
	inc l
	ld [hli], a
	inc de
	ld a, [de]
	and a
	jr z, HwEnvNoEnv2
	inc a
	ld [hli], a
	inc l
	inc de
	ld a, [de]
	inc de
	ld [hl], a
	ret
HwEnvNoEnv2:
	ld [hli], a
	ld [hl], a
	inc de
	ret
Cmd_AutoPan:
	ld a, [de]
	inc de
	ld l, $2E
	ld [hli], a
	ld [hli], a
	ld [hl], $01
	ret

; Auto-pan: every n ticks the next of centre, right, centre, left, centre.
DoAutoPan:
	ld l, $2F
	dec [hl]
	ret nz
	ld l, $2E
	ld a, [hli]
	ld [hli], a
	ld a, [hl]
	inc a
	ld [hl], a
	dec a
	jr z, Cmd_PanR
	dec a
	jr z, Cmd_PanL
	ld [hl], $01
	jp Cmd_PanR
Cmd_PanC:
	ld l, $38
	ld [hl], $11
	ret
Cmd_PanR:
	ld l, $38
	ld [hl], $01
	ret
Cmd_PanL:
	ld l, $38
	ld [hl], $10
	ret
Cmd_AutoDuty:
	ld a, h
	cp $D4
	jr z, Cmd_WaveSeq
AutoDutyStart:
	ld a, [de]
	inc de
	ld l, $31
	ld [hli], a
	ld [hli], a
	ld [hl], $01
	ret
Cmd_WaveSeq:
	ld l, $31
	ld a, $80
	ld [hli], a
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	inc de
	ld [hl], a
	ret

; Auto-duty: every n ticks the next of 50, 75, 12.5, 75, 50 %. Written to NR11 on
; the Ch1 page, NR21 on any other page.
DoAutoDuty:
	ld a, h
	cp $D4
	ret nc
	ld l, $32
	dec [hl]
	ret nz
	ld l, $31
	ld a, [hli]
	ld [hli], a
	ld a, [hl]
	inc a
	ld [hl], a
	dec a
	jr z, Cmd_Duty50
	dec a
	jr z, Cmd_Duty75
	dec a
	jr z, Cmd_Duty12
	dec a
	jr z, Cmd_Duty25
	ld [hl], $01
Cmd_Duty50:
	ld l, $80
	jr SetDuty
Cmd_Duty75:
	ld l, $C0
	jr SetDuty
Cmd_Duty12:
	ld l, $00
	jr SetDuty
Cmd_Duty25:
	ld l, $40

; SetDuty: NR11 on the Ch1 page, NR21 on any other page (also Ch3/SFX).
SetDuty:
	ld a, h
	cp $D2
	jr nz, SetDutyCh2
	ld a, l
	ld [wDutyCh1], a
	ret
SetDutyCh2:
	ld a, l
	ld [wDutyCh2], a
	ret

; StartFade (A = speed, HL = table) / FADE speed, table: one byte into NR50 every
; speed + 1 ticks; $6A loops, $FF ends, $80 pauses (DoFade). StartFade also
; reloads the music wave.
StartFade:
	ld [wFadeSpeed], a
	ld a, l
	ld [wFadeTable], a
	ld a, h
	ld [wFadeTableHi], a
	call RestoreMusicWave
	jr FadeInit
Cmd_Fade:
	ld a, [de]
	ld [wFadeSpeed], a
	inc de
	ld a, [de]
	ld [wFadeTable], a
	inc de
	ld a, [de]
	ld [wFadeTableHi], a
	inc de
FadeInit:
	xor a
	ld [wFadePos], a
	ld [wFadeTimer], a
	inc a
	ld [wFadeOn], a
	ret
FadeEndPause:
	call SndPause
FadeStop:
	xor a
	ld [wFadeOn], a
	ret

; DoFade: a $80 byte in the table pauses the driver (SndPause) and ends the fade.
; No NR50 = $77 forcing in this version.
DoFade:
	ld a, [wFadeOn]
	and a
	jr nz, FadeRun
	ret
FadeRun:
	ld a, [wFadeTimer]
	and a
	jr z, FadeStep
	dec a
	ld [wFadeTimer], a
	ret
FadeStep:
	ld hl, wFadeTable
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [wFadePos]
	add a, l
	ld l, a
	adc a, h
	sub l
	ld h, a
	ld a, [hl]
	cp $6A
	jr z, FadeLoop
	cp $FF
	jr z, FadeStop
	cp $80
	jr z, FadeEndPause
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
WaveNoSeq:
	ld a, h
	cp $D4
	jr nz, LoadWave
SetMusicWave:
	ld a, [de]
	inc de
	ld [wMusicWave], a
	ld a, [de]
	ld [wMusicWaveHi], a
	ld a, [$D527]
	and a
	jr z, WaveRewind
	inc de
	ret
WaveRewind:
	dec de

; LoadWave: NR30 = 0, copy 16 bytes, NR30 = NR34 = Ch3 period-hi shadow | $80.
LoadWave:
	ld b, h
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
	ld h, b
	ld l, $07
	ld a, [hl]
	or $80
	ldh [rNR30], a
	ldh [rNR34], a
	ret

; RestoreMusicWave: reload the music wave; unless paused, NR30 = NR34 = $80.
RestoreMusicWave:
	ld hl, wMusicWave
	ld a, [hli]
	ld h, [hl]
	ld l, a
	xor a
	ldh [rNR30], a
	ld c, $30
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
	ld a, [wPaused]
	and a
	ret nz
	xor a
	ldh [rNR31], a
	ld a, [$D405]
	ldh [rNR33], a
	ld a, $80
	ld [$D407], a
	ldh [rNR30], a
	ldh [rNR34], a
	ret

; Unreferenced (243 bytes)
	db $6F, $00, $6E, $00, $20, $00, $4D, $00, $75, $00, $73, $00, $69, $00, $63, $00
	db $20, $00, $31, $00, $36, $00, $30, $00, $78, $00, $31, $00, $32, $00, $30, $00
	db $00, $00, $03, $00, $00, $00, $FF, $FF, $FF, $FF, $0B, $00, $48, $01, $44, $65
	db $73, $63, $72, $69, $70, $74, $69, $6F, $6E, $43, $00, $6F, $00, $6E, $00, $76
	db $00, $65, $00, $72, $00, $74, $00, $20, $00, $76, $00, $69, $00, $64, $00, $65
	db $00, $6F, $00, $20, $00, $2B, $00, $20, $00, $61, $00, $75, $00, $64, $00, $69
	db $00, $6F, $00, $20, $00, $68, $00, $69, $00, $67, $00, $68, $00, $20, $00, $6D
	db $00, $6F, $00, $74, $00, $69, $00, $6F, $00, $6E, $00, $20, $00, $77, $00, $69
	db $00, $74, $00, $68, $00, $20, $00, $6D, $00, $75, $00, $73, $00, $69, $00, $63
	db $00, $20, $00, $74, $00, $6F, $00, $20, $00, $4D, $00, $69, $00, $63, $00, $72
	db $00, $6F, $00, $73, $00, $6F, $00, $66, $00, $74, $00, $20, $00, $57, $00, $69
	db $00, $6E, $00, $64, $00, $6F, $00, $77, $00, $73, $00, $20, $00, $4D, $00, $65
	db $00, $64, $00, $69, $00, $61, $00, $20, $00, $66, $00, $6F, $00, $72, $00, $6D
	db $00, $61, $00, $74, $00, $20, $00, $28, $00, $2E, $00, $61, $00, $73, $00, $66
	db $00, $29, $00, $20, $00, $66, $00, $6F, $00, $72, $00, $20, $00, $73, $00, $74
	db $00, $72, $00
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

; DoEnvelope: pulse pages: count down to the 2nd hardware envelope value.
; CH3/SFX page: software envelope, attack then decay.
DoEnvelope:
	ld a, h
	cp $D4
	jr nc, SoftEnvelope
	ld l, $2C
	ld a, [hl]
	and a
	ret z
	dec [hl]
	ret nz
	ld l, $2D
	ld a, [hl]
	ld l, $28
	ld [hli], a
	ld [hl], $01
	ret
SoftEnvelope:
	ld l, $11
	ld a, [hl]
	and a
	jr z, EnvDecay
	ld l, $18
	dec [hl]
	ret nz
	inc l
	ld a, [hld]
	ld [hl], a
	ld l, $11
	dec [hl]
	inc l
	ld a, [hl]
	ld l, $08
	add a, [hl]
	cp $0F
	jr c, StoreVol
	ld a, $0F
StoreVol:
	ld [hl], a
	ret
EnvDecay:
	ld l, $14
	ld a, [hl]
	and a
	ret z
	ld l, $1A
	dec [hl]
	ret nz
	inc l
	ld a, [hld]
	ld [hl], a
	ld l, $14
	dec [hl]
	ld l, $08
	ld a, [hl]
	ld l, $15
	sub [hl]
	jr nc, StoreVol2
	xor a
StoreVol2:
	ld l, $08
	ld [hl], a
	ret
L49F0:
	ld h, $D2
	jr L4A01
L49F4:
	ld h, $D3
	jr L4A01
L49F8:
	ld h, $D4
	xor a
	ld [wFadeOn], a
	ld [wDrumsOn], a
L4A01:
	call ResetChannel
	ld l, $27
	ld [hl], $01
	ld l, $02
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	inc de
	ld [hl], a
	ld l, $00
	ld [hl], e
	inc l
	ld [hl], d
	ret

; PlaySfx (A = id): no priority test; reset the SFX page and start the stream.
PlaySfx:
	ld c, a
	cp $06
	jr nc, PlaySfxStart
	ld a, [$D527]
	cp $06
	ret nc
	ld a, c
PlaySfxStart:
	ld [$D527], a
	ld a, $11
	ld [$D538], a
	xor a
	ld [$D504], a
	ld [$D50B], a
	ld [$D531], a
	ld [$D52E], a
	ld [$D50E], a
	ld [$D50F], a
	inc a
	ld [$D50A], a
	ld a, $F4
	ld [$D50D], a
	ld a, c
	ld de, $D502
	add a, a
	add a, $E8
	ld l, a
	adc a, $74
	sub l
	ld h, a
	ld a, [hli]
	ld [de], a
	inc de
	ld a, l
	ld l, e
	ld e, a
	ld a, h
	ld h, d
	ld d, a
	ld a, [de]
	ld [hl], a
	ret

; Fade the music out / in (A = speed).
SongFadeOut:
	ld hl, FadeOutTable
	jp StartFade
SongFadeIn:
	push af
	call SndResume
	pop af
	ld hl, FadeInTable
	jp StartFade
Cmd_DrumsOff:
	xor a
	ld [wDrumsOn], a
	ret

; DRUMS t, pattern: one drum step every t ticks.
Cmd_Drums:
	ld a, [de]
	and a
	jr nz, DrumsTempoSet
	ld a, $06
DrumsTempoSet:
	ld [wDrumTempo], a
	inc de
	ld a, [de]
	ld [wDrumPat], a
	inc de
	ld a, [de]
	ld [wDrumPatHi], a
	inc de
	xor a
	ld [wDrumPos], a
	ld [wNoiseAtten], a
	ld [wNoiseTimer], a
	ld [wNoiseSpeed], a
	ld [wNoisePingPong], a
	inc a
	ld [wDrumsOn], a
	ld [wDrumTimer], a
NoisePanCentre:
	ld a, $88
	ld [wNoisePan], a
	ret

; DrumStep: read pattern bytes until a 0 or a drum sound: $FF restart; $32/$33/$34
; noise pan C/R/L; $35 n noise auto-pan; $36 repeat end; $37-$46 noise level;
; $47-$5A noise speed; then a repeat-start range and a tempo range (see the doc);
; $01-$31 = drum sound n (skipped while wDrumHold runs).
DrumStep:
	ld a, [wDrumsOn]
	and a
	ret z
	ld a, [wDrumTempo]
	ld [wDrumTimer], a
DrumRead:
	ld a, [wDrumPos]
DrumReadAt:
	ld e, a
	inc a
	ld [wDrumPos], a
	ld a, [wDrumPat]
	add a, e
	ld l, a
	ld a, [wDrumPatHi]
	adc a, $00
	ld h, a
DrumByte:
	ld a, [hli]
	and a
	ret z
	cp $FF
	jr z, DrumLoop
	cp $32
	jr z, DrumPanC
	cp $33
	jr z, DrumPanR
	cp $34
	jr z, DrumPanL
	cp $36
	jr z, DrumPingPongOff
	cp $35
	jr z, DrumPingPong
	cp $37
	jr z, DrumRepeatEnd
	cp $C8
	jr nc, DrumTempo
	cp $5C
	jr nc, DrumRepeat
	cp $48
	jr nc, DrumNoiseSpeed
	cp $38
	jr nc, DrumAtten
	ld e, a
	ld a, [wDrumHold]
	and a
	ret nz
	ld a, e
	add a, a
	add a, $7B
	ld l, a
	adc a, $4B
	sub l
	ld h, a
	ld a, [hli]
	ld h, [hl]

; Drum sound table (indexed from 2 bytes before; drum 1 is the first entry).
DrumTable_m2:
	ld l, a
	jp hl
DrumTempo:
	sub $C7
	ld [wDrumTempo], a
	ld [wDrumTimer], a
	jr DrumNextByte
DrumLoop:
	xor a
	ld [wDrumPos], a
	jr DrumRead
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
DrumPingPongOff:
	xor a
	ld [wNoisePingPong], a
	jr DrumNextByte
DrumNoiseSpeed:
	sub $48
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	jr DrumNextByte
DrumPingPong:
	ld a, $01
	ld [wNoisePingPong], a
	jr DrumNextByte
DrumRepeatEnd:
	ld a, [wDrumLoopCount]
	dec a
	jr z, DrumNextByte
	ld [wDrumLoopCount], a
	ld a, [wDrumLoopPos]
	jp DrumReadAt
DrumRepeat:
	sub $5B
	ld [wDrumLoopCount], a
	ld a, [wDrumPos]
	ld [wDrumLoopPos], a
	jr DrumNextByte
DrumAtten:
	sub $38
	ld c, a
	ld a, $0F
	sub c
	ld [wNoiseAtten], a
DrumNextByte:
	ld a, [wDrumPos]
	inc a
	ld [wDrumPos], a
	jp DrumByte
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
	dw Drum13
	dw Drum13
	dw Drum13
	dw Drum14

; DrumTick: wDrumHold counts down; drum timer; then one noise-sequence step every
; speed + 1 ticks: NR43 = seq43[i]; with an NR42 table NR42 = seq42[i] - level
; (not while held; $FF = no write) and NR44 = $80; $FF in the NR43 table ends.
; Auto-pan of the noise from the step count.
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
	ld a, [wNoise43Hi]
	ld h, a
	ld a, [wNoise43]
	ld l, a
	ld a, [wNoisePos]
	ld e, a
	inc a
	ld [wNoisePos], a
	ld d, $00
	add hl, de
	ld a, [hl]
	cp $FF
	jr z, NoiseSeqEnd
	ldh [rNR43], a
	ld a, [wNoise42Hi]
	and a
	jr z, NoisePingPong
	ld h, a
	ld a, [wNoise42]
	ld l, a
	add hl, de
	ld c, $00
	ld a, [wDrumHold]
	and a
	jr nz, NoiseWriteNR42
	ld a, [wNoiseAtten]
	ld c, a
NoiseWriteNR42:
	ld a, [hl]
	cp $FF
	jr z, NoisePingPong
	swap c
	sub c
	jr nc, NoiseNR42
	and $0F
NoiseNR42:
	ldh [rNR42], a
	xor a
	ldh [rNR41], a
	ld a, $80
	ldh [rNR44], a
NoisePingPong:
	ld a, [wDrumHold]
	and a
	ret nz
	ld a, [wNoisePingPong]
	and a
	ld b, a
	ret z
	ld a, [wNoisePos]
	dec a
	jr nz, NoisePingPongCentre
	bit 7, b
	jr z, NoisePingPongRight
	ld a, $01
	ld [wNoisePingPong], a
	ld a, $80
	ld [wNoisePan], a
	ret
NoisePingPongRight:
	ld a, $81
	ld [wNoisePingPong], a
	ld a, $08
	ld [wNoisePan], a
	ret
NoisePingPongCentre:
	ld a, $88
	ld [wNoisePan], a
	ret

; Unreferenced (14 bytes)
	db $78, $3D, $28, $E0, $EA, $4B, $D2, $3E, $08, $EA, $43, $D2, $C9, $C9
NoiseSeqEnd:
	xor a
	ld [wNoisePos], a
	ld [wNoiseOn], a
	ret
WaveSeqNoteOn:
	ld l, $31
	ld a, [hl]
	and a
	ret z
	push de
	and $7F
WaveSeqRead:
	ld l, $32
	ld e, [hl]
	inc l
	ld d, [hl]
	add a, a
	add a, e
	ld e, a
	jr nc, WaveSeqEntry
	inc d
WaveSeqEntry:
	ld a, [de]
	ld l, a
	inc de
	ld a, [de]
	or l
	jr nz, WaveSeqLoad
	ld a, $80
	ld l, $31
	ld [hl], a
	jr WaveSeqRead
WaveSeqLoad:
	dec de
	call SetMusicWave
	ld l, $31
	inc [hl]
	pop de
	ret
DriverCreditText:
	db "(Music & Sound Driver by Alberto Jose Gonzalez, 1999)"

; Song 1: instrument table 2, arpeggio table 1 (the one SndInit sets)
PlaySong1:
	call StopAll
	ld de, Song1_Ch3
	call L49F8
	ld de, Song1_Ch2
	call L49F4
	ld de, Song1_Ch1
	call L49F0
	ld a, $73
	ld [wInstrTableHi], a
	ld a, $1B
	ld [wInstrTable], a
	ret
Song1_Ch3:
	dw Pat_4CFD
	dw Pat_4D31
	dw Pat_4CFD
	dw Pat_4D89
	dw Pat_4DD5
	dw Pat_4E2E
	ORDER_LOOP Song1_Ch3
Song1_Ch2:
	dw Pat_4E87
	dw Pat_4EAE
	dw Pat_4E87
	dw Pat_4EE0
	dw Pat_4F0F
	dw Pat_4F46
	ORDER_LOOP Song1_Ch2
Song1_Ch1:
	dw Pat_4F7B
	dw Pat_4FA5
	dw Pat_4F7B
	dw Pat_4FDA
	dw Pat_5009
	dw Pat_5034
	ORDER_LOOP Song1_Ch1
Pat_4CFD:
	DRUMS $07, DrumPat_5063
	REPEAT 2
	INSTR 12
	LEN 14
	NOTE D_, 2
	INSTR 11
	LEN 7
	NOTE D_, 3
	INSTR 4
	LEN 14
	NOTE D_, 4
	INSTR 12
	LEN 7
	NOTE D_, 2
	LEN 14
	NOTE A_, 2
	INSTR 11
	LEN 7
	NOTE A_, 3
	INSTR 4
	LEN 14
	NOTE D_, 4
	INSTR 12
	LEN 7
	NOTE A_, 2
	LEN 14
	NOTE Ash, 2
	INSTR 11
	LEN 7
	NOTE Ash, 3
	INSTR 4
	LEN 14
	NOTE Ash, 4
	INSTR 12
	LEN 7
	NOTE Ash, 2
	LEN 14
	NOTE C_, 3
	INSTR 11
	LEN 7
	NOTE C_, 4
	INSTR 4
	LEN 14
	NOTE C_, 5
	INSTR 12
	LEN 7
	NOTE C_, 3
	REPEAT_END
	NEXT
Pat_4D31:
	INSTR 12
	LEN 14
	NOTE D_, 2
	INSTR 11
	LEN 7
	NOTE D_, 3
	INSTR 4
	LEN 14
	NOTE D_, 4
	INSTR 12
	LEN 7
	NOTE D_, 2
	LEN 14
	NOTE A_, 2
	INSTR 11
	LEN 7
	NOTE A_, 3
	INSTR 4
	LEN 14
	NOTE D_, 4
	INSTR 12
	LEN 7
	NOTE A_, 2
	LEN 14
	NOTE G_, 2
	INSTR 11
	LEN 7
	NOTE G_, 3
	INSTR 4
	LEN 14
	NOTE G_, 4
	INSTR 12
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE A_, 2
	INSTR 4
	LEN 7
	NOTE A_, 4
	INSTR 12
	LEN 14
	NOTE A_, 2
	INSTR 4
	LEN 7
	NOTE A_, 4
	INSTR 12
	LEN 14
	NOTE D_, 2
	INSTR 11
	LEN 7
	NOTE D_, 3
	INSTR 4
	LEN 14
	NOTE D_, 4
	INSTR 12
	LEN 7
	NOTE D_, 2
	LEN 14
	NOTE Fsh, 2
	INSTR 11
	LEN 7
	NOTE Fsh, 3
	INSTR 4
	LEN 14
	NOTE D_, 4
	INSTR 12
	LEN 7
	NOTE Fsh, 2
	LEN 14
	NOTE G_, 2
	INSTR 11
	LEN 7
	NOTE G_, 3
	INSTR 4
	LEN 14
	NOTE G_, 4
	INSTR 12
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE A_, 2
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE Fsh, 2
	LEN 7
	NOTE E_, 2
	NEXT
Pat_4D89:
	INSTR 12
	LEN 14
	NOTE D_, 2
	INSTR 11
	LEN 7
	NOTE D_, 3
	INSTR 4
	LEN 14
	NOTE D_, 4
	INSTR 12
	LEN 7
	NOTE D_, 2
	LEN 14
	NOTE A_, 2
	INSTR 11
	LEN 7
	NOTE A_, 3
	INSTR 4
	LEN 14
	NOTE D_, 4
	INSTR 12
	LEN 7
	NOTE A_, 2
	LEN 14
	NOTE G_, 2
	INSTR 11
	LEN 7
	NOTE G_, 3
	INSTR 4
	LEN 14
	NOTE G_, 4
	INSTR 12
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE A_, 2
	INSTR 11
	LEN 7
	NOTE A_, 3
	INSTR 4
	LEN 14
	NOTE A_, 4
	INSTR 12
	LEN 7
	NOTE A_, 2
	LEN 14
	NOTE D_, 2
	INSTR 11
	LEN 7
	NOTE D_, 3
	INSTR 4
	LEN 14
	NOTE D_, 4
	INSTR 12
	LEN 7
	NOTE D_, 2
	LEN 14
	NOTE G_, 2
	INSTR 11
	LEN 7
	NOTE G_, 3
	INSTR 4
	LEN 14
	NOTE G_, 4
	INSTR 12
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE D_, 2
	LEN 7
	NOTE D_, 3
	LEN 21
	NOTE C_, 3
	NOTE B_, 2
	NOTE A_, 2
	NEXT
Pat_4DD5:
	INSTR 12
	LEN 14
	NOTE G_, 2
	INSTR 11
	LEN 7
	NOTE G_, 3
	INSTR 4
	LEN 14
	NOTE G_, 3
	INSTR 12
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE D_, 2
	INSTR 11
	LEN 7
	NOTE D_, 3
	INSTR 4
	LEN 14
	NOTE G_, 3
	INSTR 12
	LEN 7
	NOTE D_, 2
	LEN 14
	NOTE G_, 2
	INSTR 11
	LEN 7
	NOTE G_, 3
	INSTR 4
	LEN 14
	NOTE G_, 3
	INSTR 12
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE D_, 2
	INSTR 11
	LEN 7
	NOTE D_, 3
	INSTR 4
	LEN 14
	NOTE G_, 3
	INSTR 12
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE D_, 3
	INSTR 11
	LEN 7
	NOTE D_, 4
	INSTR 4
	LEN 14
	NOTE D_, 4
	INSTR 12
	LEN 7
	NOTE D_, 3
	LEN 14
	NOTE A_, 2
	INSTR 11
	LEN 7
	NOTE A_, 3
	INSTR 4
	LEN 14
	NOTE D_, 4
	INSTR 12
	LEN 7
	NOTE A_, 2
	LEN 14
	NOTE D_, 3
	LEN 7
	NOTE D_, 3
	LEN 14
	NOTE C_, 3
	INSTR 11
	LEN 7
	NOTE C_, 4
	INSTR 12
	LEN 14
	NOTE B_, 2
	INSTR 11
	LEN 7
	NOTE B_, 3
	INSTR 12
	LEN 14
	NOTE A_, 2
	INSTR 11
	LEN 7
	NOTE A_, 3
	NEXT
Pat_4E2E:
	INSTR 12
	LEN 14
	NOTE G_, 2
	INSTR 11
	LEN 7
	NOTE G_, 3
	INSTR 4
	LEN 14
	NOTE G_, 4
	INSTR 12
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE D_, 2
	INSTR 11
	LEN 7
	NOTE D_, 3
	INSTR 4
	LEN 14
	NOTE G_, 4
	INSTR 12
	LEN 7
	NOTE D_, 2
	LEN 14
	NOTE G_, 2
	INSTR 11
	LEN 7
	NOTE G_, 3
	INSTR 4
	LEN 14
	NOTE G_, 4
	INSTR 12
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE D_, 2
	INSTR 11
	LEN 7
	NOTE D_, 3
	INSTR 4
	LEN 14
	NOTE G_, 4
	INSTR 12
	LEN 7
	NOTE E_, 2
	LEN 14
	NOTE A_, 2
	INSTR 11
	LEN 7
	NOTE A_, 3
	INSTR 4
	LEN 14
	NOTE A_, 4
	INSTR 12
	LEN 7
	NOTE A_, 2
	LEN 14
	NOTE B_, 2
	INSTR 11
	LEN 7
	NOTE B_, 3
	INSTR 4
	LEN 14
	NOTE A_, 4
	INSTR 12
	LEN 7
	NOTE B_, 2
	LEN 14
	NOTE C_, 3
	INSTR 11
	LEN 7
	NOTE C_, 4
	INSTR 4
	LEN 14
	NOTE A_, 4
	INSTR 12
	LEN 7
	NOTE C_, 3
	LEN 14
	NOTE Csh, 3
	INSTR 4
	LEN 7
	NOTE A_, 4
	INSTR 12
	LEN 14
	NOTE B_, 2
	LEN 7
	NOTE A_, 2
	NEXT
Pat_4E87:
	VIBRATO $07, $01, $04
	PINGPONG
	INSTR 13
	LEN 21
	NOTE D_, 3
	GLISS_3
	NOTE D_, 4
	LEN 35
	NOTE A_, 3
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE G_, 4
	LEN 21
	NOTE A_, 4
	NOTE G_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 21
	NOTE E_, 4
	NOTE D_, 3
	NOTE D_, 4
	LEN 35
	NOTE A_, 3
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE G_, 4
	LEN 21
	NOTE A_, 4
	NOTE G_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 21
	NOTE E_, 4
	NEXT
Pat_4EAE:
	INSTR 13
	LEN 21
	NOTE Fsh, 4
	NOTE A_, 4
	LEN 35
	NOTE D_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE E_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE G_, 4
	LEN 21
	NOTE Csh, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE E_, 4
	LEN 21
	NOTE Fsh, 4
	INSTR 9
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE Fsh, 4
	LEN 7
	NOTE A_, 4
	INSTR 13
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE B_, 4
	LEN 21
	NOTE Csh, 5
	NOTE Csh, 4
	LEN 7
	NOTE A_, 3
	NEXT
Pat_4EE0:
	INSTR 13
	LEN 21
	NOTE Fsh, 4
	NOTE A_, 4
	LEN 35
	NOTE D_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE E_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE G_, 4
	LEN 21
	NOTE Csh, 4
	LEN 7
	NOTE D_, 4
	LEN 21
	NOTE E_, 4
	LEN 14
	NOTE D_, 4
	INSTR 9
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE E_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE Csh, 5
	LEN 14
	NOTE D_, 5
	INSTR 6
	LEN 7
	NOTE D_, 5
	LEN 21
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NEXT
Pat_4F0F:
	GLISS_OFF
	LEN 14
	REST
	INSTR 6
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE B_, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE B_, 3
	LEN 21
	NOTE C_, 4
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE B_, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE B_, 3
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE Csh, 4
	LEN 21
	NOTE D_, 4
	INSTR 9
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE Fsh, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE A_, 4
	INSTR 6
	LEN 14
	NOTE Fsh, 4
	LEN 21
	NOTE Fsh, 4
	LEN 7
	NOTE Fsh, 4
	LEN 21
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NEXT
Pat_4F46:
	LEN 14
	WAIT
	INSTR 6
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE B_, 4
	LEN 21
	NOTE C_, 5
	LEN 7
	NOTE B_, 4
	LEN 14
	NOTE D_, 5
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE Csh, 5
	LEN 14
	NOTE D_, 5
	LEN 21
	NOTE Csh, 5
	NOTE A_, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE B_, 3
	LEN 21
	NOTE A_, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE C_, 4
	LEN 21
	NOTE A_, 4
	NOTE Csh, 4
	INSTR 13
	LEN 7
	NOTE A_, 3
	LEN 14
	NOTE B_, 3
	LEN 7
	NOTE A_, 3
	NEXT
Pat_4F7B:
	VIBRATO $07, $01, $04
	PINGPONG
	INSTR 6
	LEN 21
	NOTE D_, 5
	NOTE D_, 6
	LEN 35
	NOTE A_, 5
	LEN 7
	ARP 11
	NOTE A_, 5
	LEN 14
	NOTE Ash, 5
	LEN 21
	NOTE C_, 6
	NOTE Ash, 5
	LEN 7
	NOTE A_, 5
	LEN 21
	NOTE G_, 5
	ARP_OFF
	DUTY_50
	NOTE D_, 5
	NOTE D_, 6
	LEN 35
	NOTE A_, 5
	ARP 11
	LEN 7
	NOTE A_, 5
	LEN 14
	NOTE Ash, 5
	LEN 21
	NOTE C_, 6
	NOTE Ash, 5
	LEN 7
	NOTE A_, 5
	LEN 21
	NOTE G_, 5
	NEXT
Pat_4FA5:
	INSTR 6
	LEN 21
	NOTE Fsh, 5
	NOTE A_, 5
	LEN 35
	NOTE D_, 5
	LEN 7
	NOTE Fsh, 5
	LEN 14
	NOTE E_, 5
	LEN 7
	NOTE Fsh, 5
	LEN 14
	NOTE G_, 5
	LEN 21
	NOTE Csh, 5
	LEN 7
	NOTE D_, 5
	LEN 14
	NOTE E_, 5
	LEN 21
	NOTE Fsh, 5
	INSTR 9
	LEN 7
	NOTE Fsh, 3
	LEN 14
	NOTE A_, 3
	LEN 7
	NOTE Fsh, 3
	LEN 14
	NOTE B_, 3
	LEN 7
	NOTE A_, 3
	LEN 14
	NOTE Fsh, 3
	LEN 7
	NOTE A_, 3
	INSTR 6
	LEN 14
	NOTE E_, 5
	LEN 7
	NOTE Fsh, 5
	LEN 14
	NOTE G_, 5
	LEN 21
	NOTE A_, 5
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE A_, 5
	LEN 7
	NOTE A_, 4
	NEXT
Pat_4FDA:
	INSTR 6
	LEN 21
	NOTE Fsh, 5
	NOTE A_, 5
	LEN 35
	NOTE D_, 5
	LEN 7
	NOTE Fsh, 5
	LEN 14
	NOTE E_, 5
	LEN 7
	NOTE Fsh, 5
	LEN 14
	NOTE G_, 5
	LEN 21
	NOTE Csh, 5
	LEN 7
	NOTE D_, 5
	LEN 21
	NOTE E_, 5
	LEN 14
	NOTE D_, 5
	INSTR 9
	LEN 7
	NOTE D_, 3
	LEN 14
	NOTE E_, 3
	LEN 7
	NOTE Fsh, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE A_, 3
	LEN 14
	NOTE B_, 3
	LEN 7
	NOTE Csh, 4
	LEN 14
	NOTE D_, 4
	INSTR 6
	LEN 7
	NOTE D_, 4
	LEN 21
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	NEXT
Pat_5009:
	INSTR 6
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE D_, 4
	LEN 21
	NOTE E_, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE F_, 4
	LENGTH $46
	NOTE Fsh, 4
	LEN 14
	NOTE A_, 4
	LEN 21
	NOTE D_, 5
	LEN 7
	NOTE D_, 5
	LEN 21
	NOTE C_, 5
	NOTE A_, 4
	NOTE Fsh, 4
	NEXT
Pat_5034:
	INSTR 6
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE B_, 4
	LEN 14
	NOTE D_, 5
	LEN 7
	NOTE B_, 4
	LEN 14
	NOTE D_, 5
	LEN 21
	NOTE E_, 5
	LEN 7
	NOTE D_, 5
	LEN 14
	NOTE F_, 5
	LEN 7
	NOTE E_, 5
	LEN 14
	NOTE D_, 5
	LEN 7
	NOTE B_, 4
	LEN 14
	NOTE D_, 5
	LEN 7
	NOTE E_, 5
	LEN 14
	NOTE Fsh, 5
	LEN 28
	NOTE E_, 5
	LEN 21
	NOTE A_, 3
	NOTE B_, 4
	NOTE A_, 3
	NOTE C_, 5
	LEN 14
	NOTE A_, 3
	LEN 21
	NOTE Csh, 5
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE A_, 4
	NEXT
DrumPat_5063:
	db 7, 0, 0, 2, 0, 6, DRUM_REPEAT + 6, 1
	db 0, 6, 2, 0, 6, DRUM_REPEAT_END, 1, 0
	db 6, 2, 0, 2, DRUM_REPEAT + 7, 1, 0, 6
	db 2, 0, 6, DRUM_REPEAT_END, 1, 0, 2, 2
	db 0, 2, DRUM_LOOP

; Song 2: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong2:
	ld a, $52
	ld [wInstrTableHi], a
	ld a, $21
	ld [wInstrTable], a
	ld de, Song2_Ch3
	call L49F8
	ld de, Song2_Ch2
	call L49F4
	ld de, Song2_Ch1
	jp L49F0
Song2_Ch3:
	dw Pat_50A8
Song2_Ch2:
	dw Pat_5114
Song2_Ch1:
	dw Pat_51A5
Pat_50A8:
	CH_TRANSPOSE $0C
	INSTR 3
	LEN 12
	NOTE Csh, 3
	INSTR 0
	NOTE Csh, 4
	INSTR 3
	NOTE Gsh, 2
	INSTR 0
	NOTE Csh, 4
	INSTR 3
	NOTE Csh, 3
	NOTE C_, 3
	NOTE Ash, 2
	NOTE Gsh, 2
	NOTE A_, 2
	INSTR 0
	NOTE A_, 3
	INSTR 3
	NOTE E_, 2
	INSTR 0
	NOTE A_, 3
	INSTR 3
	NOTE A_, 2
	NOTE Gsh, 2
	NOTE Fsh, 2
	NOTE E_, 2
	WAIT2
	LEN 24
	NOTE F_, 2
	NOTE F_, 2
	LEN 12
	NOTE C_, 2
	LEN 36
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	LEN 24
	NOTE F_, 2
	NOTE Gsh, 2
	WAVE Wave_7D97
	VOLENV 15, $11, $11, $11
	ARP_OFF
	RELEASE $03, $51
	VIBRATO $0C, $01, $04
	LEN 6
	NOTE Csh, 6
	NOTE Csh, 6
	NOTE C_, 6
	WAIT2
	NOTE Ash, 5
	WAIT2
	NOTE Gsh, 5
	WAIT2
	LEN 30
	NOTE F_, 5
	LEN 6
	WAIT2
	NOTE Gsh, 5
	WAIT2
	NOTE Csh, 6
	NOTE Csh, 6
	NOTE C_, 6
	WAIT2
	NOTE Ash, 5
	WAIT2
	NOTE B_, 5
	WAIT2
	LEN 36
	NOTE C_, 6
	LEN 12
	WAIT2
	RELEASE $00
	INSTR 4
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Dsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Dsh, 2
	INSTR 3
	NOTE F_, 2
	NOTE Gsh, 2
	NOTE A_, 2
	NOTE Ash, 2
	NOTE C_, 3
	LEN 18
	NOTE Csh, 2
	LEN 6
	NOTE Csh, 3
	LEN 24
	WAIT2
	END
Pat_5114:
	INSTR 5
	LEN 6
	NOTE Csh, 4
	LEN 18
	WAIT2
	LEN 6
	NOTE Gsh, 3
	LEN 18
	WAIT2
	LEN 6
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE C_, 4
	WAIT2
	NOTE Ash, 3
	WAIT2
	NOTE Gsh, 3
	WAIT2
	NOTE A_, 3
	LEN 18
	WAIT2
	LEN 6
	NOTE E_, 3
	LEN 18
	WAIT2
	LEN 6
	NOTE A_, 3
	NOTE A_, 3
	NOTE Gsh, 3
	WAIT2
	NOTE Fsh, 3
	WAIT2
	NOTE E_, 3
	LEN 18
	WAIT2
	LEN 6
	NOTE A_, 4
	LEN 18
	WAIT2
	LEN 6
	NOTE A_, 4
	LEN 18
	WAIT2
	LEN 6
	NOTE Ash, 4
	WAIT2
	NOTE Ash, 4
	LEN 30
	WAIT2
	LEN 6
	NOTE Ash, 4
	LEN 18
	WAIT2
	LEN 6
	NOTE Ash, 4
	WAIT2
	NOTE A_, 4
	LEN 18
	WAIT2
	INSTR 1
	LEN 24
	NOTE Gsh, 4
	INSTR 5
	LEN 6
	NOTE Csh, 4
	NOTE Csh, 4
	INSTR 2
	LEN 12
	NOTE C_, 5
	INSTR 5
	NOTE Ash, 3
	INSTR 2
	NOTE C_, 5
	INSTR 5
	NOTE F_, 3
	INSTR 2
	NOTE C_, 5
	NOTE C_, 5
	INSTR 5
	NOTE Gsh, 3
	NOTE Csh, 4
	INSTR 2
	NOTE C_, 5
	INSTR 5
	NOTE Ash, 3
	INSTR 2
	NOTE C_, 5
	INSTR 5
	NOTE C_, 4
	INSTR 2
	NOTE B_, 4
	NOTE B_, 4
	INSTR 5
	LEN 6
	NOTE C_, 6
	WAIT2
	HWENV $A2, $00
	RELEASE $00
	LEN 3
	NOTE Ash, 5
	NOTE C_, 6
	LEN 6
	WAIT2
	NOTE Gsh, 5
	WAIT2
	LEN 3
	NOTE Gsh, 5
	NOTE Ash, 5
	LEN 6
	WAIT2
	NOTE Gsh, 5
	WAIT2
	LEN 3
	NOTE Ash, 5
	NOTE C_, 6
	LEN 6
	WAIT2
	NOTE Gsh, 5
	WAIT2
	LEN 3
	NOTE Gsh, 5
	NOTE Ash, 5
	LEN 6
	WAIT2
	NOTE F_, 4
	WAIT2
	INSTR 5
	NOTE Gsh, 4
	WAIT2
	NOTE A_, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE C_, 5
	WAIT2
	LEN 18
	NOTE Csh, 5
	LEN 6
	NOTE Gsh, 5
	LEN 24
	WAIT2
	END
Pat_51A5:
	INSTR 5
	LEN 6
	NOTE Csh, 6
	NOTE Csh, 6
	NOTE C_, 6
	WAIT2
	NOTE Ash, 5
	WAIT2
	NOTE Gsh, 5
	WAIT2
	LEN 30
	NOTE F_, 5
	LEN 6
	WAIT2
	NOTE Gsh, 5
	WAIT2
	NOTE A_, 5
	NOTE A_, 5
	NOTE Gsh, 5
	WAIT2
	NOTE Fsh, 5
	WAIT2
	NOTE E_, 5
	WAIT2
	LEN 42
	NOTE Csh, 5
	LEN 6
	WAIT2
	INSTR 1
	LEN 12
	NOTE F_, 5
	INSTR 5
	LEN 6
	NOTE C_, 5
	WAIT2
	INSTR 1
	LEN 12
	NOTE D_, 5
	INSTR 5
	LEN 6
	NOTE C_, 5
	WAIT2
	INSTR 1
	LEN 12
	NOTE C_, 5
	INSTR 5
	LEN 6
	NOTE C_, 5
	WAIT2
	NOTE C_, 5
	LEN 18
	WAIT2
	INSTR 1
	LEN 12
	NOTE C_, 5
	INSTR 5
	LEN 6
	NOTE C_, 5
	WAIT2
	INSTR 1
	LEN 12
	NOTE D_, 5
	NOTE E_, 5
	LEN 24
	NOTE F_, 5
	NOTE Gsh, 5
	LEN 12
	WAIT
	INSTR 2
	LEN 24
	NOTE Csh, 5
	NOTE Csh, 5
	LEN 12
	NOTE Csh, 5
	LEN 36
	NOTE Csh, 5
	LEN 24
	NOTE Csh, 5
	NOTE Csh, 5
	LEN 12
	NOTE C_, 5
	NOTE C_, 5
	INSTR 5
	LEN 6
	NOTE C_, 5
	WAIT2
	ARP 3
	NOTE Ash, 4
	WAIT2
	ARP_OFF
	NOTE Gsh, 4
	WAIT2
	ARP 3
	NOTE Gsh, 4
	WAIT2
	ARP_OFF
	NOTE Gsh, 4
	WAIT2
	ARP 3
	NOTE Ash, 4
	WAIT2
	ARP_OFF
	NOTE Gsh, 4
	WAIT2
	ARP 3
	NOTE Gsh, 4
	WAIT2
	ARP_OFF
	NOTE F_, 5
	WAIT2
	NOTE Gsh, 5
	WAIT2
	NOTE A_, 5
	WAIT2
	NOTE Ash, 5
	WAIT2
	NOTE C_, 6
	WAIT2
	NOTE Csh, 6
	LEN 12
	NOTE Dsh, 6
	LEN 6
	NOTE F_, 6
	LEN 24
	WAIT2
	END

; Instrument table 1, entries 1..6 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr1_0
	dw Instr1_1
	dw Instr1_2
	dw Instr1_3
	dw Instr1_4
	dw Instr1_5
Instr1_0:
	VOLENV 13, $11, $18, $11
	ARP 4
	WAVE Wave_7E07
	END
Instr1_1:
	HWENV $E1, $08, $55
	RELEASE $00
	VIBRATO $08, $01, $02
	DUTY_50
	ARP 0
	END
Instr1_2:
	HWENV $91, $04, $52
	DUTY_12
	ARP 0
	RELEASE $00
	END
Instr1_3:
	VOLENV 15, $11, $1F, $12
	ARP 0
	WAVE Wave_7D87
	END
Instr1_4:
	VOLENV 11, $11, $1F, $11
	ARP_OFF
	WAVE Wave_7D67
	END
Instr1_5:
	HWENV $A0, $00
	DUTY_75
	RELEASE $02, $52
	VIBRATO $12, $02, $04
	END

; Song 3: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong3:
	ld de, Song3_Ch1
	call L49F0
	ld de, Song3_Ch3
	call L49F8
	ld de, Song3_Ch2
	jp L49F4
Song3_Ch1:
	dw Pat_52BA
	dw Pat_52CC
	dw Pat_52F5
	dw Pat_52CC
	dw Pat_52F5
	dw Pat_53A3
	dw Pat_5336
	dw Pat_5371
	ORDER_LOOP Song3_Ch1
Song3_Ch3:
	dw Pat_53B1
	dw Pat_53C8
	dw Pat_5434
	dw Pat_53C8
	dw Pat_5443
	dw Pat_54BA
	dw Pat_5454
	dw Pat_5483
	ORDER_LOOP Song3_Ch3
Song3_Ch2:
	dw Pat_54C5
	dw Pat_54D3
	dw Pat_5547
	dw Pat_54D3
	dw Pat_5557
	dw Pat_55CF
	dw Pat_556B
	dw Pat_559C
	ORDER_LOOP Song3_Ch2
Pat_52BA:
	DRUMS $06, DrumPat_55DA
	TRANSPOSE $01
	LEN 12
	REPEAT 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE E_, 4
	REPEAT_END
	NEXT
Pat_52CC:
	DRUMS $06, DrumPat_55E9
	REPEAT 3
	INSTR 0
	NOTE A_, 2
	INSTR 5
	NOTE A_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 5
	NOTE A_, 4
	REPEAT_END
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 5
	NOTE A_, 4
	REPEAT 3
	INSTR 0
	NOTE A_, 2
	INSTR 5
	NOTE A_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 5
	NOTE A_, 4
	REPEAT_END
	INSTR 0
	NOTE E_, 2
	INSTR 4
	NOTE E_, 5
	INSTR 0
	NOTE B_, 2
	INSTR 4
	NOTE E_, 5
	NEXT
Pat_52F5:
	DRUMS $06, DrumPat_5606
	INSTR 0
	NOTE E_, 2
	INSTR 4
	NOTE E_, 5
	INSTR 0
	NOTE B_, 2
	INSTR 4
	NOTE E_, 5
	INSTR 0
	NOTE E_, 2
	INSTR 4
	NOTE E_, 3
	NOTE E_, 3
	INSTR 0
	NOTE B_, 1
	NOTE E_, 2
	INSTR 4
	NOTE E_, 5
	INSTR 0
	NOTE B_, 2
	INSTR 4
	NOTE E_, 5
	INSTR 0
	NOTE E_, 2
	INSTR 4
	NOTE E_, 4
	NOTE E_, 4
	INSTR 0
	NOTE B_, 2
	NOTE E_, 2
	INSTR 4
	NOTE E_, 5
	INSTR 0
	NOTE B_, 2
	INSTR 4
	NOTE E_, 5
	INSTR 0
	NOTE E_, 2
	INSTR 4
	NOTE E_, 5
	INSTR 0
	NOTE B_, 2
	INSTR 4
	NOTE E_, 5
	INSTR 0
	NOTE E_, 2
	INSTR 4
	NOTE E_, 5
	INSTR 0
	NOTE Gsh, 2
	INSTR 4
	NOTE E_, 5
	INSTR 0
	NOTE A_, 2
	INSTR 5
	NOTE A_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 5
	NOTE A_, 4
	NEXT
Pat_5336:
	DRUMS $06, DrumPat_5635
	REPEAT 2
	INSTR 0
	NOTE D_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 5
	NOTE D_, 4
	REPEAT_END
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	INSTR 0
	NOTE A_, 2
	INSTR 5
	NOTE A_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 5
	NOTE A_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 4
	NOTE E_, 4
	INSTR 0
	NOTE B_, 2
	NOTE B_, 1
	NOTE E_, 2
	INSTR 4
	NOTE E_, 4
	INSTR 0
	NOTE B_, 2
	INSTR 4
	NOTE E_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 5
	NOTE A_, 4
	INSTR 0
	NOTE B_, 2
	INSTR 5
	NOTE A_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 5
	NOTE A_, 4
	INSTR 0
	NOTE Csh, 3
	INSTR 4
	NOTE A_, 4
	NEXT
Pat_5371:
	DRUMS $06, DrumPat_5664
	REPEAT 2
	INSTR 0
	NOTE D_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 5
	NOTE D_, 4
	REPEAT_END
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	INSTR 0
	NOTE A_, 2
	INSTR 5
	NOTE A_, 4
	INSTR 0
	NOTE E_, 3
	INSTR 5
	NOTE A_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	INSTR 0
	NOTE B_, 1
	INSTR 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE F_, 2
	LEN 24
	NOTE E_, 2
	NOTE E_, 3
	LEN 12
	NEXT
Pat_53A3:
	DRUMS $06, DrumPat_56A5
	INSTR 0
	LEN 12
	NOTE A_, 2
	INSTR 5
	NOTE A_, 4
	INSTR 0
	NOTE E_, 3
	INSTR 4
	NOTE A_, 4
	NEXT
Pat_53B1:
	WAVE Wave_7D17
	VIBRATO $01, $02, $04
	LEN 12
	WAIT
	INSTR 6
	LEN 24
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	LEN 30
	NOTE C_, 4
	INSTR 7
	LEN 6
	NOTE E_, 4
	NEXT
Pat_53C8:
	LEN 6
	WAIT
	INSTR 7
	LEN 12
	NOTE A_, 4
	LEN 6
	NOTE A_, 4
	NOTE Gsh, 4
	LEN 12
	NOTE A_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 6
	NOTE F_, 4
	NOTE E_, 4
	LEN 12
	NOTE F_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE B_, 3
	LEN 6
	NOTE A_, 3
	INSTR 6
	LEN 30
	NOTE C_, 4
	INSTR 7
	LEN 12
	NOTE E_, 4
	NOTE A_, 4
	LEN 6
	NOTE A_, 4
	NOTE Gsh, 4
	LEN 12
	NOTE A_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 6
	NOTE F_, 4
	NOTE E_, 4
	LEN 12
	NOTE F_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 4
	LEN 6
	NOTE B_, 3
	INSTR 6
	LEN 30
	NOTE D_, 4
	INSTR 7
	LEN 6
	NOTE E_, 4
	NEXT
Pat_5401:
	LEN 6
	WAIT
	INSTR 7
	LEN 12
	NOTE Gsh, 4
	LEN 6
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 12
	NOTE Fsh, 4
	NOTE F_, 4
	LEN 6
	NOTE E_, 4
	INSTR 6
	LEN 12
	NOTE E_, 2
	LEN 18
	NOTE E_, 2
	INSTR 7
	LEN 12
	NOTE E_, 4
	NOTE Gsh, 4
	LEN 6
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 12
	NOTE Fsh, 4
	NOTE F_, 4
	LEN 6
	NOTE E_, 4
	INSTR 6
	LEN 12
	NOTE E_, 3
	LEN 18
	NOTE E_, 3
	INSTR 7
	LEN 12
	NOTE E_, 4
	NOTE B_, 4
	LEN 6
	NOTE B_, 4
	NOTE A_, 4
	LEN 12
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE B_, 3
	NEXT
Pat_5434:
	PAT_CALL Pat_5401
	NOTE C_, 4
	NOTE D_, 4
	NOTE B_, 3
	LEN 6
	NOTE C_, 4
	INSTR 6
	LEN 30
	NOTE E_, 4
	INSTR 7
	LEN 6
	NOTE E_, 4
	NEXT
Pat_5443:
	PAT_CALL Pat_5401
	LEN 6
	NOTE B_, 3
	NOTE C_, 4
	LEN 12
	NOTE D_, 4
	NOTE B_, 3
	LEN 6
	NOTE A_, 3
	INSTR 6
	LEN 24
	NOTE C_, 4
	LEN 12
	NOTE C_, 4
	NEXT
Pat_5454:
	INSTR 6
	LEN 12
	NOTE G_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE B_, 5
	NOTE A_, 5
	NOTE C_, 6
	NOTE B_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE Ash, 4
	NOTE A_, 4
	LEN 6
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	LEN 12
	NOTE E_, 5
	NOTE D_, 5
	NOTE B_, 4
	NOTE B_, 3
	NOTE E_, 4
	LEN 6
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	LEN 12
	NOTE F_, 5
	NOTE E_, 5
	NOTE B_, 2
	NOTE E_, 5
	NOTE C_, 3
	NOTE E_, 5
	NOTE Csh, 3
	LEN 6
	NOTE E_, 5
	NOTE E_, 5
	NEXT
Pat_5483:
	INSTR 6
	LEN 12
	NOTE G_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE B_, 5
	NOTE A_, 5
	NOTE C_, 6
	NOTE B_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE Ash, 4
	NOTE A_, 4
	LEN 6
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	LEN 12
	NOTE E_, 5
	NOTE D_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	LEN 6
	NOTE E_, 5
	NOTE F_, 5
	LEN 12
	NOTE E_, 5
	LEN 6
	NOTE E_, 5
	NOTE F_, 5
	LEN 24
	NOTE E_, 5
	ARP 3
	LEN 18
	VOLENV 10, $11, $1F, $14
	NOTE D_, 6
	GLIDE $FE
	LEN 6
	WAIT
	GLIDE_OFF
	NEXT
Pat_54BA:
	LEN 12
	WAIT
	INSTR 6
	LEN 6
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	NEXT
Pat_54C5:
	INSTR 1
	PINGPONG
	REPEAT 7
	LEN 12
	NOTE A_, 3
	LEN 6
	NOTE B_, 3
	NOTE C_, 4
	REPEAT_END
	LEN 12
	NOTE A_, 3
	INSTR 2
	NOTE E_, 4
	NEXT
Pat_54D3:
	INSTR 3
	LEN 12
	NOTE G_, 4
	INSTR 2
	LEN 6
	NOTE A_, 4
	NOTE Gsh, 4
	LEN 12
	NOTE A_, 4
	NOTE E_, 4
	INSTR 3
	NOTE Dsh, 4
	INSTR 2
	LEN 6
	NOTE F_, 4
	NOTE E_, 4
	LEN 12
	NOTE F_, 4
	NOTE D_, 4
	INSTR 3
	NOTE D_, 4
	INSTR 2
	NOTE C_, 4
	INSTR 3
	NOTE C_, 4
	INSTR 2
	NOTE B_, 3
	NOTE A_, 3
	INSTR 1
	LEN 6
	NOTE B_, 3
	NOTE C_, 4
	LEN 12
	NOTE A_, 3
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE G_, 4
	INSTR 2
	LEN 6
	NOTE A_, 4
	NOTE Gsh, 4
	LEN 12
	NOTE A_, 4
	NOTE E_, 4
	INSTR 3
	NOTE Dsh, 4
	INSTR 2
	LEN 6
	NOTE F_, 4
	NOTE E_, 4
	LEN 12
	NOTE F_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE C_, 4
	INSTR 3
	NOTE C_, 4
	INSTR 2
	NOTE C_, 4
	NOTE B_, 3
	INSTR 1
	LEN 6
	NOTE C_, 4
	NOTE D_, 4
	LEN 12
	NOTE B_, 3
	INSTR 2
	NOTE E_, 4
	NEXT
Pat_5519:
	INSTR 3
	LEN 12
	NOTE Fsh, 4
	INSTR 2
	LEN 6
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 12
	NOTE Fsh, 4
	NOTE F_, 4
	NOTE E_, 4
	INSTR 1
	NOTE E_, 3
	NOTE E_, 3
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE Fsh, 4
	INSTR 2
	LEN 6
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 12
	NOTE Fsh, 4
	NOTE F_, 4
	NOTE E_, 4
	INSTR 1
	NOTE E_, 4
	NOTE E_, 4
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE A_, 4
	INSTR 2
	LEN 6
	NOTE B_, 4
	NOTE A_, 4
	LEN 12
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE B_, 3
	NEXT
Pat_5547:
	PAT_CALL Pat_5519
	NOTE C_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE C_, 4
	INSTR 1
	LEN 6
	NOTE B_, 3
	NOTE C_, 4
	LEN 12
	NOTE A_, 3
	INSTR 2
	NOTE E_, 4
	NEXT
Pat_5557:
	PAT_CALL Pat_5519
	LEN 6
	NOTE B_, 3
	NOTE C_, 4
	LEN 12
	NOTE D_, 4
	NOTE B_, 3
	NOTE A_, 3
	INSTR 1
	LEN 6
	NOTE B_, 3
	NOTE C_, 4
	LEN 12
	NOTE A_, 3
	LEN 6
	NOTE B_, 3
	NOTE C_, 4
	NEXT
Pat_556B:
	INSTR 1
	LEN 12
	NOTE G_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE E_, 4
	NOTE E_, 5
	NOTE E_, 5
	NOTE E_, 5
	NOTE E_, 4
	LEN 6
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 12
	NOTE E_, 4
	NOTE D_, 4
	NOTE B_, 3
	INSTR 0
	NOTE B_, 2
	NOTE E_, 3
	INSTR 1
	LEN 6
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 12
	NOTE F_, 4
	NOTE E_, 4
	NOTE B_, 3
	NOTE E_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE Csh, 4
	LEN 6
	NOTE E_, 4
	NOTE E_, 4
	NEXT
Pat_559C:
	INSTR 1
	LEN 12
	NOTE G_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE E_, 4
	NOTE E_, 5
	NOTE E_, 5
	NOTE E_, 5
	NOTE E_, 4
	LEN 6
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 12
	NOTE E_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 6
	NOTE E_, 4
	NOTE F_, 4
	LEN 12
	NOTE E_, 4
	LEN 6
	NOTE E_, 4
	NOTE F_, 4
	LEN 24
	NOTE E_, 4
	INSTR 3
	LEN 18
	NOTE D_, 5
	GLIDE $FE
	LEN 6
	WAIT
	GLIDE_OFF
	NEXT
Pat_55CF:
	INSTR 1
	LEN 12
	NOTE A_, 3
	LEN 6
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NEXT
DrumPat_55DA:
	db DRUM_REPEAT + 6, 1, 0, 2, 0, DRUM_REPEAT_END, 1, 0; no DRUM_LOOP: the pattern runs into the next data
	db 2, 0, 1, 0, 2, 2, DRUM_REPEAT + 15
DrumPat_55E9:
	db DRUM_REPEAT + 6, 1, 0, 2, 0, DRUM_REPEAT_END, 1, 0
	db 2, 0, 1, 0, 2, 2, DRUM_REPEAT + 6, 1
	db 0, 2, 0, DRUM_REPEAT_END, 1, 0, 2, 0
	db 1, 0, 2, 2, DRUM_REPEAT + 15
DrumPat_5606:
	db 1, 0, 2, 0, 1, 0, 2, 1
	db 1, 0, 2, 0, 2, 0, 1, 0
	db 1, 0, 2, 0, 1, 0, 2, 1
	db 1, 0, 2, 0, 2, 0, 2, 2
	db DRUM_REPEAT + 6, 1, 0, 2, 0, DRUM_REPEAT_END, 1, 0
	db 2, 0, 1, 0, 2, 2, DRUM_REPEAT + 15
DrumPat_5635:
	db DRUM_REPEAT + 6, 1, 0, 2, 0, DRUM_REPEAT_END, 1, 0
	db 2, 0, 1, 0, 2, 2, 1, 0
	db 2, 0, 1, 0, 2, 0, 2, 0
	db 2, 0, 1, 0, 2, 0, 1, 0
	db 2, 0, 1, 0, 2, 0, 1, 0
	db 2, 0, 2, 0, 2, 2, DRUM_REPEAT + 15
DrumPat_5664:
	db 1, 0, 2, 0, 1, 0, 2, 0
	db 1, 0, 2, 0, 1, 0, 2, 0
	db 1, 0, 2, 0, 2, 0, 2, 0
	db 1, 0, 2, 0, 1, 0, 2, 2
	db 1, 0, 2, 0, 1, 0, 2, 0
	db 2, 0, 2, 0, 1, 0, 2, 0
	db 2, 0, 2, 2, 2, 0, 2, 2
	db 2, 0, 2, 2, 2, 0, 2, 0
	db DRUM_REPEAT + 15
DrumPat_56A5:
	db 1, 0, 2, 0, 1, 0, 2, 0
	db DRUM_REPEAT + 15

; Song 4: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong4:
	ld de, Song4_Ch1
	call L49F0
	ld de, Song4_Ch3
	call L49F8
	ld de, Song4_Ch2
	jp L49F4
Song4_Ch1:
	dw Pat_5735
	dw Pat_574F
	dw Pat_5735
	dw Pat_574F
	dw Pat_5769
	dw Pat_57C0
	ORDER_LOOP Song4_Ch1
Song4_Ch3:
	dw Pat_57EB
	dw Pat_5824
	dw Pat_57EB
	dw Pat_5824
	dw Pat_5854
	dw Pat_588E
	ORDER_LOOP Song4_Ch3
Song4_Ch2:
	dw Pat_58BF
	dw Pat_5921
	dw Pat_58CE
	dw Pat_5926
	dw Pat_5959
	dw Pat_596B
	ORDER_LOOP Song4_Ch2
Pat_56F0:
	INSTR 9
	LEN 16
	NOTE G_, 2
	INSTR 8
	LEN 8
	NOTE G_, 3
	INSTR 5
	LEN 16
	NOTE G_, 3
	INSTR 9
	LEN 8
	NOTE G_, 2
	LEN 16
	NOTE D_, 3
	INSTR 8
	LEN 8
	NOTE D_, 4
	INSTR 5
	LEN 16
	NOTE G_, 3
	INSTR 9
	LEN 8
	NOTE D_, 3
	LEN 16
	NOTE C_, 3
	INSTR 8
	LEN 8
	NOTE C_, 4
	INSTR 5
	LEN 16
	NOTE C_, 4
	INSTR 9
	LEN 8
	NOTE C_, 3
	LEN 16
	NOTE G_, 2
	INSTR 8
	LEN 8
	NOTE G_, 3
	INSTR 5
	LEN 16
	NOTE C_, 4
	INSTR 9
	LEN 8
	NOTE G_, 2
	LEN 16
	NOTE Dsh, 2
	INSTR 8
	LEN 8
	NOTE Dsh, 3
	INSTR 5
	LEN 16
	NOTE Dsh, 3
	INSTR 9
	LEN 8
	NOTE Dsh, 2
	LEN 16
	NOTE Ash, 2
	INSTR 8
	LEN 8
	NOTE Ash, 3
	INSTR 5
	LEN 16
	NOTE Dsh, 3
	INSTR 9
	LEN 8
	NOTE Ash, 2
	LEN 16
	NEXT
Pat_5735:
	PAT_CALL Pat_56F0
	NOTE D_, 2
	INSTR 8
	LEN 8
	NOTE D_, 3
	INSTR 9
	LEN 16
	NOTE E_, 2
	INSTR 8
	LEN 8
	NOTE E_, 3
	INSTR 9
	LEN 16
	NOTE F_, 2
	INSTR 8
	LEN 8
	NOTE F_, 3
	INSTR 9
	LEN 16
	NOTE Fsh, 2
	INSTR 8
	LEN 8
	NOTE Fsh, 3
	NEXT
Pat_574F:
	PAT_CALL Pat_56F0
	NOTE D_, 3
	INSTR 8
	LEN 8
	NOTE D_, 4
	INSTR 9
	LEN 16
	NOTE C_, 3
	INSTR 8
	LEN 8
	NOTE C_, 4
	INSTR 9
	LEN 16
	NOTE Ash, 2
	INSTR 8
	LEN 8
	NOTE Ash, 3
	INSTR 9
	LEN 16
	NOTE A_, 2
	INSTR 8
	LEN 8
	NOTE A_, 3
	NEXT
Pat_5769:
	INSTR 9
	LEN 16
	NOTE C_, 3
	INSTR 8
	LEN 8
	NOTE C_, 4
	INSTR 5
	LEN 16
	NOTE C_, 4
	INSTR 9
	LEN 8
	NOTE C_, 3
	LEN 16
	NOTE G_, 2
	INSTR 8
	LEN 8
	NOTE G_, 3
	INSTR 5
	LEN 16
	NOTE G_, 3
	INSTR 9
	LEN 8
	NOTE G_, 2
	LEN 16
	NOTE D_, 2
	INSTR 8
	LEN 8
	NOTE D_, 3
	INSTR 5
	LEN 16
	NOTE B_, 3
	INSTR 9
	LEN 8
	NOTE D_, 2
	LEN 16
	NOTE G_, 2
	LEN 8
	NOTE A_, 2
	LEN 16
	NOTE Ash, 2
	LEN 8
	NOTE D_, 3
	LEN 16
	NOTE C_, 3
	INSTR 8
	LEN 8
	NOTE C_, 4
	INSTR 5
	LEN 16
	NOTE C_, 4
	INSTR 9
	LEN 8
	NOTE C_, 3
	LEN 16
	NOTE G_, 2
	INSTR 8
	LEN 8
	NOTE G_, 3
	INSTR 5
	LEN 16
	NOTE G_, 3
	INSTR 9
	LEN 8
	NOTE G_, 2
	LEN 16
	NOTE A_, 2
	INSTR 8
	LEN 8
	NOTE A_, 3
	INSTR 9
	LEN 16
	NOTE E_, 2
	INSTR 8
	LEN 8
	NOTE E_, 3
	INSTR 9
	LEN 16
	NOTE D_, 2
	INSTR 8
	LEN 8
	NOTE D_, 3
	INSTR 9
	LEN 16
	NOTE D_, 2
	LEN 8
	NOTE D_, 2
	NEXT
Pat_57C0:
	INSTR 9
	LEN 40
	NOTE C_, 3
	LEN 8
	NOTE C_, 3
	LEN 40
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	LEN 40
	NOTE D_, 2
	LEN 16
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	NOTE A_, 2
	NOTE Ash, 2
	NOTE A_, 2
	NOTE G_, 2
	LEN 40
	NOTE C_, 3
	LEN 8
	NOTE C_, 3
	LEN 40
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	LEN 16
	NOTE D_, 2
	LEN 8
	NOTE D_, 2
	LEN 16
	NOTE E_, 2
	LEN 8
	NOTE Fsh, 2
	LEN 36
	NOTE G_, 2
	LEN 12
	GLIDE $01
	WAIT
	GLIDE_OFF
	NEXT
Pat_57EB:
	CH_TRANSPOSE $0C
	GLISS_OFF
	PINGPONG
	WAVE Wave_7DD7
	VOLENV 12, $11, $16, $11
	RELEASE $02, $11
	LEN 16
	NOTE Ash, 3
	GLISS_3
	LEN 24
	NOTE G_, 3
	NOTE G_, 3
	LEN 8
	NOTE G_, 3
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE Ash, 3
	LEN 16
	NOTE C_, 4
	LEN 24
	NOTE G_, 3
	NOTE G_, 3
	LEN 8
	NOTE G_, 3
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE G_, 3
	LEN 24
	NOTE Ash, 3
	NOTE G_, 3
	LEN 16
	NOTE Ash, 3
	LEN 8
	NOTE G_, 3
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE Ash, 3
	LEN 24
	NOTE A_, 3
	NOTE Ash, 3
	NOTE B_, 3
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE D_, 3
	NEXT
Pat_5824:
	LEN 16
	NOTE Ash, 3
	LEN 24
	NOTE G_, 3
	NOTE G_, 3
	LEN 8
	NOTE G_, 3
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE Ash, 3
	LEN 24
	NOTE C_, 4
	LEN 16
	NOTE D_, 4
	LEN 24
	NOTE G_, 3
	LEN 8
	NOTE G_, 3
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE G_, 3
	LEN 16
	NOTE Ash, 3
	LEN 24
	NOTE G_, 3
	LEN 8
	NOTE G_, 3
	LEN 16
	NOTE Ash, 3
	LEN 8
	NOTE G_, 3
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE Ash, 3
	LEN 16
	NOTE D_, 4
	LEN 24
	NOTE Dsh, 4
	NOTE D_, 4
	LEN 8
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE D_, 4
	NEXT
Pat_5854:
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE Dsh, 4
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE Dsh, 4
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE D_, 4
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE D_, 4
	LEN 16
	NOTE Fsh, 4
	LEN 8
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE Dsh, 4
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE Dsh, 4
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE D_, 4
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE D_, 4
	LEN 16
	NOTE A_, 4
	LEN 24
	NOTE E_, 4
	NOTE Fsh, 4
	LEN 8
	NOTE G_, 4
	LEN 16
	NOTE Fsh, 4
	LEN 8
	NOTE Fsh, 4
	NEXT
Pat_588E:
	LEN 16
	NOTE G_, 4
	LEN 24
	NOTE Dsh, 4
	LEN 8
	NOTE Dsh, 4
	LEN 16
	NOTE G_, 4
	LEN 24
	NOTE D_, 4
	LEN 8
	NOTE D_, 4
	LEN 16
	NOTE Fsh, 4
	LEN 8
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	LEN 16
	NOTE D_, 4
	LEN 8
	NOTE D_, 4
	NOTE C_, 4
	NOTE Ash, 3
	NOTE A_, 3
	NOTE Ash, 3
	LEN 24
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 16
	NOTE D_, 3
	LEN 8
	NOTE D_, 3
	LEN 16
	NOTE E_, 3
	LEN 8
	NOTE Fsh, 3
	LEN 36
	NOTE G_, 3
	RELEASE $00
	LEN 12
	GLIDE $FF
	WAIT
	GLIDE_OFF
	NEXT
Pat_58BF:
	GLISS_OFF
	PINGPONG
	HWENV $C2, $10, $40
	ARP_OFF
	RELEASE $02, $30
	DUTY_50
	VIBRATO $10, $02, $04
Pat_58CE:
	DRUMS $08, DrumPat_5986
	LEN 40
	NOTE D_, 5
	GLISS_3
	LEN 8
	NOTE G_, 4
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE C_, 5
	LEN 24
	NOTE Ash, 4
	LEN 40
	NOTE C_, 5
	LEN 32
	NOTE G_, 4
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE A_, 4
	LEN 24
	NOTE Ash, 4
	NOTE C_, 5
	LEN 16
	NOTE Ash, 4
	LEN 8
	NOTE A_, 4
	LEN 24
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE D_, 4
	NEXT
Pat_58F6:
	LEN 40
	NOTE D_, 5
	LEN 8
	NOTE G_, 4
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE C_, 5
	LEN 24
	NOTE Ash, 4
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	LEN 24
	NOTE G_, 4
	LEN 8
	NOTE D_, 4
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE A_, 4
	LEN 24
	NOTE Ash, 4
	NOTE C_, 5
	LEN 16
	NOTE Ash, 4
	LEN 8
	NOTE A_, 4
	LEN 24
	NOTE G_, 4
	DRUMS $08, DrumPat_59A9
	LEN 16
	NOTE D_, 5
	LEN 24
	NOTE Dsh, 5
	LENGTH $30
	NOTE D_, 5
	LEN 8
	NEXT
Pat_5921:
	PAT_CALL Pat_58F6
	NOTE G_, 4
	NEXT
Pat_5926:
	PAT_CALL Pat_58F6
	GLISS_OFF
	RELEASE $00
	HWENV $D3, $08, $53
	DUTY_75
	ARP 1
	NOTE G_, 3
	NEXT
Pat_5934:
	LEN 16
	NOTE Dsh, 4
	LEN 24
	NOTE C_, 4
	LEN 8
	NOTE C_, 4
	LEN 16
	NOTE D_, 4
	LEN 24
	NOTE Ash, 3
	LEN 8
	NOTE Ash, 3
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE A_, 3
	NOTE Ash, 3
	NOTE C_, 4
	LENGTH $30
	NOTE Ash, 3
	LEN 8
	NOTE D_, 4
	LEN 16
	NOTE Dsh, 4
	LEN 24
	NOTE C_, 4
	LEN 8
	NOTE Csh, 4
	LEN 16
	NOTE D_, 4
	LEN 24
	NOTE Ash, 3
	LEN 8
	NOTE Ash, 3
	LEN 16
	NEXT
Pat_5959:
	DRUMS $08, DrumPat_5986
	PAT_CALL Pat_5934
	NOTE Csh, 4
	LEN 24
	NOTE A_, 3
	NOTE D_, 4
	LEN 8
	NOTE Dsh, 4
	LEN 16
	NOTE D_, 4
	LEN 8
	NOTE G_, 3
	NEXT
Pat_596B:
	DRUMS $08, DrumPat_59B5
	PAT_CALL Pat_5934
	NOTE A_, 3
	LEN 8
	NOTE A_, 3
	LEN 16
	NOTE G_, 3
	LEN 8
	NOTE Fsh, 3
	LEN 16
	HWENV $D3, $08, $50
	LEN 36
	NOTE G_, 3
	GLIDE $FF
	LEN 12
	WAIT
	GLIDE_OFF
	NEXT
DrumPat_5986:
	db 7, 0, 5, 2, 0, 5, DRUM_REPEAT + 2, 1
	db 0, 5, 2, 0, 5, DRUM_REPEAT_END, 1, 0
	db 5, 2, 0, 1, DRUM_REPEAT + 3, 1, 0, 5
	db 2, 0, 5, DRUM_REPEAT_END, 1, 0, 1, 2
	db 0, 2, DRUM_LOOP
DrumPat_59A9:
	db 14, 0, 1, 14, 0, 1, 14, 8
	db 8, 9, 10, 10
DrumPat_59B5:
	db 7, 0, 6, 5, 0, 5, DRUM_REPEAT + 8, 14
	db 0, 6, 5, 0, 5, DRUM_REPEAT_END, DRUM_LOOP

; Song 5: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong5:
	ld de, Song5_Ch3
	call L49F8
	ld de, Song5_Ch2
	call L49F4
	ld de, Song5_Ch1
	jp L49F0
Song5_Ch3:
	dw Pat_5A4D
	dw Pat_5A78
	ORDER_LOOP Song5_Ch3
Song5_Ch2:
	dw Pat_5A96
	dw Pat_5AD1
	dw Pat_5AE0
	dw Pat_5AEA
	dw Pat_5AEA
	ORDER_LOOP Song5_Ch2
Song5_Ch1:
	dw Pat_5A04
	dw Pat_5B4C
	dw Pat_5A07
	dw Pat_5B4C
	dw Pat_5A0A
	dw Pat_5B4C
	dw Pat_5A0D
	dw Pat_5B4C
	dw Pat_5A10
	dw Pat_5B4C
	ORDER_LOOP Song5_Ch1
Pat_5A04:
	TRANSPOSE $03
	NEXT
Pat_5A07:
	TRANSPOSE $04
	NEXT
Pat_5A0A:
	TRANSPOSE $05
	NEXT
Pat_5A0D:
	TRANSPOSE $06
	NEXT
Pat_5A10:
	TRANSPOSE $07
	NEXT
Pat_5A13:
	INSTR 10
	LEN 12
	NOTE C_, 2
	INSTR 11
	NOTE C_, 4
	INSTR 10
	NOTE G_, 2
	INSTR 11
	NOTE C_, 4
	INSTR 10
	NOTE D_, 2
	INSTR 11
	NOTE D_, 4
	INSTR 10
	NOTE G_, 2
	INSTR 11
	NOTE B_, 3
	INSTR 10
	NOTE C_, 2
	INSTR 11
	NOTE C_, 4
	INSTR 10
	NOTE G_, 2
	INSTR 11
	NOTE C_, 4
	INSTR 10
	NOTE D_, 2
	INSTR 11
	NOTE D_, 4
	INSTR 10
	NOTE G_, 2
	INSTR 11
	NOTE G_, 3
	INSTR 10
	NOTE C_, 2
	INSTR 11
	NOTE C_, 4
	INSTR 10
	NOTE G_, 2
	INSTR 11
	NOTE C_, 4
	INSTR 10
	NOTE D_, 2
	INSTR 11
	NOTE D_, 4
	INSTR 10
	NOTE G_, 2
	INSTR 11
	NOTE B_, 3
	INSTR 10
	NOTE F_, 2
	INSTR 11
	NOTE Gsh, 3
	INSTR 10
	NOTE Dsh, 2
	INSTR 11
	NOTE G_, 3
	NEXT
Pat_5A4D:
	INSTR 11
	LEN 6
	NOTE G_, 2
	NOTE Gsh, 2
	NOTE G_, 2
	NOTE Gsh, 2
	LEN 12
	NOTE G_, 2
	NOTE G_, 2
	LEN 6
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	LEN 12
	NOTE B_, 3
	NOTE D_, 2
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 24
	NOTE G_, 2
	PAT_CALL Pat_5A13
	INSTR 10
	NOTE D_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 10
	NOTE G_, 2
	NOTE G_, 3
	PAT_CALL Pat_5A13
	INSTR 10
	NOTE D_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE G_, 2
Pat_5A78:
	LEN 12
	REPEAT 8
	INSTR 10
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	REPEAT_END
	REPEAT 4
	INSTR 10
	NOTE C_, 3
	INSTR 11
	NOTE C_, 4
	REPEAT_END
	INSTR 10
	NOTE G_, 2
	INSTR 11
	NOTE G_, 3
	INSTR 10
	NOTE G_, 2
	INSTR 11
	NOTE G_, 3
	INSTR 10
	NOTE D_, 2
	NOTE G_, 2
	NOTE C_, 2
	INSTR 11
	LEN 6
	NOTE G_, 3
	NOTE Dsh, 3
	NEXT
Pat_5A96:
	HWENV $F2, $06, $47
	DUTY_75
	ARP 11
	VIBRATO $01, $02, $04
	PINGPONG
	LEN 6
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 24
	NOTE G_, 4
	LEN 6
	NOTE G_, 2
	NOTE Gsh, 2
	NOTE G_, 2
	NOTE Gsh, 2
	LEN 24
	NOTE G_, 2
	LEN 6
	NOTE G_, 2
	NOTE Gsh, 2
	NOTE A_, 2
	NOTE Ash, 2
	NOTE B_, 2
	NOTE C_, 3
	NOTE Csh, 3
	NOTE D_, 3
	NOTE Dsh, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE Fsh, 3
	LEN 24
	NOTE G_, 3
	NEXT
Pat_5ABF:
	LEN 12
	WAIT
	LEN 24
	NOTE G_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE G_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE Ash, 3
	NEXT
Pat_5AD1:
	HWENV $B2, $06, $41
	PAT_CALL Pat_5ABF
	LEN 12
	NOTE Gsh, 3
	LEN 6
	NOTE B_, 3
	NOTE C_, 4
	LEN 12
	NOTE D_, 4
	NEXT
Pat_5AE0:
	PAT_CALL Pat_5ABF
	LEN 12
	NOTE B_, 4
	NOTE G_, 4
	LEN 6
	NOTE C_, 4
	NOTE G_, 3
	NEXT
Pat_5AEA:
	REPEAT 2
	LEN 12
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	LEN 6
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 4
	REPEAT_END
	LEN 12
	NOTE C_, 5
	NOTE G_, 3
	NOTE C_, 5
	NOTE G_, 3
	NOTE C_, 5
	NOTE F_, 3
	LEN 6
	NOTE C_, 5
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 12
	NOTE Dsh, 4
	NOTE D_, 4
	LEN 24
	NOTE Dsh, 4
	NEXT
Pat_5B12:
	LEN 6
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE D_, 5
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE G_, 4
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE D_, 5
	NOTE A_, 4
	NOTE A_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE G_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE D_, 5
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE C_, 5
	NOTE D_, 5
	NEXT
Pat_5B4C:
	DRUMS $06, DrumPat_5C17
	PINGPONG
	HWENV $A2, $06, $47
	DUTY_50
	RELEASE $01, $40
	ARP_OFF
	VIBRATO $06, $02, $04
	LEN 6
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE Gsh, 5
	LEN 24
	NOTE G_, 5
	LEN 6
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE Gsh, 3
	LEN 24
	NOTE G_, 3
	LEN 6
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Gsh, 4
	LEN 24
	NOTE G_, 4
	DRUMS $06, DrumPat_5BE9
	HWENV $82, $06, $47
	ARP 11
	PAT_CALL Pat_5B12
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE D_, 5
	PAT_CALL Pat_5B12
	LEN 12
	NOTE Dsh, 5
	LEN 3
	NOTE D_, 5
	NOTE E_, 5
	LEN 6
	NOTE D_, 5
	LEN 18
	NOTE C_, 5
	LEN 6
	NOTE E_, 5
	REPEAT 2
	DRUMS $06, DrumPat_5BFE
	LEN 6
	NOTE G_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE Gsh, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE G_, 5
	NOTE Ash, 5
	NOTE G_, 5
	NOTE C_, 5
	NOTE G_, 5
	NOTE Ash, 5
	NOTE G_, 5
	NOTE C_, 5
	NOTE Gsh, 5
	NOTE C_, 6
	NOTE Gsh, 5
	NOTE C_, 5
	NOTE Gsh, 5
	NOTE C_, 6
	NOTE Gsh, 5
	NOTE C_, 5
	NOTE G_, 5
	DRUMS $06, DrumPat_5BF3
	NOTE C_, 6
	NOTE G_, 5
	NOTE C_, 6
	NOTE G_, 5
	NOTE C_, 6
	NOTE G_, 5
	NOTE C_, 6
	NOTE G_, 5
	NOTE C_, 6
	NOTE F_, 5
	NOTE C_, 6
	NOTE F_, 5
	NOTE C_, 6
	NOTE F_, 5
	NOTE C_, 6
	NOTE F_, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE D_, 5
	LEN 12
	NOTE C_, 5
	NOTE B_, 4
	LEN 3
	NOTE C_, 5
	NOTE Csh, 5
	LEN 18
	NOTE C_, 5
	REPEAT_END
	NEXT
DrumPat_5BE9:
	db DRUM_REPEAT + 7, 1, 6, 2, 6, DRUM_REPEAT_END, 1, 6
	db 2, 2
DrumPat_5BF3:
	db DRUM_REPEAT + 7, 1, 6, 2, 6, DRUM_REPEAT_END, 2, 2
	db 2, 2, DRUM_LOOP
DrumPat_5BFE:
	db DRUM_REPEAT + 2, 7, 0, 2, 6, 1, 6, 2
	db 6, DRUM_REPEAT_END, DRUM_REPEAT + 2, 7, 0, 2, 6, DRUM_REPEAT_END
	db 7, 0, 2, 6, 1, 6, 2, 6
	db DRUM_LOOP
DrumPat_5C17:
	db DRUM_PINGPONG, 7, 0, 0, 0, 1, 0, 0; no DRUM_LOOP: the pattern runs into the next data
	db 0, 7, 0, 0, 0, 1, 0, 0
	db 0, 7, 0, 0, 0, 7, 0, 0
	db 0, 7, 0, 0, 0, DRUM_PINGPONG_OFF, 2, 2
	db 2, 2

; Song 6: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong6:
	ld de, Song6_Ch2
	call L49F4
	ld de, Song6_Ch3
	call L49F8
	ld de, Song6_Ch1
	jp L49F0
Song6_Ch2:
	dw Pat_5CF2
	dw Pat_5CF2
	dw Pat_5CF2
	dw Pat_5CA5
	dw Pat_5CBC
	dw Pat_5CF2
	dw Pat_5CF2
	dw Pat_5CA5
	dw Pat_5CBC
	dw Pat_5CE1
	dw Pat_5CE1
	dw Pat_5CA5
	dw Pat_5CBC
	ORDER_LOOP Song6_Ch2
Song6_Ch3:
	dw Pat_5D08
	dw Pat_5D08
	dw Pat_5D08
	dw Pat_5D31
	dw Pat_5D73
	dw Pat_5D08
	dw Pat_5D08
	dw Pat_5D31
	dw Pat_5D73
	dw Pat_5D80
	dw Pat_5D80
	dw Pat_5D31
	dw Pat_5D73
	ORDER_LOOP Song6_Ch3
Song6_Ch1:
	dw Pat_5EC4
	dw Pat_5DA5
	dw Pat_5DAA
	dw Pat_5E1D
	dw Pat_5E4D
	dw Pat_5DAA
	dw Pat_5DAA
	dw Pat_5E1D
	dw Pat_5E4D
	dw Pat_5E84
	dw Pat_5E84
	dw Pat_5DED
	dw Pat_5E4D
	ORDER_LOOP Song6_Ch1
Pat_5CA5:
	REPEAT 2
	LEN 21
	NOTE F_, 2
	NOTE G_, 2
	LEN 28
	NOTE Gsh, 2
	LEN 14
	NOTE F_, 2
	NOTE G_, 2
	NOTE Gsh, 2
	REPEAT_END
	REPEAT 2
	LEN 21
	NOTE C_, 2
	NOTE D_, 2
	LEN 28
	NOTE Dsh, 2
	LEN 14
	NOTE C_, 2
	NOTE D_, 2
	NOTE Dsh, 2
	REPEAT_END
	NEXT
Pat_5CBC:
	LEN 21
	NOTE D_, 2
	NOTE Fsh, 2
	LEN 28
	NOTE A_, 2
	LEN 14
	NOTE D_, 2
	NOTE Fsh, 2
	NOTE A_, 2
	LEN 21
	NOTE D_, 2
	NOTE Fsh, 2
	LEN 28
	NOTE A_, 2
	LEN 14
	NOTE D_, 2
	NOTE E_, 2
	NOTE Fsh, 2
	LEN 21
	NOTE G_, 2
	NOTE D_, 2
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE D_, 2
	NOTE G_, 2
	NOTE F_, 2
	LEN 21
	NOTE G_, 2
	NOTE Gsh, 2
	LEN 14
	NOTE G_, 2
	NOTE Gsh, 2
	NOTE G_, 2
	NOTE Dsh, 2
	NOTE D_, 2
	NEXT
Pat_5CE1:
	LEN 14
	REPEAT 4
	NOTE C_, 2
	LEN 7
	NOTE C_, 3
	LEN 14
	NOTE D_, 2
	LEN 7
	NOTE D_, 3
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE C_, 2
	NOTE D_, 2
	NOTE Dsh, 2
	REPEAT_END
	NEXT
Pat_5CF2:
	DRUMS $07, DrumPat_5F0A
	HWENV $F1, $0E, $71
	ARP 0
	DUTY_12
	REPEAT 4
	LEN 21
	NOTE C_, 2
	NOTE D_, 2
	LEN 28
	NOTE Dsh, 2
	LEN 14
	NOTE C_, 2
	NOTE D_, 2
	NOTE Dsh, 2
	REPEAT_END
	NEXT
Pat_5D08:
	LEN 14
	WAVE Wave_7DA7
	CH_TRANSPOSE $0C
	REPEAT 2
	INSTR 13
	NOTE C_, 4
	INSTR 15
	NOTE C_, 4
	INSTR 13
	NOTE C_, 4
	INSTR 15
	NOTE C_, 4
	INSTR 13
	NOTE C_, 4
	INSTR 15
	NOTE D_, 4
	INSTR 13
	NOTE C_, 4
	INSTR 15
	NOTE D_, 4
	INSTR 13
	NOTE C_, 4
	INSTR 14
	NOTE Dsh, 4
	INSTR 13
	NOTE C_, 4
	INSTR 14
	NOTE Dsh, 4
	INSTR 13
	NOTE C_, 4
	INSTR 15
	NOTE D_, 4
	INSTR 13
	NOTE C_, 4
	INSTR 15
	NOTE D_, 4
	REPEAT_END
	NEXT
Pat_5D31:
	INSTR 13
	LEN 14
	NOTE C_, 4
	INSTR 15
	NOTE F_, 4
	INSTR 13
	NOTE C_, 4
	INSTR 15
	NOTE F_, 4
	INSTR 13
	NOTE C_, 4
	INSTR 15
	NOTE G_, 4
	INSTR 13
	NOTE C_, 4
	INSTR 15
	NOTE G_, 4
	INSTR 13
	NOTE C_, 4
	INSTR 14
	NOTE Gsh, 4
	INSTR 13
	NOTE C_, 4
	INSTR 14
	NOTE Gsh, 4
	INSTR 13
	NOTE C_, 4
	INSTR 15
	NOTE G_, 4
	INSTR 13
	NOTE C_, 4
	INSTR 15
	NOTE G_, 4
	INSTR 13
	NOTE C_, 4
	INSTR 15
	NOTE C_, 4
	INSTR 13
	NOTE C_, 4
	INSTR 15
	NOTE C_, 4
	INSTR 13
	NOTE C_, 4
	INSTR 15
	NOTE D_, 4
	INSTR 13
	NOTE C_, 4
	INSTR 15
	NOTE D_, 4
	INSTR 13
	NOTE C_, 4
	INSTR 14
	NOTE Dsh, 4
	INSTR 13
	NOTE C_, 4
	INSTR 14
	NOTE Dsh, 4
	INSTR 13
	NOTE C_, 4
	INSTR 15
	NOTE D_, 4
	INSTR 13
	NOTE C_, 4
	INSTR 15
	NOTE D_, 4
	NEXT
Pat_5D73:
	REPEAT 8
	INSTR 13
	NOTE C_, 4
	INSTR 14
	NOTE D_, 4
	REPEAT_END
	REPEAT 8
	INSTR 13
	NOTE C_, 4
	INSTR 14
	NOTE G_, 4
	REPEAT_END
	NEXT
Pat_5D80:
	REPEAT 2
	INSTR 13
	NOTE C_, 4
	INSTR 15
	NOTE C_, 5
	INSTR 13
	NOTE C_, 4
	INSTR 15
	NOTE D_, 5
	INSTR 13
	NOTE C_, 4
	INSTR 14
	NOTE Dsh, 5
	INSTR 13
	NOTE C_, 4
	INSTR 15
	NOTE D_, 5
	REPEAT_END
	REPEAT 2
	INSTR 13
	NOTE C_, 4
	INSTR 15
	NOTE C_, 4
	INSTR 13
	NOTE C_, 4
	INSTR 15
	NOTE D_, 4
	INSTR 13
	NOTE C_, 4
	INSTR 14
	NOTE Dsh, 4
	INSTR 13
	NOTE C_, 4
	INSTR 14
	NOTE F_, 4
	REPEAT_END
	NEXT
Pat_5DA5:
	LEN 14
	NOTE C_, 3
	PAT_GOTO Pat_5DAD
Pat_5DAA:
	INSTR 12
	LEN 14
	NOTE G_, 3
Pat_5DAD:
	RELEASE $00
	ARP 11
	DUTY_75
	GLISS_OFF
	HWENV $F1, $0E, $72
	CH_TRANSPOSE $00
	NOTE C_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE Fsh, 4
	NOTE C_, 4
	NOTE F_, 4
	LEN 28
	NOTE Dsh, 4
	LEN 14
	NOTE G_, 3
	NOTE Dsh, 4
	NOTE G_, 3
	LEN 7
	NOTE D_, 4
	NOTE D_, 4
	LEN 14
	NOTE G_, 3
	NOTE C_, 4
	NOTE Ash, 3
	LEN 21
	NOTE C_, 4
	CH_TRANSPOSE $0C
	GLISS_3
	RELEASE $87, $20
	INSTR 12
	ARP 3
	NOTE F_, 4
	ARP_OFF
	LEN 14
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	LEN 21
	NOTE Dsh, 4
	NOTE C_, 4
	LEN 14
	NOTE G_, 3
	ARP 3
	LEN 21
	NOTE C_, 4
	ARP_OFF
	NOTE Ash, 3
	LEN 14
	NOTE F_, 3
	RELEASE $02, $20
	NEXT
Pat_5DED:
	CH_TRANSPOSE $00
	ARP 1
	DUTY_75
	LENGTH $54
	NOTE F_, 4
	LEN 14
	WAIT2
	LEN 7
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	WAIT2
	NOTE F_, 4
	NOTE Dsh, 4
	WAIT2
	NOTE D_, 4
	WAIT2
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE D_, 4
	NOTE C_, 4
	WAIT2
	LEN 14
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE G_, 3
	LEN 7
	WAIT2
	LEN 21
	NOTE C_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE D_, 4
	LEN 7
	WAIT2
	LEN 21
	NOTE C_, 4
	LEN 14
	NOTE Ash, 3
	LENGTH $40
	NOTE C_, 4
	LEN 48
	WAIT2
	NEXT
Pat_5E1D:
	ARP 3
	LENGTH $54
	NOTE Dsh, 4
	LEN 14
	WAIT2
	ARP_OFF
	LEN 7
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	WAIT2
	NOTE F_, 4
	NOTE Dsh, 4
	WAIT2
	NOTE D_, 4
	WAIT2
	LEN 14
	ARP 3
	NOTE Csh, 4
	ARP_OFF
	LEN 7
	NOTE D_, 4
	NOTE C_, 4
	WAIT2
	LEN 14
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE G_, 3
	LEN 7
	WAIT2
	LEN 21
	NOTE C_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE D_, 4
	LEN 7
	WAIT2
	LEN 21
	NOTE C_, 4
	LEN 14
	NOTE Ash, 3
	LENGTH $40
	NOTE G_, 3
	LEN 48
	WAIT2
	NEXT
Pat_5E4D:
	LEN 14
	NOTE D_, 4
	LEN 7
	WAIT2
	LEN 14
	NOTE Fsh, 4
	LEN 7
	WAIT2
	LEN 28
	NOTE A_, 4
	LEN 14
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	LEN 7
	NOTE C_, 5
	WAIT2
	NOTE B_, 4
	NOTE Ash, 4
	WAIT2
	NOTE A_, 4
	WAIT2
	LEN 21
	NOTE A_, 4
	LEN 14
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	LEN 7
	WAIT2
	LEN 21
	NOTE C_, 5
	LEN 14
	NOTE B_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 35
	NOTE G_, 4
	LEN 7
	WAIT2
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	WAIT2
	NOTE G_, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE D_, 4
	NEXT
Pat_5E84:
	DRUMS $07, DrumPat_5F3E
	GLISS_OFF
	HWENV $91, $04, $20
	ARP_OFF
	AUTODUTY $07
	LEN 7
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 4
	NOTE Ash, 4
	REPEAT 2
	NOTE C_, 4
	NOTE Ash, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE Ash, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE Ash, 4
	REPEAT_END
	REPEAT 2
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 5
	REPEAT_END
	REPEAT 2
	NOTE C_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE G_, 4
	REPEAT_END
	AUTODUTY $00
	GLISS_3
	INSTR 12
	NEXT
Pat_5EC4:
	CH_TRANSPOSE $00
	RELEASE $00
	GLISS_OFF
	VIBRATO $0F, $10, $01
	DUTY_75
	ARP 0
	LEN 28
	HWENV $60, $00
	NOTE C_, 6
	HWENV $50, $00
	NOTE C_, 6
	HWENV $40, $00
	NOTE C_, 6
	HWENV $30, $00
	NOTE C_, 6
	HWENV $20, $00
	NOTE C_, 6
	HWENV $10, $00
	NOTE C_, 6
	LENGTH $0E
	REST
	VIBRATO $0E, $02, $04
	PINGPONG
	HWENV $91, $0E, $53
	DUTY_12
	LEN 7
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE C_, 5
	LENGTH $AF
	WAIT
	LEN 7
	NOTE C_, 5
	NOTE Ash, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	CH_TRANSPOSE $0C
	NEXT
DrumPat_5F0A:
	db DRUM_PINGPONG, 7, 0, 0, 0, 12, 0, 6
	db 0, 1, 0, 6, 0, 2, 0, 4
	db 6, DRUM_REPEAT + 2, 1, 0, 6, 0, 12, 0
	db 6, 0, 1, 0, 6, 0, 2, 0
	db 4, 6, DRUM_REPEAT_END, 1, 0, 6, 0, 12
	db 0, 6, 0, 1, 2, 1, 0, 2
	db 0, 14, 0, DRUM_LOOP
DrumPat_5F3E:
	db DRUM_PINGPONG, 7, 0, 4, 0, 2, 6, 4
	db 6, 1, 6, 4, 6, 2, 6, 4
	db 2, DRUM_REPEAT + 2, 1, 6, 4, 6, 2, 6
	db 4, 6, 1, 6, 4, 6, 2, 6
	db 4, 2, DRUM_REPEAT_END, 1, 6, 4, 6, 2
	db 6, 4, 6, 1, 2, 1, 6, 2
	db 2, 14, 6, DRUM_LOOP

; Song 7: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong7:
	ld de, Song7_Ch3
	call L49F8
	ld de, Song7_Ch2
	call L49F4
	ld de, Song7_Ch1
	jp L49F0
Song7_Ch3:
	dw Pat_5FB8
	dw Pat_5FD4
Loop_5F88:
	dw Pat_5FE3
	dw Pat_5FEF
	dw Pat_601A
	dw Pat_6021
	dw Pat_6037
	ORDER_LOOP Loop_5F88
Song7_Ch2:
	dw Pat_60B7
	dw Pat_60D5
Loop_5F9A:
	dw Pat_6100
	dw Pat_6107
	dw Pat_6175
	dw Pat_617F
	dw Pat_618F
	ORDER_LOOP Loop_5F9A
Song7_Ch1:
	dw Pat_6257
	dw Pat_6274
Loop_5FAC:
	dw Pat_627B
	dw Pat_627B
	dw Pat_62A1
	dw Pat_62E6
	ORDER_LOOP Loop_5FAC
Pat_5FB8:
	VIBRATO $0E, $02, $05
	VOLENV 10, $1A, $10, $11
	RELEASE $07, $A1
	WAVE Wave_7D67
	LENGTH $78
	NOTE Csh, 2
	NOTE Dsh, 2
	LENGTH $3C
	NOTE D_, 2
	NOTE Fsh, 2
	LENGTH $78
	NOTE Csh, 2
	RELEASE $00
	NEXT
Pat_5FD4:
	WAVE Wave_7D57
	VOLENV 15, $12, $1F, $11
	LEN 28
	REPEAT 4
	NOTE Csh, 2
	NOTE E_, 2
	NOTE Dsh, 2
	NOTE D_, 2
	REPEAT_END
	NEXT
Pat_5FE3:
	DRUMS $07, DrumPat_63B9
	WAVE Wave_7D77
	VOLENV 15, $13, $1F, $11
	ARP 0
Pat_5FEF:
	LEN 14
	REPEAT 4
Pat_5FF1:
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE E_, 2
	NOTE Gsh, 3
	NOTE Dsh, 2
	NOTE G_, 3
	NOTE D_, 2
	NOTE D_, 3
	REPEAT_END
	NEXT
Pat_5FFB:
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE E_, 2
	NOTE E_, 3
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE Fsh, 2
	NOTE Fsh, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE E_, 2
	NOTE E_, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NEXT
Pat_601A:
	LEN 14
	PAT_CALL Pat_5FFB
	NOTE D_, 2
	NOTE D_, 3
	NEXT
Pat_6021:
	LEN 14
	PAT_CALL Pat_5FFB
	NOTE Csh, 2
	NOTE Csh, 3
	NEXT
Pat_6028:
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE E_, 2
	NOTE E_, 3
	NEXT
Pat_6037:
	LEN 14
	PAT_CALL Pat_6028
	NOTE Fsh, 2
	NOTE Fsh, 3
	PAT_CALL Pat_6028
	NOTE Gsh, 2
	NOTE Gsh, 3
	ARP_OFF
	RELEASE $01, $41
	ARP_OFF
	VOLENV 10, $1A, $10, $11
	WAVE Wave_7D27
	LEN 7
	NOTE Gsh, 2
	WAIT2
	NOTE Gsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 4
	WAIT2
	NOTE E_, 4
	WAIT2
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE C_, 4
	WAIT2
	NOTE C_, 4
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE Fsh, 3
	NOTE Csh, 2
	WAIT2
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE Csh, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	LEN 14
	NOTE Csh, 4
	LEN 7
	NOTE Gsh, 3
	NOTE E_, 3
	NOTE Csh, 3
	NOTE Dsh, 3
	NOTE E_, 3
	NOTE Csh, 3
	NOTE Dsh, 2
	WAIT2
	NOTE Dsh, 3
	WAIT2
	NOTE Ash, 2
	WAIT2
	NOTE Dsh, 3
	WAIT2
	NOTE Dsh, 2
	WAIT2
	NOTE Ash, 3
	WAIT2
	NOTE Dsh, 3
	WAIT2
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Gsh, 2
	WAIT2
	NOTE Dsh, 2
	WAIT2
	NOTE Gsh, 2
	WAIT2
	NOTE Dsh, 2
	WAIT2
	NOTE Gsh, 2
	WAIT2
	NOTE Gsh, 2
	NOTE A_, 2
	NOTE Gsh, 2
	LEN 21
	WAIT2
	LENGTH $70
	NOTE Csh, 4
	LEN 28
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE G_, 3
	NOTE Dsh, 3
	NOTE D_, 4
	NOTE A_, 3
	LEN 7
	NOTE D_, 3
	WAIT2
	DRUMS $07, DrumPat_641A
	NOTE D_, 3
	LEN 35
	REST
	WAVE Wave_7D77
	DRUMS $07, DrumPat_640A
	ARP 0
	RELEASE $00
	VOLENV 15, $13, $1F, $11
	LEN 14
	PAT_GOTO Pat_5FF1
Pat_60B7:
	PINGPONG
	HWENV $69, $02, $90
	ARP_OFF
	DUTY_75
	VIBRATO $0E, $01, $05
	RELEASE $04, $47
	LENGTH $78
	NOTE Csh, 3
	LEN 30
	NOTE Dsh, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE Dsh, 4
	LENGTH $3C
	NOTE A_, 3
	NOTE Fsh, 3
	LENGTH $78
	NOTE Gsh, 3
	NEXT
Pat_60D5:
	RELEASE $00
	HWENV $A1, $04, $37
	DUTY_50
	ARP 6
	RELEASE $00
	LEN 14
	REPEAT 4
	NOTE Csh, 3
	NOTE Csh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE D_, 3
	NOTE D_, 3
	REPEAT_END
	NEXT
Pat_60EB:
	HWENV $A1, $04, $37
	ARP 6
	LEN 7
	NOTE Csh, 4
	NOTE C_, 4
	LEN 14
	NOTE Csh, 4
	LEN 7
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 14
	NOTE Gsh, 4
	LEN 7
	NOTE Csh, 5
	NOTE C_, 5
	LEN 14
	NOTE Csh, 5
	NEXT
Pat_6100:
	RELEASE $00
	DUTY_50
	HWENV $D1, $05, $44
Pat_6107:
	ARP 15
	LEN 14
	NOTE Csh, 4
	PAT_CALL Pat_60EB
	HWENV $D1, $05, $44
	ARP 14
	NOTE D_, 4
	ARP 15
	NOTE Csh, 4
	LEN 28
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 14
	NOTE Csh, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE Csh, 4
	PAT_CALL Pat_60EB
	HWENV $D1, $05, $44
	ARP 15
	NOTE Csh, 4
	ARP 14
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE D_, 4
	NEXT
Pat_6130:
	LEN 14
	NOTE Gsh, 3
	LEN 7
	NOTE Csh, 4
	NOTE C_, 4
	LEN 14
	NOTE Csh, 4
	LEN 7
	NOTE E_, 4
	NOTE Dsh, 4
	LEN 14
	NOTE E_, 4
	LEN 7
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 14
	NOTE Gsh, 4
	NOTE Csh, 5
	NOTE Dsh, 5
	LEN 7
	NOTE Ash, 4
	NOTE A_, 4
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE G_, 4
	NOTE Fsh, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE Dsh, 4
	NOTE D_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE A_, 3
	LEN 7
	NOTE D_, 4
	NOTE Csh, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE Fsh, 4
	NOTE F_, 4
	LEN 14
	NOTE Fsh, 4
	LEN 7
	NOTE A_, 4
	NOTE Gsh, 4
	LEN 14
	NOTE A_, 4
	NOTE D_, 5
	NOTE Csh, 5
	LEN 7
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 14
	NOTE Gsh, 4
	LEN 7
	NOTE E_, 4
	NOTE Dsh, 4
	LEN 14
	NOTE E_, 4
	LEN 7
	NOTE Csh, 4
	NOTE C_, 4
	LEN 14
	NOTE Csh, 4
	NEXT
Pat_6175:
	HWENV $A1, $04, $37
	ARP 6
	PAT_CALL Pat_6130
	NOTE A_, 3
	NEXT
Pat_617F:
	PAT_CALL Pat_6130
	HWENV $69, $02, $90
	ARP_OFF
	DUTY_75
	RELEASE $01, $72
	LEN 7
	NOTE A_, 3
	WAIT2
	NEXT
Pat_618F:
	LEN 14
	NOTE Gsh, 3
	LEN 7
	NOTE C_, 4
	WAIT2
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE Dsh, 4
	WAIT2
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Fsh, 4
	WAIT2
	NOTE Fsh, 4
	WAIT2
	NOTE E_, 4
	WAIT2
	LEN 28
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE A_, 3
	LEN 14
	NOTE Gsh, 4
	LEN 7
	NOTE C_, 5
	WAIT2
	LEN 14
	NOTE C_, 5
	LEN 7
	NOTE Dsh, 5
	WAIT2
	LEN 14
	NOTE Dsh, 5
	LEN 7
	NOTE Fsh, 5
	WAIT2
	LEN 14
	NOTE Fsh, 5
	LEN 7
	WAIT2
	NOTE Dsh, 5
	LEN 28
	NOTE E_, 5
	NOTE Fsh, 5
	LEN 7
	NOTE Gsh, 5
	WAIT2
	DUTY_50
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 7
	NOTE Gsh, 4
	WAIT2
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE Gsh, 4
	WAIT2
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE Gsh, 4
	WAIT2
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	WAIT2
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	WAIT2
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	WAIT2
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE E_, 4
	NOTE Dsh, 4
	WAIT2
	NOTE Ash, 3
	NOTE Dsh, 4
	NOTE G_, 4
	WAIT2
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE Csh, 5
	NOTE G_, 5
	NOTE Dsh, 5
	NOTE G_, 5
	NOTE Gsh, 5
	LEN 7
	NOTE Dsh, 5
	WAIT2
	NOTE Csh, 5
	WAIT2
	NOTE C_, 5
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE C_, 5
	WAIT2
	NOTE C_, 4
	NOTE Csh, 4
	NOTE C_, 4
	WAIT2
	LEN 14
	NOTE Gsh, 3
	ARP 6
	DUTY_75
	LEN 7
	NOTE Gsh, 3
	WAIT2
	DRUMS_OFF
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Csh, 4
	WAIT2
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	WAIT2
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	WAIT2
	NOTE Csh, 5
	WAIT2
	NOTE Dsh, 5
	WAIT2
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	WAIT2
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	WAIT2
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	WAIT2
	NOTE Ash, 3
	WAIT2
	NOTE A_, 3
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE Fsh, 4
	WAIT2
	NOTE A_, 4
	LEN 35
	WAIT2
	HWENV $A1, $04, $37
	DUTY_50
	RELEASE $00
	LEN 14
	NOTE Csh, 4
	LEN 7
	NOTE Gsh, 3
	NOTE Csh, 4
	LEN 14
	NOTE E_, 4
	LEN 7
	NOTE Gsh, 3
	NOTE E_, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Ash, 3
	NOTE Dsh, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE A_, 3
	NOTE D_, 4
	NEXT
Pat_6257:
	PINGPONG
	HWENV $69, $02, $90
	ARP_OFF
	DUTY_75
	VIBRATO $0E, $01, $05
	RELEASE $04, $47
	LENGTH $3C
	NOTE Csh, 4
	NOTE Gsh, 4
	LENGTH $78
	NOTE G_, 4
	LENGTH $3C
	NOTE D_, 4
	NOTE C_, 4
	LENGTH $78
	NOTE Csh, 4
	NEXT
Pat_6274:
	RELEASE $00
	DUTY_75
	ARP_OFF
	HWENV $A1, $00
Pat_627B:
	LEN 28
	REPEAT 4
	NOTE Csh, 3
	NOTE E_, 3
	NOTE Dsh, 3
	NOTE D_, 3
	REPEAT_END
	NEXT
Pat_6283:
	LEN 35
	NOTE Gsh, 5
	LEN 7
	WAIT2
	NOTE Gsh, 4
	WAIT2
	NOTE Csh, 5
	WAIT2
	NOTE Dsh, 5
	WAIT2
	NOTE E_, 5
	WAIT2
	NOTE Gsh, 5
	WAIT2
	LEN 21
	NOTE G_, 5
	LEN 7
	WAIT2
	LENGTH $3F
	NOTE Dsh, 5
	LEN 7
	WAIT2
	NOTE Gsh, 4
	WAIT2
	LEN 21
	NOTE Fsh, 5
	LEN 7
	WAIT2
	NEXT
Pat_62A1:
	CH_TRANSPOSE $00
	ARP_OFF
	HWENV $69, $02, $90
	RELEASE $01, $72
	DUTY_50
	PAT_CALL Pat_6283
	LENGTH $31
	NOTE D_, 5
	LEN 7
	WAIT2
	NOTE Fsh, 5
	WAIT2
	NOTE D_, 5
	WAIT2
	NOTE E_, 5
	NOTE Dsh, 5
	LENGTH $54
	NOTE Csh, 5
	LEN 14
	WAIT2
	PAT_CALL Pat_6283
	LEN 42
	NOTE D_, 5
	LEN 7
	NOTE Fsh, 4
	WAIT2
	NOTE B_, 4
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE Csh, 5
	NOTE C_, 5
	RELEASE $00
	LENGTH $31
	NOTE Csh, 5
	LEN 7
	HWENV $70, $00
	NOTE C_, 5
	NOTE B_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Gsh, 4
	HWENV $69, $02, $90
	DUTY_75
	RELEASE $01, $72
	NOTE Csh, 4
	WAIT2
	NEXT
Pat_62E6:
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE Dsh, 4
	WAIT2
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Fsh, 4
	WAIT2
	LEN 14
	NOTE Fsh, 4
	LEN 7
	NOTE A_, 4
	WAIT2
	NOTE A_, 4
	WAIT2
	NOTE Gsh, 4
	WAIT2
	NOTE Gsh, 4
	NOTE A_, 4
	LEN 21
	NOTE Gsh, 4
	LEN 7
	NOTE Gsh, 4
	NOTE Csh, 5
	NOTE Dsh, 5
	NOTE E_, 5
	NOTE Dsh, 5
	NOTE Csh, 5
	NOTE Gsh, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE E_, 4
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE Dsh, 4
	WAIT2
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Fsh, 4
	WAIT2
	LEN 14
	NOTE Fsh, 4
	LEN 7
	NOTE A_, 4
	WAIT2
	LEN 14
	NOTE A_, 4
	LEN 7
	WAIT2
	NOTE B_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	LEN 21
	NOTE Gsh, 4
	LEN 7
	NOTE Gsh, 4
	NOTE Csh, 5
	NOTE Dsh, 5
	NOTE E_, 5
	DUTY_50
	NOTE Dsh, 5
	NOTE Csh, 5
	NOTE Dsh, 5
	NOTE E_, 5
	NOTE Fsh, 5
	NOTE Gsh, 5
	NOTE G_, 5
	LEN 21
	NOTE Fsh, 5
	LEN 7
	NOTE Dsh, 5
	NOTE C_, 5
	WAIT2
	NOTE Dsh, 5
	WAIT2
	LEN 14
	NOTE Fsh, 5
	LEN 7
	NOTE Dsh, 5
	WAIT2
	LEN 14
	NOTE A_, 5
	LEN 7
	NOTE Gsh, 5
	WAIT2
	LEN 21
	NOTE E_, 5
	LEN 7
	NOTE Csh, 5
	NOTE Gsh, 4
	WAIT2
	NOTE Csh, 5
	WAIT2
	LEN 14
	NOTE E_, 5
	LEN 7
	NOTE Csh, 5
	WAIT2
	LEN 14
	NOTE A_, 5
	LEN 7
	NOTE Gsh, 5
	WAIT2
	LEN 21
	NOTE G_, 5
	LEN 7
	NOTE Dsh, 5
	NOTE Ash, 4
	WAIT2
	NOTE Dsh, 5
	WAIT2
	NOTE G_, 5
	NOTE Dsh, 5
	NOTE G_, 5
	NOTE Ash, 5
	NOTE Csh, 6
	NOTE Ash, 5
	NOTE Dsh, 6
	NOTE Csh, 6
	LEN 7
	NOTE C_, 6
	WAIT2
	NOTE A_, 5
	WAIT2
	NOTE Gsh, 5
	NOTE Fsh, 5
	NOTE Gsh, 5
	NOTE A_, 5
	NOTE Gsh, 5
	WAIT2
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE Gsh, 3
	WAIT2
	LEN 14
	NOTE Gsh, 4
	LEN 35
	NOTE Gsh, 5
	LEN 7
	WAIT2
	NOTE Gsh, 4
	WAIT2
	DRUMS $07, DrumPat_641A
	NOTE Csh, 5
	WAIT2
	NOTE Dsh, 5
	WAIT2
	NOTE E_, 5
	WAIT2
	NOTE Gsh, 5
	WAIT2
	LEN 21
	NOTE G_, 5
	LEN 7
	WAIT2
	LENGTH $3F
	NOTE Dsh, 5
	LEN 7
	WAIT2
	NOTE Gsh, 4
	WAIT2
	LEN 21
	NOTE Fsh, 5
	LEN 7
	WAIT2
	LEN 42
	NOTE D_, 5
	LEN 7
	NOTE Fsh, 4
	WAIT2
	NOTE B_, 4
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE Csh, 5
	NOTE C_, 5
	RELEASE $00
	LENGTH $31
	NOTE Csh, 5
	LEN 7
	HWENV $70, $00
	NOTE C_, 5
	NOTE B_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	CH_TRANSPOSE $0C
	HWENV $30, $00
	RELEASE $00
	DUTY_75
	ARP 1
	NEXT
DrumPat_63B9:
	db 7, 0, 0, 0, 2, 0, 1, 0
	db DRUM_REPEAT + 2, 1, 0, 6, 0, 2, 0, 1
	db 0, DRUM_REPEAT_END, 1, 0, 6, 0, 2, 0
	db 14, 0, DRUM_REPEAT + 3, 1, 0, 6, 0, 2
	db 0, 1, 0, DRUM_REPEAT_END, 1, 0, 2, 0
	db 2, 0, 14, 0, DRUM_REPEAT + 3, 1, 0, 6
	db 0, 2, 0, 1, 0, DRUM_REPEAT_END, 1, 0
	db 6, 0, 2, 0, 14, 0, DRUM_REPEAT + 3, 1
	db 0, 6, 0, 2, 0, 1, 0, DRUM_REPEAT_END
	db 1, 0, 2, 0, 2, 0, 2, 2
	db DRUM_LOOP
DrumPat_640A:
	db 7, 0, 0, 0, 2, 0, 1, 0
	db 1, 0, 2, 0, 2, 0, 2, 2
DrumPat_641A:
	db DRUM_TEMPO + 28, 14, 0, DRUM_LOOP

; Song 8: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong8:
	ld de, Song8_Ch3
	call L49F8
	ld de, Song8_Ch1
	call L49F0
	ld de, Song8_Ch2
	jp L49F4
Song8_Ch3:
	dw Pat_6442

; Unreferenced (4 bytes)
	db $00, $00, $30, $64
Song8_Ch1:
	dw Pat_6469

; Unreferenced (4 bytes)
	db $00, $00, $36, $64
Song8_Ch2:
	dw Pat_6491

; Unreferenced (4 bytes)
	db $00, $00, $3C, $64
Pat_6442:
	CH_TRANSPOSE $0C
	DRUMS $07, DrumPat_64B7
	INSTR 10
	LEN 14
	NOTE C_, 2
	INSTR 14
	NOTE C_, 5
	INSTR 10
	NOTE G_, 1
	INSTR 14
	NOTE C_, 5
	INSTR 10
	NOTE C_, 2
	INSTR 14
	NOTE C_, 5
	INSTR 10
	NOTE G_, 1
	INSTR 14
	NOTE C_, 5
	NOTE Ash, 3
	INSTR 10
	NOTE Ash, 1
	NOTE Ash, 1
	INSTR 14
	NOTE Ash, 4
	INSTR 10
	NOTE F_, 1
	NOTE G_, 1
	LEN 7
	NOTE C_, 2
	DRUMS_OFF
	LENGTH $F5
	WAIT2
	END
Pat_6469:
	HWENV $59, $03, $90
	RELEASE $01, $34
	DUTY_50
	LEN 7
	NOTE C_, 5
	WAIT2
	PINGPONG
	NOTE B_, 4
	NOTE C_, 5
	NOTE G_, 4
	WAIT2
	NOTE E_, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE E_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE C_, 5
	WAIT2
	LENGTH $38
	NOTE Ash, 4
	LEN 14
	WAIT2
	NOTE F_, 4
	LEN 7
	NOTE E_, 4
	LENGTH $F5
	RELEASE $00
	WAIT2
	END
Pat_6491:
	PINGPONG
	TRANSPOSE $FE
	CH_TRANSPOSE $0C
	DUTY_50
	HWENV $A1, $02, $62
	LEN 14
	NOTE C_, 6
	LEN 7
	NOTE B_, 5
	NOTE C_, 6
	LEN 14
	NOTE G_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	LEN 7
	REPEAT 8
	LEN 4
	NOTE Ash, 5
	LEN 3
	NOTE Ash, 4
	REPEAT_END
	LEN 14
	NOTE Ash, 5
	NOTE B_, 3
	LEN 7
	NOTE C_, 4
	LENGTH $F5
	WAIT2
	END
DrumPat_64B7:
	db 1, 0, 5, 6, 2, 0, 14, 6
	db 1, 0, 5, 6, 2, 0, 4, 0
	db 1, 0, 5, 6, 2, 0, 5, 6
	db 2, 0, 2, 2, 7, DRUM_LOOP

; Song 9: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong9:
	ld de, Song9_Ch3
	call L49F8
	ld de, Song9_Ch2
	call L49F4
	ld de, Song9_Ch1
	jp L49F0
Song9_Ch3:
	dw Pat_6513
	dw Pat_651D
	dw Pat_6578
	dw Pat_663A
	dw Pat_6578
	dw Pat_65A1
	ORDER_LOOP Song9_Ch3
Song9_Ch2:
	dw Pat_6648
	dw Pat_6700
	dw Pat_6760
	dw Pat_6700
	dw Pat_67F0
	ORDER_LOOP Song9_Ch2
Song9_Ch1:
	dw Pat_6696
	dw Pat_6733
	dw Pat_6797
	dw Pat_6733
	dw Pat_67FF
	ORDER_LOOP Song9_Ch1
Pat_6513:
	CH_TRANSPOSE $0C
	VIBRATO $12, $02, $04
	RELEASE $01, $11
	INSTR 16
Pat_651D:
	LEN 45
	NOTE A_, 2
	LEN 9
	NOTE E_, 2
	LEN 27
	NOTE G_, 2
	LEN 18
	NOTE G_, 2
	LENGTH $51
	NOTE A_, 2
	LEN 9
	NOTE E_, 2
	LEN 27
	NOTE G_, 2
	LEN 45
	NOTE A_, 2
	LEN 9
	NOTE E_, 2
	LEN 27
	NOTE G_, 2
	LEN 18
	NOTE G_, 2
	LENGTH $51
	NOTE A_, 2
	LEN 9
	NOTE E_, 2
	LEN 27
	NOTE Dsh, 2
	LEN 45
	NOTE D_, 2
	LEN 9
	NOTE A_, 2
	LEN 27
	NOTE C_, 3
	LEN 18
	NOTE C_, 3
	LENGTH $51
	NOTE D_, 3
	LEN 9
	NOTE C_, 2
	LEN 27
	NOTE Csh, 2
	LEN 45
	NOTE D_, 2
	LEN 9
	NOTE A_, 2
	LEN 27
	NOTE C_, 3
	LEN 18
	NOTE C_, 3
	LENGTH $51
	NOTE D_, 3
	LEN 9
	NOTE Fsh, 2
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE Gsh, 2
	NEXT
Pat_655C:
	INSTR 16
	LEN 27
	NOTE A_, 2
	INSTR 15
	LEN 18
	NOTE A_, 3
	INSTR 16
	LEN 9
	NOTE E_, 2
	LEN 18
	NOTE G_, 2
	INSTR 15
	LEN 9
	NOTE A_, 3
	INSTR 16
	LEN 18
	NOTE G_, 2
	LEN 36
	NOTE A_, 2
	INSTR 15
	LEN 18
	NOTE A_, 3
	LEN 27
	NOTE A_, 3
	INSTR 16
	LEN 9
	NOTE E_, 2
	NEXT
Pat_6578:
	PAT_CALL Pat_655C
	LEN 18
	NOTE G_, 2
	INSTR 15
	LEN 9
	NOTE A_, 3
	INSTR 16
	LEN 27
	NOTE A_, 2
	INSTR 15
	LEN 18
	NOTE A_, 3
	INSTR 16
	LEN 9
	NOTE E_, 2
	LEN 18
	NOTE G_, 2
	INSTR 15
	LEN 9
	NOTE A_, 3
	INSTR 16
	LEN 18
	NOTE G_, 2
	LEN 36
	NOTE A_, 2
	INSTR 15
	LEN 18
	NOTE A_, 3
	LEN 27
	NOTE A_, 3
	INSTR 16
	LEN 9
	NOTE E_, 2
	LEN 18
	NOTE Dsh, 2
	INSTR 15
	LEN 9
	NOTE A_, 3
	NEXT
Pat_65A1:
	PAT_CALL Pat_6608
	LEN 36
	NOTE D_, 3
	INSTR 14
	LEN 18
	NOTE D_, 4
	LEN 27
	NOTE D_, 4
	INSTR 16
	LEN 9
	NOTE Fsh, 2
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE Gsh, 2
	PAT_CALL Pat_655C
	LEN 27
	NOTE G_, 2
	NOTE A_, 2
	INSTR 15
	LEN 18
	NOTE A_, 3
	INSTR 16
	LEN 9
	NOTE E_, 2
	LEN 18
	NOTE G_, 2
	INSTR 15
	LEN 9
	NOTE A_, 3
	INSTR 16
	LEN 18
	NOTE G_, 2
	LEN 36
	NOTE A_, 2
	INSTR 15
	LEN 18
	NOTE A_, 3
	LEN 27
	NOTE A_, 3
	INSTR 16
	LEN 9
	NOTE A_, 2
	LEN 18
	NOTE C_, 3
	LEN 9
	NOTE D_, 3
	INSTR 16
	LEN 27
	NOTE E_, 2
	INSTR 15
	LEN 18
	NOTE E_, 4
	INSTR 16
	LEN 9
	NOTE B_, 2
	LEN 18
	NOTE D_, 3
	INSTR 15
	LEN 9
	NOTE E_, 4
	INSTR 16
	LEN 18
	NOTE D_, 3
	LEN 36
	NOTE E_, 3
	INSTR 15
	LEN 18
	NOTE E_, 4
	LEN 27
	NOTE E_, 4
	INSTR 16
	LEN 9
	NOTE B_, 2
	LEN 18
	NOTE D_, 3
	LEN 9
	NOTE E_, 3
	LEN 27
	NOTE D_, 2
	INSTR 15
	LEN 18
	NOTE D_, 4
	INSTR 16
	LEN 9
	NOTE A_, 2
	LEN 18
	NOTE C_, 3
	INSTR 15
	LEN 9
	NOTE D_, 4
	INSTR 16
	LEN 27
	NOTE D_, 3
	LENGTH $36
	NOTE D_, 2
	WAIT2
	NEXT
Pat_6608:
	INSTR 16
	LEN 27
	NOTE D_, 2
	INSTR 14
	LEN 18
	NOTE D_, 4
	INSTR 16
	LEN 9
	NOTE A_, 2
	LEN 18
	NOTE C_, 3
	INSTR 14
	LEN 9
	NOTE D_, 4
	INSTR 16
	LEN 18
	NOTE C_, 3
	LEN 36
	NOTE D_, 3
	INSTR 14
	LEN 18
	NOTE D_, 4
	LEN 27
	NOTE D_, 4
	INSTR 16
	LEN 9
	NOTE C_, 2
	LEN 18
	NOTE Csh, 2
	INSTR 14
	LEN 9
	NOTE D_, 4
	INSTR 16
	LEN 27
	NOTE D_, 2
	INSTR 14
	LEN 18
	NOTE D_, 4
	INSTR 16
	LEN 9
	NOTE A_, 2
	LEN 18
	NOTE C_, 3
	INSTR 14
	LEN 9
	NOTE D_, 4
	INSTR 16
	LEN 18
	NOTE C_, 3
	NEXT
Pat_663A:
	PAT_CALL Pat_6608
	LEN 27
	NOTE D_, 3
	INSTR 14
	LEN 9
	NOTE D_, 4
	INSTR 16
	LEN 27
	NOTE Fsh, 2
	NOTE G_, 2
	NOTE Gsh, 2
	NEXT
Pat_6648:
	HWENV $00, $00
	DUTY_50
	VIBRATO $12, $01, $04
	PINGPONG
	LEN 27
	NOTE C_, 2
	HWENV $A1, $12, $33
	REPEAT 4
	LEN 18
	NOTE E_, 4
	LEN 36
	NOTE E_, 4
	LENGTH $36
	NOTE E_, 4
	REPEAT_END
	REPEAT 3
	LEN 18
	NOTE Fsh, 4
	LEN 36
	NOTE Fsh, 4
	LENGTH $36
	NOTE Fsh, 4
	REPEAT_END
	LEN 18
	NOTE Fsh, 4
	LEN 36
	NOTE Fsh, 4
	LEN 27
	NOTE Fsh, 4
	REPEAT 2
	NOTE A_, 3
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE E_, 4
	LEN 27
	NOTE E_, 3
	LEN 18
	NOTE E_, 4
	LEN 36
	NOTE C_, 4
	LEN 18
	NOTE E_, 4
	LEN 36
	NOTE E_, 4
	LEN 27
	NOTE E_, 4
	REPEAT_END
	REPEAT 2
	NOTE A_, 3
	LEN 18
	NOTE Fsh, 4
	LEN 9
	NOTE Fsh, 4
	LEN 27
	NOTE Fsh, 3
	LEN 18
	NOTE Fsh, 4
	LEN 36
	NOTE C_, 4
	LEN 18
	NOTE Fsh, 4
	LEN 36
	NOTE Fsh, 4
	LEN 27
	NOTE Fsh, 4
	REPEAT_END
	NEXT
Pat_6696:
	DRUMS $09, DrumPat_6815
	HWENV $00, $00
	DUTY_50
	VIBRATO $12, $01, $04
	LEN 27
	REST
	HWENV $A1, $12, $33
	PINGPONG
	REPEAT 4
	LEN 18
	NOTE C_, 4
	LEN 36
	NOTE C_, 4
	LENGTH $36
	NOTE C_, 4
	REPEAT_END
	REPEAT 3
	LEN 18
	NOTE D_, 4
	LEN 36
	NOTE D_, 4
	LENGTH $36
	NOTE D_, 4
	REPEAT_END
	LEN 18
	NOTE D_, 4
	LEN 27
	NOTE D_, 4
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE A_, 3
	LEN 27
	REPEAT 2
	NOTE A_, 5
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE C_, 4
	LEN 27
	NOTE E_, 5
	LEN 18
	NOTE C_, 4
	LEN 36
	NOTE C_, 6
	LEN 18
	NOTE C_, 4
	LEN 36
	NOTE C_, 4
	LEN 27
	NOTE C_, 4
	REPEAT_END
	NOTE A_, 5
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE D_, 4
	LEN 27
	NOTE Fsh, 5
	LEN 18
	NOTE D_, 4
	LEN 36
	NOTE C_, 6
	LEN 18
	NOTE D_, 4
	LEN 36
	NOTE D_, 4
	LEN 27
	NOTE D_, 4
	NOTE A_, 5
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE D_, 4
	LEN 27
	NOTE Fsh, 5
	LEN 18
	NOTE D_, 4
	LEN 36
	NOTE C_, 6
	LEN 18
	NOTE D_, 4
	LEN 27
	NOTE D_, 4
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE A_, 3
	NEXT
Pat_6700:
	LEN 18
	NOTE A_, 3
	LEN 9
	NOTE C_, 4
	LEN 18
	NOTE D_, 4
	LEN 27
	NOTE E_, 4
	LEN 9
	NOTE A_, 3
	LEN 27
	NOTE E_, 4
	LEN 18
	NOTE Dsh, 4
	LEN 9
	NOTE D_, 4
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE C_, 4
	LEN 27
	NOTE A_, 3
	LEN 9
	NOTE E_, 3
	LEN 18
	NOTE G_, 3
	LEN 27
	NOTE A_, 3
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE C_, 4
	LEN 27
	NOTE A_, 3
	NOTE A_, 3
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE D_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE C_, 4
	NEXT
Pat_6733:
	CH_TRANSPOSE $18
	PAT_CALL Pat_6700
	CH_TRANSPOSE $00
	NEXT
Pat_673B:
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE A_, 3
	LEN 27
	NOTE Fsh, 4
	LEN 18
	NOTE E_, 4
	LEN 27
	NOTE E_, 4
	NOTE Fsh, 4
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE C_, 4
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE D_, 4
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE D_, 4
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE A_, 3
	LEN 27
	NOTE G_, 4
	LEN 18
	NOTE G_, 4
	LEN 27
	NOTE G_, 4
	NOTE Fsh, 4
	NEXT
Pat_6760:
	PAT_CALL Pat_673B
	LEN 9
	NOTE D_, 4
	LEN 18
	NOTE Fsh, 2
	LEN 9
	NOTE E_, 4
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE D_, 4
	LEN 18
	NOTE Gsh, 2
	LEN 9
	NOTE C_, 4
	NEXT
Pat_6772:
	LEN 18
	NOTE D_, 6
	LEN 9
	NOTE A_, 5
	LEN 27
	NOTE A_, 4
	LEN 18
	NOTE A_, 4
	LEN 27
	NOTE A_, 4
	NOTE A_, 4
	LEN 9
	NOTE A_, 5
	LEN 18
	NOTE D_, 6
	LEN 9
	NOTE C_, 6
	LEN 18
	NOTE E_, 6
	LEN 9
	NOTE D_, 6
	LEN 18
	NOTE C_, 6
	LEN 9
	NOTE D_, 6
	LEN 18
	NOTE C_, 6
	LEN 9
	NOTE A_, 5
	LEN 27
	NOTE A_, 4
	LEN 18
	NOTE A_, 4
	LEN 27
	NOTE A_, 4
	NOTE C_, 5
	NEXT
Pat_6797:
	PAT_CALL Pat_6772
	LEN 9
	NOTE D_, 3
	LEN 27
	NOTE Fsh, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NEXT
Pat_67A1:
	LEN 18
	NOTE A_, 3
	LEN 27
	NOTE C_, 4
	LEN 9
	NOTE E_, 2
	LEN 27
	NOTE G_, 2
	LEN 18
	NOTE G_, 2
	LENGTH $51
	NOTE A_, 2
	LEN 9
	NOTE E_, 2
	LEN 27
	NOTE G_, 2
	LEN 45
	NOTE A_, 2
	LEN 9
	NOTE E_, 2
	LEN 27
	NOTE G_, 2
	LEN 18
	NOTE G_, 2
	LENGTH $51
	NOTE A_, 2
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE D_, 4
	LEN 27
	NOTE E_, 4
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE E_, 4
	LEN 18
	NOTE A_, 4
	LEN 9
	NOTE G_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 36
	NOTE E_, 4
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE E_, 4
	LEN 18
	NOTE A_, 4
	LEN 9
	NOTE G_, 4
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE G_, 4
	LEN 27
	NOTE D_, 4
	LEN 18
	NOTE F_, 4
	LEN 9
	NOTE D_, 4
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE F_, 4
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE C_, 4
	LEN 18
	NOTE D_, 4
	LEN 27
	NOTE D_, 4
	NEXT
Pat_67F0:
	PAT_CALL Pat_673B
	NOTE G_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 9
	NOTE C_, 4
	PAT_CALL Pat_67A1
	LENGTH $3F
	NOTE D_, 4
	NEXT
Pat_67FF:
	PAT_CALL Pat_6772
	NOTE G_, 6
	NOTE E_, 6
	NOTE D_, 6
	LEN 9
	NOTE C_, 6
	CH_TRANSPOSE $18
	PAT_CALL Pat_67A1
	CH_TRANSPOSE $00
	LEN 7
	NOTE D_, 6
	DRUMS_OFF
	LENGTH $38
	WAIT
	NEXT
DrumPat_6815:
	db DRUM_PINGPONG, 1, 0, 6, 4, 0, 1, 1
	db 0, 6, 4, 0, 5, 1, 0, 6
	db 4, 0, 1, 1, 0, 2, 4, 0
	db 5, 1, 0, 6, 4, 0, 1, 1
	db 0, 6, 4, 0, 5, 1, 0, 6
	db 4, 0, 1, 1, 0, 4, 6, 6
	db 2, DRUM_LOOP

; Song 10: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong10:
	ld de, Song10_Ch3
	call L49F8
	ld de, Song10_Ch1
	call L49F0
	ld de, Song10_Ch2
	jp L49F4
Song10_Ch3:
	dw Pat_6883
Loop_685B:
	dw Pat_6895
	dw Pat_68C5
	dw Pat_6902
	dw Pat_691E
	ORDER_LOOP Loop_685B
Song10_Ch1:
	dw Pat_693D
Loop_6869:
	dw Pat_6952
	dw Pat_6999
	dw Pat_69D9
	dw Pat_69EE
	ORDER_LOOP Loop_6869
Song10_Ch2:
	dw Pat_6A2A
Loop_6877:
	dw Pat_6A42
	dw Pat_6A9A
	dw Pat_6ADE
	dw Pat_6B04
	ORDER_LOOP Loop_6877
Pat_6883:
	RELEASE $02, $11
	INSTR 10
	LEN 18
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	LEN 9
	NOTE G_, 2
	NOTE A_, 2
	NOTE Ash, 2
	NOTE G_, 2
	LEN 18
	NOTE Fsh, 2
	LEN 36
	NOTE G_, 2
	NEXT
Pat_6895:
	LEN 18
	REPEAT 2
	INSTR 10
	NOTE G_, 2
	INSTR 14
	NOTE G_, 5
	INSTR 10
	NOTE D_, 3
	INSTR 14
	NOTE G_, 5
	REPEAT_END
	REPEAT 2
	INSTR 10
	NOTE D_, 2
	INSTR 14
	NOTE D_, 5
	INSTR 10
	NOTE A_, 2
	INSTR 14
	NOTE D_, 5
	REPEAT_END
	REPEAT 2
	INSTR 10
	NOTE G_, 2
	INSTR 14
	NOTE G_, 5
	INSTR 10
	NOTE D_, 3
	INSTR 14
	NOTE G_, 5
	REPEAT_END
	INSTR 10
	NOTE D_, 2
	INSTR 14
	NOTE D_, 5
	INSTR 10
	NOTE A_, 2
	INSTR 14
	NOTE D_, 5
	INSTR 10
	NOTE G_, 2
	NOTE B_, 2
	NOTE G_, 2
	INSTR 14
	LEN 9
	NOTE G_, 5
	NOTE G_, 5
	NEXT
Pat_68C5:
	LEN 18
	REPEAT 2
	INSTR 10
	NOTE C_, 3
	INSTR 14
	NOTE C_, 6
	INSTR 10
	NOTE G_, 2
	INSTR 14
	NOTE C_, 6
	REPEAT_END
	INSTR 10
	NOTE G_, 2
	INSTR 14
	NOTE G_, 5
	INSTR 10
	NOTE D_, 3
	INSTR 14
	NOTE G_, 5
	INSTR 10
	NOTE C_, 3
	NOTE G_, 2
	NOTE D_, 3
	INSTR 14
	LEN 9
	NOTE D_, 5
	NOTE D_, 5
	INSTR 10
	LEN 18
	NOTE G_, 2
	INSTR 14
	NOTE G_, 5
	INSTR 10
	NOTE G_, 2
	INSTR 14
	NOTE G_, 5
	INSTR 10
	NOTE G_, 2
	INSTR 15
	NOTE G_, 5
	INSTR 10
	NOTE G_, 2
	INSTR 15
	NOTE G_, 5
	INSTR 10
	NOTE D_, 2
	INSTR 14
	NOTE D_, 5
	INSTR 10
	NOTE D_, 2
	INSTR 14
	NOTE D_, 5
	INSTR 10
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	INSTR 15
	LEN 9
	NOTE G_, 5
	NOTE G_, 5
	NEXT
Pat_6902:
	INSTR 10
	LEN 18
	NOTE Dsh, 2
	INSTR 15
	NOTE C_, 6
	INSTR 10
	NOTE C_, 2
	INSTR 15
	NOTE C_, 6
	INSTR 10
	NOTE D_, 2
	NOTE D_, 2
	LEN 36
	NOTE D_, 2
	LEN 18
	NOTE Ash, 2
	INSTR 14
	NOTE Dsh, 6
	INSTR 10
	NOTE G_, 2
	INSTR 14
	NOTE Dsh, 6
	INSTR 10
	NOTE D_, 2
	NOTE D_, 2
	LEN 36
	NOTE D_, 3
	NEXT
Pat_691E:
	REPEAT 7
	LEN 18
	NOTE D_, 2
	LEN 9
	NOTE D_, 2
	NOTE D_, 2
	REPEAT_END
	NOTE D_, 2
	NOTE Fsh, 2
	NOTE A_, 2
	NOTE D_, 3
	REPEAT 4
	LEN 18
	NOTE D_, 3
	LEN 9
	NOTE D_, 3
	NOTE D_, 3
	REPEAT_END
	LEN 18
	NOTE D_, 3
	NOTE A_, 2
	NOTE Fsh, 2
	NOTE A_, 2
	LEN 9
	NOTE D_, 2
	NOTE D_, 3
	LEN 18
	NOTE D_, 2
	NOTE E_, 2
	NOTE Fsh, 2
	NEXT
Pat_693D:
	HWENV $F1, $04, $40
	DUTY_12
	ARP 0
	PINGPONG
	LEN 18
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE G_, 3
	LEN 18
	NOTE A_, 3
	LEN 36
	NOTE G_, 3
	NEXT
Pat_6952:
	HWENV $B1, $04, $37
	DUTY_12
	ARP 11
	LEN 9
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE D_, 5
	NOTE C_, 5
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE Fsh, 4
	LEN 18
	NOTE G_, 4
	NOTE B_, 4
	NOTE G_, 4
	LEN 9
	NOTE A_, 4
	NOTE B_, 4
	NEXT
Pat_6999:
	LEN 9
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	LEN 18
	NOTE C_, 5
	NOTE E_, 4
	NOTE Fsh, 4
	LEN 9
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE Ash, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE Fsh, 4
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE G_, 4
	NOTE Fsh, 4
	LEN 36
	NOTE G_, 4
	NEXT
Pat_69D9:
	DUTY_50
	LEN 18
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE D_, 5
	NOTE Ash, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE Ash, 4
	NOTE A_, 4
	LEN 9
	NOTE Ash, 4
	NOTE B_, 4
	LEN 36
	NOTE C_, 5
	NEXT
Pat_69EE:
	HWENV $70, $00
	ARP_OFF
	DUTY_50
	LEN 9
	REPEAT 3
	NOTE D_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	REPEAT_END
	NOTE Fsh, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	ARP 11
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE G_, 4
	NOTE Ash, 4
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE Csh, 5
	NOTE E_, 4
	NOTE G_, 4
	NOTE Csh, 5
	NOTE D_, 5
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE D_, 5
	HWENV $C1, $04, $37
	LEN 18
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE Csh, 5
	NOTE D_, 5
	LEN 9
	DUTY_75
	ARP 6
	NOTE D_, 4
	NOTE D_, 5
	LEN 18
	NOTE D_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NEXT
Pat_6A2A:
	VIBRATO $12, $01, $05
	HWENV $F1, $09, $40
	DUTY_12
	ARP 0
	LEN 18
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	LEN 9
	NOTE Ash, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE Ash, 3
	LEN 18
	NOTE C_, 4
	LEN 36
	NOTE Ash, 3
	NEXT
Pat_6A42:
	VIBRATO $12, $01, $05
	DRUMS $09, DrumPat_6B3B
	HWENV $80, $00
	RELEASE $73, $30
	DUTY_50
	ARP_OFF
	CH_TRANSPOSE $0C
	LEN 27
	NOTE D_, 4
	GLISS_2
	LEN 9
	NOTE Fsh, 4
	LEN 27
	NOTE G_, 4
	LEN 9
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 18
	NOTE B_, 4
	LEN 9
	NOTE A_, 4
	NOTE B_, 4
	LEN 18
	NOTE D_, 5
	LEN 9
	NOTE C_, 5
	NOTE B_, 4
	LEN 18
	NOTE A_, 4
	LEN 9
	NOTE B_, 4
	NOTE C_, 5
	LEN 5
	NOTE B_, 4
	NOTE C_, 5
	LEN 8
	NOTE B_, 4
	LEN 18
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	LEN 27
	NOTE D_, 4
	LEN 9
	NOTE Fsh, 4
	LEN 27
	NOTE G_, 4
	LEN 9
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 18
	NOTE B_, 4
	LEN 9
	NOTE C_, 5
	NOTE B_, 4
	LEN 18
	NOTE A_, 4
	LEN 9
	NOTE B_, 4
	NOTE C_, 5
	LEN 18
	NOTE B_, 4
	LEN 5
	NOTE A_, 4
	NOTE B_, 4
	LEN 8
	NOTE A_, 4
	LENGTH $48
	NOTE G_, 4
	NEXT
Pat_6A9A:
	LEN 27
	NOTE C_, 5
	LEN 9
	NOTE D_, 5
	LEN 27
	NOTE E_, 5
	LEN 9
	NOTE D_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	LEN 18
	NOTE G_, 5
	LEN 9
	NOTE F_, 5
	NOTE E_, 5
	LEN 18
	NOTE D_, 5
	LEN 9
	NOTE E_, 5
	NOTE F_, 5
	LEN 18
	NOTE G_, 5
	LEN 9
	NOTE F_, 5
	NOTE E_, 5
	LEN 18
	NOTE D_, 5
	NOTE C_, 5
	LEN 27
	NOTE D_, 5
	LEN 9
	NOTE C_, 5
	LEN 18
	NOTE B_, 4
	LEN 9
	NOTE C_, 5
	NOTE D_, 5
	LEN 27
	NOTE G_, 4
	LEN 9
	NOTE A_, 4
	LEN 18
	NOTE Ash, 4
	NOTE G_, 4
	LEN 27
	NOTE D_, 4
	LEN 9
	NOTE G_, 4
	LEN 18
	NOTE A_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	LEN 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 3
	NOTE G_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 36
	NOTE G_, 4
	CH_TRANSPOSE $00
	NEXT
Pat_6ADE:
	DRUMS $09, DrumPat_6B46
	GLISS_OFF
	RELEASE $01, $51
	DUTY_12
	ARP 1
	LEN 36
	NOTE Dsh, 4
	NOTE G_, 4
	LEN 9
	NOTE D_, 4
	WAIT2
	NOTE D_, 4
	WAIT2
	NOTE D_, 4
	LEN 27
	WAIT2
	LEN 36
	NOTE G_, 4
	NOTE Ash, 4
	LEN 9
	NOTE Fsh, 4
	WAIT2
	NOTE G_, 4
	NOTE Gsh, 4
	DRUMS $09, DrumPat_6B57
	NOTE A_, 4
	LEN 27
	WAIT2
	ARP_OFF
	NEXT
Pat_6B04:
	DRUMS $09, DrumPat_6B5F
	VIBRATO $09, $03, $05
	HWENV $A0, $00
	RELEASE $04, $51
	DUTY_50
	LENGTH $36
	NOTE D_, 3
	GLISS_1
	NOTE Ash, 3
	LEN 36
	NOTE G_, 3
	LENGTH $36
	NOTE A_, 3
	LENGTH $48
	NOTE D_, 4
	LEN 18
	NOTE D_, 4
	LEN 36
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Csh, 4
	NOTE D_, 4
	LEN 18
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Csh, 4
	NOTE D_, 4
	DRUMS $09, DrumPat_6B68
	GLISS_3
	LEN 9
	DUTY_75
	NOTE D_, 3
	NOTE D_, 4
	LEN 18
	NOTE D_, 3
	NOTE E_, 3
	NOTE Fsh, 3
	GLISS_OFF
	NEXT
DrumPat_6B3B:
	db DRUM_REPEAT + 7, 1, 5, 2, 6, DRUM_REPEAT_END, 1, 5
	db 2, 2, DRUM_LOOP
DrumPat_6B46:
	db 7, 0, 0, 0, 2, 0, 6, 0
	db 14, 0, 14, 0, 2, 0, 5, 6
	db DRUM_LOOP
DrumPat_6B57:
	db 2, DRUM_TEMPO + 4, 2, DRUM_TEMPO + 5, 2, DRUM_TEMPO + 9, 2, 2
DrumPat_6B5F:
	db 14, 0, 1, 1, 2, 6, 1, 14
	db DRUM_LOOP
DrumPat_6B68:
	db 2, 2, 2, 0, 2, 0, 2, 2
	db DRUM_LOOP

; Song 11: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong11:
	ld de, Song11_Ch3
	call L49F8
	ld de, Song11_Ch2
	call L49F4
	ld de, Song11_Ch1
	jp L49F0
Song11_Ch3:
	dw Pat_6BE8
	dw Pat_6BF4
	dw Pat_6BFA
	dw Pat_6C35
	dw Pat_6C9A
	dw Pat_6CA5
	ORDER_LOOP Song11_Ch3
Song11_Ch2:
	dw Pat_6CB0
	dw Pat_6CF6
	dw Pat_6D40
	dw Pat_6D8B
	dw Pat_6DD1
	dw Pat_6DFF
	ORDER_LOOP Song11_Ch2
Song11_Ch1:
	dw Pat_6E35
	dw Pat_6E7B
	dw Pat_6EB4
	dw Pat_6EE8
	dw Pat_6F15
	dw Pat_6F4C
	ORDER_LOOP Song11_Ch1
Pat_6BB3:
	LEN 18
	REPEAT 2
	INSTR 17
	NOTE A_, 2
	INSTR 19
	NOTE A_, 3
	INSTR 17
	NOTE E_, 2
	INSTR 19
	NOTE A_, 3
	REPEAT_END
	INSTR 17
	NOTE D_, 3
	INSTR 19
	NOTE D_, 4
	INSTR 17
	NOTE A_, 2
	INSTR 19
	NOTE D_, 4
	INSTR 17
	NOTE G_, 2
	INSTR 18
	NOTE G_, 3
	INSTR 17
	NOTE D_, 2
	INSTR 18
	NOTE G_, 3
	REPEAT 2
	INSTR 17
	NOTE A_, 2
	INSTR 19
	NOTE A_, 3
	INSTR 17
	NOTE E_, 2
	INSTR 19
	NOTE A_, 3
	REPEAT_END
	INSTR 17
	NOTE D_, 3
	INSTR 19
	NOTE D_, 4
	INSTR 17
	NOTE D_, 3
	INSTR 19
	NOTE D_, 4
	INSTR 17
	NOTE G_, 2
	NOTE E_, 2
	NOTE A_, 2
	INSTR 19
	LEN 9
	NOTE A_, 3
	NEXT
Pat_6BE8:
	DRUMS $09, DrumPat_6F85
	TRANSPOSE $02
	PAT_CALL Pat_6BB3
	INSTR 17
	NOTE G_, 2
	NEXT
Pat_6BF4:
	PAT_CALL Pat_6BB3
	INSTR 17
	NOTE A_, 2
	NEXT
Pat_6BFA:
	LEN 18
	REPEAT 2
	INSTR 17
	NOTE G_, 2
	INSTR 18
	NOTE G_, 4
	INSTR 17
	NOTE D_, 2
	INSTR 18
	NOTE G_, 4
	REPEAT_END
	INSTR 17
	NOTE A_, 2
	INSTR 19
	NOTE A_, 4
	INSTR 17
	NOTE E_, 2
	INSTR 19
	NOTE A_, 4
	INSTR 17
	NOTE A_, 2
	INSTR 19
	NOTE A_, 4
	INSTR 17
	NOTE E_, 2
	LEN 9
	NOTE A_, 2
	NOTE Gsh, 2
	LEN 18
	REPEAT 2
	INSTR 17
	NOTE G_, 2
	INSTR 18
	NOTE G_, 4
	INSTR 17
	NOTE D_, 2
	INSTR 18
	NOTE G_, 4
	REPEAT_END
	INSTR 17
	NOTE C_, 3
	INSTR 18
	NOTE C_, 5
	INSTR 17
	NOTE G_, 2
	INSTR 18
	NOTE C_, 5
	INSTR 17
	NOTE C_, 3
	INSTR 18
	NOTE C_, 5
	INSTR 17
	NOTE G_, 2
	INSTR 18
	LEN 9
	NOTE C_, 5
	INSTR 17
	NOTE C_, 3
	NEXT
Pat_6C35:
	LEN 18
	REPEAT 2
	INSTR 17
	NOTE Gsh, 2
	INSTR 18
	NOTE E_, 5
	INSTR 17
	NOTE E_, 2
	INSTR 18
	NOTE E_, 5
	REPEAT_END
	INSTR 17
	NOTE A_, 2
	INSTR 19
	NOTE A_, 4
	INSTR 17
	NOTE E_, 2
	INSTR 19
	NOTE A_, 4
	INSTR 17
	NOTE A_, 2
	INSTR 19
	NOTE A_, 4
	INSTR 17
	NOTE E_, 2
	NOTE A_, 2
	NOTE Gsh, 2
	INSTR 18
	NOTE E_, 4
	INSTR 17
	NOTE E_, 2
	INSTR 18
	NOTE E_, 4
	INSTR 17
	NOTE Gsh, 2
	INSTR 18
	NOTE E_, 4
	INSTR 17
	NOTE E_, 2
	INSTR 18
	NOTE E_, 4
	INSTR 17
	NOTE A_, 2
	INSTR 19
	NOTE A_, 4
	INSTR 17
	NOTE E_, 2
	INSTR 19
	NOTE A_, 4
	INSTR 17
	NOTE A_, 2
	NOTE G_, 2
	LEN 9
	NOTE E_, 2
	NOTE G_, 2
	INSTR 19
	LEN 18
	NOTE A_, 4
	NEXT
Pat_6C70:
	INSTR 17
	LEN 18
	NOTE A_, 2
	INSTR 19
	NOTE A_, 4
	NOTE A_, 4
	INSTR 17
	NOTE G_, 2
	INSTR 18
	NOTE G_, 4
	NOTE G_, 4
	INSTR 17
	NOTE F_, 2
	INSTR 18
	NOTE F_, 4
	NOTE F_, 4
	INSTR 17
	NOTE E_, 2
	INSTR 18
	LEN 9
	NOTE E_, 4
	INSTR 17
	NOTE B_, 2
	NOTE D_, 3
	NOTE E_, 3
	LEN 18
	NOTE C_, 3
	INSTR 18
	NOTE C_, 5
	NOTE C_, 5
	INSTR 17
	NOTE G_, 2
	INSTR 18
	NOTE G_, 4
	NOTE G_, 4
	INSTR 17
	NOTE F_, 2
	INSTR 18
	NOTE F_, 4
	INSTR 17
	NOTE G_, 2
	NEXT
Pat_6C9A:
	DRUMS $09, DrumPat_6F8A
	PAT_CALL Pat_6C70
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	NEXT
Pat_6CA5:
	PAT_CALL Pat_6C70
	LENGTH $36
	VOLENV 15, $00, $00, $00
	NOTE A_, 2
	NEXT
Pat_6CB0:
	PINGPONG
	HWENV $C1, $03, $73
	DUTY_12
	ARP 11
	VIBRATO $09, $02, $04
	LEN 18
	NOTE A_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE E_, 3
	NOTE C_, 3
	LEN 9
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE C_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE C_, 3
	LEN 18
	NOTE E_, 3
	LEN 9
	NOTE D_, 3
	NOTE E_, 3
	LEN 18
	NOTE D_, 3
	LEN 9
	NOTE D_, 3
	NOTE D_, 3
	LEN 18
	NOTE A_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE E_, 3
	NOTE C_, 3
	LEN 9
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE C_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE C_, 3
	LEN 18
	NOTE B_, 2
	LEN 9
	NOTE A_, 2
	NOTE Gsh, 2
	LEN 18
	NOTE A_, 2
	LEN 9
	NOTE E_, 3
	NOTE G_, 3
	NEXT
Pat_6CF6:
	LEN 18
	NOTE A_, 3
	LEN 9
	NOTE A_, 3
	NOTE A_, 3
	LEN 18
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	NOTE G_, 3
	LEN 18
	NOTE E_, 3
	LEN 9
	NOTE E_, 3
	NOTE E_, 3
	LEN 18
	NOTE C_, 3
	LEN 9
	NOTE D_, 3
	NOTE E_, 3
	LEN 18
	NOTE F_, 3
	LEN 9
	NOTE F_, 3
	LEN 27
	NOTE F_, 3
	LEN 9
	NOTE F_, 3
	LEN 27
	NOTE F_, 3
	LEN 9
	NOTE G_, 3
	LEN 27
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	NOTE G_, 3
	LEN 18
	NOTE A_, 3
	LEN 9
	NOTE A_, 3
	NOTE A_, 3
	LEN 18
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	NOTE G_, 3
	LEN 18
	NOTE E_, 3
	LEN 9
	NOTE E_, 3
	NOTE E_, 3
	LEN 18
	NOTE C_, 3
	LEN 9
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE C_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE C_, 3
	LEN 18
	NOTE G_, 3
	NOTE E_, 3
	LEN 9
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE A_, 3
	NEXT
Pat_6D40:
	LEN 9
	NOTE B_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE D_, 4
	LEN 18
	NOTE F_, 4
	LEN 9
	NOTE D_, 5
	NOTE C_, 5
	LEN 18
	NOTE B_, 4
	LEN 9
	NOTE B_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE D_, 4
	LEN 18
	NOTE F_, 4
	LEN 9
	NOTE E_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE C_, 4
	LEN 18
	NOTE B_, 3
	LEN 9
	NOTE D_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE A_, 3
	LEN 18
	NOTE E_, 3
	LEN 9
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE D_, 4
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE B_, 4
	NOTE A_, 4
	LEN 18
	NOTE B_, 4
	LEN 9
	NOTE C_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE B_, 4
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE Fsh, 5
	LEN 18
	NOTE G_, 5
	LEN 9
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NEXT
Pat_6D8B:
	LEN 9
	NOTE E_, 4
	NOTE E_, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 18
	NOTE B_, 4
	LEN 9
	NOTE B_, 5
	NOTE A_, 5
	LEN 18
	NOTE Gsh, 5
	LEN 9
	NOTE C_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE B_, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 18
	NOTE A_, 4
	LEN 9
	NOTE E_, 4
	NOTE E_, 4
	LEN 18
	NOTE F_, 4
	LEN 9
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 18
	NOTE E_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	LEN 9
	NOTE D_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE E_, 4
	LEN 18
	NOTE Gsh, 4
	LEN 9
	NOTE B_, 5
	NOTE A_, 5
	LEN 18
	NOTE Gsh, 5
	LEN 9
	NOTE C_, 5
	NOTE B_, 4
	LEN 18
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 4
	LEN 9
	NOTE A_, 3
	LEN 27
	NOTE A_, 3
	LEN 9
	NOTE G_, 3
	NOTE G_, 3
	LEN 18
	NOTE A_, 3
	NOTE G_, 3
	LEN 9
	NOTE E_, 3
	LEN 18
	NOTE G_, 3
	LEN 9
	NOTE B_, 4
	NEXT
Pat_6DD1:
	LEN 9
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE B_, 3
	LEN 18
	NOTE C_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 3
	LEN 9
	NOTE F_, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	LEN 18
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE E_, 3
	LEN 9
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 18
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 3
	LEN 9
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE C_, 4
	LEN 18
	NOTE B_, 3
	LEN 27
	NOTE A_, 3
	LEN 9
	NOTE E_, 3
	LEN 18
	NOTE G_, 3
	NEXT
Pat_6DFF:
	LEN 9
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE B_, 3
	LEN 18
	NOTE C_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 3
	LEN 9
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE A_, 3
	NOTE C_, 4
	LEN 27
	NOTE B_, 3
	LEN 9
	NOTE G_, 4
	LEN 18
	NOTE D_, 4
	NOTE E_, 4
	LEN 9
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 18
	NOTE G_, 4
	NOTE D_, 4
	LEN 9
	NOTE G_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE C_, 4
	LEN 18
	NOTE B_, 3
	LENGTH $2A
	HWENV $C1, $03, $70
	NOTE Csh, 4
	LEN 12
	GLIDE $FF
	WAIT
	GLIDE_OFF
	NEXT
Pat_6E35:
	PINGPONG
	HWENV $B2, $09, $50
	DUTY_75
	VIBRATO $09, $01, $05
	RELEASE $A4, $34
	LEN 18
	ARP 3
	NOTE G_, 5
	ARP_OFF
	NOTE A_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE E_, 5
	NOTE C_, 5
	LEN 9
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE C_, 5
	LEN 18
	NOTE E_, 5
	LEN 9
	NOTE D_, 5
	NOTE E_, 5
	LEN 36
	NOTE D_, 5
	LEN 18
	ARP 3
	NOTE G_, 5
	ARP_OFF
	NOTE A_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE E_, 5
	NOTE C_, 5
	LEN 9
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE C_, 5
	LEN 18
	NOTE B_, 4
	LEN 9
	NOTE A_, 4
	NOTE Gsh, 4
	LEN 36
	NOTE A_, 4
	NEXT
Pat_6E7B:
	ARP 2
	LEN 18
	NOTE G_, 4
	ARP 11
	NOTE A_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE C_, 4
	LEN 9
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE D_, 4
	NOTE E_, 4
	LEN 36
	NOTE D_, 4
	LEN 18
	ARP 2
	NOTE G_, 4
	ARP 11
	NOTE A_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE C_, 4
	LEN 9
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	LEN 18
	NOTE B_, 3
	LEN 9
	NOTE A_, 3
	NOTE Gsh, 3
	LEN 36
	NOTE A_, 3
	NEXT
Pat_6EB4:
	ARP_OFF
	RELEASE $00
	GLISS_2
	HWENV $59, $03, $80
	DUTY_50
	VIBRATO $0E, $02, $05
	LEN 18
	NOTE B_, 4
	GLISS_1
	NOTE D_, 5
	LENGTH $36
	NOTE F_, 5
	LEN 18
	NOTE B_, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE D_, 5
	NOTE C_, 5
	NOTE A_, 4
	LEN 36
	NOTE E_, 4
	LEN 18
	NOTE B_, 4
	NOTE D_, 5
	LENGTH $36
	NOTE G_, 5
	LEN 18
	NOTE A_, 5
	NOTE F_, 5
	NOTE G_, 5
	HWENV $80, $64, $87
	LENGTH $68
	NOTE E_, 5
	LEN 40
	WAIT
	NEXT
Pat_6EE8:
	HWENV $59, $03, $80
	LEN 18
	NOTE E_, 5
	NOTE Gsh, 5
	LENGTH $36
	NOTE B_, 5
	LEN 18
	NOTE C_, 6
	NOTE B_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE B_, 4
	LENGTH $36
	NOTE D_, 5
	LEN 9
	NOTE E_, 5
	NOTE D_, 5
	LEN 18
	NOTE E_, 5
	GLISS_2
	NOTE E_, 4
	HWENV $80, $64, $87
	LENGTH $68
	GLISS_1
	NOTE A_, 4
	LEN 40
	WAIT
	NEXT
Pat_6F15:
	VIBRATO $09, $01, $05
	GLISS_OFF
	RELEASE $00
	HWENV $A3, $00
	DUTY_12
	ARP 11
	LEN 18
	NOTE A_, 4
	NOTE E_, 5
	NOTE E_, 5
	LEN 9
	NOTE D_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE B_, 4
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE C_, 5
	LEN 18
	NOTE B_, 4
	NOTE Gsh, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE E_, 5
	LEN 9
	NOTE D_, 5
	NOTE B_, 4
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE C_, 5
	LEN 18
	NOTE B_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE G_, 4
	NEXT
Pat_6F4C:
	LEN 18
	NOTE A_, 4
	NOTE E_, 5
	NOTE E_, 5
	LEN 9
	NOTE D_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE B_, 4
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE C_, 5
	LEN 27
	NOTE B_, 4
	LEN 9
	NOTE G_, 5
	LEN 18
	NOTE D_, 5
	NOTE E_, 5
	LEN 9
	NOTE E_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	LEN 18
	NOTE G_, 5
	NOTE D_, 5
	LEN 9
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE C_, 5
	LEN 18
	NOTE B_, 4
	LENGTH $2A
	RELEASE $00
	HWENV $A3, $09, $80
	NOTE A_, 4
	GLIDE $01
	LEN 12
	WAIT
	GLIDE_OFF
	NEXT
DrumPat_6F85:
	db 1, 0, 5, 6, DRUM_LOOP
DrumPat_6F8A:
	db 1, 0, 4, 0, 4, 6, DRUM_LOOP

; Song 12: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong12:
	ld de, Song12_Ch3
	call L49F8
	ld de, Song12_Ch2
	call L49F4
	ld de, Song12_Ch1
	jp L49F0
Song12_Ch3:
	dw Pat_701C
	dw Pat_7033
	dw Pat_7066
	dw Pat_7071
	dw Pat_707C
	dw Pat_7080
	ORDER_LOOP Song12_Ch3
Song12_Ch2:
	dw Pat_70D7
	dw Pat_7111
	dw Pat_7163
	dw Pat_716A
	dw Pat_7171
	dw Pat_71B6
	ORDER_LOOP Song12_Ch2
Song12_Ch1:
	dw Pat_7223
	dw Pat_7238
	dw Pat_726F
	dw Pat_7274
	dw Pat_727C
	dw Pat_72C0
	ORDER_LOOP Song12_Ch1
Pat_6FD3:
	INSTR 20
	LEN 16
	NOTE A_, 2
	INSTR 11
	LEN 8
	NOTE A_, 3
	INSTR 18
	LEN 16
	NOTE A_, 3
	INSTR 20
	LEN 8
	NOTE A_, 2
	LEN 16
	NOTE D_, 2
	INSTR 11
	LEN 8
	NOTE D_, 3
	INSTR 18
	LEN 16
	NOTE D_, 4
	INSTR 20
	LEN 8
	NOTE D_, 2
	LEN 16
	NOTE E_, 2
	INSTR 11
	LEN 8
	NOTE E_, 3
	INSTR 18
	LEN 16
	NOTE E_, 4
	INSTR 20
	LEN 8
	NOTE E_, 2
	LEN 16
	NOTE A_, 2
	INSTR 11
	LEN 8
	NOTE A_, 3
	INSTR 18
	LEN 16
	NOTE A_, 3
	INSTR 20
	LEN 8
	NOTE A_, 2
	LEN 16
	NOTE A_, 2
	INSTR 11
	LEN 8
	NOTE A_, 3
	INSTR 18
	LEN 16
	NOTE A_, 3
	INSTR 20
	LEN 8
	NOTE A_, 2
	LEN 16
	NOTE D_, 2
	INSTR 11
	LEN 8
	NOTE D_, 3
	INSTR 18
	LEN 16
	NOTE D_, 4
	INSTR 20
	LEN 8
	NOTE Dsh, 2
	LEN 16
	NOTE E_, 2
	INSTR 11
	LEN 8
	NOTE E_, 3
	NEXT
Pat_701C:
	DRUMS $08, DrumPat_72FD
	TRANSPOSE $01
	PAT_CALL Pat_6FD3
	INSTR 18
	LEN 16
	NOTE E_, 4
	INSTR 20
	LEN 8
	NOTE E_, 2
	LEN 16
	NOTE A_, 2
	INSTR 11
	LEN 8
	NOTE Csh, 4
	LEN 24
	NOTE A_, 3
	NEXT
Pat_7033:
	PAT_CALL Pat_6FD3
	INSTR 20
	NOTE E_, 2
	NOTE Fsh, 2
	NOTE Gsh, 2
	LENGTH $30
	DRUMS $08, DrumPat_730A
	NOTE A_, 2
	NEXT
Pat_7042:
	INSTR 11
	LEN 24
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	LEN 16
	NOTE A_, 2
	LEN 8
	NOTE A_, 2
	LEN 24
	NOTE E_, 2
	LEN 16
	NOTE E_, 2
	LEN 8
	NOTE E_, 2
	LEN 24
	NOTE A_, 2
	LEN 16
	NOTE A_, 2
	LEN 8
	NOTE E_, 2
	LEN 24
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	LEN 16
	NOTE A_, 2
	LEN 8
	NOTE A_, 2
	LEN 24
	NOTE E_, 2
	LEN 8
	NOTE E_, 2
	NOTE Fsh, 2
	NOTE Gsh, 2
	NEXT
Pat_7066:
	DRUMS $08, DrumPat_7310
	PAT_CALL Pat_7042
	LENGTH $30
	NOTE A_, 2
	NEXT
Pat_7071:
	PAT_CALL Pat_7042
	DRUMS $08, DrumPat_730A
	LENGTH $30
	NOTE A_, 2
	NEXT
Pat_707C:
	DRUMS $08, DrumPat_72FD
Pat_7080:
	INSTR 20
	LEN 16
	NOTE B_, 1
	INSTR 11
	LEN 8
	NOTE B_, 2
	INSTR 18
	LEN 16
	NOTE D_, 5
	INSTR 20
	LEN 8
	NOTE B_, 1
	LEN 16
	NOTE E_, 2
	INSTR 11
	LEN 8
	NOTE E_, 3
	INSTR 18
	LEN 16
	NOTE E_, 5
	INSTR 20
	LEN 8
	NOTE E_, 2
	LEN 16
	NOTE B_, 2
	INSTR 11
	LEN 8
	NOTE B_, 3
	INSTR 18
	LEN 16
	NOTE D_, 5
	INSTR 20
	LEN 8
	NOTE B_, 2
	LEN 16
	NOTE E_, 2
	INSTR 11
	LEN 8
	NOTE E_, 3
	INSTR 18
	LEN 16
	NOTE E_, 5
	INSTR 20
	LEN 8
	NOTE E_, 2
	LEN 16
	NOTE B_, 1
	INSTR 11
	LEN 8
	NOTE B_, 2
	INSTR 18
	LEN 16
	NOTE D_, 5
	INSTR 20
	LEN 8
	NOTE B_, 1
	LEN 16
	NOTE E_, 2
	INSTR 11
	LEN 8
	NOTE E_, 3
	INSTR 18
	LEN 16
	NOTE E_, 5
	INSTR 20
	LEN 8
	NOTE E_, 2
	LEN 16
	NOTE B_, 2
	INSTR 11
	LEN 8
	NOTE B_, 3
	INSTR 18
	LEN 16
	NOTE D_, 5
	INSTR 20
	LEN 8
	NOTE B_, 2
	LEN 16
	NOTE E_, 2
	INSTR 11
	LEN 8
	NOTE E_, 3
	INSTR 18
	LEN 24
	NOTE E_, 5
	NEXT
Pat_70D7:
	PINGPONG
	HWENV $92, $00
	ARP 11
	DUTY_12
	RELEASE $04, $30
	VIBRATO $08, $02, $04
	LEN 8
	REST
	NOTE Csh, 5
	NOTE A_, 4
	LEN 32
	NOTE E_, 4
	LEN 8
	NOTE D_, 5
	NOTE A_, 4
	LEN 32
	NOTE Fsh, 4
	LEN 8
	NOTE E_, 5
	NOTE B_, 4
	LEN 32
	NOTE Gsh, 4
	LEN 8
	NOTE Csh, 5
	NOTE A_, 4
	LEN 32
	NOTE E_, 4
	LEN 8
	NOTE Csh, 5
	NOTE A_, 4
	LEN 32
	NOTE E_, 4
	LEN 8
	NOTE D_, 5
	NOTE A_, 4
	LEN 32
	NOTE Fsh, 4
	LEN 8
	NOTE E_, 5
	NOTE B_, 4
	LEN 16
	NOTE Gsh, 4
	LEN 8
	NOTE E_, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE E_, 4
	LEN 24
	NOTE Csh, 4
	NEXT
Pat_7111:
	LEN 8
	WAIT
	NOTE Csh, 5
	NOTE A_, 4
	LEN 32
	NOTE E_, 4
	LEN 8
	NOTE D_, 5
	NOTE A_, 4
	LEN 32
	NOTE Fsh, 4
	LEN 8
	NOTE E_, 5
	NOTE B_, 4
	LEN 32
	NOTE Gsh, 4
	LEN 8
	NOTE Csh, 5
	NOTE A_, 4
	LEN 32
	NOTE E_, 4
	LEN 8
	NOTE Csh, 5
	NOTE A_, 4
	LEN 32
	NOTE E_, 4
	LEN 8
	NOTE D_, 5
	NOTE A_, 4
	LENGTH $30
	NOTE Fsh, 4
	LEN 24
	NOTE E_, 4
	LENGTH $30
	NOTE A_, 4
	NEXT
Pat_7137:
	LEN 8
	NOTE Csh, 4
	NOTE A_, 3
	NOTE E_, 3
	NOTE Csh, 4
	NOTE A_, 3
	NOTE E_, 3
	NOTE Csh, 4
	NOTE A_, 3
	NOTE E_, 3
	NOTE Csh, 4
	NOTE A_, 3
	NOTE E_, 3
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE E_, 3
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE E_, 3
	NOTE Csh, 4
	NOTE A_, 3
	NOTE E_, 3
	NOTE Csh, 4
	NOTE A_, 3
	NOTE E_, 3
	NOTE Csh, 4
	NOTE A_, 3
	NOTE E_, 3
	NOTE Csh, 4
	NOTE A_, 3
	NOTE E_, 3
	NOTE Csh, 4
	NOTE A_, 3
	NOTE E_, 3
	NOTE Csh, 4
	NOTE A_, 3
	NOTE E_, 3
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE E_, 3
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE E_, 3
	NEXT
Pat_7163:
	PAT_CALL Pat_7137
	LEN 24
	NOTE A_, 3
	NOTE A_, 6
	NEXT
Pat_716A:
	PAT_CALL Pat_7137
	LENGTH $30
	NOTE A_, 3
	NEXT
Pat_7171:
	LEN 16
	NOTE B_, 3
	LEN 8
	NOTE B_, 3
	LEN 16
	NOTE D_, 4
	LEN 8
	NOTE D_, 4
	LEN 16
	NOTE E_, 4
	LEN 8
	NOTE E_, 4
	LEN 16
	NOTE Gsh, 4
	LEN 8
	NOTE E_, 4
	LEN 16
	NOTE B_, 3
	LEN 8
	NOTE B_, 3
	LEN 16
	NOTE D_, 4
	LEN 24
	NOTE E_, 4
	LEN 8
	NOTE E_, 4
	NOTE Gsh, 4
	NOTE E_, 4
	NOTE Csh, 4
	LEN 16
	NOTE B_, 3
	LEN 8
	NOTE B_, 3
	LEN 16
	NOTE D_, 4
	LEN 8
	NOTE D_, 4
	LEN 16
	NOTE E_, 4
	LEN 8
	NOTE E_, 4
	LEN 16
	NOTE Gsh, 4
	LEN 8
	NOTE E_, 4
	LEN 16
	NOTE Fsh, 4
	LEN 8
	NOTE A_, 4
	LEN 16
	NOTE Csh, 5
	LEN 8
	NOTE A_, 4
	LEN 24
	NOTE B_, 4
	HWENV $49, $02, $70
	ARP_OFF
	DUTY_75
	RELEASE $01, $62
	LEN 8
	NOTE Fsh, 5
	NOTE E_, 5
	NOTE Dsh, 5
	NEXT
Pat_71B6:
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE Fsh, 5
	NOTE A_, 5
	WAIT2
	NOTE Csh, 6
	LEN 16
	NOTE B_, 5
	LEN 8
	NOTE Gsh, 5
	NOTE E_, 5
	WAIT2
	NOTE Dsh, 5
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE Fsh, 5
	NOTE A_, 5
	NOTE Csh, 6
	LEN 24
	NOTE B_, 5
	LEN 8
	WAIT2
	NOTE Fsh, 5
	NOTE E_, 5
	NOTE Dsh, 5
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE Fsh, 5
	NOTE A_, 5
	WAIT2
	NOTE Csh, 6
	LEN 16
	NOTE B_, 5
	LEN 8
	NOTE Gsh, 5
	NOTE D_, 5
	WAIT2
	NOTE E_, 5
	LEN 16
	NOTE Fsh, 5
	LEN 8
	NOTE A_, 5
	NOTE Csh, 6
	NOTE D_, 6
	LEN 32
	NOTE B_, 5
	LEN 24
	WAIT2
	RELEASE $00
	NEXT
Pat_71EC:
	LEN 16
	NOTE E_, 5
	LEN 8
	GLISS_3
	NOTE E_, 5
	LEN 16
	NOTE A_, 5
	LEN 8
	NOTE Gsh, 5
	LEN 16
	NOTE Fsh, 5
	LEN 8
	NOTE Fsh, 5
	LEN 16
	NOTE B_, 5
	LEN 8
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE Gsh, 5
	LEN 16
	NOTE Csh, 6
	LEN 8
	NOTE B_, 5
	LEN 16
	NOTE A_, 5
	LEN 8
	NOTE A_, 5
	NOTE Csh, 5
	NOTE D_, 5
	NOTE Dsh, 5
	LEN 16
	NOTE E_, 5
	LEN 8
	NOTE E_, 5
	LEN 16
	NOTE A_, 5
	LEN 8
	NOTE Gsh, 5
	LEN 16
	NOTE Fsh, 5
	LEN 8
	NOTE Fsh, 5
	LEN 16
	NOTE B_, 5
	LEN 8
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE Gsh, 5
	LEN 16
	NOTE Csh, 6
	LEN 8
	NOTE B_, 5
	NEXT
Pat_7223:
	PINGPONG
	HWENV $D1, $08, $20
	VIBRATO $08, $02, $02
	ARP_OFF
	DUTY_50
	PAT_CALL Pat_71EC
	LEN 24
	NOTE A_, 5
	LEN 8
	NOTE Csh, 5
	NOTE D_, 5
	NOTE Dsh, 5
	NEXT
Pat_7238:
	PAT_CALL Pat_71EC
	LENGTH $30
	NOTE A_, 5
	NEXT
Pat_723F:
	LEN 24
	NOTE Csh, 5
	NOTE A_, 4
	NOTE Fsh, 4
	LEN 16
	NOTE E_, 4
	LEN 8
	NOTE Csh, 4
	NOTE D_, 4
	NOTE Csh, 4
	NOTE D_, 4
	LEN 16
	NOTE Fsh, 4
	LEN 8
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE E_, 4
	LEN 16
	NOTE Csh, 5
	LEN 8
	NOTE Csh, 5
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE A_, 4
	LEN 16
	NOTE Fsh, 4
	LEN 8
	NOTE Fsh, 4
	LEN 16
	NOTE E_, 4
	LEN 8
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE Gsh, 4
	LEN 24
	NOTE A_, 4
	NEXT
Pat_726F:
	PAT_CALL Pat_723F
	NOTE A_, 5
	NEXT
Pat_7274:
	PAT_CALL Pat_723F
	LEN 8
	NOTE D_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NEXT
Pat_727C:
	LEN 16
	NOTE B_, 4
	LEN 8
	NOTE D_, 5
	LEN 16
	NOTE Fsh, 5
	LEN 8
	NOTE A_, 5
	LEN 16
	NOTE Gsh, 5
	LEN 8
	NOTE E_, 5
	LEN 16
	NOTE Csh, 5
	LEN 8
	NOTE C_, 5
	LEN 16
	NOTE B_, 4
	LEN 8
	NOTE D_, 5
	NOTE Fsh, 5
	NOTE A_, 5
	LEN 32
	NOTE Gsh, 5
	LEN 8
	NOTE D_, 5
	NOTE Csh, 5
	NOTE C_, 5
	LEN 16
	NOTE B_, 4
	LEN 8
	NOTE D_, 5
	LEN 16
	NOTE Fsh, 5
	LEN 8
	NOTE A_, 5
	LEN 16
	NOTE Gsh, 5
	LEN 8
	NOTE E_, 5
	LEN 16
	NOTE B_, 4
	LEN 8
	NOTE Csh, 5
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE Fsh, 5
	LEN 16
	NOTE A_, 5
	LEN 8
	NOTE Fsh, 5
	LEN 24
	NOTE Gsh, 5
	HWENV $49, $02, $70
	ARP_OFF
	DUTY_75
	RELEASE $01, $62
	LEN 8
	NOTE D_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NEXT
Pat_72C0:
	LEN 16
	NOTE B_, 4
	LEN 8
	NOTE D_, 5
	NOTE Fsh, 5
	WAIT2
	NOTE A_, 5
	LEN 16
	NOTE Gsh, 5
	LEN 8
	NOTE E_, 5
	NOTE Csh, 5
	WAIT2
	NOTE C_, 5
	LEN 16
	NOTE B_, 4
	LEN 8
	NOTE D_, 5
	NOTE Fsh, 5
	NOTE A_, 5
	LEN 24
	NOTE Gsh, 5
	LEN 8
	WAIT2
	NOTE D_, 5
	NOTE Csh, 5
	NOTE C_, 5
	LEN 16
	NOTE B_, 4
	LEN 8
	NOTE D_, 5
	NOTE Fsh, 5
	WAIT2
	NOTE A_, 5
	LEN 16
	NOTE Gsh, 5
	LEN 8
	NOTE E_, 5
	NOTE B_, 4
	WAIT2
	NOTE Csh, 5
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE Fsh, 5
	NOTE A_, 5
	NOTE B_, 5
	LEN 32
	NOTE Gsh, 5
	RELEASE $00
	HWENV $D1, $08, $20
	DUTY_50
	LEN 8
	NOTE Csh, 5
	NOTE D_, 5
	NOTE Dsh, 5
	NEXT
DrumPat_72FD:
	db 1, 0, 6, 2, 0, 6, 1, 0
	db 6, 2, 0, 4, DRUM_LOOP
DrumPat_730A:
	db 7, 0, 2, 2, 0, 2
DrumPat_7310:
	db 14, 0, 0, 14, 0, 0, 14, 0
	db 0, 14, 0, 2, DRUM_LOOP

; Instrument table 2, entries 1..14 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr2_0
	dw Instr2_1
	dw Instr2_1
	dw Instr2_1
	dw Instr2_1
	dw Instr2_5
	dw Instr2_6
	dw Instr2_6
	dw Instr2_8
	dw Instr2_8
	dw Instr2_10
	dw Instr2_10
	dw Instr2_12
	dw Instr2_13
Instr2_0:
	VOLENV 15, $11, $1F, $12
	WAVE Wave_7D77
	END
Instr2_1:
	VOLENV 13, $01, $1F, $12
	ARP 14
	WAVE Wave_7D57
	END
Instr2_5:
	VOLENV 13, $01, $1F, $12
	ARP 15
	WAVE Wave_7D57
	END
Instr2_6:
	HWENV $C2, $07, $64
	RELEASE $00
	END
Instr2_8:
	HWENV $C1, $07, $52
	ARP 11
	DUTY_12
	RELEASE $00
	END
Instr2_10:
	VOLENV 15, $12, $2F, $11
	ARP 0
	WAVE Wave_7D57
	END
Instr2_12:
	VOLENV 15, $00, $1F, $12
	ARP 0
	WAVE Wave_7D57
	END
Instr2_13:
	HWENV $C1, $04, $60
	DUTY_75
	RELEASE $02, $20
	END

; Instrument table 3, entries 1..21 (the song routines point 2 bytes before:
; entry 0 is never read)
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
	dw Instr3_10
	dw Instr3_11
	dw Instr3_12
	dw Instr3_13
	dw Instr3_14
	dw Instr3_15
	dw Instr3_16
	dw Instr3_17
	dw Instr3_18
	dw Instr3_19
	dw Instr3_20
Instr3_0:
	HWENV $F1, $00
	ARP 0
	DUTY_12
	END
Instr3_1:
	HWENV $D1, $06, $53
	ARP 11
	DUTY_75
	END
Instr3_2:
	HWENV $B0, $06, $40
	ARP 11
	END
Instr3_3:
	HWENV $B0, $06, $40
	ARP 2
	END
Instr3_4:
	HWENV $A2, $04, $52
	ARP 4
	AUTODUTY $03
	END
Instr3_5:
	HWENV $A2, $04, $52
	ARP 5
	AUTODUTY $03
	END
Instr3_7:
	VOLENV 5, $00, $00, $00
	AUTOPAN $03
	ARP 0
	END
Instr3_6:
	VOLENV 10, $11, $1F, $12
	ARP 0
	END
Instr3_8:
	HWENV $C1, $02, $42
	DUTY_12
	ARP 0
	END
Instr3_9:
	HWENV $D0, $06, $50
	ARP 0
	DUTY_12
	END
Instr3_10:
	VOLENV 15, $11, $1F, $12
	WAVE Wave_7D67
	END
Instr3_11:
	VOLENV 13, $00, $1F, $12
	ARP 11
	WAVE Wave_7D57
	END
Instr3_12:
	HWENV $C1, $05, $70
	DUTY_50
	END
Instr3_13:
	VOLENV 15, $14, $FF, $11
	GLIDE $FB
	WAVE Wave_74DA
	END
Instr3_14:
	VOLENV 12, $11, $1A, $11
	ARP 4
	WAVE Wave_7E07
	END
Instr3_15:
	VOLENV 12, $11, $1A, $11
	ARP 5
	WAVE Wave_7E07
	END
Instr3_16:
	VOLENV 15, $13, $1F, $12
	ARP 0
	WAVE Wave_7DB7
	END
Instr3_17:
	VOLENV 15, $11, $1F, $13
	WAVE Wave_7DF7
	END
Instr3_18:
	VOLENV 13, $01, $1F, $12
	ARP 14
	WAVE Wave_7D57
	END
Instr3_19:
	VOLENV 13, $01, $1F, $12
	ARP 15
	WAVE Wave_7D57
	END
Instr3_20:
	VOLENV 15, $11, $1F, $12
	WAVE Wave_7D77
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
	dw Arp9
	dw Arp9
	dw Arp12
	dw Arp12
	dw Arp12
	dw Arp15

; Unreferenced (16 bytes)
	db $BF, $74, $BF, $74, $BF, $74, $BF, $74, $BF, $74, $C2, $74, $C2, $74, $C2, $74
Arp0:
	db $0C, $00, ARP_HOLD
Arp3:
	db $00, $00, $01, $01, $02, ARP_HOLD
Arp2:
	db $00, $0E, $01, $01, $02, ARP_HOLD
Arp1:
	db $0C, $0C, $00, $00, ARP_LOOP
Arp4:
	db $00, $04, $07, ARP_LOOP
Arp5:
	db $00, $03, $07, ARP_LOOP
Arp6:
	db $00, $0C, $00, $00, $00, $00, $00, ARP_LOOP
Arp7:
	db $00, $01, $02, ARP_HOLD
Arp8:
	db $00, $00, $00, $00, $00, $0C, $0C, $0C
	db $0C, ARP_LOOP
Arp9:
	db $00, $0C, $00, ARP_HOLD
Arp12:
	db $00, $00, $04, $04, $07, $07, ARP_LOOP
Arp15:
	db $00, $00, $03, $03, $07, $07, ARP_LOOP

; Unreferenced (3 bytes)
	db $00, $0C, $6A

; PlaySong table: A = 0-11
SongTable:
	dw PlaySong1                        ; A = 0: song 1
	dw PlaySong2                        ; A = 1: song 2
	dw PlaySong3                        ; A = 2: song 3
	dw PlaySong4                        ; A = 3: song 4
	dw PlaySong5                        ; A = 4: song 5
	dw PlaySong6                        ; A = 5: song 6
	dw PlaySong7                        ; A = 6: song 7
	dw PlaySong8                        ; A = 7: song 8
	dw PlaySong9                        ; A = 8: song 9
	dw PlaySong10                       ; A = 9: song 10
	dw PlaySong11                       ; A = 10: song 11
	dw PlaySong12                       ; A = 11: song 12
Wave_74DA:
	db $FF, $FF, $FD, $B8, $53, $10, $00, $00
	db $00, $00, $01, $35, $8B, $DF, $FF, $FF

; SFX table (indexed from 2 bytes before: id 1 is the first entry)
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
	dw Sfx25
	dw Sfx26
	dw Sfx27
	dw Sfx28
	dw Sfx29
	dw Sfx30
	dw Sfx31
	dw Sfx32
	dw Sfx33
	dw Sfx34
	dw Sfx35
	dw Sfx36
	dw Sfx37
	dw Sfx38

; Sound effect 3
Sfx03:
	WAVE Wave_74DA
	PAN_R
	VOLENV 15, $00, $00, $00
	GLIDE $FD
	LEN 3
	NOTE G_, 5
	END

; Sound effect 4
Sfx04:
	WAVE Wave_74DA
	VOLENV 15, $00, $00, $00
	GLIDE $FD
	LEN 3
	NOTE Dsh, 5
	END

; Sound effect 5
Sfx05:
	WAVE Wave_74DA
	PAN_L
	VOLENV 15, $00, $00, $00
	GLIDE $FD
	LEN 3
	NOTE B_, 4
	END

; Sound effect 1
Sfx01:
	WAVE Wave_74DA
	VOLENV 15, $00, $00, $00
	LEN 1
	NOTE D_, 4
	NOTE Gsh, 3
	END

; Sound effect 2
Sfx02:
	WAVE Wave_74DA
	VOLENV 15, $00, $00, $00
	LEN 1
	NOTE B_, 4
	NOTE Gsh, 4
	END

; Sound effect 31
Sfx31:
	VOLENV 15, $00, $00, $00
	WAVE Wave_7D17
	GLIDE $03
	LEN 5
	NOTE A_, 3
	CALL_CODE Code_77D5
	END

; Sound effect 32
Sfx32:
	WAVE Wave_7D57
	VOLENV 15, $11, $1F, $13
	CALL_CODE Code_7CC4
	LEN 20
	NOTE A_, 6
	END

; Sound effect 29
Sfx29:
	WAVE Wave_7DA7
	VOLENV 15, $11, $1F, $11
	GLIDE $02
	LEN 7
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE Gsh, 4
	END

; Sound effect 28
Sfx28:
	WAVE Wave_7D17
	CALL_CODE Code_7810
	VOLENV 10, $00, $00, $00
	LEN 8
	GLIDE $FC
	NOTE A_, 7
	LEN 10
	GLIDE $FF
	WAIT
	WAIT
	END

; Sound effect 25
Sfx25:
	WAVE Wave_7D07
	VOLENV 5, $1F, $00, $20
	CALL_CODE Code_7897
	LEN 21
	NOTE Gsh, 3
	END

; Sound effect 24
Sfx24:
	CALL_CODE Code_7C8B
	END

; Sound effect 26
Sfx26:
	WAVE Wave_7E07
	VOLENV 15, $00, $00, $00
	GLIDE $04
	LEN 5
	NOTE A_, 5
	GLIDE $FE
	WAIT
	WAIT
	GLIDE $FF
	WAIT
	END

; Sound effect 27
Sfx27:
	WAVE Wave_7DC7
	VOLENV 15, $00, $00, $00
	LEN 5
	ARP 20
	NOTE A_, 5
	REST
	REST
	NOTE G_, 5
	NOTE Fsh, 5
	REST
	NOTE E_, 5
	REST
	NOTE D_, 5
	END

; Sound effect 23
Sfx23:
	WAVE Wave_7DC7
	VOLENV 15, $00, $00, $00
	LEN 6
	ARP 20
	RELEASE $02, $11
	NOTE D_, 5
	NOTE Fsh, 5
	NOTE A_, 5
	NOTE D_, 6
	REST
	NOTE C_, 6
	NOTE D_, 6
	WAIT
	WAIT
	END

; Sound effect 38
Sfx38:
	WAVE Wave_7D17
	VOLENV 10, $11, $1F, $14
	CALL_CODE Code_78DE
	LEN 2
	NOTE A_, 6
	REST
	LEN 48
	NOTE A_, 7
	END

; Sound effect 14
Sfx14:
	WAVE Wave_7DA7
	VOLENV 15, $00, $00, $00
	LEN 14
	GLIDE $01
	VIBRATO $00, $64, $02
	CALL_CODE Code_7919
	NOTE A_, 2
	GLIDE_OFF
	LENGTH $F1
	WAIT
	END

; Sound effect 13
Sfx13:
	CALL_CODE Code_7943
	END

; Sound effect 15
Sfx15:
	WAVE Wave_7D17
	CALL_CODE Code_7997
	VOLENV 15, $00, $00, $00
	LEN 2
	GLIDE $FD
	NOTE D_, 4
	REST
	NOTE A_, 3
	END

; Sound effect 8
Sfx08:
	CALL_CODE Code_79D0
	WAVE Wave_7DA7
	VOLENV 15, $00, $00, $00
	GLIDE $FD
	LEN 8
	NOTE A_, 5
	END

; Sound effect 7
Sfx07:
	CALL_CODE Code_7A0B
	WAVE Wave_7D97
	VOLENV 10, $11, $1F, $13
	LEN 20
	SLIDE_DOWN $01
	NOTE A_, 7
	END

; Sound effect 16
Sfx16:
	CALL_CODE Code_7B3C
	END

; Sound effect 9
Sfx09:
	CALL_CODE Code_7C34
	VOLENV 10, $11, $1F, $11
	WAVE Wave_7D17
	LEN 10
	ARP 5
	GLIDE $01
	NOTE A_, 7
	NOTE A_, 7
	END

; Sound effect 35
Sfx35:
	VOLENV 12, $11, $1F, $14
	WAVE Wave_7D37
	GLIDE $04
	LEN 4
	NOTE A_, 3
	GLIDE $FD
	LEN 4
	WAIT
	REST
	GLIDE $04
	LEN 4
	NOTE G_, 3
	GLIDE $FD
	LEN 4
	WAIT
	REST
	GLIDE $04
	LEN 4
	NOTE Fsh, 3
	GLIDE $FD
	LEN 6
	WAIT
	REST
	END

; Sound effect 36
Sfx36:
	VOLENV 15, $11, $1F, $16
	LEN 6
	WAVE Wave_7E17
	GLIDE $03
	NOTE F_, 5
	LEN 1
	GLIDE $01
	WAIT
	GLIDE_OFF
	LEN 10
	VIBRATO $01, $04, $01
	NOTE C_, 7
	LEN 4
	GLIDE $02
	WAIT
	GLIDE $FE
	WAIT
	END

; Sound effect 22
Sfx22:
	VOLENV 15, $13, $FF, $11
	LEN 5
	GLIDE $FF
	WAVE Wave_7DE7
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE Gsh, 3
	NOTE Fsh, 3
	NOTE A_, 2
	END

; Sound effect 30
Sfx30:
	CALL_CODE Code_7A87
	END

; Sound effect 10
Sfx10:
	VOLENV 15, $00, $00, $00
	LEN 10
	WAVE Wave_7DA7
	CALL_CODE Code_7AC2
	GLIDE $FD
	NOTE A_, 4
	END

; Sound effect 11
Sfx11:
	VOLENV 15, $00, $00, $00
	LEN 6
	WAVE Wave_7D17
	CALL_CODE Code_7B01
	GLIDE $FC
	AUTOPAN $04
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	VOLENV 10, $00, $00, $00
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	END

; Sound effect 33
Sfx33:
	VOLENV 5, $4F, $1F, $11
	LEN 3
	WAVE Wave_7D17
	GLIDE $01
	NOTE A_, 4
	LEN 1
	REST
	LEN 3
	NOTE A_, 4
	LEN 1
	REST
	LEN 3
	NOTE Ash, 4
	LEN 1
	REST
	LEN 4
	NOTE B_, 4
	VOLENV 10, $00, $00, $00
	PAN_R
	NOTE Ash, 4
	PAN_L
	NOTE B_, 4
	END

; Sound effect 34
Sfx34:
	WAVE Wave_7D57
	CALL_CODE Code_7B81
	GLIDE $04
	LEN 10
	VOLENV 15, $00, $00, $00
	NOTE A_, 3
	VOLENV 10, $00, $00, $00
	PAN_R
	NOTE A_, 3
	VOLENV 5, $00, $00, $00
	PAN_L
	NOTE A_, 3
	END

; Sound effect 19
Sfx19:
	VOLENV 15, $00, $00, $00
	WAVE Wave_7D97
	CALL_CODE Code_7BC6
	GLIDE $03
	LEN 10
	NOTE A_, 3
	END

; Sound effect 17
Sfx17:
	VOLENV 15, $00, $00, $00
	WAVE Wave_7D17
	CALL_CODE Code_7BF9
	LEN 1
	NOTE A_, 4
	REST
	NOTE Dsh, 5
	LEN 8
	REST
	LEN 1
	NOTE A_, 3
	END

; Sound effect 18
Sfx18:
	VOLENV 15, $11, $1F, $12
	LEN 6
	WAVE Wave_7D17
	GLIDE $FC
	NOTE D_, 4
	WAVE Wave_7D87
	LEN 13
	GLIDE $01
	VIBRATO $00, $50, $03
	NOTE A_, 3
	END

; Sound effect 37
Sfx37:
	VOLENV 15, $00, $00, $00
	LEN 4
	CH_TRANSPOSE $18
	WAVE Wave_7DC7
	GLIDE $02
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	VOL $0A
	PAN_R
	NOTE A_, 4
	NOTE B_, 4
	VOL $05
	PAN_L
	NOTE A_, 4
	NOTE B_, 4
	END

; Sound effect 12
Sfx12:
	CALL_CODE Code_7A46
	VOLENV 15, $11, $FF, $11
	WAVE Wave_7D17
	LEN 4
	NOTE G_, 5
	NOTE B_, 5
	END

; Sound effect 20
Sfx20:
	VOLENV 15, $11, $2F, $11
	WAVE Wave_7D67
	LEN 8
	NOTE C_, 6
	VOLENV 10, $11, $2F, $11
	PAN_R
	NOTE C_, 6
	VOLENV 5, $11, $2F, $11
	PAN_L
	NOTE C_, 6
	END

; Sound effect 21
Sfx21:
	LEN 4
	VOLENV 15, $11, $2F, $11
	WAVE Wave_7D67
	LEN 4
	NOTE Gsh, 5
	LEN 1
	REST
	LEN 4
	NOTE Gsh, 6
	VOL $0A
	PAN_L
	LEN 4
	NOTE Gsh, 5
	LEN 1
	REST
	LEN 4
	NOTE Gsh, 6
	VOL $05
	PAN_R
	LEN 4
	NOTE Gsh, 5
	LEN 1
	REST
	LEN 4
	NOTE Gsh, 6
	END

; Sound effect 6
Sfx06:
	LEN 5
	ARP 0
	WAVE Wave_7DC7
	VOLENV 15, $10, $00, $10
	RELEASE $02, $11
	NOTE C_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	END
Code_77D5:
	ld a, $88
	ld [wNoisePan], a
	ld a, $04
	ld [wDrumHold], a
	ld a, $00
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7805)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7805)
	ld [wNoise43], a
	ld a, HIGH(Noise42_780B)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_780B)
	ld [wNoise42], a
	ret
Noise43_7805:
	db $00, $53, $71, $91, $31, $FF
Noise42_780B:
	db $F1, $FF, $FF, $FF, $00
Code_7810:
	ld a, $88
	ld [wNoisePan], a
	ld a, $18
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $01
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_7870)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7870)
	ld [wNoise43], a
	ld a, HIGH(Noise42_788A)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_788A)
	ld [wNoise42], a
	ret

; Unreferenced (48 bytes)
	db $3E, $88, $EA, $43, $D2, $3E, $0F, $EA, $44, $D2, $AF, $EA, $58, $D2, $3C, $EA
	db $59, $D2, $3E, $00, $EA, $5C, $D2, $AF, $EA, $5B, $D2, $3E, $78, $EA, $54, $D2
	db $3E, $7D, $EA, $55, $D2, $3E, $78, $EA, $56, $D2, $3E, $8A, $EA, $57, $D2, $C9
Noise43_7870:
	db $10, $10, $20, $31, $32, $33, $33, $34
	db $34, $35, $35, $36, $FF

; Unreferenced (13 bytes)
	db $36, $35, $35, $34, $34, $33, $33, $32, $31, $20, $10, $10, $FF
Noise42_788A:
	db $5C, $FF, $FF, $FF, $FF, $FF, $A1, $FF
	db $FF, $FF, $FF, $FF

; Unreferenced (1 bytes)
	db $FF
Code_7897:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $00
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $13
	ld [wDrumHold], a
	ld a, $F2
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ld a, HIGH(Noise43_78CF)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_78CF)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_78CF:
	db $18, $3A, $47, $49, $2E, $2D, $1C, $28
	db $4A, $57, $39, $4E, $1D, $0C, $FF
Code_78DE:
	ld a, $88
	ld [wNoisePan], a
	ld a, $32
	ld [wDrumHold], a
	ld a, $00
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_790E)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_790E)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7914)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7914)
	ld [wNoise42], a
	ret
Noise43_790E:
	db $30, $20, $D0, $D0, $11, $FF
Noise42_7914:
	db $F1, $F1, $F1, $F1, $86
Code_7919:
	ld a, $88
	ld [wNoisePan], a
	ld a, $DD
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7940)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7940)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7942)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7942)
	ld [wNoise42], a
	ret
Noise43_7940:
	db $11, $FF
Noise42_7942:
	db $30
Code_7943:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $14
	ld [wDrumHold], a
	ld a, HIGH(Noise43_796A)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_796A)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7981)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7981)
	ld [wNoise42], a
	ret
Noise43_796A:
	db $90, $90, $90, $90, $90, $90, $90, $90
	db $90, $90, $90, $A0, $A0, $A0, $A0, $A0
	db $A0, $A0, $A0, $A0, $A0, $A0, $FF
Noise42_7981:
	db $F0, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $F0, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $00
Code_7997:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $14
	ld [wDrumHold], a
	ld a, $02
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_79C7)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_79C7)
	ld [wNoise43], a
	ld a, HIGH(Noise42_79CC)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_79CC)
	ld [wNoise42], a
	ret
Noise43_79C7:
	db $71, $00, $00, $61, $FF
Noise42_79CC:
	db $F1, $11, $11, $F1
Code_79D0:
	ld a, $88
	ld [wNoisePan], a
	ld a, $14
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $00
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_7A00)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7A00)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7A06)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7A06)
	ld [wNoise42], a
	ret
Noise43_7A00:
	db $50, $11, $16, $24, $34, $FF
Noise42_7A06:
	db $F1, $FF, $FF, $FF, $FF
Code_7A0B:
	ld a, $88
	ld [wNoisePan], a
	ld a, $14
	ld [wDrumHold], a
	ld a, $01
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7A3B)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7A3B)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7A41)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7A41)
	ld [wNoise42], a
	ret
Noise43_7A3B:
	db $10, $12, $14, $16, $17, $FF
Noise42_7A41:
	db $59, $FF, $FF, $FF, $82
Code_7A46:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0A
	ld [wDrumHold], a
	ld a, $00
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7A76)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7A76)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7A7F)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7A7F)
	ld [wNoise42], a
	ret
Noise43_7A76:
	db $78, $78, $78, $78, $58, $56, $56, $68
	db $FF
Noise42_7A7F:
	db $A1, $FF, $11, $00, $81, $FF, $11, $00
Code_7A87:
	ld a, $88
	ld [wNoisePan], a
	ld a, $19
	ld [wDrumHold], a
	ld a, $00
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7AB7)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7AB7)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7ABD)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7ABD)
	ld [wNoise42], a
	ret
Noise43_7AB7:
	db $02, $41, $26, $71, $31, $FF
Noise42_7ABD:
	db $F0, $FF, $FF, $A0, $D2
Code_7AC2:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $00
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_7AF2)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7AF2)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7AFA)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7AFA)
	ld [wNoise42], a
	ret
Noise43_7AF2:
	db $02, $41, $61, $71, $91, $71, $62, $FF
Noise42_7AFA:
	db $F0, $F9, $F9, $F9, $F0, $70, $A2
Code_7B01:
	ld a, $88
	ld [wNoisePan], a
	ld a, $2B
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $02
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_7B31)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B31)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B37)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B37)
	ld [wNoise42], a
	ret
Noise43_7B31:
	db $03, $93, $80, $72, $71, $FF
Noise42_7B37:
	db $F0, $FF, $FF, $FF, $F3
Code_7B3C:
	ld a, $88
	ld [wNoisePan], a
	ld a, $50
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $03
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_7B6C)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B6C)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B77)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B77)
	ld [wNoise42], a
	ret
Noise43_7B6C:
	db $57, $46, $45, $44, $43, $42, $41, $40
	db $21, $20, $FF
Noise42_7B77:
	db $19, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $F5
Code_7B81:
	ld a, $88
	ld [wNoisePan], a
	ld a, $23
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $01
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_7BB1)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7BB1)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7BBC)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7BBC)
	ld [wNoise42], a
	ret
Noise43_7BB1:
	db $27, $26, $25, $14, $13, $12, $11, $10
	db $10, $10, $FF
Noise42_7BBC:
	db $19, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $F2
Code_7BC6:
	ld a, $88
	ld [wNoisePan], a
	ld a, $19
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $00
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_7BF6)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7BF6)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7BF8)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7BF8)
	ld [wNoise42], a
	ret
Noise43_7BF6:
	db $32, $FF
Noise42_7BF8:
	db $F1
Code_7BF9:
	ld a, $88
	ld [wNoisePan], a
	ld a, $08
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $00
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_7C29)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7C29)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7C2F)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7C2F)
	ld [wNoise42], a
	ret
Noise43_7C29:
	db $22, $32, $42, $44, $00, $FF
Noise42_7C2F:
	db $F1, $F1, $F1, $F1, $00
Code_7C34:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $00
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $13
	ld [wDrumHold], a
	call NoisePanCentre
	ld a, $F2
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ld a, HIGH(Noise43_7C6F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7C6F)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_7C6F:
	db $12, $64, $02, $37, $47, $24, $55, $71
	db $07, $44, $60, $36, $84, $82, $64, $02
	db $37, $47, $24, $55, $71, $07, $44, $60
	db $36, $86, $32, $FF
Code_7C8B:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $C2
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ld a, HIGH(Noise43_7CBA)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7CBA)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_7CBA:
	db $12, $92, $42, $42, $42, $42, $52, $65
	db $45, $FF
Code_7CC4:
	ld a, $88
	ld [wNoisePan], a
	ld a, $08
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $00
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_7CF4)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7CF4)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7CF6)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7CF6)
	ld [wNoise42], a
	ret
Noise43_7CF4:
	db $32, $FF
Noise42_7CF6:
	db $A3

; Unreferenced (16 bytes)
	db $00, $36, $8A, $FF, $FF, $A8, $63, $00, $00, $36, $8A, $FF, $FF, $A8, $63, $00
Wave_7D07:
	db $B7, $40, $F4, $7B, $FD, $FF, $FE, $DC
	db $02, $46, $8A, $BD, $FD, $BA, $6F, $20
Wave_7D17:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
Wave_7D27:
	db $02, $22, $22, $00, $89, $CC, $CC, $98
	db $04, $44, $44, $00, $CC, $CC, $CC, $CC
Wave_7D37:
	db $00, $00, $00, $00, $CD, $EF, $FD, $EC
	db $00, $12, $21, $00, $DD, $DD, $DD, $DD

; Unreferenced (16 bytes)
	db $00, $00, $00, $00, $00, $00, $FF, $FF, $00, $00, $00, $00, $00, $00, $FF, $FF
Wave_7D57:
	db $00, $00, $00, $00, $00, $00, $FF, $00
	db $00, $00, $00, $00, $00, $00, $FF, $00
Wave_7D67:
	db $00, $00, $00, $CD, $EF, $FF, $FF, $FF
	db $04, $8C, $FF, $FF, $FF, $FF, $FF, $FF
Wave_7D77:
	db $48, $FF, $FF, $FF, $FF, $FF, $FF, $84
	db $00, $66, $06, $60, $00, $4F, $FF, $88
Wave_7D87:
	db $EC, $96, $31, $90, $00, $00, $00, $00
	db $24, $69, $CE, $FF, $FF, $FF, $FF, $FF
Wave_7D97:
	db $12, $34, $56, $78, $9A, $BC, $DE, $FF
	db $ED, $CB, $A9, $87, $65, $43, $21, $00
Wave_7DA7:
	db $63, $10, $40, $20, $00, $00, $01, $36
	db $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9
Wave_7DB7:
	db $63, $10, $01, $47, $74, $10, $01, $36
	db $9C, $EF, $FE, $B8, $8B, $EF, $FE, $C9
Wave_7DC7:
	db $63, $1F, $01, $47, $74, $10, $01, $36
	db $9C, $E0, $FE, $B8, $8B, $EF, $FE, $C9
Wave_7DD7:
	db $B7, $40, $04, $7B, $CD, $FF, $FE, $DC
	db $02, $46, $8A, $BD, $FD, $BA, $64, $20
Wave_7DE7:
	db $0F, $00, $F0, $F0, $F0, $F0, $00, $0F
	db $0F, $FF, $FF, $00, $FF, $F0, $0F, $0F
Wave_7DF7:
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $ED, $CB, $A9, $87, $65, $43, $21, $00
Wave_7E07:
	db $20, $24, $68, $AC, $EC, $A8, $64, $20
	db $24, $68, $A8, $64, $20, $24, $68, $64
Wave_7E17:
	db $02, $48, $AC, $FF, $FC, $53, $00, $27
	db $9C, $DD, $DC, $B7, $7B, $CD, $DD, $C9
Noise43_7E27:
	db $21, $22, $23, $FF
Noise42_7E2B:
	db $A3, $FF, $54
Noise43_7E2E:
	db $21, $21, $FF
Noise42_7E31:
	db $61, $31
Noise43_7E33:
	db $21, $21, $FF
Noise42_7E36:
	db $81, $31
Noise43_7E38:
	db $21, $21, $FF
Noise42_7E3B:
	db $81, $43
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7E63)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7E63)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7E66)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7E66)
	ld [wNoise42], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $01
	jp PlaySfx
Noise43_7E63:
	db $20, $15, $FF
Noise42_7E66:
	db $A0, $41
Drum2:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7E8E)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7E8E)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7E91)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7E91)
	ld [wNoise42], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $02
	jp PlaySfx
Noise43_7E8E:
	db $20, $32, $FF
Noise42_7E91:
	db $A0, $52
Drum3:
	ret
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7E38)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7E38)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7E3B)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7E3B)
	ld [wNoise42], a
	ret
Drum14:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7E38)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7E38)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7E3B)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7E3B)
	ld [wNoise42], a
	ld a, $01
	jp PlaySfx

; Unreferenced (1 bytes)
	db $C9
Drum5:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7E33)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7E33)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7E36)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7E36)
	ld [wNoise42], a
	ret
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7E2E)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7E2E)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7E31)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7E31)
	ld [wNoise42], a
	ret
Drum7:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7E27)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7E27)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7E2B)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7E2B)
	ld [wNoise42], a
	ld a, $01
	jp PlaySfx

; Unreferenced (1 bytes)
	db $C9
Drum8:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7FCB)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7FCB)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7FCE)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7FCE)
	ld [wNoise42], a
	ld a, $08
	ld [wNoisePan], a
	ld a, $03
	jp PlaySfx

; Unreferenced (1 bytes)
	db $C9
Drum9:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7FCB)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7FCB)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7FCE)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7FCE)
	ld [wNoise42], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $04
	jp PlaySfx

; Unreferenced (1 bytes)
	db $C9
Drum10:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7FCB)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7FCB)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7FCE)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7FCE)
	ld [wNoise42], a
	ld a, $80
	ld [wNoisePan], a
	ld a, $05
	jp PlaySfx

; Unreferenced (1 bytes)
	db $C9
Drum13:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7FD0)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7FD0)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7FD3)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7FD3)
	ld [wNoise42], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $01
	jp PlaySfx

; Unreferenced (1 bytes)
	db $C9
Noise43_7FCB:
	db $21, $31, $FF
Noise42_7FCE:
	db $A0, $62
Noise43_7FD0:
	db $20, $42, $FF
Noise42_7FD3:
	db $A0, $81

; Unreferenced (1 bytes)
	db $FF
FadeOutTable:
	db $77, $66, $55, $44, $33, $22, $11, $00
	db $80, FADE_END
FadeInTable:
	db $00, $11, $22, $33, $44, $55, $66, $77
	db FADE_END

; Unreferenced (23 bytes)
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00
