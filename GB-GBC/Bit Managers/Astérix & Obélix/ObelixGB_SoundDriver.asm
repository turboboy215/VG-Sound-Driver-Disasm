; =====================================================================
; Asterix & Obelix (E) (M2) (Eng-Spa) [S] - Game Boy
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o obelixgb.o ObelixGB_SoundDriver.asm
;   rgblink -o obelixgb.gb obelixgb.o
;   python tools/cmp_banked.py obelixgb.gb "Obelix (E) (M2) (Eng-Spa) [S][!].gb" 6:4000-7FFF
; (driver and data fill ROM bank 6; the linked file only matches in that range)
;
; Documentation: Obelix_SoundDriver.md / AJG_SoundEngine_Family.md
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
DEF wPaused EQU $C196
DEF wStereo EQU $C197
DEF wShNR32 EQU $C198
DEF wInInstr EQU $C199
DEF wNoisePan EQU $C19A
DEF wDrumHold EQU $C19B
DEF wInstrTable EQU $C19C
DEF wInstrTableHi EQU $C19D
DEF wArpTable EQU $C19E
DEF wArpTableHi EQU $C19F
DEF wMusicWave EQU $C1A0
DEF wMusicWaveHi EQU $C1A1
DEF wNoiseAutoPan EQU $C1A2
DEF wDrumPatHi EQU $C1A3
DEF wDrumPat EQU $C1A4
DEF wDrumPos EQU $C1A5
DEF wDrumsOn EQU $C1A6
DEF wDrumTempo EQU $C1A7
DEF wDrumTimer EQU $C1A8
DEF wDrumLoopCount EQU $C1A9
DEF wDrumLoopPos EQU $C1AA
DEF wNoise43Hi EQU $C1AB
DEF wNoise43 EQU $C1AC
DEF wNoise42Hi EQU $C1AD
DEF wNoise42 EQU $C1AE
DEF wNoisePos EQU $C1AF
DEF wNoiseOn EQU $C1B0
DEF wNoiseAtten EQU $C1B1
DEF wNoiseTimer EQU $C1B2
DEF wNoiseSpeed EQU $C1B3
DEF wFadeTable EQU $C1B4
DEF wFadeTableHi EQU $C1B5
DEF wFadePos EQU $C1B6
DEF wFadeTimer EQU $C1B7
DEF wFadeSpeed EQU $C1B8
DEF wFadeOn EQU $C1B9
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


SECTION "SoundDriver", ROMX[$4000], BANK[6]

	jp SndUpdate                       ; SndUpdate
	jp SndPause                        ; SndPause
	jp SndResume                       ; SndResume
	jp StopAll                         ; StopAll
	jp PlaySfx                         ; PlaySfx (A = id)
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
	jp PlaySong15                      ; song 15
	jp PlaySong16                      ; song 16
	jp PlaySfxNow                      ; PlaySfx without the SFX-29 test (A = id)

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
	add a, $4E
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
	ld b, $44
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

; Unreferenced (181 bytes)
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
	db $00, $00, $00, $00, $00

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

; Unreferenced (43 bytes)
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
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
PlaySfxIgnore:
	pop af
	ret

; PlaySfx (A = id): ignored while SFX 29 plays (no other priority); reset the SFX
; page and start the stream. The API's last entry (PlaySfxNow) skips the test.
PlaySfx:
	push af
	ld a, [$C427]
	cp $1D
	jr z, PlaySfxIgnore
	pop af
PlaySfxNow:
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
	add a, $95
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
	add a, $F9
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

; Song 1: instrument table 1, arpeggio table 1
PlaySong1:
	ld a, HIGH(ArpTable)
	ld [wArpTableHi], a
	ld a, LOW(ArpTable)
	ld [wArpTable], a
	ld a, $4E
	ld [wInstrTableHi], a
	ld a, $DF
	ld [wInstrTable], a
	ld de, Song1_Ch1
	call StartMusicCh1
	ld de, Song1_Ch2
	call StartMusicCh2
	ld de, Song1_Ch3
	call StartMusicCh3
	ret
Song1_Ch1:
	dw Pat_4B66
	dw Pat_4BDA
	ORDER_LOOP Song1_Ch1
Song1_Ch2:
	dw Pat_4C2F
	ORDER_LOOP Song1_Ch2
Song1_Ch3:
	dw Pat_4D4E
	ORDER_LOOP Song1_Ch3
Pat_4B66:
	DRUMS $07, DrumPat_4E7E
	LEN 14
	PAT_CALL Pat_4BFE
	INSTR 1
	NOTE Dsh, 5
	INSTR 0
	NOTE Ash, 2
	NOTE G_, 2
	PAT_CALL Pat_4BFE
	NOTE Ash, 2
	NOTE G_, 2
	NOTE Dsh, 2
	DRUMS $07, DrumPat_4EC8
	NOTE E_, 2
	NOTE B_, 2
	INSTR 1
	NOTE E_, 5
	INSTR 0
	NOTE Gsh, 2
	NOTE Dsh, 2
	NOTE Ash, 2
	NOTE G_, 2
	NOTE Dsh, 2
	NOTE Csh, 2
	NOTE Gsh, 2
	INSTR 2
	NOTE Csh, 5
	INSTR 0
	NOTE Ash, 2
	DRUMS $07, DrumPat_4EB2
	NOTE Dsh, 2
	INSTR 1
	NOTE Dsh, 5
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE Dsh, 5
	DRUMS $07, DrumPat_4E7E
	PAT_CALL Pat_4E5C
	NOTE Dsh, 2
	NOTE G_, 2
	PAT_CALL Pat_4E5C
	NOTE Gsh, 2
	NOTE G_, 2
	DRUMS $07, DrumPat_4EC3
	INSTR 0
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	NOTE F_, 2
	LEN 14
	NOTE F_, 2
	LEN 7
	NOTE F_, 2
	NOTE F_, 2
	LEN 28
	NOTE F_, 2
	NOTE C_, 3
	LEN 14
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	LENGTH $38
	NOTE F_, 2
	LEN 14
	NOTE Dsh, 2
	LEN 7
	NOTE Dsh, 2
	NOTE Dsh, 2
	LEN 14
	NOTE Dsh, 2
	NOTE Dsh, 2
	LEN 28
	NOTE Dsh, 2
	NOTE Gsh, 2
	LEN 14
	NOTE Dsh, 2
	NOTE F_, 2
	NOTE Dsh, 2
	NOTE F_, 2
	DRUMS $07, DrumPat_4EB2
	NOTE Dsh, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE Dsh, 2
	NOTE G_, 2
Pat_4BDA:
	DRUMS $07, DrumPat_4E7E
	LEN 14
	REPEAT 2
	INSTR 0
	NOTE Gsh, 2
	INSTR 1
	NOTE Gsh, 4
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Gsh, 4
	REPEAT_END
	REPEAT 4
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Dsh, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE Gsh, 2
	INSTR 1
	NOTE Gsh, 4
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Gsh, 4
	REPEAT_END
	NEXT
Pat_4BFE:
	REPEAT 2
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Dsh, 5
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE Dsh, 5
	REPEAT_END
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE E_, 5
	INSTR 0
	NOTE B_, 2
	INSTR 1
	NOTE E_, 5
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Dsh, 5
	INSTR 0
	NOTE Ash, 2
	NOTE Dsh, 2
	NOTE Csh, 2
	INSTR 2
	NOTE Csh, 5
	INSTR 0
	NOTE Gsh, 2
	INSTR 2
	NOTE Csh, 5
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Dsh, 5
	INSTR 0
	NOTE Ash, 2
	NOTE Dsh, 2
	NOTE E_, 2
	INSTR 1
	NOTE E_, 5
	INSTR 0
	NOTE B_, 2
	INSTR 1
	NOTE E_, 5
	INSTR 0
	NOTE Dsh, 2
	NEXT
Pat_4C2F:
	HWENV $F2, $04, $62
	DUTY_50
	ARP 4
	REPEAT 2
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE E_, 4
	LEN 7
	NOTE E_, 4
	NOTE E_, 4
	LEN 14
	NOTE E_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	ARP 5
	LEN 14
	NOTE Csh, 4
	LEN 7
	NOTE Csh, 4
	NOTE Csh, 4
	LEN 14
	NOTE Csh, 4
	LEN 7
	NOTE Csh, 4
	NOTE Csh, 4
	ARP 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE E_, 4
	LEN 7
	NOTE E_, 4
	NOTE E_, 4
	LEN 14
	NOTE E_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	REPEAT_END
	HWENV $F2, $07, $6C
	LEN 42
	NOTE E_, 4
	HWENV $F2, $04, $72
	LEN 14
	NOTE Fsh, 4
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	NOTE Dsh, 4
	ARP 5
	HWENV $F2, $07, $6C
	LEN 42
	NOTE Csh, 4
	HWENV $F2, $04, $62
	LEN 14
	NOTE Csh, 4
	ARP 4
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	HWENV $30, $00
	DUTY_75
	ARP_OFF
	RELEASE $01, $10
	AUTOPAN $07
	CH_TRANSPOSE $F4
	REST
	PAT_CALL Pat_4DF7
	LEN 7
	WAIT
	WAIT2
	NOTE Dsh, 4
	WAIT2
	PAT_CALL Pat_4DF7
	LEN 7
	NOTE Gsh, 4
	WAIT2
	NOTE Ash, 4
	AUTOPAN $00
	CH_TRANSPOSE $00
	HWENV $F2, $04, $63
	DUTY_50
	ARP 5
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE F_, 4
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE F_, 4
	LEN 28
	NOTE F_, 4
	NOTE F_, 4
	ARP 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE Dsh, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	ARP 5
	NOTE F_, 4
	ARP 4
	NOTE Dsh, 4
	ARP 5
	NOTE F_, 4
	ARP 4
	NOTE Dsh, 4
	HWENV $F1, $04, $63
	ARP 0
	DUTY_12
	NOTE Dsh, 3
	NOTE C_, 4
	NOTE Csh, 4
	REPEAT 2
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE F_, 4
	NOTE Dsh, 4
	LEN 14
	NOTE Dsh, 4
	LEN 7
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 14
	NOTE G_, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Csh, 4
	NOTE C_, 4
	LEN 7
	NOTE Csh, 4
	NOTE C_, 4
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE Csh, 4
	NOTE C_, 4
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE Csh, 4
	NOTE C_, 4
	LEN 14
	NOTE C_, 4
	NOTE Csh, 4
	REPEAT_END
	NEXT
Pat_4D4E:
	VOLENV 15, $F1, $11, $11
	RELEASE $01, $61
	VIBRATO $0E, $01, $05
	WAVE Wave_7B1E
	LEN 7
	PAT_CALL Pat_4E29
	LEN 35
	NOTE Dsh, 4
	LEN 7
	WAIT2
	NOTE Dsh, 4
	WAIT2
	PAT_CALL Pat_4E29
	NOTE Dsh, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE Dsh, 4
	WAIT2
	ARP 4
	LEN 14
	NOTE E_, 3
	ARP_OFF
	LEN 28
	NOTE Gsh, 4
	LEN 7
	NOTE Ash, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE Dsh, 4
	WAIT2
	ARP 4
	LEN 14
	NOTE Csh, 3
	ARP_OFF
	LEN 28
	NOTE E_, 4
	LEN 7
	NOTE Fsh, 4
	WAIT2
	LENGTH $31
	NOTE Dsh, 4
	LEN 7
	WAIT2
	PAT_CALL Pat_4DF7
	LEN 7
	WAIT
	WAIT2
	NOTE Dsh, 4
	WAIT2
	PAT_CALL Pat_4DF7
	LEN 7
	NOTE Gsh, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	LENGTH $4D
	NOTE C_, 5
	LEN 7
	NOTE G_, 4
	NOTE Gsh, 4
	WAIT2
	NOTE F_, 4
	NOTE Gsh, 4
	LENGTH $4D
	NOTE C_, 5
	LEN 7
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE Csh, 5
	WAIT2
	LENGTH $46
	NOTE Dsh, 5
	LEN 7
	NOTE Ash, 4
	WAIT2
	NOTE B_, 4
	WAIT2
	NOTE Gsh, 4
	NOTE B_, 4
	LENGTH $4D
	NOTE Dsh, 5
	LEN 7
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE Csh, 5
	WAIT2
	REPEAT 2
	LENGTH $4D
	NOTE Dsh, 5
	LEN 7
	WAIT2
	NOTE Csh, 5
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Gsh, 4
	LENGTH $31
	NOTE G_, 4
	LEN 7
	WAIT2
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	WAIT2
	LEN 21
	NOTE Csh, 5
	LEN 7
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE Ash, 4
	WAIT2
	LEN 21
	NOTE Gsh, 4
	LEN 7
	WAIT2
	NOTE G_, 4
	WAIT2
	LENGTH $4D
	NOTE Gsh, 4
	LEN 7
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE Csh, 5
	WAIT2
	REPEAT_END
	NEXT
Pat_4DF7:
	LEN 7
	NOTE Gsh, 4
	WAIT2
	NOTE Gsh, 4
	WAIT2
	LEN 42
	NOTE Gsh, 4
	LEN 7
	NOTE Ash, 4
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE Csh, 5
	WAIT2
	NOTE C_, 5
	WAIT2
	LEN 6
	NOTE Ash, 4
	LEN 4
	NOTE C_, 5
	NOTE Ash, 4
	LENGTH $3F
	NOTE Gsh, 4
	LEN 7
	WAIT2
	LEN 14
	NOTE Ash, 4
	LEN 7
	NOTE Dsh, 5
	WAIT2
	NOTE Csh, 5
	NOTE C_, 5
	LENGTH $31
	NOTE Ash, 4
	LEN 7
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE Csh, 5
	WAIT2
	NOTE C_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Ash, 4
	LENGTH $38
	NOTE Gsh, 4
	NEXT
Pat_4E29:
	NOTE Ash, 4
	WAIT2
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	LEN 35
	NOTE Ash, 4
	LEN 7
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE B_, 4
	WAIT2
	NOTE Csh, 5
	NOTE Dsh, 5
	NOTE Csh, 5
	NOTE B_, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	LEN 35
	NOTE Ash, 4
	LEN 7
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE Gsh, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	NOTE Gsh, 4
	WAIT2
	NOTE Ash, 4
	WAIT2
	LEN 35
	NOTE G_, 4
	LEN 7
	WAIT2
	NOTE Dsh, 4
	WAIT2
	NOTE E_, 4
	WAIT2
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NEXT
Pat_4E5C:
	REPEAT 4
	INSTR 0
	NOTE Gsh, 2
	INSTR 1
	NOTE Gsh, 4
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Gsh, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Dsh, 4
	REPEAT_END
	INSTR 0
	NOTE Gsh, 2
	INSTR 1
	NOTE Gsh, 4
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Gsh, 4
	INSTR 0
	NOTE Gsh, 2
	INSTR 1
	NOTE Gsh, 4
	INSTR 0
	NEXT
DrumPat_4E7E:
	db DRUM_REPEAT + 3, 1, DRUM_LEVEL + 10, 8, DRUM_LEVEL + 15, 8, DRUM_LEVEL + 10, 8
	db DRUM_LEVEL + 15, 9, DRUM_LEVEL + 10, 8, DRUM_LEVEL + 15, 8, DRUM_LEVEL + 10, 8
	db DRUM_LEVEL + 15, DRUM_REPEAT_END, 1, DRUM_LEVEL + 10, 8, DRUM_LEVEL + 15, 8, DRUM_LEVEL + 10
	db 8, DRUM_LEVEL + 15, 9, DRUM_LEVEL + 10, 8, DRUM_LEVEL + 15, 1, DRUM_LEVEL + 10
	db 8, DRUM_LEVEL + 15, DRUM_REPEAT + 3, 1, DRUM_LEVEL + 10, 8, DRUM_LEVEL + 15, 8
	db DRUM_LEVEL + 10, 8, DRUM_LEVEL + 15, 9, DRUM_LEVEL + 10, 8, DRUM_LEVEL + 15, 8
	db DRUM_LEVEL + 10, 8, DRUM_LEVEL + 15, DRUM_REPEAT_END
DrumPat_4EB2:
	db 1, DRUM_LEVEL + 10, 8, DRUM_LEVEL + 15, 9, DRUM_LEVEL + 10, 8, DRUM_LEVEL + 15
	db 9, DRUM_LEVEL + 10, 8, DRUM_LEVEL + 15, 1, DRUM_LEVEL + 15, 9, DRUM_LEVEL + 15
	db DRUM_LOOP
DrumPat_4EC3:
	db 9, 0, 10, 10, DRUM_LOOP
DrumPat_4EC8:
	db 7, 0, 9, 0, 0, 0, 9, 0
	db 1, 0, 9, 9, 1, 0, 1, 0
	db 7, 0, 9, 0, 9, 0, 9, 10
	db DRUM_LOOP

; Instrument table 1, entries 1..3 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr1_0
	dw Instr1_1
	dw Instr1_2
Instr1_0:
	HWENV $F3, $07, $A2
	DUTY_50
	ARP 0
	END
Instr1_1:
	HWENV $D1, $00
	ARP 4
	DUTY_75
	END
Instr1_2:
	HWENV $D1, $00
	ARP 5
	DUTY_75
	END

; Song 2: instrument table 2, arpeggio table 1 (the one SndInit sets)
PlaySong2:
	ld a, $51
	ld [wInstrTableHi], a
	ld a, $63
	ld [wInstrTable], a
	ld de, Song2_Ch3
	call StartMusicCh3
	ld de, Song2_Ch2
	call StartMusicCh2
	ld de, Song2_Ch1
	jp StartMusicCh1
Song2_Ch3:
	dw Pat_4F3A
	dw Pat_4F3A
	dw Pat_4FC1
	dw Pat_5002
	ORDER_LOOP Song2_Ch3
Song2_Ch2:
	dw Pat_5038
	dw Pat_5038
	dw Pat_5082
	dw Pat_50A3
	ORDER_LOOP Song2_Ch2
Song2_Ch1:
	dw Pat_50C4
	dw Pat_50C4
	dw Pat_5119
	dw Pat_513A
	ORDER_LOOP Song2_Ch1
Pat_4F3A:
	LEN 10
	TRANSPOSE $FE
	WAVE Wave_7A4E
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE Csh, 4
	NEXT
Pat_4FC1:
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE D_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE Ash, 3
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE E_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE A_, 3
	NEXT
Pat_5002:
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE D_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE Ash, 3
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE E_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE A_, 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE C_, 3
	NOTE A_, 2
	WAIT
	NOTE E_, 2
	WAIT
	NOTE A_, 1
	WAIT
	NOTE B_, 1
	NOTE Csh, 2
	NEXT
Pat_5038:
	HWENV $E2, $05, $92
	DUTY_75
	LEN 10
	RELEASE $02, $00
	NOTE D_, 3
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE D_, 3
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE D_, 3
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE D_, 3
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NEXT
Pat_5082:
	NOTE G_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE F_, 3
	NOTE Ash, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE E_, 3
	NOTE A_, 3
	NOTE E_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 3
	NOTE A_, 3
	NOTE Csh, 4
	NOTE D_, 4
	NOTE E_, 4
	NEXT
Pat_50A3:
	NOTE G_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE F_, 3
	NOTE Ash, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE E_, 3
	NOTE A_, 3
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE A_, 4
	WAIT
	NOTE E_, 3
	WAIT
	NOTE A_, 2
	NOTE Csh, 4
	NOTE D_, 4
	NOTE E_, 4
	NEXT
Pat_50C4:
	DRUMS $05, DrumPat_515B
	HWENV $F2, $05, $A2
	DUTY_75
	LEN 10
	RELEASE $01, $00
	ARP 0
	NOTE Gsh, 5
	LEN 5
	NOTE A_, 5
	NOTE A_, 5
	LEN 10
	NOTE A_, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE A_, 5
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	NOTE A_, 5
	NOTE A_, 5
	NOTE D_, 6
	NOTE A_, 5
	NOTE A_, 5
	NOTE A_, 5
	NOTE Gsh, 5
	LEN 5
	NOTE A_, 5
	NOTE A_, 5
	LEN 10
	NOTE A_, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE Csh, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE A_, 4
	WAIT
	NOTE A_, 3
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE Csh, 5
	NOTE Csh, 5
	NOTE E_, 3
	NOTE A_, 3
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE G_, 4
	WAIT
	WAIT
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NEXT
Pat_5119:
	NOTE Ash, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE Ash, 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE A_, 4
	WAIT
	WAIT
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE Csh, 4
	NOTE Csh, 4
	WAIT
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NEXT
Pat_513A:
	NOTE Ash, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE Ash, 3
	NOTE D_, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE A_, 4
	WAIT
	WAIT
	NOTE D_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE Csh, 5
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NEXT
DrumPat_515B:
	db DRUM_LEVEL + 14, 1, 0, 6, 0, 9, 0, 6
	db 0, DRUM_LOOP

