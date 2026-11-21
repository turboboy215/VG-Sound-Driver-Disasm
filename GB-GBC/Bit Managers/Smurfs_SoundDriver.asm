; =====================================================================
; The Smurfs (UE) (V1.0) (M4) - Game Boy
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4 (reference)
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o smurfs.o Smurfs_SoundDriver.asm
;   rgblink -o smurfs.gb smurfs.o
;   python tools/cmp_banked.py smurfs.gb "Smurfs, The (UE) (V1.0) (M4) [!].gb" 6:4000-7FFF
; (driver and data fill ROM bank 6; the linked file only matches in that range)
;
; Documentation: Smurfs_SoundDriver.md / AJG_SoundEngine_Family.md
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
MACRO REPEAT    ; play the following bytes n times (up to REPEAT_END), n = 2-24
	db $E7 + \1
ENDM
MACRO LEN       ; note length in ticks, 1-48
	db $B8 + \1
ENDM
MACRO VOLENV    ; start volume + envelope (CH3/SFX): atk (lo=count hi=step), dec (lo=count hi=step), rates (hi=atk lo=dec)
	db $A9 + \1, \2, \3, \4
ENDM
MACRO INSTR     ; instrument n = entry n + 1 of the current instrument table
	db $84 + \1
ENDM
MACRO ARP       ; arpeggio n of the current arpeggio table
	db $8E + \1
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
DEF DRUM_TEMPO EQU $B8         ; + n: one step every n ticks
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


; Entry points (jump table at the start of the bank). The game calls these with the
; bank switched in: SndUpdate, SndPause, SndResume, StopAll, PlaySfx (A = id), SndInit,
; SongFadeIn, SongFadeOut (A = speed), then one entry per song.
SndAPI:
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
	jp PlaySong15                      ; song 15
	jp PlaySong16                      ; song 16
	jp PlaySong17                      ; song 17
	jp PlaySong18                      ; song 18
	jp PlaySong19                      ; song 19

; Not reached: an older copy of the game's PlaySfx glue (ids $1E-$20 -> noise
; routines), the same bytes as the live copy in the data area.
Unused_OldSfxGlue:
	db $FE, $1E, $CA, $7A, $79, $FE, $1F, $CA, $8B, $7A, $FE, $20, $CA, $10, $79, $C3
	db $1D, $49

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
	add a, $66
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
	sub $E7
	ld l, $39
	ld [hli], a
	ld [hl], e
	inc l
	ld [hl], d
	jr ReadByte

; StreamCommand: REPEAT / LEN / VOLENV / ARP / INSTR ranges, else CmdTable.
StreamCommand:
	cp $E9
	jr nc, Cmd_Repeat
	cp $B9
	jr nc, Cmd_Len
	cp $A9
	jr nc, Cmd_VolEnv
	cp $8E
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
	sub $B8
	ld l, $09
	ld [hl], a
	jp ReadStream

; VOLENV v, atk, dec, rates: start volume v; attack = lo nibble steps of hi nibble;
; decay likewise; rates hi = ticks per attack step, lo = ticks per decay step.
; Only the CH3 and SFX pages use it.
Cmd_VolEnv:
	sub $A9
	ld l, $16
	ld [hl], a
	ld a, [de]
	inc de
	ld l, $10
	ld [hli], a
	ld [hl], $00
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
	jp ReadStream

; ARP n: arpeggio n of wArpTable.
Cmd_Arp:
	sub $8E
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

; Not reached: assembler leftovers (x86 code bytes) up to the command table.
Unused_Garbage1:
	db $98, $E8, $3B, $1A, $E8, $38, $1A, $8B, $D9, $2E, $8B, $9F, $6E, $1A, $87, $D3
	db $2E, $8A, $8F, $74, $35, $32, $ED, $3D, $FF, $FF, $75, $03, $B8, $01, $00, $8B
	db $DA, $48, $03, $D8, $03, $D8, $40, $2E, $8B, $17, $92, $AB, $32, $ED, $E3, $16
	db $80, $F9, $FF, $75, $02, $8B, $CA, $57, $51, $80, $F9, $05, $72, $04, $89, $3E
	db $0C, $17, $FF, $26, $E8, $16, $89, $3E, $F2, $16, $EB, $F6, $D7, $0F, $B8, $01
	db $00, $E8, $EB, $19, $3D, $82, $0F, $D1, $EB, $E8, $F3, $FD, $91, $58, $50, $E8
	db $32, $00, $2E, $D7, $98, $E8, $D7, $19, $EB, $AD, $82, $0F, $58, $50, $D1, $E8
	db $B8, $04, $00, $1C, $00, $E8, $C7, $19, $91, $EB, $AF, $D7, $0F, $93, $26, $8A
	db $4C, $FF, $D0, $E9, $D0, $E9, $32, $ED, $03, $D9, $03, $D9, $2E, $8B, $17, $BB
	db $64, $34, $EB, $C9, $53, $32, $E4, $BB, $80, $18, $2E, $D7, $5B, $0A, $C0

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

; Not reached.
Unused_Ret:
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

; Not reached (leftover bytes before the aligned period table).
Unused_Garbage2:
	db $02, $C0, $01, $7F, $0B, $CC, $27, $FA, $27, $72, $3B, $72, $3B, $6B, $07, $6B
	db $07, $81, $07, $5D, $17, $47, $07, $06, $07, $22, $22, $27, $0F, $4E, $22, $0C
	db $07, $17, $07, $31, $22, $6F, $07, $78, $07, $58, $07, $85, $05, $92, $20

; Period table: 81 entries from C2 (same values as all earlier versions), aligned
; at $4800 so that only the low byte is computed.
PeriodTable:
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

; API entry for PlaySfx: goes through the game's glue in the data area first.
PlaySfxEntry:
	jp GamePlaySfxGlue

; PlaySfx (A = id): ignored while a lower id plays; reset the SFX page and start the
; stream from SfxTable. The first tick happens in the next SndUpdate.
PlaySfx:
	ld c, a
	ld a, [$C427]
	and a
	jr z, PlaySfxNow
	cp c
	ret c
PlaySfxNow:
	ld a, c
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
	add a, $9D
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
	cp $B9
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
	add a, $FB
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
	sub $B8
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

; Song 4: instrument table 1, arpeggio table 1 (the one SndInit sets)
PlaySong4:
	ld a, $4D
	ld [wInstrTableHi], a
	ld a, $90
	ld [wInstrTable], a
	ld de, Song4_Ch1
	call StartMusicCh1
	ld de, Song4_Ch2
	call StartMusicCh2
	ld de, Song4_Ch3
	jp StartMusicCh3
Song4_Ch1:
	dw Pat_4B67
	dw Pat_4B67
	dw Pat_4CD5
	dw Pat_4CD5
	dw Pat_4B67
	ORDER_LOOP Song4_Ch1
Song4_Ch2:
	dw Pat_4C86
	dw Pat_4C86
	dw Pat_4D0A
	dw Pat_4D0A
	dw Pat_4C86
	ORDER_LOOP Song4_Ch2
Song4_Ch3:
	dw Pat_4BB1
Pat_4B67:
	LEN 32
	REPEAT 2
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE A_, 3
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	REPEAT_END
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 3
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 3
	LEN 16
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE D_, 2
	INSTR 1
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE A_, 2
	NOTE A_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE A_, 2
	NOTE D_, 2
	NOTE D_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE A_, 2
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE F_, 3
	NOTE E_, 3
	NEXT
Pat_4BA5:
	NOTE C_, 5
Pat_4BA6:
	NOTE D_, 5
	NOTE A_, 4
	WAIT
	NOTE A_, 4
	NOTE D_, 5
	NOTE A_, 4
	WAIT
	NOTE A_, 4
	NOTE D_, 5
	WAIT
	NEXT
Pat_4BB1:
	ARP 0
	RELEASE $04, $01
	WAVE Wave_7BDD
Pat_4BB8:
	VOLENV 12, $11, $1F, $23
	VIBRATO $08, $01, $04
	REPEAT 2
	DRUMS $08, DrumPat_4D3B
	LEN 24
	NOTE A_, 4
	LEN 8
	NOTE G_, 4
	LEN 16
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	LEN 8
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	LEN 48
	NOTE F_, 4
	LEN 16
	WAIT
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	LEN 8
	WAIT
	NOTE B_, 4
	LEN 16
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE A_, 4
	NOTE B_, 4
	LEN 32
	NOTE C_, 5
	LEN 48
	NOTE A_, 4
	LEN 16
	NOTE B_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE B_, 4
	LEN 32
	NOTE A_, 4
	LEN 16
	NOTE B_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	DRUMS $08, DrumPat_4D4E
	NOTE A_, 4
	LEN 8
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	LEN 32
	NOTE A_, 4
	LEN 16
	NOTE B_, 4
	NOTE G_, 4
	NOTE A_, 4
	LEN 8
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	LEN 16
	NOTE D_, 4
	NOTE D_, 4
	NOTE A_, 3
	NOTE G_, 3
	REPEAT_END
	DRUMS $08, DrumPat_4D6F
	LEN 8
	REPEAT 2
	PAT_CALL Pat_4BA6
	NOTE E_, 5
	WAIT
	NOTE D_, 5
	NOTE C_, 5
	WAIT
	PAT_CALL Pat_4BA5
	NOTE F_, 5
	WAIT
	NOTE E_, 5
	NOTE D_, 5
	WAIT
	PAT_CALL Pat_4BA5
	NOTE E_, 5
	WAIT
	NOTE D_, 5
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	NOTE D_, 5
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 4
	NOTE D_, 5
	NOTE A_, 4
	NOTE B_, 4
	NOTE A_, 4
	REPEAT_END
	DRUMS $08, DrumPat_4D3B
	VOLENV 11, $12, $1F, $12
	VIBRATO $08, $01, $04
	LEN 32
	NOTE D_, 5
	LENGTH $40
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE B_, 4
	LEN 48
	NOTE B_, 4
	LEN 8
	NOTE B_, 4
	NOTE B_, 3
	LEN 16
	NOTE C_, 4
	NOTE B_, 3
	DRUMS $08, DrumPat_4D4E
	NOTE A_, 3
	NOTE A_, 3
	LEN 32
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	WAIT
	NOTE G_, 4
	NOTE D_, 4
	LEN 16
	NOTE A_, 3
	NOTE G_, 3
	PAT_GOTO Pat_4BB8
Pat_4C86:
	LEN 16
	INSTR 1
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 4
	NOTE D_, 3
	NOTE D_, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE F_, 3
	NOTE D_, 3
	NOTE D_, 3
	NOTE D_, 4
	NOTE D_, 3
	NOTE D_, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE G_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 4
	NOTE F_, 3
	NOTE F_, 3
	NOTE C_, 4
	NOTE F_, 4
	NOTE A_, 3
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 4
	NOTE F_, 3
	NOTE F_, 3
	NOTE C_, 4
	NOTE F_, 4
	NOTE B_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 4
	NOTE G_, 3
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 3
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 4
	NOTE G_, 3
	NOTE G_, 3
	LEN 8
	NOTE D_, 4
	NOTE G_, 3
	LEN 16
	NOTE F_, 3
	NOTE E_, 3
	NOTE D_, 3
	LEN 8
	NOTE D_, 4
	NOTE A_, 3
	LEN 16
	NOTE E_, 4
	LEN 8
	NOTE C_, 4
	NOTE D_, 4
	LEN 16
	NOTE F_, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE D_, 3
	NOTE A_, 3
	NOTE E_, 4
	NOTE A_, 3
	NOTE F_, 4
	LEN 8
	NOTE A_, 3
	NOTE D_, 3
	LEN 16
	NOTE C_, 4
	NOTE B_, 3
	NEXT
Pat_4CD5:
	REPEAT 2
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE A_, 3
	REPEAT_END
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE B_, 3
	REPEAT 2
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE A_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE A_, 3
	REPEAT_END
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE D_, 4
	NEXT
Pat_4D0A:
	LEN 8
	PAT_CALL Pat_4D22
	WAIT
	WAIT
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE E_, 4
	WAIT
	PAT_CALL Pat_4D22
	WAIT
	WAIT
	NOTE G_, 4
	NOTE D_, 4
	NOTE F_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NEXT
Pat_4D22:
	WAIT
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	NOTE D_, 4
	NOTE A_, 3
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	WAIT
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NEXT
DrumPat_4D3B:
	db DRUM_REPEAT + 3, 6, 0, 6, 0, 4, 0, 6
	db 0, DRUM_REPEAT_END, 6, 0, 6, 0, 4, 0
	db 6, 6, DRUM_LOOP
DrumPat_4D4E:
	db 6, 0, 6, 6, 4, 0, 6, 0
	db 4, 0, 6, 0, 4, 0, 6, 6
	db 6, 0, 6, 6, 4, 0, 6, 0
	db 4, 0, 10, 10, 9, 0, 10, 10
	db DRUM_LOOP
DrumPat_4D6F:
	db DRUM_REPEAT + 3, 9, 0, 10, 10, 9, 0, 10
	db 10, 9, 10, 9, 0, 9, 9, 10
	db 10, DRUM_REPEAT_END, 9, 0, 10, 10, 9, 0
	db 10, 10, 9, 10, 9, 0, 9, 9
	db 9, 9, DRUM_LOOP

; Instrument table 1, entries 1..2 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr1_0
	dw Instr1_1
Instr1_0:
	HWENV $F1, $05, $94
	ARP 0
	END
Instr1_1:
	HWENV $F1, $08, $54
	DUTY_75
	ARP 22
	END

; Song 17: instrument table - (none set), arpeggio table 1 (the one SndInit sets)
PlaySong17:
	ld de, Song17_Ch1
	call StartMusicCh1
	ld de, Song17_Ch2
	call StartMusicCh2
	ld de, Song17_Ch3
	jp StartMusicCh3
Song17_Ch1:
	dw Pat_4DBB
Song17_Ch2:
	dw Pat_4DE5
Song17_Ch3:
	dw Pat_4E1F
Pat_4DBB:
	HWENV $F1, $0C, $C1
	DUTY_50
	ARP 18
Pat_4DC1:
	LEN 24
	REPEAT 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE Csh, 2
	REPEAT_END
	NOTE G_, 2
	NOTE A_, 2
	NOTE Ash, 2
	NOTE C_, 3
	NOTE D_, 3
	NOTE A_, 2
	NOTE F_, 2
	NOTE D_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE Ash, 2
	NOTE C_, 3
	NOTE A_, 2
	NOTE E_, 2
	LEN 18
	NOTE A_, 2
	LEN 6
	NOTE G_, 2
	NOTE F_, 2
	WAIT
	NOTE E_, 2
	WAIT
	PAT_GOTO Pat_4DC1
Pat_4DE5:
	HWENV $F1, $06, $63
	DUTY_75
	LEN 12
Pat_4DEB:
	REPEAT 2
	ARP 9
	NOTE D_, 4
	LEN 24
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN 12
	ARP 8
	NOTE Dsh, 4
	ARP 9
	NOTE D_, 4
	LEN 24
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN 12
	NOTE Csh, 4
	REPEAT_END
	NOTE G_, 4
	LEN 24
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 12
	NOTE G_, 4
	NOTE D_, 4
	LEN 24
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	LEN 12
	NOTE D_, 4
	NOTE G_, 4
	LEN 24
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 12
	NOTE G_, 4
	ARP 8
	NOTE A_, 4
	LEN 24
	NOTE A_, 4
	NOTE A_, 4
	LEN 12
	NOTE A_, 4
	NOTE A_, 4
	NOTE A_, 4
	PAT_GOTO Pat_4DEB
Pat_4E1F:
	WAVE Wave_7BCD
	LEN 6
	VOLENV 10, $00, $00, $00
	RELEASE $01, $50
	ARP 0
Pat_4E2B:
	DRUMS $06, DrumPat_4E98
	REPEAT 2
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE Csh, 5
	NOTE E_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE G_, 5
	NOTE E_, 5
	NOTE Csh, 5
	NOTE E_, 5
	REPEAT_END
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE C_, 6
	NOTE D_, 6
	NOTE Csh, 6
	NOTE D_, 6
	NOTE Dsh, 6
	NOTE D_, 6
	NOTE Ash, 5
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE A_, 4
	NOTE E_, 5
	NOTE A_, 4
	NOTE F_, 5
	NOTE A_, 4
	NOTE G_, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE Ash, 5
	NOTE C_, 6
	NOTE D_, 6
	NOTE Csh, 6
	NOTE D_, 6
	NOTE Dsh, 6
	NOTE D_, 6
	NOTE Ash, 5
	NOTE A_, 5
	NOTE Gsh, 5
	NOTE A_, 5
	REST
	NOTE A_, 5
	NOTE Ash, 5
	NOTE A_, 5
	REST
	NOTE Ash, 5
	REST
	NOTE A_, 5
	WAIT
	DRUMS $06, DrumPat_4EA5
	REST
	NOTE Ash, 5
	NOTE A_, 5
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	PAT_GOTO Pat_4E2B
DrumPat_4E98:
	db DRUM_LEVEL + 14, 1, 0, DRUM_LEVEL + 12, 6, 6, DRUM_LEVEL + 14, 9
	db 0, DRUM_LEVEL + 12, 6, 6, DRUM_LOOP
DrumPat_4EA5:
	db DRUM_LEVEL + 14, 0, 9, 9, 0, 9, 9, DRUM_LOOP

; Song 2: instrument table 2, arpeggio table 1 (the one SndInit sets)
PlaySong2:
	ld a, $52
	ld [wInstrTableHi], a
	ld a, $DB
	ld [wInstrTable], a
	ld de, Song2_Ch1
	call StartMusicCh1
	ld de, Song2_Ch3
	call StartMusicCh3
	ld de, Song2_Ch2
	jp StartMusicCh2
Song2_Ch1:
	dw Pat_4F13
	dw Pat_4F16
	dw Pat_4F1C
	dw Pat_4FF4
	dw Pat_4F45
	dw Pat_4F1C
	dw Pat_4FCC
	dw Pat_5035
	dw Pat_4F1C
	dw Pat_4F1C
	dw Pat_4FF4
	dw Pat_4FCC
	ORDER_LOOP Song2_Ch1
Song2_Ch3:
	dw Pat_5110
Loop_4EE7:
	dw Pat_5152
	dw Pat_51BD
	dw Pat_511D
	dw Pat_51B7
	dw Pat_5251
	dw Pat_511D
	dw Pat_5152
	dw Pat_51B7
	dw Pat_511D
	ORDER_LOOP Loop_4EE7
Song2_Ch2:
	dw Pat_5097
Loop_4EFF:
	dw Pat_50B2
	dw Pat_51FB
	dw Pat_50A2
	dw Pat_50CB
	dw Pat_5282
	dw Pat_50A2
	dw Pat_50B2
	dw Pat_50A1
	ORDER_LOOP Loop_4EFF
Pat_4F13:
	TRANSPOSE $00
	NEXT
Pat_4F16:
	DRUMS $09, DrumPat_52B4
	LEN 9
	INSTR 0
Pat_4F1C:
	PAT_CALL Pat_4FAF
	NOTE A_, 3
	WAIT
	INSTR 0
	NOTE A_, 2
	NOTE Ash, 2
	WAIT
	WAIT
	INSTR 1
	NOTE Ash, 3
	WAIT
	INSTR 0
	NOTE Ash, 2
	NOTE F_, 2
	WAIT
	WAIT
	INSTR 1
	NOTE F_, 4
	WAIT
	INSTR 0
	NOTE F_, 2
	NOTE G_, 2
	WAIT
	WAIT
	INSTR 1
	NOTE Ash, 3
	WAIT
	INSTR 0
	NOTE G_, 2
	NOTE C_, 3
	WAIT
	INSTR 2
	NOTE D_, 4
	ARP 6
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	NEXT
Pat_4F45:
	PAT_CALL Pat_4FAF
	NOTE A_, 4
	WAIT
	INSTR 0
	NOTE A_, 2
	NOTE Ash, 2
	WAIT
	WAIT
	INSTR 1
	NOTE Ash, 4
	WAIT
	INSTR 0
	NOTE Ash, 2
	NOTE C_, 3
	WAIT
	WAIT
	INSTR 1
	NOTE C_, 5
	WAIT
	INSTR 0
	NOTE C_, 3
	NOTE F_, 2
	WAIT
	WAIT
	INSTR 1
	NOTE F_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	WAIT
	INSTR 0
	NOTE Gsh, 2
	REPEAT 2
	NOTE A_, 2
	WAIT
	WAIT
	INSTR 2
	NOTE A_, 4
	WAIT
	INSTR 0
	NOTE A_, 2
	NOTE E_, 2
	WAIT
	WAIT
	INSTR 2
	NOTE A_, 4
	WAIT
	INSTR 0
	NOTE E_, 2
	NOTE Ash, 2
	WAIT
	WAIT
	INSTR 1
	NOTE Ash, 4
	WAIT
	INSTR 0
	NOTE Ash, 2
	NOTE F_, 2
	WAIT
	WAIT
	INSTR 1
	NOTE Ash, 4
	WAIT
	INSTR 0
	NOTE F_, 2
	NOTE G_, 2
	WAIT
	WAIT
	INSTR 2
	NOTE G_, 4
	WAIT
	INSTR 0
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	WAIT
	INSTR 2
	NOTE G_, 4
	WAIT
	INSTR 0
	NOTE D_, 2
	NOTE C_, 2
	WAIT
	WAIT
	INSTR 1
	NOTE C_, 5
	WAIT
	INSTR 0
	NOTE C_, 2
	NOTE C_, 3
	WAIT
	WAIT
	INSTR 1
	NOTE C_, 5
	WAIT
	INSTR 0
	NOTE C_, 3
	REPEAT_END
	NEXT
Pat_4FAF:
	NOTE F_, 2
	WAIT
	WAIT
	INSTR 1
	NOTE F_, 4
	WAIT
	INSTR 0
	NOTE F_, 2
	NOTE C_, 2
	WAIT
	WAIT
	INSTR 1
	NOTE C_, 4
	WAIT
	INSTR 0
	NOTE C_, 2
	NOTE D_, 2
	WAIT
	WAIT
	INSTR 2
	NOTE D_, 4
	WAIT
	INSTR 0
	NOTE D_, 2
	NOTE A_, 2
	WAIT
	WAIT
	INSTR 2
	NEXT
Pat_4FCC:
	PAT_CALL Pat_4FAF
	NOTE A_, 4
	WAIT
	INSTR 0
	NOTE A_, 2
	NOTE Ash, 2
	WAIT
	WAIT
	INSTR 1
	NOTE Ash, 4
	WAIT
	INSTR 0
	NOTE Ash, 2
	NOTE C_, 3
	WAIT
	WAIT
	INSTR 1
	NOTE C_, 5
	WAIT
	INSTR 0
	NOTE C_, 3
	NOTE F_, 2
	WAIT
	WAIT
	INSTR 1
	NOTE F_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	WAIT
	INSTR 0
	NOTE C_, 3
	NEXT
