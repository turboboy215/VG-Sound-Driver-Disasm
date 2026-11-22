; =====================================================================
; Radikal Bikers (E) (M4) (Prototype) [C] - Game Boy Color
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o radikal.o RadikalBikers_SoundDriver.asm
;   rgblink -o radikal.gb radikal.o
;   python tools/cmp_banked.py radikal.gb "Radikal Bikers (E) (M4) (Prototype) [C].gbc" 63:4000-7FFF
; (driver and data fill ROM bank 63; the linked file only matches in that range)
;
; Documentation: RadikalBikers_SoundDriver.md / AJG_SoundEngine_Family.md
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
	db $8C + \1
ENDM
MACRO ARP       ; arpeggio n of the current arpeggio table
	db $A1 + \1
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
MACRO CMD_8B
	db $8B
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
DEF wCh1 EQU $D000
DEF wPaused EQU $D041
DEF wShNR32 EQU $D042
DEF wInInstr EQU $D043
DEF wNoisePan EQU $D044
DEF wDrumHold EQU $D045
DEF wInstrTable EQU $D046
DEF wInstrTableHi EQU $D047
DEF wArpTable EQU $D048
DEF wArpTableHi EQU $D049
DEF wMusicWave EQU $D04A
DEF wMusicWaveHi EQU $D04B
DEF wNoisePingPong EQU $D04C
DEF wDrumPatHi EQU $D04D
DEF wDrumPat EQU $D04E
DEF wDrumPos EQU $D04F
DEF wDrumsOn EQU $D050
DEF wDrumTempo EQU $D051
DEF wDrumTimer EQU $D052
DEF wDrumLoopCount EQU $D053
DEF wDrumLoopPos EQU $D054
DEF wNoise43Hi EQU $D055
DEF wNoise43 EQU $D056
DEF wNoise42Hi EQU $D057
DEF wNoise42 EQU $D058
DEF wNoisePos EQU $D059
DEF wNoiseOn EQU $D05A
DEF wNoiseAtten EQU $D05B
DEF wNoiseTimer EQU $D05C
DEF wNoiseSpeed EQU $D05D
DEF wFadeTable EQU $D05E
DEF wFadeTableHi EQU $D05F
DEF wFadePos EQU $D060
DEF wFadeTimer EQU $D061
DEF wFadeSpeed EQU $D062
DEF wFadeOn EQU $D063
DEF wDutyCh1 EQU $D064
DEF wDutyCh2 EQU $D065
DEF wCurSong EQU $D066
DEF wCh2 EQU $D100
DEF wCh3 EQU $D200
DEF wSfx EQU $D300

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
	dw PlaySong
	jp SndUpdate                       ; SndUpdate
	jp SndPause                        ; SndPause
	jp SndResume                       ; SndResume
	jp StopAll                         ; StopAll
	jp PlaySong                        ; PlaySong (A = song number; sets the default instrument and arpeggio tables)
	jp PlaySfx                         ; PlaySfx (A = id)
	jp SndInit                         ; SndInit
	jp SongFadeIn                      ; SongFadeIn (A = speed)
	jp SongFadeOut                     ; SongFadeOut (A = speed)
PlaySong:
	push af
	call StopAll
	ld a, $6A
	ld [wInstrTableHi], a
	ld a, $8D
	ld [wInstrTable], a
	ld a, HIGH(ArpTable)
	ld [wArpTableHi], a
	ld a, LOW(ArpTable)
	ld [wArpTable], a
	pop af
	cp $09
	ret nc
	ld [wCurSong], a
	add a, a
	add a, $A7
	ld l, a
	adc a, $6B
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
	ld h, $D0
	call ChannelTick
	inc h
	call ChannelTick
	inc h
	call ChannelTick
	call DrumTick
	ld h, $D3
	call ChannelTick

; Output, pulse pages: NRx3 = period low + pitch offset; when the high byte changed
; or the envelope flag ($33) is set: with the flag NRx2 = field $32 and NRx4 =
; high | $80, else NRx4 = high. (Obelix GBC's duty shadows are gone: duty goes
; straight to NR11/NR21.)
OutputCh1:
	ld hl, $D025
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
	ld hl, $D327
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
	add a, $D5
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
	ld hl, $D038
	ld c, [hl]
	inc h
	ld a, [hl]
	rlc a
	or c
	ld c, a
	inc h
	ld a, [$D327]
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
	ld h, $D3
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
	jr nz, L42C2
	ld l, $25
	add a, [hl]
	ld [hli], a
	ret nc
	inc [hl]
	ret
L429A:
	ld l, $22
	ld a, [hl]
	cpl
	inc a
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
	bit 7, c
	jr nz, L429A
	ld l, $25
	ld a, [hl]
	sub c
	ld [hli], a
	ret nc
	dec [hl]
	ret
L42C2:
	ld l, $22
	ld a, [hl]
	cpl
	inc a
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
	jr z, L433D
	res 2, [hl]
	ld l, $17
	ld a, [hl]
	ld l, $1A
	ld [hli], a
	ld [hli], a
	ld l, $04
L433D:
	bit 6, [hl]
	jr z, L4358
	ld l, $40
	ld a, [hl]
	rla
	rla
	and $C0
	ld c, a
NoteOnEnvelope:
	ld a, h
	cp $D0
	jr nz, L4354
	ld a, c
	ld [wDutyCh1], a
	jr L4358
L4354:
	ld a, c
	ld [wDutyCh2], a
L4358:
	ld a, h
	cp $D2
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
	cp $A1
	jr nc, Cmd_Arp
	cp $8C
	jp nc, Cmd_Instrument
	sub $60
	add a, a
	ld c, a
	ld b, $40
	ld a, [bc]
	ld l, a
	inc c
	ld a, [bc]
	ld c, $ED
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
	sub $A1
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
	cp $D2
	jr nc, InstrLookup
	cp $D0
	jr nz, InstrDutyCh2
	ld a, $80
	ld [wDutyCh1], a
	jr InstrLookup
InstrDutyCh2:
	ld a, $80
	ld [wDutyCh2], a
InstrLookup:
	ld a, b
	sub $8B
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
	set 3, [hl]
	set 4, [hl]
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
	set 3, [hl]
	res 4, [hl]
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
	cp $D2
	jr z, ReleaseCh3
	cp $D3
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
	ld [$D21B], a
	ld [$D21A], a
	ld a, [hl]
	and $F0
	swap a
	jr z, SetReleased
	ld [$D208], a
	jr SetReleased
ReleaseSfx:
	ld a, [hl]
	and $0F
	ld [$D31B], a
	ld [$D31A], a
	ld a, [hl]
	and $F0
	swap a
	jr z, SetReleased
	ld [$D308], a
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
	cp $D2
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
	ld h, $D0
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
	cp $D3
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
	ld l, $40
	ld [hl], a
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
	ld [$D327], a
	ld [$D308], a
	ld [wNoiseTimer], a
	ld [wNoiseSpeed], a
	dec a
	ld [wShNR32], a
	jp RestoreMusicWave
Cmd_Transpose:
	ld a, [de]
	ld [$D00F], a
	ld [$D10F], a
	ld [$D20F], a
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
	cp $D2
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
	cp $D2
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
	cp $D0
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
	cp $D2
	jr nz, LoadWave
SetMusicWave:
	ld a, [de]
	inc de
	ld [wMusicWave], a
	ld a, [de]
	ld [wMusicWaveHi], a
	ld a, [$D327]
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
	ld a, [$D205]
	ldh [rNR33], a
	ld a, $80
	ld [$D207], a
	ldh [rNR30], a
	ldh [rNR34], a
	ret

; Unreferenced (167 bytes)
	db $06, $00, $00, $89, $75, $00, $8B, $6C, $24, $14, $85, $ED, $74, $10, $3B, $D3
	db $76, $0C, $33, $C9, $66, $39, $7A, $FE, $0F, $94, $C1, $89, $4D, $00, $2B, $C6
	db $D1, $F8, $5F, $5E, $5D, $5B, $C2, $0C, $00, $56, $8B, $71, $20, $C1, $EE, $02
	db $57, $74, $25, $83, $7C, $24, $0C, $00, $74, $1E, $8B, $79, $24, $4E, $FF, $74
	db $24, $0C, $FF, $37, $FF, $15, $20, $12, $C7, $7B, $85, $C0, $74, $0E, $83, $C7
	db $18, $8B, $C6, $4E, $85, $C0, $75, $E6, $33, $C0, $EB, $02, $8B, $C7, $5F, $5E
	db $C2, $04, $00, $8B, $4C, $24, $04, $66, $8B, $54, $24, $08, $66, $8B, $01, $66
	db $85, $C0, $74, $11, $66, $3B, $C2, $74, $0C, $66, $8B, $41, $02, $83, $C1, $02
	db $66, $85, $C0, $75, $EF, $33, $C0, $66, $39, $11, $0F, $95, $C0, $48, $23, $C1
	db $C3, $55, $8B, $EC, $53, $56, $57, $FF, $75, $10, $FF, $75, $0C, $FF, $75, $08
	db $FF, $15, $90, $12, $C7, $7B, $8B
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
	cp $D2
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
	ld h, $D0
	jr L4A01
L49F4:
	ld h, $D1
	jr L4A01
L49F8:
	ld h, $D2
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
	ld a, [$D327]
	cp $06
	ret nc
	ld a, c
PlaySfxStart:
	ld [$D327], a
	ld a, $11
	ld [$D338], a
	xor a
	ld [$D304], a
	ld [$D30B], a
	ld [$D331], a
	ld [$D32E], a
	ld [$D30E], a
	ld [$D30F], a
	inc a
	ld [$D30A], a
	ld a, $F4
	ld [$D30D], a
	ld a, c
	ld de, $D302
	add a, a
	add a, $C7
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
	db $78, $3D, $28, $E0, $EA, $4C, $D0, $3E, $08, $EA, $44, $D0, $C9, $C9
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

; Song 1: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong1:
	call StopAll
	ld a, $50
	ld [wInstrTableHi], a
	ld a, $A1
	ld [wInstrTable], a
	ld de, Song1_Ch3
	call L49F8
	ld de, Song1_Ch1
	call L49F0
	ld de, Song1_Ch2
	jp L49F4
Song1_Ch3:
	dw Pat_4CFC
Loop_4CCE:
	dw Pat_4D4F
	dw Pat_4D4F
	dw Pat_4D97
	dw Pat_4DC2
	dw Pat_4DC2
	ORDER_LOOP Loop_4CCE
Song1_Ch1:
	dw Pat_4E0D
Loop_4CDE:
	dw Pat_4E3A
	dw Pat_4E3A
	dw Pat_4E83
	dw Pat_4EA8
	dw Pat_4EA8
	ORDER_LOOP Loop_4CDE
Song1_Ch2:
	dw Pat_4EF2
Loop_4CEE:
	dw Pat_4F42
	dw Pat_4F42
	dw Pat_4F8D
	dw Pat_4FBD
	dw Pat_4FBD
	ORDER_LOOP Loop_4CEE
Pat_4CFC:
	DRUMS $07, DrumPat_4FFC
	INSTR 0
	LEN 7
	NOTE G_, 2
	NOTE D_, 2
	NOTE F_, 2
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE D_, 2
	NOTE F_, 2
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	LEN 14
	NOTE Ash, 2
	NOTE Ash, 2
	LEN 7
	NOTE G_, 2
	NOTE D_, 2
	NOTE F_, 2
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE D_, 2
	NOTE F_, 2
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	LEN 14
	NOTE F_, 2
	NOTE F_, 2
	LEN 7
	NOTE G_, 2
	NOTE D_, 2
	NOTE F_, 2
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE D_, 2
	NOTE F_, 2
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	LEN 14
	NOTE Ash, 2
	NOTE Ash, 2
	LEN 7
	NOTE G_, 2
	NOTE F_, 2
	NOTE D_, 2
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE D_, 2
	NOTE C_, 2
	LEN 14
	NOTE D_, 2
	LEN 7
	NOTE C_, 2
	NOTE D_, 2
	NOTE F_, 2
	DRUMS $07, DrumPat_5055
	NOTE Ash, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE F_, 3
	NEXT
Pat_4D4F:
	DRUMS $07, DrumPat_5019
	INSTR 0
	LEN 7
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE Ash, 2
	NOTE Ash, 2
	LEN 7
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE F_, 2
	NOTE F_, 2
	LEN 7
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE Ash, 2
	NOTE Ash, 2
	LEN 7
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	NOTE F_, 2
	NOTE D_, 2
	NEXT
Pat_4D97:
	DRUMS $07, DrumPat_505E
	INSTR 0
	LEN 7
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 3
	LEN 14
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 2
	NOTE Dsh, 3
	LEN 14
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE D_, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Ash, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 3
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	NOTE F_, 3
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE Fsh, 2
	NOTE Fsh, 2
	NEXT
Pat_4DC2:
	DRUMS $07, DrumPat_505E
	INSTR 0
	LEN 7
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 3
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	NOTE G_, 3
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE F_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 3
	LEN 14
	NOTE Ash, 2
	LEN 7
	NOTE Ash, 2
	NOTE Ash, 3
	LEN 14
	NOTE Ash, 2
	LEN 7
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE Ash, 2
	NOTE A_, 3
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE Ash, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE D_, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE D_, 3
	NOTE Dsh, 3
	NOTE F_, 2
	NOTE F_, 2
	NOTE Dsh, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 3
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE Ash, 2
	LEN 21
	NOTE F_, 2
	NEXT
Pat_4E0D:
	HWENV $11, $00
	LENGTH $E0
	REST
	INSTR 1
	LEN 7
	NOTE G_, 3
	NOTE D_, 3
	NOTE F_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE D_, 3
	NOTE F_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE D_, 3
	NOTE F_, 3
	NOTE G_, 3
	LEN 14
	NOTE Ash, 3
	NOTE Ash, 3
	LEN 7
	NOTE G_, 3
	NOTE F_, 3
	NOTE D_, 3
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE D_, 3
	NOTE C_, 3
	LEN 14
	NOTE D_, 3
	LEN 7
	NOTE C_, 3
	NOTE D_, 3
	NOTE F_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NEXT
Pat_4E3A:
	INSTR 2
	LEN 7
	NOTE G_, 3
	NOTE D_, 3
	NOTE F_, 3
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE D_, 3
	NOTE F_, 3
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE D_, 3
	NOTE F_, 3
	NOTE G_, 3
	LEN 14
	NOTE D_, 4
	NOTE D_, 4
	LEN 7
	NOTE G_, 3
	NOTE D_, 3
	NOTE F_, 3
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE D_, 3
	NOTE F_, 3
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE D_, 3
	NOTE F_, 3
	NOTE G_, 3
	LEN 14
	NOTE C_, 4
	NOTE A_, 3
	LEN 7
	NOTE G_, 3
	NOTE D_, 3
	NOTE F_, 3
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE D_, 3
	NOTE F_, 3
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE D_, 3
	NOTE F_, 3
	NOTE G_, 3
	LEN 14
	NOTE D_, 4
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE D_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE D_, 4
	NEXT
Pat_4E83:
	INSTR 2
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE D_, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE D_, 4
	LEN 14
	NOTE Dsh, 4
	LEN 21
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE F_, 4
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE Ash, 3
	NEXT
Pat_4EA8:
	INSTR 2
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE C_, 4
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE F_, 4
	NOTE F_, 4
	LEN 7
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 14
	NOTE G_, 4
	NOTE D_, 4
	LEN 7
	NOTE G_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN 14
	NOTE F_, 4
	NOTE C_, 4
	LEN 7
	NOTE A_, 3
	NEXT
Pat_4EF2:
	DUTY_50
	HWENV $81, $00
	ARP_OFF
	LEN 7
	NOTE G_, 2
	NOTE D_, 2
	NOTE F_, 2
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE D_, 2
	NOTE F_, 2
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	LEN 14
	NOTE Ash, 2
	NOTE Ash, 2
	LEN 7
	NOTE G_, 2
	NOTE D_, 2
	NOTE F_, 2
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE D_, 2
	NOTE F_, 2
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	LEN 14
	NOTE F_, 2
	NOTE F_, 2
	INSTR 1
	LEN 7
	NOTE D_, 4
	NOTE A_, 3
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE A_, 3
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	LEN 14
	NOTE F_, 4
	NOTE F_, 4
	LEN 7
	NOTE D_, 4
	NOTE C_, 4
	NOTE A_, 3
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE A_, 3
	NOTE G_, 3
	LEN 14
	NOTE A_, 3
	LEN 7
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	NEXT
Pat_4F42:
	RELEASE $00
	INSTR 2
	LEN 7
	NOTE G_, 4
	NOTE D_, 4
	NOTE F_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE D_, 4
	NOTE F_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE D_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 14
	NOTE Ash, 4
	NOTE Ash, 4
	LEN 7
	NOTE G_, 4
	NOTE D_, 4
	NOTE F_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE D_, 4
	NOTE F_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE D_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 14
	NOTE F_, 4
	NOTE F_, 4
	LEN 7
	NOTE G_, 4
	NOTE D_, 4
	NOTE F_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE D_, 4
	NOTE F_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE D_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 14
	NOTE Ash, 4
	NOTE Ash, 4
	LEN 7
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE F_, 4
	NEXT
Pat_4F8D:
	INSTR 2
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	NOTE F_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	NOTE F_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE A_, 4
	NOTE A_, 4
	LEN 7
	NOTE A_, 4
	NOTE G_, 4
	LEN 14
	NOTE A_, 4
	DUTY_50
	ARP_OFF
	CH_TRANSPOSE $F4
	GLISS_2
	HWENV $F5, $00
	RELEASE $01, $40
	NOTE D_, 5
	LEN 7
	NOTE D_, 5
	LEN 14
	NOTE F_, 5
	NOTE Fsh, 5
	NEXT
Pat_4FBD:
	CH_TRANSPOSE $F4
	LEN 28
	NOTE G_, 5
	GLISS_2
	LEN 7
	NOTE G_, 5
	NOTE A_, 5
	NOTE Ash, 5
	LEN 14
	NOTE A_, 5
	NOTE F_, 5
	LEN 35
	NOTE G_, 5
	LEN 28
	NOTE Ash, 5
	LEN 7
	NOTE Ash, 5
	NOTE C_, 6
	NOTE D_, 6
	LEN 14
	NOTE C_, 6
	LEN 7
	NOTE Ash, 5
	NOTE A_, 5
	LEN 14
	NOTE Ash, 5
	LEN 21
	NOTE F_, 5
	LEN 7
	NOTE Dsh, 5
	NOTE G_, 5
	NOTE A_, 5
	LEN 14
	NOTE Ash, 5
	NOTE A_, 5
	LEN 7
	NOTE G_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE Ash, 5
	LEN 14
	NOTE C_, 6
	NOTE Ash, 5
	LEN 7
	NOTE A_, 5
	NOTE Ash, 5
	LEN 14
	NOTE G_, 5
	LEN 35
	NOTE G_, 5
	GLISS_OFF
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE Ash, 3
	LEN 21
	NOTE F_, 3
	CH_TRANSPOSE $00
	NEXT
DrumPat_4FFC:
	db DRUM_LEVEL + 15, 1, DRUM_LEVEL + 14, 6, DRUM_LEVEL + 13, 6, 5, DRUM_LEVEL + 15
	db 1, DRUM_LEVEL + 14, 6, DRUM_LEVEL + 13, 6, 5, DRUM_LEVEL + 15, 1
	db DRUM_LEVEL + 14, 6, DRUM_LEVEL + 13, 6, 5, DRUM_LEVEL + 15, 1, DRUM_LEVEL + 14
	db 6, DRUM_LEVEL + 13, 6, 4, DRUM_LOOP
