; Sanrio Carnival 2 sound, bank $01: music streams, $6E32-$7FFF

Song0D_Ch1:
	lengths LengthTable3
	wave Wave3
	master_vol $77
	music_pan $de
	sweep1 $78
	pitch 1, PitchMacro_2C
	jump Song01_Ch1_Loop
Song01_Ch1:
	lengths LengthTable3
	wave Wave3
	master_vol $77
	music_pan $de
	sweep1 $78
	duty1 $3f
	env 1, EnvMacro_00
	pitch 1, PitchMacro_2C
	note E_4, 4, 2
	note D_4
	note C_4, 3, 1
	note E_4, 11, 3
	note D_4
	note C_4
	note B_3, 3, 2
	note REST
Song01_Ch1_Loop:
	duty1 $7f
	env 1, EnvMacro_08
	note E_4, 11, 16
	note Ds4
	note E_4
	note G_3
	note Fs3
	note G_3
	note E_4
	note Ds4
	note E_4
	note G_3
	note Fs3
	note G_3
	note C_4
	note B_3
	note C_4
	note A_3
	note Gs3, 11, 16
	note A_3
	note C_4
	note B_3
	note C_4
	note A_3
	note B_3
	note C_4
	note Fs3
	note F_3
	note Fs3
	note A_3
	note Gs3
	note A_3
	note D_4
	note Cs4
	note D_4, 11, 16
	note Fs4
	note F_4
	note Fs4
	note B_3
	note As3
	note B_3
	note D_4
	note Cs4
	note D_4
	note B_3
	note As3
	note B_3
	note F_4
	note E_4
	note D_4
	note E_4, 11, 16
	note Ds4
	note E_4
	note G_3
	note Fs3
	note G_3
	note E_4
	note Ds4
	note E_4
	note B_3
	note C_4
	note D_4
	note E_4
	note Ds4
	note E_4
	note A_4
	note Gs4, 11, 16
	note A_4
	note Fs4
	note F_4
	note Fs4
	note Fs4
	note Gs4
	note A_4
	note G_4
	note Fs4
	note G_4
	note F_4
	note REST
	note E_4
	note Fs4
	note E_4
	note Fs4, 11, 10
	note E_4
	note REST
	note D_4
	note E_4
	note Ds4
	note E_4
	note E_4
	note Ds4
	note E_4
	note E_4, 3, 2
	note REST
	env 1, EnvMacro_0E
	note F_4, 11, 6
	note REST
	note E_4
	note F_4
	note REST
	note F_4
	note E_4, 3, 2
	env 1, EnvMacro_00
	note G_4
	note F_4, 11, 9
	note REST
	note F_4
	note E_4
	note REST
	note F_4
	note G_4
	note REST
	note F_4
	note E_4, 3, 1
	env 1, EnvMacro_0E
	note F_4, 11, 6
	note REST
	note E_4
	note F_4
	note REST
	note F_4
	note E_4, 3, 2
	env 1, EnvMacro_00
	note G_4
	note Fs4, 11, 6
	note REST
	note Fs4
	note G_4
	note REST
	note A_4
	note B_4, 3, 2
	note REST
	jump Song01_Ch1_Loop
Song0D_Ch2:
	pitch 2, PitchMacro_2C
	jump Song01_Ch2_Loop
Song01_Ch2:
	duty2 $3f
	env 2, EnvMacro_00
	pitch 2, PitchMacro_2C
	note G_4, 11, 12
	note A_4
	note G_4
	note G_5
	note REST
	note G_5
	note G_4
	note A_4
	note G_4
	note G_5
	note REST
	note G_5
	note A_4, 11, 6
	note B_4
	note C_5
	note C_5
	note D_5
	note E_5
	note D_5, 3, 2
	note G_5
Song01_Ch2_Loop:
	duty2 $bf
	env 2, EnvMacro_08
	note G_4, 3, 1
	note REST, 12, 1
	note A_4, 11, 7
	note G_4
	note REST
	note E_4
	note D_4
	note REST
	note C_4
	note A_4, 3, 2
	note A_4
	note A_4, 4, 1
	note D_4, 3, 1
	note REST, 12, 1
	note E_4, 11, 7
	note Fs4
	note REST
	note C_5
	note B_4
	note REST
	note A_4
	note G_4, 3, 1
	note G_4, 11, 3
	note REST
	note A_4
	note G_4, 4, 1
	note G_4, 3, 1
	note REST, 12, 1
	note A_4, 11, 7
	note Gs4
	note REST
	note Gs4
	note A_4
	note REST
	note B_4
	note C_5, 3, 5
	note C_5
	note C_5
	note D_5
	note E_5
	note D_5, 11, 3
	note REST
	note C_5
	note D_5, 3, 1
	note C_5, 11, 3
	note REST
	note B_4
	note C_5, 3, 4
	note C_5
	note C_5
	note REST
	duty2 $7f
	env 2, EnvMacro_0E
	note A_3, 11, 6
	note REST
	note Gs3
	note A_3
	note REST
	note B_3
	note C_4, 3, 2
	duty2 $bf
	env 2, EnvMacro_00
	note E_5
	note D_5, 11, 9
	note REST
	note D_5
	note C_5
	note REST
	note D_5
	note E_5
	note REST
	note D_5
	note C_5, 3, 1
	duty2 $7f
	env 2, EnvMacro_0E
	note A_3, 11, 6
	note REST
	note Gs3
	note A_3
	note REST
	note B_3
	note C_4, 3, 2
	duty2 $bf
	env 2, EnvMacro_00
	note E_5
	note D_5, 11, 12
	note REST
	note D_5
	note E_5
	note REST
	note Fs5
	note G_5
	note REST
	note G_4
	note G_4
	note REST
	note G_4
	jump Song01_Ch2_Loop
Song0D_Ch3:
	len3 $ff
	env 3, EnvMacro_18
	pitch 3, PitchMacro_2C
	jump Song01_Ch3_Loop
Song01_Ch3:
	len3 $ff
	env 3, EnvMacro_18
	pitch 3, PitchMacro_2C
	note C_5, 4, 2
	note B_4
	note A_4, 3, 2
	note Fs4
	note A_4, 11, 6
	note REST
	note G_3
	note G_3
	note A_3
	note B_3
