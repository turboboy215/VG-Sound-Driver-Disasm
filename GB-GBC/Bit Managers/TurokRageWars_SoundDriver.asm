; =====================================================================
; Turok: Rage Wars (UE) (M4) [C] - Game Boy Color
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o ragewars.o TurokRageWars_SoundDriver.asm
;   rgblink -o ragewars.gb ragewars.o
;   python tools/cmp_banked.py ragewars.gb "Turok - Rage Wars (UE) (M4) [C][!].gbc" 63:4000-7FFF
; (driver and data fill ROM bank 63; the linked file only matches in that range)
;
; Documentation: TurokRageWars_SoundDriver.md / AJG_SoundEngine_Family.md
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


SECTION "SoundDriver", ROMX[$4000], BANK[63]


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
	dw Cmd_Wave
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
	ld a, $67
	ld [wInstrTableHi], a
	ld a, $CE
	ld [wInstrTable], a
	pop af
	cp $0B
	ret nc
	ld [wCurSong], a
	add a, a
	add a, $BA
	ld l, a
	adc a, $67
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
	set 3, a
	set 4, a
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
	jr ResetMusicPage

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
	ld l, $3E
	ld [hli], a
	ld [hli], a
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

; WAVE w: Ch3 page: remember w and load it unless an SFX plays; other pages: load w.
Cmd_Wave:
	xor a
	ld l, $31
	ld [hl], a
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

; Unreferenced (233 bytes)
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00
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

; StartMusicChN (de = order list): set wInstrTable to the one instrument table (in
; all three entries, so every song plays with it; 14 bytes apart, not 4), reset
; the page, mark it active, start its first pattern. StartMusicCh3 also stops the
; fade and the drums.
StartMusicCh1:
	ld h, $D2
	jr StartMusicCh
StartMusicCh2:
	ld h, $D3
	jr StartMusicCh
StartMusicCh3:
	ld h, $D4
	xor a
	ld [wFadeOn], a
	ld [wDrumsOn], a
StartMusicCh:
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
	cp $07
	jr nc, PlaySfxStart
	ld a, [$D527]
	cp $07
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
	add a, $B1
	ld l, a
	adc a, $6B
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

; Song 2: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong2:
	call StopAll
	ld de, Song2_Ch3
	call StartMusicCh3
	ld de, Song2_Ch2
	call StartMusicCh2
	ld de, Song2_Ch1
	jp StartMusicCh1

; Unreferenced (1 bytes)
	db $C9
Song2_Ch3:
	dw Pat_4CEB
	dw Pat_4D4F
	dw Pat_4DC0
	dw Pat_4DC0
	ORDER_LOOP Song2_Ch3
Song2_Ch2:
	dw Pat_4E2F
	dw Pat_4E67
	dw Pat_4EB6
	dw Pat_4EF0
	dw Pat_4F2E
	dw Pat_4F38
	ORDER_LOOP Song2_Ch2
Song2_Ch1:
	dw Pat_4FB4
	dw Pat_4FED
	dw Pat_5034
	dw Pat_5034
	ORDER_LOOP Song2_Ch1
Pat_4CEB:
	VOLENV 10, $00, $00, $00
	ARP 0
	TRANSPOSE $04
	WAVE_SEQ WaveSeq_6AAD
	VOLENV 10, $00, $00, $00
	RELEASE $02, $11
	VIBRATO $08, $04, $04
	DRUMS $08, DrumPat_50C7
	REPEAT 2
	LEN 24
	NOTE E_, 2
	NOTE E_, 2
	LEN 16
	NOTE E_, 2
	LEN 24
	NOTE E_, 2
	NOTE E_, 2
	LEN 16
	NOTE E_, 2
	LEN 24
	NOTE E_, 2
	NOTE E_, 2
	LEN 16
	NOTE E_, 2
	LEN 24
	NOTE E_, 2
	NOTE E_, 2
	LEN 8
	NOTE G_, 2
	NOTE A_, 2
	REPEAT_END
	LEN 24
	NOTE D_, 2
	NOTE D_, 2
	LEN 16
	NOTE D_, 2
	LEN 24
	NOTE D_, 2
	NOTE D_, 2
	LEN 8
	NOTE C_, 2
	NOTE Csh, 2
	LEN 24
	NOTE D_, 2
	NOTE D_, 2
	LEN 16
	NOTE D_, 2
	NOTE D_, 2
	LEN 8
	NOTE D_, 3
	LEN 16
	NOTE C_, 3
	LEN 8
	NOTE G_, 2
	LEN 16
	NOTE F_, 2
	LEN 24
	NOTE C_, 2
	NOTE C_, 2
	LEN 16
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	LEN 16
	NOTE F_, 2
	LEN 8
	NOTE Fsh, 2
	NOTE G_, 2
	NOTE Ash, 2
	LEN 24
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	LEN 8
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	LEN 16
	NOTE C_, 3
	LEN 8
	NOTE G_, 2
	NOTE C_, 2
	NEXT
Pat_4D4F:
	REPEAT 2
	LEN 16
	NOTE E_, 2
	LEN 8
	NOTE E_, 3
	LEN 16
	NOTE E_, 2
	LEN 8
	NOTE E_, 3
	NOTE E_, 2
	NOTE E_, 3
	LEN 16
	NOTE E_, 2
	LEN 8
	NOTE E_, 3
	LEN 16
	NOTE E_, 2
	LEN 8
	NOTE E_, 3
	NOTE E_, 2
	NOTE E_, 3
	LEN 16
	NOTE E_, 2
	LEN 8
	NOTE E_, 3
	LEN 16
	NOTE E_, 2
	LEN 8
	NOTE E_, 3
	NOTE E_, 2
	NOTE E_, 3
	LEN 16
	NOTE E_, 2
	LEN 8
	NOTE E_, 3
	LEN 16
	NOTE E_, 2
	LEN 8
	NOTE E_, 3
	NOTE G_, 2
	NOTE A_, 2
	REPEAT_END
	REPEAT 2
	LEN 16
	NOTE D_, 2
	LEN 8
	NOTE D_, 3
	LEN 16
	NOTE D_, 2
	LEN 8
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	REPEAT_END
	LEN 16
	NOTE C_, 2
	LEN 8
	NOTE C_, 3
	LEN 16
	NOTE C_, 2
	LEN 8
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	LEN 16
	NOTE C_, 2
	LEN 8
	NOTE C_, 3
	LEN 16
	NOTE C_, 2
	LEN 8
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	REPEAT 2
	LEN 16
	NOTE A_, 2
	LEN 8
	NOTE A_, 3
	LEN 16
	NOTE A_, 2
	LEN 8
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	REPEAT_END
	LEN 16
	NOTE B_, 2
	LEN 8
	NOTE B_, 3
	LEN 16
	NOTE B_, 2
	LEN 8
	NOTE B_, 3
	NOTE B_, 2
	NOTE B_, 3
	LEN 8
	RELEASE $00
	NOTE B_, 2
	DRUMS_OFF
	LENGTH $20
	WAIT
	LEN 12
	GLIDE $FF
	WAIT
	GLIDE $01
	WAIT
	GLIDE_OFF
	NEXT
Pat_4DC0:
	VOLENV 10, $00, $00, $00
	WAVE_SEQ WaveSeq_697F
	DRUMS $08, DrumPat_50ED
	LEN 8
	REPEAT 2
	NOTE E_, 2
	NOTE E_, 3
	NOTE E_, 2
	NOTE E_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE E_, 3
	NOTE G_, 2
	NOTE E_, 2
	NOTE E_, 3
	NOTE E_, 2
	NOTE E_, 3
	NOTE A_, 3
	NOTE E_, 3
	NOTE E_, 3
	NOTE G_, 2
	NOTE E_, 2
	NOTE E_, 3
	NOTE E_, 2
	NOTE E_, 3
	NOTE B_, 3
	NOTE E_, 3
	NOTE E_, 3
	NOTE G_, 2
	NOTE E_, 2
	NOTE E_, 3
	NOTE D_, 2
	NOTE E_, 3
	NOTE D_, 4
	NOTE E_, 3
	NOTE E_, 3
	NOTE D_, 4
	REPEAT_END
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE E_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE E_, 2
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE A_, 3
	NOTE G_, 2
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE E_, 4
	NOTE A_, 3
	NOTE A_, 3
	NOTE G_, 2
	NOTE E_, 2
	NOTE E_, 3
	NOTE E_, 2
	NOTE E_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE E_, 3
	NOTE G_, 2
	NOTE E_, 2
	NOTE E_, 3
	NOTE E_, 2
	NOTE E_, 3
	NOTE A_, 3
	NOTE E_, 3
	NOTE E_, 3
	NOTE G_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE A_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE A_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE A_, 2
	NEXT
Pat_4E2F:
	HWENV $B1, $08, $40
	DUTY_50
	RELEASE $54, $20
	AUTODUTY $00
	PINGPONG
	VIBRATO $08, $02, $02
	LEN 32
	NOTE B_, 3
	LEN 48
	NOTE B_, 3
	LEN 16
	NOTE B_, 3
	LEN 8
	NOTE A_, 3
	LEN 24
	NOTE B_, 3
	LEN 32
	NOTE A_, 3
	LEN 48
	NOTE A_, 3
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE G_, 3
	LEN 24
	NOTE A_, 3
	LEN 32
	NOTE B_, 3
	LEN 48
	NOTE B_, 3
	LEN 16
	NOTE B_, 3
	LEN 8
	NOTE A_, 3
	LEN 24
	NOTE B_, 3
	LEN 32
	NOTE A_, 3
	LEN 48
	NOTE A_, 3
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE G_, 3
	LEN 24
	NOTE A_, 3
	NEXT
Pat_4E67:
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE G_, 3
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE G_, 3
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE D_, 3
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE D_, 3
	LEN 16
	NOTE G_, 3
	LEN 8
	NOTE G_, 3
	NOTE G_, 3
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE G_, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE G_, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE D_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE C_, 5
	NOTE G_, 4
	LEN 16
	NOTE G_, 5
	LEN 8
	NOTE F_, 5
	LEN 16
	NOTE G_, 5
	LEN 8
	NOTE F_, 5
	LEN 16
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE Dsh, 5
	LEN 8
	NOTE C_, 5
	LEN 16
	NOTE Dsh, 5
	LEN 8
	NOTE C_, 5
	LEN 16
	NOTE G_, 5
	LEN 8
	NOTE F_, 5
	LEN 16
	NOTE G_, 5
	LEN 8
	NOTE F_, 5
	LEN 16
	NOTE Dsh, 5
	NOTE C_, 6
	NOTE G_, 5
	LEN 4
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	NOTE F_, 5
	LEN 16
	NOTE Dsh, 5
	NEXT
Pat_4EB6:
	VIBRATO $20, $0C, $01
	DUTY_75
	LEN 32
	ARP 3
	NOTE A_, 4
	ARP_OFF
	LEN 48
	NOTE B_, 4
	LEN 16
	ARP 3
	NOTE A_, 4
	ARP_OFF
	LEN 8
	NOTE A_, 4
	LEN 24
	NOTE B_, 4
	LEN 32
	NOTE A_, 4
	LEN 48
	NOTE A_, 4
	LEN 16
	ARP 3
	NOTE G_, 4
	ARP_OFF
	LEN 8
	NOTE G_, 4
	LEN 24
	NOTE A_, 4
	LEN 32
	NOTE B_, 4
	LEN 48
	NOTE B_, 4
	LEN 16
	ARP 3
	NOTE A_, 4
	ARP_OFF
	LEN 8
	NOTE A_, 4
	LEN 24
	NOTE B_, 4
	LEN 32
	NOTE A_, 4
	LEN 48
	NOTE A_, 4
	LEN 16
	ARP 3
	NOTE G_, 4
	ARP_OFF
	LEN 8
	NOTE G_, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE G_, 4
	NEXT
Pat_4EF0:
	LEN 32
	NOTE A_, 4
	LEN 48
	NOTE A_, 4
	LEN 16
	ARP 3
	NOTE G_, 4
	ARP_OFF
	LEN 8
	NOTE G_, 4
	LEN 24
	NOTE A_, 4
	LEN 32
	NOTE G_, 4
	LEN 48
	NOTE G_, 4
	LEN 16
	ARP 3
	NOTE F_, 4
	ARP_OFF
	LEN 8
	NOTE Fsh, 4
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE Fsh, 4
	LEN 32
	NOTE G_, 4
	LEN 48
	NOTE G_, 4
	LEN 16
	ARP 3
	NOTE F_, 4
	ARP_OFF
	LEN 8
	NOTE Fsh, 4
	LEN 24
	NOTE G_, 4
	LEN 16
	NOTE Fsh, 4
	LEN 8
	NOTE G_, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE B_, 4
	NOTE C_, 5
	RELEASE $00
	VIBRATO $08, $03, $04
	LEN 8
	NOTE B_, 4
	LEN 40
	WAIT
	GLIDE $FF
	LEN 24
	WAIT
	NEXT
Pat_4F2E:
	HWENV $B2, $08, $60
	DUTY_50
	VIBRATO $18, $04, $04
	GLIDE_OFF
Pat_4F38:
	LENGTH $40
	ARP 3
	NOTE F_, 4
	ARP_OFF
	LEN 32
	NOTE A_, 4
	LEN 16
	NOTE B_, 4
	LENGTH $64
	NOTE Fsh, 4
	GLIDE $FF
	LEN 12
	WAIT
	GLIDE_OFF
	LEN 8
	NOTE D_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	LENGTH $40
	ARP 3
	NOTE F_, 4
	ARP_OFF
	LEN 32
	NOTE A_, 4
	LEN 16
	NOTE B_, 4
	LEN 32
	ARP 3
	NOTE C_, 5
	ARP_OFF
	LEN 16
	NOTE Fsh, 4
	LENGTH $34
	ARP 3
	NOTE E_, 4
	ARP_OFF
	LEN 12
	GLIDE $FF
	WAIT
	GLIDE_OFF
	LEN 8
	NOTE D_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	LENGTH $D4
	NOTE E_, 4
	LEN 12
	GLIDE $FF
	WAIT
	GLIDE_OFF
	LEN 8
	NOTE D_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	LENGTH $80
	NOTE E_, 4
	LEN 24
	ARP 3
	NOTE D_, 4
	ARP_OFF
	LEN 4
	NOTE Fsh, 4
	NOTE E_, 4
	LEN 16
	NOTE D_, 4
	LEN 32
	NOTE A_, 3
	LEN 36
	ARP 3
	NOTE C_, 4
	ARP_OFF
	GLIDE $FF
	LEN 12
	WAIT
	GLIDE_OFF
	AUTODUTY $08
	NEXT
Pat_4F93:
	NOTE E_, 3
	NOTE E_, 4
	NOTE E_, 2
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE G_, 3
	NOTE E_, 3
	NOTE E_, 4
	NOTE E_, 2
	NOTE E_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE G_, 3
	NOTE E_, 3
	NOTE E_, 4
	NOTE E_, 2
	NOTE E_, 4
	NOTE B_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE G_, 3
	NOTE E_, 3
	NOTE E_, 4
	NOTE E_, 2
	NOTE E_, 4
	NOTE D_, 5
	NOTE E_, 4
	NOTE E_, 4
	NOTE D_, 5
	NEXT
Pat_4FB4:
	HWENV $91, $00
	AUTODUTY $08
	PINGPONG
	LEN 8
	REPEAT 2
	PAT_CALL Pat_4F93
	REPEAT_END
	CH_TRANSPOSE $FE
	PAT_CALL Pat_4F93
	CH_TRANSPOSE $FC
	PAT_CALL Pat_4F93
	CH_TRANSPOSE $00
	NEXT
Pat_4FCD:
	NOTE G_, 4
	NOTE E_, 4
	NOTE E_, 2
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE G_, 3
	NOTE E_, 3
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE G_, 3
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE E_, 2
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE Fsh, 3
	NOTE D_, 3
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NEXT
Pat_4FED:
	DRUMS $08, DrumPat_50DA
	PAT_CALL Pat_4FCD
	NOTE D_, 5
	PAT_CALL Pat_4FCD
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE D_, 2
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE Fsh, 3
	NOTE D_, 3
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE C_, 2
	NOTE C_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE E_, 3
	NOTE C_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE Dsh, 5
	NOTE Fsh, 4
	NOTE E_, 5
	NOTE Fsh, 5
	NOTE B_, 4
	NOTE G_, 5
	NOTE A_, 5
	LENGTH $48
	NOTE Dsh, 5
	NEXT
Pat_5034:
	REPEAT 2
	INSTR 5
	LEN 16
	NOTE E_, 4
	INSTR 8
	NOTE E_, 6
	INSTR 5
	LEN 8
	NOTE E_, 4
	INSTR 8
	LEN 24
	NOTE E_, 6
	LEN 16
	NOTE E_, 6
	INSTR 5
	NOTE E_, 4
	INSTR 8
	LEN 8
	NOTE E_, 6
	INSTR 5
	LEN 16
	NOTE E_, 4
	INSTR 8
	LEN 8
	NOTE E_, 6
	INSTR 4
	LEN 16
	NOTE D_, 4
	INSTR 8
	NOTE E_, 6
	INSTR 4
	LEN 8
	NOTE D_, 4
	INSTR 8
	LEN 24
	NOTE E_, 6
	LEN 16
	NOTE E_, 6
	INSTR 4
	NOTE D_, 4
	INSTR 8
	LEN 8
	NOTE E_, 6
	INSTR 4
	LEN 16
	NOTE D_, 4
	INSTR 8
	LEN 8
	NOTE E_, 6
	REPEAT_END
	INSTR 4
	LEN 16
	NOTE C_, 5
	INSTR 8
	NOTE E_, 6
	INSTR 4
	LEN 8
	NOTE C_, 5
	INSTR 8
	LEN 24
	NOTE E_, 6
	LEN 16
	NOTE E_, 6
	INSTR 4
	NOTE C_, 5
	INSTR 8
	LEN 8
	NOTE E_, 6
	INSTR 4
	LEN 16
	NOTE C_, 5
	INSTR 8
	LEN 8
	NOTE E_, 6
	INSTR 5
	LEN 16
	NOTE A_, 4
	INSTR 8
	NOTE E_, 6
	INSTR 5
	LEN 8
	NOTE A_, 4
	INSTR 8
	LEN 24
	NOTE E_, 6
	LEN 16
	NOTE E_, 6
	INSTR 5
	NOTE A_, 4
	INSTR 8
	LEN 8
	NOTE E_, 6
	INSTR 5
	LEN 16
	NOTE A_, 4
	INSTR 8
	LEN 8
	NOTE E_, 6
	INSTR 5
	LEN 16
	NOTE E_, 4
	INSTR 8
	NOTE E_, 6
	INSTR 5
	LEN 8
	NOTE E_, 4
	INSTR 8
	LEN 24
	NOTE E_, 6
	LEN 16
	NOTE E_, 6
	INSTR 5
	NOTE E_, 4
	INSTR 8
	LEN 8
	NOTE E_, 6
	INSTR 5
	LEN 16
	NOTE E_, 4
	INSTR 8
	LEN 8
	NOTE E_, 6
	INSTR 4
	LEN 16
	NOTE D_, 5
	INSTR 8
	NOTE E_, 6
	INSTR 4
	LEN 8
	NOTE D_, 5
	INSTR 8
	LEN 24
	NOTE E_, 6
	LEN 16
	NOTE E_, 6
	INSTR 4
	NOTE D_, 5
	INSTR 8
	LEN 8
	NOTE E_, 6
	INSTR 4
	LEN 16
	NOTE D_, 5
	INSTR 8
	LEN 8
	NOTE E_, 6
	NEXT