; Instrument table 2, entries 1..2 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr2_0
	dw Instr2_1
Instr2_0:
	WAVE Wave_7A9E
	CH_TRANSPOSE $0C
	ARP 0
	VOLENV 15, $11, $11, $12
	END
Instr2_1:
	WAVE Wave_7A6E
	CH_TRANSPOSE $00
	ARP_OFF
	VOLENV 13, $00, $11, $11
	END

; Song 3: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong3:
	ld a, $54
	ld [wInstrTableHi], a
	ld a, $0E
	ld [wInstrTable], a
	ld de, Song3_Ch1
	call StartMusicCh1
	ld de, Song3_Ch2
	call StartMusicCh2
	ld de, Song3_Ch3
	jp StartMusicCh3
Song3_Ch1:
	dw Pat_51BF
	dw Pat_51BF
	dw Pat_51FB
	dw Pat_5242
	ORDER_LOOP Song3_Ch1
Song3_Ch2:
	dw Pat_5289
	dw Pat_5289
	dw Pat_52D8
	dw Pat_531A
	ORDER_LOOP Song3_Ch2
Song3_Ch3:
	dw Pat_5355
	dw Pat_5355
	dw Pat_539D
	dw Pat_53D4
	ORDER_LOOP Song3_Ch3
Pat_51BF:
	LEN 24
	WAIT
	INSTR 0
	LEN 16
	DRUMS $08, DrumPat_540B
	NOTE C_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	REPEAT 3
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	REPEAT_END
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE C_, 5
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE C_, 5
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	DRUMS_OFF
	CALL_CODE Drum9
	LEN 8
	NOTE G_, 3
	NEXT
Pat_51FB:
	LEN 24
	WAIT
	INSTR 0
	LEN 16
	DRUMS $08, DrumPat_540B
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE B_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE B_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE B_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE B_, 3
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	LEN 8
	NOTE E_, 2
	NEXT
Pat_5242:
	LEN 8
	WAIT
	INSTR 1
	LEN 16
	NOTE E_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE B_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE B_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE B_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE B_, 3
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE B_, 3
	INSTR 0
	NOTE C_, 2
	NOTE G_, 2
	DRUMS_OFF
	CALL_CODE Drum9
	LEN 8
	NOTE C_, 2
	NEXT
Pat_5289:
	LEN 24
	WAIT
	INSTR 2
	LEN 16
	NOTE C_, 3
	INSTR 1
	NOTE Dsh, 4
	INSTR 2
	NOTE G_, 3
	INSTR 1
	NOTE Dsh, 4
	INSTR 2
	NOTE C_, 3
	INSTR 1
	LEN 8
	NOTE C_, 4
	INSTR 2
	NOTE D_, 4
	LEN 16
	NOTE C_, 4
	INSTR 1
	LEN 8
	NOTE C_, 4
	INSTR 2
	NOTE D_, 4
	LEN 16
	NOTE C_, 3
	INSTR 1
	NOTE Dsh, 4
	INSTR 2
	NOTE G_, 3
	INSTR 1
	NOTE Dsh, 4
	INSTR 2
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE G_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE Gsh, 4
	INSTR 2
	NOTE C_, 4
	INSTR 1
	LEN 8
	NOTE F_, 4
	INSTR 2
	NOTE D_, 4
	LEN 16
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE G_, 3
	INSTR 1
	NOTE Dsh, 4
	INSTR 2
	NOTE G_, 3
	INSTR 1
	NOTE Dsh, 4
	INSTR 2
	NOTE G_, 3
	INSTR 1
	NOTE Dsh, 4
	INSTR 2
	LEN 8
	NOTE B_, 3
	NOTE C_, 4
	INSTR 1
	NOTE B_, 3
	INSTR 2
	NOTE C_, 4
	INSTR 1
	NOTE B_, 3
	NEXT
Pat_52D8:
	LEN 24
	WAIT
	INSTR 2
	LEN 16
	NOTE F_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE F_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE C_, 4
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE G_, 3
	INSTR 1
	NOTE Dsh, 4
	INSTR 2
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE G_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE G_, 3
	INSTR 1
	NOTE F_, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE F_, 4
	INSTR 2
	NOTE G_, 3
	INSTR 1
	NOTE F_, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE D_, 4
	INSTR 2
	NOTE C_, 3
	INSTR 1
	NOTE Dsh, 4
	INSTR 2
	NOTE D_, 3
	INSTR 1
	NOTE Dsh, 4
	INSTR 2
	NOTE Dsh, 3
	INSTR 1
	NOTE Dsh, 4
	LEN 8
	NOTE E_, 4
	NEXT
Pat_531A:
	VOLENV 15, $11, $1F, $15
	LEN 8
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 16
	NOTE Gsh, 4
	LEN 8
	NOTE G_, 4
	NOTE B_, 4
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE C_, 5
	NOTE D_, 5
	LEN 16
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE B_, 4
	NOTE D_, 4
	NOTE G_, 3
	LEN 8
	NOTE B_, 4
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE Dsh, 4
	LEN 8
	NOTE C_, 4
	NEXT
Pat_5355:
	VOLENV 15, $00, $1F, $12
	ARP 0
	WAVE Wave_7A6E
	LEN 8
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE C_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE B_, 3
	LEN 16
	NOTE C_, 4
	LEN 32
	NOTE Dsh, 4
	LEN 16
	NOTE Dsh, 4
	NOTE C_, 4
	LEN 8
	NOTE C_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE B_, 3
	LEN 16
	NOTE C_, 4
	LEN 32
	NOTE Dsh, 4
	LEN 16
	NOTE Dsh, 4
	LEN 8
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 16
	NOTE Gsh, 4
	NOTE Gsh, 4
	LEN 8
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	LEN 16
	NOTE G_, 4
	NOTE G_, 4
	LEN 8
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE Dsh, 4
	LEN 16
	NOTE G_, 4
	NOTE D_, 4
	LEN 8
	NOTE G_, 3
	NEXT
Pat_539D:
	LEN 8
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE C_, 5
	NOTE G_, 4
	LEN 16
	NOTE Gsh, 4
	LEN 8
	NOTE Gsh, 4
	NOTE F_, 4
	LEN 16
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN 32
	NOTE D_, 4
	LEN 8
	NOTE D_, 4
	NOTE Dsh, 4
	LEN 16
	NOTE F_, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 32
	NOTE G_, 4
	LEN 8
	NOTE G_, 4
	NEXT
Pat_53D4:
	LEN 8
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	LEN 16
	NOTE C_, 5
	LEN 8
	NOTE C_, 5
	NOTE D_, 5
	LEN 16
	NOTE Dsh, 5
	LEN 8
	NOTE Dsh, 5
	NOTE F_, 5
	LEN 16
	NOTE G_, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE F_, 5
	LENGTH $30
	NOTE D_, 5
	LEN 8
	NOTE D_, 5
	NOTE Dsh, 5
	LEN 16
	NOTE F_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE Dsh, 5
	LEN 32
	NOTE C_, 5
	LEN 8
	NOTE Dsh, 4
	NEXT
DrumPat_540B:
	db 1, 0, 9, 0, DRUM_LOOP

; Instrument table 3, entries 1..3 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr3_0
	dw Instr3_1
	dw Instr3_2
Instr3_0:
	HWENV $F2, $00
	ARP 0
	DUTY_50
	END
Instr3_1:
	HWENV $F2, $02, $B2
	ARP 0
	DUTY_75
	END
Instr3_2:
	HWENV $E2, $02, $82
	ARP 0
	DUTY_75
	END

; Song 4: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong4:
	ld a, $54
	ld [wInstrTableHi], a
	ld a, $0E
	ld [wInstrTable], a
	ld de, Song4_Ch1
	call StartMusicCh1
	ld de, Song4_Ch2
	call StartMusicCh2
	ld de, Song4_Ch3
	jp StartMusicCh3
Song4_Ch1:
	dw Pat_558F
	dw Pat_549C
	dw Pat_549C
	dw Pat_54EF
	dw Pat_5545
	dw Pat_549C
	dw Pat_549C
	dw Pat_54EF
	dw Pat_5545
	dw Pat_55B5
	dw Pat_55B5
	ORDER_LOOP Song4_Ch1
Song4_Ch2:
	dw Pat_5654
	dw Pat_55C8
	dw Pat_55C8
	dw Pat_55FD
	dw Pat_55C8
	dw Pat_55C8
	dw Pat_55FD
	dw Pat_5663
	dw Pat_5663
	ORDER_LOOP Song4_Ch2
Song4_Ch3:
	dw Pat_570D
	dw Pat_5680
	dw Pat_5680
	dw Pat_56C6
	dw Pat_56E9
	dw Pat_5709
	dw Pat_5496
	dw Pat_5680
	dw Pat_5680
	dw Pat_56C6
	dw Pat_56E9
	dw Pat_570B
	dw Pat_5741
	dw Pat_5741
	ORDER_LOOP Song4_Ch3
Pat_5496:
	WAVE Wave_7AEE
	CH_TRANSPOSE $00
	NEXT
Pat_549C:
	INSTR 0
	LEN 16
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 4
	NOTE E_, 4
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	NOTE E_, 4
	INSTR 0
	NOTE B_, 2
	INSTR 1
	LEN 8
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 4
	NOTE E_, 4
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	NOTE E_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE E_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE E_, 4
	NOTE E_, 4
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	NOTE E_, 4
	INSTR 0
	NOTE B_, 2
	INSTR 1
	LEN 8
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 1
	LEN 8
	NOTE E_, 4
	NOTE E_, 4
	INSTR 0
	LEN 16
	NOTE F_, 2
	INSTR 1
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE A_, 2
	NOTE E_, 2
	NEXT
Pat_54EF:
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	LEN 8
	NOTE Gsh, 3
	NOTE Gsh, 3
	INSTR 0
	LEN 16
	NOTE B_, 2
	INSTR 1
	NOTE Gsh, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	LEN 8
	NOTE Gsh, 3
	NOTE Gsh, 3
	INSTR 0
	LEN 16
	NOTE B_, 2
	INSTR 1
	NOTE Gsh, 3
	INSTR 0
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	LEN 8
	NOTE F_, 3
	NOTE F_, 3
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	LEN 8
	NOTE Dsh, 3
	NOTE Dsh, 3
	INSTR 0
	LEN 16
	NOTE B_, 2
	INSTR 1
	NOTE Dsh, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	LEN 8
	NOTE E_, 3
	NOTE E_, 3
	INSTR 0
	LEN 16
	NOTE B_, 2
	INSTR 1
	NOTE E_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE F_, 3
	NOTE E_, 3
	INSTR 0
	NOTE B_, 2
	NEXT
Pat_5545:
	LEN 16
	NOTE E_, 2
	INSTR 1
	LEN 8
	NOTE Gsh, 3
	NOTE Gsh, 3
	INSTR 0
	LEN 16
	NOTE B_, 2
	INSTR 1
	NOTE Gsh, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	LEN 8
	NOTE Gsh, 3
	NOTE Gsh, 3
	INSTR 0
	LEN 16
	NOTE B_, 2
	INSTR 1
	NOTE Gsh, 3
	INSTR 0
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	LEN 8
	NOTE F_, 3
	NOTE F_, 3
	INSTR 0
	LEN 16
	NOTE E_, 2
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE Dsh, 2
	INSTR 1
	NOTE Dsh, 3
	INSTR 0
	NOTE B_, 2
	INSTR 1
	NOTE Dsh, 3
	INSTR 1
	NOTE E_, 2
	NOTE Dsh, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE E_, 2
	WAIT2
	LEN 32
	NOTE E_, 3
	LEN 16
	NEXT
Pat_558F:
	INSTR 0
	LEN 32
	NOTE A_, 2
	NOTE F_, 2
	LEN 16
	NOTE E_, 2
	NOTE Gsh, 2
	NOTE A_, 2
	NOTE E_, 2
	NEXT
Pat_5599:
	LEN 16
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE Csh, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE B_, 3
	INSTR 0
	NOTE E_, 2
	INSTR 1
	NOTE B_, 3
	INSTR 0
	NOTE A_, 2
	NEXT
Pat_55B5:
	PAT_CALL Pat_5599
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE C_, 4
	PAT_CALL Pat_5599
	NOTE E_, 2
	NOTE A_, 2
	INSTR 1
	LEN 8
	NOTE Csh, 4
	NOTE Csh, 4
	NEXT
Pat_55C8:
	INSTR 1
	LEN 16
	NOTE A_, 3
	LEN 8
	NOTE C_, 4
	NOTE C_, 4
	LEN 16
	NOTE E_, 3
	NOTE C_, 4
	NOTE B_, 3
	LEN 8
	NOTE D_, 4
	NOTE D_, 4
	LEN 16
	NOTE E_, 3
	NOTE D_, 4
	NOTE A_, 3
	LEN 8
	NOTE C_, 4
	NOTE C_, 4
	LEN 16
	NOTE E_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE A_, 3
	LEN 8
	NOTE C_, 4
	NOTE C_, 4
	LEN 16
	NOTE E_, 3
	NOTE C_, 4
	NOTE B_, 3
	LEN 8
	NOTE D_, 4
	NOTE D_, 4
	LEN 16
	NOTE E_, 3
	NOTE D_, 4
	NOTE F_, 3
	LEN 8
	NOTE C_, 4
	NOTE C_, 4
	LEN 16
	NOTE F_, 3
	NOTE C_, 4
	NOTE E_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE E_, 3
	NEXT
Pat_55FD:
	LEN 16
	NOTE E_, 3
	LEN 8
	NOTE B_, 3
	NOTE B_, 3
	LEN 16
	NOTE B_, 3
	NOTE B_, 3
	NOTE E_, 3
	LEN 8
	NOTE B_, 3
	NOTE B_, 3
	LEN 16
	NOTE B_, 3
	NOTE B_, 3
	REPEAT 2
	NOTE A_, 3
	LEN 8
	NOTE C_, 4
	NOTE C_, 4
	LEN 16
	NOTE E_, 3
	NOTE C_, 4
	REPEAT_END
	NOTE F_, 3
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	LEN 16
	NOTE E_, 3
	NOTE A_, 3
	NOTE Dsh, 3
	LEN 8
	NOTE Fsh, 3
	NOTE Fsh, 3
	LEN 16
	NOTE B_, 3
	NOTE Fsh, 3
	NOTE E_, 3
	LEN 8
	NOTE Gsh, 3
	NOTE Gsh, 3
	LEN 16
	NOTE B_, 3
	NOTE Gsh, 3
	NOTE E_, 3
	NOTE A_, 3
	NOTE Gsh, 3
	NOTE B_, 3
	REPEAT 2
	NOTE E_, 3
	LEN 8
	NOTE B_, 3
	NOTE B_, 3
	LEN 16
	NOTE B_, 3
	NOTE B_, 3
	REPEAT_END
	REPEAT 2
	NOTE A_, 3
	LEN 8
	NOTE C_, 4
	NOTE C_, 4
	LEN 16
	NOTE E_, 3
	NOTE C_, 4
	REPEAT_END
	NOTE F_, 3
	LEN 8
	NOTE A_, 3
	NOTE A_, 3
	LEN 16
	NOTE E_, 3
	NOTE A_, 3
	NOTE Dsh, 3
	NOTE Fsh, 3
	NOTE B_, 3
	NOTE Fsh, 3
	NOTE E_, 3
	NOTE Dsh, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE E_, 3
	WAIT2
	LEN 32
	NOTE Gsh, 3
	NEXT
Pat_5654:
	INSTR 1
	LEN 16
	NOTE C_, 4
	LEN 8
	NOTE D_, 4
	NOTE C_, 4
	LEN 16
	NOTE A_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE D_, 3
	NOTE C_, 3
	INSTR 1
	NOTE E_, 2
	NEXT
Pat_5663:
	INSTR 1
	LEN 16
	REPEAT 2
	NOTE A_, 3
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 4
	REPEAT_END
	NOTE E_, 3
	NOTE E_, 4
	NOTE E_, 3
	NOTE E_, 4
	REPEAT 3
	NOTE A_, 3
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 4
	REPEAT_END
	NOTE E_, 3
	NOTE E_, 4
	NOTE E_, 3
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 3
	NOTE A_, 3
	LEN 8
	NOTE E_, 4
	NOTE E_, 4
	NEXT
Pat_5680:
	DRUMS $08, DrumPat_5753
	VOLENV 10, $15, $11, $11
	VIBRATO $10, $01, $05
	RELEASE $72, $A3
	LEN 24
	NOTE A_, 4
	LEN 8
	NOTE B_, 4
	LEN 16
	NOTE C_, 5
	NOTE A_, 4
	LEN 8
	NOTE B_, 4
	NOTE Ash, 4
	NOTE B_, 4
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	NOTE B_, 4
	LEN 24
	NOTE A_, 4
	LEN 8
	NOTE B_, 4
	LEN 16
	NOTE C_, 5
	NOTE A_, 4
	LEN 32
	NOTE F_, 4
	LEN 16
	NOTE E_, 4
	LEN 16
	NOTE E_, 4
	LEN 24
	NOTE A_, 4
	LEN 8
	NOTE B_, 4
	LEN 16
	NOTE C_, 5
	NOTE A_, 4
	LEN 8
	NOTE B_, 4
	NOTE Ash, 4
	NOTE B_, 4
	NOTE C_, 5
	LEN 16
	NOTE D_, 5
	NOTE B_, 4
	NOTE E_, 5
	LEN 8
	NOTE F_, 5
	NOTE E_, 5
	LEN 16
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE Gsh, 4
	LEN 32
	NOTE A_, 4
	NEXT
Pat_56C6:
	LEN 16
	NOTE B_, 4
	LEN 8
	NOTE C_, 5
	NOTE D_, 5
	LENGTH $60
	NOTE Gsh, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE B_, 4
	NOTE C_, 5
	LENGTH $60
	NOTE E_, 4
	LEN 32
	NOTE F_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE B_, 3
	LEN 16
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 5
	NOTE E_, 4
	NOTE Gsh, 4
	LEN 6
	NOTE B_, 4
	LEN 32
	NOTE E_, 5
	NEXT
Pat_56E9:
	LEN 16
	NOTE B_, 4
	LEN 8
	NOTE C_, 5
	NOTE D_, 5
	LENGTH $60
	NOTE Gsh, 4
	LEN 16
	NOTE A_, 4
	LEN 8
	NOTE B_, 4
	NOTE C_, 5
	LENGTH $60
	NOTE E_, 4
	LEN 32
	NOTE F_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE B_, 3
	LEN 16
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	WAIT2
	LEN 24
	NOTE E_, 5
	LEN 8
	NEXT
Pat_5709:
	WAIT
	NEXT
Pat_570B:
	NOTE D_, 5
	NEXT
Pat_570D:
	DRUMS_OFF
	WAVE Wave_7A6E
	VOLENV 15, $11, $1F, $12
	ARP 0
	RELEASE $00
	LEN 16
	NOTE E_, 4
	LEN 8
	NOTE F_, 4
	NOTE E_, 4
	LEN 16
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE Gsh, 3
	LEN 32
	NOTE A_, 3
	WAVE Wave_7ACE
	CH_TRANSPOSE $0C
	NEXT
Pat_572A:
	LEN 16
	NOTE Csh, 5
	LEN 8
	NOTE D_, 5
	NOTE E_, 5
	LEN 24
	NOTE A_, 4
	LEN 8
	NOTE B_, 4
	LEN 16
	NOTE C_, 5
	NOTE A_, 4
	LEN 24
	NOTE E_, 4
	LEN 8
	NOTE A_, 4
	LEN 16
	NOTE B_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE Gsh, 4
	NOTE A_, 4
	NEXT
Pat_5741:
	PAT_CALL Pat_572A
	NOTE B_, 4
	LEN 32
	NOTE C_, 5
	PAT_CALL Pat_572A
	LEN 3
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 4
	LEN 7
	NOTE Gsh, 4
	LEN 32
	NOTE A_, 4
	NEXT
DrumPat_5753:
	db 1, 0, 6, 0, 9, 0, 6, 0
	db 1, 0, 6, 0, 9, 0, 6, 6
	db DRUM_LOOP

; Song 5: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong5:
	ld a, $74
	ld [wInstrTableHi], a
	ld a, $36
	ld [wInstrTable], a
	ld de, Song5_Ch1
	call StartMusicCh1
	ld de, Song5_Ch2
	call StartMusicCh2
	ld de, Song5_Ch3
	jp StartMusicCh3