Song01_Ch3_Loop:
	note C_4, 3, 3
	note REST
	note C_4
	note G_3, 11, 3
	note C_4
	note B_3
	note A_3, 3, 3
	note REST
	note A_3
	note E_4, 11, 3
	note D_4
	note C_4
	note D_4, 3, 3
	note REST
	note D_4
	note D_3, 11, 3
	note D_4
	note D_3
	note G_3, 3, 2
	note REST
	note G_3, 11, 6
	note REST
	note G_3
	note G_3
	note A_3
	note B_3
	note C_4, 3, 3
	note REST
	note B_3
	note E_3, 11, 3
	note Fs3
	note Gs3
	note A_3, 3, 3
	note REST
	note D_4
	note D_3, 11, 3
	note E_3
	note Fs3
	note G_3, 3, 1
	note G_4, 11, 3
	note Fs4
	note G_4
	note G_3, 3, 1
	note G_4, 11, 3
	note Fs4
	note G_4
	note C_4, 3, 1
	note G_4, 11, 9
	note Fs4
	note G_4
	note C_4
	note REST
	note C_4
	note C_4
	note D_4
	note E_4
	note REST, 5, 1
	note G_3, 11, 6
	note REST
	note G_4
	note G_3
	note REST
	note G_4
	note C_4, 3, 2
	note REST
	note REST, 5, 1
	note D_3, 11, 6
	note REST
	note D_4
	note D_3
	note REST
	note D_4
	note G_3, 3, 2
	note REST
	jump Song01_Ch3_Loop
Song0D_Ch4:
	len4 $3f
	env 4, EnvMacro_28
	jump Song01_Ch4_Loop
Song01_Ch4:
	len4 $3f
	env 4, EnvMacro_28
	note REST, 5, 2
	note REST
Song01_Ch4_Loop:
	env 4, EnvMacro_28
	gosub 4, Song01_Ch4_Sub
	gosub 4, Song01_Ch4_Sub
	gosub 4, Song01_Ch4_Sub
	gosub 4, Song01_Ch4_Sub
	gosub 4, Song01_Ch4_Sub
	gosub 4, Song01_Ch4_Sub
	gosub 4, Song01_Ch4_Sub
	gosub 4, Song01_Ch4_Sub
	note REST, 5, 1
	env 4, EnvMacro_24
	gosub 4, Song01_Ch4_Sub
	note REST, 5, 1
	note 1, 3, 1
	note 2, 11, 3
	note REST
	note 1
	note 1, 3, 1
	note 2, 11, 3
	note 2
	note 2
	jump Song01_Ch4_Loop
Song01_Ch4_Sub:
	note 1, 3, 1
	note 2, 11, 3
	note REST
	note 1
	note 1, 3, 1
	note 2, 11, 3
	note REST
	note 1
	endsub 4
Song0A_Ch1:
	lengths LengthTable3
	wave Wave3
	master_vol $77
	music_pan $56
	sweep1 $78
	duty1 $bf
	env 1, EnvMacro_08
	pitch 1, PitchMacro_2C
	jump Song02_Ch1_Loop
Song02_Ch1:
	lengths LengthTable2
	wave Wave3
	master_vol $77
	music_pan $56
	sweep1 $78
	duty1 $bf
	env 1, EnvMacro_08
	pitch 1, PitchMacro_2C
	note C_5, 1, 3
	note C_5
	note C_5
	note REST, 10, 1
	note C_5, 1, 3
	note C_5
	note C_5
	note REST, 10, 1
	note As6, 3, 1
Song02_Ch1_Loop:
	note REST, 1, 5
	note F_5
	note A_5
	note C_6
	note F_6
	note REST, 3, 1
	note A_5, 1, 4
	note C_6
	note E_6
	note G_6
	note REST, 3, 1
	note As5, 1, 4
	note D_6
	note F_6
	note A_6
	note REST, 10, 1
	note REST, 4, 1
	note REST, 1, 5
	note G_5
	note As5
	note D_6
	note G_6
	note REST, 3, 1
	note E_5, 1, 4
	note G_5
	note As5
	note C_6
	note REST, 3, 1
	note A_5, 1, 4
	note C_6
	note A_3
	note C_4
	note REST, 10, 1
	note REST, 1, 6
	note F_3
	note REST
	note F_3
	note F_3
	note REST
	note A_5, 0, 1
	note C_6, 1, 1
	note REST, 0, 1
	note REST, 1, 5
	note F_5
	note A_5
	note C_6
	note F_6
	note REST, 3, 1
	note C_6, 1, 4
	note E_6
	note G_6
	note A_6
	note REST, 10, 1
	note REST, 5, 1
	note REST, 1, 5
	note G_5
	note As5
	note D_6
	note F_6
	note REST, 3, 1
	note C_5, 1, 1
	note C_6, 2, 1
	note REST, 3, 1
	note REST, 0, 2
	note F_5
	note A_5, 1, 9
	note As5
	note C_6
	note D_6
	note E_6
	note F_6
	note G_6
	note A_6
	note REST
	note REST, 3, 1
	note F_7, 1, 2
	note REST
	gosub 1, Song02_Ch1_Sub1
	gosub 1, Song02_Ch1_Sub1
	gosub 1, Song02_Ch1_Sub2
	gosub 1, Song02_Ch1_Sub1
	gosub 1, Song02_Ch1_Sub3
	gosub 1, Song02_Ch1_Sub3
	note REST, 1, 8
	note G_3
	note REST
	note G_3
	note G_3
	note REST
	note C_4
	note REST
	note Ds4, 0, 16
	note G_4
	note E_4
	note G_4
	note E_4
	note G_4
	note E_4
	note G_4
	note Ds4
	note Fs4
	note Ds4
	note Fs4
	note Ds4
	note Fs4
	note Ds4
	note Fs4
	note A_3, 0, 8
	note Fs4
	note A_3
	note Fs4
	note A_3
	note Fs4
	note A_3
	note Fs4
	gosub 1, Song02_Ch1_Sub3
	note As3, 0, 10
	note D_4
	note As3
	note D_4
	note As3
	note D_4
	note As3
	note D_4
	note D_6
	note F_6
	note REST, 10, 1
	note REST, 1, 8
	note F_3
	note REST
	note F_3
	note F_3
	note REST
	note As3
	note REST
	gosub 1, Song02_Ch1_Sub1
	gosub 1, Song02_Ch1_Sub1
	gosub 1, Song02_Ch1_Sub2
	gosub 1, Song02_Ch1_Sub1
	note G_3, 0, 8
	note Ds4
	note G_3
	note Ds4
	note G_3
	note Ds4
	note G_3
	note Ds4
	note REST, 4, 1
	note E_3, 0, 8
	note As3
	note E_3
	note As3
	note E_3
	note As3
	note E_3
	note As3
	note A_3, 0, 8
	note C_4
	note A_3
	note C_4
	note A_3
	note C_4
	note A_3
	note C_4
	gosub 1, Song02_Ch1_Sub4
	gosub 1, Song02_Ch1_Sub4
	note C_6, 0, 2
	note F_6
	note REST, 10, 1
	note REST, 3, 1
	gosub 1, Song02_Ch1_Sub1
	note REST, 3, 1
	note F_4, 10, 1
	note F_4, 1, 1
	jump Song02_Ch1_Loop
