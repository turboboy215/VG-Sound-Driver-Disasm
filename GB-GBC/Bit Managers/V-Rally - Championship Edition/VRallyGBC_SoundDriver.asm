; =====================================================================
; V-Rally: Championship Edition (E) (M4) [C] - Game Boy Color
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4 (GBC revision)
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o vrallygbc.o VRallyGBC_SoundDriver.asm
;   rgblink -o vrallygbc.gb vrallygbc.o
;   python tools/cmp_banked.py vrallygbc.gb "V-Rally - Championship Edition (E) (M4) [C][!].gbc" 16:4000-7FFF
; (driver and data fill ROM bank 16; the linked file only matches in that range)
;
; Documentation: VRally_SoundDriver.md / AJG_SoundEngine_Family.md
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
MACRO REPEAT    ; play the following bytes n times (up to REPEAT_END), n = 2-13
	db $F2 + \1
ENDM
MACRO LEN       ; note length in ticks, 1-48
	db $C3 + \1
ENDM
MACRO VOLENV    ; start volume + envelope (CH3/SFX): atk (lo=count hi=step), dec (lo=count hi=step), rates (hi=atk lo=dec)
	db $B4 + \1, \2, \3, \4
ENDM
MACRO INSTR     ; instrument n = entry n + 1 of the current instrument table
	db $85 + \1
ENDM
MACRO ARP       ; arpeggio n of the current arpeggio table
	db $98 + \1
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
DEF DRUM_TEMPO EQU $C3         ; + n: one step every n ticks
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
DEF wDutyCh1 EQU $DB66
DEF wDutyCh2 EQU $DB67
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


SECTION "SoundDriver", ROMX[$4000], BANK[16]


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
	jp EngineStart                     ; EngineStart (game: race-engine sound on)
	jp EngineUpdate                    ; EngineUpdate (rpm in $DC87)
	jp EngineTick                      ; EngineTick
	jp EngineWaveA                     ; EngineWaveA
	jp EngineWaveB                     ; EngineWaveB
	jp EngineHit2                      ; EngineHit2 (CH1)
	jp EngineHit1                      ; EngineHit1 (CH1)
	jp EngineHit3                      ; EngineHit3 (CH1)
	jp EngineCh1Off                    ; EngineCh1Off
	jp EngineNoise3                    ; EngineNoise3
	jp EngineNoise1                    ; EngineNoise1
	jp EngineNoise2                    ; EngineNoise2
	jp EngineCh2Seq                    ; EngineCh2Seq (A = id)
	jp EngineStop                      ; EngineStop
	jp PlaySong1                       ; song 1
	jp PlaySong2                       ; song 2
	jp PlaySong3                       ; song 3
	jp PlaySong4                       ; song 4
	jp PlaySong5                       ; song 5
	jp PlaySong6                       ; song 6
	jp PlaySong7                       ; song 7
	jp PlaySong8                       ; song 8
	jp InstrTable1                      ; unused song slot: jumps into the instrument table (never called)
	jp InstrTable1                      ; unused song slot: jumps into the instrument table (never called)
	jp InstrTable1                      ; unused song slot: jumps into the instrument table (never called)
	jp InstrTable1                      ; unused song slot: jumps into the instrument table (never called)
	jp InstrTable1                      ; unused song slot: jumps into the instrument table (never called)
PlaySfxEntry2:
	jp PlaySfx                         ; PlaySfxNow (A = id; the same code as PlaySfx)

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
	ld a, [$DC91]
	and a
	jp nz, EngineUpdate
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
	add a, $F2
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
	sub $F2
	ld l, $39
	ld [hli], a
	ld [hl], e
	inc l
	ld [hl], d
	jp ReadByte

; StreamCommand: REPEAT / LEN / VOLENV / ARP / INSTR ranges, else CmdTable.
StreamCommand:
	cp $F4
	jr nc, Cmd_Repeat
	cp $C4
	jr nc, Cmd_Len
	cp $B4
	jr nc, Cmd_VolEnv
	cp $98
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
	sub $C3
	ld l, $09
	ld [hl], a
	jp ReadStream

; VOLENV v, atk, dec, rates: start volume v; attack = lo nibble steps of hi nibble;
; decay likewise; rates hi = ticks per attack step, lo = ticks per decay step.
; Only the CH3 and SFX pages use it.
Cmd_VolEnv:
	sub $B4
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
	sub $98
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
	call SndResume
	call EngineStop
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
	cp $DB
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
	xor a
	ldh [rNR31], a
	ld a, $80
	ld [$DD07], a
	ldh [rNR30], a
	ldh [rNR34], a
	ret

; Unreferenced (16 bytes)
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
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
DriverDateText:
	db "1998 by Alberto Jose Gonzalez."

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

; StartMusicChN (de = order list): set wInstrTable to the one instrument table (in
; all three entries, so every song plays with it; 14 bytes apart, not 4), reset
; the page, mark it active, start its first pattern. StartMusicCh3 also stops the
; fade and the drums.
StartMusicCh1:
	ld a, $5C
	ld [wInstrTableHi], a
	ld a, $6C
	ld [wInstrTable], a
	ld h, $DB
	jr StartMusicCh
StartMusicCh2:
	ld a, $5C
	ld [wInstrTableHi], a
	ld a, $6C
	ld [wInstrTable], a
	ld h, $DC
	jr StartMusicCh
StartMusicCh3:
	ld a, HIGH(InstrTable1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable1 - 2)
	ld [wInstrTable], a
	ld h, $DD
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

; API entry for PlaySfx: jumps to the last slot of the API table (PlaySfxEntry2),
; which jumps to PlaySfx.
PlaySfxEntry:
	jp PlaySfxEntry2

; PlaySfx (A = id): no priority test; reset the SFX page and start the stream.
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
	add a, $DE
	ld l, a
	adc a, $5D
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
	cp $C4
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
	add a, $2E
	ld l, a
	adc a, $4A
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

; Unreferenced (4 bytes)
	db $8E, $5F, $AB, $5F
DrumTempo:
	sub $C3
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
DriverCreditText:
	db "(Music & Sound Driver by Alberto Jose Gonzalez, 1998)"

; Load engine wave A (if the B wave is loaded), CH3 volume $20
EngineWaveA:
	ld a, [$DC89]
	and a
	ret z
	xor a
	ld [$DC89], a
	ld a, $20
	ld [$DC86], a
	ld hl, EngineWaveA_Data
	jp EngineLoadWave

; Load engine wave B (if wave A is loaded)
EngineWaveB:
	ld a, [$DC89]
	and a
	ret nz
	inc a
	ld [$DC89], a
	ld a, $20
	ld [$DC86], a
	ld hl, EngineWaveB_Data
	jp EngineLoadWave

; CH1 hit: duty 75 %, NR12 $A0, trigger; random-pitch seed 7
EngineHit1:
	ld a, $C0
	ldh [rNR11], a
	ld a, $A0
	ldh [rNR12], a
	ld a, $80
	ldh [rNR14], a
	ld a, $07
	ld [$DC8A], a
	ret

; CH1 hit: NR12 $70; seed 3
EngineHit2:
	ld a, $80
	ldh [rNR11], a
	ld a, $70
	ldh [rNR12], a
	ld a, $87
	ldh [rNR14], a
	ld a, $03
	ld [$DC8A], a
	ret

; CH1 hit: NR12 $90; seed 10
EngineHit3:
	ld a, $80
	ldh [rNR11], a
	ld a, $90
	ldh [rNR12], a
	ld a, $87
	ldh [rNR14], a
	ld a, $0A
	ld [$DC8A], a
	ret

; Start a noise sequence (NR43 table, NR42 table; $FF ends / $FF in NR42 = no write)
EngineNoise1:
	ld a, $4E
	ld [$DC93], a
	ld a, $A2
	ld [$DC92], a
	ld a, $4E
	ld [$DC95], a
	ld a, $C8
	ld [$DC94], a
	ret
EngineNoise2:
	ld a, $4E
	ld [$DC93], a
	ld a, $27
	ld [$DC92], a
	ld a, $4E
	ld [$DC95], a
	ld a, $65
	ld [$DC94], a
	ret
EngineNoise3:
	ld a, $4E
	ld [$DC93], a
	ld a, $18
	ld [$DC92], a
	ld a, $4E
	ld [$DC95], a
	ld a, $20
	ld [$DC94], a
	ret

; CH1 volume off
EngineCh1Off:
	xor a
	ldh [rNR12], a
	ret

; Game code in the sound bank: the race-engine sound (API slot 9). Sets EngineOn ($DC91),
; which makes SndUpdate run EngineUpdate instead of the music; silences all four channels.
EngineStart:
	ld a, $FF
	ldh [rNR52], a
	ldh [rNR51], a
	ld a, $77
	ldh [rNR50], a
	ld a, $38
	ld [$DC85], a
	ld a, $0F
	ld hl, $DC81
	ld [hli], a
	ld [hli], a
	ld a, $20
	ld [$DC87], a
	ld a, $C0
	ldh [rNR21], a
	xor a
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR32], a
	ldh [rNR42], a
	ld [$DC8C], a
	ld [$DC93], a
	ld [$DC89], a
	inc a
	ld [$DC91], a
	call EngineWaveB
	ret

; EngineStop (API slot 22, also called by StopAll): silence, clear $DC91/$DC93/$DC8C
EngineStop:
	xor a
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR32], a
	ldh [rNR42], a
	ld [$DC93], a
	ld [$DC8C], a
	ld [$DC91], a
	ld a, $80
	ldh [rNR14], a
	ldh [rNR24], a
	ldh [rNR34], a
	ldh [rNR44], a
	ret
EngineLoadWave:
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
	xor a
	ldh [rNR31], a
	ld a, $80
	ldh [rNR30], a
	ld [$DC84], a
	ldh [rNR34], a
	ret
EngineRandCh3:
	ld a, [$DC85]
	add a, $0E
	xor $4D
	ld [$DC85], a
	and $1F
	ret
EngineRandCh1:
	ld a, [$DC8A]
	add a, $0D
	xor $65
	ld [$DC8A], a
	and $1F
	ret

; EngineUpdate (API slot 10, and SndUpdate while $DC91 is set): base CH3 period = rpm ($DC87) * 8,
; then EngineTick.
EngineUpdate:
	ld a, [$DC87]
	ld l, a
	ld h, $00
	add hl, hl
	add hl, hl
	add hl, hl
	ld a, l
	ld [$DC80], a
	ld a, h
	ld [$DC81], a

; EngineTick (API slot 11): CH3 drone at the base period + a pseudo-random 0-31 (EngineRandCh3),
; CH1 NR13 = $FA + random (EngineRandCh1), then one step of the CH2 sequence and of the noise sequence.
EngineTick:
	ld a, [$DC91]
	and a
	ret z
	call EngineRandCh3
	ld c, a
	ld a, [$DC80]
	add a, c
	jr nc, L4D0D
	ld a, $FF
	and a
L4D0D:
	ld [$DC82], a
	ld a, [$DC81]
	adc a, $00
	ld [$DC83], a
	ld a, [$DC86]
	ldh [rNR32], a
	ld hl, $DC82
	ld a, [hli]
	ldh [rNR33], a
	ld a, [hli]
	and $07
	ld c, a
	ld a, [hl]
	cp c
	jr z, L4D32
	ld [hl], c
	xor a
	ldh [rNR31], a
	ld a, c
	ldh [rNR34], a
L4D32:
	ld a, $FA
	ld c, a
	call EngineRandCh1
	add a, c
	ldh [rNR13], a
	ld a, [$DC8C]
	and a
	jp z, EngineNoiseStep
	ld a, [$DC8D]
	and a
	jr z, L4D4F
	dec a
	ld [$DC8D], a
	jp EngineNoiseStep
L4D4F:
	ld a, [$DC8E]
	ld [$DC8D], a
	ld a, [$DC8B]
	ld e, a
	ld a, [$DC8C]
	ld d, a
EngineCh2Step:
	ld a, [de]
	inc de
	cp $60
	jp nc, L4D80
	add a, a
	ld b, $48
	ld c, a
	ld a, $C3
	ldh [rNR22], a
	ld a, [bc]
	inc bc
	ldh [rNR23], a
	ld a, [bc]
	or $80
	ldh [rNR24], a
L4D75:
	ld a, d
	ld [$DC8C], a
	ld a, e
	ld [$DC8B], a
	jp EngineNoiseStep
L4D80:
	cp $C4
	jr nc, L4DA5
	cp $68
	jp z, L4DB0
	cp $65
	jp z, L4D9C
	cp $66
	jp z, L4D96
	jp EngineCh2Step
L4D96:
	xor a
	ldh [rNR22], a
	jp L4D75
L4D9C:
	ld a, [$DC8E]
	ld [$DC8D], a
	jp L4D75
L4DA5:
	sub $C4
	ld [$DC8D], a
	ld [$DC8E], a
	jp EngineCh2Step
L4DB0:
	xor a
	ld [$DC8C], a
	inc a
	ld [$DC8D], a
	jp EngineNoiseStep
EngineNoiseStep:
	ld a, [$DC93]
	and a
	ret z
	ld d, a
	ld a, [$DC92]
	ld e, a
	ld a, [$DC95]
	ld b, a
	ld a, [$DC94]
	ld c, a
	ld a, [de]
	cp $FF
	jr z, L4DF5
	ldh [rNR43], a
	ld a, [bc]
	cp $FF
	jr z, L4DE2
	ldh [rNR42], a
	xor a
	ldh [rNR41], a
	ld a, $80
	ldh [rNR44], a
L4DE2:
	inc de
	inc bc
	ld a, b
	ld [$DC95], a
	ld a, c
	ld [$DC94], a
	ld a, d
	ld [$DC93], a
	ld a, e
	ld [$DC92], a
	ret
L4DF5:
	xor a
	ld [$DC93], a
	ret
EngineCh2SeqTable:
	db $00, $4E, $11, $4E, $15, $4E
EngineCh2Seq0:
	db $C7, $2D, $66, $2D, $65, $66, $2D, $66
	db $2D, $65, $66, $2D, $66, $2D, $65, $66
	db $68
EngineCh2Seq1:
	db $DC, $23, $66, $68
EngineCh2Seq2:
	db $C8, $2F, $68
EngineNoise3_NR43:
	db $15, $27, $35, $47, $55, $67, $7C, $FF
EngineNoise3_NR42:
	db $F1, $FF, $FF, $FF, $FF, $FF, $FF
EngineNoise2_NR43:
	db $25, $08, $14, $54, $55, $15, $54, $25
	db $06, $55, $55, $00, $00, $00, $14, $54
	db $55, $65, $55, $56, $47, $48, $47, $46
	db $45, $43, $44, $44, $43, $47, $4A, $48
	db $47, $43, $47, $43, $42, $41, $40, $00
	db $57, $00, $47, $46, $45, $43, $44, $44
	db $43, $47, $4A, $48, $47, $43, $47, $43
	db $42, $41, $40, $00, $47, $FF
EngineNoise2_NR42:
	db $F1, $FF, $FF, $FF, $F1, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $C1, $FF
	db $FF, $FF, $FF, $FF, $F7, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF
EngineNoise1_NR43:
	db $25, $08, $14, $54, $55, $65, $54, $25
	db $06, $55, $55, $00, $00, $00, $00, $00
	db $14, $54, $55, $65, $54, $55, $56, $47
	db $47, $47, $47, $47, $47, $14, $54, $55
	db $65, $54, $55, $56, $47, $FF
EngineNoise1_NR42:
	db $F1, $FF, $FF, $FF, $F1, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $C3, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $F1, $FF, $FF, $FF, $F3, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $C3, $FF, $FF, $FF, $FF, $FF, $FF, $FF

