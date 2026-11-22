; =====================================================================
; Turok 3: Shadow of Oblivion (UE) (M4) [C] - Game Boy Color
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o turok3.o Turok3_SoundDriver.asm
;   rgblink -o turok3.gb turok3.o
;   python tools/cmp_banked.py turok3.gb "Turok 3 - Shadow of Oblivion (UE) (M4) [C][!].gbc" 63:4000-7FFF
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
	ld a, $6D
	ld [wInstrTableHi], a
	ld a, $96
	ld [wInstrTable], a
	pop af
	cp $0A
	ret nc
	ld [wCurSong], a
	add a, a
	add a, $84
	ld l, a
	adc a, $6D
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
	db $BD, $60, $BD, $60, $BC, $60, $BC, $60, $BB, $40, $BB, $40, $BA, $40, $BA, $40
	db $B9, $40, $B9, $40, $B8, $40, $B8, $40, $B7, $40, $B7, $40, $B6, $40, $B6, $40
	db $B5, $40, $B5, $40, $B4, $40, $B4, $40, $B3, $40, $B3, $40, $B2, $40, $B2, $40
	db $B1, $40, $B1, $40, $B0, $40, $B0, $60, $AF, $60, $AF, $60, $AE, $60, $AE, $60
	db $AD, $60, $AD, $60, $AC, $60, $AC, $60, $AB, $40, $AB, $40, $AA, $40, $AA, $40
	db $A9, $40, $A9, $40, $A8, $40, $A8, $40, $A7, $40, $A7, $40, $A6, $40, $A6, $40
	db $A5, $40, $A5, $40, $A4, $40, $A4, $40, $A3, $40, $A3, $40, $A2, $40, $A2, $40
	db $A1, $40, $A1, $40, $A0, $40, $A0, $60, $9F, $60, $9F, $60, $9E, $60, $9E, $60
	db $9D, $60, $9D, $60, $9C, $60, $9C, $60, $9B, $40, $9B, $40, $9A, $40, $9A, $40
	db $99, $40, $99, $40, $98, $40, $98, $40, $97, $40, $97, $40, $96, $40, $96, $40
	db $95, $40, $95, $40, $94, $40, $94, $40, $93, $40, $93, $40, $92, $40, $92, $40
	db $91, $40, $91, $40, $90, $40, $90, $60, $8F, $60, $8F, $60, $8E, $60, $8E, $60
	db $8D, $60, $8D, $60, $8C, $60, $8C, $60, $8B, $40, $8B, $40, $8A, $40, $8A, $40
	db $89, $40, $89, $40, $88, $40, $88, $40, $87, $40, $87, $40, $86, $40, $86, $40
	db $85, $40, $85, $40, $84, $40, $84, $40, $83
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
	add a, $87
	ld l, a
	adc a, $71
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
	dw Drum11
	dw Drum12
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
	db "(Music & Sound Driver by Alberto Jose Gonzalez, 2000)"

; Song 2: instrument table 7, arpeggio table 1 (the one SndInit sets)
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
	dw Pat_4DCB
	dw Pat_4CF3
	dw Pat_4D3A
	dw Pat_4CF7
	dw Pat_4D7D
	dw Pat_4DC0
	ORDER_LOOP Song2_Ch3
Song2_Ch2:
	dw Pat_4EBD
	dw Pat_4DF1
	dw Pat_4E1A
	dw Pat_4E41
	dw Pat_4E60
	dw Pat_4E82
	ORDER_LOOP Song2_Ch2
Song2_Ch1:
	dw Pat_4FD7
	dw Pat_4EF2
	dw Pat_4F19
	dw Pat_4F3F
	dw Pat_4F6E
	dw Pat_4F9B
	ORDER_LOOP Song2_Ch1
Pat_4CF3:
	DRUMS $08, DrumPat_5026
Pat_4CF7:
	INSTR 12
	LEN 16
	NOTE F_, 2
	NOTE F_, 2
	INSTR 19
	NOTE F_, 4
	INSTR 12
	NOTE F_, 2
	LEN 8
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	INSTR 19
	LEN 16
	NOTE F_, 4
	INSTR 12
	NOTE F_, 2
	NOTE Ash, 2
	NOTE Ash, 2
	INSTR 19
	NOTE Ash, 4
	INSTR 12
	NOTE Ash, 2
	LEN 8
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 2
	INSTR 19
	LEN 16
	NOTE Ash, 4
	INSTR 12
	NOTE Ash, 2
	NOTE C_, 3
	NOTE C_, 3
	INSTR 19
	NOTE C_, 5
	INSTR 12
	NOTE C_, 3
	LEN 8
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	INSTR 19
	LEN 16
	NOTE C_, 5
	INSTR 12
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 2
	INSTR 19
	NOTE F_, 4
	INSTR 12
	NOTE F_, 2
	LEN 8
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	INSTR 19
	LEN 16
	NOTE F_, 4
	INSTR 12
	NOTE C_, 2
	NEXT
Pat_4D3A:
	INSTR 12
	LEN 16
	NOTE F_, 2
	NOTE F_, 2
	INSTR 19
	NOTE F_, 4
	INSTR 12
	NOTE F_, 2
	LEN 8
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	INSTR 19
	LEN 16
	NOTE F_, 4
	INSTR 12
	NOTE F_, 2
	NOTE Ash, 2
	NOTE Ash, 2
	INSTR 19
	NOTE Ash, 4
	INSTR 12
	NOTE Ash, 2
	LEN 8
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 2
	INSTR 19
	LEN 16
	NOTE Ash, 4
	INSTR 12
	NOTE Ash, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	INSTR 19
	NOTE Gsh, 4
	INSTR 12
	NOTE Gsh, 2
	LEN 8
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	INSTR 19
	LEN 16
	NOTE Gsh, 4
	INSTR 12
	NOTE Gsh, 2
	NOTE C_, 2
	NOTE C_, 2
	INSTR 19
	NOTE C_, 5
	INSTR 12
	NOTE C_, 2
	LEN 8
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	INSTR 19
	LEN 16
	NOTE C_, 5
	INSTR 12
	NOTE C_, 2
	NEXT
Pat_4D7D:
	INSTR 12
	LEN 16
	NOTE A_, 2
	NOTE A_, 2
	INSTR 19
	NOTE F_, 4
	INSTR 12
	NOTE A_, 2
	LEN 8
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	INSTR 19
	LEN 16
	NOTE F_, 4
	INSTR 12
	NOTE C_, 3
	NOTE Ash, 2
	NOTE Ash, 2
	INSTR 19
	NOTE Ash, 4
	INSTR 12
	NOTE Ash, 2
	LEN 8
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 2
	INSTR 19
	LEN 16
	NOTE Ash, 4
	INSTR 12
	NOTE Ash, 2
	NOTE C_, 3
	NOTE C_, 3
	INSTR 19
	NOTE Gsh, 4
	INSTR 12
	NOTE C_, 3
	LEN 8
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	INSTR 19
	LEN 16
	NOTE Gsh, 4
	INSTR 12
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	INSTR 19
	NOTE C_, 5
	INSTR 12
	NOTE C_, 2
	LEN 8
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	INSTR 19
	LEN 16
	NOTE C_, 5
	INSTR 12
	NOTE C_, 2
	NEXT
Pat_4DC0:
	INSTR 12
	LEN 16
	REPEAT 8
	NOTE F_, 2
	NOTE F_, 2
	INSTR 19
	NOTE F_, 4
	INSTR 12
	NOTE F_, 2
	REPEAT_END
	NEXT
Pat_4DCB:
	INSTR 12
	LEN 16
	NOTE F_, 2
	NOTE C_, 3
	NOTE F_, 3
	NOTE C_, 3
	NOTE F_, 2
	NOTE C_, 3
	NOTE F_, 3
	NOTE C_, 3
	NOTE F_, 2
	NOTE C_, 3
	NOTE F_, 3
	NOTE Gsh, 2
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE F_, 2
	NOTE C_, 3
	NOTE F_, 3
	NOTE C_, 3
	NOTE F_, 2
	NOTE C_, 3
	NOTE F_, 3
	NOTE C_, 3
	NOTE F_, 2
	NOTE C_, 3
	NOTE F_, 3
	NOTE Gsh, 2
	LEN 8
	NOTE C_, 3
	NOTE Csh, 3
	LEN 16
	NOTE C_, 3
	NOTE Ash, 2
	NOTE C_, 3
	NEXT
Pat_4DF1:
	RELEASE $00
	HWENV $59, $05, $80
	DUTY_75
	RELEASE $98, $63
	LEN 32
	NOTE F_, 3
	LEN 16
	NOTE C_, 4
	NOTE Ash, 3
	LEN 32
	NOTE C_, 4
	NOTE Csh, 4
	LENGTH $30
	NOTE Ash, 3
	LEN 16
	NOTE G_, 3
	LENGTH $50
	NOTE E_, 3
	LEN 16
	NOTE C_, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	LEN 32
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE G_, 3
	LENGTH $30
	NOTE F_, 3
	LEN 16
	NOTE C_, 3
	NEXT
Pat_4E1A:
	LEN 32
	NOTE F_, 3
	LEN 16
	NOTE C_, 4
	NOTE Ash, 3
	LEN 32
	NOTE C_, 4
	NOTE F_, 3
	LENGTH $30
	NOTE Dsh, 4
	LEN 16
	NOTE Csh, 4
	NOTE Ash, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	LENGTH $50
	NOTE C_, 4
	LEN 32
	NOTE Ash, 3
	LEN 16
	NOTE Gsh, 3
	LEN 8
	NOTE G_, 3
	NOTE Gsh, 3
	LENGTH $50
	NOTE G_, 3
	HWENV $D1, $08, $60
	ARP 1
	DUTY_50
	LEN 32
	NOTE C_, 3
	NEXT
Pat_4E41:
	LEN 32
	NOTE F_, 3
	LEN 16
	NOTE C_, 4
	NOTE Ash, 3
	LEN 32
	NOTE C_, 4
	NOTE Csh, 4
	LENGTH $30
	NOTE Ash, 3
	LEN 16
	NOTE G_, 3
	LENGTH $50
	NOTE E_, 3
	LEN 16
	NOTE C_, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	LEN 32
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE G_, 3
	LENGTH $30
	NOTE F_, 3
	LEN 16
	NOTE C_, 3
	NEXT
Pat_4E60:
	LEN 32
	NOTE F_, 3
	LEN 16
	NOTE C_, 4
	NOTE Ash, 3
	LEN 32
	NOTE C_, 4
	NOTE F_, 3
	LENGTH $30
	NOTE Dsh, 4
	LEN 16
	NOTE Csh, 4
	NOTE Ash, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	LENGTH $50
	NOTE C_, 4
	LEN 32
	NOTE Ash, 3
	LEN 16
	NOTE Gsh, 3
	LEN 8
	NOTE G_, 3
	NOTE Gsh, 3
	LENGTH $30
	NOTE G_, 3
	LEN 32
	NOTE F_, 3
	NOTE E_, 3
	NEXT
Pat_4E82:
	LENGTH $80
	NOTE F_, 3
	WAIT
	RELEASE $00
	INSTR 15
	LEN 8
	NOTE C_, 4
	NOTE F_, 4
	INSTR 9
	NOTE C_, 5
	INSTR 15
	NOTE F_, 4
	INSTR 9
	NOTE Gsh, 5
	INSTR 15
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	INSTR 9
	NOTE C_, 5
	INSTR 15
	NOTE F_, 4
	INSTR 9
	NOTE G_, 5
	INSTR 15
	NOTE F_, 4
	INSTR 9
	NOTE C_, 5
	INSTR 15
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	INSTR 9
	NOTE F_, 5
	INSTR 15
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	INSTR 9
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	INSTR 15
	NOTE F_, 4
	INSTR 9
	NOTE D_, 5
	INSTR 15
	NOTE F_, 4
	INSTR 9
	NOTE E_, 5
	INSTR 15
	NOTE F_, 4
	NEXT
Pat_4EBD:
	HWENV $00, $00
	LEN 32
	REST
	HWENV $69, $04, $80
	RELEASE $01, $37
	DUTY_75
	ARP_OFF
	VIBRATO $18, $02, $04
	NOTE C_, 5
	WAIT2
	NOTE Ash, 4
	WAIT2
	LEN 16
	NOTE Gsh, 4
	WAIT2
	LEN 8
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	NOTE G_, 4
	LEN 40
	WAIT2
	LEN 32
	NOTE C_, 4
	WAIT2
	NOTE Ash, 3
	WAIT2
	LEN 16
	NOTE Gsh, 3
	WAIT2
	LEN 8
	NOTE C_, 4
	NOTE Csh, 4
	NOTE C_, 4
	WAIT2
	NOTE Ash, 3
	WAIT2
	NOTE C_, 4
	WAIT2
	NEXT
Pat_4EF2:
	LEN 16
	WAIT
	HWENV $20, $00
	DUTY_50
	VIBRATO $00, $01, $05
	LEN 32
	NOTE F_, 3
	LEN 16
	NOTE C_, 4
	NOTE Ash, 3
	LEN 32
	NOTE C_, 4
	NOTE Csh, 4
	LENGTH $30
	NOTE Ash, 3
	LEN 16
	NOTE G_, 3
	LENGTH $50
	NOTE E_, 3
	LEN 16
	NOTE C_, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	LEN 32
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE G_, 3
	LENGTH $30
	NOTE F_, 3
	NEXT
Pat_4F19:
	LEN 16
	NOTE C_, 3
	LEN 32
	NOTE F_, 3
	LEN 16
	NOTE C_, 4
	NOTE Ash, 3
	LEN 32
	NOTE C_, 4
	NOTE F_, 3
	LENGTH $30
	NOTE Dsh, 4
	LEN 16
	NOTE Csh, 4
	NOTE Ash, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	LENGTH $50
	NOTE C_, 4
	LEN 32
	NOTE Ash, 3
	LEN 16
	NOTE G_, 3
	LEN 8
	NOTE G_, 3
	NOTE Gsh, 3
	LEN 32
	NOTE G_, 3
	INSTR 9
	LEN 16
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE G_, 4
	NEXT
Pat_4F3F:
	LEN 16
	WAIT
	HWENV $C1, $08, $60
	DUTY_50
	ARP_OFF
	RELEASE $98, $63
	VIBRATO $10, $02, $04
	NOTE C_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 32
	NOTE Gsh, 4
	NOTE Ash, 4
	LENGTH $30
	NOTE G_, 4
	LEN 16
	NOTE F_, 4
	NOTE Csh, 4
	NOTE G_, 3
	LEN 8
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Csh, 4
	LEN 16
	NOTE C_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE F_, 4
	LEN 32
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE E_, 4
	LENGTH $40
	NOTE C_, 4
	NEXT
Pat_4F6E:
	LEN 32
	NOTE C_, 4
	LEN 16
	NOTE A_, 4
	NOTE G_, 4
	LEN 32
	NOTE A_, 4
	NOTE C_, 5
	LENGTH $30
	NOTE C_, 5
	LEN 8
	NOTE Ash, 4
	NOTE C_, 5
	LEN 16
	NOTE Ash, 4
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE F_, 4
	LENGTH $30
	NOTE F_, 4
	LEN 16
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 32
	NOTE F_, 4
	LEN 8
	NOTE E_, 4
	NOTE F_, 4
	LEN 32
	NOTE E_, 4
	RELEASE $00
	INSTR 9
	LEN 8
	NOTE C_, 5
	NOTE Csh, 5
	LEN 16
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NEXT
Pat_4F9B:
	INSTR 2
	LEN 16
	NOTE G_, 3
	INSTR 9
	NOTE C_, 4
	NOTE Gsh, 4
	INSTR 2
	NOTE G_, 3
	NOTE G_, 3
	INSTR 9
	NOTE C_, 4
	NOTE G_, 4
	NOTE C_, 4
	INSTR 2
	NOTE G_, 3
	NOTE G_, 3
	INSTR 9
	LEN 8
	NOTE F_, 4
	INSTR 2
	LEN 24
	NOTE G_, 3
	LEN 8
	NOTE G_, 3
	INSTR 9
	NOTE F_, 4
	LEN 16
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	INSTR 2
	NOTE G_, 3
	INSTR 9
	NOTE C_, 4
	NOTE Gsh, 4
	INSTR 2
	NOTE G_, 3
	NOTE G_, 3
	INSTR 9
	NOTE C_, 4
	NOTE G_, 4
	NOTE C_, 4
	INSTR 2
	NOTE G_, 3
	NOTE G_, 3
	INSTR 9
	LEN 8
	NOTE F_, 4
	INSTR 2
	LEN 24
	NOTE G_, 3
	LEN 8
	NOTE G_, 3
	INSTR 9
	NOTE F_, 4
	LEN 16
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	NEXT
Pat_4FD7:
	HWENV $69, $04, $80
	RELEASE $01, $37
	DUTY_75
	ARP_OFF
	VIBRATO $18, $02, $04
	LEN 8
	NOTE F_, 3
	WAIT2
	NOTE C_, 4
	WAIT2
	LEN 32
	NOTE Gsh, 4
	LEN 8
	NOTE F_, 3
	WAIT2
	NOTE C_, 4
	WAIT2
	LEN 32
	NOTE G_, 4
	LEN 8
	NOTE F_, 3
	WAIT2
	NOTE C_, 4
	WAIT2
	LEN 16
	NOTE F_, 4
	LEN 8
	NOTE Gsh, 3
	WAIT2
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	WAIT2
	NOTE D_, 4
	WAIT2
	NOTE E_, 4
	WAIT2
	NOTE F_, 3
	WAIT2
	NOTE C_, 4
	WAIT2
	LEN 32
	NOTE Gsh, 4
	LEN 8
	NOTE F_, 3
	WAIT2
	NOTE C_, 4
	WAIT2
	LEN 32
	NOTE G_, 4
	LEN 8
	NOTE F_, 3
	WAIT2
	NOTE C_, 4
	WAIT2
	LEN 16
	NOTE F_, 4
	LEN 8
	NOTE Gsh, 3
	WAIT2
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE G_, 3
	WAIT2
	NOTE F_, 3
	WAIT2
	NOTE G_, 3
	WAIT2
	RELEASE $00
	NEXT
DrumPat_5026:
	db 7, 0, 0, 0, 2, 0, 1, 0
	db 1, 6, 5, 6, 2, 0, 6, 0
	db 1, 0, 1, 0, 2, 1, 6, 0
	db 1, 6, 5, 6, 2, 0, 4, 0
	db DRUM_REPEAT + 2, 1, 0, 6, 0, 2, 0, 1
	db 0, 1, 6, 5, 6, 2, 0, 6
	db 0, 1, 0, 1, 0, 2, 1, 6
	db 0, 1, 6, 5, 6, 2, 0, 4
	db 0, DRUM_REPEAT_END, 1, 0, 6, 0, 2, 0
	db 1, 0, 1, 6, 5, 6, 2, 0
	db 6, 0, 1, 0, 1, 0, 2, 1
	db 6, 0, 1, 1, 1, 4, 2, 0
	db 2, 0, DRUM_LOOP

; Song 3: instrument table 7, arpeggio table 1 (the one SndInit sets)
PlaySong3:
	call StopAll
	ld de, Song3_Ch3
	call StartMusicCh3
	ld de, Song3_Ch2
	call StartMusicCh2
	ld de, Song3_Ch1
	jp StartMusicCh1
Song3_Ch3:
	dw Pat_5191
	dw Pat_50E2
	dw Pat_50E2
	dw Pat_5105
	dw Pat_5133
	dw Pat_5191
	dw Pat_5105
	dw Pat_5160
	ORDER_LOOP Song3_Ch3
Song3_Ch2:
	dw Pat_5241
	dw Pat_51AC
	dw Pat_51AC
	dw Pat_51D8
	dw Pat_520A
	dw Pat_5241
	dw Pat_5394
	ORDER_LOOP Song3_Ch2
Song3_Ch1:
	dw Pat_5310
	dw Pat_528B
	dw Pat_528B
	dw Pat_52B0
	dw Pat_52E2
	dw Pat_5324
	dw Pat_52B0
	dw Pat_5360
	ORDER_LOOP Song3_Ch1
Pat_50D8:
	REPEAT 2
	LEN 16
	NOTE Gsh, 2
	LEN 8
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE G_, 2
	NOTE Gsh, 2
	REPEAT_END
	NEXT
Pat_50E2:
	PAT_CALL Pat_50D8
	LEN 16
	NOTE Dsh, 2
	LEN 8
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE D_, 2
	NOTE Dsh, 2
	LEN 16
	NOTE Dsh, 2
	LEN 8
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE D_, 2
	NOTE Dsh, 2
	PAT_CALL Pat_50D8
	LEN 16
	NOTE B_, 2
	LEN 8
	NOTE B_, 2
	NOTE B_, 3
	NOTE Ash, 2
	NOTE B_, 2
	LEN 16
	NOTE B_, 2
	LEN 8
	NOTE B_, 2
	NOTE B_, 3
	NOTE Ash, 2
	NOTE B_, 2
	NEXT
Pat_5105:
	LEN 16
	NOTE Csh, 3
	LEN 8
	NOTE Csh, 3
	NOTE Csh, 4
	NOTE C_, 3
	NOTE Csh, 3
	LEN 16
	NOTE Csh, 3
	LEN 8
	NOTE Csh, 3
	NOTE Csh, 4
	NOTE C_, 3
	NOTE Csh, 3
	PAT_CALL Pat_50D8
	LEN 16
	NOTE B_, 2
	LEN 8
	NOTE B_, 2
	NOTE B_, 3
	NOTE Ash, 2
	NOTE B_, 2
	LEN 16
	NOTE B_, 2
	LEN 8
	NOTE B_, 2
	NOTE B_, 3
	NOTE Ash, 2
	NOTE B_, 2
	LEN 16
	NOTE Fsh, 2
	LEN 8
	NOTE Fsh, 2
	NOTE Fsh, 3
	NOTE F_, 2
	NOTE Fsh, 2
	LEN 16
	NOTE Fsh, 2
	LEN 8
	NOTE Fsh, 2
	NOTE Fsh, 3
	NOTE F_, 2
	NOTE Fsh, 2
	NEXT
