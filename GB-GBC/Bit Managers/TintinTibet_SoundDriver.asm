; =====================================================================
; Tintin in Tibet (E) (M4) (Eng-Fre-Ger-Dut) [S] - Game Boy
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o tibet.o TintinTibet_SoundDriver.asm
;   rgblink -o tibet.gb tibet.o
;   python tools/cmp_banked.py tibet.gb "Tintin in Tibet (E) (M4) (Eng-Fre-Ger-Dut) [S].gb" 15:4000-7FFF
; (driver and data fill ROM bank 15; the linked file only matches in that range)
;
; Documentation: TintinTibet_SoundDriver.md / AJG_SoundEngine_Family.md
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
	db $84 + \1
ENDM
MACRO ARP       ; arpeggio n of the current arpeggio table
	db $91 + \1
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
DEF DRUM_TEMPO EQU $BC         ; + n: one step every n ticks
DEF DRUM_LOOP EQU $FF           ; restart the pattern

; ---- RAM / HRAM ----
DEF wCh1 EQU $C100
DEF wPaused EQU $C13C
DEF wStereo EQU $C13D
DEF wShNR32 EQU $C13E
DEF wInInstr EQU $C13F
DEF wNoisePan EQU $C140
DEF wDrumHold EQU $C141
DEF wInstrTable EQU $C142
DEF wInstrTableHi EQU $C143
DEF wArpTable EQU $C144
DEF wArpTableHi EQU $C145
DEF wMusicWave EQU $C146
DEF wMusicWaveHi EQU $C147
DEF wNoiseAutoPan EQU $C148
DEF wDrumPatHi EQU $C149
DEF wDrumPat EQU $C14A
DEF wDrumPos EQU $C14B
DEF wDrumsOn EQU $C14C
DEF wDrumTempo EQU $C14D
DEF wDrumTimer EQU $C14E
DEF wDrumLoopCount EQU $C14F
DEF wDrumLoopPos EQU $C150
DEF wNoise43Hi EQU $C151
DEF wNoise43 EQU $C152
DEF wNoise42Hi EQU $C153
DEF wNoise42 EQU $C154
DEF wNoisePos EQU $C155
DEF wNoiseOn EQU $C156
DEF wNoiseAtten EQU $C157
DEF wNoiseTimer EQU $C158
DEF wNoiseSpeed EQU $C159
DEF wFadeTable EQU $C15A
DEF wFadeTableHi EQU $C15B
DEF wFadePos EQU $C15C
DEF wFadeTimer EQU $C15D
DEF wFadeSpeed EQU $C15E
DEF wFadeOn EQU $C15F
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
	dw Cmd_FadeOff
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
	ld [hl], $00
	dec l
	ld a, [hl]
	ldh [rNR12], a
	ld a, b
	or $80
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
	ld [hl], $00
	dec l
	ld a, [hl]
	ldh [rNR22], a
	ld a, b
	or $80
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
	add a, $90
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
	jr nc, StreamCommand
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
	bit 5, [hl]
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
	sub $EB
	ld l, $39
	ld [hli], a
	ld [hl], e
	inc l
	ld [hl], d
	jr ReadByte

; StreamCommand: REPEAT / LEN / VOLENV / ARP / INSTR ranges, else CmdTable.
StreamCommand:
	cp $ED
	jr nc, Cmd_Repeat
	cp $BD
	jr nc, Cmd_Len
	cp $AD
	jr nc, Cmd_VolEnv
	cp $91
	jr nc, Cmd_Arp
	cp $84
	jr nc, Cmd_Instrument
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

; ARP n: arpeggio n of wArpTable.
Cmd_Arp:
	sub $91
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
	sub $83
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

; SLIDE_UP n / SLIDE_DOWN n: the vibrato machinery without delay and with speed 1:
; from each note on, the pitch offset moves n per tick in one direction for 255
; ticks (the counter starts at 1 >> 1 = 0). Flag b5 keeps the direction at note on.
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
	or $38
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
	or $28
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
	or $48
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
	ld l, $08
	ld [hl], $00
	ld a, h
	cp $C3
	jr nc, Cmd_Wait
	ld l, $32
	xor a
	ld [hli], a
	inc a
	ld [hl], a

; WAIT / WAIT2: wait one length (ends the read). The release check looks for WAIT
; only, so WAIT2 is a tie that lets the release happen.
Cmd_Wait:
	pop af
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
; speed + 1 ticks; $6A loops, $FF ends.
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
Cmd_FadeOff:
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
	jr z, Cmd_FadeOff
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

; Unreferenced (230 bytes)
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $C9, $00, $00, $FF, $FF, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0
	db $C0, $C0, $C0, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $C1, $00, $00, $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $C2, $00, $00, $FF, $FF, $01, $01, $01, $01, $01
	db $01, $01, $01, $01, $01, $01, $01, $01, $01, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $CC, $01, $00, $C0, $C0, $C0, $C0
	db $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0, $FF, $FF, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $CD, $01, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $C8
	db $01, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
	db $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $B9, $00, $00, $C0
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

; PlaySfx (A = id): no priority test (the SFX-29 test of Obelix GB is gone); reset
; the SFX page and start the stream. Both API SFX entries lead here, through the
; jp at the end of the API table (PlaySfxEntry2).
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
	add a, $63
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

; Song 1: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong1:
	ld a, $4E
	ld [wInstrTableHi], a
	ld a, $17
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
	dw Pat_4B8B
Loop_4B45:
	dw Pat_4B8B
	dw Pat_4BA5
	dw Pat_4BA5
	dw Pat_4BA5
	dw Pat_4BA5
	dw Pat_4BA5
	dw Pat_4BF4
	dw Pat_4BA5
	dw Pat_4B8B
	ORDER_LOOP Loop_4B45
Song1_Ch2:
	dw Pat_4BFD
Loop_4B5D:
	dw Pat_4BFD
	dw Pat_4C28
	dw Pat_4C28
	dw Pat_4C28
	dw Pat_4CB0
	dw Pat_4CB0
	dw Pat_4C49
	dw Pat_4C4E
	dw Pat_4BFD
	ORDER_LOOP Loop_4B5D
Song1_Ch3:
	dw Pat_4CC9
Loop_4B75:
	dw Pat_4CD8
	dw Pat_4CF4
	dw Pat_4D3F
	dw Pat_4D53
	dw Pat_4D3F
	dw Pat_4D53
	dw Pat_4D6E
	dw Pat_4DA6
	dw Pat_4DDD
	ORDER_LOOP Loop_4B75
Pat_4B8B:
	DRUMS $09, DrumPat_4DE8
	VIBRATO $09, $01, $05
	LEN 18
	REPEAT 4
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE C_, 3
	NOTE C_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE C_, 3
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	REPEAT_END
	NEXT
Pat_4BA5:
	DRUMS $09, DrumPat_4DF2
Pat_4BA9:
	LEN 18
	INSTR 0
	NOTE C_, 3
	INSTR 1
	LEN 9
	NOTE C_, 3
	NOTE G_, 3
	INSTR 0
	LEN 18
	NOTE C_, 3
	NOTE C_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE C_, 3
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 1
	LEN 9
	NOTE C_, 3
	NOTE G_, 3
	INSTR 0
	LEN 18
	NOTE C_, 3
	NOTE C_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE C_, 3
	NOTE C_, 3
	INSTR 1
	LEN 9
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	LEN 18
	NOTE C_, 3
	INSTR 1
	LEN 9
	NOTE C_, 3
	NOTE G_, 3
	INSTR 0
	LEN 18
	NOTE C_, 3
	NOTE C_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE C_, 3
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 1
	LEN 9
	NOTE C_, 3
	NOTE G_, 3
	INSTR 0
	LEN 18
	NOTE C_, 3
	NOTE C_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE C_, 3
	NOTE C_, 3
	INSTR 1
	LEN 9
	NOTE C_, 4
	NOTE C_, 4
	NEXT
Pat_4BF4:
	LEN 18
	CH_TRANSPOSE $02
	PAT_CALL Pat_4BA9
	CH_TRANSPOSE $00
	NEXT
Pat_4BFD:
	REPEAT 4
	INSTR 2
	LEN 18
	NOTE C_, 2
	NOTE C_, 2
	INSTR 1
	NOTE C_, 2
	LEN 9
	NOTE C_, 2
	NOTE C_, 2
	LEN 18
	NOTE C_, 2
	LEN 9
	NOTE C_, 2
	NOTE C_, 2
	LEN 18
	NOTE C_, 2
	LEN 9
	NOTE C_, 2
	NOTE C_, 2
	REPEAT_END
	NEXT
Pat_4C13:
	INSTR 2
	LEN 18
	NOTE C_, 2
	LEN 9
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	LEN 18
	NOTE C_, 2
	LEN 9
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 4
	NOTE C_, 2
	NOTE C_, 2
	NEXT
Pat_4C28:
	PAT_CALL Pat_4C13
	INSTR 2
	LEN 18
	NOTE C_, 2
	LEN 9
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	LEN 18
	NOTE C_, 2
	LEN 9
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 2
	LEN 18
	NOTE C_, 2
	LEN 9
	NOTE C_, 2
	NOTE C_, 2
	PAT_CALL Pat_4C13
	PAT_CALL Pat_4C13
	CH_TRANSPOSE $00
	NEXT
Pat_4C49:
	CH_TRANSPOSE $02
	PAT_GOTO Pat_4C28
Pat_4C4E:
	INSTR 2
	LEN 18
	NOTE C_, 2
	LEN 9
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 4
	LEN 18
	NOTE C_, 4
	INSTR 1
	LEN 9
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	NOTE C_, 2
	NOTE C_, 2
	INSTR 2
	LEN 18
	NOTE C_, 2
	LEN 9
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 4
	LEN 18
	NOTE C_, 4
	INSTR 1
	LEN 9
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 2
	INSTR 4
	LEN 18
	NOTE C_, 4
	INSTR 1
	LEN 9
	NOTE C_, 2
	NOTE C_, 2
	INSTR 2
	LEN 18
	NOTE C_, 2
	LEN 9
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 4
	NOTE C_, 4
	NOTE C_, 4
	INSTR 1
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	NOTE C_, 2
	NOTE C_, 2
	INSTR 2
	LEN 18
	NOTE C_, 2
	LEN 9
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 4
	NOTE C_, 4
	NOTE C_, 4
	INSTR 1
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 4
	NOTE C_, 4
	INSTR 1
	NOTE C_, 2
	NEXT
Pat_4CB0:
	REPEAT 4
	INSTR 2
	LEN 18
	NOTE C_, 2
	NOTE C_, 2
	INSTR 4
	NOTE C_, 4
	INSTR 1
	LEN 9
	NOTE C_, 2
	NOTE C_, 2
	LEN 18
	NOTE C_, 2
	LEN 9
	NOTE C_, 2
	NOTE C_, 2
	INSTR 4
	LEN 18
	NOTE C_, 4
	INSTR 1
	LEN 9
	NOTE C_, 2
	NOTE C_, 2
	REPEAT_END
	NEXT
Pat_4CC9:
	INSTR 5
	LENGTH $90
	CH_TRANSPOSE $0C
	PAN_R
	NOTE C_, 3
	PAN_L
	NOTE C_, 3
	PAN_R
	NOTE C_, 3
	PAN_L
	NOTE C_, 3
	PAN_C
	NEXT
Pat_4CD8:
	LEN 18
	REPEAT 3
	INSTR 5
	NOTE C_, 3
	INSTR 8
	LEN 27
	NOTE G_, 2
	NOTE G_, 2
	LEN 36
	NOTE G_, 2
	LEN 18
	NOTE G_, 2
	NOTE G_, 2
	REPEAT_END
	INSTR 5
	NOTE C_, 3
	INSTR 8
	LEN 27
	NOTE G_, 2
	NOTE G_, 2
	LEN 36
	NOTE G_, 2
	LEN 9
	NOTE G_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 3
	NEXT
Pat_4CF4:
	INSTR 5
	LEN 18
	NOTE C_, 3
	INSTR 8
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE F_, 2
	NOTE G_, 2
	LEN 9
	NOTE F_, 2
	LEN 27
	NOTE G_, 2
	LEN 9
	NOTE F_, 2
	LEN 18
	NOTE G_, 2
	NOTE G_, 2
	INSTR 5
	NOTE C_, 3
	INSTR 8
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE F_, 2
	NOTE G_, 2
	LEN 9
	NOTE F_, 2
	LEN 27
	NOTE G_, 2
	LEN 9
	NOTE F_, 2
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 2
	NOTE G_, 2
	INSTR 5
	LEN 18
	NOTE C_, 3
	INSTR 8
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE F_, 2
	NOTE G_, 2
	LEN 9
	NOTE F_, 2
	LEN 27
	NOTE G_, 2
	LEN 9
	NOTE F_, 2
	LEN 18
	NOTE G_, 2
	NOTE G_, 2
	INSTR 5
	NOTE C_, 3
	INSTR 8
	LEN 9
	NOTE G_, 2
	LEN 18
	NOTE F_, 2
	NOTE G_, 2
	LEN 9
	NOTE F_, 2
	LEN 27
	NOTE G_, 2
	LEN 9
	NOTE F_, 2
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 2
	NOTE G_, 3
	NEXT
Pat_4D3F:
	INSTR 6
	LEN 27
	NOTE C_, 4
	NOTE B_, 3
	LENGTH $5A
	NOTE G_, 3
	LENGTH $90
	NOTE C_, 3
	LEN 27
	NOTE Ash, 3
	NOTE A_, 3
	LENGTH $5A
	NOTE F_, 3
	LENGTH $90
	NOTE C_, 3
	NEXT
Pat_4D53:
	INSTR 6
	LEN 27
	NOTE C_, 4
	NOTE B_, 3
	LENGTH $5A
	NOTE G_, 3
	LEN 27
	NOTE Ash, 3
	NOTE A_, 3
	LENGTH $36
	NOTE F_, 3
	LEN 36
	NOTE D_, 3
	LEN 9
	NOTE E_, 3
	NOTE F_, 3
	LENGTH $6C
	NOTE G_, 3
	LEN 18
	NOTE C_, 3
	LENGTH $90
	NOTE C_, 3
	NEXT
Pat_4D6E:
	CH_TRANSPOSE $00
	INSTR 7
	LEN 18
	NOTE Fsh, 4
	LEN 9
	NOTE D_, 3
	NOTE A_, 3
	LEN 18
	NOTE D_, 4
	LEN 36
	NOTE G_, 4
	LEN 18
	NOTE D_, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 4
	LEN 9
	NOTE D_, 3
	NOTE A_, 3
	LEN 18
	NOTE D_, 4
	LEN 36
	NOTE G_, 4
	LEN 18
	NOTE D_, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE Fsh, 4
	LEN 9
	NOTE D_, 3
	NOTE A_, 3
	LEN 18
	NOTE D_, 4
	LEN 36
	NOTE G_, 4
	LEN 18
	NOTE D_, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE C_, 5
	LEN 9
	NOTE D_, 4
	LEN 18
	NOTE B_, 4
	LEN 9
	NOTE D_, 4
	LEN 36
	NOTE A_, 4
	LEN 9
	NOTE D_, 3
	NOTE A_, 3
	LEN 18
	NOTE C_, 4
	NOTE D_, 4
	NEXT
Pat_4DA6:
	INSTR 7
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE C_, 3
	NOTE G_, 3
	LEN 18
	NOTE C_, 4
	LEN 36
	NOTE F_, 4
	LEN 18
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 4
	LEN 9
	NOTE C_, 3
	NOTE G_, 3
	LEN 18
	NOTE C_, 4
	LEN 36
	NOTE F_, 4
	LEN 18
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 5
	LEN 9
	NOTE C_, 3
	NOTE G_, 3
	LEN 18
	NOTE C_, 4
	LEN 36
	NOTE F_, 5
	LEN 18
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE Ash, 5
	LEN 9
	NOTE C_, 4
	LEN 18
	NOTE A_, 5
	LEN 9
	NOTE C_, 4
	LEN 36
	NOTE F_, 5
	LEN 9
	NOTE C_, 3
	NOTE G_, 3
	NOTE D_, 5
	NOTE E_, 5
	LEN 18
	NOTE F_, 5
	NEXT
Pat_4DDD:
	INSTR 7
	LENGTH $90
	NOTE C_, 5
	CH_TRANSPOSE $0C
	INSTR 5
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NEXT
DrumPat_4DE8:
	db DRUM_LEVEL + 15, 6, 0, 8, 0, 10, 0, 6
	db 0, DRUM_LOOP
DrumPat_4DF2:
	db DRUM_PAN_C, DRUM_LEVEL + 15, 6, DRUM_LEVEL + 12, 8, DRUM_LEVEL + 10, DRUM_PAN_L, 8
	db DRUM_LEVEL + 12, 8, DRUM_PAN_C, 9, DRUM_PAN_L, 8, DRUM_LEVEL + 15, 6
	db DRUM_PAN_C, DRUM_LEVEL + 14, 8, DRUM_PAN_C, DRUM_LEVEL + 15, 6, DRUM_LEVEL + 12, 8
	db DRUM_LEVEL + 10, DRUM_PAN_R, 8, DRUM_LEVEL + 12, 8, DRUM_PAN_C, 9, DRUM_PAN_R
	db 8, DRUM_LEVEL + 15, 6, DRUM_PAN_C, DRUM_LEVEL + 14, 8, DRUM_LOOP

