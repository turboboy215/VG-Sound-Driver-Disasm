; =====================================================================
; Spirou (E) (M4) [S] - Game Boy
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o spirou.o Spirou_SoundDriver.asm
;   rgblink -o spirou.gb spirou.o
;   python tools/cmp_banked.py spirou.gb "Spirou (E) (M4) [S][!].gb" 15:4000-7FFF
; (driver and data fill ROM bank 15; the linked file only matches in that range)
;
; Documentation: Spirou_SoundDriver.md / AJG_SoundEngine_Family.md
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
MACRO REPEAT    ; play the following bytes n times (up to REPEAT_END), n = 2-19
	db $EC + \1
ENDM
MACRO LEN       ; note length in ticks, 1-48
	db $BD + \1
ENDM
MACRO VOLENV    ; start volume + envelope (CH3/SFX): atk (lo=count hi=step), dec (lo=count hi=step), rates (hi=atk lo=dec)
	db $AE + \1, \2, \3, \4
ENDM
MACRO INSTR     ; instrument n = entry n + 1 of the current instrument table
	db $85 + \1
ENDM
MACRO ARP       ; arpeggio n of the current arpeggio table
	db $92 + \1
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
DEF DRUM_TEMPO EQU $BD         ; + n: one step every n ticks
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
	ld a, [$C427]
	and a
	jr nz, PauseTrigger
	xor a
	ldh [rNR32], a
PauseTrigger:
	ld a, $80
	ldh [rNR14], a
	ldh [rNR24], a
	ldh [rNR44], a
	ld a, [$C427]
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
	ld h, $C1
	call ChannelTick
	inc h
	call ChannelTick
	inc h
	call ChannelTick
	inc h
	call ChannelTick
	call DrumTick

; Output, pulse pages: NRx3 = period low + pitch offset (fields $25/$26, vibrato and
; slides); NRx4 = high byte (no trigger) when it differs from the shadow ($07). When
; the envelope flag ($33) is set: NRx2 = field $32, NRx4 = high | $80 (retrigger).
; The pulse channels have no software volume in this version.
OutputCh1:
	ld hl, $C125
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
	ldh [rNR14], a
	ld b, a
	ld [hl], a
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
	ldh [rNR24], a
	ld b, a
	ld [hl], a
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
	add a, $AD
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

; Note on. The direction bit (b4, vibrato/slides) is cleared unless bit 4 of the
; vibrato delay (field $20, in A here) is set: The Smurfs tests the slide bit
; (bit 5, [hl]) at this point. Slides have delay 0, so they always restart
; downwards; a vibrato with a delay of 16-31, 48-63 ... keeps its direction.
NoteOn:
	ld l, $02
	ld [hl], e
	inc l
	ld [hl], d
	ld l, $0C
	ld [hl], a
	ld c, $00
	ld l, $1F
	ld [hl], c
	ld l, $09
	ld a, [hli]
	ld [hl], a
	ld l, $26
	ld [hl], c
	dec l
	ld [hl], c
	dec l
	ld a, [hld]
	srl a
	ld [hl], a
	ld l, $20
	ld a, [hli]
	ld [hl], a
	ld l, $04
	bit 4, a
	jr nz, NoteOnRelease
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
	sub $EC
	ld l, $39
	ld [hli], a
	ld [hl], e
	inc l
	ld [hl], d
	jp ReadByte

; StreamCommand: REPEAT / LEN / VOLENV / ARP / INSTR ranges, else CmdTable.
StreamCommand:
	cp $EE
	jr nc, Cmd_Repeat
	cp $BE
	jr nc, Cmd_Len
	cp $AE
	jr nc, Cmd_VolEnv
	cp $92
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
	sub $BD
	ld l, $09
	ld [hl], a
	jp ReadStream

; VOLENV v, atk, dec, rates: start volume v; attack = lo nibble steps of hi nibble;
; decay likewise; rates hi = ticks per attack step, lo = ticks per decay step.
; Only the CH3 and SFX pages use it.
Cmd_VolEnv:
	sub $AE
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

; SetVolEnvBC: VOLENV from the four bytes at BC (start volume, attack, decay,
; rates), then ret. Called by song 3's NOTE_HOOK routines.
SetVolEnvBC:
	ld a, [bc]
	inc bc
	ld l, $16
	ld [hl], a
	ld a, [bc]
	inc bc
	ld l, $10
	ld [hl], a
	ld a, [bc]
	inc bc
	ld l, $13
	ld [hl], a
	ld a, [bc]
	swap a
	and $0F
	ld l, $18
	ld [hli], a
	ld [hl], a
	ld a, [bc]
	and $0F
	ld l, $1A
	ld [hli], a
	ld [hl], a
	ld l, $17
	ld [hl], a
	xor a
	ld l, $11
	ld [hl], a
	ret

; ARP n: arpeggio n of wArpTable.
Cmd_Arp:
	sub $92
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
	cp $C3
	jr nc, InstrLookup
	cp $C1
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

; SLIDE_UP n / SLIDE_DOWN n: set b3 + b4 (up) / b3 (down), delay 0, speed 1. A note
; on clears b4 (see NoteOn), so after the next note both slide down, n per tick
; for 255 ticks.
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
	cp $C1
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
	ld [$C307], a
	ldh [rNR30], a
	ldh [rNR34], a
	ret

; Unreferenced (113 bytes)
	db $09, $00, $00, $00, $05, $00, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $03, $00, $00, $00, $05, $00, $02, $00, $00, $00, $00, $00, $00, $00, $01, $00
	db $00, $00, $00, $00, $00, $00, $05, $00, $05, $00, $4D, $61, $70, $49, $44, $34
	db $36, $2C, $34, $37, $00, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00
	db $00, $05, $00, $05, $00, $4D, $61, $70, $49, $44, $32, $32, $2C, $32, $33, $00
	db $44, $00, $00, $00, $71, $00, $06, $00, $15, $00, $00, $00, $01, $00, $00, $00
	db $00, $00, $00, $00, $38, $30, $30, $2C, $36, $30, $30, $01, $00, $00, $00, $00
	db $00
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
	add a, $AA
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
	cp $BE
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
	dw Drum9
	dw Drum2
	dw Drum9
	dw Drum10

; Unreferenced (2 bytes)
	db $BB, $7E
DrumTempo:
	sub $BD
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
	ld a, $75
	ld [wInstrTableHi], a
	ld a, $B0
	ld [wInstrTable], a
	ld de, Song2_Ch1
	call StartMusicCh1
	ld de, Song2_Ch2
	call StartMusicCh2
	ld de, Song2_Ch3
	jp StartMusicCh3
Song2_Ch1:
	dw Pat_4B7E
	dw Pat_4B7E
	dw Pat_4B88
	dw Pat_4B88
	dw Pat_4B88
	dw Pat_4B88
	dw Pat_4BF8
	dw Pat_4C5C
	ORDER_LOOP Song2_Ch1
Song2_Ch3:
	dw Pat_4D07
	dw Pat_4D07
	dw Pat_4D21
	dw Pat_4D21
	dw Pat_4D1A
	dw Pat_4D5F
	dw Pat_4DCD
	dw Pat_4DE1
	ORDER_LOOP Song2_Ch3
Song2_Ch2:
	dw Pat_4DF5
	dw Pat_4DF5
	dw Pat_4E38
	dw Pat_4E84
	dw Pat_4EC9
	dw Pat_4F09
	dw Pat_4F40
	dw Pat_4F86
	ORDER_LOOP Song2_Ch2
Pat_4B7E:
	DRUMS $0A, DrumPat_4FCE
	VIBRATO $0A, $02, $06
	CH_TRANSPOSE $F4
Pat_4B88:
	INSTR 2
	LEN 20
	NOTE F_, 3
	INSTR 4
	LEN 10
	NOTE F_, 5
	INSTR 2
	LEN 20
	NOTE F_, 3
	LEN 10
	NOTE F_, 3
	INSTR 4
	NOTE F_, 5
	INSTR 2
	NOTE Dsh, 3
	LEN 20
	NOTE C_, 3
	INSTR 4
	LEN 10
	NOTE C_, 5
	INSTR 2
	LEN 20
	NOTE C_, 3
	LEN 10
	NOTE C_, 3
	INSTR 4
	NOTE C_, 5
	INSTR 2
	NOTE Dsh, 3
	LEN 20
	NOTE F_, 3
	INSTR 4
	LEN 10
	NOTE F_, 5
	INSTR 2
	LEN 20
	NOTE F_, 3
	LEN 10
	NOTE F_, 3
	INSTR 4
	NOTE F_, 5
	INSTR 2
	NOTE Dsh, 3
	LEN 20
	NOTE C_, 3
	INSTR 4
	LEN 10
	NOTE C_, 5
	INSTR 2
	LEN 20
	NOTE C_, 3
	LEN 10
	NOTE Dsh, 3
	INSTR 4
	NOTE C_, 5
	INSTR 2
	NOTE C_, 3
	LEN 20
	NOTE F_, 3
	INSTR 4
	LEN 10
	NOTE F_, 5
	INSTR 2
	LEN 20
	NOTE F_, 3
	LEN 10
	NOTE F_, 3
	INSTR 4
	NOTE F_, 5
	INSTR 2
	NOTE Dsh, 3
	LEN 20
	NOTE C_, 3
	INSTR 4
	LEN 10
	NOTE C_, 5
	INSTR 2
	LEN 20
	NOTE C_, 3
	LEN 10
	NOTE Dsh, 3
	INSTR 4
	NOTE C_, 5
	INSTR 2
	NOTE C_, 3
	LEN 20
	NOTE Csh, 3
	INSTR 3
	LEN 10
	NOTE Csh, 5
	INSTR 2
	LEN 20
	NOTE Csh, 3
	LEN 10
	NOTE F_, 3
	INSTR 3
	NOTE Csh, 5
	INSTR 2
	NOTE Csh, 3
	LEN 20
	NOTE Dsh, 3
	INSTR 3
	LEN 10
	NOTE Dsh, 5
	INSTR 2
	LEN 20
	NOTE Dsh, 3
	LEN 10
	NOTE F_, 3
	NOTE Dsh, 3
	NOTE C_, 3
	NEXT
Pat_4BF8:
	INSTR 2
	REPEAT 2
	LEN 20
	NOTE Gsh, 3
	INSTR 3
	LEN 10
	NOTE Gsh, 5
	INSTR 2
	LEN 20
	NOTE Gsh, 3
	LEN 10
	NOTE Gsh, 3
	INSTR 3
	NOTE Gsh, 5
	INSTR 2
	NOTE Dsh, 3
	REPEAT_END
	LEN 20
	NOTE Csh, 3
	INSTR 3
	LEN 10
	NOTE Csh, 5
	INSTR 2
	LEN 20
	NOTE Csh, 3
	LEN 10
	NOTE Csh, 3
	INSTR 3
	NOTE Csh, 5
	INSTR 2
	NOTE C_, 3
	LEN 20
	NOTE Csh, 3
	INSTR 3
	LEN 10
	NOTE Csh, 5
	INSTR 2
	LEN 20
	NOTE Csh, 3
	LEN 10
	NOTE Csh, 3
	INSTR 3
	NOTE Csh, 5
	INSTR 2
	NOTE Gsh, 3
	LEN 20
	NOTE Csh, 3
	INSTR 4
	LEN 10
	NOTE F_, 5
	INSTR 2
	LEN 20
	NOTE Csh, 3
	LEN 10
	NOTE Csh, 3
	INSTR 4
	NOTE F_, 5
	INSTR 2
	NOTE Gsh, 3
	LEN 20
	NOTE Dsh, 3
	INSTR 3
	LEN 10
	NOTE Dsh, 5
	INSTR 2
	LEN 20
	NOTE Dsh, 3
	LEN 10
	NOTE Dsh, 3
	INSTR 3
	NOTE Dsh, 5
	INSTR 2
	NOTE Dsh, 3
	LEN 20
	NOTE Gsh, 3
	INSTR 3
	LEN 10
	NOTE Gsh, 5
	INSTR 2
	LEN 20
	NOTE Gsh, 3
	LEN 10
	NOTE Gsh, 3
	INSTR 3
	NOTE Gsh, 5
	INSTR 2
	NOTE Dsh, 3
	LEN 20
	NOTE Gsh, 3
	INSTR 3
	LEN 10
	NOTE Gsh, 5
	INSTR 2
	LEN 20
	NOTE Gsh, 3
	LEN 10
	NOTE Gsh, 3
	NOTE Dsh, 3
	NOTE G_, 3
	NEXT
Pat_4C5C:
	INSTR 2
	LEN 20
	NOTE Gsh, 3
	INSTR 3
	LEN 10
	NOTE Gsh, 5
	INSTR 2
	LEN 20
	NOTE Gsh, 3
	LEN 10
	NOTE Gsh, 3
	INSTR 3
	NOTE Gsh, 5
	INSTR 2
	NOTE Dsh, 3
	LEN 20
	NOTE Gsh, 3
	INSTR 3
	LEN 10
	NOTE Gsh, 5
	INSTR 2
	LEN 20
	NOTE Gsh, 3
	LEN 10
	NOTE Gsh, 3
	INSTR 3
	NOTE Gsh, 5
	INSTR 2
	NOTE Dsh, 3
	LEN 20
	NOTE Csh, 3
	INSTR 3
	LEN 10
	NOTE Csh, 5
	INSTR 2
	LEN 20
	NOTE Csh, 3
	LEN 10
	NOTE Csh, 3
	INSTR 3
	NOTE Csh, 5
	INSTR 2
	NOTE C_, 3
	LEN 20
	NOTE Csh, 3
	INSTR 3
	LEN 10
	NOTE Csh, 5
	INSTR 2
	LEN 20
	NOTE Csh, 3
	LEN 10
	NOTE Csh, 3
	INSTR 3
	NOTE Csh, 5
	INSTR 2
	NOTE Gsh, 3
	LEN 20
	NOTE Csh, 3
	INSTR 4
	LEN 10
	NOTE F_, 5
	INSTR 2
	LEN 20
	NOTE Csh, 3
	LEN 10
	NOTE Csh, 3
	INSTR 4
	NOTE F_, 5
	INSTR 2
	NOTE Gsh, 3
	LEN 20
	NOTE Dsh, 3
	INSTR 3
	LEN 10
	NOTE Dsh, 5
	INSTR 2
	LEN 20
	NOTE Dsh, 3
	LEN 10
	NOTE Dsh, 3
	INSTR 3
	NOTE Dsh, 5
	INSTR 2
	NOTE Dsh, 3
	LEN 20
	NOTE F_, 3
	INSTR 4
	LEN 10
	NOTE F_, 5
	INSTR 2
	LEN 20
	NOTE F_, 3
	LEN 10
	NOTE F_, 3
	INSTR 4
	NOTE F_, 5
	INSTR 2
	NOTE C_, 3
	LEN 20
	NOTE F_, 3
	INSTR 4
	LEN 10
	NOTE F_, 5
	INSTR 2
	LEN 20
	NOTE F_, 3
	LEN 10
	NOTE F_, 3
	NOTE C_, 3
	NOTE Dsh, 3
	NEXT
Pat_4CCC:
	LEN 10
	NOTE F_, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE F_, 5
	LEN 20
	NOTE C_, 5
	LEN 30
	NOTE Ash, 4
	NOTE C_, 5
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE F_, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE F_, 5
	LEN 20
	NOTE Gsh, 5
	NOTE G_, 5
	LEN 10
	NOTE G_, 5
	LEN 20
	NOTE Dsh, 5
	LEN 10
	NOTE Dsh, 5
	LEN 20
	NOTE Ash, 4
	LEN 10
	NOTE F_, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE F_, 5
	LEN 20
	NOTE C_, 5
	LEN 30
	NOTE Ash, 4
	NOTE C_, 5
	LEN 20
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 10
	NOTE Ash, 4
	LEN 20
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 10
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NEXT
Pat_4D07:
	VOLENV 12, $11, $1F, $13
	WAVE Wave_7C80
	ARP 0
	VIBRATO $0A, $01, $04
	PAT_CALL Pat_4CCC
	NOTE F_, 4
	LEN 20
	NOTE Dsh, 4
	NEXT
Pat_4D1A:
	PAT_CALL Pat_4CCC
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NEXT
Pat_4D21:
	LEN 10
	NOTE F_, 3
	NOTE F_, 3
	NOTE C_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE F_, 4
	LEN 20
	NOTE C_, 4
	LEN 30
	NOTE Ash, 3
	NOTE C_, 4
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE F_, 3
	NOTE F_, 3
	NOTE C_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE F_, 4
	LEN 20
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	LEN 20
	NOTE Dsh, 4
	LEN 10
	NOTE Dsh, 4
	LEN 20
	NOTE Ash, 3
	LEN 10
	NOTE F_, 3
	NOTE F_, 3
	NOTE C_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE F_, 4
	LEN 20
	NOTE C_, 4
	LEN 30
	NOTE Ash, 3
	NOTE C_, 4
	LEN 20
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	LEN 10
	NOTE Ash, 3
	LEN 20
	NOTE Gsh, 3
	NOTE G_, 3
	LEN 10
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NEXT
Pat_4D5F:
	LEN 10
	NOTE C_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE F_, 5
	NOTE Gsh, 5
	NOTE Gsh, 5
	LEN 20
	NOTE F_, 5
	LEN 30
	NOTE Dsh, 5
	NOTE F_, 5
	LEN 20
	NOTE Ash, 4
	LEN 10
	NOTE C_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE F_, 5
	NOTE Gsh, 5
	NOTE Gsh, 5
	LEN 20
	NOTE C_, 6
	NOTE Ash, 5
	LEN 10
	NOTE C_, 6
	LEN 20
	NOTE Ash, 5
	LEN 10
	NOTE Gsh, 5
	LEN 20
	NOTE G_, 5
	LEN 10
	NOTE C_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE F_, 5
	NOTE Gsh, 5
	NOTE Gsh, 5
	LEN 20
	NOTE F_, 5
	LEN 30
	NOTE Dsh, 5
	NOTE F_, 5
	LEN 20
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE F_, 5
	LEN 10
	NOTE G_, 5
	LEN 20
	NOTE F_, 5
	NOTE G_, 5
	LEN 10
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE F_, 5
	LEN 20
	NOTE Dsh, 5
	NEXT
Pat_4D9D:
	LEN 10
	NOTE C_, 5
	NOTE Dsh, 4
	NOTE Gsh, 4
	LEN 20
	NOTE Ash, 4
	NOTE Dsh, 5
	NOTE C_, 5
	LEN 10
	NOTE Dsh, 4
	NOTE Gsh, 4
	LEN 20
	NOTE Ash, 4
	NOTE Dsh, 5
	LEN 10
	NOTE C_, 5
	NOTE F_, 4
	NOTE Gsh, 3
	NOTE Csh, 4
	LEN 20
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE F_, 4
	LEN 10
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Csh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE Csh, 5
	NOTE Gsh, 5
	NOTE Csh, 4
	NOTE Gsh, 3
	NOTE Csh, 4
	LEN 20
	NOTE Dsh, 4
	NOTE Gsh, 4
	LEN 10
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE Dsh, 4
	LEN 20
	NOTE F_, 4
	NOTE Ash, 4
	LEN 10
	NOTE Dsh, 5
	NEXT
Pat_4DCD:
	PAT_CALL Pat_4D9D
	NOTE Gsh, 4
	NOTE Dsh, 4
	NOTE Gsh, 4
	LEN 20
	NOTE Ash, 4
	NOTE Dsh, 5
	NOTE C_, 5
	LEN 10
	NOTE Dsh, 4
	NOTE Gsh, 4
	LEN 20
	NOTE Ash, 4
	LEN 10
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NEXT
Pat_4DE1:
	PAT_CALL Pat_4D9D
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	LEN 20
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE F_, 4
	LEN 10
	NOTE C_, 4
	NOTE F_, 4
	LEN 20
	NOTE Gsh, 4
	LEN 10
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE G_, 4
	NEXT
Pat_4DF5:
	VIBRATO $0A, $01, $04
	RELEASE $00
	DUTY_50
	HWENV $D2, $0F, $63
	ARP 0
	LEN 30
	NOTE C_, 4
	LEN 10
	NOTE C_, 4
	NOTE C_, 5
	LEN 30
	NOTE C_, 5
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 20
	NOTE Dsh, 4
	LEN 30
	NOTE C_, 4
	LEN 10
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 5
	LEN 20
	NOTE F_, 5
	NOTE Dsh, 5
	LEN 10
	NOTE Dsh, 5
	LEN 20
	NOTE Ash, 4
	LEN 10
	NOTE Ash, 4
	LEN 20
	NOTE G_, 4
	LEN 30
	NOTE C_, 4
	LEN 10
	NOTE C_, 4
	NOTE C_, 5
	LEN 30
	NOTE C_, 5
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 20
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE F_, 4
	LEN 10
	NOTE G_, 4
	LEN 20
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 10
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE Ash, 3
	NOTE G_, 3
	NEXT
Pat_4E38:
	HWENV $99, $04, $D0
	RELEASE $01, $B2
	ARP 3
	LENGTH $3C
	NOTE Dsh, 4
	LEN 10
	WAIT2
	ARP 0
	NOTE Dsh, 4
	LEN 40
	NOTE C_, 4
	LEN 10
	WAIT2
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	ARP 3
	NOTE B_, 4
	ARP 0
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	LENGTH $32
	NOTE Dsh, 4
	LEN 10
	WAIT2
	NOTE C_, 4
	NOTE Dsh, 4
	ARP 3
	LENGTH $32
	NOTE Dsh, 4
	ARP 0
	LEN 10
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Dsh, 4
	LEN 40
	NOTE C_, 4
	LEN 10
	WAIT2
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Csh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	ARP 3
	NOTE Gsh, 4
	ARP 0
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 20
	NOTE Dsh, 4
	LEN 10
	WAIT2
	LEN 20
	NOTE G_, 4
	LEN 10
	WAIT2
	LEN 20
	NOTE Ash, 4
	NEXT
Pat_4E84:
	ARP 3
	LENGTH $3C
	NOTE Dsh, 4
	LEN 10
	WAIT2
	ARP 0
	NOTE Dsh, 4
	LEN 40
	NOTE C_, 4
	LEN 10
	WAIT2
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	ARP 3
	NOTE B_, 4
	ARP 0
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	LENGTH $32
	NOTE Dsh, 4
	LEN 10
	WAIT2
	NOTE C_, 4
	NOTE Dsh, 4
	ARP 3
	LENGTH $32
	NOTE Dsh, 4
	ARP 0
	LEN 10
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE Ash, 4
	NOTE Dsh, 4
	WAIT2
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Csh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	ARP 3
	NOTE Gsh, 4
	ARP 0
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE Ash, 4
	WAIT2
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NEXT
Pat_4EC9:
	ARP 0
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE Gsh, 4
	NOTE F_, 4
	HWENV $E2, $0F, $73
	ARP 0
	RELEASE $00
	NOTE C_, 5
	LEN 30
	NOTE C_, 5
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 20
	NOTE Dsh, 4
	LEN 30
	NOTE C_, 4
	LEN 10
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 5
	LEN 20
	NOTE F_, 5
	NOTE Dsh, 5
	LEN 10
	NOTE Dsh, 5
	LEN 20
	NOTE Ash, 4
	LEN 10
	NOTE Ash, 4
	LEN 20
	NOTE G_, 4
	LEN 30
	NOTE C_, 4
	LEN 10
	NOTE C_, 4
	NOTE C_, 5
	LEN 30
	NOTE C_, 5
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 20
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE F_, 4
	LEN 10
	NOTE G_, 4
	LEN 20
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 10
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NEXT
Pat_4F09:
	LEN 30
	NOTE C_, 4
	LEN 10
	NOTE C_, 4
	NOTE F_, 5
	LEN 30
	NOTE F_, 5
	NOTE C_, 5
	NOTE C_, 5
	LEN 20
	NOTE G_, 4
	LEN 30
	NOTE C_, 4
	LEN 10
	NOTE C_, 4
	NOTE F_, 5
	NOTE F_, 5
	LEN 20
	NOTE Gsh, 5
	NOTE G_, 5
	LEN 10
	NOTE Gsh, 5
	LEN 20
	NOTE G_, 5
	LEN 10
	NOTE F_, 5
	LEN 20
	NOTE Dsh, 5
	LEN 30
	NOTE C_, 4
	LEN 10
	NOTE C_, 4
	NOTE F_, 5
	LEN 30
	NOTE F_, 5
	NOTE C_, 5
	NOTE C_, 5
	LEN 20
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 10
	NOTE Ash, 4
	LEN 20
	NOTE Gsh, 4
	NOTE Ash, 4
	LEN 10
	NOTE C_, 5
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	LEN 20
	NOTE G_, 4
	NEXT
Pat_4F40:
	HWENV $E2, $0F, $73
	LEN 20
	NOTE Gsh, 4
	HWENV $99, $04, $D0
	RELEASE $01, $B2
	ARP 0
	LEN 10
	NOTE C_, 5
	NOTE Csh, 5
	WAIT2
	NOTE Dsh, 5
	WAIT2
	ARP 3
	LENGTH $32
	NOTE Csh, 5
	ARP 0
	LEN 10
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	LENGTH $3C
	NOTE Gsh, 4
	LEN 10
	NOTE Ash, 4
	LEN 30
	NOTE F_, 4
	LENGTH $50
	WAIT2
	LEN 10
	NOTE Csh, 5
	NOTE C_, 5
	WAIT2
	NOTE Gsh, 4
	WAIT2
	LEN 20
	NOTE Ash, 4
	LEN 10
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE Dsh, 5
	ARP 3
	LEN 30
	NOTE B_, 4
	ARP 0
	LEN 10
	NOTE C_, 5
	WAIT2
	NOTE Ash, 4
	LEN 40
	NOTE C_, 5
	LENGTH $3C
	WAIT2
	NEXT
