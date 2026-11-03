; Daiku no Gensan (J) - sound bank $3C ($4000-$7D88)
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


SECTION "Sound bank $3C", ROMX[$4000], BANK[$3C]

INCLUDE "Daiku_sound_common.inc"


SndMusicTable:
	dw Mus3C_0, Mus3C_1, Mus3C_2, Mus3C_3
	dw Mus3C_4, Mus3C_5, Mus3C_6, Mus3C_7
	dw Mus3C_8, Mus3C_9, Mus3C_10, Mus3C_11
Mus3C_0:
	db $0F	; channel mask
	dw Mus3C_0_Ch1, Mus3C_0_Ch2, Mus3C_0_Ch3, Mus3C_0_Ch4
Mus3C_0_Ch2:
	snd_tempo 150
	snd_duty $80
	snd_env $B1
	snd_transpose $0C
	snd_note G_4, 8
	snd_note G_4
	snd_note C_5
	snd_note E_5
	snd_note G_5, 16
	snd_note A_5, 8
	snd_note E_5
	snd_env $B4
	snd_note G_5, 96
	snd_len 6
	snd_off
	snd_transpose $18
	snd_env $23
	snd_note G_4, 6
	snd_note G_4
	snd_note C_5
	snd_note E_5
	snd_env $13
	snd_note G_4
	snd_note G_4
	snd_note C_5
	snd_note E_5
	snd_env $13
	snd_note G_4
	snd_note G_4
	snd_note C_5
	snd_note E_5
	snd_env $13
	snd_note G_4
	snd_note G_4
	snd_note C_5
	snd_note E_5
	snd_end
Mus3C_0_Ch1:
	snd_duty $80
	snd_env $81
	snd_transpose $0C
	snd_len 3
	snd_off
	snd_note G_4, 8
	snd_note G_4
	snd_note C_5
	snd_note E_5
	snd_note G_5, 16
	snd_note A_5, 8
	snd_note E_5, 5
	snd_duty $80
	snd_env $80
	snd_transpose $18
	snd_env $62
	snd_note G_4, 6
	snd_note G_4
	snd_note C_5
	snd_note E_5
	snd_env $53
	snd_note G_4
	snd_note G_4
	snd_note C_5
	snd_note E_5
	snd_env $43
	snd_note G_4
	snd_note G_4
	snd_note C_5
	snd_note E_5
	snd_env $33
	snd_note G_4
	snd_note G_4
	snd_note C_5
	snd_note E_5
	snd_env $23
	snd_note G_4
	snd_note G_4
	snd_note C_5
	snd_note E_5
	snd_env $13
	snd_note G_4
	snd_note G_4
	snd_note C_5
	snd_note E_5
	snd_env $13
	snd_note G_4
	snd_note G_4
	snd_note C_5
	snd_note E_5
	snd_env $13
	snd_note G_4
	snd_note G_4
	snd_note C_5
	snd_note E_5
	snd_end
Mus3C_0_Ch3:
	snd_duty $00
	snd_env2 $20
	snd_wave SndWave0E
	snd_transpose $0C
	snd_note C_4, 8
	snd_note B_3
	snd_note A_3
	snd_note G_3
	snd_note F_3
	snd_note E_3
	snd_note D_3
	snd_note C_3
	snd_note C_2, 96
	snd_end
Mus3C_0_Ch4:
	snd_end
Mus3C_1:
	db $0F	; channel mask
	dw Mus3C_1_Ch1, Mus3C_1_Ch2, Mus3C_1_Ch3, Mus3C_1_Ch4
Mus3C_1_Ch1:
	snd_tempo 70
	snd_duty $00
	snd_env $80
	snd_env $40
Trk3C_53D8:
	snd_call Trk3C_54A4
	snd_call Trk3C_54A4
	snd_call Trk3C_544E
	snd_call Trk3C_544E
	snd_call Trk3C_544E
	snd_call Trk3C_544E
	snd_call Trk3C_5479
	snd_call Trk3C_5479
	snd_call Trk3C_5479
	snd_call Trk3C_5479
	snd_loop 4
	snd_len 6
	snd_off
	snd_note Cs_6, 2
	snd_len 1
	snd_off
	snd_note E_6, 2
	snd_len 1
	snd_off
	snd_note Gs_6, 2
	snd_len 1
	snd_off
	snd_note As_6, 2
	snd_len 1
	snd_off
	snd_note B_6, 2
	snd_len 1
	snd_off
	snd_note Fs_6, 2
	snd_len 1
	snd_off
	snd_note D_7, 2
	snd_len 4
	snd_off
	snd_note D_6, 2
	snd_len 4
	snd_off
	snd_note C_7, 2
	snd_len 4
	snd_off
	snd_note C_6, 2
	snd_len 10
	snd_off
	snd_note D_6, 2
	snd_len 1
	snd_off
	snd_note F_6, 2
	snd_len 1
	snd_off
	snd_note A_6, 2
	snd_len 1
	snd_off
	snd_note B_6, 2
	snd_len 1
	snd_off
	snd_note C_7, 2
	snd_len 1
	snd_off
	snd_note G_6, 2
	snd_len 1
	snd_off
	snd_note D_7, 2
	snd_len 4
	snd_off
	snd_note D_6, 2
	snd_len 4
	snd_off
	snd_note C_7, 2
	snd_len 4
	snd_off
	snd_note C_6, 2
	snd_len 4
	snd_off
	snd_endloop
	snd_jump Trk3C_53D8
Trk3C_544E:
	snd_len 6
	snd_off
	snd_note D_6, 2
	snd_len 1
	snd_off
	snd_note F_6, 2
	snd_len 1
	snd_off
	snd_note A_6, 2
	snd_len 1
	snd_off
	snd_note B_6, 2
	snd_len 1
	snd_off
	snd_note C_7, 2
	snd_len 1
	snd_off
	snd_note G_6, 2
	snd_len 1
	snd_off
	snd_note D_7, 2
	snd_len 4
	snd_off
	snd_note C_7, 2
	snd_len 4
	snd_off
	snd_note D_7, 2
	snd_len 4
	snd_off
	snd_note C_7, 2
	snd_len 52
	snd_off
	snd_ret
Trk3C_5479:
	snd_len 6
	snd_off
	snd_note E_6, 2
	snd_len 1
	snd_off
	snd_note Ds_6, 2
	snd_len 1
	snd_off
	snd_note E_6, 2
	snd_len 1
	snd_off
	snd_note B_6, 2
	snd_len 1
	snd_off
	snd_note Cs_7, 2
	snd_len 1
	snd_off
	snd_note A_6, 2
	snd_len 1
	snd_off
	snd_note E_6, 2
	snd_len 4
	snd_off
	snd_note D_6, 2
	snd_len 4
	snd_off
	snd_note E_7, 2
	snd_len 4
	snd_off
	snd_note D_7, 2
	snd_len 52
	snd_off
	snd_ret
Trk3C_54A4:
	snd_note D_2, 3
	snd_off
	snd_note A_2
	snd_off
	snd_note C_3
	snd_off
	snd_note D_2
	snd_off
	snd_note B_2
	snd_off
	snd_note G_2
	snd_off
	snd_note D_2
	snd_off
	snd_note As_2
	snd_off
	snd_note A_2
	snd_off
	snd_note Fs_2
	snd_off
	snd_note G_2
	snd_off
	snd_note Cs_3
	snd_off
	snd_note C_3
	snd_off
	snd_note F_2
	snd_off
	snd_note E_2
	snd_off
	snd_note B_2
	snd_off
	snd_ret
Mus3C_1_Ch2:
	snd_duty $40
	snd_env $80
Trk3C_54CA:
	snd_transpose $00
	snd_loop 6
	snd_call Trk3C_54A4
	snd_endloop
	snd_transpose $02
	snd_loop 4
	snd_call Trk3C_54A4
	snd_endloop
	snd_transpose $F4
	snd_loop 2
	snd_note F_3, 3
	snd_off
	snd_note F_3
	snd_off
	snd_note A_3
	snd_off
	snd_note E_3
	snd_off
	snd_note F_3
	snd_off
	snd_note G_3
	snd_off
	snd_note D_3
	snd_off
	snd_note F_3
	snd_off
	snd_note F_3
	snd_off
	snd_note Fs_3
	snd_off
	snd_note F_3
	snd_off
	snd_note Cs_4
	snd_off
	snd_note F_3
	snd_off
	snd_note Ds_3
	snd_off
	snd_note F_3
	snd_off
	snd_note B_3
	snd_off
	snd_note F_3
	snd_off
	snd_note F_3
	snd_off
	snd_note D_4
	snd_off
	snd_note E_3
	snd_off
	snd_note F_3
	snd_off
	snd_note Gs_3
	snd_off
	snd_note D_3
	snd_off
	snd_note F_3
	snd_off
	snd_note F_3
	snd_off
	snd_note Fs_3
	snd_off
	snd_note F_3
	snd_off
	snd_note E_4
	snd_off
	snd_note F_3
	snd_off
	snd_note Ds_3
	snd_off
	snd_note F_3
	snd_off
	snd_note Cs_4
	snd_off
	snd_endloop
	snd_jump Trk3C_54CA
Mus3C_1_Ch3:
	snd_duty $00
	snd_env2 $40
	snd_pitchenv SndPitchEnv_4A55
Trk3C_552A:
	snd_wave SndWave02
	snd_call Trk3C_54A4
	snd_call Trk3C_54A4
	snd_wave SndWave07
	snd_note A_5, 3
	snd_len 15
	snd_off
	snd_note A_5, 3
	snd_off
	snd_note C_6
	snd_len 15
	snd_off
	snd_note C_6, 3
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
	snd_len 9
	snd_off
	snd_note Ds_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 15
	snd_off
	snd_note D_5, 3
	snd_off
	snd_note F_5
	snd_len 15
	snd_off
	snd_note F_5, 3
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
	snd_note Gs_4, 18
	snd_note A_5, 3
	snd_len 15
	snd_off
	snd_note A_5, 3
	snd_off
	snd_note C_6
	snd_len 15
	snd_off
	snd_note C_6, 3
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
	snd_len 9
	snd_off
	snd_note Ds_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 15
	snd_off
	snd_note D_5, 3
	snd_off
	snd_note F_5
	snd_len 15
	snd_off
	snd_note F_5, 3
	snd_off
	snd_note E_5
	snd_off
	snd_note Gs_5
	snd_off
	snd_note G_5
	snd_off
	snd_note B_5
	snd_off
	snd_note As_5
	snd_off
	snd_note Ds_6, 18
	snd_note B_5, 3
	snd_len 15
	snd_off
	snd_note B_5, 3
	snd_off
	snd_note D_6
	snd_len 15
	snd_off
	snd_note D_6, 3
	snd_off
	snd_note E_5
	snd_off
	snd_note G_5
	snd_off
	snd_note Fs_5
	snd_off
	snd_note As_5
	snd_off
	snd_note A_5
	snd_len 9
	snd_off
	snd_note F_5, 3
	snd_len 9
	snd_off
	snd_note E_5, 3
	snd_len 15
	snd_off
	snd_note E_5, 3
	snd_off
	snd_note G_5
	snd_len 15
	snd_off
	snd_note G_5, 3
	snd_off
	snd_note Fs_5
	snd_off
	snd_note D_5
	snd_off
	snd_note Cs_5
	snd_off
	snd_note F_5
	snd_off
	snd_note E_5
	snd_off
	snd_note As_4, 18
	snd_note B_5, 3
	snd_len 15
	snd_off
	snd_note B_5, 3
	snd_off
	snd_note D_6
	snd_len 15
	snd_off
	snd_note D_6, 3
	snd_off
	snd_note E_5
	snd_off
	snd_note G_5
	snd_off
	snd_note Fs_5
	snd_off
	snd_note As_5
	snd_off
	snd_note A_5
	snd_len 9
	snd_off
	snd_note F_5, 3
	snd_len 9
	snd_off
	snd_note E_5, 3
	snd_len 15
	snd_off
	snd_note E_5, 3
	snd_off
	snd_note G_5
	snd_len 15
	snd_off
	snd_note G_5, 3
	snd_off
	snd_note Fs_5
	snd_off
	snd_note As_5
	snd_off
	snd_note A_5
	snd_off
	snd_note F_5
	snd_off
	snd_note Cs_5
	snd_off
	snd_note Fs_4, 18
	snd_wave SndWave0E
	snd_note D_4, 47
	snd_len 1
	snd_off
	snd_note Ds_4, 47
	snd_len 1
	snd_off
	snd_note D_4, 47
	snd_len 1
	snd_off
	snd_note Ds_4, 47
	snd_len 1
	snd_off
	snd_note E_4, 47
	snd_len 1
	snd_off
	snd_note G_4, 47
	snd_len 1
	snd_off
	snd_note D_4, 47
	snd_len 1
	snd_off
	snd_note Ds_4, 47
	snd_len 1
	snd_off
	snd_jump Trk3C_552A
Mus3C_1_Ch4:
	snd_loop 13
	snd_len 24
	snd_drum 5
	snd_drum 4
	snd_len 9
	snd_drum 6
	snd_drum 6
	snd_len 6
	snd_drum 6
	snd_len 24
	snd_drum 3
	snd_endloop
	snd_len 24
	snd_drum 5
	snd_drum 4
	snd_len 9
	snd_drum 6
	snd_drum 6
	snd_len 6
	snd_drum 6
	snd_len 12
	snd_drum 6
	snd_len 6
	snd_drum 4
	snd_len 3
	snd_drum 4
	snd_drum 4
	snd_jump Mus3C_1_Ch4
Mus3C_2:
	db $0F	; channel mask
	dw Mus3C_2_Ch1, Mus3C_2_Ch2, Mus3C_2_Ch3, Mus3C_2_Ch4
Mus3C_2_Ch1:
	snd_tempo 56
	snd_duty $40
	snd_env $70
	snd_pitchenv SndPitchEnv_49A8
Trk3C_5661:
	snd_call Trk3C_5A3D
	snd_call Trk3C_5A3D
	snd_call Trk3C_571F
	snd_call Trk3C_571F
	snd_call Trk3C_569A
	snd_len 24
	snd_off
	snd_call Trk3C_569A
	snd_note E_4, 6
	snd_note B_4, 1
	snd_note E_5
	snd_off
	snd_note D_4, 3
	snd_note E_4, 6
	snd_note B_4, 1
	snd_note E_5
	snd_off
	snd_note D_4, 3
	snd_call Trk3C_571F
	snd_call Trk3C_571F
	snd_call Trk3C_56B8
	snd_call Trk3C_571F
	snd_call Trk3C_571F
	snd_call Trk3C_56E5
	snd_jump Trk3C_5661
Trk3C_569A:
	snd_env $81
	snd_note E_4, 6
	snd_note E_4, 3
	snd_note E_4
	snd_note B_3, 6
	snd_note D_4
	snd_note E_4, 3
	snd_note D_7
	snd_note B_6
	snd_note D_7
	snd_note B_6
	snd_note D_7
	snd_note B_6
	snd_note G_6
	snd_note A_6
	snd_note E_6
	snd_note G_6
	snd_note A_6
	snd_note B_6
	snd_note A_6
	snd_note G_6
	snd_note D_6
	snd_env $70
	snd_ret
Trk3C_56B8:
	snd_env $82
	snd_note C_6, 6
	snd_note A_5
	snd_note C_6
	snd_note A_5
	snd_len 12
	snd_off
	snd_note Fs_5, 3
	snd_note Fs_5, 6
	snd_note A_5, 3
	snd_note C_6, 6
	snd_note A_5
	snd_note C_6
	snd_note A_5
	snd_len 24
	snd_off
	snd_note C_6, 6
	snd_note A_5
	snd_note C_6
	snd_note A_5
	snd_len 12
	snd_off
	snd_note Ds_5, 3
	snd_note Fs_5, 6
	snd_note A_5, 3
	snd_note C_6, 6
	snd_note A_5
	snd_note Ds_6
	snd_note C_6
	snd_len 24
	snd_off
	snd_env $70
	snd_ret
Trk3C_56E5:
	snd_env $0F
	snd_note D_6, 24
	snd_env $97
	snd_note D_6, 24
	snd_env $0E
	snd_note G_6, 24
	snd_note F_6
	snd_env $81
	snd_duty $00
	snd_loop 2
	snd_note A_5, 3
	snd_note C_6
	snd_note A_5
	snd_note G_5
	snd_endloop
	snd_note A_5
	snd_note G_5
	snd_note Ds_5
	snd_note G_5
	snd_note Ds_5
	snd_note G_5
	snd_note Ds_5
	snd_note C_5
	snd_note D_5
	snd_note A_4
	snd_note C_5
	snd_note D_5
	snd_note Ds_5
	snd_note D_5
	snd_note C_5
	snd_note G_4
	snd_note A_3, 6
	snd_note F_4, 1
	snd_note A_4
	snd_off
	snd_note G_3, 3
	snd_note A_3
	snd_note G_3
	snd_note Fs_3
	snd_note F_3
	snd_env $70
	snd_duty $40
	snd_ret
Trk3C_571F:
	snd_note E_4, 2
	snd_len 4
	snd_off
	snd_note E_4, 2
	snd_len 1
	snd_off
	snd_note E_4, 2
	snd_len 1
	snd_off
	snd_note B_3, 2
	snd_len 4
	snd_off
	snd_note D_4, 2
	snd_len 4
	snd_off
	snd_note E_4, 2
	snd_len 70
	snd_off
	snd_ret
Mus3C_2_Ch2:
	snd_duty $80
	snd_env $80
	snd_pitchenv SndPitchEnv_499B
Trk3C_573F:
	snd_len 96
	snd_off
	snd_len 96
	snd_off
	snd_call Trk3C_571F
	snd_call Trk3C_571F
	snd_call Trk3C_571F
	snd_call Trk3C_575E
	snd_call Trk3C_5787
	snd_call Trk3C_5787
	snd_call Trk3C_57B4
	snd_call Trk3C_582E
	snd_jump Trk3C_573F
