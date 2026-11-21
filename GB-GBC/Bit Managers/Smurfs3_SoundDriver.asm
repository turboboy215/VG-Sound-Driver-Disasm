; =====================================================================
; The Smurfs' Nightmare / Smurfs 3 (E) (M4) - Game Boy
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o smurfs3.o Smurfs3_SoundDriver.asm
;   rgblink -o smurfs3.gb smurfs3.o
;   python tools/cmp_banked.py smurfs3.gb "Smurfs 3, The (E) (M4) [!].gb" 2:4000-7FFF
; (driver and data fill ROM bank 2; the linked file only matches in that range)
;
; Documentation: Smurfs3_SoundDriver.md / AJG_SoundEngine_Family.md
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


SECTION "SoundDriver", ROMX[$4000], BANK[2]


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
	jp PlaySong18                      ; song 18
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

; Unreferenced (83 bytes)
	db $8B, $46, $F2, $26, $89, $07, $C4, $5E, $EE, $8B, $46, $F4, $26, $89, $47, $02
	db $C4, $5E, $EE, $8B, $46, $F6, $26, $89, $47, $04, $C4, $5E, $EE, $8B, $46, $F8
	db $26, $89, $47, $06, $E9, $2C, $03, $C7, $46, $EC, $D7, $30, $C7, $46, $EA, $0C
	db $02, $FF, $76, $EC, $FF, $76, $EA, $68, $D7, $30, $68, $61, $00, $6A, $FF, $16
	db $8D, $86, $E2, $FE, $50, $9A, $8B, $02, $1F, $01, $8B, $F8, $83, $FF, $FF, $75
	db $1F, $16, $8D
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
	add a, $96
	ld l, a
	adc a, $76
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
	dw Drum11
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

; Song 1: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong1:
	ld a, $75
	ld [wInstrTableHi], a
	ld a, $72
	ld [wInstrTable], a
	call StopAll
	ld de, Song1_Ch1
	call StartMusicCh1
	ld de, Song1_Ch2
	call StartMusicCh2
	ld de, Song1_Ch3
	jp StartMusicCh3
Song1_Ch1:
	dw Pat_4BB9
	dw Pat_4BD4
	dw Pat_4BB9
	dw Pat_4BD4
	dw Pat_4BEF
	dw Pat_4BEF
	dw Pat_4BEF
	ORDER_LOOP Song1_Ch1
Song1_Ch2:
	dw Pat_4C17
	dw Pat_4C3D
	dw Pat_4C17
	dw Pat_4C3D
	dw Pat_4C83
	dw Pat_4C83
	dw Pat_4C83
	ORDER_LOOP Song1_Ch2
Song1_Ch3:
	dw Pat_4CB7
	dw Pat_4CE3
	dw Pat_4CB7
	dw Pat_4CE3
	dw Pat_4CFD
	dw Pat_4D26
	dw Pat_4D26
	ORDER_LOOP Song1_Ch3
Pat_4BB9:
	HWENV $F2, $07, $86
	ARP 0
	DUTY_50
	REPEAT 2
	LEN 42
	NOTE D_, 2
	LEN 14
	NOTE D_, 2
	NOTE Fsh, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	REPEAT_END
	REPEAT 2
	LEN 42
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE C_, 3
	REPEAT_END
	NEXT
Pat_4BD4:
	REPEAT 2
	LEN 42
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE B_, 2
	NOTE C_, 3
	NOTE C_, 3
	NOTE D_, 3
	REPEAT_END
	LEN 42
	NOTE D_, 2
	LEN 14
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE Fsh, 2
	LEN 42
	NOTE D_, 2
	LEN 14
	NOTE D_, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE C_, 2
	NEXT
Pat_4BEF:
	LEN 14
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE C_, 2
	LEN 42
	NOTE D_, 2
	LEN 7
	NOTE C_, 2
	NOTE Csh, 2
	LEN 14
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE C_, 2
	LEN 28
	NOTE D_, 2
	LEN 14
	NOTE A_, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE C_, 3
	NOTE D_, 3
	NOTE C_, 3
	NOTE A_, 2
	NOTE F_, 2
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	NOTE Gsh, 2
	LEN 14
	NOTE A_, 2
	NOTE A_, 2
	NOTE C_, 3
	NOTE F_, 2
	NEXT
Pat_4C17:
	LEN 14
	REPEAT 2
	INSTR 8
	NOTE D_, 3
	INSTR 6
	NOTE D_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 8
	NOTE D_, 3
	INSTR 6
	NOTE D_, 4
	INSTR 8
	NOTE A_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 6
	NOTE D_, 4
	REPEAT_END
	REPEAT 2
	INSTR 8
	NOTE F_, 3
	INSTR 6
	NOTE F_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 8
	NOTE F_, 3
	INSTR 6
	NOTE F_, 4
	INSTR 8
	NOTE C_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 6
	NOTE F_, 4
	REPEAT_END
	NEXT
Pat_4C3D:
	LEN 14
	REPEAT 2
	INSTR 8
	NOTE G_, 3
	INSTR 6
	NOTE G_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 8
	NOTE G_, 3
	INSTR 6
	NOTE G_, 4
	INSTR 8
	NOTE D_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 6
	NOTE G_, 4
	REPEAT_END
	INSTR 8
	NOTE D_, 3
	INSTR 6
	LEN 7
	NOTE D_, 4
	INSTR 8
	NOTE D_, 3
	INSTR 1
	LEN 14
	NOTE C_, 3
	INSTR 8
	NOTE D_, 3
	INSTR 6
	LEN 7
	NOTE D_, 4
	INSTR 8
	LEN 14
	NOTE A_, 3
	LEN 7
	NOTE A_, 3
	INSTR 1
	LEN 14
	NOTE C_, 3
	INSTR 6
	NOTE D_, 4
	INSTR 8
	NOTE D_, 3
	INSTR 6
	LEN 7
	NOTE D_, 4
	INSTR 8
	NOTE D_, 3
	INSTR 1
	LEN 14
	NOTE C_, 3
	INSTR 8
	NOTE D_, 3
	INSTR 6
	LEN 7
	NOTE D_, 4
	INSTR 8
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE C_, 4
	INSTR 1
	LEN 14
	NOTE C_, 3
	INSTR 6
	NOTE C_, 4
	NEXT
Pat_4C83:
	LEN 14
	REPEAT 2
	INSTR 8
	NOTE D_, 3
	INSTR 6
	NOTE D_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 8
	NOTE D_, 3
	INSTR 6
	NOTE D_, 4
	INSTR 8
	NOTE A_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 6
	NOTE D_, 4
	REPEAT_END
	INSTR 8
	NOTE F_, 3
	INSTR 6
	NOTE F_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 8
	NOTE F_, 3
	INSTR 6
	NOTE F_, 4
	INSTR 8
	NOTE C_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 6
	NOTE F_, 4
	INSTR 8
	NOTE G_, 3
	INSTR 6
	NOTE G_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 8
	NOTE G_, 3
	INSTR 6
	NOTE G_, 4
	INSTR 8
	NOTE D_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 4
	NOTE A_, 4
	NEXT
Pat_4CB7:
	VOLENV 12, $11, $1F, $17
	CH_TRANSPOSE $0C
	RELEASE $01, $01
	VIBRATO $07, $01, $04
	WAVE Wave_7A57
	DRUMS $07, DrumPat_4D47
	INSTR 13
	LEN 42
	NOTE A_, 3
	LENGTH $70
	NOTE A_, 3
	LEN 14
	NOTE A_, 3
	NOTE B_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE A_, 3
	LEN 42
	NOTE C_, 4
	LENGTH $70
	NOTE A_, 3
	LEN 14
	NOTE A_, 3
	NOTE B_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE A_, 3
	NEXT
Pat_4CE3:
	INSTR 13
	LEN 42
	NOTE D_, 4
	NOTE B_, 3
	LENGTH $46
	NOTE G_, 3
	LEN 14
	NOTE D_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	LENGTH $70
	NOTE A_, 3
	INSTR 11
	LEN 42
	NOTE D_, 2
	LEN 14
	NOTE D_, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE C_, 2
	NEXT
Pat_4CFD:
	INSTR 12
	LEN 14
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE C_, 3
	LEN 42
	NOTE D_, 3
	LEN 7
	NOTE C_, 3
	NOTE Csh, 3
	LEN 14
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE C_, 3
	LEN 28
	NOTE D_, 3
	LEN 14
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE F_, 3
	NOTE G_, 3
	LEN 28
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE Gsh, 3
	LEN 14
	NOTE A_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE F_, 3
	NEXT
Pat_4D26:
	INSTR 13
	LEN 28
	NOTE D_, 4
	NOTE D_, 5
	LEN 42
	NOTE A_, 4
	LEN 7
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 28
	NOTE A_, 4
	NOTE A_, 4
	LEN 42
	NOTE Fsh, 4
	LEN 14
	NOTE D_, 4
	LEN 28
	NOTE A_, 4
	NOTE A_, 4
	LEN 14
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE A_, 4
	LEN 28
	NOTE G_, 4
	LEN 14
	NOTE F_, 4
	NOTE E_, 4
	LEN 28
	NOTE D_, 4
	NOTE C_, 4
	NEXT
DrumPat_4D47:
	db DRUM_LEVEL + 14, 1, 0, 4, 0, 9, 0, 1
	db 0, 1, 0, 4, 0, 9, 0, 4
	db 0, DRUM_LOOP

; Song 2: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong2:
	ld a, $75
	ld [wInstrTableHi], a
	ld a, $72
	ld [wInstrTable], a
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
	dw Pat_4DBF
	dw Pat_4DD7
Loop_4D7D:
	dw Pat_4DD7
	dw Pat_4DD7
	dw Pat_4E0E
	dw Pat_4DD7
	dw Pat_4E49
	dw Pat_4E49
	dw Pat_4E63
	ORDER_LOOP Loop_4D7D
Song2_Ch3:
	dw Pat_4E9D
	dw Pat_4EBA
Loop_4D93:
	dw Pat_4EBA
	dw Pat_4EBA
	dw Pat_4F24
	dw Pat_4F35
	dw Pat_4EBA
	dw Pat_4F46
	dw Pat_4F46
	dw Pat_4F6D
	ORDER_LOOP Loop_4D93
Song2_Ch2:
	dw Pat_4FA7
	dw Pat_4FC1
Loop_4DAB:
	dw Pat_4FC9
	dw Pat_4FC9
	dw Pat_5035
	dw Pat_5049
	dw Pat_4FC1
	dw Pat_5058
	dw Pat_5058
	dw Pat_5085
	ORDER_LOOP Loop_4DAB
Pat_4DBF:
	HWENV $69, $04, $C0
	RELEASE $02, $72
	DUTY_75
	VIBRATO $12, $01, $06
	LENGTH $48
	NOTE F_, 2
	NOTE Csh, 2
	LEN 36
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	LEN 18
	NOTE Ash, 2
	NOTE C_, 3
	NEXT
Pat_4DD7:
	DRUMS $09, DrumPat_50B8
	RELEASE $00
	LEN 18
	REPEAT 2
	INSTR 0
	NOTE F_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE E_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 4
	NOTE E_, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE F_, 2
	INSTR 5
	NOTE F_, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE Ash, 2
	INSTR 5
	NOTE Ash, 4
	REPEAT_END
	INSTR 0
	NOTE C_, 2
	INSTR 4
	NOTE E_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE E_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 4
	NOTE F_, 4
	NOTE E_, 4
	INSTR 0
	LEN 9
	NOTE D_, 2
	NOTE E_, 2
	NEXT
Pat_4E0E:
	LEN 18
	REPEAT 4
	INSTR 0
	NOTE Ash, 2
	INSTR 5
	NOTE Ash, 4
	INSTR 0
	NOTE F_, 2
	INSTR 5
	NOTE Ash, 4
	REPEAT_END
	REPEAT 3
	INSTR 0
	NOTE F_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 5
	NOTE F_, 4
	REPEAT_END
	INSTR 0
	NOTE F_, 2
	NOTE E_, 2
	NOTE Dsh, 2
	NOTE D_, 2
	REPEAT 4
	INSTR 0
	NOTE Ash, 2
	INSTR 5
	NOTE Ash, 4
	INSTR 0
	NOTE F_, 2
	INSTR 5
	NOTE Ash, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE F_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 5
	NOTE F_, 4
	REPEAT_END
	INSTR 0
	NOTE C_, 2
	INSTR 6
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 6
	NOTE C_, 4
	INSTR 0
	LEN 36
	NOTE C_, 2
	NOTE C_, 3
	NEXT
Pat_4E49:
	LEN 36
	REPEAT 2
	INSTR 0
	NOTE F_, 2
	INSTR 5
	NOTE F_, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE C_, 2
	INSTR 4
	NOTE E_, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE Csh, 2
	INSTR 6
	NOTE Csh, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE C_, 2
	INSTR 6
	NOTE C_, 4
	REPEAT_END
	NEXT
Pat_4E63:
	INSTR 0
	LEN 18
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 2
	INSTR 5
	LEN 9
	NOTE Ash, 3
	NOTE Ash, 3
	LEN 36
	NOTE Ash, 3
	INSTR 0
	LEN 18
	NOTE Ash, 2
	NOTE C_, 3
	NOTE Csh, 3
	NOTE Csh, 3
	NOTE Csh, 3
	INSTR 6
	LEN 9
	NOTE Csh, 4
	NOTE Csh, 4
	LENGTH $48
	NOTE Csh, 4
	INSTR 0
	LEN 18
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	INSTR 6
	LEN 9
	NOTE C_, 5
	NOTE C_, 5
	LEN 18
	NOTE C_, 5
	INSTR 0
	NOTE C_, 2
	LEN 36
	NOTE C_, 2
	LEN 18
	NOTE C_, 3
	INSTR 6
	NOTE C_, 5
	INSTR 0
	NOTE C_, 3
	INSTR 6
	NOTE C_, 5
	INSTR 0
	NOTE C_, 3
	INSTR 6
	NOTE C_, 5
	INSTR 0
	NOTE C_, 3
	LEN 9
	NOTE Gsh, 2
	NOTE G_, 2
	NEXT
Pat_4E9D:
	VOLENV 10, $15, $11, $11
	RELEASE $04, $A1
	VIBRATO $12, $01, $06
	CH_TRANSPOSE $00
	WAVE Wave_7907
	LENGTH $48
	NOTE C_, 4
	NOTE Csh, 4
	LEN 36
	NOTE E_, 4
	NOTE C_, 4
	LEN 18
	NOTE Ash, 3
	NOTE Csh, 4
	NOTE E_, 4
	NOTE C_, 4
	NEXT
Pat_4EBA:
	VOLENV 12, $11, $1F, $12
	CH_TRANSPOSE $0C
	VIB_OFF
	RELEASE $00
	WAVE Wave_7A77
	LEN 18
	NOTE F_, 1
	NOTE Gsh, 3
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE F_, 1
	NOTE Gsh, 3
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE Csh, 4
	NOTE Ash, 3
	NOTE Csh, 4
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE Csh, 4
	NOTE C_, 4
	NOTE G_, 3
	LEN 9
	NOTE Ash, 3
	NOTE Gsh, 3
	LEN 18
	NOTE G_, 3
	NEXT
Pat_4EEB:
	LEN 18
	NOTE Ash, 3
	LEN 9
	NOTE Csh, 4
	NOTE C_, 4
	LEN 18
	NOTE Ash, 3
	LEN 9
	NOTE Csh, 4
	NOTE C_, 4
	LEN 18
	NOTE Ash, 3
	LEN 9
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE C_, 4
	LEN 18
	NOTE Ash, 3
	LEN 9
	NOTE Csh, 4
	NOTE C_, 4
	LEN 18
	NOTE Ash, 3
	LEN 9
	NOTE Csh, 4
	NOTE C_, 4
	LEN 18
	NOTE Ash, 3
	LEN 9
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE G_, 3
	LEN 18
	NOTE F_, 3
	LEN 9
	NOTE Gsh, 3
	NOTE G_, 3
	LEN 18
	NOTE F_, 3
	LEN 9
	NOTE Gsh, 3
	NOTE G_, 3
	LEN 18
	NOTE F_, 3
	LEN 9
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	NEXT
Pat_4F24:
	PAT_CALL Pat_4EEB
	NOTE G_, 3
	LEN 18
	NOTE Gsh, 3
	LEN 9
	NOTE Gsh, 3
	NOTE G_, 3
	LEN 18
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NEXT
Pat_4F35:
	PAT_CALL Pat_4EEB
	NOTE F_, 3
	LEN 18
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	NOTE F_, 3
	LEN 18
	NOTE E_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE Csh, 4
	NEXT
Pat_4F46:
	VOLENV 15, $11, $1F, $15
	RELEASE $00
	ARP 0
	WAVE Wave_7A17
	LEN 36
	WAIT
	LEN 18
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 36
	NOTE Gsh, 4
	LEN 18
	NOTE Gsh, 4
	NOTE G_, 4
	LENGTH $48
	NOTE F_, 4
	LENGTH $6C
	NOTE E_, 4
	LEN 18
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 36
	NOTE F_, 4
	LEN 18
	NOTE F_, 4
	NOTE Dsh, 4
	LENGTH $48
	NOTE Csh, 4
	NOTE C_, 4
	NEXT
Pat_4F6D:
	VOLENV 10, $15, $11, $11
	RELEASE $04, $A1
	VIBRATO $12, $01, $06
	ARP_OFF
	WAVE Wave_79F7
	LENGTH $5A
	NOTE Csh, 5
	LEN 9
	NOTE Ash, 4
	NOTE C_, 5
	LEN 18
	NOTE Csh, 5
	NOTE Dsh, 5
	LENGTH $5A
	NOTE F_, 5
	LEN 9
	NOTE Csh, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE Ash, 5
	LENGTH $7E
	NOTE C_, 6
	LEN 9
	NOTE Ash, 5
	NOTE Gsh, 5
	NOTE G_, 5
	WAIT2
	NOTE C_, 6
	WAIT2
	NOTE F_, 5
	WAIT2
	NOTE C_, 6
	WAIT2
	NOTE E_, 5
	WAIT2
	NOTE C_, 6
	WAIT2
	LEN 18
	NOTE Csh, 6
	LEN 9
	NOTE C_, 6
	WAIT2
	NEXT
Pat_4FA7:
	HWENV $69, $04, $C0
	RELEASE $02, $72
	DUTY_75
	VIBRATO $12, $01, $06
	LENGTH $48
	NOTE F_, 4
	LEN 36
	NOTE F_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE E_, 4
	LEN 18
	NOTE G_, 4
	NOTE Ash, 4
	NOTE Csh, 5
	NOTE E_, 4
	NEXT
Pat_4FC1:
	LENGTH $48
	NOTE F_, 4
	LENGTH $FC
	WAIT2
	WAIT2
	NEXT
Pat_4FC9:
	HWENV $69, $04, $C0
	RELEASE $02, $72
	DUTY_75
	VIBRATO $12, $01, $06
	LEN 18
	NOTE F_, 3
	NOTE F_, 4
	NOTE F_, 5
	NOTE Csh, 5
	LEN 27
	NOTE C_, 5
	LEN 9
	WAIT2
	LEN 18
	NOTE G_, 4
	NOTE Ash, 4
	LEN 27
	NOTE Gsh, 4
	LEN 9
	WAIT2
	LEN 27
	NOTE F_, 4
	LEN 9
	WAIT2
	LEN 18
	NOTE B_, 4
	NOTE C_, 5
	LEN 36
	NOTE G_, 4
	LEN 18
	NOTE F_, 3
	NOTE F_, 4
	LEN 9
	NOTE F_, 5
	WAIT2
	LEN 18
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE F_, 4
	NOTE Gsh, 4
	LEN 27
	NOTE G_, 4
	LEN 9
	WAIT2
	LEN 27
	NOTE G_, 4
	LEN 9
	WAIT2
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 27
	WAIT
	LEN 9
	WAIT2
	WAIT2
	NEXT
Pat_500B:
	LEN 45
	NOTE Csh, 5
	LEN 9
	WAIT2
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	WAIT2
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	LEN 45
	NOTE Csh, 5
	LEN 9
	WAIT2
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	WAIT2
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE G_, 4
	LEN 45
	NOTE Gsh, 4
	LEN 9
	WAIT2
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	WAIT2
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NEXT
Pat_5035:
	DUTY_12
	PAT_CALL Pat_500B
	NOTE G_, 4
	LEN 45
	NOTE Gsh, 4
	LEN 9
	WAIT2
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE B_, 4
	WAIT2
	NOTE C_, 5
	WAIT2
	NEXT
Pat_5049:
	PAT_CALL Pat_500B
	NOTE F_, 4
	LEN 45
	NOTE G_, 4
	LEN 9
	WAIT2
	LEN 18
	NOTE F_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NEXT
Pat_5058:
	DUTY_75
	HWENV $A4, $00
	VIB_OFF
	RELEASE $00
	LEN 18
	NOTE F_, 3
	NOTE Gsh, 3
	LEN 36
	NOTE C_, 4
	LEN 18
	NOTE F_, 3
	NOTE Gsh, 3
	LEN 36
	NOTE C_, 4
	LEN 18
	NOTE E_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE E_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE Csh, 3
	NOTE F_, 3
	LEN 36
	NOTE Gsh, 3
	LEN 18
	NOTE Csh, 3
	NOTE F_, 3
	LEN 36
	NOTE Gsh, 3
	LEN 18
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NEXT
Pat_5085:
	LEN 18
	WAIT
	LEN 9
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE C_, 4
	LEN 36
	NOTE Ash, 3
	LENGTH $36
	NOTE F_, 3
	LEN 9
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	LEN 36
	NOTE Gsh, 4
	LENGTH $36
	NOTE F_, 4
	LEN 9
	NOTE E_, 4
	NOTE F_, 4
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 18
	NOTE Ash, 4
	LEN 9
	NOTE Ash, 4
	NOTE C_, 5
	LEN 18
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE C_, 5
	NEXT
DrumPat_50B8:
	db DRUM_LEVEL + 12, 1, 0, 5, 0, DRUM_LOOP

; Song 3: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong3:
	ld a, $75
	ld [wInstrTableHi], a
	ld a, $72
	ld [wInstrTable], a
	call StopAll
	ld de, Song3_Ch1
	call StartMusicCh1
	ld de, Song3_Ch3
	call StartMusicCh3
	ld de, Song3_Ch2
	jp StartMusicCh2

; Unreferenced (1 bytes)
	db $C9
Song3_Ch1:
	dw Pat_514F
	dw Pat_517E
	dw Pat_5126
	dw Pat_5126
	dw Pat_5126
	dw Pat_52CB
	dw Pat_52CB
	dw Pat_5126
	dw Pat_5126
	dw Pat_519D
	ORDER_LOOP Song3_Ch1
Song3_Ch3:
	dw Pat_51CC
	dw Pat_51DD
	dw Pat_51E5
	dw Pat_51C1
	dw Pat_51C1
	dw Pat_52F0
	dw Pat_52F0
	dw Pat_51C1
	dw Pat_51C1
	dw Pat_51F0
	ORDER_LOOP Song3_Ch3
Song3_Ch2:
	dw Pat_524B
	dw Pat_5273
	dw Pat_5292
	dw Pat_51F8
	dw Pat_51F8
	dw Pat_52F8
	dw Pat_532C
	dw Pat_524B
	dw Pat_5273
	dw Pat_52B2
	ORDER_LOOP Song3_Ch2
Pat_5126:
	INSTR 12
	LEN 13
	DRUMS $0D, DrumPat_535F
	REPEAT 4
	NOTE Dsh, 2
	INSTR 9
	NOTE Dsh, 3
	INSTR 1
	NOTE D_, 3
	INSTR 12
	LEN 26
	NOTE Dsh, 2
	INSTR 9
	LEN 13
	NOTE Dsh, 3
	INSTR 1
	NOTE D_, 3
	INSTR 12
	NOTE D_, 2
	REPEAT_END
	REPEAT 4
	NOTE Ash, 2
	INSTR 9
	NOTE Ash, 3
	INSTR 1
	NOTE D_, 3
	INSTR 12
	LEN 26
	NOTE Ash, 2
	INSTR 9
	LEN 13
	NOTE Ash, 3
	INSTR 1
	NOTE D_, 3
	INSTR 12
	NOTE A_, 2
	REPEAT_END
	NEXT
