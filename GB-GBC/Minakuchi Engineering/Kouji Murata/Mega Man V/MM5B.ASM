;Mega Man V audio disassembly (bank 2)
;Disassembly by Will Trowbridge & Claude

SECTION "Audio 2", ROMX[AudioROM], BANK[$2]

	jp Audio2_PlayAudio
	jp Audio2_LoadSong
	jp Audio2_InitSound

	;Game-specific function
	jp Audio2_SetStageMus

Audio2_SetStageMus:
	ret

Audio2_SongTab:
	;Percussion
	dw Audio2_Perc_Empty
	dw Audio2_Perc01
	dw Audio2_Perc02
	dw Audio2_Perc03
	dw Audio2_Perc04
	dw Audio2_Perc05
	dw Audio2_Perc06
	dw Audio2_Perc07
	dw Audio2_Perc08
	dw Audio2_Perc09
	dw Audio2_FadeOutTrack
	;SFX
	dw Audio2_SFXEmpty1
	dw Audio2_SFXEmpty2
	dw Audio2_SFX_Shot
	dw Audio2_SFX_ChargeShotSmall
	dw Audio2_SFX_ChargeShotLarge
	dw Audio2_SFX_Charge
	dw Audio2_SFX_Land
	dw Audio2_SFX_ExtraLife
	dw Audio2_SFX_Hurt
	dw Audio2_SFX_PlayerExplode
	dw Audio2_SFX_EnemyHit
	dw Audio2_SFX_BossExplode
	dw Audio2_SFX_Health
	dw Audio2_SFX_Shing
	dw Audio2_SFX_Select
	dw Audio2_SFX_Pause
	dw Audio2_SFX_TeleportIn
	dw Audio2_SFX_TeleportOut
	dw Audio2_SFX_Deflect
	dw Audio2_SFX_Door
	dw Audio2_SFX_Explode
	dw Audio2_SFX_Splash
	dw Audio2_SFX_WilyUFO
	dw Audio2_SFX_Error
	dw Audio2_SFX_Accept
	dw Audio2_SFX_Text
	dw Audio2_SFX_FortressExplode
	dw Audio2_SFX_RainFlush
	dw Audio2_SFX_Helicopter
	dw Audio2_SFX_Cannon
	dw Audio2_SFX_GetWeapon
	dw Audio2_SFX_Stomp
	dw Audio2_SFX_WilyMachineExplode
	dw Audio2_SFX_WilyTankMissile
	dw Audio2_SFX_ProtoMan
	dw Audio2_SFX_BigShot1
	dw Audio2_SFX_BigShot2
	dw Audio2_SFX_ShotAlt
	dw Audio2_SFX_ChargeAlt1
	dw Audio2_SFX_ChargeAlt2
	dw Audio2_SFX_ChargeAlt3
	dw Audio2_SFX_GetWeaponAlt
	dw Audio2_SFX_RushSpaceshipAccel
	dw Audio2_SFX_RushSpaceshipBlast
	dw Audio2_SFX_RushSpaceshipMotor
	dw Audio2_SFX_SuperMegaBuster
	dw Audio2_SFX_Tango
	dw Audio2_SFX_BreakDash
	dw Audio2_SFX_ElectricShock1
	dw Audio2_SFX_ElectricShock2
	dw Audio2_SFX_PhotonMissile
	dw Audio2_SFX_GrabBuster
	dw Audio2_SFX_SaltWater
	dw Audio2_SFX_BubbleBomb
	dw Audio2_SFX_SpecialWeapon
	dw Audio2_SFX_WilyStarExplode
	dw Audio2_SFX_EnemyShot
	dw Audio2_SFX_TimeFreeze
	dw Audio2_SFX_TeleportOutAlt
	dw Audio2_SFX_BubbleEnemy
	dw Audio2_SFX_TangoHit
	dw Audio2_Perc06
	dw Audio2_Perc06
	dw Audio2_Perc06
	dw Audio2_Perc06
	dw Audio2_SFX_SparkChaser1
	dw Audio2_SFX_SparkChaser2
	dw Audio2_SFX_BlackHole1
	dw Audio2_SFX_BlackHole2
	dw Audio2_SFX_ExplodeBlast
	dw Audio2_SFX_Laser
	dw Audio2_SFX_PlatformExplode
	dw Audio2_Perc06
	dw Audio2_Perc06
	dw Audio2_Perc06
	dw Audio2_Perc06
	dw Audio2_Perc06
	dw Audio2_Perc06
	dw 0				;Empty - use bank 1
	dw Audio2_Perc06
	;Music
	dw 0
	dw 0
	dw 0
	dw 0
	dw 0
	dw 0
	dw 0
	dw 0
	dw 0
	dw 0
	dw 0
	dw 0
	dw 0
	dw Audio2_Perc06
	dw Audio2_Perc06
	dw Audio2_Perc06
	dw Audio2_Perc06
	dw 0
	dw Audio2_Mus_Intro1
	dw Audio2_Mus_StageStart
	dw Audio2_Mus_GameOver
	dw Audio2_Mus_Victory
	dw Audio2_Mus_FinalVictoryAlt
	dw Audio2_Mus_GetWeapon
	dw Audio2_Mus_EndGame
	dw Audio2_Mus_VictoryAlt
	dw Audio2_Mus_TitleAlt
	dw Audio2_Mus_Title
	dw Audio2_Mus_Terra
	dw Audio2_Mus_Shop
	dw Audio2_Mus_LightIntro
	dw Audio2_Mus_Intro2
	dw Audio2_Mus_Password
	dw Audio2_Mus_Sunstar
	dw Audio2_Mus_FinalVictory
	dw Audio2_Mus_Venus

Audio2_Perc_Empty:

Audio2_FadeOutTrack:
	db %00000000
	db 0
	dw Audio2_EmptySeq

Audio2_Perc01:
	db %10000000
	db 0
	dw Audio2_Perc01D

Audio2_Perc02:
	db %10000000
	db 0
	dw Audio2_Perc02D

Audio2_Perc03:
	db %10000000
	db 0
	dw Audio2_Perc03D

Audio2_Perc04:
	db %11000000
	db 0
	dw Audio2_Perc04C
	dw Audio2_Perc03D

Audio2_Perc05:
	db %10000000
	db 0
	dw Audio2_Perc05D

Audio2_Perc06:
	db %11000000
	db 0
	dw Audio2_Perc06C
	dw Audio2_Perc01D

Audio2_Perc07:
	db %11000000
	db 0
	dw Audio2_Perc07C
	dw Audio2_Perc01D

Audio2_Perc08:
	db %11000000
	db 0
	dw Audio2_Perc08C
	dw Audio2_Perc01D

Audio2_Perc09:
	db %11000000
	db 0
	dw Audio2_Perc09C
	dw Audio2_Perc01D

Audio2_SFX_Shot:
	db %00010000
	db 4
	dw Audio2_SFX_ShotA

Audio2_SFX_ChargeShotSmall:
	db %10000000
	db 4
	dw Audio2_SFX_ChargeShotSmallD

Audio2_SFX_ChargeShotLarge:
	db %10000000
	db 4
	dw Audio2_SFX_ChargeShotLargeD

Audio2_SFX_Charge:
	db %00010000
	db 3
	dw Audio2_SFX_ChargeA

Audio2_SFX_Land:
	db %00010000
	db 3
	dw Audio2_SFX_LandA

Audio2_SFX_ExtraLife:
	db %00010000
	db 10
	dw Audio2_SFX_ExtraLifeA

Audio2_SFX_Hurt:
	db %10010000
	db 11
	dw Audio2_SFX_HurtA
	dw Audio2_SFX_HurtD

Audio2_SFX_PlayerExplode:
	db %00010000
	db 12
	dw Audio2_SFX_PlayerExplodeA

Audio2_SFX_EnemyHit:
	db %10000000
	db 5
	dw Audio2_SFX_EnemyHitD

Audio2_SFX_BossExplode:
	db %10000000
	db 9
	dw Audio2_SFX_BossExplodeD

Audio2_SFX_Health:
	db %00010000
	db 10
	dw Audio2_SFX_HealthA

Audio2_SFX_Shing:
	db %00110000
	db 10
	dw Audio2_SFX_ShingA
	dw Audio2_SFX_ShingB

Audio2_SFX_Select:
	db %00010000
	db 10
	dw Audio2_SFX_SelectA

Audio2_SFX_Pause:
	db %00010000
	db 10
	dw Audio2_SFX_PauseA

Audio2_SFX_TeleportIn:
	db %00010000
	db 3
	dw Audio2_SFX_TeleportInA

Audio2_SFX_TeleportOut:
	db %00010000
	db 7
	dw Audio2_SFX_TeleportOutA

Audio2_SFX_Deflect:
	db %10000000
	db 4
	dw Audio2_SFX_DeflectD

Audio2_SFX_Door:
	db %10000000
	db 10
	dw Audio2_SFX_DoorD

Audio2_SFX_Explode:
	db %10000000
	db 7
	dw Audio2_SFX_ExplodeD

Audio2_SFX_Splash:
	db %10000000
	db 4
	dw Audio2_SFX_SplashD

Audio2_SFX_WilyUFO:
	db %00010000
	db 4
	dw Audio2_SFX_WilyUFOA

Audio2_SFX_Error:
	db %00110000
	db 10
	dw Audio2_SFX_ErrorA
	dw Audio2_SFX_ErrorB

Audio2_SFX_Accept:
	db %00110000
	db 10
	dw Audio2_SFX_AcceptA
	dw Audio2_SFX_AcceptB

Audio2_SFX_Text:
	db %10000000
	db 8
	dw Audio2_SFX_TextD

Audio2_SFX_FortressExplode:
	db %10010000
	db 9
	dw Audio2_SFX_FortressExplodeA
	dw Audio2_SFX_FortressExplodeD

Audio2_SFXEmpty1:
	db %00001111
	db 2
	dw Audio2_EmptySeq
	dw Audio2_EmptySeq
	dw Audio2_EmptySeq
	dw Audio2_EmptySeq

Audio2_SFXEmpty2:
	db %11110000
	db 15
	dw Audio2_EmptySeq
	dw Audio2_EmptySeq
	dw Audio2_EmptySeq
	dw Audio2_EmptySeq

Audio2_SFX_RainFlush:
	db %10000000
	db 4
	dw Audio2_SFX_RainFlushD

Audio2_SFX_BreakDash:
	db %10000000
	db 4
	dw Audio2_SFX_BreakDashD

Audio2_SFX_Helicopter:
	db %10000000
	db 1
	dw Audio2_SFX_HelicopterD

Audio2_SFX_Cannon:
	db %00010000
	db 2
	dw Audio2_SFX_CannonA

Audio2_SFX_GetWeapon:
	db %00110000
	db 4
	dw Audio2_SFX_GetWeaponA
	dw Audio2_SFX_GetWeaponB

Audio2_SFX_Stomp:
	db %00010000
	db 7
	dw Audio2_SFX_StompA

Audio2_SFX_WilyMachineExplode:
	db %10010000
	db 9
	dw Audio2_SFX_WilyMachineExplodeA
	dw Audio2_SFX_WilyMachineExplodeD

Audio2_SFX_WilyTankMissile:
	db %10010000
	db 9
	dw Audio2_SFX_WilyTankMissileA
	dw Audio2_SFX_WilyTankMissileD

Audio2_SFX_ProtoMan:
	db %00001111
	db 0
	dw Audio2_EmptySeq2
	dw Audio2_SFX_ProtoManB
	dw Audio2_EmptySeq2
	dw Audio2_EmptySeq2

Audio2_SFX_BigShot1:
	db %10000000
	db 4
	dw Audio2_SFX_BigShot1D

Audio2_SFX_BigShot2:
	db %10000000
	db 4
	dw Audio2_SFX_BigShot2D

Audio2_SFX_ShotAlt:
	db %00010000
	db 4
	dw Audio2_SFX_ShotAltA

Audio2_SFX_ChargeAlt1:
	db %00010000
	db 3
	dw Audio2_SFX_ChargeAlt1A

Audio2_SFX_ChargeAlt2:
	db %00010000
	db 3
	dw Audio2_SFX_ChargeAlt2A

Audio2_SFX_GetWeaponAlt:
	db %00110000
	db 4
	dw Audio2_SFX_GetWeaponAltA
	dw Audio2_SFX_GetWeaponAltB

Audio2_SFX_ChargeAlt3:
	db %00010000
	db 3
	dw Audio2_SFX_ChargeAlt3A

;Unused - nothing in the song table points at this entry
Audio2_UnusedFadeOutTrack:
	db %00010000
	db 3
	dw Audio2_UnusedFadeOutTrackA

;Unused - nothing in the song table points at this entry
Audio2_UnusedPerc01:
	db %10110000
	db 3
	dw Audio2_UnusedPerc01A
	dw Audio2_UnusedPerc01B
	dw Audio2_UnusedPerc01D

Audio2_SFX_RushSpaceshipMotor:
	db %00000001
	db 3
	dw Audio2_SFX_RushSpaceshipMotorA

Audio2_SFX_RushSpaceshipAccel:
	db %00000001
	db 3
	dw Audio2_SFX_RushSpaceshipAccelA

Audio2_SFX_RushSpaceshipBlast:
	db %10110000
	db 3
	dw Audio2_SFX_RushSpaceshipBlastA
	dw Audio2_SFX_RushSpaceshipBlastB
	dw Audio2_SFX_RushSpaceshipBlastD

Audio2_SFX_SuperMegaBuster:
	db %10000000
	db 4
	dw Audio2_SFX_SuperMegaBusterD

Audio2_SFX_Tango:
	db %00010000
	db 4
	dw Audio2_SFX_TangoA

Audio2_SFX_ElectricShock2:
	db %10000000
	db 4
	dw Audio2_SFX_ElectricShock2D

Audio2_SFX_PhotonMissile:
	db %10000000
	db 4
	dw Audio2_SFX_PhotonMissileD

Audio2_SFX_GrabBuster:
	db %10000000
	db 4
	dw Audio2_SFX_GrabBusterD

Audio2_SFX_SaltWater:
	db %10000000
	db 4
	dw Audio2_SFX_SaltWaterD

Audio2_SFX_BubbleBomb:
	db %00010000
	db 4
	dw Audio2_SFX_BubbleBombA

Audio2_SFX_ElectricShock1:
	db %10000000
	db 4
	dw Audio2_SFX_ElectricShock1D

Audio2_SFX_SparkChaser1:
	db %10000000
	db 2
	dw Audio2_SFX_SparkChaser1D

Audio2_SFX_SparkChaser2:
	db %10000000
	db 2
	dw Audio2_SFX_SparkChaser2D

Audio2_SFX_BlackHole1:
	db %10000000
	db 1
	dw Audio2_SFX_BlackHole1D

Audio2_SFX_BlackHole2:
	db %10000000
	db 1
	dw Audio2_SFX_BlackHole2D

Audio2_SFX_ExplodeBlast:
	db %10000000
	db 1
	dw Audio2_SFX_ExplodeBlastD

Audio2_SFX_Laser:
	db %00010000
	db 12
	dw Audio2_SFX_LaserA

Audio2_SFX_PlatformExplode:
	db %10000000
	db 2
	dw Audio2_SFX_PlatformExplodeD

Audio2_SFX_SpecialWeapon:
	db %10100000
	db 3
	dw Audio2_SFX_SpecialWeaponB
	dw Audio2_SFX_SpecialWeaponD

Audio2_SFX_WilyStarExplode:
	db %10110000
	db 9
	dw Audio2_SFX_WilyStarExplodeA
	dw Audio2_SFX_WilyStarExplodeB
	dw Audio2_SFX_WilyStarExplodeD

Audio2_SFX_EnemyShot:
	db %00010000
	db 2
	dw Audio2_SFX_EnemyShotA

Audio2_SFX_TangoHit:
	db %00010000
	db 1
	dw Audio2_SFX_TangoHitA

Audio2_SFX_TimeFreeze:
	db %00110000
	db 2
	dw Audio2_SFX_TimeFreezeA
	dw Audio2_SFX_TimeFreezeB

Audio2_SFX_TeleportOutAlt:
	db %00010000
	db 1
	dw Audio2_SFX_TeleportOutAltA

Audio2_SFX_BubbleEnemy:
	db %00010000
	db 1
	dw Audio2_SFX_BubbleEnemyA

Audio2_Mus_Intro1:
	db %00001111
	db 0
	dw Audio2_Mus_Intro1A
	dw Audio2_Mus_Intro1B
	dw Audio2_Mus_Intro1C
	dw Audio2_Mus_Intro1D

Audio2_Mus_StageStart:
	db %00001111
	db 0
	dw Audio2_Mus_StageStartA
	dw Audio2_Mus_StageStartB
	dw Audio2_Mus_StageStartC
	dw Audio2_Mus_StageStartD

Audio2_Mus_GameOver:
	db %00001111
	db 0
	dw Audio2_Mus_GameOverA
	dw Audio2_Mus_GameOverB
	dw Audio2_Mus_GameOverC
	dw Audio2_Mus_GameOverD

Audio2_Mus_Victory:
	db %00001111
	db 0
	dw Audio2_Mus_VictoryA
	dw Audio2_Mus_VictoryB
	dw Audio2_Mus_VictoryC
	dw Audio2_Mus_VictoryD

Audio2_Mus_FinalVictoryAlt:
	db %00001111
	db 0
	dw Audio2_Mus_FinalVictoryAltA
	dw Audio2_Mus_FinalVictoryAltB
	dw Audio2_Mus_FinalVictoryAltC
	dw Audio2_Mus_FinalVictoryAltD

Audio2_Mus_GetWeapon:
	db %00001111
	db 0
	dw Audio2_Mus_GetWeaponA
	dw Audio2_Mus_GetWeaponB
	dw Audio2_Mus_GetWeaponC
	dw Audio2_Mus_GetWeaponD

Audio2_Mus_EndGame:
	db %00001111
	db 0
	dw Audio2_Mus_EndGameA
	dw Audio2_Mus_EndGameB
	dw Audio2_Mus_EndGameC
	dw Audio2_Mus_EndGameD

Audio2_Mus_Title:
	db %00001111
	db 0
	dw Audio2_Mus_TitleA
	dw Audio2_Mus_TitleB
	dw Audio2_Mus_TitleC
	dw Audio2_Mus_TitleD

Audio2_Mus_Terra:
	db %00001111
	db 0
	dw Audio2_Mus_TerraA
	dw Audio2_Mus_TerraB
	dw Audio2_Mus_TerraC
	dw Audio2_Mus_TerraD

Audio2_Mus_Shop:
	db %00001111
	db 0
	dw Audio2_Mus_ShopA
	dw Audio2_Mus_ShopB
	dw Audio2_Mus_ShopC
	dw Audio2_Mus_ShopD

Audio2_Mus_LightIntro:
	db %00001111
	db 0
	dw Audio2_Mus_LightIntroA
	dw Audio2_Mus_LightIntroB
	dw Audio2_Mus_LightIntroC
	dw Audio2_Mus_LightIntroD

Audio2_Mus_Intro2:
	db %00001111
	db 0
	dw Audio2_Mus_Intro2A
	dw Audio2_Mus_Intro2B
	dw Audio2_Mus_Intro2C
	dw Audio2_Mus_Intro2D

Audio2_Mus_Password:
	db %00001111
	db 0
	dw Audio2_Mus_PasswordA
	dw Audio2_Mus_PasswordB
	dw Audio2_Mus_PasswordC
	dw Audio2_Mus_PasswordD

Audio2_Mus_Sunstar:
	db %00001111
	db 0
	dw Audio2_Mus_SunstarA
	dw Audio2_Mus_SunstarB
	dw Audio2_Mus_SunstarC
	dw Audio2_Mus_SunstarD

Audio2_Mus_FinalVictory:
	db %00001111
	db 0
	dw Audio2_Mus_FinalVictoryA
	dw Audio2_Mus_FinalVictoryB
	dw Audio2_Mus_FinalVictoryC
	dw Audio2_Mus_FinalVictoryD

Audio2_Mus_VictoryAlt:
	db %00001111
	db 0
	dw Audio2_Mus_VictoryAltA
	dw Audio2_Mus_VictoryAltB
	dw Audio2_Mus_VictoryAltC
	dw Audio2_Mus_VictoryAltD

Audio2_Mus_TitleAlt:
	db %00001111
	db 0
	dw Audio2_Mus_TitleAltA
	dw Audio2_Mus_TitleAltB
	dw Audio2_Mus_TitleAltC
	dw Audio2_Mus_TitleAltD

Audio2_Mus_Venus:
	db %00001111
	db 0
	dw Audio2_Mus_VenusA
	dw Audio2_Mus_VenusB
	dw Audio2_Mus_VenusC
	dw Audio2_Mus_VenusD

;Load song/sound effect
Audio2_LoadSong:
	;If song is 0
	or a
	jp z, Audio2_NoAudio2

	;If song is $0A, then fade out current music
	cp $0A
	jp z, Audio2_FadeOutMus
	push bc
	push de
	;Load number to SFX number RAM variable
	ld [SFXNum], a
	push af
	;Get pointer from song table
	add a
	add LOW(Audio2_SongTab)
	ld l, a
	ld a, HIGH(Audio2_SongTab)
	adc 0
	ld h, a
	pop af
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	;Entries in the song table may be blank ($0000)
	;If so, then there is nothing to play
	or h
	jr z, Audio2_LoadSongRet

	;Load header values into RAM
	ld a, [hl+]
	ld [Temp1], a				;Byte 1 = Channel mask
	ld a, [hl+]
	ld [Temp2], a				;Byte 2 = priority
	ld b, h
	ld c, l
	;Set channel number to 0
	xor a
	ld [CurTrack], a
	ld de, MusC1MusNum

Audio2_GetTracks:
	;Check if each track (SFX 4-1, then music 4-1) is present
	ld hl, Temp1
	srl [hl]
	;If track present
	jr c, Audio2_InitTrackRAM

	;When finished
	jr z, Audio2_LoadSongRet

Audio2_GetTracksNext:
	;Advance channel
	ld hl, CurTrack
	inc [hl]
	;Skip to next channel area in RAM
	ld hl, TrackRAMSize
	add hl, de
	ld d, h
	ld e, l
	jr Audio2_GetTracks

Audio2_LoadSongRet:
	;Return from routine
	pop de
	pop bc
	ret

Audio2_InitTrackRAM:
	;Get song number
	ld hl, $00
	add hl, de
	ld a, [hl+]
	or a
	jr z, .InitTrackRAM2

	;If not below priority, then don't play channel
	ld a, [Temp2]
	cp [hl]
	jr nc, .InitTrackRAM2
	inc bc
	inc bc
	jr Audio2_GetTracksNext

.InitTrackRAM2
	;Get pointer from current song
	ld h, b
	ld l, c
	ld a, [hl+]
	ld b, [hl]
	inc hl
	push hl
	ld hl, $20
	add hl, de
	ld [hl+], a
	ld [hl], b
	inc hl
	ld [hl+], a
	ld [hl], b
	inc hl
	ld [hl+], a
	ld [hl], b
	;Set vibrato to first sequence
	ld hl, $0F
	add hl, de
	ld a, LOW(Audio2_Vibrato0)
	ld [hl+], a
	ld a, HIGH(Audio2_Vibrato0)
	ld [hl], a
	pop bc
	;Add current channel mask to output value
	ld a, [CurTrack]
	push af
	add LOW(Audio2_TrackMaskVals)
	ld l, a
	ld a, HIGH(Audio2_TrackMaskVals)
	adc 0
	ld h, a
	pop af
	ld a, [Output]
	or [hl]
	ld [Output], a
	;Copy SFX number value to channel music number
	ld h, d
	ld l, e
	ld a, [SFXNum]
	ld [hl+], a
	;Get priority value and copy to channel location
	ld a, [Temp2]
	ld [hl+], a
	;Set sweep value
	ld a, %00001000
	ld [hl+], a
	;Set transpose and tuning to 0
	xor a
	ld [hl+], a
	ld [hl+], a
	;Set volume to maximum
	ld a, %00000011
	ld [hl+], a
	ld [hl+], a
	;Set delay to 1
	ld a, 1
	ld [hl], a
	jr Audio2_GetTracksNext

;Call sound effect with music
Audio2_CallSFX:
	;Get sound effect number called
	push bc
	push de
	ld [SFXNum], a
	push af
	;Get sound effect pointer from RAM
	add a
	add LOW(Audio2_SongTab)
	ld l, a
	ld a, HIGH(Audio2_SongTab)
	adc 0
	ld h, a
	pop af
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ld a, [hl+]
	;Get mask and priority values
	and %11110000
	swap a
	ld [Temp1], a
	ld a, [hl+]
	ld [Temp2], a
	ld b, h
	ld c, l
	;Set current track to 4 (SFX track 1)
	ld a, 4
	ld [CurTrack], a
	ld de, SFXC1MusNum
	jp Audio2_GetTracks

Audio2_FadeOutMus:
	ld a, 7
	ld [Fade], a
	ld [FadeTime], a
	ret

Audio2_PlayAudio:
	;Check if fade out is enabled
	ld a, [Fade]
	or a
	;If not, then play audio
	jr z, .PlayAudio2

	;Otherwise, decrement fade and check again
	ld hl, FadeTime
	dec [hl]
	;If not done, then continue playing audio
	jr nz, .PlayAudio2

	;Otherwise, check NR50 value
	ld [hl], a
	ld hl, NR50Val
	ld a, [hl]
	;If not 0, then subtract volume
	or a
	;Otherwise, disable audio
	jp z, Audio2_NoAudio2
	sub %00010001
	ld [hl], a

.PlayAudio2
	call Audio2_CheckAllTracks
	jp Audio2_OutputTracks

Audio2_CheckAllTracks:
	;Check all tracks to see if they are playing
	xor a
	ld [CurTrackCheck], a
	ld de, MusC1MusNum

Audio2_CheckTrack:
	;Check if track is on (with song number)
	ld hl, $00
	add hl, de
	ld a, [hl]
	or a
	;If 0, then skip to next track
	jr z, Audio2_NextTrack

	;Process the track
	call Audio2_ProcTrack
	;Copy values to register RAM values
	call Audio2_ProcTrackRegVals

