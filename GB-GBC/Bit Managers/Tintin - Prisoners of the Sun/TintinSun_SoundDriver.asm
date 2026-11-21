; =====================================================================
; Les Aventures de Tintin: Le Temple du Soleil / Prisoners of the Sun (E) (M3) - Game Boy
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o sun.o TintinSun_SoundDriver.asm
;   rgblink -o sun.gb sun.o
;   python tools/cmp_banked.py sun.gb "Les Aventures De TinTin - Le Temple du Soleil (E) (M3) [M].gb" 15:4000-7FFF
; (driver and data fill ROM bank 15; the linked file only matches in that range)
;
; Documentation: TintinSun_SoundDriver.md / AJG_SoundEngine_Family.md
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


SECTION "SoundDriver", ROMX[$4000], BANK[15]


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
	jp PlayCh1Tone                     ; PlayCh1Tone (BC = period; new)
	jp PlaySong1                       ; song slot 1: song 1
	jp PlaySong2                       ; song slot 2: song 2
	jp PlaySong3                       ; song slot 3: song 3
	jp PlaySong4                       ; song slot 4: song 4
	jp PlaySong5                       ; song slot 5: song 5
	jp PlaySong6                       ; song slot 6: song 6
	jp PlaySong7                       ; song slot 7: song 7
	jp PlaySong8                       ; song slot 8: song 8
	jp PlaySong9                       ; song slot 9: song 9
	jp PlaySong10                      ; song slot 10: song 10
	jp PlaySong11                      ; song slot 11: song 11
	jp PlaySong12                      ; song slot 12: song 12
	jp PlaySong13                      ; song slot 13: song 13
	jp PlaySong14                      ; song slot 14: song 14
	jp PlaySong1                       ; song slot 15: song 1
	jp PlaySong1                       ; song slot 16: song 1
	jp PlaySong1                       ; song slot 17: song 1
PlaySfxEntry2:
	jp PlaySfx                         ; PlaySfxNow (A = id; the same code as PlaySfx)

; PlayCh1Tone (BC = period; API entry 9, new in this build): Ch1 page period = BC,
; NRx2 value $F0 with the write flag set, NR11 = $C0 (75 % duty). The next output
; retriggers CH1 at volume 15 with no envelope; a playing Ch1 track overwrites it.
; The game's VBlank glue calls it every frame while one game mode runs (period =
; a game variable x 8). Song 10 starts no Ch1 track.
PlayCh1Tone:
	ld a, b
	ld [$DC06], a
	ld a, c
	ld [$DC05], a
	ld a, $F0
	ld [$DC32], a
	ld [$DC33], a
	ld a, $C0
	ldh [rNR11], a
	ret

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
	add a, $D8
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

; Unreferenced (61 bytes)
	db $E0, $1A, $E0, $1E, $C9, $C0, $3E, $80, $EA, $07, $DE, $E0, $1A, $E0, $1E, $C9
	db $09, $4A, $52, $09, $5A, $2C, $24, $53, $4F, $4C, $4F, $31, $09, $3B, $20, $53
	db $6F, $6C, $6F, $20, $6E, $65, $63, $65, $73, $69, $74, $61, $20, $6C, $61, $20
	db $70, $72, $69, $6D, $65, $72, $61, $20, $65, $6E, $76, $6F, $6C
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

; API entry for PlaySfx: jumps to the last slot of the API table (PlaySfxEntry2),
; which jumps to PlaySfx.
PlaySfxEntry:
	jp PlaySfxEntry2

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
	add a, $34
	ld l, a
	adc a, $72
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
	db $4A, $7A
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

; Song 2: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong2:
	ld a, $70
	ld [wInstrTableHi], a
	ld a, $B4
	ld [wInstrTable], a
	call StopAll
	ld de, Song2_Ch1
	call StartMusicCh1
	ld de, Song2_Ch2
	call StartMusicCh2
	ld de, Song2_Ch3
	jp StartMusicCh3
Song2_Ch1:
	dw Pat_4B79
	dw Pat_4B7F
	dw Pat_4B7F
	dw Pat_4B92
	dw Pat_4B92
	dw Pat_4B98
	dw Pat_4B98
	ORDER_LOOP Song2_Ch1
Song2_Ch3:
	dw Pat_4BAC
	dw Pat_4BD2
	dw Pat_4BFB
	dw Pat_4C1C
	dw Pat_4C60
	dw Pat_4C96
	dw Pat_4C9D
	ORDER_LOOP Song2_Ch3
Song2_Ch2:
	dw Pat_4CC3
	dw Pat_4CED
	dw Pat_4D0F
	dw Pat_4D31
	dw Pat_4D53
	dw Pat_4D78
	dw Pat_4D9A
	ORDER_LOOP Song2_Ch2
Pat_4B79:
	VIBRATO $07, $01, $04
	CH_TRANSPOSE $00
Pat_4B7F:
	REPEAT 4
	INSTR 11
	LEN 28
	NOTE F_, 2
	INSTR 12
	LEN 14
	NOTE C_, 3
	INSTR 11
	LEN 28
	NOTE F_, 2
	INSTR 12
	LEN 14
	NOTE C_, 3
	INSTR 11
	NOTE F_, 2
	INSTR 12
	NOTE C_, 3
	REPEAT_END
	NEXT
Pat_4B92:
	CH_TRANSPOSE $02
	PAT_GOTO Pat_4B7F

; Unreferenced (1 bytes)
	db $6A
Pat_4B98:
	CH_TRANSPOSE $04
	PAT_GOTO Pat_4B7F

; Unreferenced (15 bytes)
	db $6A, $91, $CF, $1A, $90, $DD, $13, $91, $CF, $1A, $90, $13, $91, $1A, $6A
Pat_4BAC:
	RELEASE $01, $01
	VOLENV 10, $11, $1F, $13
	CH_TRANSPOSE $0C
	ARP 0
	VIBRATO $18, $02, $05
	WAVE Wave_77BF
	REPEAT 2
	LEN 14
	NOTE C_, 4
	NOTE F_, 4
	NOTE C_, 5
	LEN 28
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE Csh, 5
	NOTE F_, 4
	NOTE C_, 5
	NOTE F_, 4
	REPEAT_END
	NEXT
Pat_4BD2:
	VOLENV 12, $11, $1F, $17
	WAVE Wave_783F
	ARP_OFF
	LEN 14
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	LENGTH $46
	ARP 3
	NOTE F_, 4
	ARP_OFF
	LEN 14
	NOTE F_, 4
	NOTE Csh, 4
	NOTE F_, 4
	LENGTH $46
	NOTE C_, 4
	LEN 14
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	LENGTH $38
	NOTE C_, 5
	NEXT
Pat_4BFB:
	LEN 14
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	LENGTH $46
	ARP 3
	NOTE F_, 4
	ARP_OFF
	LEN 14
	NOTE F_, 4
	NOTE Csh, 4
	NOTE F_, 4
	LENGTH $46
	NOTE C_, 4
	LEN 14
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	LENGTH $38
	NOTE F_, 4
	NEXT
Pat_4C1C:
	VOLENV 8, $18, $1F, $1A
	RELEASE $01, $A2
	WAVE Wave_78CF
	ARP_OFF
	LEN 21
	NOTE G_, 4
	LEN 7
	WAIT2
	NOTE G_, 4
	WAIT2
	ARP 3
	LENGTH $38
	NOTE G_, 4
	ARP_OFF
	LEN 14
	NOTE Ash, 4
	LEN 21
	NOTE G_, 4
	LEN 7
	WAIT2
	NOTE G_, 4
	WAIT2
	LENGTH $31
	NOTE D_, 4
	LEN 7
	WAIT2
	NOTE C_, 4
	WAIT2
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE Dsh, 4
	WAIT2
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE C_, 4
	WAIT2
	LEN 14
	NOTE D_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 21
	NOTE C_, 5
	LEN 7
	WAIT2
	LEN 21
	NOTE D_, 5
	LEN 7
	WAIT2
	LEN 28
	NOTE Gsh, 4
	LEN 14
	NOTE A_, 4
	LEN 7
	NOTE Ash, 4
	WAIT2
	NEXT
Pat_4C60:
	ARP 0
	LEN 21
	NOTE G_, 4
	LEN 7
	WAIT2
	NOTE G_, 4
	WAIT2
	ARP 3
	LENGTH $38
	NOTE G_, 4
	ARP 0
	LEN 14
	NOTE Ash, 4
	LEN 21
	NOTE G_, 4
	LEN 7
	WAIT2
	NOTE G_, 4
	WAIT2
	LENGTH $38
	NOTE D_, 4
	LEN 14
	NOTE C_, 4
	NOTE D_, 4
	NOTE G_, 4
	ARP 3
	NOTE Gsh, 4
	ARP 0
	NOTE A_, 4
	ARP 3
	NOTE Ash, 4
	ARP 0
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	LEN 7
	NOTE G_, 4
	WAIT2
	LEN 21
	NOTE F_, 4
	LEN 7
	WAIT2
	LENGTH $31
	NOTE G_, 4
	LEN 7
	WAIT2
	RELEASE $01, $01
	NEXT
Pat_4C96:
	VOLENV 15, $11, $1F, $11
	WAVE Wave_780F
Pat_4C9D:
	ARP 5
	LEN 14
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	ARP 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE B_, 3
	NOTE B_, 3
	NOTE Ash, 3
	NOTE Ash, 3
	ARP 5
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	ARP 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE C_, 4
	NEXT
Pat_4CC3:
	DRUMS $0E, DrumPat_4DBE
	HWENV $E2, $07, $63
	DUTY_12
	ARP 0
	VIBRATO $07, $02, $04
	LEN 42
	NOTE F_, 3
	NOTE F_, 3
	LEN 28
	NOTE F_, 3
	LEN 42
	NOTE F_, 3
	NOTE F_, 3
	LEN 28
	NOTE Dsh, 3
	LEN 14
	NOTE F_, 3
	NOTE C_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE C_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE C_, 3
	NOTE F_, 3
	NOTE Csh, 3
	NOTE F_, 3
	NOTE C_, 3
	NOTE Csh, 3
	NOTE F_, 3
	NOTE C_, 3
	NOTE Csh, 3
	NEXT
Pat_4CED:
	LEN 14
	NOTE F_, 3
	NOTE C_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE C_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE C_, 3
	NOTE F_, 3
	NOTE Csh, 3
	NOTE F_, 3
	NOTE C_, 3
	NOTE Csh, 3
	NOTE F_, 3
	NOTE C_, 3
	NOTE Csh, 3
	NOTE F_, 3
	NOTE C_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Gsh, 3
	NEXT
Pat_4D0F:
	LEN 14
	NOTE F_, 3
	NOTE C_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE C_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE C_, 3
	NOTE F_, 3
	NOTE Csh, 3
	NOTE F_, 3
	NOTE C_, 3
	NOTE Csh, 3
	NOTE F_, 3
	NOTE C_, 3
	NOTE Csh, 3
	NOTE F_, 3
	NOTE C_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE F_, 3
	NEXT
Pat_4D31:
	LEN 14
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE Dsh, 3
	NOTE G_, 3
	NOTE D_, 3
	NOTE Dsh, 3
	NOTE G_, 3
	NOTE D_, 3
	NOTE Dsh, 3
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE Ash, 3
	NEXT
Pat_4D53:
	LEN 14
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE Dsh, 3
	NOTE G_, 3
	NOTE D_, 3
	NOTE Dsh, 3
	NOTE G_, 3
	NOTE D_, 3
	NOTE Dsh, 3
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NEXT
Pat_4D78:
	LEN 14
	NOTE A_, 3
	NOTE E_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE E_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE E_, 3
	NOTE A_, 3
	NOTE E_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE E_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE E_, 3
	NOTE A_, 3
	NOTE E_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE E_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE E_, 3
	NOTE A_, 3
	NOTE E_, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE E_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE B_, 3
	NEXT
Pat_4D9A:
	ARP 8
	VIB_OFF
	LEN 14
	NOTE A_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE E_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE B_, 4
	NEXT
DrumPat_4DBE:
	db DRUM_REPEAT + 3, 1, 6, 3, 1, DRUM_REPEAT_END, 1, DRUM_TEMPO + 7
	db 6, 6, DRUM_TEMPO + 14, 3, 1, DRUM_REPEAT + 3, 1, 6
	db 3, 1, DRUM_REPEAT_END, 1, DRUM_TEMPO + 7, 6, DRUM_TEMPO + 3, 6
	db DRUM_TEMPO + 4, 6, DRUM_TEMPO + 7, 3, 0, 6, 6, DRUM_TEMPO + 14
	db DRUM_LOOP

; Song 3: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong3:
	ld a, $70
	ld [wInstrTableHi], a
	ld a, $B4
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
	ORDER_LOOP Song3_Ch1
Song3_Ch2:
	dw Pat_4E54
	dw Pat_4E54
	dw Pat_4E65
	dw Pat_4E65
	dw Pat_4E65
	dw Pat_4E65
	dw Pat_4E65
	dw Pat_4E65
	dw Pat_4E65
	dw Pat_4E65
	ORDER_LOOP Song3_Ch2
Song3_Ch3:
	dw Pat_4E84
	dw Pat_4EBE
	dw Pat_4EE0
	dw Pat_4EFB
	dw Pat_4F18
	dw Pat_4EBE
	dw Pat_4EE0
	dw Pat_4EFB
	dw Pat_4F18
	ORDER_LOOP Song3_Ch3
Pat_4E32:
	HWENV $F3, $00
	ARP 0
	VIBRATO $0E, $04, $05
	DUTY_50
	LEN 42
	NOTE D_, 2
	NOTE D_, 3
	LEN 14
	NOTE C_, 3
	NOTE A_, 2
	LEN 42
	NOTE D_, 2
	NOTE D_, 3
	LEN 14
	NOTE C_, 3
	NOTE A_, 2
	LEN 42
	NOTE D_, 2
	NOTE D_, 3
	LEN 14
	NOTE C_, 3
	NOTE A_, 2
	LEN 42
	NOTE D_, 2
	NOTE D_, 3
	LEN 14
	NOTE C_, 3
	NOTE A_, 2
	NEXT
Pat_4E54:
	LEN 28
	REPEAT 4
	INSTR 0
	NOTE D_, 3
	INSTR 5
	LEN 14
	NOTE D_, 4
	INSTR 0
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE E_, 3
	INSTR 5
	LEN 28
	NOTE D_, 4
	REPEAT_END
	NEXT
Pat_4E65:
	REPEAT 2
	INSTR 0
	NOTE D_, 3
	INSTR 4
	LEN 14
	NOTE C_, 4
	INSTR 0
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE E_, 3
	INSTR 4
	LEN 28
	NOTE C_, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE D_, 3
	INSTR 4
	LEN 14
	NOTE D_, 4
	INSTR 0
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE E_, 3
	INSTR 4
	LEN 28
	NOTE D_, 4
	REPEAT_END
	NEXT
Pat_4E84:
	DRUMS $0E, DrumPat_4F30
	CH_TRANSPOSE $0C
	VOLENV 7, $15, $1F, $10
	VIBRATO $18, $01, $06
	ARP 0
	WAVE Wave_771F
	LENGTH $A8
	NOTE A_, 4
	LEN 28
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 14
	NOTE F_, 4
	LEN 28
	NOTE E_, 4
	NOTE F_, 4
	LEN 42
	NOTE E_, 4
	LEN 28
	NOTE D_, 4
	NOTE C_, 4
	NOTE E_, 4
	LENGTH $8C
	NOTE A_, 3
	LEN 14
	NOTE G_, 3
	NOTE A_, 3
	LEN 28
	NOTE C_, 4
	LEN 14
	NOTE B_, 3
	NOTE C_, 4
	LENGTH $8C
	NOTE A_, 3
	LEN 14
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NEXT
Pat_4EBE:
	WAVE Wave_77BF
	VOLENV 9, $15, $17, $16
	ARP 4
	LEN 42
	NOTE C_, 4
	ARP_OFF
	NOTE G_, 3
	LEN 28
	NOTE A_, 3
	LEN 42
	NOTE B_, 3
	NOTE D_, 4
	LEN 28
	NOTE E_, 4
	ARP 3
	NOTE D_, 4
	ARP_OFF
	LEN 14
	NOTE Fsh, 4
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE E_, 4
	NOTE C_, 4
	NOTE D_, 4
	LENGTH $70
	NOTE A_, 3
	NEXT
Pat_4EE0:
	ARP 4
	LEN 42
	NOTE C_, 4
	ARP_OFF
	NOTE G_, 3
	LEN 28
	NOTE A_, 3
	LEN 42
	NOTE B_, 3
	NOTE D_, 4
	LEN 28
	NOTE E_, 4
	ARP 3
	NOTE D_, 4
	ARP_OFF
	LEN 14
	NOTE Fsh, 4
	LEN 28
	NOTE A_, 4
	NOTE B_, 4
	LENGTH $46
	NOTE D_, 5
	LEN 28
	NOTE C_, 5
	NOTE B_, 4
	NEXT
Pat_4EFB:
	ARP_OFF
	LEN 14
	NOTE C_, 5
	NOTE B_, 4
	NOTE G_, 4
	LEN 42
	NOTE E_, 4
	LEN 14
	NOTE G_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE G_, 4
	LEN 28
	NOTE E_, 4
	NOTE G_, 4
	LENGTH $54
	NOTE A_, 4
	LEN 14
	NOTE A_, 4
	NOTE G_, 4
	LENGTH $46
	NOTE Fsh, 4
	LEN 28
	NOTE E_, 4
	NOTE D_, 4
	NEXT
Pat_4F18:
	ARP_OFF
	LEN 28
	NOTE E_, 4
	LEN 14
	NOTE C_, 4
	LENGTH $62
	NOTE A_, 3
	LEN 28
	NOTE C_, 4
	NOTE A_, 3
	NOTE E_, 4
	ARP 3
	NOTE D_, 4
	ARP_OFF
	LEN 14
	NOTE D_, 4
	LEN 28
	NOTE D_, 4
	NOTE A_, 3
	LENGTH $7E
	NOTE D_, 3
	NEXT
DrumPat_4F30:
	db DRUM_REPEAT + 3, 1, 6, 4, 1, 1, 6, 4
	db 6, DRUM_REPEAT_END, 1, 6, 4, 1, 1, 6
	db DRUM_TEMPO + 7, 9, 0, 10, 10, DRUM_TEMPO + 14, DRUM_LOOP

; Song 4: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong4:
	ld a, $70
	ld [wInstrTableHi], a
	ld a, $B4
	ld [wInstrTable], a
	call StopAll
	ld de, Song4_Ch1
	call StartMusicCh1
	ld de, Song4_Ch2
	call StartMusicCh2
	ld de, Song4_Ch3
	jp StartMusicCh3
Song4_Ch1:
	dw Pat_4FA8
	dw Pat_4FBE
	dw Pat_4FA8
	dw Pat_4FBE
	dw Pat_4FD3
	dw Pat_5002
	dw Pat_5041
	dw Pat_5041
	dw Pat_4FB1
	ORDER_LOOP Song4_Ch1
Song4_Ch3:
	dw Pat_5058
	dw Pat_5083
	dw Pat_5058
	dw Pat_5083
	dw Pat_509F
	dw Pat_50BA
	dw Pat_50D0
	dw Pat_50F2
	dw Pat_5119
	ORDER_LOOP Song4_Ch3
Song4_Ch2:
	dw Pat_5123
	dw Pat_514A
	dw Pat_5123
	dw Pat_514A
	dw Pat_5165
	dw Pat_5181
	dw Pat_51AC
	dw Pat_51B0
	dw Pat_5123
	ORDER_LOOP Song4_Ch2
Pat_4FA8:
	HWENV $F7, $00
	VIBRATO $12, $04, $06
	ARP 0
	DUTY_75
Pat_4FB1:
	LENGTH $7E
	NOTE D_, 2
	REPEAT 3
	LEN 18
	NOTE C_, 2
	LENGTH $7E
	NOTE D_, 2
	REPEAT_END
	LEN 18
	NOTE D_, 2
	NEXT
Pat_4FBE:
	LENGTH $7E
	NOTE E_, 2
	LEN 18
	NOTE E_, 2
	LENGTH $7E
	NOTE Dsh, 2
	LEN 18
	NOTE Dsh, 2
	LENGTH $48
	NOTE D_, 2
	NOTE G_, 2
	NOTE D_, 2
	LEN 36
	NOTE G_, 2
	LEN 18
	NOTE A_, 2
	NOTE C_, 3
	NEXT
Pat_4FD3:
	LEN 9
	REPEAT 2
	NOTE D_, 2
	REST
	LEN 36
	NOTE D_, 2
	LEN 9
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	REST
	LEN 36
	NOTE D_, 2
	LEN 9
	NOTE D_, 2
	REST
	REPEAT_END
	NOTE D_, 3
	REST
	LEN 36
	NOTE D_, 2
	LEN 9
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	REST
	LEN 36
	NOTE D_, 2
	LEN 9
	NOTE D_, 2
	REST
	NOTE D_, 3
	REST
	LEN 36
	NOTE D_, 2
	LEN 9
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	REST
	NOTE D_, 2
	REST
	NOTE D_, 3
	REST
	LEN 18
	NOTE D_, 2
	NEXT
Pat_5002:
	LEN 9
	NOTE D_, 2
	REST
	LEN 36
	NOTE D_, 2
	LEN 9
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	REST
	LEN 36
	NOTE D_, 2
	LEN 9
	NOTE D_, 2
	REST
	NOTE D_, 2
	REST
	LEN 36
	NOTE D_, 2
	LEN 9
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	REST
	LEN 36
	NOTE D_, 2
	LEN 9
	NOTE D_, 2
	REST
	NOTE Dsh, 2
	REST
	LEN 36
	NOTE Dsh, 2
	LEN 9
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 3
	REST
	LEN 36
	NOTE Dsh, 2
	LEN 9
	NOTE Dsh, 2
	REST
	NOTE D_, 3
	REST
	LEN 18
	NOTE D_, 3
	LEN 9
	NOTE A_, 2
	REST
	LEN 18
	NOTE A_, 2
	LEN 9
	NOTE F_, 2
	REST
	LEN 18
	NOTE F_, 2
	LEN 9
	NOTE E_, 2
	REST
	LEN 18
	NOTE E_, 2
	NEXT