Pat_5133:
	LEN 16
	NOTE Csh, 3
	LEN 8
	NOTE Csh, 3
	NOTE Csh, 4
	NOTE C_, 3
	NOTE Csh, 3
	LEN 16
	NOTE Csh, 3
	LEN 8
	NOTE Csh, 3
	NOTE Csh, 4
	NOTE C_, 3
	NOTE Csh, 3
	PAT_CALL Pat_50D8
	LEN 16
	NOTE B_, 2
	LEN 8
	NOTE B_, 2
	NOTE B_, 3
	NOTE Ash, 2
	NOTE B_, 2
	LEN 16
	NOTE B_, 2
	LEN 8
	NOTE B_, 2
	NOTE B_, 3
	NOTE Ash, 2
	NOTE B_, 2
	NOTE Dsh, 2
	NOTE Dsh, 3
	LEN 16
	NOTE Dsh, 2
	LEN 8
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 3
	NOTE Dsh, 3
	NOTE Dsh, 3
	NOTE Dsh, 3
	NEXT
Pat_5160:
	LEN 16
	NOTE Csh, 3
	LEN 8
	NOTE Csh, 3
	NOTE Csh, 4
	NOTE C_, 3
	NOTE Csh, 3
	LEN 16
	NOTE Csh, 3
	LEN 8
	NOTE Csh, 3
	NOTE Csh, 4
	NOTE C_, 3
	NOTE Csh, 3
	PAT_CALL Pat_50D8
	LEN 16
	NOTE B_, 2
	LEN 8
	NOTE B_, 2
	NOTE B_, 3
	NOTE Ash, 2
	NOTE B_, 2
	LEN 16
	NOTE B_, 2
	LEN 8
	NOTE B_, 2
	NOTE B_, 3
	NOTE Ash, 2
	NOTE B_, 2
	CH_TRANSPOSE $03
	NOTE Dsh, 2
	NOTE Dsh, 3
	LEN 16
	NOTE Dsh, 2
	LEN 8
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 3
	NOTE Dsh, 3
	NOTE Dsh, 3
	NOTE Dsh, 3
	CH_TRANSPOSE $00
	NEXT
Pat_5191:
	DRUMS $08, DrumPat_53F5
	TRANSPOSE $03
	VOLENV 15, $11, $15, $11
	ARP 2
	WAVE_SEQ WaveSeq_6F67
	PAT_CALL Pat_50D8
	PAT_CALL Pat_50D8
	PAT_CALL Pat_50D8
	PAT_CALL Pat_50D8
	NEXT
Pat_51AC:
	LENGTH $30
	NOTE Gsh, 3
	LEN 8
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE Ash, 3
	LEN 16
	NOTE B_, 3
	LEN 8
	NOTE Gsh, 3
	LENGTH $30
	NOTE Dsh, 3
	LEN 8
	NOTE Dsh, 3
	NOTE Fsh, 3
	NOTE F_, 3
	LEN 16
	NOTE Fsh, 3
	LEN 8
	NOTE Dsh, 3
	LENGTH $30
	NOTE Gsh, 3
	LEN 8
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE Ash, 3
	LEN 16
	NOTE B_, 3
	LEN 8
	NOTE Gsh, 3
	LENGTH $30
	NOTE B_, 3
	LEN 8
	NOTE B_, 3
	NOTE D_, 4
	NOTE Csh, 4
	NOTE D_, 4
	NOTE Fsh, 3
	NOTE G_, 3
	NEXT
Pat_51D8:
	LEN 8
	NOTE Csh, 3
	NOTE E_, 4
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE E_, 4
	NOTE Csh, 3
	NOTE E_, 4
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE E_, 4
	NOTE Gsh, 2
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE Gsh, 2
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE B_, 2
	NOTE D_, 4
	NOTE B_, 3
	NOTE Csh, 4
	NOTE B_, 3
	NOTE D_, 4
	NOTE B_, 2
	NOTE D_, 4
	NOTE B_, 3
	NOTE Csh, 4
	NOTE B_, 3
	NOTE D_, 4
	NOTE Fsh, 2
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE Gsh, 3
	NOTE Fsh, 3
	NOTE Csh, 4
	NOTE Fsh, 2
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE Gsh, 3
	NOTE Fsh, 3
	NOTE Csh, 4
	NEXT
Pat_520A:
	LEN 8
	WAIT
	NOTE Gsh, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	LEN 16
	NOTE Gsh, 4
	LEN 8
	NOTE Gsh, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	LEN 16
	NOTE Gsh, 4
	LEN 8
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Csh, 4
	NOTE B_, 3
	LEN 16
	NOTE Dsh, 4
	LEN 8
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Csh, 4
	NOTE B_, 3
	LEN 16
	NOTE Dsh, 4
	LEN 8
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 16
	NOTE Fsh, 4
	LEN 8
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE F_, 3
	NOTE F_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE Gsh, 3
	NOTE G_, 4
	NOTE Ash, 3
	NOTE Gsh, 4
	NOTE B_, 3
	NOTE Ash, 4
	NEXT
Pat_5241:
	ARP 2
	HWENV $A2, $10, $20
	DUTY_50
	VIBRATO $10, $02, $04
	DUTY_12
	AUTODUTY $08
	LEN 16
	NOTE Gsh, 3
	LEN 8
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE Gsh, 3
	LEN 16
	NOTE Gsh, 3
	LEN 8
	NOTE Gsh, 3
	LEN 16
	NOTE Gsh, 3
	LEN 8
	NOTE Gsh, 3
	LEN 16
	NOTE Dsh, 4
	LEN 8
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	LEN 16
	NOTE Dsh, 4
	LEN 8
	NOTE Dsh, 4
	LEN 16
	NOTE Dsh, 4
	LEN 8
	NOTE Dsh, 4
	LEN 16
	NOTE Gsh, 4
	LEN 8
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 16
	NOTE Gsh, 4
	LEN 8
	NOTE Gsh, 4
	LEN 16
	NOTE Gsh, 4
	LEN 8
	NOTE Gsh, 4
	LEN 16
	NOTE B_, 4
	LEN 8
	NOTE B_, 4
	NOTE B_, 4
	NOTE Ash, 4
	NOTE B_, 4
	LEN 16
	NOTE Dsh, 5
	LEN 8
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE Dsh, 5
	DUTY_75
	NEXT
Pat_528B:
	LEN 8
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE Ash, 4
	LEN 16
	NOTE B_, 4
	LENGTH $38
	NOTE Gsh, 4
	LEN 8
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE F_, 4
	LEN 16
	NOTE Fsh, 4
	LENGTH $38
	NOTE Dsh, 4
	LEN 8
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE Ash, 4
	LEN 16
	NOTE B_, 4
	LENGTH $38
	NOTE Gsh, 4
	LEN 8
	NOTE B_, 4
	NOTE D_, 5
	NOTE Csh, 5
	LEN 16
	NOTE D_, 5
	LENGTH $38
	NOTE B_, 4
	NEXT
Pat_52B0:
	LEN 8
	NOTE Csh, 4
	NOTE E_, 5
	NOTE Csh, 5
	NOTE Dsh, 5
	NOTE Csh, 5
	NOTE E_, 5
	NOTE Csh, 4
	NOTE E_, 5
	NOTE Csh, 5
	NOTE Dsh, 5
	NOTE Csh, 5
	NOTE E_, 5
	NOTE Gsh, 3
	NOTE B_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE Gsh, 3
	NOTE B_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE B_, 3
	NOTE D_, 5
	NOTE B_, 4
	NOTE Csh, 5
	NOTE B_, 4
	NOTE D_, 5
	NOTE B_, 3
	NOTE D_, 5
	NOTE B_, 4
	NOTE Csh, 5
	NOTE B_, 4
	NOTE D_, 5
	NOTE Fsh, 3
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE Csh, 5
	NOTE Fsh, 3
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE Csh, 5
	NEXT
Pat_52E2:
	DUTY_75
	LEN 8
	NOTE Csh, 4
	NOTE E_, 5
	NOTE Csh, 5
	NOTE Dsh, 5
	NOTE Csh, 5
	NOTE E_, 5
	NOTE Csh, 4
	NOTE E_, 5
	NOTE Csh, 5
	NOTE Dsh, 5
	NOTE Csh, 5
	NOTE E_, 5
	NOTE Gsh, 3
	NOTE B_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE Gsh, 3
	NOTE B_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE B_, 3
	NOTE D_, 5
	NOTE B_, 4
	NOTE Csh, 5
	NOTE B_, 4
	NOTE D_, 5
	NOTE B_, 3
	NOTE D_, 5
	NOTE B_, 4
	NOTE Csh, 5
	NOTE B_, 4
	NOTE D_, 5
	LEN 16
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE B_, 4
	NOTE Csh, 5
	NOTE Dsh, 5
	NEXT
Pat_5310:
	HWENV $00, $00
	LENGTH $60
	REST
	ARP 2
	HWENV $A2, $10, $20
	DUTY_50
	VIBRATO $10, $02, $04
	DUTY_12
	PAT_GOTO Pat_5332
Pat_5324:
	ARP 2
	HWENV $A2, $10, $20
	DUTY_50
	VIBRATO $10, $02, $04
	DUTY_12
	LENGTH $60
	WAIT
Pat_5332:
	LEN 16
	NOTE Gsh, 3
	LEN 8
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	LEN 16
	NOTE Gsh, 3
	LEN 8
	NOTE Gsh, 3
	LEN 16
	NOTE Gsh, 3
	LEN 8
	NOTE Gsh, 3
	LEN 16
	NOTE B_, 3
	LEN 8
	NOTE B_, 3
	NOTE B_, 3
	NOTE B_, 3
	NOTE B_, 3
	LEN 16
	NOTE B_, 3
	LEN 8
	NOTE B_, 3
	LEN 16
	NOTE B_, 3
	LEN 8
	NOTE B_, 3
	LEN 16
	NOTE Dsh, 4
	LEN 8
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 16
	NOTE Gsh, 4
	LEN 8
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	DUTY_50
	NEXT
Pat_5360:
	LEN 8
	NOTE Csh, 4
	NOTE E_, 5
	NOTE Csh, 5
	NOTE Dsh, 5
	NOTE Csh, 5
	NOTE E_, 5
	NOTE Csh, 4
	NOTE E_, 5
	NOTE Csh, 5
	NOTE Dsh, 5
	NOTE Csh, 5
	NOTE E_, 5
	NOTE Gsh, 3
	NOTE B_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE Gsh, 3
	NOTE B_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE B_, 3
	NOTE D_, 5
	NOTE B_, 4
	NOTE Csh, 5
	NOTE B_, 4
	NOTE D_, 5
	NOTE B_, 3
	NOTE D_, 5
	NOTE B_, 4
	NOTE Csh, 5
	NOTE B_, 4
	NOTE D_, 5
	LEN 16
	NOTE B_, 4
	LEN 8
	NOTE B_, 4
	NOTE B_, 4
	NOTE B_, 4
	NOTE B_, 4
	LEN 16
	NOTE Ash, 4
	LEN 8
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NEXT
Pat_5394:
	HWENV $C0, $00
	RELEASE $98, $47
	GLISS_2
	ARP_OFF
	LEN 24
	NOTE Gsh, 4
	LEN 40
	NOTE E_, 4
	LEN 16
	NOTE Fsh, 4
	NOTE E_, 4
	LENGTH $38
	NOTE Dsh, 4
	LEN 8
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE B_, 3
	NOTE Csh, 4
	NOTE Dsh, 4
	LEN 16
	NOTE Fsh, 4
	LEN 8
	NOTE Gsh, 4
	LEN 24
	NOTE Fsh, 4
	LEN 16
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE D_, 4
	LENGTH $30
	NOTE Csh, 4
	LEN 8
	NOTE Fsh, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE Csh, 4
	LEN 24
	NOTE Gsh, 4
	LEN 40
	NOTE E_, 4
	LEN 16
	NOTE Fsh, 4
	NOTE E_, 4
	LEN 8
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Fsh, 4
	LEN 32
	NOTE Gsh, 4
	LEN 8
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE B_, 4
	NOTE Csh, 5
	NOTE Dsh, 5
	LEN 16
	NOTE Fsh, 5
	NOTE Fsh, 5
	LEN 8
	NOTE Gsh, 5
	NOTE A_, 5
	LEN 16
	NOTE Gsh, 5
	NOTE Fsh, 5
	NOTE E_, 5
	LENGTH $30
	NOTE Fsh, 5
	ARP 2
	HWENV $A2, $10, $20
	DUTY_50
	VIBRATO $10, $02, $04
	RELEASE $00
	GLISS_OFF
	LEN 16
	NOTE Csh, 4
	LEN 8
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NEXT
DrumPat_53F5:
	db 7, 0, 5, 2, 0, 5, 1, 6
	db 5, 2, 0, 2, 1, 6, 5, 2
	db 0, 5, 1, 6, 5, 2, 0, 2
	db 1, 6, 5, 2, 0, 5, 1, 6
	db 5, 2, 0, 2, 1, 6, 5, 2
	db 0, 5, 1, 2, 1, 2, 2, 2
	db DRUM_LOOP

; Song 4: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong4:
	call StopAll
	ld a, $56
	ld [wInstrTableHi], a
	ld a, $F8
	ld [wInstrTable], a
	ld de, Song4_Ch3
	call StartMusicCh3
	ld de, Song4_Ch2
	call StartMusicCh2
	ld de, Song4_Ch1
	jp StartMusicCh1
Pat_5445:
	TRANSPOSE $00
	NEXT
Pat_5448:
	TRANSPOSE $02
	NEXT
Song4_Ch3:
	dw Pat_5445
	dw Pat_54AD
	dw Pat_54B9
	dw Pat_54BF
	dw Pat_54E2
	dw Pat_54E8
	dw Pat_54F7
	dw Pat_54F7
	dw Pat_5448
	dw Pat_54AD
	dw Pat_54B9
	dw Pat_54BF
	dw Pat_54E2
	dw Pat_54E8
	dw Pat_54F7
	dw Pat_54F7
	ORDER_LOOP Song4_Ch3
Song4_Ch2:
	dw Pat_5521
	dw Pat_552D
	dw Pat_5533
	dw Pat_557D
	dw Pat_55AF
	dw Pat_55D4
	dw Pat_55D4
	ORDER_LOOP Song4_Ch2
Song4_Ch1:
	dw Pat_55DB
	dw Pat_55E9
	dw Pat_561B
	dw Pat_564D
	dw Pat_568B
	dw Pat_56AB
	dw Pat_56AB
	ORDER_LOOP Song4_Ch1
Pat_5493:
	INSTR 6
	LEN 8
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	INSTR 5
	LEN 16
	NOTE F_, 3
	INSTR 6
	LEN 8
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	INSTR 5
	LEN 16
	NOTE F_, 3
	INSTR 6
	LEN 8
	NOTE Csh, 2
	NOTE Csh, 2
	INSTR 5
	LEN 16
	NOTE F_, 3
	NEXT
Pat_54AD:
	DRUMS $08, DrumPat_56D1
	CH_TRANSPOSE $0C
	PAT_CALL Pat_5493
	PAT_GOTO Pat_5493
Pat_54B9:
	REPEAT 4
	PAT_CALL Pat_5493
	REPEAT_END
	NEXT
Pat_54BF:
	CH_TRANSPOSE $11
	REPEAT 3
	PAT_CALL Pat_5493
	REPEAT_END
	CH_TRANSPOSE $0C
Pat_54C8:
	INSTR 6
	LEN 8
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	INSTR 5
	LEN 16
	NOTE F_, 4
	INSTR 6
	LEN 8
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	INSTR 5
	LEN 16
	NOTE F_, 4
	INSTR 6
	LEN 8
	NOTE Csh, 2
	NOTE Csh, 2
	INSTR 5
	LEN 16
	NOTE F_, 4
	NEXT
Pat_54E2:
	REPEAT 4
	PAT_CALL Pat_54C8
	REPEAT_END
	NEXT
Pat_54E8:
	CH_TRANSPOSE $11
	REPEAT 2
	PAT_CALL Pat_54C8
	REPEAT_END
	CH_TRANSPOSE $0C
	REPEAT 2
	PAT_CALL Pat_54C8
	REPEAT_END
	NEXT
Pat_54F7:
	REPEAT 2
	PAT_CALL Pat_54C8
	REPEAT_END
	NEXT
Pat_54FD:
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Csh, 5
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Csh, 5
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE C_, 5
	NOTE Csh, 5
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Csh, 5
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE Gsh, 4
	NOTE G_, 4
	NEXT
Pat_5521:
	VIBRATO $08, $01, $04
	INSTR 3
	LEN 8
	CH_TRANSPOSE $F4
	PAT_CALL Pat_54FD
	NEXT
Pat_552D:
	REPEAT 2
	PAT_CALL Pat_54FD
	REPEAT_END
	NEXT
Pat_5533:
	CH_TRANSPOSE $00
	NOTE Ash, 3
	NOTE Csh, 4
	NOTE F_, 4
	NOTE Fsh, 4
	LEN 16
	NOTE F_, 4
	LEN 8
	NOTE Ash, 3
	NOTE Csh, 4
	NOTE F_, 4
	NOTE Fsh, 4
	LEN 16
	NOTE F_, 4
	LEN 8
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Ash, 3
	NOTE Csh, 4
	NOTE F_, 4
	NOTE Fsh, 4
	LEN 16
	NOTE F_, 4
	LEN 8
	NOTE Ash, 3
	NOTE Csh, 4
	NOTE F_, 4
	NOTE Fsh, 4
	LEN 16
	NOTE F_, 4
	LEN 8
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Ash, 3
	NOTE Csh, 4
	NOTE F_, 4
	NOTE Fsh, 4
	LEN 16
	NOTE F_, 4
	LEN 8
	NOTE Ash, 3
	NOTE Csh, 4
	NOTE F_, 4
	NOTE Fsh, 4
	LEN 16
	NOTE F_, 4
	LEN 8
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE C_, 4
	NOTE Csh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Csh, 5
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE Gsh, 4
	NOTE G_, 4
	NEXT
Pat_557D:
	INSTR 0
	LEN 16
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 24
	ARP 7
	NOTE Gsh, 4
	ARP_OFF
	NOTE Gsh, 4
	LEN 16
	NOTE F_, 4
	LEN 8
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Csh, 4
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Csh, 4
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Gsh, 3
	NOTE G_, 3
	LEN 16
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 24
	ARP 7
	NOTE Gsh, 4
	ARP_OFF
	NOTE Gsh, 4
	LEN 32
	NOTE C_, 5
	LEN 16
	NOTE Gsh, 4
	LEN 32
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NEXT
Pat_55AF:
	INSTR 0
	LEN 16
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	LEN 24
	ARP 7
	NOTE Ash, 4
	ARP_OFF
	NOTE Ash, 4
	LENGTH $30
	NOTE Csh, 5
	INSTR 1
	LEN 32
	NOTE Ash, 3
	NOTE C_, 4
	LEN 16
	NOTE Csh, 4
	LEN 8
	NOTE Dsh, 4
	NOTE Csh, 4
	LENGTH $80
	NOTE C_, 4
	LEN 32
	NOTE Csh, 4
	LEN 16
	NOTE C_, 4
	LEN 32
	NOTE Ash, 3
	LEN 16
	NOTE Gsh, 3
	LEN 32
	NOTE G_, 3
	NEXT
Pat_55D4:
	INSTR 3
	DUTY_50
	LEN 8
	PAT_CALL Pat_54FD
	NEXT
Pat_55DB:
	VIBRATO $08, $01, $04
	HWENV $00, $00
	LENGTH $40
	REST
	REST
	REST
	REST
	NEXT
Pat_55E9:
	INSTR 1
	LEN 16
	NOTE F_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 24
	NOTE G_, 4
	NOTE F_, 4
	LEN 32
	NOTE C_, 4
	INSTR 2
	LEN 16
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 8
	NOTE G_, 4
	NOTE G_, 3
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE Gsh, 3
	NOTE F_, 4
	NOTE Ash, 4
	NOTE C_, 5
	INSTR 1
	LEN 16
	NOTE F_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 24
	NOTE G_, 4
	NOTE F_, 4
	LEN 32
	NOTE Gsh, 4
	NOTE F_, 4
	INSTR 2
	LEN 8
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE Gsh, 4
	NOTE G_, 4
	NEXT
Pat_561B:
	INSTR 1
	LEN 16
	NOTE F_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 24
	NOTE G_, 4
	NOTE F_, 4
	LEN 32
	NOTE Csh, 4
	INSTR 2
	LEN 16
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	LEN 8
	NOTE C_, 5
	NOTE C_, 4
	NOTE Ash, 4
	NOTE Csh, 5
	NOTE Csh, 4
	NOTE Ash, 4
	NOTE Dsh, 5
	NOTE F_, 5
	INSTR 1
	LEN 16
	NOTE F_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 24
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 32
	NOTE G_, 4
	NOTE F_, 4
	INSTR 2
	LEN 8
	NOTE F_, 5
	NOTE Gsh, 5
	NOTE C_, 6
	NOTE Csh, 6
	NOTE C_, 6
	NOTE C_, 5
	NOTE C_, 6
	NOTE Csh, 6
	NOTE Gsh, 5
	NOTE G_, 5
	NEXT
Pat_564D:
	INSTR 0
	LEN 16
	NOTE F_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 24
	ARP 7
	NOTE F_, 4
	ARP_OFF
	NOTE F_, 4
	LEN 16
	NOTE C_, 4
	INSTR 1
	LEN 8
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Csh, 5
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE Gsh, 4
	NOTE G_, 4
	INSTR 0
	LEN 16
	NOTE F_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 24
	ARP 7
	NOTE F_, 4
	ARP_OFF
	NOTE F_, 4
	LEN 32
	NOTE Gsh, 4
	LEN 16
	NOTE F_, 4
	INSTR 1
	LEN 8
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE F_, 4
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE F_, 3
	NEXT
Pat_568B:
	INSTR 0
	LEN 16
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Csh, 5
	LEN 24
	ARP 7
	NOTE Csh, 5
	ARP_OFF
	NOTE Csh, 5
	LENGTH $80
	NOTE F_, 5
	LEN 8
	NOTE Dsh, 4
	NOTE Csh, 4
	LEN 32
	NOTE C_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	LEN 16
	NOTE Gsh, 4
	LEN 32
	NOTE G_, 4
	LEN 16
	NOTE F_, 4
	LEN 32
	NOTE Dsh, 4
	NEXT
