; =====================================================================
; V-Rally: Championship Edition (U) (M3) - Game Boy
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o vrally.o VRallyGB_SoundDriver.asm
;   rgblink -o vrally.gb vrally.o
;   python tools/cmp_banked.py vrally.gb "V-Rally - Championship Edition (U) (M3) [M][!].gb" 2:4000-7FFF
; (driver and data fill ROM bank 2; the linked file only matches in that range)
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
	jp InstrTable1                      ; unused song slot: jumps into the instrument table (never called)
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
	add a, $E5
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

; Unreferenced (40 bytes)
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00
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
	ld a, $5B
	ld [wInstrTableHi], a
	ld a, $CB
	ld [wInstrTable], a
	ld h, $DB
	jr StartMusicCh
StartMusicCh2:
	ld a, $5B
	ld [wInstrTableHi], a
	ld a, $CB
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
	add a, $33
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
	db $D3, $5E, $F0, $5E
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
	ld a, $96
	ld [$DC92], a
	ld a, $4E
	ld [$DC95], a
	ld a, $BC
	ld [$DC94], a
	ret
EngineNoise2:
	ld a, $4E
	ld [$DC93], a
	ld a, $1B
	ld [$DC92], a
	ld a, $4E
	ld [$DC95], a
	ld a, $59
	ld [$DC94], a
	ret
EngineNoise3:
	ld a, $4E
	ld [$DC93], a
	ld a, $0C
	ld [$DC92], a
	ld a, $4E
	ld [$DC95], a
	ld a, $14
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
	ld a, $80
	ldh [rNR30], a
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
	jr nc, L4D02
	ld a, $FF
	and a
L4D02:
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
	jr z, L4D26
	ld [hl], c
	ld a, $80
	or c
	jr L4D27
L4D26:
	ld a, c
L4D27:
	ldh [rNR34], a
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
	jr z, L4D46
	dec a
	ld [$DC8D], a
	jp EngineNoiseStep
L4D46:
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
	jp nc, L4D77
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
L4D6C:
	ld a, d
	ld [$DC8C], a
	ld a, e
	ld [$DC8B], a
	jp EngineNoiseStep
L4D77:
	cp $C4
	jr nc, L4D9C
	cp $68
	jp z, L4DA7
	cp $65
	jp z, L4D93
	cp $66
	jp z, L4D8D
	jp EngineCh2Step
L4D8D:
	xor a
	ldh [rNR22], a
	jp L4D6C
L4D93:
	ld a, [$DC8E]
	ld [$DC8D], a
	jp L4D6C
L4D9C:
	sub $C4
	ld [$DC8D], a
	ld [$DC8E], a
	jp EngineCh2Step
L4DA7:
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
	jr z, L4DE9
	ldh [rNR43], a
	ld a, [bc]
	cp $FF
	jr z, L4DD6
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
L4DD6:
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
L4DE9:
	xor a
	ld [$DC93], a
	ret
EngineCh2SeqTable:
	db $F4, $4D, $05, $4E, $09, $4E
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
	add a, $EE
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
	db $3E, $00, $C3, $EC, $4E
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
	dw Pat_4F87
	dw Pat_4F87
	dw Pat_4FCD
	dw Pat_4FF2
	dw Pat_4FCD
	dw Pat_4FF2
	dw Pat_5025
	ORDER_LOOP Song1_Ch3
Song1_Ch2:
	dw Pat_5038
	dw Pat_5038
	dw Pat_508B
	dw Pat_50E1
	dw Pat_508B
	dw Pat_50E1
	dw Pat_5137
	ORDER_LOOP Song1_Ch2
Song1_Ch1:
	dw Pat_518D
	dw Pat_518D
	dw Pat_51BF
	dw Pat_5222
	dw Pat_51BF
	dw Pat_5235
	dw Pat_524B
	ORDER_LOOP Song1_Ch1
Pat_4F87:
	CH_TRANSPOSE $0C
	TRANSPOSE $FE
	DRUMS $07, DrumPat_5286
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
Pat_4FCD:
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
Pat_4FF2:
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
Pat_5025:
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
Pat_5038:
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
Pat_508B:
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
Pat_50E1:
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
Pat_5137:
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
Pat_518D:
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
Pat_51BF:
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
Pat_51F4:
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
Pat_5222:
	PAT_CALL Pat_51F4
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
Pat_5235:
	PAT_CALL Pat_51F4
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
Pat_524B:
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
DrumPat_5286:
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
	dw Pat_5308
	ORDER_LOOP Song2_Ch3
Song2_Ch2:
	dw Pat_53A2
Loop_52EE:
	dw Pat_536B
	dw Pat_536F
	dw Pat_5325
	dw Pat_5325
	ORDER_LOOP Loop_52EE
Song2_Ch1:
	dw Pat_542B
Loop_52FC:
	dw Pat_5400
	dw Pat_544E
	dw Pat_53C4
	dw Pat_53C4
	ORDER_LOOP Loop_52FC
Pat_5308:
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
Pat_5325:
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
Pat_536B:
	DRUMS $07, DrumPat_5481
Pat_536F:
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
Pat_53A2:
	DRUMS $07, DrumPat_547C
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
	DRUMS $07, DrumPat_54A6
	LEN 14
	NOTE A_, 3
	INSTR 2
	NOTE G_, 3
	NEXT
Pat_53C4:
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
Pat_5400:
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
Pat_542B:
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
Pat_544E:
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
DrumPat_547C:
	db 1, 0, 5, 6, DRUM_LOOP
DrumPat_5481:
	db DRUM_REPEAT + 3, 1, 0, 5, 6, 9, 0, 5
	db 6, DRUM_REPEAT_END, 1, 0, 5, 6, 9, 0
	db 4, 0, DRUM_REPEAT + 3, 1, 0, 5, 6, 9
	db 0, 5, 6, DRUM_REPEAT_END, 1, 0, 5, 6
	db 9, 0, 1, 9, DRUM_LOOP
DrumPat_54A6:
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
	dw Pat_54DD

; Unreferenced (4 bytes)
	db $00, $00, $CB, $54
Song3_Ch2:
	dw Pat_54EC

; Unreferenced (4 bytes)
	db $00, $00, $D1, $54
Song3_Ch1:
	dw Pat_54F8

; Unreferenced (4 bytes)
	db $00, $00, $D7, $54
Pat_54DD:
	INSTR 11
	DRUMS $07, DrumPat_5503
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
Pat_54EC:
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
Pat_54F8:
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
DrumPat_5503:
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
	dw Pat_5559
	dw Pat_5559
	dw Pat_5596
	dw Pat_5596
	ORDER_LOOP Song4_Ch3
Song4_Ch2:
	dw Pat_55D1
	dw Pat_55D1
	dw Pat_561C
	dw Pat_561C
	ORDER_LOOP Song4_Ch2
Song4_Ch1:
	dw Pat_5663
	dw Pat_5663
	dw Pat_5693
	dw Pat_5693
	ORDER_LOOP Song4_Ch1
Pat_5559:
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
Pat_5596:
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
Pat_55D1:
	LEN 7
	WAIT
	INSTR 4
	NOTE F_, 4
	INSTR 0
	NOTE A_, 3
	DRUMS $07, DrumPat_56C6
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
Pat_561C:
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
Pat_5663:
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
Pat_5693:
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
DrumPat_56C6:
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
	dw Pat_5700

; Unreferenced (4 bytes)
	db $00, $00, $EE, $56
Song5_Ch2:
	dw Pat_572A

; Unreferenced (4 bytes)
	db $00, $00, $F4, $56
Song5_Ch1:
	dw Pat_5768

; Unreferenced (4 bytes)
	db $00, $00, $FA, $56
Pat_5700:
	CH_TRANSPOSE $0C
	DRUMS $07, DrumPat_578D
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
Pat_572A:
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
Pat_5768:
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
DrumPat_578D:
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
	dw Pat_57DC
	dw Pat_581C

; Unreferenced (4 bytes)
	db $00, $00, $C4, $57
Song6_Ch2:
	dw Pat_5822
	dw Pat_5877

; Unreferenced (4 bytes)
	db $00, $00, $CC, $57
Song6_Ch1:
	dw Pat_587E
	dw Pat_58B2

; Unreferenced (4 bytes)
	db $00, $00, $D4, $57
Pat_57DC:
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
Pat_581C:
	INSTR 11
	LENGTH $E0
	NOTE D_, 2
	WAIT
	END
Pat_5822:
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
Pat_5877:
	INSTR 9
	NOTE D_, 3
	DRUMS_OFF
	LENGTH $E0
	WAIT
	END
Pat_587E:
	DRUMS $07, DrumPat_58B5
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
Pat_58B2:
	LEN 14
	NOTE D_, 4
	END
DrumPat_58B5:
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
	dw Pat_593D
	dw Pat_598B
	dw Pat_598B
	ORDER_LOOP Song7_Ch3
Song7_Ch2:
	dw Pat_59D8
	dw Pat_5A32
	dw Pat_5A41
	dw Pat_5A68
	dw Pat_5A41
	dw Pat_5A68
	ORDER_LOOP Song7_Ch2
Song7_Ch1:
	dw Pat_5ACA
	dw Pat_5B03
	dw Pat_5B03
	ORDER_LOOP Song7_Ch1
Pat_593D:
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
Pat_598B:
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
Pat_59D8:
	DRUMS $0A, DrumPat_5B80
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
Pat_5A32:
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
Pat_5A41:
	DRUMS $0A, DrumPat_5BB5
	LEN 20
	PAT_CALL Pat_5A49
Pat_5A49:
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
Pat_5A68:
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
	DRUMS $0A, DrumPat_5BBE
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
Pat_5ACA:
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
Pat_5B03:
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
DrumPat_5B80:
	db DRUM_REPEAT + 2, 1, 6, 9, 6, 1, 1, 9
	db 6, DRUM_REPEAT_END, 1, 6, 9, 6, 1, 1
	db 9, 1, 6, 9, 6, 9, 6, 9
	db 9, 9, DRUM_REPEAT + 3, 1, 6, 9, 6, 1
	db 1, 9, 6, DRUM_REPEAT_END, 1, 1, 9, 9
	db 1, 6, 9, 6, 1, 1, 9, 9
	db 6, 9, 6, 9, DRUM_LOOP
DrumPat_5BB5:
	db 1, 6, 9, 6, 1, 1, 9, 6
	db DRUM_LOOP
DrumPat_5BBE:
	db 9, 1, 1, 9, 1, 1, 9, 9
	db 1, 9, 9, 1, 9, 9, DRUM_LOOP

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
	dw Instr1_14
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
	WAVE Wave_5D8C
	ARP 0
	END
Instr1_12:
	HWENV $D2, $05, $70
	DUTY_75
	ARP_OFF
	RELEASE $02, $53
	END
Instr1_14:
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
	db $AA, $5C, $AD, $5C, $B7, $5C, $BF, $5C, $C3, $5C, $CD, $5C, $DC, $5C, $E2, $5C
	db $ED, $5C, $F4, $5C, $FF, $5C, $16, $5D, $1A, $5D, $1E, $5D, $31, $5D, $31, $5D
	db $31, $5D, $31, $5D, $35, $5D, $35, $5D, $35, $5D, $35, $5D
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
	WAVE Wave_5D5C
	LEN 5
	NOTE Csh, 6
	END

