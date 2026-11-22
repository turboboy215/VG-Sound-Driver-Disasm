; =====================================================================
; Ronaldo V-Football (E) (M7) [C] - Game Boy Color
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o ronaldo.o Ronaldo_SoundDriver.asm
;   rgblink -o ronaldo.gb ronaldo.o
;   python tools/cmp_banked.py ronaldo.gb "Ronaldo V.Football (E) (M7) [C][!].gbc" 31:4000-7FFF
; (driver and data fill ROM bank 31; the linked file only matches in that range)
;
; Documentation: Ronaldo_SoundDriver.md / AJG_SoundEngine_Family.md
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
	db $89 + \1
ENDM
MACRO ARP       ; arpeggio n of the current arpeggio table
	db $9C + \1
ENDM
MACRO HWENV     ; HWENV env, 0 | HWENV env, ticks, env2  (pulse NRx2 at note on, env2 after ticks)
	db $74, \1, \2
	IF _NARG > 2
		db \3
	ENDC
ENDM
MACRO RELEASE   ; RELEASE 0 = off | RELEASE minlen << 4 | ticks_left, env
	db $7B, \1
	IF _NARG > 1
		db \2
	ENDC
ENDM
MACRO NOTE_HOOK ; NOTE_HOOK 0 = off | NOTE_HOOK on_note, on_wait (code addresses)
	db $84
	IF _NARG > 1
		dw \1, \2
	ELSE
		db \1
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
MACRO AUTOPAN
	db $75
	db \1
ENDM
MACRO AUTODUTY
	db $76
	db \1
ENDM
MACRO FADE
	db $77
	db \1
	dw \2
ENDM
MACRO FADE_OFF
	db $78
ENDM
MACRO WAVE
	db $79
	dw \1
ENDM
MACRO CH_TRANSPOSE
	db $7A
	db \1
ENDM
MACRO ARP_OFF
	db $7C
ENDM
MACRO PAT_GOTO
	db $7D
	dw \1
ENDM
MACRO PAT_CALL
	db $7E
	dw \1
ENDM
MACRO CALL_CODE
	db $7F
	dw \1
ENDM
MACRO REPEAT_END
	db $80
ENDM
MACRO VOL
	db $81
	db \1
ENDM
MACRO SLIDE_UP
	db $82
	db \1
ENDM
MACRO SLIDE_DOWN
	db $83
	db \1
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
DEF DRUM_AUTOPAN EQU $35        ; + 1 byte: noise auto-pan every n noise steps
DEF DRUM_REPEAT_END EQU $36
DEF DRUM_LEVEL EQU $37          ; + 0-15: noise level (attenuation 15 - n)
DEF DRUM_SPEED EQU $47          ; + 0-19: noise sequence speed
DEF DRUM_REPEAT EQU $5A         ; + n: repeat the following bytes up to DRUM_REPEAT_END
DEF DRUM_TEMPO EQU $C7         ; + n: one step every n ticks
DEF DRUM_LOOP EQU $FF           ; restart the pattern

; ---- RAM / HRAM ----
DEF wCh1 EQU $DC00
DEF wPaused EQU $DC44
DEF wStereo EQU $DC45
DEF wShNR32 EQU $DC46
DEF wInInstr EQU $DC47
DEF wNoisePan EQU $DC48
DEF wDrumHold EQU $DC49
DEF wInstrTable EQU $DC4A
DEF wInstrTableHi EQU $DC4B
DEF wArpTable EQU $DC4C
DEF wArpTableHi EQU $DC4D
DEF wMusicWave EQU $DC4E
DEF wMusicWaveHi EQU $DC4F
DEF wNoiseAutoPan EQU $DC50
DEF wDrumPatHi EQU $DC51
DEF wDrumPat EQU $DC52
DEF wDrumPos EQU $DC53
DEF wDrumsOn EQU $DC54
DEF wDrumTempo EQU $DC55
DEF wDrumTimer EQU $DC56
DEF wDrumLoopCount EQU $DC57
DEF wDrumLoopPos EQU $DC58
DEF wNoise43Hi EQU $DC59
DEF wNoise43 EQU $DC5A
DEF wNoise42Hi EQU $DC5B
DEF wNoise42 EQU $DC5C
DEF wNoisePos EQU $DC5D
DEF wNoiseOn EQU $DC5E
DEF wNoiseAtten EQU $DC5F
DEF wNoiseTimer EQU $DC60
DEF wNoiseSpeed EQU $DC61
DEF wFadeTable EQU $DC62
DEF wFadeTableHi EQU $DC63
DEF wFadePos EQU $DC64
DEF wFadeTimer EQU $DC65
DEF wFadeSpeed EQU $DC66
DEF wFadeOn EQU $DC67
DEF wDutyCh1 EQU $DC68
DEF wDutyCh2 EQU $DC69
DEF wCrowdNoise EQU $DC6A
DEF wCrowdLevel EQU $DC6B
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


SECTION "SoundDriver", ROMX[$4000], BANK[31]


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
	dw Cmd_NoteHook
	dw Cmd_Gliss1
	dw Cmd_Gliss2
	dw Cmd_Gliss3
	dw Cmd_GlissOff
	jp SndUpdate                       ; SndUpdate
	jp SndPause                        ; SndPause
	jp SndResume                       ; SndResume
	jp StopAll                         ; StopAll
	jp GamePlaySfxGlue                 ; PlaySfx (A = id)
	jp SndInit                         ; SndInit
	jp SongFadeIn                      ; SongFadeIn (A = speed)
	jp SongFadeOut                     ; SongFadeOut (A = speed)
	jp PlaySong1                       ; song 1
	jp PlaySong2                       ; song 2
	jp PlaySong3                       ; song 3
	jp PlaySong4                       ; song 4
	jp PlaySong5                       ; song 5
	jp PlaySong6                       ; song 6
	jp InstrTable1                      ; unused song slot: jumps into the instrument table (never called)
	jp InstrTable1                      ; unused song slot: jumps into the instrument table (never called)
	jp InstrTable1                      ; unused song slot: jumps into the instrument table (never called)
	jp InstrTable1                      ; unused song slot: jumps into the instrument table (never called)
	jp InstrTable1                      ; unused song slot: jumps into the instrument table (never called)
	jp InstrTable1                      ; unused song slot: jumps into the instrument table (never called)
	jp InstrTable1                      ; unused song slot: jumps into the instrument table (never called)

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

; NOTE_HOOK on_note, on_wait / NOTE_HOOK 0 (new in this version, unused by the
; data): at each note, field $3C = previous note, $3D = this note, then call
; on_note; at each WAIT/WAIT2, call on_wait and play the note in $3C.
Cmd_NoteHook:
	ld l, $3C
	xor a
	ld [hli], a
	ld [hli], a
	ld a, [de]
	inc de
	and a
	jr z, NoteHookOff
	ld [hli], a
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	inc de
	ld [hl], a
	ld l, $04
	set 5, [hl]
	ret
NoteHookOff:
	ld l, $04
	res 5, [hl]
	ret
Cmd_Gliss1:
	ld a, $01
	ld l, $43
	ld [hl], a
	ret
Cmd_Gliss2:
	ld a, $02
	ld l, $43
	ld [hl], a
	ret
Cmd_Gliss3:
	ld a, $03
	ld l, $43
	ld [hl], a
	ret
Cmd_GlissOff:
	xor a
	ld l, $43
	ld [hl], a
	ret

; SndUpdate (once per frame): tick the four pages (or only the SFX page while paused),
; drums + noise sequence, output, NR51, then the NR50 fade.
SndUpdate:
	ld a, [wPaused]
	and a
	jp nz, UpdatePaused
	ld h, $DC
	call ChannelTick
	inc h
	call ChannelTick
	inc h
	call ChannelTick
	call DrumTick
	ld h, $DF
	call ChannelTick

; Output, pulse pages: NRx3 = period low + pitch offset; when the high byte changed
; or the envelope flag ($33) is set: with the flag NRx2 = field $32 and NRx4 =
; high | $80, else NRx4 = high. (Obelix GBC's duty shadows are gone: duty goes
; straight to NR11/NR21.)
OutputCh1:
	ld hl, $DC25
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
	ld l, $33
	ld a, b
	ld c, [hl]
	inc c
	dec c
	jr z, OutputCh1Hi
	jp OutputCh1Retrig
OutputCh1Env:
	ld l, $33
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
	ld l, $33
	ld a, b
	ld c, [hl]
	inc c
	dec c
	jr z, OutputCh2Hi
	jp OutputCh2Retrig
OutputCh2Env:
	ld l, $33
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
	ld hl, $DF27
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
	add a, $DE
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
	ld hl, $DC38
	ld c, [hl]
	inc h
	ld a, [hl]
	rlc a
	or c
	ld c, a
	inc h
	ld a, [$DF27]
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
	ld c, a
	ld a, [wStereo]
	and a
	ld a, c
	jr nz, WriteNR51
	ld a, $FF
WriteNR51:
	ldh [rNR51], a
	jp DoFade

; Paused: NR50 fade, tick and output only the SFX page.
UpdatePaused:
	call DoFade
	ld h, $DF
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
	ld l, $2F
	ld a, [hl]
	and a
	call nz, DoAutoDuty
	ld l, $2C
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
	bit 0, [hl]
	jr nz, DoArp
GlissStep:
	ld l, $42
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
	ld l, $42
	add a, [hl]
	cp $50
	jr c, SetPeriod
	xor a
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
NoteOnHook:
	ld l, $04
	bit 5, [hl]
	jr z, NoteOn
	ld b, a
	ld l, $3D
	ld a, [hld]
	ld [hli], a
	ld a, b
	push af
	ld [hl], a
	ld l, $3E
	ld a, [hli]
	ld c, a
	ld a, [hl]
	ld b, a
	call CallBC
	pop af
NoteOn:
	ld l, $02
	ld [hl], e
	inc l
	ld [hl], d
	ld c, a
	ld l, $43
	ld a, [hl]
	and a
	jr z, NoteOnNoGliss
	ld l, $0C
	ld a, [hl]
	sub c
	ld l, $42
	ld [hl], a
NoteOnNoGliss:
	ld a, c
	ld l, $0C
	ld [hl], a
	xor a
	ld l, $1F
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
	cp $DE
	jr c, NoteOnHwEnv
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
NoteOnHwEnv:
	ld l, $28
	ld a, [hl]
	ld l, $32
	ld [hli], a
	ld [hl], $01
	ld l, $29
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
	cp $9C
	jr nc, Cmd_Arp
	cp $89
	jp nc, Cmd_Instrument
	sub $60
	add a, a
	ld c, a
	ld b, $40
	ld a, [bc]
	ld l, a
	inc c
	ld a, [bc]
	ld b, a
	ld c, l
	call CallBC
	jp ReadStream
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
	sub $9C
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
	ld a, h
	cp $DE
	jr nc, InstrLookup
	cp $DC
	jr nz, InstrDutyCh2
	ld a, $80
	ld [wDutyCh1], a
	jr InstrLookup
InstrDutyCh2:
	ld a, $80
	ld [wDutyCh2], a
InstrLookup:
	ld a, b
	sub $88
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

; Unreferenced (1 bytes)
	db $C9
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
	cp $DE
	jr z, ReleaseCh3
	cp $DF
	jr z, ReleaseSfx
	ld a, [hl]
	ld l, $32
	ld [hli], a
	ld [hl], $01
SetReleased:
	ld l, $04
	set 2, [hl]
	ret
ReleaseCh3:
	ld a, [hl]
	and $0F
	ld [$DE1B], a
	ld [$DE1A], a
	ld a, [hl]
	and $F0
	swap a
	jr z, SetReleased
	ld [$DE08], a
	jr SetReleased
ReleaseSfx:
	ld a, [hl]
	and $0F
	ld [$DF1B], a
	ld [$DF1A], a
	ld a, [hl]
	and $F0
	swap a
	jr z, SetReleased
	ld [$DF08], a
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
	cp $DE
	jr nc, WaitReload
	ld l, $32
	xor a
	ld [hli], a
	inc a
	ld [hl], a
	jp WaitReload

; WAIT / WAIT2: wait one length (ends the read). The release check looks for WAIT
; only, so WAIT2 is a tie that lets the release happen.
Cmd_Wait:
	pop af
	ld l, $04
	bit 5, [hl]
	jr z, WaitReload
	ld l, $40
	ld a, [hli]
	ld c, a
	ld a, [hl]
	ld b, a
	call CallBC
	ld l, $3C
	ld a, [hl]
	jp NoteOn
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
	ld [wStereo], a
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
	ld [wCrowdLevel], a
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
	ld h, $DC
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
	cp $DF
	jr z, ResetSfxPage
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
	ld l, $42
	ld [hl], a
	ld l, $43
	ld [hl], a
	ld l, $2F
	ld [hl], a
	ld l, $2C
	ld [hl], a
	ld l, $37
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
	ld l, $33
	ld [hld], a
	dec a
	ld [hl], a
	ret
ResetSfxPage:
	xor a
	ld [$DF43], a
	ld [$DF27], a
	ld [$DF08], a
	ld [wNoiseTimer], a
	ld [wNoiseSpeed], a
	dec a
	ld [wShNR32], a
	jp RestoreMusicWave
Cmd_Transpose:
	ld a, [de]
	ld [$DC0F], a
	ld [$DD0F], a
	ld [$DE0F], a
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

; HwEnvAtten: a = a - 0 (stub; a place for an envelope attenuation).
HwEnvAtten:
	ld c, $00
	sub c
	ret

; HWENV env, t, env2: NRx2 value at each note on (pulse pages); if t is not 0,
; NRx2 = env2 t ticks into the note. HWENV env, 0: no second value.
Cmd_HwEnv:
	ld a, [de]
	call HwEnvAtten
	ld l, $32
	ld [hl], a
	ld l, $28
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
	call HwEnvAtten
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
	ld l, $2C
	ld [hli], a
	ld [hli], a
	ld [hl], $01
	ret

; Auto-pan: every n ticks the next of centre, right, centre, left, centre.
DoAutoPan:
	ld l, $2D
	dec [hl]
	ret nz
	ld l, $2C
	ld a, [hli]
	ld [hli], a
	ld a, [hl]
	inc a
	ld [hl], a
	dec a
	jr z, Cmd_PanC
	dec a
	jr z, Cmd_PanR
	dec a
	jr z, Cmd_PanC
	dec a
	jr z, Cmd_PanL
	ld [hl], $01
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
	ld a, [de]
	inc de
	ld l, $2F
	ld [hli], a
	ld [hli], a
	ld [hl], $01
	ret

; Auto-duty: every n ticks the next of 50, 75, 12.5, 75, 50 %. Written to NR11 on
; the Ch1 page, NR21 on any other page.
DoAutoDuty:
	ld l, $30
	dec [hl]
	ret nz
	ld l, $2F
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
	jr z, Cmd_Duty75
	ld [hl], $01
Cmd_Duty50:
	ld l, $80
	jr SetDuty
Cmd_Duty75:
	ld l, $C0
	jr SetDuty
Cmd_Duty12:
	ld l, $00

; SetDuty: NR11 on the Ch1 page, NR21 on any other page (also Ch3/SFX).
SetDuty:
	ld a, h
	cp $DC
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
	ld a, h
	cp $DE
	jr nz, LoadWave
	ld a, [de]
	inc de
	ld [wMusicWave], a
	ld a, [de]
	ld [wMusicWaveHi], a
	ld a, [$DF27]
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
	xor a
	ldh [rNR31], a
	ld a, [hl]
	or $80
	ldh [rNR30], a
	ldh [rNR34], a
	ret

; RestoreMusicWave: reload the music wave; unless paused, NR30 = NR34 = $80.
RestoreMusicWave:
	xor a
	ldh [rNR30], a
	ld c, $30
	ld hl, wMusicWave
	ld a, [hli]
	ld h, [hl]
	ld l, a
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
	ld a, $80
	ld [$DE07], a
	ldh [rNR30], a
	ldh [rNR34], a
	ret

; Unreferenced (233 bytes)
	db $03, $17, $04, $4F, $04, $84, $04, $B6, $04, $E5, $04, $12, $05, $3C, $05, $64
	db $05, $89, $05, $AD, $05, $CE, $05, $EE, $05, $0C, $06, $28, $06, $42, $06, $5B
	db $06, $73, $06, $89, $06, $9E, $06, $B2, $06, $C5, $06, $D7, $06, $E7, $06, $F7
	db $06, $06, $07, $14, $07, $21, $07, $2E, $07, $3A, $07, $45, $07, $4F, $07, $59
	db $07, $63, $07, $6C, $07, $74, $07, $7C, $07, $83, $07, $8A, $07, $91, $07, $97
	db $07, $9D, $07, $A3, $07, $A8, $07, $AD, $07, $B2, $07, $B6, $07, $BA, $07, $BE
	db $07, $C2, $07, $C5, $07, $C9, $07, $CC, $07, $CF, $07, $D2, $07, $D4, $07, $D7
	db $07, $D9, $07, $DB, $07, $DD, $07, $DF, $07, $E1, $07, $E3, $07, $E5, $07, $E6
	db $07, $E2, $07, $E9, $07, $EA, $07, $EC, $07, $ED, $07, $7C, $FE, $C3, $30, $10
	db $2E, $2A, $7E, $A7, $C8, $35, $C0, $2E, $2B, $7E, $2E, $32, $22, $36, $01, $C9
	db $2E, $11, $7E, $A7, $28, $17, $2E, $18, $35, $C0, $2C, $3A, $77, $2E, $11, $35
	db $2C, $7E, $2E, $08, $86, $FE, $0F, $38, $02, $3E, $0F, $77, $C9, $2E, $14, $7E
	db $A7, $C8, $2E, $1A, $35, $C0, $2C, $3A, $77, $2E, $14, $35, $2E, $08, $7E, $2E
	db $15, $96, $30, $01, $AF, $2E, $08, $77, $C9, $26, $C1, $18, $11, $26, $C2, $18
	db $0D, $26, $C3, $AF, $EA, $6E, $C1, $EA, $5B
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
DriverCreditText:
	db "(Music & Sound Driver (C) 1999 by Alberto Jose Gonzalez :)"

; DoEnvelope: pulse pages: count down to the 2nd hardware envelope value.
; CH3/SFX page: software envelope, attack then decay.
DoEnvelope:
	ld a, h
	cp $DE
	jr nc, SoftEnvelope
	ld l, $2A
	ld a, [hl]
	and a
	ret z
	dec [hl]
	ret nz
	ld l, $2B
	ld a, [hl]
	ld l, $32
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
PlayOnCh1:
	ld h, $DC
	jp PlayOnCh
PlayOnCh2:
	ld h, $DD
	jp PlayOnCh
PlayOnCh3:
	ld h, $DE
PlayOnCh:
	call ResetChannel
	ld l, $09
	ld [hl], $01
	ld l, $0A
	ld [hl], $01
	ld l, $27
	ld [hl], $01
	ld l, $02
	ld a, e
	ld [hli], a
	ld a, d
	ld [hl], a
	ret

; StartMusicChN (de = order list): set wInstrTable to the one instrument table (in
; all three entries, so every song plays with it; 14 bytes apart, not 4), reset
; the page, mark it active, start its first pattern. StartMusicCh3 also stops the
; fade and the drums.
StartMusicCh1:
	ld a, $5B
	ld [wInstrTableHi], a
	ld a, $2E
	ld [wInstrTable], a
	ld h, $DC
	jr StartMusicCh