Pat_4F86:
	HWENV $E2, $0F, $73
	RELEASE $00
	LEN 20
	NOTE Gsh, 4
	HWENV $99, $04, $D0
	RELEASE $01, $B2
	ARP 0
	LEN 10
	NOTE C_, 5
	NOTE Csh, 5
	WAIT2
	NOTE Dsh, 5
	WAIT2
	ARP 3
	LENGTH $32
	NOTE Csh, 5
	ARP 0
	LEN 10
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	LENGTH $3C
	NOTE Gsh, 4
	LEN 10
	NOTE Ash, 4
	LEN 30
	NOTE F_, 4
	LENGTH $50
	WAIT2
	LEN 10
	NOTE Csh, 5
	NOTE C_, 5
	WAIT2
	NOTE Gsh, 4
	WAIT2
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE Gsh, 4
	NOTE Ash, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 20
	NOTE G_, 4
	LEN 10
	WAIT2
	LEN 20
	NOTE Gsh, 4
	LEN 10
	WAIT2
	LENGTH $50
	NOTE F_, 4
	LEN 20
	WAIT2
	NEXT
DrumPat_4FCE:
	db DRUM_LEVEL + 14, DRUM_REPEAT + 3, 1, 6, 9, 9, 1, 6
	db 9, 6, 1, 6, 9, 1, 5, 1
	db 9, 6, DRUM_REPEAT_END, 1, 6, 9, 9, 1
	db 6, 9, 6, 1, 6, 9, 1, 5
	db 9, 9, 1, DRUM_LOOP

; Song 3: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong3:
	call StopAll
	ld a, $75
	ld [wInstrTableHi], a
	ld a, $B0
	ld [wInstrTable], a
	ld de, Song3_Ch1
	call StartMusicCh1
	ld de, Song3_Ch3
	call StartMusicCh3
	ld de, Song3_Ch2
	jp StartMusicCh2
Song3_Ch1:
	dw Pat_515A
	dw Pat_5053
	dw Pat_5099
	dw Pat_5179
	dw Pat_51BD
	dw Pat_5179
	dw Pat_5201
	ORDER_LOOP Song3_Ch1
Song3_Ch3:
	dw Pat_532E
	dw Pat_5245
	dw Pat_5278
	dw Pat_529D
	dw Pat_52D7
	dw Pat_530A
	dw Pat_52C2
	dw Pat_5354
	dw Pat_52C2
	dw Pat_5354
	ORDER_LOOP Song3_Ch3
Song3_Ch2:
	dw Pat_542F
	dw Pat_5378
	dw Pat_53A0
	dw Pat_53C1
	dw Pat_53E9
	dw Pat_5406
	dw Pat_5446
	dw Pat_547F
	dw Pat_5446
	dw Pat_54A7
	ORDER_LOOP Song3_Ch2
Pat_5053:
	DRUMS $09, DrumPat_54FF
	INSTR 2
	LEN 27
	NOTE F_, 3
	LEN 9
	NOTE F_, 3
	INSTR 4
	LEN 18
	NOTE F_, 5
	INSTR 2
	LEN 36
	NOTE F_, 3
	LEN 18
	NOTE F_, 3
	INSTR 4
	NOTE F_, 5
	INSTR 2
	NOTE C_, 3
	INSTR 2
	LEN 27
	NOTE F_, 3
	LEN 9
	NOTE F_, 3
	INSTR 4
	LEN 18
	NOTE F_, 5
	INSTR 2
	LEN 36
	NOTE F_, 3
	LEN 18
	NOTE F_, 3
	INSTR 4
	NOTE F_, 5
	INSTR 2
	NOTE F_, 3
	INSTR 2
	LEN 27
	NOTE C_, 3
	LEN 9
	NOTE C_, 3
	INSTR 3
	LEN 18
	NOTE C_, 5
	INSTR 2
	LEN 36
	NOTE C_, 3
	LEN 18
	NOTE C_, 3
	INSTR 3
	NOTE C_, 5
	INSTR 2
	NOTE G_, 3
	LEN 27
	NOTE C_, 3
	LEN 9
	NOTE C_, 3
	INSTR 3
	LEN 18
	NOTE C_, 5
	INSTR 2
	LEN 36
	NOTE C_, 3
	LEN 18
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NEXT
Pat_5099:
	LEN 27
	NOTE F_, 3
	LEN 9
	NOTE F_, 3
	INSTR 4
	LEN 18
	NOTE F_, 5
	INSTR 2
	LEN 36
	NOTE F_, 3
	LEN 18
	NOTE F_, 3
	INSTR 4
	NOTE F_, 5
	INSTR 2
	NOTE C_, 3
	LEN 27
	NOTE F_, 3
	LEN 9
	NOTE F_, 3
	INSTR 4
	LEN 18
	NOTE F_, 5
	INSTR 2
	LEN 36
	NOTE F_, 3
	LEN 18
	NOTE F_, 3
	INSTR 4
	NOTE F_, 5
	INSTR 2
	NOTE F_, 3
	LEN 27
	NOTE Fsh, 3
	LEN 9
	NOTE Fsh, 3
	INSTR 3
	LEN 18
	NOTE Fsh, 5
	INSTR 2
	LEN 36
	NOTE Fsh, 3
	LEN 18
	NOTE Fsh, 3
	INSTR 3
	NOTE Fsh, 5
	INSTR 2
	NOTE Csh, 3
	LEN 27
	NOTE Fsh, 3
	LEN 9
	NOTE Fsh, 3
	INSTR 3
	LEN 18
	NOTE Fsh, 5
	INSTR 2
	NOTE Fsh, 3
	NOTE Fsh, 3
	NOTE Csh, 3
	NOTE Fsh, 3
	NOTE Dsh, 3
	PAT_CALL Pat_5053
	LEN 27
	NOTE Csh, 3
	LEN 9
	NOTE Csh, 3
	INSTR 3
	LEN 18
	NOTE Csh, 5
	INSTR 2
	LEN 36
	NOTE Csh, 3
	LEN 18
	NOTE Csh, 3
	INSTR 3
	NOTE Csh, 5
	INSTR 2
	NOTE C_, 3
	LEN 27
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	INSTR 3
	LEN 18
	NOTE G_, 5
	INSTR 2
	LEN 36
	NOTE G_, 3
	LEN 18
	NOTE D_, 3
	INSTR 3
	NOTE G_, 5
	INSTR 2
	NOTE G_, 3
	LEN 27
	NOTE C_, 3
	LEN 9
	NOTE C_, 3
	INSTR 3
	LEN 18
	NOTE C_, 5
	INSTR 2
	LEN 36
	NOTE C_, 3
	LEN 18
	NOTE C_, 3
	INSTR 3
	NOTE C_, 5
	INSTR 2
	NOTE G_, 3
	LEN 27
	NOTE C_, 3
	INSTR 2
	LEN 9
	NOTE C_, 3
	INSTR 3
	LEN 18
	NOTE C_, 5
	INSTR 2
	LEN 36
	NOTE C_, 3
	INSTR 2
	LEN 18
	NOTE Csh, 3
	NOTE C_, 3
	INSTR 2
	NOTE C_, 3
	INSTR 2
	LEN 27
	NOTE F_, 3
	LEN 9
	NOTE F_, 3
	INSTR 4
	LEN 18
	NOTE F_, 5
	INSTR 2
	LEN 36
	NOTE F_, 3
	LEN 18
	NOTE F_, 3
	INSTR 4
	NOTE F_, 5
	INSTR 2
	NOTE Dsh, 3
	LEN 27
	NOTE F_, 3
	LEN 9
	NOTE F_, 3
	INSTR 4
	LEN 18
	NOTE F_, 5
	INSTR 2
	LEN 36
	NOTE F_, 3
	LEN 18
	NOTE F_, 3
	INSTR 4
	NOTE F_, 5
	INSTR 2
	NOTE Dsh, 3
	LEN 27
	NOTE F_, 3
	LEN 9
	NOTE F_, 3
	INSTR 4
	LEN 18
	NOTE F_, 5
	INSTR 2
	LEN 36
	NOTE F_, 3
	LEN 18
	NOTE F_, 3
	INSTR 4
	NOTE F_, 5
	INSTR 2
	NOTE Dsh, 3
	LEN 27
	NOTE F_, 3
	LEN 9
	NOTE F_, 3
	INSTR 4
	LEN 18
	NOTE F_, 5
	INSTR 2
	LEN 36
	NOTE F_, 3
	LEN 18
	NOTE F_, 3
	NOTE Dsh, 3
	NOTE C_, 3
	NEXT
Pat_515A:
	CH_TRANSPOSE $F4
	DRUMS $09, DrumPat_54DC
	VIBRATO $09, $02, $04
	INSTR 2
	LEN 27
	NOTE F_, 3
	NOTE F_, 3
	LEN 36
	NOTE F_, 3
	NOTE F_, 3
	LEN 18
	NOTE Dsh, 3
	LEN 27
	NOTE F_, 3
	NOTE F_, 3
	LEN 36
	NOTE F_, 3
	LEN 18
	NOTE F_, 3
	INSTR 4
	NOTE F_, 5
	INSTR 2
	NOTE Dsh, 3
	NEXT
Pat_5179:
	INSTR 2
	LEN 27
	NOTE Csh, 3
	LEN 9
	NOTE Csh, 3
	INSTR 3
	LEN 18
	NOTE Csh, 5
	INSTR 2
	LEN 36
	NOTE Csh, 3
	LEN 18
	NOTE Csh, 3
	INSTR 3
	NOTE Csh, 5
	INSTR 2
	NOTE C_, 3
	LEN 27
	NOTE Csh, 3
	LEN 9
	NOTE Csh, 3
	INSTR 3
	LEN 18
	NOTE Csh, 5
	INSTR 2
	NOTE C_, 3
	NOTE Csh, 3
	NOTE Csh, 3
	INSTR 3
	NOTE Csh, 5
	INSTR 2
	NOTE Dsh, 3
	LEN 27
	NOTE F_, 3
	LEN 9
	NOTE F_, 3
	INSTR 4
	LEN 18
	NOTE F_, 5
	INSTR 2
	LEN 36
	NOTE F_, 3
	LEN 18
	NOTE F_, 3
	INSTR 4
	NOTE F_, 5
	INSTR 2
	NOTE Dsh, 3
	LEN 27
	NOTE F_, 3
	LEN 9
	NOTE F_, 3
	INSTR 4
	LEN 18
	NOTE F_, 5
	INSTR 2
	NOTE Dsh, 3
	NOTE F_, 3
	LEN 9
	NOTE C_, 4
	NOTE F_, 3
	INSTR 4
	NOTE F_, 5
	INSTR 2
	NOTE Dsh, 3
	LEN 18
	NOTE C_, 3
	NEXT
Pat_51BD:
	INSTR 2
	LEN 27
	NOTE Csh, 3
	LEN 9
	NOTE Csh, 3
	INSTR 3
	LEN 18
	NOTE Csh, 5
	INSTR 2
	LEN 36
	NOTE Csh, 3
	LEN 18
	NOTE Csh, 3
	INSTR 3
	NOTE Csh, 5
	INSTR 2
	NOTE Csh, 3
	LEN 27
	NOTE Dsh, 3
	LEN 9
	NOTE Dsh, 3
	INSTR 3
	LEN 18
	NOTE Dsh, 5
	INSTR 2
	NOTE Dsh, 3
	NOTE Gsh, 3
	NOTE G_, 3
	INSTR 3
	NOTE Dsh, 5
	INSTR 2
	NOTE Dsh, 3
	LEN 27
	NOTE F_, 3
	LEN 9
	NOTE F_, 3
	INSTR 4
	LEN 18
	NOTE F_, 5
	INSTR 2
	LEN 36
	NOTE F_, 3
	LEN 18
	NOTE F_, 3
	INSTR 4
	NOTE F_, 5
	INSTR 2
	NOTE Dsh, 3
	LEN 27
	NOTE F_, 3
	LEN 9
	NOTE F_, 3
	INSTR 4
	LEN 18
	NOTE F_, 5
	INSTR 2
	NOTE Dsh, 3
	NOTE F_, 3
	LEN 9
	NOTE C_, 4
	NOTE F_, 3
	INSTR 4
	NOTE F_, 5
	INSTR 2
	NOTE Dsh, 3
	LEN 18
	NOTE C_, 3
	NEXT
Pat_5201:
	INSTR 2
	LEN 27
	NOTE Csh, 3
	LEN 9
	NOTE Csh, 3
	INSTR 3
	LEN 18
	NOTE Csh, 5
	INSTR 2
	LEN 36
	NOTE Csh, 3
	LEN 18
	NOTE Csh, 3
	INSTR 3
	NOTE Csh, 5
	INSTR 2
	NOTE Csh, 3
	LEN 27
	NOTE Dsh, 3
	LEN 9
	NOTE Dsh, 3
	INSTR 3
	LEN 18
	NOTE Dsh, 5
	INSTR 2
	NOTE Dsh, 3
	NOTE Gsh, 3
	NOTE G_, 3
	INSTR 3
	NOTE Dsh, 5
	INSTR 2
	NOTE Dsh, 3
	LEN 27
	NOTE F_, 3
	LEN 9
	NOTE F_, 3
	INSTR 4
	LEN 18
	NOTE F_, 5
	INSTR 2
	LEN 36
	NOTE F_, 3
	LEN 18
	NOTE F_, 3
	INSTR 4
	NOTE F_, 5
	INSTR 2
	NOTE Dsh, 3
	LEN 27
	NOTE F_, 3
	LEN 9
	NOTE F_, 3
	INSTR 4
	LEN 18
	NOTE F_, 5
	INSTR 2
	NOTE F_, 3
	NOTE Dsh, 3
	LEN 9
	NOTE Ash, 3
	NOTE Dsh, 3
	INSTR 3
	NOTE Dsh, 5
	INSTR 2
	NOTE C_, 3
	LEN 18
	NOTE Dsh, 3
	NEXT
Pat_5245:
	REPEAT 2
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE Gsh, 5
	WAIT
	NOTE C_, 6
	WAIT
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE Gsh, 5
	WAIT
	NOTE Dsh, 6
	WAIT
	REPEAT_END
	NOTE E_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE Ash, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE C_, 6
	WAIT
	NOTE E_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE Ash, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE Csh, 6
	WAIT
	NEXT
Pat_5278:
	REPEAT 2
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE Gsh, 5
	WAIT
	NOTE C_, 6
	WAIT
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE Gsh, 5
	WAIT
	NOTE Dsh, 6
	WAIT
	REPEAT_END
	REPEAT 2
	NOTE Fsh, 5
	WAIT
	NOTE Gsh, 5
	WAIT
	NOTE Ash, 5
	WAIT
	NOTE Csh, 6
	WAIT
	NOTE Fsh, 5
	WAIT
	NOTE Gsh, 5
	WAIT
	NOTE Ash, 5
	WAIT
	NOTE Fsh, 6
	WAIT
	REPEAT_END
	NEXT
Pat_529D:
	REPEAT 2
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE Gsh, 5
	WAIT
	NOTE C_, 6
	WAIT
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE Gsh, 5
	WAIT
	NOTE Dsh, 6
	WAIT
	REPEAT_END
	REPEAT 2
	NOTE E_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE Ash, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE C_, 6
	WAIT
	REPEAT_END
	NEXT
Pat_52C2:
	REPEAT 2
	NOTE Csh, 5
	WAIT
	NOTE Dsh, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE Gsh, 5
	WAIT
	NOTE Csh, 5
	WAIT
	NOTE Dsh, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE Csh, 6
	WAIT
	REPEAT_END
	PAT_GOTO Pat_5341
Pat_52D7:
	NOTE Csh, 5
	WAIT
	NOTE Dsh, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE Gsh, 5
	WAIT
	NOTE Csh, 5
	WAIT
	NOTE Dsh, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE Csh, 6
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE G_, 5
	WAIT
	REPEAT 2
	NOTE E_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE Ash, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE C_, 6
	WAIT
	REPEAT_END
	NEXT
Pat_530A:
	PAT_CALL Pat_5341
	NOTE F_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE Gsh, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE F_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE Gsh, 4
	WAIT
	NOTE Dsh, 5
	WAIT
	NOTE F_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE Gsh, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE Gsh, 5
	NOTE C_, 6
	NEXT
Pat_532E:
	VIBRATO $05, $01, $04
	LEN 9
	CH_TRANSPOSE $0C
	WAVE Wave_7D10
	VOLENV 15, $11, $1F, $11
	NOTE_HOOK Song3HookNote, Song3HookWait
Pat_5341:
	REPEAT 2
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE Gsh, 5
	WAIT
	NOTE C_, 6
	WAIT
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE Gsh, 5
	WAIT
	NOTE Dsh, 6
	WAIT
	REPEAT_END
	NEXT
Pat_5354:
	NOTE Csh, 5
	WAIT
	NOTE Dsh, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE Gsh, 5
	WAIT
	NOTE Csh, 5
	WAIT
	NOTE Dsh, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE Csh, 6
	WAIT
	NOTE Dsh, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE Ash, 5
	WAIT
	NOTE Dsh, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE Dsh, 6
	WAIT
	PAT_GOTO Pat_5341

; Unreferenced (1 bytes)
	db $6A
Pat_5378:
	ARP_OFF
	LENGTH $6C
	NOTE C_, 5
	LEN 18
	WAIT2
	LEN 9
	NOTE C_, 5
	NOTE Csh, 5
	LEN 18
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE F_, 4
	LEN 36
	NOTE C_, 4
	LEN 18
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	LENGTH $5A
	NOTE E_, 4
	ARP 3
	LEN 18
	NOTE F_, 4
	ARP_OFF
	NOTE Csh, 4
	LEN 9
	NOTE C_, 4
	WAIT2
	LENGTH $51
	NOTE C_, 4
	LEN 9
	WAIT2
	LEN 18
	NOTE G_, 4
	NOTE C_, 5
	NOTE Csh, 5
	NEXT
Pat_53A0:
	ARP_OFF
	LENGTH $5A
	NOTE C_, 5
	LEN 18
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE C_, 5
	LENGTH $5A
	NOTE Ash, 4
	LEN 18
	WAIT2
	NOTE C_, 5
	NOTE Csh, 5
	LENGTH $36
	NOTE Dsh, 5
	LEN 18
	WAIT2
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Csh, 5
	NEXT
Pat_53C1:
	ARP_OFF
	LENGTH $6C
	NOTE C_, 5
	LEN 18
	WAIT2
	LEN 9
	NOTE C_, 5
	NOTE Csh, 5
	LEN 18
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE F_, 4
	LEN 36
	NOTE C_, 4
	LEN 18
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	LENGTH $5A
	NOTE E_, 4
	ARP 3
	LEN 18
	NOTE F_, 4
	ARP_OFF
	NOTE Csh, 4
	LEN 9
	NOTE C_, 4
	WAIT2
	LENGTH $51
	NOTE C_, 4
	LEN 9
	WAIT2
	LEN 18
	NOTE G_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NEXT
Pat_53E9:
	ARP_OFF
	LENGTH $63
	NOTE Csh, 4
	LEN 9
	WAIT2
	LEN 36
	NOTE C_, 4
	LENGTH $51
	NOTE B_, 3
	LEN 9
	WAIT2
	LEN 18
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	LENGTH $6C
	NOTE Gsh, 3
	LEN 18
	NOTE G_, 3
	NOTE Gsh, 3
	LENGTH $7E
	NOTE G_, 3
	LEN 18
	WAIT2
	NEXT
Pat_5406:
	RELEASE $00
	HWENV $92, $00
	LEN 18
	REPEAT 2
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE G_, 5
	REPEAT_END
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE Gsh, 5
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE C_, 6
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE Gsh, 5
	LEN 9
	NOTE C_, 5
	NOTE F_, 5
	NOTE Gsh, 5
	NOTE C_, 6
	NOTE F_, 5
	NOTE Gsh, 5
	NOTE C_, 6
	NOTE F_, 6
	RELEASE $01, $83
	NEXT
Pat_542F:
	HWENV $11, $00
	DUTY_50
	RELEASE $00
	VIBRATO $12, $01, $06
	LENGTH $87
	NOTE C_, 3
	WAIT2
	HWENV $A0, $00
	RELEASE $01, $83
	LEN 18
	NOTE C_, 4
	NEXT
Pat_5446:
	HWENV $F1, $04, $A0
	DUTY_50
	LEN 18
	NOTE Gsh, 4
	LEN 9
	WAIT2
	LEN 18
	NOTE G_, 4
	LEN 9
	WAIT2
	LEN 36
	NOTE Gsh, 4
	LEN 9
	WAIT2
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 27
	NOTE Gsh, 4
	LENGTH $3F
	NOTE F_, 4
	LEN 18
	WAIT2
	NOTE C_, 4
	NOTE Csh, 4
	LEN 27
	NOTE C_, 4
	LEN 18
	NOTE F_, 4
	LEN 9
	WAIT2
	LEN 18
	NOTE Gsh, 4
	LEN 27
	NOTE G_, 4
	LEN 18
	NOTE F_, 4
	LEN 9
	WAIT2
	LEN 18
	NOTE Csh, 4
	LENGTH $48
	NOTE C_, 4
	LENGTH $36
	WAIT2
	LEN 9
	NOTE F_, 4
	NOTE G_, 4
	NEXT
Pat_547F:
	LEN 18
	NOTE Gsh, 4
	LEN 9
	WAIT2
	LEN 18
	NOTE G_, 4
	LEN 9
	WAIT2
	LEN 36
	NOTE Gsh, 4
	LEN 9
	WAIT2
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 27
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Dsh, 4
	LEN 9
	WAIT2
	LEN 18
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 27
	NOTE G_, 4
	LEN 18
	NOTE F_, 4
	LEN 9
	WAIT2
	LENGTH $5A
	NOTE C_, 4
	LENGTH $90
	WAIT2
	NEXT
Pat_54A7:
	LEN 18
	NOTE Gsh, 4
	LEN 9
	WAIT2
	LEN 18
	NOTE G_, 4
	LEN 9
	WAIT2
	LENGTH $36
	NOTE F_, 4
	LEN 18
	WAIT2
	LEN 9
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 18
	NOTE Ash, 4
	LEN 9
	WAIT2
	LEN 18
	NOTE Gsh, 4
	LEN 9
	WAIT2
	LEN 27
	NOTE G_, 4
	LEN 9
	WAIT2
	LEN 18
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	LEN 27
	NOTE Ash, 4
	LEN 18
	NOTE C_, 5
	LEN 9
	WAIT2
	LEN 18
	NOTE Gsh, 4
	LEN 27
	NOTE G_, 4
	LEN 18
	NOTE Gsh, 4
	LEN 9
	WAIT2
	LENGTH $5A
	NOTE F_, 4
	LENGTH $48
	NOTE Dsh, 4
	NEXT
DrumPat_54DC:
	db DRUM_REPEAT + 3, DRUM_TEMPO + 10, 1, DRUM_TEMPO + 8, 6, DRUM_TEMPO + 10, 5, DRUM_TEMPO + 8
	db 6, DRUM_TEMPO + 10, 0, DRUM_TEMPO + 8, 6, DRUM_TEMPO + 10, 5, DRUM_TEMPO + 8
	db 6, DRUM_REPEAT_END, DRUM_TEMPO + 10, 1, DRUM_TEMPO + 8, 9, DRUM_TEMPO + 10, 1
	db DRUM_TEMPO + 8, 6, DRUM_TEMPO + 10, 9, DRUM_TEMPO + 8, 6, DRUM_TEMPO + 12, 9
	db DRUM_TEMPO + 7, 9, DRUM_LOOP
DrumPat_54FF:
	db DRUM_TEMPO + 9, DRUM_REPEAT + 3, DRUM_TEMPO + 10, 1, DRUM_TEMPO + 8, 5, DRUM_TEMPO + 10, 6
	db DRUM_TEMPO + 8, 1, DRUM_TEMPO + 10, 9, DRUM_TEMPO + 8, 5, DRUM_TEMPO + 10, 1
	db DRUM_TEMPO + 8, 4, DRUM_TEMPO + 10, 6, DRUM_TEMPO + 8, 5, DRUM_TEMPO + 10, 1
	db DRUM_TEMPO + 8, 6, DRUM_TEMPO + 10, 9, DRUM_TEMPO + 8, 5, DRUM_TEMPO + 10, 6
	db DRUM_TEMPO + 8, 6, DRUM_REPEAT_END, DRUM_TEMPO + 10, 1, DRUM_TEMPO + 8, 5, DRUM_TEMPO + 10
	db 6, DRUM_TEMPO + 8, 1, DRUM_TEMPO + 10, 9, DRUM_TEMPO + 8, 5, DRUM_TEMPO + 10
	db 1, DRUM_TEMPO + 8, 4, DRUM_TEMPO + 10, 6, DRUM_TEMPO + 8, 9, DRUM_TEMPO + 10
	db 1, DRUM_TEMPO + 8, 6, DRUM_TEMPO + 10, 9, DRUM_TEMPO + 8, 5, DRUM_TEMPO + 11
	db 9, DRUM_TEMPO + 7, 9, DRUM_LOOP

