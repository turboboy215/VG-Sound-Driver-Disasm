; Daiku no Gensan (J) - sound bank $3E ($4000-$61C7)
; Biox sound driver B v2. Disassembled for GBAudioLab\Biox.

DEF BIOXB_VER EQU 2
INCLUDE "hardware.inc"
INCLUDE "bioxB_sound.inc"

; ---- RAM ----
DEF wSndMus1        EQU $D44C
DEF wSndMus2        EQU $D465
DEF wSndMus3        EQU $D47E
DEF wSndMus4        EQU $D497
DEF wSndSfx1        EQU $D4B0
DEF wSndSfx2        EQU $D4C9
DEF wSndSfx3        EQU $D4E2
DEF wSndSfx4        EQU $D4FB
DEF wSndQueue       EQU $D514
DEF wSndQueuePtr    EQU $D51C
DEF wSndQueueCount  EQU $D51E
DEF wSndNRx1        EQU $D51F
DEF wSndChanIdx     EQU $D520
DEF wSndFadeMode    EQU $D521
DEF wSndFadeUnused  EQU $D522
DEF wSndFadeTimer   EQU $D523
DEF wSndWavePtr     EQU $D524
DEF wSndWaveSaved   EQU $D526
DEF hCurRomBank2    EQU $FFAA
DEF hSndPause       EQU $FFC1
DEF hCurRomBank     EQU $FFC8
DEF hSndCurMusic    EQU $FFD0
DEF hSndCurSfx      EQU $FFD1
DEF hSndTempo       EQU $FFD2
DEF hSndTempoStep   EQU $FFD3
DEF hSndTempoAcc    EQU $FFD5
DEF hSndTicks       EQU $FFD7
DEF hSndFlags       EQU $FFD8
DEF hSndPtr         EQU $FFD9
DEF hSndCount       EQU $FFDB
DEF hSndLength      EQU $FFDC
DEF hSndLoopCount   EQU $FFDD
DEF hSndLoopPtr     EQU $FFDE
DEF hSndRetPtr      EQU $FFE0
DEF hSndUnusedE2    EQU $FFE2
DEF hSndPEnvStart   EQU $FFE8
DEF hSndPEnvPtr     EQU $FFEA
DEF hSndFreq        EQU $FFEC
DEF hSndEnv         EQU $FFEE
DEF hSndDuty        EQU $FFEF
DEF hSndTranspose   EQU $FFF0


SECTION "Sound bank $3E", ROMX[$4000], BANK[$3E]

INCLUDE "Daiku_sound_common.inc"


SndMusicTable:
	dw Mus3E_0, Mus3E_1
Mus3E_0:
	db $0F	; channel mask
	dw Mus3E_0_Ch1, Mus3E_0_Ch2, Mus3E_0_Ch3, Mus3E_0_Ch4