Song02_Ch1_Sub1:
	note D_3, 0, 8
	note F_3
	note D_3
	note F_3
	note D_3
	note F_3
	note D_3
	note F_3
	endsub 1
Song02_Ch1_Sub2:
	note D_3, 0, 8
	note G_3
	note D_3
	note G_3
	note D_3
	note G_3
	note D_3
	note G_3
	endsub 1
Song02_Ch1_Sub3:
	note D_3, 0, 8
	note Ds3
	note D_3
	note Ds3
	note D_3
	note Ds3
	note D_3
	note Ds3
	endsub 1
Song02_Ch1_Sub4:
	note C_4, 0, 8
	note E_4
	note C_4
	note E_4
	note C_4
	note E_4
	note C_4
	note E_4
	endsub 1
Song0A_Ch2:
	duty2 $bf
	env 2, EnvMacro_14
	pitch 2, PitchMacro_2C
	jump Song02_Ch2_Loop
Song02_Ch2:
	duty2 $bf
	env 2, EnvMacro_14
	pitch 2, PitchMacro_2C
	note REST, 6, 1
	note C_7, 3, 1
Song02_Ch2_Loop:
	note A_4, 1, 4
	note C_5
	note REST
	note A_4
	note D_5, 2, 1
	note A_4, 1, 4
	note C_5
	note REST
	note A_4
	note E_5, 2, 1
	note D_5, 1, 4
	note REST
	note A_4
	note REST
	note REST, 1, 4
	note As4
	note As4
	note G_4
	note REST, 3, 1
	note REST, 10, 1
	note G_5, 1, 1
	note G_7, 0, 4
	note F_7
	note G_7
	note REST
	note REST, 2, 1
	note G_4, 1, 4
	note As4
	note REST
	note G_4
	note E_5, 2, 1
	note G_4, 1, 4
	note As4
	note REST
	note G_4
	note F_5, 2, 1
	note E_5, 1, 8
	note REST
	note A_4
	note REST
	note REST
	note C_5
	note D_5
	note C_5
	note REST, 6, 1
	note A_4, 1, 4
	note C_5
	note REST
	note A_4
	note D_5, 2, 1
	note A_4, 1, 5
	note C_5
	note REST
	note A_4
	note F_5
	note REST, 2, 1
	note F_5, 1, 3
	note G_5
	note F_5
	note D_5, 2, 1
	note REST, 1, 2
	note As4
	note F_6, 0, 2
	note As6
	note REST, 10, 1
	note REST, 4, 1
	note G_4, 1, 4
	note As4
	note REST
	note G_4
	note D_5, 2, 1
	note G_4, 1, 4
	note As4
	note REST
	note G_4
	note E_5, 10, 1
	note F_5, 1, 3
	note G_5
	note F_5
	note REST, 5, 1
	note REST, 2, 1
	note F_5, 1, 4
	note G_5
	note REST
	note F_5
	note G_5, 2, 1
	note F_5, 1, 9
	note G_5
	note REST
	note F_5
	note REST
	note G_5
	note REST
	note D_5
	note Ds5
	note REST, 10, 1
	note C_6, 1, 3
	note G_5
	note D_6
	note Ds6, 10, 1
	note REST, 7, 1
	note REST, 2, 1
	note G_5, 1, 14
	note A_5
	note REST
	note G_5
	note As5
	note REST
	note G_5
	note C_6
	note REST
	note D_6
	note REST
	note Ds6
	note REST
	note C_6
	note F_6, 1, 9
	note REST
	note As6
	note REST
	note REST
	note A_4
	note As4
	note G_4
	note F_4
	note REST, 10, 1
	note REST, 7, 1
	note F_5, 1, 4
	note G_5
	note REST
	note F_5
	note G_5, 2, 1
	note REST, 1, 8
	note G_5
	note G_5
	note F_5
	note G_5
	note REST
	note D_5
	note REST
	note REST, 1, 16
	note G_4
	note C_5
	note Ds4
	note REST
	note G_4
	note C_4
	note D_4
	note Ds4
	note G_3
	note REST
	note G_3
	note E_4
	note G_3
	note REST
	note Fs3
	note REST, 1, 16
	note A_3
	note C_4
	note Ds4
	note REST
	note G_4
	note A_4
	note C_5
	note Ds5
	note D_5
	note REST
	note Ds5
	note REST
	note F_5
	note Ds5
	note C_5
	note D_5, 1, 2
	note As4
	note REST, 10, 1
	note As4, 1, 4
	note A_4
	note As4
	note REST
	note As3, 10, 1
	note REST, 3, 1
	jump Song02_Ch2_Loop
Song0A_Ch3:
	len3 $ff
	env 3, EnvMacro_1A
	pitch 3, PitchMacro_2C
	jump Song02_Ch3_Loop
Song02_Ch3:
	len3 $ff
	env 3, EnvMacro_1A
	pitch 3, PitchMacro_2C
	note Gs4, 1, 3
	note G_4
	note Fs4
	note REST, 10, 1
	note F_4, 1, 3
	note E_4
	note C_4
	note REST, 10, 1
	note REST, 3, 1
Song02_Ch3_Loop:
	note F_3, 1, 4
	note REST
	note F_4
	note REST
	note REST, 3, 1
	note A_4, 2, 1
	note REST, 7, 1
	note G_4, 2, 1
	note REST, 10, 1
	note G_4, 1, 7
	note D_4
	note G_4
	note D_4
	note G_3
	note G_3
	note REST
	note REST, 3, 1
	note C_3, 1, 4
	note REST
	note C_4
	note REST
	note REST, 3, 1
	note E_4, 2, 1
	note REST, 7, 1
	note F_4, 1, 1
	note REST, 3, 1
	note F_4, 1, 8
	note E_4
	note F_4
	note REST
	note E_3
	note REST
	note E_3
	note E_3
	note REST, 10, 1
	note F_3, 1, 16
	note REST
	note F_4
	note REST
	note REST
	note F_3
	note F_3
	note REST
	note F_4
	note REST
	note REST
	note A_4
	note Ds4
	note F_3
	note REST
	note F_3
	note As3, 1, 14
	note As3
	note REST
	note As4
	note REST
	note As4
	note A_4
	note As4
	note REST
	note As3
	note REST
	note As3
	note As3
	note REST
	note G_3, 2, 3
	note REST
	note E_4
	note REST, 3, 1
	note C_4, 2, 1
	note REST, 7, 1
	note D_5, 1, 13
	note C_5
	note REST
	note D_5
	note REST
	note C_5
	note A_4
	note G_4
	note F_4
	note REST
	note REST
	note F_3
	note F_3
	note REST, 10, 1
	note As4, 2, 8
	note REST
	note F_4
	note REST
	note REST
	note B_4
	note G_4
	note REST
	note REST, 1, 4
	note C_5
	note G_4
	note C_5
	note REST, 3, 1
	note REST, 1, 5
	note C_4
	note REST
	note C_4
	note C_4
	note REST, 10, 1
	note C_5, 2, 8
	note REST
	note G_4
	note REST
	note REST
	note F_4
	note A_4
	note REST
	note REST, 3, 1
	note As3, 2, 1
	note REST, 10, 1
	note B_3, 1, 4
	note REST
	note As3
	note As3
	note REST, 10, 1
	note As4, 2, 5
	note REST
	note F_4
	note REST
	note B_4
	note REST, 3, 1
	note REST, 1, 2
	note B_3
	note C_4, 2, 3
	note REST
	note C_3
	note REST, 4, 1
	note E_3, 2, 1
	note G_3, 1, 1
	note REST, 10, 1
	note F_4, 1, 2
	note REST
	note REST, 7, 1
	note G_3, 1, 1
	note REST, 10, 1
	note REST, 3, 1
	note As3, 1, 2
	note REST
	note REST, 7, 1
	note As3, 10, 1
	note As3, 1, 1
	jump Song02_Ch3_Loop
