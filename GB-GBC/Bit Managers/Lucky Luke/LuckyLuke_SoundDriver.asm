; =====================================================================
; Lucky Luke (E) (M4) - Game Boy
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o luckyluke.o LuckyLuke_SoundDriver.asm
;   rgblink -o luckyluke.gb luckyluke.o
;   python tools/cmp_banked.py luckyluke.gb "Lucky Luke (E) (M4) [M].gb" 12:4000-7FFF
; (driver and data fill ROM bank 12; the linked file only matches in that range)
;
; Documentation: LuckyLuke_SoundDriver.md / AJG_SoundEngine_Family.md
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
MACRO REPEAT    ; play the following bytes n times (up to REPEAT_END), n = 2-17
	db $EE + \1
ENDM
MACRO LEN       ; note length in ticks, 1-48
	db $BF + \1
ENDM
MACRO VOLENV    ; start volume + envelope (CH3/SFX): atk (lo=count hi=step), dec (lo=count hi=step), rates (hi=atk lo=dec)
	db $B0 + \1, \2, \3, \4
ENDM
MACRO INSTR     ; instrument n = entry n + 1 of the current instrument table
	db $85 + \1
ENDM
MACRO ARP       ; arpeggio n of the current arpeggio table
	db $94 + \1
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
DEF DRUM_TEMPO EQU $BF         ; + n: one step every n ticks
DEF DRUM_LOOP EQU $FF           ; restart the pattern

; ---- RAM / HRAM ----
DEF wCh1 EQU $DB00
DEF wPaused EQU $DB42
DEF wStereo EQU $DB43
DEF wShNR32 EQU $DB44
DEF wInInstr EQU $DB45
DEF wNoisePan EQU $DB46
DEF wDrumHold EQU $DB47
DEF wInstrTable EQU $DB48
DEF wInstrTableHi EQU $DB49
DEF wArpTable EQU $DB4A
DEF wArpTableHi EQU $DB4B
DEF wMusicWave EQU $DB4C
DEF wMusicWaveHi EQU $DB4D
DEF wNoiseAutoPan EQU $DB4E
DEF wDrumPatHi EQU $DB4F
DEF wDrumPat EQU $DB50
DEF wDrumPos EQU $DB51
DEF wDrumsOn EQU $DB52
DEF wDrumTempo EQU $DB53
DEF wDrumTimer EQU $DB54
DEF wDrumLoopCount EQU $DB55
DEF wDrumLoopPos EQU $DB56
DEF wNoise43Hi EQU $DB57
DEF wNoise43 EQU $DB58
DEF wNoise42Hi EQU $DB59
DEF wNoise42 EQU $DB5A
DEF wNoisePos EQU $DB5B
DEF wNoiseOn EQU $DB5C
DEF wNoiseAtten EQU $DB5D
DEF wNoiseTimer EQU $DB5E
DEF wNoiseSpeed EQU $DB5F
DEF wFadeTable EQU $DB60
DEF wFadeTableHi EQU $DB61
DEF wFadePos EQU $DB62
DEF wFadeTimer EQU $DB63
DEF wFadeSpeed EQU $DB64
DEF wFadeOn EQU $DB65
DEF wCh2 EQU $DC00
DEF wCh3 EQU $DD00
DEF wSfx EQU $DE00

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


SECTION "SoundDriver", ROMX[$4000], BANK[12]


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
	jp SndUpdate                       ; SndUpdate
	jp SndPause                        ; SndPause
	jp SndResume                       ; SndResume
	jp StopAll                         ; StopAll
	jp PlaySfxEntry                    ; PlaySfx (A = id)
	jp SndInit                         ; SndInit
	jp SongFadeIn                      ; SongFadeIn (A = speed)
	jp SongFadeOut                     ; SongFadeOut (A = speed)
	jp PlaySong1                       ; song 1
	jp PlaySong2                       ; song 2
	jp PlaySong3                       ; song 3
	jp PlaySong4                       ; song 4
	jp PlaySong5                       ; song 5
	jp PlaySong6                       ; song 6
	jp PlaySong7                       ; song 7
	jp PlaySong8                       ; song 8
	jp PlaySong9                       ; song 9
	jp PlaySong10                      ; song 10
	jp PlaySong11                      ; song 11
	jp PlaySong12                      ; song 12
	jp PlaySong13                      ; song 13
	jp PlaySong14                      ; song 14
	jp PlaySong15                      ; song 15
	jp PlaySong16                      ; song 16
	jp PlaySong17                      ; song 17
PlaySfxEntry2:
	jp PlaySfx                         ; PlaySfxNow (A = id; the same code as PlaySfx)

; SndResume: wPaused = 0, reload the music wave.
SndResume:
	xor a
	ld [wPaused], a
	jp RestoreMusicWave

; SndPause: silence CH1, CH2, CH4 (and CH3 unless an SFX plays), wPaused = 1.
; While paused only the SFX page is ticked and output.
SndPause:
	xor a
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR42], a
	inc a
	ld [wPaused], a
	ld a, [$DE27]
	and a
	jr nz, PauseTrigger
	xor a
	ldh [rNR32], a
PauseTrigger:
	ld a, $80
	ldh [rNR14], a
	ldh [rNR24], a
	ldh [rNR44], a
	ld a, [$DE27]
	and a
	ret nz
	ld a, $80
	ldh [rNR34], a
	ret

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

; SndUpdate (once per frame): tick the four pages (or only the SFX page while paused),
; drums + noise sequence, output, NR51, then the NR50 fade.
SndUpdate:
	ld a, [wPaused]
	and a
	jp nz, UpdatePaused
	ld h, $DB
	call ChannelTick
	inc h
	call ChannelTick
	inc h
	call ChannelTick
	inc h
	call ChannelTick
	call DrumTick

; Output, pulse pages: NRx3 = period low + pitch offset; when the high byte changed
; or the envelope flag ($33) is set: with the flag NRx2 = field $32 and NRx4 =
; high | $80, else NRx4 = high. (Obelix GBC's duty shadows are gone: duty goes
; straight to NR11/NR21.)
OutputCh1:
	ld hl, $DB25
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
	ld hl, $DE27
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
	ld a, [hli]
	add a, e
	ldh [rNR33], a
	ld a, [hli]
	adc a, d
	cp [hl]
	jr z, WriteCh3Vol
	ldh [rNR34], a
	ld [hl], a
WriteCh3Vol:
	inc l
	ld a, [hl]
	add a, $CB
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
	ld hl, $DB38
	ld c, [hl]
	inc h
	ld a, [hl]
	rlc a
	or c
	ld c, a
	inc h
	ld a, [$DE27]
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
	ld h, $DE
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
	cp $50
	jr c, SetPeriod
	xor a
SetPeriod:
	add a, a
	ld c, a
	ld b, $48
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
	jr z, UpdatePeriod
	inc [hl]
	ld l, $0E
	ld [hl], a
	jr UpdatePeriod

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

; Note on. The direction bit (b4, vibrato/slides) is always cleared, as in Prisoners
; of the Sun (Spirou tests bit 4 of the vibrato delay here).
NoteOn:
	ld l, $02
	ld [hl], e
	inc l
	ld [hl], d
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
	cp $DD
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
	sub $EE
	ld l, $39
	ld [hli], a
	ld [hl], e
	inc l
	ld [hl], d
	jp ReadByte

; StreamCommand: REPEAT / LEN / VOLENV / ARP / INSTR ranges, else CmdTable.
StreamCommand:
	cp $F0
	jr nc, Cmd_Repeat
	cp $C0
	jr nc, Cmd_Len
	cp $B0
	jr nc, Cmd_VolEnv
	cp $94
	jr nc, Cmd_Arp
	cp $85
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
	sub $BF
	ld l, $09
	ld [hl], a
	jp ReadStream

; VOLENV v, atk, dec, rates: start volume v; attack = lo nibble steps of hi nibble;
; decay likewise; rates hi = ticks per attack step, lo = ticks per decay step.
; Only the CH3 and SFX pages use it.
Cmd_VolEnv:
	sub $B0
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

; Not reached: SetVolEnvBC, VOLENV from the four bytes at BC (start volume,
; attack, decay, rates), then ret. A helper for NOTE_HOOK routines; nothing in
; this game uses it.
Unused_SetVolEnvBC:
	db $0A, $03, $2E, $16, $77, $0A, $03, $2E, $10, $77, $0A, $03, $2E, $13, $77, $0A
	db $CB, $37, $E6, $0F, $2E, $18, $22, $77, $0A, $E6, $0F, $2E, $1A, $22, $77, $2E
	db $17, $77, $AF, $2E, $11, $77, $C9

; ARP n: arpeggio n of wArpTable.
Cmd_Arp:
	sub $94
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
	cp $DD
	jr nc, InstrLookup
	cp $DB
	jr nz, InstrDutyCh2
	ld a, $80
	ldh [rNR11], a
	jr InstrLookup
InstrDutyCh2:
	ld a, $80
	ldh [rNR21], a
InstrLookup:
	ld a, b
	sub $84
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

; CheckRelease (RELEASE t, env; t = min length (hi) / ticks left (lo)): skipped for
; notes shorter than the minimum; on the tick where ticks left = lo nibble, unless
; the next byte is WAIT: pulse NRx2 = env; CH3/SFX page: decay rate = env & $0F and,
; if env >> 4 is not 0, volume = env >> 4.
CheckRelease:
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
	cp $DD
	jr z, ReleaseCh3
	cp $DE
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
	ld [$DD1B], a
	ld [$DD1A], a
	ld a, [hl]
	and $F0
	swap a
	jr z, SetReleased
	ld [$DD08], a
	jr SetReleased
ReleaseSfx:
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
	cp $DD
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
	ld h, $DB
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
	cp $DE
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
	ld [$DE27], a
	ld [$DE08], a
	ld [wNoiseTimer], a
	ld [wNoiseSpeed], a
	dec a
	ld [wShNR32], a
	jp RestoreMusicWave
Cmd_Transpose:
	ld a, [de]
	ld [$DB0F], a
	ld [$DC0F], a
	ld [$DD0F], a
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
	cp $DB
	jr nz, SetDutyCh2
	ld a, l
	ldh [rNR11], a
	ret
SetDutyCh2:
	ld a, l
	ldh [rNR21], a
	ret

; StartFade (A = speed, HL = table) / FADE speed, table: one byte into NR50 every
; speed + 1 ticks; $6A loops, $FF ends. (No music-wave reload, no $80 byte.)
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
FadeStop:
	xor a
	ld [wFadeOn], a
	ret

; DoFade: while no fade runs, NR50 is forced back to $77 unless it is 0.
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
	cp $DD
	jr nz, LoadWave
	ld a, [de]
	inc de
	ld [wMusicWave], a
	ld a, [de]
	ld [wMusicWaveHi], a
	ld a, [$DE27]
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
	ld a, $80
	ld [$DD07], a
	ldh [rNR30], a
	ldh [rNR34], a
	ret

; Unreferenced (89 bytes)
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
	cp $DD
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

; StartMusicChN (de = order list): reset the page, mark it active, start its first
; pattern. StartMusicCh3 also stops the fade and the drums and sets NR50 = $77.
StartMusicCh1:
	ld h, $DB
	jr StartMusicCh
StartMusicCh2:
	ld h, $DC
	jr StartMusicCh
StartMusicCh3:
	ld h, $DD
	xor a
	ld [wFadeOn], a
	ld [wDrumsOn], a
	ld a, $77
	ldh [rNR50], a
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

; API entry for PlaySfx: jumps to the last slot of the API table (PlaySfxEntry2),
; which jumps to PlaySfx.
PlaySfxEntry:
	jp PlaySfxEntry2

; PlaySfx (A = id): no priority test; reset the SFX page and start the stream. Both
; API SFX entries lead here, through the jp at the end of the API table.
PlaySfx:
	ld [$DE27], a
	ld c, a
	ld a, $11
	ld [$DE38], a
	xor a
	ld [$DE04], a
	ld [$DE0B], a
	ld [$DE2F], a
	ld [$DE2C], a
	ld [$DE0E], a
	inc a
	ld [$DE0A], a
	ld a, $F4
	ld [$DE0D], a
	ld a, c
	ld de, $DE02
	add a, a
	add a, $7C
	ld l, a
	adc a, $77
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
	cp $C0
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
	add a, $F1
	ld l, a
	adc a, $49
	sub l
	ld h, a
	ld a, [hli]
	ld h, [hl]

; Drum sound table (indexed from 2 bytes before; drum 1 is the first entry).
DrumTable_m2:
	ld l, a
	jp hl
DrumTable:
	dw Drum1
	dw Drum8
	dw Drum4
	dw Drum4
	dw Drum5
	dw Drum6
	dw Drum9
	dw Drum8
	dw Drum9
	dw Drum10

; Unreferenced (2 bytes)
	db $CD, $7F
DrumTempo:
	sub $BF
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

; Song 2: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong2:
	ld a, $76
	ld [wInstrTableHi], a
	ld a, $3C
	ld [wInstrTable], a
	call StopAll
	ld de, Song2_Ch1
	call StartMusicCh1
	ld de, Song2_Ch2
	call StartMusicCh2
	ld de, Song2_Ch3
	jp StartMusicCh3

; Unreferenced (1 bytes)
	db $C9
Song2_Ch1:
	dw Pat_4B7F
	dw Pat_4B8C
	dw Pat_4BA7
	dw Pat_4BC2
	dw Pat_4BDD
	dw Pat_4BDD
	dw Pat_4BA7
	dw Pat_4BC2
	ORDER_LOOP Song2_Ch1
Song2_Ch2:
	dw Pat_4BF2
	dw Pat_4BF2
	dw Pat_4C15
	dw Pat_4C54
	dw Pat_4C90
	dw Pat_4C90
	dw Pat_4C15
	dw Pat_4C54
	ORDER_LOOP Song2_Ch2
Song2_Ch3:
	dw Pat_4CB5
	dw Pat_4CB8
	dw Pat_4CE6
	dw Pat_4CFB
	dw Pat_4D12
	dw Pat_4D42
	dw Pat_4D85
	dw Pat_4DA2
	ORDER_LOOP Song2_Ch3
Pat_4B7F:
	DRUMS $07, DrumPat_4DC3
	INSTR 0
	VIBRATO $07, $02, $05
	ARP 0
	RELEASE $01, $11
Pat_4B8C:
	LEN 42
	NOTE G_, 2
	NOTE F_, 2
	LEN 28
	NOTE F_, 2
	LEN 42
	NOTE G_, 2
	LEN 28
	NOTE Ash, 2
	LEN 14
	NOTE Ash, 2
	NOTE C_, 3
	NOTE C_, 3
	LEN 42
	NOTE G_, 2
	NOTE F_, 2
	LEN 28
	NOTE F_, 2
	LEN 42
	NOTE Dsh, 2
	LEN 28
	NOTE D_, 2
	LEN 14
	NOTE D_, 2
	NOTE F_, 2
	NOTE F_, 2
	NEXT
Pat_4BA7:
	LEN 42
	NOTE Dsh, 2
	NOTE Dsh, 2
	LEN 28
	NOTE Ash, 2
	LEN 42
	NOTE Dsh, 2
	LEN 28
	NOTE Dsh, 2
	LEN 14
	NOTE Dsh, 2
	NOTE F_, 2
	NOTE F_, 2
	LEN 42
	NOTE G_, 2
	NOTE G_, 2
	LEN 28
	NOTE D_, 2
	LEN 42
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE F_, 2
	NOTE D_, 2
	NOTE G_, 2
	NEXT
Pat_4BC2:
	LEN 42
	NOTE Dsh, 2
	NOTE Dsh, 2
	LEN 28
	NOTE Ash, 2
	LEN 42
	NOTE Dsh, 2
	LEN 28
	NOTE Dsh, 2
	LEN 14
	NOTE Dsh, 2
	NOTE F_, 2
	NOTE Dsh, 2
	LEN 42
	NOTE D_, 2
	NOTE D_, 2
	LEN 28
	NOTE A_, 2
	LEN 42
	NOTE D_, 2
	LEN 28
	NOTE D_, 3
	LEN 14
	NOTE C_, 3
	NOTE Ash, 2
	NOTE A_, 2
	NEXT
Pat_4BDD:
	LEN 42
	NOTE G_, 2
	NOTE G_, 2
	LEN 28
	NOTE F_, 2
	LEN 42
	NOTE G_, 2
	NOTE G_, 2
	LEN 28
	NOTE Ash, 2
	LEN 42
	NOTE G_, 2
	NOTE G_, 2
	LEN 28
	NOTE F_, 2
	LEN 42
	NOTE G_, 2
	NOTE D_, 3
	LEN 28
	NOTE D_, 2
	NEXT
Pat_4BF2:
	INSTR 5
	LEN 42
	NOTE G_, 4
	INSTR 4
	LEN 28
	NOTE F_, 4
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	INSTR 5
	LEN 42
	NOTE G_, 4
	INSTR 4
	LEN 28
	NOTE Ash, 4
	NOTE Ash, 4
	LEN 14
	NOTE C_, 5
	INSTR 5
	LEN 42
	NOTE G_, 4
	INSTR 4
	LEN 28
	NOTE F_, 4
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	LEN 42
	NOTE Dsh, 4
	LEN 28
	NOTE D_, 4
	NOTE D_, 4
	LEN 14
	NOTE D_, 4
	NEXT
Pat_4C15:
	INSTR 4
	LEN 14
	NOTE Dsh, 4
	INSTR 10
	LEN 28
	NOTE G_, 4
	INSTR 4
	LEN 14
	NOTE Dsh, 4
	INSTR 10
	NOTE G_, 4
	INSTR 4
	LEN 28
	NOTE Dsh, 4
	LEN 14
	NOTE F_, 4
	INSTR 5
	NOTE G_, 4
	INSTR 10
	LEN 28
	NOTE G_, 4
	INSTR 5
	LEN 14
	NOTE G_, 4
	INSTR 10
	NOTE G_, 4
	INSTR 4
	LEN 28
	NOTE F_, 4
	LEN 14
	NOTE Dsh, 4
	INSTR 5
	NOTE G_, 4
	INSTR 10
	LEN 28
	NOTE G_, 4
	INSTR 5
	LEN 14
	NOTE G_, 4
	INSTR 10
	NOTE G_, 4
	INSTR 5
	LEN 28
	NOTE G_, 4
	INSTR 4
	LEN 14
	NOTE F_, 4
	INSTR 5
	NOTE G_, 4
	INSTR 10
	LEN 28
	NOTE G_, 4
	INSTR 5
	LEN 14
	NOTE G_, 4
	INSTR 10
	NOTE G_, 4
	INSTR 4
	LEN 28
	NOTE F_, 4
	LEN 14
	NOTE Dsh, 4
	NEXT
Pat_4C54:
	INSTR 4
	LEN 14
	NOTE Dsh, 4
	INSTR 10
	LEN 28
	NOTE G_, 4
	INSTR 4
	LEN 14
	NOTE Dsh, 4
	INSTR 10
	NOTE G_, 4
	INSTR 4
	LEN 28
	NOTE Dsh, 4
	LEN 14
	NOTE F_, 4
	INSTR 5
	NOTE G_, 4
	INSTR 10
	LEN 28
	NOTE G_, 4
	INSTR 5
	LEN 14
	NOTE G_, 4
	INSTR 10
	NOTE G_, 4
	INSTR 4
	LEN 28
	NOTE F_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE D_, 4
	INSTR 10
	LEN 28
	NOTE Fsh, 4
	INSTR 4
	LEN 14
	NOTE D_, 4
	INSTR 10
	NOTE Fsh, 4
	INSTR 4
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE D_, 4
	INSTR 10
	LEN 28
	NOTE Fsh, 4
	INSTR 4
	LEN 14
	NOTE Dsh, 4
	INSTR 10
	NOTE A_, 4
	INSTR 4
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE D_, 4
	NEXT
Pat_4C90:
	INSTR 5
	LEN 42
	NOTE G_, 3
	LEN 28
	NOTE G_, 3
	NOTE G_, 3
	INSTR 4
	LEN 14
	NOTE F_, 3
	INSTR 5
	LEN 42
	NOTE G_, 3
	LEN 28
	NOTE G_, 3
	NOTE G_, 3
	INSTR 4
	LEN 14
	NOTE Ash, 3
	INSTR 5
	LEN 42
	NOTE G_, 3
	LEN 28
	NOTE G_, 3
	NOTE G_, 3
	INSTR 4
	LEN 14
	NOTE F_, 3
	INSTR 5
	LEN 42
	NOTE G_, 3
	LEN 28
	NOTE G_, 3
	INSTR 4
	NOTE F_, 3
	LEN 14
	NOTE Dsh, 3
	NEXT
Pat_4CB5:
	WAVE Wave_7E52
Pat_4CB8:
	CH_TRANSPOSE $0C
	VIBRATO $14, $01, $06
	INSTR 6
	LEN 14
	NOTE G_, 3
	NOTE Ash, 3
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE C_, 4
	NOTE A_, 3
	NOTE F_, 3
	LEN 28
	NOTE G_, 3
	LEN 14
	NOTE Ash, 3
	NOTE D_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE E_, 4
	LEN 28
	NOTE G_, 4
	LEN 14
	NOTE G_, 3
	NOTE Ash, 3
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE C_, 4
	NOTE A_, 3
	NOTE F_, 3
	LEN 28
	NOTE Dsh, 3
	LEN 14
	NOTE G_, 3
	NOTE Ash, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE Fsh, 3
	LEN 28
	NOTE D_, 3
	NEXT
Pat_4CE6:
	LEN 28
	WAIT
	INSTR 13
	NOTE G_, 4
	NOTE Dsh, 4
	ARP 3
	NOTE Gsh, 4
	INSTR 13
	LENGTH $8C
	NOTE G_, 4
	LEN 28
	NOTE G_, 4
	NOTE D_, 4
	ARP 3
	NOTE Gsh, 4
	INSTR 13
	LENGTH $70
	NOTE G_, 4
	NEXT
Pat_4CFB:
	LEN 28
	WAIT
	INSTR 13
	NOTE G_, 4
	NOTE Dsh, 4
	ARP 3
	NOTE Gsh, 4
	INSTR 13
	LENGTH $8C
	NOTE G_, 4
	LEN 28
	NOTE Fsh, 4
	NOTE D_, 4
	ARP 3
	NOTE G_, 4
	INSTR 13
	LENGTH $38
	NOTE Fsh, 4
	ARP 3
	NOTE C_, 5
	NEXT
Pat_4D12:
	LEN 14
	WAIT
	INSTR 6
	CH_TRANSPOSE $00
	WAVE Wave_7E02
	NOTE D_, 3
	LEN 28
	NOTE G_, 3
	LEN 14
	NOTE D_, 3
	LEN 28
	NOTE G_, 3
	NOTE F_, 3
	LEN 14
	NOTE D_, 3
	LEN 28
	NOTE G_, 3
	LEN 14
	NOTE D_, 3
	LEN 28
	NOTE G_, 3
	NOTE Ash, 3
	LEN 14
	NOTE D_, 3
	LEN 28
	NOTE G_, 3
	LEN 14
	NOTE D_, 3
	LEN 28
	NOTE G_, 3
	NOTE F_, 3
	LEN 14
	NOTE D_, 3
	LEN 28
	NOTE G_, 3
	LEN 7
	NOTE Ash, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE D_, 3
	NOTE C_, 3
	NEXT
