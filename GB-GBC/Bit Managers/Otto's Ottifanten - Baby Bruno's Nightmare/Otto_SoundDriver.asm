; =====================================================================
; Otto's Ottifanten: Baby Bruno's Nightmare (E) - Game Boy
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o otto.o Otto_SoundDriver.asm
;   rgblink -o otto.gb otto.o
;   python tools/cmp_banked.py otto.gb "Otto's Ottifanten (E).gb" 3:4000-7FFF
; (driver and data fill ROM bank 3; the linked file only matches in that range)
;
; Documentation: Otto_SoundDriver.md / AJG_SoundEngine_Family.md
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


SECTION "SoundDriver", ROMX[$4000], BANK[3]


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
	jp PlaySong1                       ; song 1
	jp PlaySong2                       ; song 2
	jp PlaySong3                       ; song 3
	jp PlaySong4                       ; song 4
	jp PlaySong5                       ; song 5
	jp PlaySong6                       ; song 6
	jp InstrTable1                      ; unused song slot: jumps into the instrument table (never called)
	jp InstrTable1                      ; unused song slot: jumps into the instrument table (never called)
	jp InstrTable1                      ; unused song slot: jumps into the instrument table (never called)
	jp InstrTable1                      ; unused song slot: jumps into the instrument table (never called)
	jp InstrTable1                      ; unused song slot: jumps into the instrument table (never called)
	jp InstrTable1                      ; unused song slot: jumps into the instrument table (never called)
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

; Unreferenced (39 bytes)
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
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
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
	add a, $5F
	ld l, a
	adc a, $6D
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
	dw Drum2
	dw Drum3
	dw Drum4
	dw Drum5
	dw Drum6
	dw Drum7
	dw Drum8
	dw Drum9
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
	jr nz, L4B30
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
L4B30:
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
	jr z, L4B4A
	dec a
	ld [hl], a
	ret
L4B4A:
	ld l, $45
	ld a, [hl]
	and a
	ret z
	ld l, $42
	ld b, [hl]
	cp $01
	jr z, L4B66
	ld l, $48
	ld a, [hl]
	add a, b
	ld [hl], a
	jr nc, L4B5F
	inc l
	inc [hl]
L4B5F:
	ld l, $4A
	xor a
	ld [hl], a
	jr L4B74

; Unreferenced (1 bytes)
	db $C9
L4B66:
	ld l, $48
	ld a, [hl]
	add a, b
	ld [hl], a
	jr nc, L4B6F
	inc l
	inc [hl]
L4B6F:
	ld l, $4A
	ld a, $01
	ld [hl], a
L4B74:
	push de
	ld l, $47
	ld d, h
	ld e, $49
	ld a, [de]
	cp [hl]
	jr z, L4B88
	jr c, L4B96
	ld a, [hl]
	ld [de], a
	dec l
	dec e
	ld a, [hl]
	ld [de], a
	jr L4B92
L4B88:
	dec l
	dec e
	ld a, [de]
	cp [hl]
	jr z, L4B92
	jr c, L4B96
	ld a, [hl]
	ld [de], a
L4B92:
	ld l, $45
	ld [hl], $00
L4B96:
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
	jr L4BF6
PortaScan:
	ld a, [de]
	inc de
	cp $60
	jr nc, L4BCD
	ld c, a
	ld l, $43
	ld b, [hl]
	ld l, $44
	ld a, [hl]
	sub b
	jr c, L4BC9
	ld [hl], a
	jr PortaTarget
L4BC9:
	xor a
	ld [hl], a
	jr PortaTarget
L4BCD:
	cp $65
	jr z, L4BF6
	cp $66
	jr z, L4BF6
	cp $83
	jr z, L4BED
	cp $AC
	jr c, L4BE3
	cp $BC
	jr nc, L4BE3
	jr L4BF1
L4BE3:
	cp $6A
	jr z, PortaNone
	cp $68
	jr z, PortaNone
	jr PortaScan
L4BED:
	inc de
	inc de
	jr PortaScan
L4BF1:
	inc de
	inc de
	inc de
	jr PortaScan
L4BF6:
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
	jr z, L4C67
	jr nc, L4C39
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
	jr L4C6E
L4C39:
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
	jr L4C6E
PortaNone:
	ld l, $44
	ld [hl], $00
	inc l
L4C67:
	ld [hl], $00
	ld l, $46
	xor a
	ld [hli], a
	ld [hl], a
L4C6E:
	pop de
	ret

; Song 1: instrument table 1, arpeggio table 1
PlaySong1:
	ld a, HIGH(InstrTable1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable1 - 2)
	ld [wInstrTable], a
	ld a, HIGH(ArpTable)
	ld [wArpTableHi], a
	ld a, LOW(ArpTable)
	ld [wArpTable], a
	ld de, Song1_Ch1
	call StartMusicCh1
	ld de, Song1_Ch2
	call StartMusicCh2
	ld de, Song1_Ch3
	call StartMusicCh3
	ret
Song1_Ch1:
	dw Pat_4DD3
	dw Pat_4DD3
	dw Pat_4E73
	dw Pat_4EA7
	dw Pat_4EA7
	dw Pat_4EA7
	dw Pat_4EA7
	dw Pat_504E
	dw Pat_504E
	dw Pat_50E8
	dw Pat_51B4
	dw Pat_50E8
	dw Pat_51B4
	dw Pat_4EBF
	dw Pat_4EBF
	dw Pat_504E
	dw Pat_504E
	dw Pat_504C
	dw Pat_504E
	dw Pat_5272
	dw Pat_5272
	dw Pat_5272
	dw Pat_5272
	dw Pat_5272
	dw Pat_5272
	dw Pat_5272
	dw Pat_5272
	dw Pat_53A6
	dw Pat_53A6
	dw Pat_53A6
	dw Pat_53A6
	dw Pat_50E8
	dw Pat_51B4
	dw Pat_548D
	ORDER_LOOP Song1_Ch1
Song1_Ch2:
	dw Pat_4D97
	dw Pat_4D97
	dw Pat_4E41
	dw Pat_4F10
	dw Pat_4F10
	dw Pat_500C
	dw Pat_500C
	dw Pat_5078
	dw Pat_507E
	dw Pat_5136
	dw Pat_5205
	dw Pat_5136
	dw Pat_5205
	dw Pat_500C
	dw Pat_500C
	dw Pat_5078
	dw Pat_507E
	dw Pat_5078
	dw Pat_507E
	dw Pat_5293
	dw Pat_52A0
	dw Pat_532A
	dw Pat_535E
	dw Pat_53F8
	dw Pat_53F8
	dw Pat_53F8
	dw Pat_53F8
	dw Pat_5136
	dw Pat_5205
	dw Pat_54D2
	ORDER_LOOP Song1_Ch2
Song1_Ch3:
	dw Pat_4D61
	dw Pat_4D61
	dw Pat_4E13
	dw Pat_4E13
	dw Pat_4F2B
	dw Pat_4F83
	dw Pat_4FD9
	dw Pat_4FD9
	dw Pat_50B9
	dw Pat_50B9
	dw Pat_517C
	dw Pat_5227
	dw Pat_517C
	dw Pat_5227
	dw Pat_4FDE
	dw Pat_4FDE
	dw Pat_50B9
	dw Pat_50B9
	dw Pat_50B1
	dw Pat_50B1
	dw Pat_52D6
	dw Pat_52D6
	dw Pat_536E
	dw Pat_536E
	dw Pat_5405
	dw Pat_5461
	dw Pat_5405
	dw Pat_5461
	dw Pat_517C
	dw Pat_5227
	dw Pat_54F6
	ORDER_LOOP Song1_Ch3
Pat_4D61:
	CH_TRANSPOSE $00
	WAVE Wave_6B52
	RELEASE $02, $00
	DRUMS $0A, DrumPat_69C9
	INSTR 0
	LEN 10
	NOTE G_, 3
	WAIT
	WAIT
	NOTE G_, 3
	WAIT
	NOTE D_, 3
	LEN 30
	NOTE G_, 2
	WAIT
	LEN 10
	NOTE F_, 3
	WAIT
	WAIT
	NOTE F_, 3
	WAIT
	NOTE C_, 3
	LEN 30
	NOTE F_, 2
	WAIT
	LEN 10
	NOTE Dsh, 3
	WAIT
	WAIT
	NOTE Dsh, 3
	WAIT
	NOTE Ash, 2
	LEN 30
	NOTE Dsh, 2
	WAIT
	LEN 10
	NOTE D_, 3
	WAIT
	WAIT
	NOTE D_, 3
	WAIT
	NOTE A_, 2
	LEN 30
	NOTE D_, 2
	WAIT
	NEXT
Pat_4D97:
	INSTR 9
	DUTY_75
	LEN 10
	HWENV $F2, $14, $56
	VIBRATO $09, $01, $06
	NOTE G_, 4
	WAIT
	NOTE D_, 4
	NOTE G_, 4
	WAIT
	NOTE D_, 4
	NOTE G_, 4
	WAIT
	NOTE D_, 4
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	NOTE F_, 4
	WAIT
	NOTE C_, 4
	NOTE F_, 4
	WAIT
	NOTE C_, 4
	NOTE F_, 4
	WAIT
	NOTE C_, 4
	NOTE F_, 4
	WAIT
	NOTE G_, 4
	NOTE Dsh, 4
	WAIT
	NOTE Ash, 3
	NOTE Dsh, 4
	WAIT
	NOTE Ash, 3
	NOTE Dsh, 4
	WAIT
	NOTE Ash, 3
	NOTE Dsh, 4
	WAIT
	NOTE F_, 4
	NOTE D_, 4
	WAIT
	NOTE A_, 3
	NOTE D_, 4
	WAIT
	NOTE A_, 3
	NOTE D_, 4
	WAIT
	NOTE A_, 3
	NOTE E_, 4
	WAIT
	NOTE Fsh, 4
	NEXT
Pat_4DD3:
	TRANSPOSE $00
	INSTR 9
	DUTY_75
	LEN 11
	HWENV $F2, $14, $56
	VIBRATO $09, $01, $06
	NOTE B_, 4
	LEN 10
	WAIT
	WAIT
	NOTE B_, 4
	WAIT
	WAIT
	NOTE B_, 4
	WAIT
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 5
	NOTE A_, 4
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	NOTE Ash, 4
	NOTE G_, 4
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	NOTE Fsh, 4
	WAIT
	WAIT
	NOTE Fsh, 4
	WAIT
	WAIT
	NOTE Fsh, 4
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	LEN 9
	NOTE A_, 4
	NEXT
Pat_4E13:
	DRUMS $0A, DrumPat_69D6
	LEN 10
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	WAIT
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	WAIT
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	WAIT
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 4
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	WAIT
	INSTR 4
	NOTE G_, 4
	NEXT
Pat_4E41:
	LEN 10
	NOTE G_, 4
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	WAIT
	NOTE D_, 3
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	WAIT
	NOTE D_, 3
	WAIT
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	WAIT
	NOTE G_, 3
	WAIT
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	WAIT
	NOTE D_, 3
	WAIT
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	WAIT
	NOTE G_, 3
	WAIT
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NEXT
Pat_4E73:
	LEN 11
	NOTE B_, 4
	LEN 10
	WAIT
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 5
	NOTE B_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE B_, 4
	WAIT
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 5
	NOTE B_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE B_, 3
	WAIT
	WAIT
	NOTE B_, 3
	WAIT
	NOTE C_, 4
	NOTE B_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE B_, 3
	WAIT
	WAIT
	NOTE B_, 3
	WAIT
	NOTE C_, 4
	NOTE B_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	LEN 9
	WAIT
	NEXT
Pat_4EA7:
	INSTR 3
	LEN 30
	RELEASE $A2, $00
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 3
	NOTE D_, 3
	NOTE F_, 2
	NOTE F_, 2
	NOTE C_, 3
	NOTE C_, 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE D_, 3
	NOTE D_, 3
	NOTE E_, 2
	NOTE B_, 2
	NOTE D_, 2
	NOTE A_, 2
	RELEASE $00
	NEXT
Pat_4EBF:
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE E_, 2
	WAIT
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE B_, 2
	WAIT
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE D_, 4
	NEXT
Pat_4F10:
	LEN 30
	DUTY_50
	HWENV $F1, $0A, $66
	ARP 2
	NOTE G_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE D_, 4
	ARP 3
	NOTE E_, 4
	NOTE E_, 4
	ARP 2
	NOTE D_, 4
	NOTE D_, 4
	ARP_OFF
	NEXT
Pat_4F2B:
	LEN 10
	ARP_OFF
	CH_TRANSPOSE $18
	VOLENV 15, $00, $00, $00
	VIBRATO $0A, $01, $02
	WAVE Wave_6B72
	RELEASE $A2, $00
	DRUMS $1E, DrumPat_6A46
	NOTE D_, 5
	WAIT
	LEN 7
	NOTE D_, 5
	LEN 3
	NOTE E_, 5
	LEN 10
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	NOTE C_, 5
	WAIT
	LEN 7
	NOTE C_, 5
	LEN 3
	NOTE D_, 5
	LEN 10
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	REST
	NOTE D_, 5
	WAIT
	LEN 7
	NOTE D_, 5
	LEN 3
	NOTE E_, 5
	LEN 10
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	WAIT
	NOTE A_, 4
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	LEN 3
	NOTE E_, 4
	LEN 10
	NOTE G_, 4
	LEN 7
	REST
	LEN 10
	NOTE E_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	REST
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	REST
	NEXT