; Unreferenced (1 bytes)
	db $C9
Song5_Ch1:
	dw Pat_57C3
	dw Pat_57C8
	dw Pat_5811
	dw Pat_5827
	ORDER_LOOP Song5_Ch1
Song5_Ch2:
	dw Pat_57BD
	dw Pat_5835
	dw Pat_586D
	dw Pat_58CD
	dw Pat_58E4
	dw Pat_57C0
	dw Pat_5835
	dw Pat_57BD
	dw Pat_586D
	dw Pat_57C0
	dw Pat_58CD
	dw Pat_58E4
	ORDER_LOOP Song5_Ch2
Song5_Ch3:
	dw Pat_57BD
	dw Pat_5919
	dw Pat_595A
	dw Pat_5979
	dw Pat_57C0
	dw Pat_5919
	dw Pat_595A
	dw Pat_5979
	ORDER_LOOP Song5_Ch3
Pat_57BD:
	CH_TRANSPOSE $00
	NEXT
Pat_57C0:
	CH_TRANSPOSE $0C
	NEXT
Pat_57C3:
	LEN 14
	DRUMS $0E, DrumPat_597F
Pat_57C8:
	REPEAT 7
	INSTR 6
	NOTE C_, 2
	INSTR 2
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 6
	NOTE G_, 2
	INSTR 2
	NOTE D_, 4
	REPEAT_END
	INSTR 6
	NOTE C_, 2
	INSTR 2
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE Ash, 3
	NEXT
Pat_57E1:
	REPEAT 4
	INSTR 6
	NOTE C_, 2
	INSTR 2
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 6
	NOTE G_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 6
	REPEAT_END
	NOTE Dsh, 2
	INSTR 1
	NOTE Dsh, 4
	NOTE Dsh, 4
	INSTR 0
	NOTE Dsh, 3
	INSTR 6
	NOTE Ash, 2
	INSTR 2
	NOTE G_, 4
	INSTR 6
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	NOTE F_, 4
	INSTR 0
	NOTE F_, 3
	INSTR 6
	NOTE C_, 3
	INSTR 1
	NOTE Dsh, 4
	INSTR 6
	NOTE C_, 2
	INSTR 2
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 6
	NOTE G_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 6
	NEXT
Pat_5811:
	PAT_CALL Pat_57E1
	NOTE C_, 2
	INSTR 2
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE Ash, 3
	PAT_CALL Pat_57E1
	LEN 28
	NOTE F_, 2
	NOTE G_, 2
	NOTE Dsh, 2
	LEN 14
	NEXT
Pat_5827:
	REPEAT 4
	INSTR 6
	NOTE C_, 2
	INSTR 2
	NOTE C_, 4
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 6
	NOTE G_, 2
	INSTR 2
	NOTE D_, 4
	REPEAT_END
	NEXT
Pat_5835:
	LEN 14
	HWENV $D1, $02, $53
	ARP 0
	DUTY_75
	VIBRATO $0E, $01, $06
	NOTE G_, 4
	NOTE G_, 4
	REPEAT 2
	NOTE G_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 4
	WAIT
	REPEAT_END
	NOTE G_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	WAIT
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	WAIT
	NEXT
Pat_586D:
	HWENV $6D, $1C, $C7
	DUTY_75
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	NOTE Ash, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	NOTE Dsh, 4
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE C_, 4
	NOTE D_, 4
	LEN 28
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE Ash, 3
	LEN 14
	NEXT
Pat_58A1:
	NOTE G_, 3
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE F_, 4
	NOTE G_, 4
	WAIT
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	LEN 7
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	WAIT
	LEN 14
	NOTE Dsh, 4
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE F_, 4
	WAIT
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	WAIT
	WAIT
	NEXT
Pat_58CD:
	PAT_CALL Pat_58A1
	WAIT
	NOTE D_, 4
	WAIT
	NOTE F_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE C_, 4
	NOTE Ash, 3
	PAT_CALL Pat_58A1
	NOTE F_, 4
	LEN 28
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Dsh, 4
	LEN 14
	NEXT
Pat_58E4:
	LENGTH $70
	NOTE C_, 4
	WAIT
	WAIT
	NEXT
Pat_58EA:
	LEN 14
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE F_, 3
	NOTE G_, 3
	WAIT
	NOTE G_, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE F_, 3
	NOTE G_, 3
	WAIT
	NOTE G_, 3
	NOTE Ash, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE F_, 3
	NOTE G_, 3
	WAIT
	NOTE G_, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE F_, 3
	NOTE G_, 3
	WAIT
	NOTE G_, 3
	NOTE F_, 3
	LEN 28
	NOTE Dsh, 3
	NOTE D_, 3
	LENGTH $38
	NEXT
Pat_5919:
	VIBRATO $0E, $01, $06
	VOLENV 12, $11, $1F, $14
	ARP 0
	WAVE Wave_7A4E
	PAT_CALL Pat_58EA
	WAIT
	PAT_CALL Pat_58EA
	NOTE C_, 3
	NEXT
Pat_592E:
	LEN 14
	NOTE C_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	WAIT
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Ash, 4
	LEN 7
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	WAIT
	LEN 14
	NOTE G_, 4
	WAIT
	NOTE C_, 5
	WAIT
	WAIT
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE F_, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE D_, 5
	WAIT
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE C_, 5
	WAIT
	NEXT
Pat_595A:
	VOLENV 10, $1C, $1F, $35
	WAVE Wave_7A2E
	PAT_CALL Pat_592E
	NOTE G_, 4
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	PAT_CALL Pat_592E
	WAIT
	NOTE D_, 5
	LEN 28
	NOTE Dsh, 5
	LENGTH $54
	NOTE C_, 5
	NEXT
Pat_5979:
	LENGTH $70
	NOTE G_, 4
	WAIT
	WAIT
	NEXT
DrumPat_597F:
	db DRUM_TEMPO + 14, 7, 0, 9, 6, 1, 4, 1
	db DRUM_TEMPO + 7, 6, 6, DRUM_TEMPO + 14, 9, 6, 1, 4
	db 1, 6, 9, 6, 1, 4, 1, DRUM_TEMPO + 7
	db 6, 6, DRUM_TEMPO + 14, 9, 1, 9, 9, 1
	db 6, 9, 6, 1, 4, 1, DRUM_TEMPO + 7, 6
	db 6, DRUM_TEMPO + 14, 9, 6, 1, 4, 1, 6
	db 9, 6, 1, 4, 1, DRUM_TEMPO + 7, 6, 6
	db DRUM_TEMPO + 14, 9, 1, 9, DRUM_TEMPO + 7, 9, 9, DRUM_LOOP

; Song 6: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong6:
	ld a, $74
	ld [wInstrTableHi], a
	ld a, $36
	ld [wInstrTable], a
	ld de, Song6_Ch1
	call StartMusicCh1
	ld de, Song6_Ch2
	call StartMusicCh2
	ld de, Song6_Ch3
	jp StartMusicCh3
Song6_Ch1:
	dw Pat_5A2B
	dw Pat_5A2B
	dw Pat_5A69
	dw Pat_5A2B
	dw Pat_5A2B
	dw Pat_5A69
	dw Pat_5A85
	dw Pat_5A85
	dw Pat_5AAE
	ORDER_LOOP Song6_Ch1
Song6_Ch2:
	dw Pat_5AB9
	dw Pat_5AB9
	dw Pat_5AE5
	dw Pat_5AB9
	dw Pat_5AB9
	dw Pat_5AE5
	dw Pat_5B08
	dw Pat_5B08
	dw Pat_5B34
	ORDER_LOOP Song6_Ch2
Song6_Ch3:
	dw Pat_5B41
	dw Pat_5B41
	dw Pat_5B85
	dw Pat_5B41
	dw Pat_5B41
	dw Pat_5B85
	dw Pat_5BB3
	dw Pat_5BD0
	dw Pat_5BF6
	ORDER_LOOP Song6_Ch3
Pat_5A1D:
	INSTR 6
	REPEAT 2
	LEN 18
	NOTE D_, 2
	LEN 9
	NOTE D_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 6
	NOTE D_, 3
	NOTE D_, 2
	REPEAT_END
	LEN 18
	NEXT
Pat_5A2B:
	PAT_CALL Pat_5A1D
	NOTE C_, 2
	LEN 9
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 6
	NOTE C_, 3
	NOTE C_, 2
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 2
	INSTR 2
	NOTE G_, 4
	INSTR 6
	NOTE G_, 3
	NOTE G_, 2
	PAT_CALL Pat_5A1D
	NOTE F_, 2
	LEN 9
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 6
	NOTE C_, 3
	NOTE F_, 2
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE D_, 3
	NOTE G_, 2
	NEXT
Pat_5A54:
	REPEAT 2
	LEN 18
	NOTE A_, 2
	LEN 9
	NOTE A_, 2
	INSTR 1
	NOTE A_, 4
	INSTR 6
	NOTE E_, 3
	NOTE A_, 2
	REPEAT_END
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE D_, 3
	NOTE G_, 2
	NEXT
Pat_5A69:
	INSTR 6
	PAT_CALL Pat_5A54
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE D_, 3
	NOTE G_, 2
	PAT_CALL Pat_5A54
	INSTR 6
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 6
	NOTE F_, 2
	NOTE E_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 6
	NOTE E_, 2
	NEXT
Pat_5A85:
	REPEAT 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 6
	NOTE D_, 3
	NOTE D_, 2
	REPEAT_END
	REPEAT 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 6
	NOTE D_, 3
	NOTE D_, 2
	REPEAT_END
	REPEAT 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	INSTR 1
	NOTE E_, 4
	INSTR 6
	NOTE D_, 3
	NOTE D_, 2
	REPEAT_END
	REPEAT 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	INSTR 1
	NOTE Dsh, 4
	INSTR 6
	NOTE D_, 3
	NOTE D_, 2
	REPEAT_END
	NEXT
Pat_5AAE:
	REPEAT 8
	NOTE C_, 2
	NOTE C_, 3
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 6
	NOTE C_, 3
	NOTE C_, 2
	REPEAT_END
	NEXT
Pat_5AB9:
	HWENV $92, $00
	DUTY_50
	ARP 0
	LEN 27
	NOTE F_, 4
	LEN 9
	NOTE D_, 4
	NOTE E_, 4
	LEN 36
	NOTE F_, 4
	LEN 9
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 18
	NOTE E_, 4
	LEN 36
	NOTE C_, 4
	LEN 18
	NOTE D_, 5
	LEN 36
	NOTE Ash, 4
	LEN 27
	NOTE F_, 4
	LEN 9
	NOTE D_, 4
	NOTE E_, 4
	LEN 36
	NOTE F_, 4
	LEN 9
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 18
	NOTE A_, 4
	LEN 36
	NOTE F_, 4
	LEN 18
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NEXT
Pat_5AE5:
	LEN 9
	NOTE Csh, 5
	NOTE B_, 4
	NOTE A_, 4
	LENGTH $51
	NOTE E_, 4
	LEN 9
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	LENGTH $51
	NOTE D_, 4
	LEN 9
	NOTE Csh, 5
	NOTE B_, 4
	NOTE A_, 4
	LENGTH $51
	NOTE E_, 4
	LEN 9
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 27
	NOTE D_, 4
	LEN 9
	NOTE C_, 4
	NOTE Ash, 3
	NOTE A_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NEXT
Pat_5B08:
	INSTR 2
	LEN 9
	REPEAT 2
	NOTE D_, 4
	INSTR 0
	NOTE F_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	INSTR 2
	REPEAT_END
	INSTR 1
	REPEAT 2
	NOTE Dsh, 4
	INSTR 0
	NOTE F_, 4
	NOTE D_, 4
	NOTE Ash, 4
	NOTE F_, 4
	NOTE D_, 4
	INSTR 1
	REPEAT_END
	REPEAT 2
	NOTE E_, 4
	INSTR 0
	NOTE F_, 4
	NOTE D_, 4
	NOTE B_, 4
	NOTE F_, 4
	NOTE D_, 4
	INSTR 1
	REPEAT_END
	REPEAT 2
	NOTE Dsh, 4
	INSTR 0
	NOTE F_, 4
	NOTE D_, 4
	NOTE Ash, 4
	NOTE F_, 4
	NOTE D_, 4
	INSTR 1
	REPEAT_END
	NEXT
Pat_5B34:
	INSTR 0
	LEN 9
	REPEAT 8
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	REPEAT_END
	REPEAT 8
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	REPEAT_END
	NEXT
Pat_5B41:
	DRUMS $09, DrumPat_5C1B
	VOLENV 12, $13, $1F, $1F
	VIBRATO $09, $01, $06
	ARP 0
	RELEASE $01, $50
	WAVE Wave_7ADE
	CH_TRANSPOSE $0C
	LEN 9
	NOTE A_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 18
	NOTE A_, 4
	LEN 9
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 18
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE Ash, 3
	LEN 9
	NOTE A_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 18
	NOTE A_, 4
	LEN 9
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 18
	NOTE C_, 5
	NOTE A_, 4
	NOTE F_, 4
	LEN 9
	NOTE B_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	LEN 18
	NOTE D_, 5
	NEXT
Pat_5B85:
	LEN 9
	NOTE E_, 5
	NOTE D_, 5
	NOTE Csh, 5
	LEN 36
	NOTE A_, 4
	LEN 9
	NOTE E_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE Csh, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	LEN 45
	NOTE G_, 4
	LEN 9
	NOTE A_, 4
	NOTE B_, 4
	NOTE Csh, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE Csh, 5
	LEN 36
	NOTE A_, 4
	LEN 9
	NOTE E_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE Csh, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	LEN 27
	NOTE G_, 4
	LEN 9
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NEXT
Pat_5BB3:
	LENGTH $5A
	NOTE D_, 4
	LEN 9
	NOTE E_, 4
	NOTE F_, 4
	LENGTH $5A
	NOTE G_, 4
	LEN 9
	NOTE F_, 4
	NOTE E_, 4
	LENGTH $48
	NOTE D_, 4
	LEN 18
	NOTE F_, 4
	NOTE E_, 4
	LENGTH $36
	NOTE D_, 4
	LEN 9
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE C_, 5
	NOTE D_, 5
	NEXT
Pat_5BD0:
	LEN 36
	NOTE F_, 5
	LEN 9
	NOTE E_, 5
	NOTE F_, 5
	LEN 18
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	LEN 36
	NOTE A_, 4
	LEN 9
	NOTE G_, 4
	NOTE A_, 4
	LEN 18
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 4
	LEN 9
	NOTE E_, 4
	NOTE F_, 4
	LENGTH $48
	NOTE E_, 4
	LEN 9
	NOTE F_, 4
	NOTE G_, 4
	LENGTH $36
	NOTE F_, 4
	LEN 9
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NEXT
Pat_5BF6:
	LENGTH $5A
	NOTE G_, 4
	LEN 9
	NOTE F_, 4
	NOTE E_, 4
	LENGTH $5A
	NOTE C_, 4
	LEN 9
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 5
	NOTE D_, 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE C_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE C_, 4
	NEXT
DrumPat_5C1B:
	db DRUM_LEVEL + 15, 1, DRUM_LEVEL + 12, 6, 6, DRUM_LEVEL + 15, 2, DRUM_LEVEL + 12
	db 6, 6, DRUM_LOOP

; Song 7: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong7:
	ld a, $74
	ld [wInstrTableHi], a
	ld a, $36
	ld [wInstrTable], a
	ld de, Song7_Ch1
	call StartMusicCh1
	ld de, Song7_Ch2
	call StartMusicCh2
	ld de, Song7_Ch3
	jp StartMusicCh3

; Unreferenced (1 bytes)
	db $C9
Song7_Ch1:
	dw Pat_5C73
	dw Pat_5CC6
	dw Pat_5CEB
	dw Pat_5CC6
	dw Pat_5D0D
	dw Pat_5C73
	ORDER_LOOP Song7_Ch1
Song7_Ch2:
	dw Pat_5D35
	dw Pat_5D7B
	dw Pat_5D99
	dw Pat_5D7B
	dw Pat_5DBD
	dw Pat_5D35
	ORDER_LOOP Song7_Ch2
Song7_Ch3:
	dw Pat_5DE3
	dw Pat_5E52
	dw Pat_5E6E
	dw Pat_5E52
	dw Pat_5E84
	dw Pat_5DE3
	ORDER_LOOP Song7_Ch3
Pat_5C73:
	HWENV $F2, $0A, $E1
	ARP 0
	LEN 10
	DUTY_50
	DRUMS $0A, DrumPat_5E9C
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 3
	REPEAT 3
	NOTE A_, 2
	WAIT
	NOTE A_, 3
	REPEAT_END
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 3
	REPEAT 3
	NOTE E_, 2
	WAIT
	NOTE E_, 3
	REPEAT_END
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 3
	REPEAT 3
	NOTE A_, 2
	WAIT
	NOTE A_, 3
	REPEAT_END
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 3
	REPEAT 3
	NOTE E_, 2
	WAIT
	NOTE E_, 3
	REPEAT_END
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 3
	REPEAT 3
	NOTE F_, 2
	WAIT
	NOTE F_, 3
	REPEAT_END
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 3
	REPEAT 3
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	REPEAT_END
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 3
	REPEAT 3
	NOTE A_, 2
	WAIT
	NOTE A_, 3
	REPEAT_END
	DRUMS $0A, DrumPat_5EA9
	LEN 20
	NOTE A_, 2
	NOTE B_, 2
	NOTE C_, 3
	LEN 10
	NOTE A_, 2
	NOTE A_, 3
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 3
	NOTE G_, 2
	NEXT
Pat_5CC6:
	DRUMS $0A, DrumPat_5E9C
	REPEAT 4
	NOTE F_, 2
	WAIT
	NOTE F_, 3
	REPEAT_END
	REPEAT 2
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	REPEAT_END
	NOTE B_, 2
	NOTE G_, 2
	NOTE C_, 3
	NOTE B_, 2
	NOTE D_, 2
	NOTE G_, 2
	REPEAT 4
	NOTE F_, 2
	WAIT
	NOTE F_, 3
	REPEAT_END
	REPEAT 2
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	REPEAT_END
	NOTE B_, 2
	NOTE C_, 3
	NOTE B_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	NEXT
Pat_5CEB:
	REPEAT 4
	NOTE F_, 2
	WAIT
	NOTE F_, 3
	REPEAT_END
	REPEAT 2
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	REPEAT_END
	NOTE B_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	REPEAT 4
	NOTE E_, 2
	WAIT
	NOTE E_, 3
	REPEAT_END
	NOTE A_, 2
	WAIT
	NOTE A_, 2
	NOTE A_, 3
	NOTE E_, 3
	NOTE A_, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 2
	NEXT
Pat_5D0D:
	REPEAT 4
	NOTE F_, 2
	WAIT
	NOTE F_, 3
	REPEAT_END
	REPEAT 2
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	REPEAT_END
	NOTE B_, 2
	NOTE G_, 2
	NOTE C_, 3
	NOTE B_, 2
	NOTE D_, 2
	NOTE G_, 2
	REPEAT 3
	NOTE A_, 2
	WAIT
	NOTE A_, 3
	REPEAT_END
	NOTE E_, 3
	WAIT
	NOTE E_, 2
	DRUMS $0A, DrumPat_5EA9
	LEN 20
	NOTE A_, 2
	NOTE B_, 2
	NOTE C_, 3
	LEN 10
	NOTE A_, 2
	NOTE B_, 2
	NOTE C_, 3
	NOTE A_, 2
	WAIT
	NOTE G_, 2
	NEXT
Pat_5D35:
	INSTR 2
	LEN 10
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 30
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 10
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	LEN 30
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	LEN 10
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 30
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 10
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	LEN 30
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	INSTR 1
	LEN 10
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	LEN 30
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	LEN 10
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 30
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	INSTR 2
	LEN 10
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 30
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	LEN 20
	NOTE A_, 3
	NOTE A_, 3
	INSTR 1
	NOTE Ash, 3
	INSTR 2
	LEN 30
	NOTE A_, 3
	INSTR 1
	NOTE G_, 3
	NEXT
Pat_5D7B:
	LEN 10
	REPEAT 4
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE A_, 3
	NOTE C_, 4
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE B_, 3
	NOTE D_, 4
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE A_, 3
	NOTE C_, 4
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE B_, 3
	NOTE D_, 4
	REPEAT_END
	NEXT