Pat_4FF4:
	NOTE Ash, 2
	WAIT
	WAIT
	INSTR 1
	NOTE Ash, 4
	WAIT
	INSTR 0
	NOTE Ash, 2
	NOTE F_, 2
	WAIT
	WAIT
	INSTR 1
	NOTE Ash, 4
	WAIT
	INSTR 0
	NOTE F_, 2
	NOTE C_, 3
	WAIT
	WAIT
	INSTR 2
	NOTE C_, 5
	WAIT
	INSTR 0
	NOTE F_, 2
	NOTE Ash, 2
	WAIT
	WAIT
	INSTR 1
	NOTE Ash, 4
	WAIT
	NOTE Ash, 4
	INSTR 0
	NOTE Ash, 2
	WAIT
	WAIT
	INSTR 1
	NOTE Ash, 4
	WAIT
	INSTR 0
	NOTE Ash, 2
	NOTE F_, 2
	WAIT
	WAIT
	INSTR 1
	NOTE Ash, 4
	WAIT
	INSTR 0
	NOTE F_, 2
	NOTE C_, 3
	WAIT
	WAIT
	INSTR 2
	NOTE C_, 5
	WAIT
	INSTR 0
	NOTE F_, 2
	NOTE Ash, 2
	WAIT
	INSTR 1
	NOTE Ash, 4
	NOTE Ash, 4
	WAIT
	INSTR 0
	NOTE F_, 2
	NEXT
Pat_5035:
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	INSTR 0
	NOTE C_, 2
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	WAIT
	WAIT
	INSTR 0
	NOTE F_, 2
	NOTE C_, 2
	WAIT
	NOTE D_, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	INSTR 0
	NOTE D_, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	WAIT
	INSTR 0
	NOTE D_, 2
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	WAIT
	NOTE A_, 2
	TRANSPOSE $02
	NEXT
Pat_5072:
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE Ash, 4
	NOTE C_, 5
	WAIT
	NOTE Ash, 4
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	NOTE F_, 4
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	NOTE F_, 4
	WAIT
	NOTE E_, 4
	NOTE D_, 4
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	WAIT
	NEXT
Pat_5097:
	LEN 9
	HWENV $F1, $04, $73
	DUTY_50
	VIBRATO $09, $01, $04
Pat_50A1:
	ARP_OFF
Pat_50A2:
	PAT_CALL Pat_5072
	NOTE D_, 4
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	NOTE G_, 4
	NOTE F_, 4
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	NEXT
Pat_50B2:
	PAT_CALL Pat_5072
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	NOTE Ash, 4
	WAIT
	NOTE B_, 4
	LEN 27
	NOTE C_, 5
	NOTE G_, 5
	LEN 9
	PAT_CALL Pat_50FA
	NOTE D_, 6
	WAIT
	NOTE Ash, 5
	PAT_CALL Pat_50FA
	NOTE A_, 4
	WAIT
	NOTE G_, 4
Pat_50CB:
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE Ash, 4
	NOTE C_, 5
	WAIT
	NOTE Ash, 4
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	NOTE F_, 4
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	NOTE F_, 4
	WAIT
	NOTE E_, 4
	NOTE D_, 4
	WAIT
	NOTE E_, 4
	NOTE F_, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	NOTE Ash, 4
	WAIT
	NOTE A_, 4
	NOTE F_, 4
	WAIT
	NOTE C_, 4
	NOTE A_, 3
	WAIT
	NOTE C_, 4
	LEN 27
	NOTE F_, 3
	WAIT
	LEN 9
	NEXT
Pat_50FA:
	NOTE D_, 5
	WAIT
	NOTE Ash, 4
	NOTE F_, 4
	WAIT
	NOTE Ash, 4
	NOTE D_, 5
	WAIT
	NOTE Ash, 4
	NOTE D_, 5
	WAIT
	NOTE F_, 5
	NOTE Dsh, 5
	WAIT
	NOTE C_, 5
	NOTE G_, 4
	WAIT
	NOTE F_, 5
	NOTE D_, 5
	WAIT
	NOTE Ash, 4
	NEXT
Pat_5110:
	LEN 9
	VOLENV 12, $11, $1F, $12
	ARP 0
	WAVE Wave_7BDD
	VIBRATO $09, $01, $04
Pat_511D:
	PAT_CALL Pat_5129
	WAIT
	NOTE E_, 4
	NOTE D_, 4
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	NEXT
Pat_5129:
	WAIT
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	WAIT
	NOTE A_, 3
	WAIT
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	WAIT
	NOTE A_, 3
	WAIT
	WAIT
	NOTE F_, 3
	NOTE A_, 3
	WAIT
	NOTE F_, 3
	WAIT
	WAIT
	NOTE F_, 3
	NOTE A_, 3
	WAIT
	NOTE F_, 3
	WAIT
	WAIT
	NOTE D_, 3
	NOTE F_, 3
	WAIT
	NOTE D_, 3
	WAIT
	WAIT
	NOTE C_, 3
	NOTE F_, 3
	WAIT
	NOTE C_, 3
	NOTE Ash, 3
	WAIT
	NOTE C_, 4
	NOTE D_, 4
	NEXT
Pat_5152:
	PAT_CALL Pat_5129
	WAIT
	NOTE Dsh, 4
	LEN 27
	NOTE E_, 4
	NOTE E_, 5
	LEN 9
	NOTE F_, 4
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	NOTE D_, 4
	NOTE F_, 4
	WAIT
	NOTE D_, 4
	NOTE F_, 4
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	WAIT
	NOTE G_, 4
	NOTE F_, 4
	WAIT
	NOTE D_, 4
	NOTE F_, 5
	WAIT
	NOTE D_, 5
	NOTE F_, 4
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	NOTE D_, 4
	NOTE F_, 4
	WAIT
	NOTE D_, 4
	NOTE F_, 4
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE Dsh, 4
	WAIT
	WAIT
	NOTE G_, 4
	NOTE F_, 4
	WAIT
	NOTE D_, 4
	NOTE C_, 4
	WAIT
	NOTE Ash, 3
	NEXT
Pat_518C:
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	WAIT
	NOTE A_, 3
	WAIT
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	WAIT
	NOTE A_, 3
	WAIT
	WAIT
	NOTE F_, 3
	NOTE A_, 3
	WAIT
	NOTE F_, 3
	WAIT
	WAIT
	NOTE F_, 3
	NOTE A_, 3
	WAIT
	NOTE F_, 3
	WAIT
	WAIT
	NOTE Ash, 3
	NOTE D_, 4
	WAIT
	NOTE Ash, 3
	WAIT
	WAIT
	NOTE C_, 4
	NOTE E_, 4
	WAIT
	NOTE C_, 4
	LEN 27
	NOTE A_, 3
	LENGTH $36
	NOTE F_, 3
	LEN 27
	NEXT
Pat_51B7:
	PAT_CALL Pat_518C
	NOTE A_, 2
	LEN 9
	NEXT
Pat_51BD:
	PAT_CALL Pat_518C
	NOTE G_, 2
	PAT_CALL Pat_51E8
	NOTE Ash, 3
	NOTE D_, 4
	LEN 9
	NOTE Ash, 3
	WAIT
	NOTE G_, 3
	LEN 27
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	LEN 9
	NOTE C_, 4
	WAIT
	NOTE D_, 4
	PAT_CALL Pat_51E8
	NOTE B_, 3
	NOTE D_, 4
	LEN 9
	NOTE G_, 4
	WAIT
	NOTE D_, 5
	NOTE E_, 5
	WAIT
	NOTE E_, 5
	NOTE F_, 5
	WAIT
	NOTE Fsh, 5
	NOTE G_, 5
	WAIT
	NOTE C_, 4
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	NEXT
Pat_51E8:
	LEN 27
	NOTE A_, 3
	NOTE C_, 4
	NOTE E_, 4
	LEN 9
	NOTE C_, 4
	WAIT
	NOTE A_, 3
	LEN 27
	NOTE Ash, 3
	NOTE D_, 4
	NOTE F_, 4
	LEN 9
	NOTE D_, 4
	WAIT
	NOTE Ash, 3
	LEN 27
	NOTE G_, 3
	NEXT
Pat_51FB:
	PAT_CALL Pat_523A
	ARP 19
	LEN 27
	NOTE F_, 5
	NOTE F_, 5
	LEN 9
	NOTE F_, 5
	WAIT
	ARP_OFF
	NOTE D_, 5
	NOTE E_, 5
	WAIT
	NOTE F_, 5
	ARP 19
	NOTE G_, 5
	WAIT
	ARP_OFF
	NOTE G_, 5
	ARP 19
	NOTE G_, 5
	WAIT
	ARP_OFF
	LENGTH $3F
	NOTE G_, 5
	PAT_CALL Pat_523A
	NOTE G_, 5
	WAIT
	NOTE G_, 5
	NOTE A_, 5
	WAIT
	NOTE Ash, 5
	NOTE B_, 5
	WAIT
	NOTE G_, 5
	NOTE A_, 5
	WAIT
	NOTE B_, 5
	NOTE C_, 6
	WAIT
	NOTE C_, 6
	NOTE D_, 6
	WAIT
	NOTE Dsh, 6
	NOTE E_, 6
	WAIT
	LEN 3
	NOTE B_, 4
	LEN 6
	NOTE C_, 5
	LEN 9
	NOTE B_, 4
	WAIT
	NOTE Ash, 4
	HWENV $F1, $04, $73
	NEXT
Pat_523A:
	LEN 27
	WAIT
	HWENV $F1, $04, $76
	NOTE A_, 5
	NOTE A_, 5
	NOTE Ash, 5
	ARP 19
	NOTE G_, 5
	ARP_OFF
	LEN 9
	NOTE G_, 5
	WAIT
	NOTE F_, 5
	WAIT
	WAIT
	NOTE D_, 5
	NOTE E_, 5
	WAIT
	NOTE F_, 5
	NEXT
Pat_5251:
	WAIT
	WAIT
	NOTE A_, 4
	NOTE C_, 5
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	NOTE A_, 4
	NOTE C_, 5
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	NOTE A_, 4
	NOTE C_, 5
	WAIT
	NOTE A_, 4
	NOTE D_, 5
	WAIT
	NOTE C_, 5
	NOTE C_, 5
	WAIT
	NOTE D_, 5
	WAIT
	WAIT
	NOTE B_, 3
	NOTE D_, 4
	WAIT
	NOTE B_, 3
	WAIT
	WAIT
	NOTE B_, 3
	NOTE D_, 4
	WAIT
	NOTE B_, 3
	NOTE G_, 3
	WAIT
	NOTE B_, 3
	NOTE D_, 4
	WAIT
	NOTE B_, 3
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	NEXT
Pat_5282:
	NOTE F_, 3
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	WAIT
	NOTE A_, 3
	WAIT
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	WAIT
	NOTE A_, 3
	WAIT
	WAIT
	NOTE A_, 3
	NOTE C_, 4
	WAIT
	NOTE A_, 3
	NOTE D_, 4
	WAIT
	NOTE C_, 4
	NOTE C_, 4
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	NOTE B_, 4
	NOTE D_, 5
	WAIT
	NOTE B_, 4
	WAIT
	WAIT
	NOTE B_, 4
	NOTE D_, 5
	WAIT
	NOTE B_, 4
	WAIT
	WAIT
	NOTE B_, 4
	NOTE D_, 5
	WAIT
	NOTE B_, 4
	NOTE E_, 5
	WAIT
	NOTE D_, 5
	NOTE G_, 5
	WAIT
	NOTE A_, 5
	ARP 14
	NEXT
DrumPat_52B4:
	db DRUM_LEVEL + 15, 6, 0, DRUM_LEVEL + 12, 6, DRUM_LEVEL + 14, 4, 0
	db DRUM_LEVEL + 12, 6, DRUM_LEVEL + 15, 6, 0, DRUM_LEVEL + 15, 6, DRUM_LEVEL + 14
	db 4, 0, DRUM_LEVEL + 12, 6, DRUM_LEVEL + 15, 6, 0, DRUM_LEVEL + 12
	db 6, DRUM_LEVEL + 14, 4, 0, DRUM_LEVEL + 12, 6, DRUM_LEVEL + 15, 6
	db 0, DRUM_LEVEL + 15, 6, DRUM_LEVEL + 14, 4, 0, DRUM_LEVEL + 14, 4
	db DRUM_LOOP

; Instrument table 2, entries 1..3 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr2_0
	dw Instr2_1
	dw Instr2_2
Instr2_0:
	HWENV $F1, $06, $60
	ARP 13
	END
Instr2_1:
	HWENV $F2, $04, $83
	ARP 6
	DUTY_75
	END
Instr2_2:
	HWENV $F2, $04, $83
	ARP 7
	DUTY_75
	END

; Song 9: instrument table - (none set), arpeggio table 1 (the one SndInit sets)
PlaySong9:
	ld de, Song9_Ch1
	call StartMusicCh1
	ld de, Song9_Ch2
	call StartMusicCh2
	ld de, Song9_Ch3
	jp StartMusicCh3
Song9_Ch1:
	dw Pat_532D
Loop_530B:
	dw Pat_5378
	dw Pat_532A
	dw Pat_5378
	dw Pat_5327
	ORDER_LOOP Loop_530B
Song9_Ch2:
	dw Pat_54D6
Loop_5319:
	dw Pat_54EE
	ORDER_LOOP Loop_5319
Song9_Ch3:
	dw Pat_5346
Loop_5321:
	dw Pat_541C
	ORDER_LOOP Loop_5321
Pat_5327:
	TRANSPOSE $00
	NEXT
Pat_532A:
	TRANSPOSE $02
	NEXT
Pat_532D:
	LEN 7
	HWENV $F1, $05, $A3
	ARP 0
	DUTY_50
	RELEASE $01, $00
	LEN 28
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	LEN 14
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE C_, 3
	NOTE Ash, 2
	NOTE A_, 2
	NEXT
Pat_5346:
	LEN 7
	RELEASE $01, $50
	ARP 0
	VIBRATO $07, $02, $05
	WAVE Wave_7BCD
	DRUMS $07, DrumPat_55BB
	VOLENV 15, $15, $15, $11
	VIBRATO $0A, $01, $05
	LEN 42
	NOTE A_, 4
	LEN 14
	NOTE Ash, 4
	LEN 42
	NOTE A_, 4
	LEN 14
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	LEN 7
	DRUMS $07, DrumPat_558D
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE D_, 5
	NEXT
Pat_5378:
	LEN 7
	REPEAT 2
	NOTE G_, 2
	WAIT
	NOTE D_, 3
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 3
	NOTE D_, 2
	NOTE G_, 2
	WAIT
	NOTE D_, 3
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 3
	NOTE D_, 2
	NOTE G_, 2
	WAIT
	NOTE A_, 2
	WAIT
	NOTE Ash, 2
	WAIT
	NOTE C_, 3
	WAIT
	NOTE D_, 3
	NOTE Dsh, 3
	NOTE D_, 3
	NOTE C_, 3
	NOTE D_, 3
	NOTE C_, 3
	NOTE Ash, 2
	NOTE A_, 2
	NOTE G_, 2
	WAIT
	NOTE D_, 3
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 3
	NOTE D_, 2
	NOTE G_, 2
	WAIT
	NOTE D_, 3
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 3
	NOTE D_, 2
	NOTE G_, 2
	WAIT
	NOTE Fsh, 2
	WAIT
	NOTE F_, 2
	WAIT
	NOTE E_, 2
	WAIT
	NOTE Dsh, 2
	WAIT
	NOTE Ash, 2
	NOTE Dsh, 2
	NOTE D_, 2
	WAIT
	NOTE A_, 2
	NOTE D_, 2
	REPEAT_END
	REPEAT 2
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	NOTE D_, 3
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	NOTE D_, 3
	NOTE C_, 3
	WAIT
	NOTE C_, 4
	NOTE G_, 3
	NOTE C_, 3
	WAIT
	NOTE C_, 4
	NOTE G_, 3
	NOTE F_, 2
	WAIT
	NOTE F_, 3
	NOTE C_, 3
	NOTE F_, 2
	WAIT
	NOTE F_, 3
	NOTE C_, 3
	NOTE Ash, 2
	WAIT
	NOTE Ash, 3
	NOTE F_, 3
	NOTE Ash, 2
	WAIT
	NOTE Ash, 3
	NOTE F_, 3
	NOTE Dsh, 2
	WAIT
	NOTE Dsh, 3
	NOTE Ash, 2
	NOTE Dsh, 2
	WAIT
	NOTE Dsh, 3
	NOTE Ash, 2
	NOTE C_, 2
	WAIT
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 2
	WAIT
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 2
	WAIT
	NOTE C_, 3
	NOTE G_, 2
	NOTE C_, 2
	WAIT
	NOTE C_, 3
	NOTE G_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 3
	NOTE A_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 3
	NOTE A_, 2
	REPEAT_END
	REPEAT 2
	LENGTH $62
	NOTE G_, 2
	LEN 14
	NOTE Gsh, 2
	LENGTH $54
	NOTE G_, 2
	LEN 14
	NOTE C_, 3
	NOTE Ash, 2
	NOTE G_, 2
	LEN 42
	NOTE G_, 2
	LEN 14
	NOTE G_, 2
	LEN 28
	NOTE G_, 2
	LEN 14
	NOTE Gsh, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 3
	WAIT
	NOTE D_, 2
	NOTE D_, 2
	NOTE D_, 3
	NOTE D_, 2
	REPEAT_END
	NEXT
Pat_541C:
	DRUMS $07, DrumPat_5561
	REPEAT 2
	NOTE G_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE Ash, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE Ash, 4
	NOTE D_, 4
	NOTE C_, 5
	NOTE D_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE A_, 4
	NOTE C_, 5
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE Ash, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	REPEAT_END
	REPEAT 2
	NOTE B_, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE Dsh, 5
	WAIT
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	WAIT
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE D_, 5
	WAIT
	NOTE D_, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	WAIT
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	WAIT
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE G_, 3
	NOTE Dsh, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE D_, 4
	NOTE A_, 3
	NOTE Fsh, 4
	NOTE A_, 3
	NOTE Ash, 4
	NOTE A_, 3
	NOTE A_, 4
	NOTE A_, 3
	REPEAT_END
	REPEAT 2
	DRUMS $07, DrumPat_55A8
	LEN 14
	NOTE G_, 4
	WAIT
	NOTE D_, 4
	NOTE D_, 3
	NOTE Ash, 3
	NOTE G_, 3
	WAIT
	NOTE G_, 3
	LEN 7
	DRUMS $07, DrumPat_5596
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE C_, 4
	LEN 14
	NOTE D_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE G_, 4
	NOTE D_, 5
	WAIT
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE Ash, 4
	LEN 35
	NOTE D_, 5
	LEN 7
	NOTE Dsh, 5
	NOTE D_, 5
	NOTE C_, 5
	LENGTH $38
	NOTE D_, 5
	REPEAT_END
	LEN 7
	NEXT
Pat_54D6:
	HWENV $F1, $05, $93
	ARP 0
	DUTY_75
	LEN 28
	ARP 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	LEN 14
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	ARP 5
	NOTE G_, 4
	ARP 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NEXT
Pat_54EE:
	REPEAT 2
	WAIT
	LEN 28
	ARP 5
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	ARP 4
	LEN 14
	NOTE D_, 4
	LEN 42
	NOTE D_, 4
	LEN 28
	ARP 5
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 14
	NOTE G_, 4
	NOTE G_, 4
	ARP 4
	NOTE Fsh, 4
	NOTE F_, 4
	ARP 5
	NOTE E_, 4
	LEN 28
	ARP 4
	NOTE Dsh, 4
	NOTE D_, 4
	LEN 14
	REPEAT_END
	REPEAT 2
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	ARP 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	NOTE C_, 5
	ARP 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Ash, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	ARP 5
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	ARP 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 4
	REPEAT_END
	REPEAT 2
	ARP 5
	LENGTH $38
	NOTE G_, 4
	LEN 42
	NOTE G_, 3
	ARP 4
	LEN 14
	NOTE Gsh, 3
	ARP 5
	LENGTH $38
	NOTE G_, 3
	LEN 28
	NOTE G_, 3
	LEN 14
	NOTE C_, 4
	ARP 4
	NOTE Ash, 3
	ARP 5
	NOTE G_, 3
	LEN 42
	NOTE G_, 3
	LEN 14
	NOTE G_, 3
	LEN 28
	NOTE G_, 3
	ARP 4
	LEN 14
	NOTE Gsh, 3
	ARP 5
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 4
	WAIT
	ARP 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE D_, 5
	WAIT
	REPEAT_END
	NEXT
DrumPat_5561:
	db 7, 0, 0, 6, 9, 0, 6, 6
	db DRUM_REPEAT + 2, 1, 0, 6, 6, 9, 0, 6
	db 6, DRUM_REPEAT_END, 1, 0, 6, 6, 9, 0
	db 10, 9, DRUM_REPEAT + 2, 1, 0, 6, 6, 9
	db 0, 6, 6, DRUM_REPEAT_END, 1, 0, 6, 6
	db 9, 0, 6, 9
DrumPat_558D:
	db 1, 0, 9, 10, 9, 0, 9, 9
	db DRUM_LOOP
DrumPat_5596:
	db DRUM_LEVEL + 13, 9, 0, 10, 10, 9, 0, 10
	db 10, 9, 10, 9, 10, 9, 0, 10
	db 10, DRUM_LOOP
DrumPat_55A8:
	db DRUM_LEVEL + 15, 7, 0, 0, DRUM_LEVEL + 13, 10, 9, 0
	db 10, 10, 9, 10, 9, 10, 9, 0
	db 10, 10, DRUM_LOOP
DrumPat_55BB:
	db DRUM_LEVEL + 12, 1, 0, DRUM_LEVEL + 11, 4, DRUM_LEVEL + 13, 6, DRUM_LOOP

; Song 13: instrument table - (none set), arpeggio table 1 (the one SndInit sets)
PlaySong13:
	ld de, Song13_Ch1
	call StartMusicCh1
	ld de, Song13_Ch2
	call StartMusicCh2
	ld de, Song13_Ch3
	jp StartMusicCh3
Song13_Ch1:
	dw Pat_55DB
Song13_Ch2:
	dw Pat_55FF
Song13_Ch3:
	dw Pat_5621
Pat_55DB:
	LEN 7
	TRANSPOSE $01
	HWENV $C0, $00
	DUTY_75
	VIBRATO $0E, $01, $05
	RELEASE $01, $57
	NOTE D_, 3
	WAIT
	WAIT
	WAIT2
	NOTE D_, 3
	WAIT
	WAIT2
	NOTE Csh, 3
	NOTE D_, 3
	WAIT2
	NOTE G_, 3
	WAIT2
	NOTE B_, 3
	WAIT2
	NOTE D_, 4
	WAIT2
	LENGTH $4E
	NOTE C_, 4
	LEN 48
	WAIT2
	END
Pat_55FF:
	LEN 7
	HWENV $C0, $00
	DUTY_75
	VIBRATO $0E, $01, $05
	RELEASE $01, $57
	NOTE B_, 3
	WAIT
	WAIT
	WAIT2
	NOTE B_, 3
	WAIT
	WAIT2
	NOTE Ash, 3
	NOTE B_, 3
	WAIT2
	NOTE D_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE B_, 4
	WAIT2
	LENGTH $4E
	NOTE A_, 4
	LEN 48
	WAIT2
	END
