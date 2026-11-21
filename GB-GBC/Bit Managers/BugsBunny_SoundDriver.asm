; =====================================================================
; Bugs Bunny & Lola Bunny: Operation Carrots (E) (M6) [C] - Game Boy Color
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o bugs.o BugsBunny_SoundDriver.asm
;   rgblink -o bugs.gb bugs.o
;   python tools/cmp_banked.py bugs.gb "Bugs Bunny & Lola Bunny - Operation Carrots (E) (M6) [C][!].gbc" 2:4000-7FFF
; (driver and data fill ROM bank 2; the linked file only matches in that range)
;
; Documentation: BugsBunny_SoundDriver.md / AJG_SoundEngine_Family.md
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
	jp DrumPat_6F7A+21                  ; unused song slot: jumps into pattern data (never called)
	jp DrumPat_6F7A+21                  ; unused song slot: jumps into pattern data (never called)
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
	ld a, $70
	ld [wInstrTableHi], a
	ld a, $20
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

; Unreferenced (73 bytes)
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
	add a, $A4
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

; Song 1: instrument table 2, arpeggio table 1 (the one SndInit sets)
PlaySong1:
	jp Song1Routine

; Song 1 proper (PlaySong1 is a jp to the next instruction)
Song1Routine:
	call StopAll
	ld de, Song1_Ch3
	call StartMusicCh3
	ld de, Song1_Ch2
	call StartMusicCh2
	ld de, Song1_Ch1
	jp StartMusicCh1
Song1_Ch3:
	dw Pat_4BB6
	dw Pat_4BF2
	ORDER_LOOP Song1_Ch3
Song1_Ch2:
	dw Pat_4C38
	dw Pat_4C7D
	ORDER_LOOP Song1_Ch2
Song1_Ch1:
	dw Pat_4B53
	dw Pat_4B8D
	ORDER_LOOP Song1_Ch1
Pat_4B53:
	DRUMS $07, DrumPat_5137
	ARP 2
	HWENV $E1, $04, $83
	VIBRATO $00, $03, $04
	DUTY_12
	CH_TRANSPOSE $FE
	RELEASE $00
	LEN 21
	NOTE Dsh, 5
	LEN 14
	NOTE Dsh, 5
	LEN 7
	NOTE Dsh, 5
	LEN 21
	NOTE Dsh, 5
	LEN 14
	NOTE Dsh, 5
	LEN 7
	NOTE Dsh, 5
	LEN 14
	NOTE Dsh, 5
	LEN 7
	NOTE Dsh, 5
	LEN 21
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE Ash, 4
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE Ash, 4
	LEN 21
	NOTE Ash, 4
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE Ash, 4
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE Ash, 4
	LEN 21
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NEXT
Pat_4B8D:
	LEN 21
	NOTE F_, 4
	NOTE C_, 5
	LEN 35
	NOTE Ash, 4
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE F_, 4
	LEN 21
	NOTE C_, 5
	NOTE Ash, 4
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 21
	NOTE G_, 4
	NOTE C_, 5
	NOTE Ash, 4
	LEN 14
	NOTE G_, 4
	LEN 21
	NOTE Ash, 4
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE D_, 5
	LEN 7
	NOTE Ash, 4
	LEN 14
	NOTE C_, 5
	LEN 7
	NOTE D_, 5
	NEXT
Pat_4BB6:
	CH_TRANSPOSE $0C
	INSTR 11
	LEN 21
	NOTE Dsh, 2
	INSTR 4
	LEN 14
	NOTE Dsh, 4
	INSTR 11
	LEN 7
	NOTE Dsh, 2
	LEN 21
	NOTE Ash, 2
	INSTR 4
	LEN 14
	NOTE Dsh, 4
	INSTR 11
	LEN 7
	NOTE Ash, 2
	LEN 21
	NOTE Dsh, 2
	INSTR 4
	LEN 14
	NOTE Dsh, 4
	INSTR 11
	LEN 7
	NOTE Dsh, 2
	LEN 21
	NOTE G_, 2
	NOTE Gsh, 2
	NOTE Ash, 2
	INSTR 4
	LEN 14
	NOTE Ash, 3
	INSTR 11
	LEN 7
	NOTE Ash, 2
	LEN 21
	NOTE F_, 2
	INSTR 4
	LEN 14
	NOTE Ash, 3
	INSTR 11
	LEN 7
	NOTE F_, 2
	LEN 21
	NOTE Ash, 2
	INSTR 4
	LEN 14
	NOTE Ash, 3
	INSTR 11
	LEN 7
	NOTE Ash, 2
	LEN 21
	NOTE F_, 2
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE Gsh, 2
	NEXT
Pat_4BF2:
	INSTR 11
	LEN 21
	NOTE Ash, 2
	INSTR 4
	LEN 14
	NOTE Ash, 3
	INSTR 11
	LEN 7
	NOTE Ash, 2
	LEN 21
	NOTE F_, 2
	INSTR 4
	LEN 14
	NOTE Ash, 3
	INSTR 11
	LEN 7
	NOTE F_, 2
	LEN 21
	NOTE Ash, 2
	INSTR 4
	LEN 14
	NOTE Ash, 3
	INSTR 11
	LEN 7
	NOTE Ash, 2
	LEN 14
	NOTE F_, 2
	INSTR 4
	LEN 7
	NOTE Ash, 3
	INSTR 11
	LEN 14
	NOTE G_, 2
	INSTR 4
	LEN 7
	NOTE Ash, 3
	INSTR 11
	LEN 21
	NOTE Dsh, 2
	INSTR 4
	LEN 14
	NOTE Dsh, 4
	INSTR 11
	LEN 7
	NOTE Dsh, 2
	LEN 21
	NOTE Ash, 2
	INSTR 4
	LEN 14
	NOTE Dsh, 4
	INSTR 11
	LEN 21
	NOTE Ash, 2
	LEN 7
	NOTE Ash, 2
	INSTR 4
	LEN 14
	NOTE Ash, 3
	INSTR 11
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
	NEXT
Pat_4C38:
	VIBRATO $00, $03, $04
	INSTR 9
	LEN 14
	NOTE Dsh, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE Dsh, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE Dsh, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE Dsh, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE D_, 4
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NEXT
Pat_4C7D:
	INSTR 9
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE Gsh, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE Dsh, 3
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE Dsh, 3
	LEN 21
	NOTE Ash, 3
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE Ash, 3
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE D_, 4
	NEXT

; Song 2 (the long version of song 1: its order lists start with song 1's two patterns per
; channel, then continue with new ones). Reached only through the jp at PlaySong2 ($513F),
; which sits after song 2's data, just before song 3; the instrument table is StopAll's.
Song2Routine:
	call StopAll
	ld de, Song2_Ch3
	call StartMusicCh3
	ld de, Song2_Ch2
	call StartMusicCh2
	ld de, Song2_Ch1
	jp StartMusicCh1
Song2_Ch3:
	dw Pat_4BB6
	dw Pat_4BF2
	dw Pat_4BB6
	dw Pat_4D36
	dw Pat_4D8E
	dw Pat_4D8E
	dw Pat_4BB6
	dw Pat_4BF2
	dw Pat_4BB6
	dw Pat_4D36
	dw Pat_4D8E
	dw Pat_4D8E
	ORDER_LOOP Song2_Ch3
Song2_Ch2:
	dw Pat_4C38
	dw Pat_4C7D
	dw Pat_4C38
	dw Pat_4DEE
	dw Pat_4E30
	dw Pat_4E72
	dw Pat_4E30
	dw Pat_4E72
	dw Pat_4EB4
	dw Pat_4F5C
	dw Pat_4F08
	dw Pat_4FA8
	dw Pat_4E30
	dw Pat_4E72
	dw Pat_4E30
	dw Pat_4E72
	ORDER_LOOP Song2_Ch2
Song2_Ch1:
	dw Pat_4B53
	dw Pat_4B8D
	dw Pat_4B53
	dw Pat_4FFB
	dw Pat_5018
	dw Pat_507A
	dw Pat_5018
	dw Pat_5087
	dw Pat_5094
	dw Pat_50C7
	dw Pat_50F1
	dw Pat_5119
	dw Pat_5018
	dw Pat_507A
	dw Pat_5018
	dw Pat_5087
	ORDER_LOOP Song2_Ch1
Pat_4D36:
	INSTR 11
	LEN 21
	NOTE Ash, 2
	INSTR 4
	LEN 14
	NOTE Ash, 3
	INSTR 11
	LEN 7
	NOTE Ash, 2
	LEN 21
	NOTE F_, 2
	INSTR 4
	LEN 14
	NOTE Ash, 3
	INSTR 11
	LEN 7
	NOTE F_, 2
	LEN 21
	NOTE Ash, 2
	INSTR 4
	LEN 14
	NOTE Ash, 3
	INSTR 11
	LEN 7
	NOTE Ash, 2
	LEN 14
	NOTE F_, 2
	INSTR 4
	LEN 7
	NOTE Ash, 3
	INSTR 11
	LEN 14
	NOTE G_, 2
	INSTR 4
	LEN 7
	NOTE Ash, 3
	INSTR 11
	LEN 21
	NOTE Dsh, 2
	INSTR 4
	LEN 14
	NOTE Dsh, 4
	INSTR 11
	LEN 7
	NOTE Dsh, 2
	LEN 21
	NOTE Ash, 2
	INSTR 4
	LEN 14
	NOTE Dsh, 4
	INSTR 11
	LEN 7
	NOTE Ash, 2
	LEN 14
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 3
	LEN 21
	NOTE Dsh, 2
	NOTE F_, 2
	NOTE Fsh, 2
	NEXT
Pat_4D74:
	INSTR 11
	LEN 21
	NOTE G_, 2
	INSTR 4
	LEN 14
	NOTE G_, 3
	INSTR 11
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE D_, 2
	INSTR 4
	LEN 14
	NOTE G_, 3
	INSTR 11
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE C_, 3
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE C_, 3
	NEXT
Pat_4D8E:
	PAT_CALL Pat_4D74
	LEN 21
	NOTE G_, 2
	INSTR 5
	LEN 14
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE Fsh, 2
	LEN 21
	NOTE F_, 2
	INSTR 4
	LEN 14
	NOTE F_, 3
	INSTR 11
	LEN 7
	NOTE F_, 2
	LEN 21
	NOTE C_, 2
	INSTR 4
	LEN 14
	NOTE F_, 3
	INSTR 11
	LEN 7
	NOTE F_, 2
	LEN 21
	NOTE Ash, 2
	INSTR 4
	LEN 14
	NOTE Ash, 3
	INSTR 11
	LEN 7
	NOTE Ash, 2
	LEN 21
	NOTE F_, 2
	INSTR 4
	LEN 14
	NOTE Ash, 3
	INSTR 11
	LEN 7
	NOTE F_, 2
	PAT_CALL Pat_4D74
	LEN 14
	NOTE G_, 2
	INSTR 5
	LEN 7
	NOTE C_, 4
	INSTR 11
	LEN 14
	NOTE Fsh, 2
	INSTR 5
	LEN 7
	NOTE C_, 4
	INSTR 11
	LEN 21
	NOTE F_, 2
	INSTR 4
	LEN 14
	NOTE F_, 4
	INSTR 11
	LEN 7
	NOTE F_, 2
	LEN 21
	NOTE C_, 3
	INSTR 4
	LEN 14
	NOTE F_, 4
	INSTR 11
	LEN 7
	NOTE C_, 3
	LEN 14
	NOTE Ash, 2
	INSTR 4
	LEN 7
	NOTE Ash, 4
	INSTR 11
	LEN 14
	NOTE F_, 2
	INSTR 4
	LEN 7
	NOTE Ash, 4
	INSTR 11
	LEN 14
	NOTE Ash, 2
	INSTR 4
	LEN 7
	NOTE Ash, 4
	INSTR 11
	NOTE F_, 2
	NOTE G_, 2
	NOTE F_, 2
	NEXT
Pat_4DEE:
	INSTR 9
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE Gsh, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE Dsh, 3
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE Dsh, 3
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 3
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE Fsh, 3
	LEN 7
	NOTE Fsh, 4
	NEXT
Pat_4E30:
	INSTR 9
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE D_, 3
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE D_, 3
	LEN 14
	NOTE D_, 3
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE Fsh, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE C_, 3
	LEN 7
	NOTE A_, 3
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE C_, 3
	LEN 14
	NOTE C_, 3
	LEN 7
	NOTE A_, 3
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE Ash, 3
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE Ash, 3
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE Fsh, 4
	LEN 7
	NOTE G_, 4
	NEXT
Pat_4E72:
	INSTR 9
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE D_, 3
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE D_, 3
	LEN 14
	NOTE D_, 3
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE A_, 3
	LEN 7
	NOTE A_, 3
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE B_, 3
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE Gsh, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE F_, 3
	NEXT
Pat_4EB4:
	INSTR 14
	LEN 14
	NOTE G_, 5
	INSTR 9
	LEN 7
	NOTE G_, 3
	INSTR 14
	LEN 14
	NOTE G_, 5
	LEN 7
	NOTE G_, 5
	LEN 14
	NOTE G_, 5
	INSTR 9
	LEN 7
	NOTE G_, 3
	INSTR 14
	LEN 14
	NOTE G_, 5
	LEN 7
	NOTE G_, 5
	LEN 14
	NOTE G_, 5
	LEN 7
	NOTE Gsh, 5
	LEN 14
	NOTE G_, 5
	INSTR 9
	LEN 7
	NOTE G_, 3
	INSTR 14
	LEN 14
	NOTE F_, 5
	INSTR 9
	LEN 7
	NOTE G_, 3
	INSTR 14
	LEN 14
	NOTE Dsh, 5
	INSTR 9
	LEN 7
	NOTE G_, 3
	INSTR 14
	LEN 14
	NOTE D_, 5
	INSTR 9
	LEN 7
	NOTE D_, 4
	INSTR 14
	LEN 14
	NOTE D_, 5
	LEN 7
	NOTE D_, 5
	LEN 14
	NOTE D_, 5
	INSTR 9
	LEN 7
	NOTE D_, 4
	INSTR 14
	LEN 14
	NOTE D_, 5
	LEN 7
	NOTE D_, 5
	LEN 14
	NOTE D_, 5
	LEN 7
	NOTE Dsh, 5
	LEN 14
	NOTE D_, 5
	INSTR 9
	LEN 7
	NOTE D_, 4
	INSTR 14
	LEN 14
	NOTE C_, 5
	INSTR 9
	LEN 7
	NOTE D_, 4
	INSTR 14
	NOTE Ash, 4
	INSTR 9
	NOTE G_, 3
	NOTE Gsh, 3
	NEXT
Pat_4F08:
	INSTR 14
	LEN 14
	NOTE Dsh, 5
	INSTR 9
	LEN 7
	NOTE G_, 3
	INSTR 14
	LEN 14
	NOTE Dsh, 5
	LEN 7
	NOTE Dsh, 5
	LEN 14
	NOTE Dsh, 5
	INSTR 9
	LEN 7
	NOTE G_, 3
	INSTR 14
	LEN 14
	NOTE Dsh, 5
	LEN 7
	NOTE Dsh, 5
	LEN 14
	NOTE Dsh, 5
	LEN 7
	NOTE Dsh, 5
	LEN 14
	NOTE Dsh, 5
	INSTR 9
	LEN 7
	NOTE G_, 3
	INSTR 14
	LEN 14
	NOTE C_, 5
	INSTR 9
	LEN 7
	NOTE G_, 3
	INSTR 14
	LEN 14
	NOTE Csh, 5
	INSTR 9
	LEN 7
	NOTE G_, 3
	INSTR 14
	LEN 14
	NOTE D_, 5
	INSTR 9
	LEN 7
	NOTE D_, 4
	INSTR 14
	LEN 14
	NOTE D_, 5
	LEN 7
	NOTE D_, 5
	LEN 14
	NOTE D_, 5
	INSTR 9
	LEN 7
	NOTE D_, 4
	INSTR 14
	LEN 14
	NOTE D_, 5
	LEN 7
	NOTE D_, 5
	LEN 14
	NOTE D_, 5
	LEN 7
	NOTE D_, 5
	LEN 14
	NOTE D_, 5
	INSTR 9
	LEN 7
	NOTE D_, 4
	INSTR 14
	LEN 14
	NOTE Dsh, 5
	INSTR 9
	LEN 7
	NOTE D_, 4
	INSTR 14
	NOTE E_, 5
	INSTR 9
	NOTE G_, 3
	NOTE Gsh, 3
	NEXT
Pat_4F5C:
	INSTR 14
	LEN 14
	NOTE Gsh, 4
	INSTR 9
	LEN 7
	NOTE D_, 4
	INSTR 14
	LEN 14
	NOTE Dsh, 5
	INSTR 9
	LEN 7
	NOTE D_, 4
	INSTR 14
	LEN 14
	NOTE D_, 5
	INSTR 9
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE F_, 3
	INSTR 14
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE Gsh, 4
	LEN 7
	NOTE Dsh, 5
	INSTR 9
	LEN 14
	NOTE F_, 3
	INSTR 14
	LEN 7
	NOTE D_, 5
	INSTR 9
	LEN 14
	NOTE Ash, 3
	INSTR 14
	LEN 7
	NOTE D_, 5
	LEN 14
	NOTE Dsh, 5
	LEN 7
	NOTE F_, 5
	LEN 14
	NOTE G_, 5
	INSTR 9
	LEN 7
	NOTE C_, 4
	INSTR 14
	LEN 14
	NOTE G_, 5
	INSTR 9
	LEN 7
	NOTE C_, 4
	INSTR 14
	LEN 14
	NOTE G_, 5
	LEN 7
	NOTE G_, 5
	LEN 21
	NOTE G_, 5
	LEN 14
	NOTE G_, 5
	LEN 7
	NOTE Gsh, 5
	LEN 14
	NOTE G_, 5
	LEN 21
	NOTE F_, 5
	LEN 7
	NOTE Dsh, 5
	LEN 14
	NOTE D_, 5
	LEN 7
	NOTE F_, 5
	NEXT
Pat_4FA8:
	INSTR 14
	LEN 14
	NOTE D_, 5
	INSTR 9
	LEN 7
	NOTE D_, 4
	INSTR 14
	LEN 14
	NOTE D_, 5
	LEN 7
	NOTE D_, 5
	LEN 14
	NOTE D_, 5
	INSTR 9
	LEN 7
	NOTE D_, 4
	INSTR 14
	LEN 14
	NOTE D_, 5
	LEN 7
	NOTE D_, 5
	LEN 14
	NOTE D_, 5
	LEN 7
	NOTE D_, 5
	LEN 14
	NOTE D_, 5
	INSTR 9
	LEN 7
	NOTE D_, 4
	INSTR 14
	LEN 14
	NOTE Dsh, 5
	INSTR 9
	LEN 7
	NOTE Gsh, 3
	INSTR 14
	LEN 14
	NOTE D_, 5
	INSTR 9
	LEN 7
	NOTE F_, 3
	INSTR 14
	LEN 14
	NOTE G_, 4
	INSTR 9
	LEN 7
	NOTE C_, 4
	INSTR 14
	LEN 14
	NOTE G_, 4
	INSTR 9
	LEN 7
	NOTE C_, 4
	INSTR 14
	LEN 14
	NOTE Gsh, 4
	LEN 7
	NOTE Gsh, 4
	INSTR 9
	LEN 14
	NOTE Ash, 3
	INSTR 14
	LEN 7
	NOTE G_, 4
	INSTR 9
	LEN 14
	NOTE Dsh, 3
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 3
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE Fsh, 3
	LEN 7
	NOTE Fsh, 4
	NEXT
Pat_4FFB:
	LEN 21
	NOTE F_, 4
	NOTE C_, 5
	LEN 35
	NOTE Ash, 4
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE F_, 4
	LEN 21
	NOTE C_, 5
	NOTE Ash, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE F_, 4
	LEN 21
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 21
	NOTE Dsh, 4
	LENGTH $5B
	NOTE Dsh, 4
	NEXT
Pat_5018:
	LEN 21
	WAIT
	HWENV $A0, $00
	DUTY_50
	RELEASE $02, $62
	LEN 14
	NOTE B_, 4
	LEN 7
	WAIT2
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE B_, 4
	LEN 7
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE C_, 5
	LEN 14
	WAIT2
	LENGTH $31
	NOTE G_, 4
	LEN 21
	WAIT2
	LEN 14
	NOTE A_, 4
	LEN 7
	WAIT2
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE A_, 4
	LEN 7
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE Ash, 4
	LEN 14
	WAIT2
	LEN 42
	NOTE F_, 4
	LEN 7
	WAIT2
	NEXT
Pat_504D:
	LEN 21
	WAIT
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE C_, 5
	NOTE D_, 5
	WAIT2
	NOTE C_, 5
	NOTE B_, 4
	WAIT2
	LEN 21
	NOTE C_, 5
	LEN 7
	WAIT2
	LEN 14
	NOTE G_, 4
	LEN 7
	WAIT2
	LEN 14
	NOTE Dsh, 5
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE F_, 5
	LEN 7
	WAIT2
	LEN 14
	NOTE Dsh, 5
	LEN 7
	WAIT2
	LEN 14
	NOTE D_, 5
	LEN 7
	WAIT2
	LEN 14
	NOTE C_, 5
	LEN 7
	WAIT2
	LEN 14
	NEXT
Pat_507A:
	PAT_CALL Pat_504D
	NOTE Ash, 4
	LEN 7
	NOTE C_, 5
	NOTE Ash, 4
	WAIT2
	LEN 42
	NOTE F_, 4
	LEN 7
	WAIT2
	NEXT
Pat_5087:
	PAT_CALL Pat_504D
	NOTE D_, 5
	LEN 7
	NOTE Dsh, 5
	NOTE E_, 5
	WAIT2
	LEN 35
	NOTE F_, 5
	LEN 14
	WAIT2
	NEXT
Pat_5094:
	HWENV $E1, $04, $83
	VIBRATO $00, $03, $04
	DUTY_12
	RELEASE $00
	LEN 21
	NOTE Dsh, 5
	LEN 14
	NOTE Dsh, 5
	LEN 7
	NOTE Dsh, 5
	LEN 21
	NOTE Dsh, 5
	LEN 14
	NOTE Dsh, 5
	LEN 7
	NOTE Dsh, 5
	LEN 14
	NOTE Dsh, 5
	LEN 7
	NOTE F_, 5
	LEN 21
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE Ash, 4
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE Ash, 4
	LEN 21
	NOTE Ash, 4
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE Ash, 4
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE C_, 5
	LEN 21
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NEXT
Pat_50C7:
	LEN 21
	NOTE F_, 4
	NOTE C_, 5
	LEN 35
	NOTE Ash, 4
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE F_, 4
	LEN 21
	NOTE C_, 5
	NOTE Ash, 4
	LEN 7
	NOTE Ash, 4
	LEN 14
	NOTE C_, 5
	LEN 7
	NOTE D_, 5
	LEN 21
	NOTE Dsh, 5
	NOTE Dsh, 5
	LEN 14
	NOTE Dsh, 5
	LEN 7
	NOTE Dsh, 5
	LEN 21
	NOTE Dsh, 5
	LEN 14
	NOTE Dsh, 5
	LEN 7
	NOTE F_, 5
	LEN 14
	NOTE Dsh, 5
	LEN 21
	NOTE D_, 5
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE Gsh, 4
	NEXT
Pat_50F1:
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
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 21
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE Ash, 4
	LEN 21
	NOTE Ash, 4
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE Ash, 4
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE Ash, 4
	LEN 21
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	NEXT
Pat_5119:
	LEN 21
	NOTE F_, 5
	LEN 14
	NOTE F_, 5
	LEN 7
	NOTE F_, 5
	LEN 21
	NOTE F_, 5
	LEN 14
	NOTE F_, 5
	LEN 7
	NOTE F_, 5
	LEN 14
	NOTE F_, 5
	LEN 7
	NOTE F_, 5
	LEN 21
	NOTE F_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE Dsh, 5
	LEN 14
	NOTE Dsh, 5
	LEN 21
	NOTE Dsh, 5
	LENGTH $5B
	NOTE Dsh, 5
	NEXT
DrumPat_5137:
	db DRUM_LEVEL + 12, 1, 0, 6, 9, 0, 6, DRUM_LOOP