Pat_5041:
	REPEAT 2
	LEN 27
	NOTE D_, 2
	NOTE D_, 3
	LEN 18
	NOTE D_, 2
	LEN 27
	NOTE D_, 2
	NOTE D_, 3
	LEN 18
	NOTE D_, 2
	LEN 27
	NOTE F_, 2
	NOTE F_, 3
	LEN 18
	NOTE F_, 2
	LEN 27
	NOTE Dsh, 2
	NOTE Dsh, 3
	LEN 18
	NOTE Dsh, 2
	REPEAT_END
	NEXT
Pat_5058:
	INSTR 13
	WAVE Wave_771F
	VIBRATO $18, $01, $05
	ARP 3
	LENGTH $5A
	NOTE D_, 5
	ARP_OFF
	LEN 18
	NOTE D_, 5
	NOTE E_, 5
	NOTE D_, 5
	LENGTH $7E
	NOTE A_, 4
	LEN 18
	NOTE D_, 5
	ARP 3
	NOTE D_, 5
	ARP_OFF
	NOTE F_, 5
	LENGTH $36
	NOTE E_, 5
	LEN 18
	NOTE D_, 5
	ARP 3
	NOTE D_, 5
	ARP_OFF
	NOTE D_, 5
	LEN 36
	NOTE Ash, 4
	LENGTH $5A
	NOTE A_, 4
	LEN 18
	NOTE A_, 4
	NEXT
Pat_5083:
	ARP_OFF
	LEN 36
	NOTE Gsh, 4
	LENGTH $5A
	NOTE E_, 4
	LEN 18
	NOTE Gsh, 4
	LEN 36
	NOTE G_, 4
	LENGTH $48
	NOTE Dsh, 4
	LEN 18
	NOTE G_, 4
	NOTE Dsh, 4
	LEN 9
	NOTE F_, 4
	NOTE E_, 4
	LENGTH $6C
	NOTE D_, 4
	LEN 18
	NOTE C_, 4
	LENGTH $90
	NOTE D_, 4
	NEXT
Pat_509F:
	WAVE Wave_77BF
	CH_TRANSPOSE $0C
	ARP_OFF
	LENGTH $6C
	NOTE D_, 3
	LEN 36
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE E_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LENGTH $48
	NOTE Dsh, 4
	LEN 36
	NOTE F_, 4
	LENGTH $7E
	NOTE D_, 4
	LEN 18
	NOTE C_, 4
	NEXT
Pat_50BA:
	ARP_OFF
	LENGTH $6C
	NOTE D_, 4
	LEN 36
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE E_, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE D_, 5
	NOTE C_, 5
	LEN 18
	NOTE D_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NEXT
Pat_50D0:
	ARP_OFF
	LENGTH $6C
	NOTE D_, 5
	LEN 18
	NOTE A_, 4
	NOTE Ash, 4
	LEN 27
	NOTE C_, 5
	NOTE A_, 4
	LEN 18
	NOTE F_, 4
	LEN 27
	NOTE Ash, 4
	NOTE G_, 4
	LEN 18
	NOTE Dsh, 4
	LENGTH $6C
	NOTE D_, 4
	LEN 18
	NOTE D_, 4
	NOTE E_, 4
	LEN 27
	NOTE F_, 4
	NOTE A_, 4
	LEN 18
	NOTE C_, 5
	LEN 27
	NOTE Ash, 4
	NOTE Dsh, 5
	LEN 18
	NOTE G_, 5
	NEXT
Pat_50F2:
	ARP_OFF
	LENGTH $5A
	NOTE F_, 5
	LEN 18
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	LEN 27
	NOTE A_, 5
	NOTE F_, 5
	LEN 18
	NOTE C_, 5
	LEN 27
	NOTE G_, 5
	NOTE Dsh, 5
	LEN 18
	NOTE Ash, 4
	LEN 27
	NOTE D_, 5
	NOTE C_, 5
	LEN 36
	NOTE D_, 5
	LEN 18
	NOTE A_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 27
	NOTE D_, 4
	NOTE F_, 4
	LEN 18
	NOTE A_, 4
	LEN 27
	NOTE G_, 4
	NOTE Dsh, 4
	LEN 9
	NOTE D_, 4
	NOTE Dsh, 4
	NEXT
Pat_5119:
	ARP_OFF
	LENGTH $90
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	CH_TRANSPOSE $00
	NEXT
Pat_5123:
	DRUMS $09, DrumPat_51F6
	HWENV $F2, $12, $73
	ARP 0
	DUTY_12
	VIBRATO $12, $02, $05
	AUTODUTY $00
	LEN 36
	NOTE D_, 3
	NOTE D_, 4
	NOTE Ash, 3
	NOTE A_, 3
	NOTE D_, 3
	NOTE D_, 4
	NOTE Ash, 3
	NOTE A_, 3
	NOTE D_, 3
	NOTE D_, 4
	NOTE Ash, 3
	NOTE A_, 3
	LEN 18
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 4
	NOTE D_, 4
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE A_, 3
	NEXT
Pat_514A:
	LEN 36
	NOTE E_, 3
	NOTE E_, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Ash, 3
	LEN 18
	NOTE G_, 3
	NOTE Dsh, 3
	LEN 36
	NOTE D_, 3
	NOTE A_, 3
	NOTE G_, 3
	LEN 18
	NOTE F_, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE E_, 3
	NEXT
Pat_5165:
	DRUMS $09, DrumPat_51D3
	HWENV $F1, $00
	LEN 18
	ARP 16
	REPEAT 2
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	REPEAT_END
	NEXT
Pat_5181:
	HWENV $F2, $00
	AUTODUTY $03
	ARP 5
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	ARP 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	ARP 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	ARP 5
	NOTE D_, 5
	NOTE D_, 4
	NOTE D_, 5
	NOTE D_, 4
	NOTE D_, 5
	NOTE D_, 4
	ARP 4
	NOTE C_, 5
	NOTE C_, 5
	NEXT
Pat_51AC:
	ARP 0
	AUTODUTY $09
	LEN 9
Pat_51B0:
	REPEAT 2
	NOTE D_, 4
	NOTE A_, 3
	NOTE D_, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE D_, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE D_, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE D_, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 3
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 3
	NOTE F_, 4
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Ash, 3
	REPEAT_END
	NEXT
DrumPat_51D3:
	db DRUM_REPEAT + 3, 1, 6, 6, 6, 9, 0, 6
	db 6, 1, 6, 6, 6, 9, 0, 6
	db 0, DRUM_REPEAT_END, 1, 6, 6, 6, 9, 0
	db 6, 6, 1, 6, 6, 6, 9, 0
	db 9, 9, DRUM_LOOP
DrumPat_51F6:
	db 1, 0, 6, 0, 8, 0, 4, 0
	db 1, 0, 8, 0, 6, 0, 1, 0
	db DRUM_LOOP

; Song 5: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong5:
	ld a, $70
	ld [wInstrTableHi], a
	ld a, $B4
	ld [wInstrTable], a
	call StopAll
	ld de, Song5_Ch1
	call StartMusicCh1
	ld de, Song5_Ch2
	call StartMusicCh2
	ld de, Song5_Ch3
	jp StartMusicCh3

; Unreferenced (1 bytes)
	db $C9
Song5_Ch1:
	dw Pat_5369
	dw Pat_5275
	dw Pat_52E8
	dw Pat_5275
	dw Pat_528A
	dw Pat_52AB
	dw Pat_52D7
	dw Pat_5309
	dw Pat_532D
	dw Pat_5309
	dw Pat_532D
	ORDER_LOOP Song5_Ch1
Song5_Ch2:
	dw Pat_54FF
	dw Pat_53A5
	dw Pat_545E
	dw Pat_53A5
	dw Pat_53D3
	dw Pat_540E
	dw Pat_5456
	dw Pat_5499
	dw Pat_54C4
	dw Pat_5499
	dw Pat_54C4
	ORDER_LOOP Song5_Ch2
Song5_Ch3:
	dw Pat_5663
	dw Pat_5507
	dw Pat_556E
	dw Pat_5507
	dw Pat_553C
	dw Pat_559D
	dw Pat_55CF
	dw Pat_55E1
	dw Pat_5622
	dw Pat_55E1
	dw Pat_5622
	ORDER_LOOP Song5_Ch3
Pat_5275:
	DRUMS $07, DrumPat_5677
	REPEAT 4
	INSTR 11
	NOTE G_, 2
	INSTR 10
	NOTE G_, 2
	NOTE Ash, 3
	INSTR 11
	NOTE G_, 2
	INSTR 10
	NOTE G_, 2
	NOTE C_, 4
	INSTR 11
	NOTE D_, 2
	INSTR 10
	NOTE Ash, 3
	REPEAT_END
	NEXT
Pat_528A:
	REPEAT 2
	INSTR 11
	NOTE C_, 3
	INSTR 10
	NOTE C_, 3
	NOTE Dsh, 4
	INSTR 11
	NOTE C_, 3
	INSTR 10
	NOTE C_, 3
	NOTE F_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 10
	NOTE Dsh, 4
	REPEAT_END
	REPEAT 2
	INSTR 11
	NOTE G_, 2
	INSTR 10
	NOTE G_, 2
	NOTE Ash, 3
	INSTR 11
	NOTE G_, 2
	INSTR 10
	NOTE G_, 2
	NOTE C_, 4
	INSTR 11
	NOTE D_, 2
	INSTR 10
	NOTE Ash, 3
	REPEAT_END
	NEXT
Pat_52AB:
	REPEAT 2
	INSTR 11
	NOTE F_, 2
	INSTR 10
	NOTE F_, 2
	NOTE A_, 3
	INSTR 11
	NOTE F_, 2
	INSTR 10
	NOTE F_, 2
	NOTE Ash, 3
	INSTR 11
	NOTE C_, 2
	INSTR 10
	NOTE A_, 3
	REPEAT_END
	INSTR 11
	NOTE Dsh, 2
	INSTR 10
	NOTE Dsh, 2
	NOTE G_, 3
	INSTR 11
	NOTE Dsh, 2
	INSTR 10
	NOTE Dsh, 2
	NOTE A_, 3
	INSTR 11
	NOTE Ash, 2
	INSTR 10
	NOTE G_, 3
	INSTR 11
	NOTE Dsh, 2
	INSTR 10
	NOTE Dsh, 2
	NOTE G_, 3
	INSTR 11
	NOTE Dsh, 2
	INSTR 10
	NOTE Dsh, 2
	NOTE A_, 3
	INSTR 11
	NOTE Ash, 2
	NOTE A_, 2
	NEXT
Pat_52D7:
	REPEAT 2
	INSTR 11
	NOTE G_, 2
	INSTR 10
	NOTE G_, 2
	NOTE Ash, 3
	INSTR 11
	NOTE G_, 2
	INSTR 10
	NOTE G_, 2
	NOTE C_, 4
	INSTR 11
	NOTE D_, 2
	INSTR 10
	NOTE Ash, 3
	REPEAT_END
	NEXT
Pat_52E8:
	REPEAT 2
	INSTR 11
	NOTE C_, 3
	INSTR 10
	NOTE C_, 3
	NOTE Dsh, 4
	INSTR 11
	NOTE C_, 3
	INSTR 10
	NOTE C_, 3
	NOTE F_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 10
	NOTE Dsh, 4
	REPEAT_END
	REPEAT 2
	INSTR 11
	NOTE G_, 2
	INSTR 10
	NOTE G_, 2
	NOTE Ash, 3
	INSTR 11
	NOTE G_, 2
	INSTR 10
	NOTE G_, 2
	NOTE C_, 4
	INSTR 11
	NOTE D_, 2
	INSTR 10
	NOTE Ash, 3
	REPEAT_END
	NEXT
Pat_5309:
	REPEAT 2
	INSTR 11
	NOTE G_, 2
	INSTR 10
	NOTE G_, 2
	NOTE Ash, 3
	INSTR 11
	NOTE G_, 2
	INSTR 10
	NOTE G_, 2
	NOTE C_, 4
	INSTR 11
	NOTE D_, 2
	INSTR 10
	NOTE Ash, 3
	REPEAT_END
	REPEAT 2
	INSTR 11
	NOTE C_, 3
	INSTR 10
	NOTE C_, 3
	NOTE Dsh, 4
	INSTR 11
	NOTE C_, 3
	INSTR 10
	NOTE C_, 3
	LEN 7
	NOTE F_, 4
	INSTR 11
	NOTE G_, 2
	LEN 14
	NOTE Ash, 2
	INSTR 10
	NOTE Dsh, 4
	REPEAT_END
	NEXT
Pat_532D:
	INSTR 11
	NOTE Gsh, 2
	INSTR 10
	NOTE Gsh, 2
	NOTE C_, 4
	INSTR 11
	NOTE Gsh, 2
	INSTR 10
	NOTE Gsh, 2
	NOTE C_, 4
	INSTR 11
	NOTE Dsh, 2
	INSTR 10
	NOTE C_, 4
	INSTR 11
	NOTE Gsh, 2
	INSTR 10
	NOTE Gsh, 2
	NOTE C_, 4
	INSTR 11
	NOTE Gsh, 2
	INSTR 10
	NOTE Gsh, 2
	NOTE C_, 4
	INSTR 11
	NOTE Dsh, 2
	INSTR 10
	LEN 7
	NOTE C_, 4
	INSTR 11
	NOTE Gsh, 2
	LEN 14
	NOTE G_, 2
	INSTR 10
	NOTE G_, 2
	NOTE Ash, 3
	INSTR 11
	NOTE G_, 2
	INSTR 10
	NOTE G_, 2
	NOTE C_, 4
	INSTR 11
	NOTE D_, 2
	INSTR 10
	NOTE Ash, 3
	INSTR 11
	NOTE F_, 2
	INSTR 10
	NOTE F_, 2
	NOTE A_, 3
	INSTR 11
	NOTE F_, 2
	INSTR 10
	NOTE F_, 2
	NOTE Ash, 3
	INSTR 11
	NOTE C_, 3
	INSTR 10
	NOTE A_, 3
	NEXT
Pat_5369:
	DRUMS $07, DrumPat_5677
	LEN 14
	REPEAT 2
	INSTR 11
	NOTE G_, 2
	INSTR 10
	NOTE G_, 2
	NOTE Ash, 3
	INSTR 11
	NOTE G_, 2
	INSTR 10
	NOTE G_, 2
	NOTE C_, 4
	INSTR 11
	NOTE D_, 2
	INSTR 10
	NOTE Ash, 3
	REPEAT_END
	NEXT
Pat_537F:
	LEN 14
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE D_, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE Dsh, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE D_, 4
	NEXT
Pat_5391:
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE D_, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE Dsh, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	LEN 7
	NOTE D_, 4
	INSTR 2
	NOTE D_, 3
	NEXT
Pat_53A5:
	LEN 14
	PAT_CALL Pat_537F
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE D_, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE Dsh, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	LEN 7
	NOTE D_, 4
	INSTR 2
	NOTE D_, 3
	PAT_CALL Pat_537F
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE D_, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE Dsh, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	LEN 7
	NOTE D_, 4
	INSTR 1
	NOTE A_, 3
	NEXT
Pat_53D3:
	LEN 14
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE G_, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE Gsh, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE G_, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE G_, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE Gsh, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	LEN 7
	NOTE G_, 4
	INSTR 2
	NOTE D_, 3
	PAT_CALL Pat_537F
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE D_, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE Dsh, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	LEN 7
	NOTE D_, 4
	INSTR 1
	NOTE A_, 3
	NEXT
Pat_540E:
	LEN 14
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE C_, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE D_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE C_, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE C_, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE D_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	LEN 7
	NOTE C_, 4
	INSTR 2
	NOTE D_, 3
	LEN 14
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE Ash, 3
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE C_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE Ash, 3
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE Ash, 3
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE C_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	LEN 7
	NOTE Ash, 3
	INSTR 1
	NOTE A_, 3
	NEXT
Pat_5456:
	LEN 14
	PAT_CALL Pat_537F
	PAT_CALL Pat_5391
	NEXT
Pat_545E:
	LEN 14
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE G_, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE Gsh, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE G_, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE G_, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE Gsh, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	LEN 7
	NOTE G_, 4
	INSTR 2
	NOTE D_, 3
	PAT_CALL Pat_537F
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE D_, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE Dsh, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	LEN 7
	NOTE D_, 4
	INSTR 1
	NOTE A_, 3
	NEXT
Pat_5499:
	LEN 14
	PAT_CALL Pat_537F
	PAT_CALL Pat_5391
	LEN 14
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE G_, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE Gsh, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE G_, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE G_, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE Gsh, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	LEN 7
	NOTE G_, 4
	INSTR 1
	NOTE A_, 3
	NEXT
Pat_54C4:
	LEN 14
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE Dsh, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE F_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE Dsh, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE Dsh, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE F_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	LEN 7
	NOTE Dsh, 4
	INSTR 2
	NOTE D_, 3
	PAT_CALL Pat_537F
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE C_, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 10
	NOTE D_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	LEN 7
	NOTE C_, 4
	INSTR 1
	NOTE A_, 3
	NEXT
Pat_54FF:
	LEN 14
	PAT_CALL Pat_537F
	PAT_CALL Pat_5391
	NEXT
Pat_5507:
	ARP_OFF
	LEN 35
	NOTE G_, 4
	LEN 7
	WAIT2
	LEN 14
	NOTE G_, 4
	LEN 35
	NOTE D_, 5
	LEN 7
	WAIT2
	LEN 14
	NOTE D_, 5
	LEN 28
	NOTE C_, 5
	LEN 14
	NOTE Ash, 4
	NOTE A_, 4
	LEN 28
	NOTE G_, 4
	LEN 21
	NOTE F_, 4
	LEN 7
	WAIT2
	ARP 3
	LEN 14
	NOTE G_, 4
	LEN 7
	WAIT2
	ARP_OFF
	LEN 14
	NOTE G_, 4
	LEN 7
	WAIT2
	LEN 14
	NOTE A_, 4
	LENGTH $3F
	NOTE D_, 4
	LEN 7
	WAIT2
	LEN 14
	NOTE G_, 3
	NOTE D_, 4
	NOTE Dsh, 4
	ARP 3
	LEN 28
	NOTE Dsh, 4
	ARP_OFF
	LEN 14
	NOTE Dsh, 4
	NOTE D_, 4
	NEXT
Pat_553C:
	ARP_OFF
	LENGTH $3F
	NOTE G_, 4
	LEN 7
	WAIT2
	LEN 14
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE G_, 4
	LEN 7
	WAIT2
	LEN 14
	NOTE G_, 4
	LEN 7
	WAIT2
	LEN 14
	NOTE G_, 4
	ARP 3
	NOTE F_, 4
	LEN 7
	WAIT2
	ARP_OFF
	LEN 14
	NOTE F_, 4
	LEN 7
	WAIT2
	LEN 14
	NOTE Dsh, 4
	LEN 21
	NOTE D_, 4
	NOTE G_, 4
	LEN 35
	NOTE Ash, 3
	LEN 7
	WAIT2
	LEN 14
	NOTE A_, 3
	NOTE Ash, 3
	LENGTH $3F
	NOTE G_, 3
	LEN 7
	WAIT2
	LEN 14
	NOTE G_, 3
	NOTE A_, 3
	NOTE Ash, 3
	NEXT
Pat_556E:
	ARP_OFF
	LENGTH $3F
	NOTE G_, 4
	LEN 7
	WAIT2
	LEN 14
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE G_, 4
	LEN 7
	WAIT2
	LEN 14
	NOTE G_, 4
	LEN 7
	WAIT2
	NOTE G_, 4
	WAIT2
	ARP 3
	LEN 21
	NOTE F_, 4
	ARP_OFF
	NOTE F_, 4
	LEN 14
	NOTE Dsh, 4
	LEN 21
	NOTE D_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	WAIT2
	LEN 35
	NOTE Ash, 3
	LEN 7
	WAIT2
	LEN 14
	NOTE A_, 3
	NOTE Ash, 3
	LENGTH $46
	NOTE D_, 4
	LEN 14
	WAIT2
	LEN 28
	NOTE D_, 4
	NEXT
Pat_559D:
	ARP_OFF
	LEN 42
	NOTE C_, 4
	LEN 35
	NOTE A_, 3
	LEN 7
	WAIT2
	LEN 28
	NOTE F_, 4
	LEN 35
	NOTE A_, 4
	LEN 7
	WAIT2
	LEN 14
	NOTE C_, 4
	LEN 21
	NOTE A_, 4
	NOTE Ash, 4
	LEN 14
	NOTE A_, 4
	ARP 3
	NOTE G_, 4
	LEN 7
	WAIT2
	ARP_OFF
	LEN 14
	NOTE Ash, 4
	LEN 7
	WAIT2
	LEN 14
	NOTE Dsh, 4
	ARP 3
	LENGTH $3F
	NOTE Csh, 4
	LEN 7
	WAIT2
	ARP_OFF
	LEN 14
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	LEN 7
	NOTE A_, 4
	NOTE G_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE F_, 4
	NEXT
Pat_55CF:
	ARP_OFF
	LENGTH $70
	NOTE D_, 4
	LEN 28
	WAIT2
	VOLENV 15, $11, $1F, $14
	ARP 0
	LEN 42
	NOTE G_, 4
	LEN 28
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NEXT
Pat_55E1:
	ARP 5
	LEN 28
	NOTE G_, 4
	ARP 0
	LEN 14
	NOTE G_, 4
	ARP 5
	LEN 28
	NOTE G_, 4
	ARP 0
	LEN 14
	NOTE G_, 4
	ARP 4
	NOTE Ash, 4
	ARP 0
	NOTE G_, 4
	ARP 5
	LEN 28
	NOTE G_, 4
	ARP 0
	LEN 14
	NOTE G_, 4
	ARP 5
	LEN 28
	NOTE G_, 4
	ARP 0
	LEN 14
	NOTE G_, 4
	ARP 4
	NOTE Ash, 4
	ARP 0
	NOTE G_, 4
	ARP 5
	LEN 28
	NOTE C_, 5
	ARP 0
	LEN 14
	NOTE C_, 4
	ARP 5
	LEN 28
	NOTE C_, 5
	ARP 0
	LEN 14
	NOTE C_, 4
	ARP 4
	NOTE Ash, 4
	ARP 0
	NOTE C_, 4
	ARP 5
	LEN 28
	NOTE C_, 5
	ARP 0
	LEN 14
	NOTE C_, 4
	ARP 5
	LEN 28
	NOTE C_, 5
	ARP 0
	LEN 14
	NOTE C_, 4
	ARP 4
	NOTE Ash, 4
	ARP 0
	NOTE C_, 4
	NEXT