Pat_4F83:
	NOTE D_, 5
	LEN 3
	NOTE C_, 5
	NOTE D_, 5
	LEN 4
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	NOTE C_, 5
	LEN 3
	NOTE B_, 4
	NOTE C_, 5
	LEN 4
	NOTE B_, 4
	LEN 10
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 3
	NOTE A_, 4
	LEN 17
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	LEN 3
	NOTE A_, 4
	LEN 7
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE C_, 4
	WAIT
	REST
	NOTE D_, 5
	LEN 3
	NOTE C_, 5
	NOTE D_, 5
	LEN 4
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	NOTE C_, 5
	LEN 3
	NOTE B_, 4
	NOTE C_, 5
	LEN 4
	NOTE B_, 4
	LEN 10
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 3
	NOTE A_, 4
	LEN 7
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	NOTE A_, 4
	LEN 3
	NOTE A_, 4
	LEN 7
	NOTE B_, 4
	LEN 10
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE D_, 4
	WAIT
	REST
	CH_TRANSPOSE $00
	NEXT
Pat_4FD9:
	INSTR 6
	DRUMS $05, DrumPat_69E3
Pat_4FDE:
	CH_TRANSPOSE $0C
	RELEASE $00
	PORTA $06, $04
	LEN 20
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	LEN 10
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	LEN 20
	NOTE G_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	NOTE D_, 4
	WAIT
	PORTA_OFF
	CH_TRANSPOSE $00
	NEXT
Pat_500C:
	LEN 10
	DUTY_12
	ARP 0
	HWENV $F2, $00
	NOTE G_, 4
	NOTE G_, 3
	NOTE A_, 4
	NOTE G_, 3
	NOTE B_, 4
	NOTE G_, 3
	NOTE D_, 5
	NOTE D_, 4
	NOTE C_, 5
	NOTE D_, 4
	NOTE B_, 4
	NOTE D_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE B_, 4
	LEN 3
	NOTE C_, 5
	NOTE B_, 4
	LEN 4
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 5
	NOTE D_, 5
	NOTE A_, 5
	NOTE D_, 5
	NOTE B_, 5
	NOTE D_, 5
	NOTE D_, 6
	NOTE D_, 5
	NOTE C_, 6
	NOTE D_, 5
	NOTE B_, 5
	NOTE D_, 5
	NOTE C_, 6
	NOTE E_, 5
	LEN 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE B_, 5
	NOTE C_, 6
	LEN 10
	NOTE B_, 5
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE D_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE D_, 5
	WAIT
	NEXT
Pat_504C:
	TRANSPOSE $01
Pat_504E:
	LEN 10
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	NEXT
Pat_5078:
	PAT_CALL Pat_5084
	PAT_GOTO Pat_50AB
Pat_507E:
	PAT_CALL Pat_5084
	PAT_GOTO Pat_50AE
Pat_5084:
	INSTR 7
	VIBRATO $0A, $04, $04
	LEN 2
	NOTE D_, 4
	NOTE F_, 4
	LEN 16
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	LEN 10
	NOTE F_, 4
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	NOTE F_, 4
	LEN 2
	NOTE D_, 4
	NOTE F_, 4
	LEN 16
	NOTE G_, 4
	LEN 5
	NOTE G_, 4
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NEXT
Pat_50AB:
	NOTE D_, 4
	NOTE F_, 4
	NEXT
Pat_50AE:
	WAIT
	WAIT
	NEXT
Pat_50B1:
	WAVE Wave_6BB2
	CH_TRANSPOSE $0C
	PAT_GOTO Pat_50C6
Pat_50B9:
	CH_TRANSPOSE $0C
	INSTR 6
	RELEASE $00
	VIBRATO $14, $01, $05
	DRUMS $05, DrumPat_6A14
Pat_50C6:
	LENGTH $78
	NOTE D_, 5
	LEN 10
	NOTE F_, 5
	LEN 3
	NOTE E_, 5
	NOTE F_, 5
	LEN 4
	NOTE E_, 5
	LEN 10
	NOTE D_, 5
	NOTE E_, 5
	LEN 3
	NOTE D_, 5
	NOTE E_, 5
	LEN 4
	NOTE D_, 5
	LEN 10
	NOTE C_, 5
	NOTE D_, 5
	LEN 3
	NOTE C_, 5
	NOTE D_, 5
	LEN 4
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	CH_TRANSPOSE $00
	NEXT
Pat_50E8:
	LEN 10
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE C_, 3
	WAIT
	NOTE B_, 2
	WAIT
	NOTE A_, 2
	WAIT
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	NEXT
Pat_5136:
	LEN 10
	DUTY_50
	ARP 0
	HWENV $F2, $14, $60
	NOTE B_, 4
	WAIT
	LEN 5
	NOTE B_, 4
	NOTE B_, 4
	LEN 10
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	WAIT
	NOTE Fsh, 4
	NOTE Fsh, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	LEN 5
	NOTE A_, 4
	NOTE A_, 4
	LEN 10
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE G_, 4
	WAIT
	WAIT
	NOTE B_, 4
	WAIT
	LEN 5
	NOTE B_, 4
	NOTE B_, 4
	LEN 10
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	WAIT
	NOTE Fsh, 4
	NOTE Fsh, 4
	WAIT
	NOTE G_, 4
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE B_, 3
	LEN 3
	NOTE C_, 4
	NOTE B_, 3
	LEN 4
	NOTE C_, 4
	LEN 10
	NOTE B_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NEXT
Pat_517C:
	INSTR 5
	LEN 10
	CH_TRANSPOSE $0C
	NOTE D_, 5
	WAIT
	LEN 5
	NOTE D_, 5
	NOTE D_, 5
	LEN 10
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	WAIT
	NOTE A_, 4
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE D_, 5
	WAIT
	NOTE D_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	WAIT
	NOTE A_, 4
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	NOTE G_, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NEXT
Pat_51B4:
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 5
	INSTR 3
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 5
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 5
	INSTR 3
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 5
	NEXT
Pat_5205:
	NOTE B_, 3
	WAIT
	LEN 5
	NOTE B_, 3
	NOTE B_, 3
	LEN 10
	NOTE B_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE Fsh, 3
	WAIT
	NOTE Fsh, 3
	NOTE Fsh, 3
	WAIT
	NOTE G_, 3
	NOTE A_, 3
	WAIT
	LEN 5
	NOTE A_, 3
	NOTE A_, 3
	LEN 10
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	DUTY_75
	CH_TRANSPOSE $F4
	PAT_GOTO Pat_5243
Pat_5227:
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	NOTE A_, 3
	WAIT
	NOTE B_, 3
	NOTE C_, 4
	WAIT
	NOTE C_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	INSTR 6
	RELEASE $A2, $00
	CH_TRANSPOSE $18
Pat_5243:
	NOTE D_, 4
	NOTE E_, 4
	LEN 3
	NOTE G_, 4
	NOTE A_, 4
	LEN 14
	NOTE G_, 4
	LEN 10
	NOTE D_, 4
	WAIT
	NOTE B_, 4
	NOTE G_, 4
	LEN 3
	NOTE A_, 4
	NOTE B_, 4
	LEN 14
	NOTE A_, 4
	LEN 10
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	LEN 3
	NOTE A_, 4
	NOTE B_, 4
	LEN 14
	NOTE A_, 4
	LEN 10
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	LEN 5
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE E_, 4
	LEN 10
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	CH_TRANSPOSE $00
	RELEASE $00
	NEXT
Pat_5272:
	INSTR 3
	NOTE F_, 2
	WAIT
	WAIT
	INSTR 8
	NOTE F_, 4
	WAIT
	WAIT
	INSTR 3
	NOTE F_, 2
	WAIT
	WAIT
	INSTR 8
	NOTE F_, 4
	WAIT
	WAIT
	INSTR 3
	NOTE G_, 2
	WAIT
	WAIT
	INSTR 8
	NOTE G_, 4
	WAIT
	WAIT
	INSTR 3
	NOTE G_, 2
	WAIT
	WAIT
	INSTR 8
	NOTE G_, 4
	WAIT
	WAIT
	NEXT
Pat_5293:
	ARP 1
	DUTY_50
	HWENV $F2, $0F, $4C
	VIBRATO $14, $04, $04
	PAT_GOTO Pat_52A3
Pat_52A0:
	CH_TRANSPOSE $0C
	DUTY_75
Pat_52A3:
	NOTE F_, 4
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	NOTE E_, 4
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	WAIT
	NOTE B_, 3
	WAIT
	NOTE G_, 3
	WAIT
	NOTE D_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE F_, 4
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	NOTE E_, 4
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	CH_TRANSPOSE $00
	NEXT
Pat_52D6:
	CH_TRANSPOSE $00
	VIBRATO $0A, $01, $04
	VOLENV 15, $11, $18, $12
	ARP 0
	WAVE Wave_6BA2
	DRUMS $05, DrumPat_6A2D
	NOTE A_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 6
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	LEN 3
	NOTE B_, 5
	NOTE C_, 6
	LEN 4
	NOTE B_, 5
	LEN 10
	NOTE C_, 6
	NOTE D_, 6
	WAIT
	LEN 3
	NOTE G_, 5
	NOTE A_, 5
	LEN 4
	NOTE G_, 5
	LEN 10
	NOTE A_, 5
	NOTE B_, 5
	WAIT
	WAIT
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE A_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 6
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	LEN 3
	NOTE B_, 5
	NOTE C_, 6
	LEN 4
	NOTE B_, 5
	LEN 10
	NOTE C_, 6
	NOTE D_, 6
	NOTE B_, 5
	NOTE C_, 6
	NOTE B_, 5
	NOTE G_, 5
	WAIT
	NOTE D_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	CH_TRANSPOSE $00
	NEXT
Pat_532A:
	CH_TRANSPOSE $00
	DUTY_50
	PAT_CALL Pat_5333
	PAT_GOTO Pat_5365
Pat_5333:
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	WAIT
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE D_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE D_, 3
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NEXT
Pat_535E:
	CH_TRANSPOSE $0C
	DUTY_75
	PAT_CALL Pat_5333
	DRUMS_OFF
Pat_5365:
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	CH_TRANSPOSE $00
	NEXT
Pat_536E:
	DRUMS $05, DrumPat_69E3
	NOTE A_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 6
	NOTE A_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE D_, 6
	WAIT
	NOTE G_, 5
	NOTE A_, 5
	NOTE B_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE A_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 6
	NOTE A_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE D_, 6
	NOTE B_, 5
	NOTE C_, 6
	NOTE B_, 5
	NOTE G_, 5
	WAIT
	WAIT
	CALL_CODE Drum3
	WAIT
	WAIT
	WAIT
	NEXT
Pat_53A6:
	LEN 10
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE C_, 2
	WAIT
	INSTR 1
	NOTE C_, 5
	INSTR 3
	NOTE C_, 2
	WAIT
	INSTR 1
	NOTE C_, 5
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 3
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 5
	INSTR 3
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 5
	INSTR 3
	NOTE C_, 2
	WAIT
	INSTR 1
	NOTE C_, 5
	INSTR 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	NEXT
Pat_53F8:
	LEN 10
	INSTR 7
	CH_TRANSPOSE $F4
	PAT_CALL Pat_543E
	PAT_CALL Pat_541B
	CH_TRANSPOSE $00
	NEXT
Pat_5405:
	LEN 10
	CH_TRANSPOSE $18
	VIBRATO $0A, $01, $04
	VOLENV 15, $11, $18, $12
	ARP 0
	WAVE Wave_6BA2
	DRUMS $05, DrumPat_6A14
	PAT_CALL Pat_543E
Pat_541B:
	NOTE B_, 4
	WAIT
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE A_, 4
	WAIT
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	LEN 3
	NOTE G_, 4
	NOTE A_, 4
	LEN 4
	NOTE G_, 4
	LEN 10
	NOTE E_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	LEN 3
	NOTE A_, 4
	NOTE B_, 4
	LEN 4
	NOTE A_, 4
	LEN 10
	NOTE F_, 4
	NEXT
Pat_543E:
	NOTE B_, 4
	WAIT
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE A_, 4
	WAIT
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	LEN 3
	NOTE G_, 4
	NOTE A_, 4
	LEN 4
	NOTE G_, 4
	LEN 10
	NOTE E_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	LEN 3
	NOTE A_, 4
	NOTE B_, 4
	LEN 4
	NOTE A_, 4
	LEN 10
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NEXT
Pat_5461:
	CH_TRANSPOSE $18
	RELEASE $A2, $00
	VOLENV 15, $00, $00, $00
	WAVE Wave_6BB2
	PAT_CALL Pat_543E
	CH_TRANSPOSE $0C
	NOTE B_, 5
	WAIT
	NOTE G_, 5
	NOTE D_, 5
	NOTE G_, 5
	NOTE B_, 5
	NOTE A_, 5
	WAIT
	NOTE F_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 5
	NOTE F_, 6
	NOTE C_, 6
	NOTE G_, 5
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE C_, 6
	RELEASE $00
	NEXT
Pat_548D:
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 5
	INSTR 3
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 5
	INSTR 3
	NOTE C_, 2
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 3
	LENGTH $3C
	DRUMS $FE, DrumPat_6A7A
	NOTE G_, 2
	NEXT
Pat_54D2:
	CH_TRANSPOSE $00
	LEN 3
	NOTE B_, 3
	NOTE C_, 4
	LEN 14
	NOTE B_, 3
	LEN 10
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE B_, 3
	LEN 3
	NOTE A_, 3
	NOTE B_, 3
	LEN 14
	NOTE A_, 3
	LEN 10
	NOTE Fsh, 3
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE E_, 3
	NOTE Fsh, 3
	NOTE G_, 3
	NOTE A_, 3
	HWENV $F7, $1E, $F7
	LENGTH $F0
	NOTE B_, 3
	NEXT
