; =====================================================================
; Turok 2: Seeds of Evil (U) (M4) [C] - Game Boy Color
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o turok2.o Turok2_SoundDriver.asm
;   rgblink -o turok2.gb turok2.o
;   python tools/cmp_banked.py turok2.gb "Turok 2 - Seeds of Evil (U) (M4) [C][!].gbc" 15:4000-7FFF
; (driver and data fill ROM bank 15; the linked file only matches in that range)
;
; Documentation: Turok_SoundDriver.md / AJG_SoundEngine_Family.md
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
MACRO REPEAT    ; play the following bytes n times (up to REPEAT_END), n = 2-10
	db $F5 + \1
ENDM
MACRO LEN       ; note length in ticks, 1-48
	db $C6 + \1
ENDM
MACRO VOLENV    ; start volume + envelope (CH3/SFX): atk (lo=count hi=step), dec (lo=count hi=step), rates (hi=atk lo=dec)
	db $B7 + \1, \2, \3, \4
ENDM
MACRO INSTR     ; instrument n = entry n + 1 of the current instrument table
	db $85 + \1
ENDM
MACRO ARP       ; arpeggio n of the current arpeggio table
	db $9B + \1
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
DEF DRUM_TEMPO EQU $C6         ; + n: one step every n ticks
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
	jp PlayCh1Tone                     ; PlayCh1Tone (BC = period)
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
PlaySfxEntry2:
	jp PlaySfx                         ; PlaySfxNow (A = id; the same code as PlaySfx)

; PlayCh1Tone (BC = period; API entry 9, as Prisoners of the Sun): Ch1 page period =
; BC, NRx2 value $F0 with the write flag set, NR11 = $C0 (75 % duty). Nothing in
; the game calls it.
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
	add a, $CC
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
	sub $F5
	ld l, $39
	ld [hli], a
	ld [hl], e
	inc l
	ld [hl], d
	jp ReadByte

; StreamCommand: REPEAT / LEN / VOLENV / ARP / INSTR ranges, else CmdTable.
StreamCommand:
	cp $F7
	jr nc, Cmd_Repeat
	cp $C7
	jr nc, Cmd_Len
	cp $B7
	jr nc, Cmd_VolEnv
	cp $9B
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
	sub $C6
	ld l, $09
	ld [hl], a
	jp ReadStream

; VOLENV v, atk, dec, rates: start volume v; attack = lo nibble steps of hi nibble;
; decay likewise; rates hi = ticks per attack step, lo = ticks per decay step.
; Only the CH3 and SFX pages use it.
Cmd_VolEnv:
	sub $B7
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
	sub $9B
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

; SndInit: NR52 = $FF, the instrument table (as StartMusicChN also sets it) and the
; default arpeggio table, clear flags; falls into StopAll.
SndInit:
	ld a, $FF
	ldh [rNR52], a
	ld a, $73
	ld [wInstrTableHi], a
	ld a, $2A
	ld [wInstrTable], a
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

; Unreferenced (58 bytes)
	db $00, $00, $5E, $C3, $8B, $4E, $20, $85, $C9, $74, $07, $8B, $11, $FF, $52, $18
	db $5E, $C3, $33, $C0, $5E, $C3, $90, $90, $90, $90, $83, $EC, $08, $53, $55, $56
	db $8B, $F1, $57, $89, $74, $24, $14, $8B, $46, $08, $83, $F8, $02, $74, $12, $83
	db $F8, $04, $74, $0D, $B8, $09, $00, $00, $00, $5F
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
L48F0:
	ld a, $73
	ld [wInstrTableHi], a
	ld a, $2A
	ld [wInstrTable], a

; StartMusicChN (de = order list): set wInstrTable to the one instrument table (in
; all three entries, so every song plays with it; 14 bytes apart, not 4), reset
; the page, mark it active, start its first pattern. StartMusicCh3 also stops the
; fade and the drums.
StartMusicCh1:
	ld h, $DC
	jr StartMusicCh
L48FE:
	ld a, $73
	ld [wInstrTableHi], a
	ld a, $2A
	ld [wInstrTable], a
StartMusicCh2:
	ld h, $DD
	jr StartMusicCh
L490C:
	ld a, $73
	ld [wInstrTableHi], a
	ld a, $2A
	ld [wInstrTable], a
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
	add a, $14
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
	cp $C7
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
	add a, $10
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
	dw Drum10

; Unreferenced (2 bytes)
	db $99, $7F
DrumTempo:
	sub $C6
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
	call StopAll
	ld de, Song2_Ch1
	call L48F0
	ld de, Song2_Ch2
	call L48FE
	ld de, Song2_Ch3
	jp L490C
Song2_Ch3:
	dw Pat_4BF9
	dw Pat_4BF9
	dw Pat_4BF9
	dw Pat_4C01
	dw Pat_4C01
	dw Pat_4C01
	dw Pat_4C18
	dw Pat_4C71
	dw Pat_4BF9
	dw Pat_4C01
	dw Pat_4C01
	dw Pat_4C01
	dw Pat_4C18
	dw Pat_4C71
	ORDER_LOOP Song2_Ch3
Song2_Ch2:
	dw Pat_4BBB
	dw Pat_4BBB
	dw Pat_4CC8
	dw Pat_4CF0
	dw Pat_4D09
	dw Pat_4D09
	dw Pat_4D65
	dw Pat_4D95
	dw Pat_4CC8
	dw Pat_4CF0
	dw Pat_4D09
	dw Pat_4D09
	dw Pat_4D65
	dw Pat_4D95
	ORDER_LOOP Song2_Ch2
Song2_Ch1:
	dw Pat_4BBB
	dw Pat_4BB7
	dw Pat_4DC2
	dw Pat_4DDC
	dw Pat_4DF1
	dw Pat_4DF1
	dw Pat_4E47
	dw Pat_4E65
	dw Pat_4DC2
	dw Pat_4DDC
	dw Pat_4DF1
	dw Pat_4DF1
	dw Pat_4E47
	dw Pat_4E65
	ORDER_LOOP Song2_Ch1
Pat_4BB7:
	AUTODUTY $07
	CH_TRANSPOSE $07
Pat_4BBB:
	ARP_OFF
	DUTY_12
	HWENV $A4, $00
	RELEASE $01, $11
	LEN 14
	REPEAT 3
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	NOTE F_, 3
	GLIDE $FE
	LEN 14
	NOTE A_, 3
	GLIDE_OFF
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	NOTE F_, 3
	LEN 14
	NOTE F_, 2
	GLIDE $FE
	NOTE A_, 3
	LEN 14
	GLIDE_OFF
	NOTE Dsh, 2
	REPEAT_END
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	NOTE F_, 3
	GLIDE $FE
	LEN 14
	NOTE A_, 3
	GLIDE_OFF
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	NOTE F_, 3
	LEN 14
	NOTE F_, 2
	LEN 7
	GLIDE $FE
	NOTE A_, 3
	NOTE A_, 3
	LEN 14
	NOTE A_, 3
	GLIDE_OFF
	RELEASE $00
	AUTODUTY $00
	CH_TRANSPOSE $00
	NEXT
Pat_4BF9:
	DRUMS $07, DrumPat_4E7E
	CH_TRANSPOSE $0C
	INSTR 19
	LEN 14
Pat_4C01:
	REPEAT 4
	NOTE F_, 2
	INSTR 20
	LEN 7
	NOTE F_, 3
	NOTE F_, 3
	INSTR 2
	LEN 14
	NOTE A_, 3
	INSTR 19
	NOTE F_, 2
	INSTR 20
	LEN 7
	NOTE F_, 3
	NOTE F_, 3
	LEN 14
	NOTE F_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 19
	NOTE Dsh, 2
	REPEAT_END
	NEXT
Pat_4C18:
	INSTR 19
	LEN 14
	NOTE Csh, 2
	INSTR 20
	LEN 7
	NOTE Csh, 3
	NOTE Csh, 3
	INSTR 2
	LEN 14
	NOTE A_, 3
	INSTR 19
	NOTE Csh, 2
	INSTR 20
	LEN 7
	NOTE Csh, 3
	NOTE Csh, 3
	LEN 14
	NOTE Csh, 2
	INSTR 2
	NOTE A_, 3
	INSTR 19
	NOTE F_, 2
	NOTE Ash, 2
	INSTR 20
	LEN 7
	NOTE Ash, 3
	NOTE Ash, 3
	INSTR 2
	LEN 14
	NOTE A_, 3
	INSTR 19
	NOTE Ash, 2
	INSTR 20
	LEN 7
	NOTE Ash, 3
	NOTE Ash, 3
	LEN 14
	NOTE Ash, 2
	INSTR 2
	NOTE A_, 3
	INSTR 19
	NOTE Gsh, 2
	NOTE F_, 2
	INSTR 20
	LEN 7
	NOTE F_, 3
	NOTE F_, 3
	INSTR 2
	LEN 14
	NOTE A_, 3
	INSTR 19
	NOTE F_, 2
	INSTR 20
	LEN 7
	NOTE F_, 3
	NOTE F_, 3
	LEN 14
	NOTE F_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 19
	NOTE Dsh, 2
	NOTE F_, 2
	INSTR 20
	LEN 7
	NOTE F_, 3
	NOTE F_, 3
	INSTR 2
	LEN 14
	NOTE A_, 3
	INSTR 19
	NOTE F_, 2
	INSTR 20
	LEN 7
	NOTE F_, 3
	INSTR 19
	NOTE Gsh, 2
	NOTE F_, 2
	INSTR 20
	NOTE Ash, 2
	INSTR 2
	NOTE A_, 3
	INSTR 20
	NOTE Gsh, 2
	INSTR 19
	NOTE Dsh, 2
	INSTR 20
	NOTE F_, 2
	NEXT
Pat_4C71:
	INSTR 19
	LEN 14
	NOTE Csh, 2
	INSTR 20
	LEN 7
	NOTE Csh, 3
	NOTE Csh, 3
	INSTR 2
	LEN 14
	NOTE A_, 3
	INSTR 19
	NOTE Csh, 2
	INSTR 20
	LEN 7
	NOTE Csh, 3
	NOTE Csh, 3
	LEN 14
	NOTE Csh, 2
	INSTR 2
	NOTE A_, 3
	INSTR 19
	NOTE F_, 2
	NOTE Ash, 2
	INSTR 20
	LEN 7
	NOTE Ash, 3
	NOTE Ash, 3
	INSTR 2
	LEN 14
	NOTE A_, 3
	INSTR 19
	NOTE Ash, 2
	INSTR 20
	LEN 7
	NOTE Ash, 3
	NOTE Ash, 3
	LEN 14
	NOTE Ash, 2
	INSTR 2
	NOTE A_, 3
	INSTR 19
	NOTE Gsh, 2
	NOTE F_, 2
	INSTR 20
	LEN 7
	NOTE F_, 3
	NOTE F_, 3
	INSTR 2
	LEN 14
	NOTE A_, 3
	INSTR 19
	NOTE F_, 2
	INSTR 20
	LEN 7
	NOTE F_, 3
	NOTE F_, 3
	LEN 14
	NOTE F_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 19
	NOTE Dsh, 2
	NOTE C_, 3
	INSTR 20
	LEN 7
	NOTE C_, 4
	NOTE C_, 4
	INSTR 2
	LEN 14
	NOTE A_, 3
	INSTR 19
	NOTE C_, 3
	INSTR 20
	LEN 7
	NOTE C_, 4
	INSTR 19
	NOTE Ash, 2
	NOTE Gsh, 2
	INSTR 20
	NOTE Gsh, 3
	INSTR 2
	NOTE A_, 3
	INSTR 19
	NOTE F_, 2
	LEN 14
	NOTE Dsh, 2
	NEXT
Pat_4CC8:
	HWENV $D7, $00
	VIBRATO $0A, $02, $04
	DUTY_50
	RELEASE $01, $10
	LEN 42
	NOTE F_, 4
	NOTE G_, 4
	LEN 28
	NOTE Gsh, 4
	LEN 42
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 28
	NOTE G_, 4
	LENGTH $54
	NOTE F_, 4
	LEN 14
	NOTE Dsh, 4
	LEN 28
	NOTE F_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 28
	NOTE Gsh, 4
	LEN 7
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 14
	NOTE G_, 4
	NEXT
Pat_4CF0:
	LEN 42
	NOTE F_, 4
	NOTE G_, 4
	LEN 28
	NOTE Gsh, 4
	LEN 42
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 28
	NOTE G_, 4
	LENGTH $54
	NOTE F_, 4
	LEN 14
	NOTE Dsh, 4
	LEN 28
	NOTE F_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 28
	NOTE Gsh, 4
	NOTE Ash, 4
	NEXT
Pat_4D09:
	LEN 7
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE C_, 5
	HWENV $D1, $07, $52
	ARP 6
	DUTY_75
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE F_, 4
	NOTE F_, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE C_, 4
	NOTE F_, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 14
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	HWENV $D7, $00
	ARP_OFF
	DUTY_50
	LEN 7
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE Ash, 4
	LEN 14
	NOTE Gsh, 4
	LEN 7
	NOTE F_, 4
	HWENV $D1, $07, $52
	ARP 6
	DUTY_75
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE Dsh, 5
	HWENV $D7, $00
	ARP_OFF
	DUTY_50
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE Ash, 4
	NEXT
Pat_4D65:
	LEN 42
	NOTE Gsh, 4
	NOTE F_, 4
	LEN 7
	NOTE Gsh, 4
	NOTE Ash, 4
	LEN 14
	NOTE C_, 5
	NOTE Ash, 4
	LEN 7
	NOTE Gsh, 4
	LENGTH $31
	NOTE F_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	LEN 7
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE Dsh, 4
	LENGTH $46
	NOTE C_, 4
	LEN 14
	NOTE F_, 5
	LEN 7
	NOTE F_, 5
	LEN 14
	NOTE Dsh, 5
	LEN 7
	NOTE Dsh, 5
	LEN 21
	NOTE C_, 5
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NEXT
Pat_4D95:
	LEN 7
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Dsh, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	LEN 14
	NOTE Dsh, 5
	LEN 7
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	LENGTH $46
	NOTE F_, 5
	LEN 14
	NOTE C_, 6
	LEN 7
	NOTE Ash, 5
	LEN 21
	NOTE Gsh, 5
	LEN 7
	NOTE Ash, 5
	NOTE Gsh, 5
	LENGTH $38
	NOTE F_, 5
	LEN 14
	NOTE Dsh, 5
	LEN 7
	NOTE F_, 5
	LEN 14
	NOTE Gsh, 5
	LENGTH $77
	NOTE Dsh, 5
	NEXT
Pat_4DC2:
	DUTY_75
	HWENV $4E, $1C, $A7
	ARP 5
	LEN 42
	NOTE F_, 4
	LENGTH $46
	NOTE F_, 4
	LEN 42
	NOTE C_, 4
	LENGTH $46
	NOTE C_, 4
	ARP 4
	LEN 42
	NOTE Csh, 4
	LENGTH $46
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 42
	NOTE Dsh, 4
	NEXT
Pat_4DDC:
	ARP 5
	LEN 42
	NOTE F_, 4
	LENGTH $46
	NOTE F_, 4
	LEN 42
	NOTE C_, 4
	LENGTH $46
	NOTE C_, 4
	ARP 4
	LEN 42
	NOTE Csh, 4
	LENGTH $46
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 42
	NOTE Dsh, 4
	NEXT
Pat_4DF1:
	HWENV $E1, $00
	ARP 5
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	ARP 4
	NOTE Dsh, 4
	ARP 5
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	ARP 4
	LEN 14
	NOTE Dsh, 4
	ARP 5
	NOTE F_, 4
	ARP 4
	LEN 7
	NOTE Dsh, 4
	ARP 5
	NOTE F_, 4
	ARP 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE Csh, 4
	NOTE Dsh, 4
	LEN 7
	NOTE Csh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Csh, 4
	LEN 7
	NOTE Csh, 4
	LEN 14
	NOTE Csh, 4
	LEN 7
	NOTE Csh, 4
	ARP 5
	LEN 14
	NOTE C_, 4
	ARP 4
	NOTE Csh, 4
	LEN 7
	NOTE Csh, 4
	ARP 5
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE C_, 4
	ARP 4
	LEN 14
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 7
	NOTE Csh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	LEN 21
	NOTE Csh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	ARP 5
	NOTE F_, 4
	NOTE F_, 4
	ARP 4
	LEN 14
	NOTE Dsh, 4
	NEXT
Pat_4E47:
	HWENV $4E, $1C, $A7
	ARP 4
	LEN 42
	NOTE Csh, 4
	LENGTH $46
	NOTE Csh, 4
	ARP 5
	LEN 42
	NOTE Ash, 4
	NOTE Ash, 4
	ARP 4
	LEN 28
	NOTE Gsh, 4
	ARP 5
	LEN 42
	NOTE F_, 4
	LENGTH $46
	NOTE F_, 4
	LEN 42
	NOTE F_, 4
	NOTE F_, 4
	ARP 4
	LEN 28
	NOTE Dsh, 4
	NEXT
Pat_4E65:
	ARP 4
	LEN 42
	NOTE Csh, 4
	LENGTH $46
	NOTE Csh, 4
	ARP 5
	LEN 42
	NOTE Ash, 4
	NOTE Ash, 4
	ARP 4
	LEN 28
	NOTE Gsh, 4
	ARP 5
	LEN 42
	NOTE F_, 4
	LENGTH $46
	NOTE F_, 4
	LEN 42
	NOTE C_, 5
	NOTE C_, 4
	LEN 28
	NOTE F_, 3
	NEXT
DrumPat_4E7E:
	db DRUM_REPEAT + 3, 1, 6, 5, 6, 9, 0, 6
	db 5, 1, 6, 5, 6, 9, 0, 5
	db 4, DRUM_REPEAT_END, 1, 6, 5, 6, 9, 0
	db 6, 5, 1, 6, 5, 6, 9, 9
	db 9, 4, DRUM_LOOP

; Song 3: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong3:
	call StopAll
	ld de, Song3_Ch1
	call L48F0
	ld de, Song3_Ch2
	call L48FE
	ld de, Song3_Ch3
	jp L490C

; Unreferenced (1 bytes)
	db $C9
Song3_Ch1:
	dw Pat_4ED5
	dw Pat_4EEB
	dw Pat_4F08
	ORDER_LOOP Song3_Ch1
Song3_Ch2:
	dw Pat_4F44
	dw Pat_4F52
	dw Pat_4F6F
	ORDER_LOOP Song3_Ch2
Song3_Ch3:
	dw Pat_4FA3
	dw Pat_4FC0
	dw Pat_5025
	ORDER_LOOP Song3_Ch3
Pat_4ED5:
	HWENV $D1, $00
	AUTODUTY $0B
	ARP 0
	LEN 11
	REPEAT 8
	NOTE C_, 2
	NOTE C_, 2
	ARP 5
	NOTE C_, 4
	ARP 0
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	ARP 5
	NOTE C_, 4
	ARP 0
	NOTE C_, 2
	REPEAT_END
	NEXT
Pat_4EEB:
	REPEAT 4
	NOTE C_, 2
	NOTE C_, 2
	ARP 5
	NOTE C_, 4
	ARP 0
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	ARP 5
	NOTE C_, 4
	ARP 0
	NOTE C_, 2
	REPEAT_END
	REPEAT 4
	NOTE F_, 2
	NOTE F_, 2
	ARP 4
	NOTE F_, 4
	ARP 0
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	ARP 4
	NOTE F_, 4
	ARP 0
	NOTE F_, 2
	REPEAT_END
	NEXT
Pat_4F08:
	ARP 0
	LEN 11
	REPEAT 3
	NOTE G_, 2
	NOTE G_, 2
	ARP 5
	NOTE G_, 4
	ARP 0
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	ARP 5
	NOTE G_, 4
	ARP 0
	NOTE G_, 2
	REPEAT_END
	NOTE Ash, 2
	NOTE Ash, 2
	ARP 4
	NOTE Ash, 4
	ARP 0
	NOTE F_, 2
	NOTE F_, 2
	NOTE Dsh, 2
	ARP 4
	NOTE Ash, 4
	ARP 0
	NOTE C_, 2
	REPEAT 4
	NOTE C_, 2
	NOTE C_, 2
	ARP 5
	NOTE C_, 4
	ARP 0
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	ARP 5
	NOTE C_, 4
	ARP 0
	NOTE C_, 2
	REPEAT_END
	NEXT
Pat_4F33:
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE Dsh, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE Dsh, 4
	NOTE G_, 3
	NOTE C_, 3
	NOTE C_, 4
	NEXT
Pat_4F44:
	AUTOPAN $0B
	INSTR 9
	ARP_OFF
	DUTY_50
	AUTODUTY $16
	LEN 11
	REPEAT 4
	PAT_CALL Pat_4F33
	REPEAT_END
	NEXT
Pat_4F52:
	LEN 11
	CH_TRANSPOSE $0C
	REPEAT 2
	PAT_CALL Pat_4F33
	REPEAT_END
	CH_TRANSPOSE $00
	REPEAT 2
	NOTE F_, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE F_, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE F_, 5
	REPEAT_END
	NEXT
Pat_4F6F:
	LEN 11
	NOTE G_, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE G_, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE G_, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE G_, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE Ash, 4
	REPEAT 2
	NOTE C_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 4
	NOTE Ash, 4
	REPEAT_END
	NEXT
Pat_4FA3:
	DRUMS $0B, DrumPat_508E
	CH_TRANSPOSE $0C
	INSTR 10
	REPEAT 2
	LEN 33
	NOTE C_, 4
	LEN 22
	NOTE Ash, 3
	NOTE Ash, 3
	LENGTH $4D
	NOTE C_, 4
	LEN 11
	NOTE G_, 3
	NOTE Ash, 3
	LEN 33
	NOTE C_, 4
	LEN 22
	NOTE Ash, 3
	NOTE Ash, 3
	LENGTH $63
	NOTE C_, 4
	REPEAT_END
	NEXT