Pat_56AB:
	INSTR 1
	LEN 8
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Csh, 4
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Csh, 4
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE C_, 4
	NOTE Csh, 4
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Csh, 4
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Csh, 4
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Gsh, 3
	NOTE G_, 3
	NEXT
DrumPat_56D1:
	db 1, 0, DRUM_TEMPO + 5, 13, 13, DRUM_TEMPO + 6, 13, DRUM_TEMPO + 8
	db 12, 0, 12, 0, 1, 13, 12, 0
	db 12, 0, 13, 13, 1, 0, DRUM_TEMPO + 5, 13
	db 13, DRUM_TEMPO + 6, 13, DRUM_TEMPO + 8, 12, 0, 12, 0
	db 1, 13, 12, 0, 12, 12, 12, 12
	db DRUM_LOOP

; Instrument table 1, entries 1..7 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr1_0
	dw Instr1_1
	dw Instr1_2
	dw Instr1_3
	dw Instr1_4
	dw Instr1_5
	dw Instr1_6
Instr1_0:
	HWENV $E2, $10, $60
	DUTY_75
	END
Instr1_1:
	HWENV $D2, $08, $30
	DUTY_75
	ARP 1
	END
Instr1_2:
	HWENV $C1, $08, $62
	END
Instr1_3:
	HWENV $A1, $04, $51
	ARP 0
	DUTY_12
	END
Instr1_4:
	WAVE Wave_78E5
	VOLENV 15, $11, $1A, $11
	ARP 14
	END
Instr1_5:
	WAVE Wave_78E5
	VOLENV 15, $11, $1A, $11
	ARP 15
	END
Instr1_6:
	VOLENV 15, $12, $1F, $11
	ARP 0
	WAVE Wave_78A5
	END

; Song 5: instrument table 7, arpeggio table 1 (the one SndInit sets)
PlaySong5:
	call StopAll
	ld de, Song5_Ch3
	call StartMusicCh3
	ld de, Song5_Ch2
	call StartMusicCh2
	ld de, Song5_Ch1
	jp StartMusicCh1
Song5_Ch3:
	dw Pat_5767
	dw Pat_57A6
	ORDER_LOOP Song5_Ch3
Song5_Ch2:
	dw Pat_57DD
	dw Pat_5800
	ORDER_LOOP Song5_Ch2
Song5_Ch1:
	dw Pat_5822
	ORDER_LOOP Song5_Ch1
Pat_5767:
	VIBRATO $09, $04, $04
	TRANSPOSE $03
	INSTR 18
	LEN 18
	NOTE D_, 2
	NOTE D_, 2
	INSTR 19
	NOTE D_, 4
	INSTR 18
	LEN 36
	NOTE D_, 2
	LEN 18
	NOTE D_, 2
	INSTR 19
	LEN 36
	NOTE D_, 4
	INSTR 18
	LEN 18
	NOTE F_, 2
	NOTE F_, 2
	INSTR 19
	NOTE F_, 4
	INSTR 18
	LEN 36
	NOTE F_, 2
	LEN 18
	NOTE F_, 2
	INSTR 19
	LEN 36
	NOTE F_, 4
	INSTR 18
	LEN 18
	NOTE D_, 2
	NOTE D_, 2
	INSTR 19
	NOTE D_, 4
	INSTR 18
	LEN 36
	NOTE D_, 2
	LEN 18
	NOTE D_, 2
	INSTR 19
	LEN 36
	NOTE D_, 4
	INSTR 18
	LEN 18
	NOTE A_, 2
	NOTE A_, 2
	INSTR 19
	NOTE A_, 4
	INSTR 18
	LEN 36
	NOTE A_, 2
	LEN 18
	NOTE A_, 2
	INSTR 19
	LEN 36
	NOTE A_, 4
	NEXT
Pat_57A6:
	INSTR 18
	LEN 18
	NOTE G_, 2
	NOTE G_, 2
	INSTR 19
	NOTE G_, 4
	INSTR 18
	LEN 36
	NOTE G_, 2
	LEN 18
	NOTE G_, 2
	INSTR 19
	LEN 36
	NOTE G_, 4
	INSTR 18
	NOTE Dsh, 2
	INSTR 19
	LEN 18
	NOTE Dsh, 4
	INSTR 18
	LEN 36
	NOTE G_, 2
	LEN 18
	NOTE F_, 2
	INSTR 19
	NOTE Dsh, 4
	INSTR 18
	NOTE Dsh, 2
	NOTE G_, 2
	NOTE G_, 2
	INSTR 19
	NOTE G_, 4
	INSTR 18
	LEN 36
	NOTE G_, 2
	LEN 18
	NOTE G_, 2
	INSTR 19
	LEN 36
	NOTE G_, 4
	INSTR 18
	LEN 18
	NOTE A_, 2
	NOTE A_, 2
	INSTR 19
	NOTE A_, 4
	INSTR 18
	LEN 36
	NOTE A_, 2
	LEN 18
	NOTE A_, 2
	INSTR 19
	NOTE A_, 4
	NOTE A_, 4
	NEXT
Pat_57DD:
	INSTR 9
	LEN 18
	NOTE D_, 3
	NOTE A_, 3
	NOTE F_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE F_, 3
	NOTE C_, 4
	NOTE Gsh, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE D_, 3
	NOTE A_, 3
	NOTE F_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE A_, 3
	NOTE E_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE B_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE E_, 4
	NEXT
Pat_5800:
	LEN 18
	NOTE G_, 3
	NOTE D_, 4
	NOTE Ash, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE Dsh, 3
	NOTE Ash, 3
	NOTE G_, 4
	NOTE Ash, 3
	NOTE F_, 4
	NOTE Ash, 3
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE G_, 3
	NOTE D_, 4
	NOTE Ash, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE A_, 3
	NOTE A_, 3
	NOTE G_, 4
	NOTE A_, 3
	NOTE F_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE A_, 3
	NEXT
Pat_5822:
	DRUMS $09, DrumPat_5883
	HWENV $F1, $04, $67
	DUTY_50
	VIBRATO $12, $02, $04
	ARP 19
	LEN 36
	NOTE D_, 2
	GLISS_3
	NOTE A_, 3
	GLISS_1
	LEN 18
	NOTE A_, 3
	NOTE G_, 3
	LEN 36
	NOTE A_, 3
	NOTE C_, 4
	LEN 18
	NOTE D_, 4
	LEN 36
	NOTE C_, 4
	NOTE Gsh, 3
	GLISS_3
	LEN 18
	NOTE C_, 2
	LEN 36
	NOTE D_, 2
	NOTE A_, 3
	GLISS_1
	LEN 18
	NOTE A_, 3
	NOTE G_, 3
	LEN 36
	NOTE A_, 3
	LEN 27
	NOTE C_, 4
	NOTE D_, 4
	LEN 18
	NOTE C_, 4
	LEN 36
	NOTE A_, 3
	GLISS_3
	LEN 18
	NOTE A_, 2
	NOTE A_, 3
	LEN 18
	GLISS_1
	NOTE Ash, 3
	NOTE A_, 3
	NOTE G_, 3
	LEN 36
	NOTE A_, 3
	LEN 18
	NOTE Ash, 3
	LEN 36
	NOTE Dsh, 3
	GLISS_3
	LENGTH $36
	NOTE Dsh, 2
	GLISS_1
	LEN 36
	NOTE G_, 2
	NOTE F_, 2
	LEN 18
	NOTE Dsh, 2
	NOTE G_, 2
	LEN 18
	NOTE G_, 2
	LEN 36
	GLISS_3
	NOTE Ash, 3
	GLISS_1
	LEN 18
	NOTE Ash, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE G_, 3
	LEN 36
	NOTE F_, 3
	LEN 18
	NOTE E_, 3
	NOTE D_, 3
	GLISS_3
	NEXT
DrumPat_5883:
	db DRUM_REPEAT + 3, 1, 0, 5, 0, 2, 0, 1
	db 0, 1, 0, 5, 0, 2, 0, 4
	db 0, DRUM_REPEAT_END, 1, 0, 5, 0, 2, 0
	db 1, 0, 1, 0, 1, 0, 2, 6
	db 2, 0, DRUM_LOOP

; Song 6: instrument table 2, arpeggio table 1 (the one SndInit sets)
PlaySong6:
	call StopAll
	ld a, $5C
	ld [wInstrTableHi], a
	ld a, $D5
	ld [wInstrTable], a
	ld de, Song6_Ch3
	call StartMusicCh3
	ld de, Song6_Ch2
	call StartMusicCh2
	ld de, Song6_Ch1
	jp StartMusicCh1
Song6_Ch3:
	dw Pat_58D7
	ORDER_LOOP Song6_Ch3
Song6_Ch2:
	dw Pat_5A86
	ORDER_LOOP Song6_Ch2
Song6_Ch1:
	dw Pat_5B49
	ORDER_LOOP Song6_Ch1
Pat_58D7:
	CH_TRANSPOSE $0C
	WAVE Wave_78A5
	INSTR 0
	LEN 16
	REPEAT 2
	NOTE Fsh, 2
	INSTR 1
	LEN 8
	NOTE Fsh, 2
	NOTE Fsh, 2
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	INSTR 1
	LEN 8
	NOTE Fsh, 2
	NOTE Fsh, 2
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	INSTR 1
	LEN 8
	NOTE Fsh, 2
	NOTE Fsh, 2
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	NOTE Fsh, 2
	REPEAT_END
	REPEAT 2
	NOTE G_, 2
	INSTR 1
	LEN 8
	NOTE G_, 2
	NOTE G_, 2
	INSTR 0
	LEN 16
	NOTE G_, 2
	INSTR 1
	LEN 8
	NOTE G_, 2
	NOTE G_, 2
	INSTR 0
	LEN 16
	NOTE G_, 2
	INSTR 1
	LEN 8
	NOTE G_, 2
	NOTE G_, 2
	INSTR 0
	LEN 16
	NOTE G_, 2
	NOTE G_, 2
	REPEAT_END
	INSTR 0
	LEN 16
	REPEAT 2
	NOTE E_, 2
	INSTR 1
	LEN 8
	NOTE E_, 2
	NOTE E_, 2
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	LEN 8
	NOTE E_, 2
	NOTE E_, 2
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	LEN 8
	NOTE E_, 2
	NOTE E_, 2
	INSTR 0
	LEN 16
	NOTE E_, 2
	NOTE E_, 2
	REPEAT_END
	REPEAT 2
	NOTE C_, 2
	INSTR 1
	LEN 8
	NOTE C_, 2
	NOTE C_, 2
	INSTR 0
	LEN 16
	NOTE C_, 2
	INSTR 1
	LEN 8
	NOTE C_, 2
	NOTE C_, 2
	INSTR 0
	LEN 16
	NOTE C_, 2
	INSTR 1
	LEN 8
	NOTE C_, 2
	NOTE C_, 2
	INSTR 0
	LEN 16
	NOTE C_, 2
	NOTE C_, 2
	REPEAT_END
	INSTR 0
	LEN 16
	REPEAT 2
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE A_, 2
	NOTE G_, 2
	REPEAT_END
	NOTE F_, 2
	INSTR 1
	LEN 8
	NOTE C_, 3
	NOTE F_, 3
	INSTR 0
	LEN 16
	NOTE F_, 2
	INSTR 1
	LEN 8
	NOTE C_, 3
	NOTE F_, 3
	INSTR 0
	LEN 16
	NOTE F_, 2
	INSTR 1
	LEN 8
	NOTE C_, 3
	NOTE F_, 3
	INSTR 0
	LEN 16
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE A_, 2
	NOTE E_, 2
	INSTR 0
	LEN 16
	REPEAT 2
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE A_, 2
	NOTE G_, 2
	REPEAT_END
	NOTE F_, 2
	INSTR 1
	LEN 8
	NOTE C_, 3
	NOTE F_, 3
	INSTR 0
	LEN 16
	NOTE F_, 2
	INSTR 1
	LEN 8
	NOTE C_, 3
	NOTE F_, 3
	INSTR 0
	LEN 16
	NOTE F_, 2
	INSTR 1
	LEN 8
	NOTE C_, 3
	NOTE F_, 3
	INSTR 0
	LEN 16
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE A_, 2
	NOTE A_, 2
	INSTR 0
	LEN 16
	NOTE G_, 2
	NOTE G_, 2
	INSTR 1
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	NOTE G_, 2
	LEN 16
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	NOTE G_, 2
	LEN 16
	NOTE G_, 2
	INSTR 0
	NOTE G_, 2
	NOTE F_, 2
	NOTE F_, 2
	INSTR 1
	NOTE F_, 2
	LEN 8
	NOTE F_, 2
	NOTE F_, 2
	LEN 16
	NOTE F_, 2
	LEN 8
	NOTE F_, 2
	NOTE F_, 2
	LEN 16
	NOTE F_, 2
	LEN 8
	NOTE F_, 2
	NOTE F_, 2
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE B_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE C_, 3
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE D_, 3
	NOTE E_, 3
	INSTR 0
	LEN 16
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	INSTR 1
	NOTE G_, 2
	LEN 16
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	NOTE G_, 2
	LEN 16
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	NOTE G_, 2
	LEN 16
	NOTE G_, 2
	INSTR 0
	LEN 8
	NOTE D_, 2
	NOTE E_, 2
	LEN 16
	NOTE F_, 2
	LEN 8
	NOTE F_, 2
	INSTR 1
	NOTE F_, 2
	LEN 16
	NOTE F_, 2
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 2
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 2
	INSTR 0
	NOTE A_, 2
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	LEN 8
	NOTE E_, 2
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE A_, 2
	NOTE A_, 2
	NEXT
Pat_5A86:
	VIBRATO $10, $02, $04
	INSTR 4
	LENGTH $50
	NOTE Csh, 3
	LEN 32
	NOTE Fsh, 3
	LEN 16
	NOTE E_, 3
	LENGTH $70
	NOTE Fsh, 3
	LEN 16
	NOTE Csh, 3
	LENGTH $60
	NOTE D_, 3
	LEN 24
	NOTE D_, 3
	LEN 8
	NOTE Csh, 3
	LEN 32
	NOTE B_, 2
	LEN 24
	NOTE D_, 4
	LEN 8
	NOTE Csh, 4
	LENGTH $40
	NOTE B_, 3
	INSTR 4
	LENGTH $50
	NOTE B_, 2
	LEN 32
	NOTE E_, 3
	LEN 16
	NOTE D_, 3
	LENGTH $70
	NOTE E_, 3
	LEN 16
	NOTE E_, 3
	LENGTH $60
	NOTE G_, 3
	LEN 24
	NOTE G_, 3
	LEN 8
	NOTE Fsh, 3
	LEN 32
	NOTE E_, 3
	LEN 24
	NOTE G_, 4
	LEN 8
	NOTE Fsh, 4
	LEN 16
	NOTE E_, 4
	HWENV $A2, $00
	DUTY_75
	ARP 0
	NOTE C_, 4
	NOTE B_, 3
	NOTE G_, 3
	LEN 8
	REPEAT 8
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE E_, 4
	REPEAT_END
	REPEAT 4
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	REPEAT_END
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE G_, 4
	NOTE A_, 3
	NOTE B_, 3
	INSTR 4
	NOTE A_, 3
	NOTE B_, 3
	INSTR 4
	LEN 32
	NOTE C_, 4
	NOTE B_, 3
	LEN 16
	NOTE C_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	LEN 32
	NOTE D_, 4
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE D_, 4
	NOTE C_, 4
	LEN 32
	NOTE B_, 3
	NOTE A_, 3
	NOTE F_, 4
	LEN 16
	NOTE E_, 4
	LEN 32
	NOTE F_, 4
	LEN 16
	NOTE A_, 4
	NOTE G_, 4
	NOTE D_, 4
	LEN 8
	NOTE B_, 3
	LEN 24
	NOTE C_, 4
	LEN 32
	NOTE C_, 4
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE E_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	INSTR 4
	LEN 16
	NOTE B_, 3
	LEN 32
	NOTE B_, 3
	NOTE D_, 4
	NOTE B_, 3
	LEN 16
	NOTE B_, 3
	NOTE A_, 3
	LEN 32
	NOTE A_, 3
	NOTE D_, 4
	NOTE C_, 4
	LENGTH $40
	NOTE C_, 4
	LENGTH $30
	NOTE B_, 3
	LEN 16
	NOTE G_, 3
	LEN 32
	NOTE A_, 3
	NOTE G_, 3
	NOTE E_, 3
	LEN 16
	NOTE D_, 3
	NOTE E_, 3
	NOTE A_, 3
	INSTR 4
	LEN 16
	NOTE G_, 3
	LEN 32
	NOTE G_, 3
	NOTE B_, 3
	NOTE G_, 3
	LEN 8
	NOTE D_, 3
	NOTE E_, 3
	LEN 16
	NOTE F_, 3
	LEN 32
	NOTE F_, 3
	NOTE C_, 4
	NOTE B_, 3
	LEN 16
	NOTE A_, 3
	LENGTH $80
	NOTE A_, 3
	WAIT
	NEXT
Pat_5B49:
	VIBRATO $10, $02, $04
	DRUMS $08, DrumPat_5C39
	INSTR 3
	LEN 32
	NOTE Csh, 4
	LEN 16
	NOTE Fsh, 4
	NOTE E_, 4
	LENGTH $50
	NOTE Fsh, 4
	LEN 16
	NOTE Csh, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE Fsh, 4
	LEN 32
	NOTE G_, 4
	LEN 24
	NOTE D_, 4
	LEN 8
	NOTE Csh, 4
	LEN 32
	NOTE B_, 3
	INSTR 2
	LEN 24
	NOTE D_, 3
	LEN 8
	NOTE Csh, 3
	LEN 32
	NOTE B_, 2
	LEN 24
	NOTE D_, 4
	LEN 8
	NOTE Csh, 4
	LEN 16
	NOTE B_, 3
	INSTR 3
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	INSTR 3
	LEN 32
	NOTE B_, 3
	LEN 16
	NOTE E_, 4
	NOTE D_, 4
	LENGTH $50
	NOTE E_, 4
	LEN 16
	NOTE D_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE D_, 5
	LEN 32
	NOTE C_, 5
	LEN 24
	NOTE G_, 4
	LEN 8
	NOTE Fsh, 4
	LEN 32
	NOTE E_, 4
	INSTR 2
	LEN 24
	NOTE G_, 3
	LEN 8
	NOTE Fsh, 3
	LEN 32
	NOTE E_, 3
	LEN 24
	NOTE G_, 4
	LEN 8
	NOTE Fsh, 4
	LEN 16
	NOTE E_, 4
	INSTR 3
	ARP 1
	NOTE C_, 5
	NOTE B_, 4
	NOTE G_, 4
	DRUMS $08, DrumPat_5CB0
	LENGTH $50
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	LEN 32
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	LENGTH $50
	NOTE A_, 4
	LEN 16
	NOTE G_, 4
	LEN 24
	NOTE C_, 4
	LEN 8
	NOTE D_, 4
	LENGTH $70
	NOTE E_, 4
	INSTR 3
	LEN 8
	NOTE C_, 5
	NOTE D_, 5
	INSTR 3
	LENGTH $50
	NOTE E_, 5
	LEN 16
	NOTE E_, 5
	NOTE D_, 5
	NOTE E_, 5
	LEN 32
	NOTE F_, 5
	NOTE E_, 5
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE E_, 5
	NOTE D_, 5
	LEN 32
	NOTE C_, 5
	LENGTH $50
	NOTE A_, 5
	LEN 16
	NOTE C_, 6
	NOTE B_, 5
	NOTE G_, 5
	LEN 8
	NOTE D_, 5
	LEN 24
	NOTE E_, 5
	LENGTH $30
	NOTE E_, 5
	LEN 8
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	DRUMS $08, DrumPat_5C61
	INSTR 3
	LEN 16
	NOTE D_, 4
	LEN 32
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	LEN 16
	NOTE D_, 4
	NOTE C_, 4
	LEN 32
	NOTE C_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	DRUMS $08, DrumPat_5C89
	LENGTH $D0
	WAIT
	LEN 8
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	DRUMS $08, DrumPat_5C61
	INSTR 3
	LEN 16
	NOTE D_, 4
	LEN 32
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	LEN 8
	NOTE D_, 4
	NOTE E_, 4
	LEN 16
	NOTE F_, 4
	LEN 32
	NOTE F_, 4
	NOTE C_, 5
	NOTE B_, 4
	LEN 16
	NOTE A_, 4
	LENGTH $60
	DRUMS $08, DrumPat_5C89
	NOTE A_, 4
	LEN 32
	NOTE E_, 2
	LENGTH $50
	NOTE A_, 2
	LEN 8
	NOTE A_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE A_, 3
	NEXT
DrumPat_5C39:
	db DRUM_LEVEL + 14, 12, 0, 13, 13, 12, 0, 13
	db 13, 12, 12, 12, 0, 12, 0, DRUM_TEMPO + 4
	db 13, 13, DRUM_TEMPO + 8, 13, 12, 0, 13, 13
	db 12, 0, 13, 13, 12, 12, 12, 0
	db 12, 12, DRUM_TEMPO + 4, 13, 13, DRUM_TEMPO + 8, 12, DRUM_LOOP
DrumPat_5C61:
	db DRUM_LEVEL + 14, 7, 0, 13, 13, 12, 0, 13
	db 13, 12, 12, 12, 0, 12, 0, DRUM_TEMPO + 4
	db 13, 13, DRUM_TEMPO + 8, 13, 7, 0, 13, 13
	db 12, 0, 13, 13, 12, 12, 12, 0
	db 12, 12, DRUM_TEMPO + 4, 13, 13, DRUM_TEMPO + 8, 12, DRUM_LOOP
DrumPat_5C89:
	db 7, 0, 13, 13, 2, 0, 13, 13
	db 1, 12, 12, 0, 2, 0, DRUM_TEMPO + 4, 1
	db 13, DRUM_TEMPO + 8, 13, 11, 0, 13, 13, 2
	db 0, 13, 13, 1, 12, 12, 0, 2
	db 12, DRUM_TEMPO + 4, 1, 13, DRUM_TEMPO + 8, 12, DRUM_LOOP