Pat_5622:
	ARP 4
	LEN 28
	NOTE Gsh, 4
	ARP 0
	LEN 14
	NOTE Gsh, 4
	ARP 4
	LEN 28
	NOTE Gsh, 4
	ARP 0
	LEN 14
	NOTE Gsh, 4
	ARP 4
	NOTE Ash, 4
	ARP 0
	NOTE Gsh, 4
	ARP 4
	LEN 28
	NOTE Gsh, 4
	ARP 0
	LEN 14
	NOTE Gsh, 4
	ARP 4
	LEN 28
	NOTE Gsh, 4
	ARP 0
	LEN 14
	NOTE Gsh, 4
	ARP 4
	NOTE Ash, 4
	ARP 0
	NOTE Gsh, 4
	ARP 5
	LEN 28
	NOTE G_, 4
	ARP 0
	LEN 14
	NOTE G_, 4
	ARP 5
	LEN 28
	NOTE G_, 4
	ARP 0
	LEN 14
	NOTE G_, 4
	ARP 4
	NOTE Ash, 4
	ARP 0
	NOTE G_, 4
	ARP 4
	LEN 28
	NOTE F_, 4
	ARP 0
	LEN 14
	NOTE F_, 4
	ARP 4
	LEN 28
	NOTE F_, 4
	ARP 0
	LEN 14
	NOTE F_, 4
	ARP 4
	NOTE Ash, 4
	ARP 0
	NOTE F_, 4
	NEXT
Pat_5663:
	INSTR 13
	CH_TRANSPOSE $00
	VIBRATO $0E, $01, $05
	RELEASE $01, $01
	WAVE Wave_76BF
	LENGTH $C4
	REST
	ARP_OFF
	LEN 28
	NOTE D_, 4
	NEXT
DrumPat_5677:
	db 1, 0, 6, 0, 9, 0, 1, 0
	db 3, 0, 6, 0, 9, 0, 6, 1
	db 1, 0, 6, 0, 9, 0, 1, 0
	db 3, 0, 6, 0, 9, 0, 6, 10
	db DRUM_LOOP

; Song 6: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong6:
	ld a, $70
	ld [wInstrTableHi], a
	ld a, $B4
	ld [wInstrTable], a
	call StopAll
	ld de, Song6_Ch1
	call StartMusicCh1
	ld de, Song6_Ch2
	call StartMusicCh2
	ld de, Song6_Ch3
	jp StartMusicCh3
Song6_Ch1:
	dw Pat_56E7
	dw Pat_56FE
	dw Pat_56E7
	dw Pat_56FE
	dw Pat_5714
	dw Pat_5730
	ORDER_LOOP Song6_Ch1
Song6_Ch2:
	dw Pat_5757
	dw Pat_5772
	dw Pat_5757
	dw Pat_5772
	dw Pat_5785
	dw Pat_5794
	ORDER_LOOP Song6_Ch2
Song6_Ch3:
	dw Pat_57AD
	dw Pat_57DB
	dw Pat_57AD
	dw Pat_57DB
	dw Pat_57FD
	dw Pat_581E
	ORDER_LOOP Song6_Ch3
Pat_56E7:
	INSTR 11
	REPEAT 8
	LEN 12
	NOTE G_, 2
	LEN 6
	NOTE G_, 2
	NOTE G_, 2
	REPEAT_END
	REPEAT 4
	LEN 12
	NOTE G_, 2
	LEN 6
	NOTE G_, 2
	NOTE G_, 2
	REPEAT_END
	REPEAT 4
	LEN 12
	NOTE Dsh, 2
	LEN 6
	NOTE Dsh, 2
	NOTE Dsh, 2
	REPEAT_END
	NEXT
Pat_56FE:
	REPEAT 8
	LEN 12
	NOTE F_, 2
	LEN 6
	NOTE F_, 2
	NOTE F_, 2
	REPEAT_END
	REPEAT 4
	LEN 12
	NOTE Fsh, 2
	LEN 6
	NOTE Fsh, 2
	NOTE Fsh, 2
	REPEAT_END
	REPEAT 4
	LEN 12
	NOTE D_, 2
	LEN 6
	NOTE D_, 2
	NOTE D_, 2
	REPEAT_END
	NEXT
Pat_5714:
	LEN 12
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE D_, 3
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Ash, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE D_, 3
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE F_, 2
	REPEAT 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE F_, 3
	NOTE G_, 3
	NOTE G_, 2
	NOTE D_, 3
	REPEAT_END
	NEXT
Pat_5730:
	LEN 12
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE D_, 3
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Ash, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE D_, 3
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE C_, 3
	LEN 6
	NOTE D_, 3
	NOTE D_, 3
	LEN 12
	NOTE D_, 3
	LEN 6
	NOTE A_, 2
	NOTE D_, 2
	NEXT
Pat_5757:
	INSTR 5
	LEN 24
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 12
	NOTE G_, 4
	ARP 4
	NOTE Ash, 4
	ARP 5
	LEN 24
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	ARP 4
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE Dsh, 5
	LEN 12
	NOTE Dsh, 5
	NOTE Dsh, 5
	NEXT
Pat_5772:
	ARP 4
	LEN 24
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NEXT
Pat_5785:
	INSTR 10
	LEN 6
	REPEAT 8
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Dsh, 4
	REPEAT_END
	REPEAT 8
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE D_, 4
	REPEAT_END
	NEXT
Pat_5794:
	REPEAT 8
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Dsh, 4
	REPEAT_END
	REPEAT 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	REPEAT_END
	REPEAT 2
	NOTE D_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE Fsh, 4
	REPEAT_END
	REPEAT 2
	NOTE Fsh, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE A_, 4
	REPEAT_END
	NEXT
Pat_57AD:
	DRUMS $06, DrumPat_583E
	WAVE Wave_787F
	VIBRATO $0C, $01, $05
	ARP 0
	VOLENV 9, $16, $1F, $1A
	LEN 12
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE C_, 4
	LENGTH $3C
	NOTE D_, 4
	LEN 12
	NOTE D_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE G_, 4
	LEN 24
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE Ash, 4
	NOTE G_, 4
	NEXT
Pat_57DB:
	LENGTH $3C
	NOTE C_, 5
	LEN 12
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	LEN 24
	NOTE F_, 4
	LEN 12
	NOTE F_, 4
	NOTE C_, 5
	NOTE F_, 5
	LEN 36
	NOTE D_, 5
	LEN 24
	NOTE A_, 4
	LEN 12
	NOTE A_, 4
	NOTE D_, 5
	NOTE G_, 5
	LEN 24
	NOTE Fsh, 5
	LEN 12
	NOTE G_, 5
	LEN 24
	NOTE A_, 5
	NOTE Ash, 5
	LEN 12
	NOTE D_, 5
	NEXT
Pat_57FD:
	DRUMS $06, DrumPat_5851
	LEN 36
	WAIT
	NOTE C_, 5
	LEN 24
	NOTE F_, 5
	LEN 36
	NOTE D_, 5
	LEN 24
	NOTE C_, 5
	LEN 12
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 24
	NOTE A_, 4
	LEN 12
	NOTE Ash, 4
	LEN 24
	NOTE A_, 4
	NOTE G_, 4
	LENGTH $3C
	NOTE D_, 4
	LEN 12
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NEXT
Pat_581E:
	LEN 36
	NOTE D_, 5
	NOTE C_, 5
	LEN 24
	NOTE F_, 5
	NOTE D_, 5
	LEN 12
	NOTE Dsh, 5
	LEN 24
	NOTE C_, 5
	LEN 12
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 18
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE D_, 5
	LEN 12
	NOTE Fsh, 5
	NOTE A_, 5
	LEN 18
	NOTE C_, 6
	NOTE Ash, 5
	LEN 12
	NOTE A_, 5
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NEXT
DrumPat_583E:
	db DRUM_REPEAT + 7, 1, 0, 6, 6, 9, 0, 6
	db 6, DRUM_REPEAT_END, 1, 0, 6, 6, 9, 0
	db 9, 9, DRUM_LOOP
DrumPat_5851:
	db DRUM_REPEAT + 7, 1, 6, 6, 6, 9, 0, 6
	db 0, DRUM_REPEAT_END, 1, 0, 6, 0, 9, 0
	db 9, 9, DRUM_LOOP

; Song 7: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong7:
	ld a, $70
	ld [wInstrTableHi], a
	ld a, $B4
	ld [wInstrTable], a
	call StopAll
	ld de, Song7_Ch1
	call StartMusicCh1
	ld de, Song7_Ch2
	call StartMusicCh2
	ld de, Song7_Ch3
	jp StartMusicCh3
Song7_Ch1:
	dw Pat_58B3
	dw Pat_58CA
	dw Pat_58EC
	dw Pat_58FF
	dw Pat_5924
	dw Pat_5947
	ORDER_LOOP Song7_Ch1
Song7_Ch3:
	dw Pat_596D
	dw Pat_599F
	dw Pat_59C4
	dw Pat_59E2
	dw Pat_5A02
	dw Pat_5A37
	ORDER_LOOP Song7_Ch3
Song7_Ch2:
	dw Pat_5A6B
	dw Pat_5A6F
	dw Pat_5AA2
	dw Pat_5ABD
	dw Pat_5AE0
	dw Pat_5B0D
	ORDER_LOOP Song7_Ch2
Pat_58B3:
	HWENV $F5, $00
	DUTY_50
	VIBRATO $0A, $02, $05
	ARP 0
	RELEASE $01, $01
	LENGTH $50
	NOTE Dsh, 2
	NOTE E_, 2
	NOTE Csh, 2
	LENGTH $3C
	NOTE D_, 2
	LEN 20
	NOTE D_, 2
	NEXT
Pat_58CA:
	LEN 20
	NOTE Dsh, 2
	LEN 10
	NOTE Dsh, 2
	LEN 20
	NOTE Dsh, 3
	LEN 30
	NOTE Dsh, 2
	LEN 20
	NOTE E_, 2
	LEN 10
	NOTE E_, 2
	LEN 20
	NOTE E_, 3
	LEN 30
	NOTE E_, 2
	LEN 20
	NOTE Csh, 2
	LEN 10
	NOTE Csh, 2
	LEN 20
	NOTE Csh, 3
	LEN 30
	NOTE Csh, 2
	LEN 20
	NOTE D_, 2
	LEN 10
	NOTE D_, 2
	LEN 20
	NOTE D_, 3
	NOTE D_, 2
	LEN 10
	NOTE D_, 3
	NEXT
Pat_58EC:
	LEN 20
	NOTE D_, 2
	LEN 10
	NOTE D_, 2
	LEN 20
	NOTE D_, 3
	LEN 30
	NOTE D_, 2
	LEN 20
	NOTE D_, 2
	LEN 10
	NOTE D_, 2
	LEN 20
	NOTE D_, 3
	LEN 10
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NEXT
Pat_58FF:
	REPEAT 3
	LEN 20
	NOTE Csh, 2
	LEN 10
	NOTE Csh, 2
	LEN 20
	NOTE Csh, 3
	LEN 30
	NOTE Csh, 2
	LEN 20
	NOTE Csh, 2
	LEN 10
	NOTE Csh, 2
	LEN 20
	NOTE Csh, 3
	NOTE Csh, 2
	LEN 10
	NOTE Gsh, 2
	REPEAT_END
	LEN 20
	NOTE D_, 2
	LEN 10
	NOTE D_, 2
	LEN 20
	NOTE D_, 3
	LEN 30
	NOTE D_, 2
	LEN 20
	NOTE D_, 2
	LEN 10
	NOTE D_, 2
	LEN 20
	NOTE D_, 3
	NOTE D_, 2
	LEN 10
	NOTE A_, 2
	NEXT
Pat_5924:
	LEN 20
	NOTE D_, 2
	LEN 10
	NOTE D_, 2
	NOTE D_, 3
	LEN 20
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE B_, 2
	NOTE E_, 2
	LEN 10
	NOTE Gsh, 2
	NOTE B_, 2
	LEN 20
	NOTE Csh, 2
	NOTE Csh, 2
	NOTE Csh, 2
	NOTE Csh, 2
	NOTE Csh, 2
	NOTE Csh, 2
	LEN 10
	NOTE Csh, 3
	NOTE Gsh, 2
	NOTE Fsh, 2
	NOTE Csh, 2
	NEXT
Pat_5947:
	LEN 30
	NOTE Fsh, 2
	NOTE Gsh, 2
	LEN 10
	NOTE E_, 2
	NOTE Gsh, 2
	LEN 30
	NOTE A_, 2
	LEN 20
	NOTE B_, 2
	LEN 10
	NOTE Fsh, 2
	NOTE B_, 2
	NOTE D_, 3
	LEN 20
	REPEAT 8
	NOTE Csh, 3
	REPEAT_END
	NOTE Csh, 2
	LEN 10
	NOTE Csh, 3
	LEN 20
	NOTE Csh, 2
	LEN 10
	NOTE Csh, 3
	LEN 20
	NOTE Csh, 2
	LEN 10
	NOTE Csh, 3
	LEN 20
	NOTE Csh, 2
	LEN 10
	NOTE Csh, 3
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE Csh, 2
	NOTE Csh, 2
	NEXT
Pat_596D:
	VOLENV 15, $11, $1F, $17
	VIBRATO $0A, $01, $06
	CH_TRANSPOSE $00
	RELEASE $01, $01
	WAVE Wave_76BF
	LEN 10
	NOTE Dsh, 3
	NOTE Ash, 3
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE E_, 3
	NOTE B_, 3
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE B_, 3
	NOTE Csh, 3
	NOTE Gsh, 3
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE Gsh, 3
	NOTE D_, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NEXT
Pat_599F:
	LEN 20
	NOTE Ash, 4
	LEN 10
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE Fsh, 5
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE Ash, 4
	LEN 20
	NOTE B_, 4
	LEN 10
	NOTE E_, 5
	NOTE Fsh, 5
	NOTE Gsh, 5
	NOTE Fsh, 5
	NOTE E_, 5
	NOTE B_, 4
	LEN 20
	NOTE Gsh, 4
	LEN 10
	NOTE Csh, 5
	NOTE Dsh, 5
	NOTE E_, 5
	NOTE Dsh, 5
	NOTE Csh, 5
	NOTE Gsh, 4
	LEN 20
	NOTE A_, 4
	LEN 10
	NOTE D_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE Fsh, 5
	NOTE A_, 5
	NEXT
Pat_59C4:
	LEN 10
	NOTE D_, 5
	NOTE E_, 5
	NOTE Fsh, 5
	NOTE A_, 5
	VOLENV 10, $11, $1F, $17
	NOTE D_, 5
	NOTE E_, 5
	NOTE Fsh, 5
	NOTE A_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE Fsh, 5
	NOTE A_, 5
	VOLENV 5, $11, $1F, $17
	NOTE D_, 5
	NOTE E_, 5
	NOTE Fsh, 5
	NOTE A_, 5
	VOLENV 15, $11, $1F, $17
	NEXT
Pat_59E2:
	LENGTH $50
	NOTE Csh, 4
	NOTE Gsh, 4
	LEN 40
	NOTE G_, 4
	NOTE Dsh, 4
	LENGTH $50
	NOTE Fsh, 4
	LENGTH $3C
	NOTE Gsh, 4
	LEN 20
	NOTE Dsh, 5
	NOTE E_, 5
	NOTE Csh, 5
	NOTE Gsh, 4
	NOTE E_, 4
	LENGTH $5A
	NOTE D_, 4
	LEN 10
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	LEN 20
	NOTE A_, 4
	LEN 10
	NOTE Fsh, 4
	NOTE D_, 4
	NEXT
Pat_5A02:
	LEN 10
	NOTE D_, 5
	NOTE Csh, 5
	NOTE D_, 5
	LEN 20
	NOTE A_, 4
	LEN 10
	NOTE D_, 5
	NOTE Csh, 5
	NOTE D_, 5
	NOTE A_, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE E_, 5
	NOTE Dsh, 5
	NOTE E_, 5
	LEN 20
	NOTE B_, 4
	LEN 10
	NOTE E_, 5
	NOTE Dsh, 5
	NOTE E_, 5
	NOTE B_, 4
	NOTE E_, 4
	NOTE Gsh, 4
	NOTE E_, 4
	NOTE B_, 4
	NOTE Gsh, 4
	NOTE E_, 5
	NOTE B_, 4
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	LEN 20
	NOTE Csh, 5
	LEN 10
	NOTE F_, 5
	NOTE Fsh, 5
	NOTE Gsh, 5
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE Fsh, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NEXT
Pat_5A37:
	LEN 10
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE A_, 4
	LEN 20
	NOTE Gsh, 4
	LEN 10
	NOTE A_, 4
	NOTE B_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE Csh, 5
	LEN 20
	NOTE B_, 4
	LEN 10
	NOTE Csh, 5
	NOTE D_, 5
	NOTE B_, 4
	NOTE Csh, 5
	NOTE Csh, 6
	NOTE D_, 6
	NOTE Csh, 4
	NOTE C_, 6
	NOTE Csh, 6
	NOTE Csh, 4
	NOTE Ash, 5
	NOTE B_, 5
	NOTE Csh, 4
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE F_, 5
	NOTE Fsh, 5
	NOTE Csh, 5
	NOTE D_, 5
	NOTE Csh, 3
	NOTE Csh, 5
	NOTE D_, 5
	NOTE Csh, 3
	NOTE C_, 5
	NOTE Csh, 5
	NOTE Csh, 3
	NOTE Ash, 4
	NOTE B_, 4
	NOTE Csh, 3
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE Csh, 4
	NOTE D_, 4
	NEXT
Pat_5A6B:
	DRUMS $05, DrumPat_5B4C
Pat_5A6F:
	INSTR 14
	LEN 10
	NOTE Ash, 3
	NOTE Dsh, 3
	INSTR 5
	NOTE Dsh, 4
	INSTR 14
	NOTE Ash, 3
	NOTE Dsh, 3
	INSTR 5
	NOTE Dsh, 4
	INSTR 14
	NOTE Ash, 3
	NOTE Dsh, 3
	NOTE B_, 3
	NOTE E_, 3
	INSTR 4
	NOTE E_, 4
	INSTR 14
	NOTE B_, 3
	NOTE E_, 3
	INSTR 4
	NOTE E_, 4
	INSTR 14
	NOTE B_, 3
	NOTE E_, 3
	NOTE Gsh, 3
	NOTE Csh, 3
	INSTR 5
	NOTE Csh, 4
	INSTR 14
	NOTE Gsh, 3
	NOTE Csh, 3
	INSTR 5
	NOTE Csh, 4
	INSTR 14
	NOTE Gsh, 3
	NOTE Csh, 3
	NOTE A_, 3
	NOTE D_, 3
	INSTR 4
	NOTE D_, 4
	INSTR 14
	NOTE A_, 3
	NOTE D_, 3
	INSTR 4
	NOTE D_, 4
	INSTR 14
	NOTE A_, 3
	NOTE D_, 3
	NEXT
Pat_5AA2:
	INSTR 14
	LEN 10
	NOTE A_, 3
	NOTE D_, 3
	INSTR 4
	NOTE D_, 4
	INSTR 14
	NOTE A_, 3
	NOTE D_, 3
	INSTR 4
	NOTE D_, 4
	INSTR 14
	NOTE A_, 3
	NOTE D_, 3
	NOTE A_, 3
	NOTE D_, 3
	INSTR 4
	NOTE D_, 4
	INSTR 14
	NOTE A_, 3
	NOTE D_, 3
	INSTR 4
	NOTE D_, 4
	INSTR 14
	NOTE A_, 3
	NOTE D_, 3
	NEXT
Pat_5ABD:
	INSTR 14
	LEN 10
	REPEAT 6
	NOTE Gsh, 3
	LEN 20
	NOTE Csh, 3
	LEN 10
	NOTE Gsh, 3
	LEN 20
	NOTE Csh, 3
	LEN 10
	NOTE Gsh, 3
	NOTE Csh, 3
	REPEAT_END
	NOTE A_, 3
	LEN 20
	NOTE D_, 3
	LEN 10
	NOTE A_, 3
	LEN 20
	NOTE D_, 3
	LEN 10
	NOTE A_, 3
	NOTE D_, 3
	NOTE A_, 3
	LEN 20
	NOTE D_, 3
	LEN 10
	NOTE A_, 3
	LEN 20
	NOTE D_, 3
	LEN 10
	NOTE A_, 3
	NOTE D_, 3
	NEXT
Pat_5AE0:
	INSTR 14
	LEN 10
	REPEAT 2
	NOTE A_, 3
	NOTE D_, 3
	INSTR 4
	NOTE D_, 4
	INSTR 14
	NOTE A_, 3
	NOTE D_, 3
	INSTR 4
	NOTE D_, 4
	INSTR 14
	NOTE A_, 3
	NOTE D_, 3
	REPEAT_END
	REPEAT 2
	NOTE B_, 3
	NOTE E_, 3
	INSTR 4
	NOTE E_, 4
	INSTR 14
	NOTE B_, 3
	NOTE E_, 3
	INSTR 4
	NOTE E_, 4
	INSTR 14
	NOTE B_, 3
	NOTE E_, 3
	REPEAT_END
	REPEAT 2
	NOTE Csh, 4
	NOTE Gsh, 3
	INSTR 4
	NOTE Csh, 4
	INSTR 14
	NOTE Csh, 4
	NOTE Gsh, 3
	INSTR 4
	NOTE Csh, 4
	INSTR 14
	NOTE Csh, 4
	NOTE Gsh, 3
	REPEAT_END
	NEXT
Pat_5B0D:
	INSTR 14
	LEN 10
	NOTE Fsh, 3
	NOTE Gsh, 3
	NOTE A_, 3
	LEN 20
	NOTE Gsh, 3
	LEN 10
	NOTE A_, 3
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE E_, 3
	NOTE A_, 3
	LEN 20
	NOTE B_, 3
	LEN 10
	NOTE Fsh, 3
	NOTE B_, 3
	NOTE D_, 4
	REPEAT 2
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	REPEAT_END
	INSTR 4
	LEN 20
	NOTE Csh, 4
	INSTR 14
	LEN 10
	NOTE Csh, 4
	INSTR 4
	LEN 20
	NOTE Csh, 4
	INSTR 14
	LEN 10
	NOTE Csh, 4
	INSTR 4
	LEN 20
	NOTE Csh, 4
	INSTR 14
	LEN 10
	NOTE Csh, 4
	INSTR 4
	LEN 20
	NOTE Csh, 4
	INSTR 14
	LEN 10
	NOTE Csh, 4
	INSTR 4
	NOTE Csh, 4
	INSTR 14
	NOTE Csh, 4
	INSTR 4
	NOTE Csh, 4
	INSTR 14
	NOTE Csh, 3
	NEXT