Pat_54F6:
	CH_TRANSPOSE $18
	RELEASE $A2, $00
	LEN 3
	NOTE B_, 4
	NOTE C_, 5
	LEN 14
	NOTE B_, 4
	LEN 10
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	LEN 3
	NOTE A_, 4
	NOTE B_, 4
	LEN 14
	NOTE A_, 4
	LEN 10
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE Fsh, 4
	VOLENV 15, $10, $1F, $1F
	LENGTH $F0
	NOTE G_, 4
	RELEASE $00
	NEXT

; Song 2: instrument table 1, arpeggio table 1
PlaySong2:
	ld a, HIGH(InstrTable1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable1 - 2)
	ld [wInstrTable], a
	ld a, HIGH(ArpTable)
	ld [wArpTableHi], a
	ld a, LOW(ArpTable)
	ld [wArpTable], a
	ld de, Song2_Ch1
	call StartMusicCh1
	ld de, Song2_Ch3
	call StartMusicCh3
	ld de, Song2_Ch2
	call StartMusicCh2
	ret
Song2_Ch1:
	dw Pat_5552
	dw Pat_5552
	dw Pat_55D9
	dw Pat_55D9
	ORDER_LOOP Song2_Ch1
Pat_5552:
	LEN 16
	INSTR 3
	DRUMS $08, DrumPat_6A7D
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 3
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 3
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 3
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 3
	INSTR 1
	NOTE G_, 4
	NEXT
Pat_55D9:
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 3
	NOTE E_, 2
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE B_, 2
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE E_, 2
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE B_, 2
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE E_, 2
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE B_, 2
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE E_, 2
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE B_, 2
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 3
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	NEXT
Song2_Ch3:
	dw Pat_5666
	dw Pat_5666
	dw Pat_56FC
	dw Pat_56FC
	ORDER_LOOP Song2_Ch3
Pat_5666:
	LEN 8
	INSTR 12
	INSTR 12
	NOTE G_, 4
	WAIT
	INSTR 5
	NOTE Fsh, 6
	NOTE D_, 6
	NOTE B_, 5
	WAIT
	INSTR 12
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	INSTR 5
	NOTE Fsh, 6
	NOTE D_, 6
	NOTE B_, 5
	WAIT
	INSTR 12
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE B_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE G_, 3
	WAIT
	INSTR 5
	NOTE Fsh, 5
	NOTE D_, 5
	NOTE B_, 4
	WAIT
	INSTR 12
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	INSTR 5
	NOTE Fsh, 5
	NOTE D_, 5
	NOTE B_, 4
	WAIT
	INSTR 12
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	NOTE D_, 3
	WAIT
	NOTE G_, 3
	WAIT
	NOTE B_, 3
	WAIT
	NOTE C_, 4
	WAIT
	INSTR 13
	NOTE E_, 6
	NOTE D_, 6
	NOTE E_, 6
	REST
	NOTE E_, 6
	NOTE D_, 6
	NOTE C_, 6
	WAIT
	INSTR 12
	NOTE E_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE C_, 4
	WAIT
	NOTE D_, 4
	WAIT
	INSTR 13
	NOTE Fsh, 6
	NOTE E_, 6
	NOTE Fsh, 6
	REST
	NOTE Fsh, 6
	NOTE E_, 6
	NOTE D_, 6
	WAIT
	INSTR 12
	NOTE A_, 3
	WAIT
	NOTE D_, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE G_, 4
	WAIT
	INSTR 13
	PORTA $05, $04
	NOTE G_, 5
	WAIT
	NOTE B_, 5
	WAIT
	NOTE D_, 6
	WAIT
	NOTE G_, 6
	WAIT
	NOTE B_, 5
	WAIT
	NOTE D_, 6
	PORTA_OFF
	WAIT
	INSTR 12
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	WAIT
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	WAIT
	NOTE B_, 3
	NOTE B_, 3
	NOTE B_, 3
	WAIT
	NOTE G_, 3
	NOTE Fsh, 3
	NEXT
Pat_56FC:
	VOLENV 15, $00, $1F, $12
	ARP 4
	WAVE Wave_6BD2
	NOTE B_, 3
	WAIT
	NOTE B_, 3
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 4
	WAIT
	NOTE B_, 3
	WAIT
	NOTE B_, 3
	WAIT
	NOTE B_, 4
	WAIT
	NOTE G_, 3
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	NOTE G_, 3
	NOTE B_, 3
	WAIT
	NOTE B_, 3
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 4
	WAIT
	NOTE B_, 3
	WAIT
	NOTE B_, 3
	WAIT
	NOTE B_, 4
	WAIT
	NOTE G_, 3
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	NOTE G_, 3
	NOTE G_, 3
	WAIT
	NOTE G_, 3
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 4
	WAIT
	NOTE Fsh, 3
	WAIT
	NOTE Fsh, 3
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE G_, 3
	WAIT
	NOTE G_, 3
	WAIT
	NOTE G_, 4
	WAIT
	NOTE E_, 3
	WAIT
	NOTE E_, 4
	WAIT
	NOTE Fsh, 3
	WAIT
	NOTE Fsh, 3
	NOTE E_, 3
	INSTR 13
	RELEASE $02, $00
	VIBRATO $08, $01, $05
	NOTE E_, 6
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE E_, 6
	NOTE Fsh, 6
	NOTE G_, 6
	NOTE A_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE Fsh, 6
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	RELEASE $00
	VOLENV 15, $11, $1F, $12
	ARP 4
	WAVE Wave_6BD2
	NOTE A_, 3
	WAIT
	NOTE D_, 4
	WAIT
	NOTE Fsh, 4
	NOTE Fsh, 4
	NEXT
Song2_Ch2:
	dw Pat_57A3
	dw Pat_57A3
	dw Pat_582F
	dw Pat_582F
	ORDER_LOOP Song2_Ch2
Pat_57A3:
	DUTY_50
	LEN 8
	HWENV $F3, $08, $85
	VIBRATO $08, $02, $05
	ARP 4
	NOTE B_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	NOTE C_, 5
	NOTE B_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	NOTE C_, 5
	NOTE B_, 4
	WAIT
	NOTE A_, 4
	NOTE C_, 5
	NOTE B_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE B_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE B_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	NOTE B_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	NOTE B_, 3
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	NOTE B_, 3
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	NOTE B_, 3
	WAIT
	NOTE G_, 3
	WAIT
	NOTE B_, 3
	WAIT
	NOTE D_, 4
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE A_, 3
	WAIT
	NOTE C_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	WAIT
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	WAIT
	NOTE B_, 3
	NOTE A_, 3
	NEXT
Pat_582F:
	DUTY_75
	HWENV $F2, $00
	ARP 4
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE E_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE E_, 5
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE B_, 3
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 4
	NOTE B_, 3
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE E_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE E_, 5
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE B_, 3
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 4
	NOTE B_, 3
	NOTE B_, 3
	WAIT
	NOTE B_, 3
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 4
	WAIT
	NOTE B_, 3
	WAIT
	NOTE B_, 3
	WAIT
	NOTE B_, 4
	WAIT
	NOTE G_, 3
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	NOTE G_, 3
	NOTE B_, 3
	WAIT
	NOTE B_, 3
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	NOTE G_, 3
	WAIT
	NOTE G_, 3
	NOTE Fsh, 3
	NOTE E_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	NOTE G_, 3
	NOTE Fsh, 3
	WAIT
	NOTE Fsh, 3
	WAIT
	NOTE Fsh, 3
	NOTE E_, 3
	NOTE D_, 3
	WAIT
	NOTE G_, 3
	WAIT
	NOTE D_, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE A_, 4
	NOTE A_, 4
	NEXT

; Song 3: instrument table 2, arpeggio table 1
PlaySong3:
	ld a, $69
	ld [wInstrTableHi], a
	ld a, $18
	ld [wInstrTable], a
	ld a, HIGH(ArpTable)
	ld [wArpTableHi], a
	ld a, LOW(ArpTable)
	ld [wArpTable], a
	ld de, Song3_Ch1
	call StartMusicCh1
	ld de, Song3_Ch2
	call StartMusicCh2
	ld de, Song3_Ch3
	call StartMusicCh3
	ret
Song3_Ch1:
	dw Pat_5A14
	dw Pat_58F2
	dw Pat_59B3
	dw Pat_5A14
	dw Pat_58F2
	dw Pat_59B3
	dw Pat_59B3
	dw Pat_5A14
	dw Pat_5A14
	ORDER_LOOP Song3_Ch1
Pat_58F2:
	LEN 12
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 3
	WAIT
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 3
	WAIT
	INSTR 0
	NOTE E_, 2
	WAIT
	INSTR 1
	NOTE E_, 3
	WAIT
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 3
	NOTE A_, 3
	INSTR 0
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 3
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE Gsh, 2
	WAIT
	INSTR 1
	NOTE Gsh, 3
	NOTE Gsh, 3
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 3
	WAIT
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 3
	WAIT
	INSTR 0
	NOTE E_, 2
	WAIT
	INSTR 1
	NOTE E_, 3
	WAIT
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 3
	NOTE A_, 3
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 3
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE Dsh, 3
	WAIT
	INSTR 1
	NOTE Dsh, 4
	NOTE Dsh, 4
	INSTR 0
	NOTE E_, 3
	WAIT
	INSTR 1
	NOTE E_, 4
	NOTE E_, 4
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 3
	WAIT
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 3
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 3
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 3
	WAIT
	INSTR 0
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE D_, 3
	WAIT
	INSTR 0
	NOTE E_, 2
	WAIT
	INSTR 1
	NOTE E_, 3
	NOTE E_, 3
	INSTR 0
	NOTE E_, 2
	WAIT
	INSTR 1
	NOTE E_, 3
	NOTE E_, 3
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 3
	WAIT
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 3
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 3
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 3
	WAIT
	INSTR 0
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE D_, 3
	WAIT
	INSTR 0
	NOTE E_, 2
	WAIT
	INSTR 1
	NOTE E_, 3
	WAIT
	INSTR 0
	NOTE A_, 2
	WAIT
	NOTE E_, 2
	NOTE G_, 2
	NEXT
Pat_59B3:
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 3
	WAIT
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 3
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 3
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 3
	WAIT
	INSTR 0
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE D_, 3
	WAIT
	INSTR 0
	NOTE E_, 2
	WAIT
	INSTR 1
	NOTE E_, 3
	NOTE E_, 3
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 3
	NOTE A_, 3
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 3
	WAIT
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 3
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 3
	WAIT
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 3
	WAIT
	INSTR 0
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE D_, 3
	WAIT
	INSTR 0
	NOTE E_, 2
	WAIT
	INSTR 1
	NOTE E_, 3
	NOTE E_, 3
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 3
	WAIT
	NEXT
Pat_5A14:
	LEN 12
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE E_, 2
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 0
	NOTE E_, 2
	WAIT
	INSTR 1
	NOTE B_, 3
	WAIT
	NOTE B_, 3
	WAIT
	INSTR 0
	NOTE E_, 2
	WAIT
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE E_, 2
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 0
	NOTE E_, 2
	WAIT
	INSTR 1
	NOTE B_, 3
	WAIT
	NOTE B_, 3
	WAIT
	INSTR 0
	NOTE E_, 2
	WAIT
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE E_, 2
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 0
	NOTE B_, 2
	WAIT
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE Fsh, 2
	NOTE B_, 2
	WAIT
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE B_, 2
	INSTR 0
	NOTE E_, 2
	WAIT
	INSTR 1
	NOTE E_, 4
	WAIT
	NOTE E_, 4
	WAIT
	INSTR 0
	NOTE E_, 2
	WAIT
	NEXT
Song3_Ch2:
	dw Pat_5B3C
	dw Pat_5A8E
	dw Pat_5ADA
	dw Pat_5B3C
	dw Pat_5A8E
	dw Pat_5ADA
	dw Pat_5ADA
	dw Pat_5BA4
	dw Pat_5BA4
	ORDER_LOOP Song3_Ch2
Pat_5A8E:
	LEN 24
	REST
	INSTR 1
	LEN 48
	NOTE C_, 4
	NOTE A_, 3
	NOTE Gsh, 3
	LEN 12
	NOTE C_, 4
	LEN 36
	NOTE C_, 4
	LEN 48
	NOTE F_, 4
	NOTE B_, 3
	LEN 12
	NOTE G_, 3
	NOTE G_, 3
	WAIT
	WAIT
	NOTE D_, 4
	LEN 36
	NOTE D_, 4
	LEN 48
	NOTE C_, 4
	NOTE A_, 3
	NOTE Gsh, 3
	LEN 12
	NOTE C_, 4
	LEN 36
	NOTE C_, 4
	LEN 48
	NOTE B_, 3
	NOTE E_, 4
	LEN 12
	NOTE Fsh, 4
	NOTE Fsh, 4
	WAIT
	WAIT
	NOTE Gsh, 4
	LEN 36
	NOTE Gsh, 4
	LEN 48
	NOTE C_, 4
	NOTE A_, 3
	NOTE B_, 3
	LEN 12
	NOTE E_, 4
	LEN 36
	NOTE E_, 4
	LEN 48
	NOTE C_, 4
	NOTE A_, 3
	LEN 12
	NOTE Gsh, 3
	NOTE Gsh, 3
	WAIT
	WAIT
	NOTE Gsh, 3
	LEN 36
	NOTE Gsh, 3
	LEN 48
	NOTE C_, 4
	NOTE A_, 3
	NOTE B_, 3
	LEN 12
	NOTE E_, 4
	LEN 36
	NOTE E_, 4
	LEN 48
	NOTE C_, 4
	NOTE D_, 4
	LEN 24
	NOTE B_, 3
	LEN 48
	NOTE E_, 4
	NEXT