Pat_4FC0:
	DRUMS $0B, DrumPat_5092
	INSTR 10
	LEN 22
	NOTE C_, 5
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE Ash, 4
	LEN 11
	NOTE Ash, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	LEN 33
	NOTE C_, 5
	INSTR 1
	NOTE A_, 3
	LEN 11
	NOTE A_, 3
	INSTR 10
	NOTE G_, 4
	NOTE Ash, 4
	LEN 22
	NOTE C_, 5
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE Ash, 4
	LEN 11
	NOTE Ash, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE C_, 5
	LEN 11
	NOTE G_, 4
	INSTR 1
	LEN 33
	NOTE A_, 3
	LEN 22
	NOTE A_, 3
	LEN 11
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE C_, 5
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE Ash, 4
	LEN 11
	NOTE Ash, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	LEN 33
	NOTE C_, 5
	INSTR 1
	NOTE A_, 3
	LEN 11
	NOTE A_, 3
	INSTR 10
	NOTE G_, 4
	NOTE Ash, 4
	LEN 22
	NOTE C_, 5
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE C_, 5
	LEN 11
	NOTE Ash, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE Ash, 4
	LEN 11
	NOTE G_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE G_, 4
	INSTR 1
	NOTE A_, 3
	LEN 11
	NOTE A_, 3
	NEXT
Pat_5025:
	INSTR 10
	LEN 22
	NOTE C_, 5
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE Ash, 4
	LEN 11
	NOTE Ash, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	LEN 33
	NOTE C_, 5
	INSTR 1
	NOTE A_, 3
	LEN 11
	NOTE A_, 3
	INSTR 10
	NOTE G_, 4
	NOTE Ash, 4
	LEN 22
	NOTE C_, 5
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE C_, 5
	LEN 11
	NOTE Ash, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE C_, 5
	LEN 11
	NOTE Dsh, 5
	INSTR 1
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE F_, 5
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 10
	NOTE G_, 5
	INSTR 1
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE C_, 5
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE Ash, 4
	LEN 11
	NOTE Ash, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	LEN 33
	NOTE C_, 5
	INSTR 1
	NOTE A_, 3
	LEN 11
	NOTE A_, 3
	INSTR 10
	NOTE G_, 4
	NOTE Ash, 4
	LEN 22
	NOTE C_, 5
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE C_, 5
	LEN 11
	NOTE Ash, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE Ash, 4
	LEN 11
	NOTE G_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE Dsh, 4
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 10
	NOTE C_, 4
	INSTR 1
	NOTE A_, 3
	NEXT
DrumPat_508E:
	db DRUM_LEVEL + 14, 4, 0, DRUM_LOOP
DrumPat_5092:
	db DRUM_LEVEL + 14, 1, 6, 9, 4, 1, 6, 9
	db 5, 1, 6, 9, 1, 1, 9, 5
	db 1, 1, 6, 9, 4, 1, 6, 9
	db 5, 1, 6, 9, 1, 1, 9, 1
	db 9, DRUM_LOOP

; Song 4: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong4:
	call StopAll
	ld de, Song4_Ch1
	call L48F0
	ld de, Song4_Ch3
	call L490C
	ld de, Song4_Ch2
	jp L48FE
Song4_Ch1:
	dw Pat_50FF
Loop_50CB:
	dw Pat_516E
	dw Pat_51D9
	dw Pat_5244
	dw Pat_52AF
	dw Pat_531A
	dw Pat_5351
	ORDER_LOOP Loop_50CB
Song4_Ch3:
	dw Pat_5388
Loop_50DD:
	dw Pat_53A1
	dw Pat_53C6
	dw Pat_53EB
	dw Pat_5410
	dw Pat_5455
	dw Pat_5477
	ORDER_LOOP Loop_50DD
Song4_Ch2:
	dw Pat_549C
Loop_50EF:
	dw Pat_549C
	dw Pat_54D3
	dw Pat_5501
	dw Pat_552F
	dw Pat_5563
	dw Pat_557C
	ORDER_LOOP Loop_50EF
Pat_50FF:
	DRUMS $07, DrumPat_559D
	INSTR 12
	LEN 7
	NOTE C_, 2
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	NOTE Ash, 2
	INSTR 12
	NOTE C_, 2
	NOTE G_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE C_, 2
	INSTR 11
	NOTE Ash, 2
	INSTR 12
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	NOTE Ash, 2
	INSTR 12
	NOTE C_, 2
	NOTE G_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE C_, 2
	INSTR 11
	NOTE Ash, 2
	INSTR 12
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	NOTE Ash, 2
	INSTR 12
	NOTE C_, 2
	NOTE G_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE C_, 2
	INSTR 11
	NOTE Ash, 2
	INSTR 12
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	NOTE Ash, 2
	INSTR 12
	NOTE C_, 2
	NOTE G_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE C_, 2
	INSTR 11
	NOTE Ash, 2
	INSTR 12
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE G_, 2
	NEXT
Pat_516E:
	INSTR 12
	LEN 7
	NOTE C_, 2
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	NOTE Ash, 2
	INSTR 12
	NOTE C_, 2
	NOTE G_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE C_, 2
	INSTR 11
	NOTE Ash, 2
	INSTR 12
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	NOTE Ash, 2
	INSTR 12
	NOTE C_, 2
	NOTE G_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE C_, 2
	INSTR 11
	NOTE Ash, 2
	INSTR 12
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	NOTE Ash, 2
	INSTR 12
	NOTE C_, 2
	NOTE G_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE C_, 2
	INSTR 11
	NOTE Ash, 2
	INSTR 12
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	NOTE Ash, 2
	INSTR 12
	NOTE C_, 2
	NOTE G_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE C_, 2
	INSTR 11
	NOTE Ash, 2
	INSTR 12
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE G_, 2
	NEXT
Pat_51D9:
	INSTR 12
	LEN 7
	NOTE Dsh, 2
	NOTE Dsh, 2
	INSTR 11
	NOTE Dsh, 3
	NOTE Csh, 3
	INSTR 12
	NOTE Dsh, 2
	NOTE Ash, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE Ash, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE Dsh, 2
	INSTR 11
	NOTE Csh, 3
	INSTR 12
	NOTE Dsh, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE Ash, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	INSTR 11
	NOTE Dsh, 3
	NOTE Csh, 3
	INSTR 12
	NOTE Dsh, 2
	NOTE Ash, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE Ash, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE Dsh, 2
	INSTR 11
	NOTE Csh, 3
	INSTR 12
	NOTE Dsh, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE Ash, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	INSTR 11
	NOTE Dsh, 3
	NOTE Csh, 3
	INSTR 12
	NOTE Dsh, 2
	NOTE Ash, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE Ash, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE Dsh, 2
	INSTR 11
	NOTE Csh, 3
	INSTR 12
	NOTE Dsh, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE Ash, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	INSTR 11
	NOTE Dsh, 3
	NOTE Csh, 3
	INSTR 12
	NOTE Dsh, 2
	NOTE Ash, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE Ash, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE Dsh, 2
	INSTR 11
	NOTE Csh, 3
	INSTR 12
	NOTE Dsh, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE Ash, 2
	NEXT
Pat_5244:
	INSTR 12
	LEN 7
	NOTE F_, 2
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	NOTE Dsh, 3
	INSTR 12
	NOTE F_, 2
	NOTE C_, 3
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE F_, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	NOTE Dsh, 3
	INSTR 12
	NOTE F_, 2
	NOTE C_, 3
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE F_, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	NOTE Dsh, 3
	INSTR 12
	NOTE F_, 2
	NOTE C_, 3
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE F_, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	NOTE Dsh, 3
	INSTR 12
	NOTE F_, 2
	NOTE C_, 3
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE F_, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE C_, 3
	NEXT
Pat_52AF:
	INSTR 12
	LEN 7
	NOTE C_, 2
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	NOTE Ash, 2
	INSTR 12
	NOTE C_, 2
	NOTE G_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE C_, 2
	INSTR 11
	NOTE Ash, 2
	INSTR 12
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	NOTE Ash, 2
	INSTR 12
	NOTE C_, 2
	NOTE G_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE C_, 2
	INSTR 11
	NOTE Ash, 2
	INSTR 12
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	NOTE Ash, 2
	INSTR 12
	NOTE C_, 2
	NOTE G_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE C_, 2
	INSTR 11
	NOTE Ash, 2
	INSTR 12
	NOTE C_, 2
	INSTR 11
	NOTE C_, 3
	INSTR 12
	NOTE G_, 2
	NOTE F_, 2
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	NOTE Dsh, 3
	INSTR 12
	NOTE F_, 2
	NOTE C_, 3
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE F_, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE F_, 2
	NEXT
Pat_531A:
	INSTR 12
	LEN 7
	NOTE Dsh, 2
	NOTE Dsh, 2
	INSTR 11
	NOTE Dsh, 3
	NOTE Csh, 3
	INSTR 12
	NOTE Dsh, 2
	NOTE Ash, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE Ash, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE Dsh, 2
	INSTR 11
	NOTE Csh, 3
	INSTR 12
	NOTE Dsh, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE Ash, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	INSTR 11
	NOTE Dsh, 3
	NOTE Csh, 3
	INSTR 12
	NOTE Dsh, 2
	NOTE Ash, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE Ash, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE Dsh, 2
	INSTR 11
	NOTE Csh, 3
	INSTR 12
	NOTE Dsh, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE Ash, 2
	NEXT
Pat_5351:
	INSTR 12
	LEN 7
	NOTE F_, 2
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	NOTE Dsh, 3
	INSTR 12
	NOTE F_, 2
	NOTE C_, 3
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE F_, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	NOTE Dsh, 3
	INSTR 12
	NOTE F_, 2
	NOTE C_, 3
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE F_, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE C_, 3
	NEXT
Pat_5388:
	CH_TRANSPOSE $0C
	INSTR 2
	LEN 28
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	LEN 21
	NOTE F_, 3
	INSTR 1
	LEN 7
	NOTE F_, 3
	NEXT
Pat_53A1:
	INSTR 2
	LEN 28
	NOTE F_, 3
	INSTR 1
	NOTE F_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE F_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE F_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE F_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE F_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE F_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE F_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 1
	LEN 21
	NOTE F_, 3
	LEN 7
	NOTE F_, 3
	NEXT
Pat_53C6:
	INSTR 2
	LEN 28
	NOTE F_, 3
	INSTR 1
	NOTE F_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE F_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE F_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE F_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE F_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE F_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE F_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 1
	LEN 21
	NOTE F_, 3
	LEN 7
	NOTE F_, 3
	NEXT
Pat_53EB:
	INSTR 2
	LEN 28
	NOTE F_, 3
	INSTR 1
	NOTE F_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE F_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE F_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE F_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE F_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE F_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE F_, 3
	INSTR 2
	NOTE F_, 3
	INSTR 1
	LEN 21
	NOTE F_, 3
	LEN 7
	NOTE F_, 3
	NEXT
Pat_5410:
	INSTR 2
	LEN 14
	NOTE F_, 3
	INSTR 15
	NOTE C_, 4
	INSTR 1
	NOTE F_, 3
	INSTR 15
	NOTE C_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 15
	NOTE C_, 4
	INSTR 1
	NOTE F_, 3
	INSTR 15
	NOTE C_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 15
	NOTE C_, 4
	INSTR 1
	NOTE F_, 3
	INSTR 15
	NOTE C_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 15
	NOTE C_, 4
	INSTR 1
	NOTE F_, 3
	INSTR 15
	NOTE C_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 15
	NOTE C_, 4
	INSTR 1
	NOTE F_, 3
	INSTR 15
	NOTE C_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 15
	NOTE C_, 4
	INSTR 1
	NOTE F_, 3
	INSTR 15
	NOTE C_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 14
	NOTE F_, 4
	INSTR 1
	NOTE F_, 3
	INSTR 14
	NOTE F_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 14
	NOTE F_, 4
	INSTR 1
	NOTE F_, 3
	INSTR 14
	LEN 7
	NOTE F_, 4
	INSTR 1
	NOTE F_, 3
	NEXT
Pat_5455:
	INSTR 2
	LEN 14
	NOTE F_, 3
	INSTR 14
	NOTE Dsh, 4
	INSTR 1
	NOTE F_, 3
	INSTR 14
	NOTE Dsh, 4
	INSTR 2
	NOTE F_, 3
	INSTR 14
	NOTE Dsh, 4
	INSTR 1
	NOTE F_, 3
	INSTR 14
	NOTE Dsh, 4
	INSTR 2
	NOTE F_, 3
	INSTR 14
	NOTE Dsh, 4
	INSTR 1
	NOTE F_, 3
	INSTR 14
	NOTE Dsh, 4
	INSTR 2
	NOTE F_, 3
	INSTR 14
	NOTE Dsh, 4
	INSTR 1
	NOTE F_, 3
	INSTR 14
	NOTE Dsh, 4
	NEXT
Pat_5477:
	INSTR 2
	LEN 14
	NOTE F_, 3
	INSTR 14
	NOTE F_, 4
	INSTR 1
	NOTE F_, 3
	INSTR 14
	NOTE F_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 14
	NOTE F_, 4
	INSTR 1
	NOTE F_, 3
	INSTR 14
	NOTE F_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 14
	NOTE F_, 5
	INSTR 1
	NOTE F_, 3
	INSTR 14
	NOTE F_, 5
	INSTR 2
	NOTE F_, 3
	INSTR 14
	NOTE F_, 5
	INSTR 1
	NOTE F_, 3
	INSTR 14
	LEN 7
	NOTE F_, 5
	INSTR 1
	NOTE F_, 3
	NEXT
Pat_549C:
	ARP_OFF
	DUTY_50
	HWENV $D2, $00
	VIBRATO $00, $04, $05
	LEN 14
	NOTE C_, 2
	LEN 7
	NOTE C_, 3
	LEN 21
	NOTE Ash, 2
	LEN 14
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Ash, 2
	NOTE C_, 3
	NOTE C_, 2
	LEN 7
	NOTE C_, 3
	LEN 21
	NOTE Ash, 2
	LEN 14
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Ash, 2
	NOTE C_, 3
	NOTE C_, 2
	LEN 7
	NOTE C_, 3
	LEN 21
	NOTE Ash, 2
	LEN 14
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Ash, 2
	NOTE C_, 3
	NOTE C_, 2
	LEN 7
	NOTE C_, 3
	LEN 21
	NOTE Ash, 2
	LEN 14
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Ash, 2
	NOTE C_, 3
	NEXT
Pat_54D3:
	LEN 14
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 3
	LEN 21
	NOTE Csh, 3
	LEN 14
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Csh, 3
	NOTE Dsh, 3
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 3
	LEN 21
	NOTE Csh, 3
	LEN 14
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Csh, 3
	NOTE Dsh, 3
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 3
	LEN 21
	NOTE Csh, 3
	LEN 14
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Csh, 3
	NOTE Dsh, 3
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 3
	LEN 21
	NOTE Csh, 3
	LEN 14
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Csh, 3
	NOTE Dsh, 3
	NEXT
Pat_5501:
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	LEN 21
	NOTE Dsh, 3
	LEN 14
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	LEN 21
	NOTE Dsh, 3
	LEN 14
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	LEN 21
	NOTE Dsh, 3
	LEN 14
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	LEN 21
	NOTE Dsh, 3
	LEN 14
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE Dsh, 3
	NOTE F_, 3
	NEXT
Pat_552F:
	DUTY_75
	HWENV $A7, $00
	VIBRATO $0E, $03, $04
	RELEASE $01, $11
	AUTODUTY $0E
	LEN 42
	NOTE C_, 4
	LEN 7
	NOTE G_, 3
	NOTE C_, 4
	LEN 42
	NOTE Dsh, 4
	LEN 7
	NOTE C_, 4
	NOTE Dsh, 4
	LEN 21
	NOTE F_, 4
	NOTE G_, 4
	LEN 14
	NOTE Ash, 4
	LEN 42
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	NOTE Ash, 4
	LEN 28
	NOTE C_, 5
	NOTE G_, 4
	LEN 21
	NOTE Dsh, 5
	NOTE D_, 5
	LEN 14
	NOTE C_, 5
	LENGTH $46
	NOTE F_, 4
	LEN 7
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NEXT
Pat_5563:
	LEN 21
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE Ash, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE F_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Dsh, 5
	LEN 21
	NOTE C_, 5
	NOTE G_, 4
	NOTE Ash, 4
	LEN 7
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE Ash, 4
	NOTE C_, 5
	NEXT
Pat_557C:
	LEN 21
	NOTE F_, 5
	NOTE C_, 5
	NOTE A_, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	LEN 14
	NOTE F_, 5
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE Dsh, 5
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	LEN 7
	NOTE Ash, 4
	LEN 21
	NOTE C_, 5
	RELEASE $00
	AUTODUTY $00
	NEXT
DrumPat_559D:
	db DRUM_LEVEL + 12, 1, 6, 5, 6, 2, 6, 6
	db 6, DRUM_LOOP

; Song 5: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong5:
	call StopAll
	ld de, Song5_Ch3
	call L490C
	ld de, Song5_Ch2
	call L48FE
	ld de, Song5_Ch1
	jp L48F0
Song5_Ch3:
	dw Pat_55C2
Song5_Ch2:
	dw Pat_55EB
Song5_Ch1:
	dw Pat_561C
Pat_55C2:
	CH_TRANSPOSE $0C
	INSTR 19
	LEN 28
	NOTE C_, 2
	LEN 14
	NOTE C_, 2
	LEN 28
	NOTE C_, 2
	LEN 14
	NOTE C_, 2
	LEN 28
	NOTE C_, 2
	NOTE Dsh, 2
	LEN 14
	NOTE Dsh, 2
	LEN 28
	NOTE Dsh, 2
	LEN 14
	NOTE Dsh, 2
	LEN 28
	NOTE Dsh, 2
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	LEN 28
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	LEN 28
	NOTE F_, 2
	LEN 21
	NOTE C_, 3
	NOTE C_, 3
	LEN 7
	NOTE C_, 3
	NOTE C_, 3
	LENGTH $38
	NOTE C_, 3
	END
Pat_55EB:
	HWENV $C0, $15, $C5
	DUTY_50
	VIBRATO $0E, $03, $04
	RELEASE $01, $11
	LEN 21
	ARP 3
	NOTE Ash, 4
	ARP_OFF
	NOTE G_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE C_, 5
	LEN 21
	NOTE Ash, 4
	NOTE G_, 4
	LEN 28
	NOTE Dsh, 5
	LEN 14
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Dsh, 4
	LEN 7
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	LENGTH $31
	NOTE C_, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	LENGTH $77
	NOTE C_, 4
	END
Pat_561C:
	DRUMS $07, DrumPat_5651
	HWENV $A3, $00
	DUTY_12
	ARP 6
	AUTOPAN $07
	LEN 7
	REPEAT 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE G_, 3
	REPEAT_END
	REPEAT 4
	NOTE Ash, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE G_, 3
	REPEAT_END
	REPEAT 3
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE F_, 3
	REPEAT_END
	NOTE Dsh, 3
	NOTE D_, 3
	NOTE Dsh, 3
	NOTE Ash, 2
	NOTE C_, 3
	NOTE Dsh, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	LENGTH $38
	DRUMS_OFF
	CALL_CODE Drum7
	AUTOPAN $00
	PAN_C
	NOTE C_, 5
	END
DrumPat_5651:
	db 9, 0, 10, 10, 9, 0, 9, 0
	db 10, 10, 9, 0, 9, 10, 10, 10
	db DRUM_LOOP

; Song 6: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong6:
	call StopAll
	ld de, Song6_Ch1
	call L48F0
	ld de, Song6_Ch3
	call L490C
	ld de, Song6_Ch2
	jp L48FE

; Unreferenced (1 bytes)
	db $C9
Song6_Ch1:
	dw Pat_56FD
Loop_567A:
	dw Pat_5703
	dw Pat_5703
	dw Pat_5734
	dw Pat_57A6
	dw Pat_57A6
	dw Pat_57A6
	dw Pat_5798
	dw Pat_5798
	dw Pat_57A6
	dw Pat_57A6
	dw Pat_5798
	dw Pat_5798
	dw Pat_57CC
	dw Pat_57A2
	dw Pat_57A2
	dw Pat_57A6
	dw Pat_57A6
	ORDER_LOOP Loop_567A
Song6_Ch3:
	dw Pat_57FD
Loop_56A2:
	dw Pat_5829
	dw Pat_5829
	dw Pat_584A
	dw Pat_5808
	dw Pat_5869
	dw Pat_5869
	dw Pat_5875
	dw Pat_5875
	dw Pat_5869
	dw Pat_5869
	dw Pat_5875
	dw Pat_5875
	dw Pat_588A
	dw Pat_5829
	dw Pat_5829
	dw Pat_5869
	dw Pat_5869
	ORDER_LOOP Loop_56A2
Song6_Ch2:
	dw Pat_58A8
Loop_56CA:
	dw Pat_58B4
	dw Pat_58B4
	dw Pat_590D
	dw Pat_58B4
	dw Pat_594F
	dw Pat_594F
	dw Pat_5978
	dw Pat_59AF
	dw Pat_56F2
	dw Pat_594F
	dw Pat_594F
	dw Pat_5978
	dw Pat_59AF
	dw Pat_59F8
	dw Pat_59E4
	dw Pat_59EC
	dw Pat_56F5
	dw Pat_56F5
	ORDER_LOOP Loop_56CA
Pat_56F2:
	AUTODUTY $07
	NEXT
Pat_56F5:
	DRUMS $07, DrumPat_5A30
	INSTR 6
	PAT_GOTO Pat_57A6
Pat_56FD:
	AUTODUTY $07
	ARP 6
	RELEASE $01, $01
Pat_5703:
	HWENV $D1, $00
	AUTOPAN $00
	DRUMS $07, DrumPat_5A2A
	LEN 21
	NOTE F_, 2
	NOTE F_, 2
	LEN 28
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	NOTE F_, 2
	NOTE Dsh, 2
	LEN 21
	NOTE F_, 2
	NOTE F_, 2
	LEN 28
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	NOTE F_, 2
	NOTE Dsh, 2
	LEN 21
	NOTE F_, 2
	NOTE F_, 2
	LEN 28
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	NOTE F_, 2
	NOTE Dsh, 2
	LEN 21
	NOTE F_, 2
	NOTE F_, 2
	LEN 28
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	NOTE Gsh, 2
	NOTE Ash, 2
	NOTE C_, 3
	NEXT
Pat_5734:
	DRUMS $07, DrumPat_5A30
	LEN 21
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 2
	LEN 14
	NOTE Dsh, 3
	NOTE Dsh, 2
	LEN 7
	NOTE Csh, 3
	NOTE Dsh, 3
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Csh, 2
	LEN 21
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 2
	LEN 14
	NOTE Dsh, 3
	NOTE Dsh, 2
	LEN 7
	NOTE Gsh, 2
	NOTE Ash, 2
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Csh, 2
	LEN 21
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 2
	LEN 14
	NOTE Dsh, 3
	NOTE Dsh, 2
	LEN 7
	NOTE Csh, 3
	NOTE Dsh, 3
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Csh, 2
	LEN 21
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 2
	LEN 14
	NOTE Dsh, 3
	NOTE Dsh, 2
	LEN 7
	NOTE Gsh, 2
	NOTE Ash, 2
	LEN 14
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 2
	NOTE Fsh, 2
	NOTE Gsh, 2
	NOTE Ash, 2
	NEXT
