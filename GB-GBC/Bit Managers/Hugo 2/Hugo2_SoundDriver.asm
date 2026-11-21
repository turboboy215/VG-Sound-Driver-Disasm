; =====================================================================
; Hugo 2 (G) [S] - Game Boy
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o hugo2.o Hugo2_SoundDriver.asm
;   rgblink -o hugo2.gb hugo2.o
;   python tools/cmp_banked.py hugo2.gb "Hugo 2 (G) [S][!].gb" 7:4000-7FFF
; (driver and data fill ROM bank 7; the linked file only matches in that range)
;
; Documentation: Hugo2_SoundDriver.md / AJG_SoundEngine_Family.md
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
MACRO REPEAT    ; play the following bytes n times (up to REPEAT_END), n = 2-15
	db $F0 + \1
ENDM
MACRO LEN       ; note length in ticks, 1-48
	db $C1 + \1
ENDM
MACRO VOLENV    ; start volume + envelope (CH3/SFX): atk (lo=count hi=step), dec (lo=count hi=step), rates (hi=atk lo=dec)
	db $B2 + \1, \2, \3, \4
ENDM
MACRO INSTR     ; instrument n = entry n + 1 of the current instrument table
	db $85 + \1
ENDM
MACRO ARP       ; arpeggio n of the current arpeggio table
	db $96 + \1
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
DEF DRUM_TEMPO EQU $C1         ; + n: one step every n ticks
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


SECTION "SoundDriver", ROMX[$4000], BANK[7]


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
	jp Pat_5F8E                         ; unused song slot: jumps into pattern data (never called)
	jp Pat_5F8E                         ; unused song slot: jumps into pattern data (never called)
	jp Pat_5F8E                         ; unused song slot: jumps into pattern data (never called)
	jp Pat_5F8E                         ; unused song slot: jumps into pattern data (never called)
	jp Pat_5F8E                         ; unused song slot: jumps into pattern data (never called)
	jp Pat_5F8E                         ; unused song slot: jumps into pattern data (never called)
	jp Pat_5F8E                         ; unused song slot: jumps into pattern data (never called)

; The game's PlaySfx glue (PlaySfxEntry jumps here): ids 2 and 3 start noise
; routines (SFX 2-3, their table entries are placeholders), others go to PlaySfx.
GamePlaySfxGlue:
	cp $02
	jp z, Sfx02_Noise
	cp $03
	jp z, Sfx03_Noise
PlaySfxEntry2:
	jp PlaySfx

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
	add a, $C4
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
	sub $F0
	ld l, $39
	ld [hli], a
	ld [hl], e
	inc l
	ld [hl], d
	jp ReadByte

; StreamCommand: REPEAT / LEN / VOLENV / ARP / INSTR ranges, else CmdTable.
StreamCommand:
	cp $F2
	jr nc, Cmd_Repeat
	cp $C2
	jr nc, Cmd_Len
	cp $B2
	jr nc, Cmd_VolEnv
	cp $96
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
	sub $C1
	ld l, $09
	ld [hl], a
	jp ReadStream

; VOLENV v, atk, dec, rates: start volume v; attack = lo nibble steps of hi nibble;
; decay likewise; rates hi = ticks per attack step, lo = ticks per decay step.
; Only the CH3 and SFX pages use it.
Cmd_VolEnv:
	sub $B2
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
	sub $96
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

; StopAll: as Prisoners of the Sun (calls SndResume), then sets the default
; instrument table ($6227, instrument table 2; songs 2-4 keep it, the others set
; their own), then silences CH1-CH4 and resets the pages.
StopAll:
	call SndResume
	ld a, $62
	ld [wInstrTableHi], a
	ld a, $27
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
	ldh [rNR11], a
	ret
SetDutyCh2:
	ld a, l
	ldh [rNR21], a
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

; Unreferenced (71 bytes)
	db $E0, $1E, $C9, $0C, $2A, $E2, $0C, $7E, $E2, $FA, $42, $DC, $A7, $C0, $3E, $80
	db $EA, $07, $DE, $E0, $1A, $E0, $1E, $C9, $2E, $2B, $50, $E8, $97, $18, $83, $C4
	db $08, $E9, $82, $00, $C4, $1E, $40, $2F, $26, $8A, $47, $21, $98, $05, $40, $00
	db $50, $B8, $83, $26, $EB, $C7, $C4, $5E, $04, $26, $8A, $47, $07, $98, $3D, $59
	db $00, $74, $0E, $77, $61, $2C, $47
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

; API entry for PlaySfx: goes through the game's glue (GamePlaySfxGlue) first.
PlaySfxEntry:
	jp GamePlaySfxGlue

; PlaySfx (A = id): no priority test; reset the SFX page and start the stream.
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
	add a, $C9
	ld l, a
	adc a, $63
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
	cp $C2
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
	add a, $F2
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
	dw Drum3
	dw Drum4
	dw Drum5
	dw Drum6
	dw Drum7
	dw Drum8
	dw Drum9
	dw Drum10
	dw Drum11
DrumTempo:
	sub $C1
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

; Song 2: instrument table 2, arpeggio table 1 (the one SndInit sets)
PlaySong2:
	call StopAll
	ld de, Song2_Ch1
	call StartMusicCh1
	ld de, Song2_Ch3
	call StartMusicCh3
	ld de, Song2_Ch2
	jp StartMusicCh2

; Unreferenced (1 bytes)
	db $C9
Song2_Ch1:
	dw Pat_4B88
	dw Pat_4BA2
	dw Pat_4BC7
	dw Pat_4B8D
	dw Pat_4BE8
	dw Pat_4C0D
	dw Pat_4C0D
	dw Pat_4B8D
	dw Pat_4BE8
	dw Pat_4C0D
	dw Pat_4C0D
	ORDER_LOOP Song2_Ch1
Song2_Ch3:
	dw Pat_4C32
	dw Pat_4C36
	dw Pat_4C62
	dw Pat_4CA7
	dw Pat_4CBE
	dw Pat_4CD5
	dw Pat_4CD9
	dw Pat_4CA7
	dw Pat_4CBE
	dw Pat_4CD5
	dw Pat_4CD9
	ORDER_LOOP Song2_Ch3
Song2_Ch2:
	dw Pat_4D18
	dw Pat_4D48
	dw Pat_4D6A
	dw Pat_4D81
	dw Pat_4DB1
	dw Pat_4DD7
	dw Pat_4DFE
	dw Pat_4D81
	dw Pat_4DB1
	dw Pat_4DD7
	dw Pat_4DFE
	ORDER_LOOP Song2_Ch2
Pat_4B88:
	HWENV $E2, $00
	DUTY_50
	ARP 0
Pat_4B8D:
	REPEAT 2
	LEN 28
	NOTE C_, 2
	LEN 14
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE F_, 2
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 2
	NOTE D_, 3
	NOTE G_, 3
	NOTE G_, 2
	REPEAT_END
	NEXT
Pat_4BA2:
	LEN 28
	NOTE F_, 2
	LEN 14
	NOTE F_, 3
	NOTE C_, 3
	NOTE F_, 2
	NOTE C_, 3
	NOTE F_, 3
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE C_, 3
	NOTE C_, 3
	NOTE D_, 3
	NOTE G_, 3
	LEN 28
	NOTE F_, 2
	LEN 14
	NOTE F_, 3
	NOTE C_, 3
	NOTE F_, 2
	NOTE C_, 3
	NOTE F_, 3
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NEXT
Pat_4BC7:
	LEN 42
	NOTE C_, 2
	LEN 14
	NOTE E_, 2
	LEN 42
	NOTE E_, 2
	LEN 14
	NOTE F_, 2
	LEN 42
	NOTE F_, 2
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	LEN 42
	NOTE C_, 2
	LEN 14
	NOTE E_, 2
	LEN 42
	NOTE E_, 2
	LEN 14
	NOTE F_, 2
	LEN 42
	NOTE F_, 2
	LEN 14
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NEXT
Pat_4BE8:
	LEN 28
	NOTE C_, 2
	LEN 14
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE F_, 2
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 2
	NOTE D_, 3
	NOTE G_, 3
	NOTE G_, 2
	LEN 28
	NOTE C_, 2
	LEN 14
	NOTE C_, 3
	NOTE G_, 2
	NOTE F_, 2
	NOTE C_, 3
	NOTE F_, 3
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE F_, 3
	NOTE G_, 3
	NOTE G_, 2
	NOTE Fsh, 2
	NEXT
Pat_4C0D:
	LEN 28
	NOTE F_, 2
	LEN 14
	NOTE F_, 3
	NOTE C_, 3
	NOTE F_, 2
	NOTE C_, 3
	NOTE F_, 3
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE C_, 3
	NOTE C_, 3
	NOTE D_, 3
	NOTE G_, 3
	LEN 28
	NOTE F_, 2
	LEN 14
	NOTE F_, 3
	NOTE C_, 3
	NOTE F_, 2
	NOTE C_, 3
	NOTE F_, 3
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NEXT
Pat_4C32:
	DRUMS $07, DrumPat_4E28
Pat_4C36:
	CH_TRANSPOSE $0C
	LEN 28
	REPEAT 4
	INSTR 2
	NOTE E_, 3
	INSTR 1
	NOTE B_, 3
	INSTR 2
	LEN 14
	NOTE E_, 3
	NOTE E_, 3
	INSTR 1
	LEN 28
	NOTE B_, 3
	REPEAT_END
	NEXT
Pat_4C47:
	INSTR 2
	NOTE E_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 2
	NOTE E_, 3
	NEXT
Pat_4C62:
	DRUMS $07, DrumPat_4E3A
	LEN 14
	PAT_CALL Pat_4C47
	INSTR 4
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 4
	NOTE G_, 4
	PAT_CALL Pat_4C47
	NOTE E_, 3
	INSTR 1
	NOTE B_, 3
	INSTR 2
	NOTE E_, 3
	NEXT
Pat_4C79:
	INSTR 2
	LEN 14
	NOTE E_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 1
	NOTE B_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 2
	NOTE E_, 3
	NOTE E_, 3
	INSTR 1
	LEN 28
	NOTE B_, 3
	INSTR 2
	LEN 14
	NOTE E_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 1
	NOTE B_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	NOTE E_, 3
	INSTR 1
	LEN 28
	NOTE B_, 3
	INSTR 2
	LEN 14
	NOTE E_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 1
	NOTE B_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 2
	NOTE E_, 3
	NOTE E_, 3
	INSTR 1
	LEN 28
	NOTE B_, 3
	NEXT
Pat_4CA7:
	DRUMS $07, DrumPat_4E28
	PAT_CALL Pat_4C79
	INSTR 2
	LEN 14
	NOTE E_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 1
	NOTE B_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	NOTE E_, 3
	INSTR 1
	LEN 28
	NOTE B_, 3
	NEXT
Pat_4CBE:
	PAT_CALL Pat_4C79
	DRUMS $07, DrumPat_4E5E
	INSTR 2
	LEN 14
	NOTE E_, 3
	INSTR 1
	NOTE B_, 3
	NOTE B_, 3
	INSTR 2
	NOTE E_, 3
	NOTE E_, 3
	INSTR 1
	NOTE B_, 3
	NOTE B_, 3
	LEN 7
	NOTE B_, 3
	NOTE B_, 3
	NEXT
Pat_4CD5:
	DRUMS $07, DrumPat_4E28
Pat_4CD9:
	INSTR 2
	LEN 14
	NOTE E_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 1
	NOTE B_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 2
	NOTE E_, 3
	NOTE E_, 3
	INSTR 1
	LEN 28
	NOTE B_, 3
	INSTR 2
	LEN 14
	NOTE E_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 1
	NOTE B_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	NOTE E_, 3
	INSTR 1
	LEN 28
	NOTE B_, 3
	INSTR 2
	LEN 14
	NOTE E_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 1
	NOTE B_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 2
	NOTE E_, 3
	NOTE E_, 3
	INSTR 1
	LEN 7
	NOTE B_, 3
	LEN 21
	WAIT2
	INSTR 2
	LEN 14
	NOTE E_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 1
	NOTE B_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	NOTE E_, 3
	INSTR 1
	LEN 28
	NOTE B_, 3
	NEXT
Pat_4D18:
	DRUMS $07, DrumPat_4E28
	HWENV $A2, $07, $43
	ARP 1
	DUTY_12
	VIBRATO $0E, $01, $05
	LEN 14
	NOTE C_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	NEXT
Pat_4D48:
	LEN 14
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE B_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE G_, 5
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE F_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 5
	NOTE G_, 4
	NOTE G_, 5
	NOTE F_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE D_, 5
	NEXT
Pat_4D6A:
	LEN 21
	NOTE C_, 5
	LENGTH $CB
	WAIT2
	ARP 0
	LEN 42
	NOTE C_, 3
	LEN 14
	NOTE E_, 3
	LEN 42
	NOTE E_, 3
	LEN 14
	NOTE F_, 3
	LEN 42
	NOTE F_, 3
	LEN 14
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NEXT
Pat_4D81:
	HWENV $C3, $00
	DUTY_50
	ARP_OFF
	VIBRATO $0E, $01, $04
	LEN 7
	NOTE E_, 4
	NOTE F_, 4
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NOTE C_, 4
	LENGTH $38
	NOTE C_, 4
	LEN 7
	NOTE B_, 4
	NOTE C_, 5
	LEN 14
	NOTE D_, 5
	NOTE D_, 5
	NOTE G_, 4
	LEN 42
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	NOTE E_, 4
	LENGTH $38
	NOTE D_, 4
	NEXT
Pat_4DB1:
	LEN 7
	NOTE E_, 4
	NOTE F_, 4
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NOTE C_, 4
	LENGTH $38
	NOTE C_, 4
	LEN 7
	NOTE B_, 4
	NOTE C_, 5
	LEN 14
	NOTE D_, 5
	NOTE D_, 5
	NOTE G_, 4
	LEN 42
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE B_, 5
	NOTE C_, 6
	LEN 28
	NOTE G_, 5
	LEN 14
	NOTE F_, 5
	NOTE E_, 5
	LENGTH $38
	NOTE D_, 5
	NEXT
Pat_4DD7:
	LEN 14
	WAIT
	HWENV $79, $04, $B0
	DUTY_75
	RELEASE $01, $64
	NOTE F_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE B_, 4
	WAIT2
	NOTE G_, 4
	NOTE D_, 4
	LEN 42
	NOTE B_, 3
	WAIT2
	LEN 14
	NOTE F_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE B_, 4
	WAIT2
	NOTE G_, 4
	NOTE D_, 5
	LEN 42
	NOTE G_, 5
	LEN 28
	WAIT2
	NEXT
Pat_4DFE:
	LEN 14
	WAIT
	NOTE F_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE B_, 4
	WAIT2
	NOTE G_, 4
	NOTE D_, 4
	LEN 28
	NOTE B_, 3
	LEN 14
	NOTE D_, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 21
	NOTE F_, 4
	LEN 7
	WAIT2
	LEN 21
	NOTE A_, 4
	LEN 7
	WAIT2
	NOTE C_, 5
	WAIT2
	LEN 14
	NOTE C_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	LEN 42
	NOTE D_, 5
	LEN 28
	WAIT2
	RELEASE $00
	NEXT
DrumPat_4E28:
	db DRUM_LEVEL + 14, 1, 0, 5, 0, 9, 0, 5
	db 0, 1, 0, 1, 0, 9, 0, 4
	db 0, DRUM_LOOP
DrumPat_4E3A:
	db DRUM_LEVEL + 14, DRUM_REPEAT + 3, 1, 0, 5, 6, 1, 0
	db 5, 6, 1, 0, 5, 6, 1, 0
	db 4, 0, DRUM_REPEAT_END, 1, 0, 5, 6, 1
	db 0, 5, 6, 1, 0, 1, 6, 9
	db 0, 1, 0, DRUM_LOOP
DrumPat_4E5E:
	db 1, 0, 9, 0, 9, 0, 1, 0
	db 1, 0, 9, 0, 9, 0, 9, 9
	db DRUM_LOOP

; Song 3: instrument table 2, arpeggio table 1 (the one SndInit sets)
PlaySong3:
	call StopAll
	ld de, Song3_Ch3
	call StartMusicCh3
	ld de, Song3_Ch2
	call StartMusicCh2
	ld de, Song3_Ch1
	jp StartMusicCh1

; Unreferenced (1 bytes)
	db $C9
Song3_Ch3:
	dw Pat_5F8E
	dw Pat_4EFE
	dw Pat_4F52
	dw Pat_4F94
	dw Pat_4F00
	dw Pat_4F2B
	dw Pat_4F00
	dw Pat_4F2B
	dw Pat_4F00
	dw Pat_5F91
	dw Pat_4F00
	dw Pat_4EFE
	dw Pat_4F52
	dw Pat_4F94
	dw Pat_4F00
	dw Pat_4F2B
	dw Pat_4F00
	dw Pat_4F2B
	dw Pat_4F00
	dw Pat_5F8E
	dw Pat_4F00
	ORDER_LOOP Song3_Ch3
Song3_Ch2:
	dw Pat_4FEB
	dw Pat_4FF2
	dw Pat_5007
	dw Pat_4FEB
	dw Pat_4FFC
	dw Pat_4FEB
	dw Pat_4FFC
	dw Pat_4FEB
	dw Pat_4FEB
	ORDER_LOOP Song3_Ch2
Song3_Ch1:
	dw Pat_503A
	dw Pat_5060
	dw Pat_5079
	dw Pat_508B
	dw Pat_50B3
	dw Pat_50CF
	dw Pat_50F6
	dw Pat_5119
	dw Pat_5119
	ORDER_LOOP Song3_Ch1
Pat_4EDF:
	INSTR 1
	LEN 18
	NOTE G_, 3
	INSTR 11
	LEN 9
	NOTE C_, 2
	NOTE G_, 2
	REST
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 11
	NOTE A_, 2
	NOTE G_, 2
	LEN 27
	NOTE C_, 2
	INSTR 1
	LEN 18
	NOTE G_, 3
	INSTR 11
	LEN 9
	NOTE C_, 2
	NOTE G_, 2
	REST
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 11
	NOTE F_, 2
	NOTE E_, 2
	NEXT
Pat_4EFE:
	CH_TRANSPOSE $0C
Pat_4F00:
	DRUMS $09, DrumPat_514C
	INSTR 11
	LEN 27
	NOTE C_, 2
	INSTR 1
	LEN 18
	NOTE G_, 3
	INSTR 11
	LEN 9
	NOTE C_, 2
	NOTE G_, 2
	REST
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 11
	NOTE A_, 2
	NOTE G_, 2
	LEN 27
	NOTE C_, 2
	INSTR 1
	LEN 18
	NOTE G_, 3
	INSTR 11
	LEN 9
	NOTE C_, 2
	NOTE G_, 2
	REST
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 11
	NOTE A_, 2
	NOTE G_, 2
	LEN 27
	NOTE C_, 2
	PAT_CALL Pat_4EDF
	NEXT
Pat_4F2B:
	INSTR 11
	LEN 27
	NOTE Dsh, 2
	INSTR 1
	LEN 18
	NOTE G_, 3
	INSTR 11
	LEN 9
	NOTE Dsh, 2
	NOTE Ash, 2
	REST
	NOTE Ash, 2
	INSTR 1
	NOTE G_, 3
	INSTR 11
	NOTE C_, 3
	NOTE Ash, 2
	LEN 27
	NOTE Dsh, 2
	INSTR 1
	LEN 18
	NOTE G_, 3
	INSTR 11
	LEN 9
	NOTE Dsh, 2
	NOTE Ash, 2
	REST
	NOTE Ash, 2
	INSTR 1
	NOTE G_, 3
	INSTR 11
	NOTE C_, 3
	NOTE Ash, 2
	LEN 27
	NOTE C_, 2
	PAT_CALL Pat_4EDF
	NEXT
