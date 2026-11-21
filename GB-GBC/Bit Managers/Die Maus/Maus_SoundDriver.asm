; =====================================================================
; Die Maus (E) (M4) - Game Boy
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o maus.o Maus_SoundDriver.asm
;   rgblink -o maus.gb maus.o
;   python tools/cmp_banked.py maus.gb "Maus, Die (E) (M4) [M].gb" 15:4000-7FFF
; (driver and data fill ROM bank 15; the linked file only matches in that range)
;
; Documentation: Maus_SoundDriver.md / AJG_SoundEngine_Family.md
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
MACRO REPEAT    ; play the following bytes n times (up to REPEAT_END), n = 2-21
	db $EA + \1
ENDM
MACRO LEN       ; note length in ticks, 1-48
	db $BB + \1
ENDM
MACRO VOLENV    ; start volume + envelope (CH3/SFX): atk (lo=count hi=step), dec (lo=count hi=step), rates (hi=atk lo=dec)
	db $AC + \1, \2, \3, \4
ENDM
MACRO INSTR     ; instrument n = entry n + 1 of the current instrument table
	db $85 + \1
ENDM
MACRO ARP       ; arpeggio n of the current arpeggio table
	db $93 + \1
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
	db $82
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
MACRO PORTA
	db $83
	db \1
	db \2
ENDM
MACRO PORTA_OFF
	db $84
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
DEF DRUM_TEMPO EQU $BB         ; + n: one step every n ticks
DEF DRUM_LOOP EQU $FF           ; restart the pattern

; ---- RAM / HRAM ----
DEF wCh1 EQU $C100
DEF wPaused EQU $C14B
DEF wStereo EQU $C14C
DEF wShNR32 EQU $C14D
DEF wInInstr EQU $C14E
DEF wNoisePan EQU $C14F
DEF wDrumHold EQU $C150
DEF wInstrTable EQU $C151
DEF wInstrTableHi EQU $C152
DEF wArpTable EQU $C153
DEF wArpTableHi EQU $C154
DEF wMusicWave EQU $C155
DEF wMusicWaveHi EQU $C156
DEF wNoiseAutoPan EQU $C157
DEF wDrumPatHi EQU $C158
DEF wDrumPat EQU $C159
DEF wDrumPos EQU $C15A
DEF wDrumsOn EQU $C15B
DEF wDrumTempo EQU $C15C
DEF wDrumTimer EQU $C15D
DEF wDrumLoopCount EQU $C15E
DEF wDrumLoopPos EQU $C15F
DEF wNoise43Hi EQU $C160
DEF wNoise43 EQU $C161
DEF wNoise42Hi EQU $C162
DEF wNoise42 EQU $C163
DEF wNoisePos EQU $C164
DEF wNoiseOn EQU $C165
DEF wNoiseAtten EQU $C166
DEF wNoiseTimer EQU $C167
DEF wNoiseSpeed EQU $C168
DEF wFadeTable EQU $C169
DEF wFadeTableHi EQU $C16A
DEF wFadePos EQU $C16B
DEF wFadeTimer EQU $C16C
DEF wFadeSpeed EQU $C16D
DEF wFadeOn EQU $C16E
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
	dw Cmd_NoteHook
	dw Cmd_Porta
	dw Cmd_PortaOff
	jp SndUpdate                       ; SndUpdate
	jp SndPause                        ; SndPause
	jp SndResume                       ; SndResume
	jp StopAll                         ; StopAll
	jp PlaySfxEntry                    ; PlaySfx (A = id)
	jp SndInit                         ; SndInit
	jp SongFadeIn                      ; SongFadeIn (A = speed)
	jp SongFadeOut                     ; SongFadeOut (A = speed)
	jp PlaySong1                       ; song slot 1: song 1
	jp PlaySong2                       ; song slot 2: song 2
	jp PlaySong3                       ; song slot 3: song 3
	jp PlaySong4                       ; song slot 4: song 4
	jp PlaySong5                       ; song slot 5: song 5
	jp PlaySong6                       ; song slot 6: song 6
	jp PlaySong7                       ; song slot 7: song 7
	jp PlaySong8                       ; song slot 8: song 8
	jp PlaySong9                       ; song slot 9: song 9
	jp PlaySong1                       ; song slot 10: song 1
	jp PlaySong1                       ; song slot 11: song 1
	jp PlaySong1                       ; song slot 12: song 1
PlaySfxEntry2:
	jp PlaySfx                         ; PlaySfxNow (A = id; the same code as PlaySfx)

; SndResume / SndPause: wPaused = 0 / 1; both silence CH1-CH4 and reset the SFX
; page (which reloads the music wave), as in Prisoners of the Sun. Nothing in the
; driver calls them (StopAll, STOP_ALL and SongFadeIn do not).
SndResume:
	xor a
	ld [wPaused], a
	jp L4096
SndPause:
	ld a, $01
	ld [wPaused], a
	dec a
L4096:
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

; NOTE_HOOK on_note, on_wait / NOTE_HOOK 0 (moved to $82; unused by the data): at
; each note, field $3C = previous note, $3D = this note, then call on_note; at each
; WAIT/WAIT2, call on_wait and play the note in $3C.
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

; Output, pulse pages: AddPortaOffset first moves the period fields ($05/$06) by the
; porta offset; NRx3 = period low + pitch offset; when the high byte changed or the
; envelope flag ($33) is set: with the flag NRx2 = field $32 and NRx4 = high | $80,
; else NRx4 = high.
OutputCh1:
	ld hl, $C125
	call AddPortaOffset
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
	call AddPortaOffset
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
	jr nz, L4154
	dec h
L4154:
	call AddPortaOffset
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
	add a, $BA
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
	call L4154
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
	bit 6, [hl]
	call nz, PortaTick
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
	jp UpdatePeriod

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

; Note on: clear the porta state (fields $48-$4A), ticks left = length, then
; PortaStart (look ahead for the next note). The direction bit (b4) is always cleared.
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
	ld l, $4A
	ld [hld], a
	ld [hld], a
	ld [hld], a
	ld l, $09
	ld a, [hli]
	ld [hl], a
	call PortaStart
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
	sub $EA
	ld l, $39
	ld [hli], a
	ld [hl], e
	inc l
	ld [hl], d
	jp ReadByte

; StreamCommand: REPEAT / LEN / VOLENV / ARP / INSTR ranges, else CmdTable.
StreamCommand:
	cp $EC
	jr nc, Cmd_Repeat
	cp $BC
	jr nc, Cmd_Len
	cp $AC
	jr nc, Cmd_VolEnv
	cp $93
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
	sub $BB
	ld l, $09
	ld [hl], a
	jp ReadStream

; VOLENV v, atk, dec, rates: start volume v; attack = lo nibble steps of hi nibble;
; decay likewise; rates hi = ticks per attack step, lo = ticks per decay step.
; Only the CH3 and SFX pages use it.
Cmd_VolEnv:
	sub $AC
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
	sub $93
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

; INSTR n: clear arpeggio, vibrato (b3), glide, arpeggio offset and auto-duty
; (field $2F); pulse pages: NR11/NR21 = 50 % duty; then run macro n (entry n + 1
; of wInstrTable) up to END with wInInstr = $C9.
Cmd_Instrument:
	push de
	ld b, a
	xor a
	ld l, $04
	res 0, [hl]
	res 3, [hl]
	ld l, $0B
	ld [hl], a
	ld l, $0E
	ld [hl], a
	ld l, $2F
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

; RELEASE minlen << 4 | ticks, env / RELEASE 0: an env byte of 0 is replaced by $11.
Cmd_Release:
	ld l, $34
	ld a, [de]
	inc de
	and a
	jr z, ReleaseOff
	ld [hli], a
	ld a, [de]
	and a
	jr nz, L4490
	ld a, $11
L4490:
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

; VIBRATO delay, depth, speed: fields $20-$24, set b3 (vibrato) and b4 (direction).
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
	set 3, [hl]
	set 4, [hl]
	ret

; VIB_OFF: clear b3 only (earlier builds clear b3 and b4).
Cmd_VibOff:
	ld l, $04
	res 3, [hl]
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

; Unreferenced (122 bytes)
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $C0, $F7, $01, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $E0, $F7, $01, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $F8, $01, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
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
	add a, $4C
	ld l, a
	adc a, $6A
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
	cp $BC
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
	dw Drum8
	dw Drum3
	dw Drum4
	dw Drum5
	dw Drum6
	dw Drum9
	dw Drum8
	dw Drum9

; Unreferenced (4 bytes)
	db $19, $75, $36, $75
DrumTempo:
	sub $BB
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

; AddPortaOffset (h = page): period fields $05/$06 += offset $48/$49, or -= when
; field $4A is 1 (slide down).
AddPortaOffset:
	ld l, $4A
	ld a, [hld]
	and a
	jr nz, L4B34
	ld a, [hld]
	ld c, a
	ld a, [hl]
	ld l, $05
	add a, [hl]
	ld [hli], a
	ld a, [hl]
	adc a, c
	ld [hl], a
	ret
L4B34:
	ld a, [hld]
	ld c, a
	ld b, [hl]
	ld l, $05
	ld a, [hl]
	sub b
	ld [hli], a
	ld a, [hl]
	sbc a, c
	ld [hl], a
	ret

; PortaTick (each tick while b6 is set): the delay $44 counts down first; then, while
; a slide is pending ($45 = 1 down / 2 up), offset $48/$49 += step ($42) and
; $4A = 1 for down; once the offset reaches the period distance $46/$47 it is
; clamped there and $45 = 0.
PortaTick:
	ld l, $04
	bit 6, [hl]
	ret z
	ld l, $44
	ld a, [hl]
	and a
	jr z, L4B4E
	dec a
	ld [hl], a
	ret
L4B4E:
	ld l, $45
	ld a, [hl]
	and a
	ret z
	ld l, $42
	ld b, [hl]
	cp $01
	jr z, L4B6A
	ld l, $48
	ld a, [hl]
	add a, b
	ld [hl], a
	jr nc, L4B63
	inc l
	inc [hl]
L4B63:
	ld l, $4A
	xor a
	ld [hl], a
	jr L4B78

; Unreferenced (1 bytes)
	db $C9
L4B6A:
	ld l, $48
	ld a, [hl]
	add a, b
	ld [hl], a
	jr nc, L4B73
	inc l
	inc [hl]
L4B73:
	ld l, $4A
	ld a, $01
	ld [hl], a
L4B78:
	push de
	ld l, $47
	ld d, h
	ld e, $49
	ld a, [de]
	cp [hl]
	jr z, L4B8C
	jr c, L4B9A
	ld a, [hl]
	ld [de], a
	dec l
	dec e
	ld a, [hl]
	ld [de], a
	jr L4B96
L4B8C:
	dec l
	dec e
	ld a, [de]
	cp [hl]
	jr z, L4B96
	jr c, L4B9A
	ld a, [hl]
	ld [de], a
L4B96:
	ld l, $45
	ld [hl], $00
L4B9A:
	pop de
	ret

; PORTA step, lead (new, $83): field $42 = step, $43 = lead, set b6. From the next
; note on, each note slides to the following note during the last `lead` ticks
; before it, `step` period units per tick (PortaStart, PortaTick, AddPortaOffset).
Cmd_Porta:
	ld a, [de]
	inc de
	ld l, $42
	ld [hli], a
	ld a, [de]
	inc de
	ld [hl], a
	ld l, $04
	set 6, [hl]
	ret

; PORTA_OFF (new, $84): clear b6.
Cmd_PortaOff:
	ld l, $04
	res 6, [hl]
	ret

; PortaStart (note on, while b6 is set): scan the stream after this note. Delay $44
; = this note's length, + one length per WAIT/REST; VOLENV (4 bytes) and PORTA
; (3 bytes) are skipped, every other byte counts as 1 (LEN and command arguments
; are not followed); END or NEXT: no slide. At the next note: delay -= lead
; (not below 0), direction from the two notes, distance = difference of their
; periods (note + channel and global transpose; no arpeggio).
PortaStart:
	ld l, $04
	bit 6, [hl]
	ret z
	ld l, $44
	ld [hl], $00
	push de
	jr L4BFA
PortaScan:
	ld a, [de]
	inc de
	cp $60
	jr nc, L4BD1
	ld c, a
	ld l, $43
	ld b, [hl]
	ld l, $44
	ld a, [hl]
	sub b
	jr c, L4BCD
	ld [hl], a
	jr PortaTarget
L4BCD:
	xor a
	ld [hl], a
	jr PortaTarget
L4BD1:
	cp $65
	jr z, L4BFA
	cp $66
	jr z, L4BFA
	cp $83
	jr z, L4BF1
	cp $AC
	jr c, L4BE7
	cp $BC
	jr nc, L4BE7
	jr L4BF5
L4BE7:
	cp $6A
	jr z, PortaNone
	cp $68
	jr z, PortaNone
	jr PortaScan
L4BF1:
	inc de
	inc de
	jr PortaScan
L4BF5:
	inc de
	inc de
	inc de
	jr PortaScan
L4BFA:
	ld l, $09
	ld b, [hl]
	ld l, $44
	ld a, [hl]
	add a, b
	ld [hl], a
	jr PortaScan
PortaTarget:
	ld l, $46
	xor a
	ld [hli], a
	ld [hl], a
	ld l, $0C
	ld b, [hl]
	ld a, c
	ld l, $45
	cp b
	jr z, L4C6B
	jr nc, L4C3D
	ld [hl], $01
	push de
	ld l, $0D
	ld a, [hl]
	ld l, $0F
	add a, [hl]
	ld e, a
	ld a, b
	add a, e
	ld b, a
	ld a, c
	add a, e
	ld d, h
	push bc
	add a, a
	ld l, a
	ld h, $48
	pop bc
	ld a, b
	add a, a
	ld c, a
	ld b, h
	ld e, $46
	ld a, [bc]
	sub [hl]
	ld [de], a
	inc e
	inc c
	inc l
	ld a, [bc]
	sbc a, [hl]
	ld [de], a
	ld h, d
	pop de
	jr L4C72
L4C3D:
	ld [hl], $02
	push de
	ld l, $0D
	ld a, [hl]
	ld l, $0F
	add a, [hl]
	ld e, a
	ld a, c
	add a, e
	ld c, a
	ld a, b
	add a, e
	ld d, h
	push bc
	add a, a
	ld l, a
	ld h, $48
	pop bc
	ld a, c
	add a, a
	ld c, a
	ld b, h
	ld e, $46
	ld a, [bc]
	sub [hl]
	ld [de], a
	inc e
	inc c
	inc l
	ld a, [bc]
	sbc a, [hl]
	ld [de], a
	ld h, d
	pop de
	jr L4C72
PortaNone:
	ld l, $44
	ld [hl], $00
	inc l
L4C6B:
	ld [hl], $00
	ld l, $46
	xor a
	ld [hli], a
	ld [hl], a
L4C72:
	pop de
	ret

; Song 2: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong2:
	ld a, $68
	ld [wInstrTableHi], a
	ld a, $A5
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
	dw Pat_4CE2
Loop_4C96:
	dw Pat_4CE9
	dw Pat_4CE9
	dw Pat_4D0C
	dw Pat_4D0C
	dw Pat_4D48
	dw Pat_4DB9
	dw Pat_4E1B
	dw Pat_4E1B
	dw Pat_4E45
	dw Pat_4E45
	ORDER_LOOP Loop_4C96
Song2_Ch3:
	dw Pat_4E68
Loop_4CB0:
	dw Pat_4E73
	dw Pat_4E73
	dw Pat_4E93
	dw Pat_4E93
	dw Pat_4ECD
	dw Pat_4F07
	dw Pat_4F40
	dw Pat_4F40
	dw Pat_4F79
	dw Pat_4F79
	ORDER_LOOP Loop_4CB0
Song2_Ch2:
	dw Pat_4FE3
Loop_4CCA:
	dw Pat_4FE9
	dw Pat_4FE9
	dw Pat_4FFE
	dw Pat_4FFE
	dw Pat_5027
	dw Pat_5058
	dw Pat_5086
	dw Pat_5086
	dw Pat_50BF
	dw Pat_50BF
	ORDER_LOOP Loop_4CCA
Pat_4CE2:
	INSTR 0
Pat_4CE3:
	LENGTH $40
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	NEXT
Pat_4CE9:
	INSTR 0
	LEN 16
	NOTE C_, 3
	INSTR 6
	LEN 32
	NOTE G_, 3
	LEN 16
	NOTE G_, 3
	INSTR 0
	NOTE C_, 3
	INSTR 6
	LEN 32
	NOTE G_, 3
	LEN 8
	NOTE G_, 3
	NOTE C_, 3
	INSTR 0
	LEN 16
	NOTE C_, 3
	INSTR 6
	LEN 32
	NOTE G_, 3
	LEN 16
	NOTE G_, 3
	INSTR 0
	NOTE C_, 3
	INSTR 6
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 6
	LEN 8
	NOTE G_, 3
	NOTE G_, 2
	NEXT
Pat_4D0C:
	INSTR 0
	LEN 16
	NOTE C_, 3
	INSTR 6
	LEN 32
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 6
	LEN 32
	NOTE D_, 4
	LEN 16
	NOTE D_, 4
	INSTR 0
	NOTE Ash, 2
	INSTR 6
	LEN 32
	NOTE D_, 4
	LEN 16
	NOTE D_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 6
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 6
	NOTE B_, 3
	INSTR 0
	NOTE C_, 3
	INSTR 6
	LEN 32
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 6
	LEN 32
	NOTE D_, 4
	LEN 16
	NOTE D_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 6
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 6
	NOTE G_, 3
	INSTR 0
	NOTE C_, 3
	INSTR 6
	LEN 32
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	NEXT
Pat_4D48:
	INSTR 0
	LEN 16
	NOTE G_, 2
	INSTR 6
	LEN 8
	NOTE B_, 3
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE D_, 3
	INSTR 6
	LEN 8
	NOTE B_, 3
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE D_, 2
	INSTR 6
	LEN 8
	NOTE A_, 3
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 6
	LEN 8
	NOTE A_, 3
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE F_, 2
	INSTR 6
	LEN 8
	NOTE A_, 3
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE C_, 3
	INSTR 6
	LEN 8
	NOTE A_, 3
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE C_, 2
	INSTR 6
	LEN 8
	NOTE G_, 3
	NOTE C_, 4
	INSTR 0
	LEN 16
	NOTE D_, 2
	INSTR 6
	LEN 8
	NOTE G_, 3
	NOTE C_, 4
	INSTR 0
	LEN 16
	NOTE G_, 2
	INSTR 6
	LEN 8
	NOTE B_, 3
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE D_, 3
	INSTR 6
	LEN 8
	NOTE B_, 3
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE D_, 2
	INSTR 6
	LEN 8
	NOTE A_, 3
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 6
	LEN 8
	NOTE A_, 3
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE F_, 2
	INSTR 6
	LEN 8
	NOTE A_, 3
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE C_, 3
	INSTR 6
	LEN 8
	NOTE A_, 3
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE C_, 2
	INSTR 6
	LEN 8
	NOTE G_, 3
	NOTE C_, 4
	INSTR 0
	LEN 16
	NOTE C_, 3
	INSTR 6
	LEN 8
	NOTE E_, 4
	NOTE G_, 4
	NEXT
Pat_4DB9:
	INSTR 0
	LEN 16
	NOTE G_, 2
	INSTR 6
	LEN 8
	NOTE B_, 3
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE D_, 3
	INSTR 6
	LEN 8
	NOTE B_, 3
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE D_, 2
	INSTR 6
	LEN 8
	NOTE A_, 3
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 6
	LEN 8
	NOTE A_, 3
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE F_, 2
	INSTR 6
	LEN 8
	NOTE A_, 3
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE C_, 3
	INSTR 6
	LEN 8
	NOTE A_, 3
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE C_, 2
	INSTR 6
	LEN 8
	NOTE G_, 3
	NOTE C_, 4
	INSTR 0
	LEN 16
	NOTE D_, 2
	INSTR 6
	LEN 8
	NOTE G_, 3
	NOTE C_, 4
	INSTR 0
	LEN 16
	NOTE G_, 2
	INSTR 6
	LEN 8
	NOTE B_, 3
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE D_, 3
	INSTR 6
	LEN 8
	NOTE B_, 3
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE D_, 2
	INSTR 6
	LEN 8
	NOTE A_, 3
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 6
	LEN 8
	NOTE A_, 3
	NOTE D_, 4
	INSTR 0
	LEN 16
	NOTE C_, 2
	INSTR 6
	NOTE G_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 6
	NOTE A_, 3
	INSTR 0
	LEN 32
	NOTE G_, 2
	NOTE G_, 2
	NEXT
Pat_4E1B:
	INSTR 6
	LEN 16
	NOTE G_, 2
	NOTE G_, 2
	LEN 32
	NOTE D_, 4
	LEN 16
	NOTE F_, 2
	NOTE F_, 2
	LEN 32
	NOTE C_, 4
	LEN 16
	NOTE C_, 2
	NOTE C_, 2
	LEN 32
	NOTE G_, 3
	LEN 16
	NOTE D_, 2
	NOTE D_, 2
	LEN 32
	NOTE A_, 3
	LEN 16
	NOTE G_, 2
	NOTE G_, 2
	LEN 32
	NOTE D_, 4
	LEN 16
	NOTE F_, 2
	NOTE F_, 2
	LEN 32
	NOTE C_, 4
	LEN 16
	NOTE C_, 2
	NOTE C_, 2
	LEN 32
	NOTE G_, 3
	LEN 16
	NOTE D_, 2
	NOTE D_, 2
	LEN 32
	NOTE Fsh, 3
	NEXT
