; =====================================================================
; Sylvester and Tweety: Breakfast on the Run (E) (M6) [C] - Game Boy Color
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o sylvester.o Sylvester_SoundDriver.asm
;   rgblink -o sylvester.gb sylvester.o
;   python tools/cmp_banked.py sylvester.gb "Sylvester and Tweety (E) (M6) [C][!].gbc" 15:4000-7FFF
; (driver and data fill ROM bank 15; the linked file only matches in that range)
;
; Documentation: Sylvester_SoundDriver.md / AJG_SoundEngine_Family.md
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
MACRO REPEAT    ; play the following bytes n times (up to REPEAT_END), n = 2-20
	db $EB + \1
ENDM
MACRO LEN       ; note length in ticks, 1-48
	db $BC + \1
ENDM
MACRO VOLENV    ; start volume + envelope (CH3/SFX): atk (lo=count hi=step), dec (lo=count hi=step), rates (hi=atk lo=dec)
	db $AD + \1, \2, \3, \4
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
DEF DRUM_TEMPO EQU $BC         ; + n: one step every n ticks
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

; Song slot(s) 1, 10, 11, 12: each jumps 9 bytes early, into three TRANSPOSE patterns; they run as code
; (ld l, c / ld [bc], a / ld l, d / ld l, c / ld bc, $696A / nop / ld l, d)
; and fall through into the song routine
	jp Pat_6B85                         ; song slot 1: song 1; jumps 9 bytes early, into three TRANSPOSE patterns; they run as code ...
	jp PlaySong2                       ; song slot 2: song 2
	jp PlaySong3                       ; song slot 3: song 3
	jp PlaySong4                       ; song slot 4: song 4
	jp PlaySong5                       ; song slot 5: song 5
	jp PlaySong6                       ; song slot 6: song 6
	jp PlaySong7                       ; song slot 7: song 7
	jp PlaySong8                       ; song slot 8: song 8
	jp PlaySong9                       ; song slot 9: song 9
	jp Pat_6B85                         ; song slot 10: song 1; jumps 9 bytes early, into three TRANSPOSE patterns; they run as code ...
	jp Pat_6B85                         ; song slot 11: song 1; jumps 9 bytes early, into three TRANSPOSE patterns; they run as code ...
	jp Pat_6B85                         ; song slot 12: song 1; jumps 9 bytes early, into three TRANSPOSE patterns; they run as code ...
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
	sub $EB
	ld l, $39
	ld [hli], a
	ld [hl], e
	inc l
	ld [hl], d
	jp ReadByte

; StreamCommand: REPEAT / LEN / VOLENV / ARP / INSTR ranges, else CmdTable.
StreamCommand:
	cp $ED
	jr nc, Cmd_Repeat
	cp $BD
	jr nc, Cmd_Len
	cp $AD
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
	sub $BC
	ld l, $09
	ld [hl], a
	jp ReadStream

; VOLENV v, atk, dec, rates: start volume v; attack = lo nibble steps of hi nibble;
; decay likewise; rates hi = ticks per attack step, lo = ticks per decay step.
; Only the CH3 and SFX pages use it.
Cmd_VolEnv:
	sub $AD
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
	add a, $71
	ld l, a
	adc a, $70
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
	cp $BD
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
	dw Drum7
	dw Drum8
	dw Drum9
	dw Drum10
	dw Drum11
DrumTempo:
	sub $BC
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
	cp $AD
	jr c, L4BE7
	cp $BD
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

; Song 2: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong2:
	call StopAll
	ld a, $6E
	ld [wInstrTableHi], a
	ld a, $B4
	ld [wInstrTable], a
	ld de, Song2_Ch1
	call StartMusicCh1
	ld de, Song2_Ch2
	call StartMusicCh2
	ld de, Song2_Ch3
	jp StartMusicCh3
Song2_Ch3:
	dw Pat_6B8B
	dw Pat_506D
	dw Pat_4D2B
	dw Pat_4D71
	dw Pat_4DA1
	dw Pat_4DD1
	dw Pat_4E2C
	dw Pat_4E73
	dw Pat_4EC6
	dw Pat_4F06
	dw Pat_4F5B
	dw Pat_4FB5
	dw Pat_4F5B
	dw Pat_5011
	dw Pat_4D2B
	dw Pat_50A4
	dw Pat_506D
	dw Pat_6B85
	dw Pat_506D
	dw Pat_4D2B
	dw Pat_4D71
	dw Pat_4DA1
	dw Pat_4DD1
	dw Pat_4E2C
	dw Pat_4E73
	dw Pat_4EC6
	dw Pat_4F06
	dw Pat_4F5B
	dw Pat_4FB5
	dw Pat_4F5B
	dw Pat_5011
	dw Pat_4D2B
	dw Pat_50A4
	dw Pat_506D
	ORDER_LOOP Song2_Ch3
Song2_Ch2:
	dw Pat_52FB
	dw Pat_530F
	dw Pat_50CE
	dw Pat_50E1
	dw Pat_511E
	dw Pat_5159
	dw Pat_518E
	dw Pat_51C5
	dw Pat_5205
	dw Pat_5237
	dw Pat_525D
	dw Pat_5292
	dw Pat_525D
	dw Pat_52C6
	dw Pat_50CE
	dw Pat_5321
	dw Pat_52FB
	dw Pat_530F
	ORDER_LOOP Song2_Ch2
Song2_Ch1:
	dw Pat_5575
	dw Pat_5580
	dw Pat_535C
	dw Pat_538E
	dw Pat_53C1
	dw Pat_53F6
	dw Pat_5428
	dw Pat_545A
	dw Pat_5490
	dw Pat_54C2
	dw Pat_54F4
	dw Pat_551A
	dw Pat_54F4
	dw Pat_5548
	dw Pat_535C
	dw Pat_5589
	dw Pat_5575
	dw Pat_5580
	ORDER_LOOP Song2_Ch1
Pat_4D2B:
	INSTR 11
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	INSTR 4
	LEN 18
	NOTE G_, 3
	INSTR 11
	LEN 9
	NOTE G_, 2
	REPEAT 2
	LEN 18
	NOTE D_, 2
	INSTR 12
	LEN 9
	NOTE D_, 3
	INSTR 4
	LEN 18
	NOTE G_, 3
	INSTR 11
	LEN 9
	NOTE D_, 2
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	INSTR 4
	LEN 18
	NOTE G_, 3
	INSTR 11
	LEN 9
	NOTE G_, 2
	REPEAT_END
	LEN 18
	NOTE D_, 2
	INSTR 12
	LEN 9
	NOTE D_, 3
	INSTR 4
	LEN 18
	NOTE G_, 3
	INSTR 11
	LEN 9
	NOTE D_, 2
	LEN 18
	NOTE A_, 2
	INSTR 12
	LEN 9
	NOTE A_, 3
	INSTR 4
	LEN 18
	NOTE D_, 4
	INSTR 11
	LEN 9
	NOTE A_, 2
	LEN 18
	NOTE D_, 2
	INSTR 12
	LEN 9
	NOTE D_, 3
	INSTR 4
	LEN 18
	NOTE D_, 4
	INSTR 11
	LEN 9
	NOTE D_, 2
	NEXT
Pat_4D71:
	INSTR 11
	REPEAT 3
	LEN 18
	NOTE A_, 2
	INSTR 12
	LEN 9
	NOTE A_, 3
	INSTR 4
	LEN 18
	NOTE D_, 4
	INSTR 11
	LEN 9
	NOTE A_, 2
	LEN 18
	NOTE D_, 2
	INSTR 12
	LEN 9
	NOTE D_, 3
	INSTR 4
	LEN 18
	NOTE D_, 4
	INSTR 11
	LEN 9
	NOTE D_, 2
	REPEAT_END
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	INSTR 4
	LEN 18
	NOTE G_, 3
	INSTR 11
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE C_, 2
	INSTR 4
	LEN 9
	NOTE D_, 3
	INSTR 11
	LEN 18
	NOTE D_, 2
	INSTR 4
	LEN 9
	NOTE D_, 3
	NEXT
Pat_4DA1:
	INSTR 11
	REPEAT 3
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	INSTR 4
	LEN 18
	NOTE G_, 3
	INSTR 11
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE D_, 2
	INSTR 12
	LEN 9
	NOTE D_, 3
	INSTR 4
	LEN 18
	NOTE G_, 3
	INSTR 11
	LEN 9
	NOTE D_, 2
	REPEAT_END
	LEN 18
	NOTE C_, 3
	INSTR 12
	LEN 9
	NOTE C_, 4
	INSTR 4
	LEN 18
	NOTE C_, 4
	INSTR 11
	LEN 9
	NOTE C_, 3
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE C_, 4
	INSTR 4
	LEN 18
	NOTE C_, 4
	INSTR 11
	LEN 9
	NOTE G_, 2
	NEXT
Pat_4DD1:
	INSTR 11
	LEN 18
	NOTE C_, 3
	INSTR 12
	LEN 9
	NOTE C_, 4
	INSTR 4
	LEN 18
	NOTE C_, 4
	INSTR 11
	LEN 9
	NOTE C_, 3
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	INSTR 4
	LEN 18
	NOTE C_, 4
	INSTR 11
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	INSTR 4
	LEN 18
	NOTE G_, 3
	INSTR 11
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE E_, 2
	INSTR 12
	LEN 9
	NOTE E_, 3
	INSTR 4
	LEN 18
	NOTE E_, 4
	INSTR 11
	LEN 9
	NOTE E_, 2
	LEN 18
	NOTE A_, 2
	INSTR 12
	LEN 9
	NOTE A_, 3
	INSTR 5
	LEN 18
	NOTE A_, 4
	INSTR 11
	LEN 9
	NOTE A_, 2
	LEN 18
	NOTE D_, 2
	INSTR 12
	LEN 9
	NOTE D_, 3
	INSTR 4
	LEN 18
	NOTE D_, 5
	INSTR 11
	LEN 9
	NOTE D_, 2
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	INSTR 11
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	INSTR 11
	LEN 18
	NOTE A_, 2
	INSTR 12
	LEN 9
	NOTE A_, 3
	INSTR 11
	LEN 18
	NOTE B_, 2
	INSTR 12
	LEN 9
	NOTE B_, 3
	NEXT
Pat_4E2C:
	INSTR 11
	REPEAT 2
	LEN 18
	NOTE C_, 3
	INSTR 12
	LEN 9
	NOTE C_, 4
	INSTR 4
	LEN 18
	NOTE C_, 5
	INSTR 11
	LEN 9
	NOTE C_, 3
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	INSTR 4
	LEN 18
	NOTE C_, 5
	INSTR 11
	LEN 9
	NOTE G_, 2
	REPEAT_END
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	INSTR 4
	LEN 18
	NOTE G_, 4
	INSTR 11
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE D_, 2
	INSTR 12
	LEN 9
	NOTE D_, 3
	INSTR 4
	LEN 18
	NOTE G_, 4
	INSTR 11
	LEN 9
	NOTE D_, 2
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	INSTR 11
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	INSTR 11
	LEN 18
	NOTE Fsh, 2
	INSTR 12
	LEN 9
	NOTE Fsh, 3
	INSTR 11
	LEN 18
	NOTE E_, 2
	INSTR 12
	LEN 9
	NOTE E_, 3
	NEXT
Pat_4E73:
	INSTR 11
	LEN 18
	NOTE D_, 2
	INSTR 12
	LEN 9
	NOTE D_, 3
	INSTR 4
	LEN 18
	NOTE D_, 4
	INSTR 11
	LEN 9
	NOTE D_, 2
	LEN 18
	NOTE A_, 2
	INSTR 12
	LEN 9
	NOTE A_, 3
	INSTR 4
	LEN 18
	NOTE D_, 4
	INSTR 11
	LEN 9
	NOTE A_, 2
	LEN 18
	NOTE D_, 2
	INSTR 12
	LEN 9
	NOTE D_, 3
	INSTR 4
	LEN 18
	NOTE D_, 4
	INSTR 11
	NOTE D_, 3
	INSTR 12
	LEN 9
	NOTE D_, 4
	INSTR 11
	NOTE A_, 2
	LEN 18
	NOTE Fsh, 2
	LEN 9
	NOTE D_, 2
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	INSTR 4
	LEN 18
	NOTE G_, 4
	INSTR 11
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE A_, 2
	INSTR 12
	LEN 9
	NOTE A_, 3
	INSTR 4
	LEN 18
	NOTE G_, 4
	INSTR 11
	LEN 9
	NOTE A_, 2
	LEN 18
	NOTE Ash, 2
	INSTR 12
	LEN 9
	NOTE Ash, 3
	INSTR 11
	LEN 18
	NOTE Ash, 2
	LEN 9
	NOTE B_, 2
	LEN 18
	WAIT2
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE A_, 2
	LEN 9
	NOTE B_, 2
	NEXT
Pat_4EC6:
	INSTR 11
	REPEAT 2
	LEN 18
	NOTE C_, 3
	INSTR 12
	LEN 9
	NOTE C_, 4
	INSTR 4
	LEN 18
	NOTE C_, 5
	INSTR 11
	LEN 9
	NOTE C_, 3
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	INSTR 4
	LEN 18
	NOTE C_, 5
	INSTR 11
	LEN 9
	NOTE G_, 2
	REPEAT_END
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	INSTR 4
	LEN 18
	NOTE G_, 4
	INSTR 11
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE F_, 2
	INSTR 12
	LEN 9
	NOTE F_, 3
	INSTR 4
	LEN 18
	NOTE F_, 4
	INSTR 11
	LEN 9
	NOTE F_, 2
	LEN 18
	NOTE E_, 2
	INSTR 12
	LEN 9
	NOTE E_, 3
	INSTR 11
	LEN 18
	NOTE E_, 2
	LEN 27
	NOTE B_, 2
	LEN 9
	NOTE Gsh, 2
	LEN 18
	NOTE Dsh, 2
	LEN 9
	NOTE E_, 2
	NEXT
Pat_4F06:
	INSTR 11
	LEN 18
	NOTE A_, 2
	INSTR 5
	LEN 9
	NOTE A_, 4
	INSTR 11
	LEN 18
	NOTE B_, 2
	INSTR 5
	LEN 9
	NOTE A_, 4
	INSTR 11
	LEN 18
	NOTE C_, 3
	INSTR 5
	LEN 9
	NOTE A_, 4
	INSTR 11
	LEN 18
	NOTE Csh, 3
	INSTR 5
	LEN 9
	NOTE A_, 4
	INSTR 11
	LEN 18
	NOTE D_, 3
	INSTR 12
	LEN 9
	NOTE D_, 4
	INSTR 11
	LEN 18
	NOTE D_, 3
	LEN 27
	NOTE D_, 2
	LEN 9
	NOTE E_, 2
	LEN 27
	NOTE Fsh, 2
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	INSTR 4
	LEN 18
	NOTE G_, 4
	INSTR 11
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE D_, 2
	INSTR 12
	LEN 9
	NOTE D_, 3
	INSTR 4
	LEN 18
	NOTE G_, 4
	INSTR 11
	LEN 9
	NOTE D_, 2
	LEN 18
	NOTE D_, 3
	INSTR 12
	LEN 9
	NOTE D_, 4
	INSTR 11
	LEN 18
	NOTE C_, 3
	INSTR 12
	LEN 9
	NOTE C_, 4
	INSTR 11
	LEN 18
	NOTE B_, 2
	INSTR 12
	LEN 9
	NOTE B_, 3
	INSTR 11
	LEN 18
	NOTE A_, 2
	INSTR 12
	LEN 9
	NOTE A_, 3
	NEXT
Pat_4F5B:
	INSTR 11
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	INSTR 4
	LEN 18
	NOTE G_, 4
	INSTR 11
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE D_, 2
	INSTR 12
	LEN 9
	NOTE D_, 3
	INSTR 4
	LEN 18
	NOTE G_, 4
	INSTR 11
	LEN 9
	NOTE D_, 2
	LEN 18
	NOTE E_, 2
	INSTR 12
	LEN 9
	NOTE E_, 3
	INSTR 4
	LEN 18
	NOTE E_, 4
	INSTR 11
	LEN 9
	NOTE E_, 2
	LEN 18
	NOTE B_, 2
	INSTR 12
	LEN 9
	NOTE B_, 3
	INSTR 4
	LEN 18
	NOTE E_, 4
	INSTR 11
	LEN 9
	NOTE B_, 2
	LEN 18
	NOTE A_, 2
	INSTR 12
	LEN 9
	NOTE A_, 3
	INSTR 5
	LEN 18
	NOTE A_, 4
	INSTR 11
	LEN 9
	NOTE A_, 2
	LEN 18
	NOTE E_, 2
	INSTR 12
	LEN 9
	NOTE E_, 3
	INSTR 5
	LEN 18
	NOTE A_, 4
	INSTR 11
	LEN 9
	NOTE E_, 2
	LEN 18
	NOTE D_, 2
	INSTR 12
	LEN 9
	NOTE D_, 3
	INSTR 4
	LEN 18
	NOTE D_, 4
	INSTR 11
	LEN 9
	NOTE D_, 2
	LEN 18
	NOTE D_, 3
	INSTR 12
	LEN 9
	NOTE D_, 4
	INSTR 4
	LEN 18
	NOTE D_, 4
	INSTR 11
	LEN 9
	NOTE D_, 3
	NEXT
Pat_4FB5:
	INSTR 11
	LEN 18
	NOTE B_, 2
	INSTR 12
	LEN 9
	NOTE B_, 3
	INSTR 5
	LEN 18
	NOTE B_, 4
	INSTR 11
	LEN 9
	NOTE B_, 2
	LEN 18
	NOTE Fsh, 2
	INSTR 12
	LEN 9
	NOTE Fsh, 3
	INSTR 5
	LEN 18
	NOTE B_, 4
	INSTR 11
	LEN 9
	NOTE Fsh, 2
	LEN 18
	NOTE E_, 2
	INSTR 12
	LEN 9
	NOTE E_, 3
	INSTR 5
	LEN 18
	NOTE E_, 4
	INSTR 11
	LEN 9
	NOTE E_, 2
	LEN 18
	NOTE B_, 2
	INSTR 12
	LEN 9
	NOTE B_, 3
	INSTR 11
	LEN 18
	NOTE Ash, 2
	INSTR 12
	LEN 9
	NOTE Ash, 3
	INSTR 11
	LEN 18
	NOTE A_, 2
	INSTR 12
	LEN 9
	NOTE A_, 3
	INSTR 5
	LEN 18
	NOTE A_, 4
	INSTR 11
	LEN 9
	NOTE A_, 2
	LEN 18
	NOTE E_, 2
	INSTR 12
	LEN 9
	NOTE E_, 3
	INSTR 5
	LEN 18
	NOTE A_, 4
	INSTR 11
	LEN 9
	NOTE E_, 2
	LEN 18
	NOTE D_, 2
	INSTR 12
	LEN 9
	NOTE D_, 3
	INSTR 11
	LEN 18
	NOTE E_, 2
	INSTR 12
	LEN 9
	NOTE E_, 3
	INSTR 11
	LEN 18
	NOTE F_, 2
	INSTR 12
	LEN 9
	NOTE F_, 3
	INSTR 11
	LEN 18
	NOTE Fsh, 2
	INSTR 12
	LEN 9
	NOTE Fsh, 3
	NEXT
Pat_5011:
	INSTR 11
	LEN 18
	NOTE B_, 2
	INSTR 12
	LEN 9
	NOTE B_, 3
	INSTR 5
	LEN 18
	NOTE B_, 4
	INSTR 11
	LEN 9
	NOTE B_, 2
	LEN 18
	NOTE Fsh, 2
	INSTR 12
	LEN 9
	NOTE Fsh, 3
	INSTR 5
	LEN 18
	NOTE B_, 4
	INSTR 11
	LEN 9
	NOTE Fsh, 2
	LEN 18
	NOTE E_, 2
	INSTR 12
	LEN 9
	NOTE E_, 3
	INSTR 5
	LEN 18
	NOTE E_, 4
	INSTR 11
	LEN 9
	NOTE E_, 2
	LEN 18
	NOTE B_, 2
	INSTR 12
	LEN 9
	NOTE B_, 3
	INSTR 11
	LEN 18
	NOTE Ash, 2
	INSTR 12
	LEN 9
	NOTE Ash, 3
	INSTR 11
	LEN 18
	NOTE A_, 2
	INSTR 12
	LEN 9
	NOTE A_, 3
	INSTR 5
	LEN 18
	NOTE A_, 4
	INSTR 11
	LEN 9
	NOTE A_, 2
	LEN 18
	NOTE E_, 2
	INSTR 12
	LEN 9
	NOTE E_, 3
	INSTR 5
	LEN 18
	NOTE A_, 4
	INSTR 11
	LEN 9
	NOTE E_, 2
	LEN 18
	NOTE D_, 2
	INSTR 12
	LEN 9
	NOTE D_, 3
	INSTR 11
	LEN 18
	NOTE E_, 2
	INSTR 12
	LEN 9
	NOTE E_, 3
	INSTR 11
	LEN 18
	NOTE F_, 2
	INSTR 12
	LEN 9
	NOTE F_, 3
	INSTR 11
	LEN 18
	NOTE Fsh, 2
	INSTR 12
	LEN 9
	NOTE Fsh, 3
	NEXT
Pat_506D:
	DRUMS $09, DrumPat_55BA
	VIBRATO $09, $04, $04
	CH_TRANSPOSE $0C
	INSTR 11
	REPEAT 3
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	INSTR 4
	LEN 18
	NOTE G_, 3
	INSTR 11
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE D_, 2
	INSTR 12
	LEN 9
	NOTE D_, 3
	INSTR 4
	LEN 18
	NOTE G_, 3
	INSTR 11
	LEN 9
	NOTE D_, 2
	REPEAT_END
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	INSTR 4
	LEN 18
	NOTE G_, 3
	INSTR 11
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE D_, 2
	LEN 9
	NOTE D_, 2
	LEN 18
	NOTE E_, 2
	LEN 9
	NOTE Fsh, 2
	NEXT
Pat_50A4:
	INSTR 11
	REPEAT 3
	LEN 18
	NOTE A_, 2
	INSTR 12
	LEN 9
	NOTE A_, 3
	INSTR 4
	LEN 18
	NOTE D_, 4
	INSTR 11
	LEN 9
	NOTE A_, 2
	LEN 18
	NOTE D_, 2
	INSTR 12
	LEN 9
	NOTE D_, 3
	INSTR 4
	LEN 18
	NOTE D_, 4
	INSTR 11
	LEN 9
	NOTE D_, 2
	REPEAT_END
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	INSTR 11
	LEN 18
	NOTE B_, 2
	LEN 27
	NOTE G_, 2
	LEN 9
	NOTE D_, 2
	LEN 18
	NOTE E_, 2
	LEN 9
	NOTE Fsh, 2
	NEXT
Pat_50CE:
	LENGTH $87
	REST
	INSTR 13
	LEN 9
	NOTE G_, 5
	WAIT2
	NOTE G_, 5
	LENGTH $BD
	WAIT2
	LEN 9
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE Fsh, 5
	LEN 45
	WAIT2
	NEXT