Pat_5D99:
	REPEAT 4
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE A_, 3
	NOTE C_, 4
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE B_, 3
	NOTE D_, 4
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE E_, 3
	INSTR 0
	NOTE B_, 3
	NOTE E_, 4
	REPEAT_END
	REPEAT 2
	INSTR 2
	NOTE A_, 3
	INSTR 0
	NOTE E_, 4
	NOTE A_, 4
	REPEAT_END
	REPEAT 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE D_, 4
	NOTE G_, 4
	REPEAT_END
	NEXT
Pat_5DBD:
	REPEAT 4
	INSTR 1
	NOTE F_, 3
	INSTR 0
	NOTE A_, 3
	NOTE C_, 4
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE B_, 3
	NOTE D_, 4
	REPEAT_END
	REPEAT 4
	INSTR 2
	NOTE A_, 3
	INSTR 0
	NOTE C_, 4
	NOTE E_, 4
	REPEAT_END
	INSTR 2
	LEN 20
	NOTE A_, 3
	NOTE A_, 3
	INSTR 1
	NOTE Ash, 3
	INSTR 2
	NOTE A_, 3
	INSTR 0
	LEN 10
	NOTE A_, 3
	INSTR 2
	NOTE A_, 3
	INSTR 0
	NOTE B_, 3
	NOTE C_, 4
	NEXT
Pat_5DE3:
	VOLENV 10, $12, $1F, $10
	VIBRATO $14, $01, $04
	ARP 0
	WAVE Wave_7B1E
	RELEASE $03, $02
	LEN 10
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	LENGTH $50
	NOTE E_, 4
	LEN 10
	WAIT2
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	LENGTH $50
	NOTE B_, 3
	LEN 10
	WAIT2
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	LENGTH $32
	NOTE E_, 4
	LEN 10
	NOTE E_, 4
	NOTE A_, 4
	WAIT2
	NOTE C_, 5
	LEN 20
	NOTE B_, 4
	LEN 10
	NOTE G_, 4
	LENGTH $32
	NOTE E_, 5
	LEN 10
	WAIT2
	LEN 20
	NOTE B_, 4
	LEN 10
	WAIT2
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	LEN 40
	NOTE F_, 4
	LEN 10
	WAIT2
	NOTE F_, 4
	LEN 20
	NOTE A_, 4
	LEN 10
	NOTE C_, 5
	LEN 20
	NOTE B_, 4
	LEN 10
	NOTE G_, 4
	LEN 20
	NOTE D_, 4
	LEN 10
	WAIT2
	LEN 20
	NOTE C_, 4
	LEN 10
	WAIT2
	LEN 20
	NOTE B_, 3
	LEN 10
	WAIT2
	LENGTH $50
	NOTE A_, 3
	LEN 10
	NOTE B_, 3
	WAIT2
	NOTE C_, 4
	WAIT2
	LENGTH $78
	NOTE A_, 4
	NEXT
Pat_5E43:
	LEN 10
	NOTE F_, 2
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	LEN 30
	NOTE F_, 4
	NOTE E_, 4
	LEN 20
	NOTE E_, 4
	LEN 10
	NOTE D_, 4
	NEXT
Pat_5E52:
	VOLENV 15, $11, $1F, $14
	WAVE Wave_7A1E
	CH_TRANSPOSE $0C
	PAT_CALL Pat_5E43
	LENGTH $5A
	NOTE G_, 3
	PAT_CALL Pat_5E43
	LEN 30
	NOTE G_, 4
	LEN 10
	NOTE B_, 2
	NOTE C_, 3
	NOTE B_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE G_, 2
	NEXT
Pat_5E6E:
	PAT_CALL Pat_5E43
	LENGTH $3C
	NOTE G_, 3
	LEN 30
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE B_, 3
	NOTE E_, 4
	NOTE D_, 4
	LEN 20
	NOTE D_, 4
	LEN 10
	NOTE C_, 4
	LEN 30
	NOTE A_, 3
	LENGTH $3C
	NOTE G_, 1
	NEXT
Pat_5E84:
	PAT_CALL Pat_5E43
	LENGTH $3C
	NOTE B_, 3
	LEN 30
	NOTE C_, 4
	LEN 20
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	LENGTH $3C
	NOTE A_, 3
	CH_TRANSPOSE $00
	NEXT
DrumPat_5E9C:
	db DRUM_LEVEL + 15, 1, DRUM_LEVEL + 14, 6, DRUM_LEVEL + 13, 6, DRUM_LEVEL + 15, 2
	db DRUM_LEVEL + 14, 6, DRUM_LEVEL + 13, 6, DRUM_LOOP
DrumPat_5EA9:
	db 7, 0, 7, 0, 7, 0, 2, 6
	db 1, 2, 2, 2, DRUM_LOOP

; Song 8: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong8:
	ld a, $74
	ld [wInstrTableHi], a
	ld a, $36
	ld [wInstrTable], a
	ld de, Song8_Ch1
	call StartMusicCh1
	ld de, Song8_Ch2
	call StartMusicCh2
	ld de, Song8_Ch3
	jp StartMusicCh3
Song8_Ch1:
	dw Pat_5F9B
Loop_5ED4:
	dw Pat_5EFC
	dw Pat_5F52
	dw Pat_5F52
	dw Pat_5FB7
	ORDER_LOOP Loop_5ED4
Song8_Ch2:
	dw Pat_602B
Loop_5EE2:
	dw Pat_6145
	dw Pat_6000
	dw Pat_6000
	dw Pat_6057
	ORDER_LOOP Loop_5EE2
Song8_Ch3:
	dw Pat_60DA
Loop_5EF0:
	dw Pat_61BF
	dw Pat_6090
	dw Pat_6090
	dw Pat_6115
	ORDER_LOOP Loop_5EF0
Pat_5EFC:
	LEN 12
	REPEAT 6
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	REPEAT_END
	REPEAT 8
	INSTR 6
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 6
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	REPEAT_END
	REPEAT 7
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	REPEAT_END
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE Ash, 4
	INSTR 6
	NOTE D_, 2
	INSTR 1
	NOTE Ash, 4
	REPEAT 4
	INSTR 6
	NOTE C_, 3
	INSTR 1
	NOTE C_, 5
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE C_, 5
	REPEAT_END
	REPEAT 2
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	REPEAT_END
	REPEAT 2
	INSTR 6
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 6
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	REPEAT_END
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE A_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE B_, 2
	INSTR 1
	NOTE G_, 4
	NEXT
Pat_5F52:
	REPEAT 4
	INSTR 6
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	REPEAT_END
	REPEAT 2
	INSTR 6
	NOTE D_, 3
	INSTR 1
	NOTE D_, 4
	INSTR 6
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	REPEAT_END
	INSTR 6
	NOTE D_, 3
	INSTR 1
	NOTE D_, 4
	INSTR 6
	NOTE C_, 3
	INSTR 1
	NOTE D_, 4
	INSTR 6
	NOTE B_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 6
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	REPEAT 4
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	REPEAT_END
	REPEAT 2
	INSTR 6
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	REPEAT_END
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE Gsh, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE A_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE B_, 2
	INSTR 1
	NOTE G_, 4
	NEXT
Pat_5F9B:
	INSTR 6
	LEN 24
	NOTE G_, 2
	LEN 18
	NOTE G_, 2
	LEN 6
	NOTE D_, 2
	LEN 12
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE C_, 3
	LEN 18
	NOTE D_, 2
	LEN 6
	NOTE D_, 2
	LEN 12
	NOTE E_, 2
	NOTE Fsh, 2
	NOTE G_, 2
	LEN 6
	NOTE B_, 2
	NOTE D_, 3
	LEN 12
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	NEXT
Pat_5FB7:
	INSTR 6
	LEN 12
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 6
	NOTE C_, 2
	INSTR 1
	LEN 6
	NOTE C_, 4
	INSTR 6
	NOTE G_, 2
	LEN 12
	NOTE C_, 2
	INSTR 1
	LEN 6
	NOTE C_, 4
	NOTE C_, 4
	LEN 12
	NOTE C_, 4
	INSTR 6
	NOTE G_, 2
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 6
	NOTE C_, 2
	INSTR 1
	LEN 6
	NOTE C_, 4
	INSTR 6
	NOTE G_, 2
	LEN 12
	NOTE C_, 2
	INSTR 1
	LEN 6
	NOTE C_, 4
	NOTE C_, 4
	INSTR 6
	LEN 12
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 6
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 6
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 6
	NOTE C_, 3
	INSTR 1
	NOTE F_, 4
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 6
	NOTE C_, 2
	NOTE G_, 2
	LEN 24
	NOTE C_, 2
	NEXT
Pat_6000:
	LEN 12
	HWENV $F2, $04, $A1
	REPEAT 4
	NOTE E_, 3
	NOTE G_, 3
	NOTE E_, 3
	NOTE G_, 3
	REPEAT_END
	REPEAT 4
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	REPEAT_END
	LEN 12
	REPEAT 4
	NOTE G_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	REPEAT_END
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	LEN 6
	REPEAT 2
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE B_, 3
	REPEAT_END
	LEN 12
	REPEAT 2
	NOTE D_, 4
	NOTE B_, 3
	NOTE D_, 4
	NOTE B_, 3
	REPEAT_END
	NEXT
Pat_602B:
	HWENV $F0, $00
	ARP 0
	DUTY_75
	RELEASE $02, $F1
	LEN 18
	NOTE G_, 3
	LEN 6
	WAIT2
	LEN 12
	NOTE G_, 3
	LEN 6
	WAIT2
	NOTE D_, 3
	NOTE G_, 3
	WAIT2
	NOTE A_, 3
	WAIT2
	NOTE B_, 3
	WAIT2
	NOTE C_, 4
	WAIT2
	LEN 18
	NOTE D_, 3
	LEN 6
	NOTE D_, 3
	NOTE E_, 3
	WAIT2
	NOTE Fsh, 3
	WAIT2
	LEN 12
	NOTE G_, 3
	LEN 6
	NOTE B_, 3
	NOTE D_, 4
	LEN 12
	NOTE G_, 3
	WAIT2
	RELEASE $00
	NEXT
Pat_6057:
	LEN 12
	NOTE C_, 3
	WAIT2
	NOTE C_, 3
	LEN 6
	WAIT2
	NOTE D_, 3
	LEN 12
	NOTE C_, 3
	LEN 24
	WAIT2
	LEN 12
	NOTE G_, 3
	NOTE C_, 3
	WAIT2
	NOTE C_, 3
	LEN 6
	WAIT2
	NOTE D_, 3
	LEN 12
	NOTE C_, 3
	LEN 6
	NOTE G_, 4
	NOTE F_, 4
	LEN 12
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE G_, 4
	LEN 6
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	LEN 12
	NOTE C_, 5
	LEN 6
	NOTE B_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 12
	NOTE E_, 4
	LEN 6
	NOTE C_, 4
	NOTE B_, 3
	LEN 24
	NOTE C_, 4
	NEXT
Pat_6090:
	WAVE Wave_7A9E
	VOLENV 15, $15, $1F, $11
	DRUMS $06, DrumPat_6235
	LEN 12
	NOTE C_, 4
	REPEAT 2
	LEN 6
	NOTE C_, 5
	NOTE B_, 4
	LEN 12
	NOTE C_, 5
	LEN 24
	NOTE G_, 4
	REPEAT_END
	LEN 6
	NOTE C_, 5
	NOTE B_, 4
	LEN 12
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE Csh, 5
	NOTE D_, 5
	NOTE A_, 4
	LENGTH $48
	NOTE A_, 4
	LEN 24
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	LEN 12
	NOTE G_, 3
	REPEAT 2
	LEN 6
	NOTE B_, 4
	NOTE Ash, 4
	LEN 12
	NOTE B_, 4
	LEN 24
	NOTE G_, 4
	REPEAT_END
	LEN 6
	NOTE B_, 4
	NOTE Ash, 4
	LEN 12
	NOTE B_, 4
	NOTE Ash, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE G_, 4
	LENGTH $48
	NOTE G_, 4
	LEN 24
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE B_, 3
	NEXT
Pat_60DA:
	DRUMS $0C, DrumPat_623E
	VOLENV 15, $11, $1A, $18
	VIBRATO $0C, $01, $04
	RELEASE $62, $51
	ARP_OFF
	CH_TRANSPOSE $0C
	WAVE Wave_7ADE
	LEN 18
	NOTE G_, 4
	LEN 6
	WAIT2
	LEN 12
	NOTE G_, 4
	LEN 6
	WAIT2
	NOTE Fsh, 4
	NOTE G_, 4
	WAIT2
	NOTE A_, 4
	WAIT2
	NOTE B_, 4
	WAIT2
	NOTE C_, 5
	WAIT2
	LEN 3
	REPEAT 7
	NOTE D_, 5
	NOTE E_, 5
	REPEAT_END
	NOTE D_, 5
	NOTE B_, 4
	LEN 12
	NOTE G_, 4
	LEN 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE D_, 5
	LEN 12
	NOTE G_, 5
	ARP 0
Pat_6110:
	WAVE Wave_7B0E
	NOTE D_, 4
	NEXT
Pat_6115:
	DRUMS $0C, DrumPat_623E
	WAVE Wave_7ADE
	VOLENV 15, $11, $1A, $18
	REPEAT 2
	LEN 12
	NOTE C_, 4
	WAIT2
	NOTE C_, 4
	LEN 6
	WAIT2
	NOTE G_, 3
	LEN 12
	NOTE C_, 4
	LEN 36
	WAIT2
	REPEAT_END
	LEN 12
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE E_, 4
	LEN 24
	NOTE D_, 4
	LEN 12
	NOTE D_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	LEN 4
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	LEN 12
	NOTE C_, 5
	PAT_GOTO Pat_6110
Pat_6145:
	ARP 0
	DUTY_75
	HWENV $F1, $02, $73
	LEN 12
	WAIT
	REPEAT 3
	LEN 12
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	LENGTH $3C
	NOTE D_, 5
	REPEAT_END
	LEN 12
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	NOTE B_, 5
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	LENGTH $3C
	NOTE Fsh, 5
	REPEAT 2
	LEN 12
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	LENGTH $3C
	NOTE Fsh, 5
	REPEAT_END
	LEN 12
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	LEN 24
	NOTE B_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE D_, 5
	REPEAT 2
	LENGTH $3C
	NOTE D_, 5
	LEN 12
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	REPEAT_END
	LENGTH $3C
	NOTE D_, 5
	LEN 12
	NOTE F_, 5
	NOTE E_, 5
	NOTE Dsh, 5
	LEN 24
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE G_, 5
	LEN 36
	NOTE G_, 5
	LEN 12
	NOTE G_, 5
	LEN 24
	NOTE Fsh, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE G_, 5
	LEN 36
	NOTE B_, 5
	LEN 12
	NOTE B_, 5
	NOTE C_, 6
	NOTE B_, 5
	NOTE A_, 5
	NOTE G_, 5
	LEN 24
	NOTE Fsh, 5
	NOTE A_, 5
	NOTE G_, 5
	LEN 18
	NOTE G_, 5
	LEN 6
	NOTE G_, 5
	LEN 36
	NOTE G_, 5
	LEN 12
	NOTE E_, 3
	NEXT
Pat_61A6:
	LEN 12
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE B_, 4
	LEN 24
	NOTE D_, 4
	LEN 36
	NOTE D_, 4
	LEN 12
	NOTE B_, 3
	NOTE C_, 4
	NOTE Csh, 4
	LEN 24
	NOTE D_, 4
	LEN 36
	NOTE D_, 4
	LEN 12
	NOTE D_, 4
	NOTE E_, 4
	NEXT
Pat_61BF:
	DRUMS $06, DrumPat_6210
	PAT_CALL Pat_61A6
	NOTE G_, 4
	LENGTH $54
	NOTE Fsh, 4
	LEN 12
	NOTE D_, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 24
	NOTE G_, 4
	LENGTH $30
	NOTE Fsh, 4
	LEN 12
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	LEN 24
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	LEN 36
	NOTE D_, 4
	LEN 12
	NOTE D_, 4
	PAT_CALL Pat_61A6
	NOTE F_, 4
	LENGTH $54
	NOTE E_, 4
	LEN 12
	NOTE E_, 4
	LEN 36
	NOTE A_, 4
	LEN 12
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE Csh, 5
	LEN 24
	NOTE D_, 5
	LEN 36
	NOTE G_, 4
	LEN 12
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	LEN 24
	NOTE D_, 4
	NOTE B_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 18
	NOTE G_, 4
	LEN 6
	NOTE G_, 4
	LENGTH $30
	NOTE G_, 4
	NEXT
DrumPat_6210:
	db DRUM_REPEAT + 3, 1, 0, 6, 0, 9, 0, 6
	db 0, DRUM_REPEAT_END, 1, 0, 6, 0, 9, 0
	db 1, 0, DRUM_REPEAT + 3, 1, 0, 6, 0, 9
	db 0, 6, 0, DRUM_REPEAT_END, 1, 0, 9, 9
	db 9, 0, 9, 0, DRUM_LOOP
DrumPat_6235:
	db 1, 0, 4, 6, 9, 0, 4, 6
	db DRUM_LOOP
DrumPat_623E:
	db 1, 6, 1, 6, DRUM_LOOP

; Song 9: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong9:
	ld a, $74
	ld [wInstrTableHi], a
	ld a, $36
	ld [wInstrTable], a
	ld de, Song9_Ch1
	call StartMusicCh1
	ld de, Song9_Ch2
	call StartMusicCh2
	ld de, Song9_Ch3
	jp StartMusicCh3
Song9_Ch1:
	dw Pat_628F
	dw Pat_62F1
	dw Pat_634D
	dw Pat_63AB
	dw Pat_6469
	dw Pat_640A
	ORDER_LOOP Song9_Ch1
Song9_Ch2:
	dw Pat_64CF
	dw Pat_651D
	dw Pat_6560
	dw Pat_65AB
	dw Pat_662F
	dw Pat_65F0
	ORDER_LOOP Song9_Ch2
Song9_Ch3:
	dw Pat_6656
	dw Pat_66A2
	dw Pat_66D3
	dw Pat_6718
	dw Pat_6785
	dw Pat_6756
	ORDER_LOOP Song9_Ch3
Pat_628F:
	RELEASE $02, $52
	INSTR 10
	LEN 22
	NOTE A_, 2
	INSTR 2
	LEN 11
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE A_, 2
	LEN 11
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE G_, 2
	LEN 11
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 10
	NOTE A_, 2
	LEN 22
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	INSTR 2
	LEN 11
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE A_, 2
	LEN 11
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE C_, 3
	LEN 11
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 10
	NOTE A_, 2
	LEN 22
	NOTE C_, 3
	NOTE C_, 3
	NOTE A_, 2
	INSTR 2
	LEN 11
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE A_, 2
	LEN 11
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE G_, 2
	LEN 11
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 10
	NOTE A_, 2
	LEN 22
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	INSTR 2
	LEN 11
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE A_, 2
	LEN 11
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE C_, 3
	LEN 11
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 10
	NOTE A_, 2
	LEN 22
	NOTE C_, 3
	NOTE C_, 3
	NEXT
Pat_62F1:
	LEN 22
	NOTE D_, 3
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	LEN 22
	NOTE D_, 3
	LEN 11
	NOTE D_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 10
	LEN 22
	NOTE C_, 3
	LEN 11
	NOTE D_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 10
	NOTE D_, 3
	LEN 22
	NOTE C_, 3
	NOTE C_, 3
	NOTE D_, 3
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	LEN 22
	NOTE D_, 3
	LEN 11
	NOTE D_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 10
	LEN 22
	NOTE F_, 3
	LEN 11
	NOTE D_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 10
	NOTE D_, 3
	LEN 22
	NOTE F_, 3
	NOTE F_, 3
	NOTE D_, 3
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	LEN 22
	NOTE D_, 3
	LEN 11
	NOTE D_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 10
	LEN 22
	NOTE C_, 3
	LEN 11
	NOTE D_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 10
	NOTE D_, 3
	LEN 22
	NOTE C_, 3
	NOTE D_, 3
	NOTE A_, 2
	INSTR 1
	LEN 11
	NOTE A_, 4
	INSTR 10
	LEN 22
	NOTE A_, 2
	LEN 11
	NOTE A_, 2
	INSTR 1
	NOTE A_, 4
	INSTR 10
	NOTE G_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE E_, 2
	NEXT