DrumPat_50C7:
	db DRUM_REPEAT + 3, 1, 0, 6, 1, 0, 6, 1
	db 0, DRUM_REPEAT_END, 1, 0, 6, 1, 0, 6
	db 1, 1, DRUM_LOOP
DrumPat_50DA:
	db 1, 0, 6, 1, 0, DRUM_PINGPONG, 7, 7
	db 7, 7, 0, DRUM_PINGPONG_OFF, 1, 0, 1, 1
	db 6, 5, DRUM_LOOP
DrumPat_50ED:
	db 1, 5, 5, 1, 2, 5, 1, 5
	db 1, 1, 5, 5, 2, 5, DRUM_TEMPO + 4, 1
	db 6, 6, 6, DRUM_TEMPO + 8, 1, 5, 5, 1
	db 2, 5, 1, 5, 1, 1, 1, 5
	db 2, DRUM_TEMPO + 4, 5, 6, DRUM_TEMPO + 8, 1, 1, DRUM_LOOP

; Song 3: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong3:
	call StopAll
	ld de, Song3_Ch3
	call StartMusicCh3
	ld de, Song3_Ch2
	call StartMusicCh2
	ld de, Song3_Ch1
	jp StartMusicCh1
Pat_512A:
	CH_TRANSPOSE $00
	NEXT
Pat_512D:
	CH_TRANSPOSE $0C
	NEXT
Pat_5130:
	TRANSPOSE $00
	NEXT
Pat_5133:
	TRANSPOSE $02
	NEXT
Song3_Ch3:
	dw Pat_5130
	dw Pat_5193
	dw Pat_51A2
	dw Pat_51A2
	dw Pat_5133
	dw Pat_5193
	dw Pat_51A2
	dw Pat_51A2
	ORDER_LOOP Song3_Ch3
Pat_514A:
	DRUMS $00, DrumPat_53CC
	NEXT
Pat_514F:
	DRUMS $00, DrumPat_53B6
	NEXT
Pat_5154:
	DRUMS $00, DrumPat_5374
	NEXT
Song3_Ch2:
	dw Pat_512A
	dw Pat_514A
	dw Pat_51DF
	dw Pat_514F
	dw Pat_51FE
	dw Pat_51FE
	dw Pat_525C
	dw Pat_525C
	dw Pat_512D
	dw Pat_5154
	dw Pat_51FE
	dw Pat_51FE
	dw Pat_525C
	dw Pat_525C
	ORDER_LOOP Song3_Ch2
Song3_Ch1:
	dw Pat_512A
	dw Pat_52AD
	dw Pat_52EA
	dw Pat_52EA
	dw Pat_532D
	dw Pat_532D
	dw Pat_52EA
	dw Pat_52EA
	dw Pat_512D
	dw Pat_532D
	dw Pat_532D
	ORDER_LOOP Song3_Ch1
Pat_5193:
	CH_TRANSPOSE $0C
	VOLENV 15, $11, $15, $11
	WAVE Wave_74FF
	LEN 12
	REPEAT 8
	NOTE Dsh, 2
	NOTE Dsh, 3
	REPEAT_END
	NEXT
Pat_51A2:
	CH_TRANSPOSE $0C
	LEN 12
	REPEAT 2
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Fsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Ash, 2
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Fsh, 2
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE Ash, 2
	NOTE Ash, 2
	REPEAT_END
	PAT_CALL Pat_51CA
Pat_51CA:
	REPEAT 4
	NOTE Gsh, 2
	NOTE Gsh, 3
	REPEAT_END
	REPEAT 4
	NOTE Gsh, 1
	NOTE Gsh, 2
	REPEAT_END
	REPEAT 3
	NOTE Fsh, 2
	NOTE Fsh, 3
	REPEAT_END
	NOTE Fsh, 2
	NOTE Fsh, 2
	REPEAT 3
	NOTE Csh, 2
	NOTE Csh, 3
	REPEAT_END
	NOTE Csh, 2
	NOTE Csh, 2
	NEXT
Pat_51DF:
	VIBRATO $00, $03, $02
	LEN 6
	HWENV $81, $02, $00
	DUTY_50
	AUTOPAN $02
	REPEAT 2
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE Dsh, 5
	WAIT
	NOTE Dsh, 5
	NOTE Dsh, 5
	WAIT
	NOTE Dsh, 5
	NOTE Dsh, 5
	WAIT
	NOTE Dsh, 5
	NOTE Dsh, 5
	WAIT
	NOTE Dsh, 5
	NOTE Fsh, 5
	NOTE Dsh, 5
	REPEAT_END
	NEXT
Pat_51FE:
	RELEASE $03, $20
	LEN 6
	INSTR 9
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE Dsh, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE Dsh, 4
	NOTE Ash, 3
	WAIT
	RELEASE $00
	INSTR 18
	NOTE Dsh, 3
	NOTE Fsh, 3
	NOTE Ash, 3
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE Ash, 4
	RELEASE $03, $20
	INSTR 9
	NOTE C_, 5
	NOTE C_, 5
	NOTE Gsh, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE Gsh, 4
	NOTE Dsh, 4
	WAIT
	RELEASE $00
	INSTR 18
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Dsh, 5
	RELEASE $03, $20
	INSTR 9
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE Dsh, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE Dsh, 4
	NOTE Ash, 3
	WAIT
	RELEASE $00
	INSTR 18
	NOTE Dsh, 3
	NOTE Fsh, 3
	NOTE Ash, 3
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE Ash, 4
	RELEASE $03, $20
	INSTR 9
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Ash, 4
	WAIT
	NOTE Csh, 5
	WAIT
	NOTE Ash, 4
	NOTE F_, 4
	WAIT
	RELEASE $00
	INSTR 18
	NOTE Csh, 5
	NOTE Ash, 4
	NOTE F_, 4
	NOTE Csh, 4
	NOTE Ash, 4
	NOTE F_, 4
	NOTE Csh, 4
	NEXT
Pat_525C:
	WAIT
	INSTR 18
	NOTE Dsh, 3
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE Gsh, 3
	NOTE Csh, 4
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE Dsh, 3
	NOTE Gsh, 3
	INSTR 9
	DUTY_50
	NOTE Gsh, 5
	NOTE Dsh, 6
	NOTE Gsh, 5
	NOTE Csh, 6
	NOTE Gsh, 5
	NOTE C_, 6
	NOTE Gsh, 5
	NOTE Fsh, 5
	NOTE Ash, 5
	NOTE Gsh, 5
	NOTE Dsh, 5
	NOTE Fsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Dsh, 4
	NOTE Fsh, 3
	INSTR 18
	NOTE Fsh, 4
	INSTR 9
	NOTE F_, 3
	INSTR 18
	NOTE F_, 4
	INSTR 9
	NOTE Fsh, 3
	INSTR 18
	NOTE Fsh, 4
	INSTR 9
	NOTE F_, 3
	INSTR 18
	NOTE F_, 4
	INSTR 9
	NOTE Fsh, 3
	INSTR 18
	NOTE Fsh, 4
	INSTR 9
	NOTE F_, 3
	INSTR 18
	NOTE Fsh, 4
	NOTE Dsh, 4
	INSTR 9
	NOTE F_, 3
	NOTE Dsh, 3
	INSTR 18
	NOTE Csh, 4
	WAIT
	NOTE Fsh, 5
	NOTE Gsh, 3
	NOTE F_, 5
	NOTE Gsh, 3
	NOTE Fsh, 5
	NOTE Gsh, 3
	NOTE F_, 5
	NOTE Gsh, 3
	NOTE Fsh, 5
	NOTE Gsh, 3
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE Gsh, 3
	NOTE F_, 5
	NOTE Csh, 5
	NEXT
Pat_52AD:
	LEN 6
	ARP_OFF
	AUTODUTY $0C
	HWENV $62, $00
	NOTE Ash, 3
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE Dsh, 4
	HWENV $52, $00
	NOTE Ash, 3
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE Dsh, 4
	HWENV $34, $00
	NOTE Ash, 3
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE Dsh, 4
	HWENV $53, $00
	NOTE Ash, 3
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE Dsh, 4
	HWENV $63, $00
	NOTE Ash, 3
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE Dsh, 4
	HWENV $72, $00
	NOTE Ash, 3
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE Dsh, 4
	HWENV $82, $00
	NOTE Ash, 3
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE Dsh, 4
	HWENV $A2, $00
	NOTE Ash, 3
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE Dsh, 4
	NEXT
Pat_52EA:
	LEN 6
	INSTR 13
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE Fsh, 4
	NOTE Ash, 3
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE Fsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 3
	NOTE Fsh, 3
	NOTE Ash, 3
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE Ash, 4
	NOTE Dsh, 5
	NOTE Gsh, 4
	NOTE Dsh, 4
	NOTE C_, 5
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Dsh, 4
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE Gsh, 5
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE Fsh, 4
	NOTE Ash, 3
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE Fsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 3
	NOTE Fsh, 3
	NOTE Ash, 3
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE Ash, 4
	NOTE Dsh, 5
	NOTE Ash, 4
	NOTE F_, 4
	NOTE Csh, 5
	NOTE F_, 4
	NOTE Ash, 4
	NOTE F_, 4
	NOTE Csh, 5
	NOTE Ash, 4
	NOTE Csh, 5
	NOTE Ash, 4
	NOTE F_, 4
	NOTE Csh, 4
	NOTE Ash, 4
	NOTE F_, 4
	NOTE Csh, 4
	NOTE Ash, 3
	NEXT
Pat_532D:
	ARP_OFF
	NOTE Dsh, 3
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE Gsh, 3
	NOTE Csh, 4
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE Dsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 4
	NOTE Dsh, 5
	NOTE Gsh, 4
	NOTE Csh, 5
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Dsh, 4
	NOTE Fsh, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE Dsh, 3
	NOTE Fsh, 4
	NOTE Fsh, 3
	NOTE F_, 4
	NOTE Fsh, 3
	NOTE Fsh, 4
	NOTE Fsh, 3
	NOTE F_, 4
	NOTE Fsh, 3
	NOTE Fsh, 4
	NOTE Fsh, 3
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE Fsh, 3
	NOTE F_, 4
	NOTE Csh, 4
	NOTE Gsh, 3
	RELEASE $02, $20
	NOTE Fsh, 5
	NOTE Fsh, 5
	NOTE F_, 5
	NOTE Gsh, 3
	NOTE Fsh, 5
	NOTE Gsh, 3
	NOTE F_, 5
	NOTE Gsh, 3
	NOTE Fsh, 5
	NOTE Gsh, 3
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE Gsh, 3
	NOTE F_, 5
	NOTE Csh, 5
	NOTE Gsh, 4
	RELEASE $00
	NEXT
DrumPat_5374:
	db DRUM_TEMPO + 6, 7, 0, 0, 0, 2, 6, 4
	db 0, 1, 0, 4, 0, 2, 6, 4
	db 0, 1, 0, 4, 0, 2, 6, 4
	db 0, 1, 0, 4, 0, 2, 6, 1
	db 0, 1, 0, 4, 0, 2, 6, 4
	db 0, 1, 0, 4, 0, 2, 6, 4
	db 0, 1, 0, 4, 0, 2, 6, 4
	db 0, 1, 0, 4, 0, 2, 6, 2
	db 2, DRUM_LOOP
DrumPat_53B6:
	db DRUM_TEMPO + 6, DRUM_REPEAT + 7, 1, 0, 5, 6, DRUM_REPEAT_END, 1
	db 0, 1, 0, DRUM_REPEAT + 7, 1, 0, 5, 6
	db DRUM_REPEAT_END, 2, 0, 1, 1, DRUM_LOOP
DrumPat_53CC:
	db DRUM_TEMPO + 6, 7, 0, 0, 0, 1, 6, 0
	db 6, 1, 0, 6, 6, 1, 6, 6
	db 6, 1, 6, 6, 0, 1, 6, 0
	db 6, 1, 0, 1, 1, 2, 0, 1
	db 6, DRUM_LOOP

; Song 4: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong4:
	ld de, Song4_Ch1
	call StartMusicCh1
	ld de, Song4_Ch2
	call StartMusicCh2
	ld de, Song4_Ch3
	jp StartMusicCh3
Song4_Ch3:
	dw Pat_543C
	dw Pat_543C
	dw Pat_547D
	dw Pat_543C
	dw Pat_543C
	dw Pat_543C
	dw Pat_543C
	dw Pat_5697
	ORDER_LOOP Song4_Ch3
Song4_Ch2:
	dw Pat_54F1
	dw Pat_54F1
	dw Pat_5596
	dw Pat_5525
	dw Pat_55AA
	dw Pat_5525
	dw Pat_55BF
	dw Pat_56B1
	ORDER_LOOP Song4_Ch2
Song4_Ch1:
	dw Pat_55D4
	dw Pat_55D4
	dw Pat_55D4
	dw Pat_55D4
	dw Pat_561D
	dw Pat_5655
	dw Pat_566B
	dw Pat_5683
	ORDER_LOOP Song4_Ch1
Pat_543C:
	VIBRATO $09, $04, $04
	VOLENV 15, $11, $10, $12
	RELEASE $04, $50
	WAVE Wave_75CF
	DRUMS $09, DrumPat_56C3
	LEN 9
	WAIT2
	NOTE A_, 2
	LEN 18
	NOTE G_, 2
	NOTE E_, 2
	NOTE D_, 2
	LEN 27
	NOTE C_, 2
	LEN 36
	NOTE A_, 1
	REPEAT 2
	LEN 18
	ARP 2
	NOTE A_, 1
	LEN 9
	ARP_OFF
	NOTE A_, 2
	LEN 18
	NOTE G_, 2
	NOTE E_, 2
	NOTE D_, 2
	LEN 27
	NOTE C_, 2
	LEN 36
	NOTE A_, 1
	REPEAT_END
	LEN 18
	ARP 2
	NOTE A_, 1
	LEN 9
	ARP_OFF
	NOTE A_, 2
	LEN 18
	NOTE G_, 2
	NOTE E_, 2
	NOTE D_, 2
	LEN 27
	NOTE C_, 2
	LEN 18
	NOTE D_, 2
	LEN 9
	NOTE E_, 2
	NOTE G_, 2
	LEN 9
	NOTE A_, 2
	NEXT
Pat_547D:
	DRUMS $00, DrumPat_5745
	LEN 9
	NOTE A_, 1
	ARP_OFF
	NOTE A_, 2
	LEN 18
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	LEN 27
	ARP 3
	NOTE Ash, 2
	ARP_OFF
	NOTE A_, 2
	LEN 9
	NOTE G_, 2
	NOTE A_, 2
	WAIT2
	NOTE A_, 2
	LEN 18
	NOTE G_, 2
	NOTE E_, 2
	NOTE G_, 2
	LEN 27
	ARP 9
	NOTE D_, 2
	ARP_OFF
	NOTE E_, 2
	NOTE G_, 2
Pat_549D:
	LEN 9
	NOTE A_, 2
	LEN 18
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	LEN 27
	ARP 3
	NOTE Ash, 2
	ARP_OFF
	NOTE A_, 2
	LEN 9
	NOTE G_, 2
	NOTE A_, 2
	WAIT2
	NOTE A_, 2
	LEN 18
	NOTE G_, 2
	NOTE E_, 2
	NOTE G_, 2
	LEN 27
	ARP 9
	NOTE D_, 2
	ARP_OFF
	NOTE C_, 2
	LEN 18
	NOTE A_, 1
	NEXT
Pat_54B9:
	LEN 9
	NOTE A_, 1
	ARP_OFF
	NOTE A_, 2
	LEN 18
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	LEN 27
	ARP 3
	NOTE Ash, 2
	ARP_OFF
	NOTE A_, 2
	LEN 9
	NOTE G_, 2
	NOTE A_, 2
	WAIT2
	NOTE A_, 2
	LEN 18
	NOTE G_, 2
	NOTE E_, 2
	NOTE G_, 2
	LEN 27
	ARP 9
	NOTE D_, 2
	ARP_OFF
	NOTE E_, 2
	NOTE G_, 2
	LEN 9
	NOTE A_, 2
	LEN 18
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	LEN 27
	ARP 3
	NOTE Ash, 2
	ARP_OFF
	NOTE A_, 2
	LEN 9
	NOTE G_, 2
	NOTE A_, 2
	WAIT2
	NOTE A_, 2
	LEN 18
	NOTE G_, 2
	NOTE E_, 2
	NOTE G_, 2
	LEN 27
	ARP 9
	NOTE D_, 3
	ARP_OFF
	NOTE C_, 3
	LEN 18
	NOTE A_, 2
	NEXT