DrumPat_5019:
	db 7, 0, 2, 1, 6, 1, 2, 1
	db 6, 1, 2, 1, 2, 6, 2, 6
	db 1, 1, 2, 1, 6, 1, 2, 1
	db 6, 1, 2, 1, 2, 6, 2, 2
	db 1, 1, 2, 1, 6, 1, 2, 1
	db 6, 1, 2, 1, 2, 6, 2, 6
	db 1, 1, 2, 1, 6, 1, 2, 1
	db 6, 1, 2, 1
DrumPat_5055:
	db DRUM_TEMPO + 4, 2, 2, DRUM_TEMPO + 6, 2, DRUM_TEMPO + 7, 2, 2
	db DRUM_LOOP
DrumPat_505E:
	db 7, 0, 2, 1, 5, 1, 2, 5
	db 1, 5, 2, 1, 5, 1, 2, 5
	db 1, 5, 2, 1, 5, 1, 2, 5
	db 1, 5, 2, 1, 5, 1, 2, 2
	db 1, 5, 2, 1, 5, 1, 2, 5
	db 1, 5, 2, 1, 5, 1, 2, 5
	db 1, 5, 2, 1, 5, 1, 2, 5
	db 1, 5, 2, 1, DRUM_TEMPO + 4, 2, 2, DRUM_TEMPO + 6
	db 2, DRUM_TEMPO + 7, 2, 2, DRUM_LOOP

; Instrument table 1, entries 1..3 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr1_0
	dw Instr1_1
	dw Instr1_2
Instr1_0:
	VOLENV 15, $11, $1F, $12
	RELEASE $01, $51
	ARP 0
	WAVE Wave_7598
	END
Instr1_1:
	HWENV $C1, $07, $53
	ARP 11
	DUTY_12
	END
Instr1_2:
	HWENV $E1, $07, $76
	DUTY_75
	VIBRATO $07, $02, $04
	ARP 11
	END

; Song 2: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong2:
	call StopAll
	ld de, Song2_Ch3
	call L49F8
	ld de, Song2_Ch2
	call L49F4
	ld de, Song2_Ch1
	jp L49F0

; Unreferenced (1 bytes)
	db $C9
Song2_Ch3:
	dw Pat_5134
	dw Pat_5134
	dw Pat_51B6
	dw Pat_51C3
	dw Pat_51C3
	ORDER_LOOP Song2_Ch3
Song2_Ch2:
	dw Pat_523B
	dw Pat_523B
	dw Pat_52A4
	dw Pat_52B7
	ORDER_LOOP Song2_Ch2
Song2_Ch1:
	dw Pat_5333
	dw Pat_5333
	dw Pat_53A0
	dw Pat_53B1
	ORDER_LOOP Song2_Ch1
Pat_5103:
	LEN 8
	NOTE D_, 2
	NOTE D_, 2
	LEN 16
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	LEN 8
	NOTE G_, 2
	LEN 16
	NOTE F_, 2
	NOTE D_, 2
	LEN 8
	NOTE D_, 2
	LEN 16
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	LEN 8
	NOTE G_, 2
	NOTE F_, 2
	NOTE C_, 2
	LEN 16
	NOTE D_, 2
	LEN 8
	NOTE D_, 2
	LEN 16
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	LEN 8
	NOTE G_, 2
	LEN 16
	NOTE F_, 2
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	LEN 16
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE G_, 2
	NEXT
Pat_5134:
	DRUMS $08, DrumPat_5407
	INSTR 12
	PAT_CALL Pat_5103
	NOTE A_, 2
	LEN 8
	NOTE C_, 3
	NOTE D_, 3
	NOTE G_, 2
	NOTE F_, 2
	PAT_CALL Pat_5103
	NOTE F_, 2
	LEN 8
	NOTE G_, 2
	NOTE A_, 2
	NOTE C_, 3
	NOTE D_, 3
	DRUMS $08, DrumPat_544A
	LEN 8
	NOTE F_, 2
	NOTE F_, 2
	INSTR 14
	NOTE F_, 4
	INSTR 12
	LEN 16
	NOTE F_, 2
	LEN 8
	NOTE F_, 2
	INSTR 14
	NOTE F_, 4
	INSTR 12
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 2
	INSTR 14
	NOTE G_, 4
	INSTR 12
	LEN 16
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	INSTR 14
	NOTE G_, 4
	INSTR 12
	NOTE G_, 2
	NOTE D_, 2
	NOTE D_, 2
	INSTR 15
	NOTE D_, 4
	INSTR 12
	LEN 16
	NOTE C_, 2
	LEN 8
	NOTE C_, 2
	INSTR 15
	NOTE D_, 4
	INSTR 12
	NOTE D_, 2
	NOTE D_, 3
	NOTE C_, 3
	INSTR 15
	NOTE D_, 4
	INSTR 12
	LEN 16
	NOTE D_, 3
	LEN 8
	NOTE A_, 2
	INSTR 14
	NOTE F_, 4
	INSTR 12
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 2
	INSTR 14
	NOTE G_, 4
	INSTR 12
	LEN 16
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	INSTR 14
	NOTE G_, 4
	INSTR 12
	NOTE G_, 2
	NOTE E_, 2
	NOTE E_, 2
	INSTR 14
	NOTE E_, 4
	INSTR 12
	LEN 16
	NOTE E_, 2
	LEN 8
	NOTE E_, 2
	INSTR 14
	NOTE E_, 4
	INSTR 12
	NOTE E_, 2
	LEN 16
	NOTE A_, 2
	INSTR 14
	LEN 8
	NOTE A_, 4
	INSTR 12
	LEN 16
	NOTE A_, 2
	LEN 8
	NOTE A_, 2
	LEN 16
	NOTE G_, 2
	LEN 8
	NOTE A_, 2
	LEN 16
	NOTE C_, 3
	LEN 8
	NOTE A_, 2
	LEN 16
	NOTE G_, 2
	LEN 8
	NOTE F_, 2
	WAIT
	NEXT
Pat_51B6:
	DRUMS $08, DrumPat_546F
	VOLENV 15, $00, $19, $15
	LENGTH $80
	NOTE D_, 2
	WAIT
	NEXT
Pat_51C3:
	DRUMS $08, DrumPat_5493
	INSTR 12
	LEN 8
	REPEAT 6
	NOTE D_, 2
	NOTE D_, 3
	REPEAT_END
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	REPEAT 6
	NOTE D_, 2
	NOTE D_, 3
	REPEAT_END
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	REPEAT 6
	NOTE D_, 2
	NOTE D_, 3
	REPEAT_END
	NOTE G_, 2
	NOTE G_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE D_, 3
	LEN 16
	NOTE D_, 3
	LEN 8
	NOTE C_, 3
	LEN 16
	NOTE C_, 3
	LEN 8
	NOTE A_, 2
	LEN 16
	NOTE A_, 2
	LEN 8
	NOTE G_, 2
	LEN 16
	NOTE G_, 2
	NOTE F_, 2
	LEN 8
	NOTE E_, 2
	NOTE Dsh, 2
	NEXT
Pat_51F5:
	INSTR 9
	LEN 8
	NOTE D_, 4
	NOTE C_, 4
	INSTR 5
	LEN 16
	NOTE D_, 4
	INSTR 9
	NOTE C_, 4
	INSTR 5
	NOTE D_, 4
	INSTR 9
	NOTE C_, 4
	INSTR 5
	LEN 8
	NOTE D_, 4
	INSTR 9
	LEN 24
	NOTE D_, 4
	INSTR 5
	LEN 8
	NOTE D_, 4
	INSTR 9
	LEN 16
	NOTE D_, 4
	LEN 8
	NOTE C_, 4
	INSTR 5
	LEN 16
	NOTE D_, 4
	INSTR 9
	NOTE C_, 4
	INSTR 5
	NOTE D_, 4
	INSTR 9
	NOTE F_, 3
	INSTR 5
	LEN 8
	NOTE D_, 4
	INSTR 9
	LEN 24
	NOTE D_, 3
	INSTR 5
	LEN 16
	NOTE D_, 4
	INSTR 9
	LEN 8
	NOTE D_, 4
	NOTE C_, 4
	INSTR 5
	LEN 16
	NOTE D_, 4
	INSTR 9
	NOTE C_, 4
	INSTR 5
	NOTE D_, 4
	INSTR 9
	NOTE C_, 4
	INSTR 5
	LEN 8
	NOTE D_, 4
	INSTR 9
	LEN 24
	NOTE D_, 4
	INSTR 5
	LEN 16
	NOTE D_, 4
	INSTR 9
	NOTE G_, 4
	NEXT
Pat_523B:
	PAT_CALL Pat_51F5
	INSTR 4
	NOTE G_, 4
	INSTR 13
	NOTE B_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 13
	NOTE C_, 4
	INSTR 4
	LEN 8
	NOTE G_, 4
	INSTR 13
	LEN 24
	NOTE B_, 3
	INSTR 4
	LEN 16
	NOTE G_, 4
	PAT_CALL Pat_51F5
	INSTR 4
	NOTE G_, 4
	INSTR 13
	NOTE D_, 4
	INSTR 4
	NOTE G_, 4
	INSTR 13
	NOTE F_, 4
	INSTR 4
	LEN 8
	NOTE G_, 4
	INSTR 13
	LEN 24
	NOTE G_, 4
	INSTR 4
	LEN 16
	NOTE G_, 4
	INSTR 13
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE A_, 4
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE G_, 4
	LEN 16
	NOTE A_, 4
	NOTE B_, 4
	LEN 8
	NOTE B_, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE A_, 4
	LEN 16
	NOTE B_, 4
	NOTE F_, 4
	LEN 8
	NOTE F_, 4
	LEN 16
	NOTE E_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 24
	NOTE A_, 3
	NOTE D_, 4
	LEN 8
	NOTE C_, 4
	LEN 16
	NOTE B_, 4
	LEN 8
	NOTE B_, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE A_, 4
	LEN 16
	NOTE B_, 4
	NOTE Gsh, 4
	LEN 8
	NOTE Gsh, 4
	LEN 16
	NOTE Fsh, 4
	LEN 8
	NOTE Fsh, 4
	LEN 16
	NOTE Gsh, 4
	NOTE Csh, 5
	LEN 8
	NOTE Csh, 5
	LEN 16
	NOTE B_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE C_, 4
	LEN 8
	NOTE A_, 3
	LEN 16
	NOTE G_, 3
	NOTE F_, 3
	NEXT
Pat_52A4:
	LEN 8
	NOTE D_, 2
	HWENV $80, $00
	RELEASE $00
	AUTODUTY $08
	NOTE D_, 2
	LENGTH $70
	WAIT
	LENGTH $80
	WAIT
	AUTODUTY $00
	NEXT
Pat_52B7:
	REPEAT 2
	INSTR 13
	LEN 8
	NOTE A_, 4
	NOTE D_, 4
	NOTE G_, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE G_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE G_, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE G_, 4
	LEN 16
	NOTE C_, 5
	NOTE C_, 5
	LEN 8
	NOTE A_, 4
	NOTE D_, 4
	NOTE G_, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE G_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE G_, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE G_, 4
	LEN 16
	NOTE C_, 5
	NOTE B_, 4
	LEN 8
	NOTE A_, 4
	NOTE D_, 4
	NOTE G_, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE G_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE G_, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE G_, 4
	LEN 16
	NOTE C_, 5
	RELEASE $00
	HWENV $50, $00
	DUTY_50
	GLISS_3
	LEN 8
	NOTE D_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE Csh, 5
	NOTE D_, 5
	NOTE D_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE Gsh, 4
	NOTE D_, 4
	NOTE G_, 4
	GLISS_OFF
	REPEAT_END
	NEXT
Pat_530B:
	INSTR 13
	DUTY_50
	VIBRATO $10, $02, $05
	LEN 8
	NOTE D_, 5
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	NOTE C_, 5
	NOTE A_, 4
	LEN 24
	NOTE C_, 5
	LEN 32
	NOTE D_, 5
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	NOTE C_, 5
	NOTE A_, 4
	LEN 24
	NOTE F_, 4
	LEN 40
	NOTE D_, 4
	LEN 8
	NOTE D_, 5
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	NOTE C_, 5
	NOTE A_, 4
	LEN 24
	NOTE C_, 5
	NOTE D_, 5
	NEXT
Pat_5333:
	PAT_CALL Pat_530B
	LENGTH $58
	NOTE G_, 4
	LEN 8
	NOTE A_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE A_, 4
	PAT_CALL Pat_530B
	LEN 16
	NOTE F_, 5
	LENGTH $48
	NOTE G_, 5
	LEN 8
	NOTE G_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE A_, 5
	DUTY_75
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE C_, 5
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE C_, 5
	LEN 16
	NOTE C_, 5
	NOTE D_, 5
	LEN 8
	NOTE D_, 5
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE D_, 5
	LEN 16
	NOTE D_, 5
	NOTE A_, 4
	LEN 8
	NOTE A_, 4
	LEN 16
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	DUTY_50
	LEN 8
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE F_, 5
	DUTY_75
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE D_, 5
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE D_, 5
	LEN 16
	NOTE D_, 5
	NOTE B_, 4
	LEN 8
	NOTE B_, 4
	LEN 16
	NOTE B_, 4
	LEN 8
	NOTE B_, 4
	LEN 16
	NOTE B_, 4
	NOTE E_, 5
	LEN 8
	NOTE E_, 5
	LEN 16
	NOTE E_, 5
	NOTE E_, 5
	NOTE E_, 5
	LEN 8
	DUTY_50
	HWENV $F1, $00
	RELEASE $00
	NOTE C_, 3
	WAIT
	LEN 8
	NOTE A_, 2
	NOTE G_, 2
	WAIT
	NOTE F_, 2
	WAIT
	NEXT
Pat_53A0:
	DUTY_75
	HWENV $90, $00
	VIBRATO $42, $F8, $01
	LENGTH $80
	NOTE D_, 2
	WAIT
	VIBRATO $10, $02, $05
	NEXT
Pat_53B1:
	REPEAT 2
	INSTR 13
	LEN 16
	NOTE D_, 5
	GLISS_2
	LEN 8
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE C_, 5
	LEN 16
	NOTE F_, 5
	NOTE F_, 5
	NOTE D_, 5
	LEN 8
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE C_, 5
	LEN 16
	NOTE G_, 5
	NOTE G_, 5
	NOTE D_, 5
	LEN 8
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE C_, 5
	LEN 16
	NOTE F_, 5
	GLISS_3
	RELEASE $00
	HWENV $A0, $00
	DUTY_50
	LEN 8
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE Csh, 5
	NOTE D_, 5
	NOTE D_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE F_, 4
	GLISS_OFF
	REPEAT_END
	NEXT
DrumPat_5407:
	db 7, 0, 4, 0, 2, 0, 4, 0
	db 1, 0, 4, 0, 2, 0, 4, 5
	db 1, 0, 4, 0, 2, 0, 4, 0
	db 1, 0, 4, 0, 2, 0, 4, 2
	db DRUM_REPEAT + 3, 1, 0, 4, 0, 2, 0, 4
	db 0, 1, 0, 4, 0, 2, 0, 4
	db 5, 1, 0, 4, 0, 2, 0, 4
	db 0, 1, 0, 4, 0, 2, 0, 4
	db 2, DRUM_REPEAT_END, DRUM_LOOP
DrumPat_544A:
	db DRUM_REPEAT + 3, 7, 0, 2, 1, 5, 1, 2
	db 5, DRUM_REPEAT_END, 5, 1, 2, 5, 1, 1
	db 2, 5, DRUM_REPEAT + 3, 7, 0, 2, 1, 5
	db 1, 2, 5, DRUM_REPEAT_END, 7, 8, 0, 9
	db 9, 0, 10, 10, DRUM_LOOP
DrumPat_546F:
	db 7, 0, 1, 6, 2, 6, 1, 1
	db 5, 2, 1, 6, 2, 6, 5, 1
	db 1, 6, 1, 6, 2, 6, 1, 1
	db 5, 2, 1, 1, 2, 6, DRUM_TEMPO + 4, 2
	db 2, DRUM_TEMPO + 8, 2, DRUM_LOOP
DrumPat_5493:
	db 7, 0, 2, 1, 5, 1, 2, 5
	db 5, 1, 2, 5, 1, 1, 2, 5
	db DRUM_REPEAT + 3, 1, 5, 2, 1, 5, 1, 2
	db 5, DRUM_REPEAT_END, 7, 8, 0, 9, 9, 0
	db 10, 10, 7, 0, 2, 1, 5, 1
	db 2, 5, 1, 5, 2, 5, 1, 2
	db DRUM_TEMPO + 4, 2, 2, DRUM_TEMPO + 8, 2, DRUM_LOOP

; Song 3: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong3:
	call StopAll
	ld de, Song3_Ch1
	call L49F0
	ld de, Song3_Ch3
	call L49F8
	ld de, Song3_Ch2
	jp L49F4
Song3_Ch1:
	dw Pat_54E4
Song3_Ch3:
	dw Pat_553E
Song3_Ch2:
	dw Pat_559E
Pat_54E4:
	INSTR 13
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	LENGTH $31
	REST
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE D_, 4
	LENGTH $38
	REST
	LEN 7
	NOTE Ash, 3
	LEN 14
	NOTE Ash, 3
	NOTE A_, 3
	NOTE Ash, 3
	LEN 7
	NOTE A_, 3
	NOTE Ash, 3
	LEN 14
	NOTE Ash, 3
	NOTE A_, 3
	NOTE Ash, 3
	LEN 7
	NOTE B_, 3
	NOTE C_, 4
	LEN 14
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	LEN 7
	NOTE B_, 3
	NOTE C_, 4
	LEN 14
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	LEN 7
	NOTE Csh, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE Ash, 3
	LEN 35
	NOTE G_, 3
	LEN 14
	NOTE Csh, 4
	LEN 7
	NOTE C_, 4
	LEN 35
	NOTE Ash, 3
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE G_, 4
	LEN 35
	NOTE D_, 4
	LEN 21
	NOTE Csh, 5
	LEN 14
	NOTE C_, 5
	NOTE Ash, 4
	LENGTH $3F
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	LENGTH $B2
	REST
	STOP_ALL
Pat_553E:
	INSTR 12
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE F_, 2
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE F_, 2
	LENGTH $46
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE F_, 2
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE Ash, 2
	LENGTH $46
	NOTE G_, 2
	LEN 7
	NOTE Dsh, 2
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 2
	NOTE Dsh, 2
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	LEN 7
	NOTE E_, 2
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	LEN 7
	NOTE Fsh, 2
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	LEN 7
	NOTE C_, 2
	NOTE D_, 2
	NOTE F_, 2
	DRUMS $07, DrumPat_5642
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE F_, 2
	NOTE F_, 3
	LEN 7
	NOTE F_, 2
	LENGTH $C0
	NOTE G_, 2
	STOP_ALL