Song0B_Ch1:
	lengths LengthTable4
	wave Wave1
	master_vol $77
	music_pan $de
	sweep1 $78
	duty1 $3f
	env 1, EnvMacro_08
	pitch 1, PitchMacro_2C
	jump Song03_Ch1_Loop
Song03_Ch1:
	lengths LengthTable3
	wave Wave1
	master_vol $77
	music_pan $de
	sweep1 $78
	duty1 $3f
	env 1, EnvMacro_08
	pitch 1, PitchMacro_2C
	note E_4, 3, 1
	note REST, 2, 2
	note F_4
	note REST, 3, 1
	note Fs4, 2, 6
	note G_4
	note Gs4
	note A_4
	note As4
	note B_4
	note REST, 4, 1
	duty1 $7f
Song03_Ch1_Loop:
	gosub 1, Song03_Ch1_Sub1
	gosub 1, Song03_Ch1_Sub1
	note REST, 2, 1
	note G_3, 1, 2
	note C_4
	note E_4, 3, 1
	note C_4, 2, 5
	note G_3
	note C_4
	note E_4
	note REST
	note A_3, 1, 2
	note D_4
	note F_4, 3, 1
	note D_4, 2, 5
	note A_3
	note F_3
	note E_3
	note D_3
	note A_3, 1, 2
	note D_4
	note F_4, 3, 1
	note Cs4, 2, 5
	note A_4
	note Cs4
	note F_4
	note REST
	note A_4, 1, 2
	note C_4
	note F_4, 3, 1
	note C_4, 2, 5
	note A_3
	note C_4
	note F_4
	note REST
	note A_3, 1, 2
	note D_4
	note F_4, 3, 1
	note B_3, 2, 5
	note C_4
	note B_3
	note A_3
	note REST
	note G_3, 1, 2
	note C_4
	note E_4, 3, 1
	note C_4, 2, 5
	note C_4
	note D_4
	note E_4
	note REST
	note A_4, 1, 6
	note C_4
	note F_4
	note E_4
	note D_4
	note C_4
	note D_4, 2, 2
	note E_4
	note F_4, 3, 1
	note E_4, 2, 3
	note B_3
	note G_4
	note E_4, 3, 1
	note C_4, 2, 3
	note D_4
	note E_4
	note E_4, 1, 8
	note E_4
	note D_4
	note E_4
	note F_4
	note E_4
	note D_4
	note C_4
	note B_3, 2, 5
	note C_4
	note D_4
	note C_4
	note REST
	note C_4, 1, 2
	note D_4
	note E_4, 2, 7
	note F_4
	note E_4
	note C_4
	note D_4
	note E_4
	note REST
	note A_3, 1, 6
	note C_4
	note F_4
	note E_4
	note D_4
	note C_4
	note D_4, 2, 2
	note E_4
	note F_4, 3, 1
	note E_4, 2, 3
	note B_3
	note G_4
	note E_4, 3, 1
	note E_4, 2, 4
	note F_4
	note G_4
	note REST
	note F_4, 1, 2
	note E_4
	note D_4, 3, 1
	note G_4, 2, 3
	note Fs4
	note F_4
	note E_4, 8, 1
	note REST, 8, 1
	note F_4, 2, 3
	note A_4
	note C_5
	note REST, 8, 1
	note E_4, 2, 3
	note G_4
	note C_5
	note REST, 8, 1
	note A_5, 1, 2
	note B_5
	note C_6, 3, 1
	note B_5, 2, 8
	note G_5
	note A_5
	note B_5
	note C_6
	note B_5
	note A_5
	note G_5
	note REST, 8, 1
	note F_4, 2, 3
	note A_4
	note C_5
	note REST, 8, 1
	note E_4, 2, 3
	note G_4
	note C_5
	note REST, 8, 1
	note D_4, 1, 2
	note E_4
	note Fs4, 3, 1
	note F_4, 2, 4
	note G_4
	note A_4
	note C_5
	note G_4, 5, 1
	gosub 1, Song03_Ch1_Sub2
	gosub 1, Song03_Ch1_Sub2
	note B_4, 3, 2
	note REST
	jump Song03_Ch1_Loop
Song03_Ch1_Sub1:
	note REST, 2, 1
	note G_3, 1, 2
	note C_4
	note E_4, 3, 1
	note B_3, 2, 4
	note G_3
	note B_3
	note E_4
	endsub 1
Song03_Ch1_Sub2:
	note B_4, 0, 8
	note C_5
	note B_4
	note C_5
	note B_4
	note C_5
	note B_4
	note C_5
	endsub 1
Song0B_Ch2:
	duty2 $3f
	env 2, EnvMacro_00
	pitch 2, PitchMacro_2C
	jump Song03_Ch2_Loop
Song03_Ch2:
	duty2 $3f
	env 2, EnvMacro_08
	pitch 2, PitchMacro_2C
	note G_4, 2, 1
	note G_4, 1, 2
	note Fs4
	note G_4, 2, 2
	note Gs4
	note Gs4, 1, 2
	note G_4
	duty2 $7f
	note Gs4, 2, 11
	note A_4
	note As4
	note B_4
	note C_5
	note Cs5
	note D_5
	note G_5
	note G_4
	note C_5
	note D_5