Trk3C_575E:
	snd_note E_6, 2
	snd_len 4
	snd_off
	snd_note E_6, 2
	snd_len 1
	snd_off
	snd_note E_6, 2
	snd_len 1
	snd_off
	snd_note B_5, 2
	snd_len 4
	snd_off
	snd_note D_6, 2
	snd_len 4
	snd_off
	snd_note E_6, 2
	snd_len 46
	snd_off
	snd_note E_4, 6
	snd_note B_4, 1
	snd_note E_5
	snd_off
	snd_note D_4, 3
	snd_note E_4, 6
	snd_note B_4, 1
	snd_note E_5
	snd_off
	snd_note D_4, 3
	snd_ret
Trk3C_5787:
	snd_note G_6, 2
	snd_len 4
	snd_off
	snd_note E_6, 2
	snd_len 4
	snd_off
	snd_note G_6, 2
	snd_len 4
	snd_off
	snd_note E_6, 2
	snd_len 16
	snd_off
	snd_note D_6, 2
	snd_len 1
	snd_off
	snd_note D_6, 2
	snd_len 4
	snd_off
	snd_note E_6, 2
	snd_len 1
	snd_off
	snd_note G_6, 2
	snd_len 4
	snd_off
	snd_note E_6, 2
	snd_len 4
	snd_off
	snd_note G_6, 2
	snd_len 4
	snd_off
	snd_note E_6, 2
	snd_len 28
	snd_off
	snd_ret
Trk3C_57B4:
	snd_note A_6, 2
	snd_len 4
	snd_off
	snd_note Fs_6, 2
	snd_len 4
	snd_off
	snd_note A_6, 2
	snd_len 4
	snd_off
	snd_note Fs_6, 2
	snd_len 16
	snd_off
	snd_note Ds_6, 2
	snd_len 1
	snd_off
	snd_note Ds_6, 2
	snd_len 4
	snd_off
	snd_note Fs_6, 2
	snd_len 1
	snd_off
	snd_note A_6, 2
	snd_len 4
	snd_off
	snd_note Fs_6, 2
	snd_len 4
	snd_off
	snd_note A_6, 2
	snd_len 4
	snd_off
	snd_note Fs_6, 2
	snd_len 4
	snd_off
	snd_note Fs_4, 6
	snd_note A_4, 1
	snd_note C_5
	snd_off
	snd_note Ds_4, 3
	snd_note A_4, 6
	snd_note C_5, 1
	snd_note Ds_5
	snd_off
	snd_note Fs_4, 3
	snd_note A_6, 2
	snd_len 4
	snd_off
	snd_note Fs_6, 2
	snd_len 4
	snd_off
	snd_note A_6, 2
	snd_len 4
	snd_off
	snd_note Fs_6, 2
	snd_len 16
	snd_off
	snd_note C_6, 2
	snd_len 1
	snd_off
	snd_note Ds_6, 2
	snd_len 4
	snd_off
	snd_note Fs_6, 2
	snd_len 1
	snd_off
	snd_note A_6, 2
	snd_len 4
	snd_off
	snd_note Fs_6, 2
	snd_len 4
	snd_off
	snd_note C_7, 2
	snd_len 4
	snd_off
	snd_note A_6, 2
	snd_len 4
	snd_off
	snd_note A_4, 6
	snd_note C_5, 1
	snd_note Ds_5
	snd_off
	snd_note Fs_4, 3
	snd_note C_5, 6
	snd_note Ds_6, 1
	snd_note E_6
	snd_note Fs_6
	snd_note G_6
	snd_note A_6, 2
	snd_ret
Trk3C_582E:
	snd_env $0F
	snd_note B_6, 24
	snd_env $87
	snd_note B_6, 24
	snd_env $0D
	snd_note E_7, 24
	snd_env $70
	snd_note D_7
	snd_note E_7, 48
	snd_note A_6, 36
	snd_env $66
	snd_note A_6, 12
	snd_env $0F
	snd_note As_6, 36
	snd_env $87
	snd_note As_6, 60
	snd_env $60
	snd_note C_7, 72
	snd_env $65
	snd_note C_7, 24
	snd_ret
Mus3C_2_Ch3:
	snd_duty $00
	snd_env2 $20
	snd_wave SndWave08
	snd_pitchenv SndPitchEnv_4A1B
Trk3C_5860:
	snd_loop 8
	snd_call Trk3C_5A3D
	snd_endloop
	snd_loop 2
	snd_note E_3, 2
	snd_len 4
	snd_off
	snd_note E_3, 2
	snd_len 4
	snd_off
	snd_note E_3, 2
	snd_len 4
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note E_3, 2
	snd_len 4
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note E_2, 3
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note A_4
	snd_len 2
	snd_off
	snd_note E_3
	snd_len 1
	snd_off
	snd_note Fs_4
	snd_len 2
	snd_off
	snd_note E_3, 3
	snd_len 1
	snd_off
	snd_len 2
	snd_off
	snd_note E_3
	snd_len 4
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note C_5
	snd_len 2
	snd_off
	snd_note E_3
	snd_len 1
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note E_3, 2
	snd_len 4
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note E_2
	snd_len 2
	snd_off
	snd_note E_3
	snd_len 1
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note Ds_4
	snd_len 2
	snd_off
	snd_endloop
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note E_4, 2
	snd_len 1
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note E_4, 2
	snd_len 1
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note B_4, 2
	snd_len 1
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note E_5
	snd_len 2
	snd_off
	snd_note E_3
	snd_len 1
	snd_off
	snd_note E_2, 3
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note B_4
	snd_len 2
	snd_off
	snd_note E_3
	snd_len 1
	snd_off
	snd_note G_4
	snd_len 2
	snd_off
	snd_note E_3, 3
	snd_len 1
	snd_off
	snd_len 2
	snd_off
	snd_note E_3
	snd_len 4
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note B_4
	snd_len 2
	snd_off
	snd_note E_3
	snd_len 1
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note E_3, 2
	snd_len 4
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note E_2
	snd_len 2
	snd_off
	snd_note E_3
	snd_len 1
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note D_4
	snd_len 2
	snd_off
	snd_note Fs_3
	snd_len 1
	snd_off
	snd_note Fs_4, 2
	snd_len 1
	snd_off
	snd_note Fs_3, 2
	snd_len 1
	snd_off
	snd_note Fs_4, 2
	snd_len 1
	snd_off
	snd_note Fs_3, 2
	snd_len 1
	snd_off
	snd_note C_5, 2
	snd_len 1
	snd_off
	snd_note Fs_3, 2
	snd_len 1
	snd_off
	snd_note Fs_3, 2
	snd_len 1
	snd_off
	snd_note Fs_3, 2
	snd_len 1
	snd_off
	snd_note E_5
	snd_len 2
	snd_off
	snd_note Fs_3
	snd_len 1
	snd_off
	snd_note Fs_2, 3
	snd_note Fs_3, 2
	snd_len 1
	snd_off
	snd_note C_5
	snd_len 2
	snd_off
	snd_note Fs_3
	snd_len 1
	snd_off
	snd_note A_4
	snd_len 2
	snd_off
	snd_note Fs_3, 3
	snd_len 1
	snd_off
	snd_len 2
	snd_off
	snd_note Fs_3
	snd_len 4
	snd_off
	snd_note Fs_3, 2
	snd_len 1
	snd_off
	snd_note C_5
	snd_len 2
	snd_off
	snd_note Fs_3
	snd_len 1
	snd_off
	snd_note Fs_3, 2
	snd_len 1
	snd_off
	snd_note Fs_3, 2
	snd_len 4
	snd_off
	snd_note Fs_3, 2
	snd_len 1
	snd_off
	snd_note Fs_2
	snd_len 2
	snd_off
	snd_note Fs_3
	snd_len 1
	snd_off
	snd_note Fs_3, 2
	snd_len 1
	snd_off
	snd_note Fs_3, 2
	snd_len 1
	snd_off
	snd_note D_4
	snd_len 2
	snd_off
	snd_note G_3
	snd_len 4
	snd_off
	snd_note G_3, 2
	snd_len 4
	snd_off
	snd_note G_3, 2
	snd_len 4
	snd_off
	snd_note G_3, 2
	snd_len 1
	snd_off
	snd_note G_3, 2
	snd_len 1
	snd_off
	snd_note G_3, 2
	snd_len 4
	snd_off
	snd_note G_3, 2
	snd_len 1
	snd_off
	snd_note G_2, 3
	snd_note G_3, 2
	snd_len 1
	snd_off
	snd_note D_5
	snd_len 2
	snd_off
	snd_note G_3
	snd_len 1
	snd_off
	snd_note As_4
	snd_len 2
	snd_off
	snd_note G_3, 3
	snd_len 1
	snd_off
	snd_len 2
	snd_off
	snd_note G_3
	snd_len 4
	snd_off
	snd_note G_3, 2
	snd_len 1
	snd_off
	snd_note D_5
	snd_len 2
	snd_off
	snd_note G_3
	snd_len 1
	snd_off
	snd_note G_3, 2
	snd_len 1
	snd_off
	snd_note G_3, 2
	snd_len 4
	snd_off
	snd_note G_3, 2
	snd_len 1
	snd_off
	snd_note G_2, 3
	snd_note G_3, 2
	snd_len 1
	snd_off
	snd_note G_3, 2
	snd_len 1
	snd_off
	snd_note G_3, 2
	snd_len 1
	snd_off
	snd_note F_4
	snd_len 2
	snd_off
	snd_note A_2
	snd_len 4
	snd_off
	snd_note A_3, 2
	snd_len 4
	snd_off
	snd_note A_3, 2
	snd_len 4
	snd_off
	snd_note A_3, 2
	snd_len 1
	snd_off
	snd_note A_3, 2
	snd_len 1
	snd_off
	snd_note A_3, 2
	snd_len 4
	snd_off
	snd_note A_3, 2
	snd_len 4
	snd_off
	snd_note A_3, 2
	snd_len 1
	snd_off
	snd_note A_3, 2
	snd_len 1
	snd_off
	snd_note A_3, 2
	snd_len 1
	snd_off
	snd_note A_3, 2
	snd_len 1
	snd_off
	snd_note A_2, 3
	snd_off
	snd_note A_3, 2
	snd_len 4
	snd_off
	snd_note A_3, 2
	snd_len 4
	snd_off
	snd_note A_3, 2
	snd_len 1
	snd_off
	snd_note A_3, 2
	snd_len 1
	snd_off
	snd_note A_3, 2
	snd_len 4
	snd_off
	snd_note A_3, 2
	snd_len 4
	snd_off
	snd_note A_3, 3
	snd_note G_3
	snd_note Fs_3
	snd_note F_3
	snd_jump Trk3C_5860
Trk3C_5A3D:
	snd_note E_3, 2
	snd_len 4
	snd_off
	snd_note E_3, 2
	snd_len 4
	snd_off
	snd_note E_3, 2
	snd_len 4
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note E_3, 2
	snd_len 4
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note E_2, 3
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note B_4
	snd_len 2
	snd_off
	snd_note E_3
	snd_len 1
	snd_off
	snd_note G_4
	snd_len 2
	snd_off
	snd_note E_3, 3
	snd_len 1
	snd_off
	snd_len 2
	snd_off
	snd_note E_3
	snd_len 4
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note B_4
	snd_len 2
	snd_off
	snd_note E_3
	snd_len 1
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note E_3, 2
	snd_len 4
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note E_2, 3
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note E_3, 2
	snd_len 1
	snd_off
	snd_note D_4
	snd_len 2
	snd_off
	snd_ret
Mus3C_2_Ch4:
	snd_len 24
	snd_drum 5
	snd_drum 4
	snd_drum 6
	snd_len 12
	snd_drum 3
	snd_len 1
	snd_drum 6
	snd_len 11
	snd_drum 2
	snd_jump Mus3C_2_Ch4
Mus3C_3:
	db $0F	; channel mask
	dw Mus3C_3_Ch1, Mus3C_3_Ch2, Mus3C_3_Ch3, Mus3C_3_Ch4
Mus3C_3_Ch1:
	snd_tempo 75
	snd_pitchenv SndPitchEnv_4959
	snd_env $E0
	snd_duty $00
	snd_transpose $F4
Trk3C_5ABA:
	snd_call Trk3C_5B0B
	snd_call Trk3C_5B0B
	snd_call Trk3C_5B4C
	snd_call Trk3C_5B8D
	snd_call Trk3C_5B4C
	snd_call Trk3C_5B8D
	snd_call Trk3C_5BCE
	snd_call Trk3C_5C0F
	snd_call Trk3C_5B4C
	snd_call Trk3C_5B8D
	snd_call Trk3C_5C50
	snd_call Trk3C_5C91
	snd_call Trk3C_5CD2
	snd_call Trk3C_5CD2
	snd_loop 6
	snd_note E_3, 5
	snd_len 1
	snd_off
	snd_note E_3, 5
	snd_len 1
	snd_off
	snd_note F_3, 5
	snd_len 1
	snd_off
	snd_note Ds_3, 5
	snd_len 1
	snd_off
	snd_endloop
	snd_note E_3, 3
	snd_off
	snd_note G_3
	snd_off
	snd_note Fs_3
	snd_off
	snd_note A_3
	snd_off
	snd_note G_3
	snd_off
	snd_note C_4
	snd_off
	snd_note A_3
	snd_off
	snd_note Fs_3
	snd_off
	snd_jump Trk3C_5ABA
Trk3C_5B0B:
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note D_4, 5
	snd_len 1
	snd_off
	snd_note A_3, 5
	snd_len 1
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_note A_3, 5
	snd_len 1
	snd_off
	snd_note Gs_3, 5
	snd_len 1
	snd_off
	snd_note G_3, 5
	snd_len 1
	snd_off
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_note F_3, 5
	snd_len 1
	snd_off
	snd_note E_3, 5
	snd_len 1
	snd_off
	snd_note G_3, 5
	snd_len 1
	snd_off
	snd_note F_3, 5
	snd_len 1
	snd_off
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_ret
Trk3C_5B4C:
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note D_4, 5
	snd_len 1
	snd_off
	snd_note A_3, 5
	snd_len 1
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_note A_3, 5
	snd_len 1
	snd_off
	snd_note Gs_3, 5
	snd_len 1
	snd_off
	snd_note Gs_3, 5
	snd_len 1
	snd_off
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_note E_3, 5
	snd_len 1
	snd_off
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_note Gs_3, 5
	snd_len 1
	snd_off
	snd_note E_3, 5
	snd_len 1
	snd_off
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_ret
Trk3C_5B8D:
	snd_note Cs_4, 5
	snd_len 1
	snd_off
	snd_note Cs_4, 5
	snd_len 1
	snd_off
	snd_note E_4, 5
	snd_len 1
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note Cs_4, 5
	snd_len 1
	snd_off
	snd_note Cs_4, 5
	snd_len 1
	snd_off
	snd_note Gs_3, 5
	snd_len 1
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note As_3, 5
	snd_len 1
	snd_off
	snd_note A_3, 5
	snd_len 1
	snd_off
	snd_note Gs_3, 5
	snd_len 1
	snd_off
	snd_note G_3, 5
	snd_len 1
	snd_off
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_note G_3, 5
	snd_len 1
	snd_off
	snd_note F_3, 5
	snd_len 1
	snd_off
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_ret
Trk3C_5BCE:
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note Ds_4, 5
	snd_len 1
	snd_off
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note Cs_4, 5
	snd_len 1
	snd_off
	snd_note Cs_4, 5
	snd_len 1
	snd_off
	snd_note E_4, 5
	snd_len 1
	snd_off
	snd_note C_4, 5
	snd_len 1
	snd_off
	snd_note Cs_4, 5
	snd_len 1
	snd_off
	snd_note Ds_4, 5
	snd_len 1
	snd_off
	snd_note C_4, 5
	snd_len 1
	snd_off
	snd_note Cs_4, 5
	snd_len 1
	snd_off
	snd_ret
Trk3C_5C0F:
	snd_note E_3, 5
	snd_len 1
	snd_off
	snd_note E_3, 5
	snd_len 1
	snd_off
	snd_note Gs_3, 5
	snd_len 1
	snd_off
	snd_note Ds_3, 5
	snd_len 1
	snd_off
	snd_note E_3, 5
	snd_len 1
	snd_off
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_note Gs_3, 5
	snd_len 1
	snd_off
	snd_note G_3, 5
	snd_len 1
	snd_off
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_note Gs_3, 5
	snd_len 1
	snd_off
	snd_note F_3, 5
	snd_len 1
	snd_off
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_note A_3, 5
	snd_len 1
	snd_off
	snd_note F_3, 5
	snd_len 1
	snd_off
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_ret
Trk3C_5C50:
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note D_4, 5
	snd_len 1
	snd_off
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note Cs_4, 5
	snd_len 1
	snd_off
	snd_note Cs_4, 5
	snd_len 1
	snd_off
	snd_note E_4, 5
	snd_len 1
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note Cs_4, 5
	snd_len 1
	snd_off
	snd_note D_4, 5
	snd_len 1
	snd_off
	snd_note C_4, 5
	snd_len 1
	snd_off
	snd_note Cs_4, 5
	snd_len 1
	snd_off
	snd_ret
Trk3C_5C91:
	snd_note Ds_4, 5
	snd_len 1
	snd_off
	snd_note Ds_4, 5
	snd_len 1
	snd_off
	snd_note Fs_4, 5
	snd_len 1
	snd_off
	snd_note A_3, 5
	snd_len 1
	snd_off
	snd_note Ds_4, 5
	snd_len 1
	snd_off
	snd_note Ds_4, 5
	snd_len 1
	snd_off
	snd_note A_3, 5
	snd_len 1
	snd_off
	snd_note Ds_4, 5
	snd_len 1
	snd_off
	snd_note Ds_4, 5
	snd_len 1
	snd_off
	snd_note Ds_4, 5
	snd_len 1
	snd_off
	snd_note Fs_4, 5
	snd_len 1
	snd_off
	snd_note A_3, 5
	snd_len 1
	snd_off
	snd_note Ds_4, 5
	snd_len 1
	snd_off
	snd_note E_4, 5
	snd_len 1
	snd_off
	snd_note D_4, 5
	snd_len 1
	snd_off
	snd_note Ds_4, 5
	snd_len 1
	snd_off
	snd_ret
Trk3C_5CD2:
	snd_note E_3, 5
	snd_len 1
	snd_off
	snd_note E_3, 5
	snd_len 1
	snd_off
	snd_note F_3, 5
	snd_len 1
	snd_off
	snd_note Ds_3, 5
	snd_len 1
	snd_off
	snd_note E_3, 5
	snd_len 1
	snd_off
	snd_note E_4, 5
	snd_len 1
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note D_4, 5
	snd_len 1
	snd_off
	snd_note C_4, 5
	snd_len 1
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note A_3, 5
	snd_len 1
	snd_off
	snd_note G_3, 5
	snd_len 1
	snd_off
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_note G_3, 5
	snd_len 1
	snd_off
	snd_note F_3, 5
	snd_len 1
	snd_off
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_ret
Mus3C_3_Ch3:
	snd_duty $00
	snd_env2 $20
Trk3C_5D17:
	snd_wave SndWave0E
	snd_note Fs_4, 24
	snd_note Fs_4
	snd_note F_4
	snd_note F_4
	snd_note Fs_4
	snd_note Fs_4
	snd_note F_4
	snd_note F_4
	snd_call Trk3C_5DF2
	snd_note B_4, 12
	snd_note Fs_5, 24
	snd_note E_5, 12
	snd_note D_5
	snd_note A_5, 24
	snd_note Gs_5, 7
	snd_len 1
	snd_off
	snd_note A_5, 4
	snd_note As_5, 12
	snd_note B_5
	snd_note G_5
	snd_note E_5
	snd_note Fs_5, 8
	snd_note A_5, 4
	snd_note Gs_5, 8
	snd_note B_5, 4
	snd_note As_5, 24
	snd_note Fs_5, 10
	snd_note Gs_5, 3
	snd_note Fs_5, 23
	snd_note Gs_5, 9
	snd_note B_5, 3
	snd_note Fs_5, 8
	snd_len 1
	snd_off
	snd_note Gs_5, 3
	snd_note Fs_5, 24
	snd_note Gs_5, 2
	snd_note G_5
	snd_note Fs_5
	snd_note F_5, 3
	snd_note E_5
	snd_note Ds_5, 21
	snd_note Cs_5, 3
	snd_note Gs_5, 21
	snd_note Cs_5, 3
	snd_note Fs_5, 12
	snd_note Gs_5
	snd_note A_5
	snd_note As_5
	snd_wave SndWave10
	snd_transpose $0C
	snd_call Trk3C_5DF2
	snd_transpose $00
	snd_note Fs_6, 8
	snd_note G_6, 4
	snd_note Fs_6, 24
	snd_note G_6, 8
	snd_note B_6, 4
	snd_note Fs_6, 8
	snd_note G_6, 4
	snd_note Fs_6, 35
	snd_len 1
	snd_off
	snd_note Fs_6, 8
	snd_note G_6, 4
	snd_note Fs_6, 24
	snd_note G_6, 8
	snd_note B_6, 4
	snd_note Fs_6, 8
	snd_note G_6, 4
	snd_note Fs_6, 24
	snd_len 1
	snd_off
	snd_note Fs_6, 3
	snd_note G_6, 2
	snd_note Fs_6
	snd_note F_6
	snd_note Fs_6
	snd_loop 2
	snd_note G_6, 3
	snd_off
	snd_note E_6
	snd_off
	snd_note G_6
	snd_off
	snd_note E_6
	snd_len 15
	snd_off
	snd_note G_6, 3
	snd_note E_6
	snd_note Ds_6
	snd_note E_6
	snd_note G_6
	snd_off
	snd_note E_6
	snd_len 15
	snd_off
	snd_note As_6, 2
	snd_note B_6
	snd_note As_6
	snd_note B_6
	snd_note As_6
	snd_note B_6
	snd_note As_6
	snd_note B_6
	snd_note As_6
	snd_note B_6
	snd_note As_6
	snd_note B_6
	snd_endloop
	snd_loop 2
	snd_note C_6, 12
	snd_note B_5, 2
	snd_len 10
	snd_off
	snd_note C_7, 12
	snd_note B_6, 2
	snd_len 10
	snd_off
	snd_endloop
	snd_note C_6, 12
	snd_note B_5, 2
	snd_len 10
	snd_off
	snd_note C_6, 12
	snd_note B_5, 2
	snd_len 10
	snd_off
	snd_note C_5, 3
	snd_off
	snd_note B_4
	snd_off
	snd_note As_4
	snd_off
	snd_note A_4
	snd_off
	snd_note Gs_4
	snd_off
	snd_note G_4
	snd_off
	snd_note Fs_4
	snd_off
	snd_note F_4
	snd_off
	snd_jump Trk3C_5D17
Trk3C_5DF2:
	snd_note B_4, 12
	snd_note Fs_5, 24
	snd_note E_5, 12
	snd_note D_5
	snd_note A_5, 24
	snd_note Gs_5, 7
	snd_len 1
	snd_off
	snd_note Fs_5, 4
	snd_note E_5, 12
	snd_note D_5
	snd_note Cs_5
	snd_note B_4
	snd_note As_4, 7
	snd_len 1
	snd_off
	snd_note C_5, 4
	snd_note Cs_5, 7
	snd_len 1
	snd_off
	snd_note Ds_5, 4
	snd_note E_5, 24
	snd_ret
Mus3C_3_Ch2:
	snd_duty $80
	snd_pitchenv SndPitchEnv_499B
Trk3C_5E1A:
	snd_env $0D
	snd_note D_4, 48
	snd_note Cs_4
	snd_note D_4
	snd_note Cs_4
	snd_env $50
	snd_len 12
	snd_off
	snd_note Fs_4, 3
	snd_len 1
	snd_off
	snd_note Fs_4, 3
	snd_len 1
	snd_off
	snd_note Fs_4, 3
	snd_len 1
	snd_off
	snd_note Fs_4, 24
	snd_len 12
	snd_off
	snd_note Fs_4, 3
	snd_len 1
	snd_off
	snd_note Fs_4, 3
	snd_len 1
	snd_off
	snd_note Fs_4, 3
	snd_len 1
	snd_off
	snd_note Fs_4, 24
	snd_note Gs_5, 12
	snd_note Fs_5
	snd_note E_5
	snd_note D_5
	snd_note Cs_5, 6
	snd_note C_5, 1
	snd_note B_4
	snd_note As_4
	snd_note A_4
	snd_note Gs_4
	snd_note G_4
	snd_note Fs_4, 36
	snd_len 12
	snd_off
	snd_note Fs_4, 3
	snd_len 1
	snd_off
	snd_note Fs_4, 3
	snd_len 1
	snd_off
	snd_note Fs_4, 3
	snd_len 1
	snd_off
	snd_note Fs_4, 24
	snd_len 12
	snd_off
	snd_note Fs_4, 3
	snd_len 1
	snd_off
	snd_note Fs_4, 3
	snd_len 1
	snd_off
	snd_note Fs_4, 3
	snd_len 1
	snd_off
	snd_note Fs_4, 24
	snd_note Cs_5, 12
	snd_note D_5
	snd_note E_5
	snd_note Cs_5
	snd_note As_4, 8
	snd_note E_5, 4
	snd_note B_4, 8
	snd_note Fs_5, 4
	snd_note Cs_5, 24
	snd_len 12
	snd_off
	snd_note Ds_5, 3
	snd_len 1
	snd_off
	snd_note Ds_5, 3
	snd_len 1
	snd_off
	snd_note Ds_5, 3
	snd_len 1
	snd_off
	snd_note Ds_5, 24
	snd_len 12
	snd_off
	snd_note E_5, 3
	snd_len 1
	snd_off
	snd_note E_5, 3
	snd_len 1
	snd_off
	snd_note E_5, 3
	snd_len 1
	snd_off
	snd_note E_5, 24
	snd_len 60
	snd_off
	snd_note Cs_6, 3
	snd_len 1
	snd_off
	snd_note Cs_6, 3
	snd_len 1
	snd_off
	snd_note Cs_6, 3
	snd_len 1
	snd_off
	snd_note Cs_6, 3
	snd_off
	snd_note Cs_6
	snd_off
	snd_note Cs_6
	snd_off
	snd_note Cs_6
	snd_off
	snd_note Fs_5, 12
	snd_note D_6, 24
	snd_note Cs_6, 12
	snd_note B_5
	snd_note Fs_6, 24
	snd_note E_6, 7
	snd_len 1
	snd_off
	snd_note D_6, 4
	snd_note Cs_6, 12
	snd_note B_5
	snd_note As_5
	snd_note G_5
	snd_note Fs_5, 8
	snd_note G_5, 4
	snd_note Gs_5, 8
	snd_note A_5, 4
	snd_note As_5, 24
	snd_note D_6, 8
	snd_note Ds_6, 4
	snd_note D_6, 36
	snd_note Cs_6, 8
	snd_note D_6, 4
	snd_note Cs_6, 36
	snd_note C_6, 8
	snd_note D_6, 4
	snd_note C_6, 36
	snd_note B_5, 8
	snd_note C_6, 4
	snd_note B_5, 36
	snd_loop 2
	snd_len 24
	snd_off
	snd_note B_5, 3
	snd_off
	snd_note G_5
	snd_off
	snd_note B_5
	snd_off
	snd_note G_5
	snd_len 15
	snd_off
	snd_note B_5, 3
	snd_off
	snd_note G_5
	snd_off
	snd_note E_5
	snd_len 21
	snd_off
	snd_endloop
	snd_loop 2
	snd_note G_5, 12
	snd_note E_5, 3
	snd_len 9
	snd_off
	snd_note G_6, 12
	snd_note E_6, 3
	snd_len 9
	snd_off
	snd_endloop
	snd_note G_5, 12
	snd_note E_5, 3
	snd_len 9
	snd_off
	snd_note G_5, 12
	snd_note E_5, 3
	snd_len 9
	snd_off
	snd_note G_5, 3
	snd_off
	snd_note E_5
	snd_off
	snd_note Fs_5
	snd_off
	snd_note D_5
	snd_off
	snd_note E_5
	snd_off
	snd_note C_5
	snd_off
	snd_note D_5
	snd_off
	snd_note B_4
	snd_off
	snd_jump Trk3C_5E1A
Mus3C_3_Ch4:
	snd_loop 15
	snd_len 9
	snd_drum 5
	snd_len 3
	snd_drum 5
	snd_len 6
	snd_drum 0
	snd_drum 5
	snd_len 12
	snd_drum 5
	snd_drum 2
	snd_len 9
	snd_drum 5
	snd_len 3
	snd_drum 5
	snd_len 6
	snd_drum 0
	snd_drum 5
	snd_len 12
	snd_drum 5
	snd_len 6
	snd_drum 4
	snd_drum 5
	snd_endloop
	snd_len 9
	snd_drum 5
	snd_len 3
	snd_drum 5
	snd_len 6
	snd_drum 0
	snd_drum 5
	snd_len 12
	snd_drum 5
	snd_drum 2
	snd_len 6
	snd_drum 5
	snd_drum 7
	snd_drum 5
	snd_drum 8
	snd_drum 5
	snd_drum 9
	snd_len 1
	snd_drum 4
	snd_len 11
	snd_drum 4
	snd_jump Mus3C_3_Ch4
Mus3C_4:
	db $0F	; channel mask
	dw Mus3C_4_Ch1, Mus3C_4_Ch2, Mus3C_4_Ch3, Mus3C_4_Ch4
Mus3C_4_Ch1:
	snd_tempo 80
	snd_duty $40
	snd_pitchenv SndPitchEnv_4A04
Trk3C_5F76:
	snd_env $0F
	snd_loop 2
	snd_len 48
	snd_off
	snd_off
	snd_off
	snd_off
	snd_endloop
	snd_note Fs_4, 48
	snd_note F_4
	snd_note E_4
	snd_note F_4, 44
	snd_len 1
	snd_off
	snd_env $80
	snd_note F_4
	snd_note Fs_4
	snd_note G_4
	snd_env $0F
	snd_note Gs_4, 92
	snd_len 1
	snd_off
	snd_env $80
	snd_note Gs_4
	snd_note A_4
	snd_note As_4
	snd_env $1F
	snd_note B_4, 41
	snd_env $80
	snd_note As_4, 3
	snd_note A_4, 2
	snd_env $2F
	snd_note Gs_4, 25
	snd_env $80
	snd_note D_4, 1
	snd_env $0F
	snd_note Ds_4, 24
	snd_note Fs_4, 47
	snd_note F_4, 49
	snd_note E_4, 48
	snd_note F_4, 44
	snd_env $80
	snd_len 1
	snd_off
	snd_note F_4
	snd_off
	snd_note G_4
	snd_env $0F
	snd_note Gs_4, 92
	snd_len 1
	snd_off
	snd_env $80
	snd_note Gs_4
	snd_note A_4
	snd_note As_4
	snd_env $1F
	snd_note B_4, 40
	snd_env $80
	snd_note As_4, 3
	snd_note A_4
	snd_env $2F
	snd_note Gs_4, 25
	snd_env $80
	snd_note C_5, 1
	snd_env $2F
	snd_note Cs_5, 24
	snd_env $80
	snd_call Trk3C_619C
	snd_transpose $01
	snd_call Trk3C_619C
	snd_transpose $FC
	snd_call Trk3C_619C
	snd_transpose $FD
	snd_call Trk3C_619C
	snd_transpose $00
	snd_note As_4, 2
	snd_len 1
	snd_off
	snd_note F_5, 2
	snd_len 1
	snd_off
	snd_note F_5, 2
	snd_len 7
	snd_off
	snd_note F_5, 2
	snd_len 1
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note F_5, 2
	snd_len 1
	snd_off
	snd_note F_5, 2
	snd_len 1
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note As_4, 2
	snd_len 1
	snd_off
	snd_note F_5, 2
	snd_len 1
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note F_5, 2
	snd_len 1
	snd_off
	snd_note F_5, 2
	snd_len 1
	snd_off
	snd_note B_4, 2
	snd_len 1
	snd_off
	snd_note Fs_5, 2
	snd_len 1
	snd_off
	snd_note Fs_5, 2
	snd_len 7
	snd_off
	snd_note Fs_5, 2
	snd_len 1
	snd_off
	snd_note Fs_5, 2
	snd_len 4
	snd_off
	snd_note Fs_5, 2
	snd_len 4
	snd_off
	snd_note Fs_5, 2
	snd_len 4
	snd_off
	snd_note Fs_5, 2
	snd_len 4
	snd_off
	snd_note Fs_5, 2
	snd_len 1
	snd_off
	snd_note Fs_5, 2
	snd_len 1
	snd_off
	snd_note Fs_5, 2
	snd_len 4
	snd_off
	snd_note Fs_5, 2
	snd_len 4
	snd_off
	snd_note Fs_5, 2
	snd_len 4
	snd_off
	snd_note Fs_5, 2
	snd_len 5
	snd_off
	snd_note Fs_5, 2
	snd_note B_5, 3
	snd_note E_6
	snd_note A_6
	snd_note B_6, 2
	snd_note Fs_6, 3
	snd_note Gs_6, 2
	snd_note Cs_7
	snd_note E_7, 3
	snd_note Ds_7, 2
	snd_note Cs_7, 1
	snd_note Fs_6
	snd_note Gs_5, 2
	snd_note Ds_5
	snd_len 4
	snd_off
	snd_note Fs_4, 2
	snd_len 1
	snd_off
	snd_note Cs_5, 2
	snd_len 1
	snd_off
	snd_note Cs_5, 2
	snd_len 4
	snd_off
	snd_note Cs_5, 2
	snd_len 4
	snd_off
	snd_note Cs_5, 2
	snd_len 4
	snd_off
	snd_note Cs_5, 2
	snd_len 4
	snd_off
	snd_note Cs_5, 2
	snd_len 1
	snd_off
	snd_note Cs_5, 2
	snd_len 1
	snd_off
	snd_note Cs_5, 2
	snd_len 4
	snd_off
	snd_note Cs_5, 2
	snd_len 4
	snd_off
	snd_note Cs_5, 2
	snd_len 4
	snd_off
	snd_note Cs_5, 2
	snd_len 4
	snd_off
	snd_note Fs_4, 2
	snd_len 1
	snd_off
	snd_note Cs_5, 2
	snd_len 1
	snd_off
	snd_note Cs_5, 2
	snd_len 4
	snd_off
	snd_note Cs_5, 2
	snd_len 4
	snd_off
	snd_note Cs_5, 2
	snd_len 1
	snd_off
	snd_note Cs_5, 2
	snd_len 1
	snd_off
	snd_note Cs_5, 5
	snd_len 1
	snd_off
	snd_note Ds_5, 5
	snd_len 1
	snd_off
	snd_note E_5, 5
	snd_len 1
	snd_off
	snd_note G_5, 5
	snd_len 7
	snd_off
	snd_note G_4, 18
	snd_note A_4
	snd_note As_4, 26
	snd_note B_4, 2
	snd_note C_5
	snd_note Cs_5, 5
	snd_len 1
	snd_off
	snd_note Gs_4, 5
	snd_len 1
	snd_off
	snd_note G_4, 5
	snd_len 1
	snd_off
	snd_note Fs_4, 5
	snd_len 7
	snd_off
	snd_note E_4, 6
	snd_note Fs_4, 48
	snd_note E_4, 6
	snd_note Fs_4, 5
	snd_len 1
	snd_off
	snd_note Gs_4, 9
	snd_len 3
	snd_off
	snd_note Gs_4, 6
	snd_note B_4, 9
	snd_len 3
	snd_off
	snd_note B_4, 5
	snd_len 1
	snd_off
	snd_note As_4, 50
	snd_len 10
	snd_off
	snd_note Cs_5, 5
	snd_len 1
	snd_off
	snd_note Gs_4, 5
	snd_len 1
	snd_off
	snd_note G_4, 5
	snd_len 1
	snd_off
	snd_note Fs_4, 5
	snd_len 7
	snd_off
	snd_note E_4, 6
	snd_note Fs_4, 48
	snd_note E_4, 5
	snd_note Fs_4, 6
	snd_len 1
	snd_off
	snd_note Gs_4, 7
	snd_len 5
	snd_off
	snd_note Gs_3
	snd_len 1
	snd_off
	snd_note B_3, 8
	snd_len 4
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note Cs_4, 60
	snd_note Cs_5, 5
	snd_note Gs_4, 6
	snd_note G_4
	snd_len 1
	snd_off
	snd_note Fs_4, 8
	snd_len 4
	snd_off
	snd_note E_4, 5
	snd_len 1
	snd_off
	snd_note Fs_4, 46
	snd_len 2
	snd_off
	snd_note E_4, 6
	snd_note Fs_4
	snd_note Gs_4, 9
	snd_len 3
	snd_off
	snd_note Gs_4, 6
	snd_note B_4, 9
	snd_len 3
	snd_off
	snd_note B_4, 5
	snd_len 1
	snd_off
	snd_note As_4, 50
	snd_len 10
	snd_off
	snd_note Cs_5, 5
	snd_note Gs_4, 6
	snd_len 1
	snd_off
	snd_note G_4, 6
	snd_note Fs_4
	snd_off
	snd_note E_4
	snd_note Fs_4, 44
	snd_len 4
	snd_off
	snd_note E_4, 5
	snd_note Fs_4, 6
	snd_len 1
	snd_off
	snd_note Gs_4, 7
	snd_len 5
	snd_off
	snd_note Gs_3
	snd_len 1
	snd_off
	snd_note B_3, 8
	snd_len 4
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note Cs_4, 60
	snd_jump Trk3C_5F76
Trk3C_619C:
	snd_note F_5, 2
	snd_len 1
	snd_off
	snd_note F_5, 2
	snd_len 1
	snd_off
	snd_note F_5, 2
	snd_len 7
	snd_off
	snd_note F_5, 2
	snd_len 1
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note F_5, 2
	snd_len 1
	snd_off
	snd_note F_5, 2
	snd_len 1
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note F_5, 2
	snd_len 7
	snd_off
	snd_note F_5, 2
	snd_len 1
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note F_5, 2
	snd_len 1
	snd_off
	snd_note F_5, 2
	snd_len 1
	snd_off
	snd_ret
Mus3C_4_Ch2:
	snd_env $60
	snd_duty $80
	snd_pitchenv SndPitchEnv_499B
Trk3C_61F0:
	snd_loop 2
	snd_note Fs_4, 48
	snd_note F_4
	snd_note E_4
	snd_note F_4
	snd_endloop
	snd_note Gs_4, 12
	snd_note Ds_5, 18
	snd_note Gs_5, 42
	snd_note B_5, 6
	snd_note Cs_6
	snd_note Fs_5
	snd_note G_5
	snd_note Gs_5, 12
	snd_note B_5, 6
	snd_note D_6, 54
	snd_note D_6, 24
	snd_note As_5, 12
	snd_note Cs_6, 6
	snd_note B_5
	snd_note D_6, 12
	snd_note E_5, 6
	snd_note F_5, 30
	snd_note Gs_5, 6
	snd_note As_5
	snd_note Gs_5
	snd_note B_5
	snd_len 12
	snd_off
	snd_note Fs_5, 18
	snd_note F_5
	snd_note Gs_5
	snd_note Ds_5
	snd_note Cs_5, 12
	snd_note Gs_4
	snd_note Ds_5, 18
	snd_note Gs_5, 42
	snd_note B_5, 6
	snd_note Cs_6
	snd_note Fs_5
	snd_note G_5
	snd_note Gs_5, 12
	snd_note B_5, 6
	snd_note D_6, 54
	snd_note D_6, 24
	snd_note As_5, 12
	snd_note Cs_6, 6
	snd_note B_5
	snd_note D_6, 12
	snd_note E_6, 6
	snd_note F_6, 30
	snd_note Gs_6, 6
	snd_note As_6
	snd_note Gs_6
	snd_note B_6
	snd_len 12
	snd_off
	snd_note As_6, 18
	snd_note G_6
	snd_note E_6
	snd_note Cs_6, 30
	snd_note As_4, 2
	snd_len 1
	snd_off
	snd_note As_4, 2
	snd_len 1
	snd_off
	snd_note As_4, 2
	snd_len 4
	snd_off
	snd_note As_4, 2
	snd_len 4
	snd_off
	snd_note As_4, 2
	snd_len 4
	snd_off
	snd_note As_4, 2
	snd_len 4
	snd_off
	snd_note As_4, 2
	snd_len 4
	snd_off
	snd_note As_4, 2
	snd_len 4
	snd_off
	snd_note As_4, 2
	snd_len 1
	snd_off
	snd_note As_4, 2
	snd_len 1
	snd_off
	snd_note As_4, 2
	snd_len 4
	snd_off
	snd_note As_4, 2
	snd_len 4
	snd_off
	snd_note As_4, 2
	snd_len 4
	snd_off
	snd_note As_4, 2
	snd_len 4
	snd_off
	snd_note As_4, 2
	snd_len 4
	snd_off
	snd_note As_4, 2
	snd_len 4
	snd_off
	snd_note As_4, 3
	snd_note As_4
	snd_note As_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 2
	snd_len 1
	snd_off
	snd_note A_4, 2
	snd_len 1
	snd_off
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 2
	snd_len 1
	snd_off
	snd_note A_4, 2
	snd_len 1
	snd_off
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 3
	snd_note B_4
	snd_note Cs_5
	snd_off
	snd_note Gs_4, 2
	snd_len 1
	snd_off
	snd_note Gs_4, 2
	snd_len 1
	snd_off
	snd_note Gs_4, 2
	snd_len 4
	snd_off
	snd_note Gs_4, 2
	snd_len 4
	snd_off
	snd_note Gs_4, 2
	snd_len 4
	snd_off
	snd_note Gs_4, 2
	snd_len 4
	snd_off
	snd_note Gs_4, 2
	snd_len 4
	snd_off
	snd_note Gs_4, 2
	snd_len 4
	snd_off
	snd_note Gs_4, 2
	snd_len 1
	snd_off
	snd_note Gs_4, 2
	snd_len 1
	snd_off
	snd_note Gs_4, 2
	snd_len 4
	snd_off
	snd_note Gs_4, 2
	snd_len 4
	snd_off
	snd_note Gs_4, 2
	snd_len 4
	snd_off
	snd_note Gs_4, 2
	snd_len 4
	snd_off
	snd_note Gs_4, 2
	snd_len 4
	snd_off
	snd_note Gs_4, 2
	snd_len 4
	snd_off
	snd_note Gs_4, 2
	snd_len 1
	snd_off
	snd_note Gs_4, 2
	snd_len 1
	snd_off
	snd_note Gs_4, 2
	snd_len 1
	snd_off
	snd_note G_4, 2
	snd_len 1
	snd_off
	snd_note Fs_4, 2
	snd_len 1
	snd_off
	snd_note Fs_4, 2
	snd_len 1
	snd_off
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note Fs_4, 2
	snd_len 1
	snd_off
	snd_note Fs_4, 2
	snd_len 1
	snd_off
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note Fs_4, 2
	snd_len 1
	snd_off
	snd_note Fs_4, 2
	snd_len 1
	snd_off
	snd_note Fs_4, 2
	snd_len 5
	snd_off
	snd_note Ds_4, 17
	snd_note As_4
	snd_note Ds_5, 33
	snd_len 4
	snd_off
	snd_note Ds_5, 6
	snd_note Cs_5
	snd_note Ds_5
	snd_note E_5
	snd_note Fs_5, 12
	snd_note Gs_5, 7
	snd_note A_5, 76
	snd_len 1
	snd_off
	snd_note Ds_6, 19
	snd_note Gs_5, 18
	snd_note Ds_5, 34
	snd_note E_5, 1
	snd_note F_5, 2
	snd_note Fs_5, 8
	snd_note E_5, 7
	snd_note Ds_5
	snd_note Cs_5, 6
	snd_note G_5
	snd_note As_5
	snd_note Ds_6, 7
	snd_len 21
	snd_off
	snd_note Ds_6, 1
	snd_note E_6
	snd_note Fs_6, 11
	snd_note E_6, 7
	snd_note Ds_6, 12
	snd_note Gs_6, 18
	snd_env $0F
	snd_note Cs_7, 32
	snd_env $D7
	snd_note Cs_7, 64
	snd_env $60
	snd_len 1
	snd_off
	snd_note Cs_4, 17
	snd_note C_5, 1
	snd_note Cs_5, 17
	snd_note Cs_4, 28
	snd_len 2
	snd_off
	snd_note Cs_4, 6
	snd_off
	snd_note B_3
	snd_note Cs_4, 10
	snd_len 2
	snd_off
	snd_note Cs_4, 18
	snd_note C_5, 1
	snd_note Cs_5, 16
	snd_len 1
	snd_off
	snd_note Cs_4, 28
	snd_len 2
	snd_off
	snd_note Cs_4, 6
	snd_off
	snd_note B_3
	snd_note Cs_4, 9
	snd_len 3
	snd_off
	snd_note Cs_4, 18
	snd_note C_5, 1
	snd_note Cs_5, 17
	snd_note Cs_4, 60
	snd_note Cs_5, 17
	snd_note C_6, 1
	snd_note Cs_6, 18
	snd_note Cs_5, 48
	snd_note Cs_6, 6
	snd_note Ds_6
	snd_note E_6, 19
	snd_note F_6, 1
	snd_note Fs_6
	snd_note G_6, 16
	snd_note Fs_6, 59
	snd_len 1
	snd_off
	snd_note Gs_6, 18
	snd_note E_6, 17
	snd_note As_6, 48
	snd_note Gs_6, 6
	snd_note As_6
	snd_note B_6, 16
	snd_note Cs_7, 1
	snd_note D_7
	snd_note Ds_7, 18
	snd_note Cs_7, 60
	snd_jump Trk3C_61F0
Mus3C_4_Ch3:
	snd_duty $00
	snd_env2 $20
	snd_wave SndWave00
Trk3C_6418:
	snd_loop 4
	snd_note Gs_3, 4
	snd_len 2
	snd_off
	snd_note Gs_3, 4
	snd_len 2
	snd_off
	snd_note B_3, 4
	snd_len 2
	snd_off
	snd_note Gs_3, 4
	snd_len 8
	snd_off
	snd_note Gs_3, 4
	snd_len 8
	snd_off
	snd_note Fs_3, 4
	snd_len 2
	snd_off
	snd_note Gs_3, 4
	snd_len 2
	snd_off
	snd_note Gs_3, 4
	snd_len 2
	snd_off
	snd_note B_3, 4
	snd_len 2
	snd_off
	snd_note Gs_3, 4
	snd_len 8
	snd_off
	snd_note Gs_3, 4
	snd_len 8
	snd_off
	snd_note Fs_3, 4
	snd_len 2
	snd_off
	snd_endloop
	snd_loop 2
	snd_note Gs_3, 4
	snd_len 2
	snd_off
	snd_note Gs_3, 4
	snd_len 2
	snd_off
	snd_note B_3, 4
	snd_len 2
	snd_off
	snd_note Gs_3, 4
	snd_len 8
	snd_off
	snd_note Gs_3, 4
	snd_len 8
	snd_off
	snd_note Fs_3, 4
	snd_len 2
	snd_off
	snd_note Gs_3, 4
	snd_len 2
	snd_off
	snd_note Gs_3, 4
	snd_len 2
	snd_off
	snd_note B_3, 4
	snd_len 2
	snd_off
	snd_note Gs_3, 4
	snd_len 8
	snd_off
	snd_note Gs_3, 4
	snd_len 8
	snd_off
	snd_note Fs_3, 4
	snd_len 2
	snd_off
	snd_note Gs_3, 4
	snd_len 2
	snd_off
	snd_note Gs_3, 4
	snd_len 2
	snd_off
	snd_note B_3, 4
	snd_len 2
	snd_off
	snd_note Gs_3, 4
	snd_len 8
	snd_off
	snd_note Gs_3, 4
	snd_len 2
	snd_off
	snd_note As_3, 4
	snd_len 2
	snd_off
	snd_note Cs_4, 4
	snd_len 2
	snd_off
	snd_note B_3, 4
	snd_len 2
	snd_off
	snd_note B_3, 4
	snd_len 2
	snd_off
	snd_note D_4, 4
	snd_len 2
	snd_off
	snd_note B_3, 4
	snd_len 8
	snd_off
	snd_note B_3, 4
	snd_len 8
	snd_off
	snd_note Fs_3, 4
	snd_len 2
	snd_off
	snd_note F_3, 4
	snd_len 2
	snd_off
	snd_note F_3, 4
	snd_len 2
	snd_off
	snd_note Gs_3, 4
	snd_len 2
	snd_off
	snd_note F_3, 4
	snd_len 8
	snd_off
	snd_note F_3, 4
	snd_len 8
	snd_off
	snd_note Gs_3, 4
	snd_len 2
	snd_off
	snd_note F_3, 4
	snd_len 2
	snd_off
	snd_note F_3, 4
	snd_len 2
	snd_off
	snd_note Gs_3, 4
	snd_len 2
	snd_off
	snd_note F_3, 4
	snd_len 8
	snd_off
	snd_note F_3, 4
	snd_len 8
	snd_off
	snd_note Gs_3, 4
	snd_len 2
	snd_off
	snd_note F_3, 4
	snd_len 2
	snd_off
	snd_note F_3, 4
	snd_len 2
	snd_off
	snd_note Gs_3, 4
	snd_len 2
	snd_off
	snd_note F_3, 4
	snd_len 8
	snd_off
	snd_note F_3, 4
	snd_len 8
	snd_off
	snd_note Gs_3, 4
	snd_len 2
	snd_off
	snd_note As_3, 4
	snd_len 2
	snd_off
	snd_note As_3, 4
	snd_len 2
	snd_off
	snd_note Cs_4, 4
	snd_len 2
	snd_off
	snd_note As_3, 4
	snd_len 8
	snd_off
	snd_note As_3, 4
	snd_len 8
	snd_off
	snd_note Fs_3, 4
	snd_len 2
	snd_off
	snd_endloop
	snd_note Gs_3, 12
	snd_note Ds_4, 18
	snd_note Gs_4, 42
	snd_note B_4, 6
	snd_note Cs_5
	snd_note Fs_4
	snd_note G_4
	snd_note A_4, 12
	snd_note Cs_4, 6
	snd_note D_4, 66
	snd_len 12
	snd_off
	snd_note B_4
	snd_note E_4, 18
	snd_note B_3, 42
	snd_note Gs_3, 6
	snd_note Fs_3
	snd_note Cs_4
	snd_note C_4
	snd_note B_3, 12
	snd_note E_4, 6
	snd_note As_3, 66
	snd_len 12
	snd_off
	snd_note G_3, 6
	snd_note Ds_4, 5
	snd_len 25
	snd_off
	snd_note Ds_4, 6
	snd_note G_3, 4
	snd_len 8
	snd_off
	snd_note G_3, 5
	snd_len 1
	snd_off
	snd_note Ds_4, 36
	snd_note E_4, 6
	snd_note A_3, 7
	snd_len 23
	snd_off
	snd_note A_3, 6
	snd_note E_4
	snd_off
	snd_note E_4
	snd_note B_4, 36
	snd_note Gs_4, 6
	snd_note Ds_4, 5
	snd_len 25
	snd_off
	snd_note Ds_4, 6
	snd_note Gs_3, 4
	snd_len 8
	snd_off
	snd_note Gs_3, 5
	snd_len 1
	snd_off
	snd_note Cs_4, 35
	snd_len 1
	snd_off
	snd_note G_3, 6
	snd_note Ds_4
	snd_note E_4
	snd_note As_4
	snd_len 17
	snd_off
	snd_note A_3, 1
	snd_note As_3, 18
	snd_note G_3, 5
	snd_len 1
	snd_off
	snd_note F_4
	snd_note Fs_4, 12
	snd_note E_4, 11
	snd_note As_3, 1
	snd_note B_3
	snd_note C_4
	snd_note D_4, 3
	snd_note Cs_4, 5
	snd_len 1
	snd_off
	snd_note Gs_3, 6
	snd_note G_3
	snd_note Fs_3, 8
	snd_len 4
	snd_off
	snd_note E_3, 5
	snd_len 1
	snd_off
	snd_note Fs_3, 46
	snd_len 2
	snd_off
	snd_note E_3, 6
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_note Gs_3, 9
	snd_len 3
	snd_off
	snd_note Gs_3, 6
	snd_note B_3, 9
	snd_len 3
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note As_3, 50
	snd_len 10
	snd_off
	snd_note Cs_4, 6
	snd_note Gs_3
	snd_note G_3
	snd_note Fs_3
	snd_off
	snd_note E_3
	snd_note Fs_3, 44
	snd_len 4
	snd_off
	snd_note E_3, 6
	snd_note Fs_3
	snd_note Gs_3, 7
	snd_len 5
	snd_off
	snd_note Gs_2
	snd_len 1
	snd_off
	snd_note B_2, 8
	snd_len 4
	snd_off
	snd_note B_2, 5
	snd_len 1
	snd_off
	snd_note Cs_3, 60
	snd_note Cs_4, 5
	snd_len 1
	snd_off
	snd_note Gs_3, 6
	snd_note G_3
	snd_note Fs_3, 8
	snd_len 4
	snd_off
	snd_note E_3, 5
	snd_len 1
	snd_off
	snd_note Fs_3, 46
	snd_len 2
	snd_off
	snd_note E_3, 5
	snd_len 1
	snd_off
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_note Gs_3, 9
	snd_len 3
	snd_off
	snd_note Gs_3, 6
	snd_note B_3, 9
	snd_len 3
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note As_3, 50
	snd_len 10
	snd_off
	snd_note Cs_4, 5
	snd_len 1
	snd_off
	snd_note Gs_3, 6
	snd_note G_3
	snd_note Fs_3
	snd_off
	snd_note E_3
	snd_note Fs_3, 44
	snd_len 4
	snd_off
	snd_note E_3, 5
	snd_len 1
	snd_off
	snd_note Fs_3, 6
	snd_note Gs_3, 7
	snd_len 5
	snd_off
	snd_note Gs_2
	snd_len 1
	snd_off
	snd_note B_2, 8
	snd_len 4
	snd_off
	snd_note B_2, 5
	snd_len 1
	snd_off
	snd_note Cs_3, 60
	snd_jump Trk3C_6418
Mus3C_4_Ch4:
	snd_loop 12
	snd_len 12
	snd_drum 9
	snd_drum 4
	snd_len 6
	snd_drum 5
	snd_drum 5
	snd_len 12
	snd_drum 4
	snd_drum 5
	snd_drum 4
	snd_len 6
	snd_drum 5
	snd_drum 5
	snd_len 12
	snd_drum 4
	snd_endloop
	snd_loop 4
	snd_len 6
	snd_drum 5
	snd_drum 0
	snd_len 3
	snd_drum 1
	snd_drum 0
	snd_len 6
	snd_drum 2
	snd_drum 4
	snd_drum 0
	snd_len 3
	snd_drum 5
	snd_drum 0
	snd_drum 2
	snd_drum 0
	snd_len 6
	snd_drum 11
	snd_drum 0
	snd_len 12
	snd_drum 5
	snd_len 3
	snd_drum 4
	snd_drum 0
	snd_len 6
	snd_drum 8
	snd_len 3
	snd_drum 0
	snd_drum 0
	snd_drum 8
	snd_drum 2
	snd_endloop
	snd_loop 3
	snd_len 3
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 5
	snd_drum 0
	snd_drum 0
	snd_drum 1
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 5
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 11
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_len 6
	snd_drum 5
	snd_len 3
	snd_drum 5
	snd_drum 5
	snd_drum 4
	snd_drum 0
	snd_drum 8
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 8
	snd_drum 2
	snd_endloop
	snd_len 3
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 5
	snd_drum 0
	snd_drum 0
	snd_drum 1
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 5
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_len 6
	snd_drum 11
	snd_drum 7
	snd_len 3
	snd_drum 7
	snd_drum 7
	snd_len 6
	snd_drum 7
	snd_drum 8
	snd_drum 8
	snd_drum 9
	snd_drum 9
	snd_loop 7
	snd_len 12
	snd_drum 5
	snd_drum 5
	snd_len 18
	snd_drum 4
	snd_len 6
	snd_drum 5
	snd_len 12
	snd_drum 5
	snd_drum 2
	snd_drum 4
	snd_drum 5
	snd_endloop
	snd_len 12
	snd_drum 11
	snd_len 6
	snd_drum 7
	snd_len 12
	snd_drum 8
	snd_len 6
	snd_drum 9
	snd_len 12
	snd_drum 11
	snd_drum 5
	snd_drum 9
	snd_len 3
	snd_drum 4
	snd_drum 4
	snd_len 6
	snd_drum 4
	snd_drum 4
	snd_drum 4
	snd_jump Mus3C_4_Ch4
Mus3C_5:
	db $0F	; channel mask
	dw Mus3C_5_Ch1, Mus3C_5_Ch2, Mus3C_5_Ch3, Mus3C_5_Ch4
Mus3C_5_Ch2:
	snd_tempo 140
	snd_duty $80
	snd_env $50
	snd_pitchenv SndPitchEnv_4A04
Trk3C_66CF:
	snd_transpose $00
	snd_loop 4
	snd_len 96
	snd_off
	snd_len 48
	snd_off
	snd_note D_5, 12
	snd_note A_5, 2
	snd_note D_6
	snd_len 8
	snd_off
	snd_note D_5, 12
	snd_note A_5, 2
	snd_note D_6
	snd_len 8
	snd_off
	snd_endloop
	snd_call Trk3C_6729
	snd_call Trk3C_6729
	snd_call Trk3C_678B
	snd_call Trk3C_679F
	snd_call Trk3C_678B
	snd_call Trk3C_67B4
	snd_call Trk3C_67C1
	snd_call Trk3C_6894
	snd_transpose $0C
	snd_call Trk3C_6894
	snd_transpose $00
	snd_call Trk3C_6894
	snd_transpose $0C
	snd_call Trk3C_6894
	snd_transpose $18
	snd_call Trk3C_6C99
	snd_transpose $13
	snd_call Trk3C_6C99
	snd_transpose $00
	snd_note D_5, 96
	snd_off
	snd_transpose $18
	snd_call Trk3C_6CD2
	snd_transpose $30
	snd_call Trk3C_6CD2
	snd_jump Trk3C_66CF
Trk3C_6729:
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
	snd_ret
Trk3C_678B:
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
	snd_ret
Trk3C_679F:
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
	snd_ret
Trk3C_67B4:
	snd_note G_5, 36
	snd_note A_5, 12
	snd_note C_6, 24
	snd_note A_5, 18
	snd_note G_5, 6
	snd_note A_5, 96
	snd_ret
Trk3C_67C1:
	snd_note G_5, 18
	snd_note F_5, 5
	snd_len 1
	snd_off
	snd_note G_5, 9
	snd_len 3
	snd_off
	snd_note D_4, 1
	snd_len 5
	snd_off
	snd_note F_4, 1
	snd_len 5
	snd_off
	snd_note G_4, 1
	snd_len 5
	snd_off
	snd_note G_4, 1
	snd_len 5
	snd_off
	snd_note D_5, 1
	snd_len 5
	snd_off
	snd_note G_4, 1
	snd_len 5
	snd_off
	snd_note G_4, 1
	snd_len 5
	snd_off
	snd_note G_4, 1
	snd_len 5
	snd_off
	snd_note D_5, 1
	snd_len 5
	snd_off
	snd_note G_4, 1
	snd_len 5
	snd_off
	snd_note A_5, 18
	snd_note G_5, 5
	snd_len 1
	snd_off
	snd_note A_5, 9
	snd_len 3
	snd_off
	snd_note D_4, 1
	snd_len 5
	snd_off
	snd_note F_4, 1
	snd_len 5
	snd_off
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note D_5, 1
	snd_len 5
	snd_off
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note D_5, 1
	snd_len 5
	snd_off
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note G_5, 4
	snd_len 2
	snd_off
	snd_note G_5, 6
	snd_off
	snd_note F_5, 5
	snd_len 1
	snd_off
	snd_note G_5, 9
	snd_len 3
	snd_off
	snd_note D_4, 1
	snd_len 5
	snd_off
	snd_note F_4, 1
	snd_len 5
	snd_off
	snd_note G_4, 1
	snd_len 5
	snd_off
	snd_note G_4, 1
	snd_len 5
	snd_off
	snd_note D_5, 1
	snd_len 5
	snd_off
	snd_note G_4, 1
	snd_len 5
	snd_off
	snd_note G_4, 1
	snd_len 5
	snd_off
	snd_note G_4, 1
	snd_len 5
	snd_off
	snd_note D_5, 1
	snd_len 5
	snd_off
	snd_note G_4, 1
	snd_len 5
	snd_off
	snd_note A_5, 4
	snd_len 2
	snd_off
	snd_note A_5, 6
	snd_off
	snd_note G_5, 5
	snd_len 1
	snd_off
	snd_note A_5, 9
	snd_len 3
	snd_off
	snd_note D_4, 1
	snd_len 5
	snd_off
	snd_note F_4, 1
	snd_len 5
	snd_off
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note D_5, 1
	snd_len 5
	snd_off
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note D_5, 1
	snd_len 5
	snd_off
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_ret
Trk3C_6894:
	snd_note D_6, 6
	snd_off
	snd_note A_5
	snd_note C_6
	snd_note D_6
	snd_off
	snd_note F_6
	snd_note D_6
	snd_note G_6
	snd_off
	snd_note F_6
	snd_off
	snd_note D_6
	snd_len 18
	snd_off
	snd_ret
Mus3C_5_Ch1:
	snd_duty $40
	snd_env $60
Trk3C_68A9:
	snd_len 96
	snd_off
	snd_off
	snd_off
	snd_off
	snd_loop 9
	snd_call Trk3C_68EB
	snd_endloop
	snd_call Trk3C_695A
	snd_call Trk3C_69C9
	snd_call Trk3C_6A22
	snd_loop 2
	snd_call Trk3C_6894
	snd_transpose $F4
	snd_call Trk3C_6894
	snd_transpose $00
	snd_endloop
	snd_transpose $13
	snd_call Trk3C_6C99
	snd_transpose $0C
	snd_call Trk3C_6C99
	snd_transpose $0C
	snd_call Trk3C_6CD2
	snd_call Trk3C_6CD2
	snd_transpose $00
	snd_call Trk3C_6A83
	snd_transpose $18
	snd_call Trk3C_6CD2
	snd_transpose $00
	snd_jump Trk3C_68A9
Trk3C_68EB:
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
	snd_ret
Trk3C_695A:
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
	snd_ret
Trk3C_69C9:
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
	snd_note G_7, 18
	snd_note F_7, 6
	snd_note G_7
	snd_off
	snd_note C_7, 2
	snd_len 4
	snd_off
	snd_note D_6, 1
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
	snd_note C_7, 1
	snd_len 5
	snd_off
	snd_note A_6, 3
	snd_off
	snd_note G_6, 1
	snd_len 5
	snd_off
	snd_note D_6, 1
	snd_len 5
	snd_off
	snd_note A_7, 18
	snd_note G_7, 6
	snd_note A_7
	snd_off
	snd_note C_7, 2
	snd_len 4
	snd_off
	snd_note D_6, 1
	snd_len 5
	snd_off
	snd_ret
Trk3C_6A22:
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
	snd_note G_7, 4
	snd_len 2
	snd_off
	snd_note G_7, 6
	snd_off
	snd_note F_7
	snd_note G_7
	snd_off
	snd_note C_7, 2
	snd_len 4
	snd_off
	snd_note D_6, 1
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
	snd_note C_7, 1
	snd_len 5
	snd_off
	snd_note A_6, 3
	snd_off
	snd_note G_6, 1
	snd_len 5
	snd_off
	snd_note D_6, 1
	snd_len 5
	snd_off
	snd_note A_7, 4
	snd_len 2
	snd_off
	snd_note A_7, 6
	snd_off
	snd_note G_7
	snd_note A_7
	snd_off
	snd_note C_7, 2
	snd_len 4
	snd_off
	snd_note D_6, 1
	snd_len 5
	snd_off
	snd_ret
Trk3C_6A83:
	snd_note A_4, 12
	snd_note A_5, 2
	snd_len 4
	snd_off
	snd_note A_5, 2
	snd_len 4
	snd_off
	snd_note A_5, 2
	snd_len 10
	snd_off
	snd_note A_5, 2
	snd_len 10
	snd_off
	snd_note A_4, 12
	snd_note A_5, 2
	snd_len 4
	snd_off
	snd_note A_5, 2
	snd_len 4
	snd_off
	snd_note A_5, 2
	snd_len 10
	snd_off
	snd_note A_5, 2
	snd_len 10
	snd_off
	snd_ret
Mus3C_5_Ch3:
	snd_duty $00
	snd_env2 $20
	snd_wave SndWave08
Trk3C_6AAF:
	snd_loop 8
	snd_call Trk3C_6AE7
	snd_endloop
	snd_loop 3
	snd_call Trk3C_6B4E
	snd_endloop
	snd_call Trk3C_6BB5
	snd_loop 2
	snd_call Trk3C_6C0F
	snd_endloop
	snd_loop 2
	snd_call Trk3C_6C6E
	snd_transpose $F4
	snd_call Trk3C_6C6E
	snd_transpose $00
	snd_endloop
	snd_call Trk3C_6C99
	snd_transpose $FB
	snd_call Trk3C_6C99
	snd_transpose $00
	snd_loop 3
	snd_call Trk3C_6CAB
	snd_endloop
	snd_call Trk3C_6CD2
	snd_jump Trk3C_6AAF
Trk3C_6AE7:
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
	snd_ret
Trk3C_6B4E:
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
	snd_ret
Trk3C_6BB5:
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
	snd_ret
Trk3C_6C0F:
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
	snd_ret
Trk3C_6C6E:
	snd_note D_4, 6
	snd_note D_4, 1
	snd_len 5
	snd_off
	snd_note A_3, 6
	snd_note C_4
	snd_note D_4
	snd_note D_4, 1
	snd_len 5
	snd_off
	snd_note F_4, 6
	snd_note D_4
	snd_note G_4
	snd_note D_4, 1
	snd_len 5
	snd_off
	snd_note F_4, 6
	snd_note D_4, 1
	snd_len 5
	snd_off
	snd_note D_4, 6
	snd_note D_4, 1
	snd_len 5
	snd_off
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note D_4, 1
	snd_len 5
	snd_off
	snd_ret
Trk3C_6C99:
	snd_len 12
	snd_off
	snd_note D_6, 6
	snd_off
	snd_note Cs_6
	snd_off
	snd_note C_6
	snd_off
	snd_note B_5
	snd_off
	snd_note As_5
	snd_off
	snd_note A_5
	snd_off
	snd_note Gs_5
	snd_off
	snd_ret
Trk3C_6CAB:
	snd_len 2
	snd_off
	snd_note D_3, 10
	snd_note D_3, 2
	snd_len 4
	snd_off
	snd_note A_5, 2
	snd_len 4
	snd_off
	snd_note A_5, 2
	snd_len 10
	snd_off
	snd_note A_5, 2
	snd_len 12
	snd_off
	snd_note D_3, 10
	snd_note D_3, 2
	snd_len 4
	snd_off
	snd_note A_5, 2
	snd_len 4
	snd_off
	snd_note A_5, 2
	snd_len 10
	snd_off
	snd_note A_5, 2
	snd_len 10
	snd_off
	snd_ret
Trk3C_6CD2:
	snd_note D_4, 4
	snd_note C_4, 4
	snd_note A_3, 16
	snd_len 1
	snd_off
	snd_note D_4, 4
	snd_note C_4
	snd_note A_3, 15
	snd_note C_4, 6
	snd_len 5
	snd_off
	snd_note D_4, 7
	snd_len 6
	snd_off
	snd_note D_4, 12
	snd_off
	snd_ret
Mus3C_5_Ch4:
	snd_loop 24
	snd_len 12
	snd_drum 6
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 4
	snd_drum 5
	snd_drum 5
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
	snd_endloop
	snd_loop 2
	snd_len 6
	snd_drum 6
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 6
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_endloop
	snd_loop 3
	snd_len 12
	snd_drum 6
	snd_len 6
	snd_drum 8
	snd_drum 8
	snd_len 12
	snd_drum 8
	snd_drum 8
	snd_drum 6
	snd_len 6
	snd_drum 8
	snd_drum 8
	snd_len 12
	snd_drum 8
	snd_drum 8
	snd_endloop
	snd_len 24
	snd_drum 6
	snd_drum 6
	snd_len 12
	snd_drum 6
	snd_drum 4
	snd_len 24
	snd_drum 4
	snd_jump Mus3C_5_Ch4
Mus3C_6:
	db $0F	; channel mask
	dw Mus3C_6_Ch1, Mus3C_6_Ch2, Mus3C_6_Ch3, Mus3C_6_Ch4
Mus3C_6_Ch1:
	snd_tempo 106
	snd_duty $40
	snd_env $70
Trk3C_6D66:
	snd_loop 4
	snd_note D_3, 1
	snd_len 5
	snd_off
	snd_note D_4, 1
	snd_len 5
	snd_off
	snd_note A_4, 6
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 1
	snd_len 11
	snd_off
	snd_note F_4, 6
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note B_4, 1
	snd_len 5
	snd_off
	snd_note B_4, 4
	snd_len 2
	snd_off
	snd_note D_5, 6
	snd_note B_4, 3
	snd_off
	snd_note D_5, 6
	snd_off
	snd_note B_4
	snd_len 6
	snd_off
	snd_off
	snd_note E_4, 1
	snd_len 5
	snd_off
	snd_note B_4, 6
	snd_note G_4, 4
	snd_len 2
	snd_off
	snd_note B_4, 1
	snd_len 11
	snd_off
	snd_note G_4, 6
	snd_note Gs_4, 4
	snd_len 2
	snd_off
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note A_4, 3
	snd_off
	snd_note B_4, 6
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note B_4, 6
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note Fs_4, 6
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_endloop
	snd_len 6
	snd_off
	snd_note D_4, 1
	snd_len 5
	snd_off
	snd_note A_4, 6
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 1
	snd_len 11
	snd_off
	snd_note F_4, 6
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note B_4, 1
	snd_len 5
	snd_off
	snd_note B_4, 4
	snd_len 2
	snd_off
	snd_note D_5, 6
	snd_note B_4, 3
	snd_off
	snd_note D_5, 6
	snd_off
	snd_note B_4
	snd_off
	snd_len 6
	snd_off
	snd_note E_4, 1
	snd_len 5
	snd_off
	snd_note B_4, 6
	snd_note G_4, 4
	snd_len 2
	snd_off
	snd_note B_4, 1
	snd_len 11
	snd_off
	snd_note A_4, 6
	snd_note As_4, 4
	snd_len 2
	snd_off
	snd_note B_4, 1
	snd_len 5
	snd_off
	snd_note B_4, 3
	snd_off
	snd_note D_5, 6
	snd_note B_4, 1
	snd_len 5
	snd_off
	snd_note D_5, 6
	snd_note B_4, 1
	snd_len 5
	snd_off
	snd_note A_4, 6
	snd_note B_4, 1
	snd_len 5
	snd_off
	snd_len 6
	snd_off
	snd_note D_4, 1
	snd_len 5
	snd_off
	snd_note A_4, 6
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note B_4, 1
	snd_len 11
	snd_off
	snd_note F_4, 6
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note Fs_4, 1
	snd_len 5
	snd_off
	snd_note Fs_4, 4
	snd_len 2
	snd_off
	snd_note A_4, 6
	snd_note Fs_4, 3
	snd_off
	snd_note A_4, 6
	snd_off
	snd_note Fs_4
	snd_off
	snd_len 6
	snd_off
	snd_note E_4, 1
	snd_len 5
	snd_off
	snd_note G_4, 6
	snd_note E_4, 4
	snd_len 2
	snd_off
	snd_note B_4, 1
	snd_len 11
	snd_off
	snd_note G_4, 6
	snd_note Gs_4, 4
	snd_len 2
	snd_off
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note A_4, 3
	snd_off
	snd_note E_4, 6
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note E_4, 6
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note E_4, 6
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_call Trk3C_6EAF
	snd_note B_4, 6
	snd_off
	snd_note D_5, 4
	snd_len 2
	snd_off
	snd_note B_4, 5
	snd_len 1
	snd_off
	snd_note A_4, 4
	snd_len 2
	snd_off
	snd_note A_4, 6
	snd_off
	snd_note B_4, 5
	snd_len 1
	snd_off
	snd_note Fs_4, 6
	snd_len 42
	snd_off
	snd_call Trk3C_6EAF
	snd_note B_4, 5
	snd_len 7
	snd_off
	snd_note A_4, 4
	snd_len 2
	snd_off
	snd_note B_4, 4
	snd_len 2
	snd_off
	snd_note D_5, 4
	snd_len 2
	snd_off
	snd_note D_5, 5
	snd_len 7
	snd_off
	snd_note E_5, 4
	snd_len 2
	snd_off
	snd_note D_5, 5
	snd_len 43
	snd_off
	snd_jump Trk3C_6D66
Trk3C_6EAF:
	snd_note A_4, 5
	snd_len 7
	snd_off
	snd_note A_4, 3
	snd_off
	snd_note A_4, 4
	snd_len 2
	snd_off
	snd_note Fs_4, 3
	snd_off
	snd_note Fs_4, 4
	snd_len 8
	snd_off
	snd_note A_4, 4
	snd_len 2
	snd_off
	snd_note B_4, 6
	snd_len 42
	snd_off
	snd_ret
Mus3C_6_Ch2:
	snd_duty $80
	snd_env $80
Trk3C_6ECE:
	snd_loop 2
	snd_call Trk3C_7014
	snd_note B_5, 5
	snd_len 7
	snd_off
	snd_note D_6, 5
	snd_len 1
	snd_off
	snd_note B_5, 5
	snd_len 1
	snd_off
	snd_note A_5, 3
	snd_off
	snd_note A_5, 5
	snd_len 7
	snd_off
	snd_note B_5, 5
	snd_len 1
	snd_off
	snd_note Fs_5, 6
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 3
	snd_off
	snd_note Fs_4
	snd_off
	snd_note F_4
	snd_off
	snd_note Fs_4
	snd_off
	snd_call Trk3C_7014
	snd_note B_5, 4
	snd_len 8
	snd_off
	snd_note A_5, 5
	snd_len 1
	snd_off
	snd_note B_5, 4
	snd_len 2
	snd_off
	snd_note D_6, 4
	snd_len 2
	snd_off
	snd_note D_6, 5
	snd_len 7
	snd_off
	snd_note E_6, 4
	snd_len 2
	snd_off
	snd_note D_6, 6
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 3
	snd_off
	snd_note Fs_4
	snd_off
	snd_note F_4
	snd_off
	snd_note Fs_4
	snd_off
	snd_endloop
	snd_note D_6, 5
	snd_len 1
	snd_off
	snd_note D_6, 5
	snd_len 7
	snd_off
	snd_note D_6, 6
	snd_note B_5, 4
	snd_len 8
	snd_off
	snd_note D_6, 5
	snd_len 7
	snd_off
	snd_note E_6, 6
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note B_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note B_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note E_6, 5
	snd_len 7
	snd_off
	snd_note D_6, 5
	snd_len 1
	snd_off
	snd_note E_6, 5
	snd_len 1
	snd_off
	snd_note Fs_6, 3
	snd_off
	snd_note Fs_6, 5
	snd_len 7
	snd_off
	snd_note D_6, 5
	snd_len 1
	snd_off
	snd_note A_5, 6
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 3
	snd_off
	snd_note Fs_4
	snd_off
	snd_note F_4
	snd_off
	snd_note Fs_4
	snd_off
	snd_note B_5, 5
	snd_len 7
	snd_off
	snd_note B_5, 5
	snd_len 1
	snd_off
	snd_note B_5, 6
	snd_note As_5, 5
	snd_len 1
	snd_off
	snd_note As_5, 5
	snd_len 7
	snd_off
	snd_note As_5, 6
	snd_note B_5, 5
	snd_len 1
	snd_off
	snd_note B_5, 5
	snd_len 1
	snd_off
	snd_note Fs_5, 5
	snd_len 1
	snd_off
	snd_note B_5, 6
	snd_note D_6, 5
	snd_len 7
	snd_off
	snd_note B_5, 5
	snd_len 1
	snd_off
	snd_note D_6, 6
	snd_note Fs_6, 4
	snd_len 8
	snd_off
	snd_note A_6, 5
	snd_len 1
	snd_off
	snd_note Fs_6, 4
	snd_len 2
	snd_off
	snd_note E_6, 5
	snd_len 1
	snd_off
	snd_note D_6, 5
	snd_len 1
	snd_off
	snd_note B_5, 5
	snd_len 1
	snd_off
	snd_note Fs_6, 5
	snd_len 1
	snd_off
	snd_note E_6, 6
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 3
	snd_off
	snd_note Fs_4
	snd_off
	snd_note F_4
	snd_off
	snd_note Fs_4
	snd_off
	snd_loop 2
	snd_len 54
	snd_off
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note B_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 2
	snd_len 16
	snd_off
	snd_note A_4, 3
	snd_len 63
	snd_off
	snd_note Fs_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note Fs_4, 2
	snd_len 10
	snd_off
	snd_note Fs_4, 3
	snd_off
	snd_note F_4
	snd_off
	snd_note Fs_4
	snd_off
	snd_endloop
	snd_jump Trk3C_6ECE
Trk3C_7014:
	snd_note D_5, 5
	snd_len 7
	snd_off
	snd_note D_5, 5
	snd_len 1
	snd_off
	snd_note E_5, 6
	snd_note Fs_5, 4
	snd_len 2
	snd_off
	snd_note Fs_5, 5
	snd_len 7
	snd_off
	snd_note A_5, 4
	snd_len 2
	snd_off
	snd_note B_5, 6
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note B_4, 2
	snd_len 4
	snd_off
	snd_note A_4, 2
	snd_len 4
	snd_off
	snd_note B_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_ret
Mus3C_6_Ch3:
	snd_duty $00
	snd_env2 $20
	snd_wave SndWave0B
Trk3C_7048:
	snd_loop 4
	snd_note D_3, 4
	snd_len 2
	snd_off
	snd_note D_4, 6
	snd_off
	snd_note A_3, 5
	snd_len 1
	snd_off
	snd_note B_3, 5
	snd_len 7
	snd_off
	snd_note D_3, 1
	snd_note D_4, 5
	snd_len 6
	snd_off
	snd_note E_4, 4
	snd_len 2
	snd_off
	snd_note E_4, 6
	snd_off
	snd_note A_3, 4
	snd_len 2
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note A_4
	snd_len 5
	snd_off
	snd_note D_3, 1
	snd_note D_4, 5
	snd_len 6
	snd_off
	snd_note E_3, 3
	snd_off
	snd_note E_4, 5
	snd_len 7
	snd_off
	snd_note A_3, 4
	snd_len 2
	snd_off
	snd_note B_3, 5
	snd_len 7
	snd_off
	snd_note E_3, 1
	snd_note A_3, 5
	snd_len 6
	snd_off
	snd_note D_4, 3
	snd_off
	snd_note D_4, 5
	snd_len 7
	snd_off
	snd_note B_3, 4
	snd_len 2
	snd_off
	snd_note A_3, 4
	snd_len 2
	snd_off
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note D_3, 1
	snd_note Fs_3, 4
	snd_len 7
	snd_off
	snd_endloop
	snd_note B_3, 4
	snd_len 2
	snd_off
	snd_note B_3, 6
	snd_off
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_note F_3, 5
	snd_len 7
	snd_off
	snd_note D_3, 1
	snd_note Fs_3, 5
	snd_len 6
	snd_off
	snd_note B_3, 4
	snd_len 2
	snd_off
	snd_note B_3, 6
	snd_off
	snd_note Fs_3, 4
	snd_len 2
	snd_off
	snd_note F_3, 5
	snd_len 1
	snd_off
	snd_note A_4
	snd_len 5
	snd_off
	snd_note D_3, 1
	snd_note Fs_3, 5
	snd_note F_3
	snd_len 1
	snd_off
	snd_note E_3, 3
	snd_off
	snd_note E_3, 5
	snd_len 7
	snd_off
	snd_note A_3, 4
	snd_len 2
	snd_off
	snd_note B_3, 5
	snd_len 7
	snd_off
	snd_note D_3, 1
	snd_note Fs_3, 5
	snd_len 6
	snd_off
	snd_note G_3, 3
	snd_off
	snd_note G_3, 5
	snd_len 7
	snd_off
	snd_note F_3, 4
	snd_len 2
	snd_off
	snd_note E_3, 4
	snd_len 2
	snd_off
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note D_3, 1
	snd_note Fs_3, 4
	snd_len 7
	snd_off
	snd_note B_3, 4
	snd_len 2
	snd_off
	snd_note B_3, 6
	snd_off
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_note F_3, 5
	snd_len 7
	snd_off
	snd_note D_3, 1
	snd_note Fs_3, 5
	snd_len 6
	snd_off
	snd_note B_3, 4
	snd_len 2
	snd_off
	snd_note B_3, 6
	snd_off
	snd_note Fs_3, 4
	snd_len 2
	snd_off
	snd_note F_3, 5
	snd_len 1
	snd_off
	snd_note A_4
	snd_len 5
	snd_off
	snd_note D_3, 1
	snd_note Fs_3, 5
	snd_note F_3
	snd_len 1
	snd_off
	snd_note E_3, 3
	snd_off
	snd_note E_3, 5
	snd_len 7
	snd_off
	snd_note A_3, 4
	snd_len 2
	snd_off
	snd_note B_3, 5
	snd_len 7
	snd_off
	snd_note D_3, 1
	snd_note Fs_3, 5
	snd_len 6
	snd_off
	snd_note E_4, 3
	snd_off
	snd_note E_4, 5
	snd_len 7
	snd_off
	snd_note D_4, 4
	snd_len 2
	snd_off
	snd_note B_3, 4
	snd_len 2
	snd_off
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note D_3, 1
	snd_note A_3, 4
	snd_len 7
	snd_off
	snd_loop 2
	snd_note D_4, 4
	snd_len 2
	snd_off
	snd_note D_4, 6
	snd_off
	snd_note A_3, 5
	snd_len 1
	snd_off
	snd_note B_3, 5
	snd_len 7
	snd_off
	snd_note D_3, 1
	snd_note D_4, 5
	snd_len 6
	snd_off
	snd_note E_4, 4
	snd_len 26
	snd_off
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note D_3, 1
	snd_len 11
	snd_off
	snd_note E_4, 3
	snd_off
	snd_note E_4, 5
	snd_len 7
	snd_off
	snd_note A_3, 4
	snd_len 2
	snd_off
	snd_note B_3, 5
	snd_len 7
	snd_off
	snd_note E_3, 1
	snd_note A_3, 5
	snd_len 6
	snd_off
	snd_note D_4, 3
	snd_len 27
	snd_off
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note D_5, 12
	snd_endloop
	snd_jump Trk3C_7048
Mus3C_6_Ch4:
	snd_loop 8
	snd_len 12
	snd_drum 6
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_len 6
	snd_off
	snd_drum 6
	snd_drum 0
	snd_drum 6
	snd_len 12
	snd_drum 9
	snd_drum 0
	snd_endloop
	snd_loop 4
	snd_len 12
	snd_drum 6
	snd_drum 2
	snd_drum 4
	snd_drum 2
	snd_len 6
	snd_off
	snd_drum 6
	snd_drum 2
	snd_drum 6
	snd_len 12
	snd_drum 2
	snd_drum 3
	snd_endloop
	snd_loop 4
	snd_drum 6
	snd_drum 0
	snd_off
	snd_drum 0
	snd_off
	snd_drum 0
	snd_off
	snd_drum 2
	snd_endloop
	snd_jump Mus3C_6_Ch4
Mus3C_7:
	db $0F	; channel mask
	dw Mus3C_7_Ch1, Mus3C_7_Ch2, Mus3C_7_Ch3, Mus3C_7_Ch4
Mus3C_7_Ch2:
	snd_tempo 140
	snd_duty $80
	snd_env $50
	snd_pitchenv SndPitchEnv_4A04
Trk3C_71E4:
	snd_len 96
	snd_off
	snd_len 48
	snd_off
	snd_note D_5, 12
	snd_note A_5, 2
	snd_note D_6
	snd_len 8
	snd_off
	snd_note D_5, 12
	snd_note A_5, 2
	snd_note D_6
	snd_len 8
	snd_off
	snd_jump Trk3C_71E4
Mus3C_7_Ch1:
	snd_end
Mus3C_7_Ch3:
	snd_duty $00
	snd_env2 $20
	snd_wave SndWave08
Trk3C_7201:
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
	snd_jump Trk3C_7201
Mus3C_7_Ch4:
	snd_len 12
	snd_drum 6
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 4
	snd_drum 5
	snd_drum 5
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 1
	snd_drum 3
	snd_jump Mus3C_7_Ch4
Mus3C_8:
	db $0F	; channel mask
	dw Mus3C_8_Ch1, Mus3C_8_Ch2, Mus3C_8_Ch3, Mus3C_8_Ch4
Mus3C_8_Ch1:
	snd_tempo 135
	snd_duty $80
	snd_pitchenv SndPitchEnv_49A8
Trk3C_728D:
	snd_env $60
	snd_call Trk3C_72DC
	snd_call Trk3C_72FB
	snd_call Trk3C_72DC
	snd_call Trk3C_7319
	snd_call Trk3C_7319
	snd_call Trk3C_7319
	snd_call Trk3C_7319
	snd_call Trk3C_72DC
	snd_transpose $0C
	snd_call Trk3C_748C
	snd_call Trk3C_748C
	snd_env $40
	snd_transpose $00
	snd_call Trk3C_748C
	snd_call Trk3C_748C
	snd_transpose $0C
	snd_call Trk3C_748C
	snd_call Trk3C_748C
	snd_transpose $00
	snd_note G_5, 96
	snd_len 3
	snd_off
	snd_note Cs_5, 6
	snd_note Cs_5
	snd_note C_5
	snd_note C_5
	snd_note B_4
	snd_note B_4
	snd_note As_4
	snd_note As_4
	snd_note A_4
	snd_note A_4
	snd_note Gs_4
	snd_note Gs_4
	snd_note G_4
	snd_note G_4
	snd_note Fs_4
	snd_note Fs_4, 3
	snd_jump Trk3C_728D
Trk3C_72DC:
	snd_note D_5, 12
	snd_note D_6, 1
	snd_len 5
	snd_off
	snd_note D_5, 6
	snd_note A_4, 5
	snd_len 7
	snd_off
	snd_note B_4, 5
	snd_len 7
	snd_off
	snd_note D_5, 12
	snd_note D_6, 1
	snd_len 11
	snd_off
	snd_note Fs_5, 5
	snd_len 7
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_ret
Trk3C_72FB:
	snd_note B_4, 12
	snd_note B_5, 1
	snd_len 5
	snd_off
	snd_note B_4, 6
	snd_note Fs_4, 7
	snd_len 5
	snd_off
	snd_note A_4
	snd_len 7
	snd_off
	snd_note B_4, 12
	snd_note B_5, 1
	snd_len 11
	snd_off
	snd_note D_5, 5
	snd_len 7
	snd_off
	snd_note B_4, 4
	snd_len 8
	snd_off
	snd_ret
Trk3C_7319:
	snd_note B_4, 12
	snd_note B_5, 1
	snd_len 5
	snd_off
	snd_note B_4, 6
	snd_note Fs_4, 7
	snd_len 5
	snd_off
	snd_note A_4
	snd_len 7
	snd_off
	snd_note B_4, 12
	snd_note B_5, 1
	snd_len 11
	snd_off
	snd_note D_5, 5
	snd_len 7
	snd_off
	snd_note B_4, 4
	snd_len 8
	snd_off
	snd_ret
Mus3C_8_Ch2:
	snd_duty $40
	snd_env $80
	snd_pitchenv SndPitchEnv_499B
Trk3C_733E:
	snd_note D_5, 4
	snd_note E_5
	snd_note Fs_5, 60
	snd_len 4
	snd_off
	snd_note Fs_5, 3
	snd_note E_5, 8
	snd_note Fs_5, 5
	snd_note A_5, 9
	snd_note B_5, 92
	snd_len 3
	snd_off
	snd_note B_5
	snd_note A_5, 7
	snd_note B_5, 59
	snd_len 2
	snd_off
	snd_note A_5, 4
	snd_note B_5, 9
	snd_note Fs_5, 4
	snd_note D_5, 9
	snd_note E_5, 93
	snd_len 2
	snd_off
	snd_note E_5, 4
	snd_note D_5
	snd_note E_5, 60
	snd_len 4
	snd_off
	snd_note E_5
	snd_note Fs_5, 5
	snd_note A_5
	snd_note B_5, 12
	snd_note E_5, 91
	snd_len 3
	snd_off
	snd_note A_5, 4
	snd_note B_5, 5
	snd_note A_5, 58
	snd_len 4
	snd_off
	snd_note B_5, 5
	snd_note A_5, 10
	snd_note Fs_5, 4
	snd_note E_5, 9
	snd_note D_5, 82
	snd_len 11
	snd_off
	snd_env $62
	snd_call Trk3C_748C
	snd_call Trk3C_748C
	snd_env $46
	snd_note As_7, 2
	snd_note B_7, 22
	snd_note A_7, 24
	snd_note Fs_7, 12
	snd_note E_7
	snd_note D_7
	snd_note E_7
	snd_note As_6, 2
	snd_note B_6, 24
	snd_note A_6, 23
	snd_note Fs_6, 11
	snd_len 1
	snd_off
	snd_note E_6, 12
	snd_note D_6
	snd_note E_6, 11
	snd_env $62
	snd_call Trk3C_748C
	snd_call Trk3C_748C
	snd_env $66
	snd_note As_7, 2
	snd_note B_7, 22
	snd_note A_7, 24
	snd_note Fs_7, 12
	snd_note E_7
	snd_note D_7
	snd_note E_7, 7
	snd_len 5
	snd_off
	snd_env $82
	snd_duty $00
	snd_note Cs_5, 6
	snd_note Cs_5
	snd_note C_5
	snd_note C_5
	snd_note B_4
	snd_note B_4
	snd_note As_4
	snd_note As_4
	snd_note A_4
	snd_note A_4
	snd_note Gs_4
	snd_note Gs_4
	snd_note G_4
	snd_note G_4
	snd_note Fs_4
	snd_note Fs_4
	snd_env $60
	snd_duty $80
	snd_jump Trk3C_733E
Mus3C_8_Ch3:
	snd_duty $00
	snd_env2 $20
	snd_wave SndWave00
Trk3C_73E8:
	snd_pitchenv SndPitchEnv_4A1B
	snd_call Trk3C_7426
	snd_call Trk3C_7441
	snd_call Trk3C_7426
	snd_transpose $F9
	snd_call Trk3C_7441
	snd_call Trk3C_7441
	snd_call Trk3C_7441
	snd_transpose $00
	snd_call Trk3C_745C
	snd_call Trk3C_7426
	snd_call Trk3C_7478
	snd_call Trk3C_748C
	snd_call Trk3C_748C
	snd_call Trk3C_7478
	snd_transpose $F9
	snd_call Trk3C_748C
	snd_transpose $00
	snd_note A_3, 12
	snd_len 60
	snd_off
	snd_pitchenv SndPitchEnv_4ABD
	snd_note A_3, 24
	snd_jump Trk3C_73E8
Trk3C_7426:
	snd_note D_4, 12
	snd_note A_4, 4
	snd_len 8
	snd_off
	snd_note A_3, 12
	snd_note A_4, 4
	snd_len 8
	snd_off
	snd_note D_4, 5
	snd_len 7
	snd_off
	snd_note D_4, 6
	snd_note B_3
	snd_note A_3, 5
	snd_len 7
	snd_off
	snd_note D_4, 6
	snd_off
	snd_ret
Trk3C_7441:
	snd_note B_3, 12
	snd_note Fs_4, 4
	snd_len 8
	snd_off
	snd_note Fs_3, 12
	snd_note Fs_4, 5
	snd_len 7
	snd_off
	snd_note B_3, 4
	snd_len 8
	snd_off
	snd_note B_3, 6
	snd_note A_3
	snd_note Fs_3, 4
	snd_len 8
	snd_off
	snd_note A_3, 6
	snd_off
	snd_ret
Trk3C_745C:
	snd_note E_3, 12
	snd_note B_3, 4
	snd_len 8
	snd_off
	snd_note B_2, 12
	snd_note B_3, 4
	snd_len 8
	snd_off
	snd_note E_3, 5
	snd_len 7
	snd_off
	snd_note E_3, 6
	snd_note D_3
	snd_note B_2, 5
	snd_len 7
	snd_off
	snd_note E_3, 5
	snd_len 7
	snd_off
	snd_ret
Trk3C_7478:
	snd_note E_3, 17
	snd_len 31
	snd_off
	snd_note E_3, 13
	snd_len 35
	snd_off
	snd_note E_3, 11
	snd_len 13
	snd_off
	snd_note E_3, 12
	snd_off
	snd_note E_3, 13
	snd_len 35
	snd_off
	snd_ret
Trk3C_748C:
	snd_loop 2
	snd_note B_3, 6
	snd_off
	snd_note B_3
	snd_note A_3
	snd_note Fs_3, 4
	snd_len 8
	snd_off
	snd_note A_3, 5
	snd_len 7
	snd_off
	snd_endloop
	snd_ret
Mus3C_8_Ch4:
	snd_loop 8
	snd_len 12
	snd_drum 5
	snd_drum 2
	snd_drum 4
	snd_drum 2
	snd_drum 5
	snd_drum 2
	snd_drum 4
	snd_drum 2
	snd_endloop
	snd_call Trk3C_74BF
	snd_call Trk3C_74D9
	snd_call Trk3C_74D9
	snd_call Trk3C_74BF
	snd_call Trk3C_74D9
	snd_len 72
	snd_drum 4
	snd_len 24
	snd_drum 9
	snd_jump Mus3C_8_Ch4
Trk3C_74BF:
	snd_loop 2
	snd_len 12
	snd_drum 6
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_drum 0
	snd_endloop
	snd_drum 6
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 6
	snd_drum 4
	snd_drum 8
	snd_len 6
	snd_drum 3
	snd_drum 3
	snd_len 12
	snd_drum 3
	snd_drum 3
	snd_ret
Trk3C_74D9:
	snd_len 12
	snd_drum 6
	snd_drum 0
	snd_drum 4
	snd_drum 4
	snd_drum 6
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_ret
Mus3C_9:
	db $0F	; channel mask
	dw Mus3C_9_Ch1, Mus3C_9_Ch2, Mus3C_9_Ch3, Mus3C_9_Ch4
Mus3C_9_Ch1:
	snd_tempo 73
	snd_duty $80
	snd_env $60
Trk3C_74F2:
	snd_len 12
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note E_5, 3
	snd_len 9
	snd_off
	snd_note E_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note E_5, 3
	snd_len 9
	snd_off
	snd_note E_5, 3
	snd_len 21
	snd_off
	snd_note E_5, 3
	snd_len 9
	snd_off
	snd_note E_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 21
	snd_off
	snd_note Cs_5, 3
	snd_len 9
	snd_off
	snd_note Cs_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note A_5, 3
	snd_off
	snd_note A_5
	snd_off
	snd_note As_5
	snd_off
	snd_note A_5
	snd_off
	snd_note F_5
	snd_off
	snd_note E_5
	snd_off
	snd_jump Trk3C_74F2
Mus3C_9_Ch2:
	snd_duty $40
	snd_env $0D
	snd_pitchenv SndPitchEnv_498E
Trk3C_7603:
	snd_note A_5, 24
	snd_note As_5, 12
	snd_note A_5
	snd_note F_5
	snd_note A_5
	snd_note D_6, 24
	snd_note F_6, 12
	snd_note E_6, 36
	snd_note F_6, 12
	snd_note E_6
	snd_note D_6
	snd_note As_5
	snd_note D_6
	snd_note As_5
	snd_note A_5, 72
	snd_note As_5, 24
	snd_note A_5, 12
	snd_note As_5, 24
	snd_note D_6, 12
	snd_note E_6
	snd_note D_6
	snd_note As_5
	snd_note A_5, 24
	snd_len 12
	snd_off
	snd_note F_5, 24
	snd_note A_5, 12
	snd_note E_5
	snd_note F_5
	snd_note E_5
	snd_note D_5, 60
	snd_len 12
	snd_off
	snd_note E_6, 24
	snd_note F_6, 12
	snd_note E_6, 24
	snd_note D_6, 12
	snd_note E_6
	snd_note D_6
	snd_note As_5
	snd_note A_5, 24
	snd_len 12
	snd_off
	snd_note G_5
	snd_note A_5
	snd_note As_5
	snd_note D_6, 24
	snd_note F_6, 12
	snd_note E_6, 60
	snd_len 12
	snd_off
	snd_note F_6, 24
	snd_note E_6, 12
	snd_note D_6, 24
	snd_len 12
	snd_off
	snd_note E_6
	snd_note D_6
	snd_note As_5
	snd_note A_5, 24
	snd_len 12
	snd_off
	snd_note F_5, 24
	snd_note A_5, 12
	snd_note E_5
	snd_note F_5
	snd_note E_5
	snd_note D_5, 60
	snd_len 12
	snd_off
	snd_jump Trk3C_7603
Mus3C_9_Ch3:
	snd_duty $00
	snd_env2 $20
	snd_wave SndWave0E
Trk3C_7671:
	snd_note D_4, 12
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_3, 12
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note D_4, 12
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_3, 12
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note D_4, 12
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_3, 12
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note D_4, 12
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_3, 12
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note G_4, 12
	snd_note As_4, 3
	snd_len 9
	snd_off
	snd_note As_4, 3
	snd_len 9
	snd_off
	snd_note D_4, 12
	snd_note As_4, 3
	snd_len 9
	snd_off
	snd_note As_4, 3
	snd_len 9
	snd_off
	snd_note G_4, 12
	snd_note As_4, 3
	snd_len 9
	snd_off
	snd_note As_4, 3
	snd_len 9
	snd_off
	snd_note D_4, 12
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note D_4, 12
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_3, 12
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note D_4, 12
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_3, 12
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note G_4, 12
	snd_note As_4, 3
	snd_len 9
	snd_off
	snd_note As_4, 3
	snd_len 9
	snd_off
	snd_note D_4, 12
	snd_note As_4, 3
	snd_len 9
	snd_off
	snd_note As_4, 3
	snd_len 9
	snd_off
	snd_note G_4, 12
	snd_note As_4, 3
	snd_len 9
	snd_off
	snd_note As_4, 3
	snd_len 9
	snd_off
	snd_note D_4, 12
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note G_4, 12
	snd_note As_4, 3
	snd_len 9
	snd_off
	snd_note As_4, 3
	snd_len 9
	snd_off
	snd_note D_4, 12
	snd_note As_4, 3
	snd_len 9
	snd_off
	snd_note As_4, 3
	snd_len 9
	snd_off
	snd_note E_4, 12
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_3, 12
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note D_4, 12
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_3, 12
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note As_3, 12
	snd_note G_4, 6
	snd_off
	snd_note G_4
	snd_off
	snd_note D_4, 12
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note D_4, 12
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_3, 12
	snd_note E_4, 6
	snd_off
	snd_note E_4
	snd_off
	snd_note D_4, 12
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_3, 12
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 3
	snd_len 9
	snd_off
	snd_jump Trk3C_7671
Mus3C_9_Ch4:
	snd_len 12
	snd_drum 5
	snd_drum 3
	snd_drum 3
	snd_jump Mus3C_9_Ch4
Mus3C_10:
	db $0F	; channel mask
	dw Mus3C_10_Ch1, Mus3C_10_Ch2, Mus3C_10_Ch3, Mus3C_10_Ch4
Mus3C_10_Ch2:
	snd_tempo 60
Trk3C_77C0:
	snd_duty $80
	snd_env $60
	snd_note D_5, 2
	snd_len 10
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note D_5, 2
	snd_len 4
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note G_5, 2
	snd_len 4
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note G_5, 2
	snd_len 4
	snd_off
	snd_note As_5, 2
	snd_len 10
	snd_off
	snd_note D_6, 2
	snd_len 10
	snd_off
	snd_note F_5, 24
	snd_duty $40
	snd_env $82
	snd_note D_6, 6
	snd_off
	snd_note F_6
	snd_note D_6
	snd_note F_6
	snd_note G_6
	snd_note F_6
	snd_note G_6
	snd_note As_6
	snd_note As_6
	snd_note G_6
	snd_note F_6
	snd_note G_6
	snd_len 18
	snd_off
	snd_jump Trk3C_77C0
Mus3C_10_Ch1:
	snd_len 2
	snd_off
Trk3C_7803:
	snd_duty $80
	snd_env $30
	snd_note D_5, 2
	snd_len 10
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note D_5, 2
	snd_len 4
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note G_5, 2
	snd_len 4
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note G_5, 2
	snd_len 4
	snd_off
	snd_note As_5, 2
	snd_len 10
	snd_off
	snd_note D_6, 2
	snd_len 10
	snd_off
	snd_note F_5, 24
	snd_duty $00
	snd_env $32
	snd_note D_6, 6
	snd_off
	snd_note F_6
	snd_note D_6
	snd_note F_6
	snd_note G_6
	snd_note F_6
	snd_note G_6
	snd_note As_6
	snd_note As_6
	snd_note G_6
	snd_note F_6
	snd_note G_6
	snd_len 18
	snd_off
	snd_jump Trk3C_7803
Mus3C_10_Ch3:
	snd_duty $00
	snd_env2 $20
	snd_wave SndWave07
Trk3C_784B:
	snd_note As_3, 4
	snd_len 14
	snd_off
	snd_note F_4, 3
	snd_off
	snd_note G_4
	snd_len 9
	snd_off
	snd_note F_4, 3
	snd_len 9
	snd_off
	snd_note As_3, 3
	snd_off
	snd_note As_3, 4
	snd_len 8
	snd_off
	snd_note F_4, 3
	snd_off
	snd_note G_4
	snd_len 9
	snd_off
	snd_note F_4, 3
	snd_len 9
	snd_off
	snd_note C_4, 4
	snd_len 14
	snd_off
	snd_note F_4, 3
	snd_off
	snd_note G_4
	snd_len 9
	snd_off
	snd_note F_4, 3
	snd_len 9
	snd_off
	snd_note C_4, 3
	snd_off
	snd_note C_4, 4
	snd_len 8
	snd_off
	snd_note F_4, 3
	snd_off
	snd_note G_4
	snd_len 9
	snd_off
	snd_note F_4, 3
	snd_len 9
	snd_off
	snd_jump Trk3C_784B
Mus3C_10_Ch4:
	snd_len 12
	snd_drum 6
	snd_len 6
	snd_drum 1
	snd_drum 3
	snd_len 12
	snd_drum 3
	snd_drum 8
	snd_jump Mus3C_10_Ch4
Mus3C_11:
	db $0F	; channel mask
	dw Mus3C_11_Ch1, Mus3C_11_Ch2, Mus3C_11_Ch3, Mus3C_11_Ch4
Mus3C_11_Ch1:
	snd_tempo 138
	snd_duty $00
	snd_env $80
	snd_pitchenv SndPitchEnv_49A8
Trk3C_78A9:
	snd_note B_5, 6
	snd_off
	snd_note A_5
	snd_off
	snd_note B_5
	snd_off
	snd_note A_5
	snd_len 30
	snd_off
	snd_note Fs_5, 4
	snd_len 2
	snd_off
	snd_note Fs_5, 6
	snd_off
	snd_note A_5
	snd_note B_5
	snd_off
	snd_note A_5
	snd_off
	snd_note B_5
	snd_off
	snd_note A_5
	snd_len 54
	snd_off
	snd_note B_5, 6
	snd_off
	snd_note A_5
	snd_off
	snd_note B_5
	snd_off
	snd_note A_5
	snd_len 30
	snd_off
	snd_note Fs_5, 6
	snd_note A_5
	snd_off
	snd_note B_5
	snd_note D_6
	snd_off
	snd_note B_5
	snd_off
	snd_note Fs_6
	snd_off
	snd_note B_5
	snd_len 54
	snd_off
	snd_len 96
	snd_off
	snd_off
	snd_off
	snd_off
	snd_off
	snd_off
	snd_off
	snd_off
	snd_off
	snd_off
	snd_note B_4, 90
	snd_note A_4, 6
	snd_note B_4, 96
	snd_note B_4, 90
	snd_note A_4, 6
	snd_note B_4, 96
	snd_note B_5, 6
	snd_off
	snd_note A_5
	snd_off
	snd_note B_5
	snd_off
	snd_note Gs_5
	snd_len 30
	snd_off
	snd_note Gs_5, 4
	snd_len 2
	snd_off
	snd_note Gs_5, 6
	snd_off
	snd_note A_5
	snd_note B_5
	snd_off
	snd_note A_5
	snd_off
	snd_note B_5
	snd_off
	snd_note Gs_5
	snd_len 54
	snd_off
	snd_note B_5, 6
	snd_off
	snd_note A_5
	snd_off
	snd_note B_5
	snd_off
	snd_note Gs_5
	snd_len 30
	snd_off
	snd_note B_5, 4
	snd_len 2
	snd_off
	snd_note B_5, 6
	snd_off
	snd_note Cs_6
	snd_note D_6
	snd_off
	snd_note B_5
	snd_off
	snd_note F_6
	snd_off
	snd_note B_5
	snd_len 54
	snd_off
	snd_note Fs_5, 11
	snd_len 1
	snd_off
	snd_note Ds_5, 5
	snd_len 1
	snd_off
	snd_note Ds_5, 6
	snd_off
	snd_note Fs_5
	snd_off
	snd_note Gs_5, 78
	snd_len 24
	snd_off
	snd_note Fs_5, 11
	snd_len 1
	snd_off
	snd_note Ds_5, 6
	snd_note Fs_5
	snd_off
	snd_note Ds_5
	snd_len 4
	snd_off
	snd_note Cs_5, 80
	snd_len 24
	snd_off
	snd_note Fs_5, 11
	snd_len 1
	snd_off
	snd_note Ds_5, 5
	snd_len 1
	snd_off
	snd_note Ds_5, 6
	snd_off
	snd_note Fs_5
	snd_off
	snd_note Gs_5, 78
	snd_len 24
	snd_off
	snd_note B_5, 12
	snd_note Gs_5, 6
	snd_note B_5
	snd_off
	snd_note Ds_6
	snd_off
	snd_note E_6, 78
	snd_len 24
	snd_off
	snd_env $87
	snd_len 76
	snd_off
	snd_loop 11
	snd_note E_6, 96
	snd_len 36
	snd_off
	snd_endloop
	snd_note E_6, 96
	snd_len 96
	snd_off
	snd_len 8
	snd_off
	snd_env $80
	snd_note Cs_4, 6
	snd_note D_4
	snd_note Cs_4
	snd_note D_4
	snd_note Cs_4
	snd_note D_4
	snd_note E_4
	snd_note F_4
	snd_note G_4
	snd_note Gs_4
	snd_note G_4
	snd_note Gs_4
	snd_note G_4
	snd_note F_4
	snd_note E_4
	snd_note D_4
	snd_note G_4
	snd_note Gs_4
	snd_note As_4
	snd_note B_4
	snd_note Cs_5
	snd_note D_5
	snd_note E_5
	snd_note F_5
	snd_note G_5
	snd_note Gs_5
	snd_note A_5
	snd_note As_5
	snd_note B_5
	snd_note C_6
	snd_note Cs_6, 4
	snd_note D_6
	snd_note Ds_6, 2
	snd_note E_6
	snd_note F_6, 96
	snd_note F_6
	snd_env $87
	snd_note F_6
	snd_env $80
	snd_note Cs_4, 5
	snd_len 7
	snd_off
	snd_note Cs_4, 4
	snd_len 2
	snd_off
	snd_note Gs_4, 6
	snd_note Cs_5, 5
	snd_len 1
	snd_off
	snd_note B_4, 3
	snd_off
	snd_note Cs_5, 6
	snd_note B_4
	snd_note Cs_3, 6
	snd_note G_3
	snd_note Cs_3
	snd_note G_3
	snd_note C_3
	snd_note Fs_3
	snd_note C_3
	snd_note Fs_3
	snd_jump Trk3C_78A9
Mus3C_11_Ch2:
	snd_duty $80
	snd_env $80
	snd_pitchenv SndPitchEnv_499B
Trk3C_79CD:
	snd_env $60
	snd_note B_4, 90
	snd_note A_4, 6
	snd_note B_4, 96
	snd_note D_6, 6
	snd_off
	snd_note B_5
	snd_off
	snd_note D_6
	snd_off
	snd_note B_5
	snd_len 30
	snd_off
	snd_note Fs_5, 6
	snd_note A_5
	snd_off
	snd_note B_5
	snd_note D_6
	snd_off
	snd_note B_5
	snd_off
	snd_note Fs_6
	snd_off
	snd_note B_5, 60
	snd_call Trk3C_7B08
	snd_note A_5, 12
	snd_note Fs_5, 6
	snd_note A_5
	snd_off
	snd_note Fs_5
	snd_off
	snd_note E_5, 96
	snd_note E_5, 2
	snd_len 4
	snd_off
	snd_call Trk3C_7B08
	snd_note D_6, 12
	snd_note B_5, 6
	snd_note D_6
	snd_off
	snd_note Fs_6
	snd_off
	snd_note E_6, 78
	snd_len 24
	snd_off
	snd_note Fs_6, 4
	snd_note E_6
	snd_note Fs_6, 58
	snd_note A_6, 18
	snd_note B_6, 12
	snd_note Fs_6, 15
	snd_note E_6, 17
	snd_note D_6, 16
	snd_note B_5, 22
	snd_note E_6, 2
	snd_note Fs_6, 24
	snd_note E_6, 96
	snd_note E_6, 72
	snd_len 24
	snd_off
	snd_note B_5, 6
	snd_off
	snd_note A_5, 5
	snd_len 7
	snd_off
	snd_note B_5, 6
	snd_off
	snd_note A_5
	snd_len 30
	snd_off
	snd_note Fs_5, 4
	snd_len 2
	snd_off
	snd_note Fs_5, 5
	snd_len 7
	snd_off
	snd_note A_5, 5
	snd_len 1
	snd_off
	snd_note B_5, 5
	snd_len 7
	snd_off
	snd_note A_5, 5
	snd_len 7
	snd_off
	snd_note B_5, 6
	snd_off
	snd_note A_5, 5
	snd_len 55
	snd_off
	snd_note B_5, 6
	snd_off
	snd_note A_5, 5
	snd_len 7
	snd_off
	snd_note B_5, 6
	snd_off
	snd_note A_5
	snd_len 30
	snd_off
	snd_note Fs_5, 4
	snd_len 2
	snd_off
	snd_note A_5, 5
	snd_len 7
	snd_off
	snd_note B_5, 5
	snd_len 1
	snd_off
	snd_note D_6, 5
	snd_len 7
	snd_off
	snd_note B_5, 5
	snd_len 7
	snd_off
	snd_note Fs_6, 6
	snd_off
	snd_note B_5, 5
	snd_len 55
	snd_off
	snd_note B_5, 90
	snd_note A_5, 6
	snd_note B_5, 96
	snd_note Gs_5, 6
	snd_off
	snd_note Fs_5
	snd_off
	snd_note Gs_5
	snd_off
	snd_note F_5
	snd_len 30
	snd_off
	snd_note D_6, 4
	snd_len 2
	snd_off
	snd_note D_6, 6
	snd_off
	snd_note E_6
	snd_note F_6
	snd_off
	snd_note D_6
	snd_off
	snd_note Gs_6
	snd_off
	snd_note D_6
	snd_len 54
	snd_off
	snd_call Trk3C_7B18
	snd_note Fs_6, 12
	snd_note Ds_6, 6
	snd_note Fs_6
	snd_off
	snd_note Ds_6
	snd_off
	snd_note Cs_6, 78
	snd_len 24
	snd_off
	snd_call Trk3C_7B18
	snd_note B_6, 12
	snd_note Gs_6, 6
	snd_note B_6
	snd_off
	snd_note Ds_7
	snd_off
	snd_note E_7, 78
	snd_len 24
	snd_off
	snd_env $50
	snd_loop 4
	snd_call Trk3C_7B28
	snd_endloop
	snd_transpose $02
	snd_loop 4
	snd_call Trk3C_7B28
	snd_endloop
	snd_transpose $04
	snd_loop 8
	snd_call Trk3C_7B28
	snd_endloop
	snd_transpose $05
	snd_loop 3
	snd_call Trk3C_7B28
	snd_endloop
	snd_transpose $00
	snd_note Cs_5
	snd_note D_5
	snd_note E_5
	snd_note F_5
	snd_note G_5
	snd_note Gs_5
	snd_note As_5
	snd_note B_5
	snd_note Cs_6
	snd_note D_6
	snd_note Ds_6
	snd_note E_6
	snd_note F_6
	snd_note Fs_6
	snd_note G_6, 4
	snd_note Gs_6
	snd_note A_6, 2
	snd_note As_6
	snd_note B_6, 96
	snd_note B_6
	snd_env $87
	snd_note B_6
	snd_env $80
	snd_note Cs_5, 6
	snd_off
	snd_note Cs_5
	snd_note Gs_5
	snd_note Cs_6
	snd_note B_5
	snd_note Cs_6
	snd_note B_5
	snd_note Cs_3
	snd_note G_3
	snd_note Cs_3
	snd_note G_3
	snd_note C_3
	snd_note Fs_3
	snd_note C_3
	snd_note Fs_3
	snd_jump Trk3C_79CD
Trk3C_7B08:
	snd_note A_5, 12
	snd_note Fs_5, 5
	snd_len 1
	snd_off
	snd_note Fs_5, 6
	snd_off
	snd_note A_5
	snd_off
	snd_note B_5, 78
	snd_len 24
	snd_off
	snd_ret
Trk3C_7B18:
	snd_note Fs_6, 12
	snd_note Ds_6, 5
	snd_len 1
	snd_off
	snd_note Ds_6, 6
	snd_off
	snd_note Fs_6
	snd_off
	snd_note Gs_6, 78
	snd_len 24
	snd_off
	snd_ret
Trk3C_7B28:
	snd_note Gs_4, 6
	snd_note A_4
	snd_note Gs_4
	snd_note A_4
	snd_note Gs_4
	snd_note A_4
	snd_note B_4
	snd_note C_5
	snd_note D_5
	snd_note Ds_5
	snd_note D_5
	snd_note Ds_5
	snd_note D_5
	snd_note C_5
	snd_note B_4
	snd_note A_4
	snd_ret
Mus3C_11_Ch3:
	snd_duty $00
	snd_env2 $20
	snd_wave SndWave00
Trk3C_7B41:
	snd_loop 8
	snd_call Trk3C_7C5F
	snd_endloop
	snd_call Trk3C_7C5F
	snd_call Trk3C_7C72
	snd_call Trk3C_7C72
	snd_call Trk3C_7C5F
	snd_transpose $F9
	snd_call Trk3C_7C72
	snd_call Trk3C_7C72
	snd_transpose $00
	snd_call Trk3C_7C5F
	snd_call Trk3C_7C72
	snd_call Trk3C_7C72
	snd_call Trk3C_7C5F
	snd_transpose $F9
	snd_call Trk3C_7C72
	snd_call Trk3C_7C72
	snd_transpose $00
	snd_loop 4
	snd_note E_3, 5
	snd_len 7
	snd_off
	snd_note E_3, 6
	snd_note B_3, 4
	snd_len 2
	snd_off
	snd_note Fs_4, 5
	snd_len 7
	snd_off
	snd_note E_4, 5
	snd_len 7
	snd_off
	snd_endloop
	snd_transpose $07
	snd_loop 4
	snd_call Trk3C_7C5F
	snd_endloop
	snd_transpose $00
	snd_loop 8
	snd_call Trk3C_7C5F
	snd_endloop
	snd_transpose $02
	snd_loop 8
	snd_call Trk3C_7C5F
	snd_endloop
	snd_transpose $04
	snd_call Trk3C_7C5F
	snd_transpose $F8
	snd_call Trk3C_7C72
	snd_call Trk3C_7C72
	snd_transpose $04
	snd_call Trk3C_7C5F
	snd_transpose $FD
	snd_call Trk3C_7C72
	snd_call Trk3C_7C72
	snd_transpose $04
	snd_call Trk3C_7C5F
	snd_transpose $F8
	snd_call Trk3C_7C72
	snd_call Trk3C_7C72
	snd_transpose $00
	snd_note Ds_3, 5
	snd_len 7
	snd_off
	snd_note Ds_3, 4
	snd_len 2
	snd_off
	snd_note Gs_3, 6
	snd_note Cs_4, 5
	snd_len 7
	snd_off
	snd_note B_3, 3
	snd_len 9
	snd_off
	snd_transpose $F4
	snd_call Trk3C_7C72
	snd_call Trk3C_7C72
	snd_transpose $00
	snd_loop 4
	snd_call Trk3C_7C80
	snd_endloop
	snd_transpose $02
	snd_loop 4
	snd_call Trk3C_7C80
	snd_endloop
	snd_transpose $04
	snd_loop 4
	snd_call Trk3C_7C80
	snd_endloop
	snd_transpose $F8
	snd_loop 4
	snd_call Trk3C_7C80
	snd_endloop
	snd_transpose $00
	snd_loop 2
	snd_note Cs_3, 11
	snd_len 37
	snd_off
	snd_note Cs_3, 4
	snd_len 20
	snd_off
	snd_note Cs_3, 5
	snd_len 1
	snd_off
	snd_note D_3, 5
	snd_len 7
	snd_off
	snd_note B_2, 4
	snd_len 2
	snd_off
	snd_note Cs_3, 17
	snd_len 31
	snd_off
	snd_note Cs_3, 4
	snd_len 8
	snd_off
	snd_note Cs_3, 5
	snd_len 1
	snd_off
	snd_note G_3, 5
	snd_len 1
	snd_off
	snd_note Cs_4, 5
	snd_len 7
	snd_off
	snd_note B_3, 4
	snd_len 8
	snd_off
	snd_endloop
	snd_loop 6
	snd_note Cs_3, 5
	snd_len 7
	snd_off
	snd_note Cs_3, 4
	snd_len 2
	snd_off
	snd_note Gs_3, 6
	snd_note Cs_4, 5
	snd_len 7
	snd_off
	snd_note B_3, 5
	snd_len 7
	snd_off
	snd_endloop
	snd_note Cs_3, 5
	snd_len 7
	snd_off
	snd_note Cs_3, 6
	snd_note Gs_3
	snd_note Cs_4
	snd_note B_3
	snd_note Cs_4
	snd_note B_3
	snd_note Cs_3
	snd_note G_3
	snd_note Cs_3
	snd_note G_3
	snd_note C_3
	snd_note Fs_3
	snd_note C_3
	snd_note Fs_3
	snd_jump Trk3C_7B41
Trk3C_7C5F:
	snd_note B_2, 5
	snd_len 7
	snd_off
	snd_note B_2, 4
	snd_len 2
	snd_off
	snd_note Fs_3, 6
	snd_note B_3, 5
	snd_len 7
	snd_off
	snd_note A_3, 3
	snd_len 9
	snd_off
	snd_ret
Trk3C_7C72:
	snd_note C_4, 6
	snd_off
	snd_note C_4
	snd_note E_4
	snd_note B_4, 3
	snd_len 9
	snd_off
	snd_note A_4, 4
	snd_len 8
	snd_off
	snd_ret
Trk3C_7C80:
	snd_note Gs_3, 11
	snd_len 37
	snd_off
	snd_note Gs_3, 6
	snd_len 18
	snd_off
	snd_note Gs_3, 5
	snd_len 1
	snd_off
	snd_note A_3, 5
	snd_len 7
	snd_off
	snd_note Fs_3, 4
	snd_len 2
	snd_off
	snd_ret
Mus3C_11_Ch4:
	snd_loop 4
	snd_call Trk3C_7D76
	snd_endloop
	snd_loop 4
	snd_len 12
	snd_drum 5
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 5
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_drum 5
	snd_drum 3
	snd_drum 0
	snd_drum 5
	snd_len 12
	snd_drum 9
	snd_drum 0
	snd_endloop
	snd_loop 2
	snd_len 12
	snd_drum 5
	snd_drum 0
	snd_len 12
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 5
	snd_drum 0
	snd_len 12
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 5
	snd_drum 0
	snd_len 12
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_drum 5
	snd_drum 0
	snd_off
	snd_drum 0
	snd_len 12
	snd_drum 4
	snd_drum 0
	snd_endloop
	snd_loop 8
	snd_call Trk3C_7D76
	snd_endloop
	snd_loop 3
	snd_len 12
	snd_drum 5
	snd_drum 0
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_drum 5
	snd_drum 4
	snd_drum 0
	snd_drum 5
	snd_len 12
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 5
	snd_len 12
	snd_drum 0
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_drum 5
	snd_drum 4
	snd_drum 5
	snd_drum 0
	snd_drum 4
	snd_drum 5
	snd_drum 5
	snd_drum 12
	snd_endloop
	snd_loop 16
	snd_len 24
	snd_drum 2
	snd_len 12
	snd_drum 0
	snd_drum 0
	snd_endloop
	snd_loop 3
	snd_len 12
	snd_drum 5
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_endloop
	snd_len 12
	snd_drum 5
	snd_len 6
	snd_drum 0
	snd_drum 5
	snd_len 12
	snd_drum 9
	snd_drum 0
	snd_loop 3
	snd_len 12
	snd_drum 5
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_endloop
	snd_len 6
	snd_drum 5
	snd_drum 4
	snd_drum 4
	snd_drum 5
	snd_len 12
	snd_drum 4
	snd_drum 9
	snd_loop 3
	snd_drum 5
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_endloop
	snd_drum 5
	snd_len 6
	snd_drum 0
	snd_drum 5
	snd_len 12
	snd_drum 9
	snd_drum 0
	snd_drum 5
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 5
	snd_len 24
	snd_drum 4
	snd_len 12
	snd_drum 5
	snd_drum 2
	snd_drum 4
	snd_len 18
	snd_drum 4
	snd_len 6
	snd_drum 5
	snd_drum 2
	snd_drum 5
	snd_len 12
	snd_drum 2
	snd_drum 2
	snd_drum 5
	snd_loop 4
	snd_call Trk3C_7D76
	snd_endloop
	snd_loop 6
	snd_len 12
	snd_drum 5
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_endloop
	snd_len 12
	snd_drum 5
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_drum 8
	snd_drum 9
	snd_drum 5
	snd_drum 4
	snd_drum 4
	snd_drum 5
	snd_drum 4
	snd_drum 5
	snd_drum 4
	snd_drum 4
	snd_jump Mus3C_11_Ch4
Trk3C_7D76:
	snd_len 12
	snd_drum 5
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 4
	snd_len 6
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_len 6
	snd_drum 5
	snd_drum 0
	snd_drum 5
	snd_len 12
	snd_drum 0
	snd_drum 3
	snd_ret
