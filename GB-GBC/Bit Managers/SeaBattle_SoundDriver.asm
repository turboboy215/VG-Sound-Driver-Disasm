; =====================================================================
; Sea Battle (E) (M4) - Game Boy
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o seabattle.o SeaBattle_SoundDriver.asm
;   rgblink -o seabattle.gb seabattle.o
;   python tools/cmp_banked.py seabattle.gb "Sea Battle (E) (M4).gb" 4:4000-7FFF
; (driver and data fill ROM bank 4; the linked file only matches in that range)
;
; Documentation: SeaBattle_SoundDriver.md / AJG_SoundEngine_Family.md
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
DEF wCh1 EQU $DC00
DEF wPaused EQU $DC42
DEF wStereo EQU $DC43
DEF wShNR32 EQU $DC44
DEF wInInstr EQU $DC45
DEF wNoisePan EQU $DC46
DEF wDrumHold EQU $DC47
DEF wInstrTable EQU $DC48
DEF wInstrTableHi EQU $DC49
DEF wArpTable EQU $DC4A
DEF wArpTableHi EQU $DC4B
DEF wMusicWave EQU $DC4C
DEF wMusicWaveHi EQU $DC4D
DEF wNoiseAutoPan EQU $DC4E
DEF wDrumPatHi EQU $DC4F
DEF wDrumPat EQU $DC50
DEF wDrumPos EQU $DC51
DEF wDrumsOn EQU $DC52
DEF wDrumTempo EQU $DC53
DEF wDrumTimer EQU $DC54
DEF wDrumLoopCount EQU $DC55
DEF wDrumLoopPos EQU $DC56
DEF wNoise43Hi EQU $DC57
DEF wNoise43 EQU $DC58
DEF wNoise42Hi EQU $DC59
DEF wNoise42 EQU $DC5A
DEF wNoisePos EQU $DC5B
DEF wNoiseOn EQU $DC5C
DEF wNoiseAtten EQU $DC5D
DEF wNoiseTimer EQU $DC5E
DEF wNoiseSpeed EQU $DC5F
DEF wFadeTable EQU $DC60
DEF wFadeTableHi EQU $DC61
DEF wFadePos EQU $DC62
DEF wFadeTimer EQU $DC63
DEF wFadeSpeed EQU $DC64
DEF wFadeOn EQU $DC65
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


SECTION "SoundDriver", ROMX[$4000], BANK[4]


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
	jp Pat_53A9                         ; unused song slot: jumps into pattern data (never called)
	jp Pat_53A9                         ; unused song slot: jumps into pattern data (never called)
	jp Pat_53A9                         ; unused song slot: jumps into pattern data (never called)
	jp Pat_53A9                         ; unused song slot: jumps into pattern data (never called)
	jp Pat_53A9                         ; unused song slot: jumps into pattern data (never called)
	jp Pat_53A9                         ; unused song slot: jumps into pattern data (never called)
	jp Pat_53A9                         ; unused song slot: jumps into pattern data (never called)
	jp Pat_53A9                         ; unused song slot: jumps into pattern data (never called)
	jp Pat_53A9                         ; unused song slot: jumps into pattern data (never called)
	jp Pat_53A9                         ; unused song slot: jumps into pattern data (never called)
	jp Pat_53A9                         ; unused song slot: jumps into pattern data (never called)
	jp Pat_53A9                         ; unused song slot: jumps into pattern data (never called)
	jp Pat_53A9                         ; unused song slot: jumps into pattern data (never called)
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
	ld a, [$DF27]
	and a
	jr nz, PauseTrigger
	xor a
	ldh [rNR32], a
PauseTrigger:
	ld a, $80
	ldh [rNR14], a
	ldh [rNR24], a
	ldh [rNR44], a
	ld a, [$DF27]
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
	ld h, $DC
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
	ld hl, $DC25
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
	add a, $CE
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

; Unreferenced (39 bytes)
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

; INSTR n: clear arpeggio, glide, arpeggio offset and auto-duty (field $2F; Lucky
; Luke leaves auto-duty running); pulse pages: NR11/NR21 = 50 % duty; then run
; macro n (entry n + 1 of wInstrTable) up to END with wInInstr = $C9.
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
	ld l, $2F
	ld [hl], a
	ld a, h
	cp $DE
	jr nc, InstrLookup
	cp $DC
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
	ld a, $54
	ld [wInstrTableHi], a
	ld a, $3B
	ld [wInstrTable], a
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
	cp $DC
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
	ld [$DE07], a
	ldh [rNR30], a
	ldh [rNR34], a
	ret

; Unreferenced (73 bytes)
	db $46, $FA, $89, $46, $F2, $C4, $5E, $06, $26, $8B, $87, $D6, $00, $03, $46, $FA
	db $05, $FE, $FF, $89, $46, $FE, $C4, $5E, $06, $26, $8B, $87, $88, $01, $3B, $46
	db $FE, $7E, $05, $8B, $46, $FE, $EB, $08, $C4, $5E, $06, $26, $8B, $87, $88, $01
	db $89, $46, $F6, $C4, $5E, $EC, $26, $FF, $37, $16, $8D, $46, $F0, $50, $16, $8D
	db $46, $F8, $50, $56, $FF, $76, $08, $FF, $76
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

; StartMusicChN (de = order list): reset the page, mark it active, start its first
; pattern. StartMusicCh3 also stops the fade and the drums and sets NR50 = $77.
StartMusicCh1:
	ld h, $DC
	jr StartMusicCh
StartMusicCh2:
	ld h, $DD
	jr StartMusicCh
StartMusicCh3:
	ld h, $DE
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
	add a, $74
	ld l, a
	adc a, $55
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
	dw Drum2
	dw Drum4
	dw Drum4
	dw Drum5
	dw Drum6
	dw Drum7
	dw Drum8
	dw Drum9
	dw Drum10

; Unreferenced (2 bytes)
	db $70, $60
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

; Not reached: the driver's version text (after the driver code, before the first song).
DriverVersionText:
	db "GBS 3.4 (C) 1990 - 1997 Alberto Jose Gonzalez & Bit Managers S.L."

; Song 2: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong2:
	call StopAll
	ld a, $54
	ld [wInstrTableHi], a
	ld a, $3B
	ld [wInstrTable], a
	ld de, Song2_Ch1
	call StartMusicCh1
	ld de, Song2_Ch2
	call StartMusicCh2
	ld de, Song2_Ch3
	jp StartMusicCh3
Song2_Ch1:
	dw Pat_53A9
	dw Pat_4C6B
	dw Pat_4CA5
	dw Pat_4C6B
	dw Pat_4CA5
	dw Pat_4CD2
	dw Pat_4CD2
	dw Pat_53AC
	dw Pat_4C6B
	dw Pat_4CA5
	dw Pat_4C6B
	dw Pat_4CA5
	dw Pat_4CD2
	dw Pat_4CD2
	ORDER_LOOP Song2_Ch1
Song2_Ch2:
	dw Pat_4BC3
	dw Pat_4BD4
	dw Pat_4BC3
	dw Pat_4BD4
	dw Pat_4BE2
	dw Pat_4BE2
	ORDER_LOOP Song2_Ch2
Song2_Ch3:
	dw Pat_4BEE
	dw Pat_4C0A
	dw Pat_4BEE
	dw Pat_4C0A
	dw Pat_4C2B
	dw Pat_4C48
	ORDER_LOOP Song2_Ch3
Pat_4BC3:
	INSTR 5
	AUTODUTY $06
	LEN 14
	REPEAT 8
	NOTE F_, 4
	REPEAT_END
	ARP 4
	REPEAT 8
	NOTE Gsh, 4
	REPEAT_END
	ARP 5
	REPEAT 8
	NOTE C_, 5
	NOTE C_, 5
	REPEAT_END
	NEXT
Pat_4BD4:
	LEN 14
	REPEAT 8
	NOTE Ash, 4
	REPEAT_END
	ARP 4
	REPEAT 8
	NOTE Fsh, 4
	REPEAT_END
	ARP 5
	REPEAT 8
	NOTE F_, 4
	NOTE F_, 4
	REPEAT_END
	NEXT
Pat_4BE2:
	ARP 4
	LEN 14
	REPEAT 8
	NOTE Fsh, 4
	NOTE Fsh, 4
	REPEAT_END
	ARP 5
	REPEAT 8
	NOTE F_, 4
	NOTE F_, 4
	REPEAT_END
	NEXT
Pat_4BEE:
	DRUMS $07, DrumPat_4CF3
	INSTR 13
	INSTR 6
	LEN 28
	NOTE F_, 3
	INSTR 13
	NOTE F_, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	LEN 42
	NOTE Gsh, 4
	LEN 14
	NOTE Ash, 4
	LENGTH $54
	NOTE C_, 5
	LEN 14
	NOTE G_, 3
	NOTE Ash, 3
	LENGTH $70
	NOTE C_, 4
	NEXT
Pat_4C0A:
	INSTR 6
	LEN 28
	NOTE Ash, 3
	INSTR 13
	LEN 14
	NOTE F_, 5
	NOTE Dsh, 5
	LEN 4
	NOTE G_, 5
	LEN 24
	NOTE F_, 5
	LEN 14
	NOTE Dsh, 5
	LEN 28
	NOTE Csh, 5
	LEN 14
	NOTE Fsh, 5
	NOTE F_, 5
	NOTE Fsh, 5
	LEN 5
	NOTE A_, 5
	LEN 23
	NOTE Gsh, 5
	LEN 14
	NOTE Fsh, 5
	NOTE F_, 5
	LENGTH $C4
	NOTE F_, 5
	INSTR 6
	LEN 28
	NOTE C_, 3
	NEXT
Pat_4C2B:
	INSTR 6
	LEN 14
	NOTE Fsh, 3
	INSTR 13
	WAVE Wave_5E7E
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	LEN 21
	NOTE C_, 5
	NOTE Csh, 5
	LEN 14
	NOTE Dsh, 5
	LEN 28
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE Gsh, 5
	NOTE Fsh, 5
	LEN 42
	NOTE F_, 5
	LEN 7
	NOTE Dsh, 5
	NOTE Csh, 5
	LENGTH $A8
	NOTE C_, 5
	NEXT
Pat_4C48:
	INSTR 6
	LEN 14
	NOTE Fsh, 3
	INSTR 13
	WAVE Wave_5E7E
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	LEN 21
	NOTE C_, 5
	NOTE Csh, 5
	LEN 14
	NOTE Dsh, 5
	LEN 28
	NOTE F_, 5
	NOTE Dsh, 5
	LEN 42
	NOTE C_, 6
	LEN 14
	NOTE Gsh, 5
	LENGTH $54
	NOTE F_, 5
	INSTR 13
	LEN 14
	NOTE C_, 2
	NOTE Dsh, 2
	LEN 42
	NOTE F_, 2
	NOTE C_, 4
	LEN 28
	NOTE Gsh, 4
	NEXT
Pat_4C6B:
	INSTR 11
	LEN 14
	NOTE F_, 2
	INSTR 14
	NOTE C_, 4
	NOTE F_, 3
	INSTR 11
	NOTE F_, 2
	INSTR 14
	NOTE Dsh, 4
	NOTE C_, 4
	INSTR 11
	NOTE F_, 2
	INSTR 14
	NOTE F_, 4
	INSTR 11
	NOTE Gsh, 2
	INSTR 14
	NOTE C_, 4
	NOTE Gsh, 3
	INSTR 11
	NOTE Gsh, 2
	INSTR 14
	NOTE Dsh, 4
	NOTE C_, 4
	INSTR 11
	NOTE Gsh, 2
	INSTR 14
	NOTE G_, 4
	INSTR 11
	NOTE C_, 3
	INSTR 14
	NOTE C_, 4
	NOTE G_, 3
	INSTR 11
	NOTE C_, 3
	INSTR 14
	NOTE Dsh, 4
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 14
	NOTE G_, 4
	INSTR 11
	NOTE C_, 2
	INSTR 14
	NOTE C_, 4
	NOTE G_, 3
	INSTR 11
	NOTE C_, 3
	INSTR 14
	NOTE Dsh, 4
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	INSTR 14
	NOTE G_, 4
	NEXT
Pat_4CA5:
	INSTR 11
	NOTE Ash, 2
	INSTR 14
	NOTE Csh, 4
	NOTE Ash, 3
	INSTR 11
	NOTE Ash, 2
	INSTR 14
	NOTE F_, 4
	NOTE Csh, 4
	INSTR 11
	NOTE Ash, 2
	INSTR 14
	NOTE Ash, 4
	INSTR 11
	NOTE Fsh, 2
	INSTR 14
	NOTE Csh, 4
	NOTE Ash, 3
	INSTR 11
	NOTE Fsh, 2
	INSTR 14
	NOTE Fsh, 4
	NOTE Csh, 4
	INSTR 11
	NOTE Fsh, 2
	INSTR 14
	NOTE Ash, 4
	REPEAT 2
	INSTR 11
	NOTE F_, 2
	INSTR 14
	NOTE C_, 4
	NOTE F_, 3
	INSTR 11
	NOTE F_, 2
	INSTR 14
	NOTE Dsh, 4
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	INSTR 14
	NOTE F_, 4
	REPEAT_END
	NEXT
Pat_4CD2:
	REPEAT 2
	INSTR 11
	NOTE Fsh, 2
	INSTR 14
	NOTE Csh, 4
	NOTE Ash, 3
	INSTR 11
	NOTE Fsh, 2
	INSTR 14
	NOTE Fsh, 4
	NOTE Csh, 4
	INSTR 11
	NOTE Csh, 2
	INSTR 14
	NOTE Ash, 4
	REPEAT_END
	REPEAT 2
	INSTR 11
	NOTE F_, 2
	INSTR 14
	NOTE C_, 4
	NOTE F_, 3
	INSTR 11
	NOTE F_, 2
	INSTR 14
	NOTE F_, 4
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	INSTR 14
	NOTE Gsh, 4
	REPEAT_END
	NEXT
DrumPat_4CF3:
	db DRUM_LEVEL + 14, 9, 0, 10, 10, 10, 0, 9
	db 0, 10, 10, 10, 0, 9, 10, 10
	db 0, 9, 0, 10, 10, 10, 0, 9
	db 0, 10, 10, 10, 0, 9, 9, 9
	db 9, DRUM_LOOP

; Song 3: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong3:
	ld a, $54
	ld [wInstrTableHi], a
	ld a, $3B
	ld [wInstrTable], a
	call StopAll
	ld de, Song3_Ch1
	call StartMusicCh1
	ld de, Song3_Ch2
	call StartMusicCh2
	ld de, Song3_Ch3
	jp StartMusicCh3
Song3_Ch1:
	dw Pat_4D46
	ORDER_LOOP Song3_Ch1
Song3_Ch2:
	dw Pat_4DAC
	ORDER_LOOP Song3_Ch2
Song3_Ch3:
	dw Pat_4E12
	ORDER_LOOP Song3_Ch3
Pat_4D46:
	LEN 9
	TRANSPOSE $01
	INSTR 11
	NOTE F_, 2
	WAIT
	WAIT
	NOTE F_, 2
	WAIT
	WAIT
	NOTE F_, 2
	WAIT
	WAIT
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	NOTE Gsh, 2
	WAIT
	WAIT
	NOTE Gsh, 2
	WAIT
	WAIT
	NOTE Gsh, 2
	WAIT
	NOTE Gsh, 2
	NOTE Gsh, 2
	WAIT
	NOTE Gsh, 2
	NOTE Ash, 2
	WAIT
	WAIT
	NOTE Ash, 2
	WAIT
	WAIT
	NOTE Ash, 2
	WAIT
	WAIT
	NOTE Ash, 2
	WAIT
	NOTE Ash, 2
	NOTE Csh, 2
	NOTE Csh, 2
	NOTE Csh, 2
	NOTE Csh, 2
	WAIT
	WAIT
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	WAIT
	NOTE Dsh, 2
	INSTR 11
	NOTE F_, 2
	WAIT
	WAIT
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	NOTE F_, 2
	WAIT
	WAIT
	NOTE F_, 2
	WAIT
	WAIT
	NOTE Gsh, 2
	WAIT
	WAIT
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	WAIT
	WAIT
	NOTE Gsh, 2
	WAIT
	WAIT
	NOTE Ash, 2
	WAIT
	WAIT
	NOTE Ash, 2
	WAIT
	NOTE Ash, 2
	NOTE Ash, 2
	WAIT
	WAIT
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Csh, 2
	NOTE Csh, 2
	NOTE Csh, 2
	NOTE Csh, 2
	WAIT
	WAIT
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	WAIT
	NOTE Dsh, 2
	NEXT