DrumPat_5B4C:
	db 1, 0, 6, 0, 2, 0, 1, 0
	db 6, 0, 1, 0, 2, 0, 1, 0
	db 1, 0, 6, 0, 2, 0, 1, 0
	db 1, 0, 6, 0, 2, 0, 1, 6
	db DRUM_LOOP

; Song 8: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong8:
	ld a, $70
	ld [wInstrTableHi], a
	ld a, $B4
	ld [wInstrTable], a
	call StopAll
	ld de, Song8_Ch1
	call StartMusicCh1
	ld de, Song8_Ch2
	call StartMusicCh2
	ld de, Song8_Ch3
	jp StartMusicCh3
Song8_Ch1:
	dw Pat_5BBC
	dw Pat_5BBC
	dw Pat_5BFE
	dw Pat_5BFE
	dw Pat_5C40
	dw Pat_5C40
	ORDER_LOOP Song8_Ch1
Song8_Ch2:
	dw Pat_5C81
	dw Pat_5C81
	dw Pat_5CC5
	dw Pat_5CC5
	dw Pat_5D16
	dw Pat_5D16
	ORDER_LOOP Song8_Ch2
Song8_Ch3:
	dw Pat_5D65
	dw Pat_5D65
	dw Pat_5DBE
	dw Pat_5DBE
	dw Pat_5E03
	dw Pat_5E03
	ORDER_LOOP Song8_Ch3
Pat_5BBC:
	INSTR 11
	LEN 20
	NOTE C_, 2
	INSTR 5
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	INSTR 5
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 5
	NOTE G_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 5
	NOTE G_, 4
	INSTR 11
	NOTE C_, 2
	INSTR 5
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	INSTR 5
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 5
	NOTE G_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 5
	NOTE G_, 4
	INSTR 11
	NOTE Dsh, 2
	INSTR 4
	NOTE Dsh, 4
	INSTR 11
	NOTE Dsh, 2
	INSTR 4
	NOTE Dsh, 4
	INSTR 11
	NOTE Ash, 2
	INSTR 4
	NOTE Ash, 4
	INSTR 11
	NOTE Ash, 2
	INSTR 4
	NOTE Ash, 4
	INSTR 11
	NOTE C_, 2
	INSTR 5
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	INSTR 5
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 5
	NOTE G_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 5
	NOTE G_, 4
	NEXT
Pat_5BFE:
	INSTR 11
	LEN 20
	NOTE C_, 2
	INSTR 5
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	INSTR 5
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 5
	NOTE G_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 5
	NOTE G_, 4
	INSTR 11
	NOTE C_, 2
	INSTR 5
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	INSTR 5
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 5
	NOTE G_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 5
	NOTE G_, 4
	INSTR 11
	NOTE C_, 2
	INSTR 5
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	INSTR 5
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 5
	NOTE G_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 5
	NOTE G_, 4
	INSTR 11
	NOTE C_, 2
	INSTR 5
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	INSTR 5
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 5
	NOTE G_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 5
	NOTE C_, 4
	NEXT
Pat_5C40:
	INSTR 11
	LEN 20
	NOTE Dsh, 2
	INSTR 4
	NOTE Dsh, 4
	INSTR 11
	NOTE Dsh, 2
	INSTR 4
	NOTE Dsh, 4
	INSTR 11
	NOTE Ash, 2
	INSTR 4
	NOTE Ash, 4
	INSTR 11
	NOTE Ash, 2
	INSTR 4
	NOTE Ash, 4
	INSTR 11
	NOTE C_, 2
	INSTR 5
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	INSTR 5
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 5
	NOTE G_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 5
	NOTE G_, 4
	INSTR 11
	NOTE Gsh, 2
	INSTR 4
	NOTE Gsh, 4
	INSTR 11
	NOTE Gsh, 2
	INSTR 4
	NOTE Gsh, 4
	INSTR 11
	NOTE Ash, 2
	INSTR 4
	NOTE Ash, 4
	INSTR 11
	NOTE Ash, 2
	INSTR 4
	NOTE Ash, 4
	INSTR 11
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 11
	NOTE C_, 2
	INSTR 5
	NOTE C_, 4
	INSTR 11
	NOTE Ash, 2
	NOTE F_, 2
	NEXT
Pat_5C81:
	INSTR 9
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 20
	NOTE F_, 3
	LEN 10
	NOTE G_, 3
	NOTE G_, 3
	LEN 20
	NOTE F_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 10
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 20
	NOTE Ash, 3
	LEN 10
	NOTE Ash, 3
	NOTE Ash, 3
	LEN 20
	NOTE C_, 4
	NOTE Ash, 3
	NOTE G_, 3
	LEN 10
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 20
	NOTE Ash, 3
	LEN 10
	NOTE Ash, 3
	NOTE Ash, 3
	LEN 20
	NOTE F_, 3
	NOTE Ash, 3
	NOTE C_, 4
	LEN 10
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	LEN 20
	NOTE Ash, 3
	LEN 10
	NOTE Ash, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NEXT
Pat_5CC5:
	INSTR 9
	LEN 20
	NOTE C_, 3
	LEN 10
	NOTE G_, 3
	NOTE G_, 3
	LEN 20
	NOTE C_, 3
	LEN 10
	NOTE G_, 3
	NOTE G_, 3
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE D_, 4
	NOTE D_, 4
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE D_, 4
	NOTE D_, 4
	LEN 20
	NOTE C_, 3
	LEN 10
	NOTE G_, 3
	NOTE G_, 3
	LEN 20
	NOTE C_, 3
	LEN 10
	NOTE G_, 3
	NOTE G_, 3
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE D_, 4
	NOTE D_, 4
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE D_, 4
	NOTE D_, 4
	LEN 20
	NOTE C_, 3
	LEN 10
	NOTE G_, 3
	NOTE G_, 3
	LEN 20
	NOTE C_, 3
	LEN 10
	NOTE G_, 3
	NOTE G_, 3
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE D_, 4
	NOTE D_, 4
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE D_, 4
	NOTE D_, 4
	LEN 20
	NOTE C_, 3
	LEN 10
	NOTE G_, 3
	NOTE G_, 3
	LEN 20
	NOTE C_, 3
	LEN 10
	NOTE G_, 3
	NOTE G_, 3
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE D_, 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NEXT
Pat_5D16:
	INSTR 9
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE Ash, 3
	NOTE Dsh, 4
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE Ash, 3
	NOTE Dsh, 4
	LEN 20
	NOTE F_, 3
	LEN 10
	NOTE Ash, 3
	NOTE D_, 4
	LEN 20
	NOTE F_, 3
	LEN 10
	NOTE Ash, 3
	NOTE D_, 4
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE C_, 4
	NOTE Dsh, 4
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE C_, 4
	NOTE Dsh, 4
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE Ash, 3
	NOTE D_, 4
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE Ash, 3
	NOTE D_, 4
	LEN 20
	NOTE Gsh, 3
	LEN 10
	NOTE C_, 4
	NOTE Dsh, 4
	LEN 20
	NOTE Gsh, 3
	LEN 10
	NOTE C_, 4
	NOTE Dsh, 4
	LEN 20
	NOTE Ash, 3
	LEN 10
	NOTE D_, 4
	NOTE F_, 4
	LEN 20
	NOTE Ash, 3
	LEN 10
	NOTE D_, 4
	NOTE F_, 4
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE G_, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE G_, 3
	NOTE F_, 3
	NOTE Ash, 3
	NOTE D_, 4
	NOTE F_, 3
	NEXT
Pat_5D65:
	WAVE Wave_77FF
	DRUMS $0A, DrumPat_5E4C
	CH_TRANSPOSE $0C
	RELEASE $01, $01
	VIBRATO $05, $01, $04
	INSTR 13
	LEN 20
	NOTE C_, 4
	LEN 10
	WAIT2
	NOTE G_, 4
	NOTE C_, 5
	WAIT2
	NOTE Dsh, 5
	WAIT2
	LEN 20
	NOTE D_, 5
	LEN 10
	WAIT2
	NOTE F_, 4
	NOTE Ash, 4
	WAIT2
	NOTE D_, 5
	WAIT2
	LEN 20
	NOTE C_, 5
	LEN 10
	WAIT2
	NOTE G_, 4
	NOTE C_, 5
	WAIT2
	NOTE Dsh, 5
	WAIT2
	LEN 30
	NOTE D_, 5
	LEN 10
	WAIT2
	NOTE C_, 5
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE F_, 5
	LEN 20
	NOTE G_, 5
	LEN 10
	WAIT2
	NOTE Ash, 4
	NOTE Dsh, 5
	WAIT2
	NOTE G_, 5
	WAIT2
	LEN 20
	NOTE F_, 5
	LEN 10
	WAIT2
	NOTE Ash, 4
	NOTE D_, 5
	WAIT2
	NOTE F_, 5
	WAIT2
	LEN 20
	NOTE Dsh, 5
	LEN 10
	WAIT2
	NOTE G_, 4
	NOTE C_, 5
	WAIT2
	NOTE Dsh, 5
	WAIT2
	LEN 20
	NOTE D_, 5
	LEN 10
	WAIT2
	NOTE F_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE Ash, 4
	NEXT
Pat_5DBE:
	INSTR 6
	LEN 10
	NOTE C_, 4
	WAIT2
	NOTE G_, 4
	NOTE G_, 4
	WAIT2
	NOTE G_, 4
	NOTE G_, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE C_, 5
	WAIT2
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE G_, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE G_, 4
	NOTE G_, 4
	WAIT2
	NOTE G_, 4
	NOTE G_, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE C_, 5
	WAIT2
	LEN 20
	NOTE F_, 4
	NOTE Ash, 3
	LEN 10
	NOTE C_, 4
	WAIT2
	NOTE G_, 4
	NOTE G_, 4
	WAIT2
	NOTE G_, 4
	NOTE G_, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE C_, 5
	WAIT2
	LEN 20
	NOTE D_, 5
	LEN 10
	NOTE Ash, 4
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE G_, 4
	NOTE Dsh, 5
	WAIT2
	NOTE D_, 5
	NOTE C_, 5
	WAIT2
	LEN 20
	NOTE Ash, 4
	NOTE D_, 5
	LEN 10
	NOTE F_, 4
	WAIT2
	NOTE Dsh, 4
	NOTE D_, 4
	NEXT
Pat_5E03:
	LEN 10
	NOTE Dsh, 4
	WAIT2
	WAVE Wave_77FF
	INSTR 13
	NOTE Dsh, 5
	NOTE G_, 5
	WAIT2
	NOTE Gsh, 5
	NOTE Ash, 5
	WAIT2
	NOTE F_, 5
	WAIT2
	NOTE D_, 5
	WAIT2
	LEN 20
	NOTE Gsh, 5
	LEN 30
	NOTE G_, 5
	LEN 10
	WAIT2
	NOTE C_, 5
	NOTE Dsh, 5
	WAIT2
	NOTE F_, 5
	NOTE G_, 5
	WAIT2
	NOTE D_, 5
	WAIT2
	NOTE Ash, 4
	WAIT2
	LEN 20
	NOTE G_, 4
	LEN 30
	NOTE C_, 5
	LEN 10
	WAIT2
	NOTE Gsh, 4
	NOTE C_, 5
	WAIT2
	NOTE D_, 5
	NOTE Dsh, 5
	WAIT2
	LEN 20
	NOTE Dsh, 5
	LEN 10
	NOTE F_, 5
	LEN 20
	NOTE D_, 5
	LEN 10
	WAIT2
	NOTE Ash, 4
	WAIT2
	LEN 20
	NOTE G_, 4
	NOTE B_, 4
	LEN 10
	NOTE D_, 5
	WAIT2
	NOTE G_, 5
	WAIT2
	LEN 20
	NOTE F_, 5
	LEN 10
	NOTE Dsh, 5
	NOTE D_, 5
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE Ash, 4
	NEXT
DrumPat_5E4C:
	db DRUM_TEMPO + 10, 1, 6, 3, 6, 9, 6, 4
	db 6, 1, 6, 3, 6, 9, 6, 4
	db DRUM_TEMPO + 5, 6, 6, DRUM_LOOP

; Song 9: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong9:
	ld a, $70
	ld [wInstrTableHi], a
	ld a, $B4
	ld [wInstrTable], a
	call StopAll
	ld de, Song9_Ch1
	call StartMusicCh1
	ld de, Song9_Ch2
	call StartMusicCh2
	ld de, Song9_Ch3
	jp StartMusicCh3
Song9_Ch1:
	dw Pat_5EBB
	dw Pat_5EC7
	dw Pat_5EC7
	dw Pat_5ED2
	dw Pat_5EC7
	dw Pat_5ED2
	dw Pat_5EDA
	dw Pat_5EDA
	ORDER_LOOP Song9_Ch1
Song9_Ch2:
	dw Pat_5EF3
	dw Pat_5F1E
	dw Pat_5F74
	dw Pat_5F8B
	dw Pat_5F74
	dw Pat_5F8B
	dw Pat_5F45
	dw Pat_5F45
	ORDER_LOOP Song9_Ch2
Song9_Ch3:
	dw Pat_5FC4
	dw Pat_5FFF
	dw Pat_6029
	dw Pat_604B
	dw Pat_6029
	dw Pat_604B
	dw Pat_6072
	dw Pat_6072
	ORDER_LOOP Song9_Ch3
Pat_5EBB:
	LEN 12
	REPEAT 8
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 2
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 2
	REPEAT_END
	NEXT
Pat_5EC7:
	REPEAT 8
	INSTR 11
	NOTE D_, 2
	INSTR 5
	NOTE D_, 4
	INSTR 11
	NOTE D_, 2
	INSTR 5
	NOTE D_, 4
	REPEAT_END
	NEXT
Pat_5ED2:
	CH_TRANSPOSE $03
	PAT_CALL Pat_5EC7
	CH_TRANSPOSE $00
	NEXT
Pat_5EDA:
	REPEAT 10
	INSTR 16
	NOTE D_, 2
	INSTR 5
	NOTE D_, 4
	REPEAT_END
	REPEAT 2
	INSTR 16
	NOTE F_, 2
	INSTR 4
	NOTE F_, 4
	REPEAT_END
	REPEAT 2
	INSTR 16
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	REPEAT_END
	REPEAT 2
	INSTR 16
	NOTE D_, 2
	INSTR 5
	NOTE D_, 4
	REPEAT_END
	NEXT
Pat_5EF3:
	HWENV $B0, $00
	ARP_OFF
	DUTY_50
	LEN 24
	NOTE A_, 3
	LEN 12
	NOTE E_, 4
	NOTE F_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 3
	LEN 24
	NOTE A_, 3
	LEN 12
	NOTE E_, 4
	NOTE F_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 3
	NOTE A_, 3
	NOTE D_, 3
	NOTE C_, 4
	NOTE D_, 3
	NOTE D_, 4
	LEN 6
	NOTE C_, 4
	NOTE B_, 3
	LEN 12
	NOTE A_, 3
	NOTE B_, 3
	NOTE F_, 3
	NOTE A_, 3
	LEN 24
	NOTE G_, 3
	LEN 36
	NOTE D_, 3
	LEN 12
	NOTE A_, 3
	NEXT
Pat_5F1E:
	LEN 24
	NOTE A_, 3
	LEN 12
	NOTE E_, 4
	NOTE F_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 3
	LEN 24
	NOTE A_, 3
	LEN 12
	NOTE E_, 4
	NOTE F_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 3
	NOTE A_, 3
	NOTE D_, 3
	NOTE C_, 4
	NOTE D_, 3
	NOTE D_, 4
	LEN 6
	NOTE C_, 4
	NOTE B_, 3
	LEN 12
	NOTE A_, 3
	NOTE B_, 3
	NOTE F_, 3
	NOTE A_, 3
	LEN 24
	NOTE G_, 3
	LEN 12
	NOTE D_, 3
	NOTE A_, 3
	NOTE D_, 3
	NOTE A_, 3
	NEXT
Pat_5F45:
	HWENV $B0, $00
	ARP_OFF
	DUTY_50
	PAT_GOTO Pat_5F1E

; Unreferenced (39 bytes)
	db $D9, $21, $CD, $28, $29, $21, $28, $24, $1F, $D9, $21, $CD, $28, $29, $21, $28
	db $24, $1F, $21, $1A, $24, $1A, $26, $C7, $24, $23, $CD, $21, $23, $1D, $21, $D9
	db $1F, $CD, $1A, $21, $1A, $21, $6A
Pat_5F74:
	HWENV $F2, $00
	ARP_OFF
	DUTY_12
	LEN 12
	REPEAT 4
	NOTE D_, 3
	NOTE F_, 3
	REPEAT_END
	REPEAT 4
	NOTE E_, 3
	NOTE G_, 3
	REPEAT_END
	REPEAT 4
	NOTE F_, 3
	NOTE A_, 3
	REPEAT_END
	REPEAT 4
	NOTE E_, 3
	NOTE G_, 3
	REPEAT_END
	NEXT
Pat_5F8B:
	LEN 12
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE F_, 3
	NOTE Gsh, 3
	LEN 6
	NOTE F_, 3
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	LEN 12
	NOTE G_, 3
	NOTE Ash, 3
	NOTE G_, 3
	NOTE Ash, 3
	LEN 6
	NOTE G_, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE Ash, 3
	LEN 12
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE C_, 4
	LEN 6
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE C_, 4
	LEN 12
	NOTE G_, 3
	NOTE Ash, 3
	NOTE G_, 3
	NOTE Ash, 3
	LEN 6
	NOTE G_, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NEXT
Pat_5FC4:
	DRUMS $06, DrumPat_60A1
	VOLENV 15, $11, $1F, $12
	ARP 0
	CH_TRANSPOSE $00
	VIBRATO $18, $01, $06
	WAVE Wave_775F
	LEN 24
	NOTE A_, 4
	LEN 12
	NOTE E_, 5
	LEN 24
	NOTE F_, 5
	LEN 12
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 4
	LEN 24
	NOTE A_, 4
	LEN 12
	NOTE E_, 5
	LEN 24
	NOTE F_, 5
	LEN 12
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 4
	NOTE A_, 4
	NOTE D_, 4
	LEN 24
	NOTE C_, 5
	LEN 12
	NOTE D_, 5
	LEN 6
	NOTE C_, 5
	NOTE B_, 4
	LEN 12
	NOTE A_, 4
	NOTE B_, 4
	NOTE F_, 4
	NOTE A_, 4
	LEN 24
	NOTE G_, 4
	LEN 36
	NOTE D_, 4
	LEN 12
	NOTE A_, 4
	NEXT
Pat_5FFF:
	DRUMS $06, DrumPat_60C4
	LEN 24
	NOTE A_, 4
	LEN 12
	NOTE E_, 5
	NOTE F_, 5
	NOTE A_, 4
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 4
	LEN 24
	NOTE A_, 4
	LEN 12
	NOTE E_, 5
	NOTE F_, 5
	NOTE A_, 4
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 4
	NOTE A_, 4
	NOTE D_, 4
	LEN 24
	NOTE C_, 5
	LEN 12
	NOTE D_, 5
	LEN 6
	NOTE C_, 5
	NOTE B_, 4
	LEN 12
	NOTE A_, 4
	NOTE B_, 4
	NOTE F_, 4
	NOTE A_, 4
	LEN 24
	NOTE G_, 4
	LENGTH $30
	NOTE D_, 4
	NEXT
Pat_6029:
	INSTR 13
	CH_TRANSPOSE $0C
	WAVE Wave_782F
	LENGTH $6C
	NOTE A_, 4
	LEN 12
	WAIT2
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE G_, 4
	LENGTH $36
	NOTE A_, 4
	LEN 6
	WAIT2
	LEN 12
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 36
	NOTE E_, 4
	LEN 12
	NOTE D_, 4
	LENGTH $30
	NOTE C_, 4
	NEXT
Pat_604B:
	LEN 36
	NOTE F_, 4
	LEN 12
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 6
	NOTE G_, 4
	NOTE Gsh, 4
	LENGTH $30
	NOTE F_, 4
	LEN 12
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	LENGTH $3C
	NOTE C_, 5
	LEN 12
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	LEN 6
	NOTE C_, 5
	NOTE Csh, 5
	LEN 42
	NOTE C_, 5
	LEN 6
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NEXT
Pat_6072:
	VOLENV 15, $11, $1F, $13
	ARP 0
	WAVE Wave_76DF
	LEN 24
	NOTE A_, 4
	LEN 12
	NOTE E_, 5
	NOTE F_, 5
	NOTE A_, 4
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 4
	LEN 24
	NOTE A_, 4
	LEN 12
	NOTE E_, 5
	NOTE F_, 5
	NOTE A_, 4
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 4
	NOTE A_, 4
	NOTE D_, 4
	LEN 24
	NOTE C_, 5
	LEN 12
	NOTE D_, 5
	LEN 6
	NOTE C_, 5
	NOTE B_, 4
	LEN 12
	NOTE A_, 4
	NOTE B_, 4
	NOTE F_, 4
	NOTE A_, 4
	LEN 24
	NOTE G_, 4
	LEN 36
	NOTE D_, 4
	LEN 12
	NOTE A_, 4
	NEXT
DrumPat_60A1:
	db DRUM_REPEAT + 3, 1, 0, 6, 6, 1, 0, 6
	db 6, 1, 0, 6, 6, 9, 0, 4
	db 0, DRUM_REPEAT_END, 1, 0, 6, 6, 1, 0
	db 6, 6, 1, 0, 6, 6, 9, 0
	db 9, 9, DRUM_LOOP
DrumPat_60C4:
	db DRUM_REPEAT + 3, 1, 0, 6, 6, 9, 0, 6
	db 6, 1, 0, 6, 6, 9, 0, 4
	db 0, DRUM_REPEAT_END, 1, 0, 6, 6, 9, 0
	db 6, 6, 1, 0, 6, 6, 9, 0
	db 9, 9, DRUM_LOOP

; Song 10: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong10:
	ld a, $70
	ld [wInstrTableHi], a
	ld a, $B4
	ld [wInstrTable], a
	call StopAll
	ld de, Song10_Ch2
	call StartMusicCh2
	ld de, Song10_Ch3
	jp StartMusicCh3