Pat_5621:
	LEN 7
	VOLENV 15, $11, $1F, $10
	VIBRATO $0E, $01, $05
	RELEASE $03, $01
	WAVE Wave_7B0D
	NOTE G_, 3
	WAIT
	WAIT
	WAIT2
	NOTE G_, 3
	WAIT
	WAIT2
	NOTE Fsh, 3
	NOTE G_, 3
	WAIT2
	NOTE B_, 3
	WAIT2
	NOTE D_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	LENGTH $4E
	RELEASE $05, $02
	NOTE F_, 4
	LEN 48
	WAIT2
	END

; Song 14: instrument table - (none set), arpeggio table 1 (the one SndInit sets)
PlaySong14:
	ld de, Song14_Ch1
	call StartMusicCh1
	ld de, Song14_Ch2
	call StartMusicCh2
	ld de, Song14_Ch3
	jp StartMusicCh3
Song14_Ch1:
	dw Pat_5661
Song14_Ch2:
	dw Pat_5681
Song14_Ch3:
	dw Pat_56A1
Pat_5661:
	LEN 7
	HWENV $F1, $04, $64
	ARP 23
	DUTY_50
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	NOTE F_, 3
	WAIT
	NOTE F_, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE G_, 3
	WAIT
	NOTE G_, 2
	NOTE C_, 2
	WAIT
	WAIT
	NOTE G_, 2
	WAIT
	NOTE C_, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	END
Pat_5681:
	LEN 7
	HWENV $F1, $04, $64
	ARP 4
	AUTODUTY $03
	NOTE F_, 4
	WAIT
	WAIT
	NOTE F_, 4
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	END
Pat_56A1:
	LEN 7
	DRUMS $07, DrumPat_56C8
	VOLENV 15, $12, $1F, $11
	ARP 23
	CH_TRANSPOSE $0C
	WAVE Wave_7B6D
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	NOTE C_, 5
	WAIT
	NOTE B_, 4
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	NOTE C_, 5
	WAIT
	WAIT
	NOTE Dsh, 4
	WAIT
	NOTE C_, 4
	DRUMS_OFF
	WAIT
	WAIT
	WAIT
	WAIT
	END
DrumPat_56C8:
	db 6, 0, 6, 4, 0, 6, 6, 0           ; no DRUM_LOOP: the pattern runs into the next data
	db 6, 4, 0, 6, 6, 6, 6, 7
	db 0, 7

; Song 16: instrument table - (none set), arpeggio table 1 (the one SndInit sets)
PlaySong16:
	ld de, Song16_Ch1
	call StartMusicCh1
	ld de, Song16_Ch2
	call StartMusicCh2
	ld de, Song16_Ch3
	jp StartMusicCh3
Song16_Ch1:
	dw Pat_56F2
Song16_Ch2:
	dw Pat_5728
Song16_Ch3:
	dw Pat_5743
Pat_56F2:
	DUTY_75
	FADE $06, FadeInTable
	HWENV $F2, $18, $67
	ARP 23
	VIBRATO $0C, $04, $05
	DRUMS $0C, DrumPat_591B
Pat_5704:
	LEN 24
	NOTE C_, 2
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	NOTE G_, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	WAIT
	NOTE Gsh, 2
	NOTE G_, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	NOTE G_, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE F_, 2
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE D_, 2
	NOTE D_, 2
	PAT_GOTO Pat_5704
Pat_5728:
	AUTODUTY $06
	HWENV $5F, $30, $D7
	VIBRATO $00, $01, $06
	LENGTH $60
Pat_5734:
	ARP 5
	NOTE C_, 4
	NOTE G_, 4
	ARP 4
	NOTE Gsh, 4
	NOTE G_, 4
	ARP 5
	NOTE C_, 4
	NOTE G_, 4
	NOTE F_, 4
	ARP 4
	NOTE Dsh, 4
	PAT_GOTO Pat_5734
Pat_5743:
	LEN 12
	WAVE Wave_7B6D
	VOLENV 12, $00, $1A, $16
	ARP 0
	CH_TRANSPOSE $0C
	RELEASE $75, $01
Pat_5751:
	NOTE C_, 5
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 5
	WAIT
	WAIT
	NOTE C_, 5
	NOTE D_, 5
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	NOTE C_, 5
	WAIT
	NOTE Gsh, 4
	WAIT
	NOTE F_, 4
	WAIT
	WAIT
	WAIT
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 5
	WAIT
	WAIT
	NOTE C_, 5
	NOTE D_, 5
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE Ash, 4
	WAIT
	NOTE C_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE G_, 5
	WAIT
	LEN 3
	NOTE F_, 5
	LEN 21
	NOTE G_, 5
	LEN 12
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	WAIT
	WAIT
	WAIT
	PAT_GOTO Pat_5751

; Song 15: instrument table - (none set), arpeggio table 1 (the one SndInit sets)
PlaySong15:
	ld de, Song15_Ch1
	call StartMusicCh1
	ld de, Song15_Ch2
	call StartMusicCh2
	ld de, Song15_Ch3
	jp StartMusicCh3
Song15_Ch1:
	dw Pat_57CC
Song15_Ch2:
	dw Pat_5836
	dw Pat_57BF
Loop_57AF:
	dw Pat_583D
	ORDER_LOOP Loop_57AF
Song15_Ch3:
	dw Pat_5887
	dw Pat_57C6
Loop_57B9:
	dw Pat_589B
	ORDER_LOOP Loop_57B9
Pat_57BF:
	CH_TRANSPOSE $0C
	HWENV $F1, $0C, $93
	NEXT
Pat_57C6:
	CH_TRANSPOSE $00
	WAVE Wave_7BCD
	NEXT
Pat_57CC:
	LEN 12
	HWENV $F1, $0C, $82
	DUTY_50
	ARP 23
Pat_57D3:
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	NOTE Dsh, 2
	WAIT
	NOTE Dsh, 2
	NOTE Dsh, 2
	WAIT
	NOTE Dsh, 2
	NOTE Dsh, 2
	WAIT
	NOTE Dsh, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	NOTE C_, 2
	WAIT
	NOTE C_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	NOTE F_, 2
	WAIT
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	NOTE Gsh, 2
	WAIT
	NOTE Gsh, 2
	NOTE Gsh, 2
	WAIT
	NOTE Gsh, 2
	NOTE Gsh, 2
	WAIT
	NOTE Gsh, 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 2
	NOTE Ash, 2
	WAIT
	NOTE Ash, 2
	NOTE Ash, 2
	WAIT
	NOTE Ash, 2
	PAT_GOTO Pat_57D3
Pat_5836:
	HWENV $F1, $0C, $81
	DUTY_75
	AUTODUTY $06
Pat_583D:
	ARP 5
	LEN 12
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	LEN 36
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	LEN 12
	ARP 4
	NOTE Dsh, 3
	NOTE Dsh, 3
	NOTE Dsh, 3
	LEN 36
	NOTE Dsh, 3
	NOTE Dsh, 3
	NOTE Dsh, 3
	ARP 5
	LEN 12
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	LEN 36
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 3
	LEN 12
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 36
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 12
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	LEN 36
	NOTE F_, 3
	NOTE F_, 3
	NOTE F_, 3
	LEN 12
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	LEN 36
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	ARP 4
	LEN 12
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	LEN 36
	NOTE Gsh, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	LEN 12
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	NOTE Ash, 3
	WAIT
	NOTE Ash, 3
	NOTE Ash, 3
	WAIT
	NOTE Ash, 3
	NEXT
Pat_5887:
	WAVE Wave_7B1D
	DRUMS $06, DrumPat_58DC
	VOLENV 13, $00, $13, $11
	VIBRATO $19, $01, $04
	CH_TRANSPOSE $0C
	RELEASE $01, $51
Pat_589B:
	LEN 36
	NOTE G_, 4
	WAIT
	NOTE C_, 5
	NOTE G_, 5
	NOTE Fsh, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE G_, 4
	WAIT
	NOTE C_, 5
	NOTE G_, 5
	NOTE Ash, 5
	LEN 12
	NOTE Ash, 5
	NOTE A_, 5
	NOTE Gsh, 5
	LEN 36
	NOTE G_, 5
	WAIT
	LEN 12
	NOTE F_, 5
	NOTE G_, 5
	NOTE Gsh, 5
	LEN 36
	NOTE C_, 5
	WAIT
	LEN 24
	NOTE Gsh, 5
	LEN 12
	NOTE G_, 5
	NOTE G_, 5
	NOTE Gsh, 5
	NOTE G_, 5
	LEN 36
	NOTE D_, 5
	WAIT
	WAIT
	LEN 12
	NOTE Gsh, 5
	NOTE Ash, 5
	NOTE Gsh, 5
	NOTE Dsh, 5
	WAIT
	WAIT
	NOTE Gsh, 4
	NOTE Ash, 4
	NOTE C_, 5
	NOTE Gsh, 5
	WAIT
	NOTE G_, 5
	NOTE G_, 5
	WAIT
	WAIT
	WAIT
	NOTE Gsh, 5
	NOTE G_, 5
	NOTE F_, 5
	WAIT
	WAIT
	WAIT
	NOTE Dsh, 5
	NOTE D_, 5
	NEXT
DrumPat_58DC:
	db DRUM_LEVEL + 13, DRUM_TEMPO + 6, 9, 0, 9, 0, 9, 0
	db 9, 0, 10, 10, 10, 0, 9, 0
	db 10, 0, 10, 10, 9, 0, 10, 10
	db DRUM_TEMPO + 3, 10, 10, 10, 10, DRUM_TEMPO + 6, 9, 0
	db 9, 0, 9, 0, 9, 0, DRUM_TEMPO + 3, 10
	db 10, DRUM_TEMPO + 6, 10, 10, 0, 9, 0, 10
	db 0, 10, 10, 9, 0, 9, DRUM_TEMPO + 3, 10
	db 10, DRUM_TEMPO + 3, 10, 10, 10, 10, DRUM_LOOP
DrumPat_591B:
	db DRUM_LEVEL + 12, 1, 8, 8, 8, DRUM_LEVEL + 14, 9, DRUM_LEVEL + 12
	db 8, 8, 8, DRUM_LOOP

; Song 18: instrument table - (none set), arpeggio table 1 (the one SndInit sets)
PlaySong18:
	ld de, Song18_Ch1
	call StartMusicCh1
	ld de, Song18_Ch2
	call StartMusicCh2
	ld de, Song18_Ch3
	jp StartMusicCh3
Song18_Ch1:
	dw Pat_594F
	dw Pat_5955
	dw Pat_595B
	ORDER_LOOP Song18_Ch1
Song18_Ch2:
	dw Pat_59CB
Song18_Ch3:
	dw Pat_5A48
	dw Pat_5961
	dw Pat_5A57
	ORDER_LOOP Song18_Ch3
Pat_594F:
	TRANSPOSE $00
	PAT_CALL Pat_5964
	NEXT
Pat_5955:
	TRANSPOSE $01
	PAT_CALL Pat_5964
	NEXT
Pat_595B:
	TRANSPOSE $02
	PAT_CALL Pat_5964
	NEXT
Pat_5961:
	CH_TRANSPOSE $0C
	NEXT
Pat_5964:
	LEN 7
	HWENV $F2, $00
	ARP 23
	DUTY_50
	NOTE Fsh, 2
	WAIT
	NOTE Fsh, 2
	NOTE Fsh, 2
	WAIT
	NOTE Fsh, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE Fsh, 2
	WAIT
	NOTE Csh, 2
	NOTE Fsh, 2
	WAIT
	NOTE Fsh, 2
	NOTE Fsh, 2
	WAIT
	NOTE Fsh, 2
	NOTE A_, 2
	NOTE Gsh, 2
	NOTE G_, 2
	NOTE Fsh, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE Fsh, 2
	WAIT
	NOTE Fsh, 2
	NOTE Fsh, 2
	WAIT
	NOTE Fsh, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE Fsh, 2
	WAIT
	NOTE Csh, 2
	NOTE Fsh, 2
	WAIT
	NOTE Fsh, 2
	NOTE Fsh, 2
	WAIT
	NOTE Fsh, 2
	NOTE A_, 2
	NOTE Gsh, 2
	NOTE G_, 2
	NOTE Fsh, 2
	NOTE G_, 2
	NOTE Gsh, 2
	NOTE A_, 2
	WAIT
	NOTE A_, 2
	NOTE A_, 2
	WAIT
	NOTE A_, 2
	NOTE Ash, 2
	NOTE A_, 2
	NOTE Ash, 2
	NOTE A_, 2
	WAIT
	NOTE E_, 2
	NOTE A_, 2
	WAIT
	NOTE A_, 2
	NOTE A_, 2
	WAIT
	NOTE A_, 2
	NOTE C_, 3
	NOTE B_, 2
	NOTE Ash, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE Gsh, 2
	NOTE A_, 2
	WAIT
	NOTE A_, 2
	NOTE A_, 2
	WAIT
	NOTE A_, 2
	NOTE Ash, 2
	WAIT
	NOTE Ash, 2
	NOTE A_, 2
	WAIT
	NOTE E_, 2
	NOTE A_, 2
	WAIT
	NOTE A_, 2
	NOTE A_, 2
	WAIT
	NOTE A_, 2
	NOTE C_, 3
	NOTE B_, 2
	NOTE Ash, 2
	NOTE A_, 2
	NOTE Gsh, 2
	NOTE G_, 2
	NEXT
Pat_59CB:
	LEN 7
	AUTOPAN $07
	HWENV $F1, $03, $A2
	DUTY_75
	ARP 7
	NOTE Fsh, 4
	WAIT
	NOTE Fsh, 3
	NOTE Fsh, 4
	WAIT
	NOTE Fsh, 3
	ARP 6
	NOTE G_, 4
	WAIT
	NOTE G_, 3
	ARP 7
	NOTE Fsh, 4
	WAIT
	NOTE Fsh, 3
	NOTE Fsh, 4
	WAIT
	NOTE Fsh, 3
	NOTE Fsh, 4
	WAIT
	NOTE Fsh, 3
	ARP 6
	NOTE A_, 4
	NOTE Gsh, 4
	ARP 7
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE E_, 3
	NOTE F_, 3
	NOTE Fsh, 4
	WAIT
	NOTE Fsh, 3
	NOTE Fsh, 4
	WAIT
	NOTE Fsh, 3
	ARP 6
	NOTE G_, 4
	WAIT
	NOTE G_, 3
	ARP 7
	NOTE Fsh, 4
	WAIT
	NOTE Fsh, 3
	NOTE Fsh, 4
	WAIT
	NOTE Fsh, 3
	NOTE Fsh, 4
	WAIT
	NOTE Fsh, 3
	ARP 6
	NOTE A_, 4
	NOTE Gsh, 4
	ARP 7
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	ARP 7
	NOTE A_, 4
	WAIT
	NOTE A_, 3
	NOTE A_, 4
	WAIT
	NOTE A_, 3
	ARP 6
	NOTE Ash, 4
	WAIT
	NOTE Ash, 3
	ARP 7
	NOTE A_, 4
	WAIT
	NOTE A_, 3
	NOTE A_, 4
	WAIT
	NOTE A_, 3
	NOTE A_, 4
	WAIT
	NOTE A_, 3
	ARP 6
	NOTE C_, 5
	NOTE B_, 4
	ARP 7
	NOTE Ash, 4
	NOTE A_, 4
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE A_, 4
	WAIT
	NOTE A_, 3
	NOTE A_, 4
	WAIT
	NOTE A_, 3
	ARP 6
	NOTE Ash, 4
	WAIT
	NOTE Ash, 3
	ARP 7
	NOTE A_, 4
	WAIT
	NOTE A_, 3
	NOTE A_, 4
	WAIT
	NOTE A_, 3
	NOTE A_, 4
	WAIT
	NOTE A_, 3
	ARP 6
	NOTE C_, 5
	NOTE B_, 4
	ARP 7
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Gsh, 4
	NOTE G_, 4
	PAT_GOTO Pat_59CB
Pat_5A48:
	LEN 7
	DRUMS $07, DrumPat_5AB8
	VOLENV 15, $12, $1F, $11
	ARP 0
	CH_TRANSPOSE $00
	WAVE Wave_7B0D
Pat_5A57:
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Csh, 4
	NOTE D_, 4
	NOTE Csh, 4
	NOTE D_, 4
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Csh, 4
	WAIT
	WAIT
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Csh, 4
	NOTE D_, 4
	NOTE Csh, 4
	NOTE D_, 4
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE C_, 4
	NOTE Csh, 4
	NOTE Csh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE Csh, 4
	NOTE D_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE F_, 4
	NOTE E_, 4
	WAIT
	WAIT
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NEXT
DrumPat_5AB8:
	db 1, 6, 6, 2, 6, 6, DRUM_LOOP

; Song 7: instrument table 3, arpeggio table 1 (the one SndInit sets)
PlaySong7:
	ld a, $5D
	ld [wInstrTableHi], a
	ld a, $65
	ld [wInstrTable], a
	ld de, Song7_Ch1
	call StartMusicCh1
	ld de, Song7_Ch2
	call StartMusicCh2
	ld de, Song7_Ch3
	jp StartMusicCh3
Song7_Ch1:
	dw Pat_5AE1
Song7_Ch2:
	dw Pat_5B73
Song7_Ch3:
	dw Pat_5BFD
Pat_5AE1:
	HWENV $F1, $07, $A0
	ARP 0
	DUTY_50
	RELEASE $01, $50
	VIBRATO $07, $03, $04
	LEN 7
Pat_5AEF:
	DRUMS $07, DrumPat_5D2C
	REPEAT 8
	NOTE E_, 2
	WAIT
	NOTE E_, 3
	NOTE E_, 3
	REPEAT_END
	NOTE C_, 2
	WAIT
	REPEAT 7
	NOTE C_, 3
	NOTE C_, 3
	NOTE C_, 2
	WAIT
	REPEAT_END
	NOTE C_, 3
	NOTE B_, 2
	REPEAT 8
	NOTE A_, 2
	WAIT
	NOTE A_, 3
	NOTE A_, 3
	REPEAT_END
	REPEAT 4
	NOTE B_, 2
	WAIT
	NOTE B_, 3
	NOTE B_, 3
	REPEAT_END
	DRUMS $07, DrumPat_5D4F
	NOTE B_, 2
	WAIT
	WAIT
	NOTE Fsh, 2
	WAIT
	WAIT
	NOTE Dsh, 2
	WAIT
	NOTE B_, 1
	WAIT
	NOTE B_, 2
	NOTE C_, 3
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE Fsh, 2
	DRUMS $07, DrumPat_5D2C
	REPEAT 4
	NOTE C_, 2
	WAIT
	NOTE C_, 3
	NOTE C_, 3
	REPEAT_END
	REPEAT 4
	NOTE D_, 2
	WAIT
	NOTE D_, 3
	NOTE D_, 3
	REPEAT_END
	REPEAT 5
	NOTE E_, 2
	WAIT
	NOTE E_, 3
	NOTE E_, 3
	REPEAT_END
	NOTE Fsh, 2
	WAIT
	NOTE Fsh, 3
	NOTE Fsh, 3
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	NOTE G_, 3
	NOTE A_, 2
	WAIT
	NOTE B_, 2
	NOTE E_, 2
	REPEAT 4
	NOTE C_, 2
	WAIT
	NOTE C_, 3
	NOTE C_, 3
	REPEAT_END
	REPEAT 4
	NOTE D_, 2
	WAIT
	NOTE D_, 3
	NOTE D_, 3
	REPEAT_END
	REPEAT 4
	NOTE E_, 2
	WAIT
	NOTE E_, 3
	NOTE E_, 3
	REPEAT_END
	DRUMS $07, DrumPat_5D4F
	PAN_R
	NOTE E_, 3
	WAIT
	WAIT
	PAN_L
	NOTE B_, 2
	WAIT
	WAIT
	PAN_R
	NOTE G_, 2
	WAIT
	PAN_L
	NOTE E_, 2
	WAIT
	PAN_C
	NOTE E_, 2
	NOTE Fsh, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE Fsh, 2
	PAT_GOTO Pat_5AEF
Pat_5B73:
	LEN 7
Pat_5B74:
	AUTOPAN $07
	REPEAT 8
	INSTR 2
	NOTE E_, 4
	INSTR 0
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	REPEAT_END
	REPEAT 8
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	REPEAT_END
	REPEAT 8
	INSTR 2
	NOTE A_, 4
	INSTR 0
	NOTE Fsh, 5
	NOTE E_, 5
	NOTE Dsh, 5
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE B_, 4
	INSTR 0
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE E_, 5
	REPEAT_END
	NOTE B_, 5
	NOTE C_, 6
	NOTE B_, 5
	NOTE A_, 5
	NOTE Fsh, 5
	NOTE G_, 5
	NOTE Fsh, 5
	NOTE E_, 5
	NOTE Dsh, 5
	NOTE E_, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	INSTR 0
	NOTE G_, 4
	NOTE Fsh, 4
	REPEAT 4
	INSTR 2
	NOTE E_, 4
	INSTR 0
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	REPEAT_END
	REPEAT 4
	INSTR 2
	NOTE E_, 4
	INSTR 0
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	REPEAT_END
	REPEAT 3
	INSTR 2
	NOTE E_, 4
	INSTR 0
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	REPEAT_END
	INSTR 2
	NOTE E_, 4
	INSTR 0
	NOTE A_, 4
	INSTR 0
	NOTE G_, 4
	NOTE Fsh, 4
	REPEAT 4
	INSTR 2
	NOTE E_, 4
	INSTR 0
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	REPEAT_END
	REPEAT 4
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	REPEAT_END
	REPEAT 4
	INSTR 2
	NOTE E_, 4
	INSTR 0
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	REPEAT_END
	INSTR 2
	NOTE E_, 4
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	NOTE E_, 4
	WAIT
	INSTR 0
	NOTE G_, 4
	NOTE Fsh, 4
	INSTR 2
	NOTE E_, 4
	INSTR 0
	NOTE A_, 4
	NOTE G_, 4
	NOTE Fsh, 4
	PAT_GOTO Pat_5B74
Pat_5BFD:
	LEN 7
	VOLENV 13, $00, $1F, $1C
	VIBRATO $0E, $01, $04
	RELEASE $04, $01
	ARP 0
	WAVE Wave_7BCD