DrumPat_5CB0:
	db 11, 0, 13, 13, 2, 0, 13, 13
	db 1, 12, 12, 0, 2, 0, DRUM_TEMPO + 4, 1
	db 13, DRUM_TEMPO + 8, 13, 11, 0, 13, 13, 2
	db 0, 13, 13, 1, 12, 12, 0, 2
	db 12, DRUM_TEMPO + 4, 1, 13, DRUM_TEMPO + 8, 12, DRUM_LOOP

; Instrument table 2, entries 1..5 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr2_0
	dw Instr2_1
	dw Instr2_2
	dw Instr2_3
	dw Instr2_4
Instr2_0:
	VOLENV 15, $11, $1F, $12
	ARP 0
	END
Instr2_1:
	VOLENV 15, $12, $2F, $11
	ARP 0
	END
Instr2_2:
	HWENV $A3, $08, $63
	END
Instr2_3:
	HWENV $D2, $10, $50
	END
Instr2_4:
	HWENV $B2, $10, $40
	DUTY_75
	ARP 1
	END

; Song 7: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong7:
	call StopAll
	ld a, $61
	ld [wInstrTableHi], a
	ld a, $B5
	ld [wInstrTable], a
	ld de, Song7_Ch3
	call StartMusicCh3
	ld de, Song7_Ch2
	call StartMusicCh2
	ld de, Song7_Ch1
	jp StartMusicCh1
Song7_Ch3:
	dw Pat_5D51
Loop_5D1F:
	dw Pat_5D5E
	dw Pat_5D5E
	dw Pat_5D73
	dw Pat_5D9D
	dw Pat_5DCF
	dw Pat_5E2C
	ORDER_LOOP Loop_5D1F
Song7_Ch2:
	dw Pat_5E87
Loop_5D31:
	dw Pat_5E94
	dw Pat_5E94
	dw Pat_5EA9
	dw Pat_5F18
	dw Pat_5F83
	dw Pat_5FF3
	ORDER_LOOP Loop_5D31
Song7_Ch1:
	dw Pat_605F
Loop_5D43:
	dw Pat_6071
	dw Pat_60A2
	dw Pat_60D0
	dw Pat_60F0
	dw Pat_612A
	ORDER_LOOP Loop_5D43
Pat_5D51:
	VOLENV 0, $00, $00, $00
	LENGTH $80
	WAIT
	WAIT
	VIBRATO $08, $08, $04
	NEXT
Pat_5D5E:
	LEN 16
	REPEAT 7
	INSTR 2
	NOTE Fsh, 2
	INSTR 3
	NOTE Fsh, 2
	NOTE Fsh, 2
	NOTE Fsh, 2
	REPEAT_END
	INSTR 2
	LEN 8
	NOTE Fsh, 2
	INSTR 3
	NOTE Csh, 2
	NOTE E_, 2
	NOTE Fsh, 2
	NOTE A_, 2
	NOTE Gsh, 2
	NOTE Fsh, 2
	NOTE E_, 2
	NEXT
Pat_5D73:
	LEN 16
	REPEAT 2
	INSTR 2
	NOTE Fsh, 2
	INSTR 3
	NOTE Fsh, 2
	INSTR 1
	NOTE Fsh, 4
	INSTR 3
	NOTE Fsh, 2
	REPEAT_END
	REPEAT 2
	INSTR 2
	NOTE D_, 2
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE D_, 2
	REPEAT_END
	REPEAT 2
	INSTR 2
	NOTE E_, 2
	INSTR 3
	NOTE E_, 2
	INSTR 1
	NOTE E_, 4
	INSTR 3
	NOTE E_, 2
	REPEAT_END
	REPEAT 2
	INSTR 2
	NOTE F_, 2
	INSTR 3
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE F_, 2
	REPEAT_END
	NEXT
Pat_5D9D:
	REPEAT 2
	INSTR 2
	NOTE Fsh, 2
	INSTR 3
	NOTE Fsh, 2
	INSTR 1
	NOTE Fsh, 4
	INSTR 3
	NOTE Fsh, 2
	REPEAT_END
	REPEAT 2
	INSTR 2
	NOTE B_, 2
	INSTR 3
	NOTE B_, 2
	INSTR 1
	NOTE Fsh, 4
	INSTR 3
	NOTE B_, 2
	REPEAT_END
	REPEAT 2
	INSTR 2
	NOTE Csh, 2
	INSTR 3
	NOTE Csh, 2
	INSTR 1
	NOTE A_, 4
	INSTR 3
	NOTE Csh, 2
	REPEAT_END
	INSTR 2
	NOTE Csh, 2
	INSTR 3
	NOTE Csh, 2
	INSTR 1
	NOTE Gsh, 4
	INSTR 3
	NOTE Csh, 2
	INSTR 2
	LEN 8
	NOTE Csh, 2
	INSTR 3
	NOTE Csh, 3
	NOTE Csh, 3
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE Csh, 3
	NOTE Csh, 2
	NOTE Csh, 4
	NEXT
Pat_5DCF:
	INSTR 2
	LEN 8
	NOTE Fsh, 2
	INSTR 3
	LEN 16
	NOTE Fsh, 2
	LEN 8
	NOTE Fsh, 2
	INSTR 1
	LEN 16
	NOTE Fsh, 4
	INSTR 3
	LEN 8
	NOTE Fsh, 2
	NOTE Fsh, 2
	INSTR 2
	LEN 16
	NOTE Fsh, 2
	NOTE Fsh, 2
	INSTR 1
	NOTE Fsh, 4
	INSTR 2
	NOTE E_, 2
	LEN 8
	NOTE E_, 2
	LEN 16
	NOTE Fsh, 2
	INSTR 3
	LEN 8
	NOTE Fsh, 2
	INSTR 1
	LEN 16
	NOTE Fsh, 4
	INSTR 3
	LEN 8
	NOTE Fsh, 2
	NOTE Fsh, 2
	INSTR 2
	LEN 16
	NOTE Fsh, 2
	NOTE Fsh, 2
	INSTR 1
	NOTE Fsh, 4
	INSTR 2
	LEN 8
	NOTE Fsh, 2
	NOTE E_, 2
	LEN 24
	NOTE D_, 2
	LEN 8
	NOTE A_, 2
	INSTR 1
	NOTE A_, 4
	INSTR 3
	NOTE A_, 2
	INSTR 2
	LEN 16
	NOTE D_, 2
	LEN 24
	NOTE E_, 2
	LEN 8
	NOTE B_, 2
	INSTR 1
	NOTE B_, 4
	INSTR 3
	NOTE B_, 2
	INSTR 2
	LEN 16
	NOTE E_, 2
	LEN 24
	NOTE A_, 2
	LEN 8
	NOTE E_, 3
	INSTR 1
	LEN 16
	NOTE A_, 4
	INSTR 2
	LEN 24
	NOTE A_, 2
	LEN 8
	NOTE E_, 3
	LEN 16
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE A_, 4
	INSTR 3
	NOTE A_, 2
	INSTR 2
	NOTE Gsh, 2
	INSTR 3
	NOTE Gsh, 2
	NEXT
Pat_5E2C:
	INSTR 2
	LEN 8
	NOTE Fsh, 2
	INSTR 3
	LEN 16
	NOTE Fsh, 2
	LEN 8
	NOTE Fsh, 2
	INSTR 1
	LEN 16
	NOTE Fsh, 4
	INSTR 3
	LEN 8
	NOTE Fsh, 2
	NOTE Fsh, 2
	INSTR 2
	LEN 16
	NOTE Fsh, 2
	NOTE Fsh, 2
	INSTR 1
	NOTE Fsh, 4
	INSTR 2
	NOTE E_, 2
	LEN 8
	NOTE E_, 2
	LEN 16
	NOTE Fsh, 2
	INSTR 3
	LEN 8
	NOTE Fsh, 2
	INSTR 1
	LEN 16
	NOTE Fsh, 4
	INSTR 3
	LEN 8
	NOTE Fsh, 2
	NOTE Fsh, 2
	INSTR 2
	LEN 16
	NOTE Fsh, 2
	NOTE Fsh, 2
	INSTR 1
	NOTE Fsh, 4
	INSTR 2
	LEN 8
	NOTE Fsh, 2
	NOTE E_, 2
	LEN 24
	NOTE D_, 2
	LEN 8
	NOTE A_, 2
	INSTR 1
	NOTE A_, 4
	INSTR 3
	NOTE A_, 2
	INSTR 2
	LEN 16
	NOTE D_, 2
	LEN 24
	NOTE E_, 2
	LEN 8
	NOTE B_, 2
	INSTR 1
	NOTE B_, 4
	INSTR 3
	NOTE B_, 2
	INSTR 2
	LEN 16
	NOTE E_, 2
	NOTE Fsh, 2
	LEN 8
	NOTE Fsh, 3
	NOTE Fsh, 2
	INSTR 1
	NOTE Fsh, 4
	INSTR 3
	NOTE Fsh, 3
	INSTR 2
	LEN 16
	NOTE E_, 2
	LEN 8
	NOTE Fsh, 2
	INSTR 3
	NOTE Csh, 2
	NOTE E_, 2
	NOTE Fsh, 2
	NOTE A_, 2
	NOTE Gsh, 2
	NOTE Fsh, 2
	NOTE E_, 2
	NEXT
Pat_5E87:
	INSTR 0
	LEN 8
	REPEAT 4
	NOTE Fsh, 2
	NOTE Fsh, 3
	NOTE Fsh, 3
	NOTE Fsh, 4
	NOTE Fsh, 3
	NOTE Fsh, 3
	NOTE Fsh, 4
	NOTE Fsh, 3
	REPEAT_END
	NEXT
Pat_5E94:
	INSTR 0
	LEN 8
	REPEAT 7
	NOTE Fsh, 2
	NOTE Fsh, 3
	NOTE Fsh, 3
	NOTE Fsh, 4
	NOTE Fsh, 3
	NOTE Fsh, 3
	NOTE Fsh, 4
	NOTE Fsh, 3
	REPEAT_END
	NOTE Fsh, 2
	NOTE Csh, 3
	NOTE E_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE Fsh, 3
	NOTE E_, 3
	NEXT
Pat_5EA9:
	INSTR 0
	LEN 8
	NOTE Fsh, 3
	NOTE Fsh, 3
	INSTR 5
	NOTE Fsh, 3
	INSTR 0
	NOTE Fsh, 3
	NOTE Fsh, 3
	INSTR 5
	NOTE Fsh, 3
	INSTR 0
	NOTE Fsh, 3
	NOTE Fsh, 3
	INSTR 5
	LEN 16
	NOTE Fsh, 3
	INSTR 0
	LEN 8
	NOTE Fsh, 3
	INSTR 5
	NOTE Fsh, 3
	INSTR 0
	NOTE Fsh, 3
	NOTE Fsh, 3
	INSTR 5
	NOTE Fsh, 3
	INSTR 0
	NOTE Fsh, 4
	NOTE D_, 3
	NOTE D_, 3
	INSTR 4
	NOTE D_, 3
	INSTR 0
	NOTE D_, 3
	NOTE D_, 3
	INSTR 4
	NOTE D_, 3
	INSTR 0
	NOTE D_, 3
	NOTE D_, 3
	INSTR 4
	LEN 16
	NOTE D_, 3
	INSTR 0
	LEN 8
	NOTE D_, 3
	INSTR 4
	NOTE D_, 3
	INSTR 0
	NOTE D_, 3
	NOTE D_, 3
	INSTR 4
	NOTE D_, 3
	INSTR 0
	NOTE D_, 4
	NOTE E_, 3
	NOTE E_, 3
	INSTR 4
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	NOTE E_, 3
	INSTR 4
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	NOTE E_, 3
	INSTR 4
	LEN 16
	NOTE E_, 3
	INSTR 0
	LEN 8
	NOTE E_, 3
	INSTR 4
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	NOTE E_, 3
	INSTR 4
	NOTE E_, 3
	INSTR 0
	NOTE E_, 4
	NOTE F_, 3
	NOTE F_, 3
	INSTR 4
	NOTE Csh, 3
	INSTR 0
	NOTE F_, 3
	NOTE F_, 3
	INSTR 4
	NOTE Csh, 3
	INSTR 0
	NOTE F_, 3
	NOTE F_, 3
	INSTR 4
	LEN 16
	NOTE Csh, 3
	INSTR 0
	LEN 8
	NOTE F_, 3
	INSTR 4
	NOTE Csh, 3
	INSTR 0
	NOTE F_, 3
	NOTE F_, 3
	INSTR 4
	NOTE Csh, 3
	INSTR 0
	NOTE F_, 4
	NEXT
Pat_5F18:
	INSTR 0
	LEN 8
	NOTE Fsh, 3
	NOTE Fsh, 3
	INSTR 5
	NOTE Fsh, 3
	INSTR 0
	NOTE Fsh, 3
	NOTE Fsh, 3
	INSTR 5
	NOTE Fsh, 3
	INSTR 0
	NOTE Fsh, 3
	NOTE Fsh, 3
	INSTR 5
	LEN 16
	NOTE Fsh, 3
	INSTR 0
	LEN 8
	NOTE Fsh, 3
	INSTR 5
	NOTE Fsh, 3
	INSTR 0
	NOTE Fsh, 3
	NOTE Fsh, 3
	INSTR 5
	NOTE Fsh, 3
	INSTR 0
	NOTE Fsh, 4
	NOTE Fsh, 3
	NOTE Fsh, 3
	INSTR 5
	NOTE B_, 3
	INSTR 0
	NOTE Fsh, 3
	NOTE Fsh, 3
	INSTR 5
	NOTE B_, 3
	INSTR 0
	NOTE Fsh, 3
	NOTE Fsh, 3
	INSTR 5
	LEN 16
	NOTE B_, 3
	INSTR 0
	LEN 8
	NOTE Fsh, 3
	INSTR 5
	NOTE B_, 3
	INSTR 0
	NOTE Fsh, 3
	NOTE Fsh, 3
	INSTR 5
	NOTE B_, 3
	INSTR 0
	NOTE Fsh, 4
	NOTE A_, 3
	NOTE A_, 3
	INSTR 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	NOTE A_, 3
	INSTR 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	NOTE A_, 3
	INSTR 4
	LEN 16
	NOTE D_, 4
	INSTR 0
	LEN 8
	NOTE A_, 3
	INSTR 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	NOTE A_, 3
	INSTR 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 4
	NOTE Gsh, 3
	NOTE Gsh, 3
	INSTR 4
	NOTE Csh, 4
	INSTR 0
	NOTE Gsh, 3
	NOTE Gsh, 3
	INSTR 4
	NOTE Csh, 4
	INSTR 0
	NOTE Gsh, 3
	NOTE Gsh, 3
	INSTR 4
	LEN 16
	NOTE Csh, 4
	INSTR 0
	LEN 8
	NOTE Csh, 4
	NOTE Csh, 3
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE Csh, 3
	NOTE Csh, 5
	NEXT
Pat_5F83:
	INSTR 0
	LEN 8
	NOTE Csh, 4
	NOTE Csh, 4
	INSTR 5
	NOTE Fsh, 4
	INSTR 0
	NOTE Csh, 4
	NOTE Csh, 4
	INSTR 5
	NOTE Fsh, 4
	INSTR 0
	NOTE Csh, 4
	NOTE Csh, 4
	INSTR 5
	LEN 16
	NOTE Fsh, 4
	INSTR 0
	LEN 8
	NOTE Csh, 4
	INSTR 5
	NOTE Fsh, 4
	INSTR 0
	NOTE Csh, 4
	NOTE Csh, 4
	INSTR 5
	NOTE Fsh, 4
	INSTR 0
	LEN 16
	NOTE Csh, 4
	LEN 8
	NOTE Csh, 4
	INSTR 5
	NOTE Fsh, 4
	INSTR 0
	NOTE Csh, 4
	NOTE Csh, 4
	INSTR 5
	NOTE Fsh, 4
	INSTR 0
	NOTE Csh, 4
	NOTE Csh, 4
	INSTR 5
	LEN 16
	NOTE Fsh, 4
	INSTR 0
	LEN 8
	NOTE Csh, 4
	INSTR 5
	NOTE Fsh, 4
	INSTR 0
	NOTE Csh, 4
	NOTE Csh, 4
	INSTR 5
	NOTE Fsh, 4
	INSTR 0
	NOTE Csh, 4
	NOTE A_, 3
	NOTE A_, 3
	INSTR 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	NOTE A_, 3
	INSTR 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	NOTE A_, 3
	INSTR 4
	LEN 16
	NOTE E_, 4
	INSTR 0
	LEN 8
	NOTE B_, 3
	INSTR 4
	NOTE E_, 4
	INSTR 0
	NOTE B_, 3
	NOTE B_, 3
	INSTR 4
	NOTE E_, 4
	INSTR 0
	NOTE B_, 3
	NOTE E_, 4
	NOTE E_, 4
	INSTR 4
	NOTE A_, 4
	INSTR 0
	NOTE E_, 4
	NOTE E_, 4
	INSTR 4
	NOTE A_, 4
	INSTR 0
	NOTE E_, 4
	NOTE E_, 4
	INSTR 4
	LEN 16
	NOTE A_, 4
	INSTR 0
	LEN 8
	NOTE E_, 4
	INSTR 4
	NOTE A_, 4
	INSTR 0
	NOTE Csh, 4
	NOTE Csh, 4
	INSTR 4
	NOTE A_, 4
	INSTR 0
	NOTE Csh, 4
	NEXT
Pat_5FF3:
	INSTR 0
	LEN 8
	NOTE Csh, 4
	NOTE Csh, 4
	INSTR 5
	NOTE Fsh, 4
	INSTR 0
	NOTE Csh, 4
	NOTE Csh, 4
	INSTR 5
	NOTE Fsh, 4
	INSTR 0
	NOTE Csh, 4
	NOTE Csh, 4
	INSTR 5
	LEN 16
	NOTE Fsh, 4
	INSTR 0
	LEN 8
	NOTE Csh, 4
	INSTR 5
	NOTE Fsh, 4
	INSTR 0
	NOTE Csh, 4
	NOTE Csh, 4
	INSTR 5
	NOTE Fsh, 4
	INSTR 0
	LEN 16
	NOTE Csh, 4
	LEN 8
	NOTE Csh, 4
	INSTR 5
	NOTE Fsh, 4
	INSTR 0
	NOTE Csh, 4
	NOTE Csh, 4
	INSTR 5
	NOTE Fsh, 4
	INSTR 0
	NOTE Csh, 4
	NOTE Csh, 4
	INSTR 5
	LEN 16
	NOTE Fsh, 4
	INSTR 0
	LEN 8
	NOTE Csh, 4
	INSTR 5
	NOTE Fsh, 4
	INSTR 0
	NOTE Csh, 4
	NOTE Csh, 4
	INSTR 5
	NOTE Fsh, 4
	INSTR 0
	NOTE Csh, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	INSTR 4
	NOTE D_, 5
	INSTR 0
	NOTE Fsh, 4
	NOTE Fsh, 4
	INSTR 4
	NOTE D_, 5
	INSTR 0
	NOTE Fsh, 4
	NOTE Fsh, 4
	INSTR 4
	LEN 16
	NOTE E_, 5
	INSTR 0
	LEN 8
	NOTE Gsh, 4
	INSTR 4
	NOTE E_, 5
	INSTR 0
	NOTE Gsh, 4
	NOTE Gsh, 4
	INSTR 4
	NOTE E_, 5
	INSTR 0
	NOTE Gsh, 4
	NOTE Fsh, 2
	NOTE Fsh, 3
	INSTR 5
	NOTE Fsh, 4
	INSTR 0
	NOTE Fsh, 4
	NOTE Fsh, 3
	INSTR 4
	NOTE E_, 4
	INSTR 0
	NOTE E_, 4
	NOTE Fsh, 4
	INSTR 5
	LEN 16
	NOTE Fsh, 4
	INSTR 3
	LEN 8
	NOTE E_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE Fsh, 3
	NOTE E_, 3
	NEXT
Pat_605F:
	LEN 8
	AUTOPAN $08
	HWENV $34, $00
	DUTY_50
	REPEAT 4
	NOTE Fsh, 2
	NOTE Fsh, 3
	NOTE Fsh, 3
	NOTE Fsh, 4
	NOTE Fsh, 3
	NOTE Fsh, 3
	NOTE Fsh, 4
	NOTE Fsh, 3
	REPEAT_END
	NEXT
Pat_6071:
	DRUMS $08, DrumPat_615C
	INSTR 5
	LENGTH $70
	NOTE Fsh, 4
	LEN 16
	NOTE Fsh, 4
	ARP 8
	LENGTH $70
	NOTE Fsh, 4
	LEN 16
	NOTE Fsh, 4
	ARP 14
	LENGTH $70
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	ARP 15
	LENGTH $80
	NOTE Fsh, 4
	LENGTH $70
	NOTE Fsh, 4
	LEN 16
	NOTE Fsh, 4
	ARP 8
	LENGTH $70
	NOTE Fsh, 4
	LEN 16
	NOTE Fsh, 4
	ARP 14
	LENGTH $70
	NOTE E_, 4
	LEN 16
	ARP 13
	NOTE Gsh, 3
	ARP 12
	LENGTH $80
	NOTE A_, 3
	NEXT
Pat_60A2:
	DRUMS $08, DrumPat_6161
	VIBRATO $18, $02, $04
	HWENV $C1, $08, $60
	RELEASE $98, $63
	DUTY_50
	AUTODUTY $00
	ARP_OFF
	LENGTH $70
	NOTE Csh, 4
	LEN 8
	NOTE B_, 3
	NOTE Csh, 4
	LENGTH $70
	NOTE D_, 4
	LEN 16
	NOTE E_, 4
	LENGTH $70
	NOTE B_, 3
	LEN 8
	NOTE Csh, 4
	NOTE D_, 4
	LENGTH $40
	NOTE Csh, 4
	LENGTH $30
	NOTE B_, 3
	LEN 8
	NOTE A_, 3
	NOTE Gsh, 3
	NEXT
