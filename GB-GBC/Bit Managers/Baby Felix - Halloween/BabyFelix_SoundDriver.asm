; =====================================================================
; Baby Felix: Halloween (E) (M6) [C] - Game Boy Color
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o felix.o BabyFelix_SoundDriver.asm
;   rgblink -o felix.gb felix.o
;   python tools/cmp_banked.py felix.gb "Baby Felix - Halloween (E) (M6) [C][!].gbc" 19:4000-7FFF
; (driver and data fill ROM bank 19; the linked file only matches in that range)
;
; Documentation: BabyFelix_SoundDriver.md / AJG_SoundEngine_Family.md
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
MACRO REPEAT    ; play the following bytes n times (up to REPEAT_END), n = 2-18
	db $ED + \1
ENDM
MACRO LEN       ; note length in ticks, 1-48
	db $BE + \1
ENDM
MACRO VOLENV    ; start volume + envelope (CH3/SFX): atk (lo=count hi=step), dec (lo=count hi=step), rates (hi=atk lo=dec)
	db $AF + \1, \2, \3, \4
ENDM
MACRO INSTR     ; instrument n = entry n + 1 of the current instrument table
	db $8A + \1
ENDM
MACRO ARP       ; arpeggio n of the current arpeggio table
	db $9F + \1
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
MACRO PINGPONG
	db $83
ENDM
MACRO PINGPONG_OFF
	db $84
ENDM
MACRO GLISS_1
	db $85
ENDM
MACRO GLISS_2
	db $86
ENDM
MACRO GLISS_3
	db $87
ENDM
MACRO GLISS_OFF
	db $88
ENDM
MACRO ARP_INLINE  ; arpeggio written in the stream: offsets, then ARP_LOOP or ARP_HOLD
	db $89
	REPT _NARG
		db \1
		SHIFT
	ENDR
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
DEF DRUM_TEMPO EQU $BE         ; + n: one step every n ticks
DEF DRUM_LOOP EQU $FF           ; restart the pattern

; ---- RAM / HRAM ----
DEF wCh1 EQU $C100
DEF wPaused EQU $C140
DEF wShNR32 EQU $C141
DEF wInInstr EQU $C142
DEF wNoisePan EQU $C143
DEF wDrumHold EQU $C144
DEF wInstrTable EQU $C145
DEF wInstrTableHi EQU $C146
DEF wArpTable EQU $C147
DEF wArpTableHi EQU $C148
DEF wMusicWave EQU $C149
DEF wMusicWaveHi EQU $C14A
DEF wNoisePingPong EQU $C14B
DEF wDrumPatHi EQU $C14C
DEF wDrumPat EQU $C14D
DEF wDrumPos EQU $C14E
DEF wDrumsOn EQU $C14F
DEF wDrumTempo EQU $C150
DEF wDrumTimer EQU $C151
DEF wDrumLoopCount EQU $C152
DEF wDrumLoopPos EQU $C153
DEF wNoise43Hi EQU $C154
DEF wNoise43 EQU $C155
DEF wNoise42Hi EQU $C156
DEF wNoise42 EQU $C157
DEF wNoisePos EQU $C158
DEF wNoiseOn EQU $C159
DEF wNoiseAtten EQU $C15A
DEF wNoiseTimer EQU $C15B
DEF wNoiseSpeed EQU $C15C
DEF wFadeTable EQU $C15D
DEF wFadeTableHi EQU $C15E
DEF wFadePos EQU $C15F
DEF wFadeTimer EQU $C160
DEF wFadeSpeed EQU $C161
DEF wFadeOn EQU $C162
DEF wDutyCh1 EQU $C163
DEF wDutyCh2 EQU $C164
DEF wCurSong EQU $C165
DEF wCh2 EQU $C200
DEF wCh3 EQU $C300
DEF wSfx EQU $C400

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


SECTION "SoundDriver", ROMX[$4000], BANK[19]


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
	dw Cmd_PingPong
	dw Cmd_PingPongOff
	dw Cmd_Gliss1
	dw Cmd_Gliss2
	dw Cmd_Gliss3
	dw Cmd_GlissOff
	dw Cmd_ArpInline
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
	ld a, $6E
	ld [wInstrTableHi], a
	ld a, $E0
	ld [wInstrTable], a
	pop af
	cp $0B
	ret nc
	ld [wCurSong], a
	add a, a
	add a, $8B
	ld l, a
	adc a, $6F
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

; The game's SFX glue, inside the driver (PlaySfx jumps here after the id < 39 test):
; id 26 and 27 first start a noise routine and then play their stream as usual,
; id 38 is a noise routine only (its table entry is a placeholder).
GamePlaySfxGlue:
	cp $1A
	jp z, GlueSfx26
	cp $1B
	jp z, GlueSfx27
	cp $26
	jp z, Sfx38_Noise
	jp PlaySfxPriority

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
	ld h, $C1
	call ChannelTick
	inc h
	call ChannelTick
	inc h
	call ChannelTick
	call DrumTick
	ld h, $C4
	call ChannelTick

; Output, pulse pages: NRx3 = period low + pitch offset; when the high byte changed
; or the envelope flag ($33) is set: with the flag NRx2 = field $32 and NRx4 =
; high | $80, else NRx4 = high. (Obelix GBC's duty shadows are gone: duty goes
; straight to NR11/NR21.)
OutputCh1:
	ld hl, $C125
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
	ld hl, $C427
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
	add a, $D6
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
	ld hl, $C138
	ld c, [hl]
	inc h
	ld a, [hl]
	rlc a
	or c
	ld c, a
	inc h
	ld a, [$C427]
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
	ld h, $C4
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
	bit 7, a
	jr z, L4298
	cpl
	inc a
	jr L42B7
L4298:
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
	ld a, [hl]
	bit 7, a
	jr z, L42B7
	cpl
	inc a
	jr L4298
L42B7:
	ld c, a
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
	cp $C3
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
	sub $ED
	ld l, $39
	ld [hli], a
	ld [hl], e
	inc l
	ld [hl], d
	jp ReadByte

; StreamCommand: REPEAT / LEN / VOLENV / ARP / INSTR ranges, else CmdTable.
StreamCommand:
	cp $EF
	jr nc, Cmd_Repeat
	cp $BF
	jr nc, Cmd_Len
	cp $AF
	jr nc, Cmd_VolEnv
	cp $9F
	jr nc, Cmd_Arp
	cp $8A
	jp nc, Cmd_Instrument
	sub $60
	add a, a
	ld c, a
	ld b, $40
	ld a, [bc]
	ld l, a
	inc c
	ld a, [bc]
	ld c, $DD
	ld b, $42
	push bc
	ld b, a
	ld c, l
CallBC:
	push bc
	ret

; LEN n: note length in ticks.
Cmd_Len:
	sub $BE
	ld l, $09
	ld [hl], a
	jp ReadStream

; VOLENV v, atk, dec, rates: start volume v; attack = lo nibble steps of hi nibble;
; decay likewise; rates hi = ticks per attack step, lo = ticks per decay step.
; Only the CH3 and SFX pages use it.
Cmd_VolEnv:
	sub $AF
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
	sub $9F
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
	res 1, [hl]
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
	cp $C3
	jr nc, InstrLookup
	cp $C1
	jr nz, InstrDutyCh2
	ld a, $80
	ld [wDutyCh1], a
	jr InstrLookup
InstrDutyCh2:
	ld a, $80
	ld [wDutyCh2], a
InstrLookup:
	ld a, b
	sub $89
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
	cp $C3
	jr z, ReleaseCh3
	cp $C4
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
	ld [$C31B], a
	ld [$C31A], a
	ld a, [hl]
	and $F0
	swap a
	jr z, SetReleased
	ld [$C308], a
	jr SetReleased
ReleaseSfx:
	ld a, [hl]
	and $0F
	ld [$C41B], a
	ld [$C41A], a
	ld a, [hl]
	and $F0
	swap a
	jr z, SetReleased
	ld [$C408], a
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
	cp $C3
	jr nc, WaitReload
	ld l, $28
	ld a, $08
	ld [hli], a
	ld a, $01
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
	ld a, $80
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
	ldh [rNR42], a
	ldh [rNR32], a
	ldh [rNR42], a
	ldh [rNR32], a
	ld a, $80
	ldh [rNR14], a
	ldh [rNR24], a
	ldh [rNR34], a
	ldh [rNR44], a
	xor a
	ld [wFadeOn], a
	ld [wDrumsOn], a
	ld [wNoiseOn], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $77
	ldh [rNR50], a
	ld h, $C1
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
	cp $C4
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
	ld l, $3E
	ld [hli], a
	ld [hli], a
	ld l, $2A
	ld [hli], a
	ld [hli], a
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
	ld [$C427], a
	ld [$C408], a
	ld [wNoiseTimer], a
	ld [wNoiseSpeed], a
	dec a
	ld [wShNR32], a
	jp RestoreMusicWave
Cmd_Transpose:
	ld a, [de]
	ld [$C10F], a
	ld [$C20F], a
	ld [$C30F], a
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
	cp $C3
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
	cp $C3
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
	cp $C1
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
	cp $C3
	jr nz, LoadWave
SetMusicWave:
	ld a, [de]
	inc de
	ld [wMusicWave], a
	ld a, [de]
	ld [wMusicWaveHi], a
	ld a, [$C427]
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
	ld a, [$C305]
	ldh [rNR33], a
	ld a, $80
	ld [$C307], a
	ldh [rNR30], a
	ldh [rNR34], a
	ret

; Unreferenced (242 bytes)
	db $51, $57, $50, $E8, $14, $4B, $00, $00, $8B, $45, $FC, $8D, $4D, $20, $83, $C0
	db $58, $51, $8D, $4D, $1C, $51, $8D, $4E, $0C, $51, $57, $50, $E8, $0C, $FE, $FF
	db $FF, $8B, $45, $FC, $8D, $4D, $20, $51, $8D, $4D, $1C, $51, $8D, $4E, $18, $05
	db $B0, $00, $00, $00, $51, $57, $FF, $70, $04, $FF, $30, $E8, $CD, $47, $00, $00
	db $8B, $45, $20, $85, $C0, $7C, $18, $29, $03, $6A, $01, $5E, $FF, $75, $FC, $6A
	db $01, $E8, $6D, $FE, $FF, $FF, $8B, $C6, $5F, $5E, $5B, $C9, $C2, $1C, $00, $29
	db $03, $85, $F6, $74, $E4, $68, $EA, $00, $00, $00, $FF, $15, $78, $11, $41, $71
	db $33, $F6, $EB, $D8, $55, $8B, $EC, $51, $83, $65, $FC, $00, $83, $7D, $1C, $00
	db $56, $75, $0E, $8B, $45, $20, $6A, $01, $C7, $00, $08, $00, $00, $00, $58, $EB
	db $55, $8B, $75, $20, $6A, $08, $58, $39, $06, $89, $06, $73, $0F, $68, $EA, $00
	db $00, $00, $FF, $15, $78, $11, $41, $71, $33, $C0, $EB, $3A, $8D, $45, $FC, $50
	db $FF, $75, $14, $FF, $75, $10, $6A, $0A, $E8, $E2, $FD, $FF, $FF, $85, $C0, $74
	db $0F, $FF, $75, $1C, $FF, $75, $FC, $E8, $D7, $4D, $00, $00, $85, $C0, $75, $07
	db $83, $26, $00, $33, $F6, $EB, $03, $6A, $01, $5E, $FF, $75, $FC, $6A, $0A, $E8
	db $DF, $FD, $FF, $FF, $8B, $C6, $5E, $C9, $C2, $1C, $00, $55, $8B, $EC, $81, $EC
	db $94, $00
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
	cp $C3
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
	ld h, $C1
	jr L4A01
L49F4:
	ld h, $C2
	jr L4A01
L49F8:
	ld h, $C3
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
	cp $27
	ret nc
	ld c, a
	jp GamePlaySfxGlue
PlaySfxPriority:
	cp $06
	jr nc, L4A27
	ld a, [$C427]
	cp $06
	ret nc
L4A27:
	ld a, c
PlaySfxStart:
	ld [$C427], a
	ld a, $11
	ld [$C438], a
	xor a
	ld [$C404], a
	ld [$C40B], a
	ld [$C431], a
	ld [$C42E], a
	ld [$C40E], a
	ld [$C40F], a
	inc a
	ld [$C40A], a
	ld a, $F4
	ld [$C40D], a
	ld a, c
	ld de, $C402
	add a, a
	add a, $BF
	ld l, a
	adc a, $6F
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
	cp $BF
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
	add a, $81
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
	sub $BE
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
	db $78, $3D, $28, $E0, $EA, $4B, $C1, $3E, $08, $EA, $43, $C1, $C9, $C9
NoiseSeqEnd:
	xor a
	ld [wNoisePos], a
	ld [wNoiseOn], a
	ret
Cmd_ArpInline:
	ld l, $1D
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	ld [hl], $00
	ld l, $04
	set 0, [hl]
L4C60:
	ld a, [de]
	inc de
	cp $FF
	ret z
	cp $6A
	ret z
	jr L4C60
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
	db "(Music & Sound Driver by Alberto Jose Gonzalez, 2001)"
Pat_4CC9:
	LEN 48
	WAIT
	PAT_GOTO Pat_4CC9

; Song 2: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong2:
	call StopAll
	ld de, Song2_Ch3
	call L49F8
	ld de, Song2_Ch2
	call L49F4
	ld de, Song2_Ch1
	call L49F0
	ld a, $6E
	ld [wInstrTableHi], a
	ld a, $E0
	ld [wInstrTable], a
	ret
Song2_Ch3:
	dw Pat_4D18
	dw Pat_4D1E
	dw Pat_4D4F
	dw Pat_4D80
	dw Pat_4DB1
	ORDER_LOOP Song2_Ch3
Song2_Ch2:
	dw Pat_4DFA
	dw Pat_4E42
	dw Pat_4E74
	dw Pat_4EA7
	dw Pat_4EB1
	ORDER_LOOP Song2_Ch2
Song2_Ch1:
	dw Pat_4EBB
	dw Pat_4EF6
	dw Pat_4F3C
	dw Pat_4F82
	dw Pat_4FC8
	ORDER_LOOP Song2_Ch1
Pat_4D18:
	LEN 9
	VOLENV 15, $11, $1F, $12
	INSTR 12
Pat_4D1E:
	NOTE G_, 2
	WAIT
	WAIT
	NOTE G_, 3
	WAIT
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE F_, 3
	WAIT
	NOTE D_, 2
	NOTE G_, 2
	WAIT
	WAIT
	NOTE G_, 3
	WAIT
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE F_, 3
	WAIT
	NOTE D_, 2
	NOTE G_, 2
	WAIT
	WAIT
	NOTE G_, 3
	WAIT
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE F_, 3
	WAIT
	NOTE D_, 2
	NOTE G_, 2
	WAIT
	WAIT
	NOTE G_, 3
	WAIT
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE F_, 3
	WAIT
	NOTE D_, 2
	NEXT
Pat_4D4F:
	NOTE G_, 2
	WAIT
	WAIT
	NOTE G_, 3
	WAIT
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE F_, 3
	WAIT
	NOTE D_, 2
	NOTE G_, 2
	WAIT
	WAIT
	NOTE G_, 3
	WAIT
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE F_, 3
	WAIT
	NOTE D_, 2
	NOTE G_, 2
	WAIT
	WAIT
	NOTE G_, 3
	WAIT
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE F_, 3
	WAIT
	NOTE D_, 2
	NOTE G_, 2
	WAIT
	WAIT
	NOTE G_, 3
	WAIT
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE G_, 2
	NOTE Gsh, 2
	NOTE A_, 2
	NEXT
Pat_4D80:
	NOTE Ash, 2
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	NOTE Ash, 2
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	NOTE C_, 4
	WAIT
	NOTE F_, 2
	NOTE Ash, 2
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	NOTE Ash, 2
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	NOTE C_, 4
	WAIT
	NOTE F_, 2
	NOTE Ash, 2
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	NOTE Ash, 2
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	NOTE C_, 4
	WAIT
	NOTE F_, 2
	NOTE Ash, 2
	WAIT
	WAIT
	NOTE D_, 4
	NOTE Ash, 2
	NOTE D_, 4
	NOTE Gsh, 2
	WAIT
	NOTE Gsh, 2
	NOTE Dsh, 4
	NOTE Gsh, 2
	NOTE Dsh, 4
	NEXT
Pat_4DB1:
	NOTE Ash, 2
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	NOTE Ash, 2
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	NOTE C_, 4
	WAIT
	NOTE F_, 2
	NOTE Ash, 2
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	NOTE Ash, 2
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	NOTE C_, 4
	WAIT
	NOTE F_, 2
	NOTE Ash, 2
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	NOTE Ash, 2
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	NOTE C_, 4
	WAIT
	NOTE F_, 2
	NOTE Ash, 2
	WAIT
	WAIT
	NOTE D_, 4
	NOTE Ash, 2
	NOTE D_, 4
	NOTE Gsh, 2
	WAIT
	NOTE Gsh, 2
	NOTE C_, 4
	NOTE Gsh, 2
	NOTE C_, 4
	NEXT
Pat_4DE2:
	NOTE B_, 3
	NOTE G_, 3
	NOTE D_, 3
	ARP_INLINE $0C, $0C, $10, $10, $13, $13, ARP_LOOP
	NOTE F_, 3
	WAIT
	ARP_INLINE $0C, $0C, $10, $10, $15, $15, ARP_LOOP
	NOTE F_, 3
	WAIT
	NEXT
Pat_4DFA:
	LEN 9
	INSTR 9
	REPEAT 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE D_, 3
	ARP_INLINE $0C, $0C, $10, $10, $13, $13, ARP_LOOP
	NOTE F_, 3
	WAIT
	ARP_INLINE $0C, $0C, $10, $10, $15, $15, ARP_LOOP
	NOTE F_, 3
	WAIT
	ARP_OFF
	NOTE C_, 4
	NOTE A_, 3
	LEN 3
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 9
	NOTE C_, 4
	NOTE G_, 4
	REPEAT_END
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	ARP_INLINE $0C, $0C, $10, $10, $13, $13, ARP_LOOP
	NOTE F_, 4
	WAIT
	ARP_INLINE $0C, $0C, $10, $10, $15, $15, ARP_LOOP
	NOTE F_, 4
	WAIT
	ARP_OFF
	NOTE C_, 5
	NOTE A_, 4
	LEN 3
	NOTE E_, 5
	NOTE F_, 5
	LEN 3
	NOTE E_, 5
	LEN 9
	NOTE C_, 5
	NOTE G_, 4
	NEXT
Pat_4E42:
	INSTR 9
	NOTE G_, 2
	WAIT
	NOTE A_, 3
	NOTE B_, 3
	WAIT
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	WAIT
	NOTE D_, 2
	NOTE G_, 2
	WAIT
	NOTE A_, 3
	NOTE B_, 3
	WAIT
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	WAIT
	NOTE D_, 2
	NOTE G_, 2
	WAIT
	NOTE A_, 3
	NOTE B_, 3
	WAIT
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	WAIT
	NOTE D_, 2
	NOTE G_, 2
	WAIT
	NOTE A_, 3
	NOTE B_, 3
	WAIT
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE F_, 3
	NEXT
Pat_4E74:
	INSTR 9
	REPEAT 3
	PAT_CALL Pat_4DE2
	ARP_OFF
	NOTE C_, 4
	NOTE A_, 3
	LEN 3
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 9
	NOTE C_, 4
	NOTE G_, 4
	REPEAT_END
	PAT_CALL Pat_4DE2
	ARP_OFF
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE Csh, 4
	NEXT
Pat_4E8E:
	REPEAT 3
	NOTE Ash, 2
	NOTE F_, 4
	NOTE D_, 4
	LEN 3
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 9
	NOTE D_, 4
	NOTE Ash, 3
	NOTE F_, 2
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE Gsh, 3
	REPEAT_END
	NOTE Ash, 2
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	NEXT
Pat_4EA7:
	PAT_CALL Pat_4E8E
	NOTE Gsh, 2
	NOTE Gsh, 4
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Dsh, 4
	NOTE Gsh, 4
	NEXT
Pat_4EB1:
	PAT_CALL Pat_4E8E
	NOTE Gsh, 2
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE Dsh, 4
	NEXT