Audio2_NextTrack:
	;Skip to next track
	ld hl, $2C
	add hl, de
	ld d, h
	ld e, l
	ld hl, CurTrackCheck
	inc [hl]
	;If not done checking all 8 tracks, then check this track
	ld a, 8
	cp [hl]
	jr nz, Audio2_CheckTrack
	;Combine the four music channels' song numbers into a
	;"music playing" flag for the rest of the game to read
	ld hl, MusC1MusNum
	ld de, $2C
	ld a, [hl]
	add hl, de
	or [hl]
	add hl, de
	or [hl]
	add hl, de
	or [hl]
	ld [MusPlaying], a
	ret

Audio2_ProcTrack:
	;Process note length
	ld hl, $08
	add hl, de				;Increase time
	inc [hl]
	dec hl
	dec [hl]				;Decrease delay
	;If delay is complete, then get next command
	call z, Audio2_NextCommand
	;If track is music 4, then return
	ld a, [CurTrackCheck]
	cp 3
	ret z

	;Check if envelope is on
	ld hl, $09
	add hl, de
	ld a, [hl]
	or a
	;If not, then return
	ret z

	;Otherwise, get envelope value
	ld hl, $11
	add hl, de
	ld a, [hl]

	;If no carry, then process vibrato
	add a
	jp nc, Audio2_ProcVibrato

	;Check if wave channel
	ld a, [CurTrackCheck]
	and %00000011
	cp 2
	;If so, then perform special envelope handler
	jp z, Audio2_ProcEnvStateCh3

Audio2_ProcEnvState:
	;Otherwise, this is a decaying (CH1/CH2) envelope.
	;Wait out the current envelope stage.
	ld hl, $1A
	add hl, de
	dec [hl]
	;If not 0, then skip
	jp nz, Audio2_EnvSustain

	;Stage expired: pick the handler for the current envelope state.
	;State # is kept in +$18 and indexes the table below.
	ld hl, $18
	add hl, de
	ld a, [hl]
	push af
	add a
	add LOW(Audio2_EnvStates)
	ld l, a
	ld a, HIGH(Audio2_EnvStates)
	adc 0
	ld h, a
	pop af
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	jp hl

Audio2_EnvStates:
	dw Audio2_EnvState0
	dw Audio2_EnvState1
	dw Audio2_EnvState2
	dw Audio2_EnvState3
	dw Audio2_EnvState4
	dw Audio2_EnvSustain
	dw Audio2_EnvSustain
	dw Audio2_EnvSustain

Audio2_EnvState0:
	;Increase envelope state
	push bc
	ld hl, $18
	add hl, de
	inc [hl]

	;Get envelope value
	ld hl, $11
	add hl, de
	ld a, [hl]

	;Get volume from envelope
	and %00001111
	ld b, a
	ld a, [hl]
	swap a

	;Load the value into current hardware volume register (NRx2)
	ld hl, $1F
	add hl, de
	ld [hl], a

	;Then load upper 3 bits
	and %00000111
	ld c, a

	;Get decay
	ld hl, $0D
	add hl, de
	ld a, [hl]
	swap a
	and %00001111

	;Subtract volume
	sub b
	;If not 0 or below, then go to next stage
	jr c, Audio2_EnvState1_2

	;Otherwise, multiply the volume by decay
	call Audio2_Multiply
	;If result is 0, then skip to next state
	or a
	jr z, Audio2_EnvState1_2

	;Otherwise, then save stage duration into RAM
	pop bc
	jp Audio2_SaveStageDur

Audio2_EnvState1:
	push bc

Audio2_EnvState1_2:
	;Increase envelope state
	ld hl, $18
	add hl, de
	inc [hl]

	;Get decay
	ld hl, $0D
	add hl, de
	ld a, [hl]
	and %11110000
	ld b, a

	;Also get secondary decay parameter
	ld hl, $12
	add hl, de
	ld a, [hl]
	swap a
	and %00000111

	;Combine these values and save as current NRx1 volume
	ld c, a
	or b
	ld hl, $1F
	add hl, de
	ld [hl], a

	;Compute next stage's duration as (high nibble of +$0D - low nibble of +$12) x 7-bit count of +$12.
	ld hl, $12
	add hl, de
	ld a, [hl]
	and %00001111
	swap b
	ld l, a
	ld a, b
	sub l
	;If not 0 or below, then go to next stage
	jr c, Audio2_EnvState2_1
	call Audio2_Multiply
	or a
	;If result is 0, then skip to next state
	jr z, Audio2_EnvState2_1
	pop bc
	jp Audio2_SaveStageDur

Audio2_EnvState2:
	push bc

Audio2_EnvState2_1:
	;Increase envelope state
	ld hl, $18
	add hl, de
	inc [hl]

	;Get secondary decay parameter
	ld hl, $12
	add hl, de
	ld a, [hl]
	swap a
	and %11110000

	;Save as current NRx1 volume
	ld hl, $1F
	add hl, de
	ld [hl], a
	;Get envelope time-base/speed
	ld hl, $0A
	add hl, de
	ld a, [hl]
	;And get note time
	ld hl, $08
	add hl, de
	ld b, [hl]

	;Subtract note time from envelope time
	sub b
	;If not negative, then go to next state
	jr c, Audio2_EnvState3_2
	jr z, Audio2_EnvState3_2

	;Otherwise, then save stage duration into RAM
	pop bc
	jp Audio2_SaveStageDur

Audio2_EnvState3:
	push bc

Audio2_EnvState3_2:
	;Increase envelope state
	ld hl, $18
	add hl, de
	inc [hl]

	;Get secondary decay parameter
	ld hl, $12
	add hl, de
	ld a, [hl]
	and %00001111
	swap a
	ld b, a

	;Get tertiary decay parameter
	ld hl, $13
	add hl, de
	ld a, [hl]
	and %00000111
	ld c, a

	;Combine these values and save as current NRx1 volume
	or b
	ld hl, $1F
	add hl, de
	ld [hl], a

	;Get secondary decay and revert swap
	ld a, b
	swap a
	push af

	;Get primary decay value
	ld hl, $0D
	add hl, de
	ld a, [hl]
	and %00001111
	ld b, a

	;Subtract secondary decay value
	pop af
	sub b

	;If decay is more than 0, then go to next stage
	jr c, Audio2_EnvState4_1

	;Multiply values otherwise
	call Audio2_Multiply
	or a
	;If 0, then go to next stage
	jr z, Audio2_EnvState4_1

	;Otherwise, then save stage duration into RAM
	pop bc
	jp Audio2_SaveStageDur

Audio2_EnvState4_1:
	pop bc

Audio2_EnvState4:
	;Get primary decay value
	ld hl, $0D
	add hl, de
	ld a, [hl]
	and %00001111
	swap a

	;Set secondary decay value to it
	ld hl, $1F
	add hl, de
	ld [hl], a

	;Increase envelope state
	ld a, $FF
	ld hl, $18
	add hl, de
	inc [hl]
	;Set stage duration to 255 into RAM
	jp Audio2_SaveStageDur

Audio2_ProcEnvStateCh3:
	;Check envelope duration
	ld hl, $1A
	add hl, de
	;If not done, then return
	dec [hl]
	ret nz

	;Otherwise, check state
	ld hl, $18
	add hl, de
	ld a, [hl]

	;Jump to the handler of the correct state
	cp 1
	jr c, Audio2_EnvState1Ch3
	cp 2
	jr c, Audio2_EnvState2Ch3
	cp 3
	jr c, Audio2_EnvState3Ch3
	cp 4
	jr c, Audio2_EnvState4Ch3

	;If none of the above, then return
	ret

Audio2_EnvState1Ch3:
	;Set NR31 volume to maximum
	ld a, %11110000
	ld hl, $1F
	add hl, de
	ld [hl], a

	;Increase envelope state
	ld hl, $18
	add hl, de
	inc [hl]

	;Get envelope time + 1
	ld hl, $0A
	add hl, de
	ld a, [hl]
	inc a

	;Set envelope length to it
	ld hl, $1A
	add hl, de
	ld [hl], a
	ret

Audio2_EnvState2Ch3:
	;Get new volume
	ld a, %01010000

Audio2_EnvState2Ch3_2:
	;Set NR31 volume
	ld hl, $1F
	add hl, de
	ld [hl], a

	;Increase envelope state
	ld hl, $18
	add hl, de
	inc [hl]

	;Get envelope value (lower 7 bits)
	ld hl, $11
	add hl, de
	ld a, [hl]
	and %01111111

	;Set envelope length to it
	ld hl, $1A
	add hl, de
	ld [hl], a
	ret

Audio2_EnvState3Ch3:
	;Get new volume
	ld a, %00010000
	;Rest of state is same as 2
	jr Audio2_EnvState2Ch3_2

Audio2_EnvState4Ch3:
	;Set NR31 volume to 0
	ld a, 0
	ld hl, $1F
	add hl, de
	ld [hl], a

	;Increase envelope state
	ld hl, $18
	add hl, de
	inc [hl]
	ret

;Decrease envelope stage duration counter
Audio2_ProcVibrato:
	ld hl, $1A
	add hl, de
	dec [hl]
	;If not done, then sustain
	jr nz, Audio2_EnvSustain

	;Otherwise, get next envelope value from sequence
	ld hl, $17
	add hl, de
	inc [hl]
	;Advance the envelope sequence pointer
	ld a, [hl]
	ld hl, $14
	add hl, de
	push bc
	add [hl]
	ld c, a
	inc hl
	ld a, [hl]
	adc 0
	ld b, a
	;Check current envelope value
	ld a, [bc]
	pop bc
	;If FF, then end of sequence
	cp $FF
	;Otherwise, get volume
	jr nz, Audio2_GetVol

	;Decrement sequence position
	ld hl, $17
	add hl, de
	dec [hl]
	;Restart envelope duration
	ld hl, $1A
	add hl, de
	ld [hl], a
	jr Audio2_EnvSustain

Audio2_GetVol:
	;Get volume from upper 4 bits of envelope
	ld hl, $1F
	add hl, de
	push af
	and %11110000
	ld [hl], a
	;Then get duration from lower 4 bits of envelope
	pop af
	and %00001111

Audio2_SaveStageDur:
	;Load stage duration into RAM value
	ld hl, $1A
	add hl, de
	ld [hl], a

;After envelope is finished...
Audio2_EnvSustain:
	;If channel is 2, then return
	ld a, [CurTrackCheck]
	and 2
	jr nz, Audio2_ProcNextVibratoRet

	;Otherwise, decrease vibrato sequence delay
	ld hl, $19
	add hl, de
	dec [hl]
	;If not done, then return
	jp nz, Audio2_ProcNextVibratoRet

	;Increase vibrato sequence
	ld hl, $16
	add hl, de
	inc [hl]
	ld a, [hl]

Audio2_ProcNextVibrato:
	;Get next byte from vibrato sequence
	ld hl, $0F
	add hl, de
	push bc
	add [hl]
	ld c, a
	inc hl
	ld a, [hl]
	adc 0
	ld b, a
	ld a, [bc]
	pop bc
	;If FF, then end of sequence
	cp $FF
	;Otherwise, process value
	jr nz, .ProcNextVibrato2

	;Reset vibrato sequence step - back to start
	ld hl, $16
	add hl, de
	xor a
	ld [hl], a
	jr Audio2_ProcNextVibrato

.ProcNextVibrato2
	;Check if value is positive or negative from upper 4 bits
	push af
	swap a
	and %00001111
	cp 8
	jr c, .ProcNextVibrato3

	;If negative
	or %11110000

.ProcNextVibrato3
	;Set vibrato value
	ld hl, $1C
	add hl, de
	ld [hl], a

	;Set delay from lower 4 bits
	pop af
	and %00001111
	ld hl, $19
	add hl, de
	ld [hl], a

Audio2_ProcNextVibratoRet:
	ret

Audio2_NextCommand:
	;Get channel pointer
	ld hl, $20
	add hl, de
	ld a, [hl+]
	ld c, a
	ld b, [hl]

.NextCommand2
	;Get next byte from channel pointer
	ld a, [bc]
	cp $D0
	;If less than D0, is a note or rest
	jr c, .NoteOrRest

	;Otherwise, is parameters or VCMD
	call Audio2_ParamsOrVCMD
	;Repeat
	jr .NextCommand2

.NoteOrRest
	;Check if track is 3 (music 4)
	ld a, [CurTrackCheck]
	cp 3
	;If so, then use special handler
	jp z, Audio2_ProcNoteMusC4

	;Otherwise, load envelope on/off address value into HL
	ld hl, $09
	add hl, de
	;Check current command
	ld a, [bc]
	cp $C0
	;If less than C0, then is a note
	jr c, Audio2_ProcNote

	;Otherwise, is a rest
	ld [hl], 0
	jp Audio2_ProcNoteMusC4_3

;It is a note
Audio2_ProcNote:
	;Set envelope on/off value to on
	ld [hl], $FF
	push bc
	push af
	;Check if track is SFX 4
	ld a, [CurTrackCheck]
	cp 7
	;If so, then perform special handler
	jr z, Audio2_ProcNoteSFXCh4

	;Get octave
	ld hl, $1B
	add hl, de
	ld a, [hl]

	;Multiply to get proper octave offset
	add a
	add a
	ld b, a
	add a
	add b
	ld b, a

	;Now get note number
	pop af
	swap a
	and %00001111

	;Add to octave
	add b

	;And add transpose
	ld hl, $03
	add hl, de
	add [hl]
	push af

	;Get frequency from table
	add a
	add LOW(Audio2_FreqTab)
	ld c, a
	ld a, HIGH(Audio2_FreqTab)
	adc 0
	ld b, a
	pop af

	;Load frequency into RAM
	ld hl, $1D
	add hl, de
	ld a, [bc]
	ld [hl+], a
	inc bc
	ld a, [bc]
	ld [hl], a
	pop bc
	jr Audio2_ProcNote2

Audio2_ProcNoteSFXCh4:
	pop af
	pop bc

	;Get note from octave
	and %01110000
	ld hl, $1B
	add hl, de
	or [hl]
	swap a

	;OR with volume/duty value
	ld hl, $0C
	add hl, de
	or [hl]

	;Load frequency into RAM
	ld hl, $1D
	add hl, de
	ld [hl+], a
	xor a
	ld [hl], a

Audio2_ProcNote2:
	;Reset note time
	ld hl, $08
	add hl, de
	xor a
	ld [hl], a

	;Get note length value
	ld a, [bc]
	and %00001111
	;Convert to actual note length with speed
	call Audio2_ProcNoteLen

	;Set delay to result
	ld hl, $07
	add hl, de
	ld [hl], a

	;Advance pointer
	call Audio2_AdvChanPos

	;Check for duty/volume flag
	ld hl, $11
	add hl, de
	;If highest bit not set, then skip processing delay
	bit 7, [hl]
	jr z, Audio2_ProcDelay
	push af

	;Get lower 4 bits
	and %00001111
	ld c, a
	;Multiply with tertiary decay value
	ld hl, $13
	add hl, de
	ld a, [hl]
	swap a
	and %00001111
	push af
	call Audio2_Multiply
	swap a
	and %00001111

	;Set envelope time to it
	ld hl, $0A
	add hl, de
	ld [hl], a
	pop af

	;Load original value and multiply more to get final decay value
	ld c, a
	pop af
	swap a
	and %00001111
	call Audio2_Multiply
	add [hl]
	ld [hl], a

Audio2_ProcDelay:
	;Check final volume
	ld hl, $05
	add hl, de
	ld a, [hl+]
	or a
	;If not 0, then don't change volume or delay
	jr nz, .ProcDelay_3

	;Check if output volume is 3 (max)
	ld a, [hl]
	cp 3
	;If not, then don't change
	jr nz, .ProcDelay_2

	;If so, then set to 1
	ld a, 1

;XOR and AND value to lowest 2 bits (for envelope)
.ProcDelay_2
	xor %00000011

.ProcDelay_3
	and %00000011
	ld [hl], a
	;Reset vibrato step and envelope sequence position to FF
	ld hl, $16
	add hl, de
	ld a, $FF
	ld [hl+], a
	ld [hl+], a

	;Set envelope state to 0
	xor a
	ld [hl+], a

	;Reset vibrato to 0
	push hl
	ld hl, $1C
	add hl, de
	ld [hl], a

	;Also reset envelope length to 0
	ld hl, $0E
	add hl, de
	ld a, [hl]

	;Reset vibrato sequence delay to 0
	pop hl
	inc a
	ld [hl+], a

	;Set envelope duration to 1
	ld a, 1
	ld [hl], a
	ret

Audio2_ProcNoteMusC4:
	;Get channel 3 SFX number
	ld a, [SFXC3MusNum]

	;If between $06 and $12, cue a tom-tom drum
	cp $06
	jr c, Audio2_ProcNoteMusC4_2
	cp $0C
	jr nc, Audio2_ProcNoteMusC4_2

	;Set pointer to "empty sequence"
	ld a, LOW(Audio2_EmptySeq)
	ld [SFXC3SongPos], a
	ld a, HIGH(Audio2_EmptySeq)
	ld [$DC37], a

	;Set channel on output
	ld a, [Output]
	or %01000000
	ld [Output], a

	;Set SFX 3 note delay and SFX number to 1
	ld a, 1
	ld [SFXC3NoteDelay], a
	ld [SFXC3MusNum], a

	;Clear SFX 3 priority
	xor a
	ld [SFXC3Priority], a

Audio2_ProcNoteMusC4_2:
	;Get current note value from upper 4 bits of sequence byte
	ld a, [bc]
	swap a
	;If less than $0C, then use the value to play SFX as "percussion"
	and %00001111
	cp $0C
	call nz, Audio2_CallSFX

Audio2_ProcNoteMusC4_3:
	;Get length as lower 4 bits and process the note length
	ld a, [bc]
	and %00001111
	call Audio2_ProcNoteLen

	;Set actual length as delay
	ld hl, $07
	add hl, de
	ld [hl], a
	;Also clear note time
	ld hl, $08
	add hl, de
	xor a
	ld [hl], a
	pop hl

;Advance channel position
Audio2_AdvChanPos:
	ld hl, $20
	add hl, de
	inc bc
	ld [hl], c
	inc hl
	ld [hl], b
	ret

Audio2_ProcNoteLen:
	;Check if note length is 0
	ld hl, $0B

Audio2_ProcNoteLen2:
	add hl, de
	or a
	;If so, then set to maximum speed value
	jr z, Audio2_ProcNoteLenMax

Audio2_ProcNoteLen3:
	;Otherwise, check if less than speed
	cp [hl]
	;If not, then multiply (same as otherwise?)
	jr nc, Audio2_ProcNoteLenMult2

	;Otherwise, multiply value
	push bc
	ld c, a
	ld b, [hl]
	xor a

Audio2_ProcNoteLenMult:
	add b
	dec c
	jr nz, Audio2_ProcNoteLenMult
	pop bc
	ret

;Multiply value (same as before?)
Audio2_ProcNoteLenMult2:
	push bc
	ld c, a
	ld b, [hl]
	xor a

.ProcNoteLenMult2_2
	add b
	dec c
	jr nz, .ProcNoteLenMult2_2
	pop bc
	ret

Audio2_ProcNoteLenMax:
	;Set note length to max length of speed
	ld a, [hl]
	swap a
	and %11110000
	ret

; Unsigned 8-bit multiply: A = A(in) * C(in).
; Early-out: if A==0 or C==0 the result is 0 (so callers test it afterwards
; with `or a; jr z` to skip a zero-length envelope stage). The `cp b` isn't a
; range test - it just picks the smaller operand as the loop counter so the
; repeated-add loop runs fewer iterations. Result is left in A.
Audio2_Multiply:
	;If operand A is 0, then return
	or a
	ret z

	;Otherwise, then load into A and check operand C
	ld b, a
	xor a
	or c
	;Return if 0
	ret z

	;Compare B vs. C
	cp b
	;Pick the smaller operand as loop counter
	jr nc, .Multiply3
	xor a

;Now perform multiplication loop
.Multiply2
	add b
	dec c
	jr nz, .Multiply2

	;Return when done
	ret

;Alternate loop
.Multiply3
	xor a

.Multiply4
	add c
	dec b
	jr nz, .Multiply4

	;Return when done
	ret

Audio2_ParamsOrVCMD:
	;If Dx, is parameters
	sub $E0
	jr c, Audio2_GetParams
	push af

	;Otherwise, is a VCMD - get pointer to jump to from table
	add a
	add LOW(Audio2_VCMDTab)
	ld l, a
	ld a, HIGH(Audio2_VCMDTab)
	adc 0
	ld h, a
	pop af
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	jp hl

Audio2_GetParams:
	;Upper 4 bits of command is speed control
	ld hl, $0B
	add hl, de
	and %00001111
	ld [hl+], a

	;If current track is 3 (music 4, then return)
	inc bc
	ld a, [CurTrackCheck]
	cp 3
	ret z

	;If current track is 7 (SFX 4, then perform special handler)
	cp 7
	jr z, Audio2_GetParamsSFX4

	;If current track is 2 or 6 (music/SFX 3, then perform special handler)
	and %00000011
	cp 2
	jr z, Audio2_GetParams3

	;Otherwise, next byte is duty/volume
	ld a, [bc]
	and %00110011
	add a
	add a
	ld [hl+], a

	;Next byte is decay
	inc bc
	ld a, [bc]
	ld [hl], a

	;Next byte is vibrato
	call Audio2_EventVibrato
	;Final bytes are envelope and decay (if envelope is signed)
	jp Audio2_GetEnvVal

Audio2_GetParamsSFX4:
	;Check next byte - duty/volume
	ld a, [bc]
	;If 0, then 0, otherwise, 8
	or a
	jr z, .GetParamsSFX4_2
	ld a, 8

.GetParamsSFX4_2
	;Load parameter into RAM variable
	ld [hl+], a
	;Next byte is decay
	inc bc
	ld a, [bc]
	ld [hl], a
	;Final bytes are envelope (and decay if envelope is signed)
	jp Audio2_EventEnvDecay

Audio2_GetParams3:
	;Current byte is waveform
	dec bc
	call Audio2_EventWaveform
	;Next byte is envelope value
	ld a, [bc]
	ld hl, $11
	add hl, de
	ld [hl+], a
	;Check if envelope is at max
	add a
	;If not, then set envelope sequence
	jp nc, Audio2_GetEnvSeq

	;Otherwise, next byte is secondary decay
	inc bc
	inc hl
	ld a, [bc]
	ld [hl], a
	inc bc
	ret

Audio2_VCMDTab:
	dw Audio2_EventOctave        ;$E0
	dw Audio2_EventOctave        ;$E1
	dw Audio2_EventOctave        ;$E2
	dw Audio2_EventOctave        ;$E3
	dw Audio2_EventOctave        ;$E4
	dw Audio2_EventOctave        ;$E5
	dw Audio2_EventOctave        ;$E6
	dw Audio2_EventOctave        ;$E7
	dw Audio2_EventDutyVol       ;$E8
	dw Audio2_EventDecay         ;$E9
	dw Audio2_EventSweep         ;$EA
	dw Audio2_EventVibrato       ;$EB
	dw Audio2_EventTranspose     ;$EC
	dw Audio2_EventWaveform      ;$ED
	dw Audio2_EventEnvDecay      ;$EE
	dw Audio2_EventTuning        ;$EF
	dw Audio2_EventEnvVal        ;$F0
	dw Audio2_EventDecay2        ;$F1
	dw Audio2_EventDecay3        ;$F2
	dw Audio2_EventFinalVol      ;$F3
	dw Audio2_EventAddParam      ;$F4
	dw Audio2_EventNop           ;$F5
	dw Audio2_EventSpeed         ;$F6
	dw Audio2_EventMacro1        ;$F7
	dw Audio2_EventMacro2        ;$F8
	dw Audio2_EventMacro1Ret     ;$F9
	dw Audio2_EventMacro2Ret     ;$FA
	dw Audio2_EventRepeat1Start  ;$FB
	dw Audio2_EventRepeat2Start  ;$FC
	dw Audio2_EventRepeat1End    ;$FD
	dw Audio2_EventRepeat2End    ;$FE
	dw Audio2_EventEnd           ;$FF

Audio2_EventOctave:
	;Set the current octave (0-7)
	;Get lower 3 bits of command byte
	ld a, [bc]
	and %00000111
	;Store as octave in RAM
	ld hl, $1B
	add hl, de
	jr Audio2_StoreVal

Audio2_EventDutyVol:
	;Set duty/volume
	;Parameters: xxxxxxxx (x = value)
	inc bc
	;If track is SFX 4, then perform separate handler
	ld a, [CurTrackCheck]
	cp 7
	jr z, .EventDutyVol_SFX4
	ld a, [bc]
	;Mask out bits and multiply to get final value
	and %00110011
	add a
	add a
	ld hl, $0C
	add hl, de
	jr Audio2_StoreVal

.EventDutyVol_SFX4
	ld a, [bc]
	or a
	jr z, .EventDutyVol_2
	ld a, 8

.EventDutyVol_2
	;Store final value in RAM
	ld hl, $0C
	add hl, de
	jr Audio2_StoreVal

Audio2_EventDecay:
	;Set decay
	;Parameters: xxxxxxxx (x = value)
	ld hl, $0D
	add hl, de
	inc bc
	ld a, [bc]

Audio2_StoreVal:
	ld [hl], a

Audio2_EventNop:
;Do nothing but skip a byte
;Parameters: -------- (- = unused)
Audio2_NextByte:
	inc bc
	ret

Audio2_EventSweep:
;Set sweep
;Parameters: xxxxxxxx (x = value)
	;Load parameter in RAM
	ld hl, $02
	add hl, de
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret

Audio2_EventVibrato:
;Set vibrato
;Parameters: xxxxxxxx (x = value)
	;First, get note envelope length from upper 4 bits
	inc bc
	ld a, [bc]
	swap a
	and %00001111
	;Get the channel speed here, then enter ProcNoteLen past its own set-up
	ld hl, $0B
	add hl, de
	call Audio2_ProcNoteLen3
	;Then, get vibrato
	ld hl, $0E
	add hl, de
	inc a
	ld [hl+], a
	ld a, [bc]
	and %00001111
	push bc
	push af
	add a
	add LOW(Audio2_VibTab)
	ld c, a
	ld a, HIGH(Audio2_VibTab)
	adc 0
	ld b, a
	pop af

