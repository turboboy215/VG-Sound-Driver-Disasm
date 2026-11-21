; =====================================================================
; Asterix & Obelix (E) (M4) [C] - Game Boy Color
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4 (GBC revision)
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o obelixgbc.o ObelixGBC_SoundDriver.asm
;   rgblink -o obelixgbc.gb obelixgbc.o
;   python tools/cmp_banked.py obelixgbc.gb "Obelix (E) (M4) [C][!].gbc" 6:4000-7FFF
; (driver and data fill ROM bank 6; the linked file only matches in that range)
;
; Documentation: Obelix_SoundDriver.md / AJG_SoundEngine_Family.md
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
DEF wCh1 EQU $C100
DEF wPaused EQU $C142
DEF wStereo EQU $C143
DEF wShNR32 EQU $C144
DEF wInInstr EQU $C145
DEF wNoisePan EQU $C146
DEF wDrumHold EQU $C147
DEF wInstrTable EQU $C148
DEF wInstrTableHi EQU $C149
DEF wArpTable EQU $C14A
DEF wArpTableHi EQU $C14B
DEF wMusicWave EQU $C14C
DEF wMusicWaveHi EQU $C14D
DEF wNoiseAutoPan EQU $C14E
DEF wDrumPatHi EQU $C14F
DEF wDrumPat EQU $C150
DEF wDrumPos EQU $C151
DEF wDrumsOn EQU $C152
DEF wDrumTempo EQU $C153
DEF wDrumTimer EQU $C154
DEF wDrumLoopCount EQU $C155
DEF wDrumLoopPos EQU $C156
DEF wNoise43Hi EQU $C157
DEF wNoise43 EQU $C158
DEF wNoise42Hi EQU $C159
DEF wNoise42 EQU $C15A
DEF wNoisePos EQU $C15B
DEF wNoiseOn EQU $C15C
DEF wNoiseAtten EQU $C15D
DEF wNoiseTimer EQU $C15E
DEF wNoiseSpeed EQU $C15F
DEF wFadeTable EQU $C160
DEF wFadeTableHi EQU $C161
DEF wFadePos EQU $C162
DEF wFadeTimer EQU $C163
DEF wFadeSpeed EQU $C164
DEF wFadeOn EQU $C165
DEF wDutyCh1 EQU $C166
DEF wDutyCh2 EQU $C167
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


SECTION "SoundDriver", ROMX[$4000], BANK[6]


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
PlaySfxEntry2:
	jp PlaySfx                         ; PlaySfx without the SFX-29 test (A = id)

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
	ld h, $C1
	call ChannelTick
	inc h
	call ChannelTick
	inc h
	call ChannelTick
	inc h
	call ChannelTick
	call DrumTick

; Output, pulse pages: NR11/NR21 = duty shadows every tick; NRx3 = period low +
; pitch offset; when the high byte changed or the envelope flag ($33) is set:
; with the flag NRx2 = field $32 and NRx4 = high | $80, else NRx4 = high.
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
	ldh [rNR34], a
	ld [hl], a
WriteCh3Vol:
	inc l
	ld a, [hl]
	add a, $CA
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
	cp $C3
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

; Not reached: an older VOLENV body that read its bytes through bc.
Unused_OldVolEnv:
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

; INSTR n: clear arpeggio, glide, arpeggio offset and auto-duty; pulse pages: 50 %
; duty; then run macro n (entry n + 1 of wInstrTable) up to END with wInInstr = $C9.
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
	cp $C3
	jr z, ReleaseCh3
	cp $C4
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
	cp $C1
	jr nz, SetDutyCh2
	ld a, l
	ld [wDutyCh1], a
	ret
SetDutyCh2:
	ld a, l
	ld [wDutyCh2], a
	ret
Unused_StartFade:
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
	cp $C3
	jr nz, LoadWave
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
	ld [$C307], a
	ldh [rNR30], a
	ldh [rNR34], a
	ret

; Unreferenced (62 bytes)
	db $E2, $0C, $7E, $E2, $FA, $96, $C1, $A7, $C0, $3E, $80, $EA, $07, $C3, $E0, $1A
	db $E0, $1E, $C9, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
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
	ld h, $C1
	jr StartMusicCh
StartMusicCh2:
	ld h, $C2
	jr StartMusicCh
StartMusicCh3:
	ld h, $C3
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

; API entry for PlaySfx: goes through the game's glue in the data area first.
PlaySfxEntry:
	jp PlaySfxEntry2

; PlaySfx (A = id): no priority test; reset the SFX page and start the stream.
PlaySfx:
	ld [$C427], a
	ld c, a
	ld a, $11
	ld [$C438], a
	xor a
	ld [$C404], a
	ld [$C40B], a
	ld [$C42F], a
	ld [$C42C], a
	ld [$C40E], a
	inc a
	ld [$C40A], a
	ld a, $F4
	ld [$C40D], a
	ld a, c
	ld de, $C402
	add a, a
	add a, $96
	ld l, a
	adc a, $75
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
	jp Unused_StartFade
SongFadeIn:
	push af
	call SndResume
	pop af
	ld hl, FadeInTable
	jp Unused_StartFade
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
	ld c, a
	xor a
	ldh [rNR41], a
	ld a, c
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

; Song 1: instrument table 1, arpeggio table 1
PlaySong1:
	ld a, HIGH(ArpTable)
	ld [wArpTableHi], a
	ld a, LOW(ArpTable)
	ld [wArpTable], a
	ld a, $4E
	ld [wInstrTableHi], a
	ld a, $E0
	ld [wInstrTable], a
	ld de, Song1_Ch1
	call StartMusicCh1
	ld de, Song1_Ch2
	call StartMusicCh2
	ld de, Song1_Ch3
	call StartMusicCh3
	ret
Song1_Ch1:
	dw Pat_4B67
	dw Pat_4BDB
	ORDER_LOOP Song1_Ch1
Song1_Ch2:
	dw Pat_4C30
	ORDER_LOOP Song1_Ch2
Song1_Ch3:
	dw Pat_4D4F
	ORDER_LOOP Song1_Ch3
Pat_4B67:
	DRUMS $07, DrumPat_4E7F
	LEN 14
	PAT_CALL Pat_4BFF
	INSTR 1
	NOTE Dsh, 5
	INSTR 0
	NOTE Ash, 2
	NOTE G_, 2
	PAT_CALL Pat_4BFF
	NOTE Ash, 2
	NOTE G_, 2
	NOTE Dsh, 2
	DRUMS $07, DrumPat_4EC9
	NOTE E_, 2
	NOTE B_, 2
	INSTR 1
	NOTE E_, 5
	INSTR 0
	NOTE Gsh, 2
	NOTE Dsh, 2
	NOTE Ash, 2
	NOTE G_, 2
	NOTE Dsh, 2
	NOTE Csh, 2
	NOTE Gsh, 2
	INSTR 2
	NOTE Csh, 5
	INSTR 0
	NOTE Ash, 2
	DRUMS $07, DrumPat_4EB3
	NOTE Dsh, 2
	INSTR 1
	NOTE Dsh, 5
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE Dsh, 5
	DRUMS $07, DrumPat_4E7F
	PAT_CALL Pat_4E5D
	NOTE Dsh, 2
	NOTE G_, 2
	PAT_CALL Pat_4E5D
	NOTE Gsh, 2
	NOTE G_, 2
	DRUMS $07, DrumPat_4EC4
	INSTR 0
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	NOTE F_, 2
	LEN 28
	NOTE F_, 2
	NOTE C_, 3
	LEN 14
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	LENGTH $38
	NOTE F_, 2
	LEN 14
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 2
	NOTE Dsh, 2
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 2
	LEN 28
	NOTE Dsh, 2
	NOTE Gsh, 2
	LEN 14
	NOTE Dsh, 2
	NOTE F_, 2
	NOTE Dsh, 2
	NOTE F_, 2
	DRUMS $07, DrumPat_4EB3
	NOTE Dsh, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE Dsh, 2
	NOTE G_, 2
Pat_4BDB:
	DRUMS $07, DrumPat_4E7F
	LEN 14
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
	REPEAT 4
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Dsh, 4
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
	NEXT
Pat_4BFF:
	REPEAT 2
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Dsh, 5
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE Dsh, 5
	REPEAT_END
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE E_, 5
	INSTR 0
	NOTE B_, 2
	INSTR 1
	NOTE E_, 5
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Dsh, 5
	INSTR 0
	NOTE Ash, 2
	NOTE Dsh, 2
	NOTE Csh, 2
	INSTR 2
	NOTE Csh, 5
	INSTR 0
	NOTE Gsh, 2
	INSTR 2
	NOTE Csh, 5
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Dsh, 5
	INSTR 0
	NOTE Ash, 2
	NOTE Dsh, 2
	NOTE E_, 2
	INSTR 1
	NOTE E_, 5
	INSTR 0
	NOTE B_, 2
	INSTR 1
	NOTE E_, 5
	INSTR 0
	NOTE Dsh, 2
	NEXT
Pat_4C30:
	HWENV $F2, $04, $62
	DUTY_50
	ARP 4
	REPEAT 2
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE E_, 4
	LEN 7
	NOTE E_, 4
	NOTE E_, 4
	LEN 14
	NOTE E_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	ARP 5
	LEN 14
	NOTE Csh, 4
	LEN 7
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 14
	NOTE Csh, 4
	LEN 7
	NOTE Csh, 4
	NOTE Csh, 4
	ARP 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE E_, 4
	LEN 7
	NOTE E_, 4
	NOTE E_, 4
	LEN 14
	NOTE E_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	REPEAT_END
	HWENV $F2, $07, $6C
	LEN 42
	NOTE E_, 4
	HWENV $F2, $04, $72
	LEN 14
	NOTE Fsh, 4
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	NOTE Dsh, 4
	ARP 5
	HWENV $F2, $07, $6C
	LEN 42
	NOTE Csh, 4
	HWENV $F2, $04, $62
	LEN 14
	NOTE Csh, 4
	ARP 4
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	HWENV $30, $00
	DUTY_75
	ARP_OFF
	RELEASE $01, $10
	AUTOPAN $07
	CH_TRANSPOSE $F4
	REST
	PAT_CALL Pat_4DF8
	LEN 7
	WAIT
	WAIT2
	NOTE Dsh, 4
	WAIT2
	PAT_CALL Pat_4DF8
	LEN 7
	NOTE Gsh, 4
	WAIT2
	NOTE Ash, 4
	AUTOPAN $00
	CH_TRANSPOSE $00
	HWENV $F2, $04, $63
	DUTY_50
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
	NOTE F_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE F_, 4
	LEN 28
	NOTE F_, 4
	NOTE F_, 4
	ARP 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	ARP 5
	NOTE F_, 4
	ARP 4
	NOTE Dsh, 4
	ARP 5
	NOTE F_, 4
	ARP 4
	NOTE Dsh, 4
	HWENV $F1, $04, $63
	ARP 0
	DUTY_12
	NOTE Dsh, 3
	NOTE C_, 4
	NOTE Csh, 4
	REPEAT 2
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 14
	NOTE G_, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE C_, 4
	LEN 7
	NOTE Csh, 4
	NOTE C_, 4
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE Csh, 4
	NOTE C_, 4
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE Csh, 4
	NOTE C_, 4
	LEN 14
	NOTE C_, 4
	NOTE Csh, 4
	REPEAT_END
	NEXT
Pat_4D4F:
	VOLENV 15, $F1, $11, $11
	RELEASE $01, $61
	VIBRATO $0E, $01, $05
	WAVE Wave_7B1F
	LEN 7
	PAT_CALL Pat_4E2A
	LEN 35
	NOTE Dsh, 4
	LEN 7
	WAIT2
	NOTE Dsh, 4
	WAIT2
	PAT_CALL Pat_4E2A
	NOTE Dsh, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE Dsh, 4
	WAIT2
	ARP 4
	LEN 14
	NOTE E_, 3
	ARP_OFF
	LEN 28
	NOTE Gsh, 4
	LEN 7
	NOTE Ash, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE Dsh, 4
	WAIT2
	ARP 4
	LEN 14
	NOTE Csh, 3
	ARP_OFF
	LEN 28
	NOTE E_, 4
	LEN 7
	NOTE Fsh, 4
	WAIT2
	LENGTH $31
	NOTE Dsh, 4
	LEN 7
	WAIT2
	PAT_CALL Pat_4DF8
	LEN 7
	WAIT
	WAIT2
	NOTE Dsh, 4
	WAIT2
	PAT_CALL Pat_4DF8
	LEN 7
	NOTE Gsh, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	LENGTH $4D
	NOTE C_, 5
	LEN 7
	NOTE G_, 4
	NOTE Gsh, 4
	WAIT2
	NOTE F_, 4
	NOTE Gsh, 4
	LENGTH $4D
	NOTE C_, 5
	LEN 7
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE Csh, 5
	WAIT2
	LENGTH $46
	NOTE Dsh, 5
	LEN 7
	NOTE Ash, 4
	WAIT2
	NOTE B_, 4
	WAIT2
	NOTE Gsh, 4
	NOTE B_, 4
	LENGTH $4D
	NOTE Dsh, 5
	LEN 7
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE Csh, 5
	WAIT2
	REPEAT 2
	LENGTH $4D
	NOTE Dsh, 5
	LEN 7
	WAIT2
	NOTE Csh, 5
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	LENGTH $31
	NOTE G_, 4
	LEN 7
	WAIT2
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	WAIT2
	LEN 21
	NOTE Csh, 5
	LEN 7
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE Ash, 4
	WAIT2
	LEN 21
	NOTE Gsh, 4
	LEN 7
	WAIT2
	NOTE G_, 4
	WAIT2
	LENGTH $4D
	NOTE Gsh, 4
	LEN 7
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE Csh, 5
	WAIT2
	REPEAT_END
	NEXT
Pat_4DF8:
	LEN 7
	NOTE Gsh, 4
	WAIT2
	NOTE Gsh, 4
	WAIT2
	LEN 42
	NOTE Gsh, 4
	LEN 7
	NOTE Ash, 4
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE Csh, 5
	WAIT2
	NOTE C_, 5
	WAIT2
	LEN 6
	NOTE Ash, 4
	LEN 4
	NOTE C_, 5
	NOTE Ash, 4
	LENGTH $3F
	NOTE Gsh, 4
	LEN 7
	WAIT2
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE Dsh, 5
	WAIT2
	NOTE Csh, 5
	NOTE C_, 5
	LENGTH $31
	NOTE Ash, 4
	LEN 7
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE Csh, 5
	WAIT2
	NOTE C_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	LENGTH $38
	NOTE Gsh, 4
	NEXT
Pat_4E2A:
	NOTE Ash, 4
	WAIT2
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	LEN 35
	NOTE Ash, 4
	LEN 7
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE B_, 4
	WAIT2
	NOTE Csh, 5
	NOTE Dsh, 5
	NOTE Csh, 5
	NOTE B_, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	LEN 35
	NOTE Ash, 4
	LEN 7
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE Gsh, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE Gsh, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	LEN 35
	NOTE G_, 4
	LEN 7
	WAIT2
	NOTE Dsh, 4
	WAIT2
	NOTE E_, 4
	WAIT2
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NEXT
Pat_4E5D:
	REPEAT 4
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
	NOTE Dsh, 4
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Dsh, 4
	REPEAT_END
	INSTR 0
	NOTE Gsh, 2
	INSTR 1
	NOTE Gsh, 4
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Gsh, 4
	INSTR 0
	NOTE Gsh, 2
	INSTR 1
	NOTE Gsh, 4
	INSTR 0
	NEXT
DrumPat_4E7F:
	db DRUM_REPEAT + 3, 1, DRUM_LEVEL + 10, 8, DRUM_LEVEL + 15, 8, DRUM_LEVEL + 10, 8
	db DRUM_LEVEL + 15, 9, DRUM_LEVEL + 10, 8, DRUM_LEVEL + 15, 8, DRUM_LEVEL + 10, 8
	db DRUM_LEVEL + 15, DRUM_REPEAT_END, 1, DRUM_LEVEL + 10, 8, DRUM_LEVEL + 15, 8, DRUM_LEVEL + 10
	db 8, DRUM_LEVEL + 15, 9, DRUM_LEVEL + 10, 8, DRUM_LEVEL + 15, 1, DRUM_LEVEL + 10
	db 8, DRUM_LEVEL + 15, DRUM_REPEAT + 3, 1, DRUM_LEVEL + 10, 8, DRUM_LEVEL + 15, 8
	db DRUM_LEVEL + 10, 8, DRUM_LEVEL + 15, 9, DRUM_LEVEL + 10, 8, DRUM_LEVEL + 15, 8
	db DRUM_LEVEL + 10, 8, DRUM_LEVEL + 15, DRUM_REPEAT_END
DrumPat_4EB3:
	db 1, DRUM_LEVEL + 10, 8, DRUM_LEVEL + 15, 9, DRUM_LEVEL + 10, 8, DRUM_LEVEL + 15
	db 9, DRUM_LEVEL + 10, 8, DRUM_LEVEL + 15, 1, DRUM_LEVEL + 15, 9, DRUM_LEVEL + 15
	db DRUM_LOOP
DrumPat_4EC4:
	db 9, 0, 10, 10, DRUM_LOOP
DrumPat_4EC9:
	db 7, 0, 9, 0, 0, 0, 9, 0
	db 1, 0, 9, 9, 1, 0, 1, 0
	db 7, 0, 9, 0, 9, 0, 9, 10
	db DRUM_LOOP

; Instrument table 1, entries 1..3 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr1_0
	dw Instr1_1
	dw Instr1_2
Instr1_0:
	HWENV $F3, $07, $A2
	DUTY_50
	ARP 0
	END
Instr1_1:
	HWENV $D1, $00
	ARP 4
	DUTY_75
	END
Instr1_2:
	HWENV $D1, $00
	ARP 5
	DUTY_75
	END

; Song 2: instrument table 2, arpeggio table 1 (the one SndInit sets)
PlaySong2:
	ld a, $51
	ld [wInstrTableHi], a
	ld a, $64
	ld [wInstrTable], a
	ld de, Song2_Ch3
	call StartMusicCh3
	ld de, Song2_Ch2
	call StartMusicCh2
	ld de, Song2_Ch1
	jp StartMusicCh1
Song2_Ch3:
	dw Pat_4F3B
	dw Pat_4F3B
	dw Pat_4FC2
	dw Pat_5003
	ORDER_LOOP Song2_Ch3
Song2_Ch2:
	dw Pat_5039
	dw Pat_5039
	dw Pat_5083
	dw Pat_50A4
	ORDER_LOOP Song2_Ch2
Song2_Ch1:
	dw Pat_50C5
	dw Pat_50C5
	dw Pat_511A
	dw Pat_513B
	ORDER_LOOP Song2_Ch1
Pat_4F3B:
	LEN 10
	TRANSPOSE $FE
	WAVE Wave_7A4F
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE Csh, 4
	NEXT
Pat_4FC2:
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE D_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE Ash, 3
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE E_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE A_, 3
	NEXT
Pat_5003:
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE D_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE Ash, 3
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE E_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE A_, 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE C_, 3
	NOTE A_, 2
	WAIT
	NOTE E_, 2
	WAIT
	NOTE A_, 1
	WAIT
	NOTE B_, 1
	NOTE Csh, 2
	NEXT
Pat_5039:
	HWENV $E2, $05, $92
	DUTY_75
	LEN 10
	RELEASE $02, $00
	NOTE D_, 3
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE D_, 3
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE D_, 3
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE D_, 3
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NEXT
Pat_5083:
	NOTE G_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE F_, 3
	NOTE Ash, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE E_, 3
	NOTE A_, 3
	NOTE E_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 3
	NOTE A_, 3
	NOTE Csh, 4
	NOTE D_, 4
	NOTE E_, 4
	NEXT
Pat_50A4:
	NOTE G_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE F_, 3
	NOTE Ash, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE E_, 3
	NOTE A_, 3
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE A_, 4
	WAIT
	NOTE E_, 3
	WAIT
	NOTE A_, 2
	NOTE Csh, 4
	NOTE D_, 4
	NOTE E_, 4
	NEXT