Pat_514F:
	DUTY_50
	HWENV $40, $00
	VIBRATO $46, $01, $01
	AUTODUTY $0D
	ARP_OFF
	LENGTH $75
	NOTE Ash, 6
	LENGTH $34
	NOTE A_, 6
	LEN 39
	NOTE D_, 6
	LEN 13
	NOTE Dsh, 6
	LENGTH $C3
	NOTE F_, 6
	LEN 13
	NOTE A_, 6
	LENGTH $5B
	NOTE Ash, 6
	LENGTH $34
	NOTE A_, 6
	LEN 13
	NOTE F_, 6
	LEN 39
	NOTE C_, 6
	LEN 13
	NOTE Csh, 6
	LENGTH $8F
	NOTE D_, 6
	LEN 13
	NOTE D_, 6
	NOTE Dsh, 6
	NOTE E_, 6
	NOTE F_, 6
	NEXT
Pat_517E:
	LEN 13
	WAIT
	LENGTH $9C
	NOTE Ash, 5
	LENGTH $34
	NOTE C_, 6
	LEN 13
	NOTE D_, 6
	NOTE Dsh, 6
	LENGTH $82
	NOTE F_, 6
	LEN 26
	NOTE D_, 6
	NOTE F_, 6
	LENGTH $68
	NOTE Ash, 5
	LENGTH $34
	NOTE G_, 5
	LEN 39
	NOTE Ash, 5
	LEN 13
	NOTE C_, 6
	LENGTH $C3
	NOTE Ash, 5
	NEXT
Pat_519D:
	AUTODUTY $00
	INSTR 12
	LEN 26
	NOTE Gsh, 2
	INSTR 1
	LEN 13
	NOTE D_, 3
	INSTR 12
	LEN 39
	NOTE Gsh, 2
	INSTR 1
	LENGTH $34
	NOTE D_, 3
	REPEAT 3
	NOTE D_, 3
	LEN 26
	NOTE D_, 3
	INSTR 12
	NOTE Gsh, 2
	INSTR 1
	LEN 13
	NOTE D_, 3
	INSTR 12
	LEN 39
	NOTE Gsh, 2
	INSTR 1
	LENGTH $34
	NOTE D_, 3
	REPEAT_END
	NOTE D_, 3
	LEN 26
	NOTE D_, 3
	NEXT
Pat_51C1:
	ARP 15
	LENGTH $D0
	NOTE G_, 4
	ARP 17
	NOTE G_, 4
	ARP 15
	NOTE D_, 4
	ARP 17
	NOTE D_, 4
	NEXT
Pat_51CC:
	VOLENV 5, $1F, $1F, $88
	CH_TRANSPOSE $0C
	WAVE Wave_7AA7
	ARP 15
	LENGTH $D0
	NOTE G_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE D_, 4
	NEXT
Pat_51DD:
	ARP 15
	LENGTH $D0
	NOTE G_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE D_, 4
	NEXT
Pat_51E5:
	ARP 15
	LENGTH $D0
	NOTE G_, 4
	ARP 17
	NOTE G_, 4
	ARP 15
	NOTE D_, 4
	ARP 17
	NOTE D_, 4
	NEXT
Pat_51F0:
	ARP 15
	LENGTH $D0
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 5
	NOTE C_, 6
	NEXT
Pat_51F8:
	AUTODUTY $00
	LEN 26
	WAIT
	HWENV $F4, $00
	ARP 0
	VIBRATO $0D, $02, $05
	NOTE Ash, 3
	NOTE G_, 3
	LEN 13
	NOTE Ash, 3
	LEN 39
	NOTE D_, 4
	LEN 26
	NOTE Ash, 3
	LEN 13
	NOTE G_, 3
	LEN 26
	NOTE Ash, 3
	LEN 39
	NOTE F_, 3
	LEN 13
	NOTE Ash, 3
	NOTE Ash, 3
	LEN 26
	NOTE G_, 3
	LEN 13
	NOTE Ash, 3
	LEN 26
	NOTE D_, 4
	LEN 13
	NOTE Dsh, 4
	NOTE D_, 4
	LEN 26
	NOTE Ash, 3
	NOTE G_, 3
	LEN 39
	NOTE C_, 4
	ARP 2
	HWENV $C2, $0F, $40
	VIB_OFF
	LEN 13
	NOTE Ash, 4
	NOTE Ash, 4
	LEN 26
	NOTE A_, 4
	LEN 13
	NOTE Ash, 4
	LEN 39
	NOTE F_, 5
	LEN 13
	NOTE Ash, 4
	NOTE Ash, 4
	LEN 26
	NOTE A_, 4
	LEN 13
	NOTE Ash, 4
	LEN 39
	NOTE F_, 4
	LEN 13
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE A_, 4
	LEN 26
	NOTE Ash, 4
	NOTE A_, 5
	LEN 13
	NOTE Ash, 5
	NOTE A_, 5
	LEN 26
	NOTE F_, 5
	NOTE D_, 5
	LEN 13
	NOTE G_, 5
	NEXT
Pat_524B:
	ARP_OFF
	HWENV $F3, $1E, $40
	DUTY_50
	VIBRATO $0F, $01, $05
	AUTODUTY $00
	LENGTH $68
	NOTE Ash, 5
	LENGTH $34
	NOTE A_, 5
	NOTE D_, 5
	LEN 4
	NOTE E_, 5
	LENGTH $CC
	NOTE F_, 5
	LENGTH $68
	NOTE Ash, 5
	LENGTH $34
	NOTE A_, 5
	NOTE C_, 5
	LEN 4
	NOTE Csh, 5
	LENGTH $98
	NOTE D_, 5
	LEN 26
	NOTE Dsh, 5
	NOTE F_, 5
	NEXT
Pat_5273:
	LENGTH $9C
	NOTE Ash, 4
	LENGTH $34
	NOTE C_, 5
	LEN 13
	NOTE D_, 5
	NOTE Dsh, 5
	LENGTH $82
	NOTE F_, 5
	LEN 26
	NOTE D_, 5
	NOTE F_, 5
	LENGTH $68
	NOTE Ash, 4
	LENGTH $34
	NOTE G_, 4
	LEN 39
	NOTE Ash, 4
	LEN 3
	NOTE B_, 4
	LEN 10
	NOTE C_, 5
	LENGTH $D0
	NOTE Ash, 4
	NEXT
Pat_5292:
	DUTY_50
	HWENV $50, $00
	VIBRATO $46, $01, $01
	ARP_OFF
	AUTODUTY $0D
	LENGTH $68
	NOTE Ash, 4
	NOTE G_, 4
	NOTE D_, 5
	LEN 39
	NOTE Dsh, 5
	NOTE D_, 5
	LEN 26
	NOTE Ash, 4
	LENGTH $D0
	NOTE A_, 4
	LENGTH $68
	NOTE D_, 4
	LENGTH $34
	NOTE A_, 4
	NOTE D_, 5
	NEXT
Pat_52B2:
	DRUMS $0D, DrumPat_5379
	HWENV $C1, $09, $91
	ARP_OFF
	DUTY_75
	AUTODUTY $0D
	LEN 13
	REPEAT 8
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Dsh, 4
	REPEAT_END
	DRUMS_OFF
	NEXT
Pat_52CB:
	INSTR 12
	LEN 13
	REPEAT 4
	NOTE Gsh, 2
	INSTR 9
	NOTE Gsh, 3
	INSTR 1
	NOTE D_, 3
	INSTR 12
	LEN 26
	NOTE Gsh, 2
	INSTR 9
	LEN 13
	NOTE Gsh, 3
	INSTR 1
	NOTE D_, 3
	INSTR 12
	NOTE G_, 2
	REPEAT_END
	REPEAT 4
	NOTE G_, 2
	INSTR 9
	NOTE G_, 3
	INSTR 1
	NOTE D_, 3
	INSTR 12
	LEN 26
	NOTE G_, 2
	INSTR 9
	LEN 13
	NOTE G_, 3
	INSTR 1
	NOTE D_, 3
	INSTR 12
	NOTE F_, 2
	REPEAT_END
	NEXT
Pat_52F0:
	ARP 15
	LENGTH $D0
	NOTE C_, 4
	NOTE C_, 3
	NOTE G_, 3
	NOTE G_, 4
	NEXT
Pat_52F8:
	LENGTH $68
	WAIT
	LENGTH $34
	NOTE F_, 5
	NOTE Ash, 5
	LENGTH $68
	NOTE G_, 5
	LENGTH $34
	NOTE F_, 5
	NOTE Dsh, 5
	LEN 26
	NOTE D_, 5
	LEN 13
	NOTE Dsh, 5
	LEN 26
	NOTE D_, 5
	LENGTH $68
	NOTE Ash, 4
	ARP_OFF
	LEN 13
	NOTE G_, 4
	NOTE Ash, 4
	NOTE C_, 5
	ARP 3
	LEN 26
	NOTE C_, 5
	ARP_OFF
	LEN 13
	NOTE Dsh, 5
	LEN 26
	NOTE D_, 5
	NOTE Ash, 4
	ARP 3
	NOTE F_, 5
	ARP_OFF
	LEN 13
	NOTE F_, 5
	NOTE D_, 5
	ARP 3
	LEN 26
	NOTE Gsh, 5
	ARP_OFF
	LEN 13
	NOTE F_, 5
	LEN 26
	NOTE D_, 5
	NEXT
Pat_532C:
	ARP 2
	LENGTH $68
	NOTE G_, 5
	LENGTH $34
	NOTE F_, 5
	NOTE Ash, 5
	LENGTH $68
	NOTE G_, 5
	LENGTH $34
	NOTE F_, 5
	NOTE Dsh, 5
	LEN 26
	NOTE D_, 5
	LEN 13
	NOTE Dsh, 5
	LEN 26
	NOTE D_, 5
	LENGTH $68
	NOTE Ash, 4
	ARP_OFF
	LEN 13
	NOTE G_, 4
	NOTE Ash, 4
	NOTE C_, 5
	ARP 3
	LEN 26
	NOTE C_, 5
	ARP_OFF
	LEN 13
	NOTE Dsh, 5
	LEN 26
	NOTE D_, 5
	NOTE Ash, 4
	ARP 3
	NOTE C_, 6
	ARP_OFF
	LEN 13
	NOTE Ash, 5
	NOTE F_, 5
	LEN 26
	NOTE D_, 5
	LEN 13
	NOTE F_, 5
	NOTE Ash, 5
	NOTE G_, 5
	NEXT
DrumPat_535F:
	db DRUM_TEMPO + 13, DRUM_LEVEL + 15, DRUM_REPEAT + 3, 5, 3, 9, 6, DRUM_REPEAT_END
	db 5, 3, 9, 4, DRUM_REPEAT + 3, 5, 3, 9
	db 6, DRUM_REPEAT_END, 5, 3, 9, DRUM_TEMPO + 6, 6, DRUM_TEMPO + 7
	db 6, DRUM_LOOP
DrumPat_5379:
	db DRUM_LEVEL + 15, 4, 0, 1, 6, DRUM_LOOP

; Song 4: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong4:
	ld a, $75
	ld [wInstrTableHi], a
	ld a, $72
	ld [wInstrTable], a
	call StopAll
	ld de, Song4_Ch1
	call StartMusicCh1
	ld de, Song4_Ch2
	call StartMusicCh2
	ld de, Song4_Ch3
	jp StartMusicCh3

; Unreferenced (1 bytes)
	db $C9
Song4_Ch1:
	dw Pat_53C3
	dw Pat_53C3
	dw Pat_5438
	dw Pat_5438
	ORDER_LOOP Song4_Ch1
Song4_Ch2:
	dw Pat_54A9
	dw Pat_54A9
	dw Pat_5511
	dw Pat_5511
	ORDER_LOOP Song4_Ch2
Song4_Ch3:
	dw Pat_5574
	dw Pat_5574
	dw Pat_55AA
	dw Pat_55AA
	ORDER_LOOP Song4_Ch3
Pat_53C3:
	DRUMS $0D, DrumPat_55DB
	INSTR 12
	LEN 26
	NOTE G_, 2
	INSTR 1
	LEN 13
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	LEN 26
	NOTE A_, 2
	INSTR 1
	LEN 13
	NOTE F_, 3
	INSTR 12
	LEN 26
	NOTE B_, 2
	LEN 13
	NOTE B_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	LEN 26
	NOTE A_, 2
	INSTR 1
	LEN 13
	NOTE F_, 3
	INSTR 12
	NOTE D_, 2
	LEN 26
	NOTE G_, 2
	INSTR 1
	LEN 13
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	LEN 26
	NOTE A_, 2
	INSTR 1
	LEN 13
	NOTE F_, 3
	INSTR 12
	LEN 26
	NOTE B_, 2
	LEN 13
	NOTE B_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	LEN 26
	NOTE A_, 2
	INSTR 1
	LEN 13
	NOTE F_, 3
	INSTR 12
	NOTE D_, 2
	LEN 26
	NOTE G_, 2
	INSTR 1
	LEN 13
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	LEN 26
	NOTE A_, 2
	INSTR 1
	LEN 13
	NOTE F_, 3
	INSTR 12
	LEN 26
	NOTE B_, 2
	LEN 13
	NOTE B_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	LEN 26
	NOTE A_, 2
	INSTR 1
	LEN 13
	NOTE F_, 3
	INSTR 12
	NOTE D_, 2
	LEN 26
	NOTE G_, 2
	INSTR 1
	LEN 13
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	LEN 26
	NOTE A_, 2
	INSTR 1
	LEN 13
	NOTE F_, 3
	INSTR 12
	LEN 26
	NOTE B_, 2
	LEN 13
	NOTE B_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 12
	NOTE D_, 3
	NOTE D_, 3
	NOTE A_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 12
	NOTE D_, 2
	NEXT
Pat_5438:
	INSTR 12
	LEN 26
	NOTE C_, 2
	INSTR 1
	LEN 13
	NOTE F_, 3
	INSTR 12
	NOTE C_, 2
	LEN 26
	NOTE C_, 3
	INSTR 1
	LEN 13
	NOTE F_, 3
	INSTR 12
	LEN 26
	NOTE C_, 2
	LEN 13
	NOTE C_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 12
	NOTE C_, 2
	LEN 26
	NOTE C_, 3
	INSTR 1
	LEN 13
	NOTE F_, 3
	INSTR 12
	NOTE G_, 2
	LEN 26
	NOTE G_, 2
	INSTR 1
	LEN 13
	NOTE F_, 3
	INSTR 12
	NOTE G_, 2
	LEN 26
	NOTE A_, 2
	INSTR 1
	LEN 13
	NOTE F_, 3
	INSTR 12
	LEN 26
	NOTE B_, 2
	LEN 13
	NOTE B_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	LEN 26
	NOTE A_, 2
	INSTR 1
	LEN 13
	NOTE F_, 3
	INSTR 12
	NOTE G_, 2
	LEN 26
	NOTE C_, 2
	INSTR 1
	LEN 13
	NOTE F_, 3
	INSTR 12
	NOTE C_, 2
	LEN 26
	NOTE C_, 3
	INSTR 1
	LEN 13
	NOTE F_, 3
	INSTR 12
	LEN 26
	NOTE C_, 2
	LEN 13
	NOTE C_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 12
	NOTE C_, 2
	LEN 26
	NOTE C_, 3
	INSTR 1
	LEN 13
	NOTE F_, 3
	INSTR 12
	NOTE G_, 2
	LEN 26
	NOTE G_, 2
	INSTR 1
	LEN 13
	NOTE F_, 3
	INSTR 12
	NOTE G_, 2
	LEN 26
	NOTE A_, 2
	INSTR 1
	LEN 13
	NOTE F_, 3
	INSTR 12
	LEN 26
	NOTE B_, 2
	LEN 13
	NOTE B_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	NOTE A_, 2
	NOTE D_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 12
	NOTE D_, 2
	NEXT
Pat_54A9:
	HWENV $D1, $05, $83
	DUTY_75
	ARP 0
	LEN 13
	NOTE G_, 4
	NOTE G_, 3
	ARP 6
	NOTE G_, 4
	ARP 0
	NOTE D_, 4
	NOTE E_, 4
	NOTE A_, 3
	ARP 5
	NOTE A_, 4
	ARP 0
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE B_, 3
	ARP 5
	NOTE B_, 4
	ARP 0
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE C_, 4
	ARP 6
	NOTE C_, 5
	ARP 0
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 3
	ARP 6
	NOTE G_, 4
	ARP 0
	NOTE D_, 4
	NOTE E_, 4
	NOTE A_, 3
	ARP 5
	NOTE A_, 4
	ARP 0
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE B_, 3
	ARP 5
	NOTE B_, 4
	ARP 0
	NOTE G_, 4
	NOTE E_, 4
	NOTE G_, 4
	ARP 6
	NOTE C_, 5
	ARP 0
	NOTE A_, 4
	NOTE G_, 4
	NOTE G_, 3
	ARP 6
	NOTE G_, 4
	ARP 0
	NOTE D_, 4
	NOTE E_, 4
	NOTE A_, 3
	ARP 5
	NOTE A_, 4
	ARP 0
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE B_, 3
	ARP 5
	NOTE B_, 4
	ARP 0
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE C_, 4
	ARP 6
	NOTE C_, 5
	ARP 0
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 3
	ARP 6
	NOTE G_, 4
	ARP 0
	NOTE D_, 4
	NOTE E_, 4
	NOTE A_, 3
	ARP 5
	NOTE A_, 4
	ARP 0
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE B_, 3
	ARP 5
	NOTE B_, 4
	ARP 0
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE E_, 4
	ARP 6
	NOTE C_, 5
	ARP 0
	NOTE A_, 4
	NEXT
Pat_5511:
	ARP 0
	LEN 13
	NOTE G_, 4
	NOTE C_, 4
	ARP 6
	NOTE C_, 5
	ARP 0
	NOTE G_, 4
	NOTE A_, 4
	NOTE D_, 4
	ARP 6
	NOTE D_, 5
	ARP 0
	NOTE A_, 4
	NOTE B_, 4
	NOTE E_, 4
	ARP 5
	NOTE E_, 5
	ARP 0
	NOTE B_, 4
	NOTE A_, 4
	NOTE D_, 4
	ARP 6
	NOTE D_, 5
	ARP 0
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE G_, 3
	ARP 6
	NOTE G_, 4
	ARP 0
	NOTE D_, 4
	NOTE E_, 4
	NOTE A_, 3
	ARP 5
	NOTE A_, 4
	ARP 0
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE B_, 3
	ARP 5
	NOTE B_, 4
	ARP 0
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE C_, 4
	ARP 6
	NOTE C_, 5
	ARP 0
	NOTE G_, 4
	NOTE G_, 4
	NOTE C_, 4
	ARP 6
	NOTE C_, 5
	ARP 0
	NOTE G_, 4
	NOTE A_, 4
	NOTE D_, 4
	ARP 6
	NOTE D_, 5
	ARP 0
	NOTE A_, 4
	NOTE B_, 4
	NOTE E_, 4
	ARP 5
	NOTE E_, 5
	ARP 0
	NOTE B_, 4
	NOTE A_, 4
	NOTE D_, 4
	ARP 6
	NOTE D_, 5
	ARP 0
	NOTE A_, 4
	NOTE D_, 4
	NOTE G_, 3
	ARP 6
	NOTE G_, 4
	ARP 0
	NOTE D_, 4
	NOTE E_, 4
	NOTE A_, 3
	ARP 5
	NOTE A_, 4
	ARP 0
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE B_, 3
	ARP 5
	NOTE B_, 4
	ARP 0
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE C_, 4
	ARP 6
	NOTE C_, 5
	ARP 0
	NOTE G_, 4
	NEXT
Pat_5574:
	VOLENV 15, $11, $1A, $16
	CH_TRANSPOSE $0C
	RELEASE $01, $51
	WAVE Wave_7937
	VIBRATO $0D, $01, $06
	LEN 26
	WAIT
	LEN 13
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	LEN 26
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	LENGTH $F7
	NOTE D_, 4
	LEN 13
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	LEN 26
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	LEN 39
	NOTE A_, 4
	LENGTH $5B
	NOTE G_, 4
	LENGTH $34
	NOTE A_, 4
	LENGTH $41
	NOTE B_, 4
	NEXT
Pat_55AA:
	LENGTH $41
	NOTE D_, 5
	LEN 13
	NOTE G_, 4
	NOTE A_, 4
	LEN 26
	NOTE B_, 4
	NOTE D_, 5
	LEN 13
	NOTE C_, 5
	LEN 26
	NOTE B_, 4
	NOTE G_, 4
	LEN 39
	NOTE Fsh, 4
	NOTE G_, 4
	LENGTH $34
	NOTE D_, 4
	LEN 26
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	LENGTH $41
	NOTE D_, 5
	LEN 13
	NOTE G_, 4
	NOTE A_, 4
	LEN 26
	NOTE B_, 4
	NOTE D_, 5
	LEN 13
	NOTE C_, 5
	LEN 26
	NOTE B_, 4
	NOTE G_, 4
	LEN 39
	NOTE Fsh, 4
	NOTE G_, 4
	LENGTH $34
	NOTE D_, 5
	LEN 26
	NOTE E_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NEXT
DrumPat_55DB:
	db DRUM_LEVEL + 13, 1, 5, 9, 5, DRUM_LOOP

; Song 5: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong5:
	ld a, $75
	ld [wInstrTableHi], a
	ld a, $72
	ld [wInstrTable], a
	call StopAll
	ld de, Song5_Ch1
	call StartMusicCh1
	ld de, Song5_Ch2
	call StartMusicCh2
	ld de, Song5_Ch3
	jp StartMusicCh3
Song5_Ch1:
	dw Pat_5630
	dw Pat_565F
	dw Pat_5693
	dw Pat_5693
	dw Pat_56D5
	dw Pat_570F
	ORDER_LOOP Song5_Ch1
Song5_Ch2:
	dw Pat_5749
	dw Pat_5773
	dw Pat_579A
	dw Pat_579A
	dw Pat_57BD
	dw Pat_57DA
	ORDER_LOOP Song5_Ch2
Song5_Ch3:
	dw Pat_57F8
	dw Pat_582A
	dw Pat_5848
	dw Pat_5848
	dw Pat_586A
	dw Pat_588E
	ORDER_LOOP Song5_Ch3
Pat_5630:
	INSTR 12
	LEN 32
	NOTE F_, 2
	INSTR 5
	LEN 16
	NOTE F_, 4
	INSTR 12
	NOTE F_, 2
	LEN 32
	NOTE C_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 12
	NOTE G_, 2
	INSTR 6
	LEN 16
	NOTE G_, 4
	INSTR 12
	NOTE G_, 2
	LEN 32
	NOTE D_, 2
	INSTR 6
	NOTE G_, 4
	INSTR 12
	NOTE F_, 2
	INSTR 5
	LEN 16
	NOTE F_, 4
	INSTR 12
	NOTE F_, 2
	LEN 32
	NOTE C_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 12
	NOTE G_, 2
	INSTR 6
	LEN 16
	NOTE G_, 4
	INSTR 12
	NOTE B_, 2
	NOTE C_, 3
	NOTE B_, 2
	NOTE G_, 2
	INSTR 6
	NOTE G_, 4
	NEXT
Pat_565F:
	INSTR 12
	LEN 32
	NOTE F_, 2
	INSTR 5
	LEN 16
	NOTE F_, 4
	INSTR 12
	NOTE F_, 2
	LEN 32
	NOTE C_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 12
	NOTE G_, 2
	INSTR 6
	LEN 16
	NOTE G_, 4
	INSTR 12
	NOTE G_, 2
	LEN 32
	NOTE D_, 2
	INSTR 6
	LEN 16
	NOTE G_, 4
	INSTR 12
	NOTE G_, 2
	LEN 32
	NOTE Gsh, 2
	INSTR 6
	LEN 16
	NOTE Gsh, 4
	INSTR 12
	NOTE G_, 2
	LEN 32
	NOTE Fsh, 2
	INSTR 6
	LEN 16
	NOTE D_, 4
	INSTR 12
	NOTE Fsh, 2
	LEN 32
	NOTE G_, 2
	INSTR 6
	LEN 16
	NOTE G_, 4
	INSTR 12
	NOTE F_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE Dsh, 2
	NOTE D_, 2
	NEXT