; Song 3 NOTE_HOOK, at each Ch3 note: VOLENV 15, $11, $1F, $11 (Song3EnvNote).
Song3HookNote:
	ld bc, Song3EnvNote
	jp SetVolEnvBC

; Song 3 NOTE_HOOK, at each Ch3 WAIT: VOLENV 10, $10, $1F, $11 (Song3EnvWait); the
; driver then replays the previous note (field $3C): a quieter echo.
Song3HookWait:
	ld bc, Song3EnvWait
	jp SetVolEnvBC
Song3EnvNote:
	db $0F, $11, $1F, $11
Song3EnvWait:
	db $0A, $10, $1F, $11

; Song 4: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong4:
	call StopAll
	ld a, $75
	ld [wInstrTableHi], a
	ld a, $B0
	ld [wInstrTable], a
	ld de, Song4_Ch1
	call StartMusicCh1
	ld de, Song4_Ch3
	call StartMusicCh3
	ld de, Song4_Ch2
	jp StartMusicCh2
Song4_Ch1:
	dw Pat_55BE
	dw Pat_55BE
	dw Pat_55C9
	dw Pat_55DE
	dw Pat_55C9
	dw Pat_55C9
	dw Pat_5616
	dw Pat_562F
	dw Pat_5642
	dw Pat_566B
	ORDER_LOOP Song4_Ch1
Song4_Ch3:
	dw Pat_568E
	dw Pat_568E
	dw Pat_5696
	dw Pat_56AF
	dw Pat_5696
	dw Pat_5696
	dw Pat_56FC
	dw Pat_570F
	dw Pat_56C8
	dw Pat_56E1
	ORDER_LOOP Song4_Ch3
Song4_Ch2:
	dw Pat_5730
	dw Pat_5730
	dw Pat_575C
	dw Pat_5779
	dw Pat_5797
	dw Pat_583B
	dw Pat_5864
	dw Pat_587E
	dw Pat_57C1
	dw Pat_57F5
	ORDER_LOOP Song4_Ch2
Pat_55BE:
	VIBRATO $07, $02, $04
	TRANSPOSE $FC
	DRUMS $07, DrumPat_58A1
	INSTR 2
Pat_55C9:
	REPEAT 2
	LEN 14
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE C_, 3
	NOTE D_, 3
	NOTE Dsh, 3
	NOTE Dsh, 3
	NOTE D_, 3
	LEN 28
	NOTE Dsh, 3
	LEN 14
	NOTE D_, 3
	LEN 28
	NOTE C_, 3
	REPEAT_END
	NEXT
Pat_55DE:
	LEN 14
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE C_, 3
	NOTE D_, 3
	NOTE Dsh, 3
	NOTE Dsh, 3
	NOTE D_, 3
	LEN 28
	NOTE Dsh, 3
	LEN 14
	NOTE D_, 3
	LEN 28
	NOTE C_, 3
	LEN 14
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Dsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	LEN 28
	NOTE F_, 3
	LEN 14
	NOTE Dsh, 3
	NOTE Gsh, 3
	NOTE G_, 3
	NEXT
Pat_5603:
	LEN 14
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Dsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	LEN 28
	NOTE Ash, 3
	LEN 14
	NOTE Gsh, 3
	NOTE F_, 3
	NOTE Dsh, 3
	NEXT
Pat_5616:
	PAT_CALL Pat_5603
	LEN 28
	NOTE F_, 3
	LEN 14
	NOTE F_, 3
	NOTE Dsh, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE Dsh, 3
	LEN 28
	NOTE F_, 3
	LEN 14
	NOTE F_, 3
	NOTE F_, 3
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE Gsh, 3
	LEN 7
	NOTE F_, 3
	NOTE Dsh, 3
	LEN 14
	NOTE F_, 3
	NEXT
Pat_562F:
	PAT_CALL Pat_5603
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE G_, 3
	NOTE Dsh, 3
	NOTE Dsh, 3
	NOTE Dsh, 3
	NOTE Ash, 3
	LEN 28
	NOTE Dsh, 3
	NOTE C_, 3
	NEXT
Pat_5642:
	DRUMS $07, DrumPat_58C7
	HWENV $F3, $00
	LEN 42
	NOTE F_, 3
	LEN 14
	NOTE F_, 3
	LEN 42
	NOTE C_, 4
	LEN 14
	NOTE C_, 4
	LEN 42
	NOTE Dsh, 3
	LEN 14
	NOTE Dsh, 3
	LEN 28
	NOTE Ash, 3
	NOTE A_, 3
	LEN 21
	NOTE F_, 3
	NOTE F_, 3
	LEN 14
	NOTE F_, 3
	LEN 21
	NOTE C_, 4
	NOTE A_, 3
	LEN 14
	NOTE F_, 3
	LEN 21
	NOTE Dsh, 3
	NOTE Dsh, 3
	LEN 14
	NOTE Dsh, 3
	LEN 28
	NOTE Ash, 3
	NOTE A_, 3
	NEXT
Pat_566B:
	LEN 42
	NOTE F_, 3
	LEN 14
	NOTE F_, 3
	LEN 42
	NOTE C_, 4
	LEN 14
	NOTE C_, 4
	LEN 42
	NOTE Dsh, 3
	LEN 14
	NOTE Dsh, 3
	LEN 28
	NOTE Ash, 3
	NOTE A_, 3
	LEN 21
	NOTE F_, 3
	NOTE F_, 3
	LEN 14
	NOTE F_, 3
	LEN 21
	NOTE C_, 4
	NOTE A_, 3
	LEN 14
	NOTE F_, 3
	LEN 21
	DRUMS $1C, DrumPat_58ED
	NOTE Dsh, 3
	LENGTH $5B
	WAIT2
	NEXT
Pat_568E:
	LEN 14
	VOLENV 15, $10, $1F, $11
	WAVE Wave_7CB0
Pat_5696:
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 5
	NOTE F_, 4
	REPEAT_END
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 5
	NOTE C_, 4
	REPEAT_END
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 5
	NOTE F_, 4
	REPEAT_END
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 5
	NOTE C_, 4
	REPEAT_END
	NEXT
Pat_56AF:
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 5
	NOTE F_, 4
	REPEAT_END
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 5
	NOTE C_, 4
	REPEAT_END
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 4
	NOTE Gsh, 4
	REPEAT_END
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 4
	NOTE Ash, 4
	REPEAT_END
	NEXT
Pat_56C8:
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 4
	NOTE F_, 4
	REPEAT_END
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 4
	NOTE Dsh, 4
	REPEAT_END
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 4
	NOTE F_, 4
	REPEAT_END
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 4
	NOTE Dsh, 4
	REPEAT_END
	NEXT
Pat_56E1:
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 4
	NOTE F_, 4
	REPEAT_END
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 4
	NOTE Dsh, 4
	REPEAT_END
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 4
	NOTE F_, 4
	REPEAT_END
	ARP 15
	LEN 28
	NOTE C_, 3
	NOTE C_, 3
	LENGTH $38
	NOTE C_, 3
	LEN 14
	NEXT
Pat_56FC:
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 4
	NOTE Gsh, 4
	REPEAT_END
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 4
	NOTE Ash, 4
	REPEAT_END
	REPEAT 8
	ARP 15
	NOTE C_, 3
	ARP 4
	NOTE F_, 4
	REPEAT_END
	NEXT
Pat_570F:
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 4
	NOTE Gsh, 4
	REPEAT_END
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 4
	NOTE Ash, 4
	REPEAT_END
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 4
	NOTE C_, 5
	REPEAT_END
	REPEAT 2
	ARP 15
	NOTE C_, 3
	ARP 4
	NOTE Dsh, 5
	REPEAT_END
	ARP 15
	NOTE C_, 3
	NOTE C_, 3
	LEN 7
	NOTE C_, 3
	NOTE C_, 3
	LEN 14
	NOTE C_, 3
	NEXT
Pat_5730:
	VIBRATO $0E, $01, $05
	DUTY_75
	INSTR 5
	LEN 28
	NOTE F_, 4
	INSTR 2
	NOTE F_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE D_, 4
	LEN 28
	NOTE Dsh, 4
	LEN 14
	NOTE D_, 4
	LEN 28
	NOTE Dsh, 4
	LEN 14
	NOTE D_, 4
	LEN 28
	NOTE C_, 4
	NOTE F_, 4
	NOTE F_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE D_, 4
	LEN 28
	NOTE Dsh, 4
	LEN 14
	NOTE D_, 4
	LEN 28
	NOTE Dsh, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE Gsh, 4
	NEXT
Pat_575C:
	INSTR 5
	LENGTH $54
	NOTE G_, 4
	LEN 14
	NOTE Gsh, 4
	LEN 28
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	LEN 28
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Ash, 3
	LENGTH $46
	NOTE C_, 4
	LEN 14
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Dsh, 4
	LENGTH $46
	NOTE C_, 4
	LEN 14
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE Gsh, 4
	NEXT
Pat_5779:
	INSTR 5
	LENGTH $54
	NOTE G_, 4
	LEN 14
	NOTE Gsh, 4
	LEN 28
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	LEN 28
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Ash, 3
	LENGTH $46
	NOTE C_, 5
	LEN 14
	NOTE Ash, 4
	NOTE Gsh, 4
	LEN 28
	NOTE G_, 4
	LENGTH $38
	NOTE F_, 4
	LEN 14
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NEXT
Pat_5797:
	INSTR 5
	LEN 28
	NOTE F_, 4
	INSTR 2
	ARP 1
	NOTE F_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE D_, 4
	LEN 28
	NOTE Dsh, 4
	LEN 14
	NOTE D_, 4
	LEN 28
	NOTE Dsh, 4
	LEN 14
	NOTE D_, 4
	LEN 28
	NOTE C_, 4
	LEN 14
	NOTE F_, 4
	NOTE F_, 4
	LEN 28
	NOTE F_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE D_, 4
	LEN 28
	NOTE Dsh, 4
	INSTR 5
	LEN 14
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE Gsh, 4
	NEXT
Pat_57C1:
	INSTR 5
	LEN 21
	NOTE F_, 4
	INSTR 2
	ARP 1
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	NOTE F_, 4
	LEN 21
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 21
	NOTE D_, 4
	NOTE D_, 4
	LEN 14
	NOTE D_, 4
	LEN 21
	NOTE F_, 4
	NOTE F_, 4
	LEN 28
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE F_, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE D_, 4
	NEXT
Pat_57F5:
	INSTR 2
	ARP 1
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE D_, 5
	LEN 14
	NOTE C_, 5
	LEN 7
	NOTE D_, 5
	LEN 14
	NOTE C_, 5
	LEN 7
	NOTE D_, 5
	LEN 14
	NOTE C_, 5
	LEN 7
	NOTE D_, 5
	LEN 14
	NOTE C_, 5
	NOTE D_, 5
	NOTE Ash, 4
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE C_, 5
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE C_, 4
	NOTE D_, 4
	LENGTH $38
	NOTE Dsh, 4
	LEN 14
	REST
	DRUMS_OFF
	INSTR 5
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NEXT
Pat_583B:
	INSTR 5
	LEN 28
	NOTE F_, 4
	INSTR 2
	ARP 1
	NOTE F_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE D_, 4
	LEN 28
	NOTE Dsh, 4
	LEN 14
	NOTE D_, 4
	LEN 28
	NOTE Dsh, 4
	LEN 14
	NOTE D_, 4
	LEN 28
	NOTE C_, 4
	LEN 14
	NOTE F_, 4
	NOTE F_, 4
	LEN 28
	NOTE F_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE D_, 4
	LEN 28
	NOTE Dsh, 4
	LEN 14
	NOTE D_, 4
	LEN 28
	NOTE C_, 4
	NEXT
Pat_5864:
	LEN 28
	WAIT
	INSTR 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	LEN 14
	NOTE G_, 4
	LEN 28
	NOTE F_, 4
	NOTE F_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Dsh, 4
	LEN 28
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 14
	NOTE F_, 4
	LENGTH $7E
	NOTE C_, 4
	NEXT
Pat_587E:
	LEN 28
	WAIT
	INSTR 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	LEN 14
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 28
	NOTE F_, 4
	LEN 14
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 28
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE F_, 4
	LEN 28
	NOTE G_, 4
	LEN 14
	NOTE F_, 4
	LEN 28
	NOTE C_, 5
	NOTE C_, 5
	LEN 14
	NOTE Ash, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NEXT
DrumPat_58A1:
	db DRUM_LEVEL + 14, DRUM_REPEAT + 3, 1, 0, 5, 0, 2, 0
	db 5, 0, DRUM_REPEAT_END, 1, 0, 5, 0, 2
	db 0, 4, 2, DRUM_REPEAT + 3, 1, 0, 5, 0
	db 2, 0, 5, 0, DRUM_REPEAT_END, 1, 0, 5
	db 0, 2, 0, 2, 2, DRUM_LOOP
DrumPat_58C7:
	db DRUM_LEVEL + 14, DRUM_REPEAT + 3, 1, 0, 5, 6, 2, 0
	db 5, 6, DRUM_REPEAT_END, 1, 0, 5, 6, 2
	db 0, 4, 2, DRUM_REPEAT + 3, 1, 0, 5, 6
	db 2, 0, 5, 6, DRUM_REPEAT_END, 1, 0, 5
	db 6, 2, 0, 2, 2, DRUM_LOOP
DrumPat_58ED:
	db 1, DRUM_LOOP

; Song 5: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong5:
	call StopAll
	ld a, $75
	ld [wInstrTableHi], a
	ld a, $B0
	ld [wInstrTable], a
	ld de, Song5_Ch1
	call StartMusicCh1
	ld de, Song5_Ch3
	call StartMusicCh3
	ld de, Song5_Ch2
	jp StartMusicCh2
Song5_Ch1:
	dw Pat_5A3B
	dw Pat_5A42
	dw Pat_5A42
	dw Pat_5950
	dw Pat_5950
	dw Pat_598D
	dw Pat_598D
	dw Pat_59D3
	dw Pat_5A07
	ORDER_LOOP Song5_Ch1
Song5_Ch3:
	dw Pat_5ABA
	dw Pat_5AC5
	dw Pat_5AC5
	dw Pat_5A53
	dw Pat_5A53
	dw Pat_5AC5
	dw Pat_5AC5
	dw Pat_5A70
	dw Pat_5A70
	ORDER_LOOP Song5_Ch3
Song5_Ch2:
	dw Pat_5C28
	dw Pat_5AE6
	dw Pat_5B00
	dw Pat_5B21
	dw Pat_5B45
	dw Pat_5BA1
	dw Pat_5BB1
	dw Pat_5BB8
	dw Pat_5BF2
	ORDER_LOOP Song5_Ch2
Pat_5950:
	LEN 20
	NOTE F_, 3
	LEN 10
	NOTE F_, 3
	INSTR 3
	LEN 20
	NOTE F_, 4
	LEN 40
	NOTE F_, 4
	INSTR 2
	LEN 10
	NOTE C_, 3
	NOTE D_, 3
	NOTE G_, 3
	LEN 20
	NOTE F_, 3
	LEN 10
	NOTE F_, 3
	INSTR 3
	LEN 20
	NOTE F_, 4
	LEN 40
	NOTE F_, 4
	INSTR 2
	LEN 10
	NOTE C_, 3
	NOTE D_, 3
	NOTE F_, 3
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE G_, 3
	INSTR 4
	LEN 20
	NOTE G_, 4
	LEN 40
	NOTE G_, 4
	INSTR 2
	LEN 10
	NOTE C_, 3
	NOTE D_, 3
	NOTE F_, 3
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE G_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 4
	NOTE G_, 4
	INSTR 2
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE G_, 3
	NOTE C_, 3
	NOTE D_, 3
	NOTE F_, 3
	NEXT
Pat_598D:
	INSTR 2
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE G_, 3
	INSTR 4
	NOTE G_, 5
	INSTR 2
	LEN 20
	NOTE F_, 3
	NOTE G_, 3
	INSTR 4
	LEN 10
	NOTE G_, 5
	INSTR 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE F_, 3
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE G_, 3
	INSTR 3
	NOTE F_, 5
	INSTR 2
	LEN 20
	NOTE F_, 3
	NOTE G_, 3
	INSTR 3
	LEN 10
	NOTE F_, 5
	INSTR 2
	NOTE Ash, 3
	NOTE C_, 4
	NOTE F_, 3
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE G_, 3
	INSTR 4
	NOTE G_, 5
	INSTR 2
	LEN 20
	NOTE F_, 3
	NOTE G_, 3
	INSTR 4
	LEN 10
	NOTE G_, 5
	INSTR 2
	NOTE F_, 3
	NOTE D_, 3
	NOTE C_, 3
	LEN 20
	NOTE D_, 3
	LEN 10
	NOTE D_, 3
	INSTR 4
	NOTE D_, 5
	INSTR 2
	LEN 20
	NOTE C_, 3
	NOTE D_, 3
	INSTR 4
	LEN 10
	NOTE D_, 5
	INSTR 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE F_, 3
	NEXT
Pat_59D3:
	NOTE G_, 3
	WAIT2
	NOTE G_, 3
	WAIT2
	LEN 20
	NOTE C_, 4
	NOTE D_, 4
	LEN 10
	NOTE C_, 4
	NOTE F_, 4
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE G_, 3
	WAIT2
	NOTE G_, 3
	WAIT2
	LEN 20
	NOTE C_, 4
	NOTE D_, 4
	LEN 10
	NOTE C_, 4
	NOTE F_, 4
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE G_, 3
	WAIT2
	NOTE G_, 3
	WAIT2
	LEN 20
	NOTE C_, 4
	NOTE D_, 4
	LEN 10
	NOTE C_, 4
	NOTE F_, 4
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE G_, 3
	WAIT2
	NOTE G_, 3
	WAIT2
	LEN 20
	NOTE C_, 4
	NOTE D_, 4
	LEN 10
	NOTE C_, 4
	NOTE F_, 4
	NOTE D_, 3
	NOTE C_, 4
	NEXT
Pat_5A07:
	NOTE G_, 3
	WAIT2
	NOTE G_, 3
	WAIT2
	LEN 20
	NOTE C_, 5
	NOTE D_, 5
	LEN 10
	NOTE C_, 5
	NOTE F_, 5
	LEN 20
	NOTE G_, 5
	LEN 10
	NOTE G_, 3
	WAIT2
	NOTE G_, 3
	WAIT2
	LEN 20
	NOTE C_, 5
	NOTE D_, 5
	LEN 10
	NOTE C_, 5
	NOTE F_, 5
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE G_, 3
	WAIT2
	NOTE G_, 3
	WAIT2
	LEN 20
	NOTE C_, 5
	NOTE D_, 5
	LEN 10
	NOTE C_, 5
	NOTE F_, 5
	LEN 20
	NOTE G_, 5
	LEN 10
	NOTE G_, 3
	WAIT2
	NOTE G_, 3
	WAIT2
	LEN 20
	NOTE C_, 5
	NOTE D_, 5
	LEN 10
	NOTE C_, 5
	NOTE C_, 3
	NOTE D_, 3
	NOTE F_, 3
	NEXT
Pat_5A3B:
	CH_TRANSPOSE $F4
	INSTR 2
	DRUMS $0A, DrumPat_5C50
Pat_5A42:
	REPEAT 4
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE G_, 3
	INSTR 4
	LEN 20
	NOTE G_, 4
	LEN 40
	NOTE G_, 4
	INSTR 2
	LEN 10
	NOTE C_, 3
	NOTE D_, 3
	NOTE F_, 3
	REPEAT_END
	NEXT
Pat_5A53:
	REPEAT 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE F_, 5
	REPEAT_END
	REPEAT 2
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE D_, 5
	NOTE G_, 4
	NOTE G_, 5
	REPEAT_END
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE F_, 5
	NOTE Ash, 4
	NOTE G_, 5
	NOTE C_, 5
	NOTE A_, 5
	NOTE D_, 5
	NOTE Ash, 5
	NEXT
Pat_5A70:
	VOLENV 15, $12, $2F, $11
	ARP 15
	LEN 10
	NOTE C_, 3
	ARP 0
	LEN 20
	NOTE G_, 3
	ARP 15
	NOTE C_, 3
	ARP 0
	LEN 10
	NOTE G_, 4
	ARP 15
	LEN 30
	NOTE C_, 3
	LEN 20
	NOTE C_, 3
	LEN 10
	NOTE C_, 3
	NOTE C_, 3
	ARP 0
	LEN 20
	NOTE G_, 3
	ARP 15
	NOTE C_, 3
	ARP 0
	LEN 10
	NOTE G_, 4
	ARP 15
	LEN 30
	NOTE C_, 3
	LEN 20
	NOTE C_, 3
	LEN 10
	NOTE C_, 3
	NOTE C_, 3
	ARP 0
	LEN 20
	NOTE G_, 3
	ARP 15
	NOTE C_, 3
	ARP 0
	LEN 10
	NOTE G_, 4
	ARP 15
	LEN 30
	NOTE C_, 3
	LEN 20
	NOTE C_, 3
	LEN 10
	NOTE C_, 3
	NOTE C_, 3
	ARP 0
	LEN 20
	NOTE G_, 3
	ARP 15
	NOTE C_, 3
	ARP 0
	LEN 10
	NOTE G_, 4
	ARP 15
	LEN 20
	NOTE C_, 3
	ARP 0
	LEN 10
	NOTE F_, 4
	ARP 15
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NEXT
Pat_5ABA:
	VOLENV 12, $11, $1F, $11
	ARP 0
	CH_TRANSPOSE $0C
	LEN 10
	WAVE Wave_7C90
Pat_5AC5:
	REPEAT 2
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE D_, 5
	NOTE G_, 4
	NOTE F_, 5
	REPEAT_END
	REPEAT 2
	NOTE F_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE D_, 5
	REPEAT_END
	REPEAT 2
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE Ash, 4
	NOTE D_, 4
	NOTE D_, 5
	REPEAT_END
	REPEAT 2
	NOTE F_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE F_, 5
	REPEAT_END
	NEXT
Pat_5AE6:
	LENGTH $5A
	NOTE G_, 4
	LEN 10
	NOTE D_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 30
	NOTE A_, 4
	NOTE Ash, 4
	ARP 3
	NOTE G_, 4
	ARP_OFF
	LEN 10
	NOTE F_, 4
	WAIT2
	LENGTH $82
	NOTE D_, 4
	LENGTH $64
	WAIT2
	LEN 10
	NOTE D_, 4
	NOTE F_, 4
	NEXT
Pat_5B00:
	ARP_OFF
	LENGTH $5A
	NOTE G_, 4
	LEN 10
	NOTE D_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 30
	NOTE A_, 4
	NOTE Ash, 4
	ARP 3
	NOTE G_, 4
	ARP_OFF
	LEN 10
	NOTE F_, 4
	WAIT2
	LENGTH $82
	NOTE D_, 4
	LENGTH $3C
	WAIT2
	ARP 3
	LEN 10
	NOTE C_, 4
	WAIT2
	ARP_OFF
	NOTE C_, 4
	WAIT2
	NOTE Ash, 3
	WAIT2
	NEXT
Pat_5B21:
	ARP_OFF
	LENGTH $5A
	NOTE C_, 4
	LEN 10
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Ash, 3
	LEN 40
	NOTE A_, 3
	LEN 10
	NOTE F_, 3
	NOTE G_, 3
	LEN 30
	NOTE A_, 3
	LEN 20
	NOTE Ash, 3
	LENGTH $5A
	NOTE G_, 3
	LEN 10
	WAIT2
	NOTE F_, 3
	NOTE Ash, 3
	NOTE C_, 4
	LENGTH $3C
	NOTE G_, 3
	LEN 10
	NOTE G_, 3
	WAIT2
	NOTE Ash, 3
	WAIT2
	NOTE D_, 4
	WAIT2
	NEXT
Pat_5B45:
	ARP_OFF
	LENGTH $5A
	NOTE C_, 4
	LEN 10
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Ash, 3
	LEN 40
	NOTE A_, 3
	LEN 10
	NOTE F_, 3
	NOTE G_, 3
	LEN 30
	NOTE A_, 3
	NOTE Ash, 3
	ARP 3
	NOTE G_, 3
	ARP_OFF
	LEN 10
	NOTE G_, 3
	WAIT2
	LENGTH $46
	NOTE G_, 3
	RELEASE $00
	INSTR 4
	LEN 20
	NOTE G_, 4
	NOTE G_, 4
	INSTR 3
	NOTE F_, 4
	INSTR 4
	LEN 30
	NOTE G_, 4
	HWENV $D0, $1E, $C7
	DUTY_50
	RELEASE $01, $52
	ARP_OFF
	LEN 10
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NEXT
Pat_5B77:
	LEN 10
	NOTE G_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	LENGTH $3C
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	LEN 30
	NOTE G_, 4
	LEN 10
	NOTE Ash, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE G_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	LEN 30
	NOTE G_, 4
	LEN 10
	NOTE F_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	WAIT2
	NOTE D_, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	NEXT
Pat_5BA1:
	DRUMS $0A, DrumPat_5C40
	ARP_OFF
	PAT_CALL Pat_5B77
	LEN 30
	NOTE D_, 4
	ARP 1
	LEN 10
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NEXT
Pat_5BB1:
	PAT_CALL Pat_5B77
	LENGTH $3C
	NOTE D_, 4
	NEXT