; Song 2: instrument table 2, arpeggio table 1 (the one SndInit sets)
PlaySong2:
	jp Song2Routine

; Song 3: instrument table 2, arpeggio table 1 (the one SndInit sets)
PlaySong3:
	call StopAll
	ld de, Song3_Ch3
	call StartMusicCh3
	ld de, Song3_Ch2
	call StartMusicCh2
	ld de, Song3_Ch1
	jp StartMusicCh1
Song3_Ch3:
	dw Pat_5187
	dw Pat_51EA
	dw Pat_5187
	dw Pat_51F9
	dw Pat_5208
	dw Pat_523D
	ORDER_LOOP Song3_Ch3
Song3_Ch2:
	dw Pat_5278
	dw Pat_52AA
	dw Pat_5278
	dw Pat_52E6
	dw Pat_52FA
	dw Pat_5327
	ORDER_LOOP Song3_Ch2
Song3_Ch1:
	dw Pat_5363
	dw Pat_53B1
	dw Pat_5363
	dw Pat_53BC
	dw Pat_53C9
	dw Pat_53F0
	ORDER_LOOP Song3_Ch1
Pat_5187:
	CH_TRANSPOSE $0C
	TRANSPOSE $FE
	DRUMS $06, DrumPat_5414
	INSTR 11
	LEN 12
	NOTE D_, 2
	INSTR 4
	NOTE D_, 4
	INSTR 11
	NOTE A_, 2
	INSTR 4
	NOTE D_, 4
	INSTR 11
	NOTE D_, 2
	INSTR 4
	NOTE D_, 4
	INSTR 11
	NOTE A_, 2
	INSTR 4
	LEN 6
	NOTE D_, 4
	INSTR 11
	NOTE A_, 2
	DRUMS_OFF
	CALL_CODE Drum7
	LENGTH $60
	NOTE D_, 2
	LEN 12
	DRUMS $06, DrumPat_5414
	REPEAT 4
	INSTR 11
	NOTE A_, 2
	INSTR 4
	NOTE A_, 4
	INSTR 11
	NOTE E_, 2
	INSTR 4
	NOTE A_, 4
	REPEAT_END
	NEXT
Pat_51BA:
	LEN 12
	INSTR 11
	NOTE A_, 2
	INSTR 4
	NOTE A_, 4
	INSTR 11
	NOTE E_, 2
	INSTR 4
	NOTE A_, 4
	INSTR 11
	NOTE A_, 2
	INSTR 4
	NOTE A_, 4
	INSTR 11
	NOTE E_, 2
	INSTR 4
	LEN 6
	NOTE A_, 4
	INSTR 11
	NOTE E_, 2
	DRUMS_OFF
	CALL_CODE Drum7
	LENGTH $60
	NOTE A_, 2
	LEN 12
	DRUMS $06, DrumPat_5414
	REPEAT 2
	INSTR 11
	NOTE D_, 2
	INSTR 4
	NOTE D_, 4
	INSTR 11
	NOTE A_, 2
	INSTR 4
	NOTE D_, 4
	REPEAT_END
	INSTR 11
	NOTE A_, 2
	INSTR 4
	NOTE A_, 4
	INSTR 11
	NEXT
Pat_51EA:
	PAT_CALL Pat_51BA
	NOTE G_, 2
	INSTR 4
	NOTE A_, 4
	INSTR 11
	NOTE Fsh, 2
	INSTR 4
	NOTE A_, 4
	INSTR 11
	NOTE E_, 2
	INSTR 4
	NOTE A_, 4
	NEXT
Pat_51F9:
	PAT_CALL Pat_51BA
	NOTE E_, 2
	INSTR 4
	NOTE A_, 4
	INSTR 11
	NOTE A_, 2
	INSTR 4
	NOTE A_, 4
	INSTR 11
	NOTE E_, 2
	INSTR 4
	NOTE A_, 4
	NEXT
Pat_5208:
	INSTR 11
	LEN 12
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 11
	NOTE D_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 11
	NOTE D_, 2
	INSTR 4
	LEN 6
	NOTE G_, 4
	INSTR 11
	NOTE D_, 2
	DRUMS_OFF
	CALL_CODE Drum7
	LENGTH $60
	NOTE G_, 2
	LEN 12
	DRUMS $06, DrumPat_5414
	REPEAT 2
	INSTR 11
	NOTE D_, 2
	INSTR 4
	NOTE D_, 4
	INSTR 11
	NOTE A_, 2
	INSTR 4
	NOTE D_, 4
	REPEAT_END
	REPEAT 2
	INSTR 11
	NOTE B_, 2
	INSTR 5
	NOTE B_, 4
	INSTR 11
	NOTE Fsh, 2
	INSTR 5
	NOTE B_, 4
	REPEAT_END
	NEXT
Pat_523D:
	INSTR 11
	LEN 12
	NOTE A_, 2
	INSTR 4
	NOTE A_, 4
	INSTR 11
	NOTE E_, 2
	INSTR 4
	NOTE A_, 4
	INSTR 11
	NOTE A_, 2
	INSTR 4
	NOTE A_, 4
	INSTR 11
	NOTE E_, 2
	INSTR 4
	LEN 6
	NOTE A_, 4
	INSTR 11
	NOTE E_, 2
	DRUMS_OFF
	CALL_CODE Drum7
	LENGTH $60
	NOTE A_, 2
	LEN 12
	DRUMS $06, DrumPat_5414
	REPEAT 2
	INSTR 11
	NOTE D_, 2
	INSTR 4
	NOTE D_, 4
	INSTR 11
	NOTE A_, 2
	INSTR 4
	NOTE D_, 4
	REPEAT_END
	INSTR 11
	NOTE A_, 2
	INSTR 4
	NOTE A_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 4
	NOTE A_, 4
	INSTR 11
	NOTE Fsh, 2
	INSTR 4
	NOTE A_, 4
	INSTR 11
	NOTE E_, 2
	INSTR 4
	NOTE A_, 4
	NEXT
Pat_5278:
	INSTR 13
	LEN 12
	NOTE A_, 4
	LEN 6
	NOTE Fsh, 4
	LEN 18
	WAIT2
	INSTR 9
	LEN 6
	NOTE D_, 6
	NOTE A_, 5
	LEN 24
	NOTE Fsh, 5
	INSTR 13
	LEN 6
	NOTE A_, 3
	LEN 12
	WAIT2
	LEN 6
	NOTE A_, 3
	NOTE D_, 4
	WAIT2
	LEN 12
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	LEN 24
	NOTE B_, 4
	NOTE A_, 4
	LEN 12
	NOTE Csh, 5
	NOTE B_, 4
	NOTE Ash, 4
	LEN 6
	NOTE A_, 4
	LEN 18
	WAIT2
	LEN 12
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	WAIT2
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE Csh, 4
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NEXT
Pat_52AA:
	PAT_CALL Pat_52BF
	NOTE A_, 4
	LEN 6
	NOTE B_, 4
	NOTE A_, 4
	LEN 12
	NOTE G_, 4
	LEN 6
	NOTE A_, 4
	NOTE G_, 4
	LEN 12
	NOTE Fsh, 4
	LEN 6
	NOTE G_, 4
	NOTE Fsh, 4
	LEN 12
	NOTE E_, 4
	NOTE A_, 3
	NEXT
Pat_52BF:
	INSTR 13
	LEN 12
	NOTE A_, 4
	LEN 6
	NOTE G_, 4
	LEN 18
	WAIT2
	INSTR 9
	LEN 6
	NOTE Csh, 6
	NOTE A_, 5
	LEN 24
	NOTE E_, 5
	INSTR 13
	LEN 6
	NOTE A_, 3
	LEN 12
	WAIT2
	LEN 6
	NOTE A_, 3
	NOTE E_, 4
	WAIT2
	LEN 12
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	LEN 24
	NOTE B_, 4
	NOTE A_, 4
	LEN 12
	NOTE D_, 5
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	WAIT2
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NEXT
Pat_52E6:
	PAT_CALL Pat_52BF
	LEN 6
	NOTE A_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE Csh, 5
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE E_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Csh, 5
	LEN 12
	NOTE A_, 5
	NOTE D_, 4
	NEXT
Pat_52FA:
	INSTR 13
	LEN 12
	NOTE D_, 5
	LEN 6
	NOTE B_, 4
	LEN 18
	WAIT2
	INSTR 9
	LEN 6
	NOTE D_, 6
	NOTE B_, 5
	LEN 24
	NOTE G_, 5
	INSTR 13
	LEN 6
	NOTE D_, 4
	LEN 12
	WAIT2
	LEN 6
	NOTE D_, 4
	NOTE G_, 4
	WAIT2
	LEN 12
	NOTE D_, 5
	NOTE Csh, 5
	NOTE D_, 5
	LEN 24
	NOTE E_, 5
	NOTE D_, 5
	LEN 12
	NOTE Fsh, 5
	LEN 6
	NOTE D_, 5
	LEN 42
	WAIT2
	LEN 12
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	LEN 24
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NEXT
Pat_5327:
	INSTR 13
	LEN 12
	NOTE A_, 4
	LEN 6
	NOTE Csh, 4
	LEN 18
	WAIT2
	INSTR 9
	LEN 6
	NOTE Csh, 6
	NOTE B_, 5
	LEN 24
	NOTE A_, 5
	INSTR 13
	LEN 6
	NOTE A_, 3
	LEN 12
	WAIT2
	LEN 6
	NOTE A_, 3
	NOTE E_, 4
	WAIT2
	LEN 12
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE A_, 3
	NOTE Fsh, 4
	NOTE E_, 4
	LENGTH $36
	NOTE D_, 4
	LEN 6
	NOTE D_, 4
	NOTE Csh, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 12
	NOTE A_, 4
	LEN 6
	NOTE B_, 4
	NOTE A_, 4
	LEN 12
	NOTE G_, 4
	LEN 6
	NOTE A_, 4
	NOTE G_, 4
	LEN 12
	NOTE Fsh, 4
	LEN 6
	NOTE G_, 4
	NOTE Fsh, 4
	LEN 12
	NOTE E_, 4
	NOTE A_, 3
	NEXT
Pat_5363:
	INSTR 6
	ARP_OFF
	LEN 12
	NOTE A_, 5
	LEN 24
	NOTE Fsh, 5
	INSTR 9
	LEN 6
	NOTE A_, 5
	NOTE Fsh, 5
	LEN 24
	NOTE D_, 5
	INSTR 6
	ARP_OFF
	LEN 18
	NOTE A_, 4
	LEN 6
	NOTE A_, 4
	LEN 12
	NOTE D_, 5
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	LEN 24
	NOTE B_, 5
	NOTE A_, 5
	LEN 12
	NOTE A_, 5
	NOTE G_, 5
	NOTE E_, 5
	LEN 24
	NOTE Csh, 5
	LEN 12
	NOTE A_, 4
	NOTE Gsh, 4
	LEN 24
	NOTE A_, 4
	LEN 12
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE Csh, 5
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NEXT
Pat_5391:
	LEN 12
	NOTE A_, 5
	LEN 24
	NOTE G_, 5
	INSTR 9
	LEN 6
	NOTE E_, 6
	NOTE Csh, 6
	LEN 24
	NOTE A_, 5
	INSTR 6
	ARP_OFF
	LEN 18
	NOTE A_, 4
	LEN 6
	NOTE A_, 4
	LEN 12
	NOTE E_, 5
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	LEN 24
	NOTE B_, 5
	NOTE A_, 5
	LEN 12
	NOTE A_, 5
	NOTE Fsh, 5
	NOTE D_, 5
	LENGTH $3C
	NOTE A_, 4
	NEXT
Pat_53B1:
	PAT_CALL Pat_5391
	LEN 24
	NOTE Csh, 5
	NOTE D_, 5
	NOTE Dsh, 5
	LEN 12
	NOTE E_, 5
	NOTE A_, 4
	NEXT
Pat_53BC:
	PAT_CALL Pat_5391
	LEN 12
	NOTE E_, 5
	NOTE Csh, 5
	NOTE A_, 5
	NOTE E_, 5
	NOTE Csh, 6
	NOTE A_, 5
	NOTE A_, 6
	NOTE D_, 5
	NEXT
Pat_53C9:
	LEN 12
	NOTE D_, 6
	LEN 24
	NOTE B_, 5
	INSTR 9
	LEN 6
	NOTE B_, 5
	NOTE G_, 5
	LEN 24
	NOTE D_, 5
	INSTR 6
	ARP_OFF
	LEN 18
	NOTE D_, 5
	LEN 6
	NOTE D_, 5
	LEN 12
	NOTE G_, 5
	NOTE D_, 6
	NOTE Csh, 6
	NOTE D_, 6
	LEN 24
	NOTE E_, 6
	NOTE D_, 6
	LEN 12
	NOTE D_, 6
	LENGTH $30
	NOTE A_, 5
	LEN 12
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	LEN 24
	NOTE B_, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE Fsh, 5
	NEXT
Pat_53F0:
	LEN 12
	NOTE A_, 5
	LEN 24
	NOTE G_, 5
	INSTR 9
	LEN 6
	NOTE A_, 5
	NOTE G_, 5
	LEN 24
	NOTE E_, 5
	INSTR 6
	ARP_OFF
	LEN 18
	NOTE A_, 4
	LEN 6
	NOTE A_, 4
	LEN 12
	NOTE E_, 5
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE Fsh, 5
	NOTE E_, 5
	LENGTH $60
	NOTE D_, 5
	LEN 24
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	LEN 12
	NOTE Csh, 5
	NOTE A_, 4
	NEXT
DrumPat_5414:
	db DRUM_LEVEL + 14, 1, 0, 5, 6, 9, 0, 5
	db 6, DRUM_LOOP

; Song 4: instrument table 2, arpeggio table 1 (the one SndInit sets)
PlaySong4:
	call StopAll
	ld de, Song4_Ch3
	call StartMusicCh3
	ld de, Song4_Ch2
	call StartMusicCh2
	ld de, Song4_Ch1
	jp StartMusicCh1
Song4_Ch3:
	dw Pat_5439
Song4_Ch2:
	dw Pat_5483
Song4_Ch1:
	dw Pat_54F7
Pat_5439:
	CH_TRANSPOSE $0C
	LEN 12
	REPEAT 2
	INSTR 11
	NOTE Csh, 3
	INSTR 4
	NOTE Csh, 4
	INSTR 11
	NOTE Gsh, 2
	INSTR 4
	NOTE Csh, 4
	REPEAT_END
	REPEAT 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 5
	NOTE Dsh, 4
	INSTR 11
	NOTE Ash, 2
	INSTR 5
	NOTE Dsh, 4
	REPEAT_END
	REPEAT 2
	INSTR 11
	NOTE Gsh, 2
	INSTR 4
	NOTE Gsh, 4
	INSTR 11
	NOTE Dsh, 2
	INSTR 4
	NOTE Gsh, 4
	REPEAT_END
	INSTR 11
	NOTE Csh, 3
	NOTE C_, 3
	NOTE Ash, 2
	NOTE Gsh, 2
	NOTE Fsh, 2
	NOTE F_, 2
	NOTE Dsh, 2
	NOTE Gsh, 2
	REPEAT 2
	INSTR 11
	NOTE Csh, 2
	INSTR 4
	NOTE Csh, 4
	INSTR 11
	NOTE Gsh, 2
	INSTR 4
	NOTE Csh, 4
	REPEAT_END
	REPEAT 2
	INSTR 11
	NOTE Fsh, 2
	INSTR 4
	NOTE Fsh, 4
	INSTR 11
	NOTE Csh, 3
	INSTR 4
	NOTE Fsh, 4
	REPEAT_END
	INSTR 11
	LENGTH $60
	NOTE Gsh, 2
	LEN 24
	NOTE Csh, 3
	LEN 12
	NOTE Gsh, 2
	LENGTH $3C
	NOTE Csh, 3
	END
Pat_5483:
	LEN 12
	REST
	INSTR 13
	LEN 6
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Csh, 4
	WAIT2
	NOTE Gsh, 3
	WAIT2
	NOTE F_, 4
	WAIT2
	NOTE Csh, 4
	WAIT2
	LEN 12
	NOTE Gsh, 4
	LEN 6
	NOTE F_, 4
	LEN 18
	WAIT2
	LEN 6
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	WAIT2
	NOTE Dsh, 4
	WAIT2
	LEN 12
	NOTE Dsh, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	LEN 6
	NOTE C_, 5
	WAIT2
	NOTE Dsh, 4
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE Dsh, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE Dsh, 4
	WAIT2
	LEN 24
	NOTE A_, 4
	LEN 6
	NOTE Gsh, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	LEN 18
	NOTE Gsh, 4
	LEN 42
	WAIT2
	LEN 12
	WAIT
	INSTR 13
	LEN 6
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE Gsh, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	NOTE Csh, 4
	WAIT2
	NOTE Gsh, 3
	WAIT2
	LEN 12
	NOTE Csh, 4
	LEN 6
	NOTE F_, 4
	WAIT2
	NOTE Fsh, 4
	WAIT2
	NOTE Gsh, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	LEN 24
	NOTE Csh, 5
	LEN 6
	NOTE Csh, 4
	WAIT2
	LEN 12
	NOTE C_, 5
	LEN 6
	NOTE Ash, 4
	WAIT2
	NOTE Gsh, 3
	WAIT2
	LEN 12
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Gsh, 4
	LEN 6
	NOTE Csh, 3
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE Csh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	LEN 12
	NOTE Csh, 5
	LENGTH $30
	WAIT2
	END
Pat_54F7:
	INSTR 6
	LEN 24
	NOTE Gsh, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE Ash, 5
	LEN 12
	NOTE A_, 5
	LENGTH $3C
	NOTE Ash, 5
	LEN 24
	NOTE C_, 6
	NOTE C_, 6
	NOTE Ash, 5
	NOTE A_, 5
	LEN 12
	NOTE Gsh, 5
	NOTE Ash, 5
	NOTE F_, 5
	LEN 24
	NOTE Gsh, 5
	LEN 12
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	INSTR 6
	LEN 24
	NOTE Csh, 5
	LEN 12
	NOTE C_, 5
	NOTE Csh, 5
	LEN 24
	NOTE F_, 5
	LEN 12
	NOTE E_, 5
	NOTE F_, 5
	NOTE Fsh, 5
	NOTE Gsh, 5
	NOTE Ash, 5
	LEN 24
	NOTE Csh, 6
	LEN 12
	NOTE Csh, 6
	NOTE C_, 6
	LEN 24
	NOTE Ash, 5
	LEN 12
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE C_, 6
	NOTE Gsh, 5
	LEN 24
	NOTE Csh, 6
	LEN 12
	NOTE C_, 6
	LENGTH $3C
	NOTE Csh, 6
	END

; Song 5: instrument table 2, arpeggio table 1 (the one SndInit sets)
PlaySong5:
	call StopAll
	ld de, Song5_Ch3
	call StartMusicCh3
	ld de, Song5_Ch2
	call StartMusicCh2
	ld de, Song5_Ch1
	jp StartMusicCh1
Song5_Ch3:
	dw Pat_5552
Song5_Ch2:
	dw Pat_5575
Song5_Ch1:
	dw Pat_55AD
Pat_5552:
	CH_TRANSPOSE $0C
	LEN 12
	REPEAT 2
	INSTR 11
	NOTE Csh, 3
	INSTR 4
	NOTE Csh, 4
	INSTR 11
	NOTE Gsh, 2
	INSTR 4
	NOTE Csh, 4
	REPEAT_END
	REPEAT 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 5
	NOTE Dsh, 4
	INSTR 11
	NOTE Ash, 2
	INSTR 5
	NOTE Dsh, 4
	REPEAT_END
	INSTR 11
	LENGTH $60
	NOTE Gsh, 2
	LEN 24
	NOTE Csh, 3
	LEN 12
	NOTE Gsh, 2
	LENGTH $3C
	NOTE Csh, 3
	END
Pat_5575:
	LEN 12
	REST
	INSTR 13
	LEN 6
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Csh, 4
	WAIT2
	NOTE Gsh, 3
	WAIT2
	NOTE F_, 4
	WAIT2
	NOTE Csh, 4
	WAIT2
	LEN 12
	NOTE Gsh, 4
	LEN 6
	NOTE F_, 4
	LEN 18
	WAIT2
	LEN 6
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	WAIT2
	NOTE Dsh, 4
	WAIT2
	LEN 12
	NOTE Dsh, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	LEN 6
	NOTE Gsh, 3
	WAIT2
	LEN 12
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Gsh, 4
	LEN 6
	NOTE Csh, 3
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE Csh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	LEN 12
	NOTE Csh, 5
	LENGTH $30
	WAIT2
	END
Pat_55AD:
	INSTR 6
	LEN 24
	NOTE Gsh, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE Ash, 5
	LEN 12
	NOTE A_, 5
	LENGTH $48
	NOTE Ash, 5
	LEN 12
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE C_, 6
	NOTE Gsh, 5
	LEN 24
	NOTE Csh, 6
	LEN 12
	NOTE C_, 6
	LENGTH $3C
	NOTE Csh, 6
	END

; Song 6: instrument table 2, arpeggio table 1 (the one SndInit sets)
PlaySong6:
	call StopAll
	ld de, Song6_Ch3
	call StartMusicCh3
	ld de, Song6_Ch2
	call StartMusicCh2
	ld de, Song6_Ch1
	jp StartMusicCh1
Song6_Ch3:
	dw Pat_55FC
	dw Pat_5643
	dw Pat_567E
	ORDER_LOOP Song6_Ch3
Song6_Ch2:
	dw Pat_56B4
	dw Pat_5700
	dw Pat_571A
	ORDER_LOOP Song6_Ch2
Song6_Ch1:
	dw Pat_573D
	dw Pat_577A
	dw Pat_57BA
	ORDER_LOOP Song6_Ch1
Pat_55FC:
	CH_TRANSPOSE $0C
	TRANSPOSE $02
	INSTR 11
	LEN 14
	NOTE B_, 2
	INSTR 4
	NOTE B_, 3
	INSTR 11
	NOTE Fsh, 2
	INSTR 4
	LEN 7
	NOTE B_, 3
	INSTR 11
	NOTE Fsh, 2
	LEN 14
	NOTE B_, 2
	INSTR 4
	NOTE B_, 3
	NOTE B_, 3
	INSTR 11
	NOTE Fsh, 2
	NOTE B_, 2
	INSTR 4
	NOTE B_, 3
	INSTR 11
	NOTE Fsh, 2
	INSTR 4
	LEN 7
	NOTE B_, 3
	INSTR 11
	NOTE Fsh, 2
	LEN 14
	NOTE B_, 2
	INSTR 4
	LEN 7
	NOTE B_, 3
	NOTE B_, 3
	LEN 14
	NOTE B_, 3
	INSTR 11
	NOTE B_, 2
	NOTE Fsh, 2
	INSTR 4
	NOTE B_, 3
	INSTR 11
	NOTE G_, 2
	INSTR 4
	NOTE B_, 3
	INSTR 11
	NOTE Gsh, 2
	INSTR 4
	NOTE E_, 4
	INSTR 11
	NOTE E_, 2
	INSTR 4
	NOTE E_, 4
	INSTR 11
	LEN 21
	NOTE Fsh, 2
	LEN 7
	NOTE Gsh, 2
	LEN 14
	NOTE Fsh, 2
	NOTE Gsh, 2
	LEN 28
	NOTE Fsh, 2
	INSTR 4
	NOTE Fsh, 4
	NEXT
Pat_5643:
	INSTR 11
	LEN 14
	NOTE B_, 2
	INSTR 4
	NOTE B_, 3
	INSTR 11
	NOTE Fsh, 2
	INSTR 4
	NOTE B_, 3
	INSTR 11
	NOTE B_, 2
	INSTR 4
	NOTE B_, 3
	NOTE B_, 3
	INSTR 11
	NOTE Fsh, 2
	NOTE B_, 2
	INSTR 4
	NOTE B_, 3
	INSTR 11
	NOTE Fsh, 2
	INSTR 4
	NOTE B_, 3
	INSTR 11
	NOTE Csh, 3
	INSTR 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	INSTR 11
	NOTE Fsh, 2
	NOTE Csh, 3
	INSTR 4
	NOTE Fsh, 4
	INSTR 11
	NOTE Fsh, 2
	INSTR 4
	NOTE Fsh, 4
	INSTR 11
	NOTE Csh, 3
	INSTR 4
	NOTE Fsh, 4
	INSTR 11
	NOTE Fsh, 2
	INSTR 4
	NOTE Fsh, 4
	INSTR 11
	NOTE Csh, 3
	INSTR 4
	NOTE Fsh, 4
	INSTR 11
	NOTE Fsh, 2
	INSTR 4
	NOTE Fsh, 4
	INSTR 11
	NOTE B_, 2
	NOTE Ash, 2
	NOTE Gsh, 2
	NOTE Fsh, 2
	NEXT