Pat_4D42:
	LEN 7
	WAIT
	WAIT
	NOTE D_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE Ash, 3
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE D_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE Ash, 3
	LEN 14
	NOTE D_, 4
	NOTE C_, 3
	NOTE D_, 3
	LEN 7
	NOTE D_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE Ash, 3
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE D_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE Ash, 3
	LEN 14
	NOTE D_, 4
	NOTE F_, 3
	NOTE D_, 3
	LEN 7
	NOTE D_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE Ash, 3
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE D_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE Ash, 3
	LEN 14
	NOTE D_, 4
	NOTE C_, 3
	NOTE D_, 3
	LEN 7
	NOTE D_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE Ash, 3
	LEN 14
	NOTE D_, 4
	INSTR 13
	CH_TRANSPOSE $0C
	NOTE F_, 4
	NOTE G_, 4
	ARP 3
	NOTE Gsh, 4
	INSTR 13
	NOTE A_, 4
	NEXT
Pat_4D85:
	LEN 28
	WAIT
	NOTE G_, 4
	NOTE Dsh, 4
	ARP 3
	NOTE Gsh, 4
	INSTR 13
	LENGTH $54
	NOTE G_, 4
	LEN 14
	NOTE D_, 5
	NOTE C_, 5
	LEN 28
	NOTE D_, 5
	NOTE G_, 4
	NOTE D_, 4
	ARP 3
	NOTE Gsh, 4
	INSTR 13
	NOTE D_, 5
	LEN 14
	NOTE Ash, 4
	LEN 28
	NOTE G_, 4
	NOTE F_, 4
	LEN 14
	NOTE G_, 4
	NEXT
Pat_4DA2:
	LEN 28
	WAIT
	INSTR 13
	NOTE G_, 4
	NOTE Dsh, 4
	ARP 3
	NOTE Gsh, 4
	INSTR 13
	LENGTH $46
	NOTE G_, 4
	LEN 14
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 28
	NOTE A_, 4
	NOTE Fsh, 4
	ARP 3
	NOTE C_, 5
	INSTR 13
	LEN 14
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE D_, 5
	ARP 3
	NOTE Csh, 5
	INSTR 13
	NOTE C_, 5
	LENGTH $46
	NOTE D_, 5
	NEXT
DrumPat_4DC3:
	db DRUM_LEVEL + 14, DRUM_REPEAT + 3, 1, 0, 6, 6, 9, 0
	db 6, 6, DRUM_REPEAT_END, 1, 0, 6, 6, 9
	db 6, 6, 6, DRUM_LOOP

; Song 3: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong3:
	ld a, $76
	ld [wInstrTableHi], a
	ld a, $3C
	ld [wInstrTable], a
	call StopAll
	ld de, Song3_Ch1
	call StartMusicCh1
	ld de, Song3_Ch2
	call StartMusicCh2
	ld de, Song3_Ch3
	jp StartMusicCh3
Song3_Ch1:
	dw Pat_4E32
	dw Pat_4E32
	dw Pat_4E32
	dw Pat_4E32
	dw Pat_4E32
	dw Pat_4E32
	dw Pat_4E65
	dw Pat_4E8C
	ORDER_LOOP Song3_Ch1
Song3_Ch2:
	dw Pat_4EB3
	dw Pat_4EB3
	dw Pat_4EB3
	dw Pat_4EB3
	dw Pat_4EB3
	dw Pat_4EB3
	dw Pat_4EF5
	dw Pat_4F37
	ORDER_LOOP Song3_Ch2
Song3_Ch3:
	dw Pat_4F79
	dw Pat_4F79
	dw Pat_4FD7
	dw Pat_4FFC
	dw Pat_4F79
	dw Pat_4F79
	dw Pat_5023
	dw Pat_504F
	ORDER_LOOP Song3_Ch3
Pat_4E32:
	DRUMS $07, DrumPat_507A
	INSTR 0
	TRANSPOSE $02
	DUTY_50
	RELEASE $02, $41
	LEN 21
	NOTE C_, 2
	NOTE G_, 2
	LEN 14
	NOTE C_, 3
	LEN 21
	NOTE Ash, 2
	NOTE F_, 2
	LEN 14
	NOTE D_, 2
	LEN 21
	NOTE C_, 2
	NOTE G_, 2
	LEN 14
	NOTE C_, 3
	LEN 21
	NOTE Ash, 2
	NOTE F_, 2
	LEN 14
	NOTE Ash, 2
	LEN 21
	NOTE C_, 2
	NOTE G_, 2
	LEN 14
	NOTE C_, 3
	LEN 21
	NOTE Ash, 2
	NOTE F_, 2
	LEN 14
	NOTE Ash, 2
	LEN 21
	NOTE Gsh, 2
	NOTE Dsh, 2
	LEN 14
	NOTE Gsh, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE D_, 2
	NEXT
Pat_4E65:
	LEN 21
	NOTE Gsh, 2
	NOTE Dsh, 2
	LEN 14
	NOTE G_, 2
	LEN 28
	NOTE Gsh, 2
	LEN 14
	NOTE Dsh, 2
	NOTE G_, 2
	LEN 21
	NOTE Gsh, 2
	NOTE Dsh, 2
	LEN 14
	NOTE G_, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE G_, 2
	NOTE Dsh, 2
	LEN 21
	NOTE C_, 2
	NOTE G_, 2
	LEN 14
	NOTE C_, 3
	LEN 21
	NOTE Ash, 2
	NOTE F_, 2
	LEN 14
	NOTE D_, 2
	LEN 21
	NOTE C_, 2
	NOTE G_, 2
	LEN 14
	NOTE C_, 3
	NOTE Dsh, 3
	NOTE D_, 3
	NOTE C_, 3
	NOTE G_, 2
	NEXT
Pat_4E8C:
	LEN 21
	NOTE Gsh, 2
	NOTE Dsh, 2
	LEN 14
	NOTE G_, 2
	LEN 28
	NOTE Gsh, 2
	LEN 14
	NOTE Dsh, 2
	NOTE G_, 2
	LEN 21
	NOTE Gsh, 2
	NOTE Dsh, 2
	LEN 14
	NOTE G_, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE G_, 2
	NOTE Dsh, 2
	LEN 21
	NOTE G_, 2
	NOTE D_, 2
	LEN 14
	NOTE F_, 2
	LEN 21
	NOTE G_, 2
	NOTE D_, 2
	LEN 14
	NOTE F_, 2
	LEN 21
	NOTE G_, 2
	NOTE Gsh, 2
	LEN 14
	NOTE F_, 2
	NOTE G_, 2
	NOTE Gsh, 2
	NOTE Ash, 2
	NOTE B_, 2
	NEXT
Pat_4EB3:
	INSTR 1
	LEN 14
	NOTE C_, 3
	INSTR 5
	NOTE C_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 5
	NOTE C_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Ash, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Ash, 3
	INSTR 1
	NOTE C_, 3
	INSTR 5
	NOTE C_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 5
	NOTE C_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Ash, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Ash, 3
	INSTR 1
	NOTE C_, 3
	INSTR 5
	NOTE C_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 5
	NOTE C_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Ash, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Ash, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Gsh, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Gsh, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE G_, 3
	NEXT
Pat_4EF5:
	INSTR 1
	LEN 14
	NOTE C_, 3
	INSTR 4
	NOTE Gsh, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Gsh, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Gsh, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Gsh, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Gsh, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Gsh, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Ash, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Ash, 3
	INSTR 1
	NOTE C_, 3
	INSTR 5
	NOTE C_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 5
	NOTE C_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 5
	NOTE C_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 5
	NOTE C_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 5
	NOTE C_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 5
	NOTE C_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Ash, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Ash, 3
	NEXT
Pat_4F37:
	INSTR 1
	LEN 14
	NOTE C_, 3
	INSTR 4
	NOTE Gsh, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Gsh, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Gsh, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Gsh, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Gsh, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Gsh, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Gsh, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Gsh, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE G_, 3
	NEXT
Pat_4F79:
	LEN 14
	WAIT
	WAVE Wave_7E02
	VOLENV 11, $11, $1F, $12
	RELEASE $01, $01
	CH_TRANSPOSE $00
	VIBRATO $0E, $01, $05
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE Ash, 3
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE Ash, 3
	LEN 28
	NOTE Ash, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE Ash, 3
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE Ash, 3
	LEN 28
	NOTE Ash, 3
	LEN 7
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE F_, 4
	NOTE D_, 4
	LEN 7
	NOTE Dsh, 4
	CH_TRANSPOSE $0C
	ARP_OFF
	INSTR 13
	WAVE Wave_7DB2
	NEXT
Pat_4FD7:
	LEN 28
	NOTE G_, 3
	NOTE C_, 4
	NOTE D_, 4
	LEN 14
	NOTE C_, 4
	NOTE D_, 4
	ARP 3
	LEN 21
	NOTE Csh, 4
	ARP_OFF
	NOTE D_, 4
	LEN 14
	NOTE C_, 4
	LEN 21
	NOTE D_, 4
	NOTE Ash, 3
	LEN 14
	NOTE F_, 3
	LEN 28
	NOTE G_, 3
	NOTE C_, 4
	NOTE D_, 4
	LEN 14
	NOTE C_, 4
	NOTE Ash, 3
	ARP 3
	LEN 21
	NOTE Ash, 3
	ARP_OFF
	NOTE Ash, 3
	LEN 14
	NOTE Gsh, 3
	LENGTH $38
	NOTE G_, 3
	NEXT
Pat_4FFC:
	ARP_OFF
	LEN 28
	NOTE G_, 3
	NOTE C_, 4
	NOTE D_, 4
	LEN 14
	NOTE C_, 4
	NOTE D_, 4
	ARP 3
	LEN 21
	NOTE Csh, 4
	ARP_OFF
	NOTE D_, 4
	LEN 14
	NOTE C_, 4
	LEN 21
	NOTE D_, 4
	NOTE F_, 4
	LEN 14
	NOTE Ash, 4
	LEN 42
	NOTE G_, 4
	LEN 7
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 21
	NOTE F_, 4
	NOTE D_, 4
	LEN 14
	NOTE F_, 4
	LEN 21
	NOTE Dsh, 4
	NOTE D_, 4
	LEN 14
	NOTE C_, 4
	LENGTH $38
	NOTE D_, 4
	NEXT
Pat_5023:
	ARP 3
	LEN 21
	NOTE Ash, 4
	ARP_OFF
	NOTE Ash, 4
	LEN 28
	NOTE C_, 5
	LEN 14
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	ARP 3
	LEN 21
	NOTE Ash, 4
	ARP_OFF
	NOTE Ash, 4
	LEN 28
	NOTE C_, 5
	ARP 3
	LEN 14
	NOTE Csh, 5
	ARP_OFF
	NOTE D_, 5
	NOTE Ash, 4
	LEN 42
	NOTE G_, 4
	LEN 7
	NOTE C_, 4
	NOTE D_, 4
	LEN 42
	NOTE Dsh, 4
	LEN 14
	NOTE G_, 4
	ARP 3
	LEN 21
	NOTE Csh, 5
	ARP_OFF
	NOTE D_, 5
	NOTE C_, 5
	NOTE G_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE C_, 4
	NEXT
Pat_504F:
	ARP 3
	LEN 21
	NOTE Ash, 4
	ARP_OFF
	NOTE Ash, 4
	LEN 28
	NOTE C_, 5
	LEN 14
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	ARP 3
	LEN 21
	NOTE Ash, 4
	ARP_OFF
	NOTE Ash, 4
	LEN 28
	NOTE C_, 5
	ARP 3
	LEN 14
	NOTE Csh, 5
	ARP_OFF
	NOTE D_, 5
	NOTE C_, 5
	LEN 42
	NOTE D_, 5
	LEN 7
	NOTE Dsh, 5
	NOTE F_, 5
	LEN 28
	NOTE G_, 5
	NOTE F_, 5
	LEN 21
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE F_, 5
	ARP 3
	LEN 14
	NOTE Fsh, 5
	ARP_OFF
	NOTE G_, 5
	NEXT
DrumPat_507A:
	db DRUM_LEVEL + 13, 1, 0, 6, 6, 9, 0, 6
	db 6, 1, 0, 6, 6, 9, 0, 6
	db 6, 1, 0, 6, 6, 9, 0, 6
	db 6, 1, 0, 6, 6, 9, 0, 1
	db 6, 1, 0, 6, 6, 9, 0, 6
	db 6, 1, 0, 6, 6, 9, 0, 6
	db 6, 1, 0, 6, 6, 9, 0, 6
	db 6, 1, 0, 6, 6, 9, 0, 9
	db 9, DRUM_LOOP

; Song 4: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong4:
	ld a, $76
	ld [wInstrTableHi], a
	ld a, $3C
	ld [wInstrTable], a
	call StopAll
	ld de, Song4_Ch1
	call StartMusicCh1
	ld de, Song4_Ch2
	call StartMusicCh2
	ld de, Song4_Ch3
	jp StartMusicCh3
Song4_Ch1:
	dw Pat_5117
	dw Pat_5117
	dw Pat_511B
	dw Pat_511B
	dw Pat_5137
	dw Pat_5157
	dw Pat_5177
	dw Pat_5196
	ORDER_LOOP Song4_Ch1
Song4_Ch2:
	dw Pat_51F8
	dw Pat_51F8
	dw Pat_51F8
	dw Pat_51F8
	dw Pat_51B0
	dw Pat_51C5
	dw Pat_51DE
	dw Pat_51EB
	ORDER_LOOP Song4_Ch2
Song4_Ch3:
	dw Pat_52E1
	dw Pat_52E1
	dw Pat_5212
	dw Pat_523F
	dw Pat_525E
	dw Pat_5280
	dw Pat_52A2
	dw Pat_52C4
	ORDER_LOOP Song4_Ch3
Pat_5117:
	DRUMS $07, DrumPat_5336
Pat_511B:
	INSTR 0
	LEN 28
	NOTE B_, 2
	NOTE Fsh, 2
	NOTE B_, 2
	LEN 14
	NOTE Fsh, 2
	NOTE A_, 2
	LEN 28
	NOTE B_, 2
	NOTE Fsh, 2
	NOTE B_, 2
	LEN 14
	NOTE A_, 2
	NOTE Fsh, 2
	LEN 28
	NOTE E_, 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE D_, 3
	NOTE A_, 2
	NOTE E_, 3
	LEN 14
	NOTE A_, 2
	NOTE E_, 2
	NOTE Fsh, 2
	NOTE A_, 2
	NEXT
Pat_5137:
	INSTR 0
	LEN 28
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	LEN 14
	NOTE D_, 2
	NOTE Fsh, 2
	LEN 28
	NOTE G_, 2
	NOTE D_, 2
	LEN 14
	NOTE G_, 2
	NOTE E_, 2
	NOTE Fsh, 2
	NOTE A_, 2
	LEN 28
	NOTE B_, 2
	NOTE Fsh, 2
	NOTE B_, 2
	LEN 14
	NOTE Fsh, 2
	NOTE A_, 2
	LEN 28
	NOTE B_, 2
	NOTE Fsh, 2
	LEN 14
	NOTE B_, 2
	NOTE A_, 2
	NOTE Fsh, 2
	NOTE A_, 2
	NEXT
Pat_5157:
	INSTR 0
	LEN 28
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	LEN 14
	NOTE D_, 2
	NOTE Fsh, 2
	LEN 28
	NOTE G_, 2
	NOTE D_, 2
	LEN 14
	NOTE A_, 2
	NOTE E_, 2
	NOTE Fsh, 2
	NOTE A_, 2
	LEN 28
	NOTE D_, 3
	NOTE A_, 2
	NOTE D_, 3
	LEN 14
	NOTE A_, 2
	NOTE D_, 3
	LEN 28
	NOTE Fsh, 2
	NOTE Csh, 3
	LEN 14
	NOTE Fsh, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE Csh, 2
	NEXT
Pat_5177:
	INSTR 0
	LEN 28
	NOTE B_, 2
	NOTE Fsh, 2
	NOTE B_, 2
	LEN 14
	NOTE Fsh, 2
	NOTE A_, 2
	LEN 28
	NOTE B_, 2
	NOTE Fsh, 2
	NOTE B_, 2
	LEN 14
	NOTE Fsh, 2
	NOTE F_, 2
	LEN 28
	NOTE E_, 2
	NOTE B_, 2
	NOTE E_, 2
	LEN 14
	NOTE B_, 2
	NOTE Fsh, 2
	LEN 28
	NOTE E_, 2
	NOTE B_, 2
	LEN 14
	NOTE E_, 2
	NOTE Fsh, 2
	NOTE G_, 2
	NOTE E_, 2
	NEXT
Pat_5196:
	INSTR 0
	LEN 28
	NOTE Fsh, 2
	NOTE Csh, 3
	NOTE Fsh, 2
	NOTE Csh, 3
	NOTE Fsh, 2
	NOTE Csh, 3
	LEN 14
	NOTE Fsh, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE Csh, 2
	LEN 28
	NOTE B_, 2
	NOTE Fsh, 2
	NOTE B_, 2
	NOTE Fsh, 2
	NOTE B_, 2
	NOTE Fsh, 2
	LEN 14
	NOTE B_, 2
	NOTE E_, 2
	NOTE Fsh, 2
	NOTE A_, 2
	NEXT
Pat_51B0:
	REPEAT 7
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE G_, 3
	REPEAT_END
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE A_, 3
	REPEAT 7
	INSTR 1
	NOTE C_, 3
	INSTR 5
	NOTE B_, 3
	REPEAT_END
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE A_, 3
	NEXT
Pat_51C5:
	REPEAT 6
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE G_, 3
	REPEAT_END
	REPEAT 2
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE A_, 3
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE D_, 4
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Fsh, 4
	REPEAT_END
	NEXT
Pat_51DE:
	REPEAT 8
	INSTR 1
	NOTE C_, 3
	INSTR 5
	NOTE B_, 3
	REPEAT_END
	REPEAT 8
	INSTR 1
	NOTE C_, 3
	INSTR 5
	NOTE E_, 4
	REPEAT_END
	NEXT
Pat_51EB:
	REPEAT 8
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE Fsh, 4
	REPEAT_END
	REPEAT 8
	INSTR 1
	NOTE C_, 3
	INSTR 5
	NOTE B_, 3
	REPEAT_END
	NEXT
Pat_51F8:
	LEN 14
	REPEAT 8
	INSTR 1
	NOTE C_, 3
	INSTR 5
	NOTE B_, 3
	REPEAT_END
	REPEAT 2
	INSTR 1
	NOTE C_, 3
	INSTR 5
	NOTE E_, 3
	REPEAT_END
	REPEAT 2
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE G_, 3
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE A_, 3
	REPEAT_END
	NEXT
Pat_5212:
	VOLENV 15, $11, $1A, $16
	ARP 0
	CH_TRANSPOSE $0C
	VIBRATO $0E, $01, $05
	WAVE Wave_7E62
	LEN 28
	NOTE B_, 3
	NOTE Fsh, 3
	LEN 42
	NOTE B_, 3
	LEN 14
	NOTE Csh, 4
	LEN 28
	NOTE D_, 4
	NOTE B_, 3
	NOTE Fsh, 3
	LEN 14
	NOTE Csh, 4
	NOTE A_, 3
	LEN 28
	NOTE B_, 3
	NOTE B_, 3
	LEN 14
	NOTE B_, 3
	NOTE Csh, 4
	NOTE D_, 4
	NOTE B_, 3
	LEN 28
	NOTE Csh, 4
	LEN 14
	NOTE B_, 3
	NOTE Csh, 4
	LENGTH $38
	NOTE A_, 3
	NEXT
Pat_523F:
	LEN 28
	NOTE B_, 3
	NOTE Fsh, 3
	LEN 42
	NOTE B_, 3
	LEN 14
	NOTE Csh, 4
	LEN 28
	NOTE D_, 4
	NOTE B_, 3
	NOTE Fsh, 3
	LEN 14
	NOTE Csh, 4
	NOTE A_, 3
	LEN 28
	NOTE B_, 3
	NOTE B_, 3
	LEN 14
	NOTE B_, 3
	NOTE Csh, 4
	NOTE D_, 4
	NOTE B_, 3
	LEN 28
	NOTE Csh, 4
	LEN 14
	NOTE Fsh, 4
	NOTE A_, 4
	LENGTH $38
	NOTE E_, 4
	NEXT
Pat_525E:
	LEN 14
	WAIT
	NOTE B_, 3
	NOTE Csh, 4
	NOTE D_, 4
	NOTE Csh, 4
	NOTE E_, 4
	NOTE Csh, 4
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE B_, 3
	NOTE Csh, 4
	NOTE D_, 4
	NOTE Csh, 4
	NOTE E_, 4
	NOTE Csh, 4
	NOTE A_, 3
	LENGTH $54
	NOTE Fsh, 3
	LEN 7
	NOTE Fsh, 3
	NOTE G_, 3
	NOTE Fsh, 3
	NOTE E_, 3
	LENGTH $46
	NOTE Fsh, 3
	LEN 14
	NOTE B_, 3
	NOTE D_, 4
	NOTE A_, 3
	NEXT
Pat_5280:
	LEN 14
	WAIT
	NOTE B_, 3
	NOTE Csh, 4
	NOTE D_, 4
	NOTE Csh, 4
	NOTE E_, 4
	NOTE Csh, 4
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE B_, 3
	NOTE Csh, 4
	NOTE D_, 4
	NOTE Csh, 4
	NOTE E_, 4
	NOTE Csh, 4
	NOTE A_, 3
	LENGTH $46
	NOTE Fsh, 4
	LEN 14
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	LEN 7
	NOTE Fsh, 4
	NOTE G_, 4
	LENGTH $54
	NOTE Fsh, 4
	LEN 14
	NOTE Fsh, 4
	NEXT
Pat_52A2:
	LEN 28
	NOTE B_, 4
	NOTE Fsh, 4
	LEN 14
	NOTE B_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE Csh, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	LEN 42
	NOTE Fsh, 4
	LEN 14
	NOTE Fsh, 4
	LEN 28
	NOTE E_, 4
	NOTE B_, 3
	LEN 14
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE A_, 3
	LEN 28
	NOTE B_, 3
	LEN 14
	NOTE Csh, 4
	NOTE D_, 4
	NEXT
Pat_52C4:
	LENGTH $38
	NOTE Csh, 4
	LEN 42
	NOTE Fsh, 4
	LEN 7
	NOTE E_, 4
	NOTE D_, 4
	LEN 28
	NOTE Csh, 4
	LEN 14
	NOTE Ash, 3
	NOTE B_, 3
	NOTE Csh, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE D_, 4
	LEN 42
	NOTE B_, 3
	LEN 14
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE A_, 3
	LENGTH $70
	NOTE B_, 3
	NEXT
Pat_52E1:
	WAVE Wave_7E02
	CH_TRANSPOSE $00
	VOLENV 10, $00, $1F, $12
	ARP 18
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE B_, 4
	NOTE B_, 4
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE B_, 4
	NOTE B_, 4
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE B_, 4
	NOTE B_, 4
	LEN 14
	NOTE B_, 4
	ARP 17
	NOTE A_, 4
	ARP 18
	NOTE B_, 4
	LEN 7
	NOTE B_, 4
	NOTE B_, 4
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE B_, 4
	NOTE B_, 4
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE B_, 4
	NOTE B_, 4
	LEN 14
	NOTE B_, 4
	ARP 17
	NOTE A_, 4
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
	ARP 18
	NOTE B_, 4
	ARP 17
	NOTE A_, 4
	LEN 7
	NOTE A_, 4
	NOTE A_, 4
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE A_, 4
	NOTE A_, 4
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE A_, 4
	NOTE A_, 4
	LEN 14
	NOTE A_, 4
	NOTE A_, 4
	NEXT
DrumPat_5336:
	db DRUM_LEVEL + 14, 1, 0, 6, 6, 1, 0, 6
	db 6, 1, 0, 6, 6, 1, 6, 6
	db 6, DRUM_LOOP