Pat_5693:
	LEN 16
	INSTR 12
	NOTE C_, 2
	INSTR 5
	NOTE C_, 4
	INSTR 12
	NOTE C_, 3
	INSTR 5
	NOTE C_, 4
	INSTR 12
	NOTE C_, 2
	INSTR 5
	NOTE C_, 4
	INSTR 12
	NOTE C_, 3
	INSTR 5
	NOTE C_, 4
	INSTR 12
	NOTE C_, 2
	INSTR 5
	NOTE G_, 4
	INSTR 12
	NOTE C_, 3
	INSTR 5
	NOTE G_, 4
	INSTR 12
	NOTE C_, 2
	INSTR 5
	NOTE G_, 4
	INSTR 12
	NOTE C_, 3
	INSTR 5
	NOTE G_, 4
	INSTR 12
	NOTE C_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 12
	NOTE C_, 3
	INSTR 5
	NOTE F_, 4
	INSTR 12
	NOTE C_, 2
	INSTR 6
	NOTE Dsh, 4
	INSTR 12
	NOTE C_, 3
	INSTR 6
	NOTE Dsh, 4
	INSTR 12
	NOTE C_, 2
	INSTR 6
	NOTE Csh, 4
	INSTR 12
	NOTE C_, 3
	INSTR 6
	NOTE Csh, 4
	INSTR 12
	NOTE C_, 2
	INSTR 5
	NOTE C_, 4
	INSTR 12
	NOTE C_, 3
	INSTR 5
	NOTE C_, 4
	NEXT
Pat_56D5:
	INSTR 12
	LEN 32
	NOTE G_, 2
	INSTR 6
	LEN 16
	NOTE G_, 3
	INSTR 12
	NOTE G_, 2
	LEN 32
	NOTE G_, 2
	INSTR 6
	LEN 16
	NOTE G_, 3
	INSTR 12
	NOTE G_, 2
	LEN 32
	NOTE G_, 2
	INSTR 6
	LEN 16
	NOTE G_, 3
	INSTR 12
	NOTE G_, 2
	LEN 32
	NOTE G_, 2
	INSTR 6
	LEN 16
	NOTE G_, 3
	INSTR 12
	NOTE G_, 2
	LEN 32
	NOTE C_, 2
	INSTR 5
	LEN 16
	NOTE C_, 4
	INSTR 12
	NOTE C_, 2
	LEN 32
	NOTE C_, 2
	INSTR 5
	LEN 16
	NOTE C_, 4
	INSTR 12
	NOTE C_, 2
	LEN 32
	NOTE C_, 2
	INSTR 5
	LEN 16
	NOTE C_, 4
	INSTR 12
	NOTE C_, 2
	LEN 32
	NOTE C_, 2
	INSTR 5
	LEN 16
	NOTE C_, 4
	INSTR 12
	NOTE C_, 2
	NEXT
Pat_570F:
	INSTR 12
	LEN 32
	NOTE F_, 2
	INSTR 5
	LEN 16
	NOTE F_, 4
	INSTR 12
	NOTE F_, 2
	LEN 32
	NOTE F_, 2
	INSTR 5
	LEN 16
	NOTE F_, 4
	INSTR 12
	NOTE F_, 2
	LEN 32
	NOTE F_, 2
	INSTR 5
	LEN 16
	NOTE F_, 4
	INSTR 12
	NOTE F_, 2
	LEN 32
	NOTE F_, 2
	INSTR 5
	LEN 16
	NOTE F_, 4
	INSTR 12
	NOTE G_, 2
	LEN 32
	NOTE Gsh, 2
	INSTR 6
	LEN 16
	NOTE Gsh, 4
	INSTR 12
	NOTE Gsh, 2
	LEN 32
	NOTE Gsh, 2
	INSTR 6
	LEN 16
	NOTE Gsh, 4
	INSTR 12
	NOTE Gsh, 2
	LEN 32
	NOTE G_, 2
	INSTR 6
	LEN 16
	NOTE G_, 4
	INSTR 12
	NOTE G_, 2
	LEN 32
	NOTE G_, 2
	INSTR 6
	LEN 16
	NOTE G_, 4
	INSTR 12
	NOTE G_, 2
	NEXT
Pat_5749:
	HWENV $D2, $00
	VIBRATO $08, $01, $06
	DUTY_75
	LEN 16
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE B_, 3
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NEXT
Pat_5773:
	LEN 16
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	LEN 8
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE G_, 5
	NEXT
Pat_579A:
	HWENV $89, $04, $D7
	LEN 32
	NOTE C_, 6
	NOTE C_, 6
	NOTE Ash, 5
	NOTE Ash, 5
	LEN 16
	NOTE Gsh, 5
	NOTE Ash, 5
	NOTE Gsh, 5
	NOTE Ash, 5
	LEN 32
	NOTE G_, 5
	LEN 16
	NOTE G_, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE Dsh, 5
	LEN 32
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	LEN 16
	NOTE C_, 5
	NOTE G_, 5
	NEXT
Pat_57BD:
	LENGTH $70
	NOTE B_, 4
	LEN 8
	NOTE B_, 4
	NOTE C_, 5
	LEN 16
	NOTE B_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE Gsh, 4
	LENGTH $70
	NOTE G_, 4
	LEN 16
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NEXT
Pat_57DA:
	LENGTH $50
	NOTE F_, 4
	LEN 16
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	LENGTH $50
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE Gsh, 5
	LEN 32
	NOTE G_, 5
	NOTE D_, 5
	NEXT
Pat_57F8:
	DRUMS $10, DrumPat_58A9
	VOLENV 15, $11, $1F, $17
	CH_TRANSPOSE $0A
	VIBRATO $10, $01, $06
	ARP 7
	RELEASE $02, $51
	WAVE Wave_7AC7
	LEN 16
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	LEN 32
	NOTE B_, 4
	LENGTH $60
	NOTE D_, 5
	LEN 16
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	LEN 32
	NOTE B_, 4
	LENGTH $60
	NOTE G_, 4
	NEXT
Pat_582A:
	LEN 16
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	LEN 32
	NOTE B_, 4
	LENGTH $50
	NOTE D_, 5
	LEN 16
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE Dsh, 5
	LEN 32
	NOTE D_, 5
	LENGTH $60
	NOTE B_, 4
	NEXT
Pat_5848:
	WAVE Wave_7937
	ARP 0
	CH_TRANSPOSE $0C
	LEN 32
	NOTE C_, 4
	NOTE C_, 4
	NOTE Ash, 3
	NOTE Ash, 3
	LEN 16
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	LEN 32
	NOTE G_, 3
	NOTE G_, 3
	LEN 16
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE F_, 3
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE Dsh, 3
	LEN 32
	NOTE D_, 3
	NOTE Dsh, 3
	NOTE C_, 3
	NOTE C_, 4
	NEXT
Pat_586A:
	LEN 16
	NOTE B_, 3
	NOTE B_, 3
	NOTE B_, 3
	NOTE C_, 4
	LEN 32
	NOTE D_, 4
	LENGTH $30
	NOTE G_, 3
	LEN 16
	NOTE B_, 2
	NOTE B_, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	LEN 32
	NOTE Dsh, 4
	LENGTH $30
	NOTE G_, 3
	LEN 16
	NOTE C_, 3
	NOTE C_, 3
	NOTE D_, 3
	NOTE Dsh, 3
	NOTE C_, 3
	NOTE D_, 3
	NOTE Dsh, 3
	NEXT
Pat_588E:
	LEN 16
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE G_, 3
	LEN 32
	NOTE Gsh, 3
	LENGTH $A0
	NOTE F_, 3
	LEN 16
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	LEN 32
	NOTE C_, 4
	NOTE Gsh, 3
	LEN 16
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE Gsh, 3
	LEN 32
	NOTE G_, 3
	NOTE G_, 4
	NEXT
DrumPat_58A9:
	db DRUM_LEVEL + 13, DRUM_REPEAT + 3, 5, 6, 9, 6, DRUM_REPEAT_END, 5
	db 6, 9, 4, DRUM_LOOP

; Song 6: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong6:
	ld a, $75
	ld [wInstrTableHi], a
	ld a, $72
	ld [wInstrTable], a
	ld de, Song6_Ch3
	call StartMusicCh3
	ld de, Song6_Ch2
	call StartMusicCh2
	ld de, Song6_Ch1
	call StartMusicCh1
	ret
Song6_Ch3:
	dw Pat_598B
	dw Pat_5915
	dw Pat_59E5
	dw Pat_590B
	dw Pat_5A08
	dw Pat_5910
Loop_58DE:
	dw Pat_5A0B
	ORDER_LOOP Loop_58DE
Song6_Ch2:
	dw Pat_59A2
	dw Pat_59AF
	dw Pat_58FD
	dw Pat_59AF
	dw Pat_5905
Loop_58EE:
	dw Pat_59AF
	ORDER_LOOP Loop_58EE
Song6_Ch1:
	dw Pat_591A
	ORDER_LOOP Song6_Ch1

; Unreferenced (3 bytes)
	db $7A, $00, $6A
Pat_58FD:
	CH_TRANSPOSE $0C
	NEXT

; Unreferenced (5 bytes)
	db $77, $B0, $F3, $7C, $6A
Pat_5905:
	HWENV $F1, $04, $86
	ARP 16
	NEXT
Pat_590B:
	DRUMS $0B, DrumPat_5A57
	NEXT
Pat_5910:
	DRUMS $0B, DrumPat_5A68
	NEXT
Pat_5915:
	DRUMS $0B, DrumPat_5A56
	NEXT
Pat_591A:
	HWENV $59, $03, $90
	RELEASE $05, $92
	DUTY_50
	VIBRATO $0B, $01, $04
	REPEAT 5
	PAT_CALL Pat_5939
	LENGTH $9A
	NOTE C_, 5
	LEN 22
	NOTE G_, 5
	REPEAT_END
	NEXT

; Unreferenced (8 bytes)
	db $7E, $39, $59, $6B, $BB, $30, $6D, $6A
Pat_5939:
	LENGTH $6E
	NOTE C_, 6
	LEN 11
	NOTE B_, 5
	NOTE C_, 6
	ARP 3
	NOTE C_, 6
	WAIT
	ARP_OFF
	NOTE C_, 6
	NOTE B_, 5
	LENGTH $9A
	NOTE G_, 5
	LEN 11
	NOTE A_, 5
	WAIT
	ARP 3
	LENGTH $6E
	NOTE Ash, 5
	LEN 11
	ARP_OFF
	NOTE B_, 5
	NOTE C_, 6
	ARP 3
	NOTE C_, 6
	WAIT
	ARP_OFF
	NOTE C_, 6
	NOTE B_, 5
	LENGTH $79
	NOTE E_, 5
	LEN 11
	NOTE F_, 5
	NOTE G_, 5
	WAIT
	WAIT
	ARP 3
	NOTE G_, 5
	ARP_OFF
	LENGTH $79
	NOTE D_, 5
	LEN 11
	NOTE E_, 5
	NOTE F_, 5
	WAIT
	WAIT
	ARP 3
	NOTE F_, 5
	ARP_OFF
	LEN 22
	NOTE F_, 5
	NOTE E_, 5
	NOTE C_, 5
	WAIT
	WAIT
	LEN 11
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	WAIT
	WAIT
	ARP 3
	NOTE G_, 5
	LENGTH $6E
	ARP_OFF
	NOTE D_, 5
	LEN 11
	NOTE D_, 5
	NOTE E_, 5
	ARP 3
	NOTE F_, 5
	WAIT
	ARP_OFF
	NOTE E_, 5
	NOTE D_, 5
	NEXT
Pat_598B:
	WAVE Wave_7997
	LEN 11
	VOLENV 10, $00, $00, $00
	VIBRATO $0B, $01, $04
	PAN_L
	ARP_OFF
	REST
	REST
	PAT_CALL Pat_5939
	LENGTH $9A
	NOTE C_, 5
	NEXT
Pat_59A2:
	LEN 22
	HWENV $D1, $0B, $83
	VIBRATO $0B, $01, $04
	DUTY_75
	ARP 16
	AUTOPAN $0B
Pat_59AF:
	REPEAT 2
	NOTE G_, 3
	NOTE E_, 3
	NOTE C_, 3
	NOTE E_, 3
	NOTE A_, 3
	NOTE E_, 3
	NOTE C_, 3
	NOTE E_, 3
	NOTE B_, 3
	NOTE E_, 3
	NOTE C_, 3
	NOTE E_, 3
	NOTE A_, 3
	NOTE E_, 3
	NOTE C_, 3
	NOTE E_, 3
	REPEAT_END
	NOTE A_, 3
	NOTE F_, 3
	NOTE D_, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE F_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE E_, 3
	NOTE C_, 3
	NOTE A_, 3
	NOTE F_, 3
	NOTE D_, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE G_, 3
	LEN 11
	NOTE E_, 3
	NOTE D_, 3
	LEN 22
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NEXT
Pat_59E5:
	WAVE Wave_79D7
	PAN_C
	ARP 16
	VOLENV 15, $13, $19, $13
	LENGTH $58
	REPEAT 8
	NOTE C_, 3
	REPEAT_END
	NOTE D_, 3
	NOTE D_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE D_, 3
	LEN 22
	NOTE D_, 3
	WAIT
	NOTE G_, 3
	LEN 11
	NOTE E_, 3
	NOTE D_, 3
	LENGTH $58
	NOTE C_, 3
	LEN 22
	NOTE C_, 3
	WAIT
	WAIT
	NOTE G_, 3
	NEXT
Pat_5A08:
	RELEASE $03, $50
Pat_5A0B:
	REPEAT 3
	LEN 22
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 4
	LEN 11
	NOTE C_, 3
	NOTE C_, 4
	REPEAT_END
	LEN 22
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	LEN 11
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	LEN 22
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 4
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 4
	LEN 11
	NOTE D_, 3
	NOTE D_, 4
	LEN 22
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 4
	LEN 11
	NOTE C_, 3
	NOTE C_, 4
	LEN 22
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 4
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	LEN 11
	NOTE G_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE D_, 3
	LEN 22
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	LEN 11
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	RELEASE $01, $50
	NEXT
DrumPat_5A56:
	db DRUM_LEVEL + 11
DrumPat_5A57:
	db 9, 0, 10, 10, 9, 0, 10, 10
	db 9, 10, 9, 0, 9, 0, 10, 10
	db DRUM_LOOP
DrumPat_5A68:
	db 9, 10, 11, 10, 9, 10, 10, 10
	db 9, 11, 9, 10, 9, 11, 10, 10
	db DRUM_LOOP

; Song 7: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong7:
	ld a, $5D
	ld [wInstrTableHi], a
	ld a, $B2
	ld [wInstrTable], a
	ld de, Song7_Ch1
	call StartMusicCh1
	ld de, Song7_Ch2
	call StartMusicCh2
	ld de, Song7_Ch3
	call StartMusicCh3
	ret
Song7_Ch1:
	dw Pat_5AC8
	dw Pat_5AC8
Loop_5A9A:
	dw Pat_5BCE
	dw Pat_5C2F
	dw Pat_5ACC
	dw Pat_5ACC
	dw Pat_5ACC
	ORDER_LOOP Loop_5A9A
Song7_Ch2:
	dw Pat_5AEB
	dw Pat_5AEB
Loop_5AAC:
	dw Pat_5BEE
	dw Pat_5C57
	dw Pat_5AF1
	dw Pat_5AF1
	dw Pat_5AF1
	ORDER_LOOP Loop_5AAC
Song7_Ch3:
	dw Pat_5B04
Loop_5ABC:
	dw Pat_5C08
	dw Pat_5C8A
	dw Pat_5CE7
	dw Pat_5B14
	ORDER_LOOP Loop_5ABC
Pat_5AC8:
	LEN 12
	RELEASE $02, $40
Pat_5ACC:
	REPEAT 4
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 5
	INSTR 0
	NOTE C_, 3
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 0
	NOTE Ash, 2
	WAIT
	INSTR 1
	NOTE Ash, 4
	INSTR 0
	NOTE Ash, 2
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE G_, 2
	REPEAT_END
	NEXT
Pat_5AEB:
	LEN 12
	INSTR 2
	VIBRATO $07, $01, $04
Pat_5AF1:
	REPEAT 4
	WAIT
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	WAIT
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	WAIT
	NOTE Ash, 3
	NOTE D_, 4
	NOTE F_, 4
	WAIT
	NOTE F_, 3
	NOTE A_, 3
	NOTE C_, 4
	REPEAT_END
	NEXT
Pat_5B04:
	LEN 6
	RELEASE $01, $50
	DRUMS $06, DrumPat_5D50
	VOLENV 15, $11, $11, $11
	VIBRATO $0E, $01, $04
Pat_5B14:
	REPEAT 2
	WAVE Wave_7AE7
	NOTE C_, 5
	WAIT
	WAIT2
	NOTE E_, 5
	NOTE G_, 5
	WAIT2
	NOTE C_, 6
	WAIT2
	NOTE Ash, 5
	WAIT
	WAIT
	WAIT2
	NOTE A_, 5
	WAIT2
	NOTE G_, 5
	WAIT2
	NOTE Ash, 5
	WAIT
	WAIT2
	NOTE A_, 5
	NOTE G_, 5
	WAIT2
	NOTE Dsh, 5
	WAIT2
	NOTE E_, 5
	WAIT2
	NOTE G_, 5
	WAIT2
	NOTE C_, 5
	WAIT
	WAIT
	WAIT2
	WAIT
	WAIT
	ARP 12
	WAVE Wave_79C7
	VOLENV 15, $11, $1A, $11
	PAN_R
	NOTE C_, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE G_, 5
	WAIT
	PAN_L
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	NOTE B_, 4
	WAIT
	NOTE D_, 5
	WAIT
	VOLENV 15, $11, $11, $11
	ARP_OFF
	WAVE Wave_79E7
	PAN_C
	NOTE Ash, 6
	NOTE A_, 6
	NOTE G_, 6
	NOTE A_, 6
	NOTE Ash, 6
	NOTE A_, 6
	NOTE Ash, 6
	NOTE D_, 7
	LEN 2
	NOTE C_, 7
	NOTE D_, 7
	NOTE C_, 7
	LEN 6
	REST
	NOTE A_, 6
	REST
	NOTE F_, 6
	WAIT
	REST
	REST
	WAVE Wave_7AE7
	NOTE C_, 5
	WAIT
	WAIT2
	NOTE E_, 5
	NOTE G_, 5
	WAIT2
	NOTE C_, 6
	WAIT2
	NOTE Ash, 5
	WAIT
	WAIT
	WAIT2
	NOTE Ash, 5
	WAIT2
	NOTE C_, 6
	WAIT2
	NOTE D_, 6
	WAIT
	WAIT2
	NOTE C_, 6
	NOTE Ash, 5
	WAIT2
	NOTE A_, 5
	WAIT2
	LEN 3
	NOTE Ash, 5
	NOTE A_, 5
	LEN 6
	WAIT2
	NOTE F_, 5
	WAIT2
	NOTE F_, 5
	WAIT2
	NOTE G_, 5
	WAIT2
	WAIT
	WAIT
	ARP 12
	WAVE Wave_79C7
	VOLENV 15, $11, $1A, $11
	PAN_R
	NOTE C_, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE G_, 5
	WAIT
	PAN_L
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	NOTE B_, 4
	WAIT
	NOTE D_, 5
	WAIT
	VOLENV 15, $11, $11, $11
	ARP_OFF
	WAVE Wave_79E7
	PAN_C
	NOTE Ash, 6
	NOTE A_, 6
	NOTE G_, 6
	NOTE A_, 6
	NOTE Ash, 6
	NOTE A_, 6
	NOTE Ash, 6
	NOTE D_, 7
	LEN 2
	NOTE C_, 7
	NOTE D_, 7
	NOTE C_, 7
	LEN 6
	REST
	NOTE A_, 6
	REST
	NOTE F_, 7
	WAIT
	REST
	REST
	REPEAT_END
	NEXT
Pat_5BCE:
	REPEAT 4
	NOTE C_, 3
	LEN 6
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	WAIT
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	WAIT
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	WAIT
	NOTE G_, 2
	WAIT
	NOTE C_, 3
	WAIT
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	WAIT
	NOTE C_, 3
	NOTE C_, 3
	LEN 12
	NOTE C_, 3
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	REPEAT_END
	NEXT
Pat_5BEE:
	AUTOPAN $0C
	HWENV $F2, $04, $92
	ARP 6
	REPEAT 4
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 4
	NOTE D_, 5
	NOTE D_, 4
	NOTE D_, 5
	NOTE D_, 4
	NOTE Dsh, 5
	NOTE Dsh, 4
	NOTE Dsh, 5
	NOTE Dsh, 4
	NOTE D_, 5
	NOTE D_, 4
	NOTE D_, 5
	NOTE D_, 4
	REPEAT_END
	NEXT
Pat_5C08:
	DRUMS $06, DrumPat_5D92
	REPEAT 4
	NOTE C_, 7
	NOTE D_, 7
	NOTE C_, 7
	NOTE B_, 6
	NOTE C_, 7
	NOTE D_, 7
	NOTE C_, 7
	NOTE B_, 6
	NOTE C_, 7
	NOTE D_, 7
	NOTE C_, 7
	NOTE B_, 6
	NOTE C_, 7
	NOTE D_, 7
	NOTE C_, 7
	NOTE D_, 7
	NOTE Dsh, 7
	NOTE F_, 7
	NOTE Dsh, 7
	NOTE D_, 7
	NOTE Dsh, 7
	NOTE F_, 7
	NOTE Dsh, 7
	NOTE F_, 7
	NOTE G_, 7
	NOTE A_, 7
	NOTE G_, 7
	NOTE A_, 7
	NOTE Ash, 7
	NOTE A_, 7
	NOTE G_, 7
	NOTE E_, 7
	REPEAT_END
	NEXT
Pat_5C2F:
	HWENV $F1, $05, $74
	REPEAT 3
	LEN 24
	NOTE C_, 3
	NOTE C_, 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE F_, 2
	LEN 12
	NOTE F_, 2
	NOTE G_, 2
	NOTE Gsh, 2
	LEN 6
	WAIT
	NOTE Gsh, 2
	LEN 12
	NOTE G_, 2
	NOTE F_, 2
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	WAIT
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	LEN 6
	WAIT
	NOTE G_, 2
	LEN 12
	NOTE A_, 2
	NOTE B_, 2
	REPEAT_END
	NEXT
Pat_5C57:
	REPEAT 3
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	INSTR 1
	NOTE G_, 4
	INSTR 2
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	INSTR 1
	NOTE Ash, 4
	INSTR 2
	NOTE Ash, 3
	NOTE D_, 4
	NOTE F_, 4
	INSTR 1
	NOTE F_, 4
	INSTR 2
	NOTE F_, 3
	NOTE A_, 3
	NOTE C_, 4
	INSTR 1
	NOTE Gsh, 4
	INSTR 2
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Dsh, 4
	INSTR 1
	NOTE C_, 5
	INSTR 2
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	INSTR 1
	NOTE G_, 4
	INSTR 2
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	INSTR 1
	NOTE G_, 4
	INSTR 2
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	REPEAT_END
	NEXT
Pat_5C8A:
	DRUMS $06, DrumPat_5D3F
	LEN 12
	NOTE C_, 7
	WAIT
	GLIDE $FF
	WAIT
	GLIDE_OFF
	WAIT
	LENGTH $90
	REST
	REST
	LEN 48
	REST
	PAT_CALL Pat_5CB7
	LEN 48
	WAIT
	PAT_CALL Pat_5CC1
	WAVE Wave_7A27
	VOLENV 15, $11, $11, $11
	DRUMS $06, DrumPat_5D38
	LEN 6
	WAIT
	NOTE G_, 5
	NOTE A_, 5
	WAIT2
	NOTE B_, 5
	WAIT2
	NEXT
Pat_5CB7:
	LEN 12
	WAIT
	WAVE Wave_7A87
	VOLENV 15, $11, $1A, $12
	ARP 0