StartMusicCh2:
	ld a, $5B
	ld [wInstrTableHi], a
	ld a, $2E
	ld [wInstrTable], a
	ld h, $DD
	jr StartMusicCh
StartMusicCh3:
	ld a, HIGH(InstrTable1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable1 - 2)
	ld [wInstrTable], a
	ld h, $DE
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
	cp $03
	jr nc, PlaySfxStart
	ld a, [$DF27]
	cp $03
	ret nc
	ld a, c
PlaySfxStart:
	ld [$DF27], a
	ld c, a
	ld a, $11
	ld [$DF38], a
	xor a
	ld [$DF04], a
	ld [$DF0B], a
	ld [$DF2F], a
	ld [$DF2C], a
	ld [$DF0E], a
	inc a
	ld [$DF0A], a
	ld a, $F4
	ld [$DF0D], a
	ld a, c
	ld de, $DF02
	add a, a
	add a, $A3
	ld l, a
	adc a, $5F
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
	ld [wNoiseAutoPan], a
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
	ld a, [hl]
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
	cp $35
	jp z, DrumAutoPan
	cp $36
	jp z, DrumRepeatEnd
	cp $C8
	jr nc, DrumTempo
	cp $5B
	jp nc, DrumRepeat
	cp $47
	jr nc, DrumNoiseSpeed
	cp $37
	jr nc, DrumAtten
	ld e, a
	ld a, [wDrumHold]
	and a
	ret nz
	ld a, e
	add a, a
	add a, $75
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
DrumTable:
	dw Drum11
	dw Drum12
	dw Drum4
	dw Drum4
	dw Drum5
	dw Drum6
	dw Drum7
	dw Drum8
	dw Drum12
	dw Drum10
	dw Drum11
	dw Drum12
DrumTempo:
	sub $C7
	ld [wDrumTempo], a
	ld [wDrumTimer], a
	jr DrumNextByte
DrumLoop:
	xor a
	ld [wDrumPos], a
	jr DrumRead
DrumAtten:
	sub $37
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
	sub $47
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
DrumRepeatEnd:
	ld a, [wDrumLoopCount]
	dec a
	jr z, DrumNextByte
	ld [wDrumLoopCount], a
	ld a, [wDrumLoopPos]
	jp DrumReadAt
DrumRepeat:
	sub $5A
	ld [wDrumLoopCount], a
	ld a, [wDrumPos]
	ld [wDrumLoopPos], a
	jr DrumNextByte

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
	jp z, CrowdNoise
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
	jr z, NoiseAutoPan
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
	jr z, NoiseAutoPan
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
NoiseAutoPan:
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
	xor a
	ld [wNoisePos], a
	ld [wNoiseOn], a
	ret
CrowdNoiseNR43:
	db $31, $41, $33, $51, $36, $37, $44, $45
	db $53, $54, $55, $56, $57, $64, $65, $66
CrowdNoise:
	ld a, [wCrowdLevel]
	and a
	jr nz, CrowdNoiseOn
	ld a, [wCrowdNoise]
	and a
	ret z
	xor a
	ldh [rNR43], a
	ld [wCrowdNoise], a
	jp CrowdNoiseWrite
CrowdNoiseOn:
	ldh a, [rNR43]
	ld c, a
	ld a, [wCrowdNoise]
	add a, $AE
	ld l, a
	adc a, $4C
	sub l
	ld h, a
	ld a, [hl]
	cp c
	jr z, CrowdNoiseLevel
	ldh [rNR43], a
CrowdNoiseLevel:
	ldh a, [rNR42]
	swap a
	ld c, a
	ld a, [wCrowdLevel]
	cp c
	ret z
	swap a
CrowdNoiseWrite:
	ldh [rNR42], a
	xor a
	ldh [rNR41], a
	ld a, $80
	ldh [rNR44], a
	ret

; Song 1: instrument table 1, arpeggio table 1 (the one SndInit sets)
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
	dw Pat_5157
	dw Pat_4D53
	dw Pat_4D94
	dw Pat_4D53
	dw Pat_4DCE
	dw Pat_4E0D
	dw Pat_4E4A
	dw Pat_4D53
	dw Pat_4E80
	ORDER_LOOP Song1_Ch3
Song1_Ch2:
	dw Pat_51BF
	dw Pat_5000
	dw Pat_503C
	dw Pat_5000
	dw Pat_5072
	dw Pat_50BD
	dw Pat_50F0
	dw Pat_5000
	dw Pat_5123
	ORDER_LOOP Song1_Ch2
Song1_Ch1:
	dw Pat_51F4
	dw Pat_4EBF
	dw Pat_4EEF
	dw Pat_4EBF
	dw Pat_4F25
	dw Pat_4F65
	dw Pat_4F95
	dw Pat_4EBF
	dw Pat_4FC9
	ORDER_LOOP Song1_Ch1
Pat_4D53:
	DRUMS $07, DrumPat_52FC
	LEN 21
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE D_, 2
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE D_, 2
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE D_, 2
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE D_, 2
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE A_, 2
	LEN 7
	NOTE A_, 2
	LEN 21
	NOTE E_, 2
	LEN 14
	NOTE A_, 2
	NOTE A_, 2
	LEN 7
	NOTE A_, 2
	LEN 21
	NOTE E_, 2
	LEN 7
	NOTE A_, 2
	LEN 21
	NOTE A_, 2
	LEN 7
	NOTE A_, 2
	LEN 21
	NOTE E_, 2
	LEN 14
	NOTE A_, 2
	NOTE A_, 2
	LEN 7
	NOTE A_, 2
	LEN 21
	NOTE E_, 2
	LEN 7
	NOTE A_, 2
	NEXT
Pat_4D94:
	LEN 21
	NOTE B_, 2
	LEN 7
	NOTE B_, 2
	LEN 21
	NOTE Fsh, 2
	LEN 14
	NOTE B_, 2
	NOTE B_, 2
	LEN 7
	NOTE Fsh, 2
	LEN 14
	NOTE B_, 2
	NOTE Ash, 2
	LEN 21
	NOTE A_, 2
	LEN 7
	NOTE A_, 2
	LEN 21
	NOTE E_, 2
	LEN 14
	NOTE D_, 2
	NOTE D_, 2
	LEN 7
	NOTE D_, 2
	LEN 14
	NOTE D_, 3
	NOTE D_, 2
	LEN 21
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE D_, 2
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE D_, 2
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE A_, 2
	LEN 7
	NOTE A_, 2
	LEN 21
	NOTE E_, 2
	LEN 14
	NOTE D_, 3
	NOTE D_, 3
	LEN 7
	NOTE D_, 3
	LEN 14
	NOTE A_, 2
	NOTE D_, 2
	NEXT
Pat_4DCE:
	LEN 21
	NOTE B_, 2
	LEN 7
	NOTE B_, 2
	LEN 21
	NOTE Fsh, 2
	LEN 14
	NOTE B_, 2
	NOTE B_, 2
	LEN 7
	NOTE Fsh, 2
	LEN 14
	NOTE B_, 2
	NOTE Ash, 2
	LEN 21
	NOTE A_, 2
	LEN 7
	NOTE A_, 2
	LEN 21
	NOTE E_, 2
	LEN 14
	NOTE D_, 2
	NOTE D_, 2
	LEN 7
	NOTE D_, 2
	LEN 14
	NOTE D_, 3
	NOTE D_, 2
	LEN 21
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE D_, 2
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE D_, 2
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE A_, 2
	LEN 7
	NOTE A_, 2
	NOTE D_, 2
	LEN 14
	NOTE D_, 3
	LEN 7
	NOTE D_, 3
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE E_, 2
	NOTE D_, 2
	NEXT
Pat_4E0D:
	LEN 21
	NOTE C_, 2
	LEN 7
	NOTE C_, 2
	LEN 21
	NOTE C_, 3
	LEN 14
	NOTE C_, 2
	NOTE C_, 2
	LEN 7
	NOTE C_, 2
	LEN 21
	NOTE C_, 3
	LEN 7
	NOTE C_, 2
	LEN 21
	NOTE C_, 2
	LEN 7
	NOTE C_, 2
	LEN 21
	NOTE C_, 3
	LEN 14
	NOTE C_, 2
	NOTE C_, 2
	LEN 7
	NOTE C_, 2
	LEN 21
	NOTE C_, 3
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE G_, 3
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE G_, 3
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE G_, 3
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE G_, 3
	LEN 7
	NOTE G_, 2
	NEXT
Pat_4E4A:
	LEN 21
	NOTE C_, 2
	LEN 7
	NOTE C_, 2
	LEN 21
	NOTE C_, 3
	LEN 14
	NOTE C_, 2
	NOTE C_, 2
	LEN 7
	NOTE C_, 2
	LEN 21
	NOTE C_, 3
	LEN 7
	NOTE C_, 2
	LEN 21
	NOTE C_, 2
	LEN 7
	NOTE C_, 2
	LEN 21
	NOTE C_, 3
	LEN 14
	NOTE C_, 2
	NOTE C_, 2
	LEN 7
	NOTE C_, 2
	LEN 14
	NOTE C_, 3
	LEN 7
	NOTE G_, 2
	NOTE Gsh, 2
	LEN 21
	NOTE A_, 2
	LEN 7
	NOTE A_, 2
	LEN 21
	NOTE A_, 3
	LEN 14
	NOTE A_, 2
	NOTE A_, 2
	LEN 7
	NOTE A_, 2
	LEN 14
	NOTE A_, 3
	NOTE A_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NEXT
Pat_4E80:
	LEN 21
	NOTE B_, 2
	LEN 7
	NOTE B_, 2
	LEN 21
	NOTE Fsh, 2
	LEN 14
	NOTE B_, 2
	NOTE B_, 2
	LEN 7
	NOTE Fsh, 2
	LEN 14
	NOTE B_, 2
	NOTE Ash, 2
	LEN 21
	NOTE A_, 2
	LEN 7
	NOTE A_, 2
	LEN 21
	NOTE E_, 2
	LEN 14
	NOTE D_, 2
	NOTE D_, 2
	LEN 7
	NOTE D_, 2
	LEN 14
	NOTE D_, 3
	NOTE D_, 2
	LEN 21
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE D_, 2
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE D_, 2
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE A_, 2
	LEN 7
	NOTE A_, 2
	NOTE D_, 2
	LEN 14
	NOTE D_, 3
	LEN 7
	NOTE D_, 3
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE E_, 2
	NOTE D_, 2
	NEXT
Pat_4EBF:
	INSTR 6
	LENGTH $3F
	NOTE Fsh, 4
	INSTR 9
	LEN 7
	NOTE A_, 4
	NOTE G_, 4
	LEN 14
	NOTE Fsh, 4
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE B_, 3
	NOTE D_, 4
	INSTR 6
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	LEN 21
	NOTE Fsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE E_, 4
	LENGTH $3F
	NOTE G_, 4
	INSTR 9
	LEN 7
	NOTE D_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 14
	NOTE A_, 4
	INSTR 6
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	LEN 21
	NOTE G_, 4
	NOTE E_, 4
	LEN 14
	NOTE Fsh, 4
	NEXT
Pat_4EEF:
	INSTR 6
	LENGTH $46
	NOTE A_, 4
	GLISS_3
	LEN 14
	NOTE Fsh, 4
	NOTE D_, 5
	NOTE Csh, 5
	LEN 21
	NOTE C_, 5
	NOTE Dsh, 4
	LEN 14
	NOTE E_, 4
	LEN 21
	NOTE B_, 4
	NOTE A_, 4
	LEN 14
	NOTE Fsh, 4
	LEN 21
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	DUTY_12
	HWENV $90, $00
	RELEASE $02, $51
	LEN 7
	NOTE D_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 21
	NOTE A_, 4
	NOTE E_, 4
	NOTE D_, 5
	LEN 7
	NOTE B_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE D_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE E_, 4
	RELEASE $00
	GLISS_OFF
	NEXT
Pat_4F25:
	INSTR 6
	LENGTH $46
	GLISS_3
	NOTE A_, 4
	LEN 14
	NOTE Fsh, 4
	NOTE D_, 5
	NOTE Csh, 5
	LEN 21
	NOTE C_, 5
	NOTE Dsh, 4
	LEN 14
	NOTE E_, 4
	LEN 21
	NOTE B_, 4
	NOTE A_, 4
	LEN 14
	NOTE Fsh, 4
	LEN 21
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	DUTY_12
	HWENV $90, $00
	RELEASE $02, $51
	LEN 7
	NOTE D_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE A_, 4
	LEN 21
	NOTE A_, 4
	LEN 14
	NOTE D_, 5
	LEN 7
	NOTE D_, 5
	LEN 14
	NOTE G_, 5
	LEN 28
	REST
	RELEASE $00
	GLISS_OFF
	INSTR 6
	DUTY_75
	HWENV $90, $00
	RELEASE $07, $72
	LEN 14
	NOTE G_, 4
	NEXT
Pat_4F65:
	GLISS_3
	LEN 21
	NOTE E_, 5
	NOTE C_, 5
	LEN 14
	NOTE G_, 4
	LEN 21
	NOTE E_, 5
	NOTE C_, 5
	LEN 28
	NOTE G_, 4
	LEN 7
	NOTE E_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	LEN 14
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	LEN 7
	NOTE G_, 5
	LEN 14
	NOTE Fsh, 5
	NOTE E_, 5
	LEN 21
	NOTE D_, 5
	NOTE B_, 4
	LEN 14
	NOTE G_, 4
	LEN 21
	NOTE D_, 5
	NOTE B_, 4
	LEN 28
	NOTE G_, 4
	LEN 7
	NOTE E_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	LEN 14
	NOTE G_, 5
	NOTE G_, 5
	LEN 7
	NOTE Fsh, 5
	LEN 14
	NOTE E_, 5
	NOTE D_, 5
	NOTE G_, 4
	NEXT
Pat_4F95:
	LEN 21
	NOTE E_, 5
	NOTE C_, 5
	LEN 14
	NOTE G_, 4
	LEN 21
	NOTE E_, 5
	NOTE C_, 5
	LEN 28
	NOTE G_, 4
	LEN 7
	NOTE E_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	LEN 14
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	LEN 7
	NOTE G_, 5
	LEN 14
	NOTE Fsh, 5
	NOTE E_, 5
	LEN 21
	NOTE E_, 5
	NOTE Csh, 5
	LEN 14
	NOTE A_, 4
	LEN 21
	NOTE E_, 5
	NOTE Csh, 5
	LEN 14
	NOTE A_, 4
	NOTE G_, 5
	LEN 7
	NOTE A_, 5
	LEN 14
	NOTE G_, 5
	LEN 7
	NOTE Fsh, 5
	LEN 14
	NOTE E_, 5
	LEN 42
	NOTE D_, 5
	LEN 7
	RELEASE $00
	GLISS_OFF
	INSTR 6
	NOTE D_, 4
	NOTE E_, 4
	NEXT
Pat_4FC9:
	INSTR 6
	LENGTH $46
	NOTE A_, 4
	GLISS_3
	LEN 14
	NOTE Fsh, 4
	NOTE D_, 5
	NOTE Csh, 5
	LEN 21
	NOTE C_, 5
	NOTE Dsh, 4
	LEN 14
	NOTE E_, 4
	LEN 28
	NOTE B_, 4
	LEN 21
	NOTE B_, 4
	LEN 7
	NOTE A_, 4
	LENGTH $3F
	NOTE G_, 4
	DUTY_12
	HWENV $90, $00
	RELEASE $02, $51
	LEN 7
	NOTE D_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE A_, 4
	LEN 21
	NOTE A_, 4
	LEN 14
	NOTE D_, 5
	LEN 7
	NOTE D_, 5
	LENGTH $15
	NOTE G_, 5
	LEN 35
	REST
	RELEASE $00
	GLISS_OFF
	NEXT
Pat_5000:
	HWENV $A1, $0E, $52
	AUTODUTY $07
	CH_TRANSPOSE $00
	ARP 4
	LEN 14
	NOTE G_, 4
	LEN 21
	NOTE G_, 5
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 21
	NOTE G_, 5
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	ARP 5
	NOTE A_, 4
	LEN 21
	NOTE A_, 5
	LEN 14
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	LEN 21
	NOTE A_, 5
	LEN 14
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE A_, 4
	NOTE A_, 4
	NEXT
Pat_503C:
	ARP 5
	LEN 14
	NOTE B_, 4
	LEN 21
	NOTE B_, 5
	LEN 14
	NOTE B_, 4
	NOTE B_, 4
	NOTE B_, 4
	LEN 7
	NOTE B_, 4
	LEN 14
	NOTE B_, 4
	NOTE Ash, 4
	NOTE A_, 4
	LEN 21
	NOTE A_, 5
	LEN 14
	NOTE A_, 4
	ARP 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 7
	NOTE Gsh, 4
	LEN 14
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 21
	NOTE G_, 5
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	ARP 5
	NOTE A_, 4
	LEN 21
	NOTE A_, 5
	LEN 14
	NOTE A_, 4
	ARP 4
	NOTE D_, 5
	NOTE D_, 5
	LEN 7
	NOTE D_, 5
	LEN 14
	NOTE D_, 5
	NOTE D_, 5
	NEXT
Pat_5072:
	ARP 5
	LEN 14
	NOTE B_, 4
	LEN 21
	NOTE B_, 5
	LEN 14
	NOTE B_, 4
	NOTE B_, 4
	NOTE B_, 4
	LEN 7
	NOTE B_, 4
	LEN 14
	NOTE B_, 4
	NOTE Ash, 4
	NOTE A_, 4
	LEN 21
	NOTE A_, 5
	LEN 14
	NOTE A_, 4
	ARP 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 7
	NOTE Gsh, 4
	LEN 14
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 21
	NOTE G_, 5
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	ARP 5
	NOTE A_, 4
	LEN 21
	NOTE A_, 5
	ARP 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	NOTE G_, 4
Pat_50A3:
	AUTODUTY $00
	DUTY_50
	GLIDE $FF
	HWENV $C1, $00
	ARP_OFF
	LEN 14
	NOTE E_, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE Csh, 4
	LEN 7
	NOTE B_, 3
	NOTE A_, 3
	HWENV $A1, $0E, $52
	AUTODUTY $07
	GLIDE_OFF
	NEXT
Pat_50BD:
	ARP 4
	LEN 14
	NOTE C_, 5
	LEN 21
	NOTE C_, 6
	LEN 14
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	LEN 21
	NOTE C_, 6
	LEN 14
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE C_, 5
	NOTE C_, 5
	NOTE G_, 4
	LEN 21
	NOTE G_, 5
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 21
	NOTE G_, 5
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NEXT
Pat_50F0:
	ARP 4
	LEN 14
	NOTE C_, 5
	LEN 21
	NOTE C_, 6
	LEN 14
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	LEN 21
	NOTE C_, 6
	LEN 14
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE C_, 5
	NOTE C_, 5
	NOTE A_, 4
	LEN 21
	NOTE A_, 5
	LEN 14
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE A_, 4
	NOTE A_, 4
	NOTE D_, 5
	LEN 21
	NOTE D_, 6
	LEN 14
	NOTE D_, 5
	NOTE D_, 5
	LEN 7
	NOTE D_, 5
	LEN 14
	NOTE D_, 5
	NOTE D_, 5
	NOTE D_, 5
	NEXT