; A = sequence id: start a CH2 tone sequence from EngineCh2SeqTable. The streams use the driver's
; note bytes ($00-$5F, period table at $4800), lengths from $C4, WAIT $65, REST $66, END $68.
EngineCh2Seq:
	add a, a
	add a, $FA
	ld c, a
	adc a, $4D
	sub c
	ld b, a
	ld a, [bc]
	ld [$DC8B], a
	inc bc
	ld a, [bc]
	ld [$DC8C], a
	ld a, $01
	ld [$DC8D], a
	ret

; Unreferenced: ld a, 0 / jp EngineCh2Seq
Unused_EngineCh2Seq0:
	db $3E, $00, $C3, $F8, $4E
EngineWaveA_Data:
	db $48, $FF, $FF, $FF, $FF, $FF, $FF, $84
	db $00, $05, $75, $00, $00, $4F, $FF, $88

; 16-byte wave. The 10 bytes after it are unreferenced leftover SM83 code: ld a, [$DC91] /
; and a / jp z, $4062 / jp $4089 (an older form of the SndUpdate engine hook)
EngineWaveB_Data:
	db $63, $10, $40, $20, $00, $00, $01, $36
	db $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9

; Unreferenced (10 bytes)
	db $FA, $91, $DC, $A7, $CA, $62, $40, $C3, $89, $40

; Song 1: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong1:
	call StopAll
	ld a, HIGH(InstrTable1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable1 - 2)
	ld [wInstrTable], a
	ld de, Song1_Ch3
	call StartMusicCh3
	ld de, Song1_Ch2
	call StartMusicCh2
	ld de, Song1_Ch1
	jp StartMusicCh1
Song1_Ch3:
	dw Pat_4F93
	dw Pat_4F93
	dw Pat_4FD9
	dw Pat_4FFE
	dw Pat_4FD9
	dw Pat_4FFE
	dw Pat_5031
	ORDER_LOOP Song1_Ch3
Song1_Ch2:
	dw Pat_5044
	dw Pat_5044
	dw Pat_5097
	dw Pat_50ED
	dw Pat_5097
	dw Pat_50ED
	dw Pat_5143
	ORDER_LOOP Song1_Ch2
Song1_Ch1:
	dw Pat_5199
	dw Pat_5199
	dw Pat_51CB
	dw Pat_522E
	dw Pat_51CB
	dw Pat_5241
	dw Pat_5257
	ORDER_LOOP Song1_Ch1
Pat_4F93:
	CH_TRANSPOSE $0C
	TRANSPOSE $FE
	DRUMS $07, DrumPat_5292
	INSTR 11
	LEN 7
	NOTE C_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	LEN 14
	NOTE D_, 2
	NOTE D_, 2
	LEN 7
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	LEN 14
	NOTE D_, 2
	NOTE D_, 2
	LEN 7
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	LEN 14
	NOTE C_, 3
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE C_, 2
	NOTE D_, 2
	LEN 7
	NOTE D_, 2
	LEN 14
	NOTE D_, 3
	NOTE C_, 3
	NOTE A_, 2
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE F_, 2
	NOTE G_, 2
	NOTE C_, 2
	NEXT
Pat_4FD9:
	INSTR 11
	LEN 7
	REPEAT 3
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 3
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	REPEAT_END
	NOTE C_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	LEN 14
	NOTE D_, 2
	NOTE D_, 2
	LEN 7
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NEXT
Pat_4FFE:
	REPEAT 2
	NOTE Ash, 2
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 4
	LEN 14
	NOTE C_, 3
	NOTE C_, 3
	LEN 7
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 3
	NOTE Ash, 2
	REPEAT_END
	NOTE D_, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 3
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE D_, 2
	NOTE Dsh, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 3
	LEN 14
	NOTE F_, 2
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NEXT
Pat_5031:
	REPEAT 4
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 3
	LEN 14
	NOTE G_, 2
	NOTE G_, 2
	LEN 7
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	REPEAT_END
	NEXT
Pat_5044:
	INSTR 9
	LEN 7
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	LEN 14
	NOTE D_, 4
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE D_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	LEN 14
	NOTE D_, 4
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE D_, 4
	NOTE C_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	LEN 14
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 4
	LEN 7
	NOTE F_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE G_, 4
	LEN 14
	NOTE C_, 4
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	NOTE D_, 5
	INSTR 0
	NOTE A_, 3
	INSTR 9
	LEN 14
	NOTE C_, 5
	NOTE A_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE F_, 4
	INSTR 0
	NOTE A_, 3
	LEN 7
	NOTE A_, 3
	NOTE A_, 3
	NEXT
Pat_5097:
	INSTR 9
	LEN 7
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	LEN 14
	NOTE D_, 4
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE D_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	LEN 14
	NOTE D_, 4
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	LEN 14
	NOTE D_, 4
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE D_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE F_, 4
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	NOTE E_, 4
	LEN 7
	NOTE E_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	NOTE A_, 3
	NEXT
Pat_50ED:
	INSTR 9
	LEN 7
	NOTE F_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE Dsh, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE G_, 3
	NOTE Ash, 3
	NOTE G_, 3
	NOTE Dsh, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE G_, 3
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE F_, 4
	INSTR 0
	NOTE A_, 3
	NOTE A_, 3
	NEXT
Pat_5143:
	INSTR 9
	LEN 7
	NOTE F_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE C_, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE D_, 5
	INSTR 0
	NOTE A_, 3
	INSTR 9
	LEN 14
	NOTE D_, 5
	NOTE D_, 5
	LEN 7
	NOTE D_, 5
	NOTE D_, 5
	NOTE D_, 5
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE D_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	INSTR 0
	NOTE A_, 3
	INSTR 9
	LEN 14
	NOTE G_, 5
	NOTE G_, 5
	LEN 7
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE G_, 5
	INSTR 0
	NOTE A_, 3
	NOTE A_, 3
	NEXT
Pat_5199:
	CH_TRANSPOSE $0C
	RELEASE $02, $42
	VIBRATO $07, $01, $04
	INSTR 6
	DUTY_75
	LENGTH $69
	NOTE D_, 3
	LEN 7
	NOTE C_, 3
	LENGTH $62
	NOTE D_, 3
	LEN 14
	NOTE C_, 3
	LEN 7
	NOTE C_, 3
	LEN 21
	NOTE D_, 3
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE C_, 4
	NOTE A_, 3
	NOTE G_, 3
	NOTE F_, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE C_, 3
	NOTE D_, 3
	LEN 7
	NOTE D_, 3
	LEN 14
	NOTE D_, 4
	NOTE C_, 4
	NOTE A_, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE F_, 3
	NOTE G_, 3
	NOTE C_, 3
	NEXT
Pat_51CB:
	INSTR 13
	LEN 7
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	WAIT2
	NOTE D_, 5
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE A_, 4
	NOTE G_, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE Ash, 4
	LEN 35
	NOTE D_, 4
	LEN 7
	WAIT2
	NOTE G_, 3
	NOTE Ash, 3
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	LENGTH $31
	NOTE G_, 4
	LEN 7
	WAIT2
	NOTE D_, 4
	NOTE Ash, 4
	NOTE A_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	LEN 14
	NOTE F_, 4
	LEN 7
	WAIT2
	LENGTH $69
	NOTE D_, 4
	LEN 7
	WAIT2
	NEXT
Pat_5200:
	INSTR 13
	LEN 7
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE F_, 5
	WAIT2
	NOTE G_, 5
	WAIT2
	NOTE F_, 5
	WAIT2
	NOTE Dsh, 5
	WAIT2
	NOTE D_, 5
	NOTE C_, 5
	WAIT2
	NOTE Ash, 4
	WAIT2
	LEN 14
	NOTE D_, 5
	LEN 7
	NOTE Dsh, 5
	LEN 35
	NOTE G_, 4
	LEN 7
	WAIT2
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Ash, 4
	LENGTH $31
	NOTE C_, 5
	LEN 7
	WAIT2
	NOTE G_, 4
	NOTE Dsh, 5
	NOTE D_, 5
	WAIT2
	NOTE C_, 5
	WAIT2
	LEN 14
	NOTE Ash, 4
	NEXT
Pat_522E:
	PAT_CALL Pat_5200
	LEN 7
	WAIT2
	LEN 35
	NOTE Ash, 4
	LEN 7
	NOTE C_, 5
	NOTE Ash, 4
	LEN 28
	NOTE A_, 4
	LEN 7
	WAIT2
	LEN 21
	NOTE F_, 4
	LEN 7
	WAIT2
	NEXT
Pat_5241:
	PAT_CALL Pat_5200
	LEN 7
	WAIT2
	LEN 21
	NOTE A_, 4
	LEN 7
	WAIT2
	LEN 21
	NOTE C_, 5
	LEN 7
	WAIT2
	LEN 21
	NOTE F_, 5
	LEN 7
	WAIT2
	LEN 21
	NOTE A_, 5
	LEN 7
	WAIT2
	NEXT
Pat_5257:
	INSTR 13
	LEN 7
	NOTE F_, 5
	LENGTH $69
	NOTE G_, 5
	CH_TRANSPOSE $00
	INSTR 4
	LEN 7
	NOTE F_, 4
	INSTR 5
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	INSTR 4
	NOTE F_, 4
	INSTR 5
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	INSTR 4
	NOTE F_, 4
	LEN 7
	NOTE F_, 5
	INSTR 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	LEN 14
	NOTE G_, 5
	NOTE G_, 5
	LEN 7
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	INSTR 4
	NOTE F_, 5
	NEXT
DrumPat_5292:
	db 1, 6, 1, 1, 9, 1, 6, 1
	db 6, 1, 1, 1, 9, 1, 1, 1
	db 1, 6, 1, 1, 9, 1, 6, 1
	db 6, 1, 1, 1, 9, 1, 1, 9
	db 1, 6, 1, 1, 9, 1, 6, 1
	db 6, 1, 1, 1, 9, 1, 1, 1
	db 1, 6, 1, 1, 9, 1, 6, 1
	db 6, 1, 1, 1, 9, 1, 9, 9
	db DRUM_LOOP

; Song 2: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong2:
	call StopAll
	ld a, HIGH(InstrTable1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable1 - 2)
	ld [wInstrTable], a
	ld de, Song2_Ch3
	call StartMusicCh3
	ld de, Song2_Ch2
	call StartMusicCh2
	ld de, Song2_Ch1
	jp StartMusicCh1
Song2_Ch3:
	dw Pat_5314
	ORDER_LOOP Song2_Ch3
Song2_Ch2:
	dw Pat_53AE
Loop_52FA:
	dw Pat_5377
	dw Pat_537B
	dw Pat_5331
	dw Pat_5331
	ORDER_LOOP Loop_52FA
Song2_Ch1:
	dw Pat_5437
Loop_5308:
	dw Pat_540C
	dw Pat_545A
	dw Pat_53D0
	dw Pat_53D0
	ORDER_LOOP Loop_5308
Pat_5314:
	CH_TRANSPOSE $0C
	INSTR 11
	REPEAT 2
	LEN 28
	NOTE F_, 2
	LEN 14
	NOTE Gsh, 2
	LEN 7
	NOTE F_, 2
	LEN 21
	NOTE Gsh, 2
	LEN 14
	NOTE Ash, 2
	NOTE Dsh, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE Gsh, 2
	LEN 7
	NOTE F_, 2
	LEN 21
	NOTE Gsh, 2
	LEN 14
	NOTE Ash, 2
	NOTE Dsh, 2
	NOTE E_, 2
	REPEAT_END
	NEXT
Pat_5331:
	LEN 7
	REPEAT 2
	INSTR 2
	NOTE G_, 3
	INSTR 9
	NOTE F_, 4
	NOTE F_, 3
	NOTE F_, 3
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 4
	REPEAT_END
	REPEAT 2
	INSTR 2
	NOTE G_, 3
	INSTR 9
	NOTE Dsh, 4
	NOTE Dsh, 3
	NOTE Dsh, 3
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE Dsh, 3
	NOTE Dsh, 3
	NOTE Dsh, 4
	REPEAT_END
	REPEAT 2
	INSTR 2
	NOTE G_, 3
	INSTR 9
	NOTE F_, 4
	NOTE F_, 3
	NOTE F_, 3
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 4
	REPEAT_END
	INSTR 2
	NOTE G_, 3
	INSTR 9
	NOTE Gsh, 4
	NOTE Gsh, 3
	NOTE Gsh, 3
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 4
	INSTR 2
	NOTE G_, 3
	INSTR 9
	NOTE Ash, 4
	NOTE Ash, 3
	NOTE Ash, 3
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE Ash, 3
	INSTR 2
	NOTE G_, 3
	INSTR 0
	NOTE A_, 3
	NEXT
Pat_5377:
	DRUMS $07, DrumPat_548D
Pat_537B:
	LEN 14
	REPEAT 2
	INSTR 2
	NOTE G_, 3
	INSTR 5
	NOTE F_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 5
	NOTE F_, 4
	REPEAT_END
	REPEAT 2
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE Gsh, 4
	INSTR 0
	NOTE A_, 3
	INSTR 4
	NOTE Gsh, 4
	REPEAT_END
	REPEAT 2
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE Ash, 4
	INSTR 0
	NOTE A_, 3
	INSTR 4
	NOTE Ash, 4
	REPEAT_END
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE Csh, 5
	INSTR 0
	NOTE A_, 3
	INSTR 4
	NOTE Csh, 5
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE Dsh, 5
	INSTR 0
	NOTE A_, 3
	INSTR 2
	LEN 7
	NOTE G_, 3
	INSTR 0
	NOTE A_, 3
	NEXT
Pat_53AE:
	DRUMS $07, DrumPat_5488
	INSTR 2
	LEN 28
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	NOTE G_, 3
	LEN 28
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	INSTR 0
	DRUMS $07, DrumPat_54B2
	LEN 14
	NOTE A_, 3
	INSTR 2
	NOTE G_, 3
	NEXT
Pat_53D0:
	LEN 14
	WAIT
	INSTR 5
	NOTE F_, 5
	NOTE F_, 5
	LEN 7
	NOTE F_, 4
	LEN 21
	NOTE F_, 5
	LEN 14
	NOTE F_, 5
	NOTE F_, 5
	LEN 7
	NOTE F_, 4
	LEN 21
	NOTE F_, 5
	INSTR 4
	LEN 14
	NOTE Gsh, 5
	NOTE Gsh, 5
	LEN 7
	NOTE Gsh, 4
	LEN 21
	NOTE Gsh, 5
	LEN 14
	NOTE Gsh, 5
	NOTE Gsh, 5
	LEN 7
	NOTE Gsh, 4
	LEN 21
	NOTE Gsh, 5
	LEN 14
	NOTE Ash, 5
	NOTE Ash, 5
	LEN 7
	NOTE Ash, 4
	LEN 21
	NOTE Ash, 5
	LEN 14
	NOTE Ash, 5
	NOTE Ash, 5
	LEN 7
	NOTE Ash, 4
	LEN 21
	NOTE Ash, 5
	LEN 14
	NOTE Csh, 5
	NOTE Csh, 5
	LEN 7
	NOTE Csh, 4
	LEN 21
	NOTE Csh, 5
	LEN 14
	NOTE Dsh, 5
	NOTE Dsh, 5
	LEN 7
	NOTE Dsh, 5
	INSTR 5
	NOTE F_, 5
	NEXT
Pat_540C:
	INSTR 13
	LEN 42
	NOTE C_, 5
	INSTR 15
	LEN 7
	NOTE Dsh, 4
	LEN 21
	NOTE F_, 4
	LEN 14
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE F_, 3
	INSTR 13
	NOTE C_, 5
	NOTE Ash, 4
	LEN 7
	NOTE Gsh, 4
	LEN 21
	NOTE Ash, 4
	LEN 14
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE C_, 5
	LEN 42
	NOTE Ash, 4
	LEN 7
	NOTE Gsh, 4
	LEN 21
	NOTE F_, 4
	LEN 14
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 21
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 14
	NOTE F_, 4
	LENGTH $38
	NOTE C_, 4
	NEXT