Pat_4F52:
	INSTR 11
	LEN 27
	NOTE Dsh, 2
	INSTR 1
	LEN 18
	NOTE G_, 3
	INSTR 11
	LEN 9
	NOTE Dsh, 2
	NOTE Ash, 2
	REST
	NOTE Ash, 2
	INSTR 1
	NOTE G_, 3
	INSTR 11
	NOTE C_, 3
	NOTE Ash, 2
	LEN 27
	NOTE Dsh, 2
	INSTR 1
	LEN 18
	NOTE G_, 3
	INSTR 11
	LEN 9
	NOTE Dsh, 2
	NOTE Ash, 2
	REST
	NOTE Ash, 2
	INSTR 1
	NOTE G_, 3
	INSTR 11
	NOTE C_, 3
	NOTE Ash, 2
	LEN 27
	NOTE Dsh, 2
	INSTR 1
	LEN 18
	NOTE G_, 3
	INSTR 11
	LEN 9
	NOTE Dsh, 2
	NOTE Ash, 2
	REST
	NOTE Ash, 2
	INSTR 1
	NOTE G_, 3
	INSTR 11
	NOTE C_, 3
	NOTE Ash, 2
	LEN 27
	NOTE Dsh, 2
	INSTR 1
	LEN 18
	NOTE G_, 3
	INSTR 11
	LEN 9
	NOTE Dsh, 2
	NOTE Ash, 2
	REST
	NOTE Ash, 2
	INSTR 1
	NOTE G_, 3
	INSTR 11
	NOTE Gsh, 2
	NOTE G_, 2
	NEXT
Pat_4F94:
	DRUMS $09, DrumPat_5166
	INSTR 11
	LENGTH $B4
	NOTE C_, 2
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE A_, 2
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE C_, 2
	LEN 9
	NOTE C_, 2
	LEN 27
	NOTE C_, 3
	LEN 18
	NOTE C_, 2
	LEN 9
	NOTE C_, 2
	LEN 27
	NOTE C_, 3
	LEN 18
	NOTE F_, 2
	LEN 9
	NOTE F_, 2
	LEN 18
	NOTE A_, 2
	LEN 27
	NOTE G_, 2
	INSTR 1
	DRUMS $09, DrumPat_516B
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	NEXT
Pat_4FC2:
	INSTR 12
	NOTE C_, 4
	INSTR 8
	NOTE G_, 3
	NOTE C_, 4
	INSTR 12
	NOTE C_, 4
	INSTR 8
	NOTE G_, 3
	NOTE C_, 4
	INSTR 13
	NOTE D_, 4
	INSTR 8
	NOTE G_, 3
	NOTE B_, 3
	INSTR 13
	NOTE D_, 4
	INSTR 8
	NOTE G_, 3
	NOTE B_, 3
	INSTR 13
	NOTE E_, 4
	INSTR 8
	NOTE G_, 3
	NOTE C_, 4
	INSTR 13
	NOTE E_, 4
	INSTR 8
	NOTE G_, 3
	INSTR 13
	NOTE D_, 4
	INSTR 8
	NOTE C_, 3
	NOTE G_, 3
	INSTR 13
	NOTE E_, 4
	NOTE D_, 4
	INSTR 8
	NOTE G_, 3
	NOTE B_, 3
	NEXT
Pat_4FEB:
	LEN 9
	REPEAT 2
	PAT_CALL Pat_4FC2
	REPEAT_END
	NEXT
Pat_4FF2:
	REPEAT 2
	CH_TRANSPOSE $03
	PAT_CALL Pat_4FC2
	REPEAT_END
	CH_TRANSPOSE $00
	NEXT
Pat_4FFC:
	CH_TRANSPOSE $03
	PAT_CALL Pat_4FC2
	CH_TRANSPOSE $00
	PAT_CALL Pat_4FC2
	NEXT
Pat_5007:
	INSTR 8
	LEN 9
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE C_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE C_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NEXT
Pat_503A:
	DUTY_75
	HWENV $F2, $08, $80
	VIBRATO $09, $01, $05
	ARP 0
	RELEASE $02, $55
	LENGTH $36
	NOTE C_, 4
	LENGTH $51
	REST
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE E_, 4
	LEN 18
	NOTE F_, 4
	LEN 9
	NOTE E_, 4
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE E_, 4
	LENGTH $36
	NOTE C_, 4
	LENGTH $A2
	REST
	NEXT
Pat_5060:
	LENGTH $36
	NOTE Dsh, 4
	LENGTH $51
	REST
	LEN 18
	NOTE F_, 4
	LEN 9
	NOTE G_, 4
	LEN 18
	NOTE Gsh, 4
	LEN 9
	NOTE G_, 4
	LEN 18
	NOTE F_, 4
	LEN 9
	NOTE G_, 4
	LENGTH $36
	NOTE Dsh, 4
	LENGTH $A2
	REST
	NEXT
Pat_5079:
	LEN 27
	NOTE C_, 5
	NOTE G_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE B_, 4
	NOTE D_, 5
	NEXT
Pat_508B:
	DUTY_50
	HWENV $F2, $08, $75
	ARP_OFF
	RELEASE $00
	LENGTH $87
	NOTE C_, 4
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE E_, 4
	LEN 18
	NOTE F_, 4
	LEN 9
	NOTE E_, 4
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE E_, 4
	LEN 45
	NOTE G_, 4
	LEN 9
	NOTE E_, 4
	LEN 27
	NOTE G_, 4
	LEN 18
	NOTE A_, 4
	LEN 36
	NOTE G_, 4
	LEN 27
	NOTE E_, 4
	LEN 18
	NOTE C_, 4
	LEN 36
	NOTE D_, 4
	NEXT
Pat_50B3:
	LEN 27
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE C_, 4
	LEN 18
	NOTE Ash, 3
	LEN 27
	NOTE Dsh, 4
	LEN 9
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	LEN 18
	NOTE C_, 4
	LEN 27
	NOTE Ash, 3
	LENGTH $AB
	NOTE C_, 4
	LEN 9
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE A_, 4
	NEXT
Pat_50CF:
	LEN 45
	NOTE C_, 5
	LEN 9
	NOTE A_, 4
	LEN 27
	NOTE C_, 5
	LEN 18
	NOTE D_, 5
	LEN 27
	NOTE E_, 5
	LEN 9
	NOTE E_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 4
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE F_, 4
	LEN 45
	NOTE G_, 4
	LEN 9
	NOTE E_, 4
	LEN 27
	NOTE G_, 4
	LEN 18
	NOTE A_, 4
	LEN 36
	NOTE G_, 4
	LEN 27
	NOTE E_, 4
	LEN 18
	NOTE C_, 4
	LEN 36
	NOTE D_, 4
	NEXT
Pat_50F6:
	LEN 27
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 18
	NOTE Ash, 3
	LEN 27
	NOTE G_, 4
	LEN 9
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 18
	NOTE Dsh, 4
	LEN 27
	NOTE D_, 4
	LENGTH $AB
	NOTE E_, 4
	HWENV $F1, $00
	GLIDE $FE
	LEN 9
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	GLIDE $00
	NEXT
Pat_5119:
	INSTR 8
	LEN 9
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE C_, 6
	NOTE C_, 6
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE A_, 5
	NOTE A_, 5
	NOTE E_, 5
	NOTE E_, 5
	NOTE E_, 5
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE E_, 6
	NOTE E_, 6
	NOTE E_, 6
	NOTE B_, 5
	NOTE B_, 5
	NOTE B_, 5
	NOTE D_, 6
	NOTE D_, 6
	NOTE D_, 6
	NOTE C_, 6
	NOTE C_, 6
	NOTE C_, 6
	NEXT
DrumPat_514C:
	db DRUM_LEVEL + 13, 1, 0, 6, 9, 0, 6, 1
	db 0, 6, 9, 0, 4, 1, 0, 6
	db 9, 0, 6, 1, 0, 6, 9, 6
	db 6, DRUM_LOOP
DrumPat_5166:
	db DRUM_LEVEL + 13, 4, 0, 0, DRUM_LOOP
DrumPat_516B:
	db DRUM_LEVEL + 13, 9, 9, 0, 9, DRUM_LOOP

; Song 4: instrument table 2, arpeggio table 1 (the one SndInit sets)
PlaySong4:
	call StopAll
	ld de, Song4_Ch1
	call StartMusicCh1
	ld de, Song4_Ch3
	call StartMusicCh3
	ld de, Song4_Ch2
	jp StartMusicCh2

; Unreferenced (1 bytes)
	db $C9
Song4_Ch1:
	dw Pat_51FD
	dw Pat_5215
	dw Pat_5220
	dw Pat_5261
	dw Pat_5220
	dw Pat_5261
	dw Pat_520A
	dw Pat_5215
	ORDER_LOOP Song4_Ch1
Song4_Ch3:
	dw Pat_52A2
	dw Pat_5355
	dw Pat_52DF
	dw Pat_531A
	dw Pat_5390
	dw Pat_531A
	dw Pat_52A4
	dw Pat_52A4
	ORDER_LOOP Song4_Ch3
Song4_Ch2:
	dw Pat_53CB
	dw Pat_543E
	dw Pat_540A
	dw Pat_5429
	dw Pat_547B
	dw Pat_549F
	dw Pat_54B4
	dw Pat_54F3
	ORDER_LOOP Song4_Ch2
Pat_51C3:
	LEN 12
	NOTE A_, 2
	LEN 6
	NOTE A_, 2
	LEN 12
	NOTE A_, 3
	LEN 6
	NOTE A_, 2
	LEN 12
	NOTE A_, 2
	LEN 6
	NOTE A_, 2
	LEN 12
	NOTE E_, 3
	LEN 6
	NOTE A_, 2
	LEN 12
	NOTE G_, 2
	LEN 6
	NOTE G_, 2
	LEN 12
	NOTE G_, 3
	LEN 6
	NOTE G_, 2
	LEN 12
	NOTE G_, 2
	LEN 6
	NOTE G_, 2
	LEN 12
	NOTE D_, 3
	LEN 6
	NOTE G_, 2
	LEN 12
	NOTE E_, 2
	LEN 6
	NOTE E_, 2
	LEN 12
	NOTE E_, 3
	LEN 6
	NOTE E_, 2
	LEN 12
	NOTE E_, 2
	LEN 6
	NOTE E_, 2
	LEN 12
	NOTE B_, 2
	LEN 6
	NOTE E_, 2
	LEN 12
	NOTE F_, 2
	LEN 6
	NOTE F_, 2
	LEN 12
	NOTE F_, 3
	LEN 6
	NOTE F_, 2
	LEN 12
	NEXT
Pat_51FD:
	DRUMS $06, DrumPat_5531
	HWENV $F1, $00
	ARP_OFF
	DUTY_50
	VIBRATO $06, $01, $04
Pat_520A:
	PAT_CALL Pat_51C3
	NOTE F_, 2
	LEN 6
	NOTE F_, 2
	LEN 12
	NOTE G_, 2
	LEN 6
	NOTE Gsh, 2
	NEXT
Pat_5215:
	PAT_CALL Pat_51C3
	NOTE G_, 2
	LEN 6
	NOTE G_, 2
	LEN 12
	NOTE A_, 2
	LEN 6
	NOTE B_, 2
	NEXT
Pat_5220:
	LEN 12
	NOTE C_, 2
	LEN 6
	NOTE C_, 2
	LEN 12
	NOTE C_, 3
	LEN 6
	NOTE G_, 2
	LEN 12
	NOTE C_, 2
	LEN 6
	NOTE C_, 2
	LEN 12
	NOTE G_, 2
	LEN 6
	NOTE A_, 2
	LEN 12
	NOTE C_, 2
	LEN 6
	NOTE C_, 2
	LEN 12
	NOTE C_, 3
	LEN 6
	NOTE G_, 2
	LEN 12
	NOTE C_, 2
	LEN 6
	NOTE C_, 2
	LEN 12
	NOTE D_, 2
	LEN 6
	NOTE Dsh, 2
	LEN 12
	NOTE E_, 2
	LEN 6
	NOTE E_, 2
	LEN 12
	NOTE E_, 3
	LEN 6
	NOTE B_, 2
	LEN 12
	NOTE E_, 2
	LEN 6
	NOTE E_, 2
	LEN 12
	NOTE E_, 3
	LEN 6
	NOTE G_, 2
	LEN 12
	NOTE E_, 2
	LEN 6
	NOTE E_, 2
	LEN 12
	NOTE E_, 3
	LEN 6
	NOTE B_, 2
	LEN 12
	NOTE E_, 2
	LEN 6
	NOTE E_, 2
	LEN 12
	NOTE E_, 3
	LEN 6
	NOTE E_, 2
	NEXT
Pat_5261:
	LEN 12
	NOTE F_, 2
	LEN 6
	NOTE F_, 2
	LEN 12
	NOTE F_, 3
	LEN 6
	NOTE F_, 2
	LEN 12
	NOTE F_, 2
	LEN 6
	NOTE F_, 2
	LEN 12
	NOTE C_, 3
	LEN 6
	NOTE F_, 2
	LEN 12
	NOTE D_, 2
	LEN 6
	NOTE D_, 2
	LEN 12
	NOTE D_, 3
	LEN 6
	NOTE D_, 2
	LEN 12
	NOTE D_, 2
	LEN 6
	NOTE D_, 2
	LEN 12
	NOTE A_, 2
	LEN 6
	NOTE D_, 2
	LEN 12
	NOTE G_, 2
	LEN 6
	NOTE G_, 2
	LEN 12
	NOTE G_, 3
	LEN 6
	NOTE G_, 2
	LEN 12
	NOTE G_, 2
	LEN 6
	NOTE G_, 2
	LEN 12
	NOTE C_, 3
	LEN 6
	NOTE D_, 3
	LEN 12
	NOTE G_, 2
	LEN 6
	NOTE G_, 2
	LEN 12
	NOTE G_, 3
	LEN 6
	NOTE G_, 2
	LEN 12
	NOTE G_, 2
	LEN 6
	NOTE A_, 2
	LEN 12
	NOTE G_, 2
	LEN 6
	NOTE E_, 2
	NEXT
Pat_52A2:
	CH_TRANSPOSE $0C
Pat_52A4:
	INSTR 2
	LEN 18
	NOTE C_, 3
	INSTR 3
	NOTE A_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 3
	LEN 12
	NOTE A_, 4
	INSTR 2
	LEN 6
	NOTE C_, 3
	LEN 18
	NOTE C_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 1
	LEN 12
	NOTE A_, 3
	INSTR 4
	LEN 6
	NOTE G_, 4
	INSTR 2
	LEN 12
	NOTE C_, 3
	INSTR 4
	LEN 6
	NOTE G_, 4
	INSTR 2
	LEN 18
	NOTE C_, 3
	INSTR 3
	NOTE E_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 3
	LEN 12
	NOTE E_, 4
	INSTR 2
	LEN 6
	NOTE C_, 3
	LEN 18
	NOTE C_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 1
	LEN 12
	NOTE A_, 3
	INSTR 4
	LEN 6
	NOTE F_, 4
	INSTR 2
	LEN 12
	NOTE C_, 3
	INSTR 4
	LEN 6
	NOTE F_, 4
	NEXT
Pat_52DF:
	INSTR 2
	LEN 18
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 4
	LEN 12
	NOTE C_, 4
	INSTR 2
	LEN 6
	NOTE C_, 3
	LEN 18
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 1
	LEN 12
	NOTE A_, 3
	INSTR 4
	LEN 6
	NOTE C_, 4
	INSTR 2
	LEN 12
	NOTE C_, 3
	INSTR 4
	LEN 6
	NOTE C_, 4
	INSTR 2
	LEN 18
	NOTE C_, 3
	INSTR 3
	NOTE E_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 3
	LEN 12
	NOTE E_, 4
	INSTR 2
	LEN 6
	NOTE C_, 3
	LEN 18
	NOTE C_, 3
	INSTR 3
	NOTE E_, 4
	INSTR 1
	LEN 12
	NOTE A_, 3
	INSTR 3
	LEN 6
	NOTE E_, 4
	INSTR 2
	LEN 12
	NOTE C_, 3
	INSTR 3
	LEN 6
	NOTE E_, 4
	NEXT
Pat_531A:
	INSTR 2
	LEN 18
	NOTE C_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 4
	LEN 12
	NOTE F_, 4
	INSTR 2
	LEN 6
	NOTE C_, 3
	LEN 18
	NOTE C_, 3
	INSTR 3
	NOTE D_, 4
	INSTR 1
	LEN 12
	NOTE A_, 3
	INSTR 3
	LEN 6
	NOTE D_, 4
	INSTR 2
	LEN 12
	NOTE C_, 3
	INSTR 3
	LEN 6
	NOTE D_, 4
	INSTR 2
	LEN 18
	NOTE C_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 4
	LEN 12
	NOTE G_, 4
	INSTR 2
	LEN 6
	NOTE C_, 3
	LEN 18
	NOTE C_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 1
	LEN 12
	NOTE A_, 3
	INSTR 4
	LEN 6
	NOTE G_, 4
	INSTR 2
	LEN 12
	NOTE C_, 3
	INSTR 4
	LEN 6
	NOTE G_, 4
	NEXT
Pat_5355:
	INSTR 2
	LEN 18
	NOTE C_, 3
	INSTR 3
	NOTE A_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 3
	LEN 12
	NOTE A_, 4
	INSTR 2
	LEN 6
	NOTE C_, 3
	LEN 18
	NOTE C_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 1
	LEN 12
	NOTE A_, 3
	INSTR 4
	LEN 6
	NOTE G_, 4
	INSTR 2
	LEN 12
	NOTE C_, 3
	INSTR 4
	LEN 6
	NOTE G_, 4
	INSTR 2
	LEN 18
	NOTE C_, 3
	INSTR 3
	NOTE E_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 3
	LEN 12
	NOTE E_, 4
	INSTR 2
	LEN 6
	NOTE C_, 3
	LEN 18
	NOTE C_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 1
	LEN 12
	NOTE A_, 3
	INSTR 4
	LEN 6
	NOTE G_, 4
	INSTR 2
	LEN 12
	NOTE C_, 3
	INSTR 4
	LEN 6
	NOTE C_, 5
	NEXT
Pat_5390:
	INSTR 2
	LEN 18
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 4
	LEN 12
	NOTE C_, 4
	INSTR 2
	LEN 6
	NOTE C_, 3
	LEN 18
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 1
	LEN 12
	NOTE A_, 3
	INSTR 4
	LEN 6
	NOTE C_, 4
	INSTR 2
	LEN 12
	NOTE C_, 3
	INSTR 4
	LEN 6
	NOTE C_, 4
	INSTR 2
	LEN 18
	NOTE C_, 3
	INSTR 3
	NOTE E_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 3
	LEN 12
	NOTE E_, 4
	INSTR 2
	LEN 6
	NOTE C_, 3
	LEN 18
	NOTE C_, 3
	INSTR 3
	NOTE E_, 4
	INSTR 1
	LEN 12
	NOTE A_, 3
	INSTR 3
	LEN 6
	NOTE E_, 4
	INSTR 2
	LEN 12
	NOTE C_, 3
	INSTR 3
	LEN 6
	NOTE E_, 4
	NEXT