Pat_5BB8:
	INSTR 2
	RELEASE $02, $00
	LEN 10
	NOTE D_, 3
	NOTE D_, 4
	NOTE D_, 3
	NOTE G_, 4
	LEN 20
	NOTE F_, 3
	NOTE G_, 3
	LEN 10
	NOTE F_, 3
	NOTE Ash, 3
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE D_, 3
	NOTE D_, 4
	NOTE D_, 3
	NOTE G_, 4
	LEN 20
	NOTE F_, 3
	NOTE G_, 3
	LEN 10
	NOTE F_, 3
	NOTE Ash, 3
	LEN 20
	NOTE F_, 3
	LEN 10
	NOTE D_, 3
	NOTE D_, 4
	NOTE D_, 3
	NOTE G_, 4
	LEN 20
	NOTE F_, 3
	NOTE G_, 3
	LEN 10
	NOTE F_, 3
	NOTE Ash, 3
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE D_, 3
	NOTE D_, 4
	NOTE D_, 3
	NOTE G_, 4
	LEN 20
	NOTE F_, 3
	LEN 10
	NOTE G_, 3
	WAIT
	NOTE F_, 3
	NOTE Ash, 3
	NOTE G_, 3
	NOTE F_, 3
	NEXT
Pat_5BF2:
	LEN 10
	NOTE D_, 3
	NOTE D_, 4
	NOTE D_, 3
	NOTE G_, 4
	LEN 20
	NOTE F_, 3
	NOTE G_, 3
	LEN 10
	NOTE F_, 3
	NOTE Ash, 3
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE D_, 3
	NOTE D_, 4
	NOTE D_, 3
	NOTE G_, 4
	LEN 20
	NOTE F_, 3
	NOTE G_, 3
	LEN 10
	NOTE F_, 3
	NOTE Ash, 3
	LEN 20
	NOTE F_, 3
	LEN 10
	NOTE D_, 3
	NOTE D_, 4
	NOTE D_, 3
	NOTE G_, 4
	LEN 20
	NOTE F_, 3
	NOTE G_, 3
	LEN 10
	NOTE F_, 3
	NOTE Ash, 3
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE D_, 3
	NOTE D_, 4
	NOTE D_, 3
	NOTE G_, 4
	LEN 20
	NOTE F_, 3
	LEN 10
	NOTE G_, 3
	NOTE G_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NEXT
Pat_5C28:
	VIBRATO $0A, $01, $04
	HWENV $00, $00
	LENGTH $E6
	NOTE C_, 3
	WAIT2
	HWENV $D0, $1E, $C7
	RELEASE $01, $52
	DUTY_50
	ARP_OFF
	LEN 10
	NOTE D_, 4
	NOTE F_, 4
	NEXT
DrumPat_5C40:
	db DRUM_TEMPO + 10, 1, 6, 1, 2, 6, 6, 1
	db 6, 6, 2, 6, DRUM_TEMPO + 5, 6, 6, DRUM_LOOP
DrumPat_5C50:
	db DRUM_REPEAT + 3, 1, 0, 1, 4, 6, 6, 1
	db 0, 6, 4, 0, 6, DRUM_REPEAT_END, 1, 0
	db 1, 4, 6, 6, 1, 0, DRUM_TEMPO + 5, 6
	db 6, DRUM_TEMPO + 10, 4, 6, 1, DRUM_LOOP

; Song 6: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong6:
	call StopAll
	ld a, $75
	ld [wInstrTableHi], a
	ld a, $B0
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
	dw Pat_5CD0
	dw Pat_5D16
	dw Pat_5D35
	dw Pat_5D35
	dw Pat_5D35
	dw Pat_5D6C
	dw Pat_5D6C
	dw Pat_5DA4
	dw Pat_5CF0
	ORDER_LOOP Song6_Ch1
Song6_Ch3:
	dw Pat_5DCB
	dw Pat_5DDF
	dw Pat_5E6D
	dw Pat_5E2F
	dw Pat_5E2F
	dw Pat_5E47
	dw Pat_5E47
	dw Pat_5E91
	dw Pat_5EAB
	ORDER_LOOP Song6_Ch3
Song6_Ch2:
	dw Pat_5EC5
	dw Pat_5EE0
	dw Pat_5ED5
	dw Pat_5EE8
	dw Pat_5EF0
	dw Pat_5F1E
	dw Pat_5F1E
	dw Pat_5F85
	dw Pat_5F9C
	ORDER_LOOP Song6_Ch2
Pat_5CD0:
	TRANSPOSE $FE
	INSTR 7
	REPEAT 3
	LEN 28
	NOTE D_, 3
	INSTR 4
	LEN 14
	NOTE D_, 4
	INSTR 7
	LEN 28
	NOTE D_, 3
	INSTR 4
	NOTE D_, 4
	INSTR 7
	LEN 14
	NOTE F_, 3
	REPEAT_END
	LEN 28
	NOTE D_, 3
	INSTR 4
	LEN 14
	NOTE D_, 4
	INSTR 7
	LEN 28
	NOTE D_, 3
	INSTR 4
	NOTE D_, 4
	INSTR 7
	LEN 14
	NOTE D_, 3
	NEXT
Pat_5CF0:
	INSTR 7
	LEN 21
	NOTE Ash, 3
	NOTE F_, 3
	LEN 28
	NOTE Ash, 3
	LEN 14
	NOTE F_, 3
	NOTE Ash, 3
	NOTE F_, 3
	LEN 21
	NOTE A_, 3
	NOTE E_, 3
	LEN 28
	NOTE A_, 3
	LEN 14
	NOTE E_, 3
	NOTE A_, 3
	NOTE E_, 3
	LEN 21
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE F_, 3
	LEN 28
	NOTE G_, 3
	LEN 14
	NOTE D_, 3
	NOTE F_, 3
	LEN 28
	NOTE A_, 3
	NOTE A_, 3
	LEN 14
	NOTE A_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE E_, 3
	NEXT
Pat_5D16:
	INSTR 7
	REPEAT 3
	LEN 28
	NOTE Csh, 3
	INSTR 4
	LEN 14
	NOTE Csh, 4
	INSTR 7
	LEN 28
	NOTE Csh, 3
	INSTR 4
	NOTE Csh, 4
	INSTR 7
	LEN 14
	NOTE E_, 3
	REPEAT_END
	LEN 28
	NOTE Csh, 3
	INSTR 4
	LEN 14
	NOTE Csh, 4
	INSTR 7
	LEN 28
	NOTE Csh, 3
	INSTR 4
	LEN 14
	NOTE Csh, 4
	INSTR 7
	NOTE E_, 3
	NOTE Csh, 3
	NEXT
Pat_5D35:
	INSTR 7
	LEN 28
	NOTE D_, 3
	INSTR 4
	LEN 14
	NOTE D_, 4
	INSTR 7
	LEN 28
	NOTE D_, 3
	INSTR 4
	NOTE D_, 4
	INSTR 7
	LEN 14
	NOTE F_, 3
	LEN 28
	NOTE D_, 3
	INSTR 4
	LEN 14
	NOTE D_, 4
	INSTR 7
	LEN 28
	NOTE D_, 3
	INSTR 4
	NOTE D_, 4
	INSTR 7
	LEN 14
	NOTE C_, 3
	LEN 28
	NOTE D_, 3
	INSTR 4
	LEN 14
	NOTE D_, 4
	INSTR 7
	LEN 28
	NOTE D_, 3
	INSTR 4
	NOTE D_, 4
	INSTR 7
	LEN 14
	NOTE F_, 3
	LEN 28
	NOTE D_, 3
	INSTR 4
	LEN 14
	NOTE D_, 4
	INSTR 7
	LEN 28
	NOTE D_, 3
	INSTR 4
	LEN 14
	NOTE D_, 4
	INSTR 7
	NOTE C_, 3
	NOTE C_, 3
	NEXT
Pat_5D6C:
	INSTR 7
	LEN 28
	NOTE D_, 3
	INSTR 4
	LEN 14
	NOTE D_, 4
	INSTR 7
	LEN 28
	NOTE D_, 3
	INSTR 4
	NOTE D_, 4
	INSTR 7
	LEN 14
	NOTE F_, 3
	LEN 28
	NOTE C_, 3
	INSTR 3
	LEN 14
	NOTE C_, 4
	INSTR 7
	LEN 28
	NOTE C_, 3
	INSTR 3
	NOTE C_, 4
	INSTR 7
	LEN 14
	NOTE C_, 3
	LEN 28
	NOTE D_, 3
	INSTR 4
	LEN 14
	NOTE D_, 4
	INSTR 7
	LEN 28
	NOTE D_, 3
	INSTR 4
	LEN 14
	NOTE D_, 4
	INSTR 7
	NOTE D_, 3
	NOTE E_, 3
	LEN 28
	NOTE F_, 3
	INSTR 3
	LEN 14
	NOTE F_, 4
	INSTR 7
	LEN 28
	NOTE F_, 3
	INSTR 3
	LEN 14
	NOTE F_, 4
	INSTR 7
	NOTE C_, 3
	NOTE C_, 3
	NEXT
Pat_5DA4:
	INSTR 7
	LEN 21
	NOTE Ash, 3
	NOTE F_, 3
	LEN 28
	NOTE Ash, 3
	LEN 14
	NOTE F_, 3
	NOTE Ash, 3
	NOTE F_, 3
	LEN 21
	NOTE A_, 3
	NOTE E_, 3
	LEN 28
	NOTE A_, 3
	LEN 14
	NOTE E_, 3
	NOTE A_, 3
	NOTE E_, 3
	LEN 21
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE F_, 3
	LEN 28
	NOTE G_, 3
	LEN 14
	NOTE D_, 3
	NOTE F_, 3
	LEN 21
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE F_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE G_, 3
	NEXT
Pat_5DCB:
	DRUMS $0E, DrumPat_5FB1
	WAVE Wave_7CB0
	VOLENV 15, $10, $1F, $11
	ARP 15
	REPEAT 4
	LEN 42
	NOTE C_, 3
	LENGTH $46
	NOTE C_, 3
	REPEAT_END
	NEXT
Pat_5DDF:
	LEN 42
	NOTE C_, 3
	NOTE C_, 3
	LEN 28
	NOTE C_, 3
	LEN 42
	NOTE C_, 3
	NOTE C_, 3
	LEN 28
	NOTE C_, 3
	LEN 42
	NOTE C_, 3
	NOTE C_, 3
	LEN 28
	NOTE C_, 3
	LEN 42
	NOTE C_, 3
	NOTE C_, 3
	LEN 14
	NOTE C_, 3
	NOTE C_, 3
	NEXT
Pat_5DF5:
	ARP 15
	LEN 14
	NOTE C_, 3
	ARP_OFF
	LEN 7
	NOTE F_, 4
	NOTE D_, 4
	ARP 15
	LEN 14
	NOTE C_, 3
	ARP_OFF
	LEN 7
	NOTE A_, 4
	NOTE F_, 4
	ARP 15
	LEN 14
	NOTE C_, 3
	ARP_OFF
	LEN 7
	NOTE D_, 5
	NOTE A_, 4
	ARP 15
	LEN 14
	NOTE C_, 3
	ARP_OFF
	LEN 7
	NOTE F_, 5
	NOTE D_, 5
	NEXT
Pat_5E12:
	ARP 15
	LEN 14
	NOTE C_, 3
	ARP_OFF
	LEN 7
	NOTE E_, 4
	NOTE C_, 4
Pat_5E19:
	ARP 15
	LEN 14
	NOTE C_, 3
	ARP_OFF
	LEN 7
	NOTE G_, 4
	NOTE E_, 4
	ARP 15
	LEN 14
	NOTE C_, 3
	ARP_OFF
	LEN 7
	NOTE C_, 5
	NOTE G_, 4
	ARP 15
	LEN 14
	NOTE C_, 3
	ARP_OFF
	LEN 7
	NOTE E_, 5
	NOTE C_, 5
	NEXT
Pat_5E2F:
	DRUMS $07, DrumPat_5FEC
	PAT_CALL Pat_5DF5
	PAT_CALL Pat_5E12
	PAT_CALL Pat_5DF5
	PAT_CALL Pat_5E19
	ARP 15
	LEN 14
	NOTE C_, 3
	ARP_OFF
	LEN 7
	NOTE G_, 5
	NOTE E_, 5
	NEXT
Pat_5E47:
	PAT_CALL Pat_5DF5
	PAT_CALL Pat_5E12
	PAT_CALL Pat_5DF5
	ARP 15
	LEN 14
	NOTE C_, 3
	ARP_OFF
	LEN 7
	NOTE C_, 5
	NOTE G_, 4
	ARP 15
	LEN 14
	NOTE C_, 3
	ARP_OFF
	LEN 7
	NOTE F_, 5
	NOTE C_, 5
	ARP 15
	LEN 14
	NOTE C_, 3
	ARP_OFF
	LEN 7
	NOTE A_, 5
	NOTE F_, 5
	ARP 15
	LEN 14
	NOTE C_, 3
	ARP_OFF
	LEN 7
	NOTE C_, 6
	NOTE G_, 5
	NEXT
Pat_5E6D:
	REPEAT 3
	ARP 15
	LEN 21
	NOTE C_, 3
	ARP_OFF
	LEN 7
	NOTE A_, 3
	ARP 15
	LEN 28
	NOTE C_, 3
	LEN 14
	NOTE C_, 3
	ARP_OFF
	NOTE C_, 4
	ARP 15
	NOTE C_, 3
	ARP_OFF
	NOTE D_, 4
	REPEAT_END
	ARP 15
	LEN 21
	NOTE C_, 3
	ARP_OFF
	LEN 7
	NOTE A_, 3
	ARP 15
	LEN 28
	NOTE C_, 3
	LEN 14
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	LEN 7
	NOTE C_, 3
	NOTE C_, 3
	NEXT
Pat_5E91:
	LEN 14
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 5
	NOTE Ash, 4
	REPEAT_END
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 5
	NOTE A_, 4
	REPEAT_END
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 5
	NOTE G_, 4
	REPEAT_END
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 5
	NOTE G_, 4
	REPEAT_END
	NEXT
Pat_5EAB:
	LEN 14
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 4
	NOTE Ash, 4
	REPEAT_END
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 5
	NOTE A_, 4
	REPEAT_END
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 5
	NOTE G_, 4
	REPEAT_END
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 4
	NOTE A_, 4
	REPEAT_END
	NEXT
Pat_5EC5:
	LEN 1
	REST
	HWENV $B2, $06, $61
	ARP 11
	LEN 14
	VIBRATO $0E, $01, $05
	RELEASE $71, $A2
	DUTY_75
Pat_5ED5:
	REPEAT 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE A_, 4
	REPEAT_END
	NEXT
Pat_5EE0:
	CH_TRANSPOSE $FF
	PAT_CALL Pat_5ED5
	CH_TRANSPOSE $00
	NEXT
Pat_5EE8:
	HWENV $C0, $41, $C7
	ARP 0
	DUTY_75
	LENGTH $6F
Pat_5EF0:
	ARP 3
	NOTE C_, 4
	LENGTH $38
	ARP 0
	NOTE C_, 4
	ARP 3
	NOTE D_, 4
	LENGTH $70
	ARP_OFF
	NOTE A_, 3
	ARP 5
	HWENV $8E, $28, $E7
	NOTE D_, 4
	LENGTH $70
	NEXT
Pat_5F05:
	INSTR 4
	NOTE D_, 4
	HWENV $C0, $28, $C7
	ARP 0
	DUTY_50
	LEN 7
	NOTE D_, 4
	NOTE D_, 4
	LEN 14
	ARP 3
	NOTE Dsh, 4
	ARP 0
	NOTE D_, 4
	ARP 3
	NOTE G_, 4
	ARP 0
	NOTE F_, 4
	ARP 3
	NOTE C_, 5
	ARP 0
	NOTE A_, 4
	NEXT
Pat_5F1E:
	LEN 14
	PAT_CALL Pat_5F05
	INSTR 3
	NOTE C_, 4
	HWENV $C0, $28, $C7
	ARP 0
	DUTY_50
	LEN 7
	NOTE C_, 4
	NOTE C_, 4
	LEN 14
	ARP 3
	NOTE D_, 4
	ARP 0
	NOTE C_, 4
	ARP 3
	NOTE F_, 4
	ARP 0
	NOTE E_, 4
	ARP 3
	NOTE Ash, 4
	ARP 0
	NOTE G_, 4
	PAT_CALL Pat_5F05
	LEN 7
	NOTE G_, 4
	WAIT
	WAIT2
	LEN 21
	NOTE A_, 4
	LEN 14
	NOTE C_, 5
	LEN 4
	NOTE A_, 4
	ARP_OFF
	NOTE B_, 4
	LEN 20
	NOTE A_, 4
	LEN 28
	ARP 0
	NOTE G_, 4
	NEXT
Pat_5F4F:
	LEN 7
	DUTY_75
	NOTE Ash, 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE D_, 5
	NOTE Ash, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE Ash, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE Ash, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE A_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE A_, 4
	LEN 7
	DUTY_50
	ARP 3
	NOTE F_, 5
	WAIT
	WAIT2
	ARP 0
	NOTE F_, 5
	WAIT
	WAIT2
	NOTE E_, 5
	WAIT2
	NOTE D_, 5
	WAIT
	WAIT2
	NOTE C_, 5
	WAIT
	WAIT2
	NOTE Ash, 4
	NEXT
Pat_5F85:
	PAT_CALL Pat_5F4F
	WAIT
	DUTY_75
	LEN 7
	NOTE G_, 4
	NOTE G_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE F_, 5
	NOTE F_, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE G_, 4
	NOTE G_, 5
	NOTE F_, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE G_, 4
	NOTE D_, 5
	NOTE G_, 5
	NEXT
Pat_5F9C:
	PAT_CALL Pat_5F4F
	WAIT2
	NOTE A_, 4
	WAIT
	WAIT
	WAIT2
	NOTE Csh, 5
	WAIT
	WAIT
	WAIT2
	NOTE E_, 5
	WAIT
	WAIT
	WAIT2
	NOTE A_, 5
	WAIT
	WAIT
	WAIT2
	NEXT
DrumPat_5FB1:
	db DRUM_REPEAT + 7, 1, 6, 5, 1, 5, 6, 5
	db 0, DRUM_REPEAT_END, 1, 6, 5, 1, 5, 6
	db 1, 9, 1, 6, 9, 6, 1, 6
	db 9, 6, 1, 6, 9, 6, 1, 6
	db 9, DRUM_TEMPO + 7, 10, 10, DRUM_TEMPO + 14, 1, 6, 9
	db 6, 1, 6, 9, 6, 1, 6, 9
	db DRUM_TEMPO + 7, 6, 10, DRUM_TEMPO + 14, 1, 1, 1, DRUM_TEMPO + 7
	db 1, 1, DRUM_LOOP
DrumPat_5FEC:
	db 1, 0, 5, 6, 2, 0, 5, 6
	db 1, 0, 5, 6, 2, 6, 5, 6
	db 1, 0, 5, 6, 2, 0, 5, 6
	db 1, 0, 5, 6, 2, 6, 5, 2
	db 1, 0, 5, 6, 2, 0, 5, 6
	db 1, 0, 5, 6, 2, 6, 5, 6
	db 1, 0, 5, 6, 2, 0, 5, 2
	db 1, 0, 5, 6, 2, 0, 2, 2
	db DRUM_LOOP

; Song 7: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong7:
	call StopAll
	ld a, $75
	ld [wInstrTableHi], a
	ld a, $B0
	ld [wInstrTable], a
	ld de, Song7_Ch1
	call StartMusicCh1
	ld de, Song7_Ch3
	call StartMusicCh3
	ld de, Song7_Ch2
	jp StartMusicCh2
Song7_Ch1:
	dw Pat_612C
Loop_604E:
	dw Pat_6088
	dw Pat_60DF
	dw Pat_6088
	dw Pat_60E8
	dw Pat_6109
	dw Pat_6109
	dw Pat_6109
	ORDER_LOOP Loop_604E
Song7_Ch3:
	dw Pat_619A
Loop_6062:
	dw Pat_6144
	dw Pat_615B
	dw Pat_6144
	dw Pat_615B
	dw Pat_6173
	dw Pat_6182
	dw Pat_6182
	dw Pat_6182
	dw Pat_6182
	ORDER_LOOP Loop_6062
Song7_Ch2:
	dw Pat_62A7
Loop_607A:
	dw Pat_61B1
	dw Pat_6221
	dw Pat_61B1
	dw Pat_622F
	dw Pat_6255
	ORDER_LOOP Loop_607A
Pat_6088:
	DRUMS $06, DrumPat_62C5
	REPEAT 4
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	NOTE G_, 3
	REPEAT_END
	REPEAT 4
	NOTE Dsh, 2
	WAIT
	NOTE Dsh, 3
	NOTE Dsh, 3
	REPEAT_END
	REPEAT 2
	NOTE F_, 2
	WAIT
	NOTE F_, 3
	NOTE F_, 3
	REPEAT_END
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	NOTE G_, 3
	NOTE A_, 2
	WAIT
	NOTE A_, 3
	NOTE A_, 3
	REPEAT 4
	NOTE Ash, 2
	WAIT
	NOTE Ash, 3
	NOTE Ash, 3
	REPEAT_END
	NEXT
Pat_60AD:
	REPEAT 2
	NOTE Dsh, 2
	WAIT
	NOTE Dsh, 3
	NOTE Dsh, 3
	REPEAT_END
	REPEAT 2
	NOTE D_, 2
	WAIT
	NOTE D_, 3
	NOTE D_, 3
	REPEAT_END
	REPEAT 2
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	NOTE G_, 3
	REPEAT_END
	NOTE A_, 2
	WAIT
	NOTE A_, 3
	NOTE A_, 3
	NOTE Ash, 2
	WAIT
	NOTE Ash, 3
	NOTE Ash, 3
	REPEAT 2
	NOTE A_, 2
	WAIT
	NOTE A_, 3
	NOTE A_, 3
	REPEAT_END
	NOTE B_, 2
	WAIT
	NOTE B_, 3
	NOTE B_, 3
	NOTE Csh, 3
	WAIT
	NOTE Csh, 4
	NOTE Csh, 4
	REPEAT 2
	NOTE D_, 2
	WAIT
	NOTE D_, 3
	NOTE D_, 3
	REPEAT_END
	NOTE D_, 2
	WAIT
	NOTE D_, 3
	NEXT
Pat_60DF:
	PAT_CALL Pat_60AD
	NOTE Dsh, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE A_, 2
	NOTE Ash, 2
	NEXT
Pat_60E8:
	PAT_CALL Pat_60AD
	NOTE D_, 3
	NOTE D_, 2
	WAIT
	NOTE D_, 3
	NOTE D_, 3
	DRUMS $06, DrumPat_62BA
	LEN 12
	REPEAT 3
	NOTE G_, 2
	NOTE G_, 3
	REPEAT_END
	NOTE G_, 2
	LEN 6
	NOTE G_, 3
	NOTE G_, 2
	REPEAT 2
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	NOTE G_, 2
	REPEAT_END
	REPEAT 2
	NOTE F_, 2
	WAIT
	NOTE F_, 3
	NOTE F_, 3
	REPEAT_END
Pat_6109:
	DRUMS $06, DrumPat_62C5
	REPEAT 4
	NOTE Dsh, 2
	WAIT
	NOTE Dsh, 3
	NOTE Ash, 2
	REPEAT_END
	REPEAT 4
	NOTE F_, 2
	WAIT
	NOTE F_, 3
	NOTE C_, 3
	REPEAT_END
	REPEAT 4
	NOTE D_, 2
	WAIT
	NOTE Fsh, 3
	NOTE D_, 3
	REPEAT_END
	REPEAT 2
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	NOTE G_, 3
	REPEAT_END
	REPEAT 2
	NOTE F_, 2
	WAIT
	NOTE F_, 3
	NOTE F_, 3
	REPEAT_END
	NEXT
Pat_612C:
	DRUMS $06, DrumPat_62BA
	HWENV $F1, $06, $83
	ARP 0
	DUTY_75
	LEN 12
	REPEAT 6
	NOTE G_, 2
	NOTE G_, 3
	REPEAT_END
	NOTE G_, 2
	LEN 6
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	NOTE G_, 3
	NEXT
Pat_6144:
	LEN 12
	REST
	ARP 5
	LEN 24
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	ARP 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	LEN 12
	NOTE Ash, 4
	NEXT
Pat_615B:
	LEN 12
	WAIT
	ARP 4
	LEN 24
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE D_, 4
	ARP 5
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	ARP 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE D_, 5
	NOTE D_, 5
	LEN 12
	NOTE D_, 5
	NEXT
Pat_6173:
	LEN 12
	WAIT
	ARP 5
	LEN 24
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE G_, 3
	ARP 4
	NOTE F_, 3
	LEN 12
	NOTE F_, 3
	NEXT
Pat_6182:
	LEN 12
	WAIT
	ARP 4
	LEN 24
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE F_, 5
	NOTE F_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE D_, 5
	ARP 5
	NOTE G_, 5
	NOTE G_, 5
	ARP 4
	NOTE F_, 5
	LEN 12
	NOTE F_, 5
	NEXT
Pat_619A:
	VOLENV 15, $11, $1F, $11
	CH_TRANSPOSE $0C
	WAVE Wave_7D50
	LEN 12
	WAIT
	ARP 5
	LEN 24
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 12
	NOTE G_, 3
	NEXT