Song03_Ch2_Loop:
	note E_5, 3, 1
	note E_5, 2, 6
	note F_5
	note E_5
	note D_5
	note C_5
	note D_5
	note E_5, 4, 1
	note REST, 2, 4
	note G_4
	note C_5
	note D_5
	note E_5, 3, 1
	note E_5, 2, 5
	note F_5
	note E_5
	note Ds5
	note E_5
	note F_5, 6, 1
	note A_4, 2, 3
	note D_5
	note E_5
	note F_5, 3, 1
	note F_5, 2, 6
	note G_5
	note F_5
	note E_5
	note D_5
	note E_5
	note F_5, 4, 1
	note REST, 2, 4
	note A_4
	note D_5
	note E_5
	note F_5, 3, 1
	note E_5, 2, 1
	note F_5, 3, 1
	note A_5, 2, 3
	note G_5
	note F_5
	note E_5, 4, 1
	note REST, 2, 4
	note E_5
	note F_5
	note G_5
	note A_5, 3, 2
	note A_5
	note B_5, 7, 1
	note A_5, 2, 4
	note G_5
	note B_5
	note D_6
	note C_6, 3, 1
	note E_5, 2, 11
	note F_5
	note G_5
	note A_5
	note G_5
	note F_5
	note E_5
	note D_5
	note A_5
	note B_5
	note A_5
	note G_5, 4, 1
	note REST, 2, 4
	note E_5
	note F_5
	note G_5
	note A_5, 3, 2
	note A_5
	note B_5, 7, 1
	note A_5, 2, 4
	note G_5
	note B_5
	note D_6
	note C_6, 3, 1
	note C_6, 2, 10
	note D_6
	note E_6
	note E_6
	note F_6
	note A_5
	note C_6
	note B_5
	note A_5
	note B_5
	note C_6, 8, 1
	note REST, 2, 4
	note C_5
	note B_4
	note As4
	note A_4, 2, 16
	note C_5
	note F_5
	note A_5
	note REST
	note C_5
	note B_4
	note A_4
	note G_4
	note C_5
	note E_5
	note G_5
	note REST
	note G_4
	note F_4
	note E_4
	note F_4, 3, 1
	note G_4, 2, 6
	note F_4
	note F_4
	note E_4
	note D_4
	note F_4
	note E_4, 1, 6
	note C_4
	note F_4
	note D_4
	note Fs4
	note Ds4
	note E_4, 2, 16
	note REST
	note C_5
	note B_4
	note As4
	note A_4
	note C_5
	note F_5
	note A_5
	note REST
	note C_5
	note B_4
	note A_4
	note G_4
	note C_5
	note E_5
	note G_5, 2, 12
	note REST
	note E_5
	note F_5
	note G_5
	note A_5
	note B_5
	note C_6
	note D_6
	note E_6
	note A_6
	note E_6
	note D_6, 5, 1
	note REST, 2, 1
	gosub 2, Song03_Ch2_Sub
	gosub 2, Song03_Ch2_Sub
	note G_5, 2, 4
	note G_4
	note C_5
	note D_5
	jump Song03_Ch2_Loop
Song03_Ch2_Sub:
	note G_5, 0, 8
	note A_5
	note G_5
	note A_5
	note G_5
	note A_5
	note G_5
	note A_5
	endsub 2
Song0B_Ch3:
	len3 $ff
	env 3, EnvMacro_1A
	pitch 3, PitchMacro_2C
	jump Song03_Ch3_Loop
Song03_Ch3:
	len3 $ff
	env 3, EnvMacro_1A
	pitch 3, PitchMacro_2C
	note C_5, 3, 1
	note REST, 2, 2
	note Cs5
	note REST, 3, 1
	note D_4, 2, 6
	note Ds4
	note E_5
	note F_5
	note Fs5
	note G_5
	note REST, 3, 2
	note E_5
Song03_Ch3_Loop:
	note C_4, 7, 2
	note G_3
	note G_3, 3, 1
	note C_4, 7, 2
	note G_3
	note G_3, 3, 1
	note C_4, 7, 2
	note G_3
	note C_4, 3, 1
	note D_4, 7, 2
	note A_3
	note A_3, 3, 1
	note D_4, 7, 2
	note A_3
	note A_3, 3, 1
	note D_4, 7, 2
	note A_3
	note A_3, 3, 1
	note D_4, 7, 1
	note G_3, 3, 1
	note G_3, 2, 3
	note A_3
	note B_3
	note C_4, 7, 2
	note G_3
	note C_4, 3, 1
	note F_3, 7, 2
	note B_3
	note B_3, 3, 1
	note F_3, 7, 2
	note A_3
	note A_3, 3, 1
	note D_3, 7, 2
	note G_3
	note G_3, 3, 1
	note C_4, 3, 1
	note G_3, 2, 1
	note C_4, 3, 1
	note G_3, 2, 1
	note C_4, 3, 1
	note F_3, 7, 2
	note B_3
	note B_3, 3, 1
	note F_3, 7, 2
	note A_3
	note A_3, 3, 1
	note D_3, 3, 2
	note REST
	note G_3, 2, 3
	note A_3
	note G_3
	note C_3, 3, 1
	note A_3, 3, 1
	note G_3, 2, 1
	note C_4, 3, 3
	note REST
	note F_4
	note REST, 6, 1
	note E_4, 3, 1
	note REST, 6, 1
	note D_4, 7, 2
	note G_4
	note G_3, 3, 1
	note C_4, 7, 1
	note G_3, 2, 5
	note C_4
	note C_4
	note D_4
	note E_4
	note F_4, 3, 1
	note REST, 6, 1
	note E_4, 3, 1
	note REST, 6, 1
	note D_4, 7, 2
	note E_4
	note Fs4, 3, 1
	note G_4, 7, 1
	note G_4, 2, 1
	note F_4, 7, 1
	note F_4, 2, 1
	note E_4, 7, 1
	note E_4, 2, 1
	note D_4, 7, 1
	note G_4, 2, 1
	jump Song03_Ch3_Loop
Song0B_Ch4:
	len4 $3f
	env 4, EnvMacro_28
	jump Song03_Ch4_Loop
Song03_Ch4:
	len4 $3f
	env 4, EnvMacro_28
	note REST, 5, 1
	note REST, 6, 1
	note 2, 1, 2
	note 2
	note 2, 2, 1