Pat_5123:
	ARP 5
	LEN 14
	NOTE B_, 4
	LEN 21
	NOTE B_, 5
	LEN 14
	NOTE B_, 4
	NOTE B_, 4
	NOTE B_, 4
	LEN 7
	NOTE B_, 4
	LEN 14
	NOTE B_, 4
	NOTE Ash, 4
	NOTE A_, 4
	LEN 21
	NOTE A_, 5
	LEN 14
	NOTE A_, 4
	ARP 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 7
	NOTE Gsh, 4
	LEN 14
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 21
	NOTE G_, 5
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	ARP 5
	NOTE A_, 4
	LEN 21
	NOTE A_, 5
	ARP 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	NOTE G_, 4
	PAT_GOTO Pat_50A3
Pat_5157:
	CH_TRANSPOSE $0C
	TRANSPOSE $00
	DRUMS $07, DrumPat_52CA
	VOLENV 12, $11, $1F, $13
	RELEASE $01, $11
	LEN 7
	WAVE Wave_6138
	REPEAT 2
	NOTE G_, 2
	WAIT
	WAIT
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	WAIT
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	WAIT
	NOTE G_, 2
	REPEAT_END
	TRANSPOSE $FE
	REPEAT 2
	NOTE G_, 2
	WAIT
	WAIT
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	WAIT
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	WAIT
	NOTE G_, 2
	REPEAT_END
	DRUMS $07, DrumPat_52DB
	TRANSPOSE $FD
	REPEAT 2
	NOTE G_, 2
	WAIT
	WAIT
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	WAIT
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	WAIT
	NOTE G_, 2
	REPEAT_END
	DRUMS $0E, DrumPat_531F
	REPEAT 2
	NOTE G_, 2
	WAIT
	WAIT
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	WAIT
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	WAIT
	NOTE G_, 2
	REPEAT_END
	NEXT
Pat_51BF:
	LEN 7
	HWENV $D1, $01, $24
	DUTY_50
	ARP 4
	CH_TRANSPOSE $FB
	AUTODUTY $00
	REPEAT 4
	NOTE C_, 6
	WAIT
	NOTE C_, 6
	WAIT
	NOTE C_, 7
	NOTE C_, 6
	WAIT
	NOTE C_, 6
	WAIT
	NOTE C_, 6
	WAIT
	NOTE C_, 6
	WAIT
	NOTE C_, 7
	NOTE C_, 6
	NOTE C_, 6
	REPEAT_END
	HWENV $C1, $0E, $52
	DUTY_50
	REPEAT 4
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	WAIT
	WAIT
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	WAIT
	REPEAT_END
	NEXT
Pat_51F4:
	DUTY_75
	LEN 7
	ARP 0
	CH_TRANSPOSE $00
	AUTODUTY $00
	HWENV $30, $00
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	HWENV $40, $00
	NOTE B_, 3
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	HWENV $50, $00
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE D_, 4
	HWENV $60, $00
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	HWENV $70, $00
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	HWENV $80, $00
	NOTE B_, 3
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	HWENV $90, $00
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE D_, 4
	HWENV $A0, $00
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	ARP 7
	HWENV $A0, $00
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	HWENV $90, $00
	NOTE B_, 3
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	HWENV $80, $00
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE D_, 4
	HWENV $70, $00
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	HWENV $60, $00
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	HWENV $50, $00
	NOTE B_, 3
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	HWENV $40, $00
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE D_, 4
	HWENV $30, $00
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	ARP 7
	CH_TRANSPOSE $0C
	AUTODUTY $07
	HWENV $30, $00
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	HWENV $40, $00
	NOTE B_, 3
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	HWENV $50, $00
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE D_, 4
	HWENV $60, $00
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	HWENV $70, $00
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	HWENV $80, $00
	NOTE B_, 3
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	HWENV $90, $00
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE D_, 4
	HWENV $A0, $00
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	VIBRATO $07, $01, $04
	AUTODUTY $00
	DUTY_12
	ARP_OFF
	HWENV $70, $00
	GLISS_3
	LEN 21
	NOTE D_, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE B_, 4
	LEN 14
	NOTE D_, 4
	NOTE B_, 3
	LEN 21
	NOTE D_, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE A_, 5
	LEN 14
	NOTE D_, 5
	GLISS_OFF
	LEN 7
	INSTR 6
	NOTE D_, 4
	NOTE E_, 4
	NEXT
DrumPat_52CA:
	db 11, 6, 4, 11, 11, 0, 4, 11
	db 11, 6, 4, 11, 11, 6, 12, 6
	db DRUM_LOOP
DrumPat_52DB:
	db 11, 6, 4, 11, 12, 6, 4, 11
	db 11, 6, 4, 11, 12, 6, 4, 0
	db 11, 6, 4, 11, 12, 6, 4, 11
	db 11, 12, 4, 11, 12, 6, 12, 12
	db DRUM_LOOP
DrumPat_52FC:
	db DRUM_REPEAT + 7, 11, 6, 4, 11, 12, 6, 4
	db 11, 11, 6, 4, 11, 12, 6, 4
	db 0, DRUM_REPEAT_END, 11, 6, 4, 11, 12, 6
	db 4, 11, 11, 12, 4, 12, 12, 6
	db 12, 12, DRUM_LOOP
DrumPat_531F:
	db 7, 0, 5, 0, 5, 0, 5, 0
	db 5, 0, 5, 0, 5, 0, DRUM_TEMPO + 7, 5
	db 11, 12, 0, DRUM_LOOP

; Song 2: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong2:
	call StopAll
	ld de, Song2_Ch3
	call StartMusicCh3
	ld de, Song2_Ch2
	call StartMusicCh2
	ld de, Song2_Ch1
	jp StartMusicCh1
Song2_Ch3:
	dw Pat_535A

; Unreferenced (4 bytes)
	db $00, $00, $48, $53
Song2_Ch2:
	dw Pat_53A9

; Unreferenced (4 bytes)
	db $00, $00, $4E, $53
Song2_Ch1:
	dw Pat_5405

; Unreferenced (4 bytes)
	db $00, $00, $54, $53
Pat_535A:
	CH_TRANSPOSE $0C
	TRANSPOSE $01
	INSTR 11
	VOLENV 15, $11, $1F, $13
	LEN 21
	NOTE G_, 2
	LEN 7
	NOTE D_, 2
	LEN 21
	NOTE D_, 2
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE G_, 2
	LEN 7
	NOTE D_, 2
	LEN 21
	NOTE D_, 2
	LEN 7
	NOTE A_, 2
	LEN 21
	NOTE A_, 2
	LEN 7
	NOTE D_, 2
	LEN 21
	NOTE D_, 2
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE G_, 2
	LEN 7
	NOTE D_, 2
	LEN 21
	NOTE D_, 2
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE G_, 2
	LEN 7
	NOTE D_, 2
	LEN 21
	NOTE D_, 2
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE G_, 2
	LEN 7
	NOTE D_, 2
	LEN 21
	NOTE D_, 2
	LEN 7
	NOTE D_, 3
	LEN 21
	NOTE D_, 3
	LEN 7
	NOTE D_, 2
	LEN 21
	NOTE D_, 2
	LEN 14
	NOTE G_, 2
	DRUMS $07, DrumPat_545B
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	RELEASE $00
	NOTE G_, 3
	DRUMS_OFF
	LEN 21
	WAIT
	END
Pat_53A9:
	INSTR 8
	LEN 14
	NOTE B_, 6
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 8
	LEN 14
	NOTE B_, 6
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 8
	LEN 21
	NOTE B_, 6
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 8
	LEN 14
	NOTE B_, 6
	NOTE B_, 6
	INSTR 4
	NOTE G_, 4
	INSTR 8
	NOTE B_, 6
	INSTR 4
	LEN 7
	NOTE D_, 4
	INSTR 8
	LEN 14
	NOTE B_, 6
	INSTR 4
	LEN 7
	NOTE D_, 4
	INSTR 8
	LEN 21
	NOTE B_, 6
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 8
	LEN 14
	NOTE B_, 6
	NOTE B_, 6
	INSTR 4
	NOTE G_, 4
	INSTR 8
	NOTE B_, 6
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 8
	LEN 14
	NOTE B_, 6
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 8
	LEN 21
	NOTE B_, 6
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 8
	LEN 14
	NOTE B_, 6
	NOTE B_, 6
	INSTR 4
	NOTE G_, 4
	INSTR 8
	NOTE B_, 6
	INSTR 4
	LEN 7
	NOTE D_, 4
	INSTR 8
	LEN 14
	NOTE B_, 6
	INSTR 4
	LEN 7
	NOTE D_, 4
	INSTR 8
	LEN 21
	NOTE B_, 6
	INSTR 4
	LEN 14
	NOTE G_, 5
	LEN 7
	NOTE G_, 5
	LEN 28
	NOTE G_, 5
	END
Pat_5405:
	DRUMS $07, DrumPat_5455
	HWENV $A0, $03, $A0
	RELEASE $02, $81
	DUTY_50
	LEN 14
	NOTE B_, 5
	GLISS_1
	LEN 7
	NOTE A_, 5
	LEN 14
	NOTE B_, 5
	NOTE C_, 6
	NOTE D_, 6
	NOTE C_, 6
	LEN 7
	NOTE B_, 5
	LEN 14
	NOTE A_, 5
	NOTE G_, 5
	GLISS_3
	NOTE Fsh, 5
	LEN 7
	NOTE D_, 6
	LEN 14
	NOTE E_, 5
	NOTE C_, 6
	NOTE D_, 5
	NOTE B_, 5
	LEN 7
	NOTE G_, 5
	LEN 14
	NOTE D_, 5
	INSTR 13
	DUTY_50
	GLISS_OFF
	LEN 7
	NOTE B_, 3
	GLISS_2
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE Csh, 4
	LEN 14
	NOTE E_, 4
	NOTE D_, 4
	NOTE G_, 4
	LEN 7
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE D_, 5
	WAIT2
	NOTE D_, 5
	NOTE D_, 5
	WAIT2
	NOTE D_, 5
	NOTE G_, 4
	WAIT2
	NOTE B_, 4
	WAIT2
	NOTE D_, 5
	LEN 21
	NOTE G_, 5
	LEN 7
	WAIT2
	END
DrumPat_5455:
	db 1, 6, 2, 2, DRUM_LOOP

; Unreferenced (1 bytes)
	db $FF
DrumPat_545B:
	db 2, 6, 2, 7, 0, 0                 ; no DRUM_LOOP: the pattern runs into the next data

; Song 3: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong3:
	call StopAll
	ld de, Song3_Ch3
	call StartMusicCh3
	ld de, Song3_Ch2
	call StartMusicCh2
	ld de, Song3_Ch1
	jp StartMusicCh1
Song3_Ch3:
	dw Pat_5488

; Unreferenced (4 bytes)
	db $00, $00, $76, $54
Song3_Ch2:
	dw Pat_54DC

; Unreferenced (4 bytes)
	db $00, $00, $7C, $54
Song3_Ch1:
	dw Pat_551E

; Unreferenced (4 bytes)
	db $00, $00, $82, $54
Pat_5488:
	DRUMS $09, DrumPat_5555
	TRANSPOSE $03
	VOLENV 12, $11, $1F, $13
	CH_TRANSPOSE $0C
	WAVE Wave_6138
	INSTR 12
	LEN 18
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 3
	LEN 9
	NOTE B_, 3
	LEN 27
	NOTE E_, 2
	LEN 18
	NOTE E_, 2
	LEN 9
	NOTE E_, 3
	NOTE B_, 2
	NOTE E_, 2
	NOTE Dsh, 2
	LEN 18
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	LEN 9
	NOTE A_, 3
	LEN 27
	NOTE D_, 2
	LEN 18
	NOTE D_, 2
	LEN 9
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	LEN 18
	NOTE C_, 3
	NOTE C_, 3
	LEN 9
	NOTE C_, 4
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	LEN 18
	NOTE D_, 3
	LEN 9
	NOTE C_, 3
	LEN 18
	NOTE D_, 3
	LEN 9
	NOTE A_, 2
	NOTE Fsh, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	LEN 18
	NOTE E_, 2
	LEN 9
	DRUMS $09, DrumPat_5566
	NOTE E_, 2
	NOTE E_, 2
	RELEASE $00
	NOTE E_, 2
	DRUMS_OFF
	LENGTH $48
	NOTE E_, 2
	END
Pat_54DC:
	HWENV $D1, $09, $46
	DUTY_50
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE Gsh, 3
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE Gsh, 3
	LEN 18
	NOTE E_, 4
	NOTE E_, 3
	NOTE B_, 3
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE D_, 4
	LEN 9
	NOTE Fsh, 3
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE Fsh, 3
	LEN 18
	NOTE D_, 4
	NOTE D_, 3
	NOTE A_, 3
	NOTE D_, 4
	LEN 9
	NOTE Gsh, 4
	NOTE D_, 4
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE E_, 4
	LEN 18
	NOTE C_, 4
	NOTE D_, 4
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE D_, 4
	LEN 18
	NOTE A_, 3
	LEN 9
	NOTE B_, 3
	NOTE B_, 3
	NOTE B_, 3
	LEN 18
	NOTE A_, 3
	LEN 9
	NOTE A_, 3
	NOTE A_, 3
	LENGTH $51
	NOTE Gsh, 3
	END
Pat_551E:
	HWENV $D1, $09, $46
	DUTY_50
	LEN 27
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 18
	NOTE Gsh, 3
	NOTE E_, 4
	NOTE B_, 4
	LEN 9
	NOTE Gsh, 4
	LEN 27
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	LEN 18
	NOTE Fsh, 3
	LEN 9
	NOTE D_, 4
	NOTE Fsh, 4
	LEN 18
	NOTE A_, 4
	LEN 9
	NOTE Fsh, 4
	LEN 27
	NOTE E_, 4
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE G_, 4
	LEN 18
	NOTE E_, 4
	LEN 27
	NOTE Fsh, 4
	LEN 18
	NOTE G_, 4
	NOTE Fsh, 4
	LEN 9
	NOTE Fsh, 3
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE E_, 4
	NOTE E_, 4
	LENGTH $51
	NOTE E_, 4
	END
DrumPat_5555:
	db 1, 5, 6, 1, 2, 6, 1, 1
	db 5, 4, 6, 1, 2, 6, 1, 6
	db DRUM_LOOP
DrumPat_5566:
	db 1, 1, 7, 0                       ; no DRUM_LOOP: the pattern runs into the next data

; Song 4: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong4:
	call StopAll
	ld de, Song4_Ch3
	call StartMusicCh3
	ld de, Song4_Ch2
	call StartMusicCh2
	ld de, Song4_Ch1
	jp StartMusicCh1
Song4_Ch3:
	dw Pat_55C9
	dw Pat_55C9
	dw Pat_5607
	dw Pat_5607
	dw Pat_5607
	dw Pat_5607
	dw Pat_5607
	dw Pat_5607
	ORDER_LOOP Song4_Ch3
Song4_Ch2:
	dw Pat_5652
	dw Pat_5652
	dw Pat_5652
	dw Pat_5652
	dw Pat_5679
	dw Pat_5679
	dw Pat_5679
	dw Pat_5679
	ORDER_LOOP Song4_Ch2
Song4_Ch1:
	dw Pat_55C3
	dw Pat_569F
	dw Pat_569F
	dw Pat_55C6
	dw Pat_56B6
	dw Pat_56B6
	dw Pat_55C3
	dw Pat_56CE
	dw Pat_56CE
	dw Pat_55C6
	dw Pat_56B6
	dw Pat_56B6
	ORDER_LOOP Song4_Ch1
Pat_55C3:
	TRANSPOSE $04
	NEXT
Pat_55C6:
	TRANSPOSE $06
	NEXT
Pat_55C9:
	CH_TRANSPOSE $0C
	VOLENV 15, $11, $1F, $13
	ARP 6
	RELEASE $02, $11
	WAVE Wave_6018
	LEN 28
	NOTE G_, 1
	LEN 21
	NOTE G_, 1
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE F_, 2
	NOTE Ash, 2
	NOTE F_, 2
	LEN 28
	NOTE G_, 1
	LEN 21
	NOTE G_, 1
	LEN 7
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE F_, 2
	NOTE D_, 2
	NOTE C_, 2
	LEN 28
	NOTE G_, 1
	LEN 21
	NOTE G_, 1
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE F_, 2
	NOTE Ash, 2
	NOTE F_, 2
	LEN 28
	NOTE G_, 1
	LEN 21
	NOTE G_, 1
	LEN 14
	NOTE C_, 3
	LEN 7
	NOTE C_, 3
	LEN 14
	NOTE Ash, 2
	NOTE G_, 2
	NOTE F_, 2
	NEXT
Pat_5607:
	LEN 28
	NOTE G_, 1
	LEN 21
	ARP 3
	NOTE F_, 2
	ARP 6
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE F_, 2
	NOTE Ash, 2
	NOTE F_, 2
	LEN 28
	NOTE G_, 1
	LEN 21
	ARP 3
	NOTE F_, 2
	ARP 6
	LEN 7
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE F_, 2
	NOTE D_, 2
	NOTE C_, 2
	LEN 28
	NOTE G_, 1
	LEN 21
	ARP 3
	NOTE F_, 2
	ARP 6
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE F_, 2
	NOTE Ash, 2
	NOTE F_, 2
	LEN 28
	NOTE G_, 1
	LEN 21
	ARP 3
	NOTE F_, 2
	ARP 6
	LEN 14
	NOTE C_, 3
	LEN 7
	NOTE C_, 3
	LEN 14
	NOTE Ash, 2
	NOTE G_, 2
	RELEASE $00
	LEN 4
	VOLENV 15, $00, $00, $00
	NOTE F_, 2
	ARP 3
	LEN 10
	RELEASE $02, $11
	NOTE F_, 2
	VOLENV 15, $11, $1F, $13
	ARP 6
	NEXT
Pat_5652:
	LEN 14
	REPEAT 3
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE G_, 3
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE G_, 3
	REPEAT_END
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE G_, 3
	INSTR 2
	NOTE G_, 3
	NOTE G_, 3
	REPEAT 3
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE G_, 3
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE G_, 3
	REPEAT_END
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE G_, 3
	INSTR 2
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NEXT
Pat_5679:
	REPEAT 3
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE G_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 4
	NOTE G_, 3
	REPEAT_END
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE G_, 3
	INSTR 2
	NOTE D_, 4
	NOTE G_, 3
	REPEAT 3
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE G_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 4
	NOTE G_, 3
	REPEAT_END
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 2
	NOTE D_, 4
	LEN 7
	NOTE G_, 3
	NOTE D_, 4
	LEN 14
	NEXT
Pat_569F:
	DRUMS $07, DrumPat_5756
	ARP 0
	HWENV $F1, $00
	DUTY_75
	RELEASE $00
	LEN 14
	REPEAT 4
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	LEN 28
	NOTE G_, 3
	WAIT
	LEN 14
	WAIT
	REPEAT_END
	NEXT