Pat_567E:
	INSTR 11
	LEN 14
	NOTE B_, 2
	INSTR 4
	NOTE B_, 3
	INSTR 11
	NOTE Fsh, 2
	INSTR 4
	NOTE B_, 3
	INSTR 11
	NOTE B_, 2
	INSTR 4
	NOTE B_, 3
	NOTE B_, 3
	INSTR 11
	NOTE Fsh, 2
	NOTE B_, 2
	INSTR 4
	NOTE B_, 3
	INSTR 11
	NOTE Fsh, 2
	INSTR 4
	NOTE B_, 3
	INSTR 11
	NOTE Csh, 3
	INSTR 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	INSTR 11
	NOTE Fsh, 2
	NOTE Csh, 3
	INSTR 4
	NOTE Fsh, 4
	INSTR 11
	NOTE Fsh, 2
	INSTR 4
	NOTE Fsh, 4
	INSTR 11
	NOTE Csh, 3
	INSTR 4
	NOTE Fsh, 4
	INSTR 11
	NOTE Fsh, 2
	INSTR 4
	NOTE Fsh, 4
	INSTR 11
	NOTE Fsh, 2
	NOTE G_, 2
	NOTE Gsh, 2
	NOTE Ash, 2
	LENGTH $38
	NOTE B_, 2
	NEXT
Pat_56B4:
	INSTR 9
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE Dsh, 5
	NOTE B_, 4
	LEN 14
	NOTE Fsh, 4
	NOTE Dsh, 5
	NOTE B_, 4
	INSTR 13
	LEN 7
	NOTE Fsh, 4
	NOTE Dsh, 4
	NOTE B_, 3
	WAIT2
	INSTR 9
	LEN 14
	NOTE Fsh, 4
	NOTE B_, 4
	LEN 7
	NOTE Dsh, 5
	NOTE B_, 4
	LEN 14
	NOTE Fsh, 4
	NOTE Dsh, 5
	NOTE B_, 4
	INSTR 13
	LEN 7
	NOTE B_, 4
	NOTE Fsh, 4
	NOTE Dsh, 4
	LEN 21
	WAIT2
	LEN 7
	NOTE Fsh, 3
	WAIT2
	LEN 7
	NOTE F_, 3
	NOTE Fsh, 3
	LEN 7
	NOTE G_, 3
	WAIT2
	LEN 7
	NOTE Fsh, 3
	NOTE G_, 3
	LEN 7
	NOTE Gsh, 3
	WAIT2
	LEN 7
	NOTE G_, 3
	NOTE Gsh, 3
	LEN 21
	NOTE Dsh, 4
	LEN 7
	WAIT2
	LEN 14
	NOTE Ash, 4
	LEN 7
	WAIT2
	NOTE B_, 4
	LEN 7
	NOTE Ash, 4
	WAIT2
	NOTE B_, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	LEN 7
	NOTE Dsh, 4
	NOTE E_, 4
	LEN 21
	NOTE Fsh, 4
	LEN 7
	WAIT2
	NEXT
Pat_5700:
	LENGTH $46
	WAIT2
	INSTR 13
	LEN 7
	NOTE Dsh, 5
	NOTE E_, 5
	NOTE Fsh, 5
	LENGTH $5B
	WAIT2
	LEN 7
	NOTE Fsh, 5
	NOTE F_, 5
	NOTE E_, 5
	LENGTH $CB
	WAIT2
	LEN 7
	NOTE Fsh, 5
	NOTE Gsh, 5
	NOTE Ash, 5
	NOTE B_, 5
	NOTE Ash, 5
	NOTE Gsh, 5
	NEXT
Pat_571A:
	INSTR 13
	LEN 28
	NOTE Fsh, 5
	LEN 42
	WAIT2
	LEN 7
	NOTE Dsh, 5
	NOTE E_, 5
	NOTE Fsh, 5
	LENGTH $5B
	WAIT2
	LEN 7
	NOTE Fsh, 5
	NOTE F_, 5
	NOTE E_, 5
	LENGTH $77
	WAIT2
	LEN 7
	NOTE Dsh, 3
	WAIT2
	NOTE Fsh, 3
	NOTE Fsh, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE Gsh, 3
	NOTE Gsh, 4
	NOTE Ash, 3
	NOTE Ash, 4
	NOTE B_, 3
	LENGTH $31
	WAIT2
	NEXT
Pat_573D:
	DRUMS $07, DrumPat_57F9
	INSTR 9
	LEN 28
	NOTE B_, 3
	NOTE Fsh, 3
	LEN 14
	NOTE B_, 3
	INSTR 13
	LEN 7
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Fsh, 3
	LEN 21
	WAIT2
	INSTR 9
	LEN 28
	NOTE B_, 3
	NOTE Fsh, 3
	LEN 14
	NOTE B_, 3
	INSTR 13
	LEN 7
	NOTE Fsh, 4
	NOTE Dsh, 4
	NOTE B_, 3
	LEN 21
	WAIT2
	RELEASE $07, $A1
	LEN 14
	NOTE Fsh, 4
	LEN 7
	NOTE F_, 4
	NOTE Fsh, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE Fsh, 4
	NOTE G_, 4
	LEN 14
	NOTE Gsh, 4
	LEN 7
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 28
	NOTE Dsh, 5
	LEN 21
	NOTE Csh, 5
	LEN 7
	NOTE Dsh, 5
	LEN 14
	NOTE Csh, 5
	NOTE Dsh, 5
	LEN 28
	NOTE Csh, 5
	NOTE Fsh, 5
	NEXT
Pat_577A:
	DRUMS $07, DrumPat_5833
	INSTR 6
	LEN 7
	NOTE B_, 4
	NOTE B_, 4
	LEN 14
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE Dsh, 4
	INSTR 13
	LEN 7
	NOTE B_, 4
	NOTE Csh, 5
	NOTE Dsh, 5
	WAIT2
	INSTR 6
	LEN 14
	NOTE Fsh, 4
	LEN 7
	NOTE B_, 4
	NOTE B_, 4
	LEN 14
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE Ash, 4
	INSTR 13
	LEN 7
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE Csh, 5
	WAIT2
	INSTR 6
	LEN 14
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Fsh, 4
	NOTE Gsh, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE Ash, 4
	LEN 14
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE Dsh, 4
	LEN 7
	NOTE Fsh, 4
	NOTE Fsh, 4
	LEN 14
	NOTE Csh, 4
	NOTE E_, 4
	NOTE Dsh, 4
	LEN 42
	NOTE Fsh, 4
	LEN 14
	NOTE Fsh, 4
	NEXT
Pat_57BA:
	INSTR 6
	LEN 7
	NOTE B_, 4
	NOTE B_, 4
	LEN 14
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE Dsh, 4
	INSTR 13
	LEN 7
	NOTE B_, 4
	NOTE Csh, 5
	NOTE Dsh, 5
	WAIT2
	INSTR 6
	LEN 14
	NOTE Fsh, 4
	LEN 7
	NOTE B_, 4
	NOTE B_, 4
	LEN 14
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE Ash, 4
	INSTR 13
	LEN 7
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE Csh, 5
	WAIT2
	INSTR 6
	LEN 14
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Fsh, 4
	NOTE Gsh, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE Ash, 4
	LEN 14
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE Dsh, 4
	LEN 7
	NOTE Fsh, 4
	NOTE Fsh, 4
	LEN 14
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	DRUMS_OFF
	CALL_CODE Drum7
	LENGTH $38
	NOTE B_, 4
	NEXT
DrumPat_57F9:
	db DRUM_REPEAT + 2, DRUM_LEVEL + 12, 9, 0, DRUM_TEMPO + 3, 9, DRUM_TEMPO + 4, 9
	db DRUM_TEMPO + 7, 9, 9, 0, 9, 0, 9, 0
	db DRUM_LEVEL + 15, 6, 6, 4, 0, 1, 0, DRUM_REPEAT_END
	db DRUM_LEVEL + 12, 7, 0, 6, 6, 9, 0, 5
	db 6, 1, 0, 6, 5, 9, 0, 5
	db 5, 9, 0, 0, 9, 9, 0, 9
	db 0, 9, 0, 0, 0, 7, 0, 0
	db 0, DRUM_LOOP
DrumPat_5833:
	db DRUM_LEVEL + 12, 7, 0, 5, 6, 9, 0, 6
	db 5, 1, 0, 9, 9, 9, 0, 5
	db 5, 1, 0, 5, 6, 9, 0, 6
	db 5, 1, 0, 9, 9, 9, 0, 5
	db 5, DRUM_REPEAT + 3, 1, 0, 5, 6, 9, 0
	db 6, 5, DRUM_REPEAT_END, 1, 0, 9, 9, 9
	db 0, 9, 9, DRUM_LOOP

; Song 7: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong7:
	call StopAll
	ld a, $6F
	ld [wInstrTableHi], a
	ld a, $93
	ld [wInstrTable], a
	ld de, Song7_Ch1
	call StartMusicCh1
	ld de, Song7_Ch3
	call StartMusicCh3
	ld de, Song7_Ch2
	jp StartMusicCh2

; Unreferenced (1 bytes)
	db $C9
Song7_Ch1:
	dw Pat_58E7
	dw Pat_5967
	dw Pat_58FD
	dw Pat_58FD
	dw Pat_5921
	dw Pat_5930
	dw Pat_5921
	dw Pat_593F
	dw Pat_58FD
	dw Pat_58FD
	dw Pat_5921
	dw Pat_5930
	dw Pat_5921
	dw Pat_593F
	ORDER_LOOP Song7_Ch1
Song7_Ch3:
	dw Pat_5982
	dw Pat_5A47
	dw Pat_59DA
	dw Pat_59DA
	dw Pat_5A00
	dw Pat_5A15
	dw Pat_5A00
	dw Pat_5A30
	dw Pat_59DA
	dw Pat_59DA
	dw Pat_5A00
	dw Pat_5A15
	dw Pat_5A00
	dw Pat_5A30
	ORDER_LOOP Song7_Ch3
Song7_Ch2:
	dw Pat_5A98
	dw Pat_5B3D
	dw Pat_5AA9
	dw Pat_5AA9
	dw Pat_5ADB
	dw Pat_5B08
	dw Pat_5ADB
	dw Pat_5B31
	dw Pat_5AA9
	dw Pat_5AA9
	dw Pat_5ADB
	dw Pat_5B08
	dw Pat_5ADB
	dw Pat_5B31
	ORDER_LOOP Song7_Ch2
Pat_58E7:
	TRANSPOSE $01
	LEN 14
	HWENV $F1, $00
	ARP 0
	DUTY_75
	ARP 0
	AUTODUTY $00
	REPEAT 4
	REST
	NOTE Dsh, 2
	NOTE Ash, 2
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Ash, 2
	NOTE Dsh, 2
	REPEAT_END
	NEXT
Pat_58FD:
	HWENV $D1, $07, $30
	AUTODUTY $03
	ARP 4
	LEN 28
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 28
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	NEXT
Pat_5921:
	LEN 28
	NOTE Gsh, 4
	NOTE Gsh, 5
	NOTE Gsh, 4
	NOTE Gsh, 5
	LEN 14
	NOTE Gsh, 4
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 4
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 4
	NOTE Gsh, 3
	NEXT
Pat_5930:
	LEN 28
	NOTE Dsh, 5
	NOTE Dsh, 4
	NOTE Dsh, 5
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE Dsh, 4
	NOTE Dsh, 5
	NOTE Dsh, 4
	NOTE Dsh, 5
	NOTE Dsh, 4
	NEXT
Pat_593F:
	LEN 14
	NOTE Ash, 4
	NOTE Ash, 3
	NOTE Ash, 4
	NOTE Ash, 3
	NOTE Ash, 4
	LEN 7
	NOTE Ash, 3
	NOTE Ash, 4
	LEN 14
	NOTE Ash, 4
	NOTE Ash, 3
	AUTODUTY $00
	HWENV $D2, $00
	DUTY_50
	GLIDE $FF
	ARP_OFF
	DRUMS $07, DrumPat_5B62
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Ash, 4
	LEN 7
	NOTE Ash, 4
	LEN 14
	NOTE Fsh, 4
	NOTE Fsh, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	NOTE Csh, 4
	GLIDE_OFF
	NEXT
Pat_5967:
	LEN 14
	REPEAT 3
	REST
	NOTE Dsh, 2
	NOTE Ash, 2
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Ash, 2
	NOTE Dsh, 2
	REPEAT_END
	DRUMS_OFF
	CALL_CODE Drum7
	NOTE Ash, 2
	LENGTH $62
	CALL_CODE Drum7
	HWENV $F2, $0E, $40
	NOTE Ash, 2
	NEXT
Pat_5982:
	CH_TRANSPOSE $0C
	DRUMS $07, DrumPat_5B52
	INSTR 0
	LEN 14
	NOTE A_, 3
	INSTR 2
	NOTE Dsh, 5
	INSTR 0
	NOTE A_, 3
	INSTR 2
	NOTE Dsh, 4
	INSTR 0
	LEN 21
	NOTE A_, 3
	INSTR 2
	LEN 7
	NOTE Dsh, 5
	INSTR 0
	LEN 14
	NOTE A_, 3
	INSTR 2
	NOTE Ash, 3
	INSTR 0
	NOTE A_, 3
	INSTR 2
	NOTE Ash, 5
	INSTR 0
	NOTE A_, 3
	INSTR 2
	NOTE Ash, 4
	INSTR 0
	LEN 21
	NOTE A_, 3
	INSTR 2
	LEN 7
	NOTE Ash, 5
	INSTR 0
	LEN 14
	NOTE A_, 3
	INSTR 2
	LEN 7
	NOTE Dsh, 4
	INSTR 0
	NOTE A_, 3
	LEN 14
	NOTE A_, 3
	INSTR 2
	NOTE Dsh, 6
	INSTR 0
	NOTE A_, 3
	INSTR 2
	NOTE Dsh, 5
	INSTR 0
	LEN 21
	NOTE A_, 3
	INSTR 2
	LEN 7
	NOTE Dsh, 6
	INSTR 0
	LEN 14
	NOTE A_, 3
	INSTR 2
	NOTE Ash, 4
	INSTR 0
	NOTE A_, 3
	INSTR 2
	NOTE Ash, 5
	INSTR 0
	NOTE A_, 3
	INSTR 2
	NOTE Ash, 4
	INSTR 0
	LEN 21
	NOTE A_, 3
	INSTR 2
	LEN 7
	NOTE Ash, 5
	INSTR 0
	LEN 14
	NOTE A_, 3
	LEN 7
	NOTE A_, 3
	NOTE A_, 3
	NEXT
Pat_59DA:
	LEN 14
	DRUMS $07, DrumPat_5B48
	REPEAT 4
	INSTR 0
	NOTE A_, 3
	INSTR 3
	NOTE Dsh, 2
	REPEAT_END
	REPEAT 3
	INSTR 0
	NOTE A_, 3
	INSTR 3
	NOTE Ash, 2
	REPEAT_END
	INSTR 0
	NOTE A_, 3
	INSTR 3
	LEN 7
	NOTE Ash, 2
	INSTR 0
	NOTE A_, 3
	LEN 14
	REPEAT 4
	INSTR 0
	NOTE A_, 3
	INSTR 3
	NOTE Dsh, 2
	REPEAT_END
	REPEAT 4
	INSTR 0
	NOTE A_, 3
	INSTR 3
	NOTE Ash, 2
	REPEAT_END
	NEXT
Pat_5A00:
	LEN 14
	REPEAT 4
	INSTR 0
	NOTE A_, 3
	INSTR 3
	NOTE Gsh, 2
	REPEAT_END
	REPEAT 3
	INSTR 0
	NOTE A_, 3
	INSTR 3
	NOTE Gsh, 1
	REPEAT_END
	INSTR 0
	NOTE A_, 3
	INSTR 3
	LEN 7
	NOTE Gsh, 1
	INSTR 0
	NOTE A_, 3
	NEXT
Pat_5A15:
	LEN 14
	REPEAT 4
	INSTR 0
	NOTE A_, 3
	INSTR 3
	NOTE Dsh, 2
	REPEAT_END
	INSTR 0
	NOTE A_, 3
	INSTR 3
	NOTE Dsh, 3
	INSTR 0
	NOTE A_, 3
	INSTR 3
	NOTE Csh, 3
	INSTR 0
	NOTE A_, 3
	INSTR 3
	NOTE C_, 3
	INSTR 0
	NOTE A_, 3
	INSTR 3
	LEN 7
	NOTE Ash, 2
	INSTR 0
	NOTE A_, 3
	NEXT
Pat_5A30:
	LEN 14
	REPEAT 5
	INSTR 0
	NOTE A_, 3
	INSTR 3
	NOTE Ash, 2
	REPEAT_END
	INSTR 0
	NOTE A_, 3
	INSTR 3
	NOTE Gsh, 2
	INSTR 0
	NOTE A_, 3
	INSTR 3
	NOTE G_, 2
	INSTR 0
	NOTE A_, 3
	INSTR 3
	LEN 7
	NOTE F_, 2
	INSTR 0
	NOTE A_, 3
	NEXT
Pat_5A47:
	LEN 14
	REPEAT 2
	INSTR 0
	NOTE A_, 3
	INSTR 1
	NOTE Dsh, 3
	REPEAT_END
	INSTR 0
	NOTE A_, 3
	INSTR 1
	LEN 7
	NOTE Dsh, 3
	INSTR 2
	NOTE Dsh, 5
	LEN 14
	INSTR 0
	NOTE A_, 3
	INSTR 1
	NOTE Dsh, 3
	REPEAT 2
	INSTR 0
	NOTE A_, 3
	INSTR 1
	NOTE Dsh, 4
	REPEAT_END
	INSTR 0
	NOTE A_, 3
	INSTR 1
	LEN 7
	NOTE Dsh, 4
	INSTR 2
	NOTE Ash, 5
	LEN 14
	INSTR 0
	NOTE A_, 3
	INSTR 1
	LEN 7
	NOTE Dsh, 4
	INSTR 0
	NOTE A_, 3
	LEN 14
	NOTE A_, 3
	INSTR 1
	NOTE Dsh, 5
	INSTR 0
	NOTE A_, 3
	INSTR 1
	NOTE Dsh, 5
	INSTR 0
	NOTE A_, 3
	INSTR 1
	LEN 7
	NOTE Dsh, 5
	INSTR 2
	NOTE Dsh, 6
	INSTR 0
	LEN 14
	NOTE A_, 3
	INSTR 1
	NOTE Dsh, 5
	VOLENV 15, $11, $1A, $13
	ARP 4
	NOTE Dsh, 5
	ARP 5
	LENGTH $46
	NOTE Ash, 4
	DRUMS $07, DrumPat_5B5D
	INSTR 0
	LEN 14
	NOTE A_, 3
	LEN 7
	NOTE A_, 3
	NOTE A_, 3
	NEXT
Pat_5A98:
	DUTY_50
	HWENV $C0, $0E, $C7
	DUTY_75
	VIBRATO $14, $01, $05
	LENGTH $70
	NOTE Dsh, 3
	NOTE Ash, 3
	NOTE Dsh, 4
	NOTE Ash, 3
	NEXT
Pat_5AA9:
	LEN 14
	WAIT
	HWENV $C2, $00
	ARP 0
	DUTY_50
	NOTE Dsh, 4
	NOTE Ash, 4
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Dsh, 4
	NOTE Ash, 4
	LEN 28
	NOTE Dsh, 4
	LEN 14
	NOTE Csh, 4
	NOTE Gsh, 4
	NOTE Csh, 4
	NOTE Csh, 5
	LEN 7
	NOTE C_, 5
	NOTE Ash, 4
	LEN 14
	NOTE Gsh, 4
	LEN 28
	NOTE Ash, 4
	LEN 14
	NOTE Dsh, 4
	NOTE Ash, 4
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Dsh, 4
	NOTE Ash, 4
	NOTE Dsh, 4
	NOTE Dsh, 5
	LEN 7
	NOTE Csh, 5
	NOTE C_, 5
	LEN 14
	NOTE Ash, 4
	NOTE Dsh, 4
	NOTE Csh, 5
	LEN 7
	NOTE Csh, 5
	NOTE C_, 5
	LEN 14
	NOTE Ash, 4
	NOTE Gsh, 4
	NEXT
Pat_5ADB:
	ARP_OFF
	HWENV $D0, $04, $23
	AUTODUTY $07
	LEN 7
	NOTE Dsh, 5
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 5
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE Dsh, 5
	NOTE Gsh, 3
	NOTE Gsh, 4
	NOTE Gsh, 5
	NOTE Gsh, 4
	NOTE Gsh, 5
	NOTE Gsh, 6
	NOTE Gsh, 3
	NOTE Gsh, 6
	DUTY_50
	AUTODUTY $00
	ARP 0
	LEN 14
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 5
	LEN 7
	NOTE Gsh, 3
	LEN 14
	NOTE Gsh, 4
	LEN 7
	NOTE Gsh, 3
	LEN 14
	NOTE Gsh, 4
	NOTE Gsh, 5
	LEN 14
	NOTE Gsh, 4
	ARP_OFF
	NEXT
Pat_5B08:
	AUTODUTY $07
	LEN 7
	NOTE Ash, 5
	NOTE Ash, 3
	NOTE Ash, 4
	NOTE Dsh, 5
	NOTE Dsh, 6
	NOTE Dsh, 4
	NOTE Ash, 4
	NOTE Ash, 5
	NOTE Dsh, 4
	NOTE Dsh, 5
	NOTE Dsh, 6
	NOTE Dsh, 5
	NOTE Dsh, 6
	NOTE Dsh, 5
	NOTE Dsh, 4
	NOTE Dsh, 5
	DUTY_50
	AUTODUTY $00
	ARP 0
	LEN 14
	NOTE Dsh, 4
	NOTE Dsh, 5
	NOTE Dsh, 5
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE Csh, 5
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE C_, 5
	NOTE C_, 5
	LEN 7
	NOTE Ash, 3
	NOTE Ash, 4
	ARP_OFF
	NEXT
Pat_5B31:
	HWENV $C0, $0E, $C7
	DUTY_75
	LENGTH $38
	NOTE Ash, 3
	NOTE F_, 4
	NOTE Ash, 4
	NOTE Ash, 5
	NEXT
Pat_5B3D:
	LENGTH $70
	NOTE Dsh, 4
	NOTE Ash, 4
	NOTE Dsh, 5
	LEN 14
	NOTE G_, 5
	LENGTH $62
	NOTE F_, 5
	NEXT
DrumPat_5B48:
	db DRUM_LEVEL + 14, 1, 6, 4, 0, 2, 0, 4
	db 0, DRUM_LOOP
DrumPat_5B52:
	db DRUM_REPEAT + 7, 1, 0, 6, 0, DRUM_REPEAT_END, 1, 0
	db 6, 1, DRUM_LOOP
DrumPat_5B5D:
	db 2, 0, 2, 2, DRUM_LOOP
DrumPat_5B62:
	db 2, 0, 2, 0, 2, 0, 2, 2
	db 0, 2, 0, 2, 2, 0, 2, 0
	db DRUM_LOOP

; Song 8: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong8:
	call StopAll
	ld a, $6F
	ld [wInstrTableHi], a
	ld a, $93
	ld [wInstrTable], a
	ld de, Song8_Ch1
	call StartMusicCh1
	ld de, Song8_Ch2
	call StartMusicCh2
	ld de, Song8_Ch3
	jp StartMusicCh3

; Unreferenced (1 bytes)
	db $C9