Pat_5C0D:
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
	NOTE Fsh, 4
	WAIT
	NOTE G_, 4
	WAIT
	ARP 26
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	ARP 0
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	NOTE Fsh, 4
	WAIT
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	ARP 26
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
	ARP 0
	NOTE B_, 4
	WAIT
	NOTE G_, 4
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
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE E_, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	WAIT
	ARP 26
	NOTE Ash, 4
	WAIT
	ARP 0
	NOTE B_, 4
	NOTE A_, 4
	ARP 26
	NOTE Ash, 4
	WAIT
	ARP 0
	NOTE B_, 4
	NOTE A_, 4
	NOTE B_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE A_, 4
	REST
	NOTE B_, 4
	WAIT
	NOTE A_, 4
	WAIT
	ARP 26
	NOTE Ash, 4
	WAIT
	ARP 0
	NOTE B_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	ARP 26
	NOTE Ash, 4
	WAIT
	ARP 0
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
	NOTE Fsh, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	NOTE Fsh, 4
	WAIT
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	NOTE Fsh, 4
	WAIT
	WAIT
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
	NOTE B_, 4
	WAIT
	NOTE E_, 5
	WAIT
	NOTE G_, 5
	WAIT
	ARP 26
	NOTE A_, 5
	WAIT
	ARP 0
	NOTE A_, 5
	NOTE G_, 5
	ARP 26
	NOTE G_, 5
	WAIT
	ARP 0
	NOTE G_, 5
	NOTE Fsh, 5
	ARP 26
	NOTE F_, 5
	WAIT
	ARP 0
	NOTE Fsh, 5
	NOTE E_, 5
	ARP 26
	NOTE E_, 5
	WAIT
	ARP 0
	NOTE E_, 5
	NOTE D_, 5
	NOTE E_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE Fsh, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE B_, 5
	WAIT
	ARP 26
	NOTE C_, 6
	WAIT
	WAIT
	WAIT
	ARP 0
	NOTE B_, 5
	WAIT
	WAIT
	WAIT
	NOTE A_, 5
	WAIT
	WAIT
	WAIT
	NOTE B_, 5
	WAIT
	WAIT
	WAIT
	NOTE E_, 5
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
	WAVE Wave_7ACD
	NOTE E_, 4
	WAIT
	WAIT
	NOTE B_, 3
	WAIT
	WAIT
	NOTE G_, 3
	WAIT
	NOTE E_, 3
	WAIT
	WAVE Wave_7BCD
	NOTE B_, 3
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	PAT_GOTO Pat_5C0D
DrumPat_5D2C:
	db DRUM_REPEAT + 3, 1, 0, 4, 6, 9, 0, 4
	db 6, 1, 0, 4, 6, 9, 0, 4
	db 10, DRUM_REPEAT_END, 1, 0, 4, 6, 9, 0
	db 4, 6, 1, 0, 4, 6, 9, 10
	db 9, 9, DRUM_LOOP
DrumPat_5D4F:
	db DRUM_PAN_R, 7, 0, 0, DRUM_PAN_L, 7, 0, 0
	db DRUM_PAN_R, 7, 0, DRUM_PAN_L, 7, 0, DRUM_PAN_R, 10
	db 10, DRUM_PAN_C, 9, 9, DRUM_PAN_L, 9, 9, DRUM_LOOP

; Instrument table 3, entries 1..3 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr3_0
	dw Instr3_1
	dw Instr3_2
Instr3_0:
	HWENV $60, $00
	DUTY_75
	END
Instr3_1:
	HWENV $F0, $03, $A2
	ARP 6
	END
Instr3_2:
	HWENV $F0, $03, $A2
	ARP 7
	END

; Song 1: instrument table 4, arpeggio table 1 (the one SndInit sets)
PlaySong1:
	ld a, $60
	ld [wInstrTableHi], a
	ld a, $9F
	ld [wInstrTable], a
	ld de, Song1_Ch1
	call StartMusicCh1
	ld de, Song1_Ch2
	call StartMusicCh2
	ld de, Song1_Ch3
	jp StartMusicCh3
Song1_Ch1:
	dw Pat_5DBA
	dw Pat_5DC0
Loop_5D9E:
	dw Pat_5DBA
	dw Pat_5E11
	dw Pat_5DBD
	dw Pat_5E11
	ORDER_LOOP Loop_5D9E
Song1_Ch2:
	dw Pat_5EDD
Loop_5DAC:
	dw Pat_5F2B
	ORDER_LOOP Loop_5DAC
Song1_Ch3:
	dw Pat_5F8B
Loop_5DB4:
	dw Pat_5FDB
	ORDER_LOOP Loop_5DB4
Pat_5DBA:
	TRANSPOSE $01
	NEXT
Pat_5DBD:
	TRANSPOSE $02
	NEXT
Pat_5DC0:
	LEN 7
	HWENV $C0, $38, $C7
	DUTY_75
	VIBRATO $0E, $01, $05
	RELEASE $01, $57
	NOTE D_, 3
	WAIT
	WAIT
	WAIT2
	NOTE D_, 3
	WAIT
	WAIT2
	NOTE Csh, 3
	NOTE D_, 3
	WAIT2
	NOTE G_, 3
	WAIT2
	NOTE B_, 3
	WAIT2
	NOTE D_, 4
	WAIT2
	NOTE C_, 4
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
	WAIT2
	NOTE D_, 3
	WAIT
	WAIT
	WAIT2
	NOTE D_, 3
	WAIT
	WAIT2
	NOTE Csh, 3
	NOTE D_, 3
	WAIT2
	NOTE G_, 3
	WAIT2
	NOTE B_, 3
	WAIT2
	NOTE D_, 4
	WAIT2
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
	INSTR 0
	RELEASE $00
	NOTE D_, 2
	WAIT
	NOTE E_, 2
	WAIT
	NOTE Fsh, 2
	WAIT
	NEXT
Pat_5E11:
	LEN 14
	DRUMS $07, DrumPat_60BD
	REPEAT 2
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE B_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE Csh, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE D_, 3
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE G_, 3
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 2
	NOTE E_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 2
	NOTE E_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
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
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 3
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE G_, 3
	INSTR 0
	NOTE A_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE C_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE D_, 3
	INSTR 1
	NOTE D_, 4
	REPEAT_END
	NEXT
Pat_5EDD:
	LEN 7
	HWENV $C0, $38, $C7
	DUTY_75
	VIBRATO $0E, $01, $05
	RELEASE $01, $57
	NOTE B_, 3
	WAIT
	WAIT
	WAIT2
	NOTE B_, 3
	WAIT
	WAIT2
	NOTE Ash, 3
	NOTE B_, 3
	WAIT2
	NOTE D_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE B_, 4
	WAIT2
	NOTE A_, 4
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
	WAIT2
	NOTE B_, 3
	WAIT
	WAIT
	WAIT2
	NOTE B_, 3
	WAIT
	WAIT2
	NOTE Ash, 3
	NOTE B_, 3
	WAIT2
	NOTE D_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE B_, 4
	WAIT2
	NOTE Csh, 5
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
	NEXT
Pat_5F2B:
	LEN 7
	AUTOPAN $04
	HWENV $60, $00
	VIBRATO $07, $01, $04
	DUTY_75
	RELEASE $05, $53
	ARP 22
	REPEAT 2
	WAIT
	WAIT
	PAT_CALL Pat_6027
	REPEAT_END
	AUTOPAN $00
	CH_TRANSPOSE $00
	RELEASE $00
	HWENV $C2, $07, $60
	REPEAT 2
	PAT_CALL Pat_607F
	NOTE G_, 4
	WAIT
	WAIT
	WAIT2
	NOTE G_, 4
	WAIT
	WAIT2
	NOTE Fsh, 4
	NOTE G_, 4
	WAIT2
	NOTE B_, 4
	WAIT2
	NOTE D_, 5
	WAIT2
	NOTE G_, 5
	WAIT2
	NOTE A_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE G_, 5
	NOTE F_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	REPEAT_END
	RELEASE $01, $52
	HWENV $60, $00
	ARP_OFF
	DUTY_75
	AUTOPAN $04
	CH_TRANSPOSE $0C
	WAIT
	WAIT
	PAT_CALL Pat_6050
	LEN 28
	NOTE D_, 3
	PAT_CALL Pat_6050
	NOTE D_, 4
	WAIT
	CH_TRANSPOSE $00
	NEXT
Pat_5F8B:
	LEN 7
	VOLENV 15, $11, $14, $10
	VIBRATO $0E, $01, $05
	RELEASE $03, $01
	WAVE Wave_7B0D
	NOTE G_, 3
	WAIT
	WAIT
	WAIT2
	NOTE G_, 3
	WAIT
	WAIT2
	NOTE Fsh, 3
	NOTE G_, 3
	WAIT2
	NOTE B_, 3
	WAIT2
	NOTE D_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE F_, 4
	WAIT
	WAIT
	WAIT
	NOTE F_, 4
	WAIT
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	NOTE C_, 4
	WAIT
	WAIT
	WAIT
	NOTE G_, 3
	WAIT
	WAIT
	WAIT2
	NOTE G_, 3
	WAIT
	WAIT2
	NOTE Fsh, 3
	NOTE G_, 3
	WAIT2
	NOTE B_, 3
	WAIT2
	NOTE D_, 4
	WAIT2
	NOTE G_, 4
	WAIT2
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	NOTE Csh, 4
	WAIT
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	NEXT
Pat_5FDB:
	LEN 7
	CH_TRANSPOSE $0C
	VOLENV 11, $13, $1F, $16
	ARP 0
	VIBRATO $07, $01, $04
	RELEASE $03, $01
	WAVE Wave_7BBD
	REPEAT 2
	PAT_CALL Pat_6027
	WAIT
	WAIT
	REPEAT_END
	WAVE Wave_7BED
	REPEAT 2
	CH_TRANSPOSE $00
	PAT_CALL Pat_607F
	CH_TRANSPOSE $0C
	LEN 28
	NOTE B_, 3
	LEN 21
	NOTE B_, 3
	LEN 7
	NOTE Ash, 3
	LEN 14
	NOTE B_, 3
	NOTE D_, 4
	NOTE G_, 4
	NOTE B_, 4
	LEN 28
	NOTE F_, 4
	LEN 21
	NOTE F_, 4
	LEN 7
	NOTE E_, 4
	LENGTH $38
	NOTE F_, 4
	REPEAT_END
	CH_TRANSPOSE $0C
	RELEASE $07, $02
	WAVE Wave_7BCD
	PAT_CALL Pat_6050
	LEN 28
	NOTE D_, 3
	PAT_CALL Pat_6050
	LEN 28
	NOTE D_, 4
	NEXT
Pat_6027:
	LEN 28
	NOTE D_, 4
	LEN 21
	NOTE G_, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE E_, 4
	NOTE C_, 4
	NOTE A_, 3
	WAIT
	NOTE D_, 4
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	LENGTH $38
	NOTE A_, 3
	LEN 28
	NOTE D_, 4
	LEN 21
	NOTE G_, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE E_, 4
	NOTE C_, 4
	NOTE A_, 3
	WAIT
	NOTE D_, 4
	NOTE B_, 3
	NOTE C_, 4
	NOTE Fsh, 3
	LEN 7
	NOTE G_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NEXT
Pat_6050:
	LEN 28
	NOTE D_, 3
	LEN 21
	NOTE G_, 3
	LEN 7
	NOTE D_, 3
	LEN 14
	NOTE E_, 3
	NOTE A_, 3
	LEN 21
	NOTE A_, 3
	LEN 7
	NOTE E_, 3
	LEN 14
	NOTE D_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE Fsh, 3
	LEN 21
	NOTE D_, 4
	LEN 7
	NOTE C_, 4
	LEN 14
	NOTE B_, 3
	NOTE G_, 3
	NOTE D_, 3
	NOTE B_, 3
	NOTE A_, 3
	LEN 7
	NOTE D_, 4
	NOTE B_, 3
	NOTE A_, 3
	WAIT
	NOTE G_, 3
	NOTE Fsh, 3
	LEN 14
	NOTE G_, 3
	NOTE E_, 3
	NOTE C_, 3
	NOTE G_, 3
	NOTE Fsh, 3
	LEN 7
	NOTE G_, 3
	NOTE A_, 3
	NEXT
Pat_607F:
	LEN 7
	NOTE G_, 4
	WAIT
	WAIT
	WAIT2
	NOTE G_, 4
	WAIT
	WAIT2
	NOTE Fsh, 4
	NOTE G_, 4
	WAIT2
	NOTE B_, 4
	WAIT2
	NOTE D_, 5
	WAIT2
	NOTE G_, 5
	WAIT2
	NOTE F_, 5
	WAIT
	WAIT
	NOTE E_, 5
	NOTE D_, 5
	WAIT2
	NOTE F_, 5
	WAIT2
	NOTE E_, 5
	WAIT2
	NOTE D_, 5
	WAIT2
	NOTE C_, 5
	WAIT2
	NOTE E_, 5
	WAIT2
	NEXT

; Instrument table 4, entries 1..3 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr4_0
	dw Instr4_1
	dw Instr4_2
Instr4_0:
	HWENV $F2, $07, $A0
	ARP 23
	END
Instr4_1:
	HWENV $F1, $04, $A2
	ARP 6
	AUTODUTY $04
	END
Instr4_2:
	HWENV $F1, $04, $A2
	ARP 7
	AUTODUTY $04
	END
DrumPat_60BD:
	db DRUM_LEVEL + 15, 7, 0, DRUM_LEVEL + 13, 0, 0, DRUM_LEVEL + 15, 9
	db 0, DRUM_LEVEL + 13, 4, 6, DRUM_REPEAT + 2, DRUM_LEVEL + 15, 1, 0
	db DRUM_LEVEL + 13, 4, 6, DRUM_LEVEL + 15, 9, 0, DRUM_LEVEL + 13, 4
	db 6, DRUM_REPEAT_END, DRUM_LEVEL + 15, 1, 0, DRUM_LEVEL + 13, 4, 6
	db DRUM_LEVEL + 15, 9, 0, DRUM_LEVEL + 13, 1, 6, DRUM_REPEAT + 3, DRUM_LEVEL + 15
	db 1, 0, DRUM_LEVEL + 13, 4, 6, DRUM_LEVEL + 15, 9, 0
	db DRUM_LEVEL + 13, 4, 6, DRUM_REPEAT_END, DRUM_LEVEL + 15, 1, 0, DRUM_LEVEL + 14
	db 9, 6, DRUM_LEVEL + 15, 9, 0, DRUM_LEVEL + 13, 4, DRUM_LEVEL + 15
	db 9, DRUM_LOOP

; Unreferenced (7 bytes)
	db $46, $01, $00, $44, $06, $06, $FF

; Song 8: instrument table 5, arpeggio table 1 (the one SndInit sets)
PlaySong8:
	ld a, $63
	ld [wInstrTableHi], a
	ld a, $60
	ld [wInstrTable], a
	ld de, Song8_Ch1
	call StartMusicCh1
	ld de, Song8_Ch3
	call StartMusicCh3
	ld de, Song8_Ch2
	jp StartMusicCh2
Song8_Ch1:
	dw Pat_6138
	dw Pat_6140
	dw Pat_6166
	ORDER_LOOP Song8_Ch1
Song8_Ch3:
	dw Pat_61E2
	ORDER_LOOP Song8_Ch3
Song8_Ch2:
	dw Pat_6264
	ORDER_LOOP Song8_Ch2
Pat_6138:
	LEN 14
	RELEASE $02, $00
	VIBRATO $07, $02, $05
Pat_6140:
	INSTR 0
	REPEAT 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE D_, 2
	INSTR 1
	NOTE G_, 4
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE F_, 4
	REPEAT_END
	INSTR 0
	NOTE E_, 2
	INSTR 2
	NOTE E_, 4
	INSTR 0
	NOTE B_, 2
	INSTR 2
	NOTE E_, 4
	INSTR 0
	NOTE E_, 2
	INSTR 2
	NOTE E_, 4
	INSTR 0
	NOTE Fsh, 2
	INSTR 2
	NOTE E_, 4
	NEXT
Pat_6166:
	INSTR 0
	NOTE G_, 2
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	WAIT
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 4
	INSTR 0
	NOTE A_, 2
	NOTE G_, 2
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	WAIT
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 4
	INSTR 0
	NOTE B_, 2
	NOTE C_, 3
	NOTE C_, 3
	INSTR 1
	NOTE C_, 5
	WAIT
	INSTR 0
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 5
	INSTR 0
	NOTE G_, 2
	NOTE C_, 3
	NOTE C_, 3
	INSTR 1
	NOTE C_, 5
	WAIT
	INSTR 0
	NOTE D_, 3
	WAIT
	INSTR 1
	NOTE D_, 5
	WAIT
	REPEAT 2
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 1
	LEN 7
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	LEN 14
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE F_, 2
	INSTR 1
	LEN 7
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	LEN 14
	NOTE C_, 3
	INSTR 1
	NOTE C_, 5
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 4
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE C_, 5
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	LEN 7
	NOTE Ash, 4
	INSTR 0
	NOTE Ash, 2
	LEN 14
	NOTE C_, 3
	INSTR 1
	NOTE C_, 5
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 4
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE C_, 5
	INSTR 0
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 4
	REPEAT_END
	NEXT
Pat_61E2:
	VOLENV 12, $11, $1F, $13
	VIBRATO $07, $01, $04
	ARP 0
	WAVE Wave_7B0D
	LEN 14
	REPEAT 2
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 3
	NOTE B_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 3
	NOTE B_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE C_, 3
	NOTE A_, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE C_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE E_, 3
	NOTE B_, 3
	NOTE E_, 3
	NOTE B_, 3
	NOTE Fsh, 3
	NOTE B_, 3
	REPEAT_END
	NOTE G_, 3
	NOTE G_, 3
	WAIT
	WAIT
	NOTE Csh, 4
	NOTE A_, 3
	NOTE E_, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE G_, 3
	WAIT
	WAIT
	NOTE Csh, 4
	NOTE A_, 3
	NOTE E_, 4
	WAIT
	NOTE C_, 4
	NOTE C_, 4
	WAIT
	WAIT
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE A_, 3
	NOTE D_, 4
	NOTE C_, 4
	NOTE C_, 4
	WAIT
	WAIT
	NOTE A_, 3
	NOTE Fsh, 3
	LEN 7
	NOTE D_, 4
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE D_, 4
	REPEAT 2
	LEN 14
	NOTE D_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE F_, 3
	NOTE D_, 4
	LEN 7
	NOTE G_, 3
	NOTE C_, 4
	LEN 14
	WAIT
	WAIT
	NOTE D_, 4
	NOTE G_, 3
	NOTE C_, 4
	NOTE F_, 3
	NOTE D_, 4
	LEN 7
	NOTE G_, 3
	NOTE C_, 4
	LEN 14
	WAIT
	WAIT
	NOTE G_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE Ash, 3
	NOTE G_, 4
	LEN 7
	NOTE C_, 4
	NOTE F_, 4
	LEN 14
	WAIT
	WAIT
	NOTE G_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE Ash, 3
	NOTE G_, 4
	NOTE C_, 4
	LEN 7
	NOTE F_, 4
	NOTE Ash, 3
	NOTE F_, 4
	NOTE D_, 4
	REPEAT_END
	NEXT
Pat_6264:
	LEN 7
	HWENV $F1, $04, $93
	DUTY_50
	VIBRATO $07, $01, $04
	DRUMS $07, DrumPat_6350
	REPEAT 2
	NOTE B_, 4
	WAIT
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	WAIT
	WAIT
	WAIT
	NOTE G_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	WAIT
	WAIT
	NOTE D_, 5
	NOTE Csh, 5
	WAIT
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	WAIT
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	NOTE B_, 4
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE B_, 4
	WAIT
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	WAIT
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	REPEAT_END
	DRUMS $07, DrumPat_6359
	WAIT
	WAIT
	NOTE G_, 4
	NOTE B_, 4
	NOTE D_, 5
	WAIT
	NOTE B_, 4
	WAIT
	NOTE Csh, 5
	WAIT
	NOTE A_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	WAIT
	NOTE G_, 4
	NOTE B_, 4
	NOTE D_, 5
	WAIT
	NOTE B_, 4
	WAIT
	NOTE Csh, 5
	WAIT
	NOTE A_, 4
	WAIT
	NOTE E_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE Fsh, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE A_, 4
	WAIT
	NOTE D_, 5
	WAIT
	WAIT
	WAIT
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE Fsh, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE A_, 5
	WAIT
	WAIT
	WAIT
	DRUMS $07, DrumPat_633F
	REPEAT 2
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE F_, 4
	WAIT
	NOTE G_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE F_, 4
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE F_, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE Ash, 4
	WAIT
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE Ash, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE F_, 4
	REPEAT_END
	NEXT
DrumPat_633F:
	db 1, 6, 4, 6, 1, 6, 4, 6
	db 1, 6, 4, 1, 0, 1, 4, 0
	db DRUM_LOOP
DrumPat_6350:
	db 1, 0, 6, 6, 4, 0, 6, 6
	db DRUM_LOOP
DrumPat_6359:
	db 1, 0, 1, 0, 4, 0, 6, 0
	db DRUM_LOOP

; Instrument table 5, entries 1..3 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr5_0
	dw Instr5_1
	dw Instr5_2
Instr5_0:
	HWENV $F1, $05, $70
	ARP 23
	END
Instr5_1:
	HWENV $F1, $05, $83
	ARP 6
	DUTY_75
	END
Instr5_2:
	HWENV $F1, $05, $83
	ARP 7
	DUTY_75
	END

; Song 10: instrument table 6, arpeggio table 1 (the one SndInit sets)
PlaySong10:
	ld a, $65
	ld [wInstrTableHi], a
	ld a, $4F
	ld [wInstrTable], a
	ld de, Song10_Ch1
	call StartMusicCh1
	ld de, Song10_Ch2
	call StartMusicCh2
	ld de, Song10_Ch3
	jp StartMusicCh3
Song10_Ch1:
	dw Pat_63B2
	dw Pat_63B2
	dw Pat_6492
	ORDER_LOOP Song10_Ch1
Song10_Ch2:
	dw Pat_63E9
	dw Pat_64F8
	ORDER_LOOP Song10_Ch2
Song10_Ch3:
	dw Pat_642C
	dw Pat_64FD
	ORDER_LOOP Song10_Ch3
Pat_63B2:
	LEN 7
	TRANSPOSE $01
	VIBRATO $07, $02, $04
	DRUMS $07, DrumPat_653F
	REPEAT 3
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	WAIT
	NOTE G_, 3
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 3
	WAIT
	INSTR 0
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE D_, 3
	WAIT
	REPEAT_END
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 3
	NOTE G_, 3
	NOTE G_, 3
	WAIT
	NOTE G_, 3
	WAIT
	INSTR 0
	NOTE Gsh, 2
	WAIT
	WAIT
	WAIT
	NOTE G_, 2
	WAIT
	NOTE D_, 2
	WAIT
	NEXT
Pat_63E9:
	LEN 7
	HWENV $D1, $02, $65
	DUTY_50
	VIBRATO $07, $01, $04
	ARP 24
	PAT_CALL Pat_6466
	NOTE E_, 5
	NOTE F_, 5
	WAIT
	NOTE A_, 5
	WAIT
	NOTE G_, 5
	WAIT
	WAIT
	NOTE D_, 5
	NOTE D_, 5
	WAIT
	WAIT
	WAIT
	INSTR 1
	NOTE Gsh, 3
	WAIT
	WAIT
	WAIT
	NOTE G_, 3
	WAIT
	WAIT
	HWENV $D1, $02, $65
	ARP 24
	WAIT
	PAT_CALL Pat_6466
	NOTE G_, 5
	NOTE A_, 5
	WAIT
	NOTE C_, 6
	WAIT
	NOTE B_, 5
	WAIT
	WAIT
	NOTE G_, 5
	NOTE G_, 5
	WAIT
	WAIT
	WAIT
	INSTR 1
	NOTE Gsh, 3
	WAIT
	WAIT
	WAIT
	NOTE G_, 3
	WAIT
	WAIT
	WAIT
	NEXT
Pat_642C:
	LEN 7
	VOLENV 11, $10, $1F, $13
	ARP 0
	WAVE Wave_7C0D
	PAT_CALL Pat_6466
	NOTE E_, 5
	NOTE F_, 5
	WAIT
	NOTE A_, 5
	WAIT
	NOTE G_, 5
	WAIT
	WAIT
	NOTE D_, 5
	NOTE D_, 5
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
	PAT_CALL Pat_6466
	NOTE G_, 5
	NOTE A_, 5
	WAIT
	NOTE C_, 6
	WAIT
	NOTE B_, 5
	WAIT
	WAIT
	NOTE G_, 5
	NOTE G_, 5
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
	NEXT