Mus3E_0_Ch2:
	snd_tempo 142
	snd_env $60
	snd_duty $80
	snd_pitchenv SndPitchEnv_4A04
	snd_note C_6, 24
	snd_len 12
	snd_off
	snd_note A_5, 6
	snd_off
	snd_note D_6, 24
	snd_len 12
	snd_off
	snd_note A_5, 6
	snd_off
	snd_note C_6
	snd_off
	snd_note D_6
	snd_off
	snd_note F_6
	snd_off
	snd_note D_6
	snd_off
	snd_note C_6
	snd_off
	snd_note A_5, 5
	snd_len 1
	snd_off
	snd_note A_5, 5
	snd_len 1
	snd_off
	snd_note G_5, 5
	snd_len 1
	snd_off
	snd_note F_5, 5
	snd_len 1
	snd_off
	snd_note D_5, 5
	snd_len 1
	snd_off
	snd_note A_5, 5
	snd_len 1
	snd_off
	snd_note G_5, 24
	snd_len 12
	snd_off
	snd_note F_5, 6
	snd_off
	snd_note D_5, 24
	snd_len 12
	snd_off
	snd_note A_5, 6
	snd_off
	snd_note G_5
	snd_off
	snd_note F_5, 4
	snd_len 2
	snd_off
	snd_note F_5, 4
	snd_len 2
	snd_off
	snd_note D_5, 6
	snd_note F_5
	snd_note C_5
	snd_note A_4
	snd_note G_4
	snd_off
	snd_note C_5
	snd_off
	snd_note F_4
	snd_len 18
	snd_off
	snd_note F_5, 5
	snd_len 7
	snd_off
	snd_note F_5, 5
	snd_len 1
	snd_off
	snd_note G_5, 6
	snd_note A_5, 4
	snd_len 2
	snd_off
	snd_note A_5, 5
	snd_len 7
	snd_off
	snd_note C_6, 4
	snd_len 2
	snd_off
	snd_note D_6, 6
	snd_note C_5, 2
	snd_len 4
	snd_off
	snd_note D_5, 2
	snd_len 4
	snd_off
	snd_note C_5, 2
	snd_len 4
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note C_5, 3
	snd_len 9
	snd_off
	snd_note D_6, 5
	snd_len 7
	snd_off
	snd_note F_6, 5
	snd_len 1
	snd_off
	snd_note D_6, 5
	snd_len 1
	snd_off
	snd_note C_6, 3
	snd_off
	snd_note C_6, 5
	snd_len 7
	snd_off
	snd_note D_6, 5
	snd_len 1
	snd_off
	snd_note A_5, 6
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note C_5, 2
	snd_len 4
	snd_off
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note C_5, 3
	snd_off
	snd_note A_4
	snd_off
	snd_note Gs_4
	snd_off
	snd_note A_4
	snd_off
	snd_note F_5, 5
	snd_len 7
	snd_off
	snd_note F_5, 5
	snd_len 1
	snd_off
	snd_note G_5, 6
	snd_note A_5, 4
	snd_len 2
	snd_off
	snd_note A_5, 5
	snd_len 7
	snd_off
	snd_note C_6, 5
	snd_len 1
	snd_off
	snd_note D_6, 6
	snd_note D_6, 1
	snd_off
	snd_len 4
	snd_off
	snd_note D_5, 2
	snd_len 4
	snd_off
	snd_note C_5, 2
	snd_len 4
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note C_5, 3
	snd_len 9
	snd_off
	snd_note D_6, 4
	snd_len 8
	snd_off
	snd_note C_6, 5
	snd_len 1
	snd_off
	snd_note D_6, 4
	snd_len 2
	snd_off
	snd_note F_6, 4
	snd_len 2
	snd_off
	snd_note F_6, 5
	snd_len 7
	snd_off
	snd_note G_6, 4
	snd_len 2
	snd_off
	snd_note F_6, 6
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note C_5, 2
	snd_len 4
	snd_off
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note C_5, 3
	snd_off
	snd_note A_4
	snd_off
	snd_note Gs_4
	snd_off
	snd_note A_4
	snd_off
	snd_note C_6, 12
	snd_note F_5, 5
	snd_note A_5, 7
	snd_len 6
	snd_off
	snd_note C_6
	snd_off
	snd_note D_6, 96
	snd_note D_6, 31
	snd_len 23
	snd_off
	snd_note F_6, 12
	snd_note D_6, 6
	snd_note F_6
	snd_off
	snd_note A_6
	snd_off
	snd_note G_6, 96
	snd_note G_6, 6
	snd_note Gs_6, 36
	snd_len 12
	snd_off
	snd_note A_5, 6
	snd_len 30
	snd_off
	snd_note A_5, 6
	snd_off
	snd_note C_6
	snd_len 30
	snd_off
	snd_note C_6, 6
	snd_off
	snd_note D_5
	snd_off
	snd_note F_5
	snd_off
	snd_note E_5
	snd_off
	snd_note Gs_5
	snd_off
	snd_note G_5
	snd_len 18
	snd_off
	snd_note Ds_5, 6
	snd_len 18
	snd_off
	snd_note D_5, 6
	snd_len 30
	snd_off
	snd_note D_5, 6
	snd_off
	snd_note F_5
	snd_len 30
	snd_off
	snd_note F_5, 6
	snd_off
	snd_note E_5
	snd_off
	snd_note C_5
	snd_off
	snd_note B_4
	snd_off
	snd_note Ds_5
	snd_off
	snd_note D_5
	snd_off
	snd_note Gs_4, 36
	snd_pitchenv SndPitchEnv_499B
	snd_note D_7, 8
	snd_note D_6
	snd_note A_6
	snd_note G_6
	snd_note A_6
	snd_note A_5
	snd_note F_6
	snd_note E_6
	snd_note D_6
	snd_note D_5
	snd_note As_5
	snd_note G_5
	snd_note A_5
	snd_note D_6
	snd_note Cs_6
	snd_note D_6
	snd_note F_6
	snd_note A_6
	snd_note D_4
	snd_len 40
	snd_off
	snd_note D_7, 8
	snd_note D_6
	snd_note A_6
	snd_note G_6
	snd_note A_6
	snd_note A_5
	snd_note F_6
	snd_note E_6
	snd_note D_6
	snd_note D_5
	snd_note As_5
	snd_note G_5
	snd_note A_5
	snd_note D_6
	snd_note Cs_6
	snd_note D_6
	snd_note F_6
	snd_note A_6
	snd_env $70
	snd_duty $80
	snd_note D_7
	snd_note A_6
	snd_note Fs_6
	snd_note D_6
	snd_note A_5
	snd_note Fs_5
	snd_env $60
	snd_duty $80
	snd_loop 3
	snd_note B_5, 1
	snd_len 11
	snd_off
	snd_note B_5, 1
	snd_len 11
	snd_off
	snd_note B_6, 1
	snd_len 5
	snd_off
	snd_note Fs_6, 1
	snd_len 11
	snd_off
	snd_note B_5, 1
	snd_len 11
	snd_off
	snd_note B_5, 1
	snd_len 11
	snd_off
	snd_note B_5, 1
	snd_len 5
	snd_off
	snd_note B_6, 1
	snd_len 11
	snd_off
	snd_note Fs_6, 1
	snd_len 11
	snd_off
	snd_endloop
	snd_note D_6, 6
	snd_off
	snd_note A_5, 3
	snd_len 5
	snd_off
	snd_note A_5, 3
	snd_len 1
	snd_off
	snd_note Cs_6, 4
	snd_len 8
	snd_off
	snd_note Gs_5, 3
	snd_len 5
	snd_off
	snd_note Gs_5, 3
	snd_len 1
	snd_off
	snd_note C_6, 4
	snd_off
	snd_note C_6, 3
	snd_len 1
	snd_off
	snd_note C_6, 4
	snd_off
	snd_note E_6, 3
	snd_len 1
	snd_off
	snd_note C_6, 5
	snd_len 19
	snd_off
	snd_transpose $0C
	snd_env $80
	snd_duty $00
	snd_note F_5, 3
	snd_len 9
	snd_off
	snd_note D_6, 3
	snd_off
	snd_note F_6
	snd_off
	snd_note A_6
	snd_off
	snd_note B_6
	snd_off
	snd_note C_7
	snd_off
	snd_note G_6
	snd_off
	snd_note D_7
	snd_len 9
	snd_off
	snd_note C_7, 3
	snd_len 9
	snd_off
	snd_note D_7, 3
	snd_len 9
	snd_off
	snd_note C_7, 3
	snd_len 9
	snd_off
	snd_len 96
	snd_off
	snd_off
	snd_off
	snd_transpose $00
	snd_env $70
	snd_duty $80
	snd_note G_5, 6
	snd_off
	snd_note Fs_5
	snd_note G_5
	snd_off
	snd_note C_6
	snd_note E_6
	snd_off
	snd_note D_6
	snd_off
	snd_note D_6
	snd_note A_5
	snd_off
	snd_note A_5
	snd_note D_6
	snd_off
	snd_note C_6
	snd_off
	snd_note C_6
	snd_note E_5
	snd_off
	snd_note E_5
	snd_note A_5
	snd_off
	snd_note G_5, 36
	snd_len 12
	snd_off
	snd_env $70
	snd_duty $40
	snd_tempo 145
	snd_note E_6, 18
	snd_note D_6
	snd_note C_6, 12
	snd_note F_6, 18
	snd_note E_6
	snd_note D_6, 12
	snd_tempo 147
	snd_note C_6, 18
	snd_note As_5
	snd_note Gs_5, 12
	snd_env $80
	snd_duty $80
	snd_tempo 149
	snd_note G_5, 6
	snd_note E_5
	snd_note C_5
	snd_note A_5, 12
	snd_note E_5, 6
	snd_note Cs_5, 12
	snd_tempo 150
	snd_loop 2
	snd_note C_6, 24
	snd_note G_3, 1
	snd_len 11
	snd_off
	snd_note A_5, 6
	snd_off
	snd_note D_6, 24
	snd_note G_3, 1
	snd_len 11
	snd_off
	snd_note A_5, 6
	snd_off
	snd_note C_6
	snd_off
	snd_note D_6
	snd_off
	snd_note F_6
	snd_off
	snd_note D_6
	snd_off
	snd_note C_6
	snd_note C_6, 1
	snd_len 5
	snd_off
	snd_note A_5
	snd_len 1
	snd_off
	snd_note A_5, 5
	snd_len 1
	snd_off
	snd_note G_5, 5
	snd_len 1
	snd_off
	snd_note F_5, 5
	snd_len 1
	snd_off
	snd_note D_5, 5
	snd_len 1
	snd_off
	snd_note A_5, 5
	snd_len 1
	snd_off
	snd_note G_5, 24
	snd_note G_3, 1
	snd_len 11
	snd_off
	snd_note F_5, 6
	snd_off
	snd_note D_5, 24
	snd_note G_3, 1
	snd_len 11
	snd_off
	snd_note A_5, 6
	snd_off
	snd_note G_5
	snd_off
	snd_note F_5, 4
	snd_len 2
	snd_off
	snd_note F_5, 4
	snd_len 2
	snd_off
	snd_note D_5, 6
	snd_note F_5
	snd_note C_5
	snd_note A_4
	snd_note C_5
	snd_off
	snd_note D_5
	snd_off
	snd_note D_5
	snd_off
	snd_note G_3, 1
	snd_len 11
	snd_off
	snd_endloop
	snd_note D_5, 36
	snd_note F_5, 12
	snd_note G_5, 36
	snd_note D_5, 12
	snd_note F_5, 36
	snd_note A_4, 12
	snd_note C_5, 18
	snd_note Cs_5, 6
	snd_note D_5, 12
	snd_note F_5
	snd_note G_5, 36
	snd_note A_5, 12
	snd_note F_5, 36
	snd_note G_5, 12
	snd_note C_6, 24
	snd_note A_5, 18
	snd_note G_5, 6
	snd_note F_5, 18
	snd_note G_5, 6
	snd_note D_5, 24
	snd_note D_5, 36
	snd_note F_5, 12
	snd_note G_5, 36
	snd_note D_5, 12
	snd_note F_5, 36
	snd_note A_4, 12
	snd_note C_5, 18
	snd_note Cs_5, 6
	snd_note D_5, 12
	snd_note F_5
	snd_note G_5, 36
	snd_note A_5, 12
	snd_note C_6, 24
	snd_note A_5, 18
	snd_note G_5, 6
	snd_note A_5, 96
	snd_env $87
	snd_pitchenv SndPitchEnv_49E9