Song8_Ch1:
	dw Pat_5BDB
	dw Pat_5BDB
	dw Pat_5BDB
	dw Pat_5BDB
	dw Pat_5BEE
	dw Pat_5BEE
	dw Pat_5C21
	dw Pat_5C21
	dw Pat_5BEE
	dw Pat_5BEE
	ORDER_LOOP Song8_Ch1
Song8_Ch2:
	dw Pat_5C92
	dw Pat_5C92
	dw Pat_5C6F
	dw Pat_5C6F
	dw Pat_5CB8
	dw Pat_5CB8
	dw Pat_5D4A
	dw Pat_5D4A
	dw Pat_5CB8
	dw Pat_5CB8
	ORDER_LOOP Song8_Ch2
Song8_Ch3:
	dw Pat_5D87
	dw Pat_5D87
	dw Pat_5D55
	dw Pat_5D55
	dw Pat_5DCE
	dw Pat_5DCE
	dw Pat_5E3A
	dw Pat_5E45
	dw Pat_5DCE
	dw Pat_5DCE
	ORDER_LOOP Song8_Ch3
Pat_5BDB:
	LEN 24
	TRANSPOSE $02
	RELEASE $01, $00
	INSTR 4
	REPEAT 8
	LEN 24
	NOTE A_, 2
	LEN 8
	NOTE E_, 2
	INSTR 5
	LEN 16
	NOTE F_, 3
	INSTR 4
	NOTE G_, 2
	REPEAT_END
	NEXT
Pat_5BEE:
	REPEAT 3
	LEN 24
	NOTE A_, 2
	LEN 8
	NOTE E_, 2
	INSTR 5
	LEN 16
	NOTE F_, 3
	INSTR 4
	NOTE G_, 2
	REPEAT_END
	LEN 24
	NOTE A_, 2
	LEN 8
	NOTE E_, 2
	INSTR 5
	NOTE F_, 3
	INSTR 4
	NOTE G_, 2
	LEN 16
	NOTE E_, 2
	REPEAT 2
	LEN 24
	NOTE A_, 2
	LEN 8
	NOTE E_, 2
	INSTR 5
	LEN 16
	NOTE F_, 3
	INSTR 4
	NOTE G_, 2
	REPEAT_END
	LEN 24
	NOTE D_, 2
	LEN 8
	NOTE A_, 2
	INSTR 5
	LEN 16
	NOTE F_, 3
	INSTR 4
	NOTE D_, 3
	LEN 24
	NOTE E_, 2
	LEN 8
	NOTE B_, 2
	INSTR 5
	LEN 16
	NOTE F_, 3
	INSTR 4
	NOTE E_, 3
	NEXT
Pat_5C21:
	REPEAT 2
	LEN 24
	NOTE A_, 2
	LEN 8
	NOTE E_, 2
	INSTR 5
	LEN 16
	NOTE F_, 3
	INSTR 4
	NOTE Gsh, 2
	LEN 24
	NOTE A_, 2
	LEN 8
	NOTE E_, 2
	INSTR 5
	LEN 16
	NOTE F_, 3
	INSTR 4
	NOTE A_, 2
	LEN 24
	NOTE D_, 2
	LEN 8
	NOTE A_, 2
	INSTR 5
	LEN 16
	NOTE F_, 3
	INSTR 4
	NOTE D_, 3
	LEN 24
	NOTE E_, 2
	LEN 8
	NOTE B_, 2
	INSTR 5
	LEN 16
	NOTE F_, 3
	INSTR 4
	NOTE E_, 3
	REPEAT_END
	NEXT
Pat_5C48:
	NOTE A_, 4
	INSTR 7
	LEN 16
	NOTE A_, 3
	INSTR 9
	NOTE A_, 4
	INSTR 7
	LEN 8
	NOTE A_, 3
	INSTR 9
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE C_, 5
	INSTR 6
	LEN 16
	NOTE C_, 4
	INSTR 9
	NOTE C_, 5
	INSTR 6
	LEN 8
	NOTE C_, 4
	INSTR 9
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE D_, 5
	INSTR 7
	LEN 16
	NOTE A_, 3
	INSTR 9
	NOTE D_, 5
	INSTR 7
	LEN 8
	NOTE A_, 3
	INSTR 9
	LEN 16
	NOTE D_, 5
	NEXT
Pat_5C6F:
	LEN 8
	WAIT
	INSTR 9
	PAT_CALL Pat_5C48
	LEN 8
	NOTE G_, 4
	INSTR 7
	LEN 16
	NOTE A_, 4
	INSTR 9
	NOTE G_, 4
	INSTR 7
	LEN 8
	NOTE A_, 4
	INSTR 9
	NOTE G_, 4
	WAIT
	PAT_CALL Pat_5C48
	LEN 8
	NOTE E_, 4
	INSTR 7
	LEN 16
	NOTE A_, 4
	INSTR 9
	NOTE E_, 4
	INSTR 7
	LEN 8
	NOTE A_, 4
	INSTR 9
	NOTE G_, 4
	NEXT
Pat_5C92:
	RELEASE $01, $00
	INSTR 9
	LEN 24
	NOTE A_, 3
	LENGTH $68
	NOTE E_, 3
	LEN 24
	NOTE A_, 3
	LENGTH $68
	NOTE E_, 3
	LEN 8
	NOTE A_, 3
	LEN 16
	NOTE A_, 3
	LENGTH $58
	NOTE E_, 3
	LEN 16
	NOTE G_, 3
	LEN 8
	NOTE A_, 3
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE E_, 3
	LEN 16
	NOTE E_, 3
	LEN 32
	NOTE E_, 3
	LEN 16
	NOTE E_, 3
	NOTE G_, 3
	NOTE A_, 3
	NEXT
Pat_5CB8:
	LEN 8
	WAIT
	INSTR 8
	NOTE A_, 4
	INSTR 6
	LEN 16
	NOTE A_, 4
	INSTR 8
	NOTE A_, 4
	INSTR 6
	LEN 8
	NOTE A_, 4
	INSTR 8
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE E_, 4
	INSTR 6
	LEN 16
	NOTE A_, 4
	INSTR 8
	NOTE E_, 4
	INSTR 6
	LEN 8
	NOTE A_, 4
	INSTR 8
	LEN 16
	NOTE E_, 4
	LEN 8
	NOTE D_, 4
	INSTR 6
	LEN 16
	NOTE A_, 4
	INSTR 8
	NOTE D_, 4
	INSTR 6
	LEN 8
	NOTE A_, 4
	INSTR 8
	LEN 16
	NOTE D_, 4
	LEN 8
	NOTE G_, 4
	INSTR 6
	LEN 16
	NOTE A_, 4
	INSTR 8
	NOTE G_, 4
	INSTR 6
	LEN 8
	NOTE A_, 4
	INSTR 8
	LEN 16
	NOTE G_, 4
	REPEAT 2
	LEN 8
	NOTE E_, 4
	INSTR 6
	LEN 16
	NOTE A_, 3
	INSTR 8
	NOTE E_, 4
	INSTR 6
	LEN 8
	NOTE A_, 3
	INSTR 8
	LEN 16
	NOTE E_, 4
	REPEAT_END
	LEN 8
	NOTE E_, 5
	INSTR 6
	LEN 16
	NOTE D_, 4
	INSTR 8
	NOTE E_, 5
	INSTR 6
	LEN 8
	NOTE D_, 4
	INSTR 8
	LEN 16
	NOTE E_, 5
	LEN 8
	NOTE B_, 4
	INSTR 6
	LEN 16
	NOTE E_, 4
	INSTR 8
	NOTE B_, 4
	INSTR 6
	LEN 8
	NOTE E_, 4
	INSTR 8
	NOTE B_, 4
	NEXT
Pat_5D17:
	NOTE A_, 3
	INSTR 6
	LEN 16
	NOTE A_, 4
	INSTR 8
	NOTE A_, 3
	INSTR 6
	LEN 8
	NOTE A_, 4
	INSTR 8
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE A_, 3
	INSTR 6
	LEN 16
	NOTE A_, 4
	INSTR 8
	NOTE A_, 3
	INSTR 6
	LEN 8
	NOTE A_, 4
	INSTR 8
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE D_, 4
	INSTR 6
	LEN 16
	NOTE D_, 4
	INSTR 8
	NOTE D_, 4
	INSTR 6
	LEN 8
	NOTE D_, 4
	INSTR 8
	LEN 16
	NOTE D_, 4
	LEN 8
	NOTE E_, 4
	INSTR 6
	LEN 16
	NOTE E_, 4
	INSTR 8
	NOTE E_, 4
	INSTR 6
	LEN 8
	NOTE E_, 4
	INSTR 8
	NOTE E_, 4
	NEXT
Pat_5D4A:
	LEN 8
	WAIT
	INSTR 8
	PAT_CALL Pat_5D17
	WAIT
	PAT_CALL Pat_5D17
	NEXT
Pat_5D55:
	WAVE Wave_756A
	VOLENV 15, $12, $1F, $11
	GLIDE $FF
	ARP_OFF
	REPEAT 3
	LEN 24
	NOTE C_, 4
	LEN 8
	NOTE C_, 4
	LEN 16
	NOTE G_, 4
	NOTE C_, 4
	REPEAT_END
	LEN 8
	NOTE C_, 4
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE C_, 4
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE C_, 4
	NOTE G_, 4
	REPEAT 3
	LEN 24
	NOTE C_, 4
	LEN 8
	NOTE C_, 4
	LEN 16
	NOTE G_, 4
	NOTE C_, 4
	REPEAT_END
	LEN 8
	NOTE C_, 4
	LEN 16
	NOTE Gsh, 4
	LEN 8
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE D_, 4
	NEXT
Pat_5D87:
	DRUMS $08, DrumPat_5E52
	CH_TRANSPOSE $0C
	VIBRATO $08, $01, $04
	VOLENV 15, $11, $1F, $11
	ARP 0
	WAVE Wave_74DA
	LENGTH $30
	NOTE A_, 3
	LEN 16
	NOTE G_, 3
	LEN 8
	NOTE A_, 3
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE A_, 3
	LEN 16
	NOTE D_, 4
	LEN 8
	NOTE A_, 3
	LENGTH $38
	NOTE E_, 4
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE D_, 4
	LEN 16
	NOTE E_, 4
	LEN 8
	NOTE C_, 4
	LEN 16
	NOTE D_, 4
	LEN 8
	NOTE A_, 3
	LENGTH $38
	NOTE C_, 4
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE A_, 4
	LEN 16
	NOTE A_, 4
	LEN 40
	NOTE E_, 4
	LEN 24
	NOTE A_, 4
	LEN 32
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	LEN 24
	NOTE E_, 4
	LEN 16
	NOTE G_, 4
	NOTE A_, 4
	NEXT
Pat_5DCE:
	WAVE Wave_74CA
	VOLENV 15, $00, $00, $00
	GLIDE_OFF
	ARP 3
	LENGTH $40
	NOTE G_, 4
	ARP 21
	NOTE E_, 4
	NOTE D_, 4
	ARP 3
	NOTE F_, 4
	ARP 21
	LENGTH $80
	NOTE E_, 4
	ARP 3
	LEN 24
	NOTE D_, 5
	ARP 21
	NOTE D_, 5
	NOTE Csh, 5
	NOTE B_, 4
	LEN 16
	NOTE A_, 4
	NOTE Gsh, 4
	NEXT
Pat_5DEE:
	LEN 16
	REST
	RELEASE $02, $50
	ARP_OFF
	WAVE Wave_74CA
	LEN 8
	NOTE Csh, 4
	NOTE D_, 4
	LEN 16
	NOTE E_, 4
	LEN 8
	NOTE Fsh, 4
	LEN 16
	NOTE E_, 4
	NOTE A_, 4
	LEN 8
	NOTE A_, 4
	LEN 16
	NOTE B_, 4
	NOTE Csh, 5
	WAVE Wave_75AA
	NOTE D_, 5
	LEN 8
	NOTE E_, 5
	LEN 16
	NOTE D_, 5
	NOTE Csh, 5
	NOTE B_, 4
	LEN 8
	NOTE B_, 4
	LEN 16
	NOTE A_, 4
	NOTE Gsh, 4
	LEN 8
	NOTE B_, 4
	LEN 16
	NOTE A_, 4
	WAVE Wave_74CA
	LEN 8
	NOTE E_, 4
	NOTE E_, 5
	NOTE D_, 5
	NOTE Csh, 5
	LEN 16
	NOTE B_, 4
	NOTE A_, 4
	LEN 8
	NOTE B_, 4
	LEN 16
	NOTE Csh, 5
	NOTE D_, 5
	LEN 24
	NOTE Fsh, 4
	WAVE Wave_75AA
	LEN 8
	NOTE D_, 4
	NOTE A_, 4
	NOTE Gsh, 4
	LEN 16
	NOTE Fsh, 4
	LEN 8
	NOTE E_, 4
	LEN 16
	NOTE Fsh, 4
	LEN 8
	NEXT
Pat_5E3A:
	PAT_CALL Pat_5DEE
	NOTE Fsh, 4
	LEN 16
	NOTE E_, 4
	NOTE D_, 4
	LEN 8
	NOTE Csh, 4
	NOTE E_, 4
	NEXT
Pat_5E45:
	PAT_CALL Pat_5DEE
	NOTE E_, 4
	LEN 16
	NOTE D_, 4
	NOTE Csh, 4
	LEN 8
	NOTE B_, 3
	NOTE A_, 3
	RELEASE $00
	NEXT
DrumPat_5E52:
	db DRUM_LEVEL + 15, 1, DRUM_LEVEL + 13, 6, 5, 6, DRUM_LEVEL + 15, 2
	db DRUM_LEVEL + 13, 6, 5, 6, 1, 6, 5, DRUM_LEVEL + 15
	db 1, 2, DRUM_LEVEL + 13, 5, DRUM_LEVEL + 15, 4, 0, DRUM_LOOP

; Song 9: instrument table 2, arpeggio table 1 (the one SndInit sets)
PlaySong9:
	call StopAll
	ld de, Song9_Ch3
	call StartMusicCh3
	ld de, Song9_Ch2
	call StartMusicCh2
	ld de, Song9_Ch1
	jp StartMusicCh1
Song9_Ch3:
	dw Pat_5ED9
	dw Pat_5F04
	dw Pat_5F1C
Loop_5E85:
	dw Pat_5F51
	dw Pat_5F51
	dw Pat_5F35
	dw Pat_5F35
	dw Pat_5F51
	dw Pat_5F51
	dw Pat_5F35
	dw Pat_5F35
	dw Pat_5F51
	dw Pat_5F51
	ORDER_LOOP Loop_5E85
Song9_Ch2:
	dw Pat_5F6A
	dw Pat_5F86
	dw Pat_5F9A
Loop_5EA3:
	dw Pat_5FA8
	dw Pat_5FA8
	dw Pat_5FC5
	dw Pat_5FC5
	dw Pat_5FD8
	dw Pat_5FD8
	dw Pat_5FFF
	dw Pat_5FFF
	dw Pat_6014
	dw Pat_6014
	ORDER_LOOP Loop_5EA3
Song9_Ch1:
	dw Pat_608A
	dw Pat_609A
	dw Pat_60B1
Loop_5EC1:
	dw Pat_60C9
	dw Pat_60C9
	dw Pat_60EE
	dw Pat_60EE
	dw Pat_609A
	dw Pat_609A
	dw Pat_6102
	dw Pat_6102
	dw Pat_6124
	dw Pat_6124
	ORDER_LOOP Loop_5EC1
Pat_5ED9:
	WAVE Wave_753A
	CH_TRANSPOSE $0C
	VOLENV 15, $11, $1F, $12
	REPEAT 2
	CALL_CODE Drum7
	ARP 0
	LEN 20
	NOTE Gsh, 3
	ARP_OFF
	NOTE B_, 4
	ARP 0
	LEN 10
	NOTE Csh, 3
	ARP_OFF
	NOTE A_, 4
	ARP 0
	NOTE B_, 3
	ARP_OFF
	NOTE Gsh, 4
	ARP 0
	LEN 20
	NOTE Fsh, 3
	ARP_OFF
	NOTE A_, 4
	ARP 0
	LEN 10
	NOTE Csh, 3
	ARP_OFF
	NOTE Gsh, 4
	ARP 0
	NOTE Fsh, 3
	ARP_OFF
	NOTE Fsh, 4
	REPEAT_END
	NEXT
Pat_5F04:
	LEN 20
	CALL_CODE Drum7
	ARP 0
	NOTE Gsh, 3
	ARP_OFF
	NOTE B_, 4
	ARP 0
	NOTE Csh, 3
	ARP_OFF
	NOTE B_, 4
	CALL_CODE Drum7
	ARP 0
	NOTE Fsh, 3
	ARP_OFF
	NOTE Ash, 4
	ARP 0
	NOTE Csh, 3
	ARP_OFF
	NOTE Ash, 4
	LEN 10
Pat_5F1C:
	DRUMS $05, DrumPat_6148
	REPEAT 2
	ARP 0
	NOTE Gsh, 3
	ARP_OFF
	NOTE B_, 4
	ARP 0
	NOTE Csh, 3
	ARP_OFF
	NOTE B_, 4
	REPEAT_END
	REPEAT 2
	ARP 0
	NOTE Fsh, 3
	ARP_OFF
	NOTE Ash, 4
	ARP 0
	NOTE Csh, 3
	ARP_OFF
	NOTE Ash, 4
	REPEAT_END
	NEXT
Pat_5F35:
	LEN 10
	REPEAT 2
	ARP 0
	NOTE Fsh, 2
	ARP 4
	NOTE B_, 4
	ARP 0
	NOTE Csh, 2
	ARP 4
	NOTE B_, 4
	REPEAT_END
	ARP_OFF
	NOTE Fsh, 3
	ARP 4
	NOTE Fsh, 4
	ARP_OFF
	NOTE Csh, 3
	ARP 4
	NOTE Fsh, 4
	ARP 0
	NOTE Fsh, 2
	ARP 4
	NOTE Fsh, 4
	ARP 0
	NOTE Csh, 2
	ARP 4
	NOTE Fsh, 4
	NEXT
Pat_5F51:
	LEN 10
	PAT_CALL Pat_5F55
Pat_5F55:
	REPEAT 2
	ARP 0
	NOTE Gsh, 2
	ARP 4
	NOTE Csh, 4
	ARP 0
	NOTE Csh, 2
	ARP 4
	NOTE Csh, 4
	REPEAT_END
	REPEAT 2
	ARP 0
	NOTE Fsh, 2
	ARP 4
	NOTE Fsh, 4
	ARP 0
	NOTE Csh, 2
	ARP 4
	NOTE Fsh, 4
	REPEAT_END
	NEXT
Pat_5F6A:
	HWENV $00, $00
	LEN 20
	REST
	INSTR 6
	LEN 30
	NOTE Gsh, 4
	LEN 20
	NOTE Csh, 4
	LEN 30
	NOTE Csh, 4
	NOTE Fsh, 4
	LEN 20
	NOTE Csh, 4
	LEN 30
	NOTE Csh, 4
	NOTE Gsh, 4
	LEN 20
	NOTE Csh, 4
	LEN 30
	NOTE Csh, 4
	NOTE Fsh, 4
	LEN 20
	NOTE Csh, 4
	LEN 10
	NOTE Csh, 4
	NEXT
Pat_5F86:
	LEN 20
	WAIT
	INSTR 6
	LEN 40
	NOTE F_, 4
	NOTE F_, 4
	NOTE Fsh, 4
	LEN 30
	NOTE Fsh, 4
	LEN 20
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	LEN 10
	NOTE Fsh, 4
	NEXT
Pat_5F9A:
	LEN 10
	WAIT
	INSTR 6
	LEN 20
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	LEN 10
	NOTE Fsh, 4
	NEXT
Pat_5FA8:
	LEN 10
	WAIT
	INSTR 6
	NOTE Gsh, 3
	NOTE Gsh, 4
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 4
	NOTE Gsh, 3
	REPEAT 2
	NOTE Fsh, 3
	NOTE Ash, 3
	NOTE Fsh, 4
	NOTE Ash, 3
	REPEAT_END
	REPEAT 2
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE B_, 4
	NOTE B_, 3
	REPEAT_END
	REPEAT 2
	NOTE Fsh, 3
	NOTE Ash, 3
	NOTE Ash, 4
	NOTE Ash, 3
	REPEAT_END
	NEXT
Pat_5FC5:
	INSTR 6
	LEN 10
	NOTE B_, 4
	NOTE Fsh, 4
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE B_, 4
	NOTE Dsh, 5
	NOTE Ash, 4
	NOTE Fsh, 4
	NOTE Csh, 4
	NOTE Ash, 3
	NOTE Csh, 4
	NOTE Fsh, 4
	LEN 20
	NOTE Ash, 4
	NEXT
Pat_5FD8:
	LEN 10
	INSTR 8
	REPEAT 2
	LEN 10
	NOTE C_, 5
	NOTE Csh, 5
	LEN 15
	NOTE B_, 4
	LEN 5
	NOTE Csh, 5
	REPEAT_END
	REPEAT 2
	LEN 10
	NOTE C_, 5
	NOTE Csh, 5
	LEN 15
	NOTE Ash, 4
	LEN 5
	NOTE Csh, 5
	REPEAT_END
	REPEAT 2
	LEN 10
	NOTE C_, 5
	NOTE Csh, 5
	LEN 15
	NOTE Dsh, 5
	LEN 5
	NOTE Csh, 5
	REPEAT_END
	REPEAT 2
	LEN 10
	NOTE C_, 5
	NOTE Csh, 5
	LEN 15
	NOTE Fsh, 5
	LEN 5
	NOTE Csh, 5
	REPEAT_END
	NEXT
Pat_5FFF:
	INSTR 8
	LEN 10
	NOTE Dsh, 5
	NOTE B_, 4
	NOTE Fsh, 4
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE B_, 4
	NOTE Dsh, 5
	NOTE Fsh, 5
	NOTE Csh, 5
	NOTE Ash, 4
	NOTE Fsh, 4
	NOTE Csh, 4
	NOTE Fsh, 4
	NOTE Ash, 4
	LEN 15
	NOTE Csh, 5
	LEN 5
	NOTE Csh, 5
	NEXT
Pat_6014:
	LEN 5
	WAIT
	INSTR 9
	NOTE Csh, 6
	INSTR 6
	NOTE D_, 3
	INSTR 9
	LEN 10
	NOTE Csh, 6
	LEN 5
	NOTE Csh, 6
	INSTR 6
	NOTE E_, 3
	INSTR 9
	LEN 10
	NOTE Csh, 6
	LEN 5
	NOTE Csh, 6
	INSTR 6
	NOTE A_, 3
	INSTR 9
	LEN 10
	NOTE Csh, 6
	LEN 5
	NOTE Csh, 6
	INSTR 6
	NOTE G_, 3
	INSTR 9
	LEN 10
	NOTE Csh, 6
	LEN 5
	NOTE Csh, 6
	INSTR 6
	NOTE F_, 3
	INSTR 9
	NOTE Csh, 6
	INSTR 6
	NOTE E_, 3
	INSTR 9
	NOTE Csh, 6
	INSTR 6
	NOTE D_, 3
	INSTR 9
	LEN 10
	NOTE Csh, 6
	LEN 5
	NOTE Csh, 6
	INSTR 6
	NOTE D_, 3
	INSTR 9
	NOTE Csh, 6
	INSTR 6
	NOTE Csh, 3
	INSTR 9
	NOTE Csh, 6
	INSTR 6
	NOTE C_, 3
	INSTR 9
	LEN 10
	NOTE Csh, 6
	LEN 5
	NOTE Csh, 6
	INSTR 6
	NOTE Csh, 4
	INSTR 9
	LEN 10
	NOTE Csh, 6
	LEN 5
	NOTE Csh, 6
	INSTR 6
	NOTE F_, 4
	INSTR 9
	LEN 10
	NOTE Csh, 6
	LEN 5
	NOTE Csh, 6
	INSTR 6
	NOTE Ash, 4
	INSTR 9
	LEN 10
	NOTE Csh, 6
	LEN 5
	NOTE Csh, 6
	INSTR 6
	NOTE Gsh, 4
	INSTR 9
	LEN 10
	NOTE Csh, 6
	LEN 5
	NOTE Csh, 6
	INSTR 6
	NOTE Fsh, 4
	INSTR 9
	NOTE Csh, 6
	INSTR 6
	NOTE F_, 4
	INSTR 9
	NOTE Csh, 6
	INSTR 6
	NOTE Dsh, 4
	INSTR 9
	LEN 10
	NOTE Csh, 6
	LEN 5
	NOTE Csh, 6
	INSTR 6
	NOTE Dsh, 4
	INSTR 9
	NOTE Csh, 6
	INSTR 6
	NOTE D_, 4
	INSTR 9
	NOTE Csh, 6
	INSTR 6
	NOTE Csh, 4
	INSTR 9
	NOTE Csh, 6
	NEXT