Pat_6466:
	NOTE F_, 5
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE F_, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE F_, 5
	WAIT
	NOTE D_, 5
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
	NOTE D_, 5
	NOTE E_, 5
	NOTE F_, 5
	WAIT
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	WAIT
	NOTE F_, 5
	NOTE E_, 5
	NOTE F_, 5
	WAIT
	NOTE F_, 5
	NEXT
Pat_6492:
	DRUMS $07, DrumPat_6533
	REPEAT 2
	INSTR 0
	NOTE Gsh, 2
	WAIT
	INSTR 1
	NOTE Gsh, 3
	NOTE Gsh, 3
	INSTR 0
	NOTE Dsh, 2
	WAIT
	INSTR 1
	NOTE Gsh, 3
	WAIT
	INSTR 0
	NOTE Gsh, 2
	WAIT
	INSTR 1
	NOTE Gsh, 3
	WAIT
	INSTR 0
	NOTE Dsh, 2
	WAIT
	INSTR 1
	NOTE Gsh, 3
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 3
	NOTE G_, 3
	INSTR 0
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE G_, 3
	WAIT
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 3
	WAIT
	INSTR 0
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE G_, 3
	WAIT
	INSTR 0
	NOTE Gsh, 2
	WAIT
	INSTR 1
	NOTE Gsh, 3
	NOTE Gsh, 3
	INSTR 0
	NOTE Dsh, 2
	WAIT
	INSTR 1
	NOTE Gsh, 3
	WAIT
	INSTR 0
	NOTE Gsh, 2
	WAIT
	INSTR 1
	NOTE Gsh, 3
	WAIT
	INSTR 0
	NOTE Dsh, 2
	WAIT
	INSTR 1
	NOTE Gsh, 3
	WAIT
	INSTR 0
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE D_, 4
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE D_, 4
	WAIT
	INSTR 0
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE D_, 4
	INSTR 0
	NOTE D_, 2
	NOTE E_, 2
	WAIT
	NOTE Fsh, 2
	WAIT
	REPEAT_END
	NEXT
Pat_64F8:
	ARP 24
	PAT_CALL Pat_6505
	NEXT
Pat_64FD:
	ARP_OFF
	VOLENV 10, $00, $00, $00
	WAVE Wave_7B0D
Pat_6505:
	REPEAT 2
	LEN 7
	NOTE Gsh, 4
	WAIT
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	WAIT
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 14
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	LEN 7
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE Gsh, 4
	WAIT
	NOTE Gsh, 4
	NOTE G_, 4
	LEN 14
	NOTE Gsh, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE Dsh, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE D_, 5
	REPEAT_END
	NEXT
DrumPat_6533:
	db DRUM_LEVEL + 12, 1, 0, 6, 0, DRUM_LEVEL + 14, 4, 0
	db DRUM_LEVEL + 12, 6, 0, DRUM_LOOP
DrumPat_653F:
	db DRUM_LEVEL + 12, 1, 0, 10, 9, 9, 0, 10
	db 0, 1, 0, 10, 0, 9, 0, 10
	db 0, DRUM_LOOP

; Instrument table 6, entries 1..2 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr6_0
	dw Instr6_1
Instr6_0:
	HWENV $F1, $07, $84
	ARP 23
	END
Instr6_1:
	HWENV $F1, $05, $62
	ARP 25
	END

; Song 5: instrument table 7, arpeggio table 1 (the one SndInit sets)
PlaySong5:
	ld a, $68
	ld [wInstrTableHi], a
	ld a, $B5
	ld [wInstrTable], a
	ld de, Song5_Ch1
	call StartMusicCh1
	ld de, Song5_Ch2
	call StartMusicCh2
	ld de, Song5_Ch3
	jp StartMusicCh3
Song5_Ch1:
	dw Pat_65A3
Loop_657F:
	dw Pat_65CE
	dw Pat_66F4
	dw Pat_66F4
	dw Pat_675F
	ORDER_LOOP Loop_657F
Song5_Ch2:
	dw Pat_65AB
Loop_658D:
	dw Pat_65E3
	dw Pat_6709
	dw Pat_678A
	dw Pat_67D5
	ORDER_LOOP Loop_658D
Song5_Ch3:
	dw Pat_65B1
Loop_659B:
	dw Pat_663B
	dw Pat_66B7
	ORDER_LOOP Loop_659B
Pat_65A3:
	LEN 14
	TRANSPOSE $02
	INSTR 4
	NOTE G_, 2
	NOTE D_, 3
	NOTE G_, 2
	NEXT
Pat_65AB:
	LEN 14
	INSTR 3
	NOTE G_, 2
	NOTE D_, 3
	NOTE G_, 2
	NEXT
Pat_65B1:
	VOLENV 15, $00, $1F, $11
	CH_TRANSPOSE $0C
	LEN 7
	DRUMS $07, DrumPat_6824
	WAVE Wave_7B2D
	GLIDE $FE
	PAN_L
	NOTE D_, 4
	WAIT
	PAN_R
	NOTE C_, 4
	WAIT
	PAN_L
	NOTE B_, 3
	PAN_R
	NOTE Ash, 3
	PAN_C
	GLIDE_OFF
	NEXT
Pat_65CE:
	LEN 14
	INSTR 4
	REPEAT 7
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE F_, 2
	REPEAT_END
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE B_, 2
	NOTE B_, 2
	NEXT
Pat_65E3:
	INSTR 3
	LEN 28
	NOTE D_, 2
	INSTR 2
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	WAIT
	LEN 14
	INSTR 1
	NOTE C_, 4
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE D_, 2
	INSTR 2
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	WAIT
	LEN 14
	NOTE E_, 4
	NOTE E_, 4
	INSTR 3
	LEN 28
	NOTE D_, 2
	INSTR 2
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	WAIT
	LEN 14
	INSTR 1
	NOTE C_, 4
	NOTE C_, 4
	INSTR 3
	LEN 28
	NOTE D_, 2
	INSTR 2
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	LEN 14
	WAIT
	NOTE D_, 4
	NOTE E_, 4
	NOTE E_, 4
	NEXT
Pat_661B:
	LEN 28
	NOTE D_, 4
	LEN 21
	NOTE F_, 4
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE A_, 3
	WAIT
	NOTE D_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE A_, 3
	LEN 7
	LEN 28
	NOTE D_, 4
	LEN 21
	NOTE F_, 4
	LEN 7
	NOTE E_, 4
	LEN 14
	NOTE F_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE A_, 3
	NEXT
Pat_663B:
	ARP 0
	WAVE Wave_7BED
	VOLENV 12, $10, $1F, $1F
	DRUMS $07, DrumPat_682B
	RELEASE $05, $02
	VIBRATO $0E, $01, $05
	PAT_CALL Pat_661B
	WAIT
	NOTE A_, 3
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	LEN 7
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	WAIT
	NOTE G_, 3
	WAIT
	PAT_CALL Pat_661B
	WAIT
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	LENGTH $38
	NOTE A_, 4
	PAT_CALL Pat_6692
	PAT_CALL Pat_668B
	PAT_CALL Pat_6692
	WAVE Wave_7B2D
	GLIDE $FE
	VOLENV 15, $00, $1F, $11
	LEN 7
	PAN_L
	NOTE D_, 4
	WAIT
	PAN_R
	NOTE C_, 4
	WAIT
	PAN_L
	NOTE B_, 3
	PAN_R
	NOTE Ash, 3
	PAN_C
	GLIDE_OFF
	DRUMS $07, DrumPat_682B
	NEXT
Pat_668B:
	LEN 42
	WAIT
	DRUMS $07, DrumPat_682B
	NEXT
Pat_6692:
	DRUMS $07, DrumPat_68AE
	RELEASE $05, $02
	LEN 14
	NOTE B_, 4
	WAIT
	NOTE C_, 5
	NOTE D_, 5
	WAIT
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	WAIT
	NOTE B_, 4
	NOTE A_, 4
	NOTE B_, 4
	LEN 28
	NOTE G_, 4
	NOTE A_, 4
	DRUMS $07, DrumPat_684B
	LENGTH $38
	NOTE D_, 4
	WAIT2
	RELEASE $00
	LENGTH $46
	WAIT
	NEXT
Pat_66B7:
	WAVE Wave_7B4D
	VOLENV 15, $00, $11, $11
	VIBRATO $07, $01, $04
	ARP_OFF
	RELEASE $00
	PAT_CALL Pat_66CC
	DRUMS $07, DrumPat_686C
Pat_66CC:
	LEN 28
	REPEAT 2
	NOTE D_, 4
	LEN 21
	NOTE A_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 5
	NOTE Csh, 5
	NOTE A_, 4
	NOTE E_, 4
	NOTE F_, 4
	LEN 28
	NOTE D_, 4
	LEN 21
	NOTE A_, 4
	LEN 7
	NOTE G_, 4
	LEN 14
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE E_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE B_, 4
	NOTE D_, 5
	LEN 28
	NOTE F_, 5
	NOTE E_, 5
	REPEAT_END
	NEXT
Pat_66F4:
	REPEAT 2
	NOTE G_, 2
	NOTE G_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE D_, 3
	NOTE D_, 3
	NOTE B_, 2
	NOTE B_, 2
	REPEAT_END
	REPEAT 2
	NOTE D_, 2
	NOTE D_, 2
	NOTE F_, 2
	NOTE F_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE F_, 2
	NOTE F_, 2
	REPEAT_END
	NEXT
Pat_6709:
	REPEAT 2
	LEN 7
	INSTR 1
	NOTE G_, 4
	WAIT
	INSTR 0
	PAN_R
	NOTE G_, 3
	NOTE G_, 3
	INSTR 1
	NOTE G_, 4
	WAIT
	INSTR 0
	PAN_L
	NOTE B_, 3
	NOTE B_, 3
	INSTR 1
	NOTE G_, 4
	WAIT
	INSTR 0
	PAN_R
	NOTE D_, 4
	NOTE D_, 4
	INSTR 1
	NOTE G_, 4
	WAIT
	INSTR 0
	PAN_L
	NOTE G_, 4
	NOTE G_, 4
	INSTR 1
	NOTE G_, 4
	WAIT
	INSTR 0
	PAN_R
	NOTE G_, 3
	NOTE G_, 3
	INSTR 1
	NOTE G_, 4
	WAIT
	INSTR 0
	PAN_L
	NOTE B_, 3
	NOTE B_, 3
	INSTR 1
	NOTE G_, 4
	WAIT
	INSTR 0
	PAN_R
	NOTE D_, 4
	NOTE D_, 4
	INSTR 1
	NOTE G_, 4
	WAIT
	INSTR 0
	PAN_L
	LEN 14
	NOTE G_, 3
	NOTE D_, 3
	NOTE D_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 0
	PAN_R
	NOTE D_, 3
	NOTE A_, 3
	NOTE G_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 0
	PAN_L
	NOTE C_, 3
	NOTE D_, 3
	NOTE D_, 3
	INSTR 2
	NOTE D_, 4
	INSTR 0
	PAN_R
	NOTE D_, 3
	NOTE A_, 3
	NOTE A_, 3
	INSTR 2
	NOTE D_, 4
	NOTE D_, 4
	REPEAT_END
	NEXT
Pat_675F:
	REPEAT 4
	INSTR 4
	PAT_CALL Pat_6778
	NOTE D_, 2
	NOTE A_, 2
	NOTE A_, 2
	INSTR 1
	NOTE A_, 4
	INSTR 4
	NOTE A_, 2
	PAT_CALL Pat_6778
	NOTE G_, 2
	NOTE Ash, 2
	INSTR 1
	NOTE Ash, 4
	INSTR 4
	NOTE A_, 2
	INSTR 1
	NOTE A_, 4
	REPEAT_END
	NEXT
Pat_6778:
	NOTE D_, 2
	NOTE D_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 4
	NOTE F_, 2
	NOTE A_, 2
	NOTE A_, 2
	INSTR 2
	NOTE D_, 4
	INSTR 4
	NOTE F_, 2
	NOTE G_, 2
	NOTE G_, 2
	INSTR 2
	NOTE G_, 4
	INSTR 4
	NEXT
Pat_678A:
	ARP_OFF
	HWENV $40, $00
	DUTY_50
	PAN_L
	REPEAT 2
	LEN 7
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE B_, 4
	WAIT
	NOTE G_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE Csh, 5
	WAIT
	NOTE A_, 4
	WAIT
	NOTE E_, 4
	WAIT
	NOTE F_, 4
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	WAIT
	NOTE C_, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE D_, 5
	WAIT
	NOTE B_, 4
	WAIT
	NOTE D_, 5
	WAIT
	NOTE F_, 5
	WAIT
	WAIT
	WAIT
	NOTE E_, 5
	WAIT
	WAIT
	REPEAT_END
	PAN_C
	NEXT
Pat_67D5:
	INSTR 0
	REPEAT 2
	PAN_R
	NOTE D_, 3
	WAIT
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	WAIT
	PAN_L
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	WAIT
	PAN_R
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	WAIT
	NOTE C_, 4
	WAIT
	PAN_L
	NOTE B_, 3
	WAIT
	NOTE B_, 3
	NOTE C_, 4
	NOTE B_, 3
	NOTE A_, 3
	NOTE G_, 3
	WAIT
	PAN_R
	NOTE A_, 3
	WAIT
	NOTE A_, 3
	NOTE Ash, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE E_, 3
	PAN_L
	NOTE D_, 3
	WAIT
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	WAIT
	PAN_R
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	WAIT
	PAN_L
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	WAIT
	NOTE C_, 4
	WAIT
	PAN_R
	NOTE D_, 4
	WAIT
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	PAN_L
	NOTE F_, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	REPEAT_END
	PAN_C
	NEXT
DrumPat_6824:
	db 9, 0, 9, 0, 9, 9, DRUM_LOOP
DrumPat_682B:
	db 7, 0, 0, 0, 9, 0, 6, 0
	db 1, 0, 6, 0, 9, 0, 4, 0
	db 1, 0, 6, 0, 9, 0, 6, 0
	db 1, 0, 6, 0, 9, 0, 9, 0
DrumPat_684B:
	db 1, 0, 6, 0, 9, 0, 6, 0
	db 1, 0, 6, 0, 9, 0, 4, 0
	db 1, 0, 6, 0, 9, 0, 6, 0
	db 1, 0, 6, 6, 9, 0, 9, 9
	db DRUM_LOOP
DrumPat_686C:
	db DRUM_PAN_C, 7, 0, 0, 0, 9, 0, 6
	db 6, 1, 0, 6, 6, 9, 0, 4
	db 6, 1, 0, 6, 6, 9, 0, 6
	db 6, 1, 0, 6, 6, 9, 0, 9
	db 6, 1, 0, 6, 6, 9, 0, 6
	db 6, 1, 0, 6, 6, 9, 0, 4
	db 6, 1, 0, 6, 6, 9, 0, 6
	db 6, 1, 0, 6, 6, 9, 0, 9
	db 9, DRUM_LOOP
DrumPat_68AE:
	db 1, 0, 6, 6, 9, 0, 6, 6
	db DRUM_LOOP

; Instrument table 7, entries 1..5 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr7_0
	dw Instr7_1
	dw Instr7_2
	dw Instr7_3
	dw Instr7_4
Instr7_0:
	HWENV $F1, $02, $44
	DUTY_75
	ARP 1
	END
Instr7_1:
	HWENV $F2, $04, $82
	DUTY_75
	ARP 6
	PAN_C
	END
Instr7_2:
	HWENV $F2, $04, $82
	DUTY_75
	ARP 7
	PAN_C
	END
Instr7_3:
	HWENV $F1, $0E, $F1
	DUTY_12
	ARP 1
	END
Instr7_4:
	ARP 0
	HWENV $F1, $07, $52
	END

; Song 11: instrument table 8, arpeggio table 1 (the one SndInit sets)
PlaySong11:
	ld a, $6B
	ld [wInstrTableHi], a
	ld a, $0E
	ld [wInstrTable], a
	ld de, Song11_Ch1
	call StartMusicCh1
	ld de, Song11_Ch3
	call StartMusicCh3
	ld de, Song11_Ch2
	jp StartMusicCh2
Song11_Ch1:
	dw Pat_698D
	dw Pat_69B0
	dw Pat_698D
	dw Pat_69B6
	ORDER_LOOP Song11_Ch1
Song11_Ch3:
	dw Pat_6938
	dw Pat_69E6
	dw Pat_6A30
	dw Pat_6A30
	dw Pat_6935
	dw Pat_69E6
	dw Pat_6A30
	dw Pat_6A5D
	ORDER_LOOP Song11_Ch3
Song11_Ch2:
	dw Pat_6A99
	dw Pat_6AB3
	dw Pat_6AC1
	dw Pat_6AE9
	dw Pat_6A99
	dw Pat_6AB3
	dw Pat_6AC1
	dw Pat_6AE9
	ORDER_LOOP Song11_Ch2
Pat_6935:
	CH_TRANSPOSE $18
	NEXT
Pat_6938:
	CH_TRANSPOSE $0C
	NEXT
Pat_693B:
	LEN 18
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE B_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	LEN 9
	NOTE E_, 2
	NOTE Fsh, 2
	NOTE G_, 2
	WAIT
	NOTE Fsh, 2
	NOTE E_, 2
	LEN 18
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE G_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NOTE C_, 2
	NEXT
Pat_695F:
	LEN 18
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	LEN 9
	NOTE A_, 2
	NOTE B_, 2
	NOTE C_, 3
	WAIT
	NOTE B_, 2
	NOTE A_, 2
	LEN 18
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	LEN 9
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE Fsh, 2
	NOTE E_, 2
	NOTE D_, 2
	LEN 18
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE B_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	LEN 9
	NOTE E_, 2
	NOTE Fsh, 2
	NOTE G_, 2
	WAIT
	NEXT
Pat_698D:
	DRUMS $09, DrumPat_6B3B
	HWENV $F2, $09, $95
	VIBRATO $09, $08, $04
	ARP 23
	RELEASE $02, $40
	DUTY_50
	PAT_CALL Pat_693B
	NOTE C_, 2
	NOTE D_, 2
	NOTE Dsh, 2
	PAT_CALL Pat_693B
	NOTE E_, 2
	NOTE G_, 2
	NOTE Gsh, 2
	PAT_CALL Pat_695F
	NOTE A_, 2
	NOTE B_, 2
	NEXT
Pat_69B0:
	PAT_CALL Pat_695F
	NOTE G_, 2
	NOTE Fsh, 2
	NEXT
Pat_69B6:
	LEN 18
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	NOTE A_, 2
	LEN 9
	NOTE A_, 2
	NOTE B_, 2
	NOTE C_, 3
	WAIT
	NOTE B_, 2
	NOTE A_, 2
	LEN 18
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE B_, 2
	LEN 9
	NOTE B_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE Fsh, 2
	NOTE E_, 2
	NOTE D_, 2
	LEN 18
	NOTE E_, 2
	NOTE E_, 2
	WAIT
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	WAIT
	NOTE G_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE E_, 2
	LEN 9
	NOTE E_, 2
	NOTE Fsh, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 2
	NOTE Fsh, 2
	NEXT
Pat_69E6:
	LEN 9
	WAVE Wave_7C0D
	INSTR 4
	REPEAT 4
	NOTE E_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE E_, 4
	INSTR 1
	NOTE E_, 3
	INSTR 4
	NOTE E_, 4
	NOTE B_, 3
	NOTE G_, 3
	REPEAT_END
	REPEAT 3
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	NOTE G_, 3
	NOTE E_, 3
	REPEAT_END
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	NOTE B_, 3
	NOTE G_, 3
	REPEAT 4
	NOTE E_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE E_, 4
	INSTR 1
	NOTE E_, 3
	INSTR 4
	NOTE E_, 4
	NOTE B_, 3
	NOTE G_, 3
	REPEAT_END
	REPEAT 3
	NOTE C_, 3
	NOTE E_, 3
	NOTE G_, 3
	NOTE C_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 4
	NOTE C_, 4
	NOTE G_, 3
	NOTE E_, 3
	REPEAT_END
	NOTE C_, 3
	NOTE E_, 3
	NOTE E_, 3
	NOTE E_, 3
	INSTR 0
	NOTE C_, 3
	INSTR 4
	NOTE G_, 3
	NOTE Gsh, 3
	NOTE Gsh, 3
	NEXT
Pat_6A30:
	REPEAT 2
	NOTE A_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE A_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE C_, 4
	REPEAT_END
	NOTE B_, 3
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE B_, 4
	INSTR 0
	NOTE B_, 3
	INSTR 4
	NOTE B_, 4
	NOTE Fsh, 4
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE B_, 4
	INSTR 0
	NOTE B_, 3
	INSTR 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	REPEAT 4
	NOTE E_, 3
	NOTE G_, 3
	NOTE B_, 3
	NOTE E_, 4
	INSTR 1
	NOTE E_, 3
	INSTR 4
	NOTE E_, 4
	NOTE B_, 3
	NOTE G_, 3
	REPEAT_END
	NEXT
Pat_6A5D:
	REPEAT 2
	NOTE A_, 3
	NOTE C_, 4
	NOTE E_, 4
	NOTE A_, 4
	INSTR 1
	NOTE A_, 3
	INSTR 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE C_, 4
	REPEAT_END
	NOTE B_, 3
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE B_, 4
	INSTR 0
	NOTE B_, 3
	INSTR 4
	NOTE B_, 4
	NOTE Fsh, 4
	NOTE Dsh, 4
	NOTE B_, 3
	NOTE Dsh, 4
	NOTE Fsh, 4
	NOTE B_, 4
	INSTR 0
	NOTE B_, 3
	INSTR 4
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	VOLENV 15, $11, $1F, $1F
	WAVE Wave_7ACD
	CH_TRANSPOSE $00
	LENGTH $B4
	NOTE E_, 3
	CH_TRANSPOSE $18
	WAVE Wave_7C0D
	INSTR 1
	LEN 18
	NOTE E_, 3
	WAIT
	WAIT
	NOTE E_, 3
	NOTE E_, 3
	LEN 9
	WAIT
	NOTE E_, 3
	NEXT
Pat_6A99:
	VIBRATO $24, $02, $04
	INSTR 2
	LENGTH $90
	NOTE E_, 4
	LENGTH $6C
	NOTE E_, 4
	LEN 36
	INSTR 3
	NOTE D_, 4
	LENGTH $90
	NOTE C_, 4
	LENGTH $48
	NOTE C_, 5
	INSTR 2
	LEN 36
	NOTE A_, 4
	INSTR 3
	NOTE F_, 4
	NEXT
Pat_6AB3:
	INSTR 2
	LENGTH $90
	NOTE E_, 4
	LENGTH $48
	NOTE E_, 4
	INSTR 3
	NOTE D_, 4
	LENGTH $90
	NOTE C_, 4
	NOTE C_, 5
	NEXT