Pat_50E1:
	INSTR 13
	LEN 9
	NOTE B_, 3
	LEN 18
	WAIT2
	LEN 9
	NOTE D_, 3
	LEN 18
	WAIT2
	LEN 9
	NOTE A_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE D_, 6
	LEN 18
	WAIT2
	LEN 9
	NOTE B_, 3
	WAIT2
	NOTE A_, 3
	NOTE D_, 3
	LEN 18
	WAIT2
	LEN 9
	NOTE A_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE D_, 6
	LEN 18
	WAIT2
	LEN 9
	NOTE B_, 3
	LEN 18
	WAIT2
	LEN 9
	NOTE D_, 3
	LEN 18
	WAIT2
	LEN 9
	NOTE A_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE D_, 6
	WAIT2
	NOTE E_, 6
	LEN 18
	NOTE D_, 6
	LEN 9
	WAIT2
	LEN 18
	NOTE B_, 5
	LEN 9
	WAIT2
	LEN 18
	NOTE G_, 5
	LEN 9
	WAIT2
	NOTE Fsh, 5
	WAIT2
	NOTE D_, 5
	NEXT
Pat_511E:
	INSTR 13
	LEN 18
	NOTE E_, 5
	LEN 9
	NOTE D_, 5
	LEN 18
	NOTE Csh, 5
	LEN 9
	NOTE D_, 5
	LEN 18
	NOTE B_, 4
	LEN 9
	NOTE D_, 5
	LEN 18
	NOTE E_, 5
	LEN 9
	NOTE D_, 5
	LEN 18
	NOTE G_, 5
	LEN 9
	WAIT2
	NOTE D_, 6
	WAIT2
	NOTE B_, 5
	LEN 45
	WAIT2
	LEN 9
	NOTE A_, 5
	LEN 18
	NOTE G_, 5
	LEN 9
	NOTE D_, 5
	LEN 18
	NOTE G_, 5
	LEN 9
	NOTE B_, 5
	LEN 18
	NOTE D_, 6
	LEN 9
	NOTE B_, 5
	LEN 18
	NOTE A_, 5
	LEN 9
	NOTE G_, 5
	LEN 18
	NOTE C_, 6
	LEN 9
	WAIT2
	LEN 18
	NOTE E_, 6
	LEN 9
	WAIT2
	LEN 27
	NOTE G_, 6
	LEN 18
	WAIT2
	LEN 9
	NOTE E_, 6
	NEXT
Pat_5159:
	INSTR 13
	LEN 9
	NOTE G_, 6
	NOTE Fsh, 6
	NOTE G_, 6
	NOTE Fsh, 6
	WAIT2
	NOTE G_, 6
	NOTE Fsh, 6
	WAIT2
	LEN 27
	NOTE E_, 6
	LEN 9
	NOTE Dsh, 6
	NOTE D_, 6
	NOTE E_, 6
	NOTE D_, 6
	NOTE C_, 6
	WAIT2
	NOTE B_, 5
	NOTE A_, 5
	WAIT2
	LEN 27
	NOTE Gsh, 5
	LEN 9
	NOTE E_, 5
	NOTE C_, 6
	NOTE D_, 6
	NOTE C_, 6
	LEN 18
	NOTE B_, 5
	LEN 9
	NOTE A_, 5
	NOTE D_, 6
	WAIT2
	NOTE D_, 5
	NOTE E_, 5
	WAIT2
	LEN 36
	NOTE G_, 5
	LEN 18
	NOTE B_, 3
	LEN 9
	WAIT2
	LEN 18
	NOTE C_, 4
	LEN 9
	WAIT2
	LEN 18
	NOTE D_, 4
	LEN 9
	WAIT2
	NEXT
Pat_518E:
	INSTR 13
	LEN 18
	NOTE C_, 4
	LEN 9
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE B_, 3
	LEN 18
	NOTE C_, 4
	LEN 9
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE B_, 3
	LEN 18
	NOTE C_, 4
	LEN 9
	WAIT2
	INSTR 6
	LEN 18
	NOTE E_, 5
	LEN 27
	NOTE C_, 5
	INSTR 13
	LEN 9
	NOTE C_, 4
	LEN 18
	NOTE B_, 3
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE B_, 3
	LEN 9
	WAIT2
	INSTR 6
	LEN 18
	NOTE D_, 5
	LEN 36
	NOTE B_, 4
	LEN 18
	NOTE G_, 5
	LEN 36
	NOTE D_, 5
	LEN 18
	NOTE B_, 5
	LEN 27
	NOTE G_, 5
	LEN 9
	NOTE Fsh, 5
	LEN 18
	NOTE E_, 5
	LEN 9
	NOTE F_, 5
	NEXT
Pat_51C5:
	INSTR 6
	LEN 18
	NOTE Fsh, 5
	LEN 9
	NOTE A_, 5
	LEN 18
	NOTE Fsh, 5
	LEN 9
	NOTE F_, 5
	LEN 18
	NOTE E_, 5
	LEN 9
	NOTE G_, 5
	LEN 18
	NOTE E_, 5
	LEN 9
	NOTE Dsh, 5
	LEN 18
	NOTE D_, 5
	LEN 9
	NOTE Fsh, 5
	NOTE D_, 5
	NOTE Csh, 5
	LEN 27
	NOTE C_, 5
	LEN 9
	NOTE D_, 4
	LEN 18
	NOTE A_, 4
	LEN 9
	NOTE Ash, 4
	LEN 18
	NOTE B_, 4
	LEN 9
	NOTE G_, 4
	LEN 18
	NOTE B_, 4
	LEN 9
	NOTE G_, 4
	LEN 18
	NOTE C_, 5
	LEN 9
	NOTE G_, 4
	LEN 18
	NOTE C_, 5
	LEN 9
	NOTE G_, 4
	LEN 18
	NOTE Csh, 5
	LEN 9
	NOTE G_, 4
	LEN 18
	NOTE Csh, 5
	LEN 9
	NOTE D_, 5
	LEN 18
	WAIT2
	INSTR 13
	LEN 9
	NOTE G_, 4
	NOTE A_, 4
	WAIT2
	NOTE B_, 4
	NEXT
Pat_5205:
	INSTR 13
	LEN 18
	NOTE C_, 5
	LEN 9
	WAIT2
	LEN 18
	NOTE B_, 4
	LEN 9
	NOTE C_, 5
	LEN 18
	NOTE E_, 5
	LEN 9
	WAIT2
	LEN 18
	NOTE C_, 5
	LEN 9
	NOTE E_, 5
	NOTE G_, 5
	WAIT2
	NOTE E_, 5
	NOTE G_, 5
	WAIT2
	LEN 18
	NOTE C_, 6
	LEN 9
	WAIT2
	NOTE C_, 6
	NOTE B_, 5
	WAIT2
	NOTE A_, 5
	LENGTH $36
	NOTE G_, 5
	NOTE F_, 5
	LEN 18
	NOTE E_, 5
	LEN 9
	WAIT2
	NOTE E_, 5
	WAIT2
	LEN 18
	NOTE B_, 4
	LEN 9
	NOTE Dsh, 4
	NOTE E_, 4
	LEN 18
	NOTE F_, 4
	LEN 9
	NOTE E_, 4
	NEXT
Pat_5237:
	INSTR 6
	LEN 27
	NOTE C_, 5
	NOTE D_, 5
	LEN 18
	NOTE E_, 5
	LEN 9
	NOTE D_, 5
	LEN 18
	NOTE C_, 5
	LEN 9
	NOTE B_, 4
	LEN 27
	NOTE B_, 4
	NOTE A_, 4
	LEN 18
	NOTE G_, 4
	LEN 27
	NOTE A_, 4
	LEN 36
	NOTE B_, 4
	LEN 27
	NOTE G_, 4
	LEN 9
	NOTE D_, 4
	INSTR 13
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE Csh, 5
	INSTR 6
	LEN 27
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	NEXT
Pat_525D:
	INSTR 6
	LEN 18
	NOTE G_, 3
	INSTR 9
	LEN 9
	NOTE B_, 3
	NOTE D_, 4
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE G_, 4
	INSTR 6
	NOTE A_, 3
	LEN 18
	NOTE B_, 3
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE Gsh, 3
	LENGTH $3F
	NOTE B_, 3
	LEN 18
	NOTE A_, 3
	INSTR 9
	LEN 9
	NOTE E_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE C_, 5
	INSTR 6
	NOTE B_, 3
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE B_, 3
	LEN 18
	NOTE A_, 3
	LEN 36
	NOTE C_, 4
	LEN 9
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NEXT
Pat_5292:
	INSTR 6
	LEN 18
	NOTE D_, 4
	INSTR 9
	LEN 9
	NOTE Fsh, 4
	NOTE B_, 4
	NOTE Fsh, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE B_, 4
	NOTE D_, 5
	NOTE Fsh, 5
	NOTE D_, 5
	INSTR 6
	NOTE Dsh, 4
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE Fsh, 4
	LEN 18
	NOTE G_, 4
	LEN 27
	NOTE E_, 4
	LEN 9
	NOTE B_, 3
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE B_, 3
	LEN 27
	NOTE A_, 3
	NOTE C_, 4
	NOTE E_, 4
	LEN 18
	NOTE A_, 4
	LEN 9
	NOTE G_, 4
	LEN 18
	NOTE Fsh, 4
	LEN 9
	NOTE G_, 4
	LEN 18
	NOTE A_, 4
	NOTE D_, 4
	LEN 9
	NOTE Fsh, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NEXT
Pat_52C6:
	INSTR 6
	LEN 18
	NOTE D_, 4
	INSTR 9
	LEN 9
	NOTE Fsh, 4
	NOTE B_, 4
	NOTE Fsh, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE B_, 4
	NOTE D_, 5
	NOTE Fsh, 5
	NOTE D_, 5
	INSTR 6
	NOTE Dsh, 4
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE Fsh, 4
	LEN 18
	NOTE G_, 4
	LEN 27
	NOTE E_, 4
	LEN 9
	NOTE B_, 3
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE D_, 4
	LEN 27
	NOTE A_, 3
	NOTE C_, 4
	NOTE E_, 4
	LEN 18
	NOTE A_, 4
	LEN 9
	NOTE G_, 4
	LEN 18
	NOTE Fsh, 4
	LEN 9
	NOTE G_, 4
	LEN 18
	NOTE A_, 4
	LEN 27
	NOTE D_, 4
	LEN 9
	NOTE D_, 4
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE Fsh, 4
	NEXT
Pat_52FB:
	INSTR 9
	LEN 27
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	LEN 18
	NOTE G_, 4
	LEN 36
	NOTE D_, 4
	LEN 27
	NOTE G_, 4
	LEN 18
	NOTE B_, 4
	LEN 9
	NOTE B_, 4
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE D_, 4
	NEXT
Pat_530F:
	INSTR 9
	LEN 27
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	LEN 18
	NOTE G_, 4
	LEN 36
	NOTE D_, 4
	LEN 27
	NOTE G_, 4
	LEN 18
	NOTE B_, 4
	LEN 9
	NOTE B_, 4
	LEN 27
	NOTE G_, 4
	NEXT
Pat_5321:
	INSTR 13
	LEN 9
	NOTE B_, 3
	LEN 18
	WAIT2
	LEN 9
	NOTE D_, 3
	LEN 18
	WAIT2
	LEN 9
	NOTE A_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE D_, 6
	LEN 18
	WAIT2
	LEN 9
	NOTE B_, 3
	WAIT2
	NOTE A_, 3
	NOTE D_, 3
	LEN 18
	WAIT2
	LEN 9
	NOTE A_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE D_, 6
	LEN 18
	WAIT2
	LEN 9
	NOTE B_, 3
	LEN 18
	WAIT2
	LEN 9
	NOTE D_, 3
	LEN 18
	WAIT2
	LEN 9
	NOTE A_, 5
	NOTE B_, 5
	NOTE C_, 6
	NOTE D_, 6
	LEN 18
	WAIT2
	HWENV $C2, $00
	ARP 4
	RELEASE $00
	LEN 27
	NOTE G_, 3
	LEN 18
	NOTE G_, 3
	LENGTH $3F
	NOTE G_, 3
	NEXT
Pat_535C:
	INSTR 6
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE D_, 4
	LEN 18
	NOTE Csh, 4
	LEN 9
	NOTE D_, 4
	LEN 18
	NOTE B_, 3
	LEN 9
	NOTE D_, 4
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE D_, 4
	LEN 27
	NOTE G_, 4
	LEN 18
	NOTE G_, 4
	LENGTH $36
	NOTE G_, 4
	LEN 9
	NOTE A_, 4
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE D_, 4
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE B_, 4
	LEN 18
	NOTE D_, 5
	LEN 9
	NOTE B_, 4
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE B_, 4
	LEN 27
	NOTE A_, 4
	NOTE Fsh, 4
	LEN 45
	NOTE D_, 4
	LEN 9
	NOTE A_, 4
	NEXT
Pat_538E:
	INSTR 6
	LEN 18
	NOTE B_, 4
	LEN 9
	NOTE A_, 4
	LEN 18
	NOTE Gsh, 4
	LEN 9
	NOTE A_, 4
	LEN 45
	NOTE Fsh, 4
	LEN 9
	NOTE A_, 4
	LEN 18
	NOTE B_, 4
	LEN 9
	NOTE A_, 4
	LEN 18
	NOTE Gsh, 4
	LEN 9
	NOTE A_, 4
	LEN 45
	NOTE Fsh, 4
	LEN 9
	NOTE A_, 4
	LEN 18
	NOTE D_, 5
	LEN 9
	NOTE A_, 4
	LEN 18
	NOTE B_, 4
	LEN 9
	NOTE A_, 4
	LEN 18
	NOTE D_, 5
	LEN 9
	NOTE A_, 4
	LEN 18
	NOTE B_, 4
	LEN 9
	NOTE C_, 5
	LEN 27
	NOTE B_, 4
	NOTE G_, 4
	NOTE E_, 4
	LEN 18
	NOTE D_, 4
	INSTR 13
	LEN 9
	NOTE B_, 4
	NEXT
Pat_53C1:
	INSTR 13
	LEN 18
	NOTE C_, 5
	LEN 9
	NOTE B_, 4
	LEN 18
	NOTE Ash, 4
	LEN 9
	NOTE B_, 4
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE B_, 4
	LEN 18
	NOTE C_, 5
	LEN 9
	NOTE B_, 4
	LEN 18
	NOTE D_, 5
	LEN 9
	WAIT2
	NOTE B_, 5
	WAIT2
	NOTE G_, 5
	LEN 45
	WAIT2
	LEN 9
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE E_, 5
	NEXT
Pat_53F6:
	INSTR 13
	LEN 9
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE Fsh, 5
	WAIT2
	NOTE G_, 5
	NOTE Fsh, 5
	WAIT2
	LEN 27
	NOTE E_, 5
	LEN 9
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE C_, 5
	WAIT2
	NOTE B_, 4
	NOTE A_, 4
	WAIT2
	LEN 27
	NOTE E_, 5
	LEN 9
	NOTE E_, 4
	LEN 27
	NOTE G_, 4
	NOTE E_, 4
	LEN 18
	NOTE Fsh, 4
	LEN 9
	NOTE E_, 4
	LEN 18
	NOTE D_, 4
	LEN 36
	NOTE G_, 4
	LEN 18
	NOTE G_, 3
	LEN 9
	WAIT2
	LEN 18
	NOTE A_, 3
	LEN 9
	WAIT2
	LEN 18
	NOTE B_, 3
	LEN 9
	WAIT2
	NEXT
Pat_5428:
	INSTR 13
	LEN 18
	NOTE E_, 4
	LEN 9
	WAIT2
	NOTE E_, 4
	WAIT2
	NOTE Dsh, 4
	LEN 18
	NOTE E_, 4
	LEN 9
	WAIT2
	NOTE E_, 4
	WAIT2
	NOTE Dsh, 4
	LEN 18
	NOTE E_, 4
	LEN 9
	WAIT2
	INSTR 6
	LEN 18
	NOTE G_, 5
	LEN 27
	NOTE E_, 5
	INSTR 13
	LEN 9
	NOTE E_, 4
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE Csh, 4
	LEN 18
	NOTE D_, 4
	LEN 9
	WAIT2
	INSTR 6
	LEN 18
	NOTE G_, 5
	LEN 36
	NOTE D_, 5
	LEN 18
	NOTE B_, 5
	LEN 36
	NOTE G_, 5
	LEN 18
	NOTE D_, 6
	LENGTH $3F
	NOTE B_, 5
	NEXT
Pat_545A:
	INSTR 13
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE B_, 3
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE B_, 3
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE B_, 3
	NOTE C_, 4
	WAIT2
	LEN 27
	NOTE A_, 3
	LEN 9
	NOTE D_, 3
	NOTE D_, 4
	NOTE Csh, 4
	LEN 27
	NOTE C_, 4
	LEN 9
	NOTE A_, 3
	NOTE D_, 3
	WAIT2
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE A_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE Ash, 4
	WAIT2
	NOTE B_, 4
	LEN 18
	WAIT2
	LEN 9
	NOTE B_, 4
	NOTE C_, 5
	WAIT2
	NOTE D_, 5
	NEXT
Pat_5490:
	INSTR 13
	LEN 18
	NOTE E_, 5
	LEN 9
	WAIT2
	LEN 18
	NOTE Dsh, 5
	LEN 9
	NOTE E_, 5
	LEN 18
	NOTE G_, 5
	LEN 9
	WAIT2
	LEN 18
	NOTE E_, 5
	LEN 9
	NOTE G_, 5
	NOTE C_, 6
	WAIT2
	NOTE G_, 5
	NOTE C_, 6
	WAIT2
	LEN 18
	NOTE E_, 6
	LEN 9
	WAIT2
	NOTE E_, 6
	NOTE D_, 6
	WAIT2
	NOTE C_, 6
	LENGTH $36
	NOTE B_, 5
	NOTE A_, 5
	LEN 18
	NOTE A_, 5
	LEN 9
	WAIT2
	NOTE A_, 5
	WAIT2
	LEN 18
	NOTE Gsh, 5
	LEN 9
	NOTE Dsh, 5
	NOTE E_, 5
	LEN 18
	NOTE F_, 5
	LEN 9
	NOTE E_, 5
	NEXT
Pat_54C2:
	INSTR 13
	LEN 9
	NOTE A_, 5
	WAIT2
	NOTE E_, 5
	NOTE B_, 5
	WAIT2
	NOTE E_, 5
	LEN 18
	NOTE C_, 6
	LEN 9
	NOTE B_, 5
	LEN 18
	NOTE A_, 5
	LEN 9
	NOTE G_, 5
	LEN 18
	NOTE G_, 5
	LEN 9
	WAIT2
	LEN 18
	NOTE Fsh, 5
	LEN 9
	WAIT2
	NOTE E_, 5
	WAIT2
	LEN 18
	NOTE Fsh, 5
	LEN 9
	WAIT2
	LENGTH $6C
	NOTE G_, 5
	LEN 9
	WAIT2
	LEN 18
	NOTE D_, 5
	LEN 9
	NOTE E_, 5
	LEN 18
	NOTE B_, 4
	LEN 27
	NOTE D_, 5
	LEN 9
	NOTE E_, 5
	LEN 18
	NOTE B_, 4
	LEN 9
	NOTE C_, 5
	NEXT
Pat_54F4:
	INSTR 13
	LENGTH $5A
	NOTE D_, 5
	LEN 9
	WAIT2
	NOTE Dsh, 5
	NOTE E_, 5
	WAIT2
	NOTE B_, 4
	NOTE Gsh, 4
	WAIT2
	LENGTH $36
	NOTE E_, 4
	LEN 9
	WAIT2
	LENGTH $5A
	NOTE E_, 5
	LEN 9
	WAIT2
	NOTE F_, 5
	NOTE Fsh, 5
	WAIT2
	NOTE D_, 5
	NOTE C_, 5
	WAIT2
	LEN 18
	NOTE A_, 4
	LEN 9
	WAIT2
	LEN 18
	NOTE Fsh, 4
	LEN 9
	WAIT2
	NOTE D_, 4
	NEXT
Pat_551A:
	INSTR 13
	LENGTH $5A
	NOTE Fsh, 5
	LEN 9
	WAIT2
	NOTE D_, 5
	NOTE G_, 5
	WAIT2
	NOTE Fsh, 5
	NOTE E_, 5
	WAIT2
	LEN 27
	NOTE G_, 5
	LEN 9
	NOTE E_, 5
	LEN 18
	NOTE Fsh, 5
	LEN 9
	NOTE G_, 5
	NOTE A_, 5
	WAIT2
	NOTE E_, 5
	LEN 18
	NOTE Fsh, 5
	LEN 9
	NOTE G_, 5
	NOTE A_, 5
	WAIT2
	NOTE E_, 5
	LEN 18
	NOTE Fsh, 5
	LEN 9
	NOTE G_, 5
	LEN 18
	NOTE B_, 5
	LEN 9
	WAIT2
	NOTE B_, 5
	WAIT2
	LENGTH $36
	NOTE A_, 5
	LEN 9
	WAIT2
	NEXT
Pat_5548:
	INSTR 13
	LENGTH $5A
	NOTE Fsh, 5
	LEN 9
	WAIT2
	NOTE D_, 5
	NOTE G_, 5
	WAIT2
	NOTE Fsh, 5
	NOTE E_, 5
	WAIT2
	LEN 27
	NOTE G_, 5
	LEN 9
	NOTE E_, 5
	LEN 18
	NOTE Fsh, 5
	LEN 9
	NOTE G_, 5
	NOTE A_, 5
	WAIT2
	NOTE E_, 5
	LEN 18
	NOTE Fsh, 5
	LEN 9
	NOTE G_, 5
	NOTE C_, 6
	WAIT2
	NOTE E_, 5
	LEN 18
	NOTE Fsh, 5
	LEN 9
	NOTE G_, 5
	LEN 18
	NOTE B_, 5
	LEN 9
	NOTE C_, 6
	NOTE D_, 6
	WAIT2
	LEN 36
	NOTE A_, 5
	LEN 27
	WAIT2
	NEXT
Pat_5575:
	ARP 4
	DUTY_12
	AUTODUTY $04
	HWENV $40, $00
	LENGTH $D8
	NOTE G_, 4
	NEXT
Pat_5580:
	LENGTH $CF
	NOTE G_, 3
	AUTODUTY $00
	INSTR 6
	LEN 9
	NOTE D_, 4
	NEXT
Pat_5589:
	INSTR 6
	LEN 18
	NOTE B_, 4
	LEN 9
	NOTE A_, 4
	LEN 18
	NOTE Gsh, 4
	LEN 9
	NOTE A_, 4
	LEN 45
	NOTE Fsh, 4
	LEN 9
	NOTE A_, 4
	LEN 18
	NOTE B_, 4
	LEN 9
	NOTE A_, 4
	LEN 18
	NOTE Gsh, 4
	LEN 9
	NOTE A_, 4
	LEN 45
	NOTE D_, 5
	LEN 9
	NOTE A_, 4
	LEN 18
	NOTE B_, 4
	LEN 9
	NOTE A_, 4
	LEN 18
	NOTE Gsh, 4
	LEN 9
	NOTE A_, 4
	LEN 18
	NOTE D_, 5
	LEN 9
	NOTE D_, 4
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE Fsh, 4
	LEN 27
	NOTE G_, 4
	LEN 18
	NOTE G_, 4
	LENGTH $3F
	NOTE G_, 4
	NEXT