Pat_56B6:
	CH_TRANSPOSE $00
	HWENV $5A, $0E, $D7
	AUTODUTY $07
	ARP 2
	LENGTH $70
	NOTE G_, 3
	LENGTH $38
	NOTE Ash, 3
	NOTE A_, 3
	LENGTH $70
	NOTE G_, 3
	LENGTH $38
	NOTE Ash, 3
	NOTE C_, 4
	NEXT
Pat_56CE:
	DRUMS $07, DrumPat_579B
	AUTODUTY $07
	AUTOPAN $07
	CH_TRANSPOSE $0C
	INSTR 13
	LEN 7
	NOTE G_, 3
	INSTR 10
	NOTE D_, 4
	INSTR 13
	NOTE G_, 4
	INSTR 10
	NOTE G_, 3
	INSTR 13
	NOTE G_, 3
	INSTR 10
	NOTE G_, 4
	INSTR 13
	NOTE G_, 4
	NOTE F_, 4
	INSTR 10
	NOTE G_, 4
	INSTR 13
	NOTE F_, 4
	NOTE E_, 4
	INSTR 10
	NOTE F_, 4
	INSTR 13
	NOTE D_, 4
	INSTR 10
	NOTE E_, 4
	INSTR 13
	NOTE F_, 4
	INSTR 10
	NOTE D_, 4
	INSTR 13
	NOTE G_, 3
	INSTR 10
	NOTE F_, 4
	INSTR 13
	NOTE G_, 4
	INSTR 10
	NOTE F_, 4
	INSTR 13
	NOTE G_, 3
	INSTR 10
	NOTE G_, 4
	INSTR 13
	NOTE G_, 4
	NOTE F_, 4
	INSTR 10
	NOTE G_, 4
	INSTR 13
	NOTE F_, 4
	NOTE E_, 4
	INSTR 10
	NOTE G_, 4
	INSTR 13
	NOTE D_, 4
	INSTR 10
	NOTE E_, 4
	INSTR 13
	NOTE Ash, 3
	NOTE A_, 3
	NOTE G_, 3
	INSTR 10
	NOTE Ash, 3
	INSTR 13
	NOTE G_, 4
	INSTR 10
	NOTE G_, 3
	INSTR 13
	NOTE G_, 3
	INSTR 10
	NOTE G_, 4
	INSTR 13
	NOTE G_, 4
	NOTE F_, 4
	INSTR 10
	NOTE G_, 4
	INSTR 13
	NOTE F_, 4
	NOTE E_, 4
	INSTR 10
	NOTE G_, 4
	INSTR 13
	NOTE D_, 4
	INSTR 10
	NOTE F_, 4
	INSTR 13
	NOTE F_, 4
	INSTR 10
	NOTE D_, 4
	INSTR 13
	NOTE G_, 3
	INSTR 10
	NOTE F_, 4
	INSTR 13
	NOTE G_, 4
	INSTR 10
	NOTE G_, 3
	INSTR 13
	NOTE G_, 3
	INSTR 10
	NOTE G_, 4
	INSTR 13
	NOTE G_, 4
	NOTE C_, 5
	INSTR 10
	NOTE G_, 4
	INSTR 13
	NOTE C_, 5
	NOTE Ash, 4
	INSTR 10
	NOTE C_, 5
	INSTR 13
	NOTE F_, 4
	INSTR 10
	NOTE Ash, 4
	INSTR 13
	NOTE D_, 4
	INSTR 10
	NOTE F_, 4
	AUTOPAN $00
	AUTODUTY $00
	CH_TRANSPOSE $00
	NEXT
DrumPat_5756:
	db DRUM_AUTOPAN, $01, 7, 0, 0, 0, DRUM_AUTOPAN, $00
	db 4, 0, 6, 6, 1, 0, 6, 0
	db 4, 0, 6, 0, 1, 0, 6, 0
	db 4, 0, 6, 6, 1, 0, 6, 0
	db 4, 0, 4, 0, 1, 0, 6, 0
	db 4, 0, 6, 6, 1, 0, 6, 0
	db 4, 0, 6, 0, 1, 0, 6, 0
	db 4, 0, 6, 6, 1, 0, 6, 0
	db 4, 0, 4, 1, DRUM_LOOP
DrumPat_579B:
	db DRUM_AUTOPAN, $01, 7, 0, DRUM_AUTOPAN, $00, 5, 6
	db 9, 0, 5, 6, 1, 6, 5, 6
	db 9, 0, 5, 6, 1, 0, 5, 6
	db 9, 0, 5, 6, 1, 0, 5, 6
	db 9, 0, 1, 6, 1, 0, 5, 6
	db 9, 0, 5, 6, 1, 0, 5, 6
	db 9, 0, 5, 6, 1, 0, 5, 6
	db 9, 0, 5, 6, 1, 0, 5, 6
	db 9, 0, 1, 9, DRUM_LOOP

; Song 5: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong5:
	call StopAll
	ld de, Song5_Ch3
	call StartMusicCh3
	ld de, Song5_Ch2
	call StartMusicCh2
	ld de, Song5_Ch1
	jp StartMusicCh1
Song5_Ch3:
	dw Pat_583F
	dw Pat_583F
	dw Pat_5871
	dw Pat_5871
	dw Pat_5898
	dw Pat_5898
	dw Pat_5871
	dw Pat_5898
	dw Pat_5898
	dw Pat_5871
	dw Pat_5871
	ORDER_LOOP Song5_Ch3
Song5_Ch2:
	dw Pat_58BA
	dw Pat_58BA
	dw Pat_58EB
	dw Pat_58EB
	dw Pat_5925
	dw Pat_5925
	dw Pat_58EB
	dw Pat_5925
	dw Pat_5925
	dw Pat_58EB
	dw Pat_58EB
	ORDER_LOOP Song5_Ch2
Song5_Ch1:
	dw Pat_595F
	dw Pat_595F
	dw Pat_5971
	dw Pat_59AD
	dw Pat_59C6
	dw Pat_5A13
	dw Pat_59C6
	dw Pat_5A13
	dw Pat_59AD
	ORDER_LOOP Song5_Ch1
Pat_583F:
	CH_TRANSPOSE $0C
	TRANSPOSE $02
	INSTR 11
	RELEASE $01, $11
	LEN 10
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	LEN 5
	NOTE C_, 3
	NOTE F_, 3
	LEN 10
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	LEN 5
	NOTE Ash, 2
	NOTE C_, 3
	NOTE Ash, 2
	NOTE Gsh, 2
	NOTE Ash, 2
	NOTE Gsh, 2
	NOTE F_, 2
	NOTE Dsh, 2
	NEXT
Pat_5871:
	LEN 10
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	LEN 5
	NOTE F_, 2
	NOTE F_, 3
	LEN 10
	NOTE Ash, 1
	NOTE Ash, 2
	NOTE Ash, 1
	NOTE Ash, 2
	NOTE Ash, 1
	NOTE Ash, 2
	NOTE Ash, 1
	NOTE Ash, 2
	NOTE Ash, 1
	NOTE Ash, 2
	NOTE Ash, 1
	NOTE Ash, 2
	NOTE Ash, 1
	NOTE Ash, 2
	NOTE Ash, 1
	LEN 5
	NOTE Ash, 2
	NOTE Ash, 3
	NEXT
Pat_5898:
	LEN 10
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE F_, 1
	NOTE F_, 2
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Ash, 1
	NOTE Ash, 2
	NOTE Ash, 1
	NOTE Ash, 2
	NOTE Ash, 1
	NOTE Ash, 2
	NOTE Ash, 1
	NOTE Ash, 2
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NEXT
Pat_58BA:
	INSTR 0
	HWENV $F1, $9C, $71
	GLIDE $FE
	LEN 20
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	LEN 20
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	LEN 20
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	LEN 20
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	LEN 20
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	LEN 20
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	LEN 20
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	LEN 20
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	LEN 20
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	LEN 5
	NOTE A_, 3
	NOTE A_, 3
	NEXT
Pat_58EB:
	INSTR 4
	LEN 20
	NOTE F_, 4
	INSTR 0
	LEN 10
	NOTE A_, 3
	INSTR 4
	LEN 20
	NOTE F_, 4
	LEN 10
	NOTE F_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 4
	NOTE F_, 4
	LEN 20
	NOTE F_, 4
	INSTR 0
	LEN 10
	NOTE A_, 3
	INSTR 4
	LEN 20
	NOTE F_, 4
	LEN 10
	NOTE F_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 4
	NOTE F_, 4
	LEN 20
	NOTE Ash, 3
	INSTR 0
	LEN 10
	NOTE A_, 3
	INSTR 4
	LEN 20
	NOTE Ash, 3
	LEN 10
	NOTE Ash, 3
	INSTR 0
	NOTE A_, 3
	INSTR 4
	NOTE Ash, 3
	LEN 20
	NOTE Ash, 3
	INSTR 0
	LEN 10
	NOTE A_, 3
	INSTR 4
	LEN 20
	NOTE Ash, 3
	LEN 10
	NOTE Ash, 3
	INSTR 0
	NOTE A_, 3
	INSTR 4
	NOTE Ash, 3
	NEXT
Pat_5925:
	INSTR 4
	LEN 20
	NOTE F_, 4
	INSTR 0
	LEN 10
	NOTE A_, 3
	INSTR 4
	LEN 20
	NOTE F_, 4
	LEN 10
	NOTE F_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 4
	NOTE F_, 4
	LEN 20
	NOTE C_, 4
	INSTR 0
	LEN 10
	NOTE A_, 3
	INSTR 4
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE C_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 4
	NOTE C_, 4
	LEN 20
	NOTE Ash, 3
	INSTR 0
	LEN 10
	NOTE A_, 3
	INSTR 4
	LEN 20
	NOTE Ash, 3
	LEN 10
	NOTE Ash, 3
	INSTR 0
	NOTE A_, 3
	INSTR 4
	NOTE Ash, 3
	LEN 20
	NOTE Csh, 4
	INSTR 0
	LEN 10
	NOTE A_, 3
	INSTR 4
	LEN 20
	NOTE Dsh, 4
	LEN 10
	NOTE Dsh, 4
	INSTR 0
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 4
	NEXT
Pat_595F:
	HWENV $5B, $1E, $C7
	AUTODUTY $04
	DRUMS $05, DrumPat_5A23
	ARP 4
	LENGTH $50
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NEXT
Pat_5971:
	DRUMS $05, DrumPat_5A64
	VIBRATO $0A, $02, $04
	ARP 4
	LENGTH $A0
	NOTE F_, 5
	AUTODUTY $00
Pat_597F:
	LEN 10
	AUTODUTY $0A
	HWENV $F0, $05, $70
	DUTY_50
	ARP_OFF
	RELEASE $02, $53
	HWENV $62, $00
	ARP 0
	DUTY_12
	NOTE F_, 3
	NOTE Ash, 3
	NOTE F_, 4
	NOTE Ash, 3
	HWENV $82, $00
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE D_, 4
	NOTE Ash, 3
	HWENV $A2, $00
	NOTE F_, 3
	NOTE Ash, 3
	NOTE F_, 4
	NOTE Ash, 3
	HWENV $C2, $00
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE D_, 4
	NOTE Ash, 3
	HWENV $F2, $00
	NEXT
Pat_59AD:
	LEN 10
	REPEAT 2
	NOTE F_, 3
	NOTE C_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 4
	REPEAT_END
	REPEAT 2
	NOTE F_, 3
	LEN 5
	NOTE Ash, 3
	NOTE Ash, 3
	LEN 10
	NOTE F_, 4
	NOTE Ash, 3
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE D_, 4
	NOTE Ash, 3
	REPEAT_END
	NEXT
Pat_59C6:
	DUTY_50
	HWENV $F6, $14, $80
	ARP_OFF
	LEN 20
	NOTE A_, 4
	LEN 10
	NOTE Ash, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	LEN 30
	NOTE G_, 4
	LEN 10
	NOTE A_, 4
	NOTE G_, 4
	LEN 15
	NOTE Ash, 4
	NOTE A_, 4
	LEN 10
	NOTE G_, 4
	LENGTH $46
	NOTE F_, 4
	LEN 5
	NOTE F_, 4
	NOTE G_, 4
	LEN 20
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 10
	NOTE F_, 4
	LEN 20
	NOTE Dsh, 4
	LEN 10
	NOTE F_, 4
	WAIT
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 20
	NOTE F_, 4
	LEN 10
	NOTE D_, 4
	LEN 20
	NOTE F_, 4
	NOTE D_, 4
	LEN 5
	NOTE Csh, 4
	NOTE Dsh, 4
	LEN 20
	NOTE F_, 4
	LEN 10
	NOTE G_, 4
	LEN 20
	NOTE Gsh, 4
	LEN 10
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NEXT
Pat_5A13:
	LEN 10
	NOTE G_, 4
	HWENV $F0, $1E, $F7
	LEN 20
	NOTE F_, 4
	LENGTH $82
	NOTE F_, 4
	INSTR 9
	LEN 10
	PAT_GOTO Pat_597F
DrumPat_5A23:
	db 9, 0, 6, 0, 9, 0, 9, 0
	db 6, 0, 9, 0, 9, 0, 6, 0
	db 9, 0, 9, 0, 6, 0, 9, 0
	db 9, 0, 0, 0, 9, 6, 6, 6
	db 9, 0, 6, 0, 9, 0, 9, 0
	db 6, 0, 9, 0, 9, 0, 6, 0
	db 9, 0, 9, 0, 6, 0, 9, 0
	db 9, 0, 0, 0, 9, 0, 9, 9
	db DRUM_LOOP
DrumPat_5A64:
	db 1, 0, 5, 0, 9, 0, 5, 6
	db 1, 0, 1, 0, 9, 0, 5, 6
	db 1, 0, 5, 0, 9, 0, 5, 6
	db 1, 0, 1, 0, 9, 0, 5, 6
	db DRUM_LOOP

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
	dw Pat_5AAC

; Unreferenced (4 bytes)
	db $00, $00, $9A, $5A
Song6_Ch2:
	dw Pat_5AD2

; Unreferenced (4 bytes)
	db $00, $00, $A0, $5A
Song6_Ch1:
	dw Pat_5AF6

; Unreferenced (4 bytes)
	db $00, $00, $A6, $5A
Pat_5AAC:
	DRUMS $07, DrumPat_5B19
	CH_TRANSPOSE $0C
	INSTR 11
	LEN 7
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE G_, 2
	LEN 7
	NOTE F_, 2
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE Ash, 2
	NOTE Ash, 2
	LEN 14
	NOTE Ash, 2
	NOTE C_, 3
	LEN 7
	NOTE C_, 3
	LENGTH $8F
	DRUMS_OFF
	CALL_CODE Drum7
	NOTE G_, 2
	END
Pat_5AD2:
	INSTR 2
	LEN 7
	NOTE A_, 3
	NOTE A_, 3
	LEN 14
	NOTE A_, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE A_, 3
	NOTE A_, 3
	LEN 7
	NOTE A_, 3
	NOTE A_, 3
	INSTR 0
	LEN 14
	NOTE C_, 4
	INSTR 2
	LEN 7
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 14
	NOTE A_, 3
	INSTR 0
	LEN 7
	NOTE C_, 4
	INSTR 2
	LEN 14
	NOTE A_, 3
	INSTR 0
	LENGTH $8F
	NOTE C_, 4
	END
Pat_5AF6:
	ARP 7
	HWENV $F0, $05, $75
	AUTODUTY $04
	LEN 14
	NOTE G_, 5
	NOTE G_, 4
	NOTE F_, 5
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE E_, 5
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE D_, 5
	LEN 7
	NOTE Ash, 4
	NOTE C_, 5
	NOTE C_, 4
	NOTE Csh, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE Ash, 4
	LEN 14
	NOTE G_, 4
	LENGTH $8F
	NOTE G_, 4
	END
DrumPat_5B19:
	db 1, 1, 1, 6, 9, 6, 1, 1           ; no DRUM_LOOP: the pattern runs into the next data
	db 6, 1, 6, 1, 9, 6, 1, 1
	db 1, 1, 1, 1, 9, 1, 6

; Instrument table 1, entries 1..14 (the song routines point 2 bytes before:
; entry 0 is never read)
InstrTable1:
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
	dw Instr1_12

; Unreferenced (4 bytes)
	db $B8, $5B, $C2, $5B
Instr1_1:
	VOLENV 15, $12, $1F, $11
	GLIDE $FE
	WAVE Wave_6168
	END
Instr1_0:
	HWENV $F2, $03, $42
	ARP_OFF
	AUTODUTY $00
	DUTY_50
	GLIDE $FF
	END
Instr1_2:
	HWENV $F2, $04, $31
	ARP_OFF
	AUTODUTY $00
	DUTY_50
	GLIDE $FC
	END
Instr1_3:
	HWENV $F1, $00
	DUTY_50
	GLIDE $FF
	ARP 0
	END
Instr1_4:
	HWENV $A1, $04, $53
	ARP 4
	DUTY_75
	END
Instr1_5:
	HWENV $A1, $04, $53
	ARP 5
	DUTY_75
	END
Instr1_6:
	HWENV $A3, $0E, $30
	DUTY_50
	END
Instr1_7:
	HWENV $F1, $06, $43
	ARP 0
	DUTY_75
	END
Instr1_8:
	HWENV $B0, $01, $42
	END
Instr1_9:
	HWENV $C1, $07, $71
	DUTY_75
	END
Instr1_10:
	HWENV $50, $00
	END
Instr1_11:
	VOLENV 15, $11, $1F, $13
	ARP 6
	RELEASE $02, $11
	WAVE Wave_6138
	END
Instr1_12:
	HWENV $F0, $05, $70
	DUTY_50
	ARP_OFF
	RELEASE $02, $53
	END

; Unreferenced (17 bytes)
	db $C7, $0B, $1F, $11, $60, $FE, $79, $68, $61, $68, $74, $C2, $0E, $30, $71, $7C
	db $68
ArpTable:
	dw Arp0
	dw Arp1
	dw Arp2
	dw Arp3
	dw Arp4
	dw Arp5
	dw Arp6
	dw Arp7

; Unreferenced (40 bytes)
	db $2E, $5C, $36, $5C, $3A, $5C, $44, $5C, $53, $5C, $59, $5C, $64, $5C, $6B, $5C
	db $76, $5C, $8D, $5C, $91, $5C, $95, $5C, $A8, $5C, $A8, $5C, $A8, $5C, $A8, $5C
	db $AC, $5C, $AC, $5C, $AC, $5C, $AC, $5C
Arp0:
	db $0C, $00, ARP_HOLD
Arp3:
	db $00, $00, $01, $01, $02, ARP_HOLD
Arp2:
	db $18, $00, $04, $04, $07, $07, $0C, ARP_LOOP
Arp1:
	db $02, $02, $01, $01, $00, ARP_HOLD
Arp4:
	db $00, $00, $07, $07, $04, $04, ARP_LOOP
Arp5:
	db $00, $00, $07, $07, $03, $03, ARP_LOOP
Arp6:
	db $18, $0C, $00, ARP_HOLD
Arp7:
	db $18, $0C, $00, ARP_HOLD