Pat_5CC1:
	LEN 6
	NOTE C_, 6
	NOTE D_, 6
	LEN 12
	NOTE E_, 6
	NOTE C_, 6
	NOTE D_, 6
	NOTE B_, 5
	NOTE G_, 5
	WAIT
	WAIT
	LEN 6
	NOTE Ash, 5
	NOTE C_, 6
	LEN 12
	NOTE D_, 6
	NOTE Ash, 5
	NOTE C_, 6
	NOTE A_, 5
	NOTE F_, 5
	WAIT
	NOTE Gsh, 5
	LEN 6
	WAIT
	NOTE Gsh, 5
	LEN 12
	NOTE G_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE E_, 6
	NOTE E_, 6
	NOTE G_, 6
	NOTE G_, 6
	NOTE G_, 6
	NOTE A_, 6
	NOTE G_, 6
	NEXT
Pat_5CE7:
	DRUMS $06, DrumPat_5D50
	REPEAT 2
	ARP 3
	NOTE Ash, 5
	WAIT
	ARP_OFF
	NOTE G_, 5
	WAIT2
	WAIT
	WAIT
	ARP 3
	NOTE Ash, 5
	WAIT2
	ARP_OFF
	NOTE Ash, 5
	WAIT
	WAIT
	NOTE A_, 5
	NOTE G_, 5
	WAIT2
	NOTE A_, 5
	WAIT2
	NOTE Ash, 5
	WAIT
	NOTE A_, 5
	WAIT2
	NOTE G_, 5
	WAIT
	NOTE F_, 5
	WAIT2
	ARP 3
	NOTE G_, 5
	WAIT2
	ARP_OFF
	NOTE F_, 5
	WAIT2
	NOTE C_, 5
	WAIT
	WAIT
	WAIT2
	ARP 3
	NOTE Ash, 5
	WAIT
	ARP_OFF
	NOTE G_, 5
	WAIT2
	WAIT
	WAIT
	ARP 3
	NOTE Ash, 5
	WAIT2
	ARP_OFF
	NOTE Ash, 5
	WAIT
	WAIT
	NOTE A_, 5
	NOTE G_, 5
	WAIT2
	NOTE A_, 5
	WAIT2
	NOTE Ash, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE Ash, 5
	WAIT2
	NOTE D_, 6
	WAIT2
	NOTE C_, 6
	WAIT
	NOTE A_, 5
	WAIT2
	NOTE F_, 6
	WAIT
	WAIT
	WAIT2
	REPEAT_END
	NEXT
DrumPat_5D38:
	db 9, 9, 9, 0, 9, 9, DRUM_LOOP
DrumPat_5D3F:
	db 1, 0, 6, 0, 1, 0, 6, 0
	db 1, 0, 6, 0, 1, 0, 4, 0
	db DRUM_LOOP
DrumPat_5D50:
	db DRUM_LEVEL + 14, 1, 0, 6, 0, 9, 0, 1
	db 0, 1, 0, 6, 0, 9, 0, 6
	db 0, 1, 0, 6, 0, 9, 0, 1
	db 0, 6, 0, 1, 0, 9, 0, 4
	db 0, 1, 0, 6, 0, 9, 0, 1
	db 0, 1, 0, 6, 0, 9, 0, 6
	db 0, 1, 0, 6, 0, 9, 0, 1
	db 0, 6, 0, 1, 0, 9, 0, 9
	db 9, DRUM_LOOP
DrumPat_5D92:
	db DRUM_LEVEL + 15, 9, 0, 10, 10, 9, 0, 10
	db 10, 9, 0, 10, 10, 9, 9, 9
	db 9, 9, 0, 10, 10, 9, 0, 10
	db 10, 9, 0, 9, 10, 9, 9, 9
	db 10, DRUM_LOOP

; Instrument table 1, entries 1..3 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr1_0
	dw Instr1_1
	dw Instr1_2
Instr1_0:
	HWENV $F2, $05, $60
	ARP 0
	END
Instr1_1:
	HWENV $F2, $04, $92
	ARP 6
	DUTY_75
	END
Instr1_2:
	HWENV $B1, $06, $42
	DUTY_75
	AUTOPAN $06
	ARP 0
	END

; Song 8: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong8:
	ld a, $75
	ld [wInstrTableHi], a
	ld a, $72
	ld [wInstrTable], a
	call StopAll
	ld de, Song8_Ch1
	call StartMusicCh1
	ld de, Song8_Ch3
	call StartMusicCh3
	ld de, Song8_Ch2
	jp StartMusicCh2
Song8_Ch1:
	dw Pat_5E13
	dw Pat_5E13
	dw Pat_5E26
	dw Pat_5E26
	ORDER_LOOP Song8_Ch1
Song8_Ch3:
	dw Pat_5E48
	dw Pat_5E48
	dw Pat_5E77
	dw Pat_5E77
	ORDER_LOOP Song8_Ch3
Song8_Ch2:
	dw Pat_5E99
	dw Pat_5E99
	dw Pat_5ED1
	dw Pat_5ED1
	ORDER_LOOP Song8_Ch2
Pat_5E13:
	HWENV $F2, $00
	ARP 0
	DUTY_75
	REPEAT 4
	LEN 14
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	LEN 7
	NOTE C_, 3
	NOTE C_, 2
	REPEAT_END
	NEXT
Pat_5E26:
	REPEAT 2
	LEN 14
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	NOTE F_, 2
	REPEAT_END
	LEN 14
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	LEN 7
	NOTE C_, 3
	NOTE C_, 2
	LEN 14
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE E_, 2
	NOTE E_, 3
	NEXT
Pat_5E48:
	DRUMS $07, DrumPat_5F0C
	VOLENV 15, $12, $1F, $11
	CH_TRANSPOSE $0C
	WAVE Wave_7AE7
	LEN 14
	WAIT
	ARP 6
	NOTE C_, 4
	ARP 18
	NOTE F_, 3
	ARP 6
	LEN 28
	NOTE C_, 4
	REPEAT 3
	LEN 14
	NOTE C_, 4
	ARP 18
	NOTE F_, 3
	ARP 6
	LEN 28
	NOTE C_, 4
	REPEAT_END
	REPEAT 3
	LEN 14
	NOTE C_, 5
	ARP 18
	NOTE F_, 3
	ARP 6
	LEN 28
	NOTE C_, 5
	REPEAT_END
	LEN 14
	NOTE C_, 5
	ARP 18
	NOTE F_, 3
	ARP 6
	NOTE C_, 5
	NEXT
Pat_5E77:
	LEN 14
	WAIT
	ARP 6
	NOTE F_, 4
	ARP 18
	NOTE F_, 3
	ARP 6
	LEN 28
	NOTE F_, 4
	REPEAT 3
	LEN 14
	NOTE F_, 4
	ARP 18
	NOTE F_, 3
	ARP 6
	LEN 28
	NOTE F_, 4
	REPEAT_END
	REPEAT 3
	LEN 14
	NOTE C_, 5
	ARP 18
	NOTE F_, 3
	ARP 6
	LEN 28
	NOTE C_, 5
	REPEAT_END
	LEN 14
	NOTE C_, 5
	ARP 18
	NOTE F_, 3
	ARP 6
	NOTE C_, 5
	NEXT
Pat_5E99:
	HWENV $F2, $08, $83
	DUTY_50
	LEN 14
	NOTE C_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE D_, 5
	NOTE C_, 5
	NOTE E_, 5
	LEN 7
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE G_, 5
	NEXT
Pat_5ED1:
	LEN 14
	NOTE F_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE D_, 5
	NOTE C_, 5
	LEN 7
	NOTE D_, 5
	NOTE E_, 5
	LEN 14
	NOTE F_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 4
	LEN 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 6
	NOTE G_, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE G_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE A_, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE G_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE A_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE A_, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE B_, 4
	NOTE G_, 5
	NOTE A_, 5
	NEXT
DrumPat_5F0C:
	db 1, 6, 5, 6, 2, 6, 5, 6
	db DRUM_LOOP

; Song 9: instrument table 2, arpeggio table 1 (the one SndInit sets)
PlaySong9:
	ld a, $62
	ld [wInstrTableHi], a
	ld a, $6A
	ld [wInstrTable], a
	call StopAll
	ld de, Song9_Ch3
	call StartMusicCh3
	ld de, Song9_Ch2
	call StartMusicCh2
	ld de, Song9_Ch1
	jp StartMusicCh1

; Unreferenced (1 bytes)
	db $C9
Song9_Ch3:
	dw Pat_5F71
	dw Pat_5F71
	dw Pat_5F8D
	dw Pat_5FAC
	dw Pat_5FCB
	dw Pat_5FCB
	dw Pat_6001
	dw Pat_601E
	ORDER_LOOP Song9_Ch3
Song9_Ch2:
	dw Pat_6031
	dw Pat_6031
	dw Pat_6067
	dw Pat_60A1
	dw Pat_60DA
	dw Pat_60DA
	dw Pat_610E
	dw Pat_6140
	ORDER_LOOP Song9_Ch2
Song9_Ch1:
	dw Pat_616D
	dw Pat_616D
	dw Pat_619B
	dw Pat_61D4
	dw Pat_620C
	dw Pat_620C
	dw Pat_622D
	dw Pat_624E
	ORDER_LOOP Song9_Ch1
Pat_5F71:
	CH_TRANSPOSE $0C
	LEN 12
	REPEAT 4
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE G_, 2
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE D_, 2
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE G_, 2
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE D_, 2
	REPEAT_END
	NEXT
Pat_5F8D:
	REPEAT 7
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE Dsh, 2
	REPEAT_END
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE F_, 2
	REPEAT 3
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE G_, 2
	REPEAT_END
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE Ash, 2
	REPEAT 3
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE G_, 2
	REPEAT_END
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE Ash, 2
	NEXT
Pat_5FAC:
	REPEAT 7
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE Dsh, 2
	REPEAT_END
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE F_, 2
	REPEAT 3
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE G_, 2
	REPEAT_END
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE Ash, 2
	REPEAT 2
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE D_, 2
	REPEAT_END
	NOTE D_, 3
	NOTE C_, 3
	NOTE Ash, 2
	NOTE A_, 2
	NEXT
Pat_5FCB:
	REPEAT 3
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE A_, 2
	REPEAT_END
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE D_, 2
	NEXT
Pat_5FEE:
	REPEAT 2
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE G_, 2
	REPEAT_END
	NEXT
Pat_6001:
	PAT_CALL Pat_5FEE
	REPEAT 2
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE D_, 2
	REPEAT_END
	REPEAT 2
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE C_, 3
	INSTR 0
	LEN 6
	NOTE D_, 2
	NOTE Dsh, 2
	LEN 12
	REPEAT_END
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE D_, 2
	NOTE F_, 2
	NOTE Fsh, 2
	NEXT
Pat_601E:
	PAT_CALL Pat_5FEE
	LENGTH $30
	NOTE D_, 2
	LEN 36
	NOTE D_, 2
	LEN 12
	NOTE A_, 2
	LENGTH $30
	NOTE D_, 3
	LEN 24
	NOTE D_, 2
	LEN 12
	NOTE D_, 3
	NOTE D_, 2
	NEXT
Pat_6031:
	INSTR 5
	LEN 12
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN 24
	NOTE Csh, 4
	LEN 12
	NOTE D_, 4
	NOTE D_, 4
	NOTE Csh, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE A_, 3
	NOTE A_, 3
	INSTR 4
	LEN 6
	NOTE G_, 4
	NOTE Ash, 4
	NOTE D_, 5
	NOTE G_, 5
	NOTE Ash, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE D_, 5
	NOTE G_, 5
	NOTE Ash, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE Ash, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE Fsh, 5
	NOTE D_, 5
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE Fsh, 5
	NOTE D_, 5
	NOTE A_, 4
	NOTE Fsh, 4
	NEXT
Pat_6067:
	INSTR 5
	LEN 6
	NOTE D_, 3
	NOTE Dsh, 3
	INSTR 2
	LEN 12
	NOTE Dsh, 5
	NOTE Dsh, 5
	INSTR 5
	NOTE Dsh, 3
	INSTR 2
	NOTE D_, 5
	NOTE Dsh, 5
	INSTR 5
	NOTE Dsh, 3
	INSTR 2
	NOTE Dsh, 5
	INSTR 5
	LEN 6
	NOTE D_, 3
	NOTE Dsh, 3
	INSTR 2
	LEN 12
	NOTE Dsh, 5
	NOTE Dsh, 5
	INSTR 5
	NOTE Dsh, 3
	INSTR 2
	NOTE D_, 5
	NOTE Dsh, 5
	INSTR 5
	NOTE Dsh, 3
	INSTR 2
	NOTE Dsh, 5
	INSTR 5
	LEN 6
	NOTE Fsh, 3
	NOTE G_, 3
	LEN 12
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 6
	NOTE Fsh, 3
	NOTE G_, 3
	LEN 12
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NEXT
Pat_60A1:
	INSTR 5
	LEN 6
	NOTE D_, 3
	NOTE Dsh, 3
	INSTR 2
	LEN 12
	NOTE Dsh, 5
	NOTE Dsh, 5
	INSTR 5
	NOTE Dsh, 3
	INSTR 2
	NOTE D_, 5
	NOTE Dsh, 5
	INSTR 5
	NOTE Dsh, 3
	INSTR 2
	NOTE Dsh, 5
	INSTR 5
	LEN 6
	NOTE D_, 3
	NOTE Dsh, 3
	INSTR 2
	LEN 12
	NOTE Dsh, 5
	NOTE Dsh, 5
	INSTR 5
	NOTE Dsh, 3
	INSTR 2
	NOTE D_, 5
	NOTE Dsh, 5
	INSTR 5
	NOTE Dsh, 3
	INSTR 2
	NOTE Dsh, 5
	INSTR 5
	LEN 6
	NOTE Fsh, 3
	NOTE G_, 3
	LEN 12
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	LEN 6
	NOTE Fsh, 3
	NOTE G_, 3
	LEN 12
	NOTE A_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 24
	NOTE Fsh, 4
	NOTE D_, 4
	NEXT
Pat_60DA:
	INSTR 3
	LEN 12
	NOTE G_, 4
	INSTR 5
	LEN 24
	NOTE D_, 4
	INSTR 3
	LEN 12
	NOTE G_, 4
	INSTR 5
	NOTE F_, 4
	INSTR 3
	NOTE G_, 4
	INSTR 5
	NOTE D_, 4
	INSTR 2
	NOTE Gsh, 4
	INSTR 3
	NOTE G_, 4
	INSTR 5
	LEN 24
	NOTE D_, 4
	INSTR 3
	LEN 12
	NOTE G_, 4
	INSTR 5
	NOTE G_, 4
	INSTR 3
	NOTE G_, 4
	INSTR 5
	NOTE D_, 4
	INSTR 2
	NOTE Gsh, 4
	INSTR 3
	NOTE G_, 4
	LEN 24
	NOTE G_, 5
	NOTE G_, 4
	LEN 12
	NOTE G_, 5
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	LEN 24
	NOTE G_, 5
	NOTE G_, 4
	INSTR 2
	LEN 12
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NEXT
Pat_610E:
	INSTR 2
	LEN 12
	NOTE Dsh, 5
	INSTR 5
	LEN 24
	NOTE Dsh, 4
	INSTR 2
	LEN 12
	NOTE Dsh, 5
	INSTR 5
	NOTE G_, 4
	INSTR 2
	NOTE Dsh, 5
	INSTR 5
	NOTE Dsh, 4
	INSTR 2
	NOTE F_, 5
	NOTE Dsh, 5
	INSTR 5
	LEN 24
	NOTE Dsh, 4
	INSTR 2
	LEN 12
	NOTE Dsh, 5
	INSTR 5
	NOTE G_, 4
	INSTR 2
	NOTE Dsh, 5
	INSTR 5
	NOTE Dsh, 4
	INSTR 2
	NOTE F_, 5
	LEN 36
	NOTE D_, 5
	LEN 24
	NOTE D_, 5
	LEN 12
	NOTE D_, 5
	NOTE D_, 5
	NOTE Dsh, 5
	LEN 18
	NOTE D_, 5
	NOTE Dsh, 5
	LEN 24
	NOTE D_, 5
	LEN 12
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE D_, 5
	NEXT
Pat_6140:
	INSTR 2
	LEN 12
	NOTE Dsh, 5
	INSTR 5
	LEN 24
	NOTE Dsh, 4
	INSTR 2
	LEN 12
	NOTE Dsh, 5
	INSTR 5
	NOTE G_, 4
	INSTR 2
	NOTE Dsh, 5
	INSTR 5
	NOTE Dsh, 4
	INSTR 2
	NOTE F_, 5
	NOTE Dsh, 5
	INSTR 5
	LEN 24
	NOTE Dsh, 4
	INSTR 2
	LEN 12
	NOTE Dsh, 5
	INSTR 5
	NOTE G_, 4
	INSTR 2
	NOTE Dsh, 5
	INSTR 5
	NOTE Dsh, 4
	INSTR 2
	NOTE F_, 5
	LENGTH $30
	NOTE D_, 4
	LEN 36
	NOTE D_, 4
	LEN 12
	NOTE Dsh, 4
	LEN 24
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE D_, 4
	NEXT
Pat_616D:
	DRUMS $06, DrumPat_62A5
	INSTR 5
	LEN 12
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	LEN 24
	NOTE Ash, 3
	LEN 12
	NOTE A_, 3
	NOTE A_, 3
	NOTE Gsh, 3
	LEN 6
	NOTE A_, 3
	WAIT2
	LEN 12
	NOTE A_, 3
	NOTE F_, 3
	LEN 24
	NOTE Fsh, 3
	DUTY_12
	LEN 12
	NOTE D_, 4
	NOTE Ash, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 4
	LEN 24
	NOTE G_, 4
	LEN 12
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Csh, 4
	NOTE D_, 4
	NOTE Gsh, 3
	NOTE A_, 3
	NEXT
Pat_619B:
	LEN 12
	WAIT
	DUTY_50
	LEN 6
	NOTE Ash, 4
	NOTE A_, 4
	LEN 12
	NOTE G_, 4
	LEN 6
	NOTE Ash, 4
	NOTE A_, 4
	LEN 12
	NOTE G_, 4
	LEN 6
	NOTE Ash, 4
	NOTE A_, 4
	LEN 12
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	LEN 6
	NOTE Ash, 4
	NOTE A_, 4
	LEN 12
	NOTE G_, 4
	LEN 6
	NOTE Ash, 4
	NOTE A_, 4
	LEN 12
	NOTE G_, 4
	LEN 6
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 18
	NOTE C_, 5
	DUTY_75
	LEN 12
	NOTE D_, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE Csh, 5
	LEN 24
	NOTE D_, 5
	LEN 12
	NOTE D_, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE Csh, 5
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NEXT
Pat_61D4:
	LEN 12
	WAIT
	DUTY_50
	LEN 6
	NOTE Ash, 4
	NOTE A_, 4
	LEN 12
	NOTE G_, 4
	LEN 6
	NOTE Ash, 4
	NOTE A_, 4
	LEN 12
	NOTE G_, 4
	LEN 6
	NOTE Ash, 4
	NOTE A_, 4
	LEN 12
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	LEN 6
	NOTE Ash, 4
	NOTE A_, 4
	LEN 12
	NOTE G_, 4
	LEN 6
	NOTE Ash, 4
	NOTE A_, 4
	LEN 12
	NOTE G_, 4
	LEN 6
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 18
	NOTE C_, 5
	DUTY_75
	LEN 12
	NOTE D_, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE Csh, 5
	NOTE D_, 5
	NOTE Dsh, 5
	LEN 24
	NOTE D_, 5
	LEN 12
	NOTE D_, 5
	NOTE D_, 5
	NOTE C_, 5
	LEN 24
	NOTE D_, 5
	NOTE A_, 4
	NEXT
Pat_620C:
	INSTR 5
	LEN 12
	NOTE G_, 2
	LEN 36
	NOTE G_, 4
	LEN 24
	NOTE Ash, 4
	LEN 36
	NOTE G_, 4
	NOTE G_, 4
	LEN 24
	NOTE C_, 5
	NOTE G_, 4
	ARP 0
	DUTY_12
	LEN 12
	NOTE G_, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE Ash, 3
	NOTE Fsh, 3
	NEXT
Pat_622D:
	LEN 12
	WAIT
	INSTR 5
	LEN 36
	NOTE G_, 4
	LEN 24
	NOTE Ash, 4
	LEN 36
	NOTE G_, 4
	NOTE G_, 4
	LEN 24
	NOTE C_, 5
	NOTE G_, 4
	ARP 0
	DUTY_12
	LEN 12
	NOTE Fsh, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE Ash, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE Fsh, 3
	NOTE D_, 3
	NEXT
Pat_624E:
	LEN 12
	WAIT
	INSTR 5
	LEN 36
	NOTE G_, 4
	LEN 24
	NOTE Ash, 4
	LEN 36
	NOTE G_, 4
	NOTE G_, 4
	LEN 24
	NOTE C_, 5
	NOTE G_, 4
	DUTY_12
	ARP 0
	LEN 12
	NOTE Fsh, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	LEN 24
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Dsh, 5
	NOTE D_, 5
	NEXT

; Instrument table 2, entries 1..6 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr2_0
	dw Instr2_1
	dw Instr2_2
	dw Instr2_3
	dw Instr2_4
	dw Instr2_5
Instr2_0:
	VOLENV 15, $11, $1A, $12
	ARP 0
	WAVE Wave_78F7
	END
Instr2_1:
	VOLENV 15, $11, $1A, $11
	ARP 18
	WAVE Wave_79F7
	END
Instr2_2:
	HWENV $D1, $06, $74
	AUTODUTY $02
	ARP 6
	END
Instr2_3:
	HWENV $D1, $06, $74
	AUTODUTY $02
	ARP 5
	END
Instr2_4:
	HWENV $B1, $00
	DUTY_12
	END
Instr2_5:
	HWENV $E2, $0C, $65
	DUTY_75
	END
DrumPat_62A5:
	db DRUM_LEVEL + 14, DRUM_REPEAT + 7, 1, 0, 5, 6, 9, 0
	db 5, 6, DRUM_REPEAT_END, 1, 0, 5, 6, 9
	db 0, 9, 9, DRUM_LOOP

; Song 10: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong10:
	ld a, $75
	ld [wInstrTableHi], a
	ld a, $72
	ld [wInstrTable], a
	call StopAll
	ld de, Song10_Ch1
	call StartMusicCh1
	ld de, Song10_Ch2
	call StartMusicCh2
	ld de, Song10_Ch3
	jp StartMusicCh3
Song10_Ch1:
	dw Pat_6306
Loop_62DA:
	dw Pat_6355
	dw Pat_6377
	dw Pat_6355
	dw Pat_63FC
	ORDER_LOOP Loop_62DA
Song10_Ch2:
	dw Pat_6443
Loop_62E8:
	dw Pat_6456
	dw Pat_6472
	dw Pat_6456
	dw Pat_648B
	ORDER_LOOP Loop_62E8
Song10_Ch3:
	dw Pat_6537
Loop_62F6:
	dw Pat_654F
	dw Pat_659C
	dw Pat_654F
	dw Pat_659C
	dw Pat_660C
	dw Pat_6632
	ORDER_LOOP Loop_62F6
Pat_6306:
	DUTY_75
	AUTODUTY $0E
	CH_TRANSPOSE $F4
	HWENV $0F, $7E, $F7
	ARP 6
	LENGTH $E0
	NOTE C_, 5
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	ARP 6
	LENGTH $E0
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE Gsh, 4
	LENGTH $70
	NOTE Fsh, 4
	LENGTH $E0
	NOTE G_, 4
	CH_TRANSPOSE $00
	NEXT
Pat_6325:
	INSTR 14
	NOTE C_, 2
	INSTR 1
	LEN 14
	NOTE A_, 2
	INSTR 14
	NOTE C_, 2
	LEN 28
	NOTE C_, 2
	INSTR 1
	NOTE A_, 2
	NEXT
Pat_6331:
	INSTR 14
	NOTE G_, 2
	INSTR 1
	LEN 14
	NOTE A_, 2
	INSTR 14
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	INSTR 1
	NOTE A_, 2
	NEXT