DrumPat_55BA:
	db DRUM_LEVEL + 13, DRUM_REPEAT + 3, 5, 0, 6, 9, 0, 6
	db DRUM_REPEAT_END, 5, 0, 6, 9, 0, 4, DRUM_REPEAT + 3
	db 5, 0, 6, 9, 0, 6, DRUM_REPEAT_END, 5
	db 0, DRUM_TEMPO + 4, 10, DRUM_TEMPO + 5, 10, DRUM_TEMPO + 9, 9, 0
	db 9, DRUM_LOOP

; Song 3: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong3:
	call StopAll
	ld a, $6E
	ld [wInstrTableHi], a
	ld a, $B4
	ld [wInstrTable], a
	ld de, Song3_Ch3
	call StartMusicCh3
	ld de, Song3_Ch2
	call StartMusicCh2
	ld de, Song3_Ch1
	jp StartMusicCh1
Song3_Ch3:
	dw Pat_562B
	dw Pat_562B
	dw Pat_5666
	dw Pat_568F
	dw Pat_6B85
	dw Pat_562B
	dw Pat_562B
	dw Pat_5666
	dw Pat_568F
	dw Pat_6B8B
	ORDER_LOOP Song3_Ch3
Song3_Ch2:
	dw Pat_56C1
	dw Pat_56C1
	dw Pat_571B
	dw Pat_5752
	ORDER_LOOP Song3_Ch2
Song3_Ch1:
	dw Pat_5794
	dw Pat_5794
	dw Pat_57E3
	dw Pat_5817
	ORDER_LOOP Song3_Ch1
Pat_562B:
	CH_TRANSPOSE $0C
	LEN 12
	REPEAT 2
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
	NOTE G_, 2
	LEN 6
	NOTE Fsh, 2
	NOTE G_, 2
	LEN 12
	NOTE A_, 2
	LEN 6
	NOTE Gsh, 2
	NOTE A_, 2
	LEN 12
	NOTE Ash, 2
	LEN 6
	NOTE A_, 2
	NOTE Gsh, 2
	LEN 12
	NOTE G_, 2
	WAIT2
	REPEAT 2
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
	LEN 6
	NOTE Fsh, 2
	WAIT2
	NOTE G_, 2
	WAIT2
	NOTE Gsh, 2
	WAIT2
	NOTE A_, 2
	WAIT2
	LEN 18
	NOTE Ash, 2
	LEN 6
	WAIT2
	LEN 12
	NOTE B_, 2
	NOTE G_, 2
	NEXT
Pat_5666:
	LEN 12
	REPEAT 2
	INSTR 11
	NOTE C_, 2
	INSTR 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	REPEAT_END
	REPEAT 2
	INSTR 11
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	REPEAT_END
	REPEAT 2
	INSTR 11
	NOTE C_, 2
	INSTR 4
	NOTE C_, 5
	INSTR 11
	NOTE G_, 2
	INSTR 4
	NOTE C_, 5
	REPEAT_END
	INSTR 11
	NOTE G_, 2
	INSTR 4
	NOTE G_, 5
	INSTR 11
	NOTE D_, 2
	INSTR 4
	NOTE G_, 5
	INSTR 11
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NEXT
Pat_568F:
	REPEAT 2
	INSTR 11
	NOTE C_, 2
	INSTR 4
	NOTE C_, 5
	INSTR 11
	NOTE G_, 2
	INSTR 4
	NOTE C_, 5
	REPEAT_END
	REPEAT 2
	INSTR 11
	NOTE F_, 2
	INSTR 4
	NOTE F_, 5
	INSTR 11
	NOTE C_, 3
	INSTR 4
	NOTE F_, 5
	REPEAT_END
	INSTR 11
	NOTE G_, 2
	INSTR 4
	NOTE G_, 5
	INSTR 11
	NOTE F_, 2
	INSTR 4
	NOTE F_, 5
	INSTR 11
	NOTE E_, 2
	INSTR 5
	NOTE E_, 5
	INSTR 11
	NOTE D_, 2
	INSTR 5
	NOTE D_, 5
	INSTR 11
	NOTE C_, 2
	INSTR 4
	NOTE C_, 5
	INSTR 11
	NOTE G_, 2
	NOTE B_, 2
	NOTE C_, 3
	LEN 6
	NOTE C_, 3
	NOTE C_, 3
	LEN 24
	NOTE G_, 2
	NEXT
Pat_56C1:
	INSTR 9
	LEN 6
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	INSTR 6
	LEN 12
	NOTE G_, 3
	LEN 6
	NOTE Fsh, 3
	NOTE G_, 3
	LEN 12
	NOTE A_, 3
	LEN 6
	NOTE Gsh, 3
	NOTE A_, 3
	LEN 12
	NOTE Ash, 3
	LEN 6
	NOTE A_, 3
	NOTE Gsh, 3
	GLIDE $01
	DUTY_50
	HWENV $A3, $00
	LEN 24
	NOTE G_, 3
	INSTR 9
	LEN 6
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	INSTR 6
	NOTE Fsh, 3
	WAIT2
	NOTE G_, 3
	WAIT2
	NOTE Gsh, 3
	WAIT2
	NOTE A_, 3
	WAIT2
	LEN 18
	NOTE Ash, 3
	LEN 6
	WAIT2
	GLIDE $02
	DUTY_75
	HWENV $A3, $00
	LEN 6
	VIBRATO $01, $02, $01
	NOTE D_, 5
	LEN 18
	GLIDE $00
	WAIT
	NEXT
Pat_571B:
	INSTR 14
	LEN 6
	REPEAT 2
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	REPEAT_END
	REPEAT 2
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE G_, 3
	REPEAT_END
	NOTE E_, 3
	WAIT2
	NOTE C_, 3
	WAIT2
	NOTE G_, 3
	WAIT2
	NOTE E_, 3
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE G_, 3
	WAIT2
	NOTE E_, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	LEN 18
	NOTE B_, 3
	LEN 6
	WAIT2
	LEN 18
	NOTE C_, 4
	LEN 6
	WAIT2
	LEN 18
	NOTE Csh, 4
	LEN 6
	WAIT2
	LEN 18
	NOTE D_, 4
	LEN 6
	WAIT2
	NEXT
Pat_5752:
	INSTR 14
	LEN 12
	NOTE E_, 4
	LEN 6
	NOTE G_, 4
	LEN 18
	WAIT2
	LEN 6
	NOTE Dsh, 5
	WAIT2
	NOTE E_, 5
	NOTE Dsh, 5
	NOTE E_, 5
	NOTE G_, 5
	LEN 12
	NOTE E_, 5
	WAIT2
	NOTE F_, 4
	LEN 6
	NOTE A_, 4
	LEN 18
	WAIT2
	LEN 6
	NOTE E_, 5
	WAIT2
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE D_, 5
	NOTE G_, 5
	WAIT2
	NOTE A_, 4
	WAIT2
	NOTE F_, 5
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE E_, 5
	WAIT2
	NOTE F_, 4
	WAIT2
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE E_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE B_, 3
	NOTE C_, 4
	LEN 18
	NOTE D_, 4
	LEN 6
	WAIT2
	NEXT
Pat_5794:
	HWENV $A2, $06, $77
	DUTY_50
	VIBRATO $06, $03, $02
	RELEASE $01, $20
	ARP 0
	LEN 12
	NOTE G_, 5
	LEN 6
	NOTE G_, 5
	NOTE Fsh, 5
	LEN 12
	NOTE G_, 5
	NOTE E_, 5
	LEN 6
	NOTE E_, 5
	NOTE Dsh, 5
	LEN 12
	NOTE E_, 5
	NOTE C_, 5
	NOTE A_, 4
	DUTY_75
	NOTE G_, 4
	LEN 6
	NOTE Fsh, 4
	NOTE G_, 4
	LEN 12
	NOTE A_, 4
	LEN 6
	NOTE Gsh, 4
	NOTE A_, 4
	LEN 12
	NOTE Ash, 4
	LEN 6
	NOTE A_, 4
	NOTE Gsh, 4
	LEN 12
	NOTE G_, 4
	WAIT2
	DUTY_50
	NOTE G_, 5
	LEN 6
	NOTE G_, 5
	NOTE Fsh, 5
	LEN 12
	NOTE G_, 5
	NOTE E_, 5
	LEN 6
	NOTE E_, 5
	NOTE Dsh, 5
	LEN 12
	NOTE E_, 5
	NOTE C_, 5
	NOTE A_, 4
	DUTY_75
	LEN 6
	NOTE Fsh, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE Gsh, 4
	WAIT2
	NOTE A_, 4
	WAIT2
	LEN 18
	NOTE Ash, 4
	LEN 6
	WAIT2
	LEN 12
	NOTE B_, 4
	NOTE G_, 4
	NEXT
Pat_57E3:
	LEN 36
	DUTY_75
	ARP_OFF
	NOTE G_, 5
	LEN 6
	NOTE Fsh, 5
	NOTE G_, 5
	LEN 24
	NOTE C_, 6
	NOTE E_, 5
	LEN 36
	NOTE F_, 5
	LEN 6
	NOTE E_, 5
	NOTE F_, 5
	LEN 24
	NOTE A_, 5
	NOTE D_, 5
	LEN 6
	NOTE Dsh, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE G_, 5
	NOTE Ash, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE A_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE Ash, 5
	NOTE C_, 5
	NOTE Csh, 5
	NOTE D_, 5
	NOTE B_, 5
	NOTE E_, 5
	NOTE F_, 5
	NEXT
Pat_5817:
	LEN 12
	NOTE G_, 5
	LEN 6
	NOTE G_, 5
	NOTE Fsh, 5
	LEN 12
	NOTE G_, 5
	NOTE Fsh, 5
	LEN 6
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE C_, 6
	LEN 12
	NOTE G_, 5
	LEN 6
	NOTE G_, 5
	NOTE Gsh, 5
	LEN 12
	NOTE A_, 5
	LEN 6
	NOTE A_, 5
	NOTE Gsh, 5
	LEN 12
	NOTE A_, 5
	NOTE Gsh, 5
	LEN 6
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	NOTE D_, 6
	LEN 12
	NOTE A_, 5
	LEN 6
	NOTE A_, 5
	NOTE Ash, 5
	NOTE B_, 5
	NOTE D_, 6
	NOTE B_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE C_, 6
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE B_, 5
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE C_, 6
	NOTE G_, 5
	NOTE E_, 5
	NOTE G_, 5
	LEN 24
	NOTE C_, 5
	NOTE G_, 4
	NEXT

; Song 4: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong4:
	call StopAll
	ld a, $6E
	ld [wInstrTableHi], a
	ld a, $B4
	ld [wInstrTable], a
	ld de, Song4_Ch3
	call StartMusicCh3
	ld de, Song4_Ch2
	call StartMusicCh2
	ld de, Song4_Ch1
	jp StartMusicCh1
Song4_Ch3:
	dw Pat_58BE
	dw Pat_58BE
	dw Pat_590F
	dw Pat_5940
	dw Pat_5995
	dw Pat_59F6
	dw Pat_5995
	dw Pat_59F6
	dw Pat_5A57
	dw Pat_5A57
	ORDER_LOOP Song4_Ch3
Song4_Ch2:
	dw Pat_5AA8
	dw Pat_5AA8
	dw Pat_5ADB
	dw Pat_5B13
	dw Pat_5B43
	dw Pat_5B80
	dw Pat_5B43
	dw Pat_5B80
	dw Pat_5BBC
	dw Pat_5BE1
	ORDER_LOOP Song4_Ch2
Song4_Ch1:
	dw Pat_5C01
	dw Pat_5C01
	dw Pat_5C2D
	dw Pat_5C55
	dw Pat_5CB3
	dw Pat_5CCA
	dw Pat_5CB3
	dw Pat_5CCA
	dw Pat_5CE1
	dw Pat_5D12
	ORDER_LOOP Song4_Ch1
Pat_58BE:
	CH_TRANSPOSE $0C
	TRANSPOSE $02
	RELEASE $01, $51
	INSTR 11
	LEN 20
	NOTE F_, 2
	INSTR 5
	LEN 10
	NOTE F_, 4
	INSTR 11
	LEN 20
	NOTE C_, 3
	INSTR 5
	LEN 10
	NOTE F_, 4
	INSTR 11
	LEN 20
	NOTE B_, 2
	INSTR 5
	LEN 10
	NOTE F_, 4
	INSTR 11
	LEN 20
	NOTE C_, 3
	INSTR 5
	LEN 10
	NOTE F_, 4
	INSTR 10
	LENGTH $3C
	NOTE Ash, 2
	LEN 10
	NOTE C_, 3
	WAIT2
	INSTR 11
	NOTE Ash, 2
	LEN 20
	NOTE Gsh, 2
	LEN 10
	NOTE G_, 2
	LEN 20
	NOTE F_, 2
	INSTR 5
	LEN 10
	NOTE F_, 4
	INSTR 11
	LEN 20
	NOTE C_, 3
	INSTR 5
	LEN 10
	NOTE F_, 4
	INSTR 11
	LEN 20
	NOTE B_, 2
	INSTR 5
	LEN 10
	NOTE F_, 4
	INSTR 11
	LEN 20
	NOTE C_, 3
	INSTR 5
	LEN 10
	NOTE F_, 4
	INSTR 10
	LENGTH $3C
	NOTE Csh, 2
	LEN 10
	NOTE C_, 2
	WAIT2
	INSTR 11
	NOTE D_, 2
	LEN 20
	NOTE Dsh, 2
	LEN 10
	NOTE E_, 2
	NEXT
Pat_590F:
	INSTR 10
	LEN 40
	NOTE Ash, 2
	LEN 10
	WAIT2
	NOTE F_, 2
	LENGTH $32
	NOTE Ash, 2
	LEN 10
	NOTE C_, 2
	LEN 40
	NOTE F_, 2
	LEN 10
	WAIT2
	NOTE C_, 2
	LENGTH $32
	NOTE F_, 2
	LEN 10
	WAIT2
	LEN 20
	NOTE Csh, 2
	LEN 10
	WAIT2
	LEN 20
	NOTE Dsh, 2
	LEN 10
	WAIT2
	LEN 40
	NOTE C_, 2
	LEN 20
	WAIT2
	NOTE Csh, 2
	LEN 10
	WAIT2
	LEN 20
	NOTE Gsh, 2
	LEN 10
	WAIT2
	LEN 20
	NOTE C_, 3
	LEN 10
	WAIT2
	LEN 20
	NOTE C_, 2
	LEN 10
	WAIT2
	NEXT
Pat_5940:
	INSTR 11
	LEN 20
	NOTE F_, 2
	INSTR 5
	LEN 10
	NOTE F_, 4
	INSTR 11
	LEN 20
	NOTE C_, 3
	INSTR 5
	LEN 10
	NOTE F_, 4
	INSTR 11
	LEN 20
	NOTE B_, 2
	INSTR 5
	LEN 10
	NOTE F_, 4
	INSTR 11
	LEN 20
	NOTE C_, 3
	INSTR 5
	LEN 10
	NOTE F_, 4
	INSTR 10
	LENGTH $3C
	NOTE Ash, 2
	LEN 10
	NOTE C_, 3
	LEN 20
	WAIT2
	INSTR 11
	LEN 10
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	LEN 20
	NOTE F_, 2
	INSTR 5
	LEN 10
	NOTE F_, 4
	INSTR 11
	LEN 20
	NOTE C_, 2
	INSTR 5
	LEN 10
	NOTE F_, 4
	INSTR 11
	LEN 20
	NOTE F_, 2
	INSTR 5
	LEN 10
	NOTE F_, 4
	INSTR 11
	LEN 20
	NOTE C_, 2
	INSTR 5
	LEN 10
	NOTE F_, 4
	INSTR 11
	LEN 20
	NOTE F_, 2
	INSTR 5
	LEN 10
	NOTE F_, 4
	INSTR 11
	LEN 20
	NOTE G_, 2
	INSTR 5
	LEN 10
	NOTE F_, 4
	INSTR 11
	LEN 20
	NOTE Gsh, 2
	INSTR 5
	LEN 10
	NOTE F_, 4
	INSTR 11
	LEN 20
	NOTE A_, 2
	INSTR 5
	LEN 10
	NOTE F_, 4
	NEXT
Pat_5995:
	INSTR 11
	LEN 20
	NOTE Ash, 2
	INSTR 5
	LEN 10
	NOTE Ash, 3
	INSTR 11
	LEN 20
	NOTE F_, 2
	INSTR 5
	LEN 10
	NOTE Ash, 3
	INSTR 11
	LEN 20
	NOTE Ash, 2
	INSTR 5
	LEN 10
	NOTE Ash, 3
	INSTR 11
	LEN 20
	NOTE F_, 2
	INSTR 5
	LEN 10
	NOTE Ash, 3
	INSTR 11
	LEN 20
	NOTE Ash, 2
	INSTR 5
	LEN 10
	NOTE Ash, 3
	INSTR 11
	LEN 20
	NOTE F_, 2
	INSTR 5
	LEN 10
	NOTE Ash, 3
	INSTR 11
	LEN 20
	NOTE Ash, 2
	INSTR 5
	LEN 10
	NOTE Ash, 3
	INSTR 11
	LEN 20
	NOTE F_, 2
	INSTR 5
	LEN 10
	NOTE Ash, 3
	INSTR 11
	LEN 20
	NOTE F_, 2
	INSTR 5
	LEN 10
	NOTE F_, 3
	INSTR 11
	LEN 20
	NOTE C_, 2
	INSTR 5
	LEN 10
	NOTE F_, 3
	INSTR 11
	LEN 20
	NOTE F_, 2
	INSTR 5
	LEN 10
	NOTE F_, 3
	INSTR 11
	LEN 20
	NOTE C_, 2
	INSTR 5
	LEN 10
	NOTE F_, 3
	INSTR 11
	LEN 20
	NOTE F_, 2
	INSTR 5
	LEN 10
	NOTE F_, 3
	INSTR 11
	LEN 20
	NOTE C_, 2
	INSTR 5
	LEN 10
	NOTE F_, 3
	INSTR 11
	LEN 20
	NOTE F_, 2
	INSTR 5
	LEN 10
	NOTE F_, 3
	INSTR 11
	LEN 20
	NOTE C_, 2
	INSTR 5
	LEN 10
	NOTE F_, 3
	NEXT
Pat_59F6:
	INSTR 11
	LEN 20
	NOTE Ash, 2
	INSTR 5
	LEN 10
	NOTE Ash, 3
	INSTR 11
	LEN 20
	NOTE F_, 2
	INSTR 5
	LEN 10
	NOTE Ash, 3
	INSTR 11
	LEN 20
	NOTE Ash, 2
	INSTR 5
	LEN 10
	NOTE Ash, 3
	INSTR 11
	LEN 20
	NOTE F_, 2
	INSTR 5
	LEN 10
	NOTE Ash, 3
	INSTR 11
	LEN 20
	NOTE Ash, 2
	INSTR 5
	LEN 10
	NOTE Ash, 3
	INSTR 11
	LEN 20
	NOTE F_, 2
	INSTR 5
	LEN 10
	NOTE Ash, 3
	INSTR 11
	LEN 20
	NOTE Ash, 2
	INSTR 5
	LEN 10
	NOTE Ash, 3
	INSTR 11
	LEN 20
	NOTE F_, 2
	INSTR 5
	LEN 10
	NOTE Ash, 3
	INSTR 11
	LEN 20
	NOTE C_, 3
	INSTR 4
	LEN 10
	NOTE C_, 4
	INSTR 11
	LEN 20
	NOTE G_, 2
	INSTR 4
	LEN 10
	NOTE C_, 4
	INSTR 11
	LEN 20
	NOTE C_, 3
	INSTR 4
	LEN 10
	NOTE C_, 4
	INSTR 11
	LEN 20
	NOTE G_, 2
	INSTR 4
	LEN 10
	NOTE C_, 4
	INSTR 11
	LEN 20
	NOTE C_, 3
	INSTR 4
	LEN 10
	NOTE C_, 4
	INSTR 11
	LEN 20
	NOTE Ash, 2
	INSTR 4
	LEN 10
	NOTE C_, 4
	INSTR 11
	LEN 20
	NOTE Gsh, 2
	INSTR 4
	LEN 10
	NOTE C_, 4
	INSTR 11
	LEN 20
	NOTE G_, 2
	INSTR 4
	LEN 10
	NOTE C_, 4
	NEXT
Pat_5A57:
	INSTR 11
	LEN 20
	NOTE F_, 2
	LEN 10
	NOTE C_, 3
	LEN 20
	NOTE B_, 2
	LEN 10
	NOTE C_, 3
	LEN 20
	NOTE Csh, 3
	LEN 10
	NOTE C_, 3
	LEN 20
	NOTE Csh, 3
	LEN 10
	NOTE C_, 3
	LEN 20
	NOTE Csh, 2
	INSTR 4
	LEN 10
	NOTE Csh, 4
	INSTR 11
	LEN 20
	NOTE Csh, 2
	INSTR 4
	LEN 10
	NOTE Csh, 4
	INSTR 11
	LEN 20
	NOTE C_, 2
	INSTR 4
	LEN 10
	NOTE C_, 4
	INSTR 11
	LEN 20
	NOTE C_, 2
	INSTR 4
	LEN 10
	NOTE C_, 4
	INSTR 11
	LEN 20
	NOTE F_, 2
	LEN 10
	NOTE C_, 3
	LEN 20
	NOTE B_, 2
	LEN 10
	NOTE C_, 3
	LEN 20
	NOTE Csh, 3
	LEN 10
	NOTE C_, 3
	LEN 20
	NOTE Csh, 3
	LEN 10
	NOTE C_, 3
	LEN 20
	NOTE Csh, 2
	INSTR 4
	LEN 10
	NOTE Csh, 4
	INSTR 11
	LEN 20
	NOTE Csh, 2
	INSTR 4
	LEN 10
	NOTE Csh, 4
	INSTR 11
	LEN 20
	NOTE E_, 2
	INSTR 4
	LEN 10
	NOTE C_, 4
	INSTR 11
	LEN 20
	NOTE E_, 2
	INSTR 4
	LEN 10
	NOTE C_, 4
	NEXT
Pat_5AA8:
	INSTR 9
	LEN 10
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE Gsh, 4
	INSTR 14
	LENGTH $3C
	NOTE Ash, 3
	LEN 10
	NOTE G_, 3
	INSTR 9
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE Gsh, 4
	INSTR 14
	LENGTH $3C
	NOTE F_, 3
	LEN 10
	NOTE E_, 3
	INSTR 9
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NEXT
Pat_5ADB:
	INSTR 9
	LEN 10
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE Dsh, 5
	INSTR 14
	LEN 20
	NOTE F_, 4
	LEN 10
	WAIT2
	LEN 20
	NOTE G_, 4
	LEN 10
	WAIT2
	LEN 30
	NOTE E_, 4
	LEN 10
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	LEN 20
	NOTE Gsh, 4
	LEN 10
	WAIT2
	LEN 20
	NOTE Ash, 4
	LEN 10
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE Ash, 3
	NOTE Gsh, 3
	WAIT2
	NOTE G_, 3
	NEXT
