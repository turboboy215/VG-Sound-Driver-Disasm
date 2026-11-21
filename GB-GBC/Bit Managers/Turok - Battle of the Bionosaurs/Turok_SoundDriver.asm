; =====================================================================
; Turok: Battle of the Bionosaurs (UE) (M4) - Game Boy
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o turok.o Turok_SoundDriver.asm
;   rgblink -o turok.gb turok.o
;   python tools/cmp_banked.py turok.gb "Turok - Battle of the Bionosaurs (UE) (M4) [!].gb" 15:4000-7FFF
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

; Not reached: SetVolEnvBC, VOLENV from the four bytes at BC (start volume,
; attack, decay, rates), then ret. A helper for NOTE_HOOK routines; nothing in
; this game uses it.
Unused_SetVolEnvBC:
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

; Unreferenced (68 bytes)
	db $00, $00, $81, $F9, $00, $01, $00, $00, $74, $12, $81, $F9, $00, $02, $00, $00
	db $74, $0F, $81, $F9, $00, $03, $00, $00, $74, $0C, $EB, $0D, $80, $CC, $04, $EB
	db $08, $80, $CC, $08, $EB, $03, $80, $CC, $0C, $8B, $CA, $81, $E1, $00, $00, $03
	db $00, $74, $0A, $81, $F9, $00, $00, $01, $00, $74, $07, $EB, $08, $80, $CC, $03
	db $EB, $03, $80, $CC
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
	ld a, $72
	ld [wInstrTableHi], a
	ld a, $1A
	ld [wInstrTable], a

; StartMusicChN (de = order list): set wInstrTable to the one instrument table (in
; all three entries, so every song plays with it; 14 bytes apart, not 4), reset
; the page, mark it active, start its first pattern. StartMusicCh3 also stops the
; fade and the drums.
StartMusicCh1:
	ld h, $DC
	jr StartMusicCh
L48FE:
	ld a, $72
	ld [wInstrTableHi], a
	ld a, $1A
	ld [wInstrTable], a
StartMusicCh2:
	ld h, $DD
	jr StartMusicCh
L490C:
	ld a, $72
	ld [wInstrTableHi], a
	ld a, $1A
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
	add a, $CA
	ld l, a
	adc a, $73
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
	db $71, $7F
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

; Song 2: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong2:
	call StopAll
	ld de, Song2_Ch3
	call L490C
	ld de, Song2_Ch1
	call L48F0
	ld de, Song2_Ch2
	jp L48FE

; Unreferenced (1 bytes)
	db $C9
Song2_Ch3:
	dw Pat_4B8E
Loop_4B5A:
	dw Pat_4B96
	dw Pat_4BA7
	dw Pat_4B8E
	dw Pat_4B8E
	dw Pat_4B96
	dw Pat_4B96
	ORDER_LOOP Loop_4B5A
Song2_Ch1:
	dw Pat_4BCF
Loop_4B6C:
	dw Pat_4BCF
	dw Pat_4BF1
	dw Pat_4C2A
	dw Pat_4C2A
	dw Pat_4BCF
	dw Pat_4BCF
	ORDER_LOOP Loop_4B6C
Song2_Ch2:
	dw Pat_4C8D
Loop_4B7E:
	dw Pat_4C95
	dw Pat_4C95
	dw Pat_4CBA
	dw Pat_4CBA
	dw Pat_4CDB
	dw Pat_4CDB
	ORDER_LOOP Loop_4B7E
Pat_4B8E:
	DRUMS $07, DrumPat_4D10
	AUTOPAN $07
	CH_TRANSPOSE $0C
Pat_4B96:
	REPEAT 8
	INSTR 2
	LEN 14
	NOTE C_, 3
	INSTR 17
	LEN 7
	NOTE B_, 3
	INSTR 16
	NOTE C_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 17
	NOTE B_, 3
	NOTE B_, 2
	NOTE B_, 2
	REPEAT_END
	NEXT
Pat_4BA7:
	REPEAT 7
	INSTR 2
	LEN 14
	NOTE C_, 3
	INSTR 17
	LEN 7
	NOTE B_, 3
	INSTR 16
	NOTE C_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 17
	NOTE B_, 3
	NOTE B_, 2
	NOTE B_, 2
	REPEAT_END
	INSTR 2
	NOTE C_, 3
	DRUMS $07, DrumPat_4D1E
	AUTOPAN $00
	PAN_C
	INSTR 1
	NOTE G_, 3
	NOTE G_, 3
	INSTR 16
	NOTE C_, 3
	INSTR 1
	NOTE G_, 3
	NOTE G_, 3
	INSTR 17
	NOTE B_, 2
	INSTR 1
	NOTE G_, 3
	AUTOPAN $07
	NEXT
Pat_4BCF:
	INSTR 11
	LEN 21
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	LEN 14
	NOTE B_, 2
	NOTE Fsh, 2
	LEN 21
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	NOTE C_, 2
	LEN 21
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	LEN 14
	NOTE B_, 2
	NOTE Fsh, 2
	LEN 21
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	NOTE C_, 2
	NEXT
Pat_4BF1:
	INSTR 11
	LEN 14
	REPEAT 2
	NOTE B_, 2
	INSTR 12
	LEN 7
	NOTE A_, 2
	INSTR 11
	LEN 14
	NOTE B_, 2
	INSTR 12
	LEN 7
	NOTE A_, 2
	INSTR 11
	LEN 14
	NOTE B_, 2
	INSTR 12
	LEN 7
	NOTE A_, 2
	INSTR 11
	LEN 14
	NOTE B_, 2
	INSTR 12
	LEN 7
	NOTE A_, 2
	INSTR 11
	LEN 14
	NOTE B_, 2
	NOTE Fsh, 2
	NOTE F_, 2
	INSTR 12
	LEN 7
	NOTE E_, 2
	INSTR 11
	LEN 14
	NOTE F_, 2
	INSTR 12
	LEN 7
	NOTE E_, 2
	INSTR 11
	LEN 14
	NOTE F_, 2
	INSTR 12
	LEN 7
	NOTE E_, 2
	INSTR 11
	LEN 14
	NOTE F_, 2
	INSTR 12
	LEN 7
	NOTE E_, 2
	INSTR 11
	LEN 14
	NOTE F_, 2
	NOTE C_, 2
	REPEAT_END
	NEXT
Pat_4C2A:
	INSTR 11
	LEN 14
	NOTE D_, 2
	INSTR 12
	NOTE D_, 4
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 4
	INSTR 11
	NOTE E_, 2
	INSTR 12
	LEN 7
	NOTE E_, 3
	INSTR 11
	LEN 14
	NOTE F_, 2
	INSTR 12
	LEN 7
	NOTE F_, 3
	INSTR 11
	LEN 14
	NOTE D_, 2
	INSTR 12
	NOTE D_, 4
	INSTR 11
	NOTE D_, 2
	INSTR 12
	LEN 7
	NOTE D_, 4
	INSTR 11
	LEN 14
	NOTE D_, 2
	INSTR 12
	LEN 7
	NOTE D_, 3
	INSTR 11
	LEN 14
	NOTE Gsh, 2
	INSTR 12
	LEN 7
	NOTE Gsh, 3
	INSTR 11
	LEN 14
	NOTE G_, 2
	INSTR 12
	LEN 7
	NOTE G_, 3
	INSTR 11
	LEN 14
	NOTE F_, 2
	NOTE D_, 2
	INSTR 12
	NOTE D_, 4
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 4
	INSTR 11
	NOTE E_, 2
	INSTR 12
	LEN 7
	NOTE E_, 3
	INSTR 11
	LEN 14
	NOTE F_, 2
	INSTR 12
	LEN 7
	NOTE F_, 3
	INSTR 11
	LEN 14
	NOTE D_, 2
	INSTR 12
	LEN 7
	NOTE D_, 4
	INSTR 11
	LEN 14
	NOTE D_, 2
	INSTR 12
	LEN 7
	NOTE D_, 3
	INSTR 11
	LEN 14
	NOTE F_, 2
	NOTE A_, 2
	NOTE Csh, 3
	INSTR 12
	LEN 7
	NOTE Gsh, 4
	INSTR 11
	LEN 14
	NOTE Csh, 3
	INSTR 12
	LEN 7
	NOTE Gsh, 4
	INSTR 11
	LEN 14
	NOTE Csh, 3
	NEXT
Pat_4C8D:
	HWENV $00, $00
	LENGTH $E0
	REST
	REST
	NEXT
Pat_4C95:
	VIBRATO $38, $06, $01
	INSTR 7
	LENGTH $70
	NOTE B_, 3
	INSTR 4
	LEN 7
	NOTE C_, 4
	LEN 14
	WAIT2
	LEN 21
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	LEN 14
	NOTE C_, 4
	NOTE C_, 4
	INSTR 7
	LENGTH $70
	NOTE B_, 3
	INSTR 4
	LEN 7
	NOTE Ash, 3
	LEN 14
	WAIT2
	LEN 21
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	LEN 14
	NOTE Ash, 3
	NOTE Ash, 3
	NEXT
Pat_4CBA:
	INSTR 5
	LEN 28
	NOTE D_, 4
	NOTE D_, 4
	LEN 21
	NOTE E_, 4
	NOTE F_, 4
	LEN 28
	NOTE D_, 4
	LEN 21
	NOTE D_, 4
	NOTE D_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 14
	NOTE F_, 4
	LEN 28
	NOTE D_, 4
	NOTE D_, 4
	LEN 21
	NOTE E_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN 14
	NOTE F_, 4
	NOTE A_, 4
	LEN 21
	NOTE Csh, 5
	NOTE Csh, 5
	LEN 14
	NOTE Csh, 5
	NEXT
Pat_4CDB:
	HWENV $D1, $07, $70
	VIBRATO $0E, $02, $04
	ARP 3
	LEN 21
	NOTE B_, 4
	ARP_OFF
	NOTE D_, 5
	NOTE Csh, 5
	NOTE B_, 4
	LEN 14
	NOTE Fsh, 4
	NOTE B_, 3
	ARP 3
	LEN 21
	NOTE G_, 4
	ARP_OFF
	NOTE G_, 4
	LEN 14
	NOTE F_, 4
	LENGTH $38
	NOTE C_, 4
	ARP 3
	LEN 14
	NOTE B_, 4
	ARP_OFF
	LEN 7
	NOTE B_, 4
	LEN 14
	NOTE Csh, 5
	NOTE D_, 5
	LEN 21
	NOTE Csh, 5
	LEN 14
	NOTE B_, 4
	NOTE Fsh, 4
	NOTE B_, 3
	NOTE G_, 4
	LEN 7
	NOTE F_, 4
	LEN 14
	NOTE E_, 4
	NOTE F_, 4
	LENGTH $3F
	NOTE C_, 5
	NEXT
DrumPat_4D10:
	db DRUM_LEVEL + 14, DRUM_PAN_C, 1, DRUM_PAN_R, 6, 4, 0, DRUM_PAN_C
	db 9, DRUM_PAN_L, 6, 4, 0, DRUM_LOOP
DrumPat_4D1E:
	db DRUM_LEVEL + 14, 9, 9, 4, 9, 9, 0, 9
	db DRUM_LOOP

; Song 3: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong3:
	call StopAll
	ld de, Song3_Ch1
	call L48F0
	ld de, Song3_Ch3
	call L490C
	ld de, Song3_Ch2
	jp L48FE
Song3_Ch1:
	dw Pat_4D66
Loop_4D3E:
	dw Pat_4D66
	dw Pat_4D90
	dw Pat_4D66
	dw Pat_4D66
	ORDER_LOOP Loop_4D3E
Song3_Ch3:
	dw Pat_4DC4
Loop_4D4C:
	dw Pat_4E00
	dw Pat_4DCA
	dw Pat_4E00
	dw Pat_4E00
	ORDER_LOOP Loop_4D4C
Song3_Ch2:
	dw Pat_4E62
Loop_4D5A:
	dw Pat_4E6C
	dw Pat_4EA9
	dw Pat_4ECF
	dw Pat_4E6C
	ORDER_LOOP Loop_4D5A
Pat_4D66:
	INSTR 11
	LENGTH $36
	NOTE D_, 2
	LEN 9
	NOTE C_, 2
	LEN 18
	NOTE D_, 2
	NOTE F_, 2
	LEN 27
	NOTE D_, 2
	LEN 18
	NOTE C_, 2
	LENGTH $48
	NOTE D_, 2
	LEN 27
	NOTE D_, 3
	NOTE D_, 3
	LEN 18
	NOTE D_, 3
	LENGTH $36
	NOTE D_, 2
	LEN 9
	NOTE C_, 2
	LEN 18
	NOTE D_, 2
	NOTE F_, 2
	LEN 27
	NOTE D_, 2
	LEN 18
	NOTE C_, 2
	LENGTH $48
	NOTE D_, 2
	LEN 27
	NOTE G_, 2
	NOTE Gsh, 2
	LEN 18
	NOTE A_, 2
	NEXT
Pat_4D90:
	INSTR 12
	LEN 9
	NOTE D_, 2
	LEN 45
	NOTE D_, 2
	LEN 9
	NOTE D_, 2
	LENGTH $3F
	NOTE D_, 2
	LEN 18
	NOTE C_, 2
	LEN 9
	NOTE D_, 2
	LEN 45
	NOTE D_, 2
	LEN 9
	NOTE D_, 2
	LENGTH $3F
	NOTE D_, 2
	LEN 18
	NOTE C_, 2
	LEN 9
	NOTE D_, 2
	LEN 45
	NOTE D_, 2
	LEN 9
	NOTE D_, 2
	LENGTH $3F
	NOTE D_, 2
	LEN 18
	NOTE C_, 2
	LEN 9
	NOTE D_, 2
	LEN 27
	NOTE D_, 2
	LEN 18
	NOTE D_, 3
	LEN 9
	NOTE D_, 2
	LEN 27
	NOTE D_, 2
	LEN 18
	NOTE D_, 3
	LEN 9
	NOTE C_, 2
	NOTE C_, 2
	LEN 18
	NOTE C_, 2
	NEXT
Pat_4DC4:
	DRUMS $09, DrumPat_4ED5
	CH_TRANSPOSE $0C
Pat_4DCA:
	INSTR 2
	LEN 36
	NOTE E_, 3
	INSTR 1
	LEN 27
	NOTE G_, 3
	INSTR 2
	LEN 9
	NOTE E_, 3
	LEN 36
	NOTE E_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 1
	LEN 27
	NOTE G_, 3
	INSTR 2
	LEN 9
	NOTE E_, 3
	LEN 18
	NOTE E_, 3
	NOTE E_, 3
	INSTR 1
	LEN 36
	NOTE G_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 1
	LEN 27
	NOTE G_, 3
	INSTR 2
	LEN 9
	NOTE E_, 3
	LEN 36
	NOTE E_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 1
	LEN 27
	NOTE G_, 3
	INSTR 2
	LEN 9
	NOTE E_, 3
	LEN 18
	NOTE E_, 3
	NOTE E_, 3
	INSTR 1
	LEN 36
	NOTE G_, 3
	NEXT
Pat_4E00:
	INSTR 2
	LEN 18
	NOTE E_, 3
	INSTR 15
	NOTE D_, 4
	INSTR 1
	LEN 9
	NOTE G_, 3
	INSTR 15
	LEN 18
	NOTE D_, 4
	INSTR 2
	LEN 9
	NOTE E_, 3
	LEN 18
	NOTE E_, 3
	INSTR 15
	NOTE D_, 4
	INSTR 1
	LEN 9
	NOTE G_, 3
	INSTR 15
	LEN 27
	NOTE D_, 4
	INSTR 2
	LEN 18
	NOTE E_, 3
	INSTR 15
	NOTE D_, 4
	INSTR 1
	LEN 9
	NOTE G_, 3
	INSTR 15
	LEN 18
	NOTE D_, 4
	INSTR 2
	LEN 9
	NOTE E_, 3
	LEN 18
	NOTE E_, 3
	LEN 9
	NOTE E_, 3
	INSTR 15
	NOTE E_, 4
	INSTR 1
	LEN 18
	NOTE G_, 3
	INSTR 15
	NOTE E_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE D_, 4
	INSTR 1
	LEN 9
	NOTE G_, 3
	INSTR 15
	LEN 18
	NOTE D_, 4
	INSTR 2
	LEN 9
	NOTE E_, 3
	LEN 18
	NOTE E_, 3
	INSTR 15
	NOTE D_, 4
	INSTR 1
	LEN 9
	NOTE G_, 3
	INSTR 15
	LEN 27
	NOTE D_, 4
	INSTR 2
	LEN 18
	NOTE E_, 3
	INSTR 15
	NOTE D_, 4
	INSTR 1
	LEN 9
	NOTE G_, 3
	INSTR 15
	LEN 18
	NOTE D_, 4
	INSTR 2
	LEN 9
	NOTE E_, 3
	LEN 18
	NOTE E_, 3
	LEN 9
	NOTE E_, 3
	INSTR 15
	NOTE A_, 4
	INSTR 1
	LEN 18
	NOTE G_, 3
	INSTR 15
	NOTE A_, 4
	NEXT
Pat_4E62:
	HWENV $00, $00
	LENGTH $90
	WAIT
	WAIT
	WAIT
	WAIT
	NEXT
Pat_4E6C:
	HWENV $C1, $04, $46
	DUTY_50
	ARP 1
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE C_, 4
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE C_, 4
	LEN 18
	NOTE D_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	LEN 9
	NOTE C_, 4
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE C_, 4
	LEN 18
	NOTE D_, 4
	NOTE E_, 4
	NOTE E_, 4
	LEN 36
	NOTE F_, 4
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE C_, 4
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE C_, 4
	LEN 18
	NOTE D_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	LEN 9
	NOTE C_, 4
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE C_, 4
	LEN 18
	NOTE D_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 36
	NOTE D_, 4
	NEXT
Pat_4EA9:
	LEN 18
	WAIT
	DUTY_12
	ARP_OFF
Pat_4EAD:
	NOTE D_, 4
	NOTE A_, 4
	NOTE D_, 4
	LEN 27
	NOTE Gsh, 4
	NOTE E_, 4
	LEN 36
	NOTE F_, 4
	LEN 27
	NOTE Csh, 4
	NOTE D_, 4
	NOTE B_, 4
	NOTE B_, 4
	LEN 36
	NOTE C_, 5
	LEN 18
	NOTE D_, 4
	NOTE A_, 4
	NOTE D_, 4
	LEN 27
	NOTE Gsh, 4
	NOTE E_, 4
	LEN 36
	NOTE F_, 4
	LEN 18
	NOTE A_, 3
	NOTE D_, 4
	NOTE F_, 4
	LEN 27
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 18
	NOTE D_, 4
	NEXT
Pat_4ECF:
	LEN 18
	WAIT
	DUTY_75
	PAT_GOTO Pat_4EAD
DrumPat_4ED5:
	db DRUM_LEVEL + 14, 1, 0, 6, 6, 9, 0, 6
	db 1, 1, 0, 6, 6, 9, 0, DRUM_LEVEL + 15
	db 4, 0, DRUM_LEVEL + 14, 1, 0, 6, 6, 9
	db 0, 6, 1, 1, 4, 1, 0, 9
	db 0, 6, 6, DRUM_LOOP

; Song 4: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong4:
	call StopAll
	ld de, Song4_Ch1
	call L48F0
	ld de, Song4_Ch3
	call L490C
	ld de, Song4_Ch2
	jp L48FE

; Unreferenced (1 bytes)
	db $C9
Song4_Ch1:
	dw Pat_4F2F
	dw Pat_4F34
	dw Pat_4F45
	dw Pat_4F85
	ORDER_LOOP Song4_Ch1
Song4_Ch3:
	dw Pat_4F9F
	dw Pat_4F9F
	dw Pat_4FBF
	dw Pat_502D
	ORDER_LOOP Song4_Ch3
Song4_Ch2:
	dw Pat_504B
	dw Pat_50FA
	ORDER_LOOP Song4_Ch2
Pat_4F2F:
	DRUMS $0B, DrumPat_511E
	INSTR 11
Pat_4F34:
	REPEAT 4
	LEN 22
	NOTE C_, 2
	NOTE C_, 3
	LEN 11
	NOTE C_, 2
	LEN 33
	NOTE C_, 3
	NOTE C_, 2
	LEN 22
	NOTE C_, 3
	LEN 11
	NOTE F_, 2
	NOTE G_, 2
	NOTE Ash, 2
	REPEAT_END
	NEXT
Pat_4F45:
	LEN 22
	NOTE Gsh, 2
	NOTE Gsh, 3
	LEN 11
	NOTE Gsh, 2
	LEN 33
	NOTE Gsh, 3
	NOTE Gsh, 2
	LEN 22
	NOTE Gsh, 3
	LEN 11
	NOTE C_, 3
	NOTE Dsh, 3
	NOTE F_, 3
	LEN 22
	NOTE Gsh, 2
	NOTE Gsh, 3
	LEN 11
	NOTE Gsh, 2
	LEN 33
	NOTE Gsh, 3
	NOTE Gsh, 2
	LEN 11
	NOTE Gsh, 3
	NOTE F_, 2
	NOTE G_, 2
	NOTE Ash, 2
	NOTE C_, 3
	REPEAT 2
	LEN 22
	NOTE C_, 2
	NOTE C_, 3
	LEN 11
	NOTE C_, 2
	LEN 33
	NOTE C_, 3
	NOTE C_, 2
	LEN 22
	NOTE C_, 3
	LEN 11
	NOTE F_, 2
	NOTE G_, 2
	NOTE Ash, 2
	REPEAT_END
	REPEAT 2
	LEN 22
	NOTE C_, 2
	NOTE C_, 3
	LEN 11
	NOTE C_, 2
	LEN 22
	NOTE C_, 3
	LEN 11
	NOTE C_, 3
	LEN 33
	NOTE G_, 2
	LEN 11
	NOTE G_, 2
	LEN 22
	NOTE Ash, 2
	LEN 11
	NOTE C_, 3
	NOTE F_, 2
	REPEAT_END
Pat_4F85:
	DRUMS $0B, DrumPat_512D
	LEN 11
	REPEAT 4
	NOTE C_, 2
	LEN 22
	NOTE C_, 3
	NOTE C_, 3
	LEN 11
	NOTE C_, 3
	NOTE G_, 2
	NOTE Ash, 2
	REPEAT_END
	REPEAT 4
	NOTE F_, 2
	LEN 22
	NOTE F_, 3
	NOTE F_, 3
	LEN 11
	NOTE F_, 3
	NOTE C_, 3
	NOTE Dsh, 3
	REPEAT_END
	NEXT