Pat_50C5:
	DRUMS $05, DrumPat_515C
	HWENV $F2, $05, $A2
	DUTY_75
	LEN 10
	RELEASE $01, $00
	ARP 0
	NOTE Gsh, 5
	LEN 5
	NOTE A_, 5
	NOTE A_, 5
	LEN 10
	NOTE A_, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE A_, 5
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	NOTE A_, 5
	NOTE A_, 5
	NOTE D_, 6
	NOTE A_, 5
	NOTE A_, 5
	NOTE A_, 5
	NOTE Gsh, 5
	LEN 5
	NOTE A_, 5
	NOTE A_, 5
	LEN 10
	NOTE A_, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE Csh, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE A_, 4
	WAIT
	NOTE A_, 3
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE E_, 3
	NOTE A_, 3
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE G_, 4
	WAIT
	WAIT
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NEXT
Pat_511A:
	NOTE Ash, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE Ash, 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE A_, 4
	WAIT
	WAIT
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE Csh, 4
	NOTE Csh, 4
	WAIT
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NEXT
Pat_513B:
	NOTE Ash, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE Ash, 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE A_, 4
	WAIT
	WAIT
	NOTE D_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE Csh, 5
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NEXT
DrumPat_515C:
	db DRUM_LEVEL + 14, 1, 0, 6, 0, 9, 0, 6
	db 0, DRUM_LOOP

; Instrument table 2, entries 1..2 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr2_0
	dw Instr2_1
Instr2_0:
	WAVE Wave_7A9F
	CH_TRANSPOSE $0C
	ARP 0
	VOLENV 15, $11, $11, $12
	END
Instr2_1:
	WAVE Wave_7A6F
	CH_TRANSPOSE $00
	ARP_OFF
	VOLENV 13, $00, $11, $11
	END

; Song 3: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong3:
	ld a, $54
	ld [wInstrTableHi], a
	ld a, $0F
	ld [wInstrTable], a
	ld de, Song3_Ch1
	call StartMusicCh1
	ld de, Song3_Ch2
	call StartMusicCh2
	ld de, Song3_Ch3
	jp StartMusicCh3
Song3_Ch1:
	dw Pat_51C0
	dw Pat_51C0
	dw Pat_51FC
	dw Pat_5243
	ORDER_LOOP Song3_Ch1
Song3_Ch2:
	dw Pat_528A
	dw Pat_528A
	dw Pat_52D9
	dw Pat_531B
	ORDER_LOOP Song3_Ch2
Song3_Ch3:
	dw Pat_5356
	dw Pat_5356
	dw Pat_539E
	dw Pat_53D5
	ORDER_LOOP Song3_Ch3
Pat_51C0:
	LEN 24
	WAIT
	INSTR 0
	LEN 16
	DRUMS $08, DrumPat_540C
	NOTE C_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	REPEAT 3
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	REPEAT_END
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE C_, 5
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE C_, 5
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	DRUMS_OFF
	CALL_CODE Drum9
	LEN 8
	NOTE G_, 3
	NEXT
Pat_51FC:
	LEN 24
	WAIT
	INSTR 0
	LEN 16
	DRUMS $08, DrumPat_540C
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE B_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE B_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE B_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE B_, 3
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	LEN 8
	NOTE E_, 2
	NEXT
Pat_5243:
	LEN 8
	WAIT
	INSTR 1
	LEN 16
	NOTE E_, 4
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
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE B_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE B_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE B_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE B_, 3
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE B_, 3
	INSTR 0
	NOTE C_, 2
	NOTE G_, 2
	DRUMS_OFF
	CALL_CODE Drum9
	LEN 8
	NOTE C_, 2
	NEXT
Pat_528A:
	LEN 24
	WAIT
	INSTR 2
	LEN 16
	NOTE C_, 3
	INSTR 1
	NOTE Dsh, 4
	INSTR 2
	NOTE G_, 3
	INSTR 1
	NOTE Dsh, 4
	INSTR 2
	NOTE C_, 3
	INSTR 1
	LEN 8
	NOTE C_, 4
	INSTR 2
	NOTE D_, 4
	LEN 16
	NOTE C_, 4
	INSTR 1
	LEN 8
	NOTE C_, 4
	INSTR 2
	NOTE D_, 4
	LEN 16
	NOTE C_, 3
	INSTR 1
	NOTE Dsh, 4
	INSTR 2
	NOTE G_, 3
	INSTR 1
	NOTE Dsh, 4
	INSTR 2
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE G_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE Gsh, 4
	INSTR 2
	NOTE C_, 4
	INSTR 1
	LEN 8
	NOTE F_, 4
	INSTR 2
	NOTE D_, 4
	LEN 16
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE G_, 3
	INSTR 1
	NOTE Dsh, 4
	INSTR 2
	NOTE G_, 3
	INSTR 1
	NOTE Dsh, 4
	INSTR 2
	NOTE G_, 3
	INSTR 1
	NOTE Dsh, 4
	INSTR 2
	LEN 8
	NOTE B_, 3
	NOTE C_, 4
	INSTR 1
	NOTE B_, 3
	INSTR 2
	NOTE C_, 4
	INSTR 1
	NOTE B_, 3
	NEXT
Pat_52D9:
	LEN 24
	WAIT
	INSTR 2
	LEN 16
	NOTE F_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE G_, 3
	INSTR 1
	NOTE Dsh, 4
	INSTR 2
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE G_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE G_, 3
	INSTR 1
	NOTE F_, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE F_, 4
	INSTR 2
	NOTE G_, 3
	INSTR 1
	NOTE F_, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE D_, 4
	INSTR 2
	NOTE C_, 3
	INSTR 1
	NOTE Dsh, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE Dsh, 4
	INSTR 2
	NOTE Dsh, 3
	INSTR 1
	NOTE Dsh, 4
	LEN 8
	NOTE E_, 4
	NEXT
Pat_531B:
	VOLENV 15, $11, $1F, $15
	LEN 8
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 16
	NOTE Gsh, 4
	LEN 8
	NOTE G_, 4
	NOTE B_, 4
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE C_, 5
	NOTE D_, 5
	LEN 16
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE B_, 4
	NOTE D_, 4
	NOTE G_, 3
	LEN 8
	NOTE B_, 4
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE Dsh, 4
	LEN 8
	NOTE C_, 4
	NEXT
Pat_5356:
	VOLENV 15, $00, $1F, $12
	ARP 0
	WAVE Wave_7A6F
	LEN 8
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE C_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE B_, 3
	LEN 16
	NOTE C_, 4
	LEN 32
	NOTE Dsh, 4
	LEN 16
	NOTE Dsh, 4
	NOTE C_, 4
	LEN 8
	NOTE C_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE B_, 3
	LEN 16
	NOTE C_, 4
	LEN 32
	NOTE Dsh, 4
	LEN 16
	NOTE Dsh, 4
	LEN 8
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 16
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 8
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 16
	NOTE G_, 4
	NOTE G_, 4
	LEN 8
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	LEN 16
	NOTE G_, 4
	NOTE D_, 4
	LEN 8
	NOTE G_, 3
	NEXT
Pat_539E:
	LEN 8
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE C_, 5
	NOTE G_, 4
	LEN 16
	NOTE Gsh, 4
	LEN 8
	NOTE Gsh, 4
	NOTE F_, 4
	LEN 16
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN 32
	NOTE D_, 4
	LEN 8
	NOTE D_, 4
	NOTE Dsh, 4
	LEN 16
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 32
	NOTE G_, 4
	LEN 8
	NOTE G_, 4
	NEXT
Pat_53D5:
	LEN 8
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE C_, 5
	NOTE D_, 5
	LEN 16
	NOTE Dsh, 5
	LEN 8
	NOTE Dsh, 5
	NOTE F_, 5
	LEN 16
	NOTE G_, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE F_, 5
	LENGTH $30
	NOTE D_, 5
	LEN 8
	NOTE D_, 5
	NOTE Dsh, 5
	LEN 16
	NOTE F_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE Dsh, 5
	LEN 32
	NOTE C_, 5
	LEN 8
	NOTE Dsh, 4
	NEXT
DrumPat_540C:
	db 1, 0, 9, 0, DRUM_LOOP

; Instrument table 3, entries 1..3 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr3_0
	dw Instr3_1
	dw Instr3_2
Instr3_0:
	HWENV $F2, $00
	ARP 0
	DUTY_50
	END
Instr3_1:
	HWENV $F2, $02, $B2
	ARP 0
	DUTY_75
	END
Instr3_2:
	HWENV $E2, $02, $82
	ARP 0
	DUTY_75
	END

; Song 4: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong4:
	ld a, $54
	ld [wInstrTableHi], a
	ld a, $0F
	ld [wInstrTable], a
	ld de, Song4_Ch1
	call StartMusicCh1
	ld de, Song4_Ch2
	call StartMusicCh2
	ld de, Song4_Ch3
	jp StartMusicCh3
Song4_Ch1:
	dw Pat_5590
	dw Pat_549D
	dw Pat_549D
	dw Pat_54F0
	dw Pat_5546
	dw Pat_549D
	dw Pat_549D
	dw Pat_54F0
	dw Pat_5546
	dw Pat_55B6
	dw Pat_55B6
	ORDER_LOOP Song4_Ch1
Song4_Ch2:
	dw Pat_5655
	dw Pat_55C9
	dw Pat_55C9
	dw Pat_55FE
	dw Pat_55C9
	dw Pat_55C9
	dw Pat_55FE
	dw Pat_5664
	dw Pat_5664
	ORDER_LOOP Song4_Ch2
Song4_Ch3:
	dw Pat_570E
	dw Pat_5681
	dw Pat_5681
	dw Pat_56C7
	dw Pat_56EA
	dw Pat_570A
	dw Pat_5497
	dw Pat_5681
	dw Pat_5681
	dw Pat_56C7
	dw Pat_56EA
	dw Pat_570C
	dw Pat_5742
	dw Pat_5742
	ORDER_LOOP Song4_Ch3
Pat_5497:
	WAVE Wave_7AEF
	CH_TRANSPOSE $00
	NEXT
Pat_549D:
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 4
	NOTE E_, 4
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	NOTE E_, 4
	INSTR 0
	NOTE B_, 2
	INSTR 1
	LEN 8
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 4
	NOTE E_, 4
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	NOTE E_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE E_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 4
	NOTE E_, 4
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	NOTE E_, 4
	INSTR 0
	NOTE B_, 2
	INSTR 1
	LEN 8
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 1
	LEN 8
	NOTE E_, 4
	NOTE E_, 4
	INSTR 0
	LEN 16
	NOTE F_, 2
	INSTR 1
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	NOTE E_, 2
	NEXT
Pat_54F0:
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	LEN 8
	NOTE Gsh, 3
	NOTE Gsh, 3
	INSTR 0
	LEN 16
	NOTE B_, 2
	INSTR 1
	NOTE Gsh, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	LEN 8
	NOTE Gsh, 3
	NOTE Gsh, 3
	INSTR 0
	LEN 16
	NOTE B_, 2
	INSTR 1
	NOTE Gsh, 3
	INSTR 0
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	LEN 8
	NOTE F_, 3
	NOTE F_, 3
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	LEN 8
	NOTE Dsh, 3
	NOTE Dsh, 3
	INSTR 0
	LEN 16
	NOTE B_, 2
	INSTR 1
	NOTE Dsh, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE E_, 3
	INSTR 0
	LEN 16
	NOTE B_, 2
	INSTR 1
	NOTE E_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE F_, 3
	NOTE E_, 3
	INSTR 0
	NOTE B_, 2
	NEXT
Pat_5546:
	LEN 16
	NOTE E_, 2
	INSTR 1
	LEN 8
	NOTE Gsh, 3
	NOTE Gsh, 3
	INSTR 0
	LEN 16
	NOTE B_, 2
	INSTR 1
	NOTE Gsh, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	LEN 8
	NOTE Gsh, 3
	NOTE Gsh, 3
	INSTR 0
	LEN 16
	NOTE B_, 2
	INSTR 1
	NOTE Gsh, 3
	INSTR 0
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	LEN 8
	NOTE F_, 3
	NOTE F_, 3
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Dsh, 3
	INSTR 0
	NOTE B_, 2
	INSTR 1
	NOTE Dsh, 3
	INSTR 1
	NOTE E_, 2
	NOTE Dsh, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE E_, 2
	WAIT2
	LEN 32
	NOTE E_, 3
	LEN 16
	NEXT
Pat_5590:
	INSTR 0
	LEN 32
	NOTE A_, 2
	NOTE F_, 2
	LEN 16
	NOTE E_, 2
	NOTE Gsh, 2
	NOTE A_, 2
	NOTE E_, 2
	NEXT
Pat_559A:
	LEN 16
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE B_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE B_, 3
	INSTR 0
	NOTE A_, 2
	NEXT
Pat_55B6:
	PAT_CALL Pat_559A
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE C_, 4
	PAT_CALL Pat_559A
	NOTE E_, 2
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE Csh, 4
	NOTE Csh, 4
	NEXT
Pat_55C9:
	INSTR 1
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE C_, 4
	NOTE C_, 4
	LEN 16
	NOTE E_, 3
	NOTE C_, 4
	NOTE B_, 3
	LEN 8
	NOTE D_, 4
	NOTE D_, 4
	LEN 16
	NOTE E_, 3
	NOTE D_, 4
	NOTE A_, 3
	LEN 8
	NOTE C_, 4
	NOTE C_, 4
	LEN 16
	NOTE E_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE A_, 3
	LEN 8
	NOTE C_, 4
	NOTE C_, 4
	LEN 16
	NOTE E_, 3
	NOTE C_, 4
	NOTE B_, 3
	LEN 8
	NOTE D_, 4
	NOTE D_, 4
	LEN 16
	NOTE E_, 3
	NOTE D_, 4
	NOTE F_, 3
	LEN 8
	NOTE C_, 4
	NOTE C_, 4
	LEN 16
	NOTE F_, 3
	NOTE C_, 4
	NOTE E_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE E_, 3
	NEXT
Pat_55FE:
	LEN 16
	NOTE E_, 3
	LEN 8
	NOTE B_, 3
	NOTE B_, 3
	LEN 16
	NOTE B_, 3
	NOTE B_, 3
	NOTE E_, 3
	LEN 8
	NOTE B_, 3
	NOTE B_, 3
	LEN 16
	NOTE B_, 3
	NOTE B_, 3
	REPEAT 2
	NOTE A_, 3
	LEN 8
	NOTE C_, 4
	NOTE C_, 4
	LEN 16
	NOTE E_, 3
	NOTE C_, 4
	REPEAT_END
	NOTE F_, 3
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	LEN 16
	NOTE E_, 3
	NOTE A_, 3
	NOTE Dsh, 3
	LEN 8
	NOTE Fsh, 3
	NOTE Fsh, 3
	LEN 16
	NOTE B_, 3
	NOTE Fsh, 3
	NOTE E_, 3
	LEN 8
	NOTE Gsh, 3
	NOTE Gsh, 3
	LEN 16
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE E_, 3
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE B_, 3
	REPEAT 2
	NOTE E_, 3
	LEN 8
	NOTE B_, 3
	NOTE B_, 3
	LEN 16
	NOTE B_, 3
	NOTE B_, 3
	REPEAT_END
	REPEAT 2
	NOTE A_, 3
	LEN 8
	NOTE C_, 4
	NOTE C_, 4
	LEN 16
	NOTE E_, 3
	NOTE C_, 4
	REPEAT_END
	NOTE F_, 3
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	LEN 16
	NOTE E_, 3
	NOTE A_, 3
	NOTE Dsh, 3
	NOTE Fsh, 3
	NOTE B_, 3
	NOTE Fsh, 3
	NOTE E_, 3
	NOTE Dsh, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE E_, 3
	WAIT2
	LEN 32
	NOTE Gsh, 3
	NEXT
Pat_5655:
	INSTR 1
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE D_, 4
	NOTE C_, 4
	LEN 16
	NOTE A_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE C_, 3
	INSTR 1
	NOTE E_, 2
	NEXT
Pat_5664:
	INSTR 1
	LEN 16
	REPEAT 2
	NOTE A_, 3
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 4
	REPEAT_END
	NOTE E_, 3
	NOTE E_, 4
	NOTE E_, 3
	NOTE E_, 4
	REPEAT 3
	NOTE A_, 3
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 4
	REPEAT_END
	NOTE E_, 3
	NOTE E_, 4
	NOTE E_, 3
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 3
	NOTE A_, 3
	LEN 8
	NOTE E_, 4
	NOTE E_, 4
	NEXT
Pat_5681:
	DRUMS $08, DrumPat_5754
	VOLENV 10, $15, $11, $11
	VIBRATO $10, $01, $05
	RELEASE $72, $A3
	LEN 24
	NOTE A_, 4
	LEN 8
	NOTE B_, 4
	LEN 16
	NOTE C_, 5
	NOTE A_, 4
	LEN 8
	NOTE B_, 4
	NOTE Ash, 4
	NOTE B_, 4
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	NOTE B_, 4
	LEN 24
	NOTE A_, 4
	LEN 8
	NOTE B_, 4
	LEN 16
	NOTE C_, 5
	NOTE A_, 4
	LEN 32
	NOTE F_, 4
	LEN 16
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	LEN 24
	NOTE A_, 4
	LEN 8
	NOTE B_, 4
	LEN 16
	NOTE C_, 5
	NOTE A_, 4
	LEN 8
	NOTE B_, 4
	NOTE Ash, 4
	NOTE B_, 4
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	NOTE B_, 4
	NOTE E_, 5
	LEN 8
	NOTE F_, 5
	NOTE E_, 5
	LEN 16
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE Gsh, 4
	LEN 32
	NOTE A_, 4
	NEXT
Pat_56C7:
	LEN 16
	NOTE B_, 4
	LEN 8
	NOTE C_, 5
	NOTE D_, 5
	LENGTH $60
	NOTE Gsh, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE B_, 4
	NOTE C_, 5
	LENGTH $60
	NOTE E_, 4
	LEN 32
	NOTE F_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE B_, 3
	LEN 16
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 5
	NOTE E_, 4
	NOTE Gsh, 4
	LEN 6
	NOTE B_, 4
	LEN 32
	NOTE E_, 5
	NEXT
Pat_56EA:
	LEN 16
	NOTE B_, 4
	LEN 8
	NOTE C_, 5
	NOTE D_, 5
	LENGTH $60
	NOTE Gsh, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE B_, 4
	NOTE C_, 5
	LENGTH $60
	NOTE E_, 4
	LEN 32
	NOTE F_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE B_, 3
	LEN 16
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	WAIT2
	LEN 24
	NOTE E_, 5
	LEN 8
	NEXT
Pat_570A:
	WAIT
	NEXT
Pat_570C:
	NOTE D_, 5
	NEXT
Pat_570E:
	DRUMS_OFF
	WAVE Wave_7A6F
	VOLENV 15, $11, $1F, $12
	ARP 0
	RELEASE $00
	LEN 16
	NOTE E_, 4
	LEN 8
	NOTE F_, 4
	NOTE E_, 4
	LEN 16
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE Gsh, 3
	LEN 32
	NOTE A_, 3
	WAVE Wave_7ACF
	CH_TRANSPOSE $0C
	NEXT
Pat_572B:
	LEN 16
	NOTE Csh, 5
	LEN 8
	NOTE D_, 5
	NOTE E_, 5
	LEN 24
	NOTE A_, 4
	LEN 8
	NOTE B_, 4
	LEN 16
	NOTE C_, 5
	NOTE A_, 4
	LEN 24
	NOTE E_, 4
	LEN 8
	NOTE A_, 4
	LEN 16
	NOTE B_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NEXT
Pat_5742:
	PAT_CALL Pat_572B
	NOTE B_, 4
	LEN 32
	NOTE C_, 5
	PAT_CALL Pat_572B
	LEN 3
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 4
	LEN 7
	NOTE Gsh, 4
	LEN 32
	NOTE A_, 4
	NEXT
DrumPat_5754:
	db 1, 0, 6, 0, 9, 0, 6, 0
	db 1, 0, 6, 0, 9, 0, 6, 6
	db DRUM_LOOP