Pat_608A:
	LEN 5
	HWENV $91, $00
	DUTY_75
	REPEAT 8
	NOTE Csh, 6
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Csh, 6
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Csh, 5
	REPEAT_END
	NEXT
Pat_609A:
	HWENV $91, $00
	DUTY_75
	REPEAT 4
	NOTE Csh, 6
	NOTE Csh, 5
	NOTE Csh, 6
	NOTE Csh, 6
	NOTE Csh, 7
	NOTE Csh, 6
	NOTE Csh, 6
	NOTE Csh, 5
	NOTE Csh, 6
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Csh, 6
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Csh, 5
	REPEAT_END
	NEXT
Pat_60B1:
	REPEAT 3
	NOTE Csh, 6
	NOTE Csh, 5
	NOTE Csh, 6
	NOTE Csh, 6
	NOTE Csh, 7
	NOTE Csh, 6
	NOTE Csh, 6
	NOTE Csh, 5
	REPEAT_END
	NOTE Csh, 6
	NOTE Csh, 5
	NOTE Csh, 6
	NOTE Csh, 6
	NOTE Csh, 7
	NOTE Csh, 6
	NOTE Csh, 6
	HWENV $F2, $0A, $57
	DUTY_50
	NOTE Csh, 5
	NEXT
Pat_60C9:
	REPEAT 2
	LEN 10
	NOTE C_, 5
	NOTE Csh, 5
	LEN 15
	NOTE B_, 4
	LEN 5
	NOTE Csh, 5
	REPEAT_END
	REPEAT 2
	LEN 10
	NOTE C_, 5
	NOTE Csh, 5
	LEN 15
	NOTE Ash, 4
	LEN 5
	NOTE Csh, 5
	REPEAT_END
	REPEAT 2
	LEN 10
	NOTE C_, 5
	NOTE Csh, 5
	LEN 15
	NOTE Dsh, 5
	LEN 5
	NOTE Csh, 5
	REPEAT_END
	REPEAT 2
	LEN 10
	NOTE C_, 5
	NOTE Csh, 5
	LEN 15
	NOTE Fsh, 5
	LEN 5
	NOTE Csh, 5
	REPEAT_END
	NEXT
Pat_60EE:
	LEN 10
	NOTE Dsh, 5
	NOTE B_, 4
	NOTE Fsh, 4
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE B_, 4
	NOTE Dsh, 5
	NOTE Fsh, 5
	NOTE Csh, 5
	NOTE Ash, 4
	NOTE Fsh, 4
	NOTE Csh, 4
	NOTE Fsh, 4
	NOTE Ash, 4
	LEN 15
	NOTE Csh, 5
	LEN 5
	NOTE Csh, 5
	NEXT
Pat_6102:
	LEN 5
	NOTE Dsh, 6
	NOTE Dsh, 5
	NOTE Dsh, 6
	NOTE Dsh, 6
	NOTE Dsh, 7
	NOTE Dsh, 6
	NOTE Dsh, 6
	NOTE Dsh, 5
	NOTE Dsh, 6
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE Dsh, 6
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE Csh, 6
	NOTE Csh, 5
	NOTE Csh, 6
	NOTE Csh, 6
	NOTE Csh, 7
	NOTE Csh, 6
	NOTE Csh, 6
	NOTE Csh, 5
	NOTE Csh, 6
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Csh, 6
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE Csh, 5
	NEXT
Pat_6124:
	LEN 10
	WAIT
	HWENV $F2, $0A, $57
	DUTY_50
	LEN 20
	NOTE Csh, 3
	NOTE F_, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	LEN 10
	NOTE Fsh, 3
	NOTE F_, 3
	LEN 20
	NOTE Dsh, 3
	LEN 10
	NOTE Dsh, 3
	NOTE D_, 3
	LEN 20
	NOTE Csh, 3
	NOTE Csh, 3
	NOTE F_, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	LEN 10
	NOTE Fsh, 3
	NOTE F_, 3
	LEN 20
	NOTE Dsh, 3
	LEN 10
	NOTE Dsh, 3
	NOTE D_, 3
	NOTE Csh, 3
	NEXT
DrumPat_6148:
	db DRUM_LEVEL + 14, 1, 0, 5, 6, 9, 0, 5
	db 6, DRUM_LOOP

; Song 10: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong10:
	call StopAll
	ld a, $6F
	ld [wInstrTableHi], a
	ld a, $93
	ld [wInstrTable], a
	ld de, Song10_Ch1
	call StartMusicCh1
	ld de, Song10_Ch2
	call StartMusicCh2
	ld de, Song10_Ch3
	jp StartMusicCh3

; Unreferenced (1 bytes)
	db $C9
Song10_Ch1:
	dw Pat_61D8
	dw Pat_61D1
	dw Pat_61D8
	dw Pat_61F8
	dw Pat_6246
	dw Pat_61D1
	dw Pat_61D8
	dw Pat_61F8
	dw Pat_6246
	ORDER_LOOP Song10_Ch1
Song10_Ch2:
	dw Pat_6323
	dw Pat_631D
	dw Pat_6323
	dw Pat_62E3
	dw Pat_62F9
	dw Pat_631D
	dw Pat_6323
	dw Pat_62E3
	dw Pat_62F9
	ORDER_LOOP Song10_Ch2
Song10_Ch3:
	dw Pat_6448
	dw Pat_636C
	dw Pat_6390
	dw Pat_63BE
	dw Pat_643C
	dw Pat_636C
	dw Pat_6390
	dw Pat_63BE
	dw Pat_6442
	ORDER_LOOP Song10_Ch3
Pat_61B4:
	LEN 20
	NOTE C_, 2
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	NOTE C_, 2
	LEN 20
	NOTE G_, 2
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	NOTE G_, 2
	LEN 20
	NOTE D_, 2
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	NOTE D_, 2
	LEN 20
	NOTE G_, 2
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	NOTE G_, 2
	NEXT
Pat_61D1:
	INSTR 10
	REPEAT 4
	PAT_CALL Pat_61B4
	REPEAT_END
	NEXT
Pat_61D8:
	INSTR 10
	RELEASE $02, $10
	REPEAT 3
	PAT_CALL Pat_61B4
	REPEAT_END
	LEN 20
	NOTE C_, 2
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	LEN 20
	NOTE A_, 2
	LEN 10
	NOTE G_, 2
	INSTR 5
	NOTE A_, 3
	INSTR 10
	NOTE G_, 2
	LEN 20
	NOTE C_, 2
	INSTR 5
	LEN 40
	NOTE A_, 3
	INSTR 10
	LEN 20
	NOTE G_, 2
	NEXT
Pat_61F8:
	INSTR 10
	REPEAT 2
	LEN 20
	NOTE F_, 2
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	NOTE F_, 2
	LEN 20
	NOTE C_, 3
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	NOTE C_, 3
	REPEAT_END
	REPEAT 2
	LEN 20
	NOTE C_, 2
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	NOTE C_, 2
	LEN 20
	NOTE G_, 2
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	NOTE G_, 2
	REPEAT_END
	REPEAT 2
	LEN 20
	NOTE G_, 2
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	NOTE G_, 2
	LEN 20
	NOTE D_, 2
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	NOTE D_, 2
	REPEAT_END
	LEN 20
	NOTE C_, 2
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	NOTE C_, 2
	LEN 20
	NOTE G_, 2
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	NOTE G_, 2
	LEN 20
	NOTE C_, 3
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	LEN 20
	NOTE C_, 3
	LEN 10
	NOTE G_, 2
	INSTR 5
	NOTE A_, 3
	INSTR 10
	NOTE Fsh, 2
	NEXT
Pat_6246:
	INSTR 10
	LEN 20
	NOTE F_, 2
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	NOTE F_, 2
	LEN 20
	NOTE C_, 3
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	NOTE C_, 3
	LEN 20
	NOTE F_, 3
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	NOTE F_, 3
	LEN 20
	NOTE C_, 3
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	NOTE C_, 3
	LEN 20
	NOTE C_, 2
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	NOTE C_, 2
	LEN 20
	NOTE G_, 2
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	NOTE G_, 2
	LEN 20
	NOTE C_, 3
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	NOTE C_, 3
	LEN 20
	NOTE G_, 2
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	NOTE G_, 2
	REPEAT 2
	LEN 20
	NOTE G_, 2
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	NOTE G_, 2
	LEN 20
	NOTE D_, 2
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	NOTE D_, 2
	REPEAT_END
	LEN 20
	NOTE C_, 2
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 10
	LEN 20
	NOTE G_, 2
	LEN 10
	NOTE G_, 2
	INSTR 5
	NOTE A_, 3
	INSTR 10
	NOTE G_, 2
	LEN 20
	NOTE C_, 3
	INSTR 5
	NOTE A_, 3
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	LEN 5
	NOTE A_, 3
	NOTE A_, 3
	NEXT
Pat_62A8:
	ARP 4
	LEN 20
	NOTE F_, 4
	LEN 10
	NOTE F_, 4
	LEN 20
	NOTE F_, 4
	LEN 10
	NOTE F_, 4
	LEN 20
	NOTE F_, 4
	LEN 10
	NOTE G_, 4
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE F_, 4
	LEN 20
	NOTE F_, 4
	NOTE G_, 4
	NOTE C_, 4
	LEN 10
	NOTE C_, 4
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE C_, 4
	LEN 20
	NOTE C_, 4
	ARP 5
	LEN 10
	NOTE D_, 4
	LEN 20
	NOTE D_, 4
	ARP 4
	LEN 10
	NOTE C_, 4
	LEN 20
	NOTE C_, 4
	NOTE C_, 4
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE G_, 5
	LEN 20
	NOTE G_, 5
	LEN 10
	NOTE G_, 4
	LEN 20
	NOTE G_, 4
	NOTE G_, 4
	NEXT
Pat_62E3:
	PAT_CALL Pat_62A8
	NOTE C_, 5
	LEN 10
	NOTE C_, 5
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE C_, 5
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE C_, 6
	LEN 20
	NOTE C_, 6
	LEN 10
	NOTE C_, 5
	LEN 20
	NOTE C_, 5
	NOTE B_, 4
	NEXT
Pat_62F9:
	PAT_CALL Pat_62A8
	NOTE C_, 5
	LEN 30
	NOTE C_, 5
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE C_, 5
	LENGTH $50
	NOTE C_, 5
	NEXT
Pat_6307:
	LEN 20
	ARP 4
	NOTE C_, 4
	LEN 10
	NOTE C_, 4
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE C_, 4
	LEN 20
	NOTE C_, 4
	ARP 5
	LEN 10
	NOTE D_, 4
	LEN 20
	NOTE D_, 4
	LEN 10
	NOTE E_, 4
	LEN 20
	NOTE E_, 4
	NOTE D_, 4
	NEXT
Pat_631D:
	REPEAT 4
	PAT_CALL Pat_6307
	REPEAT_END
	NEXT
Pat_6323:
	DUTY_50
	HWENV $D1, $07, $20
	AUTODUTY $03
	LEN 20
	REPEAT 3
	PAT_CALL Pat_6307
	REPEAT_END
	ARP 4
	NOTE C_, 4
	LEN 30
	NOTE C_, 4
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE C_, 4
	LEN 20
	NOTE C_, 5
	LENGTH $3C
	NOTE C_, 5
	NEXT
Pat_633E:
	ARP 3
	LENGTH $5A
	NOTE F_, 5
	ARP_OFF
	LEN 10
	NOTE G_, 5
	NOTE F_, 5
	NOTE G_, 5
	LEN 13
	NOTE A_, 5
	NOTE B_, 5
	LEN 14
	NOTE C_, 6
	LEN 12
	ARP 21
	NOTE B_, 5
	LEN 8
	ARP_OFF
	WAIT2
	LEN 10
	NOTE G_, 5
	LENGTH $3C
	NOTE E_, 5
	LEN 10
	NOTE E_, 5
	NOTE D_, 5
	NOTE E_, 5
	LEN 13
	NOTE F_, 5
	NOTE G_, 5
	LEN 14
	NOTE A_, 5
	LEN 12
	ARP 21
	NOTE G_, 5
	LEN 8
	ARP_OFF
	WAIT2
	LEN 10
	NOTE E_, 5
	LENGTH $3C
	NOTE C_, 5
	NEXT
Pat_636C:
	DRUMS $0A, DrumPat_6494
	PAT_CALL Pat_633E
	LEN 10
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	LEN 13
	NOTE A_, 4
	NOTE B_, 4
	LEN 14
	NOTE C_, 5
	LENGTH $5A
	ARP 3
	NOTE F_, 5
	ARP 3
	LEN 10
	NOTE G_, 5
	ARP 21
	NOTE G_, 5
	ARP 3
	NOTE G_, 5
	ARP 21
	NOTE G_, 5
	ARP 3
	NOTE G_, 5
	ARP 21
	NOTE G_, 5
	ARP_OFF
	NOTE G_, 4
	NEXT
Pat_6390:
	PAT_CALL Pat_633E
	LEN 10
	NOTE D_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE G_, 4
	LEN 20
	NOTE E_, 5
	LEN 10
	NOTE D_, 5
	NOTE C_, 5
	WAIT2
	NOTE C_, 5
	LEN 20
	WAIT2
	LEN 10
	NOTE C_, 5
	WAIT2
	NOTE C_, 5
	DRUMS $0A, DrumPat_64AD
	NOTE C_, 5
	VOLENV 15, $12, $1F, $12
	RELEASE $00
	ARP 0
	WAVE Wave_75BA
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE B_, 3
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE B_, 3
	NOTE C_, 4
	NEXT
Pat_63BE:
	DRUMS $0A, DrumPat_6494
	LENGTH $5A
	NOTE A_, 3
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE B_, 3
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE B_, 3
	NOTE C_, 4
	LEN 20
	NOTE E_, 4
	LEN 10
	NOTE C_, 4
	LENGTH $3C
	NOTE G_, 3
	LEN 10
	NOTE G_, 3
	NOTE C_, 4
	NOTE D_, 4
	LEN 13
	NOTE E_, 4
	NOTE F_, 4
	LEN 14
	NOTE E_, 4
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE F_, 4
	LENGTH $3C
	NOTE D_, 4
	LEN 10
	NOTE G_, 3
	NOTE B_, 3
	NOTE C_, 4
	LEN 13
	NOTE D_, 4
	NOTE E_, 4
	LEN 14
	NOTE F_, 4
	LEN 20
	NOTE A_, 4
	LEN 10
	NOTE G_, 4
	LEN 20
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	NOTE C_, 5
	NEXT
Pat_63FF:
	LENGTH $5A
	NOTE A_, 4
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	NOTE C_, 5
	LEN 20
	NOTE E_, 5
	LEN 10
	NOTE C_, 5
	LEN 20
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 10
	NOTE G_, 4
	NOTE C_, 5
	LEN 13
	NOTE D_, 5
	NOTE E_, 5
	LEN 14
	NOTE F_, 5
	LEN 13
	NOTE E_, 5
	NOTE E_, 5
	LEN 14
	NOTE D_, 5
	LENGTH $3C
	NOTE D_, 5
	LEN 10
	NOTE G_, 4
	NOTE B_, 4
	NOTE C_, 5
	LEN 13
	NOTE D_, 5
	NOTE E_, 5
	LEN 14
	NOTE D_, 5
	LEN 20
	NOTE C_, 5
	LEN 30
	NOTE C_, 5
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE C_, 5
	LENGTH $3C
	DRUMS $0A, DrumPat_64BB
	NOTE C_, 5
	NEXT
Pat_643C:
	PAT_CALL Pat_63FF
	PAT_GOTO Pat_6483
Pat_6442:
	PAT_CALL Pat_63FF
	LEN 20
	WAIT2
	NEXT
Pat_6448:
	WAVE Wave_75AA
	DRUMS $0A, DrumPat_6494
	CH_TRANSPOSE $0C
	VOLENV 15, $00, $1F, $12
	ARP 23
	LEN 30
	NOTE A_, 3
	LENGTH $64
	NOTE G_, 3
	LEN 10
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	LEN 30
	NOTE A_, 3
	LENGTH $64
	NOTE G_, 3
	LEN 10
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	LEN 20
	NOTE A_, 3
	LEN 10
	NOTE B_, 3
	LENGTH $64
	NOTE G_, 3
	LEN 10
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	LEN 20
	NOTE C_, 4
	LEN 30
	NOTE C_, 4
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE C_, 4
	DRUMS $0A, DrumPat_64AD
	LENGTH $3C
	NOTE C_, 4
	ARP_OFF
Pat_6483:
	VOLENV 10, $15, $1F, $10
	WAVE Wave_759A
	VIBRATO $19, $01, $04
	RELEASE $02, $53
	LEN 20
	NOTE G_, 4
	NEXT
DrumPat_6494:
	db DRUM_LEVEL + 12, 1, 6, DRUM_LEVEL + 14, 9, DRUM_LEVEL + 12, 1, 1
	db 5, DRUM_LEVEL + 14, 9, DRUM_LEVEL + 12, 6, 1, 6, DRUM_LEVEL + 14
	db 9, DRUM_LEVEL + 12, 1, 1, 5, DRUM_LEVEL + 14, 9, 4
	db DRUM_LOOP
DrumPat_64AD:
	db DRUM_LEVEL + 12, 1, 6, DRUM_LEVEL + 14, 9, DRUM_LEVEL + 12, 6, 5
	db 6, 5, DRUM_TEMPO + 5, 5, 5, DRUM_LOOP
DrumPat_64BB:
	db DRUM_LEVEL + 12, 1, 6, DRUM_LEVEL + 14, 9, DRUM_LEVEL + 14, 1, 9
	db 1, 9, DRUM_TEMPO + 5, 9, 9, DRUM_LOOP

; Song 11: instrument table 2, arpeggio table 1 (the one SndInit sets)
PlaySong11:
	call StopAll
	ld de, Song11_Ch3
	call StartMusicCh3
	ld de, Song11_Ch2
	call StartMusicCh2
	ld de, Song11_Ch1
	jp StartMusicCh1
Song11_Ch3:
	dw Pat_6508
	dw Pat_657B
	dw Pat_658F
	dw Pat_657B
	dw Pat_658F
	ORDER_LOOP Song11_Ch3
Song11_Ch2:
	dw Pat_65A3
	dw Pat_65C7
	dw Pat_65FC
	dw Pat_65C7
	dw Pat_65FC
	ORDER_LOOP Song11_Ch2
Song11_Ch1:
	dw Pat_6634
	dw Pat_665F
	dw Pat_669C
	dw Pat_665F
	dw Pat_669C
	ORDER_LOOP Song11_Ch1
Pat_6508:
	CH_TRANSPOSE $0C
	INSTR 11
	LEN 16
	NOTE C_, 2
	LEN 8
	NOTE C_, 3
	LEN 16
	NOTE C_, 2
	LEN 8
	NOTE C_, 3
	LEN 16
	NOTE C_, 2
	LEN 8
	NOTE C_, 3
	LEN 16
	NOTE C_, 2
	LEN 8
	NOTE C_, 3
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	LEN 16
	NOTE C_, 2
	LEN 8
	NOTE Ash, 2
	LEN 16
	NOTE A_, 2
	LEN 8
	NOTE G_, 2
	NEXT
Pat_652A:
	INSTR 11
	LEN 16
	NOTE F_, 2
	INSTR 4
	LEN 8
	NOTE F_, 4
	INSTR 11
	LEN 16
	NOTE C_, 2
	INSTR 4
	LEN 8
	NOTE F_, 4
	INSTR 11
	LEN 16
	NOTE F_, 2
	INSTR 4
	LEN 8
	NOTE F_, 4
	INSTR 11
	LEN 16
	NOTE C_, 2
	INSTR 4
	LEN 8
	NOTE F_, 4
	INSTR 11
	LEN 16
	NOTE G_, 2
	INSTR 5
	LEN 8
	NOTE G_, 4
	INSTR 11
	LEN 16
	NOTE D_, 2
	INSTR 5
	LEN 8
	NOTE G_, 4
	INSTR 11
	LEN 16
	NOTE G_, 2
	INSTR 5
	LEN 8
	NOTE G_, 4
	INSTR 11
	LEN 16
	NOTE D_, 2
	INSTR 5
	LEN 8
	NOTE G_, 4
	INSTR 11
	LEN 16
	NOTE C_, 2
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 16
	NOTE C_, 3
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
	NOTE C_, 3
	INSTR 4
	LEN 8
	NOTE C_, 4
	INSTR 11
	LEN 16
	NOTE F_, 2
	INSTR 4
	LEN 8
	NOTE F_, 4
	INSTR 11
	LEN 16
	NEXT
Pat_657B:
	PAT_CALL Pat_652A
	NOTE E_, 2
	INSTR 4
	LEN 8
	NOTE F_, 4
	INSTR 11
	LEN 16
	NOTE D_, 2
	INSTR 4
	LEN 8
	NOTE F_, 4
	INSTR 11
	LEN 16
	NOTE C_, 2
	INSTR 4
	LEN 8
	NOTE F_, 4
	NEXT
Pat_658F:
	PAT_CALL Pat_652A
	NOTE C_, 2
	INSTR 4
	LEN 8
	NOTE F_, 4
	INSTR 11
	LEN 16
	NOTE F_, 2
	INSTR 4
	LEN 8
	NOTE F_, 4
	INSTR 11
	LEN 16
	NOTE F_, 2
	INSTR 4
	LEN 8
	NOTE F_, 4
	NEXT
Pat_65A3:
	LENGTH $50
	HWENV $00, $00
	REST
	HWENV $59, $04, $70
	RELEASE $01, $53
	DUTY_50
	VIBRATO $08, $02, $04
	DUTY_75
	ARP 0
	LEN 8
	NOTE C_, 6
	NOTE E_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 5
	NOTE A_, 5
	NOTE B_, 5
	NOTE C_, 6
	WAIT2
	NOTE E_, 5
	NOTE D_, 5
	WAIT2
	NOTE Csh, 5
	NEXT
Pat_65C7:
	LEN 8
	NOTE C_, 5
	WAIT2
	NOTE B_, 4
	NOTE C_, 5
	WAIT2
	NOTE D_, 5
	NOTE C_, 5
	NOTE C_, 6
	NOTE D_, 6
	LEN 16
	NOTE C_, 6
	LEN 8
	WAIT2
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE Csh, 5
	NOTE D_, 5
	WAIT2
	NOTE E_, 5
	NOTE D_, 5
	NOTE D_, 6
	NOTE E_, 6
	LEN 16
	NOTE D_, 6
	LEN 8
	WAIT2
	NOTE G_, 4
	NOTE E_, 5
	NOTE F_, 5
	LEN 16
	NOTE E_, 5
	WAIT2
	LEN 8
	NOTE C_, 5
	NOTE D_, 5
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE Ash, 4
	NOTE A_, 4
	WAIT2
	NOTE F_, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE D_, 5
	LEN 32
	NOTE C_, 5
	LEN 16
	WAIT2
	NEXT
Pat_65FC:
	LEN 8
	NOTE C_, 5
	WAIT2
	NOTE B_, 4
	NOTE C_, 5
	WAIT2
	NOTE D_, 5
	NOTE C_, 5
	NOTE C_, 6
	NOTE D_, 6
	LEN 16
	NOTE C_, 6
	LEN 8
	WAIT2
	LEN 16
	NOTE D_, 5
	LEN 8
	NOTE Csh, 5
	NOTE D_, 5
	WAIT2
	NOTE E_, 5
	NOTE D_, 5
	NOTE D_, 6
	NOTE E_, 6
	LEN 16
	NOTE D_, 6
	LEN 8
	WAIT2
	NOTE G_, 4
	NOTE E_, 5
	NOTE F_, 5
	LEN 16
	NOTE E_, 5
	LEN 8
	NOTE G_, 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE G_, 4
	NOTE Ash, 4
	NOTE A_, 4
	WAIT2
	NOTE C_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE A_, 4
	ARP 4
	NOTE F_, 4
	LEN 16
	WAIT2
	ARP_OFF
	NEXT