Song03_Ch4_Loop:
	gosub 4, Song03_Ch4_Sub
	gosub 4, Song03_Ch4_Sub
	gosub 4, Song03_Ch4_Sub
	gosub 4, Song03_Ch4_Sub
	gosub 4, Song03_Ch4_Sub
	gosub 4, Song03_Ch4_Sub
	gosub 4, Song03_Ch4_Sub
	gosub 4, Song03_Ch4_Sub
	gosub 4, Song03_Ch4_Sub
	gosub 4, Song03_Ch4_Sub
	gosub 4, Song03_Ch4_Sub
	gosub 4, Song03_Ch4_Sub
	gosub 4, Song03_Ch4_Sub
	gosub 4, Song03_Ch4_Sub
	note 1, 3, 1
	note REST, 4, 1
	note 2, 1, 2
	note 2
	note 2, 2, 2
	note 1
	note 2, 1, 4
	note 2
	note REST
	note 2
	note 2, 2, 1
	note 1, 3, 2
	note REST
	gosub 4, Song03_Ch4_Sub
	gosub 4, Song03_Ch4_Sub
	gosub 4, Song03_Ch4_Sub
	gosub 4, Song03_Ch4_Sub
	gosub 4, Song03_Ch4_Sub
	gosub 4, Song03_Ch4_Sub
	gosub 4, Song03_Ch4_Sub
	gosub 4, Song03_Ch4_Sub
	note 1, 2, 1
	note 2, 1, 4
	note 2
	note REST
	note 2
	note 2, 2, 1
	note 1, 3, 1
	note 2, 1, 2
	note 2
	note 2, 2, 1
	jump Song03_Ch4_Loop
Song03_Ch4_Sub:
	note 1, 2, 1
	note 2, 1, 2
	note 2
	note 2, 2, 6
	note 1
	note 2
	note 2
	note 1
	note 2
	endsub 4
Song0C_Ch1:
	gosub 1, Song04_Ch1_Sub
	jump Song05_Ch1
Song04_Ch1:
	gosub 1, Song04_Ch1_Sub
	endch 1
Song04_Ch1_Sub:
	lengths LengthTable2
	wave Wave1
	master_vol $77
	music_pan $de
	sweep1 $78
	duty1 $bf
	env 1, EnvMacro_00
	pitch 1, PitchMacro_2C
	note Ds6, 1, 1
	note Ds6, 2, 1
	note Ds5, 1, 1
	note Ds5, 2, 2
	note Ds4
	note REST, 8, 1
	note D_5, 2, 1
	note Cs5, 3, 2
	note REST
	endsub 1
Song0C_Ch2:
	gosub 2, Song04_Ch2_Sub
	jump Song05_Ch2
Song04_Ch2:
	gosub 2, Song04_Ch2_Sub
	endch 2
Song04_Ch2_Sub:
	duty2 $bf
	env 2, EnvMacro_00
	pitch 2, PitchMacro_2C
	note E_6, 1, 1
	note E_6, 2, 1
	note E_5, 1, 1
	note E_5, 2, 2
	note E_4
	note A_4, 0, 16
	note Cs4
	note B_4
	note E_4
	note Cs5
	note A_4
	note E_5
	note Gs4
	note Fs5
	note A_4
	note Gs5
	note B_4
	note A_5
	note D_5
	note D_6
	note Fs5
	note E_5, 2, 2
	note Gs5
	note A_5, 3, 2
	note REST
	endsub 2
Song0C_Ch3:
	gosub 3, Song04_Ch3_Sub
	jump Song05_Ch3
Song04_Ch3:
	gosub 3, Song04_Ch3_Sub
	endch 3
Song04_Ch3_Sub:
	len3 $ff
	env 3, EnvMacro_18
	pitch 3, PitchMacro_2C
	note REST, 4, 1
	note A_4, 1, 8
	note Gs4
	note A_4
	note E_4
	note D_4
	note E_4
	note Fs4
	note Gs4
	note A_4, 2, 2
	note E_4
	note A_3, 3, 2
	note REST
	endsub 3
Song04_Ch4:
	len4 $3f
	env 4, EnvMacro_24
	note REST, 3, 1
	note 2, 1, 4
	note 2
	note 2
	note 2
	note 2, 2, 1
	note 2, 1, 7
	note 2
	note 2
	note 2
	note 2
	note 2
	note 2
	note 2, 2, 1
	note 2, 1, 1
	note 2, 0, 4
	note 2
	note 2
	note 2
	note 2, 1, 2
	note 2
	endch 4
Song05_Ch1:
	lengths LengthTable1
	wave Wave2
	master_vol $77
	music_pan $16
	sweep1 $78
	duty1 $7f
	env 1, EnvMacro_08
	pitch 1, PitchMacro_2C
Song05_Ch1_Loop:
	note REST, 8, 1
	note Gs6, 2, 2
	note Gs6
	note REST, 6, 1
	note Fs6, 2, 2
	note Fs6
	note REST, 2, 1
	jump Song05_Ch1_Loop
Song05_Ch2:
	duty2 $7f
	env 2, EnvMacro_08
	pitch 2, PitchMacro_2C
Song05_Ch2_Loop:
	note D_5, 2, 1
	note A_4, 1, 2
	note A_4
	note As4, 2, 7
	note A_4
	note D_5
	note REST
	note REST
	note D_4
	note G_4
	note D_4, 1, 2
	note D_4
	note F_4, 2, 3
	note Fs4
	note G_4
	note REST, 3, 1
	note A_4, 1, 2
	note A_4
	jump Song05_Ch2_Loop
Song05_Ch3:
	len3 $ff
	env 3, EnvMacro_1E
	pitch 3, PitchMacro_2C
Song05_Ch3_Loop:
	note REST, 8, 1
	note A_6, 2, 2
	note A_6
	note REST, 6, 1
	note G_6, 2, 2
	note G_6
	note REST, 2, 1
	jump Song05_Ch3_Loop
Song06_Ch1:
	lengths LengthTable2
	wave Wave3
	master_vol $77
	music_pan $de
	sweep1 $78
	duty1 $bf
	env 1, EnvMacro_00
	pitch 1, PitchMacro_2C
	note F_7, 1, 1
	note F_7, 10, 1
	note REST, 3, 1
	note REST, 0, 1
	note Fs5, 1, 7
	note A_5
	note D_6
	note A_5
	note Fs5
	note A_5
	note B_5
	note Cs6, 0, 1
	note Fs6, 4, 1
	endch 1
Song06_Ch2:
	duty2 $bf
	env 2, EnvMacro_00
	pitch 2, PitchMacro_2C
	note Fs7, 1, 1
	note Fs7, 10, 1
	note REST, 3, 1
	note A_5, 1, 8
	note D_6
	note Cs6
	note D_6
	note E_6
	note Fs6
	note G_6
	note E_6
	note A_6, 4, 1
	endch 2
Song06_Ch3:
	len3 $ff
	env 3, EnvMacro_18
	pitch 3, PitchMacro_2C
	note REST, 5, 1
	note D_6, 4, 1
	endch 3
Song06_Ch4:
	len4 $3f
	env 4, EnvMacro_24
	note 3, 1, 1
	note 3, 10, 1
	note REST, 1, 1
	note 3, 1, 2
	note 3
	note 3, 0, 2
	note 3
	gosub 4, Song06_Ch4_Sub
	gosub 4, Song06_Ch4_Sub
	gosub 4, Song06_Ch4_Sub
	gosub 4, Song06_Ch4_Sub
	endch 4