; Song 5: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong5:
	ld a, $74
	ld [wInstrTableHi], a
	ld a, $37
	ld [wInstrTable], a
	ld de, Song5_Ch1
	call StartMusicCh1
	ld de, Song5_Ch2
	call StartMusicCh2
	ld de, Song5_Ch3
	jp StartMusicCh3

; Unreferenced (1 bytes)
	db $C9
Song5_Ch1:
	dw Pat_57C4
	dw Pat_57C9
	dw Pat_5812
	dw Pat_5828
	ORDER_LOOP Song5_Ch1
Song5_Ch2:
	dw Pat_57BE
	dw Pat_5836
	dw Pat_586E
	dw Pat_58CE
	dw Pat_58E5
	dw Pat_57C1
	dw Pat_5836
	dw Pat_57BE
	dw Pat_586E
	dw Pat_57C1
	dw Pat_58CE
	dw Pat_58E5
	ORDER_LOOP Song5_Ch2
Song5_Ch3:
	dw Pat_57BE
	dw Pat_591A
	dw Pat_595B
	dw Pat_597A
	dw Pat_57C1
	dw Pat_591A
	dw Pat_595B
	dw Pat_597A
	ORDER_LOOP Song5_Ch3
Pat_57BE:
	CH_TRANSPOSE $00
	NEXT
Pat_57C1:
	CH_TRANSPOSE $0C
	NEXT
Pat_57C4:
	LEN 14
	DRUMS $0E, DrumPat_5980
Pat_57C9:
	REPEAT 7
	INSTR 6
	NOTE C_, 2
	INSTR 2
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 6
	NOTE G_, 2
	INSTR 2
	NOTE D_, 4
	REPEAT_END
	INSTR 6
	NOTE C_, 2
	INSTR 2
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE Ash, 3
	NEXT
Pat_57E2:
	REPEAT 4
	INSTR 6
	NOTE C_, 2
	INSTR 2
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 6
	NOTE G_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 6
	REPEAT_END
	NOTE Dsh, 2
	INSTR 1
	NOTE Dsh, 4
	NOTE Dsh, 4
	INSTR 0
	NOTE Dsh, 3
	INSTR 6
	NOTE Ash, 2
	INSTR 2
	NOTE G_, 4
	INSTR 6
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	NOTE F_, 3
	INSTR 6
	NOTE C_, 3
	INSTR 1
	NOTE Dsh, 4
	INSTR 6
	NOTE C_, 2
	INSTR 2
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 6
	NOTE G_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 6
	NEXT
Pat_5812:
	PAT_CALL Pat_57E2
	NOTE C_, 2
	INSTR 2
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE Ash, 3
	PAT_CALL Pat_57E2
	LEN 28
	NOTE F_, 2
	NOTE G_, 2
	NOTE Dsh, 2
	LEN 14
	NEXT
Pat_5828:
	REPEAT 4
	INSTR 6
	NOTE C_, 2
	INSTR 2
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 6
	NOTE G_, 2
	INSTR 2
	NOTE D_, 4
	REPEAT_END
	NEXT
Pat_5836:
	LEN 14
	HWENV $D1, $02, $53
	ARP 0
	DUTY_75
	VIBRATO $0E, $01, $06
	NOTE G_, 4
	NOTE G_, 4
	REPEAT 2
	NOTE G_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 4
	WAIT
	REPEAT_END
	NOTE G_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	WAIT
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	WAIT
	NEXT
Pat_586E:
	HWENV $6D, $1C, $C7
	DUTY_75
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	NOTE Ash, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	NOTE Dsh, 4
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 4
	NOTE D_, 4
	LEN 28
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE Ash, 3
	LEN 14
	NEXT
Pat_58A2:
	NOTE G_, 3
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE G_, 4
	WAIT
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	LEN 7
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	WAIT
	LEN 14
	NOTE Dsh, 4
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE F_, 4
	WAIT
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	WAIT
	WAIT
	NEXT
Pat_58CE:
	PAT_CALL Pat_58A2
	WAIT
	NOTE D_, 4
	WAIT
	NOTE F_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE C_, 4
	NOTE Ash, 3
	PAT_CALL Pat_58A2
	NOTE F_, 4
	LEN 28
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Dsh, 4
	LEN 14
	NEXT
Pat_58E5:
	LENGTH $70
	NOTE C_, 4
	WAIT
	WAIT
	NEXT
Pat_58EB:
	LEN 14
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE F_, 3
	NOTE G_, 3
	WAIT
	NOTE G_, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE F_, 3
	NOTE G_, 3
	WAIT
	NOTE G_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE F_, 3
	NOTE G_, 3
	WAIT
	NOTE G_, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE F_, 3
	NOTE G_, 3
	WAIT
	NOTE G_, 3
	NOTE F_, 3
	LEN 28
	NOTE Dsh, 3
	NOTE D_, 3
	LENGTH $38
	NEXT
Pat_591A:
	VIBRATO $0E, $01, $06
	VOLENV 12, $11, $1F, $14
	ARP 0
	WAVE Wave_7A4F
	PAT_CALL Pat_58EB
	WAIT
	PAT_CALL Pat_58EB
	NOTE C_, 3
	NEXT
Pat_592F:
	LEN 14
	NOTE C_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	WAIT
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Ash, 4
	LEN 7
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	WAIT
	LEN 14
	NOTE G_, 4
	WAIT
	NOTE C_, 5
	WAIT
	WAIT
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE D_, 5
	WAIT
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE C_, 5
	WAIT
	NEXT
Pat_595B:
	VOLENV 10, $1C, $1F, $35
	WAVE Wave_7A2F
	PAT_CALL Pat_592F
	NOTE G_, 4
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	PAT_CALL Pat_592F
	WAIT
	NOTE D_, 5
	LEN 28
	NOTE Dsh, 5
	LENGTH $54
	NOTE C_, 5
	NEXT
Pat_597A:
	LENGTH $70
	NOTE G_, 4
	WAIT
	WAIT
	NEXT
DrumPat_5980:
	db DRUM_TEMPO + 14, 7, 0, 9, 6, 1, 4, 1
	db DRUM_TEMPO + 7, 6, 6, DRUM_TEMPO + 14, 9, 6, 1, 4
	db 1, 6, 9, 6, 1, 4, 1, DRUM_TEMPO + 7
	db 6, 6, DRUM_TEMPO + 14, 9, 1, 9, 9, 1
	db 6, 9, 6, 1, 4, 1, DRUM_TEMPO + 7, 6
	db 6, DRUM_TEMPO + 14, 9, 6, 1, 4, 1, 6
	db 9, 6, 1, 4, 1, DRUM_TEMPO + 7, 6, 6
	db DRUM_TEMPO + 14, 9, 1, 9, DRUM_TEMPO + 7, 9, 9, DRUM_LOOP

; Song 6: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong6:
	ld a, $74
	ld [wInstrTableHi], a
	ld a, $37
	ld [wInstrTable], a
	ld de, Song6_Ch1
	call StartMusicCh1
	ld de, Song6_Ch2
	call StartMusicCh2
	ld de, Song6_Ch3
	jp StartMusicCh3
Song6_Ch1:
	dw Pat_5A2C
	dw Pat_5A2C
	dw Pat_5A6A
	dw Pat_5A2C
	dw Pat_5A2C
	dw Pat_5A6A
	dw Pat_5A86
	dw Pat_5A86
	dw Pat_5AAF
	ORDER_LOOP Song6_Ch1
Song6_Ch2:
	dw Pat_5ABA
	dw Pat_5ABA
	dw Pat_5AE6
	dw Pat_5ABA
	dw Pat_5ABA
	dw Pat_5AE6
	dw Pat_5B09
	dw Pat_5B09
	dw Pat_5B35
	ORDER_LOOP Song6_Ch2
Song6_Ch3:
	dw Pat_5B42
	dw Pat_5B42
	dw Pat_5B86
	dw Pat_5B42
	dw Pat_5B42
	dw Pat_5B86
	dw Pat_5BB4
	dw Pat_5BD1
	dw Pat_5BF7
	ORDER_LOOP Song6_Ch3
Pat_5A1E:
	INSTR 6
	REPEAT 2
	LEN 18
	NOTE D_, 2
	LEN 9
	NOTE D_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 6
	NOTE D_, 3
	NOTE D_, 2
	REPEAT_END
	LEN 18
	NEXT
Pat_5A2C:
	PAT_CALL Pat_5A1E
	NOTE C_, 2
	LEN 9
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 6
	NOTE C_, 3
	NOTE C_, 2
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 2
	INSTR 2
	NOTE G_, 4
	INSTR 6
	NOTE G_, 3
	NOTE G_, 2
	PAT_CALL Pat_5A1E
	NOTE F_, 2
	LEN 9
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 6
	NOTE C_, 3
	NOTE F_, 2
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE D_, 3
	NOTE G_, 2
	NEXT
Pat_5A55:
	REPEAT 2
	LEN 18
	NOTE A_, 2
	LEN 9
	NOTE A_, 2
	INSTR 1
	NOTE A_, 4
	INSTR 6
	NOTE E_, 3
	NOTE A_, 2
	REPEAT_END
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE D_, 3
	NOTE G_, 2
	NEXT
Pat_5A6A:
	INSTR 6
	PAT_CALL Pat_5A55
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE D_, 3
	NOTE G_, 2
	PAT_CALL Pat_5A55
	INSTR 6
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 6
	NOTE F_, 2
	NOTE E_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 6
	NOTE E_, 2
	NEXT
Pat_5A86:
	REPEAT 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 6
	NOTE D_, 3
	NOTE D_, 2
	REPEAT_END
	REPEAT 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 6
	NOTE D_, 3
	NOTE D_, 2
	REPEAT_END
	REPEAT 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	INSTR 1
	NOTE E_, 4
	INSTR 6
	NOTE D_, 3
	NOTE D_, 2
	REPEAT_END
	REPEAT 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 6
	NOTE D_, 3
	NOTE D_, 2
	REPEAT_END
	NEXT
Pat_5AAF:
	REPEAT 8
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 6
	NOTE C_, 3
	NOTE C_, 2
	REPEAT_END
	NEXT
Pat_5ABA:
	HWENV $92, $00
	DUTY_50
	ARP 0
	LEN 27
	NOTE F_, 4
	LEN 9
	NOTE D_, 4
	NOTE E_, 4
	LEN 36
	NOTE F_, 4
	LEN 9
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 18
	NOTE E_, 4
	LEN 36
	NOTE C_, 4
	LEN 18
	NOTE D_, 5
	LEN 36
	NOTE Ash, 4
	LEN 27
	NOTE F_, 4
	LEN 9
	NOTE D_, 4
	NOTE E_, 4
	LEN 36
	NOTE F_, 4
	LEN 9
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 18
	NOTE A_, 4
	LEN 36
	NOTE F_, 4
	LEN 18
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NEXT
Pat_5AE6:
	LEN 9
	NOTE Csh, 5
	NOTE B_, 4
	NOTE A_, 4
	LENGTH $51
	NOTE E_, 4
	LEN 9
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	LENGTH $51
	NOTE D_, 4
	LEN 9
	NOTE Csh, 5
	NOTE B_, 4
	NOTE A_, 4
	LENGTH $51
	NOTE E_, 4
	LEN 9
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 27
	NOTE D_, 4
	LEN 9
	NOTE C_, 4
	NOTE Ash, 3
	NOTE A_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NEXT
Pat_5B09:
	INSTR 2
	LEN 9
	REPEAT 2
	NOTE D_, 4
	INSTR 0
	NOTE F_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	INSTR 2
	REPEAT_END
	INSTR 1
	REPEAT 2
	NOTE Dsh, 4
	INSTR 0
	NOTE F_, 4
	NOTE D_, 4
	NOTE Ash, 4
	NOTE F_, 4
	NOTE D_, 4
	INSTR 1
	REPEAT_END
	REPEAT 2
	NOTE E_, 4
	INSTR 0
	NOTE F_, 4
	NOTE D_, 4
	NOTE B_, 4
	NOTE F_, 4
	NOTE D_, 4
	INSTR 1
	REPEAT_END
	REPEAT 2
	NOTE Dsh, 4
	INSTR 0
	NOTE F_, 4
	NOTE D_, 4
	NOTE Ash, 4
	NOTE F_, 4
	NOTE D_, 4
	INSTR 1
	REPEAT_END
	NEXT
Pat_5B35:
	INSTR 0
	LEN 9
	REPEAT 8
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	REPEAT_END
	REPEAT 8
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	REPEAT_END
	NEXT
Pat_5B42:
	DRUMS $09, DrumPat_5C1C
	VOLENV 12, $13, $1F, $1F
	VIBRATO $09, $01, $06
	ARP 0
	RELEASE $01, $50
	WAVE Wave_7ADF
	CH_TRANSPOSE $0C
	LEN 9
	NOTE A_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 18
	NOTE A_, 4
	LEN 9
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 18
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE Ash, 3
	LEN 9
	NOTE A_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 18
	NOTE A_, 4
	LEN 9
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 18
	NOTE C_, 5
	NOTE A_, 4
	NOTE F_, 4
	LEN 9
	NOTE B_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	LEN 18
	NOTE D_, 5
	NEXT
Pat_5B86:
	LEN 9
	NOTE E_, 5
	NOTE D_, 5
	NOTE Csh, 5
	LEN 36
	NOTE A_, 4
	LEN 9
	NOTE E_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE Csh, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	LEN 45
	NOTE G_, 4
	LEN 9
	NOTE A_, 4
	NOTE B_, 4
	NOTE Csh, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE Csh, 5
	LEN 36
	NOTE A_, 4
	LEN 9
	NOTE E_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE Csh, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	LEN 27
	NOTE G_, 4
	LEN 9
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NEXT
Pat_5BB4:
	LENGTH $5A
	NOTE D_, 4
	LEN 9
	NOTE E_, 4
	NOTE F_, 4
	LENGTH $5A
	NOTE G_, 4
	LEN 9
	NOTE F_, 4
	NOTE E_, 4
	LENGTH $48
	NOTE D_, 4
	LEN 18
	NOTE F_, 4
	NOTE E_, 4
	LENGTH $36
	NOTE D_, 4
	LEN 9
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 5
	NOTE D_, 5
	NEXT
Pat_5BD1:
	LEN 36
	NOTE F_, 5
	LEN 9
	NOTE E_, 5
	NOTE F_, 5
	LEN 18
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	LEN 36
	NOTE A_, 4
	LEN 9
	NOTE G_, 4
	NOTE A_, 4
	LEN 18
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 4
	LEN 9
	NOTE E_, 4
	NOTE F_, 4
	LENGTH $48
	NOTE E_, 4
	LEN 9
	NOTE F_, 4
	NOTE G_, 4
	LENGTH $36
	NOTE F_, 4
	LEN 9
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NEXT
Pat_5BF7:
	LENGTH $5A
	NOTE G_, 4
	LEN 9
	NOTE F_, 4
	NOTE E_, 4
	LENGTH $5A
	NOTE C_, 4
	LEN 9
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 5
	NOTE D_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE C_, 4
	NEXT
DrumPat_5C1C:
	db DRUM_LEVEL + 15, 1, DRUM_LEVEL + 12, 6, 6, DRUM_LEVEL + 15, 2, DRUM_LEVEL + 12
	db 6, 6, DRUM_LOOP

; Song 7: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong7:
	ld a, $74
	ld [wInstrTableHi], a
	ld a, $37
	ld [wInstrTable], a
	ld de, Song7_Ch1
	call StartMusicCh1
	ld de, Song7_Ch2
	call StartMusicCh2
	ld de, Song7_Ch3
	jp StartMusicCh3

; Unreferenced (1 bytes)
	db $C9
Song7_Ch1:
	dw Pat_5C74
	dw Pat_5CC7
	dw Pat_5CEC
	dw Pat_5CC7
	dw Pat_5D0E
	dw Pat_5C74
	ORDER_LOOP Song7_Ch1
Song7_Ch2:
	dw Pat_5D36
	dw Pat_5D7C
	dw Pat_5D9A
	dw Pat_5D7C
	dw Pat_5DBE
	dw Pat_5D36
	ORDER_LOOP Song7_Ch2
Song7_Ch3:
	dw Pat_5DE4
	dw Pat_5E53
	dw Pat_5E6F
	dw Pat_5E53
	dw Pat_5E85
	dw Pat_5DE4
	ORDER_LOOP Song7_Ch3
Pat_5C74:
	HWENV $F2, $0A, $E1
	ARP 0
	LEN 10
	DUTY_50
	DRUMS $0A, DrumPat_5E9D
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 3
	REPEAT 3
	NOTE A_, 2
	WAIT
	NOTE A_, 3
	REPEAT_END
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 3
	REPEAT 3
	NOTE E_, 2
	WAIT
	NOTE E_, 3
	REPEAT_END
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 3
	REPEAT 3
	NOTE A_, 2
	WAIT
	NOTE A_, 3
	REPEAT_END
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 3
	REPEAT 3
	NOTE E_, 2
	WAIT
	NOTE E_, 3
	REPEAT_END
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 3
	REPEAT 3
	NOTE F_, 2
	WAIT
	NOTE F_, 3
	REPEAT_END
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 3
	REPEAT 3
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	REPEAT_END
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 3
	REPEAT 3
	NOTE A_, 2
	WAIT
	NOTE A_, 3
	REPEAT_END
	DRUMS $0A, DrumPat_5EAA
	LEN 20
	NOTE A_, 2
	NOTE B_, 2
	NOTE C_, 3
	LEN 10
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NEXT
Pat_5CC7:
	DRUMS $0A, DrumPat_5E9D
	REPEAT 4
	NOTE F_, 2
	WAIT
	NOTE F_, 3
	REPEAT_END
	REPEAT 2
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	REPEAT_END
	NOTE B_, 2
	NOTE G_, 2
	NOTE C_, 3
	NOTE B_, 2
	NOTE D_, 2
	NOTE G_, 2
	REPEAT 4
	NOTE F_, 2
	WAIT
	NOTE F_, 3
	REPEAT_END
	REPEAT 2
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	REPEAT_END
	NOTE B_, 2
	NOTE C_, 3
	NOTE B_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	NEXT
Pat_5CEC:
	REPEAT 4
	NOTE F_, 2
	WAIT
	NOTE F_, 3
	REPEAT_END
	REPEAT 2
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	REPEAT_END
	NOTE B_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	REPEAT 4
	NOTE E_, 2
	WAIT
	NOTE E_, 3
	REPEAT_END
	NOTE A_, 2
	WAIT
	NOTE A_, 2
	NOTE A_, 3
	NOTE E_, 3
	NOTE A_, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 2
	NEXT
Pat_5D0E:
	REPEAT 4
	NOTE F_, 2
	WAIT
	NOTE F_, 3
	REPEAT_END
	REPEAT 2
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	REPEAT_END
	NOTE B_, 2
	NOTE G_, 2
	NOTE C_, 3
	NOTE B_, 2
	NOTE D_, 2
	NOTE G_, 2
	REPEAT 3
	NOTE A_, 2
	WAIT
	NOTE A_, 3
	REPEAT_END
	NOTE E_, 3
	WAIT
	NOTE E_, 2
	DRUMS $0A, DrumPat_5EAA
	LEN 20
	NOTE A_, 2
	NOTE B_, 2
	NOTE C_, 3
	LEN 10
	NOTE A_, 2
	NOTE B_, 2
	NOTE C_, 3
	NOTE A_, 2
	WAIT
	NOTE G_, 2
	NEXT
Pat_5D36:
	INSTR 2
	LEN 10
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 30
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 10
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	LEN 30
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	LEN 10
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 30
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 10
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	LEN 30
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	INSTR 1
	LEN 10
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	LEN 30
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	LEN 10
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 30
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	INSTR 2
	LEN 10
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 30
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 20
	NOTE A_, 3
	NOTE A_, 3
	INSTR 1
	NOTE Ash, 3
	INSTR 2
	LEN 30
	NOTE A_, 3
	INSTR 1
	NOTE G_, 3
	NEXT