Audio2_StorePtr:
	;Store pointer into RAM
	ld a, [bc]
	ld [hl+], a
	inc bc
	ld a, [bc]
	ld [hl], a
	pop bc
	inc bc
	ret

Audio2_EventTranspose:
;Set transpose (per-channel)
;Parameters: xxxxxxxx (x = value, signed)
	;Load parameter in RAM
	ld hl, $03
	add hl, de
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret

Audio2_EventWaveform:
;Set waveform
;Parameters: xxxxxxxx (x = value)
	;Check current track and set its respective waveform
	ld a, [CurTrackCheck]
	cp 2
	jr z, .EventWaveform2
	cp 6
	;If neither channel 3 tracks, then do nothing
	jr nz, Audio2_NextByte
	inc bc
	ld a, [bc]
	ld [WaveformSFX], a
	inc bc
	ret

.EventWaveform2
	inc bc
	ld a, [bc]
	ld [WaveformMus], a
	inc bc
	ret

Audio2_EventEnvDecay:
;Set duty/volume and decay 2/3
;Parameters: xyyyyyyy (zzzzzzzz aaaaaaaa)  (x = if set, z and a are used, z = decay 2, a = decay 3)
	inc bc

Audio2_GetEnvVal:
	;Get envelope value from byte
	ld a, [bc]
	ld hl, $11
	add hl, de
	ld [hl+], a
	;If signed, then get decay parameters from next 2 bytes
	add a
	jr c, Audio2_GetDecay

Audio2_GetEnvSeq:
	;Get envelope sequence number from parameter
	ld a, [bc]

Audio2_GetEnvSeq2:
	push bc
	push af
	;Get envelope sequence pointer from table
	add a
	add LOW(Audio2_EnvSeqTab)
	ld c, a
	ld a, HIGH(Audio2_EnvSeqTab)
	adc 0
	;Load pointer into RAM
	ld b, a
	pop af
	ld hl, $14
	add hl, de
	jr Audio2_StorePtr

;Get decay parameters
Audio2_GetDecay:
	inc bc
	ld a, [bc]
	ld [hl+], a
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret

Audio2_EventTuning:
;Set tuning
;Parameters: xxxxxxxx (x = relative pitch, signed)
	;Load parameter in RAM
	ld hl, $04
	add hl, de
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret

Audio2_EventEnvVal:
;Set envelope value
;Parameters: xxxxxxxx (x = value)
	;Load parameter in RAM
	ld hl, $11
	add hl, de
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret

Audio2_EventDecay2:
;Set secondary decay
;Parameters: xxxxxxxx (x = value)
	;Load parameter in RAM
	ld hl, $12
	add hl, de
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret

Audio2_EventDecay3:
;Set tertiary decay
;Parameters: xxxxxxxx (x = value)
	;Load parameter in RAM
	ld hl, $13
	add hl, de
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret

Audio2_EventFinalVol:
;Set final channel volume step
;Parameters: xxxxxxxx (x = value)
	;Load parameter in RAM
	ld hl, $05
	add hl, de
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret

Audio2_EventSpeed:
;Set channel speed
;Parameters: xxxxxxxx (x = value)
	;Load parameter in RAM
	ld hl, $0B
	add hl, de
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret

Audio2_EventMacro1:
;Go to macro (subroutine) (1)
;Parameters: xxxxxxxx xxxxxxxx (X = position, absolute)
;(NOTE: 1 level only)
	;Get pointer from 2 parameters
	inc bc
	ld a, [bc]
	ld l, a
	inc bc
	ld a, [bc]
	ld h, a
	inc bc

	;Load pointer into RAM
	push hl
	ld hl, $26
	add hl, de
	ld [hl], c
	inc hl
	ld [hl], b
	pop bc
	ret

Audio2_EventMacro2:
;Go to macro (subroutine) (2)
;Parameters: xxxxxxxx xxxxxxxx (X = position, absolute)
;(NOTE: 1 level only)
	;Get pointer from 2 parameters
	inc bc
	ld a, [bc]
	ld l, a
	inc bc
	ld a, [bc]
	ld h, a
	inc bc

	;Load pointer into RAM
	push hl
	ld hl, $28
	add hl, de
	ld [hl], c
	inc hl
	ld [hl], b
	pop bc
	ret

Audio2_EventMacro1Ret:
;Return from macro (subroutine) (1)
	;Go to position in RAM
	ld hl, $26
	add hl, de
	ld a, [hl+]
	ld b, [hl]
	ld c, a
	ret

Audio2_EventMacro2Ret:
;Return from macro (subroutine) (2)
	;Go to position in RAM
	ld hl, $28
	add hl, de
	ld a, [hl+]
	ld b, [hl]
	ld c, a
	ret

Audio2_EventRepeat1Start:
;Start repeat (1) after command
;(NOTE: 1 level only)
	;Load pointer in RAM
	inc bc
	ld hl, $22
	add hl, de
	ld a, c
	ld [hl+], a
	ld [hl], b

	;Set loop times to 0
	ld hl, $2A
	add hl, de
	ld [hl], 0
	ret

Audio2_EventRepeat2Start:
;Start repeat (2) after command
;(NOTE: 1 level only)
	;Load pointer in RAM
	inc bc
	ld hl, $24
	add hl, de
	ld a, c
	ld [hl+], a
	ld [hl], b

	;Set loop times to 0
	ld hl, $2B
	add hl, de
	ld [hl], 0
	ret

Audio2_EventRepeat1End:
;End of repeat (1) - jump to start
;Parameters: xxxxxxxx (x = times to repeat, 0 = infinite)
	;Check if times parameter is 0
	inc bc
	ld a, [bc]
	or a
	;If so, then repeat infinitely
	jr z, .EventRepeat1End_GoBack

	;Otherwise, get times currently repeated
	ld hl, $2A
	add hl, de
	push hl
	ld h, [hl]
	cp h
	pop hl
	;If done repeating, then continue ahead
	jr z, Audio2_EventRepeatEnd_Done

	;Otherwise, increase value and go to repeat start
	inc [hl]

;Go to repeat start
.EventRepeat1End_GoBack
	ld hl, $22
	add hl, de
	ld a, [hl+]
	ld c, a
	ld b, [hl]
	ret

;Reset repeat count and continue ahead
Audio2_EventRepeatEnd_Done:
	ld [hl], 0
	jp Audio2_NextByte

Audio2_EventRepeat2End:
;End of repeat (2) - jump to start
;Parameters: xxxxxxxx (x = times to repeat, 0 = infinite)
	;Check if times parameter is 0
	inc bc
	ld a, [bc]
	or a
	;If so, then repeat infinitely
	jr z, .EventRepeat2End_GoBack

	;Otherwise, get times currently repeated
	ld hl, $2B
	add hl, de
	push hl
	ld h, [hl]
	cp h
	pop hl
	;If done repeating, then continue ahead
	jr z, Audio2_EventRepeatEnd_Done

	;Otherwise, increase value and go to repeat start
	inc [hl]

;Go to repeat start
.EventRepeat2End_GoBack
	ld hl, $24
	add hl, de
	ld a, [hl+]
	ld c, a
	ld b, [hl]
	ret

Audio2_EventEnd:
;End of track
	;Get channel mask and add to output
	ld a, [CurTrackCheck]
	push af
	add LOW(Audio2_ChanMaskVals)
	ld c, a
	ld a, HIGH(Audio2_ChanMaskVals)
	adc 0
	ld b, a
	pop af
	ld a, [bc]
	ld hl, Output
	and [hl]
	ld [hl], a

	;If SFX 1, then reset sweep
	ld a, [CurTrackCheck]
	cp 4
	jr z, .EventEnd_ResetSweep

	;Otherwise, if channel 1, then set decay to 8
	and %00000011
	jr z, .EventEnd_DecayVol8

	;If music 4, then set decay and volume to 0
	cp 3
	jr nz, .EventEnd_DecayVol0

.EventEnd_DecayVol8
	ld a, 8
	jr .EventEnd_2

.EventEnd_DecayVol0
	xor a

.EventEnd_2
	;Set decay
	ld hl, $0D
	add hl, de
	ld [hl], a

	;Set current volume
	ld hl, $1F
	add hl, de
	ld [hl], a

	;Set frequency to 0
	xor a
	ld hl, $1D
	add hl, de
	ld [hl+], a
	ld [hl], a

	;Set envelope on/off to off
	ld hl, $09
	add hl, de
	ld [hl], a

	;Also clear music number and priority
	ld h, d
	ld l, e
	ld [hl+], a
	ld [hl+], a

	;Reset sweep
	ld a, %00001000
	ld [hl], a

	;Set note time to 8
	ld hl, $08
	add hl, de
	ld [hl], a
	pop hl
	ret

.EventEnd_ResetSweep
	;Reset sweep
	ld a, %00001000
	ldh [rNR10], a
	ld [NR10Val], a
	jr .EventEnd_DecayVol8

Audio2_ChanMaskVals:
	db $FE, $FD, $FB, $F7, $EF, $DF, $BF, $7F

Audio2_TrackMaskVals:
	db $01, $02, $04, $08, $10, $20, $40, $80

Audio2_ProcTrackRegVals:
	;Get pointer for track routine
	ld a, [CurTrackCheck]
	push af
	add a
	add LOW(Audio2_PrepStates)
	ld l, a
	ld a, HIGH(Audio2_PrepStates)
	adc 0
	ld h, a
	pop af
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	jp hl

Audio2_PrepStates:
	dw Audio2_MusC1Prep
	dw Audio2_MusC2Prep
	dw Audio2_MusC3Prep
	dw Audio2_MusC4Prep
	dw Audio2_SFXC1Prep
	dw Audio2_SFXC2Prep
	dw Audio2_SFXC3Prep
	dw Audio2_SFXC4Prep

Audio2_MusC1Prep:
	;Check if SFX is playing in channel 1
	ld hl, SFXC1MusNum
	ld a, [hl]
	or a
	;Return if so
	ret nz

;Otherwise, get duty/pan value from table
Audio2_SFXC1Prep:
	ld hl, $06
	add hl, de
	ld a, [hl]
	and %00000011
	push af
	add LOW(Audio2_Duty1PanTab)
	ld l, a
	ld a, HIGH(Audio2_Duty1PanTab)
	adc 0
	ld h, a
	pop af

	;Load into NR51 RAM value
	ld bc, NR51Val
	ld a, [bc]
	and %11101110
	or [hl]
	ld [bc], a

	;Load sweep into NR10 RAM value
	ld bc, NR10Val
	ld hl, $02
	add hl, de
	ld a, [hl]
	ld [bc], a

	;Load note time into "gate off" value
	inc bc
	ld hl, $08
	add hl, de
	ld a, [hl]
	ld [Gate1Off], a

Audio2_MusC1Prep_2:
	;If note time is 0, then set duty/volume value to it
	or a
	jr z, Audio2_MusC1Prep_3A

	;Otherwise, set it and swap
	ld hl, $0C
	add hl, de
	ld a, [hl]
	swap a
	jr Audio2_MusC1Prep_3B

Audio2_MusC1Prep_3A:
	ld hl, $0C
	add hl, de
	ld a, [hl]

Audio2_MusC1Prep_3B:
	;Set NR11 wave duty
	and %11000000
	ld [bc], a

	;Then check if envelope is on
	inc bc
	ld hl, $09
	add hl, de
	ld a, [hl]
	or a
	;If so, then get hardware volume
	jr nz, Audio2_MusC1Prep_4

	;If not, then use empty value
	ld a, %00001000
	jr Audio2_MusC1Prep_5

Audio2_MusC1Prep_4:
	;Get hardware volume
	ld hl, $1F
	add hl, de
	ld a, [hl]

Audio2_MusC1Prep_5:
	;Set NR12 value to it
	ld [bc], a
	inc bc

Audio2_MusC1Prep_6:
	;Get tuning
	ld hl, $04
	add hl, de
	ld a, [hl]

	;And add to vibrato
	ld hl, $1C
	add hl, de
	add [hl]
	inc hl

	;Check if positive or negative
	bit 7, a
	jr nz, Audio2_MusC1Prep_Neg

	;If positive, then add to frequency
	add [hl]
	inc hl
	;And set NR13 value to it
	ld [bc], a
	ld a, [hl]
	adc 0

Audio2_MusC1Prep_7:
	;Set NR14 value
	inc bc
	and %00000111
	ld [bc], a

Audio2_MusC4Prep:
	;Do nothing
	ret

Audio2_MusC1Prep_Neg:
	;If negative, then add negative to frequency
	add [hl]
	push af
	inc hl
	ld [bc], a
	pop af
	ld a, [hl]
	adc -1
	jr Audio2_MusC1Prep_7

Audio2_MusC2Prep:
	;Check if SFX is playing in channel 2
	ld hl, SFXC2MusNum
	ld a, [hl]
	or a
	;Return if so
	ret nz

;Otherwise, get duty/pan value from table
Audio2_SFXC2Prep:
	ld hl, $06
	add hl, de
	ld a, [hl]
	and %00000011
	push af
	add LOW(Audio2_Duty2PanTab)
	ld l, a
	ld a, HIGH(Audio2_Duty2PanTab)
	adc 0
	ld h, a
	pop af

	;Load into NR51 RAM value
	ld bc, NR51Val
	ld a, [bc]
	and %11011101
	or [hl]
	ld [bc], a

	;Load note time into "gate off" value
	ld bc, NR21Val
	ld hl, $08
	add hl, de
	ld a, [hl]
	ld [Gate2Off], a
	jr Audio2_MusC1Prep_2

Audio2_MusC3Prep:
	;Check if music is playing in SFX channel 3
	ld hl, SFXC3MusNum
	ld a, [hl]
	or a
	;Return if so
	ret nz

;Otherwise, get duty/pan value from table
Audio2_SFXC3Prep:
	ld hl, $06
	add hl, de
	ld a, [hl]
	and %00000011
	push af
	add LOW(Audio2_Duty3PanTab)
	ld l, a
	ld a, HIGH(Audio2_Duty3PanTab)
	adc 0
	ld h, a
	pop af

	;Load into NR51 RAM value
	ld bc, NR51Val
	ld a, [bc]
	and %10111011
	or [hl]
	ld [bc], a

	;Load "on" value into NR10 RAM value
	ld bc, NR30Val
	ld a, %10000000
	ld [bc], a
	inc bc
	inc bc

	;Then check if envelope is on
	ld hl, $09
	add hl, de
	ld a, [hl]
	or a
	;If not, then set NR33 to 0
	jr z, Audio2_SFXC3Prep_2

	;Otherwise, get hardware volume
	ld hl, $1F
	add hl, de
	ld a, [hl]

	;Get volume from look-up table
	swap a
	and %00001111
	push bc
	push af
	add LOW(Audio2_Vol3LUT)
	ld c, a
	ld a, HIGH(Audio2_Vol3LUT)
	adc 0
	ld b, a
	pop af
	ld a, [bc]
	pop bc

;Set NR33
Audio2_SFXC3Prep_2:
	ld [bc], a
	inc bc
	jp Audio2_MusC1Prep_6

Audio2_SFXC4Prep:
	;Get duty/pan value from table
	ld hl, $06
	add hl, de
	ld a, [hl]
	and %00000011
	push af
	add LOW(Audio2_Duty4PanTab)
	ld l, a
	ld a, HIGH(Audio2_Duty4PanTab)
	adc 0
	ld h, a
	pop af

	;Load into NR51 RAM value
	ld bc, NR51Val
	ld a, [bc]
	and %01110111
	or [hl]
	ld [bc], a

	;Load note time into "gate off" value
	ld bc, NR42Val
	ld hl, $08
	add hl, de
	ld a, [hl]
	ld [Gate4Off], a

	;Then check if envelope is on
	ld hl, $09
	add hl, de
	xor a
	or [hl]
	;If so, then get hardware volume
	jr nz, Audio2_SFXC4Prep_2

	;If not, then use empty value
	ld a, %00001000
	jr Audio2_SFXC4Prep_3

Audio2_SFXC4Prep_2:
	;Get hardware volume
	ld hl, $1F
	add hl, de
	ld a, [hl]

Audio2_SFXC4Prep_3:
	;Set NR42 value to it
	ld [bc], a
	inc bc

	;Finally, load frequency into NR43-NR44
	ld hl, $1D
	add hl, de
	ld a, [hl+]
	ld [bc], a
	inc bc
	ld a, [hl]
	ld [bc], a
	ret

Audio2_Vol3LUT:
	db $00, $60, $40, $40, $40, $40, $40, $40
	db $20, $20, $20, $20, $20, $20, $20, $20

Audio2_Duty1PanTab:
	db $11, $01, $10, $11

Audio2_Duty2PanTab:
	db $22, $02, $20, $22

Audio2_Duty3PanTab:
	db $44, $04, $40, $44

Audio2_Duty4PanTab:
	db $88, $08, $80, $88

Audio2_OutputTracks:
	ld hl, NR10Val
	ld de, NR10ValCopy
	ld c, $10
	;Check "gate off" value
	ld a, [Gate1Off]
	ld b, a
	or a
	;If gate off, set register value
	jr z, .SetRegVal

	;Otherwise, check if copy register variable is the same as register value
	ld a, [de]
	cp [hl]
	jr z, .NextRegVal

.SetRegVal
	;Set temporary copy variable to register value
	ld a, [hl]
	ld [de], a
	;Also load to real register
	ldh [c], a
	ldh [c], a

.NextRegVal
	;Go to next register
	inc hl
	inc de
	inc c

Audio2_DoAllRegs:
	;Copy all register values in RAM to actual values and set appropriately
	call Audio2_OutputReg
	ld a, b
	call Audio2_OutputRegTrig
	ld a, b
	call Audio2_OutputRegCheck
	call Audio2_OutputRegWithTrig
	inc c
	call Audio2_OutputReg
	ld a, [Gate2Off]
	call Audio2_OutputRegTrig
	call Audio2_OutputReg
	call Audio2_OutputRegWithTrig
	call Audio2_OutputReg
	inc hl
	inc de
	inc c
	call Audio2_OutputReg
	call Audio2_OutputReg
	call Audio2_OutputRegWithTrig
	inc c
	inc hl
	inc de
	inc c
	ld a, [Gate4Off]
	call Audio2_OutputRegTrig
	call Audio2_OutputReg
	call Audio2_OutputRegWithTrig

	;Output NR50 and NR51 values
	ld hl, $FF24
	ld a, [NR50Val]
	ld [hl+], a
	ld a, [NR51Val]
	ld [hl+], a

	;Check if SFX on channel 3 is playing
	ld a, [SFXC3MusNum]
	or a
	;If so, set SFX waveform
	jr nz, Audio2_SetSFXWaveform

;Otherwise, set music waveform
Audio2_SetMusWaveform:
	ld a, [WaveformMus]
	jr Audio2_LoadWaveform

Audio2_SetSFXWaveform:
	ld a, [WaveformSFX]

Audio2_LoadWaveform:
	;If waveform is same, then return
	ld hl, NewWave
	cp [hl]
	ret z

	;Otherwise, load new waveform - get pointer to waveform from table
	ld [hl], a
	push af
	add a
	add LOW(Audio2_WaveTab)
	ld l, a
	ld a, HIGH(Audio2_WaveTab)
	adc 0
	ld h, a
	pop af
	ld a, [hl+]
	ld h, [hl]
	ld l, a

	;Load all bytes of the waveform into wave RAM
	ld c, $30
	xor a
	ldh [rNR30], a
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c
	ld a, [hl+]
	ldh [c], a
	inc c

	;Turn on CH3 DAC
	ld a, %10000000
	ldh [rNR30], a

	;Set CH3 trigger bit on
	ld a, [NR34Val]
	or %10000000
	ldh [rNR34], a
	ret

Audio2_OutputRegTrig:
	;Check "gate off" value
	or a
	;If gate off, get new value and set trigger
	jr z, .OutputRegTrig_2

	;Otherwise, check if copy register variable is the same as register value
	ld a, [de]
	cp [hl]
	jr z, Audio2_OutputReg_Ret

.OutputRegTrig_2
	;Get next register value from RAM
	ld a, [hl+]
	;Copy to copy register in RAM
	ld [de], a
	;Also load in real register
	ldh [c], a

	;Set bit 7 (trigger) of next register value
	inc hl
	set 7, [hl]
	dec hl
	inc de
	inc c
	ret

Audio2_OutputRegCheck:
	;Check "gate off" value
	or a
	;If gate off, get new value
	jr z, Audio2_OutputReg2

Audio2_OutputReg:
	;Get copy value and compare to main register value
	ld a, [de]
	cp [hl]
	;If same, then return
	jr z, Audio2_OutputReg_Ret

;Otherwise, load to main register value and actual register
Audio2_OutputReg2:
	ld a, [hl]
	ld [de], a
	ldh [c], a

Audio2_OutputReg_Ret:
	inc hl
	inc de
	inc c
	ret

Audio2_OutputRegWithTrig:
	;Check "trigger" bit of copy value
	ld a, [de]
	bit 7, a
	;If set, then output new value
	jr nz, .OutputRegWithTrig2

	;Otherwise, check if main value is the same
	cp [hl]
	;If so, then return
	jr z, Audio2_OutputReg_Ret

;Otherwise, output new value
.OutputRegWithTrig2
	ld a, [hl]
	ldh [c], a
	and %00000111
	ld [de], a
	inc hl
	inc de
	inc c
	ret

Audio2_NoAudio2:
	;Silence everything, then fall through into NoAudio and do it again
	call Audio2_NoAudio

;Initialize audio with no music/SFX
Audio2_NoAudio:
	push bc
	push de
	call Audio2_ClearCh1
	ld a, %01110111
	ld [NR50Val], a
	jr Audio2_InitSoundRAM

;Initialize audio
Audio2_InitSound:
	push bc
	push de
	call Audio2_AudioOff
	ld a, %01110111
	ldh [rNR50], a
	ld [NR50Val], a

;Initialize RAM variables
Audio2_InitSoundRAM:
	ld hl, MusC1MusNum
	ld de, TrackRAMSize
	ld a, 0
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	ld hl, MusC1NoteTime				;Set note time flag to 1
	ld a, 1
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	ld a, 0
	ld [Output], a				;Set output flag to 0
	ld [Fade], a				;Disable fade out routine
	ld [FadeTime], a
	ld a, $FF
	ld [NewWave], a				;Set (new) waveform value
	pop de
	pop bc
	ret

Audio2_AudioOff:
	;Turn off audio
	xor a
	ldh [rNR50], a
	ld a, %10000000
	ldh [rNR52], a

Audio2_ClearCh1:
	;Reset NR10 (sweep)
	ld a, %00001000
	ldh [rNR10], a
	ld [NR10Val], a
	;Check if channel is on
	ldh a, [rNR52]
	bit 0, a
	;If not, then skip
	jr z, Audio2_ClearCh2
	xor a
	;Clear NR11-NR14
	ldh [rNR11], a
	ld [NR11Val], a
	ld a, %00001000
	ldh [rNR12], a
	ld [NR12Val], a
	xor a
	ldh [rNR13], a
	ld [NR13Val], a
	ld [NR14Val], a
	;Set trigger bit
	ld a, %10000000
	ldh [rNR14], a
	xor a

Audio2_ClearCh2:
	;Check if channel is on
	ldh a, [rNR52]
	bit 1, a
	;If not, then skip
	jr z, Audio2_ClearCh3
	xor a
	;Clear NR21-NR24
	ldh [rNR21], a
	ld [NR21Val], a
	ldh [rNR22], a
	ld [NR22Val], a
	ldh [rNR23], a
	ld [NR23Val], a
	ld [NR24Val], a
	;Set trigger bit
	ld a, %10000000
	ldh [rNR24], a

Audio2_ClearCh3:
	;Check if channel is on
	ldh a, [rNR52]
	bit 2, a
	;If not, then skip
	jr z, Audio2_ClearCh4
	xor a
	;Clear NR32 and NR34
	ldh [rNR32], a
	ld [NR32Val], a
	ld [NR34Val], a
	;Set trigger bit
	ld a, %10000000
	ldh [rNR34], a

Audio2_ClearCh4:
	;Check if channel is on
	ldh a, [rNR52]
	bit 3, a
	;If not, then return
	jr z, Audio2_AudioOffRet
	xor a
	;Clear NR41-NR14
	ldh [rNR41], a
	ld [NR41Val], a
	ld a, %00001000
	ldh [rNR42], a
	ld [NR42Val], a
	xor a
	ldh [rNR43], a
	ld [NR43Val], a
	ld [NR44Val], a
	;Set trigger bit
	ld a, %10000000
	ldh [rNR44], a

Audio2_AudioOffRet:
	ret

Audio2_EventAddParam:
;Add a signed value to one of the current channel's RAM parameters
;Parameters: xxxxxxxx yyyyyyyy (x = RAM offset, y = value to add, signed)
	;If the offset is $11 (envelope value), the envelope sequence is reloaded
	inc bc
	ld a, [bc]
	push af
	ld l, a
	xor a
	ld h, a
	add hl, de
	inc bc
	ld a, [bc]
	add [hl]
	ld [hl], a
	pop af
	cp $11
	jr z, .EventAddParam2
	jp Audio2_NextByte

.EventAddParam2
	ld a, [hl]
	jp Audio2_GetEnvSeq2