Pat_559E:
	HWENV $90, $00
	RELEASE $01, $20
	VIBRATO $07, $02, $05
	DUTY_50
	DRUMS $07, DrumPat_5635
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE G_, 3
	DRUMS_OFF
	LEN 7
	WAIT2
	LEN 14
	NOTE G_, 5
	LEN 7
	NOTE F_, 5
	LEN 14
	NOTE D_, 5
	LEN 7
	NOTE F_, 5
	NOTE F_, 3
	DRUMS $07, DrumPat_5635
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE Ash, 3
	LEN 14
	NOTE G_, 3
	DRUMS_OFF
	LEN 7
	WAIT2
	NOTE G_, 4
	GLISS_3
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE D_, 5
	NOTE F_, 5
	NOTE G_, 5
	DRUMS $07, DrumPat_5639
	LEN 42
	NOTE Ash, 5
	LEN 7
	NOTE A_, 5
	LEN 42
	NOTE G_, 5
	LEN 7
	NOTE D_, 5
	NOTE F_, 5
	NOTE Fsh, 5
	LEN 14
	NOTE G_, 5
	LEN 7
	NOTE Ash, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE F_, 5
	LEN 42
	NOTE C_, 5
	LEN 7
	NOTE G_, 4
	NOTE D_, 5
	NOTE G_, 4
	LEN 14
	NOTE C_, 5
	LEN 7
	NOTE Ash, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	NOTE D_, 5
	NOTE G_, 4
	LEN 14
	NOTE Csh, 5
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE G_, 4
	NOTE G_, 5
	NOTE G_, 4
	LEN 14
	NOTE F_, 5
	LEN 7
	NOTE G_, 5
	LEN 14
	NOTE D_, 5
	LEN 7
	NOTE G_, 5
	NOTE D_, 6
	NOTE G_, 5
	LEN 14
	NOTE Csh, 6
	LEN 7
	NOTE G_, 5
	LEN 14
	NOTE C_, 6
	NOTE Ash, 5
	LENGTH $3F
	NOTE G_, 5
	DRUMS $FF, DrumPat_5635
	HWENV $92, $00
	RELEASE $00
	LEN 7
	NOTE G_, 5
	LEN 12
	GLIDE $FF
	NOTE G_, 5
	DRUMS_OFF
	LENGTH $AD
	REST
	GLIDE_OFF
	STOP_ALL
DrumPat_5635:
	db 7, 0, 1, DRUM_LOOP
DrumPat_5639:
	db 1, 1, 2, 1, 5, 1, 2, 5
	db DRUM_LOOP
DrumPat_5642:
	db 7, 8, 0, 9, 0, 10, 0, 1          ; no DRUM_LOOP: the pattern runs into the next data

; Song 4: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong4:
	call StopAll
	ld de, Song4_Ch1
	call L49F0
	ld de, Song4_Ch2
	call L49F4
	ld de, Song4_Ch3
	jp L49F8
Pat_565F:
	TRANSPOSE $00
	NEXT
Pat_5662:
	TRANSPOSE $02
	NEXT
Song4_Ch3:
	dw Pat_565F
	dw Pat_56A5
	dw Pat_56F6
	dw Pat_56F6
	dw Pat_56A5
	dw Pat_5662
	dw Pat_56A5
	dw Pat_56F6
	dw Pat_56F6
	dw Pat_56A5
	ORDER_LOOP Song4_Ch3
Song4_Ch2:
	dw Pat_5820
	dw Pat_585B
	dw Pat_5891
	dw Pat_58CA
	dw Pat_585B
	dw Pat_5891
	dw Pat_58CA
	dw Pat_5820
	ORDER_LOOP Song4_Ch2
Song4_Ch1:
	dw Pat_58F7
	dw Pat_5942
	dw Pat_5977
	dw Pat_59AF
	dw Pat_5942
	dw Pat_5977
	dw Pat_59AF
	dw Pat_58F7
	ORDER_LOOP Song4_Ch1
Pat_56A5:
	DRUMS $07, DrumPat_5A14
	INSTR 12
	LEN 14
	NOTE D_, 2
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 11
	LEN 7
	NOTE D_, 4
	INSTR 12
	LEN 14
	NOTE C_, 3
	INSTR 11
	LEN 7
	NOTE C_, 4
	INSTR 12
	LEN 14
	NOTE A_, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 2
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 11
	LEN 7
	NOTE D_, 4
	INSTR 12
	LEN 14
	NOTE C_, 3
	INSTR 11
	LEN 7
	NOTE C_, 4
	INSTR 12
	LEN 14
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE D_, 2
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 11
	LEN 7
	NOTE D_, 4
	INSTR 12
	LEN 14
	NOTE C_, 3
	INSTR 11
	LEN 7
	NOTE C_, 4
	INSTR 12
	LEN 14
	NOTE A_, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 2
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 11
	LEN 7
	NOTE D_, 4
	INSTR 12
	LEN 14
	NOTE C_, 3
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE Gsh, 2
	NOTE A_, 2
	NOTE C_, 3
	NEXT
Pat_56F6:
	DRUMS $07, DrumPat_5A37
	INSTR 12
	LEN 14
	NOTE D_, 2
	INSTR 11
	NOTE D_, 3
	INSTR 12
	LEN 7
	NOTE D_, 2
	INSTR 11
	LEN 14
	NOTE D_, 3
	INSTR 12
	NOTE G_, 2
	INSTR 11
	LEN 7
	NOTE G_, 3
	INSTR 12
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	INSTR 11
	LEN 7
	NOTE G_, 3
	NOTE G_, 2
	INSTR 12
	LEN 14
	NOTE D_, 2
	INSTR 11
	NOTE D_, 3
	INSTR 12
	LEN 7
	NOTE D_, 2
	INSTR 11
	LEN 14
	NOTE D_, 3
	INSTR 12
	NOTE G_, 2
	INSTR 11
	LEN 7
	NOTE G_, 3
	INSTR 12
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	INSTR 11
	LEN 7
	NOTE G_, 3
	NOTE G_, 2
	INSTR 12
	LEN 14
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	LEN 7
	NOTE F_, 2
	INSTR 11
	LEN 14
	NOTE F_, 3
	INSTR 12
	NOTE G_, 2
	INSTR 11
	LEN 7
	NOTE G_, 3
	INSTR 12
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	INSTR 11
	LEN 7
	NOTE G_, 3
	NOTE G_, 2
	INSTR 12
	LEN 14
	NOTE A_, 2
	INSTR 11
	LEN 7
	NOTE A_, 3
	INSTR 12
	LEN 14
	NOTE A_, 2
	INSTR 11
	LEN 7
	NOTE A_, 3
	INSTR 12
	LEN 14
	NOTE A_, 2
	INSTR 11
	LEN 7
	NOTE A_, 3
	INSTR 12
	NOTE C_, 3
	LEN 14
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	INSTR 12
	LEN 14
	NOTE D_, 2
	INSTR 11
	NOTE D_, 3
	INSTR 12
	LEN 7
	NOTE D_, 2
	INSTR 11
	LEN 14
	NOTE D_, 3
	INSTR 12
	NOTE G_, 2
	INSTR 11
	LEN 7
	NOTE G_, 3
	INSTR 12
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	INSTR 11
	LEN 7
	NOTE G_, 3
	NOTE G_, 2
	INSTR 12
	LEN 14
	NOTE D_, 2
	INSTR 11
	NOTE D_, 3
	INSTR 12
	LEN 7
	NOTE D_, 2
	INSTR 11
	LEN 14
	NOTE D_, 3
	INSTR 12
	NOTE G_, 2
	INSTR 11
	LEN 7
	NOTE G_, 3
	INSTR 12
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	INSTR 11
	LEN 7
	NOTE G_, 3
	NOTE G_, 2
	INSTR 12
	LEN 14
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	LEN 7
	NOTE F_, 2
	INSTR 11
	LEN 14
	NOTE F_, 3
	INSTR 12
	NOTE G_, 2
	INSTR 11
	LEN 7
	NOTE G_, 3
	INSTR 12
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	INSTR 11
	LEN 7
	NOTE G_, 3
	NOTE G_, 2
	INSTR 12
	LEN 14
	NOTE A_, 2
	INSTR 11
	LEN 7
	NOTE A_, 3
	INSTR 12
	LEN 14
	NOTE A_, 2
	INSTR 11
	LEN 7
	NOTE A_, 3
	INSTR 12
	LEN 14
	NOTE A_, 2
	INSTR 11
	LEN 7
	NOTE A_, 3
	INSTR 12
	NOTE G_, 2
	LEN 14
	NOTE A_, 2
	LEN 7
	NOTE A_, 2
	NOTE A_, 2
	LEN 14
	NOTE Gsh, 2
	INSTR 12
	LEN 14
	NOTE G_, 2
	INSTR 11
	NOTE G_, 3
	INSTR 12
	LEN 7
	NOTE G_, 2
	INSTR 11
	LEN 14
	NOTE G_, 3
	INSTR 12
	NOTE G_, 2
	INSTR 11
	LEN 7
	NOTE G_, 3
	INSTR 12
	LEN 14
	NOTE G_, 2
	NOTE F_, 2
	INSTR 11
	LEN 7
	NOTE F_, 3
	NOTE F_, 2
	INSTR 12
	LEN 14
	NOTE G_, 2
	INSTR 11
	NOTE G_, 3
	INSTR 12
	LEN 7
	NOTE G_, 2
	INSTR 11
	LEN 14
	NOTE G_, 3
	INSTR 12
	NOTE G_, 2
	INSTR 11
	LEN 7
	NOTE G_, 3
	INSTR 12
	LEN 14
	NOTE G_, 2
	NOTE F_, 2
	INSTR 11
	LEN 7
	NOTE G_, 2
	NOTE Gsh, 2
	INSTR 12
	LEN 14
	NOTE A_, 2
	INSTR 11
	NOTE A_, 3
	INSTR 12
	LEN 7
	NOTE A_, 2
	INSTR 11
	LEN 14
	NOTE A_, 3
	INSTR 12
	NOTE A_, 2
	INSTR 11
	LEN 7
	NOTE A_, 3
	INSTR 12
	LEN 14
	NOTE A_, 2
	NOTE G_, 2
	INSTR 11
	LEN 7
	NOTE G_, 2
	NOTE Gsh, 2
	INSTR 12
	LEN 14
	NOTE A_, 2
	INSTR 11
	LEN 7
	NOTE A_, 3
	INSTR 12
	LEN 14
	NOTE A_, 2
	INSTR 11
	LEN 7
	NOTE A_, 3
	INSTR 12
	LEN 14
	NOTE A_, 2
	INSTR 11
	LEN 7
	NOTE A_, 3
	INSTR 12
	LEN 14
	NOTE A_, 2
	LEN 7
	NOTE C_, 3
	LEN 14
	NOTE A_, 2
	NOTE G_, 2
	NEXT
Pat_5820:
	VIBRATO $07, $01, $04
	INSTR 9
	LEN 14
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	NEXT
Pat_585B:
	INSTR 10
	LEN 21
	NOTE A_, 3
	NOTE D_, 4
	LEN 14
	NOTE F_, 4
	NOTE D_, 4
	INSTR 9
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	INSTR 10
	LEN 21
	NOTE A_, 4
	NOTE F_, 4
	LEN 14
	NOTE D_, 4
	LEN 21
	NOTE B_, 3
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	NOTE A_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE F_, 4
	LEN 21
	NOTE D_, 4
	NOTE B_, 3
	LEN 14
	NOTE D_, 4
	NOTE E_, 4
	INSTR 9
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE G_, 4
	LEN 21
	NOTE A_, 4
	INSTR 10
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NEXT
Pat_5891:
	INSTR 10
	LEN 21
	NOTE A_, 3
	NOTE D_, 4
	LEN 14
	NOTE F_, 4
	NOTE D_, 4
	INSTR 9
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	INSTR 10
	LEN 21
	NOTE A_, 4
	NOTE F_, 4
	LEN 14
	NOTE D_, 4
	LEN 21
	NOTE B_, 3
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	NOTE A_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE F_, 4
	LEN 21
	NOTE D_, 4
	NOTE B_, 3
	LEN 14
	NOTE D_, 4
	NOTE E_, 4
	INSTR 9
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE G_, 4
	LEN 21
	NOTE A_, 4
	INSTR 10
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE E_, 4
	LEN 7
	NOTE E_, 4
	NOTE E_, 4
	LEN 14
	NOTE Dsh, 4
	NEXT
Pat_58CA:
	INSTR 10
	LEN 28
	NOTE G_, 4
	LEN 21
	NOTE G_, 5
	NOTE F_, 5
	LEN 14
	NOTE E_, 5
	NOTE D_, 5
	NOTE B_, 4
	NOTE D_, 5
	LEN 7
	NOTE E_, 5
	LEN 42
	NOTE D_, 5
	INSTR 9
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE G_, 3
	NOTE F_, 3
	INSTR 10
	LEN 7
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 28
	NOTE A_, 4
	LEN 21
	NOTE A_, 5
	NOTE G_, 5
	LEN 14
	NOTE Fsh, 5
	NOTE E_, 5
	LEN 7
	NOTE D_, 5
	LEN 21
	NOTE A_, 5
	LENGTH $4D
	NOTE E_, 5
	LEN 7
	NOTE A_, 2
	NOTE Ash, 2
	NOTE B_, 2
	NEXT
Pat_58F7:
	VIBRATO $07, $01, $04
	INSTR 9
	LEN 7
	NOTE A_, 4
	NOTE A_, 4
	LEN 14
	NOTE A_, 4
	NOTE A_, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE B_, 4
	LEN 14
	NOTE B_, 4
	NOTE B_, 4
	LEN 7
	NOTE B_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE C_, 5
	LEN 14
	NOTE C_, 5
	NOTE C_, 5
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE B_, 4
	LEN 14
	NOTE B_, 4
	NOTE B_, 4
	LEN 7
	NOTE B_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE A_, 4
	LEN 14
	NOTE A_, 4
	NOTE A_, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE B_, 4
	LEN 14
	NOTE B_, 4
	NOTE B_, 4
	LEN 7
	NOTE B_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE C_, 5
	LEN 14
	NOTE C_, 5
	NOTE C_, 5
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE Gsh, 3
	NOTE A_, 3
	LEN 7
	NOTE C_, 4
	NOTE D_, 4
	NEXT
Pat_5942:
	INSTR 10
	LEN 21
	NOTE D_, 4
	NOTE F_, 4
	LEN 14
	NOTE A_, 4
	LEN 21
	NOTE G_, 4
	INSTR 9
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	INSTR 10
	NOTE B_, 4
	NOTE C_, 5
	LEN 21
	NOTE D_, 5
	NOTE A_, 4
	LEN 14
	NOTE F_, 4
	LEN 21
	NOTE A_, 4
	NOTE G_, 4
	LEN 28
	NOTE F_, 4
	LEN 14
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	LEN 21
	NOTE G_, 4
	NOTE A_, 4
	LEN 14
	NOTE B_, 4
	NOTE A_, 4
	INSTR 9
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE E_, 4
	LEN 7
	NOTE D_, 4
	LEN 21
	NOTE E_, 4
	INSTR 10
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE A_, 3
	NOTE G_, 3
	NOTE F_, 3
	NEXT
Pat_5977:
	INSTR 10
	LEN 21
	NOTE D_, 4
	NOTE F_, 4
	LEN 14
	NOTE A_, 4
	LEN 21
	NOTE G_, 4
	INSTR 9
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	INSTR 10
	NOTE B_, 4
	NOTE C_, 5
	LEN 21
	NOTE D_, 5
	NOTE A_, 4
	LEN 14
	NOTE F_, 4
	LEN 21
	NOTE A_, 4
	NOTE G_, 4
	LEN 28
	NOTE F_, 4
	LEN 14
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	LEN 21
	NOTE B_, 4
	NOTE G_, 4
	LEN 14
	NOTE B_, 4
	NOTE Csh, 5
	INSTR 9
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE E_, 4
	LEN 7
	NOTE D_, 4
	LEN 21
	NOTE E_, 4
	INSTR 10
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE A_, 4
	NOTE A_, 4
	LEN 14
	NOTE Gsh, 4
	NEXT
Pat_59AF:
	INSTR 10
	LEN 7
	NOTE G_, 3
	INSTR 9
	NOTE G_, 3
	NOTE G_, 4
	NOTE G_, 3
	INSTR 10
	NOTE G_, 4
	INSTR 9
	NOTE G_, 3
	NOTE E_, 4
	INSTR 10
	LEN 14
	NOTE F_, 4
	INSTR 9
	LEN 7
	NOTE G_, 3
	INSTR 10
	NOTE E_, 4
	INSTR 9
	NOTE G_, 3
	INSTR 10
	NOTE D_, 4
	INSTR 9
	NOTE G_, 3
	INSTR 10
	NOTE B_, 3
	INSTR 9
	NOTE D_, 4
	INSTR 10
	NOTE D_, 4
	INSTR 9
	NOTE G_, 3
	INSTR 10
	NOTE E_, 4
	NOTE D_, 4
	INSTR 9
	NOTE F_, 4
	NOTE G_, 3
	NOTE E_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE G_, 3
	NOTE G_, 4
	NOTE G_, 3
	NOTE F_, 4
	NOTE G_, 3
	NOTE E_, 4
	NOTE D_, 4
	INSTR 10
	NOTE A_, 3
	INSTR 9
	NOTE A_, 3
	NOTE A_, 4
	NOTE A_, 3
	INSTR 10
	NOTE A_, 4
	INSTR 9
	NOTE A_, 3
	NOTE E_, 4
	INSTR 10
	LEN 14
	NOTE G_, 4
	INSTR 9
	LEN 7
	NOTE A_, 3
	INSTR 10
	NOTE Fsh, 4
	INSTR 9
	NOTE A_, 3
	INSTR 10
	NOTE E_, 4
	INSTR 9
	NOTE A_, 3
	INSTR 10
	NOTE D_, 4
	LEN 14
	NOTE A_, 4
	INSTR 9
	LEN 7
	NOTE A_, 3
	INSTR 10
	NOTE E_, 4
	INSTR 9
	NOTE A_, 3
	NOTE G_, 4
	NOTE A_, 3
	NOTE E_, 4
	LEN 14
	NOTE Csh, 4
	LEN 7
	NOTE A_, 3
	NOTE A_, 4
	NOTE A_, 3
	NOTE G_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE Csh, 4
	NEXT
DrumPat_5A14:
	db DRUM_REPEAT + 3, 7, 0, 14, 0, 2, 0, 1
	db 1, 0, 2, 1, 0, 2, 0, 1
	db 0, DRUM_REPEAT_END, 7, 0, 14, 0, 2, 0
	db 1, 1, 0, 8, 8, 0, 9, 0
	db 10, 10, DRUM_LOOP
DrumPat_5A37:
	db 7, 0, 2, 1, 6, 1, 2, 4
	db 0, 1, 2, 5, 1, 5, 2, 1
	db DRUM_REPEAT + 2, 1, 6, 2, 1, 6, 1, 2
	db 4, 0, 1, 2, 5, 1, 5, 2
	db 1, DRUM_REPEAT_END, 1, 6, 2, 6, 1, 6
	db 2, 6, 1, 2, 2, 6, 2, 6
	db 2, 2, DRUM_LOOP

; Song 5: instrument table 2, arpeggio table 1 (the one SndInit sets)
PlaySong5:
	call StopAll
	ld a, $5D
	ld [wInstrTableHi], a
	ld a, $C9
	ld [wInstrTable], a
	ld de, Song5_Ch3
	call L49F8
	ld de, Song5_Ch2
	call L49F4
	ld de, Song5_Ch1
	jp L49F0

; Unreferenced (1 bytes)
	db $C9
Pat_5A8A:
	TRANSPOSE $00
	NEXT
Pat_5A8D:
	TRANSPOSE $02
	NEXT
Song5_Ch3:
	dw Pat_5AF0
	dw Pat_5AF3
	dw Pat_5AF3
	dw Pat_5B35
	dw Pat_5B77
	dw Pat_5AF3
	dw Pat_5AF3
	dw Pat_5B35
	dw Pat_5B77
	dw Pat_5AF0
	ORDER_LOOP Song5_Ch3
Song5_Ch2:
	dw Pat_5BB0
	dw Pat_5BE9
	dw Pat_5BE9
	dw Pat_5C27
	dw Pat_5C65
	dw Pat_5BE9
	dw Pat_5BE9
	dw Pat_5C27
	dw Pat_5C65
	dw Pat_5BB0
	ORDER_LOOP Song5_Ch2