Pat_60D0:
	LENGTH $70
	NOTE A_, 3
	LEN 8
	NOTE Gsh, 3
	NOTE A_, 3
	LENGTH $40
	NOTE B_, 3
	LEN 32
	NOTE A_, 3
	NOTE B_, 3
	LENGTH $68
	NOTE Csh, 4
	LEN 8
	NOTE D_, 4
	NOTE Csh, 4
	NOTE B_, 3
	LENGTH $40
	NOTE Csh, 4
	DRUMS $08, DrumPat_616E
	LEN 24
	NOTE F_, 4
	NOTE Fsh, 4
	LEN 16
	NOTE Gsh, 4
	NEXT
Pat_60F0:
	DRUMS $08, DrumPat_6176
	HWENV $D1, $08, $80
	DUTY_75
	LEN 8
	NOTE Fsh, 3
	NOTE Fsh, 3
	LEN 16
	NOTE Csh, 5
	GLISS_2
	NOTE Fsh, 5
	LEN 8
	NOTE A_, 5
	LEN 24
	NOTE Gsh, 5
	LEN 32
	NOTE Fsh, 5
	GLISS_OFF
	LEN 16
	NOTE E_, 3
	LEN 8
	NOTE E_, 3
	NOTE Fsh, 3
	LEN 16
	NOTE Csh, 5
	GLISS_2
	NOTE Fsh, 5
	LEN 8
	NOTE A_, 5
	LEN 24
	NOTE Gsh, 5
	LEN 32
	NOTE Fsh, 5
	LEN 8
	NOTE Fsh, 5
	NOTE E_, 5
	LEN 24
	NOTE Fsh, 5
	NOTE E_, 5
	LEN 16
	NOTE D_, 5
	LEN 32
	NOTE A_, 4
	LEN 16
	NOTE B_, 4
	LENGTH $70
	NOTE Csh, 5
	LEN 16
	GLISS_OFF
	NOTE A_, 3
	NOTE Gsh, 3
	NEXT
Pat_612A:
	LEN 8
	NOTE Fsh, 3
	NOTE Fsh, 3
	LEN 16
	NOTE Csh, 5
	GLISS_2
	NOTE Fsh, 5
	LEN 8
	NOTE A_, 5
	LEN 24
	NOTE Gsh, 5
	LEN 32
	NOTE Fsh, 5
	GLISS_OFF
	LEN 16
	NOTE E_, 3
	LEN 8
	NOTE E_, 3
	NOTE Fsh, 3
	LEN 16
	NOTE Csh, 5
	GLISS_2
	NOTE Fsh, 5
	LEN 8
	NOTE A_, 5
	LEN 24
	NOTE Gsh, 5
	LEN 32
	NOTE Fsh, 5
	LEN 16
	NOTE E_, 5
	LEN 8
	NOTE E_, 5
	LEN 40
	NOTE Fsh, 5
	LEN 16
	NOTE Fsh, 5
	LEN 32
	NOTE A_, 5
	LEN 16
	NOTE B_, 5
	LEN 32
	NOTE A_, 5
	LEN 8
	NOTE Gsh, 5
	LENGTH $68
	NOTE Fsh, 5
	GLISS_OFF
	NEXT
DrumPat_615C:
	db 1, 0, 0, 0, DRUM_LOOP
DrumPat_6161:
	db DRUM_LEVEL + 15, 1, DRUM_LEVEL + 13, 6, 5, 6, DRUM_LEVEL + 15, 1
	db DRUM_LEVEL + 13, 6, 5, 6, DRUM_LOOP
DrumPat_616E:
	db 2, 2, 5, 2, 5, 2, 2, 2
DrumPat_6176:
	db 7, 0, 0, 6, 2, 6, 5, 1
	db 1, 6, 1, 6, 2, 6, 5, 6
	db 1, 6, 5, 6, 2, 6, 5, 1
	db 1, 6, 1, 6, 2, 6, 5, 6
	db 1, 6, 5, 6, 2, 6, 1, 6
	db 1, 6, 5, 6, 2, 6, 1, 6
	db 1, 6, 5, 1, 2, 6, 1, 6
	db 1, 6, 5, 6, 2, 2, 1, 6
	db DRUM_LOOP

; Instrument table 3, entries 1..6 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr3_0
	dw Instr3_1
	dw Instr3_2
	dw Instr3_3
	dw Instr3_4
	dw Instr3_5
Instr3_0:
	AUTODUTY $08
	HWENV $A1, $06, $20
	END
Instr3_1:
	VOLENV 15, $11, $1A, $11
	WAVE Wave_7815
	END
Instr3_2:
	WAVE Wave_7855
	VOLENV 15, $11, $1F, $12
	ARP 0
	END
Instr3_3:
	WAVE Wave_7855
	VOLENV 15, $11, $1F, $11
	ARP 0
	END
Instr3_4:
	HWENV $C2, $04, $40
	ARP 14
	AUTODUTY $02
	END
Instr3_5:
	HWENV $C1, $04, $40
	ARP 15
	AUTODUTY $02
	END

; Song 8: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong8:
	call StopAll
	ld a, $61
	ld [wInstrTableHi], a
	ld a, $B5
	ld [wInstrTable], a
	ld de, Song8_Ch3
	call StartMusicCh3
	ld de, Song8_Ch2
	call StartMusicCh2
	ld de, Song8_Ch1
	jp StartMusicCh1
Song8_Ch3:
	dw Pat_6219
Song8_Ch2:
	dw Pat_6242
Song8_Ch1:
	dw Pat_6275
Pat_6219:
	INSTR 2
	LEN 8
	NOTE Fsh, 2
	INSTR 3
	LEN 16
	NOTE Fsh, 2
	LEN 8
	NOTE Fsh, 2
	INSTR 1
	LEN 16
	NOTE Fsh, 4
	INSTR 3
	LEN 8
	NOTE Fsh, 2
	NOTE Fsh, 2
	INSTR 2
	LEN 16
	NOTE Fsh, 2
	NOTE Fsh, 2
	INSTR 1
	NOTE Fsh, 4
	INSTR 2
	NOTE E_, 2
	NOTE D_, 2
	LEN 8
	NOTE D_, 2
	NOTE E_, 2
	INSTR 1
	NOTE Fsh, 4
	INSTR 2
	NOTE E_, 2
	LEN 16
	NOTE E_, 2
	VOLENV 15, $11, $1F, $14
	LENGTH $40
	NOTE Fsh, 2
	END
Pat_6242:
	INSTR 0
	LEN 8
	NOTE Csh, 4
	NOTE Csh, 4
	INSTR 5
	NOTE Fsh, 4
	INSTR 0
	NOTE Csh, 4
	NOTE Csh, 4
	INSTR 5
	NOTE Fsh, 4
	INSTR 0
	NOTE Csh, 4
	NOTE Csh, 4
	INSTR 5
	LEN 16
	NOTE Fsh, 4
	INSTR 0
	LEN 8
	NOTE Csh, 4
	INSTR 5
	NOTE Fsh, 4
	INSTR 0
	NOTE Csh, 4
	NOTE Csh, 4
	INSTR 5
	NOTE Fsh, 4
	INSTR 0
	LEN 16
	NOTE Csh, 4
	LEN 8
	NOTE A_, 3
	INSTR 4
	NOTE D_, 5
	INSTR 0
	NOTE A_, 3
	NOTE B_, 3
	INSTR 4
	NOTE E_, 5
	INSTR 0
	NOTE B_, 3
	NOTE B_, 3
	INSTR 5
	LENGTH $40
	HWENV $C2, $04, $67
	NOTE Fsh, 5
	END
Pat_6275:
	DRUMS $08, DrumPat_62A0
	HWENV $F1, $08, $87
	DUTY_50
	VIBRATO $10, $02, $04
	ARP 9
	LEN 8
	NOTE Fsh, 3
	NOTE Fsh, 3
	LEN 16
	NOTE Csh, 4
	NOTE Fsh, 4
	LEN 8
	NOTE A_, 4
	LEN 24
	NOTE Gsh, 4
	LEN 32
	NOTE Fsh, 4
	LEN 16
	NOTE E_, 4
	LEN 8
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE E_, 4
	LEN 16
	NOTE Fsh, 4
	LEN 8
	NOTE Fsh, 4
	LEN 16
	NOTE E_, 4
	LENGTH $40
	NOTE Fsh, 4
	DRUMS_OFF
	END
DrumPat_62A0:
	db 1, 6, 5, 1, 2, 6, 5, 1           ; no DRUM_LOOP: the pattern runs into the next data
	db 6, 1, 6, 1, 2, 6, 1, 6
	db 2, 2, 2, 2, 5, 2, 2, 5
	db 7, 0, 0, 0, 0, 0, 0, 0

; Song 9: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong9:
	call StopAll
	ld a, $66
	ld [wInstrTableHi], a
	ld a, $7F
	ld [wInstrTable], a
	ld de, Song9_Ch3
	call StartMusicCh3
	ld de, Song9_Ch2
	call StartMusicCh2
	ld de, Song9_Ch1
	jp StartMusicCh1
Song9_Ch3:
	dw Pat_6317
	dw Pat_632C
	dw Pat_6336
	dw Pat_6349
	dw Pat_6385
	dw Pat_63C6
	dw Pat_6405
	ORDER_LOOP Song9_Ch3
Song9_Ch2:
	dw Pat_643F
	dw Pat_6454
	dw Pat_645C
	dw Pat_647C
	dw Pat_649D
	ORDER_LOOP Song9_Ch2
Song9_Ch1:
	dw Pat_6516
	ORDER_LOOP Song9_Ch1
Pat_6305:
	ARP 0
	LEN 8
	NOTE Ash, 3
	NOTE Ash, 2
	NOTE Ash, 2
	LEN 16
	NOTE Gsh, 2
	NOTE Ash, 2
	LEN 8
	NOTE Ash, 2
	NOTE Ash, 2
	ARP 7
	LEN 16
	NOTE B_, 2
	ARP 0
	LEN 8
	NOTE Ash, 2
	NEXT
Pat_6317:
	VIBRATO $08, $08, $04
	VOLENV 14, $00, $15, $12
	ARP 0
	RELEASE $02, $11
	WAVE_SEQ WaveSeq_7083
	REPEAT 4
	PAT_CALL Pat_6305
	REPEAT_END
	NEXT
Pat_632C:
	REPEAT 4
	CH_TRANSPOSE $03
	PAT_CALL Pat_6305
	CH_TRANSPOSE $00
	REPEAT_END
	NEXT
Pat_6336:
	REPEAT 2
	CH_TRANSPOSE $08
	PAT_CALL Pat_6305
	CH_TRANSPOSE $00
	REPEAT_END
	REPEAT 2
	CH_TRANSPOSE $03
	PAT_CALL Pat_6305
	CH_TRANSPOSE $00
	REPEAT_END
	NEXT
Pat_6349:
	ARP 0
	LEN 8
	NOTE E_, 4
	NOTE E_, 3
	NOTE E_, 3
	LEN 16
	NOTE D_, 3
	NOTE E_, 3
	LEN 8
	NOTE E_, 3
	NOTE E_, 3
	ARP 7
	LEN 16
	NOTE F_, 3
	ARP 0
	LEN 8
	NOTE E_, 3
	NOTE E_, 4
	NOTE E_, 3
	NOTE E_, 3
	LEN 16
	NOTE D_, 3
	NOTE E_, 3
	LEN 8
	NOTE E_, 3
	NOTE E_, 3
	ARP 7
	LEN 16
	NOTE F_, 3
	ARP 0
	LEN 8
	NOTE E_, 3
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 2
	LEN 16
	NOTE Fsh, 2
	NOTE Gsh, 2
	LEN 8
	NOTE Gsh, 2
	NOTE Gsh, 2
	ARP 7
	LEN 16
	NOTE Ash, 2
	ARP 0
	LEN 8
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 2
	LEN 16
	NOTE Fsh, 2
	NOTE Gsh, 2
	LEN 8
	NOTE Gsh, 3
	NOTE Fsh, 3
	NOTE E_, 3
	NOTE Dsh, 3
	NOTE B_, 2
	NEXT
Pat_6385:
	ARP 0
	LEN 16
	NOTE Csh, 3
	NOTE Csh, 3
	LEN 8
	NOTE C_, 3
	NOTE Csh, 3
	ARP 7
	LEN 16
	NOTE B_, 2
	ARP 0
	NOTE Csh, 3
	LEN 8
	NOTE C_, 3
	NOTE Csh, 3
	ARP 7
	LEN 16
	NOTE B_, 2
	ARP 0
	NOTE Csh, 3
	LEN 8
	NOTE C_, 3
	NOTE Csh, 3
	ARP 7
	LEN 16
	NOTE B_, 2
	ARP 0
	LEN 8
	NOTE Csh, 3
	NOTE Csh, 4
	NOTE Csh, 3
	NOTE D_, 3
	REPEAT 2
	LEN 16
	NOTE Dsh, 3
	LEN 8
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Dsh, 3
	NOTE Dsh, 3
	LEN 16
	NOTE Csh, 3
	LEN 8
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Dsh, 3
	NOTE Dsh, 3
	ARP 7
	LEN 16
	NOTE E_, 3
	ARP 0
	LEN 8
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Dsh, 3
	LEN 16
	NOTE Dsh, 3
	LEN 8
	NOTE Dsh, 3
	NOTE Csh, 3
	NOTE Gsh, 2
	NOTE Ash, 2
	NOTE Csh, 3
	REPEAT_END
	NEXT
Pat_63C6:
	ARP 0
	LEN 16
	NOTE Dsh, 3
	LEN 8
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Dsh, 3
	NOTE Dsh, 3
	LEN 16
	NOTE Csh, 3
	LEN 8
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Dsh, 3
	NOTE Dsh, 3
	ARP 7
	LEN 16
	NOTE E_, 3
	ARP 0
	LEN 8
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Dsh, 3
	NOTE Dsh, 3
	LEN 16
	NOTE Csh, 3
	LEN 8
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Dsh, 3
	NOTE Dsh, 3
	ARP 7
	LEN 16
	NOTE E_, 3
	ARP 0
	LEN 8
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Dsh, 3
	NOTE Dsh, 3
	LEN 16
	NOTE Csh, 3
	LEN 8
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Dsh, 3
	NOTE Dsh, 3
	ARP 7
	LEN 16
	NOTE E_, 3
	ARP 0
	LEN 8
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Dsh, 3
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	NEXT
Pat_6405:
	ARP 0
	LEN 16
	NOTE Dsh, 3
	LEN 8
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Dsh, 3
	NOTE Dsh, 3
	LEN 16
	NOTE Csh, 3
	LEN 8
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Dsh, 3
	NOTE Dsh, 3
	LEN 16
	NOTE Fsh, 3
	LEN 8
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Dsh, 3
	NOTE Dsh, 3
	LEN 16
	NOTE Csh, 3
	LEN 8
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Dsh, 3
	NOTE Dsh, 3
	LEN 16
	NOTE Fsh, 3
	LEN 8
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Dsh, 3
	NOTE Dsh, 3
	LEN 16
	NOTE Csh, 3
	LEN 8
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Dsh, 3
	NOTE Dsh, 3
	LEN 16
	NOTE Fsh, 3
	LEN 8
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Dsh, 3
	LEN 16
	NOTE Dsh, 3
	LEN 8
	NOTE Dsh, 3
	NOTE Csh, 3
	NOTE Gsh, 2
	NOTE Ash, 2
	NOTE Csh, 3
	NEXT
Pat_643F:
	LEN 8
	REPEAT 4
	INSTR 2
	NOTE Ash, 4
	INSTR 0
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE C_, 5
	NOTE Csh, 5
	NOTE Ash, 4
	INSTR 2
	LEN 16
	NOTE Ash, 4
	INSTR 0
	LEN 8
	NOTE Ash, 3
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	REPEAT_END
	NEXT
Pat_6454:
	CH_TRANSPOSE $03
	PAT_CALL Pat_643F
	CH_TRANSPOSE $00
	NEXT
Pat_645C:
	LEN 8
	REPEAT 2
	INSTR 0
	NOTE Fsh, 5
	NOTE E_, 5
	NOTE Csh, 5
	NOTE E_, 5
	NOTE Fsh, 5
	LEN 16
	NOTE Csh, 5
	INSTR 2
	NOTE Fsh, 4
	NOTE Fsh, 4
	LEN 8
	NOTE Fsh, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE Csh, 5
	NOTE B_, 4
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE Csh, 5
	LEN 16
	NOTE Gsh, 4
	INSTR 2
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 8
	NOTE Csh, 4
	REPEAT_END
	NEXT
Pat_647C:
	REPEAT 2
	INSTR 0
	LEN 8
	NOTE E_, 5
	NOTE D_, 5
	NOTE B_, 4
	NOTE D_, 5
	NOTE E_, 5
	LEN 16
	NOTE B_, 4
	INSTR 2
	NOTE E_, 4
	NOTE E_, 4
	LEN 8
	NOTE E_, 4
	REPEAT_END
	INSTR 0
	REPEAT 3
	NOTE Gsh, 5
	NOTE Fsh, 5
	NOTE Dsh, 5
	REPEAT_END
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE Fsh, 5
	LEN 16
	NOTE Gsh, 5
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE Fsh, 5
	NOTE E_, 5
	NOTE Dsh, 5
	NEXT
Pat_649D:
	INSTR 2
	LEN 16
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 8
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 16
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 8
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 16
	NOTE Csh, 5
	NOTE Csh, 5
	LEN 8
	NOTE Csh, 5
	NOTE Csh, 5
	LEN 16
	NOTE Csh, 5
	LEN 8
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Csh, 4
	NOTE D_, 4
	REPEAT 2
	LEN 16
	NOTE Dsh, 4
	INSTR 0
	LEN 8
	NOTE Dsh, 4
	INSTR 2
	NOTE Dsh, 4
	INSTR 0
	NOTE Dsh, 4
	NOTE Dsh, 4
	INSTR 2
	LEN 16
	NOTE Dsh, 4
	INSTR 0
	LEN 8
	NOTE Dsh, 4
	INSTR 2
	NOTE Dsh, 4
	INSTR 0
	NOTE Dsh, 4
	NOTE Dsh, 4
	INSTR 1
	LEN 16
	NOTE Fsh, 4
	INSTR 0
	LEN 8
	NOTE Dsh, 4
	INSTR 1
	NOTE Fsh, 4
	INSTR 0
	NOTE Dsh, 4
	NOTE Dsh, 4
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE Dsh, 4
	NOTE Csh, 4
	INSTR 1
	NOTE E_, 4
	INSTR 0
	NOTE Ash, 3
	NOTE Csh, 4
	REPEAT_END
	REPEAT 4
	INSTR 2
	LEN 8
	NOTE Dsh, 4
	INSTR 6
	LEN 16
	NOTE Ash, 3
	INSTR 2
	LEN 8
	NOTE Dsh, 4
	INSTR 6
	LEN 16
	NOTE Ash, 3
	INSTR 2
	LEN 8
	NOTE Dsh, 4
	INSTR 6
	LEN 16
	NOTE Ash, 3
	INSTR 2
	LEN 8
	NOTE Dsh, 4
	INSTR 6
	LEN 16
	NOTE Ash, 3
	INSTR 1
	LEN 8
	NOTE Fsh, 4
	INSTR 6
	LEN 16
	NOTE Csh, 4
	INSTR 1
	LEN 8
	NOTE Fsh, 4
	INSTR 6
	LEN 16
	NOTE Csh, 4
	INSTR 1
	LEN 8
	NOTE F_, 4
	INSTR 6
	LEN 16
	NOTE C_, 4
	INSTR 1
	LEN 8
	NOTE E_, 4
	INSTR 6
	LEN 16
	NOTE B_, 3
	REPEAT_END
	NEXT
Pat_6516:
	DRUMS $08, DrumPat_6645
	RELEASE $92, $20
	VIBRATO $18, $04, $05
	INSTR 3
	LEN 1
	NOTE Dsh, 3
	LENGTH $5F
	NOTE Ash, 3
	LENGTH $60
	NOTE Csh, 4
	LENGTH $A0
	NOTE F_, 4
	LEN 32
	WAIT
	LENGTH $60
	NOTE Csh, 4
	LENGTH $50
	NOTE E_, 4
	LEN 8
	NOTE Dsh, 4
	NOTE E_, 4
	LENGTH $A0
	NOTE Gsh, 4
	LEN 32
	WAIT
	LEN 8
	REPEAT 2
	INSTR 0
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE Fsh, 4
	INSTR 4
	NOTE Fsh, 3
	NOTE Csh, 4
	NOTE Fsh, 3
	NOTE E_, 4
	NOTE Fsh, 3
	NOTE Fsh, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE Csh, 4
	INSTR 4
	NOTE Csh, 3
	NOTE Gsh, 3
	NOTE Csh, 3
	NOTE B_, 3
	NOTE Csh, 3
	NOTE Csh, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE E_, 4
	INSTR 4
	NOTE E_, 3
	NOTE B_, 3
	NOTE E_, 3
	NOTE D_, 4
	NOTE E_, 3
	NOTE E_, 4
	REPEAT_END
	HWENV $70, $08, $67
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE Fsh, 4
	LEN 16
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE Dsh, 4
	HWENV $A2, $00
	ARP 9
	DUTY_75
	DRUMS $08, DrumPat_6637
	LEN 16
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 8
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 16
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 8
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 16
	NOTE E_, 4
	NOTE E_, 4
	LEN 8
	NOTE E_, 4
	NOTE E_, 4
	LEN 16
	NOTE Gsh, 4
	LEN 8
	NOTE Gsh, 4
	NOTE Csh, 5
	ARP 0
	DUTY_50
	HWENV $A3, $00
	GLISS_OFF
	CH_TRANSPOSE $F4
	NOTE Csh, 3
	NOTE D_, 3
	DRUMS $08, DrumPat_6645
	REPEAT 2
	LEN 16
	NOTE Dsh, 3
	NOTE Dsh, 3
	LEN 8
	NOTE Dsh, 3
	NOTE Dsh, 3
	LEN 16
	ARP 7
	NOTE B_, 2
	ARP 0
	NOTE Dsh, 3
	LEN 8
	NOTE Dsh, 3
	NOTE Dsh, 3
	LEN 16
	NOTE Fsh, 3
	NOTE Dsh, 3
	LEN 8
	NOTE Dsh, 3
	LEN 16
	NOTE Dsh, 3
	LEN 8
	NOTE Dsh, 3
	NOTE Csh, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE Csh, 4
	REPEAT_END
	CH_TRANSPOSE $00
	INSTR 5
	LEN 8
	NOTE Ash, 3
	NOTE Dsh, 4
	NOTE Csh, 4
	LEN 16
	NOTE Dsh, 4
	NOTE Csh, 4
	LEN 8
	NOTE Ash, 4
	NOTE Gsh, 4
	LEN 16
	NOTE Ash, 4
	LEN 8
	NOTE Gsh, 4
	LEN 16
	NOTE Csh, 5
	NOTE Ash, 4
	NOTE Csh, 5
	LEN 8
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	LEN 16
	NOTE Ash, 4
	GLISS_OFF
	HWENV $F1, $00
	DUTY_12
	ARP 9
	LEN 8
	NOTE Dsh, 3
	NOTE Dsh, 3
	LEN 16
	NOTE Csh, 3
	NOTE Dsh, 3
	INSTR 5
	LEN 8
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 16
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	LEN 8
	NOTE A_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE E_, 4
	NOTE Gsh, 4
	LEN 16
	NOTE Fsh, 4
	NOTE Dsh, 4
	GLISS_OFF
	HWENV $F1, $04, $62
	DUTY_12
	ARP 1
	LEN 8
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 16
	NOTE Csh, 4
	NOTE Dsh, 4
	INSTR 5
	GLISS_OFF
	LEN 8
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE Ash, 4
	NOTE Csh, 5
	NOTE Fsh, 4
	NOTE Ash, 4
	NOTE Csh, 5
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Dsh, 5
	ARP 20
	NOTE Csh, 5
	ARP_OFF
	NOTE Csh, 5
	LENGTH $98
	NOTE Dsh, 5
	LENGTH $18
	WAIT
	NEXT