Audio2_FreqTab:
	dw $002C
	dw $009D
	dw $0107
	dw $016B
	dw $01C9
	dw $0223
	dw $0277
	dw $02C7
	dw $0312
	dw $0358
	dw $039B
	dw $03DA
	dw $0416
	dw $044E
	dw $0483
	dw $04B5
	dw $04E5
	dw $0511
	dw $053B
	dw $0563
	dw $0589
	dw $05AC
	dw $05CE
	dw $05ED
	dw $060B
	dw $0627
	dw $0642
	dw $065B
	dw $0672
	dw $0689
	dw $069E
	dw $06B2
	dw $06C4
	dw $06D6
	dw $06E7
	dw $06F7
	dw $0706
	dw $0714
	dw $0721
	dw $072D
	dw $0739
	dw $0744
	dw $074F
	dw $0759
	dw $0762
	dw $076B
	dw $0773
	dw $077B
	dw $0783
	dw $078A
	dw $0790
	dw $0797
	dw $079D
	dw $07A2
	dw $07A7
	dw $07AC
	dw $07B1
	dw $07B6
	dw $07BA
	dw $07BE
	dw $07C1
	dw $07C5
	dw $07C8
	dw $07CB
	dw $07CE
	dw $07D1
	dw $07D4
	dw $07D6
	dw $07D9
	dw $07DB
	dw $07DD
	dw $07DF
	dw $07E1
	dw $07E2
	dw $07E4
	dw $07E6
	dw $07E7
	dw $07E9
	dw $07EA
	dw $07EB
	dw $07EC
	dw $07ED
	dw $07EE
	dw $07EF
	dw $07F0
	dw $07F1
	dw $07F2
	dw $07F3
	dw $07F4
	dw $01DF
	dw $01E3
	dw $0243
	dw $0247
	dw $0243
	dw $0257

Audio2_EmptySeq:
	db $FF

Audio2_Perc01D:
	db $D1, $00, $90, $89, $11, $81
	db $E0
	db $15
	db $FF

Audio2_Perc02D:
	db $D2, $00, $A0, $8A, $31, $F4
	db $E0
	db $1E
	db $FF

Audio2_Perc03D:
	db $D1, $00, $90, $89, $11, $B1
	db $E1
	db $B7
	db $FF

Audio2_Perc04C:
	db $D1, $10, $0E
	db $E3
	db $51
	db $21
	db $E2
	db $B1
	db $81
	db $51
	db $21
	db $E1
	db $B1
	db $81
	db $FF

Audio2_Perc05D:
	db $D1, $11, $00, $09
	db $E5
	db $32
	db $EE, $06
	db $31
	db $EE, $02
	db $31
	db $FF

Audio2_Perc06C:
	db $D1, $10, $0E
	db $E4
	db $91
	db $61
	db $31
	db $01
	db $E3
	db $91
	db $61
	db $31
	db $01
	db $E2
	db $91
	db $61
	db $31
	db $01
	db $E1
	db $91
	db $61
	db $31
	db $01
	db $E0
	db $91
	db $61
	db $31
	db $01
	db $FF

Audio2_Perc07C:
	db $D1, $10, $0E
	db $E4
	db $31
	db $01
	db $E3
	db $91
	db $61
	db $31
	db $01
	db $E2
	db $91
	db $61
	db $31
	db $01
	db $E1
	db $91
	db $61
	db $31
	db $01
	db $E0
	db $91
	db $61
	db $31
	db $01
	db $FF

Audio2_Perc08C:
	db $D1, $10, $0E
	db $E3
	db $91
	db $61
	db $31
	db $01
	db $E2
	db $91
	db $61
	db $31
	db $01
	db $E1
	db $91
	db $61
	db $31
	db $01
	db $E0
	db $91
	db $61
	db $31
	db $01
	db $FF

Audio2_Perc09C:
	db $D1, $10, $0E
	db $E3
	db $31
	db $01
	db $E2
	db $91
	db $61
	db $31
	db $01
	db $E1
	db $91
	db $61
	db $31
	db $01
	db $E0
	db $91
	db $61
	db $31
	db $01
	db $FF

Audio2_UnusedData_4F08:
	db $D7, $10, $90, $0A, $E5, $04, $14
	db $24
	db $34
	db $44
	db $54
	db $64
	db $74
	db $FF

Audio2_UnusedData_4F16:
	db $FF

Audio2_EnvSeqTab:
	dw Audio2_EnvSeq00
	dw Audio2_EnvSeq01
	dw Audio2_EnvSeq02
	dw Audio2_EnvSeq03
	dw Audio2_EnvSeq04
	dw Audio2_EnvSeq05
	dw Audio2_EnvSeq06
	dw Audio2_EnvSeq07
	dw Audio2_EnvSeq08
	dw Audio2_EnvSeq09
	dw Audio2_EnvSeq0A
	dw Audio2_EnvSeq0B
	dw Audio2_EnvSeq0C
	dw Audio2_EnvSeq0D
	dw Audio2_EnvSeq0E
	dw Audio2_EnvSeq0F
	dw Audio2_EnvSeq10
	dw Audio2_EnvSeq11
	dw Audio2_EnvSeq12
	dw Audio2_EnvSeq13

Audio2_EnvSeq00:
	db $8F
	db $FF

Audio2_EnvSeq01:
	db $1F
	db $FF

Audio2_EnvSeq02:
	db $2F
	db $FF

Audio2_EnvSeq03:
	db $3F
	db $FF

Audio2_EnvSeq04:
	db $4F
	db $FF

Audio2_EnvSeq05:
	db $5F
	db $FF

Audio2_EnvSeq06:
	db $6F
	db $FF

Audio2_EnvSeq07:
	db $7F
	db $FF

Audio2_EnvSeq08:
	db $8F
	db $FF

Audio2_EnvSeq09:
	db $9F
	db $FF

Audio2_EnvSeq0A:
	db $AF
	db $FF

Audio2_EnvSeq0B:
	db $BF
	db $FF

Audio2_EnvSeq0C:
	db $CF
	db $FF

Audio2_EnvSeq0D:
	db $DF
	db $FF

Audio2_EnvSeq0E:
	db $EF
	db $FF

Audio2_EnvSeq0F:
	db $FE
	db $FF

Audio2_EnvSeq10:
	db $B2, $52, $92, $42
	db $72, $32, $52, $22
	db $FF

Audio2_EnvSeq11:
	db $92, $42, $72, $32
	db $52, $22, $32, $12
	db $FF

Audio2_EnvSeq12:
	db $B3, $43, $63, $43
	db $63, $43, $63, $43
	db $63, $43, $63, $43
	db $63, $43, $63, $43
	db $63, $43, $63, $43
	db $63, $43
	db $FF

Audio2_EnvSeq13:
	db $83, $23, $43, $23
	db $43, $23, $43, $23
	db $43, $23, $43, $23
	db $43, $23, $43, $23
	db $43, $23, $43, $23
	db $43, $23
	db $FF

Audio2_VibTab:
	dw Audio2_Vibrato0
	dw Audio2_Vibrato1
	dw Audio2_Vibrato2
	dw Audio2_Vibrato3
	dw Audio2_Vibrato4
	dw Audio2_Vibrato5
	dw Audio2_Vibrato6
	dw Audio2_Vibrato7
	dw Audio2_Vibrato8
	dw Audio2_Vibrato9
	dw Audio2_VibratoA
	dw Audio2_VibratoA
	dw Audio2_VibratoA
	dw Audio2_VibratoA
	dw Audio2_VibratoA
	dw Audio2_VibratoA

Audio2_Vibrato0:
	db $0F
	db $FF

Audio2_Vibrato1:
	db $14, $03, $F4, $03
	db $FF

Audio2_Vibrato2:
	db $11, $22, $11, $02
	db $F1, $E2, $F1, $02
	db $FF

Audio2_Vibrato3:
	db $21, $32, $21, $02
	db $E1, $D2, $E1, $02
	db $FF

Audio2_Vibrato4:
	db $21, $42, $21, $02
	db $E1, $C2, $E1, $02
	db $FF

Audio2_Vibrato5:
	db $31, $52, $31, $02
	db $D1, $B2, $D1, $02
	db $FF

Audio2_Vibrato6:
	db $31, $62, $31, $02
	db $D1, $A2, $D1, $02
	db $FF

Audio2_Vibrato7:
	db $32, $72, $32, $02
	db $D2, $92, $D2, $02
	db $FF

Audio2_Vibrato8:
	db $81, $91, $A1, $B1
	db $C1, $D1, $E1, $F1
	db $0F, $0F, $0F, $0F
	db $0F, $0F
	db $FF

Audio2_Vibrato9:
	db $31, $21, $11, $0F
	db $0F, $0F, $0F, $0F
	db $0F
	db $FF

Audio2_VibratoA:
	db $03, $13, $23, $13
	db $FF

Audio2_WaveTab:
	dw Audio2_Waveform00
	dw Audio2_Waveform01
	dw Audio2_Waveform02
	dw Audio2_Waveform03
	dw Audio2_Waveform04
	dw Audio2_Waveform05
	dw Audio2_Waveform06
	dw Audio2_Waveform07
	dw Audio2_Waveform08
	dw Audio2_Waveform09
	dw Audio2_Waveform0A
	dw Audio2_Waveform0A
	dw Audio2_Waveform0A
	dw Audio2_Waveform0A
	dw Audio2_Waveform0A
	dw Audio2_Waveform0A
	dw Audio2_Waveform10

Audio2_Waveform00:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $ED, $CB, $A9, $87, $65, $43, $21, $00

Audio2_Waveform01:
	db $02, $46, $8A, $CE, $FF, $FF, $FF, $FF, $EC, $A8, $64, $20, $00, $44, $88, $44

Audio2_Waveform02:
	db $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

Audio2_Waveform03:
	db $35, $22, $4A, $00, $0A, $34, $05, $00, $FA, $FF, $0F, $FA, $FC, $F0, $00, $F0

Audio2_Waveform04:
	db $FE, $DC, $BA, $98, $76, $54, $32, $10, $76, $54, $32, $10, $44, $00, $22, $00

Audio2_Waveform05:
	db $79, $8F, $FC, $CF, $FD, $B9, $75, $31, $76, $54, $32, $10, $44, $00, $22, $00

Audio2_Waveform06:
	db $03, $69, $CF, $FC, $96, $30, $03, $56, $77, $65, $44, $33, $20, $00, $52, $00

Audio2_Waveform07:
	db $01, $21, $45, $67, $01, $21, $45, $67, $FE, $DC, $BA, $98, $76, $54, $32, $10

Audio2_Waveform08:
	db $01, $11, $12, $23, $34, $45, $56, $67, $78, $89, $9A, $AB, $BC, $CD, $DD, $D0

Audio2_Waveform09:
	db $13, $57, $9B, $DF, $00, $00, $00, $00, $13, $57, $9B, $DF, $00, $00, $00, $00

Audio2_Waveform0A:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $ED, $CB, $A9, $87, $65, $43, $21, $00

Audio2_Waveform10:
	db $02, $34, $67, $9A, $CD, $FF, $FF, $EE, $EE, $FF, $FF, $DC, $A9, $76, $43, $10

Audio2_SFX_ShotA:
	db $D1, $22, $F0, $00, $0F
	db $EA, $25
	db $E2
	db $38
	db $EE, $02
	db $E3
	db $34
	db $FF

Audio2_SFX_ChargeShotSmallD:
	db $D1, $11, $F0, $0F
	db $E5
	db $72
	db $61
	db $51
	db $41
	db $31
	db $21
	db $11
	db $E8, $00
	db $E5
	db $62
	db $E1
	db $12
	db $EE, $0C
	db $12
	db $EE, $08
	db $12
	db $EE, $04
	db $12
	db $FF

Audio2_SFX_ChargeShotLargeD:
	db $D2, $11, $F0, $0F
	db $E5
	db $72
	db $61
	db $51
	db $41
	db $31
	db $21
	db $11
	db $E8, $00
	db $E2
	db $51
	db $41
	db $31
	db $21
	db $11
	db $01
	db $EE, $0C
	db $02
	db $EE, $08
	db $02
	db $EE, $06
	db $02
	db $EE, $04
	db $02
	db $EE, $02
	db $02
	db $FF

Audio2_SFX_ChargeA:
	db $D3, $22, $F0, $00, $0A
	db $E1
	db $91
	db $A1
	db $B1
	db $E2
	db $01
	db $11
	db $21
	db $31
	db $41
	db $51
	db $FF

Audio2_SFX_LandA:
	db $D1, $11, $A0, $00, $9A, $31, $F3
	db $E3
	db $91
	db $E4
	db $22
	db $C1
	db $E3
	db $91
	db $E4
	db $22
	db $C1
	db $FF

Audio2_SFX_ExtraLifeA:
	db $D3, $22, $F0, $00, $0F
	db $FB
	db $E4
	db $11
	db $31
	db $51
	db $61
	db $81
	db $A1
	db $E5
	db $01
	db $11
	db $EE, $08
	db $FD, $01
	db $FF

Audio2_SFX_HurtA:
	db $D1, $11, $C0, $00, $0F
	db $EA, $1D
	db $E1
	db $62
	db $C1
	db $EA, $1E
	db $E2
	db $38
	db $EE, $03
	db $36
	db $FF

Audio2_SFX_HurtD:
	db $D1, $00, $F0, $0F
	db $E4
	db $B1
	db $A1
	db $C1
	db $E1
	db $23
	db $EE, $0C
	db $21
	db $31
	db $EE, $09
	db $41
	db $51
	db $EE, $06
	db $61
	db $71
	db $EE, $03
	db $71
	db $71
	db $FF

Audio2_SFX_PlayerExplodeA:
	db $D1, $22, $C0, $00, $0F
	db $EA, $2E
	db $C1
	db $E4
	db $F6, $02
	db $17
	db $EE, $0C
	db $17
	db $EE, $08
	db $17
	db $EE, $06
	db $17
	db $EE, $04
	db $17
	db $EE, $02
	db $17
	db $FF

Audio2_SFX_EnemyHitD:
	db $D1, $11, $E0, $0E
	db $E3
	db $72
	db $62
	db $51
	db $41
	db $31
	db $21
	db $11
	db $C1
	db $43
	db $FF

Audio2_SFX_BossExplodeD:
	db $D1, $11, $F0, $0F
	db $E6
	db $FB
	db $02
	db $12
	db $01
	db $11
	db $C1
	db $FD, $04
	db $E8, $00
	db $E4
	db $02
	db $12
	db $22
	db $32
	db $42
	db $52
	db $62
	db $72
	db $E2
	db $02
	db $12
	db $22
	db $32
	db $42
	db $52
	db $62
	db $72
	db $FF

Audio2_SFX_HealthA:
	db $D1, $11, $F0, $00, $0F
	db $E4
	db $41
	db $01
	db $41
	db $01
	db $41
	db $01
	db $41
	db $01
	db $FF

Audio2_SFX_ShingA:
	db $D2, $22, $F0, $00, $9F, $21, $F2
	db $E4
	db $83
	db $E5
	db $50
	db $FF

Audio2_SFX_ShingB:
	db $D2, $22, $F0, $00, $9F, $21, $F2
	db $EF, $02
	db $E4
	db $83
	db $E5
	db $50
	db $FF

Audio2_SFX_SelectA:
	db $D1, $01, $E0, $00, $9E, $21, $81
	db $E3
	db $87
	db $17
	db $FF

Audio2_SFX_PauseA:
	db $D1, $12, $C0, $00, $98, $11, $F1
	db $E3
	db $04
	db $44
	db $74
	db $A4
	db $D1, $12, $50, $00, $91, $11, $F1
	db $E3
	db $44
	db $74
	db $A4
	db $FF

Audio2_SFX_TeleportInA:
	db $D1, $11, $A0, $00, $0A
	db $EA, $1E
	db $E7
	db $12
	db $EA, $17
	db $E4
	db $26
	db $EE, $04
	db $26
	db $FF

Audio2_SFX_TeleportOutA:
	db $D1, $21, $F0, $00, $0F
	db $EA, $1E
	db $E6
	db $14
	db $C2
	db $EA, $25
	db $EE, $0A
	db $E2
	db $66
	db $E4
	db $14
	db $EE, $08
	db $E2
	db $66
	db $E4
	db $14
	db $EE, $06
	db $E2
	db $66
	db $E4
	db $14
	db $EE, $04
	db $E2
	db $66
	db $E4
	db $14
	db $EE, $02
	db $E2
	db $66
	db $E4
	db $14
	db $FF

Audio2_SFX_DeflectD:
	db $D1, $11, $C0, $0E
	db $E1
	db $12
	db $EE, $8C, $10, $11
	db $04
	db $FF

Audio2_SFX_DoorD:
	db $D1, $00, $00, $0E
	db $E1
	db $31
	db $E8, $11
	db $EE, $0A
	db $E0
	db $01
	db $EE, $0E
	db $E4
	db $31
	db $EE, $08
	db $E4
	db $32
	db $FF

Audio2_SFX_ExplodeD:
	db $D1, $11, $F0, $0F
	db $E5
	db $72
	db $51
	db $71
	db $C2
	db $72
	db $51
	db $21
	db $E8, $00
	db $E2
	db $53
	db $EE, $0C
	db $33
	db $EE, $0A
	db $23
	db $EE, $08
	db $13
	db $EE, $07
	db $13
	db $EE, $06
	db $13
	db $EE, $05
	db $13
	db $EE, $04
	db $13
	db $EE, $02
	db $13
	db $FF

Audio2_SFX_SplashD:
	db $D1, $00, $F0, $0F
	db $E3
	db $01
	db $21
	db $41
	db $61
	db $E8, $0B
	db $71
	db $C3
	db $D2, $00, $F0, $8F, $23, $F4
	db $E3
	db $2C
	db $FF

Audio2_SFX_WilyUFOA:
	db $D1, $22, $00, $17, $08
	db $E4
	db $FB
	db $2F
	db $FD, $00
	db $FF

Audio2_SFX_ErrorB:
	db $D8, $33, $00, $00, $0E
	db $E1
	db $34
	db $EE, $02
	db $31
	db $FF

Audio2_SFX_ErrorA:
	db $D8, $33, $00, $00, $0E
	db $E0
	db $B4
	db $EE, $02
	db $B1
	db $FF

Audio2_SFX_AcceptB:
	db $D4, $33, $00, $00, $0F
	db $E3
	db $A1
	db $E4
	db $01
	db $21
	db $31
	db $51
	db $EE, $08
	db $E3
	db $A1
	db $E4
	db $01
	db $21
	db $31
	db $51
	db $EE, $03
	db $E3
	db $A1
	db $E4
	db $01
	db $21
	db $31
	db $51
	db $FF

Audio2_SFX_AcceptA:
	db $D4, $33, $00, $00, $08
	db $C1
	db $EF, $01
	db $F3, $00
	db $E3
	db $A1
	db $E4
	db $01
	db $21
	db $31
	db $51
	db $EE, $04
	db $E3
	db $A1
	db $E4
	db $01
	db $21
	db $31
	db $51
	db $EE, $02
	db $E3
	db $A1
	db $E4
	db $01
	db $21
	db $31
	db $51
	db $FF

Audio2_SFX_TextD:
	db $D1, $00, $00, $0E
	db $E3
	db $71
	db $E8, $11
	db $EE, $08
	db $E0
	db $01
	db $E8, $00
	db $EE, $04
	db $E3
	db $73
	db $EE, $02
	db $73
	db $FF

Audio2_SFX_FortressExplodeA:
	db $D1, $31, $00, $00, $0F
	db $EA, $1C
	db $E5
	db $35
	db $C1
	db $E3
	db $35
	db $C1
	db $E3
	db $59
	db $EE, $09
	db $E3
	db $89
	db $EE, $05
	db $E3
	db $49
	db $EE, $03
	db $E3
	db $59
	db $FF

Audio2_SFX_FortressExplodeD:
	db $D1, $11, $00, $0E
	db $E7
	db $11
	db $EE, $0C
	db $21
	db $EE, $0A
	db $11
	db $C3
	db $EE, $0E
	db $E7
	db $11
	db $EE, $0C
	db $21
	db $EE, $0A
	db $11
	db $C2
	db $EE, $0E
	db $11
	db $21
	db $11
	db $01
	db $11
	db $C1
	db $EE, $0C
	db $21
	db $11
	db $01
	db $11
	db $D3, $00, $A0, $8A, $22, $F3
	db $E5
	db $4A
	db $FF

Audio2_UnusedData_53AA:
	db $D1, $31, $00, $00, $0F
	db $EA, $1B
	db $E4
	db $25
	db $C1
	db $E4
	db $98
	db $EE, $08
	db $58
	db $EE, $04
	db $58
	db $FF

Audio2_UnusedData_53BD:
	db $D1, $22, $F0, $00, $0F
	db $EA, $1D
	db $E2
	db $13
	db $EA, $14
	db $E0
	db $88
	db $EE, $0C
	db $88
	db $EE, $08
	db $88
	db $EE, $04
	db $88
	db $EE, $02
	db $88
	db $FF

Audio2_SFX_SparkChaser1D:
	db $D1, $11, $C0, $0E
	db $E1
	db $52
	db $32
	db $62
	db $42
	db $72
	db $52
	db $62
	db $42
	db $52
	db $32
	db $52
	db $32
	db $42
	db $22
	db $42
	db $22
	db $32
	db $12
	db $32
	db $12
	db $EE, $08
	db $22
	db $02
	db $22
	db $02
	db $EE, $04
	db $22
	db $02
	db $22
	db $02
	db $EE, $02
	db $22
	db $02
	db $22
	db $02
	db $FF

Audio2_SFX_SparkChaser2D:
	db $D1, $00, $C0, $0E
	db $E0
	db $62
	db $E8, $11
	db $42
	db $62
	db $52
	db $42
	db $32
	db $22
	db $12
	db $02
	db $EE, $08
	db $32
	db $22
	db $12
	db $02
	db $EE, $04
	db $32
	db $22
	db $12
	db $02
	db $FF

Audio2_SFX_BlackHole1D:
	db $D1, $00, $C0, $0E
	db $E0
	db $03
	db $13
	db $22
	db $32
	db $41
	db $51
	db $FF

Audio2_SFX_BlackHole2D:
	db $D1, $00, $C0, $08
	db $E3
	db $73
	db $EE, $0B
	db $63
	db $EE, $0E
	db $52
	db $42
	db $31
	db $21
	db $FF

Audio2_SFX_ExplodeBlastD:
	db $D1, $00, $F0, $8F, $21, $F2
	db $E5
	db $C1
	db $F6, $02
	db $31
	db $21
	db $3A
	db $FF

Audio2_SFX_LaserA:
	db $D3, $30, $B1, $00, $0D
	db $EA, $1F
	db $E6
	db $B1
	db $B1
	db $B1
	db $B1
	db $71
	db $31
	db $E5
	db $B1
	db $71
	db $31
	db $E4
	db $B1
	db $71
	db $31
	db $E3
	db $B1
	db $71
	db $31
	db $EE, $06
	db $E3
	db $B1
	db $71
	db $31
	db $EE, $03
	db $E3
	db $B1
	db $71
	db $31
	db $FF

Audio2_SFX_PlatformExplodeD:
	db $D1, $00, $C0, $0F
	db $E2
	db $73
	db $62
	db $EE, $0C
	db $52
	db $EE, $0A
	db $41
	db $31
	db $21
	db $FF

Audio2_SFX_RainFlushD:
	db $F6, $01
	db $C1
	db $DF, $00, $C0, $8C, $29, $4F
	db $E3
	db $26
	db $FF

Audio2_SFX_BreakDashD:
	db $D1, $00, $F0, $0F
	db $E3
	db $11
	db $31
	db $C1
	db $E1
	db $12
	db $C1
	db $D2, $00, $F0, $8F, $23, $F4
	db $E3
	db $36
	db $FF

Audio2_SFX_ProtoManB:
	db $DE, $22, $B0, $00, $93, $F0, $8F
	db $E4
	db $71
	db $A1
	db $E5
	db $EB, $08
	db $05
	db $EB, $09
	db $E4
	db $A1
	db $EB, $08
	db $E5
	db $26
	db $FF

Audio2_EmptySeq2:
	db $FF

Audio2_SFX_HelicopterD:
	db $D1, $11, $00, $0E
	db $E6
	db $61
	db $11
	db $C3
	db $31
	db $11
	db $C3
	db $E8, $00
	db $E3
	db $61
	db $51
	db $C4
	db $EE, $08
	db $61
	db $51
	db $C4
	db $EE, $06
	db $61
	db $51
	db $C4
	db $EE, $03
	db $61
	db $51
	db $FF

Audio2_SFX_CannonA:
	db $D1, $11, $C0, $00, $0F
	db $EA, $2E
	db $E2
	db $A2
	db $EA, $25
	db $64
	db $FF

Audio2_SFX_StompA:
	db $D1, $11, $00, $00, $0F
	db $EA, $1B
	db $E4
	db $33
	db $C1
	db $B6
	db $EE, $0C
	db $36
	db $EE, $08
	db $36
	db $EE, $04
	db $36
	db $FF

Audio2_SFX_WilyMachineExplodeA:
	db $D1, $22, $00, $00, $0F
	db $EA, $1C
	db $E3
	db $C1
	db $35
	db $C1
	db $35
	db $C1
	db $35
	db $C1
	db $59
	db $EE, $0C
	db $89
	db $EE, $08
	db $49
	db $EE, $04
	db $19
	db $FF

Audio2_SFX_WilyMachineExplodeD:
	db $D1, $11, $00, $0E
	db $E7
	db $FB
	db $EE, $0E
	db $E7
	db $C1
	db $11
	db $EE, $0C
	db $22
	db $EE, $0A
	db $11
	db $C2
	db $FD, $02
	db $EE, $0E
	db $11
	db $21
	db $11
	db $01
	db $11
	db $C1
	db $EE, $0C
	db $21
	db $11
	db $01
	db $11
	db $EE, $0A
	db $21
	db $11
	db $01
	db $11
	db $EE, $08
	db $21
	db $11
	db $01
	db $11
	db $FF

Audio2_SFX_WilyTankMissileA:
	db $D1, $12, $80, $00, $0F
	db $EA, $1C
	db $E3
	db $C1
	db $33
	db $C1
	db $33
	db $E8, $22
	db $EA, $1B
	db $F3, $00
	db $E3
	db $C1
	db $77
	db $C1
	db $77
	db $EE, $0C
	db $78
	db $EE, $08
	db $78
	db $EE, $04
	db $78
	db $FF