Pat_5437:
	VIBRATO $0E, $01, $04
	HWENV $00, $00
	LENGTH $E0
	REST
	INSTR 9
	LEN 28
	NOTE F_, 3
	LEN 14
	NOTE Gsh, 3
	LEN 7
	NOTE F_, 3
	LEN 21
	NOTE Gsh, 3
	LEN 14
	NOTE Ash, 3
	NOTE Dsh, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE Gsh, 3
	LEN 7
	NOTE F_, 3
	LEN 21
	NOTE Gsh, 3
	LEN 14
	NOTE Ash, 3
	NOTE Dsh, 3
	NOTE E_, 3
	NEXT
Pat_545A:
	INSTR 13
	LEN 42
	NOTE C_, 5
	INSTR 15
	LEN 7
	NOTE Dsh, 4
	LEN 21
	NOTE F_, 4
	LEN 14
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE F_, 3
	INSTR 13
	NOTE C_, 5
	NOTE Ash, 4
	LEN 7
	NOTE Gsh, 4
	LEN 21
	NOTE Ash, 4
	LEN 14
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE C_, 5
	LEN 42
	NOTE Ash, 4
	LEN 7
	NOTE C_, 5
	LEN 21
	NOTE F_, 4
	LEN 14
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 21
	NOTE Gsh, 4
	NOTE F_, 4
	LEN 14
	NOTE C_, 5
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Dsh, 4
	LEN 7
	NOTE C_, 4
	NOTE F_, 4
	NEXT
DrumPat_5488:
	db 1, 0, 5, 6, DRUM_LOOP
DrumPat_548D:
	db DRUM_REPEAT + 3, 1, 0, 5, 6, 9, 0, 5
	db 6, DRUM_REPEAT_END, 1, 0, 5, 6, 9, 0
	db 4, 0, DRUM_REPEAT + 3, 1, 0, 5, 6, 9
	db 0, 5, 6, DRUM_REPEAT_END, 1, 0, 5, 6
	db 9, 0, 1, 9, DRUM_LOOP
DrumPat_54B2:
	db 9, 6, 1, 5, 0                    ; no DRUM_LOOP: the pattern runs into the next data

; Song 3: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong3:
	call StopAll
	ld a, HIGH(InstrTable1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable1 - 2)
	ld [wInstrTable], a
	ld de, Song3_Ch3
	call StartMusicCh3
	ld de, Song3_Ch2
	call StartMusicCh2
	ld de, Song3_Ch1
	jp StartMusicCh1

; Unreferenced (1 bytes)
	db $C9
Song3_Ch3:
	dw Pat_54E9

; Unreferenced (4 bytes)
	db $00, $00, $D7, $54
Song3_Ch2:
	dw Pat_54F8

; Unreferenced (4 bytes)
	db $00, $00, $DD, $54
Song3_Ch1:
	dw Pat_5504

; Unreferenced (4 bytes)
	db $00, $00, $E3, $54
Pat_54E9:
	INSTR 11
	DRUMS $07, DrumPat_550F
	LEN 14
	NOTE F_, 3
	NOTE F_, 3
	NOTE Gsh, 3
	LEN 7
	NOTE Ash, 3
	LEN 30
	NOTE F_, 3
	DRUMS_OFF
	END
Pat_54F8:
	INSTR 2
	LEN 14
	NOTE F_, 3
	NOTE F_, 3
	INSTR 0
	NOTE A_, 3
	LEN 7
	NOTE A_, 3
	LENGTH $80
	NOTE A_, 3
	END
Pat_5504:
	INSTR 9
	LEN 14
	NOTE F_, 3
	NOTE F_, 3
	NOTE Gsh, 3
	LEN 7
	NOTE Ash, 3
	LENGTH $80
	NOTE F_, 3
	END
DrumPat_550F:
	db 1, 6, 1, 5, 9, 0, 9, 7
	db 0, 0, 0, 0, 0, 0, 0, 0
	db DRUM_LOOP

; Unreferenced (1 bytes)
	db $FF

; Song 4: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong4:
	call StopAll
	ld a, HIGH(InstrTable1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable1 - 2)
	ld [wInstrTable], a
	ld de, Song4_Ch3
	call StartMusicCh3
	ld de, Song4_Ch2
	call StartMusicCh2
	ld de, Song4_Ch1
	jp StartMusicCh1

; Unreferenced (1 bytes)
	db $C9
Song4_Ch3:
	dw Pat_5565
	dw Pat_5565
	dw Pat_55A2
	dw Pat_55A2
	ORDER_LOOP Song4_Ch3
Song4_Ch2:
	dw Pat_55DD
	dw Pat_55DD
	dw Pat_5628
	dw Pat_5628
	ORDER_LOOP Song4_Ch2
Song4_Ch1:
	dw Pat_566F
	dw Pat_566F
	dw Pat_569F
	dw Pat_569F
	ORDER_LOOP Song4_Ch1
Pat_5565:
	INSTR 11
	CH_TRANSPOSE $0C
	LEN 7
	NOTE Ash, 2
	NOTE B_, 2
	LEN 14
	NOTE C_, 3
	LEN 7
	NOTE C_, 3
	LEN 14
	NOTE C_, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	LEN 21
	NOTE Dsh, 2
	LEN 28
	NOTE F_, 2
	LEN 14
	NOTE C_, 3
	LEN 7
	NOTE C_, 3
	LEN 14
	NOTE C_, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 2
	LEN 14
	NOTE F_, 2
	NOTE G_, 2
	LEN 7
	NOTE Ash, 2
	NOTE B_, 2
	LEN 14
	NOTE C_, 3
	LEN 7
	NOTE C_, 3
	LEN 14
	NOTE C_, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	LEN 21
	NOTE Dsh, 2
	LEN 28
	NOTE F_, 2
	LEN 14
	NOTE C_, 3
	LEN 7
	NOTE C_, 3
	LEN 14
	NOTE C_, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 2
	NOTE F_, 2
	NOTE G_, 2
	LEN 14
	NOTE F_, 2
	NEXT
Pat_55A2:
	INSTR 11
	LEN 7
	NOTE Csh, 3
	NOTE D_, 3
	LEN 14
	NOTE Dsh, 3
	LEN 7
	NOTE Dsh, 3
	LEN 14
	NOTE Dsh, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN 21
	NOTE G_, 2
	LEN 28
	NOTE Ash, 2
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE F_, 2
	NOTE A_, 2
	NOTE A_, 2
	LEN 7
	NOTE A_, 2
	NOTE Ash, 2
	NOTE B_, 2
	LEN 14
	NOTE C_, 3
	LEN 7
	NOTE Csh, 3
	NOTE D_, 3
	LEN 14
	NOTE Dsh, 3
	LEN 7
	NOTE Dsh, 3
	LEN 14
	NOTE Dsh, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN 21
	NOTE G_, 2
	LEN 28
	NOTE Ash, 2
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE F_, 3
	LEN 14
	NOTE F_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE Ash, 2
	LEN 7
	NOTE Ash, 2
	LEN 14
	NOTE C_, 3
	NEXT
Pat_55DD:
	LEN 7
	WAIT
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE A_, 3
	DRUMS $07, DrumPat_56D2
	INSTR 2
	LEN 14
	NOTE G_, 3
	INSTR 5
	NOTE C_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 5
	NOTE C_, 4
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 0
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 2
	NOTE G_, 3
	INSTR 5
	NOTE C_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 5
	NOTE C_, 4
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 2
	NOTE G_, 3
	INSTR 5
	NOTE C_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 5
	NOTE C_, 4
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 0
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 2
	NOTE G_, 3
	INSTR 5
	NOTE C_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 5
	NOTE C_, 4
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 0
	LEN 7
	NOTE A_, 3
	NEXT
Pat_5628:
	LEN 7
	WAIT
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 2
	LEN 14
	NOTE G_, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 0
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 0
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 0
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 0
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 2
	NOTE G_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 0
	LEN 7
	NOTE A_, 3
	NEXT
Pat_566F:
	VIBRATO $0A, $01, $04
	RELEASE $02, $21
	CH_TRANSPOSE $0C
	INSTR 6
	DUTY_75
	LEN 7
	NOTE Ash, 3
	NOTE B_, 3
	LENGTH $70
	NOTE C_, 4
	LENGTH $3F
	NOTE G_, 3
	LEN 28
	NOTE F_, 3
	LEN 21
	NOTE Ash, 3
	LENGTH $70
	NOTE G_, 3
	INSTR 9
	CH_TRANSPOSE $00
	RELEASE $01, $21
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE C_, 3
	NOTE Dsh, 3
	NOTE Dsh, 3
	LEN 7
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE G_, 3
	LEN 14
	NOTE F_, 3
	NEXT
Pat_569F:
	LEN 35
	WAIT
	INSTR 15
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 7
	NOTE F_, 4
	LEN 21
	NOTE G_, 4
	LEN 14
	NOTE Ash, 4
	NOTE A_, 4
	LEN 7
	NOTE Ash, 4
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE G_, 4
	LEN 28
	NOTE F_, 4
	LEN 14
	NOTE A_, 3
	NOTE C_, 4
	NOTE F_, 4
	LEN 21
	NOTE Dsh, 4
	NOTE D_, 4
	LEN 28
	NOTE Ash, 3
	LEN 14
	NOTE Ash, 3
	LEN 7
	NOTE Ash, 3
	NOTE C_, 4
	NOTE D_, 4
	LEN 21
	NOTE C_, 4
	INSTR 9
	LEN 14
	NOTE F_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE Ash, 3
	LEN 7
	NOTE Ash, 3
	LEN 14
	NOTE C_, 4
	NEXT
DrumPat_56D2:
	db DRUM_REPEAT + 7, 1, 6, 5, 6, 9, 6, 6
	db 5, DRUM_REPEAT_END, 1, 6, 5, 6, 9, 6
	db 1, 9, DRUM_LOOP

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
	dw Pat_570C

; Unreferenced (4 bytes)
	db $00, $00, $FA, $56
Song5_Ch2:
	dw Pat_5736

; Unreferenced (4 bytes)
	db $00, $00, $00, $57
Song5_Ch1:
	dw Pat_5774

; Unreferenced (4 bytes)
	db $00, $00, $06, $57
Pat_570C:
	CH_TRANSPOSE $0C
	DRUMS $07, DrumPat_5799
	INSTR 11
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE F_, 2
	LENGTH $3F
	NOTE G_, 2
	LEN 7
	NOTE F_, 2
	LEN 14
	NOTE G_, 2
	NOTE Ash, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE F_, 3
	LEN 7
	NOTE Fsh, 3
	LEN 14
	NOTE G_, 3
	NOTE F_, 2
	LEN 7
	RELEASE $00
	VOLENV 15, $11, $1F, $13
	NOTE G_, 2
	DRUMS_OFF
	LENGTH $D9
	WAIT
	END
Pat_5736:
	INSTR 2
	LEN 7
	NOTE F_, 3
	INSTR 9
	NOTE F_, 3
	LEN 14
	NOTE G_, 3
	INSTR 0
	LEN 7
	NOTE A_, 3
	INSTR 9
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE G_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 0
	LEN 3
	NOTE D_, 4
	LEN 4
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE G_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 9
	NOTE F_, 3
	LEN 14
	NOTE G_, 3
	INSTR 0
	LEN 7
	NOTE A_, 3
	INSTR 9
	LEN 14
	NOTE C_, 4
	INSTR 2
	LEN 7
	NOTE F_, 3
	NOTE F_, 3
	INSTR 9
	NOTE F_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 9
	NOTE Fsh, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE G_, 4
	INSTR 0
	NOTE A_, 3
	NOTE A_, 3
	LENGTH $E0
	NOTE A_, 3
	END
Pat_5774:
	RELEASE $04, $51
	INSTR 4
	LEN 14
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	LEN 7
	NOTE Ash, 3
	LEN 14
	NOTE C_, 4
	NOTE C_, 4
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE C_, 4
	NOTE C_, 4
	LENGTH $E0
	RELEASE $00
	NOTE G_, 4
	END
DrumPat_5799:
	db 1, 6, 6, 6, 9, 6, 6, 6
	db 1, 9, 9, 9, 9, 9, 9, 9
	db 1, 6, 6, 6, 9, 6, 6, 1
	db 1, 6, 1, 6, 9, 6, 9, 9
	db 7, DRUM_LOOP

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
	dw Pat_57E8
	dw Pat_5828

; Unreferenced (4 bytes)
	db $00, $00, $D0, $57
Song6_Ch2:
	dw Pat_582E
	dw Pat_5883

; Unreferenced (4 bytes)
	db $00, $00, $D8, $57
Song6_Ch1:
	dw Pat_588A
	dw Pat_58BE

; Unreferenced (4 bytes)
	db $00, $00, $E0, $57
Pat_57E8:
	CH_TRANSPOSE $0C
	INSTR 11
	LEN 7
	NOTE C_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	LEN 14
	NOTE D_, 2
	NOTE D_, 2
	LEN 7
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	LEN 14
	NOTE D_, 2
	NOTE D_, 2
	LEN 7
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	LEN 14
	NOTE C_, 3
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE C_, 2
	LEN 7
	NOTE C_, 2
	LEN 14
	NOTE D_, 2
	NOTE D_, 3
	NOTE C_, 3
	NOTE A_, 2
	LEN 7
	NOTE G_, 2
	LEN 14
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 2
	NEXT
Pat_5828:
	INSTR 11
	LENGTH $E0
	NOTE D_, 2
	WAIT
	END
Pat_582E:
	INSTR 9
	LEN 7
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	LEN 14
	NOTE D_, 4
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE D_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	LEN 14
	NOTE D_, 4
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	LEN 14
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 4
	LEN 7
	NOTE F_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE G_, 4
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE D_, 5
	INSTR 0
	NOTE A_, 3
	INSTR 9
	LEN 14
	NOTE C_, 5
	NOTE A_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE F_, 4
	INSTR 0
	NOTE A_, 3
	LEN 7
	NOTE A_, 3
	NOTE A_, 3
	NEXT
Pat_5883:
	INSTR 9
	NOTE D_, 3
	DRUMS_OFF
	LENGTH $E0
	WAIT
	END
Pat_588A:
	DRUMS $07, DrumPat_58C1
	TRANSPOSE $FE
	CH_TRANSPOSE $0C
	INSTR 6
	RELEASE $03, $42
	DUTY_75
	LENGTH $69
	NOTE D_, 3
	LEN 7
	NOTE C_, 3
	LENGTH $62
	NOTE D_, 3
	LEN 14
	NOTE C_, 3
	LEN 7
	NOTE C_, 3
	LEN 21
	NOTE D_, 3
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE C_, 4
	NOTE A_, 3
	NOTE G_, 3
	NOTE F_, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE C_, 3
	NOTE D_, 3
	LEN 7
	NOTE D_, 3
	LEN 14
	NOTE D_, 4
	NOTE C_, 4
	NOTE A_, 3
	LEN 7
	NOTE G_, 3
	LEN 14
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NEXT
Pat_58BE:
	LEN 14
	NOTE D_, 4
	END
DrumPat_58C1:
	db 1, 6, 1, 1, 9, 1, 6, 1
	db 6, 1, 1, 1, 9, 1, 1, 1
	db 1, 6, 1, 1, 9, 1, 6, 1
	db 6, 1, 1, 1, 9, 1, 1, 9
	db 1, 6, 1, 1, 9, 1, 6, 1
	db 6, 1, 1, 1, 9, 1, 1, 1
	db 1, 6, 1, 1, 9, 1, 6, 1
	db 6, 1, 1, 1, 9, 0, 9, 9
	db 7, 0, DRUM_LOOP