Pat_4DAC:
	LEN 9
	INSTR 5
	NOTE F_, 3
	WAIT
	WAIT
	NOTE F_, 3
	WAIT
	WAIT
	NOTE F_, 3
	WAIT
	WAIT
	NOTE F_, 3
	WAIT
	NOTE F_, 3
	INSTR 4
	NOTE Gsh, 3
	WAIT
	WAIT
	NOTE Gsh, 3
	WAIT
	WAIT
	NOTE Gsh, 3
	WAIT
	NOTE Gsh, 3
	NOTE Gsh, 3
	WAIT
	NOTE Gsh, 3
	NOTE Ash, 3
	WAIT
	WAIT
	NOTE Ash, 3
	WAIT
	WAIT
	NOTE Ash, 3
	WAIT
	WAIT
	NOTE Ash, 3
	WAIT
	NOTE Ash, 3
	NOTE Csh, 3
	NOTE Csh, 3
	NOTE Csh, 3
	NOTE Csh, 3
	WAIT
	WAIT
	NOTE Dsh, 3
	NOTE Dsh, 3
	NOTE Dsh, 3
	NOTE Dsh, 3
	WAIT
	NOTE Dsh, 3
	INSTR 5
	NOTE F_, 3
	WAIT
	WAIT
	NOTE F_, 3
	WAIT
	NOTE F_, 3
	NOTE F_, 3
	WAIT
	WAIT
	NOTE F_, 3
	WAIT
	WAIT
	INSTR 4
	NOTE Gsh, 3
	WAIT
	WAIT
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	WAIT
	WAIT
	NOTE Gsh, 3
	WAIT
	WAIT
	NOTE Ash, 3
	WAIT
	WAIT
	NOTE Ash, 3
	WAIT
	NOTE Ash, 3
	NOTE Ash, 3
	WAIT
	WAIT
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE Csh, 4
	WAIT
	WAIT
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	NEXT
Pat_4E12:
	LEN 9
	DRUMS $09, DrumPat_4E79
	INSTR 13
	NOTE F_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE F_, 4
	NOTE Gsh, 4
	WAIT
	NOTE C_, 5
	NOTE Dsh, 5
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
	NOTE Gsh, 4
	NOTE Ash, 4
	WAIT
	WAIT
	NOTE F_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE F_, 4
	NOTE Ash, 4
	WAIT
	NOTE F_, 4
	NOTE Gsh, 4
	WAIT
	WAIT
	NOTE Dsh, 4
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	NOTE Gsh, 4
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
	NOTE F_, 4
	NOTE Gsh, 4
	WAIT
	NOTE C_, 5
	NOTE Dsh, 5
	WAIT
	WAIT
	NOTE C_, 5
	WAIT
	WAIT
	NOTE Gsh, 5
	WAIT
	WAIT
	NOTE Dsh, 5
	WAIT
	WAIT
	NOTE D_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE Ash, 4
	WAIT
	WAIT
	NOTE F_, 5
	WAIT
	WAIT
	WAIT
	NOTE F_, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE Csh, 5
	WAIT
	WAIT
	NOTE Dsh, 5
	NOTE G_, 5
	NOTE Ash, 5
	NOTE G_, 5
	NOTE Ash, 5
	NOTE Dsh, 6
	NEXT
DrumPat_4E79:
	db DRUM_LEVEL + 14, DRUM_TEMPO + 9, 9, 0, DRUM_TEMPO + 4, 10, DRUM_TEMPO + 5, 10
	db DRUM_TEMPO + 9, 10, 10, 10, 9, 0, DRUM_TEMPO + 4, 10
	db DRUM_TEMPO + 5, 10, DRUM_TEMPO + 9, 10, 10, 10, 9, 10
	db 10, 9, 0, 10, 9, 0, DRUM_TEMPO + 3, 10
	db 10, 10, DRUM_TEMPO + 9, 10, 10, 10, DRUM_LOOP

; Song 4: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong4:
	call StopAll
	ld de, Song4_Ch1
	call StartMusicCh1
	ld de, Song4_Ch2
	call StartMusicCh2
	ld de, Song4_Ch3
	jp StartMusicCh3
Song4_Ch1:
	dw Pat_4EC7
	ORDER_LOOP Song4_Ch1
Song4_Ch2:
	dw Pat_4F4F
	ORDER_LOOP Song4_Ch2
Song4_Ch3:
	dw Pat_4FDD
	ORDER_LOOP Song4_Ch3
Pat_4EC7:
	LEN 7
	DRUMS $07, DrumPat_5060
	INSTR 11
	NOTE Ash, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Ash, 2
	WAIT
	NOTE Csh, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Csh, 3
	WAIT
	NOTE Dsh, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 3
	WAIT
	NOTE Ash, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE F_, 2
	WAIT
	NOTE Ash, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Ash, 2
	WAIT
	NOTE Csh, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Csh, 2
	WAIT
	NOTE Dsh, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 2
	WAIT
	NOTE Dsh, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE F_, 2
	WAIT
	INSTR 11
	NOTE Ash, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Ash, 2
	WAIT
	NOTE Csh, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Csh, 3
	WAIT
	NOTE Dsh, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 3
	WAIT
	NOTE Ash, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE F_, 2
	WAIT
	NOTE Dsh, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 2
	WAIT
	NOTE F_, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE F_, 2
	WAIT
	NOTE Fsh, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Fsh, 2
	WAIT
	NOTE Gsh, 2
	WAIT
	NOTE Dsh, 2
	WAIT
	NOTE F_, 2
	WAIT
	NOTE Gsh, 2
	WAIT
	NEXT
Pat_4F4F:
	LEN 7
	HWENV $82, $00
	ARP 5
	NOTE Ash, 3
	WAIT
	NOTE Ash, 3
	WAIT
	NOTE Ash, 3
	WAIT
	NOTE Ash, 3
	WAIT
	ARP 4
	NOTE Csh, 4
	WAIT
	NOTE Csh, 4
	WAIT
	NOTE Csh, 4
	WAIT
	NOTE Csh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	ARP 5
	NOTE Ash, 3
	WAIT
	NOTE Ash, 3
	WAIT
	NOTE Ash, 3
	WAIT
	NOTE Ash, 3
	WAIT
	NOTE Ash, 3
	WAIT
	NOTE Ash, 3
	WAIT
	NOTE Ash, 3
	WAIT
	NOTE Ash, 3
	WAIT
	ARP 4
	NOTE Csh, 4
	WAIT
	NOTE Csh, 4
	WAIT
	NOTE Csh, 4
	WAIT
	NOTE Csh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	ARP 5
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	ARP 5
	NOTE Ash, 3
	WAIT
	NOTE Ash, 3
	WAIT
	NOTE Ash, 3
	WAIT
	NOTE Ash, 3
	WAIT
	ARP 4
	NOTE Csh, 4
	WAIT
	NOTE Csh, 4
	WAIT
	NOTE Csh, 4
	WAIT
	NOTE Csh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	ARP 5
	NOTE Ash, 3
	WAIT
	NOTE Ash, 3
	WAIT
	NOTE Ash, 3
	WAIT
	NOTE Ash, 3
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	WAIT
	ARP 4
	NOTE Fsh, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE Gsh, 4
	WAIT
	NOTE Gsh, 4
	WAIT
	NOTE Gsh, 4
	WAIT
	NOTE Gsh, 4
	WAIT
	NEXT
Pat_4FDD:
	LEN 7
	INSTR 13
	WAIT
	WAIT
	NOTE F_, 4
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE Csh, 5
	WAIT
	WAIT
	WAIT
	NOTE F_, 5
	WAIT
	NOTE Csh, 5
	WAIT
	NOTE Dsh, 5
	WAIT
	WAIT
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE Dsh, 5
	WAIT
	NOTE Csh, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE Ash, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE F_, 4
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE Gsh, 4
	WAIT
	WAIT
	WAIT
	NOTE F_, 4
	WAIT
	NOTE Gsh, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE F_, 4
	WAIT
	WAIT
	WAIT
	NOTE F_, 4
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE Csh, 5
	WAIT
	WAIT
	WAIT
	NOTE F_, 5
	WAIT
	NOTE Csh, 5
	WAIT
	NOTE Dsh, 5
	WAIT
	WAIT
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE Dsh, 5
	WAIT
	NOTE Csh, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE F_, 5
	WAIT
	NOTE Fsh, 5
	WAIT
	WAIT
	WAIT
	NOTE F_, 5
	WAIT
	NOTE Fsh, 5
	WAIT
	NOTE Gsh, 5
	WAIT
	WAIT
	WAIT
	NOTE C_, 6
	WAIT
	NOTE Gsh, 5
	WAIT
	NOTE Ash, 5
	WAIT
	NOTE C_, 6
	WAIT
	NOTE Csh, 6
	WAIT
	NOTE Dsh, 6
	WAIT
	NOTE Csh, 6
	WAIT
	WAIT
	WAIT
	NOTE C_, 6
	WAIT
	WAIT
	WAIT
	NEXT
DrumPat_5060:
	db DRUM_LEVEL + 13, DRUM_TEMPO + 7, 9, 0, DRUM_TEMPO + 4, 10, DRUM_TEMPO + 5, 10
	db 10, DRUM_TEMPO + 7, 9, 0, DRUM_TEMPO + 5, 10, 10, DRUM_TEMPO + 4
	db 10, DRUM_TEMPO + 7, 9, 0, DRUM_TEMPO + 5, 10, 10, DRUM_TEMPO + 4
	db 10, DRUM_TEMPO + 7, 9, 0, 9, 0, DRUM_TEMPO + 7, 9
	db 0, DRUM_TEMPO + 4, 10, DRUM_TEMPO + 5, 10, 10, DRUM_TEMPO + 7, 9
	db 0, DRUM_TEMPO + 5, 10, 10, DRUM_TEMPO + 4, 10, DRUM_TEMPO + 7, 9
	db 0, DRUM_TEMPO + 5, 10, 10, DRUM_TEMPO + 4, 10, DRUM_TEMPO + 7, 9
	db 9, 9, 9, DRUM_LOOP

; Song 5: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong5:
	call StopAll
	ld a, $54
	ld [wInstrTableHi], a
	ld a, $3B
	ld [wInstrTable], a
	ld de, Song5_Ch1
	call StartMusicCh1
	ld de, Song5_Ch2
	call StartMusicCh2
	ld de, Song5_Ch3
	jp StartMusicCh3
Song5_Ch1:
	dw Pat_50E5
	dw Pat_5100
	dw Pat_515E
	dw Pat_5100
	dw Pat_51A5
	ORDER_LOOP Song5_Ch1
Song5_Ch2:
	dw Pat_51EC
	dw Pat_5207
	dw Pat_523E
	dw Pat_5207
	dw Pat_526D
	ORDER_LOOP Song5_Ch2
Song5_Ch3:
	dw Pat_5299
	dw Pat_52EB
	dw Pat_5316
	dw Pat_52EB
	dw Pat_5342
	ORDER_LOOP Song5_Ch3
Pat_50E5:
	INSTR 11
	LENGTH $30
	NOTE G_, 2
	NOTE G_, 2
	LEN 24
	NOTE G_, 2
	NOTE G_, 2
	LENGTH $30
	NOTE G_, 2
	LEN 24
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	LEN 24
	NOTE G_, 2
	NOTE G_, 2
	NEXT
Pat_5100:
	INSTR 11
	LEN 16
	NOTE C_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 16
	NOTE G_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 16
	NOTE C_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 16
	NOTE G_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 16
	NOTE C_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 16
	NOTE G_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 16
	NOTE C_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 16
	NOTE G_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 16
	NOTE G_, 2
	INSTR 4
	LEN 8
	NOTE G_, 4
	INSTR 11
	LEN 16
	NOTE D_, 2
	INSTR 4
	LEN 8
	NOTE G_, 4
	INSTR 11
	LEN 16
	NOTE G_, 2
	INSTR 4
	LEN 8
	NOTE G_, 4
	INSTR 11
	LEN 16
	NOTE D_, 2
	INSTR 4
	LEN 8
	NOTE G_, 4
	INSTR 11
	LEN 16
	NOTE G_, 2
	INSTR 4
	LEN 8
	NOTE G_, 4
	INSTR 11
	LEN 16
	NOTE D_, 2
	INSTR 4
	LEN 8
	NOTE G_, 4
	INSTR 11
	LEN 16
	NOTE G_, 2
	LEN 8
	NOTE F_, 2
	LEN 16
	NOTE E_, 2
	LEN 8
	NOTE D_, 2
	NEXT
Pat_515E:
	INSTR 11
	LEN 16
	NOTE C_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 16
	NOTE G_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 16
	NOTE C_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 16
	NOTE G_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 16
	NOTE C_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 16
	NOTE G_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 16
	NOTE C_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 16
	NOTE G_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 24
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 11
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 11
	NOTE E_, 2
	INSTR 5
	NOTE D_, 4
	INSTR 11
	LEN 8
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	LEN 16
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	NEXT
Pat_51A5:
	INSTR 11
	LEN 16
	NOTE C_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 16
	NOTE G_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 16
	NOTE C_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 16
	NOTE G_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 16
	NOTE C_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 16
	NOTE G_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 16
	NOTE C_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 16
	NOTE G_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 24
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 11
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 11
	NOTE E_, 2
	INSTR 5
	NOTE D_, 4
	INSTR 11
	LEN 8
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	LEN 16
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	NEXT
Pat_51EC:
	INSTR 4
	LENGTH $30
	NOTE G_, 3
	NOTE G_, 3
	LEN 24
	NOTE G_, 3
	NOTE G_, 3
	LENGTH $30
	NOTE G_, 3
	LEN 24
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 8
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LENGTH $30
	NOTE G_, 4
	NEXT
Pat_5207:
	VIBRATO $08, $01, $04
	DUTY_50
	HWENV $C3, $00
	ARP_OFF
	LEN 40
	NOTE E_, 4
	LEN 8
	NOTE F_, 4
	LEN 40
	NOTE G_, 4
	LEN 8
	NOTE D_, 5
	LEN 16
	NOTE E_, 5
	LEN 8
	NOTE Dsh, 5
	LEN 16
	NOTE E_, 5
	LEN 8
	NOTE F_, 5
	LEN 24
	NOTE E_, 5
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE C_, 5
	LEN 24
	NOTE B_, 4
	NOTE B_, 4
	LEN 16
	NOTE B_, 4
	LEN 8
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE Dsh, 5
	NEXT
Pat_523E:
	LEN 40
	NOTE E_, 5
	LEN 8
	NOTE G_, 5
	LEN 40
	NOTE C_, 6
	LEN 8
	NOTE D_, 6
	LEN 16
	NOTE E_, 6
	LEN 8
	NOTE Dsh, 6
	LEN 16
	NOTE E_, 6
	LEN 8
	NOTE F_, 6
	LEN 24
	NOTE E_, 6
	LEN 16
	NOTE C_, 6
	LEN 8
	NOTE A_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE D_, 6
	NOTE G_, 5
	NOTE A_, 5
	NOTE B_, 5
	NOTE A_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE F_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE B_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NEXT
Pat_526D:
	LEN 40
	NOTE E_, 5
	LEN 8
	NOTE G_, 5
	LEN 40
	NOTE C_, 6
	LEN 8
	NOTE D_, 6
	LEN 16
	NOTE E_, 6
	LEN 8
	NOTE Dsh, 6
	LEN 16
	NOTE E_, 6
	LEN 8
	NOTE F_, 6
	LEN 24
	NOTE E_, 6
	LEN 16
	NOTE C_, 6
	LEN 8
	NOTE A_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE D_, 6
	NOTE G_, 5
	NOTE A_, 5
	NOTE B_, 5
	NOTE A_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE F_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE B_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	LEN 24
	NOTE G_, 5
	NOTE G_, 4
	NEXT
Pat_5299:
	DRUMS $08, DrumPat_538F
	WAVE Wave_5E7E
	VOLENV 12, $11, $18, $14
	RELEASE $01, $51
	VIBRATO $08, $01, $04
	LEN 14
	NOTE G_, 4
	LEN 5
	NOTE G_, 4
	NOTE G_, 4
	LEN 8
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 16
	NOTE B_, 4
	LEN 8
	NOTE G_, 4
	LEN 16
	NOTE B_, 4
	LEN 8
	NOTE G_, 4
	LEN 14
	NOTE B_, 4
	LEN 5
	NOTE B_, 4
	NOTE B_, 4
	LEN 8
	NOTE B_, 4
	NOTE B_, 4
	NOTE B_, 4
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE B_, 4
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE B_, 4
	LEN 14
	NOTE D_, 5
	LEN 5
	NOTE D_, 5
	NOTE D_, 5
	LEN 8
	NOTE D_, 5
	NOTE D_, 5
	NOTE D_, 5
	LEN 16
	NOTE F_, 5
	LEN 8
	NOTE D_, 5
	LEN 16
	NOTE F_, 5
	LEN 8
	NOTE D_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE A_, 5
	LEN 24
	NOTE G_, 5
	WAVE Wave_5CEE
	NOTE G_, 4
	NEXT
Pat_52EB:
	DRUMS $08, DrumPat_536F
	LEN 40
	NOTE C_, 5
	LEN 8
	NOTE D_, 5
	LEN 40
	NOTE E_, 5
	LEN 8
	NOTE F_, 5
	LEN 16
	NOTE G_, 5
	LEN 8
	NOTE Fsh, 5
	LEN 16
	NOTE G_, 5
	LEN 8
	NOTE A_, 5
	LEN 24
	NOTE G_, 5
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE E_, 5
	LEN 24
	NOTE D_, 5
	NOTE D_, 5
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE E_, 5
	LEN 16
	NOTE F_, 5
	LEN 8
	NOTE E_, 5
	LENGTH $48
	NOTE D_, 5
	LEN 24
	NOTE G_, 4
	NEXT