; Unreferenced (126 bytes)
	db $01, $00, $02, $01, $03, $01, $00, $6A, $0C, $0C, $00, $FF, $0C, $00, $00, $00
	db $00, $00, $00, $00, $0C, $FF, $0C, $00, $00, $00, $00, $00, $00, $0C, $0C, $0C
	db $0C, $0C, $0C, $0C, $FF, $00, $01, $02, $01, $00, $FF, $0C, $00, $00, $00, $00
	db $00, $00, $00, $00, $0C, $FF, $22, $04, $03, $02, $01, $00, $FF, $02, $FC, $FA
	db $F8, $F5, $F2, $F0, $EC, $EA, $E6, $FF, $0C, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $6A, $18
	db $0C, $0C, $6A, $03, $00, $07, $6A, $07, $0C, $03, $00, $00, $00, $00, $00, $00
	db $07, $0C, $03, $00, $00, $00, $00, $00, $00, $FF, $18, $0C, $00, $FF
Noise43_5CAC:
	db $10, $12, $13, $14, $15, $16, $17, $27
	db $FF
Noise42_5CB5:
	db $29, $FF, $FF, $FF, $FF, $FF, $FF, $81
Noise43_5CBD:
	db $12, $55, $FF

; Unreferenced (6 bytes)
	db $71, $FF, $36, $71, $30, $FF
Noise42_5CC6:
	db $A1, $FF

; Unreferenced (6 bytes)
	db $FF, $FF, $FF, $FF, $FF, $41
Noise43_5CCE:
	db $31, $FF

; Unreferenced (4 bytes)
	db $FF, $FF, $FF, $FF
Noise43_5CD4:
	db $31, $44, $FF

; Unreferenced (3 bytes)
	db $FF, $10, $FF
Noise42_5CDA:
	db $61, $FF

; Unreferenced (3 bytes)
	db $FF, $FF, $32
Noise42_5CDF:
	db $41, $FF

; Unreferenced (3 bytes)
	db $FF, $FF, $12
Noise42_5CE4:
	db $22, $FF

; Unreferenced (3 bytes)
	db $FF, $FF, $FF
GamePlaySfxGlue:
	add a, a
	add a, $F5
	ld l, a
	adc a, $5C
	sub l
	ld h, a
	ld c, [hl]
	inc hl
	ld b, [hl]
	push bc
GlueSfxTable_m2:
	ret

; Unreferenced (1 bytes)
	db $C9

; The game's sound-effect table: id n (1-18) jumps to entry n (indexed from 2 bytes before)
GlueSfxTable:
	dw GlueSfx01
	dw GlueSfx02
	dw GlueSfx03
	dw GlueSfx04
	dw GlueSfx05
	dw GlueSfx06
	dw GlueSfx07
	dw GlueSfx08
	dw GlueSfx09
	dw GlueSfx10
	dw GlueSfx11
	dw GlueSfx12
	dw GlueSfx13
	dw GlueSfx14
	dw GlueSfx15
	dw GlueSfx16
	dw GlueSfx17
	dw GlueSfx18

; Game sound effect 1
GlueSfx01:
	ld a, $03
	jp PlaySfx

; Game sound effect 2
GlueSfx02:
	ld a, $04
	jp PlaySfx

; Game sound effect 3
GlueSfx03:
	ld de, GlueStream_5D2B
	jp PlayOnCh1
GlueStream_5D2B:
	HWENV $E0, $00
	DUTY_50
	LEN 2
	REPEAT 8
	NOTE A_, 6
	NOTE Gsh, 6
	REPEAT_END
	END

; Game sound effect 4
GlueSfx04:
	ld a, $88
	ld [wNoisePan], a
	ld a, $08
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5CD4)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5CD4)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5CDA)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5CDA)
	ld [wNoise42], a
	ld de, GlueStream_5D61
	jp PlayOnCh2
GlueStream_5D61:
	DUTY_50
	HWENV $F1, $02, $51
	LEN 4
	GLIDE $FD
	NOTE E_, 3
	END

; Game sound effect 5
GlueSfx05:
	ld a, $88
	ld [wNoisePan], a
	ld a, $08
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5CD4)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5CD4)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5CDF)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5CDF)
	ld [wNoise42], a
	ld de, GlueStream_5D97
	jp PlayOnCh2
GlueStream_5D97:
	DUTY_50
	HWENV $81, $02, $21
	LEN 4
	GLIDE $FD
	NOTE C_, 3
	END

; Game sound effect 6
GlueSfx06:
	ld a, $88
	ld [wNoisePan], a
	ld a, $08
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5CD4)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5CD4)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5CE4)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5CE4)
	ld [wNoise42], a
	ld de, GlueStream_5DCD
	jp PlayOnCh2
GlueStream_5DCD:
	DUTY_50
	HWENV $61, $00
	LEN 4
	GLIDE $FD
	NOTE C_, 3
	END

; Game sound effect 7
GlueSfx07:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5CBD)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5CBD)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5CC6)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5CC6)
	ld [wNoise42], a
	ld de, GlueStream_5E02
	jp PlayOnCh2
GlueStream_5E02:
	DUTY_50
	LEN 5
	REST
	HWENV $91, $00
	LEN 8
	GLIDE $FF
	NOTE Gsh, 3
	END

; Game sound effect 8
GlueSfx08:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0C
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5CAC)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5CAC)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5CB5)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5CB5)
	ld [wNoise42], a
	ret

; Game sound effect 10
GlueSfx10:
	ld a, $88
	ld [wNoisePan], a
	ld a, $08
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5CD4)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5CD4)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5CDA)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5CDA)
	ld [wNoise42], a
	ld de, GlueStream_5E60
	jp PlayOnCh2
GlueStream_5E60:
	DUTY_50
	HWENV $C1, $02, $52
	LEN 6
	GLIDE $03
	NOTE E_, 2
	END

; Game sound effect 11
GlueSfx11:
	ld a, $88
	ld [wNoisePan], a
	ld a, $08
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5CCE)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5CCE)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5CDA)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5CDA)
	ld [wNoise42], a
	ld de, GlueStream_5E96
	jp PlayOnCh2
GlueStream_5E96:
	DUTY_50
	HWENV $C1, $03, $31
	LEN 8
	VIBRATO $00, $08, $02
	NOTE Fsh, 3
	END

; Game sound effect 12
GlueSfx12:
	ld a, $02
	ld [wCrowdLevel], a
	ld a, $09
	ld [wCrowdNoise], a
	ret

; Game sound effect 13
GlueSfx13:
	ld a, $05
	ld [wCrowdLevel], a
	ld a, $07
	ld [wCrowdNoise], a
	ret

; Game sound effect 14
GlueSfx14:
	ld a, $08
	ld [wCrowdLevel], a
	ld a, $05
	ld [wCrowdNoise], a
	ret

; Game sound effect 9
GlueSfx09:
	ld a, $88
	ld [wNoisePan], a
	ld a, $08
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5CD4)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5CD4)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5CDA)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5CDA)
	ld [wNoise42], a
	ld de, GlueStream_5EEF
	jp PlayOnCh2
GlueStream_5EEF:
	DUTY_50
	HWENV $F1, $02, $51
	LEN 4
	GLIDE $FD
	NOTE C_, 4
	END

; Game sound effect 15
GlueSfx15:
	ld de, GlueStream_5EFF
	jp PlayOnCh3
GlueStream_5EFF:
	WAVE Wave_6148
	VOLENV 10, $00, $00, $00
	CH_TRANSPOSE $0C
	GLIDE_OFF
	ARP 3
	LEN 18
	NOTE E_, 4
	LEN 27
	NOTE G_, 4
	LEN 9
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	LEN 45
	NOTE C_, 4
	LEN 41
	REST
	END

; Game sound effect 16
GlueSfx16:
	ld de, GlueStream_5F1F
	jp PlayOnCh3
GlueStream_5F1F:
	WAVE Wave_6148
	VOLENV 10, $11, $1F, $13
	CH_TRANSPOSE $0C
	GLIDE $FF
	LEN 28
	NOTE A_, 3
	NOTE A_, 3
	LEN 14
	NOTE A_, 3
	NOTE A_, 3
	LEN 28
	NOTE A_, 3
	LEN 14
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 28
	NOTE A_, 3
	LEN 14
	NOTE A_, 3
	LENGTH $FC
	NOTE A_, 3
	END

; Game sound effect 17
GlueSfx17:
	ld de, GlueStream_5F44
	jp PlayOnCh3
GlueStream_5F44:
	WAVE Wave_6148
	VOLENV 10, $11, $1F, $13
	CH_TRANSPOSE $0C
	GLIDE $FF
	LEN 16
	NOTE B_, 3
	NOTE B_, 3
	LEN 8
	NOTE B_, 3
	NOTE B_, 3
	NOTE B_, 3
	NOTE B_, 3
	LEN 16
	NOTE B_, 3
	NOTE B_, 3
	LEN 8
	NOTE B_, 3
	NOTE B_, 3
	NOTE B_, 3
	NOTE B_, 3
	LEN 16
	NOTE B_, 3
	NOTE B_, 3
	LEN 8
	NOTE B_, 3
	NOTE B_, 3
	NOTE B_, 3
	NOTE B_, 3
	LENGTH $78
	NOTE B_, 3
	END

; Game sound effect 18
GlueSfx18:
	ld de, GlueStream_5F71
	jp PlayOnCh3
GlueStream_5F71:
	WAVE Wave_6148
	VOLENV 10, $11, $11, $11
	CH_TRANSPOSE $0C
	ARP 3
	GLIDE_OFF
	VIBRATO $00, $04, $02
	RELEASE $04, $A1
	LEN 8
	NOTE G_, 4
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE G_, 4
	LENGTH $30
	NOTE G_, 4
	LEN 16
	NOTE E_, 4
	LEN 8
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	LEN 8
	NOTE E_, 4
	LENGTH $30
	NOTE E_, 4
	LEN 24
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 4
	LENGTH $30
	NOTE E_, 4
	LENGTH $90
SfxTable_m2:
	REST
	END

; SFX table (indexed from 2 bytes before: id 1 is the first entry)
SfxTable:
	dw Sfx01
	dw Sfx02
	dw Sfx03
	dw Sfx04
	dw Sfx05

; Sound effect 1
Sfx01:
	WAVE Wave_6158
	VOLENV 15, $00, $00, $00
	LEN 1
	NOTE D_, 4
	NOTE Gsh, 3
	END

; Sound effect 2
Sfx02:
	WAVE Wave_6158
	VOLENV 15, $00, $00, $00
	LEN 1
	NOTE B_, 4
	NOTE Gsh, 4
	END

; Sound effect 5
Sfx05:
	VOLENV 15, $00, $00, $00
	GLIDE $FB
	LEN 40
	NOTE A_, 7
	END

; Sound effect 3
Sfx03:
	VOLENV 15, $11, $1F, $12
	CH_TRANSPOSE $0C
	WAVE Wave_6178
	LEN 2
	NOTE Csh, 6
	NOTE A_, 5
	END

; Sound effect 4
Sfx04:
	WAVE Wave_6178
	LEN 3
	VOLENV 15, $11, $1F, $1F
	CH_TRANSPOSE $0C
	ARP 0
	NOTE Fsh, 6
	NOTE Csh, 6
	NOTE Fsh, 5
	VOLENV 10, $11, $1F, $1F
	NOTE Fsh, 6
	NOTE Csh, 6
	NOTE Fsh, 5
	VOLENV 5, $11, $1F, $1F
	NOTE Fsh, 6
	NOTE Csh, 6
	NOTE Fsh, 5
	END

; Unreferenced (32 bytes)
	db $84, $32, $55, $55, $51, $23, $8F, $F8, $40, $04, $8F, $F8, $40, $04, $8F, $F8
	db $02, $46, $8A, $CE, $FF, $DB, $DF, $FF, $EC, $A8, $64, $20, $FF, $FF, $FF, $FF
Wave_6018:
	db $FF, $FF, $FF, $F7, $7F, $FF, $FF, $F7
	db $71, $23, $45, $67, $77, $76, $54, $32

; Unreferenced (272 bytes)
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00
	db $01, $11, $11, $00, $89, $AA, $AA, $98, $01, $11, $11, $00, $FF, $FF, $FF, $FF
	db $A8, $40, $04, $8A, $FF, $FF, $FF, $FF, $A8, $40, $04, $8A, $FF, $FF, $FF, $FF
	db $8C, $FE, $ED, $B8, $53, $21, $10, $24, $84, $01, $12, $35, $8B, $DE, $EF, $8C
	db $00, $46, $8A, $FF, $FF, $A8, $64, $00, $00, $46, $8A, $FF, $FF, $A8, $64, $00
	db $B7, $40, $F4, $7B, $FD, $FF, $FE, $DC, $02, $46, $8A, $BD, $FD, $BA, $6F, $20
	db $B7, $4E, $F4, $FF, $DF, $FF, $ED, $C0, $24, $68, $AB, $DF, $DD, $DD, $6F, $20
	db $32, $22, $11, $11, $11, $22, $23, $45, $FD, $CB, $A9, $87, $65, $43, $21, $10
	db $DD, $DB, $97, $52, $22, $54, $22, $22, $DD, $DC, $BD, $DD, $DB, $85, $22, $22
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $01, $11, $11, $00, $89, $AA, $AA, $98, $01, $11, $11, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $CD, $EF, $FD, $EC, $00, $12, $21, $00, $DD, $DD, $DD, $DD
	db $00, $00, $00, $00, $00, $00, $FF, $FF, $00, $00, $00, $00, $00, $00, $FF, $FF
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $A8, $76, $67, $8A
	db $00, $00, $00, $00, $00, $00, $FF, $00, $00, $00, $00, $00, $00, $00, $FF, $00
	db $00, $00, $00, $CD, $EF, $FF, $FF, $FF, $04, $8C, $FF, $FF, $FF, $FF, $FF, $FF
	db $48, $FF, $FF, $FF, $FF, $FF, $FF, $84, $00, $00, $00, $00, $00, $4F, $FF, $88
Wave_6138:
	db $FC, $96, $31, $00, $00, $90, $00, $00
	db $24, $69, $CE, $FF, $FF, $FF, $FF, $FF
Wave_6148:
	db $12, $34, $56, $78, $9A, $BC, $DE, $FF
	db $ED, $CB, $A9, $87, $65, $43, $21, $00
Wave_6158:
	db $FF, $FF, $FD, $B8, $53, $20, $00, $00
	db $00, $00, $02, $35, $8B, $DF, $FF, $FF
Wave_6168:
	db $63, $10, $40, $20, $00, $00, $01, $36
	db $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9
Wave_6178:
	db $63, $10, $01, $47, $74, $10, $01, $36
	db $9C, $EF, $FE, $B8, $8B, $EF, $FE, $C9

; Unreferenced (224 bytes)
	db $63, $1F, $01, $47, $74, $10, $01, $36, $9C, $E0, $FE, $B8, $8B, $EF, $FE, $C9
	db $65, $43, $22, $27, $72, $22, $22, $29, $AB, $CC, $BA, $98, $9C, $EE, $EE, $C9
	db $63, $20, $02, $47, $74, $22, $22, $36, $9C, $EF, $FE, $B6, $6B, $EE, $EE, $C9
	db $B7, $40, $04, $7B, $CD, $FF, $FE, $DC, $02, $46, $8A, $BD, $FD, $BA, $64, $20
	db $0F, $00, $F0, $F0, $F0, $F0, $00, $0F, $0F, $FF, $FF, $00, $FF, $F0, $0F, $0F
	db $BB, $2B, $BB, $2B, $BB, $5B, $2B, $BB, $2B, $BB, $BB, $72, $27, $EB, $BB, $B0
	db $00, $00, $00, $00, $00, $00, $00, $00, $ED, $CB, $A9, $87, $65, $43, $21, $00
	db $FE, $DB, $97, $53, $13, $54, $32, $10, $FE, $DC, $BC, $EF, $DB, $85, $32, $10
	db $04, $8B, $DE, $FF, $ED, $CB, $A9, $87, $65, $44, $44, $32, $11, $24, $7A, $74
	db $20, $13, $69, $BD, $FD, $B9, $64, $20, $13, $68, $B8, $64, $20, $24, $68, $64
	db $00, $00, $69, $FF, $FF, $F9, $64, $00, $03, $68, $B8, $60, $00, $04, $68, $60
	db $20, $24, $68, $AC, $EC, $A8, $64, $20, $24, $68, $A8, $64, $20, $24, $68, $64
	db $02, $48, $AC, $FF, $FC, $53, $00, $27, $9C, $DD, $DC, $B7, $7B, $CD, $DD, $C9
	db $BD, $FF, $AC, $FF, $FC, $52, $00, $27, $9C, $DF, $DC, $B7, $7B, $CD, $AD, $C9
Noise43_6268:
	db $20, $10, $FF
Noise42_626B:
	db $D0, $61
Noise43_626D:
	db $06, $04, $03, $03, $07, $FF
Noise42_6273:
	db $F0, $C0, $80, $60, $57
Noise43_6278:
	db $10, $01, $01, $FF
Noise42_627C:
	db $91, $61, $00
Noise43_627F:
	db $10, $01, $01, $FF
Noise42_6283:
	db $C1, $81, $00
Noise43_6286:
	db $12, $12, $FF
Noise42_6289:
	db $A0, $44

; Unreferenced (1 bytes)
	db $FF
Sfx1DrumNoise:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6268)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6268)
	ld [wNoise43], a
	ld a, HIGH(Noise42_626B)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_626B)
	ld [wNoise42], a
	ret
Drum8:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_62C6)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_62C6)
	ld [wNoise43], a
	ld a, HIGH(Noise42_62CC)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_62CC)
	ld [wNoise42], a
	ret
Noise43_62C6:
	db $04, $02, $01, $00, $00, $FF
Noise42_62CC:
	db $30, $40, $60, $43, $42

; Unreferenced (44 bytes)
	db $AF, $EA, $5D, $DC, $3C, $EA, $5E, $DC, $3E, $62, $EA, $59, $DC, $3E, $EE, $EA
	db $5A, $DC, $3E, $62, $EA, $5B, $DC, $3E, $F6, $EA, $5C, $DC, $C9, $62, $52, $42
	db $41, $22, $11, $04, $FF, $F0, $F0, $F0, $A0, $70, $40, $51
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6286)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6286)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6289)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6289)
	ld [wNoise42], a
	ret
Drum5:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_627F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_627F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6283)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6283)
	ld [wNoise42], a
	ret
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6278)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6278)
	ld [wNoise43], a
	ld a, HIGH(Noise42_627C)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_627C)
	ld [wNoise42], a
	ret
Drum7:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_626D)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_626D)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6273)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6273)
	ld [wNoise42], a
	ld a, $01
	jp PlaySfx

; Unreferenced (1 bytes)
	db $C9
Sfx2DrumNoise:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_63B0)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_63B0)
	ld [wNoise43], a
	ld a, HIGH(Noise42_63B3)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_63B3)
	ld [wNoise42], a
	ret
Drum10:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_63B5)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_63B5)
	ld [wNoise43], a
	ld a, HIGH(Noise42_63B7)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_63B7)
	ld [wNoise42], a
	ret
Noise43_63B0:
	db $21, $32, $FF
Noise42_63B3:
	db $B0, $62
Noise43_63B5:
	db $12, $FF
Noise42_63B7:
	db $F1

; Unreferenced (21 bytes)
	db $51, $32, $32, $32, $32, $51, $32, $FF, $80, $FF, $FF, $FF, $FF, $FF, $FF, $51
	db $FF, $FF, $FF, $80, $51