Audio2_SFX_WilyTankMissileD:
	db $D1, $11, $F0, $0F
	db $E7
	db $FB
	db $EE, $0E
	db $E7
	db $C1
	db $11
	db $EE, $0C
	db $21
	db $EE, $0A
	db $11
	db $C1
	db $FD, $01
	db $E5
	db $EE, $0C
	db $72
	db $51
	db $21
	db $72
	db $51
	db $21
	db $EE, $08
	db $72
	db $51
	db $21
	db $72
	db $51
	db $21
	db $EE, $06
	db $72
	db $51
	db $21
	db $72
	db $51
	db $21
	db $FF

Audio2_UnusedData_5593:
	db $D1, $22, $F0, $00, $0F
	db $EA, $25
	db $E2
	db $28
	db $EE, $02
	db $E3
	db $24
	db $FF

Audio2_SFX_BigShot1D:
	db $D1, $11, $F0, $0F
	db $E5
	db $52
	db $41
	db $21
	db $61
	db $21
	db $11
	db $71
	db $E8, $00
	db $E5
	db $62
	db $E1
	db $12
	db $EE, $0C
	db $12
	db $EE, $08
	db $12
	db $EE, $04
	db $12
	db $FF

Audio2_SFX_BigShot2D:
	db $D2, $11, $F0, $0F
	db $E5
	db $52
	db $41
	db $21
	db $61
	db $21
	db $11
	db $71
	db $E8, $00
	db $E2
	db $51
	db $31
	db $11
	db $31
	db $11
	db $01
	db $EE, $0C
	db $02
	db $EE, $08
	db $02
	db $EE, $06
	db $02
	db $EE, $04
	db $02
	db $EE, $02
	db $02
	db $FF

Audio2_SFX_ShotAltA:
	db $D1, $22, $F0, $00, $0F
	db $EA, $25
	db $E2
	db $28
	db $EE, $02
	db $E3
	db $24
	db $FF

Audio2_SFX_ChargeAlt1A:
	db $D1, $02, $F0, $00, $0A
	db $F7
	dw Audio2_SFX_ChargeAlt1A_1
	db $F7
	dw Audio2_SFX_ChargeAlt1A_1
	db $FB
	db $F7
	dw Audio2_SFX_ChargeAlt1A_2
	db $FD, $00
	db $FF

Audio2_SFX_ChargeAlt1A_1:
	db $E0
	db $71
	db $E1
	db $01
	db $E0
	db $91
	db $E1
	db $21
	db $E0
	db $71
	db $E0
	db $B1
	db $E1
	db $41
	db $01
	db $51
	db $01
	db $21
	db $71
	db $31
	db $81
	db $21
	db $41
	db $91
	db $51
	db $A1
	db $41
	db $51
	db $B1
	db $41
	db $51
	db $F9

Audio2_SFX_ChargeAlt1A_2:
	db $E0
	db $71
	db $E1
	db $01
	db $E0
	db $91
	db $E1
	db $21
	db $E0
	db $71
	db $E0
	db $B1
	db $E1
	db $41
	db $01
	db $51
	db $01
	db $F9

Audio2_SFX_ChargeAlt2A:
	db $D2, $22, $F0, $00, $0A
	db $F7
	dw Audio2_SFX_ChargeAlt2A_1
	db $F7
	dw Audio2_SFX_ChargeAlt2A_1
	db $FB
	db $F7
	dw Audio2_SFX_ChargeAlt2A_2
	db $FD, $00
	db $FF

Audio2_SFX_ChargeAlt2A_1:
	db $E2
	db $91
	db $E3
	db $41
	db $E2
	db $A1
	db $E3
	db $51
	db $E2
	db $B1
	db $E3
	db $61
	db $01
	db $71
	db $11
	db $81
	db $21
	db $91
	db $F9

Audio2_SFX_ChargeAlt2A_2:
	db $E2
	db $91
	db $E3
	db $41
	db $E2
	db $A1
	db $E3
	db $51
	db $E2
	db $B1
	db $F9

Audio2_SFX_ChargeAlt3A:
	db $D3, $12, $F0, $00, $0A
	db $EC, $01
	db $E1
	db $91
	db $A1
	db $B1
	db $E2
	db $01
	db $11
	db $21
	db $31
	db $41
	db $51
	db $FF

Audio2_UnusedData_5677:
	db $D2, $01, $A1, $42, $8B, $16, $A1
	db $FB
	db $E2
	db $04
	db $11
	db $21
	db $31
	db $41
	db $51
	db $61
	db $71
	db $81
	db $91
	db $E2
	db $94
	db $C4
	db $FD, $00
	db $FF

Audio2_UnusedData_5690:
	db $D2, $01, $A1, $42, $8B, $16, $A1
	db $FB
	db $E2
	db $41
	db $E3
	db $41
	db $E2
	db $51
	db $E3
	db $51
	db $E2
	db $61
	db $E3
	db $61
	db $E2
	db $71
	db $E3
	db $71
	db $E2
	db $81
	db $E3
	db $81
	db $E2
	db $91
	db $E3
	db $91
	db $E2
	db $94
	db $C6
	db $FD, $00
	db $FF

Audio2_UnusedData_56B6:
	db $D2, $01, $A1, $42, $8B, $16, $A1
	db $FB
	db $E9, $A1
	db $E2
	db $91
	db $E3
	db $41
	db $E2
	db $A1
	db $E3
	db $51
	db $E2
	db $B1
	db $E3
	db $61
	db $01
	db $71
	db $11
	db $81
	db $21
	db $91
	db $E3
	db $41
	db $91
	db $E9, $91
	db $41
	db $91
	db $E9, $81
	db $41
	db $91
	db $E9, $71
	db $41
	db $91
	db $E9, $61
	db $41
	db $91
	db $E9, $51
	db $41
	db $91
	db $C6
	db $FD, $00
	db $FF

Audio2_SFX_GetWeaponAltA:
	db $D2, $00, $00, $00, $0E
	db $EC, $06

Audio2_SFX_GetWeaponAltB_1:
	db $E2
	db $01
	db $31
	db $61
	db $91
	db $E3
	db $01
	db $31
	db $61
	db $91
	db $E4
	db $01
	db $31
	db $61
	db $91
	db $EE, $0B
	db $E5
	db $01
	db $31
	db $61
	db $91
	db $E4
	db $91
	db $61
	db $31
	db $01
	db $E3
	db $91
	db $61
	db $31
	db $01
	db $E2
	db $91
	db $61
	db $31
	db $01
	db $FF

Audio2_SFX_GetWeaponAltB:
	db $D2, $00, $00, $00, $0E
	db $EC, $06
	db $E3
	db $01
	db $F7
	dw Audio2_SFX_GetWeaponAltB_1
Audio2_UnusedFadeOutTrackA:
	db $D1, $02, $F0, $00, $0A
	db $FB
	db $E0
	db $71
	db $E1
	db $01
	db $E0
	db $91
	db $E1
	db $21
	db $E0
	db $B1
	db $E1
	db $41
	db $01
	db $51
	db $01
	db $21
	db $71
	db $21
	db $31
	db $81
	db $31
	db $FD, $01
	db $FB
	db $41
	db $81
	db $41
	db $51
	db $91
	db $51
	db $61
	db $A1
	db $61
	db $71
	db $B1
	db $71
	db $E1
	db $81
	db $E2
	db $01
	db $E1
	db $81
	db $E1
	db $81
	db $E2
	db $01
	db $E1
	db $81
	db $FD, $01
	db $F7
	dw Audio2_SFX_GetWeaponAltB_2
	db $EC, $0C
	db $F7
	dw Audio2_SFX_GetWeaponAltB_2
	db $EC, $18
	db $F7
	dw Audio2_SFX_GetWeaponAltB_2
	db $EC, $24
	db $F7
	dw Audio2_SFX_GetWeaponAltB_2
	db $EC, $30
	db $FC
	db $F7
	dw Audio2_SFX_GetWeaponAltB_3
	db $FE, $00
	db $FF

Audio2_SFX_GetWeaponAltB_2:
	db $FB
	db $E1
	db $91
	db $E2
	db $11
	db $E1
	db $91
	db $E1
	db $A1
	db $E2
	db $21
	db $E1
	db $A1
	db $E1
	db $B1
	db $E2
	db $31
	db $E1
	db $B1
	db $E2
	db $01
	db $41
	db $01
	db $FD, $01
	db $FB
	db $11
	db $51
	db $11
	db $21
	db $61
	db $21
	db $31
	db $71
	db $31
	db $41
	db $81
	db $41
	db $FD, $01
	db $FB
	db $51
	db $91
	db $51
	db $61
	db $A1
	db $61
	db $71
	db $B1
	db $71
	db $81
	db $E3
	db $01
	db $E2
	db $81
	db $FD, $01
	db $FB
	db $F9

Audio2_SFX_GetWeaponAltB_3:
	db $E1
	db $91
	db $E2
	db $11
	db $E1
	db $91
	db $E1
	db $A1
	db $E2
	db $21
	db $E1
	db $A1
	db $E1
	db $B1
	db $E2
	db $31
	db $E1
	db $B1
	db $E2
	db $01
	db $41
	db $01
	db $F9

Audio2_UnusedPerc01A:
	db $D1, $00, $00, $00, $0E
Audio2_UnusedPerc01B_1:
	db $EE, $0B
	db $E6
	db $01
	db $E5
	db $91
	db $61
	db $31
	db $01
	db $E4
	db $91
	db $61
	db $31
	db $01
	db $E3
	db $91
	db $61
	db $31
	db $01
	db $E2
	db $92
	db $62
	db $32
	db $02
	db $E1
	db $92
	db $62
	db $32
	db $02
	db $E0
	db $92
	db $62
	db $32
	db $02
	db $FF

Audio2_UnusedPerc01B:
	db $D1, $00, $00, $00, $0E
	db $E6
	db $01
	db $F7
	dw Audio2_UnusedPerc01B_1
Audio2_UnusedPerc01D:
	db $D2, $11, $F0, $0F, $E8, $00, $E2
	db $51
	db $31
	db $11
	db $31
	db $11
	db $01
	db $EE, $0C
	db $02
	db $EE, $08
	db $02
	db $EE, $06
	db $02
	db $EE, $04
	db $02
	db $EE, $02
	db $02
	db $FF

Audio2_UnusedData_581A:
	db $D2, $22, $F0, $00, $9F, $21, $F1
	db $E4
	db $54
	db $E5
	db $AC
	db $FF

Audio2_UnusedData_5826:
	db $D2, $22, $F0, $00, $9F, $21, $F1
	db $EF, $02
	db $E4
	db $84
	db $E5
	db $AC
	db $FF

Audio2_UnusedData_5834:
	db $D2, $22, $F0, $00, $9F, $21, $F1
	db $E3
	db $14
	db $E4
	db $0C
	db $FF

Audio2_UnusedData_5840:
	db $D2, $22, $F0, $00, $9F, $21, $F1
	db $EF, $02
	db $E3
	db $44
	db $E4
	db $0C
	db $FF

Audio2_SFX_RushSpaceshipMotorA:
	db $D1, $02, $F0, $00, $0A
	db $EC, $30
	db $FC
	db $F7
	dw Audio2_SFX_GetWeaponAltB_3
	db $FE, $00
	db $FF

Audio2_SFX_RushSpaceshipAccelA:
	db $D1, $02, $F0, $00, $0A
	db $FB
	db $E0
	db $71
	db $E1
	db $01
	db $E0
	db $91
	db $E1
	db $21
	db $E0
	db $B1
	db $E1
	db $41
	db $01
	db $51
	db $01
	db $21
	db $71
	db $21
	db $31
	db $81
	db $31
	db $FD, $01
	db $FB
	db $E1
	db $41
	db $81
	db $51
	db $91
	db $61
	db $A1
	db $71
	db $B1
	db $81
	db $E2
	db $01
	db $E1
	db $81
	db $E2
	db $01
	db $FD, $01
	db $F7
	dw Audio2_SFX_RushSpaceshipAccelA_1
	db $EC, $0C
	db $F7
	dw Audio2_SFX_RushSpaceshipAccelA_1
	db $EC, $18
	db $F7
	dw Audio2_SFX_RushSpaceshipAccelA_1
	db $FF

Audio2_SFX_RushSpaceshipAccelA_1:
	db $E1
	db $91
	db $E2
	db $11
	db $E1
	db $A1
	db $E2
	db $21
	db $E1
	db $B1
	db $E2
	db $31
	db $E2
	db $01
	db $41
	db $11
	db $51
	db $21
	db $61
	db $31
	db $71
	db $41
	db $81
	db $51
	db $91
	db $61
	db $A1
	db $71
	db $B1
	db $81
	db $E3
	db $01
	db $E2
	db $81
	db $F9

Audio2_SFX_RushSpaceshipBlastA:
	db $D1, $00, $00, $00, $0E

Audio2_SFX_RushSpaceshipBlastB_1:
	db $EE, $0B
	db $EE, $08
	db $E6
	db $01
	db $E5
	db $91
	db $61
	db $31
	db $01
	db $E4
	db $91
	db $61
	db $31
	db $01
	db $E3
	db $91
	db $61
	db $31
	db $01
	db $E2
	db $92
	db $62
	db $32
	db $02
	db $E1
	db $92
	db $62
	db $32
	db $02
	db $E0
	db $92
	db $62
	db $32
	db $EE, $01
	db $04
	db $EE, $03
	db $E3
	db $91
	db $61
	db $31
	db $01
	db $E2
	db $92
	db $62
	db $32
	db $02
	db $E1
	db $92
	db $62
	db $32
	db $02
	db $E0
	db $92
	db $62
	db $32
	db $EE, $01
	db $08
	db $EE, $02
	db $E2
	db $92
	db $62
	db $32
	db $02
	db $E1
	db $92
	db $62
	db $32
	db $02
	db $E0
	db $92
	db $62
	db $32
	db $EE, $01
	db $0C
	db $E2
	db $92
	db $62
	db $32
	db $02
	db $E1
	db $92
	db $62
	db $32
	db $02
	db $E0
	db $92
	db $62
	db $32
	db $02
	db $FF

Audio2_SFX_RushSpaceshipBlastB:
	db $D1, $00, $00, $00, $0E
	db $E6
	db $01
	db $F7
	dw Audio2_SFX_RushSpaceshipBlastB_1

Audio2_SFX_RushSpaceshipBlastD:
	db $D2, $11, $F0, $0F
	db $E8, $00
	db $E2
	db $51
	db $31
	db $11
	db $31
	db $11
	db $01
	db $EE, $0C
	db $02
	db $EE, $08
	db $02
	db $EE, $06
	db $02
	db $EE, $04
	db $02
	db $EE, $02
	db $02
	db $FF

Audio2_UnusedData_594A:
	db $D1, $02, $A1, $42, $8B, $16, $A1
	db $FB
	db $EE, $0A
	db $E2
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $EE, $0B
	db $61
	db $B1
	db $EE, $0C
	db $E2
	db $81
	db $E3
	db $11
	db $EE, $07
	db $01
	db $51
	db $EE, $0D
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $EE, $0C
	db $31
	db $81
	db $EE, $0B
	db $11
	db $61
	db $EE, $0A
	db $E2
	db $B1
	db $E3
	db $41
	db $EE, $08
	db $E2
	db $A1
	db $E3
	db $31
	db $E2
	db $A1
	db $E3
	db $31
	db $E2
	db $A1
	db $E3
	db $31
	db $E2
	db $A1
	db $E3
	db $31
	db $EE, $07
	db $E2
	db $A1
	db $E3
	db $31
	db $EE, $06
	db $E2
	db $A1
	db $E3
	db $31
	db $EE, $05
	db $E2
	db $A1
	db $E3
	db $31
	db $EE, $04
	db $E2
	db $A1
	db $E3
	db $31
	db $EE, $03
	db $E2
	db $A1
	db $E3
	db $31
	db $EE, $02
	db $E2
	db $A1
	db $E3
	db $31
	db $EE, $01
	db $E2
	db $A1
	db $E3
	db $31
	db $CA
	db $FD, $00
	db $FF

Audio2_UnusedData_59CB:
	db $D1, $02, $A1, $42, $8B, $16, $A1
	db $FB
	db $EE, $0A
	db $E2
	db $71
	db $E3
	db $01
	db $E2
	db $71
	db $E3
	db $01
	db $E2
	db $71
	db $E3
	db $01
	db $E2
	db $71
	db $E3
	db $01
	db $EE, $0B
	db $E2
	db $A1
	db $E3
	db $21
	db $EE, $0C
	db $E2
	db $B1
	db $E3
	db $41
	db $EE, $07
	db $21
	db $71
	db $EE, $0D
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $EE, $0C
	db $31
	db $81
	db $EE, $0B
	db $11
	db $61
	db $EE, $0A
	db $E2
	db $B1
	db $E3
	db $41
	db $EE, $08
	db $E2
	db $A1
	db $E3
	db $31
	db $E2
	db $A1
	db $E3
	db $31
	db $E2
	db $A1
	db $E3
	db $31
	db $E2
	db $A1
	db $E3
	db $31
	db $EE, $07
	db $E2
	db $A1
	db $E3
	db $31
	db $EE, $06
	db $E2
	db $A1
	db $E3
	db $31
	db $EE, $05
	db $E2
	db $A1
	db $E3
	db $31
	db $EE, $04
	db $E2
	db $A1
	db $E3
	db $31
	db $EE, $03
	db $E2
	db $A1
	db $E3
	db $31
	db $EE, $02
	db $E2
	db $A1
	db $E3
	db $31
	db $EE, $01
	db $E2
	db $A1
	db $E3
	db $31
	db $CA
	db $FD, $00
	db $FF

Audio2_UnusedData_5A55:
	db $D1, $02, $A1, $42, $8B, $16, $A1
	db $FB
	db $EE, $0A
	db $E2
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $41
	db $91
	db $E2
	db $A1
	db $E3
	db $31
	db $E2
	db $A1
	db $E3
	db $31
	db $E2
	db $A1
	db $E3
	db $31
	db $E2
	db $A1
	db $E3
	db $31
	db $E2
	db $A1
	db $E3
	db $31
	db $E2
	db $A1
	db $E3
	db $31
	db $E2
	db $61
	db $B1
	db $61
	db $B1
	db $61
	db $B1
	db $61
	db $B1
	db $61
	db $B1
	db $61
	db $B1
	db $E2
	db $71
	db $E3
	db $01
	db $E2
	db $71
	db $E3
	db $01
	db $E2
	db $71
	db $E3
	db $01
	db $E2
	db $71
	db $E3
	db $01
	db $E2
	db $71
	db $E3
	db $01
	db $E2
	db $71
	db $E3
	db $01
	db $EE, $0A
	db $E2
	db $71
	db $E3
	db $01
	db $EE, $09
	db $E2
	db $71
	db $E3
	db $01
	db $EE, $08
	db $E2
	db $71
	db $E3
	db $01
	db $EE, $07
	db $E2
	db $71
	db $E3
	db $01
	db $EE, $06
	db $E2
	db $71
	db $E3
	db $01
	db $EE, $05
	db $E2
	db $71
	db $E3
	db $01
	db $EE, $04
	db $E2
	db $71
	db $E3
	db $01
	db $EE, $03
	db $E2
	db $71
	db $E3
	db $01
	db $C0
	db $C0
	db $FD, $00
	db $FF

Audio2_UnusedData_5ADE:
	db $D1, $02, $A1, $42, $8B, $16, $A1
	db $FB
	db $EE, $0A
	db $E2
	db $91
	db $E3
	db $41
	db $E2
	db $91
	db $E3
	db $41
	db $E2
	db $91
	db $E3
	db $41
	db $E2
	db $91
	db $E3
	db $41
	db $E2
	db $91
	db $E3
	db $41
	db $E2
	db $91
	db $E3
	db $41
	db $31
	db $A1
	db $31
	db $A1
	db $A1
	db $31
	db $A1
	db $31
	db $A1
	db $A1
	db $E2
	db $B1
	db $E3
	db $61
	db $E2
	db $B1
	db $E3
	db $61
	db $E2
	db $B1
	db $E3
	db $61
	db $E2
	db $B1
	db $E3
	db $61
	db $E2
	db $B1
	db $E3
	db $61
	db $E2
	db $B1
	db $E3
	db $61
	db $01
	db $71
	db $01
	db $71
	db $01
	db $71
	db $01
	db $71
	db $01
	db $71
	db $01
	db $71
	db $EE, $0A
	db $01
	db $71
	db $EE, $09
	db $01
	db $71
	db $EE, $08
	db $01
	db $71
	db $EE, $07
	db $01
	db $71
	db $EE, $06
	db $01
	db $71
	db $EE, $05
	db $01
	db $71
	db $EE, $04
	db $01
	db $71
	db $EE, $03
	db $01
	db $71
	db $C0
	db $C0
	db $FD, $00
	db $FF

Audio2_SFX_SpecialWeaponD:
	db $D1, $11, $F0, $0F
	db $E5
	db $52
	db $41
	db $21
	db $61
	db $21
	db $11
	db $71
	db $E8, $00
	db $E5
	db $62
	db $E1
	db $12
	db $EE, $0C
	db $12
	db $EE, $08
	db $12
	db $EE, $04
	db $12
	db $FF

Audio2_SFX_SpecialWeaponB:
	db $D1, $00, $00, $00, $0E
	db $E6
	db $C8
	db $EE, $08
	db $E2
	db $01
	db $21
	db $41
	db $51
	db $71
	db $91
	db $B1
	db $E3
	db $01
	db $21
	db $41
	db $51
	db $71
	db $91
	db $B1
	db $E4
	db $01
	db $21
	db $41
	db $51
	db $71
	db $91
	db $B1
	db $E5
	db $01
	db $21
	db $41
	db $51
	db $71
	db $91
	db $B1
	db $FF

Audio2_SFX_WilyStarExplodeA:
	db $D2, $31, $00, $00, $0F
	db $EA, $1C
	db $E5
	db $35
	db $C1
	db $E3
	db $35
	db $EE, $0B
	db $E3
	db $59
	db $EE, $09
	db $E3
	db $89
	db $EE, $08
	db $E3
	db $49
	db $EE, $07
	db $E3
	db $59
	db $EE, $06
	db $E3
	db $89
	db $EE, $05
	db $E3
	db $49
	db $EE, $04
	db $E3
	db $59
	db $EE, $03
	db $E3
	db $89
	db $EE, $02
	db $E3
	db $49
	db $EE, $01
	db $E3
	db $59
	db $FF

Audio2_SFX_WilyStarExplodeB:
	db $D1, $51, $00, $00, $0F
	db $F3, $00
	db $F7
	dw Audio2_SFX_WilyStarExplodeB_1
	db $EE, $0C
	db $F7
	dw Audio2_SFX_WilyStarExplodeB_1
	db $EE, $0A
	db $F7
	dw Audio2_SFX_WilyStarExplodeB_1
	db $EE, $08
	db $F7
	dw Audio2_SFX_WilyStarExplodeB_1
	db $EE, $06
	db $F7
	dw Audio2_SFX_WilyStarExplodeB_1
	db $EE, $04
	db $F7
	dw Audio2_SFX_WilyStarExplodeB_1
	db $EE, $03
	db $F7
	dw Audio2_SFX_WilyStarExplodeB_1
	db $EE, $02
	db $F7
	dw Audio2_SFX_WilyStarExplodeB_1
	db $EE, $01
	db $F7
	dw Audio2_SFX_WilyStarExplodeB_1
	db $FF

Audio2_SFX_WilyStarExplodeB_1:
	db $FB
	db $E1
	db $01
	db $E0
	db $71
	db $41
	db $01
	db $FD, $04
	db $F9

Audio2_SFX_WilyStarExplodeD:
	db $D2, $11, $00, $0E
	db $F8
	dw Audio2_SFX_WilyStarExplodeD_1
	db $F8
	dw Audio2_SFX_WilyStarExplodeD_1
	db $F8
	dw Audio2_SFX_WilyStarExplodeD_1
	db $F8
	dw Audio2_SFX_WilyStarExplodeD_1
	db $EE, $0C
	db $FC
	db $F8
	dw Audio2_SFX_WilyStarExplodeD_1
	db $F4, $11, $FF
	db $FE, $07
	db $FF

Audio2_SFX_WilyStarExplodeD_1:
	db $E7
	db $11
	db $F4, $11, $FE
	db $21
	db $F4, $11, $FE
	db $11
	db $F4, $11, $04
	db $C1
	db $FA

Audio2_SFX_EnemyShotA:
	db $D1, $21, $F0, $00, $0F
	db $EA, $1F
	db $E5
	db $B6
	db $FF

Audio2_SFX_TimeFreezeA:
	db $D2, $22, $F0, $00, $9F, $21, $F2
	db $E4
	db $13
	db $E6
	db $00
	db $FF

Audio2_SFX_TimeFreezeB:
	db $D2, $22, $F0, $00, $9F, $21, $F2
	db $EF, $02
	db $E4
	db $13
	db $E6
	db $00
	db $FF

Audio2_SFX_TeleportOutAltA:
	db $D1, $21, $F0, $00, $0F
	db $EA, $1E
	db $E5
	db $B4
	db $C2
	db $EA, $26
	db $EE, $0A
	db $E3
	db $46
	db $E4
	db $B4
	db $EE, $08
	db $E3
	db $46
	db $E4
	db $B4
	db $EE, $04
	db $E3
	db $46
	db $E4
	db $B4
	db $FF

Audio2_SFX_BubbleEnemyA:
	db $D2, $11, $A0, $00, $9A, $31, $F3
	db $E1
	db $91
	db $E2
	db $22
	db $C1
	db $E2
	db $91
	db $E3
	db $22
	db $C1
	db $FF

;Unused space (1 bytes)
	ds 1, $FF

Audio2_SFX_TangoHitA:
	db $D1, $11, $00, $07, $08
	db $E4
	db $8C
	db $FF

Audio2_SFX_GetWeaponA:
	db $D1, $00, $00, $00, $0E
	db $EC, $06