Song10_Ch2:
	dw Pat_623C
	dw Pat_611E
	dw Pat_6175
	dw Pat_619D
	dw Pat_61C3
	dw Pat_61EB
	ORDER_LOOP Song10_Ch2
Song10_Ch3:
	dw Pat_63C2
	dw Pat_6263
	dw Pat_62B1
	dw Pat_62E9
	dw Pat_6341
	ORDER_LOOP Song10_Ch3
Pat_611E:
	LEN 11
	REPEAT 5
	INSTR 11
	NOTE E_, 2
	INSTR 12
	NOTE E_, 3
	REPEAT_END
	INSTR 11
	NOTE Fsh, 2
	INSTR 12
	NOTE E_, 3
	INSTR 11
	NOTE G_, 2
	INSTR 12
	NOTE E_, 3
	INSTR 11
	NOTE A_, 2
	NOTE B_, 2
	REPEAT 3
	NOTE E_, 2
	INSTR 12
	NOTE E_, 3
	INSTR 11
	REPEAT_END
	NOTE E_, 2
	INSTR 12
	NOTE E_, 3
	INSTR 11
	NOTE E_, 2
	INSTR 12
	NOTE E_, 3
	INSTR 11
	NOTE Fsh, 2
	INSTR 12
	NOTE E_, 3
	INSTR 11
	NOTE G_, 2
	INSTR 12
	NOTE E_, 3
	INSTR 11
	NOTE A_, 2
	NOTE B_, 2
	REPEAT 3
	NOTE E_, 2
	INSTR 12
	NOTE E_, 3
	INSTR 11
	REPEAT_END
	NOTE E_, 2
	INSTR 12
	NOTE E_, 3
	INSTR 11
	NOTE E_, 2
	INSTR 12
	NOTE E_, 3
	INSTR 11
	NOTE Fsh, 2
	INSTR 12
	NOTE E_, 3
	INSTR 11
	NOTE G_, 2
	INSTR 12
	NOTE E_, 3
	INSTR 11
	NOTE A_, 2
	NOTE B_, 2
	NOTE E_, 2
	INSTR 12
	NOTE E_, 3
	REPEAT 4
	INSTR 11
	NOTE E_, 2
	INSTR 12
	NOTE E_, 3
	REPEAT_END
	INSTR 11
	NOTE Fsh, 2
	INSTR 12
	NOTE E_, 3
	INSTR 11
	NOTE G_, 2
	INSTR 12
	NOTE E_, 3
	INSTR 11
	NOTE A_, 2
	NOTE B_, 2
	NEXT
Pat_6175:
	REPEAT 8
	INSTR 11
	NOTE A_, 2
	INSTR 12
	NOTE A_, 3
	REPEAT_END
	REPEAT 4
	INSTR 11
	NOTE B_, 2
	INSTR 12
	NOTE B_, 3
	REPEAT_END
	INSTR 11
	NOTE B_, 2
	NOTE C_, 3
	NOTE B_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE Fsh, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE E_, 2
	INSTR 12
	NOTE E_, 3
	REPEAT 4
	INSTR 11
	NOTE E_, 2
	INSTR 12
	NOTE E_, 3
	REPEAT_END
	INSTR 11
	NOTE Fsh, 2
	NOTE G_, 2
	INSTR 12
	NOTE G_, 3
	INSTR 11
	NOTE A_, 2
	NOTE B_, 2
	NOTE D_, 3
	NEXT
Pat_619D:
	REPEAT 8
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE C_, 4
	REPEAT_END
	REPEAT 8
	INSTR 11
	NOTE A_, 2
	INSTR 12
	NOTE A_, 3
	REPEAT_END
	REPEAT 8
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE C_, 4
	REPEAT_END
	REPEAT 4
	INSTR 11
	NOTE B_, 2
	INSTR 12
	NOTE B_, 3
	REPEAT_END
	INSTR 11
	NOTE B_, 2
	NOTE C_, 3
	NOTE A_, 2
	LEN 22
	NOTE B_, 2
	INSTR 12
	LEN 11
	NOTE B_, 3
	INSTR 11
	NOTE B_, 2
	INSTR 12
	NOTE B_, 3
	NEXT
Pat_61C3:
	LEN 11
	REPEAT 8
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE C_, 4
	REPEAT_END
	REPEAT 8
	INSTR 11
	NOTE A_, 2
	INSTR 12
	NOTE A_, 3
	REPEAT_END
	REPEAT 8
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE C_, 4
	REPEAT_END
	REPEAT 4
	INSTR 11
	NOTE B_, 2
	INSTR 12
	NOTE B_, 3
	REPEAT_END
	REPEAT 2
	INSTR 11
	NOTE A_, 2
	INSTR 12
	NOTE A_, 3
	REPEAT_END
	INSTR 11
	NOTE Fsh, 2
	INSTR 12
	NOTE Fsh, 3
	INSTR 11
	NOTE Fsh, 2
	INSTR 12
	NOTE Fsh, 3
	NEXT
Pat_61EB:
	REPEAT 2
	INSTR 11
	LEN 11
	NOTE E_, 2
	INSTR 12
	NOTE E_, 3
	NOTE D_, 4
	NOTE E_, 4
	INSTR 11
	NOTE E_, 2
	INSTR 12
	NOTE E_, 4
	NOTE D_, 4
	INSTR 11
	NOTE D_, 2
	NOTE E_, 2
	INSTR 12
	NOTE E_, 4
	LEN 22
	NOTE D_, 4
	INSTR 11
	LEN 11
	NOTE E_, 2
	INSTR 12
	NOTE E_, 4
	LEN 22
	NOTE D_, 4
	REPEAT_END
	INSTR 11
	LEN 11
	NOTE C_, 2
	INSTR 12
	NOTE E_, 3
	NOTE G_, 3
	NOTE E_, 4
	INSTR 11
	NOTE C_, 2
	INSTR 12
	NOTE E_, 4
	NOTE D_, 4
	INSTR 11
	NOTE G_, 2
	NOTE C_, 2
	INSTR 12
	NOTE E_, 4
	LEN 22
	NOTE D_, 4
	INSTR 11
	LEN 11
	NOTE C_, 2
	INSTR 12
	NOTE E_, 4
	LEN 22
	NOTE D_, 4
	INSTR 11
	LEN 11
	NOTE A_, 2
	INSTR 12
	NOTE E_, 3
	INSTR 11
	NOTE G_, 2
	NOTE A_, 2
	INSTR 12
	NOTE A_, 3
	NOTE E_, 4
	NOTE D_, 4
	INSTR 11
	NOTE A_, 2
	NOTE B_, 2
	INSTR 12
	NOTE E_, 4
	NOTE D_, 4
	INSTR 11
	NOTE D_, 3
	NOTE B_, 2
	INSTR 12
	NOTE E_, 4
	INSTR 11
	NOTE D_, 3
	NOTE B_, 2
	NEXT
Pat_623C:
	LEN 11
	REPEAT 5
	INSTR 11
	NOTE E_, 2
	INSTR 12
	NOTE E_, 3
	REPEAT_END
	INSTR 11
	NOTE Fsh, 2
	INSTR 12
	NOTE E_, 3
	INSTR 11
	NOTE G_, 2
	INSTR 12
	NOTE E_, 3
	INSTR 11
	NOTE A_, 2
	NOTE B_, 2
	NOTE E_, 2
	INSTR 12
	NOTE E_, 3
	REPEAT 4
	INSTR 11
	NOTE E_, 2
	INSTR 12
	NOTE E_, 3
	REPEAT_END
	INSTR 11
	NOTE Fsh, 2
	INSTR 12
	NOTE E_, 3
	INSTR 11
	NOTE G_, 2
	INSTR 12
	NOTE E_, 3
	INSTR 11
	NOTE A_, 2
	NOTE B_, 2
	NEXT
Pat_6263:
	ARP 5
	LEN 11
	NOTE E_, 4
	ARP 0
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	LEN 22
	NOTE Fsh, 4
	LEN 11
	NOTE D_, 4
	LEN 22
	NOTE B_, 3
	LEN 11
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	LEN 22
	NOTE Fsh, 4
	LEN 11
	NOTE A_, 4
	LEN 22
	NOTE B_, 4
	LEN 11
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE E_, 4
	NOTE B_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE B_, 3
	ARP 5
	NOTE E_, 4
	ARP 0
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	LEN 22
	NOTE Fsh, 4
	LEN 11
	NOTE D_, 4
	LEN 22
	NOTE B_, 3
	LEN 11
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	LEN 22
	NOTE Fsh, 4
	LEN 11
	NOTE A_, 4
	LEN 22
	NOTE B_, 4
	LEN 11
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE A_, 3
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE B_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE E_, 4
	NOTE G_, 4
	NOTE B_, 4
	NEXT
Pat_62B1:
	ARP 5
	LEN 11
	NOTE A_, 4
	ARP 0
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	LEN 22
	NOTE B_, 4
	LEN 11
	NOTE G_, 4
	LEN 22
	NOTE E_, 4
	LEN 11
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE B_, 4
	LEN 22
	NOTE G_, 4
	LEN 11
	NOTE A_, 4
	ARP 4
	NOTE B_, 4
	ARP 0
	NOTE B_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	ARP 5
	LEN 33
	NOTE E_, 4
	ARP 4
	NOTE D_, 4
	ARP 5
	NOTE E_, 4
	LEN 22
	NOTE E_, 4
	LEN 11
	NOTE E_, 4
	LEN 22
	NOTE E_, 4
	ARP 4
	NOTE G_, 4
	NEXT
Pat_62E9:
	WAVE Wave_786F
	RELEASE $01, $02
	VOLENV 15, $11, $1F, $16
	ARP_OFF
	LEN 11
	NOTE C_, 4
	WAIT2
	NOTE G_, 4
	ARP 3
	NOTE G_, 4
	WAIT2
	ARP_OFF
	LEN 33
	NOTE G_, 4
	LEN 11
	NOTE C_, 4
	WAIT2
	NOTE G_, 4
	ARP 3
	NOTE G_, 4
	WAIT2
	ARP_OFF
	NOTE G_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE B_, 3
	NOTE E_, 4
	NOTE C_, 4
	NOTE A_, 4
	NOTE E_, 4
	ARP 3
	LEN 22
	NOTE Ash, 4
	ARP_OFF
	LEN 11
	NOTE B_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	WAIT2
	NOTE G_, 4
	ARP 3
	NOTE G_, 4
	WAIT2
	ARP_OFF
	NOTE G_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	ARP 3
	NOTE G_, 4
	WAIT2
	ARP_OFF
	NOTE G_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE B_, 3
	WAIT2
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NEXT
Pat_6341:
	ARP_OFF
	LEN 11
	NOTE C_, 4
	WAIT2
	NOTE G_, 4
	ARP 3
	NOTE G_, 4
	WAIT2
	ARP_OFF
	LEN 33
	NOTE G_, 4
	LEN 11
	NOTE C_, 4
	WAIT2
	NOTE G_, 4
	ARP 3
	NOTE G_, 4
	WAIT2
	ARP_OFF
	NOTE G_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE B_, 3
	NOTE E_, 4
	NOTE C_, 4
	NOTE A_, 4
	NOTE E_, 4
	ARP 3
	LEN 22
	NOTE Ash, 4
	ARP_OFF
	LEN 11
	NOTE B_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	WAIT2
	NOTE G_, 4
	ARP 3
	NOTE G_, 4
	WAIT2
	ARP_OFF
	NOTE G_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	ARP 3
	NOTE G_, 4
	WAIT2
	ARP_OFF
	NOTE G_, 4
	NOTE E_, 4
	NOTE G_, 4
	LEN 22
	NOTE Fsh, 4
	NOTE Dsh, 4
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE B_, 4
	NOTE A_, 4
	ARP 3
	NOTE Ash, 4
	ARP_OFF
	LENGTH $79
	NOTE B_, 4
	ARP_OFF
	LEN 11
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	WAIT2
	NOTE E_, 4
	NOTE D_, 4
	WAIT2
	NOTE D_, 4
	NOTE E_, 4
	WAIT2
	LENGTH $37
	NOTE E_, 4
	LEN 11
	WAIT2
	NOTE B_, 3
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	LEN 22
	NOTE E_, 4
	LENGTH $58
	WAIT2
	LEN 11
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	WAIT2
	NOTE E_, 4
	NOTE D_, 4
	WAIT2
	LEN 22
	NOTE D_, 4
	LEN 11
	NOTE E_, 4
	NOTE B_, 3
	WAIT2
	NOTE D_, 4
	NOTE E_, 4
	LEN 22
	NOTE A_, 3
	LEN 11
	NOTE D_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE B_, 4
	WAIT2
	NOTE Fsh, 4
	NEXT
Pat_63C2:
	DRUMS $0B, DrumPat_63F7
	WAVE Wave_770F
	VOLENV 14, $00, $1F, $14
	VIBRATO $10, $01, $05
	RELEASE $00
	CH_TRANSPOSE $0C
	ARP 5
	LEN 22
	NOTE E_, 4
	ARP 0
	LEN 11
	NOTE B_, 3
	LEN 22
	NOTE E_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	LEN 11
	NOTE E_, 4
	LEN 22
	NOTE B_, 3
	ARP 4
	NOTE D_, 4
	NOTE D_, 4
	ARP 5
	NOTE E_, 4
	ARP 0
	LEN 11
	NOTE E_, 4
	LEN 22
	NOTE G_, 4
	NOTE B_, 4
	NOTE A_, 4
	LEN 11
	NOTE Fsh, 4
	LEN 22
	NOTE G_, 4
	ARP 4
	NOTE G_, 4
	NOTE G_, 4
	NEXT
DrumPat_63F7:
	db 1, 6, 2, 6, DRUM_LOOP

; Song 11: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong11:
	ld a, $70
	ld [wInstrTableHi], a
	ld a, $B4
	ld [wInstrTable], a
	call StopAll
	ld de, Song11_Ch1
	call StartMusicCh1
	ld de, Song11_Ch2
	call StartMusicCh2
	ld de, Song11_Ch3
	jp StartMusicCh3
Song11_Ch1:
	dw Pat_644B
	dw Pat_6475
	dw Pat_649F
	dw Pat_64C8
	dw Pat_64F4
	dw Pat_64F4
	ORDER_LOOP Song11_Ch1
Song11_Ch2:
	dw Pat_656E
	dw Pat_658E
	dw Pat_65AD
	dw Pat_6602
	dw Pat_666F
	dw Pat_666F
	ORDER_LOOP Song11_Ch2
Song11_Ch3:
	dw Pat_66DB
	dw Pat_670A
	dw Pat_672D
	dw Pat_674E
	dw Pat_6778
	dw Pat_6778
	ORDER_LOOP Song11_Ch3
Pat_644B:
	INSTR 11
	LEN 30
	NOTE E_, 2
	NOTE B_, 2
	LEN 20
	NOTE E_, 2
	LEN 30
	NOTE A_, 2
	NOTE E_, 3
	LEN 20
	NOTE A_, 2
	LEN 30
	NOTE E_, 2
	NOTE B_, 2
	LEN 20
	NOTE D_, 2
	LEN 30
	NOTE E_, 2
	NOTE B_, 2
	LEN 20
	NOTE E_, 2
	LEN 30
	NOTE C_, 2
	NOTE G_, 2
	LEN 20
	NOTE C_, 2
	LEN 30
	NOTE D_, 2
	NOTE A_, 2
	LEN 20
	NOTE D_, 2
	LEN 30
	NOTE E_, 2
	NOTE G_, 2
	LEN 20
	NOTE E_, 2
	LEN 30
	NOTE D_, 2
	NOTE Fsh, 2
	LEN 20
	NOTE D_, 2
	NEXT
Pat_6475:
	INSTR 11
	LEN 30
	NOTE E_, 2
	NOTE B_, 2
	LEN 20
	NOTE E_, 2
	LEN 30
	NOTE A_, 2
	NOTE E_, 3
	LEN 20
	NOTE A_, 2
	LEN 30
	NOTE E_, 2
	NOTE B_, 2
	LEN 20
	NOTE D_, 2
	LEN 30
	NOTE E_, 2
	NOTE B_, 2
	LEN 20
	NOTE E_, 2
	LEN 30
	NOTE C_, 2
	NOTE G_, 2
	LEN 20
	NOTE C_, 2
	LEN 30
	NOTE D_, 2
	NOTE A_, 2
	LEN 20
	NOTE D_, 2
	LEN 30
	NOTE G_, 2
	NOTE D_, 3
	LEN 20
	NOTE G_, 2
	LEN 30
	NOTE B_, 2
	NOTE Fsh, 2
	LEN 20
	NOTE B_, 2
	NEXT
Pat_649F:
	INSTR 11
	LEN 30
	NOTE A_, 2
	NOTE E_, 2
	LEN 20
	NOTE G_, 2
	LEN 30
	NOTE A_, 2
	NOTE E_, 2
	LEN 20
	NOTE G_, 2
	LEN 30
	NOTE A_, 2
	NOTE E_, 2
	LEN 20
	NOTE G_, 2
	LEN 30
	NOTE A_, 2
	NOTE G_, 2
	LEN 20
	NOTE D_, 2
	LEN 30
	NOTE E_, 2
	NOTE B_, 2
	LEN 20
	NOTE G_, 2
	LEN 30
	NOTE E_, 2
	NOTE B_, 2
	LEN 20
	NOTE G_, 2
	LEN 30
	NOTE E_, 2
	NOTE B_, 2
	LEN 20
	NOTE G_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE Fsh, 2
	NOTE G_, 2
	NEXT
Pat_64C8:
	INSTR 11
	LEN 30
	NOTE Fsh, 2
	NOTE Csh, 3
	LEN 20
	NOTE Ash, 2
	LEN 30
	NOTE Fsh, 2
	NOTE Csh, 3
	LEN 20
	NOTE Ash, 2
	LEN 30
	NOTE Fsh, 2
	NOTE Csh, 3
	LEN 20
	NOTE Ash, 2
	NOTE Fsh, 2
	NOTE Csh, 3
	NOTE B_, 2
	NOTE Ash, 2
	LEN 30
	NOTE B_, 2
	NOTE C_, 3
	LEN 20
	NOTE A_, 2
	LEN 30
	NOTE B_, 2
	NOTE C_, 3
	LEN 20
	NOTE A_, 2
	NOTE B_, 2
	LEN 10
	NOTE C_, 3
	LEN 20
	NOTE B_, 2
	LEN 10
	NOTE C_, 3
	LEN 40
	NOTE B_, 2
	LEN 20
	NOTE A_, 2
	NOTE G_, 2
	NOTE Fsh, 2
	NEXT
Pat_64F4:
	INSTR 11
	LEN 30
	NOTE E_, 2
	NOTE B_, 2
	LEN 20
	NOTE E_, 2
	LEN 30
	NOTE A_, 2
	NOTE E_, 3
	LEN 20
	NOTE A_, 2
	LEN 30
	NOTE D_, 2
	NOTE A_, 2
	LEN 20
	NOTE D_, 2
	LEN 30
	NOTE G_, 2
	NOTE D_, 3
	LEN 20
	NOTE G_, 2
	LEN 30
	NOTE C_, 2
	NOTE G_, 2
	LEN 20
	NOTE C_, 2
	LEN 30
	NOTE A_, 2
	NOTE E_, 2
	LEN 20
	NOTE A_, 2
	LEN 30
	NOTE B_, 2
	NOTE Fsh, 2
	LEN 20
	NOTE A_, 2
	LEN 30
	NOTE B_, 2
	NOTE Fsh, 2
	LEN 20
	NOTE B_, 2
	NEXT
Pat_651E:
	INSTR 9
	LEN 20
	NOTE E_, 3
	INSTR 5
	LEN 10
	NOTE E_, 4
	INSTR 9
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE E_, 3
	INSTR 5
	LEN 20
	NOTE E_, 4
	INSTR 9
	NOTE A_, 3
	INSTR 5
	LEN 10
	NOTE A_, 4
	INSTR 9
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE A_, 3
	INSTR 5
	LEN 20
	NOTE A_, 4
	INSTR 9
	NOTE E_, 3
	INSTR 5
	LEN 10
	NOTE E_, 4
	INSTR 9
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE E_, 3
	INSTR 5
	LEN 20
	NOTE E_, 4
	INSTR 9
	NOTE B_, 3
	INSTR 5
	LEN 10
	NOTE E_, 4
	INSTR 9
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE E_, 3
	INSTR 5
	LEN 20
	NOTE E_, 4
	INSTR 9
	NOTE C_, 3
	INSTR 4
	LEN 10
	NOTE C_, 4
	INSTR 9
	LEN 20
	NOTE E_, 3
	LEN 10
	NOTE C_, 3
	INSTR 4
	LEN 20
	NOTE C_, 4
	INSTR 9
	NOTE D_, 3
	INSTR 4
	LEN 10
	NOTE D_, 4
	INSTR 9
	LEN 20
	NOTE Fsh, 3
	LEN 10
	NOTE D_, 3
	INSTR 4
	LEN 20
	NOTE D_, 4
	NEXT
Pat_656E:
	PAT_CALL Pat_651E
	INSTR 9
	NOTE E_, 3
	INSTR 5
	LEN 10
	NOTE E_, 4
	INSTR 9
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE E_, 3
	INSTR 5
	NOTE E_, 4
	INSTR 9
	NOTE G_, 3
	LEN 20
	NOTE D_, 3
	INSTR 4
	LEN 10
	NOTE D_, 4
	INSTR 9
	LEN 20
	NOTE Fsh, 3
	LEN 10
	NOTE A_, 3
	INSTR 4
	NOTE D_, 4
	INSTR 9
	NOTE D_, 4
	NEXT
Pat_658E:
	PAT_CALL Pat_651E
	INSTR 9
	NOTE G_, 3
	INSTR 4
	LEN 10
	NOTE G_, 4
	INSTR 9
	LEN 20
	NOTE B_, 3
	LEN 10
	NOTE G_, 3
	INSTR 4
	LEN 20
	NOTE G_, 4
	INSTR 9
	NOTE B_, 3
	INSTR 4
	LEN 10
	NOTE B_, 4
	INSTR 9
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE B_, 3
	INSTR 4
	NOTE B_, 4
	INSTR 9
	NOTE Fsh, 3
	NEXT