Pat_5B13:
	INSTR 9
	LEN 10
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE Gsh, 4
	INSTR 14
	LENGTH $3C
	NOTE Ash, 3
	LEN 10
	NOTE G_, 3
	LEN 20
	WAIT2
	LEN 10
	NOTE C_, 3
	NOTE D_, 3
	NOTE E_, 3
	LEN 40
	NOTE F_, 3
	LEN 10
	NOTE Fsh, 3
	NOTE G_, 3
	LEN 40
	NOTE Gsh, 3
	LEN 10
	NOTE Ash, 3
	NOTE B_, 3
	LENGTH $3C
	NOTE C_, 4
	INSTR 9
	LEN 10
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE Gsh, 5
	NEXT
Pat_5B43:
	INSTR 14
	LEN 10
	NOTE Ash, 3
	INSTR 6
	NOTE Csh, 5
	NOTE Csh, 5
	LEN 20
	NOTE Csh, 5
	INSTR 14
	LEN 10
	NOTE F_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Ash, 3
	INSTR 6
	NOTE Csh, 5
	NOTE Csh, 5
	LEN 20
	NOTE Csh, 5
	INSTR 14
	LEN 10
	NOTE F_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE C_, 4
	INSTR 6
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 20
	NOTE Gsh, 4
	INSTR 14
	LEN 10
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 20
	NOTE Dsh, 4
	LEN 10
	NOTE C_, 4
	NEXT
Pat_5B80:
	INSTR 14
	LEN 10
	NOTE Ash, 3
	INSTR 6
	NOTE Csh, 5
	NOTE Csh, 5
	LEN 20
	NOTE Csh, 5
	INSTR 14
	LEN 10
	NOTE F_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Ash, 3
	INSTR 6
	NOTE Csh, 5
	NOTE Csh, 5
	LEN 20
	NOTE Csh, 5
	INSTR 14
	LEN 10
	NOTE F_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE Dsh, 4
	NOTE C_, 4
	INSTR 6
	NOTE G_, 4
	NOTE G_, 4
	LEN 20
	NOTE G_, 4
	INSTR 14
	LEN 10
	NOTE C_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NEXT
Pat_5BBC:
	INSTR 14
	LENGTH $78
	NOTE F_, 4
	LENGTH $46
	WAIT2
	LEN 10
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LENGTH $64
	NOTE C_, 5
	LEN 10
	NOTE Csh, 5
	NOTE Dsh, 5
	ARP 3
	NOTE Csh, 5
	WAIT2
	ARP_OFF
	LEN 20
	NOTE Csh, 5
	LEN 10
	NOTE F_, 5
	NOTE G_, 5
	ARP 3
	NOTE F_, 5
	WAIT2
	ARP_OFF
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE G_, 5
	NEXT
Pat_5BE1:
	INSTR 14
	LENGTH $78
	NOTE Gsh, 5
	LENGTH $46
	WAIT2
	LEN 10
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE Ash, 5
	NOTE G_, 5
	NOTE Gsh, 5
	LENGTH $64
	NOTE C_, 5
	LEN 10
	NOTE F_, 4
	NOTE G_, 4
	LEN 20
	NOTE Gsh, 4
	NOTE F_, 4
	LEN 10
	NOTE C_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NEXT
Pat_5C01:
	INSTR 14
	LEN 10
	NOTE F_, 3
	WAIT2
	NOTE G_, 3
	NOTE Gsh, 3
	WAIT2
	NOTE C_, 4
	LEN 30
	NOTE B_, 3
	LEN 10
	NOTE C_, 4
	LEN 20
	WAIT2
	LENGTH $3C
	NOTE Csh, 4
	LEN 10
	NOTE C_, 4
	LENGTH $32
	WAIT2
	LEN 10
	NOTE F_, 3
	WAIT2
	NOTE G_, 3
	NOTE Gsh, 3
	WAIT2
	NOTE C_, 4
	LEN 30
	NOTE B_, 3
	LEN 10
	NOTE C_, 4
	LEN 20
	WAIT2
	LENGTH $3C
	NOTE Gsh, 3
	LEN 10
	NOTE G_, 3
	LENGTH $32
	WAIT2
	NEXT
Pat_5C2D:
	INSTR 14
	LEN 40
	NOTE F_, 3
	LEN 10
	NOTE Gsh, 3
	NOTE G_, 3
	LEN 40
	NOTE F_, 3
	LEN 10
	NOTE Gsh, 3
	NOTE G_, 3
	LEN 30
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE C_, 4
	LEN 20
	NOTE Csh, 4
	LEN 10
	WAIT2
	LEN 20
	NOTE Dsh, 4
	LEN 10
	WAIT2
	LEN 40
	NOTE C_, 4
	LEN 20
	WAIT2
	NOTE Csh, 4
	LEN 10
	WAIT2
	LEN 20
	NOTE F_, 4
	LEN 10
	WAIT2
	NOTE E_, 4
	LENGTH $32
	WAIT2
	NEXT
Pat_5C55:
	INSTR 14
	LEN 10
	NOTE F_, 3
	WAIT2
	NOTE G_, 3
	NOTE Gsh, 3
	WAIT2
	NOTE C_, 4
	LEN 30
	NOTE B_, 3
	LEN 10
	NOTE C_, 4
	LEN 20
	WAIT2
	LENGTH $3C
	NOTE Csh, 4
	LEN 10
	NOTE C_, 4
	LEN 20
	WAIT2
	LEN 10
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 20
	WAIT2
	LEN 10
	NOTE C_, 4
	LEN 20
	WAIT2
	LEN 10
	NOTE Gsh, 4
	LEN 20
	WAIT2
	LEN 10
	NOTE F_, 4
	LEN 20
	WAIT2
	LEN 10
	NOTE C_, 5
	WAIT2
	NOTE Gsh, 4
	NOTE F_, 5
	WAIT2
	NOTE C_, 5
	NOTE Gsh, 5
	WAIT2
	NOTE F_, 5
	NOTE C_, 6
	WAIT2
	NOTE Gsh, 5
	NEXT
Pat_5C8B:
	LEN 10
	WAIT2
	INSTR 6
	NOTE F_, 5
	NOTE F_, 5
	LEN 20
	NOTE F_, 5
	INSTR 9
	LEN 10
	NOTE F_, 4
	NOTE Csh, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE Csh, 5
	NOTE Ash, 4
	INSTR 6
	NOTE F_, 5
	NOTE F_, 5
	LEN 20
	NOTE F_, 5
	INSTR 9
	LEN 10
	NOTE F_, 4
	NOTE Csh, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE Csh, 5
	NOTE C_, 5
	INSTR 6
	NOTE C_, 5
	NOTE C_, 5
	LEN 20
	NOTE C_, 5
	INSTR 9
	LEN 10
	NEXT
Pat_5CB3:
	PAT_CALL Pat_5C8B
	NOTE C_, 5
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE Gsh, 5
	NOTE F_, 5
	NOTE Gsh, 5
	NOTE C_, 6
	NOTE Gsh, 5
	NOTE C_, 6
	NOTE F_, 6
	NOTE C_, 6
	NOTE F_, 6
	NOTE Gsh, 6
	NEXT
Pat_5CCA:
	PAT_CALL Pat_5C8B
	NOTE G_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE G_, 5
	NOTE C_, 6
	NOTE E_, 6
	NOTE C_, 6
	NOTE E_, 6
	NOTE G_, 6
	NEXT
Pat_5CE1:
	HWENV $F2, $0A, $66
	ARP 20
	DUTY_50
	LEN 20
	NOTE F_, 2
	LEN 10
	NOTE C_, 3
	LEN 20
	NOTE B_, 2
	LEN 10
	NOTE C_, 3
	LEN 20
	NOTE Csh, 3
	LEN 10
	NOTE C_, 3
	LEN 20
	NOTE Csh, 3
	LEN 10
	NOTE C_, 3
	LEN 30
	NOTE Csh, 3
	NOTE Csh, 3
	NOTE E_, 3
	NOTE E_, 3
	LEN 20
	NOTE F_, 3
	LEN 10
	NOTE C_, 4
	LEN 20
	NOTE B_, 3
	LEN 10
	NOTE C_, 4
	LEN 20
	NOTE Csh, 4
	LEN 10
	NOTE C_, 4
	LEN 20
	NOTE Csh, 4
	LEN 10
	NOTE C_, 4
	LEN 30
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE G_, 3
	NEXT
Pat_5D12:
	LEN 20
	NOTE F_, 2
	LEN 10
	NOTE C_, 3
	LEN 20
	NOTE B_, 2
	LEN 10
	NOTE C_, 3
	LEN 20
	NOTE Csh, 3
	LEN 10
	NOTE C_, 3
	LEN 20
	NOTE Csh, 3
	LEN 10
	NOTE C_, 3
	LEN 30
	NOTE Csh, 3
	NOTE Csh, 3
	NOTE E_, 3
	NOTE E_, 3
	LEN 20
	NOTE F_, 3
	LEN 10
	NOTE C_, 4
	LEN 20
	NOTE B_, 3
	LEN 10
	NOTE C_, 4
	LEN 20
	NOTE Csh, 4
	LEN 10
	NOTE C_, 4
	LEN 20
	NOTE Csh, 4
	LEN 10
	NOTE C_, 4
	LEN 30
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE G_, 3
	NEXT

; Song 5: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong5:
	call StopAll
	ld a, $6E
	ld [wInstrTableHi], a
	ld a, $B4
	ld [wInstrTable], a
	ld de, Song5_Ch3
	call StartMusicCh3
	ld de, Song5_Ch2
	call StartMusicCh2
	ld de, Song5_Ch1
	jp StartMusicCh1
Song5_Ch3:
	dw Pat_5DAA
	dw Pat_5DB2
	dw Pat_5DF7
	dw Pat_5DFE
	dw Pat_5DAA
	dw Pat_5DB2
	dw Pat_5E46
	dw Pat_5E7C
	dw Pat_5E7C
	dw Pat_5E7C
	dw Pat_5E89
	ORDER_LOOP Song5_Ch3
Song5_Ch2:
	dw Pat_5E8E
	dw Pat_5E9B
	dw Pat_5EFF
	dw Pat_5F1C
	dw Pat_5E8E
	dw Pat_5E9B
	dw Pat_5F39
	dw Pat_5E9B
	dw Pat_5E9B
	dw Pat_5E9B
	dw Pat_5E9B
	ORDER_LOOP Song5_Ch2
Song5_Ch1:
	dw Pat_5F68
	dw Pat_5F84
	dw Pat_5FA0
	dw Pat_5FE0
	dw Pat_5F68
	dw Pat_6014
	dw Pat_6054
	dw Pat_605F
	dw Pat_60A0
	dw Pat_60BA
	dw Pat_60C7
	ORDER_LOOP Song5_Ch1
Pat_5DAA:
	CH_TRANSPOSE $0C
	TRANSPOSE $FD
	DRUMS $08, DrumPat_60E8
Pat_5DB2:
	LEN 16
	REPEAT 2
	INSTR 11
	NOTE Gsh, 2
	INSTR 4
	NOTE Gsh, 3
	INSTR 11
	NOTE Csh, 3
	INSTR 4
	NOTE Csh, 4
	INSTR 11
	NOTE C_, 3
	INSTR 5
	NOTE C_, 4
	INSTR 11
	NOTE Ash, 2
	INSTR 5
	NOTE Ash, 3
	INSTR 11
	NOTE Gsh, 2
	INSTR 4
	NOTE Gsh, 3
	INSTR 11
	NOTE Dsh, 2
	INSTR 4
	NOTE Gsh, 3
	INSTR 11
	NOTE Gsh, 2
	INSTR 4
	NOTE Gsh, 3
	INSTR 11
	NOTE Dsh, 3
	INSTR 4
	NOTE Gsh, 3
	REPEAT_END
	NEXT
Pat_5DD6:
	INSTR 11
	NOTE Dsh, 2
	INSTR 4
	NOTE Dsh, 4
	INSTR 11
	NOTE Ash, 2
	INSTR 4
	NOTE Dsh, 4
	INSTR 11
	NOTE Dsh, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 11
	NOTE Ash, 2
	INSTR 4
	NOTE Dsh, 4
	INSTR 11
	NOTE Gsh, 2
	INSTR 4
	NOTE Gsh, 4
	INSTR 11
	NOTE Dsh, 3
	INSTR 4
	NOTE Gsh, 4
	INSTR 11
	NOTE Gsh, 3
	INSTR 4
	NOTE Gsh, 4
	INSTR 11
	NOTE Dsh, 3
	INSTR 4
	NOTE Gsh, 4
	NEXT
Pat_5DF7:
	LEN 16
	REPEAT 2
	PAT_CALL Pat_5DD6
	REPEAT_END
	NEXT
Pat_5DFE:
	PAT_CALL Pat_5DD6
	INSTR 11
	NOTE Dsh, 2
	INSTR 4
	NOTE Dsh, 4
	INSTR 11
	NOTE Ash, 2
	INSTR 4
	NOTE Dsh, 4
	INSTR 11
	NOTE Dsh, 3
	INSTR 4
	NOTE Dsh, 4
	INSTR 11
	NOTE Dsh, 2
	INSTR 4
	NOTE Dsh, 4
	INSTR 11
	NOTE Gsh, 2
	INSTR 4
	NOTE Gsh, 4
	INSTR 11
	NOTE Dsh, 2
	INSTR 4
	NOTE Gsh, 4
	INSTR 11
	NOTE Gsh, 2
	NOTE Dsh, 2
	NOTE F_, 2
	NOTE G_, 2
	NEXT
Pat_5E1F:
	INSTR 11
	NOTE Ash, 2
	INSTR 12
	LEN 8
	NOTE Ash, 3
	INSTR 11
	LEN 16
	NOTE Ash, 2
	INSTR 12
	LEN 8
	NOTE Ash, 3
	INSTR 11
	LEN 16
	NOTE Ash, 2
	NOTE Ash, 2
	INSTR 12
	LEN 32
	NOTE Ash, 3
	LEN 16
	NOTE F_, 3
	INSTR 11
	NOTE Ash, 2
	INSTR 12
	LEN 8
	NOTE Ash, 3
	INSTR 11
	LEN 16
	NOTE Ash, 2
	INSTR 12
	LEN 8
	NOTE Ash, 3
	INSTR 11
	LEN 16
	NOTE Ash, 2
	NOTE Ash, 2
	INSTR 12
	NOTE Ash, 3
	INSTR 11
	NEXT
Pat_5E46:
	PAT_CALL Pat_5E1F
	NOTE F_, 2
	INSTR 12
	NOTE F_, 3
	PAT_CALL Pat_5E1F
	NOTE F_, 3
	INSTR 12
	NOTE F_, 4
	NEXT
Pat_5E53:
	LEN 16
	INSTR 11
	NOTE Ash, 2
	INSTR 12
	LEN 8
	NOTE Ash, 3
	INSTR 11
	NOTE Ash, 2
	INSTR 4
	NOTE Ash, 4
	INSTR 12
	NOTE Ash, 3
	INSTR 11
	LEN 16
	NOTE Ash, 2
	NOTE Ash, 2
	INSTR 12
	NOTE Ash, 3
	INSTR 4
	NOTE Ash, 4
	INSTR 12
	NOTE F_, 3
	INSTR 11
	NOTE Ash, 2
	INSTR 12
	LEN 8
	NOTE Ash, 3
	INSTR 11
	NOTE Ash, 2
	INSTR 4
	NOTE Ash, 4
	INSTR 12
	NOTE Ash, 3
	INSTR 11
	LEN 16
	NOTE Ash, 2
	NOTE Ash, 2
	INSTR 12
	NOTE Ash, 3
	INSTR 11
	NEXT
Pat_5E7C:
	PAT_CALL Pat_5E53
	NOTE F_, 2
	INSTR 12
	NOTE F_, 3
	PAT_CALL Pat_5E53
	NOTE F_, 3
	INSTR 12
	NOTE F_, 4
	NEXT
Pat_5E89:
	CH_TRANSPOSE $0E
	PAT_GOTO Pat_5DB2
Pat_5E8E:
	HWENV $81, $02, $40
	CH_TRANSPOSE $00
	AUTODUTY $08
	ARP 7
	RELEASE $04, $42
	LEN 8
Pat_5E9B:
	NOTE Gsh, 4
	NOTE Dsh, 5
	NOTE C_, 6
	NOTE Gsh, 5
	NOTE Dsh, 6
	NOTE Gsh, 5
	NOTE Csh, 6
	NOTE Gsh, 5
	NOTE C_, 6
	NOTE Csh, 6
	NOTE Dsh, 6
	NOTE C_, 6
	NOTE Ash, 5
	NOTE C_, 6
	NOTE Csh, 6
	NOTE Ash, 5
	NOTE C_, 6
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE Dsh, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE C_, 6
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE Csh, 6
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE Gsh, 4
	NOTE Dsh, 5
	NOTE C_, 6
	NOTE Gsh, 5
	NOTE Dsh, 6
	NOTE Gsh, 5
	NOTE Csh, 6
	NOTE Gsh, 5
	NOTE C_, 6
	NOTE Csh, 6
	NOTE Dsh, 6
	NOTE C_, 6
	NOTE Ash, 5
	NOTE C_, 6
	NOTE Csh, 6
	NOTE Ash, 5
	NOTE C_, 6
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE Dsh, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE C_, 6
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE F_, 6
	NOTE G_, 6
	NOTE Gsh, 6
	WAIT
	NEXT
Pat_5EDC:
	NOTE Ash, 4
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE Csh, 6
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE Ash, 5
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE Csh, 6
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	REPEAT 2
	NOTE Gsh, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE C_, 6
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE Dsh, 5
	REPEAT_END
	NOTE Ash, 5
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE Csh, 6
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NEXT
Pat_5EFF:
	LEN 8
	PAT_CALL Pat_5EDC
	NOTE Ash, 5
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE Csh, 6
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE Ash, 5
	NOTE C_, 6
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE Csh, 6
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE Dsh, 6
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE F_, 6
	NOTE Dsh, 6
	NOTE C_, 6
	NOTE Gsh, 5
	NEXT
Pat_5F1C:
	LEN 8
	PAT_CALL Pat_5EDC
	NOTE Dsh, 6
	NOTE Ash, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE Dsh, 6
	NOTE C_, 6
	NOTE Ash, 5
	NOTE C_, 6
	NOTE Gsh, 5
	NOTE C_, 6
	NOTE Dsh, 6
	NOTE C_, 6
	NOTE Gsh, 6
	NOTE Dsh, 6
	NOTE C_, 6
	NOTE Dsh, 6
	NOTE Gsh, 5
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE Gsh, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE Dsh, 5
	NEXT
Pat_5F39:
	CH_TRANSPOSE $02
	PAT_GOTO Pat_5E9B

; Unreferenced (1 bytes)
	db $6A
Pat_5F3F:
	INSTR 6
	DUTY_50
	LEN 16
	NOTE Gsh, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE Csh, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE Csh, 5
	NOTE Ash, 4
	LEN 8
	NOTE C_, 5
	NOTE Csh, 5
	LEN 32
	NOTE Dsh, 5
	INSTR 13
	DUTY_12
	LEN 8
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	WAIT2
	NOTE G_, 4
	NOTE F_, 4
	LEN 24
	NOTE Dsh, 4
	LEN 8
	WAIT2
	INSTR 6
	DUTY_50
	LEN 16
	NOTE Gsh, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE Csh, 5
	NOTE Dsh, 5
	LEN 8
	NOTE Ash, 4
	NOTE C_, 5
	NEXT
Pat_5F68:
	PAT_CALL Pat_5F3F
	LEN 16
	NOTE Csh, 5
	LEN 8
	NOTE C_, 5
	NOTE Ash, 4
	LEN 16
	NOTE Gsh, 4
	INSTR 13
	DUTY_12
	LEN 8
	NOTE Dsh, 3
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE Gsh, 3
	WAIT2
	NOTE Dsh, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Dsh, 4
	WAIT2
	NEXT
Pat_5F84:
	PAT_CALL Pat_5F3F
	NOTE Csh, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE G_, 5
	LEN 16
	NOTE Gsh, 5
	INSTR 13
	DUTY_12
	LEN 8
	NOTE Dsh, 3
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE Gsh, 3
	WAIT2
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Ash, 3
	NOTE Gsh, 3
	WAIT2
	INSTR 6
	NOTE G_, 4
	NOTE F_, 4
	NEXT
Pat_5FA0:
	INSTR 6
	LEN 16
	NOTE Dsh, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE C_, 5
	LEN 32
	NOTE Ash, 4
	LEN 24
	NOTE F_, 4
	LEN 8
	NOTE E_, 4
	LEN 16
	NOTE Dsh, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE Csh, 5
	NOTE C_, 5
	INSTR 13
	LEN 8
	NOTE C_, 5
	NOTE Csh, 5
	NOTE Dsh, 5
	WAIT2
	INSTR 6
	NOTE C_, 4
	NOTE Csh, 4
	LEN 16
	NOTE Dsh, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	LEN 8
	NOTE C_, 5
	LEN 24
	NOTE Ash, 4
	LEN 16
	NOTE Csh, 5
	NOTE C_, 5
	INSTR 13
	LEN 8
	NOTE C_, 5
	WAIT2
	INSTR 6
	LEN 16
	NOTE Gsh, 4
	INSTR 13
	LEN 8
	NOTE Gsh, 4
	WAIT2
	INSTR 6
	LEN 16
	NOTE F_, 4
	INSTR 13
	LEN 8
	NOTE F_, 4
	WAIT2
	INSTR 6
	NOTE Dsh, 4
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE F_, 4
	NEXT
Pat_5FE0:
	INSTR 6
	LEN 16
	NOTE Dsh, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE C_, 5
	LEN 32
	NOTE Ash, 4
	LEN 24
	NOTE F_, 4
	LEN 8
	NOTE E_, 4
	LEN 16
	NOTE Dsh, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE Csh, 5
	NOTE Dsh, 5
	INSTR 13
	LEN 8
	NOTE C_, 5
	NOTE Csh, 5
	NOTE Dsh, 5
	WAIT2
	INSTR 6
	NOTE C_, 4
	NOTE Csh, 4
	LEN 16
	NOTE Dsh, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Dsh, 5
	LEN 8
	NOTE C_, 5
	LEN 24
	NOTE Ash, 4
	LEN 16
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 8
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 16
	NOTE Gsh, 4
	INSTR 9
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE G_, 3
	NEXT
Pat_6014:
	INSTR 6
	ARP 20
	LEN 16
	NOTE Gsh, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE Csh, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE Csh, 5
	NOTE Ash, 4
	LEN 8
	NOTE C_, 5
	NOTE Csh, 5
	LEN 32
	NOTE Dsh, 5
	INSTR 13
	DUTY_12
	LEN 8
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	WAIT2
	NOTE G_, 4
	NOTE F_, 4
	LEN 24
	NOTE Dsh, 4
	LEN 8
	WAIT2
	INSTR 6
	ARP 20
	LEN 16
	NOTE Gsh, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE Csh, 5
	NOTE Dsh, 5
	LEN 8
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE G_, 5
	LEN 16
	NOTE Gsh, 5
	INSTR 13
	DUTY_12
	LEN 8
	NOTE Dsh, 3
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE Gsh, 3
	WAIT2
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Ash, 3
	LEN 24
	NOTE Gsh, 3
	LEN 8
	WAIT2
	NEXT
Pat_6054:
	DRUMS $08, DrumPat_612A
	INSTR 13
	CH_TRANSPOSE $F6
	PAT_CALL Pat_5E9B
	NEXT
Pat_605F:
	DRUMS $08, DrumPat_6106
	CH_TRANSPOSE $02
	PAT_CALL Pat_5E9B
	NEXT