Pat_4E45:
	INSTR 6
	LEN 16
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 4
	NOTE F_, 2
	NOTE F_, 4
	NOTE F_, 2
	NOTE F_, 4
	NOTE C_, 2
	NOTE C_, 4
	NOTE C_, 2
	NOTE C_, 4
	NOTE D_, 2
	NOTE D_, 4
	NOTE D_, 2
	NOTE D_, 4
	NOTE G_, 2
	NOTE G_, 4
	NOTE G_, 2
	NOTE G_, 4
	NOTE F_, 2
	NOTE F_, 4
	NOTE F_, 2
	NOTE F_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE D_, 2
	NOTE D_, 4
	NOTE D_, 2
	NOTE D_, 4
	NEXT
Pat_4E68:
	INSTR 7
	PAT_GOTO Pat_4CE3

; Unreferenced (7 bytes)
	db $6B, $80, $65, $65, $65, $65, $6A
Pat_4E73:
	CH_TRANSPOSE $0C
	LEN 16
	WAIT
	INSTR 7
	NOTE E_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 7
	LEN 32
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 7
	LEN 32
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 7
	LEN 32
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 7
	NOTE E_, 4
	NEXT
Pat_4E93:
	LEN 16
	WAIT
	INSTR 7
	NOTE C_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 7
	LEN 32
	NOTE C_, 4
	LEN 16
	NOTE B_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 7
	LEN 32
	NOTE B_, 3
	LEN 16
	NOTE Ash, 3
	INSTR 1
	NOTE C_, 3
	INSTR 7
	LEN 32
	NOTE Ash, 3
	LEN 16
	NOTE A_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 7
	LEN 32
	NOTE G_, 3
	LEN 16
	NOTE C_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 7
	LEN 32
	NOTE C_, 4
	LEN 16
	NOTE B_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 7
	LEN 32
	NOTE B_, 3
	LEN 16
	NOTE A_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 7
	LEN 32
	NOTE B_, 3
	LEN 16
	NOTE C_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 7
	NOTE C_, 4
	NEXT
Pat_4ECD:
	LEN 16
	WAIT
	INSTR 5
	NOTE G_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 5
	LEN 32
	NOTE G_, 4
	LEN 16
	NOTE D_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 5
	LEN 32
	NOTE D_, 4
	LEN 16
	NOTE F_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 5
	LEN 32
	NOTE F_, 4
	LEN 16
	NOTE C_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 5
	LEN 32
	NOTE C_, 4
	LEN 16
	NOTE G_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 5
	LEN 32
	NOTE G_, 4
	LEN 16
	NOTE D_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 5
	LEN 32
	NOTE D_, 4
	LEN 16
	NOTE F_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 5
	LEN 32
	NOTE F_, 4
	LEN 16
	NOTE C_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 5
	NOTE C_, 4
	NEXT
Pat_4F07:
	LEN 16
	WAIT
	INSTR 5
	NOTE G_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 5
	LEN 32
	NOTE G_, 4
	LEN 16
	NOTE D_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 5
	LEN 32
	NOTE D_, 4
	LEN 16
	NOTE F_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 5
	LEN 32
	NOTE F_, 4
	LEN 16
	NOTE C_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 5
	LEN 32
	NOTE C_, 4
	LEN 16
	NOTE G_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 5
	LEN 32
	NOTE G_, 4
	LEN 16
	NOTE D_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 5
	LEN 32
	NOTE D_, 4
	LEN 16
	NOTE C_, 4
	INSTR 1
	NOTE C_, 3
	INSTR 5
	NOTE D_, 4
	INSTR 7
	NOTE G_, 3
	INSTR 5
	NOTE G_, 3
	LEN 32
	NOTE G_, 3
	NEXT
Pat_4F40:
	INSTR 9
	LEN 16
	NOTE G_, 5
	NOTE G_, 5
	INSTR 7
	LEN 32
	NOTE G_, 4
	INSTR 9
	LEN 16
	NOTE F_, 5
	NOTE F_, 5
	INSTR 7
	LEN 32
	NOTE F_, 4
	INSTR 9
	LEN 16
	NOTE C_, 5
	NOTE C_, 5
	INSTR 7
	LEN 32
	NOTE C_, 4
	INSTR 9
	LEN 16
	NOTE D_, 5
	NOTE D_, 5
	INSTR 7
	LEN 32
	NOTE D_, 4
	INSTR 9
	LEN 16
	NOTE G_, 5
	NOTE G_, 5
	INSTR 7
	LEN 32
	NOTE G_, 4
	INSTR 9
	LEN 16
	NOTE F_, 5
	NOTE F_, 5
	INSTR 7
	LEN 32
	NOTE F_, 4
	INSTR 9
	LEN 16
	NOTE C_, 5
	NOTE C_, 5
	INSTR 7
	LEN 32
	NOTE C_, 4
	INSTR 9
	LEN 16
	NOTE D_, 5
	NOTE D_, 5
	INSTR 7
	LEN 32
	NOTE A_, 3
	NEXT
Pat_4F79:
	INSTR 9
	LEN 8
	NOTE G_, 4
	NOTE B_, 4
	INSTR 7
	NOTE B_, 4
	INSTR 9
	NOTE G_, 4
	LEN 16
	NOTE B_, 4
	INSTR 7
	LEN 8
	NOTE B_, 4
	INSTR 9
	NOTE G_, 4
	NOTE F_, 4
	NOTE A_, 4
	INSTR 7
	NOTE A_, 4
	INSTR 9
	NOTE F_, 4
	LEN 16
	NOTE A_, 4
	INSTR 7
	LEN 8
	NOTE A_, 4
	INSTR 9
	NOTE F_, 4
	NOTE E_, 4
	NOTE G_, 4
	INSTR 7
	NOTE G_, 4
	INSTR 9
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	INSTR 7
	LEN 16
	NOTE G_, 4
	INSTR 9
	LEN 8
	NOTE Fsh, 4
	NOTE A_, 4
	INSTR 7
	NOTE A_, 4
	INSTR 9
	NOTE Fsh, 4
	LEN 16
	NOTE A_, 4
	INSTR 7
	LEN 8
	NOTE A_, 4
	INSTR 9
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE B_, 4
	INSTR 7
	NOTE B_, 4
	INSTR 9
	NOTE G_, 4
	LEN 16
	NOTE B_, 4
	INSTR 7
	LEN 8
	NOTE B_, 4
	INSTR 9
	NOTE G_, 4
	NOTE F_, 4
	NOTE A_, 4
	INSTR 7
	NOTE A_, 4
	INSTR 9
	NOTE F_, 4
	LEN 16
	NOTE A_, 4
	INSTR 7
	LEN 8
	NOTE A_, 4
	INSTR 9
	NOTE F_, 4
	NOTE E_, 4
	NOTE G_, 4
	INSTR 7
	NOTE G_, 4
	INSTR 9
	NOTE E_, 4
	LEN 16
	NOTE G_, 4
	INSTR 7
	LEN 8
	NOTE G_, 4
	INSTR 9
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	INSTR 7
	NOTE Fsh, 4
	INSTR 9
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	INSTR 7
	NOTE Fsh, 4
	INSTR 9
	NOTE A_, 4
	NEXT
Pat_4FE3:
	LENGTH $40
	WAIT
	WAIT
	WAIT
	NEXT
Pat_4FE9:
	DRUMS $08, DrumPat_50FA
	HWENV $D2, $00
	DUTY_50
	LEN 16
	WAIT
	LEN 32
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	LEN 16
	NOTE C_, 4
	NEXT
Pat_4FFE:
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE C_, 5
	NOTE D_, 5
	LEN 16
	NOTE E_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE B_, 4
	LENGTH $30
	NOTE G_, 4
	LEN 16
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	LEN 32
	NOTE Ash, 4
	NOTE A_, 4
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE C_, 5
	NOTE D_, 5
	LEN 16
	NOTE E_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE B_, 4
	LEN 32
	NOTE G_, 4
	LEN 16
	NOTE A_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE D_, 5
	LEN 32
	NOTE C_, 5
	NOTE C_, 5
	NEXT
Pat_5027:
	LEN 16
	NOTE G_, 5
	LEN 8
	NOTE G_, 5
	NOTE A_, 5
	LEN 16
	NOTE B_, 5
	NOTE G_, 5
	NOTE D_, 6
	NOTE A_, 5
	NOTE Fsh, 5
	NOTE A_, 5
	NOTE D_, 6
	NOTE A_, 5
	NOTE F_, 5
	NOTE A_, 5
	LEN 8
	NOTE C_, 6
	NOTE D_, 6
	NOTE C_, 6
	NOTE B_, 5
	LEN 16
	NOTE A_, 5
	NOTE G_, 5
	NOTE D_, 5
	LEN 8
	NOTE G_, 5
	NOTE A_, 5
	LEN 16
	NOTE B_, 5
	NOTE G_, 5
	NOTE D_, 6
	NOTE A_, 5
	NOTE Fsh, 5
	NOTE A_, 5
	NOTE D_, 6
	NOTE A_, 5
	NOTE F_, 5
	NOTE A_, 5
	LEN 8
	NOTE G_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE G_, 5
	NOTE C_, 6
	NOTE E_, 6
	NOTE C_, 6
	NEXT
Pat_5058:
	LEN 16
	NOTE G_, 5
	LEN 8
	NOTE G_, 5
	NOTE A_, 5
	LEN 16
	NOTE B_, 5
	NOTE G_, 5
	NOTE D_, 6
	NOTE A_, 5
	NOTE Fsh, 5
	NOTE A_, 5
	NOTE D_, 6
	NOTE A_, 5
	NOTE F_, 5
	NOTE A_, 5
	LEN 8
	NOTE C_, 6
	NOTE D_, 6
	NOTE C_, 6
	NOTE B_, 5
	LEN 16
	NOTE A_, 5
	NOTE G_, 5
	NOTE D_, 5
	LEN 8
	NOTE G_, 5
	NOTE A_, 5
	LEN 16
	NOTE B_, 5
	NOTE G_, 5
	NOTE D_, 6
	NOTE A_, 5
	NOTE Fsh, 5
	NOTE D_, 5
	NOTE E_, 5
	LEN 8
	NOTE Fsh, 5
	NOTE G_, 5
	LEN 16
	NOTE A_, 5
	NOTE D_, 5
	LEN 32
	NOTE G_, 5
	NOTE G_, 5
	NEXT
Pat_5086:
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE G_, 4
	NOTE A_, 4
	LEN 16
	NOTE B_, 4
	LEN 32
	NOTE G_, 4
	LEN 8
	NOTE F_, 4
	NOTE G_, 4
	LEN 16
	NOTE A_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 8
	NOTE E_, 4
	NOTE Fsh, 4
	LEN 16
	NOTE G_, 4
	LEN 32
	NOTE E_, 4
	LEN 8
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE G_, 4
	NOTE A_, 4
	LEN 16
	NOTE B_, 4
	LEN 32
	NOTE G_, 4
	LEN 8
	NOTE F_, 4
	NOTE G_, 4
	LEN 16
	NOTE A_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 8
	NOTE E_, 4
	NOTE Fsh, 4
	LEN 16
	NOTE G_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NEXT
Pat_50BF:
	LEN 16
	NOTE G_, 5
	LEN 8
	NOTE G_, 5
	NOTE A_, 5
	LEN 16
	NOTE B_, 5
	LEN 32
	NOTE G_, 5
	LEN 8
	NOTE F_, 5
	NOTE G_, 5
	LEN 16
	NOTE A_, 5
	NOTE F_, 5
	NOTE E_, 5
	LEN 8
	NOTE E_, 5
	NOTE Fsh, 5
	LEN 16
	NOTE G_, 5
	LEN 32
	NOTE E_, 5
	LEN 8
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE A_, 5
	LEN 16
	NOTE G_, 5
	LEN 8
	NOTE G_, 5
	NOTE A_, 5
	LEN 16
	NOTE B_, 5
	LEN 32
	NOTE G_, 5
	LEN 8
	NOTE F_, 5
	NOTE G_, 5
	LEN 16
	NOTE A_, 5
	NOTE F_, 5
	NOTE C_, 5
	LEN 8
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE A_, 5
	LEN 16
	NOTE B_, 5
	NOTE C_, 6
	NOTE E_, 6
	NOTE D_, 6
	NEXT
DrumPat_50FA:
	db DRUM_LEVEL + 13, 1, 0, 5, 0, 9, 0, 6
	db 0, 1, 0, 5, 0, 9, 0, 6
	db 6, DRUM_LOOP

; Song 3: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong3:
	ld a, $68
	ld [wInstrTableHi], a
	ld a, $A5
	ld [wInstrTable], a
	call StopAll
	ld de, Song3_Ch1
	call StartMusicCh1
	ld de, Song3_Ch2
	call StartMusicCh2
	ld de, Song3_Ch3
	jp StartMusicCh3
Song3_Ch1:
	dw Pat_515B
	dw Pat_518A
	dw Pat_51C7
	dw Pat_5204
	dw Pat_5245
	dw Pat_5245
	ORDER_LOOP Song3_Ch1
Song3_Ch2:
	dw Pat_5280
	dw Pat_52BA
	dw Pat_5307
	dw Pat_5355
	dw Pat_539B
	dw Pat_539B
	ORDER_LOOP Song3_Ch2
Song3_Ch3:
	dw Pat_53B2
	dw Pat_5404
	dw Pat_5445
	dw Pat_548A
	dw Pat_54BD
	dw Pat_54BD
	ORDER_LOOP Song3_Ch3
Pat_515B:
	INSTR 6
	LEN 28
	NOTE C_, 3
	NOTE C_, 3
	NOTE G_, 2
	NOTE D_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE C_, 3
	NOTE E_, 4
	NOTE A_, 2
	LEN 14
	NOTE E_, 4
	NOTE G_, 2
	LEN 28
	NOTE F_, 2
	LEN 14
	NOTE F_, 4
	NOTE A_, 2
	LEN 28
	NOTE G_, 2
	NOTE B_, 2
	NOTE C_, 3
	NOTE E_, 4
	NOTE C_, 3
	NOTE C_, 3
	NOTE G_, 2
	NOTE D_, 4
	NOTE G_, 2
	NOTE G_, 2
	NOTE C_, 3
	NOTE E_, 4
	NOTE A_, 2
	LEN 14
	NOTE E_, 4
	NOTE G_, 2
	LEN 28
	NOTE F_, 2
	LEN 14
	NOTE F_, 4
	NOTE A_, 2
	LEN 28
	NOTE G_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	NEXT
Pat_518A:
	INSTR 6
	LEN 28
	NOTE C_, 3
	LEN 14
	NOTE G_, 4
	NOTE C_, 3
	LEN 28
	NOTE C_, 3
	NOTE G_, 4
	NOTE G_, 2
	LEN 14
	NOTE G_, 4
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	NOTE G_, 4
	NOTE F_, 2
	LEN 14
	NOTE C_, 4
	NOTE F_, 2
	LEN 28
	NOTE F_, 2
	NOTE C_, 4
	NOTE C_, 3
	LEN 14
	NOTE C_, 4
	NOTE C_, 3
	LEN 28
	NOTE C_, 3
	NOTE C_, 4
	NOTE F_, 2
	LEN 14
	NOTE D_, 4
	NOTE F_, 2
	LEN 28
	NOTE G_, 2
	NOTE D_, 4
	NOTE E_, 2
	LEN 14
	NOTE E_, 4
	NOTE E_, 2
	LEN 28
	NOTE A_, 2
	NOTE E_, 4
	NOTE D_, 3
	LEN 14
	NOTE Fsh, 4
	NOTE D_, 3
	LEN 28
	NOTE D_, 3
	NOTE Fsh, 4
	NOTE G_, 2
	LEN 14
	NOTE D_, 4
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE D_, 4
	NOTE D_, 4
	NEXT
Pat_51C7:
	INSTR 6
	LEN 28
	NOTE C_, 3
	LEN 14
	NOTE G_, 4
	NOTE C_, 3
	LEN 28
	NOTE C_, 3
	NOTE G_, 4
	NOTE G_, 2
	LEN 14
	NOTE G_, 4
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	NOTE G_, 4
	NOTE F_, 2
	LEN 14
	NOTE C_, 4
	NOTE F_, 2
	LEN 28
	NOTE F_, 2
	NOTE C_, 4
	NOTE C_, 3
	LEN 14
	NOTE C_, 4
	NOTE C_, 3
	LEN 28
	NOTE C_, 3
	NOTE C_, 4
	NOTE F_, 2
	LEN 14
	NOTE D_, 4
	NOTE F_, 2
	LEN 28
	NOTE G_, 2
	NOTE D_, 4
	NOTE E_, 2
	LEN 14
	NOTE E_, 4
	NOTE E_, 2
	LEN 28
	NOTE A_, 2
	NOTE E_, 4
	NOTE D_, 3
	LEN 14
	NOTE Fsh, 4
	NOTE D_, 3
	LEN 28
	NOTE D_, 3
	NOTE Fsh, 4
	NOTE G_, 2
	LEN 14
	NOTE D_, 4
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE D_, 4
	NOTE D_, 4
	NEXT
Pat_5204:
	INSTR 6
	LEN 28
	NOTE C_, 2
	LEN 14
	NOTE E_, 4
	NOTE C_, 2
	LEN 28
	NOTE C_, 2
	NOTE E_, 4
	NOTE C_, 2
	LEN 14
	NOTE E_, 4
	NOTE C_, 2
	LEN 28
	NOTE C_, 2
	NOTE E_, 4
	NOTE C_, 2
	LEN 14
	NOTE E_, 4
	NOTE C_, 2
	LEN 28
	NOTE F_, 2
	LEN 14
	NOTE F_, 4
	NOTE F_, 2
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE G_, 4
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	NOTE G_, 4
	NOTE D_, 2
	LEN 14
	NOTE Fsh, 4
	NOTE D_, 2
	LEN 28
	NOTE D_, 2
	NOTE Fsh, 4
	NOTE D_, 2
	LEN 14
	NOTE Fsh, 4
	NOTE D_, 2
	LEN 28
	NOTE D_, 2
	NOTE Fsh, 4
	NOTE D_, 2
	LEN 14
	NOTE Fsh, 4
	NOTE D_, 2
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE G_, 4
	NOTE G_, 2
	LEN 28
	NOTE A_, 2
	LEN 14
	NOTE A_, 4
	NOTE A_, 2
	LEN 28
	NOTE A_, 2
	NOTE A_, 4
	NEXT
Pat_5245:
	INSTR 6
	LEN 28
	NOTE F_, 2
	LEN 14
	NOTE F_, 4
	NOTE F_, 2
	LEN 28
	NOTE F_, 2
	NOTE F_, 4
	NOTE F_, 2
	LEN 14
	NOTE F_, 4
	NOTE F_, 2
	LEN 28
	NOTE F_, 2
	NOTE F_, 4
	NOTE Dsh, 2
	LEN 14
	NOTE Dsh, 4
	NOTE Dsh, 2
	LEN 28
	NOTE Dsh, 2
	NOTE Dsh, 4
	NOTE Dsh, 2
	LEN 14
	NOTE Dsh, 4
	NOTE Dsh, 2
	LEN 28
	NOTE Dsh, 2
	NOTE Dsh, 4
	NOTE Ash, 2
	LEN 14
	NOTE D_, 4
	NOTE Ash, 2
	LEN 28
	NOTE Ash, 2
	NOTE D_, 4
	NOTE Ash, 2
	LEN 14
	NOTE D_, 4
	NOTE Ash, 2
	LEN 28
	NOTE Ash, 2
	NOTE D_, 4
	NOTE Ash, 2
	LEN 14
	NOTE Csh, 4
	NOTE Ash, 2
	LEN 28
	NOTE Ash, 2
	NOTE Csh, 4
	NOTE Csh, 2
	LEN 14
	NOTE Dsh, 4
	NOTE Csh, 2
	LEN 28
	NOTE Csh, 2
	NOTE Dsh, 4
	NEXT
Pat_5280:
	LENGTH $46
	WAIT
	INSTR 6
	LEN 14
	NOTE G_, 3
	LENGTH $62
	NOTE B_, 3
	LEN 14
	NOTE G_, 3
	LEN 42
	NOTE C_, 4
	LEN 14
	NOTE A_, 3
	LEN 42
	NOTE C_, 4
	LEN 14
	NOTE A_, 3
	LEN 42
	NOTE D_, 4
	LEN 14
	NOTE G_, 3
	LEN 28
	NOTE B_, 3
	LEN 14
	NOTE C_, 4
	NOTE G_, 3
	LENGTH $62
	NOTE C_, 4
	LEN 14
	NOTE G_, 3
	LENGTH $62
	NOTE B_, 3
	LEN 14
	NOTE G_, 3
	LEN 42
	NOTE C_, 4
	LEN 14
	NOTE A_, 3
	LEN 42
	NOTE C_, 4
	LEN 14
	NOTE A_, 3
	LEN 42
	NOTE D_, 4
	LEN 14
	NOTE G_, 3
	LEN 28
	NOTE B_, 3
	LEN 14
	NOTE C_, 4
	NOTE G_, 3
	LEN 28
	NOTE C_, 3
	NEXT