Pat_54F1:
	VIBRATO $00, $02, $02
	REPEAT 4
	HWENV $82, $12, $44
	DUTY_50
	LEN 9
	ARP 0
	NOTE C_, 5
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	NOTE B_, 4
	WAIT
	WAIT
	HWENV $34, $00
	NOTE B_, 4
	WAIT
	NOTE B_, 4
	DUTY_75
	HWENV $59, $04, $91
	GLIDE $02
	LEN 5
	NOTE A_, 2
	LEN 5
	GLIDE $FF
	WAIT
	GLIDE_OFF
	INSTR 8
	PINGPONG
	LEN 8
	NOTE A_, 4
	LEN 10
	NOTE A_, 5
	LEN 8
	NOTE A_, 5
	PINGPONG_OFF
	REPEAT_END
	NEXT
Pat_5525:
	REPEAT 3
	HWENV $82, $12, $63
	DUTY_50
	LEN 9
	ARP 0
	PAN_C
	NOTE C_, 4
	WAIT
	PAN_L
	WAIT
	PAN_C
	NOTE E_, 4
	WAIT
	PAN_R
	WAIT
	PAN_C
	NOTE B_, 3
	WAIT
	PAN_L
	WAIT
	HWENV $34, $00
	PAN_R
	NOTE B_, 3
	WAIT
	PAN_L
	NOTE B_, 3
	PAN_C
	DUTY_75
	HWENV $59, $04, $91
	GLIDE $02
	LEN 5
	NOTE A_, 2
	LEN 5
	GLIDE $FF
	WAIT
	GLIDE_OFF
	INSTR 8
	PINGPONG
	LEN 8
	NOTE A_, 4
	LEN 10
	NOTE A_, 5
	LEN 8
	NOTE A_, 5
	PINGPONG_OFF
	REPEAT_END
	HWENV $82, $12, $63
	DUTY_50
	LEN 9
	ARP 0
	PAN_C
	NOTE C_, 4
	WAIT
	PAN_L
	WAIT
	PAN_C
	NOTE E_, 4
	WAIT
	PAN_R
	WAIT
	PAN_C
	NOTE B_, 3
	WAIT
	PAN_L
	WAIT
	HWENV $34, $00
	PAN_R
	NOTE B_, 3
	WAIT
	PAN_L
	NOTE B_, 3
	PAN_C
	DUTY_75
	HWENV $59, $04, $91
	GLIDE $02
	LEN 5
	NOTE A_, 2
	LEN 4
	GLIDE $FF
	WAIT
	GLIDE_OFF
	DUTY_50
	HWENV $F2, $04, $42
	PINGPONG
	LEN 9
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	PINGPONG_OFF
	NEXT
Pat_5596:
	HWENV $C1, $09, $50
	RELEASE $04, $10
	ARP_OFF
	PINGPONG
	CH_TRANSPOSE $07
	PAT_CALL Pat_547D
	CH_TRANSPOSE $00
	RELEASE $00
	PINGPONG_OFF
	NEXT
Pat_55AA:
	HWENV $81, $04, $30
	DUTY_50
	RELEASE $04, $10
	ARP_OFF
	PINGPONG
	CH_TRANSPOSE $18
	PAT_CALL Pat_547D
	CH_TRANSPOSE $00
	RELEASE $00
	PINGPONG_OFF
	NEXT
Pat_55BF:
	HWENV $81, $04, $30
	DUTY_75
	RELEASE $04, $10
	ARP_OFF
	PINGPONG
	CH_TRANSPOSE $18
	PAT_CALL Pat_54B9
	CH_TRANSPOSE $00
	RELEASE $00
	PINGPONG_OFF
	NEXT
Pat_55D4:
	TRANSPOSE $06
	VIBRATO $00, $02, $02
	HWENV $42, $12, $27
	DUTY_50
	LEN 9
	AUTOPAN $09
	CH_TRANSPOSE $F4
	NOTE C_, 6
	WAIT
	NOTE C_, 6
	WAIT
	WAIT
	NOTE E_, 5
	WAIT
	WAIT
	NOTE B_, 5
	WAIT
	WAIT
	NOTE B_, 5
	WAIT
	WAIT
	NOTE B_, 5
	WAIT
	PINGPONG
	GLIDE $FF
	DUTY_50
	LEN 18
Pat_55F9:
	HWENV $83, $00
	NOTE B_, 6
	HWENV $73, $00
	NOTE B_, 6
	HWENV $64, $00
	NOTE B_, 6
	HWENV $55, $00
	NOTE B_, 6
	HWENV $46, $00
	NOTE B_, 6
	HWENV $37, $00
	NOTE B_, 6
	HWENV $27, $00
	NOTE B_, 6
	HWENV $10, $09, $11
	NOTE B_, 6
	GLIDE_OFF
	PINGPONG_OFF
	NEXT
Pat_561D:
	PINGPONG
	INSTR 8
	REPEAT 4
	LEN 10
	NOTE A_, 5
	LEN 8
	NOTE A_, 5
	LEN 10
	NOTE A_, 5
	LEN 8
	NOTE A_, 5
	REPEAT_END
	GLIDE $FF
	LEN 9
	HWENV $10, $09, $11
	CH_TRANSPOSE $E8
	NOTE B_, 6
	HWENV $27, $00
	NOTE B_, 6
	HWENV $37, $00
	NOTE B_, 6
	HWENV $46, $00
	NOTE B_, 6
	HWENV $55, $00
	NOTE B_, 6
	HWENV $64, $00
	NOTE B_, 6
	HWENV $73, $00
	NOTE B_, 6
	HWENV $93, $00
	NOTE B_, 6
	PAT_CALL Pat_55F9
	CH_TRANSPOSE $00
	NEXT
Pat_5655:
	HWENV $A2, $09, $40
	DUTY_12
	RELEASE $04, $10
	CH_TRANSPOSE $0C
	AUTODUTY $00
	LEN 9
	NOTE A_, 1
	PAT_CALL Pat_549D
	CH_TRANSPOSE $00
	RELEASE $00
	NEXT
Pat_566B:
	HWENV $2F, $1B, $40
	RELEASE $0F, $44
	AUTODUTY $02
	REPEAT 4
	LENGTH $90
	ARP 15
	NOTE A_, 3
	ARP 14
	NOTE G_, 3
	NOTE F_, 3
	NOTE G_, 3
	REPEAT_END
	ARP_OFF
	PINGPONG_OFF
	RELEASE $00
	NEXT
Pat_5683:
	LENGTH $48
	ARP 14
	NOTE A_, 3
	LENGTH $3C
	WAIT
	LEN 12
	GLIDE $FF
	WAIT
	GLIDE_OFF
	LENGTH $48
	WAIT
	WAIT
	ARP_OFF
	AUTODUTY $00
	NEXT
Pat_5697:
	DRUMS $00, DrumPat_5745
	LENGTH $48
	RELEASE $00
	NOTE A_, 2
	LENGTH $3C
	WAIT
	LEN 12
	GLIDE $FF
	WAIT
	GLIDE_OFF
	DRUMS $00, DrumPat_5769
	LENGTH $48
	WAIT
	WAIT
	NEXT
Pat_56B1:
	ARP 3
	LENGTH $48
	NOTE G_, 4
	LENGTH $3C
	WAIT
	LEN 12
	GLIDE $FF
	WAIT
	GLIDE_OFF
	LENGTH $48
	WAIT
	WAIT
	ARP_OFF
	NEXT
DrumPat_56C3:
	db DRUM_TEMPO + 10, 1, DRUM_TEMPO + 8, 6, DRUM_TEMPO + 10, 1, DRUM_TEMPO + 8, 6
	db DRUM_TEMPO + 10, 2, DRUM_TEMPO + 8, 6, DRUM_TEMPO + 10, 5, DRUM_TEMPO + 8, 6
	db DRUM_TEMPO + 10, 1, DRUM_TEMPO + 8, 6, DRUM_TEMPO + 10, 1, DRUM_TEMPO + 8, 6
	db DRUM_TEMPO + 10, 2, DRUM_TEMPO + 8, 6, DRUM_TEMPO + 10, 5, DRUM_TEMPO + 8, 2
	db DRUM_TEMPO + 10, 1, DRUM_TEMPO + 8, 6, DRUM_TEMPO + 10, 1, DRUM_TEMPO + 8, 6
	db DRUM_TEMPO + 10, 2, DRUM_TEMPO + 8, 6, DRUM_TEMPO + 10, 5, DRUM_TEMPO + 8, 6
	db DRUM_TEMPO + 10, 1, DRUM_TEMPO + 8, 6, DRUM_TEMPO + 10, 1, DRUM_TEMPO + 8, 6
	db DRUM_TEMPO + 10, 2, DRUM_TEMPO + 8, 1, DRUM_TEMPO + 10, 5, DRUM_TEMPO + 8, 2
	db DRUM_TEMPO + 10, 1, DRUM_TEMPO + 8, 6, DRUM_TEMPO + 10, 1, DRUM_TEMPO + 8, 6
	db DRUM_TEMPO + 10, 2, DRUM_TEMPO + 8, 6, DRUM_TEMPO + 10, 5, DRUM_TEMPO + 8, 6
	db DRUM_TEMPO + 10, 1, DRUM_TEMPO + 8, 6, DRUM_TEMPO + 10, 1, DRUM_TEMPO + 8, 6
	db DRUM_TEMPO + 10, 2, DRUM_TEMPO + 8, 6, DRUM_TEMPO + 10, 5, DRUM_TEMPO + 8, 2
	db DRUM_TEMPO + 10, 1, DRUM_TEMPO + 8, 6, DRUM_TEMPO + 10, 1, DRUM_TEMPO + 8, 6
	db DRUM_TEMPO + 10, 2, DRUM_TEMPO + 8, 6, DRUM_TEMPO + 10, 5, DRUM_TEMPO + 8, 6
	db DRUM_TEMPO + 10, 1, DRUM_TEMPO + 4, 6, 6, DRUM_TEMPO + 10, 1, DRUM_TEMPO + 8
	db 6, DRUM_TEMPO + 10, 2, DRUM_TEMPO + 8, 2, DRUM_TEMPO + 10, 5, DRUM_TEMPO + 8
	db 2, DRUM_LOOP
DrumPat_5745:
	db DRUM_TEMPO + 10, 7, DRUM_TEMPO + 8, 0, DRUM_TEMPO + 10, 0, DRUM_TEMPO + 8, 6
	db DRUM_REPEAT + 6, DRUM_TEMPO + 10, 1, DRUM_TEMPO + 8, 6, DRUM_TEMPO + 10, 5, DRUM_TEMPO + 8
	db 6, DRUM_REPEAT_END, DRUM_TEMPO + 10, 1, DRUM_TEMPO + 8, 1, DRUM_TEMPO + 10, 5
	db DRUM_TEMPO + 8, 1, DRUM_REPEAT + 4, DRUM_TEMPO + 10, 1, DRUM_TEMPO + 8, 6, DRUM_TEMPO + 10
	db 5, DRUM_TEMPO + 8, 6, DRUM_REPEAT_END
DrumPat_5769:
	db DRUM_TEMPO + 10, 1, DRUM_TEMPO + 8, 6, DRUM_TEMPO + 10, 2, DRUM_TEMPO + 8, 6
	db DRUM_TEMPO + 10, 2, DRUM_TEMPO + 8, 2, DRUM_TEMPO + 10, 6, DRUM_TEMPO + 8, 2
	db DRUM_TEMPO + 10, 1, DRUM_TEMPO + 8, 1, DRUM_TEMPO + 10, 2, DRUM_TEMPO + 8, 5
	db DRUM_TEMPO + 10, 2, DRUM_TEMPO + 8, 2, DRUM_TEMPO + 10, 2, DRUM_TEMPO + 8, 2
	db DRUM_LOOP

; Song 5: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong5:
	call StopAll
	ld de, Song5_Ch3
	call StartMusicCh3
	ld de, Song5_Ch2
	call StartMusicCh2
	ld de, Song5_Ch1
	jp StartMusicCh1
Pat_579F:
	CH_TRANSPOSE $00
	NEXT
Pat_57A2:
	CH_TRANSPOSE $F4
	NEXT
Song5_Ch3:
	dw Pat_581F
	dw Pat_5842
	dw Pat_5842
	ORDER_LOOP Song5_Ch3
Song5_Ch2:
	dw Pat_5883
	dw Pat_57A2
	dw Pat_5898
	dw Pat_579F
	dw Pat_5898
	ORDER_LOOP Song5_Ch2
Song5_Ch1:
	dw Pat_5947
	dw Pat_599A
	dw Pat_59D1
	ORDER_LOOP Song5_Ch1
Pat_57C7:
	LEN 24
	NOTE E_, 2
	LEN 8
	ARP 2
	NOTE E_, 2
	WAIT2
	ARP 0
	NOTE E_, 3
	LEN 24
	NOTE E_, 2
	LEN 8
	ARP 2
	NOTE E_, 2
	WAIT2
	ARP 0
	NOTE E_, 3
	LEN 16
	NOTE E_, 2
	LEN 8
	ARP 2
	NOTE E_, 2
	ARP 0
	NOTE E_, 3
	LEN 24
	NOTE E_, 2
	LEN 8
	ARP 2
	NOTE E_, 2
	WAIT2
	ARP 0
	NOTE E_, 3
	LEN 24
	NOTE E_, 2
	LEN 8
	ARP 2
	NOTE E_, 2
	WAIT2
	ARP 0
	NOTE E_, 3
	NOTE E_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE D_, 3
	NEXT
Pat_57F3:
	LEN 24
	NOTE E_, 2
	LEN 8
	ARP 2
	NOTE E_, 2
	WAIT2
	ARP 0
	NOTE E_, 3
	LEN 24
	NOTE E_, 2
	LEN 8
	ARP 2
	NOTE E_, 2
	WAIT2
	ARP 0
	NOTE E_, 3
	LEN 16
	NOTE E_, 2
	LEN 8
	ARP 2
	NOTE E_, 2
	ARP 0
	NOTE E_, 3
	LEN 24
	NOTE E_, 2
	LEN 8
	ARP 2
	NOTE E_, 2
	WAIT2
	ARP 0
	NOTE E_, 3
	LEN 24
	NOTE E_, 2
	LEN 8
	ARP 2
	NOTE E_, 2
	WAIT2
	ARP 0
	NOTE E_, 3
	NOTE D_, 3
	NOTE E_, 3
	NOTE B_, 2
	NOTE D_, 3
	NEXT
Pat_581F:
	DRUMS $00, DrumPat_5A43
	VOLENV 15, $12, $15, $11
	RELEASE $01, $54
	ARP 0
	VIBRATO $08, $08, $04
	TRANSPOSE $05
	WAVE_SEQ WaveSeq_6AAD
	PAT_CALL Pat_57C7
	DRUMS $00, DrumPat_5A1A
	PAT_CALL Pat_57F3
	PAT_CALL Pat_57C7
	NEXT
Pat_5842:
	PAT_CALL Pat_57C7
	CH_TRANSPOSE $05
	PAT_CALL Pat_57F3
	PAT_CALL Pat_57C7
	PAT_CALL Pat_57F3
	PAT_CALL Pat_57C7
	CH_TRANSPOSE $00
	PAT_CALL Pat_57F3
	NEXT
Pat_5859:
	INSTR 5
	LEN 8
	NOTE E_, 4
	INSTR 7
	NOTE G_, 4
	NOTE E_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE B_, 4
	NOTE G_, 4
	INSTR 5
	PAN_L
	NOTE E_, 4
	INSTR 7
	NOTE C_, 5
	INSTR 5
	PAN_R
	NOTE E_, 4
	INSTR 7
	NOTE B_, 4
	NOTE Fsh, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE B_, 4
	NOTE Fsh, 4
	NEXT
Pat_5883:
	HWENV $C3, $00
	DUTY_75
	RELEASE $02, $20
	AUTOPAN $08
	PAT_CALL Pat_57C7
	RELEASE $00
	PAT_CALL Pat_5859
	PAT_CALL Pat_5859
	NEXT
Pat_5898:
	PAT_CALL Pat_5859
	REPEAT 4
	INSTR 5
	NOTE A_, 4
	INSTR 7
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE G_, 4
	INSTR 5
	PAN_L
	NOTE A_, 4
	INSTR 7
	NOTE D_, 5
	INSTR 5
	PAN_R
	NOTE A_, 4
	INSTR 7
	NOTE C_, 5
	NOTE E_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE D_, 5
	NOTE Fsh, 4
	NOTE C_, 5
	NOTE E_, 4
	REPEAT_END
	PAT_CALL Pat_5859
	NEXT
Pat_58C9:
	HWENV $96, $20, $50
	RELEASE $04, $43
	LENGTH $30
	NOTE Fsh, 5
	LEN 16
	NOTE E_, 5
	ARP 3
	NOTE E_, 5
	ARP_OFF
	LEN 8
	NOTE E_, 5
	LENGTH $38
	NOTE B_, 4
	LEN 16
	NOTE B_, 4
	NOTE Fsh, 5
	LEN 8
	NOTE E_, 5
	LEN 24
	NOTE Fsh, 5
	LEN 16
	NOTE E_, 5
	NOTE B_, 4
	NOTE D_, 5
	LENGTH $30
	NOTE C_, 5
	LEN 16
	NOTE B_, 4
	ARP 3
	NOTE Ash, 4
	ARP_OFF
	LEN 8
	NOTE B_, 4
	LENGTH $38
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	NOTE C_, 5
	LEN 8
	NOTE B_, 4
	LEN 24
	NOTE C_, 5
	LEN 16
	NOTE B_, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 8
	NOTE A_, 4
	LEN 16
	NOTE B_, 4
	LENGTH $30
	NOTE E_, 4
	NEXT
Pat_5908:
	HWENV $96, $20, $50
	RELEASE $04, $43
	LENGTH $30
	NOTE Fsh, 5
	LEN 16
	NOTE E_, 5
	ARP 3
	NOTE E_, 5
	ARP_OFF
	LEN 8
	NOTE E_, 5
	LENGTH $38
	NOTE A_, 4
	LEN 16
	NOTE A_, 4
	NOTE Fsh, 5
	LEN 8
	NOTE E_, 5
	LEN 24
	NOTE Fsh, 5
	LEN 16
	NOTE E_, 5
	NOTE B_, 4
	NOTE D_, 5
	LENGTH $30
	NOTE C_, 5
	LEN 16
	NOTE B_, 4
	ARP 3
	NOTE Ash, 4
	ARP_OFF
	LEN 8
	NOTE B_, 4
	LENGTH $38
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	NOTE C_, 5
	LEN 8
	NOTE B_, 4
	LEN 24
	NOTE C_, 5
	LEN 16
	NOTE B_, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 8
	NOTE A_, 4
	LEN 16
	NOTE B_, 4
	LENGTH $30
	NOTE B_, 4
	NEXT