Pat_4EBB:
	LEN 9
	DRUMS $09, DrumPat_5013
	VIBRATO $12, $02, $04
	INSTR 6
	NOTE G_, 2
	WAIT
	WAIT
	NOTE B_, 3
	WAIT
	NOTE G_, 3
	NOTE D_, 2
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	NOTE A_, 3
	NOTE G_, 2
	WAIT
	WAIT
	NOTE B_, 3
	WAIT
	NOTE G_, 3
	NOTE D_, 2
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	NOTE A_, 3
	NOTE G_, 2
	WAIT
	WAIT
	NOTE B_, 3
	WAIT
	NOTE G_, 3
	NOTE D_, 2
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	NOTE A_, 3
	NOTE G_, 2
	WAIT
	WAIT
	NOTE B_, 3
	WAIT
	NOTE G_, 3
	NOTE D_, 2
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	NOTE A_, 3
	NEXT
Pat_4EF6:
	INSTR 6
	NOTE G_, 5
	WAIT
	INSTR 9
	NOTE F_, 3
	NOTE G_, 3
	WAIT
	INSTR 6
	NOTE F_, 5
	NOTE G_, 5
	WAIT
	INSTR 9
	NOTE F_, 3
	NOTE A_, 3
	WAIT
	INSTR 6
	NOTE F_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	LEN 3
	NOTE F_, 5
	NOTE G_, 5
	NOTE F_, 5
	LEN 9
	WAIT
	NOTE E_, 5
	WAIT
	NOTE C_, 5
	NOTE E_, 5
	LEN 3
	NOTE Dsh, 5
	LEN 6
	NOTE D_, 5
	LEN 9
	WAIT
	INSTR 9
	NOTE F_, 3
	NOTE G_, 3
	WAIT
	INSTR 6
	NOTE C_, 5
	LEN 3
	NOTE Csh, 5
	LEN 6
	NOTE D_, 5
	LEN 9
	WAIT
	INSTR 9
	NOTE F_, 3
	NOTE A_, 3
	WAIT
	INSTR 6
	NOTE C_, 5
	NOTE D_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE D_, 3
	NOTE D_, 4
	NOTE D_, 3
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	NEXT
Pat_4F3C:
	INSTR 6
	NOTE G_, 5
	WAIT
	INSTR 9
	NOTE F_, 3
	NOTE G_, 3
	WAIT
	INSTR 6
	NOTE F_, 5
	NOTE G_, 5
	WAIT
	INSTR 9
	NOTE F_, 3
	NOTE A_, 3
	WAIT
	INSTR 6
	NOTE F_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	LEN 3
	NOTE F_, 5
	NOTE G_, 5
	NOTE F_, 5
	LEN 9
	WAIT
	NOTE E_, 5
	WAIT
	NOTE C_, 5
	NOTE E_, 5
	LEN 3
	NOTE Dsh, 5
	LEN 6
	NOTE D_, 5
	LEN 9
	WAIT
	INSTR 9
	NOTE F_, 3
	NOTE G_, 3
	WAIT
	INSTR 6
	NOTE C_, 5
	LEN 3
	NOTE Csh, 5
	LEN 6
	NOTE D_, 5
	LEN 9
	WAIT
	INSTR 9
	NOTE F_, 3
	NOTE A_, 3
	WAIT
	INSTR 6
	NOTE C_, 5
	NOTE D_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE D_, 4
	NOTE D_, 3
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NEXT
Pat_4F82:
	INSTR 13
	NOTE F_, 5
	WAIT2
	LEN 3
	NOTE E_, 5
	NOTE Dsh, 5
	LEN 7
	NOTE D_, 5
	LEN 5
	WAIT2
	LEN 9
	WAIT
	NOTE F_, 5
	NOTE Dsh, 5
	WAIT
	NOTE C_, 5
	NOTE Gsh, 4
	WAIT2
	NOTE Ash, 4
	WAIT
	WAIT2
	NOTE F_, 4
	LEN 3
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	LEN 9
	NOTE C_, 5
	NOTE Ash, 4
	LEN 3
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE Dsh, 5
	LEN 9
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE F_, 5
	WAIT2
	LEN 3
	NOTE E_, 5
	NOTE Dsh, 5
	LEN 7
	NOTE D_, 5
	LEN 5
	WAIT2
	LEN 9
	WAIT
	NOTE F_, 5
	NOTE Dsh, 5
	WAIT
	NOTE C_, 5
	NOTE Gsh, 4
	WAIT2
	NOTE Ash, 4
	WAIT
	WAIT
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	WAIT
	WAIT
	NOTE C_, 5
	WAIT2
	NOTE C_, 5
	NEXT
Pat_4FC8:
	NOTE F_, 5
	WAIT2
	LEN 3
	NOTE E_, 5
	NOTE Dsh, 5
	LEN 7
	NOTE D_, 5
	LEN 5
	WAIT2
	LEN 9
	WAIT
	NOTE F_, 5
	NOTE Dsh, 5
	WAIT
	NOTE C_, 5
	NOTE Gsh, 4
	WAIT2
	NOTE Ash, 4
	WAIT
	WAIT2
	NOTE F_, 4
	LEN 3
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	LEN 9
	NOTE C_, 5
	NOTE Ash, 4
	LEN 3
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE Dsh, 5
	LEN 9
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE F_, 5
	WAIT2
	LEN 3
	NOTE E_, 5
	NOTE Dsh, 5
	LEN 7
	NOTE D_, 5
	LEN 5
	WAIT2
	LEN 9
	WAIT
	NOTE F_, 5
	NOTE Dsh, 5
	WAIT
	LEN 3
	NOTE Gsh, 4
	LEN 3
	NOTE C_, 5
	LEN 3
	NOTE Dsh, 5
	LEN 9
	NOTE Gsh, 5
	WAIT2
	NOTE Ash, 5
	WAIT
	WAIT
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	WAIT
	WAIT
	NOTE Gsh, 4
	WAIT2
	NOTE Gsh, 4
	NEXT
DrumPat_5013:
	db 1, 6, 6, 2, 6, 6, 1, 6
	db 6, 2, 6, 4, 1, 6, 6, 2
	db 6, 6, 1, 6, 6, 2, 6, 4
	db DRUM_LOOP

; Unreferenced (25 bytes)
	db $01, $06, $06, $02, $06, $06, $01, $06, $06, $02, $06, $04, $01, $06, $06, $02
	db $06, $06, $01, $08, $08, $02, $0A, $0A, $FF

; Song 3: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong3:
	call StopAll
	ld de, Song3_Ch3
	call L49F8
	ld de, Song3_Ch2
	call L49F4
	ld de, Song3_Ch1
	call L49F0
	ld a, $6E
	ld [wInstrTableHi], a
	ld a, $E0
	ld [wInstrTable], a
	ret
Song3_Ch3:
	dw Pat_5077

; Unreferenced (4 bytes)
	db $00, $00, $65, $50
Song3_Ch2:
	dw Pat_5091

; Unreferenced (4 bytes)
	db $00, $00, $6B, $50
Song3_Ch1:
	dw Pat_50B6

; Unreferenced (4 bytes)
	db $00, $00, $71, $50
Pat_5077:
	DRUMS $09, DrumPat_50C8
	INSTR 12
	LEN 27
	NOTE G_, 2
	LEN 18
	NOTE G_, 3
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE D_, 2
	LEN 9
	NOTE D_, 2
	LEN 18
	NOTE F_, 3
	LEN 9
	NOTE D_, 2
	LENGTH $3A
	NOTE G_, 2
	DRUMS_OFF
	PAT_GOTO Pat_4CC9
Pat_5091:
	INSTR 9
	LEN 9
	NOTE B_, 3
	NOTE G_, 3
	NOTE D_, 3
	ARP_INLINE $0C, $0C, $10, $10, $13, $13, ARP_LOOP
	NOTE F_, 3
	WAIT
	ARP_INLINE $0C, $0C, $10, $10, $15, $15, ARP_LOOP
	NOTE F_, 3
	WAIT
	ARP_OFF
	NOTE C_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 4
	LENGTH $75
	NOTE G_, 4
	PAT_GOTO Pat_4CC9
Pat_50B6:
	LEN 27
	REST
	INSTR 6
	ARP 1
	LEN 18
	NOTE B_, 3
	LEN 36
	NOTE G_, 3
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE F_, 4
	LENGTH $75
	NOTE G_, 4
	PAT_GOTO Pat_4CC9
DrumPat_50C8:
	db 1, 6, 6, 2, 6, 6, 1, 6
	db 6, 2, 6, 4, 7, 0, 0, 0
	db 0, 0, 0, 0, 0, 0, 0, 0
	db DRUM_LOOP

; Song 4: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong4:
	call StopAll
	ld de, Song4_Ch3
	call L49F8
	ld de, Song4_Ch2
	call L49F4
	ld de, Song4_Ch1
	call L49F0
	ld a, $6E
	ld [wInstrTableHi], a
	ld a, $E0
	ld [wInstrTable], a
	ret
Song4_Ch3:
	dw Pat_5119
	dw Pat_5142
	ORDER_LOOP Song4_Ch3
Song4_Ch2:
	dw Pat_516B
	dw Pat_5185
	ORDER_LOOP Song4_Ch2
Song4_Ch1:
	dw Pat_51A6
	dw Pat_51EC
	ORDER_LOOP Song4_Ch1
Pat_5119:
	INSTR 12
	LEN 18
	NOTE Fsh, 2
	INSTR 4
	NOTE Fsh, 4
	INSTR 12
	NOTE Csh, 2
	INSTR 4
	LEN 12
	NOTE Fsh, 4
	INSTR 12
	LEN 18
	NOTE Fsh, 2
	INSTR 4
	LEN 6
	NOTE Fsh, 4
	INSTR 12
	LEN 18
	NOTE Csh, 2
	NOTE Fsh, 2
	NOTE F_, 2
	NOTE E_, 2
	INSTR 4
	NOTE E_, 4
	INSTR 12
	NOTE B_, 2
	INSTR 4
	LEN 12
	NOTE E_, 4
	INSTR 12
	LEN 18
	NOTE E_, 2
	INSTR 4
	LEN 6
	NOTE E_, 4
	INSTR 12
	LEN 18
	NOTE E_, 2
	NOTE E_, 2
	NOTE Dsh, 2
	NEXT
Pat_5142:
	INSTR 12
	LEN 18
	NOTE D_, 2
	INSTR 4
	NOTE D_, 4
	INSTR 12
	NOTE A_, 2
	INSTR 4
	LEN 12
	NOTE D_, 4
	INSTR 12
	LEN 18
	NOTE D_, 2
	INSTR 4
	LEN 6
	NOTE D_, 4
	INSTR 12
	LEN 18
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE Csh, 2
	INSTR 4
	NOTE Csh, 4
	INSTR 12
	NOTE Gsh, 2
	INSTR 4
	LEN 12
	NOTE Csh, 4
	INSTR 12
	LEN 18
	NOTE Csh, 2
	INSTR 4
	LEN 6
	NOTE Csh, 4
	INSTR 12
	LEN 18
	NOTE Csh, 2
	NOTE Dsh, 2
	NOTE F_, 2
	NEXT
Pat_516B:
	LEN 18
	WAIT
	INSTR 6
	NOTE Fsh, 4
	NOTE Gsh, 4
	LEN 12
	NOTE Ash, 4
	LENGTH $36
	NOTE Csh, 4
	LEN 6
	NOTE Fsh, 4
	LEN 12
	NOTE Gsh, 4
	LEN 6
	NOTE Ash, 4
	LEN 18
	NOTE Ash, 4
	NOTE B_, 4
	NOTE Gsh, 4
	LEN 12
	NOTE Fsh, 4
	LENGTH $4E
	NOTE Gsh, 4
	NEXT
Pat_5185:
	LEN 18
	WAIT
	INSTR 6
	LEN 12
	NOTE A_, 4
	LEN 6
	NOTE Gsh, 4
	LEN 12
	NOTE Fsh, 4
	LEN 24
	NOTE D_, 4
	LEN 12
	NOTE A_, 4
	LEN 6
	NOTE Gsh, 4
	LEN 12
	NOTE Fsh, 4
	LEN 6
	NOTE D_, 4
	LEN 12
	NOTE Fsh, 4
	LEN 6
	NOTE Gsh, 4
	LEN 18
	NOTE A_, 4
	LEN 36
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE F_, 4
	LEN 18
	NOTE Dsh, 4
	NOTE Csh, 4
	NEXT
Pat_51A6:
	DRUMS $06, DrumPat_522E
	INSTR 9
	LEN 12
	NOTE Fsh, 4
	LEN 6
	NOTE Csh, 4
	LEN 12
	NOTE Ash, 3
	LEN 6
	NOTE Fsh, 4
	LEN 12
	NOTE Csh, 4
	LEN 6
	NOTE Ash, 3
	LEN 12
	NOTE Fsh, 4
	LEN 6
	NOTE Csh, 4
	LEN 12
	NOTE Ash, 3
	LEN 6
	NOTE Fsh, 4
	LEN 12
	NOTE Csh, 4
	LEN 6
	NOTE Ash, 3
	LEN 12
	NOTE Fsh, 4
	LEN 6
	NOTE Csh, 4
	LEN 12
	NOTE Ash, 3
	LEN 6
	NOTE Fsh, 4
	LEN 12
	NOTE E_, 4
	LEN 6
	NOTE B_, 3
	LEN 12
	NOTE Gsh, 3
	LEN 6
	NOTE E_, 4
	LEN 12
	NOTE B_, 3
	LEN 6
	NOTE Gsh, 3
	LEN 12
	NOTE E_, 4
	LEN 6
	NOTE B_, 3
	LEN 12
	NOTE Gsh, 3
	LEN 6
	NOTE E_, 4
	LEN 12
	NOTE B_, 3
	LEN 6
	NOTE Gsh, 3
	LEN 12
	NOTE E_, 4
	LEN 6
	NOTE B_, 3
	LEN 12
	NOTE Gsh, 3
	LEN 6
	NOTE E_, 4
	NEXT
Pat_51EC:
	INSTR 9
	LEN 12
	NOTE D_, 4
	LEN 6
	NOTE A_, 3
	LEN 12
	NOTE Fsh, 3
	LEN 6
	NOTE D_, 4
	LEN 12
	NOTE A_, 3
	LEN 6
	NOTE Fsh, 3
	LEN 12
	NOTE D_, 4
	LEN 6
	NOTE A_, 3
	LEN 12
	NOTE Fsh, 3
	LEN 6
	NOTE D_, 4
	LEN 12
	NOTE A_, 3
	LEN 6
	NOTE Fsh, 3
	LEN 12
	NOTE D_, 4
	LEN 6
	NOTE A_, 3
	LEN 12
	NOTE Fsh, 3
	LEN 6
	NOTE D_, 4
	LEN 12
	NOTE Csh, 4
	LEN 6
	NOTE Gsh, 3
	LEN 12
	NOTE F_, 3
	LEN 6
	NOTE Csh, 4
	LEN 12
	NOTE Gsh, 3
	LEN 6
	NOTE F_, 3
	LEN 12
	NOTE Csh, 4
	LEN 6
	NOTE Gsh, 3
	LEN 12
	NOTE F_, 3
	LEN 6
	NOTE Csh, 4
	LEN 12
	NOTE Fsh, 3
	LEN 6
	NOTE Dsh, 4
	LEN 12
	NOTE G_, 3
	LEN 6
	NOTE E_, 4
	LEN 12
	NOTE Gsh, 3
	LEN 6
	NOTE F_, 4
	NEXT
DrumPat_522E:
	db 1, 0, 6, 2, 0, 6, DRUM_LOOP

; Song 5: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong5:
	call StopAll
	ld de, Song5_Ch3
	call L49F8
	ld de, Song5_Ch2
	call L49F4
	ld de, Song5_Ch1
	call L49F0
	ld a, $6E
	ld [wInstrTableHi], a
	ld a, $E0
	ld [wInstrTable], a
	ret
Song5_Ch3:
	dw Pat_5267

; Unreferenced (4 bytes)
	db $00, $00, $55, $52
Song5_Ch2:
	dw Pat_5291

; Unreferenced (4 bytes)
	db $00, $00, $5B, $52
Song5_Ch1:
	dw Pat_52C3

; Unreferenced (4 bytes)
	db $00, $00, $61, $52
Pat_5267:
	INSTR 12
	LEN 16
	NOTE G_, 2
	INSTR 5
	NOTE G_, 3
	NOTE G_, 3
	INSTR 12
	NOTE G_, 2
	NOTE A_, 2
	NOTE Ash, 2
	NOTE C_, 3
	INSTR 5
	NOTE C_, 4
	NOTE C_, 4
	INSTR 12
	NOTE C_, 3
	INSTR 5
	NOTE C_, 4
	NOTE C_, 4
	INSTR 12
	NOTE D_, 3
	INSTR 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 12
	NOTE D_, 2
	INSTR 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 12
	LEN 24
	NOTE G_, 2
	LEN 8
	NOTE D_, 2
	NOTE E_, 2
	NOTE Fsh, 2
	LENGTH $B0
	NOTE G_, 2
	PAT_GOTO Pat_4CC9
Pat_5291:
	INSTR 9
	LEN 8
	NOTE G_, 3
	NOTE Ash, 3
	NOTE D_, 4
	NOTE Ash, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE Fsh, 5
	NOTE D_, 5
	NOTE A_, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	LENGTH $B0
	NOTE G_, 4
	PAT_GOTO Pat_4CC9
Pat_52C3:
	DRUMS $08, DrumPat_52FC
	VIBRATO $10, $02, $04
	INSTR 13
	DUTY_50
	LEN 40
	NOTE G_, 5
	GLISS_1
	LEN 8
	WAIT2
	LEN 32
	NOTE A_, 5
	ARP 3
	LEN 16
	NOTE Gsh, 5
	ARP_OFF
	LEN 40
	NOTE A_, 5
	LEN 8
	WAIT
	LEN 40
	NOTE G_, 5
	LEN 8
	WAIT2
	LEN 16
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE C_, 5
	LEN 24
	NOTE Ash, 4
	LEN 8
	NOTE A_, 4
	LEN 8
	NOTE Ash, 4
	WAIT2
	LEN 40
	GLISS_OFF
	NOTE G_, 4
	LEN 8
	WAIT2
	DRUMS $FF, DrumPat_5303
	NOTE G_, 3
	LENGTH $A8
	WAIT2
	DRUMS_OFF
	PAT_GOTO Pat_4CC9
DrumPat_52FC:
	db 1, 0, 4, 0, 4, 0, DRUM_LOOP
DrumPat_5303:
	db 7, DRUM_LOOP

; Song 6: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong6:
	call StopAll
	ld de, Song6_Ch2
	call L49F4
	ld de, Song6_Ch3
	call L49F8
	ld de, Song6_Ch1
	call L49F0
	ld a, $55
	ld [wInstrTableHi], a
	ld a, $38
	ld [wInstrTable], a
	ret
Song6_Ch1:
	dw Pat_5337
	ORDER_LOOP Song6_Ch1
Song6_Ch3:
	dw Pat_53EC
	ORDER_LOOP Song6_Ch3
Song6_Ch2:
	dw Pat_5470
	ORDER_LOOP Song6_Ch2
Pat_5337:
	DRUMS $07, DrumPat_5508
	TRANSPOSE $03
	INSTR 0
	LEN 42
	NOTE A_, 1
	LEN 7
	NOTE A_, 2
	NOTE A_, 2
	LENGTH $38
	NOTE A_, 2
	LEN 14
	NOTE D_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	NOTE D_, 2
	LEN 42
	NOTE A_, 1
	LEN 7
	NOTE A_, 2
	NOTE A_, 2
	LENGTH $38
	NOTE A_, 2
	LEN 14
	NOTE D_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	LEN 7
	NOTE D_, 2
	NOTE Csh, 2
	DRUMS $07, DrumPat_5518
	LEN 14
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 3
	NOTE F_, 2
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE Gsh, 2
	LEN 14
	NOTE A_, 2
	INSTR 1
	NOTE A_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE A_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE A_, 4
	INSTR 0
	NOTE E_, 2
	NOTE A_, 2
	NOTE D_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	NOTE D_, 2
	NOTE E_, 2
	INSTR 1
	NOTE E_, 4
	INSTR 0
	NOTE B_, 2
	INSTR 1
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE E_, 4
	INSTR 0
	NOTE B_, 2
	INSTR 1
	NOTE E_, 4
	DRUMS $07, DrumPat_5529
	INSTR 0
	NOTE A_, 2
	LEN 7
	NOTE A_, 2
	NOTE Ash, 2
	LEN 14
	NOTE A_, 2
	NOTE Ash, 2
	NOTE A_, 2
	INSTR 1
	NOTE A_, 4
	INSTR 0
	LEN 28
	NOTE A_, 1
	NEXT