; Song 5: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong5:
	ld a, $76
	ld [wInstrTableHi], a
	ld a, $3C
	ld [wInstrTable], a
	call StopAll
	ld de, Song5_Ch1
	call StartMusicCh1
	ld de, Song5_Ch2
	call StartMusicCh2
	ld de, Song5_Ch3
	jp StartMusicCh3
Song5_Ch1:
	dw Pat_5391
	dw Pat_53D9
	dw Pat_541D
	dw Pat_541D
	dw Pat_546A
	ORDER_LOOP Song5_Ch1
Song5_Ch2:
	dw Pat_54CE
	dw Pat_5515
	dw Pat_5545
	dw Pat_5545
	dw Pat_5597
	ORDER_LOOP Song5_Ch2
Song5_Ch3:
	dw Pat_55E7
	dw Pat_5630
	dw Pat_566C
	dw Pat_56AE
	dw Pat_56EC
	ORDER_LOOP Song5_Ch3
Pat_5391:
	DRUMS $06, DrumPat_5718
	TRANSPOSE $02
	INSTR 0
	LEN 24
	NOTE D_, 2
	INSTR 5
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 5
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 5
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	NOTE D_, 2
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
	NOTE C_, 2
	NOTE Ash, 2
	INSTR 4
	NOTE Ash, 3
	INSTR 0
	NOTE F_, 2
	INSTR 4
	NOTE Ash, 3
	INSTR 0
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	NOTE C_, 3
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 4
	LEN 12
	NOTE A_, 4
	INSTR 0
	LEN 24
	NOTE A_, 2
	LEN 12
	NOTE E_, 2
	INSTR 4
	NOTE A_, 4
	INSTR 0
	NOTE A_, 2
	NEXT
Pat_53D9:
	INSTR 0
	LEN 24
	NOTE D_, 2
	INSTR 5
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 5
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 5
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	NOTE D_, 2
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
	LEN 12
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	LEN 24
	NOTE G_, 2
	NOTE C_, 2
	NOTE Ash, 2
	INSTR 4
	LEN 12
	NOTE Ash, 3
	INSTR 0
	LEN 36
	NOTE F_, 2
	INSTR 4
	LEN 24
	NOTE Ash, 3
	INSTR 0
	NOTE C_, 3
	INSTR 4
	LEN 12
	NOTE C_, 4
	INSTR 0
	LEN 36
	NOTE G_, 2
	LEN 24
	NOTE C_, 3
	NOTE D_, 2
	INSTR 5
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 5
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 5
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	NOTE C_, 2
	NEXT
Pat_541D:
	INSTR 0
	LEN 24
	NOTE Ash, 1
	INSTR 4
	NOTE Ash, 3
	INSTR 0
	NOTE F_, 2
	INSTR 4
	NOTE Ash, 3
	INSTR 0
	NOTE Ash, 1
	INSTR 4
	LEN 12
	NOTE Ash, 3
	INSTR 0
	NOTE Ash, 1
	LEN 24
	NOTE F_, 2
	NOTE C_, 2
	NOTE D_, 2
	INSTR 5
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 5
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 5
	LEN 12
	NOTE D_, 4
	INSTR 0
	LEN 24
	NOTE A_, 2
	LEN 12
	NOTE D_, 2
	INSTR 5
	NOTE D_, 4
	INSTR 0
	NOTE C_, 2
	LEN 24
	NOTE Ash, 1
	INSTR 4
	NOTE Ash, 3
	INSTR 0
	NOTE F_, 2
	INSTR 4
	NOTE Ash, 3
	INSTR 0
	NOTE Ash, 1
	INSTR 4
	NOTE Ash, 3
	INSTR 0
	NOTE F_, 2
	NOTE Ash, 2
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
	LEN 12
	NOTE C_, 4
	INSTR 0
	LEN 24
	NOTE C_, 3
	LEN 12
	NOTE G_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE E_, 2
	NEXT
Pat_546A:
	INSTR 0
	LEN 24
	NOTE D_, 2
	INSTR 5
	LEN 12
	NOTE D_, 4
	INSTR 0
	LEN 36
	NOTE A_, 2
	INSTR 5
	LEN 24
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 5
	LEN 12
	NOTE D_, 4
	INSTR 0
	LEN 36
	NOTE A_, 2
	INSTR 5
	LEN 24
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 5
	LEN 12
	NOTE D_, 4
	INSTR 0
	LEN 36
	NOTE A_, 2
	LEN 24
	NOTE C_, 3
	NOTE D_, 2
	INSTR 5
	LEN 12
	NOTE D_, 4
	INSTR 0
	LEN 24
	NOTE A_, 2
	INSTR 5
	LEN 12
	NOTE D_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 5
	NOTE D_, 4
	INSTR 0
	LEN 24
	NOTE D_, 2
	INSTR 5
	LEN 12
	NOTE D_, 4
	INSTR 0
	LEN 36
	NOTE A_, 2
	LEN 24
	NOTE C_, 3
	NOTE D_, 3
	INSTR 5
	LEN 12
	NOTE D_, 4
	INSTR 0
	LEN 24
	NOTE A_, 2
	INSTR 5
	LEN 12
	NOTE D_, 4
	INSTR 0
	NOTE F_, 2
	NOTE G_, 2
	LEN 24
	NOTE C_, 2
	INSTR 4
	LEN 12
	NOTE C_, 4
	INSTR 0
	LEN 24
	NOTE G_, 2
	LEN 12
	NOTE G_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	LEN 24
	NOTE C_, 2
	INSTR 4
	LEN 12
	NOTE C_, 4
	INSTR 0
	LEN 24
	NOTE G_, 2
	LEN 12
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	NEXT
Pat_54CE:
	HWENV $82, $00
	DUTY_12
	ARP 0
	LEN 12
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE Ash, 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE Ash, 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE Ash, 3
	NOTE D_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE Csh, 5
	NOTE E_, 4
	NOTE A_, 4
	NOTE Csh, 5
	NOTE A_, 4
	NOTE E_, 4
	NEXT
Pat_5515:
	REPEAT 5
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	REPEAT_END
	NOTE D_, 4
	NOTE C_, 4
	NOTE E_, 4
	REPEAT 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE E_, 4
	REPEAT_END
	NOTE G_, 4
	NOTE C_, 4
	NOTE Ash, 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE Ash, 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE C_, 4
	NEXT
Pat_5545:
	LEN 12
	NOTE E_, 4
	LEN 24
	NOTE F_, 4
	LEN 12
	NOTE G_, 4
	NOTE G_, 4
	LEN 24
	NOTE A_, 4
	LEN 12
	NOTE Ash, 4
	NOTE Ash, 4
	LEN 24
	NOTE A_, 4
	LEN 12
	NOTE Ash, 4
	NOTE A_, 4
	LEN 24
	NOTE F_, 4
	LEN 12
	NOTE A_, 4
	NOTE E_, 4
	LEN 24
	NOTE F_, 4
	LEN 12
	NOTE G_, 4
	NOTE G_, 4
	LEN 24
	NOTE A_, 4
	LEN 12
	NOTE Ash, 4
	NOTE Ash, 4
	LEN 24
	NOTE A_, 4
	LEN 12
	NOTE Ash, 4
	NOTE A_, 4
	LEN 24
	NOTE D_, 4
	LEN 12
	NOTE A_, 4
	NOTE E_, 4
	LEN 24
	NOTE F_, 4
	LEN 12
	NOTE G_, 4
	NOTE G_, 4
	LEN 24
	NOTE A_, 4
	LEN 12
	NOTE Ash, 4
	NOTE Ash, 4
	LEN 24
	NOTE A_, 4
	LEN 12
	NOTE Ash, 4
	NOTE A_, 4
	LEN 24
	NOTE F_, 4
	LEN 12
	NOTE A_, 4
	NOTE E_, 4
	LEN 24
	NOTE F_, 4
	LEN 12
	NOTE G_, 4
	NOTE G_, 4
	LEN 24
	NOTE A_, 4
	LEN 12
	NOTE C_, 5
	NOTE C_, 5
	LEN 24
	NOTE G_, 4
	LEN 12
	NOTE C_, 5
	NOTE G_, 4
	LEN 24
	NOTE E_, 4
	LEN 12
	NOTE A_, 4
	NEXT
Pat_5597:
	LEN 12
	NOTE F_, 4
	LEN 24
	NOTE E_, 4
	LEN 12
	NOTE F_, 4
	LEN 24
	NOTE E_, 4
	LEN 12
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 24
	NOTE E_, 4
	LEN 12
	NOTE F_, 4
	LEN 24
	NOTE E_, 4
	LEN 12
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 24
	NOTE E_, 4
	LEN 12
	NOTE F_, 4
	LEN 24
	NOTE E_, 4
	LEN 12
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 24
	NOTE E_, 4
	LEN 12
	NOTE F_, 4
	LEN 24
	NOTE E_, 4
	LEN 12
	NOTE F_, 4
	NOTE E_, 4
	NOTE A_, 4
	LEN 24
	NOTE D_, 4
	LEN 12
	NOTE A_, 4
	LEN 24
	NOTE D_, 4
	LEN 12
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 4
	LEN 24
	NOTE D_, 4
	LEN 12
	NOTE A_, 4
	LEN 24
	NOTE D_, 4
	LEN 12
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 4
	LEN 24
	NOTE D_, 4
	LEN 12
	NOTE A_, 4
	LEN 24
	NOTE D_, 4
	LEN 12
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 4
	NEXT
Pat_55E7:
	INSTR 13
	WAVE Wave_7DB2
	CH_TRANSPOSE $0C
	VIBRATO $14, $01, $06
	ARP_OFF
	LEN 12
	NOTE D_, 4
	LEN 24
	NOTE E_, 4
	LEN 12
	NOTE F_, 4
	ARP 3
	LENGTH $54
	NOTE G_, 4
	ARP_OFF
	LEN 12
	NOTE A_, 4
	ARP 3
	NOTE G_, 4
	ARP_OFF
	NOTE G_, 4
	NOTE F_, 4
	NOTE A_, 4
	LEN 36
	NOTE G_, 4
	NOTE E_, 4
	LEN 24
	NOTE G_, 4
	LENGTH $3C
	NOTE C_, 4
	LEN 12
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	ARP 3
	LEN 24
	NOTE Dsh, 4
	ARP_OFF
	LEN 12
	NOTE E_, 4
	LEN 24
	NOTE D_, 4
	LEN 12
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 3
	LEN 24
	NOTE G_, 3
	LEN 36
	NOTE C_, 4
	LENGTH $3C
	NOTE A_, 3
	LEN 12
	NOTE E_, 3
	NOTE G_, 3
	NOTE G_, 3
	ARP 3
	LENGTH $60
	NOTE G_, 3
	NEXT
Pat_5630:
	ARP_OFF
	LEN 12
	NOTE D_, 4
	LEN 24
	NOTE E_, 4
	LEN 12
	NOTE F_, 4
	ARP 3
	LENGTH $54
	NOTE G_, 4
	ARP_OFF
	LEN 12
	NOTE A_, 4
	ARP 3
	NOTE G_, 4
	ARP_OFF
	NOTE G_, 4
	NOTE F_, 4
	NOTE A_, 4
	ARP 3
	LEN 36
	NOTE Ash, 4
	ARP_OFF
	NOTE A_, 4
	LEN 24
	NOTE C_, 5
	LENGTH $3C
	NOTE E_, 4
	LEN 12
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	LEN 36
	NOTE D_, 4
	NOTE F_, 4
	LEN 24
	NOTE A_, 4
	NOTE G_, 4
	LEN 12
	NOTE E_, 4
	LEN 24
	NOTE C_, 4
	LEN 12
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	LEN 24
	NOTE D_, 4
	LEN 12
	NOTE D_, 4
	NOTE C_, 4
	LENGTH $6C
	NOTE D_, 4
	NEXT
Pat_566C:
	INSTR 6
	CH_TRANSPOSE $00
	ARP_OFF
	WAVE Wave_7DF2
	LEN 12
	NOTE D_, 4
	NOTE Ash, 3
	NOTE F_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE F_, 3
	LENGTH $30
	NOTE D_, 4
	LEN 24
	NOTE F_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 12
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	LENGTH $30
	NOTE F_, 4
	LEN 24
	NOTE D_, 5
	NOTE A_, 4
	NOTE F_, 4
	LEN 12
	NOTE D_, 4
	NOTE Ash, 3
	NOTE F_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE F_, 3
	LENGTH $30
	NOTE D_, 4
	LEN 24
	NOTE F_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE F_, 4
	LEN 12
	NOTE G_, 4
	LEN 24
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	LEN 12
	NOTE C_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 24
	NOTE G_, 4
	LEN 12
	NOTE E_, 4
	NOTE F_, 4
	NEXT
Pat_56AE:
	LEN 12
	NOTE D_, 4
	NOTE Ash, 3
	NOTE F_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE F_, 3
	LENGTH $30
	NOTE D_, 4
	LEN 24
	NOTE F_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 12
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	LENGTH $30
	NOTE F_, 4
	LEN 24
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE D_, 5
	LEN 12
	NOTE A_, 4
	LEN 24
	NOTE G_, 4
	LEN 12
	NOTE E_, 4
	NOTE C_, 5
	LEN 24
	NOTE A_, 4
	LEN 12
	NOTE F_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE E_, 4
	NOTE G_, 3
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 3
	NOTE F_, 4
	LEN 24
	NOTE G_, 4
	NOTE A_, 4
	NEXT
Pat_56EC:
	LENGTH $A8
	NOTE D_, 4
	LEN 24
	NOTE C_, 4
	LEN 12
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	LEN 24
	NOTE D_, 4
	LEN 12
	NOTE D_, 4
	NOTE C_, 4
	LENGTH $48
	NOTE D_, 4
	LEN 12
	NOTE A_, 3
	LEN 24
	NOTE C_, 4
	LENGTH $A8
	NOTE D_, 4
	LEN 24
	NOTE C_, 4
	LEN 12
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	LEN 24
	NOTE D_, 4
	LEN 12
	NOTE D_, 4
	NOTE F_, 4
	LENGTH $3C
	NOTE C_, 4
	LEN 12
	NOTE A_, 4
	NOTE Ash, 4
	LEN 24
	NOTE G_, 4
	NEXT
DrumPat_5718:
	db DRUM_LEVEL + 14, DRUM_REPEAT + 7, 1, 0, 6, 0, 9, 0
	db 6, 0, DRUM_REPEAT_END, 1, 0, 9, 0, 9
	db 0, 4, 0, DRUM_REPEAT + 7, 1, 0, 6, 0
	db 9, 0, 6, 0, DRUM_REPEAT_END, 1, 0, 9
	db 0, 9, 0, 9, 0, DRUM_LOOP

; Song 6: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong6:
	ld a, $76
	ld [wInstrTableHi], a
	ld a, $3C
	ld [wInstrTable], a
	call StopAll
	ld de, Song6_Ch1
	call StartMusicCh1
	ld de, Song6_Ch2
	call StartMusicCh2
	ld de, Song6_Ch3
	jp StartMusicCh3
Song6_Ch1:
	dw Pat_5799
	dw Pat_57C3
	dw Pat_5799
	dw Pat_57C3
	dw Pat_57DD
	dw Pat_582E
	dw Pat_582E
	dw Pat_57C3
	ORDER_LOOP Song6_Ch1
Song6_Ch2:
	dw Pat_585D
	dw Pat_5874
	dw Pat_585D
	dw Pat_5874
	dw Pat_5880
	dw Pat_58A5
	dw Pat_58A5
	dw Pat_5874
	ORDER_LOOP Song6_Ch2
Song6_Ch3:
	dw Pat_58BA
	dw Pat_5906
	dw Pat_58BA
	dw Pat_5906
	dw Pat_590A
	dw Pat_5942
	dw Pat_5942
	dw Pat_5906
	ORDER_LOOP Song6_Ch3
Pat_5799:
	LEN 12
	REPEAT 8
	INSTR 0
	NOTE G_, 2
	INSTR 3
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 3
	NOTE D_, 4
	REPEAT_END
	REPEAT 4
	INSTR 0
	NOTE Ash, 2
	INSTR 3
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 3
	NOTE F_, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE G_, 2
	INSTR 3
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 3
	NOTE D_, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE F_, 2
	INSTR 3
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	REPEAT_END
	NEXT
Pat_57C3:
	REPEAT 2
	INSTR 0
	NOTE G_, 2
	INSTR 3
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 3
	NOTE D_, 4
	REPEAT_END
	INSTR 0
	NOTE G_, 2
	INSTR 3
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 3
	NOTE D_, 4
	INSTR 0
	NOTE Ash, 2
	INSTR 3
	NOTE D_, 4
	INSTR 0
	NOTE C_, 3
	NOTE D_, 3
	NEXT
Pat_57DD:
	REPEAT 2
	INSTR 0
	NOTE C_, 3
	INSTR 3
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 3
	NOTE G_, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE G_, 2
	INSTR 3
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 3
	NOTE D_, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE F_, 2
	INSTR 3
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE F_, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE G_, 2
	INSTR 3
	NOTE Ash, 3
	INSTR 0
	NOTE D_, 2
	INSTR 3
	NOTE Ash, 3
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE C_, 3
	INSTR 3
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 3
	NOTE G_, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE G_, 2
	INSTR 3
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 3
	NOTE D_, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE A_, 2
	INSTR 3
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 3
	NOTE E_, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE D_, 3
	INSTR 3
	NOTE Fsh, 4
	INSTR 0
	NOTE A_, 2
	INSTR 3
	NOTE Fsh, 4
	REPEAT_END
	NEXT
Pat_582E:
	REPEAT 2
	INSTR 0
	NOTE G_, 2
	INSTR 3
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 3
	NOTE D_, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE C_, 3
	INSTR 3
	NOTE Dsh, 4
	INSTR 0
	NOTE G_, 2
	INSTR 3
	NOTE Dsh, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE D_, 3
	INSTR 3
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 3
	NOTE D_, 4
	REPEAT_END
	INSTR 0
	NOTE C_, 3
	INSTR 3
	NOTE Dsh, 4
	INSTR 0
	NOTE G_, 2
	INSTR 3
	NOTE Dsh, 4
	INSTR 0
	NOTE D_, 2
	INSTR 3
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 3
	NOTE D_, 4
	NEXT
Pat_585D:
	INSTR 3
	DUTY_75
	LEN 12
	REST
	LEN 24
	REPEAT 8
	NOTE Ash, 3
	NOTE Ash, 3
	REPEAT_END
	REPEAT 4
	NOTE D_, 4
	NOTE D_, 4
	REPEAT_END
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 12
	NOTE A_, 3
	NEXT
Pat_5874:
	LEN 12
	WAIT
	LEN 24
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	LEN 36
	NOTE Ash, 3
	NEXT
Pat_5880:
	LEN 12
	WAIT
	LEN 24
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	LEN 12
	NOTE A_, 4
	NEXT
Pat_58A5:
	LEN 12
	WAIT
	LEN 24
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE C_, 4
	NOTE A_, 3
	LEN 12
	NOTE A_, 3
	NEXT
Pat_58BA:
	DRUMS $06, DrumPat_597D
	VOLENV 11, $12, $1A, $17
	VIBRATO $0C, $01, $06
	RELEASE $01, $51
	WAVE Wave_7DE2
	LEN 12
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	LENGTH $60
	NOTE G_, 3
	LEN 12
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE C_, 4
	LENGTH $48
	NOTE D_, 4
	LEN 24
	NOTE G_, 4
	LEN 12
	NOTE F_, 4
	NOTE D_, 4
	NOTE Ash, 3
	NOTE G_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE Ash, 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE D_, 4
	LEN 24
	NOTE F_, 4
	LEN 12
	NOTE F_, 4
	NOTE G_, 4
	LENGTH $48
	NOTE D_, 4
	LEN 12
	NOTE F_, 4
	NOTE G_, 4
	LENGTH $3C
	NOTE C_, 4
	LEN 12
	NOTE Ash, 3
	NOTE A_, 3
	NOTE F_, 3
	NEXT
Pat_5906:
	LENGTH $C0
	NOTE G_, 3
	NEXT
Pat_590A:
	LEN 12
	NOTE Dsh, 4
	NOTE D_, 4
	LEN 36
	NOTE Dsh, 4
	LEN 12
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE Ash, 3
	LENGTH $3C
	NOTE G_, 3
	LEN 12
	NOTE G_, 3
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE Ash, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE F_, 3
	LENGTH $60
	NOTE D_, 3
	LEN 12
	NOTE Dsh, 4
	NOTE D_, 4
	LEN 36
	NOTE Dsh, 4
	LEN 12
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE G_, 4
	LENGTH $30
	NOTE G_, 4
	LEN 24
	NOTE G_, 4
	LEN 12
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	LENGTH $60
	NOTE D_, 5
	NEXT
Pat_5942:
	REPEAT 2
	LEN 12
	NOTE G_, 3
	LEN 6
	NOTE G_, 3
	NOTE A_, 3
	LEN 12
	NOTE Ash, 3
	LEN 6
	NOTE Ash, 3
	NOTE C_, 4
	LEN 12
	NOTE D_, 4
	LEN 6
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE Ash, 3
	REPEAT_END
	LEN 12
	NOTE G_, 3
	LEN 6
	NOTE G_, 3
	NOTE A_, 3
	LEN 12
	NOTE Ash, 3
	LEN 6
	NOTE Ash, 3
	NOTE C_, 4
	LEN 12
	NOTE D_, 4
	LEN 6
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	LEN 12
	NOTE C_, 4
	LEN 6
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	LEN 12
	NOTE A_, 3
	LEN 6
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE Ash, 3
	NOTE A_, 3
	NEXT
DrumPat_597D:
	db DRUM_LEVEL + 13, 1, 0, 6, 0, 9, 0, 6
	db 0, DRUM_LOOP

; Song 7: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong7:
	ld a, $76
	ld [wInstrTableHi], a
	ld a, $3C
	ld [wInstrTable], a
	call StopAll
	ld de, Song7_Ch1
	call StartMusicCh1
	ld de, Song7_Ch2
	call StartMusicCh2
	ld de, Song7_Ch3
	jp StartMusicCh3
Song7_Ch1:
	dw Pat_59D0
	dw Pat_59E3
	dw Pat_59E3
	dw Pat_5A64
	dw Pat_5AE5
	ORDER_LOOP Song7_Ch1
Song7_Ch2:
	dw Pat_5B66
	dw Pat_5B77
	dw Pat_5B77
	dw Pat_5BBA
	dw Pat_5BEE
	ORDER_LOOP Song7_Ch2
Song7_Ch3:
	dw Pat_5C22
	dw Pat_5C4A
	dw Pat_5C4A
	dw Pat_5C76
	dw Pat_5CA4
	ORDER_LOOP Song7_Ch3
Pat_59D0:
	REPEAT 4
	INSTR 0
	LEN 20
	NOTE F_, 2
	INSTR 3
	LEN 10
	NOTE F_, 4
	INSTR 0
	LEN 20
	NOTE A_, 2
	INSTR 3
	LEN 10
	NOTE F_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 3
	NOTE F_, 4
	REPEAT_END
	NEXT