Pat_634D:
	LEN 22
	NOTE Ash, 2
	INSTR 1
	LEN 11
	NOTE Ash, 3
	INSTR 10
	LEN 22
	NOTE Ash, 2
	LEN 11
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 3
	INSTR 10
	LEN 22
	NOTE F_, 2
	LEN 11
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 3
	INSTR 10
	NOTE Ash, 2
	LEN 22
	NOTE C_, 3
	NOTE C_, 3
	NOTE D_, 3
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	LEN 22
	NOTE D_, 3
	LEN 11
	NOTE D_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 10
	LEN 22
	NOTE A_, 2
	LEN 11
	NOTE D_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 10
	NOTE D_, 3
	LEN 22
	NOTE A_, 2
	NOTE C_, 3
	NOTE Ash, 2
	INSTR 1
	LEN 11
	NOTE Ash, 3
	INSTR 10
	LEN 22
	NOTE Ash, 2
	LEN 11
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 3
	INSTR 10
	LEN 22
	NOTE F_, 2
	LEN 11
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 3
	INSTR 10
	NOTE Ash, 2
	LEN 22
	NOTE F_, 2
	NOTE Ash, 2
	NOTE G_, 2
	INSTR 1
	LEN 11
	NOTE G_, 3
	INSTR 10
	LEN 22
	NOTE G_, 2
	LEN 11
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 10
	LEN 22
	NOTE D_, 2
	LEN 11
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 10
	NOTE G_, 2
	LEN 22
	NOTE A_, 2
	NOTE A_, 2
	NEXT
Pat_63AB:
	LEN 22
	NOTE Ash, 2
	INSTR 1
	LEN 11
	NOTE Ash, 3
	INSTR 10
	LEN 22
	NOTE Ash, 2
	LEN 11
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 3
	INSTR 10
	LEN 22
	NOTE F_, 2
	LEN 11
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 3
	INSTR 10
	NOTE Ash, 2
	LEN 22
	NOTE C_, 3
	NOTE C_, 3
	NOTE D_, 3
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	LEN 22
	NOTE D_, 3
	LEN 11
	NOTE D_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 10
	LEN 22
	NOTE A_, 2
	LEN 11
	NOTE D_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 10
	NOTE D_, 3
	LEN 22
	NOTE A_, 2
	NOTE C_, 3
	NOTE Ash, 2
	INSTR 1
	LEN 11
	NOTE Ash, 3
	INSTR 10
	LEN 22
	NOTE Ash, 2
	LEN 11
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 3
	INSTR 10
	LEN 22
	NOTE F_, 2
	LEN 11
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 3
	INSTR 10
	NOTE Ash, 2
	LEN 22
	NOTE F_, 2
	NOTE Ash, 2
	NOTE G_, 2
	INSTR 1
	LEN 11
	NOTE G_, 3
	INSTR 10
	LEN 22
	NOTE G_, 2
	LEN 11
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 10
	LEN 22
	NOTE A_, 2
	LEN 11
	NOTE A_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 10
	NOTE G_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE E_, 2
	NEXT
Pat_640A:
	LEN 22
	NOTE D_, 2
	INSTR 2
	LEN 11
	NOTE D_, 3
	INSTR 10
	LEN 22
	NOTE D_, 2
	LEN 11
	NOTE D_, 2
	INSTR 2
	NOTE D_, 3
	INSTR 10
	LEN 22
	NOTE C_, 2
	LEN 11
	NOTE D_, 2
	INSTR 2
	NOTE D_, 3
	INSTR 10
	NOTE D_, 2
	LEN 22
	NOTE C_, 2
	NOTE C_, 2
	NOTE D_, 2
	INSTR 2
	LEN 11
	NOTE D_, 3
	INSTR 10
	LEN 22
	NOTE D_, 2
	LEN 11
	NOTE D_, 2
	INSTR 2
	NOTE D_, 3
	INSTR 10
	LEN 22
	NOTE F_, 2
	LEN 11
	NOTE D_, 2
	INSTR 2
	NOTE D_, 3
	INSTR 10
	NOTE D_, 2
	LEN 22
	NOTE F_, 2
	NOTE G_, 2
	INSTR 10
	NOTE A_, 2
	INSTR 2
	LEN 11
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE A_, 2
	LEN 11
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE G_, 2
	LEN 11
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 10
	NOTE A_, 2
	LEN 22
	NOTE G_, 2
	NOTE G_, 2
	NOTE A_, 2
	INSTR 2
	LEN 11
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE A_, 2
	LEN 11
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 10
	LEN 22
	NOTE C_, 3
	LEN 11
	NOTE A_, 2
	INSTR 2
	NOTE A_, 3
	INSTR 10
	NOTE A_, 2
	LEN 22
	NOTE C_, 3
	NOTE C_, 3
	NEXT
Pat_6469:
	LEN 22
	NOTE D_, 2
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	NOTE D_, 2
	LEN 22
	NOTE D_, 2
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	NOTE D_, 2
	LEN 22
	NOTE D_, 2
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	NOTE D_, 2
	LEN 22
	NOTE D_, 2
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	NOTE D_, 2
	LEN 22
	NOTE D_, 2
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	NOTE D_, 2
	LEN 22
	NOTE D_, 2
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	NOTE D_, 2
	LEN 22
	NOTE D_, 2
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	NOTE D_, 2
	LEN 22
	NOTE D_, 2
	INSTR 2
	LEN 11
	NOTE D_, 4
	INSTR 10
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 10
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 10
	NOTE D_, 2
	NOTE G_, 2
	NOTE G_, 2
	INSTR 2
	NOTE G_, 4
	INSTR 10
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	INSTR 2
	NOTE G_, 4
	INSTR 10
	NOTE G_, 2
	NOTE A_, 2
	NOTE A_, 2
	INSTR 1
	NOTE A_, 4
	INSTR 10
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	INSTR 1
	NOTE A_, 4
	INSTR 10
	NOTE A_, 2
	NOTE D_, 2
	NOTE D_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 10
	NOTE D_, 2
	LEN 22
	NOTE F_, 2
	NOTE F_, 2
	NEXT
Pat_64CF:
	HWENV $C2, $0B, $81
	DUTY_75
	ARP 0
	LEN 11
	NOTE A_, 3
	NOTE E_, 4
	NOTE F_, 4
	LEN 22
	NOTE E_, 4
	LEN 11
	NOTE A_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE F_, 4
	LEN 22
	NOTE E_, 4
	LEN 11
	NOTE A_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE F_, 4
	LEN 22
	NOTE E_, 4
	LEN 11
	NOTE A_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE F_, 4
	LEN 22
	NOTE E_, 4
	LEN 11
	NOTE A_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE F_, 4
	LEN 22
	NOTE E_, 4
	LEN 11
	NOTE A_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE F_, 4
	LEN 22
	NOTE E_, 4
	LEN 11
	NOTE A_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE A_, 3
	NOTE E_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE D_, 5
	NOTE C_, 5
	NEXT
Pat_651D:
	LEN 11
	NOTE D_, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 22
	NOTE A_, 4
	LEN 11
	NOTE D_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 22
	NOTE A_, 4
	LEN 11
	NOTE D_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 22
	NOTE A_, 4
	LEN 11
	NOTE D_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 22
	NOTE A_, 4
	LEN 11
	NOTE D_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 22
	NOTE A_, 4
	LEN 11
	NOTE D_, 5
	NOTE Ash, 4
	NOTE G_, 4
	LEN 33
	NOTE A_, 4
	NOTE E_, 4
	LEN 22
	NOTE A_, 4
	NOTE E_, 4
	NOTE Ash, 4
	LEN 11
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NEXT
Pat_6560:
	LEN 11
	NOTE D_, 4
	LEN 22
	NOTE F_, 4
	LEN 11
	NOTE D_, 4
	LEN 22
	NOTE F_, 4
	LEN 11
	NOTE D_, 4
	LEN 22
	NOTE F_, 4
	LEN 11
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	LEN 22
	NOTE G_, 4
	NOTE F_, 4
	LEN 11
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 22
	NOTE D_, 4
	LEN 11
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE A_, 3
	NOTE A_, 4
	NOTE A_, 3
	NOTE G_, 4
	NOTE A_, 3
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 22
	NOTE F_, 4
	LEN 11
	NOTE D_, 4
	LEN 22
	NOTE F_, 4
	LEN 11
	NOTE D_, 4
	LEN 22
	NOTE F_, 4
	LEN 11
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	LEN 22
	NOTE G_, 4
	NOTE F_, 4
	LEN 11
	NOTE G_, 4
	NOTE F_, 4
	NOTE D_, 4
	LEN 22
	NOTE B_, 3
	LEN 11
	NOTE D_, 4
	NOTE G_, 4
	LEN 22
	NOTE B_, 3
	LEN 11
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NEXT
Pat_65AB:
	LEN 11
	NOTE D_, 4
	LEN 22
	NOTE F_, 4
	LEN 11
	NOTE D_, 4
	LEN 22
	NOTE F_, 4
	LEN 11
	NOTE D_, 4
	LEN 22
	NOTE F_, 4
	LEN 11
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	LEN 22
	NOTE G_, 4
	NOTE F_, 4
	LEN 11
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 22
	NOTE D_, 4
	LEN 11
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE A_, 3
	NOTE A_, 4
	NOTE A_, 3
	NOTE G_, 4
	NOTE A_, 3
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE F_, 4
	LEN 22
	NOTE D_, 5
	NOTE C_, 5
	LEN 11
	NOTE D_, 5
	LEN 33
	NOTE Ash, 4
	LEN 22
	NOTE D_, 5
	LEN 11
	NOTE C_, 5
	LEN 22
	NOTE D_, 5
	LEN 33
	NOTE Ash, 4
	LEN 22
	NOTE D_, 5
	NOTE C_, 5
	LEN 11
	NOTE D_, 5
	LEN 22
	NOTE Csh, 5
	LEN 11
	NOTE Csh, 5
	NOTE Ash, 4
	NOTE Ash, 4
	LEN 22
	NOTE A_, 4
	NOTE E_, 4
	NEXT
Pat_65F0:
	LEN 33
	NOTE D_, 3
	LEN 22
	NOTE D_, 3
	NOTE D_, 3
	NOTE C_, 3
	NOTE D_, 3
	LEN 11
	NOTE D_, 3
	LEN 22
	NOTE C_, 3
	NOTE C_, 3
	LEN 33
	NOTE D_, 3
	LEN 22
	NOTE D_, 3
	NOTE D_, 3
	NOTE F_, 3
	NOTE D_, 3
	LEN 11
	NOTE D_, 3
	LEN 22
	NOTE F_, 3
	NOTE G_, 3
	LEN 11
	NOTE A_, 2
	NOTE E_, 4
	NOTE F_, 4
	LEN 22
	NOTE E_, 4
	LEN 11
	NOTE A_, 4
	NOTE F_, 4
	LEN 22
	NOTE E_, 4
	LEN 11
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 22
	NOTE E_, 4
	LEN 11
	NOTE E_, 4
	NOTE F_, 4
	LEN 22
	NOTE E_, 4
	LEN 11
	NOTE A_, 4
	NOTE F_, 4
	LEN 22
	NOTE E_, 4
	LEN 11
	NOTE E_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE D_, 5
	NOTE C_, 5
	NEXT
Pat_662F:
	LENGTH $58
	NOTE A_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 11
	NOTE D_, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 22
	NOTE A_, 4
	LEN 11
	NOTE D_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Csh, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 22
	NOTE G_, 4
	LEN 11
	NOTE Csh, 5
	NOTE A_, 4
	NOTE E_, 4
	LEN 22
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 3
	NOTE F_, 3
	NEXT
Pat_6656:
	DRUMS $0B, DrumPat_67C7
	VOLENV 10, $15, $1F, $18
	VIBRATO $0B, $01, $04
	ARP 0
	RELEASE $02, $02
	WAVE Wave_7A5E
	LEN 11
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE E_, 5
	WAIT2
	NOTE D_, 5
	NOTE C_, 5
	LEN 22
	NOTE D_, 5
	LEN 11
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT2
	LEN 22
	NOTE A_, 4
	LEN 11
	WAIT2
	LENGTH $42
	NOTE E_, 4
	LENGTH $4D
	WAIT2
	LEN 11
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE E_, 5
	WAIT2
	NOTE D_, 5
	NOTE C_, 5
	LEN 22
	NOTE D_, 5
	LEN 11
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT2
	LEN 22
	NOTE A_, 4
	LEN 11
	WAIT2
	LENGTH $42
	NOTE E_, 5
	LENGTH $4D
	WAIT2
	NEXT
Pat_66A2:
	LEN 11
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	LEN 22
	NOTE A_, 5
	LEN 11
	NOTE G_, 5
	NOTE F_, 5
	LEN 22
	NOTE G_, 5
	LEN 11
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	LEN 22
	NOTE C_, 5
	LEN 33
	NOTE D_, 5
	LENGTH $8F
	NOTE A_, 4
	LEN 11
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	LEN 22
	NOTE A_, 5
	LEN 11
	NOTE G_, 5
	NOTE F_, 5
	LEN 22
	NOTE G_, 5
	LEN 11
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	LEN 22
	NOTE C_, 5
	LEN 33
	NOTE Csh, 5
	LENGTH $8F
	NOTE A_, 5
	NEXT
Pat_66D3:
	VOLENV 15, $00, $1F, $14
	WAVE Wave_7A1E
	LEN 22
	NOTE Ash, 3
	NOTE A_, 4
	LEN 11
	NOTE G_, 4
	LEN 22
	NOTE A_, 4
	LEN 33
	NOTE F_, 4
	LEN 22
	NOTE D_, 4
	NOTE F_, 4
	LEN 11
	NOTE G_, 4
	LEN 33
	NOTE D_, 4
	LEN 11
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE F_, 5
	LEN 22
	NOTE A_, 5
	LEN 11
	NOTE G_, 5
	LEN 44
	NOTE F_, 5
	LEN 22
	NOTE F_, 5
	NOTE E_, 5
	LEN 11
	NOTE F_, 5
	LEN 33
	NOTE D_, 5
	LEN 22
	NOTE F_, 5
	LEN 11
	NOTE E_, 5
	LEN 22
	NOTE F_, 5
	LEN 33
	NOTE D_, 5
	LEN 22
	NOTE F_, 5
	NOTE E_, 5
	LEN 11
	NOTE F_, 5
	LEN 22
	NOTE G_, 5
	LEN 11
	NOTE G_, 5
	NOTE F_, 5
	NOTE F_, 5
	LEN 22
	NOTE E_, 5
	NOTE D_, 5
	NEXT
Pat_6718:
	LEN 22
	NOTE Ash, 3
	NOTE A_, 4
	LEN 11
	NOTE G_, 4
	LEN 22
	NOTE A_, 4
	LEN 33
	NOTE F_, 4
	LEN 22
	NOTE D_, 4
	NOTE F_, 4
	LEN 11
	NOTE G_, 4
	LEN 33
	NOTE D_, 4
	LEN 11
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE F_, 5
	LEN 22
	NOTE A_, 5
	LEN 11
	NOTE G_, 5
	LEN 44
	NOTE F_, 5
	LEN 22
	NOTE F_, 5
	NOTE E_, 5
	LEN 11
	NOTE F_, 5
	LEN 33
	NOTE D_, 5
	LEN 22
	NOTE F_, 5
	LEN 11
	NOTE E_, 5
	LEN 22
	NOTE F_, 5
	LEN 33
	NOTE D_, 5
	LEN 22
	NOTE F_, 5
	NOTE E_, 5
	LEN 11
	NOTE F_, 5
	LEN 22
	NOTE E_, 5
	LEN 11
	NOTE E_, 5
	NOTE D_, 5
	NOTE D_, 5
	LEN 22
	NOTE Csh, 5
	NOTE A_, 4
	NEXT
Pat_6756:
	LEN 33
	NOTE D_, 2
	LEN 22
	NOTE D_, 2
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	LEN 11
	NOTE D_, 2
	LEN 22
	NOTE C_, 2
	NOTE C_, 2
	LEN 33
	NOTE D_, 2
	LEN 22
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	LEN 11
	NOTE D_, 2
	LEN 22
	NOTE F_, 2
	NOTE G_, 2
	LEN 33
	NOTE A_, 2
	NOTE E_, 3
	NOTE A_, 3
	NOTE E_, 3
	LEN 22
	NOTE A_, 3
	NOTE C_, 4
	LEN 33
	NOTE B_, 3
	LEN 22
	NOTE A_, 3
	LEN 11
	NOTE G_, 3
	LENGTH $42
	NOTE E_, 3
	CH_TRANSPOSE $00
	LEN 22
	NOTE G_, 3
	NOTE G_, 3
	NEXT
Pat_6785:
	LEN 11
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	LENGTH $37
	NOTE A_, 3
	LEN 11
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	LENGTH $37
	NOTE Ash, 3
	LEN 11
	NOTE Csh, 3
	NOTE D_, 3
	NOTE E_, 3
	LENGTH $37
	NOTE G_, 3
	LEN 11
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	LEN 22
	NOTE A_, 3
	LEN 11
	NOTE Ash, 3
	LEN 22
	NOTE A_, 3
	LEN 11
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	LENGTH $37
	NOTE A_, 3
	LEN 11
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	LENGTH $37
	NOTE Ash, 3
	LEN 11
	NOTE Csh, 3
	NOTE D_, 3
	NOTE E_, 3
	LEN 22
	NOTE A_, 3
	LEN 11
	NOTE G_, 3
	NOTE F_, 3
	NOTE E_, 3
	LEN 22
	NOTE F_, 3
	NOTE D_, 3
	WAVE Wave_7B1E
	CH_TRANSPOSE $0C
	NOTE C_, 3
	NOTE C_, 3
	NEXT
DrumPat_67C7:
	db 1, 6, 2, 1, 6, 1, 2, 1
	db 6, 1, 2, 1, 1, 6, 2, 6
	db DRUM_LOOP

; Song 10: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong10:
	ld a, $74
	ld [wInstrTableHi], a
	ld a, $36
	ld [wInstrTable], a
	ld de, Song10_Ch1
	call StartMusicCh1
	ld de, Song10_Ch2
	call StartMusicCh2
	ld de, Song10_Ch3
	jp StartMusicCh3
Pat_67F4:
	CH_TRANSPOSE $00
	NEXT
Pat_67F7:
	CH_TRANSPOSE $01
	NEXT
Song10_Ch1:
	dw Pat_6830
	dw Pat_6833
	dw Pat_6833
	dw Pat_6847
Loop_6802:
	dw Pat_67F4
	dw Pat_6852
	dw Pat_67F7
	dw Pat_6852
	ORDER_LOOP Loop_6802
Song10_Ch2:
	dw Pat_6830
	dw Pat_6868
	dw Pat_689F
	dw Pat_6882
Loop_6816:
	dw Pat_67F4
	dw Pat_688E
	dw Pat_688E
	dw Pat_67F7
	dw Pat_688E
	dw Pat_688E
	ORDER_LOOP Loop_6816
Song10_Ch3:
	dw Pat_68B3
	dw Pat_68FD
Loop_682A:
	dw Pat_690C
	ORDER_LOOP Loop_682A
Pat_6830:
	LEN 28
	REST
	NEXT
Pat_6833:
	DUTY_75
	HWENV $F3, $00
	ARP 0
	LEN 42
	NOTE C_, 2
	LEN 14
	NOTE C_, 2
	LEN 28
	NOTE C_, 2
	NOTE E_, 2
	LEN 42
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	NOTE F_, 2
	NEXT
Pat_6847:
	LEN 28
	NOTE C_, 3
	LEN 14
	NOTE C_, 2
	LEN 7
	WAIT2
	NOTE C_, 2
	LENGTH $38
	NOTE C_, 2
	NEXT
Pat_6852:
	HWENV $B2, $08, $30
	REPEAT 4
	LEN 42
	NOTE C_, 2
	LEN 14
	NOTE G_, 2
	LEN 28
	NOTE Ash, 2
	NOTE F_, 2
	LEN 42
	NOTE C_, 2
	LEN 14
	NOTE G_, 2
	NOTE Ash, 2
	NOTE Ash, 3
	NOTE F_, 2
	NOTE F_, 3
	REPEAT_END
	NEXT
Pat_6868:
	HWENV $D2, $0E, $20
	AUTODUTY $03
	ARP 4
	LEN 14
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	ARP 5
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NEXT
Pat_6882:
	ARP 4
	LEN 28
	NOTE C_, 6
	LEN 14
	NOTE C_, 5
	LEN 7
	WAIT2
	NOTE C_, 5
	LENGTH $38
	NOTE C_, 5
	NEXT
Pat_688E:
	HWENV $57, $18, $20
	ARP 4
	LENGTH $70
	NOTE C_, 5
	NOTE Ash, 4
	ARP 5
	NOTE A_, 4
	ARP 4
	LENGTH $38
	NOTE Gsh, 4
	NOTE Ash, 4
	NEXT