Pat_53EC:
	INSTR 3
	VIBRATO $07, $02, $04
	LEN 7
	NOTE E_, 4
	NOTE Dsh, 4
	LENGTH $31
	NOTE E_, 4
	REST
	LENGTH $38
	NOTE E_, 4
	NOTE F_, 4
	LEN 7
	NOTE E_, 4
	NOTE Dsh, 4
	LENGTH $62
	NOTE E_, 4
	LEN 42
	NOTE E_, 4
	LEN 7
	NOTE F_, 4
	NOTE G_, 4
	LENGTH $31
	NOTE F_, 4
	LEN 7
	NOTE D_, 4
	LEN 7
	NOTE Csh, 4
	LEN 14
	NOTE C_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE Ash, 4
	LEN 21
	NOTE Ash, 4
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE Ash, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE G_, 3
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE E_, 4
	LEN 21
	NOTE C_, 5
	LEN 7
	NOTE Ash, 4
	NOTE A_, 4
	INSTR 4
	LEN 14
	NOTE G_, 5
	LEN 7
	NOTE F_, 5
	WAIT2
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	WAIT2
	INSTR 3
	NOTE A_, 4
	NOTE Ash, 4
	LEN 7
	NOTE A_, 4
	WAIT
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	INSTR 5
	LEN 14
	NOTE Csh, 4
	LEN 21
	NOTE Csh, 5
	INSTR 3
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	INSTR 5
	LEN 14
	NOTE F_, 4
	LEN 21
	NOTE F_, 5
	INSTR 3
	LEN 14
	NOTE A_, 3
	NOTE F_, 4
	NOTE D_, 4
	LEN 21
	NOTE E_, 4
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 28
	NOTE D_, 4
	NOTE Csh, 4
	LENGTH $31
	NOTE E_, 4
	NEXT
Pat_5470:
	VIBRATO $0E, $02, $04
	INSTR 7
	LEN 7
	NOTE A_, 4
	GLISS_3
	NOTE Gsh, 4
	LENGTH $31
	NOTE A_, 4
	LEN 21
	WAIT2
	LEN 7
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 42
	NOTE Csh, 4
	LEN 14
	WAIT2
	LEN 42
	NOTE D_, 4
	LEN 14
	WAIT2
	LEN 7
	NOTE A_, 4
	NOTE Gsh, 4
	LENGTH $31
	NOTE A_, 4
	LEN 7
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE E_, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	LEN 42
	NOTE Csh, 4
	LEN 14
	WAIT2
	LEN 35
	NOTE D_, 4
	LEN 7
	WAIT2
	INSTR 6
	NOTE D_, 4
	NOTE Csh, 4
	LEN 14
	NOTE C_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE Ash, 4
	LEN 21
	NOTE Ash, 4
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE Ash, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE G_, 3
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE E_, 4
	LEN 21
	NOTE C_, 5
	LEN 7
	NOTE Ash, 4
	LEN 14
	NOTE A_, 4
	INSTR 7
	NOTE Ash, 5
	LEN 7
	NOTE A_, 5
	WAIT2
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE A_, 4
	WAIT2
	INSTR 6
	LEN 14
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	NOTE F_, 4
	LEN 14
	NOTE E_, 4
	INSTR 8
	GLISS_OFF
	NOTE A_, 4
	GLISS_3
	NOTE A_, 5
	INSTR 6
	GLISS_OFF
	NOTE G_, 4
	GLISS_3
	NOTE G_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE E_, 4
	LEN 14
	NOTE D_, 4
	INSTR 8
	GLISS_OFF
	NOTE A_, 4
	GLISS_3
	NOTE A_, 5
	INSTR 6
	GLISS_OFF
	NOTE A_, 3
	GLISS_3
	NOTE F_, 4
	NOTE D_, 4
	LEN 21
	NOTE E_, 4
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 28
	NOTE D_, 4
	NOTE Csh, 4
	LENGTH $38
	NOTE E_, 4
	NEXT
DrumPat_5508:
	db 1, 0, 0, 0, 0, 0, 2, 2
	db 2, 0, 0, 0, 0, 0, 0, 0
DrumPat_5518:
	db 1, 0, 2, 0, 1, 0, 2, 0
	db 1, 0, 2, 0, 1, 0, 2, 0
	db DRUM_LOOP
DrumPat_5529:
	db 2, 0, 2, 2, 2, 0, 2, 0
	db 2, 0, 0, 0, 7, 0, 0, 0
	db DRUM_LOOP

; Instrument table 1, entries 1..9 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr1_0
	dw Instr1_1
	dw Instr1_2
	dw Instr1_3
	dw Instr1_4
	dw Instr1_4
	dw Instr1_6
	dw Instr1_7
	dw Instr1_8
Instr1_0:
	HWENV $F1, $07, $63
	ARP_INLINE $0C, $00, ARP_HOLD
	END
Instr1_1:
	HWENV $C2, $04, $72
	ARP 4
	AUTODUTY $03
	END
Instr1_2:
	HWENV $C2, $04, $72
	ARP 5
	AUTODUTY $03
	END
Instr1_3:
	VOLENV 10, $11, $15, $11
	WAVE Wave_7604
	END
Instr1_4:
	VOLENV 15, $11, $1F, $12
	WAVE Wave_75E4
	END
Instr1_6:
	RELEASE $00
	HWENV $F1, $09, $40
	ARP_INLINE $0C, $0C, $00, $00, ARP_LOOP
	DUTY_75
	END
Instr1_7:
	HWENV $59, $04, $C0
	RELEASE $01, $A1
	END
Instr1_8:
	HWENV $F1, $00
	END

; Song 7: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong7:
	call StopAll
	ld de, Song7_Ch2
	call L49F4
	ld de, Song7_Ch1
	call L49F0
	ld de, Song7_Ch3
	call L49F8
	ld a, $6E
	ld [wInstrTableHi], a
	ld a, $E0
	ld [wInstrTable], a
	ret
Song7_Ch3:
	dw Pat_55EB
Loop_55B1:
	dw Pat_55FC
	dw Pat_55FC
	dw Pat_55FC
	dw Pat_55FC
	dw Pat_5627
	dw Pat_562F
	dw Pat_564B
	ORDER_LOOP Loop_55B1
Song7_Ch1:
	dw Pat_567B
Loop_55C5:
	dw Pat_56C4
	dw Pat_56F5
	dw Pat_56C4
	dw Pat_56F5
	dw Pat_576B
	dw Pat_577E
	dw Pat_578D
	ORDER_LOOP Loop_55C5
Song7_Ch2:
	dw Pat_57D6
Loop_55D9:
	dw Pat_5809
	dw Pat_5809
	dw Pat_5809
	dw Pat_5809
	dw Pat_5873
	dw Pat_588A
	dw Pat_589F
	ORDER_LOOP Loop_55D9
Pat_55EB:
	INSTR 12
	LEN 40
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	LEN 20
	NOTE C_, 2
	NOTE C_, 3
	LEN 10
	NOTE C_, 2
	NOTE C_, 2
	NOTE Csh, 2
	NOTE E_, 2
	NEXT
Pat_55FC:
	LEN 10
	REPEAT 2
	INSTR 12
	NOTE F_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 12
	NOTE C_, 2
	INSTR 5
	NOTE F_, 4
	REPEAT_END
	REPEAT 2
	INSTR 12
	NOTE Fsh, 2
	INSTR 4
	NOTE Fsh, 4
	INSTR 12
	NOTE Csh, 2
	INSTR 4
	NOTE Fsh, 4
	REPEAT_END
	NEXT
Pat_5612:
	REPEAT 2
	INSTR 12
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 12
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	REPEAT_END
	REPEAT 2
	INSTR 12
	NOTE F_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 12
	NOTE F_, 3
	INSTR 5
	NOTE F_, 4
	REPEAT_END
	NEXT
Pat_5627:
	LEN 10
	PAT_CALL Pat_5612
	PAT_CALL Pat_5612
	NEXT
Pat_562F:
	PAT_CALL Pat_5612
	REPEAT 2
	INSTR 12
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 12
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	REPEAT_END
	INSTR 12
	NOTE F_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 12
	NOTE F_, 3
	INSTR 5
	NOTE F_, 4
	INSTR 12
	NOTE F_, 2
	NOTE C_, 3
	NOTE F_, 2
	INSTR 5
	NOTE F_, 4
	NEXT
Pat_564B:
	LEN 10
	REPEAT 2
	INSTR 12
	NOTE Fsh, 2
	INSTR 4
	NOTE Fsh, 4
	INSTR 12
	NOTE Csh, 2
	INSTR 4
	NOTE Fsh, 4
	REPEAT_END
	INSTR 12
	NOTE F_, 2
	INSTR 5
	NOTE F_, 5
	NOTE F_, 5
	INSTR 12
	NOTE C_, 2
	INSTR 5
	NOTE F_, 5
	NOTE F_, 5
	INSTR 12
	NOTE F_, 2
	INSTR 5
	NOTE F_, 5
	REPEAT 2
	INSTR 12
	NOTE Fsh, 2
	INSTR 4
	NOTE Fsh, 4
	INSTR 12
	NOTE Csh, 2
	INSTR 4
	NOTE Fsh, 4
	REPEAT_END
	INSTR 12
	LEN 15
	NOTE C_, 3
	LEN 5
	NOTE G_, 2
	LEN 10
	NOTE E_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE Csh, 2
	NOTE E_, 2
	NEXT
Pat_567B:
	HWENV $F0, $00
	RELEASE $01, $57
	DUTY_75
	VIBRATO $05, $02, $04
	LEN 15
	NOTE C_, 4
	LEN 5
	WAIT2
	NOTE G_, 3
	WAIT2
	NOTE Gsh, 3
	WAIT2
	LEN 20
	NOTE Ash, 3
	LEN 5
	NOTE Gsh, 3
	WAIT2
	NOTE G_, 3
	WAIT2
	LEN 20
	NOTE C_, 4
	LEN 5
	NOTE G_, 3
	WAIT2
	NOTE Gsh, 3
	WAIT2
	NOTE Ash, 3
	WAIT2
	LEN 10
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE Gsh, 3
	LEN 15
	NOTE C_, 4
	LEN 5
	WAIT2
	NOTE G_, 3
	WAIT2
	NOTE Gsh, 3
	WAIT2
	LEN 20
	NOTE Ash, 3
	LEN 5
	NOTE Gsh, 3
	WAIT2
	NOTE G_, 3
	WAIT2
	LEN 15
	NOTE C_, 4
	LEN 5
	NOTE Csh, 4
	NOTE C_, 4
	WAIT2
	NOTE Csh, 4
	WAIT2
	LEN 10
	NOTE C_, 4
	LEN 5
	NOTE Ash, 3
	WAIT2
	LEN 10
	NOTE G_, 3
	LEN 5
	NOTE Gsh, 3
	WAIT2
	NEXT
Pat_56C4:
	HWENV $C0, $00
	DUTY_50
	RELEASE $01, $57
	ARP 0
	LEN 10
	NOTE G_, 4
	LEN 5
	NOTE Gsh, 4
	WAIT2
	LEN 10
	NOTE E_, 4
	LEN 5
	NOTE F_, 4
	WAIT2
	LEN 10
	NOTE B_, 3
	LEN 5
	NOTE C_, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	NOTE Gsh, 4
	WAIT2
	ARP_OFF
	HWENV $A0, $00
	DUTY_75
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Csh, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE F_, 4
	NEXT
Pat_56F5:
	HWENV $C0, $00
	DUTY_50
	RELEASE $01, $57
	ARP_INLINE $0C, $00, $00, $0C, $00, ARP_HOLD
	LEN 10
	NOTE G_, 4
	LEN 5
	NOTE Gsh, 4
	WAIT2
	LEN 10
	NOTE E_, 4
	LEN 5
	NOTE F_, 4
	WAIT2
	LEN 10
	NOTE B_, 3
	LEN 5
	NOTE C_, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	NOTE Gsh, 4
	WAIT2
	HWENV $A0, $00
	DUTY_75
	ARP_OFF
	ARP_INLINE $0C, $00, ARP_LOOP
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Csh, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE F_, 4
	ARP_OFF
	NEXT
Pat_5731:
	LEN 10
	NOTE C_, 4
	GLISS_3
	WAIT2
	NOTE C_, 5
	WAIT2
	LEN 5
	NOTE Fsh, 4
	WAIT2
	LEN 15
	NOTE G_, 4
	LEN 5
	WAIT2
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	WAIT2
	NOTE B_, 4
	NOTE C_, 5
	NOTE Gsh, 4
	WAIT2
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	WAIT2
	NOTE E_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE Gsh, 3
	LEN 15
	NOTE E_, 4
	LEN 5
	WAIT2
	LEN 15
	NOTE Ash, 4
	LEN 5
	WAIT2
	NOTE Fsh, 4
	WAIT2
	LEN 10
	NOTE G_, 4
	WAIT2
	LEN 5
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	WAIT2
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	WAIT2
	NOTE B_, 4
	NOTE C_, 5
	NOTE F_, 5
	WAIT2
	NEXT
Pat_576B:
	HWENV $A0, $00
	RELEASE $51, $47
	DUTY_50
	GLISS_3
	PAT_CALL Pat_5731
	GLISS_OFF
	NOTE E_, 5
	NOTE F_, 5
	NOTE Gsh, 5
	NOTE Ash, 5
	NOTE Gsh, 5
	NOTE F_, 5
	NEXT
Pat_577E:
	ARP_INLINE $0C, $00, ARP_HOLD
	DUTY_75
	PAT_CALL Pat_5731
	GLISS_OFF
	NOTE E_, 5
	WAIT2
	NOTE C_, 5
	LEN 15
	WAIT2
	NEXT
Pat_578D:
	GLISS_OFF
	ARP_INLINE $00, $0C, $00, ARP_HOLD
	HWENV $B1, $00
	DUTY_12
	RELEASE $00
	LEN 5
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Csh, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE F_, 4
	LEN 10
	NOTE Gsh, 5
	NOTE Gsh, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE F_, 5
	LEN 5
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Csh, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	LEN 10
	NOTE E_, 5
	LEN 5
	NOTE C_, 4
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NEXT
Pat_57D6:
	DRUMS $05, DrumPat_58D9
	VIBRATO $05, $02, $04
	ARP_INLINE $00, $0C, $00, ARP_HOLD
	HWENV $B1, $00
	DUTY_12
	LEN 5
	REPEAT 8
	NOTE C_, 4
	NOTE Csh, 4
	REPEAT_END
	REPEAT 8
	NOTE C_, 5
	NOTE Csh, 5
	REPEAT_END
	REPEAT 4
	NOTE C_, 4
	NOTE Csh, 4
	REPEAT_END
	REPEAT 4
	NOTE C_, 5
	NOTE Csh, 5
	REPEAT_END
	NOTE C_, 5
	NOTE B_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Csh, 4
	NOTE D_, 4
	NOTE E_, 4
	NEXT
Pat_5809:
	DRUMS $05, DrumPat_58D9
	RELEASE $00
	ARP_INLINE $00, $0C, $00, ARP_HOLD
	HWENV $A1, $00
	DUTY_12
	LEN 5
	REPEAT 3
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	REPEAT_END
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	ARP_OFF
	HWENV $A0, $00
	DUTY_75
	NOTE Fsh, 4
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	NEXT
Pat_5839:
	LEN 10
	NOTE C_, 5
	GLISS_3
	WAIT2
	NOTE C_, 6
	WAIT2
	LEN 5
	NOTE Fsh, 5
	WAIT2
	LEN 15
	NOTE G_, 5
	LEN 5
	WAIT2
	NOTE Gsh, 5
	NOTE Ash, 5
	NOTE Gsh, 5
	WAIT2
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE F_, 5
	WAIT2
	NOTE E_, 5
	NOTE F_, 5
	NOTE C_, 5
	WAIT2
	NOTE B_, 4
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	LEN 15
	NOTE C_, 4
	LEN 5
	WAIT2
	LEN 15
	NOTE Csh, 5
	LEN 5
	WAIT2
	NOTE A_, 4
	WAIT2
	LEN 10
	NOTE Ash, 4
	WAIT2
	LEN 5
	NOTE C_, 5
	NOTE Csh, 5
	NOTE C_, 5
	WAIT2
	NOTE B_, 4
	NOTE C_, 5
	NOTE F_, 5
	WAIT2
	NOTE E_, 5
	NOTE F_, 5
	NOTE Gsh, 5
	WAIT2
	NEXT
Pat_5873:
	DRUMS $05, DrumPat_58D9
	HWENV $A0, $00
	RELEASE $51, $47
	DUTY_50
	PAT_CALL Pat_5839
	GLISS_OFF
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE C_, 6
	NOTE Csh, 6
	NOTE C_, 6
	NOTE Gsh, 5
	GLISS_OFF
	NEXT
Pat_588A:
	DUTY_75
	ARP_INLINE $0C, $00, ARP_HOLD
	PAT_CALL Pat_5839
	LEN 10
	GLISS_OFF
	NOTE G_, 5
	LEN 5
	NOTE F_, 5
	HWENV $D0, $00
	NOTE C_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	ARP_OFF
	NEXT
Pat_589F:
	DRUMS $05, DrumPat_58F4
	LEN 5
	NOTE Fsh, 4
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	LENGTH $32
	NOTE C_, 4
	LEN 10
	WAIT2
	NOTE Gsh, 4
	LEN 5
	NOTE F_, 4
	WAIT2
	NOTE Fsh, 4
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 40
	NOTE C_, 5
	LEN 10
	WAIT2
	LEN 5
	NOTE C_, 3
	NOTE Csh, 3
	NOTE C_, 3
	NOTE Csh, 3
	NOTE Dsh, 3
	NOTE E_, 3
	NEXT
DrumPat_58D9:
	db 7, 0, 0, 0, 2, 0, 5, 6
	db DRUM_REPEAT + 6, 1, 0, 5, 6, 2, 0, 5
	db 6, DRUM_REPEAT_END, 1, 0, 5, 6, 2, 0
	db 2, 2, DRUM_LOOP
DrumPat_58F4:
	db 7, 0, 0, 0, 2, 0, 5, 6
	db 1, 0, 5, 6, 2, 0, 5, 6
	db 1, 0, 2, 0, 2, 0, 1, 0
	db 2, 0, 2, 0, 1, 0, 2, 0
	db 7, 0, 0, 0, 2, 0, 5, 6
	db 1, 0, 5, 6, 2, 0, 5, 6
	db 2, 0, 2, 2, 2, 0, 2, 0
	db 2, 0, 2, 0, 2, 0, 2, 2
	db DRUM_LOOP

; Song 8: instrument table 2, arpeggio table 1 (the one SndInit sets)
PlaySong8:
	call StopAll
	ld de, Song8_Ch2
	call L49F4
	ld de, Song8_Ch1
	call L49F0
	ld de, Song8_Ch3
	call L49F8
	ld a, $5E
	ld [wInstrTableHi], a
	ld a, $6E
	ld [wInstrTable], a
	ret
Song8_Ch3:
	dw Pat_5991
	dw Pat_59B6
	dw Pat_59EF
	dw Pat_5A24
	dw Pat_5A6E
	dw Pat_59B6
	dw Pat_5A9E
	dw Pat_5AB5
	ORDER_LOOP Song8_Ch3
Song8_Ch1:
	dw Pat_5B28
	dw Pat_5B88
	dw Pat_5BA1
	dw Pat_5BB6
	dw Pat_5BEF
	dw Pat_5B88
	dw Pat_5C2C
	dw Pat_5DD1
	ORDER_LOOP Song8_Ch1
Song8_Ch2:
	dw Pat_5C9C
	dw Pat_5CD5
	dw Pat_5D09
	dw Pat_5D41
	dw Pat_5D75
	dw Pat_5CD5
	dw Pat_5DAE
	dw Pat_5C75
	ORDER_LOOP Song8_Ch2
Pat_5991:
	DRUMS $07, DrumPat_5E02
	LEN 42
	WAIT
	INSTR 0
	LEN 14
	NOTE C_, 2
	LENGTH $38
	NOTE F_, 2
	NOTE Ash, 2
	NOTE C_, 3
	DRUMS $07, DrumPat_5E23
	LEN 14
	REPEAT 3
	INSTR 0
	NOTE F_, 2
	INSTR 2
	NOTE F_, 3
	INSTR 0
	NOTE C_, 2
	INSTR 2
	NOTE F_, 3
	REPEAT_END
	INSTR 0
	NOTE F_, 2
	INSTR 2
	NOTE F_, 3
	INSTR 0
	NOTE C_, 2
	NOTE Dsh, 2
	NEXT
Pat_59B6:
	DRUMS $07, DrumPat_5E23
	LEN 14
	REPEAT 2
	INSTR 0
	NOTE F_, 2
	INSTR 2
	NOTE F_, 3
	INSTR 0
	NOTE C_, 2
	INSTR 2
	NOTE F_, 3
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE Gsh, 2
	INSTR 1
	NOTE Gsh, 3
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Gsh, 3
	REPEAT_END
	INSTR 0
	NOTE Csh, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE Gsh, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE F_, 2
	INSTR 2
	NOTE F_, 3
	INSTR 0
	NOTE C_, 2
	INSTR 2
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 2
	NOTE F_, 3
	INSTR 0
	NOTE C_, 2
	NOTE Dsh, 2
	NEXT