Pat_59E3:
	INSTR 0
	LEN 20
	NOTE F_, 2
	INSTR 3
	LEN 10
	NOTE A_, 3
	INSTR 0
	LEN 20
	NOTE G_, 2
	INSTR 3
	LEN 10
	NOTE Ash, 3
	INSTR 0
	NOTE G_, 2
	INSTR 3
	NOTE Ash, 3
	INSTR 0
	LEN 20
	NOTE A_, 2
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	LEN 20
	NOTE Ash, 2
	INSTR 3
	LEN 10
	NOTE D_, 4
	INSTR 0
	NOTE Ash, 2
	INSTR 3
	NOTE D_, 4
	INSTR 0
	LEN 20
	NOTE F_, 2
	INSTR 3
	LEN 10
	NOTE A_, 3
	INSTR 0
	LEN 20
	NOTE C_, 3
	INSTR 3
	LEN 10
	NOTE G_, 3
	INSTR 0
	NOTE C_, 3
	INSTR 3
	NOTE G_, 3
	INSTR 0
	LEN 20
	NOTE F_, 2
	INSTR 3
	LEN 10
	NOTE A_, 3
	INSTR 0
	LEN 20
	NOTE C_, 3
	INSTR 3
	LEN 10
	NOTE A_, 3
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE A_, 3
	INSTR 0
	LEN 20
	NOTE F_, 2
	INSTR 3
	LEN 10
	NOTE A_, 3
	INSTR 0
	LEN 20
	NOTE G_, 2
	INSTR 3
	LEN 10
	NOTE Ash, 3
	INSTR 0
	NOTE G_, 2
	INSTR 3
	NOTE Ash, 3
	INSTR 0
	LEN 20
	NOTE A_, 2
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	LEN 20
	NOTE Ash, 2
	INSTR 3
	LEN 10
	NOTE D_, 4
	INSTR 0
	NOTE Ash, 2
	INSTR 3
	NOTE D_, 4
	INSTR 0
	LEN 20
	NOTE C_, 3
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	LEN 20
	NOTE C_, 2
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	INSTR 0
	LEN 20
	NOTE F_, 2
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	LEN 20
	NOTE C_, 2
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 3
	NOTE C_, 4
	NEXT
Pat_5A64:
	INSTR 0
	LEN 20
	NOTE Ash, 2
	INSTR 3
	LEN 10
	NOTE F_, 4
	INSTR 0
	LEN 20
	NOTE F_, 3
	INSTR 3
	LEN 10
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 3
	NOTE F_, 4
	INSTR 0
	LEN 20
	NOTE Ash, 2
	INSTR 3
	LEN 10
	NOTE F_, 4
	INSTR 0
	LEN 20
	NOTE F_, 3
	INSTR 3
	LEN 10
	NOTE F_, 4
	INSTR 0
	NOTE Ash, 2
	INSTR 3
	NOTE F_, 4
	INSTR 0
	LEN 20
	NOTE F_, 2
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	LEN 20
	NOTE C_, 3
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	INSTR 0
	LEN 20
	NOTE F_, 2
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	LEN 20
	NOTE C_, 3
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 3
	NOTE C_, 4
	INSTR 0
	LEN 20
	NOTE C_, 2
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	LEN 20
	NOTE G_, 2
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 3
	NOTE C_, 4
	INSTR 0
	LEN 20
	NOTE C_, 2
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	LEN 20
	NOTE G_, 2
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 3
	NOTE C_, 4
	INSTR 0
	LEN 20
	NOTE F_, 2
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	LEN 20
	NOTE F_, 3
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 3
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 3
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 3
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 3
	NOTE E_, 4
	NEXT
Pat_5AE5:
	INSTR 0
	LEN 20
	NOTE Ash, 2
	INSTR 3
	LEN 10
	NOTE F_, 4
	INSTR 0
	LEN 20
	NOTE F_, 3
	INSTR 3
	LEN 10
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 3
	NOTE F_, 4
	INSTR 0
	LEN 20
	NOTE Ash, 2
	INSTR 3
	LEN 10
	NOTE F_, 4
	INSTR 0
	LEN 20
	NOTE F_, 3
	INSTR 3
	LEN 10
	NOTE F_, 4
	INSTR 0
	NOTE Ash, 2
	INSTR 3
	NOTE F_, 4
	INSTR 0
	LEN 20
	NOTE F_, 2
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	LEN 20
	NOTE C_, 3
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	INSTR 0
	LEN 20
	NOTE F_, 2
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	LEN 20
	NOTE C_, 3
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 3
	NOTE C_, 4
	INSTR 0
	LEN 20
	NOTE C_, 2
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	LEN 20
	NOTE G_, 2
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 3
	NOTE C_, 4
	INSTR 0
	LEN 20
	NOTE C_, 2
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	LEN 20
	NOTE G_, 2
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 3
	NOTE C_, 4
	INSTR 0
	LEN 20
	NOTE F_, 2
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	LEN 20
	NOTE F_, 3
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 3
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 3
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 3
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 3
	NOTE E_, 4
	NEXT
Pat_5B66:
	DRUMS $05, DrumPat_5CCD
	INSTR 3
	REPEAT 4
	LEN 20
	NOTE F_, 4
	LEN 10
	NOTE C_, 4
	LEN 20
	NOTE F_, 4
	NOTE C_, 4
	LEN 10
	NOTE C_, 4
	REPEAT_END
	NEXT
Pat_5B77:
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE C_, 4
	LEN 20
	NOTE D_, 4
	NOTE D_, 4
	LEN 10
	NOTE D_, 4
	LEN 20
	NOTE E_, 4
	LEN 10
	NOTE E_, 4
	LEN 20
	NOTE F_, 4
	NOTE F_, 4
	LEN 10
	NOTE F_, 4
	REPEAT 2
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE C_, 4
	LEN 20
	NOTE C_, 4
	NOTE C_, 4
	LEN 10
	NOTE C_, 4
	REPEAT_END
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE C_, 4
	LEN 20
	NOTE D_, 4
	NOTE D_, 4
	LEN 10
	NOTE D_, 4
	LEN 20
	NOTE E_, 4
	LEN 10
	NOTE E_, 4
	LEN 20
	NOTE F_, 4
	NOTE F_, 4
	LEN 10
	NOTE F_, 4
	LEN 20
	NOTE F_, 4
	LEN 10
	NOTE F_, 4
	LEN 20
	NOTE F_, 4
	NOTE F_, 4
	LEN 10
	NOTE E_, 4
	LEN 20
	NOTE F_, 4
	LEN 10
	NOTE F_, 4
	LEN 20
	NOTE F_, 4
	LEN 10
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NEXT
Pat_5BBA:
	REPEAT 2
	LEN 20
	NOTE D_, 4
	LEN 10
	NOTE D_, 4
	LEN 20
	NOTE D_, 4
	LEN 10
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	REPEAT_END
	REPEAT 2
	LEN 20
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	LEN 20
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	REPEAT_END
	REPEAT 2
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE G_, 3
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	REPEAT_END
	LEN 20
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	LEN 20
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 20
	NOTE A_, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NEXT
Pat_5BEE:
	REPEAT 2
	LEN 20
	NOTE D_, 4
	LEN 10
	NOTE D_, 4
	LEN 20
	NOTE D_, 4
	LEN 10
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	REPEAT_END
	REPEAT 2
	LEN 20
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	LEN 20
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	REPEAT_END
	REPEAT 2
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE G_, 3
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	REPEAT_END
	LEN 20
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	LEN 20
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 20
	NOTE A_, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NEXT
Pat_5C22:
	LEN 20
	REST
	INSTR 3
	CH_TRANSPOSE $00
	RELEASE $01, $01
	WAVE Wave_7DF2
	VOLENV 10, $11, $1F, $12
	LEN 30
	NOTE A_, 3
	LEN 20
	NOTE A_, 3
	LEN 30
	NOTE A_, 3
	NOTE A_, 3
	LEN 20
	NOTE A_, 3
	LEN 30
	NOTE A_, 3
	NOTE A_, 3
	LEN 20
	NOTE A_, 3
	LEN 30
	NOTE A_, 3
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	CH_TRANSPOSE $0C
	INSTR 6
	NOTE F_, 3
	NOTE G_, 3
	NEXT
Pat_5C4A:
	LEN 20
	NOTE A_, 3
	NOTE C_, 4
	NOTE Ash, 3
	NOTE D_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE Ash, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE Ash, 3
	NOTE A_, 3
	LEN 10
	NOTE G_, 3
	LEN 30
	NOTE F_, 3
	LEN 10
	NOTE F_, 3
	NOTE G_, 3
	LEN 20
	NOTE A_, 3
	NOTE C_, 4
	NOTE Ash, 3
	NOTE D_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE Ash, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE C_, 4
	LEN 10
	NOTE G_, 3
	LEN 20
	NOTE Ash, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE F_, 3
	LEN 10
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NEXT
Pat_5C76:
	INSTR 13
	WAVE Wave_7DB2
	LENGTH $5A
	NOTE F_, 4
	LEN 10
	NOTE G_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE G_, 4
	LENGTH $5A
	NOTE C_, 4
	LEN 10
	NOTE D_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	LEN 30
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	LEN 10
	NOTE D_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	LENGTH $64
	NOTE A_, 3
	LEN 20
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	NEXT
Pat_5CA4:
	LENGTH $5A
	NOTE F_, 4
	LEN 10
	NOTE G_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE G_, 4
	LENGTH $5A
	NOTE C_, 4
	LEN 10
	NOTE D_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	LEN 30
	NOTE C_, 4
	NOTE G_, 4
	NOTE C_, 4
	LEN 10
	NOTE D_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE G_, 4
	LENGTH $5A
	NOTE F_, 4
	LENGTH $46
	WAIT2
	NEXT
DrumPat_5CCD:
	db DRUM_LEVEL + 13, 1, 0, 6, 0, 9, 0, 6
	db 0, 1, 0, 6, 0, 9, 0, 6
	db 0, 1, 0, 6, 0, 9, 0, 1
	db 0, 6, 0, 1, 0, 9, 0, 6
	db 0, DRUM_LOOP

; Song 8: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong8:
	call StopAll
	ld a, $76
	ld [wInstrTableHi], a
	ld a, $3C
	ld [wInstrTable], a
	ld de, Song8_Ch1
	call StartMusicCh1
	ld de, Song8_Ch2
	call StartMusicCh2
	ld de, Song8_Ch3
	jp StartMusicCh3
Song8_Ch1:
	dw Pat_5D26
	dw Pat_5D99
	ORDER_LOOP Song8_Ch1
Song8_Ch2:
	dw Pat_5E0D
	dw Pat_5E5A
	ORDER_LOOP Song8_Ch2
Song8_Ch3:
	dw Pat_5EA2
	dw Pat_5EDF
	ORDER_LOOP Song8_Ch3
Pat_5D26:
	DRUMS $0B, DrumPat_5F09
	INSTR 0
	LEN 22
	NOTE C_, 3
	INSTR 4
	LEN 11
	NOTE C_, 4
	INSTR 0
	LEN 33
	NOTE C_, 3
	INSTR 4
	LEN 11
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	LEN 22
	NOTE C_, 3
	INSTR 4
	LEN 11
	NOTE C_, 4
	INSTR 0
	LEN 33
	NOTE C_, 3
	INSTR 4
	LEN 11
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	LEN 22
	NOTE F_, 2
	INSTR 4
	LEN 11
	NOTE F_, 4
	INSTR 0
	LEN 33
	NOTE F_, 2
	INSTR 4
	LEN 11
	NOTE F_, 4
	INSTR 0
	NOTE G_, 2
	LEN 22
	NOTE C_, 3
	INSTR 4
	LEN 11
	NOTE C_, 4
	INSTR 0
	LEN 33
	NOTE C_, 3
	INSTR 4
	LEN 11
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	LEN 22
	NOTE C_, 3
	INSTR 4
	LEN 11
	NOTE C_, 4
	INSTR 0
	LEN 22
	NOTE C_, 3
	INSTR 4
	LEN 11
	NOTE C_, 4
	INSTR 0
	NOTE B_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	LEN 22
	NOTE A_, 2
	INSTR 5
	LEN 11
	NOTE A_, 4
	INSTR 0
	LEN 33
	NOTE A_, 2
	INSTR 5
	LEN 11
	NOTE A_, 4
	INSTR 0
	NOTE A_, 2
	LEN 22
	NOTE D_, 3
	INSTR 5
	LEN 11
	NOTE D_, 5
	INSTR 0
	LEN 33
	NOTE D_, 3
	INSTR 5
	LEN 11
	NOTE D_, 5
	INSTR 0
	NOTE A_, 2
	LEN 22
	NOTE G_, 2
	INSTR 4
	LEN 11
	NOTE G_, 4
	INSTR 0
	LEN 22
	NOTE G_, 2
	INSTR 4
	LEN 11
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	NEXT
Pat_5D99:
	INSTR 0
	LEN 22
	NOTE C_, 3
	INSTR 4
	LEN 11
	NOTE C_, 4
	INSTR 0
	LEN 33
	NOTE C_, 3
	INSTR 4
	LEN 11
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	LEN 22
	NOTE C_, 3
	INSTR 4
	LEN 11
	NOTE C_, 4
	INSTR 0
	LEN 22
	NOTE C_, 3
	INSTR 4
	LEN 11
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	LEN 22
	NOTE F_, 2
	INSTR 4
	LEN 11
	NOTE F_, 4
	INSTR 0
	LEN 22
	NOTE F_, 2
	INSTR 4
	LEN 11
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 0
	LEN 22
	NOTE F_, 2
	INSTR 5
	LEN 11
	NOTE F_, 4
	INSTR 0
	LEN 22
	NOTE F_, 2
	INSTR 5
	LEN 11
	NOTE F_, 4
	INSTR 0
	NOTE Gsh, 2
	INSTR 5
	NOTE F_, 4
	INSTR 0
	LEN 22
	NOTE C_, 3
	INSTR 4
	LEN 11
	NOTE C_, 4
	INSTR 0
	LEN 33
	NOTE C_, 3
	INSTR 4
	LEN 11
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	LEN 22
	NOTE G_, 2
	INSTR 4
	LEN 11
	NOTE G_, 4
	INSTR 0
	LEN 33
	NOTE G_, 2
	INSTR 4
	LEN 11
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	LEN 22
	NOTE C_, 3
	INSTR 4
	LEN 11
	NOTE C_, 4
	INSTR 0
	LEN 33
	NOTE C_, 3
	INSTR 4
	LEN 11
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	LEN 22
	NOTE C_, 3
	INSTR 4
	LEN 11
	NOTE C_, 4
	INSTR 0
	LEN 22
	NOTE C_, 3
	INSTR 4
	LEN 11
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	NEXT
Pat_5E0D:
	CH_TRANSPOSE $F4
	INSTR 10
	LEN 11
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 5
	NOTE E_, 5
	LEN 22
	NOTE G_, 5
	LEN 11
	NOTE E_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 5
	NOTE E_, 5
	LEN 22
	NOTE G_, 5
	LEN 11
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE A_, 4
	NOTE C_, 5
	LEN 22
	NOTE F_, 5
	LEN 11
	NOTE A_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 4
	NOTE C_, 5
	LEN 22
	NOTE E_, 5
	LEN 11
	NOTE G_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 5
	NOTE E_, 5
	LEN 22
	NOTE G_, 5
	LEN 11
	NOTE E_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE A_, 5
	NOTE C_, 5
	NOTE E_, 5
	LEN 22
	NOTE A_, 5
	LEN 11
	NOTE E_, 5
	NOTE D_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE D_, 5
	NOTE F_, 5
	LEN 22
	NOTE A_, 5
	LEN 11
	NOTE D_, 5
	NOTE B_, 4
	NOTE D_, 5
	NOTE G_, 5
	NOTE B_, 4
	NOTE D_, 5
	LEN 22
	NOTE G_, 5
	LEN 11
	NOTE B_, 4
	NEXT
Pat_5E5A:
	LEN 11
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 5
	NOTE E_, 5
	LEN 22
	NOTE G_, 5
	LEN 11
	NOTE E_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 5
	NOTE E_, 5
	LEN 22
	NOTE G_, 5
	LEN 11
	NOTE C_, 5
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE A_, 4
	LEN 22
	NOTE C_, 5
	LEN 11
	NOTE A_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE Gsh, 4
	LEN 22
	NOTE C_, 5
	LEN 11
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE C_, 6
	NOTE G_, 5
	NOTE E_, 5
	LEN 22
	NOTE A_, 5
	LEN 11
	NOTE A_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE E_, 5
	LEN 22
	NOTE C_, 5
	LEN 11
	NOTE E_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE A_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE G_, 4
	NEXT
Pat_5EA2:
	VOLENV 14, $00, $1F, $15
	VIBRATO $0B, $01, $05
	ARP 12
	WAVE Wave_7DF2
	LEN 22
	NOTE E_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	LENGTH $42
	NOTE E_, 4
	LEN 11
	NOTE D_, 4
	NOTE C_, 4
	LEN 22
	NOTE A_, 3
	NOTE C_, 4
	NOTE C_, 4
	LEN 11
	NOTE A_, 3
	LENGTH $4D
	NOTE G_, 3
	LEN 11
	NOTE C_, 4
	NOTE D_, 4
	LEN 22
	NOTE E_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE A_, 4
	LEN 11
	NOTE E_, 4
	LEN 33
	NOTE D_, 4
	LEN 22
	NOTE C_, 4
	LENGTH $37
	NOTE D_, 4
	LEN 11
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	LENGTH $42
	NOTE D_, 4
	LEN 11
	NOTE C_, 4
	NOTE D_, 4
	NEXT
Pat_5EDF:
	LEN 22
	NOTE E_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	LENGTH $42
	NOTE E_, 4
	LEN 11
	NOTE D_, 4
	NOTE C_, 4
	LEN 22
	NOTE A_, 3
	NOTE C_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE Gsh, 3
	LEN 11
	NOTE C_, 4
	LEN 33
	NOTE C_, 4
	LEN 22
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	LEN 11
	NOTE C_, 4
	LEN 22
	NOTE D_, 4
	LEN 11
	NOTE D_, 4
	LEN 22
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	LENGTH $8F
	NOTE C_, 4
	LEN 33
	WAIT2
	NEXT
DrumPat_5F09:
	db DRUM_LEVEL + 14, 1, DRUM_LEVEL + 13, 6, DRUM_LEVEL + 14, 9, DRUM_LEVEL + 12, 6
	db DRUM_LOOP

; Song 9: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong9:
	ld a, $76
	ld [wInstrTableHi], a
	ld a, $3C
	ld [wInstrTable], a
	call StopAll
	ld de, Song9_Ch1
	call StartMusicCh1
	ld de, Song9_Ch2
	call StartMusicCh2
	ld de, Song9_Ch3
	jp StartMusicCh3
Song9_Ch1:
	dw Pat_5F71
	dw Pat_5F71
	dw Pat_5F73
	dw Pat_5F73
	dw Pat_5F88
	dw Pat_5F88
	dw Pat_5F73
	dw Pat_5F90
	dw Pat_5F90
	ORDER_LOOP Song9_Ch1
Song9_Ch2:
	dw Pat_5FBD
	dw Pat_5FBD
	dw Pat_5FBD
	dw Pat_5FBD
	dw Pat_6007
	dw Pat_6007
	dw Pat_5FBD
	dw Pat_600F
	dw Pat_6036
	ORDER_LOOP Song9_Ch2
Song9_Ch3:
	dw Pat_607F
	dw Pat_607F
	dw Pat_60A8
	dw Pat_60CE
	dw Pat_60F7
	dw Pat_6124
	dw Pat_6158
	dw Pat_61A0
	ORDER_LOOP Song9_Ch3
Pat_5F71:
	TRANSPOSE $02
Pat_5F73:
	INSTR 11
	LEN 14
	REPEAT 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE G_, 2
	REPEAT_END
	NEXT
Pat_5F88:
	CH_TRANSPOSE $03
	PAT_CALL Pat_5F71
	CH_TRANSPOSE $00
	NEXT
Pat_5F90:
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE D_, 2
	LEN 42
	NOTE G_, 2
	INSTR 5
	LEN 14
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 4
	INSTR 4
	NOTE F_, 4
	INSTR 5
	NOTE D_, 4
	LEN 28
	NOTE G_, 4
	INSTR 11
	LEN 14
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 2
	INSTR 5
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 4
	INSTR 4
	NOTE F_, 4
	INSTR 5
	NOTE D_, 4
	INSTR 4
	NOTE F_, 4
	INSTR 5
	NOTE G_, 4
	NOTE D_, 4
	INSTR 11
	NOTE D_, 2
	NEXT
Pat_5FBD:
	INSTR 1
	LEN 14
	NOTE C_, 3
	INSTR 10
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE F_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE D_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE F_, 3
	INSTR 1
	LEN 7
	NOTE C_, 3
	INSTR 10
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	INSTR 1
	LEN 14
	NOTE C_, 3
	INSTR 10
	NOTE D_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE F_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE D_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE C_, 3
	INSTR 1
	LEN 7
	NOTE C_, 3
	INSTR 10
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	INSTR 1
	LEN 14
	NOTE C_, 3
	INSTR 10
	NOTE G_, 3
	NEXT
Pat_6007:
	CH_TRANSPOSE $03
	PAT_CALL Pat_5FBD
	CH_TRANSPOSE $00
	NEXT
Pat_600F:
	REPEAT 2
	INSTR 1
	LEN 14
	NOTE C_, 3
	INSTR 10
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE F_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE D_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE F_, 3
	INSTR 1
	LEN 7
	NOTE C_, 3
	INSTR 10
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	INSTR 1
	LEN 14
	NOTE C_, 3
	NOTE C_, 3
	REPEAT_END
	NEXT
Pat_6036:
	INSTR 1
	LEN 14
	NOTE C_, 3
	INSTR 10
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE F_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE D_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE F_, 3
	INSTR 1
	LEN 7
	NOTE C_, 3
	INSTR 10
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	INSTR 1
	LEN 14
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	INSTR 10
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE F_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE D_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 10
	NOTE F_, 3
	INSTR 1
	LEN 7
	NOTE C_, 3
	INSTR 10
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	INSTR 1
	LEN 14
	NOTE C_, 3
	LEN 7
	NOTE C_, 3
	NOTE C_, 3
	NEXT
Pat_607F:
	DRUMS $07, DrumPat_61E3
	CH_TRANSPOSE $00
	VIBRATO $0E, $02, $05
	WAVE Wave_7DE2
	VOLENV 12, $11, $1F, $13
	RELEASE $01, $01
	ARP 5
	LEN 28
	NOTE G_, 3
	LENGTH $B6
	NOTE G_, 3
	ARP 4
	LEN 14
	NOTE F_, 3
	ARP 5
	LEN 28
	NOTE G_, 3
	LENGTH $C4
	NOTE G_, 3
	CH_TRANSPOSE $0C
	RELEASE $01, $51
	NEXT
Pat_60A8:
	INSTR 9
	LEN 28
	NOTE G_, 3
	LEN 14
	NOTE F_, 3
	NOTE G_, 3
	ARP 3
	LEN 28
	NOTE G_, 3
	INSTR 9
	LEN 14
	NOTE G_, 3
	NOTE F_, 3
	LEN 28
	NOTE G_, 3
	LENGTH $38
	NOTE D_, 3
	LEN 14
	NOTE D_, 3
	NOTE F_, 3
	LEN 28
	NOTE G_, 3
	LEN 14
	NOTE F_, 3
	NOTE G_, 3
	ARP 3
	NOTE G_, 3
	INSTR 9
	NOTE A_, 3
	NOTE G_, 3
	NOTE F_, 3
	LENGTH $62
	NOTE D_, 3
	LEN 14
	NOTE D_, 3
	NEXT
