@ Generated from the ROM by gen_data.py; names are assigned (the ROM has no symbols apart from the
@ song name strings, which are real ROM data).
	.syntax unified

	.section .snd_midi, "a", %progbits
@ 1342 Standard MIDI Files (format 1, 24 ticks per quarter note), 4-byte aligned.
@ The files are extracted by "ww_tool.py extract".

	.global mid_0000_x_TEST
mid_0000_x_TEST:
	.incbin "midi/0000_x_TEST.mid"
	.balign 4, 0
	.global mid_0001_m_x_BGM_BOMB_2bar
mid_0001_m_x_BGM_BOMB_2bar:
	.incbin "midi/0001_m_x_BGM_BOMB_2bar.mid"
	.balign 4, 0
	.global mid_0002_m_x_BGM_BOMB_4bar
mid_0002_m_x_BGM_BOMB_4bar:
	.incbin "midi/0002_m_x_BGM_BOMB_4bar.mid"
	.balign 4, 0
	.global mid_0003_m_x_BGM_BOMB_8bar
mid_0003_m_x_BGM_BOMB_8bar:
	.incbin "midi/0003_m_x_BGM_BOMB_8bar.mid"
	.balign 4, 0
	.global mid_0004_m_BGM_01
mid_0004_m_BGM_01:
	.incbin "midi/0004_m_BGM_01.mid"
	.balign 4, 0
	.global mid_0005_m_BGM_Title_Demo_10
mid_0005_m_BGM_Title_Demo_10:
	.incbin "midi/0005_m_BGM_Title_Demo_10.mid"
	.balign 4, 0
	.global mid_0006_m_BGM_Title_Demo_NEWS
mid_0006_m_BGM_Title_Demo_NEWS:
	.incbin "midi/0006_m_BGM_Title_Demo_NEWS.mid"
	.balign 4, 0
	.global mid_0007_m_BGM_Title_Demo_15
mid_0007_m_BGM_Title_Demo_15:
	.incbin "midi/0007_m_BGM_Title_Demo_15.mid"
	.balign 4, 0
	.global mid_0008_m_BGM_Title_Demo_20
mid_0008_m_BGM_Title_Demo_20:
	.incbin "midi/0008_m_BGM_Title_Demo_20.mid"
	.balign 4, 0
	.global mid_0009_m_BGM_Title_Demo_30
mid_0009_m_BGM_Title_Demo_30:
	.incbin "midi/0009_m_BGM_Title_Demo_30.mid"
	.balign 4, 0
	.global mid_0010_m_BGM_Title_01
mid_0010_m_BGM_Title_01:
	.incbin "midi/0010_m_BGM_Title_01.mid"
	.balign 4, 0
	.global mid_0011_m_BGM_Select_01
mid_0011_m_BGM_Select_01:
	.incbin "midi/0011_m_BGM_Select_01.mid"
	.balign 4, 0
	.global mid_0012_m_BGM_Select_02
mid_0012_m_BGM_Select_02:
	.incbin "midi/0012_m_BGM_Select_02.mid"
	.balign 4, 0
	.global mid_0013_s_Demo_MAP_1
mid_0013_s_Demo_MAP_1:
	.incbin "midi/0013_s_Demo_MAP_1.mid"
	.balign 4, 0
	.global mid_0014_m_BGM_Demo_EP_MAP_1
mid_0014_m_BGM_Demo_EP_MAP_1:
	.incbin "midi/0014_m_BGM_Demo_EP_MAP_1.mid"
	.balign 4, 0
	.global mid_0015_m_BGM_Ending_01
mid_0015_m_BGM_Ending_01:
	.incbin "midi/0015_m_BGM_Ending_01.mid"
	.balign 4, 0
	.global mid_0016_m_BGM_Ending_02
mid_0016_m_BGM_Ending_02:
	.incbin "midi/0016_m_BGM_Ending_02.mid"
	.balign 4, 0
	.global mid_0017_m_BGM_DrMario_Title
mid_0017_m_BGM_DrMario_Title:
	.incbin "midi/0017_m_BGM_DrMario_Title.mid"
	.balign 4, 0
	.global mid_0018_m_BGM_DrMario_Select
mid_0018_m_BGM_DrMario_Select:
	.incbin "midi/0018_m_BGM_DrMario_Select.mid"
	.balign 4, 0
	.global mid_0019_m_BGM_DrMario_Game_Hot
mid_0019_m_BGM_DrMario_Game_Hot:
	.incbin "midi/0019_m_BGM_DrMario_Game_Hot.mid"
	.balign 4, 0
	.global mid_0020_m_BGM_DrMario_Clear
mid_0020_m_BGM_DrMario_Clear:
	.incbin "midi/0020_m_BGM_DrMario_Clear.mid"
	.balign 4, 0
	.global mid_0021_m_BGM_DrMario_OVER
mid_0021_m_BGM_DrMario_OVER:
	.incbin "midi/0021_m_BGM_DrMario_OVER.mid"
	.balign 4, 0
	.global mid_0022_m_BGM_DrMario_Demo
mid_0022_m_BGM_DrMario_Demo:
	.incbin "midi/0022_m_BGM_DrMario_Demo.mid"
	.balign 4, 0
	.global mid_0023_s_Demo_DrMario_UFO_1
mid_0023_s_Demo_DrMario_UFO_1:
	.incbin "midi/0023_s_Demo_DrMario_UFO_1.mid"
	.balign 4, 0
	.global mid_0024_s_Demo_DrMario_UFO_2
mid_0024_s_Demo_DrMario_UFO_2:
	.incbin "midi/0024_s_Demo_DrMario_UFO_2.mid"
	.balign 4, 0
	.global mid_0025_m_BGM_DrMario_Ending
mid_0025_m_BGM_DrMario_Ending:
	.incbin "midi/0025_m_BGM_DrMario_Ending.mid"
	.balign 4, 0
	.global mid_0026_m_BGM_PAINT_Title
mid_0026_m_BGM_PAINT_Title:
	.incbin "midi/0026_m_BGM_PAINT_Title.mid"
	.balign 4, 0
	.global mid_0027_m_BGM_PAINT_BGM_1
mid_0027_m_BGM_PAINT_BGM_1:
	.incbin "midi/0027_m_BGM_PAINT_BGM_1.mid"
	.balign 4, 0
	.global mid_0028_m_BGM_PAINT_BGM_2
mid_0028_m_BGM_PAINT_BGM_2:
	.incbin "midi/0028_m_BGM_PAINT_BGM_2.mid"
	.balign 4, 0
	.global mid_0029_m_BGM_PAINT_BGM_3
mid_0029_m_BGM_PAINT_BGM_3:
	.incbin "midi/0029_m_BGM_PAINT_BGM_3.mid"
	.balign 4, 0
	.global mid_0030_m_BGM_PAINT_BOSS
mid_0030_m_BGM_PAINT_BOSS:
	.incbin "midi/0030_m_BGM_PAINT_BOSS.mid"
	.balign 4, 0
	.global mid_0031_m_BGM_PAINT_GameOver
mid_0031_m_BGM_PAINT_GameOver:
	.incbin "midi/0031_m_BGM_PAINT_GameOver.mid"
	.balign 4, 0
	.global mid_0032_m_BGM_PAINT_Fanfare
mid_0032_m_BGM_PAINT_Fanfare:
	.incbin "midi/0032_m_BGM_PAINT_Fanfare.mid"
	.balign 4, 0
	.global mid_0033_m_BGM_Sheriff_Title
mid_0033_m_BGM_Sheriff_Title:
	.incbin "midi/0033_m_BGM_Sheriff_Title.mid"
	.balign 4, 0
	.global mid_0034_m_BGM_Sheriff_START_1
mid_0034_m_BGM_Sheriff_START_1:
	.incbin "midi/0034_m_BGM_Sheriff_START_1.mid"
	.balign 4, 0
	.global mid_0035_m_BGM_Sheriff_Game_1
mid_0035_m_BGM_Sheriff_Game_1:
	.incbin "midi/0035_m_BGM_Sheriff_Game_1.mid"
	.balign 4, 0
	.global mid_0036_m_BGM_Sheriff_BIRD_1
mid_0036_m_BGM_Sheriff_BIRD_1:
	.incbin "midi/0036_m_BGM_Sheriff_BIRD_1.mid"
	.balign 4, 0
	.global mid_0037_m_BGM_Sheriff_TEKI_IN_1
mid_0037_m_BGM_Sheriff_TEKI_IN_1:
	.incbin "midi/0037_m_BGM_Sheriff_TEKI_IN_1.mid"
	.balign 4, 0
	.global mid_0038_m_BGM_Sheriff_CLEAR_1
mid_0038_m_BGM_Sheriff_CLEAR_1:
	.incbin "midi/0038_m_BGM_Sheriff_CLEAR_1.mid"
	.balign 4, 0
	.global mid_0039_m_BGM_Sheriff_CLEAR_HART
mid_0039_m_BGM_Sheriff_CLEAR_HART:
	.incbin "midi/0039_m_BGM_Sheriff_CLEAR_HART.mid"
	.balign 4, 0
	.global mid_0040_m_BGM_Sheriff_GameOver
mid_0040_m_BGM_Sheriff_GameOver:
	.incbin "midi/0040_m_BGM_Sheriff_GameOver.mid"
	.balign 4, 0
	.global mid_0041_m_BGM_GYORO_Title_01
mid_0041_m_BGM_GYORO_Title_01:
	.incbin "midi/0041_m_BGM_GYORO_Title_01.mid"
	.balign 4, 0
	.global mid_0042_m_BGM_GYORO_Game_Type_1
mid_0042_m_BGM_GYORO_Game_Type_1:
	.incbin "midi/0042_m_BGM_GYORO_Game_Type_1.mid"
	.balign 4, 0
	.global mid_0043_m_BGM_GYORO_Game_Type_2
mid_0043_m_BGM_GYORO_Game_Type_2:
	.incbin "midi/0043_m_BGM_GYORO_Game_Type_2.mid"
	.balign 4, 0
	.global mid_0044_m_BGM_GYORO_Game_Type_3
mid_0044_m_BGM_GYORO_Game_Type_3:
	.incbin "midi/0044_m_BGM_GYORO_Game_Type_3.mid"
	.balign 4, 0
	.global mid_0045_m_BGM_GYORO_Game_Type_4
mid_0045_m_BGM_GYORO_Game_Type_4:
	.incbin "midi/0045_m_BGM_GYORO_Game_Type_4.mid"
	.balign 4, 0
	.global mid_0046_m_BGM_GYORO_Game_50000
mid_0046_m_BGM_GYORO_Game_50000:
	.incbin "midi/0046_m_BGM_GYORO_Game_50000.mid"
	.balign 4, 0
	.global mid_0047_m_BGM_GYORO_Game_50000_2
mid_0047_m_BGM_GYORO_Game_50000_2:
	.incbin "midi/0047_m_BGM_GYORO_Game_50000_2.mid"
	.balign 4, 0
	.global mid_0048_m_BGM_GYORO_Game_50000_3
mid_0048_m_BGM_GYORO_Game_50000_3:
	.incbin "midi/0048_m_BGM_GYORO_Game_50000_3.mid"
	.balign 4, 0
	.global mid_0049_m_BGM_GYORO_GameOver_01
mid_0049_m_BGM_GYORO_GameOver_01:
	.incbin "midi/0049_m_BGM_GYORO_GameOver_01.mid"
	.balign 4, 0
	.global mid_0050_m_BGM_Wario_Demo_1
mid_0050_m_BGM_Wario_Demo_1:
	.incbin "midi/0050_m_BGM_Wario_Demo_1.mid"
	.balign 4, 0
	.global mid_0051_m_BGM_Wario_Turn_NEXT_01
mid_0051_m_BGM_Wario_Turn_NEXT_01:
	.incbin "midi/0051_m_BGM_Wario_Turn_NEXT_01.mid"
	.balign 4, 0
	.global mid_0052_m_BGM_Wario_Turn_NEXT_02
mid_0052_m_BGM_Wario_Turn_NEXT_02:
	.incbin "midi/0052_m_BGM_Wario_Turn_NEXT_02.mid"
	.balign 4, 0
	.global mid_0053_m_BGM_Wario_Turn_OK_01
mid_0053_m_BGM_Wario_Turn_OK_01:
	.incbin "midi/0053_m_BGM_Wario_Turn_OK_01.mid"
	.balign 4, 0
	.global mid_0054_m_BGM_Wario_Turn_OK_02
mid_0054_m_BGM_Wario_Turn_OK_02:
	.incbin "midi/0054_m_BGM_Wario_Turn_OK_02.mid"
	.balign 4, 0
	.global mid_0055_m_BGM_Wario_Turn_NG_01
mid_0055_m_BGM_Wario_Turn_NG_01:
	.incbin "midi/0055_m_BGM_Wario_Turn_NG_01.mid"
	.balign 4, 0
	.global mid_0056_m_BGM_Wario_Turn_NG_02
mid_0056_m_BGM_Wario_Turn_NG_02:
	.incbin "midi/0056_m_BGM_Wario_Turn_NG_02.mid"
	.balign 4, 0
	.global mid_0057_m_BGM_Wario_END_01
mid_0057_m_BGM_Wario_END_01:
	.incbin "midi/0057_m_BGM_Wario_END_01.mid"
	.balign 4, 0
	.global mid_0058_m_BGM_Wario_END_Loop_01
mid_0058_m_BGM_Wario_END_Loop_01:
	.incbin "midi/0058_m_BGM_Wario_END_Loop_01.mid"
	.balign 4, 0
	.global mid_0059_m_BGM_Wario_EP_10
mid_0059_m_BGM_Wario_EP_10:
	.incbin "midi/0059_m_BGM_Wario_EP_10.mid"
	.balign 4, 0
	.global mid_0060_m_BGM_Wario_EP_STAFF_01
mid_0060_m_BGM_Wario_EP_STAFF_01:
	.incbin "midi/0060_m_BGM_Wario_EP_STAFF_01.mid"
	.balign 4, 0
	.global mid_0061_m_BGM_Wario_BOSS_10
mid_0061_m_BGM_Wario_BOSS_10:
	.incbin "midi/0061_m_BGM_Wario_BOSS_10.mid"
	.balign 4, 0
	.global mid_0062_m_BGM_Wario_BOSS_90
mid_0062_m_BGM_Wario_BOSS_90:
	.incbin "midi/0062_m_BGM_Wario_BOSS_90.mid"
	.balign 4, 0
	.global mid_0063_m_BGM_Tutorial_Demo_1
mid_0063_m_BGM_Tutorial_Demo_1:
	.incbin "midi/0063_m_BGM_Tutorial_Demo_1.mid"
	.balign 4, 0
	.global mid_0064_m_BGM_Tutorial_READY_01
mid_0064_m_BGM_Tutorial_READY_01:
	.incbin "midi/0064_m_BGM_Tutorial_READY_01.mid"
	.balign 4, 0
	.global mid_0065_m_BGM_Tutorial_Turn_OK_01
mid_0065_m_BGM_Tutorial_Turn_OK_01:
	.incbin "midi/0065_m_BGM_Tutorial_Turn_OK_01.mid"
	.balign 4, 0
	.global mid_0066_m_BGM_Tutorial_Turn_OK_02
mid_0066_m_BGM_Tutorial_Turn_OK_02:
	.incbin "midi/0066_m_BGM_Tutorial_Turn_OK_02.mid"
	.balign 4, 0
	.global mid_0067_m_BGM_Tutorial_Turn_NG_01
mid_0067_m_BGM_Tutorial_Turn_NG_01:
	.incbin "midi/0067_m_BGM_Tutorial_Turn_NG_01.mid"
	.balign 4, 0
	.global mid_0068_m_BGM_Tutorial_Turn_NG_02
mid_0068_m_BGM_Tutorial_Turn_NG_02:
	.incbin "midi/0068_m_BGM_Tutorial_Turn_NG_02.mid"
	.balign 4, 0
	.global mid_0069_m_BGM_Tutorial_Turn_NEXT_0
mid_0069_m_BGM_Tutorial_Turn_NEXT_0:
	.incbin "midi/0069_m_BGM_Tutorial_Turn_NEXT_0.mid"
	.balign 4, 0
	.global mid_0070_m_BGM_Tutorial_Turn_NEXT_1
mid_0070_m_BGM_Tutorial_Turn_NEXT_1:
	.incbin "midi/0070_m_BGM_Tutorial_Turn_NEXT_1.mid"
	.balign 4, 0
	.global mid_0071_m_BGM_Tutorial_END_01
mid_0071_m_BGM_Tutorial_END_01:
	.incbin "midi/0071_m_BGM_Tutorial_END_01.mid"
	.balign 4, 0
	.global mid_0072_m_BGM_Tutorial_BOSS_FF_ST
mid_0072_m_BGM_Tutorial_BOSS_FF_ST:
	.incbin "midi/0072_m_BGM_Tutorial_BOSS_FF_ST.mid"
	.balign 4, 0
	.global mid_0073_m_BGM_Tutorial_BOSS_10
mid_0073_m_BGM_Tutorial_BOSS_10:
	.incbin "midi/0073_m_BGM_Tutorial_BOSS_10.mid"
	.balign 4, 0
	.global mid_0074_m_BGM_BOMB_Demo_AFRO_0
mid_0074_m_BGM_BOMB_Demo_AFRO_0:
	.incbin "midi/0074_m_BGM_BOMB_Demo_AFRO_0.mid"
	.balign 4, 0
	.global mid_0075_m_BGM_BOMB_Demo_AFRO_1
mid_0075_m_BGM_BOMB_Demo_AFRO_1:
	.incbin "midi/0075_m_BGM_BOMB_Demo_AFRO_1.mid"
	.balign 4, 0
	.global mid_0076_m_BGM_BOMB_Demo_AFRO_2
mid_0076_m_BGM_BOMB_Demo_AFRO_2:
	.incbin "midi/0076_m_BGM_BOMB_Demo_AFRO_2.mid"
	.balign 4, 0
	.global mid_0077_m_BGM_BOMB_Demo_AFRO_3
mid_0077_m_BGM_BOMB_Demo_AFRO_3:
	.incbin "midi/0077_m_BGM_BOMB_Demo_AFRO_3.mid"
	.balign 4, 0
	.global mid_0078_m_BGM_BOMB_Demo_AFRO_Loop
mid_0078_m_BGM_BOMB_Demo_AFRO_Loop:
	.incbin "midi/0078_m_BGM_BOMB_Demo_AFRO_Loop.mid"
	.balign 4, 0
	.global mid_0079_m_BGM_BOMB_Demo_AFRO_Loop_B
mid_0079_m_BGM_BOMB_Demo_AFRO_Loop_B:
	.incbin "midi/0079_m_BGM_BOMB_Demo_AFRO_Loop_B.mid"
	.balign 4, 0
	.global mid_0080_m_BGM_BOMB_Demo_AFRO_Loop_C
mid_0080_m_BGM_BOMB_Demo_AFRO_Loop_C:
	.incbin "midi/0080_m_BGM_BOMB_Demo_AFRO_Loop_C.mid"
	.balign 4, 0
	.global mid_0081_m_BGM_BOMB_Demo_AFRO_Loop2
mid_0081_m_BGM_BOMB_Demo_AFRO_Loop2:
	.incbin "midi/0081_m_BGM_BOMB_Demo_AFRO_Loop2.mid"
	.balign 4, 0
	.global mid_0082_m_BGM_BOMB_Demo_AFRO_Loop22
mid_0082_m_BGM_BOMB_Demo_AFRO_Loop22:
	.incbin "midi/0082_m_BGM_BOMB_Demo_AFRO_Loop22.mid"
	.balign 4, 0
	.global mid_0083_m_BGM_BOMB_Demo_AFRO_Loop23
mid_0083_m_BGM_BOMB_Demo_AFRO_Loop23:
	.incbin "midi/0083_m_BGM_BOMB_Demo_AFRO_Loop23.mid"
	.balign 4, 0
	.global mid_0084_m_BGM_BOMB_Demo_AFRO_NEXT1A
mid_0084_m_BGM_BOMB_Demo_AFRO_NEXT1A:
	.incbin "midi/0084_m_BGM_BOMB_Demo_AFRO_NEXT1A.mid"
	.balign 4, 0
	.global mid_0085_m_BGM_BOMB_Demo_AFRO_NEXT2A
mid_0085_m_BGM_BOMB_Demo_AFRO_NEXT2A:
	.incbin "midi/0085_m_BGM_BOMB_Demo_AFRO_NEXT2A.mid"
	.balign 4, 0
	.global mid_0086_m_BGM_BOMB_Demo_AFRO_NEXT1B
mid_0086_m_BGM_BOMB_Demo_AFRO_NEXT1B:
	.incbin "midi/0086_m_BGM_BOMB_Demo_AFRO_NEXT1B.mid"
	.balign 4, 0
	.global mid_0087_m_BGM_BOMB_Demo_AFRO_NEXT2B
mid_0087_m_BGM_BOMB_Demo_AFRO_NEXT2B:
	.incbin "midi/0087_m_BGM_BOMB_Demo_AFRO_NEXT2B.mid"
	.balign 4, 0
	.global mid_0088_m_BGM_BOMB_Demo_AFRO_NEXT1C
mid_0088_m_BGM_BOMB_Demo_AFRO_NEXT1C:
	.incbin "midi/0088_m_BGM_BOMB_Demo_AFRO_NEXT1C.mid"
	.balign 4, 0
	.global mid_0089_m_BGM_BOMB_Demo_AFRO_NEXT2C
mid_0089_m_BGM_BOMB_Demo_AFRO_NEXT2C:
	.incbin "midi/0089_m_BGM_BOMB_Demo_AFRO_NEXT2C.mid"
	.balign 4, 0
	.global mid_0090_m_BGM_AFRO_Turn_NEXT_00
mid_0090_m_BGM_AFRO_Turn_NEXT_00:
	.incbin "midi/0090_m_BGM_AFRO_Turn_NEXT_00.mid"
	.balign 4, 0
	.global mid_0091_m_BGM_AFRO_Turn_OK_01
mid_0091_m_BGM_AFRO_Turn_OK_01:
	.incbin "midi/0091_m_BGM_AFRO_Turn_OK_01.mid"
	.balign 4, 0
	.global mid_0092_m_BGM_AFRO_Turn_OK_02
mid_0092_m_BGM_AFRO_Turn_OK_02:
	.incbin "midi/0092_m_BGM_AFRO_Turn_OK_02.mid"
	.balign 4, 0
	.global mid_0093_m_BGM_AFRO_Turn_NG_01
mid_0093_m_BGM_AFRO_Turn_NG_01:
	.incbin "midi/0093_m_BGM_AFRO_Turn_NG_01.mid"
	.balign 4, 0
	.global mid_0094_m_BGM_AFRO_Turn_NG_02
mid_0094_m_BGM_AFRO_Turn_NG_02:
	.incbin "midi/0094_m_BGM_AFRO_Turn_NG_02.mid"
	.balign 4, 0
	.global mid_0095_m_BGM_AFRO_Turn_NEXT_01
mid_0095_m_BGM_AFRO_Turn_NEXT_01:
	.incbin "midi/0095_m_BGM_AFRO_Turn_NEXT_01.mid"
	.balign 4, 0
	.global mid_0096_m_BGM_AFRO_Turn_NEXT_02
mid_0096_m_BGM_AFRO_Turn_NEXT_02:
	.incbin "midi/0096_m_BGM_AFRO_Turn_NEXT_02.mid"
	.balign 4, 0
	.global mid_0097_m_BGM_BOMB_Demo_AFRO_EP_A1
mid_0097_m_BGM_BOMB_Demo_AFRO_EP_A1:
	.incbin "midi/0097_m_BGM_BOMB_Demo_AFRO_EP_A1.mid"
	.balign 4, 0
	.global mid_0098_m_BGM_BOMB_Demo_AFRO_EP_A2
mid_0098_m_BGM_BOMB_Demo_AFRO_EP_A2:
	.incbin "midi/0098_m_BGM_BOMB_Demo_AFRO_EP_A2.mid"
	.balign 4, 0
	.global mid_0099_m_BGM_AFRO_BOSS_10
mid_0099_m_BGM_AFRO_BOSS_10:
	.incbin "midi/0099_m_BGM_AFRO_BOSS_10.mid"
	.balign 4, 0
	.global mid_0100_m_BGM_AFRO_BOSS_11
mid_0100_m_BGM_AFRO_BOSS_11:
	.incbin "midi/0100_m_BGM_AFRO_BOSS_11.mid"
	.balign 4, 0
	.global mid_0101_m_BGM_AFRO_BOSS_21
mid_0101_m_BGM_AFRO_BOSS_21:
	.incbin "midi/0101_m_BGM_AFRO_BOSS_21.mid"
	.balign 4, 0
	.global mid_0102_m_BGM_AFRO_BOSS_31
mid_0102_m_BGM_AFRO_BOSS_31:
	.incbin "midi/0102_m_BGM_AFRO_BOSS_31.mid"
	.balign 4, 0
	.global mid_0103_m_BGM_AFRO_BOSS_41
mid_0103_m_BGM_AFRO_BOSS_41:
	.incbin "midi/0103_m_BGM_AFRO_BOSS_41.mid"
	.balign 4, 0
	.global mid_0104_m_BGM_AFRO_BOSS_51
mid_0104_m_BGM_AFRO_BOSS_51:
	.incbin "midi/0104_m_BGM_AFRO_BOSS_51.mid"
	.balign 4, 0
	.global mid_0105_m_BGM_DraBuru_INTRO_0
mid_0105_m_BGM_DraBuru_INTRO_0:
	.incbin "midi/0105_m_BGM_DraBuru_INTRO_0.mid"
	.balign 4, 0
	.global mid_0106_m_BGM_DraBuru_INTRO_1
mid_0106_m_BGM_DraBuru_INTRO_1:
	.incbin "midi/0106_m_BGM_DraBuru_INTRO_1.mid"
	.balign 4, 0
	.global mid_0107_m_BGM_DraBuru_INTRO_2
mid_0107_m_BGM_DraBuru_INTRO_2:
	.incbin "midi/0107_m_BGM_DraBuru_INTRO_2.mid"
	.balign 4, 0
	.global mid_0108_m_BGM_DraBuru_INTRO_3
mid_0108_m_BGM_DraBuru_INTRO_3:
	.incbin "midi/0108_m_BGM_DraBuru_INTRO_3.mid"
	.balign 4, 0
	.global mid_0109_m_BGM_DraBuru_01_IN
mid_0109_m_BGM_DraBuru_01_IN:
	.incbin "midi/0109_m_BGM_DraBuru_01_IN.mid"
	.balign 4, 0
	.global mid_0110_m_BGM_DraBuru_02_IN
mid_0110_m_BGM_DraBuru_02_IN:
	.incbin "midi/0110_m_BGM_DraBuru_02_IN.mid"
	.balign 4, 0
	.global mid_0111_m_BGM_DraBuru_03_IN
mid_0111_m_BGM_DraBuru_03_IN:
	.incbin "midi/0111_m_BGM_DraBuru_03_IN.mid"
	.balign 4, 0
	.global mid_0112_m_BGM_DraBuru_04_IN
mid_0112_m_BGM_DraBuru_04_IN:
	.incbin "midi/0112_m_BGM_DraBuru_04_IN.mid"
	.balign 4, 0
	.global mid_0113_m_BGM_DraBuru_01_Intro
mid_0113_m_BGM_DraBuru_01_Intro:
	.incbin "midi/0113_m_BGM_DraBuru_01_Intro.mid"
	.balign 4, 0
	.global mid_0114_m_BGM_DraBuru_01_01
mid_0114_m_BGM_DraBuru_01_01:
	.incbin "midi/0114_m_BGM_DraBuru_01_01.mid"
	.balign 4, 0
	.global mid_0115_m_BGM_DraBuru_01_02
mid_0115_m_BGM_DraBuru_01_02:
	.incbin "midi/0115_m_BGM_DraBuru_01_02.mid"
	.balign 4, 0
	.global mid_0116_m_BGM_DraBuru_01_03
mid_0116_m_BGM_DraBuru_01_03:
	.incbin "midi/0116_m_BGM_DraBuru_01_03.mid"
	.balign 4, 0
	.global mid_0117_m_BGM_DraBuru_01_04
mid_0117_m_BGM_DraBuru_01_04:
	.incbin "midi/0117_m_BGM_DraBuru_01_04.mid"
	.balign 4, 0
	.global mid_0118_m_BGM_DraBuru_01_05
mid_0118_m_BGM_DraBuru_01_05:
	.incbin "midi/0118_m_BGM_DraBuru_01_05.mid"
	.balign 4, 0
	.global mid_0119_m_BGM_DraBuru_01_06
mid_0119_m_BGM_DraBuru_01_06:
	.incbin "midi/0119_m_BGM_DraBuru_01_06.mid"
	.balign 4, 0
	.global mid_0120_m_BGM_DraBuru_01_07
mid_0120_m_BGM_DraBuru_01_07:
	.incbin "midi/0120_m_BGM_DraBuru_01_07.mid"
	.balign 4, 0
	.global mid_0121_m_BGM_DraBuru_01_08
mid_0121_m_BGM_DraBuru_01_08:
	.incbin "midi/0121_m_BGM_DraBuru_01_08.mid"
	.balign 4, 0
	.global mid_0122_m_BGM_DraBuru_01_END
mid_0122_m_BGM_DraBuru_01_END:
	.incbin "midi/0122_m_BGM_DraBuru_01_END.mid"
	.balign 4, 0
	.global mid_0123_m_BGM_DraBuru_01_BOSS_IN
mid_0123_m_BGM_DraBuru_01_BOSS_IN:
	.incbin "midi/0123_m_BGM_DraBuru_01_BOSS_IN.mid"
	.balign 4, 0
	.global mid_0124_m_BGM_DraBuru_01_SpeedUp
mid_0124_m_BGM_DraBuru_01_SpeedUp:
	.incbin "midi/0124_m_BGM_DraBuru_01_SpeedUp.mid"
	.balign 4, 0
	.global mid_0125_m_BGM_DraBuru_02_Intro
mid_0125_m_BGM_DraBuru_02_Intro:
	.incbin "midi/0125_m_BGM_DraBuru_02_Intro.mid"
	.balign 4, 0
	.global mid_0126_m_BGM_DraBuru_02_01
mid_0126_m_BGM_DraBuru_02_01:
	.incbin "midi/0126_m_BGM_DraBuru_02_01.mid"
	.balign 4, 0
	.global mid_0127_m_BGM_DraBuru_02_02
mid_0127_m_BGM_DraBuru_02_02:
	.incbin "midi/0127_m_BGM_DraBuru_02_02.mid"
	.balign 4, 0
	.global mid_0128_m_BGM_DraBuru_02_03
mid_0128_m_BGM_DraBuru_02_03:
	.incbin "midi/0128_m_BGM_DraBuru_02_03.mid"
	.balign 4, 0
	.global mid_0129_m_BGM_DraBuru_02_04
mid_0129_m_BGM_DraBuru_02_04:
	.incbin "midi/0129_m_BGM_DraBuru_02_04.mid"
	.balign 4, 0
	.global mid_0130_m_BGM_DraBuru_02_05
mid_0130_m_BGM_DraBuru_02_05:
	.incbin "midi/0130_m_BGM_DraBuru_02_05.mid"
	.balign 4, 0
	.global mid_0131_m_BGM_DraBuru_02_06
mid_0131_m_BGM_DraBuru_02_06:
	.incbin "midi/0131_m_BGM_DraBuru_02_06.mid"
	.balign 4, 0
	.global mid_0132_m_BGM_DraBuru_02_07
mid_0132_m_BGM_DraBuru_02_07:
	.incbin "midi/0132_m_BGM_DraBuru_02_07.mid"
	.balign 4, 0
	.global mid_0133_m_BGM_DraBuru_02_08
mid_0133_m_BGM_DraBuru_02_08:
	.incbin "midi/0133_m_BGM_DraBuru_02_08.mid"
	.balign 4, 0
	.global mid_0134_m_BGM_DraBuru_02_END
mid_0134_m_BGM_DraBuru_02_END:
	.incbin "midi/0134_m_BGM_DraBuru_02_END.mid"
	.balign 4, 0
	.global mid_0135_m_BGM_DraBuru_02_BOSS_IN
mid_0135_m_BGM_DraBuru_02_BOSS_IN:
	.incbin "midi/0135_m_BGM_DraBuru_02_BOSS_IN.mid"
	.balign 4, 0
	.global mid_0136_m_BGM_DraBuru_02_SpeedUp
mid_0136_m_BGM_DraBuru_02_SpeedUp:
	.incbin "midi/0136_m_BGM_DraBuru_02_SpeedUp.mid"
	.balign 4, 0
	.global mid_0137_m_BGM_DraBuru_03_Intro
mid_0137_m_BGM_DraBuru_03_Intro:
	.incbin "midi/0137_m_BGM_DraBuru_03_Intro.mid"
	.balign 4, 0
	.global mid_0138_m_BGM_DraBuru_03_01
mid_0138_m_BGM_DraBuru_03_01:
	.incbin "midi/0138_m_BGM_DraBuru_03_01.mid"
	.balign 4, 0
	.global mid_0139_m_BGM_DraBuru_03_02
mid_0139_m_BGM_DraBuru_03_02:
	.incbin "midi/0139_m_BGM_DraBuru_03_02.mid"
	.balign 4, 0
	.global mid_0140_m_BGM_DraBuru_03_03
mid_0140_m_BGM_DraBuru_03_03:
	.incbin "midi/0140_m_BGM_DraBuru_03_03.mid"
	.balign 4, 0
	.global mid_0141_m_BGM_DraBuru_03_04
mid_0141_m_BGM_DraBuru_03_04:
	.incbin "midi/0141_m_BGM_DraBuru_03_04.mid"
	.balign 4, 0
	.global mid_0142_m_BGM_DraBuru_03_05
mid_0142_m_BGM_DraBuru_03_05:
	.incbin "midi/0142_m_BGM_DraBuru_03_05.mid"
	.balign 4, 0
	.global mid_0143_m_BGM_DraBuru_03_06
mid_0143_m_BGM_DraBuru_03_06:
	.incbin "midi/0143_m_BGM_DraBuru_03_06.mid"
	.balign 4, 0
	.global mid_0144_m_BGM_DraBuru_03_07
mid_0144_m_BGM_DraBuru_03_07:
	.incbin "midi/0144_m_BGM_DraBuru_03_07.mid"
	.balign 4, 0
	.global mid_0145_m_BGM_DraBuru_03_08
mid_0145_m_BGM_DraBuru_03_08:
	.incbin "midi/0145_m_BGM_DraBuru_03_08.mid"
	.balign 4, 0
	.global mid_0146_m_BGM_DraBuru_03_END
mid_0146_m_BGM_DraBuru_03_END:
	.incbin "midi/0146_m_BGM_DraBuru_03_END.mid"
	.balign 4, 0
	.global mid_0147_m_BGM_DraBuru_03_BOSS_IN
mid_0147_m_BGM_DraBuru_03_BOSS_IN:
	.incbin "midi/0147_m_BGM_DraBuru_03_BOSS_IN.mid"
	.balign 4, 0
	.global mid_0148_m_BGM_DraBuru_03_SpeedUp
mid_0148_m_BGM_DraBuru_03_SpeedUp:
	.incbin "midi/0148_m_BGM_DraBuru_03_SpeedUp.mid"
	.balign 4, 0
	.global mid_0149_m_BGM_DraBuru_04_Intro
mid_0149_m_BGM_DraBuru_04_Intro:
	.incbin "midi/0149_m_BGM_DraBuru_04_Intro.mid"
	.balign 4, 0
	.global mid_0150_m_BGM_DraBuru_04_01
mid_0150_m_BGM_DraBuru_04_01:
	.incbin "midi/0150_m_BGM_DraBuru_04_01.mid"
	.balign 4, 0
	.global mid_0151_m_BGM_DraBuru_04_02
mid_0151_m_BGM_DraBuru_04_02:
	.incbin "midi/0151_m_BGM_DraBuru_04_02.mid"
	.balign 4, 0
	.global mid_0152_m_BGM_DraBuru_04_03
mid_0152_m_BGM_DraBuru_04_03:
	.incbin "midi/0152_m_BGM_DraBuru_04_03.mid"
	.balign 4, 0
	.global mid_0153_m_BGM_DraBuru_04_04