Pat_5774:
	LEN 7
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 2
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE F_, 2
	NOTE F_, 2
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 2
	NOTE Ash, 2
	NOTE C_, 3
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 2
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE F_, 2
	NOTE F_, 2
	NOTE Ash, 2
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 2
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE F_, 2
	NOTE Fsh, 3
	NEXT
Pat_5798:
	CH_TRANSPOSE $FE
	PAT_CALL Pat_57A9
	CH_TRANSPOSE $00
	PAT_GOTO Pat_57A9
Pat_57A2:
	DRUMS $07, DrumPat_5A2A
Pat_57A6:
	PAT_CALL Pat_5774
Pat_57A9:
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 2
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE F_, 2
	NOTE F_, 2
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 2
	NOTE Ash, 2
	NOTE C_, 3
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 2
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE F_, 2
	NOTE F_, 2
	NOTE Ash, 2
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 2
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE Ash, 2
	NOTE C_, 3
	NEXT
Pat_57CC:
	CH_TRANSPOSE $FC
	PAT_CALL Pat_5774
	CH_TRANSPOSE $00
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 2
	LEN 14
	NOTE Dsh, 3
	LEN 7
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Csh, 3
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Gsh, 2
	NOTE Ash, 2
	NOTE Csh, 3
	NOTE Ash, 2
	DRUMS_OFF
	HWENV $D4, $00
	LEN 21
	CALL_CODE Drum7
	NOTE Dsh, 3
	CALL_CODE Drum7
	NOTE Ash, 2
	CALL_CODE Drum7
	LEN 14
	NOTE G_, 2
	LENGTH $38
	CALL_CODE Drum7
	NOTE Dsh, 2
	NEXT
Pat_57FD:
	CH_TRANSPOSE $0C
	AUTOPAN $00
	INSTR 2
	LEN 28
	REPEAT 8
	NOTE A_, 3
	NOTE A_, 3
	REPEAT_END
	NEXT
Pat_5808:
	AUTOPAN $0E
	REPEAT 4
	INSTR 2
	LEN 14
	NOTE A_, 3
	INSTR 17
	LEN 7
	NOTE F_, 3
	NOTE Gsh, 3
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 17
	LEN 7
	NOTE F_, 3
	NOTE Ash, 3
	INSTR 2
	LEN 14
	NOTE A_, 3
	INSTR 17
	LEN 7
	NOTE F_, 3
	NOTE C_, 4
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 17
	LEN 7
	NOTE F_, 3
	NOTE Dsh, 4
	REPEAT_END
	NEXT
Pat_5829:
	AUTOPAN $0E
	REPEAT 4
	INSTR 2
	LEN 14
	NOTE A_, 3
	INSTR 17
	LEN 7
	NOTE F_, 3
	NOTE Gsh, 3
	INSTR 2
	LEN 14
	NOTE A_, 3
	INSTR 17
	LEN 7
	NOTE F_, 3
	NOTE Ash, 3
	INSTR 2
	LEN 14
	NOTE A_, 3
	INSTR 17
	LEN 7
	NOTE F_, 3
	NOTE C_, 4
	INSTR 2
	LEN 14
	NOTE A_, 3
	INSTR 17
	LEN 7
	NOTE F_, 3
	NOTE Dsh, 4
	REPEAT_END
	NEXT
Pat_584A:
	REPEAT 4
	INSTR 2
	LEN 14
	NOTE A_, 3
	INSTR 17
	LEN 7
	NOTE Dsh, 3
	NOTE Fsh, 3
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 17
	LEN 7
	NOTE Dsh, 3
	NOTE Gsh, 3
	INSTR 2
	LEN 14
	NOTE A_, 3
	INSTR 17
	LEN 7
	NOTE Dsh, 3
	NOTE Ash, 3
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 17
	LEN 7
	NOTE Dsh, 3
	NOTE Csh, 4
	REPEAT_END
	NEXT
Pat_5869:
	LEN 14
	REPEAT 8
	INSTR 2
	NOTE A_, 3
	INSTR 15
	NOTE F_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE F_, 4
	REPEAT_END
	NEXT
Pat_5875:
	REPEAT 4
	INSTR 2
	NOTE A_, 3
	INSTR 14
	NOTE Dsh, 4
	INSTR 1
	NOTE A_, 3
	INSTR 14
	NOTE Dsh, 4
	REPEAT_END
	REPEAT 4
	INSTR 2
	NOTE A_, 3
	INSTR 15
	NOTE F_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE F_, 4
	REPEAT_END
	NEXT
Pat_588A:
	REPEAT 4
	INSTR 2
	NOTE A_, 3
	INSTR 14
	NOTE Csh, 4
	INSTR 1
	NOTE A_, 3
	INSTR 14
	NOTE Csh, 4
	REPEAT_END
	REPEAT 2
	INSTR 2
	NOTE A_, 3
	INSTR 14
	NOTE Dsh, 4
	INSTR 1
	NOTE A_, 3
	INSTR 14
	NOTE Dsh, 4
	REPEAT_END
	INSTR 2
	LEN 21
	NOTE A_, 3
	NOTE A_, 3
	LEN 14
	NOTE A_, 3
	LENGTH $38
	NOTE A_, 3
	NEXT
Pat_58A8:
	HWENV $00, $00
	VIBRATO $0E, $02, $04
	LENGTH $E0
	WAIT
	WAIT
	NEXT
Pat_58B4:
	INSTR 7
	GLIDE $FE
	LEN 7
	ARP 4
	NOTE A_, 5
	GLIDE_OFF
	ARP 27
	RELEASE $01, $01
	HWENV $B1, $0E, $91
	DUTY_50
	ARP 27
	LEN 7
	NOTE C_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 14
	NOTE G_, 4
	NOTE C_, 4
	LEN 7
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 28
	NOTE G_, 4
	LEN 21
	NOTE C_, 4
	LEN 7
	NOTE C_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 14
	NOTE G_, 4
	NOTE C_, 4
	LEN 7
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 28
	NOTE G_, 4
	LEN 14
	NOTE F_, 4
	GLIDE $FE
	LEN 7
	ARP 4
	NOTE A_, 5
	GLIDE_OFF
	ARP 27
	LEN 7
	NOTE C_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 14
	NOTE G_, 4
	NOTE C_, 4
	LEN 7
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 28
	NOTE G_, 4
	LEN 21
	NOTE C_, 4
	LEN 7
	NOTE C_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 14
	NOTE G_, 4
	NOTE C_, 4
	LEN 7
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 14
	NOTE G_, 4
	NOTE Dsh, 4
	LEN 7
	GLIDE $FE
	LEN 7
	ARP 4
	NOTE A_, 5
	GLIDE_OFF
	ARP 27
	NOTE F_, 4
	NEXT
Pat_590D:
	CH_TRANSPOSE $FE
	PAT_CALL Pat_58B4
	CH_TRANSPOSE $00
	NEXT

; Unreferenced (58 bytes)
	db $CD, $65, $22, $29, $2A, $D4, $29, $22, $CD, $29, $2A, $E2, $29, $DB, $22, $CD
	db $22, $29, $2A, $D4, $29, $22, $CD, $29, $2A, $E2, $29, $DB, $27, $CD, $22, $29
	db $2A, $D4, $29, $22, $CD, $29, $2A, $E2, $29, $DB, $22, $CD, $22, $29, $2A, $D4
	db $29, $22, $CD, $29, $2A, $D4, $29, $25, $27, $6A
Pat_594F:
	INSTR 6
	LEN 21
	NOTE F_, 5
	NOTE F_, 5
	LEN 14
	NOTE F_, 5
	LEN 21
	NOTE Dsh, 5
	NOTE Dsh, 5
	LEN 14
	NOTE Dsh, 5
	LEN 21
	NOTE D_, 5
	NOTE Dsh, 5
	LEN 14
	NOTE F_, 5
	LEN 42
	NOTE C_, 5
	LEN 7
	NOTE C_, 5
	NOTE Ash, 4
	LEN 21
	NOTE Gsh, 4
	NOTE Ash, 4
	LEN 14
	NOTE C_, 5
	LEN 28
	NOTE Ash, 4
	LEN 14
	NOTE C_, 4
	NOTE Dsh, 4
	LEN 21
	NOTE G_, 4
	NOTE Ash, 4
	LEN 14
	NOTE Gsh, 4
	LEN 42
	NOTE F_, 4
	LEN 14
	NOTE C_, 5
	NEXT
Pat_5978:
	LEN 21
	NOTE Ash, 4
	NOTE C_, 5
	LENGTH $46
	NOTE G_, 4
	INSTR 7
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE F_, 4
	NOTE F_, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	INSTR 6
	NOTE C_, 4
	NOTE Dsh, 4
	LEN 21
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 14
	NOTE Gsh, 4
	LEN 42
	NOTE F_, 4
	INSTR 7
	LEN 7
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	INSTR 6
	LEN 14
	NOTE C_, 5
	NEXT
Pat_59AF:
	INSTR 6
	LEN 21
	NOTE Ash, 4
	NOTE C_, 5
	LENGTH $46
	NOTE G_, 4
	INSTR 7
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE F_, 4
	NOTE F_, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	INSTR 6
	NOTE C_, 4
	NOTE Dsh, 4
	LEN 21
	NOTE G_, 4
	NOTE Ash, 4
	LEN 14
	NOTE Gsh, 4
	LENGTH $38
	NOTE F_, 4
	INSTR 5
	DUTY_50
	LEN 21
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	ARP 4
	LEN 14
	NOTE Dsh, 4
	ARP 5
	LEN 7
	NOTE F_, 4
	NOTE F_, 4
	LEN 42
	NOTE F_, 4
	NEXT
Pat_59E4:
	INSTR 9
	PAT_CALL Pat_5774
	PAT_CALL Pat_57A9
	NEXT
Pat_59EC:
	LEN 7
	CH_TRANSPOSE $07
	PAT_CALL Pat_5774
	PAT_CALL Pat_57A9
	CH_TRANSPOSE $00
	NEXT
Pat_59F8:
	INSTR 6
	LEN 21
	NOTE Csh, 5
	NOTE Gsh, 4
	LENGTH $46
	NOTE F_, 5
	INSTR 7
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE F_, 4
	NOTE F_, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE Dsh, 4
	INSTR 6
	LEN 7
	NOTE F_, 5
	NOTE G_, 5
	LEN 21
	NOTE Gsh, 5
	NOTE G_, 5
	LEN 14
	NOTE Dsh, 5
	LENGTH $38
	NOTE Ash, 5
	INSTR 4
	DUTY_50
	LEN 21
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LENGTH $38
	NOTE Dsh, 4
	AUTODUTY $00
	NEXT
DrumPat_5A2A:
	db DRUM_LEVEL + 13, 1, 0, 6, 0, DRUM_LOOP
DrumPat_5A30:
	db DRUM_LEVEL + 13, 1, 6, 5, 6, 9, 6, 5
	db 6, 1, 6, 5, 6, 9, 6, 5
	db 6, 1, 6, 5, 6, 9, 6, 5
	db 6, 1, 6, 5, 6, 9, 6, DRUM_LEVEL + 14
	db 4, 0, DRUM_LOOP

; Song 7: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong7:
	call StopAll
	ld de, Song7_Ch1
	call L48F0
	ld de, Song7_Ch3
	call L490C
	ld de, Song7_Ch2
	jp L48FE
Song7_Ch1:
	dw Pat_5AC2
	dw Pat_5AC2
	dw Pat_5AF1
	dw Pat_5AC2
	dw Pat_5AC2
	dw Pat_5B6A
	dw Pat_5B7E
	dw Pat_5AC2
	dw Pat_5AC2
	dw Pat_5B6A
	dw Pat_5B7E
	dw Pat_5AF1
	dw Pat_5AF1
	ORDER_LOOP Song7_Ch1
Song7_Ch3:
	dw Pat_5BAA
	dw Pat_5BAA
	dw Pat_5BBD
	dw Pat_5BAA
	dw Pat_5BAA
	dw Pat_5BAA
	dw Pat_5BAA
	dw Pat_5BAA
	dw Pat_5BAA
	dw Pat_5BAA
	dw Pat_5BAA
	dw Pat_5BBD
	dw Pat_5BBD
	ORDER_LOOP Song7_Ch3
Song7_Ch2:
	dw Pat_5BE8
	dw Pat_5BE8
	dw Pat_5C06
	dw Pat_5C32
	dw Pat_5C32
	dw Pat_5C5D
	dw Pat_5C73
	dw Pat_5C32
	dw Pat_5C32
	dw Pat_5C5D
	dw Pat_5C73
	dw Pat_5C06
	dw Pat_5C06
	ORDER_LOOP Song7_Ch2
Pat_5AC2:
	TRANSPOSE $02
	ARP 6
	LEN 16
	HWENV $F1, $08, $53
	DUTY_75
	RELEASE $01, $01
	REPEAT 2
	NOTE D_, 2
	NOTE D_, 2
	ARP 5
	NOTE D_, 4
	ARP 6
	NOTE C_, 2
	LEN 8
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	ARP 5
	LEN 16
	NOTE D_, 4
	ARP 6
	NOTE C_, 2
	NOTE D_, 2
	NOTE D_, 2
	ARP 5
	NOTE D_, 4
	ARP 6
	NOTE C_, 2
	LEN 8
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	ARP 5
	LEN 16
	NOTE D_, 4
	ARP 6
	NOTE F_, 2
	REPEAT_END
	NEXT
Pat_5AF1:
	ARP 6
	LEN 24
	NOTE D_, 2
	LEN 8
	NOTE D_, 2
	NOTE C_, 3
	NOTE D_, 3
	LEN 16
	NOTE D_, 2
	LEN 24
	NOTE D_, 2
	LEN 8
	NOTE D_, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	LEN 24
	NOTE D_, 2
	LEN 8
	NOTE D_, 2
	NOTE C_, 3
	NOTE D_, 3
	LEN 16
	NOTE D_, 2
	LEN 8
	NOTE D_, 2
	LEN 16
	NOTE D_, 2
	LEN 8
	NOTE D_, 2
	LEN 16
	NOTE D_, 2
	NOTE D_, 2
	LEN 24
	NOTE D_, 2
	LEN 8
	NOTE D_, 2
	NOTE C_, 3
	NOTE D_, 3
	LEN 16
	NOTE D_, 2
	LEN 24
	NOTE D_, 2
	LEN 8
	NOTE D_, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	LEN 24
	NOTE D_, 2
	LEN 8
	NOTE D_, 2
	NOTE C_, 3
	NOTE D_, 3
	LEN 16
	NOTE D_, 2
	LEN 8
	NOTE D_, 2
	LEN 16
	NOTE A_, 2
	LEN 8
	NOTE D_, 2
	LEN 16
	NOTE C_, 3
	LEN 8
	NOTE D_, 2
	NOTE D_, 3
	NEXT
Pat_5B37:
	ARP 6
	LEN 16
	NOTE G_, 2
	NOTE G_, 2
	ARP 4
	NOTE G_, 4
	ARP 6
	NOTE F_, 2
	LEN 8
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	ARP 4
	LEN 16
	NOTE G_, 4
	ARP 6
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 2
	ARP 4
	NOTE G_, 4
	ARP 6
	NOTE F_, 2
	LEN 8
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	ARP 4
	LEN 16
	NOTE G_, 4
	ARP 6
	NOTE C_, 2
	NOTE D_, 2
	NOTE D_, 2
	ARP 5
	NOTE D_, 4
	ARP 6
	NOTE C_, 2
	LEN 8
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	ARP 5
	LEN 16
	NOTE D_, 4
	ARP 6
	NOTE C_, 2
	NEXT
Pat_5B6A:
	PAT_CALL Pat_5B37
	NOTE D_, 2
	NOTE D_, 2
	ARP 5
	NOTE D_, 4
	ARP 6
	NOTE C_, 2
	LEN 8
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	ARP 5
	LEN 16
	NOTE D_, 4
	ARP 6
	NOTE F_, 2
	NEXT
Pat_5B7E:
	PAT_CALL Pat_5B37
	NOTE A_, 2
	NOTE A_, 2
	ARP 4
	NOTE A_, 4
	ARP 6
	NOTE G_, 2
	LEN 8
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	ARP 4
	LEN 16
	NOTE A_, 4
	ARP 6
	NOTE G_, 2
	NEXT
Pat_5B92:
	REPEAT 3
	LEN 24
	NOTE A_, 3
	LEN 8
	NOTE A_, 3
	INSTR 1
	LEN 16
	NOTE A_, 3
	INSTR 2
	NOTE A_, 3
	REPEAT_END
	LEN 8
	NOTE A_, 3
	INSTR 1
	LEN 16
	NOTE A_, 3
	INSTR 2
	LEN 8
	NOTE A_, 3
	INSTR 1
	LEN 16
	NOTE A_, 3
	INSTR 2
	NEXT
Pat_5BAA:
	CH_TRANSPOSE $0C
	DRUMS $08, DrumPat_5C99
	INSTR 2
	PAT_CALL Pat_5B92
	NOTE A_, 3
	PAT_CALL Pat_5B92
	LEN 8
	NOTE A_, 3
	INSTR 1
	NOTE A_, 3
	NEXT
Pat_5BBD:
	DRUMS $08, DrumPat_5CBF
	INSTR 2
	REPEAT 3
	LEN 24
	NOTE A_, 3
	NOTE A_, 3
	LEN 16
	NOTE A_, 3
	REPEAT_END
	LEN 24
	NOTE A_, 3
	LEN 8
	NOTE A_, 3
	INSTR 1
	LEN 16
	NOTE A_, 3
	INSTR 2
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	REPEAT 3
	LEN 24
	NOTE A_, 3
	NOTE A_, 3
	LEN 16
	NOTE A_, 3
	REPEAT_END
	LEN 8
	NOTE A_, 3
	INSTR 1
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	INSTR 2
	NOTE A_, 3
	INSTR 1
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NEXT
Pat_5BE8:
	HWENV $C7, $00
	DUTY_12
	VIBRATO $10, $02, $04
	ARP 25
	LENGTH $70
	NOTE D_, 3
	LEN 16
	NOTE C_, 3
	LENGTH $70
	NOTE D_, 3
	LEN 16
	NOTE F_, 3
	LENGTH $70
	NOTE D_, 3
	LEN 32
	NOTE C_, 3
	LEN 16
	NOTE D_, 3
	LENGTH $60
	NOTE D_, 3
	NEXT
Pat_5C06:
	ARP_OFF
	DUTY_50
	HWENV $C2, $00
	GLIDE $FF
	LEN 16
	NOTE A_, 3
	GLIDE_OFF
	DUTY_75
	ARP 5
	LEN 32
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	ARP 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE Ash, 3
	NOTE Ash, 3
	LEN 16
	NOTE Ash, 3
	ARP_OFF
	DUTY_50
	GLIDE $FF
	LEN 16
	NOTE A_, 3
	GLIDE_OFF
	DUTY_75
	ARP 5
	LEN 32
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	ARP 4
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE C_, 4
	LEN 16
	NOTE C_, 4
	NEXT
Pat_5C32:
	HWENV $B7, $00
	DUTY_75
	ARP_OFF
	LEN 32
	NOTE A_, 4
	LEN 16
	NOTE G_, 4
	NOTE A_, 4
	LENGTH $30
	NOTE C_, 5
	LEN 16
	NOTE G_, 4
	LEN 32
	NOTE A_, 4
	LEN 16
	NOTE G_, 4
	NOTE A_, 4
	LENGTH $40
	NOTE D_, 5
	LEN 16
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE C_, 5
	LEN 32
	NOTE D_, 5
	LEN 16
	NOTE A_, 4
	NOTE D_, 4
	LEN 32
	NOTE C_, 5
	LEN 16
	NOTE G_, 4
	NOTE C_, 4
	NEXT
Pat_5C5D:
	LENGTH $80
	NOTE D_, 4
	LEN 32
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE D_, 5
	LENGTH $80
	NOTE D_, 4
	LEN 16
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 32
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	NOTE C_, 4
	NEXT
Pat_5C73:
	LENGTH $40
	NOTE D_, 4
	NOTE A_, 4
	LEN 32
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	LEN 32
	NOTE D_, 5
	LENGTH $50
	NOTE D_, 4
	LEN 16
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	LENGTH $48
	NOTE A_, 4
	ARP 6
	HWENV $D1, $00
	GLIDE $FF
	DUTY_50
	LEN 8
	NOTE B_, 3
	NOTE B_, 3
	LEN 16
	NOTE B_, 3
	LEN 8
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	GLIDE_OFF
	NEXT
DrumPat_5C99:
	db DRUM_LEVEL + 14, DRUM_REPEAT + 3, 1, 6, 6, 1, 9, 6
	db 1, 6, DRUM_REPEAT_END, 1, 9, 6, 1, 9
	db 6, 1, 6, DRUM_REPEAT + 3, 1, 6, 6, 1
	db 9, 6, 1, 6, DRUM_REPEAT_END, 1, 9, 6
	db 1, 9, 6, 1, 9, DRUM_LOOP
DrumPat_5CBF:
	db DRUM_LEVEL + 14, DRUM_REPEAT + 3, 1, 6, 6, 1, 6, 6
	db 1, 6, DRUM_REPEAT_END, 1, 6, 6, 1, 9
	db 6, 1, 1, DRUM_REPEAT + 3, 1, 6, 6, 1
	db 6, 6, 1, 6, DRUM_REPEAT_END, 1, 9, 9
	db 9, 1, 9, 9, 9, DRUM_LOOP

; Song 8: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong8:
	call StopAll
	ld de, Song8_Ch1
	call L48F0
	ld de, Song8_Ch2
	call L48FE
	ld de, Song8_Ch3
	call L490C
	ret
Song8_Ch1:
	dw Pat_5D3D
	dw Pat_5D89
	dw Pat_5D89
	dw Pat_5E3D
	dw Pat_5E3D
	dw Pat_5DA3
	dw Pat_5DA3
	dw Pat_5E3D
	dw Pat_5E3D
	ORDER_LOOP Song8_Ch1