Pat_60CE:
	INSTR 9
	LEN 28
	NOTE G_, 3
	LEN 14
	NOTE F_, 3
	NOTE G_, 3
	ARP 3
	LEN 28
	NOTE G_, 3
	INSTR 9
	LEN 14
	NOTE G_, 3
	NOTE F_, 3
	LEN 28
	NOTE G_, 3
	LENGTH $38
	NOTE D_, 3
	LEN 14
	NOTE D_, 3
	NOTE F_, 3
	LEN 28
	NOTE G_, 3
	LEN 14
	NOTE Ash, 3
	ARP 3
	NOTE C_, 4
	INSTR 9
	NOTE C_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE F_, 3
	LEN 28
	NOTE F_, 3
	ARP 3
	NOTE F_, 3
	INSTR 9
	LENGTH $38
	NOTE G_, 3
	NEXT
Pat_60F7:
	INSTR 9
	LEN 28
	NOTE Ash, 3
	LEN 14
	NOTE Gsh, 3
	NOTE Ash, 3
	ARP 3
	LEN 28
	NOTE Ash, 3
	ARP_OFF
	LEN 14
	NOTE Ash, 3
	NOTE Gsh, 3
	LEN 28
	NOTE Ash, 3
	NOTE F_, 3
	INSTR 12
	LEN 14
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE F_, 4
	INSTR 9
	NOTE F_, 3
	LEN 28
	NOTE Ash, 3
	LEN 14
	NOTE Gsh, 3
	NOTE Ash, 3
	ARP 3
	NOTE Ash, 3
	INSTR 9
	NOTE C_, 4
	NOTE Ash, 3
	NOTE Gsh, 3
	LEN 42
	NOTE F_, 3
	INSTR 12
	LEN 14
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	INSTR 9
	NOTE F_, 3
	NEXT
Pat_6124:
	INSTR 9
	LEN 28
	NOTE Ash, 3
	LEN 14
	NOTE Gsh, 3
	NOTE Ash, 3
	ARP 3
	NOTE Ash, 3
	INSTR 9
	NOTE C_, 4
	NOTE Ash, 3
	NOTE Gsh, 3
	LEN 28
	NOTE Ash, 3
	NOTE F_, 3
	INSTR 12
	LEN 7
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	LEN 14
	NOTE Gsh, 4
	NOTE Ash, 4
	INSTR 9
	LEN 28
	NOTE Ash, 3
	LEN 14
	NOTE Gsh, 3
	NOTE Ash, 3
	ARP 3
	NOTE Ash, 3
	INSTR 9
	NOTE C_, 4
	NOTE Ash, 3
	NOTE Gsh, 3
	ARP 3
	LEN 28
	NOTE Dsh, 4
	INSTR 9
	LEN 14
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Ash, 3
	INSTR 12
	LEN 7
	NOTE F_, 3
	NOTE F_, 3
	LEN 14
	NOTE Dsh, 3
	NOTE F_, 3
	NEXT
Pat_6158:
	ARP 0
	VOLENV 15, $21, $1F, $11
	GLIDE $FF
	WAVE Wave_7DB2
	LEN 7
	NOTE B_, 3
	NOTE B_, 3
	LEN 14
	NOTE B_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE E_, 3
	NOTE E_, 3
	LEN 14
	NOTE E_, 3
	LEN 42
	NOTE D_, 3
	LEN 7
	NOTE B_, 3
	NOTE B_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 14
	NOTE A_, 3
	NOTE D_, 4
	NOTE D_, 4
	LEN 28
	NOTE D_, 4
	LEN 7
	NOTE A_, 3
	NOTE A_, 3
	LEN 14
	NOTE A_, 3
	LEN 21
	NOTE D_, 4
	LEN 7
	NOTE A_, 3
	LEN 14
	NOTE A_, 3
	LEN 7
	NOTE A_, 3
	NOTE A_, 3
	LEN 14
	NOTE D_, 4
	NOTE A_, 3
	NOTE A_, 3
	LEN 7
	NOTE F_, 3
	NOTE F_, 3
	LEN 14
	NOTE F_, 3
	NOTE D_, 3
	LEN 7
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE F_, 3
	LEN 14
	NOTE D_, 3
	REST
	GLIDE_OFF
	NEXT
Pat_61A0:
	DRUMS $07, DrumPat_6225
	LENGTH $62
	REST
	INSTR 9
	LEN 14
	NOTE D_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE D_, 3
	LENGTH $70
	NOTE G_, 3
	LEN 42
	REST
	LEN 14
	NOTE D_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE D_, 3
	NOTE F_, 3
	NOTE G_, 3
	LEN 28
	NOTE D_, 3
	LENGTH $62
	WAIT
	INSTR 9
	LEN 14
	NOTE D_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE D_, 3
	LENGTH $38
	NOTE G_, 3
	DRUMS $07, DrumPat_6204
	LEN 28
	NOTE G_, 3
	LEN 14
	NOTE Ash, 3
	NOTE D_, 4
	LEN 28
	NOTE C_, 4
	LEN 14
	NOTE A_, 3
	NOTE F_, 3
	LEN 28
	NOTE F_, 3
	ARP 3
	NOTE F_, 3
	INSTR 9
	LEN 7
	NOTE Ash, 3
	NOTE A_, 3
	LEN 42
	NOTE G_, 3
	NEXT
DrumPat_61E3:
	db DRUM_LEVEL + 14, 1, 0, 6, 0, 9, 0, 6
	db 0, 1, 0, 6, 0, 9, 0, 4
	db 0, 1, 0, 6, 0, 9, 0, 6
	db 0, 1, 6, 6, 6, 9, 0, 4
	db 0
DrumPat_6204:
	db 1, 0, 6, 0, 9, 0, 6, 0
	db 1, 0, 6, 0, 9, 0, 4, 0
	db 1, 0, 6, 0, 9, 0, 6, 0
	db 1, 6, 6, 6, 9, 0, 10, 10
	db DRUM_LOOP
DrumPat_6225:
	db DRUM_REPEAT + 3, 1, 0, 6, 0, DRUM_REPEAT_END, 9, 0
	db 6, 0, DRUM_LOOP

; Song 10: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong10:
	ld a, $76
	ld [wInstrTableHi], a
	ld a, $3C
	ld [wInstrTable], a
	call StopAll
	ld de, Song10_Ch1
	call StartMusicCh1
	ld de, Song10_Ch2
	call StartMusicCh2
	ld de, Song10_Ch3
	jp StartMusicCh3
Song10_Ch1:
	dw Pat_6273
	dw Pat_628E
	dw Pat_6273
	dw Pat_62B6
	ORDER_LOOP Song10_Ch1
Song10_Ch2:
	dw Pat_62D6
	dw Pat_6309
	dw Pat_62D6
	dw Pat_633A
	ORDER_LOOP Song10_Ch2
Song10_Ch3:
	dw Pat_636B
	dw Pat_63B4
	dw Pat_636B
	dw Pat_63F5
	ORDER_LOOP Song10_Ch3
Pat_6273:
	INSTR 0
	LEN 21
	NOTE A_, 2
	INSTR 4
	NOTE A_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 4
	NOTE A_, 3
	INSTR 0
	NOTE A_, 2
	NOTE A_, 2
	NOTE Gsh, 2
	NOTE Fsh, 2
	NOTE E_, 2
	INSTR 4
	NOTE E_, 3
	INSTR 0
	NOTE B_, 2
	INSTR 4
	NOTE E_, 3
	INSTR 0
	NOTE E_, 2
	NOTE E_, 2
	NOTE Dsh, 2
	NOTE Csh, 2
	NEXT
Pat_628E:
	INSTR 0
	LEN 21
	NOTE B_, 2
	INSTR 4
	NOTE B_, 3
	INSTR 0
	NOTE Fsh, 2
	INSTR 4
	NOTE B_, 3
	INSTR 0
	LEN 14
	NOTE B_, 2
	LEN 7
	NOTE B_, 2
	LEN 21
	NOTE A_, 2
	NOTE Gsh, 2
	NOTE Fsh, 2
	NOTE E_, 2
	INSTR 4
	NOTE E_, 4
	INSTR 0
	NOTE B_, 2
	INSTR 4
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	LEN 14
	NOTE E_, 2
	LEN 7
	NOTE E_, 2
	LEN 14
	NOTE Fsh, 2
	LEN 7
	NOTE Fsh, 2
	LEN 14
	NOTE Gsh, 2
	LEN 7
	NOTE Gsh, 2
	NEXT
Pat_62B6:
	INSTR 0
	LEN 21
	NOTE B_, 2
	INSTR 4
	NOTE B_, 3
	INSTR 0
	NOTE Fsh, 2
	INSTR 4
	NOTE B_, 3
	INSTR 0
	LEN 14
	NOTE B_, 2
	LEN 7
	NOTE B_, 2
	LEN 21
	NOTE A_, 2
	NOTE Gsh, 2
	NOTE Fsh, 2
	NOTE E_, 2
	INSTR 4
	NOTE E_, 4
	INSTR 0
	NOTE B_, 2
	INSTR 4
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	NOTE B_, 2
	NOTE E_, 2
	INSTR 4
	NOTE E_, 4
	NEXT
Pat_62D6:
	INSTR 3
	DUTY_75
	LEN 14
	NOTE Csh, 5
	LEN 21
	NOTE E_, 5
	LEN 7
	NOTE B_, 4
	LEN 14
	NOTE Csh, 5
	LEN 21
	NOTE E_, 5
	LEN 7
	NOTE B_, 4
	LEN 14
	NOTE Csh, 5
	LEN 21
	NOTE E_, 5
	LEN 7
	NOTE B_, 4
	LEN 14
	NOTE Csh, 5
	LEN 21
	NOTE E_, 5
	LEN 7
	NOTE Csh, 5
	LEN 14
	NOTE Csh, 5
	LEN 21
	NOTE B_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE Gsh, 4
	LEN 21
	NOTE B_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE Gsh, 4
	LEN 21
	NOTE B_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE Gsh, 4
	LEN 21
	NOTE B_, 4
	LEN 7
	NOTE B_, 4
	NEXT
Pat_6309:
	LEN 14
	NOTE Fsh, 4
	LEN 21
	NOTE A_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE Fsh, 4
	LEN 21
	NOTE A_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE Fsh, 4
	LEN 21
	NOTE A_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE Fsh, 4
	LEN 21
	NOTE A_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE Gsh, 4
	LEN 21
	NOTE B_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE Gsh, 4
	LEN 21
	NOTE B_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE Gsh, 4
	LEN 21
	NOTE B_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE Gsh, 4
	LEN 21
	NOTE B_, 4
	LEN 7
	NOTE B_, 4
	NEXT
Pat_633A:
	LEN 14
	NOTE Fsh, 4
	LEN 21
	NOTE A_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE Fsh, 4
	LEN 21
	NOTE A_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE Fsh, 4
	LEN 21
	NOTE A_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE Fsh, 4
	LEN 21
	NOTE A_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE Gsh, 4
	LEN 21
	NOTE B_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE Gsh, 4
	LEN 21
	NOTE B_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE Gsh, 4
	LEN 21
	NOTE B_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE Gsh, 4
	LEN 21
	NOTE B_, 4
	LEN 7
	NOTE B_, 4
	NEXT
Pat_636B:
	DRUMS $07, DrumPat_6431
	INSTR 6
	WAVE Wave_7DE2
	LEN 14
	NOTE Csh, 4
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE Csh, 4
	LEN 14
	NOTE E_, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE Csh, 4
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE Csh, 4
	LEN 14
	NOTE E_, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE Csh, 4
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE Csh, 4
	LEN 14
	NOTE B_, 3
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE Gsh, 4
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE E_, 4
	LEN 7
	NOTE Gsh, 4
	LEN 14
	NOTE B_, 3
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE Gsh, 4
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE E_, 4
	LEN 7
	NOTE Gsh, 4
	LEN 14
	NOTE B_, 3
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Csh, 4
	NEXT
Pat_63B4:
	LEN 14
	NOTE B_, 3
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE Fsh, 4
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE B_, 3
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE Fsh, 4
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE B_, 3
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE Fsh, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE B_, 3
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE Gsh, 4
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE E_, 4
	LEN 7
	NOTE Gsh, 4
	LEN 14
	NOTE B_, 3
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE Gsh, 4
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE E_, 4
	LEN 7
	NOTE Gsh, 4
	LEN 14
	NOTE B_, 3
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE Gsh, 4
	LEN 7
	NOTE B_, 3
	NEXT
Pat_63F5:
	LEN 14
	NOTE B_, 3
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE Fsh, 4
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE B_, 3
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE Fsh, 4
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE B_, 3
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE Fsh, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE E_, 4
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE Gsh, 3
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE E_, 4
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE Gsh, 3
	LEN 7
	NOTE B_, 3
	NOTE Csh, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE E_, 3
	NOTE Gsh, 3
	NOTE B_, 3
	LEN 21
	NOTE E_, 4
	NEXT
DrumPat_6431:
	db 1, 0, 6, 9, 0, 6, 1, 0
	db 6, 9, 0, 1, 1, 0, 6, 9
	db 0, 1, 6, 0, 1, 9, 0, 9
	db DRUM_LOOP

; Song 11: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong11:
	ld a, $76
	ld [wInstrTableHi], a
	ld a, $3C
	ld [wInstrTable], a
	call StopAll
	ld de, Song11_Ch1
	call StartMusicCh1
	ld de, Song11_Ch2
	call StartMusicCh2
	ld de, Song11_Ch3
	jp StartMusicCh3
Song11_Ch1:
	dw Pat_647B

; Unreferenced (4 bytes)
	db $00, $00, $69, $64
Song11_Ch2:
	dw Pat_6494

; Unreferenced (4 bytes)
	db $00, $00, $6F, $64
Song11_Ch3:
	dw Pat_64A7

; Unreferenced (4 bytes)
	db $00, $00, $75, $64
Pat_647B:
	HWENV $F7, $00
	DUTY_12
	VIBRATO $10, $01, $06
	ARP 12
	LEN 12
	NOTE D_, 3
	LENGTH $54
	NOTE A_, 3
	LEN 12
	NOTE C_, 3
	LENGTH $54
	NOTE G_, 3
	LEN 12
	NOTE D_, 3
	LENGTH $B4
	NOTE A_, 3
	END
Pat_6494:
	HWENV $F7, $00
	DUTY_12
	VIBRATO $10, $01, $06
	ARP 12
	LEN 6
	REST
	LENGTH $60
	NOTE F_, 3
	NOTE E_, 3
	LENGTH $BA
	NOTE F_, 3
	END
Pat_64A7:
	VIBRATO $18, $01, $06
	CH_TRANSPOSE $0C
	INSTR 13
	LENGTH $30
	NOTE A_, 4
	LEN 24
	NOTE C_, 5
	NOTE A_, 4
	ARP 3
	NOTE G_, 4
	ARP_OFF
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	ARP 3
	LENGTH $C0
	NOTE C_, 4
	END

; Song 12: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong12:
	ld a, $76
	ld [wInstrTableHi], a
	ld a, $3C
	ld [wInstrTable], a
	call StopAll
	ld de, Song12_Ch1
	call StartMusicCh1
	ld de, Song12_Ch2
	call StartMusicCh2
	ld de, Song12_Ch3
	jp StartMusicCh3
Song12_Ch1:
	dw Pat_64F6
	dw Pat_6525
	ORDER_LOOP Song12_Ch1
Song12_Ch2:
	dw Pat_6552
	dw Pat_65A0
	ORDER_LOOP Song12_Ch2
Song12_Ch3:
	dw Pat_65E8
	dw Pat_6637
	ORDER_LOOP Song12_Ch3
Pat_64F6:
	RELEASE $02, $41
	INSTR 0
	LEN 36
	NOTE Ash, 2
	NOTE Ash, 2
	LEN 24
	NOTE Ash, 2
	LEN 36
	NOTE Gsh, 2
	NOTE Gsh, 2
	LEN 24
	NOTE G_, 2
	LEN 36
	NOTE F_, 2
	NOTE F_, 2
	LEN 12
	NOTE F_, 2
	NOTE Dsh, 2
	LEN 36
	NOTE F_, 2
	NOTE F_, 2
	LEN 24
	NOTE Gsh, 2
	LEN 36
	NOTE Ash, 2
	NOTE Ash, 2
	LEN 24
	NOTE Ash, 2
	LEN 36
	NOTE Gsh, 2
	NOTE Gsh, 2
	LEN 24
	NOTE Dsh, 2
	LEN 36
	NOTE F_, 2
	NOTE F_, 2
	LEN 24
	NOTE Dsh, 2
	LEN 36
	NOTE Gsh, 2
	NOTE Gsh, 2
	LEN 12
	NOTE Dsh, 2
	NOTE Gsh, 2
	NEXT
Pat_6525:
	LEN 36
	NOTE Ash, 2
	NOTE Ash, 2
	LEN 24
	NOTE Ash, 2
	LEN 36
	NOTE C_, 3
	NOTE G_, 2
	LEN 24
	NOTE Dsh, 2
	LEN 36
	NOTE Csh, 2
	NOTE F_, 2
	LEN 24
	NOTE Gsh, 2
	LEN 36
	NOTE Dsh, 2
	NOTE G_, 2
	LEN 24
	NOTE Gsh, 2
	LEN 36
	NOTE Ash, 2
	NOTE Ash, 2
	LEN 24
	NOTE Ash, 2
	LEN 36
	NOTE C_, 3
	NOTE G_, 2
	LEN 24
	NOTE Dsh, 2
	LEN 36
	NOTE Csh, 2
	NOTE F_, 2
	LEN 24
	NOTE Gsh, 2
	NOTE Dsh, 2
	LEN 12
	NOTE Dsh, 2
	LEN 24
	NOTE G_, 2
	LEN 12
	NOTE G_, 2
	NOTE Ash, 2
	NOTE Dsh, 2
	NEXT
Pat_6552:
	HWENV $C1, $00
	DUTY_12
	ARP 5
	LEN 12
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	ARP 4
	NOTE Gsh, 4
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
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	ARP 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	ARP 5
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	ARP 4
	NOTE Gsh, 4
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
	NOTE F_, 4
	ARP 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NEXT
Pat_65A0:
	ARP 5
	LEN 12
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	ARP 4
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE Dsh, 5
	ARP 5
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	ARP 4
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Csh, 5
	ARP 5
	NOTE F_, 5
	NOTE F_, 5
	NOTE F_, 5
	ARP 4
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE Dsh, 5
	NEXT
Pat_65E8:
	DRUMS $06, DrumPat_6675
	VOLENV 15, $11, $14, $16
	WAVE Wave_7E72
	CH_TRANSPOSE $0C
	VIBRATO $0C, $01, $05
	RELEASE $02, $51
	LENGTH $30
	NOTE Ash, 3
	LEN 12
	NOTE Ash, 2
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	LEN 36
	NOTE C_, 4
	NOTE Gsh, 3
	LEN 12
	NOTE Dsh, 3
	LENGTH $3C
	NOTE F_, 3
	LEN 12
	NOTE F_, 2
	NOTE Gsh, 2
	NOTE C_, 3
	NOTE Dsh, 3
	LEN 24
	NOTE F_, 3
	LEN 12
	NOTE Gsh, 3
	LEN 36
	NOTE G_, 3
	LEN 24
	NOTE F_, 3
	LENGTH $30
	NOTE Ash, 3
	LEN 12
	NOTE Ash, 2
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	LEN 36
	NOTE C_, 4
	NOTE Gsh, 3
	LEN 24
	NOTE Dsh, 3
	NOTE F_, 3
	LEN 12
	NOTE F_, 3
	LEN 24
	NOTE C_, 4
	LEN 36
	NOTE F_, 3
	LEN 24
	NOTE Gsh, 3
	LEN 12
	NOTE Gsh, 3
	LEN 24
	NOTE Dsh, 4
	NOTE Gsh, 3
	LEN 12
	NOTE Gsh, 3
	NEXT
Pat_6637:
	LENGTH $30
	NOTE Ash, 3
	LEN 12
	NOTE Ash, 2
	NOTE F_, 3
	NOTE Ash, 3
	NOTE Csh, 4
	LENGTH $30
	NOTE C_, 4
	LEN 12
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE Dsh, 4
	LEN 36
	NOTE Csh, 4
	LEN 12
	NOTE Gsh, 3
	NOTE Csh, 3
	NOTE Gsh, 3
	NOTE Csh, 4
	NOTE F_, 4
	LEN 24
	NOTE Dsh, 4
	LEN 12
	NOTE Ash, 3
	LEN 36
	NOTE Dsh, 4
	LEN 12
	NOTE Ash, 3
	NOTE Gsh, 3
	LENGTH $30
	NOTE Ash, 3
	LEN 12
	NOTE Ash, 2
	NOTE F_, 3
	NOTE Ash, 3
	NOTE Csh, 4
	LEN 24
	NOTE C_, 4
	LEN 12
	NOTE G_, 3
	LEN 36
	NOTE C_, 4
	LEN 24
	NOTE G_, 3
	LENGTH $3C
	NOTE F_, 3
	LEN 24
	NOTE Gsh, 3
	LEN 12
	NOTE Ash, 3
	LEN 24
	NOTE C_, 4
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE G_, 3
	NEXT
DrumPat_6675:
	db DRUM_LEVEL + 14, 9, 0, 10, 10, 10, 0, 9
	db 0, 10, 0, 10, 0, 9, 0, 10
	db 0, 9, 0, 10, 10, 10, 0, 9
	db 0, 10, 10, 10, 0, 9, 0, 10
	db 10, 9, 0, 10, 10, 10, 0, 9
	db 0, 10, 0, 10, 0, 9, 0, 10
	db 0, 9, 0, 10, 10, 10, 0, 9
	db 0, 10, 10, 10, 0, 9, 9, 9
	db 9, DRUM_LOOP

; Song 13: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong13:
	ld a, $76
	ld [wInstrTableHi], a
	ld a, $3C
	ld [wInstrTable], a
	call StopAll
	ld de, Song13_Ch1
	call StartMusicCh1
	ld de, Song13_Ch2
	call StartMusicCh2
	ld de, Song13_Ch3
	jp StartMusicCh3
Song13_Ch1:
	dw Pat_6706
	dw Pat_674C
	dw Pat_6706
	dw Pat_674C
	dw Pat_678E
	dw Pat_67D0
	ORDER_LOOP Song13_Ch1
Song13_Ch2:
	dw Pat_6812
	dw Pat_6839
	dw Pat_6812
	dw Pat_6839
	dw Pat_685B
	dw Pat_686D
	ORDER_LOOP Song13_Ch2
Song13_Ch3:
	dw Pat_6882
	dw Pat_68A6
	dw Pat_6882
	dw Pat_68A6
	dw Pat_68C0
	dw Pat_68DA
	ORDER_LOOP Song13_Ch3
Pat_6706:
	DRUMS $07, DrumPat_4DC3
	INSTR 0
	LEN 14
	NOTE A_, 2
	INSTR 5
	NOTE A_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 5
	NOTE A_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 5
	NOTE A_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 5
	NOTE A_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 5
	NOTE A_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 5
	NOTE A_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 5
	NOTE A_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 5
	NOTE A_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE G_, 3
	NEXT
Pat_674C:
	INSTR 0
	LEN 14
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
	NOTE D_, 2
	INSTR 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 4
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 4
	NOTE D_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	NOTE D_, 3
	INSTR 4
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	NOTE D_, 3
	INSTR 4
	NOTE G_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 4
	NOTE E_, 3
	INSTR 0
	NOTE B_, 2
	INSTR 4
	NOTE E_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 4
	NOTE E_, 3
	INSTR 0
	NOTE B_, 2
	INSTR 4
	NOTE E_, 3
	NEXT