Pat_4F9F:
	CH_TRANSPOSE $0C
	LEN 22
	REPEAT 4
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE G_, 3
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 0
	LEN 22
	NOTE Ash, 3
	LEN 11
	NOTE C_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 0
	LEN 22
	NOTE G_, 3
	LEN 11
	NOTE Ash, 3
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE C_, 4
	INSTR 15
	LEN 22
	NOTE C_, 4
	REPEAT_END
	NEXT
Pat_4FBF:
	LEN 22
	REPEAT 2
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE C_, 4
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 0
	LEN 22
	NOTE Dsh, 4
	LEN 11
	NOTE F_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 0
	LEN 22
	NOTE C_, 4
	LEN 11
	NOTE Dsh, 4
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE F_, 4
	INSTR 15
	LEN 22
	NOTE C_, 4
	REPEAT_END
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE G_, 3
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 0
	LEN 22
	NOTE Ash, 3
	LEN 11
	NOTE C_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 0
	LEN 22
	NOTE G_, 3
	LEN 11
	NOTE Ash, 3
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE C_, 4
	INSTR 15
	LEN 22
	NOTE C_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE G_, 3
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 0
	LEN 22
	NOTE Ash, 3
	LEN 11
	NOTE C_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE D_, 4
	NOTE C_, 4
	NOTE Dsh, 4
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE C_, 4
	INSTR 15
	NOTE C_, 4
	INSTR 0
	NOTE G_, 3
	REPEAT 2
	LEN 22
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE G_, 3
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 0
	LEN 22
	NOTE Ash, 3
	LEN 11
	NOTE C_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 0
	LEN 22
	NOTE G_, 3
	LEN 11
	NOTE Ash, 3
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE C_, 4
	INSTR 15
	LEN 22
	NOTE C_, 4
	REPEAT_END
Pat_502D:
	LEN 22
	REPEAT 4
	INSTR 2
	NOTE E_, 3
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 22
	NOTE C_, 4
	INSTR 1
	NOTE A_, 3
	REPEAT_END
	REPEAT 4
	INSTR 2
	NOTE E_, 3
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 22
	NOTE F_, 4
	INSTR 1
	NOTE A_, 3
	REPEAT_END
	NEXT
Pat_504B:
	VIBRATO $16, $02, $04
	ARP 16
	DUTY_50
	AUTOPAN $0B
	HWENV $B7, $00
	LENGTH $9A
	NOTE C_, 4
	AUTOPAN $00
	WAIT
	WAIT
	WAIT
	HWENV $C2, $00
	ARP_OFF
	GLIDE $FF
	LEN 33
	NOTE C_, 4
	NOTE A_, 3
	LEN 11
	NOTE F_, 3
	NOTE F_, 3
	GLIDE $00
	HWENV $90, $00
	RELEASE $01, $65
	DUTY_75
	LEN 22
	NOTE D_, 4
	LEN 11
	WAIT2
	NOTE C_, 4
	LEN 44
	NOTE D_, 4
	LEN 22
	WAIT2
	LEN 11
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	WAIT2
	NOTE F_, 4
	NOTE G_, 4
	LEN 33
	NOTE D_, 4
	LEN 11
	NOTE C_, 4
	LENGTH $58
	NOTE D_, 4
	LEN 44
	WAIT2
	LEN 22
	NOTE D_, 4
	LEN 11
	WAIT2
	NOTE C_, 4
	LEN 44
	NOTE D_, 4
	LEN 22
	WAIT2
	LEN 11
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	WAIT2
	NOTE F_, 4
	NOTE G_, 4
	LEN 33
	NOTE D_, 4
	LEN 11
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	LENGTH $42
	NOTE D_, 4
	LEN 22
	WAIT2
	LEN 11
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 22
	NOTE G_, 4
	LEN 11
	WAIT2
	NOTE F_, 4
	LEN 44
	NOTE G_, 4
	LEN 22
	WAIT2
	LEN 11
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	WAIT2
	NOTE Ash, 4
	NOTE C_, 5
	LEN 33
	NOTE G_, 4
	LEN 11
	NOTE F_, 4
	LENGTH $4D
	NOTE G_, 4
	LEN 11
	WAIT2
	LEN 22
	NOTE F_, 4
	NOTE G_, 4
	NOTE D_, 4
	LEN 11
	WAIT2
	NOTE C_, 4
	LEN 44
	NOTE D_, 4
	LEN 22
	WAIT2
	LEN 11
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Dsh, 4
	LEN 33
	NOTE D_, 4
	LEN 11
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	LEN 33
	NOTE D_, 4
	LEN 11
	WAIT2
	LEN 22
	NOTE C_, 4
	NOTE Ash, 3
	NOTE D_, 4
	LENGTH $4D
	NOTE G_, 3
	LEN 11
	WAIT2
	RELEASE $00
	DUTY_50
	ARP 16
	AUTOPAN $0B
	HWENV $B7, $00
	LEN 44
	NOTE G_, 2
	NOTE Ash, 2
	LENGTH $58
	NOTE C_, 2
	LEN 44
	NOTE G_, 2
	NOTE Ash, 2
Pat_50FA:
	LEN 44
	NOTE G_, 4
	NOTE C_, 5
	LEN 33
	NOTE D_, 5
	NOTE Ash, 4
	LEN 22
	NOTE F_, 4
	LENGTH $42
	NOTE G_, 4
	LEN 11
	NOTE C_, 4
	NOTE D_, 4
	LEN 22
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 44
	NOTE G_, 4
	NOTE C_, 5
	LEN 33
	NOTE Dsh, 5
	NOTE D_, 5
	LEN 22
	NOTE Ash, 4
	LENGTH $58
	NOTE F_, 4
	LEN 22
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NEXT
DrumPat_511E:
	db DRUM_LEVEL + 14, DRUM_PAN_C, 1, DRUM_PAN_R, 6, 4, 0, DRUM_PAN_C
	db 9, DRUM_PAN_L, 6, 4, DRUM_PAN_C, 5, DRUM_LOOP
DrumPat_512D:
	db DRUM_LEVEL + 14, 1, 5, 9, 1, 6, 5, 9
	db 4, DRUM_LOOP

; Song 5: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong5:
	call StopAll
	ld de, Song5_Ch1
	call L48F0
	ld de, Song5_Ch2
	call L48FE
	ld de, Song5_Ch3
	jp L490C

; Unreferenced (1 bytes)
	db $C9
Song5_Ch1:
	dw Pat_51A9
	dw Pat_51C9
	dw Pat_51E9
	dw Pat_5224
	dw Pat_5224
	dw Pat_529B
	dw Pat_5220
	dw Pat_5220
	dw Pat_5496
	dw Pat_5496
	dw Pat_5498
	dw Pat_5224
	dw Pat_51A9
	ORDER_LOOP Song5_Ch1
Song5_Ch2:
	dw Pat_52BF
	dw Pat_52C9
	dw Pat_52D8
	dw Pat_5309
	dw Pat_5309
	dw Pat_5345
	dw Pat_5377
	dw Pat_5377
	dw Pat_5503
	dw Pat_5503
	dw Pat_54CD
	dw Pat_54FE
	dw Pat_54FE
	ORDER_LOOP Song5_Ch2
Song5_Ch3:
	dw Pat_53D6
	dw Pat_53F0
	dw Pat_541D
	dw Pat_541D
	dw Pat_541D
	dw Pat_5471
	dw Pat_5471
	dw Pat_541D
	dw Pat_541D
	dw Pat_541D
	dw Pat_541D
	dw Pat_541D
	dw Pat_541D
	dw Pat_53D6
	ORDER_LOOP Song5_Ch3
Pat_51A9:
	DRUMS $08, DrumPat_550E
	INSTR 12
	LEN 24
	NOTE E_, 2
	NOTE E_, 2
	LENGTH $50
	NOTE E_, 2
	LEN 24
	NOTE E_, 2
	NOTE E_, 2
	LENGTH $50
	NOTE E_, 2
	LEN 24
	NOTE E_, 2
	NOTE E_, 2
	LENGTH $40
	NOTE E_, 2
	LEN 16
	NOTE D_, 2
	LEN 24
	NOTE D_, 2
	NOTE E_, 2
	LENGTH $50
	NOTE E_, 2
	NEXT
Pat_51C9:
	DRUMS $08, DrumPat_5534
	INSTR 12
	LEN 24
	NOTE E_, 2
	NOTE E_, 2
	LENGTH $50
	NOTE E_, 2
	LEN 24
	NOTE E_, 2
	NOTE E_, 2
	LENGTH $50
	NOTE E_, 2
	LEN 24
	NOTE E_, 2
	NOTE E_, 2
	LENGTH $40
	NOTE E_, 2
	LEN 16
	NOTE D_, 2
	LEN 24
	NOTE D_, 2
	NOTE E_, 2
	LENGTH $50
	NOTE E_, 2
	NEXT
Pat_51E9:
	DRUMS $08, DrumPat_555A
	LEN 16
	REPEAT 3
	INSTR 12
	NOTE E_, 2
	INSTR 6
	LEN 8
	NOTE F_, 4
	INSTR 12
	LEN 16
	NOTE E_, 2
	INSTR 6
	LEN 8
	NOTE F_, 4
	INSTR 12
	LEN 16
	NOTE E_, 2
	INSTR 6
	LEN 24
	NOTE F_, 4
	NOTE F_, 4
	LEN 16
	NOTE F_, 4
	REPEAT_END
	INSTR 12
	NOTE E_, 2
	INSTR 6
	LEN 8
	NOTE F_, 4
	INSTR 12
	LEN 16
	NOTE E_, 2
	INSTR 6
	LEN 8
	NOTE F_, 4
	INSTR 12
	LEN 16
	NOTE E_, 2
	INSTR 6
	LEN 8
	NOTE F_, 4
	INSTR 11
	LEN 16
	NOTE E_, 2
	INSTR 6
	LEN 8
	NOTE F_, 4
	INSTR 11
	LEN 16
	NOTE G_, 2
	NOTE D_, 2
	NEXT
Pat_5220:
	DRUMS $08, DrumPat_555A
Pat_5224:
	INSTR 11
	LEN 16
	NOTE E_, 2
	INSTR 6
	LEN 8
	NOTE F_, 4
	INSTR 11
	LEN 16
	NOTE E_, 2
	INSTR 6
	LEN 8
	NOTE F_, 4
	INSTR 11
	LEN 16
	NOTE E_, 2
	INSTR 6
	NOTE F_, 4
	INSTR 11
	LEN 8
	NOTE G_, 2
	INSTR 6
	LEN 16
	NOTE F_, 4
	INSTR 12
	LEN 8
	NOTE A_, 2
	INSTR 6
	NOTE F_, 4
	INSTR 12
	NOTE D_, 2
	INSTR 11
	LEN 16
	NOTE D_, 2
	INSTR 6
	LEN 8
	NOTE F_, 4
	INSTR 11
	LEN 16
	NOTE E_, 2
	INSTR 6
	LEN 8
	NOTE F_, 4
	INSTR 11
	LEN 16
	NOTE E_, 2
	INSTR 6
	NOTE F_, 4
	INSTR 11
	LEN 8
	NOTE A_, 2
	INSTR 6
	LEN 16
	NOTE F_, 4
	INSTR 12
	LEN 8
	NOTE G_, 2
	INSTR 6
	LEN 16
	NOTE F_, 4
	INSTR 11
	NOTE E_, 2
	INSTR 6
	LEN 8
	NOTE F_, 4
	INSTR 11
	LEN 16
	NOTE E_, 2
	INSTR 6
	LEN 8
	NOTE F_, 4
	INSTR 11
	LEN 16
	NOTE E_, 2
	INSTR 6
	NOTE F_, 4
	INSTR 11
	LEN 8
	NOTE G_, 2
	INSTR 6
	LEN 16
	NOTE F_, 4
	INSTR 11
	LEN 8
	NOTE D_, 2
	INSTR 6
	LEN 16
	NOTE F_, 4
	INSTR 11
	NOTE D_, 2
	INSTR 6
	LEN 8
	NOTE F_, 4
	INSTR 11
	LEN 16
	NOTE E_, 2
	INSTR 6
	LEN 8
	NOTE F_, 4
	INSTR 11
	LEN 16
	NOTE E_, 2
	INSTR 6
	LEN 8
	NOTE F_, 4
	INSTR 12
	NOTE E_, 2
	INSTR 11
	NOTE B_, 2
	INSTR 6
	NOTE F_, 4
	INSTR 12
	NOTE E_, 2
	INSTR 11
	NOTE A_, 2
	INSTR 6
	NOTE F_, 4
	INSTR 12
	NOTE G_, 2
	NEXT
Pat_529B:
	DRUMS $08, DrumPat_5577
	LEN 16
	WAIT
	INSTR 6
	LEN 24
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	LEN 32
	NOTE F_, 4
	LEN 24
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	LEN 32
	NOTE F_, 4
	LEN 24
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	LEN 32
	NOTE F_, 4
	LEN 24
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	LEN 16
	NOTE F_, 4
	NEXT
Pat_52BF:
	HWENV $00, $00
	LENGTH $80
	WAIT
	WAIT
	WAIT
	WAIT
	NEXT
Pat_52C9:
	INSTR 9
	AUTODUTY $00
	REPEAT 4
	LEN 24
	NOTE D_, 3
	LEN 40
	NOTE E_, 3
	LEN 16
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 4
	NOTE E_, 3
	REPEAT_END
	NEXT
Pat_52D8:
	LEN 24
	NOTE D_, 3
	NOTE E_, 3
	LEN 16
	NOTE E_, 4
	NOTE E_, 3
	NOTE E_, 3
	NOTE A_, 4
	NOTE E_, 3
	LEN 24
	NOTE D_, 3
	NOTE E_, 3
	LEN 16
	NOTE G_, 4
	NOTE E_, 3
	NOTE E_, 3
	NOTE D_, 4
	NOTE E_, 3
	LEN 24
	NOTE D_, 3
	NOTE E_, 3
	LEN 16
	NOTE E_, 4
	NOTE E_, 3
	NOTE E_, 3
	NOTE A_, 4
	NOTE E_, 3
	LEN 24
	NOTE D_, 3
	NOTE E_, 3
	LEN 16
	NOTE B_, 4
	HWENV $F1, $00
	DUTY_50
	GLIDE $FE
	ARP_OFF
	LEN 8
	NOTE F_, 4
	LEN 16
	NOTE E_, 4
	LEN 8
	NOTE D_, 4
	LEN 16
	NOTE C_, 4
	NOTE A_, 3
	NEXT
Pat_5309:
	INSTR 5
	LEN 16
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	LEN 8
	NOTE A_, 4
	LEN 16
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	LEN 8
	NOTE A_, 4
	LEN 16
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	LEN 8
	NOTE A_, 4
	INSTR 4
	LEN 16
	NOTE G_, 4
	NOTE G_, 4
	INSTR 5
	NOTE E_, 4
	LEN 8
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	LEN 8
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	LEN 8
	NOTE E_, 4
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	LEN 8
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	LEN 8
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	LEN 8
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	NEXT
Pat_5345:
	INSTR 11
	AUTODUTY $08
	LEN 24
	NOTE E_, 3
	NOTE B_, 2
	LEN 32
	NOTE D_, 3
	LEN 16
	NOTE A_, 2
	NOTE B_, 2
	NOTE D_, 3
	LEN 24
	NOTE E_, 2
	NOTE B_, 2
	LEN 32
	NOTE D_, 3
	LEN 16
	NOTE A_, 2
	NOTE B_, 2
	NOTE D_, 3
	LEN 24
	NOTE E_, 3
	NOTE B_, 2
	LEN 32
	NOTE D_, 3
	LEN 16
	NOTE A_, 2
	NOTE B_, 2
	NOTE D_, 3
	LEN 24
	NOTE E_, 2
	NOTE B_, 2
	NOTE D_, 3
	HWENV $F1, $08, $63
	DUTY_50
	GLIDE $FE
	ARP_OFF
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE G_, 4
	LEN 16
	NOTE F_, 4
	NOTE E_, 4
	NEXT
Pat_5377:
	INSTR 4
	LEN 16
	NOTE G_, 4
	INSTR 5
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	LEN 8
	NOTE A_, 4
	INSTR 12
	NOTE E_, 4
	INSTR 5
	NOTE A_, 4
	NOTE A_, 4
	INSTR 12
	NOTE E_, 4
	INSTR 4
	LEN 16
	NOTE G_, 4
	NOTE G_, 4
	INSTR 5
	LEN 8
	NOTE A_, 4
	LEN 16
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	LEN 8
	NOTE A_, 4
	INSTR 12
	NOTE E_, 4
	INSTR 5
	NOTE A_, 4
	INSTR 4
	NOTE G_, 4
	INSTR 12
	NOTE E_, 4
	INSTR 4
	NOTE G_, 4
	INSTR 12
	NOTE D_, 2
	INSTR 4
	NOTE D_, 4
	INSTR 12
	NOTE D_, 3
	INSTR 5
	NOTE E_, 4
	NOTE E_, 4
	INSTR 12
	NOTE E_, 3
	INSTR 5
	LEN 16
	NOTE E_, 4
	NOTE E_, 4
	LEN 8
	NOTE E_, 4
	INSTR 12
	NOTE E_, 4
	INSTR 5
	NOTE E_, 4
	INSTR 4
	NOTE G_, 4
	INSTR 12
	NOTE E_, 4
	INSTR 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 12
	NOTE A_, 3
	INSTR 5
	NOTE E_, 4
	NOTE E_, 4
	INSTR 12
	NOTE B_, 3
	INSTR 5
	LEN 16
	NOTE E_, 4
	NOTE E_, 4
	LEN 8
	NOTE E_, 4
	INSTR 12
	NOTE E_, 4
	INSTR 5
	NOTE E_, 4
	INSTR 4
	NOTE G_, 4
	INSTR 12
	NOTE E_, 4
	INSTR 5
	NOTE E_, 4
	NOTE E_, 4
	INSTR 12
	NOTE D_, 4
	NEXT
Pat_53D6:
	CH_TRANSPOSE $0C
	AUTOPAN $00
	INSTR 2
	LENGTH $40
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	LENGTH $30
	NOTE E_, 3
	LEN 16
	NOTE E_, 3
	LENGTH $40
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	LEN 24
	NOTE E_, 3
	NOTE E_, 3
	LEN 16
	NOTE E_, 3
	NEXT
Pat_53F0:
	REPEAT 3
	INSTR 2
	LEN 24
	NOTE E_, 3
	INSTR 17
	NOTE E_, 3
	LEN 16
	NOTE E_, 3
	REPEAT_END
	INSTR 2
	LEN 24
	NOTE E_, 3
	INSTR 17
	LEN 16
	NOTE E_, 3
	INSTR 16
	LEN 8
	NOTE C_, 3
	INSTR 17
	NOTE E_, 3
	NOTE E_, 3
	REPEAT 3
	INSTR 2
	LEN 24
	NOTE E_, 3
	INSTR 17
	NOTE E_, 3
	LEN 16
	NOTE E_, 3
	REPEAT_END
	INSTR 2
	LEN 24
	NOTE E_, 3
	INSTR 17
	LEN 8
	NOTE E_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 16
	NOTE C_, 3
	INSTR 17
	NOTE E_, 3
	INSTR 1
	NOTE G_, 3
	NEXT
Pat_541D:
	AUTOPAN $08
	REPEAT 3
	INSTR 2
	LEN 8
	NOTE E_, 3
	INSTR 16
	LEN 16
	NOTE C_, 3
	INSTR 17
	LEN 8
	NOTE E_, 3
	INSTR 1
	LEN 16
	NOTE G_, 3
	INSTR 17
	NOTE E_, 3
	REPEAT_END
	INSTR 2
	LEN 8
	NOTE E_, 3
	INSTR 16
	LEN 16
	NOTE C_, 3
	INSTR 17
	LEN 8
	NOTE E_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 16
	NOTE C_, 3
	INSTR 17
	NOTE E_, 3
	NOTE E_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 16
	LEN 16
	NOTE C_, 3
	INSTR 17
	LEN 8
	NOTE E_, 3
	INSTR 1
	LEN 16
	NOTE G_, 3
	INSTR 17
	NOTE E_, 3
	REPEAT 2
	INSTR 2
	LEN 8
	NOTE E_, 3
	INSTR 16
	LEN 16
	NOTE C_, 3
	INSTR 17
	LEN 8
	NOTE E_, 3
	INSTR 1
	LEN 16
	NOTE G_, 3
	INSTR 17
	NOTE E_, 3
	REPEAT_END
	INSTR 2
	LEN 8
	NOTE E_, 3
	INSTR 16
	LEN 16
	NOTE C_, 3
	INSTR 17
	LEN 8
	NOTE E_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 16
	NOTE C_, 3
	INSTR 17
	NOTE E_, 3
	AUTOPAN $00
	PAN_C
	INSTR 1
	NOTE G_, 3
	NEXT
Pat_5471:
	LEN 8
	AUTOPAN $08
	REPEAT 3
	INSTR 2
	NOTE E_, 3
	INSTR 16
	NOTE C_, 3
	INSTR 15
	NOTE E_, 4
	INSTR 17
	NOTE E_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE E_, 4
	INSTR 17
	NOTE E_, 3
	INSTR 15
	NOTE E_, 4
	REPEAT_END
	INSTR 2
	NOTE E_, 3
	INSTR 16
	NOTE C_, 3
	INSTR 15
	NOTE E_, 4
	INSTR 17
	NOTE E_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 16
	NOTE C_, 3
	INSTR 17
	NOTE E_, 3
	NOTE E_, 3
	NEXT
Pat_5496:
	CH_TRANSPOSE $02
Pat_5498:
	LEN 16
	INSTR 11
	REPEAT 3
	NOTE C_, 2
	INSTR 6
	LEN 8
	NOTE Dsh, 4
	INSTR 11
	LEN 16
	NOTE D_, 2
	INSTR 6
	LEN 8
	NOTE Dsh, 4
	INSTR 11
	LEN 16
	NOTE D_, 2
	INSTR 11
	NOTE D_, 2
	LEN 8
	NOTE D_, 2
	INSTR 6
	NOTE Dsh, 4
	INSTR 11
	LEN 16
	NOTE D_, 3
	NOTE D_, 2
	REPEAT_END
	NOTE C_, 2
	INSTR 6
	LEN 8
	NOTE Dsh, 4
	INSTR 11
	LEN 16
	NOTE D_, 2
	INSTR 6
	LEN 8
	NOTE Dsh, 4
	INSTR 11
	LEN 16
	NOTE D_, 2
	INSTR 11
	NOTE D_, 2
	LEN 8
	NOTE D_, 2
	INSTR 6
	NOTE Dsh, 4
	INSTR 11
	LEN 16
	NOTE F_, 2
	NOTE G_, 2
	CH_TRANSPOSE $00
	NEXT