Pat_65AD:
	INSTR 9
	LEN 20
	NOTE A_, 3
	INSTR 5
	LEN 10
	NOTE A_, 4
	INSTR 9
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE A_, 3
	INSTR 5
	LEN 20
	NOTE A_, 4
	INSTR 9
	NOTE A_, 3
	INSTR 5
	LEN 10
	NOTE A_, 4
	INSTR 9
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE A_, 3
	INSTR 5
	NOTE A_, 4
	INSTR 9
	NOTE G_, 3
	LEN 20
	NOTE A_, 3
	INSTR 5
	LEN 10
	NOTE A_, 4
	INSTR 9
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE A_, 3
	INSTR 5
	LEN 20
	NOTE A_, 4
	INSTR 9
	NOTE A_, 3
	INSTR 5
	LEN 10
	NOTE A_, 4
	INSTR 9
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE A_, 3
	INSTR 5
	NOTE A_, 4
	INSTR 9
	NOTE G_, 3
	REPEAT 2
	LEN 20
	NOTE E_, 3
	INSTR 5
	LEN 10
	NOTE E_, 4
	INSTR 9
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE E_, 3
	INSTR 5
	LEN 20
	NOTE E_, 4
	INSTR 9
	NOTE E_, 3
	INSTR 5
	LEN 10
	NOTE E_, 4
	INSTR 9
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE E_, 3
	INSTR 5
	NOTE E_, 4
	INSTR 9
	NOTE D_, 3
	REPEAT_END
	NEXT
Pat_6602:
	INSTR 9
	LEN 20
	NOTE Fsh, 3
	INSTR 4
	LEN 10
	NOTE Fsh, 4
	INSTR 9
	LEN 20
	NOTE Ash, 3
	LEN 10
	NOTE Fsh, 3
	INSTR 4
	LEN 20
	NOTE Fsh, 4
	INSTR 9
	NOTE Fsh, 3
	INSTR 4
	LEN 10
	NOTE Fsh, 4
	INSTR 9
	LEN 20
	NOTE Ash, 3
	LEN 10
	NOTE Fsh, 3
	INSTR 4
	NOTE Fsh, 4
	INSTR 9
	NOTE E_, 3
	LEN 20
	NOTE Fsh, 3
	INSTR 4
	LEN 10
	NOTE Fsh, 4
	INSTR 9
	LEN 20
	NOTE Ash, 3
	LEN 10
	NOTE Fsh, 3
	INSTR 4
	LEN 20
	NOTE Fsh, 4
	INSTR 9
	NOTE Csh, 4
	INSTR 4
	LEN 10
	NOTE Fsh, 4
	INSTR 9
	LEN 20
	NOTE Fsh, 4
	LEN 10
	NOTE Csh, 4
	INSTR 4
	LEN 20
	NOTE Fsh, 4
	INSTR 9
	NOTE B_, 3
	INSTR 4
	LEN 10
	NOTE B_, 4
	INSTR 9
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE B_, 3
	INSTR 4
	LEN 20
	NOTE B_, 4
	INSTR 9
	NOTE B_, 3
	INSTR 4
	LEN 10
	NOTE B_, 4
	INSTR 9
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE B_, 3
	INSTR 4
	NOTE B_, 4
	INSTR 9
	NOTE A_, 3
	LEN 20
	NOTE B_, 3
	INSTR 4
	LEN 10
	NOTE B_, 4
	INSTR 9
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE B_, 3
	INSTR 4
	NOTE B_, 4
	INSTR 9
	NOTE A_, 3
	LEN 20
	NOTE B_, 3
	INSTR 4
	LEN 10
	NOTE B_, 4
	INSTR 9
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	INSTR 4
	NOTE B_, 4
	INSTR 9
	NOTE B_, 3
	NEXT
Pat_666F:
	INSTR 9
	LEN 20
	NOTE E_, 3
	INSTR 5
	LEN 10
	NOTE E_, 4
	INSTR 9
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE E_, 3
	INSTR 5
	LEN 20
	NOTE E_, 4
	INSTR 9
	NOTE A_, 3
	INSTR 5
	LEN 10
	NOTE A_, 4
	INSTR 9
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE A_, 3
	INSTR 5
	LEN 20
	NOTE A_, 4
	INSTR 9
	NOTE D_, 3
	INSTR 4
	LEN 10
	NOTE D_, 4
	INSTR 9
	LEN 20
	NOTE Fsh, 3
	LEN 10
	NOTE D_, 3
	INSTR 4
	LEN 20
	NOTE D_, 4
	INSTR 9
	NOTE G_, 3
	INSTR 4
	LEN 10
	NOTE G_, 4
	INSTR 9
	LEN 20
	NOTE B_, 3
	LEN 10
	NOTE G_, 3
	INSTR 4
	LEN 20
	NOTE G_, 4
	INSTR 9
	NOTE C_, 3
	INSTR 4
	LEN 10
	NOTE C_, 4
	INSTR 9
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE C_, 3
	INSTR 4
	LEN 20
	NOTE C_, 4
	INSTR 9
	NOTE A_, 3
	INSTR 5
	LEN 10
	NOTE A_, 3
	INSTR 9
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE E_, 4
	INSTR 5
	LEN 20
	NOTE A_, 3
	INSTR 9
	NOTE B_, 3
	INSTR 4
	LEN 10
	NOTE B_, 3
	INSTR 9
	LEN 20
	NOTE Dsh, 4
	LEN 10
	NOTE Fsh, 4
	INSTR 4
	NOTE B_, 3
	INSTR 9
	NOTE A_, 4
	LEN 20
	NOTE B_, 4
	INSTR 4
	LEN 10
	NOTE B_, 3
	INSTR 9
	LEN 20
	NOTE Fsh, 4
	LEN 10
	NOTE Dsh, 4
	INSTR 4
	NOTE B_, 3
	INSTR 9
	NOTE C_, 4
	NEXT
Pat_66DB:
	DRUMS $0A, DrumPat_67B1
	WAVE Wave_771F
	VIBRATO $14, $01, $04
	CH_TRANSPOSE $0C
	INSTR 13
	LEN 40
	NOTE E_, 4
	NOTE B_, 4
	LENGTH $3C
	NOTE A_, 4
	LEN 10
	NOTE G_, 4
	NOTE Fsh, 4
	LEN 30
	NOTE G_, 4
	LEN 10
	NOTE A_, 4
	LEN 20
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE B_, 3
	LEN 40
	NOTE C_, 4
	NOTE E_, 4
	LEN 20
	NOTE D_, 4
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	LENGTH $50
	NOTE B_, 3
	NOTE A_, 3
	NEXT
Pat_670A:
	LEN 40
	NOTE E_, 4
	LEN 30
	NOTE B_, 4
	LEN 10
	NOTE C_, 5
	LENGTH $3C
	NOTE A_, 4
	LEN 10
	NOTE G_, 4
	NOTE Fsh, 4
	LEN 30
	NOTE G_, 4
	LEN 10
	NOTE A_, 4
	LEN 20
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE B_, 4
	LEN 40
	NOTE C_, 5
	LEN 20
	NOTE B_, 4
	NOTE A_, 4
	LEN 40
	NOTE G_, 4
	NOTE A_, 4
	LENGTH $A0
	NOTE B_, 4
	NEXT
Pat_672D:
	LEN 20
	WAIT
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	LEN 30
	NOTE B_, 4
	NOTE A_, 4
	LENGTH $64
	NOTE E_, 4
	LEN 30
	NOTE A_, 2
	NOTE G_, 2
	LEN 20
	NOTE D_, 2
	NOTE E_, 2
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	LEN 30
	NOTE Fsh, 4
	NOTE E_, 4
	LEN 40
	NOTE B_, 4
	LENGTH $50
	NOTE E_, 4
	LEN 20
	NOTE E_, 2
	NOTE Fsh, 2
	NOTE G_, 2
	NEXT
Pat_674E:
	LEN 20
	NOTE Fsh, 2
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	LEN 30
	NOTE B_, 4
	NOTE Csh, 5
	LEN 10
	NOTE C_, 5
	NOTE B_, 4
	LENGTH $64
	NOTE Ash, 4
	LEN 20
	INSTR 6
	NOTE Csh, 4
	NOTE B_, 3
	NOTE Ash, 3
	LEN 30
	NOTE B_, 3
	NOTE C_, 4
	LEN 40
	NOTE B_, 3
	LEN 20
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE B_, 3
	LEN 10
	NOTE C_, 4
	LEN 20
	NOTE B_, 3
	LEN 10
	NOTE C_, 4
	LEN 40
	NOTE B_, 3
	LEN 20
	NOTE A_, 3
	NOTE G_, 3
	NOTE Fsh, 3
	NEXT
Pat_6778:
	LEN 30
	NOTE E_, 4
	NOTE Fsh, 4
	LEN 20
	NOTE G_, 4
	NOTE B_, 4
	LEN 10
	NOTE A_, 4
	LEN 20
	NOTE G_, 4
	NOTE A_, 4
	LEN 30
	NOTE Fsh, 4
	LEN 10
	NOTE C_, 5
	LEN 20
	NOTE B_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	LEN 10
	NOTE G_, 4
	NOTE Fsh, 4
	LEN 20
	NOTE G_, 4
	NOTE Fsh, 4
	LEN 30
	NOTE E_, 4
	LEN 10
	NOTE C_, 4
	LEN 20
	NOTE E_, 4
	LEN 10
	NOTE Fsh, 4
	LEN 20
	NOTE G_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	LEN 10
	NOTE B_, 3
	LEN 20
	NOTE Fsh, 4
	LEN 10
	NOTE G_, 4
	NOTE A_, 4
	LEN 20
	NOTE B_, 4
	LEN 10
	NOTE C_, 5
	NOTE A_, 4
	LEN 20
	NOTE C_, 5
	LEN 30
	NOTE B_, 4
	NEXT
DrumPat_67B1:
	db DRUM_LEVEL + 13, DRUM_REPEAT + 3, 1, 6, 9, 9, 1, 6
	db 9, 6, 1, 6, 9, 1, 1, 6
	db 9, 6, DRUM_REPEAT_END, 1, 6, 9, 1, 1
	db 6, 9, 6, 1, 6, 9, 9, 1
	db 9, 9, 9, DRUM_LOOP

; Song 12: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong12:
	ld a, $70
	ld [wInstrTableHi], a
	ld a, $B4
	ld [wInstrTable], a
	call StopAll
	ld de, Song12_Ch1
	call StartMusicCh1
	ld de, Song12_Ch2
	call StartMusicCh2
	ld de, Song12_Ch3
	jp StartMusicCh3
Song12_Ch1:
	dw Pat_6824
	dw Pat_6862
	dw Pat_689C
	dw Pat_68D6
	dw Pat_6910
	dw Pat_6824
	ORDER_LOOP Song12_Ch1
Song12_Ch2:
	dw Pat_6949
	dw Pat_6988
	dw Pat_69C1
	dw Pat_69FA
	dw Pat_6A33
	dw Pat_6949
	ORDER_LOOP Song12_Ch2
Song12_Ch3:
	dw Pat_6A70
	dw Pat_6ABC
	dw Pat_6AE3
	dw Pat_6B08
	dw Pat_6B27
	dw Pat_6A70
	ORDER_LOOP Song12_Ch3
Pat_6824:
	VIBRATO $10, $02, $05
	INSTR 15
	LEN 32
	NOTE A_, 2
	INSTR 5
	LEN 16
	NOTE A_, 4
	INSTR 15
	LEN 32
	NOTE G_, 2
	INSTR 4
	LEN 16
	NOTE G_, 4
	INSTR 15
	NOTE E_, 2
	NOTE G_, 2
	LEN 32
	NOTE A_, 2
	INSTR 5
	LEN 16
	NOTE A_, 4
	INSTR 15
	LEN 32
	NOTE G_, 2
	INSTR 4
	LEN 16
	NOTE G_, 4
	INSTR 15
	NOTE E_, 2
	NOTE G_, 2
	LEN 32
	NOTE A_, 2
	INSTR 5
	LEN 16
	NOTE A_, 4
	INSTR 15
	LEN 32
	NOTE G_, 2
	INSTR 4
	LEN 16
	NOTE G_, 4
	INSTR 15
	NOTE E_, 2
	NOTE G_, 2
	LEN 32
	NOTE A_, 2
	INSTR 5
	LEN 16
	NOTE A_, 4
	INSTR 15
	LEN 32
	NOTE G_, 2
	INSTR 4
	LEN 16
	NOTE G_, 4
	INSTR 15
	NOTE E_, 2
	NOTE G_, 2
	NEXT
Pat_6862:
	INSTR 15
	LEN 32
	NOTE A_, 2
	INSTR 5
	LEN 16
	NOTE A_, 4
	INSTR 15
	LEN 32
	NOTE G_, 2
	INSTR 4
	LEN 16
	NOTE G_, 4
	INSTR 15
	NOTE E_, 2
	NOTE G_, 2
	LEN 32
	NOTE A_, 2
	INSTR 5
	LEN 16
	NOTE A_, 4
	INSTR 15
	LEN 32
	NOTE G_, 2
	INSTR 4
	LEN 16
	NOTE G_, 4
	INSTR 15
	NOTE E_, 2
	NOTE G_, 2
	LEN 32
	NOTE A_, 2
	INSTR 5
	LEN 16
	NOTE A_, 4
	INSTR 15
	LEN 32
	NOTE G_, 2
	INSTR 4
	LEN 16
	NOTE G_, 4
	INSTR 15
	NOTE E_, 2
	NOTE G_, 2
	LEN 32
	NOTE A_, 2
	INSTR 5
	LEN 16
	NOTE A_, 4
	INSTR 15
	LEN 32
	NOTE G_, 2
	INSTR 4
	LEN 16
	NOTE G_, 4
	INSTR 15
	NOTE E_, 2
	NOTE G_, 2
	NEXT
Pat_689C:
	INSTR 15
	LEN 32
	NOTE A_, 2
	INSTR 5
	LEN 16
	NOTE A_, 4
	INSTR 15
	LEN 32
	NOTE G_, 2
	INSTR 4
	LEN 16
	NOTE G_, 4
	INSTR 15
	NOTE E_, 2
	NOTE G_, 2
	LEN 32
	NOTE A_, 2
	INSTR 5
	LEN 16
	NOTE A_, 4
	INSTR 15
	LEN 32
	NOTE G_, 2
	INSTR 4
	LEN 16
	NOTE G_, 4
	INSTR 15
	NOTE E_, 2
	NOTE G_, 2
	LEN 32
	NOTE A_, 2
	INSTR 5
	LEN 16
	NOTE A_, 4
	INSTR 15
	LEN 32
	NOTE G_, 2
	INSTR 4
	LEN 16
	NOTE G_, 4
	INSTR 15
	NOTE E_, 2
	NOTE G_, 2
	LEN 32
	NOTE A_, 2
	INSTR 5
	LEN 16
	NOTE A_, 4
	INSTR 15
	LEN 32
	NOTE A_, 2
	INSTR 5
	LEN 16
	NOTE A_, 4
	INSTR 15
	NOTE G_, 2
	NOTE E_, 2
	NEXT
Pat_68D6:
	INSTR 15
	LEN 32
	NOTE F_, 2
	INSTR 4
	LEN 16
	NOTE F_, 4
	INSTR 15
	LEN 32
	NOTE C_, 3
	INSTR 4
	LEN 16
	NOTE F_, 4
	INSTR 15
	NOTE A_, 2
	NOTE E_, 2
	LEN 32
	NOTE F_, 2
	INSTR 4
	LEN 16
	NOTE F_, 4
	INSTR 15
	LEN 32
	NOTE C_, 3
	INSTR 4
	LEN 16
	NOTE F_, 4
	INSTR 15
	NOTE A_, 2
	NOTE F_, 2
	LEN 32
	NOTE E_, 2
	INSTR 5
	LEN 16
	NOTE E_, 4
	INSTR 15
	LEN 32
	NOTE B_, 2
	INSTR 5
	LEN 16
	NOTE E_, 4
	INSTR 15
	NOTE G_, 2
	NOTE D_, 2
	LEN 32
	NOTE E_, 2
	INSTR 5
	LEN 16
	NOTE E_, 4
	INSTR 15
	LEN 32
	NOTE B_, 2
	INSTR 5
	LEN 16
	NOTE E_, 4
	INSTR 15
	NOTE G_, 2
	NOTE E_, 2
	NEXT
Pat_6910:
	INSTR 15
	LEN 32
	NOTE F_, 2
	INSTR 4
	LEN 16
	NOTE F_, 4
	INSTR 15
	LEN 32
	NOTE C_, 3
	INSTR 4
	LEN 16
	NOTE F_, 4
	INSTR 15
	NOTE A_, 2
	NOTE E_, 2
	LEN 32
	NOTE F_, 2
	INSTR 4
	LEN 16
	NOTE F_, 4
	INSTR 15
	LEN 32
	NOTE C_, 3
	LEN 16
	NOTE A_, 2
	NOTE F_, 2
	NOTE A_, 2
	LEN 32
	NOTE G_, 2
	INSTR 4
	LEN 16
	NOTE G_, 4
	INSTR 15
	LEN 32
	NOTE D_, 3
	INSTR 4
	LEN 16
	NOTE G_, 4
	INSTR 15
	NOTE B_, 2
	NOTE G_, 2
	LEN 32
	NOTE Gsh, 2
	INSTR 4
	LEN 16
	NOTE E_, 4
	INSTR 15
	LEN 32
	NOTE B_, 2
	INSTR 4
	LEN 16
	NOTE E_, 4
	INSTR 15
	NOTE E_, 3
	INSTR 4
	NOTE E_, 4
	NEXT
Pat_6949:
	HWENV $C1, $04, $56
	DUTY_75
	ARP 8
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE A_, 3
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 16
	NOTE A_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 32
	NOTE E_, 3
	LEN 8
	NOTE A_, 3
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 16
	NOTE C_, 4
	NOTE B_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE A_, 3
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 16
	NOTE A_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 32
	NOTE E_, 3
	LEN 8
	NOTE A_, 3
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 16
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NEXT
Pat_6988:
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE A_, 3
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 16
	NOTE A_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 32
	NOTE E_, 3
	LEN 8
	NOTE A_, 3
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 16
	NOTE C_, 4
	NOTE B_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE A_, 3
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 16
	NOTE A_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 32
	NOTE E_, 3
	LEN 8
	NOTE A_, 3
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 16
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NEXT
Pat_69C1:
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE A_, 3
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 16
	NOTE A_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 32
	NOTE E_, 3
	LEN 8
	NOTE A_, 3
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 16
	NOTE C_, 4
	NOTE B_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE A_, 3
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 16
	NOTE A_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 32
	NOTE E_, 3
	LEN 8
	NOTE A_, 3
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 16
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NEXT
Pat_69FA:
	LEN 8
	NOTE E_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE C_, 4
	LEN 16
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	LEN 8
	NOTE E_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE C_, 4
	LEN 16
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE E_, 4
	LEN 8
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 3
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 3
	NOTE D_, 4
	NOTE B_, 3
	LEN 16
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 3
	LEN 8
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 3
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 3
	NOTE D_, 4
	NOTE B_, 3
	LEN 16
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 3
	NEXT
Pat_6A33:
	LEN 8
	NOTE E_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE C_, 4
	LEN 16
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	LEN 8
	NOTE E_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE C_, 4
	LEN 16
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE E_, 4
	LEN 8
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 4
	NOTE D_, 4
	LEN 16
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	LEN 8
	NOTE Gsh, 4
	NOTE E_, 4
	NOTE B_, 3
	NOTE Gsh, 4
	NOTE E_, 4
	NOTE B_, 3
	NOTE Gsh, 4
	NOTE E_, 4
	LEN 16
	NOTE B_, 3
	LEN 8
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NEXT
Pat_6A70:
	DRUMS $08, DrumPat_6B41
	WAVE Wave_770F
	VOLENV 12, $11, $1F, $12
	VIBRATO $14, $01, $04
	CH_TRANSPOSE $0C
	ARP 8
	ARP 0
	LEN 16
	NOTE E_, 4
	LEN 8
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	LEN 8
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN 32
	NOTE B_, 3
	LEN 8
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	LEN 8
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	LEN 16
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE E_, 4
	LEN 8
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN 32
	NOTE B_, 3
	LEN 8
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	LEN 8
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	LEN 16
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NEXT
Pat_6ABC:
	INSTR 13
	ARP 0
	LEN 24
	NOTE A_, 3
	NOTE C_, 4
	LEN 16
	NOTE E_, 4
	LEN 32
	NOTE D_, 4
	LEN 16
	NOTE G_, 4
	NOTE D_, 4
	LENGTH $30
	NOTE E_, 4
	LEN 16
	NOTE C_, 4
	LEN 32
	NOTE D_, 4
	NOTE B_, 3
	LEN 24
	NOTE A_, 3
	NOTE C_, 4
	LEN 16
	NOTE E_, 4
	LEN 32
	NOTE D_, 4
	LEN 16
	NOTE B_, 3
	NOTE G_, 3
	LEN 24
	NOTE E_, 3
	NOTE G_, 3
	LEN 16
	NOTE B_, 3
	LENGTH $40
	NOTE A_, 3
	NEXT
Pat_6AE3:
	LEN 24
	NOTE A_, 3
	NOTE C_, 4
	LEN 16
	NOTE E_, 4
	LEN 32
	NOTE D_, 4
	LEN 16
	NOTE G_, 4
	NOTE D_, 4
	LENGTH $30
	NOTE E_, 4
	LEN 16
	NOTE C_, 4
	LEN 32
	NOTE D_, 4
	NOTE B_, 3
	LEN 24
	NOTE A_, 3
	NOTE C_, 4
	LEN 16
	NOTE E_, 4
	LEN 32
	NOTE D_, 4
	LEN 16
	NOTE G_, 4
	NOTE A_, 4
	LEN 24
	NOTE B_, 4
	NOTE C_, 5
	LEN 16
	NOTE B_, 4
	LENGTH $40
	NOTE A_, 4
	NEXT
Pat_6B08:
	LEN 32
	WAIT
	NOTE E_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 5
	LEN 16
	NOTE E_, 5
	LEN 32
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 4
	LEN 16
	NOTE E_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	LEN 32
	NOTE D_, 5
	LEN 16
	NOTE D_, 5
	NOTE C_, 5
	NOTE E_, 4
	NOTE B_, 4
	LEN 32
	NOTE G_, 4
	LEN 16
	NOTE A_, 4
	NEXT