Trk3E_5635:
	snd_note G_5, 18
	snd_note F_5, 5
	snd_len 1
	snd_off
	snd_note G_5, 72
	snd_note A_5, 18
	snd_note G_5, 5
	snd_len 1
	snd_off
	snd_note A_5, 72
	snd_note G_5, 4
	snd_len 2
	snd_off
	snd_note G_5, 6
	snd_off
	snd_note F_5, 5
	snd_len 1
	snd_off
	snd_note G_5, 72
	snd_note A_5, 4
	snd_len 2
	snd_off
	snd_note A_5, 6
	snd_off
	snd_note G_5, 5
	snd_len 1
	snd_off
	snd_note A_5, 72
	snd_jump Trk3E_5635
Mus3E_0_Ch1:
	snd_duty $40
	snd_env $60
	snd_note C_5, 24
	snd_len 12
	snd_off
	snd_note A_4, 6
	snd_off
	snd_note D_5, 24
	snd_len 12
	snd_off
	snd_note A_4, 6
	snd_off
	snd_note C_5
	snd_off
	snd_note D_5
	snd_off
	snd_note F_5
	snd_off
	snd_note D_5
	snd_off
	snd_note C_5
	snd_off
	snd_note A_4, 5
	snd_len 1
	snd_off
	snd_note A_4, 5
	snd_len 1
	snd_off
	snd_note G_4, 5
	snd_len 1
	snd_off
	snd_note F_4, 5
	snd_len 1
	snd_off
	snd_note D_4, 5
	snd_len 1
	snd_off
	snd_note A_4, 5
	snd_len 1
	snd_off
	snd_note G_4, 24
	snd_len 12
	snd_off
	snd_note F_4, 6
	snd_off
	snd_note D_4, 24
	snd_len 12
	snd_off
	snd_note A_4, 6
	snd_off
	snd_note G_4
	snd_off
	snd_note F_4, 4
	snd_len 2
	snd_off
	snd_note F_4, 4
	snd_len 2
	snd_off
	snd_note D_4, 6
	snd_note F_4
	snd_note C_4
	snd_note A_3
	snd_note G_3
	snd_off
	snd_note C_4
	snd_off
	snd_note F_3
	snd_len 18
	snd_off
	snd_loop 2
	snd_note F_3, 1
	snd_len 5
	snd_off
	snd_note F_4, 1
	snd_len 5
	snd_off
	snd_note C_5, 6
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note C_5, 1
	snd_len 11
	snd_off
	snd_note Gs_4, 6
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note D_5, 1
	snd_len 5
	snd_off
	snd_note D_5, 4
	snd_len 2
	snd_off
	snd_note F_5, 6
	snd_note D_5, 3
	snd_off
	snd_note F_5, 6
	snd_off
	snd_note D_5
	snd_len 12
	snd_off
	snd_note G_4, 1
	snd_len 5
	snd_off
	snd_note D_5, 6
	snd_note As_4, 4
	snd_len 2
	snd_off
	snd_note D_5, 1
	snd_len 11
	snd_off
	snd_note As_4, 6
	snd_note B_4, 4
	snd_len 2
	snd_off
	snd_note C_5, 1
	snd_len 5
	snd_off
	snd_note C_5, 3
	snd_off
	snd_note D_5, 6
	snd_note C_5, 1
	snd_len 5
	snd_off
	snd_note D_5, 6
	snd_note C_5, 1
	snd_len 5
	snd_off
	snd_note A_4, 6
	snd_note C_5, 1
	snd_len 5
	snd_off
	snd_endloop
	snd_env $72
	snd_note D_5, 6
	snd_off
	snd_note C_5, 5
	snd_len 7
	snd_off
	snd_note D_5, 6
	snd_off
	snd_note C_5
	snd_len 30
	snd_off
	snd_note A_4, 4
	snd_len 2
	snd_off
	snd_note A_4, 5
	snd_len 7
	snd_off
	snd_note C_5, 5
	snd_len 1
	snd_off
	snd_note D_5, 5
	snd_len 7
	snd_off
	snd_note C_5, 5
	snd_len 7
	snd_off
	snd_note D_5, 6
	snd_off
	snd_note C_5, 5
	snd_len 55
	snd_off
	snd_note D_5, 6
	snd_off
	snd_note C_5, 5
	snd_len 7
	snd_off
	snd_note D_5, 6
	snd_off
	snd_note C_5
	snd_len 30
	snd_off
	snd_note D_5, 4
	snd_len 2
	snd_off
	snd_note F_5, 6
	snd_off
	snd_note G_5, 4
	snd_len 2
	snd_off
	snd_note A_5, 5
	snd_len 7
	snd_off
	snd_note F_5, 5
	snd_len 7
	snd_off
	snd_note G_5, 6
	snd_off
	snd_note D_5, 5
	snd_len 43
	snd_off
	snd_env $83
	snd_pitchenv SndPitchEnv_4ABD
	snd_note F_7, 12
	snd_pitchenv SndPitchEnv_4AD7
	snd_env $81
	snd_duty $00
	snd_loop 2
	snd_len 12
	snd_off
	snd_note D_6, 3
	snd_off
	snd_note F_6
	snd_off
	snd_note A_6
	snd_off
	snd_note B_6
	snd_off
	snd_note C_7
	snd_off
	snd_note G_6
	snd_off
	snd_note D_7
	snd_len 9
	snd_off
	snd_note C_7, 3
	snd_len 9
	snd_off
	snd_note D_7, 3
	snd_len 9
	snd_off
	snd_note C_7, 3
	snd_len 9
	snd_off
	snd_len 96
	snd_off
	snd_endloop
	snd_env $40
	snd_duty $40
	snd_note A_6, 4
	snd_len 2
	snd_off
	snd_note A_6, 4
	snd_len 2
	snd_off
	snd_note A_6, 4
	snd_len 14
	snd_off
	snd_note A_6, 4
	snd_len 2
	snd_off
	snd_note A_6, 4
	snd_len 8
	snd_off
	snd_note A_6, 4
	snd_len 8
	snd_off
	snd_note A_6, 4
	snd_len 8
	snd_off
	snd_note A_6, 4
	snd_len 8
	snd_off
	snd_note A_6, 4
	snd_len 2
	snd_off
	snd_note A_6, 4
	snd_len 2
	snd_off
	snd_note Gs_6, 4
	snd_len 8
	snd_off
	snd_note Gs_6, 4
	snd_len 8
	snd_off
	snd_note Gs_6, 4
	snd_len 8
	snd_off
	snd_note Gs_6, 4
	snd_len 14
	snd_off
	snd_note Gs_6, 4
	snd_len 2
	snd_off
	snd_note Gs_6, 4
	snd_len 8
	snd_off
	snd_note Gs_6, 4
	snd_len 8
	snd_off
	snd_note Gs_6, 4
	snd_len 2
	snd_off
	snd_note Gs_6, 4
	snd_len 2
	snd_off
	snd_note A_6, 4
	snd_len 2
	snd_off
	snd_note A_6, 4
	snd_len 2
	snd_off
	snd_note A_6, 4
	snd_len 14
	snd_off
	snd_note A_6, 4
	snd_len 2
	snd_off
	snd_note A_6, 4
	snd_len 8
	snd_off
	snd_note A_6, 4
	snd_len 8
	snd_off
	snd_note A_6, 4
	snd_len 8
	snd_off
	snd_note A_6, 4
	snd_len 8
	snd_off
	snd_note A_6, 4
	snd_len 2
	snd_off
	snd_note A_6, 4
	snd_len 2
	snd_off
	snd_note A_6, 4
	snd_len 8
	snd_off
	snd_note A_6, 4
	snd_len 8
	snd_off
	snd_note A_6, 4
	snd_len 8
	snd_off
	snd_note A_6, 4
	snd_len 8
	snd_off
	snd_env $70
	snd_duty $80
	snd_note Fs_7
	snd_note D_7
	snd_note B_6
	snd_note A_6
	snd_note Fs_6
	snd_note D_6
	snd_loop 2
	snd_env $70
	snd_duty $80
	snd_pitchenv SndPitchEnv_49E9
	snd_note Fs_5, 22
	snd_len 2
	snd_off
	snd_note A_4, 16
	snd_len 2
	snd_off
	snd_note B_4, 29
	snd_len 1
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_note E_5, 4
	snd_len 8
	snd_off
	snd_endloop
	snd_note Fs_5, 22
	snd_len 2
	snd_off
	snd_note A_4, 16
	snd_len 2
	snd_off
	snd_note B_4, 24
	snd_len 6
	snd_off
	snd_note D_5, 4
	snd_len 7
	snd_off
	snd_note As_5, 1
	snd_note B_5, 4
	snd_len 8
	snd_off
	snd_note A_5, 48
	snd_len 12
	snd_off
	snd_note B_5, 6
	snd_off
	snd_note C_6
	snd_len 18
	snd_off
	snd_env $60
	snd_duty $80
	snd_pitchenv SndPitchEnv_4AD7
	snd_len 84
	snd_off
	snd_note D_5, 8
	snd_note C_5, 4
	snd_note A_5, 7
	snd_len 1
	snd_off
	snd_note A_5, 4
	snd_note F_5, 8
	snd_note B_5, 48
	snd_len 4
	snd_off
	snd_note Gs_5, 7
	snd_len 1
	snd_off
	snd_note A_5, 4
	snd_note F_5, 6
	snd_len 2
	snd_off
	snd_note C_5, 4
	snd_note Ds_5, 8
	snd_note D_5, 4
	snd_note Ds_5, 7
	snd_len 1
	snd_off
	snd_note Ds_5, 4
	snd_note A_5, 2
	snd_len 6
	snd_off
	snd_note As_5, 2
	snd_off
	snd_note Ds_6
	snd_len 6
	snd_off
	snd_note G_6, 2
	snd_off
	snd_note Ds_5, 8
	snd_note D_5, 4
	snd_note Ds_5, 7
	snd_len 1
	snd_off
	snd_note Ds_5, 4
	snd_note A_6, 2
	snd_len 1
	snd_off
	snd_len 5
	snd_off
	snd_note As_6, 2
	snd_off
	snd_note Ds_7
	snd_len 6
	snd_off
	snd_note G_7, 2
	snd_off
	snd_note E_5, 8
	snd_note F_5, 4
	snd_note E_5, 8
	snd_note F_5, 4
	snd_note D_5, 8
	snd_note F_5, 4
	snd_note D_5, 8
	snd_note C_5, 4
	snd_note B_4, 8
	snd_note C_5, 4
	snd_note B_4, 8
	snd_note C_5, 4
	snd_note As_4, 8
	snd_note C_5, 4
	snd_note As_4, 8
	snd_note C_5, 4
	snd_note G_4, 48
	snd_len 96
	snd_off
	snd_len 11
	snd_off
	snd_note Fs_8, 1
	snd_note G_8, 3
	snd_len 9
	snd_off
	snd_note G_7, 4
	snd_len 20
	snd_off
	snd_note G_5, 6
	snd_off
	snd_note Fs_5
	snd_note G_5
	snd_off
	snd_note C_6
	snd_note E_6
	snd_off
	snd_note D_6
	snd_off
	snd_note D_6
	snd_note A_5
	snd_off
	snd_note A_5
	snd_note D_6
	snd_off
	snd_note C_6
	snd_off
	snd_note C_6
	snd_note D_5
	snd_off
	snd_note D_5
	snd_note G_5
	snd_off
	snd_note C_4, 4
	snd_len 2
	snd_off
	snd_note C_5, 5
	snd_len 1
	snd_off
	snd_note C_4, 4
	snd_len 2
	snd_off
	snd_note As_3, 18
	snd_note A_3, 12
	snd_pitchenv SndPitchEnv_498E
	snd_note D_5, 96
	snd_note D_5
	snd_note D_5
	snd_note D_5, 94
	snd_len 2
	snd_off
	snd_note C_5, 24
	snd_note G_2, 1
	snd_len 11
	snd_off
	snd_note A_4, 6
	snd_off
	snd_note D_5, 24
	snd_note G_2, 1
	snd_len 11
	snd_off
	snd_note A_4, 6
	snd_off
	snd_note C_5
	snd_off
	snd_note D_5
	snd_off
	snd_note F_5
	snd_off
	snd_note D_5
	snd_off
	snd_note C_5
	snd_note C_5, 1
	snd_len 5
	snd_off
	snd_note A_4
	snd_len 1
	snd_off
	snd_note A_4, 5
	snd_len 1
	snd_off
	snd_note G_4, 5
	snd_len 1
	snd_off
	snd_note F_4, 5
	snd_len 1
	snd_off
	snd_note D_4, 5
	snd_len 1
	snd_off
	snd_note A_4, 5
	snd_len 1
	snd_off
	snd_note G_4, 24
	snd_note G_2, 1
	snd_len 11
	snd_off
	snd_note F_4, 6
	snd_off
	snd_note D_4, 24
	snd_note G_2, 1
	snd_len 11
	snd_off
	snd_note A_4, 6
	snd_off
	snd_note G_4
	snd_off
	snd_note F_4, 4
	snd_len 2
	snd_off
	snd_note F_4, 4
	snd_len 2
	snd_off
	snd_note D_4, 6
	snd_note F_4
	snd_note C_4
	snd_note A_3
	snd_note C_4
	snd_off
	snd_note D_4
	snd_off
	snd_note D_4
	snd_off
	snd_note G_2, 1
	snd_len 11
	snd_off
	snd_loop 3
	snd_note D_7, 1
	snd_len 5
	snd_off
	snd_note F_7, 2
	snd_len 4
	snd_off
	snd_note D_7, 1
	snd_len 5
	snd_off
	snd_note C_7, 1
	snd_len 5
	snd_off
	snd_note D_7, 1
	snd_len 5
	snd_off
	snd_note F_7, 2
	snd_len 4
	snd_off
	snd_note D_7, 1
	snd_len 5
	snd_off
	snd_note C_7, 1
	snd_len 5
	snd_off
	snd_note D_7, 1
	snd_len 5
	snd_off
	snd_note C_7, 1
	snd_len 5
	snd_off
	snd_note A_6, 1
	snd_len 5
	snd_off
	snd_note C_7, 1
	snd_len 5
	snd_off
	snd_note A_6, 1
	snd_len 5
	snd_off
	snd_note C_7, 2
	snd_len 4
	snd_off
	snd_note A_6, 1
	snd_len 5
	snd_off
	snd_note F_6, 1
	snd_len 5
	snd_off
	snd_note G_6, 1
	snd_len 5
	snd_off
	snd_note D_6, 3
	snd_off
	snd_note F_6, 1
	snd_len 5
	snd_off
	snd_note G_6, 1
	snd_len 5
	snd_off
	snd_note A_6, 1
	snd_len 5
	snd_off
	snd_note G_6, 3
	snd_off
	snd_note F_6, 1
	snd_len 5
	snd_off
	snd_note C_6, 1
	snd_len 5
	snd_off
	snd_note D_5, 12
	snd_note A_5, 2
	snd_note D_6
	snd_off
	snd_note C_5, 6
	snd_note D_5, 12
	snd_note A_5, 2
	snd_note D_6
	snd_off
	snd_note C_5, 6
	snd_endloop
	snd_note D_7, 1
	snd_len 5
	snd_off
	snd_note F_7, 2
	snd_len 4
	snd_off
	snd_note D_7, 1
	snd_len 5
	snd_off
	snd_note C_7, 1
	snd_len 5
	snd_off
	snd_note D_7, 1
	snd_len 5
	snd_off
	snd_note F_7, 2
	snd_len 4
	snd_off
	snd_note D_7, 1
	snd_len 5
	snd_off
	snd_note C_7, 1
	snd_len 5
	snd_off
	snd_note A_6, 1
	snd_len 5
	snd_off
	snd_note C_7, 1
	snd_len 5
	snd_off
	snd_note A_6, 1
	snd_len 5
	snd_off
	snd_note G_6, 1
	snd_len 5
	snd_off
	snd_note A_6, 1
	snd_len 5
	snd_off
	snd_note C_7, 2
	snd_len 4
	snd_off
	snd_note A_6, 1
	snd_len 5
	snd_off
	snd_note F_6, 1
	snd_len 5
	snd_off
	snd_note E_6, 1
	snd_len 5
	snd_off
	snd_note C_6, 3
	snd_off
	snd_note E_6, 1
	snd_len 5
	snd_off
	snd_note G_6, 1
	snd_len 5
	snd_off
	snd_note A_6, 1
	snd_len 5
	snd_off
	snd_note G_6, 3
	snd_off
	snd_note E_6, 1
	snd_len 5
	snd_off
	snd_note C_6, 1
	snd_len 5
	snd_off
	snd_note A_5, 12
	snd_note A_5, 2
	snd_note D_6
	snd_off
	snd_note C_6, 6
	snd_note A_5, 12
	snd_note A_5, 2
	snd_note D_6
	snd_off
	snd_note C_6, 6
	snd_note G_6, 18
	snd_note F_6, 6
	snd_note G_6, 24
	snd_env $67
	snd_pitchenv SndPitchEnv_499B