; Unreferenced (1 bytes)
	db $FF

; Song 7: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong7:
	call StopAll
	ld a, HIGH(InstrTable1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable1 - 2)
	ld [wInstrTable], a
	ld de, Song7_Ch3
	call StartMusicCh3
	ld de, Song7_Ch2
	call StartMusicCh2
	ld de, Song7_Ch1
	jp StartMusicCh1

; Unreferenced (1 bytes)
	db $C9
Song7_Ch3:
	dw Pat_5949
	dw Pat_5997
	dw Pat_5997
	ORDER_LOOP Song7_Ch3
Song7_Ch2:
	dw Pat_59E4
	dw Pat_5A3E
	dw Pat_5A4D
	dw Pat_5A74
	dw Pat_5A4D
	dw Pat_5A74
	ORDER_LOOP Song7_Ch2
Song7_Ch1:
	dw Pat_5AD6
	dw Pat_5B0F
	dw Pat_5B0F
	ORDER_LOOP Song7_Ch1
Pat_5949:
	CH_TRANSPOSE $0C
	INSTR 11
	LEN 10
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	LEN 20
	NOTE Ash, 2
	LEN 10
	NOTE Ash, 2
	NOTE Ash, 1
	NOTE Ash, 2
	NOTE Ash, 1
	NOTE Ash, 2
	NOTE Ash, 1
	NOTE Ash, 2
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	LEN 20
	NOTE G_, 2
	NOTE A_, 2
	NOTE Ash, 2
	NOTE B_, 2
	LEN 10
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	LEN 20
	NOTE Ash, 2
	LEN 10
	NOTE Ash, 2
	NOTE Ash, 1
	NOTE Ash, 2
	NOTE Ash, 1
	NOTE Ash, 2
	NOTE Ash, 1
	NOTE Ash, 2
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	LEN 20
	NOTE G_, 2
	LEN 10
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE F_, 3
	NOTE D_, 3
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE F_, 3
	NOTE G_, 3
	NOTE D_, 3
	NOTE F_, 3
	NEXT
Pat_5997:
	LEN 10
	REPEAT 8
	NOTE C_, 2
	NOTE C_, 3
	REPEAT_END
	REPEAT 8
	NOTE G_, 2
	NOTE G_, 3
	REPEAT_END
	REPEAT 8
	NOTE C_, 2
	NOTE C_, 3
	REPEAT_END
	REPEAT 8
	NOTE G_, 2
	NOTE G_, 3
	REPEAT_END
	REPEAT 7
	NOTE F_, 2
	NOTE F_, 3
	REPEAT_END
	NOTE F_, 2
	LEN 20
	NOTE G_, 2
	LEN 10
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	LEN 20
	NOTE B_, 2
	LEN 10
	NOTE C_, 3
	NOTE G_, 2
	LEN 20
	NOTE C_, 3
	LEN 10
	NOTE B_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 2
	LEN 20
	NOTE G_, 2
	LEN 10
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE F_, 3
	NOTE E_, 3
	NOTE G_, 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE G_, 2
	LEN 20
	NOTE C_, 3
	LEN 10
	NOTE B_, 2
	NOTE G_, 2
	NOTE D_, 2
	NEXT
Pat_59E4:
	DRUMS $0A, DrumPat_5B8C
	INSTR 9
	LEN 10
	REPEAT 2
	NOTE C_, 4
	NOTE C_, 5
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 5
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE C_, 5
	REPEAT_END
	NOTE C_, 4
	NOTE C_, 5
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 5
	INSTR 0
	NOTE A_, 3
	INSTR 9
	LEN 20
	NOTE D_, 4
	INSTR 0
	NOTE A_, 3
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	INSTR 9
	NOTE C_, 4
	NOTE C_, 5
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 5
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 5
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE C_, 5
	NOTE C_, 4
	NOTE D_, 5
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE D_, 5
	NOTE C_, 4
	NOTE C_, 5
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE C_, 5
	NOTE C_, 4
	NOTE A_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE A_, 4
	NOTE G_, 3
	NOTE G_, 4
	INSTR 0
	NOTE A_, 3
	NOTE A_, 3
	INSTR 9
	NOTE G_, 4
	NOTE G_, 3
	INSTR 0
	NOTE A_, 3
	INSTR 9
	NOTE G_, 4
	NEXT
Pat_5A3E:
	INSTR 9
	LEN 10
	NOTE G_, 3
	NOTE G_, 4
	INSTR 0
	NOTE A_, 3
	NOTE A_, 3
	INSTR 9
	NOTE G_, 4
	INSTR 0
	LEN 20
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	NEXT
Pat_5A4D:
	DRUMS $0A, DrumPat_5BC1
	LEN 20
	PAT_CALL Pat_5A55
Pat_5A55:
	REPEAT 2
	INSTR 4
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
	LEN 20
	NOTE A_, 3
	REPEAT_END
	REPEAT 2
	INSTR 5
	NOTE G_, 4
	INSTR 0
	LEN 10
	NOTE A_, 3
	INSTR 5
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	INSTR 0
	LEN 20
	NOTE A_, 3
	REPEAT_END
	NEXT
Pat_5A74:
	REPEAT 2
	INSTR 4
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
	LEN 20
	NOTE A_, 3
	REPEAT_END
	INSTR 4
	NOTE G_, 4
	INSTR 0
	LEN 10
	NOTE A_, 3
	INSTR 4
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 4
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 4
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 4
	NOTE G_, 4
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
	LEN 20
	NOTE A_, 3
	INSTR 4
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
	LEN 30
	NOTE G_, 4
	DRUMS $0A, DrumPat_5BCA
	INSTR 0
	LEN 20
	NOTE A_, 3
	INSTR 4
	LEN 10
	NOTE G_, 4
	INSTR 0
	LEN 30
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	NOTE A_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE A_, 3
	NOTE A_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE A_, 3
	NOTE A_, 3
	NEXT
Pat_5AD6:
	VIBRATO $0A, $02, $04
	RELEASE $00
	GLIDE_OFF
	DUTY_75
	HWENV $F2, $0A, $97
	ARP 4
	LENGTH $46
	NOTE C_, 5
	LENGTH $5A
	NOTE Ash, 4
	LENGTH $46
	NOTE F_, 4
	LEN 20
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 30
	NOTE B_, 4
	LENGTH $46
	NOTE C_, 5
	LENGTH $5A
	NOTE Ash, 4
	LENGTH $46
	NOTE F_, 4
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	LEN 20
	NOTE G_, 4
	NOTE G_, 4
	LEN 10
	NOTE F_, 4
	LEN 30
	NOTE G_, 4
	INSTR 3
	LEN 10
	NOTE D_, 4
	LEN 20
	NOTE D_, 4
	NOTE B_, 3
	LEN 10
	NOTE A_, 3
	NEXT
Pat_5B0F:
	INSTR 13
	LEN 10
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	LENGTH $32
	NOTE G_, 4
	LEN 10
	WAIT2
	INSTR 15
	LEN 20
	NOTE C_, 5
	NOTE B_, 4
	LEN 30
	NOTE G_, 4
	INSTR 13
	LEN 10
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	LENGTH $32
	NOTE G_, 4
	LEN 10
	WAIT2
	INSTR 15
	LEN 20
	NOTE Ash, 4
	NOTE A_, 4
	NOTE F_, 4
	LEN 10
	NOTE G_, 4
	INSTR 13
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	LENGTH $32
	NOTE G_, 4
	LEN 10
	WAIT2
	LEN 20
	NOTE E_, 4
	LEN 10
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE A_, 4
	NOTE G_, 4
	WAIT2
	NOTE F_, 4
	NOTE E_, 4
	LENGTH $32
	NOTE D_, 4
	LEN 10
	WAIT2
	NOTE E_, 4
	NOTE F_, 4
	LENGTH $50
	NOTE C_, 4
	LEN 10
	WAIT2
	INSTR 13
	LEN 30
	NOTE D_, 4
	LEN 10
	WAIT2
	LEN 30
	NOTE E_, 4
	LEN 10
	WAIT2
	LENGTH $46
	NOTE D_, 4
	LEN 10
	WAIT2
	LEN 10
	NOTE D_, 5
	LEN 20
	NOTE C_, 5
	NOTE B_, 4
	LEN 10
	NOTE A_, 4
	NOTE C_, 5
	LENGTH $32
	NOTE A_, 4
	LEN 10
	WAIT2
	NOTE F_, 4
	NOTE C_, 5
	NOTE F_, 5
	WAIT2
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	LENGTH $50
	NOTE D_, 5
	LEN 10
	WAIT2
	INSTR 3
	LEN 10
	NOTE C_, 4
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE A_, 3
	LEN 20
	NOTE A_, 3
	LEN 10
	NOTE F_, 3
	NOTE F_, 3
	NEXT
DrumPat_5B8C:
	db DRUM_REPEAT + 2, 1, 6, 9, 6, 1, 1, 9
	db 6, DRUM_REPEAT_END, 1, 6, 9, 6, 1, 1
	db 9, 1, 6, 9, 6, 9, 6, 9
	db 9, 9, DRUM_REPEAT + 3, 1, 6, 9, 6, 1
	db 1, 9, 6, DRUM_REPEAT_END, 1, 1, 9, 9
	db 1, 6, 9, 6, 1, 1, 9, 9
	db 6, 9, 6, 9, DRUM_LOOP
DrumPat_5BC1:
	db 1, 6, 9, 6, 1, 1, 9, 6
	db DRUM_LOOP
DrumPat_5BCA:
	db 9, 1, 1, 9, 1, 1, 9, 9
	db 1, 9, 9, 1, 9, 9, DRUM_LOOP

; Song 8: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong8:
	call StopAll
	ld de, Song8_Ch3
	call StartMusicCh3
	ld de, Song8_Ch1
	call StartMusicCh1
	ld de, Song8_Ch2
	jp StartMusicCh2
Song8_Ch3:
	dw Pat_5BF4
Song8_Ch1:
	dw Pat_5C18
Song8_Ch2:
	dw Pat_5C32
Pat_5BF4:
	DRUMS $07, DrumPat_5C50
	CH_TRANSPOSE $0C
	INSTR 11
	LEN 7
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	INSTR 14
	NOTE A_, 3
	INSTR 11
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	INSTR 14
	NOTE A_, 3
	INSTR 11
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	LEN 21
	NOTE C_, 2
	NOTE Csh, 2
	LENGTH $93
	NOTE D_, 2
	DRUMS_OFF
	END
Pat_5C18:
	INSTR 4
	LEN 7
	NOTE D_, 4
	NOTE D_, 4
	LEN 14
	NOTE D_, 4
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE D_, 4
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	NOTE D_, 4
	LEN 21
	NOTE F_, 4
	NOTE E_, 4
	LENGTH $93
	NOTE D_, 4
	END
Pat_5C32:
	HWENV $F2, $00
	DUTY_75
	ARP 0
	VIBRATO $07, $01, $04
	LEN 7
	NOTE D_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	LEN 14
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	LEN 7
	NOTE B_, 4
	LEN 14
	NOTE A_, 4
	NOTE D_, 5
	NOTE A_, 4
	LEN 21
	NOTE C_, 5
	NOTE B_, 4
	LENGTH $93
	NOTE D_, 5
	END
DrumPat_5C50:
	db 1, 1, 1, 6, 9, 6, 1, 1
	db 6, 1, 6, 1, 9, 1, 1, 4
	db 7, 0, 0, 7, 0, 0, 7, DRUM_TEMPO + 48
	db 0, 0, 0, 0, 0, DRUM_LOOP

; Instrument table 1, entries 1..16 (the song routines point 2 bytes before:
; entry 0 is never read)
InstrTable1:
	dw Instr1_0
	dw Instr1_1
	dw Instr1_1
	dw Instr1_3
	dw Instr1_4
	dw Instr1_5
	dw Instr1_6
	dw Instr1_7
	dw Instr1_7
	dw Instr1_7
	dw Instr1_10
	dw Instr1_10
	dw Instr1_12
	dw Instr1_12
	dw Instr1_14
	dw Instr1_15
Instr1_0:
	HWENV $F1, $03, $62
	ARP_OFF
	AUTODUTY $00
	DUTY_50
	GLIDE $FF
	END
Instr1_1:
	HWENV $F1, $04, $32
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
	HWENV $C1, $04, $63
	ARP 4
	DUTY_75
	END
Instr1_5:
	HWENV $C1, $04, $63
	ARP 5
	DUTY_75
	END
Instr1_6:
	HWENV $E2, $19, $30
	ARP 1
	DUTY_50
	END
Instr1_7:
	HWENV $C1, $02, $63
	DUTY_12
	ARP 0
	END
Instr1_10:
	VOLENV 15, $11, $1F, $13
	ARP 0
	RELEASE $02, $11
	WAVE Wave_5E37
	ARP 0
	END
Instr1_12:
	HWENV $D2, $05, $70
	DUTY_75
	ARP_OFF
	RELEASE $02, $53
	END
Instr1_14:
	VOLENV 15, $0B, $1F, $11
	GLIDE $FE
	WAVE Wave_5E47
	END
Instr1_15:
	HWENV $C2, $0E, $30
	DUTY_50
	ARP_OFF
	END
ArpTable:
	dw Arp0
	dw Arp1
	dw Arp2
	dw Arp3
	dw Arp4
	dw Arp5

; Unreferenced (44 bytes)
	db $55, $5D, $58, $5D, $62, $5D, $6A, $5D, $6E, $5D, $78, $5D, $87, $5D, $8D, $5D
	db $98, $5D, $9F, $5D, $AA, $5D, $C1, $5D, $C5, $5D, $C9, $5D, $DC, $5D, $DC, $5D
	db $DC, $5D, $DC, $5D, $E0, $5D, $E0, $5D, $E0, $5D, $E0, $5D
Arp0:
	db $0C, $00, ARP_HOLD
Arp3:
	db $00, $00, $01, $01, $02, ARP_HOLD
Arp2:
	db $07, $0C, $03, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, ARP_LOOP
Arp1:
	db $00, $00, $0C, $0C, ARP_LOOP
Arp4:
	db $00, $00, $00, $04, $04, $07, $07, ARP_LOOP
Arp5:
	db $00, $00, $00, $03, $03, $07, $07, ARP_LOOP

; Unreferenced (139 bytes)
	db $0C, $00, $FF, $0C, $00, $00, $00, $00, $00, $00, $00, $00, $6A, $01, $00, $02
	db $01, $03, $01, $00, $6A, $0C, $0C, $00, $FF, $0C, $00, $00, $00, $00, $00, $00
	db $00, $0C, $FF, $0C, $00, $00, $00, $00, $00, $00, $0C, $0C, $0C, $0C, $0C, $0C
	db $0C, $FF, $00, $01, $02, $01, $00, $FF, $0C, $00, $00, $00, $00, $00, $00, $00
	db $00, $0C, $FF, $22, $04, $03, $02, $01, $00, $FF, $02, $FC, $FA, $F8, $F5, $F2
	db $F0, $EC, $EA, $E6, $FF, $0C, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $6A, $18, $0C, $0C, $6A
	db $03, $00, $07, $6A, $07, $0C, $03, $00, $00, $00, $00, $00, $00, $07, $0C, $03
	db $00, $00, $00, $00, $00, $00, $FF, $18, $0C
SfxTable_m2:
	db $00, $FF

; SFX table (indexed from 2 bytes before: id 1 is the first entry)
SfxTable:
	dw Sfx01
	dw Sfx02

; Sound effect 1
Sfx01:
	VOLENV 15, $11, $1F, $12
	WAVE Wave_5E07
	LEN 5
	NOTE Csh, 6
	END