Pat_52BA:
	LEN 14
	WAIT
	INSTR 6
	NOTE C_, 4
	NOTE E_, 4
	LEN 28
	NOTE C_, 4
	LEN 14
	NOTE C_, 4
	LEN 42
	NOTE E_, 4
	LEN 14
	NOTE B_, 3
	NOTE D_, 4
	LEN 28
	NOTE B_, 3
	LEN 14
	NOTE B_, 3
	LEN 42
	NOTE D_, 4
	LEN 14
	NOTE A_, 3
	NOTE F_, 4
	LEN 28
	NOTE A_, 3
	LEN 14
	NOTE A_, 3
	LEN 42
	NOTE F_, 4
	LEN 14
	NOTE G_, 3
	NOTE E_, 4
	LEN 28
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 42
	NOTE E_, 4
	LEN 14
	NOTE A_, 3
	NOTE F_, 4
	LEN 28
	NOTE A_, 3
	LEN 14
	NOTE B_, 3
	NOTE F_, 4
	LEN 28
	NOTE B_, 3
	LEN 14
	NOTE B_, 3
	NOTE G_, 4
	LEN 28
	NOTE B_, 3
	LEN 14
	NOTE C_, 4
	NOTE G_, 4
	LEN 28
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	NOTE A_, 4
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE D_, 4
	NOTE A_, 4
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE B_, 3
	NOTE G_, 4
	NOTE B_, 3
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 4
	NEXT
Pat_5307:
	LEN 14
	WAIT
	INSTR 6
	NOTE C_, 4
	NOTE E_, 4
	LEN 28
	NOTE C_, 4
	LEN 14
	NOTE C_, 4
	LEN 42
	NOTE E_, 4
	LEN 14
	NOTE B_, 3
	NOTE D_, 4
	LEN 28
	NOTE B_, 3
	LEN 14
	NOTE B_, 3
	LEN 42
	NOTE D_, 4
	LEN 14
	NOTE A_, 3
	NOTE F_, 4
	LEN 28
	NOTE A_, 3
	LEN 14
	NOTE A_, 3
	LEN 42
	NOTE F_, 4
	LEN 14
	NOTE G_, 3
	NOTE E_, 4
	LEN 28
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 42
	NOTE E_, 4
	LEN 14
	NOTE A_, 3
	NOTE F_, 4
	LEN 28
	NOTE A_, 3
	LEN 14
	NOTE B_, 3
	NOTE F_, 4
	LEN 28
	NOTE B_, 3
	LEN 14
	NOTE B_, 3
	NOTE G_, 4
	LEN 28
	NOTE B_, 3
	LEN 14
	NOTE C_, 4
	NOTE G_, 4
	LEN 28
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	NOTE A_, 4
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE D_, 4
	NOTE A_, 4
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE B_, 3
	NOTE G_, 4
	NOTE B_, 3
	LEN 28
	NOTE G_, 3
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	NEXT
Pat_5355:
	LEN 14
	WAIT
	INSTR 6
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	LEN 28
	NOTE C_, 3
	LEN 42
	NOTE C_, 4
	LEN 14
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	LEN 28
	NOTE C_, 3
	LEN 42
	NOTE C_, 4
	LEN 14
	NOTE G_, 3
	NOTE C_, 4
	LEN 28
	NOTE G_, 3
	LEN 14
	NOTE A_, 3
	NOTE C_, 4
	LEN 28
	NOTE A_, 3
	LEN 14
	NOTE B_, 3
	NOTE D_, 4
	NOTE B_, 3
	LEN 28
	NOTE G_, 3
	LEN 42
	NOTE D_, 4
	LEN 14
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 3
	LEN 28
	NOTE D_, 3
	LEN 42
	NOTE D_, 4
	LEN 14
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 3
	LEN 28
	NOTE D_, 3
	LEN 42
	NOTE D_, 4
	LEN 14
	NOTE A_, 3
	NOTE D_, 4
	LEN 28
	NOTE A_, 3
	LEN 14
	NOTE B_, 3
	NOTE D_, 4
	LEN 28
	NOTE B_, 3
	LEN 14
	NOTE Csh, 4
	NOTE E_, 4
	NOTE Csh, 4
	LEN 28
	NOTE A_, 3
	NOTE E_, 4
	NEXT
Pat_539B:
	LEN 28
	WAIT
	INSTR 6
	LENGTH $38
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 28
	NOTE G_, 4
	NEXT
Pat_53B2:
	DRUMS $0E, DrumPat_5501
	VOLENV 13, $11, $1F, $13
	VIBRATO $0E, $01, $04
	WAVE Wave_725F
	LEN 28
	NOTE C_, 5
	LEN 14
	NOTE B_, 4
	NOTE C_, 5
	LENGTH $38
	NOTE D_, 5
	LEN 28
	NOTE D_, 5
	LEN 14
	NOTE C_, 5
	NOTE D_, 5
	LENGTH $38
	NOTE E_, 5
	LEN 28
	NOTE E_, 5
	LEN 14
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE F_, 5
	LEN 28
	NOTE G_, 5
	NOTE D_, 5
	LENGTH $38
	NOTE E_, 5
	LEN 28
	NOTE C_, 5
	LEN 14
	NOTE B_, 4
	NOTE C_, 5
	LENGTH $38
	NOTE D_, 5
	LEN 28
	NOTE D_, 5
	LEN 14
	NOTE C_, 5
	NOTE D_, 5
	LENGTH $38
	NOTE E_, 5
	LEN 28
	NOTE E_, 5
	LEN 14
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE F_, 5
	LEN 28
	NOTE G_, 5
	LEN 14
	NOTE G_, 5
	NOTE B_, 4
	LEN 28
	NOTE C_, 5
	LEN 14
	NOTE E_, 5
	NOTE G_, 5
	NEXT
Pat_5404:
	LEN 28
	NOTE C_, 6
	NOTE C_, 6
	NOTE C_, 6
	NOTE G_, 5
	LEN 14
	NOTE B_, 5
	NOTE C_, 6
	NOTE B_, 5
	NOTE A_, 5
	LEN 28
	NOTE G_, 5
	NOTE E_, 5
	NOTE A_, 5
	LEN 14
	NOTE A_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE A_, 5
	LEN 28
	NOTE G_, 5
	NOTE F_, 5
	LEN 42
	NOTE E_, 5
	LEN 14
	NOTE E_, 5
	LEN 28
	NOTE D_, 5
	LEN 14
	NOTE D_, 5
	NOTE A_, 5
	LEN 42
	NOTE G_, 5
	LEN 14
	NOTE F_, 5
	LEN 28
	NOTE E_, 5
	LEN 14
	NOTE E_, 5
	NOTE B_, 5
	LEN 42
	NOTE A_, 5
	LEN 14
	NOTE G_, 5
	LEN 28
	NOTE Fsh, 5
	LEN 14
	NOTE A_, 5
	NOTE D_, 6
	LEN 28
	NOTE C_, 6
	LEN 14
	NOTE A_, 5
	NOTE C_, 6
	LEN 28
	NOTE B_, 5
	LEN 14
	NOTE C_, 6
	NOTE Csh, 6
	LENGTH $38
	NOTE D_, 6
	NEXT
Pat_5445:
	LEN 14
	NOTE E_, 6
	WAIT2
	NOTE E_, 6
	WAIT2
	LEN 28
	NOTE E_, 6
	LEN 14
	NOTE C_, 6
	WAIT2
	NOTE D_, 6
	NOTE E_, 6
	NOTE D_, 6
	NOTE C_, 6
	LEN 28
	NOTE B_, 5
	LEN 14
	NOTE G_, 5
	WAIT2
	NOTE C_, 6
	WAIT2
	NOTE C_, 6
	NOTE B_, 5
	NOTE C_, 6
	NOTE D_, 6
	NOTE E_, 6
	NOTE C_, 6
	NOTE C_, 6
	WAIT2
	NOTE A_, 5
	WAIT2
	LEN 42
	NOTE G_, 5
	LEN 14
	NOTE E_, 5
	NOTE D_, 5
	WAIT2
	NOTE D_, 5
	NOTE A_, 5
	LEN 42
	NOTE G_, 5
	LEN 14
	NOTE F_, 5
	NOTE E_, 5
	WAIT2
	NOTE E_, 5
	NOTE B_, 5
	LEN 42
	NOTE A_, 5
	LEN 14
	NOTE G_, 5
	NOTE Fsh, 5
	WAIT2
	NOTE A_, 5
	NOTE D_, 6
	LEN 28
	NOTE C_, 6
	LEN 14
	NOTE A_, 5
	NOTE C_, 6
	NOTE B_, 5
	WAIT2
	NOTE C_, 6
	NOTE D_, 6
	LEN 42
	NOTE G_, 5
	LEN 14
	WAIT2
	NEXT
Pat_548A:
	VOLENV 10, $00, $00, $00
	WAVE Wave_729F
	LEN 42
	NOTE E_, 5
	NOTE F_, 5
	LEN 28
	NOTE G_, 5
	NOTE C_, 6
	NOTE G_, 5
	NOTE F_, 5
	NOTE D_, 5
	LEN 14
	NOTE E_, 5
	NOTE F_, 5
	LENGTH $38
	NOTE G_, 5
	LEN 14
	NOTE G_, 5
	NOTE A_, 5
	LENGTH $38
	NOTE G_, 5
	NOTE D_, 5
	LEN 42
	NOTE Fsh, 5
	NOTE G_, 5
	LEN 28
	NOTE A_, 5
	NOTE D_, 6
	NOTE A_, 5
	NOTE G_, 5
	NOTE Fsh, 5
	LEN 14
	NOTE E_, 5
	NOTE A_, 5
	LEN 28
	NOTE Fsh, 5
	NOTE G_, 5
	LEN 14
	NOTE A_, 5
	NOTE B_, 5
	LENGTH $70
	NOTE A_, 5
	NEXT
Pat_54BD:
	VOLENV 12, $11, $1F, $13
	WAVE Wave_725F
	LEN 28
	NOTE A_, 5
	LEN 14
	NOTE G_, 5
	NOTE F_, 5
	LENGTH $54
	NOTE C_, 6
	LEN 14
	NOTE F_, 5
	NOTE G_, 5
	LEN 28
	NOTE A_, 5
	NOTE C_, 6
	NOTE A_, 5
	LEN 14
	NOTE G_, 5
	NOTE F_, 5
	LENGTH $54
	NOTE C_, 6
	LEN 14
	NOTE F_, 5
	NOTE G_, 5
	LEN 28
	NOTE A_, 5
	NOTE C_, 6
	LEN 14
	NOTE D_, 6
	NOTE C_, 6
	NOTE Ash, 5
	NOTE C_, 6
	LENGTH $46
	NOTE Ash, 5
	LEN 14
	NOTE F_, 5
	NOTE Ash, 5
	NOTE C_, 6
	NOTE D_, 6
	NOTE C_, 6
	NOTE Ash, 5
	NOTE C_, 6
	NOTE Csh, 6
	NOTE C_, 6
	NOTE Ash, 5
	LEN 28
	NOTE C_, 6
	NOTE Ash, 5
	LEN 14
	NOTE F_, 5
	LEN 28
	NOTE A_, 5
	LEN 14
	NOTE A_, 5
	LEN 28
	NOTE G_, 5
	NOTE F_, 5
	LEN 14
	NOTE C_, 5
	NEXT
DrumPat_5501:
	db DRUM_LEVEL + 12, 1, 6, 9, 1, 1, 6, 9
	db 6, DRUM_LOOP

; Song 4: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong4:
	ld a, $5A
	ld [wInstrTableHi], a
	ld a, $38
	ld [wInstrTable], a
	call StopAll
	ld de, Song4_Ch3
	call StartMusicCh3
	ld de, Song4_Ch1
	call StartMusicCh1
	ld de, Song4_Ch2
	jp StartMusicCh2
Song4_Ch3:
	dw Pat_5578
	dw Pat_55A4
	dw Pat_55CE
	dw Pat_55F7
	dw Pat_5620
	dw Pat_5649
	dw Pat_5620
	dw Pat_5672
	dw Pat_569B
	dw Pat_56AF
	dw Pat_56D8
	ORDER_LOOP Song4_Ch3
Song4_Ch1:
	dw Pat_5700
	dw Pat_571B
	dw Pat_5739
	dw Pat_5766
	dw Pat_5795
	dw Pat_57B7
	dw Pat_5795
	dw Pat_57D4
	dw Pat_5801
	dw Pat_580C
	dw Pat_583F
	ORDER_LOOP Song4_Ch1
Song4_Ch2:
	dw Pat_5874
	dw Pat_58A3
	dw Pat_58CF
	dw Pat_5904
	dw Pat_5938
	dw Pat_5964
	dw Pat_5938
	dw Pat_5997
	dw Pat_59C9
	dw Pat_59D6
	dw Pat_5A09
	ORDER_LOOP Song4_Ch2
Pat_5578:
	CH_TRANSPOSE $0C
	INSTR 0
	LEN 20
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE D_, 4
	INSTR 0
	NOTE G_, 2
	NOTE C_, 2
	INSTR 3
	LEN 40
	NOTE C_, 4
	NEXT
Pat_55A4:
	INSTR 0
	LEN 20
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 3
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 3
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	LEN 40
	NOTE C_, 4
	NEXT
Pat_55CE:
	INSTR 0
	LEN 20
	NOTE F_, 2
	INSTR 3
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 3
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 3
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 3
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 3
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	NEXT
Pat_55F7:
	INSTR 0
	LEN 20
	NOTE F_, 2
	INSTR 3
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 3
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 3
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 3
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 3
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	NEXT
Pat_5620:
	INSTR 0
	LEN 20
	NOTE F_, 2
	INSTR 3
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 3
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 3
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	NOTE F_, 2
	NOTE E_, 2
	NEXT
Pat_5649:
	INSTR 0
	LEN 20
	NOTE D_, 2
	INSTR 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	NEXT
Pat_5672:
	INSTR 0
	LEN 20
	NOTE D_, 2
	INSTR 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 4
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 4
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	NEXT
Pat_569B:
	INSTR 0
	LEN 20
	NOTE F_, 2
	INSTR 3
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 3
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	LENGTH $3C
	NOTE F_, 2
	LEN 40
	NOTE G_, 2
	LEN 20
	NOTE A_, 2
	NEXT
Pat_56AF:
	INSTR 0
	LEN 20
	NOTE Ash, 2
	INSTR 3
	NOTE Ash, 4
	NOTE Ash, 4
	INSTR 0
	NOTE F_, 2
	INSTR 3
	NOTE Ash, 4
	NOTE Ash, 4
	INSTR 0
	NOTE F_, 2
	INSTR 3
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 3
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 3
	NOTE C_, 5
	NOTE C_, 5
	INSTR 0
	NOTE G_, 2
	INSTR 3
	NOTE C_, 5
	NOTE C_, 5
	INSTR 0
	NOTE F_, 2
	INSTR 3
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	NOTE Dsh, 2
	NOTE F_, 2
	NOTE A_, 2
	NEXT
Pat_56D8:
	INSTR 0
	LEN 20
	NOTE Ash, 2
	INSTR 3
	NOTE Ash, 4
	NOTE Ash, 4
	INSTR 0
	NOTE F_, 2
	INSTR 3
	NOTE Ash, 4
	NOTE Ash, 4
	INSTR 0
	NOTE F_, 2
	INSTR 3
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 3
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 3
	NOTE C_, 5
	NOTE C_, 5
	INSTR 0
	NOTE G_, 2
	INSTR 3
	NOTE C_, 5
	NOTE C_, 5
	INSTR 0
	NOTE F_, 2
	NOTE C_, 2
	NOTE E_, 2
	NOTE F_, 2
	INSTR 3
	NOTE F_, 4
	NOTE F_, 4
	NEXT
Pat_5700:
	INSTR 1
	LENGTH $3C
	NOTE C_, 5
	NOTE G_, 4
	LEN 20
	NOTE Csh, 4
	LEN 30
	NOTE D_, 4
	LEN 10
	NOTE D_, 4
	LEN 20
	NOTE Dsh, 4
	LEN 40
	NOTE E_, 4
	LENGTH $3C
	NOTE C_, 5
	NOTE G_, 4
	LEN 20
	NOTE D_, 4
	NOTE A_, 4
	NOTE G_, 4
	LENGTH $3C
	NOTE C_, 4
	NEXT
Pat_571B:
	INSTR 1
	LENGTH $3C
	NOTE C_, 5
	NOTE G_, 4
	LEN 20
	NOTE E_, 4
	LEN 40
	NOTE F_, 4
	LEN 20
	NOTE Fsh, 4
	LEN 40
	NOTE G_, 4
	LENGTH $3C
	NOTE C_, 5
	LEN 40
	NOTE A_, 4
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	NOTE C_, 5
	LEN 20
	NOTE D_, 5
	NOTE B_, 4
	LENGTH $3C
	NOTE C_, 5
	NEXT
Pat_5739:
	INSTR 1
	LEN 40
	NOTE F_, 4
	LEN 20
	NOTE G_, 4
	LEN 30
	NOTE A_, 4
	LEN 10
	NOTE G_, 4
	LEN 20
	NOTE F_, 4
	LEN 40
	NOTE E_, 4
	LEN 20
	NOTE F_, 4
	LEN 30
	NOTE G_, 4
	LEN 10
	NOTE F_, 4
	LEN 20
	NOTE E_, 4
	LEN 10
	NOTE D_, 4
	NOTE Csh, 4
	LEN 20
	NOTE D_, 4
	NOTE F_, 4
	LEN 10
	NOTE D_, 4
	NOTE Csh, 4
	LEN 20
	NOTE D_, 4
	NOTE F_, 4
	LEN 10
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	LEN 20
	NOTE Ash, 4
	NOTE G_, 4
	NOTE E_, 4
	NEXT
Pat_5766:
	INSTR 1
	LEN 10
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE Gsh, 4
	LEN 20
	NOTE A_, 4
	NOTE A_, 5
	NOTE C_, 5
	LEN 10
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE Fsh, 4
	LEN 20
	NOTE G_, 4
	NOTE C_, 6
	NOTE G_, 5
	LEN 10
	NOTE B_, 4
	NOTE Ash, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE B_, 4
	NOTE Ash, 4
	NOTE B_, 4
	NOTE C_, 5
	LEN 20
	NOTE D_, 5
	NOTE B_, 4
	LEN 10
	NOTE C_, 5
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	LEN 20
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NEXT
Pat_5795:
	INSTR 1
	LEN 20
	NOTE A_, 4
	LEN 10
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Gsh, 4
	LEN 20
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	LENGTH $64
	NOTE G_, 4
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	LEN 20
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	LENGTH $64
	NOTE F_, 4
	NEXT
Pat_57B7:
	INSTR 1
	LEN 20
	NOTE F_, 4
	LEN 10
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 20
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	LENGTH $64
	NOTE D_, 4
	LENGTH $3C
	NOTE C_, 4
	NOTE Ash, 3
	NOTE A_, 3
	LEN 10
	NOTE G_, 3
	NOTE A_, 3
	LEN 20
	NOTE Ash, 3
	NOTE C_, 4
	NEXT
Pat_57D4:
	INSTR 1
	LEN 20
	NOTE F_, 4
	LEN 10
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 20
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	LENGTH $46
	NOTE D_, 4
	LEN 10
	NOTE C_, 4
	NOTE G_, 4
	NOTE D_, 5
	LEN 30
	NOTE C_, 5
	LEN 10
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	LEN 30
	NOTE Ash, 4
	LEN 10
	NOTE D_, 4
	NOTE F_, 4
	NOTE Ash, 4
	LEN 30
	NOTE A_, 4
	LEN 10
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 20
	NOTE Ash, 4
	NOTE C_, 5
	NEXT
Pat_5801:
	INSTR 1
	LENGTH $3C
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 5
	LEN 40
	NOTE E_, 5
	LEN 20
	NOTE Dsh, 5
	NEXT
Pat_580C:
	INSTR 1
	LEN 10
	NOTE D_, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE E_, 5
	LEN 20
	NOTE Dsh, 5
	NOTE C_, 5
	LEN 10
	NOTE F_, 5
	NOTE Dsh, 5
	NEXT
Pat_583F:
	INSTR 1
	LEN 10
	NOTE D_, 5
	NOTE F_, 5
	NOTE Ash, 5
	NOTE C_, 6
	NOTE Ash, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE F_, 5
	NOTE Ash, 5
	NOTE C_, 6
	NOTE Ash, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE F_, 5
	LEN 20
	NOTE E_, 5
	LEN 10
	NOTE E_, 5
	LEN 20
	NOTE D_, 5
	LEN 10
	NOTE D_, 5
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE C_, 5
	LEN 20
	NOTE Ash, 4
	LEN 10
	NOTE Ash, 4
	NOTE F_, 5
	NOTE A_, 5
	LEN 20
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	WAIT
	LEN 10
	NOTE A_, 5
	NOTE Ash, 5
	NEXT
Pat_5874:
	DRUMS $0A, DrumPat_5A78
	VIBRATO $0A, $01, $05
	INSTR 1
	LEN 10
	NOTE C_, 6
	NOTE B_, 5
	NOTE C_, 6
	NOTE D_, 6
	LEN 20
	NOTE C_, 6
	NOTE G_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE Csh, 5
	LEN 30
	NOTE D_, 5
	LEN 10
	NOTE D_, 5
	LEN 20
	NOTE Dsh, 5
	LEN 30
	NOTE E_, 5
	LEN 10
	NOTE G_, 5
	NOTE C_, 6
	NOTE B_, 5
	NOTE C_, 6
	NOTE D_, 6
	LEN 20
	NOTE C_, 6
	NOTE G_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE A_, 5
	NOTE G_, 5
	LEN 40
	NOTE C_, 5
	LEN 20
	NOTE G_, 5
	NEXT