Pat_54CD:
	HWENV $A1, $04, $44
	ARP 1
	AUTODUTY $04
	GLIDE_OFF
Pat_54D5:
	REPEAT 2
	LEN 16
	NOTE D_, 4
	LEN 16
	NOTE D_, 4
	NOTE D_, 4
	LEN 8
	NOTE C_, 4
	LEN 16
	NOTE D_, 4
	LEN 8
	NOTE C_, 4
	LEN 16
	NOTE D_, 4
	LEN 8
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	LEN 16
	NOTE D_, 4
	NOTE D_, 4
	LEN 8
	NOTE C_, 4
	LEN 16
	NOTE D_, 4
	LEN 8
	NOTE C_, 4
	LEN 16
	NOTE D_, 4
	LEN 8
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE C_, 4
	REPEAT_END
	CH_TRANSPOSE $00
	NEXT
Pat_54FE:
	CH_TRANSPOSE $02
	PAT_GOTO Pat_54D5
Pat_5503:
	HWENV $C2, $08, $63
	GLIDE_OFF
	ARP 6
	AUTODUTY $08
	PAT_GOTO Pat_52D8
DrumPat_550E:
	db DRUM_LEVEL + 13, DRUM_REPEAT + 3, 1, 0, 0, 6, 0, 0
	db 6, 0, DRUM_REPEAT_END, 1, 0, 0, 6, 0
	db 0, 1, 0, DRUM_REPEAT + 3, 1, 0, 0, 6
	db 0, 0, 6, 0, DRUM_REPEAT_END, 1, 0, 0
	db 1, 0, 0, 1, 0, DRUM_LOOP
DrumPat_5534:
	db DRUM_LEVEL + 13, DRUM_REPEAT + 3, 1, 0, 0, 6, 0, 0
	db 6, 0, DRUM_REPEAT_END, 1, 0, 0, 6, 0
	db 0, 1, 0, DRUM_REPEAT + 3, 1, 0, 0, 6
	db 0, 0, 6, 0, DRUM_REPEAT_END, 1, 0, 0
	db 1, 9, 0, 1, 9, DRUM_LOOP
DrumPat_555A:
	db DRUM_LEVEL + 14, DRUM_REPEAT + 7, DRUM_PAN_C, 1, DRUM_PAN_R, 6, 4, 0
	db DRUM_PAN_C, 9, DRUM_PAN_L, 6, 4, 0, DRUM_REPEAT_END, DRUM_PAN_C
	db 1, DRUM_PAN_R, 6, 4, 0, DRUM_PAN_C, 9, DRUM_PAN_L
	db 6, 4, DRUM_PAN_C, 9, DRUM_LOOP
DrumPat_5577:
	db DRUM_LEVEL + 14, DRUM_PAN_C, 1, DRUM_PAN_R, 6, 4, 0, DRUM_PAN_C
	db 1, DRUM_PAN_L, 6, 4, 0, DRUM_LOOP

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
	dw Pat_55BF
	dw Pat_55D0
	dw Pat_55C3
	dw Pat_55D0
	ORDER_LOOP Song6_Ch1
Song6_Ch3:
	dw Pat_55E7
	dw Pat_55FC
	dw Pat_55E9
	dw Pat_55FC
	ORDER_LOOP Song6_Ch3
Song6_Ch2:
	dw Pat_561F
	dw Pat_5644
	dw Pat_5663
	dw Pat_5694
	ORDER_LOOP Song6_Ch2
Pat_55BF:
	DRUMS $09, DrumPat_56BC
Pat_55C3:
	INSTR 11
	REPEAT 4
	LEN 27
	NOTE F_, 2
	NOTE C_, 3
	LEN 36
	NOTE F_, 3
	LEN 18
	NOTE F_, 2
	NOTE C_, 3
	NOTE F_, 3
	REPEAT_END
	NEXT
Pat_55D0:
	REPEAT 2
	LEN 27
	NOTE D_, 2
	NOTE A_, 2
	LEN 36
	NOTE D_, 3
	LEN 18
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 3
	REPEAT_END
	REPEAT 2
	LEN 27
	NOTE C_, 2
	NOTE G_, 2
	LEN 36
	NOTE C_, 3
	LEN 18
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 3
	REPEAT_END
	NEXT
Pat_55E7:
	CH_TRANSPOSE $0C
Pat_55E9:
	LEN 18
	REPEAT 4
	INSTR 2
	NOTE E_, 3
	INSTR 18
	NOTE F_, 3
	INSTR 14
	NOTE F_, 4
	INSTR 18
	NOTE F_, 3
	INSTR 2
	NOTE E_, 3
	NOTE E_, 3
	INSTR 14
	NOTE F_, 4
	INSTR 18
	NOTE F_, 2
	REPEAT_END
	NEXT
Pat_55FC:
	REPEAT 2
	INSTR 2
	NOTE E_, 3
	INSTR 18
	NOTE D_, 3
	INSTR 15
	NOTE D_, 4
	INSTR 18
	NOTE D_, 3
	INSTR 2
	NOTE E_, 3
	NOTE E_, 3
	INSTR 15
	NOTE D_, 4
	INSTR 18
	NOTE D_, 2
	REPEAT_END
	REPEAT 2
	INSTR 2
	NOTE E_, 3
	INSTR 18
	NOTE C_, 3
	INSTR 14
	NOTE C_, 4
	INSTR 18
	NOTE C_, 3
	INSTR 2
	NOTE E_, 3
	NOTE E_, 3
	INSTR 14
	NOTE C_, 4
	INSTR 18
	NOTE C_, 2
	REPEAT_END
	NEXT
Pat_561F:
	HWENV $D7, $48, $40
	DUTY_75
	VIBRATO $1B, $03, $04
	ARP 7
	RELEASE $00
	LENGTH $48
	NOTE A_, 4
	LEN 36
	NOTE B_, 4
	NOTE G_, 4
	LENGTH $6C
	NOTE A_, 4
	LEN 18
	NOTE F_, 4
	NOTE G_, 4
	LENGTH $48
	NOTE A_, 4
	LEN 36
	NOTE B_, 4
	NOTE C_, 5
	LENGTH $6C
	NOTE A_, 4
	LEN 18
	NOTE F_, 4
	NOTE G_, 4
	NEXT
Pat_5644:
	LENGTH $36
	NOTE A_, 4
	LEN 18
	NOTE D_, 4
	LENGTH $36
	NOTE D_, 4
	LEN 18
	NOTE D_, 2
	LENGTH $48
	NOTE D_, 2
	LEN 27
	NOTE A_, 4
	NOTE G_, 4
	LEN 18
	NOTE F_, 4
	LENGTH $36
	NOTE E_, 4
	LEN 18
	NOTE D_, 4
	LENGTH $48
	NOTE C_, 4
	LENGTH $48
	NOTE C_, 2
	NOTE E_, 2
	NEXT
Pat_5663:
	HWENV $90, $00
	RELEASE $02, $53
	DUTY_12
	LEN 9
	NOTE A_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	LENGTH $B4
	NOTE A_, 3
	LEN 9
	NOTE A_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	LEN 18
	NOTE B_, 3
	LEN 9
	NOTE G_, 3
	NOTE B_, 3
	LENGTH $5A
	NOTE A_, 3
	LEN 18
	NOTE A_, 3
	NOTE D_, 4
	NOTE E_, 4
	NEXT
Pat_5694:
	LEN 27
	NOTE F_, 4
	NOTE E_, 4
	LEN 18
	NOTE F_, 4
	LENGTH $36
	NOTE E_, 4
	LEN 18
	NOTE A_, 3
	LEN 27
	NOTE D_, 4
	NOTE C_, 4
	LEN 18
	NOTE D_, 4
	LEN 36
	NOTE A_, 3
	LEN 18
	NOTE F_, 3
	NOTE A_, 3
	LENGTH $48
	NOTE G_, 3
	NOTE C_, 4
	LEN 9
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE F_, 4
	NOTE E_, 4
	LEN 18
	NOTE D_, 4
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NEXT
DrumPat_56BC:
	db DRUM_REPEAT + 3, DRUM_LEVEL + 14, 1, 6, 6, 10, DRUM_LEVEL + 15, 9
	db DRUM_LEVEL + 14, 6, 6, 10, 1, 10, 1, 6
	db DRUM_LEVEL + 15, 9, DRUM_LEVEL + 14, 6, 4, 10, DRUM_REPEAT_END, DRUM_LEVEL + 14
	db 1, 6, 6, 10, DRUM_LEVEL + 15, 9, DRUM_LEVEL + 14, 6
	db 6, 10, 1, 10, 1, 6, DRUM_LEVEL + 15, 9
	db 10, 10, 9, DRUM_LOOP

; Song 7: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong7:
	call StopAll
	ld de, Song7_Ch1
	call L48F0
	ld de, Song7_Ch2
	call L48FE
	ld de, Song7_Ch3
	jp L490C
Song7_Ch1:
	dw Pat_5763
	dw Pat_5786
	dw Pat_57A3
	dw Pat_57A3
	dw Pat_57D9
	dw Pat_57D9
	dw Pat_57A3
	dw Pat_57A3
	dw Pat_57D9
	dw Pat_57D9
	dw Pat_5786
	dw Pat_5786
	dw Pat_5860
	dw Pat_5814
	dw Pat_582B
	ORDER_LOOP Song7_Ch1
Song7_Ch2:
	dw Pat_5845
	dw Pat_5860
	dw Pat_58B4
	dw Pat_58D7
	dw Pat_58FD
	dw Pat_58FD
	dw Pat_58B4
	dw Pat_58D7
	dw Pat_58FD
	dw Pat_58FD
	dw Pat_5860
	dw Pat_5860
	dw Pat_5845
	dw Pat_5940
	dw Pat_5940
	ORDER_LOOP Song7_Ch2
Song7_Ch3:
	dw Pat_595D
	dw Pat_5990
	dw Pat_59B7
	dw Pat_59B7
	dw Pat_5A0A
	dw Pat_5A0A
	dw Pat_59B7
	dw Pat_59B7
	dw Pat_5A0A
	dw Pat_5A0A
	dw Pat_5990
	dw Pat_5990
	dw Pat_5A27
	dw Pat_5A27
	dw Pat_5A27
	ORDER_LOOP Song7_Ch3
Pat_5763:
	VIBRATO $08, $04, $04
	TRANSPOSE $01
	REPEAT 2
	INSTR 11
	LEN 24
	NOTE F_, 2
	INSTR 12
	NOTE F_, 2
	LEN 16
	NOTE F_, 2
	LEN 24
	NOTE F_, 2
	NOTE F_, 2
	LEN 16
	NOTE F_, 2
	INSTR 11
	LEN 24
	NOTE F_, 2
	INSTR 12
	NOTE F_, 2
	LEN 16
	NOTE F_, 2
	LEN 24
	NOTE F_, 2
	LEN 8
	NOTE F_, 2
	LEN 16
	NOTE F_, 2
	NOTE F_, 2
	REPEAT_END
	NEXT
Pat_5786:
	REPEAT 2
	INSTR 11
	LEN 24
	NOTE F_, 2
	NOTE F_, 2
	INSTR 12
	LEN 16
	NOTE C_, 3
	INSTR 11
	LEN 24
	NOTE Dsh, 2
	NOTE Dsh, 2
	INSTR 12
	LEN 16
	NOTE Ash, 2
	INSTR 11
	LEN 24
	NOTE F_, 2
	NOTE F_, 2
	LEN 16
	NOTE Dsh, 2
	LEN 24
	NOTE F_, 2
	NOTE F_, 2
	INSTR 12
	LEN 16
	NOTE C_, 3
	REPEAT_END
	NEXT
Pat_57A3:
	INSTR 11
	LEN 24
	NOTE F_, 2
	NOTE C_, 3
	INSTR 12
	LEN 16
	NOTE F_, 3
	INSTR 11
	LEN 24
	NOTE Dsh, 2
	NOTE Ash, 2
	INSTR 12
	LEN 16
	NOTE Dsh, 3
	INSTR 11
	LEN 24
	NOTE F_, 2
	NOTE C_, 3
	INSTR 12
	LEN 16
	NOTE F_, 3
	INSTR 11
	LEN 24
	NOTE Gsh, 2
	NOTE Ash, 2
	LEN 16
	NOTE Dsh, 2
	LEN 24
	NOTE F_, 2
	NOTE C_, 3
	INSTR 12
	LEN 16
	NOTE F_, 3
	INSTR 11
	LEN 24
	NOTE Dsh, 2
	NOTE Ash, 2
	INSTR 12
	LEN 16
	NOTE Dsh, 3
	INSTR 11
	LEN 24
	NOTE Gsh, 2
	NOTE Dsh, 3
	INSTR 12
	LEN 16
	NOTE Gsh, 3
	INSTR 11
	LEN 24
	NOTE Ash, 2
	NOTE F_, 3
	LEN 16
	NOTE Ash, 2
	NEXT
Pat_57D9:
	INSTR 11
	LEN 24
	NOTE Gsh, 2
	NOTE Dsh, 3
	INSTR 12
	LEN 16
	NOTE Gsh, 2
	INSTR 11
	LEN 24
	NOTE Ash, 2
	NOTE F_, 3
	INSTR 12
	LEN 16
	NOTE Ash, 2
	INSTR 11
	LEN 24
	NOTE F_, 2
	NOTE C_, 3
	INSTR 12
	LEN 16
	NOTE Dsh, 3
	INSTR 11
	LEN 24
	NOTE F_, 2
	NOTE C_, 3
	LEN 16
	NOTE F_, 2
	LEN 24
	NOTE Gsh, 2
	NOTE Dsh, 3
	INSTR 12
	LEN 16
	NOTE Gsh, 2
	INSTR 11
	LEN 24
	NOTE Ash, 2
	NOTE F_, 3
	INSTR 12
	LEN 16
	NOTE Ash, 2
	INSTR 11
	LEN 24
	NOTE C_, 2
	NOTE C_, 3
	INSTR 12
	LEN 16
	NOTE G_, 2
	INSTR 11
	LEN 24
	NOTE C_, 2
	LEN 16
	NOTE C_, 3
	INSTR 12
	LEN 8
	NOTE G_, 2
	INSTR 11
	LEN 16
	NOTE C_, 2
	NEXT
Pat_5814:
	INSTR 12
	PAN_C
	LEN 8
	REPEAT 4
	NOTE F_, 2
	NOTE F_, 2
	LEN 16
	NOTE F_, 2
	NOTE F_, 2
	LEN 8
	NOTE F_, 2
	LEN 16
	NOTE F_, 2
	LEN 8
	NOTE F_, 2
	LEN 16
	NOTE F_, 2
	NOTE F_, 2
	LEN 8
	NOTE F_, 2
	NOTE F_, 2
	REPEAT_END
	NEXT
Pat_582B:
	AUTODUTY $08
	LEN 8
	REPEAT 4
	NOTE Dsh, 2
	NOTE F_, 2
	LEN 16
	NOTE F_, 2
	NOTE F_, 3
	LEN 8
	NOTE F_, 2
	LEN 16
	NOTE C_, 3
	LEN 8
	NOTE F_, 2
	NOTE Dsh, 3
	NOTE F_, 2
	LEN 16
	NOTE F_, 3
	LEN 8
	NOTE Dsh, 3
	NOTE Ash, 2
	REPEAT_END
	AUTODUTY $00
	NEXT
Pat_5845:
	HWENV $F1, $06, $65
	DUTY_50
	GLIDE $FF
	ARP_OFF
	CH_TRANSPOSE $FA
	REPEAT 2
	PAN_R
	LEN 24
	NOTE F_, 4
	LENGTH $68
	NOTE C_, 4
	PAN_L
	LEN 24
	NOTE A_, 4
	LENGTH $68
	NOTE E_, 4
	REPEAT_END
	CH_TRANSPOSE $00
	NEXT
Pat_5860:
	HWENV $E1, $04, $64
	DUTY_12
	ARP 0
	GLIDE_OFF
	VIB_OFF
	PAN_L
	LEN 8
	NOTE F_, 3
	LEN 16
	NOTE Gsh, 3
	LEN 8
	NOTE F_, 3
	LEN 16
	NOTE Gsh, 3
	NOTE F_, 3
	PAN_R
	LEN 8
	NOTE Dsh, 3
	LEN 16
	NOTE G_, 3
	LEN 8
	NOTE Dsh, 3
	LEN 16
	NOTE G_, 3
	NOTE Dsh, 3
	PAN_L
	LEN 24
	NOTE F_, 3
	LEN 8
	NOTE F_, 3
	LEN 16
	NOTE F_, 3
	NOTE Dsh, 3
	PAN_R
	LEN 8
	NOTE F_, 3
	LEN 16
	NOTE F_, 3
	LEN 8
	NOTE F_, 3
	LEN 16
	NOTE F_, 3
	NOTE Dsh, 3
	PAN_L
	LEN 8
	NOTE F_, 3
	LEN 16
	NOTE Gsh, 3
	LEN 8
	NOTE F_, 3
	LEN 16
	NOTE Gsh, 3
	NOTE F_, 3
	PAN_R
	LEN 8
	NOTE Dsh, 3
	LEN 16
	NOTE G_, 3
	LEN 8
	NOTE Dsh, 3
	LEN 16
	NOTE G_, 3
	NOTE Dsh, 3
	PAN_L
	LEN 24
	NOTE F_, 3
	LEN 8
	NOTE F_, 3
	LEN 16
	NOTE F_, 3
	LEN 24
	NOTE Dsh, 3
	PAN_R
	LEN 8
	NOTE F_, 3
	LEN 16
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	PAN_C
	NEXT
Pat_58B4:
	INSTR 13
	LEN 24
	NOTE F_, 4
	NOTE G_, 4
	LEN 16
	NOTE Gsh, 4
	LEN 24
	NOTE G_, 4
	NOTE F_, 4
	LEN 16
	NOTE Dsh, 4
	LEN 24
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 16
	NOTE C_, 4
	LEN 24
	NOTE C_, 4
	LENGTH $38
	NOTE Ash, 3
	LEN 16
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 24
	NOTE Ash, 4
	NOTE Gsh, 4
	LEN 16
	NOTE G_, 4
	LENGTH $40
	NOTE Dsh, 4
	NOTE F_, 4
	NEXT
Pat_58D7:
	LEN 16
	NOTE F_, 3
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 24
	NOTE G_, 4
	NOTE F_, 4
	LEN 16
	NOTE Dsh, 4
	LEN 24
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 16
	NOTE C_, 4
	LEN 24
	NOTE C_, 4
	LENGTH $38
	NOTE Ash, 3
	LEN 16
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 24
	NOTE Ash, 4
	NOTE Gsh, 4
	LEN 16
	NOTE Ash, 4
	LENGTH $30
	NOTE C_, 5
	LEN 16
	NOTE Ash, 4
	LENGTH $40
	NOTE C_, 5
	NEXT
Pat_58FD:
	HWENV $E1, $04, $64
	DUTY_12
	ARP 0
	LEN 16
	NOTE Gsh, 3
	NOTE Gsh, 4
	LEN 8
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	LEN 16
	NOTE Ash, 3
	NOTE Dsh, 4
	LEN 8
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 16
	NOTE G_, 4
	NOTE F_, 4
	LEN 8
	NOTE F_, 3
	LEN 16
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 8
	NOTE C_, 4
	NOTE F_, 3
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	LEN 16
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE Gsh, 3
	NOTE Gsh, 4
	LEN 8
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	LEN 16
	NOTE Ash, 3
	NOTE F_, 4
	LEN 8
	NOTE Ash, 4
	NOTE Gsh, 4
	LEN 16
	NOTE Ash, 4
	NOTE C_, 5
	LEN 8
	NOTE G_, 4
	LEN 16
	NOTE Ash, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE Ash, 4
	LEN 8
	NOTE B_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NEXT
Pat_5940:
	CH_TRANSPOSE $06
	REPEAT 2
	PAN_R
	LEN 24
	NOTE F_, 3
	NOTE C_, 3
	LEN 16
	NOTE C_, 3
	PAN_L
	LEN 24
	NOTE C_, 4
	LEN 40
	NOTE B_, 3
	PAN_R
	LEN 24
	NOTE A_, 3
	NOTE E_, 3
	LEN 32
	NOTE C_, 3
	PAN_L
	LEN 16
	NOTE C_, 4
	LEN 32
	NOTE B_, 3
	REPEAT_END
	CH_TRANSPOSE $00
	NEXT
Pat_595D:
	CH_TRANSPOSE $0C
	DRUMS $08, DrumPat_5A6F
	REPEAT 2
	INSTR 2
	LEN 8
	NOTE G_, 3
	INSTR 0
	LEN 16
	NOTE Gsh, 3
	LEN 8
	NOTE F_, 3
	LEN 16
	NOTE Gsh, 3
	NOTE F_, 3
	INSTR 2
	LEN 8
	NOTE G_, 3
	INSTR 0
	LEN 16
	NOTE G_, 3
	LEN 8
	NOTE Dsh, 3
	LEN 16
	NOTE G_, 3
	NOTE Dsh, 3
	INSTR 2
	LEN 24
	NOTE G_, 3
	INSTR 0
	LEN 8
	NOTE F_, 3
	LEN 16
	NOTE F_, 3
	NOTE Dsh, 3
	INSTR 2
	LEN 8
	NOTE G_, 3
	INSTR 0
	LEN 16
	NOTE F_, 3
	LEN 8
	NOTE F_, 3
	LEN 16
	NOTE F_, 3
	NOTE Dsh, 3
	REPEAT_END
	NEXT
Pat_5990:
	DRUMS $08, DrumPat_5A41
	REPEAT 2
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE F_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE F_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 14
	NOTE Dsh, 3
	INSTR 1
	NOTE A_, 3
	INSTR 14
	NOTE Dsh, 3
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE F_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE F_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE F_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE F_, 3
	REPEAT_END
	NEXT
Pat_59B7:
	LEN 16
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE F_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE F_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 14
	NOTE Dsh, 4
	INSTR 1
	NOTE A_, 3
	INSTR 14
	NOTE Dsh, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE F_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE F_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 14
	NOTE Ash, 4
	INSTR 1
	NOTE A_, 3
	INSTR 14
	NOTE Ash, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE F_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE F_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 14
	NOTE Dsh, 4
	INSTR 1
	NOTE A_, 3
	INSTR 14
	NOTE Dsh, 4
	INSTR 2
	NOTE E_, 3
	INSTR 14
	NOTE Gsh, 4
	INSTR 1
	NOTE A_, 3
	INSTR 14
	NOTE Gsh, 4
	INSTR 2
	NOTE E_, 3
	INSTR 14
	NOTE Ash, 4
	INSTR 1
	NOTE A_, 3
	INSTR 14
	NOTE Ash, 4
	NEXT