Pat_689F:
	ARP 4
	LEN 14
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	ARP 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	NOTE G_, 5
	NEXT
Pat_68B3:
	WAVE Wave_7B1E
	VOLENV 15, $1F, $1F, $13
	VIBRATO $0E, $02, $04
	ARP 0
	LEN 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE E_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE B_, 3
	DRUMS $07, DrumPat_6936
	RELEASE $01, $55
	PAT_CALL Pat_68DA
	CH_TRANSPOSE $0C
Pat_68DA:
	LEN 14
	NOTE C_, 4
	LEN 7
	NOTE E_, 4
	NOTE D_, 4
	LEN 14
	NOTE E_, 4
	LEN 28
	NOTE C_, 4
	LEN 14
	NOTE G_, 4
	LEN 7
	NOTE F_, 4
	NOTE E_, 4
	LEN 14
	NOTE D_, 4
	NOTE Ash, 3
	LEN 7
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE D_, 5
	NOTE Ash, 4
	NOTE D_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE Ash, 4
	NOTE D_, 5
	CH_TRANSPOSE $00
	NEXT
Pat_68FD:
	LEN 28
	NOTE C_, 6
	LEN 14
	NOTE C_, 4
	LEN 7
	WAIT2
	NOTE C_, 4
	DRUMS_OFF
	CALL_CODE Drum7
	LENGTH $38
	NOTE C_, 4
	NEXT
Pat_690C:
	DRUMS $07, DrumPat_6948
	VOLENV 10, $11, $1F, $11
	RELEASE $03, $55
	LEN 14
	REPEAT 8
	NOTE C_, 6
	NOTE G_, 5
	NOTE D_, 6
	NOTE G_, 5
	NOTE C_, 5
	NOTE G_, 5
	NOTE D_, 6
	NOTE G_, 5
	REPEAT_END
	LEN 7
	REPEAT 8
	NOTE Csh, 6
	NOTE Csh, 7
	NOTE Gsh, 5
	NOTE Gsh, 6
	NOTE Dsh, 6
	NOTE Dsh, 7
	NOTE Gsh, 5
	NOTE Gsh, 6
	NOTE Csh, 5
	NOTE Csh, 6
	NOTE Gsh, 5
	NOTE Gsh, 6
	NOTE Dsh, 6
	NOTE Dsh, 7
	NOTE Gsh, 5
	NOTE Gsh, 6
	REPEAT_END
	NEXT
DrumPat_6936:
	db DRUM_LEVEL + 14, 9, 0, 10, 10, 9, 0, 10
	db 0, 9, 10, 10, 9, 9, 10, 10
	db 9, DRUM_LOOP
DrumPat_6948:
	db DRUM_LEVEL + 13, DRUM_REPEAT + 3, 6, 0, 6, 0, 4, 0
	db 6, 0, DRUM_REPEAT_END, 6, 0, 6, 6, 4
	db 6, 6, 4, DRUM_LOOP

; Song 11: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong11:
	ld a, $74
	ld [wInstrTableHi], a
	ld a, $36
	ld [wInstrTable], a
	ld de, Song11_Ch1
	call StartMusicCh1
	ld de, Song11_Ch2
	call StartMusicCh2
	ld de, Song11_Ch3
	jp StartMusicCh3
Song11_Ch1:
	dw Pat_69A8
	dw Pat_69A8
Loop_697C:
	dw Pat_69C5
	dw Pat_69C5
	dw Pat_6A26
	dw Pat_6A26
	ORDER_LOOP Loop_697C
Song11_Ch2:
	dw Pat_6A87
	dw Pat_6A93
Loop_698C:
	dw Pat_6B06
	dw Pat_6B06
	dw Pat_6AC5
	dw Pat_6AC5
	ORDER_LOOP Loop_698C
Song11_Ch3:
	dw Pat_6AF7
	dw Pat_6B3D
Loop_699C:
	dw Pat_6AF7
	dw Pat_6AF7
	dw Pat_6B3D
	dw Pat_6B74
	ORDER_LOOP Loop_699C
Pat_69A8:
	LEN 30
	HWENV $F1, $02, $81
	DUTY_50
	DRUMS $0A, DrumPat_6B79
	GLIDE $FE
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	NEXT
Pat_69C5:
	INSTR 6
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 3
	INSTR 6
	LEN 20
	NOTE D_, 2
	INSTR 1
	LEN 10
	NOTE G_, 3
	INSTR 6
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 3
	INSTR 6
	LEN 20
	NOTE D_, 2
	INSTR 1
	LEN 10
	NOTE G_, 3
	INSTR 6
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 3
	INSTR 6
	LEN 20
	NOTE D_, 2
	INSTR 1
	LEN 10
	NOTE G_, 3
	INSTR 6
	LEN 20
	NOTE F_, 2
	INSTR 1
	LEN 10
	NOTE F_, 3
	INSTR 6
	LEN 20
	NOTE C_, 2
	INSTR 1
	LEN 10
	NOTE F_, 3
	INSTR 6
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 3
	INSTR 6
	LEN 20
	NOTE D_, 2
	INSTR 1
	LEN 10
	NOTE G_, 3
	INSTR 6
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 3
	INSTR 6
	LEN 20
	NOTE D_, 2
	INSTR 1
	LEN 10
	NOTE G_, 3
	INSTR 6
	LEN 20
	NOTE F_, 2
	INSTR 1
	LEN 10
	NOTE F_, 3
	INSTR 6
	LEN 20
	NOTE C_, 2
	INSTR 1
	LEN 10
	NOTE F_, 3
	INSTR 6
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 3
	INSTR 6
	LEN 20
	NOTE D_, 2
	INSTR 1
	LEN 10
	NOTE G_, 3
	NEXT
Pat_6A26:
	INSTR 6
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 4
	INSTR 6
	LEN 20
	NOTE D_, 2
	INSTR 1
	LEN 10
	NOTE G_, 4
	INSTR 6
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 4
	INSTR 6
	LEN 20
	NOTE D_, 2
	INSTR 1
	LEN 10
	NOTE G_, 4
	INSTR 6
	LEN 20
	NOTE F_, 2
	INSTR 1
	LEN 10
	NOTE F_, 4
	INSTR 6
	LEN 20
	NOTE C_, 2
	INSTR 1
	LEN 10
	NOTE F_, 4
	INSTR 6
	LEN 20
	NOTE F_, 2
	INSTR 1
	LEN 10
	NOTE F_, 4
	INSTR 6
	LEN 20
	NOTE C_, 2
	INSTR 1
	LEN 10
	NOTE F_, 4
	INSTR 6
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 4
	INSTR 6
	LEN 20
	NOTE D_, 2
	INSTR 1
	LEN 10
	NOTE G_, 4
	INSTR 6
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE G_, 4
	INSTR 6
	LEN 20
	NOTE D_, 2
	INSTR 1
	LEN 10
	NOTE G_, 4
	INSTR 6
	LEN 20
	NOTE C_, 3
	INSTR 1
	LEN 10
	NOTE C_, 5
	INSTR 6
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE C_, 5
	INSTR 6
	LEN 20
	NOTE C_, 3
	INSTR 1
	LEN 10
	NOTE C_, 5
	INSTR 6
	LEN 20
	NOTE G_, 2
	INSTR 1
	LEN 10
	NOTE C_, 5
	NEXT
Pat_6A87:
	HWENV $A2, $0A, $72
	ARP 0
	DUTY_75
	LENGTH $A0
	NOTE G_, 2
	REST
	REST
	NEXT
Pat_6A93:
	LEN 10
	NOTE G_, 3
	NOTE D_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 5
	NOTE B_, 4
	NOTE F_, 3
	NOTE C_, 3
	NOTE A_, 3
	NOTE F_, 3
	NOTE C_, 4
	NOTE A_, 3
	NOTE F_, 4
	NOTE C_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 3
	NOTE D_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 5
	NOTE B_, 4
	NOTE C_, 4
	NOTE G_, 3
	NOTE E_, 4
	NOTE C_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 5
	NOTE E_, 5
	NEXT
Pat_6AC5:
	LEN 10
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 5
	NOTE B_, 4
	NOTE G_, 5
	NOTE D_, 5
	NOTE B_, 5
	NOTE G_, 5
	NOTE D_, 6
	NOTE B_, 5
	NOTE F_, 4
	NOTE C_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE F_, 5
	NOTE C_, 5
	NOTE A_, 5
	NOTE F_, 5
	NOTE C_, 6
	NOTE A_, 5
	NOTE G_, 4
	NOTE D_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 5
	NOTE B_, 4
	NOTE G_, 5
	NOTE D_, 5
	NOTE B_, 5
	NOTE G_, 5
	NOTE D_, 6
	NOTE B_, 5
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 5
	NOTE C_, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE C_, 6
	NOTE G_, 5
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	NOTE E_, 6
	NEXT
Pat_6AF7:
	VOLENV 9, $15, $15, $14
	ARP 0
	WAVE Wave_7B1E
	RELEASE $01, $A1
	VIBRATO $0A, $01, $05
Pat_6B06:
	CH_TRANSPOSE $00
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE B_, 4
	LEN 20
	NOTE A_, 4
	LEN 10
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 30
	NOTE G_, 4
	LEN 10
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 20
	NOTE E_, 4
	LEN 10
	NOTE D_, 4
	LEN 30
	NOTE C_, 4
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE B_, 4
	LEN 20
	NOTE A_, 4
	LEN 10
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	LEN 20
	NOTE G_, 5
	LEN 10
	NOTE A_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	LEN 30
	NOTE G_, 4
	NEXT
Pat_6B3D:
	LEN 10
	NOTE B_, 4
	NOTE C_, 5
	LEN 20
	NOTE D_, 5
	LEN 10
	NOTE C_, 5
	NOTE B_, 4
	LEN 20
	NOTE G_, 4
	LEN 10
	NOTE D_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE Ash, 4
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE F_, 4
	LEN 30
	NOTE C_, 4
	LEN 10
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	LEN 20
	NOTE G_, 5
	LEN 10
	NOTE D_, 5
	LEN 20
	NOTE C_, 5
	LEN 10
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE E_, 5
	LEN 5
	NOTE D_, 5
	NOTE E_, 5
	LEN 10
	NOTE D_, 5
	NOTE C_, 5
	LENGTH $3C
	NOTE G_, 5
	NEXT
Pat_6B74:
	CH_TRANSPOSE $0C
	PAT_GOTO Pat_6B3D
DrumPat_6B79:
	db DRUM_LEVEL + 13, 1, DRUM_LEVEL + 12, 6, DRUM_LEVEL + 10, 4, DRUM_LOOP

; Song 12: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong12:
	ld a, $74
	ld [wInstrTableHi], a
	ld a, $36
	ld [wInstrTable], a
	ld de, Song12_Ch1
	call StartMusicCh1
	ld de, Song12_Ch2
	call StartMusicCh2
	ld de, Song12_Ch3
	jp StartMusicCh3
Song12_Ch1:
	dw Pat_6BB4
	dw Pat_6C14
	ORDER_LOOP Song12_Ch1
Song12_Ch2:
	dw Pat_6C40
	dw Pat_6C91
	ORDER_LOOP Song12_Ch2
Song12_Ch3:
	dw Pat_6CBB
	dw Pat_6D04
	ORDER_LOOP Song12_Ch3
Pat_6BB4:
	HWENV $F2, $04, $A3
	ARP 0
	DUTY_75
	DRUMS $09, DrumPat_6D26
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE Ash, 2
	LEN 9
	NOTE Ash, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE Ash, 2
	LEN 9
	NOTE Ash, 3
	LEN 18
	NOTE Gsh, 2
	LEN 9
	NOTE Gsh, 3
	LEN 18
	NOTE Gsh, 2
	LEN 9
	NOTE Gsh, 3
	LEN 18
	NOTE Gsh, 2
	LEN 9
	NOTE Gsh, 3
	LEN 18
	NOTE Gsh, 2
	LEN 9
	NOTE Gsh, 3
	LEN 18
	NOTE Gsh, 2
	LEN 9
	NOTE Gsh, 3
	NOTE Gsh, 2
	NEXT
Pat_6C14:
	LEN 9
	WAIT
	NOTE Gsh, 3
	LEN 18
	NOTE Gsh, 2
	LEN 9
	NOTE Gsh, 3
	LEN 18
	NOTE Gsh, 2
	LEN 9
	NOTE Gsh, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE G_, 2
	LEN 9
	NOTE G_, 3
	LEN 18
	NOTE F_, 2
	LEN 9
	NOTE F_, 3
	LEN 18
	NOTE F_, 2
	LEN 9
	NOTE F_, 3
	LEN 18
	NOTE F_, 2
	LEN 9
	NOTE F_, 3
	LEN 18
	NOTE F_, 2
	LEN 9
	NOTE F_, 3
	NEXT
Pat_6C40:
	HWENV $F2, $04, $A3
	DUTY_50
	RELEASE $02, $00
	ARP 5
	LEN 27
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 27
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 27
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 18
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	ARP 4
	LEN 18
	NOTE Ash, 3
	LEN 9
	NOTE Ash, 3
	ARP 5
	LEN 27
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 27
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 27
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 18
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	ARP 4
	LEN 18
	NOTE Ash, 3
	LEN 9
	NOTE Ash, 3
	LEN 27
	NOTE Gsh, 3
	LEN 9
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	LEN 27
	NOTE Gsh, 3
	LEN 9
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	LEN 27
	NOTE Gsh, 3
	LEN 9
	NOTE Gsh, 3
	NEXT
Pat_6C91:
	ARP 4
	LEN 9
	NOTE Gsh, 3
	NOTE Gsh, 3
	ARP 5
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE C_, 4
	ARP 4
	LEN 18
	NOTE Gsh, 3
	LEN 9
	NOTE Gsh, 3
	ARP 5
	LEN 27
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 27
	NOTE G_, 3
	LEN 9
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	ARP 4
	LEN 18
	NOTE F_, 3
	NOTE F_, 3
	LEN 9
	NOTE F_, 3
	NOTE F_, 3
	LEN 18
	NOTE F_, 3
	LEN 9
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	NEXT
Pat_6CBB:
	VOLENV 15, $12, $2F, $11
	WAVE Wave_7A7E
	LEN 9
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE Ash, 3
	NOTE F_, 4
	NOTE Ash, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE Ash, 3
	NOTE F_, 4
	NOTE Ash, 4
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 3
	NEXT
Pat_6D04:
	LEN 9
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE Gsh, 3
	NOTE Dsh, 4
	NOTE Gsh, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE F_, 3
	NOTE C_, 4
	NOTE F_, 4
	NOTE F_, 3
	NOTE C_, 4
	NOTE F_, 4
	NOTE F_, 3
	NOTE C_, 4
	NOTE F_, 4
	NOTE F_, 3
	NOTE C_, 4
	NOTE F_, 4
	NEXT
DrumPat_6D26:
	db 9, 0, 10, 9, 9, 9, 9, 0
	db 10, 9, 9, 9, 9, 0, 10, 9
	db 9, 9, 9, 0, 10, 9, 0, 10
	db DRUM_LOOP

; Song 13: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong13:
	ld a, $74
	ld [wInstrTableHi], a
	ld a, $36
	ld [wInstrTable], a
	ld de, Song13_Ch1
	call StartMusicCh1
	ld de, Song13_Ch2
	call StartMusicCh2
	ld de, Song13_Ch3
	jp StartMusicCh3
Song13_Ch1:
	dw Pat_6D79
	dw Pat_6DB1
	dw Pat_6DDB
	ORDER_LOOP Song13_Ch1
Song13_Ch2:
	dw Pat_6E07
	dw Pat_6E36
	dw Pat_6E5F
	ORDER_LOOP Song13_Ch2
Song13_Ch3:
	dw Pat_6E89
	dw Pat_6EB7
	dw Pat_6ED5
	ORDER_LOOP Song13_Ch3
Pat_6D79:
	DRUMS $07, DrumPat_6EF6
	TRANSPOSE $01
	DUTY_75
	HWENV $F2, $04, $A3
	RELEASE $01, $00
	ARP 0
	LEN 14
	NOTE G_, 2
	ARP 4
	NOTE G_, 3
	NOTE G_, 3
	ARP 0
	NOTE F_, 2
	ARP 4
	NOTE F_, 3
	NOTE F_, 3
	ARP 0
	NOTE G_, 2
	ARP 4
	NOTE G_, 3
	NOTE G_, 3
	ARP 0
	NOTE D_, 2
	ARP 4
	NOTE G_, 3
	NOTE G_, 3
	ARP 0
	NOTE F_, 2
	ARP 4
	NOTE F_, 3
	NOTE F_, 3
	ARP 0
	NOTE C_, 2
	ARP 4
	NOTE C_, 3
	NOTE C_, 3
	ARP 0
	NOTE G_, 2
	ARP 4
	NOTE G_, 3
	NOTE G_, 3
	ARP 0
	NOTE F_, 2
	ARP 4
	NOTE F_, 3
	NOTE F_, 3
	NEXT
Pat_6DB1:
	ARP 0
	LEN 14
	NOTE G_, 2
	ARP 4
	NOTE G_, 3
	NOTE G_, 3
	ARP 0
	NOTE F_, 2
	ARP 4
	NOTE F_, 3
	NOTE F_, 3
	ARP 0
	NOTE G_, 2
	ARP 4
	NOTE G_, 3
	NOTE G_, 3
	ARP 0
	NOTE D_, 2
	ARP 4
	NOTE G_, 3
	NOTE G_, 3
	ARP 0
	NOTE F_, 2
	ARP 4
	NOTE F_, 3
	NOTE F_, 3
	ARP 0
	NOTE C_, 2
	ARP 4
	NOTE C_, 3
	NOTE C_, 3
	ARP 0
	NOTE G_, 2
	ARP 4
	NOTE G_, 3
	NOTE G_, 3
	ARP 0
	NOTE G_, 2
	ARP 4
	NOTE G_, 4
	NOTE G_, 4
	NEXT
Pat_6DDB:
	ARP 0
	LEN 14
	NOTE F_, 2
	ARP 4
	LEN 28
	NOTE F_, 4
	ARP 0
	LEN 14
	NOTE D_, 2
	ARP 4
	NOTE F_, 4
	NOTE G_, 4
	ARP 0
	NOTE F_, 2
	ARP 4
	LEN 28
	NOTE F_, 4
	ARP 0
	LEN 14
	NOTE D_, 2
	ARP 4
	NOTE F_, 4
	NOTE G_, 4
	ARP 0
	NOTE G_, 2
	ARP 4
	NOTE G_, 4
	NOTE G_, 4
	ARP 0
	NOTE F_, 2
	ARP 4
	NOTE F_, 4
	NOTE F_, 4
	ARP 0
	NOTE G_, 2
	ARP 4
	NOTE G_, 4
	NOTE G_, 4
	ARP 0
	NOTE F_, 2
	ARP 4
	NOTE G_, 4
	NOTE G_, 4
	NEXT
Pat_6E07:
	HWENV $C1, $02, $91
	ARP 0
	DUTY_75
	LEN 14
	WAIT
	LEN 7
	NOTE G_, 4
	NOTE B_, 4
	LEN 14
	NOTE D_, 5
	NOTE F_, 4
	NOTE A_, 4
	LEN 28
	NOTE C_, 5
	LEN 7
	NOTE G_, 4
	NOTE B_, 4
	LEN 14
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	LEN 28
	NOTE G_, 4
	LEN 7
	NOTE F_, 4
	NOTE A_, 4
	LEN 14
	NOTE C_, 5
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE B_, 4
	LEN 7
	NOTE B_, 4
	NOTE A_, 4
	LEN 14
	NOTE G_, 4
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE E_, 4
	LEN 14
	NOTE D_, 4
	NEXT
Pat_6E36:
	LEN 14
	WAIT
	LEN 7
	NOTE G_, 4
	NOTE B_, 4
	LEN 14
	NOTE D_, 5
	NOTE F_, 4
	NOTE A_, 4
	LEN 28
	NOTE C_, 5
	LEN 7
	NOTE G_, 4
	NOTE B_, 4
	LEN 14
	NOTE D_, 5
	NOTE G_, 4
	NOTE F_, 4
	LEN 28
	NOTE D_, 4
	LEN 7
	NOTE F_, 4
	NOTE A_, 4
	LEN 14
	NOTE C_, 5
	NOTE C_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	NOTE A_, 4
	LEN 14
	NOTE B_, 4
	NOTE C_, 5
	LEN 7
	NOTE C_, 5
	NOTE B_, 4
	LEN 14
	NOTE G_, 4
	NEXT