Pat_633D:
	INSTR 14
	NOTE Gsh, 2
	INSTR 1
	LEN 14
	NOTE A_, 2
	INSTR 14
	NOTE Gsh, 2
	LEN 28
	NOTE Gsh, 2
	INSTR 1
	NOTE A_, 2
	NEXT
Pat_6349:
	INSTR 14
	NOTE Ash, 2
	INSTR 1
	LEN 14
	NOTE A_, 2
	INSTR 14
	NOTE Ash, 2
	LEN 28
	NOTE Ash, 2
	INSTR 1
	NOTE A_, 2
	NEXT
Pat_6355:
	LEN 28
	REPEAT 2
	PAT_CALL Pat_6325
	REPEAT_END
	REPEAT 2
	PAT_CALL Pat_6331
	REPEAT_END
	REPEAT 2
	PAT_CALL Pat_6325
	REPEAT_END
	PAT_CALL Pat_6331
	INSTR 14
	NOTE G_, 2
	INSTR 1
	LEN 14
	NOTE A_, 2
	INSTR 14
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	INSTR 1
	NOTE A_, 2
	INSTR 14
	NOTE G_, 2
	NEXT
Pat_6377:
	LEN 28
	PAT_CALL Pat_633D
	PAT_CALL Pat_6349
	PAT_CALL Pat_6325
	INSTR 14
	NOTE C_, 2
	INSTR 1
	LEN 14
	NOTE A_, 2
	INSTR 14
	LEN 28
	NOTE C_, 3
	LEN 14
	NOTE C_, 3
	INSTR 1
	NOTE A_, 2
	INSTR 14
	NOTE Ash, 2
	LEN 28
	NOTE Gsh, 2
	INSTR 1
	LEN 14
	NOTE A_, 2
	INSTR 14
	NOTE Gsh, 2
	LEN 28
	NOTE Gsh, 2
	INSTR 1
	NOTE A_, 2
	INSTR 14
	NOTE Ash, 2
	INSTR 1
	LEN 14
	NOTE A_, 2
	INSTR 14
	NOTE Ash, 2
	LEN 28
	NOTE Ash, 2
	INSTR 1
	NOTE A_, 2
	INSTR 14
	NOTE G_, 2
	INSTR 1
	LEN 14
	NOTE A_, 2
	INSTR 14
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	INSTR 1
	NOTE A_, 2
	INSTR 14
	NOTE G_, 2
	INSTR 1
	LEN 14
	NOTE A_, 2
	INSTR 14
	LEN 28
	NOTE A_, 2
	LEN 14
	NOTE G_, 2
	INSTR 1
	NOTE A_, 2
	INSTR 14
	NOTE G_, 2
	NEXT
Pat_63BF:
	INSTR 9
	LEN 14
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 2
	NOTE B_, 2
	NOTE D_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE F_, 2
	NOTE A_, 2
	NOTE C_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE Gsh, 2
	NOTE C_, 3
	NOTE Dsh, 3
	LEN 28
	NOTE Ash, 2
	LEN 14
	NOTE D_, 3
	LEN 28
	NOTE F_, 3
	LEN 14
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE Ash, 2
	NOTE D_, 3
	NOTE F_, 3
	NOTE Ash, 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE D_, 5
	NOTE F_, 2
	NOTE A_, 2
	NOTE C_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	NEXT
Pat_63FC:
	LEN 28
	PAT_CALL Pat_633D
	PAT_CALL Pat_6349
	PAT_CALL Pat_6325
	INSTR 14
	NOTE C_, 2
	INSTR 1
	LEN 14
	NOTE A_, 2
	INSTR 14
	LEN 28
	NOTE C_, 3
	LEN 14
	NOTE C_, 3
	INSTR 1
	NOTE A_, 2
	INSTR 14
	NOTE Ash, 2
	LEN 28
	NOTE Gsh, 2
	INSTR 1
	LEN 14
	NOTE A_, 2
	INSTR 14
	NOTE Gsh, 2
	LEN 28
	NOTE Gsh, 2
	INSTR 1
	NOTE A_, 2
	PAT_CALL Pat_6349
	PAT_CALL Pat_6331
	INSTR 14
	LENGTH $70
	NOTE G_, 2
	PAT_CALL Pat_63BF
	NOTE Gsh, 2
	NOTE C_, 3
	NOTE Dsh, 3
	LEN 28
	NOTE Ash, 2
	LEN 14
	NOTE D_, 3
	LEN 28
	NOTE F_, 3
	PAT_CALL Pat_63BF
	INSTR 14
	LEN 42
	NOTE Gsh, 2
	LEN 28
	NOTE Ash, 2
	LEN 14
	NOTE Ash, 2
	INSTR 1
	NOTE A_, 2
	NOTE G_, 3
	NEXT
Pat_6443:
	HWENV $B2, $1C, $92
	ARP 0
	DUTY_50
	VIBRATO $18, $01, $05
	LEN 28
	REST
	PAT_CALL Pat_64D4
	LENGTH $62
	NOTE B_, 4
	NEXT
Pat_6456:
	HWENV $C1, $06, $55
	AUTODUTY $02
	LEN 14
	ARP 6
	REPEAT 8
	NOTE C_, 4
	NOTE C_, 4
	REPEAT_END
	ARP 5
	REPEAT 8
	NOTE G_, 4
	NOTE G_, 4
	REPEAT_END
	ARP 6
	REPEAT 8
	NOTE C_, 4
	NOTE C_, 4
	REPEAT_END
	ARP 5
	REPEAT 8
	NOTE G_, 4
	NOTE G_, 4
	REPEAT_END
	NEXT
Pat_6472:
	ARP 6
	LEN 14
	REPEAT 8
	NOTE Gsh, 4
	REPEAT_END
	REPEAT 8
	NOTE Ash, 4
	REPEAT_END
	REPEAT 8
	NOTE C_, 5
	NOTE C_, 5
	REPEAT_END
	REPEAT 8
	NOTE Gsh, 4
	REPEAT_END
	REPEAT 8
	NOTE Ash, 4
	REPEAT_END
	REPEAT 8
	NOTE F_, 4
	REPEAT_END
	REPEAT 8
	NOTE G_, 4
	REPEAT_END
	NEXT
Pat_648B:
	ARP 6
	LEN 14
	REPEAT 8
	NOTE Gsh, 4
	REPEAT_END
	REPEAT 8
	NOTE Ash, 4
	REPEAT_END
	REPEAT 8
	NOTE C_, 5
	NOTE C_, 5
	REPEAT_END
	REPEAT 8
	NOTE Gsh, 4
	REPEAT_END
	REPEAT 8
	NOTE Ash, 4
	REPEAT_END
	REPEAT 8
	NOTE F_, 4
	REPEAT_END
	HWENV $A7, $18, $40
	DRUMS_OFF
	CALL_CODE Drum7
	LENGTH $70
	NOTE G_, 4
	LENGTH $70
	NOTE C_, 4
	NOTE G_, 3
	NOTE F_, 3
	LEN 42
	NOTE Gsh, 3
	LENGTH $46
	NOTE Ash, 3
	LENGTH $70
	NOTE C_, 4
	NOTE Ash, 3
	NOTE F_, 3
	LEN 42
	NOTE Gsh, 3
	LENGTH $46
	NOTE Ash, 3
	LENGTH $70
	NOTE C_, 4
	NOTE G_, 3
	NOTE F_, 3
	LEN 42
	NOTE Gsh, 3
	LENGTH $46
	NOTE Ash, 3
	LENGTH $70
	NOTE C_, 4
	NOTE Ash, 3
	NOTE F_, 3
	LEN 42
	NOTE Gsh, 3
	LENGTH $46
	NOTE Ash, 3
	NEXT
Pat_64D4:
	LEN 14
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	LENGTH $54
	NOTE G_, 4
	LEN 14
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	LEN 28
	NOTE F_, 4
	NOTE D_, 4
	LENGTH $7E
	NOTE Ash, 3
	LEN 14
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	LENGTH $54
	NOTE G_, 3
	LEN 14
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE A_, 3
	LEN 28
	NOTE F_, 3
	NOTE D_, 4
	LENGTH $7E
	NOTE F_, 4
	LEN 14
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LENGTH $54
	NOTE Dsh, 4
	LEN 14
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE F_, 4
	LEN 28
	NOTE Csh, 4
	NOTE Ash, 3
	LENGTH $7E
	NOTE Fsh, 3
	LEN 14
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LENGTH $54
	NOTE Dsh, 4
	LEN 14
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE F_, 4
	LENGTH $46
	NOTE Csh, 4
	LEN 42
	NOTE G_, 4
	LENGTH $38
	NOTE A_, 4
	NEXT
Pat_6537:
	VOLENV 15, $12, $1A, $12
	CH_TRANSPOSE $0C
	ARP 0
	RELEASE $01, $50
	VIBRATO $18, $01, $06
	WAVE Wave_7A17
	PAT_CALL Pat_64D4
	LENGTH $7E
	NOTE B_, 4
	NEXT
Pat_654F:
	DRUMS $0E, DrumPat_664E
	CH_TRANSPOSE $00
	WAVE Wave_7997
	VOLENV 8, $14, $1A, $1A
	ARP 3
	LEN 14
	NOTE A_, 5
	ARP_OFF
	NOTE C_, 6
	NOTE B_, 5
	LENGTH $54
	NOTE G_, 5
	LEN 14
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	ARP 3
	NOTE A_, 5
	ARP_OFF
	NOTE C_, 6
	NOTE B_, 5
	NOTE G_, 5
	ARP 3
	NOTE G_, 5
	ARP_OFF
	NOTE Ash, 5
	NOTE A_, 5
	LEN 28
	NOTE F_, 5
	NOTE D_, 5
	LENGTH $54
	NOTE Ash, 4
	LEN 14
	NOTE F_, 4
	NOTE Ash, 4
	NOTE D_, 5
	ARP 3
	NOTE A_, 4
	ARP_OFF
	NOTE C_, 5
	NOTE B_, 4
	LENGTH $54
	NOTE G_, 4
	LEN 14
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	ARP 3
	NOTE A_, 4
	ARP_OFF
	NOTE C_, 5
	NOTE B_, 4
	NOTE G_, 4
	ARP 3
	NOTE G_, 4
	ARP_OFF
	NOTE Ash, 4
	NOTE A_, 4
	LEN 28
	NOTE F_, 4
	NOTE D_, 5
	LENGTH $7E
	NOTE F_, 5
	NEXT
Pat_659C:
	VOLENV 15, $11, $1A, $15
	ARP 0
	WAVE Wave_7A57
	CH_TRANSPOSE $0C
	LENGTH $46
	NOTE Dsh, 4
	LEN 28
	NOTE G_, 4
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	LEN 28
	NOTE C_, 4
	LEN 14
	NOTE Ash, 3
	LENGTH $62
	NOTE C_, 4
	LEN 14
	NOTE G_, 3
	LEN 28
	NOTE F_, 3
	LEN 14
	NOTE G_, 3
	NOTE C_, 4
	LEN 28
	NOTE E_, 3
	LEN 14
	NOTE F_, 3
	NOTE G_, 3
	NOTE C_, 4
	LENGTH $54
	NOTE C_, 4
	LEN 14
	NOTE Dsh, 4
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE D_, 4
	NOTE C_, 4
	NOTE F_, 3
	NOTE Ash, 3
	LEN 28
	NOTE C_, 4
	LENGTH $38
	NOTE G_, 3
	LEN 28
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	NOTE E_, 4
	LENGTH $7E
	NOTE D_, 4
	CH_TRANSPOSE $00
	NEXT
Pat_65E0:
	ARP_OFF
	LEN 42
	NOTE C_, 4
	LEN 28
	NOTE E_, 4
	LEN 14
	NOTE F_, 4
	NOTE G_, 4
	ARP 3
	LENGTH $7E
	NOTE F_, 4
	LEN 14
	NOTE A_, 4
	ARP_OFF
	NOTE C_, 5
	LEN 42
	NOTE F_, 4
	LEN 14
	NOTE G_, 4
	NOTE A_, 4
	LENGTH $38
	NOTE G_, 4
	LEN 28
	NOTE F_, 4
	NOTE E_, 4
	ARP 3
	LENGTH $38
	NOTE D_, 4
	ARP_OFF
	LEN 28
	NOTE G_, 4
	LEN 14
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	ARP 3
	LEN 28
	NOTE D_, 5
	ARP_OFF
	LEN 14
	NEXT
Pat_660C:
	DRUMS $0E, DrumPat_6662
	WAVE Wave_7907
	VOLENV 15, $11, $1A, $13
	VIBRATO $0E, $01, $04
	PAT_CALL Pat_65E0
	NOTE D_, 5
	LEN 28
	NOTE F_, 5
	NOTE E_, 5
	LENGTH $54
	NOTE C_, 5
	LEN 14
	NOTE G_, 4
	NOTE C_, 5
	NOTE D_, 5
	LEN 28
	NOTE Dsh, 5
	LEN 14
	NOTE Dsh, 5
	LEN 28
	NOTE D_, 5
	LEN 42
	NOTE Ash, 4
	NEXT
Pat_6632:
	PAT_CALL Pat_65E0
	NOTE F_, 5
	LEN 28
	NOTE G_, 5
	NOTE A_, 5
	LENGTH $54
	NOTE C_, 5
	LEN 14
	NOTE A_, 5
	NOTE F_, 5
	NOTE C_, 5
	DRUMS $0E, DrumPat_664E
	NOTE Gsh, 5
	NOTE Ash, 5
	NOTE C_, 6
	LEN 28
	NOTE Ash, 5
	LEN 14
	NOTE C_, 6
	LEN 28
	NOTE D_, 6
	NEXT
DrumPat_664E:
	db DRUM_LEVEL + 14, DRUM_REPEAT + 3, 1, 6, 9, 1, 1, 6
	db 9, 4, DRUM_REPEAT_END, 1, 6, 9, 1, 1
	db 6, 9, 9, DRUM_LOOP
DrumPat_6662:
	db 4, 0, DRUM_LOOP

; Song 11: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong11:
	ld a, $75
	ld [wInstrTableHi], a
	ld a, $72
	ld [wInstrTable], a
	call StopAll
	ld de, Song11_Ch1
	call StartMusicCh1
	ld de, Song11_Ch2
	call StartMusicCh2
	ld de, Song11_Ch3
	jp StartMusicCh3

; Unreferenced (1 bytes)
	db $C9
Song11_Ch1:
	dw Pat_66D9
Loop_6687:
	dw Pat_66D9
	dw Pat_66E5
	dw Pat_66D9
	dw Pat_66D9
	dw Pat_66F0
	dw Pat_66F6
	ORDER_LOOP Loop_6687
Song11_Ch2:
	dw Pat_6705
Loop_6699:
	dw Pat_6777
	dw Pat_674F
	dw Pat_6777
	dw Pat_6777
	dw Pat_677D
	dw Pat_6783
	ORDER_LOOP Loop_6699
Song11_Ch3:
	dw Pat_67A6
Loop_66AB:
	dw Pat_67FD
	dw Pat_67CE
	dw Pat_681E
	dw Pat_681E
	dw Pat_6870
	dw Pat_6899
	dw Pat_68BC
	dw Pat_68D7
	ORDER_LOOP Loop_66AB
Pat_66BF:
	LEN 36
	NOTE D_, 2
	LENGTH $48
	NOTE A_, 2
	LEN 24
	NOTE Dsh, 2
	LEN 12
	NOTE Dsh, 2
	LEN 24
	NOTE A_, 2
	NOTE Dsh, 2
	NEXT
Pat_66CC:
	LEN 36
	NOTE G_, 2
	LENGTH $48
	NOTE D_, 3
	LEN 24
	NOTE Gsh, 2
	LEN 12
	NOTE Gsh, 2
	LEN 24
	NOTE D_, 3
	NOTE Gsh, 2
	NEXT
Pat_66D9:
	HWENV $F2, $0C, $67
	DUTY_75
	ARP 0
	REPEAT 4
	PAT_CALL Pat_66BF
	REPEAT_END
	NEXT
Pat_66E5:
	REPEAT 2
	PAT_CALL Pat_66CC
	REPEAT_END
	REPEAT 2
	PAT_CALL Pat_66BF
	REPEAT_END
	NEXT
Pat_66F0:
	REPEAT 6
	PAT_CALL Pat_66CC
	REPEAT_END
	NEXT
Pat_66F6:
	REPEAT 4
	LEN 36
	NOTE D_, 2
	LENGTH $48
	NOTE A_, 2
	LEN 24
	NOTE Dsh, 2
	LEN 12
	NOTE Dsh, 2
	LEN 24
	NOTE Ash, 2
	NOTE Dsh, 2
	REPEAT_END
	NEXT
Pat_6705:
	INSTR 1
	LENGTH $30
	REPEAT 8
	NOTE C_, 3
	NOTE C_, 3
	REPEAT_END
	NEXT
Pat_670D:
	INSTR 1
	LEN 24
	NOTE C_, 3
	INSTR 5
	LEN 12
	NOTE D_, 4
	INSTR 9
	NOTE A_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 5
	LEN 24
	NOTE D_, 4
	INSTR 9
	LEN 12
	NOTE A_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 6
	LEN 24
	NOTE Dsh, 4
	INSTR 9
	LEN 12
	NOTE Ash, 3
	INSTR 1
	NOTE C_, 3
	INSTR 6
	NOTE Dsh, 4
	INSTR 9
	NOTE Ash, 3
	INSTR 6
	NOTE Dsh, 4
	NEXT
Pat_672E:
	INSTR 1
	LEN 24
	NOTE C_, 3
	INSTR 5
	LEN 12
	NOTE G_, 4
	INSTR 9
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 5
	LEN 24
	NOTE G_, 4
	INSTR 9
	LEN 12
	NOTE Gsh, 3
	INSTR 1
	NOTE C_, 3
	INSTR 6
	LEN 24
	NOTE Gsh, 4
	INSTR 9
	LEN 12
	NOTE Gsh, 3
	INSTR 1
	NOTE C_, 3
	INSTR 6
	NOTE Gsh, 4
	INSTR 9
	NOTE Gsh, 3
	INSTR 6
	NOTE Gsh, 4
	NEXT
Pat_674F:
	REPEAT 2
	PAT_CALL Pat_672E
	REPEAT_END
	REPEAT 2
	INSTR 1
	LEN 24
	NOTE C_, 3
	INSTR 5
	LEN 12
	NOTE D_, 4
	INSTR 9
	NOTE A_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 5
	LEN 24
	NOTE D_, 4
	INSTR 9
	LEN 12
	NOTE Ash, 3
	INSTR 1
	NOTE C_, 3
	INSTR 6
	LEN 24
	NOTE Dsh, 4
	INSTR 9
	LEN 12
	NOTE Ash, 3
	INSTR 1
	NOTE C_, 3
	INSTR 6
	NOTE Dsh, 4
	INSTR 9
	NOTE Ash, 3
	INSTR 6
	NOTE Dsh, 4
	REPEAT_END
	NEXT
Pat_6777:
	REPEAT 4
	PAT_CALL Pat_670D
	REPEAT_END
	NEXT
Pat_677D:
	REPEAT 6
	PAT_CALL Pat_672E
	REPEAT_END
	NEXT
Pat_6783:
	REPEAT 4
	INSTR 1
	LEN 24
	NOTE C_, 3
	INSTR 6
	LEN 12
	NOTE D_, 4
	INSTR 9
	NOTE A_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 6
	LEN 24
	NOTE D_, 4
	INSTR 9
	LEN 12
	NOTE A_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 5
	LEN 24
	NOTE G_, 4
	INSTR 9
	LEN 12
	NOTE Ash, 3
	INSTR 1
	NOTE C_, 3
	INSTR 5
	NOTE G_, 4
	INSTR 9
	NOTE Ash, 3
	INSTR 5
	NOTE G_, 4
	REPEAT_END
	NEXT
Pat_67A6:
	DRUMS $0C, DrumPat_6908
	VOLENV 13, $11, $1F, $13
	WAVE Wave_7947
	LENGTH $C0
	REST
	REST
	LEN 36
	NOTE D_, 3
	LENGTH $48
	NOTE A_, 3
	LEN 24
	NOTE Dsh, 3
	LEN 12
	NOTE Dsh, 3
	LEN 24
	NOTE A_, 3
	NOTE Dsh, 3
	LEN 36
	NOTE D_, 3
	LENGTH $48
	NOTE A_, 3
	LEN 24
	NOTE Dsh, 3
	LEN 12
	NOTE Dsh, 3
	LEN 24
	NOTE A_, 3
	NOTE Dsh, 3
	NEXT
Pat_67CE:
	LEN 12
	REPEAT 2
	NOTE F_, 5
	LEN 24
	NOTE G_, 5
	LEN 12
	NOTE F_, 5
	NOTE G_, 5
	NOTE D_, 4
	LEN 24
	NOTE G_, 3
	LEN 12
	NOTE Gsh, 3
	LEN 24
	NOTE Gsh, 5
	LEN 12
	NOTE Gsh, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE Dsh, 5
	REPEAT_END
	REPEAT 2
	NOTE C_, 5
	LEN 24
	NOTE D_, 5
	LEN 12
	NOTE C_, 5
	NOTE D_, 5
	NOTE A_, 3
	LEN 24
	NOTE D_, 3
	LEN 12
	NOTE Dsh, 3
	LEN 24
	NOTE Dsh, 5
	LEN 12
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE Ash, 4
	REPEAT_END
	CH_TRANSPOSE $00
	ARP_OFF
	NEXT
Pat_67FD:
	CH_TRANSPOSE $0A
	ARP 19
	VOLENV 15, $11, $1F, $11
	WAVE Wave_7AE7
	REPEAT 4
	LEN 12
	NOTE C_, 5
	LEN 24
	NOTE D_, 5
	LEN 12
	NOTE C_, 5
	NOTE D_, 5
	NOTE A_, 3
	LEN 24
	NOTE D_, 3
	LEN 12
	NOTE Dsh, 3
	LEN 24
	NOTE Dsh, 5
	LEN 12
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE Ash, 4
	REPEAT_END
	NEXT
Pat_681E:
	VIBRATO $0C, $02, $04
	ARP 0
	VOLENV 15, $11, $1F, $13
	CH_TRANSPOSE $00
	WAVE Wave_7997
	LEN 36
	NOTE A_, 4
	NOTE F_, 4
	LEN 24
	NOTE D_, 4
	LEN 6
	NOTE D_, 4
	ARP_OFF
	LEN 42
	NOTE Dsh, 4
	ARP 0
	GLIDE $FF
	LEN 24
	NOTE C_, 4
	LEN 36
	NOTE G_, 3
	GLIDE_OFF
	LEN 24
	NOTE D_, 4
	LEN 12
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	LEN 36
	NOTE A_, 4
	NOTE G_, 4
	GLIDE $FF
	LEN 24
	NOTE G_, 3
	GLIDE_OFF
	LEN 36
	NOTE A_, 4
	NOTE F_, 4
	LEN 24
	NOTE D_, 4
	LENGTH $30
	LEN 6
	NOTE D_, 4
	ARP_OFF
	LEN 42
	NOTE Dsh, 4
	ARP 0
	GLIDE $FF
	LEN 24
	NOTE C_, 4
	LEN 36
	NOTE G_, 3
	GLIDE_OFF
	LEN 24
	NOTE D_, 4
	LEN 12
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE D_, 4
	LEN 36
	NOTE D_, 4
	NOTE Dsh, 4
	LEN 24
	NOTE D_, 4
	NEXT
Pat_6870:
	ARP_OFF
	VOLENV 8, $1F, $11, $11
	CH_TRANSPOSE $0C
	ARP_OFF
	WAVE Wave_7917
	LENGTH $3C
	NOTE G_, 4
	LEN 12
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	LENGTH $3C
	NOTE D_, 5
	LEN 12
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	LEN 36
	NOTE G_, 4
	LEN 12
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 36
	NOTE Gsh, 4
	ARP 3
	NOTE Gsh, 4
	ARP_OFF
	LEN 24
	NOTE Gsh, 4
	NEXT