mid_0153_m_BGM_DraBuru_04_04:
	.incbin "midi/0153_m_BGM_DraBuru_04_04.mid"
	.balign 4, 0
	.global mid_0154_m_BGM_DraBuru_04_05
mid_0154_m_BGM_DraBuru_04_05:
	.incbin "midi/0154_m_BGM_DraBuru_04_05.mid"
	.balign 4, 0
	.global mid_0155_m_BGM_DraBuru_04_06
mid_0155_m_BGM_DraBuru_04_06:
	.incbin "midi/0155_m_BGM_DraBuru_04_06.mid"
	.balign 4, 0
	.global mid_0156_m_BGM_DraBuru_04_07
mid_0156_m_BGM_DraBuru_04_07:
	.incbin "midi/0156_m_BGM_DraBuru_04_07.mid"
	.balign 4, 0
	.global mid_0157_m_BGM_DraBuru_04_08
mid_0157_m_BGM_DraBuru_04_08:
	.incbin "midi/0157_m_BGM_DraBuru_04_08.mid"
	.balign 4, 0
	.global mid_0158_m_BGM_DraBuru_04_END
mid_0158_m_BGM_DraBuru_04_END:
	.incbin "midi/0158_m_BGM_DraBuru_04_END.mid"
	.balign 4, 0
	.global mid_0159_m_BGM_DraBuru_04_BOSS_IN
mid_0159_m_BGM_DraBuru_04_BOSS_IN:
	.incbin "midi/0159_m_BGM_DraBuru_04_BOSS_IN.mid"
	.balign 4, 0
	.global mid_0160_m_BGM_DraBuru_04_SpeedUp
mid_0160_m_BGM_DraBuru_04_SpeedUp:
	.incbin "midi/0160_m_BGM_DraBuru_04_SpeedUp.mid"
	.balign 4, 0
	.global mid_0161_m_BGM_DraBuru_NEXTSTAGE
mid_0161_m_BGM_DraBuru_NEXTSTAGE:
	.incbin "midi/0161_m_BGM_DraBuru_NEXTSTAGE.mid"
	.balign 4, 0
	.global mid_0162_m_BGM_DraBuru_Turn_OK_01
mid_0162_m_BGM_DraBuru_Turn_OK_01:
	.incbin "midi/0162_m_BGM_DraBuru_Turn_OK_01.mid"
	.balign 4, 0
	.global mid_0163_m_BGM_DraBuru_Turn_OK_02
mid_0163_m_BGM_DraBuru_Turn_OK_02:
	.incbin "midi/0163_m_BGM_DraBuru_Turn_OK_02.mid"
	.balign 4, 0
	.global mid_0164_m_BGM_DraBuru_Turn_NG_01
mid_0164_m_BGM_DraBuru_Turn_NG_01:
	.incbin "midi/0164_m_BGM_DraBuru_Turn_NG_01.mid"
	.balign 4, 0
	.global mid_0165_m_BGM_DraBuru_Turn_NG_02
mid_0165_m_BGM_DraBuru_Turn_NG_02:
	.incbin "midi/0165_m_BGM_DraBuru_Turn_NG_02.mid"
	.balign 4, 0
	.global mid_0166_m_BGM_DraBuru_Turn_NEXT_1
mid_0166_m_BGM_DraBuru_Turn_NEXT_1:
	.incbin "midi/0166_m_BGM_DraBuru_Turn_NEXT_1.mid"
	.balign 4, 0
	.global mid_0167_m_BGM_DraBuru_Turn_NEXT_2
mid_0167_m_BGM_DraBuru_Turn_NEXT_2:
	.incbin "midi/0167_m_BGM_DraBuru_Turn_NEXT_2.mid"
	.balign 4, 0
	.global mid_0168_m_BGM_DraBuru_Boss_START_1
mid_0168_m_BGM_DraBuru_Boss_START_1:
	.incbin "midi/0168_m_BGM_DraBuru_Boss_START_1.mid"
	.balign 4, 0
	.global mid_0169_m_BGM_DraBuru_Boss_START_FF
mid_0169_m_BGM_DraBuru_Boss_START_FF:
	.incbin "midi/0169_m_BGM_DraBuru_Boss_START_FF.mid"
	.balign 4, 0
	.global mid_0170_m_BGM_DraBuru_Boss_01
mid_0170_m_BGM_DraBuru_Boss_01:
	.incbin "midi/0170_m_BGM_DraBuru_Boss_01.mid"
	.balign 4, 0
	.global mid_0171_m_BGM_DraBuru_BOSS_BOSS
mid_0171_m_BGM_DraBuru_BOSS_BOSS:
	.incbin "midi/0171_m_BGM_DraBuru_BOSS_BOSS.mid"
	.balign 4, 0
	.global mid_0172_m_BGM_DraBuru_BOSS_NG
mid_0172_m_BGM_DraBuru_BOSS_NG:
	.incbin "midi/0172_m_BGM_DraBuru_BOSS_NG.mid"
	.balign 4, 0
	.global mid_0173_m_BGM_DraBuru_BOSS_Clear
mid_0173_m_BGM_DraBuru_BOSS_Clear:
	.incbin "midi/0173_m_BGM_DraBuru_BOSS_Clear.mid"
	.balign 4, 0
	.global mid_0174_m_BGM_DraBuru_REST_LvUp
mid_0174_m_BGM_DraBuru_REST_LvUp:
	.incbin "midi/0174_m_BGM_DraBuru_REST_LvUp.mid"
	.balign 4, 0
	.global mid_0175_m_BGM_DraBuru_EP_1
mid_0175_m_BGM_DraBuru_EP_1:
	.incbin "midi/0175_m_BGM_DraBuru_EP_1.mid"
	.balign 4, 0
	.global mid_0176_m_BGM_Monna_INTRO_0_City
mid_0176_m_BGM_Monna_INTRO_0_City:
	.incbin "midi/0176_m_BGM_Monna_INTRO_0_City.mid"
	.balign 4, 0
	.global mid_0177_m_BGM_Monna_INTRO_0_Shop
mid_0177_m_BGM_Monna_INTRO_0_Shop:
	.incbin "midi/0177_m_BGM_Monna_INTRO_0_Shop.mid"
	.balign 4, 0
	.global mid_0178_m_BGM_Monna_INTRO_1
mid_0178_m_BGM_Monna_INTRO_1:
	.incbin "midi/0178_m_BGM_Monna_INTRO_1.mid"
	.balign 4, 0
	.global mid_0179_m_BGM_Monna_INTRO_2
mid_0179_m_BGM_Monna_INTRO_2:
	.incbin "midi/0179_m_BGM_Monna_INTRO_2.mid"
	.balign 4, 0
	.global mid_0180_m_BGM_Monna_01
mid_0180_m_BGM_Monna_01:
	.incbin "midi/0180_m_BGM_Monna_01.mid"
	.balign 4, 0
	.global mid_0181_m_BGM_Monna_02
mid_0181_m_BGM_Monna_02:
	.incbin "midi/0181_m_BGM_Monna_02.mid"
	.balign 4, 0
	.global mid_0182_m_BGM_Monna_03
mid_0182_m_BGM_Monna_03:
	.incbin "midi/0182_m_BGM_Monna_03.mid"
	.balign 4, 0
	.global mid_0183_m_BGM_Monna_04
mid_0183_m_BGM_Monna_04:
	.incbin "midi/0183_m_BGM_Monna_04.mid"
	.balign 4, 0
	.global mid_0184_m_BGM_Monna_05
mid_0184_m_BGM_Monna_05:
	.incbin "midi/0184_m_BGM_Monna_05.mid"
	.balign 4, 0
	.global mid_0185_m_BGM_Monna_06
mid_0185_m_BGM_Monna_06:
	.incbin "midi/0185_m_BGM_Monna_06.mid"
	.balign 4, 0
	.global mid_0186_m_BGM_Monna_07
mid_0186_m_BGM_Monna_07:
	.incbin "midi/0186_m_BGM_Monna_07.mid"
	.balign 4, 0
	.global mid_0187_m_BGM_Monna_08
mid_0187_m_BGM_Monna_08:
	.incbin "midi/0187_m_BGM_Monna_08.mid"
	.balign 4, 0
	.global mid_0188_m_BGM_Monna_09
mid_0188_m_BGM_Monna_09:
	.incbin "midi/0188_m_BGM_Monna_09.mid"
	.balign 4, 0
	.global mid_0189_m_BGM_Monna_10
mid_0189_m_BGM_Monna_10:
	.incbin "midi/0189_m_BGM_Monna_10.mid"
	.balign 4, 0
	.global mid_0190_m_BGM_Monna_END
mid_0190_m_BGM_Monna_END:
	.incbin "midi/0190_m_BGM_Monna_END.mid"
	.balign 4, 0
	.global mid_0191_m_BGM_Monna_Loop
mid_0191_m_BGM_Monna_Loop:
	.incbin "midi/0191_m_BGM_Monna_Loop.mid"
	.balign 4, 0
	.global mid_0192_m_BGM_Monna_Result_OK_10
mid_0192_m_BGM_Monna_Result_OK_10:
	.incbin "midi/0192_m_BGM_Monna_Result_OK_10.mid"
	.balign 4, 0
	.global mid_0193_m_BGM_Monna_Result_OK_11
mid_0193_m_BGM_Monna_Result_OK_11:
	.incbin "midi/0193_m_BGM_Monna_Result_OK_11.mid"
	.balign 4, 0
	.global mid_0194_m_BGM_Monna_Result_NG_10
mid_0194_m_BGM_Monna_Result_NG_10:
	.incbin "midi/0194_m_BGM_Monna_Result_NG_10.mid"
	.balign 4, 0
	.global mid_0195_m_BGM_Monna_Result_NG_11
mid_0195_m_BGM_Monna_Result_NG_11:
	.incbin "midi/0195_m_BGM_Monna_Result_NG_11.mid"
	.balign 4, 0
	.global mid_0196_m_BGM_Monna_NEXT_10
mid_0196_m_BGM_Monna_NEXT_10:
	.incbin "midi/0196_m_BGM_Monna_NEXT_10.mid"
	.balign 4, 0
	.global mid_0197_m_BGM_Monna_NEXT_11
mid_0197_m_BGM_Monna_NEXT_11:
	.incbin "midi/0197_m_BGM_Monna_NEXT_11.mid"
	.balign 4, 0
	.global mid_0198_m_BGM_Monna_BOSS_10
mid_0198_m_BGM_Monna_BOSS_10:
	.incbin "midi/0198_m_BGM_Monna_BOSS_10.mid"
	.balign 4, 0
	.global mid_0199_m_BGM_Monna_EP_1
mid_0199_m_BGM_Monna_EP_1:
	.incbin "midi/0199_m_BGM_Monna_EP_1.mid"
	.balign 4, 0
	.global mid_0200_m_BGM_Monna_EP_Shop
mid_0200_m_BGM_Monna_EP_Shop:
	.incbin "midi/0200_m_BGM_Monna_EP_Shop.mid"
	.balign 4, 0
	.global mid_0201_m_BGM_Monna_FF_Safe_01
mid_0201_m_BGM_Monna_FF_Safe_01:
	.incbin "midi/0201_m_BGM_Monna_FF_Safe_01.mid"
	.balign 4, 0
	.global mid_0202_m_BGM_Voya_Demo_IN_05
mid_0202_m_BGM_Voya_Demo_IN_05:
	.incbin "midi/0202_m_BGM_Voya_Demo_IN_05.mid"
	.balign 4, 0
	.global mid_0203_m_BGM_Voya_Demo_IN_10
mid_0203_m_BGM_Voya_Demo_IN_10:
	.incbin "midi/0203_m_BGM_Voya_Demo_IN_10.mid"
	.balign 4, 0
	.global mid_0204_m_BGM_Voya_Demo_IN_50
mid_0204_m_BGM_Voya_Demo_IN_50:
	.incbin "midi/0204_m_BGM_Voya_Demo_IN_50.mid"
	.balign 4, 0
	.global mid_0205_m_BGM_Voya_Demo_IN_51
mid_0205_m_BGM_Voya_Demo_IN_51:
	.incbin "midi/0205_m_BGM_Voya_Demo_IN_51.mid"
	.balign 4, 0
	.global mid_0206_m_BGM_Voya_Turn_OK_1
mid_0206_m_BGM_Voya_Turn_OK_1:
	.incbin "midi/0206_m_BGM_Voya_Turn_OK_1.mid"
	.balign 4, 0
	.global mid_0207_m_BGM_Voya_Turn_OK_2
mid_0207_m_BGM_Voya_Turn_OK_2:
	.incbin "midi/0207_m_BGM_Voya_Turn_OK_2.mid"
	.balign 4, 0
	.global mid_0208_m_BGM_Voya_Turn_NG_1
mid_0208_m_BGM_Voya_Turn_NG_1:
	.incbin "midi/0208_m_BGM_Voya_Turn_NG_1.mid"
	.balign 4, 0
	.global mid_0209_m_BGM_Voya_Turn_NG_2
mid_0209_m_BGM_Voya_Turn_NG_2:
	.incbin "midi/0209_m_BGM_Voya_Turn_NG_2.mid"
	.balign 4, 0
	.global mid_0210_m_BGM_Voya_Turn_NEXT_1
mid_0210_m_BGM_Voya_Turn_NEXT_1:
	.incbin "midi/0210_m_BGM_Voya_Turn_NEXT_1.mid"
	.balign 4, 0
	.global mid_0211_m_BGM_Voya_Turn_NEXT_2
mid_0211_m_BGM_Voya_Turn_NEXT_2:
	.incbin "midi/0211_m_BGM_Voya_Turn_NEXT_2.mid"
	.balign 4, 0
	.global mid_0212_m_BGM_Voya_Game_END_1
mid_0212_m_BGM_Voya_Game_END_1:
	.incbin "midi/0212_m_BGM_Voya_Game_END_1.mid"
	.balign 4, 0
	.global mid_0213_m_BGM_Voya_BOSS_Fanfare_1
mid_0213_m_BGM_Voya_BOSS_Fanfare_1:
	.incbin "midi/0213_m_BGM_Voya_BOSS_Fanfare_1.mid"
	.balign 4, 0
	.global mid_0214_m_BGM_Voya_BOSS_10
mid_0214_m_BGM_Voya_BOSS_10:
	.incbin "midi/0214_m_BGM_Voya_BOSS_10.mid"
	.balign 4, 0
	.global mid_0215_m_BGM_KAEDE_Demo_01
mid_0215_m_BGM_KAEDE_Demo_01:
	.incbin "midi/0215_m_BGM_KAEDE_Demo_01.mid"
	.balign 4, 0
	.global mid_0216_m_BGM_KAEDE_Demo_02
mid_0216_m_BGM_KAEDE_Demo_02:
	.incbin "midi/0216_m_BGM_KAEDE_Demo_02.mid"
	.balign 4, 0
	.global mid_0217_m_BGM_KAEDE_Demo_03
mid_0217_m_BGM_KAEDE_Demo_03:
	.incbin "midi/0217_m_BGM_KAEDE_Demo_03.mid"
	.balign 4, 0
	.global mid_0218_m_BGM_KAEDE_Demo_04
mid_0218_m_BGM_KAEDE_Demo_04:
	.incbin "midi/0218_m_BGM_KAEDE_Demo_04.mid"
	.balign 4, 0
	.global mid_0219_m_BGM_KAEDE_Demo_05
mid_0219_m_BGM_KAEDE_Demo_05:
	.incbin "midi/0219_m_BGM_KAEDE_Demo_05.mid"
	.balign 4, 0
	.global mid_0220_m_BGM_KAEDE_Demo_06
mid_0220_m_BGM_KAEDE_Demo_06:
	.incbin "midi/0220_m_BGM_KAEDE_Demo_06.mid"
	.balign 4, 0
	.global mid_0221_m_BGM_KAEDE_Demo_10
mid_0221_m_BGM_KAEDE_Demo_10:
	.incbin "midi/0221_m_BGM_KAEDE_Demo_10.mid"
	.balign 4, 0
	.global mid_0222_m_BGM_KAEDE_Demo_11
mid_0222_m_BGM_KAEDE_Demo_11:
	.incbin "midi/0222_m_BGM_KAEDE_Demo_11.mid"
	.balign 4, 0
	.global mid_0223_m_BGM_KAEDE_Game_Intro
mid_0223_m_BGM_KAEDE_Game_Intro:
	.incbin "midi/0223_m_BGM_KAEDE_Game_Intro.mid"
	.balign 4, 0
	.global mid_0224_m_BGM_KAEDE_Game_1_1
mid_0224_m_BGM_KAEDE_Game_1_1:
	.incbin "midi/0224_m_BGM_KAEDE_Game_1_1.mid"
	.balign 4, 0
	.global mid_0225_m_BGM_KAEDE_Game_1_2
mid_0225_m_BGM_KAEDE_Game_1_2:
	.incbin "midi/0225_m_BGM_KAEDE_Game_1_2.mid"
	.balign 4, 0
	.global mid_0226_m_BGM_KAEDE_Game_1_3
mid_0226_m_BGM_KAEDE_Game_1_3:
	.incbin "midi/0226_m_BGM_KAEDE_Game_1_3.mid"
	.balign 4, 0
	.global mid_0227_m_BGM_KAEDE_Game_1_4
mid_0227_m_BGM_KAEDE_Game_1_4:
	.incbin "midi/0227_m_BGM_KAEDE_Game_1_4.mid"
	.balign 4, 0
	.global mid_0228_m_BGM_KAEDE_Game_1_5
mid_0228_m_BGM_KAEDE_Game_1_5:
	.incbin "midi/0228_m_BGM_KAEDE_Game_1_5.mid"
	.balign 4, 0
	.global mid_0229_m_BGM_KAEDE_Game_1_6
mid_0229_m_BGM_KAEDE_Game_1_6:
	.incbin "midi/0229_m_BGM_KAEDE_Game_1_6.mid"
	.balign 4, 0
	.global mid_0230_m_BGM_KAEDE_Game_1_7
mid_0230_m_BGM_KAEDE_Game_1_7:
	.incbin "midi/0230_m_BGM_KAEDE_Game_1_7.mid"
	.balign 4, 0
	.global mid_0231_m_BGM_KAEDE_Game_1_8
mid_0231_m_BGM_KAEDE_Game_1_8:
	.incbin "midi/0231_m_BGM_KAEDE_Game_1_8.mid"
	.balign 4, 0
	.global mid_0232_m_BGM_KAEDE_Game_1_NEXT
mid_0232_m_BGM_KAEDE_Game_1_NEXT:
	.incbin "midi/0232_m_BGM_KAEDE_Game_1_NEXT.mid"
	.balign 4, 0
	.global mid_0233_m_BGM_KAEDE_Game_1_END
mid_0233_m_BGM_KAEDE_Game_1_END:
	.incbin "midi/0233_m_BGM_KAEDE_Game_1_END.mid"
	.balign 4, 0
	.global mid_0234_m_BGM_KAEDE_Game_2_1
mid_0234_m_BGM_KAEDE_Game_2_1:
	.incbin "midi/0234_m_BGM_KAEDE_Game_2_1.mid"
	.balign 4, 0
	.global mid_0235_m_BGM_KAEDE_Game_2_2
mid_0235_m_BGM_KAEDE_Game_2_2:
	.incbin "midi/0235_m_BGM_KAEDE_Game_2_2.mid"
	.balign 4, 0
	.global mid_0236_m_BGM_KAEDE_Game_2_3
mid_0236_m_BGM_KAEDE_Game_2_3:
	.incbin "midi/0236_m_BGM_KAEDE_Game_2_3.mid"
	.balign 4, 0
	.global mid_0237_m_BGM_KAEDE_Game_2_4
mid_0237_m_BGM_KAEDE_Game_2_4:
	.incbin "midi/0237_m_BGM_KAEDE_Game_2_4.mid"
	.balign 4, 0
	.global mid_0238_m_BGM_KAEDE_Game_2_5
mid_0238_m_BGM_KAEDE_Game_2_5:
	.incbin "midi/0238_m_BGM_KAEDE_Game_2_5.mid"
	.balign 4, 0
	.global mid_0239_m_BGM_KAEDE_Game_2_6
mid_0239_m_BGM_KAEDE_Game_2_6:
	.incbin "midi/0239_m_BGM_KAEDE_Game_2_6.mid"
	.balign 4, 0
	.global mid_0240_m_BGM_KAEDE_Game_2_7
mid_0240_m_BGM_KAEDE_Game_2_7:
	.incbin "midi/0240_m_BGM_KAEDE_Game_2_7.mid"
	.balign 4, 0
	.global mid_0241_m_BGM_KAEDE_Game_2_8
mid_0241_m_BGM_KAEDE_Game_2_8:
	.incbin "midi/0241_m_BGM_KAEDE_Game_2_8.mid"
	.balign 4, 0
	.global mid_0242_m_BGM_KAEDE_Game_2_NEXT
mid_0242_m_BGM_KAEDE_Game_2_NEXT:
	.incbin "midi/0242_m_BGM_KAEDE_Game_2_NEXT.mid"
	.balign 4, 0
	.global mid_0243_m_BGM_KAEDE_Game_2_END
mid_0243_m_BGM_KAEDE_Game_2_END:
	.incbin "midi/0243_m_BGM_KAEDE_Game_2_END.mid"
	.balign 4, 0
	.global mid_0244_m_BGM_KAEDE_Game_3_1
mid_0244_m_BGM_KAEDE_Game_3_1:
	.incbin "midi/0244_m_BGM_KAEDE_Game_3_1.mid"
	.balign 4, 0
	.global mid_0245_m_BGM_KAEDE_Game_3_2
mid_0245_m_BGM_KAEDE_Game_3_2:
	.incbin "midi/0245_m_BGM_KAEDE_Game_3_2.mid"
	.balign 4, 0
	.global mid_0246_m_BGM_KAEDE_Game_3_3
mid_0246_m_BGM_KAEDE_Game_3_3:
	.incbin "midi/0246_m_BGM_KAEDE_Game_3_3.mid"
	.balign 4, 0
	.global mid_0247_m_BGM_KAEDE_Game_3_4
mid_0247_m_BGM_KAEDE_Game_3_4:
	.incbin "midi/0247_m_BGM_KAEDE_Game_3_4.mid"
	.balign 4, 0
	.global mid_0248_m_BGM_KAEDE_Game_3_5
mid_0248_m_BGM_KAEDE_Game_3_5:
	.incbin "midi/0248_m_BGM_KAEDE_Game_3_5.mid"
	.balign 4, 0
	.global mid_0249_m_BGM_KAEDE_Game_3_6
mid_0249_m_BGM_KAEDE_Game_3_6:
	.incbin "midi/0249_m_BGM_KAEDE_Game_3_6.mid"
	.balign 4, 0
	.global mid_0250_m_BGM_KAEDE_Game_3_7
mid_0250_m_BGM_KAEDE_Game_3_7:
	.incbin "midi/0250_m_BGM_KAEDE_Game_3_7.mid"
	.balign 4, 0
	.global mid_0251_m_BGM_KAEDE_Game_3_8
mid_0251_m_BGM_KAEDE_Game_3_8:
	.incbin "midi/0251_m_BGM_KAEDE_Game_3_8.mid"
	.balign 4, 0
	.global mid_0252_m_BGM_KAEDE_Game_3_NEXT
mid_0252_m_BGM_KAEDE_Game_3_NEXT:
	.incbin "midi/0252_m_BGM_KAEDE_Game_3_NEXT.mid"
	.balign 4, 0
	.global mid_0253_m_BGM_KAEDE_Game_3_END
mid_0253_m_BGM_KAEDE_Game_3_END:
	.incbin "midi/0253_m_BGM_KAEDE_Game_3_END.mid"
	.balign 4, 0
	.global mid_0254_m_BGM_KAEDE_Game_BOSS_Next
mid_0254_m_BGM_KAEDE_Game_BOSS_Next:
	.incbin "midi/0254_m_BGM_KAEDE_Game_BOSS_Next.mid"
	.balign 4, 0
	.global mid_0255_m_BGM_KAEDE_BOSS_10
mid_0255_m_BGM_KAEDE_BOSS_10:
	.incbin "midi/0255_m_BGM_KAEDE_BOSS_10.mid"
	.balign 4, 0
	.global mid_0256_m_BGM_KAEDE_Demo_EP_10
mid_0256_m_BGM_KAEDE_Demo_EP_10:
	.incbin "midi/0256_m_BGM_KAEDE_Demo_EP_10.mid"
	.balign 4, 0
	.global mid_0257_m_BGM_KAEDE_Demo_EP_11
mid_0257_m_BGM_KAEDE_Demo_EP_11:
	.incbin "midi/0257_m_BGM_KAEDE_Demo_EP_11.mid"
	.balign 4, 0
	.global mid_0258_m_BGM_KAEDE_Demo_EP_12
mid_0258_m_BGM_KAEDE_Demo_EP_12:
	.incbin "midi/0258_m_BGM_KAEDE_Demo_EP_12.mid"
	.balign 4, 0
	.global mid_0259_m_BGM_Loo_Demo_MAP_1
mid_0259_m_BGM_Loo_Demo_MAP_1:
	.incbin "midi/0259_m_BGM_Loo_Demo_MAP_1.mid"
	.balign 4, 0
	.global mid_0260_m_BGM_Loo_Demo_10
mid_0260_m_BGM_Loo_Demo_10:
	.incbin "midi/0260_m_BGM_Loo_Demo_10.mid"
	.balign 4, 0
	.global mid_0261_m_BGM_Loo_Demo_11
mid_0261_m_BGM_Loo_Demo_11:
	.incbin "midi/0261_m_BGM_Loo_Demo_11.mid"
	.balign 4, 0
	.global mid_0262_m_BGM_Loo_Demo_112
mid_0262_m_BGM_Loo_Demo_112:
	.incbin "midi/0262_m_BGM_Loo_Demo_112.mid"
	.balign 4, 0
	.global mid_0263_m_BGM_Loo_Demo_12
mid_0263_m_BGM_Loo_Demo_12:
	.incbin "midi/0263_m_BGM_Loo_Demo_12.mid"
	.balign 4, 0
	.global mid_0264_m_BGM_Loo_Demo_13
mid_0264_m_BGM_Loo_Demo_13:
	.incbin "midi/0264_m_BGM_Loo_Demo_13.mid"
	.balign 4, 0
	.global mid_0265_m_BGM_Loo_Game_1_Intro
mid_0265_m_BGM_Loo_Game_1_Intro:
	.incbin "midi/0265_m_BGM_Loo_Game_1_Intro.mid"
	.balign 4, 0
	.global mid_0266_m_BGM_Loo_Game_1_1
mid_0266_m_BGM_Loo_Game_1_1:
	.incbin "midi/0266_m_BGM_Loo_Game_1_1.mid"
	.balign 4, 0
	.global mid_0267_m_BGM_Loo_Game_1_2
mid_0267_m_BGM_Loo_Game_1_2:
	.incbin "midi/0267_m_BGM_Loo_Game_1_2.mid"
	.balign 4, 0
	.global mid_0268_m_BGM_Loo_Game_1_3
mid_0268_m_BGM_Loo_Game_1_3:
	.incbin "midi/0268_m_BGM_Loo_Game_1_3.mid"
	.balign 4, 0
	.global mid_0269_m_BGM_Loo_Game_1_4
mid_0269_m_BGM_Loo_Game_1_4:
	.incbin "midi/0269_m_BGM_Loo_Game_1_4.mid"
	.balign 4, 0
	.global mid_0270_m_BGM_Loo_Game_1_5
mid_0270_m_BGM_Loo_Game_1_5:
	.incbin "midi/0270_m_BGM_Loo_Game_1_5.mid"
	.balign 4, 0
	.global mid_0271_m_BGM_Loo_Game_1_6
mid_0271_m_BGM_Loo_Game_1_6:
	.incbin "midi/0271_m_BGM_Loo_Game_1_6.mid"
	.balign 4, 0
	.global mid_0272_m_BGM_Loo_Game_1_7
mid_0272_m_BGM_Loo_Game_1_7:
	.incbin "midi/0272_m_BGM_Loo_Game_1_7.mid"
	.balign 4, 0
	.global mid_0273_m_BGM_Loo_Game_1_8
mid_0273_m_BGM_Loo_Game_1_8:
	.incbin "midi/0273_m_BGM_Loo_Game_1_8.mid"
	.balign 4, 0
	.global mid_0274_m_BGM_Loo_Game_1_NEXT
mid_0274_m_BGM_Loo_Game_1_NEXT:
	.incbin "midi/0274_m_BGM_Loo_Game_1_NEXT.mid"
	.balign 4, 0
	.global mid_0275_m_BGM_Loo_Game_1_END
mid_0275_m_BGM_Loo_Game_1_END:
	.incbin "midi/0275_m_BGM_Loo_Game_1_END.mid"
	.balign 4, 0
	.global mid_0276_m_BGM_Loo_BOSS_FF_Start
mid_0276_m_BGM_Loo_BOSS_FF_Start:
	.incbin "midi/0276_m_BGM_Loo_BOSS_FF_Start.mid"
	.balign 4, 0
	.global mid_0277_m_BGM_Loo_BOSS_10
mid_0277_m_BGM_Loo_BOSS_10:
	.incbin "midi/0277_m_BGM_Loo_BOSS_10.mid"
	.balign 4, 0
	.global mid_0278_m_BGM_Loo_EP_05
mid_0278_m_BGM_Loo_EP_05:
	.incbin "midi/0278_m_BGM_Loo_EP_05.mid"
	.balign 4, 0
	.global mid_0279_m_BGM_Loo_EP_10
mid_0279_m_BGM_Loo_EP_10:
	.incbin "midi/0279_m_BGM_Loo_EP_10.mid"
	.balign 4, 0
	.global mid_0280_m_BGM_Loo_EP_11
mid_0280_m_BGM_Loo_EP_11:
	.incbin "midi/0280_m_BGM_Loo_EP_11.mid"
	.balign 4, 0
	.global mid_0281_m_BGM_Bio_Demo_0
mid_0281_m_BGM_Bio_Demo_0:
	.incbin "midi/0281_m_BGM_Bio_Demo_0.mid"
	.balign 4, 0
	.global mid_0282_m_BGM_Bio_Turn_OK_1
mid_0282_m_BGM_Bio_Turn_OK_1:
	.incbin "midi/0282_m_BGM_Bio_Turn_OK_1.mid"
	.balign 4, 0
	.global mid_0283_m_BGM_Bio_Turn_OK_2
mid_0283_m_BGM_Bio_Turn_OK_2:
	.incbin "midi/0283_m_BGM_Bio_Turn_OK_2.mid"
	.balign 4, 0
	.global mid_0284_m_BGM_Bio_Turn_OK_3
mid_0284_m_BGM_Bio_Turn_OK_3:
	.incbin "midi/0284_m_BGM_Bio_Turn_OK_3.mid"
	.balign 4, 0
	.global mid_0285_m_BGM_Bio_Turn_NG_1
mid_0285_m_BGM_Bio_Turn_NG_1:
	.incbin "midi/0285_m_BGM_Bio_Turn_NG_1.mid"
	.balign 4, 0
	.global mid_0286_m_BGM_Bio_Turn_NG_2
mid_0286_m_BGM_Bio_Turn_NG_2:
	.incbin "midi/0286_m_BGM_Bio_Turn_NG_2.mid"
	.balign 4, 0
	.global mid_0287_m_BGM_Bio_Turn_NG_3
mid_0287_m_BGM_Bio_Turn_NG_3:
	.incbin "midi/0287_m_BGM_Bio_Turn_NG_3.mid"
	.balign 4, 0
	.global mid_0288_m_BGM_Bio_Turn_NEXT_1
mid_0288_m_BGM_Bio_Turn_NEXT_1:
	.incbin "midi/0288_m_BGM_Bio_Turn_NEXT_1.mid"
	.balign 4, 0
	.global mid_0289_m_BGM_Bio_Turn_NEXT_2
mid_0289_m_BGM_Bio_Turn_NEXT_2:
	.incbin "midi/0289_m_BGM_Bio_Turn_NEXT_2.mid"
	.balign 4, 0
	.global mid_0290_m_BGM_Bio_Turn_NEXT_3
mid_0290_m_BGM_Bio_Turn_NEXT_3:
	.incbin "midi/0290_m_BGM_Bio_Turn_NEXT_3.mid"
	.balign 4, 0
	.global mid_0291_m_BGM_Bio_BOSS_FF_Start
mid_0291_m_BGM_Bio_BOSS_FF_Start:
	.incbin "midi/0291_m_BGM_Bio_BOSS_FF_Start.mid"
	.balign 4, 0
	.global mid_0292_m_BGM_Bio_BOSS_10
mid_0292_m_BGM_Bio_BOSS_10:
	.incbin "midi/0292_m_BGM_Bio_BOSS_10.mid"
	.balign 4, 0
	.global mid_0293_m_BGM_Bio_END
mid_0293_m_BGM_Bio_END:
	.incbin "midi/0293_m_BGM_Bio_END.mid"
	.balign 4, 0
	.global mid_0294_m_BGM_Bio_END_01
mid_0294_m_BGM_Bio_END_01:
	.incbin "midi/0294_m_BGM_Bio_END_01.mid"
	.balign 4, 0
	.global mid_0295_m_BGM_Bio_Demo_EP_1
mid_0295_m_BGM_Bio_Demo_EP_1:
	.incbin "midi/0295_m_BGM_Bio_Demo_EP_1.mid"
	.balign 4, 0
	.global mid_0296_s_BASIC_PAUSE_ON
mid_0296_s_BASIC_PAUSE_ON:
	.incbin "midi/0296_s_BASIC_PAUSE_ON.mid"
	.balign 4, 0
	.global mid_0297_s_BASIC_PAUSE_OFF
mid_0297_s_BASIC_PAUSE_OFF:
	.incbin "midi/0297_s_BASIC_PAUSE_OFF.mid"
	.balign 4, 0
	.global mid_0298_s_BASIC_CURSOR_01
mid_0298_s_BASIC_CURSOR_01:
	.incbin "midi/0298_s_BASIC_CURSOR_01.mid"
	.balign 4, 0
	.global mid_0299_s_BASIC_CURSOR_02
mid_0299_s_BASIC_CURSOR_02:
	.incbin "midi/0299_s_BASIC_CURSOR_02.mid"
	.balign 4, 0
	.global mid_0300_s_BASIC_BUTTON_A
mid_0300_s_BASIC_BUTTON_A:
	.incbin "midi/0300_s_BASIC_BUTTON_A.mid"
	.balign 4, 0
	.global mid_0301_s_BASIC_BUTTON_A1
mid_0301_s_BASIC_BUTTON_A1:
	.incbin "midi/0301_s_BASIC_BUTTON_A1.mid"
	.balign 4, 0
	.global mid_0302_s_BASIC_BUTTON_A2
mid_0302_s_BASIC_BUTTON_A2:
	.incbin "midi/0302_s_BASIC_BUTTON_A2.mid"
	.balign 4, 0
	.global mid_0303_s_BASIC_BUTTON_As1
mid_0303_s_BASIC_BUTTON_As1:
	.incbin "midi/0303_s_BASIC_BUTTON_As1.mid"
	.balign 4, 0
	.global mid_0304_s_BASIC_BUTTON_As2
mid_0304_s_BASIC_BUTTON_As2:
	.incbin "midi/0304_s_BASIC_BUTTON_As2.mid"
	.balign 4, 0
	.global mid_0305_s_BASIC_BUTTON_A_Delete
mid_0305_s_BASIC_BUTTON_A_Delete:
	.incbin "midi/0305_s_BASIC_BUTTON_A_Delete.mid"
	.balign 4, 0
	.global mid_0306_s_BASIC_BUTTON_B
mid_0306_s_BASIC_BUTTON_B:
	.incbin "midi/0306_s_BASIC_BUTTON_B.mid"
	.balign 4, 0
	.global mid_0307_s_BASIC_BUTTON_Bs
mid_0307_s_BASIC_BUTTON_Bs:
	.incbin "midi/0307_s_BASIC_BUTTON_Bs.mid"
	.balign 4, 0
	.global mid_0308_s_BASIC_DAME_1
mid_0308_s_BASIC_DAME_1:
	.incbin "midi/0308_s_BASIC_DAME_1.mid"
	.balign 4, 0
	.global mid_0309_s_BOMB_Window_Change
mid_0309_s_BOMB_Window_Change:
	.incbin "midi/0309_s_BOMB_Window_Change.mid"
	.balign 4, 0
	.global mid_0310_s_BOMB_Window_Change_2