Pat_5ADA:
	LEN 12
	INSTR 2
	NOTE C_, 4
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE B_, 3
	NOTE A_, 3
	WAIT
	INSTR 1
	NOTE A_, 3
	INSTR 2
	NOTE C_, 4
	NOTE B_, 3
	WAIT
	INSTR 1
	NOTE B_, 3
	INSTR 2
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	INSTR 1
	NOTE E_, 4
	NOTE E_, 4
	INSTR 2
	NOTE A_, 3
	WAIT
	INSTR 1
	NOTE A_, 3
	INSTR 2
	NOTE G_, 3
	NOTE F_, 3
	WAIT
	INSTR 1
	NOTE B_, 3
	INSTR 2
	NOTE A_, 3
	NOTE Gsh, 3
	WAIT
	INSTR 1
	NOTE Gsh, 3
	NOTE Gsh, 3
	INSTR 2
	NOTE A_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	NOTE C_, 4
	INSTR 2
	NOTE C_, 4
	WAIT
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE B_, 3
	NOTE A_, 3
	WAIT
	INSTR 1
	NOTE A_, 3
	INSTR 2
	NOTE C_, 4
	NOTE B_, 3
	WAIT
	INSTR 1
	NOTE B_, 3
	INSTR 2
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	INSTR 1
	NOTE E_, 4
	NOTE E_, 4
	INSTR 2
	NOTE A_, 3
	WAIT
	INSTR 1
	NOTE A_, 3
	INSTR 2
	NOTE G_, 3
	NOTE F_, 3
	WAIT
	INSTR 1
	NOTE B_, 3
	INSTR 2
	NOTE A_, 3
	NOTE Gsh, 3
	WAIT
	INSTR 1
	NOTE Gsh, 3
	NOTE Gsh, 3
	INSTR 2
	NOTE E_, 3
	WAIT
	INSTR 1
	NOTE C_, 4
	WAIT
	NEXT
Pat_5B3C:
	LEN 12
	INSTR 5
	NOTE A_, 4
	WAIT
	INSTR 1
	NOTE E_, 4
	INSTR 5
	NOTE A_, 4
	WAIT
	WAIT
	INSTR 1
	NOTE E_, 4
	INSTR 5
	NOTE A_, 4
	INSTR 5
	NOTE Gsh, 4
	WAIT
	INSTR 1
	NOTE Dsh, 4
	INSTR 5
	NOTE Gsh, 4
	INSTR 1
	NOTE Dsh, 4
	INSTR 5
	NOTE Gsh, 4
	WAIT
	WAIT
	INSTR 5
	NOTE A_, 4
	WAIT
	INSTR 1
	NOTE E_, 4
	INSTR 5
	NOTE A_, 4
	WAIT
	WAIT
	INSTR 1
	NOTE E_, 4
	INSTR 5
	NOTE A_, 4
	INSTR 5
	NOTE Gsh, 4
	WAIT
	INSTR 1
	NOTE Dsh, 4
	INSTR 5
	NOTE Gsh, 4
	INSTR 1
	NOTE Dsh, 4
	INSTR 5
	NOTE Gsh, 4
	WAIT
	WAIT
	INSTR 5
	NOTE A_, 4
	WAIT
	INSTR 1
	NOTE E_, 4
	INSTR 5
	NOTE A_, 4
	WAIT
	WAIT
	INSTR 1
	NOTE E_, 4
	INSTR 5
	NOTE A_, 4
	WAIT
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 5
	NOTE A_, 4
	WAIT
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 5
	NOTE A_, 4
	INSTR 5
	NOTE B_, 4
	WAIT
	INSTR 1
	NOTE Fsh, 4
	INSTR 5
	NOTE B_, 4
	WAIT
	WAIT
	INSTR 1
	NOTE Fsh, 4
	INSTR 5
	NOTE B_, 4
	WAIT
	WAIT
	INSTR 1
	NOTE Gsh, 4
	INSTR 5
	NOTE B_, 4
	INSTR 1
	NOTE Gsh, 4
	INSTR 5
	NOTE B_, 4
	WAIT
	WAIT
	NEXT
Pat_5BA4:
	LEN 48
	DUTY_50
	HWENV $70, $00
	VIBRATO $00, $02, $05
	PORTA $0E, $08
	ARP_OFF
	NOTE E_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE B_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE B_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE C_, 5
	NOTE Fsh, 4
	NOTE Dsh, 5
	PORTA_OFF
	LEN 12
	NOTE Gsh, 4
	WAIT
	INSTR 1
	NOTE E_, 4
	NOTE F_, 4
	LEN 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 12
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NEXT
Song3_Ch3:
	dw Pat_5CF6
	dw Pat_5BE3
	dw Pat_5C94
	dw Pat_5CEF
	dw Pat_5BEB
	dw Pat_5C94
	dw Pat_5C94
	dw Pat_5D66
	ORDER_LOOP Song3_Ch3
Pat_5BE3:
	CH_TRANSPOSE $18
	WAVE Wave_6B82
	PAT_GOTO Pat_5BF0
Pat_5BEB:
	CH_TRANSPOSE $0C
	WAVE Wave_6BA2
Pat_5BF0:
	VOLENV 11, $14, $00, $11
	RELEASE $C2, $60
	LEN 12
	VIBRATO $0C, $01, $05
	DRUMS $0C, DrumPat_6A8E
	NOTE E_, 4
	WAIT
	WAIT
	NOTE C_, 4
	NOTE A_, 3
	WAIT
	WAIT
	NOTE C_, 4
	NOTE B_, 3
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE A_, 3
	PORTA $02, $0C
	NOTE E_, 4
	WAIT
	PORTA_OFF
	NOTE D_, 4
	WAIT
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 16
	NOTE E_, 4
	LEN 12
	NOTE B_, 3
	WAIT
	NOTE E_, 4
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	NOTE C_, 4
	NOTE A_, 3
	WAIT
	WAIT
	NOTE C_, 4
	NOTE B_, 3
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE A_, 3
	PORTA $02, $0C
	NOTE A_, 4
	WAIT
	PORTA_OFF
	NOTE G_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 12
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE B_, 4
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	LEN 4
	NOTE B_, 3
	NOTE C_, 4
	LEN 40
	NOTE B_, 3
	LEN 12
	NOTE A_, 4
	WAIT
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	LEN 4
	NOTE B_, 4
	NOTE C_, 5
	LEN 16
	NOTE B_, 4
	LEN 48
	NOTE A_, 4
	NEXT
Pat_5C94:
	LEN 12
	DRUMS $06, DrumPat_6AAF
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 12
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 12
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	LEN 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 12
	NOTE C_, 4
	WAIT
	WAIT
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 12
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 12
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE Gsh, 3
	WAIT
	LEN 4
	NOTE A_, 3
	NOTE B_, 3
	LEN 40
	NOTE A_, 3
	NEXT
Pat_5CEF:
	DRUMS $06, DrumPat_6B01
	PAT_GOTO Pat_5CFA
Pat_5CF6:
	DRUMS $0C, DrumPat_6AF0
Pat_5CFA:
	LEN 12
	CH_TRANSPOSE $00
	INSTR 4
	NOTE E_, 4
	WAIT
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE E_, 4
	WAIT
	WAIT
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE E_, 4
	INSTR 4
	NOTE Dsh, 4
	WAIT
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 4
	WAIT
	WAIT
	INSTR 4
	NOTE E_, 4
	WAIT
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE E_, 4
	WAIT
	WAIT
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE E_, 4
	INSTR 4
	NOTE Dsh, 4
	WAIT
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE Dsh, 4
	WAIT
	WAIT
	INSTR 4
	NOTE E_, 4
	WAIT
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE E_, 4
	WAIT
	WAIT
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE E_, 4
	INSTR 4
	NOTE F_, 4
	WAIT
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE F_, 4
	WAIT
	WAIT
	INSTR 3
	NOTE A_, 3
	INSTR 4
	NOTE F_, 4
	INSTR 4
	NOTE Fsh, 4
	WAIT
	INSTR 3
	NOTE B_, 3
	INSTR 4
	NOTE Fsh, 4
	WAIT
	WAIT
	INSTR 3
	NOTE B_, 3
	INSTR 4
	NOTE Fsh, 4
	INSTR 4
	NOTE Gsh, 4
	WAIT
	INSTR 3
	NOTE B_, 3
	INSTR 4
	NOTE Gsh, 4
	INSTR 3
	NOTE B_, 3
	INSTR 4
	NOTE Gsh, 4
	WAIT
	WAIT
	NEXT
Pat_5D66:
	DRUMS $06, DrumPat_6B01
	VIBRATO $00, $01, $06
	VOLENV 15, $00, $00, $00
	WAVE Wave_6B72
	RELEASE $00
	PORTA $01, $12
	LENGTH $60
	CH_TRANSPOSE $0C
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE B_, 4
	PORTA $03, $06
	LEN 12
	NOTE E_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 5
	WAIT
	WAIT
	WAIT
	NOTE Gsh, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE E_, 5
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 5
	WAIT
	WAIT
	WAIT
	NOTE Ash, 5
	WAIT
	NOTE B_, 5
	WAIT
	NOTE E_, 6
	WAIT
	WAIT
	WAIT
	NOTE C_, 6
	WAIT
	WAIT
	WAIT
	NOTE A_, 5
	WAIT
	WAIT
	WAIT
	NOTE C_, 6
	WAIT
	WAIT
	WAIT
	NOTE A_, 5
	WAIT
	NOTE F_, 5
	NOTE E_, 5
	NOTE Dsh, 5
	WAIT
	NOTE Fsh, 5
	WAIT
	NOTE A_, 5
	WAIT
	NOTE C_, 6
	WAIT
	NOTE B_, 5
	WAIT
	NOTE Gsh, 5
	WAIT
	NOTE E_, 5
	WAIT
	WAIT
	WAIT
	PORTA_OFF
	NEXT

; Song 4: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong4:
	ld a, HIGH(InstrTable1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable1 - 2)
	ld [wInstrTable], a
	ld de, Song4_Ch1
	call StartMusicCh1
	ld de, Song4_Ch2
	call StartMusicCh2
	ld de, Song4_Ch3
	call StartMusicCh3
	ret
Song4_Ch1:
	dw Pat_6258
	dw Pat_60EF
	dw Pat_5E99
	dw Pat_5EA9
	dw Pat_5E99
	dw Pat_5EA9
	dw Pat_5EA9
	dw Pat_5EA9
	dw Pat_5FA6
	dw Pat_5FA6
	dw Pat_6069
	dw Pat_6069
	dw Pat_614D
	dw Pat_614D
	dw Pat_6176
	dw Pat_6176
	dw Pat_620E
	dw Pat_5E86
	dw Pat_5EA9
	dw Pat_5EA9
	dw Pat_5EA9
	dw Pat_5FA6
	dw Pat_5FA6
	dw Pat_6069
	dw Pat_6069
	dw Pat_6069
	dw Pat_6069
	ORDER_LOOP Song4_Ch1
Song4_Ch2:
	dw Pat_62AB
	dw Pat_5ED4
	dw Pat_5F2A
	dw Pat_5F2A
	dw Pat_5F2A
	dw Pat_5FE7
	dw Pat_5FE7
	dw Pat_60AE
	dw Pat_60AE
	dw Pat_60EF
	dw Pat_61C3
	dw Pat_61C3
	dw Pat_6223
	dw Pat_5ECA
	dw Pat_5ECA
	dw Pat_5FE7
	dw Pat_5FE7
	dw Pat_60AE
	dw Pat_60AE
	dw Pat_60AE
	dw Pat_60AE
	ORDER_LOOP Song4_Ch2
Song4_Ch3:
	dw Pat_62FD
	dw Pat_60EF
	dw Pat_61A2
	dw Pat_5F54
	dw Pat_5F54
	dw Pat_6028
	dw Pat_6028
	dw Pat_6104
	dw Pat_6104
	dw Pat_61B5
	dw Pat_5F31
	dw Pat_5F31
	dw Pat_5F4B
	dw Pat_5F54
	dw Pat_5F54
	dw Pat_6028
	dw Pat_6028
	dw Pat_6104
	dw Pat_6104
	dw Pat_60F7
	dw Pat_60F7
	ORDER_LOOP Song4_Ch3
Pat_5E86:
	LEN 10
	TRANSPOSE $01
	HWENV $F4, $00
	ARP 0
	DUTY_50
	VIBRATO $0A, $04, $06
	DRUMS $0A, DrumPat_6370
	PAT_GOTO Pat_5EA9
Pat_5E99:
	LEN 10
	TRANSPOSE $01
	HWENV $F4, $00
	ARP 0
	DUTY_50
	VIBRATO $0A, $04, $06
	DRUMS $0A, DrumPat_635E
Pat_5EA9:
	NOTE D_, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 2
	WAIT
	NOTE D_, 2
	WAIT
	NOTE A_, 2
	WAIT
	NOTE D_, 3
	WAIT
	NOTE A_, 2
	WAIT
	NOTE D_, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 2
	WAIT
	NOTE D_, 2
	WAIT
	NOTE A_, 2
	WAIT
	NOTE D_, 3
	WAIT
	NOTE A_, 2
	WAIT
	NEXT
Pat_5ECA:
	LEN 10
	ARP 5
	DUTY_12
	HWENV $F2, $0A, $82
	PAT_GOTO Pat_5F31
Pat_5ED4:
	TRANSPOSE $01
	LEN 10
	ARP 5
	DUTY_12
	HWENV $81, $0A, $41
	NOTE D_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE F_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE E_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE D_, 4
	WAIT
	NOTE A_, 3
	WAIT
	HWENV $A1, $0A, $51
	NOTE D_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE F_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE E_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE D_, 4
	WAIT
	NOTE A_, 3
	WAIT
	HWENV $C1, $0A, $61
	NOTE D_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE F_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE E_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE D_, 4
	WAIT
	NOTE A_, 3
	WAIT
	HWENV $D1, $0A, $71
	NOTE D_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE F_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE E_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE D_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NEXT