Song8_Ch2:
	dw Pat_5D56
	dw Pat_5DC4
	dw Pat_5DC4
	dw Pat_5E84
	dw Pat_5E84
	dw Pat_5DE5
	dw Pat_5DE5
	dw Pat_5E84
	dw Pat_5E84
	ORDER_LOOP Song8_Ch2
Song8_Ch3:
	dw Pat_5D6A
	dw Pat_5DF1
	dw Pat_5DF1
	dw Pat_5ED0
	dw Pat_5F1E
	dw Pat_5E33
	dw Pat_5E33
	dw Pat_5ED0
	dw Pat_5F1E
	ORDER_LOOP Song8_Ch3
Pat_5D3D:
	LENGTH $24
	DUTY_75
	ARP 6
	HWENV $D2, $12, $B1
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 3
	NEXT
Pat_5D56:
	PAN_R
	LEN 18
	HWENV $D1, $00
	AUTODUTY $00
	DUTY_12
	ARP 24
	REPEAT 4
	NOTE A_, 2
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	REPEAT_END
	NEXT
Pat_5D6A:
	DRUMS $09, DrumPat_5F24
	WAVE Wave_7D6F
	RELEASE $00
	PAN_L
	LENGTH $48
	VOLENV 15, $11, $1B, $16
	CH_TRANSPOSE $0C
	VIBRATO $00, $04, $05
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NEXT
Pat_5D89:
	LEN 36
	HWENV $D2, $12, $B1
	VIBRATO $09, $04, $04
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NEXT
Pat_5DA3:
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE E_, 2
	NOTE E_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NEXT
Pat_5DC4:
	REPEAT 2
	PAN_R
	NOTE A_, 2
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	PAN_L
	NOTE A_, 3
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	REPEAT_END
	PAN_R
	NOTE C_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	PAN_L
	NOTE C_, 4
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	PAN_R
	NOTE D_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	PAN_L
	NOTE D_, 4
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	NEXT
Pat_5DE5:
	CH_TRANSPOSE $0C
	AUTOPAN $03
	PAT_CALL Pat_5DC4
	CH_TRANSPOSE $00
	AUTOPAN $00
	NEXT
Pat_5DF1:
	PAN_C
	LEN 18
	VOLENV 15, $16, $14, $18
	RELEASE $32, $88
	CH_TRANSPOSE $0C
	VIBRATO $1E, $01, $04
	WAVE Wave_7CDF
	DRUMS $09, DrumPat_5F24
Pat_5E07:
	NOTE A_, 3
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	VIBRATO $16, $01, $01
	NOTE A_, 4
	WAIT
	VIBRATO $1E, $01, $04
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE D_, 5
	WAIT
	WAIT
	NOTE G_, 4
	NOTE G_, 4
	WAIT
	LEN 4
	NOTE A_, 4
	LEN 32
	NOTE B_, 4
	LEN 18
	NEXT
Pat_5E33:
	WAVE Wave_7DBF
	VIBRATO $1E, $01, $04
	PAT_GOTO Pat_5E07
Pat_5E3D:
	LEN 18
	ARP 24
	HWENV $D2, $09, $D1
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE Fsh, 2
	NOTE Fsh, 3
	NOTE Fsh, 2
	NOTE Fsh, 3
	NOTE Fsh, 2
	NOTE Fsh, 3
	NOTE Fsh, 2
	NOTE Fsh, 3
	NEXT
Pat_5E84:
	HWENV $D1, $09, $82
	AUTODUTY $02
	ARP 24
	AUTOPAN $03
	NOTE D_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE Csh, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE Csh, 5
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE A_, 4
	AUTOPAN $00
	NEXT
Pat_5ED0:
	PAN_C
	VIBRATO $1E, $02, $06
	LEN 18
	WAVE Wave_7D6F
	DRUMS $09, DrumPat_5F2A
Pat_5EDD:
	NOTE D_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE Csh, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE D_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE Gsh, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE Csh, 4
	WAIT
	WAIT
	NOTE A_, 3
	NOTE Fsh, 3
	WAIT
	WAIT
	WAIT
	NEXT
Pat_5F1E:
	WAVE Wave_7D5F
	PAT_GOTO Pat_5EDD
DrumPat_5F24:
	db DRUM_PAN_C, 1, 0, 6, 0, DRUM_LOOP
DrumPat_5F2A:
	db DRUM_PAN_C, 1, 0, DRUM_PAN_R, 6, 6, DRUM_PAN_C, 9
	db 0, DRUM_PAN_L, 6, 6, DRUM_PAN_C, 1, 6, DRUM_PAN_R
	db 6, 6, DRUM_PAN_C, 9, 0, DRUM_PAN_L, 6, 6
	db DRUM_LOOP

; Song 9: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong9:
	call StopAll
	ld de, Song9_Ch1
	call L48F0
	ld de, Song9_Ch3
	call L490C
	ld de, Song9_Ch2
	jp L48FE
Song9_Ch1:
	dw Pat_5FA6
	dw Pat_5FA6
	dw Pat_5FD0
	dw Pat_5FD0
	dw Pat_5FD0
	dw Pat_5FF7
	dw Pat_604A
	dw Pat_601C
	dw Pat_601C
	dw Pat_601C
	dw Pat_601C
	ORDER_LOOP Song9_Ch1
Song9_Ch3:
	dw Pat_6071
	dw Pat_6071
	dw Pat_60B4
	dw Pat_60B4
	dw Pat_60B4
	dw Pat_60D0
	dw Pat_616A
	dw Pat_610B
	dw Pat_610B
	dw Pat_610B
	dw Pat_610B
	ORDER_LOOP Song9_Ch3
Song9_Ch2:
	dw Pat_61A3
	dw Pat_61A3
	dw Pat_61DD
	dw Pat_61DD
	dw Pat_61F4
	dw Pat_621E
	dw Pat_6254
	dw Pat_6236
	dw Pat_6236
	dw Pat_6268
	dw Pat_6268
	ORDER_LOOP Song9_Ch2
Pat_5FA6:
	HWENV $F1, $08, $44
	DUTY_75
	ARP 6
	LEN 8
	REPEAT 3
	NOTE C_, 2
	LEN 16
	NOTE C_, 3
	NOTE C_, 3
	LEN 8
	NOTE C_, 3
	REPEAT_END
	NOTE C_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 2
	NOTE Ash, 2
	NOTE F_, 2
	NOTE C_, 2
	LEN 16
	NOTE C_, 3
	NOTE C_, 3
	LEN 8
	NOTE C_, 3
	REPEAT 2
	NOTE C_, 2
	LEN 16
	NOTE C_, 3
	NOTE C_, 3
	LEN 8
	NOTE C_, 3
	REPEAT_END
	NOTE C_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE Ash, 2
	NEXT
Pat_5FD0:
	REPEAT 3
	LEN 16
	NOTE C_, 2
	LEN 8
	NOTE C_, 2
	LEN 24
	NOTE C_, 3
	REPEAT_END
	LEN 16
	NOTE C_, 2
	LEN 8
	NOTE C_, 3
	LEN 16
	NOTE C_, 2
	LEN 8
	NOTE C_, 3
	REPEAT 2
	LEN 16
	NOTE C_, 2
	LEN 8
	NOTE C_, 2
	LEN 24
	NOTE C_, 3
	REPEAT_END
	LEN 16
	NOTE C_, 2
	LEN 8
	NOTE C_, 2
	LEN 16
	NOTE C_, 3
	LEN 8
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE Ash, 2
	NEXT
Pat_5FF7:
	INSTR 11
	LEN 16
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	LENGTH $30
	NOTE C_, 2
	LEN 16
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	LENGTH $30
	NOTE C_, 2
	LEN 16
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE Ash, 2
	NOTE F_, 2
	LEN 8
	NOTE G_, 2
	NOTE Ash, 2
	LEN 16
	NOTE C_, 2
	NOTE C_, 3
	LEN 8
	NOTE C_, 2
	NOTE C_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE Ash, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE Ash, 2
	NEXT
Pat_601C:
	LEN 8
	REPEAT 2
	INSTR 5
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE C_, 3
	INSTR 5
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	NOTE C_, 2
	INSTR 4
	NOTE Csh, 4
	INSTR 11
	NOTE Gsh, 2
	NOTE Csh, 3
	INSTR 4
	NOTE Csh, 4
	INSTR 11
	NOTE Gsh, 2
	NOTE Csh, 2
	REPEAT_END
	REPEAT 2
	INSTR 5
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	NOTE C_, 2
	INSTR 5
	NOTE C_, 4
	INSTR 11
	NOTE C_, 2
	NOTE C_, 2
	INSTR 4
	NOTE Csh, 4
	INSTR 11
	NOTE Csh, 2
	NOTE Csh, 2
	INSTR 4
	NOTE Csh, 4
	INSTR 11
	NOTE Csh, 2
	NOTE Csh, 2
	REPEAT_END
	NEXT
Pat_604A:
	INSTR 11
	LEN 16
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	LENGTH $30
	NOTE C_, 2
	LEN 16
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	LENGTH $30
	NOTE C_, 2
	LEN 16
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE Ash, 2
	LEN 8
	NOTE Ash, 2
	NOTE F_, 2
	NOTE G_, 2
	LEN 16
	NOTE Ash, 2
	LEN 8
	NOTE C_, 2
	NOTE C_, 2
	LEN 16
	NOTE C_, 3
	LEN 8
	NOTE C_, 2
	NOTE Csh, 2
	NOTE Gsh, 2
	NOTE Csh, 3
	LEN 24
	NOTE Csh, 2
	NEXT
Pat_6071:
	CH_TRANSPOSE $0C
	INSTR 3
	LEN 16
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 8
	NOTE Gsh, 3
	NOTE Gsh, 3
	LEN 16
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 8
	NOTE Gsh, 3
	NOTE Gsh, 3
	LEN 16
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 8
	NOTE Gsh, 3
	NOTE Gsh, 3
	LEN 16
	NOTE F_, 4
	LEN 8
	NOTE F_, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 16
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 8
	NOTE Gsh, 3
	NOTE Gsh, 3
	LEN 16
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 8
	NOTE Gsh, 3
	NOTE Gsh, 3
	LEN 16
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 8
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE B_, 3
	NOTE B_, 3
	NOTE B_, 3
	NEXT
Pat_60A6:
	REPEAT 3
	INSTR 18
	LEN 16
	NOTE C_, 4
	INSTR 3
	LEN 8
	NOTE Csh, 4
	INSTR 18
	NOTE C_, 4
	INSTR 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	REPEAT_END
	NEXT
Pat_60B4:
	PAT_CALL Pat_60A6
	INSTR 18
	LEN 16
	NOTE C_, 4
	INSTR 3
	LEN 8
	NOTE F_, 4
	INSTR 18
	NOTE C_, 4
	INSTR 3
	NOTE Csh, 4
	NOTE Csh, 4
	PAT_CALL Pat_60A6
	INSTR 18
	NOTE C_, 4
	INSTR 3
	NOTE F_, 4
	NOTE F_, 4
	INSTR 18
	NOTE C_, 4
	INSTR 3
	NOTE B_, 3
	NOTE B_, 3
	NEXT
Pat_60D0:
	INSTR 2
	LEN 16
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	LEN 8
	NOTE E_, 3
	INSTR 1
	LEN 24
	NOTE A_, 3
	INSTR 2
	LEN 16
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	LEN 8
	NOTE E_, 3
	NOTE E_, 3
	NOTE C_, 3
	INSTR 1
	NOTE A_, 3
	NOTE F_, 3
	NOTE D_, 3
	INSTR 2
	LEN 16
	NOTE C_, 3
	LEN 8
	NOTE C_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 2
	LEN 16
	NOTE E_, 3
	NOTE E_, 3
	LEN 8
	NOTE E_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 2
	LEN 16
	NOTE E_, 3
	NOTE E_, 3
	LEN 8
	NOTE E_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 2
	LEN 16
	NOTE E_, 3
	NOTE E_, 3
	LEN 8
	NOTE E_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	NOTE E_, 3
	NEXT
Pat_610B:
	LEN 8
	INSTR 2
	NOTE E_, 3
	INSTR 18
	NOTE Dsh, 4
	INSTR 2
	NOTE E_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 18
	NOTE Dsh, 4
	INSTR 2
	NOTE E_, 3
	INSTR 18
	NOTE F_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 18
	NOTE F_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 18
	NOTE Dsh, 4
	INSTR 2
	NOTE E_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 18
	NOTE Dsh, 4
	INSTR 2
	NOTE E_, 3
	INSTR 18
	NOTE F_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	INSTR 18
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 18
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 18
	NOTE Gsh, 4
	INSTR 2
	NOTE E_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 18
	NOTE Gsh, 4
	INSTR 2
	NOTE E_, 3
	INSTR 18
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 18
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 18
	NOTE Gsh, 4
	INSTR 2
	NOTE E_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	NOTE E_, 3
	NEXT
Pat_616A:
	INSTR 2
	LEN 16
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	LEN 8
	NOTE E_, 3
	INSTR 1
	LEN 24
	NOTE A_, 3
	INSTR 2
	LEN 16
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	LEN 8
	NOTE E_, 3
	NOTE E_, 3
	NOTE C_, 3
	INSTR 1
	NOTE A_, 3
	NOTE F_, 3
	NOTE D_, 3
	INSTR 2
	LEN 16
	NOTE C_, 3
	LEN 8
	NOTE C_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 2
	LEN 16
	NOTE E_, 3
	NOTE E_, 3
	LEN 8
	NOTE E_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 2
	LEN 16
	NOTE E_, 3
	NOTE E_, 3
	LEN 8
	NOTE E_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 2
	LEN 16
	NOTE E_, 3
	INSTR 1
	NOTE A_, 3
	NOTE A_, 3
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	NEXT
Pat_61A3:
	TRANSPOSE $02
	DRUMS $08, DrumPat_6297
	ARP 6
	HWENV $1F, $00
	DUTY_50
	VIBRATO $10, $03, $06
	LENGTH $A8
	NOTE C_, 3
	HWENV $F2, $00
	LEN 8
	NOTE C_, 3
	NOTE Csh, 3
	NOTE Ash, 2
	NOTE C_, 3
	HWENV $C1, $00
	DUTY_75
	PAN_R
	LEN 16
	NOTE C_, 4
	NOTE C_, 4
	LEN 8
	NOTE C_, 4
	PAN_L
	NOTE C_, 3
	LEN 16
	NOTE C_, 4
	NOTE C_, 4
	LEN 8
	NOTE C_, 4
	PAN_R
	NOTE C_, 3
	LEN 16
	NOTE C_, 4
	NOTE C_, 4
	LEN 8
	NOTE C_, 4
	PAN_C
	NOTE C_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE Ash, 3
	NEXT
Pat_61DD:
	AUTODUTY $10
	RELEASE $00
	VIBRATO $09, $01, $04
	HWENV $3F, $30, $D5
	ARP 5
	LENGTH $60
	NOTE C_, 4
	NOTE G_, 4
	NOTE F_, 4
	LENGTH $30
	NOTE F_, 4
	NOTE G_, 4
	NEXT
Pat_61F4:
	LENGTH $60
	NOTE C_, 5
	NOTE C_, 4
	AUTODUTY $00
	RELEASE $01, $01
	ARP 6
	HWENV $D3, $00
	DUTY_75
	VIBRATO $08, $02, $04
	LEN 16
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE Ash, 3
	NOTE F_, 3
	LEN 8
	NOTE G_, 3
	NOTE Ash, 3
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE C_, 3
	NOTE C_, 3
	LEN 16
	NOTE C_, 3
	LEN 8
	NOTE F_, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE Ash, 3
	NEXT
Pat_621E:
	DRUMS $08, DrumPat_62B4
	REPEAT 2
	LEN 16
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	LENGTH $30
	NOTE C_, 3
	REPEAT_END
	NOTE C_, 3
	LEN 24
	NOTE Csh, 3
	NOTE Fsh, 3
	LENGTH $30
	NOTE C_, 3
	LEN 24
	NOTE Csh, 3
	NOTE Fsh, 3
	NEXT
Pat_6236:
	DRUMS $08, DrumPat_6306
	LENGTH $30
	NOTE C_, 3
	LEN 24
	NOTE Csh, 3
	NOTE Ash, 2
	LENGTH $30
	NOTE C_, 3
	LEN 24
	NOTE Csh, 3
	NOTE F_, 3
	LENGTH $30
	NOTE C_, 3
	LEN 24
	NOTE Csh, 3
	NOTE Ash, 2
	LEN 16
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE Csh, 3
	NOTE Gsh, 3
	NOTE Csh, 4
	NEXT
Pat_6254:
	REPEAT 2
	LEN 16
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LENGTH $30
	NOTE G_, 3
	REPEAT_END
	NOTE G_, 3
	LEN 24
	NOTE Gsh, 3
	NOTE Csh, 4
	LENGTH $30
	NOTE G_, 3
	LEN 24
	NOTE Gsh, 3
	NOTE Csh, 3
	NEXT
Pat_6268:
	DRUMS $08, DrumPat_6306
	LEN 8
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE Csh, 4
	NOTE Gsh, 3
	NOTE Csh, 4
	NOTE Fsh, 4
	NOTE Csh, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE Csh, 4
	NOTE Gsh, 3
	NOTE Csh, 4
	NOTE Fsh, 4
	NOTE Csh, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE Csh, 4
	NOTE Gsh, 4
	NOTE Csh, 4
	NOTE Fsh, 4
	NOTE Csh, 5
	NOTE Fsh, 4
	LEN 24
	NOTE G_, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE Gsh, 5
	NEXT
DrumPat_6297:
	db DRUM_REPEAT + 3, 10, 6, 10, 6, 10, 10, DRUM_REPEAT_END
	db 10, 6, 10, 10, 10, 10, DRUM_REPEAT + 3, 10
	db 6, 10, 6, 10, 10, DRUM_REPEAT_END, 10, 10
	db 10, 10, 10, 10, DRUM_LOOP
DrumPat_62B4:
	db DRUM_LEVEL + 14, 7, 0, 7, 0, 7, 0, 7
	db 0, 1, 9, 0, 0, 7, 0, 7
	db 0, 7, 0, 7, 1, 1, 9, 9
	db 9, DRUM_REPEAT + 4, 1, 6, 1, 9, 1, 6
	db DRUM_REPEAT_END, 7, 0, 7, 0, 7, 0, 7
	db 0, 1, 9, 0, 0, 7, 0, 7
	db 0, 7, 0, 7, 1, 1, 9, 9
	db 9, 1, 6, 1, 9, 1, 6, 1
	db 0, 1, 9, 1, 6, 1, 6, 1
	db 9, 1, 6, 1, 0, 1, 9, 9
	db 9, DRUM_LOOP
DrumPat_6306:
	db DRUM_LEVEL + 14, DRUM_REPEAT + 3, 1, 6, 1, 9, 1, 6
	db DRUM_REPEAT_END, 1, 6, 1, 9, 1, 1, DRUM_LOOP

; Song 10: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong10:
	call StopAll
	ld de, Song10_Ch3
	call L490C
	ld de, Song10_Ch2
	call L48FE
	ld de, Song10_Ch1
	jp L48F0
Song10_Ch3:
	dw Pat_633D
	ORDER_LOOP Song10_Ch3
Song10_Ch2:
	dw Pat_64DA
	ORDER_LOOP Song10_Ch2
Song10_Ch1:
	dw Pat_6557
	ORDER_LOOP Song10_Ch1