Pat_59EF:
	LEN 14
	REPEAT 2
	INSTR 0
	NOTE F_, 2
	INSTR 2
	NOTE F_, 3
	INSTR 0
	NOTE C_, 2
	INSTR 2
	NOTE F_, 3
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE Gsh, 2
	INSTR 1
	NOTE Gsh, 3
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Gsh, 3
	REPEAT_END
	INSTR 0
	NOTE Csh, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE Gsh, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE F_, 2
	INSTR 2
	NOTE F_, 3
	INSTR 0
	NOTE C_, 2
	INSTR 2
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 2
	NOTE F_, 3
	INSTR 0
	NOTE C_, 2
	NOTE Dsh, 2
	NEXT
Pat_5A24:
	INSTR 0
	NOTE Gsh, 2
	INSTR 1
	NOTE Gsh, 3
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Gsh, 3
	INSTR 0
	NOTE Gsh, 2
	INSTR 1
	LEN 7
	NOTE Gsh, 3
	NOTE Gsh, 3
	INSTR 0
	LEN 14
	NOTE Dsh, 2
	INSTR 1
	NOTE Gsh, 3
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	INSTR 0
	LEN 14
	NOTE Ash, 2
	NOTE Dsh, 2
	NOTE F_, 2
	INSTR 2
	NOTE F_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 2
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 2
	LEN 7
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	LEN 14
	NOTE C_, 3
	INSTR 2
	NOTE F_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 2
	NOTE C_, 5
	INSTR 0
	NOTE G_, 2
	INSTR 2
	NOTE C_, 5
	INSTR 0
	NOTE C_, 3
	INSTR 2
	LEN 7
	NOTE C_, 5
	NOTE C_, 5
	INSTR 0
	LEN 14
	NOTE G_, 2
	NOTE C_, 3
	NEXT
Pat_5A6E:
	LEN 14
	REPEAT 2
	INSTR 0
	NOTE Csh, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE Gsh, 2
	INSTR 1
	NOTE Csh, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE Gsh, 2
	INSTR 1
	NOTE Gsh, 4
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Gsh, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 4
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE Ash, 4
	REPEAT_END
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	NEXT
Pat_5A9E:
	DRUMS $07, DrumPat_5E46
	INSTR 0
	REPEAT 3
	LEN 42
	NOTE F_, 2
	LEN 14
	NOTE C_, 2
	LENGTH $38
	NOTE F_, 2
	REPEAT_END
	LEN 42
	NOTE F_, 2
	LEN 14
	NOTE C_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE C_, 2
	NEXT
Pat_5AB5:
	DRUMS $07, DrumPat_5E23
	INSTR 0
	LEN 14
	NOTE F_, 2
	INSTR 2
	LEN 7
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	LEN 14
	NOTE C_, 2
	INSTR 2
	LEN 7
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	LEN 14
	NOTE F_, 2
	INSTR 2
	LEN 7
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	LEN 14
	NOTE C_, 3
	INSTR 2
	LEN 7
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	LEN 14
	NOTE F_, 2
	INSTR 1
	LEN 7
	NOTE Gsh, 4
	NOTE Gsh, 4
	INSTR 0
	LEN 14
	NOTE C_, 2
	INSTR 1
	LEN 7
	NOTE Gsh, 4
	NOTE Gsh, 4
	INSTR 0
	LEN 14
	NOTE F_, 2
	INSTR 1
	LEN 7
	NOTE Gsh, 4
	NOTE Gsh, 4
	INSTR 0
	LEN 14
	NOTE C_, 3
	INSTR 1
	LEN 7
	NOTE Gsh, 4
	NOTE Gsh, 4
	INSTR 0
	LEN 14
	NOTE G_, 2
	INSTR 1
	LEN 7
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	LEN 14
	NOTE D_, 2
	INSTR 1
	LEN 7
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	LEN 14
	NOTE G_, 2
	INSTR 1
	LEN 7
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	LEN 14
	NOTE D_, 3
	INSTR 1
	LEN 7
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	LEN 14
	NOTE Fsh, 2
	INSTR 1
	LEN 7
	NOTE Fsh, 4
	NOTE Fsh, 4
	INSTR 0
	LEN 14
	NOTE Csh, 2
	INSTR 1
	LEN 7
	NOTE Fsh, 4
	NOTE Fsh, 4
	INSTR 0
	DRUMS $07, DrumPat_5E67
	LEN 14
	NOTE Fsh, 2
	LEN 7
	NOTE Fsh, 2
	NOTE Fsh, 2
	LEN 28
	NOTE Fsh, 2
	NEXT
Pat_5B28:
	VIBRATO $0E, $01, $04
	LEN 14
	WAIT
	INSTR 7
	LEN 7
	NOTE C_, 5
	NOTE Ash, 4
	LEN 14
	NOTE C_, 5
	INSTR 8
	ARP 5
	LEN 7
	NOTE F_, 4
	NOTE F_, 4
	LEN 28
	NOTE F_, 4
	INSTR 7
	LEN 7
	NOTE F_, 4
	NOTE G_, 4
	LEN 14
	NOTE Gsh, 4
	INSTR 8
	ARP 5
	LEN 21
	NOTE Ash, 4
	INSTR 7
	NOTE Ash, 4
	LEN 14
	NOTE G_, 4
	INSTR 8
	ARP 5
	LEN 21
	NOTE C_, 5
	INSTR 7
	NOTE Dsh, 4
	LEN 14
	NOTE C_, 4
	INSTR 3
	LEN 7
	REPEAT 8
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Gsh, 3
	REPEAT_END
	NEXT
Pat_5B5A:
	INSTR 3
	LEN 7
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE F_, 3
	NOTE Gsh, 3
	INSTR 4
	NOTE F_, 5
	NOTE Gsh, 5
	LEN 42
	NOTE C_, 6
	LEN 14
	WAIT2
	INSTR 3
	LEN 7
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE C_, 4
	INSTR 4
	NOTE Gsh, 5
	NOTE C_, 6
	LEN 28
	NOTE Dsh, 6
	WAIT2
	INSTR 3
	LEN 14
	NOTE Gsh, 3
	LEN 7
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE G_, 3
	LEN 14
	NOTE F_, 3
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE F_, 3
	NEXT
Pat_5B88:
	VIBRATO $0E, $01, $04
	PAT_CALL Pat_5B5A
	LEN 14
	NOTE Dsh, 3
	NOTE F_, 3
	LEN 7
	NOTE Gsh, 3
	NOTE F_, 3
	LEN 14
	NOTE C_, 3
	NOTE Dsh, 3
	NOTE F_, 3
	LEN 7
	NOTE Gsh, 3
	NOTE F_, 3
	NOTE C_, 3
	NOTE Dsh, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NEXT
Pat_5BA1:
	PAT_CALL Pat_5B5A
	LEN 14
	NOTE Dsh, 3
	NOTE F_, 3
	LEN 7
	NOTE Gsh, 4
	NOTE F_, 4
	LEN 14
	NOTE C_, 4
	NOTE Dsh, 4
	LEN 21
	NOTE F_, 4
	INSTR 6
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE Gsh, 3
	NOTE Ash, 3
	NEXT
Pat_5BB6:
	INSTR 6
	LEN 21
	NOTE C_, 4
	LEN 7
	NOTE Ash, 3
	LEN 14
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE C_, 4
	LEN 21
	NOTE Ash, 3
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE G_, 3
	INSTR 4
	LEN 7
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE G_, 5
	WAIT2
	INSTR 6
	LEN 14
	NOTE Dsh, 3
	LEN 21
	NOTE Gsh, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE C_, 4
	INSTR 4
	NOTE G_, 4
	LEN 21
	NOTE Dsh, 5
	LEN 7
	NOTE D_, 5
	NOTE C_, 5
	WAIT2
	NOTE G_, 4
	WAIT2
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE C_, 4
	WAIT2
	NEXT
Pat_5BEF:
	INSTR 6
	LEN 21
	NOTE Csh, 4
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	LEN 21
	NOTE C_, 4
	LEN 7
	NOTE Gsh, 3
	LEN 14
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE Gsh, 4
	INSTR 4
	LEN 7
	NOTE C_, 5
	NOTE Csh, 5
	NOTE C_, 5
	WAIT2
	LEN 14
	NOTE Gsh, 4
	INSTR 6
	LEN 21
	NOTE D_, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE G_, 4
	INSTR 4
	LEN 7
	NOTE G_, 5
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE G_, 5
	WAIT2
	INSTR 6
	LEN 14
	NOTE E_, 4
	INSTR 4
	LEN 7
	NOTE Ash, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE Ash, 5
	WAIT2
	NEXT
Pat_5C2C:
	INSTR 8
	ARP 5
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	NOTE F_, 4
	ARP 4
	NOTE Gsh, 4
	LEN 7
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 14
	NOTE Gsh, 4
	LEN 7
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 14
	NOTE Gsh, 4
	LEN 7
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 14
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	LEN 7
	NOTE Fsh, 4
	NOTE Fsh, 4
	LEN 14
	NOTE Fsh, 4
	LEN 7
	NOTE Fsh, 4
	NOTE Fsh, 4
	LEN 14
	NOTE Fsh, 4
	LEN 7
	NOTE Fsh, 4
	NOTE Fsh, 4
	LEN 14
	NOTE Fsh, 4
	NOTE Fsh, 4
	NEXT
Pat_5C75:
	INSTR 5
	LEN 42
	NOTE F_, 3
	GLISS_2
	LEN 14
	NOTE C_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE C_, 4
	LEN 28
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE Gsh, 3
	LEN 14
	NOTE C_, 4
	NOTE Dsh, 4
	LEN 28
	NOTE D_, 4
	NOTE B_, 3
	LEN 14
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE B_, 3
	LEN 28
	NOTE Csh, 4
	NOTE Fsh, 4
	LEN 14
	NOTE Ash, 4
	INSTR 8
	GLISS_OFF
	ARP 4
	LEN 7
	NOTE Fsh, 4
	NOTE Fsh, 4
	LEN 28
	NOTE Fsh, 4
	NEXT
Pat_5C9C:
	VIBRATO $0E, $02, $04
	INSTR 5
	DUTY_75
	LEN 7
	NOTE C_, 5
	NOTE Ash, 4
	LEN 42
	NOTE C_, 5
	LEN 14
	WAIT2
	LEN 7
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	WAIT2
	NOTE C_, 5
	WAIT2
	LEN 28
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	LENGTH $5B
	NOTE F_, 4
	LEN 21
	WAIT2
	DUTY_50
	RELEASE $00
	HWENV $A0, $01, $12
	LEN 14
	NOTE F_, 5
	LEN 7
	NOTE C_, 6
	NOTE F_, 5
	LEN 14
	NOTE F_, 5
	LEN 7
	NOTE C_, 6
	NOTE F_, 5
	LEN 14
	NOTE F_, 5
	LEN 7
	NOTE C_, 6
	NOTE F_, 5
	LEN 14
	NOTE F_, 5
	INSTR 5
	NOTE C_, 4
	NEXT
Pat_5CD5:
	INSTR 5
	LEN 14
	NOTE F_, 4
	LEN 7
	WAIT2
	NOTE F_, 4
	LEN 42
	NOTE C_, 5
	LEN 14
	WAIT2
	LEN 7
	NOTE F_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	LEN 14
	NOTE Gsh, 4
	LEN 7
	WAIT2
	NOTE Gsh, 4
	LEN 42
	NOTE Dsh, 5
	LEN 7
	NOTE Dsh, 5
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE Gsh, 4
	WAIT2
	LEN 28
	NOTE Csh, 4
	LEN 7
	NOTE Gsh, 4
	WAIT2
	NOTE Csh, 4
	WAIT2
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Ash, 4
	WAIT2
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	WAIT2
	LENGTH $54
	NOTE F_, 4
	LEN 14
	WAIT2
	NOTE C_, 4
	NEXT
Pat_5D09:
	INSTR 5
	LEN 7
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	LEN 42
	NOTE C_, 5
	LEN 14
	WAIT2
	LEN 7
	NOTE F_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE Gsh, 4
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE C_, 5
	LEN 42
	NOTE Dsh, 5
	LEN 7
	NOTE Dsh, 5
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE Gsh, 4
	WAIT2
	LEN 28
	NOTE Csh, 4
	LEN 7
	NOTE Gsh, 4
	WAIT2
	NOTE Csh, 4
	WAIT2
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Ash, 4
	WAIT2
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	WAIT2
	LENGTH $38
	NOTE F_, 4
	LEN 21
	WAIT2
	INSTR 6
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE F_, 4
	NOTE G_, 4
	NEXT
Pat_5D41:
	INSTR 6
	LEN 21
	NOTE Gsh, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	LEN 21
	NOTE G_, 4
	LEN 7
	NOTE Gsh, 4
	LEN 14
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	INSTR 4
	LEN 7
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE Dsh, 5
	WAIT2
	INSTR 6
	LEN 14
	NOTE C_, 4
	LEN 21
	NOTE F_, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE Dsh, 4
	INSTR 4
	NOTE G_, 3
	LEN 21
	NOTE G_, 5
	LEN 7
	NOTE F_, 5
	NOTE Dsh, 5
	LENGTH $31
	WAIT2
	NEXT
Pat_5D75:
	INSTR 6
	LEN 21
	NOTE F_, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 21
	NOTE Dsh, 4
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE C_, 5
	INSTR 4
	LEN 7
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	WAIT2
	LEN 14
	NOTE Dsh, 4
	INSTR 6
	LEN 21
	NOTE Ash, 4
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 21
	NOTE Ash, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE G_, 4
	NOTE Ash, 4
	NOTE C_, 5
	INSTR 4
	LEN 7
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	WAIT2
	NEXT
Pat_5DAE:
	GLISS_2
	INSTR 5
	LEN 42
	NOTE F_, 4
	LEN 14
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	LEN 28
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE Gsh, 4
	LEN 14
	NOTE C_, 5
	NOTE Dsh, 5
	LEN 28
	NOTE D_, 5
	NOTE B_, 4
	LEN 14
	NOTE G_, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE B_, 4
	NOTE Csh, 5
	NOTE Ash, 4
	LEN 28
	NOTE Fsh, 4
	LEN 14
	WAIT2
	NOTE Csh, 4
	NOTE Ash, 3
	NOTE Fsh, 3
	NEXT
Pat_5DD1:
	VIBRATO $07, $02, $04
	INSTR 4
	LEN 7
	NOTE C_, 5
	GLISS_2
	NOTE F_, 5
	NOTE C_, 5
	NOTE F_, 5
	LENGTH $46
	NOTE C_, 5
	LEN 14
	WAIT2
	LEN 7
	NOTE Dsh, 5
	NOTE Gsh, 5
	NOTE Dsh, 5
	NOTE Gsh, 5
	LENGTH $46
	NOTE Dsh, 5
	LEN 14
	WAIT2
	LEN 7
	NOTE D_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE G_, 5
	LENGTH $46
	NOTE D_, 5
	LEN 14
	WAIT2
	LEN 7
	NOTE Csh, 5
	NOTE Fsh, 5
	NOTE Csh, 5
	NOTE Fsh, 5
	LEN 14
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Csh, 5
	LEN 42
	WAIT2
	GLISS_OFF
	NEXT
DrumPat_5E02:
	db 0, 0, 0, 0, 0, 0, 1, 1
	db 7, 0, 0, 0, 0, 0, 0, 0
	db 2, 0, 0, 0, 0, 0, 0, 0
	db 2, 0, 0, 0, 0, 0, 0, 0
	db DRUM_LOOP
DrumPat_5E23:
	db 7, 0, 0, 0, 2, 0, 5, 6
	db 1, 0, 5, 6, 2, 5, 5, 6
	db DRUM_REPEAT + 7, 1, 0, 5, 6, 2, 0, 5
	db 6, 1, 0, 5, 6, 2, 5, 5
	db 6, DRUM_REPEAT_END, DRUM_LOOP
DrumPat_5E46:
	db 11, 0, 13, 12, 11, 0, 13, 12
	db 11, 0, 13, 12, 11, 0, 11, 0
	db 11, 0, 13, 12, 11, 0, 13, 12
	db 11, 0, 13, 12, 11, 12, 12, 12
	db DRUM_LOOP
DrumPat_5E67:
	db 2, 0, 2, 2, 7, 0, 0, 0
	db DRUM_LOOP

; Instrument table 2, entries 1..9 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr2_0
	dw Instr2_1
	dw Instr2_2
	dw Instr2_3
	dw Instr2_4
	dw Instr2_5
	dw Instr2_6
	dw Instr2_7
	dw Instr2_8
Instr2_0:
	ARP 0
	VOLENV 13, $11, $1F, $13
	WAVE Wave_7604
	END
Instr2_1:
	VOLENV 15, $01, $1F, $11
	ARP 14
	WAVE Wave_7624
	END
Instr2_2:
	VOLENV 15, $01, $1F, $11
	ARP 15
	WAVE Wave_7624
	END
Instr2_3:
	DUTY_12
	ARP 6
	HWENV $C1, $02, $64
	END
Instr2_4:
	HWENV $59, $03, $80
	DUTY_50
	RELEASE $01, $82
	END
Instr2_5:
	HWENV $F1, $04, $B0
	RELEASE $01, $92
	END
Instr2_6:
	ARP 6
	HWENV $F2, $06, $93
	DUTY_12
	END
Instr2_7:
	HWENV $40, $00
	DUTY_75
	END
Instr2_8:
	HWENV $F1, $04, $84
	DUTY_50
	END

; Song 9: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong9:
	call StopAll
	ld de, Song9_Ch2
	call L49F4
	ld de, Song9_Ch1
	call L49F0
	ld de, Song9_Ch3
	call L49F8
	ld a, $63
	ld [wInstrTableHi], a
	ld a, $DC
	ld [wInstrTable], a
	ret
Pat_5EE7:
	TRANSPOSE $01
	NEXT
Pat_5EEA:
	TRANSPOSE $02
	NEXT
Song9_Ch3:
	dw Pat_5EE7
	dw Pat_5F5F
	dw Pat_5F5F
	dw Pat_5EE7
	dw Pat_5FA4
Loop_5EF7:
	dw Pat_5FD5
	dw Pat_5FFB
	dw Pat_5FD5
	dw Pat_5FFB
	dw Pat_601F
	dw Pat_6045
	dw Pat_601F
	dw Pat_6045
	dw Pat_5FA4
	dw Pat_5EEA
	dw Pat_5F9D
	dw Pat_5FD5
	dw Pat_5FFB
	dw Pat_5FD5
	dw Pat_5FFB
	dw Pat_601F
	dw Pat_6045
	dw Pat_601F
	dw Pat_6045
	dw Pat_5FA4
	dw Pat_5EE7
	dw Pat_5F9D
	ORDER_LOOP Loop_5EF7
Song9_Ch1:
	dw Pat_6069
	dw Pat_6069
Loop_5F2B:
	dw Pat_60B1
	dw Pat_60E3
	dw Pat_613A
	dw Pat_60E3
	dw Pat_613A
	dw Pat_6188
	dw Pat_61D0
	dw Pat_6188
	dw Pat_61D0
	dw Pat_60B1
	ORDER_LOOP Loop_5F2B
Song9_Ch2:
	dw Pat_6216
	dw Pat_6216
Loop_5F47:
	dw Pat_6248
	dw Pat_627C
	dw Pat_6297
	dw Pat_627C
	dw Pat_6297
	dw Pat_62B8
	dw Pat_62DF
	dw Pat_62B8
	dw Pat_62DF
	dw Pat_6248
	ORDER_LOOP Loop_5F47
Pat_5F5F:
	DRUMS $06, DrumPat_6303
	VOLENV 15, $11, $1A, $12
	RELEASE $01, $50
	VIBRATO $0C, $04, $04
	ARP_INLINE $0C, $00, ARP_HOLD
	WAVE Wave_7634
	LEN 12
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	LEN 6
	NOTE G_, 2
	NOTE G_, 3
	LEN 12
	NOTE E_, 2
	NOTE F_, 2
	NOTE Fsh, 2
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	LEN 6
	NOTE G_, 2
	NOTE G_, 3
	LEN 12
	NOTE Gsh, 2
	NOTE A_, 2
	NOTE B_, 2
	NEXT
Pat_5F9D:
	DRUMS $06, DrumPat_63C9
	PAT_GOTO Pat_5FA8