Pat_5F2A:
	LEN 10
	ARP 5
	DUTY_12
	HWENV $F1, $0A, $81
Pat_5F31:
	PAT_CALL Pat_5F3A
	PAT_CALL Pat_5F3A
	PAT_CALL Pat_5F3A
Pat_5F3A:
	NOTE D_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE F_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE E_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE D_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NEXT
Pat_5F4B:
	PAT_CALL Pat_5F3A
	PAT_CALL Pat_5F3A
	PAT_GOTO Pat_5F3A
Pat_5F54:
	ARP_OFF
	LEN 10
	VOLENV 9, $15, $1F, $19
	VIBRATO $14, $01, $06
	RELEASE $02, $A1
	WAVE Wave_63A4
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE E_, 5
	WAIT
	WAIT
	NOTE F_, 5
	NOTE E_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	WAIT
	NOTE B_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	ARP_OFF
	NEXT
Pat_5FA6:
	NOTE F_, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 2
	WAIT
	NOTE F_, 2
	WAIT
	NOTE C_, 3
	WAIT
	NOTE F_, 3
	WAIT
	NOTE C_, 3
	WAIT
	NOTE F_, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 2
	WAIT
	NOTE F_, 2
	WAIT
	NOTE C_, 3
	WAIT
	NOTE F_, 3
	WAIT
	NOTE C_, 3
	WAIT
	NOTE G_, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE D_, 2
	WAIT
	NOTE G_, 2
	WAIT
	NOTE D_, 3
	WAIT
	NOTE G_, 3
	WAIT
	NOTE D_, 3
	WAIT
	NOTE G_, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE D_, 2
	WAIT
	NOTE G_, 2
	WAIT
	NOTE D_, 3
	WAIT
	NOTE G_, 3
	WAIT
	NOTE D_, 3
	WAIT
	NEXT
Pat_5FE7:
	NOTE F_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE F_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE E_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE C_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE F_, 3
	WAIT
	NOTE A_, 3
	WAIT
	NOTE F_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE E_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE C_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE D_, 3
	WAIT
	NOTE G_, 3
	WAIT
	NOTE D_, 4
	WAIT
	NOTE G_, 3
	WAIT
	NOTE C_, 4
	WAIT
	NOTE G_, 3
	WAIT
	NOTE B_, 3
	WAIT
	NOTE G_, 3
	WAIT
	NOTE D_, 3
	WAIT
	NOTE G_, 3
	WAIT
	NOTE D_, 4
	WAIT
	NOTE G_, 3
	WAIT
	NOTE C_, 4
	WAIT
	NOTE G_, 3
	WAIT
	NOTE B_, 3
	WAIT
	NOTE G_, 3
	WAIT
	NEXT
Pat_6028:
	NOTE C_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE B_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE B_, 3
	WAIT
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	NEXT
Pat_6069:
	DRUMS $0A, DrumPat_6382
	NOTE D_, 2
	WAIT
	WAIT
	WAIT
	NOTE D_, 3
	WAIT
	NOTE C_, 2
	WAIT
	NOTE D_, 2
	WAIT
	NOTE A_, 2
	WAIT
	NOTE D_, 3
	WAIT
	NOTE A_, 2
	WAIT
	NOTE D_, 2
	WAIT
	WAIT
	WAIT
	NOTE D_, 3
	WAIT
	NOTE C_, 2
	WAIT
	NOTE D_, 2
	WAIT
	NOTE A_, 2
	WAIT
	NOTE D_, 3
	WAIT
	NOTE A_, 2
	WAIT
	NOTE D_, 2
	WAIT
	WAIT
	WAIT
	NOTE D_, 3
	WAIT
	NOTE C_, 2
	WAIT
	NOTE D_, 2
	WAIT
	NOTE A_, 2
	WAIT
	NOTE D_, 3
	WAIT
	NOTE A_, 2
	WAIT
	NOTE D_, 2
	WAIT
	WAIT
	WAIT
	NOTE D_, 3
	WAIT
	NOTE C_, 2
	WAIT
	NOTE D_, 2
	WAIT
	NOTE A_, 2
	WAIT
	NOTE D_, 3
	WAIT
	NOTE A_, 2
	WAIT
	NEXT
Pat_60AE:
	NOTE D_, 3
	WAIT
	NOTE A_, 3
	NOTE D_, 4
	NOTE F_, 4
	WAIT
	NOTE A_, 3
	NOTE D_, 4
	NOTE E_, 4
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE D_, 3
	WAIT
	NOTE A_, 3
	NOTE D_, 4
	NOTE F_, 4
	WAIT
	NOTE A_, 3
	NOTE D_, 4
	NOTE E_, 4
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE D_, 3
	WAIT
	NOTE A_, 3
	NOTE D_, 4
	NOTE F_, 4
	WAIT
	NOTE A_, 3
	NOTE D_, 4
	NOTE E_, 4
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE D_, 3
	WAIT
	NOTE A_, 3
	NOTE D_, 4
	NOTE F_, 4
	WAIT
	NOTE A_, 3
	NOTE D_, 4
	NOTE E_, 4
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	WAIT
	NOTE A_, 3
	WAIT
	NEXT
Pat_60EF:
	LENGTH $A0
	WAIT
	WAIT
	WAIT
	WAIT
	LEN 10
	NEXT
Pat_60F7:
	WAVE Wave_6BC2
	ARP 6
	PAT_GOTO Pat_6108

; Unreferenced (6 bytes)
	db $79, $C2, $6B, $7D, $08, $61
Pat_6104:
	WAVE Wave_6BB2
	ARP_OFF
Pat_6108:
	CH_TRANSPOSE $0C
	NOTE D_, 3
	WAIT
	WAIT
	WAIT
	NOTE A_, 3
	WAIT
	WAIT
	WAIT
	NOTE G_, 3
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 3
	WAIT
	NOTE D_, 3
	WAIT
	WAIT
	WAIT
	NOTE G_, 3
	WAIT
	WAIT
	WAIT
	NOTE E_, 3
	WAIT
	NOTE F_, 3
	WAIT
	WAIT
	WAIT
	NOTE C_, 3
	WAIT
	NOTE D_, 3
	WAIT
	WAIT
	WAIT
	NOTE A_, 3
	WAIT
	WAIT
	WAIT
	NOTE G_, 3
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 3
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	CH_TRANSPOSE $00
	NEXT
Pat_614D:
	HWENV $86, $00
	VIBRATO $0A, $04, $06
	ARP 0
	NOTE D_, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 2
	WAIT
	NOTE D_, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 2
	WAIT
	NOTE D_, 2
	WAIT
	WAIT
	WAIT
	NOTE A_, 2
	WAIT
	WAIT
	WAIT
	NEXT
Pat_6176:
	PAT_CALL Pat_614D
	ARP_OFF
	HWENV $D1, $03, $66
	VIB_OFF
	DUTY_75
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE D_, 4
	NOTE C_, 4
	NOTE G_, 4
	WAIT
	NOTE E_, 4
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	NOTE A_, 4
	WAIT
	DUTY_50
	NEXT
Pat_61A2:
	VOLENV 4, $1F, $1F, $5F
	VIB_OFF
	ARP 8
	WAVE Wave_714E
	LENGTH $A0
	ARP 8
	NOTE C_, 5
	WAIT
	NOTE C_, 4
	WAIT
	LEN 10
	NEXT

; Unreferenced (1 bytes)
	db $6A
Pat_61B5:
	VOLENV 15, $00, $43, $15
	RELEASE $00
	DRUMS_OFF
	ARP 5
	WAVE Wave_6BE2
	PAT_GOTO Pat_5F31
Pat_61C3:
	HWENV $D1, $03, $66
	DUTY_75
	ARP_OFF
	NOTE E_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE E_, 5
	WAIT
	WAIT
	WAIT
	NOTE D_, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE D_, 5
	WAIT
	WAIT
	WAIT
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	NOTE D_, 5
	LEN 8
	NOTE B_, 4
	LEN 6
	NOTE C_, 5
	NOTE B_, 4
	LEN 10
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE C_, 5
	WAIT
	WAIT
	WAIT
	NOTE B_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NEXT
Pat_620E:
	DUTY_75
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE F_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	DUTY_50
	PAT_GOTO Pat_5E99
Pat_6223:
	NOTE C_, 5
	WAIT
	NOTE B_, 4
	NOTE A_, 4
	NOTE B_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE F_, 4
	WAIT
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	LEN 8
	NOTE E_, 4
	LEN 6
	NOTE F_, 4
	NOTE E_, 4
	LEN 10
	NOTE D_, 4
	NOTE C_, 4
	NEXT
Pat_6258:
	ARP_OFF
	RELEASE $00
	DRUMS_OFF
	HWENV $59, $28, $D7
	DUTY_12
	VIBRATO $14, $01, $06
	LEN 10
	NOTE Dsh, 4
	WAIT
	WAIT
	WAIT
	NOTE Ash, 4
	WAIT
	WAIT
	WAIT
	NOTE Csh, 4
	WAIT
	WAIT
	WAIT
	NOTE Ash, 4
	WAIT
	WAIT
	WAIT
	NOTE Gsh, 4
	WAIT
	NOTE Fsh, 4
	NOTE F_, 4
	NOTE Dsh, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 4
	WAIT
	WAIT
	WAIT
	NOTE B_, 3
	WAIT
	WAIT
	WAIT
	NOTE Ash, 3
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE F_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE F_, 4
	WAIT
	WAIT
	WAIT
	NOTE F_, 4
	WAIT
	WAIT
	WAIT
	LENGTH $50
	NOTE D_, 4
	WAIT
	NEXT
Pat_62AB:
	ARP_OFF
	RELEASE $00
	HWENV $59, $28, $D7
	DUTY_12
	LEN 10
	VIBRATO $14, $01, $06
	NOTE Fsh, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE F_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Csh, 4
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	NOTE Gsh, 3
	WAIT
	NOTE Ash, 3
	WAIT
	NOTE B_, 3
	WAIT
	WAIT
	WAIT
	NOTE Gsh, 3
	WAIT
	WAIT
	WAIT
	NOTE Fsh, 3
	WAIT
	NOTE Ash, 3
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE Ash, 3
	WAIT
	NOTE Dsh, 4
	WAIT
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	NOTE B_, 3
	WAIT
	WAIT
	WAIT
	LENGTH $50
	NOTE A_, 3
	WAIT
	NEXT
Pat_62FD:
	ARP_OFF
	RELEASE $00
	WAVE Wave_6B52
	TRANSPOSE $00
	VOLENV 5, $1F, $1F, $16
	LEN 10
	VIBRATO $14, $04, $06
	NOTE Dsh, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Csh, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Gsh, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE B_, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Ash, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE A_, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Ash, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	TRANSPOSE $01
	VOLENV 5, $FF, $1A, $1F
	LEN 10
	VIBRATO $14, $08, $06
	LENGTH $50
	NOTE D_, 2
	WAIT
	NEXT
DrumPat_635E:
	db DRUM_LEVEL + 14, 1, 0, 0, 0, 0, 0, 1
	db 0, 1, 0, 0, 0, 2, 0, 0
	db 0, DRUM_LOOP
DrumPat_6370:
	db DRUM_LEVEL + 15, 1, 0, 4, 0, 6, 6, 1
	db 0, 1, 0, 6, 6, 2, 0, 6
	db 6, DRUM_LOOP
DrumPat_6382:
	db DRUM_LEVEL + 15, 1, 0, 6, 6, 3, 0, 1
	db 6, 1, 0, 6, 6, 3, 0, 4
	db 0, 1, 0, 6, 6, 3, 0, 1
	db 6, 1, 6, 6, 6, 3, 0, 4
	db 6, DRUM_LOOP
Wave_63A4:
	db $01, $36, $8B, $EF, $FE, $B8, $63, $10
	db $01, $23, $03, $69, $03, $7C, $C7, $30

; Song 5: instrument table 2, arpeggio table 1
PlaySong5:
	ld a, $69
	ld [wInstrTableHi], a
	ld a, $18
	ld [wInstrTable], a
	ld a, HIGH(ArpTable)
	ld [wArpTableHi], a
	ld a, LOW(ArpTable)
	ld [wArpTable], a
	ld de, Song5_Ch1
	call StartMusicCh1
	ld de, Song5_Ch2
	call StartMusicCh2
	ld de, Song5_Ch3
	jp StartMusicCh3
Song5_Ch1:
	dw Pat_63E4
	dw Pat_63E4
	dw Pat_641A

; Unreferenced (4 bytes)
	db $00, $00, $DA, $63
Pat_63E4:
	LEN 11
	DUTY_50
	HWENV $D1, $00
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE E_, 6
	NOTE G_, 6
	NOTE Ash, 2
	NOTE D_, 3
	NOTE F_, 3
	NOTE Ash, 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE Ash, 5
	NOTE D_, 6
	NOTE F_, 6
	NOTE Gsh, 2
	NOTE C_, 3
	NOTE Dsh, 3
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE Gsh, 5
	NOTE C_, 6
	NOTE Dsh, 6
	NOTE G_, 2
	NOTE B_, 2
	NOTE D_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE G_, 5
	NOTE B_, 5
	NOTE D_, 6
	NEXT
Pat_641A:
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
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
	WAIT
	WAIT
	WAIT
	VIBRATO $16, $03, $05
	WAIT
	WAIT
	LENGTH $74
	HWENV $19, $0B, $F7
	NOTE C_, 3
	END