Pat_58A3:
	INSTR 1
	LEN 10
	NOTE C_, 6
	NOTE B_, 5
	NOTE C_, 6
	NOTE D_, 6
	LEN 20
	NOTE C_, 6
	NOTE G_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE Csh, 5
	LEN 30
	NOTE D_, 5
	LEN 10
	NOTE D_, 5
	LEN 20
	NOTE Dsh, 5
	LEN 30
	NOTE E_, 5
	LEN 10
	NOTE G_, 5
	NOTE C_, 6
	NOTE B_, 5
	NOTE C_, 6
	NOTE D_, 6
	LEN 20
	NOTE C_, 6
	NOTE A_, 5
	NOTE F_, 5
	NOTE A_, 5
	LEN 10
	NOTE G_, 5
	NOTE A_, 5
	LEN 20
	NOTE B_, 5
	NOTE G_, 5
	LEN 40
	NOTE C_, 6
	INSTR 2
	LEN 10
	NOTE C_, 6
	NOTE B_, 5
	NEXT
Pat_58CF:
	INSTR 2
	LEN 10
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	NOTE C_, 6
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	WAIT2
	NOTE C_, 6
	WAIT2
	LEN 20
	NOTE F_, 5
	LEN 10
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	WAIT2
	NOTE C_, 6
	WAIT2
	LEN 20
	NOTE E_, 5
	LEN 10
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	WAIT2
	NOTE A_, 5
	WAIT2
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE Fsh, 5
	NOTE A_, 5
	WAIT
	NOTE G_, 5
	WAIT
	WAIT
	WAIT2
	NEXT
Pat_5904:
	INSTR 2
	LEN 10
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	NOTE C_, 6
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	WAIT2
	NOTE C_, 6
	WAIT2
	LEN 20
	NOTE F_, 5
	LEN 10
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	WAIT2
	NOTE E_, 6
	WAIT2
	LEN 20
	NOTE C_, 6
	LEN 10
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE B_, 5
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE B_, 5
	WAIT2
	NOTE G_, 5
	WAIT2
	NOTE C_, 6
	NOTE G_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE G_, 5
	LENGTH $32
	NOTE C_, 5
	LEN 10
	WAIT2
	NEXT
Pat_5938:
	INSTR 1
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	LEN 20
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	LEN 10
	NOTE Ash, 4
	NOTE D_, 5
	NOTE G_, 5
	NOTE Ash, 5
	LENGTH $3C
	NOTE D_, 6
	LEN 20
	NOTE Ash, 4
	LEN 10
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	LEN 20
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	LEN 10
	NOTE A_, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE A_, 5
	LENGTH $3C
	NOTE C_, 6
	NEXT
Pat_5964:
	INSTR 1
	LEN 20
	NOTE A_, 4
	LEN 10
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Gsh, 4
	LEN 20
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	LEN 10
	NOTE G_, 4
	NOTE Ash, 4
	NOTE D_, 5
	NOTE G_, 5
	LEN 20
	NOTE Ash, 5
	LEN 10
	NOTE G_, 5
	NOTE C_, 5
	NOTE G_, 5
	NOTE D_, 6
	LEN 30
	NOTE C_, 6
	LEN 10
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	LEN 30
	NOTE Ash, 5
	LEN 10
	NOTE D_, 5
	NOTE F_, 5
	NOTE Ash, 5
	LEN 30
	NOTE A_, 5
	LEN 10
	NOTE C_, 5
	NOTE F_, 5
	NOTE A_, 5
	LEN 20
	NOTE G_, 5
	NOTE E_, 5
	LEN 10
	NOTE C_, 5
	NOTE B_, 4
	NEXT
Pat_5997:
	INSTR 1
	LEN 20
	NOTE A_, 4
	LEN 10
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Gsh, 4
	LEN 20
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	LEN 10
	NOTE G_, 4
	NOTE Ash, 4
	NOTE D_, 5
	NOTE G_, 5
	LEN 20
	NOTE Ash, 5
	LEN 10
	NOTE G_, 5
	NOTE C_, 5
	NOTE G_, 5
	NOTE D_, 6
	LEN 30
	NOTE C_, 6
	LEN 10
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	LEN 30
	NOTE Ash, 5
	LEN 10
	NOTE D_, 5
	NOTE F_, 5
	NOTE Ash, 5
	LEN 30
	NOTE A_, 5
	LEN 10
	NOTE C_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE A_, 5
	LEN 20
	NOTE Ash, 5
	NOTE C_, 6
	NEXT
Pat_59C9:
	INSTR 1
	LENGTH $78
	NOTE F_, 5
	INSTR 2
	LENGTH $3C
	NOTE F_, 4
	LEN 40
	NOTE E_, 4
	LEN 20
	NOTE Dsh, 4
	NEXT
Pat_59D6:
	INSTR 2
	LEN 10
	NOTE D_, 5
	NOTE F_, 5
	NOTE Ash, 5
	NOTE C_, 6
	NOTE Ash, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE F_, 5
	NOTE Ash, 5
	NOTE C_, 6
	NOTE Ash, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE C_, 6
	NOTE G_, 5
	NOTE E_, 5
	NOTE C_, 6
	NOTE G_, 5
	NOTE E_, 5
	NOTE Ash, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE Ash, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	NOTE C_, 6
	NOTE D_, 6
	NOTE C_, 6
	NOTE F_, 6
	NOTE E_, 6
	LEN 20
	NOTE Dsh, 6
	NOTE C_, 6
	LEN 10
	NOTE A_, 5
	NOTE G_, 5
	NEXT
Pat_5A09:
	INSTR 2
	LEN 10
	NOTE F_, 5
	NOTE Ash, 5
	NOTE D_, 6
	NOTE Dsh, 6
	NOTE D_, 6
	NOTE Ash, 5
	NOTE F_, 5
	NOTE Ash, 5
	NOTE D_, 6
	NOTE Dsh, 6
	NOTE D_, 6
	NOTE Ash, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE C_, 6
	NOTE D_, 6
	NOTE C_, 6
	NOTE A_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE C_, 6
	NOTE D_, 6
	NOTE C_, 6
	NOTE A_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE G_, 5
	NOTE F_, 5
	NOTE C_, 6
	NOTE F_, 5
	NOTE E_, 5
	NOTE C_, 6
	NOTE E_, 5
	NOTE D_, 5
	NOTE Ash, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE C_, 6
	NOTE F_, 5
	WAIT2
	NOTE E_, 5
	WAIT2
	LEN 40
	NOTE F_, 5
	LEN 20
	WAIT2
	NEXT

; Instrument table 1, entries 1..5 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr1_0
	dw Instr1_1
	dw Instr1_2
	dw Instr1_3
	dw Instr1_4
Instr1_0:
	VOLENV 12, $11, $1F, $14
	ARP 0
	WAVE Wave_720F
	END
Instr1_1:
	HWENV $A1, $05, $85
	DUTY_50
	RELEASE $00
	VIBRATO $0A, $01, $04
	END
Instr1_2:
	HWENV $69, $05, $A0
	DUTY_75
	RELEASE $01, $63
	VIBRATO $0A, $01, $05
	END
Instr1_3:
	VOLENV 15, $11, $1A, $12
	ARP 2
	WAVE Wave_73BF
	END
Instr1_4:
	VOLENV 15, $11, $1A, $12
	ARP 1
	WAVE Wave_73BF
	END
DrumPat_5A78:
	db DRUM_LEVEL + 12, 1, 6, 5, 6, 5, 6, 9
	db 6, 5, 6, 5, 4, 1, 6, 5
	db 6, 5, 6, 9, 6, 5, 6, 1
	db 6, 1, 6, 5, 6, 5, 6, 9
	db 6, 5, 6, 5, 4, 1, 6, 5
	db 6, 5, 6, 9, 6, 3, 6, 3
	db 6, DRUM_LOOP

; Song 5: instrument table 2, arpeggio table 1 (the one SndInit sets)
PlaySong5:
	ld a, $5E
	ld [wInstrTableHi], a
	ld a, $C8
	ld [wInstrTable], a
	call StopAll
	ld de, Song5_Ch3
	call StartMusicCh3
	ld de, Song5_Ch2
	call StartMusicCh2
	ld de, Song5_Ch1
	jp StartMusicCh1
Song5_Ch3:
	dw Pat_5AF3
	dw Pat_5B68
	dw Pat_5AF3
	dw Pat_5BDA
	dw Pat_5C0E
	ORDER_LOOP Song5_Ch3
Song5_Ch2:
	dw Pat_5C84
	dw Pat_5CCB
	dw Pat_5C84
	dw Pat_5D0D
	dw Pat_5D4F
	ORDER_LOOP Song5_Ch2
Song5_Ch1:
	dw Pat_5D95
	dw Pat_5DDF
	dw Pat_5D95
	dw Pat_5E2A
	dw Pat_5E74
	ORDER_LOOP Song5_Ch1
Pat_5AF3:
	CH_TRANSPOSE $0C
	DRUMS $0E, DrumPat_5EC1
	INSTR 1
	LEN 28
	NOTE D_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE D_, 2
	LEN 28
	NOTE G_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE G_, 2
	LEN 28
	NOTE A_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE A_, 2
	LEN 28
	NOTE D_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE D_, 2
	LEN 28
	NOTE C_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE C_, 2
	LEN 28
	NOTE G_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE G_, 2
	LEN 28
	NOTE A_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE A_, 2
	LEN 28
	NOTE D_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE D_, 2
	LEN 28
	NOTE D_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE D_, 2
	LEN 28
	NOTE G_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE G_, 2
	LEN 28
	NOTE A_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE A_, 2
	LEN 28
	NOTE D_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE D_, 2
	LEN 28
	NOTE C_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE C_, 2
	LEN 28
	NOTE G_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE G_, 2
	LEN 28
	NOTE D_, 2
	INSTR 0
	NOTE F_, 3
	INSTR 1
	NOTE G_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE A_, 2
	NEXT
Pat_5B68:
	INSTR 1
	LEN 28
	NOTE B_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE B_, 2
	LEN 28
	NOTE Fsh, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE Fsh, 2
	LEN 28
	NOTE E_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE E_, 2
	LEN 28
	NOTE B_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE B_, 2
	LEN 28
	NOTE B_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE B_, 2
	LEN 28
	NOTE Fsh, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE Fsh, 2
	LEN 28
	NOTE E_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE E_, 2
	LEN 28
	NOTE B_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE B_, 2
	LEN 28
	NOTE D_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE D_, 2
	LEN 28
	NOTE A_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE A_, 2
	LEN 28
	NOTE G_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE G_, 2
	LEN 28
	NOTE D_, 3
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE D_, 3
	LEN 28
	NOTE B_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE B_, 2
	LEN 28
	NOTE Fsh, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE Fsh, 2
	LEN 28
	NOTE B_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE B_, 2
	LEN 28
	NOTE Fsh, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE B_, 2
	NEXT
Pat_5BDA:
	DRUMS $1C, DrumPat_5EBE
	INSTR 1
	LEN 28
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	LEN 14
	NOTE A_, 2
	NOTE B_, 2
	NOTE C_, 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	LEN 28
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	NOTE B_, 2
	NOTE G_, 2
	NOTE B_, 2
	NOTE Fsh, 2
	NOTE B_, 2
	LEN 28
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	LEN 14
	NOTE A_, 2
	NOTE B_, 2
	LEN 28
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NEXT
Pat_5C0E:
	DRUMS $0E, DrumPat_5EC1
	INSTR 1
	LEN 28
	NOTE G_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE G_, 2
	LEN 28
	NOTE C_, 3
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE C_, 3
	LEN 28
	NOTE D_, 3
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE D_, 3
	LEN 28
	NOTE G_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE G_, 2
	LEN 28
	NOTE A_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE A_, 2
	LEN 28
	NOTE A_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE A_, 2
	LEN 28
	NOTE D_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE D_, 2
	LEN 28
	NOTE D_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE D_, 2
	LEN 28
	NOTE G_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE G_, 2
	LEN 28
	NOTE C_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE C_, 2
	LEN 28
	NOTE D_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE D_, 2
	LEN 28
	NOTE G_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE Fsh, 2
	LEN 28
	NOTE E_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE E_, 2
	LEN 28
	NOTE A_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE A_, 2
	LEN 28
	NOTE D_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE D_, 2
	LEN 28
	NOTE D_, 2
	INSTR 0
	LEN 14
	NOTE F_, 3
	INSTR 1
	NOTE D_, 2
	NEXT
Pat_5C84:
	HWENV $C1, $00
	ARP 0
	DUTY_12
	LEN 14
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE A_, 3
	NOTE Csh, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE E_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE D_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE E_, 4
	NOTE Csh, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE A_, 3
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE A_, 3
	NOTE Csh, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE E_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE D_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE D_, 4
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 3
	NOTE A_, 3
	NEXT
Pat_5CCB:
	LEN 14
	NOTE B_, 3
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE B_, 4
	NOTE Fsh, 3
	NOTE B_, 3
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE E_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE E_, 4
	NOTE E_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE E_, 4
	NOTE B_, 3
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE B_, 4
	NOTE Fsh, 3
	NOTE B_, 3
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE E_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE E_, 4
	NOTE E_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE E_, 4
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE B_, 4
	NOTE B_, 3
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE B_, 4
	NOTE B_, 3
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE B_, 4
	NOTE B_, 3
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE B_, 4
	NEXT
Pat_5D0D:
	LEN 14
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE A_, 3
	NOTE E_, 3
	NOTE A_, 3
	NOTE E_, 3
	NOTE A_, 3
	NOTE E_, 3
	NOTE A_, 3
	NOTE E_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 3
	NEXT
Pat_5D4F:
	CH_TRANSPOSE $0C
	LEN 14
	NOTE B_, 4
	LEN 28
	NOTE G_, 4
	LEN 14
	NOTE D_, 4
	LEN 42
	NOTE E_, 4
	LEN 14
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Fsh, 4
	LEN 28
	NOTE D_, 4
	NOTE B_, 4
	NOTE C_, 5
	LEN 14
	NOTE B_, 4
	NOTE A_, 4
	LEN 28
	NOTE E_, 4
	NOTE A_, 4
	LEN 14
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE B_, 4
	LEN 28
	NOTE G_, 4
	LEN 14
	NOTE D_, 4
	LEN 42
	NOTE E_, 4
	LEN 14
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Fsh, 4
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE B_, 4
	NOTE A_, 4
	LEN 28
	NOTE G_, 4
	NOTE G_, 4
	LEN 14
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE E_, 4
	LEN 28
	NOTE A_, 4
	NOTE A_, 4
	LENGTH $38
	NOTE A_, 4
	CH_TRANSPOSE $00
	NEXT
Pat_5D95:
	RELEASE $00
	HWENV $F1, $07, $77
	DUTY_50
	VIBRATO $1C, $01, $05
	LEN 28
	NOTE D_, 5
	NOTE A_, 4
	LEN 42
	NOTE B_, 4
	LEN 14
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE E_, 4
	LEN 42
	NOTE Fsh, 4
	LEN 14
	NOTE D_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE E_, 4
	NOTE D_, 4
	NOTE B_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE B_, 4
	LENGTH $38
	NOTE A_, 4
	LEN 14
	NOTE D_, 5
	NOTE D_, 5
	NOTE A_, 4
	NOTE A_, 4
	LEN 42
	NOTE B_, 4
	LEN 14
	NOTE G_, 4
	LEN 28
	NOTE A_, 4
	LEN 14
	NOTE A_, 4
	NOTE E_, 4
	LEN 42
	NOTE Fsh, 4
	LEN 14
	NOTE D_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE E_, 4
	NOTE D_, 4
	NOTE B_, 4
	NOTE B_, 4
	NOTE G_, 4
	LEN 28
	NOTE A_, 4
	NOTE D_, 5
	LENGTH $38
	NOTE G_, 4
	NEXT
Pat_5DDF:
	LEN 14
	WAIT
	HWENV $79, $05, $B0
	RELEASE $01, $82
	DUTY_75
	NOTE B_, 4
	NOTE Dsh, 5
	NOTE E_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE A_, 5
	LEN 28
	NOTE G_, 5
	LEN 14
	NOTE Fsh, 5
	NOTE G_, 5
	LEN 28
	NOTE E_, 5
	LEN 42
	NOTE B_, 4
	LEN 14
	WAIT2
	NOTE B_, 4
	NOTE Dsh, 5
	NOTE E_, 5
	NOTE Fsh, 5
	LEN 28
	NOTE B_, 4
	LEN 14
	NOTE B_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE A_, 5
	LENGTH $46
	NOTE G_, 5
	LEN 14
	WAIT2
	NOTE D_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE B_, 5
	NOTE C_, 6
	LEN 28
	NOTE B_, 5
	LEN 14
	NOTE A_, 5
	NOTE B_, 5
	LEN 28
	NOTE G_, 5
	NOTE D_, 5
	LEN 14
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	LENGTH $46
	NOTE A_, 5
	LEN 14
	NOTE B_, 5
	NOTE A_, 5
	NOTE B_, 5
	NOTE C_, 6
	LENGTH $38
	NOTE B_, 5
	LEN 14
	WAIT2
	NEXT
Pat_5E2A:
	HWENV $79, $05, $B0
	RELEASE $01, $82
	DUTY_12
	LEN 28
	NOTE B_, 4
	LEN 14
	WAIT2
	LEN 28
	NOTE G_, 5
	LEN 14
	WAIT2
	NOTE B_, 4
	WAIT2
	LENGTH $54
	NOTE C_, 5
	LEN 28
	WAIT2
	NOTE D_, 5
	LEN 14
	WAIT2
	LEN 28
	NOTE A_, 5
	LEN 14
	NOTE Fsh, 5
	NOTE D_, 5
	WAIT2
	NOTE C_, 5
	NOTE D_, 5
	LENGTH $38
	NOTE B_, 4
	LEN 28
	WAIT2
	LEN 14
	NOTE E_, 5
	NOTE Fsh, 5
	LEN 42
	NOTE G_, 5
	LEN 14
	WAIT2
	NOTE B_, 4
	WAIT2
	NOTE E_, 5
	NOTE Fsh, 5
	LEN 42
	NOTE G_, 5
	LEN 14
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE A_, 5
	NOTE B_, 5
	LEN 28
	NOTE C_, 6
	LEN 14
	WAIT2
	NOTE G_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE A_, 5
	NOTE E_, 5
	NOTE A_, 5
	NOTE D_, 5
	NOTE A_, 5
	NOTE C_, 5
	NOTE D_, 5
	NEXT
Pat_5E74:
	CH_TRANSPOSE $F4
	LEN 14
	NOTE B_, 5
	NOTE G_, 5
	WAIT2
	NOTE D_, 5
	LEN 42
	NOTE E_, 5
	LEN 14
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE Fsh, 5
	LEN 28
	NOTE D_, 5
	LEN 14
	NOTE B_, 5
	WAIT2
	LEN 28
	NOTE C_, 6
	LEN 14
	NOTE B_, 5
	NOTE A_, 5
	LEN 28
	NOTE E_, 5
	LEN 14
	NOTE A_, 5
	WAIT2
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE D_, 6
	NOTE E_, 6
	NOTE D_, 6
	NOTE B_, 5
	NOTE G_, 5
	WAIT2
	NOTE D_, 5
	LEN 42
	NOTE E_, 5
	LEN 14
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE Fsh, 5
	LEN 28
	NOTE D_, 5
	LEN 14
	NOTE B_, 5
	NOTE A_, 5
	NOTE G_, 5
	WAIT2
	NOTE G_, 5
	WAIT2
	NOTE E_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE A_, 5
	WAIT2
	NOTE A_, 5
	WAIT2
	LEN 42
	NOTE A_, 5
	LEN 14
	WAIT2
	CH_TRANSPOSE $00
	NEXT
DrumPat_5EBE:
	db DRUM_LEVEL + 14, 4, DRUM_LOOP
DrumPat_5EC1:
	db 1, 6, 9, 1, 1, 6, 9, 6
	db DRUM_LOOP

; Instrument table 2, entries 1..2 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr2_0
	dw Instr2_1
Instr2_0:
	VOLENV 15, $10, $1F, $11
	GLIDE $FE
	WAVE Wave_72FF
	END
Instr2_1:
	VOLENV 13, $11, $1F, $13
	ARP 0
	WAVE Wave_72CF
	END

; Song 6: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong6:
	ld a, $5A
	ld [wInstrTableHi], a
	ld a, $38
	ld [wInstrTable], a
	call StopAll
	ld de, Song6_Ch3
	call StartMusicCh3
	ld de, Song6_Ch2
	call StartMusicCh2
	ld de, Song6_Ch1
	jp StartMusicCh1
Song6_Ch3:
	dw Pat_5F2A
	dw Pat_5F90
	dw Pat_5FF0
	dw Pat_6007
	dw Pat_6061
	ORDER_LOOP Song6_Ch3
Song6_Ch2:
	dw Pat_60BB
	dw Pat_6107
	dw Pat_614F
	dw Pat_615E
	dw Pat_61A4
	ORDER_LOOP Song6_Ch2
Song6_Ch1:
	dw Pat_61EA
	dw Pat_622C
	dw Pat_6266
	dw Pat_626D
	dw Pat_62A1
	ORDER_LOOP Song6_Ch1