mid_0310_s_BOMB_Window_Change_2:
	.incbin "midi/0310_s_BOMB_Window_Change_2.mid"
	.balign 4, 0
	.global mid_0311_s_Demo_Title_BUMP
mid_0311_s_Demo_Title_BUMP:
	.incbin "midi/0311_s_Demo_Title_BUMP.mid"
	.balign 4, 0
	.global mid_0312_s_BOMB_Door_Open
mid_0312_s_BOMB_Door_Open:
	.incbin "midi/0312_s_BOMB_Door_Open.mid"
	.balign 4, 0
	.global mid_0313_s_BOMB_Door_Close
mid_0313_s_BOMB_Door_Close:
	.incbin "midi/0313_s_BOMB_Door_Close.mid"
	.balign 4, 0
	.global mid_0314_s_BOMB_END_OFF_1
mid_0314_s_BOMB_END_OFF_1:
	.incbin "midi/0314_s_BOMB_END_OFF_1.mid"
	.balign 4, 0
	.global mid_0315_s_Demo_1UP_01
mid_0315_s_Demo_1UP_01:
	.incbin "midi/0315_s_Demo_1UP_01.mid"
	.balign 4, 0
	.global mid_0316_s_BOMB_BOSS_BOXING_Wind_1
mid_0316_s_BOMB_BOSS_BOXING_Wind_1:
	.incbin "midi/0316_s_BOMB_BOSS_BOXING_Wind_1.mid"
	.balign 4, 0
	.global mid_0317_s_BOMB_BOSS_BOXING_Wind_2
mid_0317_s_BOMB_BOSS_BOXING_Wind_2:
	.incbin "midi/0317_s_BOMB_BOSS_BOXING_Wind_2.mid"
	.balign 4, 0
	.global mid_0318_s_BOMB_BOSS_BOXING_Wind_3
mid_0318_s_BOMB_BOSS_BOXING_Wind_3:
	.incbin "midi/0318_s_BOMB_BOSS_BOXING_Wind_3.mid"
	.balign 4, 0
	.global mid_0319_s_BOMB_BOSS_BOXING_Punch_1
mid_0319_s_BOMB_BOSS_BOXING_Punch_1:
	.incbin "midi/0319_s_BOMB_BOSS_BOXING_Punch_1.mid"
	.balign 4, 0
	.global mid_0320_s_BOMB_BOSS_BOXING_Punch_2
mid_0320_s_BOMB_BOSS_BOXING_Punch_2:
	.incbin "midi/0320_s_BOMB_BOSS_BOXING_Punch_2.mid"
	.balign 4, 0
	.global mid_0321_s_BOMB_BOSS_BOXING_Punch_3
mid_0321_s_BOMB_BOSS_BOXING_Punch_3:
	.incbin "midi/0321_s_BOMB_BOSS_BOXING_Punch_3.mid"
	.balign 4, 0
	.global mid_0322_s_BOMB_BOSS_BOXING_OK_01
mid_0322_s_BOMB_BOSS_BOXING_OK_01:
	.incbin "midi/0322_s_BOMB_BOSS_BOXING_OK_01.mid"
	.balign 4, 0
	.global mid_0323_s_BOMB_BOSS_BOXING_OK_02
mid_0323_s_BOMB_BOSS_BOXING_OK_02:
	.incbin "midi/0323_s_BOMB_BOSS_BOXING_OK_02.mid"
	.balign 4, 0
	.global mid_0324_s_BOMB_BOSS_BOXING_OK_03
mid_0324_s_BOMB_BOSS_BOXING_OK_03:
	.incbin "midi/0324_s_BOMB_BOSS_BOXING_OK_03.mid"
	.balign 4, 0
	.global mid_0325_s_BOMB_BOSS_BOXING_NG_01
mid_0325_s_BOMB_BOSS_BOXING_NG_01:
	.incbin "midi/0325_s_BOMB_BOSS_BOXING_NG_01.mid"
	.balign 4, 0
	.global mid_0326_s_BOMB_BOSS_BOXING_NG_02
mid_0326_s_BOMB_BOSS_BOXING_NG_02:
	.incbin "midi/0326_s_BOMB_BOSS_BOXING_NG_02.mid"
	.balign 4, 0
	.global mid_0327_s_BOMB_BOSS_BOXING_NG_03
mid_0327_s_BOMB_BOSS_BOXING_NG_03:
	.incbin "midi/0327_s_BOMB_BOSS_BOXING_NG_03.mid"
	.balign 4, 0
	.global mid_0328_s_BOMB_BOSS_BOXING_Power_1
mid_0328_s_BOMB_BOSS_BOXING_Power_1:
	.incbin "midi/0328_s_BOMB_BOSS_BOXING_Power_1.mid"
	.balign 4, 0
	.global mid_0329_s_BOMB_BOSS_BOXING_Power_2
mid_0329_s_BOMB_BOSS_BOXING_Power_2:
	.incbin "midi/0329_s_BOMB_BOSS_BOXING_Power_2.mid"
	.balign 4, 0
	.global mid_0330_s_BOMB_BOSS_BOXING_WIN
mid_0330_s_BOMB_BOSS_BOXING_WIN:
	.incbin "midi/0330_s_BOMB_BOSS_BOXING_WIN.mid"
	.balign 4, 0
	.global mid_0331_s_BOMB_BOSS_BOXING_LOSE
mid_0331_s_BOMB_BOSS_BOXING_LOSE:
	.incbin "midi/0331_s_BOMB_BOSS_BOXING_LOSE.mid"
	.balign 4, 0
	.global mid_0332_s_BOMB_BOSS_BOXING_GONG
mid_0332_s_BOMB_BOSS_BOXING_GONG:
	.incbin "midi/0332_s_BOMB_BOSS_BOXING_GONG.mid"
	.balign 4, 0
	.global mid_0333_s_BOMB_BOSS_BOXING_Hit_01
mid_0333_s_BOMB_BOSS_BOXING_Hit_01:
	.incbin "midi/0333_s_BOMB_BOSS_BOXING_Hit_01.mid"
	.balign 4, 0
	.global mid_0334_s_BOMB_BOSS_BOXING_Hit_02
mid_0334_s_BOMB_BOSS_BOXING_Hit_02:
	.incbin "midi/0334_s_BOMB_BOSS_BOXING_Hit_02.mid"
	.balign 4, 0
	.global mid_0335_s_BOMB_BOSS_BOXING_Hit_03
mid_0335_s_BOMB_BOSS_BOXING_Hit_03:
	.incbin "midi/0335_s_BOMB_BOSS_BOXING_Hit_03.mid"
	.balign 4, 0
	.global mid_0336_s_BOMB_BOSS_BOXING_Hit_04
mid_0336_s_BOMB_BOSS_BOXING_Hit_04:
	.incbin "midi/0336_s_BOMB_BOSS_BOXING_Hit_04.mid"
	.balign 4, 0
	.global mid_0337_s_BOMB_BOSS_BOXING_Hit_05
mid_0337_s_BOMB_BOSS_BOXING_Hit_05:
	.incbin "midi/0337_s_BOMB_BOSS_BOXING_Hit_05.mid"
	.balign 4, 0
	.global mid_0338_s_BOMB_BOSS_BOXING_Hit_06
mid_0338_s_BOMB_BOSS_BOXING_Hit_06:
	.incbin "midi/0338_s_BOMB_BOSS_BOXING_Hit_06.mid"
	.balign 4, 0
	.global mid_0339_s_BOMB_BOSS_BOXING_Hit_07
mid_0339_s_BOMB_BOSS_BOXING_Hit_07:
	.incbin "midi/0339_s_BOMB_BOSS_BOXING_Hit_07.mid"
	.balign 4, 0
	.global mid_0340_s_BOMB_BOSS_BOXING_Hit_08
mid_0340_s_BOMB_BOSS_BOXING_Hit_08:
	.incbin "midi/0340_s_BOMB_BOSS_BOXING_Hit_08.mid"
	.balign 4, 0
	.global mid_0341_s_BOMB_BOSS_Nail_FALL_0
mid_0341_s_BOMB_BOSS_Nail_FALL_0:
	.incbin "midi/0341_s_BOMB_BOSS_Nail_FALL_0.mid"
	.balign 4, 0
	.global mid_0342_s_BOMB_BOSS_Nail_FALL_1
mid_0342_s_BOMB_BOSS_Nail_FALL_1:
	.incbin "midi/0342_s_BOMB_BOSS_Nail_FALL_1.mid"
	.balign 4, 0
	.global mid_0343_s_BOMB_BOSS_Nail_ON_1
mid_0343_s_BOMB_BOSS_Nail_ON_1:
	.incbin "midi/0343_s_BOMB_BOSS_Nail_ON_1.mid"
	.balign 4, 0
	.global mid_0344_s_BOMB_BOSS_Nail_Hit_OK_1
mid_0344_s_BOMB_BOSS_Nail_Hit_OK_1:
	.incbin "midi/0344_s_BOMB_BOSS_Nail_Hit_OK_1.mid"
	.balign 4, 0
	.global mid_0345_s_BOMB_BOSS_Nail_Hit_L_1
mid_0345_s_BOMB_BOSS_Nail_Hit_L_1:
	.incbin "midi/0345_s_BOMB_BOSS_Nail_Hit_L_1.mid"
	.balign 4, 0
	.global mid_0346_s_BOMB_BOSS_Nail_Hit_R_1
mid_0346_s_BOMB_BOSS_Nail_Hit_R_1:
	.incbin "midi/0346_s_BOMB_BOSS_Nail_Hit_R_1.mid"
	.balign 4, 0
	.global mid_0347_s_BOMB_BOSS_Nail_NG_1
mid_0347_s_BOMB_BOSS_Nail_NG_1:
	.incbin "midi/0347_s_BOMB_BOSS_Nail_NG_1.mid"
	.balign 4, 0
	.global mid_0348_s_BOMB_BOSS_Nail_Finish_1
mid_0348_s_BOMB_BOSS_Nail_Finish_1:
	.incbin "midi/0348_s_BOMB_BOSS_Nail_Finish_1.mid"
	.balign 4, 0
	.global mid_0349_s_BOMB_BOSS_BaseB_Cheer_1
mid_0349_s_BOMB_BOSS_BaseB_Cheer_1:
	.incbin "midi/0349_s_BOMB_BOSS_BaseB_Cheer_1.mid"
	.balign 4, 0
	.global mid_0350_s_BOMB_BOSS_BaseB_Cheer_2
mid_0350_s_BOMB_BOSS_BaseB_Cheer_2:
	.incbin "midi/0350_s_BOMB_BOSS_BaseB_Cheer_2.mid"
	.balign 4, 0
	.global mid_0351_s_BOMB_BOSS_BaseB_Boo_1
mid_0351_s_BOMB_BOSS_BaseB_Boo_1:
	.incbin "midi/0351_s_BOMB_BOSS_BaseB_Boo_1.mid"
	.balign 4, 0
	.global mid_0352_s_BOMB_BOSS_BaseB_Boo_2
mid_0352_s_BOMB_BOSS_BaseB_Boo_2:
	.incbin "midi/0352_s_BOMB_BOSS_BaseB_Boo_2.mid"
	.balign 4, 0
	.global mid_0353_s_BOMB_BOSS_BaseB_Miss_1
mid_0353_s_BOMB_BOSS_BaseB_Miss_1:
	.incbin "midi/0353_s_BOMB_BOSS_BaseB_Miss_1.mid"
	.balign 4, 0
	.global mid_0354_s_BOMB_BOSS_BaseB_Miss_2
mid_0354_s_BOMB_BOSS_BaseB_Miss_2:
	.incbin "midi/0354_s_BOMB_BOSS_BaseB_Miss_2.mid"
	.balign 4, 0
	.global mid_0355_s_BOMB_BOSS_BaseB_ReSet
mid_0355_s_BOMB_BOSS_BaseB_ReSet:
	.incbin "midi/0355_s_BOMB_BOSS_BaseB_ReSet.mid"
	.balign 4, 0
	.global mid_0356_s_BOMB_BOSS_Galala_Shot_01
mid_0356_s_BOMB_BOSS_Galala_Shot_01:
	.incbin "midi/0356_s_BOMB_BOSS_Galala_Shot_01.mid"
	.balign 4, 0
	.global mid_0357_s_BOMB_BOSS_Galala_Hit_01
mid_0357_s_BOMB_BOSS_Galala_Hit_01:
	.incbin "midi/0357_s_BOMB_BOSS_Galala_Hit_01.mid"
	.balign 4, 0
	.global mid_0358_s_BOMB_BOSS_Galala_Hit_02
mid_0358_s_BOMB_BOSS_Galala_Hit_02:
	.incbin "midi/0358_s_BOMB_BOSS_Galala_Hit_02.mid"
	.balign 4, 0
	.global mid_0359_s_BOMB_BOSS_Galala_Hit_03
mid_0359_s_BOMB_BOSS_Galala_Hit_03:
	.incbin "midi/0359_s_BOMB_BOSS_Galala_Hit_03.mid"
	.balign 4, 0
	.global mid_0360_s_BOMB_BOSS_Galala_Hit_04
mid_0360_s_BOMB_BOSS_Galala_Hit_04:
	.incbin "midi/0360_s_BOMB_BOSS_Galala_Hit_04.mid"
	.balign 4, 0
	.global mid_0361_s_BOMB_BOSS_Galala_CORE_02
mid_0361_s_BOMB_BOSS_Galala_CORE_02:
	.incbin "midi/0361_s_BOMB_BOSS_Galala_CORE_02.mid"
	.balign 4, 0
	.global mid_0362_s_BOMB_BOSS_Galala_CORE_03
mid_0362_s_BOMB_BOSS_Galala_CORE_03:
	.incbin "midi/0362_s_BOMB_BOSS_Galala_CORE_03.mid"
	.balign 4, 0
	.global mid_0363_s_BOMB_BOSS_Galala_Hole_01
mid_0363_s_BOMB_BOSS_Galala_Hole_01:
	.incbin "midi/0363_s_BOMB_BOSS_Galala_Hole_01.mid"
	.balign 4, 0
	.global mid_0364_s_BOMB_BOSS_Galala_Bonus
mid_0364_s_BOMB_BOSS_Galala_Bonus:
	.incbin "midi/0364_s_BOMB_BOSS_Galala_Bonus.mid"
	.balign 4, 0
	.global mid_0365_s_BOMB_BOSS_Galala_ITEM_01
mid_0365_s_BOMB_BOSS_Galala_ITEM_01:
	.incbin "midi/0365_s_BOMB_BOSS_Galala_ITEM_01.mid"
	.balign 4, 0
	.global mid_0366_s_BOMB_BOSS_Galala_OK_01
mid_0366_s_BOMB_BOSS_Galala_OK_01:
	.incbin "midi/0366_s_BOMB_BOSS_Galala_OK_01.mid"
	.balign 4, 0
	.global mid_0367_s_BOMB_BOSS_Galala_Fail_01
mid_0367_s_BOMB_BOSS_Galala_Fail_01:
	.incbin "midi/0367_s_BOMB_BOSS_Galala_Fail_01.mid"
	.balign 4, 0
	.global mid_0368_s_BOMB_BOSS_Galala_Barrier
mid_0368_s_BOMB_BOSS_Galala_Barrier:
	.incbin "midi/0368_s_BOMB_BOSS_Galala_Barrier.mid"
	.balign 4, 0
	.global mid_0369_s_BOMB_BOSS_Goma_FALL_0
mid_0369_s_BOMB_BOSS_Goma_FALL_0:
	.incbin "midi/0369_s_BOMB_BOSS_Goma_FALL_0.mid"
	.balign 4, 0
	.global mid_0370_s_BOMB_BOSS_Goma_FALL_9
mid_0370_s_BOMB_BOSS_Goma_FALL_9:
	.incbin "midi/0370_s_BOMB_BOSS_Goma_FALL_9.mid"
	.balign 4, 0
	.global mid_0371_s_BOMB_BOSS_Goma_JUMP_1
mid_0371_s_BOMB_BOSS_Goma_JUMP_1:
	.incbin "midi/0371_s_BOMB_BOSS_Goma_JUMP_1.mid"
	.balign 4, 0
	.global mid_0372_s_BOMB_BOSS_Goma_Walk_1
mid_0372_s_BOMB_BOSS_Goma_Walk_1:
	.incbin "midi/0372_s_BOMB_BOSS_Goma_Walk_1.mid"
	.balign 4, 0
	.global mid_0373_s_BOMB_BOSS_Goma_Walk_2
mid_0373_s_BOMB_BOSS_Goma_Walk_2:
	.incbin "midi/0373_s_BOMB_BOSS_Goma_Walk_2.mid"
	.balign 4, 0
	.global mid_0374_s_BOMB_BOSS_Goma_Walk_3
mid_0374_s_BOMB_BOSS_Goma_Walk_3:
	.incbin "midi/0374_s_BOMB_BOSS_Goma_Walk_3.mid"
	.balign 4, 0
	.global mid_0375_s_BOMB_BOSS_Goma_ITEM_1
mid_0375_s_BOMB_BOSS_Goma_ITEM_1:
	.incbin "midi/0375_s_BOMB_BOSS_Goma_ITEM_1.mid"
	.balign 4, 0
	.global mid_0376_s_BOMB_BOSS_Draran_Hit_1
mid_0376_s_BOMB_BOSS_Draran_Hit_1:
	.incbin "midi/0376_s_BOMB_BOSS_Draran_Hit_1.mid"
	.balign 4, 0
	.global mid_0377_s_BOMB_BOSS_Draran_Hit_2
mid_0377_s_BOMB_BOSS_Draran_Hit_2:
	.incbin "midi/0377_s_BOMB_BOSS_Draran_Hit_2.mid"
	.balign 4, 0
	.global mid_0378_s_BOMB_BOSS_Draran_Hit_3
mid_0378_s_BOMB_BOSS_Draran_Hit_3:
	.incbin "midi/0378_s_BOMB_BOSS_Draran_Hit_3.mid"
	.balign 4, 0
	.global mid_0379_s_BOMB_BOSS_Draran_Damage_1
mid_0379_s_BOMB_BOSS_Draran_Damage_1:
	.incbin "midi/0379_s_BOMB_BOSS_Draran_Damage_1.mid"
	.balign 4, 0
	.global mid_0380_s_BOMB_BOSS_Earthquake
mid_0380_s_BOMB_BOSS_Earthquake:
	.incbin "midi/0380_s_BOMB_BOSS_Earthquake.mid"
	.balign 4, 0
	.global mid_0381_s_Demo_DraBuru_Wiper_1_1
mid_0381_s_Demo_DraBuru_Wiper_1_1:
	.incbin "midi/0381_s_Demo_DraBuru_Wiper_1_1.mid"
	.balign 4, 0
	.global mid_0382_s_Demo_DraBuru_Wiper_1_2
mid_0382_s_Demo_DraBuru_Wiper_1_2:
	.incbin "midi/0382_s_Demo_DraBuru_Wiper_1_2.mid"
	.balign 4, 0
	.global mid_0383_s_Demo_DraBuru_Wiper_2_1
mid_0383_s_Demo_DraBuru_Wiper_2_1:
	.incbin "midi/0383_s_Demo_DraBuru_Wiper_2_1.mid"
	.balign 4, 0
	.global mid_0384_s_Demo_DraBuru_Wiper_2_2
mid_0384_s_Demo_DraBuru_Wiper_2_2:
	.incbin "midi/0384_s_Demo_DraBuru_Wiper_2_2.mid"
	.balign 4, 0
	.global mid_0385_s_Demo_Dra_CountDown_3
mid_0385_s_Demo_Dra_CountDown_3:
	.incbin "midi/0385_s_Demo_Dra_CountDown_3.mid"
	.balign 4, 0
	.global mid_0386_s_Demo_Dra_CountDown_2
mid_0386_s_Demo_Dra_CountDown_2:
	.incbin "midi/0386_s_Demo_Dra_CountDown_2.mid"
	.balign 4, 0
	.global mid_0387_s_Demo_Dra_CountDown_1
mid_0387_s_Demo_Dra_CountDown_1:
	.incbin "midi/0387_s_Demo_Dra_CountDown_1.mid"
	.balign 4, 0
	.global mid_0388_s_Demo_DraBuru_EP_Car
mid_0388_s_Demo_DraBuru_EP_Car:
	.incbin "midi/0388_s_Demo_DraBuru_EP_Car.mid"
	.balign 4, 0
	.global mid_0389_s_Demo_DraBuru_EP_Change
mid_0389_s_Demo_DraBuru_EP_Change:
	.incbin "midi/0389_s_Demo_DraBuru_EP_Change.mid"
	.balign 4, 0
	.global mid_0390_s_Demo_Monna_Bird_01
mid_0390_s_Demo_Monna_Bird_01:
	.incbin "midi/0390_s_Demo_Monna_Bird_01.mid"
	.balign 4, 0
	.global mid_0391_s_Demo_Monna_Bird_02
mid_0391_s_Demo_Monna_Bird_02:
	.incbin "midi/0391_s_Demo_Monna_Bird_02.mid"
	.balign 4, 0
	.global mid_0392_s_Demo_Monna_Walk_01
mid_0392_s_Demo_Monna_Walk_01:
	.incbin "midi/0392_s_Demo_Monna_Walk_01.mid"
	.balign 4, 0
	.global mid_0393_s_Demo_Monna_Walk_02
mid_0393_s_Demo_Monna_Walk_02:
	.incbin "midi/0393_s_Demo_Monna_Walk_02.mid"
	.balign 4, 0
	.global mid_0394_s_Demo_Monna_Shutter_01
mid_0394_s_Demo_Monna_Shutter_01:
	.incbin "midi/0394_s_Demo_Monna_Shutter_01.mid"
	.balign 4, 0
	.global mid_0395_s_Demo_Monna_Slide_01
mid_0395_s_Demo_Monna_Slide_01:
	.incbin "midi/0395_s_Demo_Monna_Slide_01.mid"
	.balign 4, 0
	.global mid_0396_s_Demo_Monna_KACHA_01
mid_0396_s_Demo_Monna_KACHA_01:
	.incbin "midi/0396_s_Demo_Monna_KACHA_01.mid"
	.balign 4, 0
	.global mid_0397_s_Demo_Monna_Goggles_01
mid_0397_s_Demo_Monna_Goggles_01:
	.incbin "midi/0397_s_Demo_Monna_Goggles_01.mid"
	.balign 4, 0
	.global mid_0398_s_Demo_Mon_CountDown_3
mid_0398_s_Demo_Mon_CountDown_3:
	.incbin "midi/0398_s_Demo_Mon_CountDown_3.mid"
	.balign 4, 0
	.global mid_0399_s_Demo_Mon_CountDown_2
mid_0399_s_Demo_Mon_CountDown_2:
	.incbin "midi/0399_s_Demo_Mon_CountDown_2.mid"
	.balign 4, 0
	.global mid_0400_s_Demo_Mon_CountDown_1
mid_0400_s_Demo_Mon_CountDown_1:
	.incbin "midi/0400_s_Demo_Mon_CountDown_1.mid"
	.balign 4, 0
	.global mid_0401_s_Demo_Mon_GameOver
mid_0401_s_Demo_Mon_GameOver:
	.incbin "midi/0401_s_Demo_Mon_GameOver.mid"
	.balign 4, 0
	.global mid_0402_s_Demo_Monna_EP_Bike
mid_0402_s_Demo_Monna_EP_Bike:
	.incbin "midi/0402_s_Demo_Monna_EP_Bike.mid"
	.balign 4, 0
	.global mid_0403_s_Demo_Monna_EP_Clock
mid_0403_s_Demo_Monna_EP_Clock:
	.incbin "midi/0403_s_Demo_Monna_EP_Clock.mid"
	.balign 4, 0
	.global mid_0404_s_Demo_AFRO_Tel_Catch
mid_0404_s_Demo_AFRO_Tel_Catch:
	.incbin "midi/0404_s_Demo_AFRO_Tel_Catch.mid"
	.balign 4, 0
	.global mid_0405_s_Demo_AFRO_CountDown_1
mid_0405_s_Demo_AFRO_CountDown_1:
	.incbin "midi/0405_s_Demo_AFRO_CountDown_1.mid"
	.balign 4, 0
	.global mid_0406_s_Demo_AFRO_CountDown_2
mid_0406_s_Demo_AFRO_CountDown_2:
	.incbin "midi/0406_s_Demo_AFRO_CountDown_2.mid"
	.balign 4, 0
	.global mid_0407_s_Demo_AFRO_CountDown_3
mid_0407_s_Demo_AFRO_CountDown_3:
	.incbin "midi/0407_s_Demo_AFRO_CountDown_3.mid"
	.balign 4, 0
	.global mid_0408_s_Demo_Bio_Crash_1
mid_0408_s_Demo_Bio_Crash_1:
	.incbin "midi/0408_s_Demo_Bio_Crash_1.mid"
	.balign 4, 0
	.global mid_0409_s_Demo_Bio_CountDown_3
mid_0409_s_Demo_Bio_CountDown_3:
	.incbin "midi/0409_s_Demo_Bio_CountDown_3.mid"
	.balign 4, 0
	.global mid_0410_s_Demo_Bio_CountDown_2
mid_0410_s_Demo_Bio_CountDown_2:
	.incbin "midi/0410_s_Demo_Bio_CountDown_2.mid"
	.balign 4, 0
	.global mid_0411_s_Demo_Bio_CountDown_1
mid_0411_s_Demo_Bio_CountDown_1:
	.incbin "midi/0411_s_Demo_Bio_CountDown_1.mid"
	.balign 4, 0
	.global mid_0412_s_Demo_KAEDE_Open_1
mid_0412_s_Demo_KAEDE_Open_1:
	.incbin "midi/0412_s_Demo_KAEDE_Open_1.mid"
	.balign 4, 0
	.global mid_0413_s_Demo_KAEDE_Go_1
mid_0413_s_Demo_KAEDE_Go_1:
	.incbin "midi/0413_s_Demo_KAEDE_Go_1.mid"
	.balign 4, 0
	.global mid_0414_s_Demo_KAEDE_KATANA_1
mid_0414_s_Demo_KAEDE_KATANA_1:
	.incbin "midi/0414_s_Demo_KAEDE_KATANA_1.mid"
	.balign 4, 0
	.global mid_0415_s_Demo_KAEDE_TEKI_UP
mid_0415_s_Demo_KAEDE_TEKI_UP:
	.incbin "midi/0415_s_Demo_KAEDE_TEKI_UP.mid"
	.balign 4, 0
	.global mid_0416_s_Demo_KAEDE_CountDown_3
mid_0416_s_Demo_KAEDE_CountDown_3:
	.incbin "midi/0416_s_Demo_KAEDE_CountDown_3.mid"
	.balign 4, 0
	.global mid_0417_s_Demo_KAEDE_CountDown_2
mid_0417_s_Demo_KAEDE_CountDown_2:
	.incbin "midi/0417_s_Demo_KAEDE_CountDown_2.mid"
	.balign 4, 0
	.global mid_0418_s_Demo_KAEDE_CountDown_1
mid_0418_s_Demo_KAEDE_CountDown_1:
	.incbin "midi/0418_s_Demo_KAEDE_CountDown_1.mid"
	.balign 4, 0
	.global mid_0419_s_Demo_KAEDE_EP_STEP
mid_0419_s_Demo_KAEDE_EP_STEP:
	.incbin "midi/0419_s_Demo_KAEDE_EP_STEP.mid"
	.balign 4, 0
	.global mid_0420_s_Demo_KAEDE_EP_Voice
mid_0420_s_Demo_KAEDE_EP_Voice:
	.incbin "midi/0420_s_Demo_KAEDE_EP_Voice.mid"
	.balign 4, 0
	.global mid_0421_s_Demo_KAEDE_KATANA_2
mid_0421_s_Demo_KAEDE_KATANA_2:
	.incbin "midi/0421_s_Demo_KAEDE_KATANA_2.mid"
	.balign 4, 0
	.global mid_0422_s_Demo_KAEDE_TEKI_Laugh_1
mid_0422_s_Demo_KAEDE_TEKI_Laugh_1:
	.incbin "midi/0422_s_Demo_KAEDE_TEKI_Laugh_1.mid"
	.balign 4, 0
	.global mid_0423_s_Demo_KAEDE_EP_Jump
mid_0423_s_Demo_KAEDE_EP_Jump:
	.incbin "midi/0423_s_Demo_KAEDE_EP_Jump.mid"
	.balign 4, 0
	.global mid_0424_s_Demo_Loo_Paper_1
mid_0424_s_Demo_Loo_Paper_1:
	.incbin "midi/0424_s_Demo_Loo_Paper_1.mid"
	.balign 4, 0
	.global mid_0425_s_Demo_Loo_Water_OUT_1
mid_0425_s_Demo_Loo_Water_OUT_1:
	.incbin "midi/0425_s_Demo_Loo_Water_OUT_1.mid"
	.balign 4, 0
	.global mid_0426_s_Demo_Loo_Water_IN_1
mid_0426_s_Demo_Loo_Water_IN_1:
	.incbin "midi/0426_s_Demo_Loo_Water_IN_1.mid"
	.balign 4, 0
	.global mid_0427_s_Demo_Loo_Flap
mid_0427_s_Demo_Loo_Flap:
	.incbin "midi/0427_s_Demo_Loo_Flap.mid"
	.balign 4, 0
	.global mid_0428_s_Demo_Loo_CountDown_3
mid_0428_s_Demo_Loo_CountDown_3:
	.incbin "midi/0428_s_Demo_Loo_CountDown_3.mid"
	.balign 4, 0
	.global mid_0429_s_Demo_Loo_CountDown_2
mid_0429_s_Demo_Loo_CountDown_2:
	.incbin "midi/0429_s_Demo_Loo_CountDown_2.mid"
	.balign 4, 0
	.global mid_0430_s_Demo_Loo_CountDown_1
mid_0430_s_Demo_Loo_CountDown_1:
	.incbin "midi/0430_s_Demo_Loo_CountDown_1.mid"
	.balign 4, 0
	.global mid_0431_s_Demo_Loo_EP_Water_JET_1
mid_0431_s_Demo_Loo_EP_Water_JET_1:
	.incbin "midi/0431_s_Demo_Loo_EP_Water_JET_1.mid"
	.balign 4, 0
	.global mid_0432_s_Demo_Loo_EP_Water_JET_2
mid_0432_s_Demo_Loo_EP_Water_JET_2:
	.incbin "midi/0432_s_Demo_Loo_EP_Water_JET_2.mid"
	.balign 4, 0
	.global mid_0433_s_Demo_Loo_EP_Rocket
mid_0433_s_Demo_Loo_EP_Rocket:
	.incbin "midi/0433_s_Demo_Loo_EP_Rocket.mid"
	.balign 4, 0
	.global mid_0434_s_Demo_Loo_EP_FALL_01
mid_0434_s_Demo_Loo_EP_FALL_01:
	.incbin "midi/0434_s_Demo_Loo_EP_FALL_01.mid"
	.balign 4, 0
	.global mid_0435_s_Demo_Loo_EP_Bird_01
mid_0435_s_Demo_Loo_EP_Bird_01:
	.incbin "midi/0435_s_Demo_Loo_EP_Bird_01.mid"
	.balign 4, 0
	.global mid_0436_s_Demo_Loo_EP_Swim_01
mid_0436_s_Demo_Loo_EP_Swim_01:
	.incbin "midi/0436_s_Demo_Loo_EP_Swim_01.mid"
	.balign 4, 0
	.global mid_0437_s_Demo_Voya_CountDown_3
mid_0437_s_Demo_Voya_CountDown_3:
	.incbin "midi/0437_s_Demo_Voya_CountDown_3.mid"
	.balign 4, 0
	.global mid_0438_s_Demo_Voya_CountDown_2
mid_0438_s_Demo_Voya_CountDown_2:
	.incbin "midi/0438_s_Demo_Voya_CountDown_2.mid"
	.balign 4, 0
	.global mid_0439_s_Demo_Voya_CountDown_1
mid_0439_s_Demo_Voya_CountDown_1:
	.incbin "midi/0439_s_Demo_Voya_CountDown_1.mid"
	.balign 4, 0
	.global mid_0440_s_Demo_Voya_EP_BOARD_1
mid_0440_s_Demo_Voya_EP_BOARD_1:
	.incbin "midi/0440_s_Demo_Voya_EP_BOARD_1.mid"
	.balign 4, 0
	.global mid_0441_s_Demo_Wario_CountDown_3
mid_0441_s_Demo_Wario_CountDown_3:
	.incbin "midi/0441_s_Demo_Wario_CountDown_3.mid"
	.balign 4, 0
	.global mid_0442_s_Demo_Wario_CountDown_2
mid_0442_s_Demo_Wario_CountDown_2:
	.incbin "midi/0442_s_Demo_Wario_CountDown_2.mid"
	.balign 4, 0
	.global mid_0443_s_Demo_Wario_CountDown_1
mid_0443_s_Demo_Wario_CountDown_1:
	.incbin "midi/0443_s_Demo_Wario_CountDown_1.mid"
	.balign 4, 0
	.global mid_0444_s_Demo_Wario_EP_Earthquake
mid_0444_s_Demo_Wario_EP_Earthquake:
	.incbin "midi/0444_s_Demo_Wario_EP_Earthquake.mid"
	.balign 4, 0
	.global mid_0445_s_Demo_Wario_EP_UP_Loo
mid_0445_s_Demo_Wario_EP_UP_Loo:
	.incbin "midi/0445_s_Demo_Wario_EP_UP_Loo.mid"
	.balign 4, 0
	.global mid_0446_s_Demo_Wario_EP_UP_Wario
mid_0446_s_Demo_Wario_EP_UP_Wario:
	.incbin "midi/0446_s_Demo_Wario_EP_UP_Wario.mid"
	.balign 4, 0
	.global mid_0447_s_BOMB_Success_01
mid_0447_s_BOMB_Success_01:
	.incbin "midi/0447_s_BOMB_Success_01.mid"
	.balign 4, 0
	.global mid_0448_s_BOMB_OK_01
mid_0448_s_BOMB_OK_01:
	.incbin "midi/0448_s_BOMB_OK_01.mid"
	.balign 4, 0
	.global mid_0449_s_BOMB_OK_02_Bamboo
mid_0449_s_BOMB_OK_02_Bamboo:
	.incbin "midi/0449_s_BOMB_OK_02_Bamboo.mid"
	.balign 4, 0
	.global mid_0450_s_BOMB_OK_03
mid_0450_s_BOMB_OK_03:
	.incbin "midi/0450_s_BOMB_OK_03.mid"
	.balign 4, 0
	.global mid_0451_s_BOMB_OK_04
mid_0451_s_BOMB_OK_04:
	.incbin "midi/0451_s_BOMB_OK_04.mid"
	.balign 4, 0
	.global mid_0452_s_BOMB_OK_05
mid_0452_s_BOMB_OK_05:
	.incbin "midi/0452_s_BOMB_OK_05.mid"
	.balign 4, 0
	.global mid_0453_s_BOMB_OK_06
mid_0453_s_BOMB_OK_06:
	.incbin "midi/0453_s_BOMB_OK_06.mid"
	.balign 4, 0
	.global mid_0454_s_BOMB_OK_07
mid_0454_s_BOMB_OK_07:
	.incbin "midi/0454_s_BOMB_OK_07.mid"
	.balign 4, 0
	.global mid_0455_s_BOMB_OK_08
mid_0455_s_BOMB_OK_08:
	.incbin "midi/0455_s_BOMB_OK_08.mid"
	.balign 4, 0
	.global mid_0456_s_BOMB_OK_09
mid_0456_s_BOMB_OK_09:
	.incbin "midi/0456_s_BOMB_OK_09.mid"
	.balign 4, 0
	.global mid_0457_s_BOMB_OK_10_Suck_Apple
mid_0457_s_BOMB_OK_10_Suck_Apple:
	.incbin "midi/0457_s_BOMB_OK_10_Suck_Apple.mid"
	.balign 4, 0
	.global mid_0458_s_BOMB_OK_11_SPY
mid_0458_s_BOMB_OK_11_SPY:
	.incbin "midi/0458_s_BOMB_OK_11_SPY.mid"
	.balign 4, 0
	.global mid_0459_s_BOMB_OK_12
mid_0459_s_BOMB_OK_12:
	.incbin "midi/0459_s_BOMB_OK_12.mid"
	.balign 4, 0
	.global mid_0460_s_BOMB_OK_13