; Unreferenced (1 bytes)
	db $6A
Song5_Ch2:
	dw Pat_6443
	dw Pat_6443
	dw Pat_647C

; Unreferenced (4 bytes)
	db $00, $00, $39, $64
Pat_6443:
	LEN 11
	DUTY_50
	HWENV $0F, $05, $62
	AUTOPAN $06
	NOTE D_, 6
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE E_, 6
	NOTE G_, 6
	NOTE Ash, 2
	NOTE D_, 3
	NOTE F_, 3
	NOTE Ash, 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE Ash, 5
	NOTE D_, 6
	NOTE F_, 6
	NOTE Gsh, 2
	NOTE C_, 3
	NOTE Dsh, 3
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE Gsh, 5
	NOTE C_, 6
	NOTE Dsh, 6
	NOTE G_, 2
	NOTE B_, 2
	NOTE D_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE G_, 5
	NOTE B_, 5
	NEXT
Pat_647C:
	NOTE D_, 6
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
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
	AUTOPAN $00
	WAIT
	WAIT
	VIBRATO $16, $01, $05
	WAIT
	WAIT
	LENGTH $74
	HWENV $19, $11, $F7
	NOTE D_, 5
	END

; Unreferenced (1 bytes)
	db $6A
Song5_Ch3:
	dw Pat_64A7
	dw Pat_64F1
	dw Pat_652E

; Unreferenced (4 bytes)
	db $00, $00, $9D, $64
Pat_64A7:
	FADE $0B, FadeTable_6552
	LEN 11
	VOLENV 5, $5F, $00, $11
	CH_TRANSPOSE $0C
	VIBRATO $28, $02, $05
	PORTA $03, $04
	DRUMS $46, DrumPat_6C50
	WAVE Wave_6B82
	NOTE B_, 4
	WAIT
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NEXT
Pat_64F1:
	PORTA $04, $0A
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE D_, 5
	PORTA $02, $0A
	WAIT
	WAIT
	WAIT
	NOTE E_, 5
	WAIT
	NOTE C_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	PORTA $04, $0A
	NOTE Gsh, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE D_, 5
	PORTA $04, $04
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE G_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NEXT
Pat_652E:
	NOTE E_, 4
	NOTE F_, 4
	VOLENV 15, $1F, $1F, $1F
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	DRUMS_OFF
	FADE_OFF
	VIBRATO $28, $01, $05
	LENGTH $74
	VOLENV 0, $1F, $1F, $18
	NOTE B_, 4
	END
FadeTable_6552:
	db $77, $67, $57, $47, $37, $47, $57, $67
	db $77, $76, $75, $74, $73, $74, $75, $76
	db FADE_LOOP

; Song 6: instrument table 1, arpeggio table 1
PlaySong6:
	ld a, HIGH(InstrTable1 - 2)
	ld [wInstrTableHi], a
	ld a, LOW(InstrTable1 - 2)
	ld [wInstrTable], a
	ld a, HIGH(ArpTable)
	ld [wArpTableHi], a
	ld a, LOW(ArpTable)
	ld [wArpTable], a
	ld de, Song6_Ch1
	call StartMusicCh1
	ld de, Song6_Ch2
	call StartMusicCh2
	ld de, Song6_Ch3
	call StartMusicCh3
	ret
Song6_Ch1:
	dw Pat_660F
	dw Pat_66A4
	dw Pat_66A4
	dw Pat_676F
	dw Pat_680F
	dw Pat_6872
	ORDER_LOOP Song6_Ch1
Song6_Ch2:
	dw Pat_65E7
	dw Pat_667B
	dw Pat_667B
	dw Pat_6732
	dw Pat_67E8
	dw Pat_6866
	ORDER_LOOP Song6_Ch2
Song6_Ch3:
	dw Pat_65BA
	dw Pat_6648
	dw Pat_6648
	dw Pat_66E5
	dw Pat_67C2
	dw Pat_6851
	ORDER_LOOP Song6_Ch3
Pat_65BA:
	VOLENV 15, $00, $00, $00
	ARP_OFF
	RELEASE $00
	DRUMS $0C, DrumPat_6A48
	CH_TRANSPOSE $24
	WAVE Wave_6B72
	VIBRATO $00, $01, $06
	LENGTH $60
	PORTA $02, $0A
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	PORTA $03, $0A
	NOTE D_, 2
	NOTE G_, 2
	PORTA $04, $14
	NOTE A_, 2
	VOLENV 15, $1F, $1F, $17
	NOTE A_, 3
	PORTA_OFF
	NEXT
Pat_65E7:
	LENGTH $30
	DUTY_75
	HWENV $72, $0F, $17
	VIBRATO $09, $01, $06
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	HWENV $82, $0F, $27
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	HWENV $92, $0F, $37
	NOTE F_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE G_, 4
	HWENV $A2, $0F, $47
	NOTE A_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NEXT
Pat_660F:
	LEN 24
	DUTY_75
	HWENV $72, $0F, $17
	VIBRATO $09, $01, $06
	LEN 25
	NOTE C_, 5
	LEN 24
	NOTE E_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE C_, 5
	NOTE E_, 4
	HWENV $82, $0F, $27
	NOTE C_, 5
	NOTE F_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE C_, 5
	NOTE E_, 4
	HWENV $92, $0F, $37
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE B_, 4
	NOTE D_, 4
	NOTE B_, 4
	NOTE D_, 4
	HWENV $A2, $0F, $47
	NOTE C_, 5
	NOTE E_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE D_, 5
	NOTE E_, 4
	NOTE E_, 5
	NOTE E_, 4
	NEXT
Pat_6648:
	LEN 24
	CH_TRANSPOSE $00
	WAVE Wave_6B52
	VIBRATO $0C, $0A, $06
	RELEASE $02, $00
	VOLENV 15, $11, $18, $17
	ARP 0
	NOTE A_, 2
	WAIT
	WAIT
	NOTE A_, 2
	NOTE G_, 2
	WAIT
	WAIT
	NOTE G_, 2
	NOTE F_, 2
	WAIT
	WAIT
	NOTE F_, 2
	NOTE D_, 2
	WAIT
	NOTE G_, 2
	WAIT
	NOTE A_, 2
	WAIT
	WAIT
	NOTE A_, 2
	NOTE G_, 2
	WAIT
	WAIT
	NOTE G_, 2
	NOTE F_, 2
	WAIT
	WAIT
	NOTE F_, 2
	NOTE E_, 2
	WAIT
	NOTE G_, 2
	WAIT
	NEXT
Pat_667B:
	HWENV $C2, $0F, $37
	LEN 24
	NOTE A_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE B_, 3
	LEN 12
	NOTE A_, 3
	NOTE B_, 3
	WAIT
	NOTE G_, 3
	NEXT
Pat_66A4:
	HWENV $C2, $0F, $37
	LEN 12
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE D_, 5
	NOTE E_, 5
	NOTE B_, 4
	WAIT
	NOTE B_, 4
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 5
	NOTE D_, 5
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	NOTE A_, 4
	LEN 24
	NOTE E_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	LEN 12
	NOTE G_, 4
	NOTE A_, 4
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	NOTE D_, 4
	WAIT
	WAIT
	NEXT
Pat_66E5:
	DRUMS $0C, DrumPat_6A59
	PAT_CALL Pat_6713
	PAT_CALL Pat_6713
	PAT_CALL Pat_6713
	LEN 12
	NOTE F_, 2
	WAIT
	WAIT
	INSTR 11
	NOTE F_, 5
	NOTE A_, 5
	NOTE C_, 6
	INSTR 10
	NOTE F_, 2
	WAIT
	NOTE G_, 2
	WAIT
	WAIT
	NOTE A_, 2
	WAIT
	WAIT
	NOTE B_, 2
	WAIT
	LEN 24
	NOTE F_, 2
	WAIT
	WAIT
	NOTE F_, 2
	VOLENV 15, $11, $14, $1E
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	WAIT
	NEXT
Pat_6713:
	LEN 12
	NOTE F_, 2
	WAIT
	WAIT
	INSTR 11
	NOTE F_, 5
	NOTE A_, 5
	NOTE C_, 6
	INSTR 10
	NOTE F_, 2
	WAIT
	NOTE G_, 2
	WAIT
	WAIT
	INSTR 11
	NOTE G_, 5
	NOTE B_, 5
	NOTE D_, 6
	INSTR 10
	NOTE G_, 2
	WAIT
	LEN 24
	NOTE C_, 3
	WAIT
	WAIT
	NOTE C_, 3
	NOTE C_, 3
	WAIT
	NOTE G_, 2
	WAIT
	NEXT
Pat_6732:
	HWENV $E2, $0F, $67
	PAT_CALL Pat_675D
	PAT_CALL Pat_675D
	PAT_CALL Pat_675D
	NOTE A_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE F_, 3
	NOTE B_, 3
	LEN 12
	NOTE G_, 3
	NOTE A_, 3
	WAIT
	NOTE G_, 3
	LEN 24
	NOTE G_, 3
	NOTE F_, 3
	NOTE C_, 3
	NOTE F_, 3
	NOTE C_, 3
	LEN 12
	WAIT
	LEN 24
	NOTE F_, 3
	NOTE C_, 4
	HWENV $F3, $0F, $97
	NOTE A_, 4
	LEN 12
	NOTE F_, 5
	LEN 24
	NEXT
Pat_675D:
	LEN 24
	NOTE A_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE F_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NEXT
Pat_676F:
	HWENV $E2, $0F, $67
	PAT_CALL Pat_67A1
	PAT_CALL Pat_67A1
	PAT_CALL Pat_67A1
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	NOTE B_, 3
	WAIT
	NOTE A_, 3
	WAIT
	WAIT
	WAIT
	NOTE A_, 3
	WAIT
	WAIT
	WAIT
	NOTE C_, 3
	WAIT
	NOTE A_, 3
	WAIT
	HWENV $F3, $0F, $97
	NOTE F_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NEXT
Pat_67A1:
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE F_, 4
	NOTE E_, 4
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	NEXT
Pat_67C2:
	LEN 24
	NOTE C_, 3
	WAIT
	WAIT
	NOTE C_, 3
	NOTE Ash, 2
	WAIT
	WAIT
	NOTE Ash, 2
	NOTE F_, 2
	WAIT
	WAIT
	NOTE F_, 2
	NOTE G_, 2
	WAIT
	NOTE Ash, 2
	WAIT
	NOTE C_, 3
	WAIT
	WAIT
	NOTE C_, 3
	NOTE Ash, 2
	WAIT
	WAIT
	NOTE Ash, 2
	NOTE F_, 2
	WAIT
	WAIT
	NOTE F_, 2
	VOLENV 15, $11, $14, $1A
	NOTE G_, 2
	WAIT
	NOTE Ash, 2
	WAIT
	NEXT
Pat_67E8:
	NOTE E_, 5
	NOTE G_, 4
	NOTE E_, 5
	NOTE G_, 4
	NOTE D_, 5
	NOTE F_, 4
	NOTE D_, 5
	NOTE F_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE D_, 5
	NOTE G_, 4
	NOTE D_, 5
	NOTE D_, 5
	NOTE G_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE Ash, 3
	NOTE F_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE F_, 3
	NOTE C_, 4
	NOTE D_, 4
	LEN 12
	NOTE B_, 3
	WAIT
	NOTE G_, 3
	WAIT
	LEN 16
	NOTE Ash, 3
	NOTE F_, 4
	WAIT
	LEN 24
	NEXT
Pat_680F:
	NOTE G_, 5
	WAIT
	WAIT
	WAIT
	NOTE G_, 5
	WAIT
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	WAIT
	WAIT
	WAIT
	NOTE G_, 5
	WAIT
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE A_, 5
	NOTE G_, 5
	WAIT
	WAIT
	NOTE E_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE E_, 5
	WAIT
	WAIT
	WAIT
	NOTE E_, 5
	WAIT
	NOTE F_, 5
	NOTE G_, 5
	NOTE E_, 5
	WAIT
	WAIT
	WAIT
	NOTE E_, 5
	WAIT
	NOTE F_, 5
	NOTE G_, 5
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE D_, 5
	NOTE E_, 5
	NOTE D_, 5
	WAIT
	WAIT
	WAIT
	LEN 16
	NOTE D_, 5
	NOTE C_, 5
	NOTE G_, 4
	LEN 12
	NEXT
Pat_6851:
	LEN 24
	NOTE C_, 2
	WAIT
	WAIT
	NOTE C_, 2
	NOTE C_, 2
	WAIT
	WAIT
	WAIT
	VOLENV 15, $12, $1F, $15
	DRUMS $FA, DrumPat_6A7A
	LENGTH $C0
	NOTE C_, 2
	NEXT
Pat_6866:
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	LENGTH $C0
	NOTE C_, 4
	NEXT
Pat_6872:
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	LEN 8
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	LENGTH $BF
	NOTE E_, 4
	NEXT

; Instrument table 1, entries 1..14 (the song routines point 2 bytes before:
; entry 0 is never read)
InstrTable1:
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
Instr1_0:
	WAVE Wave_6B52
	VOLENV 15, $11, $18, $14
	ARP 0
	VIBRATO $0A, $08, $04
	END
Instr1_1:
	AUTODUTY $03
	HWENV $F1, $00
	ARP 2
	END
Instr1_2:
	AUTODUTY $03
	HWENV $F1, $00
	ARP 3
	END
Instr1_3:
	DUTY_50
	HWENV $F3, $00
	ARP 0
	END
Instr1_4:
	WAVE Wave_6B42
	VOLENV 15, $00, $1F, $11
	ARP 2
	END