Pat_5FA4:
	DRUMS $06, DrumPat_6388
Pat_5FA8:
	LEN 12
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	LEN 24
	NOTE Ash, 2
	LEN 12
	NOTE Ash, 2
	NOTE Ash, 2
	LEN 24
	NOTE F_, 2
	LEN 12
	NOTE F_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE Fsh, 2
	LEN 6
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 2
	LEN 12
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	LEN 24
	NOTE Ash, 2
	LEN 12
	NOTE Ash, 3
	NOTE Ash, 2
	LEN 24
	NOTE F_, 2
	LEN 12
	NOTE F_, 3
	NOTE F_, 2
	NOTE Fsh, 2
	NOTE G_, 2
	NOTE G_, 3
	LEN 6
	NOTE B_, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE G_, 3
	NEXT
Pat_5FD5:
	DRUMS $06, DrumPat_6308
	LEN 12
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NEXT
Pat_5FFB:
	LEN 12
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	LEN 24
	NOTE G_, 2
	LEN 12
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	LEN 24
	NOTE G_, 2
	LEN 12
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NEXT
Pat_601F:
	DRUMS $06, DrumPat_636D
	LEN 12
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NEXT
Pat_6045:
	LEN 12
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	LEN 24
	NOTE G_, 2
	LEN 12
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
	LEN 24
	NOTE G_, 2
	LEN 12
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NEXT
Pat_6069:
	VIBRATO $0E, $01, $04
	INSTR 0
	LEN 12
	NOTE G_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	LEN 6
	NOTE G_, 2
	NOTE G_, 3
	LEN 12
	NOTE E_, 2
	INSTR 3
	NOTE A_, 4
	NOTE A_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	LEN 6
	NOTE G_, 2
	NOTE G_, 3
	INSTR 3
	LEN 12
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NEXT
Pat_60B1:
	INSTR 6
	LEN 12
	NOTE C_, 4
	GLISS_2
	NOTE C_, 4
	NOTE C_, 4
	LEN 24
	NOTE Ash, 3
	LEN 12
	NOTE Ash, 3
	NOTE Ash, 3
	LEN 24
	NOTE F_, 3
	LEN 12
	NOTE F_, 3
	NOTE F_, 3
	LEN 24
	NOTE G_, 3
	INSTR 3
	LEN 12
	GLISS_OFF
	NOTE C_, 5
	LEN 6
	NOTE Gsh, 4
	NOTE Fsh, 4
	LEN 12
	NOTE F_, 4
	INSTR 6
	NOTE E_, 4
	GLISS_2
	NOTE E_, 4
	NOTE E_, 4
	LEN 24
	NOTE D_, 4
	LEN 12
	NOTE D_, 4
	NOTE D_, 4
	LEN 24
	NOTE A_, 4
	LEN 12
	NOTE A_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE B_, 4
	INSTR 3
	GLISS_OFF
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NEXT
Pat_60E3:
	LEN 6
	WAIT
	INSTR 0
	NOTE E_, 4
	INSTR 4
	LEN 12
	NOTE C_, 4
	INSTR 0
	NOTE E_, 4
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE E_, 4
	INSTR 4
	NOTE C_, 4
	INSTR 0
	LEN 6
	NOTE F_, 4
	NOTE E_, 4
	INSTR 4
	LEN 12
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 4
	NOTE C_, 4
	INSTR 0
	LEN 6
	NOTE C_, 4
	NOTE G_, 3
	INSTR 4
	LEN 12
	NOTE C_, 4
	INSTR 0
	LEN 6
	NOTE G_, 3
	NOTE C_, 4
	INSTR 4
	LEN 12
	NOTE C_, 4
	INSTR 0
	LEN 6
	NOTE C_, 4
	NOTE E_, 4
	INSTR 4
	LEN 12
	NOTE C_, 4
	INSTR 0
	LEN 6
	NOTE E_, 4
	NOTE D_, 4
	INSTR 4
	LEN 12
	NOTE D_, 4
	INSTR 0
	NOTE D_, 4
	INSTR 4
	NOTE D_, 4
	INSTR 0
	NOTE D_, 4
	INSTR 4
	NOTE D_, 4
	INSTR 0
	LEN 6
	NOTE E_, 4
	NOTE D_, 4
	INSTR 4
	LEN 12
	NOTE D_, 4
	INSTR 0
	LEN 6
	NOTE D_, 3
	NOTE A_, 3
	INSTR 6
	NOTE Fsh, 4
	NOTE G_, 4
	LEN 12
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	INSTR 4
	NOTE D_, 4
	INSTR 6
	NOTE A_, 3
	INSTR 4
	NOTE D_, 4
	NEXT
Pat_613A:
	LEN 6
	WAIT
	INSTR 0
	NOTE Gsh, 4
	INSTR 4
	NOTE Gsh, 4
	INSTR 0
	LEN 18
	NOTE Gsh, 4
	INSTR 4
	LEN 6
	NOTE Gsh, 4
	INSTR 0
	LEN 18
	NOTE Ash, 4
	INSTR 4
	LEN 12
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE G_, 4
	INSTR 0
	NOTE G_, 4
	INSTR 4
	NOTE G_, 4
	INSTR 0
	LEN 6
	NOTE G_, 4
	NOTE F_, 4
	INSTR 4
	LEN 12
	NOTE G_, 4
	INSTR 0
	LEN 6
	NOTE F_, 4
	NOTE E_, 4
	INSTR 4
	LEN 12
	NOTE G_, 4
	INSTR 0
	LEN 6
	NOTE E_, 4
	NOTE D_, 4
	INSTR 4
	LEN 12
	NOTE G_, 4
	INSTR 0
	LEN 6
	NOTE D_, 4
	NOTE E_, 4
	INSTR 4
	LEN 12
	NOTE C_, 4
	INSTR 0
	NOTE G_, 4
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 4
	NOTE C_, 4
	INSTR 0
	LEN 6
	NOTE C_, 5
	NOTE G_, 4
	INSTR 5
	LEN 12
	NOTE G_, 4
	INSTR 0
	NOTE Ash, 4
	INSTR 5
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NEXT
Pat_6188:
	INSTR 2
	LEN 12
	NOTE Gsh, 3
	INSTR 4
	NOTE C_, 4
	INSTR 2
	NOTE Gsh, 3
	INSTR 4
	NOTE C_, 4
	INSTR 2
	NOTE Gsh, 3
	INSTR 4
	NOTE C_, 4
	INSTR 2
	NOTE Gsh, 3
	INSTR 4
	NOTE C_, 4
	INSTR 2
	NOTE Gsh, 3
	INSTR 4
	NOTE C_, 4
	INSTR 2
	NOTE Gsh, 3
	INSTR 4
	NOTE C_, 4
	INSTR 2
	NOTE Gsh, 3
	INSTR 4
	NOTE C_, 4
	INSTR 2
	NOTE Gsh, 3
	INSTR 4
	LEN 6
	NOTE C_, 4
	INSTR 2
	NOTE Gsh, 3
	LEN 12
	NOTE Gsh, 3
	INSTR 4
	NOTE D_, 4
	INSTR 2
	NOTE Gsh, 3
	INSTR 4
	NOTE D_, 4
	INSTR 2
	NOTE Gsh, 3
	INSTR 4
	NOTE D_, 4
	INSTR 2
	NOTE Gsh, 3
	INSTR 4
	NOTE D_, 4
	INSTR 2
	NOTE Gsh, 3
	INSTR 4
	NOTE D_, 4
	INSTR 2
	NOTE Gsh, 3
	INSTR 4
	NOTE D_, 4
	INSTR 2
	NOTE Gsh, 3
	INSTR 4
	NOTE D_, 4
	INSTR 2
	NOTE Gsh, 3
	INSTR 4
	LEN 6
	NOTE D_, 4
	INSTR 2
	NOTE Gsh, 3
	NEXT
Pat_61D0:
	LEN 12
	INSTR 2
	NOTE Gsh, 3
	INSTR 6
	NOTE Gsh, 4
	INSTR 2
	NOTE Gsh, 3
	INSTR 6
	NOTE Gsh, 4
	INSTR 2
	NOTE Gsh, 3
	INSTR 6
	NOTE Gsh, 4
	INSTR 2
	NOTE Gsh, 3
	INSTR 6
	NOTE G_, 4
	INSTR 2
	LEN 24
	NOTE Gsh, 3
	LEN 12
	NOTE Gsh, 3
	INSTR 0
	NOTE F_, 4
	INSTR 2
	NOTE Gsh, 3
	INSTR 0
	NOTE E_, 4
	INSTR 2
	NOTE Gsh, 3
	INSTR 0
	LEN 6
	NOTE D_, 4
	INSTR 2
	NOTE Gsh, 3
	LEN 12
	NOTE Gsh, 3
	INSTR 6
	NOTE Gsh, 4
	INSTR 2
	NOTE Gsh, 3
	INSTR 6
	NOTE Gsh, 4
	INSTR 2
	NOTE Gsh, 3
	INSTR 6
	NOTE Gsh, 4
	INSTR 2
	NOTE Gsh, 3
	INSTR 6
	NOTE B_, 4
	INSTR 2
	LEN 24
	NOTE Gsh, 3
	LEN 12
	NOTE Gsh, 3
	INSTR 0
	NOTE E_, 4
	INSTR 2
	NOTE Gsh, 3
	INSTR 0
	NOTE F_, 4
	INSTR 2
	NOTE Gsh, 3
	INSTR 0
	LEN 6
	NOTE G_, 4
	INSTR 2
	NOTE Gsh, 3
	NEXT
Pat_6216:
	VIBRATO $0E, $02, $04
	INSTR 6
	DUTY_50
	LEN 12
	NOTE G_, 5
	NOTE G_, 3
	NOTE G_, 4
	NOTE G_, 5
	NOTE F_, 5
	NOTE G_, 3
	NOTE G_, 4
	NOTE F_, 5
	NOTE E_, 5
	NOTE G_, 3
	NOTE G_, 4
	NOTE E_, 5
	LEN 24
	NOTE D_, 5
	INSTR 3
	LEN 12
	NOTE Ash, 4
	NOTE Ash, 4
	INSTR 6
	ARP_INLINE $0C, $0C, $00, $00, ARP_LOOP
	NOTE G_, 5
	NOTE G_, 3
	NOTE G_, 4
	NOTE G_, 5
	NOTE F_, 5
	NOTE G_, 3
	NOTE G_, 4
	NOTE F_, 5
	NOTE E_, 5
	NOTE G_, 3
	NOTE G_, 4
	NOTE E_, 5
	NOTE D_, 5
	INSTR 3
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NEXT
Pat_6248:
	INSTR 7
	ARP 4
	LEN 12
	NOTE C_, 5
	GLISS_3
	NOTE C_, 5
	NOTE C_, 5
	LEN 24
	NOTE Ash, 4
	LEN 12
	NOTE Ash, 4
	NOTE Ash, 4
	LEN 24
	NOTE F_, 4
	LEN 12
	NOTE F_, 4
	NOTE F_, 4
	LEN 24
	NOTE G_, 4
	INSTR 3
	GLISS_OFF
	LEN 12
	NOTE Csh, 5
	LEN 6
	NOTE Ash, 4
	NOTE Gsh, 4
	LEN 12
	NOTE Fsh, 4
	INSTR 7
	ARP 4
	NOTE C_, 5
	GLISS_3
	NOTE C_, 5
	NOTE C_, 5
	LEN 24
	NOTE Ash, 4
	LEN 12
	NOTE Ash, 4
	NOTE Ash, 4
	LEN 24
	NOTE F_, 5
	LEN 12
	NOTE F_, 5
	NOTE F_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	GLISS_OFF
	INSTR 3
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	NEXT
Pat_627C:
	INSTR 1
	LENGTH $3C
	NOTE E_, 4
	GLISS_3
	LEN 12
	NOTE F_, 4
	NOTE E_, 4
	LEN 36
	NOTE C_, 4
	LEN 24
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	LENGTH $3C
	NOTE D_, 4
	LEN 12
	NOTE E_, 4
	NOTE D_, 4
	NOTE D_, 3
	LENGTH $44
	NOTE A_, 3
	LEN 28
	WAIT2
	NEXT
Pat_6297:
	LEN 12
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 24
	NOTE Ash, 4
	LEN 12
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 36
	NOTE G_, 4
	LEN 24
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 6
	NOTE E_, 4
	NOTE F_, 4
	LENGTH $18
	NOTE G_, 4
	LEN 24
	NOTE C_, 4
	LEN 12
	NOTE C_, 5
	NOTE G_, 4
	LENGTH $50
	NOTE Ash, 4
	LEN 28
	WAIT2
	GLISS_OFF
	NEXT
Pat_62B8:
	INSTR 6
	DUTY_50
	LEN 12
	NOTE C_, 5
	NOTE G_, 3
	NOTE C_, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE C_, 4
	LEN 6
	NOTE C_, 5
	NOTE Csh, 5
	LEN 12
	NOTE D_, 5
	NOTE A_, 3
	NOTE D_, 4
	NOTE D_, 5
	NOTE C_, 5
	NOTE A_, 3
	NOTE D_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 3
	NEXT
Pat_62DF:
	INSTR 7
	ARP 4
	LEN 12
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 24
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 36
	NOTE G_, 4
	INSTR 1
	LEN 24
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	INSTR 7
	ARP 4
	LEN 12
	NOTE Gsh, 4
	GLISS_1
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	WAIT
	NOTE Gsh, 4
	LEN 36
	NOTE G_, 4
	GLISS_OFF
	INSTR 1
	LEN 24
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NEXT
DrumPat_6303:
	db 1, 0, 4, 0, DRUM_LOOP
DrumPat_6308:
	db 7, 0, 0, 0, 2, 0, 6, 0
	db 1, 0, 1, 0, 2, 0, 6, 0
	db DRUM_REPEAT + 2, 1, 0, 6, 0, 2, 0, 6
	db 0, 1, 0, 1, 0, 2, 0, 6
	db 0, DRUM_REPEAT_END, 1, 0, 6, 0, 2, 0
	db 6, 0, 1, 0, 1, 0, 2, 0
	db 2, 0, 7, 0, 0, 0, 2, 0
	db 6, 0, 1, 0, 1, 0, 2, 0
	db 6, 0, DRUM_REPEAT + 2, 1, 0, 6, 0, 2
	db 0, 6, 0, 1, 0, 1, 0, 2
	db 0, 6, 0, DRUM_REPEAT_END, 1, 0, 2, 0
	db 1, 0, 2, 0, 1, 0, 2, 0
	db 2, 0, 2, 0, DRUM_LOOP
DrumPat_636D:
	db 7, 0, 0, 0, 2, 0, 4, 0
	db 1, 0, 4, 0, 2, 0, 4, 0
	db DRUM_REPEAT + 6, 1, 0, 4, 0, 2, 0, 4
	db 0, DRUM_REPEAT_END, DRUM_LOOP
DrumPat_6388:
	db 2, 0, 2, 0, 2, 0, 2, 0
	db 0, 0, 2, 0, 2, 0, 2, 0
	db 0, 0, 2, 0, 2, 0, 2, 0
	db 0, 0, 9, 0, 9, 9, 9, 0
	db 2, 0, 2, 0, 2, 0, 2, 0
	db 0, 0, 2, 0, 2, 0, 2, 0
	db 0, 0, 2, 0, 2, 0, 2, 0
	db 2, 0, 9, 0, 9, 0, 9, 0
	db DRUM_LOOP
DrumPat_63C9:
	db DRUM_REPEAT + 7, 2, 0, 1, 0, DRUM_REPEAT_END, 2, 2
	db 1, 0, DRUM_REPEAT + 7, 2, 0, 1, 0, DRUM_REPEAT_END
	db 2, 2, 2, 2, DRUM_LOOP

; Instrument table 3, entries 1..8 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr3_0
	dw Instr3_1
	dw Instr3_2
	dw Instr3_3
	dw Instr3_4
	dw Instr3_5
	dw Instr3_6
	dw Instr3_7
Instr3_0:
	HWENV $40, $00
	END
Instr3_1:
	HWENV $F1, $06, $A0
	RELEASE $02, $67
	END
Instr3_2:
	ARP_INLINE $07, ARP_HOLD
	GLIDE $FC
	HWENV $F1, $07, $00
	END
Instr3_3:
	GLIDE $FF
	HWENV $C2, $00
	END
Instr3_4:
	HWENV $E1, $04, $63
	ARP 4
	DUTY_12
	END
Instr3_5:
	HWENV $E1, $04, $63
	ARP 5
	DUTY_12
	END
Instr3_6:
	ARP_INLINE $0C, $00, $00, $00, $00, $00, $00, ARP_LOOP
	HWENV $E1, $08, $50
	DUTY_75
	END
Instr3_7:
	HWENV $D2, $0E, $50
	RELEASE $01, $20
	END

; Song 10: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong10:
	call StopAll
	ld de, Song10_Ch2
	call L49F4
	ld de, Song10_Ch1
	call L49F0
	ld de, Song10_Ch3
	call L49F8
	ret
Song10_Ch3:
	dw Pat_648D
	dw Pat_64C8
	dw Pat_64F5
	dw Pat_6522
	dw Pat_654F
	dw Pat_64C8
	dw Pat_64F5
	dw Pat_6522
	dw Pat_654F
	dw Pat_648D
	ORDER_LOOP Song10_Ch3
Song10_Ch1:
	dw Pat_6580
	dw Pat_65A1
	dw Pat_65CB
	dw Pat_65EF
	dw Pat_6610
	dw Pat_65A1
	dw Pat_65CB
	dw Pat_65EF
	dw Pat_6610
	dw Pat_6580
	ORDER_LOOP Song10_Ch1
Song10_Ch2:
	dw Pat_6632
	dw Pat_6699
	dw Pat_66AF
	dw Pat_66C0
	dw Pat_66ED
	dw Pat_6699
	dw Pat_66AF
	dw Pat_66C0
	dw Pat_66ED
	dw Pat_6632
	ORDER_LOOP Song10_Ch2
Pat_648D:
	DRUMS $07, DrumPat_6714
	VOLENV 15, $11, $1F, $11
	ARP 0
	CH_TRANSPOSE $0C
	WAVE Wave_7654
	LEN 21
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	LEN 21
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	LEN 21
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	LEN 21
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NEXT
Pat_64C8:
	LEN 21
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	LEN 21
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	LEN 21
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	LEN 21
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NEXT
Pat_64F5:
	LEN 21
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	LEN 21
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	LEN 21
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	LEN 21
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NEXT
Pat_6522:
	LEN 21
	NOTE Ash, 2
	LEN 7
	NOTE Ash, 3
	LEN 14
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE Gsh, 2
	NOTE Gsh, 3
	LEN 21
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 3
	LEN 21
	NOTE C_, 2
	LEN 7
	NOTE C_, 3
	LEN 14
	NOTE Ash, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE Ash, 2
	NOTE C_, 3
	LEN 21
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 3
	NEXT
Pat_654F:
	LEN 21
	NOTE Ash, 2
	LEN 7
	NOTE Ash, 3
	LEN 14
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE Gsh, 2
	NOTE Gsh, 3
	LEN 21
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE C_, 2
	NOTE C_, 2
	LEN 28
	NOTE C_, 2
	DRUMS $64, DrumPat_6736
	LENGTH $38
	NOTE C_, 3
	DRUMS $07, DrumPat_6714
	LEN 21
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NEXT
Pat_6580:
	RELEASE $00
	ARP_OFF
	HWENV $D1, $01, $22
	DUTY_50
	VIBRATO $07, $01, $04
	LEN 14
	REST
	LEN 28
	NOTE F_, 5
	NOTE F_, 5
	NOTE F_, 5
	NOTE F_, 5
	NOTE F_, 5
	NOTE F_, 5
	NOTE F_, 5
	NOTE F_, 5
	NOTE F_, 5
	NOTE F_, 5
	NOTE F_, 5
	NOTE F_, 5
	NOTE F_, 5
	NOTE F_, 5
	NOTE F_, 5
	LEN 14
	NOTE F_, 5
	NEXT
Pat_65A1:
	LEN 14
	WAIT
	HWENV $B1, $06, $50
	RELEASE $71, $35
	DUTY_75
	ARP 5
	NOTE F_, 3
	REST
	NOTE F_, 3
	REST
	NOTE F_, 3
	REST
	NOTE F_, 3
	REST
	NOTE F_, 3
	REST
	NOTE F_, 3
	REST
	NOTE F_, 3
	REST
	NOTE F_, 3
	REST
	NOTE F_, 3
	REST
	NOTE F_, 3
	REST
	NOTE F_, 3
	REST
	NOTE F_, 3
	NOTE F_, 4
	NOTE F_, 4
	LENGTH $46
	NOTE F_, 4
	LEN 14
	WAIT2
	NEXT