Pat_53CB:
	LEN 12
	WAIT
	INSTR 5
	LEN 6
	NOTE A_, 3
	LEN 12
	NOTE C_, 4
	LEN 6
	NOTE A_, 3
	LEN 12
	NOTE C_, 4
	LEN 18
	NOTE A_, 3
	LEN 6
	NOTE A_, 3
	LEN 12
	NOTE B_, 3
	LEN 6
	NOTE G_, 3
	LEN 12
	NOTE B_, 3
	LEN 6
	NOTE G_, 3
	INSTR 6
	LEN 12
	NOTE B_, 4
	LEN 6
	NOTE G_, 4
	LEN 12
	NOTE B_, 4
	LEN 18
	NOTE G_, 4
	INSTR 5
	LEN 6
	NOTE E_, 3
	LEN 12
	NOTE G_, 3
	LEN 6
	NOTE E_, 3
	LEN 12
	NOTE G_, 3
	LEN 18
	NOTE E_, 3
	LEN 6
	NOTE E_, 3
	LEN 12
	NOTE A_, 3
	LEN 6
	NOTE F_, 3
	LEN 12
	NOTE A_, 3
	LEN 6
	NOTE F_, 3
	INSTR 6
	LEN 12
	NOTE A_, 4
	LEN 6
	NOTE F_, 4
	LEN 12
	NOTE A_, 4
	LEN 6
	NOTE E_, 4
	NEXT
Pat_540A:
	LEN 18
	WAIT
	INSTR 14
	LEN 12
	NOTE C_, 4
	LEN 6
	NOTE D_, 4
	LEN 12
	NOTE E_, 4
	LEN 6
	NOTE D_, 4
	LEN 12
	NOTE C_, 4
	LEN 24
	NOTE G_, 4
	LEN 18
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE G_, 4
	LEN 12
	NOTE G_, 4
	LEN 18
	NOTE A_, 4
	LENGTH $48
	NOTE E_, 4
	LEN 6
	NOTE G_, 4
	NEXT
Pat_5429:
	INSTR 14
	LEN 18
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	LENGTH $30
	NOTE C_, 4
	LEN 6
	NOTE D_, 4
	LEN 18
	NOTE C_, 4
	LEN 36
	NOTE B_, 3
	NOTE G_, 3
	NEXT
Pat_543E:
	LEN 12
	WAIT
	INSTR 5
	LEN 6
	NOTE A_, 3
	LEN 12
	NOTE C_, 4
	LEN 6
	NOTE A_, 3
	LEN 12
	NOTE C_, 4
	LEN 18
	NOTE A_, 3
	LEN 6
	NOTE A_, 3
	LEN 12
	NOTE D_, 4
	LEN 6
	NOTE B_, 3
	LEN 12
	NOTE D_, 4
	LEN 6
	NOTE B_, 3
	INSTR 6
	LEN 12
	NOTE D_, 5
	LEN 6
	NOTE B_, 4
	LEN 12
	NOTE D_, 5
	LEN 18
	NOTE B_, 4
	INSTR 5
	LEN 6
	NOTE B_, 3
	LEN 12
	NOTE E_, 4
	LEN 6
	NOTE B_, 3
	LEN 12
	NOTE E_, 4
	LEN 18
	NOTE B_, 3
	LEN 6
	NOTE B_, 3
	LEN 12
	NOTE F_, 4
	LEN 6
	NOTE A_, 3
	LEN 12
	NOTE C_, 4
	LEN 6
	NOTE F_, 4
	LEN 12
	NOTE G_, 4
	LEN 6
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE A_, 4
	NEXT
Pat_547B:
	LEN 18
	WAIT
	INSTR 14
	LEN 12
	NOTE C_, 4
	LEN 6
	NOTE D_, 4
	LEN 12
	NOTE E_, 4
	LEN 6
	NOTE D_, 4
	LEN 12
	NOTE C_, 4
	LEN 24
	NOTE G_, 4
	LEN 18
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE G_, 4
	LEN 12
	NOTE G_, 4
	LEN 18
	NOTE E_, 4
	LEN 36
	NOTE B_, 4
	LEN 18
	NOTE G_, 4
	LEN 6
	NOTE G_, 4
	LEN 12
	NOTE A_, 4
	LEN 6
	NOTE B_, 4
	NEXT
Pat_549F:
	INSTR 14
	LEN 18
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	LEN 12
	NOTE G_, 4
	LEN 18
	NOTE A_, 4
	LEN 6
	NOTE A_, 4
	LEN 18
	NOTE B_, 4
	NOTE C_, 5
	NOTE A_, 4
	LEN 36
	NOTE D_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE B_, 4
	NEXT
Pat_54B4:
	LEN 12
	WAIT
	INSTR 14
	LEN 6
	NOTE A_, 4
	LEN 12
	NOTE C_, 5
	LEN 6
	NOTE A_, 4
	LEN 12
	NOTE C_, 5
	LEN 18
	NOTE A_, 4
	LEN 6
	NOTE A_, 4
	LEN 12
	NOTE B_, 4
	LEN 6
	NOTE G_, 4
	LEN 12
	NOTE B_, 4
	LEN 6
	NOTE G_, 4
	INSTR 6
	LEN 12
	NOTE B_, 4
	LEN 6
	NOTE G_, 4
	LEN 12
	NOTE B_, 4
	LEN 18
	NOTE G_, 4
	INSTR 14
	LEN 6
	NOTE E_, 4
	LEN 12
	NOTE G_, 4
	LEN 6
	NOTE E_, 4
	LEN 12
	NOTE G_, 4
	LEN 18
	NOTE E_, 4
	LEN 6
	NOTE E_, 4
	LEN 12
	NOTE A_, 4
	LEN 6
	NOTE F_, 4
	LEN 12
	NOTE A_, 4
	LEN 6
	NOTE F_, 4
	INSTR 6
	LEN 12
	NOTE A_, 4
	LEN 6
	NOTE F_, 4
	LEN 12
	NOTE A_, 4
	LEN 6
	NOTE E_, 4
	NEXT
Pat_54F3:
	LEN 12
	WAIT
	INSTR 14
	LEN 6
	NOTE A_, 4
	LEN 12
	NOTE C_, 5
	LEN 6
	NOTE A_, 4
	LEN 12
	NOTE C_, 5
	LEN 18
	NOTE A_, 4
	LEN 6
	NOTE A_, 4
	LEN 12
	NOTE D_, 5
	LEN 6
	NOTE B_, 4
	LEN 12
	NOTE D_, 5
	LEN 6
	NOTE B_, 4
	INSTR 6
	LEN 12
	NOTE D_, 5
	LEN 6
	NOTE B_, 4
	LEN 12
	NOTE D_, 5
	LEN 18
	NOTE B_, 4
	INSTR 14
	LEN 6
	NOTE B_, 4
	LEN 12
	NOTE E_, 5
	LEN 6
	NOTE B_, 4
	LEN 12
	NOTE E_, 5
	LEN 18
	NOTE B_, 4
	LEN 6
	NOTE B_, 4
	LEN 12
	NOTE F_, 5
	LEN 6
	NOTE A_, 4
	LEN 12
	NOTE C_, 5
	LEN 6
	NOTE F_, 5
	LEN 12
	NOTE G_, 5
	LEN 6
	NOTE D_, 5
	LEN 12
	NOTE C_, 5
	LEN 6
	NOTE B_, 4
	NEXT
DrumPat_5531:
	db DRUM_LEVEL + 14, 1, 0, 6, 4, 0, 6, 9
	db 0, 6, 4, 0, 1, 1, 0, 6
	db 4, 0, 6, 9, 0, 6, 1, 0
	db 6, DRUM_LOOP

; Song 5: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong5:
	call StopAll
	ld a, $61
	ld [wInstrTableHi], a
	ld a, $A5
	ld [wInstrTable], a
	ld de, Song5_Ch1
	call StartMusicCh1
	ld de, Song5_Ch3
	call StartMusicCh3
	ld de, Song5_Ch2
	jp StartMusicCh2
Song5_Ch1:
	dw Pat_55AC
	dw Pat_5622
	dw Pat_55AC
	dw Pat_5622
	dw Pat_5694
	dw Pat_5694
	dw Pat_56CA
	dw Pat_56CA
	dw Pat_5709
	ORDER_LOOP Song5_Ch1
Song5_Ch3:
	dw Pat_5737
	dw Pat_576B
	dw Pat_5737
	dw Pat_576B
	dw Pat_57AE
	dw Pat_57AE
	dw Pat_57DC
	dw Pat_57DC
	dw Pat_582E
	ORDER_LOOP Song5_Ch3
Song5_Ch2:
	dw Pat_584F
	dw Pat_587B
	dw Pat_584F
	dw Pat_587B
	dw Pat_589D
	dw Pat_58CA
	dw Pat_591E
	dw Pat_591E
	dw Pat_595E
	ORDER_LOOP Song5_Ch2
Pat_55AC:
	VIBRATO $08, $02, $04
	LEN 16
	INSTR 0
	NOTE G_, 2
	INSTR 4
	LEN 8
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	LEN 16
	NOTE D_, 2
	INSTR 4
	LEN 8
	NOTE G_, 4
	INSTR 0
	LEN 16
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	LEN 16
	NOTE D_, 2
	INSTR 4
	LEN 8
	NOTE G_, 4
	INSTR 0
	NOTE F_, 2
	LEN 16
	NOTE G_, 2
	INSTR 4
	LEN 8
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	LEN 16
	NOTE D_, 2
	INSTR 4
	LEN 8
	NOTE G_, 4
	INSTR 0
	LEN 16
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	LEN 16
	NOTE D_, 2
	INSTR 4
	LEN 8
	NOTE G_, 4
	INSTR 0
	NOTE F_, 2
	LEN 16
	NOTE G_, 2
	INSTR 4
	LEN 8
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	LEN 16
	NOTE D_, 2
	INSTR 4
	LEN 8
	NOTE G_, 4
	INSTR 0
	LEN 16
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	LEN 16
	NOTE A_, 2
	INSTR 4
	LEN 8
	NOTE G_, 4
	INSTR 0
	NOTE B_, 2
	LEN 16
	NOTE C_, 3
	INSTR 4
	LEN 8
	NOTE C_, 5
	INSTR 0
	NOTE C_, 3
	LEN 16
	NOTE G_, 2
	INSTR 4
	LEN 8
	NOTE C_, 5
	INSTR 0
	LEN 16
	NOTE C_, 3
	LEN 8
	NOTE C_, 3
	INSTR 4
	NOTE C_, 5
	INSTR 0
	NOTE C_, 3
	LEN 16
	NOTE G_, 2
	INSTR 4
	LEN 8
	NOTE C_, 5
	INSTR 0
	NOTE B_, 2
	NEXT
Pat_5622:
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 5
	LEN 8
	NOTE A_, 4
	INSTR 0
	NOTE A_, 2
	LEN 16
	NOTE E_, 2
	INSTR 5
	LEN 8
	NOTE A_, 4
	INSTR 0
	LEN 16
	NOTE A_, 2
	LEN 8
	NOTE A_, 2
	INSTR 5
	NOTE A_, 4
	INSTR 0
	NOTE A_, 2
	LEN 16
	NOTE E_, 2
	INSTR 5
	LEN 8
	NOTE A_, 4
	INSTR 0
	NOTE A_, 2
	LEN 16
	NOTE G_, 2
	INSTR 4
	LEN 8
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	LEN 16
	NOTE D_, 2
	INSTR 4
	LEN 8
	NOTE G_, 4
	INSTR 0
	LEN 16
	NOTE E_, 2
	LEN 8
	NOTE E_, 2
	INSTR 5
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	LEN 16
	NOTE B_, 2
	INSTR 5
	LEN 8
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	LEN 16
	NOTE C_, 3
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	LEN 16
	NOTE G_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 0
	LEN 16
	NOTE C_, 3
	LEN 8
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	LEN 16
	NOTE G_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	LEN 16
	NOTE D_, 3
	INSTR 4
	LEN 8
	NOTE D_, 4
	INSTR 0
	NOTE D_, 3
	LEN 16
	NOTE A_, 2
	INSTR 4
	LEN 8
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE D_, 3
	LEN 8
	NOTE D_, 3
	INSTR 4
	NOTE D_, 4
	INSTR 0
	NOTE D_, 3
	LEN 16
	NOTE A_, 2
	INSTR 4
	LEN 8
	NOTE D_, 4
	INSTR 0
	NOTE F_, 2
	NEXT
Pat_5694:
	REPEAT 2
	LEN 16
	INSTR 0
	NOTE G_, 2
	INSTR 4
	LEN 8
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	NOTE D_, 2
	INSTR 4
	LEN 16
	NOTE G_, 4
	INSTR 0
	LEN 8
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	LEN 16
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	LEN 24
	NOTE D_, 2
	LEN 8
	NOTE D_, 2
	LEN 16
	NOTE F_, 2
	INSTR 4
	LEN 8
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	NOTE C_, 2
	INSTR 4
	LEN 16
	NOTE F_, 4
	INSTR 0
	LEN 8
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 0
	LEN 16
	NOTE F_, 2
	LEN 8
	NOTE F_, 2
	LEN 24
	NOTE C_, 2
	LEN 8
	NOTE F_, 2
	REPEAT_END
	NEXT
Pat_56CA:
	INSTR 0
	LEN 16
	NOTE C_, 3
	LEN 8
	NOTE C_, 3
	LEN 16
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 2
	INSTR 3
	NOTE D_, 4
	LEN 8
	NOTE C_, 4
	NOTE B_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE G_, 3
	INSTR 0
	LEN 16
	NOTE Ash, 2
	LEN 8
	NOTE A_, 2
	LEN 16
	NOTE Ash, 2
	NOTE A_, 2
	NOTE Ash, 2
	NOTE A_, 2
	NOTE Ash, 2
	LEN 24
	NOTE A_, 2
	LEN 16
	NOTE C_, 3
	LEN 8
	NOTE C_, 3
	LEN 16
	NOTE C_, 3
	LEN 8
	NOTE G_, 2
	NOTE E_, 2
	LEN 16
	NOTE C_, 2
	INSTR 3
	NOTE D_, 4
	LEN 8
	NOTE C_, 4
	NOTE B_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE G_, 3
	INSTR 0
	LEN 16
	NOTE Ash, 2
	LEN 8
	NOTE A_, 2
	LEN 16
	NOTE Ash, 2
	NOTE A_, 2
	NOTE Ash, 2
	NOTE A_, 2
	NOTE Ash, 2
	LEN 24
	NOTE D_, 3
	NEXT
Pat_5709:
	INSTR 0
	LEN 16
	NOTE C_, 3
	LEN 8
	NOTE C_, 3
	LEN 16
	NOTE C_, 3
	NOTE G_, 2
	LENGTH $48
	NOTE C_, 2
	LEN 16
	NOTE Ash, 2
	LEN 8
	NOTE Ash, 2
	LEN 16
	NOTE Ash, 2
	NOTE F_, 2
	LENGTH $48
	NOTE Ash, 2
	LEN 16
	NOTE Gsh, 2
	LEN 8
	NOTE Gsh, 2
	LEN 16
	NOTE Gsh, 2
	NOTE Dsh, 2
	LENGTH $48
	NOTE Gsh, 2
	LEN 24
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	LEN 24
	NOTE D_, 2
	LEN 16
	NOTE G_, 2
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	LEN 16
	NOTE A_, 2
	NOTE B_, 2
	NEXT
Pat_5737:
	CH_TRANSPOSE $0C
	DRUMS $08, DrumPat_5971
	LEN 16
	REPEAT 3
	INSTR 2
	NOTE F_, 3
	INSTR 6
	NOTE B_, 3
	INSTR 1
	LEN 8
	NOTE G_, 3
	INSTR 6
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE B_, 3
	INSTR 2
	LEN 16
	NOTE F_, 3
	INSTR 6
	NOTE G_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 6
	NOTE A_, 3
	REPEAT_END
	INSTR 2
	NOTE F_, 3
	INSTR 6
	NOTE C_, 4
	INSTR 1
	LEN 8
	NOTE G_, 3
	INSTR 6
	LEN 16
	NOTE D_, 4
	LEN 8
	NOTE C_, 4
	INSTR 2
	LEN 16
	NOTE F_, 3
	INSTR 6
	NOTE B_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 6
	NOTE A_, 3
	NEXT
Pat_576B:
	LEN 16
	INSTR 2
	NOTE F_, 3
	INSTR 6
	NOTE A_, 3
	INSTR 1
	LEN 8
	NOTE G_, 3
	INSTR 6
	LEN 16
	NOTE B_, 3
	LEN 8
	NOTE A_, 3
	INSTR 2
	LEN 16
	NOTE F_, 3
	INSTR 6
	NOTE E_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 6
	NOTE A_, 3
	REPEAT 2
	INSTR 2
	NOTE F_, 3
	INSTR 6
	NOTE G_, 3
	INSTR 1
	LEN 8
	NOTE G_, 3
	INSTR 6
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE G_, 3
	INSTR 2
	LEN 16
	NOTE F_, 3
	INSTR 6
	NOTE E_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 6
	NOTE G_, 3
	REPEAT_END
	INSTR 2
	NOTE F_, 3
	INSTR 6
	NOTE A_, 3
	INSTR 1
	LEN 8
	NOTE G_, 3
	INSTR 6
	LEN 16
	NOTE B_, 3
	LEN 8
	NOTE A_, 3
	INSTR 2
	LEN 16
	NOTE F_, 3
	INSTR 6
	NOTE Fsh, 3
	INSTR 1
	NOTE G_, 3
	INSTR 6
	NOTE A_, 3
	NEXT
Pat_57AE:
	LEN 16
	REPEAT 2
	INSTR 2
	NOTE F_, 3
	INSTR 6
	NOTE G_, 3
	INSTR 1
	LEN 8
	NOTE G_, 3
	INSTR 6
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE G_, 3
	INSTR 2
	LEN 16
	NOTE F_, 3
	INSTR 6
	NOTE D_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 6
	NOTE G_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 6
	NOTE F_, 3
	INSTR 1
	LEN 8
	NOTE G_, 3
	INSTR 6
	LEN 16
	NOTE G_, 3
	LEN 8
	NOTE F_, 3
	INSTR 2
	LEN 16
	NOTE F_, 3
	INSTR 6
	NOTE C_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 6
	NOTE F_, 3
	REPEAT_END
	NEXT
Pat_57DC:
	DRUMS $08, DrumPat_5985
	INSTR 7
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE C_, 5
	LEN 16
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	INSTR 2
	NOTE F_, 3
	LEN 8
	NOTE F_, 3
	INSTR 1
	LEN 24
	NOTE G_, 3
	LEN 8
	NOTE G_, 3
	INSTR 2
	LEN 16
	NOTE F_, 3
	INSTR 7
	NOTE Ash, 4
	INSTR 1
	NOTE G_, 3
	INSTR 7
	LEN 8
	NOTE Ash, 4
	INSTR 2
	NOTE F_, 3
	LEN 16
	NOTE F_, 3
	INSTR 7
	NOTE Ash, 4
	INSTR 1
	NOTE G_, 3
	INSTR 7
	NOTE Ash, 4
	NOTE C_, 5
	LEN 8
	NOTE C_, 5
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE C_, 5
	NOTE C_, 5
	LEN 16
	NOTE C_, 5
	INSTR 2
	NOTE F_, 3
	LEN 8
	NOTE F_, 3
	INSTR 1
	LEN 24
	NOTE G_, 3
	LEN 8
	NOTE G_, 3
	INSTR 2
	LEN 16
	NOTE F_, 3
	INSTR 7
	NOTE Ash, 4
	INSTR 1
	NOTE G_, 3
	INSTR 7
	LEN 8
	NOTE Ash, 4
	INSTR 2
	NOTE F_, 3
	LEN 16
	NOTE F_, 3
	INSTR 7
	NOTE Ash, 4
	INSTR 1
	NOTE G_, 3
	INSTR 7
	NOTE Ash, 4
	NEXT
Pat_582E:
	DRUMS $08, DrumPat_59C8
	LEN 16
	REPEAT 4
	INSTR 2
	NOTE F_, 3
	INSTR 7
	NOTE C_, 4
	REPEAT_END
	REPEAT 3
	INSTR 2
	NOTE F_, 3
	INSTR 7
	NOTE Ash, 3
	REPEAT_END
	INSTR 2
	NOTE F_, 3
	NOTE F_, 3
	REPEAT 4
	INSTR 2
	NOTE F_, 3
	INSTR 7
	NOTE Gsh, 3
	REPEAT_END
	REPEAT 4
	INSTR 2
	NOTE F_, 3
	INSTR 7
	NOTE G_, 4
	REPEAT_END
	NEXT