Pat_5947:
	PINGPONG
	RELEASE $00
	DUTY_12
	VIBRATO $28, $02, $01
	ARP 1
	HWENV $0F, $28, $40
	LENGTH $80
	NOTE B_, 6
	WAIT
	VIBRATO $10, $02, $04
	RELEASE $04, $43
	INSTR 5
	HWENV $1B, $18, $87
	LENGTH $58
	NOTE E_, 4
	HWENV $B2, $00
	LEN 16
	NOTE E_, 4
	LENGTH $98
	NOTE E_, 4
	HWENV $1B, $18, $87
	LENGTH $58
	NOTE E_, 4
	HWENV $B2, $00
	LEN 16
	NOTE E_, 4
	LENGTH $50
	NOTE E_, 4
Pat_597E:
	AUTODUTY $00
	RELEASE $00
	ARP_OFF
	HWENV $C1, $04, $63
	GLIDE $FF
	DUTY_50
	LEN 4
	NOTE D_, 4
	NOTE D_, 4
	LEN 8
	NOTE D_, 4
	NOTE D_, 4
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE C_, 4
	LEN 16
	NOTE Ash, 3
	LEN 8
	NOTE G_, 3
	GLIDE_OFF
	NEXT
Pat_599A:
	PAT_CALL Pat_58C9
	DUTY_75
	ARP 1
	LEN 8
	HWENV $F1, $00
	NOTE D_, 3
	LEN 16
	REST
	LEN 8
	NOTE E_, 3
	REST
	NOTE G_, 3
	REST
	RELEASE $00
	HWENV $3E, $00
	LENGTH $38
	NOTE E_, 3
	ARP_OFF
	DUTY_50
	PAT_CALL Pat_597E
	PAT_CALL Pat_5908
	DUTY_75
	ARP_OFF
	LEN 8
	NOTE A_, 4
	NOTE G_, 4
	LEN 16
	NOTE Fsh, 4
	LEN 8
	ARP 1
	NOTE E_, 3
	LEN 16
	NOTE D_, 3
	LEN 8
	NOTE D_, 3
	LEN 16
	NOTE E_, 3
	LEN 32
	NOTE E_, 3
	PAT_CALL Pat_597E
	NEXT
Pat_59D1:
	AUTODUTY $08
	PAT_CALL Pat_58C9
	AUTODUTY $00
	DUTY_75
	ARP 1
	LEN 8
	HWENV $F1, $00
	NOTE D_, 3
	LEN 16
	REST
	LEN 8
	NOTE E_, 3
	REST
	NOTE G_, 3
	REST
	RELEASE $00
	HWENV $3E, $00
	LENGTH $38
	NOTE E_, 3
	ARP_OFF
	DUTY_50
	PAT_CALL Pat_597E
	AUTODUTY $08
	PAT_CALL Pat_5908
	AUTODUTY $00
	DUTY_75
	ARP_OFF
	LEN 8
	NOTE A_, 3
	NOTE B_, 3
	LEN 16
	NOTE D_, 4
	LEN 8
	NOTE B_, 3
	LEN 16
	NOTE D_, 4
	ARP 1
	NOTE E_, 3
	LEN 8
	WAIT2
	LEN 16
	NOTE Fsh, 3
	LEN 8
	WAIT2
	LEN 16
	NOTE G_, 3
	LEN 8
	WAIT2
	LEN 16
	NOTE A_, 3
	LEN 8
	WAIT2
	NOTE B_, 3
	WAIT2
	NOTE D_, 4
	WAIT2
	NEXT
DrumPat_5A1A:
	db DRUM_TEMPO + 8, DRUM_REPEAT + 3, 1, 5, DRUM_PAN_L, 4, DRUM_PAN_C, 6
	db 11, 6, DRUM_PAN_R, 4, DRUM_PAN_C, 5, DRUM_REPEAT_END, 1
	db 5, DRUM_PAN_L, 4, DRUM_PAN_C, 6, 11, 6, DRUM_PAN_R
	db 4, DRUM_PAN_C, 2, DRUM_LOOP

; Unreferenced (13 bytes)
	db $CB, $08, $08, $CF, $08, $08, $09, $06, $09, $0A, $06, $0A, $FF
DrumPat_5A43:
	db DRUM_TEMPO + 8, DRUM_PAN_C, 5, DRUM_PAN_L, 6, DRUM_PAN_R, 5, DRUM_PAN_L
	db 6, DRUM_PAN_C, 4, DRUM_PAN_R, 6, DRUM_PAN_L, 5, DRUM_PAN_R
	db 6, DRUM_LOOP

; Song 6: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong6:
	call StopAll
	ld de, Song6_Ch3
	call StartMusicCh3
	ld de, Song6_Ch2
	call StartMusicCh2
	ld de, Song6_Ch1
	jp StartMusicCh1
Song6_Ch3:
	dw Pat_5A7C

; Unreferenced (4 bytes)
	db $00, $00, $6A, $5A
Song6_Ch2:
	dw Pat_5AA7

; Unreferenced (4 bytes)
	db $00, $00, $70, $5A
Song6_Ch1:
	dw Pat_5AC6

; Unreferenced (4 bytes)
	db $00, $00, $76, $5A
Pat_5A7C:
	DRUMS $08, DrumPat_5AED
	RELEASE $02, $11
	ARP 0
	VOLENV 15, $11, $1F, $14
	WAVE Wave_75CF
	LEN 16
	NOTE E_, 3
	LEN 8
	GLISS_3
	NOTE E_, 2
	LEN 16
	NOTE D_, 3
	NOTE E_, 2
	NOTE Csh, 3
	NOTE E_, 2
	LEN 8
	NOTE C_, 3
	LEN 16
	NOTE B_, 2
	LEN 8
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE Ash, 2
	LEN 16
	NOTE B_, 2
	LEN 8
	NOTE D_, 3
	NOTE E_, 3
	LEN 48
	NOTE E_, 2
	END
Pat_5AA7:
	HWENV $73, $08, $54
	DUTY_12
	PINGPONG
	ARP 5
	LEN 24
	NOTE E_, 4
	LEN 32
	NOTE E_, 4
	NOTE E_, 4
	LEN 24
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	ARP 4
	LEN 24
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE D_, 5
	NOTE D_, 5
	ARP 5
	LEN 8
	NOTE E_, 5
	DRUMS_OFF
	LEN 40
	WAIT
	END
Pat_5AC6:
	PINGPONG
	HWENV $B1, $08, $47
	DUTY_50
	LEN 8
	NOTE E_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 16
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	VIBRATO $08, $02, $02
	LEN 8
	NOTE E_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE E_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE E_, 5
	NOTE E_, 5
	NOTE D_, 5
	LEN 16
	NOTE E_, 5
	NOTE D_, 5
	LENGTH $10
	NOTE E_, 5
	LENGTH $94
	WAIT2
	END
DrumPat_5AED:
	db 1, 5, 6, 1, 2, 1, 5, 1           ; no DRUM_LOOP: the pattern runs into the next data
	db 6, 1, 5, 1, 2, 6, 1, 5
	db 2, 2, 2, 2, 6, 2, 2, 7

; Song 7: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong7:
	call StopAll
	ld de, Song7_Ch3
	call StartMusicCh3
	ld de, Song7_Ch2
	call StartMusicCh2
	ld de, Song7_Ch1
	jp StartMusicCh1

; Unreferenced (1 bytes)
	db $C9
Song7_Ch3:
	dw Pat_5B83
	ORDER_LOOP Song7_Ch3
Song7_Ch2:
	dw Pat_5BF3
	ORDER_LOOP Song7_Ch2
Song7_Ch1:
	dw Pat_5C1B
	ORDER_LOOP Song7_Ch1
Pat_5B2D:
	GLISS_3
	RELEASE $00
	NOTE C_, 4
	GLISS_3
	NOTE C_, 3
	RELEASE $03, $51
	NOTE C_, 2
	WAIT
	NOTE C_, 3
	NOTE C_, 2
	RELEASE $03, $51
	NOTE C_, 2
	NOTE Csh, 2
	NOTE Csh, 2
	NOTE C_, 2
	WAIT
	GLISS_OFF
	NOTE Csh, 4
	NOTE C_, 3
	NOTE Csh, 4
	RELEASE $00
	GLISS_3
	NOTE C_, 4
	NOTE C_, 3
	NEXT
Pat_5B4C:
	RELEASE $00
	NOTE C_, 4
	GLISS_3
	NOTE C_, 3
	RELEASE $03, $51
	NOTE C_, 2
	WAIT
	NOTE C_, 3
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	NOTE Csh, 3
	WAIT
	NOTE C_, 2
	NOTE Ash, 2
	WAIT
	NOTE C_, 2
	RELEASE $00
	NOTE C_, 3
	NOTE Csh, 3
	NEXT
Pat_5B65:
	RELEASE $00
	NOTE C_, 4
	GLISS_3
	NOTE C_, 3
	RELEASE $03, $51
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	NOTE Csh, 3
	NOTE C_, 3
	NOTE C_, 2
	NOTE Ash, 2
	WAIT
	DRUMS_OFF
	LENGTH $06
	REST
	LEN 12
	DRUMS $03, DrumPat_5CEA
	REST
	NEXT
Pat_5B83:
	DRUMS $06, DrumPat_5C4B
	VOLENV 15, $11, $1F, $14
	WAVE Wave_75CF
	LEN 6
	CH_TRANSPOSE $0C
	REPEAT 7
	PAT_CALL Pat_5B4C
	REPEAT_END
	PAT_CALL Pat_5B65
	WAVE_SEQ WaveSeq_6AAD
	DRUMS $06, DrumPat_5C6E
	LEN 6
	REPEAT 4
	PAT_CALL Pat_5B4C
	REPEAT_END
	DRUMS $06, DrumPat_5CA1
	REPEAT 3
	PAT_CALL Pat_5B4C
	REPEAT_END
	PAT_CALL Pat_5B2D
	DRUMS $06, DrumPat_5C4B
	VOLENV 10, $11, $1F, $13
	RELEASE $03, $51
	GLISS_OFF
	CH_TRANSPOSE $18
	REPEAT 4
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 2
	NOTE Csh, 3
	NOTE Csh, 2
	NOTE C_, 2
	NOTE C_, 3
	NOTE Csh, 2
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE C_, 3
	NOTE C_, 4
	REPEAT_END
	TRANSPOSE $02
	REPEAT 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 2
	NOTE Csh, 3
	NOTE Csh, 2
	NOTE Csh, 2
	NOTE Ash, 2
	NOTE Ash, 1
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 4
	REPEAT_END
	VOLENV 15, $11, $1F, $14
	PAT_CALL Pat_5B4C
	PAT_CALL Pat_5B2D
	TRANSPOSE $00
	NEXT
Pat_5BF3:
	HWENV $20, $00
	DUTY_12
	ARP 1
	LENGTH $30
	VIBRATO $28, $01, $01
	NOTE Fsh, 7
	WAIT
	WAIT
	WAIT
	PINGPONG
	REPEAT 4
	LEN 6
	GLIDE $01
	HWENV $91, $01, $20
	ARP 0
	PINGPONG
	RELEASE $02, $00
	NOTE C_, 6
	NOTE Csh, 6
	NOTE D_, 6
	NOTE Dsh, 6
	NOTE E_, 6
	NOTE F_, 6
	NOTE Fsh, 6
	NOTE G_, 6
	REPEAT_END
	GLIDE_OFF
	NEXT
Pat_5C1B:
	LEN 6
	DUTY_50
	HWENV $80, $00
	PINGPONG
	REPEAT 7
	PAT_CALL Pat_5B4C
	REPEAT_END
	PAT_CALL Pat_5B65
	HWENV $F0, $00
	LEN 6
	REPEAT 4
	PAT_CALL Pat_5B4C
	REPEAT_END
	REPEAT 3
	PAT_CALL Pat_5B4C
	REPEAT_END
	PAT_CALL Pat_5B2D
	HWENV $A0, $00
	REPEAT 4
	PAT_CALL Pat_5B2D
	REPEAT_END
	REPEAT 3
	PAT_CALL Pat_5B4C
	REPEAT_END
	PAT_CALL Pat_5B2D
	NEXT
DrumPat_5C4B:
	db 7, 0, 0, 0, 1, 6, 5, 0
	db 1, 0, 5, 0, 1, 6, 6, 6
	db DRUM_REPEAT + 7, 1, 0, 5, 0, 1, 6, 5
	db 0, 1, 0, 5, 0, 1, 6, 6
	db 6, DRUM_REPEAT_END, DRUM_LOOP
DrumPat_5C6E:
	db 7, 0, 4, 0, 2, 0, 4, 2
	db 1, 2, 14, 0, 2, 0, 4, 0
	db DRUM_REPEAT + 2, 1, 0, 4, 0, 2, 0, 4
	db 2, 1, 2, 14, 0, 2, 0, 4
	db 0, DRUM_REPEAT_END, 1, 0, 4, 0, 2, 0
	db 4, 2, 1, 2, 14, 0, 2, 0
	db 2, 2, DRUM_LOOP
DrumPat_5CA1:
	db 7, 0, DRUM_PAN_R, 4, DRUM_PAN_C, 6, 2, 6
	db DRUM_PAN_L, 4, DRUM_PAN_C, 2, 1, 6, DRUM_PAN_R, 4
	db DRUM_PAN_C, 6, 2, 6, DRUM_PAN_L, 4, DRUM_PAN_C, 6
	db DRUM_REPEAT + 2, 1, 6, DRUM_PAN_R, 4, DRUM_PAN_C, 6, 2
	db 6, DRUM_PAN_L, 4, DRUM_PAN_C, 2, 1, 6, DRUM_PAN_R
	db 4, DRUM_PAN_C, 6, 2, 6, DRUM_PAN_L, 4, DRUM_PAN_C
	db 6, DRUM_REPEAT_END, 1, 6, DRUM_PAN_R, 4, DRUM_PAN_C, 6
	db 2, 6, DRUM_PAN_L, 4, DRUM_PAN_C, 2, 1, 2
	db DRUM_PAN_R, 4, DRUM_PAN_C, 6, 2, 2, 2, 2
	db DRUM_LOOP
DrumPat_5CEA:
	db 1, 1, 1, 1, DRUM_LOOP

; Song 8: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong8:
	call StopAll
	ld de, Song8_Ch3
	call StartMusicCh3
	ld de, Song8_Ch2
	call StartMusicCh2
	ld de, Song8_Ch1
	jp StartMusicCh1
Song8_Ch3:
	dw Pat_5D73
	dw Pat_5D85
	dw Pat_5D85
	dw Pat_5D8C
	dw Pat_5D8C
	dw Pat_5DE5
	dw Pat_5DF0
	ORDER_LOOP Song8_Ch3
Song8_Ch2:
	dw Pat_5E31
	dw Pat_5E41
	dw Pat_5E41
	dw Pat_5E41
	dw Pat_5EA8
	ORDER_LOOP Song8_Ch2
Song8_Ch1:
	dw Pat_5E46
	dw Pat_5EE5
	dw Pat_5EE5
	dw Pat_5D9A
	dw Pat_5EE5
	ORDER_LOOP Song8_Ch1
Pat_5D32:
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 4
	NOTE D_, 3
	NOTE C_, 3
	NOTE D_, 2
	NOTE D_, 4
	NOTE D_, 3
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 4
	NOTE D_, 3
	NOTE C_, 3
	NOTE D_, 2
	NOTE D_, 4
	NOTE D_, 3
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE C_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 3
	NOTE F_, 3
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 3
	NOTE F_, 3
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE F_, 3
	NOTE G_, 3
	NEXT
Pat_5D73:
	DRUMS $08, DrumPat_5F1D
	VOLENV 15, $00, $2F, $12
	TRANSPOSE $04
	ARP 0
	WAVE_SEQ WaveSeq_6AAD
	LEN 8
	PAT_GOTO Pat_5D32
Pat_5D85:
	DRUMS $08, DrumPat_5F4F
	PAT_GOTO Pat_5D32
Pat_5D8C:
	DRUMS $08, DrumPat_5F3B
	WAVE Wave_75CF
	VOLENV 15, $00, $00, $00
	PAT_GOTO Pat_5DF0
Pat_5D9A:
	CH_TRANSPOSE $F4
	HWENV $90, $00
	LEN 8
	GLISS_3
	NOTE D_, 3
	NOTE D_, 4
	RELEASE $03, $51
	NOTE D_, 3
	WAIT
	RELEASE $00
	NOTE D_, 3
	WAIT
	REST
	RELEASE $03, $51
	GLISS_OFF
	NOTE D_, 3
	GLISS_1
	NOTE F_, 3
	NOTE D_, 3
	NOTE D_, 3
	WAIT
	RELEASE $00
	NOTE D_, 3
	NOTE F_, 3
	REST
	GLISS_3
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 4
	RELEASE $03, $51
	NOTE D_, 3
	WAIT
	RELEASE $00
	NOTE D_, 3
	WAIT
	REST
	RELEASE $03, $51
	GLISS_OFF
	NOTE D_, 3
	GLISS_1
	NOTE F_, 3
	NOTE D_, 3
	NOTE D_, 3
	WAIT
	RELEASE $00
	GLISS_OFF
	NOTE D_, 4
	GLISS_1
	NOTE F_, 4
	GLISS_3
	NOTE D_, 3
	NOTE C_, 4
	CH_TRANSPOSE $00
	PAT_CALL Pat_5DF0
	CH_TRANSPOSE $F4
	NEXT
Pat_5DE5:
	DRUMS $08, DrumPat_5F1D
	WAVE Wave_75CF
	VOLENV 15, $00, $00, $00