Pat_65CB:
	LEN 14
	REST
	ARP 5
	NOTE F_, 3
	REST
	NOTE F_, 3
	REST
	NOTE F_, 3
	REST
	NOTE F_, 3
	REST
	NOTE F_, 3
	REST
	NOTE F_, 3
	REST
	NOTE F_, 3
	REST
	NOTE F_, 3
	REST
	NOTE F_, 3
	REST
	NOTE F_, 3
	REST
	NOTE F_, 3
	REST
	NOTE F_, 3
	NOTE F_, 4
	NOTE F_, 4
	LEN 42
	NOTE F_, 4
	LEN 14
	WAIT2
	NOTE F_, 4
	ARP 4
	NOTE Gsh, 4
	NEXT
Pat_65EF:
	ARP 4
	LENGTH $54
	NOTE Ash, 4
	LEN 28
	NOTE Gsh, 4
	ARP 5
	LENGTH $62
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	ARP 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 28
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	NOTE Dsh, 4
	ARP 5
	NOTE F_, 4
	NOTE F_, 4
	LENGTH $38
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	ARP 4
	NOTE Gsh, 4
	NEXT
Pat_6610:
	ARP 4
	LENGTH $54
	NOTE Ash, 4
	LEN 28
	NOTE Gsh, 4
	ARP 5
	LENGTH $62
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	ARP 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 28
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 42
	WAIT2
	ARP 5
	LEN 21
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	REST
	NOTE F_, 4
	REST
	NOTE F_, 4
	REST
	NOTE F_, 4
	NEXT
Pat_6632:
	ARP_OFF
	RELEASE $00
	HWENV $F1, $05, $71
	GLIDE $FF
	DUTY_50
	VIBRATO $07, $02, $04
	REPEAT 2
	LEN 21
	NOTE G_, 3
	LEN 7
	GLISS_3
	NOTE C_, 4
	LEN 14
	NOTE G_, 3
	NOTE C_, 4
	LEN 21
	NOTE G_, 3
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE G_, 3
	NOTE C_, 4
	LEN 21
	NOTE G_, 3
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE G_, 3
	NOTE C_, 4
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE C_, 4
	GLISS_OFF
	NOTE G_, 3
	REPEAT_END
	NEXT
Pat_6662:
	LEN 7
	NOTE F_, 4
	GLISS_1
	WAIT2
	NOTE F_, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	LEN 28
	NOTE Gsh, 4
	GLISS_3
	NOTE F_, 4
	LEN 7
	NOTE Dsh, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	LEN 35
	NOTE C_, 4
	LEN 14
	WAIT2
	LEN 7
	NOTE C_, 3
	LEN 14
	NOTE Dsh, 3
	NOTE C_, 3
	ARP_INLINE $0C, $0C, $00, $00, ARP_LOOP
	LEN 7
	NOTE F_, 3
	WAIT2
	NOTE F_, 3
	WAIT2
	NOTE F_, 3
	WAIT2
	NOTE F_, 3
	WAIT2
	LEN 28
	GLISS_1
	NOTE Gsh, 3
	LEN 7
	GLISS_3
	NOTE F_, 3
	WAIT2
	NOTE Dsh, 3
	WAIT2
	NOTE F_, 3
	WAIT2
	NEXT
Pat_6699:
	GLIDE_OFF
	HWENV $F1, $06, $80
	RELEASE $71, $82
	DUTY_75
	PAT_CALL Pat_6662
	NOTE F_, 3
	WAIT2
	LENGTH $38
	NOTE F_, 3
	GLISS_OFF
	LEN 28
	WAIT2
	ARP_OFF
	NEXT
Pat_66AF:
	PAT_CALL Pat_6662
	NOTE Gsh, 3
	WAIT2
	LEN 35
	NOTE F_, 3
	ARP_OFF
	LEN 7
	WAIT2
	NOTE F_, 3
	WAIT2
	LEN 14
	NOTE Gsh, 3
	NOTE C_, 4
	GLISS_OFF
	NEXT
Pat_66C0:
	LENGTH $46
	NOTE D_, 4
	LEN 14
	WAIT2
	LEN 28
	NOTE C_, 4
	LENGTH $54
	NOTE Gsh, 3
	LEN 14
	WAIT2
	NOTE C_, 4
	LEN 7
	NOTE Ash, 3
	WAIT2
	NOTE Ash, 3
	WAIT2
	GLISS_1
	NOTE C_, 4
	GLISS_3
	WAIT2
	NOTE Ash, 3
	WAIT2
	LEN 28
	NOTE G_, 3
	LEN 7
	NOTE F_, 3
	WAIT2
	NOTE Dsh, 3
	WAIT2
	LEN 14
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE F_, 3
	NOTE Dsh, 3
	LEN 7
	NOTE F_, 3
	WAIT2
	NOTE F_, 3
	WAIT2
	LEN 14
	NOTE Gsh, 3
	NOTE C_, 4
	NEXT
Pat_66ED:
	LENGTH $46
	NOTE D_, 4
	LEN 14
	WAIT2
	LEN 28
	NOTE Dsh, 4
	LENGTH $54
	NOTE C_, 4
	LEN 14
	WAIT2
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE F_, 3
	LEN 28
	NOTE Dsh, 3
	ARP_INLINE $0C, $0C, $00, $00, ARP_LOOP
	WAIT2
	LEN 7
	NOTE C_, 3
	WAIT2
	NOTE Dsh, 3
	WAIT2
	NOTE F_, 3
	NOTE Gsh, 3
	LENGTH $46
	NOTE F_, 3
	LEN 28
	WAIT2
	GLISS_OFF
	ARP_OFF
	NEXT
DrumPat_6714:
	db 1, 6, 5, 6, 2, 6, 5, 6
	db 1, 6, 5, 6, 2, 5, 4, 0
	db DRUM_LOOP

; Unreferenced (17 bytes)
	db $01, $00, $05, $06, $02, $00, $05, $00, $01, $00, $05, $00, $02, $00, $04, $00
	db $FF
DrumPat_6736:
	db 1, DRUM_LOOP

; Song 11: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong11:
	call StopAll
	ld de, Song11_Ch1
	call L49F0
	ld de, Song11_Ch2
	call L49F4
	ld de, Song11_Ch3
	call L49F8
	ld a, $6E
	ld [wInstrTableHi], a
	ld a, $E0
	ld [wInstrTable], a
	ret
Song11_Ch1:
	dw Pat_6794
Loop_675A:
	dw Pat_67AB
	dw Pat_67E8
	dw Pat_681A
	dw Pat_67E8
	dw Pat_681A
	dw Pat_684C
	dw Pat_686F
	ORDER_LOOP Loop_675A
Song11_Ch2:
	dw Pat_6887
Loop_676E:
	dw Pat_68AF
	dw Pat_68C3
	dw Pat_6900
	dw Pat_68B9
	dw Pat_6900
	dw Pat_6930
	dw Pat_6961
	ORDER_LOOP Loop_676E
Song11_Ch3:
	dw Pat_6982
Loop_6782:
	dw Pat_69B9
	dw Pat_6A0F
	dw Pat_6A65
	dw Pat_6A0F
	dw Pat_6A65
	dw Pat_6ABB
	dw Pat_6B13
	ORDER_LOOP Loop_6782
Pat_6794:
	LENGTH $90
	REST
	HWENV $F1, $00
	ARP 14
	DUTY_12
	LENGTH $C0
	NOTE Csh, 5
	ARP_OFF
	GLIDE $FF
	HWENV $C2, $00
	DUTY_50
	LENGTH $30
	NOTE Csh, 5
	GLIDE_OFF
	NEXT
Pat_67AB:
	DRUMS $08, DrumPat_6B6B
	VIBRATO $08, $01, $04
	INSTR 9
	ARP 0
	DUTY_12
	LEN 8
	NOTE Fsh, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE Csh, 4
	NOTE B_, 3
	NOTE Csh, 4
	NOTE D_, 4
	NOTE Csh, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE Fsh, 3
	NOTE Gsh, 3
	NOTE Fsh, 3
	NOTE F_, 3
	NOTE Fsh, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE Csh, 4
	NOTE B_, 3
	NOTE Csh, 4
	NOTE D_, 4
	NOTE Csh, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE Fsh, 3
	NOTE Gsh, 3
	NOTE Fsh, 3
	NOTE F_, 3
	NEXT
Pat_67E8:
	LEN 8
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE Csh, 4
	NOTE A_, 3
	NOTE Csh, 4
	NOTE Fsh, 4
	NOTE Csh, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE Csh, 5
	NOTE Fsh, 5
	NOTE Csh, 5
	NOTE A_, 4
	NOTE Csh, 5
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE Csh, 4
	NOTE Fsh, 4
	NOTE Csh, 4
	NOTE A_, 3
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE Csh, 3
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE Csh, 4
	NOTE Gsh, 3
	NOTE Csh, 4
	NOTE F_, 4
	NOTE Csh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NEXT
Pat_681A:
	LEN 8
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE Csh, 4
	NOTE A_, 3
	NOTE Csh, 4
	NOTE Fsh, 4
	NOTE Csh, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE Csh, 5
	NOTE Fsh, 5
	NOTE Csh, 5
	NOTE A_, 4
	NOTE Csh, 5
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE Csh, 4
	NOTE Fsh, 4
	NOTE Csh, 4
	NOTE A_, 3
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE Csh, 5
	NOTE D_, 5
	NOTE Csh, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NEXT
Pat_684C:
	HWENV $F2, $0E, $60
	ARP_INLINE $0C, $0C, $18, $18, ARP_LOOP
	DUTY_75
	LEN 24
	NOTE Fsh, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE B_, 3
	LENGTH $30
	NOTE C_, 4
	LEN 24
	NOTE Csh, 4
	LEN 8
	NOTE Csh, 3
	NOTE Dsh, 3
	NOTE F_, 3
	LEN 24
	NOTE Fsh, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE Fsh, 3
	LENGTH $30
	NOTE D_, 3
	NOTE Csh, 3
	NEXT
Pat_686F:
	LEN 24
	NOTE Fsh, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE B_, 3
	LENGTH $30
	NOTE C_, 4
	LEN 24
	NOTE Csh, 4
	LEN 8
	NOTE Csh, 3
	NOTE Dsh, 3
	NOTE F_, 3
	LEN 24
	NOTE Fsh, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE Fsh, 3
	LENGTH $30
	NOTE Fsh, 4
	NOTE F_, 4
	NEXT
Pat_6887:
	CH_TRANSPOSE $0C
	INSTR 8
	LEN 40
	NOTE Fsh, 1
	LEN 8
	NOTE Csh, 2
	LEN 40
	NOTE C_, 2
	LEN 8
	NOTE Csh, 2
	LEN 24
	NOTE D_, 2
	LENGTH $30
	NOTE Csh, 2
	LEN 8
	NOTE Csh, 1
	NOTE Dsh, 1
	NOTE F_, 1
	LEN 40
	NOTE Fsh, 1
	LEN 8
	NOTE Csh, 2
	LEN 40
	NOTE C_, 2
	LEN 8
	NOTE Csh, 2
	LEN 24
	NOTE D_, 2
	LENGTH $30
	NOTE Csh, 2
	LEN 8
	CH_TRANSPOSE $00
	NOTE Csh, 3
	NOTE Dsh, 3
	NOTE F_, 3
	NEXT
Pat_68AF:
	INSTR 8
	LENGTH $40
	NOTE Fsh, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NEXT
Pat_68B9:
	ARP_INLINE $0C, $0C, $00, $00, ARP_LOOP
	DUTY_75
	PAT_GOTO Pat_68D4
Pat_68C3:
	CH_TRANSPOSE $F4
	VIBRATO $10, $02, $04
	CH_TRANSPOSE $F4
	HWENV $F1, $04, $A0
	DUTY_75
	RELEASE $01, $30
	DUTY_50
Pat_68D4:
	LEN 24
	NOTE Fsh, 5
	LEN 16
	WAIT2
	LEN 8
	NOTE Csh, 6
	LEN 24
	NOTE C_, 6
	LEN 16
	WAIT2
	LEN 8
	NOTE Csh, 6
	LEN 16
	NOTE D_, 6
	LEN 8
	WAIT2
	LEN 32
	NOTE Csh, 6
	LEN 8
	WAIT2
	NOTE A_, 5
	NOTE Fsh, 5
	WAIT2
	NOTE Csh, 5
	LEN 16
	NOTE D_, 5
	LEN 8
	WAIT2
	LEN 16
	NOTE Csh, 5
	LEN 8
	WAIT2
	NOTE D_, 5
	WAIT2
	NOTE Csh, 5
	NOTE E_, 5
	WAIT2
	NOTE D_, 5
	LENGTH $38
	NOTE Csh, 5
	LEN 40
	WAIT2
	NEXT
Pat_6900:
	LEN 24
	NOTE Fsh, 5
	LEN 16
	WAIT2
	LEN 8
	NOTE Csh, 6
	LEN 24
	NOTE C_, 6
	LEN 16
	WAIT2
	LEN 8
	NOTE Csh, 6
	LEN 16
	NOTE D_, 6
	LEN 8
	WAIT2
	LEN 32
	NOTE Csh, 6
	LEN 8
	WAIT2
	NOTE A_, 5
	NOTE Fsh, 5
	WAIT2
	NOTE Csh, 5
	LEN 16
	NOTE D_, 5
	LEN 8
	WAIT2
	LEN 16
	NOTE Csh, 5
	LEN 8
	WAIT2
	NOTE E_, 5
	WAIT2
	NOTE D_, 5
	NOTE Fsh, 5
	WAIT2
	NOTE A_, 5
	LENGTH $38
	NOTE Csh, 6
	LEN 8
	NOTE D_, 6
	NOTE Csh, 6
	NOTE B_, 5
	NOTE A_, 5
	NOTE Gsh, 5
	NEXT
Pat_6930:
	CH_TRANSPOSE $00
	ARP_OFF
	VIBRATO $00, $02, $05
	HWENV $50, $00
	RELEASE $00
	DUTY_50
	LEN 1
	NOTE Fsh, 4
	GLISS_3
	LENGTH $2F
	NOTE Fsh, 5
	GLISS_1
	LEN 16
	NOTE Gsh, 5
	NOTE A_, 5
	NOTE B_, 5
	LENGTH $30
	NOTE C_, 6
	LEN 32
	NOTE Csh, 6
	LEN 8
	NOTE A_, 5
	NOTE Gsh, 5
	LENGTH $30
	NOTE Fsh, 5
	LEN 16
	NOTE F_, 5
	NOTE E_, 5
	NOTE Dsh, 5
	LENGTH $30
	NOTE D_, 5
	LEN 24
	NOTE Csh, 5
	LEN 8
	NOTE Csh, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NEXT
Pat_6961:
	LENGTH $30
	NOTE Fsh, 5
	LEN 16
	NOTE Gsh, 5
	NOTE A_, 5
	NOTE B_, 5
	LENGTH $30
	NOTE C_, 6
	LEN 32
	NOTE Csh, 6
	LEN 8
	NOTE A_, 5
	NOTE Gsh, 5
	LENGTH $30
	NOTE Fsh, 5
	LEN 16
	NOTE F_, 5
	NOTE E_, 5
	NOTE Dsh, 5
	LENGTH $30
	GLISS_3
	NOTE D_, 6
	GLISS_1
	LEN 40
	NOTE Csh, 6
	LEN 8
	WAIT2
	GLISS_OFF
	NEXT
Pat_6982:
	VOLENV 15, $11, $1F, $15
	RELEASE $02, $60
	ARP_INLINE $18, $0C, $00, ARP_HOLD
	VIBRATO $08, $04, $04
	WAVE Wave_7644
	LEN 40
	NOTE Fsh, 2
	LEN 8
	NOTE Csh, 3
	LEN 40
	NOTE C_, 3
	LEN 8
	NOTE Csh, 3
	LEN 24
	NOTE D_, 3
	LENGTH $30
	NOTE Csh, 3
	LEN 8
	NOTE Csh, 2
	NOTE Dsh, 2
	NOTE F_, 2
	LEN 40
	NOTE Fsh, 2
	LEN 8
	NOTE Csh, 3
	LEN 40
	NOTE C_, 3
	LEN 8
	NOTE Csh, 3
	LEN 24
	NOTE D_, 3
	LENGTH $30
	NOTE Csh, 3
	LEN 8
	INSTR 0
	NOTE Csh, 2
	NOTE Dsh, 2
	NOTE F_, 2
	NEXT
Pat_69B9:
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 3
	INSTR 0
	LEN 16
	NOTE Csh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 3
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 3
	INSTR 0
	NOTE Csh, 2
	NOTE Dsh, 2
	NOTE F_, 2
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 3
	INSTR 0
	LEN 16
	NOTE Csh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 3
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 3
	INSTR 0
	NOTE Csh, 2
	NOTE Dsh, 2
	NOTE F_, 2
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 3
	INSTR 0
	LEN 16
	NOTE Csh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 3
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 3
	INSTR 0
	NOTE Csh, 2
	NOTE Dsh, 2
	NOTE F_, 2
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 3
	INSTR 0
	LEN 16
	NOTE Csh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 3
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 3
	INSTR 0
	NOTE Csh, 2
	NOTE Dsh, 2
	NOTE F_, 2
	NEXT
Pat_6A0F:
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 3
	INSTR 0
	LEN 16
	NOTE Csh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 3
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 3
	INSTR 0
	NOTE Csh, 2
	NOTE Dsh, 2
	NOTE F_, 2
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 3
	INSTR 0
	LEN 16
	NOTE Csh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 3
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 3
	INSTR 0
	NOTE Fsh, 2
	NOTE F_, 2
	NOTE E_, 2
	LEN 16
	NOTE D_, 2
	INSTR 4
	LEN 8
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 4
	LEN 8
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE D_, 2
	INSTR 4
	LEN 8
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	LEN 16
	NOTE Csh, 2
	INSTR 4
	LEN 8
	NOTE Csh, 4
	INSTR 0
	LEN 16
	NOTE Gsh, 2
	INSTR 4
	LEN 8
	NOTE Csh, 4
	INSTR 0
	LEN 16
	NOTE Csh, 2
	INSTR 4
	LEN 8
	NOTE Csh, 4
	INSTR 0
	NOTE Csh, 2
	NOTE Dsh, 2
	NOTE F_, 2
	NEXT
Pat_6A65:
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 3
	INSTR 0
	LEN 16
	NOTE Csh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 3
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 3
	INSTR 0
	NOTE Csh, 2
	NOTE Dsh, 2
	NOTE F_, 2
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 3
	INSTR 0
	LEN 16
	NOTE Csh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 3
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 3
	INSTR 0
	NOTE Fsh, 2
	NOTE F_, 2
	NOTE E_, 2
	LEN 16
	NOTE D_, 2
	INSTR 4
	LEN 8
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 4
	LEN 8
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE D_, 2
	INSTR 4
	LEN 8
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	NOTE E_, 2
	NOTE D_, 2
	LEN 16
	NOTE Csh, 2
	INSTR 4
	LEN 8
	NOTE Csh, 4
	INSTR 0
	LEN 16
	NOTE Gsh, 2
	INSTR 4
	LEN 8
	NOTE Csh, 4
	INSTR 0
	LEN 16
	NOTE Csh, 2
	INSTR 4
	LEN 8
	NOTE Csh, 4
	INSTR 0
	NOTE Csh, 2
	NOTE Dsh, 2
	NOTE F_, 2
	NEXT
Pat_6ABB:
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 4
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 4
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 4
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	LEN 8
	NOTE Fsh, 2
	LEN 16
	NOTE D_, 2
	INSTR 4
	LEN 8
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE D_, 2
	INSTR 4
	LEN 8
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE Csh, 2
	INSTR 4
	LEN 8
	NOTE Csh, 4
	INSTR 0
	LEN 16
	NOTE Csh, 2
	LEN 8
	NOTE Csh, 2
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 4
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 4
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 4
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	LEN 8
	NOTE Fsh, 2
	LEN 16
	NOTE D_, 2
	LEN 8
	NOTE D_, 2
	INSTR 4
	LEN 16
	NOTE D_, 4
	INSTR 0
	LEN 8
	NOTE D_, 2
	LEN 16
	NOTE Csh, 2
	LEN 8
	NOTE Csh, 2
	INSTR 4
	LEN 16
	NOTE Csh, 4
	INSTR 0
	LEN 8
	NOTE Csh, 2
	NEXT