Pat_5F2A:
	DRUMS $0D, DrumPat_62D1
	CH_TRANSPOSE $0C
	INSTR 0
	LEN 26
	NOTE A_, 2
	INSTR 3
	LEN 13
	NOTE A_, 4
	INSTR 0
	NOTE A_, 2
	LEN 26
	NOTE A_, 2
	INSTR 3
	NOTE A_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 3
	LEN 13
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	LEN 26
	NOTE E_, 2
	INSTR 3
	NOTE E_, 4
	INSTR 0
	NOTE Fsh, 2
	INSTR 4
	LEN 13
	NOTE Fsh, 4
	INSTR 0
	NOTE Fsh, 2
	LEN 26
	NOTE Fsh, 2
	INSTR 4
	NOTE Fsh, 4
	INSTR 0
	NOTE A_, 2
	INSTR 3
	LEN 13
	NOTE A_, 4
	INSTR 0
	NOTE A_, 2
	LEN 26
	NOTE E_, 2
	INSTR 3
	LEN 13
	NOTE A_, 4
	INSTR 0
	NOTE E_, 2
	LEN 26
	NOTE A_, 2
	INSTR 3
	LEN 13
	NOTE A_, 4
	INSTR 0
	NOTE A_, 2
	LEN 26
	NOTE A_, 2
	INSTR 3
	NOTE A_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 3
	LEN 13
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	LEN 26
	NOTE E_, 2
	INSTR 3
	NOTE E_, 4
	INSTR 0
	NOTE Fsh, 2
	INSTR 4
	LEN 13
	NOTE Fsh, 4
	INSTR 0
	NOTE Fsh, 2
	LEN 26
	NOTE Fsh, 2
	INSTR 4
	NOTE Fsh, 4
	INSTR 0
	NOTE D_, 2
	INSTR 4
	LEN 13
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	LEN 26
	NOTE E_, 2
	INSTR 3
	LEN 13
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	NEXT
Pat_5F90:
	INSTR 0
	LEN 26
	NOTE A_, 2
	INSTR 3
	LEN 13
	NOTE A_, 4
	INSTR 0
	NOTE A_, 2
	LEN 26
	NOTE A_, 2
	INSTR 3
	NOTE A_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 3
	LEN 13
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	LEN 26
	NOTE E_, 2
	INSTR 3
	NOTE E_, 4
	INSTR 0
	NOTE Fsh, 2
	INSTR 4
	LEN 13
	NOTE Fsh, 4
	INSTR 0
	NOTE Fsh, 2
	LEN 26
	NOTE Fsh, 2
	INSTR 4
	NOTE Fsh, 4
	INSTR 0
	NOTE A_, 2
	INSTR 3
	LEN 13
	NOTE A_, 4
	INSTR 0
	NOTE A_, 2
	LEN 26
	NOTE E_, 2
	INSTR 3
	LEN 13
	NOTE A_, 4
	INSTR 0
	NOTE E_, 2
	LEN 26
	NOTE A_, 2
	INSTR 3
	LEN 13
	NOTE A_, 4
	INSTR 0
	NOTE A_, 2
	LEN 26
	NOTE A_, 2
	INSTR 3
	NOTE A_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 3
	LEN 13
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	LEN 26
	NOTE E_, 2
	INSTR 3
	NOTE E_, 4
	INSTR 0
	NOTE Fsh, 2
	INSTR 4
	LEN 13
	NOTE Fsh, 4
	INSTR 0
	NOTE Fsh, 2
	LEN 26
	NOTE Fsh, 2
	INSTR 4
	NOTE Fsh, 4
	INSTR 0
	NOTE D_, 2
	INSTR 4
	LEN 13
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	LEN 26
	NOTE E_, 2
	INSTR 3
	LEN 13
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	NEXT
Pat_5FF0:
	INSTR 0
	LEN 26
	NOTE A_, 2
	INSTR 3
	LEN 13
	NOTE A_, 3
	INSTR 0
	NOTE A_, 2
	LEN 26
	NOTE A_, 2
	INSTR 3
	NOTE A_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 3
	LEN 13
	NOTE A_, 3
	INSTR 0
	NOTE A_, 2
	LEN 26
	NOTE A_, 2
	NOTE E_, 2
	NEXT
Pat_6007:
	INSTR 0
	LEN 26
	NOTE Fsh, 2
	INSTR 4
	LEN 13
	NOTE Fsh, 4
	INSTR 0
	NOTE Fsh, 2
	LEN 26
	NOTE Fsh, 2
	INSTR 4
	NOTE Fsh, 4
	INSTR 0
	NOTE D_, 2
	INSTR 3
	LEN 13
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	LEN 26
	NOTE D_, 2
	INSTR 3
	NOTE D_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 3
	LEN 13
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	LEN 26
	NOTE E_, 2
	INSTR 3
	NOTE E_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 3
	LEN 13
	NOTE A_, 4
	INSTR 0
	NOTE A_, 2
	LEN 26
	NOTE A_, 2
	INSTR 3
	NOTE A_, 4
	INSTR 0
	NOTE Fsh, 2
	INSTR 4
	LEN 13
	NOTE Fsh, 4
	INSTR 0
	NOTE Fsh, 2
	LEN 26
	NOTE Fsh, 2
	INSTR 4
	NOTE Fsh, 4
	INSTR 0
	NOTE D_, 2
	INSTR 3
	LEN 13
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	LEN 26
	NOTE D_, 2
	INSTR 3
	NOTE D_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 3
	LEN 13
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	LEN 26
	NOTE E_, 2
	INSTR 3
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 3
	LEN 13
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	LEN 26
	NOTE E_, 2
	INSTR 3
	NOTE E_, 4
	NEXT
Pat_6061:
	INSTR 0
	LEN 26
	NOTE Fsh, 2
	INSTR 4
	LEN 13
	NOTE Fsh, 4
	INSTR 0
	NOTE Fsh, 2
	LEN 26
	NOTE Fsh, 2
	INSTR 4
	NOTE Fsh, 4
	INSTR 0
	NOTE D_, 2
	INSTR 3
	LEN 13
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	LEN 26
	NOTE D_, 2
	INSTR 3
	NOTE D_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 3
	LEN 13
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	LEN 26
	NOTE E_, 2
	INSTR 3
	NOTE E_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 3
	LEN 13
	NOTE A_, 4
	INSTR 0
	NOTE A_, 2
	LEN 26
	NOTE A_, 2
	INSTR 3
	NOTE A_, 4
	INSTR 0
	NOTE Fsh, 2
	INSTR 4
	LEN 13
	NOTE Fsh, 4
	INSTR 0
	NOTE Fsh, 2
	LEN 26
	NOTE Fsh, 2
	INSTR 4
	NOTE Fsh, 4
	INSTR 0
	NOTE D_, 2
	INSTR 3
	LEN 13
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	LEN 26
	NOTE D_, 2
	INSTR 3
	NOTE D_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 3
	LEN 13
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	LEN 26
	NOTE E_, 2
	INSTR 3
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 3
	LEN 13
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	LEN 26
	NOTE E_, 2
	INSTR 3
	NOTE E_, 4
	NEXT
Pat_60BB:
	HWENV $D2, $00
	DUTY_75
	LEN 13
	NOTE Csh, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE Csh, 4
	NOTE E_, 4
	LEN 26
	NOTE A_, 4
	LEN 13
	NOTE E_, 4
	NOTE B_, 3
	NOTE E_, 4
	NOTE Gsh, 4
	NOTE B_, 3
	NOTE E_, 4
	LEN 26
	NOTE Gsh, 4
	LEN 13
	NOTE E_, 4
	NOTE A_, 3
	NOTE Csh, 4
	NOTE Fsh, 4
	NOTE A_, 3
	NOTE Csh, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE Csh, 4
	NOTE E_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE E_, 4
	NOTE Csh, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE Csh, 4
	NOTE E_, 4
	LEN 26
	NOTE A_, 4
	LEN 13
	NOTE E_, 4
	NOTE B_, 3
	NOTE E_, 4
	NOTE Gsh, 4
	NOTE B_, 3
	NOTE E_, 4
	LEN 26
	NOTE Gsh, 4
	LEN 13
	NOTE E_, 4
	NOTE A_, 3
	NOTE Csh, 4
	NOTE Fsh, 4
	NOTE A_, 3
	NOTE Csh, 4
	LEN 26
	NOTE Fsh, 4
	LEN 13
	NOTE Csh, 4
	NOTE A_, 3
	NOTE D_, 4
	LEN 26
	NOTE Fsh, 4
	LEN 13
	NOTE E_, 4
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE E_, 4
	NEXT
Pat_6107:
	LEN 13
	NOTE Csh, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE Csh, 4
	NOTE E_, 4
	LEN 26
	NOTE A_, 4
	LEN 13
	NOTE E_, 4
	NOTE B_, 3
	NOTE E_, 4
	NOTE Gsh, 4
	NOTE B_, 3
	NOTE E_, 4
	LEN 26
	NOTE Gsh, 4
	LEN 13
	NOTE E_, 4
	NOTE A_, 3
	NOTE Csh, 4
	NOTE Fsh, 4
	NOTE A_, 3
	NOTE Csh, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE Csh, 4
	NOTE E_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE E_, 4
	NOTE Csh, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE Csh, 4
	NOTE E_, 4
	LEN 26
	NOTE A_, 4
	LEN 13
	NOTE E_, 4
	NOTE B_, 3
	NOTE E_, 4
	NOTE Gsh, 4
	NOTE B_, 3
	NOTE E_, 4
	LEN 26
	NOTE Gsh, 4
	LEN 13
	NOTE E_, 4
	NOTE A_, 3
	NOTE Csh, 4
	NOTE Fsh, 4
	NOTE A_, 3
	NOTE Csh, 4
	LEN 26
	NOTE Fsh, 4
	LEN 13
	NOTE Csh, 4
	NOTE A_, 3
	NOTE D_, 4
	LEN 26
	NOTE Fsh, 4
	LEN 13
	NOTE E_, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE E_, 3
	NEXT
Pat_614F:
	LEN 39
	NOTE Csh, 4
	NOTE D_, 4
	LEN 13
	NOTE D_, 4
	NOTE B_, 3
	LEN 39
	NOTE Csh, 4
	LEN 26
	NOTE A_, 3
	LEN 13
	NOTE E_, 3
	NOTE A_, 3
	NOTE Gsh, 3
	NEXT
Pat_615E:
	LEN 13
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE Csh, 4
	NOTE Fsh, 3
	NOTE A_, 3
	LEN 26
	NOTE Csh, 4
	LEN 13
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE Fsh, 3
	NOTE A_, 3
	LEN 26
	NOTE D_, 4
	LEN 13
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE E_, 4
	NOTE Gsh, 3
	NOTE B_, 3
	LEN 26
	NOTE E_, 4
	LEN 13
	NOTE Gsh, 3
	LEN 26
	NOTE B_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE Gsh, 3
	LEN 13
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE Csh, 4
	NOTE Fsh, 3
	NOTE A_, 3
	LEN 26
	NOTE Csh, 4
	LEN 13
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE Fsh, 3
	NOTE A_, 3
	LEN 26
	NOTE D_, 4
	LEN 13
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE E_, 4
	NOTE Gsh, 3
	NOTE B_, 3
	LEN 26
	NOTE E_, 4
	LEN 13
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE E_, 4
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE E_, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NEXT
Pat_61A4:
	LEN 13
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE Csh, 4
	NOTE Fsh, 3
	NOTE A_, 3
	LEN 26
	NOTE Csh, 4
	LEN 13
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE Fsh, 3
	NOTE A_, 3
	LEN 26
	NOTE D_, 4
	LEN 13
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE E_, 4
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE E_, 4
	NOTE Gsh, 4
	NOTE B_, 4
	LEN 26
	NOTE D_, 5
	LEN 13
	NOTE Csh, 5
	LEN 39
	NOTE Csh, 5
	LEN 26
	NOTE B_, 4
	LEN 13
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE Csh, 4
	NOTE A_, 4
	NOTE Fsh, 4
	LEN 26
	NOTE Csh, 4
	LEN 13
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE E_, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE E_, 4
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE E_, 3
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE E_, 3
	NOTE B_, 2
	NOTE E_, 3
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE E_, 4
	NEXT
Pat_61EA:
	HWENV $F2, $13, $67
	VIBRATO $14, $01, $05
	WAVE Wave_726F
	LEN 39
	NOTE Csh, 5
	LEN 13
	NOTE B_, 4
	LEN 26
	NOTE Csh, 5
	NOTE E_, 5
	LEN 39
	NOTE B_, 4
	LEN 13
	NOTE A_, 4
	LEN 26
	NOTE B_, 4
	NOTE E_, 5
	LEN 39
	NOTE A_, 4
	LEN 13
	NOTE Gsh, 4
	LEN 26
	NOTE A_, 4
	NOTE D_, 5
	LENGTH $34
	NOTE Csh, 5
	LEN 26
	NOTE B_, 4
	LEN 13
	NOTE A_, 4
	NOTE B_, 4
	LEN 39
	NOTE Csh, 5
	LEN 13
	NOTE B_, 4
	LEN 26
	NOTE Csh, 5
	NOTE E_, 5
	LEN 39
	NOTE B_, 4
	LEN 13
	NOTE A_, 4
	LEN 26
	NOTE B_, 4
	NOTE E_, 5
	LEN 39
	NOTE A_, 4
	LEN 13
	NOTE Gsh, 4
	LEN 26
	NOTE A_, 4
	NOTE D_, 5
	NOTE Csh, 5
	NOTE E_, 4
	NOTE B_, 4
	NOTE Csh, 5
	NEXT
Pat_622C:
	LEN 39
	NOTE Csh, 5
	LEN 13
	NOTE B_, 4
	LEN 26
	NOTE Csh, 5
	NOTE E_, 5
	LEN 39
	NOTE B_, 4
	LEN 13
	NOTE A_, 4
	LEN 26
	NOTE B_, 4
	NOTE E_, 5
	LEN 39
	NOTE A_, 4
	LEN 13
	NOTE Gsh, 4
	LEN 26
	NOTE A_, 4
	NOTE D_, 5
	LENGTH $34
	NOTE Csh, 5
	LEN 26
	NOTE B_, 4
	LEN 13
	NOTE A_, 4
	NOTE B_, 4
	LEN 39
	NOTE Csh, 5
	LEN 13
	NOTE B_, 4
	LEN 26
	NOTE Csh, 5
	NOTE E_, 5
	LEN 39
	NOTE B_, 4
	LEN 13
	NOTE A_, 4
	LEN 26
	NOTE B_, 4
	NOTE E_, 5
	LEN 39
	NOTE A_, 4
	LEN 13
	NOTE Gsh, 4
	LEN 26
	NOTE A_, 4
	NOTE D_, 5
	NOTE Csh, 5
	LEN 13
	NOTE B_, 4
	NOTE A_, 4
	LEN 26
	NOTE Gsh, 4
	NOTE E_, 4
	NEXT
Pat_6266:
	LENGTH $B6
	NOTE A_, 4
	LEN 13
	NOTE E_, 4
	NOTE D_, 4
	NEXT
Pat_626D:
	LEN 26
	NOTE Csh, 4
	NOTE Fsh, 4
	LEN 39
	NOTE Fsh, 4
	LEN 13
	NOTE Gsh, 4
	NOTE A_, 4
	LEN 26
	NOTE Gsh, 4
	LENGTH $34
	NOTE Fsh, 4
	LEN 13
	NOTE Fsh, 4
	LEN 26
	NOTE B_, 4
	NOTE B_, 4
	NOTE Gsh, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE Csh, 4
	LEN 39
	NOTE Csh, 4
	LEN 13
	NOTE D_, 4
	LEN 26
	NOTE Csh, 4
	NOTE Fsh, 4
	LEN 39
	NOTE Fsh, 4
	LEN 13
	NOTE Gsh, 4
	NOTE A_, 4
	LEN 26
	NOTE Gsh, 4
	LENGTH $34
	NOTE Fsh, 4
	LEN 13
	NOTE Fsh, 4
	LEN 26
	NOTE E_, 4
	NOTE E_, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE B_, 4
	LENGTH $34
	NOTE E_, 5
	NEXT
Pat_62A1:
	LEN 26
	NOTE Csh, 5
	NOTE Fsh, 5
	LEN 39
	NOTE Fsh, 5
	LEN 13
	NOTE Gsh, 5
	NOTE A_, 5
	LEN 26
	NOTE Gsh, 5
	LENGTH $34
	NOTE Fsh, 5
	LEN 13
	NOTE Fsh, 5
	LEN 26
	NOTE B_, 5
	NOTE B_, 5
	NOTE Gsh, 5
	NOTE E_, 5
	NOTE Fsh, 5
	LEN 13
	NOTE E_, 5
	LEN 39
	NOTE E_, 5
	LEN 26
	NOTE D_, 5
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE A_, 4
	NOTE Fsh, 4
	LEN 13
	NOTE Gsh, 4
	LEN 26
	NOTE A_, 4
	LEN 39
	NOTE B_, 4
	LEN 26
	NOTE Csh, 5
	LEN 39
	NOTE B_, 4
	NOTE E_, 5
	NOTE Gsh, 5
	NOTE B_, 5
	LENGTH $34
	NOTE E_, 6
	NEXT
DrumPat_62D1:
	db DRUM_LEVEL + 13, 1, 6, 9, 1, 1, 6, 9
	db 6, DRUM_LOOP

; Song 7: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong7:
	ld a, $68
	ld [wInstrTableHi], a
	ld a, $A5
	ld [wInstrTable], a
	call StopAll
	ld de, Song7_Ch3
	call StartMusicCh3
	ld de, Song7_Ch2
	call StartMusicCh2
	ld de, Song7_Ch1
	jp StartMusicCh1
Song7_Ch3:
	dw Pat_6312
	dw Pat_633E
	ORDER_LOOP Song7_Ch3
Song7_Ch2:
	dw Pat_6360
	dw Pat_6396
	ORDER_LOOP Song7_Ch2
Song7_Ch1:
	dw Pat_63D8
	dw Pat_6427
	ORDER_LOOP Song7_Ch1
Pat_6312:
	WAVE Wave_72FF
	VOLENV 15, $11, $1F, $13
	CH_TRANSPOSE $0C
	ARP 0
	LEN 28
	NOTE F_, 2
	NOTE F_, 3
	NOTE E_, 2
	NOTE E_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE E_, 2
	NOTE E_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE A_, 2
	NOTE A_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	NOTE F_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE F_, 2
	NOTE F_, 3
	NEXT
Pat_633E:
	LEN 28
	NOTE F_, 2
	NOTE C_, 3
	NOTE F_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE D_, 3
	NOTE G_, 2
	NOTE D_, 3
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE C_, 3
	NOTE F_, 2
	NOTE C_, 3
	NOTE D_, 2
	NOTE A_, 2
	NOTE D_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE Ash, 2
	NOTE G_, 2
	NOTE Ash, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE G_, 2
	NEXT
Pat_6360:
	HWENV $D3, $0E, $50
	DUTY_75
	VIBRATO $0E, $01, $05
	LENGTH $38
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 14
	NOTE E_, 4
	NOTE D_, 4
	LEN 28
	NOTE C_, 4
	LENGTH $38
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 14
	NOTE E_, 4
	NOTE G_, 4
	LEN 28
	NOTE C_, 5
	LENGTH $38
	NOTE D_, 5
	NOTE C_, 5
	NOTE Ash, 4
	LEN 28
	NOTE A_, 4
	LEN 14
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 28
	NOTE F_, 4
	NOTE E_, 4
	LENGTH $38
	NOTE F_, 4
	NEXT
Pat_6396:
	LEN 14
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE D_, 5
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE D_, 5
	NOTE Ash, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE E_, 4
	NEXT
Pat_63D8:
	HWENV $D3, $0E, $50
	DUTY_50
	VIBRATO $0E, $01, $05
	LEN 14
	NOTE A_, 5
	NOTE G_, 5
	LEN 28
	NOTE A_, 5
	LEN 14
	NOTE G_, 5
	NOTE F_, 5
	LEN 28
	NOTE G_, 5
	LEN 14
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE D_, 5
	LEN 28
	NOTE C_, 5
	LEN 14
	NOTE A_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE G_, 5
	LEN 28
	NOTE C_, 6
	LEN 14
	NOTE D_, 6
	NOTE C_, 6
	LEN 28
	NOTE D_, 6
	LEN 14
	NOTE C_, 6
	NOTE Ash, 5
	LEN 28
	NOTE C_, 6
	LEN 14
	NOTE Ash, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE C_, 6
	NOTE A_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE C_, 6
	NOTE Ash, 5
	NOTE A_, 5
	NOTE G_, 5
	LEN 28
	NOTE F_, 5
	NOTE E_, 5
	LENGTH $38
	NOTE F_, 5
	NEXT
Pat_6427:
	LEN 28
	NOTE A_, 5
	NOTE A_, 5
	NOTE F_, 5
	LEN 14
	NOTE G_, 5
	NOTE A_, 5
	LEN 28
	NOTE Ash, 5
	NOTE Ash, 5
	LENGTH $38
	NOTE G_, 5
	LEN 28
	NOTE G_, 5
	LEN 14
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	LEN 28
	NOTE A_, 5
	NOTE A_, 5
	LENGTH $38
	NOTE F_, 5
	LEN 28
	NOTE F_, 5
	NOTE F_, 5
	NOTE D_, 5
	LEN 14
	NOTE E_, 5
	NOTE F_, 5
	LEN 28
	NOTE G_, 5
	NOTE G_, 5
	LENGTH $38
	NOTE D_, 5
	LEN 28
	NOTE G_, 5
	NOTE G_, 5
	LEN 14
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	LEN 28
	NOTE G_, 5
	NOTE C_, 5
	LEN 42
	NOTE C_, 6
	LEN 14
	NOTE Ash, 5
	NEXT

; Song 8: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong8:
	ld a, $68
	ld [wInstrTableHi], a
	ld a, $A5
	ld [wInstrTable], a
	call StopAll
	ld de, Song8_Ch3
	call StartMusicCh3
	ld de, Song8_Ch2
	call StartMusicCh2
	ld de, Song8_Ch1
	jp StartMusicCh1