Pat_5316:
	LEN 40
	NOTE C_, 5
	LEN 8
	NOTE D_, 5
	LEN 40
	NOTE E_, 5
	LEN 8
	NOTE F_, 5
	LEN 16
	NOTE G_, 5
	LEN 8
	NOTE Fsh, 5
	LEN 16
	NOTE G_, 5
	LEN 8
	NOTE A_, 5
	LEN 24
	NOTE G_, 5
	LEN 16
	NOTE E_, 5
	LEN 8
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	LEN 24
	NOTE G_, 4
	LEN 8
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	LEN 24
	NOTE F_, 4
	LEN 8
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 24
	NOTE G_, 4
	NOTE G_, 3
	NEXT
Pat_5342:
	LEN 40
	NOTE C_, 5
	LEN 8
	NOTE D_, 5
	LEN 40
	NOTE E_, 5
	LEN 8
	NOTE F_, 5
	LEN 16
	NOTE G_, 5
	LEN 8
	NOTE Fsh, 5
	LEN 16
	NOTE G_, 5
	LEN 8
	NOTE A_, 5
	LEN 24
	NOTE G_, 5
	LEN 16
	NOTE E_, 5
	LEN 8
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	LEN 24
	NOTE G_, 4
	LEN 8
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	LEN 24
	NOTE F_, 4
	LEN 8
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 24
	NOTE G_, 4
	NOTE G_, 3
	DRUMS_OFF
	NEXT
DrumPat_536F:
	db DRUM_LEVEL + 14, 9, 0, DRUM_TEMPO + 4, 10, 10, DRUM_TEMPO + 8, 10
	db 10, 10, 9, 0, DRUM_TEMPO + 4, 10, 10, DRUM_TEMPO + 8
	db 10, 10, 10, 9, 10, 10, 9, 0
	db 10, 9, 0, 9, 10, 10, 10, DRUM_LOOP
DrumPat_538F:
	db DRUM_LEVEL + 14, 7, 0, 0, 0, 0, 0, 7
	db 0, 0, 0, 0, 0, 7, 0, 0
	db 7, 0, 0, 7, 0, 0, 0, 0
	db 0, DRUM_LOOP
Pat_53A9:
	TRANSPOSE $00
	NEXT
Pat_53AC:
	TRANSPOSE $02
	NEXT

; Song 1: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong1:
	call StopAll
	ld a, $54
	ld [wInstrTableHi], a
	ld a, $3B
	ld [wInstrTable], a
	ld de, Song1_Ch1
	call StartMusicCh1
	ld de, Song1_Ch3
	call StartMusicCh3
	ret
Song1_Ch1:
	dw Pat_53D5
	ORDER_LOOP Song1_Ch1
Song1_Ch3:
	dw Pat_53F4
	ORDER_LOOP Song1_Ch3
Pat_53D5:
	DRUMS $0A, DrumPat_5417
	INSTR 1
	LEN 10
	NOTE G_, 2
	WAIT
	WAIT
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE G_, 2
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE D_, 2
	NOTE G_, 2
	WAIT
	WAIT
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE G_, 2
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE D_, 2
	NEXT
Pat_53F4:
	VOLENV 15, $11, $1F, $11
	LEN 10
	GLIDE $FD
	WAVE Wave_5DEE
	NOTE C_, 5
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
	NOTE C_, 5
	WAIT
	WAIT
	NOTE C_, 5
	WAIT
	WAIT
	NOTE C_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NEXT
DrumPat_5417:
	db DRUM_LEVEL + 14, DRUM_TEMPO + 10, 9, 0, DRUM_TEMPO + 5, 10, 10, DRUM_TEMPO + 10
	db 10, 10, 10, 9, 0, DRUM_TEMPO + 5, 10, 10
	db DRUM_TEMPO + 10, 10, 10, 10, 9, 10, 10, 9
	db 0, 10, 9, 0, DRUM_TEMPO + 3, 10, 10, DRUM_TEMPO + 4
	db 10, DRUM_TEMPO + 10, 10, 10, 10, DRUM_LOOP

; Instrument table 1, entries 1..15 (the song routines point 2 bytes before:
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
	dw Instr1_10
	dw Instr1_12
	dw Instr1_13
	dw Instr1_14

; Unreferenced (2 bytes)
	db $B8, $54
Instr1_0:
	HWENV $F1, $04, $A4
	DUTY_75
	END
Instr1_1:
	HWENV $F1, $05, $61
	ARP 18
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
	HWENV $C2, $04, $64
	DUTY_12
	ARP 4
	END
Instr1_5:
	HWENV $C2, $04, $64
	DUTY_12
	ARP 5
	END
Instr1_6:
	VOLENV 15, $11, $1F, $12
	ARP 0
	END
Instr1_7:
	VOLENV 15, $11, $1F, $11
	ARP 0
	END
Instr1_8:
	HWENV $F1, $00
	ARP 0
	DUTY_12
	END
Instr1_9:
	HWENV $A2, $00
	END
Instr1_10:
	HWENV $F3, $07, $82
	ARP 0
	END
Instr1_12:
	HWENV $F2, $0D, $47
	ARP 0
	DUTY_75
	END
Instr1_13:
	VOLENV 8, $18, $1A, $1A
	RELEASE $71, $11
	VIBRATO $0C, $01, $04
	WAVE Wave_5CEE
	END
Instr1_14:
	HWENV $C1, $0C, $67
	END
ArpTable:
	dw Arp0
	dw Arp1
	dw Arp2
	dw Arp3
	dw Arp1
	dw Arp5
	dw Arp6
	dw Arp7
	dw Arp8
	dw Arp8
	dw Arp8
	dw Arp8
	dw Arp8
	dw Arp13
	dw Arp13
	dw Arp13
	dw Arp16
	dw Arp17
	dw Arp18

; Unreferenced (18 bytes)
	db $72, $55, $76, $55, $76, $55, $76, $55, $76, $55, $76, $55, $76, $55, $76, $55
	db $76, $55
Arp0:
	db $0C, $00, ARP_HOLD
Arp3:
	db $00, $00, $01, $01, $02, ARP_HOLD
Arp2:
	db $0C, $0C, $0C, $00, $00, $00, ARP_LOOP
Arp1:
	db $00, $00, $04, $04, $07, $07, ARP_LOOP
Arp5:
	db $00, $00, $03, $03, $07, $07, ARP_LOOP
Arp6:
	db $00, $00, $04, $04, $07, $07, ARP_LOOP
Arp7:
	db $00, $01, $02, ARP_HOLD
Arp8:
	db $00, $0C, $00, ARP_HOLD
Arp13:
	db $00, $00, $00, $03, $03, $08, $08, $0C
	db $0C, $0C, $0F, $0F, $13, $13, $0F, $0F
	db $0C, $0C, $07, $07, $03, $03, ARP_LOOP
Arp16:
	db $0C, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $18, $0C, $0C, $0C, $0C
	db $0C, $0C, $0C, $0C, $0C, $0C, ARP_LOOP
Arp17:
	db $00, $00, $00, $03, $03, $08, $08, $0C
	db $0C, $0C, $0F, $0F, $14, $14, $0F, $0F
	db $08, $08, $03, $03, $00, $00, ARP_LOOP
Arp18:
	db $06, $02, $00, $FE, $FB, $F8, $F6, $F2
	db $F0, $EC, ARP_HOLD

; Unreferenced (4 bytes)
	db $0E, $03
SfxTable_m2:
	db $02, $FF

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

; Sound effect 13
Sfx13:
	VOLENV 15, $11, $1F, $16
	CH_TRANSPOSE $18
	CALL_CODE Code_58B5
	WAVE Wave_5DEE
	LEN 10
	GLIDE $FF
	NOTE C_, 4
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE Fsh, 3
	NOTE E_, 3
	WAIT
	END

; Unreferenced (12 bytes)
	db $BB, $11, $1F, $11, $79, $5E, $5D, $60, $02, $CB, $15, $68

; Sound effect 1
Sfx01:
	CALL_CODE Code_5A0D
	VOLENV 15, $11, $1F, $1F
	WAVE Wave_5DEE
	LEN 20
	GLIDE $03
	NOTE C_, 2
	END

; Unreferenced (104 bytes)
	db $BC, $11, $1F, $13, $63, $00, $01, $04, $79, $8E, $5D, $7F, $0D, $5A, $60, $FC
	db $C4, $2D, $7F, $0D, $5A, $60, $08, $65, $7F, $EB, $59, $61, $C9, $65, $60, $FF
	db $65, $68, $79, $8E, $5D, $60, $04, $C9, $7A, $F4, $94, $B5, $00, $00, $00, $21
	db $BA, $00, $00, $00, $21, $BF, $00, $00, $00, $21, $21, $21, $BA, $00, $00, $00
	db $21, $B5, $00, $00, $00, $21, $21, $68, $BF, $11, $1F, $13, $79, $EE, $5D, $7F
	db $2C, $5B, $C4, $24, $7F, $73, $5C, $C0, $66, $C9, $60, $FE, $33, $B5, $11, $1F
	db $13, $33, $B5, $11, $1F, $13, $33, $68

; Sound effect 4
Sfx04:
	LEN 5
	ARP 0
	WAVE Wave_5DBE
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

; Unreferenced (177 bytes)
	db $7F, $0D, $5A, $BF, $00, $00, $00, $97, $79, $5E, $5E, $C2, $66, $7F, $92, $5A
	db $C4, $60, $FE, $1C, $68, $7F, $8E, $5B, $BB, $11, $1F, $12, $63, $01, $06, $03
	db $DD, $79, $5E, $5D, $30, $68, $7F, $2F, $5A, $BB, $11, $1F, $14, $79, $9E, $5D
	db $C4, $60, $FB, $30, $68, $7F, $0D, $5A, $79, $9E, $5D, $BF, $11, $1F, $11, $C4
	db $60, $04, $15, $60, $65, $65, $65, $68, $7F, $EB, $59, $BB, $11, $1F, $13, $79
	db $8E, $5D, $D6, $83, $03, $2D, $68, $7F, $60, $59, $79, $5E, $5D, $BF, $11, $1F
	db $11, $94, $C6, $60, $FF, $12, $68, $BF, $0F, $1F, $14, $C2, $99, $60, $01, $79
	db $0E, $5E, $E7, $2D, $68, $BF, $11, $5F, $11, $7A, $F4, $96, $79, $0E, $5E, $C6
	db $39, $C5, $39, $C4, $39, $C3, $39, $C2, $39, $C1, $39, $BA, $11, $5F, $11, $39
	db $39, $B5, $11, $5F, $11, $39, $39, $68, $BF, $00, $00, $00, $60, $FC, $C9, $7A
	db $3F, $9A, $79, $0E, $5E, $15, $BA, $00, $00, $00, $15, $B5, $00, $00, $00, $15
	db $68

; Sound effect 8
Sfx08:
	CALL_CODE Code_5B5D
	VOLENV 15, $11, $1F, $11
	WAVE Wave_5D5E
	LEN 6
	GLIDE $FD
	NOTE D_, 4
	CALL_CODE Code_5B5D
	WAVE Wave_5DCE
	GLIDE $05
	NOTE C_, 3
	NOTE Dsh, 3
	NOTE Fsh, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	END

; Unreferenced (47 bytes)
	db $BF, $00, $00, $00, $60, $05, $C9, $79, $0E, $5E, $15, $BA, $00, $00, $00, $15
	db $B5, $00, $00, $00, $15, $68, $BF, $00, $00, $00, $63, $00, $20, $02, $60, $FF
	db $7A, $08, $CE, $30, $BA, $00, $00, $00, $30, $B5, $00, $00, $00, $30, $68

; Sound effect 7
Sfx07:
	VOLENV 15, $11, $1F, $12
	GLIDE $FD
	WAVE Wave_5D5E
	CALL_CODE Code_58B5
	LEN 9
	NOTE E_, 3
	LEN 7
	NOTE E_, 3
	NOTE D_, 3
	END

; Unreferenced (54 bytes)
	db $BF, $00, $00, $00, $C7, $7A, $F6, $96, $79, $4E, $5E, $2D, $79, $2E, $5D, $2D
	db $79, $3E, $5E, $2D, $2D, $79, $5E, $5E, $2D, $68, $79, $5E, $5D, $BF, $11, $1F
	db $11, $7F, $E2, $58, $C4, $60, $FE, $18, $61, $79, $2E, $5D, $B5, $1F, $00, $20
	db $7F, $0B, $59, $D4, $1C, $68

; Sound effect 6
Sfx06:
	CALL_CODE Code_5CB1
	VOLENV 15, $11, $1F, $13
	WAVE Wave_5D5E
	GLIDE $FE
	LEN 10
	CH_TRANSPOSE $0C
	NOTE C_, 3
	VOLENV 10, $11, $1F, $13
	NOTE C_, 3
	VOLENV 5, $11, $1F, $13
	NOTE C_, 3
	END

; Unreferenced (19 bytes)
	db $7F, $40, $5C, $BF, $11, $1F, $11, $60, $FF, $79, $5E, $5D, $C9, $13, $7F, $40
	db $5C, $13, $68

; Sound effect 9
Sfx09:
	CALL_CODE Code_5BB7
	END

; Sound effect 5
Sfx05:
	WAVE Wave_5DEE
	CALL_CODE Code_5AF8
	VOLENV 15, $12, $1F, $12
	LEN 8
	GLIDE $FF
	NOTE A_, 4
	LEN 5
	VOLENV 10, $11, $1F, $12
	NOTE A_, 4
	END

; Unreferenced (55 bytes)
	db $BA, $15, $1F, $23, $63, $00, $02, $06, $79, $6E, $5E, $9C, $D3, $39, $65, $68
	db $7F, $92, $5A, $BF, $00, $00, $00, $79, $DE, $5C, $C2, $60, $FF, $39, $79, $9E
	db $5E, $65, $60, $FE, $79, $BE, $5E, $65, $C9, $79, $9E, $5E, $BA, $00, $00, $00
	db $34, $B5, $00, $00, $00, $34, $68

; Sound effect 11
Sfx11:
	CALL_CODE Code_5C73
	END

; Sound effect 12
Sfx12:
	CALL_CODE Code_5C73
	VOLENV 10, $15, $AF, $10
	LEN 10
	RELEASE $03, $11
	VIBRATO $0A, $01, $04
	WAVE Wave_5E7E
	LEN 8
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE F_, 5
	CALL_CODE Code_5C73
	NOTE C_, 6
	WAIT
	END

; Unreferenced (8 bytes)
	db $7F, $92, $5A, $68, $7F, $11, $5C, $68

; Sound effect 2
Sfx02:
	VOLENV 15, $11, $2F, $11
	LEN 10
	WAVE Wave_5D5E
	GLIDE $04
	NOTE C_, 4
	END

; Sound effect 3
Sfx03:
	LEN 4
	VOLENV 15, $11, $2F, $11
	WAVE Wave_5D5E
	NOTE C_, 7
	LEN 2
	REST
	LEN 4
	NOTE E_, 6
	END

; Unreferenced (89 bytes)
	db $BF, $11, $1F, $11, $7F, $2C, $5B, $79, $5E, $5D, $CB, $60, $FE, $18, $68, $C4
	db $9A, $79, $FE, $5D, $BF, $10, $1F, $12, $3C, $43, $40, $3C, $43, $68, $7F, $BF
	db $5A, $68, $BF, $11, $1F, $14, $79, $7E, $5D, $63, $01, $01, $08, $C3, $24, $30
	db $2C, $68, $BC, $11, $1F, $14, $79, $5E, $5D, $60, $04, $C3, $1F, $60, $FD, $C5
	db $65, $66, $68, $BA, $11, $10, $00, $79, $4E, $5E, $60, $02, $C4, $15, $61, $C2
	db $65, $60, $02, $65, $68, $7F, $8D, $59, $68

; Sound effect 10
Sfx10:
	VOLENV 15, $00, $00, $00
	WAVE Wave_5E4E
	LEN 5
	NOTE A_, 3
	LEN 3
	REST
	LEN 20
	NOTE A_, 3
	END
Code_58B5:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $28
	ld [wDrumHold], a
	ld a, HIGH(Noise43_58D7)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_58D7)
	ld [wNoise43], a
	ld a, HIGH(Noise42_58DD)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_58DD)
	ld [wNoise42], a
	ret
Noise43_58D7:
	db $57, $56, $54, $53, $47, $FF
Noise42_58DD:
	db $F0, $F0, $60, $70, $F3