; Instrument table 1, entries 1..9 (the song routines point 2 bytes before:
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
Instr1_0:
	HWENV $F2, $00
	ARP 2
	END
Instr1_1:
	HWENV $F2, $03, $53
	DUTY_75
	ARP 0
	END
Instr1_2:
	HWENV $F2, $00
	ARP 0
	END
Instr1_3:
	HWENV $F2, $00
	ARP 0
	END
Instr1_4:
	HWENV $F1, $02, $93
	ARP 4
	AUTODUTY $02
	END
Instr1_5:
	WAVE Wave_7C6D
	VOLENV 13, $11, $1C, $1C
	VIBRATO $08, $03, $06
	ARP 0
	END
Instr1_6:
	WAVE Wave_7C9D
	VOLENV 13, $11, $1A, $18
	ARP 3
	VIBRATO $09, $01, $05
	END
Instr1_7:
	WAVE Wave_7BDD
	VOLENV 15, $11, $1F, $16
	ARP 0
	END
Instr1_8:
	WAVE Wave_7BED
	VOLENV 13, $11, $1F, $11
	ARP 0
	END

; Song 2: instrument table - (none set), arpeggio table 1 (the one SndInit sets)
PlaySong2:
	call StopAll
	ld de, Song2_Ch1
	call StartMusicCh1
	ld de, Song2_Ch2
	call StartMusicCh2
	ld de, Song2_Ch3
	jp StartMusicCh3
Song2_Ch1:
	dw Pat_4EBA
	dw Pat_4EE5
	dw Pat_4EBA
	dw Pat_4EE5
	dw Pat_4F0A
	dw Pat_4F2E
	ORDER_LOOP Song2_Ch1
Song2_Ch2:
	dw Pat_4F38
	dw Pat_4F46
	dw Pat_4F73
	dw Pat_4FA8
	dw Pat_4F49
	dw Pat_4F67
	ORDER_LOOP Song2_Ch2
Song2_Ch3:
	dw Pat_4FC8
	dw Pat_5003
	dw Pat_4FC8
	dw Pat_5003
	dw Pat_5027
	dw Pat_5047
	ORDER_LOOP Song2_Ch3
Pat_4EBA:
	HWENV $F2, $08, $54
	DUTY_50
	ARP 8
	LEN 16
	NOTE C_, 2
	NOTE G_, 2
	NOTE E_, 3
	NOTE C_, 3
	NOTE C_, 2
	NOTE E_, 2
	LEN 32
	NOTE G_, 2
	LEN 16
	NOTE C_, 2
	NOTE G_, 2
	NOTE E_, 3
	NOTE C_, 3
	NOTE C_, 2
	NOTE G_, 2
	LEN 32
	NOTE C_, 3
	LEN 16
	NOTE C_, 2
	NOTE G_, 2
	NOTE E_, 3
	NOTE C_, 3
	NOTE C_, 2
	NOTE E_, 2
	LEN 32
	NOTE G_, 2
	LEN 16
	NOTE C_, 2
	NOTE G_, 2
	NOTE E_, 3
	NOTE C_, 3
	NOTE C_, 2
	NOTE G_, 2
	LEN 32
	NOTE C_, 3
	NEXT
Pat_4EE5:
	LEN 16
	NOTE D_, 2
	NOTE A_, 2
	NOTE Fsh, 3
	NOTE D_, 3
	NOTE D_, 2
	NOTE A_, 2
	LEN 32
	NOTE D_, 3
	LEN 16
	NOTE F_, 2
	NOTE C_, 3
	NOTE F_, 3
	NOTE E_, 3
	NOTE F_, 2
	NOTE A_, 2
	LEN 32
	NOTE C_, 3
	LEN 16
	NOTE C_, 2
	NOTE G_, 2
	NOTE E_, 3
	NOTE C_, 3
	NOTE C_, 2
	NOTE G_, 2
	LEN 32
	NOTE Ash, 2
	LEN 16
	NOTE C_, 2
	NOTE G_, 2
	NOTE E_, 3
	NOTE C_, 3
	NOTE C_, 2
	NOTE G_, 2
	NOTE Ash, 2
	NOTE D_, 3
	NEXT
Pat_4F0A:
	LEN 16
	NOTE Dsh, 2
	NOTE Ash, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE F_, 2
	NOTE C_, 3
	LEN 32
	NOTE F_, 3
	LEN 16
	NOTE Ash, 2
	NOTE F_, 2
	NOTE Ash, 2
	NOTE D_, 3
	NOTE F_, 3
	NOTE D_, 3
	NOTE Ash, 2
	NOTE F_, 2
	NOTE Dsh, 2
	NOTE Ash, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE F_, 2
	NOTE C_, 3
	LEN 32
	NOTE F_, 3
	LEN 16
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NEXT
Pat_4F2E:
	LEN 16
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE A_, 2
	NOTE Ash, 2
	NOTE B_, 2
	NEXT
Pat_4F38:
	HWENV $A2, $00
	DUTY_75
	ARP 0
	VIBRATO $14, $01, $05
	CH_TRANSPOSE $0C
	PAT_GOTO Pat_4FDC
Pat_4F46:
	PAT_GOTO Pat_5003
Pat_4F49:
	LEN 32
	NOTE Dsh, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE A_, 3
	LENGTH $40
	NOTE Ash, 3
	LEN 32
	NOTE Ash, 3
	NOTE F_, 3
	NOTE Dsh, 3
	NOTE G_, 3
	LENGTH $30
	NOTE A_, 3
	LEN 8
	NOTE G_, 3
	NOTE F_, 3
	LENGTH $50
	NOTE G_, 3
	LEN 16
	NOTE D_, 4
	LEN 8
	NOTE Fsh, 3
	NOTE G_, 3
	NOTE Fsh, 3
	NOTE D_, 3
	NEXT
Pat_4F67:
	LENGTH $30
	NOTE F_, 3
	LEN 8
	NOTE E_, 3
	NOTE Dsh, 3
	LEN 16
	NOTE D_, 3
	NOTE A_, 4
	NOTE Ash, 4
	NOTE B_, 4
	NEXT
Pat_4F73:
	CH_TRANSPOSE $00
	ARP 10
	HWENV $5A, $04, $90
	RELEASE $02, $01
	VIBRATO $14, $01, $05
	LENGTH $30
	NOTE A_, 4
	LEN 16
	NOTE Ash, 4
	LENGTH $30
	NOTE A_, 4
	LEN 16
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	LENGTH $30
	NOTE C_, 5
	LEN 16
	NOTE Ash, 4
	LENGTH $30
	NOTE A_, 4
	LEN 16
	NOTE Ash, 4
	LENGTH $30
	NOTE A_, 4
	LEN 16
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	LENGTH $30
	NOTE C_, 5
	LEN 16
	NOTE A_, 4
	NEXT
Pat_4FA8:
	LEN 48
	NOTE D_, 5
	LEN 16
	NOTE C_, 5
	LEN 48
	NOTE D_, 5
	LEN 16
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	LENGTH $40
	NOTE G_, 4
	LEN 32
	NOTE A_, 4
	LENGTH $40
	NOTE C_, 4
	LEN 48
	NOTE Dsh, 4
	LEN 8
	NOTE D_, 4
	NOTE Csh, 4
	LENGTH $40
	NOTE C_, 4
	LEN 48
	NOTE Dsh, 4
	LEN 8
	NOTE D_, 4
	NOTE C_, 4
	NEXT
Pat_4FC8:
	VOLENV 10, $2F, $1F, $1F
	RELEASE $02, $50
	VIBRATO $14, $01, $05
	CH_TRANSPOSE $0C
	WAVE Wave_7D2D
	DRUMS $08, DrumPat_5054
Pat_4FDC:
	LENGTH $30
	NOTE E_, 4
	LEN 16
	NOTE F_, 4
	LENGTH $30
	NOTE E_, 4
	LEN 16
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LENGTH $30
	NOTE G_, 4
	LEN 16
	NOTE F_, 4
	LENGTH $30
	NOTE E_, 4
	LEN 16
	NOTE F_, 4
	LENGTH $30
	NOTE E_, 4
	LEN 16
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LENGTH $30
	NOTE G_, 4
	LEN 16
	NOTE E_, 4
	NEXT
Pat_5003:
	LENGTH $30
	NOTE A_, 4
	LEN 16
	NOTE G_, 4
	LENGTH $30
	NOTE A_, 4
	LEN 16
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	LENGTH $40
	NOTE D_, 4
	LEN 32
	NOTE E_, 4
	LENGTH $40
	NOTE G_, 3
	LENGTH $30
	NOTE Ash, 3
	LEN 8
	NOTE A_, 3
	NOTE Gsh, 3
	LENGTH $40
	NOTE G_, 3
	LENGTH $30
	NOTE Ash, 3
	LEN 8
	NOTE A_, 3
	NOTE G_, 3
	NEXT
Pat_5027:
	LENGTH $40
	NOTE Ash, 4
	LENGTH $30
	NOTE A_, 4
	LEN 8
	NOTE G_, 4
	NOTE F_, 4
	LEN 16
	NOTE G_, 4
	LENGTH $70
	NOTE D_, 4
	LENGTH $40
	NOTE Ash, 4
	LENGTH $30
	NOTE A_, 4
	LEN 8
	NOTE G_, 4
	NOTE F_, 4
	LENGTH $60
	NOTE G_, 4
	LEN 8
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NEXT
Pat_5047:
	LENGTH $30
	NOTE F_, 4
	LEN 8
	NOTE E_, 4
	NOTE Dsh, 4
	LEN 16
	NOTE D_, 4
	LEN 16
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NEXT
DrumPat_5054:
	db DRUM_LEVEL + 13, DRUM_REPEAT + 3, 6, 0, 6, 0, 9, 0
	db 6, 0, DRUM_REPEAT_END, 6, 0, 6, 0, 9
	db 0, 6, 6, DRUM_REPEAT + 3, 6, 0, 6, 0
	db 9, 0, 6, 0, DRUM_REPEAT_END, 6, 0, 9
	db 0, 9, 0, DRUM_LEVEL + 10, 5, DRUM_LEVEL + 13, 6, DRUM_LOOP

; Song 3: instrument table 2, arpeggio table 1 (the one SndInit sets)
PlaySong3:
	call StopAll
	ld a, $52
	ld [wInstrTableHi], a
	ld a, $E7
	ld [wInstrTable], a
	ld de, Song3_Ch1
	call StartMusicCh1
	ld de, Song3_Ch2
	call StartMusicCh2
	ld de, Song3_Ch3
	jp StartMusicCh3
Song3_Ch1:
	dw Pat_50D1
	dw Pat_50DE
	dw Pat_50EB
	dw Pat_5103
	dw Pat_5124
	dw Pat_50DE
	dw Pat_50DE
	ORDER_LOOP Song3_Ch1
Song3_Ch2:
	dw Pat_5130
	dw Pat_5130
	dw Pat_5130
	dw Pat_5158
	dw Pat_5158
	dw Pat_5130
	dw Pat_5130
	ORDER_LOOP Song3_Ch2
Song3_Ch3:
	dw Pat_51AF
	dw Pat_51ED
	dw Pat_5204
	dw Pat_5242
	dw Pat_523B
	dw Pat_528E
	dw Pat_52C1
	ORDER_LOOP Song3_Ch3
Pat_50D1:
	ARP 7
	HWENV $F3, $08, $85
	VIBRATO $10, $04, $05
	DUTY_50
	RELEASE $02, $01
Pat_50DE:
	LEN 36
	REPEAT 4
	NOTE C_, 2
	LEN 18
	NOTE C_, 2
	LEN 36
	NOTE C_, 2
	LEN 18
	NOTE C_, 2
	LEN 36
	NOTE C_, 2
	REPEAT_END
	NEXT
Pat_50EB:
	LEN 36
	REPEAT 3
	NOTE C_, 2
	LEN 18
	NOTE C_, 2
	LEN 36
	NOTE C_, 2
	LEN 18
	NOTE C_, 2
	LEN 36
	NOTE C_, 2
	REPEAT_END
	NOTE C_, 2
	LEN 18
	NOTE C_, 2
	LEN 36
	NOTE C_, 2
	LEN 18
	NOTE C_, 2
	NOTE C_, 2
	LEN 9
	NOTE C_, 3
	NOTE C_, 3
	NEXT
Pat_5103:
	LEN 27
	NOTE C_, 2
	NOTE C_, 2
	LENGTH $5A
	NOTE C_, 2
	LEN 27
	NOTE C_, 2
	NOTE C_, 2
	LENGTH $5A
	NOTE C_, 2
	LEN 27
	NOTE C_, 2
	NOTE C_, 2
	LEN 18
	NOTE C_, 2
	LEN 36
	NOTE C_, 3
	LEN 18
	NOTE C_, 2
	NOTE C_, 3
	LEN 27
	NOTE C_, 2
	NOTE C_, 2
	LEN 18
	NOTE C_, 2
	LEN 36
	NOTE C_, 3
	LEN 18
	NOTE D_, 2
	NOTE G_, 2
	NEXT
Pat_5124:
	REPEAT 4
	LEN 27
	NOTE C_, 2
	NOTE C_, 2
	LEN 18
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 3
	REPEAT_END
	NEXT
Pat_5130:
	LEN 18
	REPEAT 2
	INSTR 0
	NOTE C_, 4
	INSTR 2
	LEN 9
	NOTE C_, 3
	NOTE C_, 3
	LEN 18
	NOTE C_, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE C_, 3
	NOTE C_, 3
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE C_, 3
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE Ash, 3
	INSTR 2
	LEN 9
	NOTE C_, 3
	NOTE C_, 3
	LEN 18
	NOTE C_, 3
	INSTR 0
	NOTE Ash, 3
	INSTR 2
	NOTE C_, 3
	NOTE C_, 3
	INSTR 0
	NOTE Ash, 3
	INSTR 2
	NOTE C_, 3
	REPEAT_END
	NEXT
Pat_5158:
	LEN 18
	INSTR 1
	NOTE C_, 4
	INSTR 2
	LEN 9
	NOTE C_, 4
	INSTR 1
	LEN 18
	NOTE C_, 4
	INSTR 2
	LEN 9
	NOTE C_, 4
	INSTR 1
	LEN 18
	NOTE C_, 4
	INSTR 2
	LEN 27
	NOTE C_, 4
	LEN 9
	NOTE C_, 4
	LEN 18
	NOTE C_, 4
	NOTE Ash, 3
	INSTR 0
	NOTE Csh, 4
	INSTR 2
	LEN 9
	NOTE C_, 4
	INSTR 0
	LEN 18
	NOTE Csh, 4
	INSTR 2
	LEN 9
	NOTE C_, 4
	INSTR 0
	LEN 18
	NOTE Csh, 4
	INSTR 2
	LEN 27
	NOTE C_, 4
	LEN 9
	NOTE Dsh, 4
	LEN 18
	NOTE Dsh, 4
	NOTE D_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 2
	LEN 9
	NOTE C_, 4
	INSTR 1
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE Ash, 3
	LEN 18
	NOTE C_, 4
	INSTR 2
	NOTE C_, 4
	LEN 9
	NOTE C_, 4
	NOTE C_, 4
	LEN 18
	NOTE C_, 4
	NOTE Ash, 4
	INSTR 1
	NOTE F_, 4
	INSTR 2
	LEN 9
	NOTE C_, 4
	INSTR 1
	LEN 18
	NOTE F_, 4
	INSTR 0
	LEN 9
	NOTE Dsh, 4
	INSTR 1
	LEN 18
	NOTE F_, 4
	INSTR 2
	NOTE C_, 4
	INSTR 1
	NOTE G_, 4
	NOTE G_, 4
	INSTR 0
	NOTE Ash, 4
	NEXT
Pat_51AF:
	VOLENV 10, $2F, $1F, $1F
	RELEASE $02, $50
	VIBRATO $14, $01, $05
	CH_TRANSPOSE $0C
	WAVE Wave_7C7D
	DRUMS $09, DrumPat_5305
	ARP 0
	LENGTH $6C
	NOTE G_, 4
	ARP 1
	LEN 9
	NOTE F_, 4
	ARP 0
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	LENGTH $36
	NOTE F_, 4
	LEN 9
	NOTE E_, 4
	NOTE D_, 4
	LEN 18
	NOTE E_, 4
	ARP 1
	NOTE Dsh, 4
	ARP 0
	NOTE E_, 4
	NOTE D_, 4
	LENGTH $6C
	NOTE D_, 4
	LEN 9
	NOTE D_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE Ash, 3
	LEN 36
	NOTE C_, 4
	LEN 18
	NOTE Ash, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE Ash, 3
	NEXT
Pat_51ED:
	ARP 0
	LENGTH $90
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	NOTE Ash, 3
	LENGTH $75
	NOTE G_, 3
	LEN 9
	NOTE F_, 3
	NOTE G_, 3
	NOTE C_, 4
	LENGTH $6C
	NOTE G_, 3
	LENGTH $90
	NOTE F_, 3
	LEN 18
	WAIT2
	NEXT
Pat_5204:
	ARP 0
	LENGTH $6C
	NOTE G_, 4
	ARP 1
	LEN 9
	NOTE F_, 4
	ARP 0
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	LENGTH $36
	NOTE F_, 4
	LEN 9
	NOTE E_, 4
	NOTE D_, 4
	LEN 18
	NOTE E_, 4
	ARP 1
	NOTE Dsh, 4
	ARP 0
	NOTE E_, 4
	NOTE D_, 4
	LENGTH $36
	NOTE D_, 4
	LEN 9
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE D_, 4
	LEN 36
	NOTE Ash, 3
	LEN 18
	NOTE G_, 3
	ARP 8
	NOTE C_, 4
	LEN 9
	NOTE C_, 3
	NOTE F_, 3
	LEN 18
	NOTE G_, 3
	NOTE C_, 4
	LEN 9
	NOTE C_, 3
	NOTE F_, 3
	LEN 18
	NOTE G_, 3
	LEN 9
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE D_, 4
	NEXT
Pat_523B:
	ARP 9
	WAVE Wave_7BAD
	PAT_GOTO Pat_524B
Pat_5242:
	LEN 9
	DRUMS $09, DrumPat_533E
	VOLENV 15, $14, $1F, $11
Pat_524B:
	NOTE G_, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE G_, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE G_, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NEXT
Pat_528E:
	DRUMS $09, DrumPat_5305
	VOLENV 15, $11, $18, $13
	RELEASE $02, $50
	ARP 9
	LENGTH $48
	NOTE C_, 4
	LEN 18
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE D_, 4
	LEN 27
	NOTE Ash, 3
	NOTE A_, 3
	LEN 9
	NOTE G_, 3
	NOTE A_, 3
	LENGTH $36
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	NOTE A_, 3
	LEN 27
	NOTE Ash, 3
	NOTE A_, 3
	LEN 18
	NOTE G_, 3
	NOTE F_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE F_, 3
	LEN 27
	NOTE Ash, 3
	NOTE A_, 3
	LEN 18
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE E_, 4
	NEXT
Pat_52C1:
	LENGTH $48
	NOTE G_, 4
	LEN 18
	NOTE C_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE D_, 5
	LEN 27
	NOTE Ash, 4
	NOTE A_, 4
	LEN 9
	NOTE G_, 4
	NOTE A_, 4
	LENGTH $2D
	NOTE G_, 4
	LEN 9
	NOTE C_, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 27
	NOTE Ash, 4
	NOTE A_, 4
	LEN 18
	NOTE G_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	LEN 27
	NOTE Ash, 4
	NOTE A_, 4
	LEN 18
	NOTE G_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE Ash, 3
	NEXT

; Instrument table 2, entries 1..3 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr2_0
	dw Instr2_1
	dw Instr2_2
Instr2_0:
	HWENV $F2, $04, $A3
	ARP 4
	AUTODUTY $03
	END
Instr2_1:
	HWENV $F2, $04, $A3
	ARP 5
	AUTODUTY $03
	END
Instr2_2:
	HWENV $E1, $00
	DUTY_12
	ARP 8
	END
DrumPat_5305:
	db DRUM_LEVEL + 13, DRUM_REPEAT + 3, 1, DRUM_PAN_R, 6, DRUM_LEVEL + 12, 4, 0
	db DRUM_PAN_C, DRUM_LEVEL + 13, 2, 0, 1, 0, 1, DRUM_PAN_L
	db 6, DRUM_LEVEL + 12, 4, DRUM_LEVEL + 11, 6, DRUM_PAN_C, DRUM_LEVEL + 13, 2
	db 0, 1, 6, DRUM_REPEAT_END, 1, DRUM_PAN_R, 6, DRUM_LEVEL + 12
	db 4, 0, DRUM_PAN_C, DRUM_LEVEL + 13, 2, 0, 1, 6
	db DRUM_PAN_L, 1, DRUM_PAN_C, 1, DRUM_LEVEL + 12, DRUM_PAN_R, 1, DRUM_PAN_C
	db DRUM_LEVEL + 11, 6, DRUM_LEVEL + 13, 2, 0, 1, DRUM_LEVEL + 12, 5
	db DRUM_LOOP
DrumPat_533E:
	db DRUM_LEVEL + 15, DRUM_PAN_R, 7, 0, 0, DRUM_PAN_L, 7, 0
	db 0, DRUM_PAN_C, 7, 0, 0, DRUM_LEVEL + 13, DRUM_PAN_R, 5
	db 6, 6, DRUM_PAN_C, 9, 6, DRUM_PAN_L, 9, 9
	db DRUM_PAN_C, DRUM_LEVEL + 15, DRUM_PAN_L, 7, 0, 0, DRUM_PAN_R, 7
	db 0, 0, DRUM_PAN_C, 7, 0, 0, DRUM_LEVEL + 13, DRUM_PAN_L
	db 5, 9, 6, DRUM_PAN_C, 9, 6, DRUM_PAN_R, 1
	db 1, DRUM_PAN_C, DRUM_LEVEL + 15, DRUM_PAN_R, 7, 0, 0, DRUM_PAN_L
	db 7, 0, 0, DRUM_PAN_C, 7, 0, 0, DRUM_LEVEL + 13
	db DRUM_PAN_R, 9, 6, 6, DRUM_PAN_C, 9, 1, DRUM_PAN_L
	db 9, 1, DRUM_PAN_C, DRUM_LEVEL + 15, 7, 0, 0, 7
	db 0, 0, 7, 0, 0, DRUM_LEVEL + 13, 6, DRUM_PAN_L
	db 1, 6, DRUM_PAN_R, 1, 6, DRUM_PAN_L, 1, DRUM_PAN_R
	db 1, DRUM_PAN_C, DRUM_LOOP

; Song 4: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong4:
	ld a, $58
	ld [wInstrTableHi], a
	ld a, $49
	ld [wInstrTable], a
	call StopAll
	ld de, Song4_Ch3
	call StartMusicCh3
	ld de, Song4_Ch2
	call StartMusicCh2
	ld de, Song4_Ch1
	jp StartMusicCh1
Song4_Ch3:
	dw Pat_53F0
	dw Pat_544F
	dw Pat_54A3
	dw Pat_54F8
	dw Pat_54A3
	dw Pat_5520
	ORDER_LOOP Song4_Ch3
Song4_Ch2:
	dw Pat_5574
	dw Pat_55C2
	dw Pat_562F
	dw Pat_5674
	dw Pat_562F
	dw Pat_5697
	ORDER_LOOP Song4_Ch2
Song4_Ch1:
	dw Pat_56DA
	dw Pat_574A
	dw Pat_57AA
	dw Pat_57E3
	dw Pat_57AA
	dw Pat_57F9
	ORDER_LOOP Song4_Ch1
Pat_53F0:
	ARP 0
	RELEASE $02, $11
	WAVE Wave_7BBD
	VOLENV 15, $13, $1F, $12
	VIBRATO $06, $08, $05
	LEN 12
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	NOTE C_, 2
	WAIT2
	LEN 24
	NOTE C_, 3
	LEN 12
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	NOTE C_, 2
	WAIT2
	LEN 24
	NOTE C_, 3
	LEN 12
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	NOTE C_, 2
	WAIT2
	LEN 24
	NOTE C_, 3
	LEN 12
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	NOTE C_, 2
	WAIT2
	LEN 24
	NOTE C_, 3
	LEN 12
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	NOTE C_, 2
	WAIT2
	LEN 24
	NOTE C_, 3
	LEN 12
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	NOTE C_, 2
	WAIT2
	LEN 24
	NOTE C_, 3
	LEN 12
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 3
	NEXT
Pat_544F:
	LEN 12
	NOTE F_, 2
	LEN 24
	NOTE F_, 2
	LEN 12
	NOTE F_, 2
	NOTE F_, 2
	WAIT2
	LEN 24
	NOTE F_, 3
	LEN 12
	NOTE F_, 2
	LEN 24
	NOTE F_, 2
	LEN 12
	NOTE F_, 2
	NOTE F_, 2
	WAIT2
	LEN 24
	NOTE F_, 3
	LEN 12
	NOTE G_, 2
	LEN 24
	NOTE G_, 2
	LEN 12
	NOTE G_, 2
	NOTE G_, 2
	WAIT2
	LEN 24
	NOTE G_, 3
	LEN 12
	NOTE G_, 2
	LEN 24
	NOTE G_, 2
	LEN 12
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 2
	VOLENV 15, $13, $1F, $14
	RELEASE $02, $11
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	NOTE C_, 3
	LEN 12
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	NOTE C_, 3
	LEN 12
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NEXT
Pat_54A3:
	VOLENV 15, $10, $1F, $12
	LEN 12
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	NOTE C_, 2
	WAIT2
	LEN 24
	NOTE C_, 3
	LEN 12
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	NOTE C_, 2
	WAIT2
	LEN 24
	NOTE C_, 3
	LEN 12
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	NOTE C_, 2
	WAIT2
	LEN 24
	NOTE C_, 3
	LEN 12
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	NOTE C_, 2
	WAIT2
	LEN 24
	NOTE C_, 3
	LEN 12
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	NOTE C_, 2
	WAIT2
	LEN 24
	NOTE C_, 3
	LEN 12
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	NOTE C_, 2
	WAIT2
	LEN 24
	NOTE C_, 3
	LEN 12
	NOTE G_, 2
	LEN 24
	NOTE G_, 2
	LEN 12
	NOTE G_, 2
	NOTE G_, 2
	WAIT2
	LEN 24
	NOTE G_, 3
	LEN 12
	NOTE G_, 2
	LEN 24
	NOTE G_, 2
	LEN 12
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 3
	NEXT
Pat_54F8:
	NOTE Gsh, 2
	LEN 24
	NOTE Gsh, 2
	LEN 12
	NOTE Gsh, 2
	NOTE Gsh, 3
	WAIT2
	LEN 24
	NOTE Gsh, 2
	LEN 12
	NOTE F_, 2
	LEN 24
	NOTE F_, 2
	LEN 12
	NOTE F_, 2
	NOTE F_, 3
	WAIT2
	LEN 24
	NOTE F_, 2
	LEN 12
	NOTE G_, 2
	LEN 24
	NOTE G_, 2
	LEN 12
	NOTE G_, 2
	NOTE G_, 3
	WAIT2
	LEN 24
	NOTE G_, 2
	LEN 12
	NOTE G_, 2
	LEN 24
	NOTE G_, 2
	LEN 12
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 3
	NEXT
Pat_5520:
	LEN 12
	NOTE Gsh, 2
	LEN 24
	NOTE Gsh, 2
	LEN 12
	NOTE Gsh, 2
	NOTE Gsh, 3
	WAIT2
	LEN 24
	NOTE Gsh, 2
	LEN 12
	NOTE F_, 2
	LEN 24
	NOTE F_, 2
	LEN 12
	NOTE F_, 2
	NOTE F_, 3
	WAIT2
	LEN 24
	NOTE F_, 2
	LEN 12
	NOTE G_, 2
	LEN 24
	NOTE G_, 2
	LEN 12
	NOTE G_, 2
	NOTE G_, 3
	WAIT2
	LEN 24
	NOTE G_, 2
	LEN 12
	NOTE G_, 2
	LEN 24
	NOTE G_, 2
	LEN 12
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 3
	VOLENV 15, $13, $1F, $12
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	NOTE C_, 3
	WAIT2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	NOTE C_, 3
	WAIT2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	NOTE C_, 2
	WAIT2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	LEN 24
	NOTE C_, 2
	LEN 12
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 2
	NEXT
Pat_5574:
	RELEASE $02, $01
	VIBRATO $0C, $01, $05
	INSTR 0
	LEN 12
	NOTE C_, 3
	LEN 24
	NOTE C_, 3
	LEN 12
	NOTE C_, 3
	LEN 24
	NOTE C_, 3
	NOTE G_, 3
	LEN 12
	NOTE C_, 3
	LEN 24
	NOTE C_, 3
	LEN 12
	NOTE C_, 3
	LEN 24
	NOTE C_, 3
	NOTE G_, 3
	LEN 12
	NOTE C_, 3
	LEN 24
	NOTE C_, 3
	LEN 12
	NOTE C_, 3
	LEN 24
	NOTE C_, 3
	NOTE G_, 3
	LEN 12
	NOTE C_, 3
	LEN 24
	NOTE C_, 3
	LEN 12
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 4
	LEN 24
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	INSTR 1
	LEN 12
	NOTE G_, 3
	NOTE Fsh, 4
	LEN 24
	NOTE G_, 4
	INSTR 0
	LEN 12
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 4
	LEN 24
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	INSTR 1
	LEN 12
	NOTE G_, 3
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NEXT
Pat_55C2:
	INSTR 1
	LEN 12
	NOTE D_, 4
	INSTR 0
	NOTE D_, 4
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 4
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 4
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 4
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 4
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 4
	INSTR 1
	NOTE D_, 4
	NOTE Dsh, 4
	LEN 24
	NOTE F_, 4
	LEN 12
	NOTE D_, 4
	INSTR 0
	NOTE D_, 4
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 4
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 4
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 4
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 4
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 4
	INSTR 1
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	NOTE D_, 4
	LEN 24
	NOTE Dsh, 4
	LEN 12
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NEXT
Pat_562F:
	INSTR 2
	LEN 36
	NOTE C_, 4
	INSTR 0
	LEN 12
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE D_, 4
	LEN 24
	NOTE Dsh, 4
	LEN 12
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE C_, 3
	NOTE C_, 4
	NOTE D_, 4
	LEN 24
	NOTE Dsh, 4
	LEN 12
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 4
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE G_, 3
	NEXT
Pat_5674:
	INSTR 0
	LEN 12
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	LEN 24
	NOTE Gsh, 4
	NOTE Gsh, 3
	LEN 12
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 4
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 4
	NOTE D_, 4
	NEXT
Pat_5697:
	INSTR 0
	LEN 12
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	LEN 24
	NOTE Gsh, 4
	NOTE Gsh, 3
	LEN 12
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 4
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 5
	LEN 24
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	INSTR 1
	LEN 12
	NOTE C_, 4
	NOTE D_, 4
	LEN 24
	NOTE Dsh, 4
	INSTR 0
	LEN 12
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 5
	LEN 24
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	INSTR 1
	LEN 12
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NEXT
Pat_56DA:
	RELEASE $02, $21
	DRUMS $0C, DrumPat_5871
	VIBRATO $0C, $01, $05
	INSTR 1
	LEN 12
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	NOTE D_, 4
	LEN 24
	NOTE Dsh, 4
	LEN 12
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	NOTE D_, 4
	LEN 24
	NOTE Dsh, 4
	LEN 12
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NEXT
Pat_574A:
	INSTR 1
	LEN 12
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 5
	NOTE F_, 4
	INSTR 0
	NOTE F_, 4
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 4
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 4
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 4
	INSTR 1
	NOTE F_, 4
	NOTE G_, 4
	LEN 24
	NOTE Gsh, 4
	LEN 12
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 5
	NOTE F_, 4
	INSTR 0
	NOTE F_, 4
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 4
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 4
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 4
	INSTR 1
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	DRUMS $0C, DrumPat_587A
	INSTR 2
	LEN 24
	NOTE C_, 4
	INSTR 1
	LEN 12
	NOTE Fsh, 4
	NOTE G_, 4
	LEN 24
	NOTE Gsh, 4
	LEN 12
	NOTE G_, 4
	NOTE Fsh, 4
	LEN 24
	NOTE C_, 4
	LEN 12
	NOTE Fsh, 4
	NOTE G_, 4
	LENGTH $30
	NOTE Gsh, 4
	INSTR 2
	LEN 24
	NOTE C_, 4
	INSTR 1
	LEN 12
	NOTE Fsh, 4
	NOTE G_, 4
	LEN 24
	NOTE Gsh, 4
	LEN 12
	NOTE G_, 4
	NOTE Fsh, 4
	LEN 24
	NOTE C_, 4
	LEN 12
	NOTE Fsh, 4
	NOTE G_, 4
	LEN 24
	NOTE Gsh, 4
	NOTE G_, 4
	NEXT
Pat_57AA:
	RELEASE $00
	DRUMS $0C, DrumPat_5871
	INSTR 3
	LEN 2
	NOTE A_, 4
	NOTE Ash, 4
	NOTE B_, 4
	LEN 30
	NOTE C_, 5
	LEN 36
	NOTE G_, 4
	LEN 24
	NOTE C_, 5
	LEN 36
	NOTE B_, 4
	NOTE G_, 4
	LEN 24
	NOTE B_, 4
	LEN 36
	NOTE Ash, 4
	NOTE G_, 4
	LEN 24
	NOTE Ash, 4
	LEN 36
	NOTE A_, 4
	NOTE F_, 4
	LEN 24
	NOTE Gsh, 4
	LENGTH $78
	NOTE G_, 4
	LEN 12
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 6
	NOTE G_, 4
	NOTE Gsh, 4
	LENGTH $60
	NOTE G_, 4
	LEN 12
	NOTE G_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE D_, 4
	NEXT
Pat_57E3:
	LENGTH $48
	NOTE C_, 4
	LEN 12
	NOTE Dsh, 4
	NOTE D_, 4
	LENGTH $3C
	NOTE C_, 4
	LEN 12
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	LENGTH $30
	NOTE B_, 3
	LENGTH $78
	NOTE G_, 3
	LEN 24
	NOTE G_, 4
	NEXT
Pat_57F9:
	LENGTH $3C
	NOTE C_, 4
	LEN 12
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE C_, 4
	LEN 36
	NOTE G_, 4
	NOTE F_, 4
	LEN 24
	NOTE C_, 4
	LEN 12
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	LEN 6
	NOTE D_, 4
	NOTE Dsh, 4
	LENGTH $30
	NOTE D_, 4
	LEN 12
	NOTE C_, 4
	NOTE B_, 3
	NOTE Gsh, 3
	INSTR 1
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE Dsh, 4
	NOTE G_, 3
	INSTR 0
	NOTE G_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE G_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE G_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE G_, 3
	INSTR 1
	NOTE G_, 3
	NOTE B_, 3
	LEN 24
	NOTE C_, 4
	LEN 12
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE Dsh, 4
	NOTE G_, 3
	INSTR 0
	NOTE G_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE G_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE G_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE G_, 3
	INSTR 1
	NOTE G_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NEXT

; Instrument table 3, entries 1..4 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr3_0
	dw Instr3_1
	dw Instr3_2
	dw Instr3_3
Instr3_0:
	HWENV $B1, $00
	ARP 0
	DUTY_75
	RELEASE $00
	END
Instr3_1:
	HWENV $F2, $04, $B0
	ARP 0
	DUTY_75
	RELEASE $02, $21
	END
Instr3_3:
	HWENV $6F, $24, $C7
	END
Instr3_2:
	ARP 5
	HWENV $F3, $00
	AUTODUTY $02
	END
DrumPat_5871:
	db 6, 0, 8, 6, 10, 0, 8, 6
	db DRUM_LOOP
DrumPat_587A:
	db 7, 0, 6, 6, 4, 0, 6, 6
	db 4, 0, 6, 6, 4, 0, 9, 9
	db DRUM_LOOP

; Song 5: instrument table - (none set), arpeggio table 1 (the one SndInit sets)
PlaySong5:
	call StopAll
	ld de, Song5_Ch1
	call StartMusicCh1
	ld de, Song5_Ch3
	call StartMusicCh3
	ld de, Song5_Ch2
	jp StartMusicCh2
Song5_Ch1:
	dw Pat_58D0
	dw Pat_58D0
	dw Pat_58F5
	dw Pat_5904
	dw Pat_590D
	dw Pat_590D
	ORDER_LOOP Song5_Ch1
Song5_Ch3:
	dw Pat_591E
	dw Pat_5962
	dw Pat_5996
	dw Pat_59AB
	dw Pat_59E2
	dw Pat_59E2
	ORDER_LOOP Song5_Ch3
Song5_Ch2:
	dw Pat_5A14
	dw Pat_5A58
	dw Pat_5A8B
	dw Pat_5A92
	dw Pat_5AC9
	dw Pat_5AC9
	ORDER_LOOP Song5_Ch2
Pat_58D0:
	HWENV $F3, $08, $51
	DUTY_75
	ARP 0
	DUTY_50
	LEN 9
	REPEAT 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Ash, 2
	NOTE C_, 3
	REPEAT_END
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE F_, 2
	NOTE F_, 3
	NOTE F_, 2
	REPEAT 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Ash, 2
	NOTE C_, 3
	REPEAT_END
	NOTE Dsh, 2
	NOTE Dsh, 3
	NOTE Dsh, 2
	NOTE F_, 3
	NOTE C_, 3
	NOTE F_, 2
	NEXT
Pat_58F5:
	REPEAT 7
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE C_, 3
	NOTE D_, 3
	REPEAT_END
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE E_, 2
	NEXT
Pat_5904:
	REPEAT 8
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Ash, 2
	NOTE C_, 3
	REPEAT_END
	NEXT
Pat_590D:
	REPEAT 4
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE Ash, 2
	NOTE C_, 3
	REPEAT_END
	REPEAT 4
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE C_, 3
	NOTE D_, 3
	REPEAT_END
	NEXT
Pat_591E:
	WAVE Wave_7BFD
	VOLENV 12, $11, $15, $12
	ARP 0
	VIBRATO $09, $01, $05
	RELEASE $01, $11
	LEN 27
	NOTE G_, 4
	LEN 9
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 27
	NOTE G_, 4
	LEN 9
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 27
	NOTE G_, 4
	LEN 9
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 18
	NOTE Ash, 4
	LEN 9
	NOTE Ash, 4
	LEN 18
	NOTE A_, 4
	LEN 9
	NOTE F_, 4
	LEN 27
	NOTE G_, 4
	LEN 9
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 27
	NOTE G_, 4
	LEN 9
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 27
	NOTE G_, 4
	LEN 9
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 18
	NOTE Ash, 4
	LEN 9
	NOTE A_, 4
	LEN 18
	NOTE Ash, 4
	LEN 9
	NOTE C_, 5
	NEXT
Pat_5962:
	LEN 27
	NOTE G_, 4
	LEN 9
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 27
	NOTE G_, 4
	LEN 9
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 27
	NOTE G_, 4
	LEN 9
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 18
	NOTE Ash, 4
	LEN 9
	NOTE Ash, 4
	LEN 18
	NOTE A_, 4
	LEN 9
	NOTE F_, 4
	LEN 27
	NOTE G_, 4
	LEN 9
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 27
	NOTE G_, 4
	LEN 9
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 27
	NOTE G_, 4
	LEN 9
	NOTE G_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	LEN 18
	NOTE C_, 5
	LEN 9
	NOTE D_, 5
	NEXT
Pat_5996:
	LEN 27
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE B_, 3
	NOTE B_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE D_, 3
	NEXT
Pat_59AB:
	LEN 9
	NOTE G_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE C_, 5
	NOTE G_, 4
	LEN 18
	WAIT2
	LEN 9
	NOTE G_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE C_, 5
	NOTE G_, 4
	LEN 18
	WAIT2
	LEN 9
	NOTE G_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE C_, 5
	NOTE G_, 4
	WAIT2
	NOTE G_, 5
	NOTE G_, 5
	WAIT2
	NOTE F_, 5
	NOTE F_, 5
	WAIT2
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE Ash, 4
	NEXT
Pat_59E2:
	LEN 9
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE G_, 3
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE G_, 3
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE A_, 3
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE A_, 3
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE A_, 3
	NOTE D_, 4
	NEXT
Pat_5A14:
	HWENV $F1, $04, $90
	RELEASE $02, $92
	DUTY_75
	VIBRATO $09, $01, $05
	ARP 0
	DRUMS $09, DrumPat_5B00
	LEN 27
	NOTE C_, 5
	LEN 9
	WAIT2
	NOTE Ash, 4
	NOTE C_, 5
	LEN 27
	NOTE C_, 5
	LEN 9
	WAIT2
	NOTE Ash, 4
	NOTE C_, 5
	LEN 27
	NOTE C_, 5
	LEN 9
	WAIT2
	NOTE Ash, 4
	NOTE C_, 5
	LEN 18
	NOTE Dsh, 5
	LEN 9
	WAIT2
	NOTE D_, 5
	WAIT2
	NOTE Ash, 4
	LEN 27
	NOTE C_, 5
	LEN 9
	WAIT2
	NOTE Ash, 4
	NOTE C_, 5
	LEN 27
	NOTE C_, 5
	LEN 9
	WAIT2
	NOTE Ash, 4
	NOTE C_, 5
	LEN 27
	NOTE C_, 5
	LEN 9
	WAIT2
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Dsh, 5
	WAIT2
	NOTE D_, 5
	LEN 18
	NOTE Dsh, 5
	LEN 9
	NOTE F_, 5
	NEXT
Pat_5A58:
	LEN 27
	NOTE C_, 5
	LEN 9
	WAIT2
	NOTE Ash, 4
	NOTE C_, 5
	LEN 27
	NOTE C_, 5
	LEN 9
	WAIT2
	NOTE Ash, 4
	NOTE C_, 5
	LEN 27
	NOTE C_, 5
	LEN 9
	WAIT2
	NOTE Ash, 4
	NOTE C_, 5
	LEN 18
	NOTE Dsh, 5
	LEN 9
	WAIT2
	NOTE D_, 5
	WAIT2
	NOTE Ash, 4
	LEN 27
	NOTE C_, 5
	LEN 9
	WAIT2
	NOTE Ash, 4
	NOTE C_, 5
	LEN 27
	NOTE C_, 5
	LEN 9
	WAIT2
	NOTE Ash, 4
	NOTE C_, 5
	LEN 27
	NOTE C_, 5
	LEN 9
	WAIT2
	NOTE C_, 5
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE Dsh, 5
	LEN 18
	NOTE F_, 5
	LEN 9
	NOTE G_, 5
	NEXT
Pat_5A8B:
	LENGTH $6C
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NEXT
Pat_5A92:
	LEN 9
	NOTE C_, 5
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE C_, 5
	WAIT2
	LEN 18
	NOTE C_, 5
	LEN 9
	NOTE F_, 5
	NOTE C_, 5
	LEN 18
	WAIT2
	LEN 9
	NOTE C_, 5
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE C_, 5
	WAIT2
	LEN 18
	NOTE C_, 5
	LEN 9
	NOTE F_, 5
	NOTE C_, 5
	LEN 18
	WAIT2
	LEN 9
	NOTE C_, 5
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE C_, 5
	WAIT2
	LEN 18
	NOTE C_, 5
	LEN 9
	NOTE F_, 5
	NOTE C_, 5
	WAIT2
	NOTE Ash, 5
	NOTE Ash, 5
	WAIT2
	NOTE A_, 5
	NOTE A_, 5
	WAIT2
	NOTE G_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NEXT
Pat_5AC9:
	ARP_OFF
	HWENV $F3, $00
	DUTY_50
	LEN 9
	NOTE C_, 4
	LEN 18
	NOTE G_, 4
	NOTE G_, 4
	LEN 9
	NOTE C_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 27
	NOTE G_, 4
	LEN 9
	NOTE C_, 4
	LEN 18
	NOTE G_, 4
	NOTE G_, 4
	LEN 9
	NOTE C_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 27
	NOTE G_, 4
	LEN 9
	NOTE D_, 4
	LEN 18
	NOTE A_, 4
	NOTE A_, 4
	LEN 9
	NOTE D_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 27
	NOTE A_, 4
	LEN 9
	NOTE D_, 4
	LEN 18
	NOTE A_, 4
	NOTE A_, 4
	LEN 9
	NOTE D_, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NEXT
DrumPat_5B00:
	db DRUM_LEVEL + 13, DRUM_REPEAT + 8, 0, 9, DRUM_REPEAT_END, DRUM_REPEAT + 8, 0, 9
	db DRUM_REPEAT_END, DRUM_REPEAT + 5, 0, 9, DRUM_REPEAT_END, 0, DRUM_TEMPO + 4, 9
	db DRUM_TEMPO + 5, 9, DRUM_TEMPO + 9, 9, 9, 9, 9, DRUM_LOOP

; Song 6: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong6:
	call StopAll
	ld a, $5D
	ld [wInstrTableHi], a
	ld a, $D5
	ld [wInstrTable], a
	ld de, Song6_Ch1
	call StartMusicCh1
	ld de, Song6_Ch2
	call StartMusicCh2
	ld de, Song6_Ch3
	jp StartMusicCh3
Song6_Ch1:
	dw Pat_5B7F
	dw Pat_5B8A
	dw Pat_5B7F
	dw Pat_5B8A
	dw Pat_5BC8
	dw Pat_5BE6
	dw Pat_5BC8
	dw Pat_5BE6
	dw Pat_5B8A
	dw Pat_5B8A
	ORDER_LOOP Song6_Ch1
Song6_Ch2:
	dw Pat_5C06
	dw Pat_5C51
	dw Pat_5C06
	dw Pat_5C51
	dw Pat_5C88
	dw Pat_5C9C
	dw Pat_5CBB
	dw Pat_5CD4
	dw Pat_5CF3
	dw Pat_5CF1
	ORDER_LOOP Song6_Ch2
Song6_Ch3:
	dw Pat_5D49
	dw Pat_5D53
	dw Pat_5D49
	dw Pat_5D53
	dw Pat_5D81
	dw Pat_5DA8
	dw Pat_5D81
	dw Pat_5DC0
	dw Pat_5D53
	dw Pat_5D53
	ORDER_LOOP Song6_Ch3
Pat_5B7F:
	RELEASE $01, $00
	VIBRATO $09, $02, $05
	DRUMS $09, DrumPat_5DF3
Pat_5B8A:
	INSTR 0
	LEN 36
	NOTE C_, 2
	INSTR 1
	LEN 18
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	LEN 36
	NOTE C_, 2
	INSTR 1
	LEN 18
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	LEN 27
	NOTE C_, 2
	LEN 9
	NOTE C_, 2
	INSTR 1
	LEN 18
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	LEN 36
	NOTE C_, 2
	INSTR 1
	LEN 18
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	LEN 36
	NOTE C_, 2
	INSTR 1
	LEN 18
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	LEN 36
	NOTE C_, 2
	INSTR 1
	LEN 18
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	LEN 27
	NOTE C_, 2
	LEN 9
	NOTE C_, 2
	INSTR 1
	LEN 18
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	LEN 36
	NOTE C_, 2
	INSTR 1
	LEN 18
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	NEXT
Pat_5BC8:
	INSTR 0
	LEN 27
	NOTE Ash, 2
	NOTE Ash, 2
	LEN 18
	NOTE Ash, 2
	INSTR 1
	NOTE G_, 3
	INSTR 2
	NOTE A_, 3
	NOTE A_, 3
	LEN 9
	NOTE F_, 3
	NOTE F_, 3
	INSTR 0
	LEN 27
	NOTE F_, 2
	NOTE F_, 2
	LEN 18
	NOTE F_, 2
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 2
	NOTE F_, 3
	LEN 9
	NOTE F_, 3
	NOTE F_, 3
	NEXT
Pat_5BE6:
	INSTR 0
	LEN 36
	NOTE C_, 2
	INSTR 1
	LEN 18
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	LEN 36
	NOTE C_, 2
	INSTR 1
	LEN 18
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	LEN 27
	NOTE C_, 2
	LEN 9
	NOTE C_, 2
	INSTR 1
	LEN 18
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	LEN 36
	NOTE C_, 2
	INSTR 1
	LEN 18
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	NEXT
Pat_5C06:
	VIBRATO $09, $01, $05
	HWENV $C0, $00
	RELEASE $02, $83
	DUTY_75
	ARP 1
	LENGTH $36
	NOTE Ash, 4
	ARP 0
	LEN 18
	NOTE Ash, 4
	LENGTH $3F
	NOTE G_, 4
	LEN 9
	WAIT2
	ARP 1
	LEN 18
	NOTE Gsh, 4
	ARP 0
	LEN 9
	NOTE A_, 4
	LEN 18
	NOTE Ash, 4
	LEN 9
	NOTE A_, 4
	LENGTH $36
	NOTE F_, 4
	LEN 9
	NOTE D_, 4
	NOTE E_, 4
	LEN 18
	NOTE F_, 4
	LEN 9
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE F_, 4
	NOTE G_, 4
	WAIT2
	NOTE G_, 4
	LEN 18
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 36
	NOTE D_, 4
	LEN 9
	WAIT2
	NOTE D_, 4
	NOTE F_, 4
	NOTE A_, 4
	LEN 18
	NOTE Ash, 4
	LEN 9
	NOTE A_, 4
	LEN 18
	NOTE Ash, 4
	LEN 9
	NOTE A_, 4
	LEN 18
	NOTE F_, 4
	NEXT
Pat_5C51:
	ARP 1
	LENGTH $36
	NOTE Ash, 4
	ARP 0
	LEN 18
	NOTE Ash, 4
	LENGTH $3F
	NOTE G_, 4
	LEN 9
	WAIT2
	ARP 1
	LEN 18
	NOTE Gsh, 4
	ARP 0
	LEN 9
	NOTE A_, 4
	LEN 18
	NOTE Ash, 4
	LEN 9
	NOTE A_, 4
	LENGTH $36
	NOTE F_, 4
	LEN 9
	NOTE D_, 4
	NOTE E_, 4
	LEN 18
	NOTE F_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE E_, 4
	LEN 9
	NOTE F_, 4
	NOTE G_, 4
	WAIT2
	NOTE G_, 4
	LEN 18
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 36
	NOTE D_, 4
	LEN 18
	NOTE Ash, 3
	ARP 1
	NOTE C_, 4
	ARP 0
	LENGTH $36
	NOTE C_, 4
	LEN 18
	WAIT2
	NEXT
Pat_5C88:
	ARP 0
	LEN 27
	NOTE D_, 4
	NOTE E_, 4
	LEN 36
	NOTE F_, 4
	LEN 18
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	LEN 27
	NOTE A_, 3
	NOTE B_, 3
	LEN 36
	NOTE C_, 4
	LEN 18
	NOTE G_, 3
	NOTE C_, 4
	NOTE D_, 4
	NEXT
Pat_5C9C:
	ARP 0
	LEN 27
	NOTE D_, 4
	NOTE E_, 4
	LEN 18
	NOTE C_, 4
	LENGTH $36
	NOTE G_, 3
	LEN 18
	WAIT2
	LEN 9
	NOTE E_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 4
	NOTE A_, 4
	ARP 1
	NOTE Gsh, 4
	ARP 0
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NEXT
Pat_5CBB:
	ARP 1
	LEN 27
	NOTE Gsh, 4
	ARP 0
	NOTE C_, 5
	LEN 36
	NOTE D_, 5
	LEN 18
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE A_, 4
	LEN 9
	NOTE Ash, 4
	LEN 18
	NOTE A_, 4
	LEN 9
	NOTE F_, 4
	LEN 36
	NOTE C_, 4
	LEN 18
	NOTE G_, 3
	NOTE C_, 4
	NOTE D_, 4
	NEXT
Pat_5CD4:
	ARP 0
	LEN 27
	NOTE D_, 4
	NOTE E_, 4
	LEN 18
	NOTE C_, 4
	ARP 1
	LEN 45
	NOTE F_, 4
	LEN 9
	WAIT2
	ARP 0
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 18
	NOTE F_, 4
	LEN 9
	NOTE E_, 4
	LEN 18
	NOTE D_, 4
	LENGTH $3F
	NOTE C_, 4
	LEN 9
	WAIT2
	NEXT
Pat_5CF1:
	CH_TRANSPOSE $F4
Pat_5CF3:
	HWENV $B2, $00
	DUTY_50
	RELEASE $00
	ARP_OFF
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE E_, 5
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE E_, 5
	NOTE E_, 4
	NOTE E_, 5
	LEN 18
	NOTE F_, 4
	LEN 9
	NOTE F_, 5
	LEN 18
	NOTE F_, 4
	LEN 9
	NOTE F_, 5
	NOTE F_, 4
	NOTE F_, 5
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE G_, 5
	NOTE G_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE G_, 5
	NOTE G_, 4
	LEN 18
	NOTE F_, 4
	LEN 9
	NOTE F_, 5
	NOTE F_, 4
	NOTE F_, 3
	NOTE F_, 5
	NOTE F_, 4
	NOTE F_, 5
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE E_, 5
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE E_, 5
	NOTE E_, 4
	NOTE E_, 5
	LEN 18
	NOTE F_, 4
	LEN 9
	NOTE F_, 5
	LEN 18
	NOTE F_, 4
	LEN 9
	NOTE F_, 5
	NOTE F_, 4
	NOTE F_, 5
	LEN 18
	NOTE Ash, 4
	LEN 9
	NOTE Ash, 5
	NOTE Ash, 4
	NOTE Ash, 3
	NOTE Ash, 4
	NOTE Ash, 5
	NOTE Ash, 4
	LEN 18
	NOTE Gsh, 4
	LEN 9
	NOTE Gsh, 5
	NOTE Gsh, 4
	NOTE Gsh, 3
	NOTE Gsh, 5
	NOTE Gsh, 4
	NOTE Gsh, 5
	CH_TRANSPOSE $00
	NEXT
Pat_5D49:
	VOLENV 15, $11, $1F, $12
	ARP 11
	CH_TRANSPOSE $0C
	WAVE Wave_7D1D
Pat_5D53:
	LEN 18
	NOTE C_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE Ash, 3
	NOTE C_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE Ash, 3
	LEN 9
	NOTE C_, 3
	NOTE C_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE Ash, 3
	NOTE Ash, 3
	LEN 18
	NOTE C_, 4
	NOTE G_, 3
	NOTE Ash, 3
	NOTE F_, 3
	NOTE C_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE Ash, 3
	NOTE C_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE Ash, 3
	LEN 9
	NOTE C_, 3
	NOTE C_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE Ash, 3
	NOTE Ash, 3
	LEN 18
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE Ash, 3
	NEXT
Pat_5D81:
	DRUMS $09, DrumPat_5E15
	LEN 9
	NOTE Ash, 4
	NOTE F_, 4
	NOTE Ash, 3
	NOTE C_, 5
	NOTE F_, 4
	NOTE Ash, 3
	LEN 27
	NOTE D_, 5
	LEN 9
	NOTE Ash, 3
	LEN 18
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	LEN 9
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 3
	NOTE G_, 4
	NOTE C_, 4
	NOTE F_, 3
	LEN 27
	NOTE A_, 4
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	DRUMS $09, DrumPat_5DF3
	NEXT
Pat_5DA8:
	LEN 18
	NOTE C_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE Ash, 3
	NOTE C_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE Ash, 3
	LEN 9
	NOTE C_, 3
	NOTE C_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE Ash, 3
	NOTE Ash, 3
	LEN 18
	NOTE C_, 4
	NOTE G_, 3
	NOTE Ash, 3
	NOTE F_, 3
	NEXT
Pat_5DC0:
	NOTE C_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE Ash, 3
	NOTE C_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE Ash, 3
	LEN 9
	NOTE C_, 3
	NOTE C_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE Ash, 3
	NOTE Ash, 3
	LEN 18
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE Ash, 3
	NEXT

; Instrument table 4, entries 1..3 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr4_0
	dw Instr4_1
	dw Instr4_2
Instr4_0:
	HWENV $F2, $09, $84
	ARP 0
	DUTY_50
	END
Instr4_1:
	HWENV $F2, $04, $61
	GLIDE $FD
	DUTY_50
	END
Instr4_2:
	ARP 0
	HWENV $F1, $00
	GLIDE $FE
	END
DrumPat_5DF3:
	db DRUM_LEVEL + 13, 1, 0, 6, 0, 9, 0, 1
	db 0, 1, 0, 6, 0, 9, 0, 1
	db 0, 1, 0, 6, 1, 9, 0, 1
	db 0, 1, 0, 6, 0, 9, 0, 1
	db 0, DRUM_LOOP
DrumPat_5E15:
	db DRUM_LEVEL + 15, 7, 0, 0, 7, 0, 0, 7
	db 0, DRUM_LEVEL + 13, 9, 0, 9, 0, 9, 0
	db 9, 9, DRUM_LOOP

; Unreferenced (1 bytes)
	db $FF

; Song 7: instrument table 5, arpeggio table 1 (the one SndInit sets)
PlaySong7:
	ld a, $61
	ld [wInstrTableHi], a
	ld a, $80
	ld [wInstrTable], a
	call StopAll
	ld de, Song7_Ch1
	call StartMusicCh1
	ld de, Song7_Ch3
	call StartMusicCh3
	ld de, Song7_Ch2
	jp StartMusicCh2
Song7_Ch1:
	dw Pat_5E62
	ORDER_LOOP Song7_Ch1
Song7_Ch3:
	dw Pat_5E9F
	dw Pat_5E9F
	dw Pat_5EF5
	dw Pat_5F71
	dw Pat_5FB1
	ORDER_LOOP Song7_Ch3
Song7_Ch2:
	dw Pat_5FEF
	ORDER_LOOP Song7_Ch2
Pat_5E62:
	HWENV $F3, $00
	ARP 0
	DUTY_50
	VIBRATO $0B, $02, $04
	RELEASE $02, $51
	LEN 22
	REPEAT 6
	NOTE C_, 2
	NOTE C_, 3
	REPEAT_END
	NOTE C_, 2
	NOTE C_, 3
	LEN 11
	NOTE C_, 2
	NOTE D_, 2
	NOTE Dsh, 2
	NOTE D_, 2
	LEN 22
	REPEAT 6
	NOTE C_, 2
	NOTE C_, 3
	REPEAT_END
	NOTE C_, 2
	NOTE C_, 3
	LEN 11
	NOTE C_, 2
	NOTE D_, 2
	NOTE Dsh, 2
	NOTE E_, 2
	LEN 22
	REPEAT 6
	NOTE F_, 2
	NOTE F_, 3
	REPEAT_END
	NOTE F_, 2
	NOTE F_, 3
	LEN 11
	NOTE Gsh, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE Dsh, 2
	LEN 22
	REPEAT 6
	NOTE C_, 2
	NOTE C_, 3
	REPEAT_END
	NOTE Gsh, 2
	NOTE G_, 2
	LEN 11
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 3
	NEXT
Pat_5E9F:
	WAVE Wave_7BFD
	INSTR 0
	LEN 11
	REPEAT 6
	NOTE C_, 3
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	REPEAT_END
	NOTE C_, 3
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	NOTE C_, 3
	NOTE D_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE D_, 3
	REPEAT 6
	NOTE C_, 3
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	REPEAT_END
	NOTE C_, 3
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	NOTE C_, 3
	NOTE D_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	REPEAT 6
	NOTE F_, 3
	NOTE F_, 4
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 4
	REPEAT_END
	NOTE F_, 3
	NOTE F_, 4
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 4
	NOTE F_, 3
	NOTE G_, 3
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE G_, 3
	REPEAT 6
	NOTE C_, 3
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	REPEAT_END
	NOTE C_, 3
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 4
	NOTE C_, 3
	NOTE D_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE D_, 3
	NEXT
Pat_5EF5:
	LEN 11
	INSTR 2
	NOTE Dsh, 4
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE F_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE G_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE C_, 5
	INSTR 0
	NOTE C_, 3
	INSTR 2
	NOTE Ash, 4
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE F_, 4
	NOTE G_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Ash, 4
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Dsh, 4
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE F_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE G_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE C_, 5
	INSTR 0
	NOTE C_, 3
	INSTR 2
	NOTE Ash, 4
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE G_, 4
	NOTE F_, 4
	INSTR 0
	NOTE D_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE D_, 3
	INSTR 2
	NOTE Dsh, 4
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE F_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE G_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE C_, 5
	INSTR 0
	NOTE C_, 3
	INSTR 2
	NOTE Ash, 4
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE F_, 4
	NOTE G_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Ash, 4
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Dsh, 4
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE F_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE G_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE C_, 5
	INSTR 0
	NOTE C_, 3
	INSTR 2
	NOTE Ash, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE G_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	NEXT
Pat_5F71:
	INSTR 2
	LEN 11
	NOTE Gsh, 4
	INSTR 0
	NOTE F_, 4
	INSTR 2
	NOTE Ash, 4
	INSTR 0
	NOTE F_, 4
	INSTR 2
	NOTE C_, 5
	INSTR 0
	NOTE F_, 4
	INSTR 1
	NOTE F_, 4
	INSTR 2
	NOTE F_, 5
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE Dsh, 5
	INSTR 1
	NOTE F_, 4
	INSTR 2
	NOTE Ash, 4
	NOTE C_, 5
	INSTR 0
	NOTE F_, 4
	INSTR 2
	NOTE Dsh, 5
	INSTR 0
	NOTE F_, 4
	INSTR 2
	NOTE Gsh, 4
	INSTR 0
	NOTE F_, 4
	INSTR 2
	NOTE Ash, 4
	INSTR 0
	NOTE F_, 4
	INSTR 2
	NOTE C_, 5
	INSTR 0
	NOTE F_, 4
	INSTR 1
	NOTE F_, 4
	INSTR 2
	NOTE F_, 5
	INSTR 0
	NOTE F_, 3
	INSTR 2
	NOTE Dsh, 5
	INSTR 1
	NOTE F_, 4
	INSTR 2
	NOTE G_, 4
	NOTE Gsh, 4
	INSTR 0
	NOTE G_, 3
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE G_, 3
	NEXT
Pat_5FB1:
	INSTR 2
	LEN 11
	NOTE Dsh, 4
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE F_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE G_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE C_, 5
	INSTR 0
	NOTE C_, 3
	INSTR 2
	NOTE Ash, 4
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE F_, 4
	NOTE G_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Ash, 4
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE Dsh, 4
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE F_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 2
	NOTE G_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE C_, 5
	INSTR 0
	NOTE C_, 3
	INSTR 2
	NOTE Ash, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE G_, 4
	INSTR 0
	NOTE D_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE D_, 3
	NEXT
Pat_5FEF:
	RELEASE $01, $51
	DRUMS $0B, DrumPat_619A
	HWENV $E2, $0B, $82
	DUTY_50
	ARP 12
	VIBRATO $0B, $01, $04
	LEN 11
	NOTE C_, 4
	LEN 22
	NOTE Dsh, 4
	LEN 11
	NOTE Dsh, 4
	NOTE D_, 4
	LEN 22
	NOTE F_, 4
	LEN 11
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 22
	NOTE G_, 4
	LEN 11
	NOTE G_, 4
	NOTE F_, 4
	LEN 22
	NOTE Gsh, 4
	LEN 11
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE D_, 4
	LEN 22
	NOTE Dsh, 4
	NOTE C_, 4
	LEN 11
	NOTE C_, 4
	LEN 22
	NOTE Dsh, 4
	LEN 11
	NOTE Dsh, 4
	NOTE D_, 4
	LEN 22
	NOTE F_, 4
	LEN 11
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 22
	NOTE G_, 4
	LEN 11
	NOTE G_, 4
	NOTE F_, 4
	LEN 22
	NOTE Gsh, 4
	LEN 11
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE D_, 4
	LEN 44
	NOTE C_, 4
	LEN 11
	NOTE F_, 4
	LEN 22
	NOTE Gsh, 4
	LEN 11
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 22
	NOTE Ash, 4
	LEN 11
	NOTE Ash, 4
	NOTE Gsh, 4
	LEN 22
	NOTE C_, 5
	LEN 11
	NOTE C_, 5
	NOTE Ash, 4
	LEN 22
	NOTE Csh, 5
	LEN 11
	NOTE Csh, 5
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE G_, 4
	LEN 22
	NOTE Gsh, 4
	NOTE F_, 4
	LEN 11
	NOTE C_, 4
	LEN 22
	NOTE Dsh, 4
	LEN 11
	NOTE Dsh, 4
	NOTE D_, 4
	LEN 22
	NOTE F_, 4
	LEN 11
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 22
	NOTE G_, 4
	LEN 11
	NOTE G_, 4
	NOTE F_, 4
	LEN 22
	NOTE Gsh, 4
	LEN 11
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE D_, 4
	LEN 44
	NOTE C_, 4
	HWENV $F1, $00
	ARP 8
	DUTY_12
	REPEAT 2
	LEN 11
	NOTE C_, 5
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 22
	NOTE G_, 4
	LEN 11
	NOTE C_, 5
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 22
	NOTE Dsh, 4
	LEN 11
	NOTE C_, 5
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE C_, 4
	LEN 22
	NOTE C_, 5
	REPEAT_END
	LEN 11
	NOTE F_, 5
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	LEN 22
	NOTE C_, 5
	LEN 11
	NOTE F_, 5
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	LEN 22
	NOTE Gsh, 4
	LEN 11
	NOTE F_, 5
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE F_, 4
	LEN 22
	NOTE F_, 5
	LEN 11
	NOTE C_, 5
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 22
	NOTE G_, 4
	LEN 11
	NOTE C_, 5
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 22
	NOTE Dsh, 4
	LEN 11
	NOTE C_, 5
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE C_, 4
	LEN 22
	NOTE C_, 5
	HWENV $E3, $00
	ARP 0
	DUTY_75
	LEN 11
	NOTE C_, 4
	WAIT2
	NOTE D_, 4
	WAIT2
	LEN 33
	NOTE Dsh, 4
	LEN 11
	NOTE G_, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	NOTE D_, 4
	NOTE Dsh, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE D_, 4
	WAIT2
	LEN 33
	NOTE Dsh, 4
	LEN 11
	NOTE G_, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	NOTE D_, 4
	LEN 44
	NOTE Ash, 3
	LEN 11
	NOTE C_, 4
	WAIT2
	NOTE D_, 4
	WAIT2
	LEN 33
	NOTE Dsh, 4
	LEN 11
	NOTE G_, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	NOTE D_, 4
	NOTE Dsh, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE D_, 4
	WAIT2
	LEN 33
	NOTE Dsh, 4
	LEN 11
	NOTE G_, 4
	WAIT2
	NOTE F_, 4
	NOTE D_, 4
	NOTE Ash, 3
	LEN 33
	NOTE C_, 4
	LEN 11
	WAIT2
	LEN 11
	NOTE F_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	LEN 33
	NOTE Gsh, 4
	LEN 11
	NOTE C_, 5
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE G_, 4
	NOTE Gsh, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	LEN 33
	NOTE Gsh, 4
	LEN 11
	NOTE C_, 5
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE Ash, 4
	LEN 44
	NOTE C_, 5
	LEN 11
	NOTE C_, 4
	WAIT2
	NOTE D_, 4
	WAIT2
	LEN 33
	NOTE Dsh, 4
	LEN 11
	NOTE G_, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	NOTE D_, 4
	NOTE Dsh, 4
	WAIT2
	NOTE F_, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE D_, 4
	WAIT2
	LEN 33
	NOTE Dsh, 4
	LEN 11
	NOTE G_, 4
	WAIT2
	NOTE F_, 4
	NOTE D_, 4
	NOTE Ash, 3
	LEN 44
	NOTE C_, 4
	NEXT

; Instrument table 5, entries 1..3 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr5_0
	dw Instr5_1
	dw Instr5_2
Instr5_0:
	VOLENV 15, $11, $1F, $11
	ARP 0
	END
Instr5_1:
	VOLENV 15, $12, $1F, $11
	ARP 5
	END
Instr5_2:
	VOLENV 15, $11, $1F, $12
	ARP 0
	END
DrumPat_619A:
	db DRUM_LEVEL + 13, DRUM_REPEAT + 2, DRUM_TEMPO + 5, 6, DRUM_TEMPO + 6, 6, DRUM_TEMPO + 5, 6
	db DRUM_TEMPO + 6, 0, DRUM_TEMPO + 5, 6, DRUM_TEMPO + 6, 0, DRUM_TEMPO + 5, 6
	db DRUM_TEMPO + 6, 0, DRUM_TEMPO + 5, 6, DRUM_TEMPO + 6, 0, DRUM_TEMPO + 5, 6
	db DRUM_TEMPO + 6, 0, DRUM_TEMPO + 5, 6, DRUM_TEMPO + 6, 6, DRUM_TEMPO + 5, 6
	db DRUM_TEMPO + 6, 0, DRUM_REPEAT_END, DRUM_TEMPO + 5, 6, DRUM_TEMPO + 6, 6, DRUM_TEMPO + 5
	db 6, DRUM_TEMPO + 6, 0, DRUM_TEMPO + 5, 6, DRUM_TEMPO + 6, 0, DRUM_TEMPO + 5
	db 6, DRUM_TEMPO + 6, 6, DRUM_TEMPO + 5, 6, DRUM_TEMPO + 6, 0, DRUM_TEMPO + 5
	db 6, DRUM_TEMPO + 6, 6, DRUM_TEMPO + 5, 6, DRUM_TEMPO + 6, 0, DRUM_TEMPO + 5
	db 6, DRUM_TEMPO + 6, 0, DRUM_TEMPO + 5, 6, DRUM_TEMPO + 6, 6, DRUM_TEMPO + 5
	db 6, DRUM_TEMPO + 6, 0, DRUM_TEMPO + 5, 6, DRUM_TEMPO + 6, 0, DRUM_TEMPO + 5
	db 6, DRUM_TEMPO + 6, 0, DRUM_TEMPO + 5, 6, DRUM_TEMPO + 6, 0, DRUM_TEMPO + 5
	db 6, DRUM_TEMPO + 6, 0, DRUM_TEMPO + 5, 6, DRUM_TEMPO + 6, 6, DRUM_TEMPO + 5
	db 6, DRUM_TEMPO + 6, 6, DRUM_LOOP

; Song 8: instrument table 6, arpeggio table 1 (the one SndInit sets)
PlaySong8:
	ld a, $64
	ld [wInstrTableHi], a
	ld a, $1A
	ld [wInstrTable], a
	call StopAll
	ld de, Song8_Ch1
	call StartMusicCh1
	ld de, Song8_Ch3
	call StartMusicCh3
	ld de, Song8_Ch2
	jp StartMusicCh2
Song8_Ch1:
	dw Pat_622F
	ORDER_LOOP Song8_Ch1
Song8_Ch3:
	dw Pat_62ED
	ORDER_LOOP Song8_Ch3
Song8_Ch2:
	dw Pat_6333
	ORDER_LOOP Song8_Ch2
Pat_622F:
	REPEAT 8
	INSTR 0
	LEN 16
	NOTE C_, 2
	INSTR 1
	LEN 8
	NOTE C_, 3
	INSTR 0
	LEN 16
	NOTE C_, 2
	INSTR 1
	LEN 8
	NOTE C_, 3
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE C_, 3
	REPEAT_END
	REPEAT 3
	INSTR 0
	LEN 16
	NOTE F_, 2
	INSTR 1
	LEN 8
	NOTE F_, 3
	INSTR 0
	LEN 16
	NOTE F_, 2
	INSTR 1
	LEN 8
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	REPEAT_END
	INSTR 0
	LEN 16
	NOTE F_, 2
	LEN 8
	NOTE F_, 2
	LEN 16
	NOTE Gsh, 2
	LEN 8
	NOTE G_, 2
	LEN 16
	NOTE F_, 2
	REPEAT 3
	INSTR 0
	LEN 16
	NOTE G_, 2
	INSTR 1
	LEN 8
	NOTE G_, 3
	INSTR 0
	LEN 16
	NOTE G_, 2
	INSTR 1
	LEN 8
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	REPEAT_END
	INSTR 0
	NOTE G_, 2
	NOTE G_, 2
	LEN 16
	NOTE F_, 2
	NOTE Dsh, 2
	NOTE D_, 2
	REPEAT 4
	INSTR 0
	LEN 16
	NOTE C_, 2
	INSTR 1
	LEN 8
	NOTE C_, 3
	INSTR 0
	LEN 16
	NOTE C_, 2
	INSTR 1
	LEN 8
	NOTE C_, 3
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE C_, 3
	REPEAT_END
	REPEAT 3
	INSTR 0
	LEN 16
	NOTE C_, 2
	INSTR 1
	LEN 8
	NOTE C_, 3
	INSTR 0
	LEN 16
	NOTE C_, 2
	INSTR 1
	LEN 8
	NOTE C_, 3
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE C_, 3
	REPEAT_END
	INSTR 0
	LEN 16
	NOTE C_, 2
	INSTR 1
	LEN 8
	NOTE C_, 3
	INSTR 0
	LEN 16
	NOTE D_, 2
	INSTR 1
	LEN 8
	NOTE C_, 3
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE C_, 3
	REPEAT 3
	INSTR 0
	LEN 16
	NOTE F_, 2
	INSTR 1
	LEN 8
	NOTE F_, 3
	INSTR 0
	LEN 16
	NOTE F_, 2
	INSTR 1
	LEN 8
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	REPEAT_END
	INSTR 0
	LEN 16
	NOTE F_, 2
	INSTR 1
	LEN 8
	NOTE F_, 3
	INSTR 0
	LEN 16
	NOTE Gsh, 2
	LEN 8
	NOTE G_, 2
	LEN 16
	NOTE F_, 2
	REPEAT 2
	INSTR 0
	LEN 16
	NOTE G_, 2
	INSTR 1
	LEN 8
	NOTE G_, 3
	INSTR 0
	LEN 16
	NOTE G_, 2
	INSTR 1
	LEN 8
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	REPEAT_END
	INSTR 0
	LEN 16
	NOTE G_, 2
	LEN 8
	NOTE F_, 2
	LEN 16
	NOTE G_, 2
	LEN 8
	NOTE F_, 2
	NOTE G_, 2
	NOTE F_, 2
	LEN 16
	NOTE Gsh, 2
	NOTE A_, 2
	NOTE Ash, 2
	NOTE B_, 2
	NEXT
Pat_62ED:
	VOLENV 14, $11, $1F, $12
	CH_TRANSPOSE $0C
	WAVE Wave_7CCD
	ARP 5
	REPEAT 8
	LEN 24
	NOTE C_, 4
	LEN 40
	NOTE C_, 4
	REPEAT_END
	REPEAT 4
	LEN 24
	NOTE F_, 4
	LEN 40
	NOTE F_, 4
	REPEAT_END
	ARP 4
	REPEAT 3
	LEN 24
	NOTE G_, 4
	LEN 40
	NOTE G_, 4
	REPEAT_END
	LEN 16
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	ARP 5
	REPEAT 4
	LEN 24
	NOTE C_, 4
	LEN 40
	NOTE C_, 4
	REPEAT_END
	REPEAT 4
	LEN 24
	NOTE C_, 4
	LEN 40
	NOTE C_, 4
	REPEAT_END
	REPEAT 4
	LEN 24
	NOTE F_, 4
	LEN 40
	NOTE F_, 4
	REPEAT_END
	ARP 4
	REPEAT 2
	LEN 24
	NOTE G_, 4
	LEN 40
	NOTE G_, 4
	REPEAT_END
	LEN 24
	NOTE G_, 4
	NOTE G_, 4
	LEN 16
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NEXT
Pat_6333:
	DRUMS $08, DrumPat_6410
	TRANSPOSE $01
	HWENV $B0, $00
	ARP 0
	RELEASE $02, $A1
	VIBRATO $0A, $02, $05
	AUTODUTY $08
	REPEAT 2
	LENGTH $40
	NOTE C_, 4
	LEN 8
	NOTE C_, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	LENGTH $40
	NOTE C_, 3
	LEN 8
	NOTE C_, 3
	WAIT2
	NOTE C_, 3
	WAIT2
	NOTE C_, 3
	WAIT2
	NOTE C_, 3
	WAIT2
	REPEAT_END
	LENGTH $40
	NOTE C_, 4
	LEN 8
	NOTE C_, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	LENGTH $40
	NOTE F_, 3
	LEN 8
	NOTE F_, 3
	WAIT2
	NOTE F_, 3
	WAIT2
	NOTE F_, 3
	WAIT2
	NOTE F_, 3
	WAIT2
	LENGTH $40
	NOTE D_, 4
	LEN 8
	NOTE D_, 4
	WAIT2
	NOTE D_, 4
	WAIT2
	NOTE D_, 4
	WAIT2
	NOTE D_, 4
	WAIT2
	LENGTH $40
	NOTE G_, 3
	LEN 8
	NOTE G_, 3
	WAIT2
	NOTE G_, 3
	WAIT2
	AUTODUTY $00
	DUTY_75
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE B_, 3
	LEN 24
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	LEN 8
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE Gsh, 3
	LEN 24
	NOTE G_, 3
	NOTE Fsh, 3
	NOTE G_, 3
	LEN 8
	NOTE Fsh, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE Fsh, 3
	NOTE G_, 3
	NOTE B_, 3
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE G_, 3
	LEN 16
	NOTE D_, 4
	LEN 8
	NOTE G_, 3
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 24
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	LEN 8
	SLIDE_DOWN $00
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 16
	NOTE Gsh, 4
	LEN 8
	NOTE C_, 4
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE Gsh, 4
	LEN 16
	NOTE F_, 4
	DUTY_50
	LEN 8
	NOTE C_, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE C_, 4
	DUTY_75
	NOTE F_, 4
	LEN 16
	NOTE Gsh, 4
	LEN 8
	NOTE F_, 4
	LEN 16
	NOTE G_, 4
	LEN 8
	NOTE F_, 4
	NOTE C_, 4
	NOTE Gsh, 3
	DUTY_50
	NOTE F_, 3
	WAIT2
	NOTE F_, 3
	WAIT2
	NOTE F_, 3
	WAIT2
	NOTE F_, 3
	WAIT2
	DUTY_75
	LEN 8
	NOTE G_, 4
	NOTE F_, 4
	NOTE D_, 4
	LEN 16
	NOTE B_, 3
	LEN 8
	NOTE G_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 24
	NOTE B_, 4
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NEXT
DrumPat_6410:
	db DRUM_LEVEL + 13, DRUM_REPEAT + 3, 6, 0, 9, 0, DRUM_REPEAT_END, 0
	db 6, 9, 0, DRUM_LOOP

; Instrument table 6, entries 1..2 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr6_0
	dw Instr6_1
Instr6_0:
	HWENV $F2, $00
	ARP 0
	DUTY_50
	END
Instr6_1:
	HWENV $C1, $00
	ARP 0
	DUTY_12
	END

; Song 9: instrument table 7, arpeggio table 1 (the one SndInit sets)
PlaySong9:
	ld a, $67
	ld [wInstrTableHi], a
	ld a, $34
	ld [wInstrTable], a
	call StopAll
	ld de, Song9_Ch1
	call StartMusicCh1
	ld de, Song9_Ch3
	call StartMusicCh3
	ld de, Song9_Ch2
	jp StartMusicCh2

; Unreferenced (1 bytes)
	db $C9
Song9_Ch1:
	dw Pat_648E
	dw Pat_64A3
	dw Pat_64C2
	dw Pat_64C2
	dw Pat_64ED
	dw Pat_64ED
	dw Pat_64C2
	dw Pat_64C2
	dw Pat_64ED
	dw Pat_64ED
	dw Pat_6517
	ORDER_LOOP Song9_Ch1
Song9_Ch3:
	dw Pat_654B
	dw Pat_655B
	dw Pat_65A4
	dw Pat_65B0
	dw Pat_65BC
	dw Pat_65F0
	dw Pat_65A4
	dw Pat_65B0
	dw Pat_65BC
	dw Pat_65F0
	dw Pat_661D
	ORDER_LOOP Song9_Ch3
Song9_Ch2:
	dw Pat_6656
	dw Pat_666D
	dw Pat_6681
	dw Pat_6681
	dw Pat_6715
	ORDER_LOOP Song9_Ch2
Pat_648E:
	DUTY_50
	VIBRATO $0C, $04, $05
	INSTR 0
	REPEAT 2
	LENGTH $78
	NOTE D_, 2
	INSTR 1
	LEN 24
	NOTE D_, 2
	LENGTH $78
	NOTE D_, 2
	INSTR 0
	LEN 24
	NOTE F_, 2
	REPEAT_END
	NEXT
Pat_64A3:
	INSTR 0
	LENGTH $78
	NOTE G_, 2
	INSTR 1
	LEN 24
	NOTE G_, 2
	LENGTH $78
	NOTE G_, 2
	INSTR 0
	LEN 24
	NOTE F_, 2
	LENGTH $78
	NOTE G_, 2
	INSTR 1
	LEN 24
	NOTE G_, 2
	LENGTH $48
	NOTE G_, 2
	LEN 24
	NOTE A_, 2
	LEN 12
	NOTE A_, 2
	LEN 24
	NOTE C_, 3
	LEN 12
	NOTE C_, 3
	NEXT
Pat_64C2:
	REPEAT 3
	INSTR 1
	LEN 24
	NOTE D_, 2
	LEN 12
	NOTE D_, 2
	INSTR 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	REPEAT_END
	INSTR 1
	LEN 24
	NOTE D_, 2
	LEN 12
	NOTE D_, 2
	NOTE F_, 2
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE G_, 2
	REPEAT 3
	INSTR 1
	LEN 24
	NOTE D_, 2
	LEN 12
	NOTE D_, 2
	INSTR 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	REPEAT_END
	INSTR 1
	LEN 24
	NOTE D_, 2
	LEN 12
	NOTE D_, 2
	NOTE F_, 2
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE G_, 2
	NEXT
Pat_64ED:
	REPEAT 2
	INSTR 1
	LEN 24
	NOTE G_, 2
	LEN 12
	NOTE G_, 2
	INSTR 2
	NOTE G_, 3
	NOTE G_, 2
	NOTE G_, 3
	REPEAT_END
	INSTR 1
	LEN 24
	NOTE A_, 2
	LEN 12
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE A_, 3
	INSTR 1
	LEN 24
	NOTE A_, 2
	LEN 12
	NOTE A_, 2
	NOTE C_, 3
	INSTR 2
	NOTE C_, 4
	INSTR 1
	NOTE D_, 3
	REPEAT 4
	INSTR 1
	LEN 24
	NOTE D_, 2
	LEN 12
	NOTE D_, 2
	INSTR 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	REPEAT_END
	NEXT
Pat_6517:
	REPEAT 3
	INSTR 1
	LEN 24
	NOTE D_, 2
	LEN 12
	NOTE D_, 2
	INSTR 2
	LEN 24
	NOTE F_, 3
	LEN 12
	NOTE D_, 3
	REPEAT_END
	INSTR 1
	LEN 24
	NOTE D_, 2
	LEN 12
	NOTE D_, 2
	INSTR 2
	NOTE F_, 3
	NOTE D_, 3
	NOTE D_, 3
	REPEAT 2
	INSTR 1
	LEN 24
	NOTE D_, 2
	LEN 12
	NOTE D_, 2
	INSTR 2
	NOTE D_, 3
	NOTE D_, 2
	NOTE D_, 3
	REPEAT_END
	INSTR 1
	LEN 24
	NOTE D_, 2
	LEN 12
	NOTE D_, 2
	INSTR 2
	NOTE F_, 3
	NOTE D_, 2
	NOTE D_, 3
	INSTR 1
	LEN 24
	NOTE D_, 2
	LEN 12
	NOTE D_, 2
	NOTE F_, 2
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE G_, 2
	NEXT
Pat_654B:
	LEN 12
	CH_TRANSPOSE $0C
	REPEAT 8
	INSTR 6
	NOTE D_, 4
	INSTR 5
	LEN 36
	NOTE D_, 4
	INSTR 6
	LEN 12
	NOTE D_, 4
	INSTR 5
	NOTE D_, 4
	REPEAT_END
	NEXT
Pat_655B:
	REPEAT 7
	INSTR 6
	NOTE D_, 4
	INSTR 4
	LEN 36
	NOTE G_, 4
	INSTR 6
	LEN 12
	NOTE D_, 4
	INSTR 4
	NOTE G_, 4
	REPEAT_END
	INSTR 6
	NOTE E_, 4
	INSTR 5
	LEN 36
	NOTE A_, 4
	INSTR 4
	LEN 12
	NOTE C_, 5
	INSTR 6
	NOTE G_, 4
	NEXT
Pat_6572:
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	INSTR 5
	LEN 24
	NOTE D_, 4
	INSTR 3
	LEN 12
	NOTE A_, 2
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	INSTR 5
	LEN 24
	NOTE D_, 4
	INSTR 3
	LEN 12
	NOTE G_, 2
	REPEAT 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE E_, 3
	INSTR 4
	LEN 24
	NOTE C_, 4
	INSTR 3
	LEN 12
	NOTE G_, 2
	REPEAT_END
	REPEAT 2
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	INSTR 5
	LEN 24
	NOTE D_, 4
	INSTR 3
	LEN 12
	NOTE A_, 2
	REPEAT_END
	NOTE E_, 3
	NOTE F_, 3
	NOTE G_, 3
	INSTR 4
	LEN 24
	NOTE C_, 4
	INSTR 3
	LEN 12
	NOTE C_, 3
	NEXT
Pat_65A4:
	INSTR 3
	LEN 12
	PAT_CALL Pat_6572
	NOTE E_, 3
	NOTE F_, 3
	NOTE G_, 3
	INSTR 4
	LEN 36
	NOTE C_, 4
	NEXT
Pat_65B0:
	INSTR 3
	LEN 12
	PAT_CALL Pat_6572
	NOTE C_, 4
	NOTE C_, 5
	NOTE D_, 4
	NOTE D_, 5
	NOTE C_, 4
	NOTE C_, 5
	NEXT
Pat_65BC:
	INSTR 3
	LEN 12
	REPEAT 2
	NOTE G_, 3
	NOTE A_, 3
	NOTE Ash, 3
	INSTR 5
	LEN 24
	NOTE G_, 4
	INSTR 3
	LEN 12
	NOTE D_, 3
	REPEAT_END
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	INSTR 5
	LEN 24
	NOTE A_, 4
	INSTR 3
	LEN 12
	NOTE E_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	INSTR 5
	LEN 24
	NOTE A_, 4
	INSTR 3
	LEN 12
	NOTE A_, 3
	REPEAT 3
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	INSTR 5
	LEN 24
	NOTE D_, 4
	INSTR 3
	LEN 12
	NOTE A_, 3
	REPEAT_END
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	INSTR 5
	NOTE D_, 4
	INSTR 3
	NOTE F_, 4
	INSTR 5
	NOTE D_, 4
	NEXT
Pat_65F0:
	INSTR 3
	LEN 12
	REPEAT 2
	NOTE G_, 3
	NOTE A_, 3
	NOTE Ash, 3
	INSTR 5
	LEN 24
	NOTE G_, 4
	INSTR 3
	LEN 12
	NOTE D_, 3
	REPEAT_END
	REPEAT 2
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	INSTR 5
	LEN 24
	NOTE A_, 4
	INSTR 3
	LEN 12
	NOTE E_, 3
	REPEAT_END
	REPEAT 3
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	INSTR 5
	LEN 24
	NOTE D_, 4
	INSTR 3
	LEN 12
	NOTE A_, 3
	REPEAT_END
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	INSTR 5
	NOTE D_, 4
	INSTR 3
	NOTE F_, 4
	INSTR 5
	NOTE D_, 4
	NEXT
Pat_661D:
	REPEAT 2
	INSTR 5
	LEN 24
	NOTE D_, 4
	INSTR 3
	LEN 12
	NOTE D_, 4
	INSTR 5
	LEN 24
	NOTE D_, 4
	INSTR 3
	LEN 12
	NOTE D_, 4
	REPEAT_END
	REPEAT 2
	INSTR 5
	LEN 24
	NOTE E_, 4
	INSTR 3
	LEN 12
	NOTE D_, 4
	INSTR 5
	LEN 24
	NOTE E_, 4
	INSTR 3
	LEN 12
	NOTE D_, 4
	REPEAT_END
	REPEAT 2
	INSTR 4
	LEN 24
	NOTE F_, 4
	INSTR 3
	LEN 12
	NOTE D_, 4
	INSTR 4
	LEN 24
	NOTE F_, 4
	INSTR 3
	LEN 12
	NOTE D_, 4
	REPEAT_END
	REPEAT 2
	INSTR 5
	LEN 24
	NOTE E_, 4
	INSTR 3
	LEN 12
	NOTE D_, 4
	INSTR 5
	LEN 24
	NOTE E_, 4
	INSTR 3
	LEN 12
	NOTE D_, 4
	REPEAT_END
	NEXT
Pat_6656:
	DRUMS $18, DrumPat_678F
	HWENV $C1, $00
	DUTY_12
	ARP 13
	VIBRATO $18, $01, $06
	LEN 12
	REPEAT 8
	NOTE D_, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE D_, 3
	NOTE A_, 3
	REPEAT_END
	NEXT
Pat_666D:
	LEN 12
	REPEAT 7
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE D_, 4
	REPEAT_END
	DRUMS $24, DrumPat_678C
	NOTE A_, 3
	NOTE E_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NEXT
Pat_6681:
	HWENV $7D, $18, $D7
	DUTY_50
	ARP_OFF
	DRUMS $0C, DrumPat_6777
	LENGTH $78
	NOTE A_, 4
	LEN 12
	NOTE E_, 4
	NOTE F_, 4
	LENGTH $6C
	NOTE G_, 4
	LEN 12
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 24
	NOTE A_, 4
	LENGTH $48
	NOTE D_, 4
	LEN 12
	NOTE A_, 3
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 24
	NOTE E_, 4
	LEN 12
	NOTE D_, 4
	LENGTH $48
	NOTE C_, 4
	LEN 12
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	LENGTH $78
	NOTE A_, 4
	LEN 12
	NOTE E_, 4
	NOTE F_, 4
	LENGTH $6C
	NOTE G_, 4
	LEN 12
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 24
	NOTE A_, 4
	LENGTH $48
	NOTE D_, 4
	LEN 12
	NOTE A_, 3
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 24
	NOTE E_, 4
	LEN 12
	NOTE G_, 4
	LEN 36
	NOTE C_, 5
	LEN 24
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	LENGTH $6C
	NOTE D_, 5
	LEN 12
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	LENGTH $3C
	NOTE D_, 5
	LEN 24
	NOTE C_, 5
	LEN 12
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE G_, 4
	LENGTH $78
	NOTE A_, 4
	LEN 12
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE D_, 5
	NOTE C_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE F_, 5
	NOTE C_, 5
	LENGTH $6C
	NOTE D_, 5
	LEN 12
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	LENGTH $3C
	NOTE D_, 5
	LEN 24
	NOTE C_, 5
	LEN 12
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	LENGTH $6C
	NOTE E_, 5
	LEN 24
	NOTE D_, 5
	LENGTH $3C
	NOTE A_, 4
	LEN 12
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	LEN 36
	NOTE A_, 4
	NEXT
Pat_6715:
	DRUMS $24, DrumPat_678C
	LENGTH $FC
	WAIT
	LEN 12
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	DRUMS $0C, DrumPat_6777
	REPEAT 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE D_, 5
	REPEAT_END
	NOTE F_, 5
	NOTE D_, 5
	NOTE D_, 4
	NOTE A_, 5
	NOTE D_, 5
	NOTE D_, 4
	NOTE F_, 5
	NOTE D_, 5
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NEXT

; Instrument table 7, entries 1..7 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr7_0
	dw Instr7_1
	dw Instr7_2
	dw Instr7_3
	dw Instr7_4
	dw Instr7_5
	dw Instr7_6
Instr7_0:
	HWENV $F7, $00
	ARP 2
	END
Instr7_1:
	HWENV $F2, $00
	ARP 0
	END
Instr7_2:
	HWENV $D1, $00
	ARP 0
	DUTY_75
	END
Instr7_3:
	WAVE Wave_7D1D
	VOLENV 12, $11, $1F, $11
	ARP 0
	END
Instr7_4:
	WAVE Wave_7D0D
	VOLENV 12, $11, $18, $12
	ARP 4
	END
Instr7_5:
	WAVE Wave_7D0D
	VOLENV 12, $11, $18, $12
	ARP 5
	END
Instr7_6:
	VOLENV 11, $11, $15, $11
	WAVE Wave_7C6D
	END
DrumPat_6777:
	db DRUM_REPEAT + 7, DRUM_LEVEL + 13, 6, 0, 6, 4, DRUM_LEVEL + 12, 6
	db DRUM_LEVEL + 11, 6, DRUM_REPEAT_END, DRUM_LEVEL + 13, 6, 0, 6, 4
	db DRUM_LEVEL + 12, 6, DRUM_LEVEL + 13, 4, DRUM_LOOP
DrumPat_678C:
	db DRUM_LEVEL + 13, 4, DRUM_LOOP
DrumPat_678F:
	db DRUM_LEVEL + 13, 4, 0, 4, DRUM_LOOP

; Song 10: instrument table 8, arpeggio table 1 (the one SndInit sets)
PlaySong10:
	ld a, $6A
	ld [wInstrTableHi], a
	ld a, $4C
	ld [wInstrTable], a
	call StopAll
	ld de, Song10_Ch3
	call StartMusicCh3
	ld de, Song10_Ch2
	call StartMusicCh2
	ld de, Song10_Ch1
	jp StartMusicCh1

; Unreferenced (1 bytes)
	db $C9
Song10_Ch3:
	dw Pat_6837
	dw Pat_67E8
	dw Pat_67E8
	dw Pat_67FA
	dw Pat_6805
	dw Pat_6818
	dw Pat_6818
	ORDER_LOOP Song10_Ch3
Song10_Ch2:
	dw Pat_690E
	dw Pat_684A
	dw Pat_6891
	dw Pat_68B2
	dw Pat_68D0
	dw Pat_68D0
	ORDER_LOOP Song10_Ch2
Song10_Ch1:
	dw Pat_6A0D
Loop_67D8:
	dw Pat_693A
	dw Pat_6983
	dw Pat_69A8
	dw Pat_69C5
	dw Pat_69C5
	dw Pat_6A2F
	ORDER_LOOP Loop_67D8
Pat_67E8:
	LEN 10
	REPEAT 8
	INSTR 1
	NOTE G_, 2
	INSTR 0
	NOTE G_, 3
	REPEAT_END
	REPEAT 7
	INSTR 1
	NOTE G_, 2
	INSTR 0
	NOTE G_, 3
	REPEAT_END
	INSTR 1
	NOTE D_, 2
	INSTR 0
	NOTE G_, 3
	NEXT
Pat_67FA:
	REPEAT 8
	INSTR 1
	NOTE C_, 2
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE C_, 2
	INSTR 0
	NOTE C_, 3
	REPEAT_END
	NEXT
Pat_6805:
	REPEAT 8
	INSTR 1
	NOTE D_, 2
	INSTR 0
	NOTE D_, 3
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE Fsh, 2
	INSTR 0
	NOTE Fsh, 3
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE A_, 2
	INSTR 0
	NOTE A_, 3
	REPEAT_END
	NEXT
Pat_6818:
	REPEAT 8
	INSTR 1
	NOTE Dsh, 2
	INSTR 0
	NOTE Dsh, 3
	REPEAT_END
	REPEAT 8
	INSTR 1
	NOTE C_, 2
	INSTR 0
	NOTE C_, 3
	REPEAT_END
	REPEAT 8
	INSTR 1
	NOTE Dsh, 2
	INSTR 0
	NOTE Dsh, 3
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE Fsh, 2
	INSTR 0
	NOTE Fsh, 3
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE D_, 2
	INSTR 0
	NOTE D_, 3
	REPEAT_END
	NEXT
Pat_6837:
	WAVE Wave_7C1D
	CH_TRANSPOSE $0C
	INSTR 1
	LENGTH $50
	NOTE G_, 2
	NOTE G_, 2
	LEN 40
	NOTE G_, 2
	NOTE G_, 2
	LEN 20
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NEXT
Pat_684A:
	LEN 10
	HWENV $D3, $00
	ARP 0
	DUTY_75
	NOTE D_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE D_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE D_, 4
	NOTE D_, 5
	NOTE D_, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE D_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE D_, 4
	NOTE Ash, 4
	NOTE D_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE D_, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE D_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE D_, 4
	NOTE D_, 5
	NOTE D_, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE D_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE D_, 4
	NOTE Ash, 4
	NOTE D_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE D_, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE A_, 4
	NEXT
Pat_6891:
	NOTE G_, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE G_, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE G_, 4
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE G_, 4
	NOTE G_, 5
	NOTE G_, 4
	NOTE F_, 5
	NOTE Gsh, 5
	NOTE G_, 4
	NOTE F_, 5
	NOTE G_, 5
	NOTE G_, 4
	NOTE Dsh, 5
	NOTE G_, 4
	NOTE F_, 5
	NOTE D_, 5
	NOTE G_, 4
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE G_, 4
	NOTE D_, 5
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 5
	NOTE D_, 5
	NEXT
Pat_68B2:
	NOTE D_, 4
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE D_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE D_, 4
	NOTE Ash, 4
	NOTE D_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE D_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 4
	NOTE D_, 4
	LEN 20
	NOTE C_, 5
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NEXT
Pat_68D0:
	LEN 10
	HWENV $C1, $00
	ARP 11
	VIBRATO $0A, $01, $05
	REPEAT 2
	NOTE Ash, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE A_, 4
	REPEAT_END
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE Ash, 3
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE G_, 4
	REPEAT 2
	NOTE Ash, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE A_, 4
	REPEAT_END
	NOTE C_, 5
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NEXT
Pat_690E:
	LEN 10
	HWENV $C2, $00
	DUTY_75
	ARP 0
	NOTE G_, 3
	NOTE Ash, 3
	NOTE D_, 4
	NOTE G_, 3
	NOTE Ash, 3
	NOTE D_, 4
	NOTE G_, 3
	NOTE Ash, 3
	NOTE D_, 4
	NOTE G_, 3
	NOTE Ash, 3
	NOTE D_, 4
	NOTE G_, 3
	NOTE Ash, 3
	NOTE D_, 4
	NOTE Ash, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE D_, 4
	NOTE G_, 3
	NOTE Ash, 3
	NOTE D_, 4
	NOTE G_, 3
	NOTE Ash, 3
	NOTE D_, 4
	NOTE G_, 3
	NOTE Ash, 3
	NOTE D_, 4
	NOTE D_, 4
	HWENV $F3, $00
	ARP 0
	DUTY_75
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NEXT
Pat_693A:
	DRUMS $0A, DrumPat_6A5E
	LEN 10
	NOTE G_, 3
	NOTE D_, 4
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE Fsh, 4
	LEN 20
	NOTE A_, 4
	LEN 10
	NOTE G_, 4
	LEN 20
	NOTE G_, 4
	NOTE Ash, 4
	LEN 10
	NOTE A_, 4
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE A_, 4
	LEN 20
	NOTE Ash, 4
	NOTE G_, 4
	LEN 10
	NOTE A_, 4
	LEN 20
	NOTE Fsh, 4
	LEN 10
	NOTE A_, 4
	LEN 20
	NOTE G_, 4
	NOTE Fsh, 4
	LENGTH $32
	NOTE D_, 4
	LEN 10
	NOTE D_, 4
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE Fsh, 4
	LEN 20
	NOTE A_, 4
	LEN 10
	NOTE Fsh, 4
	LEN 20
	NOTE G_, 4
	NOTE Ash, 4
	LEN 10
	NOTE A_, 4
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE A_, 4
	LEN 20
	NOTE Ash, 4
	NOTE G_, 4
	LEN 10
	NOTE A_, 4
	LEN 20
	NOTE Fsh, 4
	LEN 10
	NOTE Fsh, 4
	LEN 20
	NOTE G_, 4
	NOTE Fsh, 4
	LEN 40
	NOTE D_, 4
	NEXT
Pat_6983:
	LEN 10
	NOTE Dsh, 4
	NOTE G_, 4
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	LEN 20
	NOTE D_, 5
	LEN 10
	NOTE B_, 4
	LEN 20
	NOTE C_, 5
	NOTE Dsh, 5
	LEN 10
	NOTE D_, 5
	LEN 20
	NOTE F_, 5
	LEN 10
	NOTE D_, 5
	LEN 20
	NOTE Dsh, 5
	NOTE C_, 5
	LEN 10
	NOTE D_, 5
	LEN 20
	NOTE B_, 4
	LEN 10
	NOTE D_, 5
	LEN 20
	NOTE C_, 5
	NOTE B_, 4
	LEN 30
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	NEXT
Pat_69A8:
	LEN 10
	NOTE Fsh, 4
	NOTE Ash, 4
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE A_, 4
	LEN 20
	NOTE Ash, 4
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	LEN 20
	NOTE A_, 4
	LEN 10
	NOTE Fsh, 4
	LEN 20
	NOTE G_, 4
	LEN 40
	NOTE D_, 4
	LEN 30
	NOTE D_, 4
	LEN 20
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NEXT
Pat_69C5:
	HWENV $9A, $08, $D0
	ARP 0
	LEN 30
	NOTE Dsh, 3
	LEN 40
	NOTE Ash, 3
	LEN 10
	NOTE D_, 3
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE Dsh, 3
	LEN 20
	NOTE Ash, 3
	LEN 10
	NOTE A_, 3
	NOTE G_, 3
	NOTE Ash, 3
	LENGTH $32
	NOTE C_, 3
	LEN 10
	NOTE C_, 3
	NOTE D_, 3
	NOTE Dsh, 3
	NOTE G_, 3
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE Ash, 3
	LEN 30
	NOTE Dsh, 3
	LEN 20
	NOTE Ash, 3
	LEN 10
	NOTE D_, 3
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE Dsh, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE D_, 4
	LEN 30
	NOTE C_, 4
	LEN 10
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE C_, 4
	LENGTH $32
	HWENV $9A, $40, $D7
	NOTE D_, 4
	CH_TRANSPOSE $0C
	NEXT
Pat_6A0D:
	DRUMS $0A, DrumPat_6A82
	HWENV $11, $00
	LENGTH $A0
	NOTE G_, 2
	LENGTH $82
	CH_TRANSPOSE $00
	VIBRATO $14, $02, $05
	HWENV $9A, $08, $D0
	ARP 0
	DUTY_50
	NOTE G_, 3
	HWENV $D2, $00
	DUTY_50
	LEN 10
	NOTE Ash, 3
	NOTE C_, 4
	NOTE A_, 3
	NEXT
Pat_6A2F:
	DRUMS $0A, DrumPat_6A82
	LENGTH $A0
	WAIT
	LENGTH $82
	CH_TRANSPOSE $00
	VIBRATO $14, $02, $05
	HWENV $9A, $08, $D0
	ARP 0
	DUTY_50
	NOTE G_, 3
	HWENV $D2, $00
	DUTY_50
	LEN 10
	NOTE Ash, 3
	NOTE C_, 4
	NOTE A_, 3
	NEXT

; Instrument table 8, entries 1..2 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr8_0
	dw Instr8_1
Instr8_0:
	VOLENV 15, $11, $1F, $11
	ARP 0
	END
Instr8_1:
	VOLENV 15, $11, $16, $13
	ARP 0
	END
DrumPat_6A5E:
	db DRUM_REPEAT + 7, DRUM_LEVEL + 13, 1, DRUM_LEVEL + 12, 6, DRUM_LEVEL + 15, 9, DRUM_LEVEL + 12
	db 6, DRUM_REPEAT_END, DRUM_LEVEL + 13, 1, 9, DRUM_LEVEL + 15, 9, DRUM_LEVEL + 12
	db 6, DRUM_REPEAT + 7, DRUM_LEVEL + 13, 1, DRUM_LEVEL + 12, 6, DRUM_LEVEL + 15, 9
	db DRUM_LEVEL + 12, 6, DRUM_REPEAT_END, DRUM_LEVEL + 13, 1, DRUM_LEVEL + 12, 6, DRUM_LEVEL + 15
	db 9, DRUM_LEVEL + 14, 9, DRUM_LOOP
DrumPat_6A82:
	db DRUM_LEVEL + 13, DRUM_TEMPO + 40, 1, 1, 1, 1, DRUM_TEMPO + 20, 1
	db 1, 1, 1, 1, 1, DRUM_TEMPO + 10, 1, DRUM_TEMPO + 5
	db 9, 9, DRUM_TEMPO + 10, 9, 9, DRUM_LOOP

; Song 11: instrument table 9, arpeggio table 1 (the one SndInit sets)
PlaySong11:
	ld a, $6E
	ld [wInstrTableHi], a
	ld a, $7F
	ld [wInstrTable], a
	call StopAll
	ld de, Song11_Ch1
	call StartMusicCh1
	ld de, Song11_Ch3
	call StartMusicCh3
	ld de, Song11_Ch2
	jp StartMusicCh2

; Unreferenced (1 bytes)
	db $C9
Song11_Ch1:
	dw Pat_6AE8
	dw Pat_6B13
	dw Pat_6AE8
	dw Pat_6B13
	dw Pat_6B54
	dw Pat_6BAB
	ORDER_LOOP Song11_Ch1
Song11_Ch3:
	dw Pat_6BD3
	dw Pat_6C44
	dw Pat_6BD3
	dw Pat_6C44
	dw Pat_6CB2
	dw Pat_6D1F
	ORDER_LOOP Song11_Ch3
Song11_Ch2:
	dw Pat_6D8D
	dw Pat_6DD5
	dw Pat_6D8D
	dw Pat_6DD5
	dw Pat_6E1D
	dw Pat_6E54
	ORDER_LOOP Song11_Ch2
Pat_6AE8:
	DRUMS $0B, DrumPat_6EC0
	VIBRATO $0B, $04, $05
	REPEAT 6
	INSTR 0
	LEN 22
	NOTE E_, 2
	INSTR 1
	LEN 11
	NOTE E_, 2
	INSTR 0
	LEN 22
	NOTE E_, 2
	INSTR 1
	LEN 11
	NOTE E_, 2
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE E_, 3
	INSTR 0
	LEN 22
	NOTE E_, 2
	INSTR 1
	LEN 11
	NOTE E_, 2
	INSTR 0
	LEN 22
	NOTE E_, 2
	INSTR 1
	LEN 11
	NOTE E_, 2
	INSTR 0
	NOTE B_, 2
	INSTR 1
	NOTE E_, 3
	REPEAT_END
	NEXT
Pat_6B13:
	INSTR 0
	LEN 22
	NOTE A_, 2
	INSTR 1
	LEN 11
	NOTE A_, 2
	INSTR 0
	LEN 22
	NOTE A_, 2
	INSTR 1
	LEN 11
	NOTE A_, 2
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	LEN 22
	NOTE A_, 2
	INSTR 1
	LEN 11
	NOTE A_, 2
	INSTR 0
	LEN 22
	NOTE A_, 2
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	LEN 22
	NOTE E_, 2
	INSTR 1
	LEN 11
	NOTE E_, 2
	INSTR 0
	LEN 22
	NOTE E_, 2
	INSTR 1
	LEN 11
	NOTE E_, 2
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE E_, 3
	INSTR 0
	LEN 22
	NOTE E_, 2
	INSTR 1
	LEN 11
	NOTE E_, 2
	INSTR 0
	LEN 22
	NOTE E_, 2
	INSTR 1
	LEN 11
	NOTE E_, 2
	INSTR 0
	NOTE B_, 2
	INSTR 1
	NOTE E_, 3
	NEXT
Pat_6B54:
	REPEAT 2
	INSTR 0
	LEN 22
	NOTE D_, 2
	INSTR 1
	LEN 11
	NOTE D_, 2
	INSTR 0
	LEN 22
	NOTE D_, 2
	INSTR 1
	LEN 11
	NOTE D_, 2
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE D_, 3
	INSTR 0
	LEN 22
	NOTE E_, 2
	INSTR 1
	LEN 11
	NOTE E_, 2
	INSTR 0
	LEN 22
	NOTE E_, 2
	INSTR 1
	LEN 11
	NOTE E_, 2
	INSTR 0
	NOTE B_, 2
	INSTR 1
	NOTE E_, 3
	REPEAT_END
	REPEAT 2
	INSTR 0
	LEN 22
	NOTE D_, 2
	INSTR 1
	LEN 11
	NOTE D_, 2
	REPEAT_END
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE D_, 3
	INSTR 0
	LEN 22
	NOTE G_, 2
	INSTR 1
	LEN 11
	NOTE G_, 2
	INSTR 0
	LEN 22
	NOTE A_, 2
	INSTR 1
	LEN 11
	NOTE A_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE A_, 3
	REPEAT 2
	INSTR 0
	LEN 22
	NOTE E_, 2
	INSTR 1
	LEN 11
	NOTE E_, 2
	REPEAT_END
	INSTR 0
	NOTE B_, 2
	INSTR 1
	NOTE E_, 3
	REPEAT 2
	INSTR 0
	LEN 22
	NOTE E_, 2
	INSTR 1
	LEN 11
	NOTE E_, 2
	REPEAT_END
	INSTR 0
	NOTE E_, 3
	INSTR 1
	NOTE B_, 2
	NEXT
Pat_6BAB:
	INSTR 0
	LENGTH $B0
	NOTE E_, 2
	LENGTH $63
	NOTE E_, 3
	LEN 11
	NOTE B_, 2
	NOTE C_, 3
	NOTE A_, 2
	NOTE B_, 2
	NOTE Gsh, 2
	NOTE A_, 2
	NOTE Fsh, 2
	LEN 33
	NOTE E_, 2
	LENGTH $37
	NOTE E_, 2
	LEN 33
	NOTE E_, 2
	NOTE E_, 2
	LEN 11
	NOTE B_, 2
	NOTE E_, 3
	LEN 33
	NOTE E_, 2
	LEN 44
	NOTE E_, 2
	LEN 22
	NOTE E_, 2
	NOTE B_, 2
	LEN 11
	NOTE C_, 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE Gsh, 2
	NOTE Fsh, 2
	NEXT
Pat_6BD3:
	CH_TRANSPOSE $0C
	LEN 11
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE E_, 4
	LEN 22
	NOTE Dsh, 4
	INSTR 5
	LEN 11
	NOTE G_, 3
	INSTR 2
	NOTE B_, 3
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE E_, 4
	LEN 22
	NOTE Fsh, 4
	NOTE Dsh, 4
	INSTR 5
	LEN 11
	NOTE G_, 3
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE E_, 4
	LEN 22
	NOTE Dsh, 4
	INSTR 5
	LEN 11
	NOTE G_, 3
	INSTR 2
	NOTE B_, 3
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE C_, 4
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE C_, 4
	LEN 22
	NOTE Dsh, 4
	LEN 11
	NOTE E_, 4
	NOTE Fsh, 4
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE E_, 4
	LEN 22
	NOTE Dsh, 4
	INSTR 5
	LEN 11
	NOTE G_, 3
	INSTR 2
	NOTE B_, 3
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE E_, 4
	LEN 22
	NOTE Fsh, 4
	NOTE Dsh, 4
	INSTR 5
	LEN 11
	NOTE G_, 3
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE E_, 4
	LEN 22
	NOTE Dsh, 4
	INSTR 5
	LEN 11
	NOTE G_, 3
	INSTR 2
	NOTE B_, 3
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE B_, 3
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NEXT
Pat_6C44:
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE E_, 4
	LEN 22
	NOTE Dsh, 4
	INSTR 5
	LEN 11
	NOTE G_, 3
	INSTR 2
	NOTE B_, 3
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE E_, 4
	LEN 22
	NOTE Fsh, 4
	NOTE Dsh, 4
	INSTR 5
	LEN 11
	NOTE G_, 3
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE E_, 4
	LEN 22
	NOTE Dsh, 4
	INSTR 5
	LEN 11
	NOTE G_, 3
	INSTR 2
	NOTE B_, 3
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE C_, 4
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE C_, 4
	LEN 22
	NOTE Dsh, 4
	LEN 11
	NOTE E_, 4
	NOTE Fsh, 4
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE E_, 4
	INSTR 4
	NOTE A_, 4
	INSTR 2
	NOTE E_, 4
	LEN 22
	NOTE Dsh, 4
	INSTR 5
	LEN 11
	NOTE G_, 3
	INSTR 2
	NOTE C_, 4
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE E_, 4
	INSTR 4
	NOTE A_, 4
	INSTR 2
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE E_, 4
	LEN 22
	NOTE Dsh, 4
	INSTR 5
	LEN 11
	NOTE G_, 3
	INSTR 2
	NOTE B_, 3
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE B_, 3
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NEXT
Pat_6CB2:
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 3
	NOTE D_, 4
	INSTR 2
	NOTE D_, 4
	LEN 22
	NOTE Csh, 4
	INSTR 5
	LEN 11
	NOTE G_, 3
	INSTR 2
	NOTE A_, 3
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE D_, 4
	LEN 22
	NOTE E_, 4
	NOTE B_, 3
	INSTR 5
	LEN 11
	NOTE G_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 3
	NOTE D_, 4
	INSTR 2
	NOTE D_, 4
	LEN 22
	NOTE Csh, 4
	INSTR 5
	LEN 11
	NOTE G_, 3
	INSTR 2
	NOTE A_, 3
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE B_, 3
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 3
	NOTE D_, 4
	INSTR 2
	NOTE D_, 4
	LEN 22
	NOTE Csh, 4
	INSTR 5
	LEN 11
	NOTE G_, 3
	INSTR 2
	NOTE A_, 3
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 3
	NOTE G_, 4
	INSTR 2
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE E_, 4
	LEN 22
	NOTE Dsh, 4
	INSTR 5
	LEN 11
	NOTE G_, 3
	INSTR 2
	NOTE B_, 3
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE B_, 3
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NEXT
Pat_6D1F:
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE E_, 4
	LEN 22
	NOTE Dsh, 4
	INSTR 5
	LEN 11
	NOTE G_, 3
	INSTR 2
	NOTE B_, 3
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE E_, 4
	LEN 22
	NOTE Fsh, 4
	NOTE Dsh, 4
	INSTR 5
	LEN 11
	NOTE G_, 3
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE E_, 4
	LEN 22
	NOTE Dsh, 4
	INSTR 5
	LEN 11
	NOTE G_, 3
	INSTR 2
	NOTE B_, 3
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE C_, 4
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE C_, 4
	LEN 22
	NOTE Dsh, 4
	LEN 11
	NOTE E_, 4
	NOTE Fsh, 4
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE E_, 4
	LEN 22
	NOTE Dsh, 4
	INSTR 5
	LEN 11
	NOTE G_, 3
	INSTR 2
	NOTE B_, 3
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE E_, 4
	LEN 22
	NOTE Fsh, 4
	NOTE Dsh, 4
	INSTR 5
	LEN 11
	NOTE G_, 3
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE E_, 4
	LEN 22
	NOTE Dsh, 4
	INSTR 5
	LEN 11
	NOTE G_, 3
	INSTR 2
	NOTE B_, 3
	INSTR 5
	NOTE G_, 3
	INSTR 2
	NOTE B_, 3
	INSTR 3
	NOTE E_, 4
	INSTR 2
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE Fsh, 3
	NEXT
Pat_6D8D:
	HWENV $7B, $0B, $90
	DUTY_50
	VIBRATO $0B, $01, $05
	RELEASE $01, $92
	ARP_OFF
	LEN 44
	NOTE B_, 5
	LEN 11
	NOTE Ash, 5
	NOTE B_, 5
	ARP 14
	LEN 44
	NOTE B_, 5
	ARP_OFF
	LEN 22
	NOTE B_, 5
	LEN 11
	NOTE Ash, 5
	NOTE B_, 5
	NOTE Ash, 5
	NOTE G_, 5
	LEN 33
	NOTE Fsh, 5
	ARP 14
	LEN 11
	NOTE F_, 5
	ARP_OFF
	NOTE Fsh, 5
	NOTE G_, 5
	LEN 33
	NOTE Fsh, 5
	LEN 11
	NOTE E_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	LEN 22
	NOTE B_, 4
	LEN 11
	NOTE C_, 5
	NOTE Dsh, 5
	ARP 14
	LEN 22
	NOTE D_, 5
	ARP_OFF
	LEN 11
	NOTE Dsh, 5
	NOTE C_, 5
	LENGTH $37
	NOTE B_, 4
	LEN 11
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE A_, 4
	ARP 14
	LENGTH $58
	NOTE A_, 4
	WAIT2
	NEXT
Pat_6DD5:
	ARP_OFF
	LEN 44
	NOTE B_, 5
	LEN 11
	NOTE Ash, 5
	NOTE B_, 5
	ARP 14
	LEN 44
	NOTE B_, 5
	ARP_OFF
	LEN 22
	NOTE B_, 5
	LEN 11
	NOTE Ash, 5
	NOTE B_, 5
	NOTE Ash, 5
	NOTE G_, 5
	LEN 33
	NOTE Fsh, 5
	ARP 14
	LEN 11
	NOTE F_, 5
	ARP_OFF
	NOTE Fsh, 5
	NOTE G_, 5
	LEN 33
	NOTE Fsh, 5
	LEN 11
	NOTE E_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	LEN 22
	NOTE B_, 4
	LEN 11
	NOTE C_, 5
	NOTE Dsh, 5
	ARP 14
	LEN 22
	NOTE D_, 5
	ARP_OFF
	LEN 11
	NOTE Dsh, 5
	NOTE C_, 5
	LENGTH $37
	NOTE A_, 4
	ARP 14
	LEN 11
	NOTE Ash, 4
	ARP_OFF
	NOTE A_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 4
	LENGTH $37
	NOTE E_, 4
	LEN 11
	NOTE B_, 3
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE Fsh, 4
	ARP 14
	NOTE Fsh, 4
	ARP_OFF
	LEN 44
	NOTE E_, 4
	NEXT
Pat_6E1D:
	HWENV $D4, $00
	DUTY_75
	ARP 0
	RELEASE $00
	LEN 33
	NOTE Fsh, 4
	NOTE A_, 4
	LEN 22
	NOTE Csh, 5
	LENGTH $42
	NOTE B_, 4
	LEN 22
	NOTE E_, 4
	LEN 33
	NOTE Fsh, 4
	NOTE A_, 4
	LEN 22
	NOTE Csh, 5
	LEN 11
	NOTE E_, 5
	NOTE B_, 4
	LENGTH $42
	NOTE B_, 4
	LEN 33
	NOTE Fsh, 4
	NOTE A_, 4
	LEN 22
	NOTE Csh, 5
	NOTE B_, 4
	LEN 11
	NOTE D_, 5
	LEN 22
	NOTE Csh, 5
	LEN 11
	NOTE A_, 4
	NOTE E_, 4
	NOTE A_, 4
	LEN 33
	NOTE B_, 4
	NOTE Gsh, 4
	NOTE E_, 4
	LEN 11
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE Csh, 4
	NOTE D_, 4
	NEXT
Pat_6E54:
	LENGTH $FF
	NOTE E_, 4
	LENGTH $6C
	WAIT
	HWENV $F1, $00
	DUTY_12
	LEN 22
	NOTE Gsh, 4
	LEN 11
	NOTE Gsh, 4
	LEN 33
	NOTE Fsh, 4
	LEN 22
	NOTE Dsh, 4
	LEN 22
	NOTE Gsh, 4
	LEN 11
	NOTE Gsh, 4
	LEN 22
	NOTE A_, 4
	LEN 33
	NOTE Fsh, 4
	LEN 22
	NOTE Gsh, 4
	LEN 11
	NOTE Gsh, 4
	LEN 33
	NOTE Fsh, 4
	LEN 22
	NOTE Dsh, 4
	HWENV $F2, $00
	NOTE B_, 3
	LEN 11
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE Fsh, 3
	NEXT

; Instrument table 9, entries 1..6 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr9_0
	dw Instr9_1
	dw Instr9_2
	dw Instr9_3
	dw Instr9_4
	dw Instr9_5
Instr9_0:
	HWENV $F2, $0B, $70
	ARP 8
	END
Instr9_1:
	HWENV $F1, $05, $61
	ARP 0
	DUTY_75
	END
Instr9_2:
	VOLENV 13, $11, $1F, $11
	ARP 12
	WAVE Wave_7C6D
	END
Instr9_3:
	VOLENV 15, $11, $16, $11
	ARP 4
	WAVE Wave_7D1D
	END
Instr9_4:
	VOLENV 15, $11, $16, $11
	ARP 5
	WAVE Wave_7D1D
	END
Instr9_5:
	VOLENV 15, $13, $1F, $11
	ARP_OFF
	GLIDE $FD
	WAVE Wave_7B3D
	END
DrumPat_6EC0:
	db DRUM_REPEAT + 3, DRUM_LEVEL + 14, 6, DRUM_LEVEL + 12, 6, DRUM_LEVEL + 15, 9, DRUM_LEVEL + 13
	db 9, DRUM_LEVEL + 14, 6, DRUM_LEVEL + 12, 6, DRUM_LEVEL + 15, 9, DRUM_LEVEL + 12
	db 6, DRUM_REPEAT_END, DRUM_LEVEL + 14, 6, DRUM_LEVEL + 12, 6, DRUM_LEVEL + 15, 9
	db DRUM_LEVEL + 13, 9, DRUM_LEVEL + 14, 6, DRUM_LEVEL + 13, 9, DRUM_LEVEL + 15, 9
	db DRUM_LEVEL + 13, 9, DRUM_LOOP

; Song 12: instrument table 10, arpeggio table 1 (the one SndInit sets)
PlaySong12:
	ld a, $72
	ld [wInstrTableHi], a
	ld a, $5E
	ld [wInstrTable], a
	call StopAll
	ld de, Song12_Ch3
	call StartMusicCh3
	ld de, Song12_Ch2
	call StartMusicCh2
	ld de, Song12_Ch1
	jp StartMusicCh1
Song12_Ch3:
	dw Pat_6F3E
	dw Pat_6FB5
	dw Pat_6F3E
	dw Pat_70BE
	dw Pat_6FDA
	dw Pat_705C
	dw Pat_6FDA
	dw Pat_705C
	ORDER_LOOP Song12_Ch3
Song12_Ch2:
	dw Pat_70DD
	dw Pat_7111
	dw Pat_70DD
	dw Pat_7188
	dw Pat_711E
	dw Pat_715D
	dw Pat_711E
	dw Pat_715D
	ORDER_LOOP Song12_Ch2
Song12_Ch1:
	dw Pat_7192
	dw Pat_71C5
	dw Pat_7192
	dw Pat_7246
	dw Pat_71DE
	dw Pat_7219
	dw Pat_71DE
	dw Pat_7219
	ORDER_LOOP Song12_Ch1
Pat_6F3E:
	WAVE Wave_7BBD
	RELEASE $01, $11
	INSTR 0
	LEN 20
	NOTE C_, 2
	INSTR 1
	LEN 10
	NOTE C_, 2
	NOTE C_, 2
	INSTR 0
	LEN 20
	NOTE C_, 2
	INSTR 1
	LEN 10
	NOTE C_, 2
	NOTE C_, 2
	INSTR 0
	LEN 20
	NOTE C_, 2
	INSTR 1
	LEN 10
	NOTE C_, 2
	NOTE C_, 2
	INSTR 0
	LEN 20
	NOTE C_, 2
	INSTR 1
	LEN 10
	NOTE C_, 2
	NOTE C_, 2
	INSTR 0
	LEN 20
	NOTE C_, 2
	INSTR 1
	LEN 10
	NOTE C_, 2
	NOTE C_, 2
	INSTR 0
	LEN 20
	NOTE C_, 2
	INSTR 1
	LEN 10
	NOTE C_, 2
	NOTE C_, 2
	INSTR 0
	LEN 20
	NOTE C_, 2
	INSTR 1
	LEN 10
	NOTE C_, 2
	NOTE C_, 2
	INSTR 0
	LEN 20
	NOTE C_, 3
	INSTR 1
	LEN 10
	NOTE C_, 2
	NOTE C_, 2
	INSTR 0
	LEN 20
	NOTE D_, 2
	INSTR 1
	LEN 10
	NOTE D_, 2
	NOTE D_, 2
	INSTR 0
	LEN 20
	NOTE D_, 2
	INSTR 1
	LEN 10
	NOTE D_, 2
	NOTE D_, 2
	INSTR 0
	LEN 20
	NOTE D_, 2
	INSTR 1
	LEN 10
	NOTE D_, 2
	NOTE D_, 2
	INSTR 0
	LEN 20
	NOTE D_, 2
	INSTR 1
	LEN 10
	NOTE D_, 2
	NOTE D_, 2
	INSTR 0
	LEN 20
	NOTE A_, 2
	INSTR 1
	LEN 10
	NOTE A_, 2
	NOTE A_, 2
	INSTR 0
	LEN 20
	NOTE A_, 2
	INSTR 1
	LEN 10
	NOTE A_, 2
	NOTE A_, 2
	INSTR 0
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 2
	NOTE G_, 2
	INSTR 0
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 2
	NOTE G_, 2
	NEXT
Pat_6FB5:
	INSTR 0
	LEN 20
	NOTE F_, 2
	NOTE F_, 3
	NOTE E_, 2
	NOTE E_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 2
	NOTE G_, 2
	INSTR 0
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 2
	NOTE G_, 2
	INSTR 0
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 2
	NOTE G_, 2
	INSTR 0
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 2
	NOTE G_, 2
	NEXT
Pat_6FDA:
	INSTR 0
	LEN 10
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE E_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE E_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE E_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE E_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE E_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE E_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE E_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE E_, 3
	NEXT
Pat_705C:
	INSTR 0
	LEN 10
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE C_, 3
	NEXT
Pat_70BE:
	INSTR 0
	LEN 20
	NOTE F_, 2
	NOTE F_, 3
	NOTE E_, 2
	NOTE E_, 3
	NOTE D_, 2
	NOTE D_, 3
	NOTE C_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN 10
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	NEXT
Pat_70DD:
	HWENV $F6, $2C, $80
	VIBRATO $0B, $01, $05
	ARP_OFF
	DUTY_75
	RELEASE $01, $81
	LEN 20
	NOTE C_, 3
	NOTE G_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	LENGTH $3C
	NOTE Ash, 3
	LEN 10
	NOTE A_, 3
	NOTE Gsh, 3
	LENGTH $50
	NOTE G_, 3
	LEN 20
	NOTE D_, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE A_, 3
	NOTE D_, 4
	LENGTH $3C
	NOTE E_, 4
	LEN 10
	NOTE D_, 4
	NOTE C_, 4
	LEN 40
	NOTE D_, 4
	LEN 20
	NOTE B_, 3
	NOTE D_, 4
	NEXT
Pat_7111:
	LEN 40
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE G_, 3
	NOTE G_, 3
	LEN 20
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE D_, 3
	NEXT
Pat_711E:
	HWENV $8A, $0B, $A6
	ARP 0
	LEN 10
	NOTE F_, 4
	LEN 20
	NOTE C_, 5
	NOTE B_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE G_, 4
	LEN 10
	NOTE A_, 4
	LEN 20
	NOTE A_, 4
	LEN 10
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 4
	LEN 20
	NOTE C_, 5
	NOTE B_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE F_, 4
	LEN 10
	NOTE G_, 4
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NEXT
Pat_715D:
	LEN 10
	NOTE G_, 4
	LEN 20
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	NOTE A_, 4
	LEN 20
	NOTE C_, 4
	LEN 10
	NOTE D_, 4
	LEN 20
	NOTE E_, 4
	LEN 10
	NOTE E_, 4
	LEN 20
	NOTE F_, 4
	LEN 10
	NOTE F_, 4
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE G_, 4
	LEN 20
	NOTE Ash, 4
	LEN 10
	NOTE Ash, 4
	LEN 20
	NOTE A_, 4
	NOTE F_, 4
	NEXT
Pat_7188:
	LEN 40
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE B_, 3
	NEXT
Pat_7192:
	DRUMS $0A, DrumPat_726F
	HWENV $F6, $2C, $80
	VIBRATO $0B, $01, $05
	ARP_OFF
	DUTY_50
	LENGTH $78
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE G_, 4
	LENGTH $3C
	NOTE Ash, 4
	LEN 10
	NOTE A_, 4
	NOTE Gsh, 4
	LENGTH $50
	NOTE G_, 4
	LENGTH $78
	NOTE D_, 5
	LEN 10
	NOTE Csh, 5
	NOTE D_, 5
	NOTE Csh, 5
	NOTE A_, 4
	LENGTH $3C
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	NOTE A_, 4
	LEN 40
	NOTE B_, 4
	LEN 20
	NOTE G_, 4
	NOTE B_, 4
	NEXT
Pat_71C5:
	LEN 30
	NOTE A_, 4
	LEN 10
	NOTE F_, 4
	LEN 30
	NOTE G_, 4
	LEN 10
	NOTE E_, 4
	LEN 30
	NOTE F_, 4
	LEN 10
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE E_, 4
	LENGTH $78
	NOTE D_, 4
	LEN 10
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NEXT
Pat_71DE:
	DRUMS $0A, DrumPat_7292
	RELEASE $01, $81
	ARP 0
	LEN 10
	NOTE F_, 3
	NOTE C_, 4
	WAIT2
	NOTE B_, 3
	WAIT2
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE A_, 3
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE B_, 3
	WAIT2
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE A_, 3
	NOTE A_, 3
	WAIT2
	LENGTH $8C
	NOTE F_, 3
	LEN 10
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE B_, 3
	WAIT2
	LEN 20
	NOTE G_, 3
	LEN 10
	NOTE A_, 3
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE B_, 3
	WAIT2
	LEN 20
	NOTE F_, 3
	LEN 10
	NOTE G_, 3
	NOTE G_, 3
	WAIT2
	LENGTH $82
	NOTE E_, 3
	LEN 10
	WAIT2
	NEXT
Pat_7219:
	LEN 10
	WAIT
	NOTE D_, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	LEN 20
	NOTE B_, 3
	LEN 10
	NOTE G_, 3
	WAIT2
	NOTE D_, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	LEN 20
	NOTE B_, 3
	LEN 10
	NOTE C_, 4
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE B_, 3
	WAIT2
	LEN 20
	NOTE A_, 3
	LEN 10
	NOTE F_, 3
	WAIT2
	NOTE C_, 4
	WAIT2
	NOTE B_, 3
	WAIT2
	LEN 20
	NOTE C_, 3
	LEN 10
	NOTE D_, 3
	NOTE E_, 3
	WAIT2
	LENGTH $82
	NOTE E_, 3
	LEN 10
	WAIT2
	NEXT
Pat_7246:
	LEN 30
	NOTE A_, 4
	LEN 10
	NOTE F_, 4
	LEN 30
	NOTE G_, 4
	LEN 10
	NOTE E_, 4
	LEN 30
	NOTE F_, 4
	LEN 10
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE E_, 4
	LEN 40
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN 10
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NEXT

; Instrument table 10, entries 1..2 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr10_0
	dw Instr10_1
Instr10_0:
	VOLENV 15, $11, $1F, $13
	ARP 8
	END
Instr10_1:
	VOLENV 15, $11, $1F, $11
	END
DrumPat_726F:
	db DRUM_TEMPO + 5, DRUM_LEVEL + 14, 9, 0, 0, 0, 10, 0
	db 10, 0, 9, 0, 0, 0, 10, 0
	db 10, 0, 9, 0, 0, 0, 10, 10
	db 10, 10, 9, 0, 9, 0, 9, 0
	db 0, 0, DRUM_LOOP
DrumPat_7292:
	db DRUM_LEVEL + 12, 6, DRUM_LEVEL + 11, 4, DRUM_LEVEL + 15, 9, DRUM_LEVEL + 11, 4
	db DRUM_LOOP

; Song 13: instrument table - (none set), arpeggio table 1 (the one SndInit sets)
PlaySong13:
	call StopAll
	ld de, Song13_Ch1
	call StartMusicCh1
	ld de, Song13_Ch3
	call StartMusicCh3
	ld de, Song13_Ch2
	jp StartMusicCh2
Song13_Ch1:
	dw Pat_72B6
Song13_Ch3:
	dw Pat_72EA
Song13_Ch2:
	dw Pat_7329
Pat_72B6:
	ARP 8
	HWENV $F7, $00
	DUTY_50
	LEN 33
	NOTE C_, 2
	NOTE C_, 2
	NOTE Gsh, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE Gsh, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE Gsh, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE Gsh, 2
	NOTE G_, 2
	LEN 22
	NOTE C_, 2
	NOTE C_, 2
	LEN 11
	NOTE C_, 3
	NOTE C_, 2
	LEN 22
	NOTE C_, 2
	NOTE C_, 2
	LEN 11
	NOTE C_, 3
	NOTE C_, 2
	LEN 22
	NOTE C_, 2
	LEN 11
	NOTE C_, 2
	NOTE C_, 3
	LEN 11
	NOTE C_, 3
	NOTE C_, 3
	LENGTH $58
	NOTE C_, 2
	LENGTH $94
	WAIT2
	WAIT2
	WAIT2
	WAIT2
	END
Pat_72EA:
	VIBRATO $16, $02, $05
	CH_TRANSPOSE $0C
	WAVE Wave_7C5D
	VOLENV 15, $1F, $1F, $4F
	LENGTH $6E
	NOTE C_, 4
	LEN 11
	NOTE D_, 4
	NOTE Dsh, 4
	LENGTH $6E
	NOTE D_, 4
	LEN 11
	NOTE Dsh, 4
	NOTE F_, 4
	LENGTH $6E
	NOTE Dsh, 4
	LEN 11
	NOTE F_, 4
	NOTE G_, 4
	LENGTH $42
	NOTE F_, 4
	LEN 33
	NOTE Gsh, 4
	NOTE G_, 4
	LENGTH $84
	NOTE C_, 4
	VOLENV 15, $11, $1F, $15
	ARP 5
	LEN 22
	NOTE C_, 4
	LEN 11
	NOTE C_, 4
	NOTE C_, 4
	LEN 11
	NOTE C_, 4
	NOTE C_, 4
	LENGTH $4D
	NOTE C_, 4
	LENGTH $97
	WAIT2
	WAIT2
	WAIT2
	WAIT2
	END
Pat_7329:
	DRUMS $0B, DrumPat_738D
	HWENV $A0, $00
	VIBRATO $16, $01, $05
	DUTY_50
	LEN 11
	NOTE Dsh, 3
	NOTE D_, 3
	NOTE C_, 3
	NOTE Dsh, 3
	NOTE D_, 3
	NOTE C_, 3
	NOTE Dsh, 3
	NOTE D_, 3
	NOTE C_, 3
	NOTE Dsh, 3
	NOTE D_, 3
	NOTE C_, 3
	NOTE F_, 3
	NOTE Dsh, 3
	NOTE D_, 3
	NOTE F_, 3
	NOTE Dsh, 3
	NOTE D_, 3
	NOTE F_, 3
	NOTE Dsh, 3
	NOTE D_, 3
	NOTE F_, 3
	NOTE Dsh, 3
	NOTE D_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE Dsh, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE Dsh, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE Dsh, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE Dsh, 3
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE Gsh, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	HWENV $F3, $00
	DRUMS $0B, DrumPat_739B
	ARP 5
	LEN 22
	NOTE C_, 4
	NOTE C_, 4
	LEN 11
	NOTE C_, 4
	NOTE C_, 4
	LEN 22
	NOTE C_, 4
	NOTE C_, 4
	LEN 11
	NOTE C_, 4
	NOTE C_, 4
	LEN 22
	NOTE C_, 5
	LEN 11
	NOTE C_, 5
	NOTE C_, 5
	LEN 11
	NOTE C_, 5
	NOTE C_, 5
	LENGTH $42
	NOTE C_, 5
	LENGTH $9A
	WAIT2
	DRUMS_OFF
	WAIT2
	WAIT2
	WAIT2
	END
DrumPat_738D:
	db DRUM_LEVEL + 13, 9, 0, 9, 9, 0, 9, 9
	db 9, 9, 9, 0, 9, DRUM_LOOP
DrumPat_739B:
	db 9, 0, 9, 0, 9, 9, 9, 0
	db 9, 0, 9, 9, 9, 0, 9, 9
	db 9, 9, 7, DRUM_TEMPO + 48, 0, 0, 0, 0
	db 0, 0, 0, 0, DRUM_LOOP

; Song 14: instrument table 11, arpeggio table 1 (the one SndInit sets)
PlaySong14:
	ld a, $75
	ld [wInstrTableHi], a
	ld a, $41
	ld [wInstrTable], a
	call StopAll
	ld de, Song14_Ch3
	call StartMusicCh3
	ld de, Song14_Ch2
	call StartMusicCh2
	ld de, Song14_Ch1
	jp StartMusicCh1
Song14_Ch3:
	dw Pat_73F5
	dw Pat_740A
	dw Pat_7419

; Unreferenced (4 bytes)
	db $00, $00, $D7, $73
Song14_Ch2:
	dw Pat_742C
	dw Pat_7450
	dw Pat_74D0

; Unreferenced (4 bytes)
	db $00, $00, $E1, $73
Song14_Ch1:
	dw Pat_7502
	dw Pat_7526
	dw Pat_7534

; Unreferenced (4 bytes)
	db $00, $00, $EB, $73
Pat_73F5:
	WAVE Wave_7BBD
	CH_TRANSPOSE $00
	ARP 0
	VOLENV 10, $00, $00, $00
	VIBRATO $0A, $05, $05
	LENGTH $A0
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	WAIT
	NEXT
Pat_740A:
	VOLENV 15, $11, $1F, $1A
	LENGTH $50
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NEXT
Pat_7419:
	LEN 20
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN 10
	NOTE G_, 2
	LENGTH $D2
	WAIT2
	LENGTH $82
	REST
	REST
	END
Pat_742C:
	INSTR 0
	LENGTH $78
	NOTE C_, 4
	LEN 10
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE G_, 3
	LENGTH $3C
	NOTE Ash, 3
	LEN 10
	NOTE C_, 4
	LENGTH $5A
	WAIT2
	LENGTH $78
	NOTE C_, 4
	LEN 10
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE G_, 3
	LENGTH $3C
	NOTE Ash, 3
	LEN 10
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE G_, 3
	LENGTH $46
	WAIT2
	NEXT
Pat_7450:
	INSTR 0
	LEN 20
	NOTE C_, 3
	LEN 10
	NOTE D_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE Dsh, 3
	INSTR 1
	NOTE D_, 3
	INSTR 0
	NOTE D_, 3
	INSTR 1
	NOTE Dsh, 3
	INSTR 0
	NOTE F_, 3
	INSTR 1
	NOTE D_, 3
	INSTR 0
	NOTE Dsh, 3
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE D_, 3
	INSTR 1
	NOTE Dsh, 3
	INSTR 0
	NOTE Dsh, 3
	INSTR 1
	NOTE D_, 3
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE Dsh, 3
	INSTR 0
	NOTE D_, 3
	INSTR 1
	NOTE C_, 3
	INSTR 0
	NOTE Dsh, 3
	INSTR 1
	NOTE D_, 3
	INSTR 0
	NOTE D_, 3
	INSTR 1
	NOTE Dsh, 3
	INSTR 0
	NOTE F_, 3
	INSTR 1
	NOTE D_, 3
	INSTR 0
	NOTE Dsh, 3
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE D_, 3
	INSTR 1
	NOTE Dsh, 3
	INSTR 0
	NOTE Dsh, 3
	INSTR 1
	NOTE D_, 3
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE Dsh, 3
	INSTR 0
	NOTE D_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE Dsh, 4
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 4
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE F_, 4
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE Dsh, 4
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE D_, 4
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE Dsh, 4
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE D_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE Dsh, 4
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 4
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE Dsh, 4
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE F_, 4
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE Dsh, 4
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 4
	INSTR 1
	NOTE Dsh, 4
	NEXT
Pat_74D0:
	LEN 10
	HWENV $80, $00
	RELEASE $00
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE B_, 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE B_, 4
	NOTE D_, 5
	HWENV $50, $00
	NOTE F_, 5
	NOTE B_, 4
	NOTE D_, 5
	HWENV $30, $00
	NOTE F_, 5
	NOTE B_, 4
	NOTE D_, 5
	HWENV $20, $00
	NOTE F_, 5
	NOTE B_, 4
	NOTE D_, 5
	HWENV $10, $00
	NOTE F_, 5
	NOTE B_, 4
	NOTE D_, 5
	REST
	END
Pat_7502:
	INSTR 0
	LENGTH $78
	NOTE C_, 3
	LEN 10
	NOTE B_, 2
	NOTE C_, 3
	NOTE B_, 2
	NOTE G_, 2
	LENGTH $3C
	NOTE Ash, 2
	LEN 10
	NOTE C_, 3
	LENGTH $5A
	WAIT2
	LENGTH $78
	NOTE C_, 3
	LEN 10
	NOTE B_, 2
	NOTE C_, 3
	NOTE B_, 2
	NOTE G_, 2
	LENGTH $3C
	NOTE Ash, 2
	LEN 10
	NOTE A_, 2
	NOTE Gsh, 2
	NOTE G_, 2
	LENGTH $46
	WAIT2
	NEXT
Pat_7526:
	LENGTH $A0
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	LENGTH $50
	NOTE Ash, 3
	LEN 40
	NOTE B_, 3
	LEN 20
	NOTE Gsh, 3
	NOTE G_, 3
	NEXT
Pat_7534:
	LEN 30
	NOTE G_, 3
	NOTE B_, 3
	LEN 20
	NOTE D_, 4
	LENGTH $50
	NOTE G_, 3
	LEN 10
	NOTE G_, 3
	LENGTH $EB
	WAIT2
	WAIT2
	END

; Instrument table 11, entries 1..2 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr11_0
	dw Instr11_1
Instr11_0:
	HWENV $49, $04, $80
	RELEASE $01, $82
	VIBRATO $14, $01, $05
	DUTY_75
	END
Instr11_1:
	HWENV $50, $00
	RELEASE $01, $52
	VIBRATO $14, $01, $05
	DUTY_75
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

; Unreferenced (26 bytes)
	db $17, $76, $1C, $76, $33, $76, $37, $76, $3B, $76, $3F, $76, $42, $76, $45, $76
	db $49, $76, $4D, $76, $55, $76, $5C, $76, $62, $76
Arp0:
	db $0C, $00, ARP_HOLD
Arp1:
	db $0E, $00, $01, $01, $02, ARP_HOLD
Arp2:
	db $07, $0C, $03, $00, ARP_HOLD
Arp3:
	db $18, $0C, $00, $00, $00, $00, $00, $00
	db $00, ARP_LOOP
Arp4:
	db $00, $04, $07, ARP_LOOP
Arp5:
	db $00, $03, $07, ARP_LOOP
Arp6:
	db $07, $0C, $03, $00, $00, $00, $00, $00
	db $00, $00, $13, $18, $0F, $0C, $0C, $0C
	db $0C, $0C, $0C, $0C, ARP_LOOP
Arp7:
	db $18, $0C, $03, $00, ARP_HOLD
Arp8:
	db $18, $0C, $00, ARP_HOLD
Arp9:
	db $0C, $0C, $00, $00, ARP_LOOP
Arp10:
	db $0C, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $00, ARP_LOOP
Arp11:
	db $0C, $00, $00, $00, $00, $00, $00, $00
	db $00, $0C, $0C, $0C, $0C, $0C, $0C, $0C
	db $0C, $0C, ARP_HOLD
Arp12:
	db $00, $0C, $00, ARP_HOLD
Arp13:
	db $0C, $00, $00, $00, $00, $00, $0C, $0C
	db $0C, $0C, $0C, $0C, ARP_LOOP
Arp14:
	db $00, $00, $01, $01, $02, ARP_HOLD

; Unreferenced (78 bytes)
	db $00, $00, $00, $01, $FF, $0C, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $18, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C, $6A, $0C, $07, $00, $6A
	db $0C, $09, $00, $6A, $0C, $08, $00, $6A, $00, $0C, $6A, $00, $01, $6A, $00, $0C
	db $00, $FF, $18, $0C, $00, $FF, $0C, $00, $00, $00, $00, $00, $00, $6A, $00, $0C
	db $04, $10, $07, $13, $6A, $0E, $00, $01, $01, $02, $FF, $0C
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

; Sound effect 1
Sfx01:
	VOLENV 12, $11, $1F, $14
	WAVE Wave_7BDD
	VIBRATO $01, $01, $08
	LEN 40
	NOTE C_, 4
	END

; Sound effect 2
Sfx02:
	VOLENV 12, $11, $1F, $14
	WAVE Wave_7BDD
	VIBRATO $01, $01, $08
	LEN 40
	NOTE D_, 4
	END

; Sound effect 3
Sfx03:
	VOLENV 12, $11, $1F, $14
	WAVE Wave_7BDD
	VIBRATO $01, $01, $08
	LEN 40
	NOTE E_, 4
	END

; Sound effect 4
Sfx04:
	VOLENV 12, $11, $1F, $14
	WAVE Wave_7BDD
	VIBRATO $01, $01, $08
	LEN 40
	NOTE F_, 4
	END

; Sound effect 5
Sfx05:
	VOLENV 12, $11, $1F, $14
	WAVE Wave_7BDD
	VIBRATO $01, $01, $08
	LEN 40
	NOTE G_, 4
	END

; Sound effect 6
Sfx06:
	VOLENV 15, $00, $1F, $12
	WAVE Wave_7C4D
	CALL_CODE Drum6
	LEN 4
	GLIDE $FD
	NOTE C_, 5
	GLIDE_OFF
	LEN 20
	NOTE F_, 3
	END

; Sound effect 7
Sfx07:
	VOLENV 15, $00, $1F, $12
	WAVE Wave_7C4D
	CALL_CODE Drum6
	LEN 4
	GLIDE $FD
	NOTE C_, 5
	GLIDE_OFF
	LEN 20
	NOTE Ash, 3
	END

; Sound effect 8
Sfx08:
	CALL_CODE Code_7AA1
	END

; Sound effect 9
Sfx09:
	VOLENV 15, $11, $2F, $11
	WAVE Wave_7BDD
	LEN 13
	NOTE C_, 6
	END

; Sound effect 10
Sfx10:
	LEN 4
	VOLENV 15, $11, $2F, $11
	WAVE Wave_7BDD
	LEN 4
	NOTE Gsh, 5
	LEN 1
	REST
	LEN 4
	NOTE Gsh, 6
	END

; Sound effect 11
Sfx11:
	VOLENV 15, $11, $1F, $11
	CALL_CODE Code_79C0
	WAVE Wave_7BBD
	LEN 12
	GLIDE $FE
	NOTE C_, 3
	END

; Sound effect 12
Sfx12:
	CALL_CODE Code_7A1A
	END

; Sound effect 13
Sfx13:
	LEN 5
	ARP 0
	WAVE Wave_7C5D
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
	CALL_CODE Code_792C
	END

; Sound effect 15
Sfx15:
	VOLENV 15, $11, $1F, $14
	WAVE Wave_7BDD
	VIBRATO $01, $01, $08
	LEN 4
	NOTE C_, 4
	NOTE C_, 5
	NOTE Gsh, 4
	END

; Sound effect 16
Sfx16:
	CALL_CODE Code_79F1
	END

; Sound effect 17
Sfx17:
	VOLENV 12, $11, $1F, $14
	WAVE Wave_7BBD
	GLIDE $04
	LEN 4
	NOTE G_, 3
	GLIDE $FD
	LEN 6
	WAIT
	REST
	END

; Sound effect 18
Sfx18:
	VOLENV 15, $00, $00, $00
	WAVE Wave_7B4D
	GLIDE $04
	LEN 6
	NOTE G_, 2
	LEN 4
	GLIDE $FE
	NOTE Dsh, 5
	GLIDE $01
	WAIT
	GLIDE $FE
	WAIT
	GLIDE $01
	WAIT
	GLIDE $FE
	WAIT
	GLIDE $01
	WAIT
	GLIDE $FE
	WAIT
	GLIDE $01
	WAIT
	GLIDE $FE
	WAIT
	WAIT
	END

; Sound effect 19
Sfx19:
	VOLENV 10, $11, $1F, $12
	WAVE Wave_7BBD
	LEN 13
	SLIDE_DOWN $03
	NOTE A_, 5
	END

; Sound effect 20
Sfx20:
	VOLENV 10, $11, $10, $00
	WAVE Wave_7CAD
	GLIDE $02
	LEN 5
	NOTE A_, 2
	GLIDE_OFF
	LEN 3
	WAIT
	GLIDE $02
	WAIT
	END

; Sound effect 21
Sfx21:
	VOLENV 12, $11, $1F, $13
	WAVE Wave_7BBD
	LEN 4
	NOTE C_, 5
	LEN 25
	NOTE C_, 6
	VIBRATO $05, $01, $04
	END

; Sound effect 22
Sfx22:
	VOLENV 15, $00, $00, $00
	WAVE Wave_7D1D
	LEN 3
	GLIDE $FF
	NOTE E_, 5
	WAVE Wave_7CED
	WAIT
	WAVE Wave_7D0D
	END

; Sound effect 23
Sfx23:
	CALL_CODE Code_7836
	WAVE Wave_7BBD
	VOLENV 10, $11, $1F, $12
	LEN 7
	GLIDE $01
	NOTE C_, 3
	NOTE G_, 2
	END

; Sound effect 24
Sfx24:
	CALL_CODE Code_7863
	END

; Sound effect 25
Sfx25:
	CALL_CODE Code_78C1
	END

; Sound effect 26
Sfx26:
	CALL_CODE Code_78E3
	END

; Sound effect 27
Sfx27:
	VOLENV 15, $00, $00, $00
	VIBRATO $01, $08, $01
	WAVE Wave_7B3D
	GLIDE $01
	LEN 18
	NOTE G_, 2
	GLIDE $00
	LEN 12
	WAIT
	END

; Sound effect 28
Sfx28:
	VOLENV 15, $00, $00, $00
	WAVE Wave_7CAD
	LEN 5
	NOTE A_, 3
	LEN 3
	REST
	LEN 20
	NOTE A_, 3
	END
Noise43_781A:
	db $82, $64, $02, $37, $47, $24, $55, $71
	db $07, $44, $60, $36, $84, $82, $64, $02
	db $37, $47, $24, $55, $71, $07, $44, $60
	db $36, $86, $32, $FF
Code_7836:
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
	ld a, HIGH(Noise43_781A)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_781A)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Code_7863:
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
	ld a, HIGH(Noise43_781A)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_781A)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret

; Unreferenced (49 bytes)
	db $3E, $08, $EA, $41, $C1, $AF, $EA, $55, $C1, $3C, $EA, $56, $C1, $3E, $78, $EA
	db $51, $C1, $3E, $B2, $EA, $52, $C1, $3E, $78, $EA, $53, $C1, $3E, $BA, $EA, $54
	db $C1, $C9, $60, $52, $42, $41, $22, $11, $21, $FF, $F0, $F0, $F0, $F0, $F0, $F0
	db $61
Code_78C1:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7905)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7905)
	ld [wNoise43], a
	ld a, HIGH(Noise42_791F)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_791F)
	ld [wNoise42], a
	ret
Code_78E3:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7912)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7912)
	ld [wNoise43], a
	ld a, HIGH(Noise42_791F)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_791F)
	ld [wNoise42], a
	ret
Noise43_7905:
	db $10, $10, $20, $31, $32, $33, $33, $34
	db $34, $35, $35, $36, $FF
Noise43_7912:
	db $36, $35, $35, $34, $34, $33, $33, $32
	db $31, $20, $10, $10, $FF
Noise42_791F:
	db $5C, $FF, $FF, $FF, $FF, $FF, $A1, $FF
	db $FF, $FF, $FF, $FF

; Unreferenced (1 bytes)
	db $FF