Pat_6899:
	LENGTH $3C
	NOTE G_, 4
	LEN 12
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	LENGTH $3C
	NOTE D_, 5
	LEN 12
	NOTE C_, 5
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE F_, 5
	ARP 3
	NOTE F_, 5
	ARP_OFF
	LEN 36
	NOTE D_, 5
	LEN 12
	NOTE D_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE Dsh, 5
	LEN 24
	NOTE C_, 5
	NOTE D_, 5
	LEN 12
	NOTE Ash, 4
	LEN 24
	ARP 3
	NOTE Ash, 4
	ARP_OFF
	NEXT
Pat_68BC:
	LENGTH $3C
	NOTE G_, 4
	LEN 12
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	LENGTH $3C
	NOTE D_, 4
	LEN 12
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	LENGTH $3C
	NOTE G_, 3
	LEN 12
	NOTE G_, 3
	NOTE F_, 3
	NOTE G_, 3
	LENGTH $30
	NOTE D_, 3
	ARP 3
	NOTE C_, 4
	NEXT
Pat_68D7:
	INSTR 7
	LENGTH $48
	NOTE A_, 3
	LEN 12
	NOTE D_, 4
	NOTE A_, 3
	LEN 36
	NOTE C_, 4
	NOTE Ash, 3
	LEN 24
	NOTE G_, 3
	LENGTH $48
	NOTE Fsh, 3
	LEN 12
	NOTE A_, 3
	NOTE D_, 3
	LEN 36
	NOTE G_, 3
	NOTE F_, 3
	LEN 24
	NOTE Dsh, 3
	LEN 36
	NOTE D_, 3
	NOTE A_, 3
	LEN 24
	NOTE C_, 4
	LEN 36
	NOTE D_, 4
	NOTE G_, 4
	LEN 24
	NOTE A_, 4
	LEN 12
	NOTE D_, 5
	LEN 24
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE Ash, 4
	NOTE C_, 5
	LEN 12
	NOTE A_, 4
	LEN 24
	ARP 3
	NOTE Gsh, 4
	ARP 0
	NOTE A_, 4
	NEXT
DrumPat_6908:
	db DRUM_LEVEL + 14, DRUM_TEMPO + 12, 1, 0, 6, 5, 1, 5
	db 0, 5, 1, 6, 4, 0, 9, 0
	db 9, DRUM_TEMPO + 6, 6, 6, DRUM_TEMPO + 12, 1, 0, 6
	db 5, 1, 5, 0, 5, 1, 6, 4
	db 0, 1, 10, 9, DRUM_TEMPO + 4, 6, 6, 6
	db DRUM_LOOP

; Song 12: instrument table - (none set), arpeggio table 1 (the one SndInit sets)
PlaySong12:
	call StopAll
	ld de, Song12_Ch1
	call StartMusicCh1
	ld de, Song12_Ch2
	call StartMusicCh2
	ld de, Song12_Ch3
	jp StartMusicCh3
Song12_Ch1:
	dw Pat_6964
	dw Pat_6964
	dw Pat_6982
	ORDER_LOOP Song12_Ch1
Song12_Ch2:
	dw Pat_69A1
	dw Pat_69A1
	dw Pat_69C3
	ORDER_LOOP Song12_Ch2
Song12_Ch3:
	dw Pat_69F0
	dw Pat_69F0
	dw Pat_6A23
	ORDER_LOOP Song12_Ch3
Pat_6964:
	DUTY_50
	HWENV $A0, $50, $A7
	VIBRATO $14, $02, $06
	LENGTH $A0
	NOTE D_, 2
	LENGTH $78
	NOTE D_, 2
	LEN 40
	NOTE A_, 2
	LENGTH $3C
	NOTE Ash, 2
	LEN 20
	NOTE Ash, 2
	LEN 40
	NOTE C_, 3
	NOTE A_, 2
	LENGTH $50
	NOTE D_, 2
	NOTE D_, 4
	NEXT
Pat_6982:
	LENGTH $8C
	NOTE Ash, 2
	LEN 20
	NOTE Ash, 2
	LENGTH $50
	NOTE C_, 2
	LEN 40
	NOTE E_, 2
	NOTE G_, 2
	LENGTH $78
	NOTE F_, 2
	LEN 40
	NOTE E_, 2
	LENGTH $50
	NOTE D_, 2
	NOTE C_, 2
	LENGTH $A0
	NOTE Ash, 2
	LENGTH $A0
	NOTE A_, 2
	WAIT
	LENGTH $A0
	NOTE D_, 2
	NEXT
Pat_69A1:
	DUTY_75
	HWENV $70, $50, $77
	VIBRATO $14, $01, $06
	LENGTH $50
	NOTE A_, 3
	NOTE C_, 4
	LEN 20
	NOTE A_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE A_, 3
	LEN 40
	NOTE F_, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE E_, 3
	LEN 20
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	NOTE F_, 3
	LENGTH $78
	NOTE D_, 3
	NEXT
Pat_69C3:
	LEN 20
	NOTE Ash, 3
	NOTE A_, 3
	LENGTH $3C
	NOTE Ash, 3
	LEN 20
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	LEN 40
	NOTE G_, 3
	NOTE E_, 3
	LENGTH $50
	NOTE Ash, 3
	LEN 20
	NOTE A_, 3
	NOTE G_, 3
	LENGTH $50
	NOTE A_, 3
	LEN 40
	NOTE E_, 3
	LENGTH $50
	NOTE D_, 3
	LEN 40
	NOTE C_, 3
	LEN 20
	NOTE E_, 3
	NOTE G_, 3
	LENGTH $A0
	NOTE F_, 3
	LEN 40
	NOTE G_, 3
	LENGTH $8C
	NOTE A_, 3
	WAIT
	LENGTH $A0
	NOTE A_, 3
	NEXT
Pat_69F0:
	VOLENV 15, $11, $1F, $17
	TRANSPOSE $02
	ARP 0
	VIBRATO $14, $01, $04
	WAVE Wave_7AD7
	CH_TRANSPOSE $0C
	LEN 20
	NOTE A_, 4
	NOTE G_, 4
	LENGTH $3C
	NOTE A_, 4
	LEN 20
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	LENGTH $3C
	NOTE F_, 4
	LEN 20
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	LEN 10
	NOTE D_, 4
	NOTE C_, 4
	LENGTH $78
	NOTE A_, 3
	NEXT
Pat_6A23:
	LEN 20
	NOTE Ash, 4
	NOTE A_, 4
	LENGTH $3C
	NOTE Ash, 4
	LEN 20
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	LENGTH $3C
	NOTE G_, 4
	LEN 20
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	LENGTH $3C
	NOTE A_, 4
	LEN 20
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LENGTH $78
	NOTE A_, 3
	LEN 20
	NOTE D_, 4
	NOTE C_, 4
	LENGTH $3C
	NOTE D_, 4
	LEN 20
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	LEN 40
	NOTE E_, 4
	LENGTH $F0
	NOTE C_, 4
	LEN 40
	NOTE A_, 3
	LENGTH $A0
	NOTE D_, 4
	NEXT

; Song 13: instrument table - (none set), arpeggio table 1 (the one SndInit sets)
PlaySong13:
	call StopAll
	ld de, Song13_Ch1
	call StartMusicCh1
	ld de, Song13_Ch2
	call StartMusicCh2
	ld de, Song13_Ch3
	jp StartMusicCh3
Song13_Ch1:
	dw Pat_6AA4
	dw Pat_6AA4
	dw Pat_6AB6
	dw Pat_6AD1
	dw Pat_6AD1
	dw Pat_6AE3
	dw Pat_6AE3
	ORDER_LOOP Song13_Ch1
Song13_Ch2:
	dw Pat_6B16
	dw Pat_6B16
	dw Pat_6B2D
	dw Pat_6B6A
	dw Pat_6B6A
	dw Pat_6B9A
	dw Pat_6B9A
	ORDER_LOOP Song13_Ch2
Song13_Ch3:
	dw Pat_6BE1
	dw Pat_6BE1
	dw Pat_6BF7
	dw Pat_6C3B
	dw Pat_6C3B
	dw Pat_6C5D
	dw Pat_6C5D
	ORDER_LOOP Song13_Ch3
Pat_6AA4:
	HWENV $F2, $06, $87
	ARP 0
	DUTY_50
	LEN 12
	REPEAT 7
	NOTE D_, 2
	NOTE D_, 3
	REPEAT_END
	NOTE F_, 2
	NOTE D_, 3
	REPEAT 8
	NOTE G_, 2
	NOTE G_, 3
	REPEAT_END
	NEXT
Pat_6AB6:
	LEN 12
	NOTE A_, 2
	NOTE A_, 2
	REST
	NOTE A_, 2
	NOTE A_, 2
	REST
	NOTE A_, 2
	REST
	NOTE A_, 2
	NOTE A_, 2
	REST
	NOTE A_, 2
	NOTE A_, 2
	REST
	LEN 24
	NOTE A_, 2
	LENGTH $30
	NOTE A_, 2
	NOTE E_, 2
	LEN 24
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NEXT
Pat_6AD1:
	LEN 12
	REPEAT 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	REPEAT_END
	REPEAT 2
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE E_, 3
	REPEAT_END
	NEXT
Pat_6AE3:
	LEN 12
	REPEAT 2
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE Ash, 2
	NOTE Ash, 3
	REPEAT_END
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE D_, 2
	NOTE E_, 2
	NEXT
Pat_6AFF:
	LEN 24
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 6
	NOTE D_, 4
	WAIT2
	NOTE E_, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE Csh, 4
	NOTE D_, 4
	NOTE Gsh, 3
	NOTE A_, 3
	NEXT
Pat_6B16:
	HWENV $A9, $04, $D0
	RELEASE $02, $D1
	DUTY_75
	VIBRATO $0C, $01, $04
	PAT_CALL Pat_6AFF
	CH_TRANSPOSE $05
	PAT_CALL Pat_6AFF
	CH_TRANSPOSE $00
	NEXT
Pat_6B2D:
	ARP 6
	LEN 12
	NOTE A_, 4
	ARP_OFF
	LEN 6
	NOTE A_, 3
	NOTE Ash, 3
	LEN 12
	NOTE A_, 3
	ARP 6
	NOTE A_, 4
	ARP_OFF
	LEN 6
	NOTE A_, 3
	NOTE Ash, 3
	LEN 12
	NOTE A_, 3
	ARP 6
	NOTE Ash, 4
	NOTE A_, 4
	NOTE A_, 4
	ARP_OFF
	LEN 6
	NOTE A_, 3
	NOTE Ash, 3
	LEN 12
	NOTE A_, 3
	ARP 6
	NOTE A_, 4
	ARP_OFF
	LEN 6
	NOTE A_, 3
	NOTE Ash, 3
	LEN 12
	NOTE A_, 3
	ARP 6
	NOTE Ash, 4
	NOTE A_, 4
	ARP_OFF
	NOTE A_, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE Csh, 4
	NOTE D_, 4
	LEN 6
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE Csh, 5
	NOTE D_, 5
	NOTE E_, 5
	NEXT
Pat_6B6A:
	LEN 12
	NOTE F_, 5
	LEN 18
	NOTE D_, 5
	LEN 6
	WAIT2
	LEN 12
	NOTE A_, 4
	NOTE Ash, 4
	NOTE Csh, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	LEN 18
	NOTE D_, 5
	LEN 6
	WAIT2
	LEN 12
	NOTE A_, 4
	NOTE Ash, 4
	NOTE Csh, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE A_, 5
	LEN 18
	NOTE F_, 5
	LEN 6
	WAIT2
	LEN 12
	NOTE A_, 4
	NOTE Ash, 4
	NOTE F_, 5
	NOTE G_, 5
	NOTE F_, 5
	LEN 18
	NOTE F_, 5
	LEN 6
	WAIT2
	LEN 18
	NOTE E_, 5
	LEN 6
	WAIT2
	LEN 12
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	NEXT
Pat_6B9A:
	LEN 12
	NOTE Gsh, 5
	LEN 18
	NOTE F_, 5
	LEN 6
	WAIT2
	LEN 12
	NOTE C_, 5
	NOTE Csh, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE Csh, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE Ash, 5
	NOTE Gsh, 5
	NOTE Csh, 6
	NOTE C_, 6
	NOTE Ash, 5
	NOTE Gsh, 5
	LEN 24
	NOTE Gsh, 5
	LEN 12
	NOTE G_, 5
	NOTE F_, 5
	LEN 24
	NOTE E_, 5
	NOTE G_, 5
	NEXT
Pat_6BBF:
	LEN 6
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE A_, 4
	NOTE E_, 5
	NOTE A_, 4
	NOTE F_, 5
	NOTE A_, 4
	NOTE G_, 5
	NOTE A_, 4
	NOTE Gsh, 5
	NOTE A_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE Csh, 5
	NOTE D_, 5
	NOTE Gsh, 4
	NOTE A_, 4
	NEXT
Pat_6BE1:
	DRUMS $06, DrumPat_6C81
	VOLENV 15, $11, $1F, $12
	WAVE Wave_7997
	PAT_CALL Pat_6BBF
	CH_TRANSPOSE $05
	PAT_CALL Pat_6BBF
	CH_TRANSPOSE $00
	NEXT
Pat_6BF7:
	LEN 12
	NOTE A_, 3
	LEN 6
	NOTE A_, 5
	NOTE Ash, 5
	LEN 12
	NOTE A_, 5
	NOTE A_, 3
	LEN 6
	NOTE A_, 5
	NOTE Ash, 5
	LEN 12
	NOTE A_, 5
	LEN 6
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	LEN 12
	NOTE A_, 3
	LEN 6
	NOTE A_, 5
	NOTE Ash, 5
	LEN 12
	NOTE A_, 5
	NOTE A_, 3
	LEN 6
	NOTE A_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE E_, 5
	NOTE A_, 5
	NOTE Csh, 5
	NOTE A_, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE E_, 5
	NOTE A_, 4
	NOTE F_, 5
	NOTE A_, 4
	NOTE G_, 5
	NOTE A_, 4
	NOTE F_, 5
	NOTE A_, 4
	NOTE G_, 5
	NOTE A_, 4
	NOTE A_, 5
	NOTE A_, 4
	NOTE Ash, 5
	NOTE A_, 4
	NOTE A_, 5
	NOTE A_, 4
	NOTE G_, 5
	NOTE A_, 4
	NOTE F_, 5
	NOTE A_, 4
	NOTE E_, 5
	NOTE A_, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE Csh, 5
	NOTE A_, 4
	NOTE A_, 5
	NOTE A_, 4
	NEXT
Pat_6C3B:
	LEN 12
	NOTE A_, 4
	LENGTH $30
	NOTE F_, 4
	LEN 12
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE A_, 4
	LENGTH $30
	NOTE F_, 4
	LEN 12
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE D_, 5
	LENGTH $30
	NOTE A_, 4
	LEN 12
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 24
	NOTE G_, 4
	NOTE E_, 4
	LEN 12
	NOTE D_, 5
	NOTE Csh, 5
	NOTE D_, 5
	NOTE E_, 5
	NEXT
Pat_6C5D:
	LEN 12
	NOTE C_, 5
	LEN 24
	NOTE Gsh, 4
	LEN 12
	NOTE F_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	LEN 24
	NOTE Gsh, 4
	LEN 12
	NOTE F_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NEXT
DrumPat_6C81:
	db DRUM_LEVEL + 13, 1, 0, 6, 6, 9, 0, 6
	db 6, DRUM_LOOP

; Song 14: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong14:
	call StopAll
	ld a, $6F
	ld [wInstrTableHi], a
	ld a, $E2
	ld [wInstrTable], a
	ld de, Song14_Ch3
	call StartMusicCh3
	ld de, Song14_Ch2
	call StartMusicCh2
	ld de, Song14_Ch1
	call StartMusicCh1
	ret
Song14_Ch3:
	dw Pat_756E
	dw Pat_6D17
	dw Pat_6D1B
	dw Pat_6D32
	dw Pat_6D32
	dw Pat_6D57
	dw Pat_6CF9
	dw Pat_6D1B
	dw Pat_6D66
	dw Pat_7571
	dw Pat_6D17
	dw Pat_6D1B
	dw Pat_6D32
	dw Pat_6D32
	dw Pat_6D57
	dw Pat_6CF9
	dw Pat_6D1B
	dw Pat_6D66
	ORDER_LOOP Song14_Ch3
Song14_Ch2:
	dw Pat_6DBC
	dw Pat_6DBC
	dw Pat_6DD1
	dw Pat_6DD1
	dw Pat_6E24
	dw Pat_6DBC
	dw Pat_6E50
	ORDER_LOOP Song14_Ch2
Song14_Ch1:
	dw Pat_6ED3
	dw Pat_6EE8
	dw Pat_6EF0
	dw Pat_6EF0
	dw Pat_6F34
	dw Pat_6ECB
	dw Pat_6F4C
	dw Pat_6F7E
	ORDER_LOOP Song14_Ch1
Pat_6CF9:
	DRUMS $07, DrumPat_6FB4
	NEXT
Pat_6CFE:
	NOTE C_, 2
	REST
	NOTE G_, 2
	REST
	NOTE F_, 2
	REST
	NOTE C_, 3
	REST
	NOTE C_, 2
	REST
	NOTE G_, 2
	REST
	NOTE G_, 2
	REST
	NOTE D_, 2
	REST
	NOTE C_, 2
	REST
	NOTE E_, 2
	REST
	NOTE F_, 2
	REST
	NOTE Fsh, 2
	REST
	NEXT
Pat_6D17:
	DRUMS $07, DrumPat_6FAA
Pat_6D1B:
	WAVE Wave_7A07
	VOLENV 15, $00, $00, $00
	CH_TRANSPOSE $0C
	ARP 0
	LEN 14
	PAT_CALL Pat_6CFE
	NOTE G_, 2
	REST
	NOTE G_, 2
	REST
	NOTE C_, 2
	REST
	NOTE G_, 2
	REST
	NEXT
Pat_6D32:
	DRUMS $07, DrumPat_6FB4
	NOTE F_, 2
	REST
	NOTE C_, 3
	REST
	NOTE F_, 2
	REST
	NOTE C_, 3
	REST
	NOTE C_, 2
	REST
	NOTE G_, 2
	REST
	NOTE C_, 2
	REST
	NOTE G_, 2
	REST
	NOTE Ash, 2
	REST
	NOTE F_, 2
	REST
	NOTE Ash, 2
	REST
	NOTE F_, 2
	REST
	NOTE A_, 2
	REST
	NOTE E_, 2
	REST
	NOTE A_, 2
	REST
	NOTE E_, 2
	REST
	NEXT
Pat_6D57:
	REPEAT 3
	NOTE G_, 2
	REST
	NOTE D_, 2
	REST
	REPEAT_END
	DRUMS $07, DrumPat_6FDA
	NOTE G_, 2
	NOTE A_, 2
	NOTE Ash, 2
	NOTE B_, 2
	NEXT
Pat_6D66:
	PAT_CALL Pat_6CFE
	NOTE E_, 2
	REST
	NOTE B_, 2
	REST
	NOTE F_, 2
	REST
	NOTE C_, 3
	REST
	REPEAT 3
	NOTE Ash, 2
	REST
	NOTE F_, 2
	REST
	REPEAT_END
	NOTE Ash, 2
	REST
	NOTE F_, 2
	NOTE Ash, 2
	REPEAT 3
	NOTE G_, 2
	REST
	NOTE D_, 2
	REST
	REPEAT_END
	LEN 7
	NOTE G_, 2
	REST
	NOTE F_, 2
	REST
	NOTE E_, 2
	REST
	LEN 14
	NOTE D_, 2
	NEXT
Pat_6D8B:
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE G_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE F_, 3
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE G_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE G_, 3
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE D_, 3
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE E_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE F_, 3
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE Fsh, 3
	INSTR 1
	NOTE F_, 4
	NEXT
Pat_6DBC:
	LEN 14
	PAT_CALL Pat_6D8B
	INSTR 0
	NOTE G_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE G_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE G_, 3
	INSTR 1
	NOTE C_, 4
	NEXT
Pat_6DD1:
	INSTR 0
	NOTE F_, 3
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 3
	INSTR 1
	LEN 7
	NOTE F_, 4
	INSTR 0
	NOTE G_, 3
	LEN 14
	NOTE F_, 3
	INSTR 1
	LEN 7
	NOTE F_, 4
	INSTR 0
	NOTE G_, 3
	LEN 14
	NOTE A_, 3
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE E_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE E_, 3
	INSTR 1
	LEN 7
	NOTE C_, 4
	INSTR 0
	NOTE F_, 3
	LEN 14
	NOTE E_, 3
	INSTR 1
	LEN 7
	NOTE C_, 4
	INSTR 0
	NOTE F_, 3
	LEN 14
	NOTE G_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE Ash, 3
	INSTR 1
	NOTE Ash, 3
	INSTR 0
	NOTE Ash, 3
	INSTR 1
	NOTE Ash, 3
	INSTR 0
	NOTE Ash, 3
	INSTR 1
	LEN 7
	NOTE Ash, 3
	INSTR 0
	LEN 21
	NOTE F_, 3
	INSTR 1
	LEN 14
	NOTE Ash, 3
	INSTR 0
	NOTE A_, 3
	INSTR 2
	NOTE A_, 3
	INSTR 0
	NOTE A_, 3
	INSTR 2
	NOTE A_, 3
	INSTR 0
	NOTE A_, 3
	INSTR 2
	LEN 7
	NOTE A_, 3
	INSTR 0
	LEN 21
	NOTE E_, 3
	INSTR 2
	LEN 14
	NOTE A_, 3
	NEXT
Pat_6E24:
	INSTR 0
	NOTE G_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE D_, 3
	INSTR 1
	LEN 7
	NOTE G_, 3
	INSTR 0
	NOTE F_, 3
	REPEAT 2
	LEN 14
	NOTE G_, 3
	INSTR 1
	LEN 7
	NOTE G_, 3
	INSTR 0
	NOTE F_, 3
	LEN 14
	NOTE D_, 3
	INSTR 1
	LEN 7
	NOTE G_, 3
	INSTR 0
	NOTE F_, 3
	REPEAT_END
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE G_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE A_, 3
	INSTR 1
	NOTE Ash, 3
	INSTR 0
	NOTE Ash, 3
	INSTR 1
	NOTE B_, 3
	INSTR 0
	NOTE B_, 3
	NEXT
Pat_6E50:
	PAT_CALL Pat_6D8B
	INSTR 0
	NOTE E_, 3
	INSTR 2
	NOTE E_, 4
	INSTR 0
	NOTE B_, 3
	INSTR 2
	NOTE E_, 4
	INSTR 0
	NOTE F_, 3
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE F_, 4
	REPEAT 2
	LEN 14
	INSTR 0
	NOTE Ash, 3
	INSTR 1
	LEN 7
	NOTE Ash, 4
	INSTR 0
	NOTE Ash, 3
	LEN 14
	NOTE A_, 3
	INSTR 1
	LEN 7
	NOTE Ash, 4
	INSTR 0
	NOTE A_, 3
	LEN 14
	NOTE G_, 3
	INSTR 1
	LEN 7
	NOTE Ash, 4
	INSTR 0
	NOTE G_, 3
	LEN 14
	NOTE F_, 3
	INSTR 1
	LEN 7
	NOTE Ash, 4
	INSTR 0
	NOTE F_, 3
	REPEAT_END
	LEN 14
	NOTE G_, 3
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE D_, 3
	INSTR 1
	LEN 7
	NOTE G_, 4
	INSTR 0
	NOTE D_, 3
	REPEAT 2
	LEN 14
	NOTE G_, 3
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE D_, 3
	INSTR 1
	NOTE G_, 4
	REPEAT_END
	LEN 7
	NOTE G_, 4
	INSTR 0
	NOTE G_, 3
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE E_, 4
	INSTR 0
	NOTE E_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 0
	NOTE D_, 3
	NEXT
Pat_6EA8:
	LEN 28
	NOTE G_, 4
	LEN 21
	NOTE C_, 5
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE A_, 4
	NOTE F_, 4
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE E_, 4
	LENGTH $38
	NOTE D_, 4
	LEN 28
	NOTE G_, 4
	LEN 21
	NOTE C_, 5
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE A_, 4
	NOTE F_, 4
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE G_, 4
	NOTE E_, 4
	NOTE F_, 4
	NEXT
Pat_6ECB:
	CH_TRANSPOSE $0C
	RELEASE $03, $62
	PAT_GOTO Pat_6ED7