Pat_5D7C:
	LEN 10
	REPEAT 4
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE A_, 3
	NOTE C_, 4
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE B_, 3
	NOTE D_, 4
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE A_, 3
	NOTE C_, 4
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE B_, 3
	NOTE D_, 4
	REPEAT_END
	NEXT
Pat_5D9A:
	REPEAT 4
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE A_, 3
	NOTE C_, 4
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE B_, 3
	NOTE D_, 4
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE E_, 3
	INSTR 0
	NOTE B_, 3
	NOTE E_, 4
	REPEAT_END
	REPEAT 2
	INSTR 2
	NOTE A_, 3
	INSTR 0
	NOTE E_, 4
	NOTE A_, 4
	REPEAT_END
	REPEAT 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE D_, 4
	NOTE G_, 4
	REPEAT_END
	NEXT
Pat_5DBE:
	REPEAT 4
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE A_, 3
	NOTE C_, 4
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE B_, 3
	NOTE D_, 4
	REPEAT_END
	REPEAT 4
	INSTR 2
	NOTE A_, 3
	INSTR 0
	NOTE C_, 4
	NOTE E_, 4
	REPEAT_END
	INSTR 2
	LEN 20
	NOTE A_, 3
	NOTE A_, 3
	INSTR 1
	NOTE Ash, 3
	INSTR 2
	NOTE A_, 3
	INSTR 0
	LEN 10
	NOTE A_, 3
	INSTR 2
	NOTE A_, 3
	INSTR 0
	NOTE B_, 3
	NOTE C_, 4
	NEXT
Pat_5DE4:
	VOLENV 10, $12, $1F, $10
	VIBRATO $14, $01, $04
	ARP 0
	WAVE Wave_7B1F
	RELEASE $03, $02
	LEN 10
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	LENGTH $50
	NOTE E_, 4
	LEN 10
	WAIT2
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	LENGTH $50
	NOTE B_, 3
	LEN 10
	WAIT2
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	LENGTH $32
	NOTE E_, 4
	LEN 10
	NOTE E_, 4
	NOTE A_, 4
	WAIT2
	NOTE C_, 5
	LEN 20
	NOTE B_, 4
	LEN 10
	NOTE G_, 4
	LENGTH $32
	NOTE E_, 5
	LEN 10
	WAIT2
	LEN 20
	NOTE B_, 4
	LEN 10
	WAIT2
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	LEN 40
	NOTE F_, 4
	LEN 10
	WAIT2
	NOTE F_, 4
	LEN 20
	NOTE A_, 4
	LEN 10
	NOTE C_, 5
	LEN 20
	NOTE B_, 4
	LEN 10
	NOTE G_, 4
	LEN 20
	NOTE D_, 4
	LEN 10
	WAIT2
	LEN 20
	NOTE C_, 4
	LEN 10
	WAIT2
	LEN 20
	NOTE B_, 3
	LEN 10
	WAIT2
	LENGTH $50
	NOTE A_, 3
	LEN 10
	NOTE B_, 3
	WAIT2
	NOTE C_, 4
	WAIT2
	LENGTH $78
	NOTE A_, 4
	NEXT
Pat_5E44:
	LEN 10
	NOTE F_, 2
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	LEN 30
	NOTE F_, 4
	NOTE E_, 4
	LEN 20
	NOTE E_, 4
	LEN 10
	NOTE D_, 4
	NEXT
Pat_5E53:
	VOLENV 15, $11, $1F, $14
	WAVE Wave_7A1F
	CH_TRANSPOSE $0C
	PAT_CALL Pat_5E44
	LENGTH $5A
	NOTE G_, 3
	PAT_CALL Pat_5E44
	LEN 30
	NOTE G_, 4
	LEN 10
	NOTE B_, 2
	NOTE C_, 3
	NOTE B_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	NEXT
Pat_5E6F:
	PAT_CALL Pat_5E44
	LENGTH $3C
	NOTE G_, 3
	LEN 30
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE E_, 4
	NOTE D_, 4
	LEN 20
	NOTE D_, 4
	LEN 10
	NOTE C_, 4
	LEN 30
	NOTE A_, 3
	LENGTH $3C
	NOTE G_, 1
	NEXT
Pat_5E85:
	PAT_CALL Pat_5E44
	LENGTH $3C
	NOTE B_, 3
	LEN 30
	NOTE C_, 4
	LEN 20
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	LENGTH $3C
	NOTE A_, 3
	CH_TRANSPOSE $00
	NEXT
DrumPat_5E9D:
	db DRUM_LEVEL + 15, 1, DRUM_LEVEL + 14, 6, DRUM_LEVEL + 13, 6, DRUM_LEVEL + 15, 2
	db DRUM_LEVEL + 14, 6, DRUM_LEVEL + 13, 6, DRUM_LOOP
DrumPat_5EAA:
	db 7, 0, 7, 0, 7, 0, 2, 6
	db 1, 2, 2, 2, DRUM_LOOP

; Song 8: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong8:
	ld a, $74
	ld [wInstrTableHi], a
	ld a, $37
	ld [wInstrTable], a
	ld de, Song8_Ch1
	call StartMusicCh1
	ld de, Song8_Ch2
	call StartMusicCh2
	ld de, Song8_Ch3
	jp StartMusicCh3
Song8_Ch1:
	dw Pat_5F9C
Loop_5ED5:
	dw Pat_5EFD
	dw Pat_5F53
	dw Pat_5F53
	dw Pat_5FB8
	ORDER_LOOP Loop_5ED5
Song8_Ch2:
	dw Pat_602C
Loop_5EE3:
	dw Pat_6146
	dw Pat_6001
	dw Pat_6001
	dw Pat_6058
	ORDER_LOOP Loop_5EE3
Song8_Ch3:
	dw Pat_60DB
Loop_5EF1:
	dw Pat_61C0
	dw Pat_6091
	dw Pat_6091
	dw Pat_6116
	ORDER_LOOP Loop_5EF1
Pat_5EFD:
	LEN 12
	REPEAT 6
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	REPEAT_END
	REPEAT 8
	INSTR 6
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 6
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	REPEAT_END
	REPEAT 7
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	REPEAT_END
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE Ash, 4
	INSTR 6
	NOTE D_, 2
	INSTR 1
	NOTE Ash, 4
	REPEAT 4
	INSTR 6
	NOTE C_, 3
	INSTR 1
	NOTE C_, 5
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE C_, 5
	REPEAT_END
	REPEAT 2
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	REPEAT_END
	REPEAT 2
	INSTR 6
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 6
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	REPEAT_END
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE A_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE B_, 2
	INSTR 1
	NOTE G_, 4
	NEXT
Pat_5F53:
	REPEAT 4
	INSTR 6
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	REPEAT_END
	REPEAT 2
	INSTR 6
	NOTE D_, 3
	INSTR 1
	NOTE D_, 4
	INSTR 6
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	REPEAT_END
	INSTR 6
	NOTE D_, 3
	INSTR 1
	NOTE D_, 4
	INSTR 6
	NOTE C_, 3
	INSTR 1
	NOTE D_, 4
	INSTR 6
	NOTE B_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 6
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	REPEAT 4
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	REPEAT_END
	REPEAT 2
	INSTR 6
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	REPEAT_END
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE Gsh, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE A_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE B_, 2
	INSTR 1
	NOTE G_, 4
	NEXT
Pat_5F9C:
	INSTR 6
	LEN 24
	NOTE G_, 2
	LEN 18
	NOTE G_, 2
	LEN 6
	NOTE D_, 2
	LEN 12
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE C_, 3
	LEN 18
	NOTE D_, 2
	LEN 6
	NOTE D_, 2
	LEN 12
	NOTE E_, 2
	NOTE Fsh, 2
	NOTE G_, 2
	LEN 6
	NOTE B_, 2
	NOTE D_, 3
	LEN 12
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	NEXT
Pat_5FB8:
	INSTR 6
	LEN 12
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 6
	NOTE C_, 2
	INSTR 1
	LEN 6
	NOTE C_, 4
	INSTR 6
	NOTE G_, 2
	LEN 12
	NOTE C_, 2
	INSTR 1
	LEN 6
	NOTE C_, 4
	NOTE C_, 4
	LEN 12
	NOTE C_, 4
	INSTR 6
	NOTE G_, 2
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 6
	NOTE C_, 2
	INSTR 1
	LEN 6
	NOTE C_, 4
	INSTR 6
	NOTE G_, 2
	LEN 12
	NOTE C_, 2
	INSTR 1
	LEN 6
	NOTE C_, 4
	NOTE C_, 4
	INSTR 6
	LEN 12
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 6
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 6
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 6
	NOTE C_, 3
	INSTR 1
	NOTE F_, 4
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE C_, 2
	NOTE G_, 2
	LEN 24
	NOTE C_, 2
	NEXT
Pat_6001:
	LEN 12
	HWENV $F2, $04, $A1
	REPEAT 4
	NOTE E_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE G_, 3
	REPEAT_END
	REPEAT 4
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	REPEAT_END
	LEN 12
	REPEAT 4
	NOTE G_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	REPEAT_END
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	LEN 6
	REPEAT 2
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE B_, 3
	REPEAT_END
	LEN 12
	REPEAT 2
	NOTE D_, 4
	NOTE B_, 3
	NOTE D_, 4
	NOTE B_, 3
	REPEAT_END
	NEXT
Pat_602C:
	HWENV $F0, $00
	ARP 0
	DUTY_75
	RELEASE $02, $F1
	LEN 18
	NOTE G_, 3
	LEN 6
	WAIT2
	LEN 12
	NOTE G_, 3
	LEN 6
	WAIT2
	NOTE D_, 3
	NOTE G_, 3
	WAIT2
	NOTE A_, 3
	WAIT2
	NOTE B_, 3
	WAIT2
	NOTE C_, 4
	WAIT2
	LEN 18
	NOTE D_, 3
	LEN 6
	NOTE D_, 3
	NOTE E_, 3
	WAIT2
	NOTE Fsh, 3
	WAIT2
	LEN 12
	NOTE G_, 3
	LEN 6
	NOTE B_, 3
	NOTE D_, 4
	LEN 12
	NOTE G_, 3
	WAIT2
	RELEASE $00
	NEXT
Pat_6058:
	LEN 12
	NOTE C_, 3
	WAIT2
	NOTE C_, 3
	LEN 6
	WAIT2
	NOTE D_, 3
	LEN 12
	NOTE C_, 3
	LEN 24
	WAIT2
	LEN 12
	NOTE G_, 3
	NOTE C_, 3
	WAIT2
	NOTE C_, 3
	LEN 6
	WAIT2
	NOTE D_, 3
	LEN 12
	NOTE C_, 3
	LEN 6
	NOTE G_, 4
	NOTE F_, 4
	LEN 12
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE G_, 4
	LEN 6
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	LEN 12
	NOTE C_, 5
	LEN 6
	NOTE B_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 12
	NOTE E_, 4
	LEN 6
	NOTE C_, 4
	NOTE B_, 3
	LEN 24
	NOTE C_, 4
	NEXT
Pat_6091:
	WAVE Wave_7A9F
	VOLENV 15, $15, $1F, $11
	DRUMS $06, DrumPat_6236
	LEN 12
	NOTE C_, 4
	REPEAT 2
	LEN 6
	NOTE C_, 5
	NOTE B_, 4
	LEN 12
	NOTE C_, 5
	LEN 24
	NOTE G_, 4
	REPEAT_END
	LEN 6
	NOTE C_, 5
	NOTE B_, 4
	LEN 12
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE D_, 5
	NOTE A_, 4
	LENGTH $48
	NOTE A_, 4
	LEN 24
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	LEN 12
	NOTE G_, 3
	REPEAT 2
	LEN 6
	NOTE B_, 4
	NOTE Ash, 4
	LEN 12
	NOTE B_, 4
	LEN 24
	NOTE G_, 4
	REPEAT_END
	LEN 6
	NOTE B_, 4
	NOTE Ash, 4
	LEN 12
	NOTE B_, 4
	NOTE Ash, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE G_, 4
	LENGTH $48
	NOTE G_, 4
	LEN 24
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE B_, 3
	NEXT
Pat_60DB:
	DRUMS $0C, DrumPat_623F
	VOLENV 15, $11, $1A, $18
	VIBRATO $0C, $01, $04
	RELEASE $62, $51
	ARP_OFF
	CH_TRANSPOSE $0C
	WAVE Wave_7ADF
	LEN 18
	NOTE G_, 4
	LEN 6
	WAIT2
	LEN 12
	NOTE G_, 4
	LEN 6
	WAIT2
	NOTE Fsh, 4
	NOTE G_, 4
	WAIT2
	NOTE A_, 4
	WAIT2
	NOTE B_, 4
	WAIT2
	NOTE C_, 5
	WAIT2
	LEN 3
	REPEAT 7
	NOTE D_, 5
	NOTE E_, 5
	REPEAT_END
	NOTE D_, 5
	NOTE B_, 4
	LEN 12
	NOTE G_, 4
	LEN 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE D_, 5
	LEN 12
	NOTE G_, 5
	ARP 0
Pat_6111:
	WAVE Wave_7B0F
	NOTE D_, 4
	NEXT
Pat_6116:
	DRUMS $0C, DrumPat_623F
	WAVE Wave_7ADF
	VOLENV 15, $11, $1A, $18
	REPEAT 2
	LEN 12
	NOTE C_, 4
	WAIT2
	NOTE C_, 4
	LEN 6
	WAIT2
	NOTE G_, 3
	LEN 12
	NOTE C_, 4
	LEN 36
	WAIT2
	REPEAT_END
	LEN 12
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE E_, 4
	LEN 24
	NOTE D_, 4
	LEN 12
	NOTE D_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	LEN 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	LEN 12
	NOTE C_, 5
	PAT_GOTO Pat_6111
Pat_6146:
	ARP 0
	DUTY_75
	HWENV $F1, $02, $73
	LEN 12
	WAIT
	REPEAT 3
	LEN 12
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	LENGTH $3C
	NOTE D_, 5
	REPEAT_END
	LEN 12
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	NOTE B_, 5
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	LENGTH $3C
	NOTE Fsh, 5
	REPEAT 2
	LEN 12
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	LENGTH $3C
	NOTE Fsh, 5
	REPEAT_END
	LEN 12
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	LEN 24
	NOTE B_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE D_, 5
	REPEAT 2
	LENGTH $3C
	NOTE D_, 5
	LEN 12
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	REPEAT_END
	LENGTH $3C
	NOTE D_, 5
	LEN 12
	NOTE F_, 5
	NOTE E_, 5
	NOTE Dsh, 5
	LEN 24
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE G_, 5
	LEN 36
	NOTE G_, 5
	LEN 12
	NOTE G_, 5
	LEN 24
	NOTE Fsh, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE G_, 5
	LEN 36
	NOTE B_, 5
	LEN 12
	NOTE B_, 5
	NOTE C_, 6
	NOTE B_, 5
	NOTE A_, 5
	NOTE G_, 5
	LEN 24
	NOTE Fsh, 5
	NOTE A_, 5
	NOTE G_, 5
	LEN 18
	NOTE G_, 5
	LEN 6
	NOTE G_, 5
	LEN 36
	NOTE G_, 5
	LEN 12
	NOTE E_, 3
	NEXT
Pat_61A7:
	LEN 12
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE B_, 4
	LEN 24
	NOTE D_, 4
	LEN 36
	NOTE D_, 4
	LEN 12
	NOTE B_, 3
	NOTE C_, 4
	NOTE Csh, 4
	LEN 24
	NOTE D_, 4
	LEN 36
	NOTE D_, 4
	LEN 12
	NOTE D_, 4
	NOTE E_, 4
	NEXT
Pat_61C0:
	DRUMS $06, DrumPat_6211
	PAT_CALL Pat_61A7
	NOTE G_, 4
	LENGTH $54
	NOTE Fsh, 4
	LEN 12
	NOTE D_, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 24
	NOTE G_, 4
	LENGTH $30
	NOTE Fsh, 4
	LEN 12
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	LEN 24
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	LEN 36
	NOTE D_, 4
	LEN 12
	NOTE D_, 4
	PAT_CALL Pat_61A7
	NOTE F_, 4
	LENGTH $54
	NOTE E_, 4
	LEN 12
	NOTE E_, 4
	LEN 36
	NOTE A_, 4
	LEN 12
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE Csh, 5
	LEN 24
	NOTE D_, 5
	LEN 36
	NOTE G_, 4
	LEN 12
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	LEN 24
	NOTE D_, 4
	NOTE B_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 18
	NOTE G_, 4
	LEN 6
	NOTE G_, 4
	LENGTH $30
	NOTE G_, 4
	NEXT
DrumPat_6211:
	db DRUM_REPEAT + 3, 1, 0, 6, 0, 9, 0, 6
	db 0, DRUM_REPEAT_END, 1, 0, 6, 0, 9, 0
	db 1, 0, DRUM_REPEAT + 3, 1, 0, 6, 0, 9
	db 0, 6, 0, DRUM_REPEAT_END, 1, 0, 9, 9
	db 9, 0, 9, 0, DRUM_LOOP
DrumPat_6236:
	db 1, 0, 4, 6, 9, 0, 4, 6
	db DRUM_LOOP
DrumPat_623F:
	db 1, 6, 1, 6, DRUM_LOOP

; Song 9: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong9:
	ld a, $74
	ld [wInstrTableHi], a
	ld a, $37
	ld [wInstrTable], a
	ld de, Song9_Ch1
	call StartMusicCh1
	ld de, Song9_Ch2
	call StartMusicCh2
	ld de, Song9_Ch3
	jp StartMusicCh3
Song9_Ch1:
	dw Pat_6290
	dw Pat_62F2
	dw Pat_634E
	dw Pat_63AC
	dw Pat_646A
	dw Pat_640B
	ORDER_LOOP Song9_Ch1
Song9_Ch2:
	dw Pat_64D0
	dw Pat_651E
	dw Pat_6561
	dw Pat_65AC
	dw Pat_6630
	dw Pat_65F1
	ORDER_LOOP Song9_Ch2
Song9_Ch3:
	dw Pat_6657
	dw Pat_66A3
	dw Pat_66D4
	dw Pat_6719
	dw Pat_6786
	dw Pat_6757
	ORDER_LOOP Song9_Ch3
Pat_6290:
	RELEASE $02, $52
	INSTR 10
	LEN 22
	NOTE A_, 2
	INSTR 2
	LEN 11
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE A_, 2
	LEN 11
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE G_, 2
	LEN 11
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 10
	NOTE A_, 2
	LEN 22
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	INSTR 2
	LEN 11
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE A_, 2
	LEN 11
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE C_, 3
	LEN 11
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 10
	NOTE A_, 2
	LEN 22
	NOTE C_, 3
	NOTE C_, 3
	NOTE A_, 2
	INSTR 2
	LEN 11
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE A_, 2
	LEN 11
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE G_, 2
	LEN 11
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 10
	NOTE A_, 2
	LEN 22
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	INSTR 2
	LEN 11
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE A_, 2
	LEN 11
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE C_, 3
	LEN 11
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 10
	NOTE A_, 2
	LEN 22
	NOTE C_, 3
	NOTE C_, 3
	NEXT
Pat_62F2:
	LEN 22
	NOTE D_, 3
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	LEN 22
	NOTE D_, 3
	LEN 11
	NOTE D_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 10
	LEN 22
	NOTE C_, 3
	LEN 11
	NOTE D_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 10
	NOTE D_, 3
	LEN 22
	NOTE C_, 3
	NOTE C_, 3
	NOTE D_, 3
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	LEN 22
	NOTE D_, 3
	LEN 11
	NOTE D_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 10
	LEN 22
	NOTE F_, 3
	LEN 11
	NOTE D_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 10
	NOTE D_, 3
	LEN 22
	NOTE F_, 3
	NOTE F_, 3
	NOTE D_, 3
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	LEN 22
	NOTE D_, 3
	LEN 11
	NOTE D_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 10
	LEN 22
	NOTE C_, 3
	LEN 11
	NOTE D_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 10
	NOTE D_, 3
	LEN 22
	NOTE C_, 3
	NOTE D_, 3
	NOTE A_, 2
	INSTR 1
	LEN 11
	NOTE A_, 4
	INSTR 10
	LEN 22
	NOTE A_, 2
	LEN 11
	NOTE A_, 2
	INSTR 1
	NOTE A_, 4
	INSTR 10
	NOTE G_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE E_, 2
	NEXT