; Sound effect 2
Sfx02:
	WAVE Wave_5E07
	VOLENV 15, $11, $1F, $1F
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
Wave_5E07:
	db $00, $46, $8A, $FF, $FF, $A8, $64, $00
	db $00, $46, $8A, $FF, $FF, $A8, $64, $00

; Unreferenced (32 bytes)
	db $00, $00, $00, $00, $00, $00, $FF, $FF, $00, $00, $00, $00, $00, $00, $FF, $FF
	db $00, $00, $00, $00, $00, $00, $FF, $00, $00, $00, $00, $00, $00, $00, $FF, $00
Wave_5E37:
	db $EC, $96, $31, $90, $00, $00, $00, $00
	db $24, $69, $CE, $FF, $FF, $FF, $FF, $FF
Wave_5E47:
	db $63, $10, $40, $20, $00, $00, $01, $36
	db $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9
Noise43_5E57:
	db $20, $10, $FF
Noise42_5E5A:
	db $A0, $61
Noise43_5E5C:
	db $06, $04, $03, $03, $07, $FF
Noise42_5E62:
	db $F0, $C0, $80, $60, $57
Noise43_5E67:
	db $00, $01, $01, $01, $01, $FF
Noise42_5E6D:
	db $91, $61, $FF, $FF, $FF
Noise43_5E72:
	db $00, $01, $01, $01, $01, $FF
Noise42_5E78:
	db $C1, $A1, $FF, $FF, $FF
Noise43_5E7D:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_5E85:
	db $70, $40, $40, $40, $40, $43, $FF
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5E57)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5E57)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5E5A)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5E5A)
	ld [wNoise42], a
	ret
Drum8:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5EC6)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5EC6)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5ECC)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5ECC)
	ld [wNoise42], a
	ret
Noise43_5EC6:
	db $04, $02, $01, $00, $00, $FF
Noise42_5ECC:
	db $30, $40, $60, $43, $42
Drum2:
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
Noise43_5EEE:
	db $60, $52, $42, $41, $22, $11, $04, $FF
Noise42_5EF6:
	db $F0, $F0, $F0, $A0, $70, $40, $51
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5E7D)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5E7D)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5E85)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5E85)
	ld [wNoise42], a
	ret
Drum5:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5E72)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5E72)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5E78)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5E78)
	ld [wNoise42], a
	ret
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5E67)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5E67)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5E6D)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5E6D)
	ld [wNoise42], a
	ret
Drum7:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5E5C)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5E5C)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5E62)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5E62)
	ld [wNoise42], a
	ret
Drum9:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5FAB)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5FAB)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5FAE)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5FAE)
	ld [wNoise42], a
	ret

; Unreferenced (29 bytes)
	db $AF, $EA, $5B, $DB, $3C, $EA, $5C, $DB, $3E, $5F, $EA, $57, $DB, $3E, $B0, $EA
	db $58, $DB, $3E, $5F, $EA, $59, $DB, $3E, $B2, $EA, $5A, $DB, $C9
Noise43_5FAB:
	db $31, $12, $FF
Noise42_5FAE:
	db $A0, $62

; Unreferenced (24 bytes)
	db $12, $FF, $F1, $51, $32, $32, $32, $32, $51, $32, $FF, $80, $FF, $FF, $FF, $FF
	db $FF, $FF, $51, $FF, $FF, $FF, $80, $51
FadeOutTable:
	db $77, $66, $55, $44, $33, $22, $11, $00
	db $80, FADE_END
FadeInTable:
	db $00, $11, $22, $33, $44, $55, $66, $77
	db FADE_END