Pat_584F:
	HWENV $F2, $10, $60
	DUTY_50
	VIBRATO $10, $01, $04
	LEN 16
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 8
	NOTE A_, 4
	LEN 24
	NOTE C_, 5
	LEN 16
	NOTE B_, 4
	NOTE A_, 4
	NOTE B_, 4
	LENGTH $80
	NOTE D_, 4
	LEN 16
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 8
	NOTE A_, 4
	LEN 24
	NOTE C_, 5
	LEN 16
	NOTE B_, 4
	NOTE A_, 4
	NOTE B_, 4
	LENGTH $68
	NOTE E_, 4
	LEN 8
	NOTE Fsh, 4
	LEN 16
	NOTE G_, 4
	NEXT
Pat_587B:
	LENGTH $40
	NOTE C_, 4
	LEN 24
	NOTE E_, 4
	NOTE Fsh, 4
	LEN 16
	NOTE G_, 4
	LENGTH $40
	NOTE D_, 4
	NOTE E_, 4
	LEN 16
	NOTE G_, 4
	NOTE E_, 4
	NOTE G_, 4
	LEN 8
	NOTE C_, 5
	LEN 24
	NOTE B_, 4
	LEN 16
	NOTE A_, 4
	NOTE G_, 4
	NOTE B_, 4
	LENGTH $30
	NOTE A_, 4
	LEN 8
	NOTE Fsh, 4
	NOTE E_, 4
	LENGTH $40
	NOTE D_, 4
	NEXT
Pat_589D:
	LEN 16
	WAIT
	HWENV $F2, $00
	DUTY_12
	ARP 0
	LEN 8
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	LEN 16
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE G_, 3
	LEN 24
	NOTE Fsh, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE F_, 4
	LEN 16
	NOTE A_, 4
	LEN 32
	NOTE C_, 5
	LEN 8
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	LEN 16
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 24
	NOTE Fsh, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE F_, 5
	LEN 16
	NOTE A_, 5
	NOTE C_, 6
	NEXT
Pat_58CA:
	HWENV $97, $00
	ARP_OFF
	DUTY_75
	VIBRATO $08, $01, $04
	RELEASE $01, $64
	LEN 8
	NOTE D_, 6
	NOTE B_, 5
	NOTE C_, 6
	NOTE D_, 6
	WAIT2
	NOTE C_, 6
	WAIT2
	NOTE B_, 5
	WAIT2
	NOTE G_, 5
	WAIT2
	NOTE A_, 5
	LEN 16
	NOTE B_, 5
	LEN 8
	NOTE D_, 6
	WAIT2
	NOTE C_, 6
	WAIT2
	NOTE A_, 5
	LEN 16
	NOTE B_, 5
	LEN 8
	NOTE C_, 6
	LEN 16
	NOTE F_, 5
	LEN 8
	WAIT2
	NOTE G_, 5
	WAIT2
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE G_, 5
	WAIT2
	NOTE D_, 5
	LEN 16
	NOTE A_, 5
	LEN 8
	NOTE D_, 5
	NOTE G_, 5
	WAIT2
	NOTE D_, 5
	NOTE A_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE G_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE G_, 5
	WAIT2
	NOTE D_, 5
	LEN 16
	NOTE A_, 5
	LEN 8
	NOTE D_, 5
	NOTE G_, 5
	WAIT2
	NOTE C_, 5
	LEN 16
	NOTE F_, 5
	LEN 8
	NOTE G_, 5
	NOTE A_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE D_, 6
	NEXT
Pat_591E:
	LEN 8
	NOTE E_, 6
	NOTE C_, 6
	NOTE A_, 5
	NOTE G_, 5
	WAIT2
	NOTE F_, 5
	WAIT2
	LEN 24
	NOTE E_, 5
	LEN 8
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 16
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	LEN 24
	NOTE G_, 4
	LEN 8
	NOTE E_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	LEN 24
	NOTE E_, 4
	LEN 8
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE Ash, 4
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE Ash, 5
	NEXT
Pat_595E:
	LENGTH $80
	RELEASE $00
	NOTE C_, 6
	NOTE Ash, 3
	NOTE Gsh, 3
	LENGTH $40
	NOTE G_, 3
	HWENV $F2, $10, $60
	DUTY_50
	LEN 32
	NOTE B_, 3
	NOTE C_, 4
	NEXT
DrumPat_5971:
	db DRUM_LEVEL + 14, DRUM_REPEAT + 3, 1, 6, 4, 0, 9, 6
	db 4, 0, DRUM_REPEAT_END, 1, 6, 4, 0, 9
	db 6, 6, 6, DRUM_LOOP
DrumPat_5985:
	db DRUM_LEVEL + 14, 9, 0, 9, 9, 0, 9, 0
	db 9, 0, 1, 0, 1, 9, 0, 4
	db 9, 1, 6, 4, 0, 9, 6, 4
	db 1, 1, 6, 4, 0, 9, 6, 4
	db 0, DRUM_LEVEL + 14, 9, 0, 9, 9, 0, 9
	db 9, 9, 0, 1, 0, 1, 9, 0
	db 4, 9, 1, 6, 4, 0, 9, 6
	db 4, 1, 1, 6, 4, 0, 9, 6
	db 4, 0, DRUM_LOOP
DrumPat_59C8:
	db DRUM_LEVEL + 14, DRUM_REPEAT + 4, 1, 6, 4, 0, DRUM_REPEAT_END, DRUM_REPEAT + 3
	db 1, 6, 4, 0, DRUM_REPEAT_END, 1, 6, 1
	db 4, DRUM_REPEAT + 8, 1, 6, 4, 0, DRUM_REPEAT_END, DRUM_LOOP

; Song 6: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong6:
	call StopAll
	ld a, $61
	ld [wInstrTableHi], a
	ld a, $A5
	ld [wInstrTable], a
	ld de, Song6_Ch1
	call StartMusicCh1
	ld de, Song6_Ch3
	call StartMusicCh3
	ld de, Song6_Ch2
	jp StartMusicCh2

; Unreferenced (1 bytes)
	db $C9
Song6_Ch1:
	dw Pat_5A30
Loop_5A02:
	dw Pat_5A5B
	dw Pat_5A5B
	dw Pat_5A8F
	dw Pat_5ACE
	dw Pat_5B0D
	ORDER_LOOP Loop_5A02
Song6_Ch3:
	dw Pat_5B71
Loop_5A12:
	dw Pat_5B82
	dw Pat_5B8E
	dw Pat_5B82
	dw Pat_5BC5
	dw Pat_5C1D
	ORDER_LOOP Loop_5A12
Song6_Ch2:
	dw Pat_5C8E
Loop_5A22:
	dw Pat_5CB5
	dw Pat_5CB5
	dw Pat_5D00
	dw Pat_5D3F
	dw Pat_5D74
	ORDER_LOOP Loop_5A22
Pat_5A30:
	DRUMS $0B, DrumPat_5DCD
	INSTR 0
	LEN 22
	NOTE C_, 2
	INSTR 4
	LEN 11
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	LEN 22
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 4
	LEN 11
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	LEN 22
	NOTE C_, 2
	INSTR 4
	LEN 11
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	LEN 22
	NOTE C_, 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	NEXT
Pat_5A5B:
	DRUMS $0B, DrumPat_5DBB
	INSTR 0
	LEN 11
	REPEAT 4
	NOTE C_, 2
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 0
	LEN 22
	NOTE C_, 2
	LEN 11
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	REPEAT_END
	REPEAT 2
	NOTE F_, 2
	NOTE F_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 0
	LEN 22
	NOTE F_, 2
	LEN 11
	NOTE F_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE F_, 3
	REPEAT_END
	REPEAT 2
	NOTE C_, 2
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 0
	LEN 22
	NOTE C_, 2
	LEN 11
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	REPEAT_END
	NEXT
Pat_5A8F:
	INSTR 0
	LEN 11
	REPEAT 2
	NOTE F_, 2
	NOTE F_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 0
	LEN 22
	NOTE F_, 2
	LEN 11
	NOTE F_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE F_, 3
	REPEAT_END
	REPEAT 2
	NOTE C_, 2
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 0
	LEN 22
	NOTE C_, 2
	LEN 11
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	REPEAT_END
	REPEAT 2
	NOTE F_, 2
	NOTE F_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 0
	LEN 22
	NOTE F_, 2
	LEN 11
	NOTE F_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE F_, 3
	REPEAT_END
	REPEAT 2
	NOTE C_, 2
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 0
	LEN 22
	NOTE C_, 2
	LEN 11
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	REPEAT_END
	NEXT
Pat_5ACE:
	INSTR 0
	LEN 11
	REPEAT 2
	NOTE F_, 2
	NOTE F_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 0
	LEN 22
	NOTE F_, 2
	LEN 11
	NOTE F_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE F_, 3
	REPEAT_END
	REPEAT 2
	NOTE C_, 2
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 0
	LEN 22
	NOTE C_, 2
	LEN 11
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	REPEAT_END
	REPEAT 2
	NOTE F_, 2
	NOTE F_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 0
	LEN 22
	NOTE F_, 2
	LEN 11
	NOTE F_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE F_, 3
	REPEAT_END
	REPEAT 2
	NOTE G_, 2
	NOTE G_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 0
	LEN 22
	NOTE G_, 2
	LEN 11
	NOTE G_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE G_, 3
	REPEAT_END
	NEXT
Pat_5B0D:
	DRUMS $0B, DrumPat_5DCD
	INSTR 0
	LEN 11
	NOTE C_, 2
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 0
	LEN 22
	NOTE C_, 2
	LEN 11
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 0
	LEN 22
	NOTE F_, 2
	LEN 11
	NOTE F_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE G_, 2
	LEN 22
	NOTE C_, 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	LEN 11
	NOTE C_, 2
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 0
	LEN 22
	NOTE C_, 2
	LEN 11
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 0
	LEN 22
	NOTE F_, 2
	LEN 11
	NOTE F_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE F_, 3
	NOTE C_, 2
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 0
	LEN 22
	NOTE C_, 2
	LEN 11
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	NOTE G_, 2
	NOTE G_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE G_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE G_, 3
	NEXT
Pat_5B71:
	CH_TRANSPOSE $0C
	LEN 22
	REPEAT 4
	INSTR 2
	NOTE F_, 3
	INSTR 1
	LEN 11
	NOTE G_, 3
	INSTR 2
	NOTE F_, 3
	LEN 22
	NOTE F_, 3
	INSTR 1
	NOTE G_, 3
	REPEAT_END
	NEXT
Pat_5B82:
	LEN 22
	REPEAT 8
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE G_, 3
	REPEAT_END
	NEXT
Pat_5B8E:
	REPEAT 4
	INSTR 2
	LEN 11
	NOTE F_, 3
	INSTR 8
	NOTE G_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 8
	NOTE C_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 8
	NOTE G_, 3
	INSTR 1
	LEN 22
	NOTE G_, 3
	REPEAT_END
	REPEAT 2
	INSTR 2
	LEN 11
	NOTE F_, 3
	INSTR 8
	NOTE A_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 8
	NOTE C_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 8
	NOTE A_, 3
	INSTR 1
	LEN 22
	NOTE G_, 3
	REPEAT_END
	REPEAT 2
	INSTR 2
	LEN 11
	NOTE F_, 3
	INSTR 8
	NOTE G_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 8
	NOTE C_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 8
	NOTE G_, 3
	INSTR 1
	LEN 22
	NOTE G_, 3
	REPEAT_END
	NEXT
Pat_5BC5:
	REPEAT 2
	INSTR 2
	LEN 11
	NOTE F_, 3
	INSTR 8
	NOTE A_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 8
	NOTE C_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 8
	NOTE A_, 3
	INSTR 1
	LEN 22
	NOTE G_, 3
	REPEAT_END
	REPEAT 2
	INSTR 2
	LEN 11
	NOTE F_, 3
	INSTR 8
	NOTE G_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 8
	NOTE C_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 8
	NOTE G_, 3
	INSTR 1
	LEN 22
	NOTE G_, 3
	REPEAT_END
	REPEAT 2
	INSTR 2
	LEN 11
	NOTE F_, 3
	INSTR 8
	NOTE A_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 8
	NOTE C_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 8
	NOTE A_, 3
	INSTR 1
	LEN 22
	NOTE G_, 3
	REPEAT_END
	INSTR 2
	LEN 11
	NOTE F_, 3
	INSTR 8
	NOTE B_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 8
	NOTE D_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 8
	NOTE B_, 3
	INSTR 1
	LEN 22
	NOTE G_, 3
	INSTR 2
	LEN 11
	NOTE F_, 3
	INSTR 8
	NOTE B_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 8
	NOTE D_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 8
	NOTE B_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 8
	NOTE D_, 4
	NEXT
Pat_5C1D:
	INSTR 2
	LEN 11
	NOTE F_, 3
	INSTR 8
	NOTE G_, 4
	INSTR 1
	NOTE G_, 3
	INSTR 2
	NOTE F_, 3
	NOTE F_, 3
	INSTR 8
	NOTE G_, 4
	INSTR 1
	NOTE G_, 3
	INSTR 8
	NOTE G_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 8
	NOTE A_, 4
	INSTR 1
	NOTE G_, 3
	INSTR 2
	NOTE F_, 3
	NOTE F_, 3
	INSTR 8
	NOTE A_, 4
	INSTR 1
	NOTE G_, 3
	INSTR 8
	NOTE A_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 8
	NOTE G_, 4
	INSTR 1
	NOTE G_, 3
	INSTR 2
	NOTE F_, 3
	LEN 22
	NOTE F_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 1
	LEN 11
	NOTE G_, 3
	INSTR 2
	NOTE F_, 3
	LEN 22
	NOTE F_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 2
	LEN 11
	NOTE F_, 3
	INSTR 8
	NOTE E_, 5
	INSTR 1
	NOTE G_, 3
	INSTR 2
	NOTE F_, 3
	NOTE F_, 3
	INSTR 8
	NOTE E_, 5
	INSTR 1
	NOTE G_, 3
	INSTR 8
	NOTE E_, 5
	INSTR 2
	NOTE F_, 3
	INSTR 8
	NOTE F_, 5
	INSTR 1
	NOTE G_, 3
	INSTR 2
	NOTE F_, 3
	NOTE F_, 3
	INSTR 8
	NOTE F_, 5
	INSTR 1
	NOTE G_, 3
	INSTR 8
	NOTE F_, 5
	INSTR 2
	NOTE F_, 3
	INSTR 8
	NOTE E_, 5
	INSTR 1
	NOTE G_, 3
	INSTR 2
	NOTE F_, 3
	NOTE F_, 3
	INSTR 8
	NOTE E_, 5
	INSTR 1
	NOTE G_, 3
	INSTR 8
	NOTE E_, 5
	INSTR 2
	NOTE F_, 3
	INSTR 8
	NOTE G_, 5
	INSTR 1
	NOTE G_, 3
	INSTR 2
	NOTE F_, 3
	LEN 22
	NOTE F_, 3
	INSTR 1
	NOTE G_, 3
	NEXT
Pat_5C8E:
	HWENV $F2, $00
	DUTY_75
	ARP 0
	LEN 11
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE G_, 4
	NEXT
Pat_5CB5:
	VIBRATO $0B, $01, $04
	HWENV $F2, $10, $60
	DUTY_50
	ARP_OFF
	LEN 11
	NOTE C_, 5
	NOTE G_, 4
	LEN 22
	NOTE C_, 5
	NOTE D_, 5
	LEN 11
	NOTE C_, 5
	NOTE D_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE E_, 5
	LEN 22
	NOTE C_, 5
	LEN 33
	NOTE G_, 4
	LEN 11
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	LEN 22
	NOTE D_, 5
	LEN 11
	NOTE C_, 5
	NOTE D_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE C_, 5
	LENGTH $37
	NOTE G_, 5
	HWENV $90, $00
	ARP 23
	LEN 11
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE B_, 4
	LEN 33
	NOTE G_, 4
	NOTE G_, 4
	LEN 11
	NOTE E_, 4
	NOTE F_, 4
	LEN 33
	NOTE G_, 4
	LENGTH $37
	NOTE G_, 4
	NEXT
Pat_5D00:
	LEN 11
	WAIT
	HWENV $F2, $10, $67
	VIBRATO $0B, $02, $04
	RELEASE $02, $43
	ARP 20
	NOTE A_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 33
	NOTE G_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE B_, 3
	LEN 22
	NOTE C_, 4
	LEN 33
	NOTE G_, 3
	LEN 11
	NOTE A_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 33
	NOTE G_, 4
	NOTE C_, 5
	NOTE D_, 4
	NOTE G_, 4
	LEN 22
	NOTE C_, 4
	NOTE E_, 4
	NEXT
Pat_5D3F:
	LEN 11
	WAIT
	NOTE A_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE A_, 5
	NOTE G_, 5
	LEN 33
	NOTE G_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE B_, 4
	LEN 22
	NOTE C_, 5
	LEN 33
	NOTE G_, 4
	LEN 11
	NOTE A_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE A_, 5
	NOTE G_, 5
	LEN 33
	NOTE G_, 5
	NOTE D_, 5
	NOTE B_, 4
	NOTE G_, 5
	LEN 22
	NOTE A_, 5
	NOTE B_, 5
	RELEASE $00
	NEXT
Pat_5D74:
	HWENV $F2, $00
	DUTY_75
	ARP 0
	LEN 11
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE B_, 5
	NEXT
DrumPat_5DBB:
	db DRUM_LEVEL + 14, 1, 6, 9, 6, 1, 6, 9
	db 6, 1, 6, 9, 6, 1, 6, 9
	db 4, DRUM_LOOP
DrumPat_5DCD:
	db DRUM_LEVEL + 14, 1, 6, 9, 1, 1, 6, 9
	db 6, 1, 6, 9, 1, 1, 6, 9
	db 4, DRUM_LOOP

; Song 7: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong7:
	call StopAll
	ld a, $61
	ld [wInstrTableHi], a
	ld a, $A5
	ld [wInstrTable], a
	ld de, Song7_Ch1
	call StartMusicCh1
	ld de, Song7_Ch3
	call StartMusicCh3
	ld de, Song7_Ch2
	jp StartMusicCh2
Song7_Ch1:
	dw Pat_5E10

; Unreferenced (4 bytes)
	db $00, $00, $FE, $5D
Song7_Ch3:
	dw Pat_5E56

; Unreferenced (4 bytes)
	db $00, $00, $04, $5E
Song7_Ch2:
	dw Pat_5E93

; Unreferenced (4 bytes)
	db $00, $00, $0A, $5E
Pat_5E10:
	DRUMS $06, DrumPat_5EC4
	INSTR 0
	LEN 12
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
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 4
	NOTE F_, 4
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
	NOTE C_, 2
	WAIT2
	DRUMS_OFF
	END
Pat_5E56:
	VOLENV 15, $11, $11, $11
	RELEASE $02, $51
	CH_TRANSPOSE $0C
	VIBRATO $0A, $01, $01
	WAVE Wave_667D
	LEN 24
	NOTE E_, 5
	LEN 12
	NOTE C_, 5
	NOTE E_, 5
	LEN 24
	NOTE F_, 5
	LEN 12
	NOTE D_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE E_, 5
	LEN 24
	NOTE D_, 5
	LEN 12
	NOTE G_, 5
	NOTE F_, 5
	LEN 24
	NOTE E_, 5
	LEN 12
	NOTE C_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE F_, 5
	LEN 6
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE A_, 5
	LEN 12
	NOTE B_, 5
	NOTE G_, 5
	NOTE C_, 6
	LEN 6
	NOTE C_, 6
	NOTE B_, 5
	LEN 12
	VIB_OFF
	NOTE C_, 6
	REST
	END