Code_792C:
	ld a, $0A
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_794E)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_794E)
	ld [wNoise43], a
	ld a, HIGH(Noise42_795A)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_795A)
	ld [wNoise42], a
	ret
Noise43_794E:
	db $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0
	db $A0, $A0, $A0, $FF
Noise42_795A:
	db $F0, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $00

; Unreferenced (91 bytes)
	db $3E, $32, $EA, $41, $C1, $AF, $EA, $55, $C1, $3C, $EA, $56, $C1, $3E, $79, $EA
	db $51, $C1, $3E, $87, $EA, $52, $C1, $3E, $79, $EA, $53, $C1, $3E, $A4, $EA, $54
	db $C1, $C9, $20, $30, $30, $30, $32, $42, $42, $42, $42, $42, $20, $30, $30, $30
	db $32, $42, $42, $42, $42, $42, $42, $42, $42, $22, $82, $81, $80, $54, $FF, $F0
	db $FF, $55, $00, $B2, $FF, $FF, $FF, $FF, $FF, $F0, $FF, $55, $00, $B2, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $F0, $FF, $FF, $FF, $F4
Code_79C0:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_79E2)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_79E2)
	ld [wNoise43], a
	ld a, HIGH(Noise42_79EA)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_79EA)
	ld [wNoise42], a
	ret