Pat_6AC1:
	ARP 0
	AUTODUTY $00
	DUTY_50
	HWENV $C0, $24, $C7
	LENGTH $5A
	NOTE E_, 4
	LEN 9
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	WAIT
	NOTE Fsh, 4
	NOTE E_, 4
	LENGTH $5A
	NOTE Fsh, 4
	LEN 9
	NOTE Fsh, 4
	NOTE G_, 4
	NOTE Fsh, 4
	WAIT
	NOTE E_, 4
	NOTE D_, 4
	LEN 36
	NOTE E_, 4
	LENGTH $6C
	NOTE B_, 3
	LENGTH $48
	INSTR 2
	NOTE E_, 4
	INSTR 3
	NOTE D_, 4
	NEXT
Pat_6AE9:
	ARP 0
	AUTODUTY $00
	DUTY_50
	HWENV $C0, $24, $C7
	LENGTH $5A
	NOTE E_, 4
	LEN 9
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE G_, 4
	WAIT
	NOTE Fsh, 4
	NOTE E_, 4
	LENGTH $5A
	NOTE Fsh, 4
	LEN 9
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	WAIT
	NOTE A_, 4
	NOTE G_, 4
	LENGTH $90
	NOTE E_, 4
	LENGTH $6C
	INSTR 2
	NOTE E_, 4
	LEN 36
	INSTR 3
	NOTE G_, 4
	NEXT

; Instrument table 8, entries 1..5 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr8_0
	dw Instr8_1
	dw Instr8_2
	dw Instr8_3
	dw Instr8_4
Instr8_2:
	HWENV $5F, $35, $C7
	ARP 7
	AUTODUTY $09
	END
Instr8_3:
	HWENV $5F, $35, $C7
	ARP 6
	AUTODUTY $09
	END
Instr8_4:
	VOLENV 11, $11, $1F, $11
	END
Instr8_1:
	VOLENV 15, $13, $1F, $11
	ARP 7
	END
Instr8_0:
	VOLENV 15, $13, $1F, $11
	ARP 6
	END
DrumPat_6B3B:
	db 7, 0, 0, 0, 9, 10, 8, 0
	db 1, 0, 8, 0, 9, 10, 1, 0
	db 1, 0, 8, 0, 9, 10, 8, 1
	db 1, 0, 8, 0, 9, 10, 8, 9
	db 1, 0, 8, 0, 9, 10, 8, 0
	db 1, 0, 8, 0, 9, 10, 1, 0
	db 1, 0, 8, 0, 9, 10, 8, 1
	db 1, 0, 9, 0, 9, 10, 8, 9
	db 7, 0, 0, 0, 9, 10, 8, 0
	db 1, 0, 8, 0, 9, 10, 1, 0
	db 1, 0, 8, 0, 9, 10, 8, 1
	db 1, 0, 8, 0, 9, 10, 8, 9
	db 1, 0, 8, 0, 9, 10, 8, 0
	db 1, 0, 8, 0, 9, 10, 1, 0
	db 1, 0, 8, 0, 9, 10, 8, 1
	db 1, 0, DRUM_TEMPO + 4, 10, 10, DRUM_TEMPO + 5, 10, 10
	db DRUM_TEMPO + 9, 9, 9, 9, 9, DRUM_LOOP

; Song 12: instrument table 9, arpeggio table 1 (the one SndInit sets)
PlaySong12:
	ld a, $6D
	ld [wInstrTableHi], a
	ld a, $2D
	ld [wInstrTable], a
	ld de, Song12_Ch1
	call StartMusicCh1
	ld de, Song12_Ch3
	call StartMusicCh3
	ld de, Song12_Ch2
	jp StartMusicCh2
Song12_Ch1:
	dw Pat_6BE9
	dw Pat_6BF3
	dw Pat_6BEC
	dw Pat_6BF3
	ORDER_LOOP Song12_Ch1
Pat_6BE9:
	TRANSPOSE $02
	NEXT
Pat_6BEC:
	TRANSPOSE $03
	NEXT
Song12_Ch3:
	dw Pat_6C42
Song12_Ch2:
	dw Pat_6CAC
Pat_6BF3:
	LEN 8
	HWENV $F1, $04, $A0
	ARP 23
	VIBRATO $07, $03, $04
	DUTY_50
	RELEASE $04, $A1
	NOTE Gsh, 2
	WAIT
	WAIT
	NOTE Dsh, 2
	WAIT
	WAIT
	NOTE Gsh, 2
	WAIT
	NOTE Ash, 2
	WAIT
	WAIT
	NOTE F_, 2
	WAIT
	WAIT
	NOTE Ash, 2
	WAIT
	NOTE C_, 3
	WAIT
	WAIT
	NOTE G_, 2
	WAIT
	WAIT
	NOTE C_, 3
	WAIT
	NOTE Ash, 2
	WAIT
	WAIT
	NOTE F_, 2
	WAIT
	WAIT
	NOTE Ash, 2
	WAIT
	NOTE Gsh, 2
	WAIT
	WAIT
	NOTE Dsh, 2
	WAIT
	WAIT
	NOTE Gsh, 2
	WAIT
	NOTE Ash, 2
	WAIT
	WAIT
	NOTE F_, 2
	WAIT
	WAIT
	NOTE Ash, 2
	WAIT
	NOTE C_, 3
	WAIT
	WAIT
	NOTE G_, 2
	WAIT
	WAIT
	NOTE C_, 3
	WAIT
	NOTE Csh, 3
	WAIT
	NOTE Gsh, 2
	NOTE Csh, 3
	NOTE Dsh, 3
	NOTE Ash, 2
	NOTE G_, 2
	NOTE Dsh, 2
	NEXT
Pat_6C42:
	LEN 8
	WAVE Wave_7AED
	INSTR 2
	NOTE Gsh, 3
	NOTE C_, 4
	INSTR 0
	NOTE Gsh, 3
	INSTR 2
	NOTE Dsh, 3
	NOTE Gsh, 3
	NOTE C_, 4
	INSTR 0
	NOTE Gsh, 3
	INSTR 2
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE Csh, 4
	INSTR 1
	NOTE Ash, 3
	INSTR 2
	NOTE F_, 3
	NOTE Ash, 3
	NOTE Csh, 4
	INSTR 1
	NOTE Ash, 3
	INSTR 2
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Dsh, 4
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE G_, 3
	NOTE C_, 4
	NOTE Dsh, 4
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE C_, 4
	NOTE Ash, 3
	NOTE Csh, 4
	INSTR 1
	NOTE Ash, 3
	INSTR 2
	NOTE F_, 3
	NOTE Ash, 3
	NOTE Csh, 4
	INSTR 1
	NOTE Ash, 3
	INSTR 2
	NOTE Ash, 3
	NOTE Gsh, 3
	NOTE C_, 4
	INSTR 0
	NOTE Gsh, 3
	INSTR 2
	NOTE Dsh, 3
	NOTE Gsh, 3
	NOTE C_, 4
	INSTR 0
	NOTE Gsh, 3
	INSTR 2
	NOTE Gsh, 3
	NOTE Ash, 3
	NOTE Csh, 4
	INSTR 1
	NOTE Ash, 3
	INSTR 2
	NOTE F_, 3
	NOTE Ash, 3
	NOTE Csh, 4
	INSTR 1
	NOTE Ash, 3
	INSTR 2
	NOTE Ash, 3
	NOTE C_, 4
	NOTE Dsh, 4
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE G_, 3
	NOTE C_, 4
	NOTE Dsh, 4
	INSTR 1
	NOTE C_, 4
	INSTR 2
	NOTE C_, 4
	NOTE Csh, 4
	NOTE F_, 4
	INSTR 0
	NOTE Csh, 4
	INSTR 2
	NOTE G_, 4
	INSTR 0
	NOTE Dsh, 4
	INSTR 2
	NOTE F_, 4
	INSTR 0
	NOTE Dsh, 4
	INSTR 2
	NOTE Dsh, 4
	PAT_GOTO Pat_6C42
Pat_6CAC:
	LEN 8
	DRUMS $08, DrumPat_6CFB
	HWENV $91, $02, $52
	DUTY_75
	AUTOPAN $04
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE Gsh, 5
	NOTE C_, 6
	NOTE Gsh, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Csh, 5
	NOTE F_, 5
	NOTE Ash, 5
	NOTE Csh, 6
	NOTE Ash, 5
	NOTE F_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE Dsh, 6
	NOTE C_, 6
	NOTE G_, 5
	NOTE Dsh, 5
	NOTE Ash, 4
	NOTE Csh, 5
	NOTE F_, 5
	NOTE Ash, 5
	NOTE Csh, 6
	NOTE Ash, 5
	NOTE F_, 5
	NOTE Csh, 5
	NOTE Gsh, 4
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE Gsh, 5
	NOTE C_, 6
	NOTE Gsh, 5
	NOTE Dsh, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE Csh, 5
	NOTE F_, 5
	NOTE Ash, 5
	NOTE Csh, 6
	NOTE Ash, 5
	NOTE F_, 5
	NOTE Csh, 5
	NOTE C_, 5
	NOTE Dsh, 5
	NOTE G_, 5
	NOTE C_, 6
	NOTE Dsh, 6
	NOTE C_, 6
	NOTE G_, 5
	NOTE Dsh, 5
	NOTE Csh, 5
	NOTE F_, 5
	NOTE Gsh, 5
	NOTE Csh, 6
	NOTE Dsh, 5
	NOTE G_, 5
	NOTE Ash, 5
	NOTE Dsh, 6
	PAT_GOTO Pat_6CAC
DrumPat_6CFB:
	db DRUM_LEVEL + 14, 7, 0, 9, 6, 1, 6, 9
	db 6, 1, 6, 9, 1, 6, 1, 9
	db 6, DRUM_REPEAT + 2, 1, 6, 9, 6, 1, 6
	db 9, 6, 1, 6, 9, 1, 6, 1
	db 9, 6, DRUM_REPEAT_END, 1, 6, 9, 6, 1
	db 6, 9, 6, 1, 6, 7, 0, 7
	db 0, 7, 0, DRUM_LOOP

; Instrument table 9, entries 1..3 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr9_0
	dw Instr9_1
	dw Instr9_2
Instr9_0:
	VOLENV 15, $11, $1F, $11
	ARP 6
	CH_TRANSPOSE $0C
	END
Instr9_1:
	VOLENV 15, $11, $1F, $11
	ARP 7
	CH_TRANSPOSE $0C
	END
Instr9_2:
	VOLENV 15, $12, $25, $11
	ARP 0
	CH_TRANSPOSE $00
	END

; Song 6: instrument table 10, arpeggio table 1 (the one SndInit sets)
PlaySong6:
	ld a, $70
	ld [wInstrTableHi], a
	ld a, $DB
	ld [wInstrTable], a
	ld de, Song6_Ch1
	call StartMusicCh1
	ld de, Song6_Ch2
	call StartMusicCh2
	ld de, Song6_Ch3
	jp StartMusicCh3
Song6_Ch1:
	dw Pat_6D6F
Song6_Ch2:
	dw Pat_6EE0
Song6_Ch3:
	dw Pat_6F7A
Pat_6D6F:
	LEN 44
	TRANSPOSE $03
	HWENV $00, $00
	REPEAT 4
	REST
	REPEAT_END
	LEN 11
	VIBRATO $0A, $04, $05
	RELEASE $02, $11
Pat_6D80:
	PAT_CALL Pat_6E8D
	PAT_CALL Pat_6ED5
	PAT_CALL Pat_6E8D
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE E_, 2
	INSTR 0
	NOTE A_, 2
	WAIT
	NOTE A_, 2
	NOTE B_, 2
	NOTE B_, 2
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 3
	NOTE C_, 3
	WAIT
	INSTR 0
	NOTE G_, 2
	NOTE B_, 2
	WAIT
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 2
	INSTR 0
	NOTE C_, 3
	NOTE B_, 2
	NOTE C_, 3
	NOTE B_, 2
	NOTE C_, 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE F_, 2
	NOTE G_, 2
	WAIT
	INSTR 0
	NOTE D_, 2
	NOTE F_, 2
	WAIT
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE D_, 2
	NOTE G_, 2
	WAIT
	INSTR 0
	NOTE D_, 2
	NOTE G_, 2
	NOTE B_, 2
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE E_, 2
	NOTE A_, 2
	WAIT
	INSTR 0
	NOTE E_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE G_, 2
	INSTR 0
	NOTE E_, 2
	WAIT
	NOTE A_, 2
	WAIT
	NOTE G_, 2
	NOTE E_, 2
	WAIT
	WAIT
	INSTR 1
	NOTE D_, 2
	NOTE E_, 2
	WAIT
	INSTR 0
	NOTE D_, 2
	WAIT
	NOTE E_, 2
	WAIT
	NOTE G_, 2
	NOTE E_, 2
	WAIT
	INSTR 1
	NOTE E_, 2
	INSTR 0
	NOTE G_, 2
	WAIT
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 2
	NOTE F_, 2
	WAIT
	INSTR 0
	NOTE C_, 2
	NOTE E_, 2
	WAIT
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE C_, 2
	INSTR 0
	NOTE F_, 2
	NOTE E_, 2
	NOTE F_, 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 2
	NOTE G_, 2
	WAIT
	INSTR 0
	NOTE D_, 2
	NOTE F_, 2
	WAIT
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE D_, 2
	NOTE G_, 2
	WAIT
	INSTR 0
	NOTE D_, 2
	NOTE G_, 2
	NOTE B_, 2
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE E_, 2
	NOTE A_, 2
	WAIT
	INSTR 0
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE E_, 2
	INSTR 0
	LEN 22
	NOTE D_, 2
	NOTE E_, 2
	LEN 11
	NOTE G_, 2
	LENGTH $8F
	NOTE A_, 2
	LEN 11
	NOTE D_, 2
	NOTE E_, 2
	NOTE G_, 2
	REPEAT 2
	INSTR 0
	NOTE C_, 3
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 2
	NOTE G_, 2
	WAIT
	INSTR 0
	NOTE E_, 2
	WAIT
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 2
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE A_, 2
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE E_, 2
	INSTR 0
	NOTE C_, 3
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 2
	NOTE G_, 2
	WAIT
	INSTR 0
	NOTE E_, 2
	WAIT
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 2
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE A_, 2
	INSTR 0
	NOTE C_, 3
	INSTR 1
	NOTE D_, 3
	REPEAT_END
	REPEAT 2
	INSTR 0
	NOTE Csh, 3
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 2
	NOTE G_, 2
	WAIT
	INSTR 0
	NOTE E_, 2
	WAIT
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 2
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE A_, 2
	INSTR 0
	NOTE G_, 2
	INSTR 1
	NOTE E_, 2
	INSTR 0
	NOTE Csh, 3
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 2
	NOTE G_, 2
	WAIT
	INSTR 0
	NOTE E_, 2
	WAIT
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 2
	INSTR 0
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE A_, 2
	INSTR 0
	NOTE Csh, 3
	INSTR 1
	NOTE D_, 3
	REPEAT_END
	PAT_GOTO Pat_6D80
Pat_6E8D:
	INSTR 0
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 2
	NOTE A_, 2
	WAIT
	INSTR 0
	NOTE E_, 2
	NOTE G_, 2
	WAIT
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE E_, 2
	INSTR 0
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE D_, 2
	NOTE C_, 2
	WAIT
	INSTR 0
	NOTE A_, 1
	NOTE C_, 2
	WAIT
	NOTE D_, 2
	WAIT
	INSTR 1
	NOTE A_, 1
	NOTE D_, 2
	WAIT
	INSTR 0
	NOTE D_, 2
	NOTE E_, 2
	NOTE E_, 2
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE C_, 2
	NOTE F_, 2
	WAIT
	INSTR 0
	NOTE F_, 2
	NOTE E_, 2
	NOTE D_, 2
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 2
	INSTR 0
	NOTE D_, 2
	WAIT
	NOTE G_, 2
	WAIT
	NOTE B_, 2
	NOTE C_, 3
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE A_, 2
	NOTE G_, 2
	WAIT
	INSTR 0
	NOTE E_, 2
	WAIT
	NEXT
Pat_6ED5:
	NOTE A_, 2
	WAIT
	INSTR 1
	NOTE E_, 2
	INSTR 0
	NOTE A_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	NOTE E_, 2
	NEXT
Pat_6EE0:
	LEN 22
	REPEAT 4
	INSTR 2
	NOTE D_, 3
	INSTR 3
	NOTE A_, 3
	REPEAT_END
Pat_6EE7:
	LEN 22
	PAT_CALL Pat_6F5B
	PAT_CALL Pat_6F54
	PAT_CALL Pat_6F5B
	INSTR 2
	NOTE D_, 3
	INSTR 3
	NOTE A_, 3
	INSTR 2
	NOTE D_, 3
	INSTR 4
	NOTE G_, 3
	REPEAT 4
	INSTR 2
	NOTE D_, 3
	INSTR 4
	NOTE C_, 4
	REPEAT_END
	REPEAT 4
	INSTR 2
	NOTE D_, 3
	INSTR 4
	NOTE G_, 4
	REPEAT_END
	REPEAT 4
	INSTR 2
	NOTE D_, 3
	INSTR 3
	NOTE A_, 4
	REPEAT_END
	REPEAT 4
	INSTR 2
	NOTE D_, 3
	INSTR 3
	NOTE E_, 4
	REPEAT_END
	REPEAT 4
	INSTR 2
	NOTE D_, 3
	INSTR 4
	NOTE F_, 4
	REPEAT_END
	REPEAT 4
	INSTR 2
	NOTE D_, 3
	INSTR 4
	NOTE G_, 4
	REPEAT_END
	REPEAT 4
	INSTR 2
	NOTE D_, 3
	INSTR 4
	NOTE A_, 4
	REPEAT_END
	REPEAT 4
	INSTR 2
	NOTE D_, 3
	INSTR 4
	NOTE A_, 3
	REPEAT_END
	LEN 11
	REPEAT 8
	INSTR 2
	NOTE C_, 3
	INSTR 5
	NOTE A_, 3
	INSTR 3
	NOTE A_, 3
	NOTE A_, 3
	REPEAT_END
	LEN 11
	REPEAT 8
	INSTR 2
	NOTE C_, 3
	INSTR 5
	NOTE A_, 3
	INSTR 3
	NOTE A_, 3
	NOTE A_, 3
	REPEAT_END
	LEN 11
	REPEAT 8
	INSTR 2
	NOTE C_, 3
	INSTR 5
	NOTE A_, 3
	INSTR 4
	NOTE A_, 3
	NOTE A_, 3
	REPEAT_END
	LEN 11
	REPEAT 8
	INSTR 2
	NOTE C_, 3
	INSTR 5
	NOTE A_, 3
	INSTR 4
	NOTE A_, 3
	NOTE A_, 3
	REPEAT_END
	PAT_GOTO Pat_6EE7
Pat_6F54:
	REPEAT 2
	INSTR 2
	NOTE D_, 3
	INSTR 3
	NOTE A_, 3
	REPEAT_END
	NEXT
Pat_6F5B:
	REPEAT 4
	INSTR 2
	NOTE D_, 3
	INSTR 3
	NOTE A_, 3
	REPEAT_END
	REPEAT 4
	INSTR 2
	NOTE D_, 3
	INSTR 3
	NOTE D_, 4
	REPEAT_END
	REPEAT 2
	INSTR 2
	NOTE D_, 3
	INSTR 4
	NOTE F_, 4
	REPEAT_END
	REPEAT 2
	INSTR 2
	NOTE D_, 3
	INSTR 4
	NOTE G_, 3
	REPEAT_END
	REPEAT 2
	INSTR 2
	NOTE D_, 3
	INSTR 3
	NOTE A_, 3
	REPEAT_END
	NEXT
Pat_6F7A:
	DRUMS $0B, DrumPat_70BB
	VOLENV 0, $00, $00, $00
	LEN 44
	REPEAT 4
	REST
	REPEAT_END
Pat_6F86:
	LEN 11
	CH_TRANSPOSE $0C
	DRUMS $0B, DrumPat_70BB
	WAVE Wave_7B5D
	VOLENV 7, $61, $1F, $10
	VIBRATO $12, $01, $05
	RELEASE $75, $03
	ARP 0
	PAT_CALL Pat_7094
	LEN 3
	NOTE G_, 4
	LEN 19
	NOTE A_, 4
	LEN 11
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	NOTE C_, 5
	NOTE A_, 4
	WAIT2
	NOTE A_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE A_, 4
	WAIT2
	NOTE G_, 4
	NOTE E_, 4
	WAIT2
	NOTE D_, 4
	LENGTH $42
	NOTE E_, 4
	LEN 11
	WAIT2
	WAIT
	NOTE E_, 4
	WAIT2
	PAT_CALL Pat_7094
	LEN 11
	NOTE G_, 4
	NOTE A_, 4
	WAIT2
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE A_, 4
	WAIT2
	NOTE A_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE E_, 5
	NOTE G_, 5
	NOTE A_, 5
	WAIT2
	NOTE G_, 5
	NOTE E_, 5
	WAIT2
	NOTE D_, 5
	NOTE C_, 5
	WAIT
	LEN 33
	NOTE A_, 4
	CH_TRANSPOSE $00
	PAT_CALL Pat_707C
	WAVE Wave_7AED
	DRUMS $0B, DrumPat_70CC
	VOLENV 13, $10, $1F, $16
	VIBRATO $0B, $01, $05
	ARP 0
	LEN 22
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	LEN 11
	NOTE C_, 4
	NOTE F_, 4
	WAIT
	WAIT
	LEN 22
	NOTE E_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE B_, 3
	NOTE C_, 4
	LEN 11
	NOTE D_, 4
	NOTE C_, 4
	NOTE B_, 3
	LENGTH $4D
	NOTE G_, 3
	LEN 22
	NOTE B_, 3
	NOTE B_, 3
	LEN 11
	NOTE C_, 4
	NOTE A_, 3
	WAIT
	WAIT
	NOTE B_, 3
	WAIT
	NOTE C_, 4
	NOTE E_, 4
	WAIT
	WAIT
	LEN 22
	NOTE A_, 4
	NOTE B_, 4
	NOTE B_, 4
	NOTE C_, 5
	LEN 11
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	LENGTH $4D
	NOTE G_, 4
	LEN 11
	NOTE B_, 4
	NOTE C_, 5
	LENGTH $42
	NOTE F_, 4
	LEN 11
	NOTE B_, 4
	NOTE C_, 5
	NOTE F_, 4
	WAIT
	NOTE B_, 4
	NOTE C_, 5
	NOTE F_, 4
	WAIT
	NOTE B_, 4
	NOTE C_, 5
	LEN 33
	NOTE D_, 5
	NOTE C_, 5
	LEN 22
	NOTE B_, 4
	LEN 33
	NOTE G_, 4
	NOTE A_, 4
	LEN 22
	NOTE B_, 4
	LENGTH $B0
	NOTE A_, 4
	VOLENV 15, $10, $1F, $16
	LENGTH $79
	NOTE A_, 2
	PAT_CALL Pat_707C
	WAVE Wave_7AED
	VOLENV 10, $11, $1F, $11
	AUTOPAN $0B
	REPEAT 8
	NOTE A_, 3
	WAIT
	WAIT
	NOTE A_, 3
	NOTE A_, 4
	WAIT
	WAIT
	NOTE A_, 4
	REPEAT_END
	RELEASE $00
	VOLENV 11, $00, $1A, $11
	ARP 10
	REPEAT 4
	NOTE A_, 4
	NOTE A_, 3
	NOTE A_, 4
	NOTE A_, 3
	NOTE A_, 5
	NOTE A_, 3
	NOTE A_, 4
	NOTE A_, 5
	NOTE A_, 3
	NOTE A_, 5
	NOTE A_, 3
	NOTE A_, 4
	NOTE A_, 5
	NOTE A_, 4
	NOTE A_, 5
	NOTE A_, 4
	REPEAT_END
	AUTOPAN $00
	PAT_GOTO Pat_6F86