Pat_61B1:
	HWENV $F1, $02, $C7
	DUTY_50
	ARP_OFF
	LEN 18
	NOTE Ash, 4
	LEN 12
	NOTE G_, 4
	LEN 6
	WAIT2
	LEN 12
	NOTE D_, 4
	LEN 6
	NOTE G_, 3
	WAIT2
	LEN 12
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	ARP 3
	LEN 18
	NOTE Dsh, 4
	ARP_OFF
	LEN 12
	NOTE Dsh, 4
	LEN 6
	WAIT2
	LEN 18
	NOTE Ash, 4
	LEN 6
	WAIT2
	LEN 12
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	LEN 18
	NOTE A_, 4
	NOTE F_, 4
	LEN 12
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE C_, 4
	ARP 3
	NOTE Csh, 4
	LEN 6
	WAIT2
	ARP_OFF
	NOTE D_, 4
	WAIT2
	NOTE C_, 4
	LEN 24
	NOTE D_, 4
	LEN 12
	NOTE Ash, 3
	NOTE C_, 4
	NOTE D_, 4
	NEXT
Pat_61EE:
	LEN 12
	NOTE Dsh, 4
	LEN 6
	WAIT2
	LEN 12
	NOTE F_, 4
	LEN 6
	WAIT2
	LEN 12
	NOTE G_, 4
	ARP 3
	NOTE F_, 4
	ARP_OFF
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 6
	WAIT2
	LEN 12
	NOTE G_, 4
	LEN 6
	WAIT2
	LEN 24
	NOTE D_, 5
	LEN 12
	NOTE G_, 4
	NOTE Dsh, 5
	NOTE D_, 5
	ARP 3
	NOTE C_, 5
	LEN 6
	WAIT2
	ARP_OFF
	NOTE Csh, 5
	WAIT2
	NOTE A_, 4
	LEN 18
	NOTE E_, 4
	LEN 6
	NOTE A_, 3
	NOTE E_, 4
	NOTE A_, 4
	LEN 12
	NOTE Csh, 5
	NOTE A_, 4
	NOTE C_, 5
	LEN 6
	WAIT2
	LEN 12
	NEXT
Pat_6221:
	PAT_CALL Pat_61EE
	NOTE Ash, 4
	LEN 6
	WAIT2
	NOTE A_, 4
	NOTE Ash, 4
	LEN 12
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NEXT
Pat_622F:
	PAT_CALL Pat_61EE
	NOTE D_, 5
	LEN 6
	WAIT2
	LEN 12
	NOTE Dsh, 5
	NOTE Fsh, 5
	LEN 6
	WAIT2
	LEN 12
	NOTE G_, 5
	LEN 6
	WAIT2
	LEN 12
	NOTE A_, 5
	RELEASE $00
	LENGTH $60
	NOTE G_, 5
	LENGTH $3C
	WAIT2
	ARP 0
	DUTY_75
	HWENV $E2, $05, $70
	RELEASE $01, $A1
	LEN 12
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
Pat_6255:
	LEN 36
	NOTE Ash, 4
	LEN 12
	NOTE G_, 4
	WAIT2
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 36
	NOTE F_, 4
	LEN 12
	NOTE C_, 4
	NOTE F_, 4
	LEN 6
	NOTE G_, 4
	LEN 18
	NOTE F_, 4
	LEN 12
	NOTE C_, 4
	LEN 18
	NOTE D_, 4
	LEN 6
	NOTE A_, 3
	LEN 12
	WAIT2
	NOTE A_, 3
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 18
	NOTE Ash, 4
	NOTE G_, 4
	LEN 12
	NOTE D_, 4
	LEN 6
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE F_, 4
	LEN 36
	NOTE Ash, 4
	LEN 6
	NOTE A_, 4
	NOTE G_, 4
	LEN 12
	WAIT2
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 18
	NOTE F_, 4
	NOTE C_, 4
	LEN 12
	NOTE F_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	LEN 18
	NOTE D_, 5
	NOTE A_, 4
	LEN 12
	NOTE Fsh, 4
	WAIT2
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE D_, 5
	LEN 18
	NOTE C_, 5
	NOTE D_, 5
	LEN 12
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NEXT
Pat_62A7:
	HWENV $F1, $02, $C7
	DUTY_50
	VIBRATO $0C, $01, $04
	RELEASE $01, $72
	LENGTH $30
	NOTE G_, 3
	NOTE Ash, 3
	NOTE D_, 4
	NOTE G_, 4
	NEXT
DrumPat_62BA:
	db DRUM_REPEAT + 7, 1, 0, 6, 0, DRUM_REPEAT_END, 9, 0
	db 9, 9, DRUM_LOOP
DrumPat_62C5:
	db DRUM_REPEAT + 8, 1, 0, 4, 6, 9, 0, 4
	db 6, DRUM_REPEAT_END, DRUM_REPEAT + 7, 1, 0, 4, 6, 9
	db 0, 4, 6, DRUM_REPEAT_END, 1, 0, 4, 6
	db 9, 0, 9, 9, DRUM_LOOP

; Unreferenced (1 bytes)
	db $FF

; Song 8: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong8:
	call StopAll
	ld a, $75
	ld [wInstrTableHi], a
	ld a, $B0
	ld [wInstrTable], a
	ld de, Song8_Ch1
	call StartMusicCh1
	ld de, Song8_Ch2
	call StartMusicCh2
	ld de, Song8_Ch3
	jp StartMusicCh3
Song8_Ch1:
	dw Pat_6346
	dw Pat_639B
	dw Pat_63D8
	dw Pat_63D8
	dw Pat_63EE
	dw Pat_6443
	dw Pat_644E
	dw Pat_648A
	ORDER_LOOP Song8_Ch1
Song8_Ch2:
	dw Pat_64C3
	dw Pat_64C3
	dw Pat_6504
	dw Pat_6514
	dw Pat_654B
	dw Pat_6574
	dw Pat_6574
	dw Pat_65AE
	dw Pat_65DB
	dw Pat_6606
	dw Pat_664A
	ORDER_LOOP Song8_Ch2
Song8_Ch3:
	dw Pat_6681
	dw Pat_6681
	dw Pat_66BA
	dw Pat_6701
	dw Pat_6701
	dw Pat_6732
	dw Pat_6763
	dw Pat_6763
	dw Pat_6763
	ORDER_LOOP Song8_Ch3
Pat_6346:
	VIBRATO $0A, $01, $05
	DRUMS $0A, DrumPat_677D
	REPEAT 2
	INSTR 2
	LEN 20
	NOTE E_, 2
	INSTR 4
	NOTE E_, 4
	LEN 10
	NOTE E_, 4
	INSTR 2
	NOTE E_, 2
	LEN 20
	NOTE A_, 2
	INSTR 3
	NOTE A_, 4
	LEN 10
	NOTE A_, 4
	INSTR 2
	NOTE A_, 2
	LEN 20
	NOTE C_, 2
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 2
	NOTE D_, 2
	INSTR 3
	LEN 20
	NOTE C_, 4
	INSTR 2
	NOTE E_, 2
	INSTR 4
	LEN 10
	NOTE E_, 4
	INSTR 2
	NOTE G_, 2
	INSTR 4
	NOTE E_, 4
	INSTR 2
	NOTE G_, 2
	LEN 20
	NOTE E_, 2
	INSTR 4
	LEN 10
	NOTE E_, 4
	INSTR 2
	NOTE G_, 2
	INSTR 4
	LEN 20
	NOTE E_, 4
	INSTR 2
	NOTE A_, 2
	INSTR 3
	NOTE A_, 4
	LEN 10
	NOTE A_, 4
	INSTR 2
	NOTE A_, 2
	LEN 20
	NOTE C_, 2
	INSTR 3
	LEN 10
	NOTE C_, 4
	INSTR 2
	NOTE D_, 2
	INSTR 3
	LEN 20
	NOTE D_, 4
	INSTR 2
	NOTE E_, 2
	INSTR 4
	NOTE E_, 4
	LEN 10
	NOTE E_, 4
	INSTR 2
	NOTE D_, 2
	REPEAT_END
	NEXT
Pat_639B:
	LEN 20
	REPEAT 3
	NOTE E_, 2
	INSTR 4
	NOTE E_, 4
	NOTE E_, 4
	INSTR 2
	REPEAT_END
	NOTE E_, 2
	INSTR 4
	LEN 10
	NOTE E_, 4
	INSTR 2
	NOTE E_, 2
	NOTE Fsh, 2
	NOTE G_, 2
	INSTR 2
	LEN 40
	NOTE C_, 2
	LEN 10
	NOTE G_, 2
	NOTE E_, 2
	LEN 40
	NOTE C_, 2
	LEN 10
	NOTE E_, 2
	NOTE G_, 2
	LEN 20
	NOTE A_, 2
	NOTE A_, 2
	LEN 10
	NOTE G_, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	LEN 40
	NOTE B_, 2
	LEN 10
	NOTE Fsh, 2
	NOTE A_, 2
	LEN 40
	NOTE B_, 2
	LEN 10
	NOTE A_, 2
	NOTE Fsh, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE Fsh, 2
	NOTE B_, 2
	NOTE A_, 2
	NOTE Fsh, 2
	NOTE B_, 2
	NOTE Fsh, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
Pat_63D8:
	LEN 10
	REPEAT 4
	INSTR 9
	NOTE E_, 2
	WAIT
	INSTR 8
	NOTE E_, 2
	NOTE E_, 2
	WAIT
	NOTE E_, 2
	INSTR 9
	NOTE C_, 3
	WAIT
	INSTR 8
	NOTE C_, 3
	INSTR 9
	NOTE B_, 2
	WAIT
	INSTR 8
	NOTE B_, 2
	REPEAT_END
	NEXT
Pat_63EE:
	INSTR 9
	LEN 20
	NOTE A_, 2
	INSTR 8
	LEN 10
	NOTE A_, 2
	LEN 20
	NOTE A_, 2
	LEN 10
	NOTE A_, 2
	INSTR 9
	LEN 20
	NOTE A_, 2
	INSTR 8
	LEN 10
	NOTE A_, 2
	LEN 20
	NOTE A_, 2
	LEN 10
	NOTE A_, 2
	INSTR 9
	LEN 20
	NOTE G_, 2
	INSTR 8
	LEN 10
	NOTE G_, 2
	LEN 20
	NOTE G_, 2
	LEN 10
	NOTE G_, 2
	INSTR 9
	LEN 20
	NOTE A_, 2
	INSTR 8
	LEN 10
	NOTE A_, 2
	LEN 20
	NOTE A_, 2
	LEN 10
	NOTE A_, 2
	INSTR 9
	LEN 20
	NOTE E_, 2
	INSTR 8
	LEN 10
	NOTE E_, 2
	LEN 20
	NOTE E_, 2
	LEN 10
	NOTE E_, 2
	INSTR 9
	LEN 20
	NOTE C_, 3
	INSTR 8
	LEN 10
	NOTE C_, 3
	INSTR 9
	LEN 20
	NOTE B_, 2
	INSTR 8
	LEN 10
	NOTE B_, 2
	INSTR 9
	LEN 20
	NOTE D_, 2
	INSTR 8
	LEN 10
	NOTE D_, 2
	LEN 20
	NOTE D_, 2
	LEN 10
	NOTE D_, 2
	INSTR 9
	LEN 20
	NOTE C_, 3
	INSTR 8
	LEN 10
	NOTE C_, 3
	INSTR 9
	LEN 20
	NOTE A_, 2
	INSTR 8
	LEN 10
	NOTE A_, 2
	NEXT
Pat_6443:
	INSTR 9
	LENGTH $78
	NOTE E_, 2
	NOTE B_, 2
	NOTE A_, 2
	LENGTH $3C
	NOTE C_, 2
	NOTE D_, 2
	NEXT
Pat_644E:
	INSTR 9
	LEN 20
	NOTE E_, 2
	INSTR 3
	NOTE E_, 4
	LEN 10
	NOTE E_, 4
	INSTR 9
	NOTE B_, 2
	LEN 20
	NOTE E_, 2
	INSTR 3
	NOTE E_, 4
	NOTE E_, 4
	INSTR 9
	NOTE B_, 2
	INSTR 4
	NOTE B_, 4
	LEN 10
	NOTE B_, 4
	INSTR 9
	NOTE Fsh, 2
	LEN 20
	NOTE B_, 2
	INSTR 4
	NOTE B_, 4
	NOTE B_, 4
	INSTR 9
	NOTE A_, 2
	INSTR 3
	NOTE A_, 4
	LEN 10
	NOTE A_, 4
	INSTR 9
	NOTE E_, 2
	LEN 20
	NOTE A_, 2
	INSTR 3
	NOTE A_, 4
	LEN 10
	NOTE A_, 4
	INSTR 9
	NOTE B_, 2
	LEN 20
	NOTE C_, 3
	INSTR 3
	NOTE C_, 4
	LEN 10
	NOTE C_, 4
	INSTR 9
	NOTE C_, 3
	LEN 20
	NOTE D_, 3
	INSTR 3
	NOTE D_, 4
	LEN 10
	NOTE D_, 4
	INSTR 9
	NOTE D_, 3
	NEXT
Pat_648A:
	REPEAT 2
	INSTR 9
	NOTE E_, 2
	WAIT
	INSTR 3
	NOTE E_, 4
	INSTR 9
	NOTE B_, 2
	WAIT
	INSTR 3
	NOTE E_, 4
	REPEAT_END
	REPEAT 2
	INSTR 9
	NOTE B_, 2
	WAIT
	INSTR 4
	NOTE B_, 4
	INSTR 9
	NOTE Fsh, 2
	WAIT
	INSTR 4
	NOTE B_, 4
	REPEAT_END
	REPEAT 2
	INSTR 9
	NOTE A_, 2
	WAIT
	INSTR 3
	NOTE A_, 4
	INSTR 9
	NOTE E_, 2
	WAIT
	INSTR 3
	NOTE A_, 4
	REPEAT_END
	INSTR 9
	NOTE C_, 3
	WAIT
	INSTR 3
	NOTE C_, 5
	INSTR 9
	NOTE G_, 2
	WAIT
	INSTR 3
	NOTE C_, 5
	INSTR 9
	NOTE D_, 3
	WAIT
	INSTR 3
	NOTE D_, 5
	INSTR 9
	NOTE A_, 2
	WAIT
	INSTR 3
	NOTE D_, 5
	NEXT
Pat_64C3:
	LEN 10
	VIBRATO $0F, $01, $05
	HWENV $D1, $05, $82
	DUTY_50
	LEN 10
	NOTE E_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	LEN 20
	NOTE D_, 6
	LEN 10
	NOTE B_, 5
	LEN 20
	NOTE Csh, 6
	LEN 10
	NOTE E_, 4
	NOTE E_, 4
	NOTE A_, 5
	NOTE B_, 5
	LEN 20
	NOTE C_, 6
	NOTE C_, 6
	LEN 10
	NOTE B_, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE E_, 5
	NOTE B_, 4
	LEN 20
	NOTE D_, 5
	LEN 10
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	LEN 20
	NOTE D_, 5
	LEN 10
	NOTE B_, 4
	LEN 20
	NOTE Csh, 5
	LEN 10
	NOTE A_, 4
	NOTE E_, 4
	NOTE B_, 4
	NOTE A_, 4
	LEN 20
	NOTE C_, 5
	NOTE C_, 5
	LEN 10
	NOTE E_, 5
	NOTE Fsh, 5
	NOTE E_, 5
	NOTE B_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE B_, 3
	NOTE G_, 3
	NEXT
Pat_6504:
	LENGTH $64
	NOTE E_, 5
	LEN 10
	NOTE D_, 5
	NOTE B_, 4
	LENGTH $46
	NOTE A_, 4
	LEN 10
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NEXT
Pat_6514:
	HWENV $79, $05, $A0
	RELEASE $02, $62
	ARP 3
	LEN 40
	NOTE F_, 5
	ARP_OFF
	LEN 10
	NOTE Fsh, 5
	NOTE F_, 5
	LEN 40
	NOTE E_, 5
	LEN 10
	NOTE D_, 5
	NOTE Dsh, 5
	LEN 20
	NOTE E_, 5
	LEN 40
	NOTE E_, 5
	ARP 3
	LEN 10
	NOTE D_, 5
	ARP_OFF
	NOTE D_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	LENGTH $3C
	NOTE B_, 4
	ARP 3
	LEN 40
	NOTE Csh, 5
	ARP_OFF
	LEN 10
	NOTE Fsh, 5
	NOTE A_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE B_, 5
	NOTE A_, 5
	NOTE B_, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE Fsh, 5
	NEXT
Pat_654B:
	LENGTH $3C
	NOTE E_, 5
	WAIT2
	RELEASE $00
	HWENV $D1, $05, $82
	LEN 30
	NOTE E_, 3
	NOTE B_, 3
	NOTE A_, 3
	NOTE D_, 4
	LEN 10
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE Fsh, 3
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE D_, 4
	NEXT
Pat_6574:
	HWENV $F3, $00
	RELEASE $02, $62
	DUTY_75
	LEN 30
	NOTE B_, 4
	LEN 10
	WAIT2
	NOTE A_, 4
	WAIT2
	LEN 30
	NOTE G_, 4
	LEN 10
	WAIT2
	NOTE A_, 4
	WAIT2
	LEN 30
	NOTE Fsh, 4
	LEN 10
	WAIT2
	NOTE G_, 4
	WAIT2
	LEN 20
	NOTE A_, 4
	LEN 10
	WAIT2
	LEN 20
	NOTE Fsh, 4
	LEN 10
	WAIT2
	LEN 30
	NOTE B_, 4
	LEN 10
	WAIT2
	NOTE A_, 4
	WAIT2
	LEN 30
	NOTE G_, 4
	LEN 10
	WAIT2
	NOTE A_, 4
	WAIT2
	LEN 20
	NOTE Fsh, 4
	LEN 10
	NOTE D_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	LENGTH $32
	NOTE E_, 4
	LEN 10
	WAIT2
	NEXT
Pat_65AE:
	LEN 30
	NOTE A_, 4
	LEN 10
	WAIT2
	NOTE B_, 4
	WAIT2
	LEN 30
	NOTE C_, 5
	LEN 10
	WAIT2
	NOTE E_, 5
	WAIT2
	NOTE D_, 5
	WAIT2
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	LEN 20
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	LEN 30
	NOTE B_, 4
	LEN 10
	WAIT2
	NOTE A_, 4
	WAIT2
	LEN 30
	NOTE G_, 4
	LEN 10
	WAIT2
	NOTE A_, 4
	WAIT2
	NOTE D_, 5
	NOTE A_, 4
	NOTE D_, 5
	NOTE E_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	LEN 20
	NOTE E_, 5
	NOTE D_, 5
	NOTE A_, 4
	NEXT
Pat_65DB:
	HWENV $89, $05, $C0
	ARP_OFF
	LENGTH $3C
	NOTE E_, 4
	LEN 20
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE Gsh, 4
	ARP 3
	LENGTH $3C
	NOTE A_, 4
	ARP_OFF
	LEN 20
	NOTE Csh, 5
	NOTE D_, 5
	NOTE Csh, 5
	ARP 3
	LEN 10
	NOTE C_, 5
	ARP_OFF
	NOTE Csh, 5
	LEN 40
	NOTE A_, 4
	LEN 20
	NOTE E_, 4
	NOTE A_, 4
	NOTE Csh, 5
	NOTE C_, 5
	NOTE E_, 4
	NOTE G_, 4
	LEN 10
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE D_, 5
	NOTE Fsh, 5
	NEXT
Pat_6606:
	HWENV $D1, $05, $82
	RELEASE $00
	LEN 20
	NOTE Gsh, 5
	LEN 10
	NOTE E_, 4
	LEN 20
	NOTE Gsh, 5
	LEN 10
	NOTE E_, 4
	LEN 20
	NOTE A_, 5
	LEN 10
	NOTE E_, 4
	LEN 20
	NOTE Gsh, 5
	LEN 10
	NOTE E_, 4
	LEN 20
	NOTE Fsh, 5
	LEN 10
	NOTE D_, 4
	LEN 20
	NOTE Fsh, 5
	LEN 10
	NOTE D_, 4
	LEN 20
	NOTE G_, 5
	LEN 10
	NOTE D_, 4
	LEN 20
	NOTE Fsh, 5
	LEN 10
	NOTE D_, 4
	LEN 20
	NOTE E_, 5
	LEN 10
	NOTE Csh, 4
	LEN 20
	NOTE E_, 5
	LEN 10
	NOTE Csh, 4
	LEN 20
	NOTE Fsh, 5
	LEN 10
	NOTE Csh, 4
	NOTE E_, 5
	NOTE Csh, 5
	NOTE Csh, 5
	LEN 20
	NOTE E_, 5
	LEN 10
	NOTE C_, 5
	NOTE E_, 4
	NOTE E_, 5
	NOTE G_, 5
	LEN 20
	NOTE Fsh, 5
	LEN 10
	NOTE D_, 5
	NOTE Fsh, 4
	NOTE Fsh, 5
	NOTE A_, 5
	NEXT
Pat_664A:
	LEN 10
	NOTE Gsh, 5
	NOTE E_, 5
	NOTE E_, 4
	NOTE Gsh, 5
	NOTE E_, 5
	NOTE E_, 4
	LEN 20
	NOTE A_, 5
	LEN 10
	NOTE E_, 4
	LEN 20
	NOTE Gsh, 5
	LEN 10
	NOTE E_, 4
	NOTE Fsh, 5
	NOTE D_, 5
	NOTE D_, 4
	NOTE Fsh, 5
	NOTE D_, 5
	NOTE D_, 4
	LEN 20
	NOTE G_, 5
	LEN 10
	NOTE D_, 4
	NOTE Fsh, 5
	NOTE D_, 5
	NOTE D_, 4
	NOTE E_, 5
	NOTE Csh, 5
	NOTE Csh, 4
	NOTE E_, 5
	NOTE Csh, 5
	NOTE Csh, 4
	LEN 20
	NOTE Fsh, 5
	LEN 10
	NOTE Csh, 4
	NOTE E_, 5
	NOTE Csh, 5
	NOTE Csh, 5
	LEN 20
	NOTE E_, 5
	LEN 10
	NOTE C_, 5
	NOTE E_, 4
	NOTE E_, 5
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE Fsh, 4
	NOTE D_, 5
	NOTE A_, 4
	NEXT
Pat_6681:
	VOLENV 13, $00, $1F, $12
	LEN 10
	WAVE Wave_7CC0
	NOTE E_, 4
	NOTE B_, 3
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE Csh, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE B_, 3
	NOTE E_, 3
	NOTE D_, 4
	NOTE B_, 3
	NOTE D_, 4
	NOTE E_, 3
	NOTE B_, 2
	NOTE E_, 3
	NOTE B_, 3
	NOTE E_, 3
	NOTE B_, 3
	NOTE A_, 3
	NOTE E_, 3
	NOTE Csh, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE E_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE E_, 4
	NOTE G_, 4
	NOTE B_, 4
	NEXT
Pat_66BA:
	REPEAT 2
	NOTE E_, 3
	NOTE B_, 3
	NOTE B_, 3
	NOTE E_, 3
	NOTE C_, 4
	NOTE C_, 4
	NOTE E_, 3
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE E_, 3
	NOTE D_, 4
	NOTE E_, 4
	REPEAT_END
	REPEAT 2
	NOTE C_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE E_, 4
	REPEAT_END
	REPEAT 2
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE A_, 3
	NOTE C_, 4
	REPEAT_END
	REPEAT 2
	NOTE B_, 3
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Fsh, 4
	NOTE B_, 3
	NOTE Dsh, 4
	REPEAT_END
	NOTE B_, 3
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 30
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 10
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE D_, 5
	NEXT
Pat_6701:
	NOTE G_, 4
	NOTE B_, 4
	NOTE B_, 3
	NOTE B_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE Fsh, 3
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE Fsh, 3
	NOTE G_, 4
	NOTE B_, 4
	NOTE B_, 3
	NOTE B_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE Fsh, 3
	NOTE Fsh, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE B_, 3
	NOTE E_, 4
	NOTE E_, 3
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NEXT
Pat_6732:
	NOTE C_, 5
	NOTE A_, 4
	NOTE A_, 3
	NOTE A_, 4
	NOTE D_, 5
	NOTE B_, 4
	NOTE E_, 5
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE E_, 5
	NOTE D_, 4
	NOTE D_, 5
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 5
	NOTE B_, 3
	NOTE B_, 4
	NOTE A_, 3
	NOTE A_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE B_, 3
	NOTE B_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE B_, 4
	NOTE E_, 5
	NOTE E_, 4
	NOTE B_, 4
	NEXT
Pat_6763:
	REPEAT 4
	NOTE E_, 5
	NOTE B_, 4
	NOTE Gsh, 4
	REPEAT_END
	REPEAT 4
	NOTE D_, 5
	NOTE B_, 4
	NOTE Fsh, 4
	REPEAT_END
	REPEAT 4
	NOTE Csh, 5
	NOTE A_, 4
	NOTE E_, 4
	REPEAT_END
	REPEAT 2
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	REPEAT_END
	REPEAT 2
	NOTE D_, 5
	NOTE A_, 4
	NOTE Fsh, 4
	REPEAT_END
	NEXT
DrumPat_677D:
	db DRUM_LEVEL + 13, DRUM_REPEAT + 3, 1, 0, 6, 9, 0, 6
	db 1, 0, 6, 9, 0, 10, DRUM_REPEAT_END, 1
	db 0, 6, 9, 0, 6, 1, 0, DRUM_TEMPO + 5
	db 10, 10, DRUM_TEMPO + 10, 9, 0, 10, DRUM_LOOP