Song8_Ch3:
	dw Pat_6491
	ORDER_LOOP Song8_Ch3
Song8_Ch2:
	dw Pat_64C2
	ORDER_LOOP Song8_Ch2
Song8_Ch1:
	dw Pat_64EB
	ORDER_LOOP Song8_Ch1
Pat_6491:
	VOLENV 15, $11, $1A, $12
	WAVE Wave_728F
	LEN 16
	NOTE Fsh, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE Fsh, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE Csh, 4
	LEN 32
	NOTE D_, 4
	NOTE D_, 3
	LEN 16
	NOTE G_, 3
	NOTE B_, 3
	NOTE Csh, 4
	NOTE B_, 3
	LEN 32
	NOTE D_, 4
	NOTE D_, 3
	LEN 16
	NOTE Csh, 3
	NOTE A_, 2
	NOTE B_, 2
	NOTE Csh, 3
	NOTE D_, 3
	NOTE E_, 3
	NOTE Fsh, 3
	NOTE D_, 3
	LEN 32
	NOTE G_, 3
	LEN 16
	NOTE A_, 3
	NOTE G_, 3
	LEN 32
	NOTE Fsh, 3
	NOTE D_, 3
	NEXT
Pat_64C2:
	HWENV $F2, $08, $84
	DUTY_50
	LENGTH $80
	REST
	LEN 16
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LENGTH $40
	NOTE Fsh, 4
	LEN 16
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LENGTH $40
	NOTE Fsh, 4
	LEN 16
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	LEN 32
	NOTE D_, 4
	LENGTH $40
	NOTE D_, 4
	LEN 16
	NOTE Csh, 4
	NOTE Csh, 4
	LENGTH $40
	NOTE A_, 3
	NEXT
Pat_64EB:
	HWENV $F2, $08, $84
	DUTY_50
	LEN 16
	NOTE D_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	LEN 32
	NOTE A_, 4
	NOTE A_, 4
	LEN 16
	NOTE B_, 4
	NOTE B_, 4
	NOTE B_, 4
	NOTE B_, 4
	LENGTH $40
	NOTE A_, 4
	LEN 16
	NOTE B_, 4
	NOTE B_, 4
	NOTE B_, 4
	NOTE B_, 4
	LENGTH $40
	NOTE A_, 4
	LEN 16
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 32
	NOTE Fsh, 4
	NOTE Fsh, 4
	LEN 16
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	LENGTH $40
	NOTE D_, 4
	NEXT

; Song 9: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong9:
	ld a, $68
	ld [wInstrTableHi], a
	ld a, $A5
	ld [wInstrTable], a
	call StopAll
	ld de, Song9_Ch3
	call StartMusicCh3
	ld de, Song9_Ch2
	call StartMusicCh2
	ld de, Song9_Ch1
	jp StartMusicCh1
Song9_Ch3:
	dw Pat_6550
	dw Pat_658F

; Unreferenced (4 bytes)
	db $00, $00, $38, $65
Song9_Ch2:
	dw Pat_65C2
	dw Pat_65F9

; Unreferenced (4 bytes)
	db $00, $00, $40, $65
Song9_Ch1:
	dw Pat_662C
	dw Pat_6663

; Unreferenced (4 bytes)
	db $00, $00, $48, $65
Pat_6550:
	LEN 15
	WAVE Wave_72FF
	CH_TRANSPOSE $0C
	VIBRATO $14, $01, $06
	VOLENV 15, $11, $1F, $17
	REST
	REST
	NOTE C_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE D_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE G_, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 3
	WAIT
	WAIT
	WAIT
	NOTE B_, 2
	WAIT
	NOTE A_, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE D_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE G_, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE G_, 2
	WAIT
	WAIT
	WAIT
	NEXT
Pat_658F:
	WAIT
	WAIT
	NOTE C_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE D_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE G_, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 3
	WAIT
	WAIT
	WAIT
	NOTE B_, 2
	WAIT
	NOTE A_, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE D_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE G_, 2
	WAIT
	WAIT
	WAIT
	NOTE G_, 2
	WAIT
	LENGTH $FF
	NOTE C_, 2
	WAIT
	WAIT
	WAIT
	END
Pat_65C2:
	HWENV $A2, $0A, $67
	DUTY_75
	LEN 15
	REST
	REST
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NEXT
Pat_65F9:
	NOTE D_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 3
	LENGTH $FF
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	END
Pat_662C:
	HWENV $D4, $0F, $77
	DUTY_50
	LEN 15
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	WAIT
	NOTE C_, 6
	WAIT
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	WAIT
	NOTE B_, 5
	WAIT
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	WAIT
	NOTE B_, 5
	WAIT
	NOTE A_, 5
	WAIT
	NOTE A_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	WAIT
	NOTE A_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	WAIT
	NOTE B_, 5
	WAIT
	NOTE A_, 5
	WAIT
	NOTE G_, 5
	WAIT
	WAIT
	WAIT
	NEXT
Pat_6663:
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	WAIT
	NOTE C_, 6
	WAIT
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	WAIT
	NOTE B_, 5
	WAIT
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	WAIT
	NOTE B_, 5
	WAIT
	NOTE A_, 5
	WAIT
	NOTE A_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	WAIT
	NOTE A_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE B_, 4
	WAIT
	NOTE G_, 4
	WAIT
	LENGTH $FF
	NOTE C_, 5
	WAIT
	WAIT
	WAIT
	END

; Song 1: instrument table - (none set), arpeggio table 1 (the one SndInit sets)
; API song slots 1, 10, 11, 12 all start this routine
PlaySong1:
	call StopAll
	ld de, Song1_Ch1
	call StartMusicCh1
	ld de, Song1_Ch2
	call StartMusicCh2
	ld de, Song1_Ch3
	jp StartMusicCh3
Song1_Ch1:
	dw Pat_66CF
	dw Pat_66E6
	dw Pat_670B
	dw Pat_672D
	ORDER_LOOP Song1_Ch1
Song1_Ch2:
	dw Pat_674E
	dw Pat_6768
	dw Pat_6787
	dw Pat_67A9
	ORDER_LOOP Song1_Ch2
Song1_Ch3:
	dw Pat_67CB
	dw Pat_6812
	dw Pat_6847
	dw Pat_686E
	ORDER_LOOP Song1_Ch3
Pat_66CF:
	HWENV $F2, $00
	DUTY_50
	ARP 0
	LEN 40
	NOTE G_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 3
	NOTE G_, 3
	NEXT
Pat_66E6:
	LEN 20
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE E_, 4
	LEN 40
	NOTE B_, 3
	LEN 20
	NOTE G_, 3
	NOTE D_, 4
	NOTE E_, 3
	NOTE B_, 3
	NOTE D_, 3
	NOTE Fsh, 3
	LEN 40
	NOTE D_, 3
	LEN 20
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE E_, 4
	LEN 40
	NOTE B_, 3
	LEN 20
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 3
	NOTE A_, 3
	LEN 40
	NOTE G_, 3
	NEXT
Pat_670B:
	LEN 20
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NEXT
Pat_672D:
	LEN 20
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 3
	NOTE Fsh, 3
	LENGTH $50
	NOTE G_, 2
	NEXT
Pat_674E:
	HWENV $F2, $00
	DUTY_50
	ARP 0
	LEN 20
	REST
	LEN 40
	NOTE B_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE B_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	LENGTH $3C
	NOTE Fsh, 3
	NEXT
Pat_6768:
	LEN 20
	WAIT
	LEN 40
	NOTE B_, 3
	NOTE B_, 3
	LEN 20
	NOTE C_, 4
	NOTE D_, 4
	LEN 40
	NOTE A_, 3
	NOTE B_, 3
	NOTE G_, 3
	LEN 20
	NOTE A_, 3
	NOTE Fsh, 3
	LEN 40
	NOTE Fsh, 3
	NOTE B_, 3
	NOTE B_, 3
	LEN 20
	NOTE C_, 4
	NOTE D_, 4
	LEN 40
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	LEN 20
	NOTE Fsh, 3
	LEN 40
	NOTE B_, 3
	NEXT
Pat_6787:
	LEN 20
	NOTE G_, 4
	LEN 40
	NOTE E_, 4
	NOTE E_, 4
	LEN 20
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE G_, 4
	LEN 40
	NOTE D_, 4
	NOTE D_, 4
	LEN 20
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN 40
	NOTE A_, 3
	NOTE A_, 3
	LEN 20
	NOTE A_, 3
	NOTE B_, 3
	NOTE A_, 3
	NOTE E_, 4
	LEN 40
	NOTE G_, 3
	NOTE G_, 3
	LEN 20
	NOTE G_, 3
	NOTE D_, 4
	NOTE E_, 4
	NEXT
Pat_67A9:
	LEN 20
	NOTE G_, 4
	LEN 40
	NOTE E_, 4
	NOTE E_, 4
	LEN 20
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE G_, 4
	LEN 40
	NOTE D_, 4
	NOTE D_, 4
	LEN 20
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN 40
	NOTE A_, 3
	NOTE A_, 3
	LEN 20
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	LEN 40
	NOTE G_, 3
	LEN 20
	NOTE A_, 3
	LEN 40
	NOTE B_, 3
	NOTE D_, 3
	NEXT
Pat_67CB:
	DRUMS $0A, DrumPat_6894
	VOLENV 13, $10, $1F, $14
	RELEASE $01, $05
	VIBRATO $0F, $01, $05
	WAVE Wave_726F
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	NOTE A_, 4
	LEN 20
	NOTE B_, 4
	NOTE D_, 5
	NOTE C_, 5
	NOTE E_, 5
	LEN 30
	NOTE D_, 5
	LEN 10
	NOTE C_, 5
	LEN 20
	NOTE B_, 4
	LEN 10
	NOTE A_, 4
	NOTE G_, 4
	LEN 20
	NOTE E_, 4
	NOTE G_, 4
	LEN 40
	NOTE Fsh, 4
	LEN 30
	NOTE D_, 4
	LEN 10
	NOTE D_, 4
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	NOTE A_, 4
	LEN 20
	NOTE B_, 4
	NOTE D_, 5
	NOTE C_, 5
	NOTE E_, 5
	LEN 30
	NOTE D_, 5
	LEN 10
	NOTE E_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE C_, 5
	LEN 20
	NOTE B_, 4
	NOTE A_, 4
	LEN 40
	NOTE A_, 4
	NOTE G_, 4
	NEXT
Pat_6812:
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	NOTE A_, 4
	LEN 20
	NOTE B_, 4
	NOTE D_, 5
	NOTE C_, 5
	NOTE E_, 5
	LEN 30
	NOTE D_, 5
	LEN 10
	NOTE C_, 5
	LEN 20
	NOTE B_, 4
	LEN 10
	NOTE A_, 4
	NOTE G_, 4
	LEN 20
	NOTE E_, 4
	NOTE G_, 4
	LEN 40
	NOTE Fsh, 4
	LEN 30
	NOTE D_, 4
	LEN 10
	NOTE D_, 4
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	NOTE A_, 4
	LEN 20
	NOTE B_, 4
	NOTE D_, 5
	NOTE C_, 5
	NOTE E_, 5
	LEN 30
	NOTE D_, 5
	LEN 10
	NOTE E_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE C_, 5
	LEN 20
	NOTE B_, 4
	NOTE A_, 4
	LEN 40
	NOTE A_, 4
	NOTE G_, 4
	NEXT
Pat_6847:
	LEN 20
	NOTE E_, 5
	LEN 10
	NOTE E_, 5
	NOTE Fsh, 5
	LEN 20
	NOTE G_, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE D_, 5
	LENGTH $50
	NOTE B_, 4
	LEN 20
	NOTE A_, 4
	NOTE D_, 5
	NOTE D_, 5
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	LEN 10
	NOTE E_, 4
	NOTE G_, 4
	LEN 20
	NOTE C_, 5
	NOTE B_, 4
	LEN 40
	NOTE G_, 4
	NOTE D_, 5
	NEXT
Pat_686E:
	LEN 20
	NOTE E_, 5
	LEN 10
	NOTE E_, 5
	NOTE Fsh, 5
	LEN 20
	NOTE G_, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE D_, 5
	LENGTH $50
	NOTE B_, 4
	LEN 20
	NOTE A_, 4
	NOTE D_, 5
	NOTE D_, 5
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	LENGTH $3C
	NOTE G_, 3
	LEN 20
	NOTE D_, 4
	NEXT
DrumPat_6894:
	db DRUM_REPEAT + 3, 6, 0, 6, 0, 4, 0, 6
	db 0, DRUM_REPEAT_END, 6, 0, 6, 0, 4, 0
	db 6, 6, DRUM_LOOP

; Instrument table 3, entries 1..10 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr3_0
	dw Instr3_1
	dw Instr3_2
	dw Instr3_3
	dw Instr3_4
	dw Instr3_5
	dw Instr3_6
	dw Instr3_7
	dw Instr3_8
	dw Instr3_9

; Unreferenced (10 bytes)
	db $13, $69, $1A, $69, $20, $69, $25, $69, $2D, $69
Instr3_0:
	HWENV $F3, $00
	DUTY_75
	END
Instr3_1:
	VOLENV 15, $11, $1F, $11
	ARP 18
	WAVE Wave_72FF
	END
Instr3_2:
	HWENV $F2, $04, $75
	DUTY_50
	ARP 0
	END
Instr3_3:
	HWENV $C2, $04, $72
	DUTY_75
	ARP 12
	END
Instr3_4:
	VOLENV 13, $11, $1F, $12
	ARP 5
	WAVE Wave_73BF
	END
Instr3_5:
	VOLENV 13, $11, $1F, $12
	ARP 6
	WAVE Wave_73BF
	END
Instr3_6:
	HWENV $C2, $0A, $56
	END
Instr3_7:
	VOLENV 13, $11, $1F, $12
	WAVE Wave_71DF
	END

; Unreferenced (6 bytes)
	db $BB, $11, $1F, $14, $93, $68
Instr3_8:
	HWENV $B1, $00
	ARP 0
	END
Instr3_9:
	VOLENV 15, $11, $2F, $11
	WAVE Wave_730F
	END

; Unreferenced (32 bytes)
	db $74, $D1, $06, $62, $9F, $73, $68, $74, $F2, $07, $62, $93, $68, $74, $F2, $00
	db $71, $68, $B4, $18, $1F, $1A, $79, $1F, $72, $68, $BB, $11, $1F, $1F, $93, $68
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

; Unreferenced (18 bytes)
	db $0C, $6A, $0C, $6A, $0F, $6A, $0F, $6A, $0F, $6A, $0F, $6A, $0F, $6A, $0F, $6A
	db $0F, $6A
Arp0:
	db $0C, $00, ARP_HOLD
Arp3:
	db $00, $00, $01, $01, $02, ARP_HOLD
Arp2:
	db $00, $00, $04, $04, $07, $07, ARP_LOOP
Arp1:
	db $00, $00, $03, $03, $07, $07, ARP_LOOP
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

; Unreferenced (66 bytes)
	db $00, $0C, $6A, $12, $00, $00, $00, $00, $00, $00, $00, $00, $0C, $00, $00, $00
	db $00, $00, $00, $00, $00, $06, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $6A, $4D, $6A, $4D, $6A, $4D, $6A, $4D, $6A, $4D, $6A, $4D
	db $6A, $4D, $6A, $4D, $6A, $4D, $6A, $4D, $6A, $4D, $6A, $4D, $6A, $4D, $6A, $4D
SfxTable_m2:
	db $6A, $68

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
	dw Sfx02
	dw Sfx03
	dw Sfx35
	dw Sfx36
	dw Sfx37
	dw Sfx12
	dw Sfx11
	dw Sfx40
	dw Sfx41
	dw Sfx42
	dw Sfx43
	dw Sfx14
	dw Sfx45
	dw Sfx46
	dw Sfx41
	dw Sfx03
	dw Sfx02
	dw Sfx35
	dw Sfx51
	dw Sfx52
	dw Sfx53
	dw Sfx26
	dw Sfx55
	dw Sfx56
	dw Sfx57
	dw Sfx01
	dw Sfx59
	dw Sfx60
	dw Sfx13

; Sound effect 25
Sfx25:
	VOLENV 15, $00, $00, $00
	ARP 20
	CH_TRANSPOSE $08
	WAVE Wave_737F
	LEN 13
	GLIDE $01
	NOTE E_, 3
	LEN 4
	GLIDE $FF
	WAIT
	END

; Sound effect 23
Sfx23:
	VOLENV 15, $11, $1F, $12
	CH_TRANSPOSE $05
	WAVE Wave_726F
	LEN 6
	NOTE G_, 5
	NOTE D_, 5
	NOTE G_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE A_, 5
	NOTE B_, 5
	NOTE Fsh, 5
	NOTE B_, 4
	NOTE D_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	LEN 30
	NOTE D_, 6
	END

; Sound effect 21
Sfx21:
	CALL_CODE Code_6DDA
	VOLENV 15, $11, $1F, $13
	WAVE Wave_73BF
	VIBRATO $01, $07, $02
	PORTA $02, $1E
	LEN 35
	NOTE D_, 6
	LEN 1
	NOTE C_, 1
	END

; Sound effect 22
Sfx22:
	VOLENV 15, $11, $1F, $12
	WAVE Wave_726F
	GLIDE $FF
	LEN 4
	NOTE E_, 3
	LEN 10
	GLIDE $01
	WAIT
	END

; Sound effect 16
Sfx16:
	WAVE Wave_726F
	VOLENV 15, $00, $1F, $11
	GLIDE $FB
	LEN 5
	NOTE E_, 4
	GLIDE $02
	NOTE E_, 4
	END

; Sound effect 17
Sfx17:
	WAVE Wave_726F
	VOLENV 15, $00, $1F, $11
	LEN 5
	GLIDE $FE
	NOTE E_, 5
	GLIDE $FB
	NOTE E_, 4
	END

; Sound effect 10
Sfx10:
	VOLENV 15, $11, $1F, $12
	WAVE Wave_726F
	LEN 7
	NOTE C_, 7
	NOTE D_, 7
	NOTE E_, 7
	NOTE F_, 7
	LEN 30
	NOTE G_, 7
	END

; Sound effect 9
Sfx09:
	CALL_CODE Code_6EC3
	END

; Sound effect 4
Sfx04:
	VOLENV 15, $11, $1F, $13
	LEN 40
	WAVE Wave_730F
	NOTE C_, 6
	END

; Sound effect 5
Sfx05:
	VOLENV 15, $11, $1F, $13
	LEN 40
	WAVE Wave_730F
	NOTE D_, 6
	END

; Sound effect 6
Sfx06:
	VOLENV 15, $11, $1F, $13
	LEN 40
	WAVE Wave_730F
	NOTE E_, 6
	END

; Sound effect 7
Sfx07:
	VOLENV 15, $11, $1F, $13
	LEN 40
	WAVE Wave_730F
	NOTE F_, 6
	END

; Sound effect 8
Sfx08:
	VOLENV 15, $11, $1F, $13
	LEN 40
	WAVE Wave_730F
	NOTE G_, 6
	END

; Sound effect 11
Sfx11:
	LEN 10
	VOLENV 15, $11, $1F, $11
	GLIDE $01
	WAVE Wave_726F
	NOTE Ash, 3
	END

; Sound effect 2
Sfx02:
	VOLENV 15, $11, $2F, $11
	WAVE Wave_728F
	LEN 13
	NOTE C_, 6
	END

; Sound effect 3
Sfx03:
	LEN 4
	VOLENV 15, $11, $2F, $11
	WAVE Wave_728F
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
	WAVE Wave_730F
	VOLENV 15, $10, $1F, $12
	RELEASE $02, $55
	NOTE C_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	END

; Sound effect 14
Sfx14:
	CALL_CODE Code_6FB7
	VOLENV 10, $11, $1F, $11
	WAVE Wave_726F
	LEN 10
	ARP 5
	GLIDE $01
	NOTE A_, 3
	END

; Sound effect 18
Sfx18:
	VOLENV 15, $11, $1F, $12
	WAVE Wave_726F
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

; Sound effect 19
Sfx19:
	VOLENV 15, $11, $1F, $12
	CH_TRANSPOSE $F5
	WAVE Wave_726F
	LEN 7
	NOTE B_, 6
	NOTE Dsh, 7
	NOTE Csh, 7
	NOTE E_, 7
	NOTE Dsh, 7
	LEN 30
	NOTE Fsh, 7
	END

; Sound effect 20
Sfx20:
	VOLENV 15, $11, $1F, $12
	WAVE Wave_726F
	LEN 7
	NOTE C_, 6
	NOTE C_, 7
	LEN 30
	NOTE G_, 6
	END

; Sound effect 24
Sfx24:
	VOLENV 15, $00, $00, $00
	WAVE Wave_735F
	LEN 5
	NOTE A_, 3
	LEN 3
	REST
	LEN 20
	NOTE A_, 3
	END

; Sound effect 40
Sfx40:
	CALL_CODE Code_6E47
	END

; Sound effect 36
Sfx36:
	LEN 5
	VOLENV 15, $00, $00, $00
	WAVE Wave_726F
	CALL_CODE Code_6FE4
	GLIDE $03
	NOTE A_, 2
	GLIDE $FC
	WAIT
	END

; Sound effect 32
Sfx32:
	VOLENV 10, $00, $00, $00
	GLIDE $FC
	WAVE Wave_72AF
	CALL_CODE Code_7015
	LEN 5
	NOTE A_, 6
	END