mid_0460_s_BOMB_OK_13:
	.incbin "midi/0460_s_BOMB_OK_13.mid"
	.balign 4, 0
	.global mid_0461_s_BOMB_OK_14
mid_0461_s_BOMB_OK_14:
	.incbin "midi/0461_s_BOMB_OK_14.mid"
	.balign 4, 0
	.global mid_0462_s_BOMB_OK_15
mid_0462_s_BOMB_OK_15:
	.incbin "midi/0462_s_BOMB_OK_15.mid"
	.balign 4, 0
	.global mid_0463_s_BOMB_OK_17
mid_0463_s_BOMB_OK_17:
	.incbin "midi/0463_s_BOMB_OK_17.mid"
	.balign 4, 0
	.global mid_0464_s_BOMB_OK_19
mid_0464_s_BOMB_OK_19:
	.incbin "midi/0464_s_BOMB_OK_19.mid"
	.balign 4, 0
	.global mid_0465_s_BOMB_OK_20
mid_0465_s_BOMB_OK_20:
	.incbin "midi/0465_s_BOMB_OK_20.mid"
	.balign 4, 0
	.global mid_0466_s_BOMB_OK_21
mid_0466_s_BOMB_OK_21:
	.incbin "midi/0466_s_BOMB_OK_21.mid"
	.balign 4, 0
	.global mid_0467_s_BOMB_OK_22
mid_0467_s_BOMB_OK_22:
	.incbin "midi/0467_s_BOMB_OK_22.mid"
	.balign 4, 0
	.global mid_0468_s_BOMB_OK_23
mid_0468_s_BOMB_OK_23:
	.incbin "midi/0468_s_BOMB_OK_23.mid"
	.balign 4, 0
	.global mid_0469_s_BOMB_OK_24
mid_0469_s_BOMB_OK_24:
	.incbin "midi/0469_s_BOMB_OK_24.mid"
	.balign 4, 0
	.global mid_0470_s_BOMB_OK_25
mid_0470_s_BOMB_OK_25:
	.incbin "midi/0470_s_BOMB_OK_25.mid"
	.balign 4, 0
	.global mid_0471_s_BOMB_OK_26
mid_0471_s_BOMB_OK_26:
	.incbin "midi/0471_s_BOMB_OK_26.mid"
	.balign 4, 0
	.global mid_0472_s_BOMB_OK_27
mid_0472_s_BOMB_OK_27:
	.incbin "midi/0472_s_BOMB_OK_27.mid"
	.balign 4, 0
	.global mid_0473_s_BOMB_OK_28
mid_0473_s_BOMB_OK_28:
	.incbin "midi/0473_s_BOMB_OK_28.mid"
	.balign 4, 0
	.global mid_0474_s_BOMB_OK_29
mid_0474_s_BOMB_OK_29:
	.incbin "midi/0474_s_BOMB_OK_29.mid"
	.balign 4, 0
	.global mid_0475_s_BOMB_OK_30
mid_0475_s_BOMB_OK_30:
	.incbin "midi/0475_s_BOMB_OK_30.mid"
	.balign 4, 0
	.global mid_0476_s_BOMB_OK_31
mid_0476_s_BOMB_OK_31:
	.incbin "midi/0476_s_BOMB_OK_31.mid"
	.balign 4, 0
	.global mid_0477_s_BOMB_OK_32
mid_0477_s_BOMB_OK_32:
	.incbin "midi/0477_s_BOMB_OK_32.mid"
	.balign 4, 0
	.global mid_0478_s_BOMB_OK_33
mid_0478_s_BOMB_OK_33:
	.incbin "midi/0478_s_BOMB_OK_33.mid"
	.balign 4, 0
	.global mid_0479_s_BOMB_OK_34
mid_0479_s_BOMB_OK_34:
	.incbin "midi/0479_s_BOMB_OK_34.mid"
	.balign 4, 0
	.global mid_0480_s_BOMB_OK_35
mid_0480_s_BOMB_OK_35:
	.incbin "midi/0480_s_BOMB_OK_35.mid"
	.balign 4, 0
	.global mid_0481_s_BOMB_OK_36
mid_0481_s_BOMB_OK_36:
	.incbin "midi/0481_s_BOMB_OK_36.mid"
	.balign 4, 0
	.global mid_0482_s_BOMB_OK_37
mid_0482_s_BOMB_OK_37:
	.incbin "midi/0482_s_BOMB_OK_37.mid"
	.balign 4, 0
	.global mid_0483_s_BOMB_OK_38
mid_0483_s_BOMB_OK_38:
	.incbin "midi/0483_s_BOMB_OK_38.mid"
	.balign 4, 0
	.global mid_0484_s_BOMB_OK_39
mid_0484_s_BOMB_OK_39:
	.incbin "midi/0484_s_BOMB_OK_39.mid"
	.balign 4, 0
	.global mid_0485_s_BOMB_OK_40
mid_0485_s_BOMB_OK_40:
	.incbin "midi/0485_s_BOMB_OK_40.mid"
	.balign 4, 0
	.global mid_0486_s_BOMB_OK_41
mid_0486_s_BOMB_OK_41:
	.incbin "midi/0486_s_BOMB_OK_41.mid"
	.balign 4, 0
	.global mid_0487_s_BOMB_OK_42
mid_0487_s_BOMB_OK_42:
	.incbin "midi/0487_s_BOMB_OK_42.mid"
	.balign 4, 0
	.global mid_0488_s_BOMB_OK_43
mid_0488_s_BOMB_OK_43:
	.incbin "midi/0488_s_BOMB_OK_43.mid"
	.balign 4, 0
	.global mid_0489_s_BOMB_OK_44
mid_0489_s_BOMB_OK_44:
	.incbin "midi/0489_s_BOMB_OK_44.mid"
	.balign 4, 0
	.global mid_0490_s_BOMB_OK_45
mid_0490_s_BOMB_OK_45:
	.incbin "midi/0490_s_BOMB_OK_45.mid"
	.balign 4, 0
	.global mid_0491_s_BOMB_OK_46
mid_0491_s_BOMB_OK_46:
	.incbin "midi/0491_s_BOMB_OK_46.mid"
	.balign 4, 0
	.global mid_0492_s_BOMB_Fail_01
mid_0492_s_BOMB_Fail_01:
	.incbin "midi/0492_s_BOMB_Fail_01.mid"
	.balign 4, 0
	.global mid_0493_s_BOMB_Fail_02
mid_0493_s_BOMB_Fail_02:
	.incbin "midi/0493_s_BOMB_Fail_02.mid"
	.balign 4, 0
	.global mid_0494_s_BOMB_Fail_03
mid_0494_s_BOMB_Fail_03:
	.incbin "midi/0494_s_BOMB_Fail_03.mid"
	.balign 4, 0
	.global mid_0495_s_BOMB_Fail_04
mid_0495_s_BOMB_Fail_04:
	.incbin "midi/0495_s_BOMB_Fail_04.mid"
	.balign 4, 0
	.global mid_0496_s_BOMB_Fail_05
mid_0496_s_BOMB_Fail_05:
	.incbin "midi/0496_s_BOMB_Fail_05.mid"
	.balign 4, 0
	.global mid_0497_s_BOMB_Fail_06
mid_0497_s_BOMB_Fail_06:
	.incbin "midi/0497_s_BOMB_Fail_06.mid"
	.balign 4, 0
	.global mid_0498_s_BOMB_Fail_07
mid_0498_s_BOMB_Fail_07:
	.incbin "midi/0498_s_BOMB_Fail_07.mid"
	.balign 4, 0
	.global mid_0499_s_BOMB_Fail_08
mid_0499_s_BOMB_Fail_08:
	.incbin "midi/0499_s_BOMB_Fail_08.mid"
	.balign 4, 0
	.global mid_0500_s_BOMB_Fail_09
mid_0500_s_BOMB_Fail_09:
	.incbin "midi/0500_s_BOMB_Fail_09.mid"
	.balign 4, 0
	.global mid_0501_s_BOMB_Fail_10
mid_0501_s_BOMB_Fail_10:
	.incbin "midi/0501_s_BOMB_Fail_10.mid"
	.balign 4, 0
	.global mid_0502_s_BOMB_Fail_11
mid_0502_s_BOMB_Fail_11:
	.incbin "midi/0502_s_BOMB_Fail_11.mid"
	.balign 4, 0
	.global mid_0503_s_BOMB_Fail_12
mid_0503_s_BOMB_Fail_12:
	.incbin "midi/0503_s_BOMB_Fail_12.mid"
	.balign 4, 0
	.global mid_0504_s_BOMB_Fail_13
mid_0504_s_BOMB_Fail_13:
	.incbin "midi/0504_s_BOMB_Fail_13.mid"
	.balign 4, 0
	.global mid_0505_s_BOMB_Fail_14
mid_0505_s_BOMB_Fail_14:
	.incbin "midi/0505_s_BOMB_Fail_14.mid"
	.balign 4, 0
	.global mid_0506_s_BOMB_Fail_15
mid_0506_s_BOMB_Fail_15:
	.incbin "midi/0506_s_BOMB_Fail_15.mid"
	.balign 4, 0
	.global mid_0507_s_BOMB_Fail_16
mid_0507_s_BOMB_Fail_16:
	.incbin "midi/0507_s_BOMB_Fail_16.mid"
	.balign 4, 0
	.global mid_0508_s_BOMB_Fail_17
mid_0508_s_BOMB_Fail_17:
	.incbin "midi/0508_s_BOMB_Fail_17.mid"
	.balign 4, 0
	.global mid_0509_s_BOMB_Fail_18
mid_0509_s_BOMB_Fail_18:
	.incbin "midi/0509_s_BOMB_Fail_18.mid"
	.balign 4, 0
	.global mid_0510_s_BOMB_Fail_19_AIR
mid_0510_s_BOMB_Fail_19_AIR:
	.incbin "midi/0510_s_BOMB_Fail_19_AIR.mid"
	.balign 4, 0
	.global mid_0511_s_BOMB_Fail_20
mid_0511_s_BOMB_Fail_20:
	.incbin "midi/0511_s_BOMB_Fail_20.mid"
	.balign 4, 0
	.global mid_0512_s_BOMB_Fail_21
mid_0512_s_BOMB_Fail_21:
	.incbin "midi/0512_s_BOMB_Fail_21.mid"
	.balign 4, 0
	.global mid_0513_s_BOMB_Fail_22
mid_0513_s_BOMB_Fail_22:
	.incbin "midi/0513_s_BOMB_Fail_22.mid"
	.balign 4, 0
	.global mid_0514_s_BOMB_Fail_23
mid_0514_s_BOMB_Fail_23:
	.incbin "midi/0514_s_BOMB_Fail_23.mid"
	.balign 4, 0
	.global mid_0515_s_BOMB_Fail_24
mid_0515_s_BOMB_Fail_24:
	.incbin "midi/0515_s_BOMB_Fail_24.mid"
	.balign 4, 0
	.global mid_0516_s_BOMB_Fail_25
mid_0516_s_BOMB_Fail_25:
	.incbin "midi/0516_s_BOMB_Fail_25.mid"
	.balign 4, 0
	.global mid_0517_s_BOMB_Fail_26
mid_0517_s_BOMB_Fail_26:
	.incbin "midi/0517_s_BOMB_Fail_26.mid"
	.balign 4, 0
	.global mid_0518_s_BOMB_Fail_27
mid_0518_s_BOMB_Fail_27:
	.incbin "midi/0518_s_BOMB_Fail_27.mid"
	.balign 4, 0
	.global mid_0519_s_BOMB_Fail_28
mid_0519_s_BOMB_Fail_28:
	.incbin "midi/0519_s_BOMB_Fail_28.mid"
	.balign 4, 0
	.global mid_0520_s_BOMB_Fail_29
mid_0520_s_BOMB_Fail_29:
	.incbin "midi/0520_s_BOMB_Fail_29.mid"
	.balign 4, 0
	.global mid_0521_s_BOMB_Fail_30
mid_0521_s_BOMB_Fail_30:
	.incbin "midi/0521_s_BOMB_Fail_30.mid"
	.balign 4, 0
	.global mid_0522_s_BOMB_Fail_31
mid_0522_s_BOMB_Fail_31:
	.incbin "midi/0522_s_BOMB_Fail_31.mid"
	.balign 4, 0
	.global mid_0523_s_BOMB_Fail_32
mid_0523_s_BOMB_Fail_32:
	.incbin "midi/0523_s_BOMB_Fail_32.mid"
	.balign 4, 0
	.global mid_0524_s_BOMB_Fail_34
mid_0524_s_BOMB_Fail_34:
	.incbin "midi/0524_s_BOMB_Fail_34.mid"
	.balign 4, 0
	.global mid_0525_s_BOMB_Fail_35
mid_0525_s_BOMB_Fail_35:
	.incbin "midi/0525_s_BOMB_Fail_35.mid"
	.balign 4, 0
	.global mid_0526_s_BOMB_Fail_36
mid_0526_s_BOMB_Fail_36:
	.incbin "midi/0526_s_BOMB_Fail_36.mid"
	.balign 4, 0
	.global mid_0527_s_BOMB_Fail_37
mid_0527_s_BOMB_Fail_37:
	.incbin "midi/0527_s_BOMB_Fail_37.mid"
	.balign 4, 0
	.global mid_0528_s_BOMB_Fail_38
mid_0528_s_BOMB_Fail_38:
	.incbin "midi/0528_s_BOMB_Fail_38.mid"
	.balign 4, 0
	.global mid_0529_s_BOMB_Fail_39
mid_0529_s_BOMB_Fail_39:
	.incbin "midi/0529_s_BOMB_Fail_39.mid"
	.balign 4, 0
	.global mid_0530_s_BOMB_Fail_40
mid_0530_s_BOMB_Fail_40:
	.incbin "midi/0530_s_BOMB_Fail_40.mid"
	.balign 4, 0
	.global mid_0531_s_BOMB_Fail_41
mid_0531_s_BOMB_Fail_41:
	.incbin "midi/0531_s_BOMB_Fail_41.mid"
	.balign 4, 0
	.global mid_0532_s_BOMB_Fail_42
mid_0532_s_BOMB_Fail_42:
	.incbin "midi/0532_s_BOMB_Fail_42.mid"
	.balign 4, 0
	.global mid_0533_s_BOMB_Fail_43
mid_0533_s_BOMB_Fail_43:
	.incbin "midi/0533_s_BOMB_Fail_43.mid"
	.balign 4, 0
	.global mid_0534_s_BOMB_Fail_44
mid_0534_s_BOMB_Fail_44:
	.incbin "midi/0534_s_BOMB_Fail_44.mid"
	.balign 4, 0
	.global mid_0535_s_BOMB_Fail_45
mid_0535_s_BOMB_Fail_45:
	.incbin "midi/0535_s_BOMB_Fail_45.mid"
	.balign 4, 0
	.global mid_0536_s_BOMB_Fail_46
mid_0536_s_BOMB_Fail_46:
	.incbin "midi/0536_s_BOMB_Fail_46.mid"
	.balign 4, 0
	.global mid_0537_s_BOMB_Fail_47
mid_0537_s_BOMB_Fail_47:
	.incbin "midi/0537_s_BOMB_Fail_47.mid"
	.balign 4, 0
	.global mid_0538_s_BOMB_Fail_48
mid_0538_s_BOMB_Fail_48:
	.incbin "midi/0538_s_BOMB_Fail_48.mid"
	.balign 4, 0
	.global mid_0539_s_BOMB_Shot_01
mid_0539_s_BOMB_Shot_01:
	.incbin "midi/0539_s_BOMB_Shot_01.mid"
	.balign 4, 0
	.global mid_0540_s_BOMB_Shot_02
mid_0540_s_BOMB_Shot_02:
	.incbin "midi/0540_s_BOMB_Shot_02.mid"
	.balign 4, 0
	.global mid_0541_s_BOMB_Shot_03
mid_0541_s_BOMB_Shot_03:
	.incbin "midi/0541_s_BOMB_Shot_03.mid"
	.balign 4, 0
	.global mid_0542_s_BOMB_Shot_04
mid_0542_s_BOMB_Shot_04:
	.incbin "midi/0542_s_BOMB_Shot_04.mid"
	.balign 4, 0
	.global mid_0543_s_BOMB_Shot_05
mid_0543_s_BOMB_Shot_05:
	.incbin "midi/0543_s_BOMB_Shot_05.mid"
	.balign 4, 0
	.global mid_0544_s_BOMB_Shot_06
mid_0544_s_BOMB_Shot_06:
	.incbin "midi/0544_s_BOMB_Shot_06.mid"
	.balign 4, 0
	.global mid_0545_s_BOMB_Shot_07
mid_0545_s_BOMB_Shot_07:
	.incbin "midi/0545_s_BOMB_Shot_07.mid"
	.balign 4, 0
	.global mid_0546_s_BOMB_Shot_08
mid_0546_s_BOMB_Shot_08:
	.incbin "midi/0546_s_BOMB_Shot_08.mid"
	.balign 4, 0
	.global mid_0547_s_BOMB_Shot_09
mid_0547_s_BOMB_Shot_09:
	.incbin "midi/0547_s_BOMB_Shot_09.mid"
	.balign 4, 0
	.global mid_0548_s_BOMB_Shot_10
mid_0548_s_BOMB_Shot_10:
	.incbin "midi/0548_s_BOMB_Shot_10.mid"
	.balign 4, 0
	.global mid_0549_s_BOMB_Shot_11
mid_0549_s_BOMB_Shot_11:
	.incbin "midi/0549_s_BOMB_Shot_11.mid"
	.balign 4, 0
	.global mid_0550_s_BOMB_Shot_12
mid_0550_s_BOMB_Shot_12:
	.incbin "midi/0550_s_BOMB_Shot_12.mid"
	.balign 4, 0
	.global mid_0551_s_BOMB_Shot_13
mid_0551_s_BOMB_Shot_13:
	.incbin "midi/0551_s_BOMB_Shot_13.mid"
	.balign 4, 0
	.global mid_0552_s_BOMB_Shot_14
mid_0552_s_BOMB_Shot_14:
	.incbin "midi/0552_s_BOMB_Shot_14.mid"
	.balign 4, 0
	.global mid_0553_s_BOMB_Shot_15
mid_0553_s_BOMB_Shot_15:
	.incbin "midi/0553_s_BOMB_Shot_15.mid"
	.balign 4, 0
	.global mid_0554_s_BOMB_Shot_16
mid_0554_s_BOMB_Shot_16:
	.incbin "midi/0554_s_BOMB_Shot_16.mid"
	.balign 4, 0
	.global mid_0555_s_BOMB_Bomb_01
mid_0555_s_BOMB_Bomb_01:
	.incbin "midi/0555_s_BOMB_Bomb_01.mid"
	.balign 4, 0
	.global mid_0556_s_BOMB_Bomb_02
mid_0556_s_BOMB_Bomb_02:
	.incbin "midi/0556_s_BOMB_Bomb_02.mid"
	.balign 4, 0
	.global mid_0557_s_BOMB_Bomb_03
mid_0557_s_BOMB_Bomb_03:
	.incbin "midi/0557_s_BOMB_Bomb_03.mid"
	.balign 4, 0
	.global mid_0558_s_BOMB_Bomb_04
mid_0558_s_BOMB_Bomb_04:
	.incbin "midi/0558_s_BOMB_Bomb_04.mid"
	.balign 4, 0
	.global mid_0559_s_BOMB_Bomb_05
mid_0559_s_BOMB_Bomb_05:
	.incbin "midi/0559_s_BOMB_Bomb_05.mid"
	.balign 4, 0
	.global mid_0560_s_BOMB_Bomb_06
mid_0560_s_BOMB_Bomb_06:
	.incbin "midi/0560_s_BOMB_Bomb_06.mid"
	.balign 4, 0
	.global mid_0561_s_BOMB_Bomb_07
mid_0561_s_BOMB_Bomb_07:
	.incbin "midi/0561_s_BOMB_Bomb_07.mid"
	.balign 4, 0
	.global mid_0562_s_BOMB_Bomb_08
mid_0562_s_BOMB_Bomb_08:
	.incbin "midi/0562_s_BOMB_Bomb_08.mid"
	.balign 4, 0
	.global mid_0563_s_BOMB_Bomb_09
mid_0563_s_BOMB_Bomb_09:
	.incbin "midi/0563_s_BOMB_Bomb_09.mid"
	.balign 4, 0
	.global mid_0564_s_BOMB_Bomb_10
mid_0564_s_BOMB_Bomb_10:
	.incbin "midi/0564_s_BOMB_Bomb_10.mid"
	.balign 4, 0
	.global mid_0565_s_BOMB_Bomb_11
mid_0565_s_BOMB_Bomb_11:
	.incbin "midi/0565_s_BOMB_Bomb_11.mid"
	.balign 4, 0
	.global mid_0566_s_BOMB_Bomb_12
mid_0566_s_BOMB_Bomb_12:
	.incbin "midi/0566_s_BOMB_Bomb_12.mid"
	.balign 4, 0
	.global mid_0567_s_BOMB_Bomb_13
mid_0567_s_BOMB_Bomb_13:
	.incbin "midi/0567_s_BOMB_Bomb_13.mid"
	.balign 4, 0
	.global mid_0568_s_BOMB_Bomb_14
mid_0568_s_BOMB_Bomb_14:
	.incbin "midi/0568_s_BOMB_Bomb_14.mid"
	.balign 4, 0
	.global mid_0569_s_BOMB_Bomb_15
mid_0569_s_BOMB_Bomb_15:
	.incbin "midi/0569_s_BOMB_Bomb_15.mid"
	.balign 4, 0
	.global mid_0570_s_BOMB_FIRE_01
mid_0570_s_BOMB_FIRE_01:
	.incbin "midi/0570_s_BOMB_FIRE_01.mid"
	.balign 4, 0
	.global mid_0571_s_BOMB_FIRE_02
mid_0571_s_BOMB_FIRE_02:
	.incbin "midi/0571_s_BOMB_FIRE_02.mid"
	.balign 4, 0
	.global mid_0572_s_BOMB_JUMP_01
mid_0572_s_BOMB_JUMP_01:
	.incbin "midi/0572_s_BOMB_JUMP_01.mid"
	.balign 4, 0
	.global mid_0573_s_BOMB_JUMP_02
mid_0573_s_BOMB_JUMP_02:
	.incbin "midi/0573_s_BOMB_JUMP_02.mid"
	.balign 4, 0
	.global mid_0574_s_BOMB_JUMP_03_1
mid_0574_s_BOMB_JUMP_03_1:
	.incbin "midi/0574_s_BOMB_JUMP_03_1.mid"
	.balign 4, 0
	.global mid_0575_s_BOMB_JUMP_03_2
mid_0575_s_BOMB_JUMP_03_2:
	.incbin "midi/0575_s_BOMB_JUMP_03_2.mid"
	.balign 4, 0
	.global mid_0576_s_BOMB_JUMP_03_3
mid_0576_s_BOMB_JUMP_03_3:
	.incbin "midi/0576_s_BOMB_JUMP_03_3.mid"
	.balign 4, 0
	.global mid_0577_s_BOMB_JUMP_04
mid_0577_s_BOMB_JUMP_04:
	.incbin "midi/0577_s_BOMB_JUMP_04.mid"
	.balign 4, 0
	.global mid_0578_s_BOMB_JUMP_05
mid_0578_s_BOMB_JUMP_05:
	.incbin "midi/0578_s_BOMB_JUMP_05.mid"
	.balign 4, 0
	.global mid_0579_s_BOMB_JUMP_06
mid_0579_s_BOMB_JUMP_06:
	.incbin "midi/0579_s_BOMB_JUMP_06.mid"
	.balign 4, 0
	.global mid_0580_s_BOMB_JUMP_07
mid_0580_s_BOMB_JUMP_07:
	.incbin "midi/0580_s_BOMB_JUMP_07.mid"
	.balign 4, 0
	.global mid_0581_s_BOMB_JUMP_08
mid_0581_s_BOMB_JUMP_08:
	.incbin "midi/0581_s_BOMB_JUMP_08.mid"
	.balign 4, 0
	.global mid_0582_s_BOMB_JUMP_09
mid_0582_s_BOMB_JUMP_09:
	.incbin "midi/0582_s_BOMB_JUMP_09.mid"
	.balign 4, 0
	.global mid_0583_s_BOMB_JUMP_10
mid_0583_s_BOMB_JUMP_10:
	.incbin "midi/0583_s_BOMB_JUMP_10.mid"
	.balign 4, 0
	.global mid_0584_s_BOMB_JUMP_11
mid_0584_s_BOMB_JUMP_11:
	.incbin "midi/0584_s_BOMB_JUMP_11.mid"
	.balign 4, 0
	.global mid_0585_s_BOMB_JUMP_12
mid_0585_s_BOMB_JUMP_12:
	.incbin "midi/0585_s_BOMB_JUMP_12.mid"
	.balign 4, 0
	.global mid_0586_s_BOMB_JUMP_13
mid_0586_s_BOMB_JUMP_13:
	.incbin "midi/0586_s_BOMB_JUMP_13.mid"
	.balign 4, 0
	.global mid_0587_s_BOMB_FALL_01
mid_0587_s_BOMB_FALL_01:
	.incbin "midi/0587_s_BOMB_FALL_01.mid"
	.balign 4, 0
	.global mid_0588_s_BOMB_FALL_02
mid_0588_s_BOMB_FALL_02:
	.incbin "midi/0588_s_BOMB_FALL_02.mid"
	.balign 4, 0
	.global mid_0589_s_BOMB_FALL_03
mid_0589_s_BOMB_FALL_03:
	.incbin "midi/0589_s_BOMB_FALL_03.mid"
	.balign 4, 0
	.global mid_0590_s_BOMB_FALL_04
mid_0590_s_BOMB_FALL_04:
	.incbin "midi/0590_s_BOMB_FALL_04.mid"
	.balign 4, 0
	.global mid_0591_s_BOMB_FALL_05
mid_0591_s_BOMB_FALL_05:
	.incbin "midi/0591_s_BOMB_FALL_05.mid"
	.balign 4, 0
	.global mid_0592_s_BOMB_FALL_06
mid_0592_s_BOMB_FALL_06:
	.incbin "midi/0592_s_BOMB_FALL_06.mid"
	.balign 4, 0
	.global mid_0593_s_BOMB_FALL_07
mid_0593_s_BOMB_FALL_07:
	.incbin "midi/0593_s_BOMB_FALL_07.mid"
	.balign 4, 0
	.global mid_0594_s_BOMB_FALL_08
mid_0594_s_BOMB_FALL_08:
	.incbin "midi/0594_s_BOMB_FALL_08.mid"
	.balign 4, 0
	.global mid_0595_s_BOMB_FALL_09
mid_0595_s_BOMB_FALL_09:
	.incbin "midi/0595_s_BOMB_FALL_09.mid"
	.balign 4, 0
	.global mid_0596_s_BOMB_Catch_OK_01
mid_0596_s_BOMB_Catch_OK_01:
	.incbin "midi/0596_s_BOMB_Catch_OK_01.mid"
	.balign 4, 0
	.global mid_0597_s_BOMB_Catch_OK_02
mid_0597_s_BOMB_Catch_OK_02:
	.incbin "midi/0597_s_BOMB_Catch_OK_02.mid"
	.balign 4, 0
	.global mid_0598_s_BOMB_Catch_OK_03
mid_0598_s_BOMB_Catch_OK_03:
	.incbin "midi/0598_s_BOMB_Catch_OK_03.mid"
	.balign 4, 0
	.global mid_0599_s_BOMB_Catch_OK_04
mid_0599_s_BOMB_Catch_OK_04:
	.incbin "midi/0599_s_BOMB_Catch_OK_04.mid"
	.balign 4, 0
	.global mid_0600_s_BOMB_Catch_OK_041
mid_0600_s_BOMB_Catch_OK_041:
	.incbin "midi/0600_s_BOMB_Catch_OK_041.mid"
	.balign 4, 0
	.global mid_0601_s_BOMB_Catch_OK_05
mid_0601_s_BOMB_Catch_OK_05:
	.incbin "midi/0601_s_BOMB_Catch_OK_05.mid"
	.balign 4, 0
	.global mid_0602_s_BOMB_Catch_OK_06
mid_0602_s_BOMB_Catch_OK_06:
	.incbin "midi/0602_s_BOMB_Catch_OK_06.mid"
	.balign 4, 0
	.global mid_0603_s_BOMB_Catch_BAD_01
mid_0603_s_BOMB_Catch_BAD_01:
	.incbin "midi/0603_s_BOMB_Catch_BAD_01.mid"
	.balign 4, 0
	.global mid_0604_s_BOMB_Catch_BAD_02
mid_0604_s_BOMB_Catch_BAD_02:
	.incbin "midi/0604_s_BOMB_Catch_BAD_02.mid"
	.balign 4, 0
	.global mid_0605_s_BOMB_PI_01
mid_0605_s_BOMB_PI_01:
	.incbin "midi/0605_s_BOMB_PI_01.mid"
	.balign 4, 0
	.global mid_0606_s_BOMB_PI_02
mid_0606_s_BOMB_PI_02:
	.incbin "midi/0606_s_BOMB_PI_02.mid"
	.balign 4, 0
	.global mid_0607_s_BOMB_PI_03
mid_0607_s_BOMB_PI_03:
	.incbin "midi/0607_s_BOMB_PI_03.mid"
	.balign 4, 0
	.global mid_0608_s_BOMB_PI_04_E2
mid_0608_s_BOMB_PI_04_E2:
	.incbin "midi/0608_s_BOMB_PI_04_E2.mid"
	.balign 4, 0
	.global mid_0609_s_BOMB_PI_05_G2
mid_0609_s_BOMB_PI_05_G2:
	.incbin "midi/0609_s_BOMB_PI_05_G2.mid"
	.balign 4, 0
	.global mid_0610_s_BOMB_PI_06_A2
mid_0610_s_BOMB_PI_06_A2:
	.incbin "midi/0610_s_BOMB_PI_06_A2.mid"
	.balign 4, 0
	.global mid_0611_s_BOMB_PI_07_C3
mid_0611_s_BOMB_PI_07_C3:
	.incbin "midi/0611_s_BOMB_PI_07_C3.mid"
	.balign 4, 0
	.global mid_0612_s_BOMB_PI_08_E3
mid_0612_s_BOMB_PI_08_E3:
	.incbin "midi/0612_s_BOMB_PI_08_E3.mid"
	.balign 4, 0
	.global mid_0613_s_BOMB_PI_09
mid_0613_s_BOMB_PI_09:
	.incbin "midi/0613_s_BOMB_PI_09.mid"
	.balign 4, 0
	.global mid_0614_s_BOMB_PI_10_1
mid_0614_s_BOMB_PI_10_1:
	.incbin "midi/0614_s_BOMB_PI_10_1.mid"
	.balign 4, 0
	.global mid_0615_s_BOMB_PI_10_2
mid_0615_s_BOMB_PI_10_2:
	.incbin "midi/0615_s_BOMB_PI_10_2.mid"
	.balign 4, 0
	.global mid_0616_s_BOMB_PI_10_3
mid_0616_s_BOMB_PI_10_3:
	.incbin "midi/0616_s_BOMB_PI_10_3.mid"
	.balign 4, 0
	.global mid_0617_s_BOMB_PI_10_4
mid_0617_s_BOMB_PI_10_4:
	.incbin "midi/0617_s_BOMB_PI_10_4.mid"
	.balign 4, 0
	.global mid_0618_s_BOMB_PI_11
mid_0618_s_BOMB_PI_11:
	.incbin "midi/0618_s_BOMB_PI_11.mid"
	.balign 4, 0
	.global mid_0619_s_BOMB_PI_12
mid_0619_s_BOMB_PI_12:
	.incbin "midi/0619_s_BOMB_PI_12.mid"
	.balign 4, 0
	.global mid_0620_s_BOMB_PI_13
mid_0620_s_BOMB_PI_13:
	.incbin "midi/0620_s_BOMB_PI_13.mid"
	.balign 4, 0
	.global mid_0621_s_BOMB_PI_14
mid_0621_s_BOMB_PI_14:
	.incbin "midi/0621_s_BOMB_PI_14.mid"
	.balign 4, 0
	.global mid_0622_s_BOMB_PI_15
mid_0622_s_BOMB_PI_15:
	.incbin "midi/0622_s_BOMB_PI_15.mid"
	.balign 4, 0
	.global mid_0623_s_BOMB_PI_16
mid_0623_s_BOMB_PI_16:
	.incbin "midi/0623_s_BOMB_PI_16.mid"
	.balign 4, 0
	.global mid_0624_s_BOMB_PI_17
mid_0624_s_BOMB_PI_17:
	.incbin "midi/0624_s_BOMB_PI_17.mid"
	.balign 4, 0
	.global mid_0625_s_BOMB_PI_18
mid_0625_s_BOMB_PI_18:
	.incbin "midi/0625_s_BOMB_PI_18.mid"
	.balign 4, 0
	.global mid_0626_s_BOMB_PI_19
mid_0626_s_BOMB_PI_19:
	.incbin "midi/0626_s_BOMB_PI_19.mid"
	.balign 4, 0
	.global mid_0627_s_BOMB_PI_20
mid_0627_s_BOMB_PI_20:
	.incbin "midi/0627_s_BOMB_PI_20.mid"
	.balign 4, 0
	.global mid_0628_s_BOMB_PI_21
mid_0628_s_BOMB_PI_21:
	.incbin "midi/0628_s_BOMB_PI_21.mid"
	.balign 4, 0
	.global mid_0629_s_BOMB_Landing_01
mid_0629_s_BOMB_Landing_01:
	.incbin "midi/0629_s_BOMB_Landing_01.mid"
	.balign 4, 0
	.global mid_0630_s_BOMB_Landing_02_OK
mid_0630_s_BOMB_Landing_02_OK:
	.incbin "midi/0630_s_BOMB_Landing_02_OK.mid"
	.balign 4, 0
	.global mid_0631_s_BOMB_Landing_02_NG
mid_0631_s_BOMB_Landing_02_NG:
	.incbin "midi/0631_s_BOMB_Landing_02_NG.mid"
	.balign 4, 0
	.global mid_0632_s_BOMB_Landing_03
mid_0632_s_BOMB_Landing_03:
	.incbin "midi/0632_s_BOMB_Landing_03.mid"
	.balign 4, 0
	.global mid_0633_s_BOMB_Landing_03_OK
mid_0633_s_BOMB_Landing_03_OK:
	.incbin "midi/0633_s_BOMB_Landing_03_OK.mid"
	.balign 4, 0
	.global mid_0634_s_BOMB_Landing_04
mid_0634_s_BOMB_Landing_04:
	.incbin "midi/0634_s_BOMB_Landing_04.mid"
	.balign 4, 0
	.global mid_0635_s_BOMB_Curve_01
mid_0635_s_BOMB_Curve_01:
	.incbin "midi/0635_s_BOMB_Curve_01.mid"
	.balign 4, 0
	.global mid_0636_s_BOMB_Sweep_01
mid_0636_s_BOMB_Sweep_01:
	.incbin "midi/0636_s_BOMB_Sweep_01.mid"
	.balign 4, 0
	.global mid_0637_s_BOMB_Sweep_02
mid_0637_s_BOMB_Sweep_02:
	.incbin "midi/0637_s_BOMB_Sweep_02.mid"
	.balign 4, 0
	.global mid_0638_s_BOMB_Sweep_03
mid_0638_s_BOMB_Sweep_03:
	.incbin "midi/0638_s_BOMB_Sweep_03.mid"
	.balign 4, 0
	.global mid_0639_s_BOMB_Sweep_04
mid_0639_s_BOMB_Sweep_04:
	.incbin "midi/0639_s_BOMB_Sweep_04.mid"
	.balign 4, 0
	.global mid_0640_s_BOMB_PO_01
mid_0640_s_BOMB_PO_01:
	.incbin "midi/0640_s_BOMB_PO_01.mid"
	.balign 4, 0
	.global mid_0641_s_BOMB_KALI_01
mid_0641_s_BOMB_KALI_01:
	.incbin "midi/0641_s_BOMB_KALI_01.mid"
	.balign 4, 0
	.global mid_0642_s_BOMB_KALI_02
mid_0642_s_BOMB_KALI_02:
	.incbin "midi/0642_s_BOMB_KALI_02.mid"
	.balign 4, 0
	.global mid_0643_s_BOMB_KALI_03
mid_0643_s_BOMB_KALI_03:
	.incbin "midi/0643_s_BOMB_KALI_03.mid"
	.balign 4, 0
	.global mid_0644_s_BOMB_KALI_04