Pat_6069:
	LENGTH $30
	NOTE F_, 5
	LEN 8
	NOTE G_, 5
	NOTE A_, 5
	LEN 16
	NOTE Ash, 5
	LEN 3
	NOTE A_, 5
	NOTE Ash, 5
	NOTE A_, 5
	LEN 7
	NOTE G_, 5
	LENGTH $50
	NOTE F_, 5
	LEN 8
	NOTE Dsh, 5
	NOTE F_, 5
	LEN 16
	NOTE G_, 5
	LEN 3
	NOTE F_, 5
	NOTE G_, 5
	NOTE F_, 5
	LEN 7
	NOTE Dsh, 5
	LEN 8
	NOTE D_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE Dsh, 5
	LENGTH $30
	NOTE D_, 5
	LEN 8
	NOTE C_, 5
	NOTE D_, 5
	LEN 16
	NOTE Dsh, 5
	LEN 3
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE D_, 5
	LEN 7
	NOTE C_, 5
	LENGTH $40
	NOTE Ash, 4
	LEN 8
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NEXT
Pat_60A0:
	CH_TRANSPOSE $0C
	VIBRATO $10, $01, $05
	HWENV $70, $00
	RELEASE $01, $73
	DUTY_50
	PAT_CALL Pat_6069
	NOTE A_, 4
	LEN 16
	NOTE Ash, 4
	NOTE F_, 4
	LEN 8
	NOTE D_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	NEXT
Pat_60BA:
	PAT_CALL Pat_6069
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE C_, 6
	NOTE D_, 6
	NOTE Dsh, 6
	NEXT
Pat_60C7:
	DRUMS $08, DrumPat_60E8
	LENGTH $78
	NOTE F_, 6
	LEN 8
	NOTE Dsh, 6
	LENGTH $78
	NOTE D_, 6
	LEN 8
	NOTE C_, 6
	LENGTH $60
	NOTE Ash, 5
	LEN 8
	NOTE A_, 5
	NOTE Ash, 5
	NOTE C_, 6
	NOTE A_, 5
	LEN 4
	NOTE Ash, 5
	NOTE C_, 6
	LENGTH $58
	NOTE Ash, 5
	LEN 32
	WAIT2
	CH_TRANSPOSE $00
	NEXT
DrumPat_60E8:
	db DRUM_LEVEL + 13, 7, 0, 9, 0, DRUM_REPEAT + 3, 1, 0
	db 9, 0, DRUM_REPEAT_END, DRUM_REPEAT + 3, 1, 0, 9, 0
	db 1, 0, 9, 0, 1, 0, 9, 0
	db 1, 0, 9, 0, DRUM_REPEAT_END, DRUM_LOOP
DrumPat_6106:
	db DRUM_LEVEL + 13, 7, 0, 4, 1, 9, 0, 1
	db 0, 1, 0, 4, 0, 9, 0, 4
	db 0, DRUM_REPEAT + 3, 1, 0, 4, 1, 9, 0
	db 1, 0, 1, 0, 4, 0, 9, 0
	db 4, 0, DRUM_REPEAT_END, DRUM_LOOP
DrumPat_612A:
	db DRUM_TEMPO + 32, DRUM_LEVEL + 13, DRUM_REPEAT + 3, 7, 4, 4, 4, DRUM_REPEAT_END
	db 7, 4, DRUM_TEMPO + 24, 4, DRUM_TEMPO + 4, 10, 10, DRUM_TEMPO + 8
	db 9, 0, 9, 9, DRUM_LOOP

; Song 6: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong6:
	call StopAll
	ld a, $6E
	ld [wInstrTableHi], a
	ld a, $B4
	ld [wInstrTable], a
	ld de, Song6_Ch3
	call StartMusicCh3
	ld de, Song6_Ch2
	call StartMusicCh2
	ld de, Song6_Ch1
	jp StartMusicCh1
Song6_Ch3:
	dw Pat_618E
	dw Pat_61B6
	dw Pat_618E
	dw Pat_61D7
	dw Pat_61FA
	dw Pat_6223
	ORDER_LOOP Song6_Ch3
Song6_Ch2:
	dw Pat_6254
	dw Pat_6285
	dw Pat_6254
	dw Pat_62B8
	dw Pat_62E8
	dw Pat_6325
	ORDER_LOOP Song6_Ch2
Song6_Ch1:
	dw Pat_6363
	dw Pat_6382
	dw Pat_6363
	dw Pat_63B0
	dw Pat_63DE
	dw Pat_640D
	ORDER_LOOP Song6_Ch1
Pat_618E:
	CH_TRANSPOSE $0C
	INSTR 11
	ARP 0
	LEN 18
	NOTE B_, 1
	NOTE Dsh, 2
	NOTE Fsh, 2
	LEN 12
	NOTE Dsh, 2
	LEN 6
	NOTE Dsh, 2
	LEN 12
	NOTE E_, 2
	LEN 6
	NOTE E_, 2
	LEN 18
	NOTE Gsh, 2
	NOTE B_, 2
	NOTE Gsh, 2
	NOTE Fsh, 2
	NOTE Ash, 2
	NOTE Csh, 3
	LEN 12
	NOTE Fsh, 2
	LEN 6
	NOTE Dsh, 2
	LEN 12
	NOTE B_, 1
	LEN 18
	NOTE Fsh, 2
	LEN 6
	NOTE G_, 2
	LEN 12
	NOTE Gsh, 2
	LEN 6
	NOTE G_, 2
	LEN 18
	NOTE Fsh, 2
	NEXT
Pat_61B6:
	LEN 18
	NOTE B_, 1
	NOTE Dsh, 2
	NOTE Fsh, 2
	NOTE Dsh, 2
	NOTE E_, 2
	NOTE Gsh, 2
	NOTE B_, 2
	LEN 12
	NOTE E_, 2
	LEN 6
	NOTE F_, 2
	LEN 12
	NOTE Fsh, 2
	LEN 6
	NOTE Fsh, 2
	LEN 18
	NOTE E_, 2
	NOTE Dsh, 2
	NOTE Csh, 2
	LEN 12
	NOTE B_, 1
	LEN 18
	NOTE Fsh, 2
	LEN 6
	NOTE G_, 2
	LEN 12
	NOTE Gsh, 2
	LEN 6
	NOTE G_, 2
	LEN 18
	NOTE Fsh, 2
	NEXT
Pat_61D7:
	LEN 18
	NOTE B_, 1
	NOTE Dsh, 2
	NOTE Fsh, 2
	NOTE Dsh, 2
	NOTE E_, 2
	NOTE Gsh, 2
	NOTE B_, 2
	LEN 12
	NOTE E_, 2
	LEN 6
	NOTE F_, 2
	LEN 12
	NOTE Fsh, 2
	LEN 6
	NOTE Fsh, 2
	LEN 18
	NOTE E_, 2
	NOTE Dsh, 2
	NOTE Csh, 2
	LEN 12
	NOTE B_, 1
	LEN 18
	NOTE Ash, 2
	LEN 6
	NOTE B_, 2
	LEN 12
	NOTE Csh, 3
	LEN 6
	NOTE B_, 2
	LEN 12
	NOTE Fsh, 2
	LEN 6
	NOTE B_, 1
	NEXT
Pat_61FA:
	LEN 18
	NOTE E_, 2
	NOTE Gsh, 2
	NOTE B_, 2
	LEN 12
	NOTE Gsh, 2
	LEN 18
	NOTE E_, 2
	LEN 6
	NOTE E_, 2
	LEN 18
	NOTE Gsh, 2
	LEN 12
	NOTE B_, 2
	LEN 6
	NOTE Gsh, 2
	LEN 12
	NOTE Fsh, 2
	LEN 6
	NOTE Dsh, 2
	LEN 18
	NOTE B_, 1
	NOTE Dsh, 2
	NOTE Fsh, 2
	LEN 12
	NOTE Dsh, 2
	LEN 18
	NOTE B_, 1
	LEN 6
	NOTE B_, 1
	LEN 18
	NOTE Dsh, 2
	LEN 12
	NOTE Fsh, 2
	LEN 6
	NOTE Dsh, 2
	LEN 12
	NOTE B_, 1
	LEN 6
	NOTE Dsh, 2
	NEXT
Pat_6223:
	LEN 18
	NOTE Csh, 2
	NOTE F_, 2
	NOTE Gsh, 2
	LEN 12
	NOTE F_, 2
	LEN 18
	NOTE Csh, 3
	LEN 6
	NOTE B_, 2
	LEN 12
	NOTE Gsh, 2
	LEN 6
	NOTE F_, 2
	LEN 12
	NOTE Csh, 3
	LEN 6
	NOTE Gsh, 2
	LEN 12
	NOTE F_, 2
	LEN 6
	NOTE Csh, 2
	LEN 18
	NOTE Fsh, 2
	LEN 12
	NOTE F_, 2
	LEN 6
	NOTE Fsh, 2
	LEN 18
	NOTE Gsh, 2
	LEN 12
	NOTE G_, 2
	LEN 6
	NOTE Gsh, 2
	LEN 12
	NOTE Ash, 2
	LEN 6
	NOTE A_, 2
	LEN 12
	NOTE Gsh, 2
	LEN 18
	NOTE Fsh, 2
	LEN 6
	NOTE Fsh, 3
	LEN 12
	NOTE Csh, 3
	LEN 6
	NOTE Fsh, 2
	NEXT
Pat_6254:
	INSTR 9
	LEN 18
	NOTE Fsh, 3
	NOTE B_, 3
	LEN 30
	NOTE Dsh, 4
	LEN 6
	NOTE B_, 3
	LEN 12
	NOTE Gsh, 3
	INSTR 14
	LEN 18
	NOTE E_, 4
	LEN 6
	NOTE Dsh, 4
	LEN 12
	NOTE E_, 4
	LEN 6
	NOTE Dsh, 4
	LEN 12
	NOTE Csh, 4
	LEN 6
	NOTE B_, 3
	NOTE Ash, 3
	LEN 12
	WAIT2
	INSTR 9
	LEN 18
	NOTE Ash, 3
	LEN 30
	NOTE Csh, 4
	LEN 6
	NOTE Ash, 3
	LEN 12
	NOTE Fsh, 3
	INSTR 14
	LEN 6
	NOTE Fsh, 3
	LEN 12
	WAIT2
	LEN 6
	NOTE G_, 3
	NOTE Gsh, 3
	WAIT2
	NOTE G_, 3
	NOTE Fsh, 3
	LEN 12
	WAIT2
	NEXT
Pat_6285:
	INSTR 9
	LEN 18
	NOTE Fsh, 3
	NOTE B_, 3
	LEN 30
	NOTE Dsh, 4
	LEN 6
	NOTE B_, 3
	LEN 12
	NOTE Csh, 4
	INSTR 14
	LEN 18
	NOTE E_, 4
	LEN 6
	NOTE Dsh, 4
	NOTE E_, 4
	WAIT2
	NOTE Dsh, 4
	NOTE Csh, 4
	WAIT2
	NOTE B_, 3
	NOTE Ash, 3
	LEN 12
	WAIT2
	LEN 6
	NOTE Fsh, 3
	LEN 12
	WAIT2
	LEN 6
	NOTE Dsh, 4
	LEN 12
	WAIT2
	LEN 6
	NOTE Csh, 4
	WAIT2
	NOTE B_, 3
	LEN 12
	WAIT2
	LEN 6
	NOTE Fsh, 3
	LEN 12
	WAIT2
	LEN 6
	NOTE G_, 3
	NOTE Gsh, 3
	WAIT2
	NOTE G_, 3
	NOTE Fsh, 3
	LEN 12
	WAIT2
	NEXT
Pat_62B8:
	INSTR 9
	LEN 18
	NOTE Fsh, 3
	NOTE B_, 3
	LEN 30
	NOTE Dsh, 4
	LEN 6
	NOTE B_, 3
	LEN 12
	NOTE Csh, 4
	INSTR 14
	LEN 18
	NOTE E_, 4
	LEN 6
	NOTE Dsh, 4
	LEN 12
	NOTE E_, 4
	LEN 6
	NOTE Dsh, 4
	LEN 12
	NOTE E_, 4
	LEN 6
	NOTE Gsh, 4
	NOTE Ash, 4
	WAIT2
	NOTE B_, 4
	NOTE Ash, 4
	WAIT2
	NOTE Gsh, 4
	NOTE Fsh, 4
	WAIT2
	NOTE Gsh, 4
	NOTE Fsh, 4
	WAIT2
	NOTE E_, 4
	NOTE Dsh, 4
	WAIT2
	LEN 18
	NOTE Ash, 3
	LEN 6
	NOTE B_, 3
	NOTE Csh, 4
	WAIT2
	NOTE B_, 3
	NOTE Ash, 3
	WAIT2
	NOTE B_, 3
	NEXT
Pat_62E8:
	INSTR 14
	LEN 6
	NOTE Gsh, 3
	LEN 12
	WAIT2
	INSTR 9
	LEN 18
	NOTE Gsh, 4
	INSTR 14
	LEN 6
	NOTE B_, 3
	LEN 12
	WAIT2
	INSTR 9
	NOTE B_, 4
	INSTR 14
	LEN 6
	NOTE E_, 4
	LEN 18
	WAIT2
	LEN 12
	NOTE Ash, 3
	LEN 6
	NOTE B_, 3
	NOTE Csh, 4
	WAIT2
	NOTE B_, 3
	NOTE Ash, 3
	WAIT2
	NOTE B_, 3
	NOTE Fsh, 3
	LEN 12
	WAIT2
	INSTR 9
	LEN 18
	NOTE Fsh, 4
	INSTR 14
	LEN 6
	NOTE Fsh, 4
	LEN 12
	WAIT2
	INSTR 9
	NOTE Dsh, 5
	INSTR 14
	LEN 6
	NOTE Dsh, 4
	LEN 12
	WAIT2
	LEN 6
	NOTE B_, 3
	LEN 12
	NOTE Ash, 3
	LEN 6
	NOTE B_, 3
	NOTE Csh, 4
	WAIT2
	NOTE B_, 3
	NOTE Ash, 3
	WAIT2
	NOTE B_, 3
	NEXT
Pat_6325:
	INSTR 14
	LEN 6
	NOTE Gsh, 3
	LEN 12
	WAIT2
	LEN 6
	NOTE F_, 3
	LEN 12
	WAIT2
	LEN 6
	NOTE Csh, 4
	LEN 12
	WAIT2
	LEN 6
	NOTE Gsh, 3
	WAIT2
	NOTE F_, 4
	LEN 18
	WAIT2
	LEN 6
	NOTE Gsh, 4
	LEN 12
	WAIT2
	LEN 6
	NOTE F_, 4
	LEN 12
	WAIT2
	LEN 6
	NOTE Csh, 4
	LEN 12
	WAIT2
	NOTE Fsh, 4
	LEN 6
	WAIT2
	LEN 12
	NOTE F_, 4
	LEN 6
	NOTE Fsh, 4
	LEN 12
	NOTE Gsh, 4
	LEN 6
	WAIT2
	LEN 12
	NOTE G_, 4
	LEN 6
	NOTE Gsh, 4
	NOTE Ash, 4
	WAIT2
	NOTE A_, 4
	NOTE Gsh, 4
	WAIT2
	NOTE Fsh, 4
	LEN 12
	WAIT2
	INSTR 9
	LEN 6
	NOTE Fsh, 5
	LEN 12
	NOTE Csh, 5
	LEN 6
	NOTE Fsh, 4
	NEXT
Pat_6363:
	DRUMS $06, DrumPat_643D
	INSTR 6
	DUTY_50
	LEN 18
	NOTE Fsh, 4
	NOTE B_, 4
	LEN 30
	NOTE Dsh, 5
	LEN 6
	NOTE B_, 4
	LEN 12
	NOTE Gsh, 4
	LENGTH $3C
	NOTE Csh, 5
	LEN 18
	NOTE Fsh, 4
	NOTE Ash, 4
	LEN 30
	NOTE Csh, 5
	LEN 6
	NOTE Ash, 4
	LEN 12
	NOTE Fsh, 4
	LENGTH $3C
	NOTE B_, 4
	NEXT
Pat_6382:
	INSTR 6
	DUTY_50
	LEN 18
	NOTE Fsh, 4
	NOTE B_, 4
	LEN 30
	NOTE Dsh, 5
	LEN 6
	NOTE B_, 4
	LEN 12
	NOTE Csh, 5
	LEN 18
	NOTE Dsh, 5
	NOTE E_, 5
	LEN 24
	NOTE Gsh, 5
	LEN 12
	NOTE Fsh, 5
	LEN 6
	NOTE Gsh, 5
	LEN 12
	NOTE Fsh, 5
	LEN 6
	NOTE E_, 5
	LEN 12
	NOTE Dsh, 5
	LEN 6
	NOTE E_, 5
	LEN 12
	NOTE Dsh, 5
	LEN 6
	NOTE Csh, 5
	LEN 12
	NOTE B_, 4
	INSTR 9
	LEN 18
	NOTE Fsh, 5
	LEN 6
	NOTE G_, 5
	LEN 12
	NOTE Gsh, 5
	LEN 6
	NOTE G_, 5
	LEN 18
	NOTE Fsh, 5
	NEXT
Pat_63B0:
	INSTR 6
	DUTY_50
	LEN 18
	NOTE Fsh, 4
	NOTE B_, 4
	LEN 30
	NOTE Dsh, 5
	LEN 6
	NOTE B_, 4
	LEN 12
	NOTE Csh, 5
	LEN 18
	NOTE Dsh, 5
	NOTE E_, 5
	LEN 24
	NOTE Gsh, 5
	LEN 12
	NOTE Fsh, 5
	LEN 6
	NOTE Gsh, 5
	LEN 12
	NOTE Fsh, 5
	LEN 6
	NOTE E_, 5
	LEN 12
	NOTE Dsh, 5
	LEN 6
	NOTE E_, 5
	LEN 12
	NOTE Dsh, 5
	LEN 6
	NOTE Csh, 5
	LEN 12
	NOTE B_, 4
	INSTR 14
	LEN 18
	NOTE Ash, 4
	LEN 6
	NOTE B_, 4
	NOTE Csh, 5
	WAIT2
	NOTE B_, 4
	NOTE Ash, 4
	WAIT2
	NOTE B_, 4
	NEXT
Pat_63DE:
	INSTR 14
	LEN 30
	NOTE Gsh, 4
	LEN 6
	WAIT2
	LEN 24
	NOTE B_, 4
	LEN 6
	WAIT2
	LEN 18
	NOTE Gsh, 4
	LEN 6
	WAIT2
	LEN 12
	NOTE Ash, 4
	LEN 6
	NOTE B_, 4
	NOTE Csh, 5
	WAIT2
	NOTE B_, 4
	NOTE Ash, 4
	WAIT2
	NOTE B_, 4
	LEN 30
	NOTE Fsh, 4
	LEN 6
	WAIT2
	LEN 24
	NOTE Dsh, 5
	LEN 6
	WAIT2
	LEN 12
	NOTE B_, 4
	LEN 6
	WAIT2
	NOTE B_, 4
	LEN 12
	NOTE Ash, 4
	LEN 6
	NOTE B_, 4
	NOTE Csh, 5
	WAIT2
	NOTE B_, 4
	NOTE Ash, 4
	WAIT2
	NOTE B_, 4
	NEXT
Pat_640D:
	INSTR 14
	LEN 30
	NOTE Csh, 5
	LEN 6
	WAIT2
	LEN 24
	NOTE Gsh, 4
	LEN 6
	WAIT2
	LEN 12
	NOTE F_, 5
	LEN 6
	WAIT2
	NOTE Csh, 5
	NOTE C_, 5
	WAIT2
	NOTE Csh, 5
	NOTE Dsh, 5
	WAIT2
	NOTE Csh, 5
	NOTE C_, 5
	WAIT2
	NOTE Csh, 5
	LEN 12
	NOTE Fsh, 5
	LEN 6
	WAIT2
	LEN 12
	NOTE F_, 5
	LEN 6
	NOTE Fsh, 5
	LEN 12
	NOTE Gsh, 5
	LEN 6
	WAIT2
	LEN 12
	NOTE G_, 5
	LEN 6
	NOTE Gsh, 5
	NOTE Ash, 5
	WAIT2
	NOTE A_, 5
	NOTE Gsh, 5
	WAIT2
	NOTE Fsh, 5
	LEN 36
	WAIT2
	NEXT
DrumPat_643D:
	db DRUM_LEVEL + 13, 4, 0, 0, 9, 0, 4, DRUM_LOOP

; Song 7: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong7:
	call StopAll
	ld a, $6E
	ld [wInstrTableHi], a
	ld a, $B4
	ld [wInstrTable], a
	ld de, Song7_Ch3
	call StartMusicCh3
	ld de, Song7_Ch2
	call StartMusicCh2
	ld de, Song7_Ch1
	jp StartMusicCh1
Song7_Ch3:
	dw Pat_647C
	dw Pat_64C9
	ORDER_LOOP Song7_Ch3
Song7_Ch2:
	dw Pat_6520
	dw Pat_654B
	ORDER_LOOP Song7_Ch2
Song7_Ch1:
	dw Pat_6586
	dw Pat_65C7
	ORDER_LOOP Song7_Ch1
Pat_647C:
	CH_TRANSPOSE $0C
	INSTR 11
	LEN 18
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 4
	LEN 9
	NOTE C_, 4
	INSTR 12
	NOTE G_, 2
	INSTR 11
	LEN 18
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 11
	NOTE D_, 2
	INSTR 4
	LEN 9
	NOTE G_, 4
	INSTR 12
	NOTE D_, 2
	INSTR 11
	LEN 18
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 4
	LEN 9
	NOTE C_, 4
	INSTR 12
	NOTE G_, 2
	INSTR 11
	LEN 18
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 11
	NOTE D_, 2
	INSTR 4
	LEN 9
	NOTE G_, 4
	INSTR 12
	NOTE D_, 2
	INSTR 11
	LEN 18
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE F_, 2
	NEXT
Pat_64C9:
	INSTR 11
	LEN 18
	NOTE D_, 2
	INSTR 5
	NOTE D_, 4
	INSTR 11
	NOTE A_, 2
	INSTR 5
	LEN 9
	NOTE D_, 4
	INSTR 12
	NOTE A_, 2
	INSTR 11
	LEN 18
	NOTE G_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 11
	NOTE D_, 2
	INSTR 4
	NOTE G_, 4
	INSTR 11
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 11
	NOTE G_, 2
	INSTR 4
	LEN 9
	NOTE C_, 4
	INSTR 12
	NOTE G_, 2
	INSTR 11
	LEN 18
	NOTE A_, 2
	INSTR 5
	NOTE A_, 4
	INSTR 11
	NOTE E_, 2
	INSTR 5
	NOTE A_, 4
	INSTR 11
	NOTE D_, 3
	INSTR 4
	NOTE D_, 4
	INSTR 11
	NOTE A_, 2
	INSTR 4
	LEN 9
	NOTE D_, 4
	INSTR 12
	NOTE A_, 2
	INSTR 11
	LEN 18
	NOTE Fsh, 2
	INSTR 4
	NOTE D_, 4
	INSTR 11
	NOTE D_, 2
	INSTR 4
	LEN 9
	NOTE D_, 4
	INSTR 12
	NOTE D_, 2
	INSTR 11
	LEN 18
	NOTE G_, 2
	INSTR 4
	LEN 9
	NOTE G_, 4
	INSTR 12
	NOTE G_, 2
	INSTR 11
	LEN 18
	NOTE D_, 2
	INSTR 4
	LEN 9
	NOTE G_, 4
	INSTR 12
	NOTE D_, 2
	INSTR 11
	LEN 18
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NEXT
Pat_6520:
	INSTR 9
	LEN 9
	REPEAT 2
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE E_, 3
	REPEAT_END
	NOTE C_, 6
	NOTE E_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE E_, 3
	REPEAT 4
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE B_, 3
	REPEAT_END
	REPEAT 2
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE E_, 3
	REPEAT_END
	NOTE C_, 6
	NOTE E_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE E_, 3
	REPEAT 4
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE B_, 3
	REPEAT_END
	NEXT