Pat_6ED3:
	HWENV $F1, $02, $A7
Pat_6ED7:
	DUTY_50
	ARP 0
	RELEASE $01, $51
	VIBRATO $0C, $01, $04
	PAT_CALL Pat_6EA8
	NOTE B_, 3
	LENGTH $38
	NOTE C_, 4
	NEXT
Pat_6EE8:
	PAT_CALL Pat_6EA8
	NOTE B_, 4
	LENGTH $38
	NOTE C_, 5
	NEXT
Pat_6EF0:
	LEN 14
	WAIT
	HWENV $79, $03, $90
	DUTY_75
	LEN 7
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 4
	WAIT2
	NOTE A_, 4
	NOTE B_, 4
	LEN 14
	NOTE A_, 4
	LEN 7
	WAIT2
	NOTE B_, 4
	NOTE C_, 5
	WAIT2
	NOTE A_, 4
	WAIT2
	LEN 21
	NOTE G_, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE E_, 4
	NOTE F_, 4
	LENGTH $38
	NOTE G_, 4
	LEN 14
	WAIT2
	LEN 7
	NOTE G_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	LEN 21
	NOTE F_, 4
	LEN 14
	NOTE E_, 4
	LEN 7
	WAIT2
	LEN 28
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	LEN 21
	NOTE F_, 4
	LEN 14
	NOTE E_, 4
	LEN 7
	WAIT2
	LEN 14
	NOTE F_, 4
	NEXT
Pat_6F34:
	LENGTH $3F
	NOTE D_, 4
	LENGTH $31
	WAIT2
	LEN 7
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE Ash, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE Csh, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE Fsh, 5
	NEXT
Pat_6F4C:
	CH_TRANSPOSE $00
	LEN 28
	NOTE G_, 5
	LEN 21
	NOTE C_, 6
	LEN 7
	NOTE G_, 5
	LEN 14
	NOTE A_, 5
	NOTE F_, 5
	LEN 28
	NOTE D_, 5
	LEN 14
	NOTE G_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE E_, 5
	LENGTH $38
	NOTE D_, 5
	LEN 28
	NOTE G_, 5
	LEN 21
	NOTE C_, 6
	LEN 7
	NOTE G_, 5
	LEN 14
	NOTE A_, 5
	NOTE F_, 5
	LEN 21
	NOTE D_, 5
	LEN 7
	NOTE A_, 5
	LEN 14
	NOTE B_, 5
	NOTE G_, 5
	LEN 21
	NOTE E_, 5
	LEN 7
	NOTE B_, 5
	LEN 14
	NOTE C_, 6
	LEN 7
	NOTE A_, 5
	NOTE F_, 5
	LEN 14
	NOTE A_, 5
	NOTE C_, 6
	NEXT
Pat_6F7E:
	LENGTH $3F
	NOTE D_, 6
	WAIT
	LEN 14
	NOTE F_, 5
	NOTE Ash, 5
	NOTE D_, 6
	NOTE F_, 6
	LEN 5
	NOTE E_, 6
	NOTE F_, 6
	LEN 4
	NOTE E_, 6
	LEN 14
	NOTE D_, 6
	NOTE C_, 6
	LEN 42
	NOTE B_, 5
	LEN 7
	NOTE C_, 6
	NOTE D_, 6
	LENGTH $31
	NOTE G_, 5
	LEN 7
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NEXT
DrumPat_6FAA:
	db DRUM_LEVEL + 13, 1, 0, 6, 5, 1, 0, 6
	db 5, DRUM_LOOP
DrumPat_6FB4:
	db DRUM_LEVEL + 13, DRUM_REPEAT + 3, 1, 0, 6, 5, 9, 0
	db 6, 5, DRUM_REPEAT_END, 1, 0, 6, 5, 9
	db 0, 1, 5, DRUM_REPEAT + 3, 1, 0, 6, 5
	db 9, 0, 6, 5, DRUM_REPEAT_END, 1, 0, 6
	db 5, 9, 0, 6, 9, DRUM_LOOP
DrumPat_6FDA:
	db DRUM_LEVEL + 13, 1, 0, 6, 5, 9, 0, 9
	db 9, DRUM_LOOP

; Instrument table 3, entries 1..3 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr3_0
	dw Instr3_1
	dw Instr3_2
Instr3_0:
	ARP 0
	DUTY_12
	HWENV $F1, $00
	END
Instr3_1:
	ARP 6
	DUTY_75
	HWENV $E1, $00
	END
Instr3_2:
	ARP 5
	DUTY_75
	HWENV $E1, $00
	END

; Song 15: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong15:
	ld a, $75
	ld [wInstrTableHi], a
	ld a, $72
	ld [wInstrTable], a
	call StopAll
	ld de, Song15_Ch1
	call StartMusicCh1
	ld de, Song15_Ch3
	call StartMusicCh3
	ld de, Song15_Ch2
	jp StartMusicCh2
Song15_Ch2:
	dw Pat_70D1
	dw Pat_70D1
	dw Pat_7110
	dw Pat_7166
	dw Pat_717B
	dw Pat_705F
	dw Pat_7090
	dw Pat_70B1
	ORDER_LOOP Song15_Ch2
Song15_Ch1:
	dw Pat_7202
	dw Pat_7213
	dw Pat_7202
	dw Pat_7213
	dw Pat_7228
	dw Pat_7202
	dw Pat_7252
	dw Pat_71A2
	dw Pat_71B8
	dw Pat_71B8
	ORDER_LOOP Song15_Ch1
Song15_Ch3:
	dw Pat_72D3
	dw Pat_7302
	dw Pat_72D3
	dw Pat_7302
	dw Pat_7336
	dw Pat_72D3
	dw Pat_7320
	dw Pat_7273
	dw Pat_729D
	dw Pat_72A9
	ORDER_LOOP Song15_Ch3
Pat_705F:
	LENGTH $48
	NOTE F_, 4
	LEN 8
	WAIT2
	NOTE A_, 5
	NOTE Ash, 5
	NOTE C_, 6
	WAIT2
	NOTE A_, 5
	WAIT2
	NOTE F_, 5
	LEN 24
	WAIT2
	LEN 32
	NOTE F_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NEXT
Pat_7072:
	LEN 16
	WAIT2
	LEN 8
	NOTE Ash, 5
	NOTE A_, 5
	NOTE Ash, 5
	WAIT2
	LEN 24
	NOTE F_, 5
	LEN 8
	WAIT2
	NOTE Ash, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE Ash, 5
	NOTE A_, 5
	WAIT2
	NOTE F_, 5
	WAIT2
	LEN 40
	NOTE C_, 5
	LEN 8
	WAIT2
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	WAIT2
	NEXT
Pat_7090:
	PAT_CALL Pat_7072
	NOTE F_, 5
	WAIT2
	NOTE E_, 5
	WAIT2
	NOTE F_, 5
	NOTE G_, 5
	LEN 32
	NOTE C_, 5
	LEN 8
	NOTE Ash, 4
	WAIT2
	NOTE C_, 5
	NOTE D_, 5
	NOTE G_, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	LEN 32
	NOTE A_, 4
	NOTE Ash, 4
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE F_, 5
	WAIT2
	NOTE G_, 5
	WAIT2
	LEN 16
	NOTE A_, 5
	NEXT
Pat_70B1:
	PAT_CALL Pat_7072
	NOTE A_, 5
	WAIT2
	NOTE C_, 6
	WAIT2
	NOTE G_, 5
	NOTE E_, 5
	LEN 16
	NOTE C_, 5
	NOTE G_, 5
	LEN 8
	NOTE C_, 6
	WAIT2
	LEN 16
	NOTE D_, 6
	NOTE C_, 6
	NOTE D_, 6
	LEN 8
	NOTE Gsh, 5
	WAIT2
	NOTE A_, 5
	NOTE C_, 6
	WAIT2
	NOTE A_, 5
	NOTE C_, 5
	WAIT2
	LEN 32
	NOTE F_, 5
	WAIT2
	NEXT
Pat_70D1:
	DRUMS $08, DrumPat_736D
	HWENV $D1, $00
	DUTY_12
	ARP_OFF
	RELEASE $00
	REPEAT 8
	LEN 16
	NOTE F_, 4
	LEN 8
	NOTE A_, 4
	NOTE F_, 4
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE A_, 4
	NOTE C_, 4
	REPEAT_END
	LEN 16
	REPEAT 3
	NOTE G_, 4
	LEN 8
	NOTE Ash, 4
	NOTE G_, 4
	LEN 16
	NOTE D_, 4
	NOTE Ash, 4
	REPEAT_END
	NOTE G_, 4
	LEN 8
	NOTE Ash, 4
	NOTE G_, 4
	LEN 16
	NOTE D_, 4
	NOTE G_, 4
	NOTE C_, 5
	LEN 8
	NOTE C_, 5
	NOTE C_, 4
	LEN 16
	NOTE F_, 4
	LEN 8
	NOTE A_, 4
	NOTE F_, 4
	LEN 16
	NOTE C_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE C_, 5
	NEXT
Pat_7110:
	HWENV $79, $04, $C0
	DUTY_50
	RELEASE $01, $A1
	VIBRATO $10, $01, $05
	ARP_OFF
	LEN 24
	NOTE A_, 4
	LEN 8
	NOTE Ash, 4
	LEN 16
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	LENGTH $38
	NOTE C_, 5
	LEN 8
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE G_, 4
	NOTE F_, 4
	LEN 16
	NOTE E_, 4
	LEN 8
	NOTE C_, 5
	WAIT2
	LEN 16
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE D_, 5
	LEN 8
	NOTE C_, 5
	WAIT2
	NOTE D_, 5
	NOTE Dsh, 5
	LEN 24
	NOTE E_, 5
	LEN 8
	WAIT2
	NEXT
Pat_714D:
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NEXT
Pat_7166:
	LEN 8
	PAT_CALL Pat_714D
	NOTE Ash, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE Ash, 4
	PAT_CALL Pat_714D
	LEN 16
	NOTE F_, 5
	NOTE D_, 5
	NOTE A_, 4
	NOTE Gsh, 4
	NEXT
Pat_717B:
	LEN 16
	NOTE G_, 4
	NOTE G_, 5
	NOTE G_, 5
	NOTE A_, 5
	LEN 24
	NOTE G_, 5
	LEN 8
	WAIT2
	LEN 16
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE G_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE F_, 5
	NOTE G_, 5
	LENGTH $38
	NOTE E_, 5
	LEN 8
	WAIT2
	LENGTH $38
	NOTE D_, 5
	LEN 8
	WAIT2
	LENGTH $38
	NOTE C_, 5
	LEN 8
	WAIT2
	LEN 32
	NOTE F_, 4
	NOTE G_, 4
	NEXT
Pat_71A2:
	INSTR 2
	LEN 16
	NOTE F_, 2
	INSTR 6
	NOTE F_, 3
	INSTR 2
	NOTE F_, 2
	INSTR 6
	NOTE F_, 3
	INSTR 2
	NOTE F_, 2
	INSTR 6
	NOTE F_, 3
	INSTR 2
	NOTE F_, 2
	NOTE F_, 2
	LEN 32
	NOTE F_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 2
	NEXT
Pat_71B8:
	LEN 16
	INSTR 2
	NOTE Ash, 2
	INSTR 6
	NOTE Ash, 3
	INSTR 2
	NOTE Ash, 2
	INSTR 6
	NOTE Ash, 3
	INSTR 2
	NOTE Ash, 2
	INSTR 6
	NOTE Ash, 3
	INSTR 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE F_, 2
	INSTR 6
	NOTE F_, 4
	INSTR 2
	NOTE F_, 2
	INSTR 6
	NOTE F_, 4
	INSTR 2
	NOTE F_, 2
	INSTR 6
	NOTE F_, 4
	INSTR 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE C_, 2
	INSTR 6
	NOTE C_, 4
	INSTR 2
	NOTE C_, 2
	INSTR 6
	NOTE C_, 4
	INSTR 2
	NOTE C_, 2
	INSTR 6
	NOTE C_, 4
	INSTR 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE F_, 2
	INSTR 6
	NOTE F_, 4
	INSTR 2
	NOTE F_, 2
	INSTR 6
	NOTE F_, 4
	INSTR 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 2
	NEXT
Pat_71F1:
	INSTR 2
	NOTE F_, 2
	INSTR 6
	NOTE F_, 4
	INSTR 2
	NOTE C_, 2
	INSTR 6
	NOTE F_, 4
	REPEAT_END
	INSTR 2
	NOTE F_, 2
	INSTR 6
	NOTE F_, 4
	INSTR 2
	NOTE G_, 2
	NOTE A_, 2
	NEXT
Pat_7202:
	LEN 16
	REPEAT 3
	PAT_CALL Pat_71F1
	NOTE F_, 2
	INSTR 6
	NOTE F_, 4
	INSTR 2
	NOTE C_, 2
	INSTR 6
	NOTE F_, 4
	REPEAT 2
	PAT_CALL Pat_71F1
	NEXT
Pat_7213:
	REPEAT 4
	INSTR 2
	NOTE G_, 2
	INSTR 6
	NOTE Ash, 4
	INSTR 2
	NOTE D_, 2
	INSTR 6
	NOTE Ash, 4
	REPEAT_END
	REPEAT 4
	INSTR 2
	NOTE F_, 2
	INSTR 6
	NOTE F_, 4
	INSTR 2
	NOTE C_, 2
	INSTR 6
	NOTE F_, 4
	REPEAT_END
	NEXT
Pat_7228:
	REPEAT 4
	INSTR 2
	NOTE F_, 2
	INSTR 6
	NOTE F_, 4
	INSTR 2
	NOTE C_, 2
	INSTR 6
	NOTE F_, 4
	REPEAT_END
	INSTR 2
	NOTE C_, 2
	INSTR 6
	NOTE C_, 4
	INSTR 2
	NOTE G_, 2
	INSTR 6
	NOTE C_, 4
	INSTR 2
	NOTE F_, 2
	INSTR 6
	NOTE F_, 4
	INSTR 2
	NOTE C_, 3
	INSTR 6
	NOTE F_, 4
	INSTR 2
	NOTE G_, 2
	INSTR 6
	NOTE G_, 4
	INSTR 2
	NOTE D_, 2
	INSTR 6
	NOTE G_, 4
	INSTR 2
	NOTE C_, 3
	INSTR 6
	NOTE C_, 5
	INSTR 2
	NOTE C_, 2
	NOTE C_, 3
	NEXT
Pat_7252:
	REPEAT 4
	INSTR 2
	NOTE G_, 2
	INSTR 6
	NOTE Ash, 4
	INSTR 2
	NOTE D_, 2
	INSTR 6
	NOTE Ash, 4
	REPEAT_END
	REPEAT 2
	INSTR 2
	NOTE C_, 2
	INSTR 6
	NOTE C_, 5
	INSTR 2
	NOTE G_, 2
	INSTR 6
	NOTE C_, 5
	REPEAT_END
	INSTR 2
	NOTE C_, 2
	INSTR 6
	NOTE C_, 4
	INSTR 2
	NOTE G_, 2
	INSTR 6
	NOTE C_, 4
	INSTR 2
	LEN 32
	NOTE C_, 2
	NOTE C_, 3
	NEXT
Pat_7273:
	LEN 32
	NOTE A_, 4
	NOTE F_, 3
	NOTE F_, 3
	LEN 16
	NOTE F_, 3
	NOTE F_, 3
	LEN 32
	NOTE F_, 3
	NOTE F_, 3
	NOTE G_, 3
	LEN 16
	NOTE A_, 3
	NOTE C_, 4
	NEXT
Pat_7282:
	LEN 16
	NOTE D_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE D_, 5
	NOTE D_, 5
	NOTE D_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NEXT
Pat_729D:
	PAT_CALL Pat_7282
	LEN 16
	NOTE A_, 4
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE C_, 4
	NEXT
Pat_72A9:
	PAT_CALL Pat_7282
	LEN 8
	NOTE A_, 4
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE A_, 4
	LEN 16
	NOTE C_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	LEN 8
	NOTE A_, 4
	NOTE Ash, 4
	NEXT
Pat_72BB:
	LEN 16
	NOTE C_, 5
	NOTE C_, 5
	LEN 24
	NOTE C_, 5
	LEN 8
	NOTE A_, 4
	LEN 16
	NOTE D_, 5
	NOTE D_, 5
	LEN 24
	NOTE D_, 5
	LEN 8
	NOTE A_, 4
	LEN 16
	NOTE E_, 5
	LEN 8
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NEXT
Pat_72D3:
	VOLENV 15, $10, $1F, $12
	ARP 0
	VIBRATO $08, $01, $03
	WAVE Wave_7A97
	PAT_CALL Pat_72BB
	LEN 16
	NOTE E_, 5
	NOTE D_, 5
	LEN 24
	NOTE D_, 5
	LEN 8
	NOTE E_, 5
	PAT_CALL Pat_72BB
	LEN 16
	NOTE A_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE B_, 4
	NEXT
Pat_72F2:
	LEN 16
	NOTE Ash, 4
	NOTE G_, 5
	NOTE G_, 5
	NOTE A_, 5
	LEN 32
	NOTE G_, 5
	LEN 16
	NOTE C_, 5
	NOTE B_, 4
	NOTE Ash, 4
	NOTE G_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE G_, 5
	NEXT
Pat_7302:
	PAT_CALL Pat_72F2
	LEN 8
	NOTE A_, 5
	NOTE G_, 5
	LEN 16
	NOTE F_, 5
	NOTE G_, 5
	NOTE A_, 5
	LEN 8
	NOTE A_, 5
	NOTE F_, 5
	LENGTH $38
	NOTE C_, 5
	LEN 8
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE A_, 5
	NEXT
Pat_7320:
	PAT_CALL Pat_72F2
	NOTE D_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE C_, 5
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE A_, 4
	LEN 32
	NOTE C_, 5
	NOTE Ash, 4
	NEXT
Pat_7336:
	LEN 16
	NOTE C_, 6
	NOTE C_, 6
	NOTE C_, 6
	NOTE D_, 6
	LEN 24
	NOTE C_, 6
	LEN 8
	NOTE C_, 6
	LEN 16
	NOTE B_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE A_, 5
	NOTE A_, 5
	NOTE Ash, 5
	LEN 24
	NOTE A_, 5
	LEN 8
	NOTE A_, 5
	LEN 16
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	LEN 8
	NOTE E_, 5
	NOTE F_, 5
	LEN 32
	NOTE G_, 5
	LEN 16
	NOTE F_, 5
	LEN 8
	NOTE F_, 5
	NOTE G_, 5
	LEN 32
	NOTE A_, 5
	LEN 16
	NOTE G_, 5
	LEN 8
	NOTE G_, 5
	NOTE A_, 5
	NOTE B_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE B_, 5
	LEN 16
	NOTE C_, 6
	LEN 8
	NOTE C_, 6
	NOTE D_, 6
	NOTE E_, 6
	NOTE E_, 6
	NOTE D_, 6
	NOTE Csh, 6
	NEXT
DrumPat_736D:
	db DRUM_LEVEL + 14, DRUM_REPEAT + 7, 1, 0, 9, 0, DRUM_REPEAT_END, 9
	db 0, 9, 0, DRUM_REPEAT + 6, 1, 0, 9, 0
	db DRUM_REPEAT_END, 1, 0, 9, 9, 9, 0, 9
	db 0, DRUM_LOOP

; Song 16: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong16:
	ld a, $75
	ld [wInstrTableHi], a
	ld a, $72
	ld [wInstrTable], a
	call StopAll
	ld de, Song16_Ch1
	call StartMusicCh1
	ld de, Song16_Ch2
	call StartMusicCh2
	ld de, Song16_Ch3
	jp StartMusicCh3
Song16_Ch1:
	dw Pat_73B8

; Unreferenced (4 bytes)
	db $00, $00, $A6, $73
Song16_Ch2:
	dw Pat_73C8

; Unreferenced (4 bytes)
	db $00, $00, $AC, $73
Song16_Ch3:
	dw Pat_73DE

; Unreferenced (4 bytes)
	db $00, $00, $B2, $73
Pat_73B8:
	HWENV $F3, $00
	ARP 0
	DUTY_50
	LEN 32
	NOTE C_, 2
	LEN 16
	NOTE C_, 3
	NOTE C_, 2
	NOTE F_, 2
	NOTE D_, 2
	LENGTH $D0
	NOTE G_, 2
	END
Pat_73C8:
	DRUMS $08, DrumPat_73FF
	INSTR 6
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE C_, 4
	NOTE C_, 4
	LEN 16
	NOTE C_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE F_, 4
	LEN 5
	NOTE G_, 4
	DRUMS_OFF
	LENGTH $D0
	WAIT
	END
Pat_73DE:
	VOLENV 15, $11, $1F, $14
	RELEASE $01, $51
	CH_TRANSPOSE $0C
	VIBRATO $10, $01, $04
	WAVE Wave_7A97
	LEN 8
	NOTE C_, 4
	WAIT2
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	WAIT2
	LEN 16
	ARP 3
	NOTE Ash, 4
	ARP_OFF
	NOTE A_, 4
	NOTE F_, 4
	LENGTH $80
	NOTE G_, 4
	END
DrumPat_73FF:
	db 9, 0, 10, 10, 9, 0, 9, 11        ; no DRUM_LOOP: the pattern runs into the next data
	db 10, 10, 9, 0, 9, 0, 0, 0

; Song 17: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong17:
	ld a, $75
	ld [wInstrTableHi], a
	ld a, $72
	ld [wInstrTable], a
	call StopAll
	ld de, Song17_Ch1
	call StartMusicCh1
	ld de, Song17_Ch2
	call StartMusicCh2
	ld de, Song17_Ch3
	jp StartMusicCh3
Song17_Ch1:
	dw Pat_7440

; Unreferenced (4 bytes)
	db $00, $00, $2E, $74
Song17_Ch2:
	dw Pat_7474

; Unreferenced (4 bytes)
	db $00, $00, $34, $74
Song17_Ch3:
	dw Pat_7494

; Unreferenced (4 bytes)
	db $00, $00, $3A, $74
Pat_7440:
	INSTR 0
	LEN 11
	NOTE C_, 2
	NOTE C_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 0
	LEN 22
	NOTE C_, 2
	LEN 11
	NOTE C_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE C_, 3
	NOTE G_, 2
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 0
	LEN 22
	NOTE G_, 2
	LEN 11
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE G_, 2
	NOTE F_, 2
	NOTE F_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE G_, 2
	NOTE C_, 2
	INSTR 1
	LEN 6
	NOTE Ash, 3
	NOTE Gsh, 3
	LEN 10
	NOTE Fsh, 3
	INSTR 0
	LENGTH $CB
	NOTE C_, 3
	END
Pat_7474:
	INSTR 6
	LEN 11
	NOTE C_, 4
	LEN 22
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	LEN 11
	NOTE C_, 4
	NOTE G_, 4
	LEN 22
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 11
	NOTE G_, 4
	NOTE F_, 4
	LEN 22
	NOTE F_, 4
	LEN 11
	NOTE F_, 4
	NOTE G_, 4
	LEN 22
	NOTE G_, 4
	LEN 11
	NOTE G_, 4
	LEN 33
	NOTE C_, 5
	LENGTH $CB
	NOTE C_, 6
	END
Pat_7494:
	DRUMS $0B, DrumPat_74C4
	VOLENV 15, $11, $1F, $14
	ARP 0
	VIBRATO $0B, $01, $04
	WAVE Wave_7A97
	LENGTH $37
	NOTE C_, 5
	LEN 11
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE B_, 4
	NOTE G_, 4
	LENGTH $37
	NOTE G_, 5
	LEN 11
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	LEN 22
	NOTE B_, 4
	LEN 11
	NOTE A_, 4
	LEN 22
	NOTE B_, 4
	LEN 33
	NOTE C_, 5
	LEN 4
	NOTE C_, 6
	DRUMS_OFF
	LENGTH $DC
	WAIT
	END
DrumPat_74C4:
	db 1, 6, 9, 6, 1, 1, 9, 4           ; no DRUM_LOOP: the pattern runs into the next data
	db 1, 6, 9, 6, 1, 1, 9, 4
	db 1, 1, 9, 4, 1, 1, 9, 4
	db 1, 1, 1, 9, 9, 0, 0