mid_0644_s_BOMB_KALI_04:
	.incbin "midi/0644_s_BOMB_KALI_04.mid"
	.balign 4, 0
	.global mid_0645_s_BOMB_KALI_05
mid_0645_s_BOMB_KALI_05:
	.incbin "midi/0645_s_BOMB_KALI_05.mid"
	.balign 4, 0
	.global mid_0646_s_BOMB_KALI_06
mid_0646_s_BOMB_KALI_06:
	.incbin "midi/0646_s_BOMB_KALI_06.mid"
	.balign 4, 0
	.global mid_0647_s_BOMB_KALI_07
mid_0647_s_BOMB_KALI_07:
	.incbin "midi/0647_s_BOMB_KALI_07.mid"
	.balign 4, 0
	.global mid_0648_s_BOMB_Bound_01
mid_0648_s_BOMB_Bound_01:
	.incbin "midi/0648_s_BOMB_Bound_01.mid"
	.balign 4, 0
	.global mid_0649_s_BOMB_Bound_02
mid_0649_s_BOMB_Bound_02:
	.incbin "midi/0649_s_BOMB_Bound_02.mid"
	.balign 4, 0
	.global mid_0650_s_BOMB_Bound_03
mid_0650_s_BOMB_Bound_03:
	.incbin "midi/0650_s_BOMB_Bound_03.mid"
	.balign 4, 0
	.global mid_0651_s_BOMB_Bound_04
mid_0651_s_BOMB_Bound_04:
	.incbin "midi/0651_s_BOMB_Bound_04.mid"
	.balign 4, 0
	.global mid_0652_s_BOMB_Bound_05
mid_0652_s_BOMB_Bound_05:
	.incbin "midi/0652_s_BOMB_Bound_05.mid"
	.balign 4, 0
	.global mid_0653_s_BOMB_Bound_06
mid_0653_s_BOMB_Bound_06:
	.incbin "midi/0653_s_BOMB_Bound_06.mid"
	.balign 4, 0
	.global mid_0654_s_BOMB_Bound_07
mid_0654_s_BOMB_Bound_07:
	.incbin "midi/0654_s_BOMB_Bound_07.mid"
	.balign 4, 0
	.global mid_0655_s_BOMB_Bound_08
mid_0655_s_BOMB_Bound_08:
	.incbin "midi/0655_s_BOMB_Bound_08.mid"
	.balign 4, 0
	.global mid_0656_s_BOMB_Push_01
mid_0656_s_BOMB_Push_01:
	.incbin "midi/0656_s_BOMB_Push_01.mid"
	.balign 4, 0
	.global mid_0657_s_BOMB_Push_02
mid_0657_s_BOMB_Push_02:
	.incbin "midi/0657_s_BOMB_Push_02.mid"
	.balign 4, 0
	.global mid_0658_s_BOMB_SMASH_02
mid_0658_s_BOMB_SMASH_02:
	.incbin "midi/0658_s_BOMB_SMASH_02.mid"
	.balign 4, 0
	.global mid_0659_s_BOMB_SMASH_03
mid_0659_s_BOMB_SMASH_03:
	.incbin "midi/0659_s_BOMB_SMASH_03.mid"
	.balign 4, 0
	.global mid_0660_s_BOMB_SMASH_04
mid_0660_s_BOMB_SMASH_04:
	.incbin "midi/0660_s_BOMB_SMASH_04.mid"
	.balign 4, 0
	.global mid_0661_s_BOMB_Throw_01
mid_0661_s_BOMB_Throw_01:
	.incbin "midi/0661_s_BOMB_Throw_01.mid"
	.balign 4, 0
	.global mid_0662_s_BOMB_Throw_02
mid_0662_s_BOMB_Throw_02:
	.incbin "midi/0662_s_BOMB_Throw_02.mid"
	.balign 4, 0
	.global mid_0663_s_BOMB_Throw_03
mid_0663_s_BOMB_Throw_03:
	.incbin "midi/0663_s_BOMB_Throw_03.mid"
	.balign 4, 0
	.global mid_0664_s_BOMB_Throw_04
mid_0664_s_BOMB_Throw_04:
	.incbin "midi/0664_s_BOMB_Throw_04.mid"
	.balign 4, 0
	.global mid_0665_s_BOMB_Throw_05
mid_0665_s_BOMB_Throw_05:
	.incbin "midi/0665_s_BOMB_Throw_05.mid"
	.balign 4, 0
	.global mid_0666_s_BOMB_v_Haa_01
mid_0666_s_BOMB_v_Haa_01:
	.incbin "midi/0666_s_BOMB_v_Haa_01.mid"
	.balign 4, 0
	.global mid_0667_s_BOMB_OUT_01
mid_0667_s_BOMB_OUT_01:
	.incbin "midi/0667_s_BOMB_OUT_01.mid"
	.balign 4, 0
	.global mid_0668_s_BOMB_v_Ahh_01
mid_0668_s_BOMB_v_Ahh_01:
	.incbin "midi/0668_s_BOMB_v_Ahh_01.mid"
	.balign 4, 0
	.global mid_0669_s_BOMB_BUTTON_01
mid_0669_s_BOMB_BUTTON_01:
	.incbin "midi/0669_s_BOMB_BUTTON_01.mid"
	.balign 4, 0
	.global mid_0670_s_BOMB_BUTTON_02
mid_0670_s_BOMB_BUTTON_02:
	.incbin "midi/0670_s_BOMB_BUTTON_02.mid"
	.balign 4, 0
	.global mid_0671_s_BOMB_Combine_01
mid_0671_s_BOMB_Combine_01:
	.incbin "midi/0671_s_BOMB_Combine_01.mid"
	.balign 4, 0
	.global mid_0672_s_BOMB_Combine_02
mid_0672_s_BOMB_Combine_02:
	.incbin "midi/0672_s_BOMB_Combine_02.mid"
	.balign 4, 0
	.global mid_0673_s_BOMB_Bowling_Throw_01
mid_0673_s_BOMB_Bowling_Throw_01:
	.incbin "midi/0673_s_BOMB_Bowling_Throw_01.mid"
	.balign 4, 0
	.global mid_0674_s_BOMB_Bowling_Gater
mid_0674_s_BOMB_Bowling_Gater:
	.incbin "midi/0674_s_BOMB_Bowling_Gater.mid"
	.balign 4, 0
	.global mid_0675_s_BOMB_Bowling_HIT_01
mid_0675_s_BOMB_Bowling_HIT_01:
	.incbin "midi/0675_s_BOMB_Bowling_HIT_01.mid"
	.balign 4, 0
	.global mid_0676_s_BOMB_Bowling_HIT_ALL
mid_0676_s_BOMB_Bowling_HIT_ALL:
	.incbin "midi/0676_s_BOMB_Bowling_HIT_ALL.mid"
	.balign 4, 0
	.global mid_0677_s_BOMB_WAVE_01
mid_0677_s_BOMB_WAVE_01:
	.incbin "midi/0677_s_BOMB_WAVE_01.mid"
	.balign 4, 0
	.global mid_0678_s_BOMB_WAVE_02
mid_0678_s_BOMB_WAVE_02:
	.incbin "midi/0678_s_BOMB_WAVE_02.mid"
	.balign 4, 0
	.global mid_0679_s_BOMB_SAW_01
mid_0679_s_BOMB_SAW_01:
	.incbin "midi/0679_s_BOMB_SAW_01.mid"
	.balign 4, 0
	.global mid_0680_s_BOMB_SAW_02
mid_0680_s_BOMB_SAW_02:
	.incbin "midi/0680_s_BOMB_SAW_02.mid"
	.balign 4, 0
	.global mid_0681_s_BOMB_Water_01
mid_0681_s_BOMB_Water_01:
	.incbin "midi/0681_s_BOMB_Water_01.mid"
	.balign 4, 0
	.global mid_0682_s_BOMB_Water_02
mid_0682_s_BOMB_Water_02:
	.incbin "midi/0682_s_BOMB_Water_02.mid"
	.balign 4, 0
	.global mid_0683_s_BOMB_Water_03
mid_0683_s_BOMB_Water_03:
	.incbin "midi/0683_s_BOMB_Water_03.mid"
	.balign 4, 0
	.global mid_0684_s_BOMB_Count_01
mid_0684_s_BOMB_Count_01:
	.incbin "midi/0684_s_BOMB_Count_01.mid"
	.balign 4, 0
	.global mid_0685_s_BOMB_PAD_01
mid_0685_s_BOMB_PAD_01:
	.incbin "midi/0685_s_BOMB_PAD_01.mid"
	.balign 4, 0
	.global mid_0686_s_BOMB_Archery_Shot_01
mid_0686_s_BOMB_Archery_Shot_01:
	.incbin "midi/0686_s_BOMB_Archery_Shot_01.mid"
	.balign 4, 0
	.global mid_0687_s_BOMB_Uproot_01
mid_0687_s_BOMB_Uproot_01:
	.incbin "midi/0687_s_BOMB_Uproot_01.mid"
	.balign 4, 0
	.global mid_0688_s_BOMB_Revolve_01
mid_0688_s_BOMB_Revolve_01:
	.incbin "midi/0688_s_BOMB_Revolve_01.mid"
	.balign 4, 0
	.global mid_0689_s_BOMB_Brush_01
mid_0689_s_BOMB_Brush_01:
	.incbin "midi/0689_s_BOMB_Brush_01.mid"
	.balign 4, 0
	.global mid_0690_s_BOMB_Flower_Water_01
mid_0690_s_BOMB_Flower_Water_01:
	.incbin "midi/0690_s_BOMB_Flower_Water_01.mid"
	.balign 4, 0
	.global mid_0691_s_BOMB_Please_01
mid_0691_s_BOMB_Please_01:
	.incbin "midi/0691_s_BOMB_Please_01.mid"
	.balign 4, 0
	.global mid_0692_s_BOMB_CAMERA_Shutter_01
mid_0692_s_BOMB_CAMERA_Shutter_01:
	.incbin "midi/0692_s_BOMB_CAMERA_Shutter_01.mid"
	.balign 4, 0
	.global mid_0693_s_BOMB_CAMERA_PRINT_01
mid_0693_s_BOMB_CAMERA_PRINT_01:
	.incbin "midi/0693_s_BOMB_CAMERA_PRINT_01.mid"
	.balign 4, 0
	.global mid_0694_s_BOMB_CAMERA_PRINT_02
mid_0694_s_BOMB_CAMERA_PRINT_02:
	.incbin "midi/0694_s_BOMB_CAMERA_PRINT_02.mid"
	.balign 4, 0
	.global mid_0695_s_BOMB_Jet_01
mid_0695_s_BOMB_Jet_01:
	.incbin "midi/0695_s_BOMB_Jet_01.mid"
	.balign 4, 0
	.global mid_0696_s_BOMB_Pour_01
mid_0696_s_BOMB_Pour_01:
	.incbin "midi/0696_s_BOMB_Pour_01.mid"
	.balign 4, 0
	.global mid_0697_s_BOMB_Turn_01
mid_0697_s_BOMB_Turn_01:
	.incbin "midi/0697_s_BOMB_Turn_01.mid"
	.balign 4, 0
	.global mid_0698_s_BOMB_START_01
mid_0698_s_BOMB_START_01:
	.incbin "midi/0698_s_BOMB_START_01.mid"
	.balign 4, 0
	.global mid_0699_s_BOMB_Suck_Body
mid_0699_s_BOMB_Suck_Body:
	.incbin "midi/0699_s_BOMB_Suck_Body.mid"
	.balign 4, 0
	.global mid_0700_s_BOMB_Page_Turn
mid_0700_s_BOMB_Page_Turn:
	.incbin "midi/0700_s_BOMB_Page_Turn.mid"
	.balign 4, 0
	.global mid_0701_s_BOMB_Page_MARK
mid_0701_s_BOMB_Page_MARK:
	.incbin "midi/0701_s_BOMB_Page_MARK.mid"
	.balign 4, 0
	.global mid_0702_s_BOMB_Trampoline_JUMP_2
mid_0702_s_BOMB_Trampoline_JUMP_2:
	.incbin "midi/0702_s_BOMB_Trampoline_JUMP_2.mid"
	.balign 4, 0
	.global mid_0703_s_BOMB_Trampoline_JUMP_3
mid_0703_s_BOMB_Trampoline_JUMP_3:
	.incbin "midi/0703_s_BOMB_Trampoline_JUMP_3.mid"
	.balign 4, 0
	.global mid_0704_s_BOMB_CURSOR_01
mid_0704_s_BOMB_CURSOR_01:
	.incbin "midi/0704_s_BOMB_CURSOR_01.mid"
	.balign 4, 0
	.global mid_0705_s_BOMB_Fly_01
mid_0705_s_BOMB_Fly_01:
	.incbin "midi/0705_s_BOMB_Fly_01.mid"
	.balign 4, 0
	.global mid_0706_s_BOMB_BIG_01
mid_0706_s_BOMB_BIG_01:
	.incbin "midi/0706_s_BOMB_BIG_01.mid"
	.balign 4, 0
	.global mid_0707_s_BOMB_Rotate_01
mid_0707_s_BOMB_Rotate_01:
	.incbin "midi/0707_s_BOMB_Rotate_01.mid"
	.balign 4, 0
	.global mid_0708_s_BOMB_AIR_ON
mid_0708_s_BOMB_AIR_ON:
	.incbin "midi/0708_s_BOMB_AIR_ON.mid"
	.balign 4, 0
	.global mid_0709_s_BOMB_AIR_OFF
mid_0709_s_BOMB_AIR_OFF:
	.incbin "midi/0709_s_BOMB_AIR_OFF.mid"
	.balign 4, 0
	.global mid_0710_s_BOMB_CAR_01
mid_0710_s_BOMB_CAR_01:
	.incbin "midi/0710_s_BOMB_CAR_01.mid"
	.balign 4, 0
	.global mid_0711_s_BOMB_CAR_02
mid_0711_s_BOMB_CAR_02:
	.incbin "midi/0711_s_BOMB_CAR_02.mid"
	.balign 4, 0
	.global mid_0712_s_BOMB_CAR_03
mid_0712_s_BOMB_CAR_03:
	.incbin "midi/0712_s_BOMB_CAR_03.mid"
	.balign 4, 0
	.global mid_0713_s_BOMB_CAR_04
mid_0713_s_BOMB_CAR_04:
	.incbin "midi/0713_s_BOMB_CAR_04.mid"
	.balign 4, 0
	.global mid_0714_s_BOMB_CAR_05
mid_0714_s_BOMB_CAR_05:
	.incbin "midi/0714_s_BOMB_CAR_05.mid"
	.balign 4, 0
	.global mid_0715_s_BOMB_CAR_06
mid_0715_s_BOMB_CAR_06:
	.incbin "midi/0715_s_BOMB_CAR_06.mid"
	.balign 4, 0
	.global mid_0716_s_BOMB_CAR_07
mid_0716_s_BOMB_CAR_07:
	.incbin "midi/0716_s_BOMB_CAR_07.mid"
	.balign 4, 0
	.global mid_0717_s_BOMB_CAR_08
mid_0717_s_BOMB_CAR_08:
	.incbin "midi/0717_s_BOMB_CAR_08.mid"
	.balign 4, 0
	.global mid_0718_s_BOMB_CAR_Back_01
mid_0718_s_BOMB_CAR_Back_01:
	.incbin "midi/0718_s_BOMB_CAR_Back_01.mid"
	.balign 4, 0
	.global mid_0719_s_BOMB_CAR_Bend
mid_0719_s_BOMB_CAR_Bend:
	.incbin "midi/0719_s_BOMB_CAR_Bend.mid"
	.balign 4, 0
	.global mid_0720_s_BOMB_CAR_Back_NG_01
mid_0720_s_BOMB_CAR_Back_NG_01:
	.incbin "midi/0720_s_BOMB_CAR_Back_NG_01.mid"
	.balign 4, 0
	.global mid_0721_s_BOMB_CAR_Crash_01
mid_0721_s_BOMB_CAR_Crash_01:
	.incbin "midi/0721_s_BOMB_CAR_Crash_01.mid"
	.balign 4, 0
	.global mid_0722_s_BOMB_WARP_01
mid_0722_s_BOMB_WARP_01:
	.incbin "midi/0722_s_BOMB_WARP_01.mid"
	.balign 4, 0
	.global mid_0723_s_BOMB_v_CHYOKI
mid_0723_s_BOMB_v_CHYOKI:
	.incbin "midi/0723_s_BOMB_v_CHYOKI.mid"
	.balign 4, 0
	.global mid_0724_s_BOMB_Change_01
mid_0724_s_BOMB_Change_01:
	.incbin "midi/0724_s_BOMB_Change_01.mid"
	.balign 4, 0
	.global mid_0725_s_BOMB_GOLF_CupIn_01
mid_0725_s_BOMB_GOLF_CupIn_01:
	.incbin "midi/0725_s_BOMB_GOLF_CupIn_01.mid"
	.balign 4, 0
	.global mid_0726_s_wario_JUMP_1
mid_0726_s_wario_JUMP_1:
	.incbin "midi/0726_s_wario_JUMP_1.mid"
	.balign 4, 0
	.global mid_0727_s_wario_DIE
mid_0727_s_wario_DIE:
	.incbin "midi/0727_s_wario_DIE.mid"
	.balign 4, 0
	.global mid_0728_s_BOMB_Nose_01
mid_0728_s_BOMB_Nose_01:
	.incbin "midi/0728_s_BOMB_Nose_01.mid"
	.balign 4, 0
	.global mid_0729_s_BOMB_Nose_02
mid_0729_s_BOMB_Nose_02:
	.incbin "midi/0729_s_BOMB_Nose_02.mid"
	.balign 4, 0
	.global mid_0730_s_BOMB_Nose_03
mid_0730_s_BOMB_Nose_03:
	.incbin "midi/0730_s_BOMB_Nose_03.mid"
	.balign 4, 0
	.global mid_0731_s_BOMB_Robot_UP
mid_0731_s_BOMB_Robot_UP:
	.incbin "midi/0731_s_BOMB_Robot_UP.mid"
	.balign 4, 0
	.global mid_0732_s_BOMB_Robot_DOWN
mid_0732_s_BOMB_Robot_DOWN:
	.incbin "midi/0732_s_BOMB_Robot_DOWN.mid"
	.balign 4, 0
	.global mid_0733_s_BOMB_Robot_NIP
mid_0733_s_BOMB_Robot_NIP:
	.incbin "midi/0733_s_BOMB_Robot_NIP.mid"
	.balign 4, 0
	.global mid_0734_s_BOMB_Robot_OK
mid_0734_s_BOMB_Robot_OK:
	.incbin "midi/0734_s_BOMB_Robot_OK.mid"
	.balign 4, 0
	.global mid_0735_s_BOMB_Robot_NG
mid_0735_s_BOMB_Robot_NG:
	.incbin "midi/0735_s_BOMB_Robot_NG.mid"
	.balign 4, 0
	.global mid_0736_s_BOMB_NIP_01
mid_0736_s_BOMB_NIP_01:
	.incbin "midi/0736_s_BOMB_NIP_01.mid"
	.balign 4, 0
	.global mid_0737_s_BOMB_Whistle_01
mid_0737_s_BOMB_Whistle_01:
	.incbin "midi/0737_s_BOMB_Whistle_01.mid"
	.balign 4, 0
	.global mid_0738_s_BOMB_Dog_Bow_01
mid_0738_s_BOMB_Dog_Bow_01:
	.incbin "midi/0738_s_BOMB_Dog_Bow_01.mid"
	.balign 4, 0
	.global mid_0739_s_BOMB_Get_01
mid_0739_s_BOMB_Get_01:
	.incbin "midi/0739_s_BOMB_Get_01.mid"
	.balign 4, 0
	.global mid_0740_s_BOMB_Get_02
mid_0740_s_BOMB_Get_02:
	.incbin "midi/0740_s_BOMB_Get_02.mid"
	.balign 4, 0
	.global mid_0741_s_BOMB_FootStep_01
mid_0741_s_BOMB_FootStep_01:
	.incbin "midi/0741_s_BOMB_FootStep_01.mid"
	.balign 4, 0
	.global mid_0742_s_BOMB_FootStep_02
mid_0742_s_BOMB_FootStep_02:
	.incbin "midi/0742_s_BOMB_FootStep_02.mid"
	.balign 4, 0
	.global mid_0743_s_BOMB_FootStep_03
mid_0743_s_BOMB_FootStep_03:
	.incbin "midi/0743_s_BOMB_FootStep_03.mid"
	.balign 4, 0
	.global mid_0744_s_BOMB_FootStep_04
mid_0744_s_BOMB_FootStep_04:
	.incbin "midi/0744_s_BOMB_FootStep_04.mid"
	.balign 4, 0
	.global mid_0745_s_BOMB_Damage_01
mid_0745_s_BOMB_Damage_01:
	.incbin "midi/0745_s_BOMB_Damage_01.mid"
	.balign 4, 0
	.global mid_0746_s_BOMB_BUMP_01
mid_0746_s_BOMB_BUMP_01:
	.incbin "midi/0746_s_BOMB_BUMP_01.mid"
	.balign 4, 0
	.global mid_0747_s_BOMB_BUMP_02
mid_0747_s_BOMB_BUMP_02:
	.incbin "midi/0747_s_BOMB_BUMP_02.mid"
	.balign 4, 0
	.global mid_0748_s_BOMB_BUMP_03
mid_0748_s_BOMB_BUMP_03:
	.incbin "midi/0748_s_BOMB_BUMP_03.mid"
	.balign 4, 0
	.global mid_0749_s_BOMB_Filter_01
mid_0749_s_BOMB_Filter_01:
	.incbin "midi/0749_s_BOMB_Filter_01.mid"
	.balign 4, 0
	.global mid_0750_s_BOMB_wario_B_Attack
mid_0750_s_BOMB_wario_B_Attack:
	.incbin "midi/0750_s_BOMB_wario_B_Attack.mid"
	.balign 4, 0
	.global mid_0751_s_BOMB_wario_BLOCK_Break_1
mid_0751_s_BOMB_wario_BLOCK_Break_1:
	.incbin "midi/0751_s_BOMB_wario_BLOCK_Break_1.mid"
	.balign 4, 0
	.global mid_0752_s_BOMB_wario_Hip_Attack_S
mid_0752_s_BOMB_wario_Hip_Attack_S:
	.incbin "midi/0752_s_BOMB_wario_Hip_Attack_S.mid"
	.balign 4, 0
	.global mid_0753_s_BOMB_Lizard_Tongue
mid_0753_s_BOMB_Lizard_Tongue:
	.incbin "midi/0753_s_BOMB_Lizard_Tongue.mid"
	.balign 4, 0
	.global mid_0754_s_BOMB_STOP_01
mid_0754_s_BOMB_STOP_01:
	.incbin "midi/0754_s_BOMB_STOP_01.mid"
	.balign 4, 0
	.global mid_0755_s_BOMB_STOP_02_CAR
mid_0755_s_BOMB_STOP_02_CAR:
	.incbin "midi/0755_s_BOMB_STOP_02_CAR.mid"
	.balign 4, 0
	.global mid_0756_s_BOMB_Frog_HIT
mid_0756_s_BOMB_Frog_HIT:
	.incbin "midi/0756_s_BOMB_Frog_HIT.mid"
	.balign 4, 0
	.global mid_0757_s_BOMB_Frog_SWIM
mid_0757_s_BOMB_Frog_SWIM:
	.incbin "midi/0757_s_BOMB_Frog_SWIM.mid"
	.balign 4, 0
	.global mid_0758_s_BOMB_Mario_Step_ON_1
mid_0758_s_BOMB_Mario_Step_ON_1:
	.incbin "midi/0758_s_BOMB_Mario_Step_ON_1.mid"
	.balign 4, 0
	.global mid_0759_s_BOMB_Mario_Step_ON_2
mid_0759_s_BOMB_Mario_Step_ON_2:
	.incbin "midi/0759_s_BOMB_Mario_Step_ON_2.mid"
	.balign 4, 0
	.global mid_0760_s_BOMB_Mario_Step_ON_3
mid_0760_s_BOMB_Mario_Step_ON_3:
	.incbin "midi/0760_s_BOMB_Mario_Step_ON_3.mid"
	.balign 4, 0
	.global mid_0761_s_BOMB_Mario2_Step_ON_1
mid_0761_s_BOMB_Mario2_Step_ON_1:
	.incbin "midi/0761_s_BOMB_Mario2_Step_ON_1.mid"
	.balign 4, 0
	.global mid_0762_s_BOMB_Mario2_Step_ON_2
mid_0762_s_BOMB_Mario2_Step_ON_2:
	.incbin "midi/0762_s_BOMB_Mario2_Step_ON_2.mid"
	.balign 4, 0
	.global mid_0763_s_BOMB_Mario2_Step_ON_3
mid_0763_s_BOMB_Mario2_Step_ON_3:
	.incbin "midi/0763_s_BOMB_Mario2_Step_ON_3.mid"
	.balign 4, 0
	.global mid_0764_s_BOMB_Mario_Step_ON_END
mid_0764_s_BOMB_Mario_Step_ON_END:
	.incbin "midi/0764_s_BOMB_Mario_Step_ON_END.mid"
	.balign 4, 0
	.global mid_0765_s_BOMB_Mario_Step_ON_END2
mid_0765_s_BOMB_Mario_Step_ON_END2:
	.incbin "midi/0765_s_BOMB_Mario_Step_ON_END2.mid"
	.balign 4, 0
	.global mid_0766_s_BOMB_Tennis_Hit_0
mid_0766_s_BOMB_Tennis_Hit_0:
	.incbin "midi/0766_s_BOMB_Tennis_Hit_0.mid"
	.balign 4, 0
	.global mid_0767_s_BOMB_Tennis_Hit_1
mid_0767_s_BOMB_Tennis_Hit_1:
	.incbin "midi/0767_s_BOMB_Tennis_Hit_1.mid"
	.balign 4, 0
	.global mid_0768_s_BOMB_Tennis_Hit_2
mid_0768_s_BOMB_Tennis_Hit_2:
	.incbin "midi/0768_s_BOMB_Tennis_Hit_2.mid"
	.balign 4, 0
	.global mid_0769_s_BOMB_Move_01
mid_0769_s_BOMB_Move_01:
	.incbin "midi/0769_s_BOMB_Move_01.mid"
	.balign 4, 0
	.global mid_0770_s_BOMB_AIR_01
mid_0770_s_BOMB_AIR_01:
	.incbin "midi/0770_s_BOMB_AIR_01.mid"
	.balign 4, 0
	.global mid_0771_s_BOMB_AIR_02
mid_0771_s_BOMB_AIR_02:
	.incbin "midi/0771_s_BOMB_AIR_02.mid"
	.balign 4, 0
	.global mid_0772_s_BOMB_Ele_01
mid_0772_s_BOMB_Ele_01:
	.incbin "midi/0772_s_BOMB_Ele_01.mid"
	.balign 4, 0
	.global mid_0773_s_BOMB_Ele_02
mid_0773_s_BOMB_Ele_02:
	.incbin "midi/0773_s_BOMB_Ele_02.mid"
	.balign 4, 0
	.global mid_0774_s_BOMB_Ele_03
mid_0774_s_BOMB_Ele_03:
	.incbin "midi/0774_s_BOMB_Ele_03.mid"
	.balign 4, 0
	.global mid_0775_s_BOMB_Ele_04
mid_0775_s_BOMB_Ele_04:
	.incbin "midi/0775_s_BOMB_Ele_04.mid"
	.balign 4, 0
	.global mid_0776_s_BOMB_Ele_05
mid_0776_s_BOMB_Ele_05:
	.incbin "midi/0776_s_BOMB_Ele_05.mid"
	.balign 4, 0
	.global mid_0777_s_BOMB_Ele_06
mid_0777_s_BOMB_Ele_06:
	.incbin "midi/0777_s_BOMB_Ele_06.mid"
	.balign 4, 0
	.global mid_0778_s_BOMB_v_1
mid_0778_s_BOMB_v_1:
	.incbin "midi/0778_s_BOMB_v_1.mid"
	.balign 4, 0
	.global mid_0779_s_BOMB_v_2
mid_0779_s_BOMB_v_2:
	.incbin "midi/0779_s_BOMB_v_2.mid"
	.balign 4, 0
	.global mid_0780_s_BOMB_v_3
mid_0780_s_BOMB_v_3:
	.incbin "midi/0780_s_BOMB_v_3.mid"
	.balign 4, 0
	.global mid_0781_s_BOMB_Beat_Tel_03
mid_0781_s_BOMB_Beat_Tel_03:
	.incbin "midi/0781_s_BOMB_Beat_Tel_03.mid"
	.balign 4, 0
	.global mid_0782_s_BOMB_Beat_Tel_04
mid_0782_s_BOMB_Beat_Tel_04:
	.incbin "midi/0782_s_BOMB_Beat_Tel_04.mid"
	.balign 4, 0
	.global mid_0783_s_BOMB_Beat_Tel_05
mid_0783_s_BOMB_Beat_Tel_05:
	.incbin "midi/0783_s_BOMB_Beat_Tel_05.mid"
	.balign 4, 0
	.global mid_0784_s_BOMB_Beat_Tel_06
mid_0784_s_BOMB_Beat_Tel_06:
	.incbin "midi/0784_s_BOMB_Beat_Tel_06.mid"
	.balign 4, 0
	.global mid_0785_s_BOMB_Beat_Tel_07
mid_0785_s_BOMB_Beat_Tel_07:
	.incbin "midi/0785_s_BOMB_Beat_Tel_07.mid"
	.balign 4, 0
	.global mid_0786_s_BOMB_GYORO_Walk_01
mid_0786_s_BOMB_GYORO_Walk_01:
	.incbin "midi/0786_s_BOMB_GYORO_Walk_01.mid"
	.balign 4, 0
	.global mid_0787_s_BOMB_GYORO_Shot_TANE
mid_0787_s_BOMB_GYORO_Shot_TANE:
	.incbin "midi/0787_s_BOMB_GYORO_Shot_TANE.mid"
	.balign 4, 0
	.global mid_0788_s_BOMB_GYORO_SHITA_Dasu
mid_0788_s_BOMB_GYORO_SHITA_Dasu:
	.incbin "midi/0788_s_BOMB_GYORO_SHITA_Dasu.mid"
	.balign 4, 0
	.global mid_0789_s_BOMB_GYORO_SHITA_Modosu
mid_0789_s_BOMB_GYORO_SHITA_Modosu:
	.incbin "midi/0789_s_BOMB_GYORO_SHITA_Modosu.mid"
	.balign 4, 0
	.global mid_0790_s_BOMB_GYORO_ESA_Get
mid_0790_s_BOMB_GYORO_ESA_Get:
	.incbin "midi/0790_s_BOMB_GYORO_ESA_Get.mid"
	.balign 4, 0
	.global mid_0791_s_BOMB_GYORO_Die_01
mid_0791_s_BOMB_GYORO_Die_01:
	.incbin "midi/0791_s_BOMB_GYORO_Die_01.mid"
	.balign 4, 0
	.global mid_0792_s_BOMB_GYORO_Die_Bean
mid_0792_s_BOMB_GYORO_Die_Bean:
	.incbin "midi/0792_s_BOMB_GYORO_Die_Bean.mid"
	.balign 4, 0
	.global mid_0793_s_BOMB_GYORO_Die_Bean_2
mid_0793_s_BOMB_GYORO_Die_Bean_2:
	.incbin "midi/0793_s_BOMB_GYORO_Die_Bean_2.mid"
	.balign 4, 0
	.global mid_0794_s_BOMB_GYORO_Die_Bean_3
mid_0794_s_BOMB_GYORO_Die_Bean_3:
	.incbin "midi/0794_s_BOMB_GYORO_Die_Bean_3.mid"
	.balign 4, 0
	.global mid_0795_s_BOMB_GYORO_Die_Bean_4
mid_0795_s_BOMB_GYORO_Die_Bean_4:
	.incbin "midi/0795_s_BOMB_GYORO_Die_Bean_4.mid"
	.balign 4, 0
	.global mid_0796_s_BOMB_GYORO_BOMB_01
mid_0796_s_BOMB_GYORO_BOMB_01:
	.incbin "midi/0796_s_BOMB_GYORO_BOMB_01.mid"
	.balign 4, 0
	.global mid_0797_s_BOMB_GYORO_Repair_Engel
mid_0797_s_BOMB_GYORO_Repair_Engel:
	.incbin "midi/0797_s_BOMB_GYORO_Repair_Engel.mid"
	.balign 4, 0
	.global mid_0798_s_BOMB_GYORO_Repair_01
mid_0798_s_BOMB_GYORO_Repair_01:
	.incbin "midi/0798_s_BOMB_GYORO_Repair_01.mid"
	.balign 4, 0
	.global mid_0799_s_BOMB_GYORO_Repair_02
mid_0799_s_BOMB_GYORO_Repair_02:
	.incbin "midi/0799_s_BOMB_GYORO_Repair_02.mid"
	.balign 4, 0
	.global mid_0800_s_BOMB_GYORO_Repair_03
mid_0800_s_BOMB_GYORO_Repair_03:
	.incbin "midi/0800_s_BOMB_GYORO_Repair_03.mid"
	.balign 4, 0
	.global mid_0801_s_BOMB_GYORO_Repair_04
mid_0801_s_BOMB_GYORO_Repair_04:
	.incbin "midi/0801_s_BOMB_GYORO_Repair_04.mid"
	.balign 4, 0
	.global mid_0802_s_BOMB_GYORO_Repair_05
mid_0802_s_BOMB_GYORO_Repair_05:
	.incbin "midi/0802_s_BOMB_GYORO_Repair_05.mid"
	.balign 4, 0
	.global mid_0803_s_BOMB_GYORO_STAR
mid_0803_s_BOMB_GYORO_STAR:
	.incbin "midi/0803_s_BOMB_GYORO_STAR.mid"
	.balign 4, 0
	.global mid_0804_s_BOMB_Wind_01
mid_0804_s_BOMB_Wind_01:
	.incbin "midi/0804_s_BOMB_Wind_01.mid"
	.balign 4, 0
	.global mid_0805_s_BOMB_Wind_02
mid_0805_s_BOMB_Wind_02:
	.incbin "midi/0805_s_BOMB_Wind_02.mid"
	.balign 4, 0
	.global mid_0806_s_BOMB_Voice_MALE_03
mid_0806_s_BOMB_Voice_MALE_03:
	.incbin "midi/0806_s_BOMB_Voice_MALE_03.mid"
	.balign 4, 0
	.global mid_0807_s_BOMB_Voice_MALE_04
mid_0807_s_BOMB_Voice_MALE_04:
	.incbin "midi/0807_s_BOMB_Voice_MALE_04.mid"
	.balign 4, 0
	.global mid_0808_s_BOMB_Voice_MALE_05
mid_0808_s_BOMB_Voice_MALE_05:
	.incbin "midi/0808_s_BOMB_Voice_MALE_05.mid"
	.balign 4, 0
	.global mid_0809_s_BOMB_Voice_MALE_06
mid_0809_s_BOMB_Voice_MALE_06:
	.incbin "midi/0809_s_BOMB_Voice_MALE_06.mid"
	.balign 4, 0
	.global mid_0810_s_BOMB_Voice_MALE_07
mid_0810_s_BOMB_Voice_MALE_07:
	.incbin "midi/0810_s_BOMB_Voice_MALE_07.mid"
	.balign 4, 0
	.global mid_0811_s_BOMB_Voice_MALE_08
mid_0811_s_BOMB_Voice_MALE_08:
	.incbin "midi/0811_s_BOMB_Voice_MALE_08.mid"
	.balign 4, 0
	.global mid_0812_s_BOMB_Voice_MALE_09
mid_0812_s_BOMB_Voice_MALE_09:
	.incbin "midi/0812_s_BOMB_Voice_MALE_09.mid"
	.balign 4, 0
	.global mid_0813_s_BOMB_Voice_MALE_10
mid_0813_s_BOMB_Voice_MALE_10:
	.incbin "midi/0813_s_BOMB_Voice_MALE_10.mid"
	.balign 4, 0
	.global mid_0814_s_BOMB_Voice_MALE_11
mid_0814_s_BOMB_Voice_MALE_11:
	.incbin "midi/0814_s_BOMB_Voice_MALE_11.mid"
	.balign 4, 0
	.global mid_0815_s_BOMB_Voice_MALE_12