Pat_6634:
	DRUMS $08, DrumPat_66DA
	HWENV $79, $02, $A0
	RELEASE $02, $82
	VIBRATO $10, $02, $04
	ARP 0
	DUTY_50
	LEN 8
	NOTE C_, 5
	REST
	NOTE C_, 5
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 5
	LEN 24
	NOTE E_, 5
	LEN 8
	REST
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	LEN 16
	NOTE C_, 5
	LEN 8
	REST
	LEN 24
	NOTE C_, 4
	NEXT
Pat_665F:
	DRUMS $08, DrumPat_66D2
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE Gsh, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE Ash, 4
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE Ash, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE F_, 4
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE A_, 4
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE D_, 4
	LEN 40
	NOTE G_, 4
	LEN 8
	NOTE F_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE D_, 5
	LEN 16
	NOTE C_, 5
	LEN 8
	WAIT2
	NOTE C_, 3
	NOTE C_, 4
	NOTE D_, 4
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE Ash, 3
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE F_, 3
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE D_, 4
	LEN 24
	NOTE C_, 4
	LEN 8
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NEXT
Pat_669C:
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE Gsh, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE Ash, 4
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE Ash, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE F_, 4
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE A_, 4
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE D_, 4
	LEN 40
	NOTE G_, 4
	LEN 8
	NOTE F_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE D_, 5
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE G_, 3
	NOTE C_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	WAIT2
	NOTE C_, 4
	NOTE A_, 3
	WAIT2
	NOTE C_, 4
	LEN 24
	NOTE F_, 3
	LEN 8
	NOTE F_, 4
	LEN 16
	WAIT2
	NEXT
DrumPat_66D2:
	db DRUM_LEVEL + 13, 1, 6, 4, 9, 6, 4, DRUM_LOOP
DrumPat_66DA:
	db DRUM_LEVEL + 13, 1, 0, 6, DRUM_LOOP

; Song 12: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong12:
	call StopAll
	ld a, $6F
	ld [wInstrTableHi], a
	ld a, $93
	ld [wInstrTable], a
	ld de, Song12_Ch1
	call StartMusicCh1
	ld de, Song12_Ch2
	call StartMusicCh2
	ld de, Song12_Ch3
	jp StartMusicCh3
Song12_Ch1:
	dw Pat_6710

; Unreferenced (4 bytes)
	db $00, $00, $FE, $66
Song12_Ch2:
	dw Pat_6730

; Unreferenced (4 bytes)
	db $00, $00, $04, $67
Song12_Ch3:
	dw Pat_6753

; Unreferenced (4 bytes)
	db $00, $00, $0A, $67
Pat_6710:
	TRANSPOSE $01
	INSTR 10
	LEN 21
	NOTE G_, 2
	INSTR 5
	LEN 14
	NOTE A_, 3
	INSTR 10
	LEN 7
	NOTE G_, 2
	LEN 21
	NOTE D_, 2
	INSTR 5
	LEN 14
	NOTE A_, 3
	INSTR 10
	LEN 7
	NOTE D_, 2
	LEN 14
	NOTE C_, 2
	LEN 7
	WAIT
	LEN 14
	NOTE Csh, 2
	HWENV $F2, $00
	LENGTH $A4
	NOTE C_, 2
	END
Pat_6730:
	HWENV $F1, $07, $65
	DUTY_12
	ARP 0
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE Fsh, 3
	ARP 4
	LEN 14
	NOTE G_, 4
	ARP 0
	LEN 7
	NOTE A_, 3
	LEN 14
	NOTE B_, 3
	LEN 7
	NOTE G_, 3
	ARP 4
	LEN 14
	NOTE G_, 4
	ARP 0
	LEN 7
	NOTE B_, 3
	LEN 21
	NOTE C_, 4
	ARP 4
	LEN 14
	NOTE Csh, 4
	LENGTH $A4
	NOTE C_, 4
	END
Pat_6753:
	DRUMS $07, DrumPat_677B
	VOLENV 15, $11, $1F, $12
	ARP 0
	CH_TRANSPOSE $0C
	WAVE Wave_74DA
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE B_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE B_, 4
	LEN 21
	NOTE C_, 5
	LEN 14
	NOTE G_, 4
	NOTE C_, 4
	DRUMS_OFF
	LENGTH $A4
	WAIT
	END
DrumPat_677B:
	db DRUM_LEVEL + 14, 1, 0, 6, 2, 0, 6, 1; no DRUM_LOOP: the pattern runs into the next data
	db 0, 6, 2, 0, 6, 1, 6, 6
	db 7, 0, 7, 0, 0, 0, 0

; Song 13: instrument table 2, arpeggio table 1 (the one SndInit sets)
PlaySong13:
	call StopAll
	ld de, Song13_Ch3
	call StartMusicCh3
	ld de, Song13_Ch2
	call StartMusicCh2
	ld de, Song13_Ch1
	jp StartMusicCh1
Song13_Ch3:
	dw Pat_67B9

; Unreferenced (4 bytes)
	db $00, $00, $A7, $67
Song13_Ch2:
	dw Pat_67D7

; Unreferenced (4 bytes)
	db $00, $00, $AD, $67
Song13_Ch1:
	dw Pat_67FB

; Unreferenced (4 bytes)
	db $00, $00, $B3, $67
Pat_67B9:
	CH_TRANSPOSE $0C
	TRANSPOSE $01
	LEN 14
	DRUMS $07, DrumPat_5833
	REPEAT 3
	INSTR 11
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 4
	NOTE C_, 4
	REPEAT_END
	INSTR 11
	NOTE F_, 2
	NOTE Fsh, 2
	DRUMS_OFF
	CALL_CODE Drum7
	LENGTH $FC
	NOTE G_, 2
	END
Pat_67D7:
	INSTR 13
	LEN 7
	NOTE C_, 4
	WAIT2
	NOTE G_, 3
	WAIT2
	NOTE E_, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE G_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE E_, 5
	NOTE E_, 5
	NOTE D_, 5
	WAIT2
	NOTE C_, 5
	WAIT2
	LEN 14
	NOTE E_, 4
	NOTE A_, 4
	LEN 7
	NOTE B_, 4
	NOTE C_, 5
	LEN 28
	NOTE D_, 5
	LENGTH $D9
	WAIT2
	END
Pat_67FB:
	INSTR 6
	LEN 7
	NOTE C_, 5
	NOTE C_, 5
	LEN 14
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 42
	NOTE E_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE C_, 5
	NOTE C_, 5
	LEN 14
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 7
	NOTE G_, 4
	NOTE A_, 4
	LENGTH $FC
	NOTE G_, 4
	END

; Song 14: instrument table 2, arpeggio table 1 (the one SndInit sets)
PlaySong14:
	call StopAll
	ld de, Song14_Ch3
	call StartMusicCh3
	ld de, Song14_Ch2
	call StartMusicCh2
	ld de, Song14_Ch1
	jp StartMusicCh1
Song14_Ch3:
	dw Pat_683D

; Unreferenced (4 bytes)
	db $00, $00, $2B, $68
Song14_Ch2:
	dw Pat_6887

; Unreferenced (4 bytes)
	db $00, $00, $31, $68
Song14_Ch1:
	dw Pat_68C4

; Unreferenced (4 bytes)
	db $00, $00, $37, $68
Pat_683D:
	CH_TRANSPOSE $0C
	DRUMS $06, DrumPat_68FA
	LEN 12
	INSTR 11
	NOTE Csh, 2
	INSTR 4
	NOTE Csh, 4
	INSTR 11
	NOTE Csh, 2
	INSTR 4
	NOTE Csh, 4
	INSTR 11
	NOTE Csh, 2
	INSTR 4
	NOTE Csh, 4
	INSTR 11
	NOTE Csh, 2
	INSTR 4
	LEN 6
	NOTE Csh, 4
	INSTR 11
	NOTE Csh, 2
	LEN 12
	NOTE Gsh, 2
	INSTR 4
	NOTE Gsh, 4
	INSTR 11
	NOTE Gsh, 2
	INSTR 4
	NOTE Gsh, 4
	INSTR 11
	NOTE Gsh, 2
	INSTR 4
	NOTE Gsh, 4
	INSTR 11
	NOTE Gsh, 2
	INSTR 4
	LEN 6
	NOTE Gsh, 4
	INSTR 11
	NOTE Dsh, 2
	LEN 12
	NOTE Gsh, 2
	INSTR 4
	NOTE Gsh, 4
	INSTR 11
	NOTE Gsh, 2
	INSTR 4
	NOTE Gsh, 4
	INSTR 11
	NOTE Gsh, 2
	INSTR 4
	LEN 6
	NOTE Gsh, 4
	INSTR 11
	NOTE Fsh, 2
	LEN 12
	NOTE F_, 2
	NOTE Dsh, 2
	LEN 24
	NOTE Csh, 2
	NOTE Gsh, 2
	DRUMS_OFF
	CALL_CODE Drum7
	LENGTH $30
	NOTE Csh, 3
	END
Pat_6887:
	HWENV $A2, $00
	ARP_OFF
	DUTY_50
	LEN 12
	NOTE Csh, 4
	NOTE Gsh, 3
	NOTE F_, 4
	NOTE Csh, 4
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE Csh, 5
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 6
	NOTE Fsh, 4
	NOTE F_, 4
	LEN 12
	NOTE Dsh, 4
	NOTE Gsh, 4
	LEN 6
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	LEN 12
	NOTE Gsh, 3
	LEN 6
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Fsh, 4
	LEN 12
	NOTE Gsh, 4
	LEN 6
	NOTE Fsh, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Gsh, 3
	LEN 12
	NOTE Csh, 4
	LEN 6
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	LENGTH $30
	NOTE Csh, 5
	END
Pat_68C4:
	INSTR 13
	LENGTH $36
	NOTE Csh, 6
	LEN 6
	WAIT2
	NOTE Csh, 6
	WAIT2
	NOTE C_, 6
	WAIT2
	NOTE Ash, 5
	WAIT2
	LENGTH $36
	NOTE Gsh, 5
	LEN 6
	WAIT2
	NOTE Gsh, 5
	WAIT2
	NOTE Fsh, 5
	WAIT2
	NOTE F_, 5
	WAIT2
	LEN 12
	NOTE Dsh, 5
	LEN 6
	NOTE Ash, 5
	WAIT2
	NOTE Gsh, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	LEN 12
	NOTE C_, 5
	LEN 6
	NOTE Gsh, 5
	WAIT2
	NOTE Gsh, 4
	WAIT2
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	WAIT2
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE Fsh, 5
	NOTE Gsh, 5
	NOTE Ash, 5
	NOTE C_, 6
	LEN 18
	NOTE Csh, 6
	LEN 30
	WAIT2
	END
DrumPat_68FA:
	db DRUM_LEVEL + 14, 1, 0, 5, 6, 2, 0, 5
	db 6, DRUM_LOOP

; Song 15: instrument table 2, arpeggio table 1 (the one SndInit sets)
PlaySong15:
	call StopAll
	ld de, Song15_Ch3
	call StartMusicCh3
	ld de, Song15_Ch2
	call StartMusicCh2
	ld de, Song15_Ch1
	jp StartMusicCh1
Song15_Ch3:
	dw Pat_6A72
	dw Pat_6973
	dw Pat_69CC
	dw Pat_69F7
	dw Pat_6A25
	dw Pat_6973
	dw Pat_69CC
	dw Pat_69F7
	dw Pat_6A25
	dw Pat_6975
	dw Pat_69CC
	dw Pat_6975
	dw Pat_69CC
	ORDER_LOOP Song15_Ch3
Song15_Ch2:
	dw Pat_6AB8
	dw Pat_6AAF
	dw Pat_6B47
	dw Pat_6B4F
	dw Pat_6B80
	dw Pat_6AAF
	dw Pat_6B47
	dw Pat_6B4F
	dw Pat_6B80
	dw Pat_6AE2
	dw Pat_6B06
	dw Pat_6AE2
	dw Pat_6B06
	ORDER_LOOP Song15_Ch2
Song15_Ch1:
	dw Pat_6BAB
	dw Pat_6B34
	dw Pat_6B47
	dw Pat_6B4F
	dw Pat_6B80
	dw Pat_6B34
	dw Pat_6B47
	dw Pat_6B4F
	dw Pat_6B80
	dw Pat_6BD2
	dw Pat_6C01
	dw Pat_6BD2
	dw Pat_6C01
	ORDER_LOOP Song15_Ch1
Pat_6973:
	CH_TRANSPOSE $0C
Pat_6975:
	INSTR 11
	REPEAT 2
	LEN 21
	NOTE F_, 2
	INSTR 4
	LEN 14
	NOTE F_, 4
	INSTR 11
	LEN 7
	NOTE F_, 2
	LEN 21
	NOTE C_, 2
	INSTR 4
	LEN 14
	NOTE F_, 4
	INSTR 11
	LEN 7
	NOTE C_, 2
	REPEAT_END
	LEN 21
	NOTE Dsh, 2
	INSTR 4
	LEN 14
	NOTE Dsh, 4
	INSTR 11
	LEN 7
	NOTE Dsh, 2
	LEN 21
	NOTE Dsh, 2
	INSTR 4
	LEN 14
	NOTE Dsh, 4
	INSTR 11
	LEN 7
	NOTE C_, 2
	LEN 14
	NOTE C_, 3
	INSTR 4
	LEN 7
	NOTE C_, 4
	INSTR 11
	LEN 14
	NOTE Ash, 2
	INSTR 4
	LEN 7
	NOTE C_, 4
	INSTR 11
	LEN 14
	NOTE A_, 2
	INSTR 4
	LEN 7
	NOTE C_, 4
	INSTR 11
	LEN 14
	NOTE G_, 2
	INSTR 4
	LEN 7
	NOTE C_, 4
	NEXT
Pat_69B0:
	INSTR 11
	LEN 21
	NOTE F_, 2
	INSTR 4
	LEN 14
	NOTE F_, 4
	INSTR 11
	LEN 7
	NOTE F_, 2
	LEN 21
	NOTE C_, 2
	INSTR 4
	LEN 14
	NOTE F_, 4
	INSTR 11
	LEN 7
	NOTE C_, 2
	LEN 21
	NOTE F_, 2
	INSTR 4
	LEN 14
	NOTE F_, 4
	INSTR 11
	LEN 7
	NOTE F_, 2
	LEN 21
	NOTE C_, 2
	NEXT
Pat_69CC:
	PAT_CALL Pat_69B0
	NOTE F_, 2
	NOTE Dsh, 2
	INSTR 4
	LEN 14
	NOTE Dsh, 4
	INSTR 11
	LEN 7
	NOTE Dsh, 2
	LEN 21
	NOTE Dsh, 2
	INSTR 4
	LEN 14
	NOTE Dsh, 4
	INSTR 11
	LEN 7
	NOTE Dsh, 2
	LEN 14
	NOTE C_, 2
	INSTR 4
	LEN 7
	NOTE C_, 4
	INSTR 11
	LEN 14
	NOTE D_, 2
	INSTR 4
	LEN 7
	NOTE C_, 4
	INSTR 11
	LEN 14
	NOTE Dsh, 2
	INSTR 4
	LEN 7
	NOTE C_, 4
	INSTR 11
	LEN 14
	NOTE E_, 2
	INSTR 4
	LEN 7
	NOTE C_, 4
	NEXT
Pat_69F7:
	INSTR 11
	PAT_CALL Pat_69B0
	INSTR 4
	LEN 14
	NOTE F_, 4
	INSTR 11
	LEN 7
	NOTE F_, 2
	LEN 21
	NOTE Ash, 2
	INSTR 4
	LEN 14
	NOTE Ash, 4
	INSTR 11
	LEN 7
	NOTE Ash, 2
	LEN 21
	NOTE F_, 2
	INSTR 4
	LEN 14
	NOTE Ash, 4
	INSTR 11
	LEN 7
	NOTE F_, 2
	LEN 21
	NOTE Ash, 2
	INSTR 4
	LEN 14
	NOTE Ash, 4
	INSTR 11
	LEN 7
	NOTE Ash, 2
	LEN 14
	NOTE F_, 2
	INSTR 4
	LEN 7
	NOTE Ash, 4
	INSTR 11
	LEN 14
	NOTE Ash, 2
	INSTR 4
	LEN 7
	NOTE Ash, 4
	NEXT
Pat_6A25:
	INSTR 11
	LEN 21
	NOTE Dsh, 2
	INSTR 4
	LEN 14
	NOTE Dsh, 4
	INSTR 11
	LEN 7
	NOTE Dsh, 2
	LEN 21
	NOTE Ash, 2
	INSTR 4
	LEN 14
	NOTE Dsh, 4
	INSTR 11
	LEN 7
	NOTE Ash, 2
	LEN 21
	NOTE Dsh, 2
	INSTR 4
	LEN 14
	NOTE Dsh, 4
	INSTR 11
	LEN 7
	NOTE Dsh, 2
	LEN 14
	NOTE Ash, 2
	INSTR 4
	LEN 7
	NOTE Dsh, 4
	INSTR 11
	LEN 14
	NOTE G_, 2
	INSTR 4
	LEN 7
	NOTE Dsh, 4
	INSTR 11
	LEN 21
	NOTE C_, 2
	INSTR 4
	LEN 14
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE C_, 2
	LEN 21
	NOTE G_, 2
	INSTR 4
	LEN 14
	NOTE C_, 4
	INSTR 11
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE C_, 2
	INSTR 4
	LEN 7
	NOTE C_, 4
	INSTR 11
	LEN 14
	NOTE D_, 2
	INSTR 4
	LEN 7
	NOTE D_, 4
	INSTR 11
	LEN 14
	NOTE Dsh, 2
	INSTR 4
	LEN 7
	NOTE Dsh, 4
	INSTR 11
	LEN 14
	NOTE E_, 2
	INSTR 4
	LEN 7
	NOTE E_, 4
	NEXT
Pat_6A72:
	CH_TRANSPOSE $0C
	DRUMS $07, DrumPat_6C2F
	INSTR 11
	LEN 21
	NOTE F_, 2
	INSTR 4
	LEN 14
	NOTE F_, 4
	INSTR 11
	LEN 7
	NOTE F_, 2
	LEN 21
	NOTE C_, 2
	INSTR 4
	LEN 14
	NOTE F_, 4
	INSTR 11
	LEN 7
	NOTE C_, 2
	LEN 21
	NOTE F_, 2
	INSTR 4
	LEN 14
	NOTE F_, 4
	INSTR 11
	LEN 7
	NOTE F_, 2
	LEN 21
	NOTE C_, 3
	INSTR 4
	LEN 14
	NOTE F_, 4
	INSTR 11
	LEN 7
	NOTE C_, 3
	LEN 21
	NOTE F_, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE C_, 3
	LEN 14
	NOTE Ash, 2
	LEN 7
	NOTE C_, 3
	LEN 14
	NOTE D_, 3
	LEN 21
	NOTE C_, 3
	INSTR 4
	LEN 7
	NOTE C_, 5
	INSTR 11
	LEN 14
	NOTE C_, 2
	LEN 7
	NOTE C_, 3
	NEXT
Pat_6AAF:
	HWENV $40, $00
	CH_TRANSPOSE $0C
	PAT_GOTO Pat_6B3C

; Unreferenced (1 bytes)
	db $6A
Pat_6AB8:
	HWENV $F1, $07, $50
	DUTY_50
	VIBRATO $07, $02, $04
	LEN 21
	NOTE A_, 3
	LEN 14
	NOTE F_, 3
	LEN 42
	NOTE C_, 3
	LEN 7
	NOTE C_, 3
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE A_, 3
	LEN 42
	NOTE C_, 4
	LEN 7
	NOTE C_, 4
	LEN 21
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	LENGTH $31
	NOTE E_, 4
	NEXT
Pat_6AE2:
	CH_TRANSPOSE $00
	LEN 21
	NOTE C_, 3
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE F_, 3
	NOTE E_, 3
	NOTE F_, 3
	LEN 42
	NOTE A_, 3
	LEN 7
	NOTE C_, 3
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE C_, 4
	LEN 21
	NOTE Ash, 3
	NOTE A_, 3
	LEN 14
	NOTE Ash, 3
	LENGTH $3F
	NOTE G_, 3
	LEN 7
	NOTE C_, 3
	LEN 14
	NOTE D_, 3
	LEN 7
	NOTE E_, 3
	NEXT
Pat_6B06:
	CH_TRANSPOSE $F4
	PAT_CALL Pat_6C01
	CH_TRANSPOSE $00
	NEXT
Pat_6B0E:
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE Gsh, 4
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE Gsh, 4
	LEN 14
	NOTE A_, 4
	LEN 21
	NOTE C_, 5
	LEN 7
	NOTE Gsh, 4
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE A_, 4
	LEN 21
	NOTE F_, 4
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE C_, 4
	LEN 21
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE D_, 4
	LEN 21
	NOTE C_, 4
	NEXT
Pat_6B34:
	HWENV $F2, $0E, $47
	VIBRATO $07, $02, $04
Pat_6B3C:
	PAT_CALL Pat_6B0E
	LEN 14
	NOTE E_, 4
	LEN 21
	NOTE E_, 4
	LENGTH $31
	NOTE E_, 4
	NEXT
Pat_6B47:
	PAT_CALL Pat_6B0E
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	NEXT
Pat_6B4F:
	LEN 14
	WAIT
	LEN 7
	NOTE Gsh, 4
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE Gsh, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE C_, 5
	LEN 7
	NOTE Gsh, 4
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE A_, 4
	LENGTH $3F
	NOTE F_, 4
	LEN 7
	NOTE Csh, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE Csh, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE Csh, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE Csh, 4
	LENGTH $31
	NOTE D_, 4
	NEXT
Pat_6B80:
	LEN 14
	WAIT
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE Ash, 4
	LEN 14
	NOTE Fsh, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE Fsh, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE Ash, 4
	LEN 14
	NOTE Fsh, 4
	LEN 21
	NOTE G_, 4
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE C_, 4
	LEN 21
	NOTE E_, 4
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE C_, 5
	LEN 14
	NOTE Ash, 4
	LEN 21
	NOTE A_, 4
	LEN 28
	NOTE G_, 4
	NEXT
Pat_6BAB:
	HWENV $C1, $07, $43
	DUTY_12
	ARP 0
	LEN 21
	NOTE A_, 4
	LEN 14
	NOTE F_, 4
	LEN 42
	NOTE C_, 4
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE A_, 4
	LEN 42
	NOTE C_, 5
	LEN 7
	NOTE C_, 5
	LEN 21
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE C_, 5
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE D_, 5
	LENGTH $31
	NOTE C_, 5
	NEXT
Pat_6BD2:
	HWENV $F1, $07, $67
	DUTY_50
	ARP_OFF
	LEN 21
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 42
	NOTE A_, 4
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE C_, 5
	LEN 7
	NOTE C_, 5
	LEN 21
	NOTE Ash, 4
	NOTE A_, 4
	LEN 14
	NOTE Ash, 4
	LEN 21
	NOTE G_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE E_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE E_, 4
	NEXT
Pat_6C01:
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE A_, 4
	LEN 21
	NOTE C_, 5
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE C_, 5
	LEN 7
	NOTE D_, 5
	LEN 14
	NOTE C_, 5
	LEN 7
	NOTE D_, 5
	LEN 14
	NOTE E_, 5
	LEN 21
	NOTE F_, 5
	LEN 7
	NOTE G_, 5
	LEN 14
	NOTE A_, 5
	LEN 7
	NOTE F_, 5
	LEN 21
	NOTE G_, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE A_, 5
	LEN 14
	NOTE G_, 5
	LEN 7
	NOTE A_, 5
	LEN 14
	NOTE Ash, 5
	LEN 21
	NOTE C_, 6
	LEN 7
	NOTE D_, 6
	LEN 21
	NOTE C_, 6
	NEXT
DrumPat_6C2F:
	db DRUM_LEVEL + 13, 1, 0, 6, 9, 0, 6, DRUM_LOOP