; Song 9: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong9:
	call StopAll
	ld a, $75
	ld [wInstrTableHi], a
	ld a, $B0
	ld [wInstrTable], a
	ld de, Song9_Ch1
	call StartMusicCh1
	ld de, Song9_Ch3
	call StartMusicCh3
	ld de, Song9_Ch2
	jp StartMusicCh2

; Unreferenced (1 bytes)
	db $C9
Song9_Ch1:
	dw Pat_6804
	dw Pat_681F
	dw Pat_6827
	dw Pat_6827
	dw Pat_6838
	dw Pat_6838
	dw Pat_6849
	dw Pat_6876
	dw Pat_6849
	dw Pat_6876
	ORDER_LOOP Song9_Ch1
Song9_Ch3:
	dw Pat_68A2
	dw Pat_68BF
	dw Pat_68D2
	dw Pat_68D2
	dw Pat_68E5
	dw Pat_68E5
	dw Pat_68F8
	dw Pat_690D
	dw Pat_68F8
	dw Pat_690D
	ORDER_LOOP Song9_Ch3
Song9_Ch2:
	dw Pat_6922
	dw Pat_6956
	dw Pat_698A
	dw Pat_698A
	dw Pat_69A2
	dw Pat_69A2
	dw Pat_69BE
	dw Pat_69E4
	dw Pat_69BC
	dw Pat_69E4
	ORDER_LOOP Song9_Ch2
Pat_6804:
	DRUMS $07, DrumPat_6A04
Pat_6808:
	HWENV $F1, $00
	ARP 0
	AUTODUTY $0E
	REPEAT 4
	LEN 14
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	LEN 7
	NOTE C_, 3
	NOTE C_, 3
	LEN 14
	NOTE C_, 2
	LEN 7
	NOTE C_, 3
	NOTE C_, 3
	REPEAT_END
	NEXT
Pat_681F:
	CH_TRANSPOSE $03
	PAT_CALL Pat_6808
	CH_TRANSPOSE $00
	NEXT
Pat_6827:
	REPEAT 2
	LEN 14
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	REPEAT_END
	NEXT
Pat_6838:
	REPEAT 2
	LEN 14
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	LEN 7
	NOTE C_, 3
	NOTE C_, 3
	LEN 14
	NOTE C_, 2
	LEN 7
	NOTE C_, 3
	NOTE C_, 3
	REPEAT_END
	NEXT
Pat_6849:
	LEN 14
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	LEN 7
	NOTE C_, 3
	NOTE C_, 3
	LEN 14
	NOTE C_, 2
	LEN 7
	NOTE C_, 3
	NOTE C_, 3
	LEN 14
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE D_, 2
	LEN 7
	NOTE D_, 3
	NOTE D_, 3
	LEN 14
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 3
	NOTE Dsh, 3
	REPEAT 2
	LEN 14
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	REPEAT_END
	NEXT
Pat_6876:
	REPEAT 2
	LEN 14
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	NOTE F_, 3
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 3
	NOTE F_, 3
	REPEAT_END
	LEN 14
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 2
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	LEN 14
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	LEN 7
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 2
	NOTE F_, 2
	NOTE Dsh, 2
	NOTE D_, 2
	NEXT
Pat_68A2:
	LEN 14
	VOLENV 15, $11, $1F, $11
	CH_TRANSPOSE $0C
	WAVE Wave_7D10
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 0
	NOTE G_, 3
	ARP 15
	NOTE C_, 3
	ARP 0
	NOTE Gsh, 3
	ARP 15
	NOTE C_, 3
	ARP 0
	NOTE G_, 3
	ARP 15
	NOTE C_, 3
	ARP 0
	NOTE C_, 4
	REPEAT_END
	NEXT
Pat_68BF:
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 0
	NOTE Ash, 3
	ARP 15
	NOTE C_, 3
	ARP 0
	NOTE B_, 3
	ARP 15
	NOTE C_, 3
	ARP 0
	NOTE B_, 3
	ARP 15
	NOTE C_, 3
	ARP 0
	NOTE Dsh, 4
	REPEAT_END
	NEXT
Pat_68D2:
	REPEAT 2
	ARP 15
	NOTE C_, 3
	ARP 0
	NOTE D_, 4
	ARP 15
	NOTE C_, 3
	ARP 0
	NOTE Dsh, 4
	ARP 15
	NOTE C_, 3
	ARP 0
	NOTE D_, 4
	ARP 15
	NOTE C_, 3
	ARP 0
	NOTE G_, 4
	REPEAT_END
	NEXT
Pat_68E5:
	REPEAT 2
	ARP 15
	NOTE C_, 3
	ARP 0
	NOTE G_, 3
	ARP 15
	NOTE C_, 3
	ARP 0
	NOTE Gsh, 3
	ARP 15
	NOTE C_, 3
	ARP 0
	NOTE G_, 3
	ARP 15
	NOTE C_, 3
	ARP 0
	NOTE C_, 4
	REPEAT_END
	NEXT
Pat_68F8:
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 5
	NOTE C_, 4
	ARP 15
	NOTE C_, 3
	ARP 5
	NOTE C_, 4
	REPEAT_END
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 4
	NOTE G_, 4
	ARP 15
	NOTE C_, 3
	ARP 4
	NOTE G_, 4
	REPEAT_END
	NEXT
Pat_690D:
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 5
	NOTE F_, 4
	ARP 15
	NOTE C_, 3
	ARP 5
	NOTE F_, 4
	REPEAT_END
	REPEAT 4
	ARP 15
	NOTE C_, 3
	ARP 4
	NOTE G_, 4
	ARP 15
	NOTE C_, 3
	ARP 4
	NOTE G_, 4
	REPEAT_END
	NEXT
Pat_6922:
	HWENV $A0, $00
	DUTY_50
	VIBRATO $07, $01, $06
	LEN 28
	NOTE C_, 4
	NOTE G_, 3
	NOTE F_, 3
	LEN 14
	NOTE G_, 3
	NOTE Gsh, 3
	LEN 28
	NOTE G_, 3
	LEN 14
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE G_, 3
	HWENV $F1, $00
	DUTY_12
	ARP 5
	NOTE C_, 4
	ARP 4
	NOTE Csh, 4
	ARP 5
	LEN 28
	NOTE C_, 4
	LEN 14
	NOTE C_, 4
	NOTE F_, 4
	LEN 28
	NOTE C_, 4
	LEN 14
	NOTE C_, 4
	ARP 4
	NOTE Csh, 4
	ARP 5
	LEN 28
	NOTE C_, 4
	NOTE C_, 4
	LEN 14
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NEXT
Pat_6956:
	HWENV $A0, $00
	DUTY_50
	ARP_OFF
	LEN 28
	NOTE Dsh, 4
	NOTE Ash, 3
	LEN 14
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE B_, 3
	NOTE Gsh, 3
	LEN 28
	NOTE Ash, 3
	LEN 14
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE Ash, 3
	HWENV $F1, $00
	DUTY_12
	ARP 5
	NOTE Dsh, 4
	ARP 4
	NOTE E_, 4
	ARP 5
	LEN 28
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	NOTE Gsh, 4
	LEN 28
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	ARP 4
	NOTE E_, 4
	ARP 5
	LEN 28
	NOTE Dsh, 4
	NOTE Dsh, 4
	ARP 4
	LEN 14
	NOTE E_, 4
	ARP 5
	NOTE Dsh, 4
	NOTE Dsh, 4
	NEXT
Pat_698A:
	HWENV $D1, $07, $72
	DUTY_12
	ARP 8
	LEN 14
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE G_, 3
	NOTE D_, 4
	NOTE C_, 5
	NOTE D_, 5
	NEXT
Pat_69A2:
	DRUMS $07, DrumPat_6A16
	ARP 8
	DUTY_75
	LEN 14
	NOTE C_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE C_, 4
	NOTE G_, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE C_, 4
	NOTE G_, 4
	NOTE Dsh, 5
	NOTE G_, 5
	DUTY_50
	ARP_OFF
	NEXT
Pat_69BC:
	DUTY_75
	ARP 9
Pat_69BE:
	HWENV $C0, $07, $82
	LEN 14
	NOTE G_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE B_, 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE B_, 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE B_, 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NEXT
Pat_69E4:
	LEN 14
	NOTE F_, 4
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE Gsh, 3
	REPEAT 2
	NOTE G_, 3
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	REPEAT_END
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 3
	NOTE B_, 3
	NEXT
DrumPat_6A04:
	db DRUM_LEVEL + 14, 1, 0, 6, 0, 9, 0, 4
	db 6, 1, 0, 6, 0, 9, 0, 6
	db 0, DRUM_LOOP
DrumPat_6A16:
	db DRUM_LEVEL + 14, 1, 6, 4, 0, 9, 6, 4
	db 0, 1, 6, 4, 0, 9, 6, 6
	db 6, DRUM_LOOP

; Song 10: instrument table - (none set), arpeggio table 1 (the one SndInit sets)
PlaySong10:
	call StopAll
	ld de, Song10_Ch1
	call StartMusicCh1
	ld de, Song10_Ch3
	call StartMusicCh3
	ld de, Song10_Ch2
	jp StartMusicCh2
Song10_Ch1:
	dw Pat_6A79
Loop_6A3F:
	dw Pat_6AAE
	dw Pat_6AAE
	dw Pat_6ADD
	dw Pat_6B03
	dw Pat_6B03
	dw Pat_6B07
	dw Pat_6B22
	ORDER_LOOP Loop_6A3F
Song10_Ch3:
	dw Pat_6B44
Loop_6A53:
	dw Pat_6B72
	dw Pat_6B72
	dw Pat_6B87
	dw Pat_6B9C
	dw Pat_6B9C
	dw Pat_6BA9
	dw Pat_6BB6
	ORDER_LOOP Loop_6A53
Song10_Ch2:
	dw Pat_6BC6
Loop_6A67:
	dw Pat_6BF6
	dw Pat_6BF6
	dw Pat_6C2E
	dw Pat_6C6B
	dw Pat_6C6B
	dw Pat_6CA0
	dw Pat_6CD9
	ORDER_LOOP Loop_6A67
Pat_6A79:
	HWENV $F2, $00
	RELEASE $02, $81
	DUTY_50
	ARP 0
	DRUMS $0A, DrumPat_6D27
	LEN 20
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	LEN 10
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	LEN 5
	NOTE F_, 2
	NOTE F_, 2
	LEN 10
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	DRUMS $05, DrumPat_6D27
	LEN 5
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NEXT
Pat_6AAE:
	DRUMS $0A, DrumPat_6D18
	LEN 10
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	LEN 5
	NOTE F_, 2
	NOTE F_, 2
	LEN 10
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	LEN 5
	NOTE F_, 2
	NOTE F_, 2
	LEN 10
	NOTE F_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	LEN 5
	NOTE F_, 2
	NOTE F_, 2
	LEN 10
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE Gsh, 2
	NOTE Gsh, 3
	NOTE Ash, 2
	NOTE C_, 3
	NEXT
Pat_6ADD:
	LEN 10
	REPEAT 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE Ash, 2
	LEN 5
	NOTE Ash, 2
	NOTE Ash, 2
	LEN 10
	NOTE Ash, 3
	NOTE Ash, 2
	NOTE Ash, 3
	REPEAT_END
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	LEN 5
	NOTE C_, 2
	NOTE C_, 2
	LEN 10
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	DRUMS $05, DrumPat_6D1E
	LEN 15
	NOTE C_, 2
	NOTE Csh, 2
	NOTE D_, 2
	NOTE Dsh, 2
	LEN 10
	NOTE E_, 2
	NOTE C_, 2
	NEXT
Pat_6B03:
	DRUMS $0A, DrumPat_6D18
Pat_6B07:
	REPEAT 2
	NOTE Csh, 2
	NOTE Csh, 2
	NOTE Csh, 3
	LEN 5
	NOTE Csh, 2
	NOTE C_, 2
	LEN 10
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE Gsh, 2
	NOTE Csh, 3
	REPEAT_END
	REPEAT 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 3
	LEN 5
	NOTE Ash, 2
	NOTE Gsh, 2
	LEN 10
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE Gsh, 2
	NOTE Gsh, 3
	REPEAT_END
	NEXT
Pat_6B22:
	LEN 10
	REPEAT 2
	NOTE Csh, 2
	NOTE Csh, 2
	NOTE Csh, 3
	LEN 5
	NOTE Csh, 2
	NOTE C_, 2
	LEN 10
	NOTE Csh, 2
	NOTE Csh, 3
	NOTE Gsh, 2
	NOTE Csh, 3
	REPEAT_END
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 3
	LEN 5
	NOTE Dsh, 2
	NOTE Ash, 2
	LEN 10
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 3
	NOTE E_, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE G_, 2
	NOTE C_, 2
	NEXT
Pat_6B44:
	VOLENV 10, $11, $1F, $11
	ARP 0
	WAVE Wave_7D30
	CH_TRANSPOSE $0C
	LEN 5
	REPEAT 2
	NOTE C_, 5
	NOTE F_, 4
	NOTE Gsh, 5
	NOTE F_, 4
	NOTE C_, 5
	NOTE G_, 5
	NOTE F_, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE F_, 4
	NOTE C_, 5
	NOTE G_, 5
	NOTE F_, 4
	NOTE C_, 5
	NOTE Gsh, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE F_, 4
	NOTE Gsh, 5
	NOTE F_, 4
	NOTE C_, 5
	NOTE G_, 5
	NOTE F_, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE F_, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE F_, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	REPEAT_END
	NEXT
Pat_6B72:
	VOLENV 13, $00, $1F, $12
	CH_TRANSPOSE $00
	WAVE Wave_7CD0
	LEN 10
	REST
	ARP 5
	LEN 20
	REPEAT 7
	NOTE F_, 4
	NOTE F_, 4
	REPEAT_END
	NOTE F_, 4
	LEN 10
	NOTE F_, 4
	NEXT
Pat_6B87:
	WAIT
	ARP 5
	LEN 20
	REPEAT 8
	NOTE Ash, 4
	REPEAT_END
	ARP 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	LEN 10
	NOTE C_, 5
	LEN 15
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	LEN 10
	NOTE Csh, 5
	NOTE C_, 5
	NEXT
Pat_6B9C:
	WAIT
	ARP 4
	LEN 20
	REPEAT 8
	NOTE Csh, 4
	REPEAT_END
	ARP 5
	REPEAT 7
	NOTE Ash, 3
	REPEAT_END
	LEN 10
	NOTE Ash, 3
	NEXT
Pat_6BA9:
	WAIT
	ARP 4
	LEN 20
	REPEAT 8
	NOTE Csh, 5
	REPEAT_END
	ARP 5
	REPEAT 7
	NOTE Ash, 4
	REPEAT_END
	LEN 10
	NOTE Ash, 4
	NEXT
Pat_6BB6:
	WAIT
	ARP 4
	LEN 20
	REPEAT 8
	NOTE Csh, 5
	REPEAT_END
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	LEN 10
	NOTE C_, 5
	NEXT
Pat_6BC6:
	HWENV $C0, $00
	RELEASE $01, $A1
	DUTY_50
	VIBRATO $0A, $02, $05
	ARP_OFF
	LEN 20
	NOTE F_, 3
	NOTE C_, 3
	NOTE C_, 4
	NOTE F_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	LEN 10
	NOTE F_, 3
	NOTE C_, 3
	NOTE C_, 4
	NOTE F_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	LEN 5
	NOTE F_, 3
	NOTE C_, 3
	NOTE C_, 4
	NOTE F_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NEXT
Pat_6BF6:
	LEN 10
	NOTE F_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE C_, 4
	ARP 3
	NOTE Fsh, 4
	ARP_OFF
	NOTE G_, 4
	NOTE Dsh, 4
	LEN 20
	NOTE C_, 4
	LEN 5
	NOTE F_, 4
	WAIT2
	LEN 10
	NOTE C_, 4
	LEN 5
	NOTE Dsh, 4
	WAIT2
	LEN 10
	NOTE Ash, 3
	LEN 5
	NOTE C_, 4
	WAIT2
	LEN 10
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE C_, 4
	ARP 3
	NOTE Fsh, 4
	ARP_OFF
	NOTE G_, 4
	NOTE Dsh, 4
	LEN 20
	NOTE C_, 5
	LEN 5
	NOTE C_, 5
	WAIT2
	LEN 10
	NOTE Ash, 4
	LEN 5
	NOTE C_, 5
	WAIT2
	LEN 10
	NOTE Gsh, 4
	LEN 5
	NOTE C_, 5
	WAIT2
	LEN 10
	NOTE G_, 4
	NOTE C_, 5
	NEXT
Pat_6C2E:
	LEN 25
	NOTE F_, 4
	LEN 5
	WAIT2
	LEN 10
	NOTE G_, 4
	ARP 3
	NOTE Fsh, 4
	ARP_OFF
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE F_, 4
	LEN 5
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Ash, 3
	NOTE Gsh, 3
	LEN 10
	NOTE G_, 4
	ARP 3
	NOTE Fsh, 4
	ARP_OFF
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE Ash, 3
	LEN 5
	NOTE C_, 4
	NOTE Csh, 4
	LEN 35
	NOTE C_, 4
	LEN 5
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Ash, 3
	ARP 3
	LEN 10
	NOTE Ash, 4
	LEN 5
	REST
	ARP_OFF
	LEN 10
	NOTE Ash, 4
	LEN 5
	REST
	LEN 10
	NOTE Gsh, 4
	LEN 5
	REST
	LEN 10
	NOTE G_, 4
	LEN 5
	REST
	LEN 10
	NOTE F_, 4
	NOTE E_, 4
	NEXT
Pat_6C6B:
	LEN 5
	REPEAT 2
	NOTE F_, 4
	LEN 10
	WAIT2
	LEN 5
	NOTE G_, 4
	LEN 10
	WAIT2
	NOTE Gsh, 4
	WAIT2
	LEN 5
	NOTE Ash, 4
	WAIT2
	NOTE Gsh, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	REPEAT_END
	NOTE Csh, 4
	LEN 10
	WAIT2
	LEN 5
	NOTE C_, 4
	LEN 10
	WAIT2
	NOTE Ash, 3
	WAIT2
	LEN 5
	NOTE Csh, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE Ash, 3
	WAIT2
	NOTE F_, 4
	WAIT2
	NOTE Ash, 3
	NOTE Dsh, 4
	WAIT2
	NOTE Ash, 3
	NOTE Csh, 4
	WAIT2
	LEN 10
	NOTE F_, 4
	LEN 5
	NOTE Csh, 4
	WAIT2
	NOTE Dsh, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NEXT
Pat_6CA0:
	HWENV $D1, $00
	RELEASE $00
	LEN 5
	REPEAT 2
	NOTE F_, 4
	NOTE F_, 5
	NOTE F_, 6
	NOTE G_, 4
	NOTE G_, 5
	NOTE G_, 6
	NOTE Gsh, 4
	NOTE Gsh, 5
	NOTE Gsh, 6
	NOTE Gsh, 5
	NOTE Ash, 4
	NOTE Ash, 5
	NOTE Gsh, 4
	NOTE Gsh, 5
	NOTE G_, 4
	NOTE G_, 5
	REPEAT_END
	NOTE Csh, 4
	NOTE Csh, 5
	NOTE Csh, 6
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 6
	NOTE Ash, 3
	NOTE Ash, 4
	NOTE Ash, 5
	NOTE Ash, 4
	NOTE Csh, 4
	NOTE Csh, 5
	NOTE C_, 4
	NOTE C_, 5
	NOTE Ash, 3
	NOTE Ash, 4
	NOTE F_, 4
	NOTE F_, 5
	NOTE F_, 6
	NOTE Dsh, 4
	NOTE Dsh, 5
	NOTE Dsh, 6
	NOTE Csh, 4
	NOTE Csh, 5
	NOTE Csh, 6
	NOTE Csh, 5
	NOTE F_, 4
	NOTE F_, 5
	NOTE Dsh, 4
	NOTE Dsh, 5
	NOTE G_, 4
	NOTE G_, 5
	NEXT
Pat_6CD9:
	REPEAT 2
	NOTE F_, 4
	NOTE F_, 5
	NOTE F_, 6
	NOTE G_, 4
	NOTE G_, 5
	NOTE G_, 6
	NOTE Gsh, 4
	NOTE Gsh, 5
	NOTE Gsh, 6
	NOTE Gsh, 5
	NOTE Ash, 4
	NOTE Ash, 5
	NOTE Gsh, 4
	NOTE Gsh, 5
	NOTE G_, 4
	NOTE G_, 5
	REPEAT_END
	HWENV $C0, $00
	RELEASE $01, $A1
	LEN 10
	NOTE Dsh, 4
	LEN 5
	WAIT2
	LEN 10
	NOTE G_, 4
	LEN 5
	WAIT2
	LEN 20
	NOTE Ash, 4
	LEN 5
	NOTE Dsh, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	ARP 3
	LEN 10
	NOTE Ash, 4
	LEN 5
	WAIT2
	ARP_OFF
	LEN 10
	NOTE G_, 4
	LEN 5
	WAIT2
	LEN 10
	NOTE E_, 4
	LEN 15
	NOTE C_, 4
	LEN 5
	WAIT2
	ARP 3
	LEN 10
	NOTE Dsh, 4
	ARP_OFF
	NOTE E_, 4
	NEXT
DrumPat_6D18:
	db DRUM_LEVEL + 13, 1, 6, 2, 6, DRUM_LOOP
DrumPat_6D1E:
	db DRUM_LEVEL + 13, DRUM_TEMPO + 15, 2, 2, 2, 2, DRUM_TEMPO + 10, 2
	db 2
DrumPat_6D27:
	db DRUM_LEVEL + 13, 1, 6, DRUM_LOOP

; Song 11: instrument table - (none set), arpeggio table 1 (the one SndInit sets)
PlaySong11:
	call StopAll
	ld de, Song11_Ch1
	call StartMusicCh1
	ld de, Song11_Ch2
	call StartMusicCh2
	ld de, Song11_Ch3
	jp StartMusicCh3
Song11_Ch1:
	dw Pat_6D46
Song11_Ch2:
	dw Pat_6D81
Song11_Ch3:
	dw Pat_6DB5
Pat_6D46:
	TRANSPOSE $FE
	ARP 0
	HWENV $F2, $09, $83
	DUTY_75
	LEN 9
	REPEAT 4
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	REPEAT_END
	REPEAT 2
	NOTE Dsh, 2
	WAIT
	NOTE Dsh, 3
	REPEAT_END
	REPEAT 2
	NOTE D_, 2
	WAIT
	NOTE D_, 3
	REPEAT_END
	REPEAT 4
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	REPEAT_END
	REPEAT 2
	NOTE Dsh, 2
	WAIT
	NOTE Dsh, 3
	REPEAT_END
	REPEAT 2
	NOTE D_, 2
	WAIT
	NOTE D_, 3
	REPEAT_END
	REPEAT 2
	LEN 18
	NOTE G_, 2
	NOTE G_, 3
	LEN 9
	NOTE G_, 2
	NOTE G_, 2
	REPEAT_END
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 2
	NOTE G_, 2
	LEN 9
	NOTE G_, 2
	NOTE G_, 2
	LENGTH $36
	NOTE G_, 2
	END
Pat_6D81:
	HWENV $C2, $09, $64
	DUTY_75
	ARP 5
	LEN 27
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	ARP 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE D_, 4
	ARP 5
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	ARP 4
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE D_, 5
	ARP 5
	LEN 18
	NOTE G_, 4
	NOTE G_, 4
	LEN 9
	NOTE G_, 4
	NOTE G_, 4
	LEN 18
	NOTE G_, 4
	NOTE G_, 4
	LEN 9
	NOTE G_, 4
	NOTE G_, 4
	LEN 18
	NOTE G_, 5
	LEN 9
	NOTE G_, 5
	NOTE G_, 5
	ARP 5
	LEN 9
	NOTE G_, 5
	NOTE G_, 5
	LENGTH $36
	NOTE G_, 5
	END
Pat_6DB5:
	VOLENV 14, $11, $1F, $18
	VIBRATO $12, $01, $06
	RELEASE $01, $A2
	ARP 0
	WAVE Wave_7D60
	LEN 45
	NOTE G_, 4
	LEN 9
	WAIT2
	LEN 18
	NOTE A_, 4
	LEN 9
	WAIT2
	LEN 18
	NOTE Ash, 4
	LEN 9
	WAIT2
	LEN 45
	NOTE Dsh, 4
	LEN 9
	WAIT2
	LEN 45
	NOTE D_, 4
	LEN 9
	WAIT2
	LEN 45
	NOTE G_, 4
	LEN 9
	WAIT2
	LEN 18
	NOTE A_, 4
	LEN 9
	WAIT2
	LEN 18
	NOTE Ash, 4
	LEN 9
	WAIT2
	LEN 36
	NOTE Dsh, 5
	LEN 9
	NOTE F_, 5
	NOTE Dsh, 5
	LEN 27
	NOTE D_, 5
	LEN 9
	WAIT2
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 27
	NOTE D_, 4
	LEN 9
	WAIT2
	NOTE D_, 4
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE D_, 4
	LEN 36
	NOTE G_, 3
	LEN 45
	WAIT
	LEN 27
	WAIT2
	END