Pat_5DF0:
	GLISS_3
	NOTE D_, 3
	NOTE D_, 4
	RELEASE $03, $51
	NOTE D_, 3
	WAIT
	RELEASE $00
	NOTE D_, 3
	WAIT
	NOTE D_, 2
	RELEASE $03, $51
	GLISS_OFF
	NOTE D_, 3
	GLISS_1
	NOTE F_, 3
	NOTE D_, 3
	NOTE D_, 3
	WAIT
	RELEASE $00
	NOTE D_, 3
	NOTE F_, 3
	NOTE D_, 2
	GLISS_3
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 4
	RELEASE $03, $51
	NOTE D_, 3
	WAIT
	RELEASE $00
	NOTE D_, 3
	WAIT
	NOTE D_, 2
	RELEASE $03, $51
	GLISS_OFF
	NOTE D_, 3
	GLISS_1
	NOTE F_, 3
	NOTE D_, 3
	NOTE D_, 3
	WAIT
	RELEASE $00
	GLISS_OFF
	NOTE D_, 4
	GLISS_1
	NOTE F_, 4
	GLISS_3
	NOTE D_, 3
	NOTE C_, 4
	GLISS_OFF
	RELEASE $00
	NEXT
Pat_5E31:
	VIBRATO $08, $01, $04
	HWENV $A1, $08, $40
	DUTY_50
	LEN 8
	PINGPONG
	CH_TRANSPOSE $00
	PAT_GOTO Pat_5D32
Pat_5E41:
	CH_TRANSPOSE $07
	PAT_GOTO Pat_5D32
Pat_5E46:
	AUTOPAN $08
	DUTY_75
	HWENV $F1, $00
	LEN 8
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	WAIT
	WAIT
	WAIT
	WAIT
	HWENV $81, $08, $51
	NOTE D_, 5
	WAIT
	NOTE D_, 5
	NOTE D_, 4
	WAIT
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	HWENV $F1, $00
	NOTE D_, 2
	WAIT
	WAIT
	NOTE D_, 2
	WAIT
	WAIT
	WAIT
	WAIT
	HWENV $81, $08, $51
	NOTE D_, 5
	WAIT
	NOTE D_, 5
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	NOTE D_, 4
	PAN_R
	NOTE F_, 4
	HWENV $F1, $00
	NOTE F_, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	WAIT
	WAIT
	WAIT
	WAIT
	HWENV $81, $08, $51
	NOTE D_, 5
	WAIT
	NOTE D_, 5
	NOTE D_, 4
	WAIT
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	HWENV $F1, $00
	NOTE G_, 2
	WAIT
	WAIT
	NOTE G_, 2
	WAIT
	WAIT
	WAIT
	WAIT
	HWENV $81, $08, $51
	NOTE D_, 5
	WAIT
	NOTE D_, 5
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	NEXT
Pat_5EA8:
	ARP_OFF
	CH_TRANSPOSE $F4
	PINGPONG_OFF
	LEN 24
	HWENV $96, $00
	NOTE D_, 5
	AUTOPAN $08
	HWENV $91, $18, $62
	RELEASE $04, $33
	LEN 32
	NOTE D_, 4
	NOTE C_, 5
	LENGTH $30
	NOTE A_, 4
	LEN 16
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 8
	NOTE A_, 4
	LEN 24
	NOTE F_, 4
	LEN 32
	NOTE D_, 4
	LEN 16
	NOTE C_, 4
	LEN 32
	NOTE D_, 4
	NOTE C_, 5
	LENGTH $30
	NOTE A_, 4
	LEN 16
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 8
	NOTE G_, 4
	LEN 24
	NOTE A_, 4
	LENGTH $28
	NOTE G_, 4
	CH_TRANSPOSE $00
	RELEASE $00
	AUTOPAN $00
	NEXT
Pat_5EE5:
	VIBRATO $08, $01, $04
	PAN_C
	AUTOPAN $00
	DUTY_50
	HWENV $F1, $18, $82
	RELEASE $04, $33
	LEN 32
	NOTE D_, 4
	NOTE C_, 5
	LENGTH $30
	NOTE A_, 4
	LEN 16
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 8
	NOTE A_, 4
	LEN 24
	NOTE F_, 4
	LEN 32
	NOTE D_, 4
	LEN 16
	NOTE C_, 4
	LEN 32
	NOTE D_, 4
	NOTE C_, 5
	LENGTH $30
	NOTE A_, 4
	LEN 16
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 8
	NOTE G_, 4
	LEN 24
	NOTE A_, 4
	LENGTH $40
	NOTE G_, 4
	CH_TRANSPOSE $00
	RELEASE $00
	NEXT
DrumPat_5F1D:
	db 7, 0, 0, 0, 1, 0, 0, 0
	db DRUM_REPEAT + 6, 1, 0, 0, 0, 1, 0, 0
	db 0, DRUM_REPEAT_END, 1, 0, 0, 0, DRUM_TEMPO + 4, 2
	db 2, DRUM_TEMPO + 8, 2, 2, 2, DRUM_LOOP
DrumPat_5F3B:
	db 1, 6, 1, 6, 2, 6, 6, 2
	db 1, 2, 1, 6, 2, 6, DRUM_TEMPO + 4, 6
	db 6, DRUM_TEMPO + 8, 2, DRUM_LOOP
DrumPat_5F4F:
	db 1, 6, 1, 6, 2, 6, 1, 6
	db 1, 6, 5, 6, 2, 6, 5, 1
	db 6, 1, 1, 6, 2, 6, 1, 6
	db 1, 6, 5, 6, 2, 6, 5, 1
	db DRUM_LOOP

; Song 9: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong9:
	call StopAll
	ld de, Song9_Ch3
	call StartMusicCh3
	ld de, Song9_Ch2
	call StartMusicCh2
	ld de, Song9_Ch1
	jp StartMusicCh1
Song9_Ch3:
	dw Pat_5FC6
	dw Pat_5FE4
	dw Pat_5FE4
	dw Pat_601D
	ORDER_LOOP Song9_Ch3
Song9_Ch2:
	dw Pat_6042
	ORDER_LOOP Song9_Ch2
Song9_Ch1:
	dw Pat_5FB1
	dw Pat_6064
	dw Pat_6070
	dw Pat_6070
	dw Pat_6070
	dw Pat_6083
	dw Pat_6083
	dw Pat_6083
	dw Pat_6083
	dw Pat_6083
	dw Pat_6083
	ORDER_LOOP Song9_Ch1
Pat_5FB1:
	VIBRATO $00, $01, $04
	HWENV $A7, $00
	DUTY_50
	ARP_OFF
	AUTODUTY $00
	CH_TRANSPOSE $00
	REPEAT 2
	LENGTH $FC
	NOTE C_, 2
	LEN 36
	REST
	REPEAT_END
	NEXT
Pat_5FC6:
	DRUMS $09, DrumPat_6089
	VOLENV 15, $11, $10, $12
	VIBRATO $09, $04, $04
	WAVE Wave_752F
	TRANSPOSE $00
	REPEAT 2
	LENGTH $F0
	NOTE C_, 3
	LEN 12
	GLIDE $FF
	WAIT
	LEN 36
	GLIDE_OFF
	REST
	REPEAT_END
	NEXT
Pat_5FE4:
	DRUMS $09, DrumPat_6089
	TRANSPOSE $00
	LENGTH $F0
	NOTE C_, 3
	LEN 12
	GLIDE $FF
	WAIT
	LEN 36
	GLIDE_OFF
	REST
	TRANSPOSE $05
	LENGTH $F0
	NOTE C_, 3
	LEN 12
	GLIDE $FF
	WAIT
	LEN 36
	GLIDE_OFF
	REST
	DRUMS $09, DrumPat_60A9
	TRANSPOSE $03
	LENGTH $F0
	NOTE C_, 3
	LEN 12
	GLIDE $FF
	WAIT
	LEN 36
	GLIDE_OFF
	REST
	TRANSPOSE $02
	LENGTH $F0
	NOTE C_, 3
	LEN 12
	GLIDE $FF
	WAIT
	LEN 36
	GLIDE_OFF
	REST
	NEXT
Pat_601D:
	TRANSPOSE $00
	DRUMS $09, DrumPat_6089
	REPEAT 4
	RELEASE $03, $50
	LEN 9
	NOTE C_, 3
	WAIT
	NOTE C_, 4
	NOTE C_, 3
	WAIT
	NOTE C_, 3
	NOTE Dsh, 3
	WAIT
	NOTE Dsh, 4
	NOTE Dsh, 3
	WAIT
	REST
	RELEASE $00
	NOTE F_, 3
	WAIT
	GLIDE $FF
	WAIT
	LEN 5
	WAIT
	LEN 4
	REST
	GLIDE_OFF
	REPEAT_END
	NEXT
Pat_6042:
	PINGPONG
	VIBRATO $00, $02, $04
	HWENV $93, $1B, $65
	DUTY_50
	LEN 9
	RELEASE $09, $51
	ARP 21
	REPEAT 2
	NOTE C_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE D_, 3
	WAIT
	WAIT
	REST
	REPEAT_END
	NEXT
Pat_6064:
	HWENV $83, $1B, $55
	DUTY_12
	LEN 9
	CH_TRANSPOSE $0C
	RELEASE $09, $51
	ARP 0
Pat_6070:
	REPEAT 2
	WAIT
	WAIT
	NOTE C_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE D_, 3
	WAIT
	REPEAT_END
	NEXT
Pat_6083:
	AUTODUTY $03
	ARP 20
	PAT_GOTO Pat_6070
DrumPat_6089:
	db 7, 0, 1, 6, 2, 6, 5, 3
	db 5, 3, 1, 6, 2, 1, 5, 1
	db 1, 6, 1, 6, 2, 6, 5, 3
	db 5, 3, 1, 6, 2, 0, 0, 0
DrumPat_60A9:
	db 1, 6, 1, 6, 2, 6, 5, 3
	db 5, 3, 1, 6, 2, 1, 5, 1
	db 1, 6, 1, 6, 2, 6, 5, 3
	db 5, 3, 1, 6, 2, 0, 0, 0
	db DRUM_LOOP

; Song 10: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong10:
	call StopAll
	ld de, Song10_Ch3
	call StartMusicCh3
	ld de, Song10_Ch2
	call StartMusicCh2
	ld de, Song10_Ch1
	jp StartMusicCh1
Song10_Ch3:
	dw Pat_6109
	dw Pat_6195
	dw Pat_6195
	dw Pat_61E8
	dw Pat_6212
	ORDER_LOOP Song10_Ch3
Song10_Ch2:
	dw Pat_613E
	dw Pat_6259
	dw Pat_6259
	dw Pat_62B0
	dw Pat_62EB
	ORDER_LOOP Song10_Ch2
Song10_Ch1:
	dw Pat_6162
	dw Pat_6339
	dw Pat_6339
	dw Pat_639A
	dw Pat_63A8
	ORDER_LOOP Song10_Ch1
Pat_6109:
	DRUMS $0B, DrumPat_63EA
	VOLENV 15, $11, $1A, $13
	RELEASE $02, $51
	CH_TRANSPOSE $0C
	VIBRATO $0B, $04, $05
	WAVE_SEQ WaveSeq_6AAD
	LEN 11
	REPEAT 2
	ARP 0
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	REPEAT_END
	NOTE C_, 2
	WAIT
	NOTE C_, 3
	NOTE C_, 2
	WAIT
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	WAIT
	NOTE C_, 3
	WAIT
	NOTE C_, 2
	DRUMS $0B, DrumPat_63ED
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NEXT
Pat_613E:
	HWENV $A1, $05, $45
	RELEASE $03, $20
	DUTY_75
	ARP 15
	LEN 11
	CH_TRANSPOSE $0C
	REPEAT 2
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	REPEAT_END
	ARP 14
	REPEAT 2
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	REPEAT_END
	CH_TRANSPOSE $00
	NEXT
Pat_6162:
	HWENV $60, $00
	DUTY_50
	ARP 4
	LEN 11
	CH_TRANSPOSE $18
	PINGPONG_OFF
	VIBRATO $00, $08, $02
	GLIDE $FE
	NOTE C_, 2
	NOTE Csh, 2
	NOTE D_, 2
	NOTE Dsh, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE Fsh, 2
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
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE Csh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	GLIDE_OFF
	CH_TRANSPOSE $00
	NEXT
Pat_6195:
	DRUMS $0B, DrumPat_63F1
	VOLENV 15, $11, $1A, $13
	RELEASE $02, $51
	CH_TRANSPOSE $0C
	VIBRATO $0B, $04, $05
	WAVE Wave_75DF
	ARP 0
	LEN 33
	NOTE F_, 2
	LEN 11
	NOTE F_, 2
	NOTE Gsh, 2
	LEN 22
	NOTE Ash, 2
	NOTE F_, 2
	NOTE Gsh, 2
	ARP 3
	NOTE Gsh, 2
	ARP 0
	NOTE F_, 2
	LEN 11
	NOTE Gsh, 2
	LEN 33
	NOTE F_, 2
	LEN 11
	NOTE F_, 2
	NOTE Gsh, 2
	LEN 22
	NOTE Ash, 2
	NOTE F_, 2
	NOTE Gsh, 2
	ARP 3
	NOTE Gsh, 2
	ARP 0
	NOTE F_, 2
	LEN 11
	NOTE Gsh, 2
	LEN 33
	NOTE F_, 2
	LEN 11
	NOTE F_, 2
	NOTE Gsh, 2
	LEN 22
	NOTE Ash, 2
	NOTE F_, 2
	NOTE Gsh, 2
	ARP 3
	NOTE Gsh, 2
	ARP 0
	NOTE F_, 2
	LEN 11
	NOTE Gsh, 2
	LEN 33
	NOTE G_, 2
	LEN 11
	NOTE G_, 2
	NOTE B_, 2
	LEN 22
	NOTE D_, 3
	NOTE Fsh, 2
	NOTE Ash, 2
	ARP 3
	NOTE B_, 2
	ARP 0
	LEN 11
	NOTE Ash, 2
	LEN 22
	NOTE Fsh, 2
	NEXT
Pat_61E8:
	DRUMS $0B, DrumPat_6424
	WAVE_SEQ WaveSeq_6AAD
Pat_61EF:
	REPEAT 2
	ARP 0
	LEN 33
	NOTE F_, 2
	LEN 11
	NOTE F_, 2
	NOTE Gsh, 2
	LEN 22
	NOTE Ash, 2
	NOTE F_, 2
	NOTE Gsh, 2
	ARP 3
	NOTE Gsh, 2
	ARP 0
	NOTE F_, 2
	LEN 11
	NOTE Gsh, 2
	LEN 33
	NOTE F_, 2
	LEN 11
	NOTE F_, 2
	NOTE Gsh, 2
	LEN 22
	NOTE Ash, 2
	NOTE F_, 2
	NOTE Gsh, 2
	ARP 3
	NOTE Gsh, 2
	ARP 0
	LEN 11
	NOTE F_, 2
	NOTE Gsh, 2
	NOTE Ash, 2
	REPEAT_END
	NEXT
Pat_6212:
	WAVE Wave_75DF
	DRUMS $0B, DrumPat_63F1
	ARP 0
	LEN 33
	NOTE C_, 2
	LEN 11
	NOTE C_, 2
	NOTE Dsh, 2
	LEN 22
	NOTE F_, 2
	NOTE C_, 2
	NOTE Dsh, 2
	ARP 3
	NOTE Dsh, 2
	ARP 0
	NOTE C_, 2
	LEN 11
	NOTE Dsh, 2
	LEN 33
	NOTE C_, 2
	LEN 11
	NOTE C_, 2
	NOTE Dsh, 2
	LEN 22
	NOTE F_, 2
	NOTE C_, 2
	NOTE Dsh, 2
	ARP 3
	NOTE Dsh, 2
	ARP 0
	LEN 11
	NOTE C_, 2
	NOTE Dsh, 2
	NOTE F_, 2
	LEN 33
	NOTE Ash, 2
	LEN 11
	NOTE Ash, 2
	NOTE Csh, 3
	LEN 22
	NOTE Dsh, 3
	NOTE Ash, 2
	NOTE Csh, 3
	ARP 3
	NOTE Csh, 3
	ARP 0
	NOTE Ash, 2
	LEN 11
	NOTE Csh, 3
	LEN 33
	NOTE Ash, 2
	LEN 11
	NOTE Ash, 2
	NOTE Csh, 3
	LEN 22
	NOTE Dsh, 3
	NOTE Ash, 2
	NOTE Csh, 3
	ARP 3
	NOTE Csh, 3
	ARP 0
	LEN 11
	NOTE Ash, 2
	NOTE Csh, 3
	NOTE Dsh, 3
	NEXT
Pat_6259:
	VIBRATO $0B, $02, $04
	HWENV $91, $04, $45
	RELEASE $03, $20
	DUTY_75
	ARP 5
	LEN 11
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	ARP 4
	LEN 22
	NOTE Gsh, 4
	LEN 11
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	ARP 5
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	LEN 22
	NOTE C_, 5
	LEN 11
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	ARP 4
	LEN 22
	NOTE Gsh, 4
	LEN 11
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 22
	NOTE G_, 4
	LEN 11
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 22
	NOTE Fsh, 4
	LEN 11
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	NEXT
Pat_62B0:
	ARP 5
	LEN 22
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	DUTY_75
	ARP_OFF
	HWENV $A6, $16, $50
	RELEASE $01, $41
	LEN 33
	NOTE C_, 3
	LEN 11
	NOTE C_, 3
	NOTE Dsh, 3
	LEN 22
	NOTE F_, 3
	NOTE C_, 3
	NOTE Dsh, 3
	ARP 3
	NOTE Dsh, 3
	ARP_OFF
	NOTE C_, 3
	LEN 11
	NOTE Dsh, 3
	LEN 33
	NOTE F_, 3
	LEN 11
	NOTE F_, 3
	NOTE Gsh, 3
	LEN 22
	NOTE Ash, 3
	NOTE F_, 3
	NOTE Gsh, 3
	ARP 3
	NOTE Gsh, 3
	ARP_OFF
	LEN 11
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NEXT
Pat_62EB:
	HWENV $91, $04, $45
	RELEASE $03, $20
	ARP 5
	LEN 11
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	LEN 22
	NOTE C_, 4
	LEN 11
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	LEN 22
	NOTE C_, 4
	LEN 11
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 4
	NOTE Ash, 3
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	LEN 22
	NOTE Ash, 3
	LEN 11
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 4
	NOTE Ash, 3
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	LEN 22
	NOTE Ash, 3
	LEN 11
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 4
	NOTE Ash, 3
	NOTE Ash, 4
	NOTE Ash, 3
	NEXT