Trk3E_5A6B:
	snd_note G_7, 18
	snd_note F_7, 6
	snd_note G_7, 72
	snd_note A_7, 18
	snd_note G_7, 6
	snd_note A_7, 72
	snd_note G_7, 4
	snd_len 2
	snd_off
	snd_note G_7, 6
	snd_off
	snd_note F_7
	snd_note G_7, 72
	snd_note A_7, 4
	snd_len 2
	snd_off
	snd_note A_7, 6
	snd_off
	snd_note G_7
	snd_note A_7, 72
	snd_jump Trk3E_5A6B
Mus3E_0_Ch3:
	snd_duty $00
	snd_env2 $20
	snd_wave SndWave08
	snd_note F_4, 24
	snd_note F_3, 42
	snd_len 6
	snd_off
	snd_note F_4, 42
	snd_len 6
	snd_off
	snd_note F_3, 41
	snd_len 7
	snd_off
	snd_note F_4, 43
	snd_len 5
	snd_off
	snd_note As_3, 38
	snd_len 10
	snd_off
	snd_note As_4, 39
	snd_len 9
	snd_off
	snd_note C_4, 24
	snd_note G_3, 6
	snd_off
	snd_note C_4
	snd_off
	snd_note F_3, 8
	snd_len 4
	snd_off
	snd_note C_3
	snd_len 8
	snd_off
	snd_loop 2
	snd_note F_4, 6
	snd_note A_5, 1
	snd_len 5
	snd_off
	snd_note F_4, 2
	snd_len 4
	snd_off
	snd_note F_4
	snd_len 2
	snd_off
	snd_note C_4, 6
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note D_4, 6
	snd_note A_5, 1
	snd_len 5
	snd_off
	snd_note F_4, 6
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note D_5, 2
	snd_len 4
	snd_off
	snd_note D_5, 2
	snd_len 4
	snd_off
	snd_note C_4, 6
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note A_3, 6
	snd_note F_5, 1
	snd_len 5
	snd_off
	snd_note G_3, 6
	snd_note As_5, 4
	snd_len 2
	snd_off
	snd_note D_6, 1
	snd_len 5
	snd_off
	snd_note As_5, 1
	snd_len 5
	snd_off
	snd_note C_4, 6
	snd_note D_6, 2
	snd_len 4
	snd_off
	snd_note G_3, 6
	snd_note As_5, 2
	snd_len 4
	snd_off
	snd_note F_3, 6
	snd_note F_6, 3
	snd_off
	snd_note F_3, 1
	snd_len 5
	snd_off
	snd_note F_3, 1
	snd_len 5
	snd_off
	snd_note C_4, 6
	snd_note D_5, 1
	snd_len 5
	snd_off
	snd_note D_4, 6
	snd_note A_3, 1
	snd_len 5
	snd_off
	snd_endloop
	snd_note F_3, 5
	snd_len 1
	snd_off
	snd_note A_5
	snd_len 5
	snd_off
	snd_note F_3, 6
	snd_off
	snd_note A_3
	snd_note C_4, 7
	snd_len 4
	snd_off
	snd_note A_5, 1
	snd_note D_4, 6
	snd_note F_4
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note D_4, 6
	snd_note D_5, 2
	snd_len 4
	snd_off
	snd_note F_4
	snd_len 2
	snd_off
	snd_note F_5
	snd_len 4
	snd_off
	snd_note G_4, 5
	snd_len 1
	snd_off
	snd_note F_5
	snd_len 5
	snd_off
	snd_note A_4, 6
	snd_note As_5, 4
	snd_len 2
	snd_off
	snd_note C_5, 6
	snd_note As_5, 1
	snd_len 5
	snd_off
	snd_note D_5, 6
	snd_note D_6, 2
	snd_len 4
	snd_off
	snd_note C_5, 6
	snd_note As_5, 2
	snd_len 4
	snd_off
	snd_note A_4, 6
	snd_note C_5
	snd_off
	snd_note G_4
	snd_note A_4
	snd_note C_6, 1
	snd_len 5
	snd_off
	snd_note F_4, 12
	snd_note F_3, 5
	snd_len 1
	snd_off
	snd_note A_5
	snd_len 5
	snd_off
	snd_note F_3, 6
	snd_off
	snd_note A_3
	snd_note C_4, 7
	snd_len 4
	snd_off
	snd_note A_5, 1
	snd_note D_4, 6
	snd_note F_4
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note D_4, 6
	snd_note D_5, 2
	snd_len 4
	snd_off
	snd_note F_4
	snd_len 2
	snd_off
	snd_note F_5
	snd_len 4
	snd_off
	snd_note G_4, 5
	snd_len 1
	snd_off
	snd_note F_5
	snd_len 5
	snd_off
	snd_note A_4, 6
	snd_note As_5, 4
	snd_len 2
	snd_off
	snd_note C_5, 6
	snd_note As_5, 1
	snd_len 5
	snd_off
	snd_note D_5, 6
	snd_note D_6, 2
	snd_len 4
	snd_off
	snd_note C_5, 6
	snd_note As_5, 2
	snd_len 4
	snd_off
	snd_note A_4, 6
	snd_note C_5
	snd_off
	snd_note Gs_4
	snd_note A_4
	snd_note E_5, 1
	snd_len 5
	snd_off
	snd_pitchenv SndPitchEnv_4ABD
	snd_note F_6, 12
	snd_pitchenv SndPitchEnv_4AD7
	snd_wave SndWave00
	snd_loop 2
	snd_note D_3, 6
	snd_note A_5, 1
	snd_len 5
	snd_off
	snd_note A_3, 6
	snd_off
	snd_note C_4
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note D_3, 6
	snd_note A_5, 1
	snd_len 5
	snd_off
	snd_note B_3, 6
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note G_3, 6
	snd_note D_5, 2
	snd_len 4
	snd_off
	snd_note D_3, 6
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note As_3, 6
	snd_note F_5, 1
	snd_len 5
	snd_off
	snd_note A_3, 6
	snd_note A_5, 4
	snd_len 2
	snd_off
	snd_note Fs_3, 6
	snd_note A_5, 1
	snd_len 5
	snd_off
	snd_note G_3, 6
	snd_note C_6, 2
	snd_len 4
	snd_off
	snd_note Cs_4, 6
	snd_note G_5, 2
	snd_len 4
	snd_off
	snd_note C_4, 6
	snd_note D_6, 3
	snd_off
	snd_note F_3, 6
	snd_off
	snd_note E_3
	snd_note D_5, 1
	snd_len 5
	snd_off
	snd_note As_3, 6
	snd_len 6
	snd_off
	snd_endloop
	snd_wave SndWave11
	snd_note D_4, 10
	snd_len 2
	snd_off
	snd_note D_4, 10
	snd_len 2
	snd_off
	snd_note F_4, 10
	snd_len 2
	snd_off
	snd_note C_4, 10
	snd_len 2
	snd_off
	snd_note D_4, 10
	snd_len 2
	snd_off
	snd_note D_4, 10
	snd_len 2
	snd_off
	snd_note A_3, 10
	snd_len 2
	snd_off
	snd_note C_4, 10
	snd_len 2
	snd_off
	snd_note B_3, 10
	snd_len 2
	snd_off
	snd_note As_3, 10
	snd_len 2
	snd_off
	snd_note A_3, 10
	snd_len 2
	snd_off
	snd_note Gs_3, 10
	snd_len 2
	snd_off
	snd_note G_3, 10
	snd_len 2
	snd_off
	snd_note As_3, 10
	snd_len 2
	snd_off
	snd_note Gs_3, 10
	snd_len 2
	snd_off
	snd_note A_3, 10
	snd_len 2
	snd_off
	snd_note D_4, 10
	snd_len 2
	snd_off
	snd_note D_4, 10
	snd_len 2
	snd_off
	snd_note F_4, 10
	snd_len 2
	snd_off
	snd_note C_4, 10
	snd_len 2
	snd_off
	snd_note D_4, 10
	snd_len 2
	snd_off
	snd_note D_4, 10
	snd_len 2
	snd_off
	snd_note A_3, 10
	snd_len 2
	snd_off
	snd_note C_4, 10
	snd_len 2
	snd_off
	snd_note B_3, 10
	snd_len 2
	snd_off
	snd_note As_3, 10
	snd_len 2
	snd_off
	snd_note A_3, 10
	snd_len 2
	snd_off
	snd_note Gs_3, 10
	snd_len 2
	snd_off
	snd_note G_3, 10
	snd_len 2
	snd_off
	snd_note Fs_3, 10
	snd_len 2
	snd_off
	snd_note F_3, 10
	snd_len 2
	snd_off
	snd_note Fs_3, 10
	snd_len 2
	snd_off
	snd_wave SndWave07
	snd_note D_3, 8
	snd_note D_4, 3
	snd_len 1
	snd_off
	snd_note Fs_3, 8
	snd_note Fs_4, 3
	snd_len 1
	snd_off
	snd_note A_3, 8
	snd_note A_4, 3
	snd_len 1
	snd_off
	snd_note B_3, 8
	snd_note B_4, 3
	snd_len 1
	snd_off
	snd_note C_4, 8
	snd_note C_5, 3
	snd_len 1
	snd_off
	snd_note B_3, 8
	snd_note B_4, 3
	snd_len 1
	snd_off
	snd_note A_3, 8
	snd_note A_4, 3
	snd_len 1
	snd_off
	snd_note Fs_3, 8
	snd_note Fs_4, 3
	snd_len 1
	snd_off
	snd_note G_3, 8
	snd_note G_4, 3
	snd_len 1
	snd_off
	snd_note B_3, 8
	snd_note B_4, 3
	snd_len 1
	snd_off
	snd_note D_4, 8
	snd_note D_5, 3
	snd_len 1
	snd_off
	snd_note E_4, 8
	snd_note E_5, 3
	snd_len 1
	snd_off
	snd_note F_4, 8
	snd_note F_5, 3
	snd_len 1
	snd_off
	snd_note E_4, 8
	snd_note E_5, 3
	snd_len 1
	snd_off
	snd_note D_4, 8
	snd_note D_5, 3
	snd_len 1
	snd_off
	snd_note B_3, 8
	snd_note B_4, 3
	snd_len 1
	snd_off
	snd_note D_3, 8
	snd_note D_4, 3
	snd_len 1
	snd_off
	snd_note Fs_3, 8
	snd_note Fs_4, 3
	snd_len 1
	snd_off
	snd_note A_3, 8
	snd_note A_4, 3
	snd_len 1
	snd_off
	snd_note B_3, 8
	snd_note B_4, 3
	snd_len 1
	snd_off
	snd_note C_4, 8
	snd_note C_5, 3
	snd_len 1
	snd_off
	snd_note B_3, 8
	snd_note B_4, 3
	snd_len 1
	snd_off
	snd_note A_3, 8
	snd_note A_4, 3
	snd_len 1
	snd_off
	snd_note Fs_3, 8
	snd_note Fs_4, 3
	snd_len 1
	snd_off
	snd_note D_3, 6
	snd_off
	snd_note D_4, 4
	snd_off
	snd_note D_4
	snd_note Cs_3, 6
	snd_off
	snd_note Cs_4, 4
	snd_off
	snd_note Cs_4
	snd_note C_3, 6
	snd_off
	snd_note Ds_5
	snd_off
	snd_note E_5
	snd_len 18
	snd_off
	snd_note F_3, 6
	snd_len 18
	snd_off
	snd_note C_3, 6
	snd_len 18
	snd_off
	snd_note F_3, 6
	snd_off
	snd_note C_3
	snd_off
	snd_note D_3
	snd_off
	snd_note E_3
	snd_off
	snd_note F_3
	snd_len 18
	snd_off
	snd_note C_4, 6
	snd_len 18
	snd_off
	snd_note D_4, 6
	snd_off
	snd_note C_4
	snd_off
	snd_note A_3
	snd_off
	snd_note F_3
	snd_off
	snd_note Ds_3
	snd_len 18
	snd_off
	snd_note As_2, 6
	snd_len 18
	snd_off
	snd_note Ds_3, 6
	snd_off
	snd_note As_2
	snd_off
	snd_note C_3
	snd_off
	snd_note D_3
	snd_off
	snd_note F_3
	snd_len 18
	snd_off
	snd_note C_3, 6
	snd_len 18
	snd_off
	snd_note F_3, 6
	snd_off
	snd_note E_3
	snd_off
	snd_note D_3
	snd_off
	snd_note Cs_3
	snd_off
	snd_wave SndWave08
	snd_note C_3, 9
	snd_len 3
	snd_off
	snd_note E_4, 9
	snd_len 3
	snd_off
	snd_note C_3, 9
	snd_len 3
	snd_off
	snd_note G_4, 9
	snd_len 3
	snd_off
	snd_note F_3, 4
	snd_len 8
	snd_off
	snd_note F_3, 4
	snd_len 2
	snd_off
	snd_note A_4, 5
	snd_len 1
	snd_off
	snd_note F_3, 4
	snd_len 8
	snd_off
	snd_note B_3, 9
	snd_len 3
	snd_off
	snd_note C_3, 9
	snd_len 3
	snd_off
	snd_note E_4, 9
	snd_len 3
	snd_off
	snd_note C_3, 9
	snd_len 3
	snd_off
	snd_note C_4, 9
	snd_len 3
	snd_off
	snd_note G_3, 4
	snd_len 8
	snd_off
	snd_note G_3, 4
	snd_len 2
	snd_off
	snd_note B_3, 4
	snd_len 2
	snd_off
	snd_note G_3, 4
	snd_len 8
	snd_off
	snd_note G_4, 9
	snd_len 3
	snd_off
	snd_note C_4, 9
	snd_len 3
	snd_off
	snd_note C_5, 5
	snd_len 1
	snd_off
	snd_note B_4, 4
	snd_len 2
	snd_off
	snd_note C_4, 9
	snd_len 3
	snd_off
	snd_note As_4, 9
	snd_len 3
	snd_off
	snd_note F_4, 4
	snd_len 2
	snd_off
	snd_note A_4, 5
	snd_len 1
	snd_off
	snd_note F_4, 4
	snd_len 2
	snd_off
	snd_note F_5, 5
	snd_len 1
	snd_off
	snd_note F_4, 4
	snd_len 8
	snd_off
	snd_note D_5, 9
	snd_len 3
	snd_off
	snd_note G_4, 9
	snd_len 3
	snd_off
	snd_note G_5, 4
	snd_len 2
	snd_off
	snd_note D_5, 5
	snd_len 1
	snd_off
	snd_note G_3, 9
	snd_len 3
	snd_off
	snd_note G_4, 9
	snd_len 3
	snd_off
	snd_note C_4, 4
	snd_len 2
	snd_off
	snd_note C_5, 5
	snd_len 1
	snd_off
	snd_note C_4, 4
	snd_len 2
	snd_off
	snd_note As_3, 18
	snd_note A_3, 12
	snd_loop 4
	snd_note D_4, 6
	snd_note A_5, 1
	snd_len 5
	snd_off
	snd_note D_4, 2
	snd_len 4
	snd_off
	snd_note D_4
	snd_len 2
	snd_off
	snd_note A_3, 6
	snd_note D_4, 1
	snd_len 5
	snd_off
	snd_note C_4, 6
	snd_note A_5, 1
	snd_len 5
	snd_off
	snd_note D_4, 6
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note D_5, 2
	snd_len 4
	snd_off
	snd_note D_5, 2
	snd_len 4
	snd_off
	snd_note A_3, 6
	snd_note A_5, 2
	snd_len 4
	snd_off
	snd_note F_3, 6
	snd_note A_5, 1
	snd_len 5
	snd_off
	snd_note G_3, 6
	snd_note A_5, 4
	snd_len 2
	snd_off
	snd_note C_6, 1
	snd_len 5
	snd_off
	snd_note A_5, 1
	snd_len 5
	snd_off
	snd_note A_3, 6
	snd_note C_6, 2
	snd_len 4
	snd_off
	snd_note F_3, 6
	snd_note A_5, 2
	snd_len 4
	snd_off
	snd_note D_3, 6
	snd_note D_6, 3
	snd_off
	snd_note D_3, 1
	snd_len 5
	snd_off
	snd_note D_3, 1
	snd_len 5
	snd_off
	snd_note A_3, 6
	snd_note D_5, 1
	snd_len 5
	snd_off
	snd_note C_4, 6
	snd_note A_3, 1
	snd_len 5
	snd_off
	snd_endloop
	snd_loop 3
	snd_note G_3, 6
	snd_note G_5, 1
	snd_len 5
	snd_off
	snd_note G_3, 2
	snd_len 4
	snd_off
	snd_note G_3
	snd_len 2
	snd_off
	snd_note D_3, 6
	snd_note G_3, 1
	snd_len 5
	snd_off
	snd_note F_3, 6
	snd_note G_5, 1
	snd_len 5
	snd_off
	snd_note G_3, 6
	snd_note G_4, 2
	snd_len 4
	snd_off
	snd_note C_5, 2
	snd_len 4
	snd_off
	snd_note C_5, 2
	snd_len 4
	snd_off
	snd_note G_3, 6
	snd_note G_5, 2
	snd_len 4
	snd_off
	snd_note D_3, 6
	snd_note G_5, 1
	snd_len 5
	snd_off
	snd_note A_3, 6
	snd_note A_5, 4
	snd_len 2
	snd_off
	snd_note C_6, 1
	snd_len 5
	snd_off
	snd_note A_5, 1
	snd_len 5
	snd_off
	snd_note C_4, 6
	snd_note C_6, 2
	snd_len 4
	snd_off
	snd_note A_3, 6
	snd_note A_5, 2
	snd_len 4
	snd_off
	snd_note D_3, 6
	snd_note D_6, 3
	snd_off
	snd_note D_3, 1
	snd_len 5
	snd_off
	snd_note D_3, 1
	snd_len 5
	snd_off
	snd_note A_3, 6
	snd_note D_5, 1
	snd_len 5
	snd_off
	snd_note C_4, 6
	snd_note A_3, 1
	snd_len 5
	snd_off
	snd_endloop
	snd_note G_3, 6
	snd_note G_5, 1
	snd_len 5
	snd_off
	snd_note G_3, 2
	snd_len 4
	snd_off
	snd_note G_3
	snd_len 2
	snd_off
	snd_note D_3, 6
	snd_note G_3, 1
	snd_len 5
	snd_off
	snd_note F_3, 6
	snd_note G_5, 1
	snd_len 5
	snd_off
	snd_note G_3, 6
	snd_note G_4, 2
	snd_len 4
	snd_off
	snd_note C_5, 2
	snd_len 4
	snd_off
	snd_note C_5, 2
	snd_len 4
	snd_off
	snd_note G_3, 6
	snd_note G_5, 2
	snd_len 4
	snd_off
	snd_note D_3, 6
	snd_note G_5, 1
	snd_len 5
	snd_off
	snd_note A_3, 6
	snd_note A_5, 4
	snd_len 2
	snd_off
	snd_note C_6, 1
	snd_len 5
	snd_off
	snd_note A_5, 1
	snd_len 5
	snd_off
	snd_note C_4, 6
	snd_note E_5, 2
	snd_len 4
	snd_off
	snd_note C_5, 6
	snd_note A_3
	snd_note C_4
	snd_note A_3
	snd_note C_3
	snd_note C_4
	snd_note A_3
	snd_note C_5, 1
	snd_len 5
	snd_off
	snd_note C_4, 6
	snd_note A_3, 1
	snd_len 5
	snd_off