; Song 12: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong12:
	call StopAll
	ld a, $75
	ld [wInstrTableHi], a
	ld a, $B0
	ld [wInstrTable], a
	ld de, Song12_Ch1
	call StartMusicCh1
	ld de, Song12_Ch3
	call StartMusicCh3
	ld de, Song12_Ch2
	jp StartMusicCh2
Song12_Ch1:
	dw Pat_6E45
	dw Pat_6E82
	dw Pat_6EBF
	dw Pat_6EBF
	ORDER_LOOP Song12_Ch1
Song12_Ch3:
	dw Pat_6EF6
	dw Pat_6EF6
	dw Pat_6F1A
	dw Pat_6F1A
	ORDER_LOOP Song12_Ch3
Song12_Ch2:
	dw Pat_6F42
	dw Pat_6F77
	dw Pat_6F99
	dw Pat_6F99
	ORDER_LOOP Song12_Ch2
Pat_6E45:
	DRUMS $12, DrumPat_6FC4
	INSTR 2
	LEN 36
	NOTE C_, 2
	INSTR 3
	LEN 18
	NOTE C_, 4
	INSTR 2
	LEN 36
	NOTE C_, 2
	INSTR 3
	LEN 18
	NOTE C_, 4
	INSTR 2
	NOTE E_, 2
	NOTE G_, 2
	LEN 36
	NOTE D_, 2
	INSTR 3
	LEN 18
	NOTE D_, 4
	INSTR 2
	LEN 36
	NOTE D_, 2
	INSTR 3
	LEN 18
	NOTE D_, 4
	INSTR 2
	NOTE G_, 2
	NOTE Fsh, 2
	LEN 36
	NOTE C_, 2
	INSTR 3
	LEN 18
	NOTE C_, 4
	INSTR 2
	LEN 36
	NOTE C_, 2
	INSTR 3
	LEN 18
	NOTE C_, 4
	INSTR 2
	NOTE E_, 2
	NOTE G_, 2
	LEN 36
	NOTE D_, 2
	INSTR 3
	LEN 18
	NOTE D_, 4
	INSTR 2
	NOTE D_, 2
	NOTE A_, 2
	INSTR 3
	NOTE D_, 4
	INSTR 2
	NOTE G_, 2
	NOTE Fsh, 2
	NEXT
Pat_6E82:
	INSTR 2
	LEN 36
	NOTE C_, 2
	INSTR 3
	LEN 18
	NOTE C_, 4
	INSTR 2
	LEN 36
	NOTE C_, 2
	INSTR 3
	LEN 18
	NOTE C_, 4
	INSTR 2
	NOTE E_, 2
	NOTE G_, 2
	LEN 36
	NOTE D_, 2
	INSTR 3
	LEN 18
	NOTE D_, 4
	INSTR 2
	LEN 36
	NOTE D_, 2
	INSTR 3
	LEN 18
	NOTE D_, 4
	INSTR 2
	NOTE G_, 2
	NOTE Fsh, 2
	LEN 27
	NOTE C_, 2
	LEN 9
	NOTE C_, 2
	INSTR 3
	LEN 18
	NOTE C_, 4
	INSTR 2
	NOTE C_, 2
	NOTE E_, 2
	INSTR 3
	NOTE C_, 4
	INSTR 2
	LEN 36
	NOTE G_, 2
	LEN 27
	NOTE D_, 2
	LEN 9
	NOTE D_, 2
	INSTR 3
	LEN 18
	NOTE D_, 4
	INSTR 2
	LEN 36
	NOTE D_, 3
	INSTR 3
	LEN 18
	NOTE D_, 4
	INSTR 2
	NOTE A_, 2
	NOTE D_, 2
	NEXT
Pat_6EBF:
	INSTR 2
	LEN 36
	NOTE G_, 2
	INSTR 3
	LEN 18
	NOTE G_, 4
	INSTR 2
	LEN 36
	NOTE G_, 2
	INSTR 3
	NOTE G_, 4
	INSTR 2
	LEN 18
	NOTE D_, 2
	LEN 36
	NOTE G_, 2
	INSTR 3
	LEN 18
	NOTE G_, 4
	INSTR 2
	LEN 36
	NOTE G_, 2
	INSTR 3
	LEN 18
	NOTE G_, 4
	INSTR 2
	LEN 36
	NOTE F_, 2
	NOTE G_, 2
	INSTR 3
	LEN 18
	NOTE F_, 4
	INSTR 2
	LEN 36
	NOTE G_, 2
	INSTR 3
	NOTE F_, 4
	INSTR 2
	LEN 18
	NOTE D_, 2
	LEN 36
	NOTE G_, 2
	INSTR 3
	LEN 18
	NOTE F_, 4
	INSTR 2
	LEN 36
	NOTE F_, 2
	INSTR 3
	LEN 18
	NOTE F_, 4
	INSTR 2
	NOTE E_, 2
	NOTE D_, 2
	NEXT
Pat_6EF6:
	VOLENV 12, $0B, $1F, $11
	ARP 0
	CH_TRANSPOSE $0C
	WAVE Wave_7D70
	LEN 18
	REPEAT 4
	NOTE G_, 4
	NOTE C_, 4
	REPEAT_END
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	REPEAT 4
	NOTE G_, 4
	NOTE C_, 4
	REPEAT_END
	NOTE B_, 4
	NOTE D_, 4
	NOTE B_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE D_, 4
	NEXT
Pat_6F1A:
	LEN 18
	NOTE G_, 3
	NOTE D_, 4
	NOTE D_, 5
	NOTE G_, 3
	NOTE D_, 4
	NOTE C_, 5
	NOTE G_, 3
	NOTE D_, 4
	NOTE B_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE A_, 4
	LEN 9
	NOTE G_, 3
	NOTE D_, 4
	LEN 36
	NOTE C_, 5
	LEN 18
	NOTE B_, 4
	NOTE F_, 3
	NOTE C_, 4
	NOTE C_, 5
	NOTE F_, 3
	NOTE C_, 4
	NOTE B_, 4
	NOTE F_, 3
	NOTE C_, 4
	NOTE A_, 4
	NOTE F_, 3
	NOTE C_, 4
	NOTE G_, 4
	LEN 9
	NOTE F_, 3
	NOTE C_, 4
	LEN 36
	NOTE A_, 4
	LEN 18
	NOTE G_, 4
	NEXT
Pat_6F42:
	HWENV $F2, $12, $70
	DUTY_50
	VIBRATO $12, $01, $06
	RELEASE $A1, $74
	LEN 18
	REST
	LEN 9
	NOTE D_, 4
	NOTE D_, 4
	LEN 18
	NOTE D_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE E_, 4
	LEN 27
	NOTE E_, 4
	NOTE D_, 4
	LEN 36
	NOTE E_, 4
	LENGTH $36
	NOTE D_, 4
	LEN 18
	WAIT2
	LEN 9
	NOTE D_, 4
	NOTE D_, 4
	LEN 18
	NOTE D_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE B_, 4
	LEN 27
	NOTE B_, 4
	NOTE D_, 5
	LENGTH $51
	NOTE A_, 4
	LEN 9
	WAIT2
	NEXT
Pat_6F77:
	LEN 18
	WAIT
	LEN 9
	NOTE D_, 4
	NOTE D_, 4
	LEN 18
	NOTE D_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE E_, 4
	LEN 27
	NOTE E_, 4
	NOTE D_, 4
	LEN 36
	NOTE E_, 4
	NOTE G_, 4
	LENGTH $36
	NOTE A_, 4
	LEN 36
	NOTE B_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE E_, 4
	LEN 18
	NOTE D_, 4
	LEN 36
	NOTE E_, 4
	NOTE D_, 4
	LEN 18
	NOTE G_, 3
	NEXT
Pat_6F99:
	LEN 36
	WAIT
	ARP 6
	NOTE D_, 4
	LEN 18
	WAIT2
	LEN 36
	NOTE C_, 4
	LEN 18
	WAIT2
	LEN 36
	NOTE B_, 3
	LEN 18
	WAIT2
	LEN 36
	NOTE A_, 3
	LEN 18
	NOTE C_, 4
	WAIT2
	LEN 36
	NOTE B_, 3
	LEN 18
	WAIT2
	LEN 36
	NOTE C_, 4
	LEN 18
	WAIT2
	LEN 36
	NOTE B_, 3
	LEN 18
	WAIT2
	LEN 36
	NOTE A_, 3
	LEN 18
	WAIT2
	LEN 36
	NOTE G_, 3
	LEN 18
	NOTE A_, 3
	WAIT2
	NOTE G_, 3
	ARP_OFF
	NEXT
DrumPat_6FC4:
	db DRUM_LEVEL + 13, 1, DRUM_TEMPO + 9, 6, 1, DRUM_TEMPO + 18, 9, 1
	db 1, 6, 9, 6, 1, 6, 9, 1
	db 1, 6, 9, 6, 1, DRUM_TEMPO + 9, 6, 1
	db DRUM_TEMPO + 18, 9, 1, 1, 6, 9, 6, 1
	db 6, 9, 1, 1, 9, 9, 6, DRUM_LOOP

; Song 13: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong13:
	call StopAll
	ld a, $75
	ld [wInstrTableHi], a
	ld a, $B0
	ld [wInstrTable], a
	ld de, Song13_Ch1
	call StartMusicCh1
	ld de, Song13_Ch2
	call StartMusicCh2
	ld de, Song13_Ch3
	jp StartMusicCh3
Song13_Ch1:
	dw Pat_703B
	dw Pat_7074
	dw Pat_70AF
	dw Pat_7111
	dw Pat_70E2
	dw Pat_7140
	ORDER_LOOP Song13_Ch1
Song13_Ch2:
	dw Pat_7175
	dw Pat_71AB
	dw Pat_71D9
	dw Pat_7244
	dw Pat_7213
	dw Pat_727C
	ORDER_LOOP Song13_Ch2
Song13_Ch3:
	dw Pat_72A4
	dw Pat_72CE
	dw Pat_72F3
	dw Pat_730E
	dw Pat_72A4
	dw Pat_72A4
	ORDER_LOOP Song13_Ch3
Pat_703B:
	INSTR 2
	DRUMS $07, DrumPat_7326
	REPEAT 4
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	REPEAT_END
	LEN 14
	NOTE F_, 2
	NOTE Dsh, 2
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	REPEAT 3
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	REPEAT_END
	LEN 14
	NOTE F_, 2
	NOTE Dsh, 2
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE Dsh, 2
	LEN 14
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 2
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Ash, 2
	LEN 7
	NOTE Ash, 2
	REPEAT 3
	LEN 14
	NOTE Ash, 2
	LEN 7
	NOTE Ash, 2
	REPEAT_END
	LEN 14
	NOTE Ash, 2
	NOTE Gsh, 2
	NEXT
Pat_7074:
	REPEAT 4
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	REPEAT_END
	LEN 14
	NOTE F_, 2
	NOTE Dsh, 2
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	REPEAT 3
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	REPEAT_END
	LEN 14
	NOTE F_, 2
	NOTE Dsh, 2
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE Dsh, 2
	LEN 14
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 2
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Ash, 2
	LEN 7
	NOTE Ash, 2
	LEN 14
	NOTE Ash, 2
	LEN 7
	NOTE Ash, 2
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	NEXT
Pat_70AF:
	DRUMS $07, DrumPat_7338
	REPEAT 4
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	REPEAT_END
	LEN 14
	NOTE F_, 2
	NOTE F_, 2
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 2
	REPEAT 3
	LEN 14
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 2
	REPEAT_END
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Gsh, 2
	LEN 7
	NOTE Gsh, 2
	REPEAT 3
	LEN 14
	NOTE Gsh, 2
	LEN 7
	NOTE Gsh, 2
	REPEAT_END
	LEN 14
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Ash, 2
	LEN 7
	NOTE Ash, 2
	REPEAT 3
	LEN 14
	NOTE Ash, 2
	LEN 7
	NOTE Ash, 2
	REPEAT_END
	NOTE Ash, 2
	NOTE Gsh, 2
	NOTE G_, 2
	NOTE Gsh, 2
	NEXT
Pat_70E2:
	REPEAT 4
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	REPEAT_END
	LEN 14
	NOTE F_, 2
	NOTE Dsh, 2
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	REPEAT 3
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	REPEAT_END
	LEN 14
	NOTE F_, 2
	NOTE Dsh, 2
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	REPEAT 3
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	REPEAT_END
	LEN 14
	NOTE F_, 2
	NOTE Dsh, 2
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	REPEAT 3
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	REPEAT_END
	NOTE Gsh, 2
	NOTE F_, 2
	NOTE Gsh, 2
	NOTE Ash, 2
	NEXT
Pat_7111:
	REPEAT 4
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	REPEAT_END
	LEN 14
	NOTE F_, 2
	NOTE F_, 2
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 2
	REPEAT 3
	LEN 14
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 2
	REPEAT_END
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Gsh, 2
	LEN 7
	NOTE Gsh, 2
	REPEAT 3
	LEN 14
	NOTE Gsh, 2
	LEN 7
	NOTE Gsh, 2
	REPEAT_END
	LEN 14
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Ash, 2
	LEN 7
	NOTE Ash, 2
	REPEAT 3
	LEN 14
	NOTE Ash, 2
	LEN 7
	NOTE Ash, 2
	REPEAT_END
	NOTE Ash, 2
	NOTE Gsh, 2
	NOTE G_, 2
	NOTE Gsh, 2
	NEXT
Pat_7140:
	REPEAT 4
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	REPEAT_END
	LEN 14
	NOTE F_, 2
	NOTE Dsh, 2
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	REPEAT 3
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	REPEAT_END
	LEN 14
	NOTE F_, 2
	NOTE Dsh, 2
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	REPEAT 3
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	REPEAT_END
	LEN 14
	NOTE F_, 2
	NOTE Dsh, 2
	NOTE Ash, 2
	LEN 7
	NOTE Ash, 2
	LEN 14
	NOTE Ash, 2
	LEN 7
	NOTE Ash, 2
	LEN 14
	NOTE Ash, 2
	LEN 7
	NOTE C_, 3
	LEN 14
	NOTE C_, 3
	LEN 7
	NOTE C_, 3
	NOTE Dsh, 3
	NOTE C_, 3
	NOTE Dsh, 3
	NOTE F_, 3
	NEXT
Pat_7175:
	HWENV $D2, $0E, $67
	VIBRATO $0E, $01, $06
	DUTY_75
	ARP 4
	LEN 21
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 42
	NOTE Gsh, 4
	LEN 14
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 21
	NOTE Gsh, 4
	ARP 5
	NOTE G_, 4
	LEN 35
	NOTE G_, 4
	ARP 15
	LEN 7
	NOTE C_, 4
	LEN 28
	NOTE Gsh, 3
	ARP 5
	LEN 21
	NOTE F_, 4
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	ARP 4
	LEN 21
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	ARP 5
	LEN 21
	NOTE C_, 4
	NOTE C_, 4
	ARP 4
	LEN 28
	NOTE Ash, 3
	ARP 15
	LEN 14
	NOTE C_, 4
	NOTE Ash, 3
	NOTE Gsh, 3
	NEXT
Pat_71AB:
	ARP 4
	LEN 21
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 42
	NOTE Gsh, 4
	LEN 14
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 21
	NOTE Gsh, 4
	ARP 5
	NOTE G_, 4
	LEN 35
	NOTE G_, 4
	ARP 15
	LEN 7
	NOTE C_, 4
	LEN 28
	NOTE Gsh, 3
	ARP 5
	LEN 21
	NOTE F_, 4
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	ARP 4
	LEN 21
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	ARP 5
	LEN 21
	NOTE G_, 4
	NOTE G_, 4
	LEN 28
	NOTE F_, 4
	ARP 15
	LEN 14
	NOTE C_, 4
	NOTE Ash, 3
	LEN 7
	NOTE Gsh, 3
	NOTE Gsh, 3
	NEXT
Pat_71D9:
	DUTY_50
	HWENV $D0, $00
	RELEASE $01, $C1
	ARP 3
	LEN 14
	NOTE Dsh, 5
	LEN 7
	WAIT2
	ARP_OFF
	LEN 14
	NOTE C_, 5
	LEN 7
	WAIT2
	LEN 14
	NOTE Gsh, 4
	LEN 42
	NOTE F_, 4
	LEN 14
	NOTE Gsh, 4
	LEN 7
	NOTE G_, 4
	WAIT2
	NOTE Gsh, 4
	NOTE G_, 4
	WAIT2
	LEN 21
	NOTE Dsh, 4
	LEN 35
	NOTE Ash, 3
	LEN 7
	WAIT2
	NOTE F_, 4
	NOTE G_, 4
	LEN 21
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 14
	NOTE F_, 4
	LEN 21
	NOTE C_, 5
	NOTE Gsh, 4
	LEN 14
	NOTE C_, 5
	NOTE Ash, 4
	LEN 7
	WAIT2
	LEN 14
	NOTE D_, 5
	LEN 7
	WAIT2
	LENGTH $46
	NOTE F_, 5
	NEXT
Pat_7213:
	ARP 6
	HWENV $D2, $0E, $60
	RELEASE $00
	DRUMS $07, DrumPat_7326
	LEN 21
	NOTE F_, 4
	NOTE G_, 4
	LEN 14
	NOTE Gsh, 4
	LEN 28
	NOTE Dsh, 5
	LEN 14
	NOTE C_, 5
	NOTE Dsh, 5
	LEN 21
	NOTE D_, 5
	NOTE Ash, 4
	LEN 14
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE C_, 5
	LEN 21
	NOTE Gsh, 4
	NOTE F_, 4
	LEN 28
	NOTE C_, 5
	LEN 14
	NOTE F_, 4
	NOTE F_, 5
	NOTE Dsh, 5
	LEN 21
	NOTE D_, 5
	NOTE Dsh, 5
	LEN 14
	NOTE F_, 5
	LEN 42
	NOTE Ash, 4
	LEN 14
	WAIT2
	NEXT
Pat_7244:
	ARP 3
	LEN 14
	NOTE Dsh, 5
	LEN 7
	WAIT2
	ARP_OFF
	LEN 14
	NOTE C_, 5
	LEN 7
	WAIT2
	LEN 14
	NOTE Gsh, 4
	LEN 35
	NOTE F_, 4
	LEN 7
	WAIT2
	LEN 14
	NOTE Gsh, 4
	LEN 7
	NOTE G_, 4
	WAIT2
	NOTE Gsh, 4
	NOTE G_, 4
	WAIT2
	LEN 21
	NOTE Dsh, 4
	LEN 42
	NOTE Ash, 3
	LEN 7
	NOTE F_, 4
	NOTE G_, 4
	LEN 21
	NOTE Gsh, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	WAIT2
	NOTE F_, 4
	WAIT2
	LEN 21
	NOTE C_, 5
	NOTE Gsh, 4
	LEN 7
	NOTE C_, 5
	WAIT2
	LEN 21
	NOTE Ash, 4
	LEN 14
	NOTE C_, 5
	LEN 7
	WAIT2
	LEN 28
	NOTE Ash, 4
	LEN 42
	NOTE F_, 4
	NEXT
Pat_727C:
	LEN 21
	NOTE F_, 4
	NOTE G_, 4
	LEN 14
	NOTE Gsh, 4
	LEN 28
	NOTE Dsh, 5
	LEN 14
	NOTE C_, 5
	NOTE Dsh, 5
	LEN 21
	NOTE D_, 5
	NOTE Ash, 4
	LEN 14
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE C_, 5
	LEN 21
	NOTE Gsh, 4
	NOTE F_, 4
	LEN 28
	NOTE C_, 5
	LEN 14
	NOTE F_, 4
	NOTE F_, 5
	NOTE Dsh, 5
	LEN 21
	NOTE D_, 5
	NOTE Dsh, 5
	LEN 14
	NOTE F_, 5
	NOTE Gsh, 5
	NOTE G_, 5
	LEN 7
	NOTE Gsh, 5
	LEN 21
	NOTE Ash, 5
	NEXT
Pat_72A4:
	VOLENV 12, $10, $1A, $12
	ARP 6
	WAVE Wave_7CC0
	LEN 14
	NOTE C_, 5
	NOTE C_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE Ash, 3
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE C_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE C_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE Ash, 3
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE Ash, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE Ash, 3
	NEXT
Pat_72CE:
	LEN 14
	NOTE C_, 5
	NOTE C_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE Ash, 3
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE C_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE C_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE Ash, 3
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE Ash, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE C_, 4
	LEN 7
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NEXT
Pat_72F3:
	VOLENV 12, $11, $1F, $12
	LEN 14
	WAIT
	ARP 5
	LEN 28
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	ARP 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	LEN 14
	NOTE Ash, 4
	NEXT
Pat_730E:
	LEN 14
	WAIT
	ARP 5
	LEN 28
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	ARP 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Ash, 4
	LEN 14
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NEXT
DrumPat_7326:
	db DRUM_LEVEL + 13, 1, 0, 6, 6, 1, 6, 6
	db 0, 1, 6, 0, 6, 1, 0, 6
	db 0, DRUM_LOOP
DrumPat_7338:
	db DRUM_LEVEL + 13, 1, 0, 4, 6, 2, 6, 4
	db 0, 1, 6, 4, 6, 2, 0, 4
	db 0, DRUM_LOOP

; Song 1: instrument table - (none set), arpeggio table 1 (the one SndInit sets)
PlaySong1:
	call StopAll
	ld de, Song1_Ch1
	call StartMusicCh1
	ld de, Song1_Ch3
	call StartMusicCh3
	ld de, Song1_Ch2
	jp StartMusicCh2
Song1_Ch1:
	dw Pat_738D
	dw Pat_73B2
	dw Pat_738D
	dw Pat_73B2
	dw Pat_73C6
	dw Pat_73DF
	ORDER_LOOP Song1_Ch1
Song1_Ch3:
	dw Pat_73ED
	dw Pat_742A
	dw Pat_73ED
	dw Pat_744D
	dw Pat_7472
	dw Pat_74BD
	ORDER_LOOP Song1_Ch3
Song1_Ch2:
	dw Pat_74DE
	dw Pat_7532
	dw Pat_74DE
	dw Pat_7532
	dw Pat_754B
	ORDER_LOOP Song1_Ch2
Pat_738D:
	DRUMS $08, DrumPat_75A3
	HWENV $F2, $00
	ARP 0
	VIBRATO $08, $01, $05
	LEN 24
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	NEXT
Pat_73B2:
	LEN 16
	WAIT
	LEN 24
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN 16
	NOTE G_, 2
	LEN 8
	NOTE D_, 2
	LEN 16
	NOTE G_, 2
	LEN 8
	NOTE D_, 2
	NEXT
Pat_73C6:
	LEN 24
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE G_, 2
	LEN 8
	NOTE G_, 2
	NEXT
Pat_73DF:
	LEN 16
	WAIT
	LEN 24
	NOTE C_, 3
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 3
	NEXT
Pat_73ED:
	WAVE Wave_7D50
	CH_TRANSPOSE $0C
	VOLENV 15, $10, $1F, $12
	ARP 4
	LEN 8
	NOTE G_, 3
	ARP 0
	REPEAT 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE G_, 4
	REPEAT_END
	REPEAT 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE G_, 4
	REPEAT_END
	NOTE C_, 4
	NOTE G_, 3
	ARP 4
	NOTE Ash, 3
	ARP 0
	REPEAT 4
	NOTE D_, 4
	NOTE F_, 3
	NOTE F_, 4
	REPEAT_END
	REPEAT 3
	NOTE C_, 4
	NOTE F_, 3
	NOTE F_, 4
	REPEAT_END
	NOTE C_, 4
	NOTE F_, 3
	ARP 4
	NOTE Dsh, 4
	ARP 0
	NOTE Ash, 3
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE Dsh, 3
	ARP 4
	NOTE F_, 4
	ARP 0
	NOTE C_, 4
	NOTE F_, 3
	NOTE F_, 4
	NEXT
Pat_742A:
	NOTE C_, 4
	NOTE F_, 3
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 3
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 3
	ARP 4
	NOTE G_, 4
	ARP 0
	NOTE D_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 3
	NEXT
Pat_744D:
	ARP 0
	LEN 8
	NOTE C_, 4
	NOTE F_, 3
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 3
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 3
	ARP 4
	NOTE G_, 4
	ARP 0
	NOTE D_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE G_, 5
	NOTE B_, 5
	NEXT
Pat_7472:
	VOLENV 15, $00, $00, $00
	CH_TRANSPOSE $0C
	WAVE Wave_7D60
	LEN 8
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 3
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 3
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 3
	NOTE F_, 4
	NOTE D_, 4
	NOTE Ash, 3
	NOTE F_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE F_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE F_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE F_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE Dsh, 3
	NOTE Dsh, 4
	NEXT
Pat_74BD:
	LEN 8
	NOTE Ash, 3
	NOTE Dsh, 3
	NOTE Dsh, 4
	NOTE Ash, 3
	NOTE Dsh, 3
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE D_, 4
	LEN 32
	NOTE G_, 3
	LEN 8
	NOTE A_, 3
	NOTE B_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE A_, 3
	NEXT