Pat_634E:
	LEN 22
	NOTE Ash, 2
	INSTR 1
	LEN 11
	NOTE Ash, 3
	INSTR 10
	LEN 22
	NOTE Ash, 2
	LEN 11
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 3
	INSTR 10
	LEN 22
	NOTE F_, 2
	LEN 11
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 3
	INSTR 10
	NOTE Ash, 2
	LEN 22
	NOTE C_, 3
	NOTE C_, 3
	NOTE D_, 3
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	LEN 22
	NOTE D_, 3
	LEN 11
	NOTE D_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 10
	LEN 22
	NOTE A_, 2
	LEN 11
	NOTE D_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 10
	NOTE D_, 3
	LEN 22
	NOTE A_, 2
	NOTE C_, 3
	NOTE Ash, 2
	INSTR 1
	LEN 11
	NOTE Ash, 3
	INSTR 10
	LEN 22
	NOTE Ash, 2
	LEN 11
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 3
	INSTR 10
	LEN 22
	NOTE F_, 2
	LEN 11
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 3
	INSTR 10
	NOTE Ash, 2
	LEN 22
	NOTE F_, 2
	NOTE Ash, 2
	NOTE G_, 2
	INSTR 1
	LEN 11
	NOTE G_, 3
	INSTR 10
	LEN 22
	NOTE G_, 2
	LEN 11
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 10
	LEN 22
	NOTE D_, 2
	LEN 11
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 10
	NOTE G_, 2
	LEN 22
	NOTE A_, 2
	NOTE A_, 2
	NEXT
Pat_63AC:
	LEN 22
	NOTE Ash, 2
	INSTR 1
	LEN 11
	NOTE Ash, 3
	INSTR 10
	LEN 22
	NOTE Ash, 2
	LEN 11
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 3
	INSTR 10
	LEN 22
	NOTE F_, 2
	LEN 11
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 3
	INSTR 10
	NOTE Ash, 2
	LEN 22
	NOTE C_, 3
	NOTE C_, 3
	NOTE D_, 3
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	LEN 22
	NOTE D_, 3
	LEN 11
	NOTE D_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 10
	LEN 22
	NOTE A_, 2
	LEN 11
	NOTE D_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 10
	NOTE D_, 3
	LEN 22
	NOTE A_, 2
	NOTE C_, 3
	NOTE Ash, 2
	INSTR 1
	LEN 11
	NOTE Ash, 3
	INSTR 10
	LEN 22
	NOTE Ash, 2
	LEN 11
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 3
	INSTR 10
	LEN 22
	NOTE F_, 2
	LEN 11
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 3
	INSTR 10
	NOTE Ash, 2
	LEN 22
	NOTE F_, 2
	NOTE Ash, 2
	NOTE G_, 2
	INSTR 1
	LEN 11
	NOTE G_, 3
	INSTR 10
	LEN 22
	NOTE G_, 2
	LEN 11
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 10
	LEN 22
	NOTE A_, 2
	LEN 11
	NOTE A_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 10
	NOTE G_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE E_, 2
	NEXT
Pat_640B:
	LEN 22
	NOTE D_, 2
	INSTR 2
	LEN 11
	NOTE D_, 3
	INSTR 10
	LEN 22
	NOTE D_, 2
	LEN 11
	NOTE D_, 2
	INSTR 2
	NOTE D_, 3
	INSTR 10
	LEN 22
	NOTE C_, 2
	LEN 11
	NOTE D_, 2
	INSTR 2
	NOTE D_, 3
	INSTR 10
	NOTE D_, 2
	LEN 22
	NOTE C_, 2
	NOTE C_, 2
	NOTE D_, 2
	INSTR 2
	LEN 11
	NOTE D_, 3
	INSTR 10
	LEN 22
	NOTE D_, 2
	LEN 11
	NOTE D_, 2
	INSTR 2
	NOTE D_, 3
	INSTR 10
	LEN 22
	NOTE F_, 2
	LEN 11
	NOTE D_, 2
	INSTR 2
	NOTE D_, 3
	INSTR 10
	NOTE D_, 2
	LEN 22
	NOTE F_, 2
	NOTE G_, 2
	INSTR 10
	NOTE A_, 2
	INSTR 2
	LEN 11
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE A_, 2
	LEN 11
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE G_, 2
	LEN 11
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 10
	NOTE A_, 2
	LEN 22
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	INSTR 2
	LEN 11
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE A_, 2
	LEN 11
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE C_, 3
	LEN 11
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 10
	NOTE A_, 2
	LEN 22
	NOTE C_, 3
	NOTE C_, 3
	NEXT
Pat_646A:
	LEN 22
	NOTE D_, 2
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	NOTE D_, 2
	LEN 22
	NOTE D_, 2
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	NOTE D_, 2
	LEN 22
	NOTE D_, 2
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	NOTE D_, 2
	LEN 22
	NOTE D_, 2
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	NOTE D_, 2
	LEN 22
	NOTE D_, 2
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	NOTE D_, 2
	LEN 22
	NOTE D_, 2
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	NOTE D_, 2
	LEN 22
	NOTE D_, 2
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	NOTE D_, 2
	LEN 22
	NOTE D_, 2
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 10
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 10
	NOTE D_, 2
	NOTE G_, 2
	NOTE G_, 2
	INSTR 2
	NOTE G_, 4
	INSTR 10
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	INSTR 2
	NOTE G_, 4
	INSTR 10
	NOTE G_, 2
	NOTE A_, 2
	NOTE A_, 2
	INSTR 1
	NOTE A_, 4
	INSTR 10
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	INSTR 1
	NOTE A_, 4
	INSTR 10
	NOTE A_, 2
	NOTE D_, 2
	NOTE D_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 10
	NOTE D_, 2
	LEN 22
	NOTE F_, 2
	NOTE F_, 2
	NEXT
Pat_64D0:
	HWENV $C2, $0B, $81
	DUTY_75
	ARP 0
	LEN 11
	NOTE A_, 3
	NOTE E_, 4
	NOTE F_, 4
	LEN 22
	NOTE E_, 4
	LEN 11
	NOTE A_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE F_, 4
	LEN 22
	NOTE E_, 4
	LEN 11
	NOTE A_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE F_, 4
	LEN 22
	NOTE E_, 4
	LEN 11
	NOTE A_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE F_, 4
	LEN 22
	NOTE E_, 4
	LEN 11
	NOTE A_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE F_, 4
	LEN 22
	NOTE E_, 4
	LEN 11
	NOTE A_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE F_, 4
	LEN 22
	NOTE E_, 4
	LEN 11
	NOTE A_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE D_, 5
	NOTE C_, 5
	NEXT
Pat_651E:
	LEN 11
	NOTE D_, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 22
	NOTE A_, 4
	LEN 11
	NOTE D_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 22
	NOTE A_, 4
	LEN 11
	NOTE D_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 22
	NOTE A_, 4
	LEN 11
	NOTE D_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 22
	NOTE A_, 4
	LEN 11
	NOTE D_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 22
	NOTE A_, 4
	LEN 11
	NOTE D_, 5
	NOTE Ash, 4
	NOTE G_, 4
	LEN 33
	NOTE A_, 4
	NOTE E_, 4
	LEN 22
	NOTE A_, 4
	NOTE E_, 4
	NOTE Ash, 4
	LEN 11
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NEXT
Pat_6561:
	LEN 11
	NOTE D_, 4
	LEN 22
	NOTE F_, 4
	LEN 11
	NOTE D_, 4
	LEN 22
	NOTE F_, 4
	LEN 11
	NOTE D_, 4
	LEN 22
	NOTE F_, 4
	LEN 11
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	LEN 22
	NOTE G_, 4
	NOTE F_, 4
	LEN 11
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 22
	NOTE D_, 4
	LEN 11
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE A_, 3
	NOTE A_, 4
	NOTE A_, 3
	NOTE G_, 4
	NOTE A_, 3
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 22
	NOTE F_, 4
	LEN 11
	NOTE D_, 4
	LEN 22
	NOTE F_, 4
	LEN 11
	NOTE D_, 4
	LEN 22
	NOTE F_, 4
	LEN 11
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	LEN 22
	NOTE G_, 4
	NOTE F_, 4
	LEN 11
	NOTE G_, 4
	NOTE F_, 4
	NOTE D_, 4
	LEN 22
	NOTE B_, 3
	LEN 11
	NOTE D_, 4
	NOTE G_, 4
	LEN 22
	NOTE B_, 3
	LEN 11
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NEXT
Pat_65AC:
	LEN 11
	NOTE D_, 4
	LEN 22
	NOTE F_, 4
	LEN 11
	NOTE D_, 4
	LEN 22
	NOTE F_, 4
	LEN 11
	NOTE D_, 4
	LEN 22
	NOTE F_, 4
	LEN 11
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	LEN 22
	NOTE G_, 4
	NOTE F_, 4
	LEN 11
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 22
	NOTE D_, 4
	LEN 11
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE A_, 3
	NOTE A_, 4
	NOTE A_, 3
	NOTE G_, 4
	NOTE A_, 3
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE F_, 4
	LEN 22
	NOTE D_, 5
	NOTE C_, 5
	LEN 11
	NOTE D_, 5
	LEN 33
	NOTE Ash, 4
	LEN 22
	NOTE D_, 5
	LEN 11
	NOTE C_, 5
	LEN 22
	NOTE D_, 5
	LEN 33
	NOTE Ash, 4
	LEN 22
	NOTE D_, 5
	NOTE C_, 5
	LEN 11
	NOTE D_, 5
	LEN 22
	NOTE Csh, 5
	LEN 11
	NOTE Csh, 5
	NOTE Ash, 4
	NOTE Ash, 4
	LEN 22
	NOTE A_, 4
	NOTE E_, 4
	NEXT
Pat_65F1:
	LEN 33
	NOTE D_, 3
	LEN 22
	NOTE D_, 3
	NOTE D_, 3
	NOTE C_, 3
	NOTE D_, 3
	LEN 11
	NOTE D_, 3
	LEN 22
	NOTE C_, 3
	NOTE C_, 3
	LEN 33
	NOTE D_, 3
	LEN 22
	NOTE D_, 3
	NOTE D_, 3
	NOTE F_, 3
	NOTE D_, 3
	LEN 11
	NOTE D_, 3
	LEN 22
	NOTE F_, 3
	NOTE G_, 3
	LEN 11
	NOTE A_, 2
	NOTE E_, 4
	NOTE F_, 4
	LEN 22
	NOTE E_, 4
	LEN 11
	NOTE A_, 4
	NOTE F_, 4
	LEN 22
	NOTE E_, 4
	LEN 11
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 22
	NOTE E_, 4
	LEN 11
	NOTE E_, 4
	NOTE F_, 4
	LEN 22
	NOTE E_, 4
	LEN 11
	NOTE A_, 4
	NOTE F_, 4
	LEN 22
	NOTE E_, 4
	LEN 11
	NOTE E_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE D_, 5
	NOTE C_, 5
	NEXT
Pat_6630:
	LENGTH $58
	NOTE A_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 11
	NOTE D_, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 22
	NOTE A_, 4
	LEN 11
	NOTE D_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Csh, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 22
	NOTE G_, 4
	LEN 11
	NOTE Csh, 5
	NOTE A_, 4
	NOTE E_, 4
	LEN 22
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 3
	NOTE F_, 3
	NEXT
Pat_6657:
	DRUMS $0B, DrumPat_67C8
	VOLENV 10, $15, $1F, $18
	VIBRATO $0B, $01, $04
	ARP 0
	RELEASE $02, $02
	WAVE Wave_7A5F
	LEN 11
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE E_, 5
	WAIT2
	NOTE D_, 5
	NOTE C_, 5
	LEN 22
	NOTE D_, 5
	LEN 11
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT2
	LEN 22
	NOTE A_, 4
	LEN 11
	WAIT2
	LENGTH $42
	NOTE E_, 4
	LENGTH $4D
	WAIT2
	LEN 11
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE E_, 5
	WAIT2
	NOTE D_, 5
	NOTE C_, 5
	LEN 22
	NOTE D_, 5
	LEN 11
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT2
	LEN 22
	NOTE A_, 4
	LEN 11
	WAIT2
	LENGTH $42
	NOTE E_, 5
	LENGTH $4D
	WAIT2
	NEXT
Pat_66A3:
	LEN 11
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	LEN 22
	NOTE A_, 5
	LEN 11
	NOTE G_, 5
	NOTE F_, 5
	LEN 22
	NOTE G_, 5
	LEN 11
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	LEN 22
	NOTE C_, 5
	LEN 33
	NOTE D_, 5
	LENGTH $8F
	NOTE A_, 4
	LEN 11
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	LEN 22
	NOTE A_, 5
	LEN 11
	NOTE G_, 5
	NOTE F_, 5
	LEN 22
	NOTE G_, 5
	LEN 11
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	LEN 22
	NOTE C_, 5
	LEN 33
	NOTE Csh, 5
	LENGTH $8F
	NOTE A_, 5
	NEXT
Pat_66D4:
	VOLENV 15, $00, $1F, $14
	WAVE Wave_7A1F
	LEN 22
	NOTE Ash, 3
	NOTE A_, 4
	LEN 11
	NOTE G_, 4
	LEN 22
	NOTE A_, 4
	LEN 33
	NOTE F_, 4
	LEN 22
	NOTE D_, 4
	NOTE F_, 4
	LEN 11
	NOTE G_, 4
	LEN 33
	NOTE D_, 4
	LEN 11
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE F_, 5
	LEN 22
	NOTE A_, 5
	LEN 11
	NOTE G_, 5
	LEN 44
	NOTE F_, 5
	LEN 22
	NOTE F_, 5
	NOTE E_, 5
	LEN 11
	NOTE F_, 5
	LEN 33
	NOTE D_, 5
	LEN 22
	NOTE F_, 5
	LEN 11
	NOTE E_, 5
	LEN 22
	NOTE F_, 5
	LEN 33
	NOTE D_, 5
	LEN 22
	NOTE F_, 5
	NOTE E_, 5
	LEN 11
	NOTE F_, 5
	LEN 22
	NOTE G_, 5
	LEN 11
	NOTE G_, 5
	NOTE F_, 5
	NOTE F_, 5
	LEN 22
	NOTE E_, 5
	NOTE D_, 5
	NEXT
Pat_6719:
	LEN 22
	NOTE Ash, 3
	NOTE A_, 4
	LEN 11
	NOTE G_, 4
	LEN 22
	NOTE A_, 4
	LEN 33
	NOTE F_, 4
	LEN 22
	NOTE D_, 4
	NOTE F_, 4
	LEN 11
	NOTE G_, 4
	LEN 33
	NOTE D_, 4
	LEN 11
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE F_, 5
	LEN 22
	NOTE A_, 5
	LEN 11
	NOTE G_, 5
	LEN 44
	NOTE F_, 5
	LEN 22
	NOTE F_, 5
	NOTE E_, 5
	LEN 11
	NOTE F_, 5
	LEN 33
	NOTE D_, 5
	LEN 22
	NOTE F_, 5
	LEN 11
	NOTE E_, 5
	LEN 22
	NOTE F_, 5
	LEN 33
	NOTE D_, 5
	LEN 22
	NOTE F_, 5
	NOTE E_, 5
	LEN 11
	NOTE F_, 5
	LEN 22
	NOTE E_, 5
	LEN 11
	NOTE E_, 5
	NOTE D_, 5
	NOTE D_, 5
	LEN 22
	NOTE Csh, 5
	NOTE A_, 4
	NEXT
Pat_6757:
	LEN 33
	NOTE D_, 2
	LEN 22
	NOTE D_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	LEN 11
	NOTE D_, 2
	LEN 22
	NOTE C_, 2
	NOTE C_, 2
	LEN 33
	NOTE D_, 2
	LEN 22
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	LEN 11
	NOTE D_, 2
	LEN 22
	NOTE F_, 2
	NOTE G_, 2
	LEN 33
	NOTE A_, 2
	NOTE E_, 3
	NOTE A_, 3
	NOTE E_, 3
	LEN 22
	NOTE A_, 3
	NOTE C_, 4
	LEN 33
	NOTE B_, 3
	LEN 22
	NOTE A_, 3
	LEN 11
	NOTE G_, 3
	LENGTH $42
	NOTE E_, 3
	CH_TRANSPOSE $00
	LEN 22
	NOTE G_, 3
	NOTE G_, 3
	NEXT
Pat_6786:
	LEN 11
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	LENGTH $37
	NOTE A_, 3
	LEN 11
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	LENGTH $37
	NOTE Ash, 3
	LEN 11
	NOTE Csh, 3
	NOTE D_, 3
	NOTE E_, 3
	LENGTH $37
	NOTE G_, 3
	LEN 11
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	LEN 22
	NOTE A_, 3
	LEN 11
	NOTE Ash, 3
	LEN 22
	NOTE A_, 3
	LEN 11
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	LENGTH $37
	NOTE A_, 3
	LEN 11
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	LENGTH $37
	NOTE Ash, 3
	LEN 11
	NOTE Csh, 3
	NOTE D_, 3
	NOTE E_, 3
	LEN 22
	NOTE A_, 3
	LEN 11
	NOTE G_, 3
	NOTE F_, 3
	NOTE E_, 3
	LEN 22
	NOTE F_, 3
	NOTE D_, 3
	WAVE Wave_7B1F
	CH_TRANSPOSE $0C
	NOTE C_, 3
	NOTE C_, 3
	NEXT
DrumPat_67C8:
	db 1, 6, 2, 1, 6, 1, 2, 1
	db 6, 1, 2, 1, 1, 6, 2, 6
	db DRUM_LOOP

; Song 10: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong10:
	ld a, $74
	ld [wInstrTableHi], a
	ld a, $37
	ld [wInstrTable], a
	ld de, Song10_Ch1
	call StartMusicCh1
	ld de, Song10_Ch2
	call StartMusicCh2
	ld de, Song10_Ch3
	jp StartMusicCh3
Pat_67F5:
	CH_TRANSPOSE $00
	NEXT
Pat_67F8:
	CH_TRANSPOSE $01
	NEXT
Song10_Ch1:
	dw Pat_6831
	dw Pat_6834
	dw Pat_6834
	dw Pat_6848
Loop_6803:
	dw Pat_67F5
	dw Pat_6853
	dw Pat_67F8
	dw Pat_6853
	ORDER_LOOP Loop_6803
Song10_Ch2:
	dw Pat_6831
	dw Pat_6869
	dw Pat_68A0
	dw Pat_6883
Loop_6817:
	dw Pat_67F5
	dw Pat_688F
	dw Pat_688F
	dw Pat_67F8
	dw Pat_688F
	dw Pat_688F
	ORDER_LOOP Loop_6817
Song10_Ch3:
	dw Pat_68B4
	dw Pat_68FE
Loop_682B:
	dw Pat_690D
	ORDER_LOOP Loop_682B
Pat_6831:
	LEN 28
	REST
	NEXT
Pat_6834:
	DUTY_75
	HWENV $F3, $00
	ARP 0
	LEN 42
	NOTE C_, 2
	LEN 14
	NOTE C_, 2
	LEN 28
	NOTE C_, 2
	NOTE E_, 2
	LEN 42
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	NOTE F_, 2
	NEXT
Pat_6848:
	LEN 28
	NOTE C_, 3
	LEN 14
	NOTE C_, 2
	LEN 7
	WAIT2
	NOTE C_, 2
	LENGTH $38
	NOTE C_, 2
	NEXT
Pat_6853:
	HWENV $B2, $08, $30
	REPEAT 4
	LEN 42
	NOTE C_, 2
	LEN 14
	NOTE G_, 2
	LEN 28
	NOTE Ash, 2
	NOTE F_, 2
	LEN 42
	NOTE C_, 2
	LEN 14
	NOTE G_, 2
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE F_, 2
	NOTE F_, 3
	REPEAT_END
	NEXT