mid_0815_s_BOMB_Voice_MALE_12:
	.incbin "midi/0815_s_BOMB_Voice_MALE_12.mid"
	.balign 4, 0
	.global mid_0816_s_BOMB_Voice_MALE_13
mid_0816_s_BOMB_Voice_MALE_13:
	.incbin "midi/0816_s_BOMB_Voice_MALE_13.mid"
	.balign 4, 0
	.global mid_0817_s_BOMB_Voice_FEMALE_01
mid_0817_s_BOMB_Voice_FEMALE_01:
	.incbin "midi/0817_s_BOMB_Voice_FEMALE_01.mid"
	.balign 4, 0
	.global mid_0818_s_BOMB_Voice_FEMALE_02
mid_0818_s_BOMB_Voice_FEMALE_02:
	.incbin "midi/0818_s_BOMB_Voice_FEMALE_02.mid"
	.balign 4, 0
	.global mid_0819_s_BOMB_Voice_FEMALE_03
mid_0819_s_BOMB_Voice_FEMALE_03:
	.incbin "midi/0819_s_BOMB_Voice_FEMALE_03.mid"
	.balign 4, 0
	.global mid_0820_s_BOMB_Voice_Child_01
mid_0820_s_BOMB_Voice_Child_01:
	.incbin "midi/0820_s_BOMB_Voice_Child_01.mid"
	.balign 4, 0
	.global mid_0821_s_BOMB_Voice_Child_02
mid_0821_s_BOMB_Voice_Child_02:
	.incbin "midi/0821_s_BOMB_Voice_Child_02.mid"
	.balign 4, 0
	.global mid_0822_s_BOMB_Voice_Child_03
mid_0822_s_BOMB_Voice_Child_03:
	.incbin "midi/0822_s_BOMB_Voice_Child_03.mid"
	.balign 4, 0
	.global mid_0823_s_BOMB_Voice_Sneeze_01
mid_0823_s_BOMB_Voice_Sneeze_01:
	.incbin "midi/0823_s_BOMB_Voice_Sneeze_01.mid"
	.balign 4, 0
	.global mid_0824_s_BOMB_Voice_Sneeze_02
mid_0824_s_BOMB_Voice_Sneeze_02:
	.incbin "midi/0824_s_BOMB_Voice_Sneeze_02.mid"
	.balign 4, 0
	.global mid_0825_s_BOMB_Voice_PON_01
mid_0825_s_BOMB_Voice_PON_01:
	.incbin "midi/0825_s_BOMB_Voice_PON_01.mid"
	.balign 4, 0
	.global mid_0826_s_BOMB_Voice_PON_02
mid_0826_s_BOMB_Voice_PON_02:
	.incbin "midi/0826_s_BOMB_Voice_PON_02.mid"
	.balign 4, 0
	.global mid_0827_s_BOMB_Voice_PON_03
mid_0827_s_BOMB_Voice_PON_03:
	.incbin "midi/0827_s_BOMB_Voice_PON_03.mid"
	.balign 4, 0
	.global mid_0828_s_BOMB_Voice_Frog_01
mid_0828_s_BOMB_Voice_Frog_01:
	.incbin "midi/0828_s_BOMB_Voice_Frog_01.mid"
	.balign 4, 0
	.global mid_0829_s_BOMB_Voice_Cat_01
mid_0829_s_BOMB_Voice_Cat_01:
	.incbin "midi/0829_s_BOMB_Voice_Cat_01.mid"
	.balign 4, 0
	.global mid_0830_s_BOMB_Voice_TakoIka
mid_0830_s_BOMB_Voice_TakoIka:
	.incbin "midi/0830_s_BOMB_Voice_TakoIka.mid"
	.balign 4, 0
	.global mid_0831_s_BOMB_Voice_Funkoro
mid_0831_s_BOMB_Voice_Funkoro:
	.incbin "midi/0831_s_BOMB_Voice_Funkoro.mid"
	.balign 4, 0
	.global mid_0832_s_BOMB_Swing_02
mid_0832_s_BOMB_Swing_02:
	.incbin "midi/0832_s_BOMB_Swing_02.mid"
	.balign 4, 0
	.global mid_0833_s_BOMB_Swing_03
mid_0833_s_BOMB_Swing_03:
	.incbin "midi/0833_s_BOMB_Swing_03.mid"
	.balign 4, 0
	.global mid_0834_s_wario_TURN
mid_0834_s_wario_TURN:
	.incbin "midi/0834_s_wario_TURN.mid"
	.balign 4, 0
	.global mid_0835_s_AFRO_BOMB_Burst
mid_0835_s_AFRO_BOMB_Burst:
	.incbin "midi/0835_s_AFRO_BOMB_Burst.mid"
	.balign 4, 0
	.global mid_0836_s_BOMB_Fit_01
mid_0836_s_BOMB_Fit_01:
	.incbin "midi/0836_s_BOMB_Fit_01.mid"
	.balign 4, 0
	.global mid_0837_s_BOMB_Hit_01
mid_0837_s_BOMB_Hit_01:
	.incbin "midi/0837_s_BOMB_Hit_01.mid"
	.balign 4, 0
	.global mid_0838_s_BOMB_Hit_02
mid_0838_s_BOMB_Hit_02:
	.incbin "midi/0838_s_BOMB_Hit_02.mid"
	.balign 4, 0
	.global mid_0839_s_BOMB_Hit_03
mid_0839_s_BOMB_Hit_03:
	.incbin "midi/0839_s_BOMB_Hit_03.mid"
	.balign 4, 0
	.global mid_0840_s_BOMB_Hit_04
mid_0840_s_BOMB_Hit_04:
	.incbin "midi/0840_s_BOMB_Hit_04.mid"
	.balign 4, 0
	.global mid_0841_s_BOMB_Hit_05
mid_0841_s_BOMB_Hit_05:
	.incbin "midi/0841_s_BOMB_Hit_05.mid"
	.balign 4, 0
	.global mid_0842_s_BOMB_Hit_06
mid_0842_s_BOMB_Hit_06:
	.incbin "midi/0842_s_BOMB_Hit_06.mid"
	.balign 4, 0
	.global mid_0843_s_BOMB_Hit_07
mid_0843_s_BOMB_Hit_07:
	.incbin "midi/0843_s_BOMB_Hit_07.mid"
	.balign 4, 0
	.global mid_0844_s_BOMB_Hit_08
mid_0844_s_BOMB_Hit_08:
	.incbin "midi/0844_s_BOMB_Hit_08.mid"
	.balign 4, 0
	.global mid_0845_s_BOMB_Hit_09
mid_0845_s_BOMB_Hit_09:
	.incbin "midi/0845_s_BOMB_Hit_09.mid"
	.balign 4, 0
	.global mid_0846_s_BOMB_Hit_10
mid_0846_s_BOMB_Hit_10:
	.incbin "midi/0846_s_BOMB_Hit_10.mid"
	.balign 4, 0
	.global mid_0847_s_BOMB_Hit_11
mid_0847_s_BOMB_Hit_11:
	.incbin "midi/0847_s_BOMB_Hit_11.mid"
	.balign 4, 0
	.global mid_0848_s_BOMB_Hit_12
mid_0848_s_BOMB_Hit_12:
	.incbin "midi/0848_s_BOMB_Hit_12.mid"
	.balign 4, 0
	.global mid_0849_s_BOMB_Hit_13
mid_0849_s_BOMB_Hit_13:
	.incbin "midi/0849_s_BOMB_Hit_13.mid"
	.balign 4, 0
	.global mid_0850_s_BOMB_Hit_14
mid_0850_s_BOMB_Hit_14:
	.incbin "midi/0850_s_BOMB_Hit_14.mid"
	.balign 4, 0
	.global mid_0851_s_BOMB_Music_CowBell
mid_0851_s_BOMB_Music_CowBell:
	.incbin "midi/0851_s_BOMB_Music_CowBell.mid"
	.balign 4, 0
	.global mid_0852_s_BOMB_Music_Drum
mid_0852_s_BOMB_Music_Drum:
	.incbin "midi/0852_s_BOMB_Music_Drum.mid"
	.balign 4, 0
	.global mid_0853_s_BOMB_Music_Guitar
mid_0853_s_BOMB_Music_Guitar:
	.incbin "midi/0853_s_BOMB_Music_Guitar.mid"
	.balign 4, 0
	.global mid_0854_s_BOMB_Music_Whistle
mid_0854_s_BOMB_Music_Whistle:
	.incbin "midi/0854_s_BOMB_Music_Whistle.mid"
	.balign 4, 0
	.global mid_0855_s_BOMB_Music_ALL
mid_0855_s_BOMB_Music_ALL:
	.incbin "midi/0855_s_BOMB_Music_ALL.mid"
	.balign 4, 0
	.global mid_0856_s_Drum_BD_1
mid_0856_s_Drum_BD_1:
	.incbin "midi/0856_s_Drum_BD_1.mid"
	.balign 4, 0
	.global mid_0857_s_Drum_SD_1
mid_0857_s_Drum_SD_1:
	.incbin "midi/0857_s_Drum_SD_1.mid"
	.balign 4, 0
	.global mid_0858_s_Drum_SD_Rim_Close
mid_0858_s_Drum_SD_Rim_Close:
	.incbin "midi/0858_s_Drum_SD_Rim_Close.mid"
	.balign 4, 0
	.global mid_0859_s_Drum_SD_Rim_Open
mid_0859_s_Drum_SD_Rim_Open:
	.incbin "midi/0859_s_Drum_SD_Rim_Open.mid"
	.balign 4, 0
	.global mid_0860_s_Drum_SD_Roll
mid_0860_s_Drum_SD_Roll:
	.incbin "midi/0860_s_Drum_SD_Roll.mid"
	.balign 4, 0
	.global mid_0861_s_Drum_Tom_1
mid_0861_s_Drum_Tom_1:
	.incbin "midi/0861_s_Drum_Tom_1.mid"
	.balign 4, 0
	.global mid_0862_s_Drum_Sym_Crash
mid_0862_s_Drum_Sym_Crash:
	.incbin "midi/0862_s_Drum_Sym_Crash.mid"
	.balign 4, 0
	.global mid_0863_s_Drum_Sym_Sprash
mid_0863_s_Drum_Sym_Sprash:
	.incbin "midi/0863_s_Drum_Sym_Sprash.mid"
	.balign 4, 0
	.global mid_0864_s_x_NoSound
mid_0864_s_x_NoSound:
	.incbin "midi/0864_s_x_NoSound.mid"
	.balign 4, 0
	.global mid_0865_m_BGM_BOMB_01
mid_0865_m_BGM_BOMB_01:
	.incbin "midi/0865_m_BGM_BOMB_01.mid"
	.balign 4, 0
	.global mid_0866_m_BGM_BOMB_02
mid_0866_m_BGM_BOMB_02:
	.incbin "midi/0866_m_BGM_BOMB_02.mid"
	.balign 4, 0
	.global mid_0867_m_BGM_BOMB_03
mid_0867_m_BGM_BOMB_03:
	.incbin "midi/0867_m_BGM_BOMB_03.mid"
	.balign 4, 0
	.global mid_0868_m_BGM_BOMB_04
mid_0868_m_BGM_BOMB_04:
	.incbin "midi/0868_m_BGM_BOMB_04.mid"
	.balign 4, 0
	.global mid_0869_m_BGM_BOMB_05
mid_0869_m_BGM_BOMB_05:
	.incbin "midi/0869_m_BGM_BOMB_05.mid"
	.balign 4, 0
	.global mid_0870_m_BGM_BOMB_06
mid_0870_m_BGM_BOMB_06:
	.incbin "midi/0870_m_BGM_BOMB_06.mid"
	.balign 4, 0
	.global mid_0871_m_BGM_BOMB_07
mid_0871_m_BGM_BOMB_07:
	.incbin "midi/0871_m_BGM_BOMB_07.mid"
	.balign 4, 0
	.global mid_0872_m_BGM_BOMB_08
mid_0872_m_BGM_BOMB_08:
	.incbin "midi/0872_m_BGM_BOMB_08.mid"
	.balign 4, 0
	.global mid_0873_m_BGM_BOMB_09
mid_0873_m_BGM_BOMB_09:
	.incbin "midi/0873_m_BGM_BOMB_09.mid"
	.balign 4, 0
	.global mid_0874_m_BGM_BOMB_10
mid_0874_m_BGM_BOMB_10:
	.incbin "midi/0874_m_BGM_BOMB_10.mid"
	.balign 4, 0
	.global mid_0875_m_BGM_BOMB_11
mid_0875_m_BGM_BOMB_11:
	.incbin "midi/0875_m_BGM_BOMB_11.mid"
	.balign 4, 0
	.global mid_0876_m_BGM_BOMB_12
mid_0876_m_BGM_BOMB_12:
	.incbin "midi/0876_m_BGM_BOMB_12.mid"
	.balign 4, 0
	.global mid_0877_m_BGM_BOMB_13
mid_0877_m_BGM_BOMB_13:
	.incbin "midi/0877_m_BGM_BOMB_13.mid"
	.balign 4, 0
	.global mid_0878_m_BGM_BOMB_14
mid_0878_m_BGM_BOMB_14:
	.incbin "midi/0878_m_BGM_BOMB_14.mid"
	.balign 4, 0
	.global mid_0879_m_BGM_BOMB_15
mid_0879_m_BGM_BOMB_15:
	.incbin "midi/0879_m_BGM_BOMB_15.mid"
	.balign 4, 0
	.global mid_0880_m_BGM_BOMB_16
mid_0880_m_BGM_BOMB_16:
	.incbin "midi/0880_m_BGM_BOMB_16.mid"
	.balign 4, 0
	.global mid_0881_m_BGM_BOMB_17
mid_0881_m_BGM_BOMB_17:
	.incbin "midi/0881_m_BGM_BOMB_17.mid"
	.balign 4, 0
	.global mid_0882_m_BGM_BOMB_18
mid_0882_m_BGM_BOMB_18:
	.incbin "midi/0882_m_BGM_BOMB_18.mid"
	.balign 4, 0
	.global mid_0883_m_BGM_BOMB_19
mid_0883_m_BGM_BOMB_19:
	.incbin "midi/0883_m_BGM_BOMB_19.mid"
	.balign 4, 0
	.global mid_0884_m_BGM_BOMB_20
mid_0884_m_BGM_BOMB_20:
	.incbin "midi/0884_m_BGM_BOMB_20.mid"
	.balign 4, 0
	.global mid_0885_m_BGM_BOMB_21
mid_0885_m_BGM_BOMB_21:
	.incbin "midi/0885_m_BGM_BOMB_21.mid"
	.balign 4, 0
	.global mid_0886_m_BGM_BOMB_22
mid_0886_m_BGM_BOMB_22:
	.incbin "midi/0886_m_BGM_BOMB_22.mid"
	.balign 4, 0
	.global mid_0887_m_BGM_BOMB_23
mid_0887_m_BGM_BOMB_23:
	.incbin "midi/0887_m_BGM_BOMB_23.mid"
	.balign 4, 0
	.global mid_0888_m_BGM_BOMB_24
mid_0888_m_BGM_BOMB_24:
	.incbin "midi/0888_m_BGM_BOMB_24.mid"
	.balign 4, 0
	.global mid_0889_m_BGM_BOMB_25
mid_0889_m_BGM_BOMB_25:
	.incbin "midi/0889_m_BGM_BOMB_25.mid"
	.balign 4, 0
	.global mid_0890_m_BGM_BOMB_26
mid_0890_m_BGM_BOMB_26:
	.incbin "midi/0890_m_BGM_BOMB_26.mid"
	.balign 4, 0
	.global mid_0891_m_BGM_BOMB_27_Zelda1
mid_0891_m_BGM_BOMB_27_Zelda1:
	.incbin "midi/0891_m_BGM_BOMB_27_Zelda1.mid"
	.balign 4, 0
	.global mid_0892_m_BGM_BOMB_28_DrMario
mid_0892_m_BGM_BOMB_28_DrMario:
	.incbin "midi/0892_m_BGM_BOMB_28_DrMario.mid"
	.balign 4, 0
	.global mid_0893_m_BGM_BOMB_29_Donkey
mid_0893_m_BGM_BOMB_29_Donkey:
	.incbin "midi/0893_m_BGM_BOMB_29_Donkey.mid"
	.balign 4, 0
	.global mid_0894_m_BGM_BOMB_30_MPaint
mid_0894_m_BGM_BOMB_30_MPaint:
	.incbin "midi/0894_m_BGM_BOMB_30_MPaint.mid"
	.balign 4, 0
	.global mid_0895_m_BGM_BOMB_31_Mario
mid_0895_m_BGM_BOMB_31_Mario:
	.incbin "midi/0895_m_BGM_BOMB_31_Mario.mid"
	.balign 4, 0
	.global mid_0896_m_BGM_BOMB_32_Wario_01
mid_0896_m_BGM_BOMB_32_Wario_01:
	.incbin "midi/0896_m_BGM_BOMB_32_Wario_01.mid"
	.balign 4, 0
	.global mid_0897_m_BGM_BOMB_33_Wario_02
mid_0897_m_BGM_BOMB_33_Wario_02:
	.incbin "midi/0897_m_BGM_BOMB_33_Wario_02.mid"
	.balign 4, 0
	.global mid_0898_m_BGM_BOMB_34_Wario_03
mid_0898_m_BGM_BOMB_34_Wario_03:
	.incbin "midi/0898_m_BGM_BOMB_34_Wario_03.mid"
	.balign 4, 0
	.global mid_0899_m_BGM_BOMB_35_0_1
mid_0899_m_BGM_BOMB_35_0_1:
	.incbin "midi/0899_m_BGM_BOMB_35_0_1.mid"
	.balign 4, 0
	.global mid_0900_m_BGM_BOMB_35_0_2
mid_0900_m_BGM_BOMB_35_0_2:
	.incbin "midi/0900_m_BGM_BOMB_35_0_2.mid"
	.balign 4, 0
	.global mid_0901_m_BGM_BOMB_35_1
mid_0901_m_BGM_BOMB_35_1:
	.incbin "midi/0901_m_BGM_BOMB_35_1.mid"
	.balign 4, 0
	.global mid_0902_m_BGM_BOMB_35_2
mid_0902_m_BGM_BOMB_35_2:
	.incbin "midi/0902_m_BGM_BOMB_35_2.mid"
	.balign 4, 0
	.global mid_0903_m_BGM_BOMB_36
mid_0903_m_BGM_BOMB_36:
	.incbin "midi/0903_m_BGM_BOMB_36.mid"
	.balign 4, 0
	.global mid_0904_m_BGM_BOMB_37
mid_0904_m_BGM_BOMB_37:
	.incbin "midi/0904_m_BGM_BOMB_37.mid"
	.balign 4, 0
	.global mid_0905_m_BGM_BOMB_38
mid_0905_m_BGM_BOMB_38:
	.incbin "midi/0905_m_BGM_BOMB_38.mid"
	.balign 4, 0
	.global mid_0906_m_BGM_BOMB_39
mid_0906_m_BGM_BOMB_39:
	.incbin "midi/0906_m_BGM_BOMB_39.mid"
	.balign 4, 0
	.global mid_0907_m_BGM_BOMB_40
mid_0907_m_BGM_BOMB_40:
	.incbin "midi/0907_m_BGM_BOMB_40.mid"
	.balign 4, 0
	.global mid_0908_m_BGM_BOMB_41
mid_0908_m_BGM_BOMB_41:
	.incbin "midi/0908_m_BGM_BOMB_41.mid"
	.balign 4, 0
	.global mid_0909_m_BGM_BOMB_42
mid_0909_m_BGM_BOMB_42:
	.incbin "midi/0909_m_BGM_BOMB_42.mid"
	.balign 4, 0
	.global mid_0910_m_BGM_BOMB_43
mid_0910_m_BGM_BOMB_43:
	.incbin "midi/0910_m_BGM_BOMB_43.mid"
	.balign 4, 0
	.global mid_0911_m_BGM_BOMB_44
mid_0911_m_BGM_BOMB_44:
	.incbin "midi/0911_m_BGM_BOMB_44.mid"
	.balign 4, 0
	.global mid_0912_m_BGM_BOMB_45
mid_0912_m_BGM_BOMB_45:
	.incbin "midi/0912_m_BGM_BOMB_45.mid"
	.balign 4, 0
	.global mid_0913_m_BGM_BOMB_46
mid_0913_m_BGM_BOMB_46:
	.incbin "midi/0913_m_BGM_BOMB_46.mid"
	.balign 4, 0
	.global mid_0914_m_BGM_BOMB_47
mid_0914_m_BGM_BOMB_47:
	.incbin "midi/0914_m_BGM_BOMB_47.mid"
	.balign 4, 0
	.global mid_0915_m_BGM_BOMB_48
mid_0915_m_BGM_BOMB_48:
	.incbin "midi/0915_m_BGM_BOMB_48.mid"
	.balign 4, 0
	.global mid_0916_m_BGM_BOMB_50
mid_0916_m_BGM_BOMB_50:
	.incbin "midi/0916_m_BGM_BOMB_50.mid"
	.balign 4, 0
	.global mid_0917_m_BGM_BOMB_51
mid_0917_m_BGM_BOMB_51:
	.incbin "midi/0917_m_BGM_BOMB_51.mid"
	.balign 4, 0
	.global mid_0918_m_BGM_BOMB_52
mid_0918_m_BGM_BOMB_52:
	.incbin "midi/0918_m_BGM_BOMB_52.mid"
	.balign 4, 0
	.global mid_0919_m_BGM_BOMB_53
mid_0919_m_BGM_BOMB_53:
	.incbin "midi/0919_m_BGM_BOMB_53.mid"
	.balign 4, 0
	.global mid_0920_m_BGM_BOMB_54
mid_0920_m_BGM_BOMB_54:
	.incbin "midi/0920_m_BGM_BOMB_54.mid"
	.balign 4, 0
	.global mid_0921_m_BGM_BOMB_55
mid_0921_m_BGM_BOMB_55:
	.incbin "midi/0921_m_BGM_BOMB_55.mid"
	.balign 4, 0
	.global mid_0922_m_BGM_BOMB_56
mid_0922_m_BGM_BOMB_56:
	.incbin "midi/0922_m_BGM_BOMB_56.mid"
	.balign 4, 0
	.global mid_0923_m_BGM_BOMB_57
mid_0923_m_BGM_BOMB_57:
	.incbin "midi/0923_m_BGM_BOMB_57.mid"
	.balign 4, 0
	.global mid_0924_m_BGM_BOMB_58
mid_0924_m_BGM_BOMB_58:
	.incbin "midi/0924_m_BGM_BOMB_58.mid"
	.balign 4, 0
	.global mid_0925_m_BGM_BOMB_59
mid_0925_m_BGM_BOMB_59:
	.incbin "midi/0925_m_BGM_BOMB_59.mid"
	.balign 4, 0
	.global mid_0926_m_BGM_BOMB_60
mid_0926_m_BGM_BOMB_60:
	.incbin "midi/0926_m_BGM_BOMB_60.mid"
	.balign 4, 0
	.global mid_0927_m_BGM_BOMB_61
mid_0927_m_BGM_BOMB_61:
	.incbin "midi/0927_m_BGM_BOMB_61.mid"
	.balign 4, 0
	.global mid_0928_m_BGM_BOMB_62
mid_0928_m_BGM_BOMB_62:
	.incbin "midi/0928_m_BGM_BOMB_62.mid"
	.balign 4, 0
	.global mid_0929_m_BGM_BOMB_63
mid_0929_m_BGM_BOMB_63:
	.incbin "midi/0929_m_BGM_BOMB_63.mid"
	.balign 4, 0
	.global mid_0930_m_BGM_BOMB_64
mid_0930_m_BGM_BOMB_64:
	.incbin "midi/0930_m_BGM_BOMB_64.mid"
	.balign 4, 0
	.global mid_0931_m_BGM_BOMB_65
mid_0931_m_BGM_BOMB_65:
	.incbin "midi/0931_m_BGM_BOMB_65.mid"
	.balign 4, 0
	.global mid_0932_m_BGM_BOMB_66
mid_0932_m_BGM_BOMB_66:
	.incbin "midi/0932_m_BGM_BOMB_66.mid"
	.balign 4, 0
	.global mid_0933_m_BGM_BOMB_67
mid_0933_m_BGM_BOMB_67:
	.incbin "midi/0933_m_BGM_BOMB_67.mid"
	.balign 4, 0
	.global mid_0934_m_BGM_BOMB_68
mid_0934_m_BGM_BOMB_68:
	.incbin "midi/0934_m_BGM_BOMB_68.mid"
	.balign 4, 0
	.global mid_0935_m_BGM_BOMB_69
mid_0935_m_BGM_BOMB_69:
	.incbin "midi/0935_m_BGM_BOMB_69.mid"
	.balign 4, 0
	.global mid_0936_m_BGM_BOMB_70
mid_0936_m_BGM_BOMB_70:
	.incbin "midi/0936_m_BGM_BOMB_70.mid"
	.balign 4, 0
	.global mid_0937_m_BGM_BOMB_71
mid_0937_m_BGM_BOMB_71:
	.incbin "midi/0937_m_BGM_BOMB_71.mid"
	.balign 4, 0
	.global mid_0938_m_BGM_BOMB_72
mid_0938_m_BGM_BOMB_72:
	.incbin "midi/0938_m_BGM_BOMB_72.mid"
	.balign 4, 0
	.global mid_0939_m_BGM_BOMB_73
mid_0939_m_BGM_BOMB_73:
	.incbin "midi/0939_m_BGM_BOMB_73.mid"
	.balign 4, 0
	.global mid_0940_m_BGM_BOMB_74
mid_0940_m_BGM_BOMB_74:
	.incbin "midi/0940_m_BGM_BOMB_74.mid"
	.balign 4, 0
	.global mid_0941_m_BGM_BOMB_75
mid_0941_m_BGM_BOMB_75:
	.incbin "midi/0941_m_BGM_BOMB_75.mid"
	.balign 4, 0
	.global mid_0942_m_BGM_BOMB_76
mid_0942_m_BGM_BOMB_76:
	.incbin "midi/0942_m_BGM_BOMB_76.mid"
	.balign 4, 0
	.global mid_0943_m_BGM_BOMB_77
mid_0943_m_BGM_BOMB_77:
	.incbin "midi/0943_m_BGM_BOMB_77.mid"
	.balign 4, 0
	.global mid_0944_m_BGM_BOMB_78
mid_0944_m_BGM_BOMB_78:
	.incbin "midi/0944_m_BGM_BOMB_78.mid"
	.balign 4, 0
	.global mid_0945_m_BGM_BOMB_79
mid_0945_m_BGM_BOMB_79:
	.incbin "midi/0945_m_BGM_BOMB_79.mid"
	.balign 4, 0
	.global mid_0946_m_BGM_BOMB_80
mid_0946_m_BGM_BOMB_80:
	.incbin "midi/0946_m_BGM_BOMB_80.mid"
	.balign 4, 0
	.global mid_0947_m_BGM_BOMB_81
mid_0947_m_BGM_BOMB_81:
	.incbin "midi/0947_m_BGM_BOMB_81.mid"
	.balign 4, 0
	.global mid_0948_m_BGM_BOMB_82
mid_0948_m_BGM_BOMB_82:
	.incbin "midi/0948_m_BGM_BOMB_82.mid"
	.balign 4, 0
	.global mid_0949_m_BGM_BOMB_83
mid_0949_m_BGM_BOMB_83:
	.incbin "midi/0949_m_BGM_BOMB_83.mid"
	.balign 4, 0
	.global mid_0950_m_BGM_BOMB_84
mid_0950_m_BGM_BOMB_84:
	.incbin "midi/0950_m_BGM_BOMB_84.mid"
	.balign 4, 0
	.global mid_0951_m_BGM_BOMB_85
mid_0951_m_BGM_BOMB_85:
	.incbin "midi/0951_m_BGM_BOMB_85.mid"
	.balign 4, 0
	.global mid_0952_m_BGM_BOMB_86
mid_0952_m_BGM_BOMB_86:
	.incbin "midi/0952_m_BGM_BOMB_86.mid"
	.balign 4, 0
	.global mid_0953_m_BGM_BOMB_87
mid_0953_m_BGM_BOMB_87:
	.incbin "midi/0953_m_BGM_BOMB_87.mid"
	.balign 4, 0
	.global mid_0954_m_BGM_BOMB_88
mid_0954_m_BGM_BOMB_88:
	.incbin "midi/0954_m_BGM_BOMB_88.mid"
	.balign 4, 0
	.global mid_0955_m_BGM_BOMB_89
mid_0955_m_BGM_BOMB_89:
	.incbin "midi/0955_m_BGM_BOMB_89.mid"
	.balign 4, 0
	.global mid_0956_m_BGM_BOMB_90
mid_0956_m_BGM_BOMB_90:
	.incbin "midi/0956_m_BGM_BOMB_90.mid"
	.balign 4, 0
	.global mid_0957_m_BGM_BOMB_91
mid_0957_m_BGM_BOMB_91:
	.incbin "midi/0957_m_BGM_BOMB_91.mid"
	.balign 4, 0
	.global mid_0958_m_BGM_BOMB_92
mid_0958_m_BGM_BOMB_92:
	.incbin "midi/0958_m_BGM_BOMB_92.mid"
	.balign 4, 0
	.global mid_0959_m_BGM_BOMB_93
mid_0959_m_BGM_BOMB_93:
	.incbin "midi/0959_m_BGM_BOMB_93.mid"
	.balign 4, 0
	.global mid_0960_m_BGM_BOMB_94
mid_0960_m_BGM_BOMB_94:
	.incbin "midi/0960_m_BGM_BOMB_94.mid"
	.balign 4, 0
	.global mid_0961_m_BGM_BOMB_95
mid_0961_m_BGM_BOMB_95:
	.incbin "midi/0961_m_BGM_BOMB_95.mid"
	.balign 4, 0
	.global mid_0962_m_BGM_BOMB_96
mid_0962_m_BGM_BOMB_96:
	.incbin "midi/0962_m_BGM_BOMB_96.mid"
	.balign 4, 0
	.global mid_0963_m_BGM_BOMB_97
mid_0963_m_BGM_BOMB_97:
	.incbin "midi/0963_m_BGM_BOMB_97.mid"
	.balign 4, 0
	.global mid_0964_m_BGM_BOMB_98
mid_0964_m_BGM_BOMB_98:
	.incbin "midi/0964_m_BGM_BOMB_98.mid"
	.balign 4, 0
	.global mid_0965_m_BGM_BOMB_99
mid_0965_m_BGM_BOMB_99:
	.incbin "midi/0965_m_BGM_BOMB_99.mid"
	.balign 4, 0
	.global mid_0966_m_BGM_BOMB_100
mid_0966_m_BGM_BOMB_100:
	.incbin "midi/0966_m_BGM_BOMB_100.mid"
	.balign 4, 0
	.global mid_0967_m_BGM_BOMB_101
mid_0967_m_BGM_BOMB_101:
	.incbin "midi/0967_m_BGM_BOMB_101.mid"
	.balign 4, 0
	.global mid_0968_m_BGM_BOMB_102
mid_0968_m_BGM_BOMB_102:
	.incbin "midi/0968_m_BGM_BOMB_102.mid"
	.balign 4, 0
	.global mid_0969_m_BGM_BOMB_103
mid_0969_m_BGM_BOMB_103:
	.incbin "midi/0969_m_BGM_BOMB_103.mid"
	.balign 4, 0
	.global mid_0970_m_BGM_BOMB_Finish_1
mid_0970_m_BGM_BOMB_Finish_1:
	.incbin "midi/0970_m_BGM_BOMB_Finish_1.mid"
	.balign 4, 0
	.global mid_0971_m_BGM_BOMB_Finish_2
mid_0971_m_BGM_BOMB_Finish_2:
	.incbin "midi/0971_m_BGM_BOMB_Finish_2.mid"
	.balign 4, 0
	.global mid_0972_m_BGM_BOMB_REST_1
mid_0972_m_BGM_BOMB_REST_1:
	.incbin "midi/0972_m_BGM_BOMB_REST_1.mid"
	.balign 4, 0
	.global mid_0973_m_BGM_BOMB_Demo_11
mid_0973_m_BGM_BOMB_Demo_11:
	.incbin "midi/0973_m_BGM_BOMB_Demo_11.mid"
	.balign 4, 0
	.global mid_0974_m_BGM_BOMB_Demo_2
mid_0974_m_BGM_BOMB_Demo_2:
	.incbin "midi/0974_m_BGM_BOMB_Demo_2.mid"
	.balign 4, 0
	.global mid_0975_m_BGM_BOSS_FF_Clear_1
mid_0975_m_BGM_BOSS_FF_Clear_1:
	.incbin "midi/0975_m_BGM_BOSS_FF_Clear_1.mid"
	.balign 4, 0
	.global mid_0976_m_BGM_BOSS_FF_Lose_1
mid_0976_m_BGM_BOSS_FF_Lose_1:
	.incbin "midi/0976_m_BGM_BOSS_FF_Lose_1.mid"
	.balign 4, 0
	.global mid_0977_m_BGM_PIG_END_01
mid_0977_m_BGM_PIG_END_01:
	.incbin "midi/0977_m_BGM_PIG_END_01.mid"
	.balign 4, 0
	.global mid_0978_m_BGM_BOMB_READY_Turn_1
mid_0978_m_BGM_BOMB_READY_Turn_1:
	.incbin "midi/0978_m_BGM_BOMB_READY_Turn_1.mid"
	.balign 4, 0
	.global mid_0979_m_BGM_BOMB_GOOD_0
mid_0979_m_BGM_BOMB_GOOD_0:
	.incbin "midi/0979_m_BGM_BOMB_GOOD_0.mid"
	.balign 4, 0
	.global mid_0980_m_BGM_BOMB_BAD_0
mid_0980_m_BGM_BOMB_BAD_0:
	.incbin "midi/0980_m_BGM_BOMB_BAD_0.mid"
	.balign 4, 0
	.global mid_0981_m_BGM_ROPE_Select
mid_0981_m_BGM_ROPE_Select:
	.incbin "midi/0981_m_BGM_ROPE_Select.mid"
	.balign 4, 0
	.global mid_0982_m_BGM_ROPE_BGM_A00
mid_0982_m_BGM_ROPE_BGM_A00:
	.incbin "midi/0982_m_BGM_ROPE_BGM_A00.mid"
	.balign 4, 0
	.global mid_0983_m_BGM_ROPE_BGM_A01
mid_0983_m_BGM_ROPE_BGM_A01:
	.incbin "midi/0983_m_BGM_ROPE_BGM_A01.mid"
	.balign 4, 0
	.global mid_0984_m_BGM_ROPE_BGM_A02
mid_0984_m_BGM_ROPE_BGM_A02:
	.incbin "midi/0984_m_BGM_ROPE_BGM_A02.mid"
	.balign 4, 0
	.global mid_0985_m_BGM_ROPE_BGM_00
mid_0985_m_BGM_ROPE_BGM_00:
	.incbin "midi/0985_m_BGM_ROPE_BGM_00.mid"
	.balign 4, 0
	.global mid_0986_m_BGM_ROPE_BGM_01
mid_0986_m_BGM_ROPE_BGM_01:
	.incbin "midi/0986_m_BGM_ROPE_BGM_01.mid"
	.balign 4, 0
	.global mid_0987_m_BGM_ROPE_BGM_02
mid_0987_m_BGM_ROPE_BGM_02:
	.incbin "midi/0987_m_BGM_ROPE_BGM_02.mid"
	.balign 4, 0
	.global mid_0988_m_BGM_ROPE_BGM_03
mid_0988_m_BGM_ROPE_BGM_03:
	.incbin "midi/0988_m_BGM_ROPE_BGM_03.mid"
	.balign 4, 0
	.global mid_0989_m_BGM_ROPE_BGM_04
mid_0989_m_BGM_ROPE_BGM_04:
	.incbin "midi/0989_m_BGM_ROPE_BGM_04.mid"
	.balign 4, 0
	.global mid_0990_m_BGM_ROPE_BGM_KAEDE_IN
mid_0990_m_BGM_ROPE_BGM_KAEDE_IN:
	.incbin "midi/0990_m_BGM_ROPE_BGM_KAEDE_IN.mid"
	.balign 4, 0
	.global mid_0991_m_BGM_ROPE_BGM_KAEDE_1A