; Sound effect 30
Sfx30:
	VOLENV 11, $11, $1F, $11
	WAVE Wave_726F
	GLIDE $FF
	LEN 10
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE Dsh, 4
	END

; Sound effect 29
Sfx29:
	LEN 2
	VOLENV 15, $11, $1F, $11
	WAVE Wave_726F
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

; Sound effect 37
Sfx37:
	VOLENV 15, $11, $23, $11
	LEN 5
	ARP 11
	WAVE Wave_729F
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

; Sound effect 42
Sfx42:
	VOLENV 15, $11, $1F, $12
	WAVE Wave_726F
	ARP 0
	GLIDE $02
	LEN 15
	NOTE A_, 2
	END

; Sound effect 43
Sfx43:
	VOLENV 15, $11, $1F, $11
	WAVE Wave_726F
	ARP 0
	GLIDE $04
	LEN 10
	NOTE A_, 3
	END

; Sound effect 46
Sfx46:
	VOLENV 15, $11, $1F, $13
	WAVE Wave_72FF
	CALL_CODE Code_70C6
	LEN 4
	NOTE C_, 3
	CALL_CODE Code_7037
	LEN 1
	REST
	LEN 10
	GLIDE $FE
	NOTE Dsh, 5
	END

; Sound effect 41
Sfx41:
	VOLENV 15, $11, $1F, $12
	WAVE Wave_729F
	CALL_CODE Code_6F3B
	LEN 10
	GLIDE $FF
	NOTE C_, 4
	END

; Sound effect 35
Sfx35:
	LEN 5
	VOLENV 15, $00, $00, $00
	WAVE Wave_72BF
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

; Sound effect 51
Sfx51:
	VOLENV 12, $11, $1F, $13
	WAVE Wave_726F
	LEN 4
	NOTE C_, 5
	LEN 25
	NOTE C_, 6
	VIBRATO $05, $01, $04
	END

; Sound effect 52
Sfx52:
	VOLENV 15, $00, $00, $00
	LEN 4
	WAVE Wave_72AF
	REPEAT 4
	NOTE A_, 5
	REST
	REPEAT_END
	END

; Sound effect 53
Sfx53:
	CALL_CODE Code_6DDA
	VOLENV 15, $11, $1F, $15
	WAVE Wave_726F
	LEN 9
	GLIDE $FC
	NOTE A_, 4
	END

; Sound effect 28
Sfx28:
	CALL_CODE Code_71A9
	VOLENV 15, $11, $1F, $15
	WAVE Wave_726F
	LEN 9
	GLIDE $FD
	NOTE A_, 3
	END

; Sound effect 26
Sfx26:
	WAVE Wave_729F
	CALL_CODE Code_7080
	VOLENV 15, $11, $1F, $12
	LEN 8
	GLIDE $FF
	NOTE A_, 4
	LEN 5
	VOLENV 10, $11, $1F, $12
	NOTE A_, 4
	END

; Sound effect 12
Sfx12:
	VOLENV 15, $11, $1F, $12
	ARP 0
	WAVE Wave_726F
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

; Sound effect 31
Sfx31:
	CALL_CODE Code_717A
	END

; Sound effect 59
Sfx59:
	VOLENV 15, $11, $1F, $11
	CALL_CODE Code_70C6
	WAVE Wave_726F
	LEN 12
	GLIDE $FE
	NOTE C_, 3
	END

; Sound effect 15
Sfx15:
	CALL_CODE Code_7120
	END

; Sound effect 60
Sfx60:
	CALL_CODE Code_70F7
	END

; Sound effect 55
Sfx55:
	VOLENV 12, $11, $1F, $14
	WAVE Wave_726F
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
	VOLENV 10, $11, $1F, $14
	WAVE Wave_726F
	LEN 33
	VIBRATO $01, $03, $01
	NOTE A_, 5
	END

; Unreferenced (16 bytes)
	db $B8, $11, $1F, $13, $79, $6F, $72, $BF, $30, $D4, $3C, $63, $05, $01, $04, $68

; Sound effect 27
Sfx27:
	CALL_CODE Code_714D
	VOLENV 15, $00, $00, $00
	WAVE Wave_73CF
	LEN 3
	GLIDE $FF
	NOTE Csh, 6
	WAVE Wave_739F
	WAIT
	WAVE Wave_73BF
	WAIT
	END

; Sound effect 45
Sfx45:
	CALL_CODE Code_6F77
	WAVE Wave_726F
	VOLENV 10, $11, $1F, $12
	LEN 7
	GLIDE $01
	NOTE C_, 3
	NOTE G_, 2
	END

; Sound effect 57
Sfx57:
	VOLENV 10, $15, $1F, $22
	VIBRATO $00, $02, $06
	WAVE Wave_737F
	LEN 20
	NOTE A_, 5
	GLIDE $FF
	LEN 10
	WAIT
	END

; Sound effect 56
Sfx56:
	VOLENV 12, $11, $1F, $13
	VIBRATO $00, $01, $04
	WAVE Wave_729F
	CALL_CODE Code_7037
	GLIDE $FC
	LEN 5
	NOTE A_, 4
	CALL_CODE Code_7037
	GLIDE $08
	WAIT
	CALL_CODE Code_7015
	GLIDE_OFF
	LEN 10
	WAIT
	GLIDE $FF
	WAIT
	END
Code_6DDA:
	ld a, $2D
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6DFC)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6DFC)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6E22)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6E22)
	ld [wNoise42], a
	ret
Noise43_6DFC:
	db $03, $93, $80, $72, $70, $56, $54, $60
	db $50, $40, $30, $20, $10, $56, $54, $60
	db $50, $40, $30, $20, $10, $56, $54, $60
	db $50, $40, $30, $20, $10, $56, $54, $60
	db $50, $40, $30, $20, $10, $FF
Noise42_6E22:
	db $F3, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF
Code_6E47:
	ld a, $50
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $03
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_6E72)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6E72)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6E7D)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6E7D)
	ld [wNoise42], a
	ret
Noise43_6E72:
	db $57, $46, $45, $44, $43, $42, $41, $40
	db $20, $20, $FF
Noise42_6E7D:
	db $19, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $F3

; Unreferenced (60 bytes)
	db $AF, $EA, $64, $C1, $3C, $EA, $65, $C1, $3E, $13, $EA, $50, $C1, $CD, $8E, $49
	db $3E, $F2, $E0, $21, $3E, $80, $E0, $23, $3E, $6E, $EA, $60, $C1, $3E, $B4, $EA
	db $61, $C1, $3E, $00, $EA, $62, $C1, $3E, $00, $EA, $63, $C1, $C9, $18, $3A, $47
	db $49, $2E, $2D, $1C, $28, $4A, $57, $39, $4E, $1D, $0C, $FF
Code_6EC3:
	ld a, $08
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6EE5)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6EE5)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6EE9)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6EE9)
	ld [wNoise42], a
	ret
Noise43_6EE5:
	db $00, $43, $45, $FF
Noise42_6EE9:
	db $F1, $FF, $00

; Unreferenced (51 bytes)
	db $3E, $0A, $EA, $50, $C1, $AF, $EA, $64, $C1, $3C, $EA, $65, $C1, $3E, $6F, $EA
	db $60, $C1, $3E, $0E, $EA, $61, $C1, $3E, $6F, $EA, $62, $C1, $3E, $17, $EA, $63
	db $C1, $C9, $36, $35, $34, $33, $31, $20, $10, $10, $FF, $C1, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF
Noise43_6F1F:
	db $12, $64, $02, $37, $47, $24, $55, $71
	db $07, $44, $60, $36, $84, $82, $64, $02
	db $37, $47, $24, $55, $71, $07, $44, $60
	db $36, $86, $32, $FF
Code_6F3B:
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
	ld a, HIGH(Noise43_6F65)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6F65)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_6F65:
	db $46, $45, $44, $43, $42, $41, $32, $30
	db $FF

; Unreferenced (9 bytes)
	db $10, $10, $20, $31, $33, $34, $35, $36, $FF
Code_6F77:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $19
	ld [wDrumHold], a
	ld a, HIGH(Noise43_6F1F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6F1F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6F99)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6F99)
	ld [wNoise42], a
	ret
Noise42_6F99:
	db $59, $FF, $FF, $FF, $FF, $FF, $FF, $F2
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF

; Unreferenced (3 bytes)
	db $FF, $FF, $FF
Code_6FB7:
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
	ld a, HIGH(Noise43_6F1F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6F1F)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Code_6FE4:
	ld a, $08
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7006)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7006)
	ld [wNoise43], a
	ld a, HIGH(Noise42_700E)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_700E)
	ld [wNoise42], a
	ret
Noise43_7006:
	db $60, $52, $42, $41, $22, $11, $21, $FF
Noise42_700E:
	db $F0, $F0, $F0, $F0, $F0, $F0, $61
Code_7015:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7059)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7059)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7073)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7073)
	ld [wNoise42], a
	ret
Code_7037:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7066)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7066)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7073)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7073)
	ld [wNoise42], a
	ret
Noise43_7059:
	db $10, $10, $20, $31, $32, $33, $33, $34
	db $34, $35, $35, $36, $FF
Noise43_7066:
	db $36, $35, $35, $34, $34, $33, $33, $32
	db $31, $20, $10, $10, $FF
Noise42_7073:
	db $5C, $FF, $FF, $FF, $FF, $FF, $A1, $FF
	db $FF, $FF, $FF, $FF

; Unreferenced (1 bytes)
	db $FF
Code_7080:
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
	ld a, HIGH(Noise43_70AA)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_70AA)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_70AA:
	db $12, $92, $42, $42, $42, $42, $52, $65
	db $45, $FF

; Unreferenced (18 bytes)
	db $F0, $FF, $55, $00, $B2, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $F0, $FF, $FF
	db $FF, $F4
Code_70C6:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_70E8)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_70E8)
	ld [wNoise43], a
	ld a, HIGH(Noise42_70F0)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_70F0)
	ld [wNoise42], a
	ret
Noise43_70E8:
	db $02, $51, $61, $71, $91, $71, $60, $FF
Noise42_70F0:
	db $F0, $F0, $F0, $F0, $F0, $70, $63
Code_70F7:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7119)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7119)
	ld [wNoise43], a
	ld a, HIGH(Noise42_711D)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_711D)
	ld [wNoise42], a
	ret
Noise43_7119:
	db $02, $51, $11, $FF
Noise42_711D:
	db $F0, $A0, $55
Code_7120:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7142)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7142)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7148)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7148)
	ld [wNoise42], a
	ret
Noise43_7142:
	db $02, $41, $61, $71, $11, $FF
Noise42_7148:
	db $F0, $FF, $FF, $A0, $B2
Code_714D:
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_716F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_716F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7175)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7175)
	ld [wNoise42], a
	ret
Noise43_716F:
	db $00, $53, $71, $91, $31, $FF
Noise42_7175:
	db $F1, $FF, $FF, $FF, $00
Code_717A:
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_719C)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_719C)
	ld [wNoise43], a
	ld a, HIGH(Noise42_71A3)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_71A3)
	ld [wNoise42], a
	ret
Noise43_719C:
	db $41, $61, $61, $41, $71, $71, $FF
Noise42_71A3:
	db $A1, $52, $00, $61, $52, $00
Code_71A9:
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
	ld a, HIGH(Noise43_71D4)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_71D4)
	ld [wNoise43], a
	ld a, HIGH(Noise42_71DA)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_71DA)
	ld [wNoise42], a
	ret
Noise43_71D4:
	db $03, $93, $80, $72, $70, $FF
Noise42_71DA:
	db $F0, $FF, $FF, $FF, $F3
Wave_71DF:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $44, $44, $44, $77, $77, $44, $44, $44

; Unreferenced (32 bytes)
	db $01, $11, $11, $00, $89, $AA, $AA, $98, $01, $11, $11, $00, $FF, $FF, $FF, $FF
	db $A8, $40, $04, $8A, $FF, $FF, $FF, $FF, $A8, $40, $04, $8A, $FF, $FF, $FF, $FF
Wave_720F:
	db $8C, $FE, $ED, $B8, $53, $21, $10, $24
	db $84, $01, $12, $35, $8B, $DE, $EF, $8C

; Unreferenced (64 bytes)
	db $00, $16, $8A, $FF, $FF, $A8, $61, $00, $00, $16, $8A, $FF, $FF, $A8, $61, $00
	db $B7, $40, $F4, $7B, $FD, $FF, $FE, $DC, $02, $46, $8A, $BD, $FD, $BA, $6F, $20
	db $32, $22, $11, $11, $11, $22, $23, $45, $FD, $CB, $A9, $87, $65, $43, $21, $10
	db $DD, $DB, $97, $52, $22, $54, $22, $22, $DD, $DC, $BD, $DD, $DB, $85, $22, $22
Wave_725F:
	db $44, $44, $44, $44, $FF, $FF, $FF, $FF
	db $44, $44, $44, $44, $FF, $FF, $FF, $FF
Wave_726F:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF

; Unreferenced (16 bytes)
	db $01, $11, $11, $00, $89, $AA, $AA, $98, $01, $11, $11, $00, $FF, $FF, $FF, $FF
Wave_728F:
	db $00, $00, $00, $00, $CD, $EF, $FD, $EC
	db $00, $12, $21, $00, $DD, $DD, $DD, $DD
Wave_729F:
	db $00, $00, $00, $00, $00, $00, $FF, $FF
	db $00, $00, $00, $00, $00, $00, $FF, $FF
Wave_72AF:
	db $00, $00, $00, $00, $00, $00, $FF, $00
	db $00, $00, $00, $00, $00, $00, $FF, $00
Wave_72BF:
	db $00, $00, $00, $CD, $EF, $FF, $FF, $FF
	db $04, $8C, $FF, $FF, $FF, $FF, $FF, $FF
Wave_72CF:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $00, $FF, $FF, $FF

; Unreferenced (32 bytes)
	db $12, $34, $56, $78, $9A, $BC, $DE, $FF, $ED, $CB, $A9, $87, $65, $43, $21, $00
	db $FF, $FE, $ED, $B8, $53, $21, $10, $00, $00, $01, $12, $35, $8B, $DE, $EF, $FF
Wave_72FF:
	db $63, $10, $00, $00, $00, $00, $01, $36
	db $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9
Wave_730F:
	db $63, $10, $01, $47, $74, $10, $01, $36
	db $9C, $EF, $FE, $B8, $8B, $EF, $FE, $C9

; Unreferenced (64 bytes)
	db $63, $1F, $01, $47, $74, $10, $01, $36, $9C, $E0, $FE, $B8, $8B, $EF, $FE, $C9
	db $65, $43, $22, $27, $72, $22, $22, $29, $AB, $CC, $BA, $98, $9C, $EE, $EE, $C9
	db $63, $20, $02, $47, $74, $22, $22, $36, $9C, $EF, $FE, $B6, $6B, $EE, $EE, $C9
	db $B7, $40, $04, $7B, $CD, $FF, $FE, $DC, $02, $46, $8A, $BD, $FD, $BA, $64, $20
Wave_735F:
	db $0F, $00, $F0, $F0, $F0, $F0, $00, $0F
	db $0F, $FF, $FF, $00, $FF, $F0, $0F, $0F

; Unreferenced (16 bytes)
	db $BB, $2B, $BB, $2B, $BB, $5B, $2B, $BB, $2B, $BB, $BB, $72, $27, $EB, $BB, $B0
Wave_737F:
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $ED, $CB, $A9, $87, $65, $43, $21, $00

; Unreferenced (16 bytes)
	db $FE, $DB, $97, $53, $13, $54, $32, $10, $FE, $DC, $BC, $EF, $DB, $85, $32, $10
Wave_739F:
	db $04, $8B, $DE, $FF, $ED, $CB, $A9, $87
	db $65, $44, $44, $32, $11, $24, $7A, $74

; Unreferenced (16 bytes)
	db $20, $13, $69, $BD, $FD, $B9, $64, $20, $13, $68, $B8, $64, $20, $24, $68, $64
Wave_73BF:
	db $20, $24, $68, $AC, $EC, $A8, $64, $20
	db $24, $68, $A8, $64, $20, $24, $68, $64
Wave_73CF:
	db $02, $48, $AC, $FF, $FC, $53, $00, $27
	db $9C, $DD, $DC, $B7, $7B, $CD, $DD, $C9

; Unreferenced (16 bytes)
	db $BD, $FF, $AC, $FF, $FC, $52, $00, $27, $9C, $DF, $DC, $B7, $7B, $CD, $AD, $C9
Noise43_73EF:
	db $01, $61, $71, $A1, $B1, $B1, $A1, $FF
Noise42_73F7:
	db $C1, $F0, $A0, $90, $70, $40, $33
Noise43_73FE:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_7406:
	db $60, $30, $12, $FF, $FF, $FF, $FF
Noise43_740D:
	db $04, $00, $00, $00, $00, $00, $00, $FF
Noise42_7415:
	db $90, $53, $FF, $FF, $FF, $FF, $FF
Noise43_741C:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_7424:
	db $70, $40, $40, $40, $40, $43, $FF
Noise43_742B:
	db $50, $41, $50, $51, $42, $53, $51, $FF
Noise42_7433:
	db $D0, $70, $90, $60, $C0, $50, $61
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_73EF)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_73EF)
	ld [wNoise43], a
	ld a, HIGH(Noise42_73F7)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_73F7)
	ld [wNoise42], a
	ret
Drum8:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7474)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7474)
	ld [wNoise43], a
	ld a, HIGH(Noise42_747C)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_747C)
	ld [wNoise42], a
	ret
Noise43_7474:
	db $60, $52, $42, $41, $22, $11, $04, $FF
Noise42_747C:
	db $F0, $F0, $F0, $A0, $70, $40, $51
Drum3:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_742B)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_742B)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7433)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7433)
	ld [wNoise42], a
	ret
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_741C)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_741C)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7424)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7424)
	ld [wNoise42], a
	ret
Drum5:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_740D)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_740D)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7415)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7415)
	ld [wNoise42], a
	ret
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_73FE)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_73FE)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7406)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7406)
	ld [wNoise42], a
	ret
Drum9:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7514)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7514)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7517)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7517)
	ld [wNoise42], a
	ret
Noise43_7514:
	db $51, $32, $FF
Noise42_7517:
	db $F0, $62

; Unreferenced (78 bytes)
	db $AF, $EA, $64, $C1, $3C, $EA, $65, $C1, $3E, $75, $EA, $60, $C1, $3E, $53, $EA
	db $61, $C1, $3E, $75, $EA, $62, $C1, $3E, $56, $EA, $63, $C1, $C9, $AF, $EA, $64
	db $C1, $3C, $EA, $65, $C1, $3E, $75, $EA, $60, $C1, $3E, $58, $EA, $61, $C1, $3E
	db $75, $EA, $62, $C1, $3E, $60, $EA, $63, $C1, $C9, $51, $32, $FF, $70, $52, $51
	db $32, $32, $32, $32, $51, $32, $FF, $70, $51, $FF, $FF, $FF, $70, $51
FadeOutTable:
	db $77, $66, $55, $44, $33, $22, $11, $00
	db FADE_END
FadeInTable:
	db $00, $11, $22, $33, $44, $55, $66, $77
	db FADE_END