DrumPat_6637:
	db DRUM_REPEAT + 3, 2, 0, 2, 0, 2, 2, DRUM_REPEAT_END
	db 2, 0, 2, 2, 2, 2
DrumPat_6645:
	db DRUM_LEVEL + 15, 7, 0, 0, 2, DRUM_LEVEL + 13, 5, 6
	db DRUM_LEVEL + 15, 1, DRUM_LEVEL + 13, 6, 1, DRUM_LEVEL + 15, 2, DRUM_LEVEL + 13
	db 5, 6, DRUM_REPEAT + 2, DRUM_LEVEL + 15, 1, DRUM_LEVEL + 13, 6, 6
	db DRUM_LEVEL + 15, 2, DRUM_LEVEL + 13, 5, 6, DRUM_LEVEL + 15, 1, DRUM_LEVEL + 13
	db 6, 1, DRUM_LEVEL + 15, 2, DRUM_LEVEL + 13, 5, 6, DRUM_REPEAT_END
	db DRUM_LEVEL + 15, 1, DRUM_LEVEL + 13, 6, 6, DRUM_LEVEL + 15, 2, DRUM_LEVEL + 13
	db 5, 6, DRUM_LEVEL + 15, 1, DRUM_LEVEL + 13, 6, 1, DRUM_LEVEL + 15
	db 2, 2, 2, DRUM_LOOP

; Instrument table 4, entries 1..7 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr4_0
	dw Instr4_1
	dw Instr4_2
	dw Instr4_3
	dw Instr4_4
	dw Instr4_5
	dw Instr4_6
Instr4_0:
	HWENV $91, $05, $53
	ARP 6
	GLISS_OFF
	END
Instr4_1:
	HWENV $C1, $04, $40
	ARP 14
	AUTODUTY $02
	END
Instr4_2:
	HWENV $C1, $04, $40
	ARP 15
	AUTODUTY $02
	END
Instr4_3:
	HWENV $97, $10, $70
	GLISS_1
	END
Instr4_4:
	HWENV $97, $10, $70
	GLISS_3
	END
Instr4_5:
	HWENV $D1, $02, $80
	GLISS_3
	END
Instr4_6:
	HWENV $50, $00
	DUTY_75
	ARP 1
	END

; Song 10: instrument table 5, arpeggio table 1 (the one SndInit sets)
PlaySong10:
	call StopAll
	ld a, $68
	ld [wInstrTableHi], a
	ld a, $E6
	ld [wInstrTable], a
	ld de, Song10_Ch3
	call StartMusicCh3
	ld de, Song10_Ch2
	call StartMusicCh2
	ld de, Song10_Ch1
	jp StartMusicCh1
Song10_Ch3:
	dw Pat_6707
	dw Pat_6745
	dw Pat_6745
	dw Pat_677E
	dw Pat_677E
	ORDER_LOOP Song10_Ch3
Song10_Ch2:
	dw Pat_67B8
	dw Pat_67EB
	dw Pat_67EB
	dw Pat_681E
	dw Pat_681E
	ORDER_LOOP Song10_Ch2
Song10_Ch1:
	dw Pat_6854
	dw Pat_687F
	dw Pat_687F
	dw Pat_68AA
	dw Pat_68AA
	ORDER_LOOP Song10_Ch1
Pat_6707:
	CH_TRANSPOSE $0C
	TRANSPOSE $FF
	INSTR 12
	LEN 16
	NOTE Gsh, 2
	LEN 8
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 2
	LEN 16
	NOTE Gsh, 2
	LEN 8
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 2
	LEN 16
	NOTE Gsh, 2
	LEN 8
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 2
	LEN 16
	NOTE Gsh, 2
	LEN 8
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 2
	LEN 16
	NOTE Gsh, 2
	LEN 8
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 2
	LEN 16
	NOTE Gsh, 2
	LEN 8
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 2
	LEN 16
	NOTE Gsh, 2
	LEN 8
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 2
	LEN 16
	NOTE Gsh, 2
	LEN 8
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 2
	NEXT
Pat_6745:
	INSTR 12
	LEN 16
	NOTE Gsh, 2
	LEN 8
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 2
	LEN 16
	NOTE Gsh, 2
	LEN 8
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 2
	LEN 16
	NOTE E_, 2
	LEN 8
	NOTE E_, 2
	NOTE E_, 3
	NOTE E_, 2
	NOTE E_, 2
	LEN 16
	NOTE E_, 2
	LEN 8
	NOTE E_, 2
	NOTE E_, 3
	NOTE E_, 2
	NOTE E_, 2
	LEN 16
	NOTE Csh, 2
	LEN 8
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE Csh, 2
	NOTE Csh, 2
	LEN 16
	NOTE Csh, 2
	LEN 8
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE Csh, 2
	NOTE Csh, 2
	LEN 16
	NOTE E_, 2
	LEN 8
	NOTE E_, 2
	NOTE E_, 3
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE B_, 2
	NOTE Ash, 2
	NOTE Gsh, 2
	NOTE Ash, 2
	NOTE B_, 2
	NEXT
Pat_677E:
	INSTR 12
	LEN 16
	NOTE Gsh, 2
	LEN 8
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 2
	LEN 16
	NOTE Gsh, 2
	LEN 8
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 2
	LEN 16
	NOTE E_, 2
	LEN 8
	NOTE E_, 2
	NOTE E_, 3
	NOTE E_, 2
	NOTE E_, 2
	LEN 16
	NOTE Dsh, 2
	LEN 8
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 2
	LEN 16
	NOTE Gsh, 2
	LEN 8
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 2
	LEN 16
	NOTE Gsh, 2
	LEN 8
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 2
	LEN 16
	NOTE Csh, 2
	LEN 8
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE Csh, 2
	NOTE Csh, 2
	LEN 16
	NOTE Dsh, 2
	LEN 8
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 2
	NEXT
Pat_67B8:
	INSTR 9
	LEN 8
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NEXT
Pat_67EB:
	INSTR 9
	LEN 8
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE B_, 3
	NOTE E_, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE E_, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE E_, 4
	NOTE B_, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE B_, 3
	NOTE F_, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE F_, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE F_, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE E_, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE E_, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE E_, 4
	NOTE B_, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE B_, 3
	NEXT
Pat_681E:
	INSTR 9
	LEN 16
	NOTE B_, 3
	LEN 8
	NOTE B_, 3
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 16
	NOTE Dsh, 4
	LEN 8
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE Dsh, 3
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 3
	NOTE Gsh, 4
	NOTE Gsh, 3
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE G_, 3
	NOTE G_, 4
	LEN 16
	NOTE B_, 3
	LEN 8
	NOTE B_, 3
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 16
	NOTE Dsh, 4
	LEN 8
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE B_, 3
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 3
	NOTE Gsh, 4
	NOTE Gsh, 3
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 3
	NOTE Ash, 4
	NOTE Ash, 3
	NOTE Ash, 4
	NEXT
Pat_6854:
	DRUMS $08, DrumPat_68E1
	VIBRATO $10, $02, $05
	INSTR 15
	LENGTH $48
	NOTE Dsh, 4
	LEN 8
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	LENGTH $48
	NOTE Dsh, 4
	LEN 8
	NOTE Csh, 4
	NOTE B_, 3
	NOTE Csh, 4
	LENGTH $48
	NOTE Dsh, 4
	LEN 8
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	LEN 32
	NOTE Dsh, 4
	LEN 8
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE Ash, 4
	NOTE B_, 4
	NOTE Csh, 5
	LEN 16
	NOTE E_, 5
	LEN 8
	NOTE Dsh, 5
	NEXT
Pat_687F:
	INSTR 13
	LEN 8
	NOTE B_, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE B_, 4
	LENGTH $38
	NOTE Dsh, 4
	LEN 8
	NOTE B_, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE B_, 4
	LENGTH $38
	NOTE E_, 4
	LEN 8
	NOTE B_, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE B_, 4
	LENGTH $38
	NOTE F_, 4
	LEN 8
	NOTE B_, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE B_, 4
	LEN 16
	NOTE Dsh, 5
	LEN 8
	NOTE Dsh, 4
	NOTE Csh, 5
	NOTE B_, 4
	NOTE Ash, 4
	NOTE Fsh, 4
	NEXT
Pat_68AA:
	INSTR 14
	LEN 8
	NOTE Gsh, 4
	WAIT2
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Ash, 4
	LEN 16
	NOTE B_, 4
	LEN 8
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE B_, 4
	NOTE Gsh, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE Csh, 4
	NOTE Dsh, 5
	WAIT2
	NOTE Csh, 5
	WAIT2
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE Csh, 5
	WAIT2
	NOTE B_, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	WAIT2
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Ash, 4
	LEN 16
	NOTE B_, 4
	LEN 8
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE B_, 4
	NOTE Csh, 5
	NOTE Dsh, 5
	LEN 16
	NOTE Fsh, 5
	LEN 8
	NOTE E_, 5
	WAIT2
	NOTE Csh, 5
	NOTE Gsh, 4
	LEN 16
	NOTE E_, 5
	LEN 8
	NOTE Dsh, 5
	WAIT2
	NOTE Ash, 4
	NOTE G_, 4
	NEXT
DrumPat_68E1:
	db 1, 6, 5, 2, 5, 6, DRUM_LOOP

; Instrument table 5, entries 1..16 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr5_0
	dw Instr5_1
	dw Instr5_2
	dw Instr5_3
	dw Instr5_4
	dw Instr5_5
	dw Instr5_6
	dw Instr5_7
	dw Instr5_8
	dw Instr5_9
	dw Instr5_10
	dw Instr5_11
	dw Instr5_12
	dw Instr5_13
	dw Instr5_14
	dw Instr5_15

; Unreferenced (8 bytes)
	db $9A, $69, $83, $69, $91, $69, $89, $69
Instr5_0:
	HWENV $C1, $03, $63
	ARP 6
	DUTY_12
	END
Instr5_1:
	HWENV $C1, $00
	ARP 8
	DUTY_12
	PAN_L
	AUTOPAN $03
	END
Instr5_2:
	HWENV $F1, $08, $00
	GLIDE $FE
	DUTY_75
	END
Instr5_3:
	HWENV $C1, $04, $10
	ARP 0
	PINGPONG
	END
Instr5_4:
	HWENV $C2, $04, $40
	ARP 4
	AUTODUTY $02
	END
Instr5_5:
	HWENV $C1, $04, $40
	ARP 5
	AUTODUTY $02
	END
Instr5_6:
	HWENV $C2, $06, $50
	DUTY_75
	ARP 0
	END
Instr5_7:
	HWENV $81, $04, $42
	DUTY_12
	END
Instr5_8:
	HWENV $70, $01, $31
	END
Instr5_9:
	HWENV $A1, $05, $53
	ARP 6
	DUTY_75
	END
Instr5_10:
	HWENV $A1, $00
	DUTY_75
	ARP 0
	END
Instr5_11:
	HWENV $C1, $02, $51
	ARP 0
	DUTY_12
	END
Instr5_12:
	WAVE Wave_78A5
	VOLENV 13, $11, $1F, $12
	ARP_OFF
	RELEASE $02, $11
	END
Instr5_13:
	HWENV $C1, $08, $80
	RELEASE $98, $63
	END
Instr5_14:
	HWENV $C1, $08, $60
	END
Instr5_15:
	HWENV $50, $00
	DUTY_75
	END

; Unreferenced (33 bytes)
	db $75, $C1, $08, $60, $A1, $68, $C7, $11, $1F, $11, $7A, $15, $78, $68, $7A, $95
	db $78, $C7, $11, $1A, $13, $A0, $68, $75, $F1, $04, $50, $A1, $72, $6F, $03, $A0
	db $68

; Song 1: instrument table 6, arpeggio table 1 (the one SndInit sets)
PlaySong1:
	call StopAll
	ld a, $6C
	ld [wInstrTableHi], a
	ld a, $D1
	ld [wInstrTable], a
	ld de, Song1_Ch3
	call StartMusicCh3
	ld de, Song1_Ch2
	call StartMusicCh2
	ld de, Song1_Ch1
	jp StartMusicCh1
Song1_Ch3:
	dw Pat_69F9
Loop_69C5:
	dw Pat_6A1D
	dw Pat_6A1D
	dw Pat_6A1D
	dw Pat_6A1D
	dw Pat_6A5B
	dw Pat_6A99
	ORDER_LOOP Loop_69C5
Song1_Ch2:
	dw Pat_6AD3
Loop_69D7:
	dw Pat_6AEF
	dw Pat_6AEF
	dw Pat_6AEF
	dw Pat_6AEF
	dw Pat_6B31
	dw Pat_6B73
	ORDER_LOOP Loop_69D7
Song1_Ch1:
	dw Pat_6BB0
Loop_69E9:
	dw Pat_6BC8
	dw Pat_6BC8
	dw Pat_6BC8
	dw Pat_6BC8
	dw Pat_6BED
	dw Pat_6C34
	ORDER_LOOP Loop_69E9
Pat_69F9:
	WAVE Wave_6F8F
	CH_TRANSPOSE $0C
	VIBRATO $00, $02, $02
	INSTR 11
	LEN 10
	NOTE E_, 2
	INSTR 12
	NOTE E_, 2
	NOTE E_, 2
	INSTR 11
	NOTE E_, 2
	INSTR 12
	NOTE E_, 2
	NOTE E_, 2
	INSTR 11
	NOTE D_, 2
	NOTE E_, 2
	INSTR 12
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 3
	INSTR 11
	NOTE G_, 2
	INSTR 12
	NOTE G_, 2
	INSTR 11
	NOTE G_, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	NEXT
Pat_6A1D:
	INSTR 11
	LEN 10
	NOTE A_, 2
	INSTR 12
	NOTE A_, 3
	INSTR 11
	NOTE A_, 2
	INSTR 12
	NOTE A_, 3
	INSTR 11
	NOTE A_, 2
	INSTR 12
	NOTE A_, 3
	INSTR 11
	NOTE A_, 2
	NOTE Ash, 2
	INSTR 12
	NOTE Ash, 3
	INSTR 11
	NOTE Ash, 2
	INSTR 12
	NOTE Ash, 3
	INSTR 11
	NOTE F_, 2
	INSTR 12
	NOTE F_, 3
	INSTR 11
	NOTE F_, 2
	NOTE E_, 2
	INSTR 12
	NOTE E_, 3
	INSTR 11
	NOTE A_, 2
	INSTR 12
	NOTE A_, 3
	INSTR 11
	NOTE A_, 2
	INSTR 12
	NOTE A_, 3
	INSTR 11
	NOTE A_, 2
	INSTR 12
	NOTE A_, 3
	INSTR 11
	NOTE A_, 2
	NOTE Ash, 2
	INSTR 12
	NOTE Ash, 3
	INSTR 11
	NOTE Ash, 2
	INSTR 12
	NOTE Ash, 3
	INSTR 11
	NOTE E_, 2
	NOTE F_, 2
	INSTR 12
	NOTE F_, 3
	INSTR 11
	NOTE E_, 2
	INSTR 12
	NOTE E_, 3
	NEXT
Pat_6A5B:
	INSTR 11
	LEN 10
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 11
	NOTE D_, 2
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 3
	INSTR 11
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 3
	INSTR 11
	NOTE Ash, 2
	INSTR 12
	NOTE Ash, 3
	INSTR 11
	NOTE Ash, 2
	NOTE Ash, 2
	INSTR 12
	NOTE Ash, 3
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 11
	NOTE D_, 2
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 3
	INSTR 11
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 3
	INSTR 11
	NOTE A_, 2
	NOTE Ash, 2
	INSTR 12
	NOTE Ash, 3
	INSTR 11
	NOTE A_, 2
	INSTR 12
	NOTE A_, 3
	NEXT
Pat_6A99:
	INSTR 11
	LEN 10
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 11
	NOTE D_, 2
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 3
	INSTR 11
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 3
	INSTR 11
	NOTE Ash, 2
	INSTR 12
	NOTE Ash, 3
	INSTR 11
	NOTE Ash, 2
	NOTE Ash, 2
	INSTR 12
	NOTE Ash, 3
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 11
	NOTE D_, 2
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 3
	INSTR 11
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 3
	INSTR 11
	NOTE Dsh, 2
	LEN 20
	NOTE G_, 2
	NOTE Gsh, 2
	NEXT
Pat_6AD3:
	INSTR 2
	LEN 10
	NOTE A_, 3
	INSTR 9
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	INSTR 2
	NOTE A_, 3
	INSTR 9
	NOTE E_, 3
	NOTE D_, 3
	NOTE E_, 3
	INSTR 2
	NOTE A_, 3
	INSTR 9
	NOTE E_, 3
	NOTE E_, 3
	NOTE G_, 3
	INSTR 2
	NOTE A_, 3
	INSTR 9
	NOTE G_, 3
	INSTR 2
	NOTE A_, 3
	INSTR 9
	NOTE Gsh, 3
	NEXT
Pat_6AEF:
	INSTR 2
	LEN 10
	NOTE A_, 3
	INSTR 5
	NOTE A_, 3
	INSTR 2
	NOTE A_, 3
	INSTR 5
	NOTE A_, 3
	INSTR 2
	NOTE A_, 3
	INSTR 5
	NOTE A_, 3
	INSTR 2
	NOTE A_, 3
	INSTR 4
	NOTE Ash, 3
	INSTR 2
	NOTE A_, 3
	INSTR 5
	NOTE A_, 4
	INSTR 2
	NOTE A_, 3
	INSTR 5
	NOTE A_, 4
	INSTR 2
	NOTE A_, 3
	INSTR 5
	NOTE A_, 4
	INSTR 2
	NOTE A_, 3
	INSTR 5
	NOTE A_, 4
	INSTR 2
	NOTE A_, 3
	INSTR 5
	NOTE A_, 3
	INSTR 2
	NOTE A_, 3
	INSTR 5
	NOTE A_, 3
	INSTR 2
	NOTE A_, 3
	INSTR 5
	NOTE A_, 3
	INSTR 2
	NOTE A_, 3
	INSTR 4
	NOTE Ash, 3
	INSTR 2
	NOTE A_, 3
	INSTR 4
	NOTE Ash, 4
	INSTR 2
	NOTE A_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 2
	NOTE A_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 2
	NOTE A_, 3
	INSTR 4
	NOTE E_, 4
	NEXT
Pat_6B31:
	INSTR 2
	LEN 10
	NOTE A_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 2
	NOTE A_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 2
	NOTE A_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 2
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 2
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 2
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 5
	INSTR 2
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 5
	INSTR 2
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 5
	INSTR 2
	NOTE A_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 2
	NOTE A_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 2
	NOTE A_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 2
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 2
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 2
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 5
	INSTR 2
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 5
	INSTR 2
	NOTE A_, 3
	INSTR 5
	NOTE D_, 5
	NEXT
Pat_6B73:
	INSTR 2
	LEN 10
	NOTE A_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 2
	NOTE A_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 2
	NOTE A_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 2
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 2
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 2
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 5
	INSTR 2
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 5
	INSTR 2
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 5
	INSTR 2
	NOTE A_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 2
	NOTE A_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 2
	NOTE A_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 2
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 2
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 2
	NOTE A_, 3
	NOTE A_, 3
	INSTR 5
	LEN 20
	NOTE G_, 3
	NOTE Gsh, 3
	NEXT
Pat_6BB0:
	RELEASE $B2, $20
	VIBRATO $0A, $02, $05
	INSTR 16
	LEN 30
	NOTE E_, 2
	NOTE E_, 2
	LEN 10
	NOTE D_, 2
	LEN 30
	NOTE E_, 2
	LEN 10
	NOTE E_, 3
	LEN 20
	NOTE G_, 2
	LEN 10
	NOTE G_, 2
	LEN 20
	NOTE Gsh, 2
	NEXT
Pat_6BC8:
	DRUMS $05, DrumPat_6C96
	INSTR 16
	LEN 10
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	LEN 20
	NOTE C_, 4
	NOTE B_, 3
	LEN 40
	NOTE Ash, 3
	LEN 20
	NOTE F_, 3
	LEN 10
	NOTE F_, 3
	NOTE E_, 3
	NOTE E_, 3
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE C_, 5
	NOTE B_, 4
	LEN 40
	NOTE Ash, 4
	LEN 10
	NOTE E_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE E_, 2
	NEXT