Pat_59F9:
	INSTR 2
	NOTE E_, 3
	INSTR 14
	NOTE Gsh, 4
	INSTR 1
	NOTE A_, 3
	INSTR 14
	NOTE Gsh, 4
	INSTR 2
	NOTE E_, 3
	INSTR 14
	NOTE Ash, 4
	INSTR 1
	NOTE A_, 3
	INSTR 14
	NOTE Ash, 4
	NEXT
Pat_5A0A:
	LEN 16
	PAT_CALL Pat_59F9
	REPEAT 2
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE F_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE F_, 4
	REPEAT_END
	LEN 16
	PAT_CALL Pat_59F9
	REPEAT 2
	INSTR 2
	NOTE E_, 3
	INSTR 14
	NOTE C_, 5
	INSTR 1
	NOTE A_, 3
	INSTR 14
	NOTE C_, 5
	REPEAT_END
	NEXT
Pat_5A27:
	DRUMS $08, DrumPat_5A58
	AUTOPAN $08
	REPEAT 8
	INSTR 2
	LEN 16
	NOTE E_, 3
	INSTR 16
	LEN 8
	NOTE G_, 3
	INSTR 17
	NOTE F_, 3
	INSTR 2
	NOTE G_, 3
	INSTR 16
	NOTE G_, 3
	INSTR 17
	NOTE F_, 3
	NOTE F_, 3
	REPEAT_END
	AUTOPAN $00
	NEXT
DrumPat_5A41:
	db DRUM_LEVEL + 13, DRUM_REPEAT + 3, 1, 6, 5, 6, 9, 6
	db 5, 6, DRUM_REPEAT_END, 1, 6, 5, 6, 9
	db 6, 5, DRUM_TEMPO + 4, 6, 6, DRUM_TEMPO + 8, DRUM_LOOP
DrumPat_5A58:
	db DRUM_LEVEL + 13, DRUM_REPEAT + 3, 1, 0, 5, 6, 1, 0
	db 5, 6, DRUM_REPEAT_END, 1, 6, 5, 6, 1
	db 0, 5, DRUM_TEMPO + 4, 6, 6, DRUM_TEMPO + 8, DRUM_LOOP
DrumPat_5A6F:
	db DRUM_LEVEL + 13, 1, 0, 0, 5, 0, 0, 5
	db 6, DRUM_LOOP

; Song 8: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong8:
	call StopAll
	ld de, Song8_Ch1
	call L48F0
	ld de, Song8_Ch3
	call L490C
	ld de, Song8_Ch2
	jp L48FE
Song8_Ch1:
	dw Pat_5AC4
Loop_5A90:
	dw Pat_5AEA
	dw Pat_5B16
	dw Pat_5B46
	dw Pat_5B85
	dw Pat_5BB9
	dw Pat_5BF6
	ORDER_LOOP Loop_5A90
Song8_Ch3:
	dw Pat_5C1C
Loop_5AA2:
	dw Pat_5C45
	dw Pat_5C45
	dw Pat_5C72
	dw Pat_5CD0
	dw Pat_5D2E
	dw Pat_5D95
	ORDER_LOOP Loop_5AA2
Song8_Ch2:
	dw Pat_5DE6
Loop_5AB4:
	dw Pat_5E11
	dw Pat_5E36
	dw Pat_5E5B
	dw Pat_5E7E
	dw Pat_5EB7
	dw Pat_5EDE
	ORDER_LOOP Loop_5AB4
Pat_5AC4:
	VIBRATO $0B, $03, $04
	PAN_L
	HWENV $C7, $00
	DUTY_75
	ARP 0
	LEN 22
	NOTE F_, 2
	NOTE C_, 3
	NOTE B_, 2
	LENGTH $6E
	NOTE Dsh, 3
	LEN 22
	NOTE F_, 2
	NOTE C_, 3
	NOTE B_, 2
	LENGTH $6E
	NOTE Dsh, 3
	LEN 22
	NOTE F_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE C_, 5
	LENGTH $B0
	NOTE B_, 4
	PAN_C
	NEXT
Pat_5AEA:
	ARP_OFF
	HWENV $2A, $04, $50
	DUTY_12
	RELEASE $04, $30
	LENGTH $B0
	NOTE F_, 4
	NOTE E_, 4
	LEN 33
	NOTE Dsh, 4
	NOTE D_, 4
	LEN 22
	NOTE Csh, 4
	LENGTH $42
	NOTE C_, 4
	INSTR 11
	RELEASE $00
	PAN_L
	DUTY_75
	LEN 22
	NOTE F_, 3
	LEN 11
	NOTE Fsh, 3
	NOTE Fsh, 3
	REST
	LEN 33
	NOTE Fsh, 3
	LEN 11
	NOTE Fsh, 3
	NOTE Fsh, 3
	REST
	LEN 33
	NOTE Fsh, 3
	LEN 44
	NOTE E_, 3
	PAN_C
	NEXT
Pat_5B16:
	ARP_OFF
	HWENV $4A, $04, $60
	DUTY_12
	RELEASE $04, $40
	LENGTH $84
	NOTE F_, 4
	LEN 44
	NOTE C_, 4
	LENGTH $B0
	NOTE E_, 4
	LEN 33
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 22
	NOTE Fsh, 4
	LENGTH $42
	NOTE F_, 4
	INSTR 11
	RELEASE $00
	DUTY_75
	PAN_L
	LEN 22
	NOTE C_, 3
	LEN 11
	NOTE Csh, 3
	NOTE Csh, 3
	REST
	LEN 33
	NOTE Csh, 3
	LEN 11
	NOTE Fsh, 3
	NOTE Fsh, 3
	REST
	LEN 33
	NOTE Fsh, 3
	LEN 44
	NOTE Ash, 3
	PAN_C
	NEXT
Pat_5B46:
	ARP_OFF
	HWENV $D1, $04, $70
	RELEASE $03, $40
	LEN 22
	WAIT
	LEN 11
	REPEAT 3
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	REPEAT_END
	NOTE Gsh, 3
	NOTE G_, 3
	LEN 22
	NOTE Fsh, 3
	NOTE Csh, 3
	NOTE Csh, 3
	NOTE Fsh, 3
	NOTE Fsh, 3
	NOTE Ash, 3
	NOTE Csh, 4
	LEN 44
	NOTE Ash, 3
	LEN 11
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE F_, 3
	LEN 22
	NOTE Fsh, 3
	LEN 11
	NOTE Ash, 3
	NOTE Gsh, 3
	LEN 22
	NOTE Ash, 3
	LEN 11
	NOTE Csh, 4
	NOTE C_, 4
	LEN 22
	NOTE Csh, 4
	LEN 11
	NOTE Fsh, 4
	NOTE F_, 4
	LEN 22
	NOTE Fsh, 4
	NOTE Ash, 4
	NEXT
Pat_5B85:
	LEN 22
	WAIT
	LEN 11
	REPEAT 3
	NOTE Dsh, 3
	NOTE D_, 3
	NOTE Dsh, 3
	NOTE F_, 3
	REPEAT_END
	NOTE Fsh, 3
	NOTE Dsh, 3
	LEN 22
	NOTE F_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 44
	NOTE F_, 3
	LEN 11
	REPEAT 2
	NOTE Dsh, 3
	NOTE D_, 3
	NOTE Dsh, 3
	NOTE F_, 3
	REPEAT_END
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE Fsh, 3
	NOTE Gsh, 3
	NOTE Fsh, 3
	NOTE Dsh, 3
	LEN 22
	NOTE F_, 3
	LEN 11
	NOTE A_, 3
	NOTE Ash, 3
	LEN 22
	NOTE C_, 4
	LEN 11
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 22
	NOTE Fsh, 4
	NOTE F_, 4
	NEXT
Pat_5BB9:
	LEN 11
	WAIT
	NOTE F_, 4
	REPEAT 2
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Csh, 5
	NOTE Dsh, 5
	REPEAT_END
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Csh, 5
	NOTE F_, 4
	NOTE Csh, 5
	NOTE C_, 5
	LEN 22
	NOTE B_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE Ash, 3
	LEN 33
	NOTE B_, 3
	LEN 11
	NOTE F_, 3
	NOTE Csh, 4
	NOTE C_, 4
	LEN 22
	NOTE Csh, 4
	LEN 11
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE C_, 4
	LEN 22
	NOTE B_, 3
	LEN 11
	NOTE Dsh, 4
	NOTE D_, 4
	LEN 22
	NOTE Dsh, 4
	LEN 11
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 22
	NOTE Gsh, 4
	LEN 11
	NOTE B_, 4
	NOTE Ash, 4
	LEN 22
	NOTE B_, 4
	NOTE Dsh, 5
	NEXT
Pat_5BF6:
	LEN 11
	NOTE E_, 5
	NOTE B_, 4
	NOTE Ash, 4
	LEN 22
	NOTE Gsh, 4
	LEN 11
	NOTE B_, 4
	NOTE E_, 5
	NOTE Dsh, 5
	NOTE E_, 5
	NOTE B_, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE B_, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	LEN 22
	NOTE E_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE Gsh, 4
	NOTE Gsh, 3
	NOTE E_, 4
	NOTE Csh, 4
	LENGTH $58
	NOTE B_, 3
	LEN 44
	NOTE Gsh, 2
	NOTE Ash, 3
	LENGTH $58
	NOTE Gsh, 3
	NOTE Gsh, 2
	NEXT
Pat_5C1C:
	CH_TRANSPOSE $0C
	INSTR 16
	LEN 33
	NOTE E_, 2
	NOTE E_, 2
	LENGTH $42
	NOTE D_, 3
	LEN 11
	NOTE B_, 2
	LEN 33
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	LENGTH $42
	NOTE D_, 3
	LEN 11
	NOTE B_, 2
	LEN 33
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	LENGTH $42
	NOTE D_, 3
	LEN 11
	NOTE B_, 2
	LEN 33
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	LENGTH $42
	NOTE D_, 3
	LEN 11
	NOTE B_, 2
	LEN 33
	NOTE E_, 2
	NEXT
Pat_5C45:
	INSTR 16
	LEN 33
	NOTE E_, 2
	NOTE E_, 2
	LENGTH $42
	NOTE D_, 3
	LEN 11
	NOTE B_, 2
	LEN 33
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	LENGTH $42
	NOTE D_, 3
	LEN 11
	NOTE B_, 2
	LEN 33
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	LENGTH $42
	NOTE D_, 3
	LEN 11
	NOTE B_, 2
	LEN 33
	NOTE E_, 2
	INSTR 2
	LEN 11
	NOTE E_, 3
	LEN 22
	NOTE E_, 3
	LEN 33
	NOTE E_, 3
	LEN 11
	NOTE E_, 3
	LEN 22
	NOTE E_, 3
	LEN 33
	NOTE E_, 3
	LEN 44
	NOTE E_, 3
	NEXT
Pat_5C72:
	INSTR 2
	LEN 33
	NOTE E_, 3
	INSTR 16
	LEN 11
	NOTE E_, 2
	INSTR 15
	LEN 22
	NOTE F_, 3
	INSTR 16
	NOTE D_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE F_, 3
	INSTR 16
	LEN 11
	NOTE B_, 2
	NOTE E_, 2
	INSTR 15
	LEN 22
	NOTE F_, 3
	INSTR 2
	LEN 33
	NOTE E_, 3
	INSTR 16
	LEN 11
	NOTE E_, 2
	INSTR 14
	LEN 22
	NOTE Fsh, 3
	INSTR 16
	NOTE D_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 14
	NOTE Fsh, 3
	INSTR 16
	LEN 11
	NOTE B_, 2
	NOTE E_, 2
	INSTR 14
	LEN 22
	NOTE Fsh, 3
	INSTR 2
	LEN 33
	NOTE E_, 3
	INSTR 16
	LEN 11
	NOTE E_, 2
	INSTR 15
	LEN 22
	NOTE F_, 3
	INSTR 16
	NOTE D_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE F_, 3
	INSTR 16
	LEN 11
	NOTE B_, 2
	NOTE E_, 2
	INSTR 15
	LEN 22
	NOTE F_, 3
	INSTR 2
	LEN 11
	NOTE E_, 3
	LEN 22
	NOTE E_, 3
	LEN 11
	NOTE E_, 3
	INSTR 14
	LEN 22
	NOTE Fsh, 3
	INSTR 2
	LEN 11
	NOTE E_, 3
	LEN 22
	NOTE E_, 3
	LEN 11
	NOTE E_, 3
	INSTR 14
	LEN 22
	NOTE Fsh, 3
	INSTR 16
	LEN 11
	NOTE B_, 2
	NOTE E_, 2
	INSTR 14
	LEN 22
	NOTE Fsh, 3
	NEXT
Pat_5CD0:
	INSTR 2
	LEN 33
	NOTE E_, 3
	INSTR 16
	LEN 11
	NOTE E_, 2
	INSTR 15
	LEN 22
	NOTE Dsh, 3
	INSTR 16
	NOTE D_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE Dsh, 3
	INSTR 16
	LEN 11
	NOTE B_, 2
	NOTE E_, 2
	INSTR 15
	LEN 22
	NOTE Dsh, 3
	INSTR 2
	LEN 33
	NOTE E_, 3
	INSTR 16
	LEN 11
	NOTE E_, 2
	INSTR 14
	LEN 22
	NOTE F_, 3
	INSTR 16
	NOTE D_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 14
	NOTE F_, 3
	INSTR 16
	LEN 11
	NOTE B_, 2
	NOTE E_, 2
	INSTR 14
	LEN 22
	NOTE F_, 3
	INSTR 2
	LEN 33
	NOTE E_, 3
	INSTR 16
	LEN 11
	NOTE E_, 2
	INSTR 15
	LEN 22
	NOTE Dsh, 3
	INSTR 16
	NOTE D_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE Dsh, 3
	INSTR 16
	LEN 11
	NOTE B_, 2
	NOTE E_, 2
	INSTR 15
	LEN 22
	NOTE Dsh, 3
	INSTR 2
	LEN 11
	NOTE E_, 3
	LEN 22
	NOTE E_, 3
	LEN 11
	NOTE E_, 3
	INSTR 14
	LEN 22
	NOTE F_, 3
	INSTR 2
	LEN 11
	NOTE E_, 3
	LEN 22
	NOTE E_, 3
	LEN 11
	NOTE E_, 3
	INSTR 14
	LEN 22
	NOTE F_, 3
	INSTR 16
	LEN 11
	NOTE B_, 2
	NOTE E_, 2
	INSTR 14
	LEN 22
	NOTE F_, 3
	NEXT
Pat_5D2E:
	INSTR 2
	LEN 22
	NOTE E_, 3
	INSTR 15
	LEN 11
	NOTE Ash, 4
	INSTR 16
	NOTE E_, 2
	INSTR 1
	LEN 22
	NOTE A_, 3
	INSTR 16
	NOTE D_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE Ash, 4
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 16
	NOTE E_, 2
	INSTR 15
	LEN 22
	NOTE Ash, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 11
	NOTE Gsh, 4
	INSTR 16
	NOTE E_, 2
	INSTR 1
	LEN 22
	NOTE A_, 3
	INSTR 16
	NOTE D_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE Gsh, 4
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 16
	NOTE E_, 2
	INSTR 15
	LEN 22
	NOTE Gsh, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 11
	NOTE Ash, 4
	INSTR 16
	NOTE E_, 2
	INSTR 1
	LEN 22
	NOTE A_, 3
	INSTR 16
	NOTE D_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE Ash, 4
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 16
	NOTE E_, 2
	INSTR 15
	LEN 22
	NOTE Ash, 4
	INSTR 2
	LEN 11
	NOTE E_, 3
	NOTE E_, 3
	INSTR 15
	NOTE Gsh, 4
	INSTR 2
	NOTE E_, 3
	INSTR 1
	LEN 22
	NOTE A_, 3
	INSTR 2
	LEN 11
	NOTE E_, 3
	LEN 22
	NOTE E_, 3
	LEN 11
	NOTE E_, 3
	INSTR 15
	LEN 22
	NOTE Gsh, 4
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 16
	NOTE E_, 2
	INSTR 2
	LEN 22
	NOTE E_, 3
	NEXT
Pat_5D95:
	INSTR 2
	LEN 22
	NOTE E_, 3
	INSTR 14
	LEN 11
	NOTE E_, 4
	INSTR 16
	NOTE E_, 2
	INSTR 1
	LEN 22
	NOTE A_, 3
	INSTR 16
	NOTE D_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 14
	NOTE E_, 4
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 16
	NOTE E_, 2
	INSTR 14
	LEN 22
	NOTE E_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 11
	NOTE Csh, 4
	INSTR 16
	NOTE E_, 2
	INSTR 1
	LEN 22
	NOTE A_, 3
	INSTR 16
	NOTE D_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE Csh, 4
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 16
	NOTE E_, 2
	INSTR 15
	LEN 22
	NOTE Csh, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 11
	NOTE Gsh, 4
	INSTR 16
	NOTE E_, 2
	INSTR 1
	LEN 22
	NOTE A_, 3
	INSTR 16
	NOTE D_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE Gsh, 4
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 16
	NOTE E_, 2
	INSTR 15
	LEN 22
	NOTE Gsh, 4
	VOLENV 11, $00, $1F, $1F
	LENGTH $B0
	NOTE Gsh, 3
	NEXT
Pat_5DE6:
	DRUMS $0B, DrumPat_5F01
	VIBRATO $0B, $03, $04
	PAN_R
	HWENV $00, $00
	LEN 11
	WAIT
	INSTR 13
	LEN 22
	NOTE F_, 2
	NOTE C_, 3
	NOTE B_, 2
	LENGTH $6E
	NOTE Dsh, 3
	LEN 22
	NOTE F_, 2
	NOTE C_, 3
	NOTE B_, 2
	LENGTH $6E
	NOTE Dsh, 3
	LEN 22
	NOTE F_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE C_, 5
	LENGTH $A5
	NOTE B_, 4
	PAN_C
	NEXT
Pat_5E11:
	DRUMS $0B, DrumPat_5F0D
	INSTR 12
	LEN 22
	REPEAT 10
	NOTE F_, 2
	NOTE F_, 2
	REPEAT_END
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	PAN_R
	INSTR 11
	DUTY_75
	NOTE F_, 2
	DRUMS $0B, DrumPat_5F2C
	LEN 11
	NOTE Fsh, 2
	NOTE Fsh, 2
	REST
	LEN 33
	NOTE Fsh, 2
	LEN 11
	NOTE Csh, 3
	NOTE Csh, 3
	REST
	LEN 33
	NOTE Csh, 3
	LEN 44
	NOTE E_, 2
	PAN_C
	NEXT
Pat_5E36:
	DRUMS $0B, DrumPat_5F0D
	INSTR 12
	LEN 22
	REPEAT 10
	NOTE F_, 2
	NOTE F_, 2
	REPEAT_END
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	PAN_R
	DUTY_75
	INSTR 11
	NOTE F_, 2
	DRUMS $0B, DrumPat_5F2C
	LEN 11
	NOTE Fsh, 2
	NOTE Fsh, 2
	REST
	LEN 33
	NOTE Fsh, 2
	LEN 11
	NOTE Csh, 3
	NOTE Csh, 3
	REST
	LEN 33
	NOTE Csh, 3
	LEN 44
	NOTE Fsh, 2
	PAN_C
	NEXT
Pat_5E5B:
	DRUMS $0B, DrumPat_5F19
	LEN 22
	REPEAT 2
	INSTR 11
	NOTE F_, 2
	INSTR 12
	NOTE F_, 2
	NOTE F_, 3
	INSTR 11
	NOTE F_, 2
	INSTR 12
	NOTE F_, 2
	NOTE F_, 3
	INSTR 11
	NOTE F_, 2
	INSTR 12
	NOTE F_, 3
	INSTR 11
	NOTE Fsh, 2
	INSTR 12
	NOTE Fsh, 2
	NOTE Fsh, 3
	INSTR 11
	NOTE Fsh, 2
	INSTR 12
	NOTE Fsh, 2
	NOTE Fsh, 3
	NOTE Fsh, 2
	INSTR 11
	NOTE E_, 2
	REPEAT_END
	NEXT
Pat_5E7E:
	LEN 22
	INSTR 11
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 2
	NOTE Dsh, 3
	INSTR 11
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 2
	NOTE Dsh, 3
	INSTR 11
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 3
	INSTR 11
	NOTE F_, 2
	INSTR 12
	NOTE F_, 2
	NOTE F_, 3
	INSTR 11
	NOTE F_, 2
	INSTR 12
	NOTE F_, 2
	NOTE F_, 3
	INSTR 11
	NOTE F_, 2
	INSTR 12
	NOTE F_, 3
	INSTR 11
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 2
	NOTE Dsh, 3
	INSTR 11
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 2
	NOTE Dsh, 3
	INSTR 11
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 3
	INSTR 11
	NOTE F_, 2
	INSTR 12
	NOTE F_, 2
	NOTE F_, 3
	INSTR 11
	NOTE F_, 2
	INSTR 12
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	INSTR 11
	NOTE A_, 2
	NEXT
Pat_5EB7:
	DRUMS $0B, DrumPat_5F3E
	INSTR 11
	LEN 22
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 3
	NEXT
Pat_5EDE:
	INSTR 11
	LEN 22
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 3
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 3
	NOTE E_, 2
	NOTE E_, 3
	NOTE Csh, 2
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE Csh, 2
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 3
	DRUMS_OFF
	CALL_CODE Drum7
	LENGTH $58
	NOTE Gsh, 2
	NOTE Gsh, 2
	NEXT
DrumPat_5F01:
	db DRUM_LEVEL + 13, DRUM_REPEAT + 8, 3, 0, 0, 0, 0, 0
	db 0, 0, DRUM_REPEAT_END, DRUM_LOOP
DrumPat_5F0D:
	db DRUM_LEVEL + 13, DRUM_REPEAT + 8, 6, 0, 6, 0, 3, 0
	db 6, 0, DRUM_REPEAT_END, DRUM_LOOP
DrumPat_5F19:
	db DRUM_LEVEL + 13, DRUM_REPEAT + 3, 1, 8, 5, 6, 3, 8
	db 6, 8, 1, 8, 5, 6, 3, 6
	db 4, 0, DRUM_REPEAT_END
DrumPat_5F2C:
	db DRUM_LEVEL + 13, 1, 1, 5, 1, 3, 8, 1
	db 1, 8, 1, 5, 6, 3, 8, 4
	db 0, DRUM_LOOP