; Unreferenced (2695 bytes)
	db $5A, $59, $FD, $D8, $F3, $F3, $AF, $DC, $F7, $8C, $BD, $C6, $6F, $77, $79, $50
	db $8F, $CE, $DF, $93, $C0, $C0, $40, $05, $03, $80, $80, $00, $00, $07, $F9, $68
	db $E0, $A0, $E2, $62, $9F, $97, $9B, $9B, $8E, $8E, $10, $01, $8E, $2F, $84, $87
	db $83, $06, $DE, $3C, $1C, $6E, $2E, $5E, $5E, $2C, $24, $58, $48, $50, $30, $E0
	db $E0, $60, $20, $76, $76, $AB, $DD, $19, $77, $8F, $FF, $00, $0B, $02, $01, $7F
	db $81, $38, $1F, $3A, $D3, $A0, $60, $D0, $30, $F0, $D0, $68, $78, $78, $68, $B7
	db $D9, $EF, $70, $8F, $1C, $EF, $0B, $FD, $03, $BF, $C0, $FD, $FE, $D6, $D9, $38
	db $28, $F8, $C8, $FF, $0F, $7D, $CB, $BF, $C1, $5D, $E3, $EA, $76, $FC, $FC, $2E
	db $F2, $D8, $06, $06, $0C, $0C, $18, $18, $30, $30, $60, $60, $38, $FE, $78, $9C
	db $01, $01, $07, $06, $1F, $19, $3F, $23, $7F, $43, $7F, $7E, $7F, $41, $81, $88
	db $20, $F0, $90, $70, $50, $10, $38, $FC, $04, $30, $7F, $40, $44, $41, $40, $01
	db $7E, $40, $08, $51, $3F, $3E, $2A, $1E, $FC, $0C, $63, $16, $01, $80, $1C, $0C
	db $F0, $BF, $F0, $10, $80, $5A, $59, $FD, $F5, $00, $00, $06, $06, $05, $07, $0F
	db $0F, $33, $3F, $41, $7F, $95, $FA, $8F, $F0, $60, $60, $80, $80, $14, $06, $FB
	db $EF, $D8, $B8, $F4, $0C, $BA, $46, $EE, $12, $A6, $F9, $4F, $70, $47, $78, $2A
	db $3D, $11, $1E, $08, $0F, $28, $DB, $03, $03, $FE, $02, $DA, $26, $FC, $04, $B4
	db $4C, $E8, $18, $90, $70, $20, $E0, $C0, $C0, $B9, $40, $45, $7B, $1E, $3E, $9F
	db $E0, $2B, $40, $0C, $FA, $06, $2E, $12, $1A, $02, $44, $02, $02, $27, $38, $13
	db $1F, $0E, $0E, $AA, $12, $02, $18, $42, $82, $1E, $42, $10, $F0, $E0, $E0, $DC
	db $2C, $01, $3D, $33, $3D, $5A, $67, $FD, $0A, $EC, $02, $03, $0E, $0F, $32, $3F
	db $C2, $F3, $04, $C6, $BF, $C3, $BD, $C6, $9B, $EC, $4B, $7C, $39, $3E, $04, $2F
	db $7E, $1A, $CB, $C4, $C6, $A8, $6C, $D0, $38, $F0, $10, $D0, $30, $9F, $7E, $B1
	db $01, $0E, $C7, $22, $01, $F5, $50, $07, $07, $1F, $1B, $3F, $25, $7D, $4B, $FE
	db $92, $3F, $3C, $5F, $60, $FF, $01, $2B, $FF, $3F, $C4, $3F, $1A, $FA, $03, $26
	db $F4, $CC, $C8, $38, $30, $F0, $5F, $3C, $E0, $00, $01, $02, $03, $00, $04, $05
	db $06, $00, $07, $08, $09, $0A, $0B, $0C, $0D, $0E, $0F, $10, $11, $12, $13, $14
	db $15, $00, $00, $01, $02, $03, $04, $00, $00, $05, $06, $07, $08, $09, $0A, $0B
	db $0C, $0D, $0E, $0F, $10, $11, $12, $13, $14, $00, $00, $10, $10, $38, $38, $7C
	db $7C, $FE, $FE, $38, $38, $38, $38, $38, $38, $00, $01, $02, $03, $04, $05, $06
	db $07, $08, $09, $0A, $0B, $0C, $0D, $0E, $0F, $5A, $59, $78, $00, $01, $10, $FF
	db $2D, $55, $00, $AA, $05, $BF, $02, $80, $00, $01, $02, $03, $04, $05, $06, $07
	db $08, $09, $0A, $0B, $0C, $0D, $0E, $5A, $59, $7B, $00, $01, $FF, $CF, $01, $54
	db $01, $7F, $01, $13, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B
	db $0C, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $00, $01, $00
	db $02, $03, $01, $00, $02, $03, $02, $03, $01, $00, $01, $02, $03, $04, $05, $06
	db $07, $00, $01, $02, $03, $04, $05, $FF, $56, $8B, $CB, $E8, $0B, $09, $00, $00
	db $E8, $29, $FA, $F8, $FF, $8B, $80, $10, $05, $00, $00, $56, $50, $8B, $18, $FF
	db $53, $14, $5F, $5E, $5B, $8B, $E5, $5D, $C3, $56, $57, $8B, $F1, $E8, $0C, $FA
	db $F8, $FF, $83, $B8, $1C, $04, $00, $00, $00, $74, $35, $8B, $CE, $E8, $5E, $F9
	db $FF, $FF, $85, $C0, $74, $2A, $6A, $00, $FF, $76, $04, $E8, $4A, $F1, $FF, $FF
	db $8B, $F8, $85, $FF, $74, $21, $57, $8B, $CE, $E8, $BD, $08, $00, $00, $E8, $DB
	db $F9, $F8, $FF, $8B, $80, $10, $05, $00, $00, $57, $50, $8B, $30, $FF, $56, $14
	db $B8, $01, $00, $00, $00, $EB, $02, $33, $C0, $5F, $5E, $C3, $55, $8B, $EC, $83
	db $EC, $08, $56, $57, $8B, $F9, $6A, $00, $8B, $75, $08, $56, $E8, $4E, $0C, $00
	db $00, $85, $C0, $75, $0A, $33, $C0, $5F, $5E, $8B, $E5, $5D, $C2, $08, $00, $FF
	db $76, $04, $8B, $4F, $04, $89, $4D, $FC, $FF, $15, $A8, $15, $6E, $50, $01, $45
	db $FC, $8B, $4D, $FC, $80, $39, $5C, $75, $03, $FF, $45, $FC, $8B, $7D, $FC, $B9
	db $FF, $FF, $FF, $FF, $2B, $C0, $F2, $AE, $F7, $D1, $2B, $F9, $8B, $C1, $C1, $E9
	db $02, $8B, $F7, $8B, $7D, $0C, $F3, $A5, $8B, $C8, $83, $E1, $03, $F3, $A4, $B8
	db $01, $00, $00, $00, $EB, $B1, $55, $8B, $EC, $83, $EC, $04, $56, $8B, $F1, $E8
	db $4A, $F9, $F8, $FF, $83, $B8, $1C, $04, $00, $00, $00, $74, $21, $6A, $01, $83
	db $EC, $04, $89, $65, $FC, $FF, $75, $08, $8B, $4D, $FC, $E8, $3D, $36, $F9, $FF
	db $8B, $CE, $E8, $CD, $05, $00, $00, $5E, $8B, $E5, $5D, $C2, $04, $00, $FF, $75
	db $08, $8B, $CE, $E8, $8E, $F7, $F8, $FF, $EB, $ED, $55, $8B, $EC, $81, $EC, $24
	db $03, $00, $00, $53, $89, $4D, $FC, $56, $57, $E8, $F3, $F8, $FA, $FF, $8B, $4D
	db $FC, $85, $C0, $0F, $84, $B6, $01, $00, $00, $33, $DB, $E8, $C2, $8B, $F9, $FF
	db $8B, $C8, $8B, $F0, $E8, $1C, $17, $00, $00, $83, $F8, $04, $74, $0E, $83, $F8
	db $05, $74, $09, $83, $F8, $06, $0F, $85, $89, $01, $00, $00, $68, $04, $01, $00
	db $00, $8D, $85, $F0, $FE, $FF, $FF, $50, $8D, $8D, $EC, $FE, $FF, $FF, $E8, $E5
	db $F8, $F8, $FF, $68, $04, $01, $00, $00, $8D, $85, $E0, $FC, $FF, $FF, $50, $8D
	db $8D, $DC, $FC, $FF, $FF, $E8, $CE, $F8, $F8, $FF, $68, $04, $01, $00, $00, $8D
	db $85, $E8, $FD, $FF, $FF, $50, $8D, $8D, $E4, $FD, $FF, $FF, $E8, $B7, $F8, $F8
	db $FF, $8D, $45, $F8, $8B, $CE, $50, $E8, $21, $82, $F9, $FF, $8B, $38, $B9, $FF
	db $FF, $FF, $FF, $2B, $C0, $F2, $AE, $F7, $D1, $2B, $F9, $8B, $C1, $C1, $E9, $02
	db $8B, $F7, $8B, $BD, $EC, $FE, $FF, $FF, $F3, $A5, $8B, $C8, $83, $E1, $03, $F3
	db $A4, $FF, $B5, $EC, $FE, $FF, $FF, $6A, $5C, $E8, $3B, $36, $F9, $FF, $85, $C0
	db $0F, $84, $FF, $00, $00, $00, $40, $B9, $FF, $FF, $FF, $FF, $8B, $F8, $89, $45
	db $F8, $2B, $C0, $F2, $AE, $F7, $D1, $2B, $F9, $8B, $D1, $C1, $E9, $02, $8B, $F7
	db $8B, $BD, $DC, $FC, $FF, $FF, $F3, $A5, $8B, $CA, $83, $E1, $03, $F3, $A4, $FF
	db $4D, $F8, $8B, $45, $F8, $C6, $00, $00, $8B, $8D, $EC, $FE, $FF, $FF, $80, $39
	db $5C, $0F, $85, $BE, $00, $00, $00, $80, $79, $01, $5C, $0F, $85, $B4, $00, $00
	db $00, $8D, $41, $02, $8D, $4D, $F8, $89, $45, $F4, $8D, $45, $F4, $50, $E8, $FA
	db $34, $F9, $FF, $8B, $7D, $F8, $B9, $FF, $FF, $FF, $FF, $2B, $C0, $F2, $AE, $F7
	db $D1, $2B, $F9, $8B, $D1, $C1, $E9, $02, $8B, $F7, $8B, $BD, $E4, $FD, $FF, $FF
	db $F3, $A5, $8B, $CA, $68, $D4, $15, $00, $00, $83, $E1, $03, $F3, $A4, $E8, $9C
	db $B9, $05, $00, $80, $38, $00, $74, $47, $FF, $B5, $E4, $FD, $FF, $FF, $8B, $75
	db $08, $FF, $B5, $DC, $FC, $FF, $FF, $50, $FF, $36, $E8, $C2, $8A, $FB, $FF, $83
	db $C4, $10, $85, $DB, $74, $20, $8B, $4D, $FC, $E8, $64, $8A, $F9, $FF, $FF, $70
	db $0C, $68, $D3, $15, $00, $00, $E8, $64, $B9, $05, $00, $50, $FF, $36, $E8, $9E
	db $8A, $FB, $FF, $83, $C4, $0C, $5F, $5E, $5B, $8B, $E5, $5D, $C2, $04, $00, $68
	db $D5, $15, $00, $00, $E8, $46, $B9, $05, $00, $FF, $B5, $DC, $FC, $FF, $FF, $8B
	db $75, $08, $FF, $B5, $E4, $FD, $FF, $FF, $50, $FF, $36, $E8, $71, $8A, $FB, $FF
	db $83, $C4, $10, $EB, $AD, $BB, $01, $00, $00, $00, $8B, $75, $08, $EB, $A3, $E8
	db $14, $3D, $F9, $FF, $50, $8B, $4D, $FC, $FF, $75, $08, $E8, $EC, $00, $00, $00
	db $EB, $B4, $55, $8B, $EC, $83, $EC, $04, $56, $8D, $45, $FC, $57, $50, $FF, $75
	db $0C, $68, $04, $01, $00, $00, $FF, $75, $08, $8B, $F9, $FF, $15, $58, $14, $6E
	db $50, $85, $C0, $75, $10, $8B, $45, $0C, $C6, $00, $00, $33, $C0, $5F, $5E, $8B
	db $E5, $5D, $C2, $0C, $00, $E8, $F4, $F6, $F8, $FF, $83, $B8, $1C, $04, $00, $00
	db $00, $75, $32, $8D, $4D, $08, $E8, $2C, $CA, $FA, $FF, $8B, $4D, $08, $80, $3C
	db $01, $2E, $75, $21, $8D, $4D, $08, $E8, $1B, $CA, $FA, $FF, $8B, $4D, $08, $8A
	db $44, $01, $FF, $3C, $2E, $74, $0E, $3C, $5C, $74, $0A, $6A, $2E, $8D, $4D, $0C
	db $E8, $F1, $F8, $F8, $FF, $8B, $87, $14, $01, $00, $00, $8B, $75, $10, $8D, $4D
	db $0C, $89, $06, $E8, $EF, $C9, $FA, $FF, $39, $87, $14, $01, $00, $00, $74, $0B
	db $03, $45, $0C, $80, $38, $5C, $75, $03, $C6, $00, $00, $8B, $45, $0C, $80, $38
	db $5C, $75, $27, $80, $78, $01, $5C, $75, $21, $8B, $87, $14, $01, $00, $00, $83
	db $F8, $FF, $74, $20, $03, $45, $0C, $8A, $08, $84, $C9, $74, $17, $80, $F9, $3A
	db $74, $05, $80, $F9, $2F, $75, $03, $C6, $00, $5C, $B8, $01, $00, $00, $00, $E9
	db $59, $FF, $FF, $FF, $6A, $5C, $8D, $4D, $0C, $E8, $88, $F8, $F8, $FF, $FF, $75
	db $0C, $FF, $15, $A8, $15, $6E, $50, $48, $89, $06, $EB, $DE, $55, $8B, $54, $24
	db $08, $8B, $EC, $81, $EC, $14, $01, $00, $00, $8B, $02, $53, $56, $33, $DB, $57
	db $8B, $F1, $88, $18, $E8, $25, $F6, $F8, $FF, $39, $98, $1C, $04, $00, $00, $0F
	db $84, $ED, $00, $00, $00, $8B, $CE, $E8, $E3, $03, $00, $00, $50, $8B, $F8, $E8
	db $3C, $31, $00, $00, $E8, $75, $03, $00, $00, $8B, $75, $0C, $89, $45, $F8, $89
	db $5D, $FC, $3B, $F3, $0F, $84, $C3, $00, $00, $00, $56, $57, $E8, $8C, $31, $00
	db $00, $8B, $F8, $83, $FE, $01, $0F, $8E, $AC, $00, $00, $00, $57, $E8, $8C, $30
	db $00, $00, $50, $E8, $C4, $2E, $00, $00, $8B, $D8, $57, $E8, $AA, $30, $00, $00
	db $8D, $45, $FC, $8B, $4D, $F8, $50, $68, $08, $59, $6D, $50, $6A, $00, $8B, $01
	db $57, $FF, $75, $F8, $FF, $50, $14, $E8, $B2, $F5, $F8, $FF, $8B, $80, $10, $05
	db $00, $00, $57, $50, $8B, $30, $FF, $56, $14, $83, $7D, $FC, $00, $74, $37, $8D
	db $85, $EC, $FE, $FF, $FF, $8B, $4D, $FC, $50, $6A, $01, $53, $8B, $01, $FF, $75
	db $FC, $FF, $50, $2C, $85, $C0, $7C, $1E, $83, $EC, $04, $89, $65, $F4, $FF, $75
	db $08, $8B, $4D, $F4, $E8, $84, $32, $F9, $FF, $53, $8D, $85, $EC, $FE, $FF, $FF
	db $50, $E8, $21, $EE, $FF, $FF, $85, $DB, $74, $12, $E8, $5F, $F5, $F8, $FF, $8B
	db $80, $10, $05, $00, $00, $53, $50, $8B, $30, $FF, $56, $14, $8B, $45, $F8, $39
	db $45, $FC, $74, $0B, $8B, $45, $FC, $FF, $75, $FC, $8B, $18, $FF, $53, $08, $5F
	db $5E, $5B, $8B, $E5, $5D, $C2, $08, $00, $8B, $DF, $8B, $45, $F8, $89, $45, $FC
	db $EB, $87, $8B, $46, $04, $8D, $4D, $FC, $51, $89, $45, $F8, $8B, $CE, $E8, $BD
	db $3A, $F9, $FF, $8B, $75, $0C, $85, $F6, $0F, $84, $83, $00, $00, $00, $4E, $74
	db $19, $33, $FF, $39, $7D, $FC, $74, $12, $8B, $45, $FC, $40, $50, $6A, $5C, $E8
	db $42, $F3, $F8, $FF, $4E, $89, $45, $FC, $75, $E9, $FF, $45, $FC, $FF, $75, $FC
	db $6A, $5C, $E8, $2F, $F3, $F8, $FF, $85, $C0, $74, $2C, $8B, $D8, $8B, $55, $08
	db $2B, $5D, $FC, $8B, $75, $FC, $8B, $3A, $8B, $CB, $C1, $E9, $02, $F3, $A5, $8B
	db $CB, $83, $E1, $03, $F3, $A4, $2B, $45, $FC, $8B, $55, $08, $8B, $0A, $C6, $04
	db $08, $00, $E9, $78, $FF, $FF, $FF, $8B, $7D, $FC, $B9, $FF, $FF, $FF, $FF, $2B
	db $C0, $F2, $AE, $F7, $D1, $2B, $F9, $8B, $C1, $8B, $55, $08, $C1, $E9, $02, $8B
	db $F7, $8B, $3A, $F3, $A5, $8B, $C8, $83, $E1, $03, $F3, $A4, $E9, $4E, $FF, $FF
	db $FF, $83, $7D, $FC, $00, $74, $32, $8B, $45, $FC, $8B, $55, $08, $2B, $45, $F8
	db $8B, $75, $F8, $40, $8B, $3A, $8B, $C8, $C1, $E9, $02, $F3, $A5, $8B, $C8, $83
	db $E1, $03, $F3, $A4, $8B, $45, $FC, $8B, $55, $08, $2B, $45, $F8, $8B, $0A, $C6
	db $44, $08, $01, $00, $E9, $16, $FF, $FF, $FF, $8B, $7D, $F8, $EB, $9C, $55, $A1
	db $80, $BA, $6D, $50, $8B, $EC, $83, $EC, $08, $53, $56, $57, $33, $F6, $39, $B0
	db $1C, $04, $00, $00, $74, $20, $E8, $04, $02, $00, $00, $8B, $F0, $8B, $4D, $08
	db $E8, $FA, $01, $00, $00, $50, $56, $E8, $32, $30, $00, $00, $40, $5F, $5E, $5B
	db $8B, $E5, $5D, $C2, $04, $00, $8B, $41, $04, $8B, $3D, $A8, $15, $6E, $50, $8B
	db $4D, $08, $89, $45, $FC, $8B, $41, $04, $50, $89, $45, $F8, $FF, $D7, $FF, $75
	db $FC, $8B, $D8, $FF, $D7, $3B, $D8, $0F, $87, $8F, $00, $00, $00, $FF, $75, $F8
	db $FF, $D7, $33, $D2, $85, $C0, $74, $19, $8B, $4D, $F8, $8B, $7D, $FC, $8A, $0C
	db $0A, $38, $0C, $3A, $75, $0B, $80, $F9, $5C, $75, $01, $46, $42, $3B, $D0, $72
	db $E7, $3B, $D0, $75, $47, $85, $D2, $74, $43, $8B, $45, $F8, $03, $C2, $8A, $48
	db $FF, $80, $F9, $5C, $75, $0A, $8B, $7D, $FC, $80, $7C, $3A, $FF, $5C, $74, $2C
	db $8A, $00, $84, $C0, $75, $09, $8B, $7D, $FC, $80, $3C, $3A, $00, $74, $1C, $80
	db $F9, $5C, $74, $09, $8B, $4D, $FC, $80, $3C, $0A, $5C, $74, $0E, $8B, $4D, $FC
	db $80, $7C, $0A, $FF, $5C, $74, $05, $3C, $5C, $75, $01, $46, $85, $F6, $7E, $15
	db $8B, $45, $F8, $80, $38, $5C, $75, $0D, $80, $78, $01, $5C, $75, $07, $83, $EE
	db $03, $79, $02, $33, $F6, $8B, $C6, $E9, $41, $FF, $FF, $FF, $FF, $75, $FC, $E9
	db $6C, $FF, $FF, $FF, $55, $8B, $EC, $81, $EC, $0C, $01, $00, $00, $56, $57, $8B
	db $F1, $8B, $7D, $0C, $81, $FF, $00, $80, $00, $00, $75, $2D, $FF, $B6, $20, $01
	db $00, $00, $E8, $CA, $30, $00, $00, $85, $C0, $74, $1E, $8B, $7D, $08, $8B, $B6
	db $20, $01, $00, $00, $E8, $25, $F3, $F8, $FF, $57, $56, $FF, $90, $34, $04, $00
	db $00, $5F, $5E, $8B, $E5, $5D, $C2, $08, $00, $8B, $8E, $1C, $01, $00, $00, $8D
	db $85, $F4, $FE, $FF, $FF, $50, $57, $8B, $01, $FF, $B6, $24, $01, $00, $00, $51
	db $FF, $50, $2C, $85, $C0, $7C, $DA, $83, $EC, $04, $8D, $45, $08, $89, $65, $FC
	db $50, $8B, $4D, $FC, $E8, $F4, $2F, $F9, $FF, $FF, $B6, $24, $01, $00, $00, $8D
	db $8D, $F4, $FE, $FF, $FF, $51, $E8, $8C, $EB, $FF, $FF, $EB, $B4, $55, $8B, $EC
	db $56, $8B, $F1, $E8, $28, $F2, $FF, $FF, $85, $C0, $74, $07, $33, $C0, $5E, $5D
	db $C2, $04, $00, $83, $7D, $08, $00, $75, $07, $C7, $45, $08, $77, $01, $0F, $F2
	db $8B, $86, $1C, $01, $00, $00, $8D, $4D, $08, $51, $81, $C6, $24, $01, $00, $00
	db $56, $6A, $01, $50, $8B, $30, $FF, $56, $24, $8B, $45, $08, $EB, $D0, $8B, $0D
	db $90, $0B, $6D, $50, $56, $57, $8B, $F9, $E8, $E3, $F1, $FF, $FF, $85, $C0, $74
	db $05, $33, $C0, $5F, $5E, $C3, $8D, $B7, $18, $01, $00, $00, $83, $3E, $00, $75
	db $1E, $FF, $B7, $24, $01, $00, $00, $E8, $6A, $2A, $00, $00, $83, $F8, $02, $75
	db $12, $8B, $87, $1C, $01, $00, $00, $8B, $38, $50, $89, $06, $FF, $57, $04, $8B
	db $06, $EB, $D0, $8B, $8F, $1C, $01, $00, $00, $56, $68, $08, $59, $6D, $50, $6A
	db $00, $FF, $B7, $24, $01, $00, $00, $51, $8B, $39, $FF, $57, $14, $EB, $E0, $8B
	db $81, $20, $01, $00, $00, $C3, $8B, $81, $24, $01, $00, $00, $C3, $8B, $81, $55
	db $8B, $EC, $83, $EC, $04, $56, $FF, $76, $08, $FF, $76, $06, $9A, $E3, $19, $E7
	db $00, $8B, $F0, $A1, $14, $00, $89, $46, $FE, $C7, $46, $FC, $00, $00, $EB, $30
	db $FF, $76, $FE, $FF, $76, $FC, $FF, $76, $08, $FF, $76, $06, $56, $9A, $65, $1A
	db $E7, $00, $0B, $C0, $75, $0B, $8B