Trk3E_5F58:
	snd_note G_3, 6
	snd_note D_5, 1
	snd_len 5
	snd_off
	snd_note G_3, 2
	snd_len 4
	snd_off
	snd_note F_3, 6
	snd_note G_3
	snd_note G_4, 1
	snd_len 5
	snd_off
	snd_note G_5, 3
	snd_off
	snd_note D_5, 1
	snd_len 5
	snd_off
	snd_note G_4, 12
	snd_note G_5, 2
	snd_len 4
	snd_off
	snd_note F_4, 6
	snd_note G_4
	snd_note G_5, 2
	snd_len 4
	snd_off
	snd_note G_3, 6
	snd_note G_5, 1
	snd_len 5
	snd_off
	snd_note A_3, 6
	snd_note D_5, 4
	snd_len 2
	snd_off
	snd_note F_5, 1
	snd_len 5
	snd_off
	snd_note D_5, 1
	snd_len 5
	snd_off
	snd_note C_4, 6
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note A_3, 6
	snd_note D_5, 2
	snd_len 4
	snd_off
	snd_note D_3, 6
	snd_note A_5, 3
	snd_off
	snd_note D_3, 1
	snd_len 5
	snd_off
	snd_note D_3, 1
	snd_len 5
	snd_off
	snd_note A_3, 6
	snd_note D_5, 1
	snd_len 5
	snd_off
	snd_note C_4, 6
	snd_note A_3, 1
	snd_len 5
	snd_off
	snd_jump Trk3E_5F58