; Song 18: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong18:
	ld a, $75
	ld [wInstrTableHi], a
	ld a, $72
	ld [wInstrTable], a
	call StopAll
	ld de, Song18_Ch1
	call StartMusicCh1
	ld de, Song18_Ch2
	call StartMusicCh2
	ld de, Song18_Ch3
	jp StartMusicCh3
Song18_Ch1:
	dw Pat_7508
Song18_Ch2:
	dw Pat_751F
Song18_Ch3:
	dw Pat_752F
Pat_7508:
	ARP 0
	HWENV $F3, $00
	DUTY_75
	LEN 35
	NOTE C_, 2
	LEN 7
	NOTE E_, 2
	LEN 35
	NOTE F_, 2
	LEN 7
	NOTE Fsh, 2
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE A_, 2
	LEN 14
	NOTE B_, 2
	LENGTH $FF
	NOTE C_, 3
	END
Pat_751F:
	ARP 6
	HWENV $F2, $00
	DUTY_12
	LEN 21
	REST
	LEN 42
	NOTE C_, 4
	NOTE F_, 4
	LEN 14
	NOTE G_, 4
	LENGTH $FF
	NOTE C_, 5
	END
Pat_752F:
	DRUMS $07, DrumPat_7558
	VOLENV 15, $11, $1F, $13
	ARP 0
	VIBRATO $07, $01, $05
	WAVE Wave_7A97
	LEN 14
	NOTE G_, 4
	LEN 21
	NOTE E_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE A_, 4
	LEN 21
	NOTE F_, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE B_, 4
	LEN 5
	NOTE C_, 5
	DRUMS_OFF
	LENGTH $FF
	WAIT
	END
DrumPat_7558:
	db 1, 0, 4, 9, 0, 4, 1, 0
	db 1, 9, 0, 4, 1, 0, 1, 9
	db 0, 9, 0, 0, 0, DRUM_LOOP
Pat_756E:
	TRANSPOSE $00
	NEXT
Pat_7571:
	TRANSPOSE $02
	NEXT

; Instrument table 4, entries 1..15 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr4_0
	dw Instr4_1
	dw Instr4_2
	dw Instr4_3
	dw Instr4_4
	dw Instr4_5
	dw Instr4_6
	dw Instr4_7
	dw Instr4_8
	dw Instr4_9
	dw Instr4_10
	dw Instr4_10
	dw Instr4_10
	dw Instr4_13
	dw Instr4_13
Instr4_0:
	HWENV $F1, $04, $A4
	DUTY_75
	END
Instr4_1:
	HWENV $F1, $05, $61
	ARP 18
	DUTY_50
	END
Instr4_2:
	HWENV $F2, $04, $75
	DUTY_50
	ARP 0
	END
Instr4_3:
	HWENV $C2, $04, $72
	DUTY_75
	ARP 12
	END
Instr4_4:
	HWENV $F2, $04, $84
	DUTY_12
	ARP 4
	END
Instr4_5:
	HWENV $F2, $04, $84
	DUTY_12
	ARP 5
	END
Instr4_6:
	HWENV $F2, $04, $84
	DUTY_12
	ARP 6
	END
Instr4_7:
	VOLENV 15, $11, $1F, $14
	ARP 0
	END
Instr4_8:
	HWENV $F1, $00
	ARP 0
	DUTY_12
	END
Instr4_9:
	HWENV $A2, $00
	END
Instr4_10:
	HWENV $F2, $0D, $47
	ARP 0
	DUTY_75
	END
Instr4_13:
	HWENV $F2, $0E, $67
	ARP 0
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
	dw Arp19

; Unreferenced (16 bytes)
	db $98, $76, $98, $76, $98, $76, $98, $76, $98, $76, $98, $76, $98, $76, $98, $76
Arp0:
	db $0C, $00, ARP_HOLD
Arp3:
	db $00, $00, $01, $01, $02, ARP_HOLD
Arp2:
	db $0C, $0C, $0C, $00, $00, $00, ARP_LOOP
Arp1:
	db $00, $00, $03, $03, $08, $08, ARP_LOOP
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
Arp19:
	db $0E, $03
SfxTable_m2:
	db $02, ARP_HOLD

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

; Sound effect 12
Sfx12:
	LEN 6
	VOLENV 15, $11, $1F, $14
	CH_TRANSPOSE $18
	WAVE Wave_7A27
	LEN 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE E_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE E_, 5
	NOTE G_, 5
	NOTE B_, 5
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE C_, 6
	VOLENV 10, $00, $00, $00
	NOTE F_, 5
	NOTE A_, 5
	NOTE C_, 6
	VOLENV 5, $00, $00, $00
	NOTE F_, 5
	NOTE A_, 5
	NOTE C_, 6
	END

; Sound effect 9
Sfx09:
	LEN 4
	VOLENV 15, $11, $2F, $11
	CALL_CODE Drum1
	WAVE Wave_7977
	GLIDE $F8
	NOTE A_, 5
	END

; Sound effect 8
Sfx08:
	VOLENV 15, $11, $1F, $12
	CH_TRANSPOSE $02
	ARP 0
	SLIDE_UP $0A
	WAVE Wave_7977
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

; Sound effect 10
Sfx10:
	LEN 3
	VOLENV 15, $11, $1F, $11
	CH_TRANSPOSE $0C
	WAVE Wave_7A27
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	VOL $05
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	END

; Sound effect 11
Sfx11:
	VOLENV 15, $00, $00, $00
	LEN 2
	CH_TRANSPOSE $18
	ARP 0
	WAVE Wave_7A27
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE Dsh, 5
	NOTE Ash, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE B_, 4
	VOL $0A
	NOTE G_, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE B_, 4
	VOL $05
	NOTE G_, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE B_, 4
	END

; Sound effect 4
Sfx04:
	LEN 14
	VOLENV 15, $15, $1F, $11
	GLIDE $01
	WAVE Wave_7977
	NOTE E_, 3
	END

; Sound effect 5
Sfx05:
	LEN 14
	VOLENV 15, $15, $1F, $12
	GLIDE $01
	WAVE Wave_7977
	NOTE Gsh, 3
	GLIDE $FF
	LEN 4
	WAIT
	END

; Sound effect 6
Sfx06:
	LEN 20
	VOLENV 15, $18, $1F, $12
	GLIDE $01
	WAVE Wave_7977
	NOTE B_, 3
	LEN 4
	GLIDE $FF
	WAIT
	END

; Sound effect 16
Sfx16:
	VOLENV 10, $00, $00, $00
	GLIDE $FC
	WAVE Wave_79B7
	CALL_CODE Code_7858
	LEN 5
	NOTE A_, 5
	END

; Sound effect 15
Sfx15:
	CALL_CODE Code_7809
	VOLENV 15, $11, $1F, $15
	WAVE Wave_7977
	LEN 9
	GLIDE $FC
	NOTE A_, 4
	END

; Sound effect 14
Sfx14:
	CALL_CODE Code_78C1
	VOLENV 15, $11, $1F, $15
	WAVE Wave_7977
	LEN 9
	GLIDE $FD
	NOTE A_, 3
	END

; Sound effect 2
Sfx02:
	VOLENV 15, $11, $2F, $11
	WAVE Wave_7997
	LEN 13
	NOTE C_, 6
	END

; Sound effect 3
Sfx03:
	LEN 4
	VOLENV 15, $11, $2F, $11
	WAVE Wave_7997
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
	WAVE Wave_7A17
	VOLENV 15, $10, $1F, $12
	RELEASE $02, $55
	NOTE C_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	END

; Sound effect 13
Sfx13:
	VOLENV 10, $11, $1F, $14
	WAVE Wave_7977
	LEN 33
	SLIDE_DOWN $03
	NOTE A_, 5
	END

; Sound effect 7
Sfx07:
	CALL_CODE Code_7894
	VOLENV 15, $00, $00, $00
	WAVE Wave_7AE7
	LEN 3
	GLIDE $FF
	NOTE Csh, 6
	WAVE Wave_7AB7
	WAIT
	WAVE Wave_7AD7
	WAIT
	END
Code_7809:
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
	ld a, HIGH(Noise43_7833)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7833)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_7833:
	db $36, $35, $34, $33, $32, $31, $20, $10
	db $10, $37, $36, $35, $34, $33, $32, $21
	db $11, $11, $38, $37, $36, $35, $34, $33
	db $22, $12, $12, $39, $38, $37, $36, $35
	db $34, $23, $13, $13, $FF
Code_7858:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_787A)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_787A)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7887)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7887)
	ld [wNoise42], a
	ret
Noise43_787A:
	db $10, $10, $20, $31, $32, $33, $33, $34
	db $34, $35, $35, $36, $FF
Noise42_7887:
	db $5C, $FF, $FF, $FF, $FF, $FF, $A1, $FF
	db $FF, $FF, $FF, $FF

; Unreferenced (1 bytes)
	db $FF
Code_7894:
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_78B6)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_78B6)
	ld [wNoise43], a
	ld a, HIGH(Noise42_78BC)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_78BC)
	ld [wNoise42], a
	ret
Noise43_78B6:
	db $00, $53, $71, $91, $31, $FF
Noise42_78BC:
	db $F1, $FF, $FF, $FF, $00
Code_78C1:
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
	ld a, HIGH(Noise43_78EC)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_78EC)
	ld [wNoise43], a
	ld a, HIGH(Noise42_78F2)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_78F2)
	ld [wNoise42], a
	ret
Noise43_78EC:
	db $03, $93, $80, $72, $70, $FF
Noise42_78F2:
	db $F0, $FF, $FF, $FF, $F3
Wave_78F7:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $00, $00, $00, $77, $77, $00, $00, $00
Wave_7907:
	db $01, $11, $11, $00, $89, $AA, $AA, $98
	db $01, $11, $11, $00, $FF, $FF, $FF, $FF
Wave_7917:
	db $A8, $42, $22, $8A, $EE, $EE, $EE, $EE
	db $A8, $42, $24, $8A, $EE, $EE, $EE, $EE

; Unreferenced (16 bytes)
	db $8C, $FE, $ED, $B8, $53, $21, $10, $24, $84, $01, $12, $35, $8B, $DE, $EF, $8C
Wave_7937:
	db $00, $16, $8A, $FF, $FF, $A8, $61, $00
	db $00, $16, $8A, $FF, $FF, $A8, $61, $00
Wave_7947:
	db $B7, $40, $F4, $7B, $FD, $FF, $FE, $DC
	db $02, $46, $8A, $BD, $FD, $BA, $6F, $20

; Unreferenced (32 bytes)
	db $32, $22, $11, $11, $11, $22, $23, $45, $FD, $CB, $A9, $87, $65, $43, $21, $10
	db $DD, $DB, $97, $52, $22, $54, $22, $22, $DD, $DC, $BD, $DD, $DB, $85, $22, $22
Wave_7977:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF

; Unreferenced (16 bytes)
	db $01, $11, $11, $00, $89, $AA, $AA, $98, $01, $11, $11, $00, $FF, $FF, $FF, $FF
Wave_7997:
	db $00, $00, $00, $00, $CD, $EF, $FD, $EC
	db $00, $12, $21, $00, $DD, $DD, $DD, $DD

; Unreferenced (16 bytes)
	db $00, $00, $00, $00, $00, $00, $FF, $FF, $00, $00, $00, $00, $00, $00, $FF, $FF
Wave_79B7:
	db $00, $00, $00, $00, $00, $00, $FF, $00
	db $00, $00, $00, $00, $00, $00, $FF, $00
Wave_79C7:
	db $00, $00, $00, $CD, $EF, $FF, $FF, $FF
	db $04, $8C, $FF, $FF, $FF, $FF, $FF, $FF
Wave_79D7:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $00, $FF, $FF, $FF
Wave_79E7:
	db $12, $34, $56, $78, $9A, $BC, $DE, $FF
	db $ED, $CB, $A9, $87, $65, $43, $21, $00
Wave_79F7:
	db $FF, $FE, $ED, $B8, $53, $21, $10, $00
	db $00, $01, $12, $35, $8B, $DE, $EF, $FF
Wave_7A07:
	db $63, $10, $00, $00, $00, $00, $01, $36
	db $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9
Wave_7A17:
	db $63, $10, $01, $47, $74, $10, $01, $36
	db $9C, $EF, $FE, $B8, $8B, $EF, $FE, $C9
Wave_7A27:
	db $63, $1F, $01, $47, $74, $10, $01, $36
	db $9C, $E0, $FE, $B8, $8B, $EF, $FE, $C9

; Unreferenced (32 bytes)
	db $65, $43, $22, $27, $72, $22, $22, $29, $AB, $CC, $BA, $98, $9C, $EE, $EE, $C9
	db $63, $20, $02, $47, $74, $22, $22, $36, $9C, $EF, $FE, $B6, $6B, $EE, $EE, $C9
Wave_7A57:
	db $B7, $40, $04, $7B, $CD, $FF, $FE, $DC
	db $02, $46, $8A, $BD, $FD, $BA, $64, $20

; Unreferenced (16 bytes)
	db $0F, $00, $F0, $F0, $F0, $F0, $00, $0F, $0F, $FF, $FF, $00, $FF, $F0, $0F, $0F
Wave_7A77:
	db $BB, $2B, $BB, $2B, $BB, $5B, $2B, $BB
	db $2B, $BB, $BB, $72, $27, $EB, $BB, $B0
Wave_7A87:
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $ED, $CB, $A9, $87, $65, $43, $21, $00
Wave_7A97:
	db $FE, $DB, $97, $53, $13, $54, $32, $10
	db $FE, $DC, $BC, $EF, $DB, $85, $32, $10
Wave_7AA7:
	db $54, $8B, $88, $88, $88, $86, $39, $87
	db $65, $44, $44, $32, $33, $24, $7A, $74
Wave_7AB7:
	db $04, $8B, $DE, $FF, $ED, $CB, $A9, $87
	db $65, $44, $44, $32, $11, $24, $7A, $74
Wave_7AC7:
	db $20, $13, $69, $BD, $FD, $B9, $64, $20
	db $13, $68, $B8, $64, $20, $24, $68, $64
Wave_7AD7:
	db $20, $24, $68, $AC, $EC, $A8, $64, $20
	db $24, $68, $A8, $64, $20, $24, $68, $64
Wave_7AE7:
	db $02, $48, $AC, $FF, $FC, $53, $00, $27
	db $9C, $DD, $DC, $B7, $7B, $CD, $DD, $C9

; Unreferenced (16 bytes)
	db $BD, $FF, $AC, $FF, $FC, $52, $00, $27, $9C, $DF, $DC, $B7, $7B, $CD, $AD, $C9
Noise43_7B07:
	db $01, $61, $71, $A1, $B1, $B1, $A1, $FF
Noise42_7B0F:
	db $C1, $F0, $A0, $90, $70, $40, $33
Noise43_7B16:
	db $06, $04, $03, $03, $07, $FF
Noise42_7B1C:
	db $F0, $C0, $80, $60, $55
Noise43_7B21:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_7B29:
	db $60, $30, $12, $FF, $FF, $FF, $FF
Noise43_7B30:
	db $04, $00, $00, $00, $00, $00, $00, $FF
Noise42_7B38:
	db $90, $53, $FF, $FF, $FF, $FF, $FF
Noise43_7B3F:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_7B47:
	db $70, $40, $40, $40, $40, $43, $FF

; Unreferenced (23 bytes)
	db $50, $41, $50, $51, $42, $53, $51, $FF, $F0, $70, $F0, $70, $D0, $70, $61, $3E
	db $08, $EA, $47, $DB, $CD, $8E, $49
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B07)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B07)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B0F)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B0F)
	ld [wNoise42], a
	ret
Drum8:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B9F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B9F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7BA5)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7BA5)
	ld [wNoise42], a
	ret
Noise43_7B9F:
	db $04, $02, $01, $00, $00, $FF
Noise42_7BA5:
	db $40, $60, $70, $82, $71
Drum2:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7BC7)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7BC7)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7BCF)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7BCF)
	ld [wNoise42], a
	ret
Noise43_7BC7:
	db $60, $52, $42, $41, $22, $11, $04, $FF
Noise42_7BCF:
	db $F0, $F0, $F0, $A0, $70, $40, $51
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B3F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B3F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B47)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B47)
	ld [wNoise42], a
	ret
Drum5:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B30)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B30)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B38)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B38)
	ld [wNoise42], a
	ret
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B21)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B21)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B29)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B29)
	ld [wNoise42], a
	ret
Drum7:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B16)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B16)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B1C)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B1C)
	ld [wNoise42], a
	ret
Drum9:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7C67)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7C67)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7C6A)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7C6A)
	ld [wNoise42], a
	ret
Noise43_7C67:
	db $51, $32, $FF
Noise42_7C6A:
	db $F0, $62
Drum10:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7CA6)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7CA6)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7CA9)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7CA9)
	ld [wNoise42], a
	ret
Drum11:
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
Noise43_7CA6:
	db $51, $32, $FF
Noise42_7CA9:
	db $70, $52
Noise43_7CAB:
	db $51, $32, $32, $32, $32, $51, $32, $FF
Noise42_7CB3:
	db $70, $51, $FF, $FF, $FF, $70, $51

; Unreferenced (57 bytes)
	db $44, $53, $62, $71, $62, $53, $44, $35, $26, $17, $26, $35, $6A, $77, $67, $57
	db $47, $37, $47, $57, $67, $77, $76, $75, $74, $73, $74, $75, $76, $6A, $00, $01
	db $02, $03, $04, $05, $06, $07, $17, $27, $36, $46, $55, $64, $73, $72, $71, $70
	db $60, $50, $40, $30, $20, $10, $00, $00, $6A
FadeOutTable:
	db $77, $66, $55, $44, $33, $22, $11, $00
	db FADE_END
FadeInTable:
	db $00, $11, $22, $33, $44, $55, $66, $77
	db FADE_END
	db "Final de la rutina de musica"

; Unreferenced (1 bytes)
	db $FF
	db "Final de la rutina de musica"

; Unreferenced (706 bytes)
	db $9A, $9D, $0F, $EF, $17, $A3, $86, $5B, $A3, $8E, $5B, $6A, $20, $9A, $9D, $0F
	db $EF, $17, $03, $C0, $8B, $16, $8C, $5B, $2B, $D0, $89, $16, $54, $0E, $8B, $C2
	db $A3, $62, $0E, $A3, $5A, $0E, $A1, $8E, $5B, $05, $7E, $FF, $A3, $52, $0E, $A3
	db $5C, $0E, $6A, $0F, $9A, $9D, $0F, $EF, $17, $A3, $92, $5B, $6A, $21, $9A, $9D
	db $0F, $EF, $17, $03, $C0, $8B, $16, $90, $5B, $03, $D2, $03, $C2, $03, $06, $92
	db $5B, $05, $FE, $FF, $8B, $16, $8E, $5B, $2B, $D0, $89, $16, $64, $0E, $33, $C0
	db $A3, $7E, $5B, $A3, $7C, $5B, $A1, $84, $5B, $48, $A3, $80, $5B, $A1, $86, $5B
	db $48, $A3, $82, $5B, $68, $D7, $30, $68, $7B, $0F, $68, $D7, $30, $68, $C0, $09
	db $66, $68, $00, $00, $CF, $02, $6A, $00, $6A, $00, $68, $00, $80, $68, $00, $80
	db $6A, $00, $6A, $00, $FF, $36, $9A, $5B, $66, $6A, $00, $9A, $F1, $07, $B7, $17
	db $A3, $2A, $0E, $EB, $35, $FF, $36, $2A, $0E, $68, $04, $28, $90, $0E, $E8, $F9
	db $F5, $83, $C4, $02, $52, $50, $68, $D7, $30, $68, $C0, $09, $6A, $35, $9A, $00
	db $00, $FF, $17, $3D, $02, $00, $75, $12, $6A, $01, $0E, $E8, $70, $FB, $83, $C4
	db $02, $33, $C0, $5F, $5E, $C9, $4D, $CA, $0A, $00, $FF, $36, $2A, $0E, $6A, $01
	db $6A, $28, $66, $6A, $00, $9A, $19, $00, $F7, $17, $0B, $C0, $74, $B7, $FF, $36
	db $2A, $0E, $16, $8D, $46, $F8, $50, $9A, $73, $10, $EF, $17, $8B, $46, $F8, $89
	db $46, $F0, $8B, $46, $FA, $89, $46, $F2, $8B, $46, $FC, $89, $46, $F4, $8B, $46
	db $FE, $89, $46, $F6, $16, $8D, $46, $E8, $50, $16, $8D, $46, $F0, $50, $9A, $E9
	db $22, $D7, $25, $83, $C4, $08, $16, $8D, $46, $E8, $50, $66, $0F, $B7, $06, $2A
	db $0E, $66, $50, $6A, $00, $6A, $00, $90, $0E, $E8, $C9, $46, $83, $C4, $0C, $89
	db $46, $E6, $83, $7E, $E6, $FF, $75, $08, $FF, $36, $2A, $0E, $6A, $03, $EB, $07
	db $FF, $36, $2A, $0E, $FF, $76, $E6, $9A, $1E, $15, $A7, $17, $66, $6A, $00, $66
	db $6A, $00, $6A, $00, $6A, $08, $90, $0E, $E8, $9A, $46, $83, $C4, $0C, $FF, $36
	db $2A, $0E, $9A, $BE, $0B, $DF, $17, $66, $83, $7E, $08, $00, $74, $11, $68, $D7
	db $30, $68, $60, $06, $FF, $76, $0A, $FF, $76, $08, $9A, $F2, $A9, $17, $01, $90
	db $0E, $E8, $36, $53, $9A, $42, $40, $57, $27, $89, $46, $E4, $6A, $01, $0E, $E8
	db $9C, $FA, $83, $C4, $02, $8B, $46, $E4, $5F, $5E, $C9, $4D, $CA, $0A, $00, $5F
	db $5E, $C9, $4D, $CA, $0A, $00, $8C, $D0, $90, $45, $55, $8B, $EC, $1E, $8E, $D8
	db $83, $EC, $04, $56, $57, $8B, $7E, $0E, $8B, $76, $0A, $8B, $46, $0C, $3D, $20
	db $00, $0F, $84, $97, $00, $7F, $45, $3D, $11, $00, $0F, $84, $5A, $03, $7F, $24
	db $3D, $05, $00, $0F, $84, $A0, $02, $7F, $11, $3D, $01, $00, $0F, $84, $02, $02
	db $3D, $02, $00, $0F, $84, $76, $03, $E9, $C6, $03, $3D, $10, $00, $0F, $84, $37
	db $03, $E9, $BC, $03, $3D, $16, $00, $0F, $84, $21, $03, $3D, $1A, $00, $0F, $84
	db $DC, $02, $3D, $1C, $00, $0F, $84, $7C, $01, $E9, $A4, $03, $3D, $13, $01, $74
	db $30, $7F, $16, $3D, $86, $00, $0F, $84, $AE, $01, $3D, $11, $01, $74, $53, $3D
	db $12, $01, $0F, $84, $08, $01, $E9, $87, $03, $3D, $1F, $01, $0F, $84, $44, $01
	db $3D, $0F, $03, $0F, $84, $8A, $02, $3D, $11, $03, $0F, $84, $94, $02, $E9, $6F
	db $03, $83, $3E, $48, $0E, $00, $75, $05, $90, $0E, $E8, $B5, $40, $33, $D2, $33
	db $C0, $5F, $5E, $8D, $66, $FE, $1F, $5D, $4D, $CA, $0A, $00, $66, $FF, $76, $06
	db $90, $0E, $E8, $BF, $19, $83, $C4, $04, $0B, $C0, $74, $03, $E9, $60, $01, $E9
	db $3E, $03, $83, $3E, $4C, $0E, $00, $74, $1B, $66, $8B, $46, $06, $66, $C1, $E8
	db $10, $3D, $01, $00, $75, $0E, $83, $7E, $06, $00, $75, $08, $33, $C0, $A3, $68
	db $0E, $A3, $4C, $0E, $66, $83, $3E, $1E, $0E, $00, $74, $2E, $81, $FE, $28, $23
	db $7D, $28, $83, $FE, $65, $7C, $23, $83, $3E, $04, $0E, $00, $75, $1C, $66, $FF
	db $76, $FF