Song5_Ch1:
	dw Pat_5A8A
	dw Pat_5C9C
	dw Pat_5CE0
	dw Pat_5D20
	dw Pat_5D54
	dw Pat_5D7A
	dw Pat_5CE0
	dw Pat_5D20
	dw Pat_5D54
	dw Pat_5D7A
	dw Pat_5C9C
	dw Pat_5A8D
	dw Pat_5C9C
	dw Pat_5CE0
	dw Pat_5D20
	dw Pat_5D54
	dw Pat_5D7A
	dw Pat_5CE0
	dw Pat_5D20
	dw Pat_5D54
	dw Pat_5D7A
	dw Pat_5C9C
	ORDER_LOOP Song5_Ch1
Pat_5AF0:
	WAVE Wave_7598
Pat_5AF3:
	INSTR 12
	LEN 20
	NOTE F_, 2
	INSTR 11
	LEN 10
	NOTE F_, 3
	INSTR 12
	LEN 20
	NOTE Gsh, 2
	INSTR 11
	LEN 10
	NOTE Gsh, 3
	INSTR 12
	NOTE Ash, 2
	INSTR 11
	NOTE Ash, 3
	INSTR 12
	LEN 20
	NOTE F_, 2
	INSTR 11
	LEN 10
	NOTE F_, 3
	INSTR 12
	LEN 20
	NOTE Gsh, 2
	INSTR 11
	LEN 10
	NOTE Gsh, 3
	INSTR 12
	NOTE Ash, 2
	LEN 5
	NOTE Dsh, 2
	NOTE E_, 2
	LEN 20
	NOTE F_, 2
	INSTR 11
	LEN 10
	NOTE F_, 3
	INSTR 12
	LEN 20
	NOTE Gsh, 2
	INSTR 11
	LEN 10
	NOTE Gsh, 3
	INSTR 12
	NOTE Ash, 2
	INSTR 11
	NOTE Ash, 3
	INSTR 12
	LEN 20
	NOTE F_, 2
	INSTR 11
	LEN 10
	NOTE F_, 3
	INSTR 12
	LEN 20
	NOTE Gsh, 2
	INSTR 11
	LEN 10
	NOTE Gsh, 3
	INSTR 12
	NOTE Ash, 2
	LEN 5
	NOTE Dsh, 2
	NOTE E_, 2
	NEXT
Pat_5B35:
	INSTR 12
	LEN 20
	NOTE Ash, 2
	INSTR 11
	LEN 10
	NOTE Ash, 3
	INSTR 12
	LEN 20
	NOTE Gsh, 2
	INSTR 11
	LEN 10
	NOTE Gsh, 3
	INSTR 12
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	LEN 20
	NOTE Ash, 2
	INSTR 11
	LEN 10
	NOTE Ash, 3
	INSTR 12
	LEN 20
	NOTE Gsh, 2
	INSTR 11
	LEN 10
	NOTE Gsh, 3
	INSTR 12
	NOTE F_, 2
	LEN 5
	NOTE Dsh, 2
	NOTE E_, 2
	LEN 20
	NOTE F_, 2
	INSTR 11
	LEN 10
	NOTE F_, 3
	INSTR 12
	LEN 20
	NOTE Gsh, 2
	INSTR 11
	LEN 10
	NOTE Gsh, 3
	INSTR 12
	NOTE Ash, 2
	INSTR 11
	NOTE Ash, 3
	INSTR 12
	LEN 20
	NOTE F_, 2
	INSTR 11
	LEN 10
	NOTE F_, 3
	INSTR 12
	LEN 20
	NOTE Gsh, 2
	INSTR 11
	LEN 10
	NOTE Gsh, 3
	INSTR 12
	NOTE Ash, 2
	LEN 5
	NOTE Dsh, 2
	NOTE E_, 2
	NEXT
Pat_5B77:
	INSTR 12
	LEN 20
	NOTE Ash, 2
	INSTR 11
	LEN 10
	NOTE Ash, 3
	INSTR 12
	LEN 20
	NOTE Gsh, 2
	INSTR 11
	LEN 10
	NOTE Gsh, 3
	INSTR 12
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	LEN 20
	NOTE Ash, 2
	INSTR 11
	LEN 10
	NOTE Ash, 3
	INSTR 12
	LEN 20
	NOTE Gsh, 2
	INSTR 11
	LEN 10
	NOTE Gsh, 3
	INSTR 12
	NOTE F_, 2
	LEN 5
	NOTE Ash, 2
	NOTE B_, 2
	LEN 20
	NOTE C_, 3
	INSTR 11
	LEN 10
	NOTE C_, 4
	INSTR 12
	LEN 20
	NOTE Ash, 2
	INSTR 11
	LEN 10
	NOTE Ash, 3
	INSTR 12
	NOTE G_, 2
	NOTE Ash, 2
	NOTE C_, 2
	NOTE Dsh, 3
	NOTE Dsh, 3
	LEN 20
	NOTE Dsh, 3
	LEN 10
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 2
	NEXT
Pat_5BB0:
	INSTR 9
	LEN 10
	NOTE C_, 4
	INSTR 5
	NOTE F_, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	NOTE Dsh, 4
	INSTR 4
	LEN 20
	NOTE Gsh, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	LEN 10
	NOTE F_, 4
	INSTR 4
	NOTE Ash, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	NOTE Dsh, 4
	INSTR 4
	LEN 20
	NOTE Gsh, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	LEN 10
	NOTE C_, 4
	INSTR 5
	NOTE F_, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	NOTE Dsh, 4
	INSTR 4
	LEN 20
	NOTE Gsh, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	LEN 10
	NOTE F_, 4
	INSTR 4
	NOTE Ash, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	NOTE Dsh, 4
	INSTR 4
	LEN 20
	NOTE Gsh, 4
	INSTR 1
	NOTE F_, 4
	NEXT
Pat_5BE9:
	INSTR 9
	LEN 10
	NOTE C_, 4
	INSTR 5
	NOTE F_, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	NOTE Dsh, 4
	INSTR 4
	LEN 20
	NOTE Gsh, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	LEN 10
	NOTE F_, 4
	INSTR 4
	NOTE Ash, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	NOTE Dsh, 4
	INSTR 4
	LEN 20
	NOTE Gsh, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	LEN 10
	NOTE C_, 4
	INSTR 5
	NOTE F_, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	NOTE Dsh, 4
	INSTR 4
	LEN 20
	NOTE Gsh, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	LEN 10
	NOTE F_, 4
	INSTR 4
	NOTE Ash, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	NOTE Dsh, 4
	INSTR 4
	LEN 20
	NOTE Gsh, 4
	INSTR 1
	LEN 10
	NOTE F_, 4
	INSTR 9
	LEN 5
	NOTE Ash, 3
	NOTE B_, 3
	NEXT
Pat_5C27:
	INSTR 9
	LEN 10
	NOTE Ash, 3
	INSTR 4
	NOTE Ash, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	NOTE Gsh, 3
	INSTR 4
	LEN 20
	NOTE Ash, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	LEN 10
	NOTE Ash, 3
	INSTR 4
	NOTE Ash, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	NOTE Gsh, 3
	INSTR 4
	LEN 20
	NOTE Ash, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	LEN 10
	NOTE C_, 4
	INSTR 5
	NOTE F_, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	NOTE Dsh, 4
	INSTR 4
	LEN 20
	NOTE Gsh, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	LEN 10
	NOTE F_, 4
	INSTR 4
	NOTE Ash, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	NOTE Dsh, 4
	INSTR 4
	LEN 20
	NOTE Gsh, 4
	INSTR 1
	LEN 10
	NOTE F_, 4
	INSTR 9
	LEN 5
	NOTE Ash, 3
	NOTE B_, 3
	NEXT
Pat_5C65:
	INSTR 9
	LEN 10
	NOTE Ash, 3
	INSTR 4
	NOTE Ash, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	NOTE Gsh, 3
	INSTR 4
	LEN 20
	NOTE Ash, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	LEN 10
	NOTE Ash, 3
	INSTR 4
	NOTE Ash, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	NOTE Gsh, 3
	INSTR 4
	LEN 20
	NOTE Ash, 4
	INSTR 1
	NOTE F_, 4
	INSTR 9
	LEN 10
	NOTE C_, 4
	INSTR 4
	NOTE C_, 5
	INSTR 1
	NOTE F_, 4
	INSTR 9
	NOTE Ash, 3
	INSTR 4
	LEN 20
	NOTE C_, 5
	INSTR 1
	NOTE F_, 4
	INSTR 9
	LEN 10
	NOTE C_, 4
	INSTR 4
	NOTE Dsh, 5
	NOTE Dsh, 5
	LEN 20
	NOTE Dsh, 5
	LEN 10
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NEXT
Pat_5C9C:
	DRUMS $0A, DrumPat_5DA3
	VIBRATO $0F, $02, $05
	RELEASE $00
	INSTR 9
	LEN 20
	NOTE Gsh, 3
	INSTR 8
	LEN 10
	NOTE F_, 5
	INSTR 9
	LEN 20
	NOTE C_, 4
	INSTR 8
	NOTE F_, 5
	LEN 10
	NOTE F_, 5
	INSTR 9
	LEN 20
	NOTE D_, 4
	INSTR 8
	LEN 10
	NOTE F_, 5
	INSTR 9
	LEN 20
	NOTE C_, 4
	INSTR 8
	NOTE F_, 5
	LEN 10
	NOTE F_, 5
	INSTR 9
	LEN 20
	NOTE Gsh, 3
	INSTR 8
	LEN 10
	NOTE F_, 5
	INSTR 9
	LEN 20
	NOTE C_, 4
	INSTR 8
	NOTE F_, 5
	LEN 10
	NOTE F_, 5
	INSTR 9
	LEN 20
	NOTE D_, 4
	INSTR 8
	LEN 10
	NOTE F_, 5
	INSTR 9
	LEN 20
	NOTE C_, 4
	DRUMS $0A, DrumPat_5DC6
	INSTR 2
	LEN 10
	NOTE A_, 4
	NOTE G_, 4
	NOTE G_, 4
	NEXT
Pat_5CE0:
	DRUMS $0A, DrumPat_5DA3
	RELEASE $61, $33
	INSTR 9
	LEN 10
	NOTE F_, 3
	NOTE F_, 3
	INSTR 10
	LEN 20
	NOTE F_, 4
	LEN 5
	NOTE B_, 4
	LEN 15
	NOTE C_, 5
	LEN 10
	NOTE F_, 4
	LEN 30
	NOTE Ash, 4
	INSTR 8
	LEN 10
	NOTE F_, 5
	INSTR 10
	LEN 20
	NOTE Gsh, 4
	INSTR 8
	LEN 10
	NOTE F_, 5
	INSTR 10
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 20
	NOTE Gsh, 4
	INSTR 8
	LEN 10
	NOTE F_, 5
	INSTR 10
	LEN 5
	NOTE Dsh, 4
	LEN 15
	NOTE F_, 4
	LEN 10
	NOTE Dsh, 4
	LEN 30
	NOTE C_, 4
	INSTR 8
	LEN 10
	NOTE F_, 5
	INSTR 9
	LEN 20
	NOTE Gsh, 3
	INSTR 8
	LEN 10
	NOTE F_, 5
	INSTR 9
	NOTE Ash, 3
	LEN 5
	NOTE Dsh, 3
	NOTE E_, 3
	NEXT
Pat_5D20:
	INSTR 9
	LEN 10
	NOTE F_, 3
	NOTE F_, 3
	INSTR 10
	LEN 20
	NOTE F_, 4
	LEN 5
	NOTE B_, 4
	LEN 15
	NOTE C_, 5
	LEN 10
	NOTE F_, 4
	LEN 20
	NOTE Ash, 4
	INSTR 8
	LEN 10
	NOTE F_, 5
	INSTR 10
	NOTE C_, 5
	LEN 20
	NOTE Gsh, 4
	INSTR 8
	LEN 10
	NOTE F_, 5
	INSTR 10
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 20
	NOTE Gsh, 4
	INSTR 8
	LEN 10
	NOTE F_, 5
	INSTR 10
	NOTE Ash, 4
	WAIT
	NOTE C_, 5
	LEN 30
	NOTE Gsh, 4
	INSTR 8
	LEN 10
	NOTE F_, 5
	INSTR 10
	LEN 20
	NOTE F_, 4
	INSTR 0
	LEN 10
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NEXT
Pat_5D54:
	LEN 10
	WAIT
	INSTR 0
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE Ash, 3
	INSTR 9
	NOTE F_, 3
	INSTR 0
	LEN 20
	NOTE Ash, 4
	LEN 10
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE F_, 4
	LEN 10
	NOTE Dsh, 4
	LENGTH $3C
	NOTE F_, 4
	LEN 10
	NOTE F_, 3
	NOTE Dsh, 4
	LEN 40
	NOTE C_, 4
	INSTR 9
	LEN 20
	NOTE C_, 4
	INSTR 0
	LEN 10
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NEXT
Pat_5D7A:
	LEN 10
	WAIT
	INSTR 0
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE Ash, 3
	INSTR 9
	NOTE F_, 3
	INSTR 0
	LEN 20
	NOTE Ash, 4
	LEN 10
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE F_, 4
	WAIT
	LEN 10
	NOTE Gsh, 4
	LENGTH $46
	NOTE C_, 5
	INSTR 9
	LEN 10
	NOTE G_, 3
	NOTE Ash, 3
	NOTE C_, 3
	DRUMS $0A, DrumPat_5DC6
	INSTR 0
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE Dsh, 5
	REST
	LEN 30
	NOTE E_, 5
	NEXT
DrumPat_5DA3:
	db 7, 0, 11, 1, 5, 6, 11, 6
	db 1, 6, 11, 1, 6, 1, 11, 6
	db DRUM_REPEAT + 3, 1, 6, 11, 1, 6, 4, 11
	db 6, 1, 6, 11, 1, 6, 1, 11
	db 6, DRUM_REPEAT_END, DRUM_LOOP
DrumPat_5DC6:
	db 9, 9, 9, 0, DRUM_LOOP

; Instrument table 2, entries 1..13 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr2_0
	dw Instr2_1
	dw Instr2_2
	dw Instr2_3
	dw Instr2_3
	dw Instr2_5
	dw Instr2_0
	dw Instr2_7
	dw Instr2_7
	dw Instr2_9
	dw Instr2_10
	dw Instr2_11
	dw Instr2_12
Instr2_0:
	HWENV $D2, $06, $70
	ARP 1
	DUTY_75
	END
Instr2_1:
	HWENV $F1, $05, $01
	GLIDE $FF
	DUTY_12
	END
Instr2_2:
	HWENV $F1, $05, $61
	GLIDE $FE
	END
Instr2_3:
	HWENV $C1, $04, $54
	ARP 4
	AUTODUTY $03
	END
Instr2_5:
	HWENV $C1, $04, $54
	ARP 5
	AUTODUTY $03
	END
Instr2_7:
	HWENV $D1, $02, $32
	END
Instr2_9:
	HWENV $D1, $0A, $81
	DUTY_12
	ARP 0
	END

; Unreferenced (7 bytes)
	db $75, $F1, $06, $52, $73, $A1, $68
Instr2_10:
	HWENV $F1, $05, $70
	END
Instr2_11:
	VOLENV 15, $12, $2F, $11
	ARP 0
	END
Instr2_12:
	VOLENV 15, $11, $1F, $12
	ARP 0
	END

; Song 6: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong6:
	call StopAll
	ld de, Song6_Ch3
	call L49F8
	ld de, Song6_Ch2
	call L49F4
	ld de, Song6_Ch1
	jp L49F0
Song6_Ch3:
	dw Pat_5E80
	dw Pat_5EA8
	dw Pat_5E80
	dw Pat_5ECB
	dw Pat_5EEE
	dw Pat_5EF3
	dw Pat_5EEE
	dw Pat_5F00
	ORDER_LOOP Song6_Ch3
Song6_Ch2:
	dw Pat_5F17
	dw Pat_5F39
	dw Pat_5F17
	dw Pat_5F58
	dw Pat_5F7C
	dw Pat_5FAA
	dw Pat_5F7C
	dw Pat_5FE6
	ORDER_LOOP Song6_Ch2
Song6_Ch1:
	dw Pat_6010
	dw Pat_603E
	dw Pat_6010
	dw Pat_606A
	dw Pat_609E
	dw Pat_60CF
	dw Pat_609E
	dw Pat_610B
	ORDER_LOOP Song6_Ch1
Pat_5E80:
	DRUMS $05, DrumPat_613A
	INSTR 12
	LEN 20
	NOTE D_, 2
	LEN 10
	NOTE F_, 2
	NOTE D_, 2
	NOTE G_, 2
	LEN 20
	NOTE D_, 2
	NOTE D_, 2
	LEN 10
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	LEN 20
	NOTE D_, 2
	LEN 10
	NOTE F_, 2
	NOTE D_, 2
	NOTE G_, 2
	LEN 20
	NOTE D_, 2
	NOTE D_, 2
	LEN 10
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NEXT
Pat_5EA8:
	LEN 20
	NOTE G_, 2
	LEN 10
	NOTE Ash, 2
	NOTE G_, 2
	NOTE C_, 3
	LEN 20
	NOTE G_, 2
	NOTE G_, 2
	LEN 10
	NOTE G_, 2
	NOTE Ash, 2
	NOTE G_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE Ash, 2
	NOTE G_, 2
	LEN 20
	NOTE D_, 2
	LEN 10
	NOTE F_, 2
	NOTE D_, 2
	NOTE G_, 2
	LEN 20
	NOTE D_, 2
	NOTE D_, 2
	LEN 10
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE D_, 2
	NEXT
Pat_5ECB:
	LEN 20
	NOTE G_, 2
	LEN 10
	NOTE Ash, 2
	NOTE G_, 2
	NOTE C_, 3
	LEN 20
	NOTE G_, 2
	NOTE G_, 2
	LEN 10
	NOTE G_, 2
	NOTE Ash, 2
	NOTE G_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE Ash, 2
	NOTE G_, 2
	LEN 20
	NOTE D_, 2
	LEN 10
	NOTE F_, 2
	NOTE D_, 2
	NOTE G_, 2
	LEN 20
	NOTE D_, 2
	NOTE D_, 2
	LEN 10
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NEXT
Pat_5EEE:
	DRUMS $05, DrumPat_616D
	LEN 10
Pat_5EF3:
	REPEAT 8
	NOTE G_, 2
	NOTE G_, 3
	REPEAT_END
	REPEAT 6
	NOTE D_, 2
	NOTE D_, 3
	REPEAT_END
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NEXT
Pat_5F00:
	REPEAT 8
	NOTE G_, 2
	NOTE G_, 3
	REPEAT_END
	NOTE G_, 2
	LEN 20
	NOTE A_, 2
	LEN 10
	NOTE G_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE G_, 2
	LEN 20
	NOTE A_, 2
	NOTE C_, 3
	LEN 10
	NOTE C_, 3
	LEN 20
	NOTE A_, 2
	LEN 10
	NOTE G_, 2
	NOTE F_, 2
	NEXT
Pat_5F17:
	RELEASE $62, $30
	INSTR 9
	LEN 10
	NOTE D_, 2
	LEN 20
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	LEN 10
	NOTE D_, 3
	NOTE D_, 2
	LEN 20
	NOTE D_, 3
	LEN 10
	NOTE D_, 3
	NOTE G_, 3
	LEN 20
	NOTE D_, 3
	NOTE D_, 3
	LEN 10
	NOTE D_, 3
	NOTE F_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE D_, 3
	NOTE F_, 3
	NOTE D_, 3
	NEXT