Pat_678E:
	INSTR 0
	LEN 14
	NOTE A_, 2
	INSTR 5
	NOTE A_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 5
	NOTE A_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 5
	NOTE A_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 5
	NOTE A_, 3
	INSTR 0
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 5
	NOTE A_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 5
	NOTE A_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE Gsh, 2
	INSTR 4
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 4
	NOTE E_, 4
	NEXT
Pat_67D0:
	INSTR 0
	LEN 14
	NOTE D_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 5
	NOTE D_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE D_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 5
	NOTE D_, 4
	INSTR 0
	NOTE D_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 5
	NOTE D_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 4
	NOTE E_, 4
	INSTR 0
	NOTE B_, 2
	INSTR 4
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 4
	NOTE E_, 4
	INSTR 0
	NOTE B_, 2
	INSTR 4
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 4
	NOTE E_, 4
	INSTR 0
	NOTE B_, 2
	INSTR 4
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 4
	NOTE E_, 4
	INSTR 0
	NOTE B_, 2
	INSTR 4
	NOTE E_, 4
	NEXT
Pat_6812:
	HWENV $C2, $00
	ARP 0
	DUTY_75
	LEN 14
	NOTE E_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE E_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE E_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE G_, 3
	NEXT
Pat_6839:
	LEN 14
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE E_, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE E_, 4
	NOTE B_, 3
	NEXT
Pat_685B:
	LEN 28
	NOTE E_, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE E_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE E_, 3
	NEXT
Pat_686D:
	LEN 28
	NOTE A_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	LEN 14
	NOTE E_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NEXT
Pat_6882:
	INSTR 13
	VIBRATO $0E, $01, $05
	CH_TRANSPOSE $0C
	WAVE Wave_7DB2
	LENGTH $46
	NOTE A_, 4
	LEN 14
	NOTE E_, 4
	NOTE A_, 4
	NOTE C_, 5
	LEN 42
	NOTE B_, 4
	NOTE A_, 4
	LEN 28
	NOTE G_, 4
	LENGTH $46
	NOTE A_, 4
	LEN 14
	NOTE E_, 4
	NOTE A_, 4
	NOTE C_, 5
	LEN 42
	NOTE D_, 5
	NOTE B_, 4
	LEN 14
	NOTE G_, 4
	NOTE D_, 4
	NEXT
Pat_68A6:
	LENGTH $46
	NOTE E_, 4
	LEN 14
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	LEN 28
	NOTE Fsh, 4
	LEN 14
	NOTE G_, 4
	LEN 42
	NOTE A_, 4
	LEN 28
	NOTE D_, 4
	LENGTH $46
	NOTE B_, 4
	LEN 14
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	LENGTH $70
	NOTE B_, 4
	NEXT
Pat_68C0:
	LEN 14
	WAIT
	NOTE E_, 3
	NOTE A_, 3
	NOTE C_, 4
	LEN 28
	NOTE B_, 3
	LEN 14
	NOTE A_, 3
	NOTE G_, 3
	LENGTH $7E
	NOTE E_, 3
	LEN 14
	NOTE E_, 3
	NOTE A_, 3
	NOTE C_, 4
	LEN 28
	NOTE B_, 3
	LEN 14
	NOTE A_, 3
	NOTE G_, 3
	LENGTH $70
	NOTE E_, 4
	NEXT
Pat_68DA:
	LEN 14
	WAIT
	NOTE A_, 3
	NOTE D_, 4
	NOTE F_, 4
	LEN 28
	NOTE E_, 4
	LEN 14
	NOTE D_, 4
	NOTE C_, 4
	LEN 28
	NOTE D_, 4
	LEN 42
	NOTE A_, 3
	LEN 14
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	LEN 28
	NOTE B_, 3
	NOTE E_, 3
	NOTE E_, 4
	LEN 14
	NOTE A_, 3
	NOTE C_, 4
	LEN 28
	NOTE B_, 3
	NOTE E_, 3
	NOTE E_, 4
	LEN 14
	NOTE B_, 3
	NOTE E_, 3
	NEXT

; Song 14: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong14:
	ld a, $76
	ld [wInstrTableHi], a
	ld a, $3C
	ld [wInstrTable], a
	call StopAll
	ld de, Song14_Ch1
	call StartMusicCh1
	ld de, Song14_Ch2
	call StartMusicCh2
	ld de, Song14_Ch3
	jp StartMusicCh3
Song14_Ch1:
	dw Pat_692C
	ORDER_LOOP Song14_Ch1
Song14_Ch2:
	dw Pat_694D
	ORDER_LOOP Song14_Ch2
Song14_Ch3:
	dw Pat_6993
	ORDER_LOOP Song14_Ch3
Pat_692C:
	HWENV $5F, $46, $A7
	DUTY_50
	VIBRATO $0A, $02, $06
	LENGTH $98
	NOTE G_, 2
	NOTE F_, 2
	NOTE G_, 2
	LENGTH $4C
	NOTE D_, 2
	NOTE F_, 2
	LENGTH $98
	NOTE G_, 2
	NOTE F_, 2
	LENGTH $4C
	NOTE Dsh, 2
	NOTE F_, 2
	NOTE G_, 2
	LEN 19
	NOTE Ash, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NEXT
Pat_694D:
	HWENV $40, $00
	VIBRATO $14, $01, $06
	DUTY_50
	LEN 20
	WAIT
	ARP 3
	LENGTH $5F
	NOTE C_, 5
	ARP_OFF
	LEN 19
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	ARP 3
	NOTE C_, 5
	ARP_OFF
	LENGTH $4C
	NOTE A_, 4
	LEN 19
	NOTE F_, 4
	NOTE D_, 4
	LENGTH $5F
	NOTE G_, 4
	LEN 19
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE E_, 4
	LENGTH $72
	NOTE D_, 4
	ARP 3
	LENGTH $5F
	NOTE C_, 5
	ARP_OFF
	LEN 19
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	ARP 3
	NOTE Ash, 4
	ARP_OFF
	NOTE D_, 5
	LENGTH $4C
	NOTE A_, 4
	LEN 19
	NOTE F_, 4
	NOTE D_, 4
	LENGTH $72
	NOTE G_, 4
	LEN 19
	NOTE F_, 4
	NOTE D_, 4
	LENGTH $84
	NOTE G_, 3
	NEXT
Pat_6993:
	VIBRATO $14, $01, $06
	INSTR 13
	ARP 3
	LENGTH $5F
	NOTE C_, 5
	ARP_OFF
	LEN 19
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	ARP 3
	NOTE C_, 5
	ARP_OFF
	LENGTH $4C
	NOTE A_, 4
	LEN 19
	NOTE F_, 4
	NOTE D_, 4
	LENGTH $5F
	NOTE G_, 4
	LEN 19
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE E_, 4
	LENGTH $72
	NOTE D_, 4
	ARP 3
	LENGTH $5F
	NOTE C_, 5
	ARP_OFF
	LEN 19
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	ARP 3
	NOTE Ash, 4
	ARP_OFF
	NOTE D_, 5
	LENGTH $4C
	NOTE A_, 4
	LEN 19
	NOTE F_, 4
	NOTE D_, 4
	LENGTH $72
	NOTE G_, 4
	LEN 19
	NOTE F_, 4
	NOTE D_, 4
	LENGTH $98
	NOTE G_, 3
	NEXT

; Song 15: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong15:
	ld a, $76
	ld [wInstrTableHi], a
	ld a, $3C
	ld [wInstrTable], a
	call StopAll
	ld de, Song15_Ch1
	call StartMusicCh1
	ld de, Song15_Ch2
	call StartMusicCh2
	ld de, Song15_Ch3
	jp StartMusicCh3
Song15_Ch1:
	dw Pat_6A05

; Unreferenced (4 bytes)
	db $00, $00, $F3, $69
Song15_Ch2:
	dw Pat_6A1E

; Unreferenced (4 bytes)
	db $00, $00, $F9, $69
Song15_Ch3:
	dw Pat_6A3C

; Unreferenced (4 bytes)
	db $00, $00, $FF, $69
Pat_6A05:
	INSTR 0
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE F_, 2
	LEN 28
	NOTE G_, 2
	NOTE Ash, 2
	LEN 14
	NOTE C_, 3
	NOTE G_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE F_, 2
	HWENV $F4, $00
	NOTE G_, 2
	LENGTH $9A
	WAIT
	WAIT
	WAIT
	WAIT
	END
Pat_6A1E:
	INSTR 5
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	INSTR 4
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	INSTR 5
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	HWENV $E4, $00
	NOTE G_, 4
	LENGTH $9A
	WAIT
	WAIT
	WAIT
	WAIT
	END
Pat_6A3C:
	CH_TRANSPOSE $0C
	INSTR 6
	LEN 42
	NOTE G_, 3
	LEN 28
	NOTE Ash, 3
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	NOTE Ash, 3
	NOTE F_, 3
	LEN 4
	NOTE G_, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	LENGTH $9A
	WAIT
	WAIT
	WAIT
	WAIT
	END

; Song 16: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong16:
	ld a, $76
	ld [wInstrTableHi], a
	ld a, $3C
	ld [wInstrTable], a
	call StopAll
	ld de, Song16_Ch1
	call StartMusicCh1
	ld de, Song16_Ch2
	call StartMusicCh2
	ld de, Song16_Ch3
	jp StartMusicCh3
Song16_Ch1:
	dw Pat_6A95
	dw Pat_6A95
	dw Pat_6AB7
	ORDER_LOOP Song16_Ch1
Song16_Ch2:
	dw Pat_6AD9
	dw Pat_6AD9
	dw Pat_6B27
	ORDER_LOOP Song16_Ch2
Song16_Ch3:
	dw Pat_6B75
	dw Pat_6B75
	dw Pat_6B9F
	ORDER_LOOP Song16_Ch3
Pat_6A95:
	INSTR 0
	LEN 28
	NOTE G_, 2
	NOTE D_, 2
	LEN 21
	NOTE G_, 2
	NOTE D_, 2
	LEN 14
	NOTE G_, 2
	LEN 28
	NOTE Ash, 2
	NOTE F_, 2
	LEN 21
	NOTE Ash, 2
	NOTE F_, 2
	LEN 14
	NOTE Ash, 2
	LEN 28
	NOTE F_, 2
	NOTE C_, 2
	LEN 21
	NOTE F_, 2
	NOTE C_, 2
	LEN 14
	NOTE F_, 2
	LEN 28
	NOTE D_, 2
	NOTE A_, 2
	LEN 21
	NOTE D_, 2
	NOTE A_, 2
	LEN 14
	NOTE D_, 2
	NEXT
Pat_6AB7:
	INSTR 0
	LEN 28
	NOTE G_, 2
	NOTE D_, 2
	LEN 21
	NOTE G_, 2
	NOTE D_, 2
	LEN 14
	NOTE G_, 2
	LEN 28
	NOTE Ash, 2
	NOTE F_, 2
	LEN 21
	NOTE Ash, 2
	NOTE F_, 2
	LEN 14
	NOTE Ash, 2
	LEN 28
	NOTE F_, 2
	NOTE C_, 2
	LEN 21
	NOTE F_, 2
	NOTE C_, 2
	LEN 14
	NOTE F_, 2
	LEN 28
	NOTE D_, 2
	NOTE A_, 2
	LEN 21
	NOTE D_, 2
	NOTE A_, 2
	LEN 14
	NOTE D_, 2
	NEXT
Pat_6AD9:
	INSTR 10
	LEN 14
	NOTE B_, 3
	INSTR 4
	NOTE G_, 3
	INSTR 10
	NOTE A_, 3
	INSTR 4
	NOTE G_, 3
	INSTR 10
	NOTE B_, 3
	INSTR 4
	LEN 7
	NOTE G_, 3
	INSTR 10
	LEN 21
	NOTE A_, 3
	INSTR 4
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE D_, 4
	INSTR 4
	NOTE Ash, 3
	INSTR 10
	NOTE C_, 4
	INSTR 4
	NOTE Ash, 3
	INSTR 10
	NOTE D_, 4
	INSTR 4
	LEN 7
	NOTE Ash, 3
	INSTR 10
	LEN 21
	NOTE C_, 4
	INSTR 4
	LEN 14
	NOTE Ash, 3
	INSTR 10
	NOTE A_, 3
	INSTR 4
	NOTE F_, 3
	INSTR 10
	NOTE G_, 3
	INSTR 4
	NOTE F_, 3
	INSTR 10
	NOTE A_, 3
	INSTR 4
	LEN 7
	NOTE F_, 3
	INSTR 10
	LEN 21
	NOTE G_, 3
	INSTR 4
	LEN 14
	NOTE F_, 3
	INSTR 10
	NOTE A_, 3
	INSTR 4
	NOTE D_, 3
	INSTR 10
	NOTE Fsh, 3
	INSTR 4
	NOTE D_, 3
	INSTR 10
	NOTE A_, 3
	INSTR 4
	LEN 7
	NOTE D_, 3
	INSTR 10
	LEN 21
	NOTE Fsh, 3
	INSTR 4
	LEN 14
	NOTE D_, 3
	NEXT
Pat_6B27:
	INSTR 10
	LEN 14
	NOTE B_, 3
	INSTR 4
	NOTE G_, 3
	INSTR 10
	NOTE A_, 3
	INSTR 4
	NOTE G_, 3
	INSTR 10
	NOTE B_, 3
	INSTR 4
	LEN 7
	NOTE G_, 3
	INSTR 10
	LEN 21
	NOTE A_, 3
	INSTR 4
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE D_, 4
	INSTR 4
	NOTE Ash, 3
	INSTR 10
	NOTE C_, 4
	INSTR 4
	NOTE Ash, 3
	INSTR 10
	NOTE D_, 4
	INSTR 4
	LEN 7
	NOTE Ash, 3
	INSTR 10
	LEN 21
	NOTE C_, 4
	INSTR 4
	LEN 14
	NOTE Ash, 3
	INSTR 10
	NOTE A_, 3
	INSTR 4
	NOTE F_, 3
	INSTR 10
	NOTE G_, 3
	INSTR 4
	NOTE F_, 3
	INSTR 10
	NOTE A_, 3
	INSTR 4
	LEN 7
	NOTE F_, 3
	INSTR 10
	LEN 21
	NOTE G_, 3
	INSTR 4
	LEN 14
	NOTE F_, 3
	INSTR 10
	NOTE A_, 3
	INSTR 4
	NOTE D_, 3
	INSTR 10
	NOTE Fsh, 3
	INSTR 4
	NOTE D_, 3
	INSTR 10
	NOTE A_, 3
	INSTR 4
	LEN 7
	NOTE D_, 3
	INSTR 10
	LEN 21
	NOTE Fsh, 3
	INSTR 4
	LEN 14
	NOTE D_, 3
	NEXT
Pat_6B75:
	DRUMS $07, DrumPat_6BDD
	INSTR 6
	ARP_OFF
	WAVE Wave_7DF2
	LEN 28
	NOTE G_, 3
	NOTE D_, 4
	LEN 21
	NOTE G_, 3
	NOTE D_, 4
	LEN 14
	NOTE G_, 3
	LEN 28
	NOTE Ash, 3
	NOTE F_, 4
	LEN 21
	NOTE Ash, 3
	NOTE F_, 4
	LEN 14
	NOTE Ash, 3
	LEN 28
	NOTE F_, 3
	NOTE C_, 4
	LEN 21
	NOTE F_, 3
	NOTE C_, 4
	LEN 14
	NOTE F_, 3
	LEN 28
	NOTE Fsh, 3
	NOTE C_, 4
	LEN 21
	NOTE D_, 4
	NOTE E_, 4
	LEN 14
	NOTE Fsh, 4
	NEXT
Pat_6B9F:
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE G_, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	LEN 7
	NOTE Ash, 4
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE Ash, 4
	LEN 21
	NOTE F_, 4
	LEN 7
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE D_, 5
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE C_, 4
	NOTE D_, 4
	LEN 14
	NOTE C_, 4
	NOTE A_, 3
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE F_, 4
	NOTE G_, 4
	LEN 21
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE E_, 4
	LEN 7
	NOTE D_, 4
	NOTE C_, 4
	NEXT
DrumPat_6BDD:
	db DRUM_LEVEL + 13, 1, 0, 6, 6, 1, 0, 6
	db 6, 1, 0, 6, 9, 1, 6, 6
	db 6, DRUM_LOOP

; Song 17: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong17:
	ld a, $76
	ld [wInstrTableHi], a
	ld a, $3C
	ld [wInstrTable], a
	call StopAll
	ld de, Song17_Ch1
	call StartMusicCh1
	ld de, Song17_Ch2
	call StartMusicCh2
	ld de, Song17_Ch3
	jp StartMusicCh3
Song17_Ch1:
	dw Pat_6C5C
	dw Pat_6D39
	dw Pat_6D54
	dw Pat_6C78
	dw Pat_6C99
	dw Pat_6CBE
	dw Pat_6CE3
	dw Pat_6D0D
	dw Pat_6D71
	dw Pat_6D71
	dw Pat_6D9C
	ORDER_LOOP Song17_Ch1
Song17_Ch2:
	dw Pat_6DC8
	dw Pat_6FBF
	dw Pat_700C
	dw Pat_6E19
	dw Pat_6E51
	dw Pat_6EAC
	dw Pat_6F07
	dw Pat_6F62
	dw Pat_705A
	dw Pat_705A
	dw Pat_7093
	ORDER_LOOP Song17_Ch2
Song17_Ch3:
	dw Pat_70CB
	dw Pat_71F1
	dw Pat_7210
	dw Pat_70F8
	dw Pat_711C
	dw Pat_7158
	dw Pat_7186
	dw Pat_71C0
	dw Pat_7237
	dw Pat_7237
	dw Pat_7282
	ORDER_LOOP Song17_Ch3
Pat_6C5C:
	TRANSPOSE $01
	INSTR 0
	LEN 42
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE Ash, 2
	NOTE D_, 3
	LEN 42
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE Ash, 2
	NOTE D_, 3
	LEN 42
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE Ash, 2
	NOTE D_, 3
	LEN 42
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE Ash, 2
	NOTE D_, 3
	NEXT
Pat_6C78:
	LEN 42
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE B_, 2
	NOTE D_, 3
	LEN 42
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE F_, 2
	NOTE D_, 2
	LEN 21
	NOTE G_, 2
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE B_, 2
	NOTE D_, 3
	LEN 21
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE F_, 2
	NEXT
Pat_6C99:
	LEN 21
	NOTE G_, 2
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE D_, 2
	NOTE F_, 2
	LEN 21
	NOTE G_, 2
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	LEN 21
	NOTE F_, 2
	NOTE F_, 2
	LEN 28
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	NOTE C_, 2
	NOTE F_, 2
	LEN 21
	NOTE G_, 2
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NEXT
Pat_6CBE:
	LEN 21
	NOTE G_, 2
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE D_, 2
	NOTE F_, 2
	LEN 21
	NOTE G_, 2
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	LEN 21
	NOTE F_, 2
	NOTE F_, 2
	LEN 28
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	NOTE C_, 2
	NOTE F_, 2
	LEN 21
	NOTE G_, 2
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NEXT
Pat_6CE3:
	LEN 21
	NOTE D_, 2
	NOTE D_, 2
	LEN 28
	NOTE D_, 2
	LEN 14
	NOTE D_, 2
	NOTE F_, 2
	NOTE Fsh, 2
	LEN 21
	NOTE G_, 2
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 2
	LEN 21
	NOTE F_, 2
	NOTE F_, 2
	LEN 28
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	LEN 21
	NOTE Dsh, 2
	NOTE G_, 2
	LEN 14
	NOTE Ash, 2
	NOTE Dsh, 2
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE Ash, 2
	LEN 7
	NOTE Dsh, 2
	NOTE G_, 2
	NOTE Ash, 2
	NEXT
Pat_6D0D:
	LEN 21
	NOTE D_, 2
	NOTE D_, 2
	LEN 28
	NOTE D_, 2
	LEN 14
	NOTE D_, 2
	NOTE F_, 2
	NOTE Fsh, 2
	LEN 21
	NOTE G_, 2
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 2
	LEN 21
	NOTE F_, 2
	NOTE F_, 2
	LEN 28
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	NOTE F_, 2
	NOTE Fsh, 2
	LEN 21
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE F_, 2
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE F_, 2
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE F_, 2
	NOTE G_, 2
	NEXT
Pat_6D39:
	LEN 42
	NOTE F_, 2
	NOTE F_, 2
	LEN 14
	NOTE A_, 2
	NOTE C_, 3
	LEN 42
	NOTE F_, 2
	NOTE F_, 2
	LEN 14
	NOTE A_, 2
	NOTE C_, 3
	LEN 42
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE Ash, 2
	NOTE D_, 3
	LEN 42
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE F_, 2
	NOTE Ash, 2
	NOTE A_, 2
	NEXT
Pat_6D54:
	LEN 42
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE Ash, 2
	NOTE D_, 3
	LEN 42
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE F_, 2
	NOTE D_, 2
	LEN 42
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE Ash, 2
	NOTE D_, 3
	LEN 42
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE F_, 2
	NOTE D_, 2
	NEXT
Pat_6D71:
	LEN 21
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE F_, 2
	LEN 21
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE D_, 3
	LEN 21
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE F_, 2
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE D_, 3
	LEN 7
	NOTE D_, 3
	LEN 14
	NOTE C_, 3
	LEN 7
	NOTE C_, 3
	LEN 14
	NOTE G_, 2
	NOTE F_, 2
	NEXT
Pat_6D9C:
	LEN 21
	NOTE G_, 2
	NOTE D_, 3
	LEN 14
	NOTE F_, 2
	LEN 21
	NOTE G_, 2
	NOTE D_, 3
	LEN 7
	NOTE D_, 2
	NOTE F_, 2
	LEN 21
	NOTE G_, 2
	NOTE D_, 3
	LEN 14
	NOTE F_, 2
	LEN 21
	NOTE G_, 2
	NOTE D_, 3
	LEN 7
	NOTE D_, 2
	NOTE F_, 2
	LEN 21
	NOTE G_, 2
	NOTE D_, 3
	LEN 14
	NOTE G_, 2
	LEN 21
	NOTE F_, 2
	NOTE C_, 3
	LEN 7
	NOTE F_, 2
	NOTE D_, 2
	LEN 21
	NOTE Dsh, 2
	NOTE Ash, 2
	LEN 14
	NOTE Dsh, 2
	LEN 21
	NOTE D_, 2
	NOTE F_, 2
	LEN 14
	NOTE A_, 2
	NEXT
Pat_6DC8:
	INSTR 5
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	INSTR 4
	NOTE F_, 3
	INSTR 5
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	INSTR 4
	NOTE F_, 3
	NOTE F_, 3
	INSTR 5
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	INSTR 4
	NOTE F_, 3
	INSTR 5
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	INSTR 4
	NOTE F_, 3
	NOTE F_, 3
	NEXT
Pat_6E19:
	INSTR 4
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	NOTE F_, 3
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE F_, 3
	LEN 21
	NOTE G_, 3
	NOTE G_, 3
	LEN 28
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 28
	NOTE F_, 3
	LEN 21
	NOTE G_, 4
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE F_, 4
	NEXT
Pat_6E51:
	INSTR 10
	LEN 14
	NOTE G_, 3
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 10
	NOTE G_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE G_, 3
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 10
	LEN 21
	NOTE G_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE F_, 3
	NOTE G_, 3
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 10
	NOTE G_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE G_, 3
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 10
	LEN 21
	NOTE G_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE G_, 3
	NOTE F_, 3
	INSTR 4
	LEN 7
	NOTE F_, 4
	INSTR 10
	NOTE F_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE F_, 3
	INSTR 4
	LEN 7
	NOTE F_, 4
	INSTR 10
	LEN 21
	NOTE F_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE F_, 3
	NOTE G_, 3
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 10
	NOTE G_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE G_, 3
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 10
	LEN 21
	NOTE G_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE F_, 3
	NEXT