Pat_6869:
	HWENV $D2, $0E, $20
	AUTODUTY $03
	ARP 4
	LEN 14
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	ARP 5
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NEXT
Pat_6883:
	ARP 4
	LEN 28
	NOTE C_, 6
	LEN 14
	NOTE C_, 5
	LEN 7
	WAIT2
	NOTE C_, 5
	LENGTH $38
	NOTE C_, 5
	NEXT
Pat_688F:
	HWENV $57, $18, $20
	ARP 4
	LENGTH $70
	NOTE C_, 5
	NOTE Ash, 4
	ARP 5
	NOTE A_, 4
	ARP 4
	LENGTH $38
	NOTE Gsh, 4
	NOTE Ash, 4
	NEXT
Pat_68A0:
	ARP 4
	LEN 14
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	ARP 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	NEXT
Pat_68B4:
	WAVE Wave_7B1F
	VOLENV 15, $1F, $1F, $13
	VIBRATO $0E, $02, $04
	ARP 0
	LEN 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	DRUMS $07, DrumPat_6937
	RELEASE $01, $55
	PAT_CALL Pat_68DB
	CH_TRANSPOSE $0C
Pat_68DB:
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE E_, 4
	NOTE D_, 4
	LEN 14
	NOTE E_, 4
	LEN 28
	NOTE C_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE F_, 4
	NOTE E_, 4
	LEN 14
	NOTE D_, 4
	NOTE Ash, 3
	LEN 7
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE D_, 5
	NOTE Ash, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE Ash, 4
	NOTE D_, 5
	CH_TRANSPOSE $00
	NEXT
Pat_68FE:
	LEN 28
	NOTE C_, 6
	LEN 14
	NOTE C_, 4
	LEN 7
	WAIT2
	NOTE C_, 4
	DRUMS_OFF
	CALL_CODE Drum7
	LENGTH $38
	NOTE C_, 4
	NEXT
Pat_690D:
	DRUMS $07, DrumPat_6949
	VOLENV 10, $11, $1F, $11
	RELEASE $03, $55
	LEN 14
	REPEAT 8
	NOTE C_, 6
	NOTE G_, 5
	NOTE D_, 6
	NOTE G_, 5
	NOTE C_, 5
	NOTE G_, 5
	NOTE D_, 6
	NOTE G_, 5
	REPEAT_END
	LEN 7
	REPEAT 8
	NOTE Csh, 6
	NOTE Csh, 7
	NOTE Gsh, 5
	NOTE Gsh, 6
	NOTE Dsh, 6
	NOTE Dsh, 7
	NOTE Gsh, 5
	NOTE Gsh, 6
	NOTE Csh, 5
	NOTE Csh, 6
	NOTE Gsh, 5
	NOTE Gsh, 6
	NOTE Dsh, 6
	NOTE Dsh, 7
	NOTE Gsh, 5
	NOTE Gsh, 6
	REPEAT_END
	NEXT
DrumPat_6937:
	db DRUM_LEVEL + 14, 9, 0, 10, 10, 9, 0, 10
	db 0, 9, 10, 10, 9, 9, 10, 10
	db 9, DRUM_LOOP
DrumPat_6949:
	db DRUM_LEVEL + 13, DRUM_REPEAT + 3, 6, 0, 6, 0, 4, 0
	db 6, 0, DRUM_REPEAT_END, 6, 0, 6, 6, 4
	db 6, 6, 4, DRUM_LOOP

; Song 11: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong11:
	ld a, $74
	ld [wInstrTableHi], a
	ld a, $37
	ld [wInstrTable], a
	ld de, Song11_Ch1
	call StartMusicCh1
	ld de, Song11_Ch2
	call StartMusicCh2
	ld de, Song11_Ch3
	jp StartMusicCh3
Song11_Ch1:
	dw Pat_69A9
	dw Pat_69A9
Loop_697D:
	dw Pat_69C6
	dw Pat_69C6
	dw Pat_6A27
	dw Pat_6A27
	ORDER_LOOP Loop_697D
Song11_Ch2:
	dw Pat_6A88
	dw Pat_6A94
Loop_698D:
	dw Pat_6B07
	dw Pat_6B07
	dw Pat_6AC6
	dw Pat_6AC6
	ORDER_LOOP Loop_698D
Song11_Ch3:
	dw Pat_6AF8
	dw Pat_6B3E
Loop_699D:
	dw Pat_6AF8
	dw Pat_6AF8
	dw Pat_6B3E
	dw Pat_6B75
	ORDER_LOOP Loop_699D
Pat_69A9:
	LEN 30
	HWENV $F1, $02, $81
	DUTY_50
	DRUMS $0A, DrumPat_6B7A
	GLIDE $FE
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
	NEXT
Pat_69C6:
	INSTR 6
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 3
	INSTR 6
	LEN 20
	NOTE D_, 2
	INSTR 1
	LEN 10
	NOTE G_, 3
	INSTR 6
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 3
	INSTR 6
	LEN 20
	NOTE D_, 2
	INSTR 1
	LEN 10
	NOTE G_, 3
	INSTR 6
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 3
	INSTR 6
	LEN 20
	NOTE D_, 2
	INSTR 1
	LEN 10
	NOTE G_, 3
	INSTR 6
	LEN 20
	NOTE F_, 2
	INSTR 1
	LEN 10
	NOTE F_, 3
	INSTR 6
	LEN 20
	NOTE C_, 2
	INSTR 1
	LEN 10
	NOTE F_, 3
	INSTR 6
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 3
	INSTR 6
	LEN 20
	NOTE D_, 2
	INSTR 1
	LEN 10
	NOTE G_, 3
	INSTR 6
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 3
	INSTR 6
	LEN 20
	NOTE D_, 2
	INSTR 1
	LEN 10
	NOTE G_, 3
	INSTR 6
	LEN 20
	NOTE F_, 2
	INSTR 1
	LEN 10
	NOTE F_, 3
	INSTR 6
	LEN 20
	NOTE C_, 2
	INSTR 1
	LEN 10
	NOTE F_, 3
	INSTR 6
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 3
	INSTR 6
	LEN 20
	NOTE D_, 2
	INSTR 1
	LEN 10
	NOTE G_, 3
	NEXT
Pat_6A27:
	INSTR 6
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 4
	INSTR 6
	LEN 20
	NOTE D_, 2
	INSTR 1
	LEN 10
	NOTE G_, 4
	INSTR 6
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 4
	INSTR 6
	LEN 20
	NOTE D_, 2
	INSTR 1
	LEN 10
	NOTE G_, 4
	INSTR 6
	LEN 20
	NOTE F_, 2
	INSTR 1
	LEN 10
	NOTE F_, 4
	INSTR 6
	LEN 20
	NOTE C_, 2
	INSTR 1
	LEN 10
	NOTE F_, 4
	INSTR 6
	LEN 20
	NOTE F_, 2
	INSTR 1
	LEN 10
	NOTE F_, 4
	INSTR 6
	LEN 20
	NOTE C_, 2
	INSTR 1
	LEN 10
	NOTE F_, 4
	INSTR 6
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 4
	INSTR 6
	LEN 20
	NOTE D_, 2
	INSTR 1
	LEN 10
	NOTE G_, 4
	INSTR 6
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 4
	INSTR 6
	LEN 20
	NOTE D_, 2
	INSTR 1
	LEN 10
	NOTE G_, 4
	INSTR 6
	LEN 20
	NOTE C_, 3
	INSTR 1
	LEN 10
	NOTE C_, 5
	INSTR 6
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE C_, 5
	INSTR 6
	LEN 20
	NOTE C_, 3
	INSTR 1
	LEN 10
	NOTE C_, 5
	INSTR 6
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE C_, 5
	NEXT
Pat_6A88:
	HWENV $A2, $0A, $72
	ARP 0
	DUTY_75
	LENGTH $A0
	NOTE G_, 2
	REST
	REST
	NEXT
Pat_6A94:
	LEN 10
	NOTE G_, 3
	NOTE D_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 5
	NOTE B_, 4
	NOTE F_, 3
	NOTE C_, 3
	NOTE A_, 3
	NOTE F_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE F_, 4
	NOTE C_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 3
	NOTE D_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 5
	NOTE B_, 4
	NOTE C_, 4
	NOTE G_, 3
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 5
	NOTE E_, 5
	NEXT
Pat_6AC6:
	LEN 10
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 5
	NOTE B_, 4
	NOTE G_, 5
	NOTE D_, 5
	NOTE B_, 5
	NOTE G_, 5
	NOTE D_, 6
	NOTE B_, 5
	NOTE F_, 4
	NOTE C_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE F_, 5
	NOTE C_, 5
	NOTE A_, 5
	NOTE F_, 5
	NOTE C_, 6
	NOTE A_, 5
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 5
	NOTE B_, 4
	NOTE G_, 5
	NOTE D_, 5
	NOTE B_, 5
	NOTE G_, 5
	NOTE D_, 6
	NOTE B_, 5
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE C_, 6
	NOTE G_, 5
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	NOTE E_, 6
	NEXT
Pat_6AF8:
	VOLENV 9, $15, $15, $14
	ARP 0
	WAVE Wave_7B1F
	RELEASE $01, $A1
	VIBRATO $0A, $01, $05
Pat_6B07:
	CH_TRANSPOSE $00
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE B_, 4
	LEN 20
	NOTE A_, 4
	LEN 10
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 30
	NOTE G_, 4
	LEN 10
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 20
	NOTE E_, 4
	LEN 10
	NOTE D_, 4
	LEN 30
	NOTE C_, 4
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE B_, 4
	LEN 20
	NOTE A_, 4
	LEN 10
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	LEN 20
	NOTE G_, 5
	LEN 10
	NOTE A_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	LEN 30
	NOTE G_, 4
	NEXT
Pat_6B3E:
	LEN 10
	NOTE B_, 4
	NOTE C_, 5
	LEN 20
	NOTE D_, 5
	LEN 10
	NOTE C_, 5
	NOTE B_, 4
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE D_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE F_, 4
	LEN 30
	NOTE C_, 4
	LEN 10
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	LEN 20
	NOTE G_, 5
	LEN 10
	NOTE D_, 5
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	LEN 5
	NOTE D_, 5
	NOTE E_, 5
	LEN 10
	NOTE D_, 5
	NOTE C_, 5
	LENGTH $3C
	NOTE G_, 5
	NEXT
Pat_6B75:
	CH_TRANSPOSE $0C
	PAT_GOTO Pat_6B3E
DrumPat_6B7A:
	db DRUM_LEVEL + 13, 1, DRUM_LEVEL + 12, 6, DRUM_LEVEL + 10, 4, DRUM_LOOP

; Song 12: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong12:
	ld a, $74
	ld [wInstrTableHi], a
	ld a, $37
	ld [wInstrTable], a
	ld de, Song12_Ch1
	call StartMusicCh1
	ld de, Song12_Ch2
	call StartMusicCh2
	ld de, Song12_Ch3
	jp StartMusicCh3
Song12_Ch1:
	dw Pat_6BB5
	dw Pat_6C15
	ORDER_LOOP Song12_Ch1
Song12_Ch2:
	dw Pat_6C41
	dw Pat_6C92
	ORDER_LOOP Song12_Ch2
Song12_Ch3:
	dw Pat_6CBC
	dw Pat_6D05
	ORDER_LOOP Song12_Ch3
Pat_6BB5:
	HWENV $F2, $04, $A3
	ARP 0
	DUTY_75
	DRUMS $09, DrumPat_6D27
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE Ash, 2
	LEN 9
	NOTE Ash, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE Ash, 2
	LEN 9
	NOTE Ash, 3
	LEN 18
	NOTE Gsh, 2
	LEN 9
	NOTE Gsh, 3
	LEN 18
	NOTE Gsh, 2
	LEN 9
	NOTE Gsh, 3
	LEN 18
	NOTE Gsh, 2
	LEN 9
	NOTE Gsh, 3
	LEN 18
	NOTE Gsh, 2
	LEN 9
	NOTE Gsh, 3
	LEN 18
	NOTE Gsh, 2
	LEN 9
	NOTE Gsh, 3
	NOTE Gsh, 2
	NEXT
Pat_6C15:
	LEN 9
	WAIT
	NOTE Gsh, 3
	LEN 18
	NOTE Gsh, 2
	LEN 9
	NOTE Gsh, 3
	LEN 18
	NOTE Gsh, 2
	LEN 9
	NOTE Gsh, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE F_, 2
	LEN 9
	NOTE F_, 3
	LEN 18
	NOTE F_, 2
	LEN 9
	NOTE F_, 3
	LEN 18
	NOTE F_, 2
	LEN 9
	NOTE F_, 3
	LEN 18
	NOTE F_, 2
	LEN 9
	NOTE F_, 3
	NEXT
Pat_6C41:
	HWENV $F2, $04, $A3
	DUTY_50
	RELEASE $02, $00
	ARP 5
	LEN 27
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 27
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 27
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 18
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	ARP 4
	LEN 18
	NOTE Ash, 3
	LEN 9
	NOTE Ash, 3
	ARP 5
	LEN 27
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 27
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 27
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 18
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	ARP 4
	LEN 18
	NOTE Ash, 3
	LEN 9
	NOTE Ash, 3
	LEN 27
	NOTE Gsh, 3
	LEN 9
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	LEN 27
	NOTE Gsh, 3
	LEN 9
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	LEN 27
	NOTE Gsh, 3
	LEN 9
	NOTE Gsh, 3
	NEXT
Pat_6C92:
	ARP 4
	LEN 9
	NOTE Gsh, 3
	NOTE Gsh, 3
	ARP 5
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE C_, 4
	ARP 4
	LEN 18
	NOTE Gsh, 3
	LEN 9
	NOTE Gsh, 3
	ARP 5
	LEN 27
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 27
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	ARP 4
	LEN 18
	NOTE F_, 3
	NOTE F_, 3
	LEN 9
	NOTE F_, 3
	NOTE F_, 3
	LEN 18
	NOTE F_, 3
	LEN 9
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NEXT
Pat_6CBC:
	VOLENV 15, $12, $2F, $11
	WAVE Wave_7A7F
	LEN 9
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE Ash, 3
	NOTE F_, 4
	NOTE Ash, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE Ash, 3
	NOTE F_, 4
	NOTE Ash, 4
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 3
	NEXT
Pat_6D05:
	LEN 9
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE F_, 3
	NOTE C_, 4
	NOTE F_, 4
	NOTE F_, 3
	NOTE C_, 4
	NOTE F_, 4
	NOTE F_, 3
	NOTE C_, 4
	NOTE F_, 4
	NOTE F_, 3
	NOTE C_, 4
	NOTE F_, 4
	NEXT
DrumPat_6D27:
	db 9, 0, 10, 9, 9, 9, 9, 0
	db 10, 9, 9, 9, 9, 0, 10, 9
	db 9, 9, 9, 0, 10, 9, 0, 10
	db DRUM_LOOP

; Song 13: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong13:
	ld a, $74
	ld [wInstrTableHi], a
	ld a, $37
	ld [wInstrTable], a
	ld de, Song13_Ch1
	call StartMusicCh1
	ld de, Song13_Ch2
	call StartMusicCh2
	ld de, Song13_Ch3
	jp StartMusicCh3
Song13_Ch1:
	dw Pat_6D7A
	dw Pat_6DB2
	dw Pat_6DDC
	ORDER_LOOP Song13_Ch1
Song13_Ch2:
	dw Pat_6E08
	dw Pat_6E37
	dw Pat_6E60
	ORDER_LOOP Song13_Ch2
Song13_Ch3:
	dw Pat_6E8A
	dw Pat_6EB8
	dw Pat_6ED6
	ORDER_LOOP Song13_Ch3
Pat_6D7A:
	DRUMS $07, DrumPat_6EF7
	TRANSPOSE $01
	DUTY_75
	HWENV $F2, $04, $A3
	RELEASE $01, $00
	ARP 0
	LEN 14
	NOTE G_, 2
	ARP 4
	NOTE G_, 3
	NOTE G_, 3
	ARP 0
	NOTE F_, 2
	ARP 4
	NOTE F_, 3
	NOTE F_, 3
	ARP 0
	NOTE G_, 2
	ARP 4
	NOTE G_, 3
	NOTE G_, 3
	ARP 0
	NOTE D_, 2
	ARP 4
	NOTE G_, 3
	NOTE G_, 3
	ARP 0
	NOTE F_, 2
	ARP 4
	NOTE F_, 3
	NOTE F_, 3
	ARP 0
	NOTE C_, 2
	ARP 4
	NOTE C_, 3
	NOTE C_, 3
	ARP 0
	NOTE G_, 2
	ARP 4
	NOTE G_, 3
	NOTE G_, 3
	ARP 0
	NOTE F_, 2
	ARP 4
	NOTE F_, 3
	NOTE F_, 3
	NEXT
Pat_6DB2:
	ARP 0
	LEN 14
	NOTE G_, 2
	ARP 4
	NOTE G_, 3
	NOTE G_, 3
	ARP 0
	NOTE F_, 2
	ARP 4
	NOTE F_, 3
	NOTE F_, 3
	ARP 0
	NOTE G_, 2
	ARP 4
	NOTE G_, 3
	NOTE G_, 3
	ARP 0
	NOTE D_, 2
	ARP 4
	NOTE G_, 3
	NOTE G_, 3
	ARP 0
	NOTE F_, 2
	ARP 4
	NOTE F_, 3
	NOTE F_, 3
	ARP 0
	NOTE C_, 2
	ARP 4
	NOTE C_, 3
	NOTE C_, 3
	ARP 0
	NOTE G_, 2
	ARP 4
	NOTE G_, 3
	NOTE G_, 3
	ARP 0
	NOTE G_, 2
	ARP 4
	NOTE G_, 4
	NOTE G_, 4
	NEXT
Pat_6DDC:
	ARP 0
	LEN 14
	NOTE F_, 2
	ARP 4
	LEN 28
	NOTE F_, 4
	ARP 0
	LEN 14
	NOTE D_, 2
	ARP 4
	NOTE F_, 4
	NOTE G_, 4
	ARP 0
	NOTE F_, 2
	ARP 4
	LEN 28
	NOTE F_, 4
	ARP 0
	LEN 14
	NOTE D_, 2
	ARP 4
	NOTE F_, 4
	NOTE G_, 4
	ARP 0
	NOTE G_, 2
	ARP 4
	NOTE G_, 4
	NOTE G_, 4
	ARP 0
	NOTE F_, 2
	ARP 4
	NOTE F_, 4
	NOTE F_, 4
	ARP 0
	NOTE G_, 2
	ARP 4
	NOTE G_, 4
	NOTE G_, 4
	ARP 0
	NOTE F_, 2
	ARP 4
	NOTE G_, 4
	NOTE G_, 4
	NEXT
Pat_6E08:
	HWENV $C1, $02, $91
	ARP 0
	DUTY_75
	LEN 14
	WAIT
	LEN 7
	NOTE G_, 4
	NOTE B_, 4
	LEN 14
	NOTE D_, 5
	NOTE F_, 4
	NOTE A_, 4
	LEN 28
	NOTE C_, 5
	LEN 7
	NOTE G_, 4
	NOTE B_, 4
	LEN 14
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	LEN 28
	NOTE G_, 4
	LEN 7
	NOTE F_, 4
	NOTE A_, 4
	LEN 14
	NOTE C_, 5
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE B_, 4
	LEN 7
	NOTE B_, 4
	NOTE A_, 4
	LEN 14
	NOTE G_, 4
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE E_, 4
	LEN 14
	NOTE D_, 4
	NEXT