Noise43_79E2:
	db $02, $51, $61, $71, $91, $71, $60, $FF
Noise42_79EA:
	db $F0, $F0, $F0, $F0, $F0, $70, $63
Code_79F1:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7A13)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7A13)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7A17)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7A17)
	ld [wNoise42], a
	ret
Noise43_7A13:
	db $02, $51, $11, $FF
Noise42_7A17:
	db $F0, $A0, $55
Code_7A1A:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7A3C)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7A3C)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7A42)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7A42)
	ld [wNoise42], a
	ret
Noise43_7A3C:
	db $02, $41, $61, $71, $11, $FF
Noise42_7A42:
	db $F0, $FF, $FF, $A0, $B2

; Unreferenced (90 bytes)
	db $3E, $08, $EA, $41, $C1, $AF, $EA, $55, $C1, $3C, $EA, $56, $C1, $3E, $7A, $EA
	db $51, $C1, $3E, $69, $EA, $52, $C1, $3E, $7A, $EA, $53, $C1, $3E, $6F, $EA, $54
	db $C1, $C9, $00, $83, $60, $60, $31, $FF, $F0, $FF, $FF, $FF, $D1, $3E, $04, $EA
	db $41, $C1, $AF, $EA, $55, $C1, $3C, $EA, $56, $C1, $3E, $7A, $EA, $51, $C1, $3E
	db $96, $EA, $52, $C1, $3E, $7A, $EA, $53, $C1, $3E, $9C, $EA, $54, $C1, $C9, $00
	db $53, $71, $91, $31, $FF, $F1, $FF, $FF, $FF, $00