Pat_5E93:
	HWENV $F1, $00
	ARP 0
	DUTY_75
	LEN 12
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	LEN 6
	NOTE F_, 4
	NOTE E_, 4
	LEN 12
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE A_, 4
	LEN 6
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 12
	NOTE B_, 4
	NOTE G_, 4
	NOTE C_, 5
	LEN 6
	NOTE C_, 5
	NOTE B_, 4
	LEN 12
	NOTE C_, 5
	WAIT2
	END
DrumPat_5EC4:
	db DRUM_REPEAT + 3, 1, 0, 6, 0, 9, 0, 6
	db 0, DRUM_REPEAT_END, 1, 0, 6, 0, 9, 0
	db 1, 0, DRUM_REPEAT + 3, 1, 0, 6, 0, 9
	db 0, 6, 0, DRUM_REPEAT_END, 9, 0, 9, 9
	db 9, 0, 0, 0, DRUM_LOOP

; Song 8: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong8:
	call StopAll
	ld a, $61
	ld [wInstrTableHi], a
	ld a, $A5
	ld [wInstrTable], a
	ld de, Song8_Ch1
	call StartMusicCh1
	ld de, Song8_Ch3
	call StartMusicCh3
	ld de, Song8_Ch2
	jp StartMusicCh2
Song8_Ch1:
	dw Pat_5F1A

; Unreferenced (4 bytes)
	db $00, $00, $08, $5F
Song8_Ch3:
	dw Pat_5F3B

; Unreferenced (4 bytes)
	db $00, $00, $0E, $5F
Song8_Ch2:
	dw Pat_5F5B

; Unreferenced (4 bytes)
	db $00, $00, $14, $5F
Pat_5F1A:
	DRUMS $07, DrumPat_5F73
	INSTR 0
	LEN 14
	NOTE G_, 2
	INSTR 5
	NOTE G_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 5
	NOTE G_, 4
	INSTR 0
	NOTE Ash, 2
	INSTR 5
	NOTE G_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 5
	NOTE G_, 4
	INSTR 0
	NOTE Dsh, 3
	NOTE D_, 3
	NOTE Csh, 3
	NOTE D_, 3
	LEN 9
	NOTE D_, 2
	DRUMS_OFF
	LENGTH $8C
	WAIT
	END
Pat_5F3B:
	CH_TRANSPOSE $0C
	INSTR 2
	LEN 14
	NOTE F_, 3
	INSTR 8
	NOTE G_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 8
	NOTE A_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 8
	NOTE Ash, 3
	INSTR 1
	NOTE A_, 3
	INSTR 8
	NOTE C_, 4
	ARP 6
	VOLENV 15, $11, $1F, $12
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	LENGTH $8C
	NOTE D_, 4
	END
Pat_5F5B:
	HWENV $F2, $10, $87
	VIBRATO $0E, $01, $04
	ARP 0
	DUTY_75
	LEN 28
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Csh, 4
	NOTE D_, 4
	LENGTH $8C
	NOTE D_, 3
	END
DrumPat_5F73:
	db 1, 0, 5, 6, 9, 0, 5, 6
	db 1, 0, 5, 6, 9, 0, 5, 6
	db 9, 0, 9, 0, 9, 0, 9, 0
	db 9, 0, DRUM_LOOP
Pat_5F8E:
	TRANSPOSE $00
	NEXT
Pat_5F91:
	TRANSPOSE $01
	NEXT

; Unreferenced (3 bytes)
	db $69, $02, $6A

; Song 1: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong1:
	call StopAll
	ld a, $61
	ld [wInstrTableHi], a
	ld a, $A5
	ld [wInstrTable], a
	ld de, Song1_Ch3
	call StartMusicCh3
	ld de, Song1_Ch2
	call StartMusicCh2
	ld de, Song1_Ch1
	jp StartMusicCh1

; Unreferenced (1 bytes)
	db $6A
Song1_Ch3:
	dw Pat_5FDB
	dw Pat_6017
	dw Pat_6043
	dw Pat_6074
	ORDER_LOOP Song1_Ch3
Song1_Ch2:
	dw Pat_60A7
	dw Pat_60D2
	dw Pat_60EF
	dw Pat_6111
	ORDER_LOOP Song1_Ch2
Song1_Ch1:
	dw Pat_6131
	dw Pat_615A
	dw Pat_6175
	dw Pat_6190
	ORDER_LOOP Song1_Ch1
Pat_5FDB:
	CH_TRANSPOSE $0C
	INSTR 9
	LEN 32
	NOTE F_, 2
	INSTR 10
	LEN 16
	NOTE F_, 3
	INSTR 9
	NOTE F_, 2
	LEN 32
	NOTE G_, 2
	INSTR 10
	LEN 16
	NOTE G_, 3
	INSTR 9
	NOTE G_, 2
	LEN 32
	NOTE F_, 2
	INSTR 10
	LEN 16
	NOTE F_, 3
	INSTR 9
	NOTE F_, 2
	LEN 32
	NOTE F_, 2
	INSTR 10
	LEN 16
	NOTE F_, 3
	INSTR 9
	NOTE F_, 2
	LEN 32
	NOTE F_, 2
	INSTR 10
	LEN 16
	NOTE F_, 3
	INSTR 9
	NOTE F_, 2
	LEN 32
	NOTE G_, 2
	INSTR 10
	LEN 16
	NOTE G_, 3
	INSTR 9
	NOTE G_, 2
	LEN 32
	NOTE F_, 2
	INSTR 10
	LEN 16
	NOTE F_, 3
	INSTR 9
	NOTE F_, 2
	LEN 32
	NOTE F_, 2
	INSTR 10
	LEN 16
	NOTE F_, 3
	INSTR 9
	NOTE F_, 2
	NEXT
Pat_6017:
	INSTR 9
	LEN 32
	NOTE F_, 2
	INSTR 10
	LEN 16
	NOTE F_, 3
	INSTR 9
	NOTE F_, 2
	LEN 32
	NOTE G_, 2
	INSTR 10
	LEN 16
	NOTE G_, 3
	INSTR 9
	NOTE A_, 2
	LEN 32
	NOTE Ash, 2
	INSTR 10
	LEN 16
	NOTE Ash, 3
	INSTR 9
	NOTE Ash, 2
	LEN 32
	NOTE C_, 3
	INSTR 10
	LEN 16
	NOTE C_, 4
	INSTR 9
	NOTE C_, 3
	LEN 32
	NOTE D_, 3
	INSTR 10
	LEN 16
	NOTE D_, 4
	INSTR 9
	NOTE D_, 3
	LEN 32
	NOTE A_, 2
	NOTE A_, 2
	LENGTH $40
	NOTE D_, 2
	WAIT2
	NEXT
Pat_6043:
	INSTR 9
	LEN 32
	NOTE G_, 2
	INSTR 11
	LEN 16
	NOTE G_, 3
	INSTR 9
	NOTE G_, 2
	LEN 32
	NOTE G_, 2
	INSTR 11
	NOTE G_, 3
	INSTR 9
	NOTE C_, 2
	INSTR 10
	LEN 16
	NOTE C_, 4
	INSTR 9
	NOTE C_, 2
	LEN 32
	NOTE C_, 2
	INSTR 10
	NOTE C_, 4
	INSTR 9
	NOTE F_, 2
	INSTR 10
	LEN 16
	NOTE F_, 3
	INSTR 9
	NOTE F_, 2
	LEN 32
	NOTE F_, 2
	INSTR 10
	NOTE F_, 3
	INSTR 9
	NOTE Dsh, 2
	INSTR 10
	LEN 16
	NOTE Ash, 3
	INSTR 9
	NOTE Dsh, 2
	LEN 32
	NOTE Dsh, 2
	INSTR 10
	LEN 16
	NOTE Ash, 3
	INSTR 9
	NOTE F_, 2
	NEXT
Pat_6074:
	INSTR 9
	LEN 32
	NOTE Ash, 2
	INSTR 10
	LEN 16
	NOTE Ash, 3
	INSTR 9
	NOTE Ash, 2
	LEN 32
	NOTE Ash, 2
	INSTR 10
	LEN 16
	NOTE Ash, 3
	INSTR 9
	NOTE C_, 3
	LEN 32
	NOTE Csh, 3
	INSTR 10
	LEN 16
	NOTE Csh, 4
	INSTR 9
	NOTE Csh, 3
	LEN 32
	NOTE Dsh, 3
	INSTR 10
	LEN 16
	NOTE Dsh, 4
	INSTR 9
	NOTE Dsh, 3
	LEN 32
	NOTE F_, 3
	INSTR 10
	LEN 16
	NOTE F_, 4
	INSTR 9
	NOTE F_, 3
	LEN 32
	NOTE F_, 3
	NOTE C_, 3
	NOTE F_, 2
	INSTR 10
	LEN 16
	NOTE F_, 3
	INSTR 9
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 2
	INSTR 10
	NOTE F_, 3
	NOTE F_, 4
	NEXT
Pat_60A7:
	HWENV $F2, $10, $60
	DUTY_50
	VIBRATO $10, $01, $04
	RELEASE $02, $63
	LEN 32
	NOTE C_, 4
	NOTE A_, 3
	NOTE D_, 4
	LENGTH $30
	NOTE B_, 3
	LEN 16
	NOTE C_, 4
	NOTE A_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE E_, 3
	NOTE F_, 3
	LEN 32
	NOTE C_, 4
	NOTE A_, 3
	NOTE D_, 4
	LENGTH $30
	NOTE B_, 3
	LEN 16
	NOTE C_, 4
	NOTE A_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE E_, 3
	NOTE F_, 3
	NEXT
Pat_60D2:
	LEN 32
	NOTE C_, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE B_, 3
	LEN 16
	NOTE F_, 4
	NOTE D_, 4
	NOTE Ash, 3
	LEN 32
	NOTE G_, 3
	LEN 16
	NOTE C_, 4
	LEN 32
	NOTE E_, 4
	NOTE D_, 4
	LEN 16
	NOTE A_, 3
	LEN 32
	NOTE G_, 3
	LEN 16
	NOTE A_, 3
	LEN 32
	NOTE D_, 4
	LENGTH $40
	NOTE Fsh, 3
	WAIT2
	NEXT
Pat_60EF:
	LENGTH $30
	WAIT
	LEN 16
	NOTE G_, 4
	LENGTH $30
	NOTE Ash, 4
	LEN 8
	NOTE C_, 5
	NOTE D_, 5
	LEN 32
	NOTE C_, 5
	LEN 16
	NOTE Ash, 4
	LEN 32
	NOTE Ash, 4
	NOTE A_, 4
	LENGTH $30
	NOTE A_, 4
	LEN 16
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 32
	NOTE Dsh, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE A_, 4
	NEXT
Pat_6111:
	LENGTH $70
	NOTE F_, 4
	LEN 16
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	LEN 32
	NOTE G_, 4
	LEN 16
	NOTE Dsh, 4
	NOTE C_, 4
	LENGTH $30
	NOTE F_, 4
	LEN 16
	NOTE C_, 4
	LEN 32
	NOTE Ash, 3
	LEN 16
	NOTE C_, 4
	LEN 32
	NOTE F_, 4
	LENGTH $50
	NOTE F_, 3
	LEN 16
	NOTE A_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NEXT
Pat_6131:
	DRUMS $08, DrumPat_621F
	HWENV $F2, $10, $60
	DUTY_50
	VIBRATO $10, $01, $04
	RELEASE $02, $63
	LEN 16
	NOTE F_, 5
	NOTE A_, 5
	NOTE C_, 6
	LEN 32
	NOTE B_, 5
	LEN 16
	NOTE G_, 5
	NOTE B_, 5
	LENGTH $90
	NOTE A_, 5
	LEN 16
	NOTE F_, 5
	NOTE A_, 5
	NOTE C_, 6
	LEN 32
	NOTE B_, 5
	LEN 16
	NOTE G_, 5
	NOTE D_, 6
	LENGTH $90
	NOTE A_, 5
	NEXT
Pat_615A:
	LEN 16
	NOTE F_, 5
	NOTE A_, 5
	NOTE C_, 6
	LEN 32
	NOTE B_, 5
	NOTE G_, 5
	LEN 16
	NOTE A_, 5
	NOTE Ash, 5
	NOTE D_, 6
	NOTE F_, 6
	LEN 32
	NOTE E_, 6
	LEN 16
	NOTE C_, 6
	NOTE G_, 5
	NOTE C_, 6
	LENGTH $C0
	NOTE D_, 6
	LEN 16
	WAIT2
	NOTE Fsh, 3
	NOTE G_, 3
	NOTE A_, 3
	NEXT
Pat_6175:
	LEN 16
	NOTE Ash, 3
	NOTE G_, 3
	LENGTH $50
	NOTE D_, 4
	LEN 8
	NOTE E_, 4
	NOTE F_, 4
	LEN 32
	NOTE E_, 4
	LEN 16
	NOTE D_, 4
	LEN 32
	NOTE C_, 4
	NOTE E_, 4
	LENGTH $80
	NOTE A_, 3
	LEN 16
	NOTE Ash, 3
	LEN 32
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE A_, 3
	NEXT
Pat_6190:
	LENGTH $70
	NOTE F_, 3
	LEN 16
	NOTE G_, 3
	LENGTH $40
	NOTE Gsh, 3
	NOTE Ash, 3
	LENGTH $60
	NOTE C_, 4
	LEN 32
	NOTE G_, 3
	LENGTH $40
	NOTE A_, 3
	LEN 16
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NEXT

; Instrument table 1, entries 1..12 (the song routines point 2 bytes before:
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
Instr1_0:
	HWENV $F2, $08, $77
	ARP 0
	END
Instr1_1:
	VOLENV 15, $11, $1F, $11
	ARP 18
	WAVE Wave_66CD
	END
Instr1_2:
	VOLENV 15, $14, $2F, $11
	ARP 18
	GLIDE $FE
	WAVE Wave_66CD
	END
Instr1_3:
	HWENV $F1, $00
	GLIDE $FF
	DUTY_50
	END
Instr1_4:
	HWENV $C1, $00
	ARP 6
	END
Instr1_5:
	HWENV $C1, $00
	ARP 5
	END
Instr1_6:
	VOLENV 15, $11, $2F, $11
	WAVE Wave_66ED
	END
Instr1_7:
	VOLENV 15, $11, $1A, $11
	ARP 6
	WAVE Wave_666D
	END
Instr1_8:
	VOLENV 15, $11, $1F, $11
	ARP 0
	WAVE Wave_666D
	END
Instr1_9:
	VOLENV 15, $11, $1F, $14
	ARP 0
	WAVE Wave_667D
	END
Instr1_10:
	VOLENV 15, $12, $1A, $11
	ARP 6
	WAVE Wave_669D
	END
Instr1_11:
	VOLENV 15, $12, $1A, $11
	ARP 5
	WAVE Wave_669D
	END
DrumPat_621F:
	db DRUM_LEVEL + 14, 1, 0, 6, 0, 9, 0, 1
	db 0, DRUM_LOOP

; Instrument table 2, entries 1..15 (the song routines point 2 bytes before:
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
	dw Instr2_9
	dw Instr2_10
	dw Instr2_11
	dw Instr2_12
	dw Instr2_13
	dw Instr2_14
Instr2_0:
	HWENV $F3, $00
	DUTY_75
	END
Instr2_1:
	VOLENV 15, $12, $1F, $11
	GLIDE $FF
	WAVE Wave_66BD
	END
Instr2_2:
	VOLENV 15, $14, $2F, $11
	GLIDE $FE
	WAVE Wave_66BD
	END
Instr2_3:
	VOLENV 14, $11, $1F, $11
	ARP 5
	WAVE Wave_671D
	END
Instr2_4:
	VOLENV 14, $11, $1F, $11
	ARP 6
	WAVE Wave_671D
	END
Instr2_5:
	HWENV $F1, $00
	ARP 0
	DUTY_75
	END
Instr2_6:
	HWENV $F1, $00
	ARP 23
	DUTY_12
	END
Instr2_7:
	END
Instr2_8:
	HWENV $A1, $00
	ARP 0
	DUTY_12
	END
Instr2_9:
	END
Instr2_10:
	END
Instr2_11:
	VOLENV 15, $11, $1F, $14
	ARP 0
	WAVE Wave_66CD
	END
Instr2_12:
	HWENV $E1, $00
	ARP 6
	AUTODUTY $03
	END
Instr2_13:
	HWENV $E1, $00
	ARP 5
	AUTODUTY $03
	END
Instr2_14:
	HWENV $F2, $0C, $60
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
	dw Arp13
	dw Arp13
	dw Arp16
	dw Arp17
	dw Arp18
	dw Arp19
	dw Arp19
	dw Arp21
	dw Arp21
	dw Arp21

; Unreferenced (8 bytes)
	db $8C, $63, $8C, $63, $8C, $63, $8C, $63
Arp0:
	db $0C, $00, ARP_HOLD
Arp3:
	db $00, $00, $01, $01, $02, ARP_HOLD
Arp2:
	db $00, $00, $04, $04, $07, $07, ARP_LOOP
Arp1:
	db $0C, $00, $00, $00, $00, $00, $00, $18
	db $0C, $0C, $0C, $0C, $0C, $0C, ARP_LOOP
Arp4:
	db $00, $03, $08, ARP_LOOP
Arp5:
	db $00, $03, $07, ARP_LOOP
Arp6:
	db $00, $04, $07, ARP_LOOP
Arp7:
	db $00, $01, $02, ARP_HOLD
Arp8:
	db $0C, $00, $00, $00, $00, $00, $00, $18
	db $0C, $0C, $0C, $0C, $0C, $0C, $0C, ARP_HOLD
Arp9:
	db $0C, $0C, $00, ARP_HOLD
Arp10:
	db $00, $01, ARP_HOLD
Arp11:
	db $0C, $00, $00, $00, $00, $00, $00, $0C
	db $0C, $0C, $0C, $0C, $0C, $0C, ARP_HOLD
Arp12:
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
Arp19:
	db $0C, $00, $00, ARP_LOOP
Arp21:
	db $18, $0C, $00, ARP_HOLD

; Unreferenced (63 bytes)
	db $12, $00, $00, $00, $00, $00, $00, $00, $00, $0C, $00, $00, $00, $00, $00, $00
	db $00, $00, $06, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $6A, $CA, $63, $CA, $63, $CA, $63, $CA, $63, $CA, $63, $CA, $63, $CA, $63
	db $CA, $63, $CA, $63, $CA, $63, $CA, $63, $CA, $63, $CA, $63, $CA
SfxTable_m2:
	db $63, $68

; SFX table (indexed from 2 bytes before: id 1 is the first entry)
SfxTable:
	dw Sfx01
	dw SfxTable+2
	dw SfxTable+4
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

; Sound effect 16
Sfx16:
	VOLENV 2, $5A, $1F, $11
	RELEASE $03, $51
	WAVE Wave_670D
	LEN 15
	GLIDE $01
	NOTE C_, 6
	LEN 15
	NOTE B_, 5
	LEN 14
	NOTE Ash, 5
	LEN 13
	NOTE A_, 5
	LEN 12
	NOTE Gsh, 5
	RELEASE $00
	WAIT
	END

; Sound effect 6
Sfx06:
	LEN 10
	VOLENV 15, $11, $1F, $11
	GLIDE $01
	WAVE Wave_668D
	NOTE Ash, 3
	END

; Sound effect 4
Sfx04:
	VOLENV 15, $11, $2F, $11
	WAVE Wave_669D
	LEN 13
	NOTE C_, 6
	END

; Sound effect 5
Sfx05:
	LEN 4
	VOLENV 15, $11, $2F, $11
	WAVE Wave_669D
	LEN 4
	NOTE Gsh, 5
	LEN 1
	REST
	LEN 4
	NOTE Gsh, 6
	END

; Sound effect 1
Sfx01:
	LEN 5
	ARP 0
	WAVE Wave_66DD
	VOLENV 15, $10, $1F, $12
	RELEASE $02, $55
	NOTE C_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	END

; Sound effect 10
Sfx10:
	CALL_CODE Code_658A
	VOLENV 10, $11, $1F, $11
	WAVE Wave_668D
	LEN 10
	ARP 5
	GLIDE $01
	NOTE A_, 3
	END

; Sound effect 13
Sfx13:
	VOLENV 15, $11, $1F, $12
	WAVE Wave_668D
	LEN 3
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE E_, 6
	NOTE G_, 6
	NOTE C_, 7
	NOTE E_, 7
	NOTE G_, 7
	LEN 30
	NOTE C_, 8
	END

; Sound effect 14
Sfx14:
	CALL_CODE Code_652A
	VOLENV 15, $11, $1F, $14
	WAVE Wave_66CD
	LEN 6
	GLIDE $02
	NOTE Csh, 6
	GLIDE_OFF
	VIBRATO $00, $01, $01
	LEN 30
	NOTE Csh, 7
	WAIT
	END

; Sound effect 15
Sfx15:
	VOLENV 10, $00, $00, $00
	GLIDE $FC
	WAVE Wave_66CD
	CALL_CODE Code_65D3
	LEN 5
	NOTE A_, 6
	END

; Sound effect 12
Sfx12:
	LEN 2
	VOLENV 15, $11, $1F, $11
	WAVE Wave_668D
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

; Sound effect 7
Sfx07:
	VOLENV 15, $11, $1F, $12
	ARP 0
	WAVE Wave_668D
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

; Sound effect 11
Sfx11:
	VOLENV 15, $11, $1F, $11
	CALL_CODE Code_660F
	WAVE Wave_668D
	LEN 12
	GLIDE $FE
	NOTE A_, 3
	END

; Sound effect 8
Sfx08:
	VOLENV 10, $11, $1F, $14
	WAVE Wave_668D
	LEN 33
	VIBRATO $01, $03, $01
	NOTE A_, 5
	END

; Sound effect 9
Sfx09:
	CALL_CODE Code_6640
	VOLENV 15, $00, $00, $00
	WAVE Wave_672D
	LEN 3
	GLIDE $FF
	NOTE Csh, 6
	WAVE Wave_66FD
	WAIT
	WAVE Wave_671D
	WAIT
	END

; Sound effect 2 (noise only; started by the game's glue, sets wDrumHold)
Sfx02_Noise:
	ld a, $0A
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6513)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6513)
	ld [wNoise43], a
	ld a, HIGH(Noise42_651F)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_651F)
	ld [wNoise42], a
	ret