Pat_6E37:
	LEN 14
	WAIT
	LEN 7
	NOTE G_, 4
	NOTE B_, 4
	LEN 14
	NOTE D_, 5
	NOTE F_, 4
	NOTE A_, 4
	LEN 28
	NOTE C_, 5
	LEN 7
	NOTE G_, 4
	NOTE B_, 4
	LEN 14
	NOTE D_, 5
	NOTE G_, 4
	NOTE F_, 4
	LEN 28
	NOTE D_, 4
	LEN 7
	NOTE F_, 4
	NOTE A_, 4
	LEN 14
	NOTE C_, 5
	NOTE C_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	NOTE A_, 4
	LEN 14
	NOTE B_, 4
	NOTE C_, 5
	LEN 7
	NOTE C_, 5
	NOTE B_, 4
	LEN 14
	NOTE G_, 4
	NEXT
Pat_6E60:
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE E_, 4
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE A_, 3
	NOTE D_, 4
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE E_, 4
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE A_, 3
	NOTE C_, 4
	LEN 7
	NOTE B_, 3
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE A_, 4
	LEN 14
	NOTE F_, 4
	NOTE D_, 4
	NOTE B_, 3
	NEXT
Pat_6E8A:
	WAVE Wave_7A5F
	VIBRATO $07, $01, $04
	VOLENV 15, $12, $15, $13
	RELEASE $02, $50
	LEN 21
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE F_, 4
	LEN 28
	NOTE G_, 4
	NOTE G_, 4
	LEN 14
	NOTE D_, 4
	NOTE E_, 4
	LEN 21
	NOTE F_, 4
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	LEN 28
	NOTE G_, 3
	LEN 14
	NOTE F_, 3
	NEXT
Pat_6EB8:
	LEN 21
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE F_, 4
	LEN 28
	NOTE G_, 4
	NOTE G_, 4
	LEN 14
	NOTE D_, 5
	NOTE E_, 5
	LEN 21
	NOTE F_, 5
	LEN 7
	NOTE E_, 5
	LEN 14
	NOTE D_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	LEN 42
	NOTE G_, 5
	NEXT
Pat_6ED6:
	LENGTH $31
	NOTE A_, 3
	LEN 7
	NOTE B_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	LEN 21
	NOTE A_, 3
	LEN 7
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE A_, 4
	LEN 14
	NOTE G_, 4
	LEN 42
	NOTE D_, 4
	NOTE C_, 4
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE G_, 4
	LEN 28
	NOTE F_, 4
	LEN 14
	NOTE A_, 4
	NEXT
DrumPat_6EF7:
	db DRUM_LEVEL + 13, 1, 0, 6, 6, 6, 0, 9
	db 0, 6, 0, 6, 0, DRUM_LOOP

; Song 14: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong14:
	ld a, $74
	ld [wInstrTableHi], a
	ld a, $37
	ld [wInstrTable], a
	ld de, Song14_Ch1
	call StartMusicCh1
	ld de, Song14_Ch2
	call StartMusicCh2
	ld de, Song14_Ch3
	jp StartMusicCh3
Song14_Ch1:
	dw Pat_6F41
Loop_6F23:
	dw Pat_6F8F
	dw Pat_6FA5
	ORDER_LOOP Loop_6F23
Song14_Ch2:
	dw Pat_6FBB
Loop_6F2D:
	dw Pat_6FC0
	dw Pat_6FE3
	ORDER_LOOP Loop_6F2D
Song14_Ch3:
	dw Pat_7002
Loop_6F37:
	dw Pat_701B
	dw Pat_701B
	dw Pat_705E
	ORDER_LOOP Loop_6F37
Pat_6F41:
	HWENV $F2, $09, $60
	VIBRATO $09, $02, $05
	ARP 0
	DUTY_50
	RELEASE $02, $61
	LENGTH $36
	NOTE D_, 2
	LEN 9
	NOTE D_, 3
	LEN 18
	NOTE D_, 3
	LEN 9
	NOTE D_, 3
	LEN 18
	NOTE C_, 3
	LEN 9
	NOTE A_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE F_, 2
	LENGTH $36
	NOTE G_, 2
	LEN 9
	NOTE Ash, 2
	LEN 18
	NOTE Ash, 2
	LEN 9
	NOTE Ash, 2
	LEN 18
	NOTE A_, 2
	LEN 9
	NOTE F_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE Csh, 2
	LENGTH $36
	NOTE D_, 2
	LEN 9
	NOTE D_, 3
	LEN 18
	NOTE D_, 3
	LEN 9
	NOTE D_, 3
	LEN 18
	NOTE C_, 3
	LEN 9
	NOTE A_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE F_, 2
	LENGTH $36
	NOTE G_, 2
	LEN 9
	NOTE Ash, 2
	LEN 18
	NOTE Ash, 2
	LEN 9
	NOTE Ash, 2
	LEN 18
	NOTE A_, 2
	LEN 9
	NOTE F_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE C_, 2
	NEXT
Pat_6F8F:
	LEN 18
	REPEAT 5
	NOTE D_, 2
	NOTE D_, 2
	LEN 27
	NOTE F_, 2
	NOTE D_, 2
	LEN 18
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN 27
	NOTE Ash, 2
	NOTE G_, 2
	LEN 18
	NOTE G_, 2
	NOTE Ash, 2
	NOTE G_, 2
	REPEAT_END
	NEXT
Pat_6FA5:
	NOTE Ash, 2
	NOTE Ash, 2
	LEN 27
	NOTE D_, 3
	NOTE Ash, 2
	LEN 18
	NOTE Ash, 2
	NOTE D_, 3
	NOTE Ash, 2
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	LEN 9
	NOTE C_, 3
	NOTE C_, 3
	WAIT2
	NOTE C_, 3
	LEN 18
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NEXT
Pat_6FBB:
	LEN 18
	REPEAT 2
	PAT_GOTO Pat_6FC1
Pat_6FC0:
	REPEAT 5
Pat_6FC1:
	INSTR 0
	NOTE D_, 4
	INSTR 2
	NOTE D_, 4
	INSTR 0
	NOTE E_, 4
	INSTR 2
	NOTE D_, 4
	INSTR 0
	NOTE F_, 4
	INSTR 2
	NOTE D_, 4
	INSTR 0
	NOTE E_, 4
	INSTR 2
	NOTE D_, 4
	INSTR 0
	NOTE G_, 4
	INSTR 2
	NOTE G_, 4
	INSTR 0
	NOTE A_, 4
	INSTR 2
	NOTE G_, 4
	INSTR 0
	NOTE Ash, 4
	INSTR 2
	NOTE G_, 4
	INSTR 0
	NOTE A_, 4
	INSTR 2
	NOTE G_, 4
	REPEAT_END
	NEXT
Pat_6FE3:
	INSTR 0
	NOTE Ash, 3
	INSTR 1
	NOTE Ash, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE Ash, 4
	INSTR 0
	NOTE D_, 4
	INSTR 1
	NOTE Ash, 4
	INSTR 0
	NOTE Ash, 3
	INSTR 1
	NOTE Ash, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	LEN 9
	NOTE C_, 5
	NOTE C_, 5
	WAIT2
	INSTR 0
	NOTE C_, 4
	LEN 18
	NOTE A_, 3
	NOTE G_, 3
	INSTR 1
	NOTE F_, 4
	NEXT
Pat_7002:
	DRUMS $09, DrumPat_7085
	WAVE Wave_7A1F
	VOLENV 10, $14, $1F, $1F
	VIBRATO $09, $01, $05
	RELEASE $05, $01
	LENGTH $90
	REST
	REST
	REST
	REST
	NEXT
Pat_701B:
	LEN 9
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 27
	NOTE A_, 4
	LEN 9
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 27
	NOTE A_, 3
	LEN 18
	NOTE D_, 4
	LEN 4
	NOTE C_, 4
	LEN 23
	NOTE D_, 4
	LEN 27
	NOTE C_, 4
	LEN 18
	NOTE Ash, 3
	NOTE F_, 3
	NOTE G_, 3
	LEN 9
	NOTE A_, 3
	NOTE G_, 3
	LEN 18
	NOTE A_, 3
	LEN 9
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 27
	NOTE A_, 4
	LEN 9
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	LEN 18
	NOTE D_, 5
	NOTE C_, 5
	LEN 9
	NOTE Ash, 4
	NOTE G_, 4
	LEN 18
	NOTE F_, 4
	NEXT
Pat_705E:
	LENGTH $36
	NOTE D_, 4
	LENGTH $AB
	WAIT2
	LEN 9
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE A_, 4
	LENGTH $36
	NOTE F_, 4
	LEN 18
	NOTE D_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 9
	NOTE A_, 4
	NOTE G_, 4
	LEN 18
	NOTE F_, 4
	LENGTH $3F
	NOTE G_, 4
	NOTE A_, 4
	LEN 9
	NOTE D_, 4
	NOTE E_, 4
	ARP 0
	DRUMS $09, DrumPat_708B
	NEXT
DrumPat_7085:
	db DRUM_LEVEL + 14, 1, 0, 6, 0, DRUM_LOOP
DrumPat_708B:
	db DRUM_LEVEL + 14, 1, 6, 6, 0, 2, 0, 4
	db 6, 1, 6, 6, 6, 2, 0, 4
	db 0, DRUM_LOOP

; Song 15: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong15:
	ld a, $74
	ld [wInstrTableHi], a
	ld a, $37
	ld [wInstrTable], a
	ld de, Song15_Ch1
	call StartMusicCh1
	ld de, Song15_Ch2
	call StartMusicCh2
	ld de, Song15_Ch3
	jp StartMusicCh3
Song15_Ch1:
	dw Pat_70BF
Song15_Ch2:
	dw Pat_70D9
Song15_Ch3:
	dw Pat_70D8
Pat_70BF:
	LEN 8
	HWENV $F2, $04, $87
	RELEASE $02, $51
	ARP 0
	DUTY_50
	DRUMS $08, DrumPat_70ED
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	WAIT
	NOTE F_, 2
	WAIT
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	DRUMS_OFF
	END
Pat_70D8:
	END
Pat_70D9:
	LEN 8
	HWENV $F2, $04, $87
	RELEASE $02, $51
	ARP 5
	DUTY_50
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE G_, 4
	NOTE D_, 4
	WAIT
	END
DrumPat_70ED:
	db 1, 6, 6, 0, 7, 0, 1, 7           ; no DRUM_LOOP: the pattern runs into the next data
	db 0, 0, 0, 0

; Song 16: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong16:
	ld a, $74
	ld [wInstrTableHi], a
	ld a, $37
	ld [wInstrTable], a
	ld de, Song16_Ch1
	call StartMusicCh1
	ld de, Song16_Ch2
	call StartMusicCh2
	ld de, Song16_Ch3
	jp StartMusicCh3

; Unreferenced (1 bytes)
	db $C9
Song16_Ch1:
	dw Pat_7140
Loop_7118:
	dw Pat_718B
	dw Pat_718B
	dw Pat_71F0
	dw Pat_71F0
	ORDER_LOOP Loop_7118
Song16_Ch3:
	dw Pat_7251
Loop_7126:
	dw Pat_729F
	dw Pat_729F
	dw Pat_7301
	dw Pat_7301
	ORDER_LOOP Loop_7126
Song16_Ch2:
	dw Pat_7362
Loop_7134:
	dw Pat_73B2
	dw Pat_73B2
	dw Pat_73F8
	dw Pat_73F8
	ORDER_LOOP Loop_7134
Pat_7140:
	LEN 11
	DUTY_50
	RELEASE $02, $01
	VIBRATO $0B, $04, $05
	INSTR 12
	NOTE D_, 2
	WAIT
	WAIT
	NOTE G_, 2
	NOTE G_, 2
	WAIT
	WAIT
	NOTE A_, 2
	WAIT
	WAIT
	WAIT
	NOTE A_, 2
	NOTE G_, 2
	WAIT
	NOTE A_, 2
	WAIT
	NOTE D_, 2
	WAIT
	WAIT
	NOTE G_, 2
	NOTE G_, 2
	WAIT
	WAIT
	NOTE A_, 2
	WAIT
	WAIT
	WAIT
	NOTE A_, 2
	NOTE G_, 2
	WAIT
	NOTE A_, 2
	WAIT
	NOTE D_, 2
	WAIT
	WAIT
	NOTE G_, 2
	NOTE G_, 2
	WAIT
	WAIT
	NOTE A_, 2
	WAIT
	WAIT
	WAIT
	NOTE A_, 2
	NOTE G_, 2
	WAIT
	NOTE A_, 2
	WAIT
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	WAIT
	WAIT
	WAIT
	NEXT
Pat_718B:
	DRUMS $0B, DrumPat_74A3
	NOTE D_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE D_, 3
	NOTE D_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE D_, 3
	NOTE D_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE D_, 3
	NOTE D_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE Gsh, 2
	NOTE A_, 2
	NOTE B_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE Gsh, 2
	NOTE A_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	WAIT
	NOTE A_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	NOTE D_, 3
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE D_, 3
	WAIT
	NOTE D_, 3
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE D_, 3
	NOTE Ash, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE Ash, 2
	WAIT
	NOTE Ash, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE Ash, 2
	NOTE A_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	WAIT
	NOTE A_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	NEXT
Pat_71F0:
	NOTE D_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE D_, 2
	NOTE A_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	WAIT
	NOTE A_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	NOTE B_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE B_, 2
	WAIT
	NOTE B_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE B_, 2
	NOTE A_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	WAIT
	NOTE A_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	NOTE G_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE E_, 2
	NOTE F_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE F_, 2
	NOTE E_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	WAIT
	NOTE A_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	NEXT
Pat_7251:
	LEN 11
	WAVE Wave_7A5F
	ARP 0
	VOLENV 15, $11, $1F, $11
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE E_, 4
	WAIT
	NOTE Csh, 4
	WAIT
	NOTE E_, 4
	NOTE D_, 4
	WAIT
	NOTE Csh, 4
	WAIT
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE E_, 4
	WAIT
	NOTE Csh, 4
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE E_, 4
	WAIT
	NOTE Csh, 4
	WAIT
	NOTE E_, 4
	NOTE D_, 4
	WAIT
	NOTE Csh, 4
	WAIT
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE A_, 4
	WAIT
	ARP_OFF
	GLIDE $FE
	NOTE A_, 3
	NOTE A_, 3
	GLIDE_OFF
	NEXT
Pat_729F:
	ARP 0
	NOTE D_, 3
	NOTE D_, 4
	ARP 4
	NOTE D_, 4
	ARP 0
	NOTE D_, 4
	NOTE D_, 3
	NOTE D_, 4
	ARP 4
	NOTE D_, 4
	ARP 0
	NOTE D_, 4
	NOTE D_, 3
	NOTE D_, 4
	ARP 4
	NOTE D_, 4
	ARP 0
	NOTE D_, 4
	NOTE D_, 3
	NOTE D_, 4
	ARP 4
	NOTE D_, 4
	ARP 0
	NOTE D_, 4
	NOTE D_, 3
	NOTE D_, 4
	ARP 4
	NOTE D_, 4
	ARP 0
	NOTE D_, 4
	NOTE D_, 3
	NOTE D_, 4
	ARP 4
	NOTE D_, 4
	ARP 0
	NOTE D_, 4
	NOTE D_, 3
	NOTE D_, 4
	ARP 4
	NOTE D_, 4
	ARP 0
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE B_, 3
	ARP 4
	NOTE E_, 4
	ARP 0
	NOTE E_, 4
	NOTE A_, 3
	NOTE A_, 4
	ARP 4
	NOTE A_, 4
	ARP 0
	NOTE A_, 4
	NOTE A_, 3
	NOTE A_, 4
	ARP 4
	NOTE A_, 4
	ARP 0
	NOTE A_, 4
	NOTE D_, 4
	NOTE D_, 5
	ARP 4
	NOTE D_, 5
	ARP 0
	NOTE D_, 5
	NOTE D_, 4
	NOTE D_, 5
	ARP 4
	NOTE D_, 5
	ARP 0
	NOTE D_, 5
	NOTE Ash, 3
	NOTE Ash, 4
	ARP 4
	NOTE Ash, 4
	ARP 0
	NOTE Ash, 4
	NOTE Ash, 3
	NOTE Ash, 4
	ARP 4
	NOTE Ash, 4
	ARP 0
	NOTE Ash, 4
	NOTE A_, 3
	NOTE A_, 4
	ARP 4
	NOTE A_, 4
	ARP 0
	NOTE A_, 4
	NOTE A_, 3
	NOTE A_, 4
	ARP 4
	NOTE A_, 4
	ARP 0
	NOTE A_, 4
	NEXT
Pat_7301:
	NOTE D_, 3
	NOTE D_, 4
	ARP 4
	NOTE D_, 4
	ARP 0
	NOTE D_, 4
	NOTE D_, 3
	NOTE D_, 4
	ARP 4
	NOTE D_, 4
	ARP 0
	NOTE D_, 4
	NOTE A_, 3
	NOTE A_, 4
	ARP 4
	NOTE A_, 4
	ARP 0
	NOTE A_, 4
	NOTE A_, 3
	NOTE A_, 4
	ARP 4
	NOTE A_, 4
	ARP 0
	NOTE A_, 4
	NOTE B_, 3
	NOTE B_, 4
	ARP 5
	NOTE B_, 4
	ARP 0
	NOTE B_, 4
	NOTE B_, 3
	NOTE B_, 4
	ARP 5
	NOTE B_, 4
	ARP 0
	NOTE B_, 4
	NOTE A_, 3
	NOTE A_, 4
	ARP 4
	NOTE A_, 4
	ARP 0
	NOTE A_, 4
	NOTE A_, 3
	NOTE A_, 4
	ARP 4
	NOTE A_, 4
	ARP 0
	NOTE A_, 4
	NOTE G_, 3
	NOTE G_, 4
	ARP 4
	NOTE G_, 4
	ARP 0
	NOTE G_, 4
	NOTE G_, 3
	NOTE G_, 4
	ARP 4
	NOTE G_, 4
	ARP 0
	NOTE G_, 4
	NOTE D_, 3
	NOTE D_, 4
	ARP 4
	NOTE D_, 4
	ARP 0
	NOTE D_, 4
	NOTE D_, 3
	NOTE D_, 4
	ARP 4
	NOTE D_, 4
	ARP 0
	NOTE E_, 4
	NOTE F_, 3
	NOTE F_, 4
	ARP 4
	NOTE F_, 4
	ARP 0
	NOTE F_, 4
	NOTE F_, 3
	NOTE F_, 4
	ARP 4
	NOTE F_, 4
	ARP 0
	NOTE F_, 4
	NOTE E_, 3
	NOTE E_, 4
	ARP 4
	NOTE G_, 4
	ARP 0
	NOTE E_, 4
	NOTE A_, 3
	NOTE A_, 4
	ARP 4
	NOTE A_, 4
	ARP 0
	NOTE A_, 4
	NEXT
Pat_7362:
	HWENV $F1, $02, $D3
	DUTY_75
	LEN 11
	VIBRATO $0B, $01, $05
	ARP 4
	NOTE D_, 4
	WAIT
	WAIT
	NOTE G_, 4
	NOTE G_, 4
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	NOTE G_, 4
	NOTE G_, 4
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	NOTE G_, 4
	NOTE G_, 4
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	ARP 0
	HWENV $F1, $00
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	NEXT
Pat_73B2:
	WAIT
	WAIT
	HWENV $F1, $04, $D7
	ARP 0
	NOTE D_, 5
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE D_, 5
	WAIT
	WAIT
	WAIT
	NOTE D_, 5
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE B_, 4
	WAIT
	WAIT
	NOTE Csh, 5
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Csh, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE Fsh, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE D_, 5
	NOTE A_, 4
	WAIT
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE Fsh, 5
	WAIT
	NOTE E_, 5
	NOTE D_, 5
	WAIT
	NOTE E_, 5
	WAIT
	WAIT
	NEXT
Pat_73F8:
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	NOTE Fsh, 4
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	NOTE Csh, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE B_, 3
	NOTE Csh, 4
	NOTE D_, 4
	WAIT
	NOTE B_, 3
	WAIT
	NOTE Csh, 4
	NOTE D_, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	NOTE Csh, 4
	NOTE A_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE B_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE Csh, 5
	NOTE B_, 4
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE Csh, 4
	NOTE D_, 4
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	NOTE Fsh, 4
	NEXT