Song06_Ch4_Sub:
	note 3, 0, 8
	note 3
	note 3
	note 3
	note 3
	note 3
	note 3
	note 3
	endsub 4
Song07_Ch1:
	lengths LengthTable2
	wave Wave3
	master_vol $77
	music_pan $de
	sweep1 $78
	duty1 $7f
	env 1, EnvMacro_08
	pitch 1, PitchMacro_2C
Song07_Ch1_Loop:
	gosub 1, Song07_Ch1_Sub
	note Gs4, 2, 2
	note B_4
	note Cs5, 0, 4
	note REST
	note E_5
	note REST
	note A_5, 2, 1
	gosub 1, Song07_Ch1_Sub
	note Gs4, 2, 2
	note B_4
	note Cs5, 1, 2
	note REST
	duty1 $bf
	note A_3, 2, 1
	jump Song07_Ch1_Loop
Song07_Ch1_Sub:
	note REST, 1, 8
	note Cs5
	note REST
	note Cs5
	note REST
	note D_5
	note REST
	note D_5
	endsub 1
Song07_Ch2:
	duty2 $ff
	env 2, EnvMacro_00
	pitch 2, PitchMacro_2C
Song07_Ch2_Loop:
	gosub 2, Song07_Ch2_Sub
	note E_5, 2, 2
	note Gs5
	note A_5, 0, 4
	note REST
	note B_5
	note REST
	note Cs6, 2, 1
	gosub 2, Song07_Ch2_Sub
	note E_5, 2, 2
	note Gs5
	note A_5, 1, 2
	note REST
	note A_3, 2, 1
	jump Song07_Ch2_Loop
Song07_Ch2_Sub:
	note REST, 1, 8
	note E_5
	note REST
	note E_4
	note REST
	note Fs5
	note REST
	note Fs5
	endsub 2
Song07_Ch3:
	len3 $ff
	env 3, EnvMacro_18
	pitch 3, PitchMacro_2C
Song07_Ch3_Loop:
	gosub 3, Song07_Ch3_Sub
	note B_4, 2, 3
	note E_4
	note A_4
	note REST, 1, 1
	note Ds5, 0, 2
	note E_5
	gosub 3, Song07_Ch3_Sub
	note B_4, 1, 4
	note E_4
	note A_4
	note REST
	note A_3, 2, 1
	jump Song07_Ch3_Loop
Song07_Ch3_Sub:
	note A_4, 1, 8
	note REST
	note E_4
	note REST
	note A_4
	note REST
	note D_4
	note REST
	endsub 3
Song07_Ch4:
	len4 $3f
	env 4, EnvMacro_24
Song07_Ch4_Loop:
	gosub 4, Song07_Ch4_Sub
	gosub 4, Song07_Ch4_Sub
	gosub 4, Song07_Ch4_Sub
	note 3, 2, 4
	note 3
	note 3
	note 3
	jump Song07_Ch4_Loop
Song07_Ch4_Sub:
	note 3, 2, 1
	note 3, 1, 2
	note 3
	note 3, 2, 1
	note 3, 1, 1
	note 3, 0, 2
	note 3
	endsub 4
Song08_Ch1:
	lengths LengthTable3
	wave Wave1
	master_vol $77
	music_pan $56
	sweep1 $78
	duty1 $3f
	env 1, EnvMacro_00
	pitch 1, PitchMacro_2C
	note REST, 2, 1
	note Cs4, 1, 2
	note REST
	note C_4, 3, 1
	note B_3, 10, 2
	note As3
	note A_4, 1, 2
	note REST
Song08_Ch1_Loop:
	note REST, 4, 1
	note F_4, 1, 5
	note G_4
	note A_4
	note C_5
	note F_5
	note REST, 10, 1
	note G_4, 1, 5
	note A_4
	note As4
	note Ds5
	note G_5
	note REST, 10, 1
	note REST, 3, 1
	note G_3, 1, 5
	note A_3
	note As3
	note D_4
	note As4
	note REST, 10, 1
	note REST, 3, 1
	note F_4, 1, 4
	note As4
	note D_5
	note REST
	note REST, 3, 1
	note E_4, 1, 8
	note E_4
	note E_4
	note REST
	note F_4
	note F_4
	note F_4
	note REST
	note Fs4, 10, 1
	note G_4, 1, 1
	note Gs4, 10, 1
	note A_4, 1, 1
	jump Song08_Ch1_Loop
Song08_Ch2:
	duty2 $bf
	env 2, EnvMacro_00
	pitch 2, PitchMacro_2C
	note REST, 2, 1
	note Cs4, 1, 2
	note REST
	note D_4, 3, 1
	note Ds4, 10, 2
	note E_4
	note F_4, 1, 2
	note REST
Song08_Ch2_Loop:
	note F_4, 1, 14
	note REST
	note D_4
	note REST
	note C_4
	note REST
	note REST
	note F_4
	note REST
	note F_4
	note D_4
	note REST
	note C_4
	note REST
	note F_4, 10, 1
	note REST, 1, 13
	note Ds4
	note REST
	note C_4
	note REST
	note REST
	note F_4
	note REST
	note F_4
	note Ds4
	note REST
	note C_4
	note REST
	note F_4, 2, 1
	note REST, 1, 6
	note F_4
	note D_4
	note REST
	note As3
	note REST
	note F_3, 2, 1
	note REST, 1, 8
	note F_4
	note D_4
	note REST
	note As3
	note REST
	note F_4
	note REST
	note G_4, 1, 8
	note G_4
	note G_4
	note REST
	note Gs4
	note Gs4
	note Gs4
	note REST
	note A_4, 10, 1
	note As4, 1, 1
	note B_4, 10, 1
	note C_5, 1, 1
	jump Song08_Ch2_Loop
Song08_Ch3:
	len3 $ff
	env 3, EnvMacro_18
	pitch 3, PitchMacro_2C
	note REST, 2, 1
	note F_4, 1, 2
	note REST
	note Fs4, 3, 1
	note G_4, 10, 2
	note Gs4
	note B_4, 1, 2
	note REST
Song08_Ch3_Loop:
	note F_3, 1, 16
	note REST
	note F_4
	note F_4
	note F_3
	note REST
	note F_4
	note F_4
	note A_3
	note REST
	note A_4
	note A_4
	note A_3
	note REST
	note A_4
	note A_4
	note Ds3, 1, 16
	note REST
	note Ds4
	note Ds4
	note Ds3
	note REST
	note Ds4
	note Ds4
	note G_3
	note REST
	note G_4
	note G_4
	note G_3
	note REST
	note G_4
	note G_4
	note As3, 1, 16
	note REST
	note As4
	note As4
	note As3
	note REST
	note As4
	note As4
	note D_4
	note REST
	note D_5
	note D_5
	note D_4
	note REST
	note D_5
	note D_5
	note C_4, 1, 8
	note C_5
	note C_4
	note REST
	note Cs4
	note Cs5
	note Cs4
	note REST
	note D_4, 10, 1
	note Ds4, 1, 1
	note E_4, 10, 1
	note C_4, 1, 1
	jump Song08_Ch3_Loop