Pat_707C:
	WAVE Wave_7B2D
	GLIDE $FE
	VOLENV 15, $00, $1F, $11
	PAN_R
	LEN 5
	NOTE C_, 5
	LEN 6
	NOTE C_, 5
	LEN 11
	NOTE C_, 5
	PAN_C
	NOTE Ash, 4
	PAN_L
	NOTE A_, 4
	NOTE A_, 4
	PAN_C
	GLIDE_OFF
	NEXT
Pat_7094:
	LEN 3
	NOTE G_, 4
	LEN 8
	NOTE A_, 4
	LEN 11
	WAIT2
	NOTE A_, 4
	NOTE G_, 4
	WAIT2
	NOTE G_, 4
	LEN 44
	NOTE E_, 4
	LEN 11
	WAIT2
	LEN 4
	NOTE G_, 4
	LEN 7
	NOTE A_, 4
	LEN 11
	NOTE G_, 4
	NOTE A_, 4
	NOTE G_, 4
	NOTE E_, 4
	LENGTH $37
	NOTE D_, 4
	LEN 11
	WAIT2
	LEN 12
	NOTE E_, 4
	LEN 5
	NOTE F_, 4
	NOTE E_, 4
	LENGTH $42
	NOTE D_, 4
	LEN 22
	WAIT2
	NEXT
DrumPat_70BB:
	db DRUM_LEVEL + 14, 1, DRUM_LEVEL + 12, 8, DRUM_LEVEL + 15, 8, DRUM_LEVEL + 12, 8
	db DRUM_LEVEL + 14, 1, DRUM_LEVEL + 12, 8, DRUM_LEVEL + 15, 8, DRUM_LEVEL + 12, 8
	db DRUM_LOOP
DrumPat_70CC:
	db DRUM_LEVEL + 14, 1, DRUM_LEVEL + 12, 8, DRUM_LEVEL + 15, 8, DRUM_LEVEL + 12, 8
	db DRUM_LEVEL + 15, 2, DRUM_LEVEL + 12, 8, DRUM_LEVEL + 15, 8, DRUM_LEVEL + 12, 8
	db DRUM_LOOP

; Instrument table 10, entries 1..6 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr10_0
	dw Instr10_1
	dw Instr10_2
	dw Instr10_3
	dw Instr10_4
	dw Instr10_5
Instr10_0:
	ARP 0
	HWENV $F2, $00
	END
Instr10_1:
	ARP 0
	DUTY_75
	HWENV $F1, $00
	END
Instr10_2:
	HWENV $F1, $06, $00
	GLIDE $FD
	END
Instr10_3:
	HWENV $F1, $0B, $F1
	ARP 9
	END
Instr10_4:
	HWENV $F1, $0B, $F1
	ARP 8
	END
Instr10_5:
	HWENV $D1, $0B, $D1
	ARP 0
	END

; Song 3: instrument table 11, arpeggio table 1 (the one SndInit sets)
PlaySong3:
	ld a, $73
	ld [wInstrTableHi], a
	ld a, $D0
	ld [wInstrTable], a
	ld de, Song3_Ch1
	call StartMusicCh1
	ld de, Song3_Ch3
	call StartMusicCh3
	ld de, Song3_Ch2
	jp StartMusicCh2
Song3_Ch1:
	dw Pat_712F
Song3_Ch3:
	dw Pat_72FB
Song3_Ch2:
	dw Pat_722C
Pat_712F:
	INSTR 0
	LEN 13
Pat_7131:
	REPEAT 2
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	NOTE C_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 3
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	NOTE C_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 3
	NOTE Ash, 2
	WAIT
	INSTR 1
	NOTE Ash, 4
	INSTR 0
	NOTE Ash, 2
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE Ash, 4
	INSTR 0
	NOTE F_, 2
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 5
	INSTR 0
	NOTE C_, 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE C_, 5
	INSTR 0
	NOTE G_, 2
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	NOTE C_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 3
	REPEAT_END
	REPEAT 4
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	WAIT
	WAIT
	INSTR 0
	NOTE C_, 2
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	REPEAT_END
	DRUMS $0D, DrumPat_73C0
	REPEAT 2
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	NOTE C_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 0
	NOTE Ash, 2
	WAIT
	INSTR 1
	NOTE Ash, 4
	INSTR 0
	NOTE Ash, 2
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE Ash, 4
	INSTR 0
	NOTE F_, 2
	INSTR 0
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 5
	INSTR 0
	NOTE C_, 3
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE C_, 5
	INSTR 0
	NOTE G_, 2
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	NOTE C_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 3
	INSTR 0
	NOTE Ash, 2
	WAIT
	INSTR 1
	NOTE Ash, 4
	INSTR 0
	NOTE Ash, 2
	NOTE C_, 3
	WAIT
	INSTR 1
	NOTE C_, 5
	INSTR 0
	NOTE C_, 3
	INSTR 0
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	NOTE C_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	REPEAT_END
	REPEAT 4
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE F_, 2
	NOTE G_, 2
	WAIT
	INSTR 1
	NOTE G_, 4
	INSTR 0
	NOTE G_, 2
	NOTE Ash, 2
	WAIT
	INSTR 1
	NOTE Ash, 4
	INSTR 0
	NOTE Ash, 2
	NOTE F_, 2
	WAIT
	INSTR 1
	NOTE F_, 4
	INSTR 0
	NOTE C_, 2
	REPEAT_END
	PAT_GOTO Pat_7131
Pat_722C:
	HWENV $E1, $0A, $30
	VIBRATO $0D, $01, $05
	DUTY_50
Pat_7235:
	REPEAT 2
	LEN 13
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	LENGTH $41
	NOTE C_, 5
	LEN 13
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	LENGTH $41
	NOTE D_, 5
	LEN 13
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE E_, 5
	WAIT
	NOTE F_, 5
	NOTE E_, 5
	NOTE C_, 5
	NOTE D_, 5
	WAIT
	NOTE A_, 5
	WAIT
	NOTE G_, 5
	NOTE E_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE Ash, 4
	NOTE C_, 5
	NOTE D_, 5
	NOTE F_, 5
	WAIT
	NOTE D_, 5
	NOTE A_, 5
	WAIT
	NOTE G_, 5
	WAIT
	NOTE E_, 5
	WAIT
	NOTE C_, 6
	NOTE B_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE Gsh, 5
	LENGTH $41
	NOTE A_, 5
	LEN 13
	NOTE Gsh, 4
	LENGTH $75
	NOTE A_, 4
	REPEAT_END
	DUTY_75
	HWENV $D1, $05, $47
	ARP 0
	DRUMS_OFF
	LEN 26
	REPEAT 2
	NOTE F_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE A_, 4
	REPEAT_END
	LEN 13
	NOTE F_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE A_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE F_, 5
	NOTE C_, 5
	NOTE D_, 5
	NOTE A_, 4
	NOTE C_, 5
	NOTE G_, 4
	DRUMS $0D, DrumPat_73CE
	NOTE A_, 4
	NOTE F_, 4
	ARP_OFF
	HWENV $E1, $0A, $30
	DUTY_50
	REPEAT 2
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	WAIT
	WAIT
	WAIT
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE D_, 4
	WAIT
	WAIT
	NOTE Ash, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 4
	WAIT
	WAIT
	WAIT
	WAIT
	NOTE A_, 4
	NOTE Ash, 4
	NOTE C_, 5
	WAIT
	NOTE C_, 5
	WAIT
	NOTE Ash, 4
	NOTE A_, 4
	NOTE Ash, 4
	NOTE A_, 4
	NOTE F_, 4
	WAIT
	NOTE F_, 4
	WAIT
	WAIT
	WAIT
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE E_, 4
	LENGTH $68
	NOTE F_, 4
	LEN 13
	REPEAT_END
	REPEAT 2
	NOTE A_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE D_, 5
	NOTE G_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE F_, 5
	NOTE C_, 5
	WAIT
	NOTE A_, 5
	NOTE F_, 5
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE G_, 4
	NOTE D_, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE D_, 5
	NOTE G_, 5
	NOTE Ash, 5
	NOTE A_, 5
	NOTE C_, 6
	NOTE F_, 6
	WAIT
	REPEAT_END
	PAT_GOTO Pat_7235
Pat_72FB:
	LEN 13
	CH_TRANSPOSE $0C
	DRUMS $0D, DrumPat_73C0
	VIBRATO $0D, $01, $05
Pat_7306:
	VOLENV 13, $00, $1F, $11
	ARP 11
	AUTOPAN $34
	WAVE Wave_7B8D
	REPEAT 2
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE Ash, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE E_, 4
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE D_, 4
	REPEAT_END
	REPEAT 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE A_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE A_, 3
	NOTE F_, 3
	REPEAT_END
	REPEAT 2
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE C_, 4
	NOTE Ash, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE D_, 4
	NOTE C_, 4
	NOTE A_, 3
	NOTE Ash, 3
	WAIT
	NOTE A_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE F_, 3
	NOTE G_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE Ash, 3
	NOTE A_, 3
	NOTE Ash, 3
	NOTE D_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE C_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE C_, 4
	NOTE Ash, 3
	NOTE A_, 3
	NOTE G_, 3
	NOTE F_, 3
	NOTE E_, 3
	REPEAT_END
	REPEAT 2
	VOLENV 12, $00, $18, $12
	ARP_OFF
	WAVE Wave_7ADD
	LENGTH $34
	NOTE F_, 4
	NOTE G_, 4
	LEN 39
	NOTE F_, 4
	LEN 13
	NOTE G_, 4
	LENGTH $34
	NOTE F_, 4
	NOTE F_, 4
	NOTE G_, 4
	LEN 39
	NOTE F_, 4
	LEN 13
	NOTE E_, 4
	LENGTH $34
	NOTE F_, 4
	REPEAT_END
	LEN 13
	PAT_GOTO Pat_7306
DrumPat_73C0:
	db DRUM_REPEAT + 7, DRUM_LEVEL + 15, 6, DRUM_LEVEL + 11, 6, DRUM_LEVEL + 14, 4, DRUM_LEVEL + 11
	db 6, DRUM_REPEAT_END, DRUM_LEVEL + 15, 6, DRUM_LEVEL + 15, 6
DrumPat_73CE:
	db DRUM_LEVEL + 14, 4, 4, DRUM_LOOP

; Instrument table 11, entries 1..2 (the song routines point 2 bytes before:
; entry 0 is never read)
	dw Instr11_0
	dw Instr11_1
Instr11_0:
	HWENV $F1, $06, $60
	ARP 12
	END
Instr11_1:
	HWENV $F1, $05, $62
	ARP 6
	END

; Song 19: instrument table - (none set), arpeggio table 1 (the one SndInit sets)
PlaySong19:
	ld de, Song19_Ch1
	call StartMusicCh1
	ld de, Song19_Ch2
	call StartMusicCh2
	ld de, Song19_Ch3
	jp StartMusicCh3
Song19_Ch1:
	dw Pat_73FA
Song19_Ch2:
	dw Pat_7485
Song19_Ch3:
	dw Pat_74D7
Pat_73FA:
	DUTY_50
	LEN 9
	HWENV $F2, $12, $40
	ARP 0
	VIBRATO $09, $08, $05
	RELEASE $03, $41
	NOTE G_, 2
	NOTE A_, 2
	WAIT
	NOTE G_, 2
	DRUMS $09, DrumPat_757C
Pat_7410:
	REPEAT 2
	NOTE C_, 2
	WAIT
	WAIT
	NOTE C_, 3
	WAIT
	NOTE G_, 2
	NOTE C_, 2
	WAIT
	NOTE C_, 3
	NOTE C_, 2
	WAIT
	NOTE D_, 2
	NOTE E_, 2
	WAIT
	NOTE E_, 2
	NOTE E_, 3
	WAIT
	NOTE B_, 2
	NOTE E_, 2
	WAIT
	WAIT
	NOTE E_, 2
	WAIT
	NOTE G_, 2
	NOTE F_, 2
	WAIT
	WAIT
	NOTE F_, 3
	WAIT
	NOTE C_, 3
	NOTE F_, 2
	WAIT
	NOTE E_, 2
	NOTE F_, 2
	WAIT
	NOTE E_, 2
	NOTE D_, 2
	WAIT
	NOTE Fsh, 2
	NOTE A_, 2
	WAIT
	NOTE Fsh, 2
	NOTE G_, 2
	WAIT
	NOTE A_, 2
	NOTE Ash, 2
	WAIT
	NOTE B_, 2
	REPEAT_END
	PAT_CALL Pat_745D
	NOTE D_, 2
	WAIT
	NOTE D_, 3
	NOTE G_, 2
	WAIT
	NOTE D_, 2
	NOTE G_, 2
	NOTE A_, 2
	NOTE B_, 2
	PAT_CALL Pat_745D
	NOTE A_, 2
	WAIT
	NOTE A_, 3
	NOTE Ash, 2
	WAIT
	NOTE Ash, 3
	NOTE G_, 2
	NOTE A_, 2
	NOTE G_, 2
	PAT_GOTO Pat_7410
Pat_745D:
	NOTE F_, 2
	WAIT
	WAIT
	NOTE F_, 3
	WAIT
	NOTE F_, 2
	NOTE E_, 2
	WAIT
	NOTE E_, 2
	NOTE E_, 3
	WAIT
	NOTE E_, 2
	NOTE D_, 2
	WAIT
	NOTE A_, 2
	NOTE D_, 3
	WAIT
	NOTE D_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE C_, 2
	NOTE D_, 2
	NOTE E_, 2
	NOTE F_, 2
	WAIT
	WAIT
	NOTE F_, 3
	WAIT
	NOTE F_, 2
	NOTE D_, 2
	WAIT
	NOTE D_, 2
	NOTE D_, 3
	NOTE A_, 2
	NOTE Fsh, 2
	NOTE G_, 2
	WAIT
	NOTE G_, 3
	NEXT
Pat_7485:
	LEN 36
	HWENV $00, $00
	REST
	HWENV $F0, $02, $B2
	DUTY_12
	ARP 4
Pat_7490:
	REPEAT 2
	LEN 27
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	NOTE C_, 4
	ARP 5
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	LEN 18
	NOTE E_, 4
	LEN 9
	NOTE E_, 4
	ARP 4
	LEN 27
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE D_, 4
	NOTE D_, 4
	NOTE G_, 4
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE G_, 4
	REPEAT_END
	REPEAT 2
	LEN 27
	NOTE F_, 4
	NOTE F_, 4
	ARP 5
	NOTE E_, 4
	NOTE E_, 4
	NOTE D_, 4
	NOTE D_, 4
	ARP 4
	NOTE C_, 4
	LEN 18
	NOTE C_, 4
	LEN 9
	NOTE C_, 4
	LEN 27
	NOTE F_, 4
	NOTE F_, 4
	NOTE D_, 4
	LEN 27
	NOTE D_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LEN 18
	NOTE G_, 4
	LEN 9
	NOTE G_, 4
	REPEAT_END
	PAT_GOTO Pat_7490
Pat_74CC:
	LEN 27
	NOTE E_, 4
	NOTE E_, 4
	LEN 9
	NOTE E_, 4
	WAIT
	NOTE D_, 4
	NOTE C_, 4
	WAIT
	NOTE E_, 4
	NEXT
Pat_74D7:
	LEN 27
	CH_TRANSPOSE $0A
	VOLENV 0, $00, $00, $00
	WAVE Wave_7BFD
	REST
	VOLENV 9, $51, $19, $18
	VIBRATO $12, $01, $05
	RELEASE $94, $A1
	LEN 9
	ARP 2
	NOTE G_, 3
Pat_74F0:
	PAT_CALL Pat_74CC
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	WAIT
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	LEN 27
	NOTE C_, 5
	NOTE B_, 4
	LEN 9
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	NOTE F_, 4
	WAIT
	NOTE E_, 4
	LEN 27
	NOTE D_, 4
	NOTE A_, 4
	LEN 45
	NOTE G_, 4
	LEN 9
	NOTE G_, 3
	PAT_CALL Pat_74CC
	NOTE B_, 4
	WAIT
	NOTE G_, 4
	NOTE D_, 4
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE G_, 4
	NOTE C_, 5
	WAIT
	NOTE A_, 4
	WAIT
	WAIT
	NOTE G_, 4
	NOTE C_, 5
	WAIT
	NOTE A_, 4
	NOTE D_, 5
	WAIT
	NOTE C_, 5
	NOTE A_, 4
	WAIT
	NOTE B_, 4
	LEN 27
	NOTE C_, 5
	LEN 27
	NOTE G_, 5
	WAIT
	LEN 9
	PAT_CALL Pat_7557
	NOTE G_, 4
	NOTE A_, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE C_, 5
	NOTE B_, 4
	NOTE C_, 5
	NOTE B_, 4
	NOTE A_, 4
	NOTE G_, 4
	WAIT
	WAIT
	ARP 3
	PAT_CALL Pat_7557
	NOTE G_, 4
	WAIT
	NOTE G_, 4
	NOTE A_, 4
	WAIT
	NOTE A_, 4
	NOTE Ash, 4
	WAIT
	NOTE Ash, 4
	NOTE B_, 4
	WAIT
	NOTE G_, 3
	ARP 2
	PAT_GOTO Pat_74F0
Pat_7557:
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE A_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE B_, 4
	NOTE C_, 5
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE C_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE A_, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NOTE D_, 4
	NOTE E_, 4
	NOTE Fsh, 4
	NEXT
DrumPat_757C:
	db DRUM_REPEAT + 3, 1, 0, 6, 9, 0, 6, DRUM_REPEAT_END
	db 1, 0, 6, 9, 0, 9, DRUM_LOOP
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
	dw Arp21
	dw Arp22
	dw Arp23
	dw Arp24
	dw Arp25
	dw Arp26
Arp0:
	db $0C, $00, ARP_HOLD
Arp1:
	db $0C, $0C, $00, ARP_HOLD
Arp2:
	db $0E, $00, $01, $02, ARP_HOLD
Arp3:
	db $0D, $0E, $01, $02, ARP_HOLD
Arp4:
	db $00, $00, $04, $04, $07, $07, ARP_LOOP
Arp5:
	db $00, $00, $03, $03, $07, $07, ARP_LOOP
Arp6:
	db $00, $04, $07, ARP_LOOP
Arp7:
	db $00, $03, $07, ARP_LOOP
Arp8:
	db $00, $00, $04, $04, $07, $07, $00, $00
	db $04, $04, $07, ARP_LOOP
Arp9:
	db $00, $00, $03, $03, $07, $07, $00, $00
	db $03, $03, $07, ARP_LOOP
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
	db $18, $0C, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $18, $0C, $0C, $0C, $0C
	db $0C, $0C, $0C, $0C, $0C, $0C, ARP_LOOP
Arp18:
	db $18, $0C, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $24, $00, ARP_HOLD
Arp19:
	db $00, $00, $01, $02, ARP_HOLD
Arp20:
	db $00, $0C, ARP_LOOP
Arp21:
	db $00, $01, ARP_LOOP
Arp22:
	db $00, $0C, $00, ARP_HOLD
Arp23:
	db $18, $0C, $00, ARP_HOLD
Arp24:
	db $0C, $00, $00, $00, $00, $00, $00, ARP_LOOP
Arp25:
	db $00, $0C, $04, $10, $07, $13, ARP_LOOP
Arp26:
	db $0E, $00, $01, $01
SfxTable_m2:
	db $02, ARP_HOLD

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

; Sound effect 9
Sfx09:
	VOLENV 15, $11, $1F, $11
	WAVE Wave_7ADD
	LEN 5
	GLIDE $02
	NOTE Csh, 3
	WAIT
	END

; Sound effect 22
Sfx22:
	VOLENV 10, $11, $1F, $12
	WAVE Wave_7ADD
	LEN 13
	SLIDE_DOWN $03
	NOTE D_, 6
	END

; Sound effect 7
Sfx07:
	VOLENV 15, $00, $00, $00
	WAVE Wave_7ADD
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

; Sound effect 25
Sfx25:
	VOLENV 10, $11, $10, $00
	WAVE Wave_7B9D
	GLIDE $02
	LEN 5
	NOTE A_, 2
	GLIDE_OFF
	LEN 3
	WAIT
	GLIDE $02
	WAIT
	END

; Sound effect 27
Sfx27:
	VOLENV 15, $00, $00, $00
	WAVE Wave_7BA4
	LEN 6
	GLIDE $02
	NOTE A_, 3
	GLIDE_OFF
	SLIDE_DOWN $03
	LEN 20
	NOTE A_, 4
	END

; Sound effect 14
Sfx14:
	LEN 30
	VOLENV 15, $00, $00, $00
	SLIDE_UP $05
	ARP 20
	WAVE Wave_7BBD
	NOTE G_, 3
	END

; Sound effect 15
Sfx15:
	LEN 30
	VOLENV 15, $00, $00, $00
	SLIDE_DOWN $06
	ARP 20
	WAVE Wave_7BBD
	NOTE E_, 4
	END

; Sound effect 18
Sfx18:
	VOLENV 15, $00, $00, $00
	WAVE Wave_7B1D
	LEN 4
	GLIDE $03
	NOTE A_, 4
	LEN 1
	NOTE B_, 5
	END

; Sound effect 24
Sfx24:
	VOLENV 15, $00, $00, $00
	WAVE Wave_7BAD
	GLIDE $01
	LEN 3
	NOTE C_, 3
	REST
	NOTE C_, 3
	GLIDE_OFF
	LEN 3
	WAIT
	END

; Sound effect 21
Sfx21:
	VOLENV 15, $11, $1F, $11
	CALL_CODE Code_79DA
	WAVE Wave_7ADD
	LEN 6
	GLIDE $FE
	NOTE C_, 3
	WAIT
	END

; Sound effect 19
Sfx19:
	VOLENV 10, $11, $1F, $11
	CALL_CODE Code_7A10
	ARP 0
	WAVE Wave_7ADD
	LEN 5
	GLIDE $03
	NOTE Csh, 2
	LEN 3
	WAIT
	END

; Sound effect 12
Sfx12:
	VOLENV 12, $11, $1F, $14
	WAVE Wave_7ADD
	LEN 6
	NOTE Ash, 5
	LEN 25
	NOTE G_, 5
	VIBRATO $05, $01, $04
	END

; Sound effect 26
Sfx26:
	VOLENV 5, $1A, $1A, $22
	WAVE Wave_7BBD
	LEN 40
	VIBRATO $00, $02, $05
	NOTE Csh, 6
	END

; Sound effect 10
Sfx10:
	LEN 4
	VOLENV 15, $00, $00, $00
	WAVE Wave_7ADD
	GLIDE $FE
	LEN 3
	NOTE B_, 4
	NOTE Fsh, 5
	LEN 2
	REST
	GLIDE $FF
	NOTE Ash, 5
	END

; Sound effect 5
Sfx05:
	VOLENV 15, $11, $1F, $1B
	WAVE Wave_7B1D
	CALL_CODE Code_7A46
	GLIDE $02
	LEN 8
	NOTE A_, 5
	GLIDE_OFF
	SLIDE_DOWN $02
	LEN 42
	NOTE Csh, 7
	END