DrumPat_5F3E:
	db DRUM_LEVEL + 13, DRUM_REPEAT + 3, 1, 8, 5, 6, 9, 8
	db 6, 8, 1, 8, 5, 6, 9, 6
	db 4, 0, DRUM_REPEAT_END, DRUM_LEVEL + 13, 1, 1, 5, 1
	db 9, 8, 1, 1, 8, 1, 5, 6
	db 9, 8, 4, 0, DRUM_LOOP

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
	dw Pat_5F7E
Song9_Ch3:
	dw Pat_5FA4
Song9_Ch2:
	dw Pat_5FD6
Pat_5F7E:
	AUTODUTY $07
	INSTR 11
	LEN 7
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE Ash, 2
	LEN 42
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	LEN 42
	NOTE G_, 2
	NOTE G_, 2
	LEN 28
	NOTE F_, 2
	LEN 7
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN 14
	NOTE Ash, 2
	LEN 42
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	LENGTH $70
	NOTE G_, 2
	END
Pat_5FA4:
	CH_TRANSPOSE $0C
	INSTR 2
	LEN 21
	NOTE G_, 3
	INSTR 17
	NOTE A_, 3
	LEN 14
	NOTE A_, 3
	INSTR 2
	NOTE G_, 3
	INSTR 17
	NOTE A_, 3
	LEN 28
	NOTE A_, 3
	INSTR 2
	LEN 21
	NOTE G_, 3
	INSTR 17
	NOTE A_, 3
	LEN 14
	NOTE A_, 3
	INSTR 2
	NOTE G_, 3
	INSTR 17
	NOTE A_, 3
	NOTE A_, 3
	INSTR 2
	NOTE G_, 3
	LEN 21
	NOTE G_, 3
	INSTR 17
	NOTE A_, 3
	LEN 14
	NOTE A_, 3
	INSTR 2
	NOTE G_, 3
	INSTR 17
	NOTE A_, 3
	NOTE A_, 3
	INSTR 14
	NOTE F_, 3
	INSTR 15
	NOTE G_, 3
	NOTE G_, 3
	NOTE F_, 3
	LENGTH $70
	NOTE G_, 3
	END
Pat_5FD6:
	DRUMS $07, DrumPat_600F
	INSTR 9
	LEN 7
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	LEN 14
	NOTE F_, 3
	LEN 42
	NOTE D_, 3
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	INSTR 13
	LEN 28
	NOTE G_, 3
	NOTE D_, 4
	NOTE Csh, 4
	NOTE F_, 4
	INSTR 9
	LEN 7
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	LEN 14
	NOTE F_, 3
	LEN 42
	NOTE D_, 3
	LEN 14
	NOTE G_, 4
	INSTR 11
	NOTE F_, 3
	DRUMS_OFF
	CALL_CODE Drum7
	NOTE G_, 3
	CALL_CODE Drum7
	NOTE G_, 3
	CALL_CODE Drum7
	NOTE F_, 3
	CALL_CODE Drum7
	LENGTH $70
	NOTE G_, 3
	END
DrumPat_600F:
	db DRUM_REPEAT + 2, 1, 0, 6, 6, 0, 0, 6
	db 0, 1, 0, 6, 0, 0, 0, 1
	db 0, DRUM_REPEAT_END, DRUM_LOOP

; Song 10: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong10:
	call StopAll
	ld de, Song10_Ch1
	call L48F0
	ld de, Song10_Ch3
	call L490C
	ld de, Song10_Ch2
	jp L48FE
Song10_Ch1:
	dw Pat_614D
	dw Pat_6085
	dw Pat_6085
	dw Pat_6085
	dw Pat_609B
	dw Pat_60C3
	dw Pat_60C3
	dw Pat_610F
	dw Pat_6111
	dw Pat_610F
	dw Pat_6111
	ORDER_LOOP Song10_Ch1
Song10_Ch3:
	dw Pat_616C
	dw Pat_6172
	dw Pat_6172
	dw Pat_6172
	dw Pat_6172
	dw Pat_6172
	dw Pat_6172
	dw Pat_6172
	dw Pat_6172
	dw Pat_6172
	dw Pat_6172
	ORDER_LOOP Song10_Ch3
Song10_Ch2:
	dw Pat_62B0
	dw Pat_619A
	dw Pat_61B3
	dw Pat_619A
	dw Pat_61C6
	dw Pat_61E1
	dw Pat_6209
	dw Pat_6231
	dw Pat_6263
	dw Pat_622D
	dw Pat_6263
	ORDER_LOOP Song10_Ch2
Pat_6085:
	REPEAT 4
	INSTR 11
	LEN 27
	NOTE A_, 2
	LEN 9
	NOTE A_, 2
	INSTR 5
	LEN 18
	NOTE A_, 3
	INSTR 11
	LEN 9
	NOTE E_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	LEN 18
	NOTE A_, 2
	INSTR 5
	LEN 36
	NOTE A_, 3
	REPEAT_END
	NEXT
Pat_609B:
	REPEAT 3
	INSTR 11
	LEN 27
	NOTE A_, 2
	LEN 9
	NOTE A_, 2
	INSTR 5
	LEN 18
	NOTE A_, 3
	INSTR 11
	LEN 9
	NOTE E_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	LEN 18
	NOTE A_, 2
	INSTR 5
	LEN 36
	NOTE A_, 3
	REPEAT_END
	INSTR 11
	LEN 27
	NOTE A_, 2
	LEN 9
	NOTE A_, 2
	INSTR 5
	LEN 18
	NOTE A_, 3
	INSTR 11
	LEN 9
	NOTE E_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	LEN 18
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	NEXT
Pat_60C3:
	INSTR 11
	LEN 27
	NOTE F_, 2
	LEN 9
	NOTE F_, 2
	INSTR 4
	LEN 18
	NOTE F_, 4
	INSTR 11
	LEN 9
	NOTE C_, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE F_, 2
	LEN 18
	NOTE F_, 2
	INSTR 4
	LEN 36
	NOTE F_, 4
	INSTR 11
	LEN 27
	NOTE G_, 2
	LEN 9
	NOTE G_, 2
	INSTR 4
	LEN 18
	NOTE G_, 4
	INSTR 11
	LEN 9
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	LEN 18
	NOTE G_, 2
	INSTR 4
	LEN 36
	NOTE G_, 4
	INSTR 11
	LEN 27
	NOTE A_, 2
	LEN 9
	NOTE A_, 2
	INSTR 5
	LEN 18
	NOTE A_, 4
	INSTR 11
	LEN 9
	NOTE E_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	LEN 18
	NOTE A_, 2
	NOTE C_, 2
	NOTE E_, 2
	LEN 27
	NOTE A_, 2
	LEN 9
	NOTE A_, 2
	INSTR 5
	LEN 18
	NOTE A_, 4
	INSTR 11
	LEN 9
	NOTE E_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	LEN 18
	NOTE A_, 2
	NOTE A_, 2
	LEN 9
	NOTE G_, 2
	NOTE E_, 2
	NEXT
Pat_610F:
	CH_TRANSPOSE $FB
Pat_6111:
	INSTR 11
	LEN 27
	NOTE A_, 2
	LEN 9
	NOTE G_, 2
	INSTR 5
	LEN 18
	NOTE A_, 4
	INSTR 11
	LEN 27
	NOTE A_, 2
	NOTE G_, 2
	LEN 18
	NOTE A_, 2
	NOTE C_, 3
	LEN 27
	NOTE A_, 2
	LEN 9
	NOTE G_, 2
	INSTR 5
	LEN 18
	NOTE A_, 4
	INSTR 11
	LEN 27
	NOTE A_, 2
	NOTE G_, 2
	LEN 18
	NOTE D_, 3
	NOTE E_, 3
	LEN 27
	NOTE A_, 2
	LEN 9
	NOTE G_, 2
	INSTR 5
	LEN 18
	NOTE A_, 4
	INSTR 11
	LEN 27
	NOTE A_, 2
	NOTE G_, 2
	LEN 18
	NOTE A_, 2
	NOTE C_, 3
	LEN 27
	NOTE A_, 2
	LEN 9
	NOTE G_, 2
	INSTR 5
	LEN 18
	NOTE A_, 4
	INSTR 11
	LEN 27
	NOTE A_, 2
	NOTE G_, 2
	LEN 18
	NOTE G_, 3
	NOTE A_, 3
	CH_TRANSPOSE $00
	NEXT
Pat_614D:
	INSTR 11
	REPEAT 3
	LEN 27
	NOTE A_, 2
	NOTE A_, 2
	LEN 9
	NOTE E_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	LENGTH $36
	NOTE A_, 2
	REPEAT_END
	LEN 27
	NOTE A_, 2
	NOTE A_, 2
	LEN 9
	NOTE E_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	LEN 18
	NOTE A_, 2
	ARP_OFF
	GLIDE $FF
	LEN 36
	NOTE A_, 3
	GLIDE_OFF
	NEXT
Pat_616C:
	DRUMS $09, DrumPat_62BA
	CH_TRANSPOSE $0C
Pat_6172:
	LEN 18
	REPEAT 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE A_, 3
	INSTR 1
	LEN 9
	NOTE A_, 3
	INSTR 0
	LEN 27
	NOTE A_, 3
	INSTR 2
	LEN 18
	NOTE E_, 3
	NOTE E_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE G_, 3
	REPEAT_END
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE A_, 3
	INSTR 1
	LEN 9
	NOTE A_, 3
	INSTR 0
	LEN 27
	NOTE A_, 3
	INSTR 2
	LEN 18
	NOTE E_, 3
	NOTE E_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	NEXT
Pat_619A:
	ARP_OFF
	HWENV $80, $48, $60
	RELEASE $04, $53
	VIBRATO $10, $02, $04
	DUTY_75
	LENGTH $90
	NOTE E_, 4
	LENGTH $48
	NOTE D_, 4
	NOTE G_, 4
	LENGTH $90
	NOTE E_, 4
	WAIT
	NEXT
Pat_61B3:
	LENGTH $90
	NOTE C_, 4
	LENGTH $48
	NOTE B_, 3
	LEN 36
	NOTE G_, 3
	NOTE A_, 3
	LENGTH $6C
	NOTE E_, 3
	LEN 18
	NOTE D_, 3
	NOTE G_, 3
	LENGTH $90
	NOTE E_, 3
	NEXT
Pat_61C6:
	LENGTH $90
	NOTE C_, 4
	LENGTH $48
	NOTE B_, 3
	LEN 36
	NOTE G_, 3
	NOTE B_, 3
	LENGTH $90
	RELEASE $00
	NOTE A_, 3
	INSTR 12
	LEN 27
	NOTE A_, 3
	NOTE A_, 3
	LEN 9
	NOTE E_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE A_, 3
	LENGTH $36
	NOTE A_, 3
	NEXT
Pat_61E1:
	ARP_OFF
	HWENV $80, $48, $60
	RELEASE $04, $53
	DUTY_75
	LEN 36
	NOTE F_, 3
	LEN 18
	NOTE A_, 3
	LEN 36
	NOTE D_, 4
	LEN 18
	NOTE C_, 4
	NOTE A_, 3
	LEN 36
	NOTE E_, 4
	LEN 18
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 36
	NOTE C_, 4
	NOTE B_, 3
	LENGTH $6C
	NOTE E_, 3
	LEN 18
	NOTE D_, 3
	NOTE G_, 3
	LENGTH $6C
	NOTE E_, 3
	LEN 18
	NOTE G_, 3
	NOTE E_, 3
	NEXT
Pat_6209:
	LEN 36
	NOTE F_, 3
	LEN 18
	NOTE A_, 3
	LEN 36
	NOTE D_, 4
	LEN 18
	NOTE C_, 4
	NOTE A_, 3
	LEN 36
	NOTE E_, 4
	LEN 18
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 36
	NOTE C_, 4
	NOTE B_, 3
	LENGTH $90
	RELEASE $00
	NOTE A_, 3
	INSTR 12
	LEN 27
	NOTE A_, 3
	NOTE A_, 3
	LEN 9
	NOTE E_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE A_, 3
	LENGTH $36
	NOTE A_, 3
	NEXT
Pat_622D:
	ARP 17
	PAT_GOTO Pat_6239
Pat_6231:
	HWENV $E1, $08, $53
	DUTY_12
	RELEASE $00
	ARP 10
Pat_6239:
	LEN 18
	NOTE E_, 3
	NOTE E_, 4
	LEN 9
	NOTE E_, 3
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE F_, 3
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE E_, 3
	LEN 18
	NOTE B_, 3
	LEN 9
	NOTE A_, 3
	NOTE B_, 3
	NOTE F_, 3
	REPEAT 3
	NOTE E_, 3
	NOTE F_, 3
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE E_, 3
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE F_, 3
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE E_, 3
	LEN 18
	NOTE B_, 3
	LEN 9
	NOTE A_, 3
	NOTE B_, 3
	NOTE F_, 3
	REPEAT_END
	NEXT
Pat_6263:
	LEN 9
	NOTE G_, 3
	NOTE A_, 3
	LEN 18
	NOTE A_, 4
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE F_, 4
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE A_, 3
	NOTE B_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	LEN 18
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE A_, 4
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE F_, 4
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE A_, 3
	NOTE B_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	LEN 18
	NOTE C_, 4
	NOTE B_, 3
	LEN 9
	NOTE A_, 3
	NEXT
Pat_62B0:
	HWENV $00, $00
	LENGTH $90
	WAIT
	WAIT
	WAIT
	WAIT
	NEXT
DrumPat_62BA:
	db DRUM_REPEAT + 3, DRUM_LEVEL + 14, 1, 6, 6, 10, DRUM_LEVEL + 15, 9
	db DRUM_LEVEL + 14, 6, 6, 10, 1, 10, 1, 6
	db DRUM_LEVEL + 15, 9, DRUM_LEVEL + 14, 6, 4, 10, DRUM_REPEAT_END, DRUM_LEVEL + 14
	db 1, 6, 6, 10, DRUM_LEVEL + 15, 9, DRUM_LEVEL + 14, 6
	db 6, 10, 1, 10, 1, 6, DRUM_LEVEL + 15, 9
	db 10, 1, 9, DRUM_LOOP

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
	dw Pat_6337
	dw Pat_635C
	dw Pat_6378
	dw Pat_6386
Loop_6303:
	dw Pat_6396
	dw Pat_63BE
	dw Pat_6396
	dw Pat_63BE
	ORDER_LOOP Loop_6303
Song11_Ch3:
	dw Pat_63E6
	dw Pat_63E6
	dw Pat_63E6
	dw Pat_63E6
Loop_6317:
	dw Pat_6410
	dw Pat_6410
	dw Pat_6410
	dw Pat_6410
	ORDER_LOOP Loop_6317
Song11_Ch2:
	dw Pat_644B
	dw Pat_6470
	dw Pat_644B
	dw Pat_6470
Loop_632B:
	dw Pat_648C
	dw Pat_648C
	dw Pat_644B
	dw Pat_6470
	ORDER_LOOP Loop_632B
Pat_6337:
	HWENV $60, $00
	DUTY_75
	VIBRATO $00, $02, $04
	LEN 9
	REST
	LEN 36
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN 18
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	LENGTH $48
	NOTE A_, 3
	LEN 18
	NOTE G_, 3
	NOTE A_, 3
	LENGTH $6C
	NOTE D_, 3
	LEN 18
	NOTE C_, 3
	NOTE D_, 3
	LENGTH $7E
	NOTE A_, 3
	LEN 9
	NOTE A_, 3
	NEXT
Pat_635C:
	LEN 9
	WAIT
	LEN 36
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN 18
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	LENGTH $48
	NOTE A_, 3
	LEN 18
	NOTE G_, 3
	NOTE A_, 3
	LENGTH $5A
	NOTE D_, 3
	LEN 18
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 3
	LENGTH $87
	NOTE D_, 3
	NEXT
Pat_6378:
	INSTR 11
	LENGTH $48
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE G_, 2
	LEN 36
	NOTE G_, 2
	NOTE C_, 2
	NEXT
Pat_6386:
	INSTR 11
	LENGTH $48
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE D_, 2
	LEN 27
	NOTE D_, 2
	NOTE D_, 2
	LEN 18
	NOTE D_, 2
	NEXT
Pat_6396:
	INSTR 11
	LEN 18
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
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE A_, 2
	LEN 9
	NOTE C_, 3
	LEN 18
	NOTE A_, 2
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE F_, 2
	NEXT
Pat_63BE:
	INSTR 11
	LEN 18
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
	NOTE D_, 2
	NOTE D_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	LEN 9
	NOTE F_, 2
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE A_, 2
	LEN 18
	NOTE C_, 3
	NEXT
Pat_63E6:
	CH_TRANSPOSE $0C
	INSTR 18
	REPEAT 3
	LEN 18
	NOTE D_, 3
	LEN 9
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE G_, 3
	NOTE A_, 3
	REPEAT_END
	LEN 18
	NOTE D_, 3
	LEN 9
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	LEN 18
	NOTE F_, 3
	NOTE G_, 3
	NEXT
Pat_6410:
	DRUMS $09, DrumPat_64B5
	REPEAT 2
	INSTR 2
	LEN 18
	NOTE E_, 3
	INSTR 18
	LEN 9
	NOTE G_, 3
	NOTE A_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 18
	NOTE A_, 3
	LEN 18
	NOTE D_, 4
	INSTR 2
	LEN 9
	NOTE E_, 3
	INSTR 18
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	INSTR 1
	LEN 18
	NOTE A_, 3
	INSTR 18
	LEN 9
	NOTE G_, 3
	NOTE A_, 3
	REPEAT_END
	INSTR 2
	LEN 18
	NOTE E_, 3
	INSTR 18
	LEN 9
	NOTE G_, 3
	NOTE A_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 18
	NOTE A_, 3
	LEN 18
	NOTE D_, 4
	INSTR 2
	LEN 9
	NOTE E_, 3
	INSTR 18
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	INSTR 1
	LEN 18
	NOTE A_, 3
	INSTR 18
	NOTE G_, 3
	NEXT
Pat_644B:
	HWENV $F0, $09, $F7
	DUTY_75
	VIBRATO $12, $02, $04
	ARP_OFF
	LEN 36
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN 18
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	LENGTH $48
	NOTE A_, 3
	LEN 18
	NOTE G_, 3
	NOTE A_, 3
	LENGTH $6C
	NOTE D_, 3
	LEN 18
	NOTE C_, 3
	NOTE D_, 3
	LENGTH $7E
	NOTE A_, 3
	LEN 18
	NOTE A_, 3
	NEXT
Pat_6470:
	LEN 36
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN 18
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	LENGTH $48
	NOTE A_, 3
	LEN 18
	NOTE G_, 3
	NOTE A_, 3
	LENGTH $5A
	NOTE D_, 3
	LEN 18
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 3
	LEN 9
	NOTE C_, 3
	LENGTH $87
	NOTE D_, 3
	NEXT
Pat_648C:
	INSTR 9
	ARP 6
	REPEAT 3
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	LEN 18
	NOTE D_, 5
	LEN 9
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	LEN 18
	NOTE D_, 5
	LEN 9
	NOTE G_, 4
	NOTE A_, 4
	REPEAT_END
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	LEN 18
	NOTE D_, 5
	LEN 9
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	LEN 18
	NOTE F_, 4
	NOTE G_, 4
	NEXT
DrumPat_64B5:
	db DRUM_LEVEL + 14, 1, 6, 4, 0, 9, 6, 4
	db 0, DRUM_LOOP

; Song 12: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong12:
	call StopAll
	ld de, Song12_Ch1
	call L48F0
	ld de, Song12_Ch3
	call L490C
	ld de, Song12_Ch2
	jp L48FE

; Unreferenced (1 bytes)
	db $C9
Song12_Ch1:
	dw Pat_6535
	dw Pat_6592
Loop_64D9:
	dw Pat_65C5
	dw Pat_65C5
	dw Pat_65C5
	dw Pat_6563
	dw Pat_65C5
	dw Pat_6563
	dw Pat_65FF
	dw Pat_662E
	dw Pat_662E
	dw Pat_662E
	dw Pat_6675
	dw Pat_6535
	ORDER_LOOP Loop_64D9
Song12_Ch3:
	dw Pat_66BC
	dw Pat_66C2
Loop_64F9:
	dw Pat_66D8
	dw Pat_66D8
	dw Pat_66F2
	dw Pat_6744
	dw Pat_66F2
	dw Pat_6744
	dw Pat_6796
	dw Pat_67E8
	dw Pat_683A
	dw Pat_67E8
	dw Pat_688C
	dw Pat_66BC
	ORDER_LOOP Loop_64F9
Song12_Ch2:
	dw Pat_68DE
	dw Pat_68DE
Loop_6519:
	dw Pat_68FC
	dw Pat_68FC
	dw Pat_6928
	dw Pat_694D
	dw Pat_6928
	dw Pat_694D
	dw Pat_696A
	dw Pat_699D
	dw Pat_69CB
	dw Pat_699D
	dw Pat_69FC
	dw Pat_68F1
	ORDER_LOOP Loop_6519
Pat_6535:
	INSTR 11
	LEN 14
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	INSTR 11
	NOTE C_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	INSTR 11
	NOTE C_, 2
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	INSTR 11
	NOTE C_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NEXT
Pat_6563:
	INSTR 11
	LEN 14
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	INSTR 11
	NOTE C_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	INSTR 11
	NOTE F_, 2
	NOTE G_, 2
	INSTR 12
	NOTE G_, 3
	INSTR 11
	NOTE G_, 2
	INSTR 12
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	INSTR 11
	NOTE G_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	INSTR 12
	NOTE A_, 3
	NOTE A_, 2
	INSTR 11
	NOTE A_, 2
	NOTE F_, 2
	NOTE E_, 2
	NEXT
Pat_6592:
	INSTR 11
	LEN 14
	NOTE G_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 11
	NOTE G_, 2
	INSTR 12
	NOTE D_, 3
	NOTE G_, 2
	NOTE D_, 3
	NOTE G_, 2
	INSTR 11
	NOTE G_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	INSTR 12
	NOTE D_, 3
	NOTE F_, 2
	NOTE D_, 3
	NOTE F_, 2
	INSTR 11
	NOTE F_, 2
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 3
	INSTR 11
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	INSTR 11
	NOTE Dsh, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	NOTE D_, 2
	LEN 7
	NOTE D_, 3
	NOTE D_, 3
	LEN 14
	NOTE D_, 2
	LEN 7
	NOTE D_, 3
	NOTE D_, 3
	NEXT