Mus3E_0_Ch4:
	snd_loop 3
	snd_len 12
	snd_drum 6
	snd_len 6
	snd_drum 9
	snd_drum 9
	snd_len 12
	snd_drum 9
	snd_drum 9
	snd_drum 6
	snd_len 6
	snd_drum 9
	snd_drum 9
	snd_len 12
	snd_drum 9
	snd_drum 9
	snd_endloop
	snd_len 24
	snd_drum 2
	snd_drum 2
	snd_len 12
	snd_drum 6
	snd_drum 4
	snd_len 24
	snd_drum 4
	snd_loop 7
	snd_len 12
	snd_drum 6
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 4
	snd_drum 9
	snd_drum 9
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 1
	snd_drum 3
	snd_endloop
	snd_loop 4
	snd_len 12
	snd_drum 6
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 4
	snd_drum 9
	snd_drum 9
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 4
	snd_len 6
	snd_drum 4
	snd_drum 4
	snd_endloop
	snd_len 12
	snd_drum 6
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 4
	snd_drum 9
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 2
	snd_len 6
	snd_drum 4
	snd_drum 0
	snd_len 12
	snd_drum 2
	snd_loop 4
	snd_len 6
	snd_drum 5
	snd_drum 0
	snd_len 12
	snd_drum 2
	snd_len 6
	snd_drum 4
	snd_drum 0
	snd_len 12
	snd_drum 2
	snd_len 6
	snd_drum 5
	snd_drum 0
	snd_len 12
	snd_drum 2
	snd_len 6
	snd_drum 4
	snd_drum 0
	snd_len 12
	snd_drum 2
	snd_endloop
	snd_loop 3
	snd_len 6
	snd_drum 5
	snd_off
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 3
	snd_drum 5
	snd_drum 3
	snd_drum 1
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_len 12
	snd_drum 2
	snd_endloop
	snd_len 12
	snd_drum 6
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 6
	snd_drum 4
	snd_drum 4
	snd_drum 9
	snd_loop 3
	snd_len 6
	snd_drum 5
	snd_off
	snd_len 12
	snd_drum 1
	snd_len 6
	snd_drum 4
	snd_off
	snd_len 12
	snd_drum 1
	snd_len 6
	snd_drum 5
	snd_off
	snd_drum 0
	snd_off
	snd_drum 4
	snd_drum 0
	snd_len 12
	snd_drum 2
	snd_endloop
	snd_len 6
	snd_drum 5
	snd_drum 0
	snd_len 12
	snd_drum 2
	snd_len 6
	snd_drum 4
	snd_drum 0
	snd_len 12
	snd_drum 2
	snd_len 8
	snd_drum 5
	snd_len 4
	snd_drum 7
	snd_len 8
	snd_drum 7
	snd_len 4
	snd_drum 8
	snd_len 8
	snd_drum 8
	snd_len 4
	snd_drum 9
	snd_len 8
	snd_drum 9
	snd_len 4
	snd_drum 11
	snd_len 12
	snd_drum 10
	snd_drum 2
	snd_len 6
	snd_drum 4
	snd_drum 0
	snd_len 12
	snd_drum 2
	snd_loop 5
	snd_len 6
	snd_drum 5
	snd_drum 0
	snd_len 12
	snd_drum 2
	snd_len 6
	snd_drum 4
	snd_drum 0
	snd_len 12
	snd_drum 2
	snd_endloop
	snd_len 6
	snd_drum 5
	snd_drum 0
	snd_len 12
	snd_drum 4
	snd_len 6
	snd_drum 4
	snd_drum 0
	snd_drum 2
	snd_drum 5
	snd_drum 4
	snd_drum 4
	snd_drum 9
	snd_drum 5
	snd_drum 4
	snd_drum 7
	snd_drum 8
	snd_drum 9
	snd_loop 14
	snd_len 12
	snd_drum 6
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 4
	snd_drum 9
	snd_drum 9
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 1
	snd_drum 3
	snd_endloop
	snd_len 12
	snd_drum 6
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_drum 6
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 1
	snd_drum 3
	snd_len 12
	snd_drum 6
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 6
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 6
	snd_drum 2