Song09_Ch1:
	lengths LengthTable3
	wave Wave3
	master_vol $77
	music_pan $56
	sweep1 $78
	duty1 $bf
	env 1, EnvMacro_00
	pitch 1, PitchMacro_2C
	note B_4, 2, 13
	note REST
	note B_4
	note REST
	note As4
	note As4
	note REST
	note A_4
	note REST
	note A_4
	note REST
	note A_4
	note Fs4
	note REST, 7, 1
Song09_Ch1_Loop:
	gosub 1, Song09_Ch1_Sub
	note F_4, 10, 1
	note Fs4, 1, 1
	note G_4, 10, 1
	note A_4, 1, 1
	note F_4, 10, 1
	note Fs4, 1, 1
	note G_4, 10, 1
	note A_4, 1, 1
	note F_4, 10, 1
	note Fs4, 1, 1
	note G_4, 10, 1
	note A_4, 1, 1
	note REST, 10, 1
	note As5, 3, 1
	note A_5, 1, 1
	gosub 1, Song09_Ch1_Sub
	note E_4, 10, 1
	note F_4, 1, 1
	note Fs4, 10, 1
	note G_4, 1, 1
	note E_5, 2, 2
	note REST
	note A_4, 10, 1
	note B_4, 1, 1
	note C_5, 10, 1
	note Cs5, 1, 1
	note Fs5, 2, 1
	note REST, 8, 1
	note E_4, 10, 1
	note F_4, 1, 1
	note Fs4, 10, 1
	note G_4, 1, 1
	note E_5, 10, 1
	note G_4, 1, 1
	note F_4, 10, 1
	note E_4, 1, 1
	note D_4, 10, 1
	note E_5, 1, 1
	note Fs5, 10, 1
	note Fs5, 1, 1
	note REST, 4, 1
	jump Song09_Ch1_Loop
Song09_Ch1_Sub:
	note G_4, 10, 1
	note A_4, 1, 1
	note As4, 10, 1
	note B_4, 1, 1
	note G_4, 10, 1
	note A_4, 1, 1
	note As4, 10, 1
	note B_4, 1, 1
	note G_4, 10, 1
	note A_4, 1, 1
	note As4, 10, 1
	note B_4, 1, 1
	note C_5, 10, 1
	note B_4, 1, 1
	note A_4, 10, 1
	note G_4, 1, 1
	endsub 1
Song09_Ch2:
	duty2 $bf
	env 2, EnvMacro_00
	pitch 2, PitchMacro_2C
	note D_5, 2, 14
	note REST
	note D_5
	note REST
	note Cs5
	note Cs5
	note REST
	note C_5
	note REST
	note C_5
	note REST
	note C_5
	note A_4
	note REST
	note D_4, 3, 1
Song09_Ch2_Loop:
	gosub 2, Song09_Ch2_Sub
	note A_4, 10, 1
	note As4, 1, 1
	note B_4, 10, 1
	note C_5, 1, 1
	note A_4, 10, 1
	note As4, 1, 1
	note B_4, 10, 1
	note C_4, 1, 1
	note A_4, 10, 1
	note As4, 1, 1
	note B_4, 10, 1
	note C_4, 1, 1
	note REST, 10, 1
	note C_6, 3, 1
	note C_6, 1, 1
	gosub 2, Song09_Ch2_Sub
	note C_5, 10, 1
	note D_5, 1, 1
	note Ds5, 10, 1
	note E_5, 1, 1
	note G_5, 2, 2
	note REST
	note Fs5, 10, 1
	note G_5, 1, 1
	note G_5, 10, 1
	note A_5, 1, 1
	note D_6, 2, 1
	note REST, 8, 1
	note C_5, 10, 1
	note D_5, 1, 1
	note Ds5, 10, 1
	note E_5, 1, 1
	note G_5, 10, 1
	note E_5, 1, 1
	note D_5, 10, 1
	note C_5, 1, 1
	note Fs5, 10, 1
	note G_5, 1, 1
	note A_5, 10, 1
	note D_6, 1, 1
	note REST, 3, 1
	note B_5, 0, 8
	note C_6
	note D_6
	note B_5
	note C_6
	note D_6
	note C_6
	note D_6
	jump Song09_Ch2_Loop
Song09_Ch2_Sub:
	note B_4, 10, 1
	note C_5, 1, 1
	note Cs5, 10, 1
	note D_5, 1, 1
	note B_4, 10, 1
	note C_5, 1, 1
	note Cs5, 10, 1
	note D_5, 1, 1
	note B_4, 10, 1
	note C_5, 1, 1
	note Cs5, 10, 1
	note D_5, 1, 1
	note E_5, 10, 1
	note D_5, 1, 1
	note C_5, 10, 1
	note B_4, 1, 1
	endsub 2
Song09_Ch3:
	len3 $ff
	env 3, EnvMacro_18
	pitch 3, PitchMacro_2C
	note D_3, 2, 14
	note REST
	note D_3
	note REST
	note D_3
	note REST
	note D_3
	note REST
	note D_3
	note REST
	note D_3
	note REST
	note D_3
	note REST
	note F_3, 3, 1
Song09_Ch3_Loop:
	gosub 3, Song09_Ch3_Sub
	note F_3, 3, 1
	note REST, 10, 1
	note C_3, 3, 1
	note REST, 1, 1
	note REST, 3, 2
	note F_3
	note REST, 10, 1
	note C_3, 2, 1
	note REST, 2, 1
	note C_4, 9, 1
	gosub 3, Song09_Ch3_Sub
	note C_3, 3, 1
	note REST, 10, 2
	note G_3
	note REST, 2, 1
	note D_3, 3, 1
	note REST, 10, 2
	note Fs3
	note REST, 2, 5
	note Fs3
	note REST
	note Fs3
	note REST
	note C_3, 3, 1
	note REST, 10, 2
	note G_3
	note REST, 2, 3
	note E_3
	note REST
	note D_3, 10, 1
	note E_3, 1, 1
	note Fs3, 10, 1
	note A_3, 1, 1
	note REST, 4, 1
	jump Song09_Ch3_Loop
Song09_Ch3_Sub:
	note G_3, 3, 1
	note REST, 10, 1
	note D_3, 3, 1
	note REST, 9, 1
	note G_3, 3, 1
	note REST, 10, 1
	note D_3, 3, 1
	note REST, 9, 1
	endsub 3
	ds $41b, $ff