Pat_6E5F:
	LEN 14
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE E_, 4
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE A_, 3
	NOTE D_, 4
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE E_, 4
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE A_, 3
	NOTE C_, 4
	LEN 7
	NOTE B_, 3
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	NOTE G_, 4
	NOTE F_, 4
	LEN 7
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE G_, 3
	NOTE G_, 4
	NOTE A_, 4
	LEN 14
	NOTE F_, 4
	NOTE D_, 4
	NOTE B_, 3
	NEXT
Pat_6E89:
	WAVE Wave_7A5E
	VIBRATO $07, $01, $04
	VOLENV 15, $12, $15, $13
	RELEASE $02, $50
	LEN 21
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE F_, 4
	LEN 28
	NOTE G_, 4
	NOTE G_, 4
	LEN 14
	NOTE D_, 4
	NOTE E_, 4
	LEN 21
	NOTE F_, 4
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	LEN 28
	NOTE G_, 3
	LEN 14
	NOTE F_, 3
	NEXT
Pat_6EB7:
	LEN 21
	NOTE G_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE F_, 4
	LEN 28
	NOTE G_, 4
	NOTE G_, 4
	LEN 14
	NOTE D_, 5
	NOTE E_, 5
	LEN 21
	NOTE F_, 5
	LEN 7
	NOTE E_, 5
	LEN 14
	NOTE D_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	LEN 42
	NOTE G_, 5
	NEXT
Pat_6ED5:
	LENGTH $31
	NOTE A_, 3
	LEN 7
	NOTE B_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	LEN 21
	NOTE A_, 3
	LEN 7
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE A_, 4
	LEN 14
	NOTE G_, 4
	LEN 42
	NOTE D_, 4
	NOTE C_, 4
	LEN 28
	NOTE D_, 4
	LEN 14
	NOTE G_, 4
	LEN 28
	NOTE F_, 4
	LEN 14
	NOTE A_, 4
	NEXT
DrumPat_6EF6:
	db DRUM_LEVEL + 13, 1, 0, 6, 6, 6, 0, 9
	db 0, 6, 0, 6, 0, DRUM_LOOP

; Song 14: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong14:
	ld a, $74
	ld [wInstrTableHi], a
	ld a, $36
	ld [wInstrTable], a
	ld de, Song14_Ch1
	call StartMusicCh1
	ld de, Song14_Ch2
	call StartMusicCh2
	ld de, Song14_Ch3
	jp StartMusicCh3
Song14_Ch1:
	dw Pat_6F40
Loop_6F22:
	dw Pat_6F8E
	dw Pat_6FA4
	ORDER_LOOP Loop_6F22
Song14_Ch2:
	dw Pat_6FBA
Loop_6F2C:
	dw Pat_6FBF
	dw Pat_6FE2
	ORDER_LOOP Loop_6F2C
Song14_Ch3:
	dw Pat_7001
Loop_6F36:
	dw Pat_701A
	dw Pat_701A
	dw Pat_705D
	ORDER_LOOP Loop_6F36
Pat_6F40:
	HWENV $F2, $09, $60
	VIBRATO $09, $02, $05
	ARP 0
	DUTY_50
	RELEASE $02, $61
	LENGTH $36
	NOTE D_, 2
	LEN 9
	NOTE D_, 3
	LEN 18
	NOTE D_, 3
	LEN 9
	NOTE D_, 3
	LEN 18
	NOTE C_, 3
	LEN 9
	NOTE A_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE F_, 2
	LENGTH $36
	NOTE G_, 2
	LEN 9
	NOTE Ash, 2
	LEN 18
	NOTE Ash, 2
	LEN 9
	NOTE Ash, 2
	LEN 18
	NOTE A_, 2
	LEN 9
	NOTE F_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE Csh, 2
	LENGTH $36
	NOTE D_, 2
	LEN 9
	NOTE D_, 3
	LEN 18
	NOTE D_, 3
	LEN 9
	NOTE D_, 3
	LEN 18
	NOTE C_, 3
	LEN 9
	NOTE A_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE F_, 2
	LENGTH $36
	NOTE G_, 2
	LEN 9
	NOTE Ash, 2
	LEN 18
	NOTE Ash, 2
	LEN 9
	NOTE Ash, 2
	LEN 18
	NOTE A_, 2
	LEN 9
	NOTE F_, 2
	NOTE G_, 2
	NOTE D_, 2
	NOTE C_, 2
	NEXT
Pat_6F8E:
	LEN 18
	REPEAT 5
	NOTE D_, 2
	NOTE D_, 2
	LEN 27
	NOTE F_, 2
	NOTE D_, 2
	LEN 18
	NOTE D_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE G_, 2
	LEN 27
	NOTE Ash, 2
	NOTE G_, 2
	LEN 18
	NOTE G_, 2
	NOTE Ash, 2
	NOTE G_, 2
	REPEAT_END
	NEXT
Pat_6FA4:
	NOTE Ash, 2
	NOTE Ash, 2
	LEN 27
	NOTE D_, 3
	NOTE Ash, 2
	LEN 18
	NOTE Ash, 2
	NOTE D_, 3
	NOTE Ash, 2
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	LEN 9
	NOTE C_, 3
	NOTE C_, 3
	WAIT2
	NOTE C_, 3
	LEN 18
	NOTE A_, 2
	NOTE G_, 2
	NOTE F_, 2
	NEXT
Pat_6FBA:
	LEN 18
	REPEAT 2
	PAT_GOTO Pat_6FC0
Pat_6FBF:
	REPEAT 5
Pat_6FC0:
	INSTR 0
	NOTE D_, 4
	INSTR 2
	NOTE D_, 4
	INSTR 0
	NOTE E_, 4
	INSTR 2
	NOTE D_, 4
	INSTR 0
	NOTE F_, 4
	INSTR 2
	NOTE D_, 4
	INSTR 0
	NOTE E_, 4
	INSTR 2
	NOTE D_, 4
	INSTR 0
	NOTE G_, 4
	INSTR 2
	NOTE G_, 4
	INSTR 0
	NOTE A_, 4
	INSTR 2
	NOTE G_, 4
	INSTR 0
	NOTE Ash, 4
	INSTR 2
	NOTE G_, 4
	INSTR 0
	NOTE A_, 4
	INSTR 2
	NOTE G_, 4
	REPEAT_END
	NEXT
Pat_6FE2:
	INSTR 0
	NOTE Ash, 3
	INSTR 1
	NOTE Ash, 4
	INSTR 0
	NOTE C_, 4
	INSTR 1
	NOTE Ash, 4
	INSTR 0
	NOTE D_, 4
	INSTR 1
	NOTE Ash, 4
	INSTR 0
	NOTE Ash, 3
	INSTR 1
	NOTE Ash, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	LEN 9
	NOTE C_, 5
	NOTE C_, 5
	WAIT2
	INSTR 0
	NOTE C_, 4
	LEN 18
	NOTE A_, 3
	NOTE G_, 3
	INSTR 1
	NOTE F_, 4
	NEXT
Pat_7001:
	DRUMS $09, DrumPat_7084
	WAVE Wave_7A1E
	VOLENV 10, $14, $1F, $1F
	VIBRATO $09, $01, $05
	RELEASE $05, $01
	LENGTH $90
	REST
	REST
	REST
	REST
	NEXT
Pat_701A:
	LEN 9
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 27
	NOTE A_, 4
	LEN 9
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 27
	NOTE A_, 3
	LEN 18
	NOTE D_, 4
	LEN 4
	NOTE C_, 4
	LEN 23
	NOTE D_, 4
	LEN 27
	NOTE C_, 4
	LEN 18
	NOTE Ash, 3
	NOTE F_, 3
	NOTE G_, 3
	LEN 9
	NOTE A_, 3
	NOTE G_, 3
	LEN 18
	NOTE A_, 3
	LEN 9
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 27
	NOTE A_, 4
	LEN 9
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE A_, 3
	LEN 18
	NOTE D_, 4
	LEN 9
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	LEN 18
	NOTE D_, 5
	NOTE C_, 5
	LEN 9
	NOTE Ash, 4
	NOTE G_, 4
	LEN 18
	NOTE F_, 4
	NEXT
Pat_705D:
	LENGTH $36
	NOTE D_, 4
	LENGTH $AB
	WAIT2
	LEN 9
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE A_, 4
	LENGTH $36
	NOTE F_, 4
	LEN 18
	NOTE D_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 9
	NOTE A_, 4
	NOTE G_, 4
	LEN 18
	NOTE F_, 4
	LENGTH $3F
	NOTE G_, 4
	NOTE A_, 4
	LEN 9
	NOTE D_, 4
	NOTE E_, 4
	ARP 0
	DRUMS $09, DrumPat_708A
	NEXT
DrumPat_7084:
	db DRUM_LEVEL + 14, 1, 0, 6, 0, DRUM_LOOP
DrumPat_708A:
	db DRUM_LEVEL + 14, 1, 6, 6, 0, 2, 0, 4
	db 6, 1, 6, 6, 6, 2, 0, 4
	db 0, DRUM_LOOP

; Song 15: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong15:
	ld a, $74
	ld [wInstrTableHi], a
	ld a, $36
	ld [wInstrTable], a
	ld de, Song15_Ch1
	call StartMusicCh1
	ld de, Song15_Ch2
	call StartMusicCh2
	ld de, Song15_Ch3
	jp StartMusicCh3
Song15_Ch1:
	dw Pat_70BE
Song15_Ch2:
	dw Pat_70D8
Song15_Ch3:
	dw Pat_70D7
Pat_70BE:
	LEN 8
	HWENV $F2, $04, $87
	RELEASE $02, $51
	ARP 0
	DUTY_50
	DRUMS $08, DrumPat_70EC
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	WAIT
	NOTE F_, 2
	WAIT
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	DRUMS_OFF
	END
Pat_70D7:
	END
Pat_70D8:
	LEN 8
	HWENV $F2, $04, $87
	RELEASE $02, $51
	ARP 5
	DUTY_50
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE G_, 4
	NOTE D_, 4
	WAIT
	END
DrumPat_70EC:
	db 1, 6, 6, 0, 7, 0, 1, 7           ; no DRUM_LOOP: the pattern runs into the next data
	db 0, 0, 0, 0

; Song 16: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong16:
	ld a, $74
	ld [wInstrTableHi], a
	ld a, $36
	ld [wInstrTable], a
	ld de, Song16_Ch1
	call StartMusicCh1
	ld de, Song16_Ch2
	call StartMusicCh2
	ld de, Song16_Ch3
	jp StartMusicCh3

; Unreferenced (1 bytes)
	db $C9
Song16_Ch1:
	dw Pat_713F
Loop_7117:
	dw Pat_718A
	dw Pat_718A
	dw Pat_71EF
	dw Pat_71EF
	ORDER_LOOP Loop_7117
Song16_Ch3:
	dw Pat_7250
Loop_7125:
	dw Pat_729E
	dw Pat_729E
	dw Pat_7300
	dw Pat_7300
	ORDER_LOOP Loop_7125
Song16_Ch2:
	dw Pat_7361
Loop_7133:
	dw Pat_73B1
	dw Pat_73B1
	dw Pat_73F7
	dw Pat_73F7
	ORDER_LOOP Loop_7133
Pat_713F:
	LEN 11
	DUTY_50
	RELEASE $02, $01
	VIBRATO $0B, $04, $05
	INSTR 12
	NOTE D_, 2
	WAIT
	WAIT
	NOTE G_, 2
	NOTE G_, 2
	WAIT
	WAIT
	NOTE A_, 2
	WAIT
	WAIT
	WAIT
	NOTE A_, 2
	NOTE G_, 2
	WAIT
	NOTE A_, 2
	WAIT
	NOTE D_, 2
	WAIT
	WAIT
	NOTE G_, 2
	NOTE G_, 2
	WAIT
	WAIT
	NOTE A_, 2
	WAIT
	WAIT
	WAIT
	NOTE A_, 2
	NOTE G_, 2
	WAIT
	NOTE A_, 2
	WAIT
	NOTE D_, 2
	WAIT
	WAIT
	NOTE G_, 2
	NOTE G_, 2
	WAIT
	WAIT
	NOTE A_, 2
	WAIT
	WAIT
	WAIT
	NOTE A_, 2
	NOTE G_, 2
	WAIT
	NOTE A_, 2
	WAIT
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	WAIT
	WAIT
	WAIT
	NEXT
Pat_718A:
	DRUMS $0B, DrumPat_74A2
	NOTE D_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE D_, 3
	NOTE D_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE D_, 3
	NOTE D_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE D_, 3
	NOTE D_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE Gsh, 2
	NOTE A_, 2
	NOTE B_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE Gsh, 2
	NOTE A_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	WAIT
	NOTE A_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	NOTE D_, 3
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE D_, 3
	WAIT
	NOTE D_, 3
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE D_, 3
	NOTE Ash, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE Ash, 2
	WAIT
	NOTE Ash, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE Ash, 2
	NOTE A_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	WAIT
	NOTE A_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	NEXT
Pat_71EF:
	NOTE D_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE D_, 2
	NOTE A_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	WAIT
	NOTE A_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	NOTE B_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE B_, 2
	WAIT
	NOTE B_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE B_, 2
	NOTE A_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	WAIT
	NOTE A_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	NOTE G_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE E_, 2
	NOTE F_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE F_, 2
	NOTE E_, 2
	WAIT
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	WAIT
	NOTE A_, 2
	INSTR 11
	NOTE F_, 3
	INSTR 12
	NOTE A_, 2
	NEXT
Pat_7250:
	LEN 11
	WAVE Wave_7A5E
	ARP 0
	VOLENV 15, $11, $1F, $11
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE E_, 4
	WAIT
	NOTE Csh, 4
	WAIT
	NOTE E_, 4
	NOTE D_, 4
	WAIT
	NOTE Csh, 4
	WAIT
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE E_, 4
	WAIT
	NOTE Csh, 4
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE D_, 3
	NOTE Fsh, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE E_, 4
	WAIT
	NOTE Csh, 4
	WAIT
	NOTE E_, 4
	NOTE D_, 4
	WAIT
	NOTE Csh, 4
	WAIT
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE A_, 4
	WAIT
	ARP_OFF
	GLIDE $FE
	NOTE A_, 3
	NOTE A_, 3
	GLIDE_OFF
	NEXT
Pat_729E:
	ARP 0
	NOTE D_, 3
	NOTE D_, 4
	ARP 4
	NOTE D_, 4
	ARP 0
	NOTE D_, 4
	NOTE D_, 3
	NOTE D_, 4
	ARP 4
	NOTE D_, 4
	ARP 0
	NOTE D_, 4
	NOTE D_, 3
	NOTE D_, 4
	ARP 4
	NOTE D_, 4
	ARP 0
	NOTE D_, 4
	NOTE D_, 3
	NOTE D_, 4
	ARP 4
	NOTE D_, 4
	ARP 0
	NOTE D_, 4
	NOTE D_, 3
	NOTE D_, 4
	ARP 4
	NOTE D_, 4
	ARP 0
	NOTE D_, 4
	NOTE D_, 3
	NOTE D_, 4
	ARP 4
	NOTE D_, 4
	ARP 0
	NOTE D_, 4
	NOTE D_, 3
	NOTE D_, 4
	ARP 4
	NOTE D_, 4
	ARP 0
	NOTE Gsh, 3
	NOTE A_, 3
	NOTE B_, 3
	ARP 4
	NOTE E_, 4
	ARP 0
	NOTE E_, 4
	NOTE A_, 3
	NOTE A_, 4
	ARP 4
	NOTE A_, 4
	ARP 0
	NOTE A_, 4
	NOTE A_, 3
	NOTE A_, 4
	ARP 4
	NOTE A_, 4
	ARP 0
	NOTE A_, 4
	NOTE D_, 4
	NOTE D_, 5
	ARP 4
	NOTE D_, 5
	ARP 0
	NOTE D_, 5
	NOTE D_, 4
	NOTE D_, 5
	ARP 4
	NOTE D_, 5
	ARP 0
	NOTE D_, 5
	NOTE Ash, 3
	NOTE Ash, 4
	ARP 4
	NOTE Ash, 4
	ARP 0
	NOTE Ash, 4
	NOTE Ash, 3
	NOTE Ash, 4
	ARP 4
	NOTE Ash, 4
	ARP 0
	NOTE Ash, 4
	NOTE A_, 3
	NOTE A_, 4
	ARP 4
	NOTE A_, 4
	ARP 0
	NOTE A_, 4
	NOTE A_, 3
	NOTE A_, 4
	ARP 4
	NOTE A_, 4
	ARP 0
	NOTE A_, 4
	NEXT
Pat_7300:
	NOTE D_, 3
	NOTE D_, 4
	ARP 4
	NOTE D_, 4
	ARP 0
	NOTE D_, 4
	NOTE D_, 3
	NOTE D_, 4
	ARP 4
	NOTE D_, 4
	ARP 0
	NOTE D_, 4
	NOTE A_, 3
	NOTE A_, 4
	ARP 4
	NOTE A_, 4
	ARP 0
	NOTE A_, 4
	NOTE A_, 3
	NOTE A_, 4
	ARP 4
	NOTE A_, 4
	ARP 0
	NOTE A_, 4
	NOTE B_, 3
	NOTE B_, 4
	ARP 5
	NOTE B_, 4
	ARP 0
	NOTE B_, 4
	NOTE B_, 3
	NOTE B_, 4
	ARP 5
	NOTE B_, 4
	ARP 0
	NOTE B_, 4
	NOTE A_, 3
	NOTE A_, 4
	ARP 4
	NOTE A_, 4
	ARP 0
	NOTE A_, 4
	NOTE A_, 3
	NOTE A_, 4
	ARP 4
	NOTE A_, 4
	ARP 0
	NOTE A_, 4
	NOTE G_, 3
	NOTE G_, 4
	ARP 4
	NOTE G_, 4
	ARP 0
	NOTE G_, 4
	NOTE G_, 3
	NOTE G_, 4
	ARP 4
	NOTE G_, 4
	ARP 0
	NOTE G_, 4
	NOTE D_, 3
	NOTE D_, 4
	ARP 4
	NOTE D_, 4
	ARP 0
	NOTE D_, 4
	NOTE D_, 3
	NOTE D_, 4
	ARP 4
	NOTE D_, 4
	ARP 0
	NOTE E_, 4
	NOTE F_, 3
	NOTE F_, 4
	ARP 4
	NOTE F_, 4
	ARP 0
	NOTE F_, 4
	NOTE F_, 3
	NOTE F_, 4
	ARP 4
	NOTE F_, 4
	ARP 0
	NOTE F_, 4
	NOTE E_, 3
	NOTE E_, 4
	ARP 4
	NOTE G_, 4
	ARP 0
	NOTE E_, 4
	NOTE A_, 3
	NOTE A_, 4
	ARP 4
	NOTE A_, 4
	ARP 0
	NOTE A_, 4
	NEXT
Pat_7361:
	HWENV $F1, $02, $D3
	DUTY_75
	LEN 11
	VIBRATO $0B, $01, $05
	ARP 4
	NOTE D_, 4
	WAIT
	WAIT
	NOTE G_, 4
	NOTE G_, 4
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	NOTE G_, 4
	NOTE G_, 4
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	NOTE G_, 4
	NOTE G_, 4
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	ARP 0
	HWENV $F1, $00
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE A_, 3
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	NEXT
Pat_73B1:
	WAIT
	WAIT
	HWENV $F1, $04, $D7
	ARP 0
	NOTE D_, 5
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE D_, 5
	WAIT
	WAIT
	WAIT
	NOTE D_, 5
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE Gsh, 4
	NOTE A_, 4
	NOTE B_, 4
	WAIT
	WAIT
	NOTE Csh, 5
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Csh, 5
	NOTE D_, 5
	NOTE E_, 5
	NOTE Fsh, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE D_, 5
	NOTE A_, 4
	WAIT
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE Fsh, 5
	WAIT
	NOTE E_, 5
	NOTE D_, 5
	WAIT
	NOTE E_, 5
	WAIT
	WAIT
	NEXT
Pat_73F7:
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	NOTE Fsh, 4
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	NOTE Csh, 4
	WAIT
	NOTE A_, 3
	WAIT
	NOTE B_, 3
	NOTE Csh, 4
	NOTE D_, 4
	WAIT
	NOTE B_, 3
	WAIT
	NOTE Csh, 4
	NOTE D_, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	NOTE Csh, 4
	NOTE A_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE B_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE Csh, 5
	NOTE B_, 4
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE Csh, 4
	NOTE D_, 4
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	NOTE Fsh, 4
	NEXT