Pat_5F39:
	INSTR 9
	LEN 10
	NOTE G_, 2
	LEN 20
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 10
	NOTE G_, 3
	NOTE D_, 2
	LEN 20
	NOTE D_, 3
	LEN 10
	NOTE D_, 3
	NOTE G_, 3
	LEN 20
	NOTE D_, 3
	NOTE D_, 3
	LEN 10
	NOTE D_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE D_, 3
	NEXT
Pat_5F58:
	INSTR 9
	LEN 10
	NOTE G_, 2
	LEN 20
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 10
	NOTE G_, 3
	NOTE D_, 2
	LEN 20
	NOTE D_, 3
	INSTR 16
	DUTY_75
	LEN 10
	NOTE D_, 3
	NOTE G_, 3
	LEN 20
	NOTE D_, 3
	NOTE D_, 3
	LEN 10
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	LEN 5
	NOTE D_, 4
	NOTE F_, 4
	LEN 10
	NOTE D_, 4
	NOTE C_, 4
	NEXT
Pat_5F7C:
	LEN 10
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE C_, 4
	LEN 5
	NOTE C_, 4
	LEN 15
	NOTE B_, 3
	LEN 10
	NOTE C_, 4
	LEN 5
	NOTE C_, 4
	LEN 15
	NOTE D_, 4
	LEN 10
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE G_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE D_, 5
	NOTE G_, 3
	LEN 5
	NOTE G_, 3
	NOTE A_, 3
	LEN 10
	NOTE D_, 5
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	LEN 5
	NOTE E_, 4
	NOTE F_, 4
	LEN 10
	NOTE E_, 4
	NOTE C_, 4
	NEXT
Pat_5FAA:
	LEN 10
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE C_, 4
	LEN 5
	NOTE C_, 4
	LEN 15
	NOTE B_, 3
	LEN 10
	NOTE C_, 4
	LEN 5
	NOTE C_, 4
	LEN 15
	NOTE D_, 4
	LEN 10
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	LEN 15
	NOTE A_, 4
	LEN 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE E_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE F_, 3
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	LEN 5
	NOTE G_, 3
	NOTE A_, 3
	LEN 10
	NOTE C_, 4
	LEN 5
	NOTE A_, 3
	NOTE C_, 4
	LEN 10
	NOTE D_, 4
	LEN 5
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NEXT
Pat_5FE6:
	LEN 10
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE C_, 4
	LEN 5
	NOTE C_, 4
	LEN 15
	NOTE B_, 3
	LEN 10
	NOTE C_, 4
	LEN 5
	NOTE C_, 4
	LEN 15
	NOTE D_, 4
	LEN 10
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE D_, 4
	LEN 20
	NOTE E_, 4
	LEN 10
	NOTE D_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 20
	NOTE E_, 4
	LEN 10
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE F_, 3
	NEXT
Pat_6010:
	INSTR 1
	CH_TRANSPOSE $0C
	VIBRATO $1E, $04, $05
	LENGTH $6E
	ARP 3
	NOTE G_, 4
	ARP_OFF
	LEN 10
	NOTE A_, 4
	LEN 5
	NOTE C_, 5
	NOTE D_, 5
	LEN 10
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 20
	ARP 3
	NOTE Dsh, 4
	ARP_OFF
	LEN 5
	NOTE D_, 4
	WAIT2
	INSTR 16
	CH_TRANSPOSE $00
	LEN 10
	NOTE D_, 3
	NOTE G_, 3
	LEN 20
	NOTE D_, 3
	NOTE D_, 3
	LEN 10
	NOTE D_, 3
	NOTE F_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE D_, 3
	NOTE F_, 3
	NOTE D_, 3
	NEXT
Pat_603E:
	INSTR 1
	CH_TRANSPOSE $0C
	LEN 5
	NOTE A_, 4
	LENGTH $55
	NOTE G_, 4
	LEN 10
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	LEN 5
	NOTE E_, 4
	LEN 15
	NOTE F_, 4
	LEN 5
	NOTE E_, 4
	LEN 15
	NOTE F_, 4
	LEN 10
	NOTE D_, 4
	LEN 15
	NOTE D_, 4
	LEN 5
	WAIT2
	INSTR 16
	CH_TRANSPOSE $00
	LEN 10
	NOTE D_, 3
	NOTE G_, 3
	LEN 20
	NOTE D_, 3
	NOTE D_, 3
	LEN 10
	NOTE D_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE D_, 3
	NEXT
Pat_606A:
	INSTR 1
	CH_TRANSPOSE $0C
	LEN 5
	NOTE A_, 4
	LENGTH $55
	NOTE G_, 4
	LEN 10
	NOTE A_, 4
	NOTE C_, 5
	NOTE D_, 5
	LEN 5
	NOTE E_, 5
	LEN 15
	NOTE F_, 5
	LEN 5
	NOTE E_, 5
	LEN 15
	NOTE F_, 5
	LEN 25
	ARP 3
	VIBRATO $12, $04, $01
	NOTE C_, 5
	ARP_OFF
	LEN 5
	WAIT2
	VIB_OFF
	INSTR 16
	CH_TRANSPOSE $00
	LEN 10
	NOTE A_, 3
	NOTE D_, 4
	LEN 20
	NOTE A_, 3
	NOTE A_, 3
	LEN 10
	NOTE D_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 5
	NOTE G_, 4
	NOTE A_, 4
	LEN 10
	NOTE G_, 4
	NOTE F_, 4
	NEXT
Pat_609E:
	LEN 10
	NOTE F_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 5
	NOTE F_, 4
	LEN 15
	NOTE G_, 4
	LEN 10
	NOTE F_, 4
	LEN 5
	NOTE F_, 4
	LEN 15
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 5
	NOTE F_, 4
	NOTE E_, 4
	LEN 10
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE C_, 4
	LEN 5
	NOTE C_, 4
	NOTE D_, 4
	LEN 10
	NOTE A_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 5
	NOTE G_, 4
	NOTE A_, 4
	LEN 10
	NOTE G_, 4
	NOTE F_, 4
	NEXT
Pat_60CF:
	LEN 10
	NOTE F_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 5
	NOTE F_, 4
	LEN 15
	NOTE G_, 4
	LEN 10
	NOTE F_, 4
	LEN 5
	NOTE F_, 4
	LEN 15
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	LEN 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE E_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	LEN 10
	NOTE D_, 4
	LEN 5
	NOTE C_, 4
	NOTE D_, 4
	LEN 10
	NOTE F_, 4
	LEN 5
	NOTE D_, 4
	NOTE F_, 4
	LEN 10
	NOTE G_, 4
	LEN 5
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	NEXT
Pat_610B:
	LEN 10
	NOTE F_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 5
	NOTE F_, 4
	LEN 15
	NOTE G_, 4
	LEN 10
	NOTE F_, 4
	LEN 5
	NOTE F_, 4
	LEN 15
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE D_, 4
	DRUMS $0A, DrumPat_61A0
	NOTE G_, 4
	LEN 20
	NOTE A_, 4
	LEN 10
	NOTE G_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 20
	NOTE A_, 4
	INSTR 9
	LEN 10
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE G_, 2
	NOTE F_, 2
	NEXT
DrumPat_613A:
	db 7, 0, 0, 0, 2, 0, 5, 0
	db 1, 0, 1, 0, 2, 0, 5, 0
	db DRUM_REPEAT + 6, 1, 0, 5, 0, 2, 0, 5
	db 0, 1, 0, 1, 0, 2, 0, 5
	db 0, DRUM_REPEAT_END, 1, 0, 5, 0, 2, 0
	db 5, 0, 1, 0, 1, 0, 2, 0
	db 2, 2, DRUM_LOOP
DrumPat_616D:
	db 7, 0, 0, 6, 2, 0, 5, 6
	db 1, 0, 1, 6, 2, 0, 5, 6
	db DRUM_REPEAT + 6, 1, 0, 5, 6, 2, 0, 5
	db 6, 1, 0, 1, 6, 2, 0, 5
	db 6, DRUM_REPEAT_END, 2, 0, 2, 0, 2, 0
	db 1, 6, 2, 0, 1, 6, 2, 2
	db 2, 2, DRUM_LOOP
DrumPat_61A0:
	db 2, 2, 0, 1, 2, 2, 1, 2
	db 0, 8, 8, 1, 9, 9, 10, 10
	db DRUM_LOOP

; Song 7: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong7:
	call StopAll
	ld de, Song7_Ch3
	call L49F8
	ld de, Song7_Ch2
	call L49F4
	ld de, Song7_Ch1
	jp L49F0
Song7_Ch3:
	dw Pat_61DA
	ORDER_LOOP Song7_Ch3
Song7_Ch2:
	dw Pat_6223
	dw Pat_6271
	ORDER_LOOP Song7_Ch2
Song7_Ch1:
	dw Pat_6275
	ORDER_LOOP Song7_Ch1
Pat_61DA:
	TRANSPOSE $05
	INSTR 12
	LEN 9
	NOTE D_, 2
	NOTE F_, 2
	NOTE Fsh, 2
	DRUMS $09, DrumPat_62B2
	NOTE G_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE Fsh, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 1
	WAIT
	NOTE G_, 1
	NOTE Ash, 1
	NOTE C_, 2
	NOTE Csh, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 1
	WAIT
	NOTE G_, 1
	NOTE Ash, 1
	NOTE C_, 2
	NOTE Csh, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE Ash, 2
	NOTE G_, 2
	NOTE C_, 3
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	NOTE Dsh, 2
	NOTE F_, 2
	NOTE Fsh, 2
	NOTE G_, 2
	NOTE Ash, 2
	NOTE G_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE Ash, 2
	NOTE G_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE Ash, 2
	NOTE C_, 2
	WAIT
	NOTE G_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE Ash, 2
	NEXT
Pat_6223:
	CH_TRANSPOSE $00
	HWENV $F1, $09, $40
	DUTY_75
	VIBRATO $00, $02, $02
	ARP_OFF
Pat_622F:
	LEN 9
	NOTE D_, 2
	NOTE F_, 2
	NOTE Fsh, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE Fsh, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 1
	WAIT
	NOTE G_, 1
	NOTE Ash, 1
	NOTE C_, 2
	NOTE Csh, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 1
	WAIT
	NOTE G_, 1
	NOTE Ash, 1
	NOTE C_, 2
	NOTE Csh, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE Ash, 2
	NOTE G_, 2
	NOTE C_, 3
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	NOTE Dsh, 2
	NOTE F_, 2
	NOTE Fsh, 2
	NOTE G_, 2
	NOTE Ash, 2
	NOTE G_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE Ash, 2
	NOTE G_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE Ash, 2
	NOTE C_, 2
	WAIT
	NOTE G_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE Ash, 2
	NEXT
Pat_6271:
	ARP 1
	PAT_GOTO Pat_622F
Pat_6275:
	ARP 15
	HWENV $81, $04, $44
	DUTY_12
	PINGPONG
	LEN 9
	CH_TRANSPOSE $0C
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	REPEAT 2
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	REPEAT_END
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	WAIT
	NEXT
DrumPat_62B2:
	db 7, 0, 2, 5, 1, 1, 2, 1
	db 5, 1, 2, 5, 1, 1, 2, 4
	db DRUM_REPEAT + 2, 1, 5, 2, 5, 1, 1, 2
	db 1, 5, 1, 2, 5, 1, 1, 2
	db 4, DRUM_REPEAT_END, 1, 5, 2, 5, 1, 1
	db 2, 1, 5, 1, 2, 1, 2, 1
	db 2, 2, DRUM_LOOP

; Song 8: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong8:
	call StopAll
	ld a, $65
	ld [wInstrTableHi], a
	ld a, $6A
	ld [wInstrTable], a
	ld de, Song8_Ch3
	call L49F8
	ld de, Song8_Ch2
	call L49F4
	ld de, Song8_Ch1
	jp L49F0

; Unreferenced (1 bytes)
	db $C9
Song8_Ch3:
	dw Pat_6329
	dw Pat_6373
	dw Pat_6329
	dw Pat_6373
	ORDER_LOOP Song8_Ch3
Song8_Ch2:
	dw Pat_63B4
	dw Pat_63F0
	dw Pat_642E
	dw Pat_6477
	ORDER_LOOP Song8_Ch2
Song8_Ch1:
	dw Pat_64B8
	dw Pat_6504
	dw Pat_64B8
	dw Pat_6504
	ORDER_LOOP Song8_Ch1
Pat_6329:
	DRUMS $08, DrumPat_6563
	WAVE Wave_7598
	INSTR 0
	LEN 8
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
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
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
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE A_, 2
	NOTE A_, 3
	NEXT
Pat_6373:
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
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
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
	NOTE E_, 2
	NOTE E_, 3
	NOTE E_, 2
	NOTE E_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NEXT
Pat_63B4:
	INSTR 1
	VIBRATO $08, $02, $04
	LEN 16
	NOTE D_, 4
	LEN 8
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	LEN 16
	NOTE C_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	NOTE B_, 3
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE B_, 3
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE B_, 3
	LENGTH $50
	NOTE C_, 4
	LEN 16
	NOTE D_, 4
	LEN 8
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	LEN 16
	NOTE C_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 8
	NOTE A_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE B_, 4
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE B_, 4
	NOTE C_, 5
	LENGTH $48
	NOTE C_, 5
	NEXT
Pat_63F0:
	LEN 8
	WAIT
	INSTR 2
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE C_, 5
	LEN 24
	NOTE B_, 4
	LEN 8
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE D_, 5
	NOTE C_, 5
	LEN 16
	NOTE B_, 4
	LEN 24
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE B_, 4
	NOTE A_, 4
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE A_, 4
	INSTR 6
	LEN 8
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE C_, 5
	LEN 24
	NOTE B_, 4
	LEN 8
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE D_, 5
	NOTE C_, 5
	LEN 16
	NOTE B_, 4
	LEN 24
	NOTE Csh, 5
	NOTE D_, 5
	NOTE E_, 5
	LEN 8
	NOTE E_, 5
	LEN 16
	NOTE Fsh, 5
	LEN 8
	NOTE G_, 5
	NOTE A_, 5
	NOTE B_, 5
	NOTE Csh, 6
	NEXT
Pat_642E:
	INSTR 5
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE Fsh, 5
	NOTE D_, 5
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE D_, 5
	LEN 16
	NOTE C_, 5
	NOTE E_, 5
	NOTE D_, 5
	LEN 8
	NOTE Fsh, 5
	NOTE Fsh, 5
	NOTE G_, 5
	LEN 16
	NOTE A_, 5
	LEN 8
	NOTE G_, 5
	LEN 16
	NOTE A_, 5
	LEN 8
	NOTE G_, 5
	NOTE D_, 5
	LEN 16
	NOTE E_, 5
	INSTR 4
	LEN 8
	NOTE A_, 2
	NOTE C_, 3
	NOTE E_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	INSTR 5
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE Fsh, 5
	NOTE D_, 5
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE D_, 5
	LEN 16
	NOTE C_, 5
	NOTE E_, 5
	NOTE D_, 5
	LEN 8
	NOTE D_, 6
	NOTE D_, 6
	NOTE Csh, 6
	NOTE C_, 6
	NOTE C_, 6
	NOTE B_, 5
	LEN 16
	NOTE C_, 6
	LEN 8
	NOTE B_, 5
	LEN 16
	NOTE G_, 5
	LEN 8
	NOTE C_, 4
	NOTE A_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE C_, 3
	NEXT
Pat_6477:
	INSTR 7
	LEN 8
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 16
	NOTE B_, 4
	LEN 8
	NOTE A_, 4
	LEN 24
	NOTE G_, 4
	LEN 8
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE A_, 4
	LEN 16
	NOTE G_, 4
	LEN 24
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	LEN 16
	NOTE A_, 4
	NOTE Fsh, 4
	LEN 8
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 16
	NOTE B_, 4
	LEN 8
	NOTE A_, 4
	LEN 24
	NOTE G_, 4
	LEN 8
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE A_, 4
	LEN 16
	NOTE G_, 4
	NOTE A_, 4
	LEN 8
	NOTE A_, 4
	LEN 16
	NOTE B_, 4
	LEN 8
	NOTE B_, 4
	LEN 16
	NOTE Csh, 5
	LEN 8
	NOTE Csh, 5
	NOTE Csh, 5
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE E_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE A_, 5
	NEXT
Pat_64B8:
	VIBRATO $08, $01, $04
	INSTR 6
	LEN 16
	NOTE D_, 4
	LEN 8
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	LEN 16
	NOTE C_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	NOTE B_, 3
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE B_, 3
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE B_, 3
	LEN 24
	NOTE C_, 4
	INSTR 4
	LEN 8
	NOTE A_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	INSTR 6
	LEN 16
	NOTE D_, 4
	LEN 8
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	LEN 16
	NOTE C_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 8
	NOTE A_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE B_, 4
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE B_, 4
	NOTE C_, 5
	NOTE C_, 5
	INSTR 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	NEXT
Pat_6504:
	INSTR 5
	LEN 8
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE C_, 5
	LEN 16
	NOTE B_, 4
	INSTR 3
	LEN 8
	NOTE C_, 4
	INSTR 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE D_, 5
	NOTE C_, 5
	LEN 16
	NOTE B_, 4
	NOTE A_, 4
	INSTR 6
	LEN 8
	NOTE A_, 4
	INSTR 5
	LEN 16
	NOTE Fsh, 4
	INSTR 6
	LEN 8
	NOTE Fsh, 4
	INSTR 5
	LEN 16
	NOTE B_, 4
	INSTR 6
	LEN 8
	NOTE B_, 4
	INSTR 5
	LEN 16
	NOTE A_, 4
	INSTR 6
	LEN 8
	NOTE A_, 4
	INSTR 5
	LEN 16
	NOTE D_, 5
	NOTE A_, 4
	LEN 8
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	LEN 16
	NOTE D_, 4
	LEN 8
	NOTE C_, 4
	LEN 16
	NOTE B_, 3
	INSTR 3
	LEN 8
	NOTE C_, 4
	INSTR 5
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE D_, 4
	NOTE C_, 4
	LEN 16
	NOTE B_, 3
	NOTE Csh, 4
	INSTR 6
	LEN 8
	NOTE Csh, 4
	INSTR 5
	LEN 16
	NOTE D_, 4
	INSTR 6
	LEN 8
	NOTE D_, 4
	INSTR 5
	LEN 16
	NOTE E_, 4
	INSTR 6
	LEN 8
	NOTE E_, 4
	INSTR 5
	NOTE E_, 4
	LEN 16
	NOTE Fsh, 4
	LEN 8
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE Csh, 5
	NEXT
DrumPat_6563:
	db 1, 6, 2, 6, 1, 1, 2, 6
	db DRUM_LOOP

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
	VOLENV 15, $11, $1F, $11
	WAVE Wave_7598
	END
Instr3_1:
	HWENV $90, $07, $27
	END
Instr3_2:
	HWENV $50, $00
	END
Instr3_3:
	HWENV $F2, $00
	GLIDE $FE
	END
Instr3_4:
	HWENV $C1, $07, $52
	ARP 11
	DUTY_12
	RELEASE $00
	END
Instr3_5:
	HWENV $B2, $08, $40
	END
Instr3_6:
	HWENV $84, $08, $47
	ARP 1
	DUTY_75
	END
Instr3_7:
	HWENV $B2, $08, $40
	DUTY_75
	ARP 11
	END

; Song 9: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong9:
	call StopAll
	ld de, Song9_Ch3
	call L49F8
	ld de, Song9_Ch2
	call L49F4
	ld de, Song9_Ch1
	jp L49F0
Pat_65C4:
	TRANSPOSE $01
	NEXT
Pat_65C7:
	TRANSPOSE $00
	NEXT