; Unreferenced (299 bytes)
	db $AF, $EA, $5B, $DC, $3C, $EA, $5C, $DC, $3E, $0A, $EA, $47, $DC, $3E, $59, $EA
	db $57, $DC, $3E, $04, $EA, $58, $DC, $3E, $59, $EA, $59, $DC, $3E, $08, $EA, $5A
	db $DC, $C9, $4A, $5A, $50, $FF, $F0, $D0, $B1, $AF, $EA, $5B, $DC, $3C, $EA, $5C
	db $DC, $3E, $1E, $EA, $47, $DC, $3E, $D2, $E0, $21, $3E, $80, $E0, $23, $3E, $59
	db $EA, $57, $DC, $3E, $35, $EA, $58, $DC, $3E, $00, $EA, $59, $DC, $3E, $00, $EA
	db $5A, $DC, $C9, $18, $3A, $47, $49, $2E, $2D, $1C, $28, $4A, $57, $39, $4E, $1D
	db $0C, $FF, $82, $64, $02, $37, $47, $24, $55, $71, $07, $44, $60, $36, $84, $82
	db $64, $02, $37, $47, $24, $55, $71, $07, $44, $60, $36, $86, $32, $FF, $AF, $EA
	db $5B, $DC, $3C, $EA, $5C, $DC, $3E, $13, $EA, $47, $DC, $CD, $8E, $49, $3E, $F2
	db $E0, $21, $3E, $80, $E0, $23, $3E, $59, $EA, $57, $DC, $3E, $44, $EA, $58, $DC
	db $3E, $00, $EA, $59, $DC, $3E, $00, $EA, $5A, $DC, $C9, $AF, $EA, $5B, $DC, $3C
	db $EA, $5C, $DC, $3E, $13, $EA, $47, $DC, $CD, $8E, $49, $3E, $F1, $E0, $21, $3E
	db $80, $E0, $23, $3E, $59, $EA, $57, $DC, $3E, $44, $EA, $58, $DC, $3E, $00, $EA
	db $59, $DC, $3E, $00, $EA, $5A, $DC, $C9, $3E, $08, $EA, $47, $DC, $AF, $EA, $5B
	db $DC, $3C, $EA, $5C, $DC, $3E, $59, $EA, $57, $DC, $3E, $DC, $EA, $58, $DC, $3E
	db $59, $EA, $59, $DC, $3E, $E4, $EA, $5A, $DC, $C9, $60, $52, $42, $41, $22, $11
	db $21, $FF, $F0, $F0, $F0, $F0, $F0, $F0, $61, $3E, $0F, $EA, $47, $DC, $AF, $EA
	db $5B, $DC, $3C, $EA, $5C, $DC, $3E, $5A, $EA, $57, $DC, $3E, $6B, $EA, $58, $DC
	db $3E, $5A, $EA, $59, $DC, $3E, $85, $EA, $5A, $DC, $C9
Code_5A0D:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5A78)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5A78)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5A85)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5A85)
	ld [wNoise42], a
	ret

; Unreferenced (73 bytes)
	db $3E, $0F, $EA, $47, $DC, $AF, $EA, $5B, $DC, $3C, $EA, $5C, $DC, $3E, $5A, $EA
	db $57, $DC, $3E, $5E, $EA, $58, $DC, $3E, $5A, $EA, $59, $DC, $3E, $51, $EA, $5A
	db $DC, $C9, $F1, $A1, $FF, $FF, $FF, $FF, $43, $FF, $FF, $FF, $FF, $FF, $FF, $51
	db $10, $20, $31, $32, $33, $53, $34, $14, $15, $15, $16, $FF, $10, $10, $20, $31
	db $32, $33, $33, $34, $34, $35, $35, $36, $FF
Noise43_5A78:
	db $36, $35, $35, $34, $34, $33, $33, $32
	db $31, $20, $10, $10, $FF
Noise42_5A85:
	db $5F, $FF, $FF, $FF, $FF, $FF, $A1, $FF
	db $FF, $FF, $FF, $FF

; Unreferenced (103 bytes)
	db $FF, $3E, $04, $EA, $47, $DC, $AF, $EA, $5B, $DC, $3C, $EA, $5C, $DC, $3E, $5A
	db $EA, $57, $DC, $3E, $B4, $EA, $58, $DC, $3E, $5A, $EA, $59, $DC, $3E, $BA, $EA
	db $5A, $DC, $C9, $00, $53, $71, $91, $31, $FF, $F2, $FF, $FF, $FF, $00, $3E, $0A
	db $EA, $47, $DC, $AF, $EA, $5B, $DC, $3C, $EA, $5C, $DC, $3E, $5A, $EA, $57, $DC
	db $3E, $E1, $EA, $58, $DC, $3E, $5A, $EA, $59, $DC, $3E, $ED, $EA, $5A, $DC, $C9
	db $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0, $FF, $F0, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $00
Code_5AF8:
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
	ld a, HIGH(Noise43_5B22)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5B22)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_5B22:
	db $02, $92, $42, $42, $42, $42, $52, $65
	db $45, $FF

; Unreferenced (49 bytes)
	db $3E, $0F, $EA, $47, $DC, $AF, $EA, $5B, $DC, $3C, $EA, $5C, $DC, $3E, $5B, $EA
	db $57, $DC, $3E, $4E, $EA, $58, $DC, $3E, $5B, $EA, $59, $DC, $3E, $56, $EA, $5A
	db $DC, $C9, $02, $51, $61, $71, $91, $71, $60, $FF, $F0, $F0, $F0, $F0, $F0, $70
	db $63
Code_5B5D:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5B7F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5B7F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5B87)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5B87)
	ld [wNoise42], a
	ret
Noise43_5B7F:
	db $72, $71, $72, $72, $72, $72, $71, $FF
Noise42_5B87:
	db $F0, $FF, $FF, $FF, $FF, $FF, $63

; Unreferenced (41 bytes)
	db $3E, $0F, $EA, $47, $DC, $AF, $EA, $5B, $DC, $3C, $EA, $5C, $DC, $3E, $5B, $EA
	db $57, $DC, $3E, $B0, $EA, $58, $DC, $3E, $5B, $EA, $59, $DC, $3E, $B4, $EA, $5A
	db $DC, $C9, $02, $51, $22, $FF, $F0, $A0, $45
Code_5BB7:
	ld a, $19
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5BD9)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5BD9)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5BDF)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5BDF)
	ld [wNoise42], a
	ret
Noise43_5BD9:
	db $02, $41, $61, $71, $11, $FF
Noise42_5BDF:
	db $F0, $FF, $FF, $A0, $B3

; Unreferenced (143 bytes)
	db $3E, $08, $EA, $47, $DC, $AF, $EA, $5B, $DC, $3C, $EA, $5C, $DC, $3E, $5C, $EA
	db $57, $DC, $3E, $06, $EA, $58, $DC, $3E, $5C, $EA, $59, $DC, $3E, $0C, $EA, $5A
	db $DC, $C9, $00, $83, $60, $60, $31, $FF, $F0, $FF, $FF, $FF, $D1, $3E, $04, $EA
	db $47, $DC, $AF, $EA, $5B, $DC, $3C, $EA, $5C, $DC, $3E, $5C, $EA, $57, $DC, $3E
	db $33, $EA, $58, $DC, $3E, $5C, $EA, $59, $DC, $3E, $3A, $EA, $5A, $DC, $C9, $41
	db $61, $61, $41, $71, $71, $FF, $A1, $52, $00, $61, $52, $00, $3E, $0A, $EA, $47
	db $DC, $AF, $EA, $5B, $DC, $3C, $EA, $5C, $DC, $3E, $5C, $EA, $57, $DC, $3E, $62
	db $EA, $58, $DC, $3E, $5C, $EA, $59, $DC, $3E, $6B, $EA, $5A, $DC, $C9, $78, $78
	db $78, $78, $58, $56, $56, $68, $FF, $A1, $FF, $11, $00, $81, $FF, $F2, $00
Code_5C73:
	ld a, $2D
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $02
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_5C9E)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5C9E)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5CA8)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5CA8)
	ld [wNoise42], a
	ret
Noise43_5C9E:
	db $35, $34, $35, $34, $33, $32, $31, $60
	db $50, $FF
Noise42_5CA8:
	db $19, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $C3
Code_5CB1:
	ld a, $19
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5CD3)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5CD3)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5CD9)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5CD9)
	ld [wNoise42], a
	ret
Noise43_5CD3:
	db $03, $83, $80, $80, $61, $FF
Noise42_5CD9:
	db $F0, $FF, $FF, $FF, $F2

; Unreferenced (16 bytes)
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $77, $77, $00, $00, $00
Wave_5CEE:
	db $01, $11, $11, $00, $89, $AA, $AA, $98
	db $01, $11, $11, $00, $FF, $FF, $FF, $FF

; Unreferenced (96 bytes)
	db $A8, $42, $22, $8A, $EE, $EE, $EE, $EE, $A8, $42, $24, $8A, $EE, $EE, $EE, $EE
	db $8C, $FE, $ED, $B8, $53, $21, $10, $24, $84, $01, $12, $35, $8B, $DE, $EF, $8C
	db $00, $16, $8A, $FF, $FF, $A8, $61, $00, $00, $16, $8A, $FF, $FF, $A8, $61, $00
	db $B7, $40, $F4, $7B, $FD, $FF, $FE, $DC, $02, $46, $8A, $BD, $FD, $BA, $6F, $20
	db $32, $22, $11, $11, $11, $22, $23, $45, $FD, $CB, $A9, $87, $65, $43, $21, $10
	db $DD, $DB, $97, $52, $22, $54, $22, $22, $DD, $DC, $BD, $DD, $DB, $85, $22, $22
Wave_5D5E:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF

; Unreferenced (80 bytes)
	db $01, $11, $11, $00, $89, $AA, $AA, $98, $01, $11, $11, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $CD, $EF, $FD, $EC, $00, $12, $21, $00, $DD, $DD, $DD, $DD
	db $00, $00, $00, $00, $00, $00, $FF, $FF, $00, $00, $00, $00, $00, $00, $FF, $FF
	db $00, $00, $00, $00, $00, $00, $FF, $00, $00, $00, $00, $00, $00, $00, $FF, $00
	db $00, $00, $00, $CD, $EF, $FF, $FF, $FF, $04, $8C, $FF, $FF, $FF, $FF, $FF, $FF
Wave_5DBE:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $00, $FF, $FF, $FF
Wave_5DCE:
	db $12, $34, $56, $78, $9A, $BC, $DE, $FF
	db $ED, $CB, $A9, $87, $65, $43, $21, $00

; Unreferenced (16 bytes)
	db $FF, $FE, $ED, $B8, $53, $21, $10, $00, $00, $01, $12, $35, $8B, $DE, $EF, $FF
Wave_5DEE:
	db $63, $10, $00, $00, $00, $00, $01, $36
	db $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9

; Unreferenced (80 bytes)
	db $63, $10, $01, $47, $74, $10, $01, $36, $9C, $EF, $FE, $B8, $8B, $EF, $FE, $C9
	db $63, $1F, $01, $47, $74, $10, $01, $36, $9C, $E0, $FE, $B8, $8B, $EF, $FE, $C9
	db $65, $43, $22, $27, $72, $22, $22, $29, $AB, $CC, $BA, $98, $9C, $EE, $EE, $C9
	db $63, $20, $02, $47, $74, $22, $22, $36, $9C, $EF, $FE, $B6, $6B, $EE, $EE, $C9
	db $B7, $40, $04, $7B, $CD, $FF, $FE, $DC, $02, $46, $8A, $BD, $FD, $BA, $64, $20
Wave_5E4E:
	db $0F, $00, $F0, $F0, $F0, $F0, $00, $0F
	db $0F, $FF, $FF, $00, $FF, $F0, $0F, $0F

; Unreferenced (32 bytes)
	db $BB, $2B, $BB, $2B, $BB, $5B, $2B, $BB, $2B, $BB, $BB, $72, $27, $EB, $BB, $B0
	db $00, $00, $00, $00, $00, $00, $00, $00, $ED, $CB, $A9, $87, $65, $43, $21, $00
Wave_5E7E:
	db $FE, $DB, $97, $53, $13, $54, $32, $10
	db $FE, $DC, $BC, $EF, $DB, $85, $32, $10

; Unreferenced (96 bytes)
	db $54, $8B, $88, $88, $88, $86, $39, $87, $65, $44, $44, $32, $33, $24, $7A, $74
	db $04, $8B, $DE, $FF, $ED, $CB, $A9, $87, $65, $44, $44, $32, $11, $24, $7A, $74
	db $20, $13, $69, $BD, $FD, $B9, $64, $20, $13, $68, $B8, $64, $20, $24, $68, $64
	db $20, $24, $68, $AC, $EC, $A8, $64, $20, $24, $68, $A8, $64, $20, $24, $68, $64
	db $02, $48, $AC, $FF, $FC, $53, $00, $27, $9C, $DD, $DC, $B7, $7B, $CD, $DD, $C9
	db $BD, $FF, $AC, $FF, $FC, $52, $00, $27, $9C, $DF, $DC, $B7, $7B, $CD, $AD, $C9
Noise43_5EEE:
	db $01, $61, $71, $A1, $B1, $B1, $A1, $FF
Noise42_5EF6:
	db $C1, $F0, $A0, $90, $70, $40, $33
Noise43_5EFD:
	db $06, $04, $03, $03, $07, $FF
Noise42_5F03:
	db $F0, $C0, $80, $60, $55
Noise43_5F08:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_5F10:
	db $60, $30, $12, $FF, $FF, $FF, $FF
Noise43_5F17:
	db $04, $00, $00, $00, $00, $00, $00, $FF
Noise42_5F1F:
	db $90, $53, $FF, $FF, $FF, $FF, $FF
Noise43_5F26:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_5F2E:
	db $70, $40, $40, $40, $40, $43, $FF

; Unreferenced (23 bytes)
	db $50, $41, $50, $51, $42, $53, $51, $FF, $F0, $70, $F0, $70, $D0, $70, $61, $3E
	db $08, $EA, $47, $DC, $CD, $8E, $49
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5EEE)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5EEE)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5EF6)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5EF6)
	ld [wNoise42], a
	ret
Drum8:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5F86)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5F86)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5F8C)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5F8C)
	ld [wNoise42], a
	ret
Noise43_5F86:
	db $04, $02, $01, $00, $00, $FF
Noise42_5F8C:
	db $40, $60, $70, $82, $71
Drum2:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5FAE)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5FAE)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5FB6)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5FB6)
	ld [wNoise42], a
	ret
Noise43_5FAE:
	db $60, $52, $42, $41, $22, $11, $04, $FF
Noise42_5FB6:
	db $F0, $F0, $F0, $A0, $70, $40, $51
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5F26)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5F26)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5F2E)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5F2E)
	ld [wNoise42], a
	ret
Drum5:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5F17)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5F17)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5F1F)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5F1F)
	ld [wNoise42], a
	ret
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5F08)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5F08)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5F10)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5F10)
	ld [wNoise42], a
	ret
Drum7:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5EFD)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5EFD)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5F03)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5F03)
	ld [wNoise42], a
	ret
Drum9:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_604E)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_604E)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6051)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6051)
	ld [wNoise42], a
	ret
Noise43_604E:
	db $51, $32, $FF
Noise42_6051:
	db $F0, $62
Drum10:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_608D)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_608D)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6090)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6090)
	ld [wNoise42], a
	ret

; Unreferenced (29 bytes)
	db $AF, $EA, $5B, $DC, $3C, $EA, $5C, $DC, $3E, $60, $EA, $57, $DC, $3E, $92, $EA
	db $58, $DC, $3E, $60, $EA, $59, $DC, $3E, $9A, $EA, $5A, $DC, $C9
Noise43_608D:
	db $51, $32, $FF
Noise42_6090:
	db $70, $52

; Unreferenced (72 bytes)
	db $51, $32, $32, $32, $32, $51, $32, $FF, $70, $51, $FF, $FF, $FF, $70, $51, $44
	db $53, $62, $71, $62, $53, $44, $35, $26, $17, $26, $35, $6A, $77, $67, $57, $47
	db $37, $47, $57, $67, $77, $76, $75, $74, $73, $74, $75, $76, $6A, $00, $01, $02
	db $03, $04, $05, $06, $07, $17, $27, $36, $46, $55, $64, $73, $72, $71, $70, $60
	db $50, $40, $30, $20, $10, $00, $00, $6A
FadeOutTable:
	db $77, $66, $55, $44, $33, $22, $11, $00
	db FADE_END
FadeInTable:
	db $00, $11, $22, $33, $44, $55, $66, $77
	db FADE_END
DriverEndText:
	db "Final de la rutina de musicaicaicaica"