; Instrument table 4, entries 1..13 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr4_0
	dw Instr4_1
	dw Instr4_2
	dw Instr4_3
	dw Instr4_4
	dw Instr4_5
	dw Instr4_6
	dw Instr4_7
	dw Instr4_8
	dw Instr4_9
	dw Instr4_10
	dw Instr4_11
	dw Instr4_12
Instr4_0:
	HWENV $F2, $04, $61
	DUTY_12
	ARP 0
	END
Instr4_1:
	HWENV $F0, $03, $A2
	ARP 4
	DUTY_75
	END
Instr4_2:
	HWENV $F0, $03, $A2
	ARP 5
	DUTY_75
	END
Instr4_3:
	ARP 17
	WAVE Wave_7B4E
	END
Instr4_4:
	ARP 18
	WAVE Wave_7B4E
	END
Instr4_5:
	ARP 19
	WAVE Wave_7B4E
	END
Instr4_6:
	HWENV $F2, $04, $A2
	DUTY_50
	ARP 0
	END
Instr4_7:
	ARP_OFF
	WAVE Wave_7ADE
	END
Instr4_8:
	HWENV $F0, $04, $51
	DUTY_50
	GLIDE $FE
	END
Instr4_9:
	HWENV $F1, $00
	DUTY_75
	ARP 0
	END
Instr4_10:
	HWENV $F3, $00
	DUTY_50
	ARP 0
	END
Instr4_11:
	HWENV $F1, $00
	GLIDE $FF
	END
Instr4_12:
	HWENV $F2, $04, $C4
	ARP 0
	END
DrumPat_74A2:
	db DRUM_LEVEL + 15, 6, DRUM_LEVEL + 13, 6, DRUM_LEVEL + 15, 9, DRUM_LEVEL + 13, 6
	db DRUM_LOOP
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
	db $71, $75, $74, $75, $77, $75, $7B, $75, $7F, $75, $87, $75, $8E, $75, $94, $75
Arp0:
	db $0C, $00, ARP_HOLD
Arp1:
	db $00, $00, $01, $01, $02, ARP_HOLD
Arp2:
	db $0E, $00, $01, $02, ARP_HOLD
Arp3:
	db $0D, $0E, $01, $02, ARP_HOLD
Arp4:
	db $00, $04, $07, ARP_LOOP
Arp5:
	db $00, $03, $07, ARP_LOOP
Arp6:
	db $00, $04, $07, ARP_LOOP
Arp7:
	db $00, $03, $07, ARP_LOOP
Arp8:
	db $00, $00, $04, $04, $07, $07, ARP_LOOP
Arp9:
	db $00, $00, $03, $03, $07, $07, ARP_LOOP
Arp10:
	db $07, $0C, $04, $00, ARP_HOLD
Arp11:
	db $00, $0C, $0C, $00, ARP_HOLD
Arp12:
	db $18, $0C, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $18, $00, $00
	db ARP_HOLD
Arp13:
	db $18, $0C, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $24, $00, ARP_HOLD
Arp14:
	db $0C, $0C, $00, $00, ARP_LOOP
Arp15:
	db $00, $00, $00, $01, ARP_HOLD
Arp16:
	db $0C, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $18, $0C, $0C, $0C, $0C
	db $0C, $0C, $0C, $0C, $0C, $0C, ARP_LOOP
Arp17:
	db $0C, $07, $00, ARP_LOOP
Arp18:
	db $0C, $09, $00, ARP_LOOP
Arp19:
	db $0C, $08, $00, ARP_LOOP

; Unreferenced (38 bytes)
	db $00, $0C, $6A, $00, $01, $6A, $00, $0C, $00, $FF, $18, $0C, $00, $FF, $0C, $00
	db $00, $00, $00, $00, $00, $6A, $00, $0C, $04, $10, $07, $13, $6A, $0E, $00, $01
	db $01, $02, $FF, $0C
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
	dw Sfx29

; Sound effect 29
Sfx29:
	VOLENV 15, $00, $1F, $11
	ARP 0
	WAVE Wave_7A4E
	LEN 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	CH_TRANSPOSE $06
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	CH_TRANSPOSE $0E
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	CH_TRANSPOSE $15
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	VOLENV 10, $00, $1F, $11
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	VOLENV 5, $00, $1F, $11
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	END

; Sound effect 28
Sfx28:
	LEN 4
	VOLENV 15, $11, $1F, $13
	WAVE Wave_7B1E
	ARP 4
	CH_TRANSPOSE $04
	NOTE C_, 5
	REST
	REST
	NOTE C_, 5
	NOTE C_, 5
	REST
	NOTE D_, 5
	REST
	NOTE C_, 5
	REST
	NOTE D_, 5
	REST
	NOTE E_, 5
	WAIT
	WAIT
	WAIT
	GLIDE $FF
	WAIT
	WAIT
	WAIT
	WAIT
	END

; Sound effect 27
Sfx27:
	LEN 26
	VOLENV 15, $11, $1F, $13
	WAVE Wave_7A4E
	ARP 27
	GLIDE $02
	NOTE C_, 3
	END

; Sound effect 26
Sfx26:
	LEN 3
	VOLENV 15, $11, $1F, $11
	WAVE Wave_7A4E
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	VOLENV 5, $00, $00, $00
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE C_, 6
	END

; Sound effect 1
Sfx01:
	VOLENV 15, $11, $2F, $11
	WAVE Wave_7A5E
	LEN 13
	NOTE C_, 6
	END

; Sound effect 2
Sfx02:
	LEN 4
	VOLENV 15, $11, $2F, $11
	WAVE Wave_7A5E
	LEN 4
	NOTE Gsh, 5
	LEN 1
	REST
	LEN 4
	NOTE Gsh, 6
	END

; Sound effect 3
Sfx03:
	CALL_CODE Code_7982
	END

; Sound effect 4
Sfx04:
	LEN 8
	VOLENV 15, $10, $1F, $11
	GLIDE $01
	WAVE Wave_7A4E
	NOTE A_, 3
	END

; Sound effect 5
Sfx05:
	CALL_CODE Code_77D1
	END

; Sound effect 6
Sfx06:
	LEN 8
	CALL_CODE Code_77AF
	REST
	CALL_CODE Code_77AF
	REST
	CALL_CODE Code_77AF
	REST
	CALL_CODE Code_77D1
	REST
	END

; Sound effect 7
Sfx07:
	LEN 5
	VOLENV 15, $00, $00, $00
	WAVE Wave_7A4E
	CALL_CODE Code_777E
	GLIDE $03
	NOTE A_, 2
	GLIDE $FC
	WAIT
	END

; Sound effect 8
Sfx08:
	LEN 6
	VOLENV 15, $11, $1F, $13
	WAVE Wave_7B3E
	CALL_CODE Code_777E
	GLIDE $06
	NOTE E_, 3
	GLIDE $FF
	WAIT
	WAIT
	END

; Sound effect 9
Sfx09:
	VOLENV 10, $11, $1F, $12
	WAVE Wave_7A4E
	LEN 13
	SLIDE_DOWN $03
	NOTE A_, 5
	END

; Sound effect 10
Sfx10:
	VOLENV 15, $11, $1F, $11
	CALL_CODE Code_78A1
	WAVE Wave_7A4E
	LEN 12
	GLIDE $FE
	NOTE C_, 3
	END

; Sound effect 11
Sfx11:
	VOLENV 15, $00, $00, $00
	WAVE Wave_7ACE
	LEN 6
	GLIDE $01
	NOTE C_, 6
	REST
	NOTE G_, 6
	END

; Sound effect 12
Sfx12:
	VOLENV 15, $00, $00, $00
	WAVE Wave_7AFE
	LEN 5
	NOTE A_, 3
	LEN 3
	REST
	LEN 20
	NOTE A_, 3
	END

; Sound effect 13
Sfx13:
	CALL_CODE Code_77AF
	END

; Sound effect 14
Sfx14:
	LEN 8
	VOLENV 15, $10, $1F, $11
	GLIDE $01
	WAVE Wave_7A4E
	NOTE D_, 4
	REST
	LEN 4
	CALL_CODE Code_78A1
	REST
	CALL_CODE Code_7955
	END

; Sound effect 15
Sfx15:
	CALL_CODE Code_780D
	END

; Sound effect 16
Sfx16:
	CALL_CODE Code_79F1
	END

; Sound effect 17
Sfx17:
	CALL_CODE Code_78D2
	END

; Sound effect 18
Sfx18:
	VOLENV 10, $00, $00, $00
	GLIDE $FC
	WAVE Wave_7A7E
	CALL_CODE Code_77AF
	LEN 5
	NOTE A_, 6
	END

; Sound effect 19
Sfx19:
	CALL_CODE Code_7955
	END

; Sound effect 20
Sfx20:
	LEN 2
	VOLENV 15, $11, $1F, $11
	WAVE Wave_7A4E
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

; Sound effect 21
Sfx21:
	VOLENV 15, $11, $23, $11
	LEN 5
	ARP 11
	WAVE Wave_7A6E
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

; Sound effect 22
Sfx22:
	LEN 8
	VOLENV 15, $11, $1F, $12
	WAVE Wave_7A4E
	GLIDE $02
	NOTE A_, 3
	GLIDE $02
	NOTE C_, 4
	GLIDE $02
	NOTE E_, 4
	GLIDE $02
	NOTE G_, 4
	GLIDE $02
	NOTE B_, 4
	END

; Sound effect 23
Sfx23:
	CALL_CODE Code_78FB
	END

; Sound effect 24
Sfx24:
	LEN 10
	CALL_CODE Code_77AF
	REST
	CALL_CODE Code_7928
	END

; Sound effect 25
Sfx25:
	LEN 5
	ARP 0
	WAVE Wave_7ACE
	VOLENV 15, $10, $1F, $12
	RELEASE $02, $55
	NOTE C_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	END
Code_777E:
	ld a, $08
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_77A0)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_77A0)
	ld [wNoise43], a
	ld a, HIGH(Noise42_77A8)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_77A8)
	ld [wNoise42], a
	ret
Noise43_77A0:
	db $60, $52, $42, $41, $22, $11, $21, $FF
Noise42_77A8:
	db $F0, $F0, $F0, $F0, $F0, $F0, $61
Code_77AF:
	ld a, $0A
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_77F3)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_77F3)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7805)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7805)
	ld [wNoise42], a
	ret
Code_77D1:
	ld a, $0A
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_77FC)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_77FC)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7805)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7805)
	ld [wNoise42], a
	ret
Noise43_77F3:
	db $10, $10, $20, $31, $33, $34, $35, $36
	db $FF
Noise43_77FC:
	db $36, $35, $34, $33, $31, $20, $10, $10
	db $FF
Noise42_7805:
	db $C1, $FF, $FF, $FF, $FF, $FF, $FF, $FF
Code_780D:
	ld a, $0A
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_782F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_782F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_783B)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_783B)
	ld [wNoise42], a
	ret
Noise43_782F:
	db $A0, $A0, $A0, $A0, $A0, $A0, $A0, $A0
	db $A0, $A0, $A0, $FF
Noise42_783B:
	db $F0, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $FF, $00

; Unreferenced (91 bytes)
	db $3E, $32, $EA, $9B, $C1, $AF, $EA, $AF, $C1, $3C, $EA, $B0, $C1, $3E, $78, $EA
	db $AB, $C1, $3E, $68, $EA, $AC, $C1, $3E, $78, $EA, $AD, $C1, $3E, $85, $EA, $AE
	db $C1, $C9, $20, $30, $30, $30, $32, $42, $42, $42, $42, $42, $20, $30, $30, $30
	db $32, $42, $42, $42, $42, $42, $42, $42, $42, $22, $82, $81, $80, $54, $FF, $F0
	db $FF, $55, $00, $B2, $FF, $FF, $FF, $FF, $FF, $F0, $FF, $55, $00, $B2, $FF, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $F0, $FF, $FF, $FF, $F4
Code_78A1:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_78C3)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_78C3)
	ld [wNoise43], a
	ld a, HIGH(Noise42_78CB)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_78CB)
	ld [wNoise42], a
	ret
Noise43_78C3:
	db $02, $51, $61, $71, $91, $71, $60, $FF
Noise42_78CB:
	db $F0, $F0, $F0, $F0, $F0, $70, $63
Code_78D2:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_78F4)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_78F4)
	ld [wNoise43], a
	ld a, HIGH(Noise42_78F8)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_78F8)
	ld [wNoise42], a
	ret
Noise43_78F4:
	db $02, $51, $11, $FF
Noise42_78F8:
	db $F0, $A0, $55
Code_78FB:
	ld a, $0F
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_791D)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_791D)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7923)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7923)
	ld [wNoise42], a
	ret
Noise43_791D:
	db $02, $41, $61, $71, $11, $FF
Noise42_7923:
	db $F0, $FF, $FF, $A0, $B2
Code_7928:
	ld a, $08
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_794A)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_794A)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7950)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7950)
	ld [wNoise42], a
	ret
Noise43_794A:
	db $00, $83, $60, $60, $31, $FF
Noise42_7950:
	db $F0, $FF, $FF, $FF, $D1
Code_7955:
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7977)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7977)
	ld [wNoise43], a
	ld a, HIGH(Noise42_797D)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_797D)
	ld [wNoise42], a
	ret
Noise43_7977:
	db $00, $53, $71, $91, $31, $FF
Noise42_797D:
	db $F1, $FF, $FF, $FF, $00
Code_7982:
	ld a, $04
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_79A4)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_79A4)
	ld [wNoise43], a
	ld a, HIGH(Noise42_79AB)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_79AB)
	ld [wNoise42], a
	ret
Noise43_79A4:
	db $41, $61, $61, $41, $71, $71, $FF
Noise42_79AB:
	db $A1, $52, $00, $61, $52, $00

; Unreferenced (64 bytes)
	db $3E, $32, $EA, $9B, $C1, $AF, $EA, $AF, $C1, $3C, $EA, $B0, $C1, $3E, $02, $EA
	db $B3, $C1, $AF, $EA, $B2, $C1, $3E, $79, $EA, $AB, $C1, $3E, $DC, $EA, $AC, $C1
	db $3E, $79, $EA, $AD, $C1, $3E, $E7, $EA, $AE, $C1, $C9, $27, $26, $25, $14, $13
	db $12, $11, $10, $10, $10, $FF, $19, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $F3
Code_79F1:
	ld a, $19
	ld [wDrumHold], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7A13)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7A13)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7A19)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7A19)
	ld [wNoise42], a
	ret
Noise43_7A13:
	db $03, $83, $80, $80, $51, $FF
Noise42_7A19:
	db $F0, $FF, $FF, $FF, $F2
Wave_7A1E:
	db $01, $11, $11, $00, $89, $AA, $AA, $98
	db $01, $11, $11, $00, $FF, $FF, $FF, $FF
Wave_7A2E:
	db $A8, $40, $04, $8A, $FF, $FF, $FF, $FF
	db $A8, $40, $04, $8A, $FF, $FF, $FF, $FF

; Unreferenced (16 bytes)
	db $00, $46, $8A, $FF, $FF, $A8, $64, $00, $00, $46, $8A, $FF, $FF, $A8, $64, $00
Wave_7A4E:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
Wave_7A5E:
	db $00, $00, $00, $00, $CD, $EF, $FD, $EC
	db $00, $12, $21, $00, $DD, $DD, $DD, $DD
Wave_7A6E:
	db $00, $00, $00, $00, $00, $00, $FF, $FF
	db $00, $00, $00, $00, $00, $00, $FF, $FF
Wave_7A7E:
	db $00, $00, $00, $00, $00, $00, $FF, $00
	db $00, $00, $00, $00, $00, $00, $FF, $00

; Unreferenced (16 bytes)
	db $00, $00, $00, $CD, $EF, $FF, $FF, $FF, $04, $8C, $FF, $FF, $FF, $FF, $FF, $FF
Wave_7A9E:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $00, $FF, $FF, $FF

; Unreferenced (32 bytes)
	db $12, $34, $56, $78, $9A, $BC, $DE, $FF, $ED, $CB, $A9, $87, $65, $43, $21, $00
	db $63, $10, $00, $00, $00, $00, $01, $36, $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9
Wave_7ACE:
	db $63, $10, $01, $47, $74, $10, $01, $36
	db $9C, $EF, $FE, $B8, $8B, $EF, $FE, $C9
Wave_7ADE:
	db $63, $20, $02, $47, $74, $22, $22, $36
	db $9C, $EF, $FE, $B6, $6B, $EE, $EE, $C9
Wave_7AEE:
	db $B7, $40, $04, $7B, $CD, $FF, $FE, $DC
	db $02, $46, $8A, $BD, $FD, $BA, $64, $20
Wave_7AFE:
	db $0F, $00, $F0, $F0, $F0, $F0, $00, $0F
	db $0F, $FF, $FF, $00, $FF, $F0, $0F, $0F
Wave_7B0E:
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $ED, $CB, $A9, $87, $65, $43, $21, $00
Wave_7B1E:
	db $FE, $DB, $97, $53, $13, $54, $32, $10
	db $FE, $DC, $BC, $EF, $DB, $85, $32, $10

; Unreferenced (16 bytes)
	db $20, $13, $69, $BD, $FD, $B9, $64, $20, $13, $68, $B8, $64, $20, $24, $68, $64
Wave_7B3E:
	db $20, $24, $68, $AC, $EC, $A8, $64, $20
	db $24, $68, $A8, $64, $20, $24, $68, $64
Wave_7B4E:
	db $02, $48, $AC, $FF, $FC, $53, $00, $27
	db $9C, $DD, $DC, $B7, $7B, $CD, $DD, $C9
Noise43_7B5E:
	db $02, $51, $61, $71, $91, $71, $60, $FF
Noise42_7B66:
	db $F0, $F0, $D0, $90, $70, $40, $31
Noise43_7B6D:
	db $06, $04, $03, $03, $07, $FF
Noise42_7B73:
	db $F0, $C0, $80, $60, $55
Noise43_7B78:
	db $04, $02, $01, $01, $FF
Noise42_7B7D:
	db $80, $40, $30, $23
Noise43_7B81:
	db $04, $02, $01, $01, $04, $02, $01, $FF
Noise42_7B89:
	db $A0, $60, $33, $23, $A0, $60, $33
Noise43_7B90:
	db $04, $02, $06, $06, $FF
Noise42_7B95:
	db $C0, $80, $60, $44
Noise43_7B99:
	db $50, $41, $50, $51, $42, $53, $51, $FF
Noise42_7BA1:
	db $F0, $70, $F0, $70, $D0, $70, $61

; Unreferenced (8 bytes)
	db $3E, $08, $EA, $9B, $C1, $CD, $96, $49
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B5E)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B5E)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B66)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B66)
	ld [wNoise42], a
	ret
Drum8:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7BEA)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7BEA)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7BF0)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7BF0)
	ld [wNoise42], a
	ret
Noise43_7BEA:
	db $04, $02, $01, $00, $00, $FF
Noise42_7BF0:
	db $40, $60, $70, $82, $71
Drum2:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7C12)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7C12)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7C1A)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7C1A)
	ld [wNoise42], a
	ret
Noise43_7C12:
	db $60, $52, $42, $41, $22, $11, $04, $FF
Noise42_7C1A:
	db $F0, $F0, $F0, $A0, $70, $40, $51
Drum3:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B99)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B99)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7BA1)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7BA1)
	ld [wNoise42], a
	ret
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B90)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B90)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B95)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B95)
	ld [wNoise42], a
	ret
Drum5:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B81)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B81)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B89)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B89)
	ld [wNoise42], a
	ret
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B78)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B78)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B7D)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B7D)
	ld [wNoise42], a
	ret
Drum7:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7B6D)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7B6D)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7B73)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7B73)
	ld [wNoise42], a
	ret
Drum9:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7CCF)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7CCF)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7CD2)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7CD2)
	ld [wNoise42], a
	ret
Noise43_7CCF:
	db $51, $32, $FF
Noise42_7CD2:
	db $F0, $72
Drum10:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7D0E)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7D0E)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7D11)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7D11)
	ld [wNoise42], a
	ret
Drum11:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7D13)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7D13)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7D1B)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7D1B)
	ld [wNoise42], a
	ret
Noise43_7D0E:
	db $51, $32, $FF
Noise42_7D11:
	db $90, $61
Noise43_7D13:
	db $51, $32, $32, $32, $32, $51, $32, $FF
Noise42_7D1B:
	db $80, $51, $FF, $FF, $FF, $80, $51
FadeOutTable:
	db $77, $66, $55, $44, $33, $22, $11, $00
	db FADE_END
FadeInTable:
	db $00, $11, $22, $33, $44, $55, $66, $77
	db FADE_END

; Unreferenced (716 bytes)
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
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