Code_7AA1:
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7AC3)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7AC3)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7ACA)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7ACA)
	ld [wNoise42], a
	ret
Noise43_7AC3:
	db $41, $61, $61, $41, $71, $71, $FF
Noise42_7ACA:
	db $A1, $52, $00, $61, $52, $00

; Unreferenced (109 bytes)
	db $3E, $32, $EA, $41, $C1, $AF, $EA, $55, $C1, $3C, $EA, $56, $C1, $3E, $02, $EA
	db $59, $C1, $AF, $EA, $58, $C1, $3E, $7A, $EA, $51, $C1, $3E, $FB, $EA, $52, $C1
	db $3E, $7B, $EA, $53, $C1, $3E, $06, $EA, $54, $C1, $C9, $27, $26, $25, $14, $13
	db $12, $11, $10, $10, $10, $FF, $19, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $F3
	db $3E, $19, $EA, $41, $C1, $AF, $EA, $55, $C1, $3C, $EA, $56, $C1, $3E, $7B, $EA
	db $51, $C1, $3E, $32, $EA, $52, $C1, $3E, $7B, $EA, $53, $C1, $3E, $38, $EA, $54
	db $C1, $C9, $03, $83, $80, $80, $51, $FF, $F0, $FF, $FF, $FF, $F2