mid_0991_m_BGM_ROPE_BGM_KAEDE_1A:
	.incbin "midi/0991_m_BGM_ROPE_BGM_KAEDE_1A.mid"
	.balign 4, 0
	.global mid_0992_m_BGM_ROPE_BGM_KAEDE_1B
mid_0992_m_BGM_ROPE_BGM_KAEDE_1B:
	.incbin "midi/0992_m_BGM_ROPE_BGM_KAEDE_1B.mid"
	.balign 4, 0
	.global mid_0993_m_BGM_ROPE_BGM_KAEDE_2A
mid_0993_m_BGM_ROPE_BGM_KAEDE_2A:
	.incbin "midi/0993_m_BGM_ROPE_BGM_KAEDE_2A.mid"
	.balign 4, 0
	.global mid_0994_m_BGM_ROPE_BGM_KAEDE_2B
mid_0994_m_BGM_ROPE_BGM_KAEDE_2B:
	.incbin "midi/0994_m_BGM_ROPE_BGM_KAEDE_2B.mid"
	.balign 4, 0
	.global mid_0995_m_BGM_DraBuru_ALL
mid_0995_m_BGM_DraBuru_ALL:
	.incbin "midi/0995_m_BGM_DraBuru_ALL.mid"
	.balign 4, 0
	.global mid_0996_m_BGM_KAEDE_ALL
mid_0996_m_BGM_KAEDE_ALL:
	.incbin "midi/0996_m_BGM_KAEDE_ALL.mid"
	.balign 4, 0
	.global mid_0997_m_BGM_Loo_ALL
mid_0997_m_BGM_Loo_ALL:
	.incbin "midi/0997_m_BGM_Loo_ALL.mid"
	.balign 4, 0
	.global mid_0998_m_BGM_Plane_BGM_01
mid_0998_m_BGM_Plane_BGM_01:
	.incbin "midi/0998_m_BGM_Plane_BGM_01.mid"
	.balign 4, 0
	.global mid_0999_m_BGM_SkateBoard_BGM_01
mid_0999_m_BGM_SkateBoard_BGM_01:
	.incbin "midi/0999_m_BGM_SkateBoard_BGM_01.mid"
	.balign 4, 0
	.global mid_1000_m_BGM_SkateBoard_FF_NG
mid_1000_m_BGM_SkateBoard_FF_NG:
	.incbin "midi/1000_m_BGM_SkateBoard_FF_NG.mid"
	.balign 4, 0
	.global mid_1001_m_BGM_VS_Title_10
mid_1001_m_BGM_VS_Title_10:
	.incbin "midi/1001_m_BGM_VS_Title_10.mid"
	.balign 4, 0
	.global mid_1002_m_BGM_VS_Chiritori2_10
mid_1002_m_BGM_VS_Chiritori2_10:
	.incbin "midi/1002_m_BGM_VS_Chiritori2_10.mid"
	.balign 4, 0
	.global mid_1003_m_BGM_VS_ChoroQ_10
mid_1003_m_BGM_VS_ChoroQ_10:
	.incbin "midi/1003_m_BGM_VS_ChoroQ_10.mid"
	.balign 4, 0
	.global mid_1004_m_BGM_VS_ChoroQ_12
mid_1004_m_BGM_VS_ChoroQ_12:
	.incbin "midi/1004_m_BGM_VS_ChoroQ_12.mid"
	.balign 4, 0
	.global mid_1005_m_BGM_VS_Hurdle_10
mid_1005_m_BGM_VS_Hurdle_10:
	.incbin "midi/1005_m_BGM_VS_Hurdle_10.mid"
	.balign 4, 0
	.global mid_1006_m_BGM_VS_PON2_10
mid_1006_m_BGM_VS_PON2_10:
	.incbin "midi/1006_m_BGM_VS_PON2_10.mid"
	.balign 4, 0
	.global mid_1007_m_BGM_VS_RoboControl_10
mid_1007_m_BGM_VS_RoboControl_10:
	.incbin "midi/1007_m_BGM_VS_RoboControl_10.mid"
	.balign 4, 0
	.global mid_1008_m_BGM_FF_Victory
mid_1008_m_BGM_FF_Victory:
	.incbin "midi/1008_m_BGM_FF_Victory.mid"
	.balign 4, 0
	.global mid_1009_s_REST_SFX_01
mid_1009_s_REST_SFX_01:
	.incbin "midi/1009_s_REST_SFX_01.mid"
	.balign 4, 0
	.global mid_1010_s_REST_SFX_02
mid_1010_s_REST_SFX_02:
	.incbin "midi/1010_s_REST_SFX_02.mid"
	.balign 4, 0
	.global mid_1011_s_REST_SFX_03
mid_1011_s_REST_SFX_03:
	.incbin "midi/1011_s_REST_SFX_03.mid"
	.balign 4, 0
	.global mid_1012_s_Demo_AFRO_melo_B1
mid_1012_s_Demo_AFRO_melo_B1:
	.incbin "midi/1012_s_Demo_AFRO_melo_B1.mid"
	.balign 4, 0
	.global mid_1013_s_Demo_AFRO_melo_C1
mid_1013_s_Demo_AFRO_melo_C1:
	.incbin "midi/1013_s_Demo_AFRO_melo_C1.mid"
	.balign 4, 0
	.global mid_1014_s_Demo_AFRO_melo_D1
mid_1014_s_Demo_AFRO_melo_D1:
	.incbin "midi/1014_s_Demo_AFRO_melo_D1.mid"
	.balign 4, 0
	.global mid_1015_s_BOMB_Ele_07
mid_1015_s_BOMB_Ele_07:
	.incbin "midi/1015_s_BOMB_Ele_07.mid"
	.balign 4, 0
	.global mid_1016_s_BOMB_Ele_08
mid_1016_s_BOMB_Ele_08:
	.incbin "midi/1016_s_BOMB_Ele_08.mid"
	.balign 4, 0
	.global mid_1017_s_BOMB_Ele_09
mid_1017_s_BOMB_Ele_09:
	.incbin "midi/1017_s_BOMB_Ele_09.mid"
	.balign 4, 0
	.global mid_1018_s_BOMB_Ele_10
mid_1018_s_BOMB_Ele_10:
	.incbin "midi/1018_s_BOMB_Ele_10.mid"
	.balign 4, 0
	.global mid_1019_s_VS_Hurdle_Hit_1
mid_1019_s_VS_Hurdle_Hit_1:
	.incbin "midi/1019_s_VS_Hurdle_Hit_1.mid"
	.balign 4, 0
	.global mid_1020_s_VS_Hurdle_Hit_2
mid_1020_s_VS_Hurdle_Hit_2:
	.incbin "midi/1020_s_VS_Hurdle_Hit_2.mid"
	.balign 4, 0
	.global mid_1021_s_VS_Hurdle_Jump_1
mid_1021_s_VS_Hurdle_Jump_1:
	.incbin "midi/1021_s_VS_Hurdle_Jump_1.mid"
	.balign 4, 0
	.global mid_1022_s_VS_Hurdle_Jump_2
mid_1022_s_VS_Hurdle_Jump_2:
	.incbin "midi/1022_s_VS_Hurdle_Jump_2.mid"
	.balign 4, 0
	.global mid_1023_s_VS_Chiritori_CRASH_A
mid_1023_s_VS_Chiritori_CRASH_A:
	.incbin "midi/1023_s_VS_Chiritori_CRASH_A.mid"
	.balign 4, 0
	.global mid_1024_s_VS_Chiritori_CRASH_B
mid_1024_s_VS_Chiritori_CRASH_B:
	.incbin "midi/1024_s_VS_Chiritori_CRASH_B.mid"
	.balign 4, 0
	.global mid_1025_s_VS_PON_Count_1
mid_1025_s_VS_PON_Count_1:
	.incbin "midi/1025_s_VS_PON_Count_1.mid"
	.balign 4, 0
	.global mid_1026_s_VS_PON_Count_2
mid_1026_s_VS_PON_Count_2:
	.incbin "midi/1026_s_VS_PON_Count_2.mid"
	.balign 4, 0
	.global mid_1027_s_VS_PON_Wall_1
mid_1027_s_VS_PON_Wall_1:
	.incbin "midi/1027_s_VS_PON_Wall_1.mid"
	.balign 4, 0
	.global mid_1028_s_VS_PON_STAR_1
mid_1028_s_VS_PON_STAR_1:
	.incbin "midi/1028_s_VS_PON_STAR_1.mid"
	.balign 4, 0
	.global mid_1029_s_VS_PON_STAR_2
mid_1029_s_VS_PON_STAR_2:
	.incbin "midi/1029_s_VS_PON_STAR_2.mid"
	.balign 4, 0
	.global mid_1030_s_VS_PON_Hit_1
mid_1030_s_VS_PON_Hit_1:
	.incbin "midi/1030_s_VS_PON_Hit_1.mid"
	.balign 4, 0
	.global mid_1031_s_VS_PON_Hit_2
mid_1031_s_VS_PON_Hit_2:
	.incbin "midi/1031_s_VS_PON_Hit_2.mid"
	.balign 4, 0
	.global mid_1032_s_VS_PON_Move_1
mid_1032_s_VS_PON_Move_1:
	.incbin "midi/1032_s_VS_PON_Move_1.mid"
	.balign 4, 0
	.global mid_1033_s_VS_PON_Move_2
mid_1033_s_VS_PON_Move_2:
	.incbin "midi/1033_s_VS_PON_Move_2.mid"
	.balign 4, 0
	.global mid_1034_s_VS_PON_Power_1
mid_1034_s_VS_PON_Power_1:
	.incbin "midi/1034_s_VS_PON_Power_1.mid"
	.balign 4, 0
	.global mid_1035_s_VS_PON_Power_2
mid_1035_s_VS_PON_Power_2:
	.incbin "midi/1035_s_VS_PON_Power_2.mid"
	.balign 4, 0
	.global mid_1036_s_VS_PON_Snap_1
mid_1036_s_VS_PON_Snap_1:
	.incbin "midi/1036_s_VS_PON_Snap_1.mid"
	.balign 4, 0
	.global mid_1037_s_VS_PON_Snap_2
mid_1037_s_VS_PON_Snap_2:
	.incbin "midi/1037_s_VS_PON_Snap_2.mid"
	.balign 4, 0
	.global mid_1038_s_VS_ChoroQ_Scroll_1
mid_1038_s_VS_ChoroQ_Scroll_1:
	.incbin "midi/1038_s_VS_ChoroQ_Scroll_1.mid"
	.balign 4, 0
	.global mid_1039_s_VS_ChoroQ_Scroll_2
mid_1039_s_VS_ChoroQ_Scroll_2:
	.incbin "midi/1039_s_VS_ChoroQ_Scroll_2.mid"
	.balign 4, 0
	.global mid_1040_s_VS_ChoroQ_Pull_1
mid_1040_s_VS_ChoroQ_Pull_1:
	.incbin "midi/1040_s_VS_ChoroQ_Pull_1.mid"
	.balign 4, 0
	.global mid_1041_s_VS_ChoroQ_Pull_2
mid_1041_s_VS_ChoroQ_Pull_2:
	.incbin "midi/1041_s_VS_ChoroQ_Pull_2.mid"
	.balign 4, 0
	.global mid_1042_s_VS_ChoroQ_Keep_1
mid_1042_s_VS_ChoroQ_Keep_1:
	.incbin "midi/1042_s_VS_ChoroQ_Keep_1.mid"
	.balign 4, 0
	.global mid_1043_s_VS_ChoroQ_Keep_2
mid_1043_s_VS_ChoroQ_Keep_2:
	.incbin "midi/1043_s_VS_ChoroQ_Keep_2.mid"
	.balign 4, 0
	.global mid_1044_s_VS_ChoroQ_GO_1
mid_1044_s_VS_ChoroQ_GO_1:
	.incbin "midi/1044_s_VS_ChoroQ_GO_1.mid"
	.balign 4, 0
	.global mid_1045_s_VS_ChoroQ_Lean_1
mid_1045_s_VS_ChoroQ_Lean_1:
	.incbin "midi/1045_s_VS_ChoroQ_Lean_1.mid"
	.balign 4, 0
	.global mid_1046_s_BOMB_Draw_01
mid_1046_s_BOMB_Draw_01:
	.incbin "midi/1046_s_BOMB_Draw_01.mid"
	.balign 4, 0
	.global mid_1047_s_VS_Push_UP_01
mid_1047_s_VS_Push_UP_01:
	.incbin "midi/1047_s_VS_Push_UP_01.mid"
	.balign 4, 0
	.global mid_1048_s_VS_Push_DOWN_01
mid_1048_s_VS_Push_DOWN_01:
	.incbin "midi/1048_s_VS_Push_DOWN_01.mid"
	.balign 4, 0
	.global mid_1049_s_VS_Push_BUTTON_01
mid_1049_s_VS_Push_BUTTON_01:
	.incbin "midi/1049_s_VS_Push_BUTTON_01.mid"
	.balign 4, 0
	.global mid_1050_s_VS_Push_BUTTON_02
mid_1050_s_VS_Push_BUTTON_02:
	.incbin "midi/1050_s_VS_Push_BUTTON_02.mid"
	.balign 4, 0
	.global mid_1051_s_VS_Push_HIT_01
mid_1051_s_VS_Push_HIT_01:
	.incbin "midi/1051_s_VS_Push_HIT_01.mid"
	.balign 4, 0
	.global mid_1052_s_VS_PUSH_NG_01
mid_1052_s_VS_PUSH_NG_01:
	.incbin "midi/1052_s_VS_PUSH_NG_01.mid"
	.balign 4, 0
	.global mid_1053_s_VS_PUSH_FALL_01
mid_1053_s_VS_PUSH_FALL_01:
	.incbin "midi/1053_s_VS_PUSH_FALL_01.mid"
	.balign 4, 0
	.global mid_1054_s_VS_PUSH_Bomb_01
mid_1054_s_VS_PUSH_Bomb_01:
	.incbin "midi/1054_s_VS_PUSH_Bomb_01.mid"
	.balign 4, 0
	.global mid_1055_s_Demo_Title_PINPON_1
mid_1055_s_Demo_Title_PINPON_1:
	.incbin "midi/1055_s_Demo_Title_PINPON_1.mid"
	.balign 4, 0
	.global mid_1056_s_Demo_Title_PINPON_2
mid_1056_s_Demo_Title_PINPON_2:
	.incbin "midi/1056_s_Demo_Title_PINPON_2.mid"
	.balign 4, 0
	.global mid_1057_s_Demo_Title_PINPON_3
mid_1057_s_Demo_Title_PINPON_3:
	.incbin "midi/1057_s_Demo_Title_PINPON_3.mid"
	.balign 4, 0
	.global mid_1058_s_Demo_Title_Rotate_1
mid_1058_s_Demo_Title_Rotate_1:
	.incbin "midi/1058_s_Demo_Title_Rotate_1.mid"
	.balign 4, 0
	.global mid_1059_s_Demo_Title_v_Snore_1
mid_1059_s_Demo_Title_v_Snore_1:
	.incbin "midi/1059_s_Demo_Title_v_Snore_1.mid"
	.balign 4, 0
	.global mid_1060_s_Demo_Wario_v_1_Ho
mid_1060_s_Demo_Wario_v_1_Ho:
	.incbin "midi/1060_s_Demo_Wario_v_1_Ho.mid"
	.balign 4, 0
	.global mid_1061_s_Demo_Wario_v_2_Yeah
mid_1061_s_Demo_Wario_v_2_Yeah:
	.incbin "midi/1061_s_Demo_Wario_v_2_Yeah.mid"
	.balign 4, 0
	.global mid_1062_s_Demo_Bio_v_1_HELP
mid_1062_s_Demo_Bio_v_1_HELP:
	.incbin "midi/1062_s_Demo_Bio_v_1_HELP.mid"
	.balign 4, 0
	.global mid_1063_s_Demo_Bio_v_2_KOBUN
mid_1063_s_Demo_Bio_v_2_KOBUN:
	.incbin "midi/1063_s_Demo_Bio_v_2_KOBUN.mid"
	.balign 4, 0
	.global mid_1064_s_Demo_Bio_v_3_YADA
mid_1064_s_Demo_Bio_v_3_YADA:
	.incbin "midi/1064_s_Demo_Bio_v_3_YADA.mid"
	.balign 4, 0
	.global mid_1065_s_Demo_Bio_Siren_1
mid_1065_s_Demo_Bio_Siren_1:
	.incbin "midi/1065_s_Demo_Bio_Siren_1.mid"
	.balign 4, 0
	.global mid_1066_s_Demo_Bio_Switch_1
mid_1066_s_Demo_Bio_Switch_1:
	.incbin "midi/1066_s_Demo_Bio_Switch_1.mid"
	.balign 4, 0
	.global mid_1067_s_Demo_Bio_Down_1
mid_1067_s_Demo_Bio_Down_1:
	.incbin "midi/1067_s_Demo_Bio_Down_1.mid"
	.balign 4, 0
	.global mid_1068_s_Demo_Bio_Fall_1
mid_1068_s_Demo_Bio_Fall_1:
	.incbin "midi/1068_s_Demo_Bio_Fall_1.mid"
	.balign 4, 0
	.global mid_1069_s_Demo_Bio_DON_1
mid_1069_s_Demo_Bio_DON_1:
	.incbin "midi/1069_s_Demo_Bio_DON_1.mid"
	.balign 4, 0
	.global mid_1070_s_Demo_Bio_DON_2
mid_1070_s_Demo_Bio_DON_2:
	.incbin "midi/1070_s_Demo_Bio_DON_2.mid"
	.balign 4, 0
	.global mid_1071_s_Demo_App_v_1_Morning
mid_1071_s_Demo_App_v_1_Morning:
	.incbin "midi/1071_s_Demo_App_v_1_Morning.mid"
	.balign 4, 0
	.global mid_1072_s_Demo_App_v_1_Hello
mid_1072_s_Demo_App_v_1_Hello:
	.incbin "midi/1072_s_Demo_App_v_1_Hello.mid"
	.balign 4, 0
	.global mid_1073_s_Demo_App_v_1_Night
mid_1073_s_Demo_App_v_1_Night:
	.incbin "midi/1073_s_Demo_App_v_1_Night.mid"
	.balign 4, 0
	.global mid_1074_s_Demo_App_v_2_Baby
mid_1074_s_Demo_App_v_2_Baby:
	.incbin "midi/1074_s_Demo_App_v_2_Baby.mid"
	.balign 4, 0
	.global mid_1075_s_Demo_App_v_2_Party
mid_1075_s_Demo_App_v_2_Party:
	.incbin "midi/1075_s_Demo_App_v_2_Party.mid"
	.balign 4, 0
	.global mid_1076_s_Demo_App_v_3_Laugh
mid_1076_s_Demo_App_v_3_Laugh:
	.incbin "midi/1076_s_Demo_App_v_3_Laugh.mid"
	.balign 4, 0
	.global mid_1077_s_Demo_App_v_3_Wow
mid_1077_s_Demo_App_v_3_Wow:
	.incbin "midi/1077_s_Demo_App_v_3_Wow.mid"
	.balign 4, 0
	.global mid_1078_s_Demo_App_v_4_OK
mid_1078_s_Demo_App_v_4_OK:
	.incbin "midi/1078_s_Demo_App_v_4_OK.mid"
	.balign 4, 0
	.global mid_1079_s_Demo_App_v_4_DJ
mid_1079_s_Demo_App_v_4_DJ:
	.incbin "midi/1079_s_Demo_App_v_4_DJ.mid"
	.balign 4, 0
	.global mid_1080_s_Demo_Dra_v_1_Ahh
mid_1080_s_Demo_Dra_v_1_Ahh:
	.incbin "midi/1080_s_Demo_Dra_v_1_Ahh.mid"
	.balign 4, 0
	.global mid_1081_s_Demo_Dra_v_1_Uhn
mid_1081_s_Demo_Dra_v_1_Uhn:
	.incbin "midi/1081_s_Demo_Dra_v_1_Uhn.mid"
	.balign 4, 0
	.global mid_1082_s_Demo_Dra_v_2_Where
mid_1082_s_Demo_Dra_v_2_Where:
	.incbin "midi/1082_s_Demo_Dra_v_2_Where.mid"
	.balign 4, 0
	.global mid_1083_s_Demo_Dra_v_3_Ahh
mid_1083_s_Demo_Dra_v_3_Ahh:
	.incbin "midi/1083_s_Demo_Dra_v_3_Ahh.mid"
	.balign 4, 0
	.global mid_1084_s_Demo_Dra_v_3_Hey
mid_1084_s_Demo_Dra_v_3_Hey:
	.incbin "midi/1084_s_Demo_Dra_v_3_Hey.mid"
	.balign 4, 0
	.global mid_1085_s_Demo_Mon_v_1_Haa
mid_1085_s_Demo_Mon_v_1_Haa:
	.incbin "midi/1085_s_Demo_Mon_v_1_Haa.mid"
	.balign 4, 0
	.global mid_1086_s_Demo_Mon_v_1_Oh
mid_1086_s_Demo_Mon_v_1_Oh:
	.incbin "midi/1086_s_Demo_Mon_v_1_Oh.mid"
	.balign 4, 0
	.global mid_1087_s_Demo_Mon_v_2_Ahh
mid_1087_s_Demo_Mon_v_2_Ahh:
	.incbin "midi/1087_s_Demo_Mon_v_2_Ahh.mid"
	.balign 4, 0
	.global mid_1088_s_Demo_Mon_v_2_Go
mid_1088_s_Demo_Mon_v_2_Go:
	.incbin "midi/1088_s_Demo_Mon_v_2_Go.mid"
	.balign 4, 0
	.global mid_1089_s_Demo_Mon_v_3_Hurry
mid_1089_s_Demo_Mon_v_3_Hurry:
	.incbin "midi/1089_s_Demo_Mon_v_3_Hurry.mid"
	.balign 4, 0
	.global mid_1090_s_Demo_Mon_v_3_Go
mid_1090_s_Demo_Mon_v_3_Go:
	.incbin "midi/1090_s_Demo_Mon_v_3_Go.mid"
	.balign 4, 0
	.global mid_1091_s_Demo_Mon_v_4_Ahn
mid_1091_s_Demo_Mon_v_4_Ahn:
	.incbin "midi/1091_s_Demo_Mon_v_4_Ahn.mid"
	.balign 4, 0
	.global mid_1092_s_Demo_Mon_v_4_Go
mid_1092_s_Demo_Mon_v_4_Go:
	.incbin "midi/1092_s_Demo_Mon_v_4_Go.mid"
	.balign 4, 0
	.global mid_1093_s_Demo_Mon_Switch_1
mid_1093_s_Demo_Mon_Switch_1:
	.incbin "midi/1093_s_Demo_Mon_Switch_1.mid"
	.balign 4, 0
	.global mid_1094_s_Demo_Mon_Switch_2
mid_1094_s_Demo_Mon_Switch_2:
	.incbin "midi/1094_s_Demo_Mon_Switch_2.mid"
	.balign 4, 0
	.global mid_1095_s_Demo_Mon_Switch_3
mid_1095_s_Demo_Mon_Switch_3:
	.incbin "midi/1095_s_Demo_Mon_Switch_3.mid"
	.balign 4, 0
	.global mid_1096_s_Demo_Mon_Shot_1
mid_1096_s_Demo_Mon_Shot_1:
	.incbin "midi/1096_s_Demo_Mon_Shot_1.mid"
	.balign 4, 0
	.global mid_1097_s_Demo_Mon_Shot_2
mid_1097_s_Demo_Mon_Shot_2:
	.incbin "midi/1097_s_Demo_Mon_Shot_2.mid"
	.balign 4, 0
	.global mid_1098_s_Demo_Mon_Shot_3
mid_1098_s_Demo_Mon_Shot_3:
	.incbin "midi/1098_s_Demo_Mon_Shot_3.mid"
	.balign 4, 0
	.global mid_1099_s_Demo_Mon_PATO_Crash
mid_1099_s_Demo_Mon_PATO_Crash:
	.incbin "midi/1099_s_Demo_Mon_PATO_Crash.mid"
	.balign 4, 0
	.global mid_1100_s_Demo_Mon_PATO_Jump
mid_1100_s_Demo_Mon_PATO_Jump:
	.incbin "midi/1100_s_Demo_Mon_PATO_Jump.mid"
	.balign 4, 0
	.global mid_1101_s_Demo_Mon_PATO_1
mid_1101_s_Demo_Mon_PATO_1:
	.incbin "midi/1101_s_Demo_Mon_PATO_1.mid"
	.balign 4, 0
	.global mid_1102_s_Demo_Mon_PATO_2
mid_1102_s_Demo_Mon_PATO_2:
	.incbin "midi/1102_s_Demo_Mon_PATO_2.mid"
	.balign 4, 0
	.global mid_1103_s_Demo_Voya_v_1_Fuu
mid_1103_s_Demo_Voya_v_1_Fuu:
	.incbin "midi/1103_s_Demo_Voya_v_1_Fuu.mid"
	.balign 4, 0
	.global mid_1104_s_Demo_Voya_v_1_Haa
mid_1104_s_Demo_Voya_v_1_Haa:
	.incbin "midi/1104_s_Demo_Voya_v_1_Haa.mid"
	.balign 4, 0
	.global mid_1105_s_Demo_Voya_v_2_9V
mid_1105_s_Demo_Voya_v_2_9V:
	.incbin "midi/1105_s_Demo_Voya_v_2_9V.mid"
	.balign 4, 0
	.global mid_1106_s_Demo_Voya_v_2_Ready
mid_1106_s_Demo_Voya_v_2_Ready:
	.incbin "midi/1106_s_Demo_Voya_v_2_Ready.mid"
	.balign 4, 0
	.global mid_1107_s_Demo_Loo_v_1_Laugh
mid_1107_s_Demo_Loo_v_1_Laugh:
	.incbin "midi/1107_s_Demo_Loo_v_1_Laugh.mid"
	.balign 4, 0
	.global mid_1108_s_Demo_Loo_v_1_OK
mid_1108_s_Demo_Loo_v_1_OK:
	.incbin "midi/1108_s_Demo_Loo_v_1_OK.mid"
	.balign 4, 0
	.global mid_1109_s_Demo_Loo_v_2_HaHa
mid_1109_s_Demo_Loo_v_2_HaHa:
	.incbin "midi/1109_s_Demo_Loo_v_2_HaHa.mid"
	.balign 4, 0
	.global mid_1110_s_Demo_Loo_v_3_GOKU
mid_1110_s_Demo_Loo_v_3_GOKU:
	.incbin "midi/1110_s_Demo_Loo_v_3_GOKU.mid"
	.balign 4, 0
	.global mid_1111_s_Demo_Loo_v_4_Ah
mid_1111_s_Demo_Loo_v_4_Ah:
	.incbin "midi/1111_s_Demo_Loo_v_4_Ah.mid"
	.balign 4, 0
	.global mid_1112_s_Demo_Loo_v_4_Oh
mid_1112_s_Demo_Loo_v_4_Oh:
	.incbin "midi/1112_s_Demo_Loo_v_4_Oh.mid"
	.balign 4, 0
	.global mid_1113_s_Demo_Loo_v_5_Bee
mid_1113_s_Demo_Loo_v_5_Bee:
	.incbin "midi/1113_s_Demo_Loo_v_5_Bee.mid"
	.balign 4, 0
	.global mid_1114_s_Demo_Loo_v_5_Naa
mid_1114_s_Demo_Loo_v_5_Naa:
	.incbin "midi/1114_s_Demo_Loo_v_5_Naa.mid"
	.balign 4, 0
	.global mid_1115_s_v_WARIO_YAHOO_1
mid_1115_s_v_WARIO_YAHOO_1:
	.incbin "midi/1115_s_v_WARIO_YAHOO_1.mid"
	.balign 4, 0
	.global mid_1116_s_v_WARIO_YAHOO_2
mid_1116_s_v_WARIO_YAHOO_2:
	.incbin "midi/1116_s_v_WARIO_YAHOO_2.mid"
	.balign 4, 0
	.global mid_1117_s_v_WARIO_YAHOO_3
mid_1117_s_v_WARIO_YAHOO_3:
	.incbin "midi/1117_s_v_WARIO_YAHOO_3.mid"
	.balign 4, 0
	.global mid_1118_s_v_WARIO_YAHOO_4
mid_1118_s_v_WARIO_YAHOO_4:
	.incbin "midi/1118_s_v_WARIO_YAHOO_4.mid"
	.balign 4, 0
	.global mid_1119_s_v_WARIO_YAHOO_5
mid_1119_s_v_WARIO_YAHOO_5:
	.incbin "midi/1119_s_v_WARIO_YAHOO_5.mid"
	.balign 4, 0
	.global mid_1120_s_v_WARIO_EXCELLENT_1
mid_1120_s_v_WARIO_EXCELLENT_1:
	.incbin "midi/1120_s_v_WARIO_EXCELLENT_1.mid"
	.balign 4, 0
	.global mid_1121_s_v_WARIO_EXCELLENT_2
mid_1121_s_v_WARIO_EXCELLENT_2:
	.incbin "midi/1121_s_v_WARIO_EXCELLENT_2.mid"
	.balign 4, 0
	.global mid_1122_s_v_WARIO_EXCELLENT_3
mid_1122_s_v_WARIO_EXCELLENT_3:
	.incbin "midi/1122_s_v_WARIO_EXCELLENT_3.mid"
	.balign 4, 0
	.global mid_1123_s_v_WARIO_OH_RIGHT_1
mid_1123_s_v_WARIO_OH_RIGHT_1:
	.incbin "midi/1123_s_v_WARIO_OH_RIGHT_1.mid"
	.balign 4, 0
	.global mid_1124_s_v_WARIO_OH_RIGHT_2
mid_1124_s_v_WARIO_OH_RIGHT_2:
	.incbin "midi/1124_s_v_WARIO_OH_RIGHT_2.mid"
	.balign 4, 0
	.global mid_1125_s_v_WARIO_LAUGH_HA1_1
mid_1125_s_v_WARIO_LAUGH_HA1_1:
	.incbin "midi/1125_s_v_WARIO_LAUGH_HA1_1.mid"
	.balign 4, 0
	.global mid_1126_s_v_WARIO_LAUGH_HA1_2
mid_1126_s_v_WARIO_LAUGH_HA1_2:
	.incbin "midi/1126_s_v_WARIO_LAUGH_HA1_2.mid"
	.balign 4, 0
	.global mid_1127_s_v_WARIO_LAUGH_HA2_1
mid_1127_s_v_WARIO_LAUGH_HA2_1:
	.incbin "midi/1127_s_v_WARIO_LAUGH_HA2_1.mid"
	.balign 4, 0
	.global mid_1128_s_v_WARIO_LAUGH_HI_1
mid_1128_s_v_WARIO_LAUGH_HI_1:
	.incbin "midi/1128_s_v_WARIO_LAUGH_HI_1.mid"
	.balign 4, 0
	.global mid_1129_s_v_WARIO_OK_1
mid_1129_s_v_WARIO_OK_1:
	.incbin "midi/1129_s_v_WARIO_OK_1.mid"
	.balign 4, 0
	.global mid_1130_s_v_WARIO_OK_2
mid_1130_s_v_WARIO_OK_2:
	.incbin "midi/1130_s_v_WARIO_OK_2.mid"
	.balign 4, 0
	.global mid_1131_s_v_WARIO_OK_3
mid_1131_s_v_WARIO_OK_3:
	.incbin "midi/1131_s_v_WARIO_OK_3.mid"
	.balign 4, 0
	.global mid_1132_s_v_WARIO_OH_BOY_1
mid_1132_s_v_WARIO_OH_BOY_1:
	.incbin "midi/1132_s_v_WARIO_OH_BOY_1.mid"
	.balign 4, 0
	.global mid_1133_s_v_WARIO_OH_BOY_2
mid_1133_s_v_WARIO_OH_BOY_2:
	.incbin "midi/1133_s_v_WARIO_OH_BOY_2.mid"
	.balign 4, 0
	.global mid_1134_s_v_WARIO_HEY_1
mid_1134_s_v_WARIO_HEY_1:
	.incbin "midi/1134_s_v_WARIO_HEY_1.mid"
	.balign 4, 0
	.global mid_1135_s_v_WARIO_HEYHEY_1
mid_1135_s_v_WARIO_HEYHEY_1:
	.incbin "midi/1135_s_v_WARIO_HEYHEY_1.mid"
	.balign 4, 0
	.global mid_1136_s_v_WARIO_YEAH_1
mid_1136_s_v_WARIO_YEAH_1:
	.incbin "midi/1136_s_v_WARIO_YEAH_1.mid"
	.balign 4, 0
	.global mid_1137_s_v_WARIO_NO_1
mid_1137_s_v_WARIO_NO_1:
	.incbin "midi/1137_s_v_WARIO_NO_1.mid"
	.balign 4, 0
	.global mid_1138_s_v_WARIO_NO_2
mid_1138_s_v_WARIO_NO_2:
	.incbin "midi/1138_s_v_WARIO_NO_2.mid"
	.balign 4, 0
	.global mid_1139_s_v_WARIO_NO_3
mid_1139_s_v_WARIO_NO_3:
	.incbin "midi/1139_s_v_WARIO_NO_3.mid"
	.balign 4, 0
	.global mid_1140_s_v_WARIO_AHH_1
mid_1140_s_v_WARIO_AHH_1:
	.incbin "midi/1140_s_v_WARIO_AHH_1.mid"
	.balign 4, 0
	.global mid_1141_s_v_WARIO_AHH_2
mid_1141_s_v_WARIO_AHH_2:
	.incbin "midi/1141_s_v_WARIO_AHH_2.mid"
	.balign 4, 0
	.global mid_1142_s_v_WARIO_AHH_3
mid_1142_s_v_WARIO_AHH_3:
	.incbin "midi/1142_s_v_WARIO_AHH_3.mid"
	.balign 4, 0
	.global mid_1143_s_v_WARIO_AHH_EYEAH_1
mid_1143_s_v_WARIO_AHH_EYEAH_1:
	.incbin "midi/1143_s_v_WARIO_AHH_EYEAH_1.mid"
	.balign 4, 0
	.global mid_1144_s_v_WARIO_AHH_EYEAH_2
mid_1144_s_v_WARIO_AHH_EYEAH_2:
	.incbin "midi/1144_s_v_WARIO_AHH_EYEAH_2.mid"
	.balign 4, 0
	.global mid_1145_s_v_WARIO_HA_1
mid_1145_s_v_WARIO_HA_1:
	.incbin "midi/1145_s_v_WARIO_HA_1.mid"
	.balign 4, 0
	.global mid_1146_s_v_WARIO_WAA_1
mid_1146_s_v_WARIO_WAA_1:
	.incbin "midi/1146_s_v_WARIO_WAA_1.mid"
	.balign 4, 0
	.global mid_1147_s_v_WARIO_WAA_2
mid_1147_s_v_WARIO_WAA_2:
	.incbin "midi/1147_s_v_WARIO_WAA_2.mid"
	.balign 4, 0
	.global mid_1148_s_v_WARIO_WAO_1
mid_1148_s_v_WARIO_WAO_1:
	.incbin "midi/1148_s_v_WARIO_WAO_1.mid"
	.balign 4, 0
	.global mid_1149_s_v_WARIO_WAO_2
mid_1149_s_v_WARIO_WAO_2:
	.incbin "midi/1149_s_v_WARIO_WAO_2.mid"
	.balign 4, 0
	.global mid_1150_s_v_WARIO_WIN_YOKI
mid_1150_s_v_WARIO_WIN_YOKI:
	.incbin "midi/1150_s_v_WARIO_WIN_YOKI.mid"
	.balign 4, 0
	.global mid_1151_s_v_Monna_OK_01
mid_1151_s_v_Monna_OK_01:
	.incbin "midi/1151_s_v_Monna_OK_01.mid"
	.balign 4, 0
	.global mid_1152_s_v_Monna_OK_02
mid_1152_s_v_Monna_OK_02:
	.incbin "midi/1152_s_v_Monna_OK_02.mid"
	.balign 4, 0
	.global mid_1153_s_v_Monna_OK_03
mid_1153_s_v_Monna_OK_03:
	.incbin "midi/1153_s_v_Monna_OK_03.mid"
	.balign 4, 0
	.global mid_1154_s_v_Monna_OK_04
mid_1154_s_v_Monna_OK_04:
	.incbin "midi/1154_s_v_Monna_OK_04.mid"
	.balign 4, 0
	.global mid_1155_s_v_Monna_OK_05