Pat_6BED:
	DRUMS $05, DrumPat_6CB1
	INSTR 9
	LEN 5
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NEXT
Pat_6C34:
	INSTR 16
	LEN 5
	NOTE D_, 4
	INSTR 9
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	INSTR 16
	NOTE D_, 4
	INSTR 9
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	INSTR 16
	NOTE D_, 4
	INSTR 9
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	INSTR 16
	NOTE D_, 4
	INSTR 9
	NOTE F_, 4
	INSTR 16
	NOTE Dsh, 4
	INSTR 9
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	INSTR 16
	NOTE Dsh, 4
	INSTR 9
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	INSTR 16
	NOTE Ash, 4
	INSTR 9
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	INSTR 16
	NOTE Ash, 4
	INSTR 9
	NOTE G_, 4
	INSTR 16
	NOTE Ash, 4
	INSTR 9
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	INSTR 16
	NOTE D_, 4
	INSTR 9
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	INSTR 16
	NOTE D_, 4
	INSTR 9
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	INSTR 16
	NOTE D_, 4
	INSTR 9
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	INSTR 16
	NOTE D_, 4
	INSTR 9
	NOTE F_, 4
	INSTR 16
	NOTE Dsh, 4
	INSTR 9
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	INSTR 16
	NOTE Dsh, 4
	INSTR 9
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	DRUMS $05, DrumPat_6CBA
	INSTR 16
	ARP 1
	LEN 10
	NOTE Dsh, 3
	LEN 20
	NOTE G_, 3
	NOTE Gsh, 3
	ARP_OFF
	NEXT
DrumPat_6C96:
	db DRUM_REPEAT + 6, 1, 0, 4, 0, 2, 0, 4
	db 0, DRUM_REPEAT_END, 1, 0, 2, 0, 1, 0
	db 2, 0, 1, 0, 2, 0, 2, 0
	db 2, 0, DRUM_LOOP
DrumPat_6CB1:
	db 1, 6, 5, 6, 2, 0, 5, 6
	db DRUM_LOOP
DrumPat_6CBA:
	db 2, 0, 2, 0, 0, 0, 2, 0
	db DRUM_LEVEL + 12, DRUM_TEMPO + 3, 1, 1, DRUM_TEMPO + 4, 1, DRUM_LOOP

; Unreferenced (10 bytes)
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

; Instrument table 6, entries 1..17 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr6_0
	dw Instr6_1
	dw Instr6_2
	dw Instr6_3
	dw Instr6_4
	dw Instr6_5
	dw Instr6_6
	dw Instr6_7
	dw Instr6_8
	dw Instr6_9
	dw Instr6_10
	dw Instr6_11
	dw Instr6_12
	dw Instr6_13
	dw Instr6_14
	dw Instr6_15
	dw Instr6_16

; Unreferenced (6 bytes)
	db $68, $6D, $76, $6D, $6E, $6D
Instr6_0:
	HWENV $C1, $03, $63
	ARP 6
	DUTY_12
	END
Instr6_1:
	HWENV $C1, $00
	DUTY_12
	PAN_L
	AUTOPAN $03
	END
Instr6_2:
	HWENV $F1, $08, $00
	GLIDE $FE
	END
Instr6_3:
	HWENV $C1, $04, $10
	ARP 0
	PINGPONG
	END
Instr6_4:
	GLIDE_OFF
	HWENV $C2, $05, $64
	ARP 4
	AUTODUTY $02
	END
Instr6_5:
	GLIDE_OFF
	HWENV $C2, $05, $64
	ARP 5
	AUTODUTY $02
	END
Instr6_6:
	HWENV $C2, $06, $50
	DUTY_75
	ARP 0
	END
Instr6_7:
	HWENV $81, $04, $42
	DUTY_12
	END
Instr6_8:
	HWENV $70, $01, $31
	END
Instr6_9:
	HWENV $81, $05, $53
	ARP 6
	DUTY_12
	END
Instr6_10:
	HWENV $A1, $00
	DUTY_75
	ARP 0
	END
Instr6_11:
	VOLENV 15, $11, $1F, $13
	ARP 0
	END
Instr6_12:
	VOLENV 15, $10, $1F, $11
	ARP 0
	END
Instr6_13:
	HWENV $59, $05, $80
	DUTY_75
	RELEASE $98, $63
	END
Instr6_14:
	HWENV $C1, $08, $60
	END
Instr6_15:
	HWENV $81, $02, $47
	END

; Unreferenced (23 bytes)
	db $75, $C1, $08, $60, $A1, $68, $C7, $11, $1F, $11, $7A, $15, $78, $68, $7A, $95
	db $78, $C7, $11, $1A, $13, $A0, $68
Instr6_16:
	HWENV $D2, $0A, $67
	END

; PlaySong table: A = 0-9
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

; Instrument table 7, entries 1..20 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr7_0
	dw Instr7_1
	dw Instr7_2
	dw Instr7_3
	dw Instr7_4
	dw Instr7_5
	dw Instr7_6
	dw Instr7_7
	dw Instr7_8
	dw Instr7_9
	dw Instr7_10
	dw Instr7_11
	dw Instr7_12
	dw Instr7_13
	dw Instr7_14
	dw Instr7_15
	dw Instr7_16
	dw Instr7_17
	dw Instr7_18
	dw Instr7_19
Instr7_0:
	HWENV $C1, $03, $63
	ARP 6
	DUTY_12
	END
Instr7_1:
	HWENV $C1, $00
	ARP 8
	DUTY_12
	PAN_L
	AUTOPAN $03
	END
Instr7_2:
	HWENV $F1, $08, $00
	GLIDE $FE
	DUTY_75
	END
Instr7_3:
	HWENV $C1, $04, $10
	ARP 0
	PINGPONG
	END
Instr7_4:
	HWENV $C2, $04, $40
	ARP 4
	AUTODUTY $02
	END
Instr7_5:
	HWENV $C1, $04, $40
	ARP 5
	AUTODUTY $02
	END
Instr7_6:
	HWENV $C2, $06, $50
	DUTY_75
	ARP 0
	END
Instr7_7:
	HWENV $81, $04, $42
	DUTY_12
	END
Instr7_8:
	HWENV $70, $01, $31
	END
Instr7_9:
	HWENV $A1, $05, $53
	ARP 6
	END
Instr7_10:
	HWENV $A1, $00
	DUTY_75
	ARP 0
	END
Instr7_11:
	HWENV $C1, $02, $51
	ARP 0
	DUTY_12
	END
Instr7_12:
	WAVE Wave_7885
	VOLENV 15, $11, $1F, $11
	ARP_OFF
	END
Instr7_13:
	HWENV $59, $05, $80
	DUTY_75
	RELEASE $98, $63
	END
Instr7_14:
	HWENV $C1, $08, $60
	END
Instr7_15:
	HWENV $81, $02, $47
	END
Instr7_17:
	HWENV $C1, $08, $60
	ARP 1
	END
Instr7_19:
	VOLENV 15, $11, $1F, $11
	WAVE Wave_7815
	END
Instr7_18:
	WAVE Wave_7895
	VOLENV 15, $11, $1A, $13
	ARP 0
	END
Instr7_16:
	HWENV $F1, $04, $50
	ARP 1
	DUTY_75
	PAN_R
	NOTE Dsh, 1
	ARP 0
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

; Unreferenced (14 bytes)
	db $46, $6F, $50, $6F, $5B, $6F, $67, $6F, $67, $6F, $67, $6F, $67, $6F
Arp0:
	db $0C, $00, ARP_HOLD
Arp3:
	db $00, $00, $00, $01, $01, $01, $02, ARP_HOLD
Arp2:
	db $0C, $01, $00, $00, $00, $00, $00, $00
	db $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C
	db ARP_LOOP
Arp1:
	db $00, $00, $0C, $0C, ARP_LOOP
Arp4:
	db $00, $04, $07, ARP_LOOP
Arp5:
	db $00, $03, $07, ARP_LOOP
Arp6:
	db $0C, $00, $00, $00, $00, $00, $00, $0C
	db ARP_LOOP
Arp7:
	db $00, $00, $00, $01, $01, $01, $02, ARP_HOLD
Arp8:
	db $00, $00, $03, $03, $08, $08, ARP_LOOP
Arp9:
	db $0C, $0C, $00, $00, $00, $00, $00, $00
	db $0C, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00
	db ARP_LOOP
Arp10:
	db $00, $0C, ARP_LOOP
Arp11:
	db $0C, $00, $00, $00, $00, $00, $00, $0C
	db $0C, $0C, $0C, $0C, $0C, $0C, ARP_HOLD
Arp12:
	db $00, $00, $04, $04, $09, $09, ARP_LOOP
Arp13:
	db $00, $00, $05, $05, $09, $09, ARP_LOOP
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
	db $0C, $00, $00, $00, $00, $00, $00, $00
	db $00, ARP_LOOP
Arp20:
	db $00, $00, $01, $01, $02, ARP_HOLD

; Unreferenced (33 bytes)
	db $13, $00, $00, $00, $00, $00, $00, $00, $00, $6A, $0C, $00, $00, $00, $00, $00
	db $00, $00, $00, $0C, $FF, $0C, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $6A
WaveSeq_6F67:
	dw Wave_7033
	dw Wave_7023
	dw Wave_7013
	dw Wave_7003
	dw Wave_6FF3
	dw Wave_6FE3
	dw Wave_6FD3
	dw Wave_6FC3
	dw Wave_6FB3
	dw Wave_6FA3
	dw Wave_6F93
	dw Wave_6F93
	dw Wave_6FA3
	dw Wave_6FB3
	dw Wave_6FC3
	dw Wave_6FD3
	dw Wave_6FE3
	dw Wave_6FF3
	dw Wave_7003
	dw Wave_7013
Wave_6F8F:
	db $23, $70, $00, $00               ; 16-byte wave: continues into the next wave
Wave_6F93:
	db $24, $68, $AC, $EF, $FF, $FF, $FF, $FF
	db $FF, $FF, $00, $00, $EC, $A8, $64, $20
Wave_6FA3:
	db $24, $68, $AC, $EF, $FF, $FF, $FF, $FF
	db $F0, $00, $00, $00, $EC, $A8, $64, $20
Wave_6FB3:
	db $24, $67, $AC, $EF, $FF, $FF, $FF, $F0
	db $02, $00, $00, $00, $EC, $A8, $64, $20
Wave_6FC3:
	db $24, $67, $AC, $FF, $FF, $FF, $F0, $00
	db $03, $00, $00, $00, $EC, $A8, $64, $20
Wave_6FD3:
	db $24, $67, $A0, $FF, $FF, $FF, $00, $00
	db $04, $00, $00, $00, $00, $00, $00, $00
Wave_6FE3:
	db $27, $CF, $F0, $FF, $FF, $F0, $00, $00
	db $05, $00, $00, $00, $00, $00, $00, $00
Wave_6FF3:
	db $27, $CF, $F0, $FF, $FF, $00, $00, $00
	db $06, $00, $00, $00, $00, $00, $00, $00
Wave_7003:
	db $FF, $FF, $F0, $FF, $F0, $00, $00, $00
	db $07, $00, $00, $00, $00, $00, $00, $00
Wave_7013:
	db $FF, $FF, $F0, $FF, $00, $00, $00, $00
	db $08, $00, $00, $00, $00, $00, $00, $00
Wave_7023:
	db $FF, $FF, $F0, $F0, $00, $00, $00, $00
	db $0A, $00, $00, $00, $00, $00, $00, $00
Wave_7033:
	db $FF, $FF, $F0, $00, $00, $00, $00, $00
	db $0B, $02, $00, $00, $00, $00, $00, $00

; Unreferenced (64 bytes)
	db $FF, $FF, $00, $00, $00, $00, $00, $00, $0C, $03, $03, $00, $00, $00, $00, $00
	db $FF, $F0, $00, $00, $00, $00, $00, $00, $0D, $04, $04, $04, $00, $00, $00, $00
	db $FF, $00, $00, $00, $00, $00, $00, $00, $0E, $05, $05, $05, $05, $00, $00, $00
	db $F0, $00, $00, $00, $00, $00, $00, $00, $0F, $0F, $0F, $0F, $0F, $07, $07, $00
WaveSeq_7083:
	dw Wave_7179
	dw Wave_7169
	dw Wave_7159
	dw Wave_7149
	dw Wave_7139
	dw Wave_7129
	dw Wave_7119
	dw Wave_7109
	dw Wave_70F9
	dw Wave_70E9
	dw Wave_70D9
	dw Wave_70C9
	dw Wave_70B9
	dw Wave_70B9
	dw Wave_70C9
	dw Wave_70D9
	dw Wave_70E9
	dw Wave_70F9
	dw Wave_7109
	dw Wave_7119
	dw Wave_7129
	dw Wave_7139
	dw Wave_7149
	dw Wave_7159
	dw Wave_7169
	dw Wave_7179
	dw 0
Wave_70B9:
	db $34, $56, $78, $9A, $BC, $DE, $FF, $F0
	db $0F, $FF, $ED, $CB, $A9, $87, $65, $43
Wave_70C9:
	db $45, $67, $89, $AB, $CD, $EF, $FF, $1F
	db $F1, $FF, $FE, $DC, $BA, $98, $76, $54
Wave_70D9:
	db $56, $78, $9A, $BC, $DE, $FF, $F1, $2F
	db $F2, $1F, $FF, $ED, $CB, $A9, $87, $65
Wave_70E9:
	db $67, $89, $AB, $CD, $EF, $FF, $12, $3F
	db $F3, $21, $FF, $FE, $DC, $BA, $98, $76
Wave_70F9:
	db $78, $9A, $BC, $DE, $FF, $F1, $23, $4F
	db $F4, $32, $1F, $FF, $ED, $CB, $A9, $87
Wave_7109:
	db $89, $AB, $CD, $EF, $FF, $12, $34, $5F
	db $F5, $43, $21, $FF, $FE, $DB, $AB, $98
Wave_7119:
	db $9A, $BC, $DE, $FF, $F1, $23, $45, $6F
	db $F6, $54, $32, $1F, $FF, $ED, $CB, $A9
Wave_7129:
	db $AB, $CD, $EF, $FF, $12, $34, $56, $7F
	db $F7, $65, $43, $21, $FF, $FE, $DC, $BA
Wave_7139:
	db $BC, $DE, $FF, $F1, $23, $45, $67, $8F
	db $F8, $76, $54, $32, $1F, $FF, $ED, $CB
Wave_7149:
	db $CD, $EF, $FF, $12, $34, $56, $78, $9F
	db $F9, $87, $65, $43, $21, $FF, $FE, $DC
Wave_7159:
	db $DE, $FF, $F1, $23, $45, $67, $89, $AF
	db $FA, $98, $76, $54, $32, $1F, $FF, $ED
Wave_7169:
	db $EF, $FF, $12, $34, $56, $78, $9A, $BF
	db $FB, $A9, $87, $65, $43, $21, $FF, $FE
Wave_7179:
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

; Sound effect 14
Sfx14:
	WAVE Wave_7905
	VOLENV 15, $11, $1F, $12
	LEN 5
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 3
	WAIT
	END

; Sound effect 30
Sfx30:
	WAVE Wave_78C5
	GLIDE $FF
	LEN 10
	ARP 1
	CH_TRANSPOSE $02
	VOLENV 5, $00, $00, $00
	NOTE G_, 5
	VOLENV 10, $00, $00, $00
	NOTE G_, 5
	VOLENV 15, $00, $00, $00
	NOTE G_, 5
	NOTE G_, 5
	VOLENV 10, $00, $00, $00
	NOTE G_, 5
	NOTE G_, 5
	VOLENV 5, $00, $00, $00
	NOTE G_, 5
	NOTE G_, 5
	END

; Sound effect 32
Sfx32:
	VOLENV 15, $00, $00, $00
	WAVE Wave_7875
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
	WAVE Wave_78B5
	PAN_R
	VOLENV 15, $00, $00, $00
	GLIDE $FE
	LEN 4
	NOTE G_, 5
	END

; Sound effect 4
Sfx04:
	WAVE Wave_78B5
	VOLENV 15, $00, $00, $00
	GLIDE $FE
	LEN 4
	NOTE Dsh, 5
	END

; Sound effect 5
Sfx05:
	WAVE Wave_78B5
	PAN_L
	VOLENV 15, $00, $00, $00
	GLIDE $FE
	LEN 4
	NOTE B_, 4
	END

; Sound effect 1
Sfx01:
	WAVE Wave_78B5
	VOLENV 15, $00, $00, $00
	LEN 1
	NOTE D_, 4
	NOTE Gsh, 3
	END

; Sound effect 2
Sfx02:
	WAVE Wave_78B5
	VOLENV 15, $00, $00, $00
	LEN 1
	NOTE B_, 4
	NOTE Gsh, 4
	END

; Sound effect 6
Sfx06:
	WAVE Wave_78B5
	VOLENV 15, $00, $00, $00
	LEN 1
	NOTE Dsh, 5
	END

; Sound effect 7
Sfx07:
	VOLENV 15, $11, $1F, $10
	WAVE Wave_7835
	CALL_CODE Code_7790
	LEN 10
	GLIDE $01
	ARP 10
	VIBRATO $01, $04, $01
	NOTE C_, 3
	GLIDE_OFF
	LEN 30
	WAIT
	LEN 10
	GLIDE $FE
	NOTE Dsh, 1
	VOLENV 5, $11, $1F, $13
	NOTE Dsh, 1
	VOLENV 5, $11, $1F, $13
	NOTE Dsh, 1
	END

; Sound effect 28
Sfx28:
	VOLENV 15, $11, $1F, $13
	WAVE Wave_78C5
	CALL_CODE Code_76EC
	LEN 5
	NOTE C_, 4
	CALL_CODE Code_7790
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

; Sound effect 11
Sfx11:
	LEN 5
	ARP 6
	WAVE Wave_7885
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

; Sound effect 23
Sfx23:
	CALL_CODE Code_75B4
	VOLENV 15, $00, $00, $00
	ARP 3
	WAVE Wave_7905
	LEN 3
	REST
	CALL_CODE Code_7643
	LEN 5
	GLIDE $FE
	NOTE E_, 3
	END

; Sound effect 24
Sfx24:
	CALL_CODE Code_75DB
	VOLENV 11, $11, $1F, $14
	WAVE Wave_7875
	LEN 5
	GLIDE $FB
	NOTE C_, 5
	END

; Sound effect 25
Sfx25:
	CALL_CODE Code_75B4
	WAVE Wave_7875
	VOLENV 15, $11, $1F, $11
	LEN 5
	GLIDE $04
	NOTE A_, 2
	GLIDE $65
	WAIT
	WAIT
	END

; Sound effect 16
Sfx16:
	CALL_CODE Code_758D
	VOLENV 11, $11, $1F, $13
	WAVE Wave_7865
	LEN 23
	SLIDE_DOWN $03
	NOTE A_, 4
	END

; Sound effect 8
Sfx08:
	CALL_CODE Code_7525
	WAVE Wave_7845
	VOLENV 15, $11, $1F, $11
	ARP 0
	LEN 7
	GLIDE $FF
	NOTE Fsh, 2
	WAVE Wave_7875
	GLIDE $FE
	NOTE C_, 4
	END

; Sound effect 17
Sfx17:
	VOLENV 15, $0F, $1F, $14
	LEN 3
	ARP 5
	GLIDE $01
	WAVE Wave_78D5
	LEN 40
	NOTE A_, 4
	END

; Sound effect 18
Sfx18:
	VOLENV 15, $11, $5F, $11
	ARP 2
	WAVE Wave_78D5
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

; Sound effect 20
Sfx20:
	VOLENV 15, $00, $00, $00
	GLIDE $FC
	LEN 10
	CH_TRANSPOSE $3F
	ARP 6
	WAVE Wave_78D5
	NOTE A_, 2
	VOLENV 10, $00, $00, $00
	NOTE A_, 2
	VOLENV 5, $00, $00, $00
	NOTE A_, 2
	END

; Sound effect 26
Sfx26:
	CALL_CODE Code_7722
	VOLENV 15, $11, $1F, $11
	WAVE Wave_7845
	LEN 6
	GLIDE $FD
	NOTE D_, 4
	END

; Sound effect 19
Sfx19:
	VOLENV 15, $00, $00, $00
	GLIDE $05
	LEN 10
	WAVE Wave_78D5
	NOTE A_, 2
	VOLENV 10, $00, $00, $00
	NOTE A_, 2
	VOLENV 5, $00, $00, $00
	NOTE A_, 2
	END

; Sound effect 22
Sfx22:
	WAVE Wave_7925
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

; Sound effect 9
Sfx09:
	VOLENV 15, $00, $00, $00
	LEN 8
	CH_TRANSPOSE $F0
	ARP 2
	WAVE Wave_78F5
	NOTE A_, 4
	WAVE Wave_7825
	NOTE A_, 4
	WAVE Wave_78E5
	NOTE A_, 4
	WAVE Wave_7835
	NOTE A_, 4
	WAVE Wave_7905
	GLIDE $FF
	NOTE A_, 4
	END

; Sound effect 10
Sfx10:
	WAVE Wave_7845
	VOLENV 15, $11, $1F, $11
	CALL_CODE Code_749D
	LEN 5
	GLIDE $FE
	NOTE C_, 3
	GLIDE_OFF
	WAVE Wave_7825
	VOLENV 5, $1F, $00, $20
	CALL_CODE Code_74CB
	LEN 21
	GLIDE $FF
	NOTE G_, 4
	END

; Sound effect 29
Sfx29:
	CALL_CODE Code_77D3
	VOLENV 15, $11, $1F, $13
	WAVE Wave_7845
	GLIDE $FE
	LEN 10
	CH_TRANSPOSE $0C
	NOTE C_, 3
	VOLENV 10, $11, $1F, $13
	NOTE C_, 3
	VOLENV 5, $11, $1F, $13
	NOTE C_, 3
	END

; Sound effect 15
Sfx15:
	CALL_CODE Code_7758
	VOLENV 15, $11, $1F, $11
	GLIDE $FF
	WAVE Wave_7845
	LEN 10
	NOTE G_, 3
	CALL_CODE Code_7758
	NOTE G_, 3
	END