; Song 16: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong16:
	call StopAll
	ld a, $6F
	ld [wInstrTableHi], a
	ld a, $93
	ld [wInstrTable], a
	ld de, Song16_Ch1
	call StartMusicCh1
	ld de, Song16_Ch3
	call StartMusicCh3
	ld de, Song16_Ch2
	jp StartMusicCh2
Song16_Ch1:
	dw Pat_6C91
	dw Pat_6CD5
	dw Pat_6C8C
	dw Pat_6CD5
	dw Pat_6D19
	dw Pat_6D2D
	dw Pat_6D2D
	ORDER_LOOP Song16_Ch1
Song16_Ch3:
	dw Pat_6D72
	dw Pat_6D92
	dw Pat_6D72
	dw Pat_6D92
	dw Pat_6DE3
	dw Pat_6DFD
	dw Pat_6DFD
	ORDER_LOOP Song16_Ch3
Song16_Ch2:
	dw Pat_6E52
	dw Pat_6E92
	dw Pat_6E52
	dw Pat_6E92
	dw Pat_6EFD
	dw Pat_6F3D
	dw Pat_6F3D
	ORDER_LOOP Song16_Ch2
Pat_6C8C:
	DUTY_75
	ARP 0
	PAT_GOTO Pat_6C9F
Pat_6C91:
	TRANSPOSE $02
	HWENV $D2, $0C, $60
	VIBRATO $0C, $02, $05
	DUTY_50
	RELEASE $06, $53
Pat_6C9F:
	LEN 12
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 36
	NOTE G_, 4
	LEN 12
	NOTE D_, 4
	NOTE E_, 4
	LEN 24
	NOTE F_, 4
	LEN 12
	NOTE G_, 4
	LEN 24
	NOTE E_, 4
	NOTE C_, 4
	LENGTH $9C
	NOTE G_, 3
	LEN 12
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 36
	NOTE G_, 4
	LEN 12
	NOTE D_, 4
	NOTE E_, 4
	LEN 24
	NOTE F_, 4
	LEN 12
	NOTE G_, 4
	LEN 24
	NOTE E_, 4
	NOTE C_, 4
	NOTE C_, 5
	LEN 12
	NOTE C_, 5
	NOTE B_, 4
	LEN 36
	NOTE Ash, 4
	LEN 24
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	NEXT
Pat_6CD5:
	LEN 12
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 5
	LEN 36
	NOTE A_, 4
	LEN 12
	NOTE B_, 4
	NOTE C_, 5
	LEN 24
	NOTE D_, 5
	LEN 12
	NOTE C_, 5
	LEN 24
	NOTE G_, 4
	NOTE E_, 4
	NOTE G_, 4
	LEN 12
	NOTE E_, 4
	NOTE G_, 4
	LENGTH $48
	NOTE A_, 4
	LEN 12
	NOTE E_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 24
	NOTE Fsh, 4
	LEN 12
	NOTE A_, 4
	LEN 24
	NOTE D_, 5
	NOTE C_, 5
	LEN 12
	NOTE A_, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	LEN 24
	NOTE D_, 5
	NOTE C_, 5
	LEN 12
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	LEN 24
	NOTE G_, 4
	LEN 12
	NOTE A_, 4
	NOTE B_, 4
	LEN 24
	NOTE F_, 4
	LEN 12
	NOTE G_, 4
	NOTE A_, 4
	LEN 24
	NOTE B_, 3
	LEN 12
	NOTE G_, 3
	LEN 24
	NOTE G_, 4
	NEXT
Pat_6D19:
	LENGTH $60
	NOTE C_, 4
	LEN 12
	NOTE C_, 4
	NOTE C_, 4
	LEN 36
	NOTE C_, 5
	HWENV $90, $00
	ARP_OFF
	DUTY_50
	RELEASE $00
	LEN 12
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NEXT
Pat_6D2D:
	LENGTH $9C
	NOTE A_, 4
	LEN 12
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	LEN 36
	NOTE A_, 4
	NOTE E_, 4
	LENGTH $54
	NOTE G_, 4
	LEN 12
	NOTE G_, 4
	NOTE C_, 5
	NOTE B_, 4
	LENGTH $9C
	NOTE D_, 5
	LEN 12
	NOTE G_, 4
	NOTE D_, 5
	NOTE C_, 5
	LEN 24
	NOTE E_, 5
	LEN 12
	NOTE C_, 5
	LEN 24
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 12
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NEXT
Pat_6D56:
	REPEAT 2
	INSTR 2
	LEN 12
	NOTE C_, 3
	NOTE E_, 3
	INSTR 0
	LEN 24
	NOTE A_, 3
	REPEAT_END
	REPEAT 2
	INSTR 2
	LEN 12
	NOTE D_, 3
	NOTE F_, 3
	INSTR 0
	LEN 24
	NOTE A_, 3
	REPEAT_END
	REPEAT 2
	INSTR 2
	LEN 12
	NOTE C_, 3
	NOTE E_, 3
	INSTR 0
	LEN 24
	NOTE A_, 3
	REPEAT_END
	NEXT
Pat_6D72:
	CH_TRANSPOSE $0C
	PAT_CALL Pat_6D56
	REPEAT 2
	INSTR 2
	LEN 12
	NOTE G_, 3
	NOTE B_, 3
	INSTR 0
	LEN 24
	NOTE A_, 3
	REPEAT_END
	PAT_CALL Pat_6D56
	INSTR 2
	LEN 12
	NOTE Ash, 3
	NOTE F_, 3
	INSTR 0
	LEN 24
	NOTE A_, 3
	INSTR 2
	LEN 12
	NOTE C_, 4
	NOTE Ash, 3
	INSTR 0
	LEN 24
	NOTE A_, 3
	NEXT
Pat_6D92:
	REPEAT 2
	INSTR 2
	LEN 12
	NOTE F_, 3
	NOTE A_, 3
	INSTR 0
	LEN 24
	NOTE A_, 3
	REPEAT_END
	REPEAT 2
	INSTR 2
	LEN 12
	NOTE G_, 3
	NOTE B_, 3
	INSTR 0
	LEN 24
	NOTE A_, 3
	REPEAT_END
	REPEAT 2
	INSTR 2
	LEN 12
	NOTE C_, 3
	NOTE E_, 3
	INSTR 0
	LEN 24
	NOTE A_, 3
	REPEAT_END
	REPEAT 2
	INSTR 2
	LEN 12
	NOTE E_, 3
	NOTE A_, 3
	INSTR 0
	LEN 24
	NOTE A_, 3
	REPEAT_END
	REPEAT 3
	INSTR 2
	LEN 12
	NOTE Fsh, 3
	NOTE A_, 3
	INSTR 0
	LEN 24
	NOTE A_, 3
	REPEAT_END
	INSTR 2
	LEN 12
	NOTE A_, 3
	NOTE D_, 4
	INSTR 0
	LEN 24
	NOTE A_, 3
	INSTR 2
	LEN 12
	NOTE G_, 3
	NOTE D_, 3
	INSTR 0
	NOTE A_, 3
	INSTR 2
	LEN 24
	NOTE F_, 3
	LEN 12
	NOTE F_, 3
	INSTR 0
	NOTE A_, 3
	INSTR 2
	NOTE D_, 3
	NOTE G_, 3
	NOTE D_, 3
	INSTR 0
	NOTE A_, 3
	INSTR 2
	LEN 24
	NOTE A_, 3
	LEN 12
	NOTE G_, 3
	INSTR 0
	NOTE A_, 3
	INSTR 2
	NOTE G_, 3
	NEXT
Pat_6DE3:
	INSTR 2
	LEN 12
	NOTE C_, 3
	NOTE E_, 3
	INSTR 0
	NOTE A_, 3
	INSTR 2
	LEN 24
	NOTE G_, 3
	LEN 12
	NOTE G_, 3
	INSTR 0
	NOTE A_, 3
	INSTR 2
	NOTE A_, 3
	INSTR 0
	NOTE A_, 3
	NOTE A_, 3
	LENGTH $30
	NOTE A_, 3
	INSTR 14
	LEN 12
	NOTE G_, 4
	NOTE A_, 4
	NEXT
Pat_6DFD:
	INSTR 14
	LEN 12
	NOTE B_, 4
	NOTE A_, 4
	REPEAT 3
	INSTR 0
	LEN 12
	NOTE A_, 3
	INSTR 14
	LEN 36
	NOTE A_, 4
	REPEAT_END
	INSTR 0
	LEN 12
	NOTE A_, 3
	INSTR 14
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 14
	NOTE A_, 4
	LEN 24
	NOTE E_, 4
	REPEAT 2
	INSTR 0
	LEN 12
	NOTE A_, 3
	INSTR 14
	LEN 36
	NOTE G_, 4
	REPEAT_END
	INSTR 0
	LEN 12
	NOTE A_, 3
	INSTR 14
	NOTE C_, 5
	NOTE B_, 4
	NOTE D_, 5
	INSTR 0
	NOTE A_, 3
	INSTR 14
	LEN 36
	NOTE D_, 5
	REPEAT 2
	INSTR 0
	LEN 12
	NOTE A_, 3
	INSTR 14
	LEN 36
	NOTE D_, 5
	REPEAT_END
	INSTR 0
	LEN 12
	NOTE A_, 3
	INSTR 14
	NOTE D_, 5
	NOTE C_, 5
	NOTE E_, 5
	INSTR 0
	NOTE A_, 3
	INSTR 14
	NOTE C_, 5
	LEN 24
	NOTE A_, 4
	INSTR 0
	LEN 12
	NOTE A_, 3
	INSTR 14
	NOTE Gsh, 4
	LEN 24
	NOTE G_, 4
	INSTR 0
	LEN 12
	NOTE A_, 3
	INSTR 14
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 14
	NOTE G_, 4
	NEXT
Pat_6E52:
	DRUMS $06, DrumPat_6F65
	INSTR 11
	REPEAT 3
	LEN 24
	NOTE C_, 2
	INSTR 6
	LEN 12
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	LEN 24
	NOTE G_, 2
	INSTR 6
	LEN 12
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	LEN 24
	NOTE G_, 2
	INSTR 6
	LEN 12
	NOTE G_, 4
	INSTR 11
	NOTE D_, 2
	LEN 24
	NOTE D_, 2
	INSTR 6
	LEN 12
	NOTE G_, 4
	INSTR 11
	NOTE C_, 2
	REPEAT_END
	LEN 24
	NOTE C_, 2
	INSTR 6
	LEN 12
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	LEN 24
	NOTE G_, 2
	INSTR 6
	LEN 12
	NOTE C_, 4
	INSTR 11
	NOTE Ash, 2
	LEN 24
	NOTE Ash, 2
	INSTR 6
	LEN 12
	NOTE C_, 4
	INSTR 11
	NOTE E_, 2
	LEN 24
	NOTE E_, 2
	INSTR 6
	LEN 12
	NOTE C_, 4
	INSTR 11
	NOTE E_, 2
	NEXT
Pat_6E92:
	INSTR 11
	LEN 24
	NOTE F_, 2
	INSTR 6
	LEN 12
	NOTE F_, 4
	INSTR 11
	NOTE C_, 3
	LEN 24
	NOTE C_, 3
	INSTR 6
	LEN 12
	NOTE F_, 4
	INSTR 11
	NOTE G_, 2
	LEN 24
	NOTE G_, 2
	INSTR 6
	LEN 12
	NOTE G_, 4
	INSTR 11
	NOTE D_, 3
	LEN 24
	NOTE D_, 3
	INSTR 6
	LEN 12
	NOTE G_, 4
	INSTR 11
	NOTE G_, 2
	LEN 24
	NOTE C_, 2
	INSTR 6
	LEN 12
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	LEN 24
	NOTE G_, 2
	INSTR 6
	LEN 12
	NOTE C_, 4
	INSTR 11
	NOTE A_, 2
	LEN 24
	NOTE A_, 2
	INSTR 6
	LEN 12
	NOTE A_, 3
	INSTR 11
	NOTE E_, 2
	LEN 24
	NOTE E_, 2
	INSTR 6
	LEN 12
	NOTE A_, 3
	INSTR 11
	NOTE A_, 2
	LEN 24
	NOTE D_, 2
	INSTR 6
	LEN 12
	NOTE D_, 4
	INSTR 11
	NOTE A_, 2
	LEN 24
	NOTE A_, 2
	INSTR 6
	LEN 12
	NOTE D_, 4
	INSTR 11
	NOTE D_, 2
	LEN 24
	NOTE D_, 2
	INSTR 6
	LEN 12
	NOTE D_, 4
	INSTR 11
	NOTE A_, 2
	LEN 24
	NOTE A_, 2
	INSTR 6
	LEN 12
	NOTE D_, 4
	INSTR 11
	NOTE G_, 2
	LEN 24
	NOTE G_, 2
	INSTR 6
	LEN 12
	NOTE G_, 4
	INSTR 11
	NOTE D_, 2
	LEN 24
	NOTE D_, 2
	INSTR 6
	LEN 12
	NOTE G_, 4
	INSTR 11
	LEN 24
	NOTE G_, 2
	LEN 12
	NOTE G_, 2
	LEN 24
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NEXT
Pat_6EFD:
	INSTR 11
	LEN 24
	NOTE C_, 2
	INSTR 6
	LEN 12
	NOTE C_, 4
	INSTR 11
	LEN 24
	NOTE G_, 2
	LEN 12
	NOTE G_, 2
	INSTR 6
	NOTE C_, 4
	INSTR 11
	NOTE A_, 2
	NOTE C_, 3
	NOTE C_, 3
	LENGTH $48
	NOTE C_, 3
	NEXT
Pat_6F12:
	LEN 24
	NOTE G_, 2
	INSTR 6
	LEN 12
	NOTE G_, 4
	INSTR 11
	NOTE D_, 2
	LEN 24
	NOTE D_, 2
	INSTR 6
	LEN 12
	NOTE G_, 4
	INSTR 11
	NOTE G_, 2
	LEN 24
	NOTE G_, 2
	INSTR 6
	LEN 12
	NOTE G_, 4
	INSTR 11
	NOTE D_, 2
	LEN 24
	NOTE D_, 2
	INSTR 6
	LEN 12
	NOTE G_, 4
	INSTR 11
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	INSTR 6
	LEN 12
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	LEN 24
	NOTE G_, 2
	INSTR 6
	LEN 12
	NOTE C_, 4
	INSTR 11
	NOTE C_, 3
	NEXT
Pat_6F3D:
	DRUMS $06, DrumPat_6F7A
	INSTR 11
	PAT_CALL Pat_6F12
	LEN 24
	NOTE C_, 3
	INSTR 6
	LEN 12
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	LEN 24
	NOTE G_, 2
	INSTR 6
	LEN 12
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	PAT_CALL Pat_6F12
	LEN 24
	NOTE C_, 3
	INSTR 6
	LEN 12
	NOTE C_, 4
	INSTR 11
	LEN 24
	NOTE G_, 2
	LEN 12
	NOTE E_, 2
	INSTR 6
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	NEXT
DrumPat_6F65:
	db DRUM_REPEAT + 3, DRUM_LEVEL + 13, 1, 0, 6, 0, 9, 0
	db 1, 0, DRUM_REPEAT_END, 1, 0, 6, 0, 9
	db 6, DRUM_LEVEL + 15, 4, 0, DRUM_LOOP
DrumPat_6F7A:
	db DRUM_REPEAT + 3, DRUM_LEVEL + 13, 1, 0, 5, 6, 9, 0
	db 1, 6, DRUM_REPEAT_END, 1, 0, 4, 6, 9
	db 6, DRUM_LEVEL + 15, 4, 0, DRUM_LOOP

; Unreferenced (6 bytes)
	db $69, $00, $6A, $69, $02, $6A

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
	dw Instr1_11
	dw Instr1_12
	dw Instr1_12
	dw Instr1_12

; Unreferenced (4 bytes)
	db $19, $70, $19, $70
Instr1_0:
	VOLENV 15, $11, $2F, $12
	GLIDE $FE
	ARP 18
	WAVE Wave_756A
	END
Instr1_1:
	VOLENV 15, $11, $1A, $12
	ARP 4
	WAVE Wave_74CA
	END
Instr1_2:
	VOLENV 10, $11, $1F, $11
	ARP 0
	WAVE Wave_74DA
	END
Instr1_3:
	VOLENV 15, $11, $1F, $12
	ARP 0
	WAVE Wave_753A
	END
Instr1_4:
	HWENV $F2, $00
	ARP 0
	DUTY_75
	END
Instr1_5:
	HWENV $F1, $04, $51
	GLIDE $FE
	DUTY_50
	END
Instr1_6:
	HWENV $F1, $00
	ARP 4
	AUTODUTY $04
	END
Instr1_7:
	HWENV $F1, $00
	ARP 5
	AUTODUTY $04
	END
Instr1_8:
	HWENV $D1, $00
	DUTY_12
	END
Instr1_9:
	HWENV $D2, $00
	DUTY_50
	END
Instr1_10:
	HWENV $F2, $0A, $50
	ARP 0
	DUTY_50
	END
Instr1_11:
	HWENV $F1, $0C, $50
	ARP 0
	DUTY_50
	END
Instr1_12:
	VOLENV 10, $00, $00, $00
	WAVE Wave_74CA
	END

; Unreferenced (9 bytes)
	db $BF, $11, $1F, $12, $94, $79, $3A, $75, $68

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
	VOLENV 15, $11, $1F, $11
	ARP 18
	WAVE Wave_756A
	END
Instr2_2:
	HWENV $F2, $04, $75
	DUTY_50
	ARP 0
	END
Instr2_3:
	HWENV $C2, $04, $72
	DUTY_75
	ARP 12
	END
Instr2_4:
	VOLENV 13, $11, $18, $11
	ARP 4
	WAVE Wave_75DA
	END
Instr2_5:
	VOLENV 13, $11, $18, $11
	ARP 5
	WAVE Wave_75DA
	END
Instr2_6:
	HWENV $E1, $08, $55
	RELEASE $00
	VIBRATO $08, $01, $02
	DUTY_50
	ARP 0
	END
Instr2_7:
	VOLENV 13, $11, $1F, $12
	WAVE Wave_74CA
	END

; Unreferenced (6 bytes)
	db $BF, $11, $1F, $14, $94, $68
Instr2_8:
	HWENV $B1, $00
	ARP 0
	END
Instr2_9:
	HWENV $91, $04, $52
	DUTY_12
	ARP 0
	RELEASE $00
	END
Instr2_10:
	VOLENV 15, $11, $1F, $1F
	ARP 1
	WAVE Wave_756A
	END
Instr2_11:
	VOLENV 15, $11, $1F, $12
	ARP 1
	WAVE Wave_753A
	END
Instr2_12:
	VOLENV 11, $11, $1F, $11
	ARP_OFF
	WAVE Wave_754A
	END
Instr2_13:
	HWENV $A0, $00
	DUTY_75
	RELEASE $02, $52
	VIBRATO $12, $02, $04
	END
Instr2_14:
	HWENV $C1, $04, $63
	DUTY_12
	END

; Unreferenced (1 bytes)
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
	dw Arp22
	dw Arp22

; Unreferenced (8 bytes)
	db $A6, $71, $A6, $71, $A6, $71, $A6, $71
Arp0:
	db $0C, $00, ARP_HOLD
Arp3:
	db $00, $00, $01, $01, $02, ARP_HOLD
Arp2:
	db $00, $01, $02, ARP_HOLD
Arp1:
	db $18, $0C, $00, ARP_HOLD
Arp4:
	db $00, $04, $07, ARP_LOOP
Arp5:
	db $00, $03, $07, ARP_LOOP
Arp6:
	db $00, $04, $07, ARP_LOOP
Arp7:
	db $F4, $00, ARP_HOLD
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
	db $0C, $0C, $00, $00, ARP_LOOP
Arp21:
	db $02, $02, $01, $01, $00, ARP_HOLD
Arp22:
	db $18, $0C
SfxTable_m2:
	db $00, ARP_HOLD

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

; Sound effect 1
Sfx01:
	VOLENV 15, $11, $1F, $11
	GLIDE $FD
	CALL_CODE Code_73C6
	LEN 8
	WAVE Wave_752A
	NOTE C_, 6
	VOL $0A
	NOTE C_, 6
	END

; Sound effect 20
Sfx20:
	CALL_CODE Code_742F
	END

; Sound effect 2
Sfx02:
	VOLENV 15, $11, $1F, $12
	CH_TRANSPOSE $02
	CALL_CODE Code_7499
	ARP 0
	SLIDE_UP $0A
	WAVE Wave_74FA
	LEN 4
	GLIDE $04
	NOTE Fsh, 2
	LEN 4
	GLIDE $FF
	WAIT
	LEN 4
	GLIDE $01
	WAIT
	GLIDE $01
	WAIT
	LEN 4
	GLIDE $03
	WAIT
	ARP_OFF
	VOLENV 12, $11, $1F, $11
	WAVE Wave_74EA
	GLIDE $FE
	LEN 8
	NOTE B_, 7
	NOTE B_, 7
	NOTE B_, 7
	VOLENV 8, $11, $1F, $11
	NOTE B_, 7
	NOTE B_, 7
	NOTE B_, 7
	END

; Sound effect 3
Sfx03:
	CALL_CODE Code_7499
	VOLENV 15, $11, $1F, $11
	WAVE Wave_74FA
	LEN 6
	GLIDE $FD
	NOTE D_, 4
	END

; Sound effect 4
Sfx04:
	VOLENV 15, $11, $2F, $11
	LEN 7
	WAVE Wave_751A
	GLIDE $04
	NOTE G_, 3
	GLIDE $FC
	NOTE G_, 5
	END

; Sound effect 5
Sfx05:
	WAVE Wave_74FA
	VOLENV 15, $11, $2F, $11
	CALL_CODE Code_7402
	LEN 4
	GLIDE $FC
	NOTE D_, 4
	LEN 2
	REST
	LEN 1
	VOLENV 10, $00, $00, $00
	NOTE C_, 8
	REST
	END

; Sound effect 10
Sfx10:
	VOLENV 5, $2A, $2F, $11
	CH_TRANSPOSE $18
	WAVE Wave_757A
	GLIDE $02
	LEN 7
	NOTE C_, 3
	NOTE D_, 3
	NOTE E_, 3
	NOTE Fsh, 3
	END

; Sound effect 12
Sfx12:
	VOLENV 15, $11, $1F, $12
	CH_TRANSPOSE $02
	ARP 0
	SLIDE_UP $0A
	WAVE Wave_74FA
	LEN 4
	GLIDE $04
	NOTE Fsh, 2
	LEN 4
	GLIDE $FF
	WAIT
	LEN 4
	GLIDE $01
	WAIT
	GLIDE $01
	WAIT
	LEN 4
	GLIDE $03
	WAIT
	END

; Sound effect 15
Sfx15:
	LEN 4
	VOLENV 15, $11, $1F, $11
	CH_TRANSPOSE $18
	WAVE Wave_758A
	NOTE C_, 5
	NOTE C_, 6
	NOTE G_, 5
	VOL $0A
	NOTE C_, 5
	NOTE C_, 6
	NOTE G_, 5
	VOL $05
	NOTE C_, 5
	NOTE C_, 6
	NOTE G_, 5
	END

; Sound effect 16
Sfx16:
	VOLENV 15, $00, $00, $00
	LEN 4
	CH_TRANSPOSE $18
	WAVE Wave_758A
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

; Sound effect 17
Sfx17:
	LEN 4
	VOLENV 15, $11, $1F, $11
	CH_TRANSPOSE $18
	WAVE Wave_757A
	NOTE C_, 6
	NOTE G_, 5
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 4
	VOL $0A
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 4
	VOL $05
	NOTE C_, 6
	NOTE G_, 5
	NOTE C_, 5
	END

; Sound effect 18
Sfx18:
	LEN 4
	VOLENV 15, $11, $1F, $11
	CH_TRANSPOSE $0C
	WAVE Wave_74EA
	NOTE C_, 7
	NOTE D_, 7
	NOTE C_, 6
	NOTE D_, 6
	NOTE C_, 5
	NOTE D_, 5
	VOL $0A
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 4
	VOL $05
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 4
	END