mid_1155_s_v_Monna_OK_05:
	.incbin "midi/1155_s_v_Monna_OK_05.mid"
	.balign 4, 0
	.global mid_1156_s_v_Monna_OK_06
mid_1156_s_v_Monna_OK_06:
	.incbin "midi/1156_s_v_Monna_OK_06.mid"
	.balign 4, 0
	.global mid_1157_s_v_Monna_OK_07
mid_1157_s_v_Monna_OK_07:
	.incbin "midi/1157_s_v_Monna_OK_07.mid"
	.balign 4, 0
	.global mid_1158_s_v_Monna_OK_08
mid_1158_s_v_Monna_OK_08:
	.incbin "midi/1158_s_v_Monna_OK_08.mid"
	.balign 4, 0
	.global mid_1159_s_v_Monna_OK_09
mid_1159_s_v_Monna_OK_09:
	.incbin "midi/1159_s_v_Monna_OK_09.mid"
	.balign 4, 0
	.global mid_1160_s_v_Monna_OK_10
mid_1160_s_v_Monna_OK_10:
	.incbin "midi/1160_s_v_Monna_OK_10.mid"
	.balign 4, 0
	.global mid_1161_s_v_Monna_OK_11
mid_1161_s_v_Monna_OK_11:
	.incbin "midi/1161_s_v_Monna_OK_11.mid"
	.balign 4, 0
	.global mid_1162_s_v_Monna_OK_12
mid_1162_s_v_Monna_OK_12:
	.incbin "midi/1162_s_v_Monna_OK_12.mid"
	.balign 4, 0
	.global mid_1163_s_v_Monna_OK_13
mid_1163_s_v_Monna_OK_13:
	.incbin "midi/1163_s_v_Monna_OK_13.mid"
	.balign 4, 0
	.global mid_1164_s_v_Monna_NG_01
mid_1164_s_v_Monna_NG_01:
	.incbin "midi/1164_s_v_Monna_NG_01.mid"
	.balign 4, 0
	.global mid_1165_s_v_Monna_NG_02
mid_1165_s_v_Monna_NG_02:
	.incbin "midi/1165_s_v_Monna_NG_02.mid"
	.balign 4, 0
	.global mid_1166_s_v_Monna_NG_03
mid_1166_s_v_Monna_NG_03:
	.incbin "midi/1166_s_v_Monna_NG_03.mid"
	.balign 4, 0
	.global mid_1167_s_v_Monna_NG_04
mid_1167_s_v_Monna_NG_04:
	.incbin "midi/1167_s_v_Monna_NG_04.mid"
	.balign 4, 0
	.global mid_1168_s_v_Monna_NG_05
mid_1168_s_v_Monna_NG_05:
	.incbin "midi/1168_s_v_Monna_NG_05.mid"
	.balign 4, 0
	.global mid_1169_s_v_Monna_NG_06
mid_1169_s_v_Monna_NG_06:
	.incbin "midi/1169_s_v_Monna_NG_06.mid"
	.balign 4, 0
	.global mid_1170_s_v_Monna_NG_07
mid_1170_s_v_Monna_NG_07:
	.incbin "midi/1170_s_v_Monna_NG_07.mid"
	.balign 4, 0
	.global mid_1171_s_v_Monna_NG_08
mid_1171_s_v_Monna_NG_08:
	.incbin "midi/1171_s_v_Monna_NG_08.mid"
	.balign 4, 0
	.global mid_1172_s_v_Monna_NG_09
mid_1172_s_v_Monna_NG_09:
	.incbin "midi/1172_s_v_Monna_NG_09.mid"
	.balign 4, 0
	.global mid_1173_s_v_Monna_NG_10
mid_1173_s_v_Monna_NG_10:
	.incbin "midi/1173_s_v_Monna_NG_10.mid"
	.balign 4, 0
	.global mid_1174_s_v_App_OK_01
mid_1174_s_v_App_OK_01:
	.incbin "midi/1174_s_v_App_OK_01.mid"
	.balign 4, 0
	.global mid_1175_s_v_App_OK_02
mid_1175_s_v_App_OK_02:
	.incbin "midi/1175_s_v_App_OK_02.mid"
	.balign 4, 0
	.global mid_1176_s_v_App_OK_03
mid_1176_s_v_App_OK_03:
	.incbin "midi/1176_s_v_App_OK_03.mid"
	.balign 4, 0
	.global mid_1177_s_v_App_OK_04
mid_1177_s_v_App_OK_04:
	.incbin "midi/1177_s_v_App_OK_04.mid"
	.balign 4, 0
	.global mid_1178_s_v_App_OK_05
mid_1178_s_v_App_OK_05:
	.incbin "midi/1178_s_v_App_OK_05.mid"
	.balign 4, 0
	.global mid_1179_s_v_App_OK_06
mid_1179_s_v_App_OK_06:
	.incbin "midi/1179_s_v_App_OK_06.mid"
	.balign 4, 0
	.global mid_1180_s_v_App_OK_07
mid_1180_s_v_App_OK_07:
	.incbin "midi/1180_s_v_App_OK_07.mid"
	.balign 4, 0
	.global mid_1181_s_v_App_OK_08
mid_1181_s_v_App_OK_08:
	.incbin "midi/1181_s_v_App_OK_08.mid"
	.balign 4, 0
	.global mid_1182_s_v_App_OK_09
mid_1182_s_v_App_OK_09:
	.incbin "midi/1182_s_v_App_OK_09.mid"
	.balign 4, 0
	.global mid_1183_s_v_App_OK_10
mid_1183_s_v_App_OK_10:
	.incbin "midi/1183_s_v_App_OK_10.mid"
	.balign 4, 0
	.global mid_1184_s_v_App_OK_11
mid_1184_s_v_App_OK_11:
	.incbin "midi/1184_s_v_App_OK_11.mid"
	.balign 4, 0
	.global mid_1185_s_v_App_OK_12
mid_1185_s_v_App_OK_12:
	.incbin "midi/1185_s_v_App_OK_12.mid"
	.balign 4, 0
	.global mid_1186_s_v_App_OK_13
mid_1186_s_v_App_OK_13:
	.incbin "midi/1186_s_v_App_OK_13.mid"
	.balign 4, 0
	.global mid_1187_s_v_App_OK_14
mid_1187_s_v_App_OK_14:
	.incbin "midi/1187_s_v_App_OK_14.mid"
	.balign 4, 0
	.global mid_1188_s_v_App_OK_15
mid_1188_s_v_App_OK_15:
	.incbin "midi/1188_s_v_App_OK_15.mid"
	.balign 4, 0
	.global mid_1189_s_v_App_OK_16
mid_1189_s_v_App_OK_16:
	.incbin "midi/1189_s_v_App_OK_16.mid"
	.balign 4, 0
	.global mid_1190_s_v_App_NG_01
mid_1190_s_v_App_NG_01:
	.incbin "midi/1190_s_v_App_NG_01.mid"
	.balign 4, 0
	.global mid_1191_s_v_App_NG_02
mid_1191_s_v_App_NG_02:
	.incbin "midi/1191_s_v_App_NG_02.mid"
	.balign 4, 0
	.global mid_1192_s_v_App_NG_03
mid_1192_s_v_App_NG_03:
	.incbin "midi/1192_s_v_App_NG_03.mid"
	.balign 4, 0
	.global mid_1193_s_v_App_NG_04
mid_1193_s_v_App_NG_04:
	.incbin "midi/1193_s_v_App_NG_04.mid"
	.balign 4, 0
	.global mid_1194_s_v_App_NG_05
mid_1194_s_v_App_NG_05:
	.incbin "midi/1194_s_v_App_NG_05.mid"
	.balign 4, 0
	.global mid_1195_s_v_App_NG_06
mid_1195_s_v_App_NG_06:
	.incbin "midi/1195_s_v_App_NG_06.mid"
	.balign 4, 0
	.global mid_1196_s_v_App_NG_07
mid_1196_s_v_App_NG_07:
	.incbin "midi/1196_s_v_App_NG_07.mid"
	.balign 4, 0
	.global mid_1197_s_v_App_NG_08
mid_1197_s_v_App_NG_08:
	.incbin "midi/1197_s_v_App_NG_08.mid"
	.balign 4, 0
	.global mid_1198_s_v_App_NG_09
mid_1198_s_v_App_NG_09:
	.incbin "midi/1198_s_v_App_NG_09.mid"
	.balign 4, 0
	.global mid_1199_s_v_App_NG_10
mid_1199_s_v_App_NG_10:
	.incbin "midi/1199_s_v_App_NG_10.mid"
	.balign 4, 0
	.global mid_1200_s_v_App_NG_11
mid_1200_s_v_App_NG_11:
	.incbin "midi/1200_s_v_App_NG_11.mid"
	.balign 4, 0
	.global mid_1201_s_v_App_Morning_1
mid_1201_s_v_App_Morning_1:
	.incbin "midi/1201_s_v_App_Morning_1.mid"
	.balign 4, 0
	.global mid_1202_s_v_App_Hello_1
mid_1202_s_v_App_Hello_1:
	.incbin "midi/1202_s_v_App_Hello_1.mid"
	.balign 4, 0
	.global mid_1203_s_v_App_Night_1
mid_1203_s_v_App_Night_1:
	.incbin "midi/1203_s_v_App_Night_1.mid"
	.balign 4, 0
	.global mid_1204_s_v_Dra_OK_01
mid_1204_s_v_Dra_OK_01:
	.incbin "midi/1204_s_v_Dra_OK_01.mid"
	.balign 4, 0
	.global mid_1205_s_v_Dra_OK_02
mid_1205_s_v_Dra_OK_02:
	.incbin "midi/1205_s_v_Dra_OK_02.mid"
	.balign 4, 0
	.global mid_1206_s_v_Dra_OK_03
mid_1206_s_v_Dra_OK_03:
	.incbin "midi/1206_s_v_Dra_OK_03.mid"
	.balign 4, 0
	.global mid_1207_s_v_Dra_OK_04
mid_1207_s_v_Dra_OK_04:
	.incbin "midi/1207_s_v_Dra_OK_04.mid"
	.balign 4, 0
	.global mid_1208_s_v_Dra_OK_05
mid_1208_s_v_Dra_OK_05:
	.incbin "midi/1208_s_v_Dra_OK_05.mid"
	.balign 4, 0
	.global mid_1209_s_v_Dra_OK_06
mid_1209_s_v_Dra_OK_06:
	.incbin "midi/1209_s_v_Dra_OK_06.mid"
	.balign 4, 0
	.global mid_1210_s_v_Dra_OK_07
mid_1210_s_v_Dra_OK_07:
	.incbin "midi/1210_s_v_Dra_OK_07.mid"
	.balign 4, 0
	.global mid_1211_s_v_Dra_OK_08
mid_1211_s_v_Dra_OK_08:
	.incbin "midi/1211_s_v_Dra_OK_08.mid"
	.balign 4, 0
	.global mid_1212_s_v_Dra_OK_09
mid_1212_s_v_Dra_OK_09:
	.incbin "midi/1212_s_v_Dra_OK_09.mid"
	.balign 4, 0
	.global mid_1213_s_v_Dra_OK_10
mid_1213_s_v_Dra_OK_10:
	.incbin "midi/1213_s_v_Dra_OK_10.mid"
	.balign 4, 0
	.global mid_1214_s_v_Dra_OK_11
mid_1214_s_v_Dra_OK_11:
	.incbin "midi/1214_s_v_Dra_OK_11.mid"
	.balign 4, 0
	.global mid_1215_s_v_Dra_OK_12
mid_1215_s_v_Dra_OK_12:
	.incbin "midi/1215_s_v_Dra_OK_12.mid"
	.balign 4, 0
	.global mid_1216_s_v_Dra_OK_13
mid_1216_s_v_Dra_OK_13:
	.incbin "midi/1216_s_v_Dra_OK_13.mid"
	.balign 4, 0
	.global mid_1217_s_v_Dra_NG_01
mid_1217_s_v_Dra_NG_01:
	.incbin "midi/1217_s_v_Dra_NG_01.mid"
	.balign 4, 0
	.global mid_1218_s_v_Dra_NG_02
mid_1218_s_v_Dra_NG_02:
	.incbin "midi/1218_s_v_Dra_NG_02.mid"
	.balign 4, 0
	.global mid_1219_s_v_Dra_NG_03
mid_1219_s_v_Dra_NG_03:
	.incbin "midi/1219_s_v_Dra_NG_03.mid"
	.balign 4, 0
	.global mid_1220_s_v_Dra_NG_04
mid_1220_s_v_Dra_NG_04:
	.incbin "midi/1220_s_v_Dra_NG_04.mid"
	.balign 4, 0
	.global mid_1221_s_v_Dra_NG_05
mid_1221_s_v_Dra_NG_05:
	.incbin "midi/1221_s_v_Dra_NG_05.mid"
	.balign 4, 0
	.global mid_1222_s_v_Dra_NG_06
mid_1222_s_v_Dra_NG_06:
	.incbin "midi/1222_s_v_Dra_NG_06.mid"
	.balign 4, 0
	.global mid_1223_s_v_Dra_NG_07
mid_1223_s_v_Dra_NG_07:
	.incbin "midi/1223_s_v_Dra_NG_07.mid"
	.balign 4, 0
	.global mid_1224_s_v_Dra_NG_08
mid_1224_s_v_Dra_NG_08:
	.incbin "midi/1224_s_v_Dra_NG_08.mid"
	.balign 4, 0
	.global mid_1225_s_v_Dra_NG_09
mid_1225_s_v_Dra_NG_09:
	.incbin "midi/1225_s_v_Dra_NG_09.mid"
	.balign 4, 0
	.global mid_1226_s_v_Dra_NG_10
mid_1226_s_v_Dra_NG_10:
	.incbin "midi/1226_s_v_Dra_NG_10.mid"
	.balign 4, 0
	.global mid_1227_s_v_Dra_NG_11
mid_1227_s_v_Dra_NG_11:
	.incbin "midi/1227_s_v_Dra_NG_11.mid"
	.balign 4, 0
	.global mid_1228_s_v_Loo_OK_01
mid_1228_s_v_Loo_OK_01:
	.incbin "midi/1228_s_v_Loo_OK_01.mid"
	.balign 4, 0
	.global mid_1229_s_v_Loo_OK_02
mid_1229_s_v_Loo_OK_02:
	.incbin "midi/1229_s_v_Loo_OK_02.mid"
	.balign 4, 0
	.global mid_1230_s_v_Loo_OK_03
mid_1230_s_v_Loo_OK_03:
	.incbin "midi/1230_s_v_Loo_OK_03.mid"
	.balign 4, 0
	.global mid_1231_s_v_Loo_OK_04
mid_1231_s_v_Loo_OK_04:
	.incbin "midi/1231_s_v_Loo_OK_04.mid"
	.balign 4, 0
	.global mid_1232_s_v_Loo_OK_05
mid_1232_s_v_Loo_OK_05:
	.incbin "midi/1232_s_v_Loo_OK_05.mid"
	.balign 4, 0
	.global mid_1233_s_v_Loo_OK_06
mid_1233_s_v_Loo_OK_06:
	.incbin "midi/1233_s_v_Loo_OK_06.mid"
	.balign 4, 0
	.global mid_1234_s_v_Loo_OK_07
mid_1234_s_v_Loo_OK_07:
	.incbin "midi/1234_s_v_Loo_OK_07.mid"
	.balign 4, 0
	.global mid_1235_s_v_Loo_OK_08
mid_1235_s_v_Loo_OK_08:
	.incbin "midi/1235_s_v_Loo_OK_08.mid"
	.balign 4, 0
	.global mid_1236_s_v_Loo_OK_09
mid_1236_s_v_Loo_OK_09:
	.incbin "midi/1236_s_v_Loo_OK_09.mid"
	.balign 4, 0
	.global mid_1237_s_v_Loo_OK_10
mid_1237_s_v_Loo_OK_10:
	.incbin "midi/1237_s_v_Loo_OK_10.mid"
	.balign 4, 0
	.global mid_1238_s_v_Loo_OK_11
mid_1238_s_v_Loo_OK_11:
	.incbin "midi/1238_s_v_Loo_OK_11.mid"
	.balign 4, 0
	.global mid_1239_s_v_Loo_OK_12
mid_1239_s_v_Loo_OK_12:
	.incbin "midi/1239_s_v_Loo_OK_12.mid"
	.balign 4, 0
	.global mid_1240_s_v_Loo_OK_13
mid_1240_s_v_Loo_OK_13:
	.incbin "midi/1240_s_v_Loo_OK_13.mid"
	.balign 4, 0
	.global mid_1241_s_v_Loo_OK_14
mid_1241_s_v_Loo_OK_14:
	.incbin "midi/1241_s_v_Loo_OK_14.mid"
	.balign 4, 0
	.global mid_1242_s_v_Loo_NG_01
mid_1242_s_v_Loo_NG_01:
	.incbin "midi/1242_s_v_Loo_NG_01.mid"
	.balign 4, 0
	.global mid_1243_s_v_Loo_NG_02
mid_1243_s_v_Loo_NG_02:
	.incbin "midi/1243_s_v_Loo_NG_02.mid"
	.balign 4, 0
	.global mid_1244_s_v_Loo_NG_03
mid_1244_s_v_Loo_NG_03:
	.incbin "midi/1244_s_v_Loo_NG_03.mid"
	.balign 4, 0
	.global mid_1245_s_v_Loo_NG_04
mid_1245_s_v_Loo_NG_04:
	.incbin "midi/1245_s_v_Loo_NG_04.mid"
	.balign 4, 0
	.global mid_1246_s_v_Loo_NG_05
mid_1246_s_v_Loo_NG_05:
	.incbin "midi/1246_s_v_Loo_NG_05.mid"
	.balign 4, 0
	.global mid_1247_s_v_Loo_NG_06
mid_1247_s_v_Loo_NG_06:
	.incbin "midi/1247_s_v_Loo_NG_06.mid"
	.balign 4, 0
	.global mid_1248_s_v_Loo_NG_07
mid_1248_s_v_Loo_NG_07:
	.incbin "midi/1248_s_v_Loo_NG_07.mid"
	.balign 4, 0
	.global mid_1249_s_v_Loo_NG_08
mid_1249_s_v_Loo_NG_08:
	.incbin "midi/1249_s_v_Loo_NG_08.mid"
	.balign 4, 0
	.global mid_1250_s_v_Loo_NG_09
mid_1250_s_v_Loo_NG_09:
	.incbin "midi/1250_s_v_Loo_NG_09.mid"
	.balign 4, 0
	.global mid_1251_s_v_Loo_NG_10
mid_1251_s_v_Loo_NG_10:
	.incbin "midi/1251_s_v_Loo_NG_10.mid"
	.balign 4, 0
	.global mid_1252_s_v_Voya_OK_01
mid_1252_s_v_Voya_OK_01:
	.incbin "midi/1252_s_v_Voya_OK_01.mid"
	.balign 4, 0
	.global mid_1253_s_v_Voya_OK_02
mid_1253_s_v_Voya_OK_02:
	.incbin "midi/1253_s_v_Voya_OK_02.mid"
	.balign 4, 0
	.global mid_1254_s_v_Voya_OK_03
mid_1254_s_v_Voya_OK_03:
	.incbin "midi/1254_s_v_Voya_OK_03.mid"
	.balign 4, 0
	.global mid_1255_s_v_Voya_OK_04
mid_1255_s_v_Voya_OK_04:
	.incbin "midi/1255_s_v_Voya_OK_04.mid"
	.balign 4, 0
	.global mid_1256_s_v_Voya_OK_05
mid_1256_s_v_Voya_OK_05:
	.incbin "midi/1256_s_v_Voya_OK_05.mid"
	.balign 4, 0
	.global mid_1257_s_v_Voya_OK_06
mid_1257_s_v_Voya_OK_06:
	.incbin "midi/1257_s_v_Voya_OK_06.mid"
	.balign 4, 0
	.global mid_1258_s_v_Voya_OK_07
mid_1258_s_v_Voya_OK_07:
	.incbin "midi/1258_s_v_Voya_OK_07.mid"
	.balign 4, 0
	.global mid_1259_s_v_Voya_OK_08
mid_1259_s_v_Voya_OK_08:
	.incbin "midi/1259_s_v_Voya_OK_08.mid"
	.balign 4, 0
	.global mid_1260_s_v_Voya_OK_09
mid_1260_s_v_Voya_OK_09:
	.incbin "midi/1260_s_v_Voya_OK_09.mid"
	.balign 4, 0
	.global mid_1261_s_v_Voya_OK_10
mid_1261_s_v_Voya_OK_10:
	.incbin "midi/1261_s_v_Voya_OK_10.mid"
	.balign 4, 0
	.global mid_1262_s_v_Voya_NG_01
mid_1262_s_v_Voya_NG_01:
	.incbin "midi/1262_s_v_Voya_NG_01.mid"
	.balign 4, 0
	.global mid_1263_s_v_Voya_NG_02
mid_1263_s_v_Voya_NG_02:
	.incbin "midi/1263_s_v_Voya_NG_02.mid"
	.balign 4, 0
	.global mid_1264_s_v_Voya_NG_03
mid_1264_s_v_Voya_NG_03:
	.incbin "midi/1264_s_v_Voya_NG_03.mid"
	.balign 4, 0
	.global mid_1265_s_v_Voya_NG_04
mid_1265_s_v_Voya_NG_04:
	.incbin "midi/1265_s_v_Voya_NG_04.mid"
	.balign 4, 0
	.global mid_1266_s_v_Voya_NG_05
mid_1266_s_v_Voya_NG_05:
	.incbin "midi/1266_s_v_Voya_NG_05.mid"
	.balign 4, 0
	.global mid_1267_s_v_Voya_NG_06
mid_1267_s_v_Voya_NG_06:
	.incbin "midi/1267_s_v_Voya_NG_06.mid"
	.balign 4, 0
	.global mid_1268_s_v_Bio_OK_01
mid_1268_s_v_Bio_OK_01:
	.incbin "midi/1268_s_v_Bio_OK_01.mid"
	.balign 4, 0
	.global mid_1269_s_v_Bio_OK_02
mid_1269_s_v_Bio_OK_02:
	.incbin "midi/1269_s_v_Bio_OK_02.mid"
	.balign 4, 0
	.global mid_1270_s_v_Bio_OK_03
mid_1270_s_v_Bio_OK_03:
	.incbin "midi/1270_s_v_Bio_OK_03.mid"
	.balign 4, 0
	.global mid_1271_s_v_Bio_OK_04
mid_1271_s_v_Bio_OK_04:
	.incbin "midi/1271_s_v_Bio_OK_04.mid"
	.balign 4, 0
	.global mid_1272_s_v_Bio_OK_05
mid_1272_s_v_Bio_OK_05:
	.incbin "midi/1272_s_v_Bio_OK_05.mid"
	.balign 4, 0
	.global mid_1273_s_v_Bio_OK_06
mid_1273_s_v_Bio_OK_06:
	.incbin "midi/1273_s_v_Bio_OK_06.mid"
	.balign 4, 0
	.global mid_1274_s_v_Bio_OK_07
mid_1274_s_v_Bio_OK_07:
	.incbin "midi/1274_s_v_Bio_OK_07.mid"
	.balign 4, 0
	.global mid_1275_s_v_Bio_OK_08
mid_1275_s_v_Bio_OK_08:
	.incbin "midi/1275_s_v_Bio_OK_08.mid"
	.balign 4, 0
	.global mid_1276_s_v_Bio_OK_09
mid_1276_s_v_Bio_OK_09:
	.incbin "midi/1276_s_v_Bio_OK_09.mid"
	.balign 4, 0
	.global mid_1277_s_v_Bio_OK_10
mid_1277_s_v_Bio_OK_10:
	.incbin "midi/1277_s_v_Bio_OK_10.mid"
	.balign 4, 0
	.global mid_1278_s_v_Bio_NG_01
mid_1278_s_v_Bio_NG_01:
	.incbin "midi/1278_s_v_Bio_NG_01.mid"
	.balign 4, 0
	.global mid_1279_s_v_Bio_NG_02
mid_1279_s_v_Bio_NG_02:
	.incbin "midi/1279_s_v_Bio_NG_02.mid"
	.balign 4, 0
	.global mid_1280_s_v_Bio_NG_03
mid_1280_s_v_Bio_NG_03:
	.incbin "midi/1280_s_v_Bio_NG_03.mid"
	.balign 4, 0
	.global mid_1281_s_v_Bio_NG_04
mid_1281_s_v_Bio_NG_04:
	.incbin "midi/1281_s_v_Bio_NG_04.mid"
	.balign 4, 0
	.global mid_1282_s_v_Bio_NG_05
mid_1282_s_v_Bio_NG_05:
	.incbin "midi/1282_s_v_Bio_NG_05.mid"
	.balign 4, 0
	.global mid_1283_s_v_Bio_NG_06
mid_1283_s_v_Bio_NG_06:
	.incbin "midi/1283_s_v_Bio_NG_06.mid"
	.balign 4, 0
	.global mid_1284_s_v_Bio_NG_07
mid_1284_s_v_Bio_NG_07:
	.incbin "midi/1284_s_v_Bio_NG_07.mid"
	.balign 4, 0
	.global mid_1285_s_v_Bio_NG_08
mid_1285_s_v_Bio_NG_08:
	.incbin "midi/1285_s_v_Bio_NG_08.mid"
	.balign 4, 0
	.global mid_1286_s_v_Bio_NG_09
mid_1286_s_v_Bio_NG_09:
	.incbin "midi/1286_s_v_Bio_NG_09.mid"
	.balign 4, 0
	.global mid_1287_s_v_Bio_NG_10
mid_1287_s_v_Bio_NG_10:
	.incbin "midi/1287_s_v_Bio_NG_10.mid"
	.balign 4, 0
	.global mid_1288_s_v_Kaede_OK_01
mid_1288_s_v_Kaede_OK_01:
	.incbin "midi/1288_s_v_Kaede_OK_01.mid"
	.balign 4, 0
	.global mid_1289_s_v_Kaede_OK_02
mid_1289_s_v_Kaede_OK_02:
	.incbin "midi/1289_s_v_Kaede_OK_02.mid"
	.balign 4, 0
	.global mid_1290_s_v_Kaede_OK_03
mid_1290_s_v_Kaede_OK_03:
	.incbin "midi/1290_s_v_Kaede_OK_03.mid"
	.balign 4, 0
	.global mid_1291_s_v_Kaede_OK_04
mid_1291_s_v_Kaede_OK_04:
	.incbin "midi/1291_s_v_Kaede_OK_04.mid"
	.balign 4, 0
	.global mid_1292_s_v_Kaede_OK_05
mid_1292_s_v_Kaede_OK_05:
	.incbin "midi/1292_s_v_Kaede_OK_05.mid"
	.balign 4, 0
	.global mid_1293_s_v_Kaede_OK_06
mid_1293_s_v_Kaede_OK_06:
	.incbin "midi/1293_s_v_Kaede_OK_06.mid"
	.balign 4, 0
	.global mid_1294_s_v_Kaede_OK_07
mid_1294_s_v_Kaede_OK_07:
	.incbin "midi/1294_s_v_Kaede_OK_07.mid"
	.balign 4, 0
	.global mid_1295_s_v_Kaede_OK_08
mid_1295_s_v_Kaede_OK_08:
	.incbin "midi/1295_s_v_Kaede_OK_08.mid"
	.balign 4, 0
	.global mid_1296_s_v_Kaede_OK_09
mid_1296_s_v_Kaede_OK_09:
	.incbin "midi/1296_s_v_Kaede_OK_09.mid"
	.balign 4, 0
	.global mid_1297_s_v_Kaede_OK_10
mid_1297_s_v_Kaede_OK_10:
	.incbin "midi/1297_s_v_Kaede_OK_10.mid"
	.balign 4, 0
	.global mid_1298_s_v_Kaede_NG_01
mid_1298_s_v_Kaede_NG_01:
	.incbin "midi/1298_s_v_Kaede_NG_01.mid"
	.balign 4, 0
	.global mid_1299_s_v_Kaede_NG_02
mid_1299_s_v_Kaede_NG_02:
	.incbin "midi/1299_s_v_Kaede_NG_02.mid"
	.balign 4, 0
	.global mid_1300_s_v_Kaede_NG_03
mid_1300_s_v_Kaede_NG_03:
	.incbin "midi/1300_s_v_Kaede_NG_03.mid"
	.balign 4, 0
	.global mid_1301_s_v_Kaede_NG_04
mid_1301_s_v_Kaede_NG_04:
	.incbin "midi/1301_s_v_Kaede_NG_04.mid"
	.balign 4, 0
	.global mid_1302_s_v_Kaede_NG_05
mid_1302_s_v_Kaede_NG_05:
	.incbin "midi/1302_s_v_Kaede_NG_05.mid"
	.balign 4, 0
	.global mid_1303_s_v_Kaede_NG_06
mid_1303_s_v_Kaede_NG_06:
	.incbin "midi/1303_s_v_Kaede_NG_06.mid"
	.balign 4, 0
	.global mid_1304_s_v_Kaede_NG_07
mid_1304_s_v_Kaede_NG_07:
	.incbin "midi/1304_s_v_Kaede_NG_07.mid"
	.balign 4, 0
	.global mid_1305_s_v_App_Select_A1
mid_1305_s_v_App_Select_A1:
	.incbin "midi/1305_s_v_App_Select_A1.mid"
	.balign 4, 0
	.global mid_1306_s_v_App_Select_A2
mid_1306_s_v_App_Select_A2:
	.incbin "midi/1306_s_v_App_Select_A2.mid"
	.balign 4, 0
	.global mid_1307_s_v_App_Select_A3
mid_1307_s_v_App_Select_A3:
	.incbin "midi/1307_s_v_App_Select_A3.mid"
	.balign 4, 0
	.global mid_1308_s_v_App_Select_B1
mid_1308_s_v_App_Select_B1:
	.incbin "midi/1308_s_v_App_Select_B1.mid"
	.balign 4, 0
	.global mid_1309_s_v_App_Select_B2
mid_1309_s_v_App_Select_B2:
	.incbin "midi/1309_s_v_App_Select_B2.mid"
	.balign 4, 0
	.global mid_1310_s_v_App_Select_B3
mid_1310_s_v_App_Select_B3:
	.incbin "midi/1310_s_v_App_Select_B3.mid"
	.balign 4, 0
	.global mid_1311_s_v_App_Select_C1
mid_1311_s_v_App_Select_C1:
	.incbin "midi/1311_s_v_App_Select_C1.mid"
	.balign 4, 0
	.global mid_1312_s_v_App_Select_C2
mid_1312_s_v_App_Select_C2:
	.incbin "midi/1312_s_v_App_Select_C2.mid"
	.balign 4, 0
	.global mid_1313_s_v_App_Select_C3
mid_1313_s_v_App_Select_C3:
	.incbin "midi/1313_s_v_App_Select_C3.mid"
	.balign 4, 0
	.global mid_1314_s_v_Dra_Select_1
mid_1314_s_v_Dra_Select_1:
	.incbin "midi/1314_s_v_Dra_Select_1.mid"
	.balign 4, 0
	.global mid_1315_s_v_Dra_Select_2
mid_1315_s_v_Dra_Select_2:
	.incbin "midi/1315_s_v_Dra_Select_2.mid"
	.balign 4, 0
	.global mid_1316_s_v_Dra_Select_3
mid_1316_s_v_Dra_Select_3:
	.incbin "midi/1316_s_v_Dra_Select_3.mid"
	.balign 4, 0
	.global mid_1317_s_v_Monna_Select_1
mid_1317_s_v_Monna_Select_1:
	.incbin "midi/1317_s_v_Monna_Select_1.mid"
	.balign 4, 0
	.global mid_1318_s_v_Monna_Select_2
mid_1318_s_v_Monna_Select_2:
	.incbin "midi/1318_s_v_Monna_Select_2.mid"
	.balign 4, 0
	.global mid_1319_s_v_Monna_Select_3
mid_1319_s_v_Monna_Select_3:
	.incbin "midi/1319_s_v_Monna_Select_3.mid"
	.balign 4, 0
	.global mid_1320_s_v_Voya_Select_1
mid_1320_s_v_Voya_Select_1:
	.incbin "midi/1320_s_v_Voya_Select_1.mid"
	.balign 4, 0
	.global mid_1321_s_v_Voya_Select_2
mid_1321_s_v_Voya_Select_2:
	.incbin "midi/1321_s_v_Voya_Select_2.mid"
	.balign 4, 0
	.global mid_1322_s_v_Voya_Select_3
mid_1322_s_v_Voya_Select_3:
	.incbin "midi/1322_s_v_Voya_Select_3.mid"
	.balign 4, 0
	.global mid_1323_s_v_Bio_Select_1
mid_1323_s_v_Bio_Select_1:
	.incbin "midi/1323_s_v_Bio_Select_1.mid"
	.balign 4, 0
	.global mid_1324_s_v_Bio_Select_2
mid_1324_s_v_Bio_Select_2:
	.incbin "midi/1324_s_v_Bio_Select_2.mid"
	.balign 4, 0
	.global mid_1325_s_v_Bio_Select_3
mid_1325_s_v_Bio_Select_3:
	.incbin "midi/1325_s_v_Bio_Select_3.mid"
	.balign 4, 0
	.global mid_1326_s_v_Loo_Select_1
mid_1326_s_v_Loo_Select_1:
	.incbin "midi/1326_s_v_Loo_Select_1.mid"
	.balign 4, 0
	.global mid_1327_s_v_Loo_Select_2
mid_1327_s_v_Loo_Select_2:
	.incbin "midi/1327_s_v_Loo_Select_2.mid"
	.balign 4, 0
	.global mid_1328_s_v_Loo_Select_3
mid_1328_s_v_Loo_Select_3:
	.incbin "midi/1328_s_v_Loo_Select_3.mid"
	.balign 4, 0
	.global mid_1329_s_v_wario_Select_1
mid_1329_s_v_wario_Select_1:
	.incbin "midi/1329_s_v_wario_Select_1.mid"
	.balign 4, 0
	.global mid_1330_s_v_wario_Select_2
mid_1330_s_v_wario_Select_2:
	.incbin "midi/1330_s_v_wario_Select_2.mid"
	.balign 4, 0
	.global mid_1331_s_v_wario_Select_3
mid_1331_s_v_wario_Select_3:
	.incbin "midi/1331_s_v_wario_Select_3.mid"
	.balign 4, 0
	.global mid_1332_s_v_Kaede_Select_1
mid_1332_s_v_Kaede_Select_1:
	.incbin "midi/1332_s_v_Kaede_Select_1.mid"
	.balign 4, 0
	.global mid_1333_s_v_Kaede_Select_2
mid_1333_s_v_Kaede_Select_2:
	.incbin "midi/1333_s_v_Kaede_Select_2.mid"
	.balign 4, 0
	.global mid_1334_s_v_Kaede_Select_3
mid_1334_s_v_Kaede_Select_3:
	.incbin "midi/1334_s_v_Kaede_Select_3.mid"
	.balign 4, 0
	.global mid_1335_s_v_App_MAP_01
mid_1335_s_v_App_MAP_01:
	.incbin "midi/1335_s_v_App_MAP_01.mid"
	.balign 4, 0
	.global mid_1336_s_v_Dra_MAP_01
mid_1336_s_v_Dra_MAP_01:
	.incbin "midi/1336_s_v_Dra_MAP_01.mid"
	.balign 4, 0
	.global mid_1337_s_v_Monna_MAP_01
mid_1337_s_v_Monna_MAP_01:
	.incbin "midi/1337_s_v_Monna_MAP_01.mid"
	.balign 4, 0
	.global mid_1338_s_v_Voya_MAP_01
mid_1338_s_v_Voya_MAP_01:
	.incbin "midi/1338_s_v_Voya_MAP_01.mid"
	.balign 4, 0
	.global mid_1339_s_v_Bio_MAP_01
mid_1339_s_v_Bio_MAP_01:
	.incbin "midi/1339_s_v_Bio_MAP_01.mid"
	.balign 4, 0
	.global mid_1340_s_v_Loo_MAP_01
mid_1340_s_v_Loo_MAP_01:
	.incbin "midi/1340_s_v_Loo_MAP_01.mid"
	.balign 4, 0
	.global mid_1341_s_v_KAEDE_MAP_01
mid_1341_s_v_KAEDE_MAP_01:
	.incbin "midi/1341_s_v_KAEDE_MAP_01.mid"
	.balign 4, 0