Pat_65C5:
	INSTR 11
	LEN 14
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	INSTR 11
	NOTE C_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	INSTR 11
	NOTE F_, 2
	NOTE G_, 2
	INSTR 12
	NOTE G_, 3
	INSTR 11
	NOTE G_, 2
	INSTR 12
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	INSTR 11
	NOTE F_, 2
	NOTE G_, 2
	INSTR 12
	LEN 7
	NOTE F_, 3
	NOTE G_, 3
	INSTR 11
	LEN 14
	NOTE G_, 2
	INSTR 12
	NOTE F_, 3
	INSTR 11
	NOTE A_, 2
	INSTR 12
	LEN 7
	NOTE G_, 3
	NOTE A_, 3
	INSTR 11
	LEN 14
	NOTE A_, 2
	INSTR 12
	NOTE G_, 3
	NEXT
Pat_65FF:
	INSTR 11
	LEN 14
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	INSTR 11
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	INSTR 11
	NOTE C_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	INSTR 12
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	INSTR 11
	NOTE A_, 2
	NOTE Gsh, 2
	NOTE G_, 2
	INSTR 12
	NOTE G_, 3
	INSTR 11
	NOTE G_, 2
	INSTR 12
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	INSTR 11
	NOTE G_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	INSTR 12
	NOTE A_, 3
	NOTE A_, 2
	INSTR 11
	NOTE A_, 2
	NOTE C_, 3
	NOTE D_, 3
	NEXT
Pat_662E:
	INSTR 11
	LEN 14
	NOTE G_, 2
	INSTR 12
	LEN 7
	NOTE D_, 3
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE G_, 3
	INSTR 11
	LEN 14
	NOTE G_, 2
	INSTR 12
	NOTE D_, 3
	NOTE F_, 3
	INSTR 11
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	INSTR 12
	LEN 7
	NOTE D_, 3
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE G_, 3
	INSTR 11
	LEN 14
	NOTE G_, 2
	INSTR 12
	NOTE D_, 3
	NOTE F_, 3
	INSTR 11
	NOTE A_, 2
	NOTE C_, 3
	NOTE D_, 2
	INSTR 12
	LEN 7
	NOTE A_, 2
	LEN 14
	NOTE C_, 3
	LEN 7
	NOTE D_, 3
	INSTR 11
	LEN 14
	NOTE D_, 2
	INSTR 12
	NOTE A_, 2
	NOTE C_, 3
	INSTR 11
	NOTE A_, 2
	NOTE C_, 3
	NOTE D_, 2
	INSTR 12
	LEN 7
	NOTE A_, 2
	LEN 14
	NOTE C_, 3
	LEN 7
	NOTE D_, 3
	INSTR 11
	LEN 14
	NOTE D_, 2
	INSTR 12
	NOTE A_, 2
	INSTR 11
	NOTE D_, 2
	NOTE A_, 2
	NOTE Gsh, 2
	NEXT
Pat_6675:
	INSTR 11
	LEN 14
	NOTE G_, 2
	INSTR 12
	LEN 7
	NOTE D_, 3
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE G_, 3
	INSTR 11
	LEN 14
	NOTE G_, 2
	INSTR 12
	NOTE D_, 3
	NOTE F_, 3
	INSTR 11
	NOTE D_, 2
	NOTE F_, 2
	NOTE G_, 2
	INSTR 12
	LEN 7
	NOTE D_, 3
	LEN 14
	NOTE F_, 3
	LEN 7
	NOTE G_, 3
	INSTR 11
	LEN 14
	NOTE G_, 2
	INSTR 12
	NOTE D_, 3
	NOTE F_, 3
	INSTR 11
	NOTE C_, 3
	NOTE G_, 2
	NOTE A_, 2
	INSTR 12
	LEN 7
	NOTE E_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE A_, 3
	INSTR 11
	LEN 14
	NOTE A_, 2
	INSTR 12
	NOTE E_, 3
	NOTE G_, 3
	INSTR 11
	NOTE E_, 2
	NOTE G_, 2
	NOTE A_, 2
	INSTR 12
	LEN 7
	NOTE E_, 3
	LEN 14
	NOTE G_, 3
	LEN 7
	NOTE A_, 3
	INSTR 11
	LEN 14
	NOTE A_, 2
	INSTR 12
	NOTE E_, 3
	NOTE G_, 3
	INSTR 11
	NOTE C_, 3
	NOTE A_, 2
	NEXT
Pat_66BC:
	CH_TRANSPOSE $0C
	DRUMS $07, DrumPat_6A2C
Pat_66C2:
	REPEAT 4
	INSTR 2
	LEN 21
	NOTE E_, 3
	INSTR 17
	LEN 7
	NOTE C_, 4
	INSTR 2
	LEN 14
	NOTE E_, 3
	INSTR 17
	NOTE C_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 17
	NOTE G_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 17
	NOTE G_, 3
	REPEAT_END
	NEXT
Pat_66D8:
	DRUMS $07, DrumPat_6A32
	REPEAT 4
	INSTR 2
	LEN 21
	NOTE E_, 3
	INSTR 17
	LEN 7
	NOTE C_, 4
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 17
	NOTE C_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 17
	NOTE G_, 3
	INSTR 1
	NOTE A_, 3
	INSTR 17
	NOTE G_, 3
	REPEAT_END
	NEXT
Pat_66F2:
	INSTR 2
	LEN 14
	NOTE E_, 3
	INSTR 15
	LEN 7
	NOTE D_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 15
	NOTE D_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE D_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE D_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 7
	NOTE A_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 1
	LEN 14
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
	LEN 7
	NOTE G_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 7
	NOTE G_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE A_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE A_, 4
	NEXT
Pat_6744:
	INSTR 2
	LEN 14
	NOTE E_, 3
	INSTR 15
	LEN 7
	NOTE D_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 15
	NOTE D_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE D_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE D_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 7
	NOTE A_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 1
	LEN 14
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
	LEN 7
	NOTE G_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 14
	LEN 7
	NOTE F_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 14
	NOTE F_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 14
	NOTE F_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 14
	NOTE F_, 4
	NEXT
Pat_6796:
	INSTR 2
	LEN 14
	NOTE E_, 3
	INSTR 15
	LEN 7
	NOTE D_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 15
	NOTE D_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE D_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE D_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 7
	NOTE A_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 1
	LEN 14
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
	LEN 7
	NOTE G_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 7
	NOTE A_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 15
	NOTE A_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE D_, 5
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE D_, 5
	NEXT
Pat_67E8:
	INSTR 2
	LEN 14
	NOTE E_, 3
	INSTR 15
	LEN 7
	NOTE G_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 7
	NOTE G_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 7
	NOTE D_, 5
	INSTR 17
	NOTE C_, 4
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 15
	NOTE D_, 5
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE D_, 5
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE D_, 5
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 7
	NOTE D_, 5
	INSTR 17
	NOTE C_, 4
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 15
	NOTE D_, 5
	INSTR 2
	NOTE E_, 3
	INSTR 14
	NOTE C_, 5
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE D_, 5
	NEXT
Pat_683A:
	INSTR 2
	LEN 14
	NOTE E_, 3
	INSTR 15
	LEN 7
	NOTE G_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 7
	NOTE G_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 7
	NOTE D_, 5
	INSTR 17
	NOTE C_, 4
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 15
	NOTE D_, 5
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE D_, 5
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE D_, 5
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 7
	NOTE D_, 5
	INSTR 17
	NOTE C_, 4
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 15
	NOTE D_, 5
	INSTR 2
	NOTE E_, 3
	INSTR 14
	NOTE C_, 5
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE D_, 5
	NEXT
Pat_688C:
	INSTR 2
	LEN 14
	NOTE E_, 3
	INSTR 15
	LEN 7
	NOTE G_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 7
	NOTE G_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 14
	LEN 7
	NOTE A_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 14
	NOTE A_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 14
	NOTE A_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 14
	NOTE A_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 14
	LEN 7
	NOTE A_, 4
	INSTR 17
	NOTE C_, 4
	INSTR 1
	LEN 14
	NOTE A_, 3
	INSTR 14
	NOTE A_, 4
	INSTR 2
	NOTE E_, 3
	INSTR 14
	NOTE A_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 14
	NOTE A_, 4
	NEXT
Pat_68DE:
	VIBRATO $0E, $02, $04
	HWENV $00, $00
	LENGTH $E0
	REST
	REST
	NEXT
Pat_68EA:
	HWENV $C2, $0E, $50
	DUTY_75
	ARP_OFF
	NEXT
Pat_68F1:
	PAT_CALL Pat_68EA
	LENGTH $38
	NOTE D_, 4
	LENGTH $C4
	REST
	REST
	NEXT
Pat_68FC:
	HWENV $F1, $03, $65
	AUTODUTY $07
	ARP 5
	LEN 21
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN 14
	NOTE D_, 4
	NOTE D_, 4
	LEN 21
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	LEN 14
	NOTE A_, 4
	NOTE A_, 4
	LEN 21
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	LEN 21
	NOTE G_, 4
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	LEN 21
	NOTE A_, 4
	NOTE A_, 4
	LEN 14
	NOTE A_, 4
	AUTODUTY $00
	NEXT
Pat_6928:
	PAT_CALL Pat_68EA
	LEN 28
	NOTE A_, 3
	LEN 14
	NOTE D_, 4
	NOTE E_, 4
	LENGTH $54
	NOTE F_, 4
	LEN 14
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE F_, 4
	LEN 42
	NOTE D_, 4
	LEN 14
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE A_, 4
	LEN 28
	NOTE A_, 4
	LEN 14
	NOTE G_, 4
	NOTE C_, 5
	LEN 28
	NOTE C_, 5
	LEN 14
	NOTE E_, 4
	NOTE F_, 4
	NEXT
Pat_694D:
	LEN 28
	NOTE A_, 3
	LEN 14
	NOTE D_, 4
	NOTE E_, 4
	LENGTH $54
	NOTE F_, 4
	LEN 14
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE F_, 4
	LEN 42
	NOTE D_, 4
	LEN 14
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE A_, 4
	LEN 28
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE A_, 3
	NEXT
Pat_696A:
	PAT_CALL Pat_68EA
	LENGTH $7E
	NOTE D_, 4
	INSTR 12
	LEN 7
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 28
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 14
	NOTE F_, 4
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE E_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 14
	NOTE C_, 4
	NOTE A_, 3
	NEXT
Pat_699D:
	PAT_CALL Pat_68EA
	LEN 21
	NOTE D_, 4
	NOTE F_, 4
	LEN 14
	NOTE A_, 4
	NOTE G_, 4
	INSTR 12
	LEN 7
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE D_, 4
	WAIT
	PAT_CALL Pat_68EA
	LEN 21
	NOTE D_, 4
	NOTE F_, 4
	LEN 14
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	LEN 21
	NOTE D_, 5
	NOTE C_, 5
	LEN 14
	NOTE D_, 5
	LENGTH $38
	NOTE A_, 4
	LEN 21
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE A_, 4
	LEN 14
	NOTE G_, 4
	NOTE F_, 4
	NEXT
Pat_69CB:
	LEN 21
	NOTE D_, 4
	NOTE F_, 4
	LEN 14
	NOTE A_, 4
	NOTE G_, 4
	INSTR 12
	LEN 7
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE D_, 4
	WAIT
	PAT_CALL Pat_68EA
	LEN 21
	NOTE D_, 4
	NOTE F_, 4
	LEN 14
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE E_, 4
	LEN 21
	NOTE F_, 4
	NOTE E_, 4
	LEN 14
	NOTE D_, 4
	LENGTH $38
	NOTE A_, 3
	LEN 14
	NOTE D_, 3
	LEN 7
	NOTE A_, 3
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE D_, 3
	NOTE A_, 3
	NOTE D_, 3
	NOTE A_, 3
	NOTE Gsh, 3
	NEXT
Pat_69FC:
	LEN 21
	NOTE D_, 4
	NOTE F_, 4
	LEN 14
	NOTE A_, 4
	NOTE G_, 4
	INSTR 12
	LEN 7
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE D_, 4
	WAIT
	PAT_CALL Pat_68EA
	LEN 21
	NOTE D_, 4
	NOTE F_, 4
	LEN 14
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE G_, 4
	LEN 21
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE E_, 4
	LEN 14
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	LEN 7
	NOTE A_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 28
	NOTE A_, 4
	LEN 14
	NOTE C_, 5
	NOTE G_, 4
	NOTE F_, 4
	NEXT
DrumPat_6A2C:
	db DRUM_LEVEL + 14, 1, 0, 6, 0, DRUM_LOOP
DrumPat_6A32:
	db DRUM_LEVEL + 14, 1, 0, 6, 0, 9, 0, 6
	db 0, DRUM_LOOP

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
	dw Pat_6AA5
	dw Pat_6B2F
	dw Pat_6B74
	dw Pat_6B16
	dw Pat_6AF9
	dw Pat_6B5E
	dw Pat_6B7A
	dw Pat_6B74
	dw Pat_6B16
	dw Pat_6AF9
	dw Pat_6B5E
	dw Pat_6B7A
	ORDER_LOOP Song13_Ch1
Song13_Ch3:
	dw Pat_6BA2
	dw Pat_6BBC
	dw Pat_6C3F
	dw Pat_6C3F
	dw Pat_6C30
	dw Pat_6BFB
	dw Pat_6C3F
	dw Pat_6C3F
	dw Pat_6C3F
	dw Pat_6C30
	dw Pat_6BFB
	dw Pat_6C3F
	ORDER_LOOP Song13_Ch3
Song13_Ch2:
	dw Pat_6C4A
	dw Pat_6CB2
	dw Pat_6CC7
	dw Pat_6CF2
	dw Pat_6C5B
	dw Pat_6C87
	dw Pat_6CB2
	dw Pat_6CC7
	dw Pat_6CF2
	dw Pat_6C5B
	dw Pat_6C87
	dw Pat_6CB2
	ORDER_LOOP Song13_Ch2
Pat_6AA5:
	INSTR 12
	LEN 18
	REPEAT 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	REPEAT_END
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE F_, 2
	NOTE F_, 2
	NEXT
Pat_6ABA:
	INSTR 11
	LEN 18
	NOTE F_, 2
	INSTR 12
	LEN 9
	NOTE F_, 3
	LEN 18
	NOTE F_, 2
	LEN 9
	NOTE F_, 2
	INSTR 11
	LEN 18
	NOTE C_, 3
	INSTR 12
	NOTE C_, 4
	NOTE C_, 3
	NOTE Gsh, 2
	LEN 9
	NOTE G_, 2
	NOTE Fsh, 2
	NEXT
Pat_6ACF:
	INSTR 11
	LEN 18
	NOTE F_, 2
	INSTR 12
	LEN 9
	NOTE F_, 3
	LEN 18
	NOTE F_, 2
	LEN 9
	NOTE F_, 2
	INSTR 11
	LEN 18
	NOTE C_, 3
	INSTR 12
	NOTE C_, 4
	NOTE C_, 3
	NOTE Gsh, 2
	LEN 9
	NOTE F_, 2
	NOTE Fsh, 2
	NEXT
Pat_6AE4:
	INSTR 11
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 2
	INSTR 11
	LEN 18
	NOTE Gsh, 2
	INSTR 12
	NOTE Gsh, 3
	NOTE Gsh, 2
	NOTE Gsh, 2
	LEN 9
	NOTE Gsh, 3
	NOTE Gsh, 2
	NEXT
Pat_6AF9:
	PAT_CALL Pat_6ABA
	PAT_CALL Pat_6ACF
	PAT_CALL Pat_6AE4
	INSTR 11
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 2
	INSTR 11
	LEN 18
	NOTE Gsh, 2
	INSTR 12
	NOTE Gsh, 3
	NOTE Gsh, 2
	INSTR 11
	NOTE G_, 2
	NOTE Fsh, 2
	NEXT
Pat_6B16:
	REPEAT 3
	PAT_CALL Pat_6AE4
	REPEAT_END
	INSTR 11
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 2
	INSTR 11
	LEN 18
	NOTE Gsh, 2
	INSTR 12
	NOTE Gsh, 3
	NOTE Gsh, 2
	INSTR 11
	NOTE G_, 2
	NOTE Fsh, 2
	NEXT
Pat_6B2F:
	INSTR 11
	LEN 18
	NOTE G_, 2
	INSTR 12
	NOTE G_, 2
	NOTE G_, 2
	INSTR 11
	NOTE Gsh, 2
	INSTR 12
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	INSTR 11
	NOTE G_, 2
	INSTR 12
	NOTE G_, 2
	NOTE G_, 2
	INSTR 11
	NOTE Gsh, 2
	INSTR 12
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	INSTR 11
	NOTE F_, 2
	NOTE G_, 2
	INSTR 12
	NOTE G_, 2
	NOTE G_, 2
	INSTR 11
	NOTE Gsh, 2
	INSTR 12
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	INSTR 11
	NOTE G_, 2
	INSTR 12
	NOTE G_, 2
	NOTE G_, 2
	INSTR 11
	LENGTH $5A
	NOTE Gsh, 2
	NEXT
Pat_6B5E:
	PAT_CALL Pat_6ABA
	PAT_CALL Pat_6ACF
	PAT_CALL Pat_6AE4
	INSTR 11
	LENGTH $51
	NOTE G_, 2
	INSTR 12
	LEN 18
	NOTE D_, 2
	LEN 9
	NOTE D_, 2
	LEN 18
	NOTE F_, 2
	NOTE Fsh, 2
	NEXT
Pat_6B74:
	REPEAT 4
	PAT_CALL Pat_6AE4
	REPEAT_END
	NEXT
Pat_6B7A:
	REPEAT 3
	PAT_CALL Pat_6AE4
	REPEAT_END
	INSTR 11
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 2
	INSTR 11
	LENGTH $5A
	NOTE Gsh, 2
	NEXT
Pat_6B8E:
	LEN 18
	REPEAT 3
	INSTR 2
	NOTE E_, 3
	INSTR 16
	NOTE C_, 3
	NOTE A_, 3
	INSTR 2
	LEN 27
	NOTE E_, 3
	INSTR 17
	LEN 18
	NOTE A_, 3
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE F_, 3
	NOTE E_, 3
	REPEAT_END
	NEXT
Pat_6BA2:
	CH_TRANSPOSE $0C
	DRUMS $09, DrumPat_6D11
	PAT_CALL Pat_6B8E
	INSTR 2
	NOTE E_, 3
	INSTR 16
	NOTE C_, 3
	NOTE A_, 3
	INSTR 2
	LEN 27
	NOTE E_, 3
	INSTR 17
	LEN 18
	NOTE A_, 3
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE F_, 3
	NOTE E_, 3
	NEXT
Pat_6BBC:
	PAT_CALL Pat_6B8E
	INSTR 2
	NOTE E_, 3
	INSTR 16
	NOTE C_, 3
	NOTE A_, 3
	DRUMS_OFF
	CALL_CODE Drum7
	INSTR 2
	LENGTH $5A
	NOTE E_, 3
	NEXT
Pat_6BCD:
	LEN 18
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 14
	LEN 9
	NOTE Gsh, 4
	INSTR 17
	LEN 18
	NOTE A_, 3
	LEN 9
	NOTE G_, 3
	INSTR 1
	LEN 18
	NOTE A_, 3
	INSTR 17
	NOTE E_, 3
	NEXT
Pat_6BE4:
	LEN 18
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE F_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 15
	LEN 9
	NOTE F_, 4
	INSTR 17
	LEN 18
	NOTE A_, 3
	LEN 9
	NOTE G_, 3
	INSTR 1
	LEN 18
	NOTE A_, 3
	INSTR 17
	NOTE E_, 3
	NEXT
Pat_6BFB:
	DRUMS $09, DrumPat_6D23
	REPEAT 2
	PAT_CALL Pat_6BE4
	REPEAT_END
	INSTR 2
	NOTE E_, 3
	INSTR 15
	NOTE G_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 14
	LEN 9
	NOTE Gsh, 4
	INSTR 17
	LEN 18
	NOTE A_, 3
	LEN 9
	NOTE G_, 3
	INSTR 1
	LEN 18
	NOTE A_, 3
	INSTR 17
	NOTE E_, 3
	DRUMS_OFF
	CALL_CODE Drum7
	INSTR 15
	LENGTH $51
	NOTE G_, 4
	DRUMS $09, DrumPat_6D35
	INSTR 2
	LEN 18
	NOTE E_, 3
	LEN 9
	NOTE E_, 3
	INSTR 1
	LEN 18
	NOTE A_, 3
	INSTR 2
	NOTE E_, 3
	NEXT
Pat_6C30:
	DRUMS $09, DrumPat_6D23
	REPEAT 2
	PAT_CALL Pat_6BE4
	REPEAT_END
	REPEAT 2
	PAT_CALL Pat_6BCD
	REPEAT_END
	NEXT
Pat_6C3F:
	DRUMS $09, DrumPat_6D23
	LEN 18
	REPEAT 4
	PAT_CALL Pat_6BCD
	REPEAT_END
	NEXT
Pat_6C4A:
	DRUMS $09, DrumPat_6D11
	HWENV $77, $00
	DUTY_75
	REPEAT 4
	LENGTH $36
	NOTE G_, 2
	LENGTH $5A
	NOTE Gsh, 2
	REPEAT_END
	NEXT
Pat_6C5B:
	LEN 9
	NOTE F_, 2
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE C_, 4
	LEN 18
	NOTE F_, 4
	LEN 27
	NOTE Gsh, 4
	LEN 18
	NOTE G_, 4
	NOTE F_, 4
	LEN 27
	NOTE C_, 4
	LEN 9
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE C_, 4
	LEN 18
	NOTE F_, 4
	LEN 27
	NOTE Gsh, 4
	LEN 18
	NOTE G_, 4
	NOTE F_, 4
	NOTE C_, 4
	LEN 9
	NOTE Csh, 4
	LENGTH $51
	NOTE D_, 4
	LEN 18
	NOTE C_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	LENGTH $36
	NOTE D_, 4
	NOTE Ash, 3
	LEN 36
	NOTE G_, 3
	NEXT
Pat_6C87:
	LEN 9
	WAIT
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE C_, 4
	LEN 18
	NOTE F_, 4
	LEN 27
	NOTE Gsh, 4
	LEN 18
	NOTE G_, 4
	NOTE F_, 4
	LEN 27
	NOTE C_, 4
	LEN 9
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE C_, 4
	LEN 18
	NOTE F_, 4
	NOTE Gsh, 4
	LEN 9
	NOTE G_, 4
	LEN 18
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LENGTH $36
	NOTE G_, 4
	NOTE F_, 4
	LEN 18
	NOTE C_, 4
	NOTE D_, 4
	LENGTH $3F
	NOTE G_, 3
	LENGTH $51
	REST
	NEXT
Pat_6CB2:
	HWENV $5A, $12, $B7
	AUTODUTY $09
	RELEASE $00
	REPEAT 4
	ARP 5
	LENGTH $36
	NOTE G_, 3
	ARP 4
	LENGTH $5A
	NOTE Gsh, 3
	REPEAT_END
	AUTODUTY $00
	NEXT