Noise43_6513:
	db $80, $B0, $80, $90, $A0, $80, $B0, $90
	db $A0, $A0, $B0, $FF
Noise42_651F:
	db $F0, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $00
Code_652A:
	ld a, $28
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_654C)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_654C)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6557)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6557)
	ld [wNoise42], a
	ret
Noise43_654C:
	db $57, $46, $45, $44, $43, $42, $41, $40
	db $20, $20, $FF
Noise42_6557:
	db $19, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $F3

; Sound effect 3 (noise only; started by the game's glue, sets wDrumHold)
Sfx03_Noise:
	ld a, $08
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6583)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6583)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6587)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6587)
	ld [wNoise42], a
	ret
Noise43_6583:
	db $00, $43, $45, $FF
Noise42_6587:
	db $F1, $FF, $00
Code_658A:
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
	ld a, HIGH(Noise43_65B7)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_65B7)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_65B7:
	db $12, $64, $02, $37, $47, $24, $55, $71
	db $07, $44, $60, $36, $84, $82, $64, $02
	db $37, $47, $24, $55, $71, $07, $44, $60
	db $36, $86, $32, $FF
Code_65D3:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_65F5)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_65F5)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6602)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6602)
	ld [wNoise42], a
	ret
Noise43_65F5:
	db $10, $10, $20, $31, $32, $33, $33, $34
	db $34, $35, $35, $36, $FF
Noise42_6602:
	db $5C, $FF, $FF, $FF, $FF, $FF, $A1, $FF
	db $FF, $FF, $FF, $FF

; Unreferenced (1 bytes)
	db $FF
Code_660F:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6631)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6631)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6639)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6639)
	ld [wNoise42], a
	ret
Noise43_6631:
	db $02, $51, $61, $71, $91, $71, $34, $FF
Noise42_6639:
	db $F0, $F0, $F0, $F0, $F0, $70, $92
Code_6640:
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6662)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6662)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6668)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6668)
	ld [wNoise42], a
	ret
Noise43_6662:
	db $00, $53, $71, $91, $31, $FF
Noise42_6668:
	db $F1, $FF, $FF, $FF, $00
Wave_666D:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $44, $44, $44, $77, $77, $44, $44, $44
Wave_667D:
	db $8C, $FE, $ED, $B8, $53, $21, $10, $24
	db $84, $01, $12, $35, $8B, $DE, $EF, $8C
Wave_668D:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
Wave_669D:
	db $00, $00, $00, $00, $CD, $EF, $FD, $EC
	db $00, $12, $21, $00, $DD, $DD, $DD, $DD

; Unreferenced (16 bytes)
	db $00, $00, $00, $00, $00, $00, $FF, $FF, $00, $00, $00, $00, $00, $00, $FF, $FF
Wave_66BD:
	db $FF, $FE, $ED, $B8, $53, $21, $10, $00
	db $00, $01, $12, $35, $8B, $DE, $EF, $FF
Wave_66CD:
	db $63, $10, $00, $00, $00, $00, $01, $36
	db $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9
Wave_66DD:
	db $63, $10, $01, $47, $74, $10, $01, $36
	db $9C, $EF, $FE, $B8, $8B, $EF, $FE, $C9
Wave_66ED:
	db $63, $1F, $01, $47, $74, $10, $01, $36
	db $9C, $E0, $FE, $B8, $8B, $EF, $FE, $C9
Wave_66FD:
	db $04, $8B, $DE, $FF, $ED, $CB, $A9, $87
	db $65, $44, $44, $32, $11, $24, $7A, $74
Wave_670D:
	db $20, $13, $69, $BD, $FD, $B9, $64, $20
	db $13, $68, $B8, $64, $20, $24, $68, $64
Wave_671D:
	db $20, $24, $68, $AC, $EC, $A8, $64, $20
	db $24, $68, $A8, $64, $20, $24, $68, $64
Wave_672D:
	db $02, $48, $AC, $FF, $FC, $53, $00, $27
	db $9C, $DD, $DC, $B7, $7B, $CD, $DD, $C9
Noise43_673D:
	db $50, $41, $50, $51, $42, $53, $51, $FF
Noise42_6745:
	db $D0, $70, $90, $60, $C0, $50, $61
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6769)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6769)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6771)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6771)
	ld [wNoise42], a
	ret
Noise43_6769:
	db $01, $61, $71, $A1, $B1, $B1, $A1, $FF
Noise42_6771:
	db $C1, $F0, $A0, $90, $70, $40, $33
Drum8:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6795)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6795)
	ld [wNoise43], a
	ld a, HIGH(Noise42_679D)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_679D)
	ld [wNoise42], a
	ret
Noise43_6795:
	db $60, $52, $42, $41, $22, $11, $04, $FF
Noise42_679D:
	db $F0, $F0, $F0, $A0, $70, $40, $51
Drum3:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_673D)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_673D)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6745)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6745)
	ld [wNoise42], a
	ret
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_67DE)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_67DE)
	ld [wNoise43], a
	ld a, HIGH(Noise42_67E6)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_67E6)
	ld [wNoise42], a
	ret
Noise43_67DE:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_67E6:
	db $70, $FF, $FF, $FF, $FF, $54, $FF
Drum5:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_680A)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_680A)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6812)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6812)
	ld [wNoise42], a
	ret
Noise43_680A:
	db $02, $00, $00, $00, $00, $00, $00, $FF
Noise42_6812:
	db $90, $52, $FF, $FF, $FF, $FF, $FF
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6836)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6836)
	ld [wNoise43], a
	ld a, HIGH(Noise42_683E)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_683E)
	ld [wNoise42], a
	ret
Noise43_6836:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_683E:
	db $60, $30, $32, $FF, $FF, $FF, $FF
Drum7:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6862)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6862)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6868)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6868)
	ld [wNoise42], a
	ret
Noise43_6862:
	db $06, $04, $03, $03, $07, $FF
Noise42_6868:
	db $F0, $C0, $80, $60, $55
Drum9:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_688A)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_688A)
	ld [wNoise43], a
	ld a, HIGH(Noise42_688D)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_688D)
	ld [wNoise42], a
	ret
Noise43_688A:
	db $51, $32, $FF
Noise42_688D:
	db $F0, $62
Drum10:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_68C9)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_68C9)
	ld [wNoise43], a
	ld a, HIGH(Noise42_68CC)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_68CC)
	ld [wNoise42], a
	ret
Drum11:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_68CE)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_68CE)
	ld [wNoise43], a
	ld a, HIGH(Noise42_68D6)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_68D6)
	ld [wNoise42], a
	ret
Noise43_68C9:
	db $51, $32, $FF
Noise42_68CC:
	db $70, $52
Noise43_68CE:
	db $51, $32, $32, $32, $32, $51, $32, $FF
Noise42_68D6:
	db $70, $51, $FF, $FF, $FF, $70, $51
FadeOutTable:
	db $77, $66, $55, $44, $33, $22, $11, $00
	db FADE_END
FadeInTable:
	db $00, $11, $22, $33, $44, $55, $66, $77
	db FADE_END