Instr1_5:
	VOLENV 15, $11, $15, $12
	ARP 0
	VIBRATO $0A, $02, $04
	WAVE Wave_6BA2
	END
Instr1_6:
	VOLENV 15, $00, $00, $00
	WAVE Wave_6B82
	END
Instr1_7:
	DUTY_12
	ARP 0
	HWENV $F2, $00
	END
Instr1_8:
	DUTY_50
	AUTODUTY $03
	HWENV $F1, $00
	ARP 2
	END
Instr1_9:
	DUTY_50
	END
Instr1_10:
	WAVE Wave_6B52
	VIBRATO $0C, $0A, $06
	VOLENV 15, $11, $16, $18
	ARP 0
	END
Instr1_11:
	WAVE Wave_6B72
	VOLENV 15, $11, $18, $12
	ARP 0
	END
Instr1_12:
	WAVE Wave_6BD2
	VOLENV 15, $11, $15, $11
	ARP 0
	END
Instr1_13:
	VOLENV 15, $00, $00, $00
	WAVE Wave_6B82
	END

; Instrument table 2, entries 1..6 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr2_0
	dw Instr2_1
	dw Instr2_2
	dw Instr2_3
	dw Instr2_4
	dw Instr2_5
Instr2_0:
	DUTY_50
	HWENV $F2, $00
	VIBRATO $06, $08, $05
	ARP 0
	END
Instr2_1:
	DUTY_12
	HWENV $F1, $05, $A2
	VIBRATO $04, $02, $05
	ARP 4
	END
Instr2_2:
	DUTY_75
	HWENV $F2, $00
	END
Instr2_3:
	WAVE Wave_6BE2
	VOLENV 15, $00, $1F, $11
	VIBRATO $04, $02, $05
	ARP 4
	END
Instr2_4:
	WAVE Wave_6B42
	VOLENV 4, $00, $00, $00
	VIBRATO $00, $04, $05
	END
Instr2_5:
	DUTY_50
	HWENV $40, $00
	VIBRATO $00, $04, $05
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

; Unreferenced (2 bytes)
	db $BC, $69
Arp0:
	db $0C, $00, ARP_HOLD
Arp1:
	db $00, $0C, $00, $00, $00, $00, $00, $00
	db $00, $00, ARP_LOOP
Arp2:
	db $00, $04, $07, ARP_LOOP
Arp3:
	db $00, $03, $07, ARP_LOOP
Arp4:
	db $00, $0C, $00, ARP_HOLD
Arp5:
	db $0C, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $18, $0C, ARP_HOLD
Arp6:
	db $0C, $0C, $0C, $0C, $00, $00, $00, $00
	db $00, $00, ARP_LOOP
Arp7:
	db $00, $00, $00, $00, $00, $0C, ARP_HOLD
Arp8:
	db $15, $15, $11, $11, $0E, $0E, $09, $09
	db $05, $05, $02, $02, ARP_LOOP

; Unreferenced (13 bytes)
	db $15, $15, $10, $10, $0C, $0C, $09, $09, $04, $04, $00, $00, $6A
DrumPat_69C9:
	db 6, 0, 0, 6, 0, 6, 6, 0
	db 0, 3, 0, 0, DRUM_LOOP
DrumPat_69D6:
	db 6, 0, 6, 3, 0, 6, 6, 0
	db 6, 3, 0, 6, DRUM_LOOP
DrumPat_69E3:
	db 1, 0, 6, 0, 6, 0, 4, 0
	db 6, 0, 6, 0, 1, 0, 6, 0
	db 6, 0, 4, 0, 6, 0, 6, 6
	db 1, 0, 6, 0, 6, 0, 4, 0
	db 6, 0, 6, 0, 1, 0, 6, 0
	db 6, 0, 4, 0, 6, 0, 4, 0
	db DRUM_LOOP
DrumPat_6A14:
	db 1, 0, 6, 0, 6, 0, 2, 0
	db 6, 0, 6, 0, 1, 0, 6, 0
	db 6, 0, 2, 0, 6, 0, 6, 6
	db DRUM_LOOP
DrumPat_6A2D:
	db 6, 0, 0, 0, 6, 0, 4, 0
	db 0, 0, 0, 0, 6, 0, 0, 0
	db 6, 0, 4, 0, 0, 0, 6, 0
	db DRUM_LOOP
DrumPat_6A46:
	db 1, DRUM_LOOP
DrumPat_6A48:
	db 1, 0, 6, 0, 4, 0, 6, 0
	db 1, 0, 6, 0, 4, 0, 1, 0
	db DRUM_LOOP
DrumPat_6A59:
	db 7, 0, 0, 6, 2, 6, 4, 6
	db 1, 6, 4, 6, 2, 6, 1, 6
	db 1, 6, 4, 6, 2, 6, 4, 6
	db 1, 6, 4, 6, 2, 6, 1, 6
	db DRUM_LOOP
DrumPat_6A7A:
	db DRUM_SPEED + 1, 7, DRUM_LOOP
DrumPat_6A7D:
	db 6, 0, 6, 6, 4, 0, 6, 6
	db 6, 0, 6, 6, 4, 6, 6, 6
	db DRUM_LOOP
DrumPat_6A8E:
	db 6, 6, 4, 6, 6, 6, 4, 6
	db 6, 6, 4, 6, 6, 6, 4, 4
	db 6, 6, 4, 6, 6, 6, 4, 6
	db 6, 6, 4, 4, 6, 6, 4, 4
	db DRUM_LOOP
DrumPat_6AAF:
	db 7, 0, 0, 0, 4, 0, 6, 0
	db 1, 0, 6, 0, 4, 0, 6, 6
	db 1, 0, 6, 0, 4, 0, 6, 0
	db 1, 0, 6, 0, 4, 0, 4, 6
	db 1, 0, 6, 0, 4, 0, 6, 0
	db 1, 0, 6, 0, 4, 0, 6, 6
	db 1, 0, 6, 0, 4, 0, 4, 0
	db 1, 0, 6, 0, 4, 0, 4, 6
	db DRUM_LOOP
DrumPat_6AF0:
	db 1, 0, 6, 1, 1, 0, 6, 1
	db 1, 0, 6, 6, 6, 6, 4, 0
	db DRUM_LOOP
DrumPat_6B01:
	db 7, 0, 0, 0, 4, 0, 1, 0
	db 1, 0, 6, 0, 4, 0, 1, 6
	db 1, 0, 6, 0, 4, 0, 6, 0
	db 4, 0, 6, 0, 1, 6, 6, 6
	db 1, 0, 6, 0, 4, 0, 1, 0
	db 1, 0, 6, 0, 4, 0, 1, 6
	db 1, 0, 6, 0, 4, 0, 6, 0
	db 4, 0, 6, 0, 1, 6, 6, 6
	db DRUM_LOOP
Wave_6B42:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
Wave_6B52:
	db $00, $00, $00, $FF, $FF, $FF, $FF, $FF
	db $00, $00, $00, $FF, $FF, $FF, $FF, $FF

; Unreferenced (16 bytes)
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $FF, $FF, $FF
Wave_6B72:
	db $12, $34, $56, $78, $9A, $BC, $DE, $FF
	db $ED, $CB, $A9, $87, $65, $43, $21, $00
Wave_6B82:
	db $FF, $FE, $ED, $B8, $53, $21, $10, $00
	db $00, $01, $12, $35, $8B, $DE, $EF, $FF
Wave_6B92:
	db $63, $10, $01, $47, $74, $10, $01, $36
	db $9C, $EF, $FE, $B8, $8B, $EF, $FE, $C9
Wave_6BA2:
	db $B7, $40, $04, $7B, $CD, $FF, $FE, $DC
	db $02, $46, $8A, $BD, $FD, $BA, $64, $20
Wave_6BB2:
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $ED, $CB, $A9, $87, $65, $43, $21, $00
Wave_6BC2:
	db $FE, $DB, $97, $53, $13, $54, $32, $10
	db $FE, $DC, $BC, $EF, $DB, $85, $32, $10
Wave_6BD2:
	db $00, $00, $00, $00, $00, $00, $FF, $FF
	db $00, $00, $00, $00, $00, $00, $FF, $FF
Wave_6BE2:
	db $00, $00, $00, $00, $00, $00, $00, $FF
	db $00, $00, $00, $00, $00, $00, $00, $FF
Noise43_6BF2:
	db $02, $51, $61, $71, $91, $71, $60, $FF
Noise42_6BFA:
	db $F0, $F0, $D0, $90, $00, $50, $43

; Unreferenced (7 bytes)
	db $F0, $F0, $D0, $90, $80, $50, $41
Noise43_6C08:
	db $60, $52, $42, $41, $22, $11, $04, $FF

; Unreferenced (14 bytes)
	db $F0, $E0, $D0, $B0, $A0, $90, $81, $F0, $E0, $D0, $B0, $A0, $70, $41
Noise43_6C1E:
	db $06, $04, $03, $03, $07, $FF
Noise42_6C24:
	db $F0, $F0, $D0, $C0, $85
Noise43_6C29:
	db $04, $02, $01, $FF
Noise42_6C2D:
	db $80, $50, $33
Noise43_6C30:
	db $04, $02, $06, $FF
Noise42_6C34:
	db $A0, $50, $54
Noise43_6C37:
	db $50, $41, $50, $51, $52, $53, $51, $FF
Noise42_6C3F:
	db $F0, $60, $F0, $60, $D0, $50, $72
Noise43_6C46:
	db $00, $00, $00, $FF
Noise42_6C4A:
	db $2F, $F7, $20
Noise43_6C4D:
	db $00, $00, $FF
DrumPat_6C50:
	db 8, 0, 0, 0, 8, 0, 0, 0
	db 8, 0, 0, 0, 0, 8, 0, 0
	db 0, 9, 0, 0, 0, DRUM_LOOP
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6BF2)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6BF2)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6BFA)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6BFA)
	ld [wNoise42], a
	ret
Drum2:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6C08)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6C08)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6BFA)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6BFA)
	ld [wNoise42], a
	ret
Drum3:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6C37)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6C37)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6C3F)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6C3F)
	ld [wNoise42], a
	ret
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6C30)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6C30)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6C34)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6C34)
	ld [wNoise42], a
	ret
Drum5:
	ret
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6C29)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6C29)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6C2D)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6C2D)
	ld [wNoise42], a
	ret
Drum7:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6C1E)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6C1E)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6C24)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6C24)
	ld [wNoise42], a
	ret
Drum8:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $55
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_6C46)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6C46)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6C4A)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6C4A)
	ld [wNoise42], a
	ret
Drum9:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $55
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_6C4D)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6C4D)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6C4A)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6C4A)
	ld [wNoise42], a
	ret

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

; Sound effect 2
Sfx02:
	VOLENV 15, $12, $1F, $12
	WAVE Wave_6B42
	VIBRATO $01, $08, $05
	GLIDE $FD
	LEN 5
	NOTE C_, 4
	GLIDE $03
	LEN 5
	WAIT
	GLIDE_OFF
	LEN 20
	WAIT
	END

; Sound effect 3
Sfx03:
	CALL_CODE Code_6F70
	VOLENV 15, $12, $1F, $11
	WAVE Wave_6B42
	GLIDE $FD
	LEN 6
	NOTE C_, 4
	NOTE Fsh, 4
	END

; Sound effect 5
Sfx05:
	CALL_CODE Code_700A
	END

; Sound effect 6
Sfx06:
	CALL_CODE Code_7079
	VOLENV 15, $11, $1F, $11
	WAVE Wave_6B42
	LEN 10
	ARP 2
	GLIDE $01
	NOTE A_, 3
	END

; Sound effect 7
Sfx07:
	CALL_CODE Code_6F9D
	VOLENV 15, $11, $1F, $13
	WAVE Wave_715E
	VIBRATO $01, $07, $02
	PORTA $02, $1E
	LEN 35
	NOTE D_, 6
	LEN 1
	NOTE C_, 1
	END

; Sound effect 25
Sfx25:
	VOLENV 15, $11, $1F, $11
	CH_TRANSPOSE $0C
	WAVE Wave_712E
	GLIDE $01
	LEN 3
	NOTE C_, 4
	REST
	NOTE B_, 3
	REST
	NOTE Ash, 3
	REST
	NOTE Gsh, 3
	REST
	NOTE G_, 3
	END

; Sound effect 8
Sfx08:
	WAVE Wave_6BE2
	VOLENV 15, $10, $1F, $11
	ARP 0
	LEN 4
	NOTE C_, 6
	NOTE A_, 5
	NOTE C_, 6
	NOTE A_, 5
	NOTE C_, 6
	NOTE A_, 5
	WAIT
	WAIT
	END

; Sound effect 9
Sfx09:
	WAVE Wave_6BD2
	CALL_CODE Code_7039
	GLIDE $05
	LEN 10
	VOLENV 15, $00, $00, $00
	NOTE A_, 3
	VOLENV 10, $00, $00, $00
	NOTE Ash, 3
	VOLENV 10, $00, $00, $00
	NOTE B_, 3
	VOLENV 5, $00, $00, $00
	NOTE C_, 4
	VOLENV 5, $00, $00, $00
	NOTE Csh, 4
	END

; Sound effect 4
Sfx04:
	WAVE Wave_6B42
	CALL_CODE Code_7039
	VOLENV 0, $1F, $1F, $13
	VIBRATO $01, $14, $07
	LEN 30
	NOTE C_, 6
	WAIT
	END

; Sound effect 10
Sfx10:
	WAVE Wave_6B42
	VOLENV 15, $11, $1F, $12
	LEN 4
	NOTE C_, 6
	NOTE C_, 7
	NOTE C_, 6
	LEN 20
	NOTE C_, 7
	END