; Instrument table 4, entries 1..13 (the song routines point 2 bytes before:
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
	dw Instr4_11
	dw Instr4_12
Instr4_0:
	HWENV $F2, $04, $61
	DUTY_12
	ARP 0
	END
Instr4_1:
	HWENV $F0, $03, $A2
	ARP 4
	DUTY_75
	END
Instr4_2:
	HWENV $F0, $03, $A2
	ARP 5
	DUTY_75
	END
Instr4_3:
	ARP 17
	WAVE Wave_7B4F
	END
Instr4_4:
	ARP 18
	WAVE Wave_7B4F
	END
Instr4_5:
	ARP 19
	WAVE Wave_7B4F
	END
Instr4_6:
	HWENV $F2, $04, $A2
	DUTY_50
	ARP 0
	END
Instr4_7:
	ARP_OFF
	WAVE Wave_7ADF
	END
Instr4_8:
	HWENV $F0, $04, $51
	DUTY_50
	GLIDE $FE
	END
Instr4_9:
	HWENV $F1, $00
	DUTY_75
	ARP 0
	END
Instr4_10:
	HWENV $F3, $00
	DUTY_50
	ARP 0
	END
Instr4_11:
	HWENV $F1, $00
	GLIDE $FF
	END
Instr4_12:
	HWENV $F2, $04, $C4
	ARP 0
	END
DrumPat_74A3:
	db DRUM_LEVEL + 15, 6, DRUM_LEVEL + 13, 6, DRUM_LEVEL + 15, 9, DRUM_LEVEL + 13, 6
	db DRUM_LOOP
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

; Unreferenced (16 bytes)
	db $72, $75, $75, $75, $78, $75, $7C, $75, $80, $75, $88, $75, $8F, $75, $95, $75
Arp0:
	db $0C, $00, ARP_HOLD
Arp1:
	db $00, $00, $01, $01, $02, ARP_HOLD
Arp2:
	db $0E, $00, $01, $02, ARP_HOLD
Arp3:
	db $0D, $0E, $01, $02, ARP_HOLD
Arp4:
	db $00, $04, $07, ARP_LOOP
Arp5:
	db $00, $03, $07, ARP_LOOP
Arp6:
	db $00, $04, $07, ARP_LOOP
Arp7:
	db $00, $03, $07, ARP_LOOP
Arp8:
	db $00, $00, $04, $04, $07, $07, ARP_LOOP
Arp9:
	db $00, $00, $03, $03, $07, $07, ARP_LOOP
Arp10:
	db $07, $0C, $04, $00, ARP_HOLD
Arp11:
	db $00, $0C, $0C, $00, ARP_HOLD
Arp12:
	db $18, $0C, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $18, $00, $00
	db ARP_HOLD
Arp13:
	db $18, $0C, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $24, $00, ARP_HOLD
Arp14:
	db $0C, $0C, $00, $00, ARP_LOOP
Arp15:
	db $00, $00, $00, $01, ARP_HOLD
Arp16:
	db $0C, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $18, $0C, $0C, $0C, $0C
	db $0C, $0C, $0C, $0C, $0C, $0C, ARP_LOOP
Arp17:
	db $0C, $07, $00, ARP_LOOP
Arp18:
	db $0C, $09, $00, ARP_LOOP
Arp19:
	db $0C, $08, $00, ARP_LOOP

; Unreferenced (38 bytes)
	db $00, $0C, $6A, $00, $01, $6A, $00, $0C, $00, $FF, $18, $0C, $00, $FF, $0C, $00
	db $00, $00, $00, $00, $00, $6A, $00, $0C, $04, $10, $07, $13, $6A, $0E, $00, $01
	db $01, $02, $FF, $0C
SfxTable_m2:
	db $00, $6A

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

; Sound effect 29
Sfx29:
	VOLENV 15, $00, $1F, $11
	ARP 0
	WAVE Wave_7A4F
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

; Sound effect 28
Sfx28:
	LEN 4
	VOLENV 15, $11, $1F, $13
	WAVE Wave_7B1F
	ARP 4
	CH_TRANSPOSE $04
	NOTE C_, 5
	REST
	REST
	NOTE C_, 5
	NOTE C_, 5
	REST
	NOTE D_, 5
	REST
	NOTE C_, 5
	REST
	NOTE D_, 5
	REST
	NOTE E_, 5
	WAIT
	WAIT
	WAIT
	GLIDE $FF
	WAIT
	WAIT
	WAIT
	WAIT
	END

; Sound effect 27
Sfx27:
	LEN 26
	VOLENV 15, $11, $1F, $13
	WAVE Wave_7A4F
	ARP 27
	GLIDE $02
	NOTE C_, 3
	END

; Sound effect 26
Sfx26:
	LEN 3
	VOLENV 15, $11, $1F, $11
	WAVE Wave_7A4F
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	VOLENV 5, $00, $00, $00
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	END

; Sound effect 1
Sfx01:
	VOLENV 15, $11, $2F, $11
	WAVE Wave_7A5F
	LEN 13
	NOTE C_, 6
	END

; Sound effect 2
Sfx02:
	LEN 4
	VOLENV 15, $11, $2F, $11
	WAVE Wave_7A5F
	LEN 4
	NOTE Gsh, 5
	LEN 1
	REST
	LEN 4
	NOTE Gsh, 6
	END

; Sound effect 3
Sfx03:
	CALL_CODE Code_7983
	END

; Sound effect 4
Sfx04:
	LEN 8
	VOLENV 15, $10, $1F, $11
	GLIDE $01
	WAVE Wave_7A4F
	NOTE A_, 3
	END

; Sound effect 5
Sfx05:
	CALL_CODE Code_77D2
	END

; Sound effect 6
Sfx06:
	LEN 8
	CALL_CODE Code_77B0
	REST
	CALL_CODE Code_77B0
	REST
	CALL_CODE Code_77B0
	REST
	CALL_CODE Code_77D2
	REST
	END

; Sound effect 7
Sfx07:
	LEN 5
	VOLENV 15, $00, $00, $00
	WAVE Wave_7A4F
	CALL_CODE Code_777F
	GLIDE $03
	NOTE A_, 2
	GLIDE $FC
	WAIT
	END

; Sound effect 8
Sfx08:
	LEN 6
	VOLENV 15, $11, $1F, $13
	WAVE Wave_7B3F
	CALL_CODE Code_777F
	GLIDE $06
	NOTE E_, 3
	GLIDE $FF
	WAIT
	WAIT
	END

; Sound effect 9
Sfx09:
	VOLENV 10, $11, $1F, $12
	WAVE Wave_7A4F
	LEN 13
	SLIDE_DOWN $03
	NOTE A_, 5
	END

; Sound effect 10
Sfx10:
	VOLENV 15, $11, $1F, $11
	CALL_CODE Code_78A2
	WAVE Wave_7A4F
	LEN 12
	GLIDE $FE
	NOTE C_, 3
	END

; Sound effect 11
Sfx11:
	VOLENV 15, $00, $00, $00
	WAVE Wave_7ACF
	LEN 6
	GLIDE $01
	NOTE C_, 6
	REST
	NOTE G_, 6
	END

; Sound effect 12
Sfx12:
	VOLENV 15, $00, $00, $00
	WAVE Wave_7AFF
	LEN 5
	NOTE A_, 3
	LEN 3
	REST
	LEN 20
	NOTE A_, 3
	END

; Sound effect 13
Sfx13:
	CALL_CODE Code_77B0
	END

; Sound effect 14
Sfx14:
	LEN 8
	VOLENV 15, $10, $1F, $11
	GLIDE $01
	WAVE Wave_7A4F
	NOTE D_, 4
	REST
	LEN 4
	CALL_CODE Code_78A2
	REST
	CALL_CODE Code_7956
	END

; Sound effect 15
Sfx15:
	CALL_CODE Code_780E
	END

; Sound effect 16
Sfx16:
	CALL_CODE Code_79F2
	END

; Sound effect 17
Sfx17:
	CALL_CODE Code_78D3
	END

; Sound effect 18
Sfx18:
	VOLENV 10, $00, $00, $00
	GLIDE $FC
	WAVE Wave_7A7F
	CALL_CODE Code_77B0
	LEN 5
	NOTE A_, 6
	END

; Sound effect 19
Sfx19:
	CALL_CODE Code_7956
	END

; Sound effect 20
Sfx20:
	LEN 2
	VOLENV 15, $11, $1F, $11
	WAVE Wave_7A4F
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

; Sound effect 21
Sfx21:
	VOLENV 15, $11, $23, $11
	LEN 5
	ARP 11
	WAVE Wave_7A6F
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

; Sound effect 22
Sfx22:
	LEN 8
	VOLENV 15, $11, $1F, $12
	WAVE Wave_7A4F
	GLIDE $02
	NOTE A_, 3
	GLIDE $02
	NOTE C_, 4
	GLIDE $02
	NOTE E_, 4
	GLIDE $02
	NOTE G_, 4
	GLIDE $02
	NOTE B_, 4
	END

; Sound effect 23
Sfx23:
	CALL_CODE Code_78FC
	END

; Sound effect 24
Sfx24:
	LEN 10
	CALL_CODE Code_77B0
	REST
	CALL_CODE Code_7929
	END

; Sound effect 25
Sfx25:
	LEN 5
	ARP 0
	WAVE Wave_7ACF
	VOLENV 15, $10, $1F, $12
	RELEASE $02, $55
	NOTE C_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	END
Code_777F:
	ld a, $08
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_77A1)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_77A1)
	ld [wNoise43], a
	ld a, HIGH(Noise42_77A9)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_77A9)
	ld [wNoise42], a
	ret
Noise43_77A1:
	db $60, $52, $42, $41, $22, $11, $21, $FF
Noise42_77A9:
	db $F0, $F0, $F0, $F0, $F0, $F0, $61
Code_77B0:
	ld a, $0A
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_77F4)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_77F4)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7806)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7806)
	ld [wNoise42], a
	ret
Code_77D2:
	ld a, $0A
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_77FD)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_77FD)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7806)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7806)
	ld [wNoise42], a
	ret
Noise43_77F4:
	db $10, $10, $20, $31, $33, $34, $35, $36
	db $FF
Noise43_77FD:
	db $36, $35, $34, $33, $31, $20, $10, $10
	db $FF
Noise42_7806:
	db $C1, $FF, $FF, $FF, $FF, $FF, $FF, $FF
Code_780E:
	ld a, $0A
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7830)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7830)
	ld [wNoise43], a
	ld a, HIGH(Noise42_783C)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_783C)
	ld [wNoise42], a
	ret
Noise43_7830:
	db $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0
	db $A0, $A0, $A0, $FF
Noise42_783C:
	db $F0, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $00

; Unreferenced (91 bytes)
	db $3E, $32, $EA, $47, $C1, $AF, $EA, $5B, $C1, $3C, $EA, $5C, $C1, $3E, $78, $EA
	db $57, $C1, $3E, $69, $EA, $58, $C1, $3E, $78, $EA, $59, $C1, $3E, $86, $EA, $5A
	db $C1, $C9, $20, $30, $30, $30, $32, $42, $42, $42, $42, $42, $20, $30, $30, $30
	db $32, $42, $42, $42, $42, $42, $42, $42, $42, $22, $82, $81, $80, $54, $FF, $F0
	db $FF, $55, $00, $B2, $FF, $FF, $FF, $FF, $FF, $F0, $FF, $55, $00, $B2, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $F0, $FF, $FF, $FF, $F4
Code_78A2:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_78C4)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_78C4)
	ld [wNoise43], a
	ld a, HIGH(Noise42_78CC)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_78CC)
	ld [wNoise42], a
	ret
Noise43_78C4:
	db $02, $51, $61, $71, $91, $71, $60, $FF
Noise42_78CC:
	db $F0, $F0, $F0, $F0, $F0, $70, $63
Code_78D3:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_78F5)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_78F5)
	ld [wNoise43], a
	ld a, HIGH(Noise42_78F9)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_78F9)
	ld [wNoise42], a
	ret
Noise43_78F5:
	db $02, $51, $11, $FF
Noise42_78F9:
	db $F0, $A0, $55
Code_78FC:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_791E)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_791E)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7924)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7924)
	ld [wNoise42], a
	ret
Noise43_791E:
	db $02, $41, $61, $71, $11, $FF
Noise42_7924:
	db $F0, $FF, $FF, $A0, $B2
Code_7929:
	ld a, $08
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_794B)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_794B)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7951)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7951)
	ld [wNoise42], a
	ret
Noise43_794B:
	db $00, $83, $60, $60, $31, $FF
Noise42_7951:
	db $F0, $FF, $FF, $FF, $D1
Code_7956:
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7978)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7978)
	ld [wNoise43], a
	ld a, HIGH(Noise42_797E)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_797E)
	ld [wNoise42], a
	ret
Noise43_7978:
	db $00, $53, $71, $91, $31, $FF
Noise42_797E:
	db $F1, $FF, $FF, $FF, $00
Code_7983:
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_79A5)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_79A5)
	ld [wNoise43], a
	ld a, HIGH(Noise42_79AC)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_79AC)
	ld [wNoise42], a
	ret
Noise43_79A5:
	db $41, $61, $61, $41, $71, $71, $FF
Noise42_79AC:
	db $A1, $52, $00, $61, $52, $00

; Unreferenced (64 bytes)
	db $3E, $32, $EA, $47, $C1, $AF, $EA, $5B, $C1, $3C, $EA, $5C, $C1, $3E, $02, $EA
	db $5F, $C1, $AF, $EA, $5E, $C1, $3E, $79, $EA, $57, $C1, $3E, $DD, $EA, $58, $C1
	db $3E, $79, $EA, $59, $C1, $3E, $E8, $EA, $5A, $C1, $C9, $27, $26, $25, $14, $13
	db $12, $11, $10, $10, $10, $FF, $19, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $F3
Code_79F2:
	ld a, $19
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7A14)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7A14)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7A1A)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7A1A)
	ld [wNoise42], a
	ret
Noise43_7A14:
	db $03, $83, $80, $80, $51, $FF
Noise42_7A1A:
	db $F0, $FF, $FF, $FF, $F2
Wave_7A1F:
	db $01, $11, $11, $00, $89, $AA, $AA, $98
	db $01, $11, $11, $00, $FF, $FF, $FF, $FF
Wave_7A2F:
	db $A8, $40, $04, $8A, $FF, $FF, $FF, $FF
	db $A8, $40, $04, $8A, $FF, $FF, $FF, $FF

; Unreferenced (16 bytes)
	db $00, $46, $8A, $FF, $FF, $A8, $64, $00, $00, $46, $8A, $FF, $FF, $A8, $64, $00
Wave_7A4F:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
Wave_7A5F:
	db $00, $00, $00, $00, $CD, $EF, $FD, $EC
	db $00, $12, $21, $00, $DD, $DD, $DD, $DD
Wave_7A6F:
	db $00, $00, $00, $00, $00, $00, $FF, $FF
	db $00, $00, $00, $00, $00, $00, $FF, $FF
Wave_7A7F:
	db $00, $00, $00, $00, $00, $00, $FF, $00
	db $00, $00, $00, $00, $00, $00, $FF, $00

; Unreferenced (16 bytes)
	db $00, $00, $00, $CD, $EF, $FF, $FF, $FF, $04, $8C, $FF, $FF, $FF, $FF, $FF, $FF
Wave_7A9F:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $00, $FF, $FF, $FF

; Unreferenced (32 bytes)
	db $12, $34, $56, $78, $9A, $BC, $DE, $FF, $ED, $CB, $A9, $87, $65, $43, $21, $00
	db $63, $10, $00, $00, $00, $00, $01, $36, $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9
Wave_7ACF:
	db $63, $10, $01, $47, $74, $10, $01, $36
	db $9C, $EF, $FE, $B8, $8B, $EF, $FE, $C9
Wave_7ADF:
	db $63, $20, $02, $47, $74, $22, $22, $36
	db $9C, $EF, $FE, $B6, $6B, $EE, $EE, $C9
Wave_7AEF:
	db $B7, $40, $04, $7B, $CD, $FF, $FE, $DC
	db $02, $46, $8A, $BD, $FD, $BA, $64, $20
Wave_7AFF:
	db $0F, $00, $F0, $F0, $F0, $F0, $00, $0F
	db $0F, $FF, $FF, $00, $FF, $F0, $0F, $0F
Wave_7B0F:
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $ED, $CB, $A9, $87, $65, $43, $21, $00
Wave_7B1F:
	db $FE, $DB, $97, $53, $13, $54, $32, $10
	db $FE, $DC, $BC, $EF, $DB, $85, $32, $10

; Unreferenced (16 bytes)
	db $20, $13, $69, $BD, $FD, $B9, $64, $20, $13, $68, $B8, $64, $20, $24, $68, $64
Wave_7B3F:
	db $20, $24, $68, $AC, $EC, $A8, $64, $20
	db $24, $68, $A8, $64, $20, $24, $68, $64
Wave_7B4F:
	db $02, $48, $AC, $FF, $FC, $53, $00, $27
	db $9C, $DD, $DC, $B7, $7B, $CD, $DD, $C9
Noise43_7B5F:
	db $02, $51, $61, $71, $91, $71, $60, $FF
Noise42_7B67:
	db $F0, $F0, $D0, $90, $70, $40, $31
Noise43_7B6E:
	db $06, $04, $03, $03, $07, $FF
Noise42_7B74:
	db $F0, $C0, $80, $60, $55
Noise43_7B79:
	db $04, $02, $01, $01, $FF
Noise42_7B7E:
	db $80, $40, $30, $23
Noise43_7B82:
	db $04, $02, $01, $01, $04, $02, $01, $FF
Noise42_7B8A:
	db $A0, $60, $33, $23, $A0, $60, $33
Noise43_7B91:
	db $04, $02, $06, $06, $FF
Noise42_7B96:
	db $C0, $80, $60, $44
Noise43_7B9A:
	db $50, $41, $50, $51, $42, $53, $51, $FF
Noise42_7BA2:
	db $F0, $70, $F0, $70, $D0, $70, $61

; Unreferenced (8 bytes)
	db $3E, $08, $EA, $47, $C1, $CD, $8F, $49
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B5F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B5F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B67)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B67)
	ld [wNoise42], a
	ret
Drum8:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7BEB)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7BEB)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7BF1)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7BF1)
	ld [wNoise42], a
	ret
Noise43_7BEB:
	db $04, $02, $01, $00, $00, $FF
Noise42_7BF1:
	db $40, $60, $70, $82, $71
Drum2:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7C13)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7C13)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7C1B)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7C1B)
	ld [wNoise42], a
	ret
Noise43_7C13:
	db $60, $52, $42, $41, $22, $11, $04, $FF
Noise42_7C1B:
	db $F0, $F0, $F0, $A0, $70, $40, $51
Drum3:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B9A)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B9A)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7BA2)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7BA2)
	ld [wNoise42], a
	ret
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B91)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B91)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B96)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B96)
	ld [wNoise42], a
	ret
Drum5:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B82)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B82)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B8A)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B8A)
	ld [wNoise42], a
	ret
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B79)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B79)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B7E)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B7E)
	ld [wNoise42], a
	ret
Drum7:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B6E)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B6E)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B74)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B74)
	ld [wNoise42], a
	ret
Drum9:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7CD0)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7CD0)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7CD3)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7CD3)
	ld [wNoise42], a
	ret
Noise43_7CD0:
	db $51, $32, $FF
Noise42_7CD3:
	db $F0, $72
Drum10:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7D0F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7D0F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7D12)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7D12)
	ld [wNoise42], a
	ret
Drum11:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7D14)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7D14)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7D1C)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7D1C)
	ld [wNoise42], a
	ret
Noise43_7D0F:
	db $51, $32, $FF
Noise42_7D12:
	db $90, $61
Noise43_7D14:
	db $51, $32, $32, $32, $32, $51, $32, $FF
Noise42_7D1C:
	db $80, $51, $FF, $FF, $FF, $80, $51
FadeOutTable:
	db $77, $66, $55, $44, $33, $22, $11, $00
	db FADE_END
FadeInTable:
	db $00, $11, $22, $33, $44, $55, $66, $77
	db FADE_END

; Unreferenced (715 bytes)
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
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