Pat_6B27:
	LEN 32
	WAIT
	NOTE E_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 5
	LEN 16
	NOTE F_, 5
	LEN 32
	NOTE E_, 5
	NOTE C_, 5
	LENGTH $40
	NOTE D_, 5
	LEN 32
	NOTE G_, 5
	NOTE D_, 5
	LENGTH $40
	NOTE E_, 5
	LEN 32
	NOTE C_, 6
	NOTE B_, 5
	LEN 16
	NOTE A_, 5
	NEXT
DrumPat_6B41:
	db DRUM_LEVEL + 14, 1, 0, 6, 0, 9, 0, 1
	db 0, 1, 0, 6, 6, 9, 0, 4
	db 0, 1, 0, 6, 0, 9, 0, 1
	db 0, 1, 0, 6, 1, 9, 0, 1
	db 0, 1, 0, 6, 0, 9, 0, 1
	db 0, 1, 0, 6, 6, 9, 0, 4
	db 0, 1, 0, 6, 0, 9, 0, 1
	db 0, 1, 0, 6, 1, 9, 0, 9
	db 0, DRUM_LOOP

; Song 13: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong13:
	ld a, $70
	ld [wInstrTableHi], a
	ld a, $B4
	ld [wInstrTable], a
	call StopAll
	ld de, Song13_Ch1
	call StartMusicCh1
	ld de, Song13_Ch2
	call StartMusicCh2
	ld de, Song13_Ch3
	jp StartMusicCh3
Song13_Ch1:
	dw Pat_6BE4
	dw Pat_6C06
	dw Pat_6C1F
	dw Pat_6C2A
	dw Pat_6C2A
	dw Pat_6C43
	dw Pat_6C2A
	dw Pat_6C2A
	dw Pat_6C43
	ORDER_LOOP Song13_Ch1
Song13_Ch2:
	dw Pat_6C5E
	dw Pat_6C5E
	dw Pat_6C7D
	dw Pat_6C8B
	dw Pat_6C8B
	dw Pat_6CA8
	dw Pat_6C8B
	dw Pat_6C8B
	dw Pat_6CA8
	ORDER_LOOP Song13_Ch2
Song13_Ch3:
	dw Pat_6CBE
	dw Pat_6CEC
	dw Pat_6D12
	dw Pat_6D1B
	dw Pat_6D1B
	dw Pat_6D3F
	dw Pat_6D1A
	dw Pat_6D1B
	dw Pat_6D3F
	ORDER_LOOP Song13_Ch3
Pat_6BE4:
	HWENV $F4, $04, $C5
	ARP 0
	DUTY_50
	VIBRATO $07, $02, $05
	LEN 42
	NOTE G_, 2
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	LEN 42
	NOTE F_, 2
	NOTE F_, 2
	LEN 28
	NOTE C_, 3
	LEN 42
	NOTE G_, 2
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	LEN 42
	NOTE F_, 2
	LEN 28
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	LEN 28
	NOTE C_, 3
	NEXT
Pat_6C06:
	LEN 42
	NOTE G_, 2
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	LEN 42
	NOTE F_, 2
	LEN 28
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	LEN 42
	NOTE G_, 2
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	LEN 42
	NOTE F_, 2
	NOTE F_, 2
	LEN 14
	NOTE C_, 3
	NOTE A_, 2
	NEXT
Pat_6C1F:
	LEN 42
	NOTE F_, 2
	NOTE F_, 2
	LEN 28
	NOTE F_, 2
	LEN 42
	NOTE F_, 2
	NOTE F_, 2
	LEN 28
	NOTE F_, 2
	NEXT
Pat_6C2A:
	LEN 42
	NOTE C_, 2
	NOTE C_, 2
	LEN 28
	NOTE C_, 2
	LEN 42
	NOTE Gsh, 2
	NOTE Gsh, 2
	LEN 14
	NOTE Gsh, 2
	NOTE Dsh, 2
	LEN 42
	NOTE C_, 2
	NOTE C_, 2
	LEN 28
	NOTE C_, 2
	LEN 42
	NOTE Ash, 2
	LEN 28
	NOTE Ash, 2
	LEN 14
	NOTE F_, 2
	NOTE Ash, 2
	NOTE F_, 2
	NEXT
Pat_6C43:
	LEN 42
	NOTE Ash, 2
	NOTE Ash, 2
	LEN 14
	NOTE Ash, 2
	NOTE F_, 2
	LEN 42
	NOTE Gsh, 2
	NOTE Gsh, 2
	LEN 14
	NOTE Gsh, 2
	NOTE G_, 2
	LEN 42
	NOTE F_, 2
	LEN 28
	NOTE F_, 2
	LEN 14
	NOTE C_, 2
	NOTE F_, 2
	NOTE C_, 2
	LEN 42
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE D_, 2
	NEXT
Pat_6C5E:
	HWENV $C1, $00
	DUTY_75
	ARP_OFF
	LEN 7
	REPEAT 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE D_, 4
	REPEAT_END
	REPEAT 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	REPEAT_END
	REPEAT 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE D_, 4
	REPEAT_END
	REPEAT 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	REPEAT_END
	NEXT
Pat_6C7D:
	LEN 7
	REPEAT 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	REPEAT_END
	REPEAT 4
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	REPEAT_END
	NEXT
Pat_6C8B:
	HWENV $F1, $00
	ARP 0
	DUTY_12
	LEN 14
	REPEAT 3
	NOTE C_, 4
	NOTE G_, 3
	REPEAT_END
	NOTE C_, 4
	NOTE D_, 4
	REPEAT 3
	NOTE Dsh, 4
	NOTE Gsh, 3
	REPEAT_END
	NOTE Dsh, 4
	NOTE F_, 4
	REPEAT 3
	NOTE G_, 4
	NOTE C_, 4
	REPEAT_END
	NOTE G_, 4
	NOTE Gsh, 4
	REPEAT 4
	NOTE G_, 4
	NOTE C_, 4
	REPEAT_END
	NEXT
Pat_6CA8:
	LEN 14
	REPEAT 4
	NOTE G_, 4
	NOTE Ash, 3
	REPEAT_END
	REPEAT 4
	NOTE G_, 4
	NOTE Gsh, 3
	REPEAT_END
	REPEAT 4
	NOTE F_, 4
	NOTE A_, 3
	REPEAT_END
	NOTE G_, 4
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NEXT
Pat_6CBE:
	DRUMS $07, DrumPat_6D5F
	CH_TRANSPOSE $0C
	INSTR 6
	VOLENV 15, $11, $1F, $16
	WAVE Wave_786F
	LENGTH $38
	NOTE G_, 3
	LEN 42
	NOTE G_, 4
	LEN 7
	NOTE F_, 4
	NOTE G_, 4
	LEN 42
	NOTE A_, 4
	LEN 14
	NOTE G_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE F_, 3
	LENGTH $38
	NOTE G_, 3
	LEN 42
	NOTE G_, 4
	LEN 7
	NOTE F_, 4
	NOTE G_, 4
	LEN 42
	NOTE A_, 4
	LEN 14
	NOTE C_, 5
	LENGTH $38
	NOTE B_, 4
	NEXT
Pat_6CEC:
	LENGTH $38
	NOTE G_, 3
	LEN 42
	NOTE G_, 4
	LEN 7
	NOTE F_, 4
	NOTE G_, 4
	LEN 35
	NOTE A_, 4
	LEN 7
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE F_, 3
	LENGTH $38
	NOTE G_, 3
	LEN 42
	NOTE G_, 4
	LEN 7
	NOTE F_, 4
	NOTE G_, 4
	LEN 42
	NOTE A_, 4
	LEN 14
	NOTE C_, 5
	LEN 28
	NOTE B_, 4
	NOTE G_, 4
	NEXT
Pat_6D12:
	LENGTH $38
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE F_, 4
	INSTR 6
	NEXT
Pat_6D1A:
	ARP 17
Pat_6D1B:
	DRUMS $0E, DrumPat_6D81
	LEN 28
	NOTE C_, 4
	LEN 14
	NOTE G_, 4
	LEN 42
	NOTE C_, 5
	LEN 14
	NOTE G_, 4
	NOTE C_, 4
	LEN 28
	NOTE Gsh, 3
	LEN 14
	NOTE Dsh, 4
	LEN 42
	NOTE Gsh, 4
	LEN 14
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 28
	NOTE G_, 4
	LEN 14
	NOTE E_, 4
	LEN 42
	NOTE C_, 4
	LEN 28
	NOTE Ash, 3
	LEN 42
	NOTE Ash, 3
	LENGTH $46
	NOTE F_, 4
	NEXT
Pat_6D3F:
	LEN 28
	NOTE Ash, 3
	LEN 14
	NOTE Csh, 4
	LEN 42
	NOTE G_, 4
	LEN 28
	NOTE Csh, 4
	NOTE Gsh, 3
	LEN 14
	NOTE C_, 4
	LEN 42
	NOTE G_, 4
	LEN 28
	NOTE C_, 4
	NOTE A_, 3
	LEN 14
	NOTE C_, 4
	LEN 42
	NOTE G_, 4
	LEN 28
	NOTE F_, 4
	NOTE B_, 4
	LEN 14
	NOTE B_, 4
	LEN 28
	NOTE C_, 5
	LEN 14
	NOTE C_, 5
	LEN 28
	NOTE D_, 5
	NEXT
DrumPat_6D5F:
	db DRUM_LEVEL + 13, 9, 0, 10, 10, 9, 0, 9
	db 0, 10, 10, 9, 0, 9, 0, 10
	db 10, 9, 0, 10, 10, 9, 0, 9
	db 0, 10, 10, 9, 0, 9, 9, 9
	db 9, DRUM_LOOP
DrumPat_6D81:
	db 1, 6, 4, 1, 1, 6, 5, 6
	db DRUM_LOOP

; Song 14: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong14:
	ld a, $70
	ld [wInstrTableHi], a
	ld a, $B4
	ld [wInstrTable], a
	call StopAll
	ld de, Song14_Ch1
	call StartMusicCh1
	ld de, Song14_Ch3
	call StartMusicCh3
	ld de, Song14_Ch2
	jp StartMusicCh2
Song14_Ch1:
	dw Pat_6DC1
	dw Pat_6DDA

; Unreferenced (4 bytes)
	db $00, $00, $A9, $6D
Song14_Ch3:
	dw Pat_6DDF
	dw Pat_6E1F

; Unreferenced (4 bytes)
	db $00, $00, $B1, $6D
Song14_Ch2:
	dw Pat_6E27
	dw Pat_6E52

; Unreferenced (4 bytes)
	db $00, $00, $B9, $6D
Pat_6DC1:
	INSTR 11
	TRANSPOSE $02
	LEN 22
	REPEAT 4
	NOTE D_, 2
	LEN 11
	NOTE D_, 2
	NOTE D_, 2
	LEN 22
	NOTE D_, 2
	LEN 11
	NOTE D_, 2
	NOTE D_, 2
	LEN 22
	NOTE D_, 2
	LEN 11
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE E_, 2
	LEN 22
	NOTE D_, 2
	REPEAT_END
	NEXT
Pat_6DDA:
	INSTR 11
	LENGTH $B0
	NOTE D_, 2
	END
Pat_6DDF:
	VOLENV 12, $11, $1F, $12
	ARP 0
	CH_TRANSPOSE $0C
	WAVE Wave_77BF
	LEN 22
	NOTE F_, 3
	NOTE D_, 3
	NOTE F_, 3
	LEN 11
	NOTE G_, 3
	LEN 22
	NOTE D_, 3
	NOTE D_, 3
	LEN 11
	NOTE D_, 3
	LEN 22
	NOTE F_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE D_, 3
	NOTE F_, 3
	LEN 11
	NOTE G_, 3
	LEN 22
	NOTE D_, 3
	NOTE D_, 3
	LEN 11
	NOTE D_, 3
	LEN 22
	NOTE A_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE D_, 3
	NOTE F_, 3
	LEN 11
	NOTE G_, 3
	LEN 22
	NOTE D_, 3
	NOTE D_, 3
	LEN 11
	NOTE D_, 3
	LEN 22
	NOTE F_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE D_, 3
	NOTE F_, 3
	LEN 11
	NOTE G_, 3
	LEN 22
	NOTE A_, 3
	NOTE G_, 3
	LEN 11
	NOTE F_, 3
	LEN 22
	NOTE G_, 3
	NOTE A_, 3
	NEXT
Pat_6E1F:
	DRUMS_OFF
	CALL_CODE Drum7
	LENGTH $B0
	NOTE D_, 4
	END
Pat_6E27:
	DRUMS $0B, DrumPat_6E57
	HWENV $F3, $0B, $77
	ARP_OFF
	DUTY_50
	VIBRATO $01, $01, $06
	ARP 0
	LEN 22
	NOTE D_, 4
	NOTE A_, 4
	NOTE G_, 4
	LENGTH $6E
	NOTE C_, 5
	ARP 2
	LENGTH $B0
	NOTE D_, 3
	ARP 0
	LEN 22
	NOTE D_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 44
	NOTE C_, 5
	NOTE D_, 5
	LEN 22
	NOTE D_, 4
	ARP 2
	NOTE C_, 3
	NOTE D_, 3
	LENGTH $84
	NOTE D_, 3
	NEXT
Pat_6E52:
	ARP 5
	LENGTH $B0
	NOTE D_, 4
	END
DrumPat_6E57:
	db 1, 0, 3, 1, 1, 0, 3, 1
	db 1, 0, 3, 1, 1, 1, 3, 1
	db DRUM_LOOP

; Song 1: instrument table 1, arpeggio table 1 (the one SndInit sets)
; API song slots 1, 15, 16, 17 all start this routine
PlaySong1:
	ld a, $70
	ld [wInstrTableHi], a
	ld a, $B4
	ld [wInstrTable], a
	call StopAll
	ld de, Song1_Ch1
	call StartMusicCh1
	ld de, Song1_Ch2
	call StartMusicCh2
	ld de, Song1_Ch3
	jp StartMusicCh3

; Unreferenced (1 bytes)
	db $C9
Song1_Ch1:
	dw Pat_6ED0
	dw Pat_6ED0
	dw Pat_6EEE
	dw Pat_6EEE
	dw Pat_6EEE
	dw Pat_6EEE
	dw Pat_6F0D
	dw Pat_6F26
	dw Pat_6F58
	dw Pat_6F58
	ORDER_LOOP Song1_Ch1
Song1_Ch2:
	dw Pat_6F6D
	dw Pat_6F6D
	dw Pat_6F7F
	dw Pat_6F7F
	dw Pat_6F7F
	dw Pat_6F7F
	dw Pat_6F91
	dw Pat_6F91
	dw Pat_6FB0
	dw Pat_6FB0
	ORDER_LOOP Song1_Ch2
Song1_Ch3:
	dw Pat_6FD1
	dw Pat_6FD1
	dw Pat_7000
	dw Pat_7022
	dw Pat_7000
	dw Pat_7022
	dw Pat_7045
	dw Pat_7045
	dw Pat_7076
	dw Pat_7089
	ORDER_LOOP Song1_Ch3
Pat_6ED0:
	DRUMS $0A, DrumPat_709C
	VIBRATO $0A, $04, $05
	INSTR 11
	LEN 20
	REPEAT 4
	NOTE F_, 2
	LEN 10
	NOTE F_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 11
	NOTE F_, 2
	NOTE F_, 2
	LEN 20
	NOTE F_, 2
	LEN 10
	NOTE F_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 11
	LEN 20
	NOTE F_, 2
	REPEAT_END
	NEXT
Pat_6EEE:
	REPEAT 4
	LEN 20
	NOTE Dsh, 2
	LEN 10
	NOTE Dsh, 2
	INSTR 4
	NOTE Dsh, 4
	INSTR 11
	NOTE Dsh, 2
	NOTE Dsh, 3
	REPEAT_END
	REPEAT 3
	LEN 20
	NOTE F_, 2
	LEN 10
	NOTE F_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 11
	NOTE F_, 2
	NOTE F_, 3
	REPEAT_END
	NOTE F_, 2
	NOTE F_, 3
	NOTE Dsh, 3
	INSTR 5
	NOTE F_, 4
	INSTR 11
	NOTE C_, 3
	NOTE Dsh, 3
	NEXT
Pat_6F0D:
	LEN 30
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	LEN 10
	NOTE F_, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	LEN 30
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	LEN 10
	NOTE F_, 2
	NOTE C_, 3
	NOTE Dsh, 3
	NEXT
Pat_6F26:
	REPEAT 2
	LEN 20
	NOTE F_, 2
	LEN 10
	NOTE F_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 11
	NOTE C_, 3
	NOTE Dsh, 3
	REPEAT_END
	LEN 20
	NOTE F_, 2
	LEN 10
	NOTE F_, 2
	INSTR 4
	NOTE Dsh, 4
	INSTR 11
	NOTE C_, 3
	NOTE Dsh, 3
	REPEAT 3
	LEN 20
	NOTE F_, 2
	LEN 10
	NOTE F_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 11
	NOTE C_, 3
	NOTE Dsh, 3
	REPEAT_END
	LEN 20
	NOTE F_, 2
	LEN 10
	NOTE F_, 2
	INSTR 4
	NOTE Dsh, 4
	INSTR 11
	NOTE C_, 3
	NOTE Dsh, 3
	LEN 20
	NOTE F_, 2
	LEN 10
	NOTE F_, 2
	INSTR 5
	NOTE F_, 4
	INSTR 11
	NOTE C_, 3
	NOTE Dsh, 3
	NEXT
Pat_6F58:
	HWENV $F7, $00
	DUTY_75
	LENGTH $3C
	NOTE F_, 2
	NOTE Csh, 3
	NOTE C_, 3
	LEN 30
	NOTE C_, 3
	NOTE Gsh, 2
	LENGTH $3C
	NOTE F_, 2
	NOTE Csh, 3
	NOTE C_, 3
	LEN 30
	NOTE C_, 3
	NOTE Gsh, 2
	NEXT
Pat_6F6D:
	HWENV $B2, $00
	DUTY_12
	ARP 13
	LEN 20
	REPEAT 4
	NOTE F_, 3
	NOTE F_, 4
	LEN 10
	NOTE F_, 3
	NOTE F_, 3
	LEN 20
	NOTE F_, 3
	NOTE F_, 4
	NOTE F_, 3
	REPEAT_END
	NEXT
Pat_6F7F:
	LEN 10
	WAIT
	LEN 20
	REPEAT 4
	NOTE Ash, 3
	NOTE Dsh, 4
	NOTE G_, 4
	REPEAT_END
	REPEAT 3
	NOTE C_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	REPEAT_END
	NOTE C_, 4
	NOTE F_, 4
	LEN 10
	NOTE Gsh, 4
	NEXT
Pat_6F91:
	LEN 20
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Ash, 3
	LEN 10
	NOTE C_, 4
	NOTE Ash, 3
	LEN 20
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Ash, 3
	LEN 10
	NOTE C_, 4
	NOTE Ash, 3
	NEXT
Pat_6FB0:
	REPEAT 3
	LEN 20
	NOTE F_, 4
	LEN 10
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	REPEAT_END
	LEN 20
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 10
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	REPEAT 2
	LEN 20
	NOTE F_, 4
	LEN 10
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	REPEAT_END
	LEN 20
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NEXT
Pat_6FD1:
	CH_TRANSPOSE $0C
	VIBRATO $14, $01, $05
	INSTR 6
	LEN 30
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	LEN 20
	NOTE Ash, 3
	LEN 40
	NOTE F_, 3
	INSTR 13
	LEN 10
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	INSTR 6
	LEN 30
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	LEN 20
	NOTE Ash, 3
	LEN 40
	NOTE F_, 3
	INSTR 13
	LEN 10
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NEXT
Pat_7000:
	CH_TRANSPOSE $00
	WAVE Wave_76EF
	INSTR 13
	LENGTH $64
	NOTE G_, 4
	LEN 10
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 40
	NOTE G_, 4
	LEN 10
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 30
	NOTE G_, 4
	LEN 20
	NOTE Gsh, 4
	LENGTH $64
	NOTE F_, 4
	LEN 20
	NOTE Dsh, 4
	LENGTH $64
	NOTE C_, 4
	LEN 10
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NEXT
Pat_7022:
	INSTR 13
	LENGTH $64
	NOTE G_, 4
	LEN 10
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 40
	NOTE G_, 4
	LEN 10
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 30
	NOTE G_, 4
	NOTE Gsh, 4
	LENGTH $3C
	NOTE Ash, 4
	LEN 40
	NOTE Gsh, 4
	LEN 10
	NOTE G_, 4
	NOTE F_, 4
	LEN 40
	NOTE G_, 4
	LEN 10
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NEXT
Pat_7045:
	VOLENV 12, $11, $1F, $15
	ARP 6
	LEN 20
	NOTE C_, 5
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Dsh, 5
	LEN 10
	NOTE C_, 5
	NOTE Ash, 4
	NOTE G_, 4
	LEN 20
	NOTE Dsh, 4
	LEN 10
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 20
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Dsh, 5
	LEN 10
	NOTE C_, 5
	NOTE Ash, 4
	NOTE G_, 4
	LEN 20
	NOTE Dsh, 4
	LEN 10
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE G_, 5
	LEN 20
	NOTE F_, 5
	NOTE Dsh, 5
	LEN 10
	NOTE F_, 5
	NOTE Dsh, 5
	NEXT
Pat_7076:
	LENGTH $3C
	NOTE F_, 5
	INSTR 13
	NOTE Csh, 4
	LENGTH $5A
	NOTE C_, 4
	LEN 30
	NOTE Gsh, 3
	LENGTH $3C
	NOTE F_, 3
	NOTE Csh, 4
	NOTE C_, 4
	LEN 30
	NOTE Dsh, 4
	NOTE F_, 4
	NEXT
Pat_7089:
	INSTR 13
	LENGTH $3C
	NOTE F_, 3
	NOTE Csh, 4
	LENGTH $5A
	NOTE C_, 4
	LEN 30
	NOTE Gsh, 3
	LENGTH $3C
	NOTE F_, 3
	NOTE Csh, 4
	NOTE C_, 4
	LEN 30
	NOTE Dsh, 4
	NOTE F_, 4
	NEXT
DrumPat_709C:
	db DRUM_LEVEL + 13, 1, 0, 6, 9, 6, 6, 1
	db 0, 6, 9, 6, 6, 1, 0, 6
	db 9, 6, 6, 1, 0, 6, 9, 6
	db 9, DRUM_LOOP