Pat_6339:
	HWENV $C2, $0E, $30
	PINGPONG
	VIBRATO $0B, $01, $04
	LEN 11
	ARP 1
	DUTY_75
	NOTE F_, 3
	ARP_OFF
	DUTY_50
	NOTE F_, 4
	LEN 22
	NOTE Gsh, 4
	LEN 11
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 22
	NOTE Dsh, 4
	NOTE F_, 4
	DUTY_75
	ARP 1
	NOTE F_, 3
	LEN 11
	NOTE Gsh, 3
	NOTE F_, 3
	DUTY_50
	ARP_OFF
	NOTE F_, 4
	LEN 22
	NOTE Gsh, 4
	LEN 11
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 22
	NOTE Dsh, 4
	NOTE C_, 4
	DUTY_75
	ARP 1
	NOTE F_, 3
	LEN 11
	NOTE Gsh, 3
	NOTE F_, 3
	DUTY_50
	ARP_OFF
	NOTE F_, 4
	LEN 22
	NOTE Gsh, 4
	LEN 11
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 22
	NOTE Dsh, 4
	NOTE F_, 4
	DUTY_75
	ARP 1
	NOTE F_, 3
	LEN 11
	NOTE Gsh, 3
	NOTE G_, 3
	ARP_OFF
	DUTY_50
	NOTE G_, 4
	LEN 22
	NOTE B_, 4
	LEN 11
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE Csh, 4
	ARP 1
	DUTY_75
	NOTE Fsh, 3
	ARP_OFF
	DUTY_50
	NOTE Fsh, 4
	LEN 22
	NOTE Ash, 4
	LEN 11
	NOTE Ash, 4
	NOTE Fsh, 4
	NOTE Csh, 4
	NOTE Ash, 3
	NEXT
Pat_639A:
	HWENV $A6, $16, $50
	RELEASE $01, $41
	DUTY_75
	PAT_CALL Pat_61EF
	RELEASE $00
	NEXT
Pat_63A8:
	HWENV $B2, $0B, $70
	DUTY_75
	ARP 23
	LENGTH $6E
	NOTE G_, 4
	GLISS_1
	LEN 22
	NOTE F_, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	LEN 11
	NOTE G_, 4
	NOTE Gsh, 4
	LENGTH $4D
	NOTE G_, 4
	LEN 11
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Dsh, 4
	LEN 22
	NOTE Csh, 4
	LEN 11
	NOTE Csh, 4
	LEN 22
	NOTE F_, 4
	LEN 11
	NOTE F_, 4
	LEN 22
	NOTE Ash, 4
	LEN 11
	NOTE Ash, 4
	LEN 22
	NOTE Csh, 5
	LEN 11
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Csh, 5
	LEN 33
	NOTE Ash, 4
	NOTE F_, 4
	LENGTH $58
	NOTE Csh, 4
	LEN 11
	GLIDE $FF
	ARP 1
	HWENV $B0, $00
	NOTE C_, 4
	WAIT
	GLIDE_OFF
	GLISS_OFF
	NEXT
DrumPat_63EA:
	db 1, 6, DRUM_LOOP
DrumPat_63ED:
	db 1, 2, 2, DRUM_LOOP
DrumPat_63F1:
	db 7, 0, 2, 1, 1, 6, 2, 1
	db 6, 1, 2, 1, 1, 6, 2, 4
	db DRUM_REPEAT + 2, 1, 6, 2, 1, 1, 6, 2
	db 1, 6, 1, 2, 1, 1, 6, 2
	db 4, DRUM_REPEAT_END, 1, 6, 2, 1, 1, 6
	db 2, 1, 6, 1, 2, 1, 1, 6
	db 2, 2, DRUM_LOOP
DrumPat_6424:
	db 7, 0, 2, 1, 1, 1, 2, 1
	db 6, 1, 2, 1, 6, 1, 2, 14
	db 1, 6, 2, 1, 1, 1, 2, 1
	db 6, 1, 2, 1, 6, 1, 2, 2
	db DRUM_LOOP

; Song 1: instrument table 1, arpeggio table 1 (the one SndInit sets)
; API song slots 1, 11 all start this routine
PlaySong1:
	call StopAll
	ld de, Song1_Ch3
	call StartMusicCh3
	ld de, Song1_Ch2
	call StartMusicCh2
	ld de, Song1_Ch1
	jp StartMusicCh1

; Unreferenced (1 bytes)
	db $C9
Song1_Ch3:
	dw Pat_6498
	dw Pat_6498
	dw Pat_6491
	dw Pat_64AC
	dw Pat_64B3
	dw Pat_64B3
	dw Pat_64D5
	ORDER_LOOP Song1_Ch3
Song1_Ch2:
	dw Pat_64F3
	dw Pat_64F3
	dw Pat_6540
	dw Pat_658D
	dw Pat_65DA
	dw Pat_6614
	dw Pat_664E
	ORDER_LOOP Song1_Ch2
Song1_Ch1:
	dw Pat_668F
	dw Pat_668F
	dw Pat_66DC
	dw Pat_6704
	dw Pat_6724
	dw Pat_6745
	dw Pat_6766
	ORDER_LOOP Song1_Ch1
Pat_6491:
	DRUMS $07, DrumPat_6797
	PAT_GOTO Pat_64AC
Pat_6498:
	DRUMS $07, DrumPat_6774
	TRANSPOSE $04
	ARP 0
	VOLENV 15, $00, $00, $00
	RELEASE $04, $51
	LEN 14
	CH_TRANSPOSE $0C
	WAVE_SEQ WaveSeq_6979
Pat_64AC:
	REPEAT 8
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	REPEAT_END
	NEXT
Pat_64B3:
	LEN 14
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NEXT
Pat_64D5:
	LEN 28
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	NOTE Dsh, 2
	LEN 28
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	NOTE Dsh, 2
	LEN 28
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	NOTE Dsh, 2
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE Dsh, 2
	NEXT
Pat_64F3:
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 7
	NOTE C_, 4
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 7
	NOTE C_, 4
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 7
	NOTE C_, 4
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 7
	NOTE C_, 4
	NOTE C_, 4
	NEXT
Pat_6540:
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 7
	NOTE C_, 4
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 7
	NOTE C_, 4
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 7
	NOTE C_, 4
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 7
	NOTE C_, 4
	NOTE C_, 4
	NEXT
Pat_658D:
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 7
	NOTE C_, 4
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 7
	NOTE C_, 4
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 7
	NOTE C_, 4
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE C_, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 7
	NOTE C_, 4
	NOTE C_, 4
	NEXT
Pat_65DA:
	INSTR 3
	LEN 14
	NOTE F_, 4
	INSTR 5
	NOTE F_, 4
	INSTR 3
	NOTE F_, 4
	NOTE F_, 4
	INSTR 5
	NOTE F_, 4
	INSTR 3
	NOTE F_, 4
	NOTE F_, 4
	INSTR 5
	NOTE F_, 4
	INSTR 3
	NOTE G_, 4
	INSTR 4
	NOTE Dsh, 4
	INSTR 3
	NOTE G_, 4
	NOTE G_, 4
	INSTR 4
	NOTE Dsh, 4
	INSTR 3
	NOTE G_, 4
	NOTE G_, 4
	INSTR 4
	NOTE Dsh, 4
	INSTR 3
	NOTE Dsh, 4
	INSTR 5
	NOTE C_, 4
	INSTR 3
	NOTE Dsh, 4
	NOTE Dsh, 4
	INSTR 5
	NOTE C_, 4
	INSTR 3
	NOTE Dsh, 4
	NOTE Dsh, 4
	INSTR 5
	NOTE C_, 4
	INSTR 3
	NOTE Csh, 4
	INSTR 4
	NOTE Csh, 4
	INSTR 3
	NOTE Csh, 4
	NOTE Dsh, 4
	INSTR 4
	NOTE Dsh, 4
	INSTR 3
	NOTE Dsh, 4
	NOTE Dsh, 4
	INSTR 4
	NOTE Dsh, 4
	NEXT
Pat_6614:
	INSTR 3
	LEN 14
	NOTE F_, 4
	INSTR 5
	NOTE F_, 4
	INSTR 3
	NOTE F_, 4
	NOTE F_, 4
	INSTR 5
	NOTE F_, 4
	INSTR 3
	NOTE F_, 4
	NOTE F_, 4
	INSTR 5
	NOTE F_, 4
	INSTR 3
	NOTE G_, 4
	INSTR 4
	NOTE Dsh, 4
	INSTR 3
	NOTE G_, 4
	NOTE G_, 4
	INSTR 4
	NOTE Dsh, 4
	INSTR 3
	NOTE G_, 4
	NOTE G_, 4
	INSTR 4
	NOTE Dsh, 4
	INSTR 3
	NOTE Dsh, 4
	INSTR 5
	NOTE C_, 4
	INSTR 3
	NOTE Dsh, 4
	NOTE Dsh, 4
	INSTR 5
	NOTE C_, 4
	INSTR 3
	NOTE Dsh, 4
	NOTE Dsh, 4
	INSTR 5
	NOTE C_, 4
	INSTR 3
	NOTE Csh, 4
	INSTR 4
	NOTE Csh, 4
	INSTR 3
	NOTE Csh, 4
	NOTE Dsh, 4
	INSTR 4
	NOTE Dsh, 4
	INSTR 3
	NOTE Dsh, 4
	NOTE Dsh, 4
	INSTR 4
	NOTE Dsh, 4
	NEXT
Pat_664E:
	INSTR 5
	LEN 14
	NOTE F_, 4
	INSTR 3
	LEN 28
	NOTE F_, 3
	INSTR 5
	LEN 14
	NOTE F_, 4
	INSTR 3
	NOTE F_, 3
	INSTR 5
	LEN 28
	NOTE F_, 4
	INSTR 4
	LEN 14
	NOTE Dsh, 4
	INSTR 5
	NOTE F_, 4
	INSTR 3
	LEN 28
	NOTE F_, 3
	INSTR 5
	LEN 14
	NOTE F_, 4
	INSTR 3
	NOTE F_, 3
	INSTR 5
	LEN 28
	NOTE F_, 4
	INSTR 4
	LEN 14
	NOTE Dsh, 4
	INSTR 5
	NOTE F_, 3
	INSTR 3
	LEN 28
	NOTE F_, 3
	INSTR 5
	LEN 14
	NOTE F_, 3
	INSTR 3
	NOTE F_, 3
	INSTR 5
	LEN 28
	NOTE F_, 3
	INSTR 4
	LEN 14
	NOTE Dsh, 3
	INSTR 5
	NOTE F_, 3
	INSTR 3
	NOTE F_, 4
	NOTE G_, 4
	INSTR 5
	NOTE F_, 3
	INSTR 3
	NOTE Dsh, 4
	INSTR 5
	NOTE F_, 3
	INSTR 3
	NOTE C_, 4
	INSTR 4
	NOTE Dsh, 3
	NEXT
Pat_668F:
	RELEASE $02, $20
	VIBRATO $07, $01, $06
	DUTY_50
	PINGPONG
	HWENV $B1, $07, $71
	LEN 14
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Ash, 3
	NOTE G_, 3
	HWENV $C0, $00
	DUTY_75
	LEN 7
	NOTE C_, 3
	WAIT2
	NOTE Dsh, 3
	WAIT2
	NOTE F_, 3
	WAIT2
	LEN 28
	NOTE C_, 3
	LEN 7
	NOTE Ash, 2
	WAIT2
	NOTE C_, 3
	WAIT2
	HWENV $B1, $07, $71
	DUTY_50
	LEN 14
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Ash, 3
	NOTE C_, 4
	HWENV $C0, $00
	DUTY_75
	LEN 7
	NOTE C_, 3
	WAIT2
	NOTE Dsh, 3
	WAIT2
	NOTE F_, 3
	WAIT2
	NOTE G_, 3
	WAIT2
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE Ash, 3
	WAIT2
	NOTE C_, 4
	WAIT2
	NEXT
Pat_66DC:
	HWENV $80, $00
	RELEASE $04, $62
	GLISS_2
	DUTY_50
	LEN 42
	NOTE Dsh, 4
	LEN 28
	NOTE C_, 4
	LEN 14
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	LEN 42
	NOTE F_, 4
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	LEN 42
	NOTE Ash, 3
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE Ash, 3
	NOTE D_, 4
	NOTE Ash, 3
	LENGTH $46
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NEXT
Pat_6704:
	LEN 42
	NOTE Dsh, 4
	LEN 28
	NOTE C_, 4
	LEN 14
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	LEN 42
	NOTE F_, 4
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	LEN 42
	NOTE Ash, 4
	LEN 28
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	NOTE Ash, 4
	LEN 7
	NOTE A_, 4
	NOTE Gsh, 4
	LENGTH $46
	NOTE G_, 4
	LEN 42
	WAIT2
	NEXT
Pat_6724:
	LEN 42
	NOTE Gsh, 4
	LEN 28
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	LEN 42
	NOTE Ash, 4
	LEN 28
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	LEN 42
	NOTE Dsh, 4
	LEN 28
	NOTE G_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Dsh, 4
	LEN 28
	NOTE F_, 4
	NOTE Csh, 4
	LEN 14
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE F_, 4
	NEXT
Pat_6745:
	LEN 42
	NOTE Gsh, 4
	LEN 28
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	LEN 42
	NOTE Ash, 4
	LEN 28
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	LEN 42
	NOTE Dsh, 5
	LEN 28
	NOTE Ash, 4
	LEN 14
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NEXT
Pat_6766:
	LENGTH $B6
	NOTE F_, 4
	WAIT
	GLISS_OFF
	INSTR 6
	LEN 14
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Ash, 3
	NEXT
DrumPat_6774:
	db DRUM_REPEAT + 3, 1, 0, 4, 0, 1, 6, 4
	db 0, 1, 5, 4, 0, 1, 0, 4
	db 5, DRUM_REPEAT_END, 1, 0, 4, 0, 1, 6
	db 4, 0, 1, 5, 4, 6, 1, 4
	db 10, 10, DRUM_LOOP
DrumPat_6797:
	db DRUM_REPEAT + 3, 1, 0, 4, 0, 2, 6, 4
	db 0, 1, 5, 4, 0, 2, 0, 4
	db 5, DRUM_REPEAT_END, 1, 0, 4, 0, 2, 6
	db 4, 0, 1, 5, 4, 6, 2, 4
	db 10, 10, DRUM_LOOP

; PlaySong table: A = 0-10
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
	dw PlaySong1                        ; A = 10: song 1

; Instrument table 1, entries 1..19 (the song routines point 2 bytes before:
; entry 0 is never read)
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
	dw Instr1_14
	dw Instr1_15
	dw Instr1_16
	dw Instr1_17
	dw Instr1_18
Instr1_0:
	HWENV $C1, $03, $63
	ARP 6
	DUTY_12
	END
Instr1_1:
	HWENV $C1, $00
	ARP 8
	DUTY_12
	PAN_L
	AUTOPAN $03
	END
Instr1_2:
	HWENV $F1, $04, $32
	ARP_OFF
	AUTODUTY $00
	DUTY_50
	GLIDE $FC
	END
Instr1_3:
	HWENV $C1, $04, $10
	ARP 0
	PINGPONG
	END
Instr1_4:
	HWENV $C2, $04, $40
	ARP 4
	AUTODUTY $02
	END
Instr1_5:
	HWENV $C1, $04, $40
	ARP 5
	AUTODUTY $02
	END
Instr1_6:
	HWENV $C2, $06, $50
	DUTY_75
	ARP 0
	END
Instr1_7:
	HWENV $81, $04, $42
	DUTY_12
	END
Instr1_8:
	HWENV $70, $01, $31
	END
Instr1_9:
	HWENV $82, $00
	DUTY_75
	END
Instr1_10:
	HWENV $A1, $00
	DUTY_75
	ARP 0
	END
Instr1_11:
	HWENV $C1, $02, $51
	ARP 0
	DUTY_12
	END
Instr1_12:
	WAVE Wave_74FF
	VOLENV 15, $11, $1F, $11
	ARP_OFF
	END
Instr1_13:
	HWENV $80, $05, $30
	ARP_OFF
	DUTY_75
	ARP 0
	END
Instr1_14:
	HWENV $A0, $00
	ARP 3
	END
Instr1_18:
	HWENV $40, $00
	DUTY_75
	AUTOPAN $03
	END
Instr1_17:
	HWENV $40, $00
	ARP 3
	PAN_R
	END
Instr1_16:
	HWENV $F1, $04, $50
	ARP 1
	DUTY_75
	PAN_R
	NOTE Dsh, 1
	ARP 0
	END
Instr1_15:
	HWENV $B2, $0E, $30
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
	dw Arp13
	dw Arp14
	dw Arp15
	dw Arp16
	dw Arp17
	dw Arp18
	dw Arp19
	dw Arp20
	dw Arp21
	dw Arp22
	dw Arp23

; Unreferenced (8 bytes)
	db $79, $69, $79, $69, $79, $69, $79, $69
Arp0:
	db $0C, $00, ARP_HOLD
Arp3:
	db $00, $00, $00, $01, $01, $01, $02, ARP_HOLD
Arp2:
	db $00, $05, $09, $0C, ARP_HOLD
Arp1:
	db $00, $00, $0C, $0C, ARP_LOOP
Arp4:
	db $00, $04, $07, ARP_LOOP
Arp5:
	db $00, $03, $07, ARP_LOOP
Arp6:
	db $18, $00, ARP_HOLD
Arp7:
	db $00, $01, $02, ARP_HOLD
Arp8:
	db $00, $00, $F4, $F4, ARP_LOOP
Arp9:
	db $02, $02, $01, $01, $00, ARP_HOLD
Arp10:
	db $0C, $00, $00, $00, $00, $00, $00, $00
	db $0C, ARP_HOLD
Arp11:
	db $0C, $00, $00, $00, $00, $00, $00, $0C
	db $0C, $0C, $0C, $0C, $0C, $0C, ARP_HOLD
Arp12:
	db $00, $01, $02, $01, $00, ARP_HOLD