; Unreferenced (7919 bytes)
	db $81, $FB, $95, $23, $74, $24, $81, $FB, $97, $23, $74, $02, $EB, $38, $C4, $5E
	db $06, $26, $FF, $37, $57, $6A, $01, $9A, $45, $07, $57, $17, $50, $9A, $AF, $03
	db $77, $17, $B8, $01, $00, $5F, $5E, $C9, $4D, $CB, $C4, $5E, $06, $26, $FF, $37
	db $57, $6A, $00, $9A, $45, $07, $57, $17, $50, $9A, $AF, $03, $77, $17, $B8, $01
	db $00, $5F, $5E, $C9, $4D, $CB, $33, $C0, $5F, $5E, $C9, $4D, $CB, $5F, $5E, $C9
	db $4D, $CB, $DF, $BF, $DF, $BF, $FB, $BF, $FB, $BF, $DC, $BE, $A7, $BF, $A7, $BF
	db $A7, $BF, $A7, $BF, $A7, $BF, $A7, $BF, $A7, $BF, $A7, $BF, $A7, $BF, $A7, $BF
	db $A7, $BF, $A7, $BF, $A7, $BF, $82, $BF, $82, $BF, $82, $BF, $82, $BF, $82, $BF
	db $82, $BF, $82, $BF, $82, $BF, $82, $BF, $82, $BF, $A5, $BE, $A7, $BF, $A7, $BF
	db $A7, $BF, $A7, $BF, $A5, $BE, $A7, $BF, $A7, $BF, $A7, $BF, $A7, $BF, $A7, $BF
	db $DC, $BE, $DC, $BE, $DC, $BE, $45, $55, $8B, $EC, $83, $EC, $04, $A1, $14, $5C
	db $89, $46, $FC, $C4, $5E, $24, $26, $8B, $47, $2C, $A3, $14, $5C, $66, $8B, $46
	db $24, $66, $A3, $16, $5C, $FF, $76, $22, $FF, $76, $20, $FF, $76, $1E, $FF, $76
	db $1C, $FF, $76, $1A, $FF, $76, $18, $FF, $76, $16, $FF, $76, $14, $FF, $76, $12
	db $FF, $76, $10, $FF, $76, $0E, $FF, $76, $0C, $FF, $76, $0A, $FF, $76, $08, $FF
	db $76, $06, $90, $0E, $E8, $A1, $00, $83, $C4, $1E, $89, $46, $FE, $66, $C7, $06
	db $16, $5C, $00, $00, $00, $00, $8B, $46, $FC, $A3, $14, $5C, $8B, $46, $FE, $C9
	db $4D, $CB, $C9, $4D, $CB, $45, $55, $8B, $EC, $83, $EC, $06, $56, $33, $F6, $A1
	db $14, $5C, $89, $46, $FC, $A1, $2E, $0E, $89, $46, $FA, $A1, $38, $5B, $A3, $14
	db $5C, $83, $3E, $30, $0E, $00, $74, $08, $90, $0E, $E8, $5A, $B7, $BE, $01, $00
	db $FF, $76, $22, $FF, $76, $20, $FF, $76, $1E, $FF, $76, $1C, $FF, $76, $1A, $FF
	db $76, $18, $FF, $76, $16, $FF, $76, $14, $FF, $76, $12, $FF, $76, $10, $FF, $76
	db $0E, $FF, $76, $0C, $FF, $76, $0A, $FF, $76, $08, $FF, $76, $06, $90, $0E, $E8
	db $26, $00, $83, $C4, $1E, $89, $46, $FE, $8B, $46, $FC, $A3, $14, $5C, $0B, $F6
	db $74, $05, $90, $0E, $E8, $57, $B7, $8B, $46, $FA, $A3, $2E, $0E, $8B, $46, $FE
	db $5E, $C9, $4D, $CB, $5E, $C9, $4D, $CB, $45, $55, $8B, $EC, $83, $EC, $1A, $56
	db $90, $0E, $E8, $31, $A6, $89, $56, $FE, $89, $46, $FC, $66, $83, $7E, $FC, $00
	db $75, $07, $B8, $FF, $FF, $5E, $C9, $4D, $CB, $C4, $5E, $FC, $66, $A1, $16, $5C
	db $66, $26, $89, $47, $10, $C4, $5E, $FC, $26, $C7, $47, $32, $10, $00, $C4, $5E
	db $FC, $26, $C7, $07, $FF, $FF, $C4, $5E, $FC, $66, $A1, $A6, $5B, $66, $26, $89
	db $47, $06, $C4, $5E, $FC, $66, $8B, $46, $0A, $66, $26, $89, $47, $0A, $C4, $5E
	db $FC, $8B, $46, $0E, $26, $89, $47, $0E, $C4, $5E, $FC, $26, $C7, $47, $30, $00
	db $00, $C4, $5E, $FC, $26, $C7, $47, $60, $01, $00, $C4, $5E, $FC, $26, $C7, $47
	db $36, $57, $23, $26, $C7, $47, $34, $CA, $B6, $C4, $5E, $FC, $66, $26, $C7, $47
	db $58, $00, $00, $00, $00, $C4, $5E, $FC, $66, $26, $C7, $47, $5C, $00, $00, $00
	db $00, $C4, $5E, $FC, $66, $8B, $46, $06, $66, $26, $89, $47, $14, $C4, $5E, $FC
	db $26, $C6, $47, $62, $00, $8B, $46, $FC, $05, $28, $00, $FF, $76, $FE, $50, $9A
	db $F1, $14, $1F, $30, $83, $C4, $04, $FF, $76, $FE, $FF, $76, $FC, $1E, $68, $6E
	db $0E, $90, $0E, $E8, $89, $9A, $83, $C4, $08, $83, $3E, $6A, $10, $00, $74, $28
	db $66, $A1, $00, $5C, $66, $89, $46, $F6, $66, $A1, $04, $5C, $66, $89, $46, $F2
	db $66, $A1, $08, $5C, $66, $89, $46, $EE, $66, $A1, $0C, $5C, $66, $89, $46, $EA
	db $66, $A1, $10, $5C, $66, $89, $46, $E6, $66, $8B, $46, $10, $66, $A3, $00, $5C
	db $66, $8B, $46, $14, $66, $A3, $04, $5C, $66, $8B, $46, $18, $66, $A3, $08, $5C
	db $66, $8B, $46, $1C, $66, $A3, $0C, $5C, $66, $8B, $46, $20, $66, $A3, $10, $5C
	db $FF, $06, $6A, $10, $C7, $06, $46, $0E, $00, $00, $A1, $AE, $0F, $89, $46, $FA
	db $FF, $36, $9A, $5B, $FF, $36, $14, $5C, $FF, $36, $14, $5C, $FF, $76, $08, $FF
	db $76, $06, $66, $6A, $05, $9A, $3B, $00, $3F, $01, $50, $9A, $04, $00, $3F, $01
	db $50, $FF, $36, $2C, $0E, $C4, $5E, $FC, $26, $FF, $77, $08, $26, $FF, $77, $06
	db $9A, $BD, $43, $4F, $17, $8B, $F0, $8B, $46, $FA, $A3, $AE, $0F, $83, $FE, $FF
	db $75, $14, $6A, $25, $90, $0E, $E8, $94, $3F, $83, $C4, $02, $52, $50, $90, $0E
	db $E8, $B7, $B8, $83, $C4, $04, $FF, $0E, $6A, $10, $FF, $76, $FE, $FF, $76, $FC
	db $1E, $68, $6E, $0E, $90, $0E, $E8, $DE, $99, $83, $C4, $08, $66, $83, $3E, $6E
	db $0E, $00, $74, $1D, $C4, $1E, $6E, $0E, $26, $8B, $07, $3B, $06, $2A, $0E, $74
	db $10, $FF, $36, $70, $0E, $FF, $36, $6E, $0E, $90, $0E, $E8, $1B, $9A, $83, $C4
	db $04, $FF, $76, $FE, $FF, $76, $FC, $90, $0E, $E8, $C9, $A4, $83, $C4, $04, $66
	db $83, $3E, $0E, $0E, $00, $74, $04, $FF, $1E, $0E, $0E, $83, $3E, $6A, $10, $00
	db $75, $57, $66, $C7, $06, $00, $5C, $00, $00, $00, $00, $66, $C7, $06, $04, $5C
	db $00, $00, $00, $00, $66, $C7, $06, $08, $5C, $00, $00, $00, $00, $66, $C7, $06
	db $0C, $5C, $00, $00, $00, $00, $66, $C7, $06, $10, $5C, $00, $00, $00, $00, $C7
	db $06, $46, $0E, $01, $00, $83, $FE, $01, $75, $1D, $66, $83, $3E, $6E, $0E, $00
	db $74, $15, $C4, $1E, $6E, $0E, $26, $83, $4F, $60, $04, $FF, $36, $3C, $22, $9A
	db $18, $3D, $FF, $30, $83, $C4, $02, $EB, $28, $66, $8B, $46, $F6, $66, $A3, $00
	db $5C, $66, $8B, $46, $F2, $66, $A3, $04, $5C, $66, $8B, $46, $EE, $66, $A3, $08
	db $5C, $66, $8B, $46, $EA, $66, $A3, $0C, $5C, $66, $8B, $46, $E6, $66, $A3, $10
	db $5C, $8B, $C6, $5E, $C9, $4D, $CB, $5E, $C9, $4D, $CB, $45, $55, $8B, $EC, $83
	db $EC, $04, $56, $57, $8B, $76, $0C, $33, $FF, $FF, $76, $0A, $FF, $76, $08, $FF
	db $76, $06, $90, $0E, $E8, $2C, $0B, $83, $C4, $06, $89, $56, $FE, $89, $46, $FC
	db $66, $83, $7E, $FC, $00, $0F, $84, $C9, $01, $C4, $5E, $FC, $26, $8B, $5F, $02
	db $83, $FB, $40, $74, $60, $7F, $4D, $83, $FB, $16, $0F, $84, $DB, $00, $7F, $11
	db $83, $EB, $0A, $83, $FB, $0B, $0F, $87, $71, $01, $03, $DB, $2E, $FF, $A7, $24
	db $C6, $83, $FB, $37, $0F, $84, $C1, $00, $7F, $18, $83, $FB, $1E, $0F, $84, $B8
	db $00, $83, $FB, $29, $0F, $84, $FA, $00, $83, $FB, $32, $0F, $84, $AA, $00, $E9
	db $49, $01, $83, $FB, $3D, $74, $1E, $83, $FB, $3E, $74, $19, $83, $FB, $3F, $74
	db $14, $E9, $37, $01, $83, $EB, $41, $83, $FB, $25, $0F, $87, $2D, $01, $03, $DB
	db $2E, $FF, $A7, $D8, $C5, $C4, $5E, $FC, $26, $C4, $5F, $0A, $26, $8B, $47, $04
	db $3D, $04, $00, $74, $02, $EB, $39, $C4, $5E, $FC, $26, $C4, $5F, $0A, $66, $26
	db $FF, $77, $0A, $C4, $5E, $FC, $26, $C4, $5F, $0A, $66, $26, $FF, $77, $06, $66
	db $0F, $BF, $C6, $66, $50, $9A, $8E, $78, $FF, $30, $83, $C4, $0C, $8B, $F0, $66
	db $0F, $B7, $C6, $C4, $5E, $FC, $26, $C4, $5F, $0A, $66, $26, $89, $07, $EB, $36
	db $C4, $5E, $FC, $26, $C4, $5F, $0A, $66, $26, $FF, $77, $0A, $C4, $5E, $FC, $26
	db $C4, $5F, $0A, $66, $26, $FF, $77, $06, $66, $0F, $BF, $C6, $66, $50, $9A, $8E
	db $78, $FF, $30, $83, $C4, $0C, $C4, $5E, $FC, $26, $C4, $5F, $0A, $26, $89, $57
	db $02, $26, $89, $07, $EB, $00, $E9, $A2, $00, $0B, $F6, $74, $05, $B8, $FE, $FF
	db $EB, $03, $B8, $FB, $FF, $C4, $5E, $FC, $26, $21, $47, $08, $0B, $F6, $74, $05
	db $B8, $04, $00, $EB, $03, $B8, $01, $00, $C4, $5E, $FC, $26, $09, $47, $08, $EB
	db $7A, $C4, $5E, $FC, $26, $89, $77, $08, $EB, $71, $C4, $5E, $FC, $26, $C4, $5F
	db $0A, $26, $89, $37, $EB, $65, $C4, $5E, $FC, $26, $C4, $5F, $0A, $26, $89, $37
	db $EB, $59, $C7, $06, $6E, $10, $01, $00, $C4, $5E, $06, $26, $FF, $37, $C4, $5E
	db $FC, $26, $FF, $37, $C4, $5E, $FC, $26, $FF, $77, $06, $26, $FF, $77, $04, $EB
	db $25, $5F, $5E, $C9, $4D, $CB, $C7, $06, $6E, $10, $01, $00, $C4, $5E, $06, $26
	db $FF, $37, $C4, $5E, $FC, $26, $FF, $37, $C4, $5E, $FC, $26, $C4, $5F, $0A, $26
	db $FF, $77, $02, $26, $FF, $37, $9A, $63, $44, $4F, $17, $C7, $06, $6E, $10, $00
	db $00, $5F, $5E, $C9, $4D, $CB, $5F, $5E, $C9, $4D, $CB, $C4, $5E, $06, $26, $8B
	db $07, $3B, $06, $2E, $0E, $74, $0D, $8B, $3E, $2E, $0E, $C4, $5E, $06, $26, $8B
	db $07, $A3, $2E, $0E, $6A, $00, $FF, $76, $FE, $FF, $76, $FC, $C4, $5E, $06, $26
	db $FF, $37, $90, $0E, $E8, $70, $0C, $83, $C4, $08, $0B, $FF, $74, $04, $89, $3E
	db $2E, $0E, $5F, $5E, $C9, $4D, $CB, $67, $C5, $76, $C4, $9C, $C5, $9C, $C5, $9C
	db $C5, $9C, $C5, $9C, $C5, $9C, $C5, $9C, $C5, $9C, $C5, $9C, $C5, $9C, $C5, $9C
	db $C5, $9C, $C5, $9C, $C5, $2B, $C5, $2B, $C5, $2B, $C5, $2B, $C5, $37, $C5, $37
	db $C5, $37, $C5, $37, $C5, $2B, $C5, $2B, $C5, $9C, $C5, $9C, $C5, $9C, $C5, $9C
	db $C5, $9C, $C5, $9C, $C5, $9C, $C5, $9C, $C5, $9C, $C5, $9C, $C5, $9C, $C5, $76
	db $C4, $76, $C4, $FA, $C4, $FA, $C4, $FA, $C4, $FA, $C4, $FA, $C4, $9C, $C5, $9C
	db $C5, $9C, $C5, $9C, $C5, $9C, $C5, $22, $C5, $FA, $C4, $45, $55, $8B, $EC, $83
	db $EC, $04, $56, $33, $F6, $FF, $76, $0A, $FF, $76, $08, $FF, $76, $06, $90, $0E
	db $E8, $D0, $08, $83, $C4, $06, $89, $56, $FE, $89, $46, $FC, $66, $83, $7E, $FC
	db $00, $0F, $84, $85, $00, $C4, $5E, $FC, $26, $8B, $5F, $02, $83, $EB, $3D, $83
	db $FB, $05, $77, $3B, $03, $DB, $2E, $FF, $A7, $EF, $C6, $C4, $5E, $FC, $26, $C4
	db $5F, $0A, $66, $26, $FF, $77, $0A, $C4, $5E, $FC, $26, $C4, $5F, $0A, $66, $26
	db $FF, $77, $06, $66, $FF, $76, $0C, $9A, $8E, $78, $FF, $30, $83, $C4, $0C, $C4
	db $5E, $FC, $26, $C4, $5F, $0A, $26, $89, $57, $02, $26, $89, $07, $EB, $04, $5E
	db $C9, $4D, $CB, $C4, $5E, $06, $26, $8B, $07, $3B, $06, $2E, $0E, $74, $0D, $8B
	db $36, $2E, $0E, $C4, $5E, $06, $26, $8B, $07, $A3, $2E, $0E, $6A, $00, $FF, $76
	db $FE, $FF, $76, $FC, $C4, $5E, $06, $26, $FF, $37, $90, $0E, $E8, $58, $0B, $83
	db $C4, $08, $0B, $F6, $74, $04, $89, $36, $2E, $0E, $5E, $C9, $4D, $CB, $7C, $C6
	db $7C, $C6, $7C, $C6, $7C, $C6, $B0, $C6, $7C, $C6, $45, $55, $8B, $EC, $83, $EC
	db $04, $FF, $76, $0A, $FF, $76, $08, $FF, $76, $06, $90, $0E, $E8, $14, $08, $83
	db $C4, $06, $89, $56, $FE, $89, $46, $FC, $66, $83, $7E, $FC, $00, $74, $43, $C4
	db $5E, $FC, $26, $C4, $5F, $0A, $66, $8B, $46, $0C, $66, $26, $89, $07, $C4, $5E
	db $FC, $26, $C4, $5F, $0A, $26, $FF, $77, $04, $C4, $5E, $FC, $26, $FF, $37, $FF
	db $76, $08, $FF, $76, $06, $90, $0E, $E8, $BA, $10, $83, $C4, $08, $6A, $00, $C4
	db $5E, $FC, $26, $FF, $37, $FF, $76, $08, $FF, $76, $06, $0E, $E8, $7C, $FC, $83
	db $C4, $08, $C9, $4D, $CB, $45, $55, $8B, $EC, $83, $EC, $04, $FF, $76, $0A, $FF
	db $76, $08, $FF, $76, $06, $90, $0E, $E8, $A9, $07, $83, $C4, $06, $89, $56, $FE
	db $89, $46, $FC, $66, $83, $7E, $FC, $00, $0F, $84, $CD, $00, $C4, $5E, $FC, $26
	db $8B, $5F, $02, $83, $FB, $40, $74, $4E, $7F, $3D, $83, $FB, $15, $74, $6E, $7F
	db $11, $83, $EB, $0A, $83, $FB, $0A, $0F, $87, $A4, $00, $03, $DB, $2E, $FF, $A7
	db $94, $C8, $83, $FB, $3D, $74, $2F, $7F, $12, $83, $FB, $16, $74, $4F, $83, $FB
	db $1E, $74, $4A, $83, $FB, $32, $74, $45, $E9, $84, $00, $83, $FB, $3E, $74, $16
	db $83, $FB, $3F, $74, $11, $EB, $78, $83, $EB, $41, $83, $FB, $18, $77, $70, $03
	db $DB, $2E, $FF, $A7, $62, $C8, $C4, $5E, $FC, $26, $C4, $5F, $0A, $26, $8B, $07
	db $C9, $4D, $CB, $C4, $5E, $FC, $26, $C4, $5F, $0A, $26, $8B, $07, $C9, $4D, $CB
	db $C4, $5E, $FC, $26, $C4, $5F, $0A, $26, $8B, $07, $C9, $4D, $CB, $C4, $5E, $FC
	db $26, $F6, $47, $08, $04, $74, $04, $EB, $30, $EB, $02, $EB, $3C, $C4, $5E, $06
	db $26, $FF, $37, $C4, $5E, $FC, $26, $FF, $37, $C4, $5E, $FC, $26, $C4, $5F, $0A
	db $26, $FF, $77, $02, $26, $FF, $37, $C4, $5E, $FC, $26, $C4, $5F, $0A, $26, $8B
	db $47, $04, $40, $50, $9A, $10, $44, $4F, $17, $B8, $01, $00, $C9, $4D, $CB, $C4
	db $5E, $FC, $26, $8B, $47, $08, $C9, $4D, $CB, $33, $C0, $C9, $4D, $CB, $C9, $4D
	db $CB, $1E, $C8, $E7, $C7, $50, $C8, $50, $C8, $50, $C8, $50, $C8, $50, $C8, $50
	db $C8, $50, $C8, $50, $C8, $50, $C8, $50, $C8, $50, $C8, $50, $C8, $50, $C8, $F4
	db $C7, $F4, $C7, $F4, $C7, $F4, $C7, $01, $C8, $01, $C8, $01, $C8, $01, $C8, $F4
	db $C7, $F4, $C7, $0E, $C8, $0E, $C8, $0E, $C8, $0E, $C8, $0E, $C8, $50, $C8, $50
	db $C8, $50, $C8, $50, $C8, $50, $C8, $50, $C8, $45, $55, $8B, $EC, $83, $EC, $04
	db $FF, $76, $0A, $FF, $76, $08, $FF, $76, $06, $90, $0E, $E8, $65, $06, $83, $C4
	db $06, $89, $56, $FE, $89, $46, $FC, $66, $83, $7E, $FC, $00, $74, $27, $C4, $5E
	db $FC, $26, $8B, $5F, $02, $83, $EB, $3D, $83, $FB, $05, $77, $18, $03, $DB, $2E
	db $FF, $A7, $00, $C9, $C4, $5E, $FC, $26, $C4, $5F, $0A, $26, $8B, $57, $02, $26
	db $8B, $07, $C9, $4D, $CB, $33, $D2, $33, $C0, $C9, $4D, $CB, $C9, $4D, $CB, $E5
	db $C8, $E5, $C8, $E5, $C8, $E5, $C8, $F6, $C8, $E5, $C8, $45, $55, $8B, $EC, $83
	db $EC, $04, $56, $8B, $76, $0E, $66, $8B, $46, $0A, $66, $89, $46, $FC, $EB, $1B
	db $56, $C4, $5E, $FC, $26, $8A, $07, $B4, $00, $50, $FF, $76, $08, $FF, $76, $06
	db $90, $0E, $E8, $5D, $00, $83, $C4, $08, $FF, $46, $FC, $C4, $5E, $FC, $26, $80
	db $3F, $00, $75, $DC, $5E, $C9, $4D, $CB, $45, $55, $8B, $EC, $83, $EC, $04, $66
	db $8B, $46, $0C, $66, $89, $46, $FC, $EB, $1B, $6A, $00, $C4, $5E, $FC, $26, $8A
	db $07, $B4, $00, $50, $FF, $76, $08, $FF, $76, $06, $0E, $E8, $6D, $FA, $83, $C4
	db $08, $FF, $46, $FC, $C4, $5E, $FC, $26, $80, $3F, $00, $75, $DC, $6A, $01, $FF
	db $76, $0A, $FF, $76, $08, $FF, $76, $06, $0E, $E8, $4F, $FA, $83, $C4, $08, $C9
	db $4D, $CB, $45, $55, $8B, $EC, $83, $EC, $04, $56, $57, $8B, $76, $0C, $FF, $76
	db $0A, $FF, $76, $08, $FF, $76, $06, $90, $0E, $E8, $77, $05, $83, $C4, $06, $89
	db $56, $FE, $89, $46, $FC, $66, $83, $7E, $FC, $00, $0F, $84, $CD, $00, $C4, $5E
	db $06, $26, $FF, $37, $C4, $5E, $FC, $26, $FF, $37, $9A, $01, $44, $4F, $17, $8B
	db $F8, $0B, $FF, $0F, $84, $B4, $00, $57, $56, $9A, $66, $0F, $6F, $17, $C4, $5E
	db $FC, $26, $8B, $47, $02, $3D, $32, $00, $74, $02, $EB, $2E, $0B, $F6, $74, $0A
	db $C4, $5E, $FC, $26, $83, $67, $08, $F7, $EB, $08, $C4, $5E, $FC, $26, $83, $4F
	db $08, $08, $6A, $00, $FF, $76, $FE, $FF, $76, $FC, $C4, $5E, $06, $26, $FF, $37
	db $90, $0E, $E8, $22, $08, $83, $C4, $08, $EB, $62, $0B, $F6, $74, $12, $C4, $5E
	db $FC, $26, $83, $67, $08, $F7, $C4, $5E, $FC, $26, $83, $4F, $08, $01, $EB, $10
	db $C4, $5E, $FC, $26, $83, $67, $08, $FE, $C4, $5E, $FC, $26, $83, $4F, $08, $08
	db $C4, $5E, $FC, $26, $83, $7F, $02, $37, $74, $08, $C4, $5E, $FC, $26, $83, $4F
	db $08, $04, $6A, $00, $FF, $76, $FE, $FF, $76, $FC, $C4, $5E, $06, $26, $FF, $37
	db $90, $0E, $E8, $D2, $07, $83, $C4, $08, $C4, $5E, $FC, $26, $83, $7F, $02, $37
	db $74, $08, $C4, $5E, $FC, $26, $83, $67, $08, $FB, $EB, $00, $C4, $5E, $FC, $26
	db $8B, $47, $08, $25, $01, $00, $5F, $5E, $C9, $4D, $CB, $B8, $FF, $FF, $5F, $5E
	db $C9, $4D, $CB, $5F, $5E, $C9, $4D, $CB, $45, $55, $8B, $EC, $83, $EC, $04, $FF
	db $76, $0A, $FF, $76, $08, $FF, $76, $06, $90, $0E, $E8, $76, $04, $83, $C4, $06
	db $89, $56, $FE, $89, $46, $FC, $66, $83, $7E, $FC, $00, $74, $11, $C4, $5E, $FC
	db $26, $8B, $47, $08, $25, $08, $00, $F7, $D8, $1B, $C0, $40, $EB, $02, $33, $C0
	db $C9, $4D, $CB, $C9, $4D, $CB, $45, $55, $8B, $EC, $83, $EC, $04, $56, $8B, $76
	db $0C, $FF, $76, $0A, $FF, $76, $08, $FF, $76, $06, $90, $0E, $E8, $34, $04, $83
	db $C4, $06, $89, $56, $FE, $89, $46, $FC, $66, $83, $7E, $FC, $00, $74, $58, $C4
	db $5E, $06, $26, $FF, $37, $C4, $5E, $FC, $26, $FF, $37, $9A, $01, $44, $4F, $17
	db $50, $0B, $F6, $74, $05, $B8, $05, $00, $EB, $02, $33, $C0, $50, $9A, $1E, $15
	db $27, $17, $0B, $F6, $74, $0B, $C4, $5E, $FC, $26, $81, $67, $08, $FF, $DF, $EB
	db $09, $C4, $5E, $FC, $26, $81, $4F, $08, $00, $20, $83, $3E, $70, $10, $00, $74
	db $16, $6A, $00, $FF, $76, $FE, $FF, $76, $FC, $C4, $5E, $06, $26, $FF, $37, $90
	db $0E, $E8, $E3, $06, $83, $C4, $08, $5E, $C9, $4D, $CB, $45, $55, $8B, $EC, $83
	db $EC, $04, $FF, $76, $0A, $FF, $76, $08, $FF, $76, $06, $90, $0E, $E8, $B3, $03
	db $83, $C4, $06, $89, $56, $FE, $89, $46, $FC, $66, $83, $7E, $FC, $00, $74, $6A
	db $C4, $5E, $FC, $26, $8B, $47, $02, $3D, $3E, $00, $74, $2D, $7F, $1A, $3D, $14
	db $00, $74, $26, $7F, $0C, $3D, $10, $00, $74, $1F, $3D, $13, $00, $74, $1A, $EB
	db $30, $3D, $3D, $00, $74, $13, $EB, $29, $3D, $3F, $00, $74, $0C, $3D, $42, $00
	db $74, $07, $3D, $46, $00, $74, $02, $EB, $18, $FF, $76, $0C, $90, $0E, $E8, $C2
	db $11, $83, $C4, $02, $C4, $5E, $FC, $26, $89, $57, $06, $26, $89, $47, $04, $EB
	db $03, $C9, $4D, $CB, $6A, $00, $FF, $76, $FE, $FF, $76, $FC, $C4, $5E, $06, $26
	db $FF, $37, $90, $0E, $E8, $50, $06, $83, $C4, $08, $C9, $4D, $CB, $45, $55, $8B
	db $EC, $83, $EC, $04, $FF, $76, $0A, $FF, $76, $08, $FF, $76, $06, $90, $0E, $E8
	db $21, $03, $83, $C4, $06, $89, $56, $FE, $89, $46, $FC, $66, $83, $7E, $FC, $00
	db $74, $20, $C4, $5E, $FC, $26, $83, $7F, $02, $14, $75, $16, $FF, $76, $0E, $FF
	db $76, $0C, $C4, $5E, $FC, $26, $FF, $77, $06, $26, $FF, $77, $04, $9A, $F2, $A9
	db $2F, $01, $C9, $4D, $CB, $C9, $4D, $CB, $45, $55, $8B, $EC, $83, $EC, $04, $56
	db $8B, $76, $0C, $FF, $76, $0A, $FF, $76, $08, $FF, $76, $06, $90, $0E, $E8, $D2
	db $02, $83, $C4, $06, $89, $56, $FE, $89, $46, $FC, $66, $83, $7E, $FC, $00, $74
	db $69, $C4, $5E, $FC, $26, $8B, $5F, $02, $83, $EB, $3D, $83, $FB, $1C, $77, $5A
	db $03, $DB, $2E, $FF, $A7, $D3, $CC, $66, $0F, $BF, $C6, $C4, $5E, $FC, $26, $C4
	db $5F, $0A, $66, $26, $89, $47, $0A, $66, $0F, $BF, $C6, $66, $50, $C4, $5E, $FC
	db $26, $C4, $5F, $0A, $66, $26, $FF, $37, $90, $0E, $E8, $E0, $BD, $83, $C4, $08
	db $C4, $5E, $FC, $26, $C4, $5F, $0A, $26, $89, $57, $02, $26, $89, $07, $EB, $1A
	db $C4, $5E, $FC, $26, $C4, $5F, $0A, $26, $89, $77, $02, $EB, $0D, $C4, $5E, $FC
	db $26, $C4, $5F, $0A, $26, $89, $77, $02, $EB, $00, $5E, $C9, $4D, $CB, $5E, $C9
	db $4D, $CB, $78, $CC, $78, $CC, $78, $CC, $78, $CC, $CB, $CC, $78, $CC, $CB, $CC
	db $CB, $CC, $CB, $CC, $CB, $CC, $CB, $CC, $CB, $CC, $CB, $CC, $CB, $CC, $CB, $CC
	db $CB, $CC, $CB, $CC, $CB, $CC, $CB, $CC, $B1, $CC, $B1, $CC, $B1, $CC, $B1, $CC
	db $BE, $CC, $BE, $CC, $BE, $CC, $BE, $CC, $B1, $CC, $B1, $CC, $45, $55, $8B, $EC
	db $83, $EC, $04, $56, $8B, $76, $0C, $FF, $76, $0A, $FF, $76, $08, $FF, $76, $06
	db $90, $0E, $E8, $FE, $01, $83, $C4, $06, $89, $56, $FE, $89, $46, $FC, $66, $83
	db $7E, $FC, $00, $74, $4F, $C4, $5E, $FC, $26, $8B, $5F, $02, $83, $EB, $3D, $83
	db $FB, $05, $77, $40, $03, $DB, $2E, $FF, $A7, $8D, $CD, $66, $0F, $BF, $C6, $C4
	db $5E, $FC, $26, $C4, $5F, $0A, $66, $26, $89, $47, $06, $66, $0F, $BF, $C6, $66
	db $50, $C4, $5E, $FC, $26, $C4, $5F, $0A, $66, $26, $FF, $37, $90, $0E, $E8, $36
	db $BD, $83, $C4, $08, $C4, $5E, $FC, $26, $C4, $5F, $0A, $26, $89, $57, $02, $26
	db $89, $07, $EB, $00, $5E, $C9, $4D, $CB, $5E, $C9, $4D, $CB, $4C, $CD, $4C, $CD
	db $4C, $CD, $4C, $CD, $85, $CD, $4C, $CD, $45, $55, $8B, $EC, $83, $EC, $08, $56
	db $C4, $5E, $06, $26, $FF, $37, $FF, $76, $0A, $9A, $01, $44, $4F, $17, $8B, $F0
	db $56, $16, $8D, $46, $F8, $50, $9A, $53, $10, $6F, $17, $C4, $5E, $0C, $8B, $46
	db $F8, $26, $89, $07, $C4, $5E, $0C, $8B, $46, $FA, $26, $89, $47, $02, $C4, $5E
	db $0C, $8B, $46, $FC, $26, $89, $47, $04, $C4, $5E, $0C, $8B, $46, $FE, $26, $89
	db $47, $06, $FF, $76, $0E, $FF, $76, $0C, $C4, $5E, $06, $26, $FF, $37, $56, $9A
	db $9F, $25, $1F, $30, $83, $C4, $08, $5E, $C9, $4D, $CB, $45, $55, $8B, $EC, $C4
	db $5E, $06, $26, $FF, $37, $FF, $76, $0A, $9A, $01, $44, $4F, $17, $50, $C4, $5E
	db $0C, $26, $FF, $37, $C4, $5E, $0C, $26, $FF, $77, $02, $C4, $5E, $0C, $26, $FF
	db $77, $04, $C4, $5E, $0C, $26, $FF, $77, $06, $6A, $01, $9A, $1C, $00, $47, $17
	db $5D, $4D, $CB, $45, $55, $8B, $EC, $66, $83, $7E, $06, $00, $74, $2B, $C4, $5E
	db $06, $26, $FF, $37, $6A, $00, $C4, $5E, $06, $26, $FF, $77, $20, $C4, $5E, $06
	db $26, $FF, $77, $22, $C4, $5E, $06, $26, $FF, $77, $24, $C4, $5E, $06, $26, $FF
	db $77, $26, $6A, $24, $9A, $45, $00, $47, $17, $5D, $4D, $CB, $45, $55, $8B, $EC
	db $83, $EC, $08, $16, $8D, $46, $F8, $50, $FF, $76, $0A, $FF, $76, $08, $FF, $76
	db $06, $0E, $E8, $13, $FF, $83, $C4, $0A, $C4, $5E, $0C, $8B, $46, $F8, $26, $89
	db $07, $C4, $5E, $10, $8B, $46, $FA, $26, $89, $07, $C9, $4D, $CB, $45, $55, $8B
	db $EC, $83, $EC, $08, $C4, $5E, $06, $26, $FF, $37, $FF, $76, $0A, $9A, $01, $44
	db $4F, $17, $50, $16, $8D, $46, $F8, $50, $9A, $53, $10, $6F, $17, $C4, $5E, $EB
	db $1C, $83, $FF, $03, $75, $15, $FF, $76, $08, $FF, $76, $06, $16, $8D, $46, $DE
	db $50, $90, $0E, $E8, $D8, $06, $83, $C4, $08, $EB, $02, $EB, $12, $9A, $71, $22
	db $1F, $30, $16, $8D, $46, $DE, $50, $90, $0E, $E8, $D4, $01, $83, $C4, $04, $6A
	db $0A, $90, $0E, $E8, $37, $D4, $83, $C4, $02, $C4, $5E, $06, $66, $26, $8B, $47
	db $0A, $66, $89, $46, $F6, $8B, $DF, $83, $EB, $02, $83, $FB, $03, $77, $4F, $03
	db $DB, $2E, $FF, $A7, $BB, $AF, $C4, $5E, $06, $66, $26, $8B, $47, $1A, $C4, $5E
	db $06, $66, $26, $29, $47, $0A, $EB, $3B, $C4, $5E, $06, $66, $26, $8B, $47, $1A
	db $C4, $5E, $06, $66, $26, $01, $47, $0A, $EB, $29, $C4, $5E, $06, $66, $26, $8B
	db $47, $1E, $C4, $5E, $06, $66, $26, $29, $47, $0A, $EB, $17, $C4, $5E, $06, $66
	db $26, $8B, $47, $1E, $C4, $5E, $06, $66, $26, $01, $47, $0A, $EB, $05, $5F, $5E
	db $C9, $4D, $CB, $FF, $76, $08, $FF, $76, $06, $90, $0E, $E8, $07, $07, $83, $C4
	db $04, $C4, $5E, $06, $66, $26, $8B, $47, $0A, $66, $3B, $46, $F6, $74, $0E, $FF
	db $76, $08, $FF, $76, $06, $90, $0E, $E8, $67, $01, $83, $C4, $04, $90, $0E, $E8
	db $19, $D4, $0B, $C0, $0F, $85, $61, $FF, $83, $FF, $02, $74, $05, $83, $FF, $03
	db $75, $12, $9A, $71, $22, $1F, $30, $16, $8D, $46, $DE, $50, $90, $0E, $E8, $0F
	db $01, $83, $C4, $04, $5F, $5E, $C9, $4D, $CB, $00, $17, $AF, $29, $AF, $3B, $AF
	db $4D, $AF, $45, $55, $8B, $EC, $83, $EC, $10, $56, $57, $8B, $7E, $0A, $83, $FF
	db $0A, $74, $05, $83, $FF, $0B, $75, $05, $B8, $01, $00, $EB, $03, $B8, $02, $00
	db $8B, $F0, $FF, $76, $08, $FF, $76, $06, $16, $8D, $46, $F8, $50, $90, $0E, $E8
	db $BC, $05, $83, $C4, $08, $C4, $5E, $06, $26, $F6, $47, $08, $01, $74, $12, $8B
	db $C6, $6B, $C0, $0D, $01, $46, $F8, $8B, $C6, $6B, $C0, $0D, $01, $46, $FC, $EB
	db $10, $8B, $C6, $6B, $C0, $0D, $01, $46, $FA, $8B, $C6, $6B, $C0, $0D, $01, $46
	db $FE, $16, $8D, $46, $F0, $50, $9A, $7A, $20, $1F, $30, $83, $C4, $04, $16, $8D
	db $46, $F8, $50, $9A, $C8, $1F, $1F, $30, $83, $C4, $04, $6A, $00, $9A, $1F, $1F
	db $1F, $30, $83, $C4, $02, $FF, $76, $FA, $FF, $76, $F8, $83, $FE, $01, $75, $05
	db $B8, $05, $00, $EB, $03, $B8, $04, $00, $03, $C0, $8B, $D8, $8B, $87, $CE, $5B
	db $99, $52, $50, $9A, $E6, $2D, $1F, $30, $83, $C4, $08, $83, $FF, $0A, $74, $05
	db $83, $FF, $0C, $75, $23, $16, $8D, $46, $F8, $50, $90, $0E, $E8, $41, $00, $83
	db $C4, $04, $83, $FE, $01, $75, $05, $B8, $40, $00, $EB, $03, $B8, $80, $00, $C4
	db $5E, $06, $26, $09, $47, $08, $EB, $16, $83, $FE, $01, $75, $05, $B8, $40, $00
	db $EB, $03, $B8, $80, $00, $F7, $D0, $C4, $5E, $06, $26, $21, $47, $08, $16, $8D
	db $46, $F0, $50, $9A, $C8, $1F, $1F, $30, $83, $C4, $04, $5F, $5E, $C9, $4D, $CB
	db $45, $55, $8B, $EC, $C4, $5E, $06, $26, $FF, $4F, $04, $C4, $5E, $06, $26, $FF
	db $4F, $06, $FF, $76, $08, $FF, $76, $06, $9A, $CB, $11, $1F, $30, $83, $C4, $04
	db $C4, $5E, $06, $26, $FF, $47, $04, $C4, $5E, $06, $26, $FF, $47, $06, $5D, $4D
	db $CB, $45, $55, $8B, $EC, $C4, $5E, $06, $66, $26, $83, $7F, $22, $00, $74, $22
	db $FF, $76, $08, $FF, $76, $06, $C4, $5E, $06, $26, $FF, $5F, $22, $83, $C4, $04
	db $0B, $C2, $74, $0E, $FF, $76, $08, $FF, $76, $06, $90, $0E, $E8, $06, $00, $83
	db $C4, $04, $5D, $4D, $CB, $45, $55, $8B, $EC, $83, $EC, $08, $FF, $76, $08, $FF
	db $76, $06, $16, $8D, $46, $F8, $50, $90, $0E, $E8, $4D, $03, $83, $C4, $08, $6A
	db $01, $16, $8D, $46, $F8, $50, $9A, $14, $12, $1F, $30, $83, $C4, $06, $16, $8D
	db $46, $F8, $50, $9A, $C8, $1F, $1F, $30, $83, $C4, $04, $FF, $76, $08, $FF, $76
	db $06, $0E, $E8, $6B, $F6, $83, $C4, $04, $9A, $71, $22, $1F, $30, $C9, $4D, $CB
	db $45, $55, $8B, $EC, $83, $EC, $1A, $56, $57, $C4, $5E, $06, $26, $F6, $47, $08
	db $04, $74, $13, $C4, $5E, $06, $66, $26, $81, $7F, $16, $E8, $03, $00, $00, $7D
	db $05, $B8, $FF, $FF, $EB, $02, $33, $C0, $89, $46, $E6, $8B, $46, $0A, $8B, $F0
	db $66, $8B, $46, $0A, $66, $C1, $F8, $10, $8B, $F8, $FF, $76, $08, $FF, $76, $06
	db $57, $56, $9A, $AC, $22, $1F, $30, $83, $C4, $08, $0B, $C0, $75, $03, $E9, $44
	db $01, $FF, $76, $08, $FF, $76, $06, $16, $8D, $46, $E8, $50, $90, $0E, $E8, $40
	db $01, $83, $C4, $08, $16, $8D, $46, $E8, $50, $57, $56, $9A, $AC, $22, $1F, $30
	db $83, $C4, $08, $0B, $C0, $74, $08, $B8, $01, $00, $5F, $5E, $C9, $4D, $CB, $FF
	db $76, $08, $FF, $76, $06, $16, $8D, $46, $F8, $50, $90, $0E, $E8, $42, $03, $83
	db $C4, $08, $16, $8D, $46, $F8, $50, $57, $56, $9A, $AC, $22, $1F, $30, $83, $C4
	db $08, $0B, $C0, $74, $0E, $83, $7E, $E6, $00, $74, $08, $B8, $02, $00, $5F, $5E
	db $C9, $4D, $CB, $FF, $76, $08, $FF, $76, $06, $16, $8D, $46, $F0, $50, $90, $0E
	db $E8, $7B, $03, $83, $C4, $08, $16, $8D, $46, $F0, $50, $57, $56, $9A, $AC, $22
	db $1F, $30, $83, $C4, $08, $0B, $C0, $74, $0E, $83, $7E, $E6, $00, $74, $08, $B8
	db $03, $00, $5F, $5E, $C9, $4D, $CB, $C4, $5E, $06, $26, $F6, $47, $08, $01, $74
	db $47, $3B, $76, $FC, $7E, $09, $3B, $76, $E8, $7D, $04, $EB, $45, $EB, $37, $3B
	db $76, $EC, $7E, $09, $3B, $76, $F0, $7D, $04, $EB, $4B, $EB, $29, $C4, $5E, $06
	db $26, $F6, $47, $08, $10, $74, $1F, $3B, $76, $F4, $7E, $0E, $8B, $46, $F4, $05
	db $0D, $00, $3B, $C6, $7E, $04, $EB, $51, $EB, $0C, $8B, $46, $F4, $05, $0D, $00
	db $3B, $C6, $7D, $02, $EB, $57, $EB, $5D, $3B, $7E, $FE, $7E, $0F, $3B, $7E, $EA
	db $7D, $0A, $B8, $04, $00, $5F, $5E, $C9, $4D, $CB, $EB, $49, $3B, $7E, $EE, $7E
	db $0F, $3B, $7E, $F2, $7D, $0A, $B8, $05, $00, $5F, $5E, $C9, $4D, $CB, $EB, $35
	db $C4, $5E, $06, $26, $F6, $47, $08, $10, $74, $2B, $3B, $7E, $F6, $7E, $14, $8B
	db $46, $F6, $05, $0D, $00, $3B, $C7, $7E, $0A, $B8, $06, $00, $5F, $5E, $C9, $4D
	db $CB, $EB, $12, $8B, $46, $F6, $05, $0D, $00, $3B, $C7, $7D, $08, $B8, $07, $00
	db $5F, $5E, $C9, $4D, $CB, $33, $C0, $5F, $5E, $C9, $4D, $CB, $5F, $5E, $C9, $4D
	db $CB, $45, $55, $8B, $EC, $83, $EC, $1C, $56, $FF, $76, $0C, $FF, $76, $0A, $16
	db $8D, $46, $EC, $50, $90, $0E, $E8, $18, $02, $83, $C4, $08, $FF, $76, $0C, $FF
	db $76, $0A, $16, $8D, $46, $E4, $50, $90, $0E, $E8, $72, $02, $83, $C4, $08, $C4
	db $5E, $0A, $26, $F6, $47, $08, $01, $74, $08, $8B, $46, $E4, $2B, $46, $F0, $EB
	db $06, $8B, $46, $E6, $2B, $46, $F2, $66, $98, $66, $89, $46, $FC, $C4, $5E, $0A
	db $66, $26, $81, $7F, $16, $E8, $03, $00, $00, $7C, $06, $66, $8B, $46, $FC, $EB
	db $06, $66, $B8, $13, $00, $00, $00, $66, $89, $46, $F8, $C4, $5E, $0A, $66, $26
	db $8B, $47, $12, $C4, $5E, $0A, $66, $26, $2B, $47, $0E, $75, $0A, $66, $C7, $46
	db $F4, $00, $00, $00, $00, $EB, $39, $C4, $5E, $0A, $66, $26, $8B, $47, $0A, $C4
	db $5E, $0A, $66, $26, $2B, $47, $0E, $66, $8B, $56, $FC, $66, $2B, $56, $F8, $66
	db $0F, $AF, $C2, $C4, $5E, $0A, $66, $26, $8B, $57, $12, $C4, $5E, $0A, $66, $26
	db $2B, $57, $0E, $66, $52, $66, $99, $66, $5B, $66, $F7, $FB, $66, $89, $46, $F4
	db $C4, $5E, $0A, $26, $F6, $47, $08, $01, $74, $57, $8B, $46, $F0, $03, $46, $F4
	db $C4, $5E, $06, $26, $89, $07, $C4, $5E, $06, $06, $C4, $76, $06, $26, $8B, $04
	db $03, $46, $F8, $07, $26, $89, $47, $04, $C4, $5E, $0A, $26, $8B, $47, $02, $40
	db $C4, $5E, $06, $26, $89, $47, $02, $C4, $5E, $0A, $26, $8B, $47, $06, $48, $C4
	db $5E, $06, $26, $89, $47, $06, $C4, $5E, $0A, $66, $26, $8B, $47, $0A, $C4, $5E
	db $0A, $66, $26, $3B, $47, $12, $75, $07, $C4, $5E, $06, $26, $83, $07, $02, $EB
	db $54, $C4, $5E, $06, $8B, $46, $F2, $03, $46, $F4, $26, $89, $47, $02, $C4, $5E
	db $06, $26, $8B, $47, $02, $03, $46, $F8, $C4, $5E, $06, $26, $89, $47, $06, $C4
	db $5E, $0A, $26, $8B, $07, $40, $C4, $5E, $06, $26, $89, $07, $C4, $5E, $0A, $26
	db $8B, $47, $04, $48, $C4, $5E, $06, $26, $89, $47, $04, $C4, $5E, $0A, $66, $26
	db $8B, $47, $0A, $C4, $5E, $0A, $66, $26, $3B, $47, $12, $75, $08, $C4, $5E, $06
	db $26, $83, $47, $02, $02, $5E, $C9, $4D, $CB, $45, $55, $8B, $EC, $56, $C4, $5E
	db $0A, $26, $F6, $47, $08, $01, $74, $53, $C4, $5E, $0A, $26, $8B, $07, $05, $0E
	db $00, $C4, $5E, $06, $26, $89, $07, $C4, $5E, $0A, $26, $8B, $47, $04, $05, $F2
	db $FF, $C4, $5E, $06, $26, $89, $47, $04, $C4, $5E, $0A, $26, $8B, $47, $02, $C4
	db $5E, $06, $26, $89, $47, $02, $C4, $5E, $06, $26, $8B, $47, $02, $05, $0E, $00
	db $C4, $5E, $06, $26, $89, $47, $06, $C4, $5E, $0A, $26, $F6, $47, $08, $10, $74
	db $08, $C4, $5E, $06, $26, $83, $6F, $04, $1A, $EB, $52, $C4, $5E, $0A, $26, $8B
	db $07, $C4, $5E, $06, $26, $89, $07, $C4, $5E, $06, $06, $C4, $76, $06, $26, $8B
	db $04, $05, $0E, $00, $07, $26, $89, $47, $04, $C4, $5E, $0A, $26, $8B, $47, $02
	db $05, $0E, $00, $C4, $5E, $06, $26, $89, $47, $02, $C4, $5E, $0A, $26, $8B, $47
	db $06, $05, $F2, $FF, $C4, $5E, $06, $26, $89, $47, $06, $C4, $5E, $0A, $26, $F6
	db $47, $08, $10, $74, $08, $C4, $5E, $06, $26, $83, $6F, $06, $1A, $5E, $5D, $4D
	db $CB, $45, $55, $8B, $EC, $56, $C4, $5E, $0A, $26, $F6, $47, $08, $01, $74, $19
	db $C4, $5E, $0A, $26, $8B, $07, $05, $02, $00, $C4, $5E, $06, $26, $89, $07, $C4
	db $5E, $0A, $26, $8B, $47, $02, $40, $EB, $17, $C4, $5E, $0A, $26, $8B, $07, $40
	db $C4, $5E, $06, $26, $89, $07, $C4, $5E, $0A, $26, $8B, $47, $02, $05, $02, $00
	db $C4, $5E, $06, $26, $89, $47, $02, $C4, $5E, $06, $06, $C4, $76, $06, $26, $8B
	db $04, $05, $0D, $00, $07, $26, $89, $47, $04, $C4, $5E, $06, $26, $8B, $47, $02
	db $05, $0D, $00, $C4, $5E, $06, $26, $89, $47, $06, $5E, $5D, $4D, $CB, $45, $55
	db $8B, $EC, $56, $C4, $5E, $0A, $26, $F6, $47, $08, $01, $74, $32, $C4, $5E, $0A
	db $26, $8B, $47, $04, $05, $F2, $FF, $C4, $5E, $06, $26, $89, $07, $C4, $5E, $0A
	db $26, $8B, $47, $02, $40, $C4, $5E, $06, $26, $89, $47, $02, $C4, $5E, $0A, $26
	db $F6, $47, $08, $10, $74, $07, $C4, $5E, $06, $26, $83, $2F, $1A, $EB, $30, $C4
	db $5E, $0A, $26, $8B, $07, $40, $C4, $5E, $06, $26, $89, $07, $C4, $5E, $0A, $26
	db $8B, $47, $06, $05, $F2, $FF, $C4, $5E, $06, $26, $89, $47, $02, $C4, $5E, $0A
	db $26, $F6, $47, $08, $10, $74, $08, $C4, $5E, $06, $26, $83, $6F, $02, $1A, $C4
	db $5E, $06, $06, $C4, $76, $06, $26, $8B, $04, $05, $0D, $00, $07, $26, $89, $47
	db $04, $C4, $5E, $06, $26, $8B, $47, $02, $05, $0D, $00, $C4, $5E, $06, $26, $89
	db $47, $06, $5E, $5D, $4D, $CB, $45, $55, $8B, $EC, $C4, $5E, $06, $26, $8B, $47
	db $04, $C4, $5E, $06, $26, $2B, $07, $5D, $4D, $CB, $5D, $4D, $CB, $45, $55, $8B
	db $EC, $C4, $5E, $06, $26, $8B, $47, $06, $C4, $5E, $06, $26, $2B, $47, $02, $5D
	db $4D, $CB, $5D, $4D, $CB, $45, $55, $8B, $EC, $C4, $5E, $06, $66, $26, $FF, $77
	db $12, $C4, $5E, $06, $66, $26, $FF, $77, $0E, $C4, $5E, $06, $66, $26, $FF, $77
	db $0A, $9A, $8E, $78, $FF, $30, $83, $C4, $0C, $C4, $5E, $06, $26, $89, $57, $0C
	db $26, $89, $47, $0A, $5D, $4D, $CB, $45, $55, $8B, $EC, $83, $7E, $06, $00, $74
	db $05, $B8, $01, $00, $EB, $02, $33, $C0, $A3, $70, $10, $A1, $70, $10, $F7, $D8
	db $1B, $C0, $40, $5D, $4D, $CB, $5D, $4D, $CB, $45, $55, $8B, $EC, $83, $EC, $08
	db $56, $57, $8B, $7E, $0A, $A1, $72, $5B, $89, $46, $FC, $A1, $74, $5B, $89, $46
	db $FE, $66, $83, $3E, $10, $5C, $00, $74, $10, $57, $FF, $76, $08, $FF, $76, $06
	db $FF, $1E, $10, $5C, $83, $C4, $06, $8B, $F8, $8B, $DF, $83, $FB, $0B, $0F, $87
	db $2F, $02, $03, $DB, $2E, $FF, $A7, $3F, $B9, $FF, $76, $08, $FF, $76, $06, $90
	db $0E, $E8, $42, $02, $83, $C4, $04, $5F, $5E, $C9, $4D, $CB, $BE, $01, $00, $C7
	db $06, $70, $10, $00, $00, $90, $0E, $E8, $FC, $03, $66, $83, $3E, $00, $5C, $00
	db $74, $0F, $FF, $76, $08, $FF, $76, $06, $FF, $1E, $00, $5C, $83, $C4, $04, $8B
	db $F0, $0B, $F6, $74, $37, $83, $3E, $F0, $0D, $00, $75, $22, $FF, $76, $08, $FF
	db $76, $06, $90, $0E, $E8, $DB, $20, $83, $C4, $04, $0B, $C0, $75, $10, $6A, $00
	db $FF, $76, $08, $FF, $76, $06, $90, $0E, $E8, $83, $A2, $83, $C4, $06, $FF, $76
	db $08, $FF, $76, $06, $90, $0E, $E8, $C5, $18, $83, $C4, $04, $FF, $36, $82, $9A
	db $9A, $C3, $2F, $1F, $30, $83, $C4, $02, $C7, $06, $70, $10, $01, $00, $8B, $C6
	db $5F, $5E, $C9, $4D, $CB, $A1, $76, $5B, $89, $46, $FA, $66, $83, $3E, $04, $5C
	db $00, $74, $0D, $FF, $76, $08, $FF, $76, $06, $FF, $1E, $04, $5C, $83, $C4, $04
	db $C4, $5E, $06, $26, $81, $4F, $60, $80, $00, $81, $3E, $76, $5B, $60, $F0, $75
	db $06, $C7, $06, $76, $5B, $02, $00, $C4, $5E, $06, $26, $FF, $37, $FF, $76, $FA
	db $9A, $CA, $43, $4F, $17, $83, $3E, $F0, $0D, $00, $75, $06, $C7, $06, $AE, $0F
	db $00, $00, $90, $0E, $E8, $A5, $03, $B8, $01, $00, $5F, $5E, $C9, $4D, $CB, $C4
	db $5E, $06, $26, $8B, $77, $38, $83, $FE, $01, $7C, $3C, $83, $FE, $0A, $7D, $37
	db $83, $FE, $01, $7F, $0E, $83, $3E, $AE, $0F, $0A, $7D, $07, $83, $3E, $AE, $0F
	db $00, $75, $06, $89, $36, $76, $5B, $EB, $06, $A1, $AE, $0F, $A3, $76, $5B, $6A
	db $01, $FF, $76, $08, $FF, $76, $06, $90, $0E, $E8, $CE, $A5, $83, $C4, $06, $B8
	db $01, $00, $5F, $5E, $C9, $4D, $CB, $83, $3E, $6E, $10, $00, $74, $03, $E9, $E8
	db $00, $56, $FF, $76, $08, $FF, $76, $06, $90, $0E, $E8, $D6, $16, $83, $C4, $06
	db $89, $56, $FA, $89, $46, $F8, $66, $83, $7E, $F8, $00, $74, $2D, $FF, $76, $FA
	db $FF, $76, $F8, $FF, $76, $08, $FF, $76, $06, $90, $0E, $E8, $84, $03, $83, $C4
	db $08, $16, $8D, $46, $FC, $50, $FF, $76, $FA, $FF, $76, $F8, $FF, $76, $08, $FF
	db $76, $06, $90, $0E, $E8, $B5, $03, $83, $C4, $0C, $81, $FE, $0F, $27, $75, $12
	db $6A, $00, $90, $0E, $E8, $44, $48, $83, $C4, $02, $B8, $01, $00, $5F, $5E, $C9
	db $4D, $CB, $66, $83, $3E, $08, $5C, $00, $74, $24, $56, $FF, $76, $08, $FF, $76
	db $06, $FF, $1E, $08, $5C, $83, $C4, $06, $0B, $C0, $75, $12, $6A, $01, $FF, $76
	db $08, $FF, $76, $06, $90, $0E, $E8, $31, $A5, $83, $C4, $06, $EB, $63, $B8, $01
	db $00, $5F, $5E, $C9, $4D, $CB, $FF, $36, $44, $0E, $FF, $36, $42, $0E, $FF, $76
	db $08, $FF, $76, $06, $9A, $67, $A3, $FF, $30, $83, $C4, $08, $B8, $01, $00, $5F
	db $5E, $C9, $4D, $CB, $66, $83, $3E, $0C, $5C, $00, $74, $1A, $C4, $5E, $06, $26
	db $FF, $77, $38, $FF, $76, $08, $FF, $76, $06, $FF, $1E, $0C, $5C, $83, $C4, $06
	db $0B, $C0, $74, $02, $EB, $13, $FF, $76, $08, $FF, $76, $06, $90, $0E, $E8, $BD
	db $03, $83, $C4, $04, $5F, $5E, $C9, $4D, $CB, $B8, $01, $00, $5F, $5E, $C9, $4D
	db $CB, $33, $C0, $5F, $5E, $C9, $4D, $CB, $5F, $5E, $C9, $4D, $CB, $00, $1D, $B7
	db $96, $B7, $2A, $B9, $2A, $B9, $D7, $B8, $F0, $B7, $F5, $B8, $0A, $B7, $2A, $B9
	db $2A, $B9, $32, $B9, $2A, $B9, $45, $55, $8B, $EC, $83, $EC, $0A, $56, $57, $FF
	db $76, $08, $FF, $76, $06, $90, $0E, $E8, $5D, $16, $83, $C4, $04, $89, $56, $FA
	db $89, $46, $F8, $66, $83, $7E, $F8, $00, $0F, $84, $40, $01, $C4, $5E, $F8, $26
	db $F6, $47, $09, $08, $0F, $84, $34, $01, $9A, $29, $21, $FF, $25, $89, $56, $FE
	db $89, $46, $FC, $EB, $00, $9A, $29, $21, $FF, $25, $0B, $C2, $75, $F7, $66, $83
	db $7E, $FC, $00, $0F, $84, $15, $01, $C4, $5E, $F8, $26, $8B, $5F, $02, $83, $EB
	db $32, $83, $FB, $10, $0F, $87, $04, $01, $03, $DB, $2E, $FF, $A7, $05, $BB, $C4
	db $5E, $F8, $26, $C4, $5F, $0A, $26, $8B, $5F, $04, $4B, $83, $FB, $1C, $77, $40
	db $03, $DB, $2E, $FF, $A7, $CB, $BA, $8A, $46, $FD, $98, $69, $C0, $E8, $03, $8B
	db $F8, $EB, $35, $8A, $46, $FD, $98, $6B, $C0, $64, $8B, $F8, $EB, $2A, $8A, $46
	db $FC, $98, $25, $F0, $00, $3D, $90, $00, $75, $0C, $80, $7E, $FE, $00, $74, $06
	db $8A, $46, $FE, $98, $8B, $F8, $EB, $10, $8A, $46, $FD, $98, $8B, $F8, $EB, $08
	db $B8, $01, $00, $5F, $5E, $C9, $4D, $CB, $C4, $5E, $06, $06, $C4, $76, $F8, $26
	db $8B, $04, $07, $26, $89, $47, $38, $66, $83, $3E, $10, $5C, $00, $74, $0F, $6A
	db $05, $FF, $76, $08, $FF, $76, $06, $FF, $1E, $10, $5C, $83, $C4, $06, $57, $C4
	db $5E, $F8, $26, $FF, $37, $FF, $76, $08, $FF, $76, $06, $90, $0E, $E8, $8B, $09
	db $83, $C4, $08, $66, $83, $3E, $08, $5C, $00, $74, $37, $C4, $5E, $06, $26, $8B
	db $47, $38, $89, $46, $F6, $C4, $5E, $06, $06, $C4, $76, $F8, $26, $8B, $04, $07
	db $26, $89, $47, $38, $C4, $5E, $06, $26, $FF, $77, $38, $FF, $76, $08, $FF, $76
	db $06, $FF, $1E, $08, $5C, $83, $C4, $06, $C4, $5E, $06, $8B, $46, $F6, $26, $89
	db $47, $38, $EB, $28, $8A, $46, $FC, $98, $25, $F0, $00, $3D, $90, $00, $75, $1A
	db $80, $7E, $FE, $00, $74, $14, $C4, $5E, $F8, $26, $FF, $37, $FF, $76, $08, $FF
	db $76, $06, $90, $0E, $E8, $06, $19, $83, $C4, $06, $EB, $00, $B8, $01, $00, $5F
	db $5E, $C9, $4D, $CB, $5F, $5E, $C9, $4D, $CB, $00, $09, $BA, $09, $BA, $09, $BA
	db $09, $BA, $09, $BA, $11, $BA, $09, $BA, $EF, $B9, $11, $BA, $11, $BA, $11, $BA
	db $11, $BA, $11, $BA, $11, $BA, $11, $BA, $11, $BA, $11, $BA, $11, $BA, $11, $BA
	db $11, $BA, $D8, $B9, $D8, $B9, $11, $BA, $11, $BA, $09, $BA, $09, $BA, $E4, $B9
	db $09, $BA, $E4, $B9, $95, $BA, $BD, $BA, $BD, $BA, $BD, $BA, $BD, $BA, $BD, $BA
	db $BD, $BA, $BD, $BA, $BD, $BA, $BD, $BA, $BD, $BA, $C0, $B9, $C0, $B9, $C0, $B9
	db $C0, $B9, $BD, $BA, $C0, $B9, $45, $55, $8B, $EC, $83, $EC, $04, $66, $A1, $72
	db $0E, $66, $89, $46, $FC, $83, $3E, $6C, $10, $00, $75, $43, $EB, $3A, $C4, $5E
	db $FC, $26, $F6, $47, $33, $80, $75, $0A, $C4, $5E, $FC, $26, $F6, $47, $32, $02
	db $74, $1A, $C4, $5E, $FC, $26, $F6, $47, $31, $20, $74, $10, $6A, $00, $FF, $76
	db $FE, $FF, $76, $FC, $90, $0E, $E8, $15, $B2, $83, $C4, $06, $C4, $5E, $FC, $66
	db $26, $8B, $47, $18, $66, $89, $46, $FC, $66, $83, $7E, $FC, $00, $75, $BF, $FF
	db $06, $6C, $10, $A1, $6C, $10, $C9, $4D, $CB, $C9, $4D, $CB, $45, $55, $8B, $EC
	db $83, $EC, $04, $66, $A1, $72, $0E, $66, $89, $46, $FC, $FF, $0E, $6C, $10, $83
	db $3E, $6C, $10, $00, $75, $43, $EB, $3A, $C4, $5E, $FC, $26, $F6, $47, $33, $80
	db $75, $0A, $C4, $5E, $FC, $26, $F6, $47, $32, $02, $74, $1A, $C4, $5E, $FC, $26
	db $F6, $47, $31, $20, $74, $10, $6A, $01, $FF, $76, $FE, $FF, $76, $FC, $90, $0E
	db $E8, $AB, $B1, $83, $C4, $06, $C4, $5E, $FC, $66, $26, $8B, $47, $18, $66, $89
	db $46, $FC, $66, $83, $7E, $FC, $00, $75, $BF, $A1, $6C, $10, $C9, $4D, $CB, $C9
	db $4D, $CB, $45, $55, $8B, $EC, $83, $EC, $04, $FF, $76, $08, $FF, $76, $06, $90
	db $0E, $E8, $C3, $13, $83, $C4, $04, $89, $56, $FE, $89, $46, $FC, $66, $83, $7E
	db $FC, $00, $74, $25, $66, $83, $7E, $0A, $00, $74, $1E, $C4, $5E, $0A, $26, $8B
	db $07, $C4, $5E, $FC, $26, $3B, $07, $74, $10, $6A, $01, $FF, $76, $FE, $FF, $76
	db $FC, $90, $0E, $E8, $E1, $14, $83, $C4, $06, $C9, $4D, $CB, $45, $55, $8B, $EC
	db $C4, $5E, $0A, $26, $8B, $5F, $02, $83, $FB, $50, $74, $41, $7F, $30, $83, $FB
	db $3D, $74, $3A, $7F, $1A, $83, $FB, $15, $74, $33, $7F, $0C, $83, $FB, $05, $74
	db $2C, $83, $FB, $0E, $74, $27, $EB, $57, $83, $FB, $16, $74, $20, $EB, $50, $83
	db $EB, $3E, $83, $FB, $04, $77, $48, $03, $DB, $2E, $FF, $A7, $D5, $BC, $83, $EB
	db $51, $83, $FB, $08, $77, $39, $03, $DB, $2E, $FF, $A7, $C3, $BC, $66, $83, $7E
	db $0E, $00, $74, $13, $C4, $5E, $0E, $26, $8B, $07, $A3, $72, $5B, $C4, $5E, $0E
	db $26, $8B, $47, $02, $A3, $74, $5B, $FF, $36, $44, $0E, $FF, $36, $42, $0E, $FF
	db $76, $08, $FF, $76, $06, $9A, $67, $A3, $FF, $30, $83, $C4, $08, $EB, $00, $5D
	db $4D, $CB, $8E, $BC, $8E, $BC, $8E, $BC, $8E, $BC, $8E, $BC, $8E, $BC, $8E, $BC
	db $8E, $BC, $8E, $BC, $8E, $BC, $8E, $BC, $8E, $BC, $C0, $BC, $8E, $BC, $45, $55
	db $8B, $EC, $83, $EC, $06, $56, $57, $C4, $5E, $06, $26, $8B, $47, $38, $89, $46
	db $FA, $C4, $5E, $06, $26, $F6, $47, $33, $80, $0F, $85, $DC, $00, $C4, $5E, $06
	db $26, $FF, $37, $9A, $83, $0F, $6F, $17, $0B, $C0, $0F, $84, $CB, $00, $33, $F6
	db $8B, $46, $FA, $3D, $2D, $00, $0F, $84, $81, $00, $7F, $1E, $3D, $21, $00, $0F
	db $84, $86, $00, $7F, $0D, $3D, $0D, $00, $74, $21, $3D, $1B, $00, $74, $4B, $E9
	db $8B, $00, $3D, $22, $00, $74, $77, $E9, $83, $00, $3D, $60, $00, $74, $65, $3D
	db $6A, $00, $74, $74, $3D, $6F, $00, $74, $6A, $EB, $72, $83, $3E, $BA, $5B, $00
	db $75, $23, $C4, $5E, $06, $26, $C7, $47, $38, $01, $00, $6A, $05, $FF, $76, $08
	db $FF, $76, $06, $90, $0E, $E8, $92, $A0, $83, $C4, $06, $B8, $01, $00, $5F, $5E
	db $C9, $4D, $CB, $EB, $03, $BE, $0D, $40, $EB, $43, $C4, $5E, $06, $26, $C7, $47
	db $38, $02, $00, $6A, $05, $FF, $76, $08, $FF, $76, $06, $90, $0E, $E8, $6A, $A0
	db $83, $C4, $06, $B8, $01, $00, $5F, $5E, $C9, $4D, $CB, $83, $3E, $BA, $5B, $00
	db $74, $02, $EB, $19, $BE, $AD, $63, $EB, $14, $BE, $98, $23, $EB, $0F, $BE, $92
	db $23, $EB, $0A, $BE, $A0, $23, $EB, $05, $BE, $9C, $23, $EB, $00, $0B, $F6, $74
	db $18, $FF, $36, $2A, $0E, $68, $11, $01, $56, $66, $6A, $01, $9A, $01, $00, $87
	db $17, $B8, $01, $00, $5F, $5E, $C9, $4D, $CB, $9A, $8F, $80, $77, $17, $8B, $F8
	db $57, $9A, $3D, $47, $4F, $17, $50, $FF, $76, $08, $FF, $76, $06, $90, $0E, $E8
	db $31, $11, $83, $C4, $06, $89, $56, $FE, $89, $46, $FC, $66, $83, $7E, $FC, $00
	db $0F, $84, $12, $02, $C4, $5E, $FC, $26, $8B, $5F, $02, $83, $FB, $40, $0F, $84
	db $C9, $00, $7F, $41, $83, $FB, $16, $0F, $84, $C0, $00, $7F, $27, $83, $FB, $0E
	db $0F, $84, $B7, $00, $7F, $0F, $83, $FB, $05, $0F, $84, $AE, $00, $83, $FB, $0A
	db $74, $34, $E9, $71, $01, $83, $FB, $10, $74, $2C, $83, $FB, $15, $0F, $84, $9A
	db $00, $E9, $62, $01, $83, $EB, $32, $83, $FB, $0D, $0F, $87, $58, $01, $03, $DB
	db $2E, $FF, $A7, $5B, $C0, $83, $EB, $42, $83, $FB, $17, $0F, $87, $47, $01, $03
	db $DB, $2E, $FF, $A7, $2B, $C0, $C4, $5E, $06, $26, $F6, $47, $33, $80, $74, $31
	db $83, $7E, $FA, $20, $74, $07, $81, $7E, $FA, $B7, $23, $75, $24, $57, $68, $01
	db $02, $6A, $00, $66, $6A, $00, $9A, $01, $00, $87, $17, $57, $68, $02, $02, $6A
	db $00, $66, $6A, $00, $9A, $01, $00, $87, $17, $B8, $01, $00, $5F, $5E, $C9, $4D
	db $CB, $E9, $02, $01, $83, $7E, $FA, $20, $74, $07, $81, $7E, $FA, $B7, $23, $75
	db $27, $C4, $5E, $06, $06, $C4, $76, $FC, $26, $8B, $04, $07, $26, $89, $47