; Sound effect 2
Sfx02:
	WAVE Wave_5D5C
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
Wave_5D5C:
	db $00, $46, $8A, $FF, $FF, $A8, $64, $00
	db $00, $46, $8A, $FF, $FF, $A8, $64, $00

; Unreferenced (32 bytes)
	db $00, $00, $00, $00, $00, $00, $FF, $FF, $00, $00, $00, $00, $00, $00, $FF, $FF
	db $00, $00, $00, $00, $00, $00, $FF, $00, $00, $00, $00, $00, $00, $00, $FF, $00
Wave_5D8C:
	db $EC, $96, $31, $90, $00, $00, $00, $00
	db $24, $69, $CE, $FF, $FF, $FF, $FF, $FF
Noise43_5D9C:
	db $20, $10, $FF
Noise42_5D9F:
	db $A0, $61
Noise43_5DA1:
	db $06, $04, $03, $03, $07, $FF
Noise42_5DA7:
	db $F0, $C0, $80, $60, $57
Noise43_5DAC:
	db $00, $01, $01, $01, $01, $FF
Noise42_5DB2:
	db $91, $61, $FF, $FF, $FF
Noise43_5DB7:
	db $00, $01, $01, $01, $01, $FF
Noise42_5DBD:
	db $C1, $A1, $FF, $FF, $FF
Noise43_5DC2:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_5DCA:
	db $70, $40, $40, $40, $40, $43, $FF
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5D9C)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5D9C)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5D9F)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5D9F)
	ld [wNoise42], a
	ret
Drum8:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5E0B)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5E0B)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5E11)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5E11)
	ld [wNoise42], a
	ret
Noise43_5E0B:
	db $04, $02, $01, $00, $00, $FF
Noise42_5E11:
	db $30, $40, $60, $43, $42
Drum2:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5E33)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5E33)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5E3B)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5E3B)
	ld [wNoise42], a
	ret
Noise43_5E33:
	db $60, $52, $42, $41, $22, $11, $04, $FF
Noise42_5E3B:
	db $F0, $F0, $F0, $A0, $70, $40, $51
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5DC2)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5DC2)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5DCA)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5DCA)
	ld [wNoise42], a
	ret
Drum5:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5DB7)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5DB7)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5DBD)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5DBD)
	ld [wNoise42], a
	ret
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5DAC)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5DAC)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5DB2)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5DB2)
	ld [wNoise42], a
	ret
Drum7:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5DA1)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5DA1)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5DA7)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5DA7)
	ld [wNoise42], a
	ret
Drum9:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_5EF0)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_5EF0)
	ld [wNoise43], a
	ld a, HIGH(Noise42_5EF3)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_5EF3)
	ld [wNoise42], a
	ret

; Unreferenced (29 bytes)
	db $AF, $EA, $5B, $DB, $3C, $EA, $5C, $DB, $3E, $5E, $EA, $57, $DB, $3E, $F5, $EA
	db $58, $DB, $3E, $5E, $EA, $59, $DB, $3E, $F7, $EA, $5A, $DB, $C9
Noise43_5EF0:
	db $31, $12, $FF
Noise42_5EF3:
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