Arp13:
	db $0C, $00, $00, $00, $00, $00, $00, $00
	db $00, $0C, ARP_HOLD
Arp14:
	db $00, $00, $04, $04, $07, $07, ARP_LOOP
Arp15:
	db $00, $00, $03, $03, $07, $07, ARP_LOOP
Arp16:
	db $0C, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $0C, $0C, $0C, $0C, $0C
	db $0C, $0C, $0C, $0C, $0C, $0C, ARP_LOOP
Arp17:
	db $00, $00, $05, $05, $07, $07, $0C, $0C
	db $0C, ARP_LOOP
Arp18:
	db $03, $00, $07, ARP_LOOP
Arp19:
	db $07, $0C, $03, $00, $00, $00, $00, $00
	db $00, $07, $0C, $03, $00, $00, $00, $00
	db $00, $00, ARP_HOLD
Arp20:
	db $00, $07, ARP_LOOP
Arp21:
	db $13, $00, $00, $00, $00, $00, $00, $00
	db $00, ARP_LOOP
Arp22:
	db $0C, $00, $00, $00, $00, $00, $00, $00
	db $00, $0C, ARP_HOLD
Arp23:
	db $0C, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, ARP_LOOP
WaveSeq_6979:
	dw Wave_74FF
	dw Wave_75CF
	dw 0
WaveSeq_697F:
	dw Wave_6A9D
	dw Wave_6A8D
	dw Wave_6A7D
	dw Wave_6A6D
	dw Wave_6A5D
	dw Wave_6A4D
	dw Wave_6A3D
	dw Wave_6A2D
	dw Wave_6A1D
	dw Wave_6A0D
	dw Wave_69FD
	dw Wave_69ED
	dw Wave_69DD
	dw Wave_69CD
	dw Wave_69BD
	dw Wave_69BD
	dw Wave_69CD
	dw Wave_69DD
	dw Wave_69ED
	dw Wave_69FD
	dw Wave_6A0D
	dw Wave_6A1D
	dw Wave_6A2D
	dw Wave_6A3D
	dw Wave_6A4D
	dw Wave_6A5D
	dw Wave_6A6D
	dw Wave_6A7D
	dw Wave_6A8D
	dw Wave_6A9D
	dw 0
Wave_69BD:
	db $24, $68, $AC, $EF, $FF, $FF, $FF, $FF
	db $FF, $FF, $00, $00, $EC, $A8, $64, $20
Wave_69CD:
	db $24, $68, $AC, $EF, $FF, $FF, $FF, $FF
	db $F0, $00, $00, $00, $EC, $A8, $64, $20
Wave_69DD:
	db $24, $67, $AC, $EF, $FF, $FF, $FF, $F0
	db $02, $00, $00, $00, $EC, $A8, $64, $20
Wave_69ED:
	db $24, $67, $AC, $FF, $FF, $FF, $F0, $00
	db $03, $00, $00, $00, $EC, $A8, $64, $20
Wave_69FD:
	db $24, $67, $A0, $FF, $FF, $FF, $00, $00
	db $04, $00, $00, $00, $00, $00, $00, $00
Wave_6A0D:
	db $27, $CF, $F0, $FF, $FF, $F0, $00, $00
	db $05, $00, $00, $00, $00, $00, $00, $00
Wave_6A1D:
	db $27, $CF, $F0, $FF, $FF, $00, $00, $00
	db $06, $00, $00, $00, $00, $00, $00, $00
Wave_6A2D:
	db $FF, $FF, $F0, $FF, $F0, $00, $00, $00
	db $07, $00, $00, $00, $00, $00, $00, $00
Wave_6A3D:
	db $FF, $FF, $F0, $FF, $00, $00, $00, $00
	db $08, $00, $00, $00, $00, $00, $00, $00
Wave_6A4D:
	db $FF, $FF, $F0, $F0, $00, $00, $00, $00
	db $0A, $00, $00, $00, $00, $00, $00, $00
Wave_6A5D:
	db $FF, $FF, $F0, $00, $00, $00, $00, $00
	db $0B, $02, $00, $00, $00, $00, $00, $00
Wave_6A6D:
	db $FF, $FF, $00, $00, $00, $00, $00, $00
	db $0C, $03, $03, $00, $00, $00, $00, $00
Wave_6A7D:
	db $FF, $F0, $00, $00, $00, $00, $00, $00
	db $0D, $04, $04, $04, $00, $00, $00, $00
Wave_6A8D:
	db $FF, $00, $00, $00, $00, $00, $00, $00
	db $0E, $05, $05, $05, $05, $00, $00, $00
Wave_6A9D:
	db $F0, $00, $00, $00, $00, $00, $00, $00
	db $0F, $0F, $0F, $0F, $0F, $07, $07, $00
WaveSeq_6AAD:
	dw Wave_6BA3
	dw Wave_6B93
	dw Wave_6B83
	dw Wave_6B73
	dw Wave_6B63
	dw Wave_6B53
	dw Wave_6B43
	dw Wave_6B33
	dw Wave_6B23
	dw Wave_6B13
	dw Wave_6B03
	dw Wave_6AF3
	dw Wave_6AE3
	dw Wave_6AE3
	dw Wave_6AF3
	dw Wave_6B03
	dw Wave_6B13
	dw Wave_6B23
	dw Wave_6B33
	dw Wave_6B43
	dw Wave_6B53
	dw Wave_6B63
	dw Wave_6B73
	dw Wave_6B83
	dw Wave_6B93
	dw Wave_6BA3
	dw 0
Wave_6AE3:
	db $34, $56, $78, $9A, $BC, $DE, $FF, $F0
	db $0F, $FF, $ED, $CB, $A9, $87, $65, $43
Wave_6AF3:
	db $45, $67, $89, $AB, $CD, $EF, $FF, $1F
	db $F1, $FF, $FE, $DC, $BA, $98, $76, $54
Wave_6B03:
	db $56, $78, $9A, $BC, $DE, $FF, $F1, $2F
	db $F2, $1F, $FF, $ED, $CB, $A9, $87, $65
Wave_6B13:
	db $67, $89, $AB, $CD, $EF, $FF, $12, $3F
	db $F3, $21, $FF, $FE, $DC, $BA, $98, $76
Wave_6B23:
	db $78, $9A, $BC, $DE, $FF, $F1, $23, $4F
	db $F4, $32, $1F, $FF, $ED, $CB, $A9, $87
Wave_6B33:
	db $89, $AB, $CD, $EF, $FF, $12, $34, $5F
	db $F5, $43, $21, $FF, $FE, $DB, $AB, $98
Wave_6B43:
	db $9A, $BC, $DE, $FF, $F1, $23, $45, $6F
	db $F6, $54, $32, $1F, $FF, $ED, $CB, $A9
Wave_6B53:
	db $AB, $CD, $EF, $FF, $12, $34, $56, $7F
	db $F7, $65, $43, $21, $FF, $FE, $DC, $BA
Wave_6B63:
	db $BC, $DE, $FF, $F1, $23, $45, $67, $8F
	db $F8, $76, $54, $32, $1F, $FF, $ED, $CB
Wave_6B73:
	db $CD, $EF, $FF, $12, $34, $56, $78, $9F
	db $F9, $87, $65, $43, $21, $FF, $FE, $DC
Wave_6B83:
	db $DE, $FF, $F1, $23, $45, $67, $89, $AF
	db $FA, $98, $76, $54, $32, $1F, $FF, $ED
Wave_6B93:
	db $EF, $FF, $12, $34, $56, $78, $9A, $BF
	db $FB, $A9, $87, $65, $43, $21, $FF, $FE
Wave_6BA3:
	db $FF, $F1, $23, $45, $67, $89, $AB, $FF
	db $FF, $BA, $98, $76, $54, $32, $1F, $FF

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

; Sound effect 33
Sfx33:
	VOLENV 15, $00, $00, $00
	WAVE Wave_74CF
	LEN 8
	GLIDE $02
	NOTE G_, 2
	WAIT
	GLIDE_OFF
	WAIT
	VOLENV 10, $00, $00, $00
	LEN 8
	GLIDE $02
	NOTE B_, 3
	GLIDE_OFF
	WAIT
	VOLENV 5, $00, $00, $00
	LEN 8
	GLIDE $02
	NOTE B_, 3
	GLIDE_OFF
	WAIT
	END

; Sound effect 3
Sfx03:
	WAVE Wave_751F
	PAN_R
	VOLENV 15, $00, $00, $00
	GLIDE $FE
	LEN 4
	NOTE G_, 5
	END

; Sound effect 4
Sfx04:
	WAVE Wave_751F
	VOLENV 15, $00, $00, $00
	GLIDE $FE
	LEN 4
	NOTE Dsh, 5
	END

; Sound effect 5
Sfx05:
	WAVE Wave_751F
	PAN_L
	VOLENV 15, $00, $00, $00
	GLIDE $FE
	LEN 4
	NOTE B_, 4
	END

; Sound effect 1
Sfx01:
	WAVE Wave_751F
	VOLENV 15, $00, $00, $00
	LEN 1
	NOTE D_, 4
	NOTE Gsh, 3
	END

; Sound effect 2
Sfx02:
	WAVE Wave_751F
	VOLENV 15, $00, $00, $00
	LEN 1
	NOTE B_, 4
	NOTE Gsh, 4
	END

; Sound effect 6
Sfx06:
	WAVE Wave_751F
	VOLENV 15, $00, $00, $00
	LEN 1
	NOTE Dsh, 5
	END

; Unreferenced (84 bytes)
	db $C3, $11, $1F, $11, $7A, $7F, $74, $60, $02, $D3, $15, $68, $C4, $11, $1F, $13
	db $63, $00, $01, $04, $7A, $AF, $74, $80, $AA, $70, $60, $FC, $CC, $2D, $80, $AA
	db $70, $60, $08, $65, $80, $83, $70, $61, $D1, $65, $60, $FF, $65, $68, $7A, $AF
	db $74, $60, $04, $D1, $7B, $F4, $A0, $BD, $00, $00, $00, $21, $C2, $00, $00, $00
	db $21, $C7, $00, $00, $00, $21, $21, $21, $C2, $00, $00, $00, $21, $BD, $00, $00
	db $00, $21, $21, $68

; Sound effect 24
Sfx24:
	VOLENV 15, $11, $1F, $13
	WAVE Wave_752F
	CALL_CODE Code_71E2
	LEN 5
	NOTE C_, 4
	CALL_CODE Code_734A
	LEN 1
	REST
	LEN 10
	GLIDE $FE
	NOTE Dsh, 5
	VOLENV 5, $11, $1F, $13
	NOTE Dsh, 5
	VOLENV 5, $11, $1F, $13
	NOTE Dsh, 5
	END

; Sound effect 7
Sfx07:
	LEN 5
	ARP 6
	WAVE Wave_74DF
	VOLENV 15, $10, $1F, $12
	RELEASE $02, $55
	NOTE C_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	VOLENV 10, $10, $1F, $12
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	VOLENV 5, $10, $1F, $12
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	END

; Sound effect 10
Sfx10:
	CALL_CODE Code_70AA
	VOLENV 15, $00, $00, $00
	ARP 3
	WAVE Wave_759F
	LEN 3
	REST
	CALL_CODE Code_7139
	LEN 5
	GLIDE $FE
	NOTE E_, 3
	END

; Sound effect 11
Sfx11:
	CALL_CODE Code_724E
	VOLENV 10, $11, $1F, $11
	VIBRATO $01, $02, $03
	LEN 5
	GLIDE $FE
	WAVE Wave_747F
	NOTE C_, 6
	END

; Sound effect 20
Sfx20:
	CALL_CODE Code_70D1
	VOLENV 11, $11, $1F, $14
	WAVE Wave_74CF
	LEN 5
	GLIDE $FB
	NOTE C_, 5
	END

; Unreferenced (4 bytes)
	db $80, $D1, $70, $68

; Sound effect 21
Sfx21:
	CALL_CODE Code_70AA
	WAVE Wave_74CF
	VOLENV 15, $11, $1F, $11
	LEN 5
	GLIDE $04
	NOTE A_, 2
	GLIDE $65
	WAIT
	WAIT
	END

; Sound effect 12
Sfx12:
	CALL_CODE Code_7083
	VOLENV 11, $11, $1F, $13
	WAVE Wave_74AF
	LEN 23
	SLIDE_DOWN $03
	NOTE A_, 4
	END

; Sound effect 13
Sfx13:
	CALL_CODE Code_6FE9
	WAVE Wave_747F
	VOLENV 15, $11, $1F, $11
	ARP 0
	LEN 7
	GLIDE $FF
	NOTE Fsh, 2
	END

; Sound effect 15
Sfx15:
	VOLENV 15, $0F, $1F, $14
	LEN 3
	ARP 5
	GLIDE $01
	WAVE Wave_754F
	LEN 40
	NOTE A_, 4
	END

; Sound effect 14
Sfx14:
	VOLENV 15, $11, $5F, $11
	ARP 2
	WAVE Wave_754F
	LEN 7
	NOTE A_, 5
	LEN 6
	NOTE A_, 5
	LEN 5
	NOTE A_, 5
	LEN 4
	NOTE A_, 5
	LEN 3
	NOTE A_, 5
	LEN 2
	NOTE A_, 5
	VOLENV 10, $11, $5F, $11
	NOTE A_, 5
	NOTE A_, 5
	VOLENV 5, $11, $5F, $11
	NOTE A_, 5
	NOTE A_, 5
	END

; Sound effect 17
Sfx17:
	VOLENV 15, $00, $00, $00
	GLIDE $FC
	LEN 10
	CH_TRANSPOSE $3F
	ARP 6
	WAVE Wave_754F
	NOTE A_, 2
	VOLENV 10, $00, $00, $00
	NOTE A_, 2
	VOLENV 5, $00, $00, $00
	NOTE A_, 2
	END

; Sound effect 22
Sfx22:
	CALL_CODE Code_7218
	VOLENV 15, $11, $1F, $11
	WAVE Wave_747F
	LEN 6
	GLIDE $FD
	NOTE D_, 4
	END

; Sound effect 16
Sfx16:
	VOLENV 15, $00, $00, $00
	GLIDE $05
	LEN 10
	WAVE Wave_754F
	NOTE A_, 2
	VOLENV 10, $00, $00, $00
	NOTE A_, 2
	VOLENV 5, $00, $00, $00
	NOTE A_, 2
	END

; Sound effect 19
Sfx19:
	WAVE Wave_760F
	VOLENV 15, $00, $00, $00
	VIBRATO $00, $20, $02
	GLIDE $FF
	CH_TRANSPOSE $08
	LEN 15
	NOTE C_, 5
	VOLENV 10, $00, $00, $00
	NOTE C_, 5
	VOLENV 5, $00, $00, $00
	NOTE C_, 5
	END

; Sound effect 25
Sfx25:
	VOLENV 15, $11, $1F, $12
	GLIDE $FD
	WAVE Wave_73EF
	CALL_CODE Code_6F26
	LEN 9
	NOTE E_, 3
	LEN 7
	NOTE E_, 3
	NOTE D_, 3
	END

; Sound effect 26
Sfx26:
	VOLENV 15, $00, $00, $00
	LEN 8
	CH_TRANSPOSE $E2
	ARP 2
	WAVE Wave_758F
	NOTE A_, 4
	WAVE Wave_743F
	NOTE A_, 4
	WAVE Wave_757F
	NOTE A_, 4
	WAVE Wave_744F
	NOTE A_, 4
	WAVE Wave_759F
	NOTE A_, 4
	END

; Sound effect 27
Sfx27:
	WAVE Wave_747F
	VOLENV 15, $11, $1F, $11
	CALL_CODE Code_6F61
	LEN 5
	GLIDE $FE
	NOTE C_, 3
	GLIDE_OFF
	WAVE Wave_743F
	VOLENV 5, $1F, $00, $20
	CALL_CODE Code_6F8F
	LEN 21
	NOTE E_, 3
	END

; Sound effect 28
Sfx28:
	CALL_CODE Code_738D
	VOLENV 15, $11, $1F, $13
	WAVE Wave_747F
	GLIDE $FE
	LEN 10
	CH_TRANSPOSE $0C
	NOTE C_, 3
	VOLENV 10, $11, $1F, $13
	NOTE C_, 3
	VOLENV 5, $11, $1F, $13
	NOTE C_, 3
	END

; Sound effect 29
Sfx29:
	CALL_CODE Code_7312
	VOLENV 15, $11, $1F, $11
	GLIDE $FF
	WAVE Wave_747F
	LEN 10
	NOTE G_, 2
	CALL_CODE Code_7312
	NOTE G_, 2
	END

; Sound effect 31
Sfx31:
	CALL_CODE Code_727A
	END

; Sound effect 23
Sfx23:
	WAVE Wave_752F
	CALL_CODE Code_71A9
	VOLENV 15, $12, $1F, $12
	LEN 8
	GLIDE $FF
	NOTE A_, 4
	LEN 5
	VOLENV 10, $11, $1F, $12
	NOTE A_, 4
	END

; Sound effect 30
Sfx30:
	VOLENV 10, $15, $1F, $23
	VIBRATO $00, $02, $06
	WAVE Wave_75AF
	LEN 20
	NOTE A_, 5
	WAIT
	END

; Sound effect 18
Sfx18:
	CALL_CODE Code_7139
	VOLENV 15, $00, $00, $00
	WAVE Wave_73EF
	LEN 3
	GLIDE $FF
	NOTE A_, 5
	WAVE Wave_75EF
	WAIT
	GLIDE $FE
	WAVE Wave_761F
	WAIT
	LEN 10
	WAVE Wave_75EF
	VOLENV 10, $00, $00, $00
	NOTE E_, 5
	VOLENV 5, $00, $00, $00
	NOTE E_, 5
	END

; Unreferenced (8 bytes)
	db $80, $4A, $73, $68, $80, $DE, $72, $68

; Sound effect 8
Sfx08:
	VOLENV 15, $11, $2F, $11
	WAVE Wave_74DF
	LEN 8
	NOTE C_, 6
	VOLENV 10, $11, $2F, $11
	NOTE C_, 6
	VOLENV 5, $11, $2F, $11
	NOTE C_, 6
	END