Pat_6B13:
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 4
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 4
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 4
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	LEN 8
	NOTE Fsh, 2
	LEN 16
	NOTE D_, 2
	INSTR 4
	LEN 8
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE D_, 2
	INSTR 4
	LEN 8
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE Csh, 2
	INSTR 4
	LEN 8
	NOTE Csh, 4
	INSTR 0
	LEN 16
	NOTE Csh, 2
	LEN 8
	NOTE Csh, 2
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 4
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 4
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	INSTR 5
	LEN 8
	NOTE Fsh, 4
	INSTR 0
	LEN 16
	NOTE Fsh, 2
	LEN 8
	NOTE Fsh, 2
	LEN 16
	NOTE D_, 2
	LEN 8
	NOTE D_, 2
	INSTR 4
	LEN 16
	NOTE D_, 4
	INSTR 0
	LEN 8
	NOTE D_, 2
	LEN 16
	NOTE Csh, 2
	LEN 8
	NOTE Csh, 2
	INSTR 4
	LEN 16
	NOTE Csh, 4
	INSTR 0
	LEN 8
	NOTE Csh, 2
	NEXT
DrumPat_6B6B:
	db 1, 0, 6, 2, 0, 6, 1, 0
	db 6, 2, 6, 6, DRUM_LOOP

; Song 1: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong1:
	call StopAll
	ld de, Song1_Ch3
	call L49F8
	ld de, Song1_Ch2
	call L49F4
	ld de, Song1_Ch1
	call L49F0
	ld a, $6E
	ld [wInstrTableHi], a
	ld a, $E0
	ld [wInstrTable], a
	ret
Song1_Ch3:
	dw Pat_6BBC
	dw Pat_6BFA
	dw Pat_6C38
	dw Pat_6C8C
	ORDER_LOOP Song1_Ch3
Song1_Ch2:
	dw Pat_6CE0
	dw Pat_6D10
	dw Pat_6D43
	dw Pat_6D7D
	ORDER_LOOP Song1_Ch2
Song1_Ch1:
	dw Pat_6DC7
	dw Pat_6E12
	dw Pat_6E52
	dw Pat_6E96
	ORDER_LOOP Song1_Ch1
Pat_6BBC:
	INSTR 12
	LEN 18
	NOTE F_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 12
	NOTE C_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 12
	NOTE F_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 12
	NOTE C_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 12
	NOTE Ash, 2
	INSTR 5
	NOTE Ash, 4
	INSTR 12
	NOTE Dsh, 2
	INSTR 4
	NOTE Dsh, 4
	INSTR 12
	NOTE Gsh, 2
	INSTR 4
	NOTE Gsh, 4
	INSTR 12
	NOTE Gsh, 2
	INSTR 4
	NOTE Gsh, 4
	INSTR 12
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 12
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 12
	NOTE F_, 2
	NOTE E_, 2
	NOTE Dsh, 2
	NOTE D_, 2
	NOTE Csh, 2
	INSTR 4
	NOTE Csh, 4
	INSTR 12
	NOTE Gsh, 2
	INSTR 4
	NOTE Csh, 4
	INSTR 12
	LEN 9
	NOTE C_, 2
	NOTE C_, 3
	LEN 18
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	NEXT
Pat_6BFA:
	INSTR 12
	LEN 18
	NOTE F_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 12
	NOTE C_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 12
	NOTE F_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 12
	NOTE C_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 12
	NOTE Ash, 2
	INSTR 5
	NOTE Ash, 4
	INSTR 12
	NOTE Dsh, 2
	INSTR 4
	NOTE Dsh, 4
	INSTR 12
	NOTE Gsh, 2
	INSTR 4
	NOTE Gsh, 4
	INSTR 12
	NOTE Gsh, 2
	INSTR 4
	NOTE Gsh, 4
	INSTR 12
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 12
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 12
	NOTE F_, 2
	NOTE E_, 2
	NOTE Dsh, 2
	NOTE D_, 2
	NOTE Csh, 2
	INSTR 5
	NOTE Ash, 4
	INSTR 12
	NOTE C_, 2
	INSTR 4
	NOTE C_, 5
	INSTR 12
	NOTE F_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 12
	NOTE C_, 3
	INSTR 5
	NOTE F_, 4
	NEXT
Pat_6C38:
	INSTR 12
	LEN 18
	NOTE Dsh, 2
	INSTR 4
	LEN 9
	NOTE Dsh, 4
	NOTE Dsh, 4
	INSTR 12
	LEN 18
	NOTE Ash, 2
	INSTR 4
	NOTE Dsh, 4
	INSTR 12
	NOTE Gsh, 2
	INSTR 4
	LEN 9
	NOTE Gsh, 4
	NOTE Gsh, 4
	INSTR 12
	LEN 18
	NOTE Dsh, 3
	INSTR 4
	NOTE Gsh, 4
	INSTR 12
	NOTE Dsh, 2
	INSTR 4
	LEN 9
	NOTE Dsh, 4
	NOTE Dsh, 4
	INSTR 12
	LEN 18
	NOTE Ash, 2
	INSTR 4
	NOTE Dsh, 4
	INSTR 12
	NOTE Gsh, 2
	INSTR 4
	LEN 9
	NOTE Gsh, 4
	NOTE Gsh, 4
	INSTR 12
	LEN 18
	NOTE Dsh, 3
	INSTR 4
	NOTE Gsh, 4
	INSTR 12
	NOTE G_, 2
	INSTR 4
	LEN 9
	NOTE G_, 4
	NOTE G_, 4
	INSTR 12
	LEN 18
	NOTE D_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 12
	NOTE C_, 3
	INSTR 5
	LEN 9
	NOTE C_, 5
	NOTE C_, 5
	INSTR 12
	LEN 18
	NOTE G_, 2
	INSTR 5
	NOTE C_, 5
	INSTR 12
	NOTE Ash, 2
	INSTR 4
	LEN 9
	NOTE Ash, 4
	NOTE Ash, 4
	INSTR 12
	LEN 18
	NOTE F_, 2
	INSTR 4
	NOTE Ash, 4
	INSTR 12
	NOTE Dsh, 2
	NOTE F_, 2
	NOTE Fsh, 2
	NOTE G_, 2
	NEXT
Pat_6C8C:
	INSTR 12
	LEN 18
	NOTE Dsh, 2
	INSTR 4
	LEN 9
	NOTE Dsh, 4
	NOTE Dsh, 4
	INSTR 12
	LEN 18
	NOTE Ash, 2
	INSTR 4
	NOTE Dsh, 4
	INSTR 12
	NOTE Gsh, 2
	INSTR 4
	LEN 9
	NOTE Gsh, 4
	NOTE Gsh, 4
	INSTR 12
	LEN 18
	NOTE Dsh, 3
	INSTR 4
	NOTE Gsh, 4
	INSTR 12
	NOTE Dsh, 2
	INSTR 4
	LEN 9
	NOTE Dsh, 4
	NOTE Dsh, 4
	INSTR 12
	LEN 18
	NOTE Ash, 2
	INSTR 4
	NOTE Dsh, 4
	INSTR 12
	NOTE Gsh, 2
	INSTR 4
	LEN 9
	NOTE Gsh, 4
	NOTE Gsh, 4
	INSTR 12
	LEN 18
	NOTE Dsh, 3
	INSTR 4
	NOTE Gsh, 4
	INSTR 12
	NOTE G_, 2
	INSTR 4
	LEN 9
	NOTE G_, 4
	NOTE G_, 4
	INSTR 12
	LEN 18
	NOTE D_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 12
	NOTE C_, 3
	INSTR 5
	LEN 9
	NOTE C_, 5
	NOTE C_, 5
	INSTR 12
	LEN 18
	NOTE G_, 2
	INSTR 5
	NOTE C_, 5
	INSTR 12
	NOTE Ash, 2
	INSTR 4
	LEN 9
	NOTE Ash, 4
	NOTE Ash, 4
	INSTR 12
	LEN 18
	NOTE F_, 2
	INSTR 4
	NOTE Ash, 4
	INSTR 12
	NOTE Dsh, 2
	NOTE F_, 2
	NOTE Fsh, 2
	NOTE G_, 2
	NEXT
Pat_6CE0:
	VIBRATO $09, $01, $04
	INSTR 6
	LEN 18
	NOTE F_, 3
	NOTE C_, 4
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE G_, 3
	LEN 9
	NOTE Gsh, 3
	NOTE G_, 3
	LEN 18
	NOTE F_, 3
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Ash, 3
	NOTE Dsh, 4
	NOTE Csh, 4
	LEN 36
	NOTE C_, 4
	NOTE Gsh, 3
	LEN 18
	NOTE Ash, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE Ash, 3
	LEN 9
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE F_, 3
	NOTE G_, 3
	LEN 18
	NOTE Gsh, 3
	NOTE F_, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	LEN 36
	NOTE G_, 3
	NOTE C_, 4
	NEXT
Pat_6D10:
	INSTR 6
	LEN 18
	NOTE F_, 3
	NOTE C_, 4
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE G_, 3
	LEN 9
	NOTE Gsh, 3
	NOTE G_, 3
	LEN 18
	NOTE F_, 3
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Ash, 3
	NOTE G_, 4
	NOTE F_, 4
	LEN 36
	NOTE Dsh, 4
	NOTE C_, 4
	LEN 18
	NOTE F_, 4
	NOTE E_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 9
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 18
	NOTE Gsh, 4
	LEN 9
	NOTE F_, 3
	NOTE G_, 3
	LEN 18
	NOTE Gsh, 3
	LEN 9
	NOTE G_, 3
	NOTE F_, 3
	LEN 18
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE F_, 3
	INSTR 9
	LEN 9
	NOTE F_, 3
	NOTE E_, 3
	NEXT
Pat_6D43:
	INSTR 9
	LEN 9
	NOTE Dsh, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE G_, 3
	NOTE Dsh, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE G_, 3
	LEN 18
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE C_, 4
	LEN 9
	NOTE Dsh, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE G_, 3
	NOTE Dsh, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE G_, 3
	LEN 18
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE C_, 4
	LEN 9
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE B_, 3
	LEN 18
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE Dsh, 4
	LEN 9
	NOTE Ash, 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE Ash, 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	LEN 18
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NEXT
Pat_6D7D:
	INSTR 13
	LEN 27
	NOTE Dsh, 4
	LEN 9
	NOTE F_, 4
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE Ash, 3
	WAIT2
	NOTE Gsh, 3
	WAIT2
	LEN 18
	NOTE Gsh, 3
	INSTR 9
	NOTE C_, 4
	LEN 9
	NOTE Dsh, 3
	NOTE G_, 3
	INSTR 13
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	WAIT2
	NOTE Gsh, 4
	WAIT2
	LEN 18
	NOTE Gsh, 4
	INSTR 9
	LEN 9
	NOTE C_, 4
	NOTE Gsh, 3
	INSTR 13
	LEN 18
	NOTE G_, 4
	LEN 9
	WAIT2
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE Dsh, 5
	LEN 18
	NOTE F_, 5
	LEN 9
	NOTE Dsh, 5
	NOTE D_, 5
	LEN 18
	NOTE Dsh, 5
	NOTE C_, 5
	LEN 9
	NOTE Ash, 4
	WAIT2
	NOTE Ash, 4
	NOTE C_, 5
	NOTE D_, 5
	WAIT2
	NOTE D_, 5
	WAIT2
	NOTE Dsh, 5
	WAIT2
	NOTE Ash, 4
	WAIT2
	LEN 27
	NOTE G_, 4
	LEN 9
	WAIT2
	NEXT
Pat_6DC7:
	DRUMS $09, DrumPat_6ED9
	VIBRATO $09, $01, $04
	GLISS_OFF
	INSTR 13
	LEN 9
	NOTE F_, 4
	GLISS_3
	WAIT2
	NOTE C_, 5
	WAIT2
	LEN 18
	NOTE Ash, 4
	LEN 9
	NOTE Gsh, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	WAIT2
	NOTE C_, 5
	WAIT2
	LEN 18
	NOTE Csh, 5
	LEN 9
	NOTE Ash, 4
	WAIT2
	LEN 18
	NOTE Dsh, 5
	NOTE Csh, 5
	LEN 36
	NOTE C_, 5
	LEN 27
	NOTE Gsh, 4
	LEN 9
	WAIT2
	LEN 18
	NOTE Ash, 4
	LEN 9
	NOTE G_, 4
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	LEN 18
	NOTE C_, 5
	LEN 9
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE Gsh, 4
	WAIT2
	LENGTH $3F
	NOTE G_, 4
	LEN 9
	WAIT2
	NEXT
Pat_6E12:
	INSTR 13
	LEN 9
	NOTE F_, 4
	WAIT2
	NOTE C_, 5
	WAIT2
	LEN 18
	NOTE Ash, 4
	LEN 9
	NOTE Gsh, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	WAIT2
	NOTE C_, 5
	WAIT2
	LEN 18
	NOTE Csh, 5
	LEN 9
	NOTE Ash, 4
	WAIT2
	LEN 18
	NOTE Dsh, 5
	NOTE Csh, 5
	LEN 36
	NOTE C_, 5
	LEN 27
	NOTE Gsh, 4
	LEN 9
	WAIT2
	LEN 18
	NOTE Ash, 4
	LEN 9
	NOTE G_, 4
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	WAIT2
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	WAIT2
	NOTE G_, 4
	NOTE F_, 4
	NOTE C_, 5
	WAIT2
	NOTE C_, 5
	WAIT2
	LENGTH $36
	NOTE F_, 4
	LEN 18
	WAIT2
	NEXT
Pat_6E52:
	INSTR 13
	DUTY_50
	LEN 18
	NOTE G_, 4
	LEN 9
	WAIT2
	NOTE Gsh, 4
	NOTE Ash, 4
	WAIT2
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	LEN 45
	NOTE C_, 4
	LEN 9
	WAIT2
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	WAIT2
	NOTE C_, 5
	WAIT2
	LEN 27
	NOTE C_, 5
	LEN 9
	WAIT2
	LEN 18
	NOTE B_, 4
	LEN 9
	WAIT2
	NOTE C_, 5
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE G_, 5
	LEN 18
	NOTE Gsh, 5
	LEN 9
	NOTE G_, 5
	NOTE F_, 5
	LEN 18
	NOTE G_, 5
	NOTE Dsh, 5
	LEN 9
	NOTE D_, 5
	WAIT2
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE F_, 5
	WAIT2
	NOTE Ash, 5
	WAIT2
	NOTE Gsh, 5
	WAIT2
	NOTE G_, 5
	WAIT2
	LEN 27
	NOTE Ash, 5
	LEN 9
	WAIT2
	NEXT
Pat_6E96:
	INSTR 13
	LEN 18
	NOTE G_, 4
	LEN 9
	WAIT2
	NOTE Gsh, 4
	NOTE Ash, 4
	WAIT2
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	LEN 45
	NOTE C_, 4
	LEN 9
	WAIT2
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	WAIT2
	NOTE C_, 5
	WAIT2
	LEN 27
	NOTE C_, 5
	LEN 9
	WAIT2
	LEN 18
	NOTE B_, 4
	LEN 9
	WAIT2
	NOTE C_, 5
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE G_, 5
	LEN 18
	NOTE Gsh, 5
	LEN 9
	NOTE G_, 5
	NOTE F_, 5
	LEN 18
	NOTE G_, 5
	NOTE Dsh, 5
	LEN 9
	NOTE D_, 5
	WAIT2
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE F_, 5
	WAIT2
	NOTE Ash, 5
	WAIT2
	NOTE Gsh, 5
	WAIT2
	NOTE G_, 5
	WAIT2
	LEN 27
	NOTE Dsh, 5
	LEN 9
	WAIT2
	NEXT
DrumPat_6ED9:
	db 1, 0, 4, 0, 2, 0, 5, 0
	db DRUM_LOOP

; Instrument table 4, entries 1..14 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr4_0
	dw Instr4_1
	dw Instr4_1
	dw Instr4_1
	dw Instr4_1
	dw Instr4_5
	dw Instr4_6
	dw Instr4_6
	dw Instr4_8
	dw Instr4_8
	dw Instr4_10
	dw Instr4_10
	dw Instr4_12
	dw Instr4_13
Instr4_0:
	VOLENV 15, $11, $1F, $12
	ARP_INLINE $18, $0C, ARP_HOLD
	WAVE Wave_7654
	END
Instr4_1:
	VOLENV 13, $01, $1F, $12
	ARP 14
	WAVE Wave_7624
	END
Instr4_5:
	VOLENV 13, $01, $1F, $12
	ARP 15
	WAVE Wave_7624
	END
Instr4_6:
	HWENV $C2, $07, $64
	END
Instr4_8:
	HWENV $C1, $07, $52
	ARP_OFF
	DUTY_75
	END
Instr4_10:
	VOLENV 15, $12, $2F, $11
	ARP 0
	WAVE Wave_7624
	END
Instr4_12:
	VOLENV 15, $00, $1F, $12
	ARP 0
	WAVE Wave_7624
	END
Instr4_13:
	HWENV $79, $02, $A0
	DUTY_75
	RELEASE $51, $81
	END
ArpTable:
	dw Arp0
	dw Arp1
	dw Arp2
	dw Arp2
	dw Arp4
	dw Arp5
	dw Arp6
	dw Arp7
	dw Arp7
	dw Arp7
	dw Arp7
	dw Arp7
	dw Arp7
	dw Arp7
	dw Arp7
	dw Arp15
Arp0:
	db $0C, $00, ARP_HOLD
Arp1:
	db $0C, $0C, $00, $00, ARP_LOOP
Arp2:
	db $00, $00, $01, $01, $02, ARP_HOLD
Arp4:
	db $00, $04, $07, ARP_LOOP
Arp5:
	db $00, $03, $07, ARP_LOOP
Arp6:
	db $00, $0C, $00, ARP_HOLD
Arp7:
	db $00, $00, $04, $04, $07, $07, ARP_LOOP
Arp15:
	db $00, $00, $03, $03, $07, $07, ARP_LOOP

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
	dw PlaySong11                       ; A = 10: song 11
Wave_6FA1:
	db $FF, $FF, $FD, $B8, $53, $10, $00, $00
	db $00, $00, $01, $35, $8B, $DF, $FF, $FF

; Glue for SFX 26: noise routine, then the stream (PlaySfxStart with C = id)
GlueSfx26:
	push bc
	call Sfx26_Noise
	pop bc
	jp L4A27

; Glue for SFX 27: noise routine, then the stream
GlueSfx27:
	push bc
	call Sfx27_Noise
	pop bc
	jp L4A27

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
	dw Sfx37+21

; Sound effect 3
Sfx03:
	WAVE Wave_6FA1
	PAN_R
	VOLENV 15, $00, $00, $00
	GLIDE $FD
	LEN 3
	NOTE G_, 5
	END

; Sound effect 4
Sfx04:
	WAVE Wave_6FA1
	VOLENV 15, $00, $00, $00
	GLIDE $FD
	LEN 3
	NOTE Dsh, 5
	END

; Sound effect 5
Sfx05:
	WAVE Wave_6FA1
	PAN_L
	VOLENV 15, $00, $00, $00
	GLIDE $FD
	LEN 3
	NOTE B_, 4
	END

; Sound effect 1
Sfx01:
	WAVE Wave_6FA1
	VOLENV 15, $00, $00, $00
	LEN 1
	NOTE D_, 4
	NOTE Gsh, 3
	END

; Sound effect 2
Sfx02:
	WAVE Wave_6FA1
	VOLENV 15, $00, $00, $00
	LEN 1
	NOTE C_, 5
	NOTE Fsh, 4
	END

; Sound effect 37
Sfx37:
	WAVE Wave_7684
	CALL_CODE Code_7355
	VOLENV 15, $12, $1F, $12
	LEN 8
	GLIDE $FF
	NOTE A_, 4
	LEN 5
	VOLENV 10, $11, $1F, $12
	NOTE A_, 4
	END

; Unreferenced (4 bytes)
	db $80, $8E, $73, $68

; Sound effect 36
Sfx36:
	WAVE Wave_7604
	VOLENV 5, $1A, $1F, $11
	ARP_INLINE $00, $06, ARP_LOOP
	GLIDE $FF
	LEN 10
	NOTE G_, 4
	NOTE Csh, 4
	NOTE G_, 3
	NOTE Csh, 3
	END

; Sound effect 35
Sfx35:
	WAVE Wave_7624
	CALL_CODE Code_75A5
	ARP_INLINE $00, $00, $06, $06, ARP_LOOP
	GLIDE $FC
	LEN 10
	VOLENV 15, $00, $00, $00
	NOTE A_, 5
	VOLENV 10, $00, $00, $00
	NOTE A_, 5
	VOLENV 5, $00, $00, $00
	NOTE A_, 5
	END