Audio2_SFX_GetWeaponB_1:
	db $E1
	db $01
	db $31
	db $61
	db $91
	db $C1
	db $E2
	db $01
	db $31
	db $61
	db $91
	db $C1
	db $E3
	db $01
	db $31
	db $61
	db $91
	db $C1
	db $E4
	db $01
	db $31
	db $61
	db $91
	db $C1
	db $EE, $0B
	db $E5
	db $01
	db $31
	db $61
	db $91
	db $F6, $02
	db $E4
	db $91
	db $61
	db $31
	db $01
	db $E3
	db $91
	db $61
	db $31
	db $01
	db $E2
	db $91
	db $61
	db $31
	db $01
	db $E1
	db $91
	db $61
	db $31
	db $01
	db $E0
	db $91
	db $61
	db $31
	db $01
	db $FF

Audio2_SFX_GetWeaponB:
	db $D1, $00, $00, $00, $0E
	db $EC, $06
	db $E3
	db $01
	db $F7
	dw Audio2_SFX_GetWeaponB_1

Audio2_SFX_SuperMegaBusterD:
	db $D1, $11, $D1, $0E
	db $E3
	db $61
	db $E8, $11
	db $C1
	db $E1
	db $21
	db $E2
	db $91
	db $FF

Audio2_SFX_TangoA:
	db $D1, $00, $E1, $17, $08
	db $E3
	db $E8, $00
	db $EE, $0F
	db $EC, $FA
	db $04
	db $41
	db $52
	db $62
	db $76
	db $8F
	db $82
	db $71
	db $61
	db $51
	db $41
	db $31
	db $EE, $06
	db $E8, $11
	db $24
	db $1F
	db $EE, $03
	db $16
	db $FF

Audio2_UnusedData_5D12:
	db $D1, $00, $F0, $0F, $E3, $01, $21
	db $41
	db $61
	db $E8, $0B
	db $EE, $0A
	db $71
	db $C3
	db $D2, $00, $A0, $8F, $23
	db $F4, $EE, $06
	db $E3
	db $21
	db $EE, $04
	db $21
	db $FF

Audio2_SFX_ElectricShock2D:
	db $D1, $20, $F0, $0F
	db $E8, $20
	db $E2
	db $53
	db $EE, $0C
	db $33
	db $EE, $0A
	db $23
	db $EE, $08
	db $13
	db $EE, $07
	db $13
	db $EE, $06
	db $13
	db $EE, $05
	db $13
	db $EE, $04
	db $13
	db $EE, $02
	db $13
	db $FF

Audio2_SFX_PhotonMissileD:
	db $D1, $00, $F0, $0F
	db $EE, $0A
	db $E3
	db $03
	db $23
	db $42
	db $61
	db $E8, $16
	db $71
	db $D1, $00, $F0, $8F, $23, $F4
	db $E3
	db $21
	db $EE, $0B
	db $E5
	db $12
	db $EE, $0E
	db $12
	db $EE, $0C
	db $11
	db $EE, $09
	db $11
	db $EE, $07
	db $01
	db $EE, $05
	db $01
	db $EE, $03
	db $01
	db $FF

Audio2_SFX_GrabBusterD:
	db $D1, $00, $F0, $0F
	db $EE, $09
	db $E3
	db $03
	db $12
	db $21
	db $E8, $16
	db $D1, $22, $F0, $8F, $23, $F4
	db $EE, $0E
	db $E2
	db $01
	db $EE, $0F
	db $15
	db $EE, $0E
	db $13
	db $EE, $0A
	db $12
	db $EE, $09
	db $01
	db $EE, $07
	db $01
	db $EE, $05
	db $01
	db $EE, $03
	db $01
	db $FF

Audio2_SFX_SaltWaterD:
	db $D1, $00, $F0, $0F
	db $E4
	db $01
	db $21
	db $41
	db $62
	db $E8, $0B
	db $71
	db $C4
	db $D2, $00, $F0, $8F, $23, $F4
	db $E4
	db $05
	db $FF

Audio2_SFX_BubbleBombA:
	db $D1, $22, $F0, $00, $0F
	db $EE, $07
	db $E3
	db $02
	db $EE, $0A
	db $E3
	db $28
	db $EE, $06
	db $E3
	db $42
	db $EE, $03
	db $E3
	db $62
	db $EE, $02
	db $E4
	db $01
	db $FF

Audio2_SFX_ElectricShock1D:
	db $D1, $00, $00, $0E
	db $E3
	db $61
	db $E8, $11
	db $64
	db $E8, $00
	db $51
	db $E8, $11
	db $54
	db $E8, $00
	db $41
	db $E8, $11
	db $44
	db $E8, $00
	db $31
	db $E8, $11
	db $34
	db $E8, $00
	db $21
	db $E8, $11
	db $24
	db $E8, $00
	db $11
	db $E8, $11
	db $14
	db $FF

Audio2_Mus_StageStartB:
	db $D8, $01, $B2, $52, $9B, $26, $C4
	db $C2
	db $EC, $04
	db $EF, $02
	db $F6, $06
	db $C4
	db $E1
	db $41
	db $51
	db $61
	db $51
	db $61
	db $71
	db $61
	db $71
	db $81
	db $97
	db $F7
	dw Audio2_Mus_StageStartA_1
	db $F6, $08
	db $E9, $51
	db $E2
	db $44
	db $34
	db $24
	db $34
	db $E9, $B1
	db $E1
	db $91
	db $41
	db $91
	db $E2
	db $41
	db $01
	db $E1
	db $71
	db $E2
	db $71
	db $96
	db $E2
	db $91
	db $91
	db $92
	db $C2
	db $91
	db $91
	db $92
	db $FF

Audio2_Mus_StageStartA_1:
	db $F6, $02
	db $E1
	db $91
	db $B1
	db $E2
	db $01
	db $21
	db $41
	db $51
	db $71
	db $91
	db $B1
	db $E3
	db $01
	db $21
	db $41
	db $51
	db $71
	db $91
	db $F9

Audio2_Mus_StageStartA:
	db $D8, $30, $92, $23, $89, $25, $C4
	db $C2
	db $EC, $07
	db $EE, $05
	db $EF, $01
	db $F6, $06
	db $C4
	db $E1
	db $41
	db $51
	db $61
	db $51
	db $61
	db $71
	db $61
	db $71
	db $81
	db $97
	db $F7
	dw Audio2_Mus_StageStartA_1
	db $EC, $04
	db $F6, $08
	db $EE, $06
	db $E9, $91
	db $FB
	db $E1
	db $41
	db $FD, $0F
	db $E1
	db $41
	db $E0
	db $91
	db $E1
	db $41
	db $91
	db $71
	db $41
	db $E2
	db $41
	db $E2
	db $46
	db $E3
	db $41
	db $41
	db $42
	db $C2
	db $41
	db $41
	db $42
	db $FF

Audio2_Mus_StageStartC:
	db $D8, $06, $86, $B0
	db $C2
	db $EC, $04
	db $F6, $06
	db $C4
	db $E1
	db $41
	db $51
	db $61
	db $51
	db $61
	db $71
	db $61
	db $71
	db $81
	db $97
	db $F7
	dw Audio2_Mus_StageStartA_1
	db $F6, $08
	db $FB
	db $E1
	db $91
	db $FD, $0F
	db $E1
	db $92
	db $92
	db $E2
	db $01
	db $02
	db $E1
	db $96
	db $E1
	db $91
	db $91
	db $92
	db $E0
	db $92
	db $E1
	db $91
	db $91
	db $92
	db $E0
	db $92
	db $FF

Audio2_Mus_StageStartD:
	db $D8
	db $C2
	db $F6, $06
	db $32
	db $31
	db $31
	db $C0
	db $F6, $02
	db $21
	db $21
	db $21
	db $21
	db $21
	db $21
	db $21
	db $21
	db $21
	db $21
	db $21
	db $21
	db $21
	db $21
	db $21
	db $F6, $08
	db $11
	db $11
	db $31
	db $11
	db $11
	db $11
	db $31
	db $11
	db $11
	db $11
	db $31
	db $11
	db $11
	db $11
	db $31
	db $11
	db $11
	db $11
	db $31
	db $11
	db $11
	db $11
	db $31
	db $22
	db $22
	db $23
	db $31
	db $31
	db $32
	db $C2
	db $31
	db $31
	db $32
	db $FF

Audio2_Mus_GameOverB:
	db $D6, $21, $B1, $52, $AB, $26, $B5
	db $C2
	db $EF, $02
	db $F7
	dw Audio2_Mus_GameOverA_1
	db $FB
	db $EC, $03
	db $F6, $09
	db $E2
	db $09
	db $E1
	db $92
	db $E2
	db $01
	db $E1
	db $BA
	db $C2
	db $E2
	db $09
	db $E1
	db $92
	db $E2
	db $01
	db $E2
	db $2A
	db $C2
	db $FD, $00
	db $FF

Audio2_Mus_GameOverA_1:
	db $F6, $03
	db $E3
	db $01
	db $E2
	db $B1
	db $91
	db $71
	db $51
	db $41
	db $21
	db $01
	db $E1
	db $B1
	db $91
	db $71
	db $51
	db $41
	db $21
	db $02
	db $F9

Audio2_Mus_GameOverA:
	db $D6, $11, $31, $52, $AB, $26, $B5
	db $C2
	db $EF, $01
	db $F7
	dw Audio2_Mus_GameOverA_1
	db $EC, $03
	db $FB
	db $F6, $09
	db $E2
	db $49
	db $02
	db $41
	db $26
	db $06
	db $49
	db $02
	db $41
	db $56
	db $76
	db $FD, $00
	db $FF

Audio2_Mus_GameOverC:
	db $D6, $06, $86, $B0
	db $C2
	db $F7
	dw Audio2_Mus_GameOverA_1
	db $EC, $03
	db $FB
	db $F6, $03
	db $E1
	db $99
	db $93
	db $93
	db $93
	db $99
	db $93
	db $B3
	db $E2
	db $03
	db $E1
	db $79
	db $73
	db $73
	db $73
	db $79
	db $73
	db $93
	db $B3
	db $E1
	db $99
	db $93
	db $93
	db $93
	db $99
	db $93
	db $B3
	db $E2
	db $03
	db $E1
	db $B9
	db $B3
	db $B3
	db $B3
	db $B9
	db $B3
	db $E2
	db $03
	db $23
	db $FD, $00
	db $FF

Audio2_Mus_GameOverD:
	db $D6
	db $C2
	db $61
	db $61
	db $71
	db $71
	db $81
	db $81
	db $81
	db $81
	db $FB
	db $F7
	dw Audio2_Mus_GameOverD_1
	db $FD, $00
	db $FF

Audio2_Mus_GameOverD_1:
	db $F6, $03
	db $29
	db $33
	db $33
	db $33
	db $39
	db $33
	db $33
	db $33
	db $29
	db $33
	db $33
	db $33
	db $33
	db $33
	db $33
	db $33
	db $33
	db $33
	db $F9

Audio2_Mus_VictoryB:
	db $D3, $20, $C1, $52, $BB, $26, $B5
	db $C2
	db $EF, $02
	db $EC, $06
	db $C8
	db $E2
	db $42
	db $43
	db $C3
	db $75
	db $C1
	db $96
	db $93
	db $C1
	db $B2
	db $42
	db $73
	db $F6, $06
	db $E3
	db $00
	db $C1
	db $FF

Audio2_Mus_VictoryA:
	db $D3, $11, $91, $52, $BB, $26, $B5
	db $C2
	db $EF, $01
	db $EC, $06
	db $C8
	db $E2
	db $42
	db $43
	db $C3
	db $75
	db $C1
	db $56
	db $53
	db $C1
	db $72
	db $02
	db $73
	db $F6, $06
	db $70
	db $C1
	db $FF

Audio2_Mus_VictoryC:
	db $D3, $01, $86, $B0
	db $C2
	db $EC, $06
	db $C8
	db $E2
	db $02
	db $04
	db $C2
	db $E1
	db $B6
	db $E2
	db $06
	db $04
	db $22
	db $02
	db $E1
	db $B3
	db $F6, $06
	db $E2
	db $00
	db $C1
	db $FF

Audio2_Mus_VictoryD:
	db $D3
	db $C2
	db $34
	db $32
	db $32
	db $32
	db $34
	db $C2
	db $26
	db $26
	db $34
	db $32
	db $32
	db $34
	db $F6, $06
	db $2E
	db $31
	db $31
	db $31
	db $FF

Audio2_Mus_FinalVictoryAltB:
	db $D8, $10, $E1, $22, $9B, $3E, $A6
	db $F3, $01
	db $C4
	db $E2
	db $48
	db $E3
	db $14
	db $C4
	db $E2
	db $28
	db $E3
	db $24
	db $C4
	db $E2
	db $98
	db $E3
	db $54
	db $21
	db $C2
	db $71
	db $74
	db $31
	db $C2
	db $81
	db $84
	db $71
	db $C2
	db $E4
	db $21
	db $20
	db $FF

Audio2_Mus_FinalVictoryAltA:
	db $D8, $10, $E1, $22, $9B, $3E, $A6
	db $F3, $02
	db $C8
	db $E2
	db $98
	db $C8
	db $E2
	db $B8
	db $C8
	db $E3
	db $08
	db $E2
	db $B1
	db $C2
	db $E3
	db $21
	db $24
	db $01
	db $C2
	db $31
	db $34
	db $21
	db $C2
	db $71
	db $70
	db $FF

Audio2_Mus_FinalVictoryAltC:
	db $D8, $09, $98, $C0
	db $E1
	db $90
	db $70
	db $50
	db $71
	db $C2
	db $71
	db $74
	db $81
	db $C2
	db $81
	db $84
	db $71
	db $C2
	db $71
	db $7F
	db $C1
	db $FF

Audio2_Mus_FinalVictoryAltD:
	db $D8
	db $24
	db $24
	db $24
	db $32
	db $31
	db $31
	db $24
	db $24
	db $24
	db $31
	db $31
	db $31
	db $31
	db $24
	db $24
	db $24
	db $32
	db $31
	db $31
	db $33
	db $31
	db $F7
	dw Audio2_Mus_FinalVictoryAltD_1
	db $33
	db $31
	db $F7
	dw Audio2_Mus_FinalVictoryAltD_1
	db $33
	db $31
	db $F7
	dw Audio2_Mus_FinalVictoryAltD_1
	db $F7
	dw Audio2_Mus_FinalVictoryAltD_1
	db $F7
	dw Audio2_Mus_FinalVictoryAltD_1
	db $34
	db $FF

Audio2_Mus_FinalVictoryAltD_1:
	db $F6, $01
	db $36
	db $35
	db $35
	db $36
	db $35
	db $35
	db $F6, $08
	db $F9

Audio2_Mus_GetWeaponB:
	db $D6, $21, $D1, $25, $AB, $15, $A6
	db $EF, $02
	db $C2
	db $C0
	db $FC
	db $E9, $D1
	db $EC, $04
	db $F7
	dw Audio2_Mus_GetWeaponB_1
	db $F7
	dw Audio2_Mus_GetWeaponB_1
	db $EC, $06
	db $F7
	dw Audio2_Mus_GetWeaponB_1
	db $F7
	dw Audio2_Mus_GetWeaponB_1
	db $FE, $00
	db $FF

Audio2_Mus_GetWeaponB_1:
	db $E1
	db $02
	db $C2
	db $78
	db $51
	db $51
	db $C1
	db $79
	db $52
	db $76
	db $F9

Audio2_Mus_GetWeaponA:
	db $D6, $11, $91, $25, $AB, $14, $A6
	db $EF, $01
	db $C2
	db $CE
	db $E1
	db $01
	db $01
	db $FC
	db $EC, $04
	db $F7
	dw Audio2_Mus_GetWeaponA_1
	db $F7
	dw Audio2_Mus_GetWeaponA_1
	db $EC, $06
	db $F7
	dw Audio2_Mus_GetWeaponA_1
	db $F7
	dw Audio2_Mus_GetWeaponA_1
	db $FE, $00

Audio2_Mus_GetWeaponA_1:
	db $E1
	db $42
	db $41
	db $41
	db $71
	db $72
	db $71
	db $42
	db $41
	db $41
	db $71
	db $72
	db $71
	db $E1
	db $01
	db $21
	db $41
	db $51
	db $21
	db $41
	db $51
	db $71
	db $41
	db $51
	db $71
	db $91
	db $71
	db $91
	db $B1
	db $E2
	db $01
	db $F9

;Unused space (1 bytes)
	ds 1, $FF

Audio2_Mus_GetWeaponC:
	db $D6, $06, $83, $A0
	db $C2
	db $CE
	db $E1
	db $01
	db $01
	db $FC
	db $EC, $04
	db $F7
	dw Audio2_Mus_GetWeaponC_1
	db $F7
	dw Audio2_Mus_GetWeaponC_1
	db $EC, $06
	db $F7
	dw Audio2_Mus_GetWeaponC_1
	db $F7
	dw Audio2_Mus_GetWeaponC_1
	db $FE, $00

Audio2_Mus_GetWeaponC_1:
	db $E1
	db $02
	db $01
	db $01
	db $01
	db $02
	db $01
	db $02
	db $01
	db $01
	db $01
	db $02
	db $01
	db $02
	db $01
	db $01
	db $01
	db $02
	db $01
	db $02
	db $01
	db $01
	db $01
	db $02
	db $01
	db $F9

;Unused space (1 bytes)
	ds 1, $FF

Audio2_Mus_GetWeaponD:
	db $D6
	db $C2
	db $32
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $32
	db $32
	db $C2
	db $31
	db $31
	db $FB
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $31
	db $31
	db $31
	db $31
	db $C1
	db $31
	db $31
	db $31
	db $FD, $00
	db $FF

Audio2_Mus_TitleB:
	db $D5, $22, $B1, $52, $8B, $26, $B5
	db $C4
	db $EF, $02
	db $EC, $01
	db $E9, $A1
	db $E8, $21
	db $C4
	db $E2
	db $48
	db $C2
	db $42
	db $52
	db $7A
	db $C2
	db $52
	db $72
	db $9A
	db $C2
	db $92
	db $92
	db $BA
	db $B4
	db $E3
	db $04
	db $FC
	db $E9, $C1
	db $E8, $22
	db $E2
	db $C4
	db $44
	db $22
	db $04
	db $76
	db $54
	db $42
	db $56
	db $26
	db $2A
	db $E9, $71
	db $E8, $11
	db $C2
	db $E1
	db $B1
	db $E2
	db $01
	db $21
	db $41
	db $52
	db $C2
	db $21
	db $41
	db $51
	db $71
	db $92
	db $E9, $C1
	db $E8, $22
	db $E2
	db $C4
	db $44
	db $22
	db $04
	db $74
	db $72
	db $54
	db $44
	db $74
	db $96
	db $BA
	db $E9, $71
	db $E8, $11
	db $E9, $91
	db $B2
	db $C4
	db $B6
	db $E9, $D1
	db $E8, $22
	db $41
	db $71
	db $91
	db $B1
	db $E9, $C1
	db $E3
	db $06
	db $E2
	db $B2
	db $C2
	db $B2
	db $C2
	db $9A
	db $92
	db $B6
	db $E3
	db $06
	db $E2
	db $B2
	db $C2
	db $B2
	db $C2
	db $9A
	db $73
	db $53
	db $42
	db $2C
	db $02
	db $74
	db $72
	db $54
	db $42
	db $56
	db $E3
	db $06
	db $0A
	db $E9, $91
	db $E8, $11
	db $E2
	db $C2
	db $42
	db $72
	db $42
	db $92
	db $72
	db $C4
	db $FE, $00
	db $FF

Audio2_Mus_TitleA:
	db $D5, $22, $71, $52, $8B, $26, $B5
	db $C4
	db $EC, $01
	db $EF, $01
	db $C4
	db $E2
	db $7A
	db $72
	db $92
	db $BC
	db $92
	db $B2
	db $E3
	db $0C
	db $02
	db $02
	db $2A
	db $24
	db $44
	db $FC
	db $E8, $11
	db $FB
	db $EE, $06
	db $E2
	db $02
	db $EE, $05
	db $42
	db $72
	db $B2
	db $FD, $03
	db $FB
	db $EE, $06
	db $22
	db $EE, $05
	db $52
	db $72
	db $B2
	db $FD, $01
	db $EE, $06
	db $E1
	db $B1
	db $E2
	db $21
	db $71
	db $91
	db $B1
	db $E3
	db $01
	db $22
	db $C2
	db $E2
	db $B1
	db $E3
	db $01
	db $21
	db $41
	db $52
	db $FB
	db $EE, $06
	db $E2
	db $02
	db $EE, $05
	db $42
	db $72
	db $B2
	db $FD, $03
	db $FB
	db $EE, $06
	db $22
	db $EE, $05
	db $52
	db $72
	db $B2
	db $FD, $01
	db $EE, $08
	db $72
	db $C4
	db $76
	db $41
	db $71
	db $91
	db $B1
	db $E8, $22
	db $F7
	dw Audio2_Mus_TitleA_1
	db $EE, $09
	db $52
	db $76
	db $F7
	dw Audio2_Mus_TitleA_1
	db $EE, $09
	db $43
	db $23
	db $02
	db $EE, $06
	db $24
	db $21
	db $41
	db $5A
	db $48
	db $02
	db $26
	db $76
	db $7A
	db $E8, $11
	db $C3
	db $42
	db $72
	db $42
	db $92
	db $72
	db $C3
	db $FE, $00
	db $FF

Audio2_Mus_TitleA_1:
	db $EE, $09
	db $E9, $91
	db $E8, $22
	db $E2
	db $96
	db $72
	db $C2
	db $72
	db $C2
	db $52
	db $EE, $07
	db $41
	db $51
	db $71
	db $91
	db $41
	db $51
	db $71
	db $91
	db $F9

Audio2_Mus_TitleC:
	db $D5, $01, $86, $B0
	db $C4
	db $EC, $01
	db $C4
	db $E2
	db $0A
	db $02
	db $22
	db $4C
	db $22
	db $42
	db $5C
	db $52
	db $52
	db $7A
	db $74
	db $94
	db $FC
	db $FB
	db $E2
	db $02
	db $FD, $0F
	db $FB
	db $E1
	db $B2
	db $FD, $0F
	db $FB
	db $E2
	db $02
	db $FD, $0F
	db $FB
	db $E1
	db $B2
	db $FD, $0F
	db $F7
	dw Audio2_Mus_TitleC_1
	db $02
	db $22
	db $22
	db $22
	db $F7
	dw Audio2_Mus_TitleC_1
	db $03
	db $23
	db $42
	db $FB
	db $E2
	db $22
	db $FD, $03
	db $FB
	db $E2
	db $02
	db $FD, $03
	db $FB
	db $E1
	db $B2
	db $FD, $03
	db $FB
	db $E1
	db $92
	db $FD, $03
	db $FB
	db $E2
	db $02
	db $FD, $07
	db $C2
	db $02
	db $42
	db $02
	db $52
	db $42
	db $C4
	db $FE, $00
	db $FF

Audio2_Mus_TitleC_1:
	db $E2
	db $42
	db $42
	db $42
	db $24
	db $22
	db $22
	db $04
	db $02
	db $02
	db $02
	db $F9

Audio2_Mus_TitleD:
	db $D5
	db $C4
	db $32
	db $32
	db $24
	db $FB
	db $14
	db $14
	db $12
	db $26
	db $FD, $02
	db $14
	db $31
	db $31
	db $32
	db $32
	db $31
	db $31
	db $FC
	db $FB
	db $F7
	dw Audio2_Mus_TitleD_1
	db $FD, $0E
	db $32
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $24
	db $32
	db $24
	db $22
	db $32
	db $24
	db $22
	db $32
	db $24
	db $22
	db $32
	db $32
	db $24
	db $32
	db $24
	db $22
	db $32
	db $24
	db $22
	db $34
	db $33
	db $33
	db $32
	db $FB
	db $F7
	dw Audio2_Mus_TitleD_1
	db $FD, $04
	db $12
	db $11
	db $11
	db $31
	db $31
	db $31
	db $31
	db $2C
	db $32
	db $31
	db $31
	db $FE, $00
	db $FF

Audio2_Mus_TitleD_1:
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $F9

Audio2_Mus_TerraB:
	db $D6, $22, $B1, $52, $9B, $26, $B5
	db $EF, $02
	db $C2
	db $FC
	db $EC, $02
	db $E9, $B1
	db $E8, $21
	db $F7
	dw Audio2_Mus_TerraA_1
	db $F7
	dw Audio2_Mus_TerraA_1
	db $EC, $04
	db $F7
	dw Audio2_Mus_TerraA_1
	db $F7
	dw Audio2_Mus_TerraA_1
	db $EC, $06
	db $F7
	dw Audio2_Mus_TerraA_1
	db $F7
	dw Audio2_Mus_TerraA_1
	db $FE, $00
	db $FF

Audio2_Mus_TerraA_1:
	db $E1
	db $01
	db $11
	db $21
	db $31
	db $4C
	db $41
	db $31
	db $21
	db $11
	db $0C
	db $01
	db $11
	db $21
	db $31
	db $4C
	db $31
	db $41
	db $51
	db $61
	db $7C
	db $F9

Audio2_Mus_TerraA:
	db $D6, $22, $71, $52, $8B, $26, $B5
	db $EC, $02
	db $C2
	db $EF, $01
	db $F7
	dw Audio2_Mus_TerraA_1
	db $EC, $02
	db $E9, $31
	db $E8, $11
	db $FB
	db $F7
	dw Audio2_Mus_TerraA_2
	db $FD, $02
	db $F8
	dw Audio2_Mus_TerraA_3
	db $FC
	db $EC, $04
	db $FB
	db $F7
	dw Audio2_Mus_TerraA_2
	db $FD, $06
	db $F8
	dw Audio2_Mus_TerraA_3
	db $EC, $06
	db $FB
	db $F7
	dw Audio2_Mus_TerraA_2
	db $FD, $06
	db $F8
	dw Audio2_Mus_TerraA_3
	db $EC, $02
	db $FB
	db $F7
	dw Audio2_Mus_TerraA_2
	db $FD, $06
	db $F8
	dw Audio2_Mus_TerraA_3
	db $FE, $00
	db $FF

Audio2_Mus_TerraA_2:
	db $EE, $05
	db $E2
	db $31
	db $EE, $04
	db $71
	db $E3
	db $01
	db $E2
	db $31
	db $71
	db $E3
	db $01
	db $E2
	db $31
	db $71
	db $E3
	db $01
	db $E2
	db $31
	db $71
	db $E3
	db $01
	db $E2
	db $31
	db $71
	db $E3
	db $01
	db $E2
	db $31
	db $F9