Pat_633D:
	CH_TRANSPOSE $0C
	INSTR 16
	LENGTH $30
	WAIT
	LEN 32
	NOTE D_, 2
	INSTR 1
	LEN 16
	NOTE A_, 3
	INSTR 16
	NOTE D_, 2
	LEN 8
	NOTE D_, 2
	LEN 24
	NOTE D_, 2
	INSTR 1
	LEN 32
	NOTE A_, 3
	INSTR 16
	NOTE F_, 2
	INSTR 1
	LEN 16
	NOTE A_, 3
	INSTR 16
	NOTE F_, 2
	LEN 8
	NOTE F_, 2
	LEN 24
	NOTE F_, 2
	INSTR 1
	LEN 32
	NOTE A_, 3
	INSTR 16
	NOTE G_, 2
	INSTR 1
	LEN 16
	NOTE A_, 3
	INSTR 16
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	LEN 24
	NOTE G_, 2
	INSTR 1
	LEN 32
	NOTE A_, 3
	INSTR 16
	NOTE Ash, 2
	INSTR 1
	LEN 16
	NOTE A_, 3
	INSTR 16
	NOTE Ash, 2
	LEN 8
	NOTE C_, 3
	NOTE C_, 3
	LEN 16
	WAIT
	INSTR 1
	LEN 32
	NOTE A_, 3
	INSTR 16
	NOTE F_, 2
	INSTR 1
	LEN 16
	NOTE A_, 3
	INSTR 16
	NOTE F_, 2
	LEN 8
	NOTE F_, 2
	LEN 24
	NOTE F_, 2
	INSTR 1
	LEN 32
	NOTE A_, 3
	INSTR 16
	NOTE A_, 2
	INSTR 1
	LEN 16
	NOTE A_, 3
	INSTR 16
	NOTE A_, 2
	LEN 8
	NOTE A_, 2
	LEN 24
	NOTE A_, 2
	INSTR 1
	LEN 32
	NOTE A_, 3
	INSTR 16
	NOTE G_, 2
	INSTR 1
	LEN 16
	NOTE A_, 3
	INSTR 16
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	LEN 24
	NOTE G_, 2
	INSTR 1
	LEN 32
	NOTE A_, 3
	INSTR 16
	NOTE Ash, 2
	INSTR 1
	LEN 16
	NOTE A_, 3
	INSTR 16
	NOTE Ash, 2
	LEN 8
	NOTE C_, 3
	NOTE C_, 3
	LEN 16
	WAIT
	INSTR 1
	LEN 32
	NOTE A_, 3
	INSTR 16
	NOTE F_, 2
	INSTR 1
	LEN 16
	NOTE A_, 3
	INSTR 16
	NOTE F_, 2
	LEN 8
	NOTE F_, 2
	LEN 24
	NOTE F_, 2
	INSTR 1
	LEN 32
	NOTE A_, 3
	INSTR 16
	NOTE E_, 2
	INSTR 1
	LEN 16
	NOTE A_, 3
	INSTR 16
	NOTE E_, 2
	LEN 8
	NOTE E_, 2
	LEN 24
	NOTE E_, 2
	INSTR 1
	LEN 32
	NOTE A_, 3
	INSTR 16
	NOTE A_, 2
	INSTR 1
	LEN 16
	NOTE A_, 3
	INSTR 16
	NOTE A_, 2
	LEN 8
	NOTE A_, 2
	LEN 24
	NOTE A_, 2
	INSTR 1
	LEN 32
	NOTE A_, 3
	INSTR 16
	NOTE G_, 2
	INSTR 1
	LEN 16
	NOTE A_, 3
	INSTR 16
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	NOTE G_, 2
	LEN 16
	WAIT
	INSTR 1
	LEN 32
	NOTE A_, 3
	INSTR 16
	LEN 16
	NOTE C_, 3
	LEN 8
	NOTE C_, 3
	NOTE C_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 16
	NOTE C_, 3
	LEN 32
	NOTE C_, 3
	LEN 16
	NOTE C_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 16
	NOTE C_, 3
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	NOTE G_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 16
	NOTE G_, 2
	LEN 16
	NOTE G_, 2
	NOTE Gsh, 2
	LEN 8
	NOTE Gsh, 2
	NOTE Gsh, 2
	INSTR 1
	NOTE A_, 3
	INSTR 16
	NOTE Gsh, 2
	LEN 16
	NOTE Gsh, 2
	NOTE A_, 2
	LEN 8
	NOTE A_, 2
	NOTE A_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 16
	NOTE A_, 2
	LEN 32
	NOTE A_, 2
	LEN 16
	NOTE A_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 16
	NOTE A_, 2
	NOTE A_, 2
	LEN 8
	NOTE A_, 2
	NOTE A_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 16
	NOTE A_, 2
	LEN 32
	NOTE A_, 2
	INSTR 16
	LEN 16
	NOTE A_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 16
	NOTE G_, 2
	NOTE C_, 3
	LEN 8
	NOTE C_, 3
	NOTE C_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 16
	NOTE C_, 3
	LEN 32
	NOTE C_, 3
	LEN 16
	NOTE C_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 16
	NOTE C_, 3
	NOTE Gsh, 2
	LEN 8
	NOTE Gsh, 2
	NOTE Gsh, 2
	INSTR 1
	NOTE A_, 3
	INSTR 16
	NOTE Gsh, 2
	LEN 16
	NOTE Gsh, 2
	NOTE E_, 2
	LEN 8
	NOTE E_, 2
	NOTE E_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 16
	NOTE E_, 2
	LEN 16
	NOTE E_, 2
	NOTE A_, 2
	LEN 8
	NOTE A_, 2
	NOTE A_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 16
	NOTE A_, 2
	LEN 32
	NOTE A_, 2
	LEN 8
	NOTE A_, 2
	NOTE A_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 16
	NOTE G_, 2
	LEN 16
	NOTE E_, 2
	NOTE A_, 2
	LEN 8
	NOTE A_, 2
	NOTE G_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 16
	LEN 16
	NOTE E_, 2
	NOTE A_, 2
	LEN 8
	NOTE G_, 2
	INSTR 16
	LEN 8
	NOTE E_, 2
	NOTE A_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 16
	NOTE G_, 2
	LEN 16
	NOTE E_, 2
	LEN 24
	NOTE F_, 2
	NOTE F_, 2
	LEN 16
	NOTE F_, 2
	LEN 32
	NOTE F_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 16
	LEN 24
	NOTE G_, 2
	NOTE G_, 2
	LEN 16
	NOTE G_, 2
	LEN 32
	NOTE G_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 16
	LEN 24
	NOTE A_, 2
	NOTE A_, 2
	LEN 16
	NOTE A_, 2
	LEN 24
	NOTE A_, 2
	NOTE A_, 2
	LEN 16
	NOTE A_, 2
	LENGTH $50
	NOTE A_, 2
	NEXT
Pat_64A4:
	LEN 8
	NOTE C_, 5
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE C_, 5
	LEN 32
	NOTE C_, 5
	LEN 16
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE G_, 4
	LEN 8
	NOTE G_, 4
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE G_, 4
	LEN 16
	NOTE G_, 4
	NOTE E_, 4
	LEN 8
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	LEN 8
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	ARP 5
	NOTE A_, 4
	LEN 8
	NOTE A_, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE A_, 4
	LEN 32
	NOTE A_, 4
	LEN 16
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	LEN 8
	NOTE A_, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE A_, 4
	LEN 32
	NOTE A_, 4
	NEXT
Pat_64DA:
	HWENV $83, $00
	DUTY_50
	AUTODUTY $04
	LENGTH $30
	REST
	ARP 5
	LEN 16
	REPEAT 8
	NOTE D_, 4
	REPEAT_END
	ARP 4
	REPEAT 8
	NOTE F_, 4
	REPEAT_END
	REPEAT 8
	NOTE G_, 4
	REPEAT_END
	REPEAT 4
	NOTE Ash, 3
	REPEAT_END
	REPEAT 4
	NOTE C_, 4
	REPEAT_END
	REPEAT 8
	NOTE F_, 4
	REPEAT_END
	ARP 5
	REPEAT 8
	NOTE A_, 4
	REPEAT_END
	ARP 4
	REPEAT 8
	NOTE G_, 4
	REPEAT_END
	REPEAT 4
	NOTE Ash, 3
	REPEAT_END
	REPEAT 4
	NOTE C_, 4
	REPEAT_END
	REPEAT 8
	NOTE F_, 4
	REPEAT_END
	REPEAT 8
	NOTE E_, 4
	REPEAT_END
	ARP 5
	REPEAT 8
	NOTE A_, 4
	REPEAT_END
	ARP 4
	REPEAT 5
	NOTE G_, 4
	REPEAT_END
	GLIDE $FF
	ARP 6
	LEN 16
	NOTE C_, 4
	NOTE B_, 3
	LEN 8
	NOTE G_, 3
	NOTE F_, 3
	GLIDE_OFF
	ARP 4
	DRUMS $08, DrumPat_665E
	LEN 16
	NOTE C_, 5
	PAT_CALL Pat_64A4
	ARP 5
	LEN 16
	NOTE A_, 4
	ARP 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE C_, 5
	PAT_CALL Pat_64A4
	ARP 5
	LEN 16
	NOTE A_, 4
	NOTE A_, 4
	ARP 4
	NOTE G_, 4
	LEN 24
	NOTE F_, 4
	NOTE F_, 4
	LEN 16
	NOTE F_, 4
	LENGTH $40
	NOTE F_, 4
	LEN 24
	NOTE G_, 3
	NOTE G_, 3
	LEN 16
	NOTE G_, 3
	LENGTH $40
	NOTE G_, 3
	ARP 5
	LEN 24
	NOTE A_, 3
	NOTE A_, 3
	LEN 16
	NOTE A_, 3
	LEN 24
	NOTE A_, 3
	NOTE A_, 3
	LEN 16
	NOTE A_, 3
	LENGTH $50
	NOTE A_, 3
	NEXT
Pat_6557:
	HWENV $A3, $10, $70
	RELEASE $04, $53
	VIBRATO $10, $01, $05
	DUTY_50
	LEN 16
	NOTE D_, 4
	NOTE A_, 4
	NOTE G_, 4
	LENGTH $50
	DRUMS $08, DrumPat_664C
	NOTE A_, 4
	LEN 16
	NOTE D_, 4
	NOTE A_, 4
	NOTE G_, 4
	LENGTH $60
	NOTE A_, 4
	LEN 8
	NOTE F_, 4
	NOTE G_, 4
	LEN 16
	NOTE A_, 4
	LENGTH $30
	NOTE G_, 4
	LEN 16
	NOTE D_, 4
	LENGTH $30
	NOTE D_, 4
	LEN 8
	NOTE D_, 4
	NOTE E_, 4
	LEN 16
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 8
	NOTE E_, 4
	LEN 24
	NOTE D_, 4
	LEN 16
	NOTE C_, 4
	NOTE A_, 4
	NOTE G_, 4
	LENGTH $50
	NOTE A_, 4
	LEN 16
	NOTE E_, 4
	NOTE C_, 5
	NOTE B_, 4
	LENGTH $60
	NOTE C_, 5
	LEN 8
	NOTE A_, 4
	NOTE B_, 4
	LEN 16
	NOTE C_, 5
	LEN 24
	NOTE B_, 4
	NOTE G_, 4
	LEN 32
	NOTE D_, 5
	LEN 16
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	LEN 24
	NOTE Ash, 4
	NOTE F_, 4
	LEN 32
	NOTE D_, 5
	LEN 32
	NOTE C_, 5
	LEN 8
	NOTE F_, 4
	NOTE G_, 4
	LENGTH $70
	NOTE A_, 4
	LEN 8
	NOTE F_, 4
	NOTE G_, 4
	LENGTH $30
	NOTE A_, 4
	LEN 8
	NOTE B_, 4
	NOTE A_, 4
	LEN 24
	NOTE Gsh, 4
	NOTE A_, 4
	LEN 16
	NOTE B_, 4
	LENGTH $70
	NOTE C_, 5
	LEN 8
	NOTE A_, 4
	NOTE B_, 4
	LENGTH $30
	NOTE C_, 5
	LEN 8
	NOTE D_, 5
	NOTE C_, 5
	LEN 16
	NOTE B_, 4
	LEN 16
	WAIT
	LEN 32
	NOTE G_, 4
	LEN 24
	NOTE E_, 5
	NOTE F_, 5
	LEN 16
	NOTE E_, 5
	LENGTH $30
	NOTE G_, 5
	LEN 8
	NOTE F_, 5
	NOTE E_, 5
	LEN 24
	NOTE D_, 5
	NOTE E_, 5
	LEN 16
	NOTE D_, 5
	LEN 24
	NOTE F_, 5
	NOTE E_, 5
	LEN 16
	NOTE B_, 4
	LENGTH $30
	NOTE C_, 5
	LEN 8
	NOTE B_, 4
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	LEN 8
	NOTE A_, 4
	LENGTH $58
	NOTE E_, 4
	LEN 16
	WAIT
	LEN 32
	NOTE G_, 4
	LEN 24
	NOTE E_, 5
	NOTE F_, 5
	LEN 16
	NOTE E_, 5
	LENGTH $30
	NOTE G_, 5
	LEN 8
	NOTE F_, 5
	NOTE E_, 5
	LEN 24
	NOTE D_, 5
	NOTE F_, 5
	LEN 16
	NOTE E_, 5
	LEN 24
	NOTE Gsh, 5
	NOTE A_, 5
	LEN 16
	NOTE B_, 5
	LENGTH $30
	NOTE C_, 6
	LEN 8
	NOTE B_, 5
	NOTE C_, 6
	LEN 16
	NOTE D_, 6
	NOTE C_, 6
	NOTE B_, 5
	LEN 8
	NOTE A_, 5
	LEN 24
	NOTE E_, 5
	LEN 16
	NOTE C_, 5
	NOTE B_, 4
	LEN 8
	NOTE A_, 4
	LEN 24
	NOTE E_, 4
	LEN 16
	NOTE C_, 4
	NOTE B_, 3
	NOTE G_, 3
	DRUMS $08, DrumPat_6670
	LENGTH $70
	NOTE A_, 3
	LEN 8
	NOTE B_, 3
	NOTE C_, 4
	LEN 32
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE G_, 3
	LEN 16
	NOTE B_, 3
	LEN 8
	NOTE C_, 4
	LENGTH $68
	NOTE A_, 3
	LENGTH $40
	DRUMS_OFF
	CALL_CODE Drum7
	NOTE A_, 2
	LEN 16
	WAIT2
	NEXT
DrumPat_664C:
	db DRUM_LEVEL + 14, 1, 0, 6, 0, 9, 0, 1
	db 0, 1, 1, 6, 0, 9, 0, 4
	db 0, DRUM_LOOP
DrumPat_665E:
	db DRUM_LEVEL + 14, 1, 6, 5, 6, 9, 6, 5
	db 6, 1, 6, 5, 6, 9, 6, 5
	db 6, DRUM_LOOP
DrumPat_6670:
	db DRUM_LEVEL + 14, 7, 0, 0, 1, 0, 0, 1; no DRUM_LOOP: the pattern runs into the next data
	db 0, 1, 0, 6, 6, 9, 0, 6
	db 0, 1, 0, 0, 1, 0, 0, 1
	db 0, 1, 0, 6, 6, 9, 0, 6
	db 6, 1, 0, 0, 1, 0, 0, 1
	db 0, 1, 0, 0, 1, 0, 0, 1
	db 0

; Song 11: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong11:
	call StopAll
	ld de, Song11_Ch1
	call L48F0
	ld de, Song11_Ch3
	call L490C
	ld de, Song11_Ch2
	jp L48FE
Song11_Ch1:
	dw Pat_66E6
Loop_66B8:
	dw Pat_6701
	dw Pat_673D
	dw Pat_6736
	dw Pat_66E6
	dw Pat_6701
	ORDER_LOOP Loop_66B8
Song11_Ch3:
	dw Pat_6778
Loop_66C8:
	dw Pat_679A
	dw Pat_67E3
	dw Pat_6845
	dw Pat_68C7
	dw Pat_679A
	ORDER_LOOP Loop_66C8
Song11_Ch2:
	dw Pat_6901
Loop_66D8:
	dw Pat_6954
	dw Pat_6978
	dw Pat_6994
	dw Pat_69AB
	dw Pat_6954
	ORDER_LOOP Loop_66D8
Pat_66E6:
	TRANSPOSE $02
	DRUMS $09, DrumPat_69DA
	INSTR 12
	LEN 18
	REPEAT 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	REPEAT_END
	NEXT
Pat_6701:
	DRUMS $09, DrumPat_69E4
	LEN 18
	INSTR 11
	REPEAT 2
	NOTE A_, 2
	INSTR 12
	LEN 9
	NOTE A_, 2
	INSTR 11
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 2
	INSTR 11
	LEN 18
	NOTE A_, 2
	INSTR 12
	LEN 9
	NOTE A_, 2
	NOTE A_, 2
	INSTR 11
	LEN 18
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE E_, 2
	INSTR 12
	LEN 9
	NOTE E_, 2
	INSTR 11
	LEN 18
	NOTE D_, 2
	INSTR 12
	LEN 9
	NOTE D_, 2
	INSTR 11
	LEN 18
	NOTE E_, 2
	INSTR 12
	LEN 9
	NOTE E_, 2
	NOTE E_, 2
	INSTR 11
	LEN 18
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	REPEAT_END
	NEXT
Pat_6736:
	DRUMS $09, DrumPat_69E4
	PAT_GOTO Pat_6741
Pat_673D:
	DRUMS $09, DrumPat_69F6
Pat_6741:
	INSTR 12
	LEN 18
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE A_, 2
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE A_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	LEN 9
	NOTE D_, 2
	LEN 18
	NOTE E_, 2
	LEN 9
	NOTE D_, 2
	LEN 18
	NOTE E_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	LEN 9
	NOTE E_, 2
	LEN 18
	NOTE F_, 2
	LEN 9
	NOTE E_, 2
	LEN 18
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 2
	LEN 9
	NOTE E_, 2
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE E_, 2
	NOTE G_, 2
	NOTE E_, 2
	NEXT
Pat_6778:
	CH_TRANSPOSE $0C
	LEN 18
	REPEAT 2
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 36
	NOTE A_, 3
	LEN 18
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 36
	NOTE A_, 3
	LEN 18
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 36
	NOTE E_, 3
	LEN 18
	NOTE E_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 36
	NOTE E_, 3
	LEN 18
	NOTE E_, 3
	REPEAT_END
	NEXT
Pat_679A:
	INSTR 2
	LEN 18
	NOTE E_, 3
	INSTR 15
	NOTE A_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE A_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE A_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE A_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE E_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE E_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE E_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	LEN 9
	NOTE E_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 2
	LEN 18
	NOTE E_, 3
	INSTR 15
	NOTE A_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE A_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE A_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE A_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE E_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE E_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE E_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	LEN 9
	NOTE E_, 4
	INSTR 1
	NOTE A_, 3
	NEXT
Pat_67E3:
	INSTR 2
	LEN 9
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	NOTE G_, 3
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	NOTE G_, 3
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	NOTE G_, 3
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	NOTE G_, 3
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	NOTE A_, 3
	NOTE B_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	NOTE A_, 3
	NOTE B_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	NOTE A_, 3
	NOTE B_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	NOTE A_, 3
	NOTE B_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	NOTE G_, 3
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	NOTE G_, 3
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	NOTE G_, 3
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	NOTE G_, 3
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	NOTE A_, 3
	NOTE B_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	NOTE A_, 3
	NOTE B_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	NOTE A_, 3
	NOTE B_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	NOTE A_, 3
	NOTE B_, 3
	NEXT
Pat_6845:
	LEN 9
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	INSTR 15
	NOTE A_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE E_, 3
	INSTR 15
	NOTE A_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	INSTR 15
	NOTE A_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE E_, 3
	INSTR 15
	NOTE A_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	INSTR 15
	NOTE E_, 4
	INSTR 0
	NOTE B_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE E_, 3
	INSTR 15
	NOTE E_, 4
	INSTR 0
	NOTE B_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	INSTR 15
	NOTE E_, 4
	INSTR 0
	NOTE B_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE E_, 3
	INSTR 15
	NOTE E_, 4
	INSTR 0
	NOTE B_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	INSTR 14
	NOTE F_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE E_, 3
	INSTR 14
	NOTE F_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	INSTR 14
	NOTE F_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE E_, 3
	INSTR 14
	NOTE F_, 4
	INSTR 0
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	INSTR 14
	NOTE G_, 4
	INSTR 0
	NOTE B_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE E_, 3
	INSTR 14
	NOTE G_, 4
	INSTR 0
	NOTE B_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE E_, 3
	INSTR 14
	NOTE G_, 4
	INSTR 0
	NOTE B_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE E_, 3
	INSTR 14
	NOTE G_, 4
	INSTR 0
	NOTE B_, 3
	NEXT
Pat_68C7:
	INSTR 2
	LEN 18
	NOTE E_, 3
	INSTR 15
	LEN 36
	NOTE A_, 3
	LEN 18
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 36
	NOTE A_, 3
	LEN 18
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 36
	NOTE E_, 3
	LEN 18
	NOTE E_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 36
	NOTE E_, 3
	LEN 18
	NOTE E_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 14
	LEN 36
	NOTE F_, 3
	LEN 18
	NOTE F_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 14
	LEN 36
	NOTE F_, 3
	LEN 18
	NOTE F_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 14
	LEN 36
	NOTE G_, 3
	LEN 18
	NOTE G_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 14
	LEN 36
	NOTE G_, 3
	LEN 18
	NOTE G_, 3
	NEXT
Pat_6901:
	VIBRATO $12, $02, $04
	HWENV $D1, $09, $53
	DUTY_50
	ARP 22
	LEN 9
	NOTE D_, 3
	NOTE E_, 3
	NOTE G_, 3
	LEN 18
	NOTE A_, 3
	LEN 9
	NOTE D_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE A_, 3
	LEN 18
	NOTE D_, 3
	LEN 9
	NOTE E_, 3
	LEN 18
	NOTE G_, 3
	NOTE A_, 3
	LEN 9
	NOTE D_, 3
	NOTE E_, 3
	NOTE G_, 3
	LEN 18
	NOTE A_, 3
	LEN 9
	NOTE D_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE A_, 3
	LEN 18
	NOTE D_, 3
	LEN 9
	NOTE E_, 3
	LEN 18
	NOTE G_, 3
	NOTE A_, 3
	LEN 9
	NOTE D_, 3
	NOTE E_, 3
	NOTE G_, 3
	LEN 18
	NOTE A_, 3
	LEN 9
	NOTE D_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE A_, 3
	LEN 18
	NOTE D_, 3
	LEN 9
	NOTE E_, 3
	LEN 18
	NOTE G_, 3
	NOTE A_, 3
	LEN 9
	NOTE D_, 3
	NOTE E_, 3
	NOTE G_, 3
	LEN 18
	NOTE A_, 3
	LEN 9
	NOTE D_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE A_, 3
	LEN 18
	NOTE D_, 3
	LEN 9
	NOTE E_, 3
	LEN 18
	NOTE G_, 3
	NOTE A_, 3
	NEXT
Pat_6954:
	LEN 9
	REPEAT 2
	NOTE D_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE G_, 4
	NOTE A_, 3
	NOTE A_, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 3
	NOTE D_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE E_, 4
	NOTE G_, 4
	NOTE B_, 3
	NOTE A_, 4
	NOTE B_, 3
	REPEAT_END
	NEXT
Pat_6978:
	ARP_OFF
	HWENV $5A, $09, $D7
	DUTY_75
	LENGTH $6C
	NOTE A_, 3
	LEN 36
	NOTE C_, 4
	LENGTH $48
	NOTE B_, 3
	LEN 36
	NOTE G_, 3
	NOTE E_, 3
	LENGTH $6C
	NOTE A_, 3
	LEN 18
	NOTE D_, 4
	NOTE C_, 4
	LENGTH $48
	NOTE B_, 3
	NOTE E_, 3
	NEXT
Pat_6994:
	LENGTH $6C
	NOTE A_, 3
	LEN 36
	NOTE C_, 4
	LENGTH $48
	NOTE B_, 3
	LEN 36
	NOTE G_, 3
	NOTE E_, 3
	LENGTH $6C
	NOTE A_, 3
	LEN 18
	NOTE D_, 4
	NOTE C_, 4
	LEN 36
	NOTE B_, 3
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 3
	NEXT
Pat_69AB:
	LENGTH $90
	NOTE A_, 3
	WAIT
	HWENV $D1, $09, $53
	DUTY_50
	ARP 22
	LEN 9
	NOTE D_, 3
	NOTE E_, 3
	NOTE G_, 3
	LEN 18
	NOTE A_, 3
	LEN 9
	NOTE D_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE A_, 3
	LEN 18
	NOTE D_, 3
	LEN 9
	NOTE E_, 3
	LEN 18
	NOTE G_, 3
	NOTE A_, 3
	LEN 9
	NOTE D_, 3
	NOTE E_, 3
	NOTE G_, 3
	LEN 18
	NOTE A_, 3
	LEN 9
	NOTE D_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE A_, 3
	LEN 18
	NOTE D_, 3
	LEN 9
	NOTE E_, 3
	LEN 18
	NOTE G_, 3
	NOTE A_, 3
	NEXT
DrumPat_69DA:
	db DRUM_LEVEL + 13, 1, 0, 6, 6, 4, 0, 6
	db 6, DRUM_LOOP