; Sound effect 12
Sfx12:
	CALL_CODE Code_6F70
	VOLENV 15, $11, $1F, $12
	ARP 1
	CH_TRANSPOSE $03
	WAVE Wave_716E
	LEN 4
	GLIDE $FD
	NOTE F_, 2
	LEN 3
	REST
	LEN 8
	GLIDE $01
	NOTE Dsh, 2
	GLIDE $FF
	WAIT
	END

; Sound effect 11
Sfx11:
	VOLENV 7, $1F, $1F, $20
	VIBRATO $01, $14, $02
	CH_TRANSPOSE $FC
	WAVE Wave_712E
	LEN 40
	PORTA $05, $28
	NOTE C_, 4
	VOLENV 15, $11, $1F, $12
	LEN 20
	NOTE E_, 4
	LEN 1
	VOLENV 0, $00, $00, $00
	NOTE E_, 2
	END

; Sound effect 20
Sfx20:
	VOLENV 15, $11, $1F, $12
	ARP 0
	WAVE Wave_6B42
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

; Sound effect 19
Sfx19:
	VOLENV 15, $00, $00, $00
	WAVE Wave_716E
	LEN 5
	NOTE A_, 3
	LEN 3
	REST
	LEN 20
	NOTE A_, 3
	END

; Sound effect 18
Sfx18:
	LEN 5
	VOLENV 15, $00, $00, $00
	WAVE Wave_6B52
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
	VOLENV 15, $11, $23, $11
	LEN 5
	ARP 0
	WAVE Wave_6BD2
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

; Sound effect 14
Sfx14:
	CALL_CODE Code_7101
	WAVE Wave_6B72
	VOLENV 15, $11, $1F, $11
	CH_TRANSPOSE $0C
	GLIDE $02
	LEN 9
	REST
	NOTE A_, 2
	NOTE B_, 2
	NOTE C_, 3
	NOTE B_, 2
	END

; Sound effect 21
Sfx21:
	WAVE Wave_6B42
	VOLENV 15, $00, $1F, $11
	GLIDE $FB
	LEN 5
	NOTE E_, 4
	GLIDE $02
	NOTE E_, 4
	END

; Sound effect 22
Sfx22:
	WAVE Wave_6B42
	VOLENV 15, $00, $1F, $11
	LEN 5
	GLIDE $FE
	NOTE E_, 5
	GLIDE $FB
	NOTE E_, 4
	END

; Sound effect 1
Sfx01:
	LEN 5
	ARP 0
	WAVE Wave_6B92
	VOLENV 15, $10, $1F, $12
	NOTE C_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	END

; Sound effect 23
Sfx23:
	LEN 14
	VOLENV 15, $13, $1F, $11
	GLIDE $01
	WAVE Wave_6B42
	NOTE C_, 3
	END

; Sound effect 24
Sfx24:
	CALL_CODE Code_70CB
	VOLENV 15, $11, $1F, $15
	WAVE Wave_6B42
	LEN 9
	GLIDE $FD
	NOTE A_, 3
	END

; Sound effect 15
Sfx15:
	LEN 30
	VOLENV 15, $00, $00, $00
	WAVE Wave_6B72
	VIBRATO $00, $05, $03
	PORTA $02, $1E
	NOTE A_, 5
	NOTE F_, 6
	LEN 1
	NOTE A_, 5
	END

; Sound effect 16
Sfx16:
	VOLENV 15, $11, $2F, $11
	WAVE Wave_713E
	LEN 13
	NOTE C_, 6
	END

; Sound effect 17
Sfx17:
	LEN 4
	VOLENV 15, $11, $2F, $11
	WAVE Wave_713E
	LEN 4
	NOTE Gsh, 5
	LEN 1
	REST
	LEN 4
	NOTE Gsh, 6
	END
Code_6F70:
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6F92)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6F92)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6F98)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6F98)
	ld [wNoise42], a
	ret
Noise43_6F92:
	db $00, $53, $71, $91, $31, $FF
Noise42_6F98:
	db $F1, $FF, $FF, $FF, $00
Code_6F9D:
	ld a, $2D
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_6FBF)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_6FBF)
	ld [wNoise43], a
	ld a, HIGH(Noise42_6FE5)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_6FE5)
	ld [wNoise42], a
	ret
Noise43_6FBF:
	db $03, $93, $80, $72, $70, $56, $54, $60
	db $50, $40, $30, $20, $10, $56, $54, $60
	db $50, $40, $30, $20, $10, $56, $54, $60
	db $50, $40, $30, $20, $10, $56, $54, $60
	db $50, $40, $30, $20, $10, $FF
Noise42_6FE5:
	db $F3, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF
Code_700A:
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_702C)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_702C)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7033)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7033)
	ld [wNoise42], a
	ret
Noise43_702C:
	db $41, $61, $61, $41, $71, $71, $FF
Noise42_7033:
	db $A1, $52, $00, $61, $52, $00
Code_7039:
	ld a, $2D
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $02
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_7064)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7064)
	ld [wNoise43], a
	ld a, HIGH(Noise42_706F)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_706F)
	ld [wNoise42], a
	ret
Noise43_7064:
	db $27, $26, $25, $14, $13, $12, $11, $10
	db $10, $10, $FF
Noise42_706F:
	db $19, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $F2
Code_7079:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $13
	ld [wDrumHold], a
	ld a, $01
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	call NoisePanCentre
	ld a, $F2
	ldh [rNR42], a
	ld a, $80
	ldh [rNR44], a
	ld a, HIGH(Noise43_70AF)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_70AF)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_70AF:
	db $12, $64, $02, $37, $47, $24, $55, $71
	db $07, $44, $60, $36, $84, $82, $64, $02
	db $37, $47, $24, $55, $71, $07, $44, $60
	db $36, $86, $32, $FF
Code_70CB:
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
	ld a, HIGH(Noise43_70F6)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_70F6)
	ld [wNoise43], a
	ld a, HIGH(Noise42_70FC)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_70FC)
	ld [wNoise42], a
	ret
Noise43_70F6:
	db $03, $93, $80, $72, $70, $FF
Noise42_70FC:
	db $F0, $FF, $FF, $FF, $F3
Code_7101:
	ld a, $23
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7123)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7123)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7129)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7129)
	ld [wNoise42], a
	ret
Noise43_7123:
	db $02, $41, $61, $71, $21, $FF
Noise42_7129:
	db $F0, $FF, $FF, $A0, $B3
Wave_712E:
	db $02, $48, $AC, $FF, $FC, $53, $00, $27
	db $9C, $DD, $DC, $B7, $7B, $CD, $DD, $C9
Wave_713E:
	db $00, $00, $00, $00, $CD, $EF, $FD, $EC
	db $00, $12, $21, $00, $DD, $DD, $DD, $DD
Wave_714E:
	db $04, $8B, $DE, $FF, $ED, $CB, $A9, $87
	db $65, $44, $44, $32, $11, $24, $7A, $74
Wave_715E:
	db $20, $24, $68, $AC, $EC, $A8, $64, $20
	db $24, $68, $A8, $64, $20, $24, $68, $64
Wave_716E:
	db $0F, $00, $F0, $F0, $F0, $F0, $00, $0F
	db $0F, $FF, $FF, $00, $FF, $F0, $0F, $0F

; Unreferenced (16 bytes)
	db $BB, $2B, $BB, $2B, $BB, $5B, $2B, $BB, $2B, $BB, $BB, $72, $27, $EB, $BB, $B0
FadeOutTable:
	db $77, $66, $55, $44, $33, $22, $11, $00
	db FADE_END
FadeInTable:
	db $00, $11, $22, $33, $44, $55, $66, $77
	db FADE_END

; Unreferenced (3680 bytes)
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $28, $01, $00, $00, $0E, $00, $00, $00
	db $D5, $FA, $FF, $FF, $D5, $3C, $EF, $7E, $D9, $3C, $AB, $7E, $03, $00, $00, $00
	db $91, $47, $FF, $FF, $08, $00, $00, $00, $00, $00, $00, $00, $43, $3A, $5C, $57
	db $49, $4E, $44, $4F, $57, $53, $5C, $45, $58, $50, $4C, $4F, $52, $45, $52, $2E
	db $45, $58, $45, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
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
	db $28, $01, $00, $00, $02, $00, $00, $00, $E5, $31, $FE, $FF, $D5, $3C, $EA, $7E
	db $D5, $3C, $AB, $7E, $01, $00, $00, $00, $D5, $FA, $FF, $FF, $08, $00, $00, $00
	db $00, $00, $00, $00, $43, $3A, $5C, $4D, $4F, $55, $53, $45, $5C, $57, $42, $55
	db $54, $54, $4F, $4E, $53, $2E, $45, $58, $45, $00, $00, $00, $00, $00, $00, $00
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
	db $00, $00, $00, $00, $00, $00, $00, $00, $28, $01, $00, $00, $02, $00, $00, $00
	db $ED, $1E, $FE, $FF, $D5, $3C, $EA, $7E, $C2, $3C, $AB, $7E, $01, $00, $00, $00
	db $D5, $FA, $FF, $FF, $08, $00, $00, $00, $00, $00, $00, $00, $43, $3A, $5C, $57
	db $49, $4E, $44, $4F, $57, $53, $5C, $53, $59, $53, $54, $45, $4D, $5C, $53, $59
	db $53, $54, $52, $41, $59, $2E, $45, $58, $45, $00, $00, $00, $00, $00, $00, $00
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
	db $28, $01, $00, $00, $02, $00, $00, $00, $6D, $02, $FE, $FF, $D5, $3C, $EA, $7E
	db $CC, $3C, $AB, $7E, $01, $00, $00, $00, $D5, $FA, $FF, $FF, $08, $00, $00, $00
	db $00, $00, $00, $00, $43, $3A, $5C, $57, $49, $4E, $44, $4F, $57, $53, $5C, $4D
	db $41, $43, $4F, $50, $45, $4E, $5C, $4D, $41, $43, $4E, $41, $4D, $45, $2E, $45
	db $58, $45, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
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
	db $00, $00, $00, $00, $00, $00, $00, $00, $28, $01, $00, $00, $02, $00, $00, $00
	db $3D, $67, $FE, $FF, $D5, $3C, $EA, $7E, $D5, $3C, $AB, $7E, $01, $00, $00, $00
	db $D5, $FA, $FF, $FF, $08, $00, $00, $00, $00, $00, $00, $00, $43, $3A, $5C, $57
	db $49, $4E, $44, $4F, $57, $53, $5C, $57, $49, $4E, $50, $4F, $50, $55, $50, $2E
	db $45, $58, $45, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
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
	db $28, $01, $00, $00, $02, $00, $00, $00, $41, $24, $FE, $FF, $D5, $3C, $EA, $7E
	db $D5, $3C, $AB, $7E, $01, $00, $00, $00, $D5, $FA, $FF, $FF, $08, $00, $00, $00
	db $00, $00, $00, $00, $43, $3A, $5C, $57, $49, $4E, $44, $4F, $57, $53, $5C, $51
	db $55, $49, $43, $4B, $52, $45, $53, $2E, $45, $58, $45, $00, $00, $00, $00, $00
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
	db $00, $00, $00, $00, $00, $00, $00, $00, $28, $01, $00, $00, $02, $00, $00, $00
	db $B9, $2A, $FE, $FF, $D5, $3C, $EA, $7E, $C6, $3C, $AB, $7E, $01, $00, $00, $00
	db $D5, $FA, $FF, $FF, $08, $00, $00, $00, $00, $00, $00, $00, $43, $3A, $5C, $57
	db $49, $4E, $44, $4F, $57, $53, $5C, $44, $45, $53, $4B, $4D, $45, $4E, $55, $2E
	db $45, $58, $45, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
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
	db $28, $01, $00, $00, $04, $00, $00, $00, $5D, $13, $FE, $FF, $D5, $3C, $E2, $7E
	db $C0, $3C, $AB, $7E, $02, $00, $00, $00, $D5, $FA, $FF, $FF, $08, $00, $00, $00
	db $00, $00, $00, $00, $43, $3A, $5C, $57, $49, $4E, $44, $4F, $57, $53, $5C, $43
	db $4C, $45, $41, $4E, $53, $57, $45, $45, $50, $5C, $43, $53, $55, $53, $45, $4D
	db $33, $32, $2E, $45, $58, $45, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
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
	db $00, $00, $00, $00, $00, $00, $00, $00, $28, $01, $00, $00, $05, $00, $00, $00
	db $D1, $70, $CF, $FF, $D5, $3C, $ED, $7E, $F5, $3C, $AB, $7E, $03, $00, $00, $00
	db $D5, $FA, $FF, $FF, $08, $00, $00, $00, $00, $00, $00, $00, $43, $3A, $5C, $57
	db $49, $4E, $44, $4F, $57, $53, $5C, $43, $4C, $45, $41, $4E, $53, $57, $45, $45
	db $50, $5C, $43, $53, $49, $4E, $53, $4D, $33, $32, $2E, $45, $58, $45, $00, $00
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
	db $28, $01, $00, $00, $02, $00, $00, $00, $15, $87, $FE, $FF, $D5, $3C, $EA, $7E
	db $D5, $3C, $AB, $7E, $01, $00, $00, $00, $D5, $FA, $FF, $FF, $08, $00, $00, $00
	db $00, $00, $00, $00, $43, $3A, $5C, $57, $49, $4E, $44, $4F, $57, $53, $5C, $53
	db $59, $53, $54, $45, $4D, $5C, $57, $49, $4E, $4F, $41, $33, $38, $36, $2E, $4D
	db $4F, $44, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
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
	db $00, $00, $00, $00, $00, $00, $00, $00, $11, $14, $00, $A0, $70, $F3, $55, $81
	db $3C, $50, $54, $81, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
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