Wave_7B3D:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $00, $00, $00, $77, $77, $00, $00, $00
Wave_7B4D:
	db $01, $11, $11, $00, $89, $AA, $AA, $98
	db $01, $11, $11, $00, $FF, $FF, $FF, $FF

; Unreferenced (80 bytes)
	db $A8, $40, $04, $8A, $FF, $FF, $FF, $FF, $A8, $40, $04, $8A, $FF, $FF, $FF, $FF
	db $8C, $FE, $ED, $B8, $53, $21, $10, $24, $84, $01, $12, $35, $8B, $DE, $EF, $8C
	db $00, $46, $8A, $FF, $FF, $A8, $64, $00, $00, $46, $8A, $FF, $FF, $A8, $64, $00
	db $B7, $40, $F4, $7B, $FD, $FF, $FE, $DC, $02, $46, $8A, $BD, $FD, $BA, $6F, $20
	db $32, $22, $11, $11, $11, $22, $23, $45, $FD, $CB, $A9, $87, $65, $43, $21, $10
Wave_7BAD:
	db $DD, $DB, $97, $52, $22, $54, $22, $22
	db $DD, $DC, $BD, $DD, $DB, $85, $22, $22
Wave_7BBD:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF

; Unreferenced (16 bytes)
	db $01, $11, $11, $00, $89, $AA, $AA, $98, $01, $11, $11, $00, $FF, $FF, $FF, $FF