; Sound effect 32
Sfx32:
	CALL_CODE Code_73C2
	VOLENV 15, $11, $1F, $12
	WAVE Wave_76A4
	ARP_INLINE $00, $0C, $0C, ARP_LOOP
	LEN 10
	NOTE C_, 7
	VIBRATO $01, $05, $02
	LEN 10
	NOTE Csh, 7
	WAIT
	WAIT
	END

; Sound effect 29
Sfx29:
	CALL_CODE Code_7434
	VOLENV 15, $11, $1F, $13
	ARP_INLINE $00, $01, $02, $01, ARP_LOOP
	WAVE Wave_7714
	GLIDE $FB
	LEN 5
	NOTE E_, 4
	GLIDE_OFF
	VIBRATO $00, $FD, $00
	LEN 10
	NOTE E_, 4
	VIBRATO $00, $03, $00
	NOTE G_, 4
	WAIT
	END

; Sound effect 31
Sfx31:
	VOLENV 10, $2F, $1F, $11
	LEN 5
	GLIDE $02
	WAVE Wave_7604
	NOTE C_, 4
	LEN 5
	REST
	VOLENV 15, $11, $1F, $12
	WAVE Wave_76B4
	LEN 4
	GLIDE $01
	NOTE C_, 3
	LEN 3
	REST
	LEN 3
	GLIDE $01
	NOTE B_, 2
	END

; Sound effect 30
Sfx30:
	WAVE Wave_7604
	VOLENV 15, $00, $1F, $11
	GLIDE $FB
	LEN 5
	NOTE E_, 4
	GLIDE $02
	NOTE E_, 4
	GLIDE $FF
	WAIT
	END

; Sound effect 33
Sfx33:
	WAVE Wave_7604
	VOLENV 15, $11, $1F, $12
	GLIDE $03
	LEN 6
	NOTE Gsh, 2
	LEN 6
	GLIDE $01
	WAIT
	WAIT
	END

; Sound effect 34
Sfx34:
	VOLENV 15, $12, $1F, $13
	WAVE Wave_7604
	VIBRATO $01, $09, $05
	GLIDE $FD
	LEN 5
	NOTE C_, 4
	GLIDE $03
	LEN 5
	WAIT
	GLIDE_OFF
	LEN 20
	WAIT
	END

; Sound effect 24
Sfx24:
	CALL_CODE Code_7472
	VOLENV 11, $11, $1F, $14
	WAVE Wave_7624
	LEN 5
	GLIDE $FB
	NOTE C_, 5
	END

; Sound effect 22
Sfx22:
	CALL_CODE Code_7434
	VOLENV 15, $11, $1F, $11
	VIBRATO $04, $03, $00
	WAVE Wave_76A4
	ARP_INLINE $00, $0C, $0C, ARP_LOOP
	LEN 10
	NOTE Gsh, 6
	VOLENV 5, $11, $1F, $00
	VIBRATO $01, $03, $00
	LEN 5
	NOTE Gsh, 6
	END

; Sound effect 21
Sfx21:
	CALL_CODE Code_7434
	WAVE Wave_7684
	VOLENV 10, $00, $00, $00
	LEN 3
	GLIDE $02
	NOTE A_, 4
	LEN 8
	GLIDE $FE
	WAIT
	END

; Sound effect 12
Sfx12:
	LEN 3
	VOLENV 15, $11, $1F, $11
	ARP_INLINE $0C, $00, ARP_LOOP
	WAVE Wave_75F4
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	VOLENV 5, $00, $00, $00
	WAVE Wave_75E4
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	END

; Sound effect 11
Sfx11:
	LEN 3
	VOLENV 15, $11, $1F, $11
	ARP_INLINE $0C, $00, ARP_LOOP
	WAVE Wave_75F4
	NOTE C_, 6
	NOTE G_, 5
	NOTE E_, 5
	NOTE C_, 5
	VOLENV 5, $00, $00, $00
	WAVE Wave_75E4
	NOTE C_, 6
	NOTE G_, 5
	NOTE E_, 5
	NOTE C_, 5
	END

; Sound effect 15
Sfx15:
	VOLENV 15, $00, $1F, $11
	ARP 0
	WAVE Wave_75F4
	LEN 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	CH_TRANSPOSE $06
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	CH_TRANSPOSE $0E
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	CH_TRANSPOSE $15
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	VOLENV 10, $00, $1F, $11
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	VOLENV 5, $00, $1F, $11
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	END

; Sound effect 27
Sfx27:
	VOLENV 15, $00, $00, $00
	LEN 6
	WAVE Wave_7604
	GLIDE $FD
	NOTE A_, 3
	NOTE A_, 3
	VOLENV 10, $00, $00, $00
	NOTE A_, 3
	NOTE A_, 3
	END

; Sound effect 26
Sfx26:
	VOLENV 15, $00, $00, $00
	LEN 6
	WAVE Wave_7604
	CALL_CODE Sfx26_Noise
	GLIDE $FD
	NOTE D_, 4
	NOTE D_, 4
	VOLENV 10, $00, $00, $00
	NOTE D_, 4
	NOTE D_, 4
	END

; Sound effect 16
Sfx16:
	WAVE Wave_7604
	VOLENV 15, $11, $1F, $12
	VIBRATO $00, $01, $02
	LEN 4
	NOTE C_, 6
	NOTE C_, 7
	NOTE C_, 6
	LEN 20
	NOTE C_, 7
	END

; Sound effect 23
Sfx23:
	VOLENV 15, $11, $1F, $12
	VIBRATO $04, $FD, $00
	WAVE Wave_76A4
	ARP_INLINE $00, $0C, $0C, ARP_LOOP
	LEN 15
	NOTE Gsh, 6
	VOLENV 5, $11, $1F, $00
	VIBRATO $01, $FD, $00
	LEN 10
	NOTE Gsh, 6
	END

; Sound effect 13
Sfx13:
	VOLENV 15, $11, $1F, $1F
	WAVE Wave_7684
	LEN 8
	GLIDE $FA
	NOTE C_, 7
	LEN 10
	GLIDE $04
	WAIT
	GLIDE $02
	LEN 2
	WAIT
	END

; Sound effect 14
Sfx14:
	VOLENV 15, $11, $1F, $16
	WAVE Wave_7684
	LEN 8
	GLIDE $FA
	NOTE C_, 7
	LEN 10
	GLIDE $04
	WAIT
	GLIDE_OFF
	ARP_INLINE $00, $04, $06, ARP_LOOP
	VIBRATO $00, $02, $00
	WAIT
	WAIT
	WAIT
	WAIT
	END

; Sound effect 17
Sfx17:
	VOLENV 15, $11, $1F, $12
	LEN 4
	WAVE Wave_7704
	GLIDE $04
	NOTE G_, 5
	LEN 1
	GLIDE $02
	WAIT
	GLIDE_OFF
	LEN 4
	VIBRATO $01, $05, $01
	NOTE C_, 7
	LEN 2
	GLIDE $02
	WAIT
	GLIDE $FD
	WAIT
	END

; Sound effect 20
Sfx20:
	VOLENV 15, $11, $1F, $15
	LEN 4
	WAVE Wave_7714
	GLIDE $02
	NOTE Fsh, 6
	LEN 1
	GLIDE $01
	GLIDE_OFF
	ARP_INLINE $00, $01, $02, $01, ARP_LOOP
	LEN 4
	VIBRATO $01, $05, $01
	NOTE E_, 7
	LEN 2
	WAVE Wave_7704
	GLIDE $02
	WAIT
	GLIDE $FF
	WAIT
	GLIDE_OFF
	LEN 30
	VIBRATO $06, $FF, $00
	WAIT
	LEN 25
	WAIT
	END

; Sound effect 18
Sfx18:
	VOLENV 15, $11, $1F, $10
	CALL_CODE Code_74EE
	WAVE Wave_7714
	LEN 4
	GLIDE $01
	NOTE Gsh, 4
	GLIDE $FE
	WAIT
	LEN 1
	REST
	END

; Sound effect 25
Sfx25:
	LEN 18
	VOLENV 5, $1F, $1F, $22
	WAVE Wave_7654
	ARP_INLINE $00, $06, $0C, ARP_LOOP
	VIBRATO $00, $FE, $01
	LEN 25
	NOTE C_, 5
	WAIT
	LEN 5
	WAIT
	END

; Sound effect 19
Sfx19:
	ARP_INLINE $01, $00, ARP_LOOP
	LEN 4
	VOLENV 15, $11, $1F, $10
	CALL_CODE Code_74B3
	WAVE Wave_7714
	GLIDE $02
	NOTE E_, 5
	GLIDE $FC
	WAIT
	GLIDE $02
	WAIT
	GLIDE $FC
	WAIT
	GLIDE $02
	WAIT
	GLIDE $FC
	WAIT
	GLIDE $02
	WAIT
	GLIDE $FD
	WAIT
	END

; Sound effect 6
Sfx06:
	VOLENV 15, $11, $2F, $11
	WAVE Wave_76A4
	LEN 6
	NOTE C_, 6
	END

; Sound effect 7
Sfx07:
	LEN 4
	VOLENV 15, $11, $2F, $11
	WAVE Wave_76A4
	LEN 4
	NOTE Gsh, 5
	LEN 5
	NOTE Gsh, 6
	END

; Sound effect 28
Sfx28:
	LEN 5
	ARP 0
	WAVE Wave_76A4
	VOLENV 15, $10, $00, $10
	RELEASE $02, $11
	NOTE C_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	END

; Sound effect 9
Sfx09:
	VOLENV 15, $13, $FF, $11
	LEN 5
	GLIDE $FE
	WAVE Wave_76B4
	NOTE C_, 4
	NOTE F_, 4
	NOTE Ash, 3
	NOTE D_, 4
	NOTE Csh, 3
	END

; Sound effect 8
Sfx08:
	VOLENV 15, $11, $1F, $11
	LEN 8
	GLIDE $02
	WAVE Wave_7694
	NOTE C_, 5
	LEN 1
	REST
	END

; Sound effect 10
Sfx10:
	VOLENV 15, $11, $1F, $13
	LEN 10
	GLIDE $02
	WAVE Wave_7694
	NOTE Fsh, 5
	LEN 8
	REST
	GLIDE $02
	LEN 12
	NOTE C_, 5
	GLIDE $FF
	LEN 21
	WAIT
	END
Code_7355:
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
	ld a, HIGH(Noise43_7384)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7384)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_7384:
	db $02, $92, $42, $42, $42, $42, $52, $65
	db $45, $FF

; Sound effect 38 (noise only; started by the game's glue, sets wDrumHold)
Sfx38_Noise:
	ld a, $88
	ld [wNoisePan], a
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_73B5)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_73B5)
	ld [wNoise43], a
	ld a, HIGH(Noise42_73BC)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_73BC)
	ld [wNoise42], a
	ret
Noise43_73B5:
	db $41, $61, $61, $41, $71, $71, $FF
Noise42_73BC:
	db $A1, $52, $00, $61, $52, $00
Code_73C2:
	ld a, $88
	ld [wNoisePan], a
	ld a, $2D
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_73E9)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_73E9)
	ld [wNoise43], a
	ld a, HIGH(Noise42_740F)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_740F)
	ld [wNoise42], a
	ret
Noise43_73E9:
	db $03, $93, $80, $72, $70, $56, $54, $60
	db $50, $40, $30, $20, $10, $56, $54, $60
	db $50, $40, $30, $20, $10, $56, $54, $60
	db $50, $40, $30, $20, $10, $56, $54, $60
	db $50, $40, $30, $20, $10, $FF
Noise42_740F:
	db $F3, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF
Code_7434:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0A
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_745B)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_745B)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7467)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7467)
	ld [wNoise42], a
	ret
Noise43_745B:
	db $44, $10, $20, $31, $33, $34, $35, $36
	db $37, $44, $46, $FF
Noise42_7467:
	db $F1, $FF, $FF, $C1, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF
Code_7472:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_74A6)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_74A6)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7499)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7499)
	ld [wNoise42], a
	ret
Noise42_7499:
	db $F1, $A1, $FF, $FF, $FF, $FF, $43, $FF
	db $FF, $FF, $FF, $FF

; Unreferenced (1 bytes)
	db $FF
Noise43_74A6:
	db $51, $10, $20, $31, $32, $33, $53, $34
	db $14, $15, $15, $16, $FF
Code_74B3:
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
	ld a, HIGH(Noise43_74E3)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_74E3)
	ld [wNoise43], a
	ld a, HIGH(Noise42_74E9)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_74E9)
	ld [wNoise42], a
	ret
Noise43_74E3:
	db $13, $33, $43, $53, $63, $FF
Noise42_74E9:
	db $59, $FF, $FF, $FF, $81
Code_74EE:
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
	ld a, HIGH(Noise43_751E)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_751E)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7527)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7527)
	ld [wNoise42], a
	ret
Noise43_751E:
	db $78, $78, $78, $78, $58, $56, $56, $68
	db $FF
Noise42_7527:
	db $A1, $FF, $11, $00, $81, $FF, $11, $00
Sfx26_Noise:
	ld a, $88
	ld [wNoisePan], a
	ld a, $2B
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $01
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_755F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_755F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7565)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7565)
	ld [wNoise42], a
	ret
Noise43_755F:
	db $03, $93, $80, $72, $70, $FF
Noise42_7565:
	db $F0, $FF, $FF, $FF, $F2
Sfx27_Noise:
	ld a, $88
	ld [wNoisePan], a
	ld a, $35
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $02
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_759A)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_759A)
	ld [wNoise43], a
	ld a, HIGH(Noise42_75A0)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_75A0)
	ld [wNoise42], a
	ret
Noise43_759A:
	db $43, $93, $82, $72, $72, $FF
Noise42_75A0:
	db $F0, $FF, $FF, $FF, $F3
Code_75A5:
	ld a, $88
	ld [wNoisePan], a
	ld a, $23
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $02
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_75D5)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_75D5)
	ld [wNoise43], a
	ld a, HIGH(Noise42_75DD)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_75DD)
	ld [wNoise42], a
	ret
Noise43_75D5:
	db $37, $36, $35, $14, $11, $11, $10, $FF
Noise42_75DD:
	db $5A, $FF, $FF, $FF, $FF, $FF, $C2
Wave_75E4:
	db $00, $36, $8A, $FF, $FF, $A8, $63, $00
	db $00, $36, $8A, $FF, $FF, $A8, $63, $00
Wave_75F4:
	db $00, $00, $7A, $FF, $FF, $A7, $00, $00
	db $00, $00, $7A, $FF, $FF, $A7, $00, $00
Wave_7604:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF

; Unreferenced (16 bytes)
	db $00, $00, $00, $00, $00, $00, $FF, $FF, $00, $00, $00, $00, $00, $00, $FF, $FF
Wave_7624:
	db $00, $00, $00, $00, $00, $00, $FF, $00
	db $00, $00, $00, $00, $00, $00, $FF, $00
Wave_7634:
	db $00, $00, $00, $CD, $EF, $FF, $FF, $FF
	db $04, $8C, $FF, $FF, $FF, $FF, $FF, $FF
Wave_7644:
	db $48, $FF, $FF, $FF, $FF, $FF, $FF, $84
	db $00, $66, $06, $60, $00, $4F, $FF, $88
Wave_7654:
	db $EC, $96, $31, $90, $00, $77, $00, $00
	db $00, $24, $69, $CE, $FF, $FF, $FF, $FF

; Unreferenced (32 bytes)
	db $12, $34, $56, $78, $9A, $BC, $DE, $FF, $ED, $CB, $A9, $87, $65, $43, $21, $00
	db $FF, $FE, $ED, $B8, $53, $21, $10, $00, $00, $01, $12, $35, $8B, $DE, $EF, $FF
Wave_7684:
	db $63, $10, $40, $20, $00, $00, $01, $36
	db $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9
Wave_7694:
	db $63, $10, $01, $47, $74, $10, $01, $36
	db $9C, $EF, $FE, $B8, $8B, $EF, $FE, $C9
Wave_76A4:
	db $63, $1F, $01, $47, $74, $10, $01, $36
	db $9C, $E0, $FE, $B8, $8B, $EF, $FE, $C9
Wave_76B4:
	db $0F, $00, $F0, $F0, $F0, $F0, $00, $0F
	db $0F, $FF, $FF, $00, $FF, $F0, $0F, $0F

; Unreferenced (64 bytes)
	db $00, $00, $00, $00, $00, $00, $00, $00, $ED, $CB, $A9, $87, $65, $43, $21, $00
	db $04, $8B, $DE, $FF, $ED, $CB, $A9, $87, $65, $44, $44, $32, $11, $24, $7A, $74
	db $20, $13, $69, $BD, $FD, $B9, $64, $20, $13, $68, $B8, $64, $20, $24, $68, $64
	db $00, $00, $69, $FF, $FF, $F9, $64, $00, $03, $68, $B8, $60, $00, $04, $68, $60
Wave_7704:
	db $20, $24, $68, $AC, $EC, $A8, $64, $20
	db $24, $68, $A8, $64, $20, $24, $68, $64
Wave_7714:
	db $02, $48, $AC, $FF, $FC, $53, $00, $27
	db $9C, $DD, $DC, $B7, $7B, $CD, $DD, $C9

; Unreferenced (32 bytes)
	db $BD, $FF, $AC, $FF, $FC, $52, $00, $27, $9C, $DF, $DC, $B7, $7B, $CD, $AD, $C9
	db $FE, $DC, $BA, $98, $76, $54, $32, $10, $FE, $DC, $BA, $98, $76, $54, $32, $10
Noise43_7744:
	db $21, $22, $23, $FF
Noise42_7748:
	db $A3, $FF, $54
Noise43_774B:
	db $11, $11, $FF
Noise42_774E:
	db $61, $31
Noise43_7750:
	db $11, $11, $FF
Noise42_7753:
	db $81, $31
Noise43_7755:
	db $11, $11, $FF
Noise42_7758:
	db $91, $52
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7780)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7780)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7783)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7783)
	ld [wNoise42], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $01
	jp PlaySfx
Noise43_7780:
	db $10, $11, $FF
Noise42_7783:
	db $F0, $41
Drum2:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_77AB)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_77AB)
	ld [wNoise43], a
	ld a, HIGH(Noise42_77B1)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_77B1)
	ld [wNoise42], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $02
	jp PlaySfx
Noise43_77AB:
	db $20, $32, $32, $32, $32, $FF
Noise42_77B1:
	db $B1, $71, $FF, $FF, $42
Drum3:
	ret
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7755)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7755)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7758)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7758)
	ld [wNoise42], a
	ret
Drum14:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7755)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7755)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7758)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7758)
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
	ld a, HIGH(Noise43_7750)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7750)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7753)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7753)
	ld [wNoise42], a
	ret
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_774B)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_774B)
	ld [wNoise43], a
	ld a, HIGH(Noise42_774E)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_774E)
	ld [wNoise42], a
	ret
Drum7:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7744)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7744)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7748)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7748)
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
	ld a, HIGH(Noise43_78C7)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_78C7)
	ld [wNoise43], a
	ld a, HIGH(Noise42_78CA)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_78CA)
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
	ld a, HIGH(Noise43_78C7)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_78C7)
	ld [wNoise43], a
	ld a, HIGH(Noise42_78CA)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_78CA)
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
	ld a, HIGH(Noise43_78C7)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_78C7)
	ld [wNoise43], a
	ld a, HIGH(Noise42_78CA)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_78CA)
	ld [wNoise42], a
	ld a, $80
	ld [wNoisePan], a
	ld a, $05
	jp PlaySfx

; Unreferenced (1 bytes)
	db $C9
Noise43_78C7:
	db $21, $31, $FF
Noise42_78CA:
	db $A0, $62
Drum11:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_78E9)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_78E9)
	ld [wNoise43], a
	ld a, HIGH(Noise42_78EC)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_78EC)
	ld [wNoise42], a
	ret
Noise43_78E9:
	db $51, $32, $FF
Noise42_78EC:
	db $F0, $62
Drum12:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7928)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7928)
	ld [wNoise43], a
	ld a, HIGH(Noise42_792B)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_792B)
	ld [wNoise42], a
	ret
Drum13:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_792D)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_792D)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7934)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7934)
	ld [wNoise42], a
	ret
Noise43_7928:
	db $51, $32, $FF
Noise42_792B:
	db $70, $52
Noise43_792D:
	db $51, $32, $32, $32, $51, $32, $FF
Noise42_7934:
	db $70, $41, $FF, $FF, $70, $41
FadeOutTable:
	db $77, $66, $55, $44, $33, $22, $11, $00
	db $80, FADE_END
FadeInTable:
	db $00, $11, $22, $33, $44, $55, $66, $77
	db FADE_END
DriverEndText:
	db "Final de la rutina de musica"

; Unreferenced (1687 bytes)
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
	db $00, $00, $00, $00, $00, $00, $00