Pat_654B:
	INSTR 9
	LEN 9
	REPEAT 2
	NOTE D_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE F_, 3
	REPEAT_END
	REPEAT 2
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE B_, 3
	REPEAT_END
	REPEAT 2
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE E_, 3
	REPEAT_END
	NOTE E_, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE E_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE A_, 3
	REPEAT 2
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE B_, 3
	REPEAT_END
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NEXT
Pat_6586:
	DRUMS $09, DrumPat_65F7
	INSTR 6
	LEN 36
	NOTE C_, 4
	LEN 18
	NOTE C_, 5
	INSTR 9
	NOTE C_, 5
	NOTE B_, 5
	INSTR 6
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	INSTR 9
	LEN 9
	NOTE D_, 5
	NOTE E_, 5
	LEN 18
	NOTE F_, 5
	LEN 9
	NOTE F_, 5
	NOTE G_, 5
	LEN 18
	NOTE A_, 5
	LEN 9
	NOTE F_, 5
	NOTE D_, 5
	LEN 18
	NOTE B_, 4
	NOTE G_, 4
	INSTR 6
	LEN 36
	NOTE C_, 4
	LEN 18
	NOTE C_, 5
	INSTR 9
	NOTE C_, 5
	NOTE B_, 5
	INSTR 6
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	LEN 9
	NOTE A_, 4
	NOTE B_, 4
	LEN 18
	NOTE G_, 4
	INSTR 9
	NOTE C_, 5
	LEN 9
	NOTE B_, 4
	NOTE A_, 4
	LEN 18
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	INSTR 6
	LEN 9
	NOTE G_, 4
	NOTE Gsh, 4
	NEXT
Pat_65C7:
	INSTR 6
	LEN 18
	NOTE A_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE D_, 4
	INSTR 9
	LEN 9
	NOTE D_, 5
	NOTE C_, 5
	LEN 18
	NOTE B_, 4
	INSTR 6
	LEN 9
	NOTE E_, 4
	NOTE F_, 4
	LEN 18
	NOTE G_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	LEN 36
	NOTE C_, 5
	NOTE A_, 4
	NOTE Fsh, 4
	LEN 18
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE G_, 4
	INSTR 9
	NOTE B_, 4
	LEN 9
	NOTE C_, 5
	NOTE D_, 5
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE F_, 4
	NOTE D_, 4
	NEXT
DrumPat_65F7:
	db DRUM_LEVEL + 13, 1, DRUM_LEVEL + 12, 6, DRUM_LEVEL + 13, 4, 6, 9
	db DRUM_LEVEL + 12, 6, DRUM_LEVEL + 13, 6, 4, DRUM_LOOP

; Song 8: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong8:
	call StopAll
	ld a, $6E
	ld [wInstrTableHi], a
	ld a, $B4
	ld [wInstrTable], a
	ld de, Song8_Ch3
	call StartMusicCh3
	ld de, Song8_Ch2
	call StartMusicCh2
	ld de, Song8_Ch1
	jp StartMusicCh1
Song8_Ch3:
	dw Pat_662A
Song8_Ch2:
	dw Pat_6666
Song8_Ch1:
	dw Pat_66AB
Pat_662A:
	CH_TRANSPOSE $0C
	TRANSPOSE $FE
	LEN 24
	REST
	INSTR 11
	LEN 12
	NOTE Csh, 3
	INSTR 4
	NOTE Csh, 4
	INSTR 11
	NOTE Gsh, 2
	INSTR 4
	NOTE Csh, 4
	INSTR 11
	NOTE Csh, 3
	NOTE C_, 3
	NOTE Ash, 2
	NOTE Gsh, 2
	NOTE Csh, 3
	INSTR 4
	NOTE Csh, 4
	INSTR 11
	NOTE Gsh, 2
	INSTR 4
	NOTE Csh, 4
	INSTR 11
	NOTE Dsh, 3
	NOTE C_, 3
	LEN 24
	NOTE Gsh, 2
	LEN 12
	NOTE Dsh, 3
	INSTR 4
	NOTE Gsh, 3
	INSTR 11
	NOTE D_, 3
	INSTR 4
	NOTE Gsh, 3
	INSTR 11
	NOTE Dsh, 3
	INSTR 4
	NOTE Gsh, 3
	INSTR 11
	NOTE D_, 3
	INSTR 4
	NOTE Gsh, 3
	INSTR 11
	NOTE Gsh, 2
	NOTE Ash, 2
	NOTE B_, 2
	LEN 6
	NOTE C_, 3
	LEN 24
	NOTE Csh, 3
	INSTR 11
	LEN 36
	NOTE Csh, 2
	END
Pat_6666:
	LEN 24
	WAIT
	INSTR 13
	LEN 6
	NOTE Csh, 4
	LEN 18
	WAIT2
	LEN 6
	NOTE Gsh, 3
	LEN 18
	WAIT2
	LEN 6
	NOTE Csh, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE Ash, 3
	WAIT2
	NOTE Gsh, 3
	WAIT2
	NOTE Csh, 4
	LEN 18
	WAIT2
	LEN 6
	NOTE Gsh, 3
	LEN 18
	WAIT2
	LEN 6
	NOTE Dsh, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE Gsh, 3
	LEN 6
	WAIT2
	LEN 6
	NOTE C_, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE Gsh, 3
	WAIT2
	NOTE Ash, 3
	WAIT2
	NOTE Gsh, 3
	NOTE C_, 4
	WAIT2
	NOTE C_, 4
	NOTE Gsh, 3
	WAIT2
	NOTE Ash, 3
	WAIT2
	NOTE F_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE B_, 4
	WAIT2
	NOTE C_, 5
	LEN 24
	NOTE Csh, 5
	INSTR 13
	LEN 6
	NOTE Csh, 4
	LEN 30
	WAIT2
	END
Pat_66AB:
	INSTR 13
	LEN 24
	NOTE Gsh, 5
	LEN 6
	NOTE Csh, 6
	WAIT2
	NOTE C_, 6
	WAIT2
	NOTE Ash, 5
	WAIT2
	NOTE Gsh, 5
	LEN 36
	NOTE F_, 5
	LEN 6
	WAIT2
	LEN 12
	NOTE Gsh, 5
	LEN 6
	NOTE Csh, 6
	NOTE Csh, 6
	NOTE C_, 6
	WAIT2
	NOTE Ash, 5
	WAIT2
	NOTE B_, 5
	WAIT2
	LEN 30
	NOTE C_, 6
	LEN 6
	WAIT2
	NOTE C_, 6
	WAIT2
	NOTE C_, 6
	WAIT2
	NOTE Gsh, 5
	WAIT2
	NOTE Ash, 5
	WAIT2
	NOTE Gsh, 5
	NOTE C_, 6
	WAIT2
	NOTE C_, 6
	NOTE Gsh, 5
	WAIT2
	NOTE Ash, 5
	WAIT2
	NOTE F_, 5
	NOTE F_, 5
	NOTE Gsh, 5
	WAIT2
	NOTE Ash, 5
	WAIT2
	NOTE B_, 5
	WAIT2
	NOTE C_, 6
	LEN 24
	NOTE Csh, 6
	INSTR 13
	LEN 6
	NOTE F_, 6
	LEN 30
	WAIT2
	END

; Song 9: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong9:
	call StopAll
	ld a, $6E
	ld [wInstrTableHi], a
	ld a, $B4
	ld [wInstrTable], a
	ld de, Song9_Ch3
	call StartMusicCh3
	ld de, Song9_Ch2
	call StartMusicCh2
	ld de, Song9_Ch1
	jp StartMusicCh1
Song9_Ch3:
	dw Pat_6B8B
	dw Pat_67C9
	dw Pat_67CF
	dw Pat_6834
	dw Pat_6858
	dw Pat_67C9
	dw Pat_67EF
	dw Pat_686E
	dw Pat_67DD
	dw Pat_67CF
	dw Pat_6834
	dw Pat_6858
	dw Pat_686E
	dw Pat_6B88
	dw Pat_67C9
	dw Pat_67CF
	dw Pat_6834
	dw Pat_6858
	dw Pat_67C9
	dw Pat_67EF
	dw Pat_686E
	dw Pat_67DD
	dw Pat_67CF
	dw Pat_6834
	dw Pat_6858
	dw Pat_686E
	ORDER_LOOP Song9_Ch3
Song9_Ch2:
	dw Pat_6892
	dw Pat_68B6
	dw Pat_68E3
	dw Pat_690C
	dw Pat_6892
	dw Pat_68B6
	dw Pat_6938
	dw Pat_696D
	dw Pat_69A0
	dw Pat_68E3
	dw Pat_690C
	dw Pat_6938
	ORDER_LOOP Song9_Ch2
Song9_Ch1:
	dw Pat_69D6
	dw Pat_6A4A
	dw Pat_6A5D
	dw Pat_6A90
	dw Pat_69D6
	dw Pat_6A55
	dw Pat_6AC1
	dw Pat_6AF8
	dw Pat_6B2F
	dw Pat_6A5D
	dw Pat_6A90
	dw Pat_6AC1
	ORDER_LOOP Song9_Ch1
Pat_6779:
	INSTR 11
	LEN 18
	NOTE Dsh, 2
	INSTR 12
	LEN 9
	NOTE Dsh, 3
	INSTR 4
	LEN 18
	NOTE Dsh, 4
	INSTR 11
	LEN 9
	NOTE Dsh, 2
	LEN 18
	NOTE Gsh, 2
	INSTR 12
	LEN 9
	NOTE Gsh, 3
	INSTR 4
	LEN 18
	NOTE Gsh, 4
	INSTR 11
	LEN 9
	NOTE Gsh, 2
	LEN 18
	NOTE Ash, 2
	INSTR 12
	LEN 9
	NOTE Ash, 3
	INSTR 4
	LEN 18
	NOTE Ash, 4
	INSTR 11
	LEN 9
	NOTE Ash, 2
	LEN 18
	NOTE Dsh, 2
	INSTR 12
	LEN 9
	NOTE Dsh, 3
	INSTR 4
	LEN 18
	NOTE Dsh, 4
	INSTR 11
	LEN 9
	NOTE Dsh, 2
	LEN 18
	NOTE Dsh, 2
	INSTR 12
	LEN 9
	NOTE Dsh, 3
	INSTR 4
	LEN 18
	NOTE Dsh, 4
	INSTR 11
	LEN 9
	NOTE Dsh, 2
	LEN 18
	NOTE Gsh, 2
	INSTR 12
	LEN 9
	NOTE Gsh, 3
	INSTR 4
	LEN 18
	NOTE Gsh, 4
	INSTR 11
	LEN 9
	NOTE Gsh, 2
	LEN 18
	NOTE Ash, 2
	INSTR 12
	LEN 9
	NOTE Ash, 3
	INSTR 4
	LEN 18
	NOTE Ash, 4
	INSTR 11
	LEN 9
	NOTE Ash, 2
	LEN 18
	NEXT
Pat_67C9:
	DRUMS $09, DrumPat_55BA
	CH_TRANSPOSE $0C
Pat_67CF:
	PAT_CALL Pat_6779
	NOTE Dsh, 2
	INSTR 12
	LEN 9
	NOTE Dsh, 3
	INSTR 4
	LEN 18
	NOTE Dsh, 4
	INSTR 11
	LEN 9
	NOTE Dsh, 2
	NEXT
Pat_67DD:
	DRUMS $09, DrumPat_55BA
	PAT_CALL Pat_6779
	NOTE Ash, 1
	INSTR 12
	LEN 9
	NOTE Ash, 2
	INSTR 4
	LEN 18
	NOTE Ash, 3
	INSTR 11
	LEN 9
	NOTE Ash, 2
	NEXT
Pat_67EF:
	PAT_CALL Pat_6779
	NOTE Dsh, 2
	INSTR 12
	LEN 9
	NOTE Dsh, 3
	INSTR 4
	LEN 27
	NOTE Dsh, 4
	NEXT
Pat_67FA:
	INSTR 11
	LEN 18
	NOTE Ash, 1
	INSTR 12
	LEN 9
	NOTE Ash, 2
	INSTR 4
	LEN 18
	NOTE Ash, 3
	INSTR 11
	LEN 9
	NOTE Ash, 1
	LEN 18
	NOTE Ash, 1
	INSTR 12
	LEN 9
	NOTE Ash, 2
	INSTR 4
	LEN 18
	NOTE Ash, 3
	INSTR 11
	LEN 9
	NOTE Ash, 1
	LEN 18
	NOTE Dsh, 2
	INSTR 12
	LEN 9
	NOTE Dsh, 3
	INSTR 4
	LEN 18
	NOTE Dsh, 4
	INSTR 11
	LEN 9
	NOTE Dsh, 2
	LEN 18
	NOTE Dsh, 2
	INSTR 12
	LEN 9
	NOTE Dsh, 3
	INSTR 4
	LEN 18
	NOTE Dsh, 4
	INSTR 11
	LEN 9
	NOTE Dsh, 2
	LEN 18
	NOTE F_, 2
	INSTR 12
	LEN 9
	NOTE F_, 3
	INSTR 5
	LEN 18
	NOTE F_, 4
	INSTR 11
	LEN 9
	NOTE F_, 2
	LEN 18
	NEXT
Pat_6834:
	PAT_CALL Pat_67FA
	NOTE C_, 2
	INSTR 12
	LEN 9
	NOTE C_, 3
	INSTR 5
	LEN 18
	NOTE F_, 4
	INSTR 11
	LEN 9
	NOTE C_, 2
	LEN 18
	NOTE Ash, 1
	INSTR 12
	LEN 9
	NOTE Ash, 2
	INSTR 4
	LEN 18
	NOTE Ash, 3
	INSTR 11
	LEN 9
	NOTE Ash, 1
	LEN 18
	NOTE Ash, 2
	INSTR 12
	LEN 9
	NOTE Ash, 3
	INSTR 4
	LEN 18
	NOTE Ash, 3
	INSTR 11
	LEN 9
	NOTE Ash, 2
	NEXT
Pat_6858:
	PAT_CALL Pat_67FA
	NOTE Ash, 2
	INSTR 12
	LEN 9
	NOTE Ash, 3
	INSTR 5
	LEN 18
	NOTE F_, 4
	INSTR 11
	LEN 9
	NOTE Ash, 1
	LEN 27
	NOTE Dsh, 2
	NOTE Ash, 2
	NOTE Dsh, 2
	LEN 9
	NOTE Ash, 1
	NOTE C_, 2
	NOTE D_, 2
	NEXT
Pat_686E:
	DRUMS $09, DrumPat_6B67
	INSTR 11
	LENGTH $36
	NOTE Ash, 1
	NOTE Ash, 1
	NOTE Ash, 1
	LEN 27
	NOTE Ash, 1
	LEN 18
	NOTE Ash, 1
	LEN 9
	NOTE Ash, 1
	LEN 45
	NOTE Ash, 2
	LEN 9
	NOTE F_, 2
	LEN 45
	NOTE Ash, 2
	LEN 9
	NOTE F_, 2
	LEN 27
	NOTE Ash, 2
	NOTE F_, 2
	LEN 18
	NOTE Ash, 2
	LEN 9
	NOTE Gsh, 2
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE F_, 2
	NEXT
Pat_6892:
	INSTR 13
	LENGTH $36
	NOTE G_, 4
	LEN 45
	NOTE Gsh, 4
	LEN 9
	NOTE G_, 4
	NOTE F_, 4
	WAIT2
	NOTE Dsh, 4
	NOTE F_, 4
	WAIT2
	LENGTH $36
	NOTE G_, 4
	LEN 9
	WAIT2
	LENGTH $36
	NOTE G_, 4
	LEN 45
	NOTE Gsh, 4
	LEN 9
	NOTE G_, 4
	NOTE F_, 4
	WAIT2
	NOTE Dsh, 4
	NOTE D_, 4
	WAIT2
	LENGTH $36
	NOTE Dsh, 4
	LEN 9
	WAIT2
	NEXT
Pat_68B6:
	INSTR 13
	LEN 45
	NOTE G_, 4
	LEN 9
	NOTE Ash, 4
	LEN 45
	NOTE Gsh, 4
	LEN 9
	NOTE C_, 5
	NOTE Ash, 4
	WAIT2
	NOTE F_, 4
	NOTE Ash, 4
	WAIT2
	NOTE Gsh, 4
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE Gsh, 4
	LEN 18
	NOTE Ash, 4
	LEN 9
	WAIT2
	LEN 45
	NOTE Dsh, 5
	LEN 9
	NOTE D_, 5
	LEN 36
	NOTE C_, 5
	LEN 9
	WAIT2
	NOTE Dsh, 5
	NOTE D_, 5
	WAIT2
	NOTE Ash, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	WAIT2
	NOTE G_, 4
	NOTE Dsh, 4
	LEN 18
	WAIT2
	NEXT
Pat_68E3:
	INSTR 13
	LEN 27
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 9
	NOTE F_, 4
	WAIT2
	NOTE Ash, 3
	LEN 27
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 9
	NOTE Dsh, 4
	WAIT2
	NOTE Ash, 3
	LEN 27
	NOTE C_, 5
	NOTE Ash, 4
	LEN 18
	NOTE Gsh, 4
	LEN 9
	NOTE G_, 4
	NOTE F_, 4
	WAIT2
	NOTE Dsh, 4
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 18
	WAIT2
	LEN 27
	NOTE Ash, 4
	LEN 9
	NOTE F_, 4
	NOTE D_, 4
	NOTE Ash, 3
	NEXT
Pat_690C:
	INSTR 13
	LEN 27
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 9
	NOTE F_, 4
	WAIT2
	NOTE Ash, 3
	LEN 18
	NOTE C_, 5
	LEN 9
	NOTE Ash, 4
	LEN 18
	NOTE A_, 4
	NOTE Ash, 4
	LEN 9
	WAIT2
	NOTE G_, 4
	NOTE Gsh, 4
	WAIT2
	NOTE Ash, 4
	LEN 27
	NOTE C_, 5
	NOTE Gsh, 4
	LEN 9
	NOTE F_, 4
	WAIT2
	NOTE D_, 4
	NOTE Ash, 3
	NOTE G_, 4
	NOTE F_, 4
	LEN 18
	NOTE Dsh, 4
	LEN 9
	WAIT2
	LEN 18
	NOTE Ash, 4
	LEN 9
	WAIT2
	LEN 27
	NOTE Dsh, 4
	WAIT2
	NEXT
Pat_6938:
	INSTR 9
	LEN 9
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE G_, 3
	LEN 18
	NOTE Gsh, 3
	LEN 9
	NOTE G_, 3
	LEN 27
	NOTE F_, 3
	NOTE Ash, 2
	INSTR 14
	LEN 9
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	LEN 18
	NOTE D_, 5
	LEN 9
	WAIT2
	LEN 18
	NOTE F_, 5
	LEN 9
	WAIT2
	NEXT
Pat_696D:
	INSTR 9
	LEN 9
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE Ash, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE Ash, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE Ash, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE Ash, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE Ash, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE Ash, 4
	NOTE D_, 5
	NOTE F_, 5
	NEXT
Pat_69A0:
	INSTR 9
	LEN 9
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE D_, 5
	LEN 18
	NOTE C_, 5
	LEN 9
	NOTE D_, 5
	LEN 18
	NOTE C_, 5
	LEN 9
	NOTE Ash, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE Dsh, 5
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Dsh, 5
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE D_, 5
	LEN 18
	NOTE C_, 5
	LEN 9
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NEXT
Pat_69D6:
	INSTR 7
	LEN 9
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE Ash, 5
	LEN 18
	NOTE Dsh, 6
	LEN 9
	NOTE Ash, 5
	LEN 18
	NOTE C_, 6
	LEN 9
	NOTE Gsh, 5
	LEN 18
	NOTE F_, 5
	LEN 9
	NOTE C_, 6
	LEN 18
	NOTE Ash, 5
	LEN 9
	NOTE F_, 5
	LEN 18
	NOTE D_, 5
	LEN 9
	NOTE F_, 5
	LEN 18
	NOTE G_, 5
	LEN 9
	NOTE Gsh, 5
	LEN 27
	NOTE Ash, 5
	LEN 9
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE Ash, 5
	LEN 18
	NOTE Dsh, 6
	LEN 9
	NOTE Ash, 5
	LEN 18
	NOTE C_, 6
	LEN 9
	NOTE Gsh, 5
	LEN 18
	NOTE F_, 5
	LEN 9
	NOTE C_, 6
	LEN 18
	NOTE Ash, 5
	LEN 9
	NOTE F_, 5
	LEN 18
	NOTE D_, 5
	LEN 9
	NOTE F_, 5
	LEN 18
	NOTE G_, 5
	LEN 9
	NOTE F_, 5
	LEN 27
	NOTE Dsh, 5
	NEXT
Pat_6A14:
	LEN 9
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE Ash, 5
	LEN 18
	NOTE Dsh, 6
	LEN 9
	NOTE Ash, 5
	LEN 18
	NOTE C_, 6
	LEN 9
	NOTE Gsh, 5
	LEN 18
	NOTE F_, 5
	LEN 9
	NOTE C_, 6
	LEN 18
	NOTE Ash, 5
	LEN 9
	NOTE F_, 5
	LEN 18
	NOTE D_, 5
	LEN 9
	NOTE F_, 5
	LEN 18
	NOTE G_, 5
	LEN 9
	NOTE Gsh, 5
	LEN 27
	NOTE Ash, 5
	LEN 9
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE Ash, 5
	LEN 18
	NOTE Dsh, 6
	LEN 9
	NOTE Ash, 5
	LEN 18
	NOTE C_, 6
	LEN 9
	NOTE Gsh, 5
	LEN 18
	NOTE F_, 5
	LEN 9
	NOTE C_, 6
	LEN 18
	NOTE Ash, 5
	LEN 9
	NOTE F_, 5
	NOTE Ash, 4
	NOTE G_, 5
	NOTE F_, 5
	NEXT
Pat_6A4A:
	INSTR 7
	PAT_CALL Pat_6A14
	LEN 36
	NOTE Dsh, 5
	LEN 9
	DUTY_75
	NOTE D_, 5
	NOTE Dsh, 5
	NEXT
Pat_6A55:
	ARP 20
	PAT_CALL Pat_6A14
	LENGTH $36
	NOTE Dsh, 5
	NEXT