Pat_6CC7:
	VIBRATO $12, $01, $05
	HWENV $49, $04, $70
	DUTY_50
	ARP_OFF
	RELEASE $04, $47
	LENGTH $5A
	NOTE G_, 4
	LEN 18
	NOTE F_, 4
	NOTE C_, 5
	NOTE Ash, 4
	LEN 36
	NOTE G_, 4
	LEN 18
	NOTE D_, 4
	NOTE G_, 3
	LEN 27
	NOTE F_, 4
	NOTE E_, 4
	LEN 18
	NOTE Dsh, 4
	LENGTH $6C
	NOTE D_, 4
	LEN 18
	NOTE C_, 4
	NOTE Dsh, 4
	LENGTH $36
	NOTE D_, 4
	NOTE Dsh, 4
	LEN 36
	NOTE Gsh, 2
	NEXT
Pat_6CF2:
	LENGTH $5A
	NOTE G_, 4
	LEN 18
	NOTE F_, 4
	NOTE C_, 5
	NOTE Ash, 4
	LEN 36
	NOTE G_, 4
	LEN 18
	NOTE D_, 4
	NOTE G_, 3
	LEN 27
	NOTE F_, 4
	NOTE E_, 4
	LEN 18
	NOTE Dsh, 4
	LENGTH $5A
	NOTE D_, 4
	LEN 18
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE Ash, 3
	LENGTH $6C
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	NOTE Fsh, 2
	NEXT
DrumPat_6D11:
	db DRUM_LEVEL + 14, 1, 0, 6, 0, 6, 0, 1
	db 0, 6, 0, 6, 0, 6, 0, 6
	db 0, DRUM_LOOP
DrumPat_6D23:
	db DRUM_LEVEL + 14, 1, 0, 6, 6, 9, 0, 1
	db 0, 6, 6, 6, 6, 9, 0, 4
	db 0, DRUM_LOOP
DrumPat_6D35:
	db DRUM_LEVEL + 14, 1, 0, 1, 9, 0, 9, 0
	db DRUM_LOOP

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
	dw Pat_6E7D
	dw Pat_6DAD
	dw Pat_6E91
	dw Pat_6DBA
	dw Pat_6E23
	dw Pat_6E38
	dw Pat_6E9E
	dw Pat_6DCF
	dw Pat_6DE4
	dw Pat_6DBA
	dw Pat_6E23
	dw Pat_6E38
	dw Pat_6E9E
	ORDER_LOOP Song1_Ch1
Song1_Ch3:
	dw Pat_6FEA
	dw Pat_6EE6
	dw Pat_7006
	dw Pat_6EF8
	dw Pat_6EF8
	dw Pat_6FB6
	dw Pat_7038
	dw Pat_6F16
	dw Pat_6F66
	dw Pat_6EF8
	dw Pat_6EF8
	dw Pat_6FB6
	dw Pat_7038
	ORDER_LOOP Song1_Ch3
Song1_Ch2:
	dw Pat_71BD
	dw Pat_706C
	dw Pat_706C
	dw Pat_70A5
	dw Pat_70D4
	dw Pat_7102
	dw Pat_712A
	dw Pat_7158
	dw Pat_718E
	dw Pat_70A5
	dw Pat_70D4
	dw Pat_7102
	dw Pat_712A
	ORDER_LOOP Song1_Ch2
Pat_6DAD:
	INSTR 11
	REPEAT 4
	LEN 18
	NOTE F_, 2
	LEN 36
	NOTE F_, 2
	LEN 18
	NOTE F_, 2
	LEN 36
	NOTE F_, 2
	NOTE F_, 2
	REPEAT_END
	NEXT
Pat_6DBA:
	LEN 18
	REPEAT 4
	INSTR 11
	NOTE F_, 2
	NOTE F_, 2
	INSTR 12
	NOTE F_, 3
	INSTR 11
	NOTE F_, 2
	LEN 27
	NOTE F_, 2
	INSTR 12
	LEN 9
	NOTE F_, 3
	INSTR 11
	LEN 18
	NOTE F_, 2
	INSTR 12
	NOTE F_, 3
	REPEAT_END
	NEXT
Pat_6DCF:
	LEN 18
	REPEAT 4
	INSTR 11
	NOTE Dsh, 2
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 4
	INSTR 11
	NOTE Dsh, 2
	LEN 27
	NOTE Dsh, 2
	INSTR 12
	LEN 9
	NOTE Dsh, 4
	INSTR 11
	LEN 18
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 4
	REPEAT_END
	NEXT
Pat_6DE4:
	INSTR 11
	LEN 18
	NOTE F_, 2
	INSTR 11
	NOTE F_, 2
	INSTR 12
	NOTE F_, 4
	INSTR 11
	NOTE F_, 2
	INSTR 11
	LEN 27
	NOTE F_, 2
	INSTR 12
	LEN 9
	NOTE F_, 4
	INSTR 11
	LEN 18
	NOTE F_, 2
	INSTR 12
	NOTE F_, 4
	INSTR 11
	NOTE F_, 2
	INSTR 11
	NOTE F_, 2
	INSTR 12
	NOTE F_, 4
	INSTR 11
	NOTE F_, 2
	INSTR 11
	LEN 27
	NOTE F_, 2
	INSTR 12
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE Gsh, 2
	INSTR 11
	NOTE Dsh, 2
	NOTE F_, 2
	INSTR 11
	NOTE F_, 2
	INSTR 12
	NOTE F_, 4
	INSTR 11
	NOTE F_, 2
	INSTR 11
	LEN 27
	NOTE F_, 2
	INSTR 12
	LEN 9
	NOTE F_, 4
	INSTR 11
	LEN 18
	NOTE F_, 2
	INSTR 11
	NOTE F_, 2
	NOTE Gsh, 2
	NOTE G_, 2
	NOTE Fsh, 2
	LENGTH $5A
	NOTE F_, 2
	NEXT
Pat_6E23:
	LEN 18
	REPEAT 4
	INSTR 11
	NOTE F_, 2
	NOTE F_, 2
	INSTR 12
	NOTE F_, 3
	INSTR 11
	NOTE F_, 2
	LEN 27
	NOTE F_, 2
	INSTR 12
	LEN 9
	NOTE F_, 3
	INSTR 11
	LEN 18
	NOTE F_, 2
	INSTR 12
	NOTE F_, 3
	REPEAT_END
	NEXT
Pat_6E38:
	INSTR 11
	LEN 18
	NOTE Dsh, 2
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 3
	INSTR 11
	NOTE Dsh, 2
	LEN 27
	NOTE Dsh, 2
	INSTR 12
	LEN 9
	NOTE Dsh, 3
	INSTR 11
	LEN 18
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 3
	INSTR 11
	NOTE Dsh, 2
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 3
	INSTR 11
	NOTE Dsh, 2
	LEN 27
	NOTE Dsh, 2
	INSTR 12
	LEN 9
	NOTE Dsh, 3
	INSTR 11
	LEN 18
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 3
	INSTR 11
	NOTE F_, 2
	NOTE F_, 2
	INSTR 12
	NOTE F_, 3
	INSTR 11
	NOTE F_, 2
	LEN 27
	NOTE F_, 2
	INSTR 12
	LEN 9
	NOTE F_, 3
	INSTR 11
	LEN 18
	NOTE F_, 2
	INSTR 12
	NOTE F_, 3
	INSTR 11
	NOTE F_, 2
	NOTE F_, 2
	INSTR 12
	NOTE F_, 3
	INSTR 11
	NOTE F_, 2
	LEN 27
	NOTE F_, 2
	INSTR 12
	LEN 9
	NOTE F_, 3
	INSTR 11
	LEN 18
	NOTE Gsh, 2
	NOTE Ash, 2
	NEXT
Pat_6E7D:
	INSTR 11
	LEN 18
	NOTE F_, 2
	LEN 36
	NOTE F_, 2
	LEN 18
	NOTE F_, 2
	LEN 36
	NOTE F_, 2
	NOTE F_, 2
	LEN 18
	NOTE F_, 2
	LEN 36
	NOTE F_, 2
	LEN 18
	NOTE F_, 2
	LEN 36
	NOTE F_, 2
	NOTE F_, 2
	NEXT
Pat_6E91:
	INSTR 11
	REPEAT 4
	LEN 18
	NOTE F_, 2
	LEN 36
	NOTE F_, 2
	LEN 18
	NOTE F_, 2
	LEN 36
	NOTE F_, 2
	NOTE F_, 2
	REPEAT_END
	NEXT
Pat_6E9E:
	INSTR 11
	LEN 18
	NOTE Dsh, 2
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 3
	INSTR 11
	NOTE Dsh, 2
	LEN 27
	NOTE Dsh, 2
	INSTR 12
	LEN 9
	NOTE Dsh, 3
	INSTR 11
	LEN 18
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 3
	INSTR 11
	NOTE Dsh, 2
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 3
	INSTR 11
	NOTE Dsh, 2
	LEN 27
	NOTE Dsh, 2
	INSTR 12
	LEN 9
	NOTE Dsh, 3
	INSTR 11
	LEN 18
	NOTE Dsh, 2
	INSTR 12
	NOTE Dsh, 3
	INSTR 11
	NOTE F_, 2
	NOTE F_, 2
	INSTR 12
	NOTE F_, 3
	INSTR 11
	NOTE F_, 2
	LEN 27
	NOTE F_, 2
	INSTR 12
	LEN 9
	NOTE F_, 3
	INSTR 11
	LEN 18
	NOTE F_, 2
	INSTR 12
	NOTE F_, 3
	INSTR 11
	NOTE F_, 2
	NOTE F_, 2
	INSTR 12
	NOTE F_, 3
	INSTR 11
	NOTE F_, 2
	NOTE F_, 2
	INSTR 12
	LEN 9
	NOTE C_, 4
	NOTE F_, 4
	INSTR 11
	LEN 18
	NOTE F_, 2
	INSTR 12
	LEN 9
	NOTE F_, 3
	NOTE F_, 4
	NEXT
Pat_6EE6:
	CH_TRANSPOSE $0C
	LEN 18
	REPEAT 4
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	REPEAT_END
	NEXT
Pat_6EF8:
	LEN 18
	REPEAT 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	REPEAT_END
	INSTR 2
	NOTE E_, 3
	NOTE E_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 2
	NOTE E_, 3
	NOTE E_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE F_, 2
	NEXT
Pat_6F16:
	LEN 18
	INSTR 2
	NOTE E_, 3
	INSTR 0
	LEN 9
	NOTE Dsh, 3
	NOTE Ash, 3
	LEN 18
	NOTE Dsh, 2
	LEN 9
	NOTE Dsh, 3
	NOTE Ash, 3
	INSTR 2
	LEN 18
	NOTE E_, 3
	INSTR 0
	NOTE Dsh, 2
	LEN 9
	NOTE Dsh, 3
	NOTE Ash, 3
	LEN 18
	NOTE Dsh, 2
	INSTR 2
	NOTE E_, 3
	INSTR 0
	LEN 9
	NOTE Dsh, 3
	NOTE Ash, 3
	LEN 18
	NOTE Dsh, 2
	LEN 9
	NOTE Dsh, 3
	NOTE Ash, 3
	INSTR 2
	LEN 18
	NOTE E_, 3
	INSTR 0
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	INSTR 2
	NOTE E_, 3
	INSTR 0
	LEN 9
	NOTE Dsh, 3
	NOTE Ash, 3
	LEN 18
	NOTE Dsh, 2
	LEN 9
	NOTE Dsh, 3
	NOTE Ash, 3
	INSTR 2
	LEN 18
	NOTE E_, 3
	INSTR 0
	NOTE Dsh, 2
	LEN 9
	NOTE Dsh, 3
	NOTE Ash, 3
	LEN 18
	NOTE Dsh, 2
	INSTR 2
	NOTE E_, 3
	INSTR 0
	LEN 9
	NOTE Dsh, 3
	NOTE Ash, 3
	LEN 18
	NOTE Dsh, 2
	LEN 9
	NOTE Dsh, 3
	NOTE Ash, 3
	INSTR 2
	LEN 18
	NOTE E_, 3
	INSTR 0
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NEXT
Pat_6F66:
	INSTR 2
	LEN 18
	NOTE E_, 3
	INSTR 0
	LEN 9
	NOTE F_, 3
	NOTE C_, 4
	LEN 18
	NOTE F_, 2
	LEN 9
	NOTE F_, 3
	NOTE C_, 4
	INSTR 2
	LEN 18
	NOTE E_, 3
	INSTR 0
	NOTE F_, 2
	LEN 9
	NOTE F_, 3
	NOTE C_, 4
	LEN 18
	NOTE F_, 2
	INSTR 2
	NOTE E_, 3
	INSTR 0
	LEN 9
	NOTE F_, 3
	NOTE C_, 4
	LEN 18
	NOTE F_, 2
	LEN 9
	NOTE F_, 3
	NOTE C_, 4
	INSTR 2
	LEN 18
	NOTE E_, 3
	INSTR 0
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	INSTR 2
	NOTE E_, 3
	INSTR 0
	LEN 9
	NOTE F_, 3
	NOTE C_, 4
	LEN 18
	NOTE F_, 2
	LEN 9
	NOTE F_, 3
	NOTE C_, 4
	INSTR 2
	LEN 18
	NOTE E_, 3
	INSTR 0
	NOTE F_, 2
	LEN 9
	NOTE F_, 3
	NOTE C_, 4
	LEN 18
	NOTE F_, 2
	INSTR 2
	NOTE E_, 3
	LEN 9
	NOTE E_, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	LEN 18
	NOTE E_, 3
	LEN 9
	NOTE E_, 3
	INSTR 0
	NOTE C_, 4
	LEN 18
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NEXT
Pat_6FB6:
	LEN 18
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	INSTR 2
	NOTE E_, 3
	NOTE E_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 2
	NOTE E_, 3
	NOTE E_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE F_, 2
	NEXT
Pat_6FEA:
	CH_TRANSPOSE $0C
	INSTR 2
	LEN 18
	NOTE E_, 3
	INSTR 0
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NEXT
Pat_7006:
	LEN 18
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NEXT
Pat_7038:
	INSTR 2
	LEN 18
	NOTE E_, 3
	INSTR 0
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	INSTR 2
	NOTE E_, 3
	NOTE E_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 2
	NOTE E_, 3
	NOTE E_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 2
	NOTE E_, 3
	INSTR 0
	NOTE F_, 2
	NEXT
Pat_706C:
	CH_TRANSPOSE $0C
	HWENV $E1, $07, $67
	DUTY_50
	ARP 19
	LEN 9
	NOTE F_, 2
	NOTE G_, 2
	NOTE Gsh, 2
	NOTE B_, 2
	LEN 18
	NOTE C_, 3
	LEN 9
	NOTE F_, 2
	NOTE G_, 2
	NOTE Gsh, 2
	NOTE Ash, 2
	LENGTH $36
	NOTE B_, 2
	LEN 18
	NOTE Gsh, 2
	LENGTH $7E
	NOTE F_, 2
	LEN 9
	NOTE F_, 2
	NOTE G_, 2
	NOTE Gsh, 2
	NOTE B_, 2
	LEN 18
	NOTE C_, 3
	LEN 9
	NOTE F_, 2
	NOTE G_, 2
	NOTE Gsh, 2
	NOTE Ash, 2
	LEN 36
	NOTE B_, 2
	LEN 18
	DUTY_75
	ARP 0
	NOTE Dsh, 2
	NOTE Gsh, 2
	LEN 36
	NOTE F_, 2
	NOTE F_, 2
	LEN 18
	DUTY_50
	ARP 19
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NEXT
Pat_70A5:
	DRUMS $09, DrumPat_71DA
	ARP_OFF
	DUTY_50
	HWENV $4A, $07, $70
	RELEASE $02, $57
	LENGTH $6C
	NOTE Dsh, 4
	LEN 18
	WAIT2
	LEN 9
	NOTE D_, 4
	NOTE Dsh, 4
	LENGTH $48
	NOTE E_, 4
	LEN 18
	WAIT2
	NOTE E_, 4
	NOTE Csh, 4
	NOTE C_, 4
	LENGTH $7E
	NOTE C_, 4
	LEN 18
	WAIT2
	ARP 5
	HWENV $C5, $00
	NOTE F_, 2
	LEN 36
	NOTE F_, 2
	LEN 18
	NOTE F_, 2
	LEN 36
	NOTE F_, 2
	NOTE F_, 2
	NEXT
Pat_70D4:
	DUTY_50
	HWENV $4A, $07, $70
	ARP_OFF
	LENGTH $6C
	NOTE Dsh, 4
	LEN 18
	WAIT2
	LEN 9
	NOTE D_, 4
	NOTE Dsh, 4
	LENGTH $5A
	NOTE E_, 4
	LEN 18
	WAIT2
	NOTE Gsh, 4
	NOTE G_, 4
	LENGTH $7E
	NOTE C_, 4
	LEN 18
	WAIT2
	ARP 5
	HWENV $C5, $00
	NOTE F_, 2
	LEN 36
	NOTE F_, 2
	LEN 18
	NOTE F_, 2
	NOTE F_, 2
	DUTY_50
	HWENV $4A, $07, $70
	ARP_OFF
	NOTE C_, 4
	NOTE Ash, 3
	NOTE Gsh, 3
	NEXT
Pat_7102:
	LENGTH $6C
	NOTE Ash, 3
	LEN 18
	WAIT2
	LEN 9
	NOTE G_, 3
	NOTE Gsh, 3
	LENGTH $36
	NOTE Ash, 3
	LEN 18
	WAIT2
	LEN 36
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE C_, 4
	LEN 18
	NOTE Gsh, 3
	LENGTH $48
	NOTE F_, 3
	LEN 18
	WAIT2
	ARP 5
	HWENV $C5, $00
	NOTE F_, 2
	LEN 36
	NOTE F_, 2
	LEN 18
	NOTE F_, 2
	LEN 36
	NOTE F_, 2
	LEN 9
	LEN 18
	NOTE F_, 2
	NOTE F_, 2
	NEXT
Pat_712A:
	DUTY_50
	HWENV $4A, $07, $70
	ARP_OFF
	LENGTH $6C
	NOTE Ash, 3
	LEN 18
	WAIT2
	LEN 9
	NOTE G_, 3
	NOTE Gsh, 3
	LENGTH $36
	NOTE Ash, 3
	LEN 18
	WAIT2
	LEN 36
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE C_, 4
	LEN 18
	NOTE F_, 3
	LENGTH $48
	NOTE F_, 4
	LEN 18
	WAIT2
	ARP 5
	HWENV $C5, $00
	NOTE F_, 2
	LEN 36
	NOTE F_, 2
	LEN 18
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	LEN 9
	NOTE F_, 2
	NOTE F_, 2
	NEXT
Pat_7158:
	HWENV $E2, $07, $80
	DUTY_75
	ARP 19
	RELEASE $07, $63
	LEN 9
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	LEN 18
	NOTE Ash, 3
	LEN 9
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE Fsh, 3
	NOTE Gsh, 3
	LENGTH $36
	NOTE A_, 3
	LEN 18
	NOTE Fsh, 3
	NOTE Dsh, 3
	NOTE Csh, 3
	LENGTH $5A
	NOTE Dsh, 3
	LEN 9
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	LEN 18
	NOTE Ash, 3
	LEN 9
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE Fsh, 3
	NOTE Gsh, 3
	LEN 36
	NOTE A_, 3
	LEN 18
	NOTE Ash, 3
	NOTE Csh, 4
	NOTE C_, 4
	NOTE B_, 3
	LENGTH $5A
	NOTE Ash, 3
	NEXT
Pat_718E:
	LEN 9
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE B_, 3
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	LENGTH $36
	NOTE B_, 3
	LEN 18
	NOTE Gsh, 3
	NOTE F_, 3
	NOTE Dsh, 3
	LENGTH $5A
	NOTE F_, 3
	LEN 9
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE B_, 3
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	LEN 36
	NOTE B_, 3
	LEN 18
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Csh, 4
	LENGTH $5A
	NOTE C_, 4
	CH_TRANSPOSE $0C
	NEXT
Pat_71BD:
	DRUMS $09, DrumPat_71D0
	VIBRATO $12, $02, $04
	HWENV $F7, $00
	DUTY_12
	LENGTH $48
	NOTE F_, 2
	WAIT
	WAIT
	WAIT
	NEXT
DrumPat_71D0:
	db DRUM_LEVEL + 13, 1, 0, 6, 0, 4, 0, 6
	db 0, DRUM_LOOP
DrumPat_71DA:
	db DRUM_LEVEL + 13, 1, 6, 6, 6, 4, 0, 6
	db 6, 1, 6, 4, 0, 6, 6, 6
	db 6, 1, 6, 6, 6, 4, 0, 6
	db 6, 1, 6, 4, 0, 6, 6, 6
	db 6, 1, 6, 6, 6, 4, 0, 6
	db 6, 1, 6, 4, 0, 6, 6, 6
	db 6, 1, 6, 1, 6, 4, 0, 1
	db 6, 1, 6, 4, 0, 1, 6, 6
	db 6, DRUM_LOOP