DrumPat_69E4:
	db DRUM_LEVEL + 13, 1, 0, 4, 6, 9, 4, 4
	db 6, 1, 0, 4, 6, 9, 6, 4
	db 6, DRUM_LOOP
DrumPat_69F6:
	db DRUM_LEVEL + 13, 1, 6, 6, 6, 1, 6, 6
	db 6, DRUM_LOOP

; Song 12: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong12:
	call StopAll
	ld de, Song12_Ch1
	call L48F0
	ld de, Song12_Ch2
	call L48FE
	ld de, Song12_Ch3
	jp L490C
Song12_Ch1:
	dw Pat_6A5D
	dw Pat_6A5D
	dw Pat_6A5D
	dw Pat_6A79
	dw Pat_6A91
	dw Pat_6A91
	dw Pat_6AA5
	dw Pat_6AA5
	dw Pat_6AA5
	dw Pat_6AA5
	ORDER_LOOP Song12_Ch1
Song12_Ch2:
	dw Pat_6AE3
	dw Pat_6AF9
	dw Pat_6B22
	dw Pat_6B54
	dw Pat_6B6D
	dw Pat_6B94
	dw Pat_6BBC
	dw Pat_6BC1
	dw Pat_6BBC
	dw Pat_6BC1
	ORDER_LOOP Song12_Ch2
Song12_Ch3:
	dw Pat_6BC7
	dw Pat_6BD5
	dw Pat_6BD5
	dw Pat_6BF9
	dw Pat_6C01
	dw Pat_6C01
	dw Pat_6C6D
	dw Pat_6C6D
	dw Pat_6C6D
	dw Pat_6C6D
	ORDER_LOOP Song12_Ch3
Pat_6A5D:
	HWENV $D7, $36, $40
	DUTY_75
	VIBRATO $12, $01, $04
	AUTODUTY $00
	LENGTH $6C
	NOTE F_, 2
	LEN 36
	NOTE G_, 2
	LENGTH $90
	NOTE D_, 2
	LENGTH $6C
	NOTE F_, 2
	LEN 36
	NOTE G_, 2
	LENGTH $90
	NOTE D_, 2
	NEXT
Pat_6A79:
	LENGTH $6C
	NOTE F_, 2
	LEN 36
	NOTE G_, 2
	LENGTH $90
	NOTE D_, 2
	LENGTH $6C
	NOTE F_, 2
	LEN 36
	NOTE G_, 2
	LEN 27
	NOTE D_, 2
	NOTE D_, 2
	LEN 18
	NOTE D_, 2
	LEN 27
	NOTE D_, 2
	NOTE D_, 2
	LEN 18
	NOTE D_, 2
	NEXT
Pat_6A91:
	LEN 9
	INSTR 12
	REPEAT 4
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	LEN 18
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	LEN 9
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	REPEAT_END
	NEXT
Pat_6AA5:
	LEN 9
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 2
	NOTE C_, 3
	LEN 18
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 3
	LEN 9
	NOTE G_, 2
	NOTE D_, 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	LEN 18
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	LEN 9
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 2
	NOTE C_, 3
	LEN 18
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 3
	LEN 9
	NOTE G_, 2
	NOTE D_, 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	LEN 18
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	LEN 9
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NEXT
Pat_6AE3:
	AUTODUTY $09
	LEN 9
	WAIT
	INSTR 13
	LENGTH $6C
	NOTE F_, 2
	LEN 36
	NOTE G_, 2
	LENGTH $90
	NOTE D_, 2
	LENGTH $6C
	NOTE F_, 2
	LEN 36
	NOTE G_, 2
	LENGTH $87
	NOTE D_, 2
	NEXT
Pat_6AF9:
	LEN 9
	NOTE A_, 3
	NOTE G_, 3
	NOTE F_, 3
	LEN 18
	NOTE G_, 3
	LENGTH $63
	NOTE A_, 3
	LEN 9
	NOTE A_, 3
	NOTE G_, 3
	NOTE F_, 3
	LEN 18
	NOTE G_, 3
	LEN 9
	NOTE A_, 3
	LENGTH $5A
	NOTE D_, 3
	LEN 9
	NOTE A_, 3
	NOTE G_, 3
	NOTE F_, 3
	LEN 18
	NOTE G_, 3
	LENGTH $63
	NOTE A_, 3
	LEN 9
	NOTE A_, 3
	NOTE G_, 3
	NOTE F_, 3
	LEN 18
	NOTE G_, 3
	LEN 9
	NOTE A_, 3
	LENGTH $5A
	NOTE D_, 4
	NEXT
Pat_6B22:
	LEN 9
	WAIT
	NOTE C_, 3
	NOTE F_, 3
	NOTE A_, 3
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE D_, 4
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE B_, 3
	LEN 18
	NOTE A_, 3
	NOTE B_, 3
	NOTE G_, 3
	LEN 45
	NOTE A_, 3
	LEN 9
	NOTE G_, 3
	NOTE F_, 3
	LEN 45
	NOTE E_, 3
	NOTE D_, 3
	LEN 9
	NOTE C_, 3
	NOTE F_, 3
	NOTE A_, 3
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE D_, 4
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE B_, 3
	LEN 18
	NOTE A_, 3
	NOTE B_, 3
	NOTE G_, 3
	LEN 45
	NOTE A_, 3
	LEN 9
	NOTE A_, 2
	NOTE C_, 3
	LENGTH $51
	NOTE D_, 3
	NEXT
Pat_6B54:
	INSTR 13
	LENGTH $6C
	NOTE C_, 4
	LEN 36
	NOTE D_, 4
	LENGTH $90
	NOTE A_, 3
	LENGTH $6C
	NOTE F_, 3
	LEN 36
	NOTE G_, 3
	LEN 27
	NOTE D_, 3
	NOTE F_, 3
	LEN 18
	NOTE F_, 3
	LEN 27
	NOTE A_, 3
	NOTE D_, 4
	LEN 18
	NOTE D_, 4
	NEXT
Pat_6B6D:
	INSTR 9
	LEN 9
	REPEAT 2
	NOTE C_, 6
	NOTE A_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE A_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE A_, 4
	NOTE F_, 5
	NOTE D_, 5
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	REPEAT_END
	REPEAT 2
	NOTE D_, 6
	NOTE B_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE B_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE B_, 4
	NOTE G_, 5
	NOTE D_, 5
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 5
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	REPEAT_END
	NEXT
Pat_6B94:
	ARP_OFF
	HWENV $0F, $36, $80
	VIBRATO $12, $01, $05
	LENGTH $90
	NOTE D_, 4
	HWENV $80, $00
	LENGTH $48
	NOTE E_, 4
	NOTE F_, 4
	LEN 27
	NOTE E_, 4
	LEN 4
	NOTE F_, 4
	LEN 5
	NOTE E_, 4
	LENGTH $BD
	NOTE D_, 4
	RELEASE $09, $92
	LEN 9
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE Gsh, 4
	NOTE D_, 4
	NEXT
Pat_6BBC:
	CH_TRANSPOSE $0C
	PAT_GOTO Pat_6AF9
Pat_6BC1:
	PAT_CALL Pat_6B22
	CH_TRANSPOSE $00
	NEXT
Pat_6BC7:
	DRUMS $09, DrumPat_6CF9
	CH_TRANSPOSE $0C
	ARP 6
	VOLENV 12, $11, $1F, $11
	WAVE Wave_7E1F
Pat_6BD5:
	LEN 9
	REPEAT 2
	NOTE E_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE D_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE D_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE D_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE D_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE F_, 3
	REPEAT_END
	NEXT
Pat_6BF9:
	CH_TRANSPOSE $18
	PAT_CALL Pat_6BD5
	CH_TRANSPOSE $0C
	NEXT
Pat_6C01:
	DRUMS $09, DrumPat_6CD5
	INSTR 2
	LEN 18
	NOTE A_, 3
	INSTR 14
	NOTE F_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 14
	LEN 9
	NOTE F_, 4
	INSTR 2
	LEN 18
	NOTE A_, 3
	INSTR 14
	LEN 9
	NOTE F_, 4
	INSTR 2
	LEN 18
	NOTE A_, 3
	INSTR 1
	LEN 9
	NOTE C_, 4
	INSTR 14
	NOTE F_, 4
	INSTR 2
	LEN 18
	NOTE A_, 3
	NOTE A_, 3
	INSTR 14
	NOTE F_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 14
	LEN 9
	NOTE F_, 4
	INSTR 2
	LEN 18
	NOTE A_, 3
	INSTR 14
	LEN 9
	NOTE F_, 4
	INSTR 2
	LEN 18
	NOTE A_, 3
	INSTR 1
	LEN 9
	NOTE C_, 4
	INSTR 14
	NOTE F_, 4
	INSTR 2
	LEN 18
	NOTE A_, 3
	NOTE A_, 3
	INSTR 14
	NOTE G_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 14
	LEN 9
	NOTE G_, 4
	INSTR 2
	LEN 18
	NOTE A_, 3
	INSTR 14
	LEN 9
	NOTE G_, 4
	INSTR 2
	LEN 18
	NOTE A_, 3
	INSTR 1
	LEN 9
	NOTE C_, 4
	INSTR 14
	NOTE G_, 4
	INSTR 2
	LEN 18
	NOTE A_, 3
	NOTE A_, 3
	INSTR 14
	NOTE G_, 4
	INSTR 1
	LEN 9
	NOTE C_, 4
	INSTR 14
	LEN 18
	NOTE G_, 4
	INSTR 2
	NOTE A_, 3
	INSTR 14
	LEN 9
	NOTE G_, 4
	INSTR 2
	LEN 18
	NOTE A_, 3
	INSTR 1
	LEN 9
	NOTE C_, 4
	INSTR 14
	NOTE G_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE A_, 3
	NEXT
Pat_6C6D:
	INSTR 2
	LEN 18
	NOTE A_, 3
	INSTR 14
	NOTE F_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 14
	LEN 9
	NOTE F_, 4
	INSTR 2
	LEN 18
	NOTE A_, 3
	INSTR 14
	LEN 9
	NOTE G_, 4
	INSTR 2
	LEN 18
	NOTE A_, 3
	INSTR 1
	LEN 9
	NOTE C_, 4
	INSTR 14
	NOTE G_, 4
	INSTR 2
	LEN 18
	NOTE A_, 3
	NOTE A_, 3
	INSTR 15
	NOTE D_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 15
	LEN 9
	NOTE D_, 4
	INSTR 2
	LEN 18
	NOTE A_, 3
	INSTR 15
	LEN 9
	NOTE D_, 4
	INSTR 2
	LEN 18
	NOTE A_, 3
	INSTR 1
	LEN 9
	NOTE C_, 4
	INSTR 15
	NOTE D_, 4
	INSTR 2
	LEN 18
	NOTE A_, 3
	NOTE A_, 3
	INSTR 14
	NOTE F_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 14
	LEN 9
	NOTE F_, 4
	INSTR 2
	LEN 18
	NOTE A_, 3
	INSTR 14
	LEN 9
	NOTE G_, 4
	INSTR 2
	LEN 18
	NOTE A_, 3
	INSTR 1
	LEN 9
	NOTE C_, 4
	INSTR 14
	NOTE G_, 4
	INSTR 2
	LEN 18
	NOTE A_, 3
	NOTE A_, 3
	INSTR 15
	NOTE D_, 4
	INSTR 1
	LEN 9
	NOTE C_, 4
	INSTR 15
	LEN 18
	NOTE D_, 4
	INSTR 2
	NOTE A_, 3
	INSTR 15
	LEN 9
	NOTE D_, 4
	INSTR 2
	LEN 18
	NOTE A_, 3
	INSTR 1
	LEN 9
	NOTE C_, 4
	INSTR 15
	NOTE D_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE A_, 3
	NEXT
DrumPat_6CD5:
	db DRUM_LEVEL + 14, DRUM_REPEAT + 3, 1, 6, 4, 6, 9, 6
	db 4, 1, 6, 6, 1, 6, 9, 6
	db 1, 6, DRUM_REPEAT_END, 1, 6, 4, 6, 9
	db 6, 4, 1, 6, 6, 1, 6, 9
	db 6, 9, 1, DRUM_LOOP
DrumPat_6CF9:
	db DRUM_LEVEL + 12, DRUM_REPEAT + 3, 5, 6, 6, 6, 4, 6
	db 6, 5, 6, 6, 5, 6, 4, 6
	db 5, 6, DRUM_REPEAT_END, 5, 6, 6, 6, 4
	db 6, 6, 5, 6, 6, 5, 6, 4
	db 6, 4, 5, DRUM_LOOP

; Song 13: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong13:
	call StopAll
	ld de, Song13_Ch1
	call L48F0
	ld de, Song13_Ch3
	call L490C
	ld de, Song13_Ch2
	jp L48FE
Song13_Ch1:
	dw Pat_6D7A
	dw Pat_6D83
	dw Pat_6D83
	dw Pat_6D96
	dw Pat_6D96
	dw Pat_6DAA
	dw Pat_6DAA
	dw Pat_6DBD
	dw Pat_6DBD
	dw Pat_6DD0
	ORDER_LOOP Song13_Ch1
Song13_Ch3:
	dw Pat_6DED
	dw Pat_6E01
	dw Pat_6E01
	dw Pat_6E01
	dw Pat_6E01
	dw Pat_6E14
	dw Pat_6E14
	dw Pat_6E27
	dw Pat_6E27
	dw Pat_6E3A
	ORDER_LOOP Song13_Ch3
Song13_Ch2:
	dw Pat_6E59
	dw Pat_6E71
	dw Pat_6E71
	dw Pat_6EAE
	dw Pat_6EAE
	dw Pat_6ED6
	dw Pat_6ED6
	dw Pat_6F04
	dw Pat_6F04
	dw Pat_6F23
	ORDER_LOOP Song13_Ch2
Pat_6D7A:
	INSTR 11
	REPEAT 4
	LEN 42
	NOTE D_, 2
	NOTE Dsh, 2
	LEN 28
	NOTE Ash, 2
	REPEAT_END
	NEXT
Pat_6D83:
	REPEAT 4
	LEN 28
	INSTR 11
	NOTE D_, 2
	INSTR 12
	LEN 14
	NOTE A_, 2
	INSTR 11
	LEN 28
	NOTE Dsh, 2
	INSTR 12
	LEN 14
	NOTE Dsh, 2
	INSTR 11
	NOTE Ash, 2
	INSTR 12
	NOTE Dsh, 2
	REPEAT_END
	NEXT
Pat_6D96:
	REPEAT 4
	INSTR 11
	LEN 28
	NOTE G_, 2
	INSTR 12
	LEN 14
	NOTE D_, 3
	INSTR 11
	LEN 28
	NOTE Gsh, 2
	INSTR 12
	LEN 14
	NOTE Gsh, 2
	INSTR 11
	NOTE Dsh, 3
	INSTR 12
	NOTE Gsh, 2
	INSTR 11
	REPEAT_END
	NEXT
Pat_6DAA:
	REPEAT 4
	INSTR 11
	LEN 28
	NOTE C_, 3
	INSTR 12
	LEN 14
	NOTE G_, 3
	INSTR 11
	LEN 28
	NOTE Csh, 3
	INSTR 12
	LEN 14
	NOTE Csh, 3
	INSTR 11
	NOTE Gsh, 3
	INSTR 12
	NOTE Csh, 3
	REPEAT_END
	NEXT
Pat_6DBD:
	REPEAT 4
	INSTR 11
	LEN 28
	NOTE Ash, 2
	INSTR 12
	LEN 14
	NOTE F_, 3
	INSTR 11
	LEN 28
	NOTE B_, 2
	INSTR 12
	LEN 14
	NOTE B_, 2
	INSTR 11
	NOTE Fsh, 3
	INSTR 12
	NOTE B_, 2
	REPEAT_END
	NEXT
Pat_6DD0:
	REPEAT 3
	INSTR 11
	LEN 28
	NOTE Ash, 2
	INSTR 12
	LEN 14
	NOTE F_, 3
	INSTR 11
	LEN 28
	NOTE B_, 2
	INSTR 12
	LEN 14
	NOTE B_, 2
	INSTR 11
	NOTE Fsh, 3
	INSTR 12
	NOTE B_, 2
	REPEAT_END
	INSTR 11
	LEN 28
	NOTE Ash, 2
	INSTR 12
	LEN 14
	NOTE F_, 3
	INSTR 11
	LENGTH $46
	NOTE B_, 2
	NEXT
Pat_6DED:
	CH_TRANSPOSE $0C
	LEN 14
	REPEAT 4
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE D_, 2
	NOTE A_, 2
	NOTE Ash, 2
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE Ash, 2
	INSTR 14
	NOTE Dsh, 4
	INSTR 0
	NOTE Ash, 2
	REPEAT_END
	NEXT
Pat_6E01:
	REPEAT 4
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE D_, 4
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE G_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE Dsh, 4
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE Dsh, 4
	REPEAT_END
	NEXT
Pat_6E14:
	REPEAT 4
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE G_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE Csh, 4
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE Csh, 4
	REPEAT_END
	NEXT
Pat_6E27:
	REPEAT 4
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE Ash, 4
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE F_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE B_, 4
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE B_, 4
	REPEAT_END
	NEXT
Pat_6E3A:
	REPEAT 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE Ash, 4
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE F_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE B_, 4
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE B_, 4
	REPEAT_END
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE Ash, 4
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE F_, 4
	INSTR 2
	LENGTH $38
	NOTE E_, 3
	NEXT
Pat_6E59:
	DRUMS $07, DrumPat_6F48
	HWENV $D5, $00
	DUTY_75
	AUTODUTY $07
	ARP_OFF
	REPEAT 3
	LEN 42
	NOTE D_, 2
	LENGTH $46
	NOTE Dsh, 2
	REPEAT_END
	LEN 42
	NOTE A_, 2
	NOTE Ash, 2
	LEN 28
	NOTE Dsh, 3
	NEXT
Pat_6E71:
	DRUMS $07, DrumPat_6F6E
	LEN 14
	REST
	CH_TRANSPOSE $0C
	VIBRATO $14, $02, $04
	AUTODUTY $00
	ARP_OFF
	HWENV $59, $04, $80
	DUTY_75
	ARP_OFF
	RELEASE $77, $82
	NOTE D_, 3
	NOTE Dsh, 3
	NOTE F_, 3
	LEN 22
	NOTE G_, 3
	LEN 3
	NOTE A_, 3
	NOTE G_, 3
	LEN 14
	NOTE F_, 3
	NOTE Dsh, 3
	LEN 28
	NOTE D_, 3
	LEN 14
	NOTE C_, 3
	NOTE D_, 3
	NOTE Dsh, 3
	NOTE D_, 3
	LEN 28
	NOTE Ash, 3
	LENGTH $7E
	NOTE A_, 3
	INSTR 9
	LEN 7
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	LEN 14
	NOTE Dsh, 3
	NOTE D_, 3
	NOTE Ash, 3
	NOTE A_, 3
	NEXT
Pat_6EAE:
	LEN 14
	WAIT
	HWENV $59, $04, $80
	DUTY_75
	ARP_OFF
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	LEN 22
	NOTE C_, 4
	LEN 3
	NOTE D_, 4
	NOTE C_, 4
	LEN 14
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE Gsh, 3
	LENGTH $70
	NOTE G_, 3
	INSTR 9
	LEN 21
	NOTE G_, 3
	NOTE Fsh, 3
	NOTE F_, 3
	NOTE E_, 3
	LEN 14
	NOTE Dsh, 3
	NOTE D_, 3
	NEXT
Pat_6ED6:
	CH_TRANSPOSE $00
	HWENV $59, $04, $80
	DUTY_50
	ARP_OFF
	LENGTH $46
	NOTE C_, 5
	LEN 14
	NOTE G_, 4
	NOTE C_, 5
	LEN 42
	NOTE Ash, 4
	LEN 28
	NOTE Gsh, 4
	LEN 20
	NOTE G_, 4
	LEN 4
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 14
	NOTE F_, 4
	LEN 28
	NOTE G_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE C_, 4
	LEN 28
	NOTE Csh, 4
	LEN 14
	NOTE F_, 4
	NOTE Gsh, 4
	LEN 28
	NOTE G_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE Csh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Ash, 4
	NEXT
Pat_6F04:
	LEN 42
	NOTE F_, 4
	LENGTH $46
	NOTE Dsh, 4
	LEN 14
	NOTE E_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	LEN 28
	NOTE Fsh, 4
	LEN 14
	NOTE Dsh, 4
	NOTE Fsh, 3
	LENGTH $38
	NOTE Ash, 3
	NOTE B_, 3
	LEN 14
	NOTE A_, 3
	NOTE Ash, 3
	NOTE B_, 3
	NOTE Csh, 4
	LEN 22
	NOTE B_, 3
	LEN 3
	NOTE Csh, 4
	NOTE B_, 3
	LEN 42
	NOTE Ash, 3
	NEXT
Pat_6F23:
	HWENV $A7, $00
	AUTODUTY $07
	RELEASE $00
	REPEAT 2
	ARP 5
	LEN 42
	NOTE Ash, 4
	ARP 4
	LENGTH $46
	NOTE B_, 4
	REPEAT_END
	ARP 5
	LEN 42
	NOTE Ash, 3
	ARP 4
	LENGTH $46
	NOTE B_, 3
	ARP 5
	LEN 42
	NOTE Ash, 3
	ARP 4
	LENGTH $46
	DRUMS_OFF
	CALL_CODE Drum7
	NOTE B_, 3
	AUTODUTY $00
	NEXT
DrumPat_6F48:
	db DRUM_LEVEL + 13, DRUM_REPEAT + 3, 1, 0, 6, 0, 4, 0
	db 6, 0, DRUM_REPEAT_END, 1, 0, 6, 0, 4
	db 0, 4, 0, DRUM_REPEAT + 3, 5, 0, 6, 0
	db 4, 0, 6, 0, DRUM_REPEAT_END, 1, 4, 5
	db 0, 4, 0, 6, 0, DRUM_LOOP
DrumPat_6F6E:
	db DRUM_LEVEL + 14, DRUM_REPEAT + 3, 1, 0, 6, 0, 9, 0
	db 6, 0, DRUM_REPEAT_END, 1, 0, 6, 0, 9
	db 0, 4, 0, DRUM_REPEAT + 3, 5, 0, 6, 0
	db 9, 0, 6, 0, DRUM_REPEAT_END, 1, 0, 5
	db 6, 9, 0, 5, 6, DRUM_LOOP