; Unreferenced (8416 bytes)
	db $9A, $8C, $9C, $23, $4E, $98, $0C, $89, $82, $34, $28, $C8, $70, $98, $C7, $0E
	db $97, $23, $87, $10, $97, $0A, $76, $DF, $9E, $A0, $97, $C8, $6C, $CC, $C9, $78
	db $7E, $29, $34, $72, $39, $04, $82, $13, $85, $13, $05, $71, $28, $47, $12, $39
	db $58, $61, $29, $56, $12, $35, $12, $84, $71, $23, $47, $12, $39, $47, $34, $95
	db $72, $97, $34, $97, $52, $30, $47, $51, $28, $37, $41, $23, $46, $10, $23, $97
	db $60, $34, $71, $34, $71, $29, $57, $39, $45, $85, $68, $45, $08, $34, $59, $86
	db $23, $94, $50, $19, $73, $49, $87, $26, $98, $23, $40, $29, $83, $47, $21, $93
	db $58, $19, $35, $83, $06, $31, $49, $51, $30, $52, $93, $57, $29, $37, $52, $93
	db $52, $39, $57, $23, $95, $20, $95, $72, $39, $57, $23, $53, $48, $67, $43, $58
	db $67, $40, $95, $76, $03, $97, $50, $27, $40, $23, $60, $38, $56, $06, $37, $37
	db $83, $97, $46, $29, $52, $54, $86, $39, $73, $73, $47, $56, $29, $86, $23, $58
	db $62, $38, $56, $23, $85, $63, $86, $52, $83, $52, $36, $52, $35, $28, $35, $62
	db $85, $28, $35, $62, $38, $42, $83, $42, $83, $42, $38, $42, $34, $28, $34, $23
	db $58, $35, $72, $35, $28, $37, $49, $23, $65, $94, $65, $38, $49, $28, $92, $19
	db $52, $4E, $43, $02, $00, $00, $0E, $E0, $00, $00, $0A, $6D, $6E, $8C, $B5, $4A
	db $04, $01, $01, $00, $FF, $01, $FF, $00, $E8, $01, $01, $60, $0B, $00, $D5, $AA
	db $EA, $95, $30, $BF, $81, $01, $BD, $83, $FF, $61, $03, $0F, $80, $FF, $C1, $C5
	db $01, $C3, $CF, $FE, $86, $FC, $85, $FC, $8F, $F8, $6A, $D5, $D5, $AB, $2B, $D5
	db $D7, $2B, $FF, $07, $FE, $0F, $EC, $1F, $FC, $1F, $E0, $1C, $19, $FF, $81, $23
	db $86, $3B, $01, $20, $03, $FE, $3F, $80, $00, $7F, $C0, $BF, $95, $AA, $AA, $55
	db $53, $68, $2F, $25, $41, $0F, $59, $55, $C0, $0F, $FD, $FA, $FF, $F8, $D8, $09
	db $31, $10, $FF, $03, $08, $FF, $5C, $AF, $AC, $5F, $6B, $03, $3F, $30, $7F, $05
	db $02, $FE, $04, $10, $FD, $0B, $F8, $2F, $DB, $3D, $01, $43, $2D, $31, $38, $18
	db $00, $7B, $60, $A6, $01, $37, $72, $C0, $0B, $41, $1F, $60, $DF, $4A, $C2, $87
	db $A9, $97, $09, $9F, $C0, $9C, $1B, $C0, $85, $81, $87, $3F, $FF, $70, $18, $F7
	db $0C, $FB, $09, $FA, $1A, $F5, $15, $F2, $3F, $E0, $C5, $0F, $F8, $FF, $C2, $0C
	db $FF, $1C, $FF, $58, $BF, $B8, $7F, $30, $FF, $F0, $7F, $18, $3F, $3D, $30, $EF
	db $0C, $35, $EA, $2A, $E5, $03, $2F, $E2, $1F, $81, $98, $57, $DF, $C6, $FD, $0C
	db $CD, $FA, $D7, $F0, $0F, $FE, $C0, $0B, $BF, $87, $7F, $5E, $AF, $08, $BC, $5F
	db $78, $BF, $79, $2F, $06, $01, $01, $32, $E7, $02, $82, $01, $06, $FC, $7F, $E1
	db $03, $57, $03, $2B, $07, $57, $07, $AE, $07, $06, $07, $0F, $97, $01, $0E, $2C
	db $1B, $F0, $15, $F0, $2A, $E0, $75, $C0, $CB, $81, $83, $81, $03, $03, $07, $07
	db $F8, $3F, $30, $7F, $45, $E0, $F6, $01, $9D, $33, $35, $07, $FC, $35, $CB, $0D
	db $F8, $0A, $F8, $18, $F0, $10, $F0, $30, $E0, $F6, $0F, $5E, $0F, $AC, $1F, $5C
	db $1F, $9F, $3F, $40, $EA, $00, $0B, $F8, $B8, $60, $19, $F0, $12, $F0, $35, $E0
	db $EA, $C0, $01, $00, $03, $01, $51, $F8, $1F, $58, $3F, $91, $43, $E1, $5A, $83
	db $40, $5F, $55, $C1, $AB, $83, $D7, $5B, $0C, $0E, $0F, $1C, $1F, $FE, $01, $55
	db $41, $EB, $C1, $D5, $C1, $03, $C3, $62, $83, $01, $87, $83, $0A, $C9, $83, $C3
	db $AB, $8C, $F8, $08, $80, $63, $7B, $07, $AF, $07, $56, $06, $0F, $AE, $0F, $4C
	db $1F, $2B, $67, $38, $01, $3F, $B3, $06, $C9, $C7, $2F, $8C, $AB, $6A, $3F, $81
	db $1B, $A9, $83, $83, $AD, $9F, $AF, $06, $B6, $4B, $01, $1F, $CE, $6D, $25, $0E
	db $03, $24, $E0, $20, $03, $01, $60, $C0, $EF, $E0, $D5, $9C, $7B, $EF, $E6, $7B
	db $4D, $4D, $70, $D9, $F8, $04, $21, $0F, $FF, $B8, $5B, $06, $FD, $08, $FF, $0C
	db $FB, $18, $F7, $20, $FF, $30, $EF, $03, $7F, $18, $FF, $38, $FF, $70, $B6, $A9
	db $FB, $70, $04, $01, $0C, $F8, $72, $0C, $9D, $00, $9F, $0E, $0E, $0C, $0C, $08
	db $49, $08, $FB, $B6, $00, $F3, $F1, $00, $1F, $0E, $1E, $1E, $3E, $3C, $77, $3F
	db $51, $73, $5B, $FF, $CC, $A5, $02, $03, $29, $03, $FF, $09, $81, $AF, $A0, $E0
	db $E0, $C0, $C1, $BB, $01, $49, $5D, $AF, $9C, $33, $F0, $00, $1C, $D0, $F0, $90
	db $01, $30, $30, $E0, $01, $7F, $3F, $7C, $35, $7F, $60, $39, $1D, $01, $E1, $B6
	db $D7, $6B, $65, $33, $10, $F0, $B9, $41, $B0, $1F, $87, $07, $0E, $C9, $5D, $1F
	db $38, $69, $4E, $FE, $8C, $C5, $87, $EC, $47, $06, $E3, $17, $0E, $B0, $BB, $0F
	db $0C, $1D, $46, $0F, $93, $82, $E7, $41, $64, $63, $70, $16, $E3, $7F, $C4, $13
	db $FF, $FF, $68, $F3, $2B, $BF, $08, $08, $BF, $B0, $E0, $0E, $C9, $85, $0F, $6C
	db $5B, $2B, $7F, $7E, $7F, $04, $5B, $C3, $2B, $F6, $FC, $40, $D0, $03, $AB, $2B
	db $7E, $E0, $03, $5B, $84, $01, $14, $45, $10, $B9, $96, $5F, $13, $01, $01, $03
	db $49, $29, $53, $F8, $06, $5D, $0B, $FE, $B1, $7F, $1F, $DB, $67, $A1, $AB, $3C
	db $63, $7F, $F8, $B6, $67, $0F, $33, $0C, $1E, $43, $21, $83, $01, $61, $C0, $7F
	db $A7, $07, $00, $0F, $10, $0F, $C2, $FE, $C4, $FC, $C8, $19, $F8, $D0, $F0, $B9
	db $DF, $47, $41, $1E, $E5, $03, $B7, $00, $41, $8F, $06, $FC, $0C, $51, $4D, $07
	db $A0, $0F, $1D, $0F, $1F, $04, $1E, $1A, $1E, $3E, $1C, $60, $6F, $40, $BF, $80
	db $7F, $B6, $99, $80, $0F, $08, $F7, $04, $72, $FB, $9F, $1D, $A1, $80, $8F, $FE
	db $FF, $70, $8F, $38, $C7, $76, $E0, $8F, $E4, $00, $69, $1A, $3D, $A3, $03, $2F
	db $00, $0F, $3C, $3C, $7C, $38, $0B, $78, $78, $F8, $70, $2D, $7F, $B2, $2B, $90
	db $F0, $99, $0F, $F1, $40, $DB, $6B, $26, $1D, $7F, $E1, $7E, $70, $01, $6B, $90
	db $0F, $05, $FE, $00, $0B, $FC, $15, $EF, $2A, $DF, $54, $AF, $90, $0F, $B8, $7C
	db $08, $FC, $78, $53, $87, $89, $D3, $30, $0F, $A9, $18, $3C, $01, $39, $83, $87
	db $92, $3C, $23, $1F, $00, $20, $1E, $C0, $FE, $80, $FD, $82, $FC, $95, $40, $57
	db $80, $15, $60, $EA, $8A, $E2, $04, $84, $D5, $15, $55, $D5, $80, $1F, $35, $20
	db $A2, $2A, $2A, $39, $40, $55, $00, $2C, $A9, $34, $00, $20, $AA, $2A, $6A, $C0
	db $D5, $1B, $D1, $50, $17, $0F, $8A, $44, $00, $89, $AB, $AD, $A8, $49, $1D, $53
	db $51, $73, $57, $EF, $80, $11, $55, $80, $AA, $0A, $8A, $2C, $11, $54, $2F, $B8
	db $65, $1C, $22, $2C, $B1, $7C, $20, $C3, $F9, $38, $C0, $7F, $83, $FD, $E7, $D2
	db $18, $00, $26, $C4, $D5, $95, $55, $A1, $8B, $9A, $0B, $FE, $B3, $0C, $F3, $FA
	db $05, $90, $0A, $B0, $B5, $25, $B5, $20, $6A, $4D, $68, $4B, $80, $2F, $A4, $43
	db $46, $57, $54, $0D, $57, $04, $AF, $A8, $01, $2C, $6F, $FD, $FA, $07, $A4, $4F
	db $FE, $11, $D8, $07, $01, $03, $FC, $C1, $01, $9B, $60, $3F, $C0, $81, $72, $EA
	db $00, $D1, $00, $6A, $C7, $03, $AA, $05, $1A, $FE, $00, $BF, $31, $2A, $07, $B1
	db $00, $AE, $20, $3E, $80, $7F, $60, $1F, $90, $0F, $C8, $07, $E4, $03, $02, $01
	db $ED, $00, $07, $F8, $06, $4D, $7D, $80, $03, $76, $AF, $4B, $1D, $D0, $91, $09
	db $EA, $87, $84, $C0, $F8, $07, $C0, $CC, $01, $FB, $0F, $04, $01, $FE, $02, $1B
	db $29, $E0, $1F, $57, $B3, $38, $E0, $7B, $31, $04, $4B, $01, $2F, $F0, $0F, $3C
	db $C3, $15, $EA, $8C, $9F, $05, $FA, $0D, $49, $5D, $B6, $30, $42, $BD, $40, $BF
	db $20, $DF, $F5, $00, $EF, $00, $7E, $81, $BC, $43, $79, $86, $B3, $4C, $77, $88
	db $A7, $58, $E7, $18, $9E, $60, $70, $80, $8F, $A6, $18, $50, $03, $20, $A6, $40
	db $5F, $80, $FC, $B0, $88, $01, $00, $06, $0E, $F8, $19, $06, $04, $6D, $A1, $09
	db $45, $8C, $35, $A0, $5F, $01, $50, $06, $2F, $D0, $2F, $70, $8F, $01, $F1, $02
	db $F5, $04, $FB, $00, $09, $30, $CF, $60, $9F, $7D, $80, $09, $EC, $65, $25, $EA
	db $B6, $4D, $F0, $95, $7F, $C0, $2D, $25, $DA, $0A, $F5, $55, $12, $AA, $0B, $F4
	db $67, $97, $65, $7F, $46, $20, $FC, $3C, $E7, $00, $04, $AF, $70, $18, $0F, $CC
	db $03, $4F, $18, $E7, $C6, $F5, $0E, $F1, $F3, $8D, $4D, $AE, $41, $18, $6E, $91
	db $CC, $33, $1D, $E2, $19, $E6, $BB, $44, $EB, $14, $01, $33, $0C, $5C, $F6, $71
	db $08, $CD, $30, $9B, $60, $B7, $40, $3F, $C0, $6D, $82, $7A, $84, $71, $8C, $7E
	db $A1, $00, $80, $40, $03, $3C, $00, $F0, $00, $0C, $E3, $00, $B0, $4F, $AB, $60
	db $01, $1F, $20, $1F, $10, $0F, $00, $0F, $A5, $C1, $A1, $3F, $01, $83, $AD, $08
	db $F7, $10, $EF, $15, $5D, $1C, $E3, $1E, $15, $01, $01, $37, $3C, $C3, $6F, $A0
	db $12, $0F, $D9, $40, $78, $BF, $04, $1F, $B2, $0C, $3C, $70, $8E, $04, $21, $67
	db $01, $98, $E6, $19, $66, $19, $75, $8A, $97, $8F, $1E, $0C, $E0, $0A, $F0, $0B
	db $F0, $D4, $08, $A8, $10, $51, $20, $2E, $34, $40, $30, $1F, $C0, $15, $72, $8D
	db $06, $44, $01, $8E, $4D, $1C, $00, $C6, $39, $9B, $F1, $F1, $0C, $53, $BC, $20
	db $A0, $A1, $90, $0F, $88, $B4, $1D, $F5, $FF, $02, $82, $ED, $17, $E0, $7C, $83
	db $06, $0B, $21, $C0, $CD, $C4, $78, $C1, $3E, $68, $F9, $C1, $41, $3E, $C1, $58
	db $27, $83, $2F, $D0, $0F, $74, $83, $4B, $09, $04, $57, $03, $FC, $06, $F9, $30
	db $D1, $01, $60, $9F, $C0, $7E, $3F, $10, $7F, $90, $BB, $02, $FD, $05, $06, $F8
	db $0C, $F0, $06, $69, $4F, $40, $6F, $E0, $1F, $0C, $76, $03, $D9, $01, $00, $8E
	db $00, $DF, $00, $05, $F8, $1A, $65, $00, $95, $60, $1F, $18, $07, $BE, $1A, $01
	db $61, $9E, $51, $17, $01, $4D, $20, $9F, $30, $8F, $5C, $83, $0E, $C1, $7C, $80
	db $BA, $40, $5D, $A0, $2E, $D0, $17, $E8, $2B, $D4, $15, $EA, $0B, $F4, $45, $02
	db $02, $01, $01, $70, $81, $00, $40, $00, $A0, $00, $D0, $00, $A8, $00, $F0, $0F
	db $88, $97, $D2, $63, $60, $D5, $D3, $1E, $E1, $38, $C7, $7F, $C0, $03, $72, $A5
	db $BD, $07, $6F, $61, $06, $80, $E7, $42, $BD, $81, $7E, $C0, $27, $A0, $5F, $14
	db $EB, $0A, $1B, $F5, $0D, $F2, $CD, $01, $23, $45, $BA, $A3, $5C, $73, $8C, $66
	db $1F, $1B, $77, $E0, $CB, $1B, $00, $00, $45, $67, $9F, $01, $06, $A1, $BD, $29
	db $E0, $06, $11, $02, $DD, $00, $BF, $F8, $0A, $85, $F1, $02, $01, $66, $99, $ED
	db $06, $1D, $EF, $E3, $06, $0F, $22, $CD, $D9, $14, $3D, $01, $D0, $D1, $B3, $74
	db $58, $80, $33, $C0, $6E, $80, $54, $88, $2C, $90, $1E, $A0, $08, $07, $F4, $03
	db $0E, $01, $1A, $E1, $05, $00, $03, $00, $79, $00, $FC, $00, $F4, $04, $99, $0B
	db $01, $50, $AF, $86, $20, $DF, $94, $6B, $CA, $35, $64, $9B, $72, $8D, $30, $CF
	db $01, $75, $7C, $62, $75, $74, $33, $DF, $03, $E1, $B0, $4F, $7C, $80, $11, $08
	db $1F, $E0, $80, $25, $02, $FC, $06, $F8, $0D, $F0, $8D, $45, $2A, $BA, $1F, $F2
	db $7D, $7D, $04, $4F, $12, $21, $08, $A8, $2F, $D0, $51, $03, $03, $10, $EF, $28
	db $D7, $34, $CB, $DA, $04, $1F, $13, $26, $9F, $26, $9B, $E3, $1D, $E0, $1E, $E0
	db $37, $C0, $21, $C0, $60, $80, $1A, $24, $51, $2E, $D0, $2F, $80, $85, $58, $27
	db $A9, $16, $DD, $02, $07, $E6, $01, $7E, $00, $3D, $60, $F7, $46, $80, $23, $C0
	db $02, $91, $60, $C8, $30, $F4, $08, $40, $6F, $48, $07, $24, $03, $1D, $92, $01
	db $C1, $83, $D5, $31, $CE, $79, $86, $17, $15, $D0, $20, $3C, $86, $60, $0F, $E0
	db $2F, $C0, $C7, $00, $98, $67, $8C, $73, $8F, $70, $87, $78, $83, $7C, $03, $7C
	db $43, $3C, $A3, $1C, $AB, $7D, $06, $82, $EA, $15, $95, $6A, $AD, $00, $05, $F8
	db $0B, $F0, $3D, $C2, $AB, $54, $CE, $63, $C0, $81, $E1, $60, $00, $E1, $53, $85
	db $87, $B7, $1E, $01, $03, $54, $41, $3C, $00, $76, $7E, $88, $32, $5F, $00, $A3
	db $14, $E1, $EB, $1A, $E5, $9D, $62, $4E, $31, $1D, $02, $0E, $01, $87, $4C, $CF
	db $B9, $08, $11, $F7, $90, $6F, $5C, $57, $03, $10, $7E, $EF, $06, $5F, $87, $DB
	db $8F, $04, $01, $19, $E6, $06, $06, $0F, $04, $FB, $63, $9C, $A3, $25, $0C, $F3
	db $1A, $55, $03, $52, $FD, $F0, $06, $00, $38, $C0, $FC, $00, $A5, $01, $E3, $1C
	db $39, $00, $1E, $00, $07, $DA, $8B, $4C, $00, $1B, $7A, $3A, $84, $FF, $5D, $4B
	db $9F, $50, $F5, $77, $00, $1B, $00, $13, $0D, $00, $20, $67, $17, $33, $E0, $09
	db $35, $F8, $00, $41, $B5, $08, $07, $15, $ED, $C6, $35, $19, $06, $1B, $07, $3F
	db $00, $C8, $07, $67, $36, $43, $47, $4D, $D7, $61, $3D, $13, $0C, $97, $08, $6D
	db $92, $9C, $63, $3A, $C1, $80, $61, $5F, $20, $CF, $30, $7B, $84, $76, $88, $E5
	db $18, $EE, $10, $55, $82, $03, $F7, $08, $CB, $34, $11, $4B, $2E, $0B, $50, $90
	db $0B, $D5, $00, $AB, $00, $14, $2F, $00, $17, $61, $C1, $EB, $50, $20, $60, $80
	db $9D, $EF, $C3, $A2, $17, $A4, $02, $3C, $C0, $37, $93, $A3, $4A, $27, $BF, $22
	db $17, $50, $E3, $40, $7C, $1F, $02, $1F, $65, $02, $FD, $08, $1D, $6B, $29, $B9
	db $F9, $00, $09, $BE, $41, $47, $80, $83, $00, $09, $82, $01, $44, $80, $54, $2B
	db $0C, $F0, $1D, $18, $E0, $23, $9C, $9D, $8F, $F7, $71, $80, $AB, $3F, $CC, $59
	db $CD, $CF, $39, $00, $BC, $C1, $9C, $C7, $E0, $0D, $EA, $78, $58, $11, $3C, $E0
	db $E5, $70, $80, $BC, $01, $40, $6E, $10, $17, $08, $8B, $04, $53, $BB, $44, $8D
	db $00, $E4, $BF, $EA, $00, $73, $7C, $23, $09, $84, $06, $01, $01, $E1, $31, $60
	db $00, $98, $C7, $13, $7E, $61, $33, $71, $00, $30, $C2, $0F, $30, $CF, $E1, $69
	db $86, $7A, $84, $B6, $48, $E7, $18, $FB, $04, $7D, $82, $B0, $F1, $7D, $88, $77
	db $47, $04, $38, $24, $18, $23, $1C, $56, $77, $E5, $E0, $1F, $C5, $3A, $E2, $1D
	db $51, $AE, $E8, $17, $F4, $0B, $FA, $05, $6D, $82, $36, $C1, $FD, $02, $B0, $C4
	db $DE, $BB, $40, $56, $18, $A1, $25, $C2, $39, $AB, $44, $8B, $E0, $95, $83, $41
	db $80, $8E, $00, $6E, $B8, $89, $28, $09, $07, $7F, $F0, $58, $00, $6F, $20, $00
	db $0F, $A0, $0F, $D0, $0F, $50, $0F, $30, $3A, $0F, $B0, $E9, $0F, $D0, $D0, $15
	db $10, $58, $EF, $F9, $46, $3A, $B9, $2F, $B8, $7B, $03, $5F, $A0, $8B, $E3, $3B
	db $10, $61, $9E, $6B, $87, $01, $86, $F3, $04, $9B, $04, $63, $1C, $03, $FC, $D3
	db $2C, $99, $66, $13, $71, $DE, $F7, $D8, $C7, $03, $DA, $31, $F7, $9D, $97, $68
	db $72, $AE, $51, $B7, $48, $B2, $4D, $A1, $4E, $A2, $4D, $01, $4E, $B8, $40, $40
	db $B0, $A1, $50, $4F, $B0, $C0, $3B, $6C, $90, $D0, $20, $E0, $E0, $EB, $BF, $00
	db $BD, $01, $02, $7B, $84, $E6, $18, $C8, $30, $8C, $E1, $12, $21, $89, $43, $02
	db $80, $8C, $03, $20, $1F, $40, $AF, $45, $9D, $D3, $07, $71, $A7, $11, $E0, $04
	db $81, $6C, $FC, $02, $FC, $3D, $C2, $97, $F1, $11, $2C, $00, $C8, $00, $60, $80
	db $B0, $40, $98, $60, $58, $20, $5C, $20, $0C, $30, $7D, $80, $7E, $80, $BF, $2C
	db $40, $01, $5B, $24, $4E, $31, $03, $3C, $20, $D6, $0E, $8D, $A0, $00, $54, $F8
	db $E7, $F5, $00, $FA, $05, $00, $3D, $C0, $C7, $38, $A9, $3F, $88, $17, $88, $13
	db $C3, $9D, $78, $07, $0C, $A2, $5B, $0E, $11, $C0, $80, $6F, $F8, $07, $FE, $01
	db $8F, $91, $13, $81, $7E, $00, $77, $04, $03, $3B, $C0, $19, $06, $E0, $0C, $F0
	db $8E, $70, $39, $8D, $5F, $80, $2E, $52, $8C, $D3, $0C, $15, $08, $CB, $01, $17
	db $87, $08, $97, $08, $F3, $0C, $F9, $06, $C5, $00, $CA, $00, $95, $67, $E7, $1F
	db $6C, $E3, $01, $9A, $5A, $00, $1C, $6F, $40, $5B, $CC, $BF, $EB, $07, $0F, $1C
	db $28, $07, $14, $5F, $1D, $39, $06, $C2, $75, $95, $C0, $51, $17, $64, $03, $46
	db $61, $E9, $0C, $FD, $02, $7E, $81, $B1, $56, $11, $A9, $AA, $55, $70, $49, $EB
	db $14, $F1, $0E, $02, $A9, $56, $51, $AE, $29, $D6, $28, $B1, $C1, $01, $DE, $00
	db $FD, $00, $24, $03, $51, $A1, $AE, $03, $31, $92, $4D, $25, $5A, $82, $7D, $95
	db $6A, $CB, $34, $DF, $20, $DD, $22, $DA, $25, $3B, $25, $15, $00, $9B, $D7, $28
	db $AB, $54, $45, $BA, $8B, $1D, $74, $21, $1E, $41, $69, $00, $38, $56, $01, $6C
	db $FA, $05, $D5, $2A, $E0, $1F, $82, $27, $3F, $C0, $7F, $80, $18, $0B, $61, $54
	db $AB, $8E, $E0, $71, $E3, $F6, $09, $AE, $51, $0C, $4E, $B1, $A7, $58, $E7, $0E
	db $10, $30, $AE, $10, $01, $0D, $AF, $10, $D7, $08, $25, $70, $9E, $61, $2C, $13
	db $0F, $10, $93, $0C, $90, $0F, $96, $09, $C0, $DF, $6F, $10, $1E, $E1, $71, $6D
	db $8E, $03, $FB, $8B, $93, $3C, $C3, $96, $0A, $F4, $04, $F8, $C3, $3C, $D4, $00
	db $3A, $C0, $8C, $70, $CA, $30, $78, $80, $98, $60, $74, $08, $91, $F0, $00, $52
	db $4E, $43, $02, $00, $00, $02, $40, $00, $00, $01, $47, $37, $4B, $C2, $7E, $02
	db $01, $1E, $A4, $1B, $00, $3C, $B7, $B8, $13, $1C, $92, $5C, $93, $7C, $94, $95
	db $96, $97, $98, $99, $9A, $9B, $9C, $9D, $9E, $9F, $A0, $A1, $A2, $A3, $06, $1F
	db $A5, $5C, $A6, $7C, $A7, $A8, $A9, $AA, $AB, $AC, $AD, $AE, $AF, $B0, $B1, $B2
	db $B3, $B4, $B5, $B6, $06, $1F, $B9, $B8, $FA, $BA, $BB, $BC, $BD, $BE, $BF, $C0
	db $C1, $C2, $C3, $C4, $C5, $C6, $C7, $C8, $C9, $07, $5F, $E3, $CA, $CB, $CC, $CD
	db $CE, $CF, $D0, $D1, $D2, $D3, $D4, $D5, $D6, $D7, $D8, $D9, $E1, $08, $7F, $DA
	db $DB, $DC, $70, $DD, $DE, $DF, $E0, $E1, $E2, $E3, $E4, $E5, $E6, $E7, $E8, $F0
	db $12, $A8, $E9, $EA, $EB, $1E, $EC, $ED, $EE, $0B, $18, $07, $EF, $F0, $F1, $F2
	db $F3, $01, $07, $F4, $F5, $F6, $F7, $F8, $E3, $0A, $1E, $F9, $FA, $00, $03, $FB
	db $FC, $FD, $FE, $A4, $FF, $00, $1E, $01, $02, $03, $0E, $5B, $2E, $04, $05, $1E
	db $06, $07, $08, $A4, $09, $0A, $0B, $0C, $0D, $0E, $0F, $10, $09, $1E, $38, $11
	db $12, $04, $13, $00, $14, $15, $16, $17, $18, $19, $1A, $1B, $78, $1C, $04, $1A
	db $1D, $1E, $71, $1F, $93, $20, $70, $21, $22, $23, $24, $21, $25, $26, $27, $28
	db $29, $2A, $2B, $F0, $05, $3A, $2C, $2D, $2E, $10, $2F, $30, $31, $09, $40, $32
	db $04, $33, $34, $3C, $35, $36, $05, $C3, $37, $00, $38, $39, $3A, $3B, $3C, $3D
	db $21, $3E, $38, $3F, $40, $0D, $41, $07, $42, $43, $44, $45, $46, $80, $04, $1F
	db $47, $48, $49, $4A, $4B, $4C, $38, $4D, $4E, $0A, $4F, $00, $50, $51, $52, $53
	db $54, $55, $56, $57, $F5, $04, $1F, $CB, $58, $59, $5A, $5B, $5C, $5D, $5E, $5F
	db $60, $61, $62, $63, $64, $65, $66, $67, $68, $69, $6A, $6B, $D7, $04, $1F, $2F
	db $6C, $6D, $6E, $6F, $70, $71, $72, $73, $74, $75, $76, $77, $78, $79, $7A, $7B
	db $7C, $7D, $7E, $7F, $04, $78, $1F, $00, $52, $4E, $43, $02, $00, $00, $02, $E0
	db $00, $00, $02, $46, $23, $58, $4A, $7E, $04, $01, $0B, $00, $00, $A6, $01, $01
	db $02, $03, $03, $02, $07, $04, $0B, $0C, $0D, $0A, $1B, $16, $3F, $20, $5F, $60
	db $7E, $4D, $AB, $DD, $FF, $99, $7F, $7F, $33, $33, $1D, $00, $C7, $C7, $EF, $28
	db $FF, $38, $BF, $73, $66, $FF, $01, $60, $01, $19, $7F, $CC, $FF, $01, $99, $C7
	db $01, $33, $06, $01, $FF, $66, $66, $1F, $2E, $87, $87, $78, $CF, $48, $FF, $30
	db $FF, $26, $FF, $27, $FE, $4E, $FC, $CC, $FC, $9C, $F9, $99, $FE, $3F, $FF, $32
	db $FD, $06, $FF, $8C, $3F, $39, $39, $C0, $1F, $86, $86, $CF, $49, $F7, $30, $39
	db $FD, $3D, $E3, $DF, $E3, $06, $6F, $53, $DB, $B6, $FF, $19, $01, $04, $F7, $6C
	db $5F, $E8, $FF, $C8, $8C, $3F, $9B, $9B, $1F, $3C, $02, $3C, $7E, $42, $FF, $C1
	db $F7, $0E, $53, $32, $38, $01, $64, $01, $C9, $00, $EF, $99, $DF, $30, $BF, $70
	db $EF, $EF, $D8, $7B, $1F, $7E, $7E, $39, $FF, $81, $01, $97, $53, $3F, $18, $F0
	db $70, $F0, $10, $D8, $38, $F0, $F0, $E0, $E0, $C0, $C0, $E0, $20, $F0, $30, $6D
	db $09, $1F, $BA, $83, $B9, $0F, $08, $1F, $13, $00, $01, $3F, $27, $3E, $26, $7E
	db $4E, $7C, $1C, $4C, $FF, $9F, $4B, $01, $82, $7F, $46, $3F, $3F, $1C, $1C, $8E
	db $1F, $CC, $CC, $38, $A9, $13, $9F, $E6, $0E, $7F, $4C, $7F, $40, $67, $49, $9F
	db $33, $1C, $9F, $66, $67, $18, $FF, $CD, $CD, $1F, $C6, $C6, $30, $EF, $29, $9F
	db $FF, $71, $FF, $63, $63, $9F, $EF, $D3, $CD, $01, $9F, $E9, $85, $21, $9F, $33
	db $33, $88, $37, $FF, $C0, $7B, $37, $02, $9F, $8E, $01, $93, $0C, $01, $FF, $36
	db $36, $1F, $78, $05, $78, $FD, $85, $FF, $83, $01, $1B, $04, $FF, $0C, $FF, $F9
	db $AE, $01, $18, $DF, $D2, $9F, $92, $BD, $A6, $3E, $27, $1F, $1F, $0C, $0C, $1F
	db $CF, $CF, $03, $FE, $31, $FF, $20, $FF, $4C, $9E, $01, $04, $E3, $18, $09, $FF
	db $19, $3F, $F3, $F3, $81, $5F, $FF, $CC, $D9, $55, $89, $B8, $F3, $A5, $03, $B8
	db $68, $FF, $07, $FE, $46, $FF, $CF, $BF, $CB, $FF, $90, $F7, $98, $1F, $C1, $7F
	db $3D, $3D, $FB, $C6, $81, $CD, $FF, $34, $FF, $3C, $FF, $B3, $A5, $13, $90, $8E
	db $77, $26, $3B, $01, $4C, $66, $87, $4E, $99, $1F, $DE, $A3, $01, $93, $07, $92
	db $FF, $12, $FF, $24, $1C, $01, $49, $01, $A1, $9F, $B6, $B6, $00, $9F, $FC, $84
	db $FE, $82, $AD, $AF, $80, $5B, $0E, $FC, $FC, $F8, $F8, $C0, $39, $C0, $80, $00
	db $A4, $19, $00, $23, $01, $01, $1A, $FB, $0F, $09, $01, $B3, $43, $26, $76, $01
	db $27, $00, $4C, $BF, $C1, $5F, $63, $3F, $3F, $1E, $60, $1E, $1F, $E7, $E7, $DF
	db $38, $28, $EF, $18, $4F, $20, $E3, $01, $4F, $5C, $01, $31, $FC, $9C, $F8, $98
	db $F9, $39, $F1, $31, $F0, $F0, $60, $60, $1F, $9F, $9F, $D0, $17, $20, $A0, $5F
	db $67, $FF, $E7, $38, $FF, $CE, $01, $9C, $E6, $01, $AB, $06, $39, $F7, $F7, $63
	db $63, $1F, $38, $B3, $B3, $AB, $48, $A4, $3F, $95, $B7, $86, $07, $7F, $82, $BF
	db $D5, $C8, $D2, $3C, $C3, $9F, $BF, $73, $DF, $18, $3B, $22, $FB, $1B, $44, $FF
	db $8C, $9F, $91, $CE, $49, $EF, $DD, $23, $B3, $A1, $E2, $CC, $F3, $01, $3F, $4D
	db $00, $77, $FD, $CD, $FC, $E4, $FE, $E6, $BE, $1D, $A6, $FE, $CE, $02, $67, $1C
	db $F8, $38, $5B, $FF, $6D, $00, $CB, $D1, $0B, $D3, $3D, $D1, $06, $00, $E0, $00
	db $52, $4E, $43, $02, $00, $00, $03, $C0, $00, $00, $02, $26, $CE, $BF, $63, $20
	db $04, $01, $0B, $00, $FF, $2E, $01, $F8, $01, $FE, $02, $FD, $05, $FA, $0A, $F5
	db $15, $EA, $2B, $D4, $57, $A8, $AF, $50, $5E, $A0, $BD, $40, $7A, $80, $F5, $00
	db $EA, $00, $D4, $00, $A8, $00, $50, $00, $A0, $00, $40, $00, $80, $00, $14, $EB
	db $25, $21, $DE, $D8, $25, $29, $10, $EF, $06, $09, $F6, $42, $BD, $5F, $25, $60
	db $42, $2D, $2F, $D0, $5B, $A4, $C0, $31, $7E, $81, $AB, $54, $EB, $06, $00, $FD
	db $00, $DE, $00, $35, $01, $FA, $00, $EF, $00, $F6, $00, $BD, $C7, $35, $42, $07
	db $3D, $D0, $00, $A4, $03, $41, $81, $00, $54, $00, $D2, $03, $00, $7A, $77, $01
	db $00, $4F, $4F, $02, $49, $0F, $4F, $E9, $02, $0F, $3D, $4F, $02, $00, $31, $4F
	db $E3, $08, $70, $C9, $11, $91, $01, $89, $11, $11, $33, $33, $06, $87, $3C, $C5
	db $4F, $F3, $02, $C3, $E3, $02, $F3, $06, $E7, $04, $E7, $0C, $CF, $08, $CF, $18
	db $06, $0F, $C3, $18, $99, $33, $0F, $0C, $C7, $1C, $9F, $30, $1F, $07, $50, $7C
	db $0F, $31, $F9, $1A, $03, $C3, $12, $27, $40, $2F, $F9, $01, $E1, $09, $02, $C9
	db $13, $93, $00, $01, $67, $18, $33, $0F, $C1, $0F, $C0, $35, $9F, $00, $87, $30
	db $F3, $E4, $45, $13, $2F, $E1, $12, $0F, $33, $22, $39, $2F, $81, $4D, $21, $5B
	db $9F, $10, $90, $53, $FF, $7F, $05, $19, $99, $03, $83, $32, $9C, $1F, $5F, $21
	db $11, $99, $5F, $C2, $25, $0F, $78, $49, $E3, $28, $59, $8F, $FF, $E2, $0F, $FF
	db $60, $FE, $00, $FF, $FF, $FF, $FD, $04, $10, $02, $00, $01, $00, $ED, $02, $00
	db $05, $00, $0A, $00, $15, $00, $2B, $00, $57, $00, $AF, $00, $5E, $01, $BD, $02
	db $7A, $05, $F5, $0A, $EA, $15, $D4, $2B, $A8, $57, $50, $AF, $A0, $5F, $40, $BF
	db $80, $7F, $FB, $02, $B5, $DC, $09, $01, $8F, $79, $09, $01, $91, $66, $CF, $8F
	db $03, $43, $9F, $CF, $88, $1F, $1B, $16, $B9, $3F, $20, $C7, $0F, $D9, $11, $04
	db $B1, $31, $31, $23, $93, $0F, $30, $FF, $3C, $1F, $3F, $00, $03, $7B, $7E, $05
	db $0F, $2C, $01, $60, $3F, $C4, $2F, $3D, $21, $9E, $2F, $01, $6D, $07, $26, $27
	db $24, $27, $6C, $67, $2F, $03, $E4, $01, $7D, $00, $B0, $5F, $F9, $03, $F3, $AC
	db $91, $27, $11, $0C, $8F, $38, $BB, $05, $3B, $6D, $06, $02, $4F, $20, $39, $21
	db $39, $63, $5A, $15, $42, $8F, $39, $03, $00, $6F, $DD, $01, $C9, $01, $81, $CE
	db $51, $33, $50, $AF, $BF, $DD, $11, $C0, $11, $89, $09, $89, $23, $23, $9A, $0F
	db $B4, $6F, $D5, $AF, $A1, $6F, $0F, $C3, $51, $07, $3C, $D4, $01, $9F, $1F, $61
	db $35, $9F, $00, $89, $3B, $E8, $03, $1F, $2B, $71, $63, $31, $9F, $03, $99, $E7
	db $00, $6C, $FF, $81, $5A, $27, $25, $2B, $A9, $CF, $CF, $A0, $2F, $CF, $04, $87
	db $1F, $24, $4B, $0D, $48, $24, $BF, $99, $8D, $2D, $8C, $9D, $02, $03, $11, $64
	db $36, $77, $44, $0F, $9B, $1B, $C9, $03, $E3, $DD, $03, $57, $12, $93, $10, $11
	db $77, $D0, $01, $0F, $51, $A8, $7F, $2A, $C1, $13, $1C, $2F, $18, $E1, $AD, $4F
	db $F1, $07, $F5, $29, $4F, $F4, $02, $0F, $A7, $4F, $D2, $02, $0F, $9F, $4F, $02
	db $4A, $00, $7D, $4F, $02, $00, $E0, $00, $52, $4E, $43, $02, $00, $00, $01, $C0
	db $00, $00, $00, $69, $0F, $C0, $8F, $59, $02, $01, $03, $5D, $5E, $5F, $60, $C1
	db $05, $00, $44, $45, $46, $5C, $E7, $03, $00, $4B, $83, $07, $00, $4C, $4D, $4E
	db $4F, $DE, $04, $1F, $06, $3C, $C1, $00, $47, $48, $49, $4A, $E7, $04, $1F, $7B
	db $83, $07, $00, $7C, $7D, $7E, $7F, $DE, $04, $1F, $F7, $00, $76, $5C, $6E, $8D
	db $32, $59, $57, $50, $70, $51, $52, $53, $54, $55, $56, $57, $58, $59, $5A, $5B
	db $5C, $8C, $98, $61, $5C, $62, $FF, $63, $64, $65, $66, $67, $68, $69, $6A, $6B
	db $6C, $6D, $6E, $6F, $70, $71, $72, $73, $74, $75, $76, $77, $78, $79, $7A, $01
	db $78, $47, $00, $52, $4E, $43, $02, $00, $00, $05, $40, $00, $00, $02, $A6, $BA
	db $C7, $F5, $84, $04, $01, $2E, $3B, $01, $01, $03, $03, $05, $07, $0B, $0D, $17
	db $19, $2F, $31, $5E, $61, $BF, $C0, $01, $6D, $05, $09, $0D, $B6, $11, $15, $19
	db $CF, $1D, $00, $01, $08, $00, $E0, $E0, $20, $38, $02, $20, $05, $E0, $F2, $02
	db $15, $FF, $41, $01, $39, $FF, $35, $4C, $01, $07, $31, $E5, $01, $01, $13, $F0
	db $00, $C0, $00, $C1, $60, $1F, $ED, $FF, $8D, $E4, $01, $8C, $05, $E6, $0F, $F8
	db $E0, $39, $07, $00, $3E, $13, $01, $FD, $02, $03, $1F, $33, $FF, $6B, $FF, $63
	db $90, $03, $01, $DC, $0B, $1D, $70, $0F, $15, $63, $9C, $26, $AD, $52, $1F, $1C
	db $CC, $FF, $1A, $01, $50, $DA, $05, $CC, $FF, $98, $77, $98, $67, $26, $6B, $94
	db $1F, $1E, $F0, $FF, $60, $03, $01, $28, $00, $97, $15, $C7, $0B, $38, $6F, $90
	db $C7, $26, $81, $01, $F6, $08, $00, $81, $13, $FE, $01, $FF, $78, $05, $0C, $1F
	db $ED, $12, $C6, $85, $AF, $50, $01, $DE, $49, $0E, $1F, $C6, $81, $68, $97, $03
	db $C7, $01, $9B, $64, $B1, $0E, $1F, $37, $EF, $10, $A1, $03, $01, $EC, $0E, $1F
	db $11, $E1, $EC, $25, $CF, $38, $00, $C3, $07, $F9, $E3, $09, $C3, $D9, $07, $AF
	db $01, $24, $E1, $03, $01, $04, $00, $8C, $C6, $11, $E3, $D9, $38, $00, $87, $01
	db $07, $E6, $01, $0D, $5C, $3D, $39, $00, $18, $00, $98, $00, $32, $00, $90, $00
	db $92, $00, $12, $07, $58, $19, $00, $0C, $0E, $00, $C6, $00, $E6, $39, $01, $FF
	db $51, $81, $55, $C9, $00, $49, $00, $43, $C8, $03, $43, $01, $1F, $26, $6F, $67
	db $01, $CF, $0B, $27, $03, $67, $01, $4F, $8F, $BF, $09, $7F, $16, $38, $3F, $03
	db $01, $81, $3B, $00, $80, $3B, $EB, $E0, $7A, $D5, $0A, $1F, $0E, $83, $EF, $3B
	db $17, $7F, $3F, $D1, $07, $0C, $7B, $1F, $17, $5F, $D0, $18, $7F, $00, $B8, $ED
	db $01, $00, $06, $00, $09, $00, $14, $03, $28, $07, $20, $0F, $40, $1F, $50, $0F
	db $05, $09, $9C, $0D, $09, $15, $71, $01, $73, $78, $D8, $29, $60, $1F, $B9, $64
	db $08, $F0, $15, $E2, $08, $E7, $03, $E0, $10, $E0, $04, $F8, $41, $B8, $82, $30
	db $84, $02, $49, $86, $15, $87, $9C, $51, $58, $D9, $0B, $C3, $BF, $99, $09, $1F
	db $07, $99, $D8, $67, $41, $28, $08, $12, $41, $24, $13, $67, $17, $D5, $1E, $67
	db $99, $06, $0B, $DA, $40, $3F, $8E, $81, $7E, $03, $FC, $04, $F9, $3A, $C1, $44
	db $03, $92, $25, $2C, $83, $44, $83, $15, $53, $E1, $7F, $3B, $39, $60, $0C, $7D
	db $28, $C0, $14, $5B, $F0, $0D, $02, $F8, $0A, $F0, $05, $B3, $09, $0D, $90, $89
	db $15, $80, $00, $A0, $14, $01, $1C, $00, $15, $03, $07, $14, $00, $10, $2F, $10
	db $B0, $08, $BB, $9D, $17, $00, $20, $00, $18, $45, $92, $20, $55, $4D, $92, $00
	db $F4, $0D, $DF, $00, $13, $80, $66, $40, $2A, $23, $5C, $F1, $0C, $1F, $1E, $00
	db $12, $8C, $AB, $06, $44, $00, $AA, $3A, $C4, $26, $3C, $7F, $80, $0A, $3F, $10
	db $E0, $5F, $00, $D0, $80, $03, $50, $64, $90, $10, $08, $FC, $F7, $0D, $3F, $86
	db $0A, $00, $45, $45, $6D, $01, $33, $6D, $55, $01, $55, $F3, $09, $6A, $03, $B0
	db $52, $00, $77, $73, $07, $24, $24, $27, $22, $21, $06, $00, $00, $08, $00, $DB
	db $76, $3E, $DE, $73, $3E, $07, $3A, $0B, $F7, $18, $9C, $C1, $1F, $4B, $4B, $21
	db $4A, $4A, $03, $BD, $00, $07, $3F, $10, $26, $F0, $C0, $06, $97, $93, $54, $54
	db $97, $39, $92, $51, $00, $E8, $0E, $7F, $10, $39, $7A, $7A, $05, $70, $45, $81
	db $02, $02, $73, $03, $02, $9C, $03, $00, $F1, $08, $29, $27, $26, $80, $03, $26
	db $26, $69, $29, $A9, $69, $31, $E9, $A9, $04, $A6, $26, $E3, $08, $1F, $33, $33
	db $39, $03, $73, $AD, $21, $00, $23, $23, $E3, $08, $1F, $97, $96, $00, $03, $39
	db $38, $A5, $A5, $B9, $B8, $A4, $E1, $00, $25, $25, $EE, $0A, $89, $38, $B4, $C0
	db $03, $80, $71, $40, $00, $C0, $FB, $09, $5F, $C0, $00, $52, $4E, $43, $02, $00
	db $00, $02, $70, $00, $00, $01, $88, $5B, $B7, $F0, $1A, $02, $01, $0F, $FF, $00
	db $02, $07, $01, $FB, $07, $B2, $7C, $81, $03, $0F, $0F, $E8, $F0, $1B, $07, $ED
	db $03, $0F, $02, $CF, $03, $03, $03, $0F, $F0, $17, $0F, $D8, $E0, $C1, $04, $3F
	db $DF, $E0, $4D, $3E, $65, $0B, $DF, $FD, $03, $FE, $04, $FB, $09, $F3, $17, $FF
	db $01, $FC, $0E, $E2, $31, $97, $CF, $5C, $3F, $70, $FF, $C0, $FF, $02, $FD, $A5
	db $C3, $5F, $3F, $F8, $FF, $80, $FF, $06, $F9, $29, $D0, $19, $E0, $B3, $40, $28
	db $50, $F0, $30, $61, $18, $9E, $92, $0C, $01, $3C, $00, $B0, $60, $F0, $0F, $07
	db $09, $06, $66, $00, $CD, $80, $01, $0F, $C6, $39, $29, $10, $D9, $00, $32, $92
	db $01, $0F, $0F, $81, $0F, $19, $E6, $26, $C0, $8C, $01, $49, $86, $4F, $FA, $30
	db $FC, $1F, $64, $FF, $98, $67, $03, $64, $03, $65, $02, $0A, $05, $60, $5A, $68
	db $47, $8C, $E9, $F3, $60, $3A, $76, $FF, $03, $FF, $A0, $58, $5F, $8F, $BF, $01
	db $C0, $7F, $20, $DF, $90, $CF, $E8, $63, $0F, $7F, $1C, $8D, $80, $BF, $00, $F0
	db $07, $DD, $FF, $EE, $2F, $18, $CC, $5F, $38, $28, $BF, $F0, $1A, $BF, $A0, $7F
	db $DC, $18, $DE, $B3, $AF, $50, $F0, $02, $E4, $52, $A0, $B0, $1A, $40, $F9, $00
	db $BD, $C0, $0F, $64, $00, $99, $60, $3C, $09, $F0, $02, $0F, $18, $38, $00, $93
	db $01, $6C, $58, $93, $0F, $12, $01, $01, $27, $00, $20, $00, $DF, $20, $60, $0F
	db $48, $87, $9D, $05, $02, $83, $00, $7C, $83, $80, $0F, $94, $0B, $3A, $05, $3F
	db $1F, $00, $C0, $3F, $03, $87, $46, $FF, $EA, $15, $AE, $02, $0B, $3E, $77, $F4
	db $33, $FA, $1C, $FB, $09, $FD, $0F, $FD, $05, $FE, $07, $FF, $07, $FF, $08, $AF
	db $B1, $0F, $FE, $8E, $ED, $01, $FD, $32, $00, $A0, $B7, $BF, $E1, $AA, $B5, $B5
	db $AA, $BA, $A5, $BD, $A2, $AE, $A1, $B7, $A0, $E0, $04, $57, $80, $7F, $40, $BF
	db $F7, $04, $0F, $8C, $08, $01, $01, $FE, $EB, $05, $E0, $01, $55, $AD, $AD, $30
	db $55, $5D, $3F, $45, $75, $85, $06, $ED, $05, $AB, $A0, $A5, $50, $37, $BF, $C0
	db $3A, $20, $3D, $24, $A8, $12, $57, $D5, $2A, $4B, $7B, $53, $9A, $8A, $C1, $03
	db $0F, $15, $EA, $AB, $54, $E1, $04, $0F, $D5, $05, $A5, $99, $50, $FD, $9B, $FE
	db $C8, $5D, $78, $0F, $00, $52, $4E, $43, $02, $00, $00, $02, $40, $00, $00, $01
	db $F9, $8C, $5E, $1D, $CD, $03, $01, $2E, $59, $01, $02, $07, $08, $1F, $00, $3E
	db $01, $3F, $43, $7B, $07, $7F, $07, $56, $AE, $8E, $7E, $8C, $7C, $01, $84, $72
	db $7C, $41, $BE, $02, $7F, $10, $2F, $0F, $0F, $F0, $08, $FC, $42, $FE, $01, $FF
	db $F0, $C3, $C3, $00, $E1, $00, $7E, $01, $71, $40, $BF, $81, $7F, $11, $2F, $23
	db $5F, $C3, $3F, $0E, $FF, $3F, $FE, $F8, $F8, $D7, $3D, $2C, $03, $04, $87, $80
	db $C7, $C8, $CF, $C0, $0F, $10, $1E, $01, $17, $29, $E1, $DF, $A3, $DF, $C0, $BF
	db $25, $80, $2E, $7F, $CF, $3C, $7F, $1C, $FC, $7C, $7C, $F0, $00, $F4, $8C, $F6
	db $0E, $FE, $06, $7E, $86, $FE, $01, $0C, $B6, $CE, $A3, $9F, $01, $03, $40, $FF
	db $01, $EB, $DF, $30, $21, $1F, $5F, $1F, $20, $0F, $1B, $04, $0F, $00, $3B, $63
	db $83, $3D, $19, $07, $64, $59, $13, $23, $00, $01, $5F, $47, $3F, $56, $3E, $46
	db $18, $3E, $9E, $9E, $9F, $C3, $44, $03, $E7, $28, $EF, $10, $FF, $00, $00, $01
	db $7F, $84, $9B, $EC, $9C, $BB, $8C, $30, $8B, $04, $72, $0B, $08, $07, $61, $0A
	db $7A, $07, $03, $03, $70, $E7, $08, $FB, $5D, $FB, $18, $DB, $3C, $FF, $38, $F7
	db $30, $C0, $01, $37, $F8, $7C, $F3, $68, $70, $E7, $01, $F7, $F0, $01, $EF, $D4
	db $CF, $50, $CF, $E7, $E7, $0E, $37, $03, $01, $3F, $B0, $70, $F0, $70, $1B, $07
	db $C2, $3F, $CA, $39, $00, $C0, $00, $9C, $12, $01, $16, $D8, $00, $9F, $FC, $2C
	db $64, $EC, $A8, $FC, $34, $DD, $00, $0A, $19, $80, $80, $03, $0A, $80, $20, $E0
	db $10, $F0, $7E, $DF, $06, $1F, $09, $76, $8E, $9E, $6E, $6C, $1F, $E1, $42, $38
	db $3F, $20, $BF, $F8, $01, $04, $FF, $41, $FE, $01, $EF, $F0, $CC, $FF, $C5, $00
	db $02, $0E, $01, $08, $17, $11, $0F, $58, $1F, $07, $FF, $76, $1E, $1F, $B8, $60
	db $3E, $40, $1F, $29, $9D, $83, $DD, $E3, $DF, $E3, $FB, $C7, $01, $AF, $D7, $A6
	db $DE, $03, $A2, $DE, $A3, $DF, $A1, $9F, $6C, $3B, $25, $2B, $07, $C0, $C1, $00
	db $83, $81, $83, $80, $03, $83, $84, $87, $80, $07, $00, $83, $D0, $08, $09, $06
	db $80, $41, $2F, $21, $5F, $03, $FF, $86, $3F, $97, $0C, $CF, $10, $F7, $3A, $D7
	db $B7, $30, $78, $BF, $BD, $70, $6F, $E0, $61, $6F, $91, $E7, $D1, $CF, $80, $01
	db $91, $AF, $A0, $9F, $28, $1F, $84, $7F, $C3, $DF, $7F, $60, $E0, $03, $00, $FE
	db $00, $85, $7F, $03, $9B, $D3, $C1, $85, $C3, $FF, $02, $3B, $DF, $03, $1F, $5C
	db $DB, $38, $FB, $FC, $9C, $5D, $01, $04, $84, $8B, $88, $87, $08, $38, $66, $A5
	db $55, $07, $CF, $31, $EF, $F7, $F7, $18, $24, $08, $03, $BE, $7F, $00, $F0, $70
	db $E0, $60, $61, $E0, $62, $E5, $96, $17, $03, $F4, $FB, $C2, $C5, $82, $81, $70
	db $01, $48, $40, $F0, $04, $10, $E8, $18, $FC, $0C, $00, $01, $EC, $1C, $5C, $BC
	db $78, $F8, $DC, $67, $14, $01, $C0, $20, $E0, $90, $F0, $08, $F8, $BC, $9F, $00
	db $52, $4E, $43, $02, $00, $00, $02, $40, $00, $00, $01, $77, $FE, $68, $3A, $C4
	db $02, $01, $0E, $7C, $7F, $03, $00, $7C, $7A, $80, $79, $7C, $98, $09, $06, $7D
	db $7E, $1B, $80, $80, $77, $02, $CE, $02, $00, $78, $38, $18, $7A, $13, $78, $C4
	db $03, $79, $7A, $07, $10, $7D, $7B, $7F, $89, $04, $1F, $7C, $7E, $04, $13, $7C
	db $7B, $7E, $D2, $11, $7B, $26, $06, $00, $C0, $01, $13, $81, $82, $83, $84, $85
	db $F5, $04, $19, $CB, $86, $87, $88, $89, $8A, $8B, $8C, $8D, $8E, $8F, $90, $91
	db $92, $93, $94, $95, $96, $97, $98, $99, $C0, $04, $1F, $9A, $9B, $9C, $9D, $9E
	db $20, $9F, $A0, $03, $A1, $00, $A2, $A3, $A4, $A5, $A6, $A7, $A8, $A9, $F5, $04
	db $1F, $CB, $AA, $AB, $AC, $AD, $AE, $AF, $B0, $B1, $B2, $B3, $B4, $B5, $B6, $B7
	db $B8, $B9, $BA, $BB, $BC, $BD, $D7, $04, $1F, $2F, $BE, $BF, $C0, $C1, $C2, $C3
	db $C4, $C5, $C6, $C7, $C8, $C9, $CA, $CB, $CC, $CD, $CE, $CF, $D0, $D1, $04, $5C
	db $1F, $BD, $D2, $D3, $D4, $D5, $D6, $D7, $D8, $D9, $DA, $DB, $DC, $DD, $DE, $DF
	db $E0, $E1, $E2, $E3, $E4, $E5, $04, $1F, $72, $DD, $E6, $E7, $E8, $E9, $EA, $EB
	db $EC, $ED, $EE, $EF, $DD, $F0, $F1, $F2, $F3, $F4, $F5, $F6, $F7, $F0, $05, $1F
	db $DD, $F8, $F9, $B8, $FA, $FA, $FB, $FC, $FD, $FE, $FF, $00, $01, $02, $03, $04
	db $05, $06, $07, $08, $09, $04, $1F, $E5, $0A, $0B, $0C, $0D, $0E, $0F, $10, $10
	db $11, $12, $13, $14, $15, $16, $17, $18, $19, $10, $1A, $1B, $EB, $04, $1F, $97
	db $1C, $1D, $1E, $1F, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2A, $2B
	db $2C, $2D, $2E, $2F, $AE, $04, $1F, $5E, $30, $31, $32, $33, $34, $35, $36, $37
	db $38, $39, $3A, $3B, $3C, $3D, $3E, $3F, $40, $41, $42, $43, $04, $1F, $B9, $7A
	db $44, $45, $46, $47, $48, $49, $4A, $4B, $4C, $4D, $4E, $4F, $50, $51, $52, $53
	db $54, $55, $56, $57, $04, $1F, $E5, $58, $59, $5A, $5B, $5C, $5D, $5E, $5F, $60
	db $61, $62, $63, $64, $65, $66, $67, $68, $69, $62, $6A, $E0, $06, $BF, $6B, $6C
	db $6D, $6E, $01, $6F, $70, $71, $DD, $72, $73, $74, $A9, $0C, $00, $EB, $06, $1F
	db $07, $00, $75, $76, $DD, $BC, $0B, $1F, $00, $52, $4E, $43, $02, $00, $00, $02
	db $B0, $00, $00, $01, $94, $16, $93, $5E, $A9, $02, $01, $2E, $58, $1C, $1C, $3E
	db $22, $7F, $49, $6F, $51, $B6, $CA, $FA, $96, $7C, $44, $38, $38, $0C, $0C, $1E
	db $12, $11, $1A, $16, $0C, $2C, $34, $3C, $24, $01, $18, $48, $18, $1F, $35, $00
	db $3B, $7A, $46, $FC, $9C, $FE, $82, $7C, $50, $7C, $0F, $59, $2D, $04, $33, $56
	db $5A, $FE, $B2, $0B, $2F, $04, $04, $96, $1E, $1A, $2E, $32, $5E, $6A, $FD, $83
	db $7E, $76, $1C, $14, $08, $08, $3E, $3E, $7F, $41, $7E, $4E, $2D, $B8, $40, $3E
	db $32, $7E, $72, $FC, $84, $78, $78, $1E, $1E, $3F, $21, $0F, $FE, $92, $D0, $01
	db $2F, $81, $1F, $3F, $39, $B1, $63, $5B, $78, $48, $89, $01, $30, $30, $0B, $5F
	db $7E, $42, $24, $1F, $0F, $DA, $01, $05, $43, $3F, $00, $00, $63, $83, $2B, $34
	db $2C, $10, $19, $58, $68, $2F, $84, $0D, $36, $3B, $09, $19, $81, $00, $36, $36
	db $0C, $2D, $3B, $6C, $49, $6C, $0F, $26, $00, $A7, $87, $AB, $B4, $04, $11, $2F
	db $92, $6F, $7B, $3F, $02, $4F, $D0, $04, $23, $00, $D8, $C1, $C5, $3E, $2A, $08
	db $7D, $4B, $7D, $43, $63, $91, $55, $3C, $3C, $40, $9B, $0D, $BE, $D2, $D0, $0D
	db $8F, $90, $9F, $6E, $5E, $24, $BC, $DC, $AF, $D8, $00, $05, $7E, $4A, $2C, $6D
	db $5B, $1F, $93, $FF, $69, $33, $1F, $6F, $2F, $02, $18, $0F, $F0, $90, $01, $60
	db $60, $B3, $3F, $10, $2F, $F6, $9A, $3F, $92, $BF, $48, $5F, $46, $6F, $2F, $25
	db $1E, $12, $B6, $7F, $35, $7D, $0C, $06, $06, $0F, $09, $01, $0D, $12, $0B, $7E
	db $72, $D0, $9F, $2F, $D8, $6F, $09, $BC, $D4, $92, $2F, $40, $D7, $68, $58, $B0
	db $D0, $90, $6F, $22, $22, $3D, $77, $55, $04, $4F, $04, $2F, $77, $0A, $0F, $C2
	db $EE, $49, $0F, $7F, $89, $AF, $B6, $DA, $21, $BF, $DF, $80, $0F, $75, $4B, $FE
	db $86, $F8, $98, $F7, $02, $9F, $33, $CF, $1F, $96, $1E, $67, $34, $34, $02, $1F
	db $DE, $7F, $02, $3F, $0F, $36, $2E, $6C, $74, $02, $C1, $CF, $3E, $26, $34, $2C
	db $1A, $4D, $34, $4F, $92, $CF, $43, $5F, $BF, $18, $0F, $5F, $69, $0F, $AE, $DA
	db $DC, $8F, $2D, $1E, $28, $10, $10, $01, $1F, $60, $CA, $1F, $EE, $AA, $44, $44
	db $81, $0F, $5D, $6B, $B1, $53, $1D, $BA, $D6, $66, $AF, $0F, $36, $3A, $26, $FD
	db $2D, $34, $28, $38, $2F, $A0, $2F, $2A, $36, $24, $54, $6C, $DF, $F0, $00, $52
	db $4E, $43, $02, $00, $00, $00, $F9, $00, $00, $00, $D1, $8A, $B6, $34, $99, $03
	db $01, $05, $06, $82, $01, $0C, $02, $02, $00, $05, $07, $C0, $05, $07, $02, $02
	db $08, $05, $03, $01, $01, $04, $04, $0D, $03, $60, $02, $0E, $0E, $08, $04, $06
	db $C3, $12, $06, $06, $01, $80, $13, $11, $03, $06, $12, $82, $CD, $0A, $82, $06
	db $C0, $05, $08, $03, $03, $0B, $03, $03, $0F, $8A, $05, $10, $0A, $01, $0B, $09
	db $05, $04, $82, $04, $0B, $98, $38, $0C, $36, $06, $03, $50, $02, $20, $08, $01
	db $D8, $23, $3E, $01, $0D, $6C, $02, $02, $39, $0D, $66, $84, $47, $11, $26, $0C
	db $10, $06, $05, $0F, $44, $0E, $31, $01, $12, $5A, $06, $84, $83, $29, $84, $05
	db $06, $04, $73, $38, $46, $21, $2F, $0C, $32, $80, $0B, $08, $06, $0B, $0B, $06
	db $0C, $61, $0A, $41, $09, $01, $02, $98, $3B, $09, $53, $0A, $82, $E6, $4D, $29
	db $63, $13, $9E, $12, $04, $99, $74, $A1, $04, $B9, $A1, $8E, $83, $05, $05, $05
	db $08, $84, $66, $93, $41, $0D, $41, $C4, $4C, $01, $0E, $37, $95, $20, $03, $AA
	db $0B, $07, $06, $8A, $9B, $02, $55, $02, $44, $0F, $09, $02, $10, $82, $99, $47
	db $43, $0A, $B2, $07, $98, $06, $19, $E6, $97, $00, $99, $1F, $07, $B0, $08, $BC
	db $32, $00, $52, $4E, $43, $02, $00, $00, $02, $40, $00, $00, $00, $B1, $7B, $6C
	db $E3, $15, $04, $01, $02, $73, $75, $76, $2C, $66, $00, $76, $0B, $E7, $05, $05
	db $10, $73, $74, $74, $38, $15, $08, $75, $9A, $19, $6F, $08, $0A, $3C, $00, $76
	db $04, $0B, $73, $1E, $74, $75, $76, $05, $1D, $7A, $73, $0B, $36, $4F, $65, $08
	db $1E, $29, $2C, $73, $08, $10, $F7, $14, $43, $80, $07, $00, $2D, $2E, $2F, $30
	db $31, $32, $13, $33, $34, $35, $40, $C3, $12, $57, $35, $9A, $52, $E3, $36, $37
	db $38, $39, $3A, $3B, $3C, $3D, $3E, $3F, $40, $41, $42, $43, $44, $2C, $32, $12
	db $3B, $41, $0C, $45, $46, $47, $71, $48, $49, $4A, $4B, $4C, $4D, $4E, $4F, $50
	db $51, $52, $53, $54, $55, $56, $57, $92, $12, $61, $0C, $58, $59, $5A, $71, $5B
	db $5C, $5D, $5E, $5F, $60, $61, $62, $63, $64, $65, $66, $67, $68, $69, $6A, $92
	db $12, $60, $0C, $6B, $6C, $6D, $6E, $0B, $6F, $70, $71, $72, $2C, $07, $0A, $B0
	db $0C, $77, $78, $02, $79, $7A, $7B, $7C, $7D, $7E, $CB, $07, $2C, $0A, $0C, $7B
	db $7F, $B7, $00, $C0, $00, $52, $4E, $43, $02, $00, $00, $01, $20, $00, $00, $00
	db $F1, $1C, $AF, $D3, $30, $03, $01, $05, $06, $82, $05, $2E, $02, $79, $01, $02
	db $82, $00, $09, $02, $05, $0A, $05, $01, $06, $84, $02, $00, $04, $01, $07, $03
	db $06, $08, $82, $04, $06, $13, $02, $12, $97, $02, $08, $0C, $04, $03, $07, $04
	db $0F, $09, $04, $10, $02, $06, $06, $05, $18, $84, $C0, $23, $04, $07, $06, $03
	db $01, $63, $05, $35, $11, $08, $33, $1F, $0B, $20, $8A, $18, $02, $0A, $04, $3F
	db $06, $07, $D8, $11, $02, $02, $08, $00, $02, $03, $03, $05, $05, $0F, $04, $02
	db $6C, $10, $23, $59, $00, $C8, $44, $06, $30, $44, $02, $0F, $05, $04, $09, $36
	db $84, $04, $28, $0B, $66, $03, $02, $82, $43, $C1, $2C, $0B, $82, $03, $0C, $B8
	db $2F, $80, $01, $5C, $08, $39, $03, $0D, $0B, $05, $0D, $8A, $02, $0D, $0A, $01
	db $0E, $09, $11, $C3, $5C, $06, $11, $39, $80, $12, $83, $0C, $02, $41, $82, $D9
	db $21, $26, $0F, $9C, $17, $10, $AD, $60, $08, $02, $0B, $03, $02, $8A, $06, $03
	db $09, $8A, $01, $0A, $32, $DB, $7A, $02, $36, $7A, $00, $26, $7A, $6D, $04, $7A
	db $BA, $82, $1C, $0D, $84, $06, $0E, $9B, $65, $D4, $63, $71, $3B, $0A, $82, $98
	db $86, $B6, $82, $09, $66, $01, $05, $0D, $84, $32, $0D, $01, $62, $03, $68, $2F
	db $21, $32, $82, $9B, $B3, $D7, $E3, $11, $36, $E3, $10, $E3, $B7, $E1, $3C, $00
	db $0D, $B6, $CB, $3D, $72, $78, $01, $00, $52, $4E, $43, $02, $00, $00, $01, $02
	db $00, $00, $00, $CA, $D9, $D3, $1E, $B8, $02, $01, $06, $06, $82, $01, $02, $17
	db $02, $06, $02, $0E, $01, $02, $05, $02, $09, $84, $01, $0A, $04, $0B, $06, $03
	db $18, $11, $0B, $01, $17, $0D, $02, $33, $0B, $0D, $14, $0E, $06, $11, $00, $03
	db $02, $07, $11, $18, $08, $82, $06, $26, $00, $01, $06, $05, $06, $0D, $84, $05
	db $14, $CC, $06, $03, $01, $82, $31, $05, $0F, $14, $10, $82, $8C, $09, $82, $04
	db $02, $03, $C0, $0E, $04, $0F, $02, $03, $10, $1B, $05, $00, $06, $47, $38, $02
	db $02, $05, $05, $00, $04, $02, $11, $03, $00, $12, $82, $00, $84, $62, $10, $68
	db $08, $05, $D8, $56, $6D, $05, $09, $CE, $34, $0A, $33, $38, $02, $38, $01, $66
	db $6F, $07, $0D, $0B, $C7, $02, $06, $0E, $3C, $62, $02, $2C, $0B, $C6, $7C, $03
	db $11, $4D, $73, $12, $4D, $6D, $47, $6C, $98, $99, $1D, $02, $02, $09, $90, $65
	db $0A, $23, $43, $04, $29, $60, $3E, $49, $00, $0D, $04, $04, $66, $0D, $41, $0E
	db $C0, $20, $06, $05, $74, $03, $CC, $7A, $0F, $05, $10, $86, $80, $32, $6C, $04
	db $71, $97, $05, $CD, $A7, $11, $5F, $49, $86, $36, $EC, $7F, $00, $CA, $32, $00
	db $3C, $71, $05, $00, $52, $4E, $43, $02, $00, $00, $02, $C0, $00, $00, $01, $3A
	db $79, $D1, $8C, $13, $05, $01, $1E, $00, $11, $00, $1C, $18, $18, $08, $01, $F7
	db $16, $1D, $B0, $10, $1F, $1D, $1C, $14, $14, $CD, $02, $1C, $02, $E3, $0C, $1D
	db $08, $08, $10, $19, $18, $14, $03, $3C, $18, $14, $0E, $3D, $28, $06, $38, $24
	db $3C, $34, $2C, $05, $DE, $03, $12, $1D, $21, $38, $28, $05, $EC, $08, $1D, $56
	db $3C, $69, $2C, $59, $21, $1D, $07, $E0, $08, $1D, $2C, $3C, $3A, $2E, $18, $1A
	db $16, $2C, $18, $34, $2A, $6D, $36, $07, $03, $E6, $02, $1B, $24, $30, $17, $3C
	db $74, $5C, $0D, $5A, $66, $3A, $26, $54, $6C, $44, $7C, $52, $6E, $32, $2E, $0B
	db $A4, $01, $1B, $18, $04, $04, $2C, $30, $3C, $72, $1B, $5E, $4A, $76, $1D, $6D
	db $3A, $1F, $1D, $B4, $01, $09, $0B, $1F, $02, $02, $84, $16, $16, $3A, $3E, $5A
	db $7E, $69, $5F, $35, $2B, $3D, $23, $31, $11, $23, $59, $67, $8C, $01, $39, $27
	db $0D, $5D, $6F, $63, $01, $12, $C3, $5F, $01, $01, $03, $3D, $3C, $03, $12, $1D
	db $BC, $1B, $18, $1F, $05, $7A, $06, $10, $1F, $4F, $1D, $10, $59, $1F, $3B, $EC
	db $0E, $1F, $74, $05, $00, $07, $06, $07, $0A, $0D, $05, $0E, $0B, $6F, $0C, $08
	db $08, $30, $1D, $06, $55, $07, $0B, $0E, $0D, $1E, $19, $15, $1E, $1D, $8F, $03
	db $0F, $0E, $08, $60, $39, $11, $15, $1A, $2F, $3C, $C0, $03, $2B, $3C, $1D, $1A
	db $17, $1E, $1E, $0D, $0E, $04, $39, $31, $0B, $0D, $1D, $1D, $12, $8F, $19, $3D
	db $3E, $08, $32, $1F, $0E, $35, $1B, $E5, $0F, $0C, $33, $3E, $5D, $62, $3B, $7C
	db $55, $5E, $2D, $32, $5B, $7C, $79, $76, $2F, $38, $35, $36, $80, $63, $1C, $1C
	db $26, $3A, $1B, $1D, $C5, $31, $43, $7E, $CB, $B9, $C6, $77, $F8, $9B, $9C, $25
	db $3E, $59, $66, $B7, $F8, $DB, $DC, $B9, $A6, $57, $78, $6D, $6E, $78, $1F, $00
	db $52, $4E, $43, $02, $00, $00, $02, $40, $00, $00, $00, $8D, $12, $93, $E8, $0E
	db $04, $01, $1E, $79, $17, $00, $79, $7A, $17, $00, $7B, $E3, $17, $00, $7C, $7D
	db $C7, $16, $01, $7E, $7F, $9E, $16, $01, $2C, $1B, $00, $07, $2D, $2E, $2F, $30
	db $31, $AE, $0F, $0F, $18, $32, $33, $34, $35, $36, $37, $38, $39, $3A, $3B, $3C
	db $3D, $0D, $33, $3E, $F5, $08, $0F, $C7, $3F, $40, $41, $42, $43, $44, $45, $46
	db $47, $48, $49, $4A, $4B, $4C, $4D, $4E, $D7, $08, $0F, $1F, $4F, $50, $51, $52
	db $53, $54, $55, $56, $57, $58, $59, $5A, $5B, $5C, $5D, $5E, $08, $5C, $0F, $7C
	db $5F, $60, $61, $62, $63, $64, $65, $66, $67, $68, $69, $6A, $6B, $6C, $6D, $6E
	db $08, $0F, $6F, $01, $70, $71, $72, $73, $74, $75, $76, $41, $06, $71, $71, $78
	db $E0, $04, $0F, $70, $70, $77, $78, $FD, $18, $7F, $EF, $98, $00, $00, $00, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