Pat_74DE:
	HWENV $E0, $00
	VIBRATO $10, $01, $04
	DUTY_50
	ARP 0
	RELEASE $01, $A2
	LEN 16
	NOTE G_, 3
	LEN 8
	WAIT2
	LEN 16
	NOTE D_, 4
	LEN 8
	WAIT2
	LEN 16
	NOTE G_, 4
	LEN 8
	WAIT2
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	WAIT2
	LEN 32
	NOTE C_, 4
	LEN 8
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE E_, 3
	LEN 16
	REST
	LEN 8
	WAIT2
	LEN 16
	NOTE F_, 4
	LEN 8
	WAIT2
	LEN 16
	NOTE D_, 5
	LEN 8
	WAIT2
	NOTE D_, 5
	NOTE C_, 5
	NOTE Ash, 4
	LENGTH $30
	NOTE C_, 5
	LEN 8
	NOTE F_, 5
	NOTE C_, 5
	NOTE F_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 4
	LEN 16
	NOTE Ash, 3
	LEN 8
	WAIT2
	LEN 16
	NOTE Dsh, 4
	LEN 8
	WAIT2
	LEN 16
	NOTE Ash, 4
	LEN 8
	WAIT2
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE C_, 5
	WAIT2
	LENGTH $38
	NOTE A_, 4
	NEXT
Pat_7532:
	LEN 8
	WAIT2
	NOTE C_, 5
	NOTE C_, 5
	LENGTH $48
	NOTE D_, 5
	LEN 8
	WAIT2
	HWENV $F3, $00
	RELEASE $00
	ARP 4
	NOTE F_, 4
	NOTE F_, 4
	LENGTH $30
	NOTE G_, 4
	LEN 24
	NOTE G_, 4
	NOTE G_, 4
	ARP 0
	NEXT
Pat_754B:
	HWENV $E0, $00
	ARP 0
	RELEASE $01, $A2
	LEN 24
	NOTE E_, 5
	LEN 8
	WAIT2
	NOTE E_, 5
	NOTE E_, 5
	NOTE Fsh, 5
	WAIT2
	NOTE G_, 5
	WAIT2
	NOTE A_, 5
	WAIT2
	LEN 16
	NOTE G_, 5
	LENGTH $48
	NOTE D_, 5
	LEN 8
	WAIT2
	LEN 24
	NOTE D_, 5
	LEN 8
	WAIT2
	NOTE D_, 5
	NOTE D_, 5
	NOTE E_, 5
	WAIT2
	NOTE F_, 5
	WAIT2
	NOTE G_, 5
	WAIT2
	LEN 32
	NOTE G_, 5
	LEN 8
	NOTE F_, 5
	NOTE E_, 5
	LEN 40
	NOTE F_, 5
	LEN 8
	WAIT2
	LEN 24
	NOTE C_, 5
	LEN 8
	WAIT2
	NOTE C_, 5
	NOTE C_, 5
	LEN 24
	NOTE D_, 5
	LEN 8
	WAIT2
	NOTE C_, 5
	NOTE D_, 5
	LEN 24
	NOTE Dsh, 5
	LEN 24
	NOTE Ash, 4
	LEN 16
	WAIT2
	LEN 8
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE C_, 5
	LENGTH $58
	NOTE D_, 5
	LEN 8
	WAIT2
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE D_, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE D_, 4
	NEXT
DrumPat_75A3:
	db DRUM_REPEAT + 3, 6, 0, 6, 9, 6, 6, DRUM_REPEAT_END
	db 6, 6, 6, 9, 6, 6, DRUM_LOOP

; Instrument table 1, entries 1..10 (the song routines point 2 bytes before:
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
Instr1_1:
	VOLENV 10, $10, $1F, $11
	END
Instr1_0:
	VOLENV 15, $10, $1F, $11
	END
Instr1_2:
	HWENV $F2, $04, $75
	DUTY_50
	ARP 0
	END
Instr1_3:
	HWENV $D2, $04, $82
	DUTY_75
	ARP 4
	END
Instr1_4:
	HWENV $D2, $04, $82
	DUTY_75
	ARP 5
	END
Instr1_5:
	HWENV $D0, $0E, $D5
	DUTY_75
	ARP 0
	END
Instr1_6:
	VOLENV 15, $11, $1F, $11
	GLIDE $FE
	END
Instr1_7:
	HWENV $F2, $00
	ARP 1
	END
Instr1_8:
	HWENV $B1, $00
	ARP 0
	END
Instr1_9:
	HWENV $F2, $0A, $60
	ARP 0
	END
ArpTable:
	dw Arp0
	dw Arp1
	dw Arp1
	dw Arp3
	dw Arp4
	dw Arp5
	dw Arp6
	dw Arp7
	dw Arp7
	dw Arp9
	dw Arp10
	dw Arp10
	dw Arp12
	dw Arp12
	dw Arp12
	dw Arp12

; Unreferenced (24 bytes)
	db $8F, $76, $8F, $76, $8F, $76, $8F, $76, $8F, $76, $8F, $76, $8F, $76, $8F, $76
	db $8F, $76, $8F, $76, $8F, $76, $8F, $76
Arp0:
	db $0C, $00, ARP_HOLD
Arp3:
	db $00, $00, $01, $01, $02, ARP_HOLD
Arp1:
	db $0C, $07, $07, $00, ARP_HOLD
Arp4:
	db $00, $00, $04, $04, $07, $07, ARP_LOOP
Arp5:
	db $00, $00, $03, $03, $07, $07, ARP_LOOP
Arp6:
	db $0C, $0C, $00, $00, $00, $00, $00, $00
	db $00, ARP_LOOP
Arp7:
	db $0C, $00, $00, $00, $00, $00, $00, $18
	db $0C, $0C, $0C, $0C, $0C, $0C, $0C, ARP_HOLD
Arp9:
	db $0C, $0C, $00, ARP_HOLD
Arp10:
	db $0C, $00, $00, $00, $00, $00, $00, $0C
	db $0C, $0C, $0C, $0C, $0C, $0C, ARP_HOLD
Arp12:
	db $08, $05, $03, $00, $FE, $FC, $FA, $F8
	db $F6, $F4, ARP_HOLD

; Unreferenced (29 bytes)
	db $AB, $76, $AB, $76, $AB, $76, $AB, $76, $AB, $76, $AB, $76, $AB, $76, $AB, $76
	db $AB, $76, $AB, $76, $AB, $76, $AB, $76, $AB, $76, $AB
SfxTable_m2:
	db $76, $68

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
	VOLENV 15, $11, $23, $11
	LEN 5
	ARP 11
	WAVE Wave_7CD0
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

; Sound effect 2
Sfx02:
	VOLENV 15, $11, $1F, $12
	WAVE Wave_7CB0
	ARP 0
	GLIDE $02
	LEN 15
	NOTE A_, 2
	END

; Sound effect 3
Sfx03:
	VOLENV 15, $11, $1F, $11
	WAVE Wave_7CB0
	ARP 0
	GLIDE $04
	LEN 10
	NOTE A_, 3
	END

; Sound effect 4
Sfx04:
	WAVE Wave_7CB0
	CALL_CODE Code_7988
	VOLENV 10, $00, $00, $00
	LEN 4
	NOTE D_, 3
	NOTE F_, 2
	END

; Sound effect 7
Sfx07:
	VOLENV 15, $11, $1F, $13
	WAVE Wave_7D10
	CALL_CODE Code_7B27
	LEN 4
	NOTE C_, 3
	CALL_CODE Code_7A98
	LEN 1
	REST
	LEN 10
	GLIDE $FE
	NOTE Dsh, 5
	END

; Sound effect 8
Sfx08:
	VOLENV 15, $11, $1F, $12
	WAVE Wave_7CD0
	CALL_CODE Code_794C
	LEN 10
	GLIDE $FF
	NOTE C_, 4
	END

; Sound effect 12
Sfx12:
	LEN 5
	VOLENV 15, $00, $00, $00
	WAVE Wave_7CF0
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	VOLENV 10, $00, $00, $00
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	VOLENV 5, $00, $00, $00
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	END

; Sound effect 13
Sfx13:
	VOLENV 12, $11, $1F, $13
	WAVE Wave_7CB0
	LEN 4
	NOTE C_, 5
	LEN 25
	NOTE C_, 6
	VIBRATO $05, $01, $04
	END

; Sound effect 14
Sfx14:
	VOLENV 15, $00, $00, $00
	WAVE Wave_7D00
	LEN 10
	GLIDE $02
	NOTE A_, 2
	END

; Sound effect 15
Sfx15:
	VOLENV 15, $00, $00, $00
	LEN 4
	WAVE Wave_7CE0
	REPEAT 4
	NOTE A_, 5
	REST
	REPEAT_END
	END

; Sound effect 17
Sfx17:
	CALL_CODE Code_7A27
	VOLENV 15, $11, $1F, $15
	WAVE Wave_7CB0
	LEN 9
	GLIDE $FC
	NOTE A_, 4
	END

; Sound effect 16
Sfx16:
	CALL_CODE Code_7C4A
	VOLENV 15, $11, $1F, $15
	WAVE Wave_7CB0
	LEN 9
	GLIDE $FD
	NOTE A_, 3
	END

; Sound effect 18
Sfx18:
	WAVE Wave_7CD0
	CALL_CODE Code_7AE1
	VOLENV 15, $11, $1F, $12
	LEN 8
	GLIDE $FF
	NOTE A_, 4
	LEN 5
	VOLENV 10, $11, $1F, $12
	NOTE A_, 4
	END

; Sound effect 20
Sfx20:
	WAVE Wave_7CE0
	CALL_CODE Code_7C0A
	GLIDE $04
	LEN 10
	VOLENV 15, $00, $00, $00
	NOTE A_, 3
	VOLENV 10, $00, $00, $00
	NOTE A_, 3
	VOLENV 5, $00, $00, $00
	NOTE A_, 3
	END

; Sound effect 21
Sfx21:
	VOLENV 15, $11, $1F, $12
	ARP 0
	WAVE Wave_7CB0
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

; Sound effect 28
Sfx28:
	CALL_CODE Code_7BDB
	END

; Sound effect 10
Sfx10:
	VOLENV 15, $11, $2F, $11
	WAVE Wave_7CC0
	LEN 13
	NOTE C_, 6
	END

; Sound effect 9
Sfx09:
	LEN 4
	VOLENV 15, $11, $2F, $11
	WAVE Wave_7CC0
	LEN 4
	NOTE Gsh, 5
	LEN 1
	REST
	LEN 4
	NOTE Gsh, 6
	END

; Sound effect 27
Sfx27:
	VOLENV 15, $11, $1F, $11
	CALL_CODE Code_7B27
	WAVE Wave_7CB0
	LEN 12
	GLIDE $FE
	NOTE C_, 3
	END

; Sound effect 30
Sfx30:
	CALL_CODE Code_7B81
	END

; Sound effect 26
Sfx26:
	LEN 5
	ARP 0
	WAVE Wave_7D20
	VOLENV 15, $10, $1F, $12
	RELEASE $02, $55
	NOTE C_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	END

; Sound effect 29
Sfx29:
	CALL_CODE Code_7B58
	END

; Sound effect 19
Sfx19:
	VOLENV 12, $11, $1F, $14
	WAVE Wave_7CB0
	GLIDE $04
	LEN 4
	NOTE G_, 3
	GLIDE $FD
	LEN 6
	WAIT
	REST
	END

; Sound effect 31
Sfx31:
	VOLENV 10, $11, $1F, $14
	WAVE Wave_7CB0
	LEN 33
	SLIDE_DOWN $03
	NOTE A_, 5
	END

; Unreferenced (16 bytes)
	db $BA, $11, $1F, $13, $79, $B0, $7C, $C1, $30, $D6, $3C, $63, $05, $01, $04, $68

; Sound effect 25
Sfx25:
	CALL_CODE Code_7BAE
	VOLENV 15, $00, $00, $00
	WAVE Wave_7D90
	LEN 3
	GLIDE $FF
	NOTE Csh, 6
	WAVE Wave_7D70
	WAIT
	WAVE Wave_7D80
	WAIT
	END

; Sound effect 6
Sfx06:
	CALL_CODE Code_79BA
	WAVE Wave_7CB0
	VOLENV 10, $11, $1F, $12
	LEN 7
	GLIDE $01
	NOTE C_, 3
	NOTE G_, 2
	END

; Sound effect 24
Sfx24:
	VOLENV 10, $15, $1F, $22
	VIBRATO $00, $02, $06
	WAVE Wave_7D50
	LEN 20
	NOTE A_, 5
	GLIDE $FF
	LEN 10
	WAIT
	END

; Sound effect 23
Sfx23:
	VOLENV 12, $11, $1F, $13
	VIBRATO $00, $01, $04
	WAVE Wave_7CD0
	CALL_CODE Code_7A98
	GLIDE $FC
	LEN 5
	NOTE A_, 4
	CALL_CODE Code_7A98
	GLIDE $08
	WAIT
	CALL_CODE Code_7A76
	GLIDE_OFF
	LEN 10
	WAIT
	GLIDE $FF
	WAIT
	END

; Sound effect 5
Sfx05:
	CALL_CODE Code_79FA
	VOLENV 10, $11, $1F, $11
	WAVE Wave_7CB0
	LEN 10
	ARP 5
	GLIDE $01
	NOTE A_, 5
	END

; Sound effect 11
Sfx11:
	VOLENV 15, $00, $00, $00
	WAVE Wave_7D40
	LEN 5
	NOTE A_, 3
	LEN 3
	REST
	LEN 20
	NOTE A_, 3
	END

; Sound effect 22
Sfx22:
	WAVE Wave_7CA0
	VOLENV 5, $1F, $00, $20
	CALL_CODE Code_78F4
	LEN 21
	NOTE Gsh, 3
	END
Code_78F4:
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
	ld a, HIGH(Noise43_7921)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7921)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_7921:
	db $18, $3A, $47, $49, $2E, $2D, $1C, $28
	db $4A, $57, $39, $4E, $1D, $0C, $FF
Noise43_7930:
	db $12, $64, $02, $37, $47, $24, $55, $71
	db $07, $44, $60, $36, $84, $82, $64, $02
	db $37, $47, $24, $55, $71, $07, $44, $60
	db $36, $86, $32, $FF
Code_794C:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $18
	ld [wDrumHold], a
	ld a, $A2
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ld a, HIGH(Noise43_7976)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7976)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_7976:
	db $46, $45, $44, $43, $42, $41, $32, $30
	db $FF

; Unreferenced (9 bytes)
	db $10, $10, $20, $31, $33, $34, $35, $36, $FF
Code_7988:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $0A
	ld [wDrumHold], a
	ld a, $02
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_79B3)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_79B3)
	ld [wNoise43], a
	ld a, HIGH(Noise42_79B7)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_79B7)
	ld [wNoise42], a
	ret
Noise43_79B3:
	db $71, $00, $61, $FF
Noise42_79B7:
	db $F1, $00, $F1
Code_79BA:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $19
	ld [wDrumHold], a
	ld a, HIGH(Noise43_7930)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7930)
	ld [wNoise43], a
	ld a, HIGH(Noise42_79DC)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_79DC)
	ld [wNoise42], a
	ret
Noise42_79DC:
	db $59, $FF, $FF, $FF, $FF, $FF, $FF, $F2
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF

; Unreferenced (3 bytes)
	db $FF, $FF, $FF
Code_79FA:
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
	ld a, HIGH(Noise43_7930)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7930)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Code_7A27:
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
	ld a, HIGH(Noise43_7A51)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7A51)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_7A51:
	db $36, $35, $34, $33, $32, $31, $20, $10
	db $10, $37, $36, $35, $34, $33, $32, $21
	db $11, $11, $38, $37, $36, $35, $34, $33
	db $22, $12, $12, $39, $38, $37, $36, $35
	db $34, $23, $13, $13, $FF
Code_7A76:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7ABA)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7ABA)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7AD4)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7AD4)
	ld [wNoise42], a
	ret
Code_7A98:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7AC7)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7AC7)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7AD4)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7AD4)
	ld [wNoise42], a
	ret
Noise43_7ABA:
	db $10, $10, $20, $31, $32, $33, $33, $34
	db $34, $35, $35, $36, $FF
Noise43_7AC7:
	db $36, $35, $35, $34, $34, $33, $33, $32
	db $31, $20, $10, $10, $FF
Noise42_7AD4:
	db $5C, $FF, $FF, $FF, $FF, $FF, $A1, $FF
	db $FF, $FF, $FF, $FF

; Unreferenced (1 bytes)
	db $FF
Code_7AE1:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $C2
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ld a, HIGH(Noise43_7B0B)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B0B)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_7B0B:
	db $12, $92, $42, $42, $42, $42, $52, $65
	db $45, $FF

; Unreferenced (18 bytes)
	db $F0, $FF, $55, $00, $B2, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $F0, $FF, $FF
	db $FF, $F4
Code_7B27:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B49)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B49)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B51)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B51)
	ld [wNoise42], a
	ret
Noise43_7B49:
	db $02, $51, $61, $71, $91, $71, $60, $FF
Noise42_7B51:
	db $F0, $F0, $F0, $F0, $F0, $70, $63
Code_7B58:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B7A)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B7A)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B7E)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B7E)
	ld [wNoise42], a
	ret
Noise43_7B7A:
	db $02, $51, $11, $FF
Noise42_7B7E:
	db $F0, $A0, $55
Code_7B81:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7BA3)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7BA3)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7BA9)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7BA9)
	ld [wNoise42], a
	ret
Noise43_7BA3:
	db $02, $41, $61, $71, $11, $FF
Noise42_7BA9:
	db $F0, $FF, $FF, $A0, $B2
Code_7BAE:
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7BD0)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7BD0)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7BD6)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7BD6)
	ld [wNoise42], a
	ret
Noise43_7BD0:
	db $00, $53, $71, $91, $31, $FF
Noise42_7BD6:
	db $F1, $FF, $FF, $FF, $00
Code_7BDB:
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7BFD)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7BFD)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7C04)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7C04)
	ld [wNoise42], a
	ret
Noise43_7BFD:
	db $41, $61, $61, $41, $71, $71, $FF
Noise42_7C04:
	db $A1, $52, $00, $61, $52, $00
Code_7C0A:
	ld a, $23
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $01
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_7C35)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7C35)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7C40)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7C40)
	ld [wNoise42], a
	ret
Noise43_7C35:
	db $27, $26, $25, $14, $13, $12, $11, $10
	db $10, $10, $FF
Noise42_7C40:
	db $19, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $F2
Code_7C4A:
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
	ld a, HIGH(Noise43_7C75)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7C75)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7C7B)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7C7B)
	ld [wNoise42], a
	ret
Noise43_7C75:
	db $03, $93, $80, $72, $70, $FF
Noise42_7C7B:
	db $F0, $FF, $FF, $FF, $F3
Wave_7C80:
	db $01, $11, $11, $00, $89, $AA, $AA, $98
	db $01, $11, $11, $00, $FF, $FF, $FF, $FF
Wave_7C90:
	db $8C, $FE, $ED, $B8, $53, $21, $10, $24
	db $84, $01, $12, $35, $8B, $DE, $EF, $8C
Wave_7CA0:
	db $B7, $40, $F4, $7B, $FD, $FF, $FE, $DC
	db $02, $46, $8A, $BD, $FD, $BA, $6F, $20
Wave_7CB0:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
Wave_7CC0:
	db $00, $00, $00, $00, $CD, $EF, $FD, $EC
	db $00, $12, $21, $00, $DD, $DD, $DD, $DD
Wave_7CD0:
	db $00, $00, $00, $00, $00, $00, $FF, $FF
	db $00, $00, $00, $00, $00, $00, $FF, $FF
Wave_7CE0:
	db $00, $00, $00, $00, $00, $00, $FF, $00
	db $00, $00, $00, $00, $00, $00, $FF, $00
Wave_7CF0:
	db $00, $00, $00, $CD, $EF, $FF, $FF, $FF
	db $04, $8C, $FF, $FF, $FF, $FF, $FF, $FF
Wave_7D00:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $00, $FF, $FF, $FF
Wave_7D10:
	db $63, $10, $00, $00, $00, $00, $01, $36
	db $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9
Wave_7D20:
	db $63, $10, $01, $47, $74, $10, $01, $36
	db $9C, $EF, $FE, $B8, $8B, $EF, $FE, $C9
Wave_7D30:
	db $63, $1F, $01, $47, $74, $10, $01, $36
	db $9C, $E0, $FE, $B8, $8B, $EF, $FE, $C9
Wave_7D40:
	db $0F, $00, $F0, $F0, $F0, $F0, $00, $0F
	db $0F, $FF, $FF, $00, $FF, $F0, $0F, $0F
Wave_7D50:
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $ED, $CB, $A9, $87, $65, $43, $21, $00
Wave_7D60:
	db $FE, $DB, $97, $53, $13, $54, $32, $10
	db $FE, $DC, $BC, $EF, $DB, $85, $32, $10
Wave_7D70:
	db $04, $8B, $DE, $FF, $ED, $CB, $A9, $87
	db $65, $44, $44, $32, $11, $24, $7A, $74
Wave_7D80:
	db $20, $24, $68, $AC, $EC, $A8, $64, $20
	db $24, $68, $A8, $64, $20, $24, $68, $64
Wave_7D90:
	db $02, $48, $AC, $FF, $FC, $53, $00, $27
	db $9C, $DD, $DC, $B7, $7B, $CD, $DD, $C9
Noise43_7DA0:
	db $02, $61, $71, $A1, $B1, $B1, $A1, $FF
Noise42_7DA8:
	db $C1, $F0, $A0, $90, $70, $40, $33
Noise43_7DAF:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_7DB7:
	db $60, $30, $12, $FF, $FF, $FF, $FF
Noise43_7DBE:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_7DC6:
	db $A0, $60, $32, $FF, $FF, $FF, $FF
Noise43_7DCD:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_7DD5:
	db $70, $40, $40, $40, $40, $43, $FF
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7DA0)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7DA0)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7DA8)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7DA8)
	ld [wNoise42], a
	ret
Drum2:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7E16)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7E16)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7E1E)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7E1E)
	ld [wNoise42], a
	ret
Noise43_7E16:
	db $60, $52, $42, $41, $22, $11, $04, $FF
Noise42_7E1E:
	db $F0, $F0, $F0, $A0, $70, $40, $51
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7DCD)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7DCD)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7DD5)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7DD5)
	ld [wNoise42], a
	ret
Drum5:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7DBE)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7DBE)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7DC6)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7DC6)
	ld [wNoise42], a
	ret
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7DAF)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7DAF)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7DB7)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7DB7)
	ld [wNoise42], a
	ret
Drum9:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7E99)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7E99)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7E9C)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7E9C)
	ld [wNoise42], a
	ret
Noise43_7E99:
	db $51, $32, $FF
Noise42_7E9C:
	db $F0, $62
Drum10:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7EBB)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7EBB)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7EBE)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7EBE)
	ld [wNoise42], a
	ret
Noise43_7EBB:
	db $51, $32, $FF
Noise42_7EBE:
	db $90, $61

; Unreferenced (15 bytes)
	db $51, $32, $32, $32, $32, $51, $32, $FF, $80, $51, $FF, $FF, $FF, $80, $51
FadeOutTable:
	db $77, $66, $55, $44, $33, $22, $11, $00
	db FADE_END
FadeInTable:
	db $00, $11, $22, $33, $44, $55, $66, $77
	db FADE_END

; Unreferenced (287 bytes)
	db $46, $69, $6E, $61, $6C, $20, $64, $65, $20, $6C, $61, $20, $72, $75, $74, $69
	db $6E, $61, $20, $64, $65, $20, $6D, $75, $73, $69, $63, $61, $00, $FA, $83, $4F
	db $10, $02, $80, $7F, $34, $2A, $74, $0B, $56, $8D, $74, $1A, $E8, $C0, $1C, $5E
	db $EB, $09, $90, $56, $8D, $74, $1E, $E8, $B5, $1C, $5E, $FB, $B0, $FF, $C3, $87
	db $DB, $E8, $3B, $4B, $72, $48, $89, $7F, $6C, $8C, $47, $6E, $81, $4F, $1E, $A0
	db $00, $83, $67, $1E, $BF, $81, $4F, $20, $00, $40, $26, $83, $7D, $04, $FF, $74
	db $27, $8D, $47, $16, $3B, $47, $16, $9C, $50, $B8, $12, $07, $50, $2B, $C0, $50
	db $B8, $30, $75, $50, $53, $8D, $47, $72, $50, $FF, $16, $3C, $00, $58, $9D, $FB
	db $75, $03, $E8, $50, $2E, $B0, $FF, $C3, $83, $4F, $1E, $40, $EB, $F4, $8B, $F7
	db $E8, $16, $0D, $B0, $FF, $C3, $87, $DB, $90, $8B, $FB, $26, $8B, $4D, $08, $83
	db $F9, $04, $73, $0E, $B0, $01, $26, $88, $45, $01, $8B, $F7, $E8, $FA, $0C, $B0
	db $FF, $C3, $8B, $C6, $8B, $D0, $33, $DB, $26, $80, $7D, $1A, $2A, $74, $18, $8D
	db $75, $1A, $E8, $EE, $17, $B0, $15, $72, $DD, $83, $7F, $06, $02, $75, $D7, $B0
	db $19, $F7, $07, $02, $00, $75, $CF, $8B, $F3, $8B, $DF, $06, $53, $57, $26, $8B
	db $4F, $08, $83, $E9, $04, $26, $C4, $5F, $04, $32, $C0, $26, $88, $47, $01, $26
	db $88, $47, $02, $26, $88, $47, $03, $8B, $C2, $8B, $D3, $0B, $F6, $75, $2A, $26
	db $C6, $07, $FF, $83, $C3, $04, $8B, $F0, $8B, $FE, $8B, $75, $64, $56, $57, $80
	db $7C, $02, $00, $74, $03, $E8, $11, $FD, $5F, $5E, $3C, $06, $74, $17, $83