; Sound effect 9
Sfx09:
	LEN 4
	VOLENV 15, $11, $2F, $11
	WAVE Wave_74DF
	LEN 4
	NOTE Gsh, 5
	LEN 1
	REST
	LEN 4
	NOTE Gsh, 6
	LEN 4
	VOLENV 10, $11, $2F, $11
	LEN 4
	NOTE Gsh, 5
	LEN 1
	REST
	LEN 4
	NOTE Gsh, 6
	VOLENV 5, $11, $2F, $11
	LEN 4
	NOTE Gsh, 5
	LEN 1
	REST
	LEN 4
	NOTE Gsh, 6
	END

; Sound effect 32
Sfx32:
	VOLENV 15, $11, $1F, $11
	CALL_CODE Code_71E2
	WAVE Wave_747F
	LEN 12
	GLIDE $FE
	NOTE C_, 3
	END

; Unreferenced (39 bytes)
	db $C4, $11, $1F, $14, $7A, $7F, $74, $60, $04, $CB, $1F, $60, $FD, $CD, $65, $66
	db $68, $C2, $11, $10, $00, $7A, $8F, $75, $60, $02, $CC, $15, $61, $CA, $65, $60
	db $02, $65, $68, $80, $1B, $70, $68
Code_6F26:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $05
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $28
	ld [wDrumHold], a
	ld a, HIGH(Noise43_6F56)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6F56)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6F5C)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6F5C)
	ld [wNoise42], a
	ret
Noise43_6F56:
	db $57, $56, $54, $53, $65, $FF
Noise42_6F5C:
	db $F0, $F0, $60, $70, $F3
Code_6F61:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $0A
	ld [wDrumHold], a
	ld a, HIGH(Noise43_6F88)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6F88)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6F8C)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6F8C)
	ld [wNoise42], a
	ret
Noise43_6F88:
	db $4A, $5A, $50, $FF
Noise42_6F8C:
	db $F0, $D0, $B1
Code_6F8F:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $1E
	ld [wDrumHold], a
	ld a, $D2
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ld a, HIGH(Noise43_6FBE)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6FBE)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_6FBE:
	db $18, $3A, $47, $49, $2E, $2D, $1C, $28
	db $4A, $57, $39, $4E, $1D, $0C, $FF
Noise43_6FCD:
	db $82, $64, $02, $37, $47, $24, $55, $71
	db $07, $44, $60, $36, $84, $82, $64, $02
	db $37, $47, $24, $55, $71, $07, $44, $60
	db $36, $86, $32, $FF
Code_6FE9:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $13
	ld [wDrumHold], a
	call NoisePanCentre
	ld a, $F2
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ld a, HIGH(Noise43_6FCD)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6FCD)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret

; Unreferenced (104 bytes)
	db $AF, $EA, $58, $D2, $3C, $EA, $59, $D2, $3E, $88, $EA, $43, $D2, $3E, $13, $EA
	db $44, $D2, $CD, $9F, $4A, $3E, $F1, $E0, $21, $3E, $80, $E0, $23, $3E, $6F, $EA
	db $54, $D2, $3E, $CD, $EA, $55, $D2, $3E, $00, $EA, $56, $D2, $3E, $00, $EA, $57
	db $D2, $C9, $3E, $88, $EA, $43, $D2, $3E, $08, $EA, $44, $D2, $AF, $EA, $58, $D2
	db $3C, $EA, $59, $D2, $3E, $70, $EA, $54, $D2, $3E, $74, $EA, $55, $D2, $3E, $70
	db $EA, $56, $D2, $3E, $7C, $EA, $57, $D2, $C9, $60, $52, $42, $41, $22, $11, $21
	db $FF, $F0, $F0, $F0, $F0, $F0, $F0, $61
Code_7083:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7112)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7112)
	ld [wNoise43], a
	ld a, HIGH(Noise42_712C)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_712C)
	ld [wNoise42], a
	ret
Code_70AA:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_711F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_711F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_712C)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_712C)
	ld [wNoise42], a
	ret
Code_70D1:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7105)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7105)
	ld [wNoise43], a
	ld a, HIGH(Noise42_70F8)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_70F8)
	ld [wNoise42], a
	ret
Noise42_70F8:
	db $F1, $A1, $FF, $FF, $FF, $FF, $43, $FF
	db $FF, $FF, $FF, $FF

; Unreferenced (1 bytes)
	db $FF
Noise43_7105:
	db $51, $10, $20, $31, $32, $33, $53, $34
	db $14, $15, $15, $16, $FF
Noise43_7112:
	db $10, $10, $20, $31, $32, $33, $33, $34
	db $34, $35, $35, $36, $FF
Noise43_711F:
	db $36, $35, $35, $34, $34, $33, $33, $32
	db $31, $20, $10, $10, $FF
Noise42_712C:
	db $5F, $FF, $FF, $FF, $FF, $FF, $A1, $FF
	db $FF, $FF, $FF, $FF

; Unreferenced (1 bytes)
	db $FF
Code_7139:
	ld a, $88
	ld [wNoisePan], a
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7160)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7160)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7166)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7166)
	ld [wNoise42], a
	ret
Noise43_7160:
	db $00, $53, $71, $91, $31, $FF
Noise42_7166:
	db $F2, $FF, $FF, $FF, $00

; Unreferenced (62 bytes)
	db $3E, $88, $EA, $43, $D2, $3E, $0A, $EA, $44, $D2, $AF, $EA, $58, $D2, $3C, $EA
	db $59, $D2, $3E, $71, $EA, $54, $D2, $3E, $92, $EA, $55, $D2, $3E, $71, $EA, $56
	db $D2, $3E, $9E, $EA, $57, $D2, $C9, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0
	db $A0, $A0, $FF, $F0, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00
Code_71A9:
	ld a, $88
	ld [wNoisePan], a
	ld a, $19
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $F2
	ldh [rNR42], a
	ld a, $82
	ldh [rNR44], a
	ld a, HIGH(Noise43_71D8)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_71D8)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_71D8:
	db $02, $92, $42, $42, $42, $42, $52, $65
	db $45, $FF
Code_71E2:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7209)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7209)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7211)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7211)
	ld [wNoise42], a
	ret
Noise43_7209:
	db $02, $51, $61, $71, $91, $71, $60, $FF
Noise42_7211:
	db $F0, $F0, $F0, $F0, $F0, $70, $63
Code_7218:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_723F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_723F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7247)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7247)
	ld [wNoise42], a
	ret
Noise43_723F:
	db $22, $51, $64, $81, $51, $41, $60, $FF
Noise42_7247:
	db $F0, $F0, $F0, $F0, $F0, $70, $63
Code_724E:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0A
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7275)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7275)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7278)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7278)
	ld [wNoise42], a
	ret
Noise43_7275:
	db $22, $31, $FF
Noise42_7278:
	db $F1, $61
Code_727A:
	ld a, $88
	ld [wNoisePan], a
	ld a, $19
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_72A1)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_72A1)
	ld [wNoise43], a
	ld a, HIGH(Noise42_72A7)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_72A7)
	ld [wNoise42], a
	ret
Noise43_72A1:
	db $02, $41, $61, $71, $11, $FF
Noise42_72A7:
	db $F0, $FF, $FF, $A0, $B2

; Unreferenced (102 bytes)
	db $3E, $88, $EA, $43, $D2, $3E, $08, $EA, $44, $D2, $AF, $EA, $58, $D2, $3C, $EA
	db $59, $D2, $3E, $72, $EA, $54, $D2, $3E, $D3, $EA, $55, $D2, $3E, $72, $EA, $56
	db $D2, $3E, $D9, $EA, $57, $D2, $C9, $00, $83, $60, $60, $31, $FF, $F0, $FF, $FF
	db $FF, $D1, $3E, $88, $EA, $43, $D2, $3E, $04, $EA, $44, $D2, $AF, $EA, $58, $D2
	db $3C, $EA, $59, $D2, $3E, $73, $EA, $54, $D2, $3E, $05, $EA, $55, $D2, $3E, $73
	db $EA, $56, $D2, $3E, $0C, $EA, $57, $D2, $C9, $41, $61, $61, $41, $71, $71, $FF
	db $A1, $52, $00, $61, $52, $00
Code_7312:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0A
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7339)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7339)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7342)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7342)
	ld [wNoise42], a
	ret
Noise43_7339:
	db $78, $78, $78, $78, $58, $56, $56, $68
	db $FF
Noise42_7342:
	db $A1, $FF, $11, $00, $81, $FF, $F2, $00
Code_734A:
	ld a, $88
	ld [wNoisePan], a
	ld a, $3C
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $02
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_737A)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_737A)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7384)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7384)
	ld [wNoise42], a
	ret
Noise43_737A:
	db $67, $56, $45, $34, $23, $22, $11, $10
	db $20, $FF
Noise42_7384:
	db $19, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $F3
Code_738D:
	ld a, $88
	ld [wNoisePan], a
	ld a, $19
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_73B4)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_73B4)
	ld [wNoise43], a
	ld a, HIGH(Noise42_73BA)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_73BA)
	ld [wNoise42], a
	ret
Noise43_73B4:
	db $03, $83, $80, $80, $61, $FF
Noise42_73BA:
	db $F0, $FF, $FF, $FF, $F2

; Unreferenced (48 bytes)
	db $84, $32, $55, $55, $51, $23, $8F, $F8, $40, $04, $8F, $F8, $40, $04, $8F, $F8
	db $02, $46, $8A, $CE, $FF, $DB, $DF, $FF, $EC, $A8, $64, $20, $FF, $FF, $FF, $FF
	db $7F, $FF, $FF, $FF, $FF, $FF, $FF, $F7, $70, $00, $00, $00, $00, $00, $00, $07
Wave_73EF:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $00, $00, $00, $00

; Unreferenced (64 bytes)
	db $01, $11, $11, $00, $89, $AA, $AA, $98, $01, $11, $11, $00, $FF, $FF, $FF, $FF
	db $A8, $40, $04, $8A, $FF, $FF, $FF, $FF, $A8, $40, $04, $8A, $FF, $FF, $FF, $FF
	db $8C, $FE, $ED, $B8, $53, $21, $10, $24, $84, $01, $12, $35, $8B, $DE, $EF, $8C
	db $00, $46, $8A, $FF, $FF, $A8, $64, $00, $00, $46, $8A, $FF, $FF, $A8, $64, $00
Wave_743F:
	db $B7, $40, $F4, $7B, $FD, $FF, $FE, $DC
	db $02, $46, $8A, $BD, $FD, $BA, $6F, $20
Wave_744F:
	db $B7, $4E, $F4, $FF, $DF, $FF, $ED, $C0
	db $24, $68, $AB, $DF, $DD, $DD, $6F, $20

; Unreferenced (32 bytes)
	db $32, $22, $11, $11, $11, $22, $23, $45, $FD, $CB, $A9, $87, $65, $43, $21, $10
	db $DD, $DB, $97, $52, $22, $54, $22, $22, $DD, $DC, $BD, $DD, $DB, $85, $22, $22
Wave_747F:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF

; Unreferenced (32 bytes)
	db $01, $11, $11, $00, $89, $AA, $AA, $98, $01, $11, $11, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $CD, $EF, $FD, $EC, $00, $12, $21, $00, $DD, $DD, $DD, $DD
Wave_74AF:
	db $00, $00, $00, $00, $00, $00, $FF, $FF
	db $00, $00, $00, $00, $00, $00, $FF, $FF

; Unreferenced (16 bytes)
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $A8, $76, $67, $8A
Wave_74CF:
	db $00, $00, $00, $00, $00, $00, $FF, $00
	db $00, $00, $00, $00, $00, $00, $FF, $00
Wave_74DF:
	db $00, $00, $00, $CD, $EF, $FF, $FF, $FF
	db $04, $8C, $FF, $FF, $FF, $FF, $FF, $FF

; Unreferenced (16 bytes)
	db $48, $FF, $FF, $FF, $FF, $FF, $FF, $84, $00, $00, $00, $00, $00, $4F, $FF, $88
Wave_74FF:
	db $EC, $96, $31, $90, $00, $00, $00, $00
	db $24, $69, $CE, $FF, $FF, $FF, $FF, $FF

; Unreferenced (16 bytes)
	db $12, $34, $56, $78, $9A, $BC, $DE, $FF, $ED, $CB, $A9, $87, $65, $43, $21, $00
Wave_751F:
	db $FF, $FF, $ED, $B8, $53, $21, $00, $00
	db $00, $00, $12, $35, $8B, $DE, $FF, $FF
Wave_752F:
	db $63, $10, $40, $20, $00, $00, $01, $36
	db $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9

; Unreferenced (16 bytes)
	db $63, $10, $01, $47, $74, $10, $01, $36, $9C, $EF, $FE, $B8, $8B, $EF, $FE, $C9
Wave_754F:
	db $63, $1F, $01, $47, $74, $10, $01, $36
	db $9C, $E0, $FE, $B8, $8B, $EF, $FE, $C9

; Unreferenced (32 bytes)
	db $65, $43, $22, $27, $72, $22, $22, $29, $AB, $CC, $BA, $98, $9C, $EE, $EE, $C9
	db $63, $20, $02, $47, $74, $22, $22, $36, $9C, $EF, $FE, $B6, $6B, $EE, $EE, $C9
Wave_757F:
	db $B7, $40, $04, $7B, $CD, $FF, $FE, $DC
	db $02, $46, $8A, $BD, $FD, $BA, $64, $20
Wave_758F:
	db $0F, $00, $F0, $F0, $F0, $F0, $00, $0F
	db $0F, $FF, $FF, $00, $FF, $F0, $0F, $0F
Wave_759F:
	db $BB, $2B, $BB, $2B, $BB, $5B, $2B, $BB
	db $2B, $BB, $BB, $72, $27, $EB, $BB, $B0
Wave_75AF:
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $ED, $CB, $A9, $87, $65, $43, $21, $00

; Unreferenced (16 bytes)
	db $FE, $DB, $97, $53, $13, $54, $32, $10, $FE, $DC, $BC, $EF, $DB, $85, $32, $10
Wave_75CF:
	db $01, $23, $43, $21, $01, $23, $43, $21
	db $BA, $98, $76, $54, $43, $32, $21, $10
Wave_75DF:
	db $01, $23, $43, $21, $01, $23, $43, $21
	db $CD, $EF, $BA, $98, $76, $54, $32, $10
Wave_75EF:
	db $04, $8B, $DE, $FF, $ED, $CB, $A9, $87
	db $65, $44, $44, $32, $11, $24, $7A, $74

; Unreferenced (16 bytes)
	db $20, $13, $69, $BD, $FD, $B9, $64, $20, $13, $68, $B8, $64, $20, $24, $68, $64
Wave_760F:
	db $00, $00, $69, $FF, $FF, $F9, $64, $00
	db $03, $68, $B8, $60, $00, $04, $68, $60
Wave_761F:
	db $20, $24, $68, $AC, $EC, $A8, $64, $20
	db $24, $68, $A8, $64, $20, $24, $68, $64

; Unreferenced (32 bytes)
	db $02, $48, $AC, $FF, $FC, $53, $00, $27, $9C, $DD, $DC, $B7, $7B, $CD, $DD, $C9
	db $BD, $FF, $AC, $FF, $FC, $52, $00, $27, $9C, $DF, $DC, $B7, $7B, $CD, $AD, $C9
Noise43_764F:
	db $21, $24, $23, $22, $16, $FF
Noise42_7655:
	db $93, $FF, $FF, $FF, $45
Noise43_765A:
	db $21, $21, $FF
Noise42_765D:
	db $51, $21
Noise43_765F:
	db $21, $21, $FF
Noise42_7662:
	db $71, $21
Noise43_7664:
	db $21, $21, $FF
Noise42_7667:
	db $81, $FF

; Unreferenced (15 bytes)
	db $50, $41, $50, $51, $42, $53, $51, $FF, $90, $50, $90, $40, $C0, $50, $42
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_769E)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_769E)
	ld [wNoise43], a
	ld a, HIGH(Noise42_76A2)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_76A2)
	ld [wNoise42], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $01
	jp PlaySfx
Noise43_769E:
	db $21, $45, $05, $FF
Noise42_76A2:
	db $81, $F1, $21

; Unreferenced (11 bytes)
	db $04, $02, $01, $00, $00, $FF, $30, $40, $60, $43, $42
Drum2:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_76FC)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_76FC)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7700)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7700)
	ld [wNoise42], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $02
	jp PlaySfx
Drum3:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_783F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_783F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7842)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7842)
	ld [wNoise42], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $06
	jp PlaySfx
Noise43_76FC:
	db $20, $44, $33, $FF
Noise42_7700:
	db $80, $F0, $43
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7664)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7664)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7667)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7667)
	ld [wNoise42], a
	ret
Drum5:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_765F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_765F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7662)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7662)
	ld [wNoise42], a
	ret
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_765A)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_765A)
	ld [wNoise43], a
	ld a, HIGH(Noise42_765D)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_765D)
	ld [wNoise42], a
	ret
Drum7:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_764F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_764F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7655)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7655)
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
	ld a, HIGH(Noise43_7844)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7844)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7847)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7847)
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
	ld a, HIGH(Noise43_7844)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7844)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7847)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7847)
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
	ld a, HIGH(Noise43_7844)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7844)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7847)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7847)
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
	ld a, HIGH(Noise43_7849)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7849)
	ld [wNoise43], a
	ld a, HIGH(Noise42_784C)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_784C)
	ld [wNoise42], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $01
	jp PlaySfx

; Unreferenced (1 bytes)
	db $C9
Drum14:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7664)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7664)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7667)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7667)
	ld [wNoise42], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $01
	jp PlaySfx

; Unreferenced (1 bytes)
	db $C9
Noise43_783F:
	db $31, $24, $FF
Noise42_7842:
	db $80, $51
Noise43_7844:
	db $21, $12, $FF
Noise42_7847:
	db $A0, $62
Noise43_7849:
	db $20, $42, $FF
Noise42_784C:
	db $A0, $81

; Unreferenced (1 bytes)
	db $FF
FadeOutTable:
	db $77, $66, $55, $44, $33, $22, $11, $00
	db $80, FADE_END
FadeInTable:
	db $00, $11, $22, $33, $44, $55, $66, $77
	db FADE_END
DriverEndText:
	db "Final de la rutina de musica"

; Unreferenced (1922 bytes)
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00