; Unreferenced (8229 bytes)
	db $52, $4E, $43, $02, $00, $00, $09, $90, $00, $00, $06, $6C, $C7, $7C, $95, $BC
	db $04, $01, $0F, $FF, $00, $06, $2E, $01, $2F, $30, $1F, $70, $3F, $D0, $60, $6F
	db $C0, $98, $C7, $93, $CF, $96, $CF, $94, $CF, $FF, $14, $A5, $02, $38, $09, $05
	db $40, $00, $FF, $22, $40, $C0, $7F, $7F, $FF, $80, $E1, $0D, $7F, $80, $07, $15
	db $25, $A8, $02, $1D, $02, $6E, $F3, $07, $0F, $FF, $C7, $07, $0F, $DD, $22, $8F
	db $06, $0F, $A9, $56, $06, $1E, $0F, $10, $EF, $04, $0F, $0C, $03, $FE, $02, $FE
	db $03, $FE, $3C, $FF, $01, $01, $1F, $95, $49, $6A, $89, $02, $05, $F4, $F8, $E3
	db $0E, $FC, $FB, $06, $16, $E3, $0D, $F3, $C5, $FB, $65, $FB, $25, $FB, $94, $CF
	db $EE, $06, $01, $00, $A1, $00, $E3, $1C, $C9, $26, $D3, $2A, $09, $C7, $32, $EF
	db $1C, $3C, $E3, $04, $0F, $21, $04, $FF, $A5, $7B, $A1, $7F, $24, $03, $01, $04
	db $D9, $FE, $A9, $DE, $89, $D0, $01, $09, $1E, $DF, $3F, $D1, $01, $01, $35, $D5
	db $3B, $03, $92, $17, $6B, $05, $03, $24, $17, $05, $D0, $03, $13, $92, $19, $48
	db $07, $49, $13, $19, $21, $07, $A9, $DE, $E9, $06, $01, $3D, $17, $02, $01, $33
	db $37, $FE, $D0, $04, $07, $05, $93, $03, $26, $01, $D1, $27, $4D, $D1, $05, $25
	db $15, $9A, $1D, $01, $47, $19, $D1, $A4, $01, $05, $15, $B0, $01, $F9, $FE, $B2
	db $17, $40, $21, $DB, $3F, $DD, $86, $0C, $A5, $DE, $84, $FF, $01, $A4, $48, $DF
	db $03, $B3, $1E, $61, $A5, $73, $04, $01, $F8, $01, $19, $01, $01, $FD, $03, $FE
	db $03, $FB, $06, $80, $09, $DF, $20, $FF, $40, $FD, $83, $E0, $09, $04, $F7, $0C
	db $60, $FF, $01, $01, $D6, $3B, $B7, $02, $6E, $DD, $66, $F7, $CC, $FF, $45, $01
	db $80, $C3, $FF, $58, $FF, $34, $FF, $63, $FF, $66, $5F, $E6, $FD, $C6, $96, $15
	db $38, $3F, $80, $01, $B0, $35, $FF, $C8, $63, $C6, $A6, $DF, $A3, $DF, $B0, $CF
	db $68, $C7, $DF, $60, $70, $3F, $2F, $1F, $7F, $80, $D8, $C9, $A8, $57, $86, $09
	db $08, $D9, $11, $28, $7F, $D1, $65, $04, $01, $FF, $E1, $7E, $FF, $37, $44, $8F
	db $04, $0F, $02, $FD, $06, $1E, $0F, $25, $DA, $06, $0F, $3D, $6E, $91, $06, $0F
	db $27, $07, $9E, $02, $0F, $76, $07, $0F, $4C, $A4, $0F, $FE, $37, $01, $01, $05
	db $41, $73, $44, $02, $9F, $F0, $FF, $02, $13, $BB, $2E, $27, $25, $3A, $F3, $65
	db $F3, $C5, $F3, $15, $E3, $0A, $07, $F3, $0E, $0E, $FC, $F4, $F8, $01, $15, $03
	db $00, $18, $18, $24, $5C, $2F, $71, $05, $12, $C8, $37, $F8, $FF, $E3, $FC, $CE
	db $F0, $98, $E0, $90, $E0, $A0, $C0, $01, $80, $C0, $B0, $33, $4F, $AB, $00, $05
	db $24, $00, $02, $27, $00, $00, $0A, $FF, $A1, $5F, $D4, $2B, $7A, $18, $05, $AD
	db $02, $EE, $0B, $00, $B8, $60, $15, $00, $BF, $FF, $57, $FF, $2A, $FF, $85, $7F
	db $42, $BF, $17, $D0, $2F, $A9, $57, $07, $FB, $FF, $F1, $FF, $F5, $40, $C9, $AD
	db $F3, $69, $38, $F3, $A9, $03, $80, $E6, $33, $3B, $00, $20, $19, $55, $20, $A0
	db $40, $69, $90, $26, $36, $C9, $46, $C0, $00, $80, $14, $88, $60, $90, $3D, $06
	db $F8, $01, $0F, $44, $00, $D1, $D4, $07, $95, $04, $01, $04, $00, $4A, $25, $17
	db $09, $20, $09, $C0, $50, $22, $29, $14, $04, $18, $64, $9A, $40, $BF, $80, $80
	db $3D, $88, $40, $00, $50, $A4, $50, $3D, $09, $F6, $06, $3F, $C3, $E2, $06, $FD
	db $8E, $01, $FF, $07, $01, $FB, $07, $FF, $03, $4C, $74, $60, $E3, $0C, $FE, $0D
	db $FF, $60, $05, $0D, $BB, $C7, $FD, $FE, $96, $E5, $00, $FE, $D5, $7F, $F7, $FB
	db $3F, $DF, $E0, $ED, $18, $C0, $0D, $7F, $CC, $EF, $DD, $03, $FD, $77, $B3, $FF
	db $FD, $03, $A1, $1D, $E8, $70, $FD, $BE, $EF, $9F, $7F, $88, $FF, $11, $EB, $34
	db $DD, $E3, $B6, $FB, $60, $7F, $29, $10, $FF, $08, $FF, $5A, $F0, $02, $0D, $87
	db $00, $B7, $34, $89, $01, $3C, $00, $0F, $F0, $00, $F6, $06, $E4, $0F, $0E, $ED
	db $0D, $C9, $1F, $23, $41, $00, $03, $83, $AE, $80, $CE, $80, $7E, $53, $07, $1D
	db $5C, $05, $73, $11, $01, $50, $D6, $D0, $D7, $90, $D3, $5C, $D5, $9F, $00, $1F
	db $00, $3F, $00, $C6, $7F, $02, $05, $80, $3F, $A0, $0E, $D0, $A3, $8F, $80, $4F
	db $87, $04, $07, $24, $07, $12, $54, $07, $A4, $30, $4F, $C3, $01, $1A, $C3, $0A
	db $85, $01, $84, $5F, $F0, $06, $9E, $01, $01, $7F, $01, $B4, $93, $BC, $DB, $98
	db $DB, $9A, $60, $2F, $DB, $1A, $93, $62, $3E, $8F, $27, $7C, $C0, $A1, $F6, $00
	db $FB, $00, $1C, $FC, $00, $EE, $09, $1B, $FD, $00, $F5, $6F, $8F, $05, $FD, $01
	db $BD, $23, $C3, $7F, $80, $EF, $10, $FB, $04, $EE, $01, $C9, $06, $9B, $04, $D0
	db $02, $13, $05, $28, $BF, $40, $0D, $05, $38, $FF, $02, $03, $0A, $B0, $1B, $F3
	db $7B, $02, $F3, $BB, $CC, $7C, $CC, $EC, $C0, $0F, $3F, $0E, $3F, $08, $0B, $FF
	db $91, $FF, $9D, $00, $0F, $F5, $AE, $FF, $AA, $FF, $DD, $3C, $FF, $55, $03, $0F
	db $EA, $0B, $FF, $5D, $FF, $51, $00, $0F, $D7, $BA, $FF, $AB, $FD, $57, $2C, $AF
	db $75, $0F, $61, $DF, $0F, $B2, $DF, $37, $EA, $02, $0F, $0F, $3F, $5C, $FF, $50
	db $01, $97, $6B, $0E, $61, $B3, $11, $FF, $1D, $E0, $01, $0F, $CB, $FF, $A9, $FF
	db $1E, $52, $FF, $92, $03, $2F, $63, $2A, $6D, $EB, $5D, $C0, $01, $1F, $A0, $FF
	db $E0, $7F, $C0, $3F, $FF, $40, $03, $AB, $07, $02, $0A, $01, $77, $F8, $03, $71
	db $EE, $FF, $A8, $FF, $AE, $80, $03, $A8, $AF, $70, $7D, $FE, $CE, $0F, $57, $39
	db $0F, $FB, $75, $87, $07, $F3, $0C, $EE, $66, $B3, $D5, $0F, $71, $AA, $23, $AA
	db $CA, $01, $C0, $09, $FB, $97, $FF, $F4, $9F, $1C, $F6, $FF, $94, $07, $91, $4F
	db $30, $B7, $5D, $39, $40, $03, $60, $9B, $3C, $08, $9B, $3A, $DB, $1A, $01, $01
	db $DA, $1A, $D8, $1E, $CC, $1D, $19, $77, $B6, $D9, $77, $6E, $70, $68, $4C, $FA
	db $DC, $D1, $9C, $F0, $7C, $01, $FD, $01, $4C, $E1, $03, $0C, $01, $72, $C8, $EB
	db $88, $DB, $08, $1B, $92, $B2, $32, $A0, $3C, $A1, $38, $A3, $20, $A7, $20, $6E
	db $61, $4D, $C5, $01, $1E, $D0, $CB, $1C, $D1, $3C, $B1, $28, $B3, $78, $62, $F0
	db $C6, $F0, $86, $E0, $0E, $07, $C4, $07, $A4, $07, $44, $17, $01, $41, $46, $08
	db $43, $C2, $83, $82, $03, $02, $83, $16, $87, $14, $87, $04, $06, $03, $07, $0C
	db $0F, $08, $01, $13, $E0, $0D, $E1, $1D, $01, $C1, $1B, $19, $13, $77, $9A, $74
	db $C8, $1E, $EC, $0D, $ED, $0D, $EF, $0F, $E7, $0F, $F7, $07, $F6, $07, $6F, $68
	db $4F, $F8, $DF, $D0, $9F, $F0, $BF, $A0, $3F, $E0, $7F, $40, $ED, $05, $51, $6F
	db $DB, $ED, $92, $83, $82, $7D, $1F, $00, $E1, $EF, $60, $17, $00, $77, $74, $17
	db $04, $EF, $64, $1F, $08, $00, $11, $A2, $00, $2A, $2A, $1C, $A2, $22, $BB, $03
	db $20, $FF, $2E, $0F, $23, $0D, $00, $AB, $AA, $23, $0F, $C2, $03, $FF, $EE, $00
	db $0F, $D3, $00, $D5, $14, $D5, $40, $15, $01, $FF, $15, $85, $0F, $C2, $1B, $00
	db $75, $70, $15, $05, $75, $75, $7B, $41, $FF, $42, $0C, $0F, $13, $0F, $74, $06
	db $53, $41, $55, $54, $15, $1D, $AC, $C3, $B6, $01, $00, $50, $00, $16, $16, $56
	db $54, $88, $01, $FF, $54, $17, $0F, $8C, $00, $6C, $BB, $B9, $98, $80, $BE, $B2
	db $89, $80, $FF, $BB, $CF, $00, $CF, $08, $9F, $18, $9F, $10, $3F, $30, $39, $20
	db $03, $03, $FF, $7E, $E1, $00, $F3, $03, $E7, $06, $E7, $04, $CF, $0C, $17, $87
	db $C1, $2B, $3C, $E3, $00, $C9, $90, $1F, $1B, $1F, $01, $33, $20, $07, $06, $FF
	db $7C, $C1, $9B, $2F, $0F, $2F, $0D, $19, $3F, $3C, $3F, $2F, $97, $1F, $7E, $0C
	db $DD, $00, $DD, $11, $89, $01, $89, $09, $23, $23, $33, $22, $01, $FF, $03, $66
	db $C3, $00, $99, $18, $CF, $60, $41, $45, $00, $33, $02, $87, $CC, $2F, $3C, $0F
	db $D9, $18, $18, $99, $11, $01, $31, $31, $20, $33, $23, $3F, $C3, $E0, $4F, $99
	db $19, $83, $1A, $03, $33, $32, $2D, $0C, $0F, $89, $0F, $09, $72, $E3, $71, $18
	db $6F, $01, $FF, $18, $09, $81, $00, $E7, $27, $20, $7D, $95, $FF, $29, $30, $E3
	db $2F, $24, $3F, $03, $4F, $CD, $1F, $EF, $0F, $30, $01, $EE, $01, $0E, $EC, $0F
	db $02, $E1, $01, $FF, $0F, $BF, $A1, $79, $57, $80, $54, $02, $30, $00, $F8, $FB
	db $E0, $03, $D2, $8B, $F0, $C0, $0F, $07, $61, $4D, $70, $46, $76, $70, $C9, $C3
	db $01, $B0, $86, $E0, $17, $21, $87, $E0, $0C, $0D, $40, $9A, $C0, $98, $83, $B7
	db $87, $B4, $07, $6C, $0F, $6F, $F8, $B8, $C6, $03, $42, $03, $82, $02, $02, $C2
	db $CA, $C2, $0A, $C2, $1A, $C2, $02, $FF, $1E, $D3, $3A, $0F, $18, $A2, $A8, $56
	db $00, $BE, $2F, $90, $18, $D3, $83, $36, $03, $80, $30, $82, $BF, $85, $BF, $BA
	db $38, $BF, $95, $47, $47, $2D, $0D, $AD, $02, $00, $21, $61, $FF, $EF, $CF, $77
	db $02, $0D, $01, $FD, $00, $FA, $85, $88, $03, $02, $FA, $8C, $DF, $0F, $70, $03
	db $BB, $00, $BB, $22, $BB, $A2, $3B, $01, $88, $41, $6D, $1F, $F9, $C4, $1B, $F9
	db $89, $1F, $82, $60, $ED, $AE, $2E, $AA, $A8, $0E, $AA, $2A, $A2, $A2, $9E, $01
	db $00, $0F, $A3, $00, $B7, $A6, $37, $24, $B7, $65, $A4, $01, $FF, $54, $6D, $E6
	db $00, $0C, $EA, $08, $E6, $02, $03, $EA, $4A, $0A, $41, $F1, $32, $00, $EE, $E6
	db $62, $8D, $3F, $CA, $26, $3F, $52, $F1, $36, $C6, $1F, $E0, $62, $1F, $1D, $CA
	db $2B, $0A, $32, $D5, $00, $4F, $AE, $A6, $A0, $AE, $AC, $62, $20, $2A, $FF, $4E
	db $BD, $39, $53, $CD, $BF, $A0, $37, $01, $7F, $0F, $47, $7D, $80, $00, $52, $4E
	db $43, $02, $00, $00, $04, $00, $00, $00, $01, $14, $BF, $90, $5E, $53, $04, $01
	db $00, $E8, $E9, $EA, $EB, $EC, $ED, $B0, $00, $EE, $EF, $07, $F0, $F1, $F2, $F3
	db $E7, $8A, $03, $00, $F4, $F5, $04, $06, $38, $39, $3A, $3B, $C7, $11, $F6, $F7
	db $90, $04, $1F, $F8, $04, $00, $2E, $2F, $30, $31, $32, $33, $34, $35, $20, $36
	db $37, $0D, $F9, $F2, $04, $1F, $FA, $00, $04, $4E, $4F, $50, $51, $52, $04, $53
	db $54, $55, $56, $57, $1E, $0D, $FB, $04, $1F, $40, $FC, $04, $6C, $6D, $00, $6E
	db $6F, $70, $71, $72, $73, $74, $75, $83, $0D, $FD, $CE, $04, $1F, $FE, $5C, $03
	db $38, $3C, $3D, $3E, $3F, $40, $41, $42, $43, $44, $45, $46, $47, $0E, $FF, $F7
	db $08, $1F, $BC, $07, $00, $0C, $1F, $09, $0F, $0A, $0B, $0C, $0D, $13, $01, $1F
	db $28, $29, $2A, $2B, $2C, $2D, $E0, $12, $1F, $48, $49, $4A, $4B, $3D, $4C, $4D
	db $12, $1F, $E4, $11, $7F, $00, $00, $04, $58, $59, $5A, $5B, $5C, $5D, $1E, $5E
	db $5F, $60, $0A, $1F, $40, $01, $04, $76, $77, $00, $78, $79, $7A, $7B, $7C, $7D
	db $7E, $7F, $83, $0D, $02, $CF, $04, $1F, $03, $0A, $3C, $5F, $04, $04, $0C, $05
	db $80, $04, $61, $62, $63, $00, $64, $65, $66, $64, $67, $E7, $68, $69, $E3, $0D
	db $06, $C4, $04, $1F, $07, $F6, $03, $05, $65, $62, $65, $6A, $15, $21, $67, $6B
	db $9E, $BF, $08, $04, $1F, $00, $0E, $0F, $10, $11, $12, $13, $14, $15, $98, $00
	db $16, $17, $1E, $18, $19, $1A, $04, $1F, $00, $1B, $1C, $1D, $1E, $1F, $20, $21
	db $22, $31, $23, $27, $00, $24, $25, $47, $0C, $26, $BD, $0A, $92, $F7, $00, $EF
	db $B3, $00, $00, $00, $52, $4E, $43, $02, $00, $00, $00, $99, $00, $00, $00, $1D
	db $7C, $F5, $A5, $1C, $04, $01, $1E, $00, $2B, $00, $20, $01, $02, $00, $01, $92
	db $00, $47, $12, $05, $BD, $08, $00, $07, $32, $EF, $03, $18, $09, $7B, $2A, $0E
	db $00, $C0, $00, $52, $4E, $43, $02, $00, $00, $03, $C0, $00, $00, $02, $00, $D5
	db $3E, $C6, $48, $03, $01, $0F, $FF, $00, $06, $2E, $01, $2F, $30, $1F, $70, $3F
	db $D0, $60, $6F, $C0, $98, $C7, $93, $CF, $96, $CF, $94, $CF, $FF, $14, $A5, $02
	db $38, $09, $05, $40, $00, $FF, $22, $40, $C0, $7F, $7F, $FF, $80, $E1, $0D, $7F
	db $80, $07, $15, $25, $A8, $02, $1D, $02, $6E, $F3, $07, $0F, $FF, $C7, $07, $0F
	db $DD, $22, $8F, $06, $0F, $A9, $56, $06, $1E, $0F, $10, $EF, $04, $0F, $0C, $03
	db $FE, $02, $FE, $03, $FE, $3C, $FF, $01, $01, $1F, $95, $49, $6A, $89, $02, $05
	db $F4, $F8, $E3, $0E, $FC, $FB, $06, $16, $E3, $0D, $F3, $C5, $FB, $65, $FB, $25
	db $FB, $94, $CF, $EE, $06, $01, $00, $A1, $00, $E3, $1C, $C9, $26, $D3, $2A, $09
	db $C7, $32, $EF, $1C, $3C, $E3, $04, $0F, $21, $04, $FF, $A5, $7B, $A1, $7F, $24
	db $03, $01, $04, $D9, $FE, $A9, $DE, $89, $D0, $01, $09, $1E, $DF, $3F, $D1, $01
	db $01, $35, $D5, $3B, $03, $92, $17, $6B, $05, $03, $24, $17, $05, $D0, $03, $13
	db $92, $19, $48, $07, $49, $13, $19, $21, $07, $A9, $DE, $E9, $06, $01, $3D, $17
	db $02, $01, $33, $37, $FE, $D0, $04, $07, $05, $93, $03, $26, $01, $D1, $27, $4D
	db $D1, $05, $25, $15, $9A, $1D, $01, $47, $19, $D1, $A4, $01, $05, $15, $B0, $01
	db $F9, $FE, $B2, $17, $40, $21, $DB, $3F, $DD, $86, $0C, $A5, $DE, $84, $FF, $01
	db $A4, $48, $DF, $03, $B3, $1E, $61, $A5, $73, $04, $01, $D7, $13, $1B, $A6, $DF
	db $A3, $DF, $B0, $CF, $68, $C7, $DF, $60, $70, $3F, $2F, $1F, $7F, $80, $62, $79
	db $A8, $57, $1B, $09, $08, $0E, $11, $80, $FF, $7F, $88, $15, $27, $01, $FF, $09
	db $2E, $FF, $C7, $4E, $8F, $04, $0F, $02, $FD, $06, $1E, $0F, $25, $DA, $06, $0F
	db $3D, $6E, $91, $06, $0F, $27, $07, $9E, $02, $0F, $76, $07, $0F, $4C, $A4, $0F
	db $FE, $37, $01, $01, $05, $40, $23, $44, $02, $03, $3E, $FE, $FF, $02, $26, $6B
	db $27, $5C, $25, $74, $F3, $65, $F3, $C5, $F3, $15, $E3, $0A, $07, $F3, $0E, $0E
	db $FC, $F4, $F8, $01, $15, $06, $00, $18, $18, $24, $2F, $B8, $E3, $05, $12, $C8
	db $37, $F8, $FF, $E3, $FC, $CE, $F0, $98, $E0, $90, $E0, $A0, $C0, $01, $80, $C0
	db $60, $33, $4F, $AB, $00, $05, $00, $48, $02, $27, $00, $00, $0A, $FF, $A1, $5F
	db $D4, $2B, $7A, $05, $31, $AD, $02, $EE, $0B, $00, $70, $15, $00, $BF, $FF, $57
	db $FF, $2A, $FF, $85, $7F, $42, $BF, $C0, $17, $D0, $2F, $A9, $57, $FB, $0E, $FF
	db $F1, $FF, $F5, $80, $79, $AD, $F3, $69, $F3, $71, $A9, $03, $80, $CC, $33, $3B
	db $20, $00, $19, $55, $20, $A0, $40, $69, $90, $36, $4D, $C9, $46, $80, $00, $80
	db $14, $88, $60, $90, $06, $7A, $F8, $01, $0F, $89, $00, $D1, $A8, $07, $95, $01
	db $08, $04, $00, $4A, $25, $2E, $09, $20, $13, $C0, $50, $22, $29, $14, $04, $18
	db $64, $9A, $40, $BF, $80, $00, $3D, $88, $40, $00, $50, $A4, $50, $09, $7B, $F6
	db $06, $3F, $78, $00, $00, $52, $4E, $43, $02, $00, $00, $04, $00, $00, $00, $00
	db $90, $4F, $25, $DC, $32, $04, $01, $00, $45, $46, $47, $48, $49, $4A, $B0, $00
	db $4B, $4C, $07, $4D, $4E, $4F, $50, $44, $8F, $03, $00, $51, $52, $04, $40, $0D
	db $00, $53, $54, $F3, $04, $0D, $55, $D9, $08, $1E, $00, $56, $E7, $04, $0C, $57
	db $9E, $0A, $1F, $58, $04, $0C, $79, $59, $0A, $1F, $5A, $E7, $04, $0C, $5B, $9E
	db $0A, $1F, $5C, $A4, $1F, $79, $5D, $17, $1F, $5E, $E7, $0A, $1F, $5F, $9E, $04
	db $0C, $60, $0A, $1F, $79, $61, $04, $0C, $62, $E7, $0A, $1F, $63, $8F, $04, $0C
	db $64, $53, $09, $CF, $BF, $65, $04, $00, $0D, $66, $67, $68, $69, $6A, $6B, $6C
	db $4C, $6D, $00, $6E, $0F, $6F, $70, $71, $72, $04, $00, $1F, $73, $74, $75, $76
	db $77, $78, $79, $18, $7A, $7B, $7F, $00, $7C, $7D, $A3, $0C, $7E, $DE, $0A, $72
	db $F7, $00, $F7, $B3, $00, $80, $00, $52, $4E, $43, $02, $00, $00, $00, $3C, $00
	db $00, $00, $0D, $30, $75, $1F, $A6, $04, $01, $1E, $00, $26, $00, $20, $01, $02
	db $00, $01, $93, $00, $C0, $00, $52, $4E, $43, $02, $00, $00, $03, $00, $00, $00
	db $01, $CE, $30, $66, $4E, $1F, $04, $01, $17, $E3, $8C, $00, $C9, $08, $91, $11
	db $89, $01, $11, $11, $33, $33, $87, $06, $FF, $3C, $F3, $00, $E3, $02, $F3, $02
	db $E7, $06, $E7, $04, $CF, $0C, $CF, $08, $FF, $18, $C3, $00, $99, $18, $F3, $33
	db $C7, $06, $9F, $1C, $33, $30, $07, $1F, $7C, $80, $0F, $F9, $31, $C3, $04, $03
	db $F3, $12, $33, $02, $2E, $2F, $1A, $F9, $00, $E1, $01, $C9, $09, $93, $13, $01
	db $00, $E7, $67, $33, $E1, $FF, $0C, $C1, $00, $CF, $0F, $9F, $18, $87, $00, $F3
	db $30, $A0, $45, $2F, $E1, $9B, $0F, $10, $3D, $33, $22, $2F, $66, $81, $19, $33
	db $5D, $86, $5B, $15, $08, $9F, $10, $FF, $30, $01, $7F, $99, $19, $83, $03, $33
	db $32, $24, $1F, $08, $5F, $99, $11, $60, $5F, $25, $0F, $0C, $FF, $78, $31, $FF
	db $00, $01, $E7, $00, $02, $59, $CF, $00, $10, $8F, $0F, $93, $11, $6D, $43, $41
	db $3F, $80, $0B, $BB, $00, $D7, $02, $EF, $04, $6C, $D7, $07, $4D, $22, $92, $1D
	db $C6, $01, $80, $03, $7A, $3F, $02, $0D, $4D, $3F, $DF, $27, $DD, $BD, $06, $4F
	db $02, $01, $0D, $8F, $CF, $60, $91, $FF, $66, $C3, $F4, $03, $9F, $20, $CF, $1F
	db $9F, $66, $1B, $B9, $3F, $CF, $4B, $20, $39, $0F, $D9, $AF, $82, $01, $31, $31
	db $33, $23, $16, $0F, $03, $FF, $3F, $3C, $3F, $20, $03, $3D, $4F, $7E, $04, $0F
	db $89, $01, $FF, $60, $06, $3F, $99, $10, $3D, $2F, $40, $21, $2F, $C9, $00, $B0
	db $6D, $27, $26, $06, $27, $24, $FF, $6C, $E1, $9F, $5B, $03, $68, $7D, $35, $C6
	db $5F, $F9, $01, $11, $80, $B3, $27, $04, $8F, $0E, $0C, $FF, $38, $CF, $5C, $3F
	db $21, $93, $13, $87, $06, $33, $30, $39, $20, $39, $21, $FF, $63, $C5, $19, $49
	db $3F, $C3, $0F, $03, $03, $30, $6F, $DD, $1F, $01, $81, $01, $CC, $51, $33, $00
	db $22, $86, $BF, $0F, $76, $DD, $DD, $09, $89, $09, $23, $23, $25, $0F, $A4, $6F
	db $AF, $96, $6F, $86, $0F, $51, $D0, $8B, $A1, $92, $9F, $0E, $1F, $35, $33, $9F
	db $89, $7F, $3B, $D0, $02, $1F, $71, $D1, $6F, $9B, $9F, $CF, $A1, $25, $A5, $00
	db $82, $FF, $81, $00, $E7, $27, $49, $AD, $69, $CF, $34, $CF, $2F, $0C, $CF, $87
	db $04, $1F, $99, $C9, $2F, $11, $34, $0D, $DD, $20, $BF, $0F, $99, $E8, $6B, $30
	db $03, $02, $11, $77, $64, $FF, $38, $44, $89, $2F, $E3, $E6, $F1, $57, $19, $93
	db $12, $11, $3F, $77, $64, $0F, $23, $51, $32, $9F, $C1, $69, $13, $1B, $0D, $5D
	db $46, $E1, $4F, $96, $A5, $C7, $2D, $FF, $1E, $ED, $08, $B9, $01, $8F, $00, $FF
	db $FF, $04, $71, $0F, $2F, $FE, $51, $2B, $19, $E9, $30, $67, $15, $38, $A1, $6B
	db $FF, $49, $6C, $0D, $E0, $00, $52, $4E, $43, $02, $00, $00, $02, $80, $00, $00
	db $01, $70, $31, $75, $C8, $58, $04, $01, $00, $40, $C0, $73, $C3, $7F, $CF, $19
	db $7F, $FF, $73, $01, $CF, $21, $07, $40, $CC, $BD, $13, $02, $01, $70, $F8, $C8
	db $FE, $CC, $3F, $F4, $3F, $F2, $FF, $CB, $FF, $CD, $80, $07, $07, $03, $01, $3D
	db $01, $00, $03, $00, $80, $21, $71, $C1, $7D, $CF, $7D, $FF, $09, $7B, $F7, $7B
	db $C7, $0F, $07, $4A, $C6, $04, $00, $3F, $5C, $6C, $DF, $EC, $BF, $F0, $BF, $12
	db $F3, $DF, $EF, $1E, $07, $83, $83, $04, $3D, $80, $3F, $70, $C0, $7E, $01, $CD
	db $7E, $FD, $7F, $F3, $7F, $C3, $21, $07, $4F, $C3, $E0, $04, $3F, $0F, $1C, $6F
	db $7C, $31, $F7, $FB, $01, $6F, $FC, $A0, $01, $07, $60, $1E, $E0, $00, $80, $06
	db $3F, $03, $78, $C8, $7F, $CC, $7F, $F4, $89, $3F, $CB, $1E, $07, $47, $06, $3F
	db $06, $0C, $3F, $3C, $F3, $FF, $01, $34, $3F, $FC, $01, $03, $07, $30, $F0, $00
	db $C0, $C7, $06, $3F, $7C, $CC, $1C, $37, $F0, $3F, $48, $CF, $07, $43, $F0, $05
	db $3F, $05, $06, $1D, $18, $1E, $DB, $FF, $01, $BD, $7E, $D0, $01, $07, $0F, $B8
	db $78, $A0, $60, $04, $01, $3F, $4C, $CC, $5F, $EC, $5F, $E0, $C4, $3D, $FF, $87
	db $07, $73, $F3, $B0, $04, $3D, $01, $00, $01, $06, $38, $07, $EF, $FC, $F6, $6A
	db $3F, $01, $0F, $07, $3E, $F0, $38, $04, $01, $3F, $4E, $CC, $4F, $FC, $4F, $F2
	db $C4, $3F, $FD, $87, $07, $71, $F1, $80, $07, $3F, $00, $83, $83, $FF, $CF, $FF
	db $04, $4F, $F3, $3F, $F3, $BF, $87, $07, $70, $3C, $99, $04, $3F, $4F, $B3, $FC
	db $D9, $BB, $FF, $A4, $05, $07, $3C, $70, $F0, $06, $3F, $80, $18, $80, $E0, $C0
	db $58, $FC, $2F, $08, $FF, $B3, $FF, $D3, $07, $07, $7F, $33, $1F, $13, $80, $04
	db $3F, $45, $C6, $5D, $FE, $5B, $FF, $09, $7B, $FF, $7D, $FE, $0F, $07, $78, $F8
	db $06, $60, $3F, $00, $F0, $C0, $FE, $0D, $3B, $FE, $3D, $20, $3A, $C3, $07, $3F
	db $1F, $33, $0F, $03, $05, $8D, $3F, $C3, $4C, $94, $84, $7D, $FF, $7C, $FF, $CF
	db $07, $FC, $06, $3A, $3F, $E0, $03, $41, $FF, $2C, $FF, $34, $74, $7D, $73, $41
	db $07, $3D, $7D, $07, $05, $3F, $E0, $00, $52, $4E, $43, $02, $00, $00, $0E, $C0
	db $00, $00, $07, $8D, $F6, $F0, $44, $30, $04, $01, $07, $00, $FF, $01, $13, $01
	db $00, $43, $01, $09, $01, $00, $7F, $00, $BF, $80, $BF, $81, $03, $01, $7F, $03
	db $0E, $0F, $80, $FF, $C1, $06, $01, $C2, $FE, $85, $FC, $01, $0E, $8B, $F8, $5F
	db $C0, $30, $15, $01, $17, $FF, $07, $FE, $30, $0F, $FC, $01, $1F, $E0, $FF, $1C
	db $C3, $FF, $81, $23, $90, $47, $02, $FE, $F3, $01, $3F, $80, $42, $05, $25, $16
	db $0F, $1B, $5E, $FB, $F8, $01, $61, $06, $31, $F0, $1F, $F8, $0A, $3B, $26, $3F
	db $00, $7D, $80, $3B, $05, $FC, $0B, $42, $F8, $2F, $49, $3D, $1C, $33, $00, $7B
	db $28, $E0, $7F, $01, $FF, $72, $C0, $0B, $4D, $1F, $85, $09, $87, $09, $9F, $C0
	db $FF, $1C, $1B, $C0, $85, $80, $87, $3F, $FF, $17, $6D, $F0, $47, $01, $B1, $05
	db $01, $2F, $E0, $88, $0F, $F8, $FF, $31, $67, $F8, $01, $3F, $F0, $90, $01, $7F
	db $3F, $DA, $3B, $17, $C7, $01, $00, $14, $BD, $C0, $DF, $03, $C5, $FC, $CB, $F8
	db $D7, $F0, $31, $0F, $FE, $5F, $83, $7F, $08, $DD, $24, $31, $7F, $D5, $70, $03
	db $01, $04, $FC, $0F, $06, $FC, $0A, $F8, $04, $43, $5F, $3F, $06, $3B, $38, $3F
	db $C7, $07, $16, $C0, $C8, $8E, $80, $1B, $03, $B5, $48, $84, $B6, $F0, $C1, $25
	db $3F, $CE, $C0, $7F, $49, $BF, $30, $01, $27, $7F, $7F, $D8, $0F, $18, $F5, $04
	db $00, $01, $D8, $6B, $B3, $1F, $1F, $3D, $F0, $00, $02, $0F, $07, $99, $00, $9B
	db $03, $0F, $7F, $CD, $B5, $05, $8C, $0D, $1F, $2F, $E0, $4C, $1F, $4F, $03, $0E
	db $FF, $7C, $FC, $83, $06, $1B, $FC, $00, $80, $00, $0B, $07, $3C, $FC, $C3, $C0
	db $3F, $1C, $0B, $C0, $3C, $CE, $00, $C0, $0A, $0B, $78, $00, $40, $40, $0B, $00
	db $1E, $1E, $DB, $45, $05, $59, $03, $00, $A1, $73, $0D, $E2, $02, $11, $FF, $FF
	db $1E, $05, $02, $13, $2C, $CB, $CB, $19, $91, $13, $FE, $58, $55, $81, $FF, $5C
	db $86, $60, $FE, $99, $F8, $A7, $E0, $DE, $C0, $18, $FC, $27, $E0, $DC, $C0, $38
	db $80, $60, $63, $80, $E2, $01, $7A, $9E, $05, $02, $01, $20, $15, $00, $17, $00
	db $F3, $01, $0F, $FF, $C9, $06, $1F, $01, $C4, $27, $81, $01, $05, $FC, $7F, $03
	db $0E, $01, $8E, $4D, $71, $01, $05, $0E, $2D, $B5, $6D, $DD, $A5, $11, $9F, $B5
	db $E0, $01, $A1, $DD, $33, $11, $27, $6C, $DF, $FE, $9C, $76, $87, $20, $AD, $28
	db $61, $17, $DF, $C0, $50, $54, $07, $7E, $F8, $01, $F9, $54, $E1, $4C, $C3, $5F
	db $C1, $B6, $E3, $02, $FE, $01, $DF, $41, $DF, $C1, $1A, $01, $11, $11, $01, $09
	db $09, $82, $C4, $EB, $26, $4B, $9B, $5A, $0F, $1F, $43, $00, $03, $30, $2B, $C7
	db $85, $AB, $90, $AD, $2B, $F8, $06, $8B, $DF, $01, $02, $10, $69, $01, $C1, $29
	db $EF, $E0, $DF, $C1, $F1, $04, $5F, $27, $D9, $AE, $02, $55, $3F, $0B, $FB, $14
	db $F0, $18, $F0, $28, $E0, $30, $E0, $50, $C0, $60, $C0, $A0, $80, $05, $1D, $BF
	db $37, $05, $0C, $DB, $D8, $D7, $90, $DF, $90, $2F, $20, $3F, $20, $5F, $40, $01
	db $7F, $1E, $40, $FF, $00, $06, $01, $1F, $FE, $02, $FD, $04, $3C, $D0, $01, $03
	db $7F, $00, $60, $00, $B0, $80, $01, $01, $50, $40, $58, $40, $D8, $40, $D3, $95
	db $F1, $03, $0D, $DA, $FF, $B7, $AC, $9E, $02, $00, $E0, $05, $0D, $F1, $0A, $00
	db $15, $15, $E3, $06, $0F, $D1, $D1, $E2, $02, $2B, $04, $00, $E9, $E9, $96, $07
	db $8F, $4F, $04, $88, $5F, $2B, $00, $EA, $60, $19, $01, $83, $FF, $8C, $FC, $1A
	db $B3, $F0, $CF, $FC, $61, $07, $3C, $80, $70, $28, $51, $7C, $C7, $01, $7C, $59
	db $04, $3D, $3F, $00, $01, $A6, $F1, $04, $4F, $07, $15, $F5, $91, $05, $0F, $00
	db $12, $1D, $89, $1F, $40, $23, $FE, $0E, $FD, $0F, $0C, $FB, $08, $F7, $02, $DD
	db $0F, $00, $63, $FE, $1E, $FD, $3C, $F7, $2B, $3F, $F3, $72, $7B, $00, $32, $2F
	db $03, $41, $08, $02, $FE, $AF, $D0, $39, $DF, $FD, $03, $CF, $8C, $31, $F7, $F0
	db $01, $D7, $39, $F0, $97, $01, $18, $C1, $FF, $3F, $27, $FC, $7F, $5E, $8F, $82
	db $51, $C1, $FF, $1F, $6B, $02, $05, $51, $7E, $07, $A3, $87, $2A, $4D, $FE, $34
	db $E1, $15, $A1, $DB, $7E, $50, $43, $FD, $4A, $0F, $BF, $35, $02, $15, $33, $1F
	db $DD, $01, $0F, $33, $FF, $07, $83, $DF, $AF, $E0, $E3, $04, $7B, $1F, $2B, $FF
	db $7F, $04, $18, $7B, $01, $F5, $FC, $F8, $04, $7B, $83, $2B, $E0, $E3, $03, $7B
	db $D9, $02, $29, $51, $07, $D5, $BB, $01, $16, $F0, $14, $F0, $BF, $BF, $C0, $F5
	db $05, $0F, $F8, $07, $3E, $C8, $60, $40, $00, $01, $5F, $40, $BF, $A0, $2F, $20
	db $9F, $1F, $90, $97, $90, $03, $1C, $59, $4C, $E8, $5B, $06, $67, $D8, $40, $D0
	db $C0, $01, $03, $B0, $80, $A0, $80, $E0, $80, $16, $4B, $F5, $F5, $D2, $E9, $C9
	db $E3, $FF, $E8, $DF, $02, $01, $87, $FF, $F8, $F8, $FF, $78, $ED, $9C, $FC, $75
	db $E3, $5C, $BF, $FC, $1F, $80, $09, $9F, $80, $7C, $E8, $69, $AC, $B0, $C3, $5B
	db $70, $54, $EF, $1F, $36, $00, $EB, $07, $57, $4F, $FF, $9F, $03, $1B, $00, $05
	db $59, $4F, $3C, $11, $03, $BB, $03, $13, $FF, $0C, $FC, $C1, $E4, $FF, $18, $F8
	db $E7, $C7, $6F, $78, $01, $1F, $0F, $FF, $F0, $F0, $0F, $D7, $2D, $53, $70, $65
	db $AF, $63, $1D, $99, $F8, $01, $61, $20, $10, $F0, $01, $20, $48, $E0, $01, $60
	db $5C, $C0, $7E, $01, $01, $03, $03, $07, $07, $06, $07, $0E, $0F, $1C, $1F, $18
	db $1F, $38, $3F, $07, $7B, $9D, $18, $73, $04, $FC, $01, $08, $F8, $73, $1F, $57
	db $BA, $2B, $3C, $83, $29, $0C, $8E, $2B, $F8, $9C, $A7, $0F, $0C, $48, $1E, $47
	db $40, $3B, $C0, $7F, $B8, $27, $0F, $10, $0F, $00, $C2, $FE, $C4, $FC, $C8, $F8
	db $D0, $F0, $CA, $77, $DF, $43, $41, $57, $2B, $55, $70, $2A, $F1, $00, $B0, $CF
	db $4F, $C8, $01, $0F, $8E, $6A, $00, $01, $0D, $0F, $1E, $1E, $1A, $1E, $1C, $7F
	db $1C, $01, $ED, $36, $13, $F6, $68, $0F, $9F, $3A, $A1, $03, $12, $AF, $FE, $E9
	db $45, $E0, $C0, $C8, $00, $99, $67, $00, $1F, $3C, $3C, $38, $38, $78, $78, $2C
	db $70, $70, $6F, $4C, $0C, $C7, $F0, $EE, $BE, $93, $00, $09, $01, $15, $0B, $F8
	db $37, $F7, $50, $DA, $CB, $37, $C9, $CF, $04, $AF, $C5, $08, $1F, $B7, $4F, $74
	db $FE, $F8, $85, $6F, $84, $7D, $02, $EC, $41, $AA, $61, $8E, $FC, $02, $FF, $03
	db $03, $F5, $04, $DA, $18, $60, $60, $E2, $01, $15, $71, $0B, $0C, $07, $73, $0E
	db $78, $FE, $02, $81, $1F, $FF, $0F, $FD, $FC, $37, $30, $02, $E8, $FB, $39, $01
	db $FF, $FF, $01, $C0, $2F, $85, $DF, $C0, $0F, $6F, $60, $D6, $10, $02, $FA, $09
	db $7F, $B3, $07, $07, $A3, $53, $A8, $54, $E4, $89, $8E, $00, $87, $3E, $19, $F8
	db $03, $BF, $C3, $09, $57, $BF, $13, $9F, $07, $0F, $CB, $05, $57, $4F, $05, $D7
	db $05, $5F, $1F, $03, $E8, $00, $05, $8B, $25, $06, $FE, $40, $57, $33, $F0, $4F
	db $3A, $C0, $BC, $A7, $A3, $30, $FC, $D6, $03, $AB, $0F, $01, $1F, $0D, $8F, $AF
	db $01, $03, $01, $60, $C0, $40, $C0, $41, $AA, $66, $7F, $99, $53, $70, $F3, $01
	db $EB, $20, $0F, $05, $FE, $0B, $01, $FC, $15, $EF, $2A, $DF, $54, $AF, $20, $0F
	db $B8, $7C, $FC, $01, $78, $53, $87, $AF, $07, $56, $0F, $20, $0F, $3E, $1C, $18
	db $0E, $3C, $01, $83, $87, $89, $94, $80, $95, $1F, $20, $1E, $C0, $FE, $80, $12
	db $FD, $82, $FC, $B8, $E4, $80, $15, $60, $00, $EA, $8A, $E2, $84, $D5, $15, $55
	db $D5, $90, $1F, $35, $20, $07, $A2, $2A, $2A, $40, $55, $24, $00, $C3, $00, $34
	db $20, $AA, $2A, $6A, $C0, $D5, $1B, $28, $D1, $17, $0F, $0A, $00, $C4, $89, $AB
	db $AD, $A8, $49, $1D, $53, $24, $51, $57, $2F, $01, $55, $80, $AA, $0A, $8A, $11
	db $54, $60, $2F, $00, $3E, $20, $00, $BD, $60, $3C, $C3, $F9, $00, $F8, $03, $90
	db $0F, $26, $C4, $00, $D5, $95, $55, $81, $AB, $9A, $0B, $B2, $A0, $0F, $90, $0A
	db $B0, $00, $B5, $25, $B5, $20, $6A, $4D, $68, $4B, $A0, $0F, $A4, $43, $46, $03
	db $57, $54, $57, $04, $AF, $A8, $3F, $01, $FF, $06, $4A, $3B, $01, $5F, $19, $F9
	db $2C, $E0, $58, $50, $61, $40, $AE, $8E, $15, $0E, $FE, $31, $B8, $ED, $3E, $00
	db $70, $9D, $07, $A3, $F4, $F4, $D7, $06, $3F, $E4, $06, $CD, $13, $F0, $54, $00
	db $7A, $35, $02, $33, $E1, $70, $FE, $8F, $80, $7E, $80, $76, $00, $05, $01, $05
	db $81, $00, $01, $6F, $60, $5F, $40, $1D, $FF, $C0, $BF, $11, $62, $0F, $21, $FF
	db $09, $00, $01, $E8, $08, $F5, $04, $FD, $04, $FA, $47, $02, $E3, $17, $E4, $19
	db $00, $EA, $10, $75, $40, $01, $39, $80, $60, $01, $F1, $03, $19, $FD, $04, $65
	db $F7, $02, $00, $9F, $05, $4E, $0F, $05, $58, $6D, $A6, $85, $4C, $EB, $A1, $71
	db $43, $F0, $97, $00, $AE, $18, $FE, $67, $E0, $9E, $80, $78, $EA, $67, $1F, $4B
	db $03, $3F, $E9, $03, $0B, $7C, $00, $07, $41, $1F, $0F, $FD, $F5, $05, $CD, $C7
	db $95, $E7, $70, $7C, $F5, $C0, $80, $58, $40, $89, $E5, $FE, $06, $9F, $DF, $00
	db $F4, $06, $F0, $0F, $3F, $60, $17, $10, $0B, $09, $88, $02, $02, $24, $1F, $9C
	db $78, $38, $01, $33, $FA, $0D, $0F, $C4, $00, $28, $20, $03, $A7, $91, $D6, $07
	db $6F, $C2, $A7, $16, $F0, $1C, $A8, $75, $01, $BF, $86, $75, $04, $D5, $04, $17
	db $40, $01, $15, $04, $05, $04, $FC, $08, $4F, $FB, $ED, $4F, $1B, $51, $19, $01
	db $F9, $00, $07, $F0, $F8, $09, $2E, $87, $87, $3F, $60, $00, $05, $BF, $5F, $06
	db $F8, $BD, $EB, $1F, $80, $E8, $07, $1F, $F0, $01, $01, $03, $FF, $84, $3A, $FC
	db $D2, $91, $7B, $9B, $F8, $A6, $D6, $3B, $63, $B8, $75, $43, $8F, $D3, $1F, $05
	db $A1, $0D, $00, $F1, $04, $5B, $80, $B3, $2C, $E0, $60, $F0, $9C, $80, $7E, $70
	db $02, $6D, $07, $80, $01, $FB, $05, $81, $5C, $22, $81, $02, $38, $00, $02, $11
	db $01, $9D, $7A, $9F, $23, $19, $8E, $53, $EC, $D7, $56, $FA, $20, $09, $FE, $02
	db $20, $FA, $02, $C1, $00, $3B, $9F, $60, $0B, $6B, $40, $80, $40, $43, $03, $F5
	db $F7, $06, $1F, $E0, $02, $ED, $0D, $FD, $33, $F3, $22, $4A, $C2, $0E, $95, $37
	db $F0, $B2, $5D, $7C, $03, $A1, $FC, $FC, $E7, $07, $FD, $E9, $05, $6F, $75, $7C
	db $37, $6D, $0F, $58, $40, $EC, $20, $D4, $10, $F6, $10, $EA, $08, $80, $05, $07
	db $CF, $20, $FC, $07, $AB, $7F, $0F, $FB, $01, $DD, $07, $01, $C0, $57, $81, $E1
	db $06, $1F, $01, $E7, $07, $3F, $D0, $EF, $01, $CB, $03, $EC, $FF, $67, $11, $0D
	db $48, $2D, $2E, $E0, $19, $01, $F9, $6C, $E0, $98, $80, $F0, $80, $6D, $85, $FA
	db $04, $5F, $3F, $87, $F3, $08, $A3, $E3, $02, $3B, $6E, $E0, $B0, $49, $00, $E3
	db $E3, $55, $B0, $BF, $DB, $03, $C4, $1F, $ED, $FF, $00, $89, $F8, $B7, $F0, $CE
	db $C0, $FC, $FF, $FA, $05, $7E, $AD, $07, $87, $3F, $01, $DC, $03, $39, $19, $F8
	db $89, $09, $07, $0E, $FE, $33, $F0, $4E, $5D, $39, $F0, $39, $FF, $97, $1F, $7F
	db $03, $67, $7F, $F5, $05, $6F, $81, $91, $68, $FF, $68, $7D, $8B, $F8, $96, $03
	db $F0, $AC, $E0, $D8, $C0, $30, $12, $2B, $C7, $70, $DF, $9B, $02, $7F, $5F, $02
	db $A4, $CA, $FF, $38, $78, $F8, $00, $52, $4E, $43, $02, $00, $00, $02, $40, $00
	db $00, $01, $4D, $47, $17, $C9, $59, $04, $01, $1E, $F4, $1B, $00, $3C, $A7, $CE
	db $13, $1C, $94, $2E, $95, $96, $3E, $97, $98, $99, $9A, $9B, $9C, $9D, $9E, $9F
	db $A0, $A1, $A2, $A3, $A4, $A5, $A6, $05, $1F, $17, $BB, $BC, $BD, $1F, $BE, $BF
	db $C0, $C1, $C2, $C3, $C4, $C5, $C6, $C7, $C8, $C9, $CA, $CB, $CC, $CD, $05, $0B
	db $1F, $E1, $E2, $E3, $8F, $E4, $E5, $E6, $E7, $E8, $E9, $EA, $EB, $EC, $ED, $EE
	db $EF, $F0, $F1, $F2, $F3, $85, $05, $1F, $04, $05, $06, $C7, $07, $08, $09, $0A
	db $0B, $0C, $0D, $0E, $0F, $10, $0E, $11, $12, $13, $14, $15, $C2, $05, $1F, $2A
	db $2B, $2C, $E3, $2D, $2E, $2F, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39
	db $3A, $15, $15, $E3, $13, $AD, $70, $71, $3C, $1E, $72, $11, $1D, $73, $31, $74
	db $75, $1E, $76, $77, $E0, $0F, $1D, $78, $79, $7A, $7B, $07, $15, $7C, $7D, $7E
	db $BA, $80, $0D, $1D, $7F, $16, $3B, $59, $15, $5B, $0F, $5C, $5D, $5E, $BA, $05
	db $17, $1F, $A8, $A9, $1F, $AA, $AB, $AC, $AD, $AE, $AF, $B0, $B1, $B2, $B3, $B4
	db $B5, $B6, $B7, $B8, $B9, $06, $0B, $1F, $CF, $D0, $D1, $86, $D2, $D3, $D4, $D5
	db $D6, $D7, $D8, $D9, $DA, $DB, $DC, $DD, $1C, $1E, $DE, $DF, $E0, $04, $1F, $03
	db $F5, $D0, $F6, $F7, $F8, $D6, $80, $00, $F9, $FA, $FB, $FC, $FD, $03, $FE, $FF
	db $00, $01, $02, $03, $D7, $04, $1F, $2F, $17, $18, $19, $1A, $1B, $1C, $1D, $1E
	db $1F, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $29, $04, $5C, $1F, $BD
	db $3C, $3D, $3E, $3F, $40, $41, $42, $43, $44, $45, $45, $46, $47, $48, $49, $4A
	db $29, $4B, $29, $4C, $04, $1F, $72, $5F, $60, $BA, $61, $62, $41, $63, $64, $65
	db $66, $67, $68, $69, $6A, $6B, $6C, $6D, $6E, $6F, $58, $F5, $04, $1F, $C7, $4D
	db $4E, $DF, $4F, $50, $51, $52, $53, $54, $55, $56, $56, $57, $58, $58, $5A, $3D
	db $02, $58, $05, $1F, $E0, $00, $52, $4E, $43, $02, $00, $00, $00, $EC, $00, $00
	db $00, $3D, $E7, $42, $00, $6D, $04, $01, $1E, $00, $09, $00, $6F, $01, $01, $05
	db $21, $00, $02, $00, $E7, $18, $26, $02, $92, $0E, $25, $01, $48, $25, $1D, $02
	db $73, $03, $00, $DE, $09, $20, $03, $3E, $F7, $01, $24, $BD, $0C, $25, $06, $20
	db $BC, $00, $04, $0D, $01, $1E, $03, $01, $02, $08, $1F, $86, $16, $15, $A4, $38
	db $CF, $62, $01, $00, $00, $52, $4E, $43, $02, $00, $00, $03, $20, $00, $00, $02
	db $C8, $87, $86, $3E, $6D, $04, $01, $12, $00, $0D, $00, $18, $3C, $24, $01, $72
	db $18, $24, $1C, $20, $3E, $0A, $6C, $5A, $3F, $41, $7E, $01, $66, $19, $E3, $84
	db $C3, $A0, $A3, $E3, $90, $1E, $78, $84, $B9, $C2, $7E, $82, $4C, $B2, $66, $A8
	db $6E, $A8, $FC, $82, $E7, $99, $E2, $85, $66, $05, $63, $00, $33, $50, $B0, $D3
	db $40, $40, $1D, $E9, $48, $78, $BC, $C4, $7C, $80, $DE, $32, $CC, $0A, $C0, $00
	db $60, $A0, $46, $A5, $E7, $84, $77, $14, $36, $49, $3F, $01, $AE, $B2, $80, $80
	db $AE, $1D, $58, $01, $01, $03, $00, $23, $40, $F1, $92, $FB, $8A, $F1, $88, $DC
	db $A5, $EE, $B2, $5C, $32, $7F, $01, $5F, $6B, $18, $03, $61, $02, $61, $01, $20
	db $60, $5C, $1F, $B0, $05, $06, $07, $00, $77, $94, $FB, $08, $BB, $40, $8F, $92
	db $1C, $93, $CD, $4B, $86, $40, $E6, $20, $67, $EE, $90, $7C, $04, $02, $B4, $CC
	db $60, $E0, $81, $7F, $80, $E0, $F0, $10, $8C, $01, $40, $C0, $4F, $D0, $06, $68
	db $F0, $08, $E8, $18, $67, $0C, $F4, $3A, $7E, $80, $8B, $68, $49, $18, $1F, $8C
	db $BC, $7C, $42, $B5, $E2, $00, $95, $73, $90, $D0, $30, $E0, $20, $61, $60, $A2
	db $B9, $67, $14, $3E, $41, $C4, $81, $2E, $32, $0B, $1D, $0C, $0C, $8E, $C6, $CA
	db $CE, $0A, $4C, $8A, $66, $A0, $E7, $A1, $77, $19, $FE, $81, $F6, $8D, $BD, $00
	db $73, $10, $31, $52, $63, $53, $50, $70, $C0, $1D, $03, $03, $01, $02, $73, $0C
	db $52, $21, $50, $39, $C6, $01, $03, $69, $15, $5C, $30, $7C, $12, $18, $9F, $73
	db $0C, $1F, $63, $02, $36, $B1, $D1, $77, $BD, $5D, $0F, $38, $0E, $19, $04, $0C
	db $91, $CF, $53, $9C, $52, $FE, $30, $DB, $35, $BE, $55, $AF, $54, $FB, $26, $6D
	db $B0, $DC, $B1, $67, $0B, $BC, $DC, $E0, $BF, $04, $2E, $02, $63, $58, $65, $FE
	db $0D, $F3, $08, $AD, $76, $CB, $56, $FE, $07, $F1, $09, $60, $90, $E0, $80, $70
	db $10, $30, $5A, $C0, $98, $18, $28, $C0, $40, $FE, $29, $39, $38, $7A, $46, $51
	db $14, $E0, $EF, $00, $B0, $D1, $B8, $68, $A1, $D1, $B8, $09, $FB, $66, $8F, $50
	db $C7, $08, $67, $A7, $3C, $78, $FF, $13, $00, $01, $03, $5D, $02, $38, $13, $1A
	db $0F, $16, $5D, $D0, $C6, $0B, $EF, $09, $F2, $05, $EF, $90, $77, $18, $63, $D4
	db $B1, $02, $F0, $69, $D8, $40, $98, $54, $84, $4C, $5D, $80, $C6, $DB, $1C, $10
	db $DD, $17, $D6, $31, $FF, $3C, $0C, $FB, $62, $03, $82, $FD, $03, $FF, $01, $26
	db $E5, $23, $20, $3B, $5C, $7E, $C1, $AD, $33, $8A, $4E, $C0, $00, $38, $00, $08
	db $00, $F8, $60, $C8, $10, $40, $A8, $68, $18, $63, $78, $09, $00, $A8, $00, $9A
	db $98, $C8, $48, $C6, $05, $42, $A2, $C1, $08, $70, $50, $20, $20, $8B, $64, $30
	db $30, $A7, $74, $4C, $7E, $82, $EC, $1A, $EF, $29, $EF, $91, $7C, $42, $FC, $64
	db $C8, $14, $EE, $22, $FF, $99, $B7, $C4, $11, $AB, $DC, $44, $F8, $38, $65, $1F
	db $02, $D3, $31, $30, $34, $4D, $7F, $83, $EE, $10, $EA, $2D, $C7, $04, $C3, $00
	db $E1, $22, $61, $A2, $41, $A2, $61, $12, $3B, $44, $1F, $20, $0F, $11, $D7, $14
	db $BE, $1C, $02, $03, $03, $04, $27, $20, $B2, $CD, $F8, $04, $EE, $12, $86, $4A
	db $CC, $12, $65, $F8, $6B, $84, $85, $84, $A0, $D0, $38, $88, $10, $A8, $38, $A0
	db $1C, $84, $10, $90, $46, $1F, $C1, $2E, $3C, $30, $1D, $BE, $D2, $F6, $08, $E7
	db $11, $E7, $24, $43, $A0, $63, $02, $80, $89, $09, $10, $28, $1C, $04, $08, $06
	db $14, $0E, $02, $06, $0A, $C0, $00, $7E, $02, $7F, $81, $FE, $19, $C7, $24, $D7
	db $77, $9E, $E3, $22, $41, $A0, $70, $11, $38, $C9, $9D, $26, $AF, $70, $D7, $18
	db $C5, $27, $E0, $80, $20, $60, $07, $04, $A3, $E0, $F3, $10, $61, $92, $F3, $8A
	db $7F, $06, $3D, $42, $B7, $D8, $6F, $D8, $B7, $04, $99, $2A, $F3, $6A, $D0, $49
	db $C8, $50, $52, $5C, $5F, $E9, $3F, $21, $3F, $00, $73, $4C, $A1, $D2, $E2, $D3
	db $7D, $C3, $1E, $A1, $AB, $BC, $21, $A2, $21, $D2, $7F, $CC, $BE, $01, $FF, $61
	db $D2, $5E, $67, $AB, $10, $89, $80, $8D, $92, $09, $CD, $0B, $00, $E0, $00, $FF
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
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF
