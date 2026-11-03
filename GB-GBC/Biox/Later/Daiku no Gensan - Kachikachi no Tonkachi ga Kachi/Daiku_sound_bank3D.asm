; Daiku no Gensan (J) - sound bank $3D ($4000-$7DFC)
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


SECTION "Sound bank $3D", ROMX[$4000], BANK[$3D]

INCLUDE "Daiku_sound_common.inc"


SndMusicTable:
	dw Mus3D_0, Mus3D_1, Mus3D_2, Mus3D_3
	dw Mus3D_4, Mus3D_5, Mus3D_6, Mus3D_7
	dw Mus3D_8, Mus3D_9, Mus3D_10, Mus3D_11
	dw Mus3D_12, Mus3D_13
Mus3D_0:
	db $0F	; channel mask
	dw SndNullTrack, Mus3D_0_Ch2, Mus3D_0_Ch3, Mus3D_0_Ch4
Mus3D_0_Ch2:
	snd_tempo 135
	snd_octenv SndOctEnv_4B06
Trk3D_533B:
	snd_duty $40
	snd_env $0F
	snd_note A_5, 48
	snd_env $67
	snd_note A_5
	snd_env $0F
	snd_note Gs_5
	snd_env $67
	snd_note Gs_5
	snd_env $0F
	snd_note G_5
	snd_env $67
	snd_note G_5
	snd_env $0F
	snd_note G_5, 48
	snd_note F_5, 24
	snd_note D_5
	snd_note E_5, 48
	snd_env $87
	snd_note E_5, 96
	snd_env $0F
	snd_note G_5, 48
	snd_note F_5, 96
	snd_env $87
	snd_note F_5, 96
	snd_jump Trk3D_533B
Mus3D_0_Ch3:
	snd_env2 $40
	snd_wave SndWave01
Trk3D_536F:
	snd_call Trk3D_53B7
	snd_loop 4
	snd_note Cs_3, 5
	snd_len 1
	snd_off
	snd_note Cs_3, 5
	snd_len 1
	snd_off
	snd_note D_3, 5
	snd_len 1
	snd_off
	snd_note E_3, 5
	snd_len 1
	snd_off
	snd_endloop
	snd_call Trk3D_53B7
	snd_call Trk3D_53B7
	snd_loop 7
	snd_note E_3, 5
	snd_len 1
	snd_off
	snd_note E_3, 5
	snd_len 1
	snd_off
	snd_note F_3, 5
	snd_len 1
	snd_off
	snd_note G_3, 5
	snd_len 1
	snd_off
	snd_endloop
	snd_note As_3, 5
	snd_len 1
	snd_off
	snd_note As_3, 5
	snd_len 1
	snd_off
	snd_note G_3, 5
	snd_len 1
	snd_off
	snd_note E_3, 5
	snd_len 1
	snd_off
	snd_call Trk3D_53B7
	snd_call Trk3D_53B7
	snd_jump Trk3D_536F
Trk3D_53B7:
	snd_loop 2
	snd_note D_3, 5
	snd_len 1
	snd_off
	snd_note D_3, 5
	snd_len 1
	snd_off
	snd_note E_3, 5
	snd_len 1
	snd_off
	snd_note F_3, 5
	snd_len 1
	snd_off
	snd_endloop
	snd_note D_3, 5
	snd_len 1
	snd_off
	snd_note D_3, 5
	snd_len 1
	snd_off
	snd_note E_3, 5
	snd_len 1
	snd_off
	snd_note F_3, 5
	snd_len 1
	snd_off
	snd_note A_3, 5
	snd_len 1
	snd_off
	snd_note A_3, 5
	snd_len 1
	snd_off
	snd_note F_3, 5
	snd_len 1
	snd_off
	snd_note E_3, 5
	snd_len 1
	snd_off
	snd_ret
Mus3D_0_Ch4:
	snd_len 12
	snd_drum 6
	snd_len 6
	snd_drum 1
	snd_drum 1
	snd_len 12
	snd_drum 4
	snd_len 6
	snd_drum 1
	snd_drum 1
	snd_jump Mus3D_0_Ch4
Mus3D_1:
	db $0F	; channel mask
	dw Mus3D_1_Ch1, Mus3D_1_Ch2, Mus3D_1_Ch3, Mus3D_1_Ch4
Mus3D_1_Ch2:
	snd_tempo 50
	snd_duty $80
	snd_env $B2
	snd_pitchenv SndPitchEnv_498E
	snd_transpose $0C
	snd_note D_4, 6
	snd_note A_3, 3
	snd_note C_4
	snd_note D_4, 2
	snd_len 1
	snd_off
	snd_note D_4, 2
	snd_len 1
	snd_off
	snd_note F_4, 2
	snd_len 1
	snd_off
	snd_tempo 45
	snd_note D_4, 2
	snd_len 1
	snd_off
	snd_tempo 40
	snd_note G_4, 6
	snd_tempo 35
	snd_note A_4
	snd_tempo 30
	snd_env $B2
	snd_note D_5
	snd_end
Mus3D_1_Ch1:
	snd_duty $40
	snd_env $93
	snd_note D_4, 6
	snd_note A_3, 3
	snd_note C_4
	snd_note D_4, 2
	snd_len 1
	snd_off
	snd_note D_4, 2
	snd_len 1
	snd_off
	snd_note F_4, 2
	snd_len 1
	snd_off
	snd_note D_4, 2
	snd_len 1
	snd_off
	snd_note G_4, 6
	snd_note F_4
	snd_env $B4
	snd_note D_4, 3
	snd_end
Mus3D_1_Ch3:
	snd_duty $00
	snd_env2 $20
	snd_wave SndWave01
	snd_transpose $F4
	snd_note D_4, 3
	snd_off
	snd_note A_3
	snd_note C_4
	snd_note D_4, 2
	snd_len 1
	snd_off
	snd_note D_4, 2
	snd_len 1
	snd_off
	snd_note F_4, 2
	snd_len 1
	snd_off
	snd_note D_4, 2
	snd_len 1
	snd_off
	snd_note G_4, 2
	snd_len 4
	snd_off
	snd_note F_4, 2
	snd_len 4
	snd_off
	snd_note D_4, 4
	snd_end
Mus3D_1_Ch4:
	snd_len 24
	snd_off
	snd_len 6
	snd_off
	snd_drum 8
	snd_drum 5
	snd_end
Mus3D_2:
	db $0F	; channel mask
	dw Mus3D_2_Ch1, Mus3D_2_Ch2, Mus3D_2_Ch3, Mus3D_2_Ch4
Mus3D_2_Ch1:
	snd_tempo 142
	snd_duty $40
	snd_env $70
	snd_pitchenv SndPitchEnv_498E
Trk3D_5493:
	snd_env $60
	snd_note A_4, 66
	snd_len 7
	snd_off
	snd_note A_4, 6
	snd_note G_4
	snd_note A_4
	snd_note As_4, 5
	snd_note A_4, 90
	snd_len 6
	snd_off
	snd_note A_4, 60
	snd_len 12
	snd_off
	snd_note A_4, 6
	snd_note G_4, 5
	snd_note A_4, 1
	snd_len 5
	snd_off
	snd_note As_4, 6
	snd_note A_4, 48
	snd_len 1
	snd_off
	snd_note D_5, 8
	snd_len 40
	snd_off
	snd_env $63
	snd_call Trk3D_5589
	snd_call Trk3D_5589
	snd_len 12
	snd_off
	snd_note G_6, 3
	snd_off
	snd_note G_6
	snd_off
	snd_note G_6
	snd_len 9
	snd_off
	snd_note G_6, 3
	snd_len 9
	snd_off
	snd_note G_6, 3
	snd_off
	snd_note G_6
	snd_off
	snd_note A_6
	snd_off
	snd_note G_6
	snd_off
	snd_note E_6
	snd_len 9
	snd_off
	snd_note G_6, 3
	snd_len 9
	snd_off
	snd_note D_3, 12
	snd_note F_5, 18
	snd_len 6
	snd_off
	snd_note F_5, 12
	snd_note D_3
	snd_note F_5, 6
	snd_off
	snd_note A_2, 9
	snd_len 3
	snd_off
	snd_note F_5, 6
	snd_len 6
	snd_off
	snd_env $62
	snd_len 12
	snd_off
	snd_note As_6, 3
	snd_off
	snd_note As_6
	snd_off
	snd_note As_6
	snd_len 9
	snd_off
	snd_note As_6, 3
	snd_len 9
	snd_off
	snd_note As_6, 3
	snd_off
	snd_note As_6
	snd_off
	snd_note C_7
	snd_off
	snd_note As_6
	snd_off
	snd_note G_6
	snd_len 9
	snd_off
	snd_note As_6, 3
	snd_len 9
	snd_off
	snd_note D_7, 24
	snd_note E_7, 6
	snd_off
	snd_note D_7
	snd_off
	snd_note Cs_7, 12
	snd_note D_7
	snd_note Cs_7
	snd_note A_6, 3
	snd_off
	snd_note A_6
	snd_off
	snd_env $63
	snd_call Trk3D_5589
	snd_note D_4, 12
	snd_note F_5, 18
	snd_len 6
	snd_off
	snd_note F_5, 9
	snd_len 3
	snd_off
	snd_note D_4, 12
	snd_note F_5, 6
	snd_off
	snd_note A_3, 9
	snd_len 3
	snd_off
	snd_note F_5, 6
	snd_off
	snd_env $67
	snd_note As_6, 36
	snd_note C_7, 12
	snd_note As_6
	snd_note C_7, 3
	snd_off
	snd_note As_6
	snd_off
	snd_note G_6
	snd_len 9
	snd_off
	snd_note D_6, 3
	snd_len 9
	snd_off
	snd_note D_5, 19
	snd_len 5
	snd_off
	snd_note D_5, 10
	snd_len 2
	snd_off
	snd_note E_5, 9
	snd_len 3
	snd_off
	snd_note F_5, 5
	snd_len 7
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note F_5, 6
	snd_note D_5
	snd_off
	snd_note F_5
	snd_off
	snd_note D_6, 7
	snd_len 5
	snd_off
	snd_note D_6, 12
	snd_off
	snd_note E_6, 7
	snd_len 5
	snd_off
	snd_note F_6, 48
	snd_len 12
	snd_off
	snd_note D_5
	snd_note E_5
	snd_note D_5
	snd_note Cs_5, 6
	snd_off
	snd_note G_4, 12
	snd_note A_4
	snd_note G_4
	snd_note F_4, 96
	snd_jump Trk3D_5493
Trk3D_5589:
	snd_note D_4, 12
	snd_note F_5, 18
	snd_len 6
	snd_off
	snd_note F_5, 9
	snd_len 3
	snd_off
	snd_note D_4, 12
	snd_note F_5, 6
	snd_off
	snd_note A_3, 9
	snd_len 3
	snd_off
	snd_note F_5, 6
	snd_off
	snd_note D_3, 12
	snd_note F_5, 18
	snd_len 6
	snd_off
	snd_note F_5, 9
	snd_len 15
	snd_off
	snd_note F_5, 6
	snd_len 18
	snd_off
	snd_note F_5, 6
	snd_off
	snd_ret
Mus3D_2_Ch2:
	snd_duty $40
	snd_env $80
	snd_pitchenv SndPitchEnv_499B
Trk3D_55B8:
	snd_env $62
	snd_call Trk3D_565B
	snd_call Trk3D_565B
	snd_call Trk3D_565B
	snd_note D_5, 6
	snd_off
	snd_note D_5
	snd_note C_5
	snd_note A_4
	snd_off
	snd_note C_5
	snd_off
	snd_note D_4, 9
	snd_len 39
	snd_off
	snd_env $87
	snd_call Trk3D_566F
	snd_call Trk3D_566F
	snd_note G_4, 36
	snd_note A_4, 12
	snd_note As_4, 24
	snd_note G_4, 12
	snd_note As_4
	snd_note A_4, 24
	snd_note D_5
	snd_note F_5, 9
	snd_len 15
	snd_off
	snd_note A_5, 24
	snd_note G_5, 9
	snd_len 3
	snd_off
	snd_note G_5, 12
	snd_note F_5
	snd_note G_5, 9
	snd_len 15
	snd_off
	snd_note G_5, 3
	snd_off
	snd_note G_5, 6
	snd_note F_5, 12
	snd_note G_5, 6
	snd_off
	snd_note G_5
	snd_off
	snd_note As_4, 9
	snd_len 3
	snd_off
	snd_note C_5, 12
	snd_note As_4
	snd_note A_4
	snd_note As_4
	snd_note A_4
	snd_off
	snd_call Trk3D_566F
	snd_note A_5, 36
	snd_note As_5, 12
	snd_note A_5, 24
	snd_note F_5, 9
	snd_len 3
	snd_off
	snd_note D_5, 12
	snd_note G_4, 36
	snd_note A_4, 12
	snd_note G_4, 24
	snd_off
	snd_note B_4, 19
	snd_len 5
	snd_off
	snd_note B_4, 10
	snd_len 2
	snd_off
	snd_note Cs_5, 9
	snd_len 3
	snd_off
	snd_note D_5, 5
	snd_len 7
	snd_off
	snd_note D_5, 2
	snd_len 4
	snd_off
	snd_note D_5, 6
	snd_note B_4
	snd_off
	snd_note D_5
	snd_off
	snd_note F_5, 7
	snd_len 5
	snd_off
	snd_note F_5, 12
	snd_len 11
	snd_off
	snd_note G_5, 7
	snd_len 6
	snd_off
	snd_note A_5, 48
	snd_len 12
	snd_off
	snd_note F_5
	snd_note G_5
	snd_note F_5
	snd_note E_5, 6
	snd_off
	snd_note As_4, 12
	snd_note C_5
	snd_note As_4
	snd_note A_4, 96
	snd_jump Trk3D_55B8
Trk3D_565B:
	snd_note D_5, 5
	snd_len 7
	snd_off
	snd_note D_5, 6
	snd_note C_5
	snd_note A_4, 5
	snd_len 7
	snd_off
	snd_note C_5, 5
	snd_len 7
	snd_off
	snd_note D_5, 5
	snd_len 43
	snd_off
	snd_ret
Trk3D_566F:
	snd_note A_5, 36
	snd_note As_5, 12
	snd_note A_5, 24
	snd_note F_5, 12
	snd_note D_5
	snd_note A_4, 36
	snd_note As_4, 12
	snd_note A_4, 24
	snd_off
	snd_ret
Mus3D_2_Ch3:
	snd_duty $00
	snd_env2 $20
	snd_wave SndWave0C
Trk3D_5687:
	snd_call Trk3D_576B
	snd_call Trk3D_576B
	snd_call Trk3D_576B
	snd_note D_3, 12
	snd_note A_3
	snd_note A_2
	snd_note A_3, 9
	snd_len 3
	snd_off
	snd_note D_3, 9
	snd_len 15
	snd_off
	snd_note A_2, 24
	snd_call Trk3D_5780
	snd_call Trk3D_5780
	snd_note G_3, 12
	snd_note D_4, 18
	snd_len 6
	snd_off
	snd_note D_4, 9
	snd_len 3
	snd_off
	snd_note G_3, 12
	snd_note D_4, 9
	snd_len 3
	snd_off
	snd_note D_3, 12
	snd_note D_4, 9
	snd_len 3
	snd_off
	snd_note D_3, 12
	snd_note A_3
	snd_off
	snd_note A_3, 9
	snd_len 3
	snd_off
	snd_note D_3, 12
	snd_note A_3, 9
	snd_len 3
	snd_off
	snd_note A_2, 12
	snd_note A_3, 9
	snd_len 3
	snd_off
	snd_note G_3, 12
	snd_note D_4, 18
	snd_len 6
	snd_off
	snd_note D_4, 9
	snd_len 3
	snd_off
	snd_note G_3, 12
	snd_note D_4, 6
	snd_off
	snd_note D_3, 12
	snd_note D_4, 6
	snd_off
	snd_note G_3, 12
	snd_note D_4
	snd_note C_4, 6
	snd_off
	snd_note As_3
	snd_off
	snd_note A_3
	snd_len 18
	snd_off
	snd_note A_4, 6
	snd_len 18
	snd_off
	snd_call Trk3D_5780
	snd_note D_3, 12
	snd_note A_3
	snd_off
	snd_note A_3, 9
	snd_len 3
	snd_off
	snd_note D_3, 12
	snd_note A_3, 6
	snd_off
	snd_note A_2, 9
	snd_len 3
	snd_off
	snd_note A_3
	snd_len 9
	snd_off
	snd_note G_3, 12
	snd_note D_4
	snd_note D_3
	snd_note D_4, 9
	snd_len 3
	snd_off
	snd_note G_3, 12
	snd_note D_4, 9
	snd_len 15
	snd_off
	snd_note D_4, 9
	snd_len 3
	snd_off
	snd_note G_3, 12
	snd_note D_4
	snd_note D_3
	snd_note D_4, 9
	snd_len 3
	snd_off
	snd_note G_3, 12
	snd_note D_4, 9
	snd_len 15
	snd_off
	snd_note D_4, 9
	snd_len 3
	snd_off
	snd_note D_3, 12
	snd_note A_3
	snd_off
	snd_note A_3, 9
	snd_len 3
	snd_off
	snd_note D_3, 12
	snd_note A_3, 6
	snd_off
	snd_note A_2, 9
	snd_len 3
	snd_off
	snd_note A_3, 6
	snd_off
	snd_note As_3, 12
	snd_note D_4, 6
	snd_off
	snd_note G_3, 12
	snd_note D_4, 6
	snd_off
	snd_note A_3, 9
	snd_len 3
	snd_off
	snd_note A_3, 24
	snd_note A_2, 9
	snd_len 3
	snd_off
	snd_note D_3, 12
	snd_note A_3
	snd_off
	snd_note A_3, 9
	snd_len 3
	snd_off
	snd_note D_3, 12
	snd_note A_3, 6
	snd_off
	snd_note A_2, 9
	snd_len 3
	snd_off
	snd_note A_3, 6
	snd_off
	snd_jump Trk3D_5687
Trk3D_576B:
	snd_note D_3, 12
	snd_note A_3
	snd_off
	snd_note A_3, 9
	snd_len 3
	snd_off
	snd_note D_3, 12
	snd_note A_3, 6
	snd_off
	snd_note A_2, 11
	snd_len 1
	snd_off
	snd_note A_3, 6
	snd_off
	snd_ret
Trk3D_5780:
	snd_note D_3, 12
	snd_note A_3, 18
	snd_len 6
	snd_off
	snd_note A_3, 9
	snd_len 3
	snd_off
	snd_note D_3, 10
	snd_len 2
	snd_off
	snd_note A_3, 6
	snd_off
	snd_note A_2, 9
	snd_len 3
	snd_off
	snd_note A_3, 6
	snd_off
	snd_note D_3, 12
	snd_note A_3
	snd_note A_2
	snd_note A_3, 9
	snd_len 3
	snd_off
	snd_note D_3, 9
	snd_len 3
	snd_off
	snd_note A_3, 12
	snd_off
	snd_note A_3, 9
	snd_len 3
	snd_off
	snd_ret
Mus3D_2_Ch4:
	snd_loop 2
	snd_len 12
	snd_drum 6
	snd_drum 0
	snd_drum 4
	snd_drum 4
	snd_drum 6
	snd_drum 0
	snd_drum 4
	snd_drum 0
	snd_endloop
	snd_drum 6
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 4
	snd_drum 4
	snd_drum 6
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 4
	snd_drum 0
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
	snd_loop 3
	snd_call Trk3D_5808
	snd_call Trk3D_5815
	snd_endloop
	snd_call Trk3D_5808
	snd_len 12
	snd_drum 5
	snd_drum 2
	snd_drum 3
	snd_drum 2
	snd_len 24
	snd_drum 9
	snd_len 12
	snd_drum 5
	snd_len 6
	snd_drum 4
	snd_drum 4
	snd_loop 2
	snd_call Trk3D_5808
	snd_call Trk3D_5815
	snd_endloop
	snd_loop 7
	snd_len 12
	snd_drum 5
	snd_drum 2
	snd_drum 4
	snd_drum 2
	snd_endloop
	snd_len 12
	snd_drum 5
	snd_len 6
	snd_drum 4
	snd_drum 4
	snd_len 12
	snd_drum 8
	snd_drum 9
	snd_jump Mus3D_2_Ch4
Trk3D_5808:
	snd_len 12
	snd_drum 5
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 0
	snd_drum 0
	snd_drum 5
	snd_drum 3
	snd_drum 5
	snd_drum 3
	snd_ret
Trk3D_5815:
	snd_len 12
	snd_drum 5
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 5
	snd_drum 0
	snd_drum 5
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 4
	snd_drum 5
	snd_ret
Mus3D_3:
	db $0F	; channel mask
	dw Mus3D_3_Ch1, Mus3D_3_Ch2, Mus3D_3_Ch3, Mus3D_3_Ch4
Mus3D_3_Ch1:
	snd_tempo 96
	snd_duty $00
	snd_env $87
	snd_pitchenv SndPitchEnv_49A8
	snd_len 96
	snd_off
	snd_off
Trk3D_583A:
	snd_loop 2
	snd_len 8
	snd_off
	snd_note C_5, 15
	snd_len 1
	snd_off
	snd_note G_4, 4
	snd_len 8
	snd_off
	snd_note As_4
	snd_note A_4, 30
	snd_len 10
	snd_off
	snd_note Gs_4, 8
	snd_note A_4, 4
	snd_note Ds_5, 7
	snd_len 1
	snd_off
	snd_note Ds_5, 4
	snd_note B_4, 8
	snd_note D_5, 48
	snd_len 4
	snd_off
	snd_note C_5, 7
	snd_len 1
	snd_off
	snd_note Ds_5, 4
	snd_note As_4, 6
	snd_len 2
	snd_off
	snd_note A_4, 4
	snd_note As_4, 8
	snd_note A_4, 4
	snd_note As_4, 7
	snd_len 1
	snd_off
	snd_note As_4, 7
	snd_len 21
	snd_off
	snd_note As_4, 8
	snd_note A_4, 4
	snd_note As_4, 7
	snd_len 1
	snd_off
	snd_note As_4, 7
	snd_len 21
	snd_off
	snd_note B_4, 8
	snd_note C_5, 4
	snd_note Gs_4, 8
	snd_note A_4, 4
	snd_note E_4, 8
	snd_note F_4, 4
	snd_note Gs_4, 8
	snd_note A_4, 39
	snd_len 13
	snd_off
	snd_endloop
	snd_note As_4, 4
	snd_len 8
	snd_off
	snd_note A_4
	snd_note As_4, 3
	snd_len 9
	snd_off
	snd_note As_4, 4
	snd_note A_4, 8
	snd_note As_4, 3
	snd_len 1
	snd_off
	snd_note As_4, 8
	snd_note D_5, 4
	snd_note C_5, 8
	snd_note As_4, 5
	snd_len 23
	snd_off
	snd_note C_5, 4
	snd_len 8
	snd_off
	snd_note B_4
	snd_note C_5, 3
	snd_len 9
	snd_off
	snd_note C_5, 4
	snd_note B_4, 8
	snd_note C_5, 3
	snd_len 1
	snd_off
	snd_note C_5, 8
	snd_note A_4, 4
	snd_note D_5, 8
	snd_note C_5, 4
	snd_len 24
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_note Cs_5
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note As_4, 4
	snd_note C_5, 8
	snd_note Cs_5, 4
	snd_len 8
	snd_off
	snd_note A_5, 4
	snd_note E_5, 8
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_note As_4, 4
	snd_note C_5, 8
	snd_note Cs_5, 4
	snd_note D_5, 8
	snd_note G_5, 4
	snd_note Cs_5, 8
	snd_note C_5, 4
	snd_note A_5, 8
	snd_note As_5, 4
	snd_note A_5, 8
	snd_note As_5, 4
	snd_note Ds_5, 8
	snd_note E_5, 4
	snd_note F_5, 8
	snd_note E_5, 4
	snd_note B_5, 8
	snd_note C_6, 4
	snd_note B_5, 8
	snd_note C_6, 4
	snd_note A_5, 6
	snd_off
	snd_note Ds_5, 8
	snd_note C_5, 28
	snd_note A_5, 6
	snd_off
	snd_note Ds_5, 8
	snd_note F_5, 27
	snd_len 1
	snd_off
	snd_note E_5, 18
	snd_len 2
	snd_off
	snd_note Ds_5, 4
	snd_note D_5, 6
	snd_off
	snd_note C_5
	snd_off
	snd_note A_4
	snd_off
	snd_note A_4
	snd_off
	snd_note As_4
	snd_off
	snd_note C_5
	snd_off
	snd_note D_5
	snd_len 96
	snd_off
	snd_len 90
	snd_off
	snd_note G_5, 20
	snd_note Cs_5, 4
	snd_note D_5, 7
	snd_len 5
	snd_off
	snd_note F_5, 7
	snd_len 5
	snd_off
	snd_note As_4, 7
	snd_len 5
	snd_off
	snd_note D_5, 7
	snd_len 5
	snd_off
	snd_note G_4, 7
	snd_len 5
	snd_off
	snd_note As_4, 7
	snd_len 5
	snd_off
	snd_note C_5, 8
	snd_note D_5, 4
	snd_note Ds_5, 8
	snd_note F_5, 4
	snd_len 8
	snd_off
	snd_note E_5, 4
	snd_len 8
	snd_off
	snd_note G_5, 4
	snd_note A_5, 7
	snd_len 5
	snd_off
	snd_note G_5, 7
	snd_len 5
	snd_off
	snd_note C_6, 7
	snd_len 5
	snd_off
	snd_note As_5, 7
	snd_len 5
	snd_off
	snd_note E_5, 7
	snd_len 89
	snd_off
	snd_len 96
	snd_off
	snd_jump Trk3D_583A
Mus3D_3_Ch2:
	snd_duty $40
	snd_env $87
	snd_pitchenv SndPitchEnv_499B
	snd_len 96
	snd_off
	snd_off
Trk3D_597E:
	snd_loop 2
	snd_len 8
	snd_off
	snd_note A_5, 15
	snd_len 1
	snd_off
	snd_note C_5, 4
	snd_len 8
	snd_off
	snd_note D_5
	snd_note F_5, 30
	snd_len 10
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
	snd_note C_5, 40
	snd_len 12
	snd_off
	snd_endloop
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_note Cs_5
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 4
	snd_note Cs_5, 8
	snd_note D_5, 3
	snd_len 1
	snd_off
	snd_note D_5, 8
	snd_note A_5, 4
	snd_note E_5, 8
	snd_note D_5, 4
	snd_len 24
	snd_off
	snd_note E_5, 4
	snd_len 8
	snd_off
	snd_note Ds_5
	snd_note E_5, 3
	snd_len 9
	snd_off
	snd_note E_5, 4
	snd_note Ds_5, 8
	snd_note E_5, 2
	snd_off
	snd_note E_5, 8
	snd_note C_5, 4
	snd_note F_5, 8
	snd_note E_5, 4
	snd_len 24
	snd_off
	snd_note G_5, 4
	snd_len 8
	snd_off
	snd_note Fs_5
	snd_note G_5, 3
	snd_len 9
	snd_off
	snd_note G_5, 4
	snd_note Fs_5, 8
	snd_note G_5, 3
	snd_len 1
	snd_off
	snd_note G_5, 8
	snd_note D_6, 4
	snd_note A_5, 8
	snd_note G_5, 5
	snd_len 7
	snd_off
	snd_note Fs_5, 4
	snd_note G_5, 8
	snd_note Gs_5, 4
	snd_note A_5, 8
	snd_note As_5, 4
	snd_note A_5, 8
	snd_note As_5, 4
	snd_note A_6, 8
	snd_note As_6, 4
	snd_note A_6, 8
	snd_note As_6, 4
	snd_note B_5, 8
	snd_note C_6, 4
	snd_note B_5, 8
	snd_note C_6, 4
	snd_note B_6, 8
	snd_note C_7, 4
	snd_note B_6, 8
	snd_note C_7, 4
	snd_note C_6, 6
	snd_off
	snd_note C_6, 8
	snd_note A_5, 28
	snd_note D_6, 6
	snd_off
	snd_note D_6, 8
	snd_note A_5, 27
	snd_len 1
	snd_off
	snd_note C_6, 18
	snd_len 2
	snd_off
	snd_note A_5, 4
	snd_note D_6, 6
	snd_off
	snd_note C_6
	snd_off
	snd_note A_5
	snd_off
	snd_note F_5
	snd_off
	snd_note Gs_5
	snd_off
	snd_note A_5
	snd_off
	snd_note As_5
	snd_len 96
	snd_off
	snd_len 90
	snd_off
	snd_note As_5, 20
	snd_note G_5, 3
	snd_len 1
	snd_off
	snd_note G_5, 8
	snd_len 4
	snd_off
	snd_note As_5, 8
	snd_len 4
	snd_off
	snd_note C_6, 8
	snd_len 4
	snd_off
	snd_note As_5, 8
	snd_len 4
	snd_off
	snd_note G_5, 8
	snd_len 4
	snd_off
	snd_note D_5, 8
	snd_len 4
	snd_off
	snd_note E_5, 8
	snd_note F_5, 4
	snd_note Fs_5, 8
	snd_note G_5, 4
	snd_len 8
	snd_off
	snd_note G_5, 4
	snd_len 8
	snd_off
	snd_note As_5, 4
	snd_note C_6, 7
	snd_len 5
	snd_off
	snd_note As_5, 7
	snd_len 5
	snd_off
	snd_note E_6, 7
	snd_len 5
	snd_off
	snd_note D_6, 7
	snd_len 5
	snd_off
	snd_note C_6, 7
	snd_len 89
	snd_off
	snd_len 96
	snd_off
	snd_jump Trk3D_597E
Mus3D_3_Ch3:
	snd_duty $00
	snd_env2 $20
	snd_wave SndWave00
	snd_loop 2
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
	snd_endloop
Trk3D_5AEE:
	snd_loop 2
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
	snd_note C_3
	snd_off
	snd_note D_3
	snd_off
	snd_note C_3
	snd_off
	snd_endloop
	snd_note G_3, 6
	snd_len 18
	snd_off
	snd_note D_3, 6
	snd_len 18
	snd_off
	snd_note G_3, 6
	snd_off
	snd_note D_3
	snd_off
	snd_note E_3
	snd_off
	snd_note D_3
	snd_off
	snd_note A_3
	snd_len 18
	snd_off
	snd_note E_3, 6
	snd_len 18
	snd_off
	snd_note A_3, 6
	snd_off
	snd_note E_3
	snd_off
	snd_note F_3
	snd_off
	snd_note Fs_3
	snd_off
	snd_note G_3
	snd_len 18
	snd_off
	snd_note D_3, 6
	snd_len 18
	snd_off
	snd_note G_3, 6
	snd_off
	snd_note D_3
	snd_off
	snd_note E_3
	snd_off
	snd_note D_3
	snd_off
	snd_note A_3
	snd_off
	snd_note A_3
	snd_off
	snd_note Gs_3
	snd_off
	snd_note Gs_3
	snd_off
	snd_note G_3
	snd_off
	snd_note G_3
	snd_off
	snd_note Fs_3
	snd_off
	snd_note Fs_3
	snd_off
	snd_note F_3
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
	snd_note G_3, 8
	snd_len 96
	snd_off
	snd_len 88
	snd_off
	snd_note G_3, 6
	snd_len 18
	snd_off
	snd_note D_3, 6
	snd_len 18
	snd_off
	snd_note G_3, 6
	snd_off
	snd_note D_3
	snd_off
	snd_note E_3
	snd_off
	snd_note D_3
	snd_off
	snd_note G_3
	snd_len 18
	snd_off
	snd_note D_3, 6
	snd_len 18
	snd_off
	snd_note G_3, 6
	snd_off
	snd_note D_3
	snd_off
	snd_note E_3
	snd_off
	snd_note Fs_3
	snd_off
	snd_note G_3, 8
	snd_len 88
	snd_off
	snd_len 96
	snd_off
	snd_jump Trk3D_5AEE
Mus3D_3_Ch4:
	snd_call Trk3D_5C74
	snd_call Trk3D_5C74
Trk3D_5BC9:
	snd_loop 14
	snd_call Trk3D_5C74
	snd_endloop
	snd_len 8
	snd_drum 5
	snd_len 4
	snd_drum 4
	snd_len 12
	snd_drum 1
	snd_drum 4
	snd_len 8
	snd_drum 2
	snd_len 4
	snd_drum 8
	snd_len 8
	snd_drum 9
	snd_len 4
	snd_drum 5
	snd_len 8
	snd_drum 8
	snd_len 4
	snd_drum 5
	snd_len 12
	snd_drum 2
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 1
	snd_len 4
	snd_drum 4
	snd_len 12
	snd_drum 4
	snd_len 8
	snd_drum 2
	snd_len 4
	snd_drum 8
	snd_len 8
	snd_drum 9
	snd_len 4
	snd_drum 5
	snd_len 12
	snd_drum 2
	snd_drum 5
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 5
	snd_len 4
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 8
	snd_drum 5
	snd_len 4
	snd_drum 0
	snd_len 8
	snd_drum 3
	snd_len 4
	snd_drum 0
	snd_len 8
	snd_drum 5
	snd_len 4
	snd_drum 0
	snd_len 8
	snd_drum 5
	snd_len 4
	snd_drum 0
	snd_len 8
	snd_drum 5
	snd_len 4
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 5
	snd_len 8
	snd_drum 5
	snd_len 4
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 8
	snd_drum 5
	snd_len 4
	snd_drum 0
	snd_len 8
	snd_drum 3
	snd_len 4
	snd_drum 0
	snd_len 8
	snd_drum 5
	snd_len 4
	snd_drum 0
	snd_len 8
	snd_drum 5
	snd_len 4
	snd_drum 0
	snd_len 8
	snd_drum 5
	snd_len 4
	snd_drum 0
	snd_drum 0
	snd_drum 0
	snd_drum 5
	snd_len 8
	snd_drum 5
	snd_len 4
	snd_drum 4
	snd_len 12
	snd_drum 1
	snd_drum 4
	snd_len 8
	snd_drum 2
	snd_len 4
	snd_drum 8
	snd_len 8
	snd_drum 9
	snd_len 4
	snd_drum 5
	snd_len 8
	snd_drum 8
	snd_len 4
	snd_drum 5
	snd_len 12
	snd_drum 2
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 1
	snd_len 4
	snd_drum 4
	snd_len 12
	snd_drum 4
	snd_len 8
	snd_drum 2
	snd_len 4
	snd_drum 8
	snd_len 8
	snd_drum 9
	snd_len 4
	snd_drum 5
	snd_len 12
	snd_drum 2
	snd_drum 5
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_jump Trk3D_5BC9
Trk3D_5C74:
	snd_len 8
	snd_drum 5
	snd_len 4
	snd_drum 0
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 0
	snd_len 8
	snd_drum 5
	snd_len 4
	snd_drum 0
	snd_len 8
	snd_drum 3
	snd_len 4
	snd_drum 0
	snd_len 8
	snd_drum 5
	snd_len 4
	snd_drum 0
	snd_len 8
	snd_drum 5
	snd_len 4
	snd_drum 0
	snd_len 8
	snd_drum 5
	snd_len 4
	snd_drum 0
	snd_len 8
	snd_drum 2
	snd_len 4
	snd_drum 5
	snd_ret
Mus3D_4:
	db $0F	; channel mask
	dw Mus3D_4_Ch1, Mus3D_4_Ch2, Mus3D_4_Ch3, Mus3D_4_Ch4
Mus3D_4_Ch2:
	snd_tempo 85
	snd_duty $40
	snd_env $87
	snd_pitchenv SndPitchEnv_499B
Trk3D_5CA7:
	snd_note D_6, 8
	snd_note B_5, 4
	snd_note G_5, 8
	snd_note D_6, 4
	snd_note B_5, 8
	snd_note G_5, 4
	snd_note D_6, 7
	snd_len 1
	snd_off
	snd_note D_6, 52
	snd_note E_6, 8
	snd_note C_6, 4
	snd_note G_5, 8
	snd_note E_6, 4
	snd_note C_6, 8
	snd_note G_5, 4
	snd_note E_6, 6
	snd_len 2
	snd_off
	snd_note E_6, 47
	snd_len 5
	snd_off
	snd_note D_6, 8
	snd_note B_5, 4
	snd_note G_5, 8
	snd_note D_6, 4
	snd_note B_5, 8
	snd_note G_5, 4
	snd_note D_6, 7
	snd_len 1
	snd_off
	snd_note D_6, 42
	snd_len 10
	snd_off
	snd_note D_5, 6
	snd_off
	snd_note A_4, 3
	snd_len 5
	snd_off
	snd_note A_4, 3
	snd_len 1
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_note A_4, 3
	snd_len 5
	snd_off
	snd_note A_4, 3
	snd_len 1
	snd_off
	snd_note D_5, 4
	snd_off
	snd_note D_5, 3
	snd_len 1
	snd_off
	snd_note D_5, 4
	snd_off
	snd_note Fs_5, 3
	snd_len 1
	snd_off
	snd_note D_5, 5
	snd_len 19
	snd_off
	snd_loop 2
	snd_note B_5, 8
	snd_note A_5, 4
	snd_note G_5, 7
	snd_len 1
	snd_off
	snd_note E_6, 4
	snd_note D_6
	snd_len 8
	snd_off
	snd_note B_5, 3
	snd_len 9
	snd_off
	snd_note B_5, 8
	snd_note A_5, 4
	snd_note G_5, 8
	snd_note E_6, 4
	snd_note D_6
	snd_len 8
	snd_off
	snd_note B_5, 3
	snd_len 9
	snd_off
	snd_note A_5, 8
	snd_note B_5, 4
	snd_note D_6, 8
	snd_note E_6, 4
	snd_note A_5, 8
	snd_note B_5, 4
	snd_note D_6, 8
	snd_note E_6, 2
	snd_off
	snd_note G_6, 3
	snd_len 9
	snd_off
	snd_note A_6, 3
	snd_len 9
	snd_off
	snd_note D_6, 3
	snd_len 21
	snd_off
	snd_note E_6, 8
	snd_note Fs_6, 4
	snd_note E_6, 8
	snd_note D_6, 4
	snd_note B_5, 8
	snd_note D_6, 4
	snd_note E_6, 6
	snd_off
	snd_note D_6, 8
	snd_note E_6, 4
	snd_note B_5, 8
	snd_note G_5, 4
	snd_note A_5, 8
	snd_note B_5, 4
	snd_note A_5, 5
	snd_len 7
	snd_off
	snd_note B_5, 8
	snd_note D_6, 4
	snd_note E_6, 8
	snd_note B_5, 4
	snd_note D_6, 8
	snd_note E_6, 4
	snd_note A_5, 7
	snd_len 1
	snd_off
	snd_note B_5, 4
	snd_note D_6, 8
	snd_note E_6, 4
	snd_note B_5, 7
	snd_len 1
	snd_off
	snd_note A_5, 4
	snd_note G_5, 5
	snd_len 19
	snd_off
	snd_endloop
	snd_loop 4
	snd_call Trk3D_5DF4
	snd_endloop
	snd_call Trk3D_5E09
	snd_loop 4
	snd_call Trk3D_5DF4
	snd_endloop
	snd_transpose $0C
	snd_call Trk3D_5E09
	snd_transpose $00
	snd_note E_5, 3
	snd_len 9
	snd_off
	snd_note B_4, 3
	snd_len 5
	snd_off
	snd_note B_4, 3
	snd_len 1
	snd_off
	snd_note E_5, 4
	snd_len 8
	snd_off
	snd_note B_4, 3
	snd_len 5
	snd_off
	snd_note B_4, 3
	snd_len 1
	snd_off
	snd_note E_5, 4
	snd_off
	snd_note Fs_5, 3
	snd_len 1
	snd_off
	snd_note G_5, 4
	snd_off
	snd_note E_5, 3
	snd_len 1
	snd_off
	snd_note Fs_5, 3
	snd_len 21
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_note A_4, 3
	snd_len 5
	snd_off
	snd_note A_4, 2
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_note A_4, 3
	snd_len 5
	snd_off
	snd_note A_4, 3
	snd_len 1
	snd_off
	snd_note D_5, 3
	snd_len 5
	snd_off
	snd_note E_5, 2
	snd_off
	snd_note Fs_5, 4
	snd_off
	snd_note D_5, 2
	snd_off
	snd_note D_6, 4
	snd_len 20
	snd_off
	snd_jump Trk3D_5CA7
Trk3D_5DF4:
	snd_note Fs_5, 2
	snd_len 4
	snd_off
	snd_note Fs_5, 2
	snd_len 10
	snd_off
	snd_note Fs_5, 2
	snd_len 10
	snd_off
	snd_note Fs_5, 2
	snd_len 10
	snd_off
	snd_note Fs_5, 2
	snd_len 4
	snd_off
	snd_ret
Trk3D_5E09:
	snd_note As_4, 3
	snd_note B_4
	snd_note As_4
	snd_note B_4
	snd_note As_4
	snd_note B_4
	snd_note As_4
	snd_note B_4
	snd_note As_4
	snd_note B_4
	snd_note As_4
	snd_note B_4
	snd_note As_4
	snd_note B_4
	snd_note C_5
	snd_note Cs_5
	snd_note D_5, 36
	snd_note D_5, 3
	snd_note Cs_5
	snd_note C_5
	snd_note B_4
	snd_note As_4
	snd_note B_4
	snd_note As_4
	snd_note B_4
	snd_note As_4
	snd_note B_4
	snd_note As_4
	snd_note B_4
	snd_note As_4
	snd_note B_4
	snd_note As_4
	snd_note B_4
	snd_note As_4
	snd_note B_4
	snd_note C_5
	snd_note Cs_5
	snd_note D_5, 36
	snd_note D_5, 3
	snd_note Cs_5
	snd_note C_5
	snd_note B_4
	snd_ret
Mus3D_4_Ch1:
	snd_duty $00
	snd_env $80
Trk3D_5E3D:
	snd_env $62
	snd_len 8
	snd_off
	snd_note G_4, 2
	snd_len 14
	snd_off
	snd_note G_4, 3
	snd_len 21
	snd_off
	snd_note G_4, 3
	snd_len 17
	snd_off
	snd_note G_4, 3
	snd_len 9
	snd_off
	snd_note G_5, 3
	snd_len 9
	snd_off
	snd_note G_4, 3
	snd_len 9
	snd_off
	snd_note G_4, 3
	snd_len 13
	snd_off
	snd_note G_4, 3
	snd_len 21
	snd_off
	snd_note G_4, 3
	snd_len 17
	snd_off
	snd_note G_4, 3
	snd_len 9
	snd_off
	snd_note G_5, 3
	snd_len 9
	snd_off
	snd_note G_4, 3
	snd_len 9
	snd_off
	snd_note G_4, 3
	snd_len 13
	snd_off
	snd_note G_4, 2
	snd_len 22
	snd_off
	snd_note G_4, 3
	snd_len 17
	snd_off
	snd_note G_4, 3
	snd_len 9
	snd_off
	snd_note G_5, 3
	snd_len 9
	snd_off
	snd_note G_4, 3
	snd_len 1
	snd_off
	snd_note B_4, 4
	snd_len 20
	snd_off
	snd_note C_5, 4
	snd_len 20
	snd_off
	snd_note As_4, 4
	snd_len 8
	snd_off
	snd_note B_4, 4
	snd_len 8
	snd_off
	snd_note C_5, 4
	snd_len 20
	snd_off
	snd_loop 2
	snd_note G_4, 2
	snd_len 6
	snd_off
	snd_note D_5, 2
	snd_len 14
	snd_off
	snd_note D_5, 2
	snd_len 22
	snd_off
	snd_note D_5, 2
	snd_len 18
	snd_off
	snd_note D_5, 2
	snd_len 10
	snd_off
	snd_note D_5, 2
	snd_len 10
	snd_off
	snd_note D_5, 2
	snd_len 10
	snd_off
	snd_note E_5, 2
	snd_len 14
	snd_off
	snd_note E_5, 2
	snd_len 22
	snd_off
	snd_note E_5, 2
	snd_len 18
	snd_off
	snd_note E_5, 2
	snd_len 10
	snd_off
	snd_note E_5, 2
	snd_len 10
	snd_off
	snd_note E_5, 2
	snd_len 10
	snd_off
	snd_note D_5, 2
	snd_len 14
	snd_off
	snd_note D_5, 2
	snd_len 22
	snd_off
	snd_note D_5, 2
	snd_len 18
	snd_off
	snd_note D_5, 2
	snd_len 10
	snd_off
	snd_note D_5, 2
	snd_len 10
	snd_off
	snd_note D_5, 2
	snd_len 10
	snd_off
	snd_note B_4, 2
	snd_len 14
	snd_off
	snd_note B_4, 2
	snd_len 22
	snd_off
	snd_note D_5, 2
	snd_len 18
	snd_off
	snd_note G_4, 2
	snd_len 10
	snd_off
	snd_note D_5, 2
	snd_len 10
	snd_off
	snd_note G_4, 2
	snd_len 2
	snd_off
	snd_endloop
	snd_env $60
	snd_loop 4
	snd_call Trk3D_5FBF
	snd_endloop
	snd_len 48
	snd_off
	snd_note Fs_4, 3
	snd_note G_4
	snd_note Fs_4
	snd_note G_4
	snd_note Fs_4
	snd_note G_4
	snd_note Fs_4
	snd_note G_4
	snd_note Fs_4
	snd_note G_4
	snd_note Fs_4
	snd_note G_4
	snd_note Fs_4
	snd_note G_4
	snd_note Gs_4
	snd_note A_4
	snd_note As_4, 35
	snd_len 1
	snd_off
	snd_note As_4, 3
	snd_note A_4
	snd_note Gs_4
	snd_note G_4
	snd_note Fs_4
	snd_note G_4
	snd_note Fs_4
	snd_note G_4
	snd_note Fs_4
	snd_note G_4
	snd_note Fs_4
	snd_note G_4
	snd_note Fs_4
	snd_note G_4
	snd_note Fs_4
	snd_note G_4
	snd_note Fs_4
	snd_note G_4
	snd_note Gs_4
	snd_note A_4
	snd_loop 4
	snd_call Trk3D_5FBF
	snd_endloop
	snd_len 48
	snd_off
	snd_note Fs_5, 3
	snd_note G_5
	snd_note Fs_5
	snd_note G_5
	snd_note Fs_5
	snd_note G_5
	snd_note Fs_5
	snd_note G_5
	snd_note Fs_5
	snd_note G_5
	snd_note Fs_5
	snd_note G_5
	snd_note Fs_5
	snd_note G_5
	snd_note Gs_5
	snd_note A_5
	snd_note As_5, 35
	snd_len 1
	snd_off
	snd_note As_5, 3
	snd_note A_5
	snd_note Gs_5
	snd_note G_5
	snd_note Fs_5
	snd_note G_5
	snd_note Fs_5
	snd_note G_5
	snd_note Fs_5
	snd_note G_5
	snd_note Fs_5
	snd_note G_5
	snd_note Fs_5
	snd_note G_5
	snd_note Fs_5
	snd_note G_5
	snd_note Fs_5
	snd_note F_5
	snd_note E_5
	snd_note Ds_5
	snd_note G_4, 3
	snd_len 9
	snd_off
	snd_note E_4, 3
	snd_len 5
	snd_off
	snd_note E_4, 3
	snd_len 1
	snd_off
	snd_note G_4, 4
	snd_len 8
	snd_off
	snd_note E_4, 3
	snd_len 5
	snd_off
	snd_note E_4, 3
	snd_len 1
	snd_off
	snd_note G_4, 4
	snd_off
	snd_note A_4, 3
	snd_len 1
	snd_off
	snd_note B_4, 4
	snd_off
	snd_note G_4, 3
	snd_len 1
	snd_off
	snd_note A_4, 3
	snd_len 21
	snd_off
	snd_note Fs_4, 4
	snd_len 8
	snd_off
	snd_note D_4, 3
	snd_len 5
	snd_off
	snd_note D_4, 2
	snd_off
	snd_note Fs_4, 4
	snd_len 8
	snd_off
	snd_note D_4, 3
	snd_len 5
	snd_off
	snd_note D_4, 3
	snd_len 1
	snd_off
	snd_note Fs_4, 3
	snd_len 5
	snd_off
	snd_note G_4, 2
	snd_off
	snd_note A_4, 4
	snd_off
	snd_note Fs_4, 2
	snd_off
	snd_note D_5, 4
	snd_len 20
	snd_off
	snd_jump Trk3D_5E3D
Trk3D_5FBF:
	snd_note B_4, 2
	snd_len 4
	snd_off
	snd_note B_4, 2
	snd_len 10
	snd_off
	snd_note B_4, 2
	snd_len 10
	snd_off
	snd_note B_4, 2
	snd_len 10
	snd_off
	snd_note B_4, 2
	snd_len 4
	snd_off
	snd_ret
Mus3D_4_Ch3:
	snd_duty $00
	snd_env2 $20
	snd_wave SndWave07
	snd_pitchenv SndPitchEnv_494B
Trk3D_5FDE:
	snd_call Trk3D_60A4
	snd_transpose $05
	snd_call Trk3D_60A4
	snd_transpose $00
	snd_call Trk3D_60A4
	snd_note D_3, 4
	snd_len 8
	snd_off
	snd_note D_4, 4
	snd_off
	snd_note D_4
	snd_note D_3
	snd_len 8
	snd_off
	snd_note D_4, 4
	snd_off
	snd_note D_4
	snd_note D_3
	snd_len 8
	snd_off
	snd_note F_5, 4
	snd_len 8
	snd_off
	snd_note Fs_5, 4
	snd_len 20
	snd_off
	snd_loop 2
	snd_call Trk3D_60A4
	snd_transpose $05
	snd_call Trk3D_60A4
	snd_transpose $00
	snd_note G_2, 8
	snd_note G_3, 4
	snd_note B_2, 8
	snd_note B_3, 4
	snd_note D_3, 8
	snd_note D_4, 4
	snd_note As_2, 8
	snd_note As_3, 4
	snd_note C_3, 8
	snd_note C_4, 4
	snd_note F_3, 8
	snd_note F_4, 4
	snd_note E_3, 8
	snd_note E_4, 4
	snd_note A_3, 8
	snd_note A_4, 4
	snd_note G_3, 8
	snd_note G_4, 4
	snd_note D_3, 8
	snd_note D_4, 4
	snd_note C_3, 8
	snd_note C_4, 4
	snd_note A_2, 8
	snd_note A_3, 4
	snd_note Cs_3, 8
	snd_note Cs_4, 4
	snd_note D_3, 8
	snd_note D_4, 4
	snd_note B_2, 8
	snd_note B_3, 4
	snd_note G_2, 7
	snd_len 1
	snd_off
	snd_note G_3, 4
	snd_endloop
	snd_loop 16
	snd_note E_3, 6
	snd_note E_4, 2
	snd_len 1
	snd_off
	snd_note E_4, 2
	snd_len 1
	snd_off
	snd_note G_3, 6
	snd_note G_4, 2
	snd_len 1
	snd_off
	snd_note G_4, 2
	snd_len 1
	snd_off
	snd_note Fs_3, 6
	snd_note Fs_4, 2
	snd_len 1
	snd_off
	snd_note Fs_4, 2
	snd_len 1
	snd_off
	snd_note A_3, 6
	snd_note A_4, 2
	snd_len 1
	snd_off
	snd_note A_4, 2
	snd_len 1
	snd_off
	snd_endloop
	snd_note E_3, 4
	snd_len 20
	snd_off
	snd_note E_3, 4
	snd_len 20
	snd_off
	snd_note E_3, 4
	snd_len 32
	snd_off
	snd_note Ds_3, 12
	snd_note D_3, 4
	snd_len 20
	snd_off
	snd_note D_3, 4
	snd_len 20
	snd_off
	snd_note D_3, 4
	snd_off
	snd_note E_3
	snd_note Fs_3
	snd_off
	snd_note D_3
	snd_note D_4
	snd_len 8
	snd_off
	snd_note D_3, 12
	snd_jump Trk3D_5FDE
Trk3D_60A4:
	snd_note G_2, 8
	snd_note G_3, 4
	snd_note B_2, 8
	snd_note B_3, 4
	snd_note D_3, 8
	snd_note D_4, 4
	snd_note E_3, 8
	snd_note E_4, 4
	snd_note F_3, 8
	snd_note F_4, 4
	snd_note E_3, 8
	snd_note E_4, 4
	snd_note D_3, 8
	snd_note D_4, 4
	snd_note B_2, 8
	snd_note B_3, 4
	snd_ret
Mus3D_4_Ch4:
	snd_loop 12
	snd_len 12
	snd_drum 12
	snd_len 8
	snd_drum 3
	snd_len 4
	snd_drum 12
	snd_endloop
	snd_len 24
	snd_drum 7
	snd_drum 8
	snd_len 12
	snd_drum 7
	snd_drum 8
	snd_len 8
	snd_drum 9
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 6
	snd_loop 32
	snd_len 12
	snd_drum 0
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 0
	snd_endloop
	snd_loop 16
	snd_len 6
	snd_drum 0
	snd_len 3
	snd_drum 0
	snd_drum 0
	snd_len 6
	snd_drum 3
	snd_len 3
	snd_drum 0
	snd_drum 0
	snd_len 6
	snd_drum 6
	snd_len 3
	snd_drum 0
	snd_drum 0
	snd_len 6
	snd_drum 3
	snd_len 3
	snd_drum 0
	snd_drum 0
	snd_endloop
	snd_len 24
	snd_drum 7
	snd_drum 8
	snd_len 12
	snd_drum 7
	snd_drum 8
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 24
	snd_drum 11
	snd_drum 8
	snd_len 12
	snd_drum 7
	snd_drum 8
	snd_len 8
	snd_drum 9
	snd_len 4
	snd_drum 8
	snd_len 12
	snd_drum 9
	snd_jump Mus3D_4_Ch4
Mus3D_5:
	db $0F	; channel mask
	dw Mus3D_5_Ch1, Mus3D_5_Ch2, Mus3D_5_Ch3, SndNullTrack
Mus3D_5_Ch1:
	snd_tempo 68
	snd_duty $80
	snd_env $60
	snd_octenv SndOctEnv_4AD8
	snd_transpose $FE
	snd_note E_5, 5
	snd_len 1
	snd_off
	snd_note E_5, 5
	snd_len 1
	snd_off
	snd_note F_5, 5
	snd_len 1
	snd_off
	snd_note D_5, 5
	snd_len 1
	snd_off
	snd_note E_5, 5
	snd_len 7
	snd_off
	snd_note E_5, 4
	snd_len 2
	snd_off
	snd_note G_5, 4
	snd_len 2
	snd_off
	snd_note C_6, 48
	snd_end
Mus3D_5_Ch2:
	snd_duty $80
	snd_env $80
	snd_octenv SndOctEnv_4AF9
	snd_transpose $FE
	snd_note G_5, 5
	snd_len 1
	snd_off
	snd_note G_5, 5
	snd_len 1
	snd_off
	snd_note A_5, 5
	snd_len 1
	snd_off
	snd_note F_5, 5
	snd_len 1
	snd_off
	snd_note G_5, 5
	snd_len 7
	snd_off
	snd_note C_6, 4
	snd_len 2
	snd_off
	snd_note E_6, 4
	snd_len 2
	snd_off
	snd_note G_6, 48
	snd_end
Mus3D_5_Ch3:
	snd_duty $00
	snd_env2 $20
	snd_wave SndWave0B
	snd_octenv SndOctEnv_4AD8
	snd_transpose $FE
	snd_note C_4, 5
	snd_len 1
	snd_off
	snd_note C_4, 5
	snd_len 1
	snd_off
	snd_note C_4, 5
	snd_len 1
	snd_off
	snd_note C_4, 5
	snd_len 1
	snd_off
	snd_note C_4, 5
	snd_len 7
	snd_off
	snd_note G_4, 4
	snd_len 2
	snd_off
	snd_note C_5, 4
	snd_len 2
	snd_off
	snd_note E_5, 48
	snd_end
Mus3D_6:
	db $0F	; channel mask
	dw Mus3D_6_Ch1, Mus3D_6_Ch2, Mus3D_6_Ch3, Mus3D_6_Ch4
Mus3D_6_Ch1:
	snd_tempo 116
	snd_duty $80
	snd_env $60
	snd_pitchenv SndPitchEnv_49B9
Trk3D_61AE:
	snd_call Trk3D_61DC
	snd_call Trk3D_61FF
	snd_call Trk3D_621C
	snd_call Trk3D_622E
	snd_call Trk3D_6277
	snd_transpose $03
	snd_call Trk3D_622E
	snd_transpose $00
	snd_call Trk3D_6282
	snd_transpose $01
	snd_call Trk3D_61FF
	snd_call Trk3D_621C
	snd_transpose $02
	snd_call Trk3D_61FF
	snd_transpose $00
	snd_call Trk3D_6297
	snd_jump Trk3D_61AE
Trk3D_61DC:
	snd_len 96
	snd_off
	snd_len 59
	snd_off
	snd_note Fs_8, 1
	snd_note G_8, 3
	snd_len 9
	snd_off
	snd_note G_7, 4
	snd_len 20
	snd_off
	snd_note E_6, 18
	snd_note D_6
	snd_note C_6, 12
	snd_note F_6, 18
	snd_note E_6
	snd_note D_6, 12
	snd_note C_6, 18
	snd_note As_5
	snd_note A_5, 12
	snd_note Gs_5, 18
	snd_note As_5
	snd_note Gs_5, 12
	snd_ret
Trk3D_61FF:
	snd_note E_5, 6
	snd_off
	snd_note Ds_5
	snd_note E_5
	snd_off
	snd_note G_5
	snd_note C_6
	snd_off
	snd_note A_5
	snd_off
	snd_note A_5
	snd_note F_5
	snd_off
	snd_note F_5
	snd_note A_5
	snd_off
	snd_note G_5
	snd_off
	snd_note G_5
	snd_note C_5
	snd_off
	snd_note C_5
	snd_note F_5
	snd_off
	snd_note D_5, 24
	snd_note Ds_5
	snd_ret
Trk3D_621C:
	snd_note E_5, 18
	snd_note D_5
	snd_note C_5, 12
	snd_note F_5, 18
	snd_note E_5
	snd_note D_5, 12
	snd_note G_5, 18
	snd_note Fs_5
	snd_note F_5, 12
	snd_note E_5, 48
	snd_ret
Trk3D_622E:
	snd_note F_5, 47
	snd_len 1
	snd_off
	snd_note F_5, 4
	snd_len 8
	snd_off
	snd_note E_5, 4
	snd_len 2
	snd_off
	snd_note F_5, 4
	snd_len 8
	snd_off
	snd_note E_5, 4
	snd_len 2
	snd_off
	snd_note F_5, 4
	snd_len 8
	snd_off
	snd_note E_5, 47
	snd_len 1
	snd_off
	snd_note E_5, 4
	snd_len 8
	snd_off
	snd_note Ds_5, 4
	snd_len 2
	snd_off
	snd_note E_5, 4
	snd_len 8
	snd_off
	snd_note Ds_5, 4
	snd_len 2
	snd_off
	snd_note E_5, 4
	snd_len 8
	snd_off
	snd_note D_5, 47
	snd_len 1
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_note Cs_5, 4
	snd_len 2
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_note Cs_5, 4
	snd_len 2
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_ret
Trk3D_6277:
	snd_note F_5, 18
	snd_note E_5
	snd_note D_5, 12
	snd_note E_5, 4
	snd_note B_4
	snd_note C_5, 40
	snd_ret
Trk3D_6282:
	snd_note E_5, 16
	snd_note F_5, 4
	snd_note Fs_5, 3
	snd_note G_5, 18
	snd_note Gs_5, 2
	snd_note A_5, 4
	snd_note As_5, 18
	snd_note B_5, 4
	snd_note C_6, 2
	snd_note Cs_6, 25
	snd_ret
Trk3D_6297:
	snd_note Fs_5, 6
	snd_off
	snd_note F_5
	snd_note Fs_5
	snd_off
	snd_note A_5
	snd_note D_6
	snd_off
	snd_note B_5
	snd_off
	snd_note B_5
	snd_note G_5, 5
	snd_len 7
	snd_off
	snd_note G_5, 6
	snd_note G_5, 1
	snd_len 5
	snd_off
	snd_len 6
	snd_off
	snd_note A_5
	snd_off
	snd_note A_5
	snd_note Cs_5
	snd_off
	snd_note Cs_5, 5
	snd_len 1
	snd_off
	snd_note E_5, 6
	snd_off
	snd_note A_4, 11
	snd_len 1
	snd_off
	snd_note A_3, 5
	snd_len 7
	snd_off
	snd_note D_3, 5
	snd_len 19
	snd_off
	snd_note G_2, 6
	snd_len 90
	snd_off
	snd_len 96
	snd_off
	snd_note G_2, 6
	snd_len 90
	snd_off
	snd_len 96
	snd_off
	snd_ret
Mus3D_6_Ch2:
	snd_duty $80
	snd_env $F0
	snd_pitchenv SndPitchEnv_4A1B
Trk3D_62DB:
	snd_transpose $F4
	snd_call Trk3D_6310
	snd_call Trk3D_6359
	snd_call Trk3D_6310
	snd_call Trk3D_6359
	snd_transpose $00
	snd_call Trk3D_63B2
	snd_call Trk3D_63DC
	snd_transpose $03
	snd_call Trk3D_63B2
	snd_transpose $00
	snd_call Trk3D_63E7
	snd_transpose $01
	snd_call Trk3D_6310
	snd_call Trk3D_6359
	snd_transpose $02
	snd_call Trk3D_6310
	snd_transpose $00
	snd_call Trk3D_63F3
	snd_jump Trk3D_62DB
Trk3D_6310:
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
	snd_note A_4, 4
	snd_len 2
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
	snd_ret
Trk3D_6359:
	snd_note C_4, 9
	snd_len 3
	snd_off
	snd_note C_5, 4
	snd_len 2
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
	snd_note A_4, 4
	snd_len 2
	snd_off
	snd_note F_4, 4
	snd_len 2
	snd_off
	snd_note F_5, 4
	snd_len 2
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
	snd_note D_5, 4
	snd_len 2
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
	snd_note C_5, 4
	snd_len 2
	snd_off
	snd_note C_4, 4
	snd_len 2
	snd_off
	snd_note Gs_5, 4
	snd_len 2
	snd_off
	snd_note C_4, 4
	snd_len 8
	snd_off
	snd_note Ds_5, 9
	snd_len 3
	snd_off
	snd_ret
Trk3D_63B2:
	snd_note D_3, 18
	snd_note F_3
	snd_note A_3, 12
	snd_note G_3, 18
	snd_note B_3
	snd_note D_4, 12
	snd_note C_3, 18
	snd_note E_3, 17
	snd_len 1
	snd_off
	snd_note G_3, 12
	snd_note F_3, 18
	snd_note A_3
	snd_note C_4, 12
	snd_note B_2, 17
	snd_len 2
	snd_off
	snd_note Cs_2, 16
	snd_len 1
	snd_off
	snd_note D_2, 12
	snd_note F_3, 18
	snd_note E_3, 16
	snd_len 2
	snd_off
	snd_note D_3, 12
	snd_ret
Trk3D_63DC:
	snd_note C_3, 18
	snd_note E_3
	snd_note G_3, 12
	snd_note C_4, 18
	snd_note D_3
	snd_note E_3, 12
	snd_ret
Trk3D_63E7:
	snd_note Ds_3, 18
	snd_note G_3
	snd_note As_3, 12
	snd_note Cs_4, 19
	snd_note E_4, 16
	snd_note G_4, 13
	snd_ret
Trk3D_63F3:
	snd_note D_4, 9
	snd_len 3
	snd_off
	snd_note D_5, 4
	snd_len 2
	snd_off
	snd_note Cs_5, 4
	snd_len 2
	snd_off
	snd_note D_4, 9
	snd_len 3
	snd_off
	snd_note C_5, 9
	snd_len 3
	snd_off
	snd_note G_4, 4
	snd_len 2
	snd_off
	snd_note B_4, 4
	snd_len 2
	snd_off
	snd_note G_4, 4
	snd_len 2
	snd_off
	snd_note G_5, 4
	snd_len 2
	snd_off
	snd_note G_4, 4
	snd_len 8
	snd_off
	snd_note E_5, 9
	snd_len 3
	snd_off
	snd_note A_4, 9
	snd_len 3
	snd_off
	snd_note A_5, 4
	snd_len 2
	snd_off
	snd_note E_5, 4
	snd_len 2
	snd_off
	snd_note A_3, 9
	snd_len 3
	snd_off
	snd_note A_4, 9
	snd_len 3
	snd_off
	snd_note D_4, 4
	snd_len 8
	snd_off
	snd_note D_4, 4
	snd_len 8
	snd_off
	snd_note D_4, 4
	snd_len 20
	snd_off
	snd_note G_3, 6
	snd_len 90
	snd_off
	snd_len 84
	snd_off
	snd_note G_4, 12
	snd_note G_3, 6
	snd_len 90
	snd_off
	snd_note G_3, 6
	snd_off
	snd_note A_4
	snd_off
	snd_note Gs_4
	snd_len 1
	snd_off
	snd_note A_4, 6
	snd_len 5
	snd_off
	snd_note D_3, 6
	snd_note D_4
	snd_len 1
	snd_off
	snd_note Fs_3, 5
	snd_len 1
	snd_off
	snd_note A_3, 5
	snd_len 6
	snd_off
	snd_note G_3, 24
	snd_ret
Mus3D_6_Ch3:
	snd_duty $00
	snd_env2 $20
	snd_wave SndWave0E
Trk3D_646E:
	snd_call Trk3D_6492
	snd_call Trk3D_64B0
	snd_call Trk3D_6492
	snd_call Trk3D_64B0
	snd_call Trk3D_64CE
	snd_transpose $01
	snd_call Trk3D_6492
	snd_call Trk3D_64B0
	snd_transpose $02
	snd_call Trk3D_6492
	snd_transpose $00
	snd_call Trk3D_6580
	snd_jump Trk3D_646E
Trk3D_6492:
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
	snd_ret
Trk3D_64B0:
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
	snd_note C_5, 36
	snd_len 12
	snd_off
	snd_ret
Trk3D_64CE:
	snd_note A_5, 4
	snd_len 8
	snd_off
	snd_note Gs_5, 4
	snd_len 2
	snd_off
	snd_note A_5, 4
	snd_len 8
	snd_off
	snd_note Gs_5, 4
	snd_len 2
	snd_off
	snd_note A_5, 4
	snd_len 8
	snd_off
	snd_note C_6, 18
	snd_note B_5
	snd_note A_5, 12
	snd_note G_5, 4
	snd_len 8
	snd_off
	snd_note Fs_5, 4
	snd_len 2
	snd_off
	snd_note G_5, 4
	snd_len 8
	snd_off
	snd_note Fs_5, 4
	snd_len 2
	snd_off
	snd_note G_5, 4
	snd_len 8
	snd_off
	snd_note B_5, 18
	snd_note A_5
	snd_note G_5, 12
	snd_note F_5, 4
	snd_len 8
	snd_off
	snd_note E_5, 4
	snd_len 2
	snd_off
	snd_note F_5, 4
	snd_len 8
	snd_off
	snd_note E_5, 4
	snd_len 2
	snd_off
	snd_note F_5, 4
	snd_len 8
	snd_off
	snd_note A_5, 18
	snd_note G_5
	snd_note F_5, 12
	snd_note G_5, 4
	snd_note D_5
	snd_note E_5, 86
	snd_len 2
	snd_off
	snd_note Gs_5, 4
	snd_len 8
	snd_off
	snd_note G_5, 4
	snd_len 2
	snd_off
	snd_note Gs_5, 4
	snd_len 8
	snd_off
	snd_note G_5, 4
	snd_len 2
	snd_off
	snd_note Gs_5, 4
	snd_len 8
	snd_off
	snd_note C_6, 18
	snd_note As_5
	snd_note Gs_5, 12
	snd_note G_5, 4
	snd_len 8
	snd_off
	snd_note Fs_5, 4
	snd_len 2
	snd_off
	snd_note G_5, 4
	snd_len 8
	snd_off
	snd_note Fs_5, 4
	snd_len 2
	snd_off
	snd_note G_5, 4
	snd_len 8
	snd_off
	snd_note As_5, 18
	snd_note Gs_5
	snd_note G_5, 12
	snd_note F_5, 4
	snd_len 8
	snd_off
	snd_note E_5, 4
	snd_len 2
	snd_off
	snd_note F_5, 4
	snd_len 8
	snd_off
	snd_note E_5, 4
	snd_len 2
	snd_off
	snd_note F_5, 4
	snd_len 8
	snd_off
	snd_note Gs_5, 18
	snd_note G_5
	snd_note F_5, 12
	snd_note E_5, 16
	snd_note Ds_5, 4
	snd_note D_5, 2
	snd_note Cs_5, 18
	snd_note C_5, 4
	snd_note B_4, 3
	snd_note As_4, 16
	snd_note A_4, 4
	snd_note Gs_4, 5
	snd_note G_4, 24
	snd_ret
Trk3D_6580:
	snd_note A_5, 6
	snd_off
	snd_note Gs_5
	snd_note A_5
	snd_off
	snd_note D_6
	snd_note Fs_6
	snd_off
	snd_note E_6
	snd_off
	snd_note E_6
	snd_note B_5, 5
	snd_len 7
	snd_off
	snd_note B_5, 6
	snd_note B_5, 1
	snd_len 5
	snd_off
	snd_len 6
	snd_off
	snd_note D_6
	snd_off
	snd_note D_6
	snd_note E_5
	snd_off
	snd_note E_5, 5
	snd_len 1
	snd_off
	snd_note A_5, 4
	snd_len 8
	snd_off
	snd_note D_5, 12
	snd_note D_5, 2
	snd_len 4
	snd_off
	snd_len 6
	snd_off
	snd_note D_4
	snd_len 18
	snd_off
	snd_note G_4, 6
	snd_len 90
	snd_off
	snd_len 96
	snd_off
	snd_note G_4, 6
	snd_len 90
	snd_off
	snd_len 96
	snd_off
	snd_ret
Mus3D_6_Ch4:
	snd_loop 8
	snd_call Trk3D_65D8
	snd_endloop
	snd_loop 8
	snd_call Trk3D_65F0
	snd_endloop
	snd_loop 7
	snd_call Trk3D_65D8
	snd_endloop
	snd_call Trk3D_6608
	snd_call Trk3D_661A
	snd_jump Mus3D_6_Ch4
Trk3D_65D8:
	snd_len 12
	snd_drum 5
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 5
	snd_len 8
	snd_drum 8
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 5
	snd_drum 5
	snd_len 7
	snd_drum 5
	snd_len 5
	snd_drum 3
	snd_len 8
	snd_drum 9
	snd_len 4
	snd_drum 5
	snd_ret
Trk3D_65F0:
	snd_len 12
	snd_drum 5
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 5
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 5
	snd_drum 5
	snd_len 7
	snd_drum 5
	snd_len 5
	snd_drum 0
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 5
	snd_ret
Trk3D_6608:
	snd_len 12
	snd_drum 5
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 5
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 0
	snd_len 12
	snd_drum 5
	snd_drum 4
	snd_len 24
	snd_drum 5
	snd_ret
Trk3D_661A:
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 12
	snd_drum 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 5
	snd_len 12
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 12
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 7
	snd_len 12
	snd_drum 0
	snd_drum 7
	snd_len 8
	snd_drum 0
	snd_len 4
	snd_drum 8
	snd_len 12
	snd_drum 8
	snd_drum 9
	snd_len 8
	snd_drum 8
	snd_len 4
	snd_drum 9
	snd_len 12
	snd_drum 9
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 12
	snd_drum 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 5
	snd_len 12
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_len 12
	snd_drum 4
	snd_drum 4
	snd_drum 8
	snd_len 8
	snd_drum 8
	snd_len 12
	snd_drum 8
	snd_len 4
	snd_drum 8
	snd_len 8
	snd_drum 8
	snd_len 4
	snd_drum 9
	snd_len 12
	snd_drum 4
	snd_drum 11
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 4
	snd_ret
Mus3D_7:
	db $0F	; channel mask
	dw Mus3D_7_Ch1, Mus3D_7_Ch2, Mus3D_7_Ch3, Mus3D_7_Ch4
Mus3D_7_Ch1:
	snd_tempo 134
	snd_duty $80
	snd_env $50
	snd_len 1
	snd_off
Trk3D_6681:
	snd_note Fs_4, 12
	snd_note Fs_5, 5
	snd_len 1
	snd_off
	snd_note A_5, 5
	snd_len 1
	snd_off
	snd_note B_5, 5
	snd_len 7
	snd_off
	snd_note D_6, 5
	snd_len 7
	snd_off
	snd_note E_6, 5
	snd_len 7
	snd_off
	snd_note Fs_6, 5
	snd_len 1
	snd_off
	snd_note D_6, 3
	snd_off
	snd_note Fs_5, 5
	snd_len 7
	snd_off
	snd_note A_5, 5
	snd_len 7
	snd_off
	snd_note D_5, 12
	snd_note A_5, 5
	snd_len 1
	snd_off
	snd_note B_5, 5
	snd_len 1
	snd_off
	snd_note D_6, 5
	snd_len 7
	snd_off
	snd_note E_6, 5
	snd_len 7
	snd_off
	snd_note Fs_6, 5
	snd_len 7
	snd_off
	snd_note A_6, 5
	snd_len 7
	snd_off
	snd_note Fs_5, 5
	snd_len 7
	snd_off
	snd_note A_5, 5
	snd_len 7
	snd_off
	snd_note G_4, 12
	snd_note Fs_5, 5
	snd_len 1
	snd_off
	snd_note A_5, 5
	snd_len 1
	snd_off
	snd_note B_5, 5
	snd_len 7
	snd_off
	snd_note D_6, 5
	snd_len 7
	snd_off
	snd_note E_6, 5
	snd_len 7
	snd_off
	snd_note Fs_6, 5
	snd_len 1
	snd_off
	snd_note D_6, 3
	snd_off
	snd_note E_5, 5
	snd_len 7
	snd_off
	snd_note B_5, 5
	snd_len 7
	snd_off
	snd_note G_4, 12
	snd_note Fs_5, 5
	snd_len 1
	snd_off
	snd_note A_5, 5
	snd_len 1
	snd_off
	snd_note B_5, 5
	snd_len 7
	snd_off
	snd_note D_6, 5
	snd_len 7
	snd_off
	snd_note E_6, 5
	snd_len 7
	snd_off
	snd_note Fs_6, 5
	snd_len 7
	snd_off
	snd_note E_5, 5
	snd_len 7
	snd_off
	snd_note B_5, 5
	snd_len 7
	snd_off
	snd_note Fs_4, 12
	snd_note Fs_5, 5
	snd_len 1
	snd_off
	snd_note A_5, 5
	snd_len 1
	snd_off
	snd_note B_5, 5
	snd_len 7
	snd_off
	snd_note D_6, 5
	snd_len 7
	snd_off
	snd_note E_6, 5
	snd_len 7
	snd_off
	snd_note Fs_6, 5
	snd_len 7
	snd_off
	snd_note Fs_5, 5
	snd_len 7
	snd_off
	snd_note A_5, 5
	snd_len 7
	snd_off
	snd_note Fs_4, 12
	snd_note Fs_5, 5
	snd_len 1
	snd_off
	snd_note A_5, 5
	snd_len 1
	snd_off
	snd_note B_5, 5
	snd_len 7
	snd_off
	snd_note D_6, 5
	snd_len 7
	snd_off
	snd_note E_6, 5
	snd_len 43
	snd_off
	snd_note A_5, 5
	snd_len 7
	snd_off
	snd_note A_5
	snd_len 5
	snd_off
	snd_note B_5, 7
	snd_len 5
	snd_off
	snd_note A_5, 7
	snd_len 5
	snd_off
	snd_note D_6, 9
	snd_len 15
	snd_off
	snd_note B_5, 5
	snd_len 19
	snd_off
	snd_note Cs_6, 7
	snd_len 5
	snd_off
	snd_note C_6, 8
	snd_len 4
	snd_off
	snd_note B_5, 7
	snd_len 5
	snd_off
	snd_note A_5, 8
	snd_len 4
	snd_off
	snd_note Fs_5, 3
	snd_len 9
	snd_off
	snd_note E_5, 3
	snd_len 9
	snd_off
	snd_note B_4, 3
	snd_len 9
	snd_off
	snd_note D_5, 3
	snd_len 9
	snd_off
	snd_jump Trk3D_6681
Mus3D_7_Ch2:
	snd_duty $40
	snd_env $87
	snd_octenv SndOctEnv_4AD8
Trk3D_6788:
	snd_note A_6, 36
	snd_note Fs_6, 5
	snd_len 7
	snd_off
	snd_note A_6, 44
	snd_len 4
	snd_off
	snd_note B_6, 18
	snd_note D_7, 5
	snd_len 1
	snd_off
	snd_note D_7, 8
	snd_len 4
	snd_off
	snd_note B_6, 9
	snd_len 3
	snd_off
	snd_note A_6, 9
	snd_len 15
	snd_off
	snd_note Fs_6, 9
	snd_len 15
	snd_off
	snd_note E_6, 36
	snd_note D_6, 6
	snd_off
	snd_note E_6, 43
	snd_len 5
	snd_off
	snd_note Fs_6, 18
	snd_note A_6, 5
	snd_len 1
	snd_off
	snd_note A_6, 8
	snd_len 4
	snd_off
	snd_note Fs_6, 10
	snd_len 2
	snd_off
	snd_note B_6, 8
	snd_len 16
	snd_off
	snd_note A_6, 10
	snd_len 14
	snd_off
	snd_note Fs_6, 18
	snd_note E_6, 6
	snd_note D_6, 8
	snd_len 4
	snd_off
	snd_note E_6, 8
	snd_len 4
	snd_off
	snd_note Fs_6, 36
	snd_note A_6, 9
	snd_len 3
	snd_off
	snd_note B_6, 18
	snd_note A_6, 6
	snd_note Fs_6, 8
	snd_len 4
	snd_off
	snd_note A_6, 8
	snd_len 4
	snd_off
	snd_note B_6, 48
	snd_note A_6, 8
	snd_len 4
	snd_off
	snd_note A_6, 8
	snd_len 4
	snd_off
	snd_note B_6, 8
	snd_len 4
	snd_off
	snd_note A_6, 8
	snd_len 4
	snd_off
	snd_note D_7, 9
	snd_len 15
	snd_off
	snd_note B_6, 7
	snd_len 17
	snd_off
	snd_note A_6, 7
	snd_len 5
	snd_off
	snd_note A_6, 8
	snd_len 4
	snd_off
	snd_note B_6, 7
	snd_len 5
	snd_off
	snd_note A_6, 8
	snd_len 4
	snd_off
	snd_note D_6, 9
	snd_len 39
	snd_off
	snd_jump Trk3D_6788
Mus3D_7_Ch3:
	snd_wave SndWave08
	snd_env2 $20
	snd_pitchenv SndPitchEnv_4959
	snd_len 1
	snd_off
Trk3D_6820:
	snd_loop 2
	snd_note D_3, 12
	snd_note D_4, 3
	snd_off
	snd_note D_4
	snd_off
	snd_note B_3, 6
	snd_off
	snd_note Fs_3
	snd_off
	snd_note A_3, 7
	snd_len 5
	snd_off
	snd_note D_3
	snd_len 7
	snd_off
	snd_note B_3, 3
	snd_off
	snd_note D_3, 6
	snd_note A_3, 5
	snd_len 1
	snd_off
	snd_note A_3, 5
	snd_len 1
	snd_off
	snd_endloop
	snd_loop 2
	snd_note E_3, 12
	snd_note E_4, 3
	snd_off
	snd_note E_4
	snd_off
	snd_note D_4, 6
	snd_off
	snd_note Fs_3
	snd_off
	snd_note A_3, 7
	snd_len 5
	snd_off
	snd_note E_3
	snd_len 7
	snd_off
	snd_note B_3, 4
	snd_len 2
	snd_off
	snd_note E_3, 6
	snd_note A_3, 5
	snd_len 1
	snd_off
	snd_note A_3, 5
	snd_len 1
	snd_off
	snd_endloop
	snd_note D_3, 12
	snd_note D_4, 3
	snd_off
	snd_note D_4
	snd_off
	snd_note B_3, 6
	snd_off
	snd_note Fs_3
	snd_off
	snd_note A_3
	snd_off
	snd_note D_3, 4
	snd_len 8
	snd_off
	snd_note B_3, 5
	snd_len 1
	snd_off
	snd_note D_3, 5
	snd_len 1
	snd_off
	snd_note A_3, 5
	snd_len 1
	snd_off
	snd_note A_3, 5
	snd_len 1
	snd_off
	snd_note B_2, 5
	snd_len 7
	snd_off
	snd_note B_2, 5
	snd_len 7
	snd_off
	snd_note Cs_3, 5
	snd_len 7
	snd_off
	snd_note Cs_3, 6
	snd_off
	snd_note D_3, 7
	snd_len 5
	snd_off
	snd_note A_4, 4
	snd_len 8
	snd_off
	snd_note Fs_4, 4
	snd_len 8
	snd_off
	snd_note A_4, 4
	snd_len 8
	snd_off
	snd_note E_3, 4
	snd_len 8
	snd_off
	snd_note E_4, 5
	snd_len 7
	snd_off
	snd_note D_4, 4
	snd_len 8
	snd_off
	snd_note Fs_3, 5
	snd_len 7
	snd_off
	snd_note G_3, 6
	snd_len 42
	snd_off
	snd_note A_3, 4
	snd_len 8
	snd_off
	snd_note B_3, 4
	snd_len 8
	snd_off
	snd_note C_4, 5
	snd_len 7
	snd_off
	snd_note Cs_4, 5
	snd_len 7
	snd_off
	snd_note D_4, 5
	snd_len 19
	snd_off
	snd_note D_3, 7
	snd_len 17
	snd_off
	snd_jump Trk3D_6820
Mus3D_7_Ch4:
	snd_len 1
	snd_off
Trk3D_68D9:
	snd_len 5
	snd_drum 6
	snd_len 7
	snd_off
	snd_len 6
	snd_drum 2
	snd_off
	snd_len 5
	snd_drum 4
	snd_len 7
	snd_off
	snd_len 5
	snd_drum 2
	snd_len 7
	snd_off
	snd_len 5
	snd_drum 6
	snd_len 7
	snd_off
	snd_len 5
	snd_drum 0
	snd_len 7
	snd_off
	snd_len 5
	snd_drum 4
	snd_len 7
	snd_off
	snd_len 5
	snd_drum 4
	snd_len 7
	snd_off
	snd_jump Trk3D_68D9
Mus3D_8:
	db $0F	; channel mask
	dw Mus3D_8_Ch1, Mus3D_8_Ch2, Mus3D_8_Ch3, Mus3D_8_Ch4
Mus3D_8_Ch1:
	snd_tempo 120
	snd_duty $80
	snd_env $60
	snd_loop 4
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
Trk3D_6931:
	snd_loop 2
	snd_note Fs_6, 4
	snd_len 8
	snd_off
	snd_note Fs_6, 4
	snd_len 8
	snd_off
	snd_note Gs_6, 6
	snd_note Ds_6, 4
	snd_len 8
	snd_off
	snd_note Fs_6, 4
	snd_len 8
	snd_off
	snd_note Gs_6, 4
	snd_len 8
	snd_off
	snd_note Ds_6, 4
	snd_len 2
	snd_off
	snd_note Fs_6, 4
	snd_len 2
	snd_off
	snd_note Gs_5, 3
	snd_off
	snd_note B_5
	snd_off
	snd_note Gs_5
	snd_off
	snd_note Fs_6, 4
	snd_len 8
	snd_off
	snd_note Fs_6, 4
	snd_len 8
	snd_off
	snd_note Gs_6, 6
	snd_note Ds_6, 4
	snd_len 8
	snd_off
	snd_note Fs_6, 4
	snd_len 8
	snd_off
	snd_note Gs_6, 4
	snd_len 8
	snd_off
	snd_note Ds_6, 4
	snd_len 2
	snd_off
	snd_note Fs_6, 4
	snd_len 2
	snd_off
	snd_note Gs_5, 3
	snd_off
	snd_note B_5
	snd_off
	snd_note Gs_5
	snd_off
	snd_note Fs_6, 4
	snd_len 8
	snd_off
	snd_note Fs_6, 4
	snd_len 8
	snd_off
	snd_note Gs_6, 6
	snd_note Ds_6, 4
	snd_len 8
	snd_off
	snd_note Fs_6, 4
	snd_len 8
	snd_off
	snd_note Gs_6, 4
	snd_len 8
	snd_off
	snd_note Ds_6, 4
	snd_len 2
	snd_off
	snd_note Fs_6, 4
	snd_len 2
	snd_off
	snd_note Gs_5, 3
	snd_off
	snd_note B_5
	snd_off
	snd_note Gs_5
	snd_off
	snd_note Ds_6, 4
	snd_len 8
	snd_off
	snd_note Ds_6, 4
	snd_len 8
	snd_off
	snd_note D_6, 6
	snd_note Ds_6, 3
	snd_len 9
	snd_off
	snd_note B_5, 4
	snd_len 8
	snd_off
	snd_note Fs_5, 4
	snd_len 8
	snd_off
	snd_note Gs_5, 4
	snd_len 2
	snd_off
	snd_note Fs_5, 4
	snd_len 2
	snd_off
	snd_note B_5, 3
	snd_off
	snd_note Ds_6
	snd_off
	snd_note B_5
	snd_off
	snd_note Ds_6, 4
	snd_len 8
	snd_off
	snd_note B_5, 4
	snd_len 8
	snd_off
	snd_note Ds_6, 6
	snd_note Gs_5, 3
	snd_len 9
	snd_off
	snd_note B_5, 4
	snd_len 8
	snd_off
	snd_note Ds_6, 4
	snd_len 8
	snd_off
	snd_note Gs_5, 6
	snd_note B_5, 4
	snd_len 2
	snd_off
	snd_note Gs_5, 3
	snd_off
	snd_note Cs_6, 6
	snd_note D_6
	snd_note Ds_6, 4
	snd_len 8
	snd_off
	snd_note B_5, 4
	snd_len 8
	snd_off
	snd_note Cs_6, 4
	snd_len 2
	snd_off
	snd_note Fs_5, 3
	snd_len 9
	snd_off
	snd_note Ds_5, 4
	snd_len 8
	snd_off
	snd_note E_5, 4
	snd_len 8
	snd_off
	snd_note Cs_5, 3
	snd_off
	snd_note Gs_4, 4
	snd_len 2
	snd_off
	snd_note Gs_5, 3
	snd_off
	snd_note B_4, 6
	snd_note Cs_5
	snd_note As_4, 4
	snd_len 8
	snd_off
	snd_note B_4, 4
	snd_len 8
	snd_off
	snd_note C_5, 4
	snd_len 2
	snd_off
	snd_note Cs_5, 5
	snd_len 7
	snd_off
	snd_note Ds_5, 4
	snd_len 8
	snd_off
	snd_note E_5, 4
	snd_len 8
	snd_off
	snd_note F_5, 4
	snd_len 2
	snd_off
	snd_note Fs_5, 4
	snd_len 8
	snd_off
	snd_note Fs_5, 5
	snd_len 7
	snd_off
	snd_note Fs_5, 4
	snd_len 8
	snd_off
	snd_note Fs_5, 4
	snd_len 8
	snd_off
	snd_note Gs_5, 4
	snd_len 2
	snd_off
	snd_note Ds_5, 3
	snd_len 9
	snd_off
	snd_note Fs_5, 4
	snd_len 8
	snd_off
	snd_note Gs_5, 4
	snd_len 8
	snd_off
	snd_note Ds_5, 3
	snd_off
	snd_note Fs_5, 4
	snd_len 2
	snd_off
	snd_note Gs_4, 3
	snd_off
	snd_note B_4, 5
	snd_len 1
	snd_off
	snd_note Gs_4, 5
	snd_len 1
	snd_off
	snd_endloop
	snd_note B_4, 4
	snd_len 8
	snd_off
	snd_note Gs_5, 4
	snd_len 8
	snd_off
	snd_note Fs_5, 4
	snd_len 2
	snd_off
	snd_note Cs_5, 3
	snd_len 9
	snd_off
	snd_note Ds_5, 4
	snd_len 8
	snd_off
	snd_note Fs_5, 4
	snd_len 8
	snd_off
	snd_note Cs_5, 4
	snd_len 2
	snd_off
	snd_note Ds_5, 4
	snd_len 2
	snd_off
	snd_note Gs_4, 3
	snd_off
	snd_note B_4
	snd_off
	snd_note Gs_4
	snd_off
	snd_note B_4, 4
	snd_len 8
	snd_off
	snd_note Gs_5, 4
	snd_len 8
	snd_off
	snd_note Fs_5, 4
	snd_len 2
	snd_off
	snd_note Cs_5, 3
	snd_len 9
	snd_off
	snd_note Ds_5, 4
	snd_len 8
	snd_off
	snd_note Fs_5, 4
	snd_len 8
	snd_off
	snd_note Cs_5, 4
	snd_len 2
	snd_off
	snd_note Ds_5, 4
	snd_len 2
	snd_off
	snd_note Gs_4, 3
	snd_off
	snd_note B_4
	snd_off
	snd_note Gs_4
	snd_off
	snd_note Ds_5, 4
	snd_len 8
	snd_off
	snd_note B_5, 4
	snd_len 8
	snd_off
	snd_note Gs_5, 4
	snd_len 2
	snd_off
	snd_note Ds_5, 3
	snd_len 9
	snd_off
	snd_note B_4, 4
	snd_len 8
	snd_off
	snd_note Ds_5, 4
	snd_len 8
	snd_off
	snd_note B_4, 3
	snd_off
	snd_note Ds_5, 4
	snd_len 2
	snd_off
	snd_note Gs_5, 3
	snd_off
	snd_note B_5, 5
	snd_len 1
	snd_off
	snd_note Ds_6, 5
	snd_len 1
	snd_off
	snd_note B_5, 4
	snd_len 8
	snd_off
	snd_note Ds_6, 4
	snd_len 8
	snd_off
	snd_note Fs_6, 4
	snd_len 2
	snd_off
	snd_note Cs_6, 3
	snd_len 9
	snd_off
	snd_note Gs_5, 4
	snd_len 8
	snd_off
	snd_note B_5, 4
	snd_len 8
	snd_off
	snd_note Cs_6, 3
	snd_off
	snd_note Gs_5, 6
	snd_note Fs_5
	snd_note Ds_5
	snd_note Gs_4
	snd_note B_5, 18
	snd_note Gs_5
	snd_note F_5, 12
	snd_note Gs_5, 24
	snd_note Ds_6
	snd_note As_5, 48
	snd_note Gs_5, 47
	snd_len 1
	snd_off
	snd_note Fs_5, 17
	snd_len 2
	snd_off
	snd_note Fs_5, 16
	snd_len 2
	snd_off
	snd_note F_5, 10
	snd_len 1
	snd_off
	snd_note E_5, 45
	snd_len 12
	snd_off
	snd_note As_5, 4
	snd_off
	snd_note As_5
	snd_off
	snd_note As_5, 5
	snd_len 11
	snd_off
	snd_note As_5, 4
	snd_off
	snd_note As_5, 6
	snd_len 9
	snd_off
	snd_note Cs_5, 3
	snd_len 5
	snd_off
	snd_note Cs_5, 6
	snd_len 18
	snd_off
	snd_note Ds_5, 4
	snd_len 8
	snd_off
	snd_note Ds_5, 4
	snd_len 8
	snd_off
	snd_note Fs_5, 6
	snd_note Ds_5, 5
	snd_len 7
	snd_off
	snd_note Gs_5, 4
	snd_len 8
	snd_off
	snd_note Gs_5, 4
	snd_len 8
	snd_off
	snd_note A_5, 4
	snd_len 2
	snd_off
	snd_note As_5, 5
	snd_len 7
	snd_off
	snd_note As_5, 5
	snd_len 7
	snd_off
	snd_note Ds_5, 4
	snd_len 8
	snd_off
	snd_note Ds_5, 4
	snd_len 8
	snd_off
	snd_note Fs_5, 6
	snd_note Ds_5, 5
	snd_len 7
	snd_off
	snd_note Gs_5, 4
	snd_len 8
	snd_off
	snd_note Gs_5, 4
	snd_len 8
	snd_off
	snd_note A_5, 4
	snd_len 2
	snd_off
	snd_note As_5, 5
	snd_len 7
	snd_off
	snd_note As_5, 5
	snd_len 7
	snd_off
	snd_note Ds_5, 4
	snd_len 8
	snd_off
	snd_note Ds_5, 4
	snd_len 8
	snd_off
	snd_note Fs_5, 6
	snd_note Ds_5, 5
	snd_len 7
	snd_off
	snd_note Gs_5, 4
	snd_len 8
	snd_off
	snd_note Gs_5, 4
	snd_len 8
	snd_off
	snd_note A_5, 4
	snd_len 2
	snd_off
	snd_note As_5, 5
	snd_len 7
	snd_off
	snd_note As_5, 5
	snd_len 7
	snd_off
	snd_note Ds_5, 5
	snd_len 7
	snd_off
	snd_note Ds_5, 5
	snd_len 7
	snd_off
	snd_note Ds_5, 5
	snd_len 1
	snd_off
	snd_note Ds_5, 5
	snd_len 7
	snd_off
	snd_note Ds_5, 5
	snd_len 49
	snd_off
	snd_jump Trk3D_6931
Unused3D_6BA8:
	snd_end
Mus3D_8_Ch2:
	snd_duty $80
	snd_env $80
	snd_pitchenv SndPitchEnv_499B
	snd_note Ds_5, 96
	snd_note Ds_5, 76
	snd_len 2
	snd_off
	snd_note D_5, 18
	snd_note Ds_5, 96
	snd_note Ds_5, 48
	snd_len 24
	snd_off
	snd_note B_5, 4
	snd_len 8
	snd_off
	snd_note Cs_6, 4
	snd_len 8
	snd_off
Trk3D_6BC6:
	snd_loop 2
	snd_note Ds_6, 22
	snd_len 2
	snd_off
	snd_note Fs_5, 16
	snd_len 2
	snd_off
	snd_note Gs_5, 29
	snd_len 1
	snd_off
	snd_note B_5, 4
	snd_len 8
	snd_off
	snd_note Cs_6, 4
	snd_len 8
	snd_off
	snd_note Ds_6, 22
	snd_len 2
	snd_off
	snd_note Fs_5, 16
	snd_len 2
	snd_off
	snd_note Gs_5, 29
	snd_len 1
	snd_off
	snd_note B_5, 4
	snd_len 8
	snd_off
	snd_note Cs_6, 4
	snd_len 8
	snd_off
	snd_note Ds_6, 22
	snd_len 2
	snd_off
	snd_note Fs_5, 16
	snd_len 2
	snd_off
	snd_note Gs_5, 24
	snd_len 6
	snd_off
	snd_note B_5, 4
	snd_len 7
	snd_off
	snd_note G_6, 1
	snd_note Gs_6, 4
	snd_len 8
	snd_off
	snd_note Fs_6, 72
	snd_len 24
	snd_off
	snd_note Fs_6, 4
	snd_len 8
	snd_off
	snd_note Ds_6, 4
	snd_len 8
	snd_off
	snd_note Fs_6, 6
	snd_note Gs_6
	snd_off
	snd_note B_6, 30
	snd_note Gs_6, 18
	snd_len 6
	snd_off
	snd_note Fs_6, 4
	snd_len 8
	snd_off
	snd_note Cs_6, 4
	snd_len 8
	snd_off
	snd_note Ds_6, 6
	snd_off
	snd_note B_5
	snd_note Gs_5, 28
	snd_len 2
	snd_off
	snd_note E_5, 4
	snd_len 8
	snd_off
	snd_note F_5, 4
	snd_len 8
	snd_off
	snd_note Fs_5, 4
	snd_len 8
	snd_off
	snd_note Fs_5, 4
	snd_len 8
	snd_off
	snd_note G_5, 4
	snd_len 2
	snd_off
	snd_note G_5, 4
	snd_len 8
	snd_off
	snd_note Gs_5, 4
	snd_len 8
	snd_off
	snd_note Gs_5, 4
	snd_len 8
	snd_off
	snd_note Gs_5, 2
	snd_len 4
	snd_off
	snd_note As_5, 6
	snd_off
	snd_note As_5, 4
	snd_len 8
	snd_off
	snd_note B_5, 48
	snd_len 24
	snd_off
	snd_note B_5, 4
	snd_len 8
	snd_off
	snd_note Cs_6, 4
	snd_len 8
	snd_off
	snd_endloop
	snd_note Ds_6, 22
	snd_len 2
	snd_off
	snd_note Gs_6, 16
	snd_len 2
	snd_off
	snd_note Fs_6, 28
	snd_len 2
	snd_off
	snd_note Ds_6, 4
	snd_len 8
	snd_off
	snd_note Cs_6, 4
	snd_len 8
	snd_off
	snd_note Ds_6, 22
	snd_len 2
	snd_off
	snd_note Gs_6, 16
	snd_len 2
	snd_off
	snd_note Fs_6, 28
	snd_len 2
	snd_off
	snd_note Ds_6, 4
	snd_len 8
	snd_off
	snd_note Cs_6, 4
	snd_len 8
	snd_off
	snd_note Ds_6, 18
	snd_note Gs_6
	snd_note Ds_6, 11
	snd_len 1
	snd_off
	snd_note As_6, 18
	snd_note Gs_6
	snd_note As_6, 11
	snd_len 1
	snd_off
	snd_note B_6, 18
	snd_note As_6
	snd_note Gs_6, 12
	snd_note Ds_6, 46
	snd_len 2
	snd_off
	snd_note Ds_6, 18
	snd_note B_5
	snd_note Gs_5, 12
	snd_note B_5, 22
	snd_note Fs_6, 2
	snd_note Gs_6, 24
	snd_note Fs_6, 48
	snd_note B_5, 22
	snd_note Ds_6, 2
	snd_note E_6, 24
	snd_note Ds_6, 18
	snd_note As_5
	snd_note A_5, 12
	snd_note Gs_5, 18
	snd_note Cs_6
	snd_note B_5, 12
	snd_len 8
	snd_off
	snd_note Fs_6, 4
	snd_off
	snd_note Fs_6
	snd_off
	snd_note Fs_6
	snd_len 12
	snd_off
	snd_note Fs_6, 4
	snd_off
	snd_note Fs_6
	snd_len 12
	snd_off
	snd_note E_5, 4
	snd_off
	snd_note E_5
	snd_len 20
	snd_off
	snd_note B_5, 1
	snd_len 11
	snd_off
	snd_note B_5, 1
	snd_len 11
	snd_off
	snd_note B_6, 2
	snd_len 4
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
	snd_note Cs_7, 2
	snd_len 10
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
	snd_note B_6, 2
	snd_len 4
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
	snd_note Cs_7, 2
	snd_len 10
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
	snd_note B_6, 2
	snd_len 4
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
	snd_note Cs_7, 2
	snd_len 10
	snd_off
	snd_note Fs_6, 1
	snd_len 11
	snd_off
	snd_note B_6, 5
	snd_len 7
	snd_off
	snd_note B_6, 4
	snd_len 8
	snd_off
	snd_note B_6, 4
	snd_len 2
	snd_off
	snd_note B_6, 4
	snd_len 8
	snd_off
	snd_note B_6, 4
	snd_len 50
	snd_off
	snd_jump Trk3D_6BC6
Mus3D_8_Ch3:
	snd_duty $00
	snd_env2 $20
	snd_wave SndWave08
	snd_note B_3, 96
	snd_note B_3, 72
	snd_len 6
	snd_off
	snd_note Fs_3, 18
	snd_note B_3, 96
	snd_note B_3, 48
	snd_len 48
	snd_off
Trk3D_6D6E:
	snd_pitchenv SndPitchEnv_4AD7
	snd_loop 2
	snd_note B_3, 16
	snd_len 2
	snd_off
	snd_note Ds_4, 15
	snd_len 3
	snd_off
	snd_note Fs_4, 12
	snd_note E_4, 16
	snd_len 2
	snd_off
	snd_note Gs_4, 16
	snd_len 2
	snd_off
	snd_note B_4, 11
	snd_len 1
	snd_off
	snd_note B_3, 16
	snd_len 2
	snd_off
	snd_note Ds_4, 15
	snd_len 3
	snd_off
	snd_note Fs_4, 12
	snd_note E_4, 16
	snd_len 2
	snd_off
	snd_note Gs_4, 16
	snd_len 2
	snd_off
	snd_note B_4, 11
	snd_len 1
	snd_off
	snd_note B_3, 16
	snd_len 2
	snd_off
	snd_note Ds_4, 15
	snd_len 3
	snd_off
	snd_note Fs_4, 12
	snd_note E_4, 16
	snd_len 2
	snd_off
	snd_note Gs_4, 16
	snd_len 2
	snd_off
	snd_note B_4, 11
	snd_len 1
	snd_off
	snd_note B_3, 15
	snd_len 3
	snd_off
	snd_note Ds_4, 15
	snd_len 3
	snd_off
	snd_note Fs_4, 12
	snd_note B_3, 16
	snd_len 2
	snd_off
	snd_note Ds_4, 10
	snd_len 8
	snd_off
	snd_note Ds_3, 9
	snd_len 3
	snd_off
	snd_note E_3, 15
	snd_len 3
	snd_off
	snd_note B_3, 15
	snd_len 3
	snd_off
	snd_note E_4, 11
	snd_len 1
	snd_off
	snd_note Fs_3, 15
	snd_len 3
	snd_off
	snd_note Cs_4, 14
	snd_len 4
	snd_off
	snd_note Fs_4, 12
	snd_note Gs_3, 17
	snd_len 1
	snd_off
	snd_note Ds_4, 14
	snd_len 4
	snd_off
	snd_note Gs_4, 10
	snd_len 2
	snd_off
	snd_note Cs_4, 15
	snd_len 3
	snd_off
	snd_note Gs_4, 16
	snd_len 2
	snd_off
	snd_note Cs_4, 11
	snd_len 1
	snd_off
	snd_note Fs_3, 5
	snd_len 7
	snd_off
	snd_note Fs_3, 5
	snd_len 7
	snd_off
	snd_note Fs_4, 4
	snd_len 2
	snd_off
	snd_note Fs_4, 6
	snd_off
	snd_note Fs_3, 5
	snd_len 7
	snd_off
	snd_note Fs_3, 5
	snd_len 7
	snd_off
	snd_note Fs_3, 4
	snd_len 2
	snd_off
	snd_note Fs_4, 5
	snd_len 7
	snd_off
	snd_note Fs_3, 5
	snd_len 7
	snd_off
	snd_note B_3, 18
	snd_note Fs_4, 14
	snd_len 4
	snd_off
	snd_note B_4, 29
	snd_len 1
	snd_off
	snd_note Fs_4, 18
	snd_note Fs_3, 11
	snd_len 1
	snd_off
	snd_endloop
	snd_note Gs_3, 16
	snd_len 2
	snd_off
	snd_note B_3, 15
	snd_len 2
	snd_off
	snd_note Ds_4, 12
	snd_len 2
	snd_off
	snd_note Cs_4, 16
	snd_len 2
	snd_off
	snd_note E_4, 14
	snd_len 2
	snd_off
	snd_note Gs_4, 11
	snd_len 2
	snd_off
	snd_note Gs_3, 16
	snd_len 2
	snd_off
	snd_note B_3, 15
	snd_len 2
	snd_off
	snd_note Ds_4, 12
	snd_len 2
	snd_off
	snd_note Cs_4, 16
	snd_len 2
	snd_off
	snd_note E_4, 14
	snd_len 2
	snd_off
	snd_note Gs_4, 11
	snd_len 2
	snd_off
	snd_note Gs_3, 17
	snd_len 1
	snd_off
	snd_note Ds_4, 15
	snd_len 3
	snd_off
	snd_note Gs_4, 11
	snd_len 1
	snd_off
	snd_note G_3, 16
	snd_len 2
	snd_off
	snd_note Ds_4, 16
	snd_len 2
	snd_off
	snd_note Gs_4, 9
	snd_len 3
	snd_off
	snd_note Fs_3, 17
	snd_len 1
	snd_off
	snd_note Ds_4, 17
	snd_len 1
	snd_off
	snd_note Gs_4, 27
	snd_len 3
	snd_off
	snd_note Ds_4, 18
	snd_note Fs_3, 11
	snd_note F_3, 19
	snd_len 1
	snd_off
	snd_note Cs_4, 15
	snd_len 2
	snd_off
	snd_note Gs_4, 11
	snd_len 1
	snd_off
	snd_note Cs_4, 17
	snd_len 1
	snd_off
	snd_note Gs_4, 17
	snd_len 2
	snd_off
	snd_note F_3, 11
	snd_note E_3, 17
	snd_len 1
	snd_off
	snd_note B_3, 16
	snd_len 1
	snd_off
	snd_note Fs_4, 10
	snd_len 3
	snd_off
	snd_note Gs_4, 17
	snd_len 1
	snd_off
	snd_note B_3, 18
	snd_note E_4, 11
	snd_note Ds_3, 17
	snd_len 1
	snd_off
	snd_note B_3, 16
	snd_len 2
	snd_off
	snd_note Ds_4, 11
	snd_len 2
	snd_off
	snd_note E_4, 18
	snd_note B_3, 15
	snd_len 2
	snd_off
	snd_note E_3, 14
	snd_len 8
	snd_off
	snd_note Fs_3, 5
	snd_len 2
	snd_off
	snd_note G_3, 5
	snd_len 4
	snd_off
	snd_note Gs_3, 7
	snd_off
	snd_note A_3, 6
	snd_len 3
	snd_off
	snd_note As_3, 7
	snd_len 9
	snd_off
	snd_note Fs_4, 4
	snd_off
	snd_note Fs_4, 9
	snd_len 15
	snd_off
	snd_note B_3, 5
	snd_len 7
	snd_off
	snd_note B_3, 5
	snd_len 6
	snd_off
	snd_note Ds_4
	snd_note B_3, 7
	snd_len 6
	snd_off
	snd_note E_4, 5
	snd_len 7
	snd_off
	snd_note E_4, 5
	snd_len 6
	snd_off
	snd_note F_4, 4
	snd_len 2
	snd_off
	snd_note Fs_4, 6
	snd_len 7
	snd_off
	snd_note Fs_4, 6
	snd_off
	snd_note B_3, 5
	snd_len 7
	snd_off
	snd_note B_3, 5
	snd_len 6
	snd_off
	snd_note Ds_4
	snd_note B_3, 7
	snd_len 6
	snd_off
	snd_note E_4, 5
	snd_len 7
	snd_off
	snd_note E_4, 5
	snd_len 6
	snd_off
	snd_note F_4, 4
	snd_len 2
	snd_off
	snd_note Fs_4, 6
	snd_len 7
	snd_off
	snd_note Fs_4, 6
	snd_off
	snd_note B_3, 5
	snd_len 7
	snd_off
	snd_note B_3, 5
	snd_len 6
	snd_off
	snd_note Ds_4
	snd_note B_3, 7
	snd_len 6
	snd_off
	snd_note E_4, 5
	snd_len 7
	snd_off
	snd_note E_4, 5
	snd_len 6
	snd_off
	snd_note F_4, 4
	snd_len 2
	snd_off
	snd_note Fs_4, 6
	snd_len 7
	snd_off
	snd_note Fs_4, 6
	snd_off
	snd_note B_3, 4
	snd_len 8
	snd_off
	snd_note B_3, 4
	snd_len 9
	snd_off
	snd_note B_3, 3
	snd_off
	snd_note B_3, 5
	snd_len 6
	snd_off
	snd_note B_3
	snd_len 24
	snd_off
	snd_pitchenv SndPitchEnv_4ABD
	snd_note Fs_4
	snd_jump Trk3D_6D6E
Mus3D_8_Ch4:
	snd_len 6
	snd_drum 6
	snd_drum 0
	snd_drum 1
	snd_drum 6
	snd_drum 4
	snd_drum 0
	snd_drum 1
	snd_drum 3
	snd_drum 6
	snd_drum 3
	snd_drum 1
	snd_drum 6
	snd_drum 4
	snd_drum 0
	snd_drum 1
	snd_drum 6
	snd_jump Mus3D_8_Ch4
Mus3D_9:
	db $0F	; channel mask
	dw Mus3D_9_Ch1, Mus3D_9_Ch2, Mus3D_9_Ch3, Mus3D_9_Ch4
Mus3D_9_Ch1:
	snd_tempo 118
	snd_duty $80
	snd_env $61
Trk3D_6F7B:
	snd_note Gs_5, 3
	snd_len 9
	snd_off
	snd_note F_5, 3
	snd_off
	snd_note F_5
	snd_off
	snd_note Gs_5
	snd_len 9
	snd_off
	snd_note F_5, 3
	snd_len 9
	snd_off
	snd_note As_5, 3
	snd_len 9
	snd_off
	snd_note F_5, 3
	snd_off
	snd_note F_5
	snd_off
	snd_note Gs_5
	snd_len 9
	snd_off
	snd_note F_5, 3
	snd_len 9
	snd_off
	snd_note As_5, 3
	snd_len 9
	snd_off
	snd_note F_5, 3
	snd_off
	snd_note F_5
	snd_off
	snd_note As_5
	snd_len 9
	snd_off
	snd_note F_5, 3
	snd_off
	snd_note F_5
	snd_off
	snd_note As_5
	snd_len 9
	snd_off
	snd_note F_5, 3
	snd_off
	snd_note F_5
	snd_off
	snd_note Gs_5
	snd_len 9
	snd_off
	snd_note F_5, 3
	snd_len 9
	snd_off
	snd_note As_5, 3
	snd_len 9
	snd_off
	snd_note Cs_6, 3
	snd_off
	snd_note Cs_6
	snd_off
	snd_note Fs_5
	snd_len 9
	snd_off
	snd_note Cs_6, 3
	snd_len 9
	snd_off
	snd_note As_5, 3
	snd_len 9
	snd_off
	snd_note Cs_6, 3
	snd_off
	snd_note Cs_6
	snd_off
	snd_note Fs_5
	snd_len 9
	snd_off
	snd_note Cs_6, 3
	snd_len 9
	snd_off
	snd_note Gs_5, 3
	snd_len 9
	snd_off
	snd_note As_5, 3
	snd_off
	snd_note As_5
	snd_off
	snd_note Gs_5
	snd_len 9
	snd_off
	snd_note As_5, 3
	snd_len 9
	snd_off
	snd_note Gs_5, 3
	snd_len 9
	snd_off
	snd_note As_5, 3
	snd_off
	snd_note As_5
	snd_off
	snd_note Gs_5
	snd_len 9
	snd_off
	snd_note As_5, 3
	snd_len 9
	snd_off
	snd_note Gs_5, 5
	snd_len 7
	snd_off
	snd_note Cs_6, 2
	snd_len 4
	snd_off
	snd_note Cs_6, 2
	snd_len 4
	snd_off
	snd_note Gs_5, 5
	snd_len 7
	snd_off
	snd_note Cs_6, 2
	snd_len 10
	snd_off
	snd_note Gs_5, 5
	snd_len 7
	snd_off
	snd_note Cs_6, 2
	snd_len 4
	snd_off
	snd_note Cs_6, 2
	snd_len 4
	snd_off
	snd_note Gs_5, 5
	snd_len 7
	snd_off
	snd_note Cs_6, 2
	snd_len 10
	snd_off
	snd_note C_6, 3
	snd_len 9
	snd_off
	snd_note As_5, 2
	snd_len 4
	snd_off
	snd_note C_6, 2
	snd_len 4
	snd_off
	snd_note As_5, 3
	snd_len 9
	snd_off
	snd_note C_6, 2
	snd_len 10
	snd_off
	snd_note As_5, 3
	snd_len 9
	snd_off
	snd_note C_6, 2
	snd_len 4
	snd_off
	snd_note As_5, 2
	snd_len 4
	snd_off
	snd_note C_6, 3
	snd_len 9
	snd_off
	snd_note Gs_5, 3
	snd_len 9
	snd_off
	snd_note As_5, 3
	snd_len 9
	snd_off
	snd_note Fs_5, 2
	snd_len 4
	snd_off
	snd_note As_5, 2
	snd_len 4
	snd_off
	snd_note Ds_5, 3
	snd_len 9
	snd_off
	snd_note As_5, 2
	snd_len 10
	snd_off
	snd_note As_5, 3
	snd_len 9
	snd_off
	snd_note Fs_5, 2
	snd_len 4
	snd_off
	snd_note As_5, 2
	snd_len 4
	snd_off
	snd_note Ds_5, 3
	snd_len 9
	snd_off
	snd_note As_5, 2
	snd_len 22
	snd_off
	snd_note Gs_5, 3
	snd_off
	snd_note Gs_5
	snd_len 15
	snd_off
	snd_note Gs_5, 3
	snd_off
	snd_note Gs_5
	snd_off
	snd_note Gs_5
	snd_off
	snd_note Gs_5
	snd_off
	snd_note Gs_5
	snd_off
	snd_note As_5, 2
	snd_len 4
	snd_off
	snd_note Gs_5, 3
	snd_len 9
	snd_off
	snd_note F_5, 2
	snd_len 4
	snd_off
	snd_note Gs_5, 3
	snd_off
	snd_jump Trk3D_6F7B
Mus3D_9_Ch2:
	snd_duty $00
	snd_env $80
	snd_octenv SndOctEnv_4AD8
Trk3D_709D:
	snd_note Cs_4, 6
	snd_len 18
	snd_off
	snd_note Gs_3, 6
	snd_len 18
	snd_off
	snd_note Cs_4, 6
	snd_off
	snd_note F_4
	snd_off
	snd_note Gs_4
	snd_len 18
	snd_off
	snd_note As_4, 6
	snd_off
	snd_note C_5
	snd_note As_4
	snd_note Gs_4
	snd_off
	snd_note F_4
	snd_off
	snd_note Ds_4
	snd_off
	snd_note Gs_4
	snd_off
	snd_note F_4
	snd_len 18
	snd_off
	snd_note As_3, 6
	snd_off
	snd_note C_4
	snd_off
	snd_note Cs_4
	snd_off
	snd_note F_4
	snd_off
	snd_note Ds_4
	snd_off
	snd_note As_4
	snd_off
	snd_note Gs_4
	snd_off
	snd_note F_4
	snd_off
	snd_note Ds_4
	snd_off
	snd_note Ds_4
	snd_off
	snd_note Cs_4
	snd_off
	snd_note Cs_4
	snd_off
	snd_note Ds_4
	snd_off
	snd_note Cs_4
	snd_off
	snd_note As_3
	snd_off
	snd_note Gs_3
	snd_off
	snd_note Cs_4
	snd_len 18
	snd_off
	snd_note Gs_3, 6
	snd_len 18
	snd_off
	snd_note Cs_4, 6
	snd_off
	snd_note F_4
	snd_off
	snd_note Gs_4
	snd_len 18
	snd_off
	snd_note Gs_4, 6
	snd_off
	snd_note As_4
	snd_note Gs_4
	snd_note F_4
	snd_off
	snd_note Cs_4
	snd_off
	snd_note Ds_4
	snd_off
	snd_note F_4
	snd_off
	snd_note Ds_4
	snd_len 18
	snd_off
	snd_note Fs_3, 6
	snd_off
	snd_note As_3
	snd_off
	snd_note Cs_4
	snd_off
	snd_note As_3
	snd_off
	snd_note E_4
	snd_off
	snd_note Ds_4
	snd_off
	snd_note Cs_4
	snd_off
	snd_note As_3
	snd_off
	snd_note Gs_3
	snd_off
	snd_note Gs_3
	snd_off
	snd_note A_3
	snd_off
	snd_note A_3
	snd_off
	snd_note As_3
	snd_off
	snd_note Gs_3
	snd_off
	snd_note Ds_4
	snd_off
	snd_note Gs_3
	snd_off
	snd_jump Trk3D_709D
Mus3D_9_Ch3:
	snd_duty $00
	snd_env2 $60
	snd_wave SndWave0F
	snd_transpose $0C
	snd_pitchenv SndPitchEnv_49A8
Trk3D_712D:
	snd_note Cs_5, 48
	snd_note Cs_6
	snd_note C_6, 72
	snd_note B_5, 24
	snd_note As_5, 48
	snd_note Cs_5
	snd_note Ds_5, 72
	snd_note Fs_5, 24
	snd_note F_5, 96
	snd_note Gs_5, 72
	snd_note F_5, 24
	snd_note Ds_5, 36
	snd_note Cs_5, 12
	snd_note Ds_5, 48
	snd_len 24
	snd_off
	snd_note As_5, 48
	snd_note Gs_5, 24
	snd_jump Trk3D_712D
Mus3D_9_Ch4:
	snd_loop 7
	snd_len 12
	snd_drum 5
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 5
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 5
	snd_len 6
	snd_drum 3
	snd_drum 0
	snd_drum 3
	snd_drum 0
	snd_drum 5
	snd_drum 5
	snd_endloop
	snd_len 12
	snd_drum 5
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 5
	snd_len 6
	snd_drum 0
	snd_drum 0
	snd_len 12
	snd_drum 5
	snd_len 6
	snd_drum 5
	snd_drum 0
	snd_drum 5
	snd_drum 0
	snd_len 12
	snd_drum 2
	snd_jump Mus3D_9_Ch4
Mus3D_10:
	db $0F	; channel mask
	dw Mus3D_10_Ch1, Mus3D_10_Ch2, Mus3D_10_Ch3, Mus3D_10_Ch4
Mus3D_10_Ch1:
	snd_tempo 127
	snd_duty $40
	snd_env $73
Trk3D_718B:
	snd_env $63
	snd_octenv SndOctEnv_4AEF
	snd_loop 2
	snd_note B_5, 12
	snd_note A_5
	snd_note B_5
	snd_note A_5, 36
	snd_note Fs_5, 6
	snd_note Fs_5, 12
	snd_note A_5, 6
	snd_note B_5, 12
	snd_note A_5
	snd_note B_5
	snd_note A_5, 60
	snd_note B_5, 12
	snd_note A_5
	snd_note B_5
	snd_note A_5, 36
	snd_note B_5, 6
	snd_note D_6, 12
	snd_note E_6, 6
	snd_note Fs_6, 12
	snd_note D_6
	snd_note E_6
	snd_note B_5, 60
	snd_endloop
	snd_pitchenv SndPitchEnv_4AD7
	snd_env $64
	snd_call Trk3D_725B
	snd_call Trk3D_725B
	snd_call Trk3D_72A7
	snd_note F_4, 12
	snd_note F_5, 3
	snd_off
	snd_note F_5, 5
	snd_len 1
	snd_off
	snd_note C_5, 5
	snd_len 1
	snd_off
	snd_note F_5, 4
	snd_len 8
	snd_off
	snd_note F_5, 4
	snd_len 2
	snd_off
	snd_note C_5, 5
	snd_len 7
	snd_off
	snd_note F_5, 4
	snd_len 8
	snd_off
	snd_note A_5, 5
	snd_len 7
	snd_off
	snd_note F_5, 4
	snd_len 8
	snd_off
	snd_note Gs_5, 3
	snd_off
	snd_note A_5
	snd_off
	snd_note C_6
	snd_len 9
	snd_off
	snd_note Ds_6, 3
	snd_len 9
	snd_off
	snd_note C_6, 3
	snd_len 9
	snd_off
	snd_note Gs_5, 3
	snd_len 9
	snd_off
	snd_note A_5, 3
	snd_len 9
	snd_off
	snd_note F_5, 3
	snd_len 9
	snd_off
	snd_note C_5, 4
	snd_len 8
	snd_off
	snd_call Trk3D_725B
	snd_call Trk3D_725B
	snd_call Trk3D_72A7
	snd_note F_4, 12
	snd_note F_5, 3
	snd_off
	snd_note F_5, 5
	snd_len 1
	snd_off
	snd_note C_5, 5
	snd_len 1
	snd_off
	snd_note F_5, 4
	snd_len 8
	snd_off
	snd_note F_5, 4
	snd_len 2
	snd_off
	snd_note C_5, 5
	snd_len 7
	snd_off
	snd_note F_5, 4
	snd_len 8
	snd_off
	snd_note A_5, 5
	snd_len 7
	snd_off
	snd_note F_5, 4
	snd_len 8
	snd_off
	snd_note Cs_5, 3
	snd_off
	snd_note G_5
	snd_off
	snd_note B_5
	snd_len 9
	snd_off
	snd_note Cs_6, 3
	snd_len 9
	snd_off
	snd_note A_5, 3
	snd_len 9
	snd_off
	snd_note F_5, 3
	snd_len 9
	snd_off
	snd_note A_5, 3
	snd_len 9
	snd_off
	snd_note F_5, 3
	snd_len 9
	snd_off
	snd_note Cs_5, 4
	snd_len 8
	snd_off
	snd_jump Trk3D_718B
Trk3D_725B:
	snd_note D_4, 12
	snd_note D_5, 3
	snd_off
	snd_note D_5, 5
	snd_len 1
	snd_off
	snd_note A_4, 5
	snd_len 1
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_note D_5, 4
	snd_len 2
	snd_off
	snd_note G_4, 5
	snd_len 7
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_note D_4, 5
	snd_len 7
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_note G_3, 6
	snd_off
	snd_note D_5, 3
	snd_off
	snd_note D_5, 5
	snd_len 1
	snd_off
	snd_note B_4, 5
	snd_len 1
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_note D_5, 4
	snd_len 2
	snd_off
	snd_note G_4, 5
	snd_len 7
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_note D_4, 5
	snd_len 7
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_ret
Trk3D_72A7:
	snd_note D_4, 12
	snd_note D_5, 3
	snd_off
	snd_note D_5, 5
	snd_len 1
	snd_off
	snd_note A_4, 5
	snd_len 1
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_note D_5, 4
	snd_len 2
	snd_off
	snd_note Fs_5, 5
	snd_len 7
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_note A_4, 5
	snd_len 7
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_note Fs_5, 3
	snd_off
	snd_note A_5
	snd_off
	snd_note B_5
	snd_len 9
	snd_off
	snd_note A_5, 3
	snd_len 9
	snd_off
	snd_note B_5, 3
	snd_len 9
	snd_off
	snd_note A_5, 3
	snd_len 9
	snd_off
	snd_note Fs_5, 3
	snd_len 9
	snd_off
	snd_note E_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_note G_4, 12
	snd_note E_5, 3
	snd_off
	snd_note E_5, 5
	snd_len 1
	snd_off
	snd_note B_4, 5
	snd_len 1
	snd_off
	snd_note E_5, 4
	snd_len 8
	snd_off
	snd_note E_5, 4
	snd_len 2
	snd_off
	snd_note G_5, 5
	snd_len 7
	snd_off
	snd_note E_5, 4
	snd_len 8
	snd_off
	snd_note B_4, 5
	snd_len 7
	snd_off
	snd_note E_5, 4
	snd_len 8
	snd_off
	snd_note G_5, 3
	snd_off
	snd_note A_5
	snd_off
	snd_note B_5
	snd_len 9
	snd_off
	snd_note D_6, 3
	snd_len 9
	snd_off
	snd_note B_5, 3
	snd_len 9
	snd_off
	snd_note A_5, 3
	snd_len 9
	snd_off
	snd_note B_5, 3
	snd_len 9
	snd_off
	snd_note Fs_5, 3
	snd_len 9
	snd_off
	snd_note E_5, 4
	snd_len 8
	snd_off
	snd_note D_4, 12
	snd_note D_5, 3
	snd_off
	snd_note D_5, 5
	snd_len 1
	snd_off
	snd_note A_4, 5
	snd_len 1
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_note D_5, 4
	snd_len 2
	snd_off
	snd_note Fs_5, 5
	snd_len 7
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_note A_4, 5
	snd_len 7
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_note Fs_5, 3
	snd_off
	snd_note A_5
	snd_off
	snd_note B_5
	snd_len 9
	snd_off
	snd_note A_5, 3
	snd_len 9
	snd_off
	snd_note B_5, 3
	snd_len 9
	snd_off
	snd_note A_5, 3
	snd_len 9
	snd_off
	snd_note Fs_5, 3
	snd_len 9
	snd_off
	snd_note E_5, 3
	snd_len 9
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_ret
Mus3D_10_Ch2:
	snd_duty $80
	snd_env $80
	snd_pitchenv SndPitchEnv_49A8
Trk3D_737E:
	snd_env $42
	snd_loop 4
	snd_len 12
	snd_off
	snd_note A_5, 3
	snd_off
	snd_note A_5, 4
	snd_len 2
	snd_off
	snd_note D_5, 4
	snd_len 2
	snd_off
	snd_note A_5
	snd_len 10
	snd_off
	snd_note A_5, 4
	snd_len 2
	snd_off
	snd_note A_4, 4
	snd_len 8
	snd_off
	snd_note A_5, 4
	snd_len 8
	snd_off
	snd_note D_5, 4
	snd_len 8
	snd_off
	snd_note A_5, 5
	snd_len 19
	snd_off
	snd_note A_5, 3
	snd_off
	snd_note A_5, 5
	snd_len 1
	snd_off
	snd_note Fs_5, 5
	snd_len 1
	snd_off
	snd_note A_5, 4
	snd_len 8
	snd_off
	snd_note A_5, 4
	snd_len 2
	snd_off
	snd_note D_5, 5
	snd_len 7
	snd_off
	snd_note A_5, 4
	snd_len 8
	snd_off
	snd_note A_4, 5
	snd_len 7
	snd_off
	snd_note A_5, 4
	snd_len 8
	snd_off
	snd_endloop
	snd_env $60
	snd_note A_5, 12
	snd_note D_5, 5
	snd_note Fs_5, 7
	snd_len 6
	snd_off
	snd_note A_5
	snd_off
	snd_note B_5, 96
	snd_note B_5, 31
	snd_len 23
	snd_off
	snd_note D_6, 12
	snd_note B_5, 6
	snd_note D_6
	snd_off
	snd_note Fs_6
	snd_off
	snd_note E_6, 96
	snd_note E_6, 30
	snd_len 24
	snd_off
	snd_note E_6, 1
	snd_note Fs_6, 33
	snd_len 2
	snd_off
	snd_note Fs_6, 36
	snd_note A_6, 24
	snd_note Fs_6, 48
	snd_note E_6, 24
	snd_note D_6, 20
	snd_len 4
	snd_off
	snd_note B_5, 36
	snd_note D_6, 12
	snd_note B_5, 96
	snd_note B_5, 48
	snd_note E_6, 1
	snd_note Fs_6, 33
	snd_len 2
	snd_off
	snd_note Fs_6, 36
	snd_note A_6, 24
	snd_note Fs_6, 48
	snd_note E_6, 24
	snd_note D_6, 20
	snd_len 4
	snd_off
	snd_note C_6, 36
	snd_note D_6, 12
	snd_note C_6, 43
	snd_note B_5, 1
	snd_note As_5
	snd_note A_5
	snd_note G_5
	snd_note Fs_5
	snd_note F_5, 96
	snd_note A_5, 12
	snd_note D_5, 5
	snd_note Fs_5, 7
	snd_len 6
	snd_off
	snd_note A_5
	snd_off
	snd_note B_5, 96
	snd_note B_5, 31
	snd_len 23
	snd_off
	snd_note D_6, 12
	snd_note B_5, 6
	snd_note D_6
	snd_off
	snd_note Fs_6
	snd_off
	snd_note E_6, 96
	snd_note E_6, 30
	snd_len 24
	snd_off
	snd_note E_6, 1
	snd_note Fs_6, 33
	snd_len 2
	snd_off
	snd_note Fs_6, 36
	snd_note A_6, 24
	snd_note B_6, 48
	snd_note D_6, 24
	snd_note Fs_6, 20
	snd_len 4
	snd_off
	snd_note E_6, 36
	snd_note D_6, 12
	snd_note E_6, 96
	snd_note E_6, 48
	snd_note E_6, 1
	snd_note Fs_6, 32
	snd_len 3
	snd_off
	snd_note Fs_6, 36
	snd_note A_6, 24
	snd_note D_6, 48
	snd_note A_5, 24
	snd_note D_6, 20
	snd_len 4
	snd_off
	snd_note C_6, 96
	snd_note Cs_6
	snd_jump Trk3D_737E
Mus3D_10_Ch3:
	snd_duty $00
	snd_env2 $40
	snd_wave SndWave00
	snd_pitchenv SndPitchEnv_4A04
Trk3D_747E:
	snd_loop 2
	snd_call Trk3D_7552
	snd_transpose $05
	snd_call Trk3D_7552
	snd_transpose $00
	snd_endloop
	snd_call Trk3D_751E
	snd_call Trk3D_751E
	snd_call Trk3D_7552
	snd_transpose $05
	snd_call Trk3D_7552
	snd_transpose $00
	snd_call Trk3D_7552
	snd_note F_3, 5
	snd_len 7
	snd_off
	snd_note F_3, 6
	snd_off
	snd_note A_3
	snd_note C_4, 7
	snd_len 5
	snd_off
	snd_note D_4, 6
	snd_note Ds_4
	snd_off
	snd_note C_4, 7
	snd_len 5
	snd_off
	snd_note Ds_4, 4
	snd_len 8
	snd_off
	snd_note F_4, 5
	snd_len 7
	snd_off
	snd_note A_4, 6
	snd_off
	snd_note Ds_4
	snd_off
	snd_note F_4
	snd_note B_4, 7
	snd_len 5
	snd_off
	snd_note C_5
	snd_len 1
	snd_off
	snd_note F_4, 6
	snd_note A_4
	snd_off
	snd_note Ds_4
	snd_note F_4, 5
	snd_len 7
	snd_off
	snd_note C_4
	snd_len 5
	snd_off
	snd_call Trk3D_751E
	snd_call Trk3D_751E
	snd_call Trk3D_7552
	snd_transpose $05
	snd_call Trk3D_7552
	snd_transpose $00
	snd_call Trk3D_7552
	snd_note F_3, 5
	snd_len 7
	snd_off
	snd_note F_3, 6
	snd_off
	snd_note A_3
	snd_note C_4, 7
	snd_len 5
	snd_off
	snd_note D_4, 6
	snd_note Ds_4
	snd_off
	snd_note C_4, 7
	snd_len 5
	snd_off
	snd_note Ds_4, 4
	snd_len 8
	snd_off
	snd_note F_4, 5
	snd_len 7
	snd_off
	snd_note A_3, 6
	snd_off
	snd_note Cs_4
	snd_off
	snd_note F_4
	snd_len 7
	snd_off
	snd_len 5
	snd_off
	snd_note A_4
	snd_len 1
	snd_off
	snd_note F_4, 6
	snd_note A_4
	snd_off
	snd_note G_4
	snd_note C_4, 5
	snd_len 7
	snd_off
	snd_note Cs_4
	snd_len 5
	snd_off
	snd_jump Trk3D_747E
Trk3D_751E:
	snd_note D_3, 5
	snd_len 7
	snd_off
	snd_note D_3, 6
	snd_off
	snd_note Fs_3
	snd_note A_3, 7
	snd_len 5
	snd_off
	snd_note Gs_3, 6
	snd_note G_3
	snd_off
	snd_note B_3, 7
	snd_len 5
	snd_off
	snd_note D_4, 4
	snd_len 8
	snd_off
	snd_note E_4, 5
	snd_len 7
	snd_off
	snd_note G_4, 6
	snd_off
	snd_note E_4
	snd_off
	snd_note D_4
	snd_off
	snd_note E_4, 7
	snd_len 5
	snd_off
	snd_note B_3, 6
	snd_note D_4
	snd_off
	snd_note A_3
	snd_note B_3, 5
	snd_len 7
	snd_off
	snd_note G_3
	snd_len 5
	snd_off
	snd_ret
Trk3D_7552:
	snd_note D_3, 5
	snd_len 7
	snd_off
	snd_note D_3, 6
	snd_off
	snd_note Fs_3
	snd_note A_3, 7
	snd_len 5
	snd_off
	snd_note B_3, 6
	snd_note D_4
	snd_off
	snd_note B_3, 7
	snd_len 5
	snd_off
	snd_note D_4, 4
	snd_len 8
	snd_off
	snd_note E_4, 5
	snd_len 7
	snd_off
	snd_note Fs_4, 6
	snd_off
	snd_note A_4
	snd_off
	snd_note B_4
	snd_off
	snd_note A_4, 7
	snd_len 5
	snd_off
	snd_note Fs_4, 6
	snd_note A_4
	snd_off
	snd_note E_4
	snd_note Fs_4, 5
	snd_len 7
	snd_off
	snd_note D_4
	snd_len 5
	snd_off
	snd_ret
Mus3D_10_Ch4:
	snd_loop 3
	snd_len 24
	snd_drum 5
	snd_drum 4
	snd_drum 5
	snd_drum 4
	snd_drum 5
	snd_drum 4
	snd_len 12
	snd_drum 5
	snd_len 6
	snd_drum 0
	snd_drum 5
	snd_len 12
	snd_drum 7
	snd_drum 0
	snd_endloop
	snd_len 24
	snd_drum 5
	snd_drum 4
	snd_drum 5
	snd_drum 4
	snd_drum 5
	snd_drum 4
	snd_len 6
	snd_drum 5
	snd_drum 4
	snd_drum 4
	snd_drum 5
	snd_len 12
	snd_drum 4
	snd_len 6
	snd_drum 4
	snd_drum 4
	snd_loop 2
	snd_len 24
	snd_drum 5
	snd_drum 4
	snd_drum 5
	snd_drum 4
	snd_drum 5
	snd_drum 4
	snd_len 12
	snd_drum 5
	snd_len 6
	snd_drum 0
	snd_drum 5
	snd_len 12
	snd_drum 7
	snd_drum 0
	snd_endloop
	snd_loop 16
	snd_len 24
	snd_drum 5
	snd_drum 4
	snd_endloop
	snd_loop 2
	snd_len 24
	snd_drum 5
	snd_drum 4
	snd_drum 5
	snd_drum 4
	snd_drum 5
	snd_drum 4
	snd_len 12
	snd_drum 5
	snd_len 6
	snd_drum 0
	snd_drum 5
	snd_len 12
	snd_drum 7
	snd_drum 0
	snd_endloop
	snd_loop 15
	snd_len 24
	snd_drum 5
	snd_drum 4
	snd_endloop
	snd_len 6
	snd_drum 5
	snd_drum 4
	snd_drum 4
	snd_drum 5
	snd_len 12
	snd_drum 4
	snd_len 6
	snd_drum 4
	snd_drum 4
	snd_jump Mus3D_10_Ch4
Mus3D_11:
	db $0F	; channel mask
	dw Mus3D_11_Ch1, Mus3D_11_Ch2, Mus3D_11_Ch3, Mus3D_11_Ch4
Mus3D_11_Ch1:
	snd_tempo 90
	snd_duty $80
	snd_env $30
	snd_pitchenv SndPitchEnv_499B
	snd_len 3
	snd_off
Trk3D_75FA:
	snd_loop 2
	snd_len 72
	snd_off
	snd_note D_7, 2
	snd_note D_8
	snd_len 20
	snd_off
	snd_endloop
	snd_len 96
	snd_off
	snd_transpose $FF
	snd_call Trk3D_76F7
	snd_len 96
	snd_off
	snd_call Trk3D_770E
	snd_transpose $00
	snd_len 96
	snd_off
	snd_len 2
	snd_off
	snd_note F_7, 2
	snd_off
	snd_note F_7
	snd_len 6
	snd_off
	snd_note E_7, 2
	snd_off
	snd_note E_7
	snd_len 6
	snd_off
	snd_note D_7, 2
	snd_off
	snd_note D_7
	snd_len 6
	snd_off
	snd_note As_6, 2
	snd_off
	snd_note As_6
	snd_len 6
	snd_off
	snd_note G_6, 2
	snd_off
	snd_note G_6
	snd_len 6
	snd_off
	snd_note F_6, 2
	snd_off
	snd_note F_6
	snd_len 6
	snd_off
	snd_note As_6, 2
	snd_off
	snd_note As_6
	snd_len 6
	snd_off
	snd_note E_6, 2
	snd_off
	snd_note F_6
	snd_off
	snd_note G_6
	snd_note D_5, 48
	snd_note E_5
	snd_note F_5
	snd_note D_4, 4
	snd_note C_4
	snd_note As_3
	snd_note A_3
	snd_note G_3
	snd_note F_3
	snd_note G_3
	snd_note A_2
	snd_note Cs_3
	snd_note E_3
	snd_note F_3
	snd_note G_3
	snd_jump Trk3D_75FA
Mus3D_11_Ch2:
	snd_duty $40
	snd_env $90
	snd_pitchenv SndPitchEnv_496C
Trk3D_7661:
	snd_loop 4
	snd_note D_3, 6
	snd_len 2
	snd_off
	snd_note D_3, 4
	snd_note Gs_3
	snd_note A_3
	snd_note D_3
	snd_note As_3
	snd_note Gs_3
	snd_note A_3
	snd_note D_3
	snd_note G_2
	snd_note A_2
	snd_note D_3, 6
	snd_len 2
	snd_off
	snd_note D_3, 4
	snd_note Gs_3
	snd_note A_3
	snd_note D_3
	snd_note D_4
	snd_note Gs_3
	snd_note A_3
	snd_note D_3
	snd_note G_2
	snd_note A_2
	snd_endloop
	snd_loop 2
	snd_note E_3, 6
	snd_len 2
	snd_off
	snd_note E_3, 4
	snd_note Gs_3
	snd_note A_3
	snd_note E_3
	snd_note As_3
	snd_note Gs_3
	snd_note A_3
	snd_note D_3
	snd_note E_3
	snd_note A_2
	snd_note E_3, 6
	snd_len 2
	snd_off
	snd_note E_3, 4
	snd_note Gs_3
	snd_note A_3
	snd_note E_3
	snd_note E_4
	snd_note Gs_3
	snd_note A_3
	snd_note D_3
	snd_note E_3
	snd_note A_2
	snd_endloop
	snd_loop 2
	snd_note F_3, 6
	snd_len 2
	snd_off
	snd_note F_3, 4
	snd_note Gs_3
	snd_note A_3
	snd_note D_3
	snd_note As_3
	snd_note Gs_3
	snd_note A_3
	snd_note F_3
	snd_note G_3
	snd_note A_2
	snd_endloop
	snd_loop 2
	snd_note G_3, 6
	snd_len 2
	snd_off
	snd_note G_3, 4
	snd_note A_3
	snd_note As_3
	snd_note D_3
	snd_note As_3
	snd_note A_3
	snd_note As_3
	snd_note Fs_3
	snd_note G_3
	snd_note As_2
	snd_endloop
	snd_loop 2
	snd_note A_3, 6
	snd_len 2
	snd_off
	snd_note A_3, 4
	snd_note Gs_3
	snd_note A_3
	snd_note D_3
	snd_note As_3
	snd_note Gs_3
	snd_note A_3
	snd_note F_3
	snd_note G_3
	snd_note A_2
	snd_endloop
	snd_note G_3, 6
	snd_len 2
	snd_off
	snd_note G_3, 4
	snd_note A_3
	snd_note As_3
	snd_note D_3
	snd_note C_4
	snd_note A_3
	snd_note As_3
	snd_note Fs_3
	snd_note G_3
	snd_note As_2
	snd_note As_3
	snd_note A_3
	snd_note G_3
	snd_note F_3
	snd_note E_3
	snd_note D_3
	snd_note E_3
	snd_note A_2
	snd_note Cs_2
	snd_note E_2
	snd_note F_2
	snd_note G_2
	snd_jump Trk3D_7661
Trk3D_76F7:
	snd_note D_7, 4
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
	snd_len 20
	snd_off
	snd_ret
Trk3D_770E:
	snd_note Cs_7, 4
	snd_note E_6
	snd_note A_6
	snd_note Cs_6
	snd_note E_6
	snd_note E_5
	snd_note A_5
	snd_note Cs_5
	snd_note D_5
	snd_note E_5
	snd_note A_4
	snd_note F_5
	snd_note E_5
	snd_note As_5
	snd_note G_5
	snd_note A_5
	snd_note F_6
	snd_note Ds_6
	snd_note E_4
	snd_len 20
	snd_off
	snd_ret
Mus3D_11_Ch3:
	snd_wave SndWave01
	snd_env2 $40
	snd_len 1
	snd_off
Trk3D_772C:
	snd_len 96
	snd_off
	snd_len 96
	snd_off
	snd_loop 2
	snd_call Trk3D_76F7
	snd_endloop
	snd_loop 2
	snd_call Trk3D_770E
	snd_endloop
	snd_note D_7, 4
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
	snd_note D_7
	snd_note A_6
	snd_note D_7
	snd_note F_7
	snd_note E_7
	snd_note D_7
	snd_note F_7, 3
	snd_len 1
	snd_off
	snd_note F_7, 3
	snd_len 5
	snd_off
	snd_note E_7, 3
	snd_len 1
	snd_off
	snd_note E_7, 3
	snd_len 5
	snd_off
	snd_note D_7, 3
	snd_len 1
	snd_off
	snd_note D_7, 3
	snd_len 5
	snd_off
	snd_note As_6, 3
	snd_len 1
	snd_off
	snd_note As_6, 3
	snd_len 5
	snd_off
	snd_note G_6, 3
	snd_len 1
	snd_off
	snd_note G_6, 3
	snd_len 5
	snd_off
	snd_note F_6, 3
	snd_len 1
	snd_off
	snd_note F_6, 3
	snd_len 5
	snd_off
	snd_note As_6, 3
	snd_len 1
	snd_off
	snd_note As_6, 3
	snd_len 5
	snd_off
	snd_note E_6, 4
	snd_note F_6
	snd_note G_6
	snd_note A_6, 12
	snd_note F_6
	snd_note D_6
	snd_note A_5
	snd_note G_6
	snd_note E_6
	snd_note C_6
	snd_note G_5
	snd_note F_6
	snd_note D_6
	snd_note As_5
	snd_note G_5
	snd_note D_5, 4
	snd_note C_5
	snd_note As_4
	snd_note A_4
	snd_note G_4
	snd_note F_4
	snd_note G_4
	snd_note A_3
	snd_note Cs_4
	snd_note E_4
	snd_note F_4
	snd_note G_4
	snd_jump Trk3D_772C
Mus3D_11_Ch4:
	snd_len 1
	snd_off
Trk3D_77B0:
	snd_len 8
	snd_drum 5
	snd_len 4
	snd_drum 5
	snd_len 12
	snd_drum 4
	snd_len 8
	snd_drum 5
	snd_len 4
	snd_drum 5
	snd_len 12
	snd_drum 4
	snd_len 8
	snd_drum 5
	snd_len 4
	snd_drum 5
	snd_len 12
	snd_drum 4
	snd_len 8
	snd_drum 5
	snd_len 4
	snd_drum 5
	snd_len 8
	snd_drum 4
	snd_len 4
	snd_drum 5
	snd_jump Trk3D_77B0
Mus3D_12:
	db $0F	; channel mask
	dw Mus3D_12_Ch1, Mus3D_12_Ch2, Mus3D_12_Ch3, Mus3D_12_Ch4
Mus3D_12_Ch1:
	snd_tempo 135
	snd_duty $40
	snd_env $70
	snd_pitchenv SndPitchEnv_498E
Trk3D_77DF:
	snd_transpose $FC
	snd_loop 32
	snd_call Trk3D_791D
	snd_endloop
	snd_transpose $00
	snd_loop 4
	snd_note F_5, 5
	snd_len 1
	snd_off
	snd_note F_5, 5
	snd_len 1
	snd_off
	snd_note D_5, 5
	snd_len 1
	snd_off
	snd_note As_4, 5
	snd_len 1
	snd_off
	snd_note C_5, 4
	snd_len 7
	snd_off
	snd_note G_4, 4
	snd_len 9
	snd_off
	snd_endloop
	snd_loop 4
	snd_note G_5, 5
	snd_len 1
	snd_off
	snd_note G_5, 5
	snd_len 1
	snd_off
	snd_note D_5, 5
	snd_len 1
	snd_off
	snd_note As_4, 5
	snd_len 1
	snd_off
	snd_note C_5, 4
	snd_len 7
	snd_off
	snd_note G_4, 4
	snd_len 9
	snd_off
	snd_endloop
	snd_loop 4
	snd_note F_5, 5
	snd_len 1
	snd_off
	snd_note F_5, 5
	snd_len 1
	snd_off
	snd_note D_5, 5
	snd_len 1
	snd_off
	snd_note As_4, 5
	snd_len 1
	snd_off
	snd_note C_5, 4
	snd_len 2
	snd_off
	snd_note G_5
	snd_note D_5, 1
	snd_len 2
	snd_off
	snd_note G_4, 4
	snd_len 3
	snd_off
	snd_note F_5, 2
	snd_note D_5, 1
	snd_len 3
	snd_off
	snd_endloop
	snd_loop 4
	snd_note G_5, 5
	snd_len 1
	snd_off
	snd_note G_5, 5
	snd_len 1
	snd_off
	snd_note D_5, 5
	snd_len 1
	snd_off
	snd_note As_4, 5
	snd_len 1
	snd_off
	snd_note C_5, 4
	snd_len 2
	snd_off
	snd_note G_5, 1
	snd_note As_5, 2
	snd_off
	snd_note G_4, 4
	snd_len 3
	snd_off
	snd_note F_5, 1
	snd_note A_5, 2
	snd_len 3
	snd_off
	snd_endloop
	snd_jump Trk3D_77DF
Mus3D_12_Ch2:
	snd_env $90
	snd_duty $80
	snd_pitchenv SndPitchEnv_49E9
Trk3D_7875:
	snd_transpose $00
	snd_loop 4
	snd_call Trk3D_791D
	snd_endloop
	snd_transpose $03
	snd_loop 2
	snd_call Trk3D_791D
	snd_endloop
	snd_transpose $02
	snd_loop 2
	snd_call Trk3D_791D
	snd_endloop
	snd_transpose $00
	snd_loop 4
	snd_call Trk3D_791D
	snd_endloop
	snd_transpose $03
	snd_loop 2
	snd_call Trk3D_791D
	snd_endloop
	snd_transpose $02
	snd_loop 2
	snd_call Trk3D_791D
	snd_endloop
	snd_transpose $00
	snd_loop 2
	snd_len 2
	snd_off
	snd_env $90
	snd_note C_5, 95
	snd_note B_4, 86
	snd_note C_5, 3
	snd_len 1
	snd_off
	snd_note Cs_5, 3
	snd_off
	snd_len 1
	snd_off
	snd_note Ds_5, 34
	snd_note D_5, 5
	snd_len 1
	snd_off
	snd_note C_5, 5
	snd_len 1
	snd_off
	snd_note B_4, 96
	snd_note B_4, 24
	snd_env $97
	snd_note B_4, 24
	snd_endloop
	snd_env $90
	snd_len 1
	snd_off
	snd_note C_5, 95
	snd_note D_5, 86
	snd_len 1
	snd_off
	snd_note D_5, 3
	snd_note Cs_5, 3
	snd_note C_5
	snd_len 2
	snd_off
	snd_note As_4, 34
	snd_note C_5, 4
	snd_len 1
	snd_off
	snd_note As_4, 5
	snd_len 1
	snd_off
	snd_note A_4, 96
	snd_note A_4, 48
	snd_len 1
	snd_off
	snd_note G_3, 96
	snd_note G_3, 96
	snd_note D_4, 6
	snd_note F_4
	snd_note G_4
	snd_note D_4
	snd_note F_4
	snd_note G_4
	snd_note F_4
	snd_note G_4
	snd_note As_4
	snd_note C_5
	snd_note D_5
	snd_note As_4
	snd_note C_5
	snd_note D_5
	snd_note G_4
	snd_note As_4
	snd_note C_5
	snd_note D_5
	snd_note F_5
	snd_note D_5
	snd_note C_5
	snd_note As_4
	snd_note G_5
	snd_note F_5
	snd_note As_5, 5
	snd_len 1
	snd_off
	snd_note As_5, 5
	snd_len 1
	snd_off
	snd_note G_5, 6
	snd_note F_5
	snd_note As_5
	snd_note C_6
	snd_note D_6
	snd_note F_6
	snd_jump Trk3D_7875
Trk3D_791D:
	snd_note C_5, 11
	snd_len 1
	snd_off
	snd_note C_5
	snd_len 5
	snd_off
	snd_note C_5, 3
	snd_off
	snd_note C_5, 1
	snd_len 5
	snd_off
	snd_note C_5, 18
	snd_ret
Mus3D_12_Ch3:
	snd_duty $00
	snd_env2 $20
	snd_wave SndWave07
	snd_pitchenv SndPitchEnv_4977
Trk3D_7938:
	snd_loop 7
	snd_call Trk3D_7997
	snd_endloop
	snd_call Trk3D_79C3
	snd_loop 7
	snd_call Trk3D_7997
	snd_endloop
	snd_call Trk3D_79C3
	snd_loop 4
	snd_call Trk3D_7997
	snd_call Trk3D_79AB
	snd_call Trk3D_7997
	snd_note F_3, 6
	snd_note Gs_4, 1
	snd_len 5
	snd_off
	snd_note F_3, 3
	snd_off
	snd_note F_4, 1
	snd_note F_3, 3
	snd_len 2
	snd_off
	snd_note Gs_3, 6
	snd_note F_3, 12
	snd_note Ds_3, 4
	snd_len 2
	snd_off
	snd_endloop
	snd_transpose $02
	snd_loop 4
	snd_call Trk3D_7997
	snd_call Trk3D_79AB
	snd_call Trk3D_7997
	snd_note F_3, 6
	snd_note Gs_4, 1
	snd_len 5
	snd_off
	snd_note F_3, 3
	snd_off
	snd_note F_4, 1
	snd_note F_3, 3
	snd_len 2
	snd_off
	snd_note Gs_3, 6
	snd_note F_3, 12
	snd_note Ds_3, 4
	snd_len 2
	snd_off
	snd_endloop
	snd_transpose $00
	snd_jump Trk3D_7938
Trk3D_7997:
	snd_note F_3, 6
	snd_note F_4, 1
	snd_len 5
	snd_off
	snd_note F_3, 3
	snd_off
	snd_note F_3
	snd_off
	snd_note Gs_3, 6
	snd_note F_3, 12
	snd_note Ds_3, 4
	snd_len 2
	snd_off
	snd_ret
Trk3D_79AB:
	snd_note F_3, 6
	snd_note F_4, 1
	snd_len 2
	snd_off
	snd_note F_3, 1
	snd_len 2
	snd_off
	snd_note F_3, 3
	snd_off
	snd_note F_3
	snd_off
	snd_note Gs_3, 6
	snd_note F_3, 12
	snd_note Ds_3, 4
	snd_len 2
	snd_off
	snd_ret
Trk3D_79C3:
	snd_note F_3, 6
	snd_note Gs_4, 1
	snd_len 2
	snd_off
	snd_note Gs_4, 1
	snd_len 2
	snd_off
	snd_note F_3, 3
	snd_off
	snd_note F_4, 1
	snd_note F_3, 3
	snd_len 2
	snd_off
	snd_note Gs_3, 6
	snd_note F_3, 12
	snd_note Ds_3, 4
	snd_len 2
	snd_off
	snd_ret
Mus3D_12_Ch4:
	snd_len 12
	snd_drum 6
	snd_len 6
	snd_drum 6
	snd_drum 6
	snd_len 12
	snd_drum 4
	snd_len 6
	snd_drum 1
	snd_drum 0
	snd_jump Mus3D_12_Ch4
Mus3D_13:
	db $0F	; channel mask
	dw Mus3D_13_Ch1, Mus3D_13_Ch2, Mus3D_13_Ch3, Mus3D_13_Ch4
Mus3D_13_Ch1:
	snd_tempo 108
	snd_duty $00
	snd_env $80
	snd_pitchenv SndPitchEnv_4977
	snd_note G_4, 3
	snd_note D_5, 2
	snd_note A_5, 4
	snd_note Ds_6, 5
	snd_len 96
	snd_off
	snd_len 82
	snd_off
	snd_note G_4, 3
	snd_note D_5, 2
	snd_note A_5, 4
	snd_note Ds_6, 5
	snd_len 96
	snd_off
	snd_len 82
	snd_off
	snd_transpose $F4
	snd_env $80
	snd_jump Trk3D_7C7D
Unused3D_7A1D:
	snd_env $53
Trk3D_7A1F:
	snd_note A_2, 8
	snd_note Fs_3
	snd_note A_3
	snd_note Fs_4
	snd_note G_4
	snd_note As_2
	snd_note G_3
	snd_note Cs_4
	snd_note Ds_4
	snd_note Fs_3
	snd_note F_4
	snd_note E_4
	snd_note F_3
	snd_note D_4
	snd_note B_4
	snd_note D_4
	snd_note Gs_4
	snd_note C_3
	snd_note F_3
	snd_note Cs_4
	snd_note G_3
	snd_note As_3
	snd_note D_4
	snd_note E_3
	snd_off
	snd_note A_3
	snd_note G_4
	snd_note Ds_4
	snd_note C_4
	snd_note Fs_4
	snd_note As_3
	snd_note F_3
	snd_note Cs_5
	snd_note G_4
	snd_note E_5
	snd_note G_4
	snd_note As_3
	snd_note A_4
	snd_note As_4
	snd_note B_3
	snd_note Gs_4
	snd_note Fs_4
	snd_note C_4
	snd_note Ds_3
	snd_note C_5
	snd_note B_4
	snd_note D_4
	snd_note B_3
	snd_note D_3
	snd_note E_4, 6
	snd_len 2
	snd_off
	snd_note G_4, 6
	snd_len 2
	snd_off
	snd_note G_5, 8
	snd_note As_4
	snd_note G_4
	snd_note As_3
	snd_note A_3
	snd_note Fs_5
	snd_note A_4
	snd_note Ds_4
	snd_note Cs_4
	snd_note As_4
	snd_note B_3
	snd_note C_4
	snd_note B_4
	snd_note D_4
	snd_note F_3
	snd_note D_4
	snd_note Gs_3
	snd_note E_5
	snd_note B_4
	snd_note Ds_4
	snd_note A_4
	snd_note Fs_4
	snd_note E_4
	snd_note C_5
	snd_note Cs_5
	snd_note G_4
	snd_note Ds_5
	snd_note Gs_5
	snd_note C_4
	snd_note Fs_4
	snd_note A_3
	snd_note Fs_4
	snd_note Ds_5
	snd_note E_4
	snd_note Ds_4
	snd_note D_5
	snd_note F_4
	snd_note G_4
	snd_note Cs_5
	snd_note As_5
	snd_note Cs_4
	snd_note D_4
	snd_note B_4
	snd_note D_5
	snd_note B_5, 6
	snd_len 2
	snd_off
	snd_note B_2, 8
	snd_note Gs_3
	snd_note B_3
	snd_note Gs_4
	snd_note A_4
	snd_note C_3
	snd_note A_3
	snd_note Ds_4
	snd_note F_4
	snd_note Gs_3
	snd_note G_4
	snd_note Fs_4
	snd_note G_3
	snd_note E_4
	snd_note Cs_5
	snd_note E_4
	snd_note As_4
	snd_note D_3
	snd_note G_3
	snd_note Ds_4
	snd_note A_3
	snd_note C_4
	snd_note E_4
	snd_note Fs_3
	snd_len 1
	snd_off
	snd_note Ds_4, 7
	snd_len 1
	snd_off
	snd_note B_3, 7
	snd_note A_4, 8
	snd_note F_4
	snd_note D_4
	snd_note Gs_4
	snd_note C_4
	snd_note G_3
	snd_note Ds_5
	snd_note A_4
	snd_note Fs_5
	snd_note A_4
	snd_note C_4
	snd_note B_4
	snd_note C_5
	snd_note Cs_4
	snd_note As_4
	snd_note Gs_4
	snd_note D_4
	snd_note F_3
	snd_note D_5
	snd_note Cs_5
	snd_note E_4
	snd_note Cs_4
	snd_jump Trk3D_7A1F
Mus3D_13_Ch2:
	snd_duty $00
	snd_env $80
	snd_pitchenv SndPitchEnv_49A8
	snd_note Cs_4, 9
	snd_len 3
	snd_off
	snd_note G_3, 5
	snd_len 7
	snd_off
	snd_note Cs_4, 8
	snd_len 4
	snd_off
	snd_note D_4, 9
	snd_len 3
	snd_off
	snd_note G_3, 6
	snd_off
	snd_note D_4, 7
	snd_len 5
	snd_off
	snd_note E_4, 10
	snd_len 2
	snd_off
	snd_note G_3, 6
	snd_off
	snd_note D_4, 10
	snd_len 2
	snd_off
	snd_note G_3, 6
	snd_off
	snd_note Cs_4, 7
	snd_len 5
	snd_off
	snd_note D_4, 7
	snd_len 5
	snd_off
	snd_note G_3, 6
	snd_off
	snd_note Cs_4, 7
	snd_len 5
	snd_off
	snd_note D_4, 7
	snd_len 5
	snd_off
	snd_note E_4, 7
	snd_len 5
	snd_off
	snd_note G_3, 7
	snd_len 5
	snd_off
	snd_note D_4, 7
	snd_len 5
	snd_off
	snd_note G_3, 8
	snd_len 4
	snd_off
	snd_note Cs_4, 7
	snd_len 5
	snd_off
	snd_note D_4, 8
	snd_len 4
	snd_off
	snd_note G_3, 8
	snd_len 4
	snd_off
	snd_note D_4, 7
	snd_len 5
	snd_off
	snd_note E_4, 7
	snd_len 5
	snd_off
	snd_note G_3, 7
	snd_len 5
	snd_off
	snd_note D_4, 7
	snd_len 5
	snd_off
	snd_note G_3, 7
	snd_len 5
	snd_off
	snd_note Cs_4, 8
	snd_len 4
	snd_off
	snd_note D_4, 7
	snd_len 5
	snd_off
	snd_note G_3, 8
	snd_len 4
	snd_off
	snd_note D_4, 7
	snd_len 5
	snd_off
	snd_note E_4, 7
	snd_len 5
	snd_off
Trk3D_7B48:
	snd_env $59
	snd_note Cs_5, 1
	snd_note G_5, 3
	snd_note D_6, 1
	snd_note A_6, 3
	snd_note Ds_7, 4
	snd_note G_4, 6
	snd_off
	snd_note F_4
	snd_off
	snd_note Ds_4
	snd_off
	snd_note F_4
	snd_off
	snd_note Gs_4
	snd_off
	snd_note G_4
	snd_off
	snd_note F_4
	snd_off
	snd_note G_4
	snd_off
	snd_note As_4
	snd_off
	snd_note Gs_4
	snd_off
	snd_note G_4
	snd_off
	snd_note E_4
	snd_off
	snd_note Gs_4
	snd_off
	snd_note F_4
	snd_off
	snd_note D_4
	snd_off
	snd_note Cs_4, 7
	snd_len 5
	snd_off
	snd_note G_4, 6
	snd_off
	snd_note F_4
	snd_off
	snd_note Ds_4
	snd_off
	snd_note F_4
	snd_off
	snd_note Gs_4
	snd_off
	snd_note G_4
	snd_off
	snd_note F_4
	snd_off
	snd_note G_4
	snd_off
	snd_note As_4
	snd_off
	snd_note Gs_4
	snd_off
	snd_note G_4
	snd_off
	snd_note E_4
	snd_off
	snd_note Gs_4
	snd_off
	snd_note F_4
	snd_off
	snd_note D_4
	snd_off
	snd_note Cs_4, 7
	snd_len 5
	snd_off
	snd_note G_4, 6
	snd_off
	snd_note F_4
	snd_off
	snd_note Ds_4
	snd_off
	snd_note F_4
	snd_off
	snd_note Gs_4
	snd_off
	snd_note G_4
	snd_off
	snd_note F_4
	snd_off
	snd_note G_4
	snd_off
	snd_note As_4
	snd_off
	snd_note Gs_4
	snd_off
	snd_note G_4
	snd_off
	snd_note E_4
	snd_off
	snd_note Gs_4
	snd_off
	snd_note F_4
	snd_off
	snd_note D_4
	snd_off
	snd_note Cs_4, 7
	snd_len 5
	snd_off
	snd_note G_4, 6
	snd_off
	snd_note F_4
	snd_off
	snd_note Ds_4
	snd_off
	snd_note F_4
	snd_off
	snd_note Gs_4
	snd_off
	snd_note G_4
	snd_off
	snd_note F_4
	snd_off
	snd_note G_4
	snd_off
	snd_note As_4
	snd_off
	snd_note Gs_4
	snd_off
	snd_note G_4
	snd_off
	snd_note E_4
	snd_off
	snd_note Gs_4
	snd_off
	snd_note F_4
	snd_off
	snd_note D_4
	snd_off
	snd_note Ds_5, 2
	snd_note A_5
	snd_note E_6, 1
	snd_note B_6
	snd_len 2
	snd_off
	snd_note Fs_6, 4
	snd_note A_4, 6
	snd_off
	snd_note G_4
	snd_off
	snd_note F_4
	snd_off
	snd_note G_4
	snd_off
	snd_note As_4
	snd_off
	snd_note A_4
	snd_off
	snd_note G_4
	snd_off
	snd_note A_4
	snd_off
	snd_note C_5
	snd_off
	snd_note As_4
	snd_off
	snd_note A_4
	snd_off
	snd_note Fs_4
	snd_off
	snd_note As_4
	snd_off
	snd_note G_4
	snd_off
	snd_note E_4
	snd_off
	snd_note Ds_4, 7
	snd_len 5
	snd_off
	snd_note A_4, 6
	snd_off
	snd_note G_4
	snd_off
	snd_note F_4
	snd_off
	snd_note G_4
	snd_off
	snd_note As_4
	snd_off
	snd_note A_4
	snd_off
	snd_note G_4
	snd_off
	snd_note A_4
	snd_off
	snd_note C_5
	snd_off
	snd_note As_4
	snd_off
	snd_note A_4
	snd_off
	snd_note Fs_4
	snd_off
	snd_note As_4
	snd_off
	snd_note G_4
	snd_off
	snd_note E_4
	snd_off
	snd_note Ds_4, 7
	snd_len 5
	snd_off
	snd_note A_4, 6
	snd_off
	snd_note G_4
	snd_off
	snd_note F_4
	snd_off
	snd_note G_4
	snd_off
	snd_note As_4
	snd_off
	snd_note A_4
	snd_off
	snd_note G_4
	snd_off
	snd_note A_4
	snd_off
	snd_note C_5
	snd_off
	snd_note As_4
	snd_off
	snd_note A_4
	snd_off
	snd_note Fs_4
	snd_off
	snd_note As_4
	snd_off
	snd_note G_4
	snd_off
	snd_note E_4
	snd_off
	snd_note Ds_4, 7
	snd_len 5
	snd_off
	snd_note A_4, 6
	snd_off
	snd_note G_4
	snd_off
	snd_note F_4
	snd_off
	snd_note G_4
	snd_off
	snd_note As_4
	snd_off
	snd_note A_4
	snd_off
	snd_note G_4
	snd_off
	snd_note A_4
	snd_off
	snd_note C_5
	snd_off
	snd_note As_4
	snd_off
	snd_note A_4
	snd_off
	snd_note Fs_4
	snd_off
	snd_note As_4
	snd_off
	snd_note G_4
	snd_off
	snd_note E_4
	snd_off
	snd_jump Trk3D_7B48
Mus3D_13_Ch3:
	snd_duty $00
	snd_env2 $20
	snd_wave SndWave0A
	snd_transpose $F4
	snd_octenv SndOctEnv_4AE8
Trk3D_7C7D:
	snd_note G_3, 4
	snd_len 43
	snd_off
	snd_note G_3, 51
	snd_len 44
	snd_off
	snd_note Fs_3, 47
	snd_len 49
	snd_off
	snd_note F_3, 51
	snd_len 47
	snd_off
	snd_note E_3, 45
	snd_len 3
	snd_off
Trk3D_7C91:
	snd_note Ds_3, 11
	snd_len 13
	snd_off
	snd_note Ds_3, 11
	snd_len 13
	snd_off
	snd_note Ds_3, 12
	snd_off
	snd_note Ds_3, 11
	snd_len 13
	snd_off
	snd_note E_3, 12
	snd_off
	snd_note Ds_3, 13
	snd_len 11
	snd_off
	snd_note Ds_3, 13
	snd_len 11
	snd_off
	snd_note Ds_3
	snd_len 13
	snd_off
	snd_note Ds_3, 11
	snd_len 13
	snd_off
	snd_note Ds_3, 11
	snd_len 13
	snd_off
	snd_note Ds_3, 12
	snd_off
	snd_note Ds_3, 11
	snd_len 13
	snd_off
	snd_note F_3, 12
	snd_off
	snd_note Ds_3, 13
	snd_len 11
	snd_off
	snd_note Ds_3, 13
	snd_len 11
	snd_off
	snd_note Ds_3
	snd_len 13
	snd_off
	snd_note Ds_3, 11
	snd_len 13
	snd_off
	snd_note Ds_3, 11
	snd_len 13
	snd_off
	snd_note Ds_3, 12
	snd_off
	snd_note Ds_3, 11
	snd_len 13
	snd_off
	snd_note E_3, 12
	snd_off
	snd_note Ds_3, 13
	snd_len 11
	snd_off
	snd_note Ds_3, 13
	snd_len 11
	snd_off
	snd_note Ds_3
	snd_len 13
	snd_off
	snd_note Ds_3, 12
	snd_off
	snd_note Ds_3, 13
	snd_len 11
	snd_off
	snd_note Ds_3, 13
	snd_len 11
	snd_off
	snd_note Ds_3
	snd_len 13
	snd_off
	snd_note Ds_3, 11
	snd_len 13
	snd_off
	snd_note Ds_3, 11
	snd_len 13
	snd_off
	snd_note Ds_3, 12
	snd_off
	snd_note Ds_3, 11
	snd_len 13
	snd_off
	snd_note F_3, 11
	snd_len 13
	snd_off
	snd_note F_3, 11
	snd_len 13
	snd_off
	snd_note F_3, 12
	snd_off
	snd_note F_3, 11
	snd_len 13
	snd_off
	snd_note Fs_3, 12
	snd_off
	snd_note F_3, 13
	snd_len 11
	snd_off
	snd_note F_3, 13
	snd_len 11
	snd_off
	snd_note F_3
	snd_len 13
	snd_off
	snd_note F_3, 11
	snd_len 13
	snd_off
	snd_note F_3, 11
	snd_len 13
	snd_off
	snd_note F_3, 12
	snd_off
	snd_note F_3, 11
	snd_len 13
	snd_off
	snd_note G_3, 12
	snd_off
	snd_note F_3, 13
	snd_len 11
	snd_off
	snd_note F_3, 13
	snd_len 11
	snd_off
	snd_note F_3
	snd_len 13
	snd_off
	snd_note F_3, 11
	snd_len 13
	snd_off
	snd_note F_3, 11
	snd_len 13
	snd_off
	snd_note F_3, 12
	snd_off
	snd_note F_3, 11
	snd_len 13
	snd_off
	snd_note Fs_3, 12
	snd_off
	snd_note F_3, 13
	snd_len 11
	snd_off
	snd_note F_3, 13
	snd_len 11
	snd_off
	snd_note F_3
	snd_len 13
	snd_off
	snd_note F_3, 12
	snd_off
	snd_note F_3, 13
	snd_len 11
	snd_off
	snd_note F_3, 13
	snd_len 11
	snd_off
	snd_note F_3
	snd_len 13
	snd_off
	snd_note F_3, 11
	snd_len 13
	snd_off
	snd_note F_3, 11
	snd_len 13
	snd_off
	snd_note F_3, 12
	snd_off
	snd_note F_3, 11
	snd_len 13
	snd_off
	snd_jump Trk3D_7C91
Mus3D_13_Ch4:
	snd_loop 4
	snd_len 14
	snd_drum 6
	snd_len 16
	snd_drum 9
	snd_drum 8
	snd_len 33
	snd_drum 8
	snd_len 7
	snd_drum 12
	snd_len 4
	snd_drum 11
	snd_len 5
	snd_drum 9
	snd_len 1
	snd_drum 8
	snd_endloop
Trk3D_7D8E:
	snd_len 4
	snd_drum 5
	snd_len 8
	snd_drum 6
	snd_len 4
	snd_drum 6
	snd_len 12
	snd_drum 6
	snd_len 4
	snd_drum 0
	snd_drum 6
	snd_len 8
	snd_drum 6
	snd_len 4
	snd_drum 1
	snd_len 8
	snd_drum 4
	snd_drum 6
	snd_drum 6
	snd_len 4
	snd_drum 1
	snd_len 8
	snd_drum 1
	snd_len 4
	snd_drum 6
	snd_len 8
	snd_drum 6
	snd_len 4
	snd_drum 0
	snd_drum 6
	snd_len 8
	snd_drum 6
	snd_len 4
	snd_drum 6
	snd_len 8
	snd_drum 1
	snd_len 4
	snd_drum 6
	snd_drum 6
	snd_drum 0
	snd_len 8
	snd_drum 6
	snd_drum 4
	snd_len 4
	snd_drum 1
	snd_drum 6
	snd_len 8
	snd_drum 6
	snd_len 4
	snd_drum 6
	snd_len 8
	snd_drum 1
	snd_len 4
	snd_drum 1
	snd_drum 0
	snd_drum 6
	snd_drum 5
	snd_drum 1
	snd_drum 1
	snd_drum 0
	snd_drum 6
	snd_len 8
	snd_drum 1
	snd_len 4
	snd_drum 1
	snd_len 8
	snd_drum 1
	snd_len 4
	snd_drum 1
	snd_len 8
	snd_drum 6
	snd_len 4
	snd_drum 6
	snd_drum 6
	snd_len 8
	snd_off
	snd_len 4
	snd_drum 6
	snd_drum 6
	snd_drum 1
	snd_len 8
	snd_drum 6
	snd_drum 0
	snd_len 4
	snd_drum 5
	snd_drum 6
	snd_len 8
	snd_drum 6
	snd_drum 6
	snd_len 4
	snd_drum 1
	snd_len 20
	snd_drum 1
	snd_len 4
	snd_drum 5
	snd_len 8
	snd_drum 6
	snd_len 4
	snd_drum 6
	snd_len 12
	snd_drum 6
	snd_len 4
	snd_drum 0
	snd_drum 6
	snd_len 8
	snd_drum 6
	snd_len 4
	snd_drum 1
	snd_jump Trk3D_7D8E