Song9_Ch3:
	dw Pat_65C7
	dw Pat_662A
	dw Pat_664D
	dw Pat_6670
	dw Pat_6699
	dw Pat_6670
	dw Pat_66C2
	dw Pat_66EB
	dw Pat_670E
	dw Pat_6731
	dw Pat_6754
	dw Pat_65C4
	dw Pat_662A
	dw Pat_664D
	dw Pat_6670
	dw Pat_6699
	dw Pat_6670
	dw Pat_66C2
	dw Pat_66EB
	dw Pat_670E
	dw Pat_6731
	dw Pat_6754
	ORDER_LOOP Song9_Ch3
Song9_Ch2:
	dw Pat_6777
	dw Pat_679C
	dw Pat_67C2
	dw Pat_67E5
	dw Pat_67C2
	dw Pat_6808
	dw Pat_682B
	dw Pat_6850
	dw Pat_6876
	dw Pat_689B
	ORDER_LOOP Song9_Ch2
Song9_Ch1:
	dw Pat_68C1
	dw Pat_68EB
	dw Pat_6917
	dw Pat_6948
	dw Pat_6917
	dw Pat_696F
	dw Pat_69A6
	dw Pat_69CA
	dw Pat_69EF
	dw Pat_6A13
	ORDER_LOOP Song9_Ch1
Pat_662A:
	INSTR 12
	LEN 10
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NEXT
Pat_664D:
	INSTR 12
	LEN 10
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE Fsh, 2
	NEXT
Pat_6670:
	INSTR 12
	LEN 10
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE F_, 3
	NOTE G_, 2
	NOTE G_, 3
	INSTR 7
	LEN 20
	NOTE G_, 2
	INSTR 12
	LEN 10
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE F_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE C_, 3
	NOTE D_, 2
	NOTE D_, 3
	INSTR 7
	LEN 20
	NOTE D_, 2
	INSTR 12
	LEN 10
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE C_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NEXT
Pat_6699:
	INSTR 12
	LEN 10
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE Ash, 3
	NOTE C_, 3
	NOTE C_, 4
	INSTR 7
	LEN 20
	NOTE C_, 3
	INSTR 12
	LEN 10
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE Ash, 3
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE F_, 3
	NOTE G_, 2
	NOTE G_, 3
	INSTR 7
	LEN 20
	NOTE G_, 2
	INSTR 12
	LEN 10
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE F_, 3
	NOTE D_, 3
	NOTE C_, 3
	NOTE Ash, 2
	NEXT
Pat_66C2:
	INSTR 12
	LEN 10
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE Ash, 3
	NOTE C_, 3
	NOTE C_, 4
	INSTR 7
	LEN 20
	NOTE C_, 3
	INSTR 12
	LEN 10
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE Ash, 3
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE F_, 3
	NOTE G_, 2
	NOTE G_, 3
	INSTR 7
	LEN 20
	NOTE G_, 2
	INSTR 12
	LEN 10
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE F_, 3
	NOTE D_, 2
	NOTE F_, 2
	NOTE Fsh, 2
	NEXT
Pat_66EB:
	INSTR 12
	LEN 10
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NEXT
Pat_670E:
	INSTR 12
	LEN 10
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE Fsh, 2
	NEXT
Pat_6731:
	INSTR 12
	LEN 10
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NEXT
Pat_6754:
	INSTR 12
	LEN 10
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN 20
	NOTE D_, 3
	LEN 10
	NOTE G_, 2
	NOTE G_, 2
	LEN 20
	NOTE Csh, 3
	LEN 10
	NOTE G_, 2
	NOTE C_, 3
	NOTE Ash, 2
	LEN 40
	NOTE G_, 2
	NEXT
Pat_6777:
	INSTR 2
	LEN 10
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE F_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE D_, 3
	LEN 20
	NOTE F_, 3
	LEN 10
	NOTE C_, 3
	NOTE Csh, 3
	NOTE D_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 3
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE C_, 4
	NEXT
Pat_679C:
	INSTR 2
	LEN 10
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	LEN 20
	NOTE Ash, 3
	LEN 10
	NOTE F_, 3
	NOTE Fsh, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE D_, 3
	NOTE D_, 3
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE D_, 3
	NOTE F_, 3
	NOTE Fsh, 3
	NEXT
Pat_67C2:
	INSTR 2
	LEN 10
	NOTE G_, 3
	NOTE G_, 4
	NOTE D_, 3
	NOTE F_, 3
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 3
	NOTE F_, 3
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE D_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE D_, 4
	NOTE D_, 5
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 5
	NOTE D_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 5
	NOTE D_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	NEXT
Pat_67E5:
	INSTR 2
	LEN 10
	NOTE C_, 4
	NOTE C_, 5
	NOTE G_, 3
	NOTE Ash, 3
	NOTE C_, 5
	NOTE C_, 4
	NOTE G_, 3
	NOTE Ash, 3
	NOTE C_, 5
	NOTE C_, 4
	NOTE G_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE D_, 3
	NOTE F_, 3
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 3
	NOTE F_, 3
	NOTE G_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE G_, 3
	NOTE F_, 4
	NOTE D_, 3
	NOTE C_, 3
	NOTE Ash, 2
	NEXT
Pat_6808:
	INSTR 2
	LEN 10
	NOTE C_, 4
	NOTE C_, 5
	NOTE G_, 3
	NOTE Ash, 3
	NOTE C_, 5
	NOTE C_, 4
	NOTE G_, 3
	NOTE Ash, 3
	NOTE C_, 5
	NOTE C_, 4
	NOTE G_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE D_, 3
	NOTE F_, 3
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 3
	NOTE F_, 3
	NOTE G_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE G_, 3
	NOTE F_, 4
	NOTE D_, 3
	NOTE F_, 3
	NOTE Fsh, 3
	NEXT
Pat_682B:
	INSTR 2
	LEN 10
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	LEN 20
	NOTE F_, 4
	LEN 10
	NOTE C_, 4
	NOTE Csh, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE A_, 4
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE C_, 5
	NEXT
Pat_6850:
	INSTR 2
	LEN 10
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	LEN 20
	NOTE Ash, 4
	LEN 10
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN 20
	NOTE A_, 4
	LEN 10
	NOTE D_, 4
	NOTE D_, 4
	LEN 20
	NOTE Gsh, 4
	LEN 10
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 3
	NOTE F_, 3
	NOTE Fsh, 3
	NEXT
Pat_6876:
	INSTR 2
	LEN 10
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	LEN 20
	NOTE F_, 4
	LEN 10
	NOTE F_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE A_, 4
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE C_, 5
	NEXT
Pat_689B:
	INSTR 2
	LEN 10
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	LEN 20
	NOTE Ash, 4
	LEN 10
	NOTE Ash, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN 20
	NOTE A_, 4
	LEN 10
	NOTE D_, 4
	NOTE D_, 4
	LEN 20
	NOTE Gsh, 4
	LEN 10
	NOTE D_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 15
	NOTE D_, 4
	LEN 25
	WAIT2
	NEXT
Pat_68C1:
	DRUMS $0A, DrumPat_6A85
	INSTR 2
	LEN 10
	NOTE G_, 3
	GLISS_3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	LEN 20
	NOTE Ash, 3
	LEN 10
	NOTE F_, 3
	NOTE Fsh, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	LEN 20
	NOTE F_, 4
	LEN 10
	NOTE C_, 4
	NOTE Csh, 4
	NOTE D_, 4
	NOTE F_, 4
	NEXT
Pat_68EB:
	INSTR 2
	LEN 10
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE C_, 4
	LEN 20
	NOTE Dsh, 4
	LEN 10
	NOTE Ash, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 20
	NOTE D_, 4
	LEN 10
	NOTE G_, 3
	NOTE G_, 3
	LEN 20
	NOTE Csh, 4
	LEN 10
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE C_, 4
	DRUMS $0A, DrumPat_6A5C
	INSTR 13
	DUTY_50
	NOTE D_, 4
	NOTE F_, 4
	NOTE Fsh, 4
	NEXT
Pat_6917:
	DRUMS $0A, DrumPat_6A4E
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	NOTE F_, 4
	LEN 5
	NOTE Ash, 4
	NOTE A_, 4
	LEN 10
	NOTE G_, 4
	NOTE D_, 4
	LEN 20
	NOTE F_, 4
	LEN 10
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE Ash, 4
	NOTE C_, 5
	LEN 5
	NOTE C_, 5
	NOTE Csh, 5
	LEN 10
	NOTE D_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE A_, 4
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE A_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE D_, 4
	LEN 5
	NOTE C_, 5
	NOTE Csh, 5
	LEN 10
	NOTE D_, 5
	NEXT
Pat_6948:
	LEN 10
	NOTE C_, 5
	NOTE Ash, 4
	NOTE G_, 4
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE D_, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE D_, 4
	LEN 5
	NOTE F_, 4
	NOTE Fsh, 4
	LEN 10
	NOTE G_, 4
	NOTE G_, 4
	LEN 20
	NOTE F_, 4
	LEN 10
	NOTE D_, 4
	NOTE F_, 4
	LENGTH $32
	NOTE G_, 4
	LEN 10
	WAIT2
	GLISS_OFF
	NOTE D_, 4
	NOTE C_, 4
	NOTE Ash, 3
	NEXT
Pat_696F:
	LEN 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE D_, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE G_, 4
	NOTE F_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE G_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE C_, 4
	LEN 10
	NOTE D_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE D_, 5
	LEN 5
	NOTE F_, 5
	NOTE Fsh, 5
	LENGTH $32
	NOTE G_, 5
	GLISS_OFF
	LEN 10
	WAIT2
	DUTY_75
	NOTE D_, 4
	GLISS_3
	NOTE F_, 4
	NOTE Fsh, 4
	NEXT
Pat_69A6:
	LEN 10
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	LEN 20
	NOTE Ash, 4
	LEN 10
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE D_, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE G_, 5
	NOTE D_, 5
	LEN 20
	NOTE F_, 5
	LEN 10
	NOTE C_, 5
	NOTE Csh, 5
	NOTE D_, 5
	NOTE F_, 5
	NEXT
Pat_69CA:
	LEN 10
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	LEN 20
	NOTE Dsh, 5
	LEN 10
	NOTE Ash, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 20
	NOTE D_, 5
	LEN 10
	NOTE G_, 4
	NOTE G_, 4
	LEN 20
	NOTE Csh, 5
	LEN 10
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE F_, 5
	NOTE Fsh, 5
	NEXT
Pat_69EF:
	LEN 10
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE Ash, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE G_, 5
	LEN 20
	NOTE Ash, 5
	LEN 10
	NOTE Ash, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE G_, 5
	NOTE D_, 5
	LEN 20
	NOTE F_, 5
	LEN 10
	NOTE C_, 5
	NOTE Csh, 5
	NOTE D_, 5
	NOTE F_, 5
	NEXT
Pat_6A13:
	LEN 10
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	LEN 20
	NOTE Dsh, 5
	LEN 10
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE F_, 4
	DRUMS $0A, DrumPat_6A3B
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 20
	NOTE D_, 5
	LEN 10
	NOTE G_, 4
	NOTE G_, 4
	LEN 20
	NOTE Csh, 5
	LEN 10
	NOTE G_, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE G_, 4
	LEN 30
	WAIT2
	NEXT
DrumPat_6A3B:
	db 1, 1, 1, 7, 0, 1, 1, 7
	db 0, 1, 2, 2, 7, 1, DRUM_TEMPO + 5, 2
	db 2, DRUM_TEMPO + 10, 2
DrumPat_6A4E:
	db DRUM_TEMPO + 10, 7, 0, 2, 5, 1, 1, 2
	db 1, 5, 1, 2, 1, 1
DrumPat_6A5C:
	db 1, 2, 2, DRUM_REPEAT + 2, 1, 1, 2, 5
	db 1, 1, 2, 1, 5, 1, 2, 1
	db 1, 1, 2, 2, DRUM_REPEAT_END, 1, 1, 2
	db 5, 1, 1, 2, 1, 5, 1, 2
	db 1, 2, 1, DRUM_TEMPO + 5, 2, 2, DRUM_TEMPO + 10, 2
	db DRUM_LOOP
DrumPat_6A85:
	db DRUM_REPEAT + 7, 14, 1, DRUM_REPEAT_END, 14, DRUM_TEMPO + 5, 1, 1
	db DRUM_TEMPO + 10, DRUM_LOOP

; Instrument table 4, entries 1..17 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr4_0
	dw Instr4_1
	dw Instr4_2
	dw Instr4_3
	dw Instr4_3
	dw Instr4_5
	dw Instr4_6
	dw Instr4_7
	dw Instr4_8
	dw Instr4_8
	dw Instr4_10
	dw Instr4_11
	dw Instr4_12
	dw Instr4_13
	dw Instr4_14
	dw Instr4_15
	dw Instr4_16

; Unreferenced (2 bytes)
	db $2B, $6B
Instr4_0:
	VOLENV 15, $11, $1F, $12
	WAVE Wave_75B8
	END
Instr4_1:
	HWENV $D0, $01, $90
	RELEASE $65, $37
	END
Instr4_2:
	DUTY_12
	HWENV $C0, $00
	RELEASE $08, $C1
	ARP 11
	VIBRATO $0A, $04, $04
	END
Instr4_3:
	HWENV $C1, $00
	ARP 14
	END
Instr4_5:
	HWENV $C1, $00
	ARP 15
	END
Instr4_7:
	VOLENV 15, $00, $1F, $14
	END
Instr4_6:
	HWENV $C2, $07, $64
	RELEASE $00
	END
Instr4_8:
	HWENV $C1, $07, $52
	ARP 11
	DUTY_12
	RELEASE $00
	END
Instr4_10:
	HWENV $B2, $06, $60
	DUTY_75
	RELEASE $01, $20
	END
Instr4_11:
	VOLENV 15, $12, $2F, $11
	ARP 0
	WAVE Wave_7588
	END
Instr4_12:
	VOLENV 15, $00, $1F, $12
	ARP 0
	WAVE Wave_7598
	END
Instr4_13:
	HWENV $C1, $04, $70
	DUTY_75
	RELEASE $01, $20
	END
Instr4_14:
	VOLENV 12, $11, $1A, $11
	ARP 4
	WAVE Wave_7588
	END
Instr4_15:
	VOLENV 12, $11, $1A, $11
	ARP 5
	WAVE Wave_7588
	END
Instr4_16:
	HWENV $C0, $06, $40
	DUTY_50
	END

; Unreferenced (7 bytes)
	db $75, $F1, $08, $40, $A2, $71, $68
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

; Unreferenced (14 bytes)
	db $A4, $6B, $A4, $6B, $A4, $6B, $A4, $6B, $A4, $6B, $A7, $6B, $A7, $6B
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

; PlaySong table: A = 0-8
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
Wave_6BB9:
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

; Sound effect 3
Sfx03:
	WAVE Wave_6BB9
	PAN_R
	VOLENV 15, $00, $00, $00
	GLIDE $FD
	LEN 4
	NOTE G_, 5
	END

; Sound effect 4
Sfx04:
	WAVE Wave_6BB9
	VOLENV 15, $00, $00, $00
	GLIDE $FD
	LEN 4
	NOTE Dsh, 5
	END

; Sound effect 5
Sfx05:
	WAVE Wave_6BB9
	PAN_L
	VOLENV 15, $00, $00, $00
	GLIDE $FD
	LEN 4
	NOTE B_, 4
	END

; Sound effect 1
Sfx01:
	WAVE Wave_6BB9
	VOLENV 15, $00, $00, $00
	LEN 1
	NOTE D_, 4
	NOTE Gsh, 3
	NOTE E_, 3
	END

; Sound effect 2
Sfx02:
	WAVE Wave_6BB9
	VOLENV 15, $00, $00, $00
	LEN 1
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 4
	END

; Sound effect 6
Sfx06:
	CALL_CODE Code_7346
	WAVE Wave_7538
	VOLENV 15, $11, $1F, $12
	LEN 4
	GLIDE $FE
	NOTE A_, 2
	NOTE C_, 3
	NOTE Csh, 3
	NOTE D_, 3
	NOTE Dsh, 3
	VOL $0A
	NOTE E_, 3
	NOTE F_, 3
	NOTE Fsh, 3
	VOL $05
	LEN 5
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	END

; Sound effect 7
Sfx07:
	VOLENV 15, $11, $1F, $12
	LEN 6
	WAVE Wave_7538
	GLIDE $FC
	NOTE D_, 4
	WAVE Wave_75C8
	LEN 13
	GLIDE $01
	VIBRATO $00, $50, $03
	NOTE Csh, 4
	END

; Sound effect 8
Sfx08:
	VOLENV 15, $00, $00, $00
	LEN 4
	CH_TRANSPOSE $18
	WAVE Wave_7608
	GLIDE $02
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	VOL $0A
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	VOL $05
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	END

; Sound effect 9
Sfx09:
	WAVE Wave_7558
	VOLENV 15, $11, $11, $11
	VIBRATO $00, $02, $02
	LEN 5
	NOTE A_, 4
	REST
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	END

; Sound effect 12
Sfx12:
	WAVE Wave_7548
	LEN 10
	VOLENV 5, $1F, $1F, $33
	GLIDE $01
	NOTE B_, 4
	GLIDE $FF
	NOTE A_, 5
	GLIDE $01
	WAIT
	GLIDE $FF
	WAIT
	GLIDE $01
	WAIT
	GLIDE $FF
	WAIT
	GLIDE $01
	WAIT
	GLIDE $FF
	WAIT
	GLIDE $01
	WAIT
	END

; Sound effect 15
Sfx15:
	VOLENV 15, $11, $2F, $11
	WAVE Wave_75A8
	LEN 8
	NOTE C_, 6
	VOL $0A
	PAN_R
	NOTE C_, 6
	VOL $05
	PAN_L
	NOTE C_, 6
	END

; Sound effect 16
Sfx16:
	LEN 4
	VOLENV 15, $11, $2F, $11
	WAVE Wave_75A8
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

; Sound effect 13
Sfx13:
	LEN 5
	ARP 0
	WAVE Wave_7638
	VOLENV 15, $10, $00, $10
	RELEASE $02, $51
	NOTE C_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	VOL $0A
	RELEASE $02, $11
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	END

; Sound effect 14
Sfx14:
	VOLENV 5, $4F, $1F, $11
	LEN 3
	CH_TRANSPOSE $0C
	WAVE Wave_7598
	GLIDE $FF
	NOTE A_, 4
	LEN 1
	REST
	LEN 3
	NOTE A_, 4
	LEN 1
	REST
	LEN 3
	NOTE A_, 4
	LEN 1
	REST
	LEN 4
	NOTE A_, 4
	LEN 2
	REST
	LEN 2
	NOTE Gsh, 4
	LEN 3
	REST
	LEN 1
	NOTE Gsh, 4
	END

; Sound effect 11
Sfx11:
	VOLENV 15, $00, $1F, $14
	LEN 5
	ARP 0
	WAVE Wave_7608
	NOTE A_, 6
	NOTE Fsh, 6
	WAIT
	WAIT
	VOLENV 10, $00, $1F, $14
	NOTE A_, 6
	NOTE Fsh, 6
	WAIT
	WAIT
	END

; Sound effect 10
Sfx10:
	VOLENV 15, $00, $00, $00
	LEN 6
	WAVE Wave_7538
	CALL_CODE Code_730B
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

; Sound effect 17
Sfx17:
	CALL_CODE Code_6F56
	END

; Sound effect 18
Sfx18:
	CALL_CODE Code_6F95
	END