Audio2_Mus_TerraA_3:
	db $E2
	db $01
	db $31
	db $71
	db $E3
	db $31
	db $01
	db $E2
	db $A1
	db $E3
	db $01
	db $E2
	db $71
	db $A1
	db $31
	db $71
	db $31
	db $01
	db $E1
	db $A1
	db $E2
	db $01
	db $E1
	db $91
	db $FA

Audio2_Mus_TerraC:
	db $D6, $01, $86, $B0
	db $C2
	db $FC
	db $EC, $02
	db $F7
	dw Audio2_Mus_TerraA_1
	db $F7
	dw Audio2_Mus_TerraA_1
	db $EC, $04
	db $F7
	dw Audio2_Mus_TerraA_1
	db $F7
	dw Audio2_Mus_TerraA_1
	db $EC, $06
	db $F7
	dw Audio2_Mus_TerraA_1
	db $F7
	dw Audio2_Mus_TerraA_1
	db $FE, $00
	db $FF

Audio2_Mus_TerraD:
	db $D6
	db $C2
	db $FB
	db $14
	db $FD, $0E
	db $31
	db $31
	db $31
	db $31
	db $FC
	db $FB
	db $F7
	dw Audio2_Mus_TerraD_1
	db $FD, $06
	db $31
	db $11
	db $72
	db $31
	db $11
	db $72
	db $FE, $00
	db $FF

Audio2_Mus_TerraD_1:
	db $31
	db $11
	db $22
	db $31
	db $11
	db $22
	db $F9

Audio2_Mus_ShopB:
	db $D6, $11, $91, $52, $AB, $26, $B5
	db $C2
	db $EF, $02
	db $EC, $F6
	db $F7
	dw Audio2_Mus_ShopA_1
	db $7C
	db $C4
	db $FC
	db $EC, $F6
	db $F8
	dw Audio2_Mus_ShopB_1
	db $EC, $F4
	db $F8
	dw Audio2_Mus_ShopB_1
	db $FE, $00
	db $FF

Audio2_Mus_ShopA_1:
	db $E3
	db $01
	db $E2
	db $71
	db $91
	db $B1
	db $E3
	db $01
	db $E2
	db $91
	db $B1
	db $E3
	db $01
	db $21
	db $E2
	db $B1
	db $E3
	db $01
	db $21
	db $41
	db $01
	db $21
	db $41
	db $F9

Audio2_Mus_ShopB_1:
	db $E8, $21
	db $E9, $C1
	db $E2
	db $76
	db $72
	db $E3
	db $4C
	db $E2
	db $92
	db $B2
	db $B2
	db $E3
	db $02
	db $02
	db $22
	db $E2
	db $42
	db $74
	db $C2
	db $E3
	db $4E
	db $C2
	db $28
	db $FA

Audio2_Mus_ShopA:
	db $D6, $11, $71, $52, $AB, $26, $B5
	db $C2
	db $EF, $01
	db $EC, $02
	db $F7
	dw Audio2_Mus_ShopA_1
	db $EC, $02
	db $E2
	db $42
	db $41
	db $41
	db $41
	db $42
	db $41
	db $42
	db $C4
	db $41
	db $41
	db $EE, $05
	db $FC
	db $EC, $02
	db $F7
	dw Audio2_Mus_ShopA_2
	db $F7
	dw Audio2_Mus_ShopA_2
	db $F7
	dw Audio2_Mus_ShopA_2
	db $F7
	dw Audio2_Mus_ShopA_2
	db $EC, $00
	db $F7
	dw Audio2_Mus_ShopA_2
	db $F7
	dw Audio2_Mus_ShopA_2
	db $F7
	dw Audio2_Mus_ShopA_2
	db $F7
	dw Audio2_Mus_ShopA_1
	db $FE, $00
	db $FF

Audio2_Mus_ShopA_2:
	db $E2
	db $02
	db $72
	db $E3
	db $02
	db $42
	db $E2
	db $02
	db $72
	db $E3
	db $02
	db $42
	db $F9

Audio2_Mus_ShopC:
	db $D6, $01, $86, $B0
	db $C2
	db $C0
	db $EC, $02
	db $E2
	db $02
	db $01
	db $01
	db $01
	db $02
	db $01
	db $02
	db $C4
	db $01
	db $01
	db $FC
	db $EC, $02
	db $F7
	dw Audio2_Mus_ShopC_1
	db $F7
	dw Audio2_Mus_ShopC_1
	db $F7
	dw Audio2_Mus_ShopC_1
	db $F7
	dw Audio2_Mus_ShopC_1
	db $EC, $00
	db $F7
	dw Audio2_Mus_ShopC_1
	db $F7
	dw Audio2_Mus_ShopC_1
	db $F7
	dw Audio2_Mus_ShopC_1
	db $F7
	dw Audio2_Mus_ShopC_1
	db $FE, $00
	db $FF

Audio2_Mus_ShopC_1:
	db $E2
	db $02
	db $02
	db $02
	db $02
	db $02
	db $E1
	db $72
	db $E2
	db $02
	db $02
	db $F9

Audio2_Mus_ShopD:
	db $D6
	db $C2
	db $C0
	db $32
	db $31
	db $31
	db $31
	db $32
	db $31
	db $32
	db $C4
	db $31
	db $31
	db $FC
	db $F7
	dw Audio2_Mus_ShopD_1
	db $F7
	dw Audio2_Mus_ShopD_1
	db $F7
	dw Audio2_Mus_ShopD_1
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $31
	db $31
	db $31
	db $31
	db $32
	db $31
	db $31
	db $FE, $00
	db $FF

Audio2_Mus_ShopD_1:
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $12
	db $11
	db $11
	db $32
	db $22
	db $F9

Audio2_Mus_Intro1B:
	db $DA, $22, $B1, $52, $AB, $26, $B5
	db $C2
	db $EF, $02
	db $E8, $11
	db $E9, $B1
	db $E3
	db $02
	db $22
	db $E2
	db $B2
	db $E3
	db $02
	db $E2
	db $92
	db $B2
	db $72
	db $92
	db $FC
	db $FB
	db $E2
	db $02
	db $42
	db $72
	db $E3
	db $02
	db $FD, $01
	db $FB
	db $E1
	db $B2
	db $E2
	db $22
	db $52
	db $B2
	db $FD, $01
	db $FB
	db $E1
	db $92
	db $E2
	db $02
	db $42
	db $92
	db $FD, $01
	db $E1
	db $72
	db $B2
	db $E2
	db $22
	db $72
	db $55
	db $48
	db $FE, $00
	db $FF

Audio2_Mus_Intro1A:
	db $DA, $11, $71, $51, $AB, $26, $B5
	db $C2
	db $EF, $01
	db $E9, $51
	db $EE, $03
	db $E8, $11
	db $E3
	db $C1
	db $02
	db $22
	db $E2
	db $B2
	db $E3
	db $02
	db $E2
	db $92
	db $B2
	db $72
	db $91
	db $FC
	db $FB
	db $E2
	db $C1
	db $02
	db $42
	db $72
	db $E3
	db $01
	db $FD, $01
	db $FB
	db $E1
	db $C1
	db $B2
	db $E2
	db $22
	db $52
	db $B1
	db $FD, $01
	db $FB
	db $E1
	db $C1
	db $92
	db $E2
	db $02
	db $42
	db $91
	db $FD, $01
	db $E1
	db $C1
	db $72
	db $B2
	db $E2
	db $22
	db $71
	db $C1
	db $55
	db $47
	db $FE, $00
	db $FF

Audio2_Mus_Intro1C:
	db $DA, $06, $83, $A0
	db $C2
	db $FC
	db $C0
	db $FE, $00
	db $FF

Audio2_Mus_Intro1D:
	db $DA
	db $C2
	db $C0
	db $FC
	db $FB
	db $C4
	db $14
	db $FD, $06
	db $CD
	db $FE, $00
	db $FF

Audio2_Mus_EndGameB:
	db $DB, $11, $C1, $52, $AB, $26, $B5
	db $C2
	db $EF, $02
	db $EC, $05
	db $E9, $A1
	db $E3
	db $0C
	db $04
	db $E2
	db $BC
	db $B4
	db $9C
	db $92
	db $B2
	db $E3
	db $08
	db $E2
	db $B4
	db $E3
	db $02
	db $22
	db $4C
	db $E1
	db $71
	db $B1
	db $E2
	db $01
	db $21
	db $E9, $C1
	db $FC
	db $E8, $16
	db $C4
	db $42
	db $22
	db $56
	db $42
	db $40
	db $C4
	db $42
	db $22
	db $56
	db $42
	db $26
	db $02
	db $08
	db $04
	db $02
	db $E1
	db $B2
	db $E2
	db $22
	db $06
	db $04
	db $02
	db $E1
	db $B2
	db $E2
	db $22
	db $06
	db $14
	db $22
	db $42
	db $62
	db $52
	db $62
	db $92
	db $8C
	db $11
	db $41
	db $61
	db $81
	db $E8, $15
	db $94
	db $92
	db $82
	db $B6
	db $92
	db $94
	db $E3
	db $18
	db $E2
	db $B4
	db $86
	db $62
	db $96
	db $82
	db $84
	db $BC
	db $E1
	db $64
	db $E2
	db $62
	db $52
	db $86
	db $62
	db $64
	db $92
	db $82
	db $B2
	db $82
	db $92
	db $B2
	db $E3
	db $18
	db $18
	db $E2
	db $90
	db $FE, $00
	db $FF

Audio2_Mus_EndGameA:
	db $DB, $11, $81, $52, $AB, $26, $B5
	db $C2
	db $EF, $01
	db $EC, $05
	db $E2
	db $4C
	db $44
	db $2C
	db $24
	db $0C
	db $02
	db $22
	db $48
	db $28
	db $E2
	db $02
	db $42
	db $72
	db $E3
	db $02
	db $E2
	db $42
	db $72
	db $E3
	db $02
	db $42
	db $FC
	db $E8, $0B
	db $EE, $04
	db $FB
	db $E2
	db $72
	db $42
	db $FD, $0B
	db $FB
	db $E2
	db $92
	db $52
	db $FD, $0B
	db $FB
	db $E2
	db $62
	db $12
	db $FD, $03
	db $FB
	db $E2
	db $82
	db $32
	db $FD, $02
	db $EE, $05
	db $E8, $16
	db $11
	db $41
	db $61
	db $81
	db $44
	db $42
	db $32
	db $86
	db $42
	db $44
	db $98
	db $84
	db $46
	db $32
	db $66
	db $42
	db $44
	db $8C
	db $E1
	db $94
	db $E2
	db $C1
	db $62
	db $52
	db $86
	db $62
	db $64
	db $92
	db $82
	db $B1
	db $42
	db $62
	db $82
	db $98
	db $98
	db $40
	db $FE, $00
	db $FF

Audio2_Mus_EndGameC:
	db $DB, $01, $86, $B0
	db $C2
	db $EC, $05
	db $E2
	db $9C
	db $94
	db $7C
	db $74
	db $5C
	db $52
	db $72
	db $98
	db $78
	db $00
	db $FC
	db $E2
	db $06
	db $02
	db $08
	db $06
	db $02
	db $02
	db $E1
	db $42
	db $72
	db $92
	db $A6
	db $A2
	db $A6
	db $A2
	db $96
	db $92
	db $92
	db $52
	db $94
	db $56
	db $52
	db $58
	db $56
	db $52
	db $52
	db $02
	db $32
	db $52
	db $66
	db $62
	db $66
	db $62
	db $86
	db $82
	db $86
	db $82
	db $E1
	db $96
	db $92
	db $E2
	db $46
	db $42
	db $E1
	db $96
	db $92
	db $96
	db $92
	db $46
	db $42
	db $46
	db $42
	db $46
	db $42
	db $B2
	db $92
	db $82
	db $42
	db $FB
	db $E1
	db $26
	db $22
	db $FD, $02
	db $22
	db $12
	db $22
	db $42
	db $68
	db $68
	db $90
	db $FE, $00
	db $FF

Audio2_Mus_EndGameD:
	db $DB
	db $C2
	db $FB
	db $C0
	db $FD, $03
	db $CC
	db $11
	db $11
	db $22
	db $FC
	db $FB
	db $12
	db $12
	db $12
	db $12
	db $12
	db $12
	db $32
	db $12
	db $FD, $06
	db $12
	db $12
	db $32
	db $12
	db $12
	db $12
	db $31
	db $31
	db $31
	db $31
	db $24
	db $32
	db $12
	db $12
	db $12
	db $32
	db $12
	db $FB
	db $12
	db $12
	db $32
	db $12
	db $12
	db $12
	db $32
	db $12
	db $FD, $03
	db $12
	db $12
	db $32
	db $12
	db $12
	db $32
	db $32
	db $32
	db $28
	db $28
	db $28
	db $C4
	db $11
	db $11
	db $22
	db $FE, $00
	db $FF

Audio2_Mus_LightIntroB:
	db $D6, $10, $91, $43, $8B, $15, $C6
	db $FB
	db $C4
	db $E3
	db $62
	db $C2
	db $E8, $12
	db $E9, $B1
	db $92
	db $22
	db $92
	db $7C
	db $C4
	db $E8, $10
	db $E9, $91
	db $E2
	db $94
	db $C4
	db $E9, $B1
	db $E8, $12
	db $E3
	db $B4
	db $72
	db $42
	db $24
	db $62
	db $22
	db $44
	db $62
	db $72
	db $42
	db $E9, $91
	db $FD, $00

Audio2_Mus_LightIntroA:
	db $D6, $10, $91, $00, $89, $23, $A6
	db $FB
	db $E1
	db $92
	db $91
	db $91
	db $E2
	db $92
	db $E1
	db $91
	db $91
	db $E2
	db $62
	db $22
	db $62
	db $44
	db $41
	db $41
	db $42
	db $41
	db $41
	db $42
	db $62
	db $72
	db $44
	db $42
	db $E1
	db $72
	db $E2
	db $41
	db $41
	db $42
	db $41
	db $41
	db $42
	db $64
	db $92
	db $62
	db $74
	db $92
	db $B2
	db $72
	db $FD, $00

Audio2_Mus_LightIntroC:
	db $D6, $06, $85, $80
	db $FB
	db $E2
	db $22
	db $FC
	db $21
	db $21
	db $22
	db $FE, $02
	db $F2, $C0
	db $14
	db $F2, $80
	db $FC
	db $11
	db $11
	db $12
	db $FE, $02
	db $F2, $C0
	db $04
	db $F2, $80
	db $FC
	db $01
	db $01
	db $02
	db $FE, $02
	db $F2, $C0
	db $E1
	db $B4
	db $F2, $80
	db $B1
	db $B1
	db $B2
	db $F2, $C0
	db $94
	db $F2, $A0
	db $B2
	db $E2
	db $12
	db $E1
	db $92
	db $F2, $80
	db $FD, $00

Audio2_Mus_LightIntroD:
	db $D6
	db $FC
	db $FB
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $12
	db $11
	db $11
	db $32
	db $32
	db $FD, $02
	db $12
	db $32
	db $32
	db $32
	db $71
	db $71
	db $72
	db $81
	db $81
	db $91
	db $91
	db $FE, $00

Audio2_Mus_Intro2B:
	db $DA, $00, $B1, $00, $8B, $35, $77
	db $FB
	db $E1
	db $BA
	db $92
	db $B3
	db $E2
	db $51
	db $E1
	db $B0
	db $F6, $01
	db $E9, $81
	db $E3
	db $B4
	db $74
	db $54
	db $F6, $0A
	db $E9, $B1
	db $E2
	db $B8
	db $F6, $01
	db $C8
	db $F6, $0A
	db $92
	db $B3
	db $53
	db $F6, $01
	db $E9, $81
	db $C5
	db $25
	db $15
	db $05
	db $F6, $0A
	db $E9, $B1
	db $E1
	db $BC
	db $FD, $00

Audio2_Mus_Intro2A:
	db $DA, $11, $91, $22, $89, $35, $85
	db $E1
	db $FC
	db $14
	db $FE, $00

Audio2_Mus_Intro2C:
	db $DA, $04, $87, $80
	db $E1
	db $FC
	db $74
	db $FE, $00

Audio2_Mus_Intro2D:
	db $DA
	db $FC
	db $FB
	db $C4
	db $31
	db $31
	db $31
	db $31
	db $32
	db $32
	db $C4
	db $FD, $02
	db $C4
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $C2
	db $31
	db $31
	db $C2
	db $FE, $00

Audio2_Mus_PasswordB:
	db $D7, $21, $B1, $24, $8B, $35, $C4
	db $FB
	db $E3
	db $C2
	db $51
	db $C1
	db $42
	db $51
	db $83
	db $71
	db $C1
	db $52
	db $E4
	db $16
	db $E3
	db $A4
	db $84
	db $53
	db $A1
	db $D7, $00, $71, $00, $87, $23, $94
	db $EF, $02
	db $F7
	dw Audio2_Mus_PasswordA_1
	db $F7
	dw Audio2_Mus_PasswordA_1
	db $D7, $21, $B1, $24, $8B, $35, $C4
	db $EF, $00
	db $C2
	db $E3
	db $61
	db $C1
	db $A2
	db $E4
	db $11
	db $33
	db $51
	db $C1
	db $11
	db $C1
	db $E3
	db $84
	db $A1
	db $C1
	db $84
	db $C2
	db $62
	db $53
	db $33
	db $E2
	db $92
	db $E3
	db $32
	db $C4
	db $02
	db $32
	db $9A
	db $C8
	db $FD, $00

Audio2_Mus_PasswordA:
	db $D7, $10, $91, $00, $89, $23, $94
	db $FB
	db $F7
	dw Audio2_Mus_PasswordA_1
	db $FD, $03
	db $E2
	db $FB
	db $C2
	db $31
	db $E1
	db $A1
	db $E2
	db $11
	db $31
	db $C1
	db $31
	db $C1
	db $31
	db $E1
	db $A1
	db $C1
	db $E2
	db $12
	db $32
	db $FD, $01
	db $C2
	db $51
	db $01
	db $31
	db $51
	db $C1
	db $51
	db $C1
	db $51
	db $01
	db $C1
	db $32
	db $52
	db $C2
	db $52
	db $42
	db $32
	db $12
	db $E1
	db $A1
	db $83
	db $92
	db $FE, $00

Audio2_Mus_PasswordA_1:
	db $E1
	db $C2
	db $A1
	db $51
	db $81
	db $A1
	db $C1
	db $A1
	db $C1
	db $A1
	db $51
	db $C1
	db $82
	db $A2
	db $F9

Audio2_Mus_PasswordC:
	db $FB
	db $D7, $04, $85, $F0
	db $E2
	db $A2
	db $F6, $01
	db $A1
	db $91
	db $81
	db $71
	db $61
	db $51
	db $41
	db $31
	db $21
	db $11
	db $01
	db $E1
	db $B1
	db $C2
	db $D7, $04, $85, $A0
	db $E1
	db $A4
	db $A2
	db $82
	db $A2
	db $E2
	db $15
	db $11
	db $E1
	db $A4
	db $82
	db $52
	db $82
	db $92
	db $A3
	db $A1
	db $52
	db $82
	db $A2
	db $82
	db $A2
	db $E2
	db $14
	db $52
	db $42
	db $32
	db $12
	db $E1
	db $A2
	db $82
	db $52
	db $33
	db $31
	db $E2
	db $34
	db $12
	db $E1
	db $A2
	db $E2
	db $12
	db $34
	db $32
	db $12
	db $E1
	db $A4
	db $82
	db $A2
	db $E2
	db $12
	db $D7, $04, $85, $F0
	db $52
	db $F6, $01
	db $51
	db $41
	db $31
	db $21
	db $11
	db $01
	db $E1
	db $B1
	db $A1
	db $91
	db $81
	db $71
	db $61
	db $C2
	db $D7, $04, $85, $B0
	db $E1
	db $54
	db $92
	db $E2
	db $02
	db $32
	db $52
	db $C2
	db $E3
	db $52
	db $42
	db $32
	db $12
	db $E2
	db $A1
	db $83
	db $92
	db $FD, $00

Audio2_Mus_PasswordD:
	db $D7
	db $FB
	db $12
	db $52
	db $32
	db $11
	db $31
	db $22
	db $32
	db $32
	db $11
	db $21
	db $12
	db $51
	db $31
	db $22
	db $32
	db $11
	db $31
	db $11
	db $31
	db $21
	db $71
	db $22
	db $32
	db $52
	db $32
	db $11
	db $31
	db $22
	db $32
	db $32
	db $11
	db $21
	db $12
	db $52
	db $32
	db $21
	db $F6, $01
	db $13
	db $14
	db $F6, $07
	db $11
	db $31
	db $11
	db $31
	db $21
	db $71
	db $31
	db $81
	db $12
	db $52
	db $32
	db $11
	db $31
	db $22
	db $32
	db $32
	db $11
	db $21
	db $12
	db $52
	db $32
	db $22
	db $11
	db $31
	db $11
	db $31
	db $32
	db $22
	db $32
	db $52
	db $32
	db $11
	db $31
	db $22
	db $32
	db $32
	db $11
	db $21
	db $24
	db $24
	db $F6, $01
	db $34
	db $35
	db $35
	db $F6, $07
	db $31
	db $31
	db $51
	db $31
	db $31
	db $21
	db $FD, $00

Audio2_Mus_SunstarB:
	db $D1, $01, $B1, $00, $8B, $35, $C6
	db $E3
	db $B5
	db $E4
	db $25
	db $E3
	db $B5
	db $A5
	db $94
	db $74
	db $94
	db $74
	db $44
	db $34
	db $24
	db $E2
	db $B5
	db $E3
	db $25
	db $E2
	db $B5
	db $A5
	db $94
	db $74
	db $94
	db $74
	db $44
	db $34
	db $24
	db $F6, $06
	db $F2, $F0
	db $E1
	db $B3
	db $E8, $11
	db $A1
	db $B5
	db $A1
	db $91
	db $81
	db $71
	db $61
	db $51
	db $41
	db $F2, $C6
	db $E8, $01
	db $FB
	db $E2
	db $49
	db $23
	db $31
	db $C1
	db $41
	db $C1
	db $73
	db $93
	db $4A
	db $49
	db $23
	db $31
	db $C1
	db $41
	db $C1
	db $73
	db $93
	db $E3
	db $23
	db $E2
	db $B2
	db $91
	db $C2
	db $52
	db $49
	db $23
	db $31
	db $C1
	db $41
	db $C1
	db $73
	db $93
	db $4A
	db $49
	db $23
	db $31
	db $C1
	db $41
	db $C1
	db $F6, $01
	db $E1
	db $94
	db $84
	db $74
	db $84
	db $94
	db $A4
	db $B4
	db $E2
	db $24
	db $34
	db $44
	db $54
	db $64
	db $94
	db $A4
	db $B4
	db $E3
	db $24
	db $E2
	db $B4
	db $A4
	db $94
	db $A4
	db $B4
	db $E3
	db $24
	db $74
	db $94
	db $F6, $06
	db $B2
	db $C2
	db $42
	db $C1
	db $22
	db $E2
	db $91
	db $B1
	db $E3
	db $21
	db $31
	db $41
	db $61
	db $91
	db $B1
	db $C1
	db $E4
	db $41
	db $C1
	db $32
	db $21
	db $E3
	db $B3
	db $A1
	db $C1
	db $91
	db $C1
	db $71
	db $C1
	db $91
	db $C1
	db $41
	db $C1
	db $71
	db $C1
	db $91
	db $C1
	db $E4
	db $33
	db $03
	db $E3
	db $92
	db $B2
	db $C2
	db $F6, $01
	db $B4
	db $E4
	db $34
	db $24
	db $E3
	db $B4
	db $A4
	db $94
	db $64
	db $94
	db $B4
	db $94
	db $64
	db $34
	db $F2, $F0
	db $E2
	db $B0
	db $E8, $11
	db $A1
	db $91
	db $81
	db $71
	db $61
	db $51
	db $C2
	db $F2, $C6
	db $F6, $06
	db $E8, $01
	db $41
	db $E1
	db $B1
	db $E2
	db $21
	db $31
	db $41
	db $41
	db $C1
	db $72
	db $71
	db $41
	db $C1
	db $22
	db $31
	db $42
	db $E1
	db $B1
	db $E2
	db $21
	db $31
	db $41
	db $41
	db $C1
	db $72
	db $A1
	db $B1
	db $71
	db $41
	db $31
	db $21
	db $E1
	db $B1
	db $FD, $00

Audio2_Mus_SunstarA:
	db $D6, $00, $91, $00, $89, $24, $C7
	db $C0
	db $F2, $F0
	db $E1
	db $63
	db $51
	db $65
	db $51
	db $41
	db $31
	db $21
	db $11
	db $01
	db $E0
	db $B1
	db $F2, $C7
	db $FC
	db $B9
	db $93
	db $A2
	db $B2
	db $E2
	db $23
	db $43
	db $E1
	db $BA
	db $B9
	db $93
	db $A2
	db $B2
	db $E2
	db $23
	db $43
	db $93
	db $52
	db $51
	db $C2
	db $02
	db $E1
	db $B9
	db $93
	db $A2
	db $B2
	db $E2
	db $23
	db $43
	db $E1
	db $BA
	db $B9
	db $93
	db $A2
	db $B2
	db $C2
	db $E3
	db $32
	db $C2
	db $32
	db $E1
	db $62
	db $62
	db $62
	db $62
	db $E2
	db $41
	db $E1
	db $B1
	db $B2
	db $B1
	db $B1
	db $B1
	db $B2
	db $B1
	db $B1
	db $B1
	db $B1
	db $B1
	db $B1
	db $B1
	db $E2
	db $41
	db $E1
	db $71
	db $E2
	db $B1
	db $E1
	db $71
	db $E2
	db $A1
	db $E1
	db $71
	db $E2
	db $91
	db $62
	db $E1
	db $41
	db $E2
	db $41
	db $E1
	db $41
	db $E2
	db $31
	db $E1
	db $61
	db $E2
	db $31
	db $E1
	db $61
	db $E2
	db $01
	db $E1
	db $41
	db $91
	db $41
	db $E2
	db $01
	db $E1
	db $41
	db $E2
	db $41
	db $E1
	db $41
	db $E2
	db $91
	db $E1
	db $01
	db $01
	db $E2
	db $51
	db $E1
	db $01
	db $01
	db $E2
	db $01
	db $E1
	db $01
	db $32
	db $C2
	db $C8
	db $F6, $01
	db $F2, $F0
	db $60
	db $51
	db $41
	db $31
	db $21
	db $01
	db $E0
	db $B1
	db $C2
	db $F2, $C7
	db $F6, $06
	db $C5
	db $E0
	db $B1
	db $CA
	db $C5
	db $E0
	db $B1
	db $C6
	db $E1
	db $B1
	db $A1
	db $91
	db $61
	db $FE, $00