Pat_6EAC:
	INSTR 10
	LEN 14
	NOTE G_, 3
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 10
	NOTE G_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE G_, 3
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 10
	LEN 21
	NOTE G_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE F_, 3
	NOTE G_, 3
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 10
	NOTE G_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE G_, 3
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 10
	LEN 21
	NOTE G_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE G_, 3
	NOTE F_, 3
	INSTR 4
	LEN 7
	NOTE F_, 4
	INSTR 10
	NOTE F_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE F_, 3
	INSTR 4
	LEN 7
	NOTE F_, 4
	INSTR 10
	LEN 21
	NOTE F_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE F_, 3
	NOTE G_, 3
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 10
	NOTE G_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE G_, 3
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 10
	LEN 21
	NOTE G_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE F_, 3
	NEXT
Pat_6F07:
	INSTR 10
	LEN 14
	NOTE A_, 3
	INSTR 5
	LEN 7
	NOTE D_, 4
	INSTR 10
	NOTE A_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE A_, 3
	INSTR 5
	LEN 7
	NOTE D_, 4
	INSTR 10
	LEN 21
	NOTE A_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE A_, 3
	NOTE B_, 3
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 10
	NOTE B_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE B_, 3
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 10
	LEN 21
	NOTE B_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE B_, 3
	NOTE A_, 3
	INSTR 5
	LEN 7
	NOTE D_, 4
	INSTR 10
	NOTE A_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE A_, 3
	INSTR 5
	LEN 7
	NOTE D_, 4
	INSTR 10
	LEN 21
	NOTE A_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE A_, 3
	NOTE Ash, 3
	INSTR 4
	LEN 7
	NOTE Dsh, 4
	INSTR 10
	NOTE Ash, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE Ash, 3
	INSTR 4
	LEN 7
	NOTE Dsh, 4
	INSTR 10
	LEN 21
	NOTE Ash, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE Ash, 3
	NEXT
Pat_6F62:
	INSTR 10
	LEN 14
	NOTE A_, 3
	INSTR 5
	LEN 7
	NOTE D_, 4
	INSTR 10
	NOTE A_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE A_, 3
	INSTR 5
	LEN 7
	NOTE D_, 4
	INSTR 10
	LEN 21
	NOTE A_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE A_, 3
	NOTE B_, 3
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 10
	NOTE B_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE B_, 3
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 10
	LEN 21
	NOTE B_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE B_, 3
	NOTE C_, 4
	INSTR 4
	LEN 7
	NOTE F_, 4
	INSTR 10
	NOTE B_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE C_, 4
	INSTR 4
	LEN 7
	NOTE F_, 4
	INSTR 10
	LEN 21
	NOTE B_, 3
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE C_, 4
	NOTE D_, 4
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 10
	NOTE D_, 4
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	NOTE D_, 4
	INSTR 4
	LEN 7
	NOTE G_, 4
	INSTR 10
	LEN 21
	NOTE D_, 4
	INSTR 1
	LEN 14
	NOTE G_, 3
	INSTR 10
	LEN 7
	NOTE D_, 4
	NOTE D_, 4
	NEXT
Pat_6FBF:
	INSTR 4
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE F_, 3
	NOTE F_, 3
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE F_, 3
	NOTE F_, 3
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE F_, 3
	NOTE F_, 3
	LEN 14
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	LEN 7
	NOTE F_, 3
	NOTE F_, 3
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE F_, 3
	NOTE F_, 3
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	INSTR 5
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	INSTR 4
	NOTE F_, 3
	INSTR 5
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NEXT
Pat_700C:
	INSTR 5
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	INSTR 4
	NOTE F_, 3
	INSTR 5
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	INSTR 4
	NOTE F_, 3
	INSTR 5
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NEXT
Pat_705A:
	INSTR 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 28
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE A_, 4
	LEN 28
	NOTE A_, 4
	LEN 14
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 7
	NOTE Ash, 4
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE Ash, 4
	LEN 28
	NOTE Ash, 4
	LEN 14
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE C_, 5
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE C_, 5
	LEN 7
	NOTE C_, 5
	LEN 28
	NOTE C_, 5
	LEN 14
	NOTE C_, 5
	NOTE C_, 5
	LEN 7
	NOTE C_, 5
	NOTE C_, 5
	NEXT
Pat_7093:
	INSTR 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 28
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 28
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 28
	NOTE G_, 4
	LEN 14
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 21
	NOTE F_, 3
	NOTE F_, 3
	LEN 14
	NOTE F_, 3
	NEXT
Pat_70CB:
	DRUMS $07, DrumPat_72C8
	CH_TRANSPOSE $0C
	VIBRATO $0E, $01, $05
	RELEASE $01, $51
	INSTR 13
	WAVE Wave_7DB2
	LEN 42
	NOTE G_, 3
	LEN 7
	NOTE D_, 4
	NOTE C_, 4
	LENGTH $70
	NOTE D_, 4
	LEN 28
	NOTE F_, 4
	NOTE G_, 4
	ARP 3
	LEN 42
	NOTE G_, 4
	ARP_OFF
	NOTE F_, 4
	LEN 14
	NOTE C_, 4
	NOTE F_, 4
	ARP 3
	LENGTH $38
	NOTE C_, 4
	ARP_OFF
	LEN 28
	NOTE C_, 4
	NOTE Ash, 3
	NEXT
Pat_70F8:
	DRUMS $07, DrumPat_72EA
	LEN 42
	NOTE G_, 3
	NOTE G_, 3
	LEN 28
	NOTE F_, 3
	LEN 42
	NOTE G_, 3
	NOTE G_, 3
	LEN 28
	NOTE F_, 3
	LEN 21
	NOTE G_, 3
	NOTE G_, 3
	LEN 28
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 28
	NOTE F_, 3
	LEN 21
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 7
	NOTE A_, 3
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	NEXT
Pat_711C:
	DRUMS $07, DrumPat_730C
	INSTR 13
	CH_TRANSPOSE $00
	WAVE Wave_7DA2
	ARP_OFF
	LEN 42
	NOTE G_, 4
	LEN 7
	NOTE D_, 4
	NOTE G_, 4
	LEN 21
	NOTE A_, 4
	ARP 3
	NOTE C_, 5
	ARP_OFF
	LEN 14
	NOTE C_, 5
	LEN 21
	NOTE B_, 4
	NOTE G_, 4
	LEN 14
	NOTE D_, 4
	ARP 3
	LEN 21
	NOTE G_, 4
	ARP_OFF
	NOTE F_, 4
	LEN 14
	NOTE D_, 4
	LEN 28
	NOTE C_, 4
	LEN 7
	NOTE A_, 3
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	ARP 3
	LEN 21
	NOTE Ash, 4
	ARP_OFF
	NOTE B_, 4
	LEN 14
	NOTE G_, 4
	ARP 3
	LEN 21
	NOTE G_, 4
	ARP_OFF
	NOTE B_, 4
	LENGTH $38
	NOTE D_, 4
	LEN 14
	NOTE D_, 4
	NEXT
Pat_7158:
	ARP_OFF
	LEN 42
	NOTE G_, 4
	LEN 7
	NOTE D_, 4
	NOTE G_, 4
	LEN 21
	NOTE A_, 4
	ARP 3
	NOTE C_, 5
	ARP_OFF
	LEN 14
	NOTE C_, 5
	LEN 21
	NOTE B_, 4
	NOTE G_, 4
	LEN 14
	NOTE D_, 4
	ARP 3
	LEN 21
	NOTE Dsh, 5
	ARP_OFF
	NOTE E_, 5
	LEN 14
	NOTE C_, 5
	LEN 42
	NOTE D_, 5
	LEN 7
	NOTE C_, 5
	NOTE B_, 4
	LEN 28
	NOTE A_, 4
	LEN 14
	NOTE F_, 4
	NOTE A_, 4
	ARP 3
	LEN 21
	NOTE G_, 4
	ARP_OFF
	NOTE G_, 4
	LEN 14
	NOTE D_, 4
	LENGTH $38
	NOTE G_, 3
	NEXT
Pat_7186:
	VOLENV 12, $11, $1F, $12
	CH_TRANSPOSE $00
	WAVE Wave_7DF2
	LEN 21
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 14
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 21
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 21
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	NOTE G_, 4
	LEN 21
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 14
	NOTE F_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	LEN 21
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	LEN 21
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	NEXT
Pat_71C0:
	LEN 21
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 14
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 21
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 21
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	NOTE G_, 4
	LEN 21
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 14
	NOTE A_, 4
	NOTE Ash, 4
	NOTE B_, 4
	LEN 7
	NOTE B_, 4
	LEN 21
	NOTE B_, 4
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE B_, 4
	LEN 21
	NOTE B_, 4
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE B_, 4
	NOTE B_, 4
	NEXT
Pat_71F1:
	ARP_OFF
	LEN 28
	NOTE A_, 3
	LEN 14
	NOTE C_, 4
	LENGTH $54
	NOTE F_, 3
	LEN 14
	NOTE C_, 3
	NOTE F_, 3
	NOTE G_, 3
	LEN 21
	NOTE A_, 3
	NOTE Ash, 3
	LEN 14
	NOTE A_, 3
	ARP 3
	LEN 21
	NOTE G_, 3
	ARP_OFF
	NOTE Ash, 3
	LENGTH $7E
	NOTE G_, 3
	LEN 14
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE G_, 4
	NEXT
Pat_7210:
	ARP 3
	LEN 28
	NOTE G_, 4
	ARP_OFF
	LEN 14
	NOTE Ash, 4
	LEN 28
	NOTE A_, 4
	NOTE F_, 4
	LENGTH $54
	NOTE D_, 4
	LEN 14
	NOTE D_, 4
	ARP 3
	NOTE F_, 4
	ARP_OFF
	NOTE D_, 4
	LEN 28
	NOTE F_, 4
	LEN 14
	NOTE G_, 4
	LEN 28
	NOTE C_, 4
	ARP 3
	NOTE Dsh, 4
	ARP_OFF
	LEN 7
	NOTE E_, 4
	NOTE Dsh, 4
	LENGTH $46
	NOTE D_, 4
	INSTR 6
	LEN 14
	NOTE C_, 4
	NOTE Ash, 3
	NOTE A_, 3
	NEXT
Pat_7237:
	DRUMS $07, DrumPat_72C8
	CH_TRANSPOSE $0C
	WAVE Wave_7E52
	LEN 7
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE A_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE A_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE A_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE A_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE A_, 4
	NOTE Ash, 4
	NOTE F_, 4
	NOTE Ash, 3
	NOTE Ash, 4
	NOTE F_, 4
	NOTE Ash, 3
	NOTE Ash, 4
	NOTE F_, 4
	NOTE Ash, 3
	NOTE Ash, 4
	NOTE F_, 4
	NOTE Ash, 3
	NOTE Ash, 4
	NOTE F_, 4
	NOTE Ash, 3
	NOTE Ash, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 4
	NOTE C_, 5
	NEXT
Pat_7282:
	DRUMS $07, DrumPat_72EA
	LEN 7
	NOTE D_, 5
	NOTE G_, 4
	NOTE D_, 4
	NOTE D_, 5
	NOTE G_, 4
	NOTE D_, 4
	NOTE D_, 5
	NOTE G_, 4
	NOTE D_, 4
	NOTE D_, 5
	NOTE G_, 4
	NOTE D_, 4
	NOTE D_, 5
	NOTE G_, 4
	NOTE D_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE G_, 4
	NOTE D_, 4
	NOTE D_, 5
	NOTE G_, 4
	NOTE D_, 4
	NOTE D_, 5
	NOTE G_, 4
	NOTE D_, 4
	NOTE D_, 5
	NOTE G_, 4
	NOTE D_, 4
	NOTE D_, 5
	NOTE G_, 4
	NOTE D_, 4
	NOTE C_, 5
	DRUMS $07, DrumPat_730C
	INSTR 13
	WAVE Wave_7DB2
	ARP_OFF
	LEN 21
	NOTE D_, 5
	NOTE B_, 4
	LEN 14
	NOTE D_, 5
	LEN 21
	NOTE C_, 5
	NOTE A_, 4
	LEN 14
	NOTE C_, 5
	LEN 21
	NOTE Ash, 4
	NOTE G_, 4
	LEN 14
	NOTE Ash, 4
	NOTE A_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE D_, 4
	NOTE C_, 4
	LEN 7
	NOTE A_, 3
	NEXT
DrumPat_72C8:
	db DRUM_LEVEL + 13, 9, 0, 10, 10, 9, 0, 9
	db 0, 10, 10, 9, 0, 9, 0, 10
	db 10, 9, 0, 10, 10, 9, 0, 9
	db 0, 10, 10, 9, 0, 9, 9, 9
	db 9, DRUM_LOOP
DrumPat_72EA:
	db DRUM_LEVEL + 13, 1, 0, 10, 10, 9, 0, 9
	db 0, 1, 10, 9, 0, 9, 0, 10
	db 10, 1, 0, 10, 10, 9, 0, 9
	db 0, 1, 10, 9, 0, 9, 9, 9
	db 9, DRUM_LOOP
DrumPat_730C:
	db DRUM_LEVEL + 14, 1, 6, 5, 0, 9, 0, 5
	db 6, 1, 0, 5, 6, 9, 6, 4
	db 6, 1, 6, 5, 0, 9, 0, 5
	db 6, 1, 0, 5, 6, 9, 6, 4
	db 6, DRUM_LOOP

; Song 1: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong1:
	ld a, $76
	ld [wInstrTableHi], a
	ld a, $3C
	ld [wInstrTable], a
	call StopAll
	ld de, Song1_Ch1
	call StartMusicCh1
	ld de, Song1_Ch2
	call StartMusicCh2
	ld de, Song1_Ch3
	jp StartMusicCh3
Song1_Ch1:
	dw Pat_7395
	dw Pat_7395
	dw Pat_73A7
	dw Pat_73D3
	dw Pat_73A7
	dw Pat_73D3
	dw Pat_73FE
	dw Pat_73FE
	dw Pat_7425
	dw Pat_7447
	ORDER_LOOP Song1_Ch1
Song1_Ch2:
	dw Pat_7471
	dw Pat_7471
	dw Pat_748A
	dw Pat_74A3
	dw Pat_748A
	dw Pat_74A3
	dw Pat_74C3
	dw Pat_74C3
	dw Pat_74F1
	dw Pat_7512
	ORDER_LOOP Song1_Ch2
Song1_Ch3:
	dw Pat_7535
	dw Pat_7535
	dw Pat_7564
	dw Pat_759A
	dw Pat_7564
	dw Pat_759A
	dw Pat_75BC
	dw Pat_75BC
	dw Pat_75D8
	dw Pat_7604
	ORDER_LOOP Song1_Ch3
Pat_7395:
	TRANSPOSE $01
	INSTR 0
	LEN 42
	NOTE D_, 2
	NOTE D_, 2
	LEN 21
	NOTE D_, 2
	NOTE D_, 2
	LEN 14
	NOTE D_, 2
	LEN 7
	NOTE Dsh, 2
	LEN 14
	NOTE E_, 2
	LEN 7
	NOTE Fsh, 2
	NEXT
Pat_73A7:
	INSTR 0
	LEN 21
	NOTE G_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	LEN 14
	NOTE D_, 2
	LEN 7
	NOTE D_, 2
	LEN 14
	NOTE E_, 2
	LEN 7
	NOTE Fsh, 2
	LEN 21
	NOTE G_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 3
	INSTR 0
	LEN 14
	NOTE D_, 2
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE Fsh, 2
	LEN 7
	NOTE E_, 2
	NEXT
Pat_73D3:
	INSTR 0
	LEN 21
	NOTE D_, 2
	INSTR 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 4
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 4
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 4
	NOTE D_, 4
	LEN 14
	NOTE D_, 4
	INSTR 0
	LEN 7
	NOTE E_, 2
	LEN 14
	NOTE D_, 2
	LEN 7
	NOTE E_, 2
	LEN 14
	NOTE D_, 2
	LEN 7
	NOTE E_, 2
	LEN 14
	NOTE Fsh, 2
	LEN 7
	NOTE D_, 2
	NEXT
Pat_73FE:
	INSTR 0
	LEN 21
	NOTE A_, 2
	INSTR 4
	NOTE A_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 4
	NOTE A_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 4
	NOTE A_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 4
	NOTE A_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 4
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE D_, 4
	INSTR 0
	LEN 14
	NOTE A_, 2
	LEN 7
	NOTE Fsh, 2
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE Gsh, 2
	NEXT
Pat_7425:
	INSTR 0
	LEN 21
	NOTE Fsh, 2
	INSTR 4
	NOTE Fsh, 3
	INSTR 0
	NOTE Csh, 2
	INSTR 4
	NOTE Fsh, 3
	INSTR 0
	NOTE Fsh, 2
	INSTR 4
	NOTE Fsh, 3
	INSTR 0
	NOTE Csh, 2
	INSTR 4
	NOTE Fsh, 3
	INSTR 0
	NOTE B_, 2
	INSTR 5
	NOTE B_, 3
	INSTR 0
	NOTE Fsh, 2
	INSTR 5
	NOTE B_, 3
	INSTR 0
	NOTE B_, 2
	INSTR 5
	NOTE B_, 3
	INSTR 0
	NOTE Fsh, 2
	INSTR 5
	NOTE B_, 3
	NEXT
Pat_7447:
	INSTR 0
	LEN 21
	NOTE E_, 2
	INSTR 4
	NOTE E_, 3
	INSTR 0
	NOTE B_, 2
	INSTR 4
	NOTE E_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 4
	NOTE E_, 3
	INSTR 0
	NOTE B_, 2
	INSTR 4
	NOTE E_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 4
	NOTE A_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 4
	NOTE A_, 3
	INSTR 0
	LEN 14
	NOTE A_, 2
	LEN 7
	NOTE Fsh, 2
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE Gsh, 2
	LEN 14
	NOTE A_, 2
	LEN 7
	NOTE G_, 2
	NOTE Fsh, 2
	NOTE F_, 2
	NOTE E_, 2
	NEXT
Pat_7471:
	HWENV $D2, $04, $85
	DUTY_50
	LEN 14
	REST
	LEN 7
	NOTE Gsh, 3
	LEN 21
	NOTE A_, 3
	LEN 14
	NOTE Gsh, 3
	LEN 21
	NOTE A_, 3
	LEN 7
	NOTE Gsh, 3
	LEN 21
	NOTE A_, 3
	LEN 14
	NOTE Gsh, 3
	LENGTH $31
	NOTE A_, 3
	NEXT
Pat_748A:
	LEN 42
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 3
	LEN 14
	NOTE D_, 3
	LEN 7
	NOTE D_, 3
	LEN 14
	NOTE E_, 3
	LEN 7
	NOTE Fsh, 3
	LEN 42
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE Fsh, 3
	LEN 7
	NOTE E_, 3
	NEXT
Pat_74A3:
	LEN 42
	NOTE D_, 3
	NOTE A_, 3
	LEN 14
	NOTE A_, 3
	LEN 7
	NOTE Fsh, 3
	LEN 14
	NOTE A_, 3
	LENGTH $31
	NOTE Fsh, 3
	LEN 42
	NOTE D_, 3
	LENGTH $38
	NOTE A_, 3
	LEN 7
	NOTE E_, 3
	LEN 14
	NOTE D_, 3
	LEN 7
	NOTE E_, 3
	LEN 14
	NOTE D_, 3
	LEN 7
	NOTE E_, 3
	LEN 14
	NOTE Fsh, 3
	LEN 7
	NOTE D_, 3
	NEXT
Pat_74C3:
	LEN 21
	NOTE A_, 3
	NOTE Csh, 4
	LEN 42
	NOTE Csh, 4
	LEN 21
	NOTE Csh, 4
	LEN 14
	NOTE D_, 4
	LEN 21
	NOTE Csh, 4
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE A_, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE Fsh, 3
	LEN 28
	NOTE A_, 3
	LEN 14
	NOTE B_, 3
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE B_, 3
	LEN 7
	NOTE A_, 3
	LEN 14
	NOTE Fsh, 3
	LEN 7
	NOTE A_, 3
	LEN 14
	NOTE E_, 3
	LEN 7
	NOTE A_, 3
	LEN 14
	NOTE D_, 3
	LEN 7
	NOTE Fsh, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE Gsh, 3
	NEXT
Pat_74F1:
	LEN 21
	NOTE Fsh, 3
	NOTE Csh, 3
	NOTE Fsh, 3
	NOTE Csh, 3
	NOTE Fsh, 3
	LEN 14
	NOTE G_, 3
	LEN 21
	NOTE Fsh, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE Fsh, 3
	LEN 7
	NOTE Fsh, 3
	LEN 21
	NOTE B_, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE G_, 3
	LEN 14
	NOTE Fsh, 3
	LEN 21
	NOTE Fsh, 3
	LEN 7
	NOTE Fsh, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE Fsh, 3
	NEXT
Pat_7512:
	LEN 21
	NOTE E_, 3
	NOTE Gsh, 3
	NOTE B_, 3
	LEN 14
	NOTE Gsh, 3
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE Gsh, 3
	LEN 21
	NOTE E_, 3
	LEN 7
	NOTE E_, 3
	LEN 14
	NOTE Fsh, 3
	LEN 7
	NOTE Gsh, 3
	LEN 42
	NOTE A_, 3
	NOTE E_, 3
	LEN 14
	NOTE A_, 3
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE Gsh, 3
	LENGTH $31
	NOTE A_, 3
	NEXT
Pat_7535:
	DRUMS $07, DrumPat_7630
	VOLENV 12, $11, $18, $13
	RELEASE $01, $01
	WAVE Wave_7DE2
	LEN 14
	NOTE D_, 3
	LEN 7
	NOTE Csh, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE D_, 3
	LEN 14
	NOTE Csh, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE D_, 3
	LEN 7
	NOTE Csh, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE D_, 3
	LEN 14
	NOTE Csh, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE D_, 3
	LEN 7
	NOTE Dsh, 3
	LEN 14
	NOTE E_, 3
	LEN 7
	NOTE Fsh, 3
	NEXT
Pat_7564:
	LEN 14
	REST
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE B_, 3
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE E_, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE E_, 4
	LENGTH $3F
	NOTE D_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE B_, 3
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE E_, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE E_, 4
	LEN 21
	NOTE D_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE D_, 5
	NEXT
Pat_759A:
	LEN 21
	NOTE C_, 5
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	LEN 14
	NOTE E_, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE E_, 4
	LEN 21
	NOTE D_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE D_, 5
	LEN 21
	NOTE C_, 5
	NOTE A_, 4
	NOTE Fsh, 4
	LEN 35
	NOTE D_, 4
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE E_, 4
	LEN 42
	NOTE D_, 4
	NEXT
Pat_75BC:
	LEN 21
	NOTE A_, 4
	NOTE A_, 4
	LEN 35
	NOTE E_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 21
	NOTE G_, 4
	NOTE A_, 4
	NOTE E_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE E_, 4
	LEN 21
	NOTE Fsh, 4
	NOTE Fsh, 4
	LEN 35
	NOTE A_, 4
	LEN 7
	NOTE G_, 4
	LEN 21
	NOTE Fsh, 4
	NOTE E_, 4
	LEN 42
	NOTE D_, 4
	NEXT