; Unreferenced (506 bytes)
	db $C7, $00, $00, $00, $7A, $38, $75, $60, $03, $CC, $21, $80, $DF, $6F, $68, $7A
	db $88, $75, $C7, $11, $1F, $13, $80, $C5, $74, $DB, $45, $68, $7A, $E8, $75, $C7
	db $11, $1F, $11, $60, $02, $CE, $24, $26, $28, $2A, $2C, $68, $7A, $38, $75, $80
	db $1A, $70, $C2, $00, $00, $00, $CF, $60, $FC, $51, $D1, $60, $FF, $65, $65, $68
	db $7A, $18, $75, $BD, $1F, $00, $20, $80, $A1, $70, $DC, $20, $68, $80, $8C, $74
	db $68, $7A, $58, $76, $C7, $00, $00, $00, $60, $04, $CC, $39, $60, $FE, $65, $65
	db $60, $FF, $65, $68, $7A, $08, $76, $C7, $00, $00, $00, $CC, $B5, $39, $66, $66
	db $37, $36, $66, $34, $66, $32, $68, $7A, $08, $76, $C7, $00, $00, $00, $CD, $B5
	db $7C, $02, $11, $32, $36, $39, $3E, $66, $3C, $3E, $65, $65, $68, $7A, $38, $75
	db $C2, $11, $1F, $14, $80, $E8, $70, $C9, $45, $66, $F7, $51, $68, $7A, $E8, $75
	db $C7, $00, $00, $00, $D5, $60, $01, $63, $00, $64, $02, $80, $23, $71, $15, $61
	db $6B, $F1, $65, $68, $80, $4D, $71, $68, $7A, $38, $75, $80, $A1, $71, $C7, $00
	db $00, $00, $C9, $60, $FD, $26, $66, $21, $68, $80, $DA, $71, $7A, $E8, $75, $C7
	db $00, $00, $00, $60, $FD, $CF, $39, $68, $80, $15, $72, $7A, $D8, $75, $C2, $11
	db $1F, $13, $DB, $84, $01, $51, $68, $80, $46, $73, $68, $80, $35, $74, $C2, $11
	db $1F, $11, $7A, $38, $75, $D1, $A6, $60, $01, $51, $51, $68, $C4, $11, $1F, $14
	db $7A, $68, $75, $60, $04, $CB, $21, $60, $FD, $CB, $65, $66, $60, $04, $CB, $1F
	db $60, $FD, $CB, $65, $66, $60, $04, $CB, $1E, $60, $FD, $CD, $65, $66, $68, $C7
	db $11, $1F, $16, $CD, $7A, $68, $76, $60, $03, $35, $C8, $60, $01, $65, $61, $D1
	db $63, $01, $04, $01, $48, $CB, $60, $02, $65, $60, $FE, $65, $68, $C7, $13, $FF
	db $11, $CC, $60, $FF, $7A, $38, $76, $24, $27, $20, $1E, $15, $68, $80, $91, $72
	db $68, $C7, $00, $00, $00, $D1, $7A, $E8, $75, $80, $CC, $72, $60, $FD, $2D, $68
	db $C7, $00, $00, $00, $CD, $7A, $38, $75, $80, $0B, $73, $60, $FC, $76, $04, $26
	db $26, $26, $C2, $00, $00, $00, $26, $26, $26, $68, $7A, $88, $75, $80, $82, $73
	db $60, $04, $D1, $C7, $00, $00, $00, $21, $C2, $00, $00, $00, $6F, $21, $BD, $00
	db $00, $00, $70, $21, $68, $C7, $00, $00, $00, $7A, $D8, $75, $80, $C7, $73, $60
	db $03, $D1, $21, $68, $C7, $00, $00, $00, $7A, $38, $75, $80, $FA, $73, $C8, $2D
	db $66, $33, $CF, $66, $C8, $21, $68, $C7, $11, $1F, $12, $CD, $7A, $38, $75, $60
	db $FC, $26, $7A, $C8, $75, $D4, $60, $01, $63, $00, $50, $03, $21, $68, $C7, $00
	db $00, $00, $CB, $7B, $18, $7A, $08, $76, $60, $02, $24, $26, $28, $29, $2B, $2D
	db $2F, $82, $0A, $6F, $2D, $2F, $82, $05, $70, $2D, $2F, $68, $80, $50, $72, $C7
	db $11, $FF, $11, $7A, $38, $75, $CB, $37, $3B, $68
Code_6F56:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0A
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $00
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_6F86)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6F86)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6F8E)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6F8E)
	ld [wNoise42], a
	ret
Noise43_6F86:
	db $48, $59, $69, $79, $89, $99, $8C, $FF
Noise42_6F8E:
	db $F0, $FF, $FF, $FF, $F0, $70, $A1
Code_6F95:
	ld a, $88
	ld [wNoisePan], a
	ld a, $28
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $00
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_6FC5)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6FC5)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6FD2)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6FD2)
	ld [wNoise42], a
	ret
Noise43_6FC5:
	db $68, $59, $59, $79, $69, $89, $6C, $61
	db $61, $61, $61, $60, $FF
Noise42_6FD2:
	db $F2, $FF, $FF, $FF, $F0, $70, $F2, $FF
	db $FF, $FF, $FF, $FF

; Unreferenced (813 bytes)
	db $FF, $3E, $88, $EA, $44, $D0, $3E, $04, $EA, $45, $D0, $3E, $00, $EA, $5D, $D0
	db $AF, $EA, $5C, $D0, $AF, $EA, $59, $D0, $3C, $EA, $5A, $D0, $3E, $70, $EA, $55
	db $D0, $3E, $0F, $EA, $56, $D0, $3E, $70, $EA, $57, $D0, $3E, $15, $EA, $58, $D0
	db $C9, $00, $53, $71, $91, $31, $FF, $F1, $FF, $FF, $FF, $00, $3E, $88, $EA, $44
	db $D0, $3E, $18, $EA, $45, $D0, $AF, $EA, $59, $D0, $3C, $EA, $5A, $D0, $3E, $01
	db $EA, $5D, $D0, $AF, $EA, $5C, $D0, $3E, $70, $EA, $55, $D0, $3E, $7A, $EA, $56
	db $D0, $3E, $70, $EA, $57, $D0, $3E, $94, $EA, $58, $D0, $C9, $3E, $88, $EA, $44
	db $D0, $3E, $0F, $EA, $45, $D0, $AF, $EA, $59, $D0, $3C, $EA, $5A, $D0, $3E, $00
	db $EA, $5D, $D0, $AF, $EA, $5C, $D0, $3E, $70, $EA, $55, $D0, $3E, $87, $EA, $56
	db $D0, $3E, $70, $EA, $57, $D0, $3E, $94, $EA, $58, $D0, $C9, $10, $10, $20, $31
	db $32, $33, $33, $34, $34, $35, $35, $36, $FF, $36, $35, $35, $34, $34, $33, $33
	db $32, $31, $20, $10, $10, $FF, $5C, $FF, $FF, $FF, $FF, $FF, $A1, $FF, $FF, $FF
	db $FF, $FF, $FF, $AF, $EA, $59, $D0, $3C, $EA, $5A, $D0, $3E, $00, $EA, $5D, $D0
	db $AF, $EA, $5C, $D0, $3E, $88, $EA, $44, $D0, $3E, $13, $EA, $45, $D0, $3E, $F2
	db $E0, $21, $3E, $80, $E0, $23, $3E, $70, $EA, $55, $D0, $3E, $D9, $EA, $56, $D0
	db $3E, $00, $EA, $57, $D0, $3E, $00, $EA, $58, $D0, $C9, $18, $3A, $47, $49, $2E
	db $2D, $1C, $28, $4A, $57, $39, $4E, $1D, $0C, $FF, $3E, $88, $EA, $44, $D0, $3E
	db $32, $EA, $45, $D0, $3E, $00, $EA, $5D, $D0, $AF, $EA, $5C, $D0, $AF, $EA, $59
	db $D0, $3C, $EA, $5A, $D0, $3E, $71, $EA, $55, $D0, $3E, $18, $EA, $56, $D0, $3E
	db $71, $EA, $57, $D0, $3E, $1E, $EA, $58, $D0, $C9, $30, $20, $D0, $D0, $11, $FF
	db $F1, $F1, $F1, $F1, $86, $3E, $88, $EA, $44, $D0, $3E, $DD, $EA, $45, $D0, $AF
	db $EA, $59, $D0, $3C, $EA, $5A, $D0, $3E, $71, $EA, $55, $D0, $3E, $4A, $EA, $56
	db $D0, $3E, $71, $EA, $57, $D0, $3E, $4C, $EA, $58, $D0, $C9, $11, $FF, $30, $AF
	db $EA, $59, $D0, $3C, $EA, $5A, $D0, $3E, $88, $EA, $44, $D0, $3E, $14, $EA, $45
	db $D0, $3E, $71, $EA, $55, $D0, $3E, $74, $EA, $56, $D0, $3E, $71, $EA, $57, $D0
	db $3E, $8B, $EA, $58, $D0, $C9, $90, $90, $90, $90, $90, $90, $90, $90, $90, $90
	db $90, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $FF, $F0, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $F0, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $00, $AF, $EA, $59, $D0, $3C, $EA, $5A, $D0, $3E, $88, $EA, $44, $D0
	db $3E, $14, $EA, $45, $D0, $3E, $02, $EA, $5D, $D0, $AF, $EA, $5C, $D0, $3E, $71
	db $EA, $55, $D0, $3E, $D1, $EA, $56, $D0, $3E, $71, $EA, $57, $D0, $3E, $D6, $EA
	db $58, $D0, $C9, $71, $00, $00, $61, $FF, $F1, $11, $11, $F1, $3E, $88, $EA, $44
	db $D0, $3E, $14, $EA, $45, $D0, $AF, $EA, $59, $D0, $3C, $EA, $5A, $D0, $3E, $00
	db $EA, $5D, $D0, $AF, $EA, $5C, $D0, $3E, $72, $EA, $55, $D0, $3E, $0A, $EA, $56
	db $D0, $3E, $72, $EA, $57, $D0, $3E, $10, $EA, $58, $D0, $C9, $50, $11, $16, $24
	db $34, $FF, $F1, $FF, $FF, $FF, $FF, $3E, $88, $EA, $44, $D0, $3E, $14, $EA, $45
	db $D0, $3E, $01, $EA, $5D, $D0, $AF, $EA, $5C, $D0, $AF, $EA, $59, $D0, $3C, $EA
	db $5A, $D0, $3E, $72, $EA, $55, $D0, $3E, $45, $EA, $56, $D0, $3E, $72, $EA, $57
	db $D0, $3E, $4B, $EA, $58, $D0, $C9, $10, $12, $14, $16, $17, $FF, $59, $FF, $FF
	db $FF, $82, $3E, $88, $EA, $44, $D0, $3E, $0A, $EA, $45, $D0, $3E, $00, $EA, $5D
	db $D0, $AF, $EA, $5C, $D0, $AF, $EA, $59, $D0, $3C, $EA, $5A, $D0, $3E, $72, $EA
	db $55, $D0, $3E, $80, $EA, $56, $D0, $3E, $72, $EA, $57, $D0, $3E, $89, $EA, $58
	db $D0, $C9, $78, $78, $78, $78, $58, $56, $56, $68, $FF, $A1, $FF, $11, $00, $81
	db $FF, $11, $00, $3E, $88, $EA, $44, $D0, $3E, $19, $EA, $45, $D0, $3E, $00, $EA
	db $5D, $D0, $AF, $EA, $5C, $D0, $AF, $EA, $59, $D0, $3C, $EA, $5A, $D0, $3E, $72
	db $EA, $55, $D0, $3E, $C1, $EA, $56, $D0, $3E, $72, $EA, $57, $D0, $3E, $C7, $EA
	db $58, $D0, $C9, $02, $41, $26, $71, $31, $FF, $F0, $FF, $FF, $A0, $D2, $3E, $88
	db $EA, $44, $D0, $3E, $0F, $EA, $45, $D0, $AF, $EA, $59, $D0, $3C, $EA, $5A, $D0
	db $3E, $00, $EA, $5D, $D0, $AF, $EA, $5C, $D0, $3E, $72, $EA, $55, $D0, $3E, $FC
	db $EA, $56, $D0, $3E, $73, $EA, $57, $D0, $3E, $04, $EA, $58, $D0, $C9, $02, $41
	db $61, $71, $91, $71, $62, $FF, $F0, $F9, $F9, $F9, $F0, $70, $A2
Code_730B:
	ld a, $88
	ld [wNoisePan], a
	ld a, $29
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $02
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_733B)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_733B)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7341)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7341)
	ld [wNoise42], a
	ret
Noise43_733B:
	db $03, $93, $80, $72, $70, $FF
Noise42_7341:
	db $F0, $FF, $FF, $FF, $F3
Code_7346:
	ld a, $88
	ld [wNoisePan], a
	ld a, $32
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_736D)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_736D)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7378)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7378)
	ld [wNoise42], a
	ret
Noise43_736D:
	db $57, $56, $55, $54, $43, $42, $41, $41
	db $42, $43, $FF
Noise42_7378:
	db $F2, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $F3

; Unreferenced (438 bytes)
	db $3E, $88, $EA, $44, $D0, $3E, $23, $EA, $45, $D0, $AF, $EA, $59, $D0, $3C, $EA
	db $5A, $D0, $3E, $01, $EA, $5D, $D0, $AF, $EA, $5C, $D0, $3E, $73, $EA, $55, $D0
	db $3E, $B2, $EA, $56, $D0, $3E, $73, $EA, $57, $D0, $3E, $BD, $EA, $58, $D0, $C9
	db $27, $26, $25, $14, $13, $12, $11, $10, $10, $10, $FF, $19, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $F2, $3E, $88, $EA, $44, $D0, $3E, $19, $EA, $45, $D0, $AF
	db $EA, $59, $D0, $3C, $EA, $5A, $D0, $3E, $00, $EA, $5D, $D0, $AF, $EA, $5C, $D0
	db $3E, $73, $EA, $55, $D0, $3E, $F7, $EA, $56, $D0, $3E, $73, $EA, $57, $D0, $3E
	db $F9, $EA, $58, $D0, $C9, $32, $FF, $F1, $3E, $88, $EA, $44, $D0, $3E, $08, $EA
	db $45, $D0, $AF, $EA, $59, $D0, $3C, $EA, $5A, $D0, $3E, $00, $EA, $5D, $D0, $AF
	db $EA, $5C, $D0, $3E, $74, $EA, $55, $D0, $3E, $2A, $EA, $56, $D0, $3E, $74, $EA
	db $57, $D0, $3E, $30, $EA, $58, $D0, $C9, $22, $32, $42, $44, $00, $FF, $F1, $F1
	db $F1, $F1, $00, $AF, $EA, $59, $D0, $3C, $EA, $5A, $D0, $3E, $00, $EA, $5D, $D0
	db $AF, $EA, $5C, $D0, $3E, $88, $EA, $44, $D0, $3E, $13, $EA, $45, $D0, $CD, $9F
	db $4A, $3E, $F2, $E0, $21, $3E, $80, $E0, $23, $3E, $74, $EA, $55, $D0, $3E, $70
	db $EA, $56, $D0, $3E, $00, $EA, $57, $D0, $3E, $00, $EA, $58, $D0, $C9, $12, $64
	db $02, $37, $47, $24, $55, $71, $07, $44, $60, $36, $84, $82, $64, $02, $37, $47
	db $24, $55, $71, $07, $44, $60, $36, $86, $32, $FF, $3E, $88, $EA, $44, $D0, $3E
	db $0F, $EA, $45, $D0, $AF, $EA, $59, $D0, $3C, $EA, $5A, $D0, $3E, $C2, $E0, $21
	db $3E, $80, $E0, $23, $3E, $74, $EA, $55, $D0, $3E, $BB, $EA, $56, $D0, $3E, $00
	db $EA, $57, $D0, $3E, $00, $EA, $58, $D0, $C9, $12, $92, $42, $42, $42, $42, $52
	db $65, $45, $FF, $3E, $88, $EA, $44, $D0, $3E, $08, $EA, $45, $D0, $AF, $EA, $59
	db $D0, $3C, $EA, $5A, $D0, $3E, $00, $EA, $5D, $D0, $AF, $EA, $5C, $D0, $3E, $74
	db $EA, $55, $D0, $3E, $F5, $EA, $56, $D0, $3E, $74, $EA, $57, $D0, $3E, $F7, $EA
	db $58, $D0, $C9, $32, $FF, $A3, $00, $36, $8A, $FF, $FF, $A8, $63, $00, $00, $36
	db $8A, $FF, $FF, $A8, $63, $00, $00, $06, $8A, $FF, $FF, $A8, $60, $00, $00, $06
	db $8A, $FF, $FF, $A8, $60, $00, $B7, $40, $F4, $7B, $FD, $FF, $FE, $DC, $02, $46
	db $8A, $BD, $FD, $BA, $6F, $20, $00, $00, $BB, $BB, $00, $00, $BB, $BB, $00, $00
	db $BB, $BB, $77, $77, $BB, $BB
Wave_7538:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
Wave_7548:
	db $00, $00, $00, $00, $CC, $CC, $CC, $CC
	db $00, $00, $00, $00, $CC, $CC, $CC, $CC
Wave_7558:
	db $02, $34, $32, $00, $89, $CF, $FC, $98
	db $04, $44, $44, $00, $CF, $FF, $FF, $FC

; Unreferenced (32 bytes)
	db $00, $00, $00, $00, $CD, $EF, $FD, $EC, $00, $12, $21, $00, $DD, $DD, $DD, $DD
	db $00, $00, $00, $00, $00, $00, $FF, $FF, $00, $00, $00, $00, $00, $00, $FF, $FF
Wave_7588:
	db $00, $00, $00, $00, $00, $00, $FF, $00
	db $00, $00, $00, $00, $00, $00, $FF, $00
Wave_7598:
	db $00, $00, $00, $00, $00, $00, $FF, $70
	db $00, $00, $00, $00, $00, $00, $FF, $70
Wave_75A8:
	db $00, $00, $00, $CD, $EF, $FF, $FF, $FF
	db $04, $8C, $FF, $FF, $FF, $FF, $FF, $FF
Wave_75B8:
	db $48, $FF, $FF, $FF, $FF, $FF, $FF, $84
	db $00, $66, $06, $60, $00, $4F, $FF, $88
Wave_75C8:
	db $EC, $96, $31, $90, $00, $00, $00, $00
	db $24, $69, $CE, $FF, $FF, $FF, $FF, $FF

; Unreferenced (48 bytes)
	db $12, $34, $56, $78, $9A, $BC, $DE, $FF, $ED, $CB, $A9, $87, $65, $43, $21, $00
	db $63, $10, $40, $20, $00, $00, $01, $36, $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9
	db $63, $10, $01, $47, $74, $10, $01, $36, $9C, $EF, $FE, $B8, $8B, $EF, $FE, $C9
Wave_7608:
	db $63, $1F, $01, $47, $74, $10, $01, $36
	db $9C, $E0, $FE, $B8, $8B, $EF, $FE, $C9

; Unreferenced (32 bytes)
	db $B7, $40, $04, $7B, $CD, $FF, $FE, $DC, $02, $46, $8A, $BD, $FD, $BA, $64, $20
	db $B7, $44, $44, $7B, $CD, $D7, $7D, $DC, $22, $46, $8A, $BD, $DD, $BA, $64, $22
Wave_7638:
	db $0F, $00, $F0, $F0, $F0, $F0, $00, $0F
	db $0F, $FF, $FF, $00, $FF, $F0, $0F, $0F