Audio2_Mus_SunstarC:
	db $D6, $04, $85, $C0
	db $C0
	db $F2, $F0
	db $E1
	db $B3
	db $A1
	db $B5
	db $A1
	db $91
	db $81
	db $71
	db $61
	db $51
	db $41
	db $D6, $04, $81, $80
	db $FC
	db $FB
	db $41
	db $41
	db $41
	db $41
	db $FD, $0B
	db $41
	db $41
	db $41
	db $42
	db $41
	db $53
	db $51
	db $51
	db $51
	db $51
	db $51
	db $52
	db $FB
	db $41
	db $41
	db $41
	db $41
	db $FD, $0B
	db $B2
	db $E9, $01
	db $E3
	db $32
	db $E1
	db $E9, $81
	db $B2
	db $E9, $01
	db $E3
	db $32
	db $E1
	db $E9, $81
	db $B2
	db $B2
	db $B2
	db $B2
	db $E2
	db $41
	db $41
	db $41
	db $41
	db $41
	db $41
	db $41
	db $22
	db $21
	db $21
	db $21
	db $21
	db $21
	db $21
	db $21
	db $01
	db $01
	db $01
	db $01
	db $01
	db $01
	db $01
	db $E1
	db $B2
	db $B1
	db $B1
	db $B1
	db $B1
	db $B1
	db $B1
	db $B1
	db $91
	db $91
	db $91
	db $91
	db $91
	db $91
	db $91
	db $91
	db $51
	db $51
	db $51
	db $51
	db $51
	db $51
	db $51
	db $51
	db $B2
	db $CA
	db $F6, $01
	db $F2, $F0
	db $E2
	db $B0
	db $A1
	db $91
	db $81
	db $71
	db $61
	db $51
	db $C2
	db $F6, $06
	db $F2, $80
	db $E1
	db $C5
	db $E1
	db $41
	db $CA
	db $C5
	db $E1
	db $41
	db $CA
	db $FE, $00

Audio2_Mus_SunstarD:
	db $D1
	db $35
	db $35
	db $35
	db $35
	db $34
	db $34
	db $34
	db $34
	db $34
	db $34
	db $34
	db $35
	db $35
	db $35
	db $35
	db $34
	db $34
	db $34
	db $34
	db $34
	db $34
	db $34
	db $54
	db $54
	db $34
	db $34
	db $54
	db $54
	db $54
	db $34
	db $54
	db $34
	db $54
	db $34
	db $34
	db $64
	db $34
	db $74
	db $34
	db $84
	db $94
	db $94
	db $94
	db $94
	db $94
	db $94
	db $FC
	db $D6
	db $FB
	db $22
	db $32
	db $22
	db $32
	db $22
	db $32
	db $22
	db $32
	db $FD, $02
	db $62
	db $31
	db $61
	db $22
	db $72
	db $21
	db $31
	db $31
	db $31
	db $31
	db $31
	db $41
	db $31
	db $FB
	db $22
	db $32
	db $22
	db $32
	db $22
	db $32
	db $22
	db $32
	db $FD, $02
	db $22
	db $32
	db $22
	db $32
	db $22
	db $22
	db $22
	db $22
	db $FB
	db $22
	db $32
	db $22
	db $31
	db $23
	db $32
	db $22
	db $32
	db $FD, $01
	db $22
	db $32
	db $22
	db $32
	db $22
	db $32
	db $22
	db $32
	db $22
	db $22
	db $22
	db $22
	db $24
	db $24
	db $12
	db $12
	db $11
	db $21
	db $12
	db $12
	db $12
	db $12
	db $12
	db $12
	db $12
	db $11
	db $21
	db $12
	db $12
	db $12
	db $31
	db $31
	db $31
	db $31
	db $FE, $00
	db $FF

Audio2_Mus_FinalVictoryB:
	db $D5, $01, $B1, $00, $8B, $25, $F0
	db $E3
	db $62
	db $F6, $01
	db $EE, $05
	db $51
	db $41
	db $31
	db $21
	db $11
	db $EE, $04
	db $01
	db $E2
	db $B1
	db $A1
	db $91
	db $81
	db $D5, $01, $B1, $00, $8B, $25, $C6
	db $E2
	db $62
	db $62
	db $62
	db $E3
	db $62
	db $C2
	db $64
	db $92
	db $82
	db $42
	db $92
	db $82
	db $42
	db $64
	db $E2
	db $62
	db $92
	db $B2
	db $E3
	db $12
	db $44
	db $52
	db $62
	db $62
	db $42
	db $62
	db $C2
	db $62
	db $42
	db $6A
	db $FF

Audio2_Mus_FinalVictoryA:
	db $D5, $00, $B1, $00, $8B, $25, $F0
	db $E3
	db $12
	db $F6, $01
	db $EE, $05
	db $01
	db $E2
	db $B1
	db $A1
	db $91
	db $81
	db $EE, $04
	db $71
	db $61
	db $51
	db $41
	db $31
	db $D5, $00, $B1, $00, $8B, $25, $C6
	db $E2
	db $12
	db $12
	db $12
	db $E3
	db $12
	db $C2
	db $14
	db $EF, $01
	db $D5, $00, $81, $00, $88, $23, $C7
	db $C1
	db $92
	db $82
	db $42
	db $92
	db $82
	db $42
	db $63
	db $EF, $01
	db $D5, $00, $B1, $00, $8B, $25, $C6
	db $E2
	db $12
	db $62
	db $82
	db $92
	db $94
	db $92
	db $E3
	db $12
	db $12
	db $12
	db $12
	db $C2
	db $12
	db $12
	db $1A
	db $FF

Audio2_Mus_FinalVictoryC:
	db $D5, $05, $84, $C0
	db $E1
	db $64
	db $92
	db $62
	db $B2
	db $62
	db $C2
	db $64
	db $42
	db $42
	db $42
	db $42
	db $42
	db $42
	db $64
	db $62
	db $92
	db $B2
	db $E2
	db $12
	db $E1
	db $44
	db $52
	db $62
	db $62
	db $62
	db $62
	db $C2
	db $62
	db $62
	db $6A
	db $FF

Audio2_Mus_FinalVictoryD:
	db $D5
	db $24
	db $32
	db $12
	db $12
	db $12
	db $32
	db $24
	db $12
	db $32
	db $32
	db $12
	db $32
	db $32
	db $24
	db $32
	db $32
	db $32
	db $32
	db $34
	db $32
	db $32
	db $32
	db $32
	db $34
	db $32
	db $32
	db $24
	db $FF

Audio2_Mus_VenusB:
	db $D6, $10, $B1, $25, $8B, $35, $A6
	db $FC
	db $C2
	db $E3
	db $41
	db $C2
	db $32
	db $21
	db $C8
	db $E2
	db $71
	db $C1
	db $41
	db $C1
	db $22
	db $31
	db $42
	db $E1
	db $B1
	db $A1
	db $91
	db $F6, $01
	db $74
	db $94
	db $74
	db $44
	db $34
	db $24
	db $F6, $06
	db $C2
	db $E3
	db $41
	db $C2
	db $32
	db $21
	db $C8
	db $E2
	db $71
	db $C1
	db $41
	db $C1
	db $22
	db $E1
	db $B1
	db $E2
	db $12
	db $21
	db $41
	db $C1
	db $32
	db $E1
	db $B1
	db $E8, $12
	db $F6, $01
	db $E9, $81
	db $E3
	db $C2
	db $92
	db $E8, $22
	db $A2
	db $F6, $06
	db $E9, $B1
	db $B1
	db $C1
	db $E8, $12
	db $A1
	db $C1
	db $92
	db $71
	db $43
	db $21
	db $C1
	db $72
	db $91
	db $A3
	db $B1
	db $C1
	db $E4
	db $22
	db $71
	db $B3
	db $A1
	db $C1
	db $91
	db $C1
	db $71
	db $C1
	db $E8, $10
	db $C2
	db $E3
	db $41
	db $C2
	db $32
	db $21
	db $C8
	db $C1
	db $21
	db $31
	db $41
	db $71
	db $A1
	db $B1
	db $21
	db $41
	db $31
	db $21
	db $E2
	db $B1
	db $32
	db $E1
	db $B2
	db $E8, $12
	db $E4
	db $B1
	db $C1
	db $A1
	db $C1
	db $B2
	db $A1
	db $93
	db $71
	db $C1
	db $42
	db $21
	db $33
	db $41
	db $C1
	db $72
	db $E3
	db $B1
	db $A3
	db $F6, $01
	db $94
	db $A4
	db $B4
	db $F6, $06
	db $E4
	db $22
	db $E3
	db $71
	db $C1
	db $E8, $10
	db $C2
	db $E3
	db $41
	db $C2
	db $32
	db $21
	db $C8
	db $C1
	db $21
	db $31
	db $41
	db $71
	db $A1
	db $B1
	db $21
	db $41
	db $31
	db $21
	db $E2
	db $B1
	db $32
	db $E1
	db $B2
	db $E8, $12
	db $E3
	db $C2
	db $91
	db $C1
	db $42
	db $71
	db $93
	db $E4
	db $01
	db $C1
	db $21
	db $C1
	db $01
	db $C1
	db $41
	db $C1
	db $71
	db $C1
	db $92
	db $B1
	db $73
	db $01
	db $C1
	db $21
	db $C1
	db $41
	db $C1
	db $63
	db $E3
	db $B3
	db $91
	db $C1
	db $B2
	db $E4
	db $21
	db $C1
	db $E3
	db $B1
	db $C1
	db $91
	db $C1
	db $61
	db $C2
	db $61
	db $C2
	db $62
	db $C4
	db $E8, $10
	db $E3
	db $74
	db $E8, $12
	db $E4
	db $C2
	db $71
	db $C3
	db $41
	db $23
	db $E3
	db $B2
	db $E4
	db $22
	db $41
	db $C1
	db $C0
	db $C1
	db $E4
	db $F6, $01
	db $E9, $81
	db $C2
	db $92
	db $E8, $22
	db $A2
	db $F6, $06
	db $E9, $B1
	db $B1
	db $C1
	db $A2
	db $91
	db $73
	db $41
	db $C1
	db $F6, $01
	db $22
	db $32
	db $E8, $22
	db $44
	db $32
	db $22
	db $E8, $12
	db $F6, $06
	db $E3
	db $B1
	db $93
	db $B1
	db $E4
	db $23
	db $72
	db $94
	db $74
	db $E8, $10
	db $FE, $00

Audio2_Mus_VenusA:
	db $D6, $10, $91, $00, $89, $24, $C7
	db $FC
	db $E2
	db $C2
	db $71
	db $C2
	db $72
	db $61
	db $C8
	db $C0
	db $C2
	db $71
	db $C2
	db $72
	db $61
	db $C8
	db $CC
	db $E1
	db $62
	db $32
	db $FB
	db $E1
	db $C2
	db $72
	db $C2
	db $72
	db $C2
	db $72
	db $C2
	db $72
	db $C2
	db $72
	db $C2
	db $72
	db $C2
	db $72
	db $C2
	db $72
	db $C2
	db $E2
	db $71
	db $C2
	db $72
	db $71
	db $C2
	db $E1
	db $72
	db $C2
	db $72
	db $C2
	db $72
	db $C2
	db $72
	db $C2
	db $72
	db $62
	db $32
	db $FD, $01
	db $E2
	db $FB
	db $C2
	db $02
	db $FD, $07
	db $FB
	db $C2
	db $22
	db $FD, $03
	db $31
	db $E1
	db $B1
	db $B1
	db $E2
	db $31
	db $E1
	db $B1
	db $B1
	db $E2
	db $32
	db $C4
	db $E3
	db $24
	db $C2
	db $E1
	db $B2
	db $C2
	db $72
	db $C2
	db $72
	db $C2
	db $72
	db $42
	db $22
	db $32
	db $41
	db $72
	db $71
	db $42
	db $22
	db $E2
	db $22
	db $C2
	db $42
	db $C2
	db $42
	db $C2
	db $02
	db $C2
	db $E1
	db $71
	db $63
	db $61
	db $93
	db $B2
	db $64
	db $E2
	db $34
	db $FE, $00

Audio2_Mus_VenusC:
	db $D6, $05, $86, $A0
	db $FC
	db $FB
	db $E1
	db $42
	db $22
	db $42
	db $72
	db $A2
	db $B1
	db $23
	db $32
	db $42
	db $22
	db $42
	db $71
	db $A3
	db $B2
	db $E2
	db $F6, $01
	db $F2, $F0
	db $29
	db $12
	db $02
	db $E1
	db $B2
	db $A1
	db $91
	db $81
	db $71
	db $61
	db $51
	db $41
	db $31
	db $21
	db $F2, $A0
	db $F6, $06
	db $42
	db $22
	db $42
	db $72
	db $A2
	db $B1
	db $23
	db $32
	db $42
	db $22
	db $42
	db $71
	db $A3
	db $B2
	db $E2
	db $22
	db $E1
	db $72
	db $FD, $02
	db $92
	db $72
	db $92
	db $42
	db $72
	db $91
	db $E2
	db $03
	db $E1
	db $72
	db $92
	db $E2
	db $42
	db $32
	db $21
	db $03
	db $E1
	db $92
	db $72
	db $92
	db $B2
	db $92
	db $B2
	db $62
	db $92
	db $B1
	db $E2
	db $23
	db $E1
	db $91
	db $A1
	db $B2
	db $C1
	db $B1
	db $C2
	db $B2
	db $C4
	db $E3
	db $94
	db $E1
	db $42
	db $E2
	db $42
	db $32
	db $21
	db $E1
	db $B3
	db $A2
	db $92
	db $72
	db $42
	db $22
	db $32
	db $41
	db $72
	db $71
	db $42
	db $22
	db $E2
	db $22
	db $02
	db $E1
	db $02
	db $72
	db $E2
	db $01
	db $42
	db $41
	db $32
	db $22
	db $01
	db $E1
	db $B3
	db $91
	db $B3
	db $E2
	db $22
	db $E1
	db $B4
	db $B4
	db $FE, $00

Audio2_Mus_VenusD:
	db $D6
	db $FC
	db $FB
	db $12
	db $22
	db $32
	db $21
	db $33
	db $21
	db $33
	db $22
	db $12
	db $22
	db $32
	db $21
	db $33
	db $22
	db $32
	db $22
	db $12
	db $22
	db $32
	db $21
	db $33
	db $21
	db $33
	db $22
	db $12
	db $22
	db $32
	db $21
	db $33
	db $22
	db $31
	db $71
	db $82
	db $FD, $02
	db $12
	db $22
	db $32
	db $21
	db $33
	db $21
	db $33
	db $22
	db $12
	db $22
	db $32
	db $21
	db $33
	db $22
	db $32
	db $22
	db $12
	db $22
	db $32
	db $21
	db $33
	db $21
	db $33
	db $22
	db $31
	db $51
	db $51
	db $31
	db $51
	db $51
	db $36
	db $52
	db $52
	db $FB
	db $12
	db $22
	db $32
	db $21
	db $33
	db $22
	db $32
	db $22
	db $FD, $01
	db $12
	db $22
	db $32
	db $21
	db $33
	db $22
	db $32
	db $21
	db $31
	db $12
	db $22
	db $32
	db $22
	db $D1
	db $65
	db $65
	db $65
	db $75
	db $94
	db $D6
	db $82
	db $81
	db $81
	db $FE, $00

Audio2_Mus_VictoryAltB:
	db $D4, $01, $B1, $00, $8B, $35, $F0
	db $E2
	db $7C
	db $72
	db $72
	db $74
	db $44
	db $04
	db $F4, $1B, $01
	db $04
	db $F4, $1B, $FF
	db $AC
	db $A2
	db $A2
	db $A4
	db $74
	db $34
	db $F4, $1B, $01
	db $34
	db $F6, $01
	db $1B
	db $F4, $1B, $FF
	db $6B
	db $AA
	db $F6, $04
	db $F4, $1B, $01
	db $18
	db $F6, $01
	db $3B
	db $F4, $1B, $FF
	db $8B
	db $F4, $1B, $01
	db $0A
	db $F6, $04
	db $38
	db $F6, $05
	db $50
	db $FF

Audio2_Mus_VictoryAltA:
	db $D4, $01, $A1, $00, $8A, $34, $C6
	db $EF, $01
	db $E2
	db $7C
	db $72
	db $72
	db $74
	db $74
	db $74
	db $74
	db $7C
	db $72
	db $72
	db $74
	db $74
	db $74
	db $74
	db $F4, $1B, $01
	db $F6, $01
	db $1B
	db $F4, $1B, $FF
	db $1B
	db $1A
	db $F6, $04
	db $18
	db $F6, $01
	db $3B
	db $3B
	db $3A
	db $F6, $04
	db $38
	db $F6, $05
	db $00
	db $FF

Audio2_Mus_VictoryAltC:
	db $D4, $05, $F4, $C0
	db $E1
	db $0C
	db $02
	db $02
	db $04
	db $04
	db $04
	db $F4, $1B, $01
	db $04
	db $F4, $1B, $FF
	db $3C
	db $32
	db $32
	db $34
	db $34
	db $34
	db $F4, $1B, $01
	db $34
	db $F6, $01
	db $6B
	db $F4, $1B, $FF
	db $6B
	db $6A
	db $F6, $04
	db $F4, $1B, $01
	db $68
	db $F6, $01
	db $8B
	db $F4, $1B, $FF
	db $8B
	db $F4, $1B, $01
	db $8A
	db $F6, $04
	db $88
	db $F6, $05
	db $90
	db $FF

Audio2_Mus_VictoryAltD:
	db $D4
	db $21
	db $38
	db $28
	db $38
	db $34
	db $22
	db $22
	db $38
	db $28
	db $38
	db $34
	db $22
	db $22
	db $38
	db $22
	db $22
	db $22
	db $22
	db $38
	db $22
	db $22
	db $22
	db $22
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $34
	db $FF

Audio2_Mus_TitleAltC_2:
	db $FB
	db $01
	db $C3
	db $01
	db $C1
	db $01
	db $C1
	db $FD, $03
	db $F9

Audio2_Mus_TitleAltC_1:
	db $FB
	db $21
	db $C3
	db $21
	db $C1
	db $21
	db $C1
	db $FD, $03
	db $F9

Audio2_Mus_TitleAltA_1:
	db $FB
	db $41
	db $C3
	db $41
	db $C1
	db $41
	db $C1
	db $FD, $03
	db $F9

Audio2_Mus_TitleAltC_3:
	db $FB
	db $41
	db $C3
	db $41
	db $C1
	db $41
	db $C1
	db $FD, $01
	db $41
	db $CF
	db $F9

Audio2_Mus_TitleAltB:
	db $D6, $01, $B1, $00, $8B, $25, $F0
	db $E3
	db $C0
	db $F6, $03
	db $F7
	dw Audio2_Mus_TitleAltA_1
	db $F6, $06
	db $FC
	db $71
	db $C5
	db $48
	db $C2
	db $91
	db $C5
	db $28
	db $C2
	db $B1
	db $C5
	db $08
	db $C2
	db $F4, $1B, $01
	db $22
	db $C4
	db $F4, $1B, $FF
	db $26
	db $F4, $1B, $01
	db $24
	db $40
	db $C0
	db $E2
	db $46
	db $B2
	db $F4, $1B, $01
	db $44
	db $74
	db $66
	db $72
	db $64
	db $42
	db $22
	db $41
	db $C5
	db $F6, $0C
	db $BC
	db $C1
	db $F6, $06
	db $E2
	db $46
	db $B2
	db $F4, $1B, $01
	db $44
	db $74
	db $66
	db $72
	db $64
	db $42
	db $22
	db $F6, $0C
	db $4F
	db $C1
	db $F6, $06
	db $06
	db $F4, $1B, $FF
	db $76
	db $F4, $1B, $01
	db $04
	db $26
	db $F4, $1B, $FF
	db $96
	db $F4, $1B, $01
	db $24
	db $46
	db $32
	db $42
	db $64
	db $70
	db $C2
	db $06
	db $B6
	db $94
	db $F4, $1B, $01
	db $26
	db $06
	db $F4, $1B, $FF
	db $94
	db $B0
	db $C0
	db $FE, $00
	db $FF

Audio2_Mus_TitleAltA:
	db $D6, $01, $B1, $00, $8B, $25, $C6
	db $EF, $01
	db $E2
	db $C0
	db $F6, $03
	db $EC, $07
	db $F4, $1B, $FF
	db $F7
	dw Audio2_Mus_TitleAltA_1
	db $F4, $1B, $01
	db $EC, $00
	db $F6, $06
	db $FC
	db $01
	db $C5
	db $08
	db $C2
	db $F4, $1B, $FF
	db $91
	db $C5
	db $98
	db $C2
	db $F4, $1B, $01
	db $71
	db $C5
	db $78
	db $C2
	db $92
	db $C4
	db $96
	db $94
	db $B0
	db $C0
	db $EF, $01
	db $E2
	db $E2
	db $46
	db $B2
	db $F4, $1B, $01
	db $44
	db $74
	db $66
	db $72
	db $64
	db $42
	db $22
	db $41
	db $C5
	db $BA
	db $EF, $01
	db $F4, $1B, $FF
	db $01
	db $41
	db $71
	db $B1
	db $F4, $1B, $01
	db $01
	db $F4, $1B, $FF
	db $71
	db $01
	db $41
	db $21
	db $61
	db $91
	db $F4, $1B, $01
	db $11
	db $21
	db $F4, $1B, $FF
	db $91
	db $21
	db $61
	db $EF, $01
	db $46
	db $B2
	db $F4, $1B, $01
	db $44
	db $74
	db $66
	db $72
	db $64
	db $42
	db $22
	db $F6, $0C
	db $4F
	db $C1
	db $F6, $06
	db $F4, $1B, $FF
	db $D6, $01, $B1, $00, $8B, $25, $A6
	db $06
	db $B6
	db $94
	db $26
	db $66
	db $94
	db $46
	db $76
	db $44
	db $B6
	db $76
	db $44
	db $06
	db $B6
	db $94
	db $26
	db $66
	db $94
	db $F6, $03
	db $F4, $1B, $FF
	db $FB
	db $61
	db $C3
	db $61
	db $C1
	db $61
	db $C1
	db $FD, $05
	db $61
	db $CF
	db $F4, $1B, $01
	db $F6, $06
	db $FE, $00
	db $FF

Audio2_Mus_TitleAltC:
	db $D3, $05, $84, $C0
	db $E1
	db $F7
	dw Audio2_Mus_TitleAltA_1
	db $F7
	dw Audio2_Mus_TitleAltA_1
	db $FC
	db $F7
	dw Audio2_Mus_TitleAltA_1
	db $F7
	dw Audio2_Mus_TitleAltC_1
	db $F7
	dw Audio2_Mus_TitleAltC_2
	db $F7
	dw Audio2_Mus_TitleAltC_1
	db $F7
	dw Audio2_Mus_TitleAltA_1
	db $F7
	dw Audio2_Mus_TitleAltC_3
	db $F7
	dw Audio2_Mus_TitleAltA_1
	db $F7
	dw Audio2_Mus_TitleAltC_1
	db $F7
	dw Audio2_Mus_TitleAltA_1
	db $01
	db $C3
	db $01
	db $C1
	db $01
	db $C1
	db $01
	db $C3
	db $01
	db $C1
	db $01
	db $C1
	db $21
	db $C3
	db $21
	db $C1
	db $21
	db $C1
	db $21
	db $C3
	db $21
	db $C1
	db $21
	db $C1
	db $F7
	dw Audio2_Mus_TitleAltA_1
	db $F7
	dw Audio2_Mus_TitleAltC_1
	db $F7
	dw Audio2_Mus_TitleAltA_1
	db $F7
	dw Audio2_Mus_TitleAltC_3
	db $F7
	dw Audio2_Mus_TitleAltC_2
	db $F7
	dw Audio2_Mus_TitleAltC_1
	db $F7
	dw Audio2_Mus_TitleAltA_1
	db $F7
	dw Audio2_Mus_TitleAltA_1
	db $F7
	dw Audio2_Mus_TitleAltC_2
	db $F7
	dw Audio2_Mus_TitleAltC_1
	db $F4, $1B, $FF
	db $FB
	db $B1
	db $C3
	db $B1
	db $C1
	db $B1
	db $C1
	db $FD, $05
	db $B1
	db $CF
	db $F4, $1B, $01
	db $FE, $00
	db $FF

Audio2_Mus_TitleAltD:
	db $D3
	db $E1
	db $C0
	db $C0
	db $C0
	db $C0
	db $FC
	db $F6, $06
	db $FB
	db $15
	db $C1
	db $15
	db $C1
	db $23
	db $C1
	db $FD, $03
	db $F6, $03
	db $FB
	db $31
	db $C3
	db $31
	db $C1
	db $31
	db $C1
	db $FD, $05
	db $38
	db $28
	db $FB
	db $11
	db $C3
	db $11
	db $C1
	db $11
	db $C1
	db $FD, $1D
	db $38
	db $32
	db $32
	db $32
	db $32
	db $FB
	db $11
	db $C3
	db $11
	db $C1
	db $11
	db $C1
	db $FD, $1D
	db $38
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $FE, $00
	db $FF

;Unused space (3215 bytes)
	ds 3215