; Unreferenced (5905 bytes)
	db $00, $5A, $59, $E0, $00, $00, $3C, $3C, $66, $42, $42, $66, $24, $A0, $3C, $02
	db $03, $68, $48, $D0, $A6, $90, $02, $06, $34, $10, $0F, $03, $E6, $FE, $19, $F2
	db $82, $FE, $FE, $E3, $20, $10, $8C, $22, $1A, $06, $DB, $E7, $FD, $81, $E7, $FF
	db $20, $0E, $7E, $66, $7A, $42, $6E, $7E, $7E, $20, $62, $FB, $C3, $18, $16, $5A
	db $66, $72, $42, $04, $30, $20, $2A, $F9, $81, $6E, $FF, $FF, $20, $05, $12, $1E
	db $16, $1A, $0D, $0B, $02, $00, $06, $1C, $14, $34, $2C, $58, $68, $3D, $BF, $CF
	db $F3, $20, $0D, $8F, $60, $98, $02, $0C, $FF, $55, $6A, $20, $4C, $20, $62, $02
	db $52, $7B, $66, $7E, $70, $0E, $1B, $10, $04, $7D, $36, $30, $70, $20, $0A, $1E
	db $12, $66, $0F, $09, $75, $0F, $79, $7D, $41, $7F, $7F, $E0, $00, $01, $02, $00
	db $00, $00, $00, $00, $00, $03, $00, $00, $04, $00, $00, $05, $06, $07, $6F, $70
	db $71, $72, $73, $0A, $0B, $0C, $0D, $0E, $0F, $10, $11, $12, $74, $75, $76, $77
	db $78, $16, $79, $7A, $1A, $1B, $1C, $1D, $1E, $1F, $7B, $7C, $7D, $7E, $7F, $23
	db $80, $25, $26, $27, $28, $29, $2A, $2B, $81, $82, $83, $84, $85, $2F, $86, $87
	db $33, $34, $35, $36, $37, $38, $88, $89, $8A, $8B, $8C, $3C, $8D, $8E, $8F, $90
	db $42, $43, $44, $45, $91, $92, $93, $94, $95, $96, $97, $98, $99, $9A, $50, $51
	db $52, $9B, $9C, $9D, $9E, $9F, $A0, $57, $A1, $A2, $A3, $5B, $5C, $5D, $A4, $A5
	db $A6, $A7, $A8, $A9, $AA, $62, $AB, $AC, $AD, $5E, $66, $69, $AE, $AF, $B0, $B1
	db $B2, $B3, $B4, $B5, $B6, $B7, $B8, $67, $68, $01, $02, $03, $04, $04, $04, $04
	db $01, $02, $03, $05, $06, $07, $04, $04, $04, $08, $09, $0A, $0B, $0C, $0D, $0E
	db $04, $0F, $10, $02, $03, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1A, $1B
	db $1C, $1D, $1E, $1F, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $04, $2A
	db $2B, $2C, $2D, $2E, $2F, $30, $31, $32, $33, $34, $35, $36, $37, $2D, $38, $39
	db $3A, $3B, $3C, $3D, $3E, $3F, $40, $41, $32, $42, $43, $44, $45, $46, $47, $48
	db $49, $4A, $4B, $4C, $4D, $4E, $4F, $50, $51, $52, $53, $54, $55, $56, $57, $58
	db $59, $5A, $5B, $5C, $5D, $5E, $5F, $60, $61, $62, $63, $64, $65, $66, $67, $68
	db $69, $6A, $6B, $6C, $6D, $6E, $6F, $70, $71, $72, $73, $74, $75, $76, $77, $78
	db $79, $7A, $7B, $7C, $7D, $01, $02, $01, $02, $01, $02, $01, $03, $04, $05, $06
	db $07, $08, $08, $01, $09, $0A, $0B, $0C, $02, $0D, $0E, $0F, $10, $11, $12, $08
	db $13, $01, $14, $15, $16, $17, $18, $19, $1A, $1B, $1C, $1D, $1E, $1F, $20, $01
	db $21, $22, $23, $01, $24, $08, $25, $26, $27, $28, $29, $2A, $08, $01, $2B, $2C
	db $2D, $01, $2E, $2F, $30, $31, $32, $33, $34, $35, $08, $36, $37, $36, $37, $38
	db $39, $3A, $3B, $3C, $3D, $3E, $3F, $08, $08, $37, $36, $37, $36, $40, $41, $42
	db $43, $44, $45, $46, $47, $48, $49, $36, $37, $36, $37, $4A, $4B, $4C, $4D, $4E
	db $4F, $50, $51, $52, $53, $37, $36, $37, $54, $10, $55, $56, $57, $58, $59, $5A
	db $5B, $08, $5C, $36, $37, $5D, $5E, $5F, $60, $61, $62, $63, $64, $65, $66, $67
	db $68, $5A, $59, $80, $00, $FD, $E4, $2B, $2C, $2D, $2E, $2F, $30, $31, $28, $32
	db $33, $34, $35, $36, $37, $38, $39, $3A, $3B, $3C, $3D, $3E, $3F, $01, $05, $3A
	db $3D, $40, $41, $42, $43, $01, $19, $10, $44, $45, $0C, $10, $46, $47, $48, $87
	db $10, $49, $4A, $4B, $86, $20, $0D, $4C, $4D, $4E, $43, $10, $4F, $50, $51, $33
	db $30, $52, $53, $20, $10, $54, $55, $56, $C4, $57, $10, $58, $31, $59, $5A, $5B
	db $0C, $10, $5C, $5D, $5E, $5F, $3F, $10, $5F, $60, $61, $62, $63, $64, $65, $66
	db $67, $68, $69, $6A, $6B, $6C, $6D, $6E, $6F, $F0, $00, $00, $00, $5A, $59, $80
	db $00, $FD, $FF, $02, $03, $06, $07, $0B, $0F, $0F, $0B, $0E, $0A, $0A, $0E, $1F
	db $1F, $17, $18, $A0, $60, $B0, $70, $A7, $68, $F8, $F8, $E8, $38, $28, $28, $38
	db $FC, $FC, $84, $7C, $16, $19, $74, $02, $10, $21, $37, $1F, $34, $FC, $4D, $02
	db $74, $21, $FC, $68, $40, $3E, $01, $00, $35, $00, $03, $03, $FD, $40, $38, $24
	db $3C, $14, $1C, $3E, $3E, $C2, $FE, $0F, $0C, $0B, $0C, $05, $06, $94, $02, $03
	db $02, $2C, $01, $06, $DA, $3E, $1A, $FE, $8D, $7F, $61, $02, $1E, $FE, $E0, $E0
	db $FC, $0E, $0E, $13, $1F, $0A, $0D, $0C, $0F, $07, $07, $05, $06, $07, $07, $0A
	db $0F, $5F, $7F, $FD, $FF, $EE, $F2, $F4, $0C, $F8, $F8, $88, $78, $F0, $F0, $D8
	db $F8, $17, $1E, $2C, $37, $5B, $6D, $64, $5B, $AD, $D2, $FF, $80, $FF, $80, $FF
	db $80, $D8, $E8, $AC, $F4, $4C, $B4, $EE, $12, $E6, $1A, $F2, $0E, $F6, $0E, $F7
	db $0F, $BB, $C4, $71, $4E, $57, $6C, $28, $3F, $7F, $7F, $98, $F8, $D0, $B0, $60
	db $60, $F9, $0F, $EB, $1D, $9F, $7F, $E0, $E0, $00, $00, $00, $00, $00, $00, $00
	db $00, $03, $03, $1C, $1F, $70, $6F, $B8, $C7, $98, $E7, $4C, $73, $24, $3B, $16
	db $19, $C0, $C0, $40, $C0, $40, $C0, $40, $C0, $20, $E0, $20, $E0, $20, $E0, $20
	db $E0, $0B, $0D, $0F, $0F, $7F, $7F, $10, $1F, $2E, $31, $37, $2E, $5B, $6C, $7F
	db $40, $E0, $E0, $F0, $F0, $FE, $FE, $08, $F8, $74, $8C, $EC, $74, $DA, $36, $FE
	db $02, $7A, $47, $7D, $46, $5E, $6D, $28, $3F, $1D, $1B, $0F, $0B, $0A, $0E, $06
	db $06, $7E, $C2, $5E, $E2, $BA, $D6, $F4, $8C, $58, $B8, $E0, $E0, $00, $00, $00
	db $00, $5A, $59, $10, $01, $6C, $00, $01, $CB, $FF, $02, $76, $01, $F8, $59, $02
	db $EF, $16, $02, $9C, $16, $02, $D3, $FC, $02, $D8, $32, $0C, $DE, $01, $12, $65
	db $01, $18, $03, $02, $BB, $01, $80, $2C, $02, $E6, $16, $02, $01, $8C, $02, $C0
	db $9A, $02, $E0, $30, $02, $F0, $F5, $12, $01, $0E, $12, $E6, $01, $18, $3F, $5E
	db $02, $C5, $2A, $0C, $A8, $1F, $93, $02, $0F, $46, $02, $07, $8C, $BA, $FE, $B1
	db $02, $BD, $D0, $12, $01, $0E, $FC, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $01, $02, $00, $00, $03, $04, $00, $05, $06, $07, $00, $00, $00, $00
	db $00, $00, $08, $09, $00, $00, $0A, $0B, $00, $0C, $0D, $0E, $0F, $10, $11, $12
	db $13, $00, $14, $02, $00, $00, $15, $16, $00, $17, $18, $19, $1A, $1B, $1C, $1D
	db $1E, $1F, $20, $21, $22, $00, $23, $24, $00, $14, $25, $26, $02, $27, $28, $29
	db $2A, $2B, $2C, $2D, $2E, $2F, $30, $31, $32, $5A, $59, $B0, $00, $60, $00, $01
	db $F6, $FF, $02, $0B, $2C, $01, $FC, $1A, $02, $FE, $7B, $02, $1C, $0C, $1D, $1E
	db $73, $18, $CD, $02, $01, $01, $87, $02, $86, $01, $0C, $F0, $00, $F8, $58, $02
	db $FB, $48, $4C, $0E, $31, $01, $07, $00, $03, $96, $02, $A3, $38, $80, $00, $C0
	db $26, $02, $E0, $1E, $02, $AD, $4C, $10, $12, $4E, $EF, $50, $01, $E0, $00, $00
	db $00, $5A, $59, $B0, $00, $3C, $FF, $00, $02, $0E, $D9, $C0, $02, $E0, $95, $02
	db $12, $EB, $01, $0E, $12, $CD, $01, $0E, $1F, $99, $02, $0F, $62, $02, $34, $D1
	db $F0, $02, $F8, $85, $02, $12, $EB, $01, $0E, $12, $D8, $01, $0E, $B4, $34, $07
	db $61, $02, $03, $02, $8C, $34, $02, $C9, $FC, $02, $FE, $85, $02, $12, $EF, $01
	db $0E, $E0, $00, $00, $00, $5A, $59, $50, $00, $FD, $E0, $02, $02, $07, $05, $0B
	db $0D, $0F, $09, $0D, $0B, $1E, $12, $9A, $96, $FC, $64, $F4, $0C, $E8, $18, $D0
	db $B0, $60, $60, $D3, $00, $01, $F5, $EB, $80, $80, $C0, $40, $F0, $30, $FC, $0C
	db $BE, $C2, $77, $79, $0D, $0E, $03, $03, $18, $00, $01, $C0, $C0, $E0, $20, $70
	db $90, $6F, $E0, $E0, $12, $8F, $01, $F0, $00, $5A, $59, $40, $00, $FD, $FF, $07
	db $07, $1F, $18, $3F, $26, $6B, $5A, $73, $52, $E3, $A2, $FD, $BE, $FF, $80, $C0
	db $C0, $F0, $30, $9E, $F8, $C8, $AC, $B4, $9C, $94, $8E, $8A, $7E, $FA, $FE, $02
	db $AA, $14, $18, $1C, $20, $A2, $24, $28, $2C, $00, $00, $AA, $14, $18, $1C, $20
	db $AB, $24, $28, $2C, $10, $F8, $00, $00, $00, $5A, $59, $90, $00, $FC, $B9, $1F
	db $E0, $7F, $9F, $1F, $EF, $60, $9F, $7F, $8F, $80, $02, $F8, $07, $FE, $FD, $F8
	db $F7, $34, $00, $FF, $F0, $61, $02, $00, $01, $EC, $24, $0C, $7D, $10, $24, $0C
	db $8F, $10, $B5, $24, $0C, $D7, $10, $24, $5D, $10, $7D, $24, $10, $0C, $8F, $24
	db $B1, $10, $0C, $FE, $01, $E4, $00, $00, $00, $0C, $0C, $15, $1D, $2A, $3B, $7B
	db $4A, $9D, $F5, $EA, $AF, $A5, $E6, $73, $52, $30, $30, $A8, $B8, $D4, $5C, $DE
	db $52, $B9, $AF, $77, $D5, $A5, $67, $CE, $4A, $3A, $2B, $14, $1F, $0D, $0E, $0B
	db $0C, $0B, $0C, $05, $06, $07, $07, $07, $07, $5C, $D4, $28, $F8, $B0, $70, $D0
	db $30, $D0, $30, $A0, $60, $E0, $E0, $E0, $E0, $0F, $0F, $37, $38, $5F, $60, $AF
	db $D0, $FF, $C0, $BB, $C4, $FF, $C0, $BF, $E0, $F8, $F8, $F4, $0C, $FA, $06, $FE
	db $02, $F9, $07, $FD, $03, $FB, $07, $E5, $1B, $FF, $E0, $CF, $F8, $91, $EF, $6D
	db $76, $7A, $7D, $35, $3F, $1B, $1F, $07, $07, $FB, $07, $AD, $77, $B7, $CF, $DA
	db $3E, $CE, $FE, $B4, $FC, $58, $F8, $E0, $E0, $5A, $59, $A0, $00, $60, $00, $01
	db $F6, $FF, $02, $0B, $2C, $01, $E0, $99, $02, $F0, $7B, $02, $18, $0C, $1C, $01
	db $EF, $16, $02, $32, $01, $0C, $0F, $65, $02, $07, $02, $8B, $01, $FC, $26, $02
	db $FE, $59, $02, $E7, $16, $18, $BB, $01, $80, $26, $02, $C0, $0D, $02, $7F, $35
	db $02, $B3, $01, $12, $D7, $7C, $01, $F8, $00, $00, $00, $01, $00, $02, $03, $04
	db $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E, $0F, $10, $00, $11, $12, $13
	db $14, $15, $16, $17, $18, $19, $1A, $1B, $00, $1C, $1D, $1E, $1F, $20, $21, $22
	db $23, $24, $25, $26, $00, $00, $00, $27, $28, $29, $2A, $2B, $2C, $00, $2D, $2E
	db $2F, $30, $31, $32, $33, $00, $00, $00, $34, $5A, $59, $40, $00, $65, $00, $01
	db $F9, $73, $07, $07, $09, $0E, $17, $18, $2F, $30, $3F, $20, $08, $10, $F0, $F0
	db $C8, $78, $02, $90, $28, $70, $90, $F0, $12, $02, $2F, $03, $31, $17, $19, $0D
	db $0E, $03, $03, $10, $1A, $20, $E0, $40, $A0, $C0, $02, $06, $A0, $E0, $C0, $C7
	db $C0, $10, $F8, $00, $00, $5A, $59, $40, $00, $00, $1C, $1C, $0E, $0A, $0F, $09
	db $07, $88, $04, $02, $03, $02, $02, $1F, $65, $1E, $00, $01, $F9, $F1, $80, $80
	db $C0, $40, $E0, $20, $F0, $10, $F8, $78, $0F, $08, $33, $1A, $01, $01, $AC, $18
	db $01, $18, $70, $1A, $01, $1C, $90, $70, $50, $38, $28, $18, $18, $FC, $00, $00
	db $00, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E
	db $0F, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1A, $1B, $1C, $1D, $1E
	db $1F, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2A, $2B, $2C, $2D, $2E
	db $2F, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3A, $00, $5A, $59, $40
	db $00, $68, $00, $01, $01, $03, $03, $05, $06, $0B, $0C, $0F, $08, $A8, $10, $F0
	db $F0, $14, $E8, $18, $F8, $08, $04, $12, $40, $0E, $09, $18, $04, $07, $02, $03
	db $63, $01, $01, $18, $F9, $F1, $D4, $3C, $F4, $EC, $84, $7C, $08, $F8, $10, $F0
	db $E0, $E0, $FE, $10, $C0, $5A, $59, $40, $00, $6C, $00, $01, $06, $07, $07, $0C
	db $0B, $1B, $17, $FF, $10, $BE, $C0, $C0, $30, $F0, $C8, $F8, $15, $1E, $0F, $0F
	db $18, $1F, $15, $1A, $2B, $34, $2D, $32, $50, $7F, $FD, $01, $37, $A8, $78, $F0
	db $F0, $10, $F0, $08, $F8, $44, $BC, $04, $FC, $0A, $FE, $01, $F0, $00, $01, $00
	db $02, $00, $03, $00, $04, $00, $05, $00, $06, $07, $08, $00, $09, $0A, $0B, $00
	db $0C, $0D, $0B, $0E, $0F, $10, $0B, $11, $0F, $12, $00, $13, $00, $14, $15, $16
	db $00, $17, $18, $19, $00, $14, $1A, $1B, $00, $14, $1C, $1D, $1E, $14, $1F, $1D
	db $20, $14, $21, $1D, $22, $5A, $59, $40, $00, $68, $00, $01, $01, $19, $19, $2E
	db $37, $7F, $6A, $F3, $BD, $8F, $0C, $EF, $D4, $3C, $3C, $DE, $E6, $7D, $8B, $CF
	db $31, $97, $7F, $32, $FE, $EC, $F3, $BB, $F6, $CF, $CD, $06, $06, $28, $CB, $35
	db $CD, $87, $87, $C7, $0C, $01, $F8, $00, $00, $01, $02, $03, $04, $05, $06, $07
	db $08, $09, $0A, $0B, $0C, $0D, $0E, $0F, $10, $11, $12, $13, $14, $15, $16, $17
	db $18, $19, $1A, $1B, $1C, $1D, $1E, $1F, $20, $21, $22, $23, $24, $25, $26, $27
	db $28, $29, $2A, $2B, $2C, $2D, $2E, $2F, $30, $5A, $59, $30, $00, $5F, $00, $01
	db $BD, $20, $22, $36, $16, $9A, $8E, $D6, $5C, $6C, $38, $58, $70, $B0, $00, $01
	db $1F, $1F, $33, $3F, $21, $33, $44, $02, $06, $1E, $1E, $1D, $06, $E0, $60, $C0
	db $C0, $80, $80, $1A, $26, $7F, $01, $00, $00, $00, $01, $02, $03, $04, $05, $06
	db $07, $08, $09, $0A, $0B, $0C, $0D, $0E, $0F, $10, $11, $12, $13, $14, $15, $16
	db $17, $18, $19, $1A, $1B, $1C, $1D, $1E, $1F, $20, $21, $22, $23, $24, $25, $26
	db $27, $28, $29, $2A, $2B, $2C, $2D, $2E, $2F, $5A, $59, $60, $00, $3D, $FF, $00
	db $02, $0C, $36, $01, $80, $61, $02, $C0, $02, $36, $01, $3F, $61, $02, $1F, $02
	db $AE, $20, $33, $1C, $02, $E0, $6C, $20, $66, $1C, $02, $0F, $1A, $10, $E2, $1A
	db $02, $C3, $F0, $10, $F8, $5A, $59, $60, $00, $1E, $00, $00, $FF, $F3, $02, $0B
	db $01, $0C, $80, $0C, $02, $5A, $01, $7F, $30, $02, $3F, $C5, $02, $01, $FE, $87
	db $02, $B1, $30, $0C, $D7, $08, $24, $D8, $01, $0E, $FF, $40, $00, $01, $02, $03
	db $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E, $0F, $10, $11, $12, $13
	db $14, $15, $16, $17, $18, $19, $1A, $1B, $1C, $1D, $1E, $1F, $20, $21, $22, $23
	db $24, $01, $01, $02, $00, $03, $03, $04, $00, $05, $05, $06, $00, $07, $01, $01
	db $08, $09, $03, $03, $0A, $0B, $05, $05, $0C, $0D, $01, $0E, $00, $0F, $03, $10
	db $00, $11, $05, $05, $00, $00, $01, $02, $03, $04, $05, $06, $07, $08, $08, $02
	db $03, $09, $0A, $06, $07, $0B, $0C, $0D, $0E, $0F, $10, $11, $12, $13, $14, $08
	db $08, $15, $16, $17, $18, $13, $14, $19, $1A, $00, $00, $01, $02, $03, $04, $05
	db $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E, $0F, $10, $11, $12, $13, $14, $15
	db $16, $17, $18, $19, $1A, $1B, $1C, $1D, $1E, $01, $02, $03, $04, $05, $06, $07
	db $08, $09, $0A, $0B, $0C, $0D, $0E, $0F, $10, $11, $12, $13, $14, $00, $15, $16
	db $00, $01, $02, $00, $03, $04, $05, $06, $07, $00, $08, $09, $0A, $0B, $0C, $0D
	db $0E, $0F, $10, $11, $12, $13, $14, $15, $16, $5A, $59, $50, $00, $79, $81, $01
	db $1C, $DF, $87, $02, $B5, $0C, $0C, $D7, $10, $0C, $DF, $02, $13, $C0, $00, $00
	db $00, $01, $01, $02, $00, $03, $03, $04, $00, $05, $01, $01, $06, $00, $03, $03
	db $07, $08, $01, $01, $09, $0A, $03, $03, $0B, $5A, $59, $20, $00, $6C, $00, $01
	db $0C, $7E, $7E, $B9, $C7, $FF, $2B, $01, $06, $0A, $7F, $16, $E0, $01, $01, $02
	db $03, $03, $04, $05, $01, $06, $07, $03, $08, $09, $01, $0A, $0B, $03, $03, $00
	db $00, $01, $01, $02, $03, $03, $04, $05, $01, $06, $07, $03, $03, $01, $01, $08
	db $09, $03, $0A, $00, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B
	db $0C, $0D, $0E, $0F, $10, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B
	db $0C, $0D, $0E, $0F, $10, $1C, $1C, $2A, $36, $5A, $66, $72, $5E, $64, $7C, $48
	db $78, $30, $30, $00, $00, $3C, $3C, $3C, $24, $3C, $24, $FF, $E7, $FF, $81, $7E
	db $42, $3C, $24, $18, $18, $08, $08, $0C, $0C, $FE, $FA, $FF, $81, $FF, $81, $FE
	db $FA, $0C, $0C, $08, $08, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $08
	db $0A, $0B, $0C, $08, $0D, $01, $02, $01, $02, $03, $04, $05, $06, $07, $08, $09
	db $09, $01, $01, $02, $03, $04, $00, $05, $04, $06, $00, $00, $00, $01, $01, $02
	db $03, $01, $04, $05, $01, $06, $00, $00, $00, $00, $00, $01, $00, $02, $00, $00
	db $00, $03, $04, $00, $05, $01, $02, $03, $04, $05, $06, $00, $00, $01, $02, $03
	db $04, $05, $06, $07, $08, $01, $00, $00, $00, $00, $02, $00, $00, $01, $02, $03
	db $04, $05, $00, $00, $00, $01, $02, $03, $04, $01, $02, $03, $04, $01, $02, $03
	db $04, $01, $02, $03, $04, $01, $00, $00, $00, $01, $02, $03, $04, $01, $02, $03
	db $04, $01, $02, $03, $04, $01, $00, $00, $00, $01, $00, $00, $00, $01, $02, $03
	db $04, $00, $01, $02, $03, $29, $2A, $00, $00, $56, $44, $50, $5F, $53, $65, $74
	db $52, $65, $67, $4E, $0E, $C2, $3A, $0B, $56, $44, $50, $5F, $53, $65, $74, $43
	db $6F, $6C, $4E, $0E, $B4, $3E, $0C, $50, $75, $7A, $7A, $6C, $65, $53, $65, $6E
	db $73, $65, $59, $0E, $06, $40, $0A, $45, $4E, $44, $4F, $42, $4A, $45, $43, $54
	db $53, $0E, $19, $41, $0D, $57, $69, $64, $65, $43, $6F, $6C, $50, $65, $72, $73
	db $6F, $31, $0C, $BC, $46, $EC, $38, $00, $00, $00, $00, $0D, $45, $6E, $65, $6D
	db $79, $48, $69, $74, $48, $65, $72, $6F, $30, $0E, $08, $3A, $17, $4E, $4F, $52
	db $4D, $41, $4C, $5F, $43, $4F, $4E, $44, $4F, $52, $5F, $53, $50, $45, $45, $44
	db $41, $4E, $49, $4D, $0E, $9F, $3A, $03, $54, $4D, $41, $0E, $73, $3B, $0A, $53
	db $4C, $5F, $44, $45, $52, $34, $35, $5F, $41, $0E, $A1, $3C, $0A, $41, $43, $54
	db $48, $55, $47, $4F, $45, $4E, $44, $0E, $41, $41, $0F, $43, $6F, $6E, $74, $46
	db $72, $61, $63, $5F, $46, $6F, $72, $65, $73, $74, $0E, $6C, $41, $0A, $48, $65
	db $72, $6F, $53, $6C, $65, $64, $67, $65, $0E, $06, $47, $0A, $55, $6E, $48, $65
	db $72, $6F, $50, $6C, $61, $74, $0E, $01, $39, $10, $44, $45, $54, $45, $43, $54
	db $53, $45, $52, $50, $5F, $59, $44, $4F, $57, $4E, $0E, $A1, $3A, $03, $44, $49
	db $56, $0E, $34, $3B, $09, $59, $45, $54, $49, $5F, $49, $5A, $51, $55, $0E, $9D
	db $3B, $06, $42, $49, $54, $5F, $55, $50, $0E, $2A, $3C, $06, $44, $49, $52, $5F
	db $55, $50, $0E, $83, $3C, $10, $48, $55, $47, $4F, $5F, $4D, $55, $45, $52, $45
	db $46, $4F, $52, $45, $53, $54, $0E, $D8, $3E, $06, $44, $45, $53, $50, $5F, $58
	db $0E, $FC, $40, $06, $4D, $41, $58, $5F, $46, $58, $0E, $6E, $39, $14, $52, $49
	db $47, $48, $54, $4D, $41, $52, $47, $49, $4E, $5F, $49, $4E, $44, $49, $4F, $4C
	db $45, $45, $0E, $CC, $39, $10, $41, $4C, $54, $55, $52, $41, $5F, $48, $45, $52
	db $4F, $45, $5F, $52, $49, $4F, $0E, $86, $3A, $10, $4C, $49, $4D, $49, $54, $45
	db $5F, $59, $55, $50, $45, $4E, $45, $49, $4E, $54, $0E, $39, $3E, $07, $42, $4C
	db $41, $4D, $49, $4E, $31, $0E, $D9, $3E, $06, $44, $45, $53, $50, $5F, $59, $0E
	db $D9, $3A, $06, $4E, $55, $4D, $53, $5F, $43, $0E, $4B, $3B, $0A, $43, $4C, $49
	db $4D, $42, $5F, $46, $41, $4C, $4C, $0E, $4F, $3E, $07, $42, $4C, $41, $4D, $49
	db $4E, $32, $0E, $F7, $3E, $10, $57, $4F, $52, $4C, $44, $5F, $50, $53, $45, $55
	db $44, $4F, $53, $42, $4E, $4B, $0E, $B6, $41, $0A, $54, $69, $6D, $65, $45, $66
	db $65, $63, $74, $6F, $0E, $5D, $3A, $0A, $4F, $42, $4A, $44, $45, $46, $5F, $50
	db $41, $4C, $0E, $53, $3C, $0D, $43, $41, $50, $54, $55, $52, $45, $44, $5F, $54
	db $49, $4D, $45, $0E, $6D, $3C, $0D, $50, $4F, $53, $43, $45, $4E, $54, $52, $45
	db $48, $55, $47, $4F, $0E, $6D, $3D, $0A, $50, $69, $65, $64, $72, $61, $50, $6C
	db $61, $74, $0E, $3A, $3E, $07, $42, $4C, $41, $4D, $41, $58, $31, $0E, $3D, $3E
	db $07, $4C, $41, $44, $4D, $49, $4E, $31, $0E, $59, $3E, $07, $42, $4C, $41, $4D
	db $49, $4E, $33, $0E, $FD, $3E, $0D, $57, $4F, $52, $4C, $44, $5F, $47, $52, $41
	db $46, $49, $43, $53, $0E, $BD, $3F, $05, $48, $65, $72, $6F, $58, $0E, $FE, $38
	db $06, $4D, $5F, $4E, $55, $4C, $4C, $0E, $FA, $3A, $07, $56, $45, $52, $5F, $31
	db $32, $38, $0E, $50, $3E, $07, $42, $4C, $41, $4D, $41, $58, $32, $0E, $53, $3E
	db $07, $4C, $41, $44, $4D, $49, $4E, $32, $0E, $DC, $3E, $0F, $48, $65, $72, $6F
	db $41, $6E, $69, $6D, $53, $70, $72, $4E, $65, $78, $74, $0E, $BE, $3F, $05, $48
	db $65, $72, $6F, $59, $0E, $97, $3A, $03, $4C, $59, $43, $0E, $1F, $3E, $0A, $52
	db $6F, $61, $64, $53, $6B, $79, $49, $6E, $74, $0E, $40, $3E, $07, $4C, $41, $44
	db $4D, $41, $58, $31, $0E, $5A, $3E, $07, $42, $4C, $41, $4D, $41, $58, $33, $0E
	db $5D, $3E, $07, $4C, $41, $44, $4D, $49, $4E, $33, $0E, $03, $3F, $0D, $4D, $41
	db $58, $4C, $45, $4E, $50, $53, $45, $55, $44, $4F, $53, $0E, $15, $39, $10, $54
	db $49, $4D, $45, $5F, $43, $52, $4F, $55, $43, $48, $5F, $44, $4F, $57, $4E, $0E
	db $F6, $3A, $03, $48, $4F, $52, $0E, $FB, $3A, $07, $56, $45, $52, $5F, $32, $35
	db $36, $0E, $BD, $3B, $03, $4B, $45, $59, $0E, $56, $3E, $07, $4C, $41, $44, $4D
	db $41, $58, $32, $0E, $09, $41, $05, $43, $72, $69, $73, $58, $0E, $60, $3E, $07
	db $4C, $41, $44, $4D, $41, $58, $33, $0E, $0A, $41, $05, $43, $72, $69, $73, $59
	db $0E, $29, $36, $06, $50, $55, $5A, $5A, $4C, $45, $0E, $33, $36, $03, $52, $49
	db $4F, $0E, $7A, $39, $0E, $46, $4C, $41, $47, $44, $4F, $4F, $52, $5F, $42, $41
	db $4A, $41, $30, $0E, $4C, $3A, $0D, $43, $4F, $44, $49, $47, $4F, $5F, $53, $50
	db $52, $49, $54, $45, $0E, $19, $3B, $09, $42, $49, $54, $53, $43, $52, $5F, $55
	db $70, $0E, $DA, $3D, $0D, $4F, $46, $46, $53, $45, $54, $5F, $43, $4F, $4E, $44
	db $4F, $52, $0E, $2C, $3F, $0A, $44, $49, $52, $43, $45, $4E, $54, $52, $4F, $41
	db $0E, $35, $3A, $0A, $41, $4E, $49, $4D, $5F, $54, $41, $42, $4C, $45, $0E, $B2
	db $41, $0A, $48, $65, $72, $6F, $41, $63, $74, $69, $6F, $6E, $0E, $22, $3A, $0B
	db $4C, $43, $44, $43, $5F, $57, $69, $6E, $64, $6F, $77, $0E, $5F, $3A, $0A, $4F
	db $42, $4A, $45, $43, $54, $5F, $45, $4E, $44, $0E, $F3, $3A, $06, $52, $55, $54
	db $4D, $4F, $56, $0E, $0E, $3C, $03, $4D, $6F, $31, $0E, $D8, $3D, $0D, $41, $4C
	db $54, $55, $52, $41, $5F, $43, $4F, $4E, $44, $4F, $52, $0E, $65, $3E, $0A, $42
	db $4C, $41, $4D, $49, $4E, $5F, $4F, $42, $4A, $0E, $C5, $3E, $06, $50, $4F, $53
	db $58, $53, $50, $0E, $F4, $41, $0A, $4F, $66, $66, $73, $65, $74, $53, $61, $63
	db $6F, $0E, $31, $39, $13, $53, $50, $52, $49, $54, $45, $5F, $4F, $55, $54, $5F
	db $4F, $46, $5F, $52, $41, $4E, $47, $45, $0E, $A4, $3A, $03, $53, $43, $58, $0E
	db $0F, $3C, $03, $4D, $6F, $32, $0E, $C4, $3E, $06, $50, $4F, $53, $59, $53, $50
	db $0E, $CE, $40, $0A, $4E, $4F, $4D, $45, $4E, $45, $4D, $49, $47, $4F, $0E, $7E
	db $41, $12, $46, $6C, $61, $67, $4C, $75, $63, $68, $61, $43, $6F, $6E, $4D, $75
	db $6E, $65, $63, $6F, $0E, $4B, $42, $0A, $4D, $6F, $76, $58, $47, $75, $61, $6E
	db $74, $65, $0E, $EF, $39, $0D, $4E, $55, $4D, $45, $52, $4F, $53, $5F, $44, $45
	db $42, $55, $47, $0E, $A3, $3A, $03, $53, $43, $59, $0E, $67, $3E, $0A, $42, $4C
	db $41, $4D, $41, $58, $5F, $4F, $42, $4A, $0E, $20, $3F, $05, $4D, $69, $6C, $75
	db $58, $0E, $7B, $3D, $0F, $53, $63, $72, $6F, $6C, $6C, $50, $6F, $6C, $6C, $6F
	db $58, $41, $6E, $74, $0E, $21, $3F, $05, $4D, $69, $6C, $75, $59, $0E, $FD, $40
	db $05, $46, $78, $50, $6E, $74, $0E, $76, $3A, $10, $4C, $49, $4D, $49, $54, $45
	db $5F, $59, $55, $50, $45, $4E, $45, $4F, $55, $54, $0E, $47, $3B, $0A, $43, $4C
	db $49, $4D, $42, $5F, $4C, $45, $46, $54, $0E, $BF, $3D, $0D, $42, $4C, $4F, $43
	db $4B, $5F, $53, $43, $52, $4F, $4C, $4C, $58, $0E, $FB, $3E, $0D, $57, $4F, $52
	db $4C, $44, $5F, $4F, $42, $4A, $45, $43, $54, $53, $0E, $1D, $36, $07, $45, $4E
	db $44, $47, $41, $4D, $45, $0E, $8D, $3C, $0A, $48, $55, $47, $4F, $5F, $42, $55
	db $43, $45, $41, $0E, $F0, $3C, $0A, $58, $4C, $45, $46, $54, $45, $4E, $45, $49
	db $4E, $0E, $BB, $3D, $0A, $57, $69, $6E, $64, $6F, $77, $46, $6C, $61, $67, $0E
	db $C1, $3D, $0D, $42, $4C, $4F, $43, $4B, $5F, $53, $43, $52, $4F, $4C, $4C, $59
	db $0E, $D2, $3F, $0A, $48, $65, $72, $6F, $43, $72, $6F, $75, $63, $68, $0E, $00
	db $41, $0A, $4D, $75, $73, $69, $63, $50, $61, $72, $61, $6D, $0E, $6A, $41, $0A
	db $43, $6F, $64, $65, $53, $70, $72, $69, $74, $65, $0E, $72, $41, $0A, $44, $69
	db $72, $43, $69, $72, $63, $75, $69, $74, $0E, $C2, $41, $05, $4F, $78, $49, $6E
	db $74, $0E, $9B, $39, $27, $44, $45, $54, $45, $43, $54, $5F, $43, $4F, $43, $4F
	db $44, $52, $49, $4C, $4F, $5F, $48, $49, $54, $5F, $48, $45, $52, $4F, $5F, $58
	db $52, $49, $47, $48, $54, $5F, $52, $45, $4D, $4F, $55, $50, $0E, $CD, $3A, $0A
	db $4D, $41, $52, $4B, $31, $5F, $50, $49, $45, $5A, $0E, $F8, $3C, $0A, $54, $69
	db $6D, $65, $43, $72, $6F, $75, $63, $68, $0E, $C9, $3D, $0D, $43, $6F, $6E, $64
	db $6F, $72, $41, $6E, $69, $6D, $41, $64, $64, $0E, $3C, $3F, $0A, $44, $49, $52
	db $48, $45, $41, $44, $5F, $49, $5A, $0E, $04, $42, $0A, $46, $72, $61, $6D, $65
	db $53, $75, $65, $6C, $6F, $0E, $91, $42, $0F, $56, $61, $72, $58, $43, $75, $72
	db $73, $6F, $72, $4C, $6C, $61, $76, $65, $0C, $18, $47, $E6, $46, $22, $01, $00
	db $00, $11, $4F, $42, $4A, $45, $54, $4F, $43, $4F, $47, $49, $42, $4C, $45, $5F
	db $43, $48, $51, $0E, $1A, $39, $0A, $46, $41, $4C, $4C, $58, $5F, $42, $4F, $4C
	db $41, $0E, $CF, $3A, $0A, $4D, $41, $52, $4B, $32, $5F, $50, $49, $45, $5A, $0E
	db $E5, $3B, $0A, $54, $41, $42, $47, $52, $46, $5F, $4C, $45, $4E, $0E, $81, $3C
	db $0A, $48, $55, $47, $4F, $5F, $47, $41, $54, $45, $41, $0E, $D0, $3C, $0D, $43
	db $61, $73, $63, $61, $64, $61, $43, $75, $65, $72, $64, $61, $0E, $22, $3E, $0A
	db $43, $6F, $6E, $64, $6F, $72, $54, $69, $6D, $65, $0E, $93, $42, $0F, $56, $61
	db $72, $59, $43, $75, $72, $73, $6F, $72, $4C, $6C, $61, $76, $65, $0E, $1C, $39
	db $0A, $46, $41, $4C, $4C, $59, $5F, $42, $4F, $4C, $41, $0E, $79, $3B, $0A, $53
	db $4C, $5F, $49, $5A, $51, $33, $30, $5F, $41, $0E, $99, $40, $0D, $4D, $41, $52
	db $4B, $45, $52, $53, $5F, $57, $48, $49, $54, $45, $0E, $92, $41, $0A, $50, $6F
	db $73, $53, $6E, $6F, $77, $4D, $61, $6E, $0E, $E7, $3A, $07, $48, $49, $47, $48
	db $43, $41, $52, $0E, $7B, $3B, $0A, $53, $4C, $5F, $49, $5A, $51, $33, $30, $5F
	db $42, $0E, $34, $3C, $0A, $50, $65, $72, $73, $6F, $46, $6C, $61, $67, $73, $0E
	db $1B, $3D, $0F, $50, $69, $65, $64, $72, $61, $73, $54, $69, $6D, $65, $4E, $65
	db $78, $74, $0E, $34, $3D, $08, $4D, $65, $73, $73, $61, $67, $65, $31, $0E, $CC
	db $34, $07, $4D, $41, $50, $45, $41, $44, $4F, $0E, $D6, $3A, $0A, $50, $49, $45
	db $5A, $5F, $42, $4C, $41, $4E, $43, $0E, $6F, $3E, $0F, $50, $75, $7A, $7A, $6C
	db $65, $56, $42, $63, $6F, $64, $65, $6D, $69, $64, $0E, $0E, $40, $0D, $44, $4F
	db $49, $4E, $47, $5F, $53, $43, $52, $4F, $4C, $4C, $58, $0E, $FA, $40, $12, $52
	db $6F, $61, $64, $43, $69, $72, $63, $75, $69, $74, $4C, $65, $6E, $48, $61, $72
	db $64, $0E, $7F, $3B, $0A, $53, $4C, $5F, $49, $5A, $51, $36, $30, $5F, $41, $0E
	db $5D, $3C, $08, $44, $69, $66, $66, $48, $61, $72, $64, $0E, $7F, $3D, $0A, $53
	db $63, $72, $6F, $6C, $6C, $50, $69, $78, $58, $0E, $AF, $3D, $05, $4C, $65, $76
	db $65, $6C, $0E, $10, $40, $0D, $44, $4F, $49, $4E, $47, $5F, $53, $43, $52, $4F
	db $4C, $4C, $59, $0E, $7C, $40, $0D, $4D, $75, $73, $69, $63, $4F, $6E, $4F, $66
	db $66, $4C, $65, $6E, $0E, $4B, $41, $08, $48, $65, $72, $6F, $58, $44, $69, $65
	db $0E, $88, $41, $08, $44, $69, $72, $50, $4D, $69, $72, $61, $0E, $81, $3B, $0A
	db $53, $4C, $5F, $49, $5A, $51, $36, $30, $5F, $42, $0E, $C1, $3E, $07, $46, $41
	db $44, $45, $56, $41, $52, $0E, $AE, $40, $06, $52, $61, $6D, $42, $47, $50, $0E
	db $C6, $41, $0A, $4D, $6F, $76, $53, $65, $6E, $6F, $69, $64, $65, $0E, $FD, $3A
	db $03, $53, $55, $52, $0E, $54, $3D, $05, $50, $61, $75, $73, $61, $0E, $75, $3D
	db $0A, $50, $49, $45, $44, $52, $41, $53, $50, $4F, $53, $0E, $C3, $3D, $0A, $54
	db $65, $6D, $62, $6C, $6F, $72, $43, $6E, $74, $0E, $D4, $3F, $0A, $50, $65, $72
	db $73, $6F, $53, $70, $65, $65, $64, $0E, $EE, $40, $14, $53, $6E, $6F, $77, $43
	db $69, $72, $63, $75, $69, $74, $4C, $65, $6E, $4D, $65, $64, $69, $75, $6D, $0E
	db $39, $41, $0D, $52, $65, $49, $6E, $69, $74, $4D, $75, $73, $46, $6C, $61, $67
	db $0E, $AE, $41, $0A, $76, $61, $72, $70, $72, $75, $65, $62, $61, $32, $0E, $DA
	db $41, $0F, $48, $75, $67, $6F, $50, $69, $65, $64, $72, $6F, $73, $50, $6C, $61
	db $74, $0E, $7D, $3B, $0A, $53, $4C, $5F, $49, $5A, $51, $34, $35, $5F, $41, $0E
	db $71, $3C, $0A, $50, $4F, $53, $43, $4F, $4C, $4C, $45, $46, $54, $0E, $CD, $3F
	db $0A, $48, $65, $72, $6F, $53, $74, $6F, $6E, $65, $64, $0E, $24, $41, $0D, $45
	db $6E, $65, $72, $67, $79, $46, $6C, $61, $67, $54, $61, $62, $0E, $69, $3B, $0A
	db $44, $49, $45, $5F, $53, $50, $4C, $41, $53, $48, $0E, $D0, $3B, $07, $46, $50
	db $4F, $4C, $4C, $4F, $30, $0E, $AC, $3C, $0F, $4A, $75, $6E, $67, $6C, $61, $45
	db $6E, $64, $53, $74, $61, $74, $75, $73, $0E, $4E, $3D, $11, $50, $72, $65, $76
	db $69, $6F, $75, $73, $57, $6F, $72, $6C, $64, $50, $61, $73, $73, $0E, $E4, $3E
	db $07, $46, $47, $4D, $49, $54, $41, $44, $0E, $D1, $3B, $07, $46, $50, $4F, $4C
	db $4C, $4F, $31, $0E, $E0, $3B, $07, $54, $41, $42, $47, $52, $46, $47, $0E, $DA
	db $3C, $0A, $4D, $75, $73, $65, $6F, $4C, $6C, $61, $76, $65, $0E, $93, $3D, $0F
	db $43, $6F, $75, $6E, $74, $65, $72, $4E, $65, $78, $74, $42, $6F, $6C, $61, $0E
	db $D2, $39, $07, $4C, $43, $44, $43, $5F, $42, $47, $0E, $45, $3B, $0A, $43, $4C
	db $49, $4D, $42, $5F, $44, $4F, $57, $4E, $0E, $A4, $3B, $0A, $42, $49, $54, $5F
	db $53, $45, $4C, $45, $43, $54, $0E, $D2, $3B, $07, $46, $50, $4F, $4C, $4C, $4F
	db $32, $0E, $B4, $3F, $0A, $48, $6F, $74, $65, $6C, $46, $6C, $6F, $6F, $72, $0E
	db $74, $40, $0A, $4D, $65, $6E, $75, $4E, $75, $6D, $62, $65, $72, $0E, $3D, $41
	db $08, $4F, $6E, $65, $55, $70, $54, $61, $62, $0E, $76, $41, $0F, $54, $61, $62
	db $43, $6F, $6C, $69, $73, $69, $6F, $6E, $53, $6E, $6F, $77, $0E, $7A, $41, $0D
	db $50, $61, $75, $73, $61, $43, $6F, $67, $65, $53, $61, $63, $6F, $0E, $DF, $39
	db $0A, $46, $52, $45, $45, $5F, $45, $4E, $45, $4D, $59, $0E, $E6, $3A, $07, $57
	db $49, $44, $45, $43, $41, $52, $0E, $D3, $3B, $07, $46, $50, $4F, $4C, $4C, $4F
	db $33, $0E, $E0, $3D, $08, $48, $65, $72, $6F, $41, $63, $74, $59, $0E, $34, $3F
	db $0A, $44, $49, $52, $46, $4F, $4F, $54, $5F, $44, $45, $0E, $4F, $42, $0F, $50
	db $69, $65, $64, $72, $6F, $52, $6F, $77, $47, $75, $61, $6E, $74, $65, $0E, $81
	db $42, $0A, $56, $61, $72, $58, $43, $75, $72, $73, $6F, $72, $00, $52, $54, $4F
	db $32, $0E, $41, $39, $0E, $50, $49, $45, $44, $52, $41, $53, $5F, $4C, $45, $56
	db $45, $4C, $33, $0E, $9C, $3A, $04, $4F, $42, $50, $31, $0E, $5B, $3D, $0B, $41
	db $6E, $69, $6D, $52, $69, $6F, $50, $6F, $73, $31, $0E, $C8, $3E, $07, $53, $54
	db $5F, $41, $4C, $4C, $33, $0E, $43, $39, $0E, $50, $49, $45, $44, $52, $41, $53
	db $5F, $4C, $45, $56, $45, $4C, $34, $0E, $6A, $39, $0E, $46, $52, $45, $4E, $4F
	db $50, $49, $45, $44, $52, $41, $4D, $49, $4E, $0E, $FA, $39, $0B, $44, $45, $41
	db $44, $5F, $41, $42, $41, $4C, $49, $4D, $0E, $2B, $3D, $12, $48, $65, $72, $6F
	db $46, $61, $6C, $6C, $69, $6E, $67, $50, $69, $65, $64, $72, $61, $73, $0E, $5D
	db $3D, $0B, $41, $6E, $69, $6D, $52, $69, $6F, $50, $6F, $73, $32, $0E, $C9, $3E
	db $07, $53, $54, $5F, $41, $4C, $4C, $34, $0E, $E0, $3E, $08, $48, $65, $72, $6F
	db $41, $6E, $69, $6D, $0E, $9E, $3F, $08, $48, $65, $72, $6F, $54, $61, $6B, $65
	db $0E, $78, $40, $0A, $44, $69, $66, $66, $69, $63, $75, $6C, $74, $79, $0E, $ED
	db $42, $0D, $54, $69, $6D, $65, $45, $78, $74, $72, $61, $4C, $69, $66, $65, $0E
	db $56, $39, $11, $54, $49, $4D, $45, $5F, $50, $49, $45, $44, $52, $41, $53, $5F
	db $48, $41, $52, $44, $0E, $0C, $3A, $0E, $53, $50, $41, $43, $45, $5F, $4D, $41
	db $52, $43, $41, $44, $4F, $52, $0E, $B3, $3B, $07, $53, $50, $45, $45, $44, $5F
	db $44, $0E, $5F, $3D, $0B, $41, $6E, $69, $6D, $52, $69, $6F, $50, $6F, $73, $33
	db $0E, $CA, $3E, $07, $53, $54, $5F, $41, $4C, $4C, $35, $0E, $DC, $40, $0B, $50
	db $50, $73, $69, $7A, $65, $58, $38, $56, $61, $72, $0E, $68, $39, $0E, $46, $52
	db $45, $4E, $4F, $50, $49, $45, $44, $52, $41, $4D, $41, $58, $0E, $23, $3D, $08
	db $76, $61, $72, $54, $6F, $41, $64, $64, $0E, $0B, $3E, $08, $52, $6F, $61, $64
	db $54, $69, $6D, $65, $0E, $10, $3F, $08, $59, $65, $74, $69, $46, $6C, $61, $67
	db $0E, $C3, $3F, $0A, $53, $74, $6F, $70, $53, $63, $72, $6F, $6C, $6C, $0C, $04
	db $47, $E6, $46, $BE, $00, $00, $00, $0A, $50, $0E, $A1, $3D, $0B, $42, $6F, $6C
	db $61, $54, $69, $6D, $65, $45, $6E, $64, $0E, $F5, $3F, $04, $54, $4D, $50, $33
	db $0E, $25, $42, $06, $44, $69, $67, $69, $74, $33, $0E, $FA, $42, $0D, $50, $6F
	db $69, $6E, $74, $73, $46, $6F, $72, $4C, $69, $66, $65, $0E, $88, $39, $0E, $50
	db $41
