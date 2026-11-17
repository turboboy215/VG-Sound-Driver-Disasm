; ---------------------------------------------------------------------------
; Realtime Associates Game Boy sound driver (David Warhol): shared definitions
; Used by Zoop (U) and Star Wars - Super Return of the Jedi (U).
; ---------------------------------------------------------------------------

IF !DEF(RTA_SOUND_INC)
DEF RTA_SOUND_INC EQU 1

; --- hardware
DEF rNR10 EQU $FF10
DEF rNR11 EQU $FF11
DEF rNR12 EQU $FF12
DEF rNR13 EQU $FF13
DEF rNR14 EQU $FF14
DEF rNR20 EQU $FF15 ; no register; the driver's CH2 block starts here
DEF rNR21 EQU $FF16
DEF rNR22 EQU $FF17
DEF rNR23 EQU $FF18
DEF rNR24 EQU $FF19
DEF rNR30 EQU $FF1A
DEF rNR31 EQU $FF1B
DEF rNR32 EQU $FF1C
DEF rNR33 EQU $FF1D
DEF rNR34 EQU $FF1E
DEF rNR40 EQU $FF1F ; no register; the driver's CH4 block starts here
DEF rNR41 EQU $FF20
DEF rNR42 EQU $FF21
DEF rNR43 EQU $FF22
DEF rNR44 EQU $FF23
DEF rNR50 EQU $FF24
DEF rNR51 EQU $FF25
DEF rNR52 EQU $FF26
DEF _AUD3WAVERAM EQU $FF30

; --- voice record (wVoice1-4, 6 bytes each)
DEF VOICE_TIMER EQU 0 ; frames to the next patch step (0 = idle)
DEF VOICE_PATCH EQU 1 ; current patch
DEF VOICE_NOTE  EQU 2 ; period index (note value - 3)
DEF VOICE_PERLO EQU 3 ; current period, low
DEF VOICE_PERHI EQU 4 ; current period, high (+ bit 7 trigger, bit 6 length)
DEF VOICE_COUNT EQU 5 ; steps left before the patch chain moves on (0 = stay)
DEF VOICE_SIZE  EQU 6

; --- sound ids (argument of SndPlay)
DEF SND_MUSIC   EQU $80 ; bit 7: music, id & $3F = SoundTable index
DEF SND_HIGHPRI EQU $40 ; SFX: bit 6 = high priority (always plays, blocks normal SFX)