Pat_75D8:
	LEN 21
	NOTE Fsh, 4
	NOTE Ash, 4
	NOTE Csh, 5
	NOTE Fsh, 5
	NOTE E_, 5
	LEN 14
	NOTE Csh, 5
	LEN 21
	NOTE Ash, 4
	NOTE Fsh, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE D_, 5
	LEN 14
	NOTE Fsh, 4
	LEN 7
	NOTE B_, 4
	LEN 14
	NOTE Csh, 5
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE A_, 4
	LEN 21
	NOTE B_, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE Fsh, 4
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE Fsh, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE Fsh, 4
	NEXT
Pat_7604:
	LEN 21
	NOTE E_, 4
	NOTE Gsh, 4
	NOTE B_, 4
	LEN 14
	NOTE E_, 5
	LEN 7
	NOTE Dsh, 5
	LEN 14
	NOTE D_, 5
	LEN 7
	NOTE B_, 4
	LEN 14
	NOTE Gsh, 4
	LEN 21
	NOTE E_, 4
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE Fsh, 4
	LEN 7
	NOTE Gsh, 4
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE Gsh, 4
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE B_, 4
	LEN 14
	NOTE Csh, 5
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE Ash, 4
	LEN 21
	NOTE A_, 4
	NOTE E_, 4
	LEN 42
	NOTE A_, 4
	NEXT
DrumPat_7630:
	db DRUM_LEVEL + 12, 6, 0, 6, 4, 0, 4, 6
	db 0, 6, 4, 0, 6, DRUM_LOOP

; Instrument table 1, entries 1..14 (the song routines point 2 bytes before:
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

; Unreferenced (2 bytes)
	db $C3, $76
Instr1_0:
	HWENV $F1, $04, $A4
	DUTY_50
	ARP 0
	END
Instr1_1:
	HWENV $F1, $05, $71
	ARP 15
	DUTY_50
	END
Instr1_2:
	HWENV $F2, $04, $75
	DUTY_50
	ARP 0
	END
Instr1_3:
	HWENV $C2, $04, $72
	DUTY_75
	ARP 12
	END
Instr1_4:
	HWENV $F2, $04, $83
	DUTY_75
	ARP 4
	END
Instr1_5:
	HWENV $F2, $04, $83
	DUTY_75
	ARP 5
	END
Instr1_6:
	VOLENV 12, $11, $1F, $14
	ARP 0
	VIBRATO $14, $01, $06
	WAVE Wave_7E52
	END
Instr1_7:
	VOLENV 15, $11, $1F, $14
	ARP 0
	END
Instr1_8:
	HWENV $B1, $00
	ARP 0
	END
Instr1_9:
	VOLENV 8, $18, $1F, $1A
	WAVE Wave_7EA2
	END
Instr1_10:
	HWENV $D1, $06, $62
	ARP 12
	DUTY_12
	END
Instr1_11:
	HWENV $F2, $07, $62
	ARP 0
	END
Instr1_12:
	VOLENV 12, $11, $1F, $11
	WAVE Wave_7E42
	END
Instr1_13:
	VOLENV 8, $18, $1F, $1A
	WAVE Wave_7DC2
	END

; Unreferenced (6 bytes)
	db $BF, $11, $1F, $1F, $94, $68
ArpTable:
	dw Arp0
	dw Arp1
	dw Arp1
	dw Arp3
	dw Arp4
	dw Arp5
	dw Arp6
	dw Arp7
	dw Arp7
	dw Arp9
	dw Arp10
	dw Arp10
	dw Arp12
	dw Arp13
	dw Arp13
	dw Arp13
	dw Arp16
	dw Arp16
	dw Arp18

; Unreferenced (18 bytes)
	db $61, $77, $61, $77, $61, $77, $61, $77, $61, $77, $61, $77, $61, $77, $61, $77
	db $61, $77
Arp0:
	db $0C, $00, ARP_HOLD
Arp3:
	db $00, $00, $01, $01, $02, ARP_HOLD
Arp1:
	db $0C, $07, $07, $00, ARP_HOLD
Arp4:
	db $00, $00, $04, $04, $07, $07, ARP_LOOP
Arp5:
	db $00, $00, $03, $03, $07, $07, ARP_LOOP
Arp6:
	db $0C, $0C, $00, $00, $00, $00, $00, $00
	db $00, ARP_LOOP
Arp7:
	db $0C, $00, $00, $00, $00, $00, $00, $18
	db $0C, $0C, $0C, $0C, $0C, $0C, $0C, ARP_HOLD
Arp9:
	db $0C, $0C, $00, ARP_HOLD
Arp10:
	db $0C, $00, $00, $00, $00, $00, $00, $0C
	db $0C, $0C, $0C, $0C, $0C, $0C, ARP_HOLD
Arp12:
	db $00, $0C, $00, ARP_HOLD
Arp13:
	db $06, $02, $00, $FE, $FB, $F8, $F6, $F2
	db $F0, $EC, ARP_HOLD
Arp16:
	db $04, $00, $07, ARP_LOOP
Arp18:
	db $03, $00, $07, ARP_LOOP

; Unreferenced (29 bytes)
	db $7D, $77, $7D, $77, $7D, $77, $7D, $77, $7D, $77, $7D, $77, $7D, $77, $7D, $77
	db $7D, $77, $7D, $77, $7D, $77, $7D, $77, $7D, $77, $7D
SfxTable_m2:
	db $77, $68

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
	dw Sfx09
	dw Sfx23
	dw Sfx24
	dw Sfx19
	dw Sfx12
	dw Sfx11
	dw Sfx13
	dw Sfx29
	dw Sfx30
	dw Sfx31
	dw Sfx02
	dw Sfx33
	dw Sfx34
	dw Sfx35
	dw Sfx01
	dw Sfx37
	dw Sfx38
	dw Sfx39
	dw Sfx08

; Sound effect 17
Sfx17:
	LEN 8
	VOLENV 15, $11, $1F, $11
	GLIDE $02
	WAVE Wave_7DD2
	NOTE E_, 3
	END

; Sound effect 18
Sfx18:
	CALL_CODE Code_79E4
	END

; Sound effect 14
Sfx14:
	LEN 5
	VOLENV 15, $00, $00, $00
	WAVE Wave_7DD2
	CALL_CODE Code_7B58
	GLIDE $03
	NOTE A_, 2
	GLIDE $FC
	WAIT
	END

; Sound effect 10
Sfx10:
	VOLENV 10, $00, $00, $00
	GLIDE $FC
	WAVE Wave_7E02
	CALL_CODE Code_7BD8
	LEN 5
	NOTE A_, 6
	END

; Sound effect 6
Sfx06:
	VOLENV 11, $11, $1F, $11
	WAVE Wave_7DD2
	GLIDE $FF
	LEN 10
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE Dsh, 4
	END

; Sound effect 5
Sfx05:
	LEN 2
	VOLENV 15, $11, $1F, $11
	WAVE Wave_7DD2
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
	VOLENV 5, $00, $00, $00
	NOTE C_, 6
	NOTE E_, 6
	NOTE G_, 6
	NOTE C_, 7
	END

; Sound effect 15
Sfx15:
	VOLENV 15, $11, $23, $11
	LEN 5
	ARP 11
	WAVE Wave_7DF2
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

; Sound effect 20
Sfx20:
	VOLENV 15, $11, $1F, $12
	WAVE Wave_7DD2
	ARP 0
	GLIDE $02
	LEN 15
	NOTE A_, 2
	END

; Sound effect 21
Sfx21:
	VOLENV 15, $11, $1F, $11
	WAVE Wave_7DD2
	ARP 0
	GLIDE $04
	LEN 10
	NOTE A_, 3
	END

; Sound effect 24
Sfx24:
	VOLENV 15, $11, $1F, $13
	WAVE Wave_7E22
	CALL_CODE Code_7C89
	LEN 4
	NOTE C_, 3
	CALL_CODE Code_7BFA
	LEN 1
	REST
	LEN 10
	GLIDE $FE
	NOTE Dsh, 5
	END

; Sound effect 19
Sfx19:
	VOLENV 15, $11, $1F, $12
	WAVE Wave_7DF2
	CALL_CODE Code_7AAF
	LEN 10
	GLIDE $FF
	NOTE C_, 4
	END

; Sound effect 13
Sfx13:
	LEN 5
	VOLENV 15, $00, $00, $00
	WAVE Wave_7E12
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	VOLENV 10, $00, $00, $00
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	VOLENV 5, $00, $00, $00
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	END

; Sound effect 29
Sfx29:
	VOLENV 12, $11, $1F, $13
	WAVE Wave_7DD2
	LEN 4
	NOTE C_, 5
	LEN 25
	NOTE C_, 6
	VIBRATO $05, $01, $04
	END

; Sound effect 30
Sfx30:
	VOLENV 15, $00, $00, $00
	LEN 4
	WAVE Wave_7E02
	REPEAT 4
	NOTE A_, 5
	REST
	REPEAT_END
	END

; Sound effect 31
Sfx31:
	CALL_CODE Code_7B89
	VOLENV 15, $11, $1F, $15
	WAVE Wave_7DD2
	LEN 9
	GLIDE $FC
	NOTE A_, 4
	END

; Sound effect 4
Sfx04:
	CALL_CODE Code_7D6C
	VOLENV 15, $11, $1F, $15
	WAVE Wave_7DD2
	LEN 9
	GLIDE $FD
	NOTE A_, 3
	END

; Sound effect 2
Sfx02:
	WAVE Wave_7DF2
	CALL_CODE Code_7C43
	VOLENV 15, $11, $1F, $12
	LEN 8
	GLIDE $FF
	NOTE A_, 4
	LEN 5
	VOLENV 10, $11, $1F, $12
	NOTE A_, 4
	END

; Sound effect 16
Sfx16:
	VOLENV 15, $11, $1F, $12
	ARP 0
	WAVE Wave_7DD2
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

; Sound effect 7
Sfx07:
	CALL_CODE Code_7D3D
	END

; Sound effect 11
Sfx11:
	VOLENV 15, $11, $2F, $11
	WAVE Wave_7DE2
	LEN 13
	NOTE C_, 6
	END

; Sound effect 12
Sfx12:
	LEN 4
	VOLENV 15, $11, $2F, $11
	WAVE Wave_7DE2
	LEN 4
	NOTE Gsh, 5
	LEN 1
	REST
	LEN 4
	NOTE Gsh, 6
	END

; Sound effect 37
Sfx37:
	VOLENV 15, $11, $1F, $11
	CALL_CODE Code_7C89
	WAVE Wave_7DD2
	LEN 12
	GLIDE $FE
	NOTE C_, 3
	END

; Sound effect 39
Sfx39:
	CALL_CODE Code_7CE3
	END

; Sound effect 1
Sfx01:
	LEN 5
	ARP 0
	WAVE Wave_7E32
	VOLENV 15, $10, $1F, $12
	RELEASE $02, $55
	NOTE C_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	END

; Sound effect 38
Sfx38:
	CALL_CODE Code_7CBA
	END

; Sound effect 33
Sfx33:
	VOLENV 12, $11, $1F, $14
	WAVE Wave_7DD2
	GLIDE $04
	LEN 4
	NOTE G_, 3
	GLIDE $FD
	LEN 6
	WAIT
	REST
	END

; Sound effect 8
Sfx08:
	VOLENV 10, $11, $1F, $14
	WAVE Wave_7DD2
	LEN 33
	SLIDE_DOWN $03
	NOTE A_, 5
	END

; Unreferenced (16 bytes)
	db $BC, $11, $1F, $13, $79, $D2, $7D, $C3, $30, $D8, $3C, $63, $05, $01, $04, $68

; Sound effect 3
Sfx03:
	CALL_CODE Code_7D10
	VOLENV 15, $00, $00, $00
	WAVE Wave_7EA2
	LEN 3
	GLIDE $FF
	NOTE Csh, 6
	WAVE Wave_7E82
	WAIT
	WAVE Wave_7E92
	WAIT
	END

; Sound effect 23
Sfx23:
	CALL_CODE Code_7AEB
	WAVE Wave_7DD2
	VOLENV 10, $11, $1F, $12
	LEN 7
	GLIDE $01
	NOTE C_, 3
	NOTE G_, 2
	END

; Sound effect 35
Sfx35:
	VOLENV 10, $15, $1F, $22
	VIBRATO $00, $02, $06
	WAVE Wave_7E62
	LEN 20
	NOTE A_, 5
	GLIDE $FF
	LEN 10
	WAIT
	END

; Sound effect 34
Sfx34:
	VOLENV 12, $11, $1F, $13
	VIBRATO $00, $01, $04
	WAVE Wave_7DF2
	CALL_CODE Code_7BFA
	GLIDE $FC
	LEN 5
	NOTE A_, 4
	CALL_CODE Code_7BFA
	GLIDE $08
	WAIT
	CALL_CODE Code_7BD8
	GLIDE_OFF
	LEN 10
	WAIT
	GLIDE $FF
	WAIT
	END

; Sound effect 9
Sfx09:
	CALL_CODE Code_7B2B
	VOLENV 10, $11, $1F, $11
	WAVE Wave_7DD2
	LEN 10
	ARP 5
	GLIDE $01
	NOTE A_, 5
	END
Code_79E4:
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
	ld a, HIGH(Noise43_7A0F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7A0F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7A1A)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7A1A)
	ld [wNoise42], a
	ret
Noise43_7A0F:
	db $57, $46, $45, $44, $43, $42, $41, $40
	db $20, $20, $FF
Noise42_7A1A:
	db $19, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $F3

; Unreferenced (111 bytes)
	db $AF, $EA, $5B, $DB, $3C, $EA, $5C, $DB, $3E, $13, $EA, $47, $DB, $CD, $8E, $49
	db $3E, $F2, $E0, $21, $3E, $80, $E0, $23, $3E, $7A, $EA, $57, $DB, $3E, $51, $EA
	db $58, $DB, $3E, $00, $EA, $59, $DB, $3E, $00, $EA, $5A, $DB, $C9, $18, $3A, $47
	db $49, $2E, $2D, $1C, $28, $4A, $57, $39, $4E, $1D, $0C, $FF, $3E, $0A, $EA, $47
	db $DB, $AF, $EA, $5B, $DB, $3C, $EA, $5C, $DB, $3E, $7A, $EA, $57, $DB, $3E, $82
	db $EA, $58, $DB, $3E, $7A, $EA, $59, $DB, $3E, $8B, $EA, $5A, $DB, $C9, $36, $35
	db $34, $33, $31, $20, $10, $10, $FF, $C1, $FF, $FF, $FF, $FF, $FF, $FF, $FF
Noise43_7A93:
	db $12, $64, $02, $37, $47, $24, $55, $71
	db $07, $44, $60, $36, $84, $82, $64, $02
	db $37, $47, $24, $55, $71, $07, $44, $60
	db $36, $86, $32, $FF
Code_7AAF:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $18
	ld [wDrumHold], a
	ld a, $A2
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ld a, HIGH(Noise43_7AD9)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7AD9)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_7AD9:
	db $46, $45, $44, $43, $42, $41, $32, $30
	db $FF

; Unreferenced (9 bytes)
	db $10, $10, $20, $31, $33, $34, $35, $36, $FF
Code_7AEB:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $19
	ld [wDrumHold], a
	ld a, HIGH(Noise43_7A93)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7A93)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B0D)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B0D)
	ld [wNoise42], a
	ret
Noise42_7B0D:
	db $59, $FF, $FF, $FF, $FF, $FF, $FF, $F2
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF

; Unreferenced (3 bytes)
	db $FF, $FF, $FF
Code_7B2B:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $13
	ld [wDrumHold], a
	call NoisePanCentre
	ld a, $F1
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ld a, HIGH(Noise43_7A93)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7A93)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Code_7B58:
	ld a, $08
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B7A)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B7A)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B82)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B82)
	ld [wNoise42], a
	ret
Noise43_7B7A:
	db $60, $52, $42, $41, $22, $11, $21, $FF
Noise42_7B82:
	db $F0, $F0, $F0, $F0, $F0, $F0, $61
Code_7B89:
	ld a, $24
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $F3
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ld a, HIGH(Noise43_7BB3)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7BB3)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_7BB3:
	db $36, $35, $34, $33, $32, $31, $20, $10
	db $10, $37, $36, $35, $34, $33, $32, $21
	db $11, $11, $38, $37, $36, $35, $34, $33
	db $22, $12, $12, $39, $38, $37, $36, $35
	db $34, $23, $13, $13, $FF
Code_7BD8:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7C1C)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7C1C)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7C36)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7C36)
	ld [wNoise42], a
	ret
Code_7BFA:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7C29)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7C29)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7C36)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7C36)
	ld [wNoise42], a
	ret
Noise43_7C1C:
	db $10, $10, $20, $31, $32, $33, $33, $34
	db $34, $35, $35, $36, $FF
Noise43_7C29:
	db $36, $35, $35, $34, $34, $33, $33, $32
	db $31, $20, $10, $10, $FF
Noise42_7C36:
	db $5C, $FF, $FF, $FF, $FF, $FF, $A1, $FF
	db $FF, $FF, $FF, $FF

; Unreferenced (1 bytes)
	db $FF
Code_7C43:
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
	ld a, HIGH(Noise43_7C6D)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7C6D)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_7C6D:
	db $12, $92, $42, $42, $42, $42, $52, $65
	db $45, $FF

; Unreferenced (18 bytes)
	db $F0, $FF, $55, $00, $B2, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $F0, $FF, $FF
	db $FF, $F4
Code_7C89:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7CAB)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7CAB)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7CB3)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7CB3)
	ld [wNoise42], a
	ret
Noise43_7CAB:
	db $02, $51, $61, $71, $91, $71, $60, $FF
Noise42_7CB3:
	db $F0, $F0, $F0, $F0, $F0, $70, $63
Code_7CBA:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7CDC)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7CDC)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7CE0)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7CE0)
	ld [wNoise42], a
	ret
Noise43_7CDC:
	db $02, $51, $11, $FF
Noise42_7CE0:
	db $F0, $A0, $55
Code_7CE3:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7D05)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7D05)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7D0B)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7D0B)
	ld [wNoise42], a
	ret
Noise43_7D05:
	db $02, $41, $61, $71, $11, $FF
Noise42_7D0B:
	db $F0, $FF, $FF, $A0, $B2
Code_7D10:
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7D32)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7D32)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7D38)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7D38)
	ld [wNoise42], a
	ret
Noise43_7D32:
	db $00, $53, $71, $91, $31, $FF
Noise42_7D38:
	db $F1, $FF, $FF, $FF, $00
Code_7D3D:
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7D5F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7D5F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7D66)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7D66)
	ld [wNoise42], a
	ret
Noise43_7D5F:
	db $41, $61, $61, $41, $71, $71, $FF
Noise42_7D66:
	db $A1, $52, $00, $61, $52, $00
Code_7D6C:
	ld a, $21
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $02
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_7D97)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7D97)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7D9D)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7D9D)
	ld [wNoise42], a
	ret
Noise43_7D97:
	db $03, $93, $80, $72, $70, $FF
Noise42_7D9D:
	db $F0, $FF, $FF, $FF, $F3
Wave_7DA2:
	db $01, $11, $11, $00, $89, $AA, $AA, $98
	db $01, $11, $11, $00, $FF, $FF, $FF, $FF
Wave_7DB2:
	db $8C, $FE, $ED, $B8, $53, $21, $10, $24
	db $84, $01, $12, $35, $8B, $DE, $EF, $8C
Wave_7DC2:
	db $00, $46, $8A, $FF, $FF, $A8, $64, $00
	db $00, $46, $8A, $FF, $FF, $A8, $64, $00
Wave_7DD2:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
Wave_7DE2:
	db $00, $00, $00, $00, $CD, $EF, $FD, $EC
	db $00, $12, $21, $00, $DD, $DD, $DD, $DD
Wave_7DF2:
	db $00, $00, $00, $00, $00, $00, $FF, $FF
	db $00, $00, $00, $00, $00, $00, $FF, $FF
Wave_7E02:
	db $00, $00, $00, $00, $00, $00, $FF, $00
	db $00, $00, $00, $00, $00, $00, $FF, $00
Wave_7E12:
	db $00, $00, $00, $CD, $EF, $FF, $FF, $FF
	db $04, $8C, $FF, $FF, $FF, $FF, $FF, $FF
Wave_7E22:
	db $63, $10, $00, $00, $00, $00, $01, $36
	db $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9
Wave_7E32:
	db $63, $10, $01, $47, $74, $10, $01, $36
	db $9C, $EF, $FE, $B8, $8B, $EF, $FE, $C9
Wave_7E42:
	db $63, $1F, $01, $47, $74, $10, $01, $36
	db $9C, $E0, $FE, $B8, $8B, $EF, $FE, $C9
Wave_7E52:
	db $B7, $40, $04, $7B, $CD, $FF, $FE, $DC
	db $02, $46, $8A, $BD, $FD, $BA, $64, $20
Wave_7E62:
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $ED, $CB, $A9, $87, $65, $43, $21, $00
Wave_7E72:
	db $FE, $DB, $97, $53, $13, $54, $32, $10
	db $FE, $DC, $BC, $EF, $DB, $85, $32, $10
Wave_7E82:
	db $04, $8B, $DE, $FF, $ED, $CB, $A9, $87
	db $65, $44, $44, $32, $11, $24, $7A, $74
Wave_7E92:
	db $20, $24, $68, $AC, $EC, $A8, $64, $20
	db $24, $68, $A8, $64, $20, $24, $68, $64
Wave_7EA2:
	db $02, $48, $AC, $FF, $FC, $53, $00, $27
	db $9C, $DD, $DC, $B7, $7B, $CD, $DD, $C9
Noise43_7EB2:
	db $02, $61, $71, $A1, $B1, $B1, $A1, $FF
Noise42_7EBA:
	db $C1, $F0, $A0, $90, $70, $40, $33
Noise43_7EC1:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_7EC9:
	db $60, $30, $12, $FF, $FF, $FF, $FF
Noise43_7ED0:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_7ED8:
	db $A0, $60, $32, $FF, $FF, $FF, $FF
Noise43_7EDF:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_7EE7:
	db $70, $40, $40, $40, $40, $43, $FF
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7EB2)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7EB2)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7EBA)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7EBA)
	ld [wNoise42], a
	ret
Drum8:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7F28)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7F28)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7F30)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7F30)
	ld [wNoise42], a
	ret
Noise43_7F28:
	db $60, $52, $42, $41, $22, $11, $04, $FF
Noise42_7F30:
	db $F0, $F0, $F0, $A0, $70, $40, $51
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7EDF)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7EDF)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7EE7)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7EE7)
	ld [wNoise42], a
	ret
Drum5:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7ED0)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7ED0)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7ED8)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7ED8)
	ld [wNoise42], a
	ret
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7EC1)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7EC1)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7EC9)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7EC9)
	ld [wNoise42], a
	ret
Drum9:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7FAB)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7FAB)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7FAE)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7FAE)
	ld [wNoise42], a
	ret
Noise43_7FAB:
	db $51, $32, $FF
Noise42_7FAE:
	db $F0, $62
Drum10:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7FCD)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7FCD)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7FD0)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7FD0)
	ld [wNoise42], a
	ret
Noise43_7FCD:
	db $51, $32, $FF
Noise42_7FD0:
	db $90, $61

; Unreferenced (15 bytes)
	db $51, $32, $32, $32, $32, $51, $32, $FF, $80, $51, $FF, $FF, $FF, $80, $51
FadeOutTable:
	db $77, $66, $55, $44, $33, $22, $11, $00
	db FADE_END
FadeInTable:
	db $00, $11, $22, $33, $44, $55, $66, $77
	db FADE_END

; Unreferenced (13 bytes)
	db $46, $69, $6E, $61, $6C, $20, $64, $65, $20, $6C, $61, $20, $FF