; Instrument table 1, entries 1..17 (the song routines point 2 bytes before:
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
	dw Instr1_14
	dw Instr1_15
	dw Instr1_16
Instr1_0:
	HWENV $93, $00
	DUTY_50
	ARP 12
	END
Instr1_1:
	HWENV $C2, $03, $42
	ARP 14
	END
Instr1_2:
	HWENV $F1, $04, $71
	ARP 15
	END
Instr1_3:
	HWENV $F2, $04, $72
	DUTY_12
	ARP 0
	END
Instr1_4:
	HWENV $F2, $04, $84
	DUTY_75
	ARP 4
	END
Instr1_5:
	HWENV $F2, $04, $84
	DUTY_75
	ARP 5
	END
Instr1_6:
	VOLENV 12, $11, $1F, $14
	ARP 0
	WAVE Wave_77BF
	END
Instr1_7:
	VOLENV 15, $00, $1A, $14
	ARP 2
	WAVE Wave_78BF
	END
Instr1_8:
	HWENV $7F, $1C, $F5
	ARP 4
	DUTY_12
	END
Instr1_9:
	HWENV $C1, $04, $45
	DUTY_12
	ARP 0
	END
Instr1_10:
	HWENV $C2, $04, $73
	ARP 0
	DUTY_12
	END
Instr1_11:
	HWENV $F2, $00
	ARP 0
	END
Instr1_12:
	HWENV $E1, $00
	ARP 0
	END
Instr1_13:
	VOLENV 8, $18, $1F, $1A
	END
Instr1_14:
	HWENV $C2, $00
	ARP 0
	END
Instr1_15:
	HWENV $F1, $04, $96
	ARP 0
	END
Instr1_16:
	HWENV $F4, $00
	ARP 2
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
	dw Arp10
	dw Arp12
	dw Arp13
	dw Arp14
	dw Arp15
	dw Arp16
	dw Arp17

; Unreferenced (20 bytes)
	db $11, $72, $15, $72, $15, $72, $15, $72, $15, $72, $15, $72, $19, $72, $19, $72
	db $19, $72, $19, $72
Arp0:
	db $0C, $00, ARP_HOLD
Arp3:
	db $00, $00, $01, $01, $02, ARP_HOLD
Arp2:
	db $07, $0C, $03, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, ARP_LOOP
Arp1:
	db $0C, $07, $07, $00, ARP_HOLD
Arp4:
	db $00, $00, $04, $04, $07, $07, ARP_LOOP
Arp5:
	db $00, $00, $03, $03, $07, $07, ARP_LOOP
Arp6:
	db $0C, $00, $00, $00, $00, $00, $00, $00
	db $00, ARP_LOOP
Arp7:
	db $01, $00, $02, $01, $03, $01, $00, ARP_LOOP
Arp8:
	db $0C, $00, $00, $00, $00, $00, $00, $00
	db $18, $0C, ARP_HOLD
Arp9:
	db $0C, $0C, $00, ARP_HOLD
Arp10:
	db $0C, $00, $00, $00, $00, $00, $00, $0C
	db $0C, $0C, $0C, $0C, $0C, $0C, ARP_HOLD
Arp12:
	db $00, $0C, $00, ARP_HOLD
Arp13:
	db $0C, $00, $00, $00, $00, $00, $00, $00
	db $00, $0C, ARP_HOLD
Arp14:
	db $22, $04, $03, $02, $01, $00, ARP_HOLD
Arp15:
	db $02, $FC, $FA, $F8, $F5, $F2, $F0, $EC
	db $EA, $E6, ARP_HOLD
Arp16:
	db $0C, $00, $00, $00, $00, $00, $00, $00
	db $00, $18, $0C, $0C, $0C, $0C, $0C, $0C
	db $0C, $0C, ARP_LOOP
Arp17:
	db $0C, $0C, $00, $00, ARP_LOOP

; Unreferenced (37 bytes)
	db $03, $00, $07, $6A, $18, $0C, $00, $FF, $35, $72, $35, $72, $35, $72, $35, $72
	db $35, $72, $35, $72, $35, $72, $35, $72, $35, $72, $35, $72, $35, $72, $35, $72
	db $35, $72, $35
SfxTable_m2:
	db $72, $68

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
	CALL_CODE Code_753E
	END

; Sound effect 21
Sfx21:
	CALL_CODE Code_7654
	END

; Sound effect 20
Sfx20:
	VOLENV 10, $15, $1F, $23
	VIBRATO $00, $02, $06
	WAVE Wave_786F
	ARP 7
	LEN 20
	NOTE A_, 5
	WAIT
	END

; Sound effect 19
Sfx19:
	CALL_CODE Code_7473
	END

; Sound effect 3
Sfx03:
	WAVE Wave_775F
	CALL_CODE Code_74D9
	VOLENV 15, $12, $1F, $12
	LEN 8
	GLIDE $FF
	NOTE A_, 4
	LEN 5
	VOLENV 10, $11, $1F, $12
	NOTE A_, 4
	END

; Sound effect 4
Sfx04:
	CALL_CODE Code_75F2
	END

; Sound effect 5
Sfx05:
	VOLENV 15, $11, $2F, $11
	WAVE Wave_777F
	LEN 13
	NOTE C_, 6
	END

; Sound effect 6
Sfx06:
	LEN 4
	VOLENV 15, $11, $2F, $11
	WAVE Wave_777F
	LEN 4
	NOTE Gsh, 5
	LEN 1
	REST
	LEN 4
	NOTE Gsh, 6
	END

; Sound effect 7
Sfx07:
	VOLENV 15, $11, $1F, $11
	CALL_CODE Code_750D
	WAVE Wave_775F
	LEN 12
	GLIDE $FE
	NOTE C_, 3
	END

; Unreferenced (4 bytes)
	db $7F, $98, $75, $68

; Sound effect 8
Sfx08:
	LEN 5
	ARP 0
	WAVE Wave_77FF
	VOLENV 15, $10, $1F, $12
	NOTE C_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	END

; Sound effect 9
Sfx09:
	CALL_CODE Code_74A0
	END

; Sound effect 10
Sfx10:
	VOLENV 15, $11, $1F, $14
	WAVE Wave_777F
	VIBRATO $01, $01, $08
	LEN 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE Gsh, 4
	END

; Sound effect 11
Sfx11:
	CALL_CODE Code_756F
	END

; Sound effect 2
Sfx02:
	CALL_CODE Code_7621
	VOLENV 15, $11, $3F, $11
	WAVE Wave_775F
	LEN 4
	NOTE G_, 4
	NOTE B_, 4
	END

; Sound effect 12
Sfx12:
	VOLENV 12, $11, $1F, $14
	WAVE Wave_775F
	GLIDE $04
	LEN 4
	NOTE G_, 3
	GLIDE $FD
	LEN 6
	WAIT
	REST
	END

; Sound effect 13
Sfx13:
	VOLENV 13, $11, $1F, $12
	WAVE Wave_775F
	LEN 13
	SLIDE_DOWN $03
	NOTE A_, 5
	END

; Sound effect 14
Sfx14:
	VOLENV 10, $11, $10, $00
	WAVE Wave_784F
	GLIDE $02
	LEN 5
	NOTE A_, 2
	GLIDE_OFF
	LEN 3
	WAIT
	GLIDE $02
	WAIT
	END

; Sound effect 15
Sfx15:
	CALL_CODE Code_7473
	VOLENV 15, $00, $00, $00
	WAVE Wave_78BF
	LEN 3
	GLIDE $FF
	NOTE A_, 6
	WAVE Wave_788F
	WAIT
	GLIDE $FE
	WAVE Wave_78AF
	WAIT
	WAIT
	END

; Sound effect 16
Sfx16:
	CALL_CODE Code_737D
	WAVE Wave_775F
	VOLENV 10, $11, $1F, $12
	LEN 7
	GLIDE $01
	NOTE C_, 3
	NOTE G_, 2
	END

; Sound effect 17
Sfx17:
	CALL_CODE Code_73AA
	END

; Sound effect 18
Sfx18:
	VOLENV 15, $00, $00, $00
	WAVE Wave_784F
	LEN 5
	NOTE A_, 3
	LEN 3
	REST
	LEN 20
	NOTE A_, 3
	END
Noise43_7361:
	db $82, $64, $02, $37, $47, $24, $55, $71
	db $07, $44, $60, $36, $84, $82, $64, $02
	db $37, $47, $24, $55, $71, $07, $44, $60
	db $36, $86, $32, $FF
Code_737D:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $13
	ld [wDrumHold], a
	call NoisePanCentre
	ld a, $F2
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ld a, HIGH(Noise43_7361)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7361)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Code_73AA:
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
	ld a, HIGH(Noise43_7361)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7361)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret

; Unreferenced (156 bytes)
	db $3E, $08, $EA, $47, $DC, $AF, $EA, $5B, $DC, $3C, $EA, $5C, $DC, $3E, $73, $EA
	db $57, $DC, $3E, $F9, $EA, $58, $DC, $3E, $74, $EA, $59, $DC, $3E, $01, $EA, $5A
	db $DC, $C9, $60, $52, $42, $41, $22, $11, $21, $FF, $F0, $F0, $F0, $F0, $F0, $F0
	db $61, $3E, $0F, $EA, $47, $DC, $AF, $EA, $5B, $DC, $3C, $EA, $5C, $DC, $3E, $74
	db $EA, $57, $DC, $3E, $4C, $EA, $58, $DC, $3E, $74, $EA, $59, $DC, $3E, $66, $EA
	db $5A, $DC, $C9, $3E, $0F, $EA, $47, $DC, $AF, $EA, $5B, $DC, $3C, $EA, $5C, $DC
	db $3E, $74, $EA, $57, $DC, $3E, $59, $EA, $58, $DC, $3E, $74, $EA, $59, $DC, $3E
	db $66, $EA, $5A, $DC, $C9, $10, $10, $20, $31, $32, $33, $33, $34, $34, $35, $35
	db $36, $FF, $36, $35, $35, $34, $34, $33, $33, $32, $31, $20, $10, $10, $FF, $5C
	db $FF, $FF, $FF, $FF, $FF, $A1, $FF, $FF, $FF, $FF, $FF, $FF
Code_7473:
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7495)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7495)
	ld [wNoise43], a
	ld a, HIGH(Noise42_749B)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_749B)
	ld [wNoise42], a
	ret
Noise43_7495:
	db $00, $53, $71, $91, $31, $FF
Noise42_749B:
	db $F2, $FF, $FF, $FF, $00
Code_74A0:
	ld a, $0A
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_74C2)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_74C2)
	ld [wNoise43], a
	ld a, HIGH(Noise42_74CE)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_74CE)
	ld [wNoise42], a
	ret
Noise43_74C2:
	db $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0
	db $A0, $A0, $A0, $FF
Noise42_74CE:
	db $F0, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $00
Code_74D9:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $F2
	ldh [rNR42], a
	ld a, $82
	ldh [rNR44], a
	ld a, HIGH(Noise43_7503)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7503)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_7503:
	db $02, $92, $42, $42, $42, $42, $52, $65
	db $45, $FF
Code_750D:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_752F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_752F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7537)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7537)
	ld [wNoise42], a
	ret
Noise43_752F:
	db $02, $51, $61, $71, $91, $71, $60, $FF
Noise42_7537:
	db $F0, $F0, $F0, $F0, $F0, $70, $63
Code_753E:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7560)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7560)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7568)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7568)
	ld [wNoise42], a
	ret
Noise43_7560:
	db $22, $51, $64, $81, $51, $41, $60, $FF
Noise42_7568:
	db $F0, $F0, $F0, $F0, $F0, $70, $63
Code_756F:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7591)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7591)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7595)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7595)
	ld [wNoise42], a
	ret
Noise43_7591:
	db $02, $51, $11, $FF
Noise42_7595:
	db $F0, $A0, $55

; Unreferenced (90 bytes)
	db $3E, $0F, $EA, $47, $DC, $AF, $EA, $5B, $DC, $3C, $EA, $5C, $DC, $3E, $75, $EA
	db $57, $DC, $3E, $BA, $EA, $58, $DC, $3E, $75, $EA, $59, $DC, $3E, $C0, $EA, $5A
	db $DC, $C9, $02, $41, $61, $71, $11, $FF, $F0, $FF, $FF, $A0, $B2, $3E, $08, $EA
	db $47, $DC, $AF, $EA, $5B, $DC, $3C, $EA, $5C, $DC, $3E, $75, $EA, $57, $DC, $3E
	db $E7, $EA, $58, $DC, $3E, $75, $EA, $59, $DC, $3E, $ED, $EA, $5A, $DC, $C9, $00
	db $83, $60, $60, $31, $FF, $F0, $FF, $FF, $FF, $D1
Code_75F2:
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7614)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7614)
	ld [wNoise43], a
	ld a, HIGH(Noise42_761B)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_761B)
	ld [wNoise42], a
	ret
Noise43_7614:
	db $41, $61, $61, $41, $71, $71, $FF
Noise42_761B:
	db $A1, $52, $00, $61, $52, $00
Code_7621:
	ld a, $0A
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7643)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7643)
	ld [wNoise43], a
	ld a, HIGH(Noise42_764C)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_764C)
	ld [wNoise42], a
	ret
Noise43_7643:
	db $78, $78, $78, $78, $58, $56, $56, $68
	db $FF
Noise42_764C:
	db $A1, $FF, $11, $00, $81, $FF, $11, $00
Code_7654:
	ld a, $32
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $03
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_767F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_767F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7689)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7689)
	ld [wNoise42], a
	ret
Noise43_767F:
	db $67, $56, $45, $34, $23, $22, $11, $10
	db $20, $FF
Noise42_7689:
	db $19, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $F3

; Unreferenced (45 bytes)
	db $3E, $19, $EA, $47, $DC, $AF, $EA, $5B, $DC, $3C, $EA, $5C, $DC, $3E, $76, $EA
	db $57, $DC, $3E, $B4, $EA, $58, $DC, $3E, $76, $EA, $59, $DC, $3E, $BA, $EA, $5A
	db $DC, $C9, $03, $83, $80, $80, $51, $FF, $F0, $FF, $FF, $FF, $F2
Wave_76BF:
	db $84, $32, $55, $55, $51, $23, $8F, $F8
	db $40, $04, $8F, $F8, $40, $04, $8F, $F8

; Unreferenced (16 bytes)
	db $02, $46, $8A, $CE, $FF, $DB, $DF, $FF, $EC, $A8, $64, $20, $FF, $FF, $FF, $FF
Wave_76DF:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $00, $00, $00, $77, $77, $00, $00, $00
Wave_76EF:
	db $01, $11, $11, $00, $89, $AA, $AA, $98
	db $01, $11, $11, $00, $FF, $FF, $FF, $FF

; Unreferenced (16 bytes)
	db $A8, $40, $04, $8A, $FF, $FF, $FF, $FF, $A8, $40, $04, $8A, $FF, $FF, $FF, $FF
Wave_770F:
	db $8C, $FE, $ED, $B8, $53, $21, $10, $24
	db $84, $01, $12, $35, $8B, $DE, $EF, $8C
Wave_771F:
	db $00, $46, $8A, $FF, $FF, $A8, $64, $00
	db $00, $46, $8A, $FF, $FF, $A8, $64, $00

; Unreferenced (48 bytes)
	db $B7, $40, $F4, $7B, $FD, $FF, $FE, $DC, $02, $46, $8A, $BD, $FD, $BA, $6F, $20
	db $32, $22, $11, $11, $11, $22, $23, $45, $FD, $CB, $A9, $87, $65, $43, $21, $10
	db $DD, $DB, $97, $52, $22, $54, $22, $22, $DD, $DC, $BD, $DD, $DB, $85, $22, $22
Wave_775F:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF

; Unreferenced (16 bytes)
	db $01, $11, $11, $00, $89, $AA, $AA, $98, $01, $11, $11, $00, $FF, $FF, $FF, $FF
Wave_777F:
	db $00, $00, $00, $00, $CD, $EF, $FD, $EC
	db $00, $12, $21, $00, $DD, $DD, $DD, $DD

; Unreferenced (48 bytes)
	db $00, $00, $00, $00, $00, $00, $FF, $FF, $00, $00, $00, $00, $00, $00, $FF, $FF
	db $00, $00, $00, $00, $00, $00, $FF, $00, $00, $00, $00, $00, $00, $00, $FF, $00
	db $00, $00, $00, $CD, $EF, $FF, $FF, $FF, $04, $8C, $FF, $FF, $FF, $FF, $FF, $FF
Wave_77BF:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $00, $FF, $FF, $FF

; Unreferenced (48 bytes)
	db $12, $34, $56, $78, $9A, $BC, $DE, $FF, $ED, $CB, $A9, $87, $65, $43, $21, $00
	db $FF, $FE, $ED, $B8, $53, $21, $10, $00, $00, $01, $12, $35, $8B, $DE, $EF, $FF
	db $63, $10, $00, $00, $00, $00, $01, $36, $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9
Wave_77FF:
	db $63, $10, $01, $47, $74, $10, $01, $36
	db $9C, $EF, $FE, $B8, $8B, $EF, $FE, $C9
Wave_780F:
	db $63, $1F, $01, $47, $74, $10, $01, $36
	db $9C, $E0, $FE, $B8, $8B, $EF, $FE, $C9

; Unreferenced (16 bytes)
	db $65, $43, $22, $27, $72, $22, $22, $29, $AB, $CC, $BA, $98, $9C, $EE, $EE, $C9
Wave_782F:
	db $63, $20, $02, $47, $74, $22, $22, $36
	db $9C, $EF, $FE, $B6, $6B, $EE, $EE, $C9
Wave_783F:
	db $B7, $40, $04, $7B, $CD, $FF, $FE, $DC
	db $02, $46, $8A, $BD, $FD, $BA, $64, $20
Wave_784F:
	db $0F, $00, $F0, $F0, $F0, $F0, $00, $0F
	db $0F, $FF, $FF, $00, $FF, $F0, $0F, $0F

; Unreferenced (16 bytes)
	db $BB, $2B, $BB, $2B, $BB, $5B, $2B, $BB, $2B, $BB, $BB, $72, $27, $EB, $BB, $B0
Wave_786F:
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $ED, $CB, $A9, $87, $65, $43, $21, $00
Wave_787F:
	db $FE, $DB, $97, $53, $13, $54, $32, $10
	db $FE, $DC, $BC, $EF, $DB, $85, $32, $10
Wave_788F:
	db $04, $8B, $DE, $FF, $ED, $CB, $A9, $87
	db $65, $44, $44, $32, $11, $24, $7A, $74

; Unreferenced (16 bytes)
	db $20, $13, $69, $BD, $FD, $B9, $64, $20, $13, $68, $B8, $64, $20, $24, $68, $64
Wave_78AF:
	db $20, $24, $68, $AC, $EC, $A8, $64, $20
	db $24, $68, $A8, $64, $20, $24, $68, $64
Wave_78BF:
	db $02, $48, $AC, $FF, $FC, $53, $00, $27
	db $9C, $DD, $DC, $B7, $7B, $CD, $DD, $C9
Wave_78CF:
	db $BD, $FF, $AC, $FF, $FC, $52, $00, $27
	db $9C, $DF, $DC, $B7, $7B, $CD, $AD, $C9
Noise43_78DF:
	db $02, $61, $71, $A1, $B1, $B1, $A1, $FF
Noise42_78E7:
	db $C1, $F0, $A0, $90, $70, $40, $33
Noise43_78EE:
	db $06, $04, $03, $03, $07, $FF
Noise42_78F4:
	db $F0, $C0, $80, $60, $55
Noise43_78F9:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_7901:
	db $60, $30, $12, $FF, $FF, $FF, $FF
Noise43_7908:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_7910:
	db $A0, $60, $32, $FF, $FF, $FF, $FF
Noise43_7917:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_791F:
	db $70, $40, $40, $40, $40, $43, $FF
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_78DF)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_78DF)
	ld [wNoise43], a
	ld a, HIGH(Noise42_78E7)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_78E7)
	ld [wNoise42], a
	ret
Drum8:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7960)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7960)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7966)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7966)
	ld [wNoise42], a
	ret
Noise43_7960:
	db $04, $02, $01, $00, $00, $FF
Noise42_7966:
	db $40, $60, $70, $82, $71
Drum2:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7988)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7988)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7990)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7990)
	ld [wNoise42], a
	ret
Noise43_7988:
	db $60, $52, $42, $41, $22, $11, $04, $FF
Noise42_7990:
	db $F0, $F0, $F0, $A0, $70, $40, $51
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7917)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7917)
	ld [wNoise43], a
	ld a, HIGH(Noise42_791F)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_791F)
	ld [wNoise42], a
	ret
Drum5:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7908)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7908)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7910)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7910)
	ld [wNoise42], a
	ret
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_78F9)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_78F9)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7901)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7901)
	ld [wNoise42], a
	ret
Drum7:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_78EE)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_78EE)
	ld [wNoise43], a
	ld a, HIGH(Noise42_78F4)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_78F4)
	ld [wNoise42], a
	ret
Drum9:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7A28)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7A28)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7A2B)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7A2B)
	ld [wNoise42], a
	ret
Noise43_7A28:
	db $51, $32, $FF
Noise42_7A2B:
	db $F0, $62
Drum10:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7A4A)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7A4A)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7A4D)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7A4D)
	ld [wNoise42], a
	ret
Noise43_7A4A:
	db $51, $32, $FF
Noise42_7A4D:
	db $90, $61

; Unreferenced (15 bytes)
	db $51, $32, $32, $32, $32, $51, $32, $FF, $80, $51, $FF, $FF, $FF, $80, $51
FadeOutTable:
	db $77, $66, $55, $44, $33, $22, $11, $00
	db $80, FADE_END
FadeInTable:
	db $00, $11, $22, $33, $44, $55, $66, $77
	db FADE_END

; Unreferenced (1423 bytes)
	db $46, $69, $6E, $61, $6C, $20, $64, $65, $20, $6C, $61, $20, $72, $75, $74, $69
	db $6E, $61, $20, $64, $65, $20, $6D, $75, $73, $69, $63, $61, $FF, $FF, $FF, $FF
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
	db $FF, $E0, $01, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $62
	db $01, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $BA, $01, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $9C, $02, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $46, $00, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FA, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $9E, $02, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $4E
	db $02, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $D2
	db $01, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $50, $01, $FF, $FF, $FF, $FF, $FF, $FF, $F8, $01, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $16, $02, $FF, $FF, $3C, $02, $44, $02, $FC, $01, $FF, $FF, $FF, $FF, $FF
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
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FC
	db $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $02, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $58, $01, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $6E, $00, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