Pat_6A5D:
	LEN 18
	NOTE F_, 5
	LEN 9
	NOTE F_, 5
	LEN 18
	NOTE F_, 5
	LEN 9
	NOTE F_, 5
	LEN 36
	NOTE F_, 5
	LEN 9
	NOTE Dsh, 5
	NOTE F_, 5
	LEN 18
	NOTE G_, 5
	LEN 9
	NOTE G_, 5
	LEN 18
	NOTE G_, 5
	LEN 9
	NOTE G_, 5
	LEN 36
	NOTE G_, 5
	LEN 9
	NOTE F_, 5
	NOTE G_, 5
	LEN 18
	NOTE Gsh, 5
	LEN 9
	NOTE Gsh, 5
	LEN 18
	NOTE Gsh, 5
	LEN 9
	NOTE G_, 5
	LEN 18
	NOTE F_, 5
	LEN 9
	NOTE Dsh, 5
	LEN 18
	NOTE D_, 5
	LEN 9
	NOTE Dsh, 5
	LEN 27
	NOTE F_, 5
	NOTE Ash, 4
	NOTE Ash, 5
	LEN 9
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE Dsh, 5
	NEXT
Pat_6A90:
	LEN 18
	NOTE F_, 5
	LEN 9
	NOTE F_, 5
	LEN 18
	NOTE F_, 5
	LEN 9
	NOTE F_, 5
	LEN 36
	NOTE F_, 5
	LEN 9
	NOTE Dsh, 5
	NOTE F_, 5
	LEN 18
	NOTE G_, 5
	LEN 9
	NOTE G_, 5
	LEN 18
	NOTE G_, 5
	LEN 9
	NOTE G_, 5
	LEN 36
	NOTE G_, 5
	LEN 9
	NOTE F_, 5
	NOTE G_, 5
	LEN 18
	NOTE Gsh, 5
	LEN 9
	NOTE G_, 5
	LEN 18
	NOTE F_, 5
	LEN 9
	NOTE Dsh, 5
	LEN 18
	NOTE D_, 5
	LEN 9
	NOTE Dsh, 5
	LEN 18
	NOTE F_, 5
	LEN 9
	NOTE D_, 5
	LEN 27
	NOTE Dsh, 5
	NOTE G_, 5
	LENGTH $36
	NOTE Dsh, 5
	NEXT
Pat_6AC1:
	INSTR 14
	LEN 9
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	WAIT2
	NOTE G_, 4
	LEN 18
	NOTE F_, 4
	LEN 9
	WAIT2
	LEN 18
	NOTE Ash, 3
	LEN 9
	WAIT2
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 18
	NOTE Ash, 4
	LEN 9
	WAIT2
	LEN 18
	NOTE D_, 5
	LEN 9
	WAIT2
	NEXT
Pat_6AF8:
	INSTR 14
	LEN 27
	NOTE Dsh, 5
	LEN 9
	WAIT2
	NOTE F_, 5
	NOTE G_, 5
	LEN 27
	NOTE Gsh, 5
	LEN 9
	NOTE Ash, 5
	WAIT2
	NOTE C_, 6
	NOTE Ash, 5
	NOTE C_, 6
	NOTE Ash, 5
	LEN 18
	NOTE Gsh, 5
	LEN 9
	NOTE Ash, 5
	NOTE Gsh, 5
	WAIT2
	NOTE G_, 5
	LEN 18
	NOTE Dsh, 5
	LEN 9
	NOTE F_, 5
	LEN 18
	NOTE G_, 5
	LEN 9
	WAIT2
	LEN 18
	NOTE G_, 5
	LEN 9
	WAIT2
	LEN 18
	NOTE Gsh, 5
	LEN 9
	NOTE G_, 5
	NOTE F_, 5
	WAIT2
	NOTE Dsh, 5
	LEN 27
	NOTE F_, 5
	LEN 9
	NOTE C_, 6
	WAIT2
	LEN 27
	NOTE Ash, 5
	LEN 9
	NOTE F_, 5
	NOTE Ash, 4
	NOTE C_, 5
	NOTE D_, 5
	NEXT
Pat_6B2F:
	INSTR 14
	LEN 27
	NOTE Dsh, 5
	LEN 9
	WAIT2
	NOTE F_, 5
	NOTE G_, 5
	LEN 27
	NOTE Gsh, 5
	LEN 9
	NOTE Ash, 5
	WAIT2
	NOTE C_, 6
	NOTE Ash, 5
	NOTE C_, 6
	NOTE Ash, 5
	LEN 18
	NOTE Gsh, 5
	LEN 9
	NOTE Ash, 5
	NOTE Gsh, 5
	WAIT2
	NOTE G_, 5
	LEN 18
	NOTE Dsh, 5
	LEN 9
	NOTE F_, 5
	LEN 18
	NOTE G_, 5
	LEN 9
	WAIT2
	LEN 18
	NOTE G_, 5
	LEN 9
	WAIT2
	LEN 18
	NOTE Gsh, 5
	LEN 9
	NOTE G_, 5
	NOTE F_, 5
	WAIT2
	NOTE Dsh, 5
	LEN 27
	NOTE F_, 5
	LEN 9
	NOTE F_, 5
	WAIT2
	LEN 36
	NOTE Dsh, 5
	LEN 9
	WAIT2
	INSTR 7
	DUTY_75
	NOTE D_, 5
	NOTE Dsh, 5
	NEXT
DrumPat_6B67:
	db DRUM_LEVEL + 14, DRUM_REPEAT + 2, 9, 0, 9, DRUM_TEMPO + 4, 10, DRUM_TEMPO + 5
	db 10, DRUM_TEMPO + 9, 10, 10, DRUM_REPEAT_END, 9, 10, 10
	db 9, 0, 10, 9, 0, 9, DRUM_TEMPO + 4, 10
	db DRUM_TEMPO + 5, 10, DRUM_TEMPO + 9, 10, 10, DRUM_LOOP
Pat_6B85:
	TRANSPOSE $02
	NEXT
Pat_6B88:
	TRANSPOSE $01
	NEXT
Pat_6B8B:
	TRANSPOSE $00
	NEXT

; Song 1: instrument table 1, arpeggio table 1 (the one SndInit sets)
; API song slots 1, 10, 11, 12 all start this routine
PlaySong1:
	call StopAll
	ld a, $6E
	ld [wInstrTableHi], a
	ld a, $B4
	ld [wInstrTable], a
	ld de, Song1_Ch3
	call StartMusicCh3
	ld de, Song1_Ch2
	call StartMusicCh2
	ld de, Song1_Ch1
	jp StartMusicCh1
Song1_Ch3:
	dw Pat_6BE9
	dw Pat_6C47
	dw Pat_6BE9
	dw Pat_6C47
	dw Pat_6C9D
	dw Pat_6C9D
	dw Pat_6CEF
	dw Pat_6C9D
	ORDER_LOOP Song1_Ch3
Song1_Ch2:
	dw Pat_6D41
	dw Pat_6D7B
	dw Pat_6D41
	dw Pat_6D7B
	dw Pat_6DA8
	dw Pat_6DA8
	dw Pat_6DD1
	dw Pat_6DA8
	ORDER_LOOP Song1_Ch2
Song1_Ch1:
	dw Pat_6DFC
	dw Pat_6E31
	dw Pat_6DFC
	dw Pat_6E31
	dw Pat_6E67
	dw Pat_6E67
	dw Pat_6E8B
	dw Pat_6E67
	ORDER_LOOP Song1_Ch1
Pat_6BE9:
	CH_TRANSPOSE $0C
	DRUMS $09, DrumPat_6EAF
	INSTR 11
	LEN 18
	NOTE C_, 2
	INSTR 5
	LEN 9
	NOTE C_, 4
	INSTR 11
	LEN 18
	NOTE C_, 3
	INSTR 12
	LEN 9
	NOTE C_, 4
	INSTR 11
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	INSTR 11
	LEN 18
	NOTE Dsh, 2
	LEN 9
	NOTE D_, 2
	LEN 18
	NOTE C_, 2
	INSTR 5
	LEN 9
	NOTE C_, 4
	INSTR 11
	LEN 18
	NOTE D_, 2
	INSTR 12
	LEN 9
	NOTE D_, 3
	INSTR 11
	LEN 18
	NOTE Dsh, 2
	INSTR 12
	LEN 9
	NOTE Dsh, 3
	INSTR 11
	LEN 18
	NOTE F_, 2
	LEN 9
	NOTE Fsh, 2
	LEN 18
	NOTE G_, 2
	INSTR 4
	LEN 9
	NOTE G_, 4
	INSTR 11
	LEN 18
	NOTE G_, 3
	INSTR 12
	LEN 9
	NOTE G_, 4
	INSTR 11
	LEN 18
	NOTE D_, 3
	INSTR 12
	LEN 9
	NOTE D_, 4
	INSTR 11
	LEN 18
	NOTE B_, 2
	LEN 9
	NOTE Gsh, 2
	LEN 18
	NOTE G_, 2
	INSTR 4
	LEN 9
	NOTE G_, 4
	INSTR 11
	LEN 18
	NOTE Gsh, 2
	INSTR 12
	LEN 9
	NOTE Gsh, 3
	INSTR 11
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE Gsh, 2
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE Fsh, 2
	NEXT
Pat_6C47:
	INSTR 11
	LEN 18
	NOTE F_, 2
	INSTR 5
	LEN 9
	NOTE F_, 4
	INSTR 11
	LEN 18
	NOTE F_, 3
	INSTR 12
	LEN 9
	NOTE F_, 4
	INSTR 11
	LEN 18
	NOTE C_, 3
	INSTR 12
	LEN 9
	NOTE C_, 4
	INSTR 11
	LEN 18
	NOTE Gsh, 2
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE F_, 2
	INSTR 5
	LEN 9
	NOTE F_, 4
	INSTR 11
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	INSTR 11
	LEN 18
	NOTE Gsh, 2
	INSTR 12
	LEN 9
	NOTE Gsh, 3
	INSTR 11
	LEN 18
	NOTE C_, 3
	INSTR 12
	LEN 9
	NOTE C_, 4
	INSTR 11
	LEN 18
	NOTE Fsh, 2
	LEN 9
	NOTE G_, 2
	INSTR 4
	LEN 18
	NOTE G_, 4
	INSTR 11
	LEN 9
	NOTE Fsh, 2
	LEN 18
	NOTE G_, 2
	INSTR 4
	LEN 9
	NOTE G_, 4
	INSTR 11
	LEN 18
	NOTE Fsh, 2
	LEN 9
	NOTE G_, 2
	INSTR 4
	LEN 18
	NOTE G_, 4
	INSTR 11
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE Fsh, 2
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE Gsh, 2
	LEN 9
	NOTE A_, 2
	LEN 18
	NOTE Ash, 2
	LEN 9
	NOTE B_, 2
	NEXT
Pat_6C9D:
	INSTR 11
	LEN 18
	NOTE C_, 2
	INSTR 5
	LEN 9
	NOTE C_, 4
	INSTR 11
	LEN 18
	NOTE C_, 3
	INSTR 12
	LEN 9
	NOTE C_, 4
	INSTR 11
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	INSTR 11
	LEN 18
	NOTE Dsh, 2
	LEN 27
	NOTE D_, 2
	INSTR 4
	LEN 9
	NOTE D_, 4
	INSTR 11
	LEN 18
	NOTE D_, 3
	LEN 9
	NOTE D_, 2
	LEN 18
	NOTE Csh, 2
	INSTR 4
	LEN 9
	NOTE Csh, 4
	INSTR 11
	LEN 18
	NOTE Csh, 2
	LEN 9
	NOTE Csh, 3
	LEN 18
	NOTE C_, 2
	INSTR 5
	LEN 9
	NOTE C_, 4
	INSTR 11
	LEN 18
	NOTE D_, 2
	INSTR 12
	LEN 9
	NOTE D_, 3
	INSTR 11
	LEN 18
	NOTE Dsh, 2
	INSTR 12
	LEN 9
	NOTE Dsh, 3
	INSTR 11
	LEN 18
	NOTE C_, 2
	INSTR 12
	LEN 9
	NOTE C_, 3
	INSTR 11
	LEN 18
	NOTE G_, 2
	INSTR 5
	LEN 9
	NOTE G_, 4
	INSTR 11
	LEN 27
	NOTE A_, 2
	LEN 18
	NOTE Ash, 2
	LEN 9
	NOTE Fsh, 2
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE Dsh, 2
	NEXT
Pat_6CEF:
	INSTR 11
	LEN 18
	NOTE F_, 2
	INSTR 5
	LEN 9
	NOTE F_, 4
	INSTR 11
	LEN 18
	NOTE F_, 3
	INSTR 12
	LEN 9
	NOTE F_, 4
	INSTR 11
	LEN 18
	NOTE C_, 3
	INSTR 12
	LEN 9
	NOTE C_, 4
	INSTR 11
	LEN 18
	NOTE Gsh, 2
	LEN 27
	NOTE G_, 2
	INSTR 4
	LEN 9
	NOTE G_, 4
	INSTR 11
	LEN 18
	NOTE G_, 3
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE Fsh, 2
	INSTR 4
	LEN 9
	NOTE Fsh, 4
	INSTR 11
	LEN 18
	NOTE Fsh, 2
	LEN 9
	NOTE Fsh, 3
	LEN 18
	NOTE F_, 2
	INSTR 5
	LEN 9
	NOTE F_, 4
	INSTR 11
	LEN 18
	NOTE G_, 2
	INSTR 12
	LEN 9
	NOTE G_, 3
	INSTR 11
	LEN 18
	NOTE Gsh, 2
	INSTR 12
	LEN 9
	NOTE Gsh, 3
	INSTR 11
	LEN 18
	NOTE F_, 2
	INSTR 12
	LEN 9
	NOTE F_, 3
	INSTR 11
	LEN 18
	NOTE C_, 3
	INSTR 5
	LEN 9
	NOTE C_, 5
	INSTR 11
	LEN 27
	NOTE D_, 3
	LEN 18
	NOTE Dsh, 3
	LEN 9
	NOTE B_, 2
	LEN 18
	NOTE C_, 3
	LEN 9
	NOTE Gsh, 2
	NEXT
Pat_6D41:
	INSTR 6
	LEN 18
	NOTE D_, 4
	LEN 27
	NOTE Dsh, 4
	LEN 9
	NOTE D_, 4
	LEN 18
	NOTE Dsh, 4
	LEN 9
	NOTE G_, 4
	LEN 18
	NOTE Fsh, 4
	LEN 9
	NOTE G_, 4
	LEN 27
	NOTE C_, 5
	LEN 18
	NOTE D_, 5
	LEN 9
	NOTE G_, 4
	LEN 18
	NOTE Dsh, 5
	LEN 9
	NOTE D_, 5
	LEN 18
	NOTE C_, 5
	LEN 9
	NOTE G_, 4
	LEN 18
	NOTE Csh, 4
	LEN 27
	NOTE D_, 4
	LEN 9
	NOTE Csh, 4
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE Gsh, 4
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE F_, 4
	LEN 18
	NOTE D_, 4
	LEN 27
	NOTE B_, 3
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE Gsh, 3
	LEN 9
	NOTE G_, 3
	NEXT
Pat_6D7B:
	INSTR 6
	LEN 18
	NOTE E_, 4
	LEN 27
	NOTE F_, 4
	LEN 9
	NOTE E_, 4
	LEN 18
	NOTE F_, 4
	LEN 9
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE F_, 5
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE F_, 5
	LEN 18
	NOTE G_, 5
	LEN 9
	NOTE Gsh, 5
	LENGTH $7E
	NOTE G_, 5
	LEN 9
	NOTE G_, 4
	LEN 18
	NOTE Fsh, 4
	LEN 9
	NOTE G_, 4
	LEN 18
	NOTE Gsh, 4
	LEN 9
	NOTE A_, 4
	LEN 18
	NOTE Ash, 4
	LEN 9
	NOTE B_, 4
	NEXT
Pat_6DA8:
	INSTR 6
	LEN 18
	NOTE Dsh, 4
	LEN 9
	NOTE G_, 3
	INSTR 9
	LEN 18
	NOTE G_, 5
	LEN 36
	NOTE C_, 5
	INSTR 13
	LEN 9
	NOTE Ash, 4
	WAIT2
	LEN 45
	NOTE A_, 4
	LEN 9
	WAIT2
	NOTE D_, 4
	LEN 27
	NOTE Gsh, 4
	LEN 18
	WAIT2
	LEN 27
	NOTE G_, 4
	LEN 9
	WAIT2
	INSTR 6
	LEN 27
	NOTE G_, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	LEN 18
	NOTE G_, 4
	LEN 27
	NOTE Fsh, 4
	NOTE F_, 4
	LEN 9
	NOTE Csh, 4
	NEXT
Pat_6DD1:
	INSTR 6
	LEN 18
	NOTE Gsh, 4
	LEN 9
	NOTE C_, 4
	INSTR 9
	LEN 18
	NOTE C_, 6
	LEN 36
	NOTE F_, 5
	INSTR 13
	LEN 9
	NOTE Dsh, 5
	WAIT2
	LEN 45
	NOTE D_, 5
	LEN 9
	WAIT2
	NOTE G_, 4
	LEN 18
	NOTE Csh, 5
	LEN 9
	NOTE Ash, 4
	NOTE Csh, 5
	NOTE Dsh, 5
	LEN 27
	NOTE C_, 5
	LEN 9
	WAIT2
	INSTR 6
	LEN 27
	NOTE C_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	LEN 18
	NOTE C_, 5
	LEN 27
	NOTE B_, 4
	NOTE Ash, 4
	LEN 9
	NOTE Fsh, 4
	NEXT
Pat_6DFC:
	INSTR 6
	LEN 18
	NOTE Fsh, 4
	LEN 27
	NOTE G_, 4
	LEN 9
	NOTE Fsh, 4
	LEN 27
	NOTE G_, 4
	INSTR 9
	LEN 9
	NOTE G_, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE G_, 5
	INSTR 6
	LEN 18
	NOTE Fsh, 4
	LEN 27
	NOTE G_, 4
	LEN 9
	NOTE Fsh, 4
	LEN 27
	NOTE G_, 4
	INSTR 9
	LEN 9
	NOTE G_, 5
	NOTE D_, 5
	NOTE B_, 4
	NOTE D_, 5
	NOTE B_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 3
	NEXT
Pat_6E31:
	INSTR 6
	LEN 18
	NOTE G_, 4
	LEN 27
	NOTE Gsh, 4
	LEN 9
	NOTE G_, 4
	LEN 27
	NOTE Gsh, 4
	INSTR 9
	LEN 9
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE C_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE F_, 5
	INSTR 6
	LEN 18
	NOTE Fsh, 3
	LEN 27
	NOTE G_, 3
	LEN 9
	NOTE Fsh, 3
	LEN 27
	NOTE G_, 3
	LEN 18
	NOTE Fsh, 3
	LEN 27
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE Fsh, 3
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE Gsh, 3
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE Ash, 3
	LEN 9
	NOTE B_, 3
	NEXT
Pat_6E67:
	INSTR 6
	LEN 18
	NOTE G_, 4
	LEN 36
	NOTE C_, 4
	LEN 9
	NOTE G_, 3
	NOTE C_, 4
	NOTE Dsh, 4
	LEN 18
	NOTE G_, 4
	LENGTH $3F
	NOTE Fsh, 4
	LEN 18
	NOTE F_, 4
	LEN 9
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE Ash, 3
	LEN 27
	NOTE C_, 4
	LEN 9
	NOTE G_, 3
	LEN 27
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	LEN 18
	NOTE Ash, 4
	LEN 27
	NOTE A_, 4
	LEN 36
	NOTE Gsh, 4
	NEXT
Pat_6E8B:
	INSTR 6
	LEN 18
	NOTE C_, 5
	LEN 36
	NOTE F_, 4
	LEN 9
	NOTE C_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	LEN 18
	NOTE C_, 5
	LENGTH $3F
	NOTE B_, 4
	LEN 18
	NOTE Ash, 4
	LEN 9
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 27
	NOTE F_, 4
	LEN 9
	NOTE C_, 4
	LEN 27
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Dsh, 5
	LEN 18
	NOTE Dsh, 5
	LEN 27
	NOTE D_, 5
	LEN 36
	NOTE Csh, 5
	NEXT
DrumPat_6EAF:
	db 1, 0, 6, 4, 0, 6, DRUM_LOOP

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
	dw Instr1_13
	dw Instr1_14
Instr1_0:
	HWENV $F3, $00
	DUTY_75
	END
Instr1_1:
	VOLENV 15, $11, $1F, $11
	ARP 18
	WAVE Wave_78A8
	END
Instr1_2:
	HWENV $F2, $04, $75
	DUTY_50
	ARP 0
	END
Instr1_3:
	HWENV $C2, $04, $72
	DUTY_75
	ARP 12
	END
Instr1_4:
	VOLENV 13, $11, $18, $11
	ARP 4
	WAVE Wave_7918
	END
Instr1_5:
	VOLENV 13, $11, $18, $11
	ARP 5
	WAVE Wave_7918
	END
Instr1_7:
	HWENV $E1, $08, $47
	RELEASE $00
	VIBRATO $09, $01, $04
	DUTY_50
	END
Instr1_6:
	HWENV $E1, $08, $57
	RELEASE $00
	VIBRATO $08, $01, $02
	DUTY_75
	END
Instr1_8:
	HWENV $B1, $00
	ARP 0
	END
Instr1_9:
	HWENV $91, $04, $44
	DUTY_12
	RELEASE $00
	END
Instr1_10:
	VOLENV 15, $11, $1F, $1F
	ARP 1
	WAVE Wave_78D8
	END
Instr1_11:
	VOLENV 15, $11, $1F, $12
	ARP 1
	WAVE Wave_78D8
	END
Instr1_12:
	VOLENV 11, $11, $1F, $11
	ARP_OFF
	WAVE Wave_7898
	END
Instr1_13:
	HWENV $49, $04, $A0
	DUTY_50
	RELEASE $01, $72
	VIBRATO $12, $02, $04
	END
Instr1_14:
	HWENV $69, $02, $B0
	DUTY_75
	RELEASE $01, $72
	VIBRATO $09, $02, $04
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
	dw Arp13
	dw Arp13
	dw Arp16
	dw Arp17
	dw Arp18
	dw Arp19
	dw Arp19

; Unreferenced (14 bytes)
	db $34, $70, $34, $70, $34, $70, $34, $70, $34, $70, $34, $70, $34, $70
Arp0:
	db $0C, $00, ARP_HOLD
Arp3:
	db $00, $01, $01, $01, $02, ARP_HOLD
Arp2:
	db $00, $00, $04, $04, $07, $07, ARP_LOOP
Arp1:
	db $18, $0C, $00, ARP_HOLD
Arp4:
	db $00, $00, $04, $04, $07, $07, ARP_LOOP
Arp5:
	db $00, $00, $03, $03, $07, $07, ARP_LOOP
Arp6:
	db $00, $04, $07, ARP_LOOP
Arp7:
	db $F4, $00, ARP_HOLD
Arp8:
	db $01, $00, $02, $01, $03, $01, $00, ARP_LOOP
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

; Unreferenced (63 bytes)
	db $12, $00, $00, $00, $00, $00, $00, $00, $00, $0C, $00, $00, $00, $00, $00, $00
	db $00, $00, $06, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $6A, $72, $70, $72, $70, $72, $70, $72, $70, $72, $70, $72, $70, $72, $70
	db $72, $70, $72, $70, $72, $70, $72, $70, $72, $70, $72, $70, $72