Trk3E_60D5:
	snd_len 12
	snd_drum 5
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 4
	snd_drum 9
	snd_drum 9
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 1
	snd_drum 3
	snd_jump Trk3E_60D5
Mus3E_1:
	db $0F	; channel mask
	dw Mus3E_1_Ch1, Mus3E_1_Ch2, Mus3E_1_Ch3, Mus3E_1_Ch4
Mus3E_1_Ch1:
	snd_env $A0
	snd_duty $80
	snd_note A_4, 6
	snd_off
	snd_note G_4
	snd_off
	snd_note E_4, 24
	snd_off
	snd_note Ds_4, 6
	snd_note E_4
	snd_note F_4
	snd_note E_4
	snd_note Ds_4
	snd_note E_4
	snd_note F_4
	snd_note Fs_4
	snd_note G_4
	snd_note Fs_4
	snd_note G_4
	snd_note B_4
	snd_note C_5
	snd_note G_4, 4
	snd_len 2
	snd_off
	snd_note D_5, 6
	snd_note G_4, 4
	snd_len 2
	snd_off
	snd_note E_5, 6
	snd_note G_4, 4
	snd_len 2
	snd_off
	snd_note F_5, 6
	snd_note G_4, 4
	snd_len 2
	snd_off
	snd_note E_5, 6
	snd_note C_5, 4
	snd_len 1
	snd_off
	snd_note C_5
	snd_note G_4, 6
	snd_note C_5, 4
	snd_len 1
	snd_off
	snd_note C_5
	snd_note E_5, 6
	snd_note C_5, 4
	snd_len 1
	snd_off
	snd_note E_5
	snd_note G_4, 6
	snd_note C_5
	snd_env $87
	snd_note E_5, 48
	snd_end