; Sound effect 11
Sfx11:
	LEN 12
	VOLENV 15, $10, $1F, $11
	GLIDE $02
	WAVE Wave_74FA
	NOTE E_, 3
	END

; Sound effect 14
Sfx14:
	VOLENV 10, $00, $00, $00
	GLIDE $FC
	WAVE Wave_752A
	CALL_CODE Code_73C6
	LEN 5
	NOTE A_, 5
	END

; Sound effect 21
Sfx21:
	CALL_CODE Code_7377
	VOLENV 15, $11, $1F, $15
	WAVE Wave_74FA
	LEN 9
	GLIDE $FC
	NOTE A_, 4
	END

; Sound effect 13
Sfx13:
	CALL_CODE Code_7463
	VOLENV 15, $11, $1F, $15
	WAVE Wave_74FA
	LEN 9
	GLIDE $FD
	NOTE A_, 3
	END

; Sound effect 7
Sfx07:
	VOLENV 15, $11, $2F, $11
	WAVE Wave_750A
	LEN 7
	NOTE C_, 6
	END

; Sound effect 8
Sfx08:
	LEN 4
	VOLENV 15, $11, $2F, $11
	WAVE Wave_750A
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
	WAVE Wave_757A
	VOLENV 15, $10, $1F, $12
	RELEASE $02, $55
	NOTE C_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	END

; Sound effect 9
Sfx09:
	VOLENV 10, $11, $1F, $14
	WAVE Wave_74FA
	LEN 33
	SLIDE_DOWN $03
	NOTE A_, 5
	END

; Sound effect 19
Sfx19:
	CALL_CODE Code_7402
	VOLENV 15, $00, $00, $00
	WAVE Wave_75EA
	LEN 3
	GLIDE $FF
	NOTE Csh, 6
	WAVE Wave_75CA
	WAIT
	WAVE Wave_75DA
	WAIT
	END
Code_7377:
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
	ld a, HIGH(Noise43_73A1)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_73A1)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_73A1:
	db $36, $35, $34, $33, $32, $31, $20, $10
	db $10, $37, $36, $35, $34, $33, $32, $21
	db $11, $11, $38, $37, $36, $35, $34, $33
	db $22, $12, $12, $39, $38, $37, $36, $35
	db $34, $23, $13, $13, $FF
Code_73C6:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_73E8)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_73E8)
	ld [wNoise43], a
	ld a, HIGH(Noise42_73F5)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_73F5)
	ld [wNoise42], a
	ret
Noise43_73E8:
	db $10, $10, $20, $31, $32, $33, $33, $34
	db $34, $35, $35, $36, $FF
Noise42_73F5:
	db $5C, $FF, $FF, $FF, $FF, $FF, $A1, $FF
	db $FF, $FF, $FF, $FF

; Unreferenced (1 bytes)
	db $FF
Code_7402:
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7424)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7424)
	ld [wNoise43], a
	ld a, HIGH(Noise42_742A)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_742A)
	ld [wNoise42], a
	ret
Noise43_7424:
	db $31, $53, $71, $41, $51, $FF
Noise42_742A:
	db $B1, $FF, $FF, $FF, $51
Code_742F:
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7451)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7451)
	ld [wNoise43], a
	ld a, HIGH(Noise42_745A)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_745A)
	ld [wNoise42], a
	ret
Noise43_7451:
	db $54, $54, $53, $55, $63, $51, $21, $53
	db $FF
Noise42_745A:
	db $B1, $FF, $FF, $FF, $FF, $FF, $FF, $FF

; Unreferenced (1 bytes)
	db $52
Code_7463:
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
	ld a, HIGH(Noise43_748E)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_748E)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7494)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7494)
	ld [wNoise42], a
	ret
Noise43_748E:
	db $03, $93, $80, $72, $70, $FF
Noise42_7494:
	db $F0, $FF, $FF, $FF, $F3
Code_7499:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_74BB)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_74BB)
	ld [wNoise43], a
	ld a, HIGH(Noise42_74C3)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_74C3)
	ld [wNoise42], a
	ret
Noise43_74BB:
	db $22, $81, $64, $71, $53, $44, $35, $FF
Noise42_74C3:
	db $F0, $F0, $F0, $F0, $F0, $70, $63
Wave_74CA:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $76, $54, $32, $10, $77, $77, $77, $77
Wave_74DA:
	db $8C, $FE, $ED, $B8, $53, $21, $10, $24
	db $84, $01, $12, $35, $8B, $DE, $EF, $8C
Wave_74EA:
	db $00, $16, $8A, $FF, $FF, $A8, $61, $00
	db $00, $16, $8A, $FF, $FF, $A8, $61, $00
Wave_74FA:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
Wave_750A:
	db $00, $00, $00, $00, $CD, $EF, $FD, $EC
	db $00, $12, $21, $00, $DD, $DD, $DD, $DD
Wave_751A:
	db $00, $00, $00, $00, $00, $00, $FF, $FF
	db $00, $00, $00, $00, $00, $00, $FF, $FF
Wave_752A:
	db $00, $00, $00, $00, $00, $00, $FF, $00
	db $00, $00, $00, $00, $00, $00, $FF, $00
Wave_753A:
	db $00, $01, $23, $45, $67, $89, $AB, $CD
	db $EF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
Wave_754A:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $00, $FF, $FF, $FF

; Unreferenced (16 bytes)
	db $12, $34, $56, $78, $9A, $BC, $DE, $FF, $ED, $CB, $A9, $87, $65, $43, $21, $00
Wave_756A:
	db $63, $10, $00, $00, $00, $00, $01, $36
	db $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9
Wave_757A:
	db $63, $10, $01, $47, $74, $10, $01, $36
	db $9C, $EF, $FE, $B8, $8B, $EF, $FE, $C9
Wave_758A:
	db $63, $1F, $01, $47, $74, $10, $01, $36
	db $9C, $E0, $FE, $B8, $8B, $EF, $FE, $C9
Wave_759A:
	db $65, $43, $22, $27, $72, $22, $22, $29
	db $AB, $CC, $BA, $98, $9C, $EE, $EE, $C9
Wave_75AA:
	db $B7, $40, $04, $7B, $CD, $FF, $FE, $DC
	db $02, $46, $8A, $BD, $FD, $BA, $64, $20
Wave_75BA:
	db $FE, $DB, $97, $53, $13, $54, $32, $10
	db $FE, $DC, $BC, $EF, $DB, $85, $32, $10
Wave_75CA:
	db $04, $8B, $DE, $FF, $ED, $CB, $A9, $87
	db $65, $44, $44, $32, $11, $24, $7A, $74
Wave_75DA:
	db $20, $24, $68, $AC, $EC, $A8, $64, $20
	db $24, $68, $A8, $64, $20, $24, $68, $64
Wave_75EA:
	db $02, $48, $AC, $FF, $FC, $53, $00, $27
	db $9C, $DD, $DC, $B7, $7B, $CD, $DD, $C9
Noise43_75FA:
	db $01, $61, $71, $A1, $B1, $B1, $A1, $FF
Noise42_7602:
	db $C1, $F0, $A0, $90, $70, $40, $33
Noise43_7609:
	db $06, $04, $03, $03, $07, $FF
Noise42_760F:
	db $F0, $C0, $80, $60, $55
Noise43_7614:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_761C:
	db $60, $30, $12, $FF, $FF, $FF, $FF
Noise43_7623:
	db $04, $00, $00, $00, $00, $00, $00, $FF
Noise42_762B:
	db $90, $53, $FF, $FF, $FF, $FF, $FF
Noise43_7632:
	db $04, $02, $01, $01, $01, $11, $11, $FF
Noise42_763A:
	db $70, $40, $40, $40, $40, $43, $FF

; Unreferenced (15 bytes)
	db $50, $41, $50, $51, $42, $53, $51, $FF, $F0, $70, $F0, $70, $D0, $70, $61
Unused_Noise_7650:
	ld a, $08
	ld [wDrumHold], a
	call NoisePanCentre
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_75FA)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_75FA)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7602)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7602)
	ld [wNoise42], a
	ret
Drum8:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7692)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7692)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7698)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7698)
	ld [wNoise42], a
	ret
Noise43_7692:
	db $04, $02, $01, $00, $00, $FF
Noise42_7698:
	db $40, $60, $70, $82, $71
Drum2:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_76BA)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_76BA)
	ld [wNoise43], a
	ld a, HIGH(Noise42_76C6)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_76C6)
	ld [wNoise42], a
	ret
Noise43_76BA:
	db $51, $31, $32, $32, $32, $32, $32, $32
	db $33, $34, $35, $FF
Noise42_76C6:
	db $F0, $63, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7632)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7632)
	ld [wNoise43], a
	ld a, HIGH(Noise42_763A)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_763A)
	ld [wNoise42], a
	ret
Drum5:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7623)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7623)
	ld [wNoise43], a
	ld a, HIGH(Noise42_762B)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_762B)
	ld [wNoise42], a
	ret
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7614)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7614)
	ld [wNoise43], a
	ld a, HIGH(Noise42_761C)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_761C)
	ld [wNoise42], a
	ret
Drum7:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7609)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7609)
	ld [wNoise43], a
	ld a, HIGH(Noise42_760F)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_760F)
	ld [wNoise42], a
	ret
Drum9:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7762)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7762)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7765)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7765)
	ld [wNoise42], a
	ret
Noise43_7762:
	db $51, $32, $FF
Noise42_7765:
	db $F0, $62
Drum10:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_77A1)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_77A1)
	ld [wNoise43], a
	ld a, HIGH(Noise42_77A4)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_77A4)
	ld [wNoise42], a
	ret
Drum11:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_77A6)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_77A6)
	ld [wNoise43], a
	ld a, HIGH(Noise42_77AE)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_77AE)
	ld [wNoise42], a
	ret
Noise43_77A1:
	db $51, $32, $FF
Noise42_77A4:
	db $70, $52
Noise43_77A6:
	db $51, $32, $32, $32, $32, $51, $32, $FF
Noise42_77AE:
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

; Not sound data: the rest of the bank (2 KB) holds game data, compressed graphics
; that the game's loader lists in bank 6 read from bank 2 (from $7908, $7BD3-$7C61,
; $7C00, $7E1D, $7E7C, $7EB1, $7F07, $7F6C).
	db $F7, $0F, $EC, $1E, $D8, $3C, $B1, $78, $62, $F1, $E4, $E2, $E2, $C5, $87, $C8
	db $88, $07, $27, $18, $1F, $60, $7C, $80, $F0, $00, $60, $80, $80, $80, $00, $00
	db $F3, $04, $F7, $0C, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $88, $70, $F2, $0C, $3C, $03, $03, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $F7, $79, $1A, $3F, $0E, $1F, $47, $8F, $A3, $47, $13, $63, $63, $D1, $10, $09
	db $D7, $88, $0E, $90, $AC, $10, $1C, $20, $18, $20, $58, $20, $38, $40, $30, $40
	db $05, $08, $08, $04, $02, $04, $04, $02, $00, $02, $01, $02, $02, $01, $00, $01
	db $30, $40, $00, $50, $10, $70, $30, $40, $30, $40, $30, $40, $30, $40, $50, $20
	db $36, $52, $FE, $01, $3F, $9B, $7D, $D9, $FE, $01, $6E, $4A, $18, $3C, $00, $00
	db $00, $01, $00, $01, $00, $03, $02, $07, $00, $01, $00, $01, $02, $01, $01, $02
	db $10, $20, $18, $20, $A8, $10, $08, $90, $D4, $88, $84, $C8, $E2, $C4, $64, $E3
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80, $80, $80
	db $00, $02, $04, $02, $02, $04, $08, $04, $05, $08, $10, $09, $02, $51, $51, $E3
	db $80, $00, $40, $80, $10, $60, $24, $18, $88, $07, $21, $C0, $C8, $30, $F8, $07
	db $00, $00, $00, $00, $00, $00, $00, $08, $89, $18, $00, $FF, $00, $00, $80, $00
	db $00, $00, $01, $00, $04, $03, $12, $0C, $88, $70, $43, $81, $0E, $07, $83, $7C
	db $F7, $0F, $EC, $1E, $D8, $3C, $B1, $78, $62, $F1, $E5, $E2, $E3, $C4, $81, $CA
	db $88, $07, $27, $18, $1F, $60, $7C, $80, $F0, $00, $E0, $00, $C0, $00, $00, $00
	db $9F, $20, $BF, $60, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $88, $70, $F2, $0C, $3C, $03, $01, $02, $02, $06, $00, $00, $00, $00, $00, $00
	db $F7, $79, $1A, $3F, $0E, $1F, $47, $8F, $A3, $47, $53, $23, $23, $11, $10, $09
	db $D3, $8E, $0E, $90, $AC, $10, $1C, $20, $18, $20, $58, $20, $38, $40, $30, $40
	db $05, $08, $08, $04, $02, $04, $04, $02, $00, $02, $01, $02, $02, $01, $00, $05
	db $30, $40, $30, $40, $30, $40, $30, $40, $30, $40, $20, $48, $28, $58, $50, $20
	db $2E, $62, $FE, $03, $7D, $99, $3F, $99, $FE, $41, $76, $46, $18, $3C, $00, $00
	db $04, $0D, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $02, $01, $01, $02
	db $10, $20, $18, $20, $A8, $10, $08, $90, $D4, $88, $84, $C8, $E2, $C4, $65, $E2
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $02, $04, $02, $02, $04, $08, $14, $15, $38, $10, $09, $02, $11, $11, $23
	db $80, $10, $50, $B0, $10, $60, $24, $18, $88, $07, $21, $C0, $C8, $30, $F8, $07
	db $00, $00, $00, $00, $00, $00, $00, $01, $81, $00, $00, $FF, $00, $00, $80, $00
	db $00, $00, $01, $00, $04, $83, $92, $8C, $88, $70, $43, $81, $0E, $07, $83, $7C
	db $F7, $0F, $EC, $1E, $D8, $3C, $B1, $78, $62, $F1, $E5, $E2, $E3, $C4, $87, $C8
	db $88, $07, $21, $1A, $1B, $66, $7C, $80, $F0, $00, $E0, $00, $C0, $00, $00, $00
	db $FF, $00, $FF, $00, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $88, $70, $F2, $0C, $24, $0B, $0B, $18, $00, $00, $00, $00, $00, $00, $00, $00
	db $F7, $79, $1A, $3F, $0E, $1F, $47, $8F, $A3, $47, $53, $23, $23, $11, $10, $09
	db $D7, $88, $0E, $90, $A0, $14, $14, $2C, $18, $20, $58, $20, $38, $40, $30, $40
	db $05, $08, $08, $04, $02, $04, $04, $0A, $08, $1A, $01, $02, $02, $01, $00, $01
	db $30, $40, $30, $40, $30, $40, $30, $40, $30, $40, $30, $40, $30, $40, $50, $20
	db $1E, $46, $FC, $41, $7F, $99, $7F, $99, $BE, $03, $7A, $62, $18, $3C, $00, $00
	db $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $02, $01, $01, $02
	db $10, $24, $14, $2C, $A8, $10, $08, $90, $D4, $88, $84, $C8, $E2, $C4, $65, $E2
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $02, $04, $0A, $0A, $1C, $08, $04, $05, $08, $10, $09, $02, $11, $11, $23
	db $80, $00, $40, $84, $14, $6C, $24, $18, $88, $07, $21, $C0, $C8, $30, $F8, $07
	db $00, $00, $00, $00, $00, $00, $00, $00, $81, $00, $00, $FF, $00, $00, $80, $00
	db $00, $00, $01, $10, $14, $33, $12, $0C, $88, $70, $43, $81, $0E, $07, $83, $7C
	db $F7, $0F, $EC, $1E, $D8, $3C, $B1, $78, $62, $F1, $E5, $E2, $E3, $C4, $87, $C8
	db $88, $07, $27, $18, $1F, $60, $4C, $90, $D0, $30, $E0, $00, $C0, $00, $00, $00
	db $FF, $00, $FF, $00, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $88, $70, $92, $2C, $3C, $63, $03, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $F7, $79, $1A, $3F, $0E, $1F, $47, $8F, $A3, $47, $53, $23, $23, $11, $10, $09
	db $D7, $88, $0E, $90, $AC, $10, $1C, $20, $18, $20, $40, $28, $28, $58, $30, $40
	db $05, $18, $18, $34, $02, $04, $04, $02, $00, $02, $01, $02, $02, $01, $00, $01
	db $30, $40, $30, $40, $30, $40, $30, $40, $30, $40, $30, $40, $30, $40, $50, $20
	db $3A, $4A, $BE, $01, $7F, $D9, $7F, $9B, $FC, $01, $5E, $52, $18, $3C, $00, $00
	db $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $00, $01, $02, $05, $05, $0E
	db $10, $20, $18, $20, $A8, $10, $08, $92, $D2, $8E, $84, $C8, $E2, $C4, $65, $E2
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $02, $04, $02, $02, $04, $08, $04, $05, $08, $10, $09, $02, $11, $11, $23
	db $80, $00, $40, $80, $10, $60, $24, $19, $88, $07, $21, $C0, $C8, $30, $F8, $07
	db $00, $00, $00, $00, $00, $80, $80, $80, $81, $00, $00, $FF, $00, $00, $80, $00
	db $00, $02, $03, $06, $04, $03, $12, $0C, $88, $70, $43, $81, $0E, $07, $83, $7C
	db $52, $4E, $43, $02, $00, $00, $02, $A0, $00, $00, $02, $0B, $45, $3A, $F6, $8D
	db $04, $01, $2E, $78, $03, $03, $0D, $0E, $19, $17, $36, $2F, $68, $5F, $50, $7F
	db $D9, $B7, $E3, $BE, $E2, $BF, $91, $FF, $70, $5F, $4A, $7D, $11, $11, $1F, $31
	db $0C, $0F, $1D, $C0, $C0, $73, $B0, $70, $88, $F8, $6C, $F4, $56, $BA, $0A, $FE
	db $8B, $FD, $47, $FD, $45, $FF, $99, $EF, $0E, $FA, $12, $FE, $64, $FC, $C6, $15
	db $30, $F0, $1D, $78, $00, $09, $00, $3C, $3C, $0D, $66, $7E, $5A, $66, $01, $B6
	db $05, $09, $0D, $20, $05, $06, $01, $07, $36, $07, $02, $4A, $02, $40, $02, $0C
	db $0D, $0B, $36, $1A, $16, $01, $5D, $0C, $08, $0F, $04, $07, $14, $A0, $40, $60
	db $01, $E0, $E0, $20, $40, $C0, $01, $80, $E4, $00, $06, $43, $06, $06, $0A, $64
	db $2E, $F6, $34, $38, $CC, $F8, $F8, $3F, $3F, $5C, $63, $7F, $40, $BF, $C0, $FF
	db $80, $E3, $9C, $CC, $06, $BF, $DF, $06, $A0, $A7, $D8, $81, $FE, $07, $0C, $A6
	db $D9, $73, $4C, $19, $4F, $01, $70, $FF, $FF, $13, $EC, $FF, $00, $22, $01, $F8
	db $EF, $07, $E0, $FF, $09, $FE, $C7, $38, $E0, $1F, $F0, $0F, $3E, $C1, $B0, $7F
	db $C7, $3F, $E1, $1F, $A3, $DC, $A0, $DF, $B2, $CF, $7C, $43, $53, $6C, $22, $3F
	db $31, $3F, $3A, $3D, $1D, $1E, $16, $1F, $19, $C7, $D9, $07, $21, $7B, $69, $8D
	db $33, $7E, $81, $3A, $71, $F7, $FF, $E3, $1F, $7C, $83, $F0, $FF, $7F, $FF, $0F
	db $FF, $73, $8F, $DE, $FF, $CD, $56, $1C, $58, $9A, $13, $FF, $7D, $17, $23, $4A
	db $87, $87, $F8, $7F, $50, $EF, $B9, $7E, $A7, $67, $F0, $F0, $FC, $4C, $CF, $73
	db $71, $FE, $CC, $4F, $43, $C3, $E0, $60, $50, $F0, $48, $F8, $00, $43, $F8, $14
	db $EC, $3A, $C6, $F4, $0C, $25, $F8, $F8, $80, $01, $C0, $C0, $70, $B0, $1C, $EC
	db $31, $C3, $FF, $6F, $1F, $1F, $87, $45, $DF, $20, $20, $23, $4B, $1F, $01, $01
	db $01, $0A, $8B, $2D, $F9, $F7, $9E, $57, $BB, $17, $FF, $F1, $FF, $CF, $CF, $AD
	db $EF, $5B, $FF, $89, $FF, $49, $7F, $29, $3F, $1B, $1D, $09, $0F, $0B, $0D, $03
	db $34, $12, $1E, $01, $18, $23, $FE, $00, $02, $02, $7B, $FE, $02, $01, $1A, $4D
	db $FD, $02, $03, $1B, $07, $04, $16, $21, $16, $1A, $43, $03, $01, $18, $07, $24
	db $3C, $2E, $2A, $F6, $C0, $03, $E4, $BC, $AC, $74, $24, $1B, $FC, $FE, $03, $01
	db $01, $26, $06, $FE, $BE, $FE, $6A, $F6, $80, $DE, $E7, $7E, $E6, $7D, $C4, $7F
	db $1C, $45, $FF, $86, $3B, $1C, $FA, $05, $00, $40, $03, $6C, $F4, $AC, $B4, $2C
	db $34, $00, $33, $48, $78, $D8, $E8, $D8, $68, $58, $6C, $E8, $01, $07, $58, $6C
	db $68, $0D, $CB, $98, $12, $E8, $A8, $F8, $2E, $D1, $39, $79, $39, $67, $7E, $C2
	db $FF, $CD, $F6, $7D, $7E, $0F, $0F, $3F, $32, $F3, $CE, $8E, $7F, $33, $F2, $C2
	db $C3, $07, $06, $0A, $A1, $1F, $00, $1F, $BE, $BE, $C7, $F9, $03, $87, $F9, $CE
	db $72, $BC, $7C, $F7, $0E, $1F, $BF, $08, $00, $04, $40, $1F, $0F, $80, $80, $00
	db $C0, $40, $E0, $20, $A0, $60, $60, $E0, $F7, $0A, $3F, $80, $00, $52, $4E, $43
	db $02, $00, $00, $01, $00, $00, $00, $00, $4D, $66, $3E, $15, $5F, $04, $01, $12
	db $00, $00, $00, $06, $03, $03, $06, $33, $33, $00, $C8, $02, $06, $01, $0D, $27
	db $2A, $06, $06, $2D, $30, $07, $09, $09, $10, $02, $09, $05, $F7, $03, $00, $9E
	db $01, $13, $21, $03, $13, $7A, $03, $05, $22, $63, $27, $06, $09, $DE, $0A, $15
	db $38, $00, $14, $09, $09, $09, $6F, $3C, $03, $03, $0C, $1D, $06, $F3, $0C, $13
	db $06, $C9, $08, $20, $06, $31, $44, $00, $24, $00, $E0, $00, $8B, $FC, $B2, $0F
	db $6A, $9C, $88, $F0, $D1, $E0, $44, $E0, $90, $60, $2B, $F0, $7A, $FD, $F0, $0F
	db $0D, $03, $96, $01, $38, $07, $1D, $03, $A9, $16, $44, $BF, $77, $F8, $E7, $1C
	db $0B, $06, $97, $02, $3B, $06, $1B, $06, $A5, $1E, $4F, $BC, $FF, $00, $FF, $00
	db $FF, $00, $FF, $00, $FF, $00, $FF, $00, $FF, $00, $FF, $00, $FB, $06, $F6, $0B
	db $EA, $1C, $E8, $10, $D1, $20, $C4, $20, $F0, $20, $EB, $30, $E0, $1F, $32, $0F
	db $1D, $02, $70, $0F, $0A, $01, $25, $02, $1E, $01, $34, $03, $3A, $FC, $5D, $38
	db $B0, $78, $48, $F0, $85, $F8, $58, $84, $86, $00, $20, $00, $37, $F8, $5F, $30
	db $AF, $70, $57, $F8, $8F, $F8, $53, $8C, $8F, $04, $23, $04, $F8, $1F, $F6, $0F
	db $EB, $16, $F4, $0F, $EA, $11, $D5, $22, $EE, $21, $C4, $23, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