; Song 1: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong1:
	call StopAll
	ld de, Song1_Ch1
	call L48F0
	ld de, Song1_Ch3
	call L490C
	ld de, Song1_Ch2
	jp L48FE
Song1_Ch1:
	dw Pat_6FEF
Loop_6FAB:
	dw Pat_6FEF
	dw Pat_7011
	dw Pat_6FEF
	dw Pat_7011
	dw Pat_703C
	dw Pat_7073
	dw Pat_7077
	dw Pat_7077
	dw Pat_7077
	dw Pat_703C
	ORDER_LOOP Loop_6FAB
Song1_Ch3:
	dw Pat_7146
Loop_6FC5:
	dw Pat_70B0
	dw Pat_70D8
	dw Pat_70B0
	dw Pat_70EE
	dw Pat_7105
	dw Pat_7126
	dw Pat_7126
	dw Pat_7126
	dw Pat_7126
	dw Pat_7152
	ORDER_LOOP Loop_6FC5
Song1_Ch2:
	dw Pat_72EA
Loop_6FDF:
	dw Pat_72EA
	dw Pat_7188
	dw Pat_72EA
	dw Pat_7188
	dw Pat_7191
	dw Pat_71C7
	ORDER_LOOP Loop_6FDF
Pat_6FEF:
	DRUMS $09, DrumPat_7312
	HWENV $F1, $09, $65
	ARP 6
	DUTY_50
	REPEAT 2
	LEN 27
	NOTE A_, 2
	LEN 18
	NOTE A_, 2
	LEN 9
	NOTE G_, 2
	LEN 36
	NOTE A_, 2
	LEN 9
	NOTE E_, 2
	NOTE G_, 2
	LEN 27
	NOTE A_, 2
	LEN 18
	NOTE A_, 2
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	REPEAT_END
	NEXT
Pat_7011:
	LEN 27
	NOTE G_, 2
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE F_, 2
	LEN 36
	NOTE G_, 2
	LEN 9
	NOTE D_, 2
	NOTE F_, 2
	LEN 27
	NOTE G_, 2
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE F_, 2
	LEN 18
	NOTE G_, 2
	NOTE F_, 2
	NOTE D_, 2
	LEN 27
	NOTE A_, 2
	LEN 18
	NOTE A_, 2
	LEN 9
	NOTE G_, 2
	LEN 36
	NOTE A_, 2
	LEN 9
	NOTE E_, 2
	NOTE G_, 2
	LEN 27
	NOTE A_, 2
	LEN 18
	NOTE A_, 2
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	NEXT
Pat_703C:
	DRUMS $09, DrumPat_7304
	LEN 27
	NOTE A_, 2
	LEN 18
	NOTE A_, 2
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE A_, 2
	NOTE A_, 3
	LEN 9
	NOTE E_, 2
	NOTE G_, 2
	LEN 27
	NOTE A_, 2
	LEN 18
	NOTE A_, 2
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE A_, 2
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE A_, 2
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE A_, 2
	NOTE A_, 3
	LEN 9
	NOTE E_, 2
	NOTE G_, 2
	LEN 18
	NOTE A_, 2
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE A_, 2
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE A_, 2
	LEN 9
	NOTE D_, 3
	NOTE C_, 3
	NOTE A_, 2
	NOTE G_, 2
	NEXT
Pat_7073:
	DRUMS $09, DrumPat_72FC
Pat_7077:
	LEN 18
	NOTE D_, 2
	LEN 9
	NOTE D_, 2
	LEN 18
	NOTE D_, 3
	LEN 9
	NOTE D_, 2
	LEN 18
	NOTE F_, 2
	NOTE G_, 2
	LEN 9
	NOTE F_, 2
	NOTE G_, 2
	LEN 18
	NOTE D_, 2
	LEN 9
	NOTE D_, 2
	LEN 18
	NOTE D_, 3
	LEN 9
	NOTE D_, 2
	LEN 18
	NOTE F_, 2
	NOTE G_, 2
	LEN 9
	NOTE A_, 2
	NOTE C_, 3
	LEN 18
	NOTE A_, 2
	LEN 9
	NOTE A_, 2
	LEN 18
	NOTE A_, 3
	LEN 9
	NOTE A_, 2
	LEN 18
	NOTE C_, 3
	NOTE D_, 3
	LEN 9
	NOTE C_, 3
	NOTE D_, 3
	LEN 18
	NOTE A_, 2
	LEN 9
	NOTE A_, 2
	LEN 18
	NOTE A_, 3
	LEN 9
	NOTE A_, 2
	LEN 18
	NOTE C_, 3
	NOTE D_, 3
	LEN 9
	NOTE C_, 3
	NOTE D_, 3
	NEXT
Pat_70B0:
	VOLENV 15, $11, $1A, $15
	ARP_OFF
	VIBRATO $12, $01, $05
	ARP 6
	CH_TRANSPOSE $0C
	WAVE Wave_7CDF
	LENGTH $48
	NOTE A_, 3
	LEN 27
	NOTE B_, 3
	LEN 9
	NOTE A_, 3
	LENGTH $48
	NOTE B_, 3
	LEN 18
	NOTE C_, 4
	NOTE B_, 3
	LENGTH $48
	NOTE C_, 4
	LEN 27
	NOTE D_, 4
	LEN 9
	NOTE C_, 4
	LENGTH $36
	NOTE D_, 4
	NOTE E_, 4
	NEXT
Pat_70D8:
	LENGTH $90
	NOTE B_, 3
	LEN 9
	NOTE G_, 3
	NOTE A_, 3
	LEN 18
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	LENGTH $48
	NOTE A_, 3
	LEN 36
	NOTE G_, 3
	LENGTH $5A
	NOTE E_, 3
	LEN 9
	NOTE E_, 3
	NOTE G_, 3
	NEXT
Pat_70EE:
	LENGTH $90
	NOTE B_, 3
	LEN 9
	NOTE G_, 3
	NOTE A_, 3
	LEN 18
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	LENGTH $48
	NOTE A_, 3
	LEN 18
	NOTE G_, 3
	NOTE B_, 3
	LENGTH $48
	NOTE A_, 3
	LEN 18
	NOTE G_, 4
	NOTE B_, 4
	NEXT
Pat_7105:
	LENGTH $D8
	NOTE A_, 4
	CH_TRANSPOSE $0C
	INSTR 15
	LEN 18
	NOTE A_, 3
	LEN 9
	NOTE A_, 3
	INSTR 14
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE C_, 4
	LEN 18
	NOTE B_, 3
	NOTE B_, 3
	NOTE Ash, 3
	INSTR 15
	NOTE A_, 5
	LEN 9
	NOTE A_, 5
	INSTR 14
	LEN 18
	NOTE C_, 6
	LEN 9
	NOTE C_, 6
	LEN 18
	NOTE B_, 5
	NOTE B_, 5
	NOTE Ash, 5
	NEXT
Pat_7126:
	LEN 18
	CH_TRANSPOSE $0C
	REPEAT 4
	INSTR 2
	LEN 18
	NOTE A_, 3
	INSTR 15
	LEN 9
	NOTE D_, 4
	INSTR 1
	LEN 18
	NOTE B_, 3
	INSTR 15
	LEN 9
	NOTE D_, 4
	REPEAT_END
	REPEAT 4
	INSTR 2
	LEN 18
	NOTE A_, 3
	INSTR 15
	LEN 9
	NOTE A_, 4
	INSTR 1
	LEN 18
	NOTE B_, 3
	INSTR 15
	LEN 9
	NOTE A_, 4
	REPEAT_END
	NEXT
Pat_7146:
	CH_TRANSPOSE $0C
	VOLENV 5, $00, $00, $00
	WAVE Wave_7D8F
	PAT_GOTO Pat_72F4
Pat_7152:
	INSTR 15
	LEN 18
	NOTE A_, 4
	LEN 9
	NOTE A_, 4
	ARP 4
	LEN 18
	NOTE C_, 5
	LEN 9
	NOTE C_, 5
	LEN 18
	NOTE B_, 4
	NOTE B_, 4
	NOTE Ash, 4
	ARP 5
	NOTE A_, 4
	LEN 9
	NOTE A_, 4
	ARP 4
	LEN 18
	NOTE C_, 5
	LEN 9
	NOTE C_, 5
	LEN 18
	NOTE B_, 4
	NOTE B_, 4
	NOTE Ash, 4
	ARP 5
	NOTE A_, 4
	LEN 9
	NOTE A_, 4
	ARP 4
	LEN 18
	NOTE C_, 5
	LEN 9
	NOTE C_, 5
	LEN 18
	NOTE B_, 4
	NOTE B_, 4
	NOTE Ash, 4
	ARP 5
	NOTE A_, 4
	LEN 9
	NOTE A_, 4
	ARP 4
	LEN 18
	NOTE C_, 5
	LEN 9
	NOTE C_, 5
	LEN 18
	NOTE B_, 4
	NOTE B_, 4
	NOTE Ash, 4
	NEXT
Pat_7188:
	ARP 4
	LENGTH $6C
	NOTE G_, 3
	NOTE G_, 4
	ARP 5
	NOTE A_, 3
	NOTE A_, 4
	NEXT
Pat_7191:
	INSTR 5
	LEN 18
	NOTE A_, 4
	LEN 9
	NOTE A_, 4
	INSTR 4
	LEN 18
	NOTE C_, 5
	LEN 9
	NOTE C_, 5
	LEN 18
	NOTE B_, 4
	NOTE B_, 4
	NOTE Ash, 4
	INSTR 5
	NOTE A_, 4
	LEN 9
	NOTE A_, 4
	INSTR 4
	LEN 18
	NOTE C_, 5
	LEN 9
	NOTE C_, 5
	LEN 18
	NOTE B_, 4
	NOTE B_, 4
	NOTE Ash, 4
	INSTR 5
	NOTE A_, 4
	LEN 9
	NOTE A_, 4
	INSTR 4
	LEN 18
	NOTE C_, 5
	LEN 9
	NOTE C_, 5
	LEN 18
	NOTE B_, 4
	NOTE B_, 4
	NOTE Ash, 4
	INSTR 5
	NOTE A_, 4
	LEN 9
	NOTE A_, 4
	INSTR 4
	LEN 18
	NOTE C_, 5
	LEN 9
	NOTE C_, 5
	LEN 18
	NOTE B_, 4
	NOTE B_, 4
	NOTE Ash, 4
	NEXT
Pat_71C7:
	LEN 9
	WAIT
	AUTODUTY $00
	DUTY_50
	ARP_OFF
	VIBRATO $0C, $02, $05
	HWENV $90, $00
	RELEASE $92, $50
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 18
	ARP 3
	NOTE G_, 4
	ARP_OFF
	NOTE G_, 4
	LEN 9
	NOTE E_, 4
	NOTE F_, 4
	LEN 18
	ARP 3
	NOTE Ash, 4
	ARP_OFF
	NOTE A_, 4
	LEN 9
	NOTE F_, 4
	NOTE G_, 4
	LEN 18
	ARP 3
	NOTE D_, 5
	ARP_OFF
	LEN 9
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	LENGTH $3F
	NOTE B_, 4
	LEN 9
	NOTE C_, 5
	NOTE A_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 45
	NOTE E_, 4
	LEN 9
	NOTE E_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	LEN 3
	NOTE B_, 3
	NOTE C_, 4
	LEN 12
	NOTE B_, 3
	LEN 9
	NOTE A_, 3
	WAIT2
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE C_, 4
	LEN 18
	ARP 3
	NOTE C_, 4
	ARP_OFF
	NOTE A_, 4
	LEN 9
	NOTE G_, 4
	NOTE E_, 4
	LEN 18
	ARP 3
	NOTE Dsh, 4
	ARP_OFF
	NOTE C_, 5
	LEN 9
	NOTE A_, 4
	NOTE F_, 4
	LEN 18
	ARP 3
	NOTE F_, 4
	ARP_OFF
	LEN 9
	NOTE E_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 6
	LEN 3
	NOTE A_, 5
	NOTE C_, 6
	NOTE A_, 5
	LEN 9
	NOTE E_, 5
	NOTE B_, 5
	LEN 3
	NOTE G_, 5
	NOTE B_, 5
	NOTE G_, 5
	LEN 9
	NOTE D_, 5
	NOTE A_, 5
	LEN 3
	NOTE E_, 5
	NOTE A_, 5
	NOTE E_, 5
	LEN 9
	NOTE C_, 5
	NOTE G_, 5
	LEN 3
	NOTE D_, 5
	NOTE G_, 5
	NOTE D_, 5
	LEN 9
	NOTE B_, 4
	NOTE E_, 5
	LEN 3
	NOTE C_, 5
	NOTE E_, 5
	NOTE C_, 5
	LEN 9
	NOTE A_, 4
	NOTE D_, 5
	LEN 3
	NOTE B_, 4
	NOTE D_, 5
	NOTE B_, 4
	LEN 9
	NOTE E_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE B_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE D_, 5
	NOTE F_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE B_, 4
	NOTE F_, 4
	LEN 3
	NOTE A_, 4
	NOTE B_, 4
	LEN 21
	NOTE A_, 4
	LEN 9
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE B_, 4
	NOTE C_, 5
	LEN 27
	NOTE A_, 4
	LEN 9
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	LEN 18
	ARP 3
	NOTE F_, 4
	ARP_OFF
	LEN 9
	NOTE A_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE G_, 4
	LEN 18
	ARP 3
	NOTE G_, 4
	ARP_OFF
	LEN 9
	NOTE B_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 18
	ARP 3
	NOTE A_, 4
	ARP_OFF
	LEN 9
	NOTE C_, 5
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE G_, 5
	LEN 36
	NOTE A_, 5
	LEN 9
	NOTE B_, 5
	NOTE A_, 5
	LEN 27
	NOTE B_, 5
	LEN 18
	NOTE C_, 6
	LEN 9
	NOTE B_, 5
	LEN 36
	NOTE C_, 6
	LEN 9
	NOTE D_, 6
	NOTE C_, 6
	LEN 18
	NOTE D_, 6
	LEN 9
	NOTE E_, 6
	ARP 3
	NOTE D_, 6
	ARP_OFF
	NOTE G_, 6
	NOTE A_, 6
	LENGTH $3F
	NOTE A_, 5
	LEN 9
	NOTE A_, 4
	NOTE D_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE A_, 5
	LEN 27
	NOTE A_, 4
	LEN 9
	NOTE E_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE G_, 4
	RELEASE $00
	HWENV $90, $48, $97
	LENGTH $D8
	NOTE A_, 4
	INSTR 5
	LEN 18
	NOTE A_, 3
	LEN 9
	NOTE A_, 3
	INSTR 4
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE C_, 4
	LEN 18
	NOTE B_, 3
	NOTE B_, 3
	NOTE Ash, 3
	INSTR 5
	NOTE A_, 5
	LEN 9
	NOTE A_, 5
	INSTR 4
	LEN 18
	NOTE C_, 6
	LEN 9
	NOTE C_, 6
	LEN 18
	NOTE B_, 5
	NOTE B_, 5
	NOTE Ash, 5
	NEXT
Pat_72EA:
	HWENV $1C, $24, $A7
	AUTODUTY $09
	VIBRATO $0C, $02, $05
Pat_72F4:
	ARP 5
	LENGTH $6C
	NOTE A_, 3
	NOTE A_, 4
	NOTE A_, 3
	NOTE A_, 4
	NEXT
DrumPat_72FC:
	db DRUM_LEVEL + 13, 1, 6, 6, 9, 6, 6, DRUM_LOOP
DrumPat_7304:
	db DRUM_LEVEL + 13, 1, 0, 6, 4, 0, 6, 1
	db 0, 4, 0, 6, 6, DRUM_LOOP
DrumPat_7312:
	db DRUM_LEVEL + 14, 6, 0, 0, 6, 0, 6, 6
	db 0, 0, 0, 6, 6, 6, 0, 0
	db 6, 0, 6, 6, 0, 6, 0, 6
	db 0, DRUM_LOOP