Mus3E_1_Ch2:
	snd_env $A0
	snd_duty $80
	snd_octenv SndOctEnv_4AFF
	snd_note C_5, 6
	snd_off
	snd_note A_4
	snd_off
	snd_note G_4, 48
	snd_note Fs_4, 6
	snd_note G_4
	snd_note A_4
	snd_note G_4
	snd_note Fs_4
	snd_note G_4
	snd_note A_4
	snd_note D_5
	snd_note C_5
	snd_note D_5
	snd_note E_5
	snd_note G_5
	snd_note A_5
	snd_off
	snd_note E_5
	snd_off
	snd_note G_5, 72
	snd_env $97
	snd_note G_5, 48
	snd_end
Mus3E_1_Ch3:
	snd_duty $00
	snd_env2 $20
	snd_wave SndWave07
	snd_note C_3, 6
	snd_note C_4
	snd_note C_3
	snd_note C_4
	snd_note C_3
	snd_note C_4
	snd_note C_3
	snd_note C_4
	snd_note C_3
	snd_note G_3
	snd_note C_4
	snd_note E_4
	snd_note G_3, 5
	snd_len 1
	snd_off
	snd_note G_3, 5
	snd_len 1
	snd_off
	snd_note G_3, 5
	snd_len 1
	snd_off
	snd_note G_3, 6
	snd_note As_4
	snd_note A_4
	snd_note G_4
	snd_note E_4
	snd_note A_4
	snd_note G_4
	snd_note E_4
	snd_note D_4
	snd_note C_4
	snd_note C_3
	snd_note G_3
	snd_note C_4
	snd_note G_3
	snd_note G_4
	snd_note G_3
	snd_note G_4
	snd_note C_4
	snd_off
	snd_note G_3
	snd_note B_3
	snd_note C_4
	snd_off
	snd_note G_3, 5
	snd_len 1
	snd_off
	snd_note G_3, 6
	snd_note C_3, 48
	snd_end
Mus3E_1_Ch4:
	snd_tempo 144
	snd_loop 4
	snd_len 12
	snd_drum 5
	snd_len 6
	snd_drum 3
	snd_drum 3
	snd_endloop
	snd_len 72
	snd_drum 11
	snd_len 12
	snd_drum 7
	snd_len 6
	snd_drum 8
	snd_drum 8
	snd_tempo 126
	snd_len 12
	snd_drum 3
	snd_len 6
	snd_drum 3
	snd_drum 2
	snd_tempo 107
	snd_drum 3
	snd_drum 8
	snd_drum 8
	snd_drum 9
	snd_tempo 92
	snd_len 48
	snd_drum 11
	snd_end