; Unreferenced (48 bytes)
	db $00, $00, $00, $00, $00, $00, $00, $00, $ED, $CB, $A9, $87, $65, $43, $21, $00
	db $20, $24, $68, $AC, $EC, $A8, $64, $20, $24, $68, $A8, $64, $20, $24, $68, $64
	db $02, $48, $AC, $FF, $FC, $53, $00, $27, $9C, $DD, $DC, $B7, $7B, $CD, $DD, $C9
Noise43_7678:
	db $21, $22, $23, $FF
Noise42_767C:
	db $A3, $FF, $54
Noise43_767F:
	db $21, $21, $FF
Noise42_7682:
	db $61, $31
Noise43_7684:
	db $21, $21, $FF
Noise42_7687:
	db $81, $31
Noise43_7689:
	db $21, $21, $FF
Noise42_768C:
	db $81, $43
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_76B4)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_76B4)
	ld [wNoise43], a
	ld a, HIGH(Noise42_76B7)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_76B7)
	ld [wNoise42], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $01
	jp PlaySfx
Noise43_76B4:
	db $20, $15, $FF
Noise42_76B7:
	db $A0, $41
Drum2:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_76DF)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_76DF)
	ld [wNoise43], a
	ld a, HIGH(Noise42_76E3)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_76E3)
	ld [wNoise42], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $02
	jp PlaySfx
Noise43_76DF:
	db $20, $52, $32, $FF
Noise42_76E3:
	db $A0, $A0, $52
Drum3:
	ret
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7689)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7689)
	ld [wNoise43], a
	ld a, HIGH(Noise42_768C)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_768C)
	ld [wNoise42], a
	ret
Drum14:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7689)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7689)
	ld [wNoise43], a
	ld a, HIGH(Noise42_768C)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_768C)
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
	ld a, HIGH(Noise43_7684)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7684)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7687)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7687)
	ld [wNoise42], a
	ret
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_767F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_767F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7682)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7682)
	ld [wNoise42], a
	ret
Drum7:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7678)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7678)
	ld [wNoise43], a
	ld a, HIGH(Noise42_767C)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_767C)
	ld [wNoise42], a
	ld a, $01
	call PlaySfx
	ret
Drum8:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_781E)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_781E)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7821)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7821)
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
	ld a, HIGH(Noise43_781E)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_781E)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7821)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7821)
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
	ld a, HIGH(Noise43_781E)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_781E)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7821)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7821)
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
	ld a, HIGH(Noise43_7823)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7823)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7826)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7826)
	ld [wNoise42], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $02
	jp PlaySfx

; Unreferenced (1 bytes)
	db $C9
Noise43_781E:
	db $21, $31, $FF
Noise42_7821:
	db $A0, $62
Noise43_7823:
	db $21, $78, $FF
Noise42_7826:
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

; Unreferenced (30 bytes)
	db $21, $31, $FF, $A0, $62, $21, $78, $FF, $A0, $81, $FF, $77, $66, $55, $44, $33
	db $22, $11, $00, $80, $FF, $00, $11, $22, $33, $44, $55, $66, $77, $FF
DriverEndText2:
	db "Final de la rutina de musica"

; Unreferenced (1902 bytes)
	db $20, $6D, $75, $73, $69, $63, $61, $45, $08, $89, $70, $1C, $89, $70, $40, $89
	db $70, $44, $8B, $45, $88, $3B, $C6, $74, $7B, $8D, $55, $08, $89, $75, $08, $8B
	db $08, $52, $68, $A0, $91, $C7, $7B, $50, $FF, $51, $28, $8B, $45, $08, $3B, $C6
	db $74, $3D, $8D, $55, $F8, $89, $75, $F8, $8B, $08, $52, $68, $10, $92, $C7, $7B
	db $50, $FF, $11, $FF, $75, $08, $E8, $CF, $97, $FF, $FF, $39, $75, $F8, $74, $1F
	db $FF, $75, $F8, $8B, $03, $53, $FF, $90, $A8, $00, $00, $00, $8B, $F8, $8B, $45
	db $F8, $50, $8B, $08, $FF, $51, $08, $3B, $FE, $0F, $8C, $49, $06, $00, $00, $8B
	db $45, $88, $8D, $55, $08, $52, $68, $78, $91, $C7, $7B, $8B, $08, $50, $FF, $51
	db $28, $3B, $C6, $75, $0F, $FF, $75, $08, $E8, $8D, $97, $FF, $FF, $C7, $45, $E4
	db $01, $00, $00, $00, $F6, $83, $AE, $02, $00, $00, $10, $75, $07, $8B, $CB, $E8
	db $7C, $18, $00, $00, $68, $C8, $00, $00, $00, $E8, $94, $A3, $FF, $FF, $3B, $C6
	db $0F, $84, $56, $3F, $09, $00, $53, $8B, $C8, $E8, $2A, $19, $00, $00, $8D, $48
	db $10, $F7, $D8, $1B, $C0, $23, $C1, $89, $45, $DC, $0F, $84, $06, $43, $09, $00
	db $8B, $4B, $3C, $C1, $E1, $1C, $81, $F9, $00, $00, $00, $10, $0F, $8D, $31, $3F
	db $09, $00, $66, $81, $A3, $AA, $02, $00, $00, $1F, $FE, $83, $C0, $F0, $89, $83
	db $24, $02, $00, $00, $8B, $83, $AC, $02, $00, $00, $C1, $E8, $03, $A8, $01, $89
	db $75, $DC, $89, $B3, $28, $02, $00, $00, $89, $B3, $2C, $02, $00, $00, $0F, $85
	db $A0, $3F, $09, $00, $8B, $43, $3C, $8B, $C8, $C1, $E1, $1C, $81, $F9, $00, $00
	db $00, $10, $7D, $07, $24, $F1, $0C, $01, $89, $43, $3C, $39, $75, $A4, $0F, $85
	db $47, $06, $00, $00, $6A, $38, $E8, $07, $A3, $FF, $FF, $8B, $F8, $3B, $FE, $0F
	db $84, $A5, $3F, $09, $00, $6A, $01, $8B, $CF, $E8, $E8, $4C, $00, $00, $89, $5F
	db $18, $C7, $07, $30, $91, $C7, $7B, $39, $B5, $7C, $FF, $FF, $FF, $89, $BB, $CC
	db $01, $00, $00, $0F, $85, $88, $3F, $09, $00, $39, $75, $84, $0F, $84, $55, $40
	db $09, $00, $39, $75, $80, $0F, $84, $20, $40, $09, $00, $8B, $45, $88, $3B, $C6
	db $0F, $84, $D8, $00, $00, $00, $8D, $55, $08, $89, $75, $08, $8B, $08, $52, $68
	db $54, $91, $C7, $7B, $50, $FF, $51, $28, $8B, $45, $08, $3B, $C6, $0F, $85, $4A
	db $40, $09, $00, $8B, $45, $D8, $3B, $C6, $0F, $85, $5E, $40, $09, $00, $8B, $45
	db $88, $8D, $55, $08, $52, $68, $F0, $91, $C7, $7B, $8B, $08, $50, $FF, $51, $28
	db $8B, $45, $08, $3B, $C6, $74, $1A, $8B, $08, $8D, $55, $F0, $52, $68, $20, $AE
	db $C7, $7B, $50, $FF, $11, $8B, $45, $08, $50, $8B, $08, $FF, $51, $08, $89, $75
	db $08, $8B, $4D, $F0, $3B, $CE, $74, $76, $8B, $71, $24, $8B, $46, $2C, $33, $45
	db $FC, $25, $10, $22, $00, $00, $31, $45, $FC, $8B, $83, $74, $02, $00, $00, $85
	db $C0, $0F, $85, $B2, $05, $00, $00, $83, $79, $28, $00, $0F, $85, $CB, $05, $00
	db $00, $8B, $46, $48, $85, $C0, $74, $14, $8D, $4D, $B0, $51, $50, $E8, $DE, $4B
	db $00, $00, $8B, $F8, $85, $FF, $0F, $85, $8C, $04, $00, $00, $8B, $46, $50, $85
	db $C0, $74, $14, $8D, $4D, $B4, $51, $50, $E8, $C3, $4B, $00, $00, $8B, $F8, $85
	db $FF, $0F, $85, $71, $04, $00, $00, $83, $7D, $C0, $00, $75, $06, $8B, $46, $3C
	db $89, $45, $C0, $8B, $46, $40, $33, $F6, $89, $83, $2C, $05, $00, $00, $39, $75
	db $80, $74, $29, $F6, $83, $AF, $02, $00, $00, $02, $0F, $85, $E2, $3F, $09, $00
	db $6A, $FF, $68, $44, $91, $C7, $7B, $6A, $06, $FF, $75, $84, $E8, $B2, $B5, $FF
	db $FF, $83, $C4, $10, $85, $C0, $0F, $84, $C6, $3F, $09, $00, $8B, $45, $80, $3B
	db $C6, $0F, $84, $2F, $40, $09, $00, $8B, $08, $8D, $55, $E0, $52, $56, $FF, $75
	db $88, $50, $FF, $51, $50, $8B, $F8, $3B, $FE, $0F, $85, $09, $04, $00, $00, $FF
	db $75, $E0, $FF, $15, $94, $13, $C7, $7B, $3B, $C6, $0F, $85, $22, $40, $09, $00
	db $FF, $75, $E0, $8D, $8B, $F0, $01, $00, $00, $E8, $30, $A0, $FF, $FF, $8B, $F8
	db $3B, $FE, $0F, $85, $E0, $03, $00, $00, $FF, $75, $80, $8D, $83, $E8, $01, $00
	db $00, $50, $E8, $B1, $C1, $FF, $FF, $8D, $85, $6C, $FF, $FF, $FF, $50, $FF, $B3
	db $F0, $01, $00, $00, $E8, $9D, $17, $00, $00, $39, $B3, $74, $02, $00, $00, $0F
	db $85, $F6, $04, $00, $00, $FF, $B3, $F0, $01, $00, $00, $E8, $A6, $A5, $FF, $FF
	db $83, $F8, $0B, $0F, $84, $D1, $3F, $09, $00, $6A, $01, $56, $56, $8B, $CB, $E8
	db $3C, $B5, $FF, $FF, $8B, $CB, $E8, $49, $93, $FF, $FF, $3B, $C3, $0F, $85, $E0
	db $04, $00, $00, $6A, $6C, $E8, $08, $A1, $FF, $FF, $3B, $C6, $0F, $84, $EC, $3F
	db $09, $00, $8B, $C8, $E8, $3F, $18, $00, $00, $89, $45, $EC, $39, $75, $EC, $0F
	db $84, $81, $40, $09, $00, $8B, $4D, $EC, $53, $E8, $DC, $18, $00, $00, $8B, $F8
	db $3B, $FE, $0F, $8C, $50, $03, $00, $00, $8B, $45, $EC, $FF, $B3, $F0, $01, $00
	db $00, $33, $F6, $89, $83, $14, $03, $00, $00, $89, $75, $EC, $E8, $35, $A5, $FF
	db $FF, $8B, $7D, $FC, $83, $F8, $0A, $0F, $84, $A9, $3F, $09, $00, $8D, $85, $68
	db $FF, $FF, $FF, $8B, $CB, $50, $E8, $DE, $78, $00, $00, $0B, $BD, $68, $FF, $FF
	db $FF, $39, $75, $C8, $0F, $85, $81, $04, $00, $00, $8B, $83, $10, $02, $00, $00
	db $A9, $00, $00, $00, $40, $0F, $85, $A0, $3F, $09, $00, $B9, $00, $20, $00, $00
	db $85, $C1, $0F, $85, $9E, $3F, $09, $00, $F6, $C4, $40, $0F, $85, $A0, $3F, $09
	db $00, $39, $75, $98, $75, $08, $E8, $3E, $34, $00, $00, $89, $45, $98, $E8, $5C
	db $34, $00, $00, $89, $45, $08, $8B, $03, $8B, $CB, $FF, $90, $BC, $01, $00, $00
	db $85, $C0, $0F, $85, $80, $3F, $09, $00, $8B, $8B, $80, $01, $00, $00, $80, $79
	db $29, $00, $0F, $84, $86, $3F, $09, $00, $F6, $83, $11, $02, $00, $00, $08, $0F
	db $85, $82, $3F, $09, $00, $83, $7D, $C0, $00, $BE, $B0, $04, $00, $00, $0F, $84
	db $15, $04, $00, $00, $83, $7D, $BC, $00, $75, $09, $8B, $83, $28, $05, $00, $00
	db $89, $45, $BC, $FF, $75, $C0, $8B, $CB, $E8, $B6, $19, $00, $00, $6A, $78, $E8
	db $FE, $9F, $FF, $FF, $85, $C0, $0F, $84, $83, $3F, $09, $00, $8B, $C8, $E8, $5E
	db $E4, $FF, $FF, $85, $C0, $89, $83, $8C, $02, $00, $00, $0F, $84, $75, $3F, $09
	db $00, $53, $8B, $C8, $E8, $A9, $19, $00, $00, $8B, $83, $8C, $02, $00, $00, $8B
	db $4D, $08, $89, $78, $2C, $8B, $83, $8C, $02, $00, $00, $89, $48, $34, $8B, $83
	db $8C, $02, $00, $00, $8B, $8B, $10, $02, $00, $00, $89, $48, $30, $8B, $83, $8C
	db $02, $00, $00, $8B, $4D, $98, $89, $48, $38, $8B, $4D, $C0, $3B, $CE, $0F, $84
	db $3C, $3F, $09, $00, $81, $F9, $B1, $04, $00, $00, $0F, $84, $30, $3F, $09, $00
	db $8B, $83, $8C, $02, $00, $00, $89, $48, $3C, $8B, $4D, $BC, $3B, $CE, $0F, $84
	db $26, $3F, $09, $00, $81, $F9, $B1, $04, $00, $00, $0F, $84, $1A, $3F, $09, $00
	db $8B, $83, $8C, $02, $00, $00, $89, $48, $40, $8B, $83, $80, $01, $00, $00, $83
	db $78, $50, $00, $74, $1D, $8B, $8B, $8C, $02, $00, $00, $83, $C0, $54, $83, $C1
	db $58, $50, $51, $E8, $C2, $77, $00, $00, $8B, $F8, $85, $FF, $0F, $85, $B6, $01
	db $00, $00, $8B, $8B, $88, $02, $00, $00, $85, $C9, $0F, $85, $E4, $3E, $09, $00
	db $83, $7D, $B0, $00, $74, $18, $FF, $75, $B0, $8B, $8B, $8C, $02, $00, $00, $E8
	db $B2, $54, $07, $00, $8B, $F8, $85, $FF, $0F, $85, $8A, $01, $00, $00, $8B, $45
	db $B4, $85, $C0, $0F, $84, $2C, $03, $00, $00, $8B, $8B, $8C, $02, $00, $00, $50
	db $E8, $A4, $77, $00, $00, $8B, $F8, $85, $FF, $0F, $85, $69, $01, $00, $00, $8B
	db $45, $8C, $85, $C0, $0F, $85, $2A, $03, $00, $00, $6A, $16, $33, $C0, $59, $8D
	db $BD, $10, $FF, $FF, $FF, $F3, $AB, $E8, $EC, $B0, $FF, $FF, $89, $85, $1C, $FF
	db $FF, $FF, $8B, $83, $8C, $02, $00, $00, $89, $85, $14, $FF, $FF, $FF, $8B, $83
	db $EC, $01, $00, $00, $89, $85, $18, $FF, $FF, $FF, $8B, $83, $F0, $01, $00, $00
	db $89, $85, $3C, $FF, $FF, $FF, $8B, $45, $B8, $89, $85, $44, $FF, $FF, $FF, $8B
	db $45, $A0, $89, $85, $34, $FF, $FF, $FF, $8B, $85, $74, $FF, $FF, $FF, $89, $85
	db $48, $FF, $FF, $FF, $8B, $45, $A8, $89, $85, $50, $FF, $FF, $FF, $8B, $45, $AC
	db $89, $85, $54, $FF, $FF, $FF, $8B, $45, $C4, $89, $85, $58, $FF, $FF, $FF, $8B
	db $45, $C8, $89, $85, $5C, $FF, $FF, $FF, $8B, $45, $CC, $89, $85, $60, $FF, $FF
	db $FF, $8B, $85, $6C, $FF, $FF, $FF, $89, $85, $64, $FF, $FF, $FF, $8B, $45, $D0
	db $85, $C0, $89, $9D, $38, $FF, $FF, $FF, $0F, $85, $15, $3E, $09, $00, $8B, $45
	db $90, $85, $C0, $0F, $85, $15, $3E, $09, $00, $8B, $85, $78, $FF, $FF, $FF, $85
	db $C0, $0F, $85, $1B, $3E, $09, $00, $8B, $85, $70, $FF, $FF, $FF, $85, $C0, $0F
	db $85, $25, $3E, $09, $00, $8B, $45, $80, $85, $C0, $74, $0F, $89, $85, $28, $FF
	db $FF, $FF, $8B, $45, $88, $89, $85, $2C, $FF, $FF, $FF, $8D, $B3, $EC, $02, $00
	db $00, $8D, $85, $10, $FF, $FF, $FF, $56, $50, $6A, $00, $6A, $00, $E8, $26, $3F
	db $00, $00, $8B, $F8, $85, $FF, $75, $60, $8B, $CB, $E8, $97, $AA, $FF, $FF, $8B
	db $0E, $50, $E8, $58, $4A, $00, $00, $8B, $F8, $85, $FF, $75, $4B, $6A, $01, $8B
	db $CB, $E8, $80, $A2, $FF, $FF, $8B, $8B, $14, $03, $00, $00, $85, $C9, $74, $07
	db $FF, $36, $E8, $DA, $17, $00, $00, $8B, $0E, $8D, $85, $10, $FF, $FF, $FF, $6A
	db $00, $50, $6A, $01, $E8, $5B, $53, $00, $00, $8B, $0E, $6A, $00, $E8, $63, $C4
	db $FF, $FF, $8B, $F8, $81, $E7, $00, $00, $80, $00, $F7, $DF, $1B, $FF, $81, $E7
	db $05, $40, $00, $80, $83, $63, $3C, $DF, $FF, $B5, $70, $FF, $FF, $FF, $E8, $57
	db $91, $FF, $FF, $FF, $75, $80, $E8, $4F, $91, $FF, $FF, $8B, $45, $F0, $8B, $C8
	db $83, $C0, $10, $F7, $D9, $1B, $C9, $23, $C8, $51, $E8, $3B, $91, $FF, $FF, $FF
	db $75, $DC, $E8, $33, $91, $FF, $FF, $FF, $75, $F4, $E8, $2B, $91, $FF, $FF, $FF
	db $75, $D0, $E8, $23, $91, $FF, $FF, $FF, $75, $D4, $E8, $1B, $91, $FF, $FF, $FF
	db $75, $E8, $E8, $13, $91, $FF, $FF, $8B, $45, $8C, $8B, $C8, $83, $C0, $10, $F7
	db $D9, $1B, $C9, $23, $C8, $51, $E8, $FF, $90, $FF, $FF, $FF, $75, $D8, $E8, $F7
	db $90, $FF, $FF, $FF, $75, $B0, $E8, $63, $98, $FF, $FF, $FF, $75, $B4, $E8, $5B
	db $98, $FF, $FF, $FF, $75, $E0, $FF, $15, $E8, $17, $C7, $7B, $8B, $45, $EC, $85
	db $C0, $0F, $85, $0E, $3D, $09, $00, $85, $FF, $7C, $1C, $8B, $43, $3C, $C1, $E0
	db $1C, $3D, $00, $00, $00, $20, $0F, $8D, $04, $3D, $09, $00, $6A, $00, $6A, $02
	db $8B, $CB, $E8, $52, $40, $00, $00, $8D, $8D, $04, $FF, $FF, $FF, $E8