Wave_7BDD:
	db $00, $00, $00, $00, $CD, $EF, $FD, $EC
	db $00, $12, $21, $00, $DD, $DD, $DD, $DD
Wave_7BED:
	db $00, $00, $00, $00, $00, $00, $FF, $FF
	db $00, $00, $00, $00, $00, $00, $FF, $FF
Wave_7BFD:
	db $00, $00, $00, $00, $00, $00, $FF, $00
	db $00, $00, $00, $00, $00, $00, $FF, $00

; Unreferenced (16 bytes)
	db $00, $00, $00, $CD, $EF, $FF, $FF, $FF, $04, $8C, $FF, $FF, $FF, $FF, $FF, $FF
Wave_7C1D:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $00, $FF, $FF, $FF

; Unreferenced (32 bytes)
	db $12, $34, $56, $78, $9A, $BC, $DE, $FF, $ED, $CB, $A9, $87, $65, $43, $21, $00
	db $FF, $FE, $ED, $B8, $53, $21, $10, $00, $00, $01, $12, $35, $8B, $DE, $EF, $FF
Wave_7C4D:
	db $63, $10, $00, $00, $00, $00, $01, $36
	db $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9
Wave_7C5D:
	db $63, $10, $01, $47, $74, $10, $01, $36
	db $9C, $EF, $FE, $B8, $8B, $EF, $FE, $C9
Wave_7C6D:
	db $63, $1F, $01, $47, $74, $10, $01, $36
	db $9C, $E0, $FE, $B8, $8B, $EF, $FE, $C9
Wave_7C7D:
	db $65, $43, $22, $27, $72, $22, $22, $29
	db $AB, $CC, $BA, $98, $9C, $EE, $EE, $C9

; Unreferenced (16 bytes)
	db $63, $20, $02, $47, $74, $22, $22, $36, $9C, $EF, $FE, $B6, $6B, $EE, $EE, $C9
Wave_7C9D:
	db $B7, $40, $04, $7B, $CD, $FF, $FE, $DC
	db $02, $46, $8A, $BD, $FD, $BA, $64, $20
Wave_7CAD:
	db $0F, $00, $F0, $F0, $F0, $F0, $00, $0F
	db $0F, $FF, $FF, $00, $FF, $F0, $0F, $0F

; Unreferenced (16 bytes)
	db $BB, $2B, $BB, $2B, $BB, $5B, $2B, $BB, $2B, $BB, $BB, $72, $27, $EB, $BB, $B0
Wave_7CCD:
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $ED, $CB, $A9, $87, $65, $43, $21, $00

; Unreferenced (16 bytes)
	db $FE, $DB, $97, $53, $13, $54, $32, $10, $FE, $DC, $BC, $EF, $DB, $85, $32, $10
Wave_7CED:
	db $04, $8B, $DE, $FF, $ED, $CB, $A9, $87
	db $65, $44, $44, $32, $11, $24, $7A, $74

; Unreferenced (16 bytes)
	db $20, $13, $69, $BD, $FD, $B9, $64, $20, $13, $68, $B8, $64, $20, $24, $68, $64
Wave_7D0D:
	db $20, $24, $68, $AC, $EC, $A8, $64, $20
	db $24, $68, $A8, $64, $20, $24, $68, $64
Wave_7D1D:
	db $02, $48, $AC, $FF, $FC, $53, $00, $27
	db $9C, $DD, $DC, $B7, $7B, $CD, $DD, $C9
Wave_7D2D:
	db $BD, $FF, $AC, $FF, $FC, $52, $00, $27
	db $9C, $DF, $DC, $B7, $7B, $CD, $AD, $C9
Noise43_7D3D:
	db $02, $51, $61, $71, $91, $71, $60, $FF
Noise42_7D45:
	db $F0, $F0, $D0, $90, $70, $40, $31
Noise43_7D4C:
	db $06, $04, $03, $03, $07, $FF
Noise42_7D52:
	db $F0, $C0, $80, $60, $55
Noise43_7D57:
	db $04, $02, $01, $01, $FF
Noise42_7D5C:
	db $80, $40, $30, $23
Noise43_7D60:
	db $04, $02, $01, $01, $04, $02, $01, $FF
Noise42_7D68:
	db $A0, $60, $33, $23, $A0, $60, $33
Noise43_7D6F:
	db $04, $02, $06, $06, $FF
Noise42_7D74:
	db $C0, $80, $60, $44
Noise43_7D78:
	db $50, $41, $50, $51, $42, $53, $51, $FF
Noise42_7D80:
	db $F0, $70, $F0, $70, $D0, $70, $61

; Unreferenced (8 bytes)
	db $3E, $08, $EA, $41, $C1, $CD, $8E, $49
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7D3D)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7D3D)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7D45)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7D45)
	ld [wNoise42], a
	ret
Drum8:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7DC9)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7DC9)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7DCF)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7DCF)
	ld [wNoise42], a
	ret
Noise43_7DC9:
	db $04, $02, $01, $00, $00, $FF
Noise42_7DCF:
	db $40, $60, $70, $82, $71
Drum2:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7DF1)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7DF1)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7DF9)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7DF9)
	ld [wNoise42], a
	ret
Noise43_7DF1:
	db $60, $52, $42, $41, $22, $11, $04, $FF
Noise42_7DF9:
	db $F0, $F0, $F0, $A0, $70, $40, $51
Drum3:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7D78)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7D78)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7D80)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7D80)
	ld [wNoise42], a
	ret
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7D6F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7D6F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7D74)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7D74)
	ld [wNoise42], a
	ret
Drum5:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7D60)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7D60)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7D68)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7D68)
	ld [wNoise42], a
	ret
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7D57)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7D57)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7D5C)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7D5C)
	ld [wNoise42], a
	ret
Drum7:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7D4C)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7D4C)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7D52)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7D52)
	ld [wNoise42], a
	ret
Drum9:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7EAE)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7EAE)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7EB1)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7EB1)
	ld [wNoise42], a
	ret
Noise43_7EAE:
	db $51, $32, $FF
Noise42_7EB1:
	db $F0, $72
Drum10:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7EED)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7EED)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7EF0)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7EF0)
	ld [wNoise42], a
	ret
Drum11:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7EF2)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7EF2)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7EFA)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7EFA)
	ld [wNoise42], a
	ret
Noise43_7EED:
	db $51, $32, $FF
Noise42_7EF0:
	db $90, $61
Noise43_7EF2:
	db $51, $32, $32, $32, $32, $51, $32, $FF
Noise42_7EFA:
	db $80, $51, $FF, $FF, $FF, $80, $51
FadeOutTable:
	db $77, $66, $55, $44, $33, $22, $11, $00
	db FADE_END
FadeInTable:
	db $00, $11, $22, $33, $44, $55, $66, $77
	db FADE_END

; Unreferenced (237 bytes)
	db $02, $00, $03, $18, $00, $04, $02, $01, $05, $06, $01, $00, $00, $07, $08, $00
	db $09, $00, $C1, $0D, $0A, $0B, $0C, $B8, $06, $1B, $0D, $42, $00, $0D, $00, $02
	db $00, $0E, $0F, $10, $00, $43, $11, $27, $39, $0A, $12, $15, $00, $00, $13, $14
	db $15, $01, $A1, $08, $16, $17, $0C, $39, $1A, $18, $E1, $03, $19, $1A, $C0, $3E
	db $1B, $1C, $00, $1D, $42, $1E, $2A, $00, $44, $00, $1F, $20, $21, $00, $10, $22
	db $23, $24, $46, $41, $25, $5C, $26, $9C, $03, $12, $07, $2E, $27, $28, $1C, $29
	db $2A, $2B, $2C, $2D, $2E, $2F, $30, $31, $32, $33, $34, $7C, $17, $35, $36, $37
	db $2C, $38, $39, $3A, $3B, $3C, $3D, $3E, $00, $3F, $00, $40, $41, $42, $43, $44
	db $45, $46, $47, $48, $49, $29, $4A, $0C, $4B, $4C, $4D, $4E, $20, $4F, $10, $50
	db $51, $52, $6B, $E4, $47, $06, $77, $53, $54, $55, $09, $0E, $56, $57, $00, $58
	db $64, $6B, $0D, $59, $00, $16, $5A, $5B, $5C, $5D, $5E, $5F, $E0, $1C, $60, $61
	db $62, $E1, $21, $63, $64, $C0, $04, $65, $66, $67, $68, $38, $69, $57, $1C, $6A
	db $71, $6B, $0D, $6C, $41, $CC, $6D, $6E, $6F, $41, $07, $70, $71, $15, $C7, $06
	db $72, $01, $17, $73, $74, $75, $76, $77, $03, $56, $78, $79, $8A, $04, $7A, $03
	db $E8, $7B, $7C, $7D, $7E, $00, $85, $27, $7F, $80, $3C, $2C, $00