SfxTable_m2:
	db $70, $68

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
	dw Sfx23
	dw Sfx31
	dw Sfx32
	dw Sfx33
	dw Sfx34
	dw Sfx02
	dw Sfx03
	dw Sfx37
	dw Sfx38
	dw Sfx39
	dw Sfx40
	dw Sfx41
	dw Sfx42
	dw Sfx08
	dw Sfx44
	dw Sfx45
	dw Sfx40
	dw Sfx03
	dw Sfx02
	dw Sfx37
	dw Sfx50
	dw Sfx51
	dw Sfx52
	dw Sfx23
	dw Sfx54
	dw Sfx01
	dw Sfx56

; Sound effect 29
Sfx29:
	WAVE Wave_7848
	VOLENV 15, $11, $5F, $11
	LEN 4
	NOTE A_, 5
	NOTE A_, 6
	NOTE A_, 5
	NOTE A_, 6
	END

; Sound effect 27
Sfx27:
	WAVE Wave_78C8
	VOLENV 15, $11, $1F, $14
	VIBRATO $00, $0C, $04
	CALL_CODE Code_77FF
	LEN 40
	NOTE C_, 4
	END

; Sound effect 18
Sfx18:
	WAVE Wave_7838
	VOLENV 5, $1F, $00, $20
	CALL_CODE Code_74D4
	LEN 21
	NOTE Gsh, 3
	END

; Sound effect 24
Sfx24:
	WAVE Wave_7828
	VOLENV 15, $11, $1F, $12
	GLIDE $03
	LEN 6
	NOTE C_, 5
	END

; Sound effect 19
Sfx19:
	VOLENV 15, $11, $1F, $11
	WAVE Wave_7828
	GLIDE $FE
	LEN 8
	NOTE B_, 7
	NOTE B_, 7
	NOTE B_, 7
	VOLENV 12, $11, $1F, $11
	NOTE B_, 7
	NOTE B_, 7
	NOTE B_, 7
	VOLENV 8, $11, $1F, $11
	NOTE B_, 7
	NOTE B_, 7
	NOTE B_, 7
	END

; Sound effect 14
Sfx14:
	VOLENV 15, $11, $1F, $16
	WAVE Wave_7848
	CALL_CODE Drum5
	GLIDE $03
	LEN 6
	NOTE G_, 5
	REST
	LEN 6
	WAVE Wave_7938
	GLIDE $03
	NOTE F_, 5
	LEN 1
	GLIDE $01
	WAIT
	GLIDE_OFF
	LENGTH $0A
	VIBRATO $01, $04, $01
	NOTE C_, 7
	LEN 4
	GLIDE $02
	WAIT
	GLIDE $FE
	WAIT
	END

; Sound effect 26
Sfx26:
	VOLENV 15, $11, $1F, $14
	LEN 6
	WAVE Wave_7938
	GLIDE $02
	NOTE Fsh, 5
	GLIDE_OFF
	LENGTH $0F
	VIBRATO $01, $02, $01
	NOTE Fsh, 6
	GLIDE $FF
	LEN 3
	WAIT
	END

; Sound effect 13
Sfx13:
	CALL_CODE Code_7427
	VOLENV 15, $11, $1F, $13
	WAVE Wave_7928
	VIBRATO $01, $07, $02
	PORTA $02, $1E
	LEN 35
	NOTE D_, 6
	LEN 1
	NOTE C_, 1
	END

; Sound effect 15
Sfx15:
	VOLENV 15, $11, $1F, $12
	WAVE Wave_7848
	GLIDE $FE
	LEN 4
	NOTE E_, 4
	LEN 6
	GLIDE $01
	WAIT
	END

; Sound effect 9
Sfx09:
	WAVE Wave_78C8
	VOLENV 15, $00, $1F, $11
	CH_TRANSPOSE $0C
	GLIDE $FB
	LEN 5
	NOTE E_, 5
	GLIDE $02
	NOTE E_, 5
	END

; Sound effect 10
Sfx10:
	WAVE Wave_78C8
	VOLENV 15, $00, $1F, $11
	LEN 5
	CH_TRANSPOSE $0C
	GLIDE $FE
	NOTE E_, 6
	GLIDE $FB
	NOTE E_, 5
	END

; Unreferenced (10 bytes)
	db $BC, $11, $1F, $13, $E4, $79, $B8, $78, $43, $68

; Sound effect 5
Sfx05:
	LEN 10
	VOLENV 15, $11, $1F, $11
	GLIDE $01
	WAVE Wave_7848
	NOTE Ash, 3
	END

; Sound effect 2
Sfx02:
	VOLENV 15, $11, $2F, $11
	WAVE Wave_7858
	LEN 13
	NOTE C_, 6
	END

; Sound effect 3
Sfx03:
	LEN 4
	VOLENV 15, $11, $2F, $11
	WAVE Wave_7858
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
	WAVE Wave_78B8
	VOLENV 15, $10, $1F, $12
	RELEASE $02, $55
	NOTE C_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	END

; Sound effect 8
Sfx08:
	CALL_CODE Code_7604
	VOLENV 10, $11, $1F, $11
	WAVE Wave_7848
	LEN 10
	ARP 5
	GLIDE $01
	NOTE A_, 3
	END

; Sound effect 11
Sfx11:
	VOLENV 15, $11, $1F, $12
	WAVE Wave_7848
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

; Sound effect 12
Sfx12:
	VOLENV 15, $11, $1F, $12
	WAVE Wave_7848
	LEN 7
	NOTE C_, 6
	NOTE C_, 7
	LEN 30
	NOTE G_, 6
	END

; Sound effect 4
Sfx04:
	VOLENV 15, $00, $00, $00
	WAVE Wave_78E8
	LEN 5
	NOTE A_, 3
	LEN 3
	REST
	LEN 20
	NOTE A_, 3
	END

; Sound effect 28
Sfx28:
	VOLENV 15, $11, $1F, $12
	ARP 0
	CALL_CODE Code_776D
	WAVE Wave_7848
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

; Sound effect 39
Sfx39:
	CALL_CODE Code_7494
	END

; Sound effect 38
Sfx38:
	LEN 5
	VOLENV 15, $00, $00, $00
	WAVE Wave_7848
	CALL_CODE Code_7631
	GLIDE $03
	NOTE A_, 2
	GLIDE $FC
	WAIT
	END

; Sound effect 34
Sfx34:
	VOLENV 10, $00, $00, $00
	GLIDE $FC
	WAVE Wave_7878
	CALL_CODE Code_7662
	LEN 5
	NOTE A_, 6
	END

; Sound effect 32
Sfx32:
	VOLENV 11, $11, $1F, $11
	WAVE Wave_7848
	GLIDE $FF
	LEN 10
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE Dsh, 4
	END

; Sound effect 31
Sfx31:
	LEN 2
	VOLENV 15, $11, $1F, $11
	WAVE Wave_7848
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

; Sound effect 41
Sfx41:
	VOLENV 15, $11, $1F, $12
	WAVE Wave_7848
	ARP 0
	GLIDE $02
	LEN 15
	NOTE A_, 2
	END

; Sound effect 42
Sfx42:
	VOLENV 15, $11, $1F, $11
	WAVE Wave_7848
	ARP 0
	GLIDE $04
	LEN 10
	NOTE A_, 3
	END

; Sound effect 45
Sfx45:
	VOLENV 15, $11, $1F, $13
	WAVE Wave_78A8
	CALL_CODE Code_7713
	LEN 4
	NOTE C_, 3
	CALL_CODE Code_7684
	LEN 1
	REST
	LEN 10
	GLIDE $FE
	NOTE Dsh, 5
	END

; Sound effect 40
Sfx40:
	VOLENV 15, $11, $1F, $12
	WAVE Wave_7868
	CALL_CODE Code_7588
	LEN 10
	GLIDE $FF
	NOTE C_, 4
	END

; Sound effect 37
Sfx37:
	LEN 5
	VOLENV 15, $00, $00, $00
	WAVE Wave_7888
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

; Sound effect 50
Sfx50:
	VOLENV 12, $11, $1F, $13
	WAVE Wave_7848
	LEN 4
	NOTE C_, 5
	LEN 25
	NOTE C_, 6
	VIBRATO $05, $01, $04
	END

; Sound effect 51
Sfx51:
	VOLENV 15, $00, $00, $00
	LEN 4
	WAVE Wave_7878
	REPEAT 4
	NOTE A_, 5
	REST
	REPEAT_END
	END

; Sound effect 52
Sfx52:
	CALL_CODE Code_7427
	VOLENV 15, $11, $1F, $15
	WAVE Wave_7848
	LEN 9
	GLIDE $FC
	NOTE A_, 4
	END

; Sound effect 22
Sfx22:
	CALL_CODE Code_76CD
	END

; Sound effect 16
Sfx16:
	CALL_CODE Code_77C9
	VOLENV 15, $11, $1F, $15
	WAVE Wave_7848
	LEN 9
	GLIDE $FD
	NOTE A_, 3
	END

; Sound effect 23
Sfx23:
	WAVE Wave_7868
	CALL_CODE Code_76CD
	VOLENV 15, $11, $1F, $12
	LEN 8
	GLIDE $FF
	NOTE A_, 4
	LEN 5
	VOLENV 10, $11, $1F, $12
	NOTE A_, 4
	END

; Sound effect 6
Sfx06:
	VOLENV 15, $11, $1F, $12
	ARP 0
	WAVE Wave_7848
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

; Sound effect 33
Sfx33:
	CALL_CODE Code_779A
	END

; Sound effect 56
Sfx56:
	VOLENV 15, $11, $1F, $11
	CALL_CODE Code_7713
	WAVE Wave_7848
	LEN 12
	GLIDE $FE
	NOTE C_, 3
	END

; Sound effect 20
Sfx20:
	CALL_CODE Code_7744
	END

; Sound effect 25
Sfx25:
	VOLENV 12, $11, $1F, $14
	WAVE Wave_7858
	GLIDE $04
	LEN 4
	NOTE A_, 3
	GLIDE $FD
	LEN 4
	WAIT
	REST
	GLIDE $04
	LEN 4
	NOTE G_, 3
	GLIDE $FD
	LEN 4
	WAIT
	REST
	GLIDE $04
	LEN 4
	NOTE Fsh, 3
	GLIDE $FD
	LEN 6
	WAIT
	REST
	END

; Sound effect 7
Sfx07:
	VOLENV 10, $11, $1F, $14
	WAVE Wave_7848
	LEN 33
	VIBRATO $01, $03, $01
	NOTE A_, 5
	END

; Unreferenced (16 bytes)
	db $B9, $11, $1F, $13, $79, $48, $78, $C0, $30, $D5, $3C, $63, $05, $01, $04, $68

; Sound effect 17
Sfx17:
	CALL_CODE Code_776D
	VOLENV 15, $00, $00, $00
	WAVE Wave_7938
	LEN 3
	GLIDE $FF
	NOTE Csh, 6
	WAVE Wave_7908
	WAIT
	WAVE Wave_7928
	WAIT
	END

; Sound effect 44
Sfx44:
	CALL_CODE Code_75C4
	WAVE Wave_7848
	VOLENV 10, $11, $1F, $12
	LEN 7
	GLIDE $01
	NOTE C_, 3
	NOTE G_, 2
	END

; Sound effect 21
Sfx21:
	VOLENV 10, $15, $1F, $23
	VIBRATO $00, $02, $06
	WAVE Wave_78F8
	ARP 8
	LEN 20
	NOTE A_, 5
	WAIT
	END

; Sound effect 54
Sfx54:
	VOLENV 12, $11, $1F, $13
	VIBRATO $00, $01, $04
	WAVE Wave_7868
	CALL_CODE Code_7684
	GLIDE $FC
	LEN 5
	NOTE A_, 4
	CALL_CODE Code_7684
	GLIDE $08
	WAIT
	CALL_CODE Code_7662
	GLIDE_OFF
	LEN 10
	WAIT
	GLIDE $FF
	WAIT
	END
Code_7427:
	ld a, $2D
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7449)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7449)
	ld [wNoise43], a
	ld a, HIGH(Noise42_746F)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_746F)
	ld [wNoise42], a
	ret
Noise43_7449:
	db $03, $93, $80, $72, $70, $56, $54, $60
	db $50, $40, $30, $20, $10, $56, $54, $60
	db $50, $40, $30, $20, $10, $56, $54, $60
	db $50, $40, $30, $20, $10, $56, $54, $60
	db $50, $40, $30, $20, $10, $FF
Noise42_746F:
	db $F3, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF
Code_7494:
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
	ld a, HIGH(Noise43_74BF)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_74BF)
	ld [wNoise43], a
	ld a, HIGH(Noise42_74CA)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_74CA)
	ld [wNoise42], a
	ret
Noise43_74BF:
	db $57, $46, $45, $44, $43, $42, $41, $40
	db $20, $20, $FF
Noise42_74CA:
	db $19, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $F3
Code_74D4:
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
	ld a, HIGH(Noise43_7501)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7501)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_7501:
	db $18, $3A, $47, $49, $2E, $2D, $1C, $28
	db $4A, $57, $39, $4E, $1D, $0C, $FF
Unused_Noise_7510:
	ld a, $08
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7532)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7532)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7536)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7536)
	ld [wNoise42], a
	ret
Noise43_7532:
	db $00, $43, $45, $FF
Noise42_7536:
	db $F1, $FF, $00
Unused_Noise_7539:
	ld a, $0A
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_755B)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_755B)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7564)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7564)
	ld [wNoise42], a
	ret
Noise43_755B:
	db $36, $35, $34, $33, $31, $20, $10, $10
	db $FF
Noise42_7564:
	db $C1, $FF, $FF, $FF, $FF, $FF, $FF, $FF
Noise43_756C:
	db $12, $64, $02, $37, $47, $24, $55, $71
	db $07, $44, $60, $36, $84, $82, $64, $02
	db $37, $47, $24, $55, $71, $07, $44, $60
	db $36, $86, $32, $FF
Code_7588:
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
	ld a, HIGH(Noise43_75B2)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_75B2)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_75B2:
	db $46, $45, $44, $43, $42, $41, $32, $30
	db $FF

; Unreferenced (9 bytes)
	db $10, $10, $20, $31, $33, $34, $35, $36, $FF
Code_75C4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $19
	ld [wDrumHold], a
	ld a, HIGH(Noise43_756C)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_756C)
	ld [wNoise43], a
	ld a, HIGH(Noise42_75E6)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_75E6)
	ld [wNoise42], a
	ret
Noise42_75E6:
	db $59, $FF, $FF, $FF, $FF, $FF, $FF, $F2
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $FF

; Unreferenced (3 bytes)
	db $FF, $FF, $FF
Code_7604:
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
	ld a, HIGH(Noise43_756C)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_756C)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Code_7631:
	ld a, $08
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7653)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7653)
	ld [wNoise43], a
	ld a, HIGH(Noise42_765B)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_765B)
	ld [wNoise42], a
	ret
Noise43_7653:
	db $60, $52, $42, $41, $22, $11, $21, $FF
Noise42_765B:
	db $F0, $F0, $F0, $F0, $F0, $F0, $61
Code_7662:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_76A6)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_76A6)
	ld [wNoise43], a
	ld a, HIGH(Noise42_76C0)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_76C0)
	ld [wNoise42], a
	ret
Code_7684:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_76B3)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_76B3)
	ld [wNoise43], a
	ld a, HIGH(Noise42_76C0)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_76C0)
	ld [wNoise42], a
	ret
Noise43_76A6:
	db $10, $10, $20, $31, $32, $33, $33, $34
	db $34, $35, $35, $36, $FF
Noise43_76B3:
	db $36, $35, $35, $34, $34, $33, $33, $32
	db $31, $20, $10, $10, $FF
Noise42_76C0:
	db $5C, $FF, $FF, $FF, $FF, $FF, $A1, $FF
	db $FF, $FF, $FF, $FF

; Unreferenced (1 bytes)
	db $FF
Code_76CD:
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
	ld a, HIGH(Noise43_76F7)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_76F7)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_76F7:
	db $12, $92, $42, $42, $42, $42, $52, $65
	db $45, $FF

; Unreferenced (18 bytes)
	db $F0, $FF, $55, $00, $B2, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $F0, $FF, $FF
	db $FF, $F4
Code_7713:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7735)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7735)
	ld [wNoise43], a
	ld a, HIGH(Noise42_773D)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_773D)
	ld [wNoise42], a
	ret
Noise43_7735:
	db $02, $51, $61, $71, $91, $71, $60, $FF
Noise42_773D:
	db $F0, $F0, $F0, $F0, $F0, $70, $63
Code_7744:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7766)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7766)
	ld [wNoise43], a
	ld a, HIGH(Noise42_776A)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_776A)
	ld [wNoise42], a
	ret
Noise43_7766:
	db $02, $51, $11, $FF
Noise42_776A:
	db $F0, $A0, $55
Code_776D:
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_778F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_778F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7795)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7795)
	ld [wNoise42], a
	ret
Noise43_778F:
	db $00, $53, $71, $91, $31, $FF
Noise42_7795:
	db $F1, $FF, $FF, $FF, $00
Code_779A:
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_77BC)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_77BC)
	ld [wNoise43], a
	ld a, HIGH(Noise42_77C3)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_77C3)
	ld [wNoise42], a
	ret
Noise43_77BC:
	db $41, $61, $61, $41, $71, $71, $FF
Noise42_77C3:
	db $A1, $52, $00, $61, $52, $00
Code_77C9:
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
	ld a, HIGH(Noise43_77F4)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_77F4)
	ld [wNoise43], a
	ld a, HIGH(Noise42_77FA)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_77FA)
	ld [wNoise42], a
	ret
Noise43_77F4:
	db $03, $93, $80, $72, $70, $FF
Noise42_77FA:
	db $F0, $FF, $FF, $FF, $F3
Code_77FF:
	ld a, $21
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7821)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7821)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7825)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7825)
	ld [wNoise42], a
	ret
Noise43_7821:
	db $60, $74, $60, $FF
Noise42_7825:
	db $F1, $FF, $83
Wave_7828:
	db $00, $16, $8A, $FF, $FF, $A8, $61, $00
	db $00, $16, $8A, $FF, $FF, $A8, $61, $00
Wave_7838:
	db $B7, $40, $F4, $7B, $FD, $FF, $FE, $DC
	db $02, $46, $8A, $BD, $FD, $BA, $6F, $20
Wave_7848:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
Wave_7858:
	db $00, $00, $00, $00, $CD, $EF, $FD, $EC
	db $00, $12, $21, $00, $DD, $DD, $DD, $DD
Wave_7868:
	db $00, $00, $00, $00, $00, $00, $FF, $FF
	db $00, $00, $00, $00, $00, $00, $FF, $FF
Wave_7878:
	db $00, $00, $00, $00, $00, $00, $FF, $00
	db $00, $00, $00, $00, $00, $00, $FF, $00
Wave_7888:
	db $00, $00, $00, $CD, $EF, $FF, $FF, $FF
	db $04, $8C, $FF, $FF, $FF, $FF, $FF, $FF
Wave_7898:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $00, $FF, $FF, $FF
Wave_78A8:
	db $63, $10, $00, $00, $00, $00, $01, $36
	db $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9
Wave_78B8:
	db $63, $10, $01, $47, $74, $10, $01, $36
	db $9C, $EF, $FE, $B8, $8B, $EF, $FE, $C9
Wave_78C8:
	db $63, $1F, $01, $47, $74, $10, $01, $36
	db $9C, $E0, $FE, $B8, $8B, $EF, $FE, $C9
Wave_78D8:
	db $00, $00, $00, $00, $12, $32, $11, $36
	db $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9
Wave_78E8:
	db $0F, $00, $F0, $F0, $F0, $F0, $00, $0F
	db $0F, $FF, $FF, $00, $FF, $F0, $0F, $0F
Wave_78F8:
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $ED, $CB, $A9, $87, $65, $43, $21, $00
Wave_7908:
	db $04, $8B, $DE, $FF, $ED, $CB, $A9, $87
	db $65, $44, $44, $32, $11, $24, $7A, $74
Wave_7918:
	db $20, $13, $69, $BD, $FD, $B9, $64, $20
	db $13, $68, $B8, $64, $20, $24, $68, $64
Wave_7928:
	db $20, $24, $68, $AC, $EC, $A8, $64, $20
	db $24, $68, $A8, $64, $20, $24, $68, $64
Wave_7938:
	db $02, $48, $AC, $FF, $FC, $53, $00, $27
	db $9C, $DD, $DC, $B7, $7B, $CD, $DD, $C9
Noise43_7948:
	db $01, $61, $71, $A1, $B1, $B1, $A1, $FF
Noise42_7950:
	db $C1, $F0, $A0, $90, $70, $40, $33
Noise43_7957:
	db $06, $04, $03, $03, $07, $FF
Noise42_795D:
	db $F0, $C0, $80, $60, $55
Noise43_7962:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_796A:
	db $60, $30, $12, $FF, $FF, $FF, $FF
Noise43_7971:
	db $04, $00, $00, $00, $00, $00, $00, $FF
Noise42_7979:
	db $90, $53, $FF, $FF, $FF, $FF, $FF
Noise43_7980:
	db $04, $02, $01, $01, $01, $01, $01, $FF
Noise42_7988:
	db $70, $40, $40, $40, $40, $43, $FF
Noise43_798F:
	db $50, $41, $50, $51, $42, $53, $51, $FF
Noise42_7997:
	db $D0, $70, $90, $60, $C0, $50, $61
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7948)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7948)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7950)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7950)
	ld [wNoise42], a
	ret
Drum8:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_79D8)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_79D8)
	ld [wNoise43], a
	ld a, HIGH(Noise42_79E0)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_79E0)
	ld [wNoise42], a
	ret
Noise43_79D8:
	db $60, $52, $42, $41, $22, $11, $04, $FF
Noise42_79E0:
	db $F0, $F0, $F0, $A0, $70, $40, $51
Drum3:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_798F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_798F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7997)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7997)
	ld [wNoise42], a
	ret
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7980)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7980)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7988)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7988)
	ld [wNoise42], a
	ret
Drum5:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7971)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7971)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7979)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7979)
	ld [wNoise42], a
	ret
Drum6:
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
Drum7:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7957)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7957)
	ld [wNoise43], a
	ld a, HIGH(Noise42_795D)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_795D)
	ld [wNoise42], a
	ret
Drum9:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7A95)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7A95)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7A98)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7A98)
	ld [wNoise42], a
	ret
Noise43_7A95:
	db $51, $32, $FF
Noise42_7A98:
	db $F0, $62
Drum10:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7AD4)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7AD4)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7AD7)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7AD7)
	ld [wNoise42], a
	ret
Drum11:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7AD9)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7AD9)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7AE1)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7AE1)
	ld [wNoise42], a
	ret
Noise43_7AD4:
	db $51, $32, $FF
Noise42_7AD7:
	db $70, $52
Noise43_7AD9:
	db $51, $32, $32, $32, $32, $51, $32, $FF
Noise42_7AE1:
	db $70, $51, $FF, $FF, $FF, $70, $51
FadeOutTable:
	db $77, $66, $55, $44, $33, $22, $11, $00
	db FADE_END
FadeInTable:
	db $00, $11, $22, $33, $44, $55, $66, $77
	db FADE_END
DriverEndText:
	db "Final de la rutina de musica"

; Unreferenced (1258 bytes)
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
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