; Sound effect 27
Sfx27:
	WAVE Wave_78C5
	CALL_CODE Code_76B3
	VOLENV 15, $12, $1F, $12
	LEN 8
	GLIDE $FF
	NOTE A_, 4
	LEN 5
	VOLENV 10, $11, $1F, $12
	NOTE A_, 4
	END

; Sound effect 21
Sfx21:
	CALL_CODE Code_7643
	VOLENV 15, $00, $00, $00
	WAVE Wave_7805
	LEN 3
	GLIDE $FF
	NOTE A_, 5
	WAVE Wave_7915
	WAIT
	GLIDE $FE
	WAVE Wave_7935
	WAIT
	LEN 10
	WAVE Wave_7915
	VOLENV 10, $00, $00, $00
	NOTE E_, 5
	VOLENV 5, $00, $00, $00
	NOTE E_, 5
	END

; Sound effect 12
Sfx12:
	VOLENV 15, $11, $2F, $11
	WAVE Wave_7885
	LEN 8
	NOTE C_, 6
	VOLENV 10, $11, $2F, $11
	NOTE C_, 6
	VOLENV 5, $11, $2F, $11
	NOTE C_, 6
	END

; Sound effect 13
Sfx13:
	LEN 4
	VOLENV 15, $11, $2F, $11
	WAVE Wave_7885
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

; Sound effect 31
Sfx31:
	VOLENV 15, $11, $1F, $11
	CALL_CODE Code_76EC
	WAVE Wave_7845
	LEN 12
	GLIDE $FE
	NOTE C_, 3
	END
Code_749D:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $0A
	ld [wDrumHold], a
	ld a, HIGH(Noise43_74C4)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_74C4)
	ld [wNoise43], a
	ld a, HIGH(Noise42_74C8)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_74C8)
	ld [wNoise42], a
	ret
Noise43_74C4:
	db $4A, $5A, $50, $FF
Noise42_74C8:
	db $F0, $D0, $B1
Code_74CB:
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
	ld a, HIGH(Noise43_74FA)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_74FA)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_74FA:
	db $18, $3A, $47, $49, $2E, $2D, $1C, $28
	db $4A, $57, $39, $4E, $1D, $0C, $FF
Noise43_7509:
	db $82, $64, $02, $37, $47, $24, $55, $71
	db $07, $44, $60, $36, $84, $82, $64, $02
	db $37, $47, $24, $55, $71, $07, $44, $60
	db $36, $86, $32, $FF
Code_7525:
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
	ld a, HIGH(Noise43_7509)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7509)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret

; Unreferenced (54 bytes)
	db $3E, $88, $EA, $43, $D2, $3E, $08, $EA, $44, $D2, $AF, $EA, $58, $D2, $3C, $EA
	db $59, $D2, $3E, $75, $EA, $54, $D2, $3E, $7E, $EA, $55, $D2, $3E, $75, $EA, $56
	db $D2, $3E, $86, $EA, $57, $D2, $C9, $60, $52, $42, $41, $22, $11, $21, $FF, $F0
	db $F0, $F0, $F0, $F0, $F0, $61
Code_758D:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_761C)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_761C)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7636)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7636)
	ld [wNoise42], a
	ret
Code_75B4:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7629)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7629)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7636)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7636)
	ld [wNoise42], a
	ret
Code_75DB:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_760F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_760F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7602)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7602)
	ld [wNoise42], a
	ret
Noise42_7602:
	db $F1, $A1, $FF, $FF, $FF, $FF, $43, $FF
	db $FF, $FF, $FF, $FF

; Unreferenced (1 bytes)
	db $FF
Noise43_760F:
	db $51, $10, $20, $31, $32, $33, $53, $34
	db $14, $15, $15, $16, $FF
Noise43_761C:
	db $10, $10, $20, $31, $32, $33, $33, $34
	db $34, $35, $35, $36, $FF
Noise43_7629:
	db $36, $35, $35, $34, $34, $33, $33, $32
	db $31, $20, $10, $10, $FF
Noise42_7636:
	db $5F, $FF, $FF, $FF, $FF, $FF, $A1, $FF
	db $FF, $FF, $FF, $FF

; Unreferenced (1 bytes)
	db $FF
Code_7643:
	ld a, $88
	ld [wNoisePan], a
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_766A)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_766A)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7670)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7670)
	ld [wNoise42], a
	ret
Noise43_766A:
	db $00, $53, $71, $91, $31, $FF
Noise42_7670:
	db $F2, $FF, $FF, $FF, $00

; Unreferenced (62 bytes)
	db $3E, $88, $EA, $43, $D2, $3E, $0A, $EA, $44, $D2, $AF, $EA, $58, $D2, $3C, $EA
	db $59, $D2, $3E, $76, $EA, $54, $D2, $3E, $9C, $EA, $55, $D2, $3E, $76, $EA, $56
	db $D2, $3E, $A8, $EA, $57, $D2, $C9, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0
	db $A0, $A0, $FF, $F0, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00
Code_76B3:
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
	ld a, HIGH(Noise43_76E2)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_76E2)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_76E2:
	db $02, $92, $42, $42, $42, $42, $52, $65
	db $45, $FF
Code_76EC:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7713)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7713)
	ld [wNoise43], a
	ld a, HIGH(Noise42_771B)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_771B)
	ld [wNoise42], a
	ret
Noise43_7713:
	db $02, $51, $61, $71, $91, $71, $60, $FF
Noise42_771B:
	db $F0, $F0, $F0, $F0, $F0, $70, $63
Code_7722:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7749)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7749)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7751)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7751)
	ld [wNoise42], a
	ret
Noise43_7749:
	db $22, $51, $64, $81, $51, $41, $60, $FF
Noise42_7751:
	db $F0, $F0, $F0, $F0, $F0, $70, $63
Code_7758:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0A
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_777F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_777F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7788)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7788)
	ld [wNoise42], a
	ret
Noise43_777F:
	db $78, $78, $78, $78, $58, $56, $56, $68
	db $FF
Noise42_7788:
	db $A1, $FF, $11, $00, $81, $FF, $F2, $00
Code_7790:
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
	ld a, HIGH(Noise43_77C0)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_77C0)
	ld [wNoise43], a
	ld a, HIGH(Noise42_77CA)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_77CA)
	ld [wNoise42], a
	ret
Noise43_77C0:
	db $67, $56, $45, $34, $23, $22, $11, $10
	db $20, $FF
Noise42_77CA:
	db $19, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $F3
Code_77D3:
	ld a, $88
	ld [wNoisePan], a
	ld a, $19
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_77FA)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_77FA)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7800)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7800)
	ld [wNoise42], a
	ret
Noise43_77FA:
	db $03, $83, $80, $80, $61, $FF
Noise42_7800:
	db $F0, $FF, $FF, $FF, $F2
Wave_7805:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $00, $00, $00, $00
Wave_7815:
	db $00, $46, $8A, $FF, $FF, $A8, $64, $00
	db $00, $46, $8A, $FF, $FF, $A8, $64, $00
Wave_7825:
	db $B7, $40, $F4, $7B, $FD, $FF, $FE, $DC
	db $02, $46, $8A, $BD, $FD, $BA, $6F, $20
Wave_7835:
	db $B7, $4E, $F4, $FF, $DF, $FF, $ED, $C0
	db $24, $68, $AB, $DF, $DD, $DD, $6F, $20
Wave_7845:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
Wave_7855:
	db $01, $11, $11, $00, $89, $AA, $AA, $98
	db $01, $11, $11, $00, $FF, $FF, $FF, $FF
Wave_7865:
	db $00, $00, $00, $00, $00, $00, $FF, $FF
	db $00, $00, $00, $00, $00, $00, $FF, $FF
Wave_7875:
	db $00, $00, $00, $00, $00, $00, $FF, $00
	db $00, $00, $00, $00, $00, $00, $FF, $00
Wave_7885:
	db $00, $00, $00, $CD, $EF, $FF, $FF, $FF
	db $04, $8C, $FF, $FF, $FF, $FF, $FF, $FF
Wave_7895:
	db $48, $FF, $FF, $FF, $FF, $FF, $FF, $84
	db $00, $00, $00, $00, $00, $4F, $FF, $88
Wave_78A5:
	db $EC, $96, $31, $8A, $40, $00, $00, $00
	db $24, $69, $CE, $FF, $FF, $FF, $FF, $FF
Wave_78B5:
	db $FF, $FF, $ED, $B8, $53, $21, $00, $00
	db $00, $00, $12, $35, $8B, $DE, $FF, $FF
Wave_78C5:
	db $63, $10, $40, $20, $00, $00, $01, $36
	db $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9
Wave_78D5:
	db $63, $1F, $01, $47, $74, $10, $01, $36
	db $9C, $E0, $FE, $B8, $8B, $EF, $FE, $C9
Wave_78E5:
	db $B7, $40, $04, $7B, $CD, $FF, $FE, $DC
	db $02, $46, $8A, $BD, $FD, $BA, $64, $20
Wave_78F5:
	db $0F, $00, $F0, $F0, $F0, $F0, $00, $0F
	db $0F, $FF, $FF, $00, $FF, $F0, $0F, $0F
Wave_7905:
	db $BB, $2B, $BB, $2B, $BB, $5B, $2B, $BB
	db $2B, $BB, $BB, $72, $27, $EB, $BB, $B0
Wave_7915:
	db $04, $8B, $DE, $FF, $ED, $CB, $A9, $87
	db $65, $44, $44, $32, $11, $24, $7A, $74
Wave_7925:
	db $00, $00, $69, $FF, $FF, $F9, $64, $00
	db $03, $68, $B8, $60, $00, $04, $68, $60
Wave_7935:
	db $20, $24, $68, $AC, $EC, $A8, $64, $20
	db $24, $68, $A8, $64, $20, $24, $68, $64
Noise43_7945:
	db $21, $24, $23, $22, $15, $FF
Noise42_794B:
	db $93, $FF, $FF, $FF, $45
Noise43_7950:
	db $11, $11, $FF
Noise42_7953:
	db $51, $21
Noise43_7955:
	db $11, $11, $FF
Noise42_7958:
	db $71, $21
Noise43_795A:
	db $11, $11, $FF
Noise42_795D:
	db $81, $FF

; Unreferenced (15 bytes)
	db $50, $41, $50, $51, $42, $53, $51, $FF, $90, $50, $90, $40, $C0, $50, $42
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7994)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7994)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7998)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7998)
	ld [wNoise42], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $01
	jp PlaySfx
Noise43_7994:
	db $21, $45, $05, $FF
Noise42_7998:
	db $61, $F1, $21

; Unreferenced (11 bytes)
	db $04, $02, $01, $00, $00, $FF, $30, $40, $60, $43, $42
Drum2:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_79F2)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_79F2)
	ld [wNoise43], a
	ld a, HIGH(Noise42_79F6)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_79F6)
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
	ld a, HIGH(Noise43_7B7E)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B7E)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B81)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B81)
	ld [wNoise42], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $06
	jp PlaySfx
Noise43_79F2:
	db $20, $44, $32, $FF
Noise42_79F6:
	db $80, $F1, $43
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_795A)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_795A)
	ld [wNoise43], a
	ld a, HIGH(Noise42_795D)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_795D)
	ld [wNoise42], a
	ret
Drum5:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7955)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7955)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7958)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7958)
	ld [wNoise42], a
	ret
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7950)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7950)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7953)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7953)
	ld [wNoise42], a
	ret
Drum7:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $88
	ld [wNoisePan], a
	ld a, HIGH(Noise43_7945)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7945)
	ld [wNoise43], a
	ld a, HIGH(Noise42_794B)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_794B)
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
	ld a, HIGH(Noise43_7B83)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B83)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B86)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B86)
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
	ld a, HIGH(Noise43_7B83)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B83)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B86)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B86)
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
	ld a, HIGH(Noise43_7B83)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B83)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B86)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B86)
	ld [wNoise42], a
	ld a, $80
	ld [wNoisePan], a
	ld a, $05
	jp PlaySfx

; Unreferenced (1 bytes)
	db $C9
Drum11:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B88)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B88)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B8B)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B8B)
	ld [wNoise42], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $01
	jp PlaySfx

; Unreferenced (1 bytes)
	db $C9
Drum12:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B30)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B30)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B33)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B33)
	ld [wNoise42], a
	ret
Noise43_7B30:
	db $51, $32, $FF
Noise42_7B33:
	db $A0, $43
Drum13:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B52)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B52)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B55)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B55)
	ld [wNoise42], a
	ret
Noise43_7B52:
	db $51, $32, $FF
Noise42_7B55:
	db $80, $32
Drum14:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_795A)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_795A)
	ld [wNoise43], a
	ld a, HIGH(Noise42_795D)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_795D)
	ld [wNoise42], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $01
	jp PlaySfx

; Unreferenced (1 bytes)
	db $C9
Noise43_7B7E:
	db $20, $32, $FF
Noise42_7B81:
	db $A0, $91
Noise43_7B83:
	db $21, $12, $FF
Noise42_7B86:
	db $A0, $62
Noise43_7B88:
	db $20, $42, $FF
Noise42_7B8B:
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

; Unreferenced (1091 bytes)
	db $C1, $40, $C0, $40, $C0, $60, $BF, $60, $BF, $60, $BE, $60, $BE, $60, $BD, $60
	db $BD, $60, $BC, $60, $BC, $60, $BB, $60, $BB, $60, $BA, $60, $BA, $60, $B9, $60
	db $B9, $60, $B8, $40, $B8, $40, $B7, $40, $B7, $40, $B6, $40, $B6, $40, $B5, $40
	db $B5, $40, $B4, $40, $B4, $40, $B3, $40, $B3, $40, $B2, $40, $B2, $40, $B1, $40
	db $B1, $40, $B0, $40, $B0, $60, $AF, $60, $AF, $60, $AE, $60, $AE, $60, $AD, $60
	db $AD, $60, $AC, $60, $AC, $60, $AB, $60, $AB, $60, $AA, $60, $AA, $60, $A9, $60
	db $A9, $60, $A8, $40, $A8, $40, $A7, $40, $A7, $40, $A6, $40, $A6, $40, $A5, $40
	db $A5, $40, $A4, $40, $A4, $40, $A3, $40, $A3, $40, $A2, $40, $A2, $40, $A1, $40
	db $A1, $40, $A0, $40, $A0, $60, $9F, $60, $9F, $60, $9E, $60, $9E, $60, $9D, $60
	db $9D, $60, $9C, $60, $9C, $60, $9B, $60, $9B, $60, $9A, $60, $9A, $60, $99, $60
	db $99, $60, $98, $40, $98, $40, $97, $40, $97, $40, $96, $40, $96, $40, $95, $40
	db $95, $40, $94, $40, $94, $40, $93, $40, $93, $40, $92, $40, $92, $40, $91, $40
	db $91, $40, $90, $40, $90, $60, $8F, $60, $8F, $60, $8E, $60, $8E, $60, $8D, $60
	db $8D, $60, $8C, $60, $8C, $60, $8B, $60, $8B, $60, $8A, $60, $8A, $60, $89, $60
	db $89, $60, $88, $40, $88, $40, $87, $40, $87, $40, $86, $40, $86, $40, $85, $40
	db $85, $40, $84, $40, $84, $40, $83, $40, $83, $40, $82, $40, $82, $40, $81, $40
	db $81, $40, $80, $40, $80, $60, $7F, $60, $7F, $60, $7E, $60, $7E, $60, $7D, $60
	db $7D, $60, $7C, $60, $7C, $60, $7B, $60, $7B, $60, $7A, $60, $7A, $60, $79, $60
	db $79, $60, $78, $40, $78, $40, $77, $40, $77, $40, $76, $40, $76, $40, $75, $40
	db $75, $40, $74, $40, $74, $40, $73, $40, $73, $40, $72, $40, $72, $40, $71, $40
	db $71, $40, $70, $40, $70, $60, $6F, $60, $6F, $60, $6E, $60, $6E, $60, $6D, $60
	db $6D, $60, $6C, $60, $6C, $60, $6B, $60, $6B, $60, $6A, $60, $6A, $60, $69, $60
	db $69, $60, $68, $40, $68, $40, $67, $40, $67, $40, $66, $40, $66, $40, $65, $40
	db $65, $40, $64, $40, $64, $40, $63, $40, $63, $40, $62, $40, $62, $40, $61, $40
	db $61, $40, $60, $40, $60, $60, $5F, $60, $5F, $60, $5E, $60, $5E, $60, $5D, $60
	db $5D, $60, $5C, $60, $5C, $60, $5B, $60, $5B, $60, $5A, $60, $5A, $60, $59, $60
	db $59, $60, $58, $40, $58, $40, $57, $40, $57, $40, $56, $40, $56, $40, $55, $40
	db $55, $40, $54, $40, $54, $40, $53, $40, $53, $40, $52, $40, $52, $40, $51, $40
	db $51, $40, $50, $40, $50, $60, $4F, $60, $4F, $60, $4E, $60, $4E, $60, $4D, $60
	db $4D, $60, $4C, $60, $4C, $60, $4B, $60, $4B, $60, $4A, $60, $4A, $60, $49, $60
	db $49, $60, $48, $40, $48, $40, $47, $40, $47, $40, $46, $40, $46, $40, $45, $40
	db $45, $40, $44, $40, $44, $40, $43, $40, $43, $40, $42, $40, $42, $40, $41, $40
	db $41, $40, $40, $40, $40, $60, $3F, $60, $3F, $60, $3E, $60, $3E, $60, $3D, $60
	db $3D, $60, $3C, $60, $3C, $60, $3B, $60, $3B, $60, $3A, $60, $3A, $60, $39, $60
	db $39, $60, $38, $40, $38, $40, $37, $40, $37, $40, $36, $40, $36, $40, $35, $40
	db $35, $40, $34, $40, $34, $40, $33, $40, $33, $40, $32, $40, $32, $40, $31, $40
	db $31, $40, $30, $40, $30, $60, $2F, $60, $2F, $60, $2E, $60, $2E, $60, $2D, $60
	db $2D, $60, $2C, $60, $2C, $60, $2B, $60, $2B, $60, $2A, $60, $2A, $60, $29, $60
	db $29, $60, $28, $40, $28, $40, $27, $40, $27, $40, $26, $40, $26, $40, $25, $40
	db $25, $40, $24, $40, $24, $40, $23, $40, $23, $40, $22, $40, $22, $40, $21, $40
	db $21, $40, $20, $40, $20, $60, $1F, $60, $1F, $60, $1E, $60, $1E, $60, $1D, $60
	db $1D, $60, $1C, $60, $1C, $60, $1B, $60, $1B, $60, $1A, $60, $1A, $60, $19, $60
	db $19, $60, $18, $40, $18, $40, $17, $40, $17, $40, $16, $40, $16, $40, $15, $40
	db $15, $40, $14, $40, $14, $40, $13, $40, $13, $40, $12, $40, $12, $40, $11, $40
	db $11, $40, $10, $40, $10, $60, $0F, $60, $0F, $60, $0E, $60, $0E, $60, $0D, $60
	db $0D, $60, $0C, $60, $0C, $60, $0B, $60, $0B, $60, $0A, $60, $0A, $60, $09, $60
	db $09, $60, $08, $40, $08, $40, $07, $40, $07, $40, $06, $40, $06, $40, $05, $40
	db $05, $40, $04, $40, $04, $40, $03, $40, $03, $40, $02, $40, $02, $40, $01, $40
	db $01, $C0, $00, $C0, $00, $70, $FF, $70, $FF, $70, $FE, $70, $FE, $70, $FD, $70
	db $FD, $70, $FC, $70, $FC, $70, $FB, $70, $FB, $70, $FA, $70, $FA, $70, $F9, $70
	db $F9, $70, $F8, $50, $F8, $50, $F7, $50, $F7, $50, $F6, $50, $F6, $50, $F5, $50
	db $F5, $50, $F4, $50, $F4, $50, $F3, $50, $F3, $50, $F2, $50, $F2, $50, $F1, $50
	db $F1, $50, $F0, $50, $F0, $70, $EF, $70, $EF, $70, $EE, $70, $EE, $70, $ED, $70
	db $ED, $70, $EC, $70, $EC, $70, $EB, $70, $EB, $70, $EA, $70, $EA, $70, $E9, $70
	db $E9, $70, $E8, $50, $E8, $50, $E7, $50, $E7, $50, $E6, $50, $E6, $50, $E5, $50
	db $E5, $50, $E4, $50, $E4, $50, $E3, $50, $E3, $50, $E2, $50, $E2, $50, $E1, $50
	db $E1, $50, $E0, $50, $E0, $70, $DF, $70, $DF, $70, $DE, $70, $DE, $70, $DD, $70
	db $DD, $70, $DC, $70, $DC, $70, $DB, $70, $DB, $70, $DA, $70, $DA, $70, $D9, $70
	db $D9, $70, $D8, $50, $D8, $50, $D7, $50, $D7, $50, $D6, $50, $D6, $50, $D5, $50
	db $D5, $50, $D4, $50, $D4, $50, $D3, $50, $D3, $50, $D2, $50, $D2, $50, $D1, $50
	db $D1, $50, $D0, $50, $D0, $70, $CF, $70, $CF, $70, $CE, $70, $CE, $70, $CD, $70
	db $CD, $70, $CC, $70, $CC, $70, $CB, $70, $CB, $70, $CA, $70, $CA, $70, $C9, $70
	db $C9, $70, $C8, $40, $C9, $40, $C8, $40, $C8, $40, $C7, $40, $C7, $40, $C6, $40
	db $C6, $40, $C5, $40, $C5, $40, $C4, $40, $C4, $40, $C3, $40, $C3, $40, $C2, $40
	db $C2, $40, $C1, $40, $C1, $40, $C0, $40, $C0, $60, $BF, $60, $BF, $60, $BE, $60
	db $BE, $60, $BD, $60, $BD, $60, $BC, $60, $BC, $60, $BB, $60, $BB, $60, $BA, $60
	db $BA, $60, $B9, $40, $B9, $40, $B8, $40, $B8, $40, $B7, $40, $B7, $40, $B6, $40
	db $B6, $40, $B5, $40, $B5, $40, $B4, $40, $B4, $40, $B3, $40, $B3, $40, $B2, $40
	db $B2, $40, $B1