; Instrument table 1, entries 1..19 (the song routines point 2 bytes before:
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
Instr1_0:
	VOLENV 11, $11, $1A, $11
	WAVE Wave_7BB6
	END
Instr1_1:
	VOLENV 15, $10, $1F, $11
	GLIDE $FF
	WAVE Wave_7BC6
	END
Instr1_2:
	VOLENV 15, $11, $1F, $11
	GLIDE $01
	ARP 15
	WAVE Wave_7CF6
	END
Instr1_3:
	VOLENV 15, $11, $1F, $13
	GLIDE $FE
	ARP 0
	WAVE Wave_7CF6
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
	HWENV $91, $03, $21
	DUTY_12
	GLIDE $FF
	END
Instr1_7:
	HWENV $4D, $1C, $D6
	ARP 5
	DUTY_75
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
	HWENV $C2, $04, $73
	ARP 0
	DUTY_12
	END
Instr1_11:
	HWENV $F1, $07, $75
	ARP 0
	DUTY_50
	END
Instr1_12:
	HWENV $D1, $04, $53
	ARP 6
	DUTY_75
	END
Instr1_13:
	HWENV $D1, $07, $77
	ARP_OFF
	END
Instr1_14:
	VOLENV 12, $11, $1F, $12
	ARP 4
	WAVE Wave_7CA6
	END
Instr1_15:
	VOLENV 12, $11, $1F, $12
	ARP 5
	WAVE Wave_7CA6
	END
Instr1_16:
	VOLENV 15, $10, $2F, $11
	ARP 12
	WAVE Wave_7BC6
	GLIDE $01
	END
Instr1_17:
	VOLENV 13, $10, $1F, $11
	WAVE Wave_7BC6
	GLIDE $FF
	END
Instr1_18:
	VOLENV 12, $11, $1F, $11
	WAVE Wave_7D16
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

; Unreferenced (16 bytes)
	db $C8, $73, $C8, $73, $C8, $73, $C8, $73, $CC, $73, $CC, $73, $CC, $73, $CC, $73
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

; Unreferenced (4 bytes)
	db $18, $0C
SfxTable_m2:
	db $00, $FF

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
	dw Sfx32
	dw Sfx33
	dw Sfx34
	dw Sfx35
	dw Sfx36
	dw Sfx37
	dw Sfx38
	dw Sfx39

; Sound effect 1
Sfx01:
	VOLENV 11, $11, $1F, $11
	WAVE Wave_7C66
	GLIDE $02
	LEN 12
	NOTE A_, 2
	END

; Sound effect 4
Sfx04:
	VOLENV 12, $11, $1F, $13
	VIBRATO $00, $01, $04
	WAVE Wave_7C96
	CALL_CODE Code_788F
	GLIDE $FC
	LEN 5
	NOTE A_, 4
	CALL_CODE Code_788F
	GLIDE $08
	WAIT
	CALL_CODE Code_7868
	GLIDE_OFF
	LEN 10
	WAIT
	GLIDE $FF
	WAIT
	END

; Sound effect 3
Sfx03:
	WAVE Wave_7C96
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
	WAVE Wave_7D06
	CALL_CODE Code_79C7
	LEN 5
	NOTE C_, 4
	CALL_CODE Code_7B31
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
	WAVE Wave_7CD6
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
	CALL_CODE Code_788F
	VOLENV 15, $00, $00, $00
	ARP 3
	WAVE Wave_7D76
	LEN 3
	REST
	CALL_CODE Code_791E
	LEN 5
	GLIDE $FE
	NOTE E_, 3
	END

; Sound effect 10
Sfx10:
	CALL_CODE Code_7A33
	VOLENV 11, $11, $1F, $12
	VIBRATO $01, $06, $03
	LEN 30
	WAVE Wave_7C66
	NOTE C_, 5
	END

; Sound effect 11
Sfx11:
	CALL_CODE Code_78B6
	VOLENV 11, $11, $1F, $14
	WAVE Wave_7CB6
	LEN 5
	GLIDE $FB
	NOTE C_, 5
	END

; Sound effect 12
Sfx12:
	CALL_CODE Code_788F
	WAVE Wave_7CB6
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
	CALL_CODE Code_7868
	VOLENV 11, $11, $1F, $13
	WAVE Wave_7C96
	LEN 23
	SLIDE_DOWN $03
	NOTE A_, 4
	END

; Sound effect 14
Sfx14:
	CALL_CODE Code_77CE
	WAVE Wave_7C66
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
	WAVE Wave_7D26
	LEN 40
	NOTE A_, 4
	END

; Sound effect 15
Sfx15:
	VOLENV 15, $11, $5F, $11
	CH_TRANSPOSE $F4
	ARP 2
	WAVE Wave_7D26
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
	WAVE Wave_7D26
	NOTE A_, 2
	VOLENV 10, $00, $00, $00
	NOTE A_, 2
	VOLENV 5, $00, $00, $00
	NOTE A_, 2
	END

; Sound effect 28
Sfx28:
	CALL_CODE Code_79FD
	VOLENV 15, $11, $1F, $11
	WAVE Wave_7C66
	LEN 6
	GLIDE $FD
	NOTE D_, 4
	END

; Sound effect 17
Sfx17:
	VOLENV 15, $00, $00, $00
	GLIDE $05
	LEN 10
	WAVE Wave_7D26
	NOTE A_, 2
	VOLENV 10, $00, $00, $00
	NOTE A_, 2
	VOLENV 5, $00, $00, $00
	NOTE A_, 2
	END

; Sound effect 20
Sfx20:
	WAVE Wave_7DC6
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
	WAVE Wave_7C66
	CALL_CODE Code_7714
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
	WAVE Wave_7D66
	NOTE A_, 4
	WAVE Wave_7C26
	NOTE A_, 4
	WAVE Wave_7D56
	NOTE A_, 4
	WAVE Wave_7C36
	NOTE A_, 4
	WAVE Wave_7D76
	NOTE A_, 4
	END

; Sound effect 23
Sfx23:
	WAVE Wave_7C66
	VOLENV 15, $11, $1F, $11
	CALL_CODE Code_7746
	LEN 5
	GLIDE $FE
	NOTE C_, 3
	GLIDE_OFF
	WAVE Wave_7C26
	VOLENV 5, $1F, $00, $20
	CALL_CODE Code_7774
	LEN 21
	NOTE E_, 3
	END

; Sound effect 24
Sfx24:
	CALL_CODE Code_7B74
	VOLENV 15, $11, $1F, $13
	WAVE Wave_7C66
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
	CALL_CODE Code_7AF9
	VOLENV 15, $11, $1F, $11
	GLIDE $FF
	WAVE Wave_7C66
	LEN 10
	NOTE G_, 2
	CALL_CODE Code_7AF9
	NOTE G_, 2
	END

; Sound effect 29
Sfx29:
	CALL_CODE Code_7A61
	END

; Sound effect 18
Sfx18:
	WAVE Wave_7D06
	CALL_CODE Code_798E
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
	WAVE Wave_7D86
	ARP 8
	LEN 20
	NOTE A_, 5
	WAIT
	END

; Sound effect 26
Sfx26:
	CALL_CODE Code_791E
	VOLENV 15, $00, $00, $00
	WAVE Wave_7BD6
	LEN 3
	GLIDE $FF
	NOTE A_, 5
	WAVE Wave_7DA6
	WAIT
	GLIDE $FE
	WAVE Wave_7DD6
	WAIT
	LEN 10
	WAVE Wave_7DA6
	VOLENV 10, $00, $00, $00
	NOTE E_, 5
	VOLENV 5, $00, $00, $00
	NOTE E_, 5
	END

; Sound effect 39
Sfx39:
	CALL_CODE Code_7B31
	END

; Sound effect 38
Sfx38:
	CALL_CODE Code_791E
	END

; Sound effect 2
Sfx02:
	CALL_CODE Code_7AC5
	END

; Sound effect 5
Sfx05:
	VOLENV 15, $11, $2F, $11
	WAVE Wave_7CD6
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
	WAVE Wave_7CD6
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
	CALL_CODE Code_79C7
	WAVE Wave_7C66
	LEN 12
	GLIDE $FE
	NOTE C_, 3
	END

; Sound effect 31
Sfx31:
	LEN 5
	ARP 6
	WAVE Wave_7D16
	VOLENV 15, $10, $1F, $12
	NOTE C_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	END

; Sound effect 32
Sfx32:
	CALL_CODE Code_7950
	END

; Sound effect 33
Sfx33:
	VOLENV 15, $11, $1F, $14
	WAVE Wave_7C86
	VIBRATO $01, $01, $08
	LEN 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE Gsh, 4
	END

; Sound effect 34
Sfx34:
	VOLENV 12, $11, $1F, $14
	WAVE Wave_7C66
	GLIDE $04
	LEN 4
	NOTE G_, 3
	GLIDE $FD
	LEN 6
	WAIT
	REST
	END

; Sound effect 35
Sfx35:
	VOLENV 10, $11, $10, $00
	WAVE Wave_7D66
	GLIDE $02
	LEN 5
	NOTE A_, 2
	GLIDE_OFF
	LEN 3
	WAIT
	GLIDE $02
	WAIT
	END

; Sound effect 36
Sfx36:
	CALL_CODE Code_7800
	END

; Sound effect 37
Sfx37:
	VOLENV 15, $00, $00, $00
	WAVE Wave_7D66
	LEN 5
	NOTE A_, 3
	LEN 3
	REST
	LEN 20
	NOTE A_, 3
	END
Code_7714:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $28
	ld [wDrumHold], a
	ld a, HIGH(Noise43_773B)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_773B)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7741)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7741)
	ld [wNoise42], a
	ret
Noise43_773B:
	db $57, $56, $54, $53, $47, $FF
Noise42_7741:
	db $F0, $F0, $60, $70, $F3
Code_7746:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $88
	ld [wNoisePan], a
	ld a, $0A
	ld [wDrumHold], a
	ld a, HIGH(Noise43_776D)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_776D)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7771)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7771)
	ld [wNoise42], a
	ret
Noise43_776D:
	db $4A, $5A, $50, $FF
Noise42_7771:
	db $F0, $D0, $B1
Code_7774:
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
	ld a, HIGH(Noise43_77A3)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_77A3)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_77A3:
	db $18, $3A, $47, $49, $2E, $2D, $1C, $28
	db $4A, $57, $39, $4E, $1D, $0C, $FF
Noise43_77B2:
	db $82, $64, $02, $37, $47, $24, $55, $71
	db $07, $44, $60, $36, $84, $82, $64, $02
	db $37, $47, $24, $55, $71, $07, $44, $60
	db $36, $86, $32, $FF
Code_77CE:
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
	ld a, HIGH(Noise43_77B2)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_77B2)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Code_7800:
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
	ld a, HIGH(Noise43_77B2)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_77B2)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Unused_Noise_7832:
	ld a, $88
	ld [wNoisePan], a
	ld a, $08
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7859)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7859)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7861)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7861)
	ld [wNoise42], a
	ret
Noise43_7859:
	db $60, $52, $42, $41, $22, $11, $21, $FF
Noise42_7861:
	db $F0, $F0, $F0, $F0, $F0, $F0, $61
Code_7868:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_78F7)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_78F7)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7911)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7911)
	ld [wNoise42], a
	ret
Code_788F:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7904)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7904)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7911)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7911)
	ld [wNoise42], a
	ret
Code_78B6:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_78EA)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_78EA)
	ld [wNoise43], a
	ld a, HIGH(Noise42_78DD)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_78DD)
	ld [wNoise42], a
	ret
Noise42_78DD:
	db $F1, $A1, $FF, $FF, $FF, $FF, $43, $FF
	db $FF, $FF, $FF, $FF

; Unreferenced (1 bytes)
	db $FF
Noise43_78EA:
	db $51, $10, $20, $31, $32, $33, $53, $34
	db $14, $15, $15, $16, $FF
Noise43_78F7:
	db $10, $10, $20, $31, $32, $33, $33, $34
	db $34, $35, $35, $36, $FF
Noise43_7904:
	db $36, $35, $35, $34, $34, $33, $33, $32
	db $31, $20, $10, $10, $FF
Noise42_7911:
	db $5F, $FF, $FF, $FF, $FF, $FF, $A1, $FF
	db $FF, $FF, $FF, $FF

; Unreferenced (1 bytes)
	db $FF
Code_791E:
	ld a, $88
	ld [wNoisePan], a
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7945)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7945)
	ld [wNoise43], a
	ld a, HIGH(Noise42_794B)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_794B)
	ld [wNoise42], a
	ret
Noise43_7945:
	db $00, $53, $71, $91, $31, $FF
Noise42_794B:
	db $F2, $FF, $FF, $FF, $00
Code_7950:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0A
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7977)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7977)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7983)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7983)
	ld [wNoise42], a
	ret
Noise43_7977:
	db $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0
	db $A0, $A0, $A0, $FF
Noise42_7983:
	db $F0, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $00
Code_798E:
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
	ld a, HIGH(Noise43_79BD)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_79BD)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_79BD:
	db $02, $92, $42, $42, $42, $42, $52, $65
	db $45, $FF
Code_79C7:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_79EE)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_79EE)
	ld [wNoise43], a
	ld a, HIGH(Noise42_79F6)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_79F6)
	ld [wNoise42], a
	ret
Noise43_79EE:
	db $02, $51, $61, $71, $91, $71, $60, $FF
Noise42_79F6:
	db $F0, $F0, $F0, $F0, $F0, $70, $63
Code_79FD:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7A24)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7A24)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7A2C)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7A2C)
	ld [wNoise42], a
	ret
Noise43_7A24:
	db $22, $51, $64, $81, $51, $41, $60, $FF
Noise42_7A2C:
	db $F0, $F0, $F0, $F0, $F0, $70, $63
Code_7A33:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7A5A)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7A5A)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7A5E)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7A5E)
	ld [wNoise42], a
	ret
Noise43_7A5A:
	db $02, $51, $22, $FF
Noise42_7A5E:
	db $F0, $A0, $45
Code_7A61:
	ld a, $88
	ld [wNoisePan], a
	ld a, $19
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7A88)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7A88)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7A8E)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7A8E)
	ld [wNoise42], a
	ret
Noise43_7A88:
	db $02, $41, $61, $71, $11, $FF
Noise42_7A8E:
	db $F0, $FF, $FF, $A0, $B2
Unused_Noise_7A93:
	ld a, $88
	ld [wNoisePan], a
	ld a, $08
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7ABA)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7ABA)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7AC0)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7AC0)
	ld [wNoise42], a
	ret
Noise43_7ABA:
	db $00, $83, $60, $60, $31, $FF
Noise42_7AC0:
	db $F0, $FF, $FF, $FF, $D1
Code_7AC5:
	ld a, $88
	ld [wNoisePan], a
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7AEC)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7AEC)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7AF3)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7AF3)
	ld [wNoise42], a
	ret
Noise43_7AEC:
	db $41, $61, $61, $41, $71, $71, $FF
Noise42_7AF3:
	db $A1, $52, $00, $61, $52, $00
Code_7AF9:
	ld a, $88
	ld [wNoisePan], a
	ld a, $0A
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B20)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B20)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B29)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B29)
	ld [wNoise42], a
	ret
Noise43_7B20:
	db $78, $78, $78, $78, $58, $56, $56, $68
	db $FF
Noise42_7B29:
	db $A1, $FF, $11, $00, $81, $FF, $F2, $00
Code_7B31:
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
	ld a, HIGH(Noise43_7B61)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B61)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B6B)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B6B)
	ld [wNoise42], a
	ret
Noise43_7B61:
	db $67, $56, $45, $34, $23, $22, $11, $10
	db $20, $FF
Noise42_7B6B:
	db $19, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $F3
Code_7B74:
	ld a, $88
	ld [wNoisePan], a
	ld a, $19
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B9B)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B9B)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7BA1)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7BA1)
	ld [wNoise42], a
	ret
Noise43_7B9B:
	db $03, $83, $80, $80, $61, $FF
Noise42_7BA1:
	db $F0, $FF, $FF, $FF, $F2

; Unreferenced (16 bytes)
	db $84, $32, $55, $55, $51, $23, $8F, $F8, $40, $04, $8F, $F8, $40, $04, $8F, $F8
Wave_7BB6:
	db $02, $46, $8A, $CE, $FF, $DB, $DF, $FF
	db $EC, $A8, $64, $20, $FF, $FF, $FF, $FF
Wave_7BC6:
	db $7F, $FF, $FF, $FF, $FF, $FF, $FF, $F7
	db $70, $00, $00, $00, $00, $00, $00, $07
Wave_7BD6:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $00, $00, $00, $00

; Unreferenced (64 bytes)
	db $01, $11, $11, $00, $89, $AA, $AA, $98, $01, $11, $11, $00, $FF, $FF, $FF, $FF
	db $A8, $40, $04, $8A, $FF, $FF, $FF, $FF, $A8, $40, $04, $8A, $FF, $FF, $FF, $FF
	db $8C, $FE, $ED, $B8, $53, $21, $10, $24, $84, $01, $12, $35, $8B, $DE, $EF, $8C
	db $00, $46, $8A, $FF, $FF, $A8, $64, $00, $00, $46, $8A, $FF, $FF, $A8, $64, $00
Wave_7C26:
	db $B7, $40, $F4, $7B, $FD, $FF, $FE, $DC
	db $02, $46, $8A, $BD, $FD, $BA, $6F, $20
Wave_7C36:
	db $B7, $4E, $F4, $FF, $DF, $FF, $ED, $C0
	db $24, $68, $AB, $DF, $DD, $DD, $6F, $20

; Unreferenced (32 bytes)
	db $32, $22, $11, $11, $11, $22, $23, $45, $FD, $CB, $A9, $87, $65, $43, $21, $10
	db $DD, $DB, $97, $52, $22, $54, $22, $22, $DD, $DC, $BD, $DD, $DB, $85, $22, $22
Wave_7C66:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF

; Unreferenced (16 bytes)
	db $01, $11, $11, $00, $89, $AA, $AA, $98, $01, $11, $11, $00, $FF, $FF, $FF, $FF
Wave_7C86:
	db $00, $00, $00, $00, $CD, $EF, $FD, $EC
	db $00, $12, $21, $00, $DD, $DD, $DD, $DD
Wave_7C96:
	db $00, $00, $00, $00, $00, $00, $FF, $FF
	db $00, $00, $00, $00, $00, $00, $FF, $FF
Wave_7CA6:
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $A8, $76, $67, $8A
Wave_7CB6:
	db $00, $00, $00, $00, $00, $00, $FF, $00
	db $00, $00, $00, $00, $00, $00, $FF, $00

; Unreferenced (16 bytes)
	db $00, $00, $00, $CD, $EF, $FF, $FF, $FF, $04, $8C, $FF, $FF, $FF, $FF, $FF, $FF
Wave_7CD6:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $00, $FF, $FF, $FF

; Unreferenced (16 bytes)
	db $12, $34, $56, $78, $9A, $BC, $DE, $FF, $ED, $CB, $A9, $87, $65, $43, $21, $00
Wave_7CF6:
	db $FF, $FE, $ED, $B8, $53, $21, $10, $00
	db $00, $01, $12, $35, $8B, $DE, $EF, $FF
Wave_7D06:
	db $63, $10, $00, $00, $00, $00, $01, $36
	db $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9
Wave_7D16:
	db $63, $10, $01, $47, $74, $10, $01, $36
	db $9C, $EF, $FE, $B8, $8B, $EF, $FE, $C9
Wave_7D26:
	db $63, $1F, $01, $47, $74, $10, $01, $36
	db $9C, $E0, $FE, $B8, $8B, $EF, $FE, $C9

; Unreferenced (32 bytes)
	db $65, $43, $22, $27, $72, $22, $22, $29, $AB, $CC, $BA, $98, $9C, $EE, $EE, $C9
	db $63, $20, $02, $47, $74, $22, $22, $36, $9C, $EF, $FE, $B6, $6B, $EE, $EE, $C9
Wave_7D56:
	db $B7, $40, $04, $7B, $CD, $FF, $FE, $DC
	db $02, $46, $8A, $BD, $FD, $BA, $64, $20
Wave_7D66:
	db $0F, $00, $F0, $F0, $F0, $F0, $00, $0F
	db $0F, $FF, $FF, $00, $FF, $F0, $0F, $0F
Wave_7D76:
	db $BB, $2B, $BB, $2B, $BB, $5B, $2B, $BB
	db $2B, $BB, $BB, $72, $27, $EB, $BB, $B0
Wave_7D86:
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $ED, $CB, $A9, $87, $65, $43, $21, $00

; Unreferenced (16 bytes)
	db $FE, $DB, $97, $53, $13, $54, $32, $10, $FE, $DC, $BC, $EF, $DB, $85, $32, $10
Wave_7DA6:
	db $04, $8B, $DE, $FF, $ED, $CB, $A9, $87
	db $65, $44, $44, $32, $11, $24, $7A, $74

; Unreferenced (16 bytes)
	db $20, $13, $69, $BD, $FD, $B9, $64, $20, $13, $68, $B8, $64, $20, $24, $68, $64
Wave_7DC6:
	db $00, $00, $69, $FF, $FF, $F9, $64, $00
	db $03, $68, $B8, $60, $00, $04, $68, $60
Wave_7DD6:
	db $20, $24, $68, $AC, $EC, $A8, $64, $20
	db $24, $68, $A8, $64, $20, $24, $68, $64

; Unreferenced (32 bytes)
	db $02, $48, $AC, $FF, $FC, $53, $00, $27, $9C, $DD, $DC, $B7, $7B, $CD, $DD, $C9
	db $BD, $FF, $AC, $FF, $FC, $52, $00, $27, $9C, $DF, $DC, $B7, $7B, $CD, $AD, $C9
Noise43_7E06:
	db $02, $61, $71, $A1, $B1, $B1, $A1, $FF
Noise42_7E0E:
	db $C1, $F0, $A0, $90, $70, $40, $33
Noise43_7E15:
	db $06, $04, $03, $03, $07, $FF
Noise42_7E1B:
	db $F0, $C0, $80, $60, $57
Noise43_7E20:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_7E28:
	db $60, $40, $33, $FF, $FF, $FF, $FF
Noise43_7E2F:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_7E37:
	db $A0, $60, $32, $FF, $FF, $FF, $FF
Noise43_7E3E:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_7E46:
	db $70, $40, $40, $40, $40, $43, $FF
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7E06)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7E06)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7E0E)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7E0E)
	ld [wNoise42], a
	ret
Drum8:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7E87)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7E87)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7E8D)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7E8D)
	ld [wNoise42], a
	ret
Noise43_7E87:
	db $04, $02, $01, $00, $00, $FF
Noise42_7E8D:
	db $30, $40, $60, $43, $42
Drum2:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7EAF)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7EAF)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7EB7)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7EB7)
	ld [wNoise42], a
	ret
Noise43_7EAF:
	db $60, $52, $42, $41, $22, $11, $04, $FF
Noise42_7EB7:
	db $F0, $F0, $F0, $A0, $70, $40, $51
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7E3E)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7E3E)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7E46)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7E46)
	ld [wNoise42], a
	ret
Drum5:
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
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7E20)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7E20)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7E28)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7E28)
	ld [wNoise42], a
	ret
Drum7:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7E15)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7E15)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7E1B)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7E1B)
	ld [wNoise42], a
	ret
Drum9:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7F4F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7F4F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7F52)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7F52)
	ld [wNoise42], a
	ret
Noise43_7F4F:
	db $51, $41, $FF
Noise42_7F52:
	db $F0, $62
Drum10:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7F71)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7F71)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7F74)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7F74)
	ld [wNoise42], a
	ret
Noise43_7F71:
	db $51, $32, $FF
Noise42_7F74:
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
	db "Final de la rutina de musicaca"

; Unreferenced (74 bytes)
	db $01, $10, $E7, $2E, $01, $10, $F9, $2E, $01, $10, $0A, $2F, $01, $10, $1B, $2F
	db $01, $10, $30, $2F, $01, $10, $45, $2F, $01, $10, $9D, $2E, $01, $10, $00, $09
	db $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09
	db $09, $09, $09, $09, $09, $09, $09, $01, $09, $09, $09, $09, $09, $09, $09, $09
	db $09, $09, $09, $09, $09, $02, $03, $04, $09, $09