; Instrument table 1, entries 1..21 (the song routines point 2 bytes before:
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
	dw Instr1_17
	dw Instr1_18
	dw Instr1_19
	dw Instr1_20
Instr1_0:
	VOLENV 11, $11, $1A, $11
	WAVE Wave_7CBF
	END
Instr1_1:
	VOLENV 12, $11, $1F, $12
	GLIDE $FF
	WAVE Wave_7D7F
	END
Instr1_2:
	VOLENV 15, $14, $2F, $11
	ARP 15
	WAVE Wave_7D7F
	END
Instr1_3:
	VOLENV 15, $11, $1F, $13
	GLIDE $FE
	WAVE Wave_7D7F
	END
Instr1_4:
	HWENV $C2, $04, $64
	DUTY_75
	ARP 4
	END
Instr1_5:
	HWENV $C2, $04, $64
	DUTY_75
	ARP 5
	END
Instr1_6:
	HWENV $C1, $07, $66
	DUTY_75
	END
Instr1_7:
	HWENV $B1, $0E, $91
	ARP 27
	END
Instr1_8:
	HWENV $F3, $00
	ARP 2
	END
Instr1_9:
	HWENV $C1, $04, $45
	DUTY_12
	ARP 0
	END
Instr1_10:
	VOLENV 15, $11, $1F, $12
	ARP 27
	WAVE Wave_7CDF
	END
Instr1_11:
	HWENV $F1, $07, $75
	ARP 6
	DUTY_50
	END
Instr1_12:
	HWENV $D1, $04, $53
	ARP 6
	DUTY_50
	END
Instr1_13:
	HWENV $D1, $07, $77
	ARP_OFF
	END
Instr1_14:
	VOLENV 12, $11, $1F, $12
	ARP 4
	WAVE Wave_7D3F
	END
Instr1_15:
	VOLENV 12, $11, $1F, $12
	ARP 5
	WAVE Wave_7D3F
	END
Instr1_16:
	VOLENV 12, $11, $1F, $13
	ARP 6
	WAVE Wave_7D6F
	END
Instr1_17:
	VOLENV 12, $10, $1F, $11
	ARP 6
	WAVE Wave_7CDF
	END
Instr1_18:
	VOLENV 12, $11, $1F, $11
	WAVE Wave_7D9F
	END
Instr1_19:
	VOLENV 15, $11, $1F, $14
	ARP 0
	WAVE Wave_7CAF
	END
Instr1_20:
	VOLENV 15, $11, $1F, $11
	ARP 0
	WAVE Wave_7CAF
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
	dw Arp14
	dw Arp15
	dw Arp16
	dw Arp17
	dw Arp18
	dw Arp19
	dw Arp20
	dw Arp20
	dw Arp20
	dw Arp23
	dw Arp24
	dw Arp25
	dw Arp26
	dw Arp27
Arp0:
	db $18, $0C, $00, ARP_HOLD
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
	db $0C, $00, ARP_HOLD
Arp7:
	db $0C, $00, $00, $00, $00, $00, $00, $00
	db $00, ARP_LOOP
Arp8:
	db $01, $00, $02, $01, $03, $01, $00, ARP_LOOP
Arp9:
	db $0C, $0C, $00, ARP_HOLD
Arp10:
	db $0C, $00, $00, $00, $00, $00, $00, $00
	db $0C, ARP_HOLD
Arp11:
	db $0C, $00, $00, $00, $00, $00, $00, $0C
	db $0C, $0C, $0C, $0C, $0C, $0C, ARP_HOLD
Arp12:
	db $00, $01, $02, $01, $00, ARP_HOLD
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
	db $00, $00, $00, $0C, $0C, $0C, $0C, $0C
	db $0C, $0C, $0C, $0C, $0C, $0C, ARP_LOOP
Arp17:
	db $18, $0C, $0C, ARP_LOOP
Arp18:
	db $03, $00, $07, ARP_LOOP
Arp19:
	db $07, $0C, $03, $00, $00, $00, $00, $00
	db $00, $07, $0C, $03, $00, $00, $00, $00
	db $00, $00, ARP_HOLD
Arp20:
	db $13, $00, ARP_HOLD
Arp23:
	db $0C, $0C, $00, $00, ARP_LOOP
Arp24:
	db $0C, $01, $00, $00, $00, $00, $00, $00
	db $00, ARP_LOOP
Arp25:
	db $0C, $0C, $00, $00, $00, $00, $00, $00
	db ARP_LOOP
Arp26:
	db $0C, $0C, $00, $00, $00, $00, $00, ARP_LOOP
Arp27:
	db $0C, $13, $00, $00, $00, $00, $00, $00
	db $00, $00
SfxTable_m2:
	db $00, ARP_LOOP

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
	dw Sfx30
	dw Sfx31

; Sound effect 1
Sfx01:
	VOLENV 11, $11, $1F, $11
	WAVE Wave_7D0F
	GLIDE $02
	LEN 12
	NOTE A_, 2
	END

; Sound effect 4
Sfx04:
	VOLENV 12, $11, $1F, $13
	VIBRATO $00, $01, $04
	WAVE Wave_7D2F
	CALL_CODE Code_7998
	GLIDE $FC
	LEN 5
	NOTE A_, 4
	CALL_CODE Code_7998
	GLIDE $08
	WAIT
	CALL_CODE Code_7971
	GLIDE_OFF
	LEN 10
	WAIT
	GLIDE $FF
	WAIT
	END

; Sound effect 3
Sfx03:
	WAVE Wave_7D2F
	GLIDE $04
	LEN 10
	CH_TRANSPOSE $F4
	ARP 0
	VOLENV 5, $00, $00, $00
	NOTE A_, 3
	VOLENV 10, $00, $00, $00
	NOTE A_, 3
	VOLENV 15, $00, $00, $00
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	VOLENV 10, $00, $00, $00
	NOTE A_, 3
	VOLENV 5, $00, $00, $00
	NOTE A_, 3
	NOTE A_, 3
	END

; Sound effect 7
Sfx07:
	VOLENV 15, $11, $1F, $13
	WAVE Wave_7D8F
	CALL_CODE Code_7AD0
	LEN 5
	NOTE C_, 4
	CALL_CODE Code_7C3A
	LEN 1
	REST
	LEN 10
	GLIDE $FE
	NOTE Dsh, 5
	VOLENV 5, $11, $1F, $13
	NOTE Dsh, 5
	VOLENV 5, $11, $1F, $13
	NOTE Dsh, 5
	END

; Sound effect 8
Sfx08:
	LEN 5
	ARP 6
	WAVE Wave_7D6F
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

; Sound effect 9
Sfx09:
	CALL_CODE Code_7998
	VOLENV 15, $00, $00, $00
	ARP 3
	WAVE Wave_7DDF
	LEN 3
	REST
	CALL_CODE Code_7A27
	LEN 5
	GLIDE $FE
	NOTE E_, 3
	END

; Sound effect 10
Sfx10:
	CALL_CODE Code_7B3C
	VOLENV 11, $11, $1F, $12
	VIBRATO $01, $06, $03
	LEN 30
	WAVE Wave_7D0F
	NOTE C_, 5
	END

; Sound effect 11
Sfx11:
	CALL_CODE Code_79BF
	VOLENV 11, $11, $1F, $14
	WAVE Wave_7D4F
	LEN 5
	GLIDE $FB
	NOTE C_, 5
	END

; Sound effect 31
Sfx31:
	CALL_CODE Code_79BF
	END

; Sound effect 12
Sfx12:
	CALL_CODE Code_7998
	WAVE Wave_7D4F
	VOLENV 15, $11, $1F, $11
	LEN 5
	GLIDE $04
	NOTE A_, 2
	GLIDE $65
	WAIT
	WAIT
	END

; Sound effect 13
Sfx13:
	CALL_CODE Code_7971
	VOLENV 11, $11, $1F, $13
	WAVE Wave_7D2F
	LEN 23
	SLIDE_DOWN $03
	NOTE A_, 4
	END

; Sound effect 14
Sfx14:
	CALL_CODE Code_78D7
	WAVE Wave_7D0F
	VOLENV 15, $11, $1F, $11
	ARP 0
	LEN 7
	GLIDE $FF
	NOTE Fsh, 2
	END

; Sound effect 16
Sfx16:
	VOLENV 15, $0F, $1F, $14
	LEN 3
	ARP 5
	GLIDE $01
	WAVE Wave_7DAF
	LEN 40
	NOTE A_, 4
	END

; Sound effect 15
Sfx15:
	VOLENV 15, $11, $5F, $11
	CH_TRANSPOSE $F4
	ARP 2
	WAVE Wave_7DAF
	LEN 7
	NOTE A_, 5
	LEN 6
	NOTE A_, 5
	LEN 5
	NOTE A_, 5
	LEN 4
	NOTE A_, 5
	LEN 3
	NOTE A_, 5
	LEN 2
	NOTE A_, 5
	VOLENV 10, $11, $5F, $11
	NOTE A_, 5
	NOTE A_, 5
	VOLENV 5, $11, $5F, $11
	NOTE A_, 5
	NOTE A_, 5
	END

; Sound effect 19
Sfx19:
	VOLENV 15, $00, $00, $00
	GLIDE $FC
	LEN 10
	CH_TRANSPOSE $3F
	ARP 6
	WAVE Wave_7DAF
	NOTE A_, 2
	VOLENV 10, $00, $00, $00
	NOTE A_, 2
	VOLENV 5, $00, $00, $00
	NOTE A_, 2
	END

; Sound effect 28
Sfx28:
	CALL_CODE Code_7B06
	VOLENV 15, $11, $1F, $11
	WAVE Wave_7D0F
	LEN 6
	GLIDE $FD
	NOTE D_, 4
	END

; Sound effect 17
Sfx17:
	VOLENV 15, $00, $00, $00
	GLIDE $05
	LEN 10
	WAVE Wave_7DAF
	NOTE A_, 2
	VOLENV 10, $00, $00, $00
	NOTE A_, 2
	VOLENV 5, $00, $00, $00
	NOTE A_, 2
	END

; Sound effect 20
Sfx20:
	WAVE Wave_7E0F
	VOLENV 15, $00, $00, $00
	VIBRATO $00, $20, $02
	GLIDE $FF
	CH_TRANSPOSE $08
	LEN 15
	NOTE C_, 5
	VOLENV 10, $00, $00, $00
	NOTE C_, 5
	VOLENV 5, $00, $00, $00
	NOTE C_, 5
	END

; Sound effect 21
Sfx21:
	VOLENV 15, $11, $1F, $12
	GLIDE $FD
	WAVE Wave_7D0F
	CALL_CODE Code_781D
	LEN 9
	NOTE E_, 3
	LEN 7
	NOTE E_, 3
	NOTE D_, 3
	END

; Sound effect 22
Sfx22:
	VOLENV 15, $00, $00, $00
	LEN 8
	CH_TRANSPOSE $F6
	ARP 2
	WAVE Wave_7DCF
	NOTE A_, 4
	WAVE Wave_7CEF
	NOTE A_, 4
	WAVE Wave_7DBF
	NOTE A_, 4
	WAVE Wave_7CFF
	NOTE A_, 4
	WAVE Wave_7DDF
	NOTE A_, 4
	END

; Sound effect 23
Sfx23:
	WAVE Wave_7D0F
	VOLENV 15, $11, $1F, $11
	CALL_CODE Code_784F
	LEN 5
	GLIDE $FE
	NOTE C_, 3
	GLIDE_OFF
	WAVE Wave_7CEF
	VOLENV 5, $1F, $00, $20
	CALL_CODE Code_787D
	LEN 21
	NOTE E_, 3
	END

; Sound effect 24
Sfx24:
	CALL_CODE Code_7C7D
	VOLENV 15, $11, $1F, $13
	WAVE Wave_7D0F
	GLIDE $FE
	LEN 10
	CH_TRANSPOSE $0C
	NOTE C_, 3
	VOLENV 10, $11, $1F, $13
	NOTE C_, 3
	VOLENV 5, $11, $1F, $13
	NOTE C_, 3
	END

; Sound effect 25
Sfx25:
	CALL_CODE Code_7C02
	VOLENV 15, $11, $1F, $11
	GLIDE $FF
	WAVE Wave_7D0F
	LEN 10
	NOTE G_, 2
	CALL_CODE Code_7C02
	NOTE G_, 2
	END

; Sound effect 29
Sfx29:
	CALL_CODE Code_7B6A
	END

; Sound effect 18
Sfx18:
	WAVE Wave_7D8F
	CALL_CODE Code_7A97
	VOLENV 15, $12, $1F, $12
	LEN 8
	GLIDE $FF
	NOTE A_, 4
	LEN 5
	VOLENV 10, $11, $1F, $12
	NOTE A_, 4
	END

; Sound effect 27
Sfx27:
	VOLENV 10, $15, $1F, $23
	VIBRATO $00, $02, $06
	WAVE Wave_7DEF
	ARP 8
	LEN 20
	NOTE A_, 5
	WAIT
	END

; Sound effect 26
Sfx26:
	CALL_CODE Code_7A27
	VOLENV 15, $00, $00, $00
	WAVE Wave_7CCF
	LEN 3
	GLIDE $FF
	NOTE A_, 5
	WAVE Wave_7DFF
	WAIT
	GLIDE $FE
	WAVE Wave_7E1F
	WAIT
	LEN 10
	WAVE Wave_7DFF
	VOLENV 10, $00, $00, $00
	NOTE E_, 5
	VOLENV 5, $00, $00, $00
	NOTE E_, 5
	END

; Unreferenced (4 bytes)
	db $7F, $3A, $7C, $68

; Sound effect 2
Sfx02:
	CALL_CODE Code_7BCE
	END

; Sound effect 5
Sfx05:
	VOLENV 15, $11, $2F, $11
	WAVE Wave_7D6F
	LEN 8
	NOTE C_, 6
	VOLENV 10, $11, $2F, $11
	NOTE C_, 6
	VOLENV 5, $11, $2F, $11
	NOTE C_, 6
	END

; Sound effect 6
Sfx06:
	LEN 4
	VOLENV 15, $11, $2F, $11
	WAVE Wave_7D6F
	LEN 4
	NOTE Gsh, 5
	LEN 1
	REST
	LEN 4
	NOTE Gsh, 6
	LEN 4
	VOLENV 10, $11, $2F, $11
	LEN 4
	NOTE Gsh, 5
	LEN 1
	REST
	LEN 4
	NOTE Gsh, 6
	VOLENV 5, $11, $2F, $11
	LEN 4
	NOTE Gsh, 5
	LEN 1
	REST
	LEN 4
	NOTE Gsh, 6
	END

; Sound effect 30
Sfx30:
	VOLENV 15, $11, $1F, $11
	CALL_CODE Code_7AD0
	WAVE Wave_7D0F
	LEN 12
	GLIDE $FE
	NOTE C_, 3
	END

; Unreferenced (39 bytes)
	db $C3, $11, $1F, $14, $79, $0F, $7D, $60, $04, $CA, $1F, $60, $FD, $CC, $65, $66
	db $68, $C1, $11, $10, $00, $79, $CF, $7D, $60, $02, $CB, $15, $61, $C9, $65, $60
	db $02, $65, $68, $7F, $09, $79, $68
Code_781D:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $28
	ld [wDrumHold], a
	ld a, HIGH(Noise43_7844)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7844)
	ld [wNoise43], a
	ld a, HIGH(Noise42_784A)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_784A)
	ld [wNoise42], a
	ret
Noise43_7844:
	db $57, $56, $54, $53, $47, $FF
Noise42_784A:
	db $F0, $F0, $60, $70, $F3
Code_784F:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $0A
	ld [wDrumHold], a
	ld a, HIGH(Noise43_7876)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7876)
	ld [wNoise43], a
	ld a, HIGH(Noise42_787A)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_787A)
	ld [wNoise42], a
	ret
Noise43_7876:
	db $4A, $5A, $50, $FF
Noise42_787A:
	db $F0, $D0, $B1
Code_787D:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $1E
	ld [wDrumHold], a
	ld a, $D2
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ld a, HIGH(Noise43_78AC)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_78AC)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_78AC:
	db $18, $3A, $47, $49, $2E, $2D, $1C, $28
	db $4A, $57, $39, $4E, $1D, $0C, $FF
Noise43_78BB:
	db $82, $64, $02, $37, $47, $24, $55, $71
	db $07, $44, $60, $36, $84, $82, $64, $02
	db $37, $47, $24, $55, $71, $07, $44, $60
	db $36, $86, $32, $FF
Code_78D7:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $13
	ld [wDrumHold], a
	call NoisePanCentre
	ld a, $F2
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ld a, HIGH(Noise43_78BB)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_78BB)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret

; Unreferenced noise-SFX starter: wNoiseOn = 1, noise pan $88, hold 19, then
; NoisePanCentre, NR42 = $F1 and NR44 = $80 written directly (an immediate hit),
; then an NR43 sequence with no NR42 sequence.
Unused_NoiseSfx_7909:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $13
	ld [wDrumHold], a
	call NoisePanCentre
	ld a, $F1
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ld a, HIGH(Noise43_78BB)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_78BB)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Unused_Noise_793B:
	ld a, $88
	ld [wNoisePan], a
	ld a, $08
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7962)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7962)
	ld [wNoise43], a
	ld a, HIGH(Noise42_796A)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_796A)
	ld [wNoise42], a
	ret
Noise43_7962:
	db $60, $52, $42, $41, $22, $11, $21, $FF
Noise42_796A:
	db $F0, $F0, $F0, $F0, $F0, $F0, $61
Code_7971:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7A00)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7A00)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7A1A)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7A1A)
	ld [wNoise42], a
	ret
Code_7998:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7A0D)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7A0D)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7A1A)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7A1A)
	ld [wNoise42], a
	ret
Code_79BF:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_79F3)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_79F3)
	ld [wNoise43], a
	ld a, HIGH(Noise42_79E6)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_79E6)
	ld [wNoise42], a
	ret
Noise42_79E6:
	db $F1, $A1, $FF, $FF, $FF, $FF, $43, $FF
	db $FF, $FF, $FF, $FF

; Unreferenced (1 bytes)
	db $FF
Noise43_79F3:
	db $51, $10, $20, $31, $32, $33, $53, $34
	db $14, $15, $15, $16, $FF
Noise43_7A00:
	db $10, $10, $20, $31, $32, $33, $33, $34
	db $34, $35, $35, $36, $FF
Noise43_7A0D:
	db $36, $35, $35, $34, $34, $33, $33, $32
	db $31, $20, $10, $10, $FF
Noise42_7A1A:
	db $5F, $FF, $FF, $FF, $FF, $FF, $A1, $FF
	db $FF, $FF, $FF, $FF

; Unreferenced (1 bytes)
	db $FF
Code_7A27:
	ld a, $88
	ld [wNoisePan], a
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7A4E)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7A4E)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7A54)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7A54)
	ld [wNoise42], a
	ret
Noise43_7A4E:
	db $00, $53, $71, $91, $31, $FF
Noise42_7A54:
	db $F2, $FF, $FF, $FF, $00
Unused_Noise_7A59:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0A
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7A80)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7A80)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7A8C)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7A8C)
	ld [wNoise42], a
	ret
Noise43_7A80:
	db $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0
	db $A0, $A0, $A0, $FF
Noise42_7A8C:
	db $F0, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $00
Code_7A97:
	ld a, $88
	ld [wNoisePan], a
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
	ld a, HIGH(Noise43_7AC6)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7AC6)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_7AC6:
	db $02, $92, $42, $42, $42, $42, $52, $65
	db $45, $FF
Code_7AD0:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7AF7)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7AF7)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7AFF)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7AFF)
	ld [wNoise42], a
	ret
Noise43_7AF7:
	db $02, $51, $61, $71, $91, $71, $60, $FF
Noise42_7AFF:
	db $F0, $F0, $F0, $F0, $F0, $70, $63
Code_7B06:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B2D)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B2D)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B35)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B35)
	ld [wNoise42], a
	ret
Noise43_7B2D:
	db $22, $51, $64, $81, $51, $41, $60, $FF
Noise42_7B35:
	db $F0, $F0, $F0, $F0, $F0, $70, $63
Code_7B3C:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B63)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B63)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B67)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B67)
	ld [wNoise42], a
	ret
Noise43_7B63:
	db $02, $51, $22, $FF
Noise42_7B67:
	db $F0, $A0, $45
Code_7B6A:
	ld a, $88
	ld [wNoisePan], a
	ld a, $19
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B91)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B91)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B97)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B97)
	ld [wNoise42], a
	ret
Noise43_7B91:
	db $02, $41, $61, $71, $11, $FF
Noise42_7B97:
	db $F0, $FF, $FF, $A0, $B2
Unused_Noise_7B9C:
	ld a, $88
	ld [wNoisePan], a
	ld a, $08
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7BC3)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7BC3)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7BC9)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7BC9)
	ld [wNoise42], a
	ret
Noise43_7BC3:
	db $00, $83, $60, $60, $31, $FF
Noise42_7BC9:
	db $F0, $FF, $FF, $FF, $D1
Code_7BCE:
	ld a, $88
	ld [wNoisePan], a
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7BF5)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7BF5)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7BFC)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7BFC)
	ld [wNoise42], a
	ret
Noise43_7BF5:
	db $41, $61, $61, $41, $71, $71, $FF
Noise42_7BFC:
	db $A1, $52, $00, $61, $52, $00
Code_7C02:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0A
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7C29)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7C29)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7C32)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7C32)
	ld [wNoise42], a
	ret
Noise43_7C29:
	db $78, $78, $78, $78, $58, $56, $56, $68
	db $FF
Noise42_7C32:
	db $A1, $FF, $11, $00, $81, $FF, $F2, $00
Code_7C3A:
	ld a, $88
	ld [wNoisePan], a
	ld a, $3C
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $02
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_7C6A)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7C6A)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7C74)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7C74)
	ld [wNoise42], a
	ret
Noise43_7C6A:
	db $67, $56, $45, $34, $23, $22, $11, $10
	db $20, $FF
Noise42_7C74:
	db $19, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $F3
Code_7C7D:
	ld a, $88
	ld [wNoisePan], a
	ld a, $19
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7CA4)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7CA4)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7CAA)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7CAA)
	ld [wNoise42], a
	ret
Noise43_7CA4:
	db $03, $83, $80, $80, $61, $FF
Noise42_7CAA:
	db $F0, $FF, $FF, $FF, $F2
Wave_7CAF:
	db $EC, $96, $31, $90, $00, $00, $00, $00
	db $24, $69, $CE, $FF, $FF, $FF, $FF, $FF
Wave_7CBF:
	db $02, $46, $8A, $CE, $FF, $DB, $DF, $FF
	db $EC, $A8, $64, $20, $FF, $FF, $FF, $FF
Wave_7CCF:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $00, $00, $00, $00
Wave_7CDF:
	db $8C, $FE, $ED, $B8, $53, $21, $10, $24
	db $84, $01, $12, $35, $8B, $DE, $EF, $8C
Wave_7CEF:
	db $B7, $40, $F4, $7B, $FD, $FF, $FE, $DC
	db $02, $46, $8A, $BD, $FD, $BA, $6F, $20
Wave_7CFF:
	db $B7, $4E, $F4, $FF, $DF, $FF, $ED, $C0
	db $24, $68, $AB, $DF, $DD, $DD, $6F, $20
Wave_7D0F:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF

; Unreferenced (16 bytes)
	db $00, $00, $00, $00, $CD, $EF, $FD, $EC, $00, $12, $21, $00, $DD, $DD, $DD, $DD
Wave_7D2F:
	db $00, $00, $00, $00, $00, $00, $FF, $FF
	db $00, $00, $00, $00, $00, $00, $FF, $FF
Wave_7D3F:
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $A8, $76, $67, $8A
Wave_7D4F:
	db $00, $00, $00, $00, $00, $00, $FF, $00
	db $00, $00, $00, $00, $00, $00, $FF, $00
Wave_7D5F:
	db $00, $00, $00, $CD, $EF, $FF, $FF, $FF
	db $04, $8C, $FF, $FF, $FF, $FF, $FF, $FF
Wave_7D6F:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $00, $FF, $FF, $FF
Wave_7D7F:
	db $FF, $FE, $ED, $B8, $53, $21, $10, $00
	db $00, $01, $12, $35, $8B, $DE, $EF, $FF
Wave_7D8F:
	db $63, $10, $00, $00, $00, $00, $01, $36
	db $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9
Wave_7D9F:
	db $63, $10, $01, $47, $74, $10, $01, $36
	db $9C, $EF, $FE, $B8, $8B, $EF, $FE, $C9
Wave_7DAF:
	db $63, $1F, $01, $47, $74, $10, $01, $36
	db $9C, $E0, $FE, $B8, $8B, $EF, $FE, $C9
Wave_7DBF:
	db $B7, $40, $04, $7B, $CD, $FF, $FE, $DC
	db $02, $46, $8A, $BD, $FD, $BA, $64, $20
Wave_7DCF:
	db $0F, $00, $F0, $F0, $F0, $F0, $00, $0F
	db $0F, $FF, $FF, $00, $FF, $F0, $0F, $0F
Wave_7DDF:
	db $BB, $2B, $BB, $2B, $BB, $5B, $2B, $BB
	db $2B, $BB, $BB, $72, $27, $EB, $BB, $B0
Wave_7DEF:
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $ED, $CB, $A9, $87, $65, $43, $21, $00
Wave_7DFF:
	db $04, $8B, $DE, $FF, $ED, $CB, $A9, $87
	db $65, $44, $44, $32, $11, $24, $7A, $74
Wave_7E0F:
	db $00, $00, $69, $FF, $FF, $F9, $64, $00
	db $03, $68, $B8, $60, $00, $04, $68, $60
Wave_7E1F:
	db $20, $24, $68, $AC, $EC, $A8, $64, $20
	db $24, $68, $A8, $64, $20, $24, $68, $64
Noise43_7E2F:
	db $02, $61, $71, $A1, $B1, $B1, $A1, $FF
Noise42_7E37:
	db $C1, $F0, $A0, $90, $70, $40, $33
Noise43_7E3E:
	db $06, $04, $03, $03, $07, $FF
Noise42_7E44:
	db $F0, $C0, $80, $60, $57
Noise43_7E49:
	db $04, $02, $01, $01, $FF
Noise42_7E4E:
	db $60, $40, $33, $FF
Noise43_7E52:
	db $04, $02, $01, $01, $FF
Noise42_7E57:
	db $A0, $60, $32, $FF
Noise43_7E5B:
	db $04, $02, $01, $FF
Noise42_7E5F:
	db $80, $FF, $63

; Unreferenced (1 bytes)
	db $FF
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7E2F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7E2F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7E37)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7E37)
	ld [wNoise42], a
	ret
Drum8:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7E9D)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7E9D)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7EA3)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7EA3)
	ld [wNoise42], a
	ret
Noise43_7E9D:
	db $04, $02, $01, $00, $00, $FF
Noise42_7EA3:
	db $30, $40, $60, $43, $42
Drum2:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7EC5)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7EC5)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7ECD)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7ECD)
	ld [wNoise42], a
	ret
Noise43_7EC5:
	db $60, $52, $42, $41, $22, $11, $04, $FF
Noise42_7ECD:
	db $F0, $F0, $F0, $A0, $70, $40, $51
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7E5B)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7E5B)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7E5F)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7E5F)
	ld [wNoise42], a
	ret
Drum5:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7E52)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7E52)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7E57)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7E57)
	ld [wNoise42], a
	ret
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7E49)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7E49)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7E4E)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7E4E)
	ld [wNoise42], a
	ret
Drum7:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7E3E)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7E3E)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7E44)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7E44)
	ld [wNoise42], a
	ret
Drum9:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7F65)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7F65)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7F71)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7F71)
	ld [wNoise42], a
	ret
Noise43_7F65:
	db $51, $41, $42, $42, $42, $42, $42, $42
	db $43, $44, $45, $FF
Noise42_7F71:
	db $F0, $63, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF
Drum10:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7F99)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7F99)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7F9C)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7F9C)
	ld [wNoise42], a
	ret
Noise43_7F99:
	db $51, $32, $FF
Noise42_7F9C:
	db $90, $61

; Unreferenced (15 bytes)
	db $51, $32, $32, $32, $32, $51, $32, $FF, $80, $51, $FF, $FF, $FF, $80, $51
FadeOutTable:
	db $77, $66, $55, $44, $33, $22, $11, $00
	db $80, FADE_END
FadeInTable:
	db $00, $11, $22, $33, $44, $55, $66, $77
	db FADE_END
DriverEndText:
	db "Final de la rutina de musica"

; Unreferenced (36 bytes)
	db $FF, $90, $61, $51, $32, $32, $32, $32, $51, $32, $FF, $80, $51, $FF, $FF, $FF
	db $80, $51, $77, $66, $55, $44, $33, $22, $11, $00, $80, $FF, $00, $11, $22, $33
	db $44, $55, $66, $77