; --- patch: 12 bytes
;  flags  bit 7 = trigger (OR'ed into NRx4), bit 0 = (re)load the period from the note
;  ofs    added to the period's low byte when the period is loaded
;  delta  signed 16-bit, added to the period on every step (vibrato/slides)
;  and/or NR51 = (NR51 & and) | or
;  dur    frames until the next step (0 = this is the last step)
;  next   patch for the following steps once cnt runs out
;  cnt    number of steps of the *next* patch before its own next is taken (0 = forever)
;  reg    $00-$FC: NRx0 value, r1 -> NRx1, r2 -> NRx2, then the period -> NRx3/NRx4
;         $FD: noise: r1 -> NR42, NR43 = r2 | (note & 7) << 4, NR44 = $80
;         $FE: CH3 wave r1 (byte offset into Waves), NR32 = $20, NR30 = $80, period
;         $FF: period only
MACRO patch
	db \1, \2
	dw \3
	db \4, \5, \6, \7, \8, \9, \<10>, \<11>
ENDM

; --- songs
; header: numDefs, then numDefs MIDI channels, then numDefs note values.
; A note value v plays period index v - 3 (C_2 = 3 = 65.4 Hz on CH1/CH2).
MACRO song_header
	DEF SONG_N = \1
	db \1
ENDM
MACRO note ; note-on for note def \1 (its MIDI channel and note)
	ASSERT (\1) < SONG_N
	db \1
ENDM
MACRO release ; release MIDI channel \1 (its program's release patch)
	ASSERT (\1) < 16
	db SONG_N + (\1)
ENDM
MACRO program ; MIDI channel \1 = program \2
	ASSERT (\1) < 16
	db SONG_N + 16 + (\1), \2
ENDM
MACRO wait ; wait \1 frames
	ASSERT (\1) >= 1 && SONG_N + 32 + (\1) < $FE
	db SONG_N + 32 + (\1)
ENDM
MACRO song_goto ; start song \1 & $3F (the songs loop to themselves)
	db $FE, \1
ENDM
MACRO song_end
	db $FF
ENDM

; --- SFX
MACRO sfx_pulse1 ; NR10, NR11, NR12, period (+ $8000 trigger, + $4000 length)
	db $00, \1, \2, \3
	dw \4
ENDM
MACRO sfx_pulse2 ; NR21, NR22, period
	db $01, \1, \2
	dw \3
ENDM
MACRO sfx_wave ; does nothing
	db $02
ENDM
MACRO sfx_noise ; NR41, NR42, NR43, NR44
	db $03, \1, \2, \3, \4
ENDM
MACRO sfx_jump
	db $FE
	dw \1
ENDM
MACRO sfx_random ; transpose = rnd & \1, extra wait = rnd & \2
	db $FF, \1, \2
ENDM
MACRO sfx_wait ; wait \1 frames (+ the random extra wait)
	ASSERT (\1) >= 1 && (\1) + 4 < $FE
	db (\1) + 4
ENDM
MACRO sfx_end
	db $04
ENDM

; --- note values (period index + 3)
DEF A_1 EQU 0
DEF As1 EQU 1
DEF B_1 EQU 2
DEF C_2 EQU 3
DEF Cs2 EQU 4
DEF D_2 EQU 5
DEF Ds2 EQU 6
DEF E_2 EQU 7
DEF F_2 EQU 8
DEF Fs2 EQU 9
DEF G_2 EQU 10
DEF Gs2 EQU 11
DEF A_2 EQU 12
DEF As2 EQU 13
DEF B_2 EQU 14
DEF C_3 EQU 15
DEF Cs3 EQU 16
DEF D_3 EQU 17
DEF Ds3 EQU 18
DEF E_3 EQU 19
DEF F_3 EQU 20
DEF Fs3 EQU 21
DEF G_3 EQU 22
DEF Gs3 EQU 23
DEF A_3 EQU 24
DEF As3 EQU 25
DEF B_3 EQU 26
DEF C_4 EQU 27
DEF Cs4 EQU 28
DEF D_4 EQU 29
DEF Ds4 EQU 30
DEF E_4 EQU 31
DEF F_4 EQU 32
DEF Fs4 EQU 33
DEF G_4 EQU 34
DEF Gs4 EQU 35
DEF A_4 EQU 36
DEF As4 EQU 37
DEF B_4 EQU 38
DEF C_5 EQU 39
DEF Cs5 EQU 40
DEF D_5 EQU 41
DEF Ds5 EQU 42
DEF E_5 EQU 43
DEF F_5 EQU 44
DEF Fs5 EQU 45
DEF G_5 EQU 46
DEF Gs5 EQU 47
DEF A_5 EQU 48
DEF As5 EQU 49
DEF B_5 EQU 50
DEF C_6 EQU 51
DEF Cs6 EQU 52
DEF D_6 EQU 53
DEF Ds6 EQU 54
DEF E_6 EQU 55
DEF F_6 EQU 56
DEF Fs6 EQU 57
DEF G_6 EQU 58
DEF Gs6 EQU 59
DEF A_6 EQU 60
DEF As6 EQU 61
DEF B_6 EQU 62
DEF C_7 EQU 63
DEF Cs7 EQU 64
DEF D_7 EQU 65
DEF Ds7 EQU 66
DEF E_7 EQU 67
DEF F_7 EQU 68
DEF Fs7 EQU 69
DEF G_7 EQU 70
DEF Gs7 EQU 71
DEF A_7 EQU 72
DEF As7 EQU 73
DEF B_7 EQU 74
DEF C_8 EQU 75
DEF Cs8 EQU 76
DEF D_8 EQU 77
DEF Ds8 EQU 78
DEF E_8 EQU 79
DEF F_8 EQU 80
DEF Fs8 EQU 81
DEF G_8 EQU 82
DEF Gs8 EQU 83

ENDC