; Sound effect 29
Sfx29:
	VOLENV 15, $00, $1F, $11
	ARP 0
	WAVE Wave_7BBD
	LEN 5
	NOTE E_, 6
	NOTE Csh, 6
	WAIT
	VOLENV 5, $11, $1F, $11
	LEN 5
	NOTE E_, 6
	NOTE Csh, 6
	WAIT
	END

; Sound effect 4
Sfx04:
	LEN 3
	VOLENV 15, $11, $1F, $11
	WAVE Wave_7B7D
	NOTE C_, 6
	NOTE E_, 6
	NOTE G_, 6
	NOTE C_, 7
	VOL $05
	NOTE C_, 6
	NOTE E_, 6
	NOTE G_, 6
	NOTE C_, 7
	END

; Unreferenced (17 bytes)
	db $B8, $10, $1F, $12, $79, $7D, $7B, $C2, $91, $82, $02, $44, $83, $01, $46, $65
	db $68

; Sound effect 1
Sfx01:
	VOLENV 15, $00, $00, $00
	WAVE Wave_7B7D
	LEN 3
	ARP 0
	NOTE G_, 6
	NOTE B_, 6
	NOTE D_, 7
	NOTE G_, 7
	NOTE D_, 7
	NOTE C_, 7
	VOL $0A
	NOTE G_, 7
	NOTE D_, 7
	NOTE C_, 7
	VOL $05
	NOTE G_, 7
	NOTE D_, 7
	NOTE C_, 7
	END

; Sound effect 16
Sfx16:
	VOLENV 15, $11, $1F, $13
	WAVE Wave_7B3D
	CALL_CODE Code_7C67
	LEN 5
	NOTE C_, 4
	CALL_CODE Code_7946
	LEN 1
	REST
	LEN 10
	GLIDE $FE
	NOTE Dsh, 5
	END

; Sound effect 11
Sfx11:
	VOLENV 15, $11, $1F, $12
	ARP 0
	WAVE Wave_7ADD
	LEN 4
	GLIDE $04
	NOTE Fsh, 2
	GLIDE $FF
	WAIT
	GLIDE $01
	WAIT
	GLIDE $FF
	WAIT
	GLIDE $01
	WAIT
	END

; Unreferenced (19 bytes)
	db $B8, $11, $1F, $12, $79, $DD, $7A, $BD, $60, $02, $17, $61, $D1, $63, $00, $13
	db $05, $22, $68

; Sound effect 17
Sfx17:
	LEN 14
	VOLENV 15, $15, $1F, $11
	GLIDE $01
	WAVE Wave_7ADD
	NOTE A_, 3
	END

; Sound effect 28
Sfx28:
	LEN 4
	ARP 0
	WAVE ChannelTick
	VOLENV 15, $00, $00, $00
	NOTE C_, 6
	NOTE G_, 6
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	VOL $0A
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	VOL $05
	NOTE E_, 6
	NOTE C_, 6
	NOTE G_, 6
	END

; Sound effect 23
Sfx23:
	VOLENV 15, $11, $1F, $14
	LEN 6
	WAVE Wave_7C0D
	GLIDE $02
	NOTE Fsh, 5
	GLIDE_OFF
	LENGTH $0F
	SLIDE_DOWN $02
	NOTE Fsh, 6
	GLIDE $FF
	LEN 3
	WAIT
	END

; Sound effect 8
Sfx08:
	VOLENV 15, $11, $1F, $16
	LEN 6
	WAVE Wave_7C0D
	GLIDE $03
	NOTE F_, 5
	LEN 1
	GLIDE $01
	WAIT
	GLIDE_OFF
	LENGTH $0A
	SLIDE_DOWN $04
	NOTE C_, 7
	LEN 4
	GLIDE $02
	WAIT
	GLIDE $FE
	WAIT
	END

; Sound effect 3
Sfx03:
	LEN 2
	VOLENV 15, $11, $1F, $11
	WAVE Wave_7B7D
	CH_TRANSPOSE $0C
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
	VOL $05
	NOTE C_, 6
	NOTE E_, 6
	NOTE G_, 6
	NOTE C_, 7
	END

; Sound effect 6
Sfx06:
	LEN 6
	VOLENV 15, $11, $1F, $13
	WAVE Wave_7C0D
	GLIDE $FF
	NOTE A_, 6
	WAVE Wave_7BFD
	LEN 4
	WAIT
	END

; Sound effect 20
Sfx20:
	LEN 4
	VOLENV 15, $11, $2F, $11
	WAVE Wave_7ADD
	GLIDE $F8
	NOTE A_, 5
	END

; Sound effect 13
Sfx13:
	LEN 4
	VOLENV 15, $00, $00, $00
	WAVE Wave_7ADD
	GLIDE $02
	NOTE A_, 4
	NOTE D_, 4
	END

; Sound effect 32 (noise only; started by the game's glue, sets wDrumHold)
Sfx32_Noise:
	ld a, $14
	ld [wDrumHold], a
	ld a, $88
	ld [wNoisePan], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7937)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7937)
	ld [wNoise43], a
	ld a, HIGH(Noise42_793F)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_793F)
	ld [wNoise42], a
	ret
Noise43_7937:
	db $30, $31, $32, $33, $34, $25, $30, $FF
Noise42_793F:
	db $D2, $FF, $FF, $FF, $FF, $FF, $FF
Code_7946:
	ld a, $0A
	ld [wDrumHold], a
	ld a, $88
	ld [wNoisePan], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $F1
	ldh [rNR42], a
	ld a, HIGH(Noise43_7971)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7971)
	ld [wNoise43], a
	ld a, $00
	ld [wNoise42Hi], a
	ld a, $00
	ld [wNoise42], a
	ret
Noise43_7971:
	db $10, $10, $20, $31, $33, $34, $35, $36
	db $FF

; Sound effect 30 (noise only; started by the game's glue, sets wDrumHold)
Sfx30_Noise:
	ld a, $32
	ld [wDrumHold], a
	ld a, $88
	ld [wNoisePan], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_79A1)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_79A1)
	ld [wNoise43], a
	ld a, HIGH(Noise42_79BE)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_79BE)
	ld [wNoise42], a
	ret
Noise43_79A1:
	db $20, $30, $30, $30, $32, $42, $42, $42
	db $42, $42, $20, $30, $30, $30, $32, $42
	db $42, $42, $42, $42, $42, $42, $42, $22
	db $82, $81, $80, $54, $FF
Noise42_79BE:
	db $F0, $FF, $55, $00, $B2, $FF, $FF, $FF
	db $FF, $FF, $F0, $FF, $55, $00, $B2, $FF
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $F0
	db $FF, $FF, $FF, $F4
Code_79DA:
	ld a, $0F
	ld [wDrumHold], a
	ld a, $88
	ld [wNoisePan], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7A01)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7A01)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7A09)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7A09)
	ld [wNoise42], a
	ret
Noise43_7A01:
	db $02, $51, $61, $71, $91, $71, $60, $FF
Noise42_7A09:
	db $F0, $F0, $F0, $F0, $F0, $70, $63
Code_7A10:
	ld a, $0A
	ld [wDrumHold], a
	ld a, $88
	ld [wNoisePan], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7A37)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7A37)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7A3F)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7A3F)
	ld [wNoise42], a
	ret
Noise43_7A37:
	db $11, $32, $32, $32, $32, $11, $32, $FF
Noise42_7A3F:
	db $F2, $71, $FF, $FF, $FF, $F0, $51
Code_7A46:
	ld a, $32
	ld [wDrumHold], a
	ld a, $88
	ld [wNoisePan], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, $02
	ld [wNoiseSpeed], a
	xor a
	ld [wNoiseTimer], a
	ld a, HIGH(Noise43_7A76)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7A76)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7A81)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7A81)
	ld [wNoise42], a
	ret
Noise43_7A76:
	db $27, $26, $25, $14, $13, $12, $11, $10
	db $10, $10, $FF
Noise42_7A81:
	db $19, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $FF, $F3

; Sound effect 31 (noise only; started by the game's glue, sets wDrumHold)
Sfx31_Noise:
	ld a, $19
	ld [wDrumHold], a
	ld a, $88
	ld [wNoisePan], a
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7AB2)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7AB2)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7AB8)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7AB8)
	ld [wNoise42], a
	ret
Noise43_7AB2:
	db $03, $83, $80, $80, $51, $FF
Noise42_7AB8:
	db $F0, $FF, $FF, $FF, $F2

; Unreferenced (16 bytes)
	db $04, $8B, $DE, $FF, $ED, $CB, $A9, $87, $65, $44, $44, $32, $11, $24, $7A, $74
Wave_7ACD:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $00, $FF, $FF, $FF
Wave_7ADD:
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
	db $00, $00, $00, $00, $FF, $FF, $FF, $FF
Wave_7AED:
	db $01, $11, $11, $00, $89, $AA, $AA, $98
	db $01, $11, $11, $00, $FF, $FF, $FF, $FF

; Unreferenced (16 bytes)
	db $22, $22, $22, $22, $CC, $CC, $CC, $CC, $22, $22, $22, $22, $CC, $CC, $CC, $CC
Wave_7B0D:
	db $00, $00, $00, $CD, $EF, $FF, $FF, $FF
	db $04, $8C, $FF, $FF, $FF, $FF, $FF, $FF
Wave_7B1D:
	db $12, $34, $56, $78, $9A, $BC, $DE, $FF
	db $ED, $CB, $A9, $87, $65, $43, $21, $00
Wave_7B2D:
	db $FF, $FE, $ED, $B8, $53, $21, $10, $00
	db $00, $01, $12, $35, $8B, $DE, $EF, $FF
Wave_7B3D:
	db $63, $10, $00, $00, $00, $00, $01, $36
	db $9C, $EF, $FF, $FF, $FF, $FF, $FE, $C9
Wave_7B4D:
	db $63, $10, $01, $47, $74, $10, $01, $36
	db $9C, $EF, $FE, $B8, $8B, $EF, $FE, $C9
Wave_7B5D:
	db $65, $43, $22, $27, $72, $22, $22, $29
	db $AB, $CC, $BA, $98, $9C, $EE, $EE, $C9
Wave_7B6D:
	db $63, $20, $02, $47, $74, $22, $22, $36
	db $9C, $EF, $FE, $B6, $6B, $EE, $EE, $C9
Wave_7B7D:
	db $63, $1F, $01, $47, $74, $10, $01, $36
	db $9C, $E0, $FE, $B8, $8B, $EF, $FE, $C9
Wave_7B8D:
	db $B7, $40, $04, $7B, $CD, $FF, $FE, $DC
	db $02, $46, $8A, $BD, $FD, $BA, $64, $20
Wave_7B9D:
	db $0F, $00, $F0, $F0, $F0, $F0, $00; 16-byte wave: continues into the next wave
Wave_7BA4:
	db $0F, $0F, $FF, $FF, $00, $FF, $F0, $0F; 16-byte wave: continues into the next wave
	db $0F
Wave_7BAD:
	db $BB, $2B, $BB, $2B, $BB, $5B, $2B, $BB
	db $2B, $BB, $BB, $72, $27, $EB, $BB, $B0
Wave_7BBD:
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $ED, $CB, $A9, $87, $65, $43, $21, $00
Wave_7BCD:
	db $FE, $DB, $97, $53, $13, $54, $32, $10
	db $FE, $DC, $BC, $EF, $DB, $85, $32, $10
Wave_7BDD:
	db $22, $22, $22, $22, $22, $22, $EE, $EE
	db $22, $22, $22, $22, $22, $22, $EE, $EE
Wave_7BED:
	db $20, $13, $69, $BD, $FD, $B9, $64, $20
	db $13, $68, $B8, $64, $20, $24, $68, $64
Wave_7BFD:
	db $20, $24, $68, $AC, $EC, $A8, $64, $20
	db $24, $68, $A8, $64, $20, $24, $68, $64
Wave_7C0D:
	db $02, $48, $AC, $FF, $FC, $53, $00, $27
	db $9C, $DD, $DC, $B7, $7B, $CD, $DD, $C9
Noise43_7C1D:
	db $02, $51, $61, $71, $91, $71, $60, $FF
Noise42_7C25:
	db $F0, $F0, $D0, $90, $70, $40, $31
Noise43_7C2C:
	db $06, $04, $03, $03, $07, $FF
Noise42_7C32:
	db $F0, $C0, $80, $60, $55
Noise43_7C37:
	db $04, $02, $01, $01, $FF
Noise42_7C3C:
	db $80, $40, $30, $23
Noise43_7C40:
	db $04, $02, $01, $01, $04, $02, $01, $FF
Noise42_7C48:
	db $A0, $60, $33, $23, $A0, $60, $33
Noise43_7C4F:
	db $04, $02, $06, $06, $FF
Noise42_7C54:
	db $C0, $80, $60, $44
Noise43_7C58:
	db $50, $41, $50, $51, $52, $53, $51, $FF
Noise42_7C60:
	db $F0, $70, $F0, $70, $D0, $70, $83
Code_7C67:
	ld a, $08
	ld [wDrumHold], a
	call NoisePanCentre
Drum1:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7C1D)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7C1D)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7C25)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7C25)
	ld [wNoise42], a
	ret
Drum8:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7CA9)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7CA9)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7CAF)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7CAF)
	ld [wNoise42], a
	ret
Noise43_7CA9:
	db $04, $02, $01, $00, $00, $FF
Noise42_7CAF:
	db $40, $60, $70, $82, $71
Drum2:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7CD1)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7CD1)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7CD9)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7CD9)
	ld [wNoise42], a
	ret
Noise43_7CD1:
	db $60, $52, $42, $41, $22, $11, $04, $FF
Noise42_7CD9:
	db $F0, $F0, $F0, $A0, $70, $40, $51
Drum3:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7C58)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7C58)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7C60)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7C60)
	ld [wNoise42], a
	ret
Drum4:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7C4F)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7C4F)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7C54)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7C54)
	ld [wNoise42], a
	ret
Drum5:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7C40)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7C40)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7C48)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7C48)
	ld [wNoise42], a
	ret
Drum6:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7C37)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7C37)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7C3C)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7C3C)
	ld [wNoise42], a
	ret
Drum7:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7C2C)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7C2C)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7C32)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7C32)
	ld [wNoise42], a
	ret
Drum9:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7D8E)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7D8E)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7D91)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7D91)
	ld [wNoise42], a
	ret
Noise43_7D8E:
	db $51, $32, $FF
Noise42_7D91:
	db $F0, $72
Drum10:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7DCD)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7DCD)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7DD0)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7DD0)
	ld [wNoise42], a
	ret
Drum11:
	xor a
	ld [wNoisePos], a
	inc a
	ld [wNoiseOn], a
	ld a, HIGH(Noise43_7DD2)
	ld [wNoise43Hi], a
	ld a, LOW(Noise43_7DD2)
	ld [wNoise43], a
	ld a, HIGH(Noise42_7DDA)
	ld [wNoise42Hi], a
	ld a, LOW(Noise42_7DDA)
	ld [wNoise42], a
	ret
Noise43_7DCD:
	db $51, $32, $FF
Noise42_7DD0:
	db $90, $61
Noise43_7DD2:
	db $51, $32, $32, $32, $32, $51, $32, $FF
Noise42_7DDA:
	db $80, $51, $FF, $FF, $FF, $80, $51
FadeOutTable:
	db $77, $66, $55, $44, $33, $22, $11, $00
	db FADE_END
FadeInTable:
	db $00, $11, $22, $33, $44, $55, $66, $77
	db FADE_END

; Jingle 1: instrument table - (none set), arpeggio table 1 (the one SndInit sets)
; Not in the API song table: the game posts this address straight into its song
; mailbox ($D95A/$D95B) from bank 0 at $1A1E.
PlayJingle1:
	ld de, Jingle1_Ch1
	call StartMusicCh1
	ld de, Jingle1_Ch2
	call StartMusicCh2
	ld de, Jingle1_Ch3
	jp StartMusicCh3
Jingle1_Ch1:
	dw Pat_7E0B
Jingle1_Ch2:
	dw Pat_7E28
Jingle1_Ch3:
	dw Pat_7E41
Pat_7E0B:
	HWENV $F2, $04, $95
	VIBRATO $07, $01, $04
	ARP 23
	DUTY_50
	LEN 21
	NOTE D_, 2
	LEN 7
	NOTE D_, 2
	LEN 14
	NOTE D_, 2
	NOTE D_, 3
	NOTE A_, 2
	NOTE Fsh, 2
	NOTE F_, 2
	NOTE A_, 2
	NOTE C_, 3
	NOTE G_, 2
	NOTE B_, 2
	NOTE D_, 3
	LENGTH $38
	NOTE A_, 2
	END
Pat_7E28:
	HWENV $F2, $04, $95
	DUTY_75
	ARP 6
	LEN 21
	NOTE D_, 4
	LEN 7
	NOTE D_, 4
	LEN 14
	NOTE D_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE E_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE F_, 4
	NOTE G_, 4
	NOTE G_, 4
	NOTE G_, 4
	LENGTH $38
	NOTE A_, 4
	END
Pat_7E41:
	VIBRATO $07, $01, $04
	VOLENV 15, $11, $1F, $14
	ARP 0
	RELEASE $01, $11
	CH_TRANSPOSE $0C
	DRUMS $07, DrumPat_7E77
	WAVE Wave_7E67
	LEN 42
	NOTE D_, 3
	LEN 14
	NOTE D_, 4
	NOTE A_, 3
	NOTE Fsh, 3
	NOTE F_, 3
	NOTE A_, 3
	NOTE C_, 4
	NOTE G_, 3
	NOTE B_, 3
	NOTE D_, 4
	LENGTH $38
	NOTE E_, 4
	DRUMS_OFF
	END
Wave_7E67:
	db $FE, $DB, $97, $53, $13, $54, $32, $10
	db $FE, $DC, $BC, $EF, $DB, $85, $32, $10
DrumPat_7E77:
	db 7, 0, 0, 10, 10, 0, 9, 0
	db 9, 0, 9, 0, 7, 0, 9, 0
	db 9, 0, 7, 0, 10, 10, 9, 9
	db 7, 0, 0, 0, 0, 0, 0, 0
	db 0, 0

; Sound effect 2
Sfx02:
	VOLENV 15, $00, $00, $00
	LEN 2
	CH_TRANSPOSE $18
	ARP 0
	WAVE Wave_7F72
	NOTE C_, 4
	NOTE E_, 4
	NOTE G_, 4
	NOTE C_, 5
	NOTE G_, 4
	NOTE E_, 4
	NOTE Dsh, 4
	NOTE G_, 4
	NOTE Ash, 4
	NOTE Dsh, 5
	NOTE Ash, 4
	NOTE G_, 4
	NOTE F_, 4
	NOTE A_, 4
	NOTE C_, 5
	NOTE F_, 5
	NOTE C_, 5
	NOTE A_, 4
	NOTE G_, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE B_, 4
	VOL $0A
	NOTE G_, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE B_, 4
	VOL $05
	NOTE G_, 4
	NOTE B_, 4
	NOTE D_, 5
	NOTE G_, 5
	NOTE D_, 5
	NOTE B_, 4
	END

; Jingle 2: instrument table - (none set), arpeggio table 1 (the one SndInit sets)
; Not in the API song table: the game posts this address straight into its song
; mailbox ($D95A/$D95B) from bank 0 at $1DB1.
PlayJingle2:
	ld de, Jingle2_Ch1
	call StartMusicCh1
	ld de, Jingle2_Ch2
	call StartMusicCh2
	ld de, Jingle2_Ch3
	jp StartMusicCh3
Jingle2_Ch1:
	dw Pat_7EE5
Jingle2_Ch2:
	dw Pat_7F09
Jingle2_Ch3:
	dw Pat_7F29
Pat_7EE5:
	HWENV $F2, $04, $95
	VIBRATO $07, $01, $04
	ARP 23
	LEN 7
	DUTY_50
	NOTE A_, 2
	WAIT
	WAIT
	NOTE A_, 3
	WAIT
	NOTE A_, 2
	NOTE D_, 3
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	NOTE D_, 3
	NOTE E_, 3
	WAIT
	NOTE E_, 2
	NOTE Gsh, 2
	WAIT
	NOTE A_, 2
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	END
Pat_7F09:
	HWENV $F2, $04, $95
	LEN 7
	DUTY_75
	ARP 6
	NOTE A_, 3
	WAIT
	WAIT
	NOTE A_, 3
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	NOTE D_, 4
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	WAIT
	NOTE E_, 4
	WAIT
	NOTE A_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	END
Pat_7F29:
	VIBRATO $07, $01, $04
	VOLENV 14, $00, $1F, $13
	ARP 0
	CH_TRANSPOSE $18
	LEN 7
	DRUMS $07, DrumPat_7F56
	WAVE Wave_7F72
	NOTE A_, 3
	WAIT
	NOTE Csh, 4
	NOTE E_, 4
	WAIT
	NOTE Csh, 4
	NOTE D_, 4
	WAIT
	NOTE Fsh, 4
	WAIT
	WAIT
	NOTE D_, 4
	NOTE E_, 4
	WAIT
	NOTE Csh, 4
	NOTE B_, 3
	WAIT
	NOTE A_, 3
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	WAIT
	DRUMS_OFF
	END
DrumPat_7F56:
	db 1, 0, 6, 9, 0, 6, 1, 0
	db 6, 9, 0, 6, 1, 0, 1, 7
	db 0, 7, 0, 0, 0, 0, 0, 0
	db 0, 0, 0, 0
Wave_7F72:
	db $63, $1F, $01, $47, $74, $10, $01, $36
	db $9C, $E0, $FE, $B8, $8B, $EF, $FE, $C9

; The game's PlaySfx glue (reached from PlaySfxEntry): ids $1E/$1F/$20 start noise
; routines (SFX 30-32), id $1C skips the priority test, others go to PlaySfx.
GamePlaySfxGlue:
	cp $1E
	jp z, Sfx30_Noise
	cp $1F
	jp z, Sfx31_Noise
	cp $20
	jp z, Sfx32_Noise
	cp $1C
	jp z, GlueForceSfx
	jp PlaySfx
GlueForceSfx:
	ld c, a
	jp PlaySfxNow

; Not reached: assembler leftovers to the end of the bank.
Unused_Garbage3:
	db $FE, $E8, $33, $FE, $E8, $30, $FE, $E8, $80, $01, $E8, $EA, $01, $E8, $39, $02
	db $EB, $31, $E8, $EA, $FE, $B0, $2D, $E8, $DF, $01, $E9, $E2, $FE, $E8, $17, $FE
	db $E8, $14, $FE, $E8, $EC, $FF, $E8, $CE, $01, $E8, $1D, $02, $EB, $15, $E8, $06
	db $FE, $E8, $03, $FE, $E8, $DB, $FF, $E8, $BD, $01, $B8, $09, $48, $E8, $1D, $02
	db $E8, $06, $02, $E9, $85, $E8, $E8, $41, $01, $E8, $AB, $01, $B8, $24, $4C, $E8
	db $0B, $02, $E8, $35, $01, $E8, $9F, $01, $B8, $6F, $3C, $E8, $F4, $01, $E8, $C5
	db $01, $EB, $E0