Drum11:
	ld a, $01
	call PlaySfx
	jp Sfx1DrumNoise

; Unreferenced (7 bytes)
	db $21, $45, $05, $FF, $81, $F1, $21
Drum12:
	ld a, $02
	call PlaySfx
	jp Sfx2DrumNoise

; Unreferenced (7 bytes)
	db $20, $44, $33, $FF, $80, $F0, $43
FadeOutTable:
	db $77, $66, $55, $44, $33, $22, $11, $00
	db $80, FADE_END
FadeInTable:
	db $00, $11, $22, $33, $44, $55, $66, $77
	db FADE_END
DriverEndText:
	db "Final de la rutina de musica"

; Unreferenced (7142 bytes)
	db $61, $63, $61, $61, $DC, $3E, $53, $EA, $5A, $DC, $3E, $63, $EA, $5B, $DC, $3E
	db $57, $EA, $5C, $DC, $C9, $AF, $EA, $5D, $DC, $3C, $EA, $5E, $DC, $3E, $63, $EA
	db $59, $DC, $3E, $48, $EA, $5A, $DC, $3E, $63, $EA, $5B, $DC, $3E, $4E, $EA, $5C
	db $DC, $3E, $01, $C3, $90, $4A, $C9, $AF, $EA, $5D, $DC, $3C, $EA, $5E, $DC, $3E
	db $64, $EA, $59, $DC, $3E, $8B, $EA, $5A, $DC, $3E, $64, $EA, $5B, $DC, $3E, $8E
	db $EA, $5C, $DC, $C9, $AF, $EA, $5D, $DC, $3C, $EA, $5E, $DC, $3E, $64, $EA, $59
	db $DC, $3E, $90, $EA, $5A, $DC, $3E, $64, $EA, $5B, $DC, $3E, $92, $EA, $5C, $DC
	db $C9, $21, $32, $FF, $B0, $62, $12, $FF, $F1, $51, $32, $32, $32, $32, $51, $32
	db $FF, $80, $FF, $FF, $FF, $FF, $FF, $FF, $51, $FF, $FF, $FF, $80, $51, $3E, $01
	db $CD, $90, $4A, $C3, $67, $63, $21, $45, $05, $FF, $81, $F1, $21, $3E, $02, $CD
	db $90, $4A, $C3, $51, $64, $20, $44, $33, $FF, $80, $F0, $43, $77, $66, $55, $44
	db $33, $22, $11, $00, $80, $FF, $00, $11, $22, $33, $44, $55, $66, $77, $FF, $46
	db $69, $6E, $61, $6C, $20, $64, $65, $20, $6C, $61, $20, $72, $75, $74, $69, $6E
	db $61, $20, $64, $65, $20, $6D, $75, $73, $69, $63, $61, $32, $FF, $80, $FF, $FF
	db $FF, $FF, $FF, $FF, $51, $FF, $FF, $FF, $80, $51, $3E, $01, $CD, $90, $4A, $C3
	db $C3, $63, $21, $45, $05, $FF, $81, $F1, $21, $3E, $02, $CD, $90, $4A, $C3, $AD
	db $64, $20, $44, $33, $FF, $80, $F0, $43, $77, $66, $55, $44, $33, $22, $11, $00
	db $80, $FF, $00, $11, $22, $33, $44, $55, $66, $77, $FF, $46, $69, $6E, $61, $6C
	db $20, $64, $65, $20, $6C, $61, $20, $72, $75, $74, $69, $6E, $61, $20, $64, $65
	db $20, $6D, $75, $73, $69, $63, $61, $01, $00, $06, $00, $06, $00, $04, $00, $06
	db $00, $06, $00, $01, $00, $06, $00, $06, $00, $04, $00, $06, $00, $04, $00, $FF
	db $01, $00, $06, $00, $06, $00, $02, $00, $06, $00, $06, $00, $01, $00, $06, $00
	db $06, $00, $02, $00, $06, $00, $06, $06, $FF, $06, $00, $00, $00, $06, $00, $04
	db $00, $00, $00, $00, $00, $06, $00, $00, $00, $06, $00, $04, $00, $00, $00, $06
	db $00, $FF, $01, $FF, $01, $00, $06, $00, $04, $00, $06, $00, $01, $00, $06, $00
	db $04, $00, $01, $00, $FF, $07, $00, $00, $06, $02, $06, $04, $06, $01, $06, $04
	db $06, $02, $06, $01, $06, $01, $06, $04, $06, $02, $06, $04, $06, $01, $06, $04
	db $06, $02, $06, $01, $06, $FF, $48, $07, $FF, $06, $00, $06, $06, $04, $00, $06
	db $06, $06, $00, $06, $06, $04, $06, $06, $06, $FF, $06, $06, $04, $06, $06, $06
	db $04, $06, $06, $06, $04, $06, $06, $06, $04, $04, $06, $06, $04, $06, $06, $06
	db $04, $06, $06, $06, $04, $04, $06, $06, $04, $04, $FF, $07, $00, $00, $00, $04
	db $00, $06, $00, $01, $00, $06, $00, $04, $00, $06, $06, $01, $00, $06, $00, $04
	db $00, $06, $00, $01, $00, $06, $00, $04, $00, $04, $06, $01, $00, $06, $00, $04
	db $00, $06, $00, $01, $00, $06, $00, $04, $00, $06, $06, $01, $00, $06, $00, $04
	db $00, $04, $00, $01, $00, $06, $00, $04, $00, $04, $06, $FF, $01, $00, $06, $01
	db $01, $00, $06, $01, $01, $00, $06, $06, $06, $06, $04, $00, $FF, $07, $00, $00
	db $00, $04, $00, $01, $00, $01, $00, $06, $00, $04, $00, $01, $06, $01, $00, $06
	db $00, $04, $00, $06, $00, $04, $00, $06, $00, $01, $06, $06, $06, $01, $00, $06
	db $00, $04, $00, $01, $00, $01, $00, $06, $00, $04, $00, $01, $06, $01, $00, $06
	db $00, $04, $00, $06, $00, $04, $00, $06, $00, $01, $06, $06, $06, $FF, $00, $00
	db $00, $00, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $00, $00
	db $00, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $FF, $FF, $FF, $12, $34
	db $56, $78, $9A, $BC, $DE, $FF, $ED, $CB, $A9, $87, $65, $43, $21, $00, $FF, $FE
	db $ED, $B8, $53, $21, $10, $00, $00, $01, $12, $35, $8B, $DE, $EF, $FF, $63, $10
	db $01, $47, $74, $10, $01, $36, $9C, $EF, $FE, $B8, $8B, $EF, $FE, $C9, $B7, $40
	db $04, $7B, $CD, $FF, $FE, $DC, $02, $46, $8A, $BD, $FD, $BA, $64, $20, $00, $00
	db $00, $00, $00, $00, $00, $00, $ED, $CB, $A9, $87, $65, $43, $21, $00, $FE, $DB
	db $97, $53, $13, $54, $32, $10, $FE, $DC, $BC, $EF, $DB, $85, $32, $10, $00, $00
	db $00, $00, $00, $00, $FF, $FF, $00, $00, $00, $00, $00, $00, $FF, $FF, $00, $00
	db $00, $00, $00, $00, $00, $FF, $00, $00, $00, $00, $00, $00, $00, $FF, $02, $51
	db $61, $71, $91, $71, $60, $FF, $F0, $F0, $D0, $90, $00, $50, $43, $F0, $F0, $D0
	db $90, $80, $50, $41, $60, $52, $42, $41, $22, $11, $04, $FF, $F0, $E0, $D0, $B0
	db $A0, $90, $81, $F0, $E0, $D0, $B0, $A0, $70, $41, $06, $04, $03, $03, $07, $FF
	db $F0, $F0, $D0, $C0, $85, $04, $02, $01, $FF, $80, $50, $33, $04, $02, $06, $FF
	db $A0, $50, $54, $50, $41, $50, $51, $52, $53, $51, $FF, $F0, $60, $F0, $60, $D0
	db $50, $72, $00, $00, $00, $FF, $2F, $F7, $20, $00, $00, $FF, $08, $00, $00, $00
	db $08, $00, $00, $00, $08, $00, $00, $00, $00, $08, $00, $00, $00, $09, $00, $00
	db $00, $FF, $AF, $EA, $64, $C1, $3C, $EA, $65, $C1, $3E, $67, $EA, $60, $C1, $3E
	db $48, $EA, $61, $C1, $3E, $67, $EA, $62, $C1, $3E, $50, $EA, $63, $C1, $C9, $AF
	db $EA, $64, $C1, $3C, $EA, $65, $C1, $3E, $67, $EA, $60, $C1, $3E, $5E, $EA, $61
	db $C1, $3E, $67, $EA, $62, $C1, $3E, $50, $EA, $63, $C1, $C9, $AF, $EA, $64, $C1
	db $3C, $EA, $65, $C1, $3E, $67, $EA, $60, $C1, $3E, $8D, $EA, $61, $C1, $3E, $67
	db $EA, $62, $C1, $3E, $95, $EA, $63, $C1, $C9, $AF, $EA, $64, $C1, $3C, $EA, $65
	db $C1, $3E, $67, $EA, $60, $C1, $3E, $86, $EA, $61, $C1, $3E, $67, $EA, $62, $C1
	db $3E, $8A, $EA, $63, $C1, $C9, $C9, $AF, $EA, $64, $C1, $3C, $EA, $65, $C1, $3E
	db $67, $EA, $60, $C1, $3E, $7F, $EA, $61, $C1, $3E, $67, $EA, $62, $C1, $3E, $83
	db $EA, $63, $C1, $C9, $AF, $EA, $64, $C1, $3C, $EA, $65, $C1, $3E, $67, $EA, $60
	db $C1, $3E, $74, $EA, $61, $C1, $3E, $67, $EA, $62, $C1, $3E, $7A, $EA, $63, $C1
	db $C9, $AF, $EA, $64, $C1, $3C, $EA, $65, $C1, $3E, $55, $EA, $68, $C1, $AF, $EA
	db $67, $C1, $3E, $67, $EA, $60, $C1, $3E, $9C, $EA, $61, $C1, $3E, $67, $EA, $62
	db $C1, $3E, $A0, $EA, $63, $C1, $C9, $AF, $EA, $64, $C1, $3C, $EA, $65, $C1, $3E
	db $55, $EA, $68, $C1, $AF, $EA, $67, $C1, $3E, $67, $EA, $60, $C1, $3E, $A3, $EA
	db $61, $C1, $3E, $67, $EA, $62, $C1, $3E, $A0, $EA, $63, $C1, $C9, $00, $01, $02
	db $03, $04, $05, $06, $07, $08, $09, $FF, $50, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $AF, $EA, $64, $C1, $3C, $EA, $65, $C1, $3E, $01, $EA, $68, $C1, $AF
	db $EA, $67, $C1, $3E, $68, $EA, $60, $C1, $3E, $B7, $EA, $61, $C1, $3E, $68, $EA
	db $62, $C1, $3E, $C2, $EA, $63, $C1, $C9, $AA, $6A, $24, $69, $3B, $69, $C0, $69
	db $4B, $69, $4F, $69, $5F, $69, $8B, $69, $9D, $69, $D2, $69, $FB, $69, $E0, $69
	db $5E, $6A, $77, $6A, $D4, $6A, $E8, $6A, $F2, $6A, $44, $6A, $36, $6A, $1A, $6A
	db $8C, $6A, $9B, $6A, $B9, $6A, $C5, $6A, $75, $69, $BB, $12, $1F, $12, $79, $98
	db $66, $63, $01, $08, $05, $60, $FD, $C0, $24, $60, $03, $C0, $65, $61, $CF, $65
	db $68, $7F, $01, $6B, $BB, $12, $1F, $11, $79, $98, $66, $60, $FD, $C1, $24, $2A
	db $68, $7F, $9B, $6B, $68, $7F, $0A, $6C, $BB, $11, $1F, $11, $79, $98, $66, $C5
	db $95, $60, $01, $21, $68, $7F, $2E, $6B, $BB, $11, $1F, $13, $79, $EF, $6C, $63
	db $01, $07, $02, $83, $02, $1E, $DE, $3E, $BC, $00, $68, $BB, $11, $1F, $11, $7A
	db $0C, $79, $BF, $6C, $60, $01, $BE, $24, $66, $23, $66, $22, $66, $20, $66, $1F
	db $68, $79, $38, $67, $BB, $10, $1F, $11, $93, $BF, $3C, $39, $3C, $39, $3C, $39
	db $65, $65, $68, $79, $28, $67, $7F, $CA, $6B, $60, $05, $C5, $BB, $00, $00, $00
	db $21, $B6, $00, $00, $00, $22, $B6, $00, $00, $00, $23, $B1, $00, $00, $00, $24
	db $B1, $00, $00, $00, $25, $68, $79, $98, $66, $7F, $CA, $6B, $AC, $1F, $1F, $13
	db $63, $01, $14, $07, $D9, $3C, $65, $68, $79, $98, $66, $BB, $11, $1F, $12, $BF
	db $3C, $48, $3C, $CF, $48, $68, $7F, $01, $6B, $BB, $11, $1F, $12, $94, $7A, $03
	db $79, $FF, $6C, $BF, $60, $FD, $11, $BE, $66, $C3, $60, $01, $0F, $60, $FF, $65
	db $68, $B3, $1F, $1F, $20, $63, $01, $14, $02, $7A, $FC, $79, $BF, $6C, $E3, $83
	db $05, $28, $24, $BB, $11, $1F, $12, $CF, $28, $BC, $AC, $00, $00, $00, $10, $68
	db $BB, $11, $1F, $12, $93, $79, $98, $66, $BF, $60, $04, $12, $BF, $60, $FF, $65
	db $BF, $60, $01, $65, $60, $FF, $65, $BF, $60, $01, $65, $68, $BB, $00, $00, $00
	db $79, $FF, $6C, $C0, $21, $BE, $66, $CF, $21, $68, $C0, $BB, $00, $00, $00, $79
	db $A8, $66, $30, $34, $37, $B6, $00, $00, $00, $30, $34, $37, $B1, $00, $00, $00
	db $30, $34, $37, $68, $BB, $11, $23, $11, $C0, $93, $79, $28, $67, $2B, $2F, $32
	db $2F, $32, $37, $32, $37, $3B, $37, $3B, $3E, $43, $65, $65, $68, $7F, $92, $6C
	db $79, $C8, $66, $BB, $11, $1F, $11, $7A, $0C, $60, $02, $C4, $66, $15, $17, $18
	db $17, $68, $79, $98, $66, $BB, $00, $1F, $11, $60, $FB, $C0, $28, $60, $02, $28
	db $68, $79, $98, $66, $BB, $00, $1F, $11, $C0, $60, $FE, $34, $60, $FB, $28, $68
	db $C0, $93, $79, $E8, $66, $BB, $10, $1F, $12, $3C, $43, $40, $3C, $43, $68, $C9
	db $BB, $13, $1F, $11, $60, $01, $79, $98, $66, $18, $68, $7F, $5C, $6C, $BB, $11
	db $1F, $15, $79, $98, $66, $C4, $60, $FD, $21, $68, $D9, $BB, $00, $00, $00, $79
	db $C8, $66, $63, $00, $05, $03, $83, $02, $1E, $39, $41, $BC, $39, $68, $BB, $11
	db $2F, $11, $79, $CF, $6C, $C8, $3C, $68, $BF, $BB, $11, $2F, $11, $79, $CF, $6C
	db $BF, $38, $BC, $66, $BF, $44, $68, $3E, $04, $EA, $50, $C1, $AF, $EA, $64, $C1
	db $3C, $EA, $65, $C1, $3E, $6B, $EA, $60, $C1, $3E, $23, $EA, $61, $C1, $3E, $6B
	db $EA, $62, $C1, $3E, $29, $EA, $63, $C1, $C9, $00, $53, $71, $91, $31, $FF, $F1
	db $FF, $FF, $FF, $00, $3E, $2D, $EA, $50, $C1, $AF, $EA, $64, $C1, $3C, $EA, $65
	db $C1, $3E, $6B, $EA, $60, $C1, $3E, $50, $EA, $61, $C1, $3E, $6B, $EA, $62, $C1
	db $3E, $76, $EA, $63, $C1, $C9, $03, $93, $80, $72, $70, $56, $54, $60, $50, $40
	db $30, $20, $10, $56, $54, $60, $50, $40, $30, $20, $10, $56, $54, $60, $50, $40
	db $30, $20, $10, $56, $54, $60, $50, $40, $30, $20, $10, $FF, $F3, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $3E, $04, $EA, $50, $C1, $AF, $EA, $64, $C1, $3C, $EA, $65, $C1, $3E, $6B
	db $EA, $60, $C1, $3E, $BD, $EA, $61, $C1, $3E, $6B, $EA, $62, $C1, $3E, $C4, $EA
	db $63, $C1, $C9, $41, $61, $61, $41, $71, $71, $FF, $A1, $52, $00, $61, $52, $00
	db $3E, $2D, $EA, $50, $C1, $AF, $EA, $64, $C1, $3C, $EA, $65, $C1, $3E, $02, $EA
	db $68, $C1, $AF, $EA, $67, $C1, $3E, $6B, $EA, $60, $C1, $3E, $F5, $EA, $61, $C1
	db $3E, $6C, $EA, $62, $C1, $3E, $00, $EA, $63, $C1, $C9, $27, $26, $25, $14, $13
	db $12, $11, $10, $10, $10, $FF, $19, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $F2
	db $AF, $EA, $64, $C1, $3C, $EA, $65, $C1, $3E, $13, $EA, $50, $C1, $3E, $01, $EA
	db $68, $C1, $AF, $EA, $67, $C1, $CD, $8E, $49, $3E, $F2, $E0, $21, $3E, $80, $E0
	db $23, $3E, $6C, $EA, $60, $C1, $3E, $40, $EA, $61, $C1, $3E, $00, $EA, $62, $C1
	db $3E, $00, $EA, $63, $C1, $C9, $12, $64, $02, $37, $47, $24, $55, $71, $07, $44
	db $60, $36, $84, $82, $64, $02, $37, $47, $24, $55, $71, $07, $44, $60, $36, $86
	db $32, $FF, $3E, $21, $EA, $50, $C1, $AF, $EA, $64, $C1, $3C, $EA, $65, $C1, $3E
	db $02, $EA, $68, $C1, $AF, $EA, $67, $C1, $3E, $6C, $EA, $60, $C1, $3E, $87, $EA
	db $61, $C1, $3E, $6C, $EA, $62, $C1, $3E, $8D, $EA, $63, $C1, $C9, $03, $93, $80
	db $72, $70, $FF, $F0, $FF, $FF, $FF, $F3, $3E, $23, $EA, $50, $C1, $AF, $EA, $64
	db $C1, $3C, $EA, $65, $C1, $3E, $6C, $EA, $60, $C1, $3E, $B4, $EA, $61, $C1, $3E
	db $6C, $EA, $62, $C1, $3E, $BA, $EA, $63, $C1, $C9, $02, $41, $61, $71, $21, $FF
	db $F0, $FF, $FF, $A0, $B3, $02, $48, $AC, $FF, $FC, $53, $00, $27, $9C, $DD, $DC
	db $B7, $7B, $CD, $DD, $C9, $00, $00, $00, $00, $CD, $EF, $FD, $EC, $00, $12, $21
	db $00, $DD, $DD, $DD, $DD, $04, $8B, $DE, $FF, $ED, $CB, $A9, $87, $65, $44, $44
	db $32, $11, $24, $7A, $74, $20, $24, $68, $AC, $EC, $A8, $64, $20, $24, $68, $A8
	db $64, $20, $24, $68, $64, $0F, $00, $F0, $F0, $F0, $F0, $00, $0F, $0F, $FF, $FF
	db $00, $FF, $F0, $0F, $0F, $BB, $2B, $BB, $2B, $BB, $5B, $2B, $BB, $2B, $BB, $BB
	db $72, $27, $EB, $BB, $B0, $77, $66, $55, $44, $33, $22, $11, $00, $FF, $00, $11
	db $22, $33, $44, $55, $66, $77, $FF, $0F, $BB, $2B, $BB, $2B, $BB, $5B, $2B, $BB
	db $2B, $BB, $BB, $72, $27, $EB, $BB, $B0, $77, $66, $55, $44, $33, $22, $11, $00
	db $FF, $00, $11, $22, $33, $44, $55, $66, $77, $FF, $61, $C1, $3E, $6C, $EA, $62
	db $C1, $3E, $70, $EA, $63, $C1, $C9, $AF, $EA, $64, $C1, $3C, $EA, $65, $C1, $3E
	db $55, $EA, $68, $C1, $AF, $EA, $67, $C1, $3E, $6C, $EA, $60, $C1, $3E, $73, $EA
	db $61, $C1, $3E, $6C, $EA, $62, $C1, $3E, $70, $EA, $63, $C1, $C9, $00, $01, $02
	db $03, $04, $05, $06, $07, $08, $09, $FF, $50, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $AF, $EA, $64, $C1, $3C, $EA, $65, $C1, $3E, $01, $EA, $68, $C1, $AF
	db $EA, $67, $C1, $3E, $6D, $EA, $60, $C1, $3E, $87, $EA, $61, $C1, $3E, $6D, $EA
	db $62, $C1, $3E, $92, $EA, $63, $C1, $C9, $7A, $6F, $F4, $6D, $0B, $6E, $90, $6E
	db $1B, $6E, $1F, $6E, $2F, $6E, $5B, $6E, $6D, $6E, $A2, $6E, $CB, $6E, $B0, $6E
	db $2E, $6F, $47, $6F, $A4, $6F, $B8, $6F, $C2, $6F, $14, $6F, $06, $6F, $EA, $6E
	db $5C, $6F, $6B, $6F, $89, $6F, $95, $6F, $45, $6E, $BB, $12, $1F, $12, $79, $68
	db $6B, $63, $01, $08, $05, $60, $FD, $C0, $24, $60, $03, $C0, $65, $61, $CF, $65
	db $68, $7F, $D1, $6F, $BB, $12, $1F, $11, $79, $68, $6B, $60, $FD, $C1, $24, $2A
	db $68, $7F, $6B, $70, $68, $7F, $DA, $70, $BB, $11, $1F, $11, $79, $68, $6B, $C5
	db $95, $60, $01, $21, $68, $7F, $FE, $6F, $BB, $11, $1F, $13, $79, $BF, $71, $63
	db $01, $07, $02, $83, $02, $1E, $DE, $3E, $BC, $00, $68, $BB, $11, $1F, $11, $7A
	db $0C, $79, $8F, $71, $60, $01, $BE, $24, $66, $23, $66, $22, $66, $20, $66, $1F
	db $68, $79, $08, $6C, $BB, $10, $1F, $11, $93, $BF, $3C, $39, $3C, $39, $3C, $39
	db $65, $65, $68, $79, $F8, $6B, $7F, $9A, $70, $60, $05, $C5, $BB, $00, $00, $00
	db $21, $B6, $00, $00, $00, $22, $B6, $00, $00, $00, $23, $B1, $00, $00, $00, $24
	db $B1, $00, $00, $00, $25, $68, $79, $68, $6B, $7F, $9A, $70, $AC, $1F, $1F, $13
	db $63, $01, $14, $07, $D9, $3C, $65, $68, $79, $68, $6B, $BB, $11, $1F, $12, $BF
	db $3C, $48, $3C, $CF, $48, $68, $7F, $D1, $6F, $BB, $11, $1F, $12, $94, $7A, $03
	db $79, $CF, $71, $BF, $60, $FD, $11, $BE, $66, $C3, $60, $01, $0F, $60, $FF, $65
	db $68, $B3, $1F, $1F, $20, $63, $01, $14, $02, $7A, $FC, $79, $8F, $71, $E3, $83
	db $05, $28, $24, $BB, $11, $1F, $12, $CF, $28, $BC, $AC, $00, $00, $00, $10, $68
	db $BB, $11, $1F, $12, $93, $79, $68, $6B, $BF, $60, $04, $12, $BF, $60, $FF, $65
	db $BF, $60, $01, $65, $60, $FF, $65, $BF, $60, $01, $65, $68, $BB, $00, $00, $00
	db $79, $CF, $71, $C0, $21, $BE, $66, $CF, $21, $68, $C0, $BB, $00, $00, $00, $79
	db $78, $6B, $30, $34, $37, $B6, $00, $00, $00, $30, $34, $37, $B1, $00, $00, $00
	db $30, $34, $37, $68, $BB, $11, $23, $11, $C0, $93, $79, $F8, $6B, $2B, $2F, $32
	db $2F, $32, $37, $32, $37, $3B, $37, $3B, $3E, $43, $65, $65, $68, $7F, $62, $71
	db $79, $98, $6B, $BB, $11, $1F, $11, $7A, $0C, $60, $02, $C4, $66, $15, $17, $18
	db $17, $68, $79, $68, $6B, $BB, $00, $1F, $11, $60, $FB, $C0, $28, $60, $02, $28
	db $68, $79, $68, $6B, $BB, $00, $1F, $11, $C0, $60, $FE, $34, $60, $FB, $28, $68
	db $C0, $93, $79, $B8, $6B, $BB, $10, $1F, $12, $3C, $43, $40, $3C, $43, $68, $C9
	db $BB, $13, $1F, $11, $60, $01, $79, $68, $6B, $18, $68, $7F, $2C, $71, $BB, $11
	db $1F, $15, $79, $68, $6B, $C4, $60, $FD, $21, $68, $D9, $BB, $00, $00, $00, $79
	db $98, $6B, $63, $00, $05, $03, $83, $02, $1E, $39, $41, $BC, $39, $68, $BB, $11
	db $2F, $11, $79, $9F, $71, $C8, $3C, $68, $BF, $BB, $11, $2F, $11, $79, $9F, $71
	db $BF, $38, $BC, $66, $BF, $44, $68, $3E, $04, $EA, $50, $C1, $AF, $EA, $64, $C1
	db $3C, $EA, $65, $C1, $3E, $6F, $EA, $60, $C1, $3E, $F3, $EA, $61, $C1, $3E, $6F
	db $EA, $62, $C1, $3E, $F9, $EA, $63, $C1, $C9, $00, $53, $71, $91, $31, $FF, $F1
	db $FF, $FF, $FF, $00, $3E, $2D, $EA, $50, $C1, $AF, $EA, $64, $C1, $3C, $EA, $65
	db $C1, $3E, $70, $EA, $60, $C1, $3E, $20, $EA, $61, $C1, $3E, $70, $EA, $62, $C1
	db $3E, $46, $EA, $63, $C1, $C9, $03, $93, $80, $72, $70, $56, $54, $60, $50, $40
	db $30, $20, $10, $56, $54, $60, $50, $40, $30, $20, $10, $56, $54, $60, $50, $40
	db $30, $20, $10, $56, $54, $60, $50, $40, $30, $20, $10, $FF, $F3, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $3E, $04, $EA, $50, $C1, $AF, $EA, $64, $C1, $3C, $EA, $65, $C1, $3E, $70
	db $EA, $60, $C1, $3E, $8D, $EA, $61, $C1, $3E, $70, $EA, $62, $C1, $3E, $94, $EA
	db $63, $C1, $C9, $41, $61, $61, $41, $71, $71, $FF, $A1, $52, $00, $61, $52, $00
	db $3E, $2D, $EA, $50, $C1, $AF, $EA, $64, $C1, $3C, $EA, $65, $C1, $3E, $02, $EA
	db $68, $C1, $AF, $EA, $67, $C1, $3E, $70, $EA, $60, $C1, $3E, $C5, $EA, $61, $C1
	db $3E, $70, $EA, $62, $C1, $3E, $D0, $EA, $63, $C1, $C9, $27, $26, $25, $14, $13
	db $12, $11, $10, $10, $10, $FF, $19, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $F2
	db $AF, $EA, $64, $C1, $3C, $EA, $65, $C1, $3E, $13, $EA, $50, $C1, $3E, $01, $EA
	db $68, $C1, $AF, $EA, $67, $C1, $CD, $8E, $49, $3E, $F2, $E0, $21, $3E, $80, $E0
	db $23, $3E, $71, $EA, $60, $C1, $3E, $10, $EA, $61, $C1, $3E, $00, $EA, $62, $C1
	db $3E, $00, $EA, $63, $C1, $C9, $12, $64, $02, $37, $47, $24, $55, $71, $07, $44
	db $60, $36, $84, $82, $64, $02, $37, $47, $24, $55, $71, $07, $44, $60, $36, $86
	db $32, $FF, $3E, $21, $EA, $50, $C1, $AF, $EA, $64, $C1, $3C, $EA, $65, $C1, $3E
	db $02, $EA, $68, $C1, $AF, $EA, $67, $C1, $3E, $71, $EA, $60, $C1, $3E, $57, $EA
	db $61, $C1, $3E, $71, $EA, $62, $C1, $3E, $5D, $EA, $63, $C1, $C9, $03, $93, $80
	db $72, $70, $FF, $F0, $FF, $FF, $FF, $F3, $3E, $23, $EA, $50, $C1, $AF, $EA, $64
	db $C1, $3C, $EA, $65, $C1, $3E, $71, $EA, $60, $C1, $3E, $84, $EA, $61, $C1, $3E
	db $71, $EA, $62, $C1, $3E, $8A, $EA, $63, $C1, $C9, $02, $41, $61, $71, $21, $FF
	db $F0, $FF, $FF, $A0, $B3, $02, $48, $AC, $FF, $FC, $53, $00, $27, $9C, $DD, $DC
	db $B7, $7B, $CD, $DD, $C9, $00, $00, $00, $00, $CD, $EF, $FD, $EC, $00, $12, $21
	db $00, $DD, $DD, $DD, $DD, $04, $8B, $DE, $FF, $ED, $CB, $A9, $87, $65, $44, $44
	db $32, $11, $24, $7A, $74, $20, $24, $68, $AC, $EC, $A8, $64, $20, $24, $68, $A8
	db $64, $20, $24, $68, $64, $0F, $00, $F0, $F0, $F0, $F0, $00, $0F, $0F, $FF, $FF
	db $00, $FF, $F0, $0F, $0F, $BB, $2B, $BB, $2B, $BB, $5B, $2B, $BB, $2B, $BB, $BB
	db $72, $27, $EB, $BB, $B0, $77, $66, $55, $44, $33, $22, $11, $00, $FF, $00, $11
	db $22, $33, $44, $55, $66, $77, $FF, $87, $77, $88, $02, $87, $77, $77, $78, $88
	db $01, $87, $77, $77, $88, $04, $77, $77, $78, $88, $02, $77, $77, $77, $77, $77
	db $89, $99, $88, $01, $77, $77, $77, $77, $88, $03, $77, $77, $77, $77, $77, $78
	db $88, $04, $87, $77, $77, $88, $04, $87, $77, $77, $77, $88, $03, $87, $77, $77
	db $77, $88, $01, $89, $88, $01, $87, $77, $77, $78, $88, $02, $98, $87, $77, $77
	db $77, $88, $02, $87, $77, $77, $78, $88, $03, $77, $77, $77, $88, $02, $87, $77
	db $77, $77, $78, $88, $02, $87, $77, $77, $78, $89, $99, $98, $77, $66, $67, $78
	db $99, $98, $87, $66, $77, $77, $88, $02, $87, $77, $77, $77, $77, $88, $04, $77
	db $66, $78, $88, $03, $77, $66, $67, $88, $01, $99, $88, $01, $76, $67, $77, $88
	db $03, $87, $77, $78, $88, $04, $77, $77, $77, $77, $88, $02, $87, $77, $77, $77
	db $88, $04, $87, $78, $88, $01, $77, $78, $78, $87, $77, $87, $77, $78, $88, $01
	db $87, $77, $87, $77, $88, $02, $87, $77, $78, $88, $01, $78, $89, $87, $77, $77
	db $88, $03, $77, $77, $88, $01, $87, $77, $88, $02, $77, $77, $88, $01, $87, $88
	db $03, $87, $77, $77, $88, $03, $78, $77, $77, $78, $88, $03, $87, $77, $77, $77
	db $78, $88, $04, $77, $77, $77, $88, $01, $89, $88, $01, $77, $77, $77, $87, $78
	db $88, $01, $77, $77, $78, $88, $02, $87, $77, $77, $88, $04, $76, $67, $78, $88
	db $01, $78, $88, $01, $87, $77, $78, $88, $02, $77, $88, $01, $77, $77, $78, $88
	db $03, $77, $77, $88, $01, $87, $78, $88, $01, $87, $77, $77, $87, $88, $03, $77
	db $77, $78, $88, $04, $87, $77, $77, $77, $78, $88, $01, $77, $78, $88, $01, $87
	db $77, $77, $78, $99, $87, $77, $77, $77, $77, $88, $02, $77, $77, $77, $77, $88
	db $02, $87, $78, $88, $01, $77, $88, $01, $87, $76, $78, $88, $01, $87, $77, $77
	db $77, $78, $88, $02, $77, $77, $77, $88, $02, $77, $77, $88, $04, $77, $77, $77
	db $88, $04, $77, $77, $77, $77, $78, $88, $01, $77, $78, $88, $01, $87, $78, $88
	db $01, $87, $77, $78, $88, $03, $77, $77, $77, $78, $88, $01, $89, $87, $77, $67
	db $78, $89, $98, $88, $01, $77, $66, $77, $88, $03, $87, $76, $67, $77, $88, $02
	db $99, $87, $77, $77, $88, $03, $87, $77, $67, $77, $88, $02, $77, $77, $77, $78
	db $88, $01, $98, $88, $02, $77, $77, $77, $88, $03, $87, $76, $67, $87, $88, $03
	db $87, $77, $88, $02, $87, $77, $77, $77, $77, $78, $88, $02, $77, $77, $78, $88
	db $01, $78, $88, $02, $87, $77, $77, $78, $87, $78, $87, $88, $01, $78, $88, $01
	db $87, $78, $88, $03, $87, $77, $77, $77, $78, $88, $02, $87, $77, $77, $78, $89
	db $98, $87, $77, $77, $77, $88, $02, $76, $77, $77, $78, $78, $88, $01, $77, $77
	db $78, $88, $03, $77, $77, $77, $77, $78, $88, $01, $87, $77, $77, $77, $77, $78
	db $88, $03, $77, $77, $78, $88, $03, $87, $66, $77, $89, $88, $01, $77, $88, $01
	db $77, $77, $88, $01, $98, $87, $77, $77, $77, $88, $02, $87, $77, $77, $77, $88
	db $02, $87, $77, $88, $02, $87, $77, $77, $78, $88, $01, $87, $77, $77, $78, $88
	db $01, $89, $98, $77, $77, $78, $88, $03, $77, $77, $77, $77, $77, $77, $88, $01
	db $98, $87, $77, $78, $88, $04, $77, $77, $77, $77, $77, $77, $78, $88, $02, $87
	db $77, $77, $78, $88, $03, $87, $77, $77, $78, $88, $01, $78, $88, $02, $77, $77
	db $88, $02, $77, $77, $88, $01, $77, $77, $77, $78, $88, $01, $77, $88, $06, $87
	db $77, $88, $03, $77, $77, $77, $77, $88, $03, $87, $77, $77, $78, $88, $01, $87
	db $77, $77, $78, $88, $02, $87, $77, $77, $78, $78, $89, $88, $01, $87, $77, $77
	db $77, $88, $03, $77, $77, $77, $77, $88, $01, $77, $88, $01, $87, $77, $78, $88
	db $01, $77, $77, $77, $88, $03, $87, $77, $77, $78, $88, $02, $87, $77, $77, $88
	db $03, $87, $77, $77, $78, $88, $02, $87, $77, $77, $77, $78, $88, $02, $86, $67
	db $78, $78, $88, $02, $87, $77, $78, $88, $03, $77, $77, $78, $88, $01, $78, $88
	db $01, $78, $87, $77, $77, $78, $88, $02, $87, $77, $77, $77, $78, $88, $02, $87
	db $77, $77, $78, $88, $01, $87, $77, $88, $03, $78, $88, $01, $77, $77, $88, $05
	db $77, $77, $77, $77, $88, $02, $87, $77, $77, $77, $88, $03, $87, $77, $77, $88
	db $03, $87, $77, $77, $77, $88, $02, $77, $77, $77, $77, $88, $02, $87, $77, $77
	db $78, $88, $02, $87, $77, $77, $78, $88, $01, $77, $77, $77, $88, $01, $87, $77
	db $78, $88, $04, $87, $77, $77, $78, $88, $03, $87, $77, $88, $01, $77, $88, $01
	db $77, $78, $88, $02, $87, $88, $01, $77, $77, $77, $88, $06, $77, $77, $88, $01
	db $77, $88, $01, $87, $77, $77, $87, $77, $78, $88, $01, $87, $77, $77, $78, $88
	db $03, $77, $77, $77, $78, $88, $02, $77, $77, $77, $88, $03, $78, $88, $02, $77
	db $88, $01, $77, $88, $01, $77, $77, $77, $78, $88, $02, $77, $78, $77, $77, $88
	db $04, $77, $77, $77, $77, $78, $88, $01, $77, $77, $88, $04, $87, $77, $88, $02
	db $77, $88, $01, $87, $77, $77, $77, $77, $88, $03, $77, $77, $77, $78, $88, $02
	db $77, $77, $77, $78, $88, $02, $77, $77, $78, $88, $04, $77, $78, $77, $88, $01
	db $77, $78, $88, $01, $87, $77, $77, $88, $03, $87, $77, $78, $88, $03, $77, $76
	db $77, $88, $02, $87, $77, $77, $77, $88, $02, $87, $77, $77, $77, $88, $02, $77
	db $77, $77, $77, $77, $88, $02, $87, $77, $77, $88, $04, $77, $77, $77, $88, $03
	db $77, $77, $77, $78, $88, $02, $77, $78, $88, $01, $77, $77, $77, $77, $77, $88
	db $03, $77, $77, $77, $77, $88, $03, $77, $77, $77, $88, $03, $77, $77, $77, $88
	db $02, $77, $77, $78, $88, $02, $87, $77, $77, $77, $78, $88, $02, $77, $77, $77
	db $78, $88, $03, $77, $77, $67, $78, $88, $03, $77, $77, $77, $88, $03, $77, $77
	db $77, $88, $01, $87, $77, $77, $77, $78, $88, $02, $87, $78, $77, $77, $77, $78
	db $88, $03, $77, $77, $77, $88, $03, $87, $77, $77, $78, $88, $03, $87, $77, $77
	db $88, $03, $87, $77, $77, $88, $03, $77, $77, $77, $88, $03, $87, $77, $77, $88
	db $03, $87, $77, $77, $77, $88, $03, $77, $77, $78, $77, $77, $88, $04, $77, $77
	db $78, $88, $01, $87, $77, $77, $77, $88, $03, $77, $77, $77, $88, $03, $87, $77
	db $77, $88, $03, $77, $77, $77, $78, $88, $03, $87, $77, $78, $88, $02, $87, $77
	db $77, $77, $78, $88, $01, $77, $88, $01, $77, $88, $05, $77, $77, $78, $88, $01
	db $87, $78, $77, $77, $77, $77, $88, $05, $77, $77, $77, $88, $03, $77, $77, $77
	db $77, $78, $88, $03, $78, $77, $77, $77, $88, $02, $77, $77, $77, $77, $78, $88
	db $02, $78, $77, $88, $02, $87, $77, $77, $88, $03, $87, $77, $77, $78, $88, $02
	db $87, $78, $88, $01, $77, $77, $78, $77, $78, $88, $01, $87, $77, $77, $78, $88
	db $01, $87, $77, $88, $04, $77, $77, $77, $88, $03, $77, $77, $77, $88, $05, $87
	db $88, $03, $77, $77, $77, $78, $88, $02, $77, $78, $88, $01, $78, $88, $02, $77
	db $78, $88, $01, $78, $88, $01, $87, $77, $77, $77, $77, $88, $02, $87, $77, $88
	db $03, $87, $77, $77, $78, $88, $02, $87, $77, $77, $77, $88, $03, $87, $77, $77
	db $88, $03, $87, $77, $77, $78, $88, $03, $87, $77, $77, $88, $03, $77, $77, $77
	db $88, $02, $87, $77, $77, $88, $01, $87, $88, $03, $87, $78, $77, $78, $87, $88
	db $01, $87, $88, $01, $77, $77, $77, $88, $03, $77, $77, $77, $77, $88, $03, $77
	db $77, $77, $88, $03, $77, $77, $77, $88, $03, $77, $77, $77, $77, $88, $02, $87
	db $77, $77, $77, $88, $04, $77, $77, $88, $02, $87, $78, $87, $77, $77, $78, $88
	db $01, $77, $77, $78, $77, $78, $88, $03, $77, $77, $77, $77, $88, $02, $77, $77
	db $77, $78, $88, $03, $77, $77, $78, $88, $03, $77, $77, $77, $88, $03, $77, $77
	db $77, $78, $88, $02, $87, $77, $87, $77, $77, $77, $88, $02, $77, $88, $01, $78
	db $88, $03, $77, $77, $77, $87, $78, $88, $01, $87, $77, $77, $77, $77, $88, $03
	db $87, $77, $77, $88, $03, $87, $77, $77, $77, $88, $04, $77, $77, $77, $88, $01
	db $78, $88, $01, $77, $77, $78, $88, $03, $77, $77, $78, $88, $03, $77, $77, $77
	db $88, $07, $77, $77, $78, $88, $02, $77, $78, $87, $77, $88, $03, $77, $77, $88
	db $01, $87, $77, $77, $88, $01, $87, $77, $77, $77, $77, $88, $01, $78, $88, $03
	db $87, $78, $77, $77, $88, $02, $87, $78, $87, $77, $77, $88, $02, $77, $88, $04
	db $77, $77, $78, $88, $01, $77, $77, $77, $77, $77, $88, $01, $77, $77, $88, $02
	db $78, $88, $01, $77, $77, $88, $02, $77, $77, $77, $88, $03, $77, $77, $78, $88
	db $02, $87, $77, $77, $88, $01, $77, $78, $88, $01, $87, $77, $78, $77, $78, $88
	db $02, $87, $77, $77, $78, $88, $02, $77, $77, $77, $78, $88, $01, $87, $77, $77
	db $88, $04, $87, $77, $77, $88, $03, $87, $77, $77, $78, $88, $03, $77, $77, $78
	db $88, $02, $87, $77, $77, $77, $88, $02, $87, $77, $77, $78, $88, $02, $87, $77
	db $77, $78, $88, $01, $77, $88, $01, $78, $87, $77, $87, $77, $88, $02, $87, $77
	db $77, $78, $88, $02, $77, $77, $77, $78, $88, $01, $87, $77, $78, $88, $03, $77
	db $77, $78, $88, $03, $87, $77, $78, $88, $04, $77, $77, $78, $88, $03, $77, $77
	db $78, $88, $01, $77, $78, $87, $77, $88, $02, $77, $78, $87, $77, $77, $88, $02
	db $77, $77, $77, $88, $03, $77, $77, $78, $88, $02, $87, $77, $78, $87, $88, $03
	db $77, $77, $77, $78, $88, $03, $77, $77, $77, $88, $02, $87, $77, $77, $88, $03
	db $87, $77, $77, $77, $88, $03, $77, $77, $77, $77, $88, $04, $77, $77, $77, $88
	db $02, $87, $77, $78, $88, $01, $77, $88, $01, $77, $78, $77, $88, $01, $87, $88
	db $01, $77, $77, $88, $04, $87, $77, $77, $77, $88, $03, $87, $77, $77, $88, $02
	db $87, $77, $77, $88, $03, $77, $77, $77, $88, $02, $87, $77, $77, $78, $88, $03
	db $77, $77, $88, $03, $77, $77, $77, $78, $88, $03, $77, $77, $77, $77, $88, $03
	db $77, $77, $77, $88, $03, $87, $77, $77, $88, $03, $87, $77, $77, $88, $03, $77
	db $77, $78, $88, $03, $87, $77, $77, $88, $03, $87, $77, $77, $77, $88, $02, $87
	db $77, $77, $77, $88, $02, $87, $77, $88, $02, $87, $88, $01, $77, $77, $77, $88
	db $04, $78, $77, $88, $01, $77, $78, $88, $02, $77, $77, $78, $88, $01, $77, $77
	db $88, $01, $77, $88, $02, $87, $77, $77, $78, $88, $02, $77, $77, $78, $88, $02
	db $77, $77, $77, $88, $03, $77, $77, $88, $01, $77, $77, $77, $77, $78, $88, $02
	db $87, $77, $77, $88, $02, $77, $78, $88, $01, $87, $77, $88, $01, $77, $77, $78
	db $87, $78, $77, $78, $88, $02, $87, $77, $77, $77, $88, $03, $77, $77, $77, $77
	db $88, $03, $87, $77, $77, $88, $02, $87, $77, $77, $77, $78, $88, $02, $77, $77
	db $77, $78, $88, $03, $77, $77, $78, $88, $02, $77, $78, $77, $78, $88, $02, $77
	db $78, $88, $03, $77, $77, $78, $88, $02, $87, $77, $77, $78, $88, $04, $77, $78
	db $88, $02, $87, $78, $87, $77, $77, $78, $88, $02, $77, $77, $77, $88, $03, $87
	db $77, $77, $78, $88, $01, $78, $87, $77, $77, $78, $88, $02, $87, $77, $77, $88
	db $01, $87, $77, $77, $77, $77, $88, $02, $77, $77, $77, $88, $03, $77, $78, $88
	db $02, $87, $77, $77, $77, $77, $88, $01, $77, $87, $77, $88, $02, $87, $78, $77
	db $88, $01, $87, $77, $78, $88, $02, $87, $77, $77, $77, $88, $02, $87, $77, $77
	db $78, $88, $03, $77, $77, $78, $88, $02, $87, $87, $77, $77, $77, $88, $02, $87
	db $77, $77, $77, $78, $88, $02, $87, $77, $77, $78, $88, $02, $77, $77, $77, $88
	db $01, $87, $88, $02, $77, $77, $77, $78, $88, $02, $87, $77, $77, $88, $03, $87
	db $77, $77, $78, $88, $02, $77, $77, $77, $78, $88, $03, $77, $77, $78, $88, $02
	db $77, $88, $01, $77, $77, $88, $01, $87, $77, $78, $88, $01, $87, $78, $88, $01
	db $77, $88, $03, $77, $88, $01, $77, $88, $01, $77, $77, $77, $88, $02, $77, $77
	db $78, $88, $03, $77, $77, $78, $88, $02, $87, $77, $77, $88, $02, $87, $77, $77
	db $78, $88, $02, $77, $78, $77, $77, $88, $03, $77, $77, $77, $78, $88, $02, $77
	db $77, $77, $88, $02, $87, $77, $88, $01, $77, $78, $88, $02, $77, $88, $01, $77
	db $88, $01, $87, $77, $78, $77, $88, $01, $77, $88, $01, $87, $77, $88, $02, $77
	db $88, $02, $87, $77, $78, $88, $01, $78, $88, $01, $87, $88, $01, $77, $77, $78
	db $88, $02, $77, $77, $77, $77, $88, $02, $77, $77, $78, $88, $03, $87, $77, $77
	db $88, $02, $87, $77, $77, $77, $88, $03, $87, $77, $88, $01, $78, $88, $02, $77
	db $78, $88, $02, $77, $87, $77, $77, $78, $88, $02, $87, $88, $01, $77, $77, $77
	db $88, $03, $87, $77, $77, $78, $88, $02, $87, $77, $77, $77, $88, $03, $77, $78
	db $87, $78, $77, $78, $88, $01, $87, $78, $88, $01, $87, $77, $78, $88, $01, $78
	db $87, $77, $77, $77, $78, $87, $88, $01, $87, $78, $88, $05, $87, $77, $78, $88
	db $02, $77, $77, $77, $77, $77, $88, $01, $78, $88, $01, $87, $88, $01, $87, $77
	db $77, $78, $88, $03, $87, $77, $77, $88, $05, $77, $77, $77, $77, $88, $03, $77
	db $77, $78, $88, $02, $87, $77, $77, $78, $88, $02, $77, $77, $77, $78, $77, $77
	db $88, $02, $87, $77, $77, $87, $77, $88, $02, $87, $77, $77, $77, $88, $03, $77
	db $78, $77, $88, $03, $77, $77, $77, $77, $88, $02, $77, $78, $77, $77, $88, $02
	db $78, $88, $01, $87, $77, $78, $88, $03, $77, $77, $77, $88, $03, $87, $77, $77
	db $77, $88, $03, $77, $77, $77, $88, $03, $77, $77, $77, $88, $03, $77, $77, $78
	db $88, $03, $77, $77, $78, $87, $78, $87, $88, $01, $87, $77, $88, $01, $87, $88
	db $03, $87, $77, $88, $01, $77, $88, $02, $87, $77, $78, $78, $88, $03, $87, $77
	db $88, $01, $77, $88, $03, $77, $77, $77, $88, $03, $87, $77, $77, $88, $01, $78
	db $88, $02, $87, $77, $87, $77, $87, $78, $88, $01, $77, $77, $77, $78, $88, $02
	db $77, $77, $77, $88, $03, $77, $77, $77, $87, $78, $88, $02, $87, $77, $77, $77
	db $88, $03, $77, $77, $77, $88, $03, $87, $77, $77, $78, $88, $02, $77, $77, $77
	db $77, $78, $88, $02, $87, $77, $77, $88, $04, $87, $77, $77, $78, $87, $87, $88
	db $01, $87, $77, $78, $88, $01, $87, $77, $88, $02, $77, $78, $88, $03, $77, $77
	db $77, $77, $78, $88, $01, $87, $77, $78, $77, $77, $88, $02, $78, $88, $01, $77
	db $78, $88, $02, $78, $87, $77, $77, $78, $88, $02, $77, $77, $77, $78, $88, $02
	db $77, $77, $77, $78, $88, $02, $87, $78, $87, $77, $88, $01, $77, $77, $88, $02
	db $87, $77, $77, $78, $88, $02, $87, $87, $77, $77, $78, $88, $02, $78, $77, $77
	db $77, $78, $88, $02, $87, $87, $77, $77, $88, $03, $87, $77, $77, $78, $87, $77
	db $88, $01, $78, $87, $87, $87, $88, $02, $87, $77, $77, $88, $03, $77, $77, $78
	db $88, $03, $87, $77, $77, $88, $04, $77, $77, $77, $78, $88, $04, $78, $77, $77
	db $77, $88, $03, $77, $77, $77, $88, $04, $77, $77, $88, $01, $77, $88, $02, $87
	db $77, $77, $88, $03, $87, $77, $77, $78, $88, $02, $87, $77, $77, $78, $88, $02
	db $77, $77, $77, $77, $88, $03, $77, $78, $77, $87, $78, $88, $01, $87, $77, $77
	db $78, $88, $02, $87, $77, $78, $88, $03, $77, $77, $78, $88, $03, $78, $77, $77
	db $77, $78, $88, $03, $87, $77, $77, $78, $88, $03, $77, $77, $77, $88, $02, $77
	db $77, $78, $88, $01, $87, $87, $77, $78, $78, $88, $02, $77, $78, $77, $77, $78
	db $88, $01, $77, $88, $01, $77, $78, $77, $88, $03, $87, $77, $78, $88, $01, $77
	db $77, $77, $77, $77, $88, $02, $87, $77, $77, $78, $88, $03, $77, $77, $77, $77
	db $88, $03, $78, $77, $77, $77, $88, $01, $77, $78, $88, $02, $77, $77, $77, $78
	db $88, $02, $87, $77, $77, $77, $88, $02, $87, $77, $77, $78, $88, $01, $87, $77
	db $77, $77, $88, $03, $77, $77, $77, $88, $02, $87, $78, $87, $77, $78, $78, $88
	db $01, $77, $87, $87, $77, $78, $88, $02, $78, $77, $77, $77, $88, $01, $87, $77
	db $77, $77, $88, $04, $77, $78, $77, $78, $88, $02, $87, $77, $77, $77, $77, $78
	db $87, $78, $88, $01, $87, $88, $01, $87, $77, $78, $88, $04, $87, $77, $77, $77
	db $88, $01, $87, $77, $88, $02, $77, $78, $88, $01, $78, $88, $02, $87, $77, $77
	db $88, $01, $87, $77, $77, $88, $03, $77, $77, $78, $88, $03, $77, $77, $77, $88
	db $03, $77, $77, $77, $88, $03, $77, $77, $78, $88, $03, $87, $77, $77, $88, $04
	db $77, $77, $78, $88, $03, $87, $77, $77, $77, $88, $02, $78, $88, $01, $77, $78
	db $78, $88, $02, $77, $77, $87, $88, $02, $77, $88, $01, $77, $78, $78, $78, $87
	db $88, $01, $78, $88, $01, $78, $87, $88, $01, $77, $77, $88, $02, $87, $77, $87
	db $77, $88, $02, $87, $88, $01, $78, $88, $01, $87, $78, $77, $78, $88, $02, $87
	db $87, $77, $78, $88, $02, $77, $77, $87, $88, $02, $77, $87, $77, $78, $78, $88
	db $01, $77, $77, $77, $88, $02, $87, $78, $78, $88, $04, $77, $77, $77, $88, $03
	db $87, $77, $77, $78, $88, $03, $77, $77, $77, $88, $03, $77, $77, $77, $77, $88
	db $03, $77, $77, $87, $78, $78, $88, $01, $78, $78, $78, $77, $77, $88, $02, $87
	db $77, $77, $88, $03, $87, $77, $77, $77, $88, $02, $77, $88, $01, $77, $77, $78
	db $78, $78, $87, $77, $88, $01, $77, $77, $78, $88, $01, $87, $87, $77, $78, $88
	db $02, $87, $87, $77, $77, $88, $02, $77, $77, $78, $88, $01, $77, $88, $01, $77
	db $78, $88, $02, $87, $87, $77, $78, $88, $01, $77, $77, $77, $88, $03, $77, $77
	db $77, $88, $04, $78, $77, $77, $78, $88, $02, $77, $77, $77, $78, $88, $02, $78
	db $77, $87, $78, $88, $01, $87, $77, $78, $77, $78, $88, $01, $78, $87, $77, $77
	db $78, $88, $04, $77, $78, $88, $01, $78, $78, $88, $01, $78, $78, $77, $88, $01
	db $77, $77, $77, $88, $02, $87, $77, $77, $78, $88, $01, $87, $88, $01, $77, $77
	db $77, $88, $03, $77, $77, $77, $88, $03, $87, $77, $78, $78, $88, $01, $77, $87
	db $77, $88, $03, $77, $87, $77, $78, $88, $03, $87, $77, $77, $78, $88, $01, $87
	db $87, $77, $77, $88, $01, $77, $88, $02, $77, $77, $77, $87, $88, $03, $77, $77
	db $77, $88, $03, $87, $77, $77, $78, $88, $02, $87, $77, $78, $78, $87, $88, $01
	db $77, $77, $77, $88, $01, $78, $88, $03, $77, $87, $77, $88, $02, $77, $77, $77
	db $88, $01, $78, $88, $01, $87, $77, $77, $88, $03, $87, $77, $77, $88, $01, $78
	db $88, $01, $77, $78, $77, $88, $01, $87, $77, $77, $87, $88, $02, $78, $77, $77
	db $87, $88, $03, $87, $87, $87, $77, $78, $87, $77, $78, $78, $88, $03, $87, $77
	db $78, $88, $02, $87, $77, $77, $87, $88, $03, $77, $77, $78, $78, $78, $87, $87
	db $87, $77, $77, $78, $87, $88, $02, $78, $77, $77, $88, $02, $78, $77, $77, $88
	db $01, $87, $87, $87, $77, $87, $87, $87, $87, $77, $77, $87, $88, $02, $77, $77
	db $77, $88, $02, $87, $87, $77, $78, $78, $78, $87, $87, $77, $87, $87, $88, $01
	db $87, $87, $87, $77, $87, $87, $88, $02, $78, $77, $77, $88, $01, $78, $88, $02
	db $78, $77, $77, $88, $01, $87, $87, $77, $78, $87, $88, $03, $77, $77, $77, $88
	db $03, $77, $87, $77, $78, $78, $88, $01, $87, $77, $78, $78, $78, $87, $87, $77
	db $87, $88, $02, $87, $87, $77, $87, $88, $02, $87, $87, $77, $78, $78, $78, $77
	db $88, $01, $78, $77, $78, $78, $78, $88, $06, $87, $87, $78, $77, $87, $87, $87
	db $77, $87, $77, $88, $02, $78, $77, $77, $78, $78, $78, $88, $01, $78, $77, $77
	db $87, $88, $02, $87, $87, $77, $77, $87, $88, $02, $87, $77, $77, $87, $88, $02
	db $78, $78, $77, $77, $87, $87, $87, $78, $78, $77, $78, $77, $87, $78, $78, $88
	db $03, $78, $77, $88, $03, $78, $77, $78, $77, $78, $78, $78, $77, $77, $87, $88
	db $02, $87, $87, $87, $78, $78, $77, $87, $77, $78, $78, $88, $01, $87, $87, $77
	db $77, $87, $88, $02, $78, $77, $77, $87, $88, $02, $87, $88, $01, $77, $78, $87
	db $88, $02, $78, $77, $77, $88, $01, $78, $88, $03, $78, $87, $87, $78, $87, $78
	db $78, $78, $77, $77, $78, $77, $88, $01, $87, $87, $77, $87, $87, $77, $87, $78
	db $77, $77, $87, $77, $87, $87
