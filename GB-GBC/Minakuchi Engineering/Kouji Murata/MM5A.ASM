;Mega Man V audio disassembly (bank 1)
;Disassembly by Will Trowbridge & Claude

include "HARDWARE.INC"

def AudioROM equ $4000
def AudioBank1 equ $02
def AudioBank2 equ $17
def AudioRAM equ $DB02
def WaveRAM equ $FF30
def TrackRAMSize equ $2C

def MusC1RAM equ $DB0E
def MusC2RAM equ $DB3A
def MusC3RAM equ $DB66
def MusC4RAM equ $DB92
def SFXC1RAM equ $DBBE
def SFXC2RAM equ $DBEA
def SFXC3RAM equ $DC16
def SFXC4RAM equ $DC42

;Game variables outside the audio engine (exact use not confirmed)
def BossMus equ $D1E0
def BossMusFlag equ $DE57
def CurStage equ $DF0A
def LabMusIndex equ $DE8A
def StageMus equ $DE58
def StageMusFlag equ $DE56

;StageMacro1-3 are game routines outside the audio banks;
;they are stubbed out in FUNCTION.ASM ($01C5, $0222 and $0225).

SECTION "Audio 1", ROMX[AudioROM], BANK[$1]

	jp Audio1_PlayAudio
	jp Audio1_LoadSong
	jp Audio1_InitSound

	;Game-specific function
	jp Audio1_SetStageMus

Audio1_StageMusIDs:
	db $62		;Mercury
	db $7E		;Venus
	db $64		;Mars
	db $5E		;Neptune
	db $65		;Jupiter
	db $61		;Saturn
	db $67		;Pluto
	db $5C		;Uranus
	db $6C		;Wily
	db $00		;(No music)
	db $00		;(No music)
	db $5D		;Rush Spaceship
	db $6C		;Wily
	db $00		;(No music)
	db $FF		;(No change)
	db $00		;(No music)
	db $5E		;Neptune
	db $00		;(No music)
	db $59		;Stage select
	db $63		;Cutscene
	db $00		;(No music)
	db $63		;Cutscene
	db $6C		;Wily
	db $FF		;(No change)
	db $6D		;Intro 1
	db $7A		;Intro 2
	db $63		;Cutscene
	db $FF		;(No change)
	db $FF		;(No change)
	db $73		;End game
	db $FF		;(No change)
	db $63		;Cutscene
	db $FF		;(No change)
	db $FF		;(No change)
	db $FF		;(No change)
	db $FF		;(No change)

Audio1_LabMusIDs:
	db $78		;Shop
	db $78		;Shop
	db $79		;Light intro
	db $FF		;(No change)
	db $78		;Shop

Audio1_SetStageMus:
	ld hl, BossMusFlag
	ld a, [hl]
	ld [hl], 0
	or a
	ld d, $FF
	;For most stages, use normal boss theme
	jr nz, .SetStageMus2
	ld d, $60
	ld a, [CurStage]
	;If stage is final battle, then use Sunstar theme
	cp 11
	jr nz, .SetStageMus2

	ld d, $7C

.SetStageMus2
	;Set boss music
	ld a, d
	ld [BossMus], a
	ld hl, StageMusFlag
	ld a, [hl]
	ld [hl], 0
	or a
	ret nz
	ld a, [CurStage]
	cp $10
	jp z, Audio1_GetLabMus
	ld hl, Audio1_StageMusIDs-1
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
	ld a, [hl]

Audio1_StartStageMus:
	;$FF means "leave the audio alone" - nothing below runs, so
	;whatever is already playing carries on. A table entry of $00
	;instead falls through and silences everything by way of InitSound.
	cp $FF
	ret z
	push af
	call Audio1_InitSound
	call StageMacro1
	pop af
	ld [StageMus], a
	call StageMacro2
	;Go to game-specific routine
	jp StageMacro3

Audio1_GetLabMus:
	;Stage $10 is Dr. Light's lab, which picks its music from its own
	;five-entry table instead (the index is masked to 8, so values
	;above 4 read past the end of it)
	ld a, [LabMusIndex]
	and %00000111
	add LOW(Audio1_LabMusIDs)
	ld e, a
	ld a, 0
	adc HIGH(Audio1_LabMusIDs)
	ld d, a
	ld a, [de]
	jr Audio1_StartStageMus

Audio1_SongTab:
	;Percussion
	dw Audio1_Perc_Empty
	dw Audio1_Perc01
	dw Audio1_Perc02
	dw Audio1_Perc03
	dw Audio1_Perc04
	dw Audio1_Perc05
	dw Audio1_Perc06
	dw Audio1_Perc07
	dw Audio1_Perc08
	dw Audio1_Perc09
	dw Audio1_FadeOutTrack
	;SFX
	dw Audio1_SFXEmpty1
	dw Audio1_SFXEmpty2
	dw Audio1_SFX_Shot
	dw Audio1_SFX_ChargeShotSmall
	dw Audio1_SFX_ChargeShotLarge
	dw Audio1_SFX_Charge
	dw Audio1_SFX_Land
	dw Audio1_SFX_ExtraLife
	dw Audio1_SFX_Hurt
	dw Audio1_SFX_PlayerExplode
	dw Audio1_SFX_EnemyHit
	dw Audio1_SFX_BossExplode
	dw Audio1_SFX_Health
	dw Audio1_SFX_Shing
	dw Audio1_SFX_Select
	dw Audio1_SFX_Pause
	dw Audio1_SFX_TeleportIn
	dw Audio1_SFX_TeleportOut
	dw Audio1_SFX_Deflect
	dw Audio1_SFX_Door
	dw Audio1_SFX_Explode
	dw Audio1_SFX_Splash
	dw Audio1_SFX_WilyUFO
	dw Audio1_SFX_Error
	dw Audio1_SFX_Accept
	dw Audio1_SFX_Text
	dw Audio1_SFX_FortressExplode
	dw Audio1_SFX_RainFlush
	dw Audio1_SFX_Helicopter
	dw Audio1_SFX_Cannon
	dw Audio1_SFX_GetWeapon
	dw Audio1_SFX_Stomp
	dw Audio1_SFX_WilyMachineExplode
	dw Audio1_SFX_WilyTankMissile
	dw Audio1_SFX_ProtoMan
	dw Audio1_SFX_BigShot1
	dw Audio1_SFX_BigShot2
	dw Audio1_SFX_ShotAlt
	dw Audio1_SFX_ChargeAlt1
	dw Audio1_SFX_ChargeAlt2
	dw Audio1_SFX_ChargeAlt3
	dw Audio1_SFX_GetWeaponAlt
	dw Audio1_SFX_RushSpaceshipAccel
	dw Audio1_SFX_RushSpaceshipBlast
	dw Audio1_SFX_RushSpaceshipMotor
	dw Audio1_SFX_SuperMegaBuster
	dw Audio1_SFX_Tango
	dw Audio1_SFX_BreakDash
	dw Audio1_SFX_ElectricShock1
	dw Audio1_SFX_ElectricShock2
	dw Audio1_SFX_PhotonMissile
	dw Audio1_SFX_GrabBuster
	dw Audio1_SFX_SaltWater
	dw Audio1_SFX_BubbleBomb
	dw Audio1_SFX_SpecialWeapon
	dw Audio1_SFX_WilyStarExplode
	dw Audio1_SFX_EnemyShot
	dw Audio1_SFX_TimeFreeze
	dw Audio1_SFX_TeleportOutAlt
	dw Audio1_SFX_BubbleEnemy
	dw Audio1_SFX_TangoHit
	dw Audio1_Perc06
	dw Audio1_Perc06
	dw Audio1_Perc06
	dw Audio1_Perc06
	dw Audio1_SFX_SparkChaser1
	dw Audio1_SFX_SparkChaser2
	dw Audio1_SFX_BlackHole1
	dw Audio1_SFX_BlackHole2
	dw Audio1_SFX_ExplodeBlast
	dw Audio1_SFX_Laser
	dw Audio1_SFX_PlatformExplode
	dw Audio1_Perc06
	dw Audio1_Perc06
	dw Audio1_Perc06
	dw Audio1_Perc06
	dw Audio1_Perc06
	dw Audio1_Perc06
	;Music
	dw Audio1_Mus_StageSelect
	dw Audio1_Perc06
	dw Audio1_Mus_WilyIntro
	dw Audio1_Mus_Uranus
	dw Audio1_Mus_RushSpaceship
	dw Audio1_Mus_Neptune
	dw Audio1_Mus_CutsceneAlt
	dw Audio1_Mus_Boss
	dw Audio1_Mus_Saturn
	dw Audio1_Mus_Mercury
	dw Audio1_Mus_Cutscene
	dw Audio1_Mus_Mars
	dw Audio1_Mus_Jupiter
	dw Audio1_Mus_VenusAlt
	dw Audio1_Mus_Pluto
	dw Audio1_Perc06
	dw Audio1_Perc06
	dw Audio1_Perc06
	dw Audio1_Perc06
	dw Audio1_Mus_Wily
	dw 0				;Empty - use bank 2
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
	dw 0
	dw 0
	dw 0
	dw 0
	
Audio1_Perc_Empty:

Audio1_FadeOutTrack:
	db %00000000
	db 0
	dw Audio1_EmptySeq

Audio1_Perc01:
	db %10000000
	db 0
	dw Audio1_Perc01D

Audio1_Perc02:
	db %10000000
	db 0
	dw Audio1_Perc02D

Audio1_Perc03:
	db %10000000
	db 0
	dw Audio1_Perc03D

Audio1_Perc04:
	db %11000000
	db 0
	dw Audio1_Perc04C
	dw Audio1_Perc03D

Audio1_Perc05:
	db %10000000
	db 0
	dw Audio1_Perc05D

Audio1_Perc06:
	db %11000000
	db 0
	dw Audio1_Perc06C
	dw Audio1_Perc01D

Audio1_Perc07:
	db %11000000
	db 0
	dw Audio1_Perc07C
	dw Audio1_Perc01D

Audio1_Perc08:
	db %11000000
	db 0
	dw Audio1_Perc08C
	dw Audio1_Perc01D

Audio1_Perc09:
	db %11000000
	db 0
	dw Audio1_Perc09C
	dw Audio1_Perc01D

Audio1_SFX_Shot:
	db %00010000
	db 4
	dw Audio1_SFX_ShotA

Audio1_SFX_ChargeShotSmall:
	db %10000000
	db 4
	dw Audio1_SFX_ChargeShotSmallD

Audio1_SFX_ChargeShotLarge:
	db %10000000
	db 4
	dw Audio1_SFX_ChargeShotLargeD

Audio1_SFX_Charge:
	db %00010000
	db 3
	dw Audio1_SFX_ChargeA

Audio1_SFX_Land:
	db %00010000
	db 3
	dw Audio1_SFX_LandA

Audio1_SFX_ExtraLife:
	db %00010000
	db 10
	dw Audio1_SFX_ExtraLifeA

Audio1_SFX_Hurt:
	db %10010000
	db 11
	dw Audio1_SFX_HurtA
	dw Audio1_SFX_HurtD

Audio1_SFX_PlayerExplode:
	db %00010000
	db 12
	dw Audio1_SFX_PlayerExplodeA

Audio1_SFX_EnemyHit:
	db %10000000
	db 5
	dw Audio1_SFX_EnemyHitD

Audio1_SFX_BossExplode:
	db %10000000
	db 9
	dw Audio1_SFX_BossExplodeD

Audio1_SFX_Health:
	db %00010000
	db 10
	dw Audio1_SFX_HealthA

Audio1_SFX_Shing:
	db %00110000
	db 10
	dw Audio1_SFX_ShingA
	dw Audio1_SFX_ShingB

Audio1_SFX_Select:
	db %00010000
	db 10
	dw Audio1_SFX_SelectA

Audio1_SFX_Pause:
	db %00010000
	db 10
	dw Audio1_SFX_PauseA

Audio1_SFX_TeleportIn:
	db %00010000
	db 3
	dw Audio1_SFX_TeleportInA

Audio1_SFX_TeleportOut:
	db %00010000
	db 7
	dw Audio1_SFX_TeleportOutA

Audio1_SFX_Deflect:
	db %10000000
	db 4
	dw Audio1_SFX_DeflectD

Audio1_SFX_Door:
	db %10000000
	db 10
	dw Audio1_SFX_DoorD

Audio1_SFX_Explode:
	db %10000000
	db 7
	dw Audio1_SFX_ExplodeD

Audio1_SFX_Splash:
	db %10000000
	db 4
	dw Audio1_SFX_SplashD

Audio1_SFX_WilyUFO:
	db %00010000
	db 4
	dw Audio1_SFX_WilyUFOA

Audio1_SFX_Error:
	db %00110000
	db 10
	dw Audio1_SFX_ErrorA
	dw Audio1_SFX_ErrorB

Audio1_SFX_Accept:
	db %00110000
	db 10
	dw Audio1_SFX_AcceptA
	dw Audio1_SFX_AcceptB

Audio1_SFX_Text:
	db %10000000
	db 8
	dw Audio1_SFX_TextD

Audio1_SFX_FortressExplode:
	db %10010000
	db 9
	dw Audio1_SFX_FortressExplodeA
	dw Audio1_SFX_FortressExplodeD

Audio1_SFXEmpty1:
	db %00001111
	db 2
	dw Audio1_EmptySeq
	dw Audio1_EmptySeq
	dw Audio1_EmptySeq
	dw Audio1_EmptySeq

Audio1_SFXEmpty2:
	db %11110000
	db 15
	dw Audio1_EmptySeq
	dw Audio1_EmptySeq
	dw Audio1_EmptySeq
	dw Audio1_EmptySeq

Audio1_SFX_RainFlush:
	db %10000000
	db 4
	dw Audio1_SFX_RainFlushD

Audio1_SFX_BreakDash:
	db %10000000
	db 4
	dw Audio1_SFX_BreakDashD

Audio1_SFX_Helicopter:
	db %10000000
	db 1
	dw Audio1_SFX_HelicopterD

Audio1_SFX_Cannon:
	db %00010000
	db 2
	dw Audio1_SFX_CannonA

Audio1_SFX_GetWeapon:
	db %00110000
	db 4
	dw Audio1_SFX_GetWeaponA
	dw Audio1_SFX_GetWeaponB

Audio1_SFX_Stomp:
	db %00010000
	db 7
	dw Audio1_SFX_StompA

Audio1_SFX_WilyMachineExplode:
	db %10010000
	db 9
	dw Audio1_SFX_WilyMachineExplodeA
	dw Audio1_SFX_WilyMachineExplodeD

Audio1_SFX_WilyTankMissile:
	db %10010000
	db 9
	dw Audio1_SFX_WilyTankMissileA
	dw Audio1_SFX_WilyTankMissileD

Audio1_SFX_ProtoMan:
	db %00001111
	db 0
	dw Audio1_EmptySeq2
	dw Audio1_SFX_ProtoManB
	dw Audio1_EmptySeq2
	dw Audio1_EmptySeq2

Audio1_SFX_BigShot1:
	db %10000000
	db 4
	dw Audio1_SFX_BigShot1D

Audio1_SFX_BigShot2:
	db %10000000
	db 4
	dw Audio1_SFX_BigShot2D

Audio1_SFX_ShotAlt:
	db %00010000
	db 4
	dw Audio1_SFX_ShotAltA

Audio1_SFX_ChargeAlt1:
	db %00010000
	db 3
	dw Audio1_SFX_ChargeAlt1A

Audio1_SFX_ChargeAlt2:
	db %00010000
	db 3
	dw Audio1_SFX_ChargeAlt2A

Audio1_SFX_GetWeaponAlt:
	db %00110000
	db 4
	dw Audio1_SFX_GetWeaponAltA
	dw Audio1_SFX_GetWeaponAltB

Audio1_SFX_ChargeAlt3:
	db %00010000
	db 3
	dw Audio1_SFX_ChargeAlt3A

;Unused - nothing in the song table points at this entry
Audio1_UnusedFadeOutTrack:
	db %00010000
	db 3
	dw Audio1_UnusedFadeOutTrackA

;Unused - nothing in the song table points at this entry
Audio1_UnusedPerc01:
	db %10110000
	db 3
	dw Audio1_UnusedPerc01A
	dw Audio1_UnusedPerc01B
	dw Audio1_UnusedPerc01D

Audio1_SFX_RushSpaceshipMotor:
	db %00000001
	db 3
	dw Audio1_SFX_RushSpaceshipMotorA

Audio1_SFX_RushSpaceshipAccel:
	db %00000001
	db 3
	dw Audio1_SFX_RushSpaceshipAccelA

Audio1_SFX_RushSpaceshipBlast:
	db %10110000
	db 3
	dw Audio1_SFX_RushSpaceshipBlastA
	dw Audio1_SFX_RushSpaceshipBlastB
	dw Audio1_SFX_RushSpaceshipBlastD

Audio1_SFX_SuperMegaBuster:
	db %10000000
	db 4
	dw Audio1_SFX_SuperMegaBusterD

Audio1_SFX_Tango:
	db %00010000
	db 4
	dw Audio1_SFX_TangoA

Audio1_SFX_ElectricShock2:
	db %10000000
	db 4
	dw Audio1_SFX_ElectricShock2D

Audio1_SFX_PhotonMissile:
	db %10000000
	db 4
	dw Audio1_SFX_PhotonMissileD

Audio1_SFX_GrabBuster:
	db %10000000
	db 4
	dw Audio1_SFX_GrabBusterD

Audio1_SFX_SaltWater:
	db %10000000
	db 4
	dw Audio1_SFX_SaltWaterD

Audio1_SFX_BubbleBomb:
	db %00010000
	db 4
	dw Audio1_SFX_BubbleBombA

Audio1_SFX_ElectricShock1:
	db %10000000
	db 4
	dw Audio1_SFX_ElectricShock1D

Audio1_SFX_SparkChaser1:
	db %10000000
	db 2
	dw Audio1_SFX_SparkChaser1D

Audio1_SFX_SparkChaser2:
	db %10000000
	db 2
	dw Audio1_SFX_SparkChaser2D

Audio1_SFX_BlackHole1:
	db %10000000
	db 1
	dw Audio1_SFX_BlackHole1D

Audio1_SFX_BlackHole2:
	db %10000000
	db 1
	dw Audio1_SFX_BlackHole2D

Audio1_SFX_ExplodeBlast:
	db %10000000
	db 1
	dw Audio1_SFX_ExplodeBlastD

Audio1_SFX_Laser:
	db %00010000
	db 12
	dw Audio1_SFX_LaserA

Audio1_SFX_PlatformExplode:
	db %10000000
	db 2
	dw Audio1_SFX_PlatformExplodeD

Audio1_SFX_SpecialWeapon:
	db %10100000
	db 3
	dw Audio1_SFX_SpecialWeaponB
	dw Audio1_SFX_SpecialWeaponD

Audio1_SFX_WilyStarExplode:
	db %10110000
	db 9
	dw Audio1_SFX_WilyStarExplodeA
	dw Audio1_SFX_WilyStarExplodeB
	dw Audio1_SFX_WilyStarExplodeD

Audio1_SFX_EnemyShot:
	db %00010000
	db 2
	dw Audio1_SFX_EnemyShotA

Audio1_SFX_TangoHit:
	db %00010000
	db 1
	dw Audio1_SFX_TangoHitA

Audio1_SFX_TimeFreeze:
	db %00110000
	db 2
	dw Audio1_SFX_TimeFreezeA
	dw Audio1_SFX_TimeFreezeB

Audio1_SFX_TeleportOutAlt:
	db %00010000
	db 1
	dw Audio1_SFX_TeleportOutAltA

Audio1_SFX_BubbleEnemy:
	db %00010000
	db 1
	dw Audio1_SFX_BubbleEnemyA

Audio1_Mus_WilyIntro:
	db %00001111
	db 0
	dw Audio1_Mus_WilyIntroA
	dw Audio1_Mus_WilyIntroB
	dw Audio1_Mus_WilyIntroC
	dw Audio1_Mus_WilyIntroD

Audio1_Mus_Uranus:
	db %00001111
	db 0
	dw Audio1_Mus_UranusA
	dw Audio1_Mus_UranusB
	dw Audio1_Mus_UranusC
	dw Audio1_Mus_UranusD

Audio1_Mus_RushSpaceship:
	db %00001111
	db 0
	dw Audio1_Mus_RushSpaceshipA
	dw Audio1_Mus_RushSpaceshipB
	dw Audio1_Mus_RushSpaceshipC
	dw Audio1_Mus_RushSpaceshipD

Audio1_Mus_Wily:
	db %00001111
	db 0
	dw Audio1_Mus_WilyA
	dw Audio1_Mus_WilyB
	dw Audio1_Mus_WilyC
	dw Audio1_Mus_WilyD

Audio1_Mus_Neptune:
	db %00001111
	db 0
	dw Audio1_Mus_NeptuneA
	dw Audio1_Mus_NeptuneB
	dw Audio1_Mus_NeptuneC
	dw Audio1_Mus_NeptuneD

Audio1_Mus_CutsceneAlt:
	db %00001111
	db 0
	dw Audio1_Mus_CutsceneAltA
	dw Audio1_Mus_CutsceneAltB
	dw Audio1_Mus_CutsceneAltC
	dw Audio1_Mus_CutsceneAltD

Audio1_Mus_Boss:
	db %00001111
	db 0
	dw Audio1_Mus_BossA
	dw Audio1_Mus_BossB
	dw Audio1_Mus_BossC
	dw Audio1_Mus_BossD

Audio1_Mus_Saturn:
	db %00001111
	db 0
	dw Audio1_Mus_SaturnA
	dw Audio1_Mus_SaturnB
	dw Audio1_Mus_SaturnC
	dw Audio1_Mus_SaturnD

Audio1_Mus_Mercury:
	db %00001111
	db 0
	dw Audio1_Mus_MercuryA
	dw Audio1_Mus_MercuryB
	dw Audio1_Mus_MercuryC
	dw Audio1_Mus_MercuryD

Audio1_Mus_Cutscene:
	db %00001111
	db 0
	dw Audio1_Mus_CutsceneA
	dw Audio1_Mus_CutsceneB
	dw Audio1_Mus_CutsceneC
	dw Audio1_Mus_CutsceneD

Audio1_Mus_Mars:
	db %00001111
	db 0
	dw Audio1_Mus_MarsA
	dw Audio1_Mus_MarsB
	dw Audio1_Mus_MarsC
	dw Audio1_Mus_MarsD

Audio1_Mus_StageSelect:
	db %00001111
	db 0
	dw Audio1_Mus_StageSelectA
	dw Audio1_Mus_StageSelectB
	dw Audio1_Mus_StageSelectC
	dw Audio1_Mus_StageSelectD

Audio1_Mus_Jupiter:
	db %00001111
	db 0
	dw Audio1_Mus_JupiterA
	dw Audio1_Mus_JupiterB
	dw Audio1_Mus_JupiterC
	dw Audio1_Mus_JupiterD

Audio1_Mus_VenusAlt:
	db %00001111
	db 0
	dw Audio1_Mus_VenusAltA
	dw Audio1_Mus_VenusAltB
	dw Audio1_Mus_VenusAltC
	dw Audio1_Mus_VenusAltD

Audio1_Mus_Pluto:
	db %00001111
	db 0
	dw Audio1_Mus_PlutoA
	dw Audio1_Mus_PlutoB
	dw Audio1_Mus_PlutoC
	dw Audio1_Mus_PlutoD

;Load song/sound effect
Audio1_LoadSong:
	;If song is 0
	or a
	jp z, Audio1_NoAudio2

	;If song is $0A, then fade out current music
	cp $0A
	jp z, Audio1_FadeOutMus
	push bc
	push de
	;Load number to SFX number RAM variable
	ld [SFXNum], a
	push af
	;Get pointer from song table
	add a
	add LOW(Audio1_SongTab)
	ld l, a
	ld a, HIGH(Audio1_SongTab)
	adc 0
	ld h, a
	pop af
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	;Entries in the song table may be blank ($0000)
	;If so, then there is nothing to play
	or h
	jr z, Audio1_LoadSongRet

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

Audio1_GetTracks:
	;Check if each track (SFX 4-1, then music 4-1) is present
	ld hl, Temp1
	srl [hl]
	;If track present
	jr c, Audio1_InitTrackRAM

	;When finished
	jr z, Audio1_LoadSongRet

Audio1_GetTracksNext:
	;Advance channel
	ld hl, CurTrack
	inc [hl]
	;Skip to next channel area in RAM
	ld hl, TrackRAMSize
	add hl, de
	ld d, h
	ld e, l
	jr Audio1_GetTracks

Audio1_LoadSongRet:
	;Return from routine
	pop de
	pop bc
	ret

Audio1_InitTrackRAM:
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
	jr Audio1_GetTracksNext

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
	ld a, LOW(Audio1_Vibrato0)
	ld [hl+], a
	ld a, HIGH(Audio1_Vibrato0)
	ld [hl], a
	pop bc
	;Add current channel mask to output value
	ld a, [CurTrack]
	push af
	add LOW(Audio1_TrackMaskVals)
	ld l, a
	ld a, HIGH(Audio1_TrackMaskVals)
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
	jr Audio1_GetTracksNext

;Call sound effect with music
Audio1_CallSFX:
	;Get sound effect number called
	push bc
	push de
	ld [SFXNum], a
	push af
	;Get sound effect pointer from RAM
	add a
	add LOW(Audio1_SongTab)
	ld l, a
	ld a, HIGH(Audio1_SongTab)
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
	jp Audio1_GetTracks

Audio1_FadeOutMus:
	ld a, 7
	ld [Fade], a
	ld [FadeTime], a
	ret

Audio1_PlayAudio:
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
	jp z, Audio1_NoAudio2
	sub %00010001
	ld [hl], a

.PlayAudio2
	call Audio1_CheckAllTracks
	jp Audio1_OutputTracks

Audio1_CheckAllTracks:
	;Check all tracks to see if they are playing
	xor a
	ld [CurTrackCheck], a
	ld de, MusC1MusNum

Audio1_CheckTrack:
	;Check if track is on (with song number)
	ld hl, $00
	add hl, de
	ld a, [hl]
	or a
	;If 0, then skip to next track
	jr z, Audio1_NextTrack

	;Process the track
	call Audio1_ProcTrack
	;Copy values to register RAM values
	call Audio1_ProcTrackRegVals

Audio1_NextTrack:
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
	jr nz, Audio1_CheckTrack
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

Audio1_ProcTrack:
	;Process note length
	ld hl, $08
	add hl, de				;Increase time
	inc [hl]
	dec hl
	dec [hl]				;Decrease delay
	;If delay is complete, then get next command
	call z, Audio1_NextCommand
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
	jp nc, Audio1_ProcVibrato

	;Check if wave channel
	ld a, [CurTrackCheck]
	and %00000011
	cp 2
	;If so, then perform special envelope handler
	jp z, Audio1_ProcEnvStateCh3

Audio1_ProcEnvState:
	;Otherwise, this is a decaying (CH1/CH2) envelope.
	;Wait out the current envelope stage.
	ld hl, $1A
	add hl, de
	dec [hl]
	;If not 0, then skip
	jp nz, Audio1_EnvSustain

	;Stage expired: pick the handler for the current envelope state.
	;State # is kept in +$18 and indexes the table below.
	ld hl, $18
	add hl, de
	ld a, [hl]
	push af
	add a
	add LOW(Audio1_EnvStates)
	ld l, a
	ld a, HIGH(Audio1_EnvStates)
	adc 0
	ld h, a
	pop af
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	jp hl

Audio1_EnvStates:
	dw Audio1_EnvState0
	dw Audio1_EnvState1
	dw Audio1_EnvState2
	dw Audio1_EnvState3
	dw Audio1_EnvState4
	dw Audio1_EnvSustain
	dw Audio1_EnvSustain
	dw Audio1_EnvSustain

Audio1_EnvState0:
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
	jr c, Audio1_EnvState1_2

	;Otherwise, multiply the volume by decay
	call Audio1_Multiply
	;If result is 0, then skip to next state
	or a
	jr z, Audio1_EnvState1_2

	;Otherwise, then save stage duration into RAM
	pop bc
	jp Audio1_SaveStageDur

Audio1_EnvState1:
	push bc

Audio1_EnvState1_2:
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
	jr c, Audio1_EnvState2_1
	call Audio1_Multiply
	or a
	;If result is 0, then skip to next state
	jr z, Audio1_EnvState2_1
	pop bc
	jp Audio1_SaveStageDur

Audio1_EnvState2:
	push bc

Audio1_EnvState2_1:
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
	jr c, Audio1_EnvState3_2
	jr z, Audio1_EnvState3_2

	;Otherwise, then save stage duration into RAM
	pop bc
	jp Audio1_SaveStageDur

Audio1_EnvState3:
	push bc

Audio1_EnvState3_2:
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
	jr c, Audio1_EnvState4_1

	;Multiply values otherwise
	call Audio1_Multiply
	or a
	;If 0, then go to next stage
	jr z, Audio1_EnvState4_1

	;Otherwise, then save stage duration into RAM
	pop bc
	jp Audio1_SaveStageDur

Audio1_EnvState4_1:
	pop bc

Audio1_EnvState4:
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
	jp Audio1_SaveStageDur

Audio1_ProcEnvStateCh3:
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
	jr c, Audio1_EnvState1Ch3
	cp 2
	jr c, Audio1_EnvState2Ch3
	cp 3
	jr c, Audio1_EnvState3Ch3
	cp 4
	jr c, Audio1_EnvState4Ch3

	;If none of the above, then return
	ret

Audio1_EnvState1Ch3:
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

Audio1_EnvState2Ch3:
	;Get new volume
	ld a, %01010000

Audio1_EnvState2Ch3_2:
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

Audio1_EnvState3Ch3:
	;Get new volume
	ld a, %00010000
	;Rest of state is same as 2
	jr Audio1_EnvState2Ch3_2

Audio1_EnvState4Ch3:
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
Audio1_ProcVibrato:
	ld hl, $1A
	add hl, de
	dec [hl]
	;If not done, then sustain
	jr nz, Audio1_EnvSustain

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
	jr nz, Audio1_GetVol

	;Decrement sequence position
	ld hl, $17
	add hl, de
	dec [hl]
	;Restart envelope duration
	ld hl, $1A
	add hl, de
	ld [hl], a
	jr Audio1_EnvSustain

Audio1_GetVol:
	;Get volume from upper 4 bits of envelope
	ld hl, $1F
	add hl, de
	push af
	and %11110000
	ld [hl], a
	;Then get duration from lower 4 bits of envelope
	pop af
	and %00001111

Audio1_SaveStageDur:
	;Load stage duration into RAM value
	ld hl, $1A
	add hl, de
	ld [hl], a

;After envelope is finished...
Audio1_EnvSustain:
	;If channel is 2, then return
	ld a, [CurTrackCheck]
	and 2
	jr nz, Audio1_ProcNextVibratoRet

	;Otherwise, decrease vibrato sequence delay
	ld hl, $19
	add hl, de
	dec [hl]
	;If not done, then return
	jp nz, Audio1_ProcNextVibratoRet

	;Increase vibrato sequence
	ld hl, $16
	add hl, de
	inc [hl]
	ld a, [hl]

Audio1_ProcNextVibrato:
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
	jr Audio1_ProcNextVibrato

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

Audio1_ProcNextVibratoRet:
	ret

Audio1_NextCommand:
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
	call Audio1_ParamsOrVCMD
	;Repeat
	jr .NextCommand2

.NoteOrRest
	;Check if track is 3 (music 4)
	ld a, [CurTrackCheck]
	cp 3
	;If so, then use special handler
	jp z, Audio1_ProcNoteMusC4

	;Otherwise, load envelope on/off address value into HL
	ld hl, $09
	add hl, de
	;Check current command
	ld a, [bc]
	cp $C0
	;If less than C0, then is a note
	jr c, Audio1_ProcNote

	;Otherwise, is a rest
	ld [hl], 0
	jp Audio1_ProcNoteMusC4_3

;It is a note
Audio1_ProcNote:
	;Set envelope on/off value to on
	ld [hl], $FF
	push bc
	push af
	;Check if track is SFX 4
	ld a, [CurTrackCheck]
	cp 7
	;If so, then perform special handler
	jr z, Audio1_ProcNoteSFXCh4

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
	add LOW(Audio1_FreqTab)
	ld c, a
	ld a, HIGH(Audio1_FreqTab)
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
	jr Audio1_ProcNote2

Audio1_ProcNoteSFXCh4:
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

Audio1_ProcNote2:
	;Reset note time
	ld hl, $08
	add hl, de
	xor a
	ld [hl], a

	;Get note length value
	ld a, [bc]
	and %00001111
	;Convert to actual note length with speed
	call Audio1_ProcNoteLen

	;Set delay to result
	ld hl, $07
	add hl, de
	ld [hl], a

	;Advance pointer
	call Audio1_AdvChanPos

	;Check for duty/volume flag
	ld hl, $11
	add hl, de
	;If highest bit not set, then skip processing delay
	bit 7, [hl]
	jr z, Audio1_ProcDelay
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
	call Audio1_Multiply
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
	call Audio1_Multiply
	add [hl]
	ld [hl], a

Audio1_ProcDelay:
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

Audio1_ProcNoteMusC4:
	;Get channel 3 SFX number
	ld a, [SFXC3MusNum]

	;If between $06 and $12, cue a tom-tom drum
	cp $06
	jr c, Audio1_ProcNoteMusC4_2
	cp $0C
	jr nc, Audio1_ProcNoteMusC4_2

	;Set pointer to "empty sequence"
	ld a, LOW(Audio1_EmptySeq)
	ld [SFXC3SongPos], a
	ld a, HIGH(Audio1_EmptySeq)
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

Audio1_ProcNoteMusC4_2:
	;Get current note value from upper 4 bits of sequence byte
	ld a, [bc]
	swap a
	;If less than $0C, then use the value to play SFX as "percussion"
	and %00001111
	cp $0C
	call nz, Audio1_CallSFX

Audio1_ProcNoteMusC4_3:
	;Get length as lower 4 bits and process the note length
	ld a, [bc]
	and %00001111
	call Audio1_ProcNoteLen

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
Audio1_AdvChanPos:
	ld hl, $20
	add hl, de
	inc bc
	ld [hl], c
	inc hl
	ld [hl], b
	ret

Audio1_ProcNoteLen:
	;Check if note length is 0
	ld hl, $0B

Audio1_ProcNoteLen2:
	add hl, de
	or a
	;If so, then set to maximum speed value
	jr z, Audio1_ProcNoteLenMax

Audio1_ProcNoteLen3:
	;Otherwise, check if less than speed
	cp [hl]
	;If not, then multiply (same as otherwise?)
	jr nc, Audio1_ProcNoteLenMult2

	;Otherwise, multiply value
	push bc
	ld c, a
	ld b, [hl]
	xor a

Audio1_ProcNoteLenMult:
	add b
	dec c
	jr nz, Audio1_ProcNoteLenMult
	pop bc
	ret

;Multiply value (same as before?)
Audio1_ProcNoteLenMult2:
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

Audio1_ProcNoteLenMax:
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
Audio1_Multiply:
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

Audio1_ParamsOrVCMD:
	;If Dx, is parameters
	sub $E0
	jr c, Audio1_GetParams
	push af

	;Otherwise, is a VCMD - get pointer to jump to from table
	add a
	add LOW(Audio1_VCMDTab)
	ld l, a
	ld a, HIGH(Audio1_VCMDTab)
	adc 0
	ld h, a
	pop af
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	jp hl

Audio1_GetParams:
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
	jr z, Audio1_GetParamsSFX4

	;If current track is 2 or 6 (music/SFX 3, then perform special handler)
	and %00000011
	cp 2
	jr z, Audio1_GetParams3

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
	call Audio1_EventVibrato
	;Final bytes are envelope and decay (if envelope is signed)
	jp Audio1_GetEnvVal

Audio1_GetParamsSFX4:
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
	jp Audio1_EventEnvDecay

Audio1_GetParams3:
	;Current byte is waveform
	dec bc
	call Audio1_EventWaveform
	;Next byte is envelope value
	ld a, [bc]
	ld hl, $11
	add hl, de
	ld [hl+], a
	;Check if envelope is at max
	add a
	;If not, then set envelope sequence
	jp nc, Audio1_GetEnvSeq

	;Otherwise, next byte is secondary decay
	inc bc
	inc hl
	ld a, [bc]
	ld [hl], a
	inc bc
	ret

Audio1_VCMDTab:
	dw Audio1_EventOctave        ;$E0
	dw Audio1_EventOctave        ;$E1
	dw Audio1_EventOctave        ;$E2
	dw Audio1_EventOctave        ;$E3
	dw Audio1_EventOctave        ;$E4
	dw Audio1_EventOctave        ;$E5
	dw Audio1_EventOctave        ;$E6
	dw Audio1_EventOctave        ;$E7
	dw Audio1_EventDutyVol       ;$E8
	dw Audio1_EventDecay         ;$E9
	dw Audio1_EventSweep         ;$EA
	dw Audio1_EventVibrato       ;$EB
	dw Audio1_EventTranspose     ;$EC
	dw Audio1_EventWaveform      ;$ED
	dw Audio1_EventEnvDecay      ;$EE
	dw Audio1_EventTuning        ;$EF
	dw Audio1_EventEnvVal        ;$F0
	dw Audio1_EventDecay2        ;$F1
	dw Audio1_EventDecay3        ;$F2
	dw Audio1_EventFinalVol      ;$F3
	dw Audio1_EventAddParam      ;$F4
	dw Audio1_EventNop           ;$F5
	dw Audio1_EventSpeed         ;$F6
	dw Audio1_EventMacro1        ;$F7
	dw Audio1_EventMacro2        ;$F8
	dw Audio1_EventMacro1Ret     ;$F9
	dw Audio1_EventMacro2Ret     ;$FA
	dw Audio1_EventRepeat1Start  ;$FB
	dw Audio1_EventRepeat2Start  ;$FC
	dw Audio1_EventRepeat1End    ;$FD
	dw Audio1_EventRepeat2End    ;$FE
	dw Audio1_EventEnd           ;$FF

Audio1_EventOctave:
;Set the current octave (0-7)
	;Get lower 3 bits of command byte
	ld a, [bc]
	and %00000111
	;Store as octave in RAM
	ld hl, $1B
	add hl, de
	jr Audio1_StoreVal

Audio1_EventDutyVol:
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
	jr Audio1_StoreVal

.EventDutyVol_SFX4
	ld a, [bc]
	or a
	jr z, .EventDutyVol_2
	ld a, 8

.EventDutyVol_2
	;Store final value in RAM
	ld hl, $0C
	add hl, de
	jr Audio1_StoreVal

Audio1_EventDecay:
;Set decay
;Parameters: xxxxxxxx (x = value)
	ld hl, $0D
	add hl, de
	inc bc
	ld a, [bc]

Audio1_StoreVal:
	ld [hl], a

Audio1_EventNop:
;Do nothing but skip a byte
;Parameters: -------- (- = unused)
Audio1_NextByte:
	inc bc
	ret

Audio1_EventSweep:
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

Audio1_EventVibrato:
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
	call Audio1_ProcNoteLen3
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
	add LOW(Audio1_VibTab)
	ld c, a
	ld a, HIGH(Audio1_VibTab)
	adc 0
	ld b, a
	pop af

Audio1_StorePtr:
	;Store pointer into RAM
	ld a, [bc]
	ld [hl+], a
	inc bc
	ld a, [bc]
	ld [hl], a
	pop bc
	inc bc
	ret

Audio1_EventTranspose:
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

Audio1_EventWaveform:
;Set waveform
;Parameters: xxxxxxxx (x = value)
	;Check current track and set its respective waveform
	ld a, [CurTrackCheck]
	cp 2
	jr z, .EventWaveform2
	cp 6
	;If neither channel 3 tracks, then do nothing
	jr nz, Audio1_NextByte
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

Audio1_EventEnvDecay:
;Set duty/volume and decay 2/3
;Parameters: xyyyyyyy (zzzzzzzz aaaaaaaa)  (x = if set, z and a are used, z = decay 2, a = decay 3)
	inc bc

Audio1_GetEnvVal:
	;Get envelope value from byte
	ld a, [bc]
	ld hl, $11
	add hl, de
	ld [hl+], a
	;If signed, then get decay parameters from next 2 bytes
	add a
	jr c, Audio1_GetDecay

Audio1_GetEnvSeq:
	;Get envelope sequence number from parameter
	ld a, [bc]

Audio1_GetEnvSeq2:
	push bc
	push af
	;Get envelope sequence pointer from table
	add a
	add LOW(Audio1_EnvSeqTab)
	ld c, a
	ld a, HIGH(Audio1_EnvSeqTab)
	adc 0
	;Load pointer into RAM
	ld b, a
	pop af
	ld hl, $14
	add hl, de
	jr Audio1_StorePtr

;Get decay parameters
Audio1_GetDecay:
	inc bc
	ld a, [bc]
	ld [hl+], a
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret

Audio1_EventTuning:
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

Audio1_EventEnvVal:
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

Audio1_EventDecay2:
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

Audio1_EventDecay3:
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

Audio1_EventFinalVol:
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

Audio1_EventSpeed:
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

Audio1_EventMacro1:
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

Audio1_EventMacro2:
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

Audio1_EventMacro1Ret:
;Return from macro (subroutine) (1)
	;Go to position in RAM
	ld hl, $26
	add hl, de
	ld a, [hl+]
	ld b, [hl]
	ld c, a
	ret

Audio1_EventMacro2Ret:
;Return from macro (subroutine) (2)
	;Go to position in RAM
	ld hl, $28
	add hl, de
	ld a, [hl+]
	ld b, [hl]
	ld c, a
	ret

Audio1_EventRepeat1Start:
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

Audio1_EventRepeat2Start:
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

Audio1_EventRepeat1End:
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
	jr z, Audio1_EventRepeatEnd_Done

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
Audio1_EventRepeatEnd_Done:
	ld [hl], 0
	jp Audio1_NextByte

Audio1_EventRepeat2End:
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
	jr z, Audio1_EventRepeatEnd_Done

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

Audio1_EventEnd:
;End of track
	;Get channel mask and add to output
	ld a, [CurTrackCheck]
	push af
	add LOW(Audio1_ChanMaskVals)
	ld c, a
	ld a, HIGH(Audio1_ChanMaskVals)
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

Audio1_ChanMaskVals:
	db $FE, $FD, $FB, $F7, $EF, $DF, $BF, $7F

Audio1_TrackMaskVals:
	db $01, $02, $04, $08, $10, $20, $40, $80

Audio1_ProcTrackRegVals:
	;Get pointer for track routine
	ld a, [CurTrackCheck]
	push af
	add a
	add LOW(Audio1_PrepStates)
	ld l, a
	ld a, HIGH(Audio1_PrepStates)
	adc 0
	ld h, a
	pop af
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	jp hl

Audio1_PrepStates:
	dw Audio1_MusC1Prep
	dw Audio1_MusC2Prep
	dw Audio1_MusC3Prep
	dw Audio1_MusC4Prep
	dw Audio1_SFXC1Prep
	dw Audio1_SFXC2Prep
	dw Audio1_SFXC3Prep
	dw Audio1_SFXC4Prep

Audio1_MusC1Prep:
	;Check if SFX is playing in channel 1
	ld hl, SFXC1MusNum
	ld a, [hl]
	or a
	;Return if so
	ret nz

;Otherwise, get duty/pan value from table
Audio1_SFXC1Prep:
	ld hl, $06
	add hl, de
	ld a, [hl]
	and %00000011
	push af
	add LOW(Audio1_Duty1PanTab)
	ld l, a
	ld a, HIGH(Audio1_Duty1PanTab)
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

Audio1_MusC1Prep_2:
	;If note time is 0, then set duty/volume value to it
	or a
	jr z, Audio1_MusC1Prep_3A

	;Otherwise, set it and swap
	ld hl, $0C
	add hl, de
	ld a, [hl]
	swap a
	jr Audio1_MusC1Prep_3B

Audio1_MusC1Prep_3A:
	ld hl, $0C
	add hl, de
	ld a, [hl]

Audio1_MusC1Prep_3B:
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
	jr nz, Audio1_MusC1Prep_4

	;If not, then use empty value
	ld a, %00001000
	jr Audio1_MusC1Prep_5

Audio1_MusC1Prep_4:
	;Get hardware volume
	ld hl, $1F
	add hl, de
	ld a, [hl]

Audio1_MusC1Prep_5:
	;Set NR12 value to it
	ld [bc], a
	inc bc

Audio1_MusC1Prep_6:
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
	jr nz, Audio1_MusC1Prep_Neg

	;If positive, then add to frequency
	add [hl]
	inc hl
	;And set NR13 value to it
	ld [bc], a
	ld a, [hl]
	adc 0

Audio1_MusC1Prep_7:
	;Set NR14 value
	inc bc
	and %00000111
	ld [bc], a

Audio1_MusC4Prep:
	;Do nothing
	ret

Audio1_MusC1Prep_Neg:
	;If negative, then add negative to frequency
	add [hl]
	push af
	inc hl
	ld [bc], a
	pop af
	ld a, [hl]
	adc -1
	jr Audio1_MusC1Prep_7

Audio1_MusC2Prep:
	;Check if SFX is playing in channel 2
	ld hl, SFXC2MusNum
	ld a, [hl]
	or a
	;Return if so
	ret nz

;Otherwise, get duty/pan value from table
Audio1_SFXC2Prep:
	ld hl, $06
	add hl, de
	ld a, [hl]
	and %00000011
	push af
	add LOW(Audio1_Duty2PanTab)
	ld l, a
	ld a, HIGH(Audio1_Duty2PanTab)
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
	jr Audio1_MusC1Prep_2

Audio1_MusC3Prep:
	;Check if music is playing in SFX channel 3
	ld hl, SFXC3MusNum
	ld a, [hl]
	or a
	;Return if so
	ret nz

;Otherwise, get duty/pan value from table
Audio1_SFXC3Prep:
	ld hl, $06
	add hl, de
	ld a, [hl]
	and %00000011
	push af
	add LOW(Audio1_Duty3PanTab)
	ld l, a
	ld a, HIGH(Audio1_Duty3PanTab)
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
	jr z, Audio1_SFXC3Prep_2

	;Otherwise, get hardware volume
	ld hl, $1F
	add hl, de
	ld a, [hl]

	;Get volume from look-up table
	swap a
	and %00001111
	push bc
	push af
	add LOW(Audio1_Vol3LUT)
	ld c, a
	ld a, HIGH(Audio1_Vol3LUT)
	adc 0
	ld b, a
	pop af
	ld a, [bc]
	pop bc

;Set NR33
Audio1_SFXC3Prep_2:
	ld [bc], a
	inc bc
	jp Audio1_MusC1Prep_6

Audio1_SFXC4Prep:
	;Get duty/pan value from table
	ld hl, $06
	add hl, de
	ld a, [hl]
	and %00000011
	push af
	add LOW(Audio1_Duty4PanTab)
	ld l, a
	ld a, HIGH(Audio1_Duty4PanTab)
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
	jr nz, Audio1_SFXC4Prep_2

	;If not, then use empty value
	ld a, %00001000
	jr Audio1_SFXC4Prep_3

Audio1_SFXC4Prep_2:
	;Get hardware volume
	ld hl, $1F
	add hl, de
	ld a, [hl]

Audio1_SFXC4Prep_3:
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

Audio1_Vol3LUT:
	db $00, $60, $40, $40, $40, $40, $40, $40
	db $20, $20, $20, $20, $20, $20, $20, $20

Audio1_Duty1PanTab:
	db $11, $01, $10, $11

Audio1_Duty2PanTab:
	db $22, $02, $20, $22

Audio1_Duty3PanTab:
	db $44, $04, $40, $44

Audio1_Duty4PanTab:
	db $88, $08, $80, $88

Audio1_OutputTracks:
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

Audio1_DoAllRegs:
	;Copy all register values in RAM to actual values and set appropriately
	call Audio1_OutputReg
	ld a, b
	call Audio1_OutputRegTrig
	ld a, b
	call Audio1_OutputRegCheck
	call Audio1_OutputRegWithTrig
	inc c
	call Audio1_OutputReg
	ld a, [Gate2Off]
	call Audio1_OutputRegTrig
	call Audio1_OutputReg
	call Audio1_OutputRegWithTrig
	call Audio1_OutputReg
	inc hl
	inc de
	inc c
	call Audio1_OutputReg
	call Audio1_OutputReg
	call Audio1_OutputRegWithTrig
	inc c
	inc hl
	inc de
	inc c
	ld a, [Gate4Off]
	call Audio1_OutputRegTrig
	call Audio1_OutputReg
	call Audio1_OutputRegWithTrig

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
	jr nz, Audio1_SetSFXWaveform

;Otherwise, set music waveform
Audio1_SetMusWaveform:
	ld a, [WaveformMus]
	jr Audio1_LoadWaveform

Audio1_SetSFXWaveform:
	ld a, [WaveformSFX]

Audio1_LoadWaveform:
	;If waveform is same, then return
	ld hl, NewWave
	cp [hl]
	ret z

	;Otherwise, load new waveform - get pointer to waveform from table
	ld [hl], a
	push af
	add a
	add LOW(Audio1_WaveTab)
	ld l, a
	ld a, HIGH(Audio1_WaveTab)
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

Audio1_OutputRegTrig:
	;Check "gate off" value
	or a
	;If gate off, get new value and set trigger
	jr z, .OutputRegTrig_2

	;Otherwise, check if copy register variable is the same as register value
	ld a, [de]
	cp [hl]
	jr z, Audio1_OutputReg_Ret

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

Audio1_OutputRegCheck:
	;Check "gate off" value
	or a
	;If gate off, get new value
	jr z, Audio1_OutputReg2

Audio1_OutputReg:
	;Get copy value and compare to main register value
	ld a, [de]
	cp [hl]
	;If same, then return
	jr z, Audio1_OutputReg_Ret

;Otherwise, load to main register value and actual register
Audio1_OutputReg2:
	ld a, [hl]
	ld [de], a
	ldh [c], a

Audio1_OutputReg_Ret:
	inc hl
	inc de
	inc c
	ret

Audio1_OutputRegWithTrig:
	;Check "trigger" bit of copy value
	ld a, [de]
	bit 7, a
	;If set, then output new value
	jr nz, .OutputRegWithTrig2

	;Otherwise, check if main value is the same
	cp [hl]
	;If so, then return
	jr z, Audio1_OutputReg_Ret

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

Audio1_NoAudio2:
	;Silence everything, then fall through into NoAudio and do it again
	call Audio1_NoAudio

;Initialize audio with no music/SFX
Audio1_NoAudio:
	push bc
	push de
	call Audio1_ClearCh1
	ld a, %01110111
	ld [NR50Val], a
	jr Audio1_InitSoundRAM

;Initialize audio
Audio1_InitSound:
	push bc
	push de
	call Audio1_AudioOff
	ld a, %01110111
	ldh [rNR50], a
	ld [NR50Val], a

;Initialize RAM variables
Audio1_InitSoundRAM:
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

Audio1_AudioOff:
	;Turn off audio
	xor a
	ldh [rNR50], a
	ld a, %10000000
	ldh [rNR52], a

Audio1_ClearCh1:
	;Reset NR10 (sweep)
	ld a, %00001000
	ldh [rNR10], a
	ld [NR10Val], a
	;Check if channel is on
	ldh a, [rNR52]
	bit 0, a
	;If not, then skip
	jr z, Audio1_ClearCh2
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

Audio1_ClearCh2:
	;Check if channel is on
	ldh a, [rNR52]
	bit 1, a
	;If not, then skip
	jr z, Audio1_ClearCh3
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

Audio1_ClearCh3:
	;Check if channel is on
	ldh a, [rNR52]
	bit 2, a
	;If not, then skip
	jr z, Audio1_ClearCh4
	xor a
	;Clear NR32 and NR34
	ldh [rNR32], a
	ld [NR32Val], a
	ld [NR34Val], a
	;Set trigger bit
	ld a, %10000000
	ldh [rNR34], a

Audio1_ClearCh4:
	;Check if channel is on
	ldh a, [rNR52]
	bit 3, a
	;If not, then return
	jr z, Audio1_AudioOffRet
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

Audio1_AudioOffRet:
	ret

Audio1_EventAddParam:
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
	jp Audio1_NextByte

.EventAddParam2
	ld a, [hl]
	jp Audio1_GetEnvSeq2

Audio1_FreqTab:
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

Audio1_EmptySeq:
	db $FF

Audio1_Perc01D:
	db $D1, $00, $90, $89, $11, $81
	db $E0
	db $15
	db $FF

Audio1_Perc02D:
	db $D2, $00, $A0, $8A, $31, $F4
	db $E0
	db $1E
	db $FF

Audio1_Perc03D:
	db $D1, $00, $90, $89, $11, $B1
	db $E1
	db $B7
	db $FF

Audio1_Perc04C:
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

Audio1_Perc05D:
	db $D1, $11, $00, $09
	db $E5
	db $32
	db $EE, $06
	db $31
	db $EE, $02
	db $31
	db $FF

Audio1_Perc06C:
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

Audio1_Perc07C:
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

Audio1_Perc08C:
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

Audio1_Perc09C:
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

Audio1_UnusedData_4F6A:
	db $D7, $10, $90, $0A, $E5, $04, $14
	db $24
	db $34
	db $44
	db $54
	db $64
	db $74
	db $FF

Audio1_UnusedData_4F78:
	db $FF

Audio1_EnvSeqTab:
	dw Audio1_EnvSeq00
	dw Audio1_EnvSeq01
	dw Audio1_EnvSeq02
	dw Audio1_EnvSeq03
	dw Audio1_EnvSeq04
	dw Audio1_EnvSeq05
	dw Audio1_EnvSeq06
	dw Audio1_EnvSeq07
	dw Audio1_EnvSeq08
	dw Audio1_EnvSeq09
	dw Audio1_EnvSeq0A
	dw Audio1_EnvSeq0B
	dw Audio1_EnvSeq0C
	dw Audio1_EnvSeq0D
	dw Audio1_EnvSeq0E
	dw Audio1_EnvSeq0F
	dw Audio1_EnvSeq10
	dw Audio1_EnvSeq11
	dw Audio1_EnvSeq12
	dw Audio1_EnvSeq13

Audio1_EnvSeq00:
	db $8F
	db $FF

Audio1_EnvSeq01:
	db $1F
	db $FF

Audio1_EnvSeq02:
	db $2F
	db $FF

Audio1_EnvSeq03:
	db $3F
	db $FF

Audio1_EnvSeq04:
	db $4F
	db $FF

Audio1_EnvSeq05:
	db $5F
	db $FF

Audio1_EnvSeq06:
	db $6F
	db $FF

Audio1_EnvSeq07:
	db $7F
	db $FF

Audio1_EnvSeq08:
	db $8F
	db $FF

Audio1_EnvSeq09:
	db $9F
	db $FF

Audio1_EnvSeq0A:
	db $AF
	db $FF

Audio1_EnvSeq0B:
	db $BF
	db $FF

Audio1_EnvSeq0C:
	db $CF
	db $FF

Audio1_EnvSeq0D:
	db $DF
	db $FF

Audio1_EnvSeq0E:
	db $EF
	db $FF

Audio1_EnvSeq0F:
	db $FE
	db $FF

Audio1_EnvSeq10:
	db $B2, $52, $92, $42
	db $72, $32, $52, $22
	db $FF

Audio1_EnvSeq11:
	db $92, $42, $72, $32
	db $52, $22, $32, $12
	db $FF

Audio1_EnvSeq12:
	db $B3, $43, $63, $43
	db $63, $43, $63, $43
	db $63, $43, $63, $43
	db $63, $43, $63, $43
	db $63, $43, $63, $43
	db $63, $43
	db $FF

Audio1_EnvSeq13:
	db $83, $23, $43, $23
	db $43, $23, $43, $23
	db $43, $23, $43, $23
	db $43, $23, $43, $23
	db $43, $23, $43, $23
	db $43, $23
	db $FF

Audio1_VibTab:
	dw Audio1_Vibrato0
	dw Audio1_Vibrato1
	dw Audio1_Vibrato2
	dw Audio1_Vibrato3
	dw Audio1_Vibrato4
	dw Audio1_Vibrato5
	dw Audio1_Vibrato6
	dw Audio1_Vibrato7
	dw Audio1_Vibrato8
	dw Audio1_Vibrato9
	dw Audio1_VibratoA
	dw Audio1_VibratoA
	dw Audio1_VibratoA
	dw Audio1_VibratoA
	dw Audio1_VibratoA
	dw Audio1_VibratoA

Audio1_Vibrato0:
	db $0F
	db $FF

Audio1_Vibrato1:
	db $14, $03, $F4, $03
	db $FF

Audio1_Vibrato2:
	db $11, $22, $11, $02
	db $F1, $E2, $F1, $02
	db $FF

Audio1_Vibrato3:
	db $21, $32, $21, $02
	db $E1, $D2, $E1, $02
	db $FF

Audio1_Vibrato4:
	db $21, $42, $21, $02
	db $E1, $C2, $E1, $02
	db $FF

Audio1_Vibrato5:
	db $31, $52, $31, $02
	db $D1, $B2, $D1, $02
	db $FF

Audio1_Vibrato6:
	db $31, $62, $31, $02
	db $D1, $A2, $D1, $02
	db $FF

Audio1_Vibrato7:
	db $32, $72, $32, $02
	db $D2, $92, $D2, $02
	db $FF

Audio1_Vibrato8:
	db $81, $91, $A1, $B1
	db $C1, $D1, $E1, $F1
	db $0F, $0F, $0F, $0F
	db $0F, $0F
	db $FF

Audio1_Vibrato9:
	db $31, $21, $11, $0F
	db $0F, $0F, $0F, $0F
	db $0F
	db $FF

Audio1_VibratoA:
	db $03, $13, $23, $13
	db $FF

Audio1_WaveTab:
	dw Audio1_Waveform00
	dw Audio1_Waveform01
	dw Audio1_Waveform02
	dw Audio1_Waveform03
	dw Audio1_Waveform04
	dw Audio1_Waveform05
	dw Audio1_Waveform06
	dw Audio1_Waveform07
	dw Audio1_Waveform08
	dw Audio1_Waveform09
	dw Audio1_Waveform0A
	dw Audio1_Waveform0A
	dw Audio1_Waveform0A
	dw Audio1_Waveform0A
	dw Audio1_Waveform0A
	dw Audio1_Waveform0A
	dw Audio1_Waveform10

Audio1_Waveform00:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $ED, $CB, $A9, $87, $65, $43, $21, $00

Audio1_Waveform01:
	db $02, $46, $8A, $CE, $FF, $FF, $FF, $FF, $EC, $A8, $64, $20, $00, $44, $88, $44

Audio1_Waveform02:
	db $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

Audio1_Waveform03:
	db $35, $22, $4A, $00, $0A, $34, $05, $00, $FA, $FF, $0F, $FA, $FC, $F0, $00, $F0

Audio1_Waveform04:
	db $FE, $DC, $BA, $98, $76, $54, $32, $10, $76, $54, $32, $10, $44, $00, $22, $00

Audio1_Waveform05:
	db $79, $8F, $FC, $CF, $FD, $B9, $75, $31, $76, $54, $32, $10, $44, $00, $22, $00

Audio1_Waveform06:
	db $03, $69, $CF, $FC, $96, $30, $03, $56, $77, $65, $44, $33, $20, $00, $52, $00

Audio1_Waveform07:
	db $01, $21, $45, $67, $01, $21, $45, $67, $FE, $DC, $BA, $98, $76, $54, $32, $10

Audio1_Waveform08:
	db $01, $11, $12, $23, $34, $45, $56, $67, $78, $89, $9A, $AB, $BC, $CD, $DD, $D0

Audio1_Waveform09:
	db $13, $57, $9B, $DF, $00, $00, $00, $00, $13, $57, $9B, $DF, $00, $00, $00, $00

Audio1_Waveform0A:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $ED, $CB, $A9, $87, $65, $43, $21, $00

Audio1_Waveform10:
	db $02, $34, $67, $9A, $CD, $FF, $FF, $EE, $EE, $FF, $FF, $DC, $A9, $76, $43, $10

Audio1_SFX_ShotA:
	db $D1, $22, $F0, $00, $0F
	db $EA, $25
	db $E2
	db $38
	db $EE, $02
	db $E3
	db $34
	db $FF

Audio1_SFX_ChargeShotSmallD:
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

Audio1_SFX_ChargeShotLargeD:
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

Audio1_SFX_ChargeA:
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

Audio1_SFX_LandA:
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

Audio1_SFX_ExtraLifeA:
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

Audio1_SFX_HurtA:
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

Audio1_SFX_HurtD:
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

Audio1_SFX_PlayerExplodeA:
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

Audio1_SFX_EnemyHitD:
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

Audio1_SFX_BossExplodeD:
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

Audio1_SFX_HealthA:
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

Audio1_SFX_ShingA:
	db $D2, $22, $F0, $00, $9F, $21, $F2
	db $E4
	db $83
	db $E5
	db $50
	db $FF

Audio1_SFX_ShingB:
	db $D2, $22, $F0, $00, $9F, $21, $F2
	db $EF, $02
	db $E4
	db $83
	db $E5
	db $50
	db $FF

Audio1_SFX_SelectA:
	db $D1, $01, $E0, $00, $9E, $21, $81
	db $E3
	db $87
	db $17
	db $FF

Audio1_SFX_PauseA:
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

Audio1_SFX_TeleportInA:
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

Audio1_SFX_TeleportOutA:
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

Audio1_SFX_DeflectD:
	db $D1, $11, $C0, $0E
	db $E1
	db $12
	db $EE, $8C, $10, $11
	db $04
	db $FF

Audio1_SFX_DoorD:
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

Audio1_SFX_ExplodeD:
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

Audio1_SFX_SplashD:
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

Audio1_SFX_WilyUFOA:
	db $D1, $22, $00, $17, $08
	db $E4
	db $FB
	db $2F
	db $FD, $00
	db $FF

Audio1_SFX_ErrorB:
	db $D8, $33, $00, $00, $0E
	db $E1
	db $34
	db $EE, $02
	db $31
	db $FF

Audio1_SFX_ErrorA:
	db $D8, $33, $00, $00, $0E
	db $E0
	db $B4
	db $EE, $02
	db $B1
	db $FF

Audio1_SFX_AcceptB:
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

Audio1_SFX_AcceptA:
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

Audio1_SFX_TextD:
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

Audio1_SFX_FortressExplodeA:
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

Audio1_SFX_FortressExplodeD:
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

Audio1_UnusedData_540C:
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

Audio1_UnusedData_541F:
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

Audio1_SFX_SparkChaser1D:
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

Audio1_SFX_SparkChaser2D:
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

Audio1_SFX_BlackHole1D:
	db $D1, $00, $C0, $0E
	db $E0
	db $03
	db $13
	db $22
	db $32
	db $41
	db $51
	db $FF

Audio1_SFX_BlackHole2D:
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

Audio1_SFX_ExplodeBlastD:
	db $D1, $00, $F0, $8F, $21, $F2
	db $E5
	db $C1
	db $F6, $02
	db $31
	db $21
	db $3A
	db $FF

Audio1_SFX_LaserA:
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

Audio1_SFX_PlatformExplodeD:
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

Audio1_SFX_RainFlushD:
	db $F6, $01
	db $C1
	db $DF, $00, $C0, $8C, $29, $4F
	db $E3
	db $26
	db $FF

Audio1_SFX_BreakDashD:
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

Audio1_SFX_ProtoManB:
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

Audio1_EmptySeq2:
	db $FF

Audio1_SFX_HelicopterD:
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

Audio1_SFX_CannonA:
	db $D1, $11, $C0, $00, $0F
	db $EA, $2E
	db $E2
	db $A2
	db $EA, $25
	db $64
	db $FF

Audio1_SFX_StompA:
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

Audio1_SFX_WilyMachineExplodeA:
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

Audio1_SFX_WilyMachineExplodeD:
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

Audio1_SFX_WilyTankMissileA:
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

Audio1_SFX_WilyTankMissileD:
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

Audio1_UnusedData_55F5:
	db $D1, $22, $F0, $00, $0F
	db $EA, $25
	db $E2
	db $28
	db $EE, $02
	db $E3
	db $24
	db $FF

Audio1_SFX_BigShot1D:
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

Audio1_SFX_BigShot2D:
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

Audio1_SFX_ShotAltA:
	db $D1, $22, $F0, $00, $0F
	db $EA, $25
	db $E2
	db $28
	db $EE, $02
	db $E3
	db $24
	db $FF

Audio1_SFX_ChargeAlt1A:
	db $D1, $02, $F0, $00, $0A
	db $F7
	dw Audio1_SFX_ChargeAlt1A_1
	db $F7
	dw Audio1_SFX_ChargeAlt1A_1
	db $FB
	db $F7
	dw Audio1_SFX_ChargeAlt1A_2
	db $FD, $00
	db $FF

Audio1_SFX_ChargeAlt1A_1:
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

Audio1_SFX_ChargeAlt1A_2:
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

Audio1_SFX_ChargeAlt2A:
	db $D2, $22, $F0, $00, $0A
	db $F7
	dw Audio1_SFX_ChargeAlt2A_1
	db $F7
	dw Audio1_SFX_ChargeAlt2A_1
	db $FB
	db $F7
	dw Audio1_SFX_ChargeAlt2A_2
	db $FD, $00
	db $FF

Audio1_SFX_ChargeAlt2A_1:
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

Audio1_SFX_ChargeAlt2A_2:
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

Audio1_SFX_ChargeAlt3A:
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

Audio1_UnusedData_56D9:
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

Audio1_UnusedData_56F2:
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

Audio1_UnusedData_5718:
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

Audio1_SFX_GetWeaponAltA:
	db $D2, $00, $00, $00, $0E
	db $EC, $06

Audio1_SFX_GetWeaponAltB_1:
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

Audio1_SFX_GetWeaponAltB:
	db $D2, $00, $00, $00, $0E
	db $EC, $06
	db $E3
	db $01
	db $F7
	dw Audio1_SFX_GetWeaponAltB_1
Audio1_UnusedFadeOutTrackA:
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
	dw Audio1_SFX_GetWeaponAltB_2
	db $EC, $0C
	db $F7
	dw Audio1_SFX_GetWeaponAltB_2
	db $EC, $18
	db $F7
	dw Audio1_SFX_GetWeaponAltB_2
	db $EC, $24
	db $F7
	dw Audio1_SFX_GetWeaponAltB_2
	db $EC, $30
	db $FC
	db $F7
	dw Audio1_SFX_GetWeaponAltB_3
	db $FE, $00
	db $FF

Audio1_SFX_GetWeaponAltB_2:
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

Audio1_SFX_GetWeaponAltB_3:
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

Audio1_UnusedPerc01A:
	db $D1, $00, $00, $00, $0E
Audio1_UnusedPerc01B_1:
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

Audio1_UnusedPerc01B:
	db $D1, $00, $00, $00, $0E
	db $E6
	db $01
	db $F7
	dw Audio1_UnusedPerc01B_1
Audio1_UnusedPerc01D:
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

Audio1_UnusedData_587C:
	db $D2, $22, $F0, $00, $9F, $21, $F1
	db $E4
	db $54
	db $E5
	db $AC
	db $FF

Audio1_UnusedData_5888:
	db $D2, $22, $F0, $00, $9F, $21, $F1
	db $EF, $02
	db $E4
	db $84
	db $E5
	db $AC
	db $FF

Audio1_UnusedData_5896:
	db $D2, $22, $F0, $00, $9F, $21, $F1
	db $E3
	db $14
	db $E4
	db $0C
	db $FF

Audio1_UnusedData_58A2:
	db $D2, $22, $F0, $00, $9F, $21, $F1
	db $EF, $02
	db $E3
	db $44
	db $E4
	db $0C
	db $FF

Audio1_SFX_RushSpaceshipMotorA:
	db $D1, $02, $F0, $00, $0A
	db $EC, $30
	db $FC
	db $F7
	dw Audio1_SFX_GetWeaponAltB_3
	db $FE, $00
	db $FF

Audio1_SFX_RushSpaceshipAccelA:
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
	dw Audio1_SFX_RushSpaceshipAccelA_1
	db $EC, $0C
	db $F7
	dw Audio1_SFX_RushSpaceshipAccelA_1
	db $EC, $18
	db $F7
	dw Audio1_SFX_RushSpaceshipAccelA_1
	db $FF

Audio1_SFX_RushSpaceshipAccelA_1:
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

Audio1_SFX_RushSpaceshipBlastA:
	db $D1, $00, $00, $00, $0E

Audio1_SFX_RushSpaceshipBlastB_1:
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

Audio1_SFX_RushSpaceshipBlastB:
	db $D1, $00, $00, $00, $0E
	db $E6
	db $01
	db $F7
	dw Audio1_SFX_RushSpaceshipBlastB_1

Audio1_SFX_RushSpaceshipBlastD:
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

Audio1_UnusedData_59AC:
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

Audio1_UnusedData_5A2D:
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

Audio1_UnusedData_5AB7:
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

Audio1_UnusedData_5B40:
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

Audio1_SFX_SpecialWeaponD:
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

Audio1_SFX_SpecialWeaponB:
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

Audio1_SFX_WilyStarExplodeA:
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

Audio1_SFX_WilyStarExplodeB:
	db $D1, $51, $00, $00, $0F
	db $F3, $00
	db $F7
	dw Audio1_SFX_WilyStarExplodeB_1
	db $EE, $0C
	db $F7
	dw Audio1_SFX_WilyStarExplodeB_1
	db $EE, $0A
	db $F7
	dw Audio1_SFX_WilyStarExplodeB_1
	db $EE, $08
	db $F7
	dw Audio1_SFX_WilyStarExplodeB_1
	db $EE, $06
	db $F7
	dw Audio1_SFX_WilyStarExplodeB_1
	db $EE, $04
	db $F7
	dw Audio1_SFX_WilyStarExplodeB_1
	db $EE, $03
	db $F7
	dw Audio1_SFX_WilyStarExplodeB_1
	db $EE, $02
	db $F7
	dw Audio1_SFX_WilyStarExplodeB_1
	db $EE, $01
	db $F7
	dw Audio1_SFX_WilyStarExplodeB_1
	db $FF

Audio1_SFX_WilyStarExplodeB_1:
	db $FB
	db $E1
	db $01
	db $E0
	db $71
	db $41
	db $01
	db $FD, $04
	db $F9

Audio1_SFX_WilyStarExplodeD:
	db $D2, $11, $00, $0E
	db $F8
	dw Audio1_SFX_WilyStarExplodeD_1
	db $F8
	dw Audio1_SFX_WilyStarExplodeD_1
	db $F8
	dw Audio1_SFX_WilyStarExplodeD_1
	db $F8
	dw Audio1_SFX_WilyStarExplodeD_1
	db $EE, $0C
	db $FC
	db $F8
	dw Audio1_SFX_WilyStarExplodeD_1
	db $F4, $11, $FF
	db $FE, $07
	db $FF

Audio1_SFX_WilyStarExplodeD_1:
	db $E7
	db $11
	db $F4, $11, $FE
	db $21
	db $F4, $11, $FE
	db $11
	db $F4, $11, $04
	db $C1
	db $FA

Audio1_SFX_EnemyShotA:
	db $D1, $21, $F0, $00, $0F
	db $EA, $1F
	db $E5
	db $B6
	db $FF

Audio1_SFX_TimeFreezeA:
	db $D2, $22, $F0, $00, $9F, $21, $F2
	db $E4
	db $13
	db $E6
	db $00
	db $FF

Audio1_SFX_TimeFreezeB:
	db $D2, $22, $F0, $00, $9F, $21, $F2
	db $EF, $02
	db $E4
	db $13
	db $E6
	db $00
	db $FF

Audio1_SFX_TeleportOutAltA:
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

Audio1_SFX_BubbleEnemyA:
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

Audio1_SFX_TangoHitA:
	db $D1, $11, $00, $07, $08
	db $E4
	db $8C
	db $FF

Audio1_SFX_GetWeaponA:
	db $D1, $00, $00, $00, $0E
	db $EC, $06

Audio1_SFX_GetWeaponB_1:
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

Audio1_SFX_GetWeaponB:
	db $D1, $00, $00, $00, $0E
	db $EC, $06
	db $E3
	db $01
	db $F7
	dw Audio1_SFX_GetWeaponB_1

Audio1_SFX_SuperMegaBusterD:
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

Audio1_SFX_TangoA:
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

Audio1_UnusedData_5D74:
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

Audio1_SFX_ElectricShock2D:
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

Audio1_SFX_PhotonMissileD:
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

Audio1_SFX_GrabBusterD:
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

Audio1_SFX_SaltWaterD:
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

Audio1_SFX_BubbleBombA:
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

Audio1_SFX_ElectricShock1D:
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

Audio1_Mus_StageSelectB:
	db $D5, $11, $B1, $52, $8B, $26, $B5
	db $C3
	db $EF, $01
	db $E9, $D1
	db $E8, $16
	db $F3, $01
	db $EC, $00
	db $F7
	dw Audio1_Mus_StageSelectA_1
	db $F3, $03
	db $F6, $05
	db $E9, $B1
	db $E8, $0B
	db $FB
	db $EC, $02
	db $F8
	dw Audio1_Mus_StageSelectB_1
	db $EC, $04
	db $F8
	dw Audio1_Mus_StageSelectB_1
	db $EC, $06
	db $F8
	dw Audio1_Mus_StageSelectB_2
	db $FD, $00
	db $FF

Audio1_Mus_StageSelectA_1:
	db $F6, $02
	db $E1
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

Audio1_Mus_StageSelectB_1:
	db $E9, $B1
	db $E1
	db $61
	db $8F
	db $83
	db $6D
	db $41
	db $6F
	db $61
	db $87
	db $E9, $91
	db $82
	db $82
	db $82
	db $82
	db $E9, $B1
	db $E1
	db $61
	db $8F
	db $83
	db $6D
	db $41
	db $6F
	db $61
	db $8B
	db $E9, $C1
	db $11
	db $31
	db $41
	db $61
	db $FA

Audio1_Mus_StageSelectA:
	db $D5, $11, $61, $52, $AB, $26, $B5
	db $C3
	db $E9, $D1
	db $E8, $16
	db $F3, $02
	db $EC, $03
	db $F6, $02
	db $F7
	dw Audio1_Mus_StageSelectA_1
	db $E8, $0B
	db $F6, $05
	db $F3, $03
	db $EE, $05
	db $E9, $91
	db $FB
	db $EC, $02
	db $F7
	dw Audio1_Mus_StageSelectA_2
	db $F7
	dw Audio1_Mus_StageSelectA_2
	db $EC, $04
	db $F7
	dw Audio1_Mus_StageSelectA_2
	db $F7
	dw Audio1_Mus_StageSelectA_2
	db $EC, $06
	db $F7
	dw Audio1_Mus_StageSelectA_2
	db $F7
	dw Audio1_Mus_StageSelectA_2
	db $FD, $00
	db $FF

Audio1_Mus_StageSelectA_2:
	db $E1
	db $91
	db $B7
	db $E2
	db $42
	db $81
	db $B1
	db $42
	db $81
	db $B1
	db $E1
	db $B3
	db $95
	db $E2
	db $22
	db $61
	db $91
	db $22
	db $61
	db $91
	db $E1
	db $71
	db $97
	db $E2
	db $22
	db $61
	db $91
	db $22
	db $61
	db $91
	db $E2
	db $C1
	db $B1
	db $91
	db $81
	db $61
	db $91
	db $81
	db $61
	db $81
	db $61
	db $81
	db $41
	db $61
	db $11
	db $41
	db $31
	db $F9

Audio1_Mus_StageSelectB_2:
	db $E1
	db $61
	db $8F
	db $83
	db $6D
	db $41
	db $6F
	db $61
	db $8F
	db $E1
	db $61
	db $8F
	db $83
	db $6D
	db $41
	db $6F
	db $61
	db $8B
	db $81
	db $71
	db $51
	db $41
	db $FA

Audio1_Mus_StageSelectC:
	db $D5, $06, $86, $B0
	db $C3
	db $EC, $FC
	db $F7
	dw Audio1_Mus_StageSelectA_1
	db $F3, $03
	db $F6, $05
	db $FC
	db $EC, $02
	db $F7
	dw Audio1_Mus_StageSelectC_1
	db $F8
	dw Audio1_Mus_StageSelectC_2
	db $EC, $04
	db $F7
	dw Audio1_Mus_StageSelectC_1
	db $F8
	dw Audio1_Mus_StageSelectC_2
	db $EC, $06
	db $F7
	dw Audio1_Mus_StageSelectC_1
	db $F7
	dw Audio1_Mus_StageSelectC_1
	db $FE, $00
	db $FF

Audio1_Mus_StageSelectC_1:
	db $FB
	db $E1
	db $42
	db $FD, $07
	db $FB
	db $E1
	db $22
	db $FD, $0F
	db $FB
	db $E1
	db $42
	db $FD, $03
	db $E1
	db $42
	db $B2
	db $42
	db $B2
	db $F9

Audio1_Mus_StageSelectC_2:
	db $FB
	db $E1
	db $42
	db $FD, $07
	db $FB
	db $E1
	db $22
	db $FD, $0F
	db $FB
	db $E1
	db $42
	db $FD, $03
	db $E1
	db $42
	db $B2
	db $11
	db $31
	db $41
	db $61
	db $FA

Audio1_Mus_StageSelectD:
	db $D5
	db $C3
	db $F6, $02
	db $31
	db $31
	db $31
	db $31
	db $21
	db $21
	db $21
	db $21
	db $21
	db $21
	db $21
	db $11
	db $11
	db $11
	db $F6, $05
	db $FC
	db $FB
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FD, $06
	db $12
	db $11
	db $11
	db $31
	db $31
	db $31
	db $31
	db $FE, $00
	db $FF

Audio1_Mus_WilyIntroB:
	db $EC, $02
	db $D7, $11, $B1, $26, $8B, $16, $C6
	db $C2
	db $E1
	db $42
	db $92
	db $82
	db $E2
	db $02
	db $E1
	db $B2
	db $E2
	db $32
	db $22
	db $54
	db $B4
	db $84
	db $E3
	db $24
	db $40
	db $FF

Audio1_Mus_WilyIntroA:
	db $EC, $02
	db $D7, $20, $B1, $26, $8B, $16, $C6
	db $C2
	db $E0
	db $B2
	db $E1
	db $52
	db $42
	db $92
	db $82
	db $E2
	db $02
	db $E1
	db $B2
	db $E2
	db $24
	db $84
	db $54
	db $84
	db $B0
	db $FF

Audio1_Mus_WilyIntroC:
	db $EC, $02
	db $D7, $06, $83, $D0
	db $E1
	db $44
	db $52
	db $42
	db $52
	db $42
	db $52
	db $42
	db $84
	db $54
	db $24
	db $54
	db $40
	db $FF

Audio1_Mus_WilyIntroD:
	db $D7
	db $12
	db $12
	db $12
	db $12
	db $12
	db $32
	db $32
	db $32
	db $24
	db $24
	db $24
	db $24
	db $21
	db $21
	db $21
	db $21
	db $21
	db $21
	db $21
	db $21
	db $28
	db $FF

Audio1_Mus_UranusB:
	db $D6, $23, $B1, $24, $8B, $35, $C7
	db $FC
	db $E1
	db $FB
	db $C4
	db $78
	db $72
	db $80
	db $C2
	db $FD, $01
	db $FB
	db $E2
	db $32
	db $32
	db $E3
	db $E8, $10
	db $E9, $81
	db $F1, $22
	db $71
	db $71
	db $71
	db $71
	db $E8, $23
	db $E9, $B1
	db $F1, $35
	db $C2
	db $72
	db $02
	db $B6
	db $52
	db $84
	db $72
	db $54
	db $E2
	db $32
	db $32
	db $E3
	db $E8, $10
	db $E9, $81
	db $F1, $22
	db $71
	db $71
	db $71
	db $71
	db $72
	db $E8, $23
	db $E9, $B1
	db $F1, $35
	db $E2
	db $32
	db $C2
	db $54
	db $52
	db $C2
	db $52
	db $C2
	db $52
	db $C2
	db $52
	db $FD, $01
	db $E3
	db $2A
	db $E2
	db $B2
	db $E3
	db $22
	db $55
	db $33
	db $26
	db $C2
	db $2C
	db $52
	db $82
	db $85
	db $73
	db $52
	db $22
	db $C2
	db $F3, $01
	db $F6, $01
	db $E4
	db $22
	db $12
	db $02
	db $E3
	db $B2
	db $E9, $81
	db $F3, $03
	db $A2
	db $92
	db $82
	db $72
	db $F3, $02
	db $62
	db $52
	db $42
	db $32
	db $E9, $B1
	db $F3, $03
	db $F6, $06
	db $E4
	db $32
	db $22
	db $02
	db $E3
	db $B2
	db $A3
	db $73
	db $32
	db $52
	db $52
	db $32
	db $E4
	db $01
	db $E3
	db $73
	db $A2
	db $E4
	db $32
	db $22
	db $03
	db $E3
	db $75
	db $A3
	db $45
	db $82
	db $71
	db $51
	db $C1
	db $31
	db $C1
	db $01
	db $54
	db $E2
	db $B4
	db $FE, $00

Audio1_Mus_UranusA:
	db $D6, $11, $91, $00, $89, $24, $C7
	db $FC
	db $E1
	db $FB
	db $C4
	db $38
	db $32
	db $50
	db $C2
	db $FD, $01
	db $FB
	db $E1
	db $72
	db $72
	db $E2
	db $C2
	db $32
	db $C2
	db $32
	db $C2
	db $54
	db $52
	db $C2
	db $52
	db $C2
	db $52
	db $C2
	db $51
	db $E1
	db $B1
	db $E1
	db $72
	db $72
	db $E2
	db $C2
	db $32
	db $E1
	db $C2
	db $72
	db $C2
	db $84
	db $82
	db $C2
	db $82
	db $C2
	db $82
	db $C2
	db $81
	db $E1
	db $B1
	db $FD, $01
	db $E1
	db $22
	db $B2
	db $C2
	db $B2
	db $C2
	db $E2
	db $22
	db $72
	db $B2
	db $E1
	db $C2
	db $B2
	db $C2
	db $B2
	db $C2
	db $B2
	db $C2
	db $82
	db $C2
	db $82
	db $C2
	db $82
	db $C2
	db $E2
	db $82
	db $E3
	db $22
	db $23
	db $E1
	db $B1
	db $E2
	db $51
	db $B1
	db $E1
	db $81
	db $E2
	db $51
	db $B1
	db $21
	db $82
	db $C2
	db $E9, $B1
	db $F3, $02
	db $F6, $01
	db $E3
	db $B2
	db $A2
	db $92
	db $82
	db $E9, $91
	db $F3, $03
	db $72
	db $62
	db $52
	db $42
	db $F3, $01
	db $32
	db $22
	db $12
	db $02
	db $F3, $03
	db $F6, $06
	db $E1
	db $C2
	db $72
	db $C2
	db $72
	db $E3
	db $32
	db $E1
	db $71
	db $E2
	db $A3
	db $72
	db $C2
	db $02
	db $C2
	db $01
	db $21
	db $21
	db $A1
	db $21
	db $A1
	db $E1
	db $71
	db $E2
	db $71
	db $E1
	db $71
	db $A1
	db $E3
	db $42
	db $E1
	db $71
	db $E3
	db $03
	db $E1
	db $A1
	db $E2
	db $41
	db $E3
	db $42
	db $E1
	db $71
	db $E2
	db $73
	db $E1
	db $A1
	db $41
	db $52
	db $E2
	db $21
	db $81
	db $E1
	db $82
	db $E2
	db $21
	db $51
	db $E1
	db $82
	db $E2
	db $81
	db $B1
	db $E1
	db $82
	db $E2
	db $51
	db $81
	db $FE, $00

Audio1_Mus_UranusC:
	db $D6, $05, $84, $80
	db $FC
	db $FB
	db $E2
	db $02
	db $02
	db $C2
	db $E1
	db $71
	db $E2
	db $01
	db $02
	db $02
	db $C2
	db $14
	db $12
	db $C2
	db $E1
	db $81
	db $B1
	db $E2
	db $12
	db $12
	db $C2
	db $E1
	db $B2
	db $FD, $05
	db $74
	db $74
	db $72
	db $52
	db $72
	db $74
	db $71
	db $71
	db $E2
	db $22
	db $E1
	db $74
	db $B2
	db $E2
	db $22
	db $E1
	db $A6
	db $A4
	db $A2
	db $92
	db $A2
	db $B5
	db $B1
	db $52
	db $82
	db $B2
	db $C6
	db $E2
	db $03
	db $01
	db $E1
	db $72
	db $E2
	db $72
	db $02
	db $E1
	db $A2
	db $E2
	db $02
	db $32
	db $53
	db $51
	db $02
	db $51
	db $73
	db $E1
	db $72
	db $A2
	db $E2
	db $22
	db $03
	db $E1
	db $A3
	db $72
	db $E2
	db $03
	db $E1
	db $A3
	db $72
	db $E2
	db $24
	db $24
	db $14
	db $14
	db $FE, $00

Audio1_Mus_UranusD:
	db $D6
	db $FC
	db $FB
	db $12
	db $22
	db $32
	db $22
	db $12
	db $22
	db $32
	db $22
	db $12
	db $22
	db $32
	db $22
	db $12
	db $22
	db $32
	db $22
	db $FD, $05
	db $12
	db $22
	db $33
	db $31
	db $12
	db $22
	db $32
	db $22
	db $C2
	db $12
	db $32
	db $24
	db $12
	db $32
	db $22
	db $C2
	db $22
	db $33
	db $31
	db $12
	db $22
	db $32
	db $24
	db $31
	db $31
	db $12
	db $31
	db $31
	db $D1
	db $14
	db $14
	db $14
	db $D6
	db $32
	db $31
	db $31
	db $71
	db $81
	db $12
	db $12
	db $32
	db $22
	db $12
	db $12
	db $32
	db $22
	db $12
	db $22
	db $32
	db $11
	db $21
	db $12
	db $22
	db $32
	db $22
	db $12
	db $11
	db $31
	db $12
	db $31
	db $21
	db $12
	db $11
	db $31
	db $12
	db $D1
	db $33
	db $33
	db $33
	db $33
	db $D6
	db $32
	db $22
	db $32
	db $12
	db $32
	db $12
	db $32
	db $12
	db $FE, $00
	db $FF

Audio1_Mus_RushSpaceshipB:
	db $D6, $00, $B1, $24, $8B, $35, $C7
	db $E3
	db $FB
	db $CA
	db $42
	db $C2
	db $22
	db $CA
	db $12
	db $22
	db $42
	db $FD, $01
	db $FC
	db $E2
	db $E8, $00
	db $82
	db $E8, $22
	db $82
	db $E8, $00
	db $42
	db $E8, $22
	db $92
	db $E8, $00
	db $42
	db $E8, $22
	db $B2
	db $C2
	db $E3
	db $26
	db $12
	db $E2
	db $B2
	db $E8, $00
	db $E1
	db $B2
	db $E8, $22
	db $E2
	db $52
	db $B2
	db $78
	db $82
	db $C6
	db $E8, $00
	db $B8
	db $98
	db $E3
	db $32
	db $E2
	db $82
	db $E8, $22
	db $82
	db $E8, $00
	db $42
	db $E8, $22
	db $92
	db $E8, $00
	db $42
	db $E8, $22
	db $B2
	db $C2
	db $E3
	db $26
	db $E2
	db $B2
	db $E3
	db $92
	db $E1
	db $B2
	db $E3
	db $72
	db $E2
	db $72
	db $E3
	db $B8
	db $42
	db $E8, $00
	db $E2
	db $B2
	db $82
	db $B2
	db $E8, $22
	db $E3
	db $A8
	db $44
	db $62
	db $72
	db $6A
	db $62
	db $52
	db $62
	db $B2
	db $C2
	db $B2
	db $B2
	db $CA
	db $E8, $00
	db $C2
	db $E3
	db $22
	db $22
	db $24
	db $12
	db $E2
	db $B2
	db $98
	db $56
	db $E3
	db $04
	db $E2
	db $B8
	db $E8, $22
	db $C2
	db $72
	db $92
	db $B2
	db $E3
	db $24
	db $12
	db $E2
	db $B2
	db $C2
	db $92
	db $C2
	db $74
	db $02
	db $42
	db $74
	db $92
	db $B2
	db $94
	db $E3
	db $22
	db $E2
	db $92
	db $94
	db $A2
	db $E3
	db $02
	db $26
	db $02
	db $52
	db $C2
	db $32
	db $C2
	db $24
	db $22
	db $22
	db $22
	db $C2
	db $64
	db $72
	db $82
	db $CE
	db $C0
	db $FE, $00

Audio1_Mus_RushSpaceshipA:
	db $D6, $11, $91, $00, $89, $24, $C7
	db $E2
	db $FB
	db $CA
	db $82
	db $C2
	db $72
	db $CA
	db $62
	db $72
	db $82
	db $FD, $01
	db $FC
	db $E1
	db $B2
	db $B1
	db $B1
	db $B2
	db $B1
	db $B1
	db $B2
	db $81
	db $81
	db $B2
	db $B4
	db $B1
	db $B1
	db $E2
	db $22
	db $21
	db $21
	db $E1
	db $22
	db $72
	db $B2
	db $B4
	db $B1
	db $B1
	db $B2
	db $B1
	db $B1
	db $B2
	db $82
	db $B2
	db $E2
	db $24
	db $42
	db $22
	db $14
	db $22
	db $42
	db $62
	db $E1
	db $B2
	db $B1
	db $B1
	db $B2
	db $B1
	db $B1
	db $B2
	db $B1
	db $B1
	db $B2
	db $B4
	db $B1
	db $B1
	db $E2
	db $22
	db $21
	db $21
	db $E1
	db $22
	db $72
	db $B2
	db $84
	db $81
	db $81
	db $82
	db $81
	db $81
	db $82
	db $82
	db $82
	db $74
	db $71
	db $71
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $72
	db $E2
	db $14
	db $11
	db $11
	db $12
	db $11
	db $11
	db $12
	db $02
	db $12
	db $32
	db $C2
	db $62
	db $E1
	db $62
	db $C4
	db $B2
	db $A2
	db $94
	db $E2
	db $92
	db $92
	db $94
	db $62
	db $62
	db $58
	db $06
	db $94
	db $78
	db $E1
	db $B2
	db $B1
	db $B1
	db $B2
	db $B1
	db $B1
	db $B2
	db $B1
	db $B1
	db $B2
	db $B1
	db $B1
	db $B2
	db $B1
	db $B1
	db $B2
	db $44
	db $41
	db $41
	db $42
	db $41
	db $41
	db $42
	db $41
	db $41
	db $42
	db $54
	db $51
	db $51
	db $52
	db $51
	db $51
	db $52
	db $51
	db $51
	db $52
	db $A4
	db $A1
	db $A1
	db $A2
	db $A1
	db $A1
	db $A2
	db $A1
	db $A1
	db $A2
	db $94
	db $92
	db $92
	db $92
	db $C2
	db $94
	db $E2
	db $02
	db $E1
	db $B2
	db $CE
	db $C0
	db $FE, $00
	db $FF

Audio1_Mus_RushSpaceshipC:
	db $D6, $05, $86, $A0
	db $FB
	db $CA
	db $E2
	db $B2
	db $C2
	db $B2
	db $CA
	db $E2
	db $A2
	db $B2
	db $B2
	db $FD, $01
	db $FC
	db $E1
	db $42
	db $41
	db $41
	db $42
	db $41
	db $41
	db $E2
	db $42
	db $E1
	db $B2
	db $42
	db $74
	db $71
	db $71
	db $72
	db $71
	db $71
	db $72
	db $B2
	db $E2
	db $22
	db $E1
	db $44
	db $41
	db $41
	db $42
	db $41
	db $41
	db $E2
	db $42
	db $E1
	db $B2
	db $42
	db $74
	db $92
	db $72
	db $64
	db $72
	db $92
	db $B2
	db $42
	db $41
	db $41
	db $42
	db $41
	db $41
	db $E2
	db $42
	db $E1
	db $B2
	db $42
	db $74
	db $71
	db $71
	db $72
	db $71
	db $71
	db $72
	db $B2
	db $E2
	db $22
	db $E1
	db $44
	db $41
	db $41
	db $42
	db $41
	db $41
	db $42
	db $41
	db $41
	db $42
	db $44
	db $41
	db $41
	db $42
	db $41
	db $41
	db $42
	db $41
	db $41
	db $42
	db $64
	db $61
	db $61
	db $62
	db $61
	db $61
	db $62
	db $52
	db $62
	db $B2
	db $C2
	db $E2
	db $B2
	db $E1
	db $B2
	db $CA
	db $E2
	db $22
	db $21
	db $21
	db $22
	db $21
	db $21
	db $22
	db $21
	db $21
	db $22
	db $54
	db $51
	db $51
	db $52
	db $54
	db $51
	db $51
	db $52
	db $51
	db $51
	db $42
	db $41
	db $41
	db $42
	db $41
	db $41
	db $42
	db $41
	db $41
	db $42
	db $41
	db $41
	db $42
	db $41
	db $41
	db $42
	db $41
	db $41
	db $42
	db $41
	db $41
	db $42
	db $E1
	db $94
	db $91
	db $91
	db $92
	db $91
	db $91
	db $92
	db $91
	db $91
	db $92
	db $A4
	db $A1
	db $A1
	db $A2
	db $A1
	db $A1
	db $A2
	db $A1
	db $A1
	db $A2
	db $E2
	db $34
	db $31
	db $31
	db $32
	db $31
	db $31
	db $32
	db $31
	db $31
	db $32
	db $24
	db $22
	db $22
	db $22
	db $C2
	db $26
	db $42
	db $CE
	db $C0
	db $FE, $00

Audio1_Mus_RushSpaceshipD:
	db $D6
	db $54
	db $44
	db $52
	db $52
	db $42
	db $52
	db $C2
	db $52
	db $42
	db $72
	db $52
	db $52
	db $72
	db $92
	db $54
	db $34
	db $52
	db $62
	db $32
	db $72
	db $71
	db $71
	db $72
	db $72
	db $52
	db $52
	db $32
	db $32
	db $31
	db $31
	db $FC
	db $C4
	db $FB
	db $34
	db $C4
	db $32
	db $26
	db $FD, $02
	db $32
	db $24
	db $32
	db $72
	db $82
	db $24
	db $FB
	db $34
	db $C4
	db $32
	db $26
	db $FD, $03
	db $34
	db $24
	db $32
	db $32
	db $52
	db $32
	db $32
	db $C2
	db $54
	db $54
	db $24
	db $34
	db $24
	db $32
	db $26
	db $32
	db $26
	db $34
	db $24
	db $34
	db $24
	db $34
	db $24
	db $FB
	db $34
	db $24
	db $32
	db $26
	db $FD, $02
	db $34
	db $24
	db $32
	db $24
	db $32
	db $32
	db $32
	db $52
	db $32
	db $52
	db $D1
	db $34
	db $34
	db $34
	db $D6
	db $FB
	db $32
	db $52
	db $FD, $05
	db $D1
	db $64
	db $64
	db $64
	db $74
	db $74
	db $74
	db $84
	db $84
	db $84
	db $94
	db $94
	db $94
	db $D6
	db $FE, $00

Audio1_Mus_NeptuneB:
	db $D6, $22, $C1, $52, $8B, $26, $B5
	db $C2
	db $EF, $02
	db $EC, $07
	db $E2
	db $02
	db $C1
	db $32
	db $C1
	db $72
	db $33
	db $53
	db $92
	db $E9, $91
	db $7C
	db $E3
	db $01
	db $01
	db $02
	db $E9, $11
	db $E8, $11
	db $FB
	db $E2
	db $31
	db $71
	db $A1
	db $E3
	db $01
	db $FD, $06
	db $E8, $00
	db $E9, $A1
	db $E4
	db $02
	db $02
	db $FC
	db $F7
	dw Audio1_Mus_NeptuneB_1
	db $E8, $11
	db $E9, $71
	db $E3
	db $C2
	db $21
	db $C2
	db $03
	db $23
	db $03
	db $22
	db $F7
	dw Audio1_Mus_NeptuneB_1
	db $E8, $11
	db $E9, $71
	db $E3
	db $C2
	db $21
	db $C2
	db $03
	db $24
	db $E8, $22
	db $E9, $A1
	db $E2
	db $71
	db $91
	db $A1
	db $E3
	db $01
	db $F8
	dw Audio1_Mus_NeptuneA_2
	db $C1
	db $38
	db $C2
	db $E2
	db $72
	db $A2
	db $E3
	db $22
	db $72
	db $C2
	db $54
	db $32
	db $26
	db $3C
	db $32
	db $22
	db $01
	db $21
	db $0E
	db $F8
	dw Audio1_Mus_NeptuneA_2
	db $C1
	db $E3
	db $2C
	db $02
	db $22
	db $52
	db $C2
	db $34
	db $22
	db $06
	db $E2
	db $A6
	db $AA
	db $E3
	db $08
	db $58
	db $FE, $00
	db $FF

Audio1_Mus_NeptuneB_1:
	db $E9, $C1
	db $E8, $22
	db $E1
	db $A1
	db $E2
	db $07
	db $03
	db $23
	db $32
	db $78
	db $71
	db $92
	db $72
	db $52
	db $31
	db $54
	db $56
	db $C2
	db $52
	db $32
	db $21
	db $31
	db $2E
	db $E1
	db $A1
	db $E2
	db $07
	db $03
	db $23
	db $32
	db $78
	db $71
	db $92
	db $72
	db $52
	db $31
	db $54
	db $A2
	db $AA
	db $F9

Audio1_Mus_NeptuneA_2:
	db $E3
	db $28
	db $C2
	db $E2
	db $52
	db $92
	db $E3
	db $02
	db $52
	db $C2
	db $34
	db $22
	db $06
	db $2C
	db $C2
	db $31
	db $21
	db $01
	db $21
	db $0D
	db $FA

Audio1_Mus_NeptuneA:
	db $D6, $22, $61, $52, $8B, $26, $B5
	db $C2
	db $EC, $07
	db $E2
	db $73
	db $73
	db $32
	db $03
	db $23
	db $52
	db $3C
	db $71
	db $71
	db $72
	db $EF, $01
	db $E8, $33
	db $EE, $03
	db $FB
	db $E2
	db $31
	db $71
	db $A1
	db $E3
	db $01
	db $FD, $07
	db $FC
	db $F7
	dw Audio1_Mus_NeptuneA_1
	db $E8, $00
	db $EE, $05
	db $C2
	db $51
	db $C2
	db $32
	db $C1
	db $53
	db $33
	db $52
	db $F7
	dw Audio1_Mus_NeptuneA_1
	db $E8, $00
	db $EE, $05
	db $C2
	db $51
	db $C2
	db $33
	db $54
	db $EE, $04
	db $E8, $22
	db $E2
	db $71
	db $91
	db $A1
	db $E3
	db $01
	db $C1
	db $F8
	dw Audio1_Mus_NeptuneA_2
	db $C1
	db $38
	db $C2
	db $E2
	db $72
	db $A2
	db $E3
	db $22
	db $72
	db $C2
	db $54
	db $32
	db $26
	db $3C
	db $32
	db $22
	db $01
	db $21
	db $0D
	db $C1
	db $F8
	dw Audio1_Mus_NeptuneA_2
	db $EE, $03
	db $E2
	db $AC
	db $92
	db $A2
	db $E3
	db $22
	db $C2
	db $04
	db $E2
	db $A2
	db $96
	db $76
	db $7A
	db $98
	db $E3
	db $28
	db $FE, $00
	db $FF

Audio1_Mus_NeptuneA_1:
	db $EE, $04
	db $E8, $33
	db $FB
	db $E2
	db $31
	db $71
	db $A1
	db $E3
	db $01
	db $FD, $07
	db $FB
	db $E1
	db $A1
	db $E2
	db $21
	db $51
	db $A1
	db $FD, $07
	db $FB
	db $E2
	db $31
	db $71
	db $A1
	db $E3
	db $01
	db $FD, $07
	db $FB
	db $E1
	db $A1
	db $E2
	db $21
	db $51
	db $A1
	db $FD, $03
	db $F9

Audio1_Mus_NeptuneC:
	db $D6, $01, $86, $B0
	db $C2
	db $EC, $07
	db $E2
	db $03
	db $E1
	db $A3
	db $72
	db $A3
	db $73
	db $32
	db $0C
	db $01
	db $01
	db $02
	db $FB
	db $E2
	db $01
	db $E1
	db $A1
	db $71
	db $A1
	db $E2
	db $03
	db $01
	db $FD, $03
	db $FC
	db $F7
	dw Audio1_Mus_NeptuneC_1
	db $E1
	db $A2
	db $A2
	db $C1
	db $93
	db $A3
	db $93
	db $A2
	db $F7
	dw Audio1_Mus_NeptuneC_1
	db $E1
	db $A2
	db $A2
	db $C1
	db $93
	db $A4
	db $E1
	db $71
	db $91
	db $A1
	db $E2
	db $01
	db $F8
	dw Audio1_Mus_NeptuneC_2
	db $FB
	db $E1
	db $72
	db $71
	db $71
	db $71
	db $51
	db $71
	db $71
	db $FD, $01
	db $FB
	db $E1
	db $52
	db $51
	db $51
	db $51
	db $31
	db $51
	db $51
	db $FD, $01
	db $FB
	db $E2
	db $02
	db $01
	db $01
	db $01
	db $E1
	db $A1
	db $E2
	db $01
	db $01
	db $FD, $01
	db $F8
	dw Audio1_Mus_NeptuneC_2
	db $FB
	db $E1
	db $52
	db $51
	db $51
	db $51
	db $31
	db $51
	db $51
	db $FD, $01
	db $F8
	dw Audio1_Mus_NeptuneC_2
	db $FB
	db $E1
	db $72
	db $71
	db $71
	db $71
	db $51
	db $71
	db $71
	db $FD, $01
	db $FB
	db $E1
	db $52
	db $51
	db $51
	db $51
	db $31
	db $51
	db $51
	db $FD, $01
	db $FB
	db $E1
	db $72
	db $71
	db $71
	db $FD, $03
	db $FB
	db $52
	db $51
	db $51
	db $FD, $03
	db $FB
	db $32
	db $31
	db $31
	db $FD, $03
	db $FB
	db $52
	db $52
	db $FD, $01
	db $FB
	db $22
	db $22
	db $FD, $01
	db $FE, $00
	db $FF

Audio1_Mus_NeptuneC_1:
	db $FB
	db $E2
	db $01
	db $E1
	db $A1
	db $71
	db $A1
	db $E2
	db $03
	db $01
	db $FD, $03
	db $FB
	db $E1
	db $A1
	db $81
	db $51
	db $81
	db $A3
	db $A1
	db $FD, $03
	db $FB
	db $E2
	db $01
	db $E1
	db $A1
	db $71
	db $A1
	db $E2
	db $03
	db $01
	db $FD, $03
	db $FB
	db $E1
	db $A1
	db $81
	db $51
	db $81
	db $A3
	db $A1
	db $FD, $01
	db $F9

Audio1_Mus_NeptuneC_2:
	db $FB
	db $E1
	db $A2
	db $A1
	db $A1
	db $A1
	db $81
	db $A1
	db $A1
	db $FD, $01
	db $FB
	db $E1
	db $92
	db $91
	db $91
	db $91
	db $71
	db $91
	db $91
	db $FD, $01
	db $FA

Audio1_Mus_NeptuneD:
	db $D6
	db $C2
	db $23
	db $23
	db $22
	db $23
	db $23
	db $22
	db $24
	db $14
	db $14
	db $31
	db $31
	db $32
	db $24
	db $32
	db $11
	db $11
	db $F7
	dw Audio1_Mus_NeptuneD_1
	db $FB
	db $F7
	dw Audio1_Mus_NeptuneD_1
	db $FD, $01
	db $FC
	db $F8
	dw Audio1_Mus_NeptuneD_2
	db $C2
	db $22
	db $31
	db $23
	db $23
	db $33
	db $32
	db $F8
	dw Audio1_Mus_NeptuneD_2
	db $C2
	db $22
	db $31
	db $23
	db $34
	db $31
	db $31
	db $31
	db $31
	db $FB
	db $11
	db $11
	db $22
	db $32
	db $22
	db $FD, $1D
	db $12
	db $22
	db $32
	db $22
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $32
	db $FE, $00
	db $FF

Audio1_Mus_NeptuneD_1:
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $F9

Audio1_Mus_NeptuneD_2:
	db $24
	db $32
	db $11
	db $11
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FB
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FD, $0B
	db $FA

Audio1_Mus_CutsceneAltB:
	db $D6, $22, $F1, $53, $8B, $26, $B5
	db $C2
	db $EC, $05
	db $EF, $02
	db $E9, $C1
	db $E8, $11
	db $C8
	db $E1
	db $33
	db $53
	db $32
	db $FC
	db $EF, $02
	db $E8, $11
	db $E9, $A1
	db $F7
	dw Audio1_Mus_CutsceneAltB_1
	db $02
	db $02
	db $21
	db $02
	db $72
	db $71
	db $51
	db $31
	db $51
	db $33
	db $F7
	dw Audio1_Mus_CutsceneAltB_1
	db $02
	db $02
	db $21
	db $02
	db $01
	db $33
	db $53
	db $72
	db $E9, $C1
	db $E8, $22
	db $F8
	dw Audio1_Mus_CutsceneAltB_2
	db $F8
	dw Audio1_Mus_CutsceneAltB_2
	db $FE, $00
	db $FF

Audio1_Mus_CutsceneAltB_1:
	db $E2
	db $02
	db $02
	db $21
	db $02
	db $33
	db $21
	db $01
	db $21
	db $03
	db $02
	db $02
	db $21
	db $02
	db $52
	db $51
	db $31
	db $21
	db $31
	db $23
	db $02
	db $02
	db $21
	db $02
	db $33
	db $21
	db $01
	db $21
	db $03
	db $F9

Audio1_Mus_CutsceneAltB_2:
	db $E2
	db $74
	db $A1
	db $92
	db $59
	db $52
	db $52
	db $91
	db $52
	db $79
	db $74
	db $E3
	db $01
	db $E2
	db $A2
	db $99
	db $52
	db $52
	db $21
	db $22
	db $79
	db $FA

Audio1_Mus_CutsceneAltA:
	db $D6, $22, $F1, $52, $89, $25, $B5
	db $C2
	db $EC, $05
	db $EF, $01
	db $C8
	db $E1
	db $73
	db $93
	db $72
	db $FC
	db $E8, $22
	db $EE, $05
	db $FB
	db $E2
	db $04
	db $24
	db $34
	db $53
	db $05
	db $24
	db $34
	db $54
	db $FD, $02
	db $04
	db $24
	db $34
	db $53
	db $05
	db $24
	db $03
	db $23
	db $32
	db $EE, $06
	db $FB
	db $C1
	db $E8, $22
	db $F7
	dw Audio1_Mus_CutsceneAltA_1
	db $FD, $01
	db $FE, $00
	db $FF

Audio1_Mus_CutsceneAltA_1:
	db $E2
	db $74
	db $A1
	db $92
	db $59
	db $52
	db $52
	db $91
	db $52
	db $79
	db $74
	db $E3
	db $01
	db $E2
	db $A2
	db $99
	db $52
	db $52
	db $21
	db $22
	db $78
	db $F9

Audio1_Mus_CutsceneAltC:
	db $D6, $01, $85, $B0
	db $C2
	db $EC, $05
	db $C8
	db $E2
	db $03
	db $23
	db $02
	db $FC
	db $FB
	db $E1
	db $02
	db $32
	db $52
	db $72
	db $52
	db $92
	db $A2
	db $E2
	db $02
	db $FD, $06
	db $E1
	db $02
	db $32
	db $52
	db $72
	db $E2
	db $03
	db $E1
	db $A3
	db $32
	db $FB
	db $E1
	db $72
	db $E2
	db $72
	db $E1
	db $72
	db $E2
	db $72
	db $E1
	db $52
	db $E2
	db $52
	db $E1
	db $52
	db $E2
	db $52
	db $E1
	db $52
	db $E2
	db $52
	db $E1
	db $52
	db $E2
	db $52
	db $E1
	db $72
	db $E2
	db $72
	db $E1
	db $72
	db $E2
	db $72
	db $FD, $03
	db $FE, $00
	db $FF

Audio1_Mus_CutsceneAltD:
	db $D6
	db $C2
	db $61
	db $61
	db $71
	db $71
	db $61
	db $61
	db $71
	db $71
	db $23
	db $33
	db $32
	db $FC
	db $FB
	db $12
	db $32
	db $FD, $1B
	db $12
	db $32
	db $12
	db $32
	db $33
	db $33
	db $32
	db $FB
	db $12
	db $22
	db $32
	db $22
	db $FD, $0D
	db $12
	db $22
	db $32
	db $22
	db $12
	db $22
	db $61
	db $61
	db $71
	db $71
	db $FE, $00
	db $FF

Audio1_Mus_BossB:
	db $D6, $22, $F1, $33, $AB, $26, $B5
	db $C2
	db $FC
	db $F3, $02
	db $EF, $02
	db $E9, $F1
	db $E8, $22
	db $EC, $02
	db $FB
	db $F8
	dw Audio1_Mus_BossB_1
	db $EC, $05
	db $FD, $01
	db $E8, $00
	db $F3, $03
	db $EC, $02
	db $FB
	db $F7
	dw Audio1_Mus_BossB_2
	db $FD, $01
	db $E9, $81
	db $E8, $11
	db $FB
	db $E3
	db $03
	db $01
	db $C6
	db $02
	db $01
	db $33
	db $FD, $01
	db $FE, $00
	db $FF

Audio1_Mus_BossB_2:
	db $E9, $F1
	db $E1
	db $A1
	db $E9, $D1
	db $B2
	db $A5
	db $E9, $81
	db $A4
	db $94
	db $E9, $F1
	db $81
	db $E9, $D1
	db $92
	db $85
	db $E9, $81
	db $84
	db $74
	db $E9, $F1
	db $A1
	db $E9, $D1
	db $B2
	db $A5
	db $E9, $81
	db $A4
	db $94
	db $E9, $F1
	db $E2
	db $01
	db $E9, $D1
	db $12
	db $05
	db $E9, $81
	db $04
	db $E1
	db $B4
	db $F9

Audio1_Mus_BossB_1:
	db $E1
	db $51
	db $61
	db $71
	db $81
	db $51
	db $61
	db $71
	db $81
	db $71
	db $81
	db $91
	db $A1
	db $71
	db $81
	db $91
	db $A1
	db $FA

Audio1_Mus_BossA:
	db $D6, $22, $F1, $44, $89, $25, $B5
	db $C2
	db $EF, $01
	db $FC
	db $EE, $0F
	db $E9, $F1
	db $E8, $22
	db $F3, $01
	db $EC, $02
	db $FB
	db $F7
	dw Audio1_Mus_BossA_1
	db $EC, $0E
	db $FD, $01
	db $F3, $00
	db $EE, $0F
	db $EC, $02
	db $E9, $F1
	db $E8, $11
	db $FB
	db $F8
	dw Audio1_Mus_BossA_2
	db $FD, $07
	db $F3, $03
	db $EE, $05
	db $F8
	dw Audio1_Mus_BossA_2
	db $F8
	dw Audio1_Mus_BossA_2
	db $FE, $00
	db $FF

Audio1_Mus_BossA_1:
	db $E0
	db $51
	db $61
	db $71
	db $81
	db $51
	db $61
	db $71
	db $81
	db $71
	db $81
	db $91
	db $A1
	db $71
	db $81
	db $91
	db $A1
	db $F9

Audio1_Mus_BossA_2:
	db $EE, $06
	db $E2
	db $51
	db $EE, $04
	db $81
	db $E3
	db $01
	db $E2
	db $51
	db $81
	db $E3
	db $01
	db $E2
	db $51
	db $81
	db $E3
	db $01
	db $E2
	db $51
	db $81
	db $E3
	db $01
	db $E2
	db $51
	db $81
	db $E3
	db $01
	db $E4
	db $51
	db $FA

Audio1_Mus_BossC:
	db $D6, $01, $84, $B0
	db $C2
	db $C0
	db $C0
	db $FC
	db $EC, $0E
	db $FB
	db $F7
	dw Audio1_Mus_BossC_1
	db $FD, $03
	db $FB
	db $E1
	db $83
	db $81
	db $C6
	db $E2
	db $32
	db $31
	db $73
	db $FD, $01
	db $F7
	dw Audio1_Mus_BossC_1
	db $FE, $00
	db $FF

Audio1_Mus_BossC_1:
	db $E1
	db $51
	db $31
	db $E0
	db $A1
	db $81
	db $E1
	db $51
	db $02
	db $31
	db $11
	db $01
	db $31
	db $11
	db $E0
	db $A1
	db $81
	db $E1
	db $51
	db $E0
	db $52
	db $E1
	db $31
	db $E0
	db $A1
	db $81
	db $E1
	db $51
	db $02
	db $31
	db $11
	db $01
	db $31
	db $11
	db $E0
	db $A1
	db $81
	db $52
	db $F9

Audio1_Mus_BossD:
	db $D6
	db $C2
	db $C0
	db $14
	db $14
	db $14
	db $32
	db $31
	db $31
	db $FC
	db $FC
	db $F7
	dw Audio1_Mus_BossD_1
	db $FB
	db $F8
	dw Audio1_Mus_BossD_2
	db $FD, $02
	db $FE, $01
	db $FB
	db $24
	db $74
	db $52
	db $52
	db $74
	db $FD, $01
	db $24
	db $34
	db $22
	db $22
	db $34
	db $24
	db $34
	db $22
	db $22
	db $32
	db $31
	db $31
	db $FE, $00
	db $FF

Audio1_Mus_BossD_1:
	db $24
	db $32
	db $11
	db $31
	db $11
	db $31
	db $11
	db $11
	db $32
	db $11
	db $11
	db $F9

Audio1_Mus_BossD_2:
	db $11
	db $11
	db $11
	db $11
	db $32
	db $11
	db $31
	db $11
	db $31
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FA

Audio1_Mus_SaturnB:
	db $D3, $22, $B1, $52, $AB, $26, $B5
	db $C4
	db $EC, $FC
	db $EF, $02
	db $E9, $A1
	db $E2
	db $44
	db $42
	db $42
	db $44
	db $42
	db $42
	db $44
	db $42
	db $42
	db $44
	db $42
	db $42
	db $42
	db $52
	db $42
	db $22
	db $02
	db $22
	db $02
	db $E1
	db $B2
	db $94
	db $CC
	db $FC
	db $E8, $11
	db $F6, $03
	db $E9, $A1
	db $F7
	dw Audio1_Mus_SaturnB_1
	db $E2
	db $71
	db $C1
	db $71
	db $C5
	db $96
	db $BE
	db $E3
	db $21
	db $C1
	db $21
	db $C1
	db $F7
	dw Audio1_Mus_SaturnB_1
	db $E2
	db $71
	db $C1
	db $71
	db $C5
	db $96
	db $BA
	db $E8, $21
	db $E9, $D1
	db $B2
	db $E3
	db $02
	db $24
	db $E9, $B1
	db $F6, $06
	db $F8
	dw Audio1_Mus_SaturnB_2
	db $C2
	db $02
	db $C2
	db $E2
	db $B2
	db $C2
	db $92
	db $C2
	db $BA
	db $C2
	db $E3
	db $54
	db $4E
	db $E2
	db $91
	db $B1
	db $E3
	db $01
	db $21
	db $F8
	dw Audio1_Mus_SaturnB_2
	db $C2
	db $02
	db $C2
	db $E2
	db $B2
	db $C2
	db $92
	db $C2
	db $72
	db $92
	db $C1
	db $99
	db $74
	db $92
	db $C1
	db $99
	db $74
	db $92
	db $C1
	db $9D
	db $C4
	db $FE, $00
	db $FF

Audio1_Mus_SaturnB_1:
	db $E2
	db $91
	db $C1
	db $91
	db $C5
	db $B6
	db $E3
	db $0E
	db $41
	db $C1
	db $41
	db $C1
	db $E2
	db $91
	db $C1
	db $91
	db $C5
	db $B6
	db $E3
	db $0E
	db $41
	db $C1
	db $41
	db $C1
	db $E2
	db $71
	db $C1
	db $71
	db $C5
	db $96
	db $BE
	db $E3
	db $21
	db $C1
	db $21
	db $C1
	db $F9

Audio1_Mus_SaturnB_2:
	db $E3
	db $48
	db $C2
	db $02
	db $22
	db $52
	db $C2
	db $42
	db $C2
	db $22
	db $C2
	db $02
	db $C2
	db $2A
	db $C2
	db $42
	db $42
	db $20
	db $C2
	db $08
	db $C2
	db $E2
	db $92
	db $B2
	db $E3
	db $22
	db $FA

Audio1_Mus_SaturnA:
	db $D3, $22, $71, $52, $AB, $26, $B5
	db $C4
	db $EC, $FC
	db $EF, $01
	db $E9, $61
	db $E2
	db $04
	db $02
	db $02
	db $04
	db $02
	db $02
	db $04
	db $02
	db $02
	db $04
	db $02
	db $02
	db $F6, $06
	db $4C
	db $C4
	db $FC
	db $F6, $03
	db $E9, $81
	db $E8, $11
	db $F7
	dw Audio1_Mus_SaturnA_1
	db $FB
	db $E1
	db $72
	db $92
	db $B2
	db $E2
	db $02
	db $FD, $02
	db $C4
	db $E1
	db $B2
	db $B2
	db $F7
	dw Audio1_Mus_SaturnA_1
	db $FB
	db $E1
	db $72
	db $92
	db $B2
	db $E2
	db $02
	db $FD, $02
	db $F6, $06
	db $E9, $B1
	db $E8, $21
	db $E2
	db $71
	db $91
	db $B2
	db $E9, $61
	db $F8
	dw Audio1_Mus_SaturnA_2
	db $C2
	db $94
	db $58
	db $7C
	db $E3
	db $24
	db $0A
	db $E1
	db $91
	db $E2
	db $01
	db $41
	db $91
	db $E1
	db $91
	db $E2
	db $01
	db $41
	db $91
	db $F8
	dw Audio1_Mus_SaturnA_2
	db $98
	db $58
	db $42
	db $C1
	db $49
	db $24
	db $42
	db $C1
	db $49
	db $24
	db $42
	db $C1
	db $4D
	db $C4
	db $FE, $00
	db $FF

Audio1_Mus_SaturnA_1:
	db $FB
	db $E1
	db $92
	db $B2
	db $E2
	db $02
	db $22
	db $FD, $02
	db $C4
	db $E2
	db $02
	db $02
	db $FB
	db $E1
	db $92
	db $B2
	db $E2
	db $02
	db $22
	db $FD, $02
	db $C4
	db $E2
	db $02
	db $02
	db $FB
	db $E1
	db $72
	db $92
	db $B2
	db $E2
	db $02
	db $FD, $02
	db $C4
	db $E1
	db $B2
	db $B2
	db $F9

Audio1_Mus_SaturnA_2:
	db $E3
	db $0A
	db $E2
	db $92
	db $B2
	db $E3
	db $22
	db $C2
	db $04
	db $E2
	db $98
	db $BC
	db $E3
	db $02
	db $02
	db $E2
	db $BA
	db $E2
	db $71
	db $91
	db $B1
	db $E3
	db $01
	db $E2
	db $71
	db $91
	db $B1
	db $E3
	db $01
	db $E2
	db $9A
	db $52
	db $72
	db $B2
	db $FA

Audio1_Mus_SaturnC:
	db $D3, $01, $86, $B0
	db $C4
	db $EC, $FC
	db $E2
	db $94
	db $92
	db $92
	db $94
	db $92
	db $92
	db $94
	db $92
	db $92
	db $94
	db $92
	db $92
	db $92
	db $B2
	db $E3
	db $02
	db $22
	db $02
	db $22
	db $E2
	db $B2
	db $E3
	db $02
	db $E2
	db $98
	db $E3
	db $91
	db $71
	db $51
	db $41
	db $21
	db $01
	db $E2
	db $B1
	db $91
	db $FC
	db $F6, $06
	db $FB
	db $E2
	db $92
	db $91
	db $91
	db $FD, $07
	db $FB
	db $E2
	db $72
	db $71
	db $71
	db $FD, $07
	db $FB
	db $E2
	db $92
	db $91
	db $91
	db $FD, $07
	db $FB
	db $E2
	db $72
	db $71
	db $71
	db $FD, $06
	db $B1
	db $91
	db $72
	db $F7
	dw Audio1_Mus_SaturnC_1
	db $FB
	db $E2
	db $42
	db $21
	db $E1
	db $B1
	db $B1
	db $E2
	db $22
	db $42
	db $72
	db $41
	db $41
	db $E1
	db $B1
	db $E2
	db $21
	db $41
	db $FD, $01
	db $F7
	dw Audio1_Mus_SaturnC_1
	db $E1
	db $72
	db $C1
	db $99
	db $74
	db $72
	db $C1
	db $99
	db $74
	db $72
	db $C1
	db $9D
	db $F6, $03
	db $E3
	db $91
	db $71
	db $51
	db $41
	db $21
	db $01
	db $E2
	db $B1
	db $91
	db $FE, $00
	db $FF

Audio1_Mus_SaturnC_1:
	db $FB
	db $E2
	db $92
	db $71
	db $41
	db $41
	db $72
	db $92
	db $E3
	db $02
	db $E2
	db $91
	db $91
	db $41
	db $71
	db $91
	db $FD, $01
	db $FB
	db $E2
	db $72
	db $51
	db $21
	db $21
	db $52
	db $72
	db $B2
	db $71
	db $71
	db $21
	db $51
	db $71
	db $FD, $01
	db $FB
	db $E2
	db $52
	db $31
	db $01
	db $01
	db $32
	db $52
	db $92
	db $51
	db $51
	db $01
	db $31
	db $51
	db $FD, $01
	db $F9

Audio1_Mus_SaturnD:
	db $D6
	db $C2
	db $24
	db $32
	db $11
	db $11
	db $22
	db $11
	db $11
	db $32
	db $11
	db $11
	db $28
	db $34
	db $C4
	db $FC
	db $24
	db $32
	db $11
	db $11
	db $22
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FB
	db $22
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FD, $0B
	db $22
	db $11
	db $11
	db $32
	db $11
	db $11
	db $22
	db $11
	db $11
	db $31
	db $31
	db $31
	db $31
	db $FB
	db $F7
	dw Audio1_Mus_SaturnD_1
	db $FD, $06
	db $32
	db $11
	db $11
	db $32
	db $11
	db $11
	db $32
	db $11
	db $11
	db $31
	db $31
	db $31
	db $31
	db $FB
	db $F7
	dw Audio1_Mus_SaturnD_1
	db $FD, $05
	db $23
	db $29
	db $34
	db $23
	db $29
	db $34
	db $23
	db $29
	db $71
	db $71
	db $71
	db $71
	db $31
	db $31
	db $31
	db $31
	db $FE, $00
	db $FF

Audio1_Mus_SaturnD_1:
	db $32
	db $11
	db $11
	db $32
	db $11
	db $11
	db $32
	db $11
	db $11
	db $32
	db $22
	db $F9

Audio1_Mus_MercuryB:
	db $D6, $22, $B1, $52, $AB, $26, $B5
	db $C2
	db $EF, $02
	db $EC, $03
	db $E9, $A1
	db $E8, $11
	db $C9
	db $FC
	db $C0
	db $C8
	db $E2
	db $A1
	db $C1
	db $A1
	db $C2
	db $E3
	db $03
	db $C0
	db $C8
	db $E2
	db $A1
	db $C1
	db $A1
	db $C2
	db $E3
	db $02
	db $F7
	dw Audio1_Mus_MercuryB_1
	db $E9, $A1
	db $E8, $11
	db $E2
	db $A1
	db $C1
	db $A1
	db $C1
	db $A1
	db $E3
	db $02
	db $F7
	dw Audio1_Mus_MercuryB_1
	db $E9, $A1
	db $E8, $11
	db $E2
	db $A1
	db $91
	db $A2
	db $A1
	db $E3
	db $02
	db $F8
	dw Audio1_Mus_MercuryB_2
	db $E2
	db $AB
	db $E9, $81
	db $E8, $00
	db $E2
	db $21
	db $31
	db $C1
	db $52
	db $F8
	dw Audio1_Mus_MercuryB_2
	db $E2
	db $A9
	db $E9, $81
	db $E8, $11
	db $E2
	db $A1
	db $C1
	db $A1
	db $C1
	db $A1
	db $E3
	db $03
	db $FE, $00
	db $FF

Audio1_Mus_MercuryB_1:
	db $E9, $B1
	db $E8, $11
	db $E2
	db $03
	db $C2
	db $34
	db $52
	db $32
	db $51
	db $72
	db $C1
	db $A1
	db $C1
	db $7D
	db $E2
	db $03
	db $C2
	db $34
	db $52
	db $32
	db $51
	db $72
	db $C1
	db $A1
	db $C1
	db $76
	db $E9, $81
	db $E8, $11
	db $E3
	db $01
	db $C1
	db $01
	db $C1
	db $01
	db $22
	db $E9, $B1
	db $E8, $11
	db $E1
	db $A3
	db $C2
	db $E2
	db $24
	db $32
	db $22
	db $31
	db $52
	db $C1
	db $91
	db $C1
	db $5D
	db $E2
	db $A3
	db $C2
	db $E2
	db $24
	db $32
	db $22
	db $31
	db $52
	db $C1
	db $91
	db $C1
	db $56
	db $F9

Audio1_Mus_MercuryB_2:
	db $E9, $A1
	db $E8, $11
	db $E3
	db $28
	db $53
	db $32
	db $21
	db $02
	db $29
	db $E9, $31
	db $E2
	db $51
	db $31
	db $55
	db $E9, $A1
	db $E3
	db $08
	db $33
	db $22
	db $01
	db $22
	db $FA

Audio1_Mus_MercuryA:
	db $D6, $22, $71, $52, $AB, $26, $B5
	db $C2
	db $EC, $03
	db $EF, $01
	db $E9, $91
	db $E8, $11
	db $C9
	db $FC
	db $FB
	db $EE, $05
	db $E9, $91
	db $E2
	db $01
	db $EE, $04
	db $31
	db $71
	db $A1
	db $FD, $05
	db $EE, $06
	db $E2
	db $71
	db $C1
	db $71
	db $C2
	db $93
	db $FB
	db $EE, $05
	db $E9, $91
	db $E2
	db $01
	db $EE, $04
	db $31
	db $71
	db $A1
	db $FD, $05
	db $EE, $06
	db $E2
	db $71
	db $C1
	db $71
	db $C2
	db $93
	db $F7
	dw Audio1_Mus_MercuryA_1
	db $71
	db $C1
	db $71
	db $C1
	db $71
	db $93
	db $F7
	dw Audio1_Mus_MercuryA_1
	db $71
	db $51
	db $72
	db $71
	db $93
	db $F8
	dw Audio1_Mus_MercuryA_2
	db $E3
	db $21
	db $31
	db $21
	db $01
	db $21
	db $01
	db $51
	db $31
	db $71
	db $51
	db $A1
	db $91
	db $71
	db $51
	db $31
	db $51
	db $F8
	dw Audio1_Mus_MercuryA_2
	db $E3
	db $21
	db $31
	db $21
	db $01
	db $21
	db $01
	db $51
	db $31
	db $E9, $91
	db $E8, $11
	db $E2
	db $71
	db $C1
	db $71
	db $C1
	db $71
	db $93
	db $FE, $00
	db $FF

Audio1_Mus_MercuryA_1:
	db $FB
	db $EE, $05
	db $E9, $91
	db $E2
	db $01
	db $EE, $04
	db $31
	db $71
	db $A1
	db $FD, $05
	db $E3
	db $71
	db $31
	db $01
	db $31
	db $01
	db $E2
	db $A1
	db $71
	db $31
	db $FB
	db $EE, $05
	db $E9, $91
	db $E2
	db $01
	db $EE, $04
	db $31
	db $71
	db $A1
	db $FD, $05
	db $EE, $06
	db $91
	db $C1
	db $91
	db $C1
	db $91
	db $A3
	db $FB
	db $EE, $04
	db $E1
	db $A1
	db $E2
	db $21
	db $51
	db $A1
	db $FD, $05
	db $E2
	db $A1
	db $E3
	db $51
	db $21
	db $E2
	db $A1
	db $E3
	db $21
	db $E2
	db $A1
	db $91
	db $51
	db $FB
	db $E1
	db $A1
	db $E2
	db $21
	db $51
	db $A1
	db $FD, $05
	db $EE, $06
	db $F9

Audio1_Mus_MercuryA_2:
	db $EE, $05
	db $E9, $81
	db $E3
	db $21
	db $01
	db $E2
	db $A1
	db $91
	db $E3
	db $01
	db $E2
	db $A1
	db $91
	db $71
	db $A1
	db $71
	db $91
	db $71
	db $51
	db $71
	db $51
	db $21
	db $51
	db $21
	db $71
	db $21
	db $E1
	db $A1
	db $E2
	db $51
	db $31
	db $21
	db $31
	db $21
	db $01
	db $E1
	db $A1
	db $91
	db $A1
	db $01
	db $E2
	db $21
	db $31
	db $01
	db $21
	db $31
	db $51
	db $31
	db $51
	db $71
	db $91
	db $71
	db $A1
	db $91
	db $E3
	db $01
	db $E2
	db $A1
	db $E3
	db $21
	db $01
	db $FA

Audio1_Mus_MercuryC:
	db $D6, $01, $86, $B0
	db $C2
	db $EC, $03
	db $C8
	db $FC
	db $FB
	db $E2
	db $03
	db $02
	db $E1
	db $A1
	db $E2
	db $03
	db $02
	db $02
	db $32
	db $01
	db $FD, $07
	db $FB
	db $E1
	db $A3
	db $A2
	db $91
	db $A3
	db $A2
	db $A2
	db $E2
	db $22
	db $E1
	db $A1
	db $FD, $03
	db $FB
	db $E2
	db $03
	db $02
	db $E1
	db $A1
	db $E2
	db $03
	db $02
	db $02
	db $32
	db $01
	db $FD, $03
	db $FB
	db $E1
	db $A3
	db $A2
	db $91
	db $E2
	db $A3
	db $A2
	db $A2
	db $E2
	db $22
	db $E1
	db $A1
	db $FD, $02
	db $E1
	db $A3
	db $A2
	db $91
	db $E2
	db $A3
	db $E2
	db $21
	db $01
	db $22
	db $21
	db $32
	db $F7
	dw Audio1_Mus_MercuryC_1
	db $F8
	dw Audio1_Mus_MercuryC_2
	db $E2
	db $23
	db $21
	db $21
	db $22
	db $21
	db $21
	db $22
	db $21
	db $21
	db $22
	db $21
	db $F7
	dw Audio1_Mus_MercuryC_1
	db $F8
	dw Audio1_Mus_MercuryC_2
	db $E2
	db $22
	db $51
	db $31
	db $01
	db $31
	db $21
	db $01
	db $E1
	db $A1
	db $E2
	db $22
	db $22
	db $21
	db $32
	db $FE, $00
	db $FF

Audio1_Mus_MercuryC_1:
	db $E2
	db $73
	db $71
	db $71
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $72
	db $71
	db $E2
	db $53
	db $51
	db $51
	db $52
	db $51
	db $51
	db $52
	db $51
	db $51
	db $52
	db $51
	db $F9

Audio1_Mus_MercuryC_2:
	db $E2
	db $33
	db $31
	db $31
	db $32
	db $31
	db $31
	db $32
	db $31
	db $31
	db $32
	db $31
	db $FA

Audio1_Mus_MercuryD:
	db $D6
	db $C2
	db $71
	db $71
	db $71
	db $71
	db $81
	db $81
	db $82
	db $FC
	db $FB
	db $25
	db $F7
	dw Audio1_Mus_MercuryD_1
	db $11
	db $11
	db $11
	db $11
	db $11
	db $32
	db $11
	db $11
	db $32
	db $32
	db $31
	db $32
	db $FD, $01
	db $FB
	db $25
	db $F7
	dw Audio1_Mus_MercuryD_1
	db $11
	db $11
	db $11
	db $11
	db $11
	db $F7
	dw Audio1_Mus_MercuryD_1
	db $FD, $02
	db $25
	db $F7
	dw Audio1_Mus_MercuryD_1
	db $11
	db $11
	db $11
	db $11
	db $11
	db $32
	db $11
	db $11
	db $32
	db $32
	db $31
	db $32
	db $FB
	db $25
	db $F7
	dw Audio1_Mus_MercuryD_1
	db $11
	db $11
	db $11
	db $11
	db $11
	db $F7
	dw Audio1_Mus_MercuryD_1
	db $FD, $02
	db $25
	db $F7
	dw Audio1_Mus_MercuryD_1
	db $11
	db $11
	db $11
	db $11
	db $11
	db $32
	db $11
	db $11
	db $31
	db $31
	db $32
	db $31
	db $32
	db $FB
	db $F8
	dw Audio1_Mus_MercuryD_2
	db $FD, $06
	db $11
	db $11
	db $11
	db $22
	db $32
	db $22
	db $32
	db $32
	db $31
	db $32
	db $FE, $00
	db $FF

Audio1_Mus_MercuryD_1:
	db $32
	db $11
	db $11
	db $11
	db $11
	db $11
	db $11
	db $32
	db $11
	db $F9

Audio1_Mus_MercuryD_2:
	db $11
	db $11
	db $11
	db $22
	db $52
	db $22
	db $11
	db $11
	db $22
	db $52
	db $21
	db $FA

Audio1_Mus_CutsceneB:
	db $D6, $11, $B1, $52, $AB, $26, $B5
	db $C2
	db $EF, $02
	db $EC, $03
	db $E9, $A1
	db $FC
	db $E2
	db $70
	db $80
	db $90
	db $A0
	db $E9, $B1
	db $E2
	db $71
	db $71
	db $C4
	db $71
	db $71
	db $C2
	db $54
	db $62
	db $71
	db $C7
	db $E9, $E1
	db $F3, $02
	db $F6, $03
	db $E4
	db $01
	db $E3
	db $B1
	db $91
	db $71
	db $51
	db $41
	db $21
	db $01
	db $E2
	db $B1
	db $91
	db $71
	db $51
	db $41
	db $21
	db $02
	db $F3, $03
	db $E9, $B1
	db $F6, $06
	db $E2
	db $21
	db $31
	db $32
	db $03
	db $72
	db $23
	db $52
	db $02
	db $21
	db $31
	db $32
	db $03
	db $72
	db $23
	db $52
	db $02
	db $31
	db $55
	db $5A
	db $50
	db $31
	db $51
	db $52
	db $23
	db $82
	db $53
	db $72
	db $22
	db $31
	db $51
	db $52
	db $23
	db $82
	db $53
	db $72
	db $22
	db $51
	db $75
	db $7A
	db $78
	db $C2
	db $82
	db $72
	db $5A
	db $C2
	db $02
	db $72
	db $52
	db $3C
	db $22
	db $02
	db $E1
	db $A4
	db $84
	db $72
	db $E2
	db $54
	db $3A
	db $C2
	db $32
	db $32
	db $5A
	db $C2
	db $52
	db $32
	db $7A
	db $C2
	db $52
	db $72
	db $8A
	db $C2
	db $32
	db $52
	db $70
	db $C2
	db $72
	db $21
	db $C1
	db $A2
	db $71
	db $C5
	db $31
	db $71
	db $81
	db $A1
	db $FB
	db $E2
	db $A1
	db $E3
	db $05
	db $E2
	db $72
	db $A6
	db $52
	db $51
	db $73
	db $7C
	db $E2
	db $A1
	db $E3
	db $05
	db $E2
	db $72
	db $A6
	db $52
	db $51
	db $73
	db $A8
	db $91
	db $A3
	db $FD, $01
	db $E3
	db $00
	db $C0
	db $FE, $00
	db $FF

Audio1_Mus_CutsceneA:
	db $D6, $11, $61, $52, $AB, $26, $B5
	db $C2
	db $EF, $01
	db $EC, $03
	db $E8, $0B
	db $FC
	db $EE, $05
	db $FB
	db $E2
	db $01
	db $31
	db $71
	db $A1
	db $FD, $0F
	db $EE, $07
	db $E2
	db $01
	db $01
	db $C4
	db $01
	db $01
	db $C2
	db $E1
	db $A4
	db $B2
	db $E2
	db $01
	db $C7
	db $E9, $E1
	db $F3, $01
	db $F6, $03
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
	db $02
	db $F3, $03
	db $F6, $06
	db $EE, $04
	db $FB
	db $E3
	db $C2
	db $01
	db $01
	db $01
	db $01
	db $C2
	db $03
	db $01
	db $C4
	db $FD, $05
	db $E3
	db $C2
	db $21
	db $21
	db $21
	db $21
	db $C2
	db $23
	db $21
	db $C4
	db $E3
	db $C2
	db $21
	db $21
	db $21
	db $21
	db $C2
	db $22
	db $EE, $04
	db $E2
	db $52
	db $32
	db $0A
	db $C2
	db $02
	db $72
	db $52
	db $3C
	db $22
	db $02
	db $E1
	db $A4
	db $84
	db $72
	db $E2
	db $54
	db $3A
	db $C2
	db $02
	db $02
	db $2A
	db $C2
	db $22
	db $02
	db $3A
	db $C2
	db $22
	db $32
	db $5A
	db $C2
	db $02
	db $22
	db $20
	db $C2
	db $E8, $16
	db $72
	db $21
	db $C1
	db $A2
	db $71
	db $C5
	db $E8, $0B
	db $31
	db $71
	db $81
	db $A1
	db $EE, $04
	db $FB
	db $E2
	db $31
	db $71
	db $A1
	db $E3
	db $01
	db $FD, $1F
	db $FB
	db $E2
	db $01
	db $31
	db $71
	db $A1
	db $FD, $07
	db $FE, $00
	db $FF

Audio1_Mus_CutsceneC:
	db $D6, $01, $86, $B0
	db $C2
	db $EC, $03
	db $FC
	db $FB
	db $E1
	db $73
	db $A1
	db $C2
	db $E2
	db $02
	db $C2
	db $E1
	db $72
	db $A2
	db $E2
	db $02
	db $FD, $03
	db $E1
	db $A1
	db $A1
	db $C4
	db $A1
	db $A1
	db $C2
	db $A4
	db $B2
	db $E2
	db $02
	db $CE
	db $FB
	db $E1
	db $73
	db $A1
	db $C2
	db $E2
	db $02
	db $C2
	db $E1
	db $72
	db $A2
	db $E2
	db $02
	db $FD, $01
	db $FB
	db $E2
	db $03
	db $31
	db $C2
	db $52
	db $C2
	db $02
	db $32
	db $52
	db $FD, $03
	db $E2
	db $23
	db $51
	db $C2
	db $72
	db $C2
	db $22
	db $52
	db $72
	db $23
	db $51
	db $C2
	db $72
	db $C2
	db $E2
	db $02
	db $E1
	db $A2
	db $84
	db $52
	db $82
	db $52
	db $32
	db $A2
	db $82
	db $74
	db $32
	db $72
	db $32
	db $22
	db $32
	db $32
	db $52
	db $72
	db $72
	db $E2
	db $22
	db $22
	db $E1
	db $72
	db $A2
	db $A2
	db $E2
	db $04
	db $02
	db $E1
	db $A2
	db $E2
	db $02
	db $32
	db $22
	db $02
	db $24
	db $22
	db $02
	db $22
	db $22
	db $52
	db $32
	db $04
	db $02
	db $E1
	db $A2
	db $E2
	db $02
	db $02
	db $32
	db $02
	db $E1
	db $A4
	db $A2
	db $82
	db $A2
	db $A2
	db $E2
	db $22
	db $E1
	db $A2
	db $74
	db $72
	db $52
	db $72
	db $72
	db $A2
	db $72
	db $72
	db $A2
	db $52
	db $E2
	db $22
	db $E1
	db $A2
	db $C8
	db $FB
	db $F7
	dw Audio1_Mus_CutsceneC_1
	db $FD, $07
	db $FB
	db $E1
	db $73
	db $A1
	db $C2
	db $E2
	db $02
	db $C2
	db $E1
	db $72
	db $A2
	db $E2
	db $02
	db $FD, $01
	db $FE, $00
	db $FF

Audio1_Mus_CutsceneC_1:
	db $E2
	db $02
	db $E1
	db $72
	db $A2
	db $52
	db $32
	db $72
	db $A2
	db $E2
	db $02
	db $F9

Audio1_Mus_CutsceneD:
	db $D6
	db $C2
	db $FC
	db $FB
	db $32
	db $11
	db $11
	db $FD, $0F
	db $31
	db $31
	db $C4
	db $31
	db $31
	db $C2
	db $34
	db $32
	db $32
	db $C6
	db $61
	db $61
	db $71
	db $71
	db $81
	db $81
	db $81
	db $81
	db $FB
	db $32
	db $11
	db $11
	db $FD, $1D
	db $11
	db $11
	db $32
	db $32
	db $22
	db $FB
	db $31
	db $11
	db $22
	db $FD, $1F
	db $32
	db $32
	db $32
	db $32
	db $C4
	db $61
	db $61
	db $71
	db $71
	db $FB
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FD, $0F
	db $FB
	db $32
	db $11
	db $11
	db $FD, $07
	db $FE, $00
	db $FF

Audio1_Mus_MarsB:
	db $D6, $11, $B1, $52, $AB, $26, $B5
	db $C2
	db $EF, $02
	db $EC, $FA
	db $FC
	db $E8, $15
	db $FB
	db $E3
	db $02
	db $E2
	db $C8
	db $A2
	db $C2
	db $E3
	db $02
	db $E2
	db $CA
	db $A2
	db $C2
	db $E3
	db $02
	db $FD, $01
	db $FB
	db $E9, $B1
	db $E3
	db $72
	db $C4
	db $7A
	db $E9, $91
	db $C2
	db $02
	db $32
	db $02
	db $52
	db $32
	db $52
	db $72
	db $E9, $B1
	db $E3
	db $52
	db $C4
	db $5A
	db $E9, $91
	db $C2
	db $02
	db $22
	db $02
	db $32
	db $22
	db $32
	db $52
	db $E9, $B1
	db $E3
	db $32
	db $C4
	db $3A
	db $E9, $91
	db $E2
	db $C2
	db $A2
	db $E3
	db $02
	db $E2
	db $A2
	db $E3
	db $22
	db $02
	db $22
	db $32
	db $E9, $B1
	db $E3
	db $22
	db $C4
	db $2A
	db $E9, $91
	db $E2
	db $C2
	db $72
	db $A2
	db $72
	db $E3
	db $02
	db $E2
	db $A2
	db $E3
	db $02
	db $22
	db $FD, $01
	db $FB
	db $E9, $B1
	db $E3
	db $02
	db $E2
	db $C8
	db $A2
	db $C2
	db $E3
	db $02
	db $E2
	db $CA
	db $A2
	db $C2
	db $E3
	db $02
	db $FD, $01
	db $E3
	db $32
	db $C4
	db $36
	db $52
	db $72
	db $71
	db $81
	db $71
	db $51
	db $51
	db $71
	db $51
	db $31
	db $31
	db $51
	db $31
	db $21
	db $04
	db $01
	db $22
	db $31
	db $52
	db $22
	db $28
	db $28
	db $E2
	db $A1
	db $E3
	db $01
	db $22
	db $C2
	db $02
	db $E2
	db $71
	db $82
	db $A3
	db $E3
	db $02
	db $E2
	db $81
	db $A2
	db $E3
	db $03
	db $22
	db $E4
	db $06
	db $E3
	db $A1
	db $E4
	db $01
	db $E3
	db $A1
	db $E4
	db $01
	db $E3
	db $A1
	db $81
	db $71
	db $81
	db $71
	db $51
	db $51
	db $71
	db $51
	db $31
	db $21
	db $31
	db $21
	db $01
	db $28
	db $20
	db $E2
	db $A1
	db $E3
	db $07
	db $22
	db $36
	db $51
	db $72
	db $51
	db $C1
	db $73
	db $38
	db $E3
	db $C2
	db $01
	db $25
	db $32
	db $56
	db $81
	db $A2
	db $81
	db $C1
	db $53
	db $A8
	db $E3
	db $C2
	db $32
	db $34
	db $52
	db $76
	db $71
	db $82
	db $71
	db $C1
	db $33
	db $88
	db $51
	db $7F
	db $51
	db $77
	db $A8
	db $FE, $00
	db $FF

Audio1_Mus_MarsA:
	db $D6, $11, $61, $52, $AB, $26, $B5
	db $C2
	db $EF, $01
	db $EC, $FA
	db $E8, $0B
	db $FC
	db $EE, $06
	db $E9, $81
	db $FB
	db $E2
	db $72
	db $C8
	db $32
	db $C2
	db $72
	db $CA
	db $32
	db $C2
	db $72
	db $FD, $01
	db $FB
	db $EE, $05
	db $E9, $71
	db $E3
	db $02
	db $C4
	db $0A
	db $00
	db $E2
	db $A2
	db $C4
	db $AA
	db $E3
	db $50
	db $E2
	db $82
	db $C4
	db $8A
	db $E3
	db $30
	db $E2
	db $72
	db $C4
	db $7A
	db $E3
	db $20
	db $FD, $01
	db $EE, $06
	db $E9, $81
	db $FB
	db $E2
	db $72
	db $C8
	db $32
	db $C2
	db $72
	db $CA
	db $32
	db $C2
	db $72
	db $FD, $01
	db $FB
	db $EE, $05
	db $E9, $71
	db $E3
	db $32
	db $C4
	db $3A
	db $30
	db $E3
	db $22
	db $C4
	db $2A
	db $50
	db $E3
	db $02
	db $C4
	db $0A
	db $30
	db $E2
	db $A2
	db $C4
	db $AA
	db $E3
	db $20
	db $FD, $01
	db $FE, $00
	db $FF

Audio1_Mus_MarsC:
	db $D6, $01, $86, $B0
	db $C2
	db $EC, $06
	db $FC
	db $FB
	db $E2
	db $02
	db $E1
	db $72
	db $A2
	db $E2
	db $02
	db $32
	db $02
	db $32
	db $72
	db $FD, $03
	db $FB
	db $E2
	db $02
	db $E1
	db $72
	db $A2
	db $E2
	db $02
	db $32
	db $02
	db $32
	db $72
	db $E2
	db $02
	db $E1
	db $72
	db $A2
	db $E2
	db $02
	db $32
	db $02
	db $32
	db $72
	db $E1
	db $A2
	db $52
	db $82
	db $A2
	db $E2
	db $22
	db $E1
	db $A2
	db $E2
	db $22
	db $52
	db $E1
	db $A2
	db $52
	db $82
	db $A2
	db $E2
	db $22
	db $E1
	db $A2
	db $E2
	db $22
	db $52
	db $E1
	db $82
	db $32
	db $52
	db $82
	db $E2
	db $02
	db $E1
	db $82
	db $E2
	db $02
	db $32
	db $E1
	db $82
	db $32
	db $52
	db $82
	db $E2
	db $02
	db $E1
	db $82
	db $E2
	db $02
	db $32
	db $E1
	db $72
	db $22
	db $52
	db $72
	db $A2
	db $52
	db $A2
	db $E2
	db $22
	db $E1
	db $72
	db $22
	db $52
	db $72
	db $A2
	db $52
	db $A2
	db $E2
	db $22
	db $FD, $01
	db $FE, $00
	db $FF

Audio1_Mus_MarsD:
	db $D6
	db $C2
	db $F7
	dw Audio1_Mus_MarsD_1
	db $FC
	db $FB
	db $32
	db $11
	db $11
	db $FD, $3E
	db $31
	db $31
	db $31
	db $31
	db $F7
	dw Audio1_Mus_MarsD_1
	db $FB
	db $32
	db $11
	db $11
	db $FD, $3F
	db $FB
	db $31
	db $31
	db $31
	db $31
	db $61
	db $61
	db $61
	db $61
	db $71
	db $71
	db $71
	db $71
	db $81
	db $81
	db $82
	db $61
	db $61
	db $81
	db $81
	db $61
	db $61
	db $81
	db $81
	db $61
	db $61
	db $81
	db $81
	db $32
	db $31
	db $31
	db $FD, $01
	db $FE, $00
	db $FF

Audio1_Mus_MarsD_1:
	db $FB
	db $52
	db $11
	db $11
	db $22
	db $31
	db $11
	db $52
	db $11
	db $11
	db $52
	db $FD, $03
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $F9

Audio1_Mus_JupiterB:
	db $D6, $22, $B1, $52, $AB, $26, $B5
	db $C3
	db $EC, $02
	db $EF, $02
	db $E8, $22
	db $C0
	db $C0
	db $C0
	db $C0
	db $FC
	db $E8, $11
	db $E9, $11
	db $FB
	db $E2
	db $02
	db $02
	db $E1
	db $73
	db $A3
	db $A2
	db $E2
	db $02
	db $22
	db $FD, $01
	db $E9, $B1
	db $F7
	dw Audio1_Mus_JupiterB_1
	db $5C
	db $23
	db $29
	db $E8, $11
	db $E2
	db $92
	db $72
	db $91
	db $73
	db $F7
	dw Audio1_Mus_JupiterB_1
	db $5C
	db $C2
	db $7E
	db $E8, $21
	db $E2
	db $41
	db $71
	db $91
	db $B1
	db $F8
	dw Audio1_Mus_JupiterB_2
	db $E3
	db $09
	db $E8, $11
	db $E2
	db $74
	db $91
	db $B3
	db $F8
	dw Audio1_Mus_JupiterB_2
	db $E3
	db $09
	db $28
	db $FE, $00
	db $FF

Audio1_Mus_JupiterB_1:
	db $E8, $22
	db $E2
	db $21
	db $45
	db $4A
	db $C2
	db $42
	db $51
	db $73
	db $52
	db $42
	db $C2
	db $22
	db $4E
	db $47
	db $E9, $81
	db $E8, $11
	db $01
	db $21
	db $03
	db $41
	db $51
	db $71
	db $91
	db $A2
	db $E9, $B1
	db $E8, $22
	db $E2
	db $51
	db $41
	db $54
	db $5A
	db $C2
	db $52
	db $71
	db $93
	db $72
	db $54
	db $42
	db $F9

Audio1_Mus_JupiterB_2:
	db $E9, $B1
	db $E8, $21
	db $E3
	db $0C
	db $E2
	db $41
	db $72
	db $B9
	db $E8, $11
	db $E9, $41
	db $E2
	db $21
	db $41
	db $21
	db $01
	db $E1
	db $B1
	db $E2
	db $01
	db $E1
	db $B1
	db $91
	db $E8, $21
	db $E9, $B1
	db $E3
	db $2C
	db $E2
	db $71
	db $92
	db $FA

Audio1_Mus_JupiterA:
	db $D6, $11, $71, $51, $AB, $26, $B5
	db $C3
	db $EC, $02
	db $EF, $01
	db $E9, $51
	db $EE, $06
	db $E8, $11
	db $C0
	db $C0
	db $C0
	db $C0
	db $FC
	db $EE, $03
	db $E9, $31
	db $E8, $11
	db $FB
	db $E2
	db $A1
	db $E3
	db $01
	db $41
	db $71
	db $FD, $15
	db $EE, $04
	db $E2
	db $A1
	db $E3
	db $01
	db $01
	db $21
	db $41
	db $51
	db $72
	db $EE, $03
	db $FB
	db $E3
	db $01
	db $21
	db $51
	db $91
	db $FD, $0B
	db $FB
	db $E2
	db $91
	db $B1
	db $E3
	db $21
	db $51
	db $FD, $01
	db $EE, $04
	db $52
	db $42
	db $51
	db $43
	db $EE, $03
	db $FB
	db $E2
	db $A1
	db $E3
	db $01
	db $41
	db $71
	db $FD, $0D
	db $E2
	db $A1
	db $E3
	db $01
	db $01
	db $21
	db $41
	db $51
	db $72
	db $FB
	db $E3
	db $01
	db $21
	db $51
	db $91
	db $FD, $0B
	db $FB
	db $E3
	db $21
	db $41
	db $71
	db $B1
	db $FD, $02
	db $E8, $22
	db $EE, $04
	db $E2
	db $41
	db $71
	db $91
	db $B1
	db $E2
	db $78
	db $47
	db $58
	db $B8
	db $51
	db $98
	db $57
	db $79
	db $42
	db $42
	db $51
	db $73
	db $E2
	db $78
	db $47
	db $58
	db $B8
	db $51
	db $98
	db $57
	db $70
	db $71
	db $FE, $00
	db $FF

Audio1_Mus_JupiterC:
	db $D6, $01, $86, $B0
	db $C3
	db $EC, $02
	db $C0
	db $CC
	db $F6, $03
	db $E3
	db $02
	db $E2
	db $91
	db $71
	db $51
	db $41
	db $21
	db $01
	db $F6, $06
	db $FB
	db $E2
	db $02
	db $02
	db $E1
	db $73
	db $A3
	db $A2
	db $E2
	db $02
	db $22
	db $FD, $01
	db $FC
	db $FB
	db $E2
	db $02
	db $02
	db $E1
	db $73
	db $A3
	db $A2
	db $E2
	db $02
	db $22
	db $FD, $01
	db $F7
	dw Audio1_Mus_JupiterC_1
	db $E1
	db $B2
	db $B2
	db $53
	db $93
	db $92
	db $B2
	db $E2
	db $02
	db $F7
	dw Audio1_Mus_JupiterC_1
	db $E2
	db $42
	db $42
	db $E1
	db $B3
	db $E2
	db $23
	db $22
	db $42
	db $52
	db $FB
	db $E2
	db $02
	db $01
	db $01
	db $02
	db $01
	db $01
	db $02
	db $01
	db $01
	db $02
	db $01
	db $E1
	db $B3
	db $B1
	db $B1
	db $B2
	db $B1
	db $B1
	db $B2
	db $B1
	db $B1
	db $B2
	db $B1
	db $B1
	db $E1
	db $92
	db $91
	db $91
	db $92
	db $91
	db $91
	db $92
	db $91
	db $91
	db $92
	db $91
	db $E1
	db $73
	db $71
	db $71
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $FD, $01
	db $FE, $00
	db $FF

Audio1_Mus_JupiterC_1:
	db $FB
	db $E2
	db $02
	db $02
	db $E1
	db $73
	db $A3
	db $A2
	db $E2
	db $02
	db $22
	db $FD, $03
	db $FB
	db $E2
	db $22
	db $22
	db $E1
	db $93
	db $E2
	db $03
	db $02
	db $22
	db $42
	db $FD, $02
	db $F9

Audio1_Mus_JupiterD:
	db $D6
	db $C3
	db $12
	db $12
	db $32
	db $11
	db $31
	db $12
	db $12
	db $32
	db $22
	db $12
	db $12
	db $32
	db $11
	db $31
	db $12
	db $12
	db $32
	db $31
	db $31
	db $12
	db $12
	db $32
	db $11
	db $31
	db $12
	db $12
	db $32
	db $22
	db $12
	db $12
	db $32
	db $11
	db $31
	db $12
	db $12
	db $31
	db $31
	db $31
	db $31
	db $FC
	db $24
	db $32
	db $11
	db $31
	db $12
	db $12
	db $32
	db $22
	db $FB
	db $12
	db $12
	db $32
	db $11
	db $31
	db $12
	db $12
	db $32
	db $22
	db $FD, $07
	db $12
	db $12
	db $32
	db $11
	db $31
	db $32
	db $32
	db $31
	db $33
	db $24
	db $32
	db $11
	db $31
	db $12
	db $12
	db $32
	db $22
	db $FB
	db $12
	db $12
	db $32
	db $11
	db $31
	db $12
	db $12
	db $32
	db $22
	db $FD, $05
	db $12
	db $12
	db $32
	db $11
	db $31
	db $12
	db $12
	db $31
	db $31
	db $31
	db $31
	db $FB
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FD, $06
	db $32
	db $32
	db $31
	db $23
	db $FB
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FD, $06
	db $12
	db $11
	db $11
	db $31
	db $31
	db $31
	db $31
	db $FE, $00
	db $FF

Audio1_Mus_VenusAltB:
	db $D6, $22, $B1, $52, $AB, $26, $B5
	db $C2
	db $EC, $05
	db $EF, $02
	db $C8
	db $FC
	db $E8, $11
	db $FB
	db $E1
	db $74
	db $A4
	db $E2
	db $08
	db $C2
	db $E1
	db $A2
	db $E2
	db $02
	db $22
	db $02
	db $E1
	db $A2
	db $72
	db $A2
	db $FD, $01
	db $E9, $81
	db $FB
	db $E2
	db $03
	db $03
	db $E1
	db $A4
	db $72
	db $A1
	db $E2
	db $03
	db $FD, $03
	db $E8, $22
	db $E9, $B1
	db $FB
	db $E1
	db $A1
	db $E2
	db $0B
	db $04
	db $E1
	db $81
	db $AB
	db $71
	db $A3
	db $FD, $03
	db $E8, $11
	db $FB
	db $E1
	db $03
	db $03
	db $33
	db $33
	db $54
	db $FD, $03
	db $FE, $00
	db $FF

Audio1_Mus_VenusAltA:
	db $D6, $11, $71, $51, $AB, $26, $B5
	db $C2
	db $EC, $05
	db $EF, $01
	db $C8
	db $FC
	db $E9, $51
	db $EE, $06
	db $E8, $22
	db $FB
	db $E1
	db $C1
	db $74
	db $A4
	db $E2
	db $08
	db $C2
	db $E1
	db $A2
	db $E2
	db $02
	db $22
	db $02
	db $E1
	db $A2
	db $72
	db $A1
	db $FD, $01
	db $EE, $03
	db $E9, $31
	db $E8, $11
	db $FB
	db $E3
	db $01
	db $41
	db $71
	db $01
	db $41
	db $71
	db $01
	db $41
	db $71
	db $01
	db $41
	db $71
	db $01
	db $41
	db $71
	db $41
	db $FD, $0B
	db $FB
	db $E3
	db $21
	db $51
	db $71
	db $21
	db $51
	db $71
	db $21
	db $51
	db $71
	db $21
	db $51
	db $71
	db $21
	db $51
	db $71
	db $51
	db $FD, $03
	db $FE, $00
	db $FF

Audio1_Mus_VenusAltC:
	db $D6, $01, $86, $B0
	db $C2
	db $C8
	db $EC, $05
	db $FC
	db $FB
	db $E1
	db $74
	db $A4
	db $E2
	db $08
	db $C2
	db $E1
	db $A2
	db $E2
	db $02
	db $22
	db $02
	db $E1
	db $A2
	db $72
	db $A2
	db $FD, $01
	db $FB
	db $E2
	db $03
	db $03
	db $E1
	db $A4
	db $72
	db $A1
	db $E2
	db $03
	db $FD, $0B
	db $FB
	db $E1
	db $73
	db $73
	db $A3
	db $A3
	db $E2
	db $01
	db $03
	db $FD, $03
	db $FE, $00
	db $FF

Audio1_Mus_VenusAltD:
	db $D6
	db $C2
	db $61
	db $61
	db $61
	db $61
	db $71
	db $71
	db $71
	db $71
	db $FC
	db $24
	db $FB
	db $14
	db $FD, $0C
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $24
	db $32
	db $11
	db $11
	db $11
	db $11
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FB
	db $11
	db $11
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FD, $1C
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

Audio1_Mus_PlutoB:
	db $D6, $22, $B1, $52, $AB, $26, $B5
	db $C3
	db $EC, $04
	db $EF, $02
	db $E8, $11
	db $FB
	db $E2
	db $02
	db $32
	db $71
	db $32
	db $E3
	db $09
	db $FD, $03
	db $FC
	db $F7
	dw Audio1_Mus_PlutoB_1
	db $E2
	db $24
	db $7C
	db $E9, $11
	db $E8, $11
	db $31
	db $51
	db $71
	db $81
	db $51
	db $71
	db $81
	db $A1
	db $E2
	db $A1
	db $E3
	db $21
	db $01
	db $E2
	db $A1
	db $E3
	db $01
	db $E2
	db $A1
	db $81
	db $71
	db $E9, $B1
	db $E8, $22
	db $F7
	dw Audio1_Mus_PlutoB_1
	db $E2
	db $24
	db $7C
	db $E9, $81
	db $E8, $21
	db $C2
	db $72
	db $C1
	db $53
	db $71
	db $71
	db $C2
	db $E9, $B1
	db $E8, $22
	db $31
	db $71
	db $81
	db $A1
	db $F8
	dw Audio1_Mus_PlutoB_2
	db $70
	db $C2
	db $E9, $91
	db $E2
	db $71
	db $81
	db $71
	db $51
	db $31
	db $51
	db $31
	db $21
	db $01
	db $21
	db $01
	db $E1
	db $A1
	db $E9, $B1
	db $E8, $22
	db $E2
	db $31
	db $71
	db $81
	db $A1
	db $F8
	dw Audio1_Mus_PlutoB_2
	db $70
	db $C2
	db $51
	db $77
	db $E9, $81
	db $E8, $11
	db $E2
	db $71
	db $81
	db $A1
	db $E3
	db $01
	db $E2
	db $71
	db $81
	db $A1
	db $E3
	db $01
	db $FE, $00
	db $FF

Audio1_Mus_PlutoB_1:
	db $E9, $C1
	db $E8, $22
	db $E2
	db $21
	db $37
	db $E1
	db $72
	db $E2
	db $02
	db $22
	db $3A
	db $31
	db $52
	db $33
	db $22
	db $28
	db $E1
	db $52
	db $A2
	db $E2
	db $02
	db $20
	db $C2
	db $E2
	db $21
	db $37
	db $E1
	db $72
	db $E2
	db $02
	db $22
	db $3A
	db $31
	db $52
	db $33
	db $22
	db $F9

Audio1_Mus_PlutoB_2:
	db $E9, $B1
	db $E8, $21
	db $E3
	db $08
	db $E2
	db $A2
	db $A4
	db $8A
	db $72
	db $56
	db $A4
	db $A4
	db $52
	db $84
	db $7E
	db $E1
	db $A1
	db $E2
	db $31
	db $51
	db $71
	db $86
	db $74
	db $72
	db $C2
	db $5A
	db $32
	db $22
	db $32
	db $FA

Audio1_Mus_PlutoA:
	db $D6, $11, $71, $51, $AB, $26, $B5
	db $C3
	db $EC, $04
	db $EF, $01
	db $EE, $04
	db $E8, $21
	db $E2
	db $7C
	db $21
	db $31
	db $72
	db $5C
	db $01
	db $21
	db $52
	db $3C
	db $E1
	db $A1
	db $E2
	db $01
	db $32
	db $3C
	db $21
	db $31
	db $72
	db $FC
	db $E8, $11
	db $F7
	dw Audio1_Mus_PlutoA_1
	db $78
	db $A8
	db $F7
	dw Audio1_Mus_PlutoA_1
	db $E8, $22
	db $C2
	db $22
	db $C1
	db $03
	db $21
	db $21
	db $C2
	db $31
	db $71
	db $81
	db $A1
	db $F8
	dw Audio1_Mus_PlutoA_2
	db $20
	db $C2
	db $E8, $11
	db $EE, $05
	db $51
	db $7B
	db $81
	db $A1
	db $E2
	db $01
	db $21
	db $EE, $04
	db $F8
	dw Audio1_Mus_PlutoA_2
	db $00
	db $C2
	db $00
	db $FE, $00
	db $FF

Audio1_Mus_PlutoA_1:
	db $EE, $04
	db $FB
	db $E2
	db $02
	db $31
	db $71
	db $FD, $07
	db $FB
	db $E1
	db $A2
	db $E2
	db $21
	db $51
	db $FD, $07
	db $FB
	db $E2
	db $02
	db $31
	db $81
	db $FD, $07
	db $FB
	db $E1
	db $A2
	db $E2
	db $21
	db $71
	db $FD, $03
	db $F9

Audio1_Mus_PlutoA_2:
	db $E8, $21
	db $E2
	db $78
	db $72
	db $74
	db $5A
	db $38
	db $74
	db $74
	db $22
	db $54
	db $3A
	db $E1
	db $A1
	db $E2
	db $31
	db $51
	db $71
	db $E1
	db $A1
	db $E2
	db $31
	db $51
	db $71
	db $56
	db $34
	db $32
	db $C2
	db $20
	db $FA

Audio1_Mus_PlutoC:
	db $D6, $01, $86, $B0
	db $C3
	db $EC, $04
	db $E2
	db $00
	db $E1
	db $A0
	db $80
	db $70
	db $FC
	db $F7
	dw Audio1_Mus_PlutoC_1
	db $E1
	db $82
	db $81
	db $81
	db $82
	db $81
	db $81
	db $A2
	db $A1
	db $A1
	db $A2
	db $A1
	db $A1
	db $F7
	dw Audio1_Mus_PlutoC_1
	db $A2
	db $A1
	db $A1
	db $A1
	db $83
	db $A1
	db $A3
	db $C4
	db $F8
	dw Audio1_Mus_PlutoC_2
	db $FB
	db $72
	db $FD, $0F
	db $F8
	dw Audio1_Mus_PlutoC_2
	db $FB
	db $72
	db $FD, $0F
	db $FE, $00
	db $FF

Audio1_Mus_PlutoC_1:
	db $FB
	db $E2
	db $02
	db $01
	db $01
	db $FD, $07
	db $FB
	db $E1
	db $A2
	db $A1
	db $A1
	db $FD, $07
	db $FB
	db $E1
	db $82
	db $81
	db $81
	db $FD, $07
	db $FB
	db $E1
	db $72
	db $71
	db $71
	db $FD, $03
	db $F9

Audio1_Mus_PlutoC_2:
	db $E2
	db $32
	db $32
	db $32
	db $24
	db $22
	db $22
	db $04
	db $02
	db $02
	db $02
	db $E1
	db $A2
	db $A2
	db $E2
	db $02
	db $02
	db $22
	db $22
	db $22
	db $04
	db $02
	db $02
	db $E1
	db $A4
	db $A2
	db $A2
	db $A2
	db $A2
	db $E2
	db $A2
	db $E1
	db $A2
	db $E2
	db $A2
	db $E2
	db $02
	db $02
	db $02
	db $E1
	db $A4
	db $A2
	db $A2
	db $84
	db $82
	db $82
	db $82
	db $82
	db $82
	db $82
	db $82
	db $FA

Audio1_Mus_PlutoD:
	db $D6
	db $C3
	db $FB
	db $24
	db $14
	db $14
	db $14
	db $FD, $01
	db $FB
	db $54
	db $FD, $05
	db $61
	db $61
	db $61
	db $61
	db $71
	db $71
	db $71
	db $71
	db $FC
	db $F7
	dw Audio1_Mus_PlutoD_1
	db $32
	db $11
	db $11
	db $32
	db $11
	db $11
	db $32
	db $11
	db $11
	db $31
	db $31
	db $31
	db $31
	db $F7
	dw Audio1_Mus_PlutoD_1
	db $32
	db $32
	db $C1
	db $33
	db $31
	db $31
	db $C2
	db $61
	db $61
	db $61
	db $61
	db $F8
	dw Audio1_Mus_PlutoD_2
	db $52
	db $11
	db $11
	db $32
	db $11
	db $11
	db $52
	db $52
	db $31
	db $31
	db $31
	db $31
	db $F8
	dw Audio1_Mus_PlutoD_2
	db $52
	db $11
	db $11
	db $32
	db $11
	db $11
	db $31
	db $31
	db $31
	db $31
	db $71
	db $71
	db $71
	db $71
	db $FE, $00
	db $FF

Audio1_Mus_PlutoD_1:
	db $24
	db $FB
	db $32
	db $11
	db $11
	db $FD, $1A
	db $F9

Audio1_Mus_PlutoD_2:
	db $24
	db $32
	db $11
	db $11
	db $52
	db $52
	db $32
	db $11
	db $11
	db $FB
	db $52
	db $11
	db $11
	db $32
	db $11
	db $11
	db $52
	db $52
	db $32
	db $11
	db $11
	db $FD, $05
	db $FA

Audio1_Mus_WilyB:
	db $D6, $10, $81, $00, $88, $22, $85
	db $EF, $01
	db $E1
	db $96
	db $96
	db $96
	db $96
	db $92
	db $92
	db $94
	db $96
	db $96
	db $92
	db $94
	db $96
	db $92
	db $92
	db $94
	db $D6, $11, $B1, $25, $8B, $35, $A6
	db $EF, $00
	db $FC
	db $FB
	db $E1
	db $46
	db $E2
	db $04
	db $E1
	db $92
	db $B2
	db $E2
	db $0E
	db $44
	db $3E
	db $E1
	db $8E
	db $C4
	db $E1
	db $46
	db $E2
	db $04
	db $E1
	db $92
	db $B2
	db $E2
	db $0E
	db $44
	db $3E
	db $9E
	db $C4
	db $FD, $01
	db $E2
	db $86
	db $44
	db $82
	db $92
	db $BE
	db $E3
	db $24
	db $06
	db $E2
	db $44
	db $92
	db $B2
	db $E3
	db $0E
	db $44
	db $26
	db $E2
	db $A4
	db $E3
	db $22
	db $42
	db $5A
	db $74
	db $54
	db $C2
	db $42
	db $22
	db $02
	db $E2
	db $B2
	db $92
	db $C2
	db $E3
	db $02
	db $E2
	db $B2
	db $92
	db $82
	db $42
	db $C2
	db $E3
	db $42
	db $42
	db $EE, $0A
	db $F6, $01
	db $31
	db $21
	db $11
	db $01
	db $E2
	db $B1
	db $A1
	db $91
	db $81
	db $71
	db $61
	db $51
	db $41
	db $F3, $03
	db $D6, $12, $91, $25, $89, $34, $A6
	db $FB
	db $E3
	db $02
	db $E2
	db $41
	db $52
	db $41
	db $E3
	db $42
	db $FD, $03
	db $FB
	db $E2
	db $B2
	db $41
	db $52
	db $41
	db $E3
	db $42
	db $FD, $03
	db $FB
	db $E2
	db $A2
	db $41
	db $52
	db $41
	db $E3
	db $42
	db $FD, $03
	db $4C
	db $52
	db $2E
	db $C4
	db $D6, $11, $B1, $25, $8B, $35, $A6
	db $E2
	db $A3
	db $E3
	db $23
	db $42
	db $58
	db $E2
	db $93
	db $E3
	db $23
	db $42
	db $58
	db $E2
	db $83
	db $E3
	db $23
	db $42
	db $58
	db $44
	db $24
	db $14
	db $E2
	db $94
	db $E2
	db $A3
	db $E3
	db $23
	db $42
	db $58
	db $E2
	db $93
	db $E3
	db $23
	db $42
	db $52
	db $C2
	db $54
	db $36
	db $E2
	db $A6
	db $74
	db $E3
	db $2C
	db $C4
	db $FE, $00

Audio1_Mus_WilyA:
	db $D6, $10, $61, $00, $86, $12, $85
	db $E2
	db $46
	db $46
	db $46
	db $46
	db $42
	db $42
	db $44
	db $46
	db $46
	db $42
	db $44
	db $46
	db $42
	db $42
	db $44
	db $D6, $10, $A1, $25, $8A, $34, $A7
	db $FC
	db $FB
	db $E1
	db $06
	db $94
	db $42
	db $82
	db $92
	db $46
	db $96
	db $E2
	db $04
	db $E1
	db $BE
	db $4E
	db $C4
	db $E1
	db $06
	db $74
	db $42
	db $72
	db $72
	db $46
	db $76
	db $E2
	db $04
	db $0E
	db $5E
	db $C4
	db $FD, $01
	db $E2
	db $46
	db $E1
	db $B4
	db $E2
	db $42
	db $62
	db $8E
	db $B4
	db $96
	db $04
	db $42
	db $82
	db $9E
	db $E3
	db $04
	db $E2
	db $A6
	db $54
	db $A2
	db $E3
	db $02
	db $2A
	db $E2
	db $A4
	db $A4
	db $C2
	db $E3
	db $02
	db $E2
	db $B2
	db $92
	db $82
	db $52
	db $C2
	db $92
	db $82
	db $52
	db $42
	db $E1
	db $B2
	db $C2
	db $E2
	db $B2
	db $B2
	db $EE, $09
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
	db $D6, $22, $81, $25, $88, $33, $A7
	db $C1
	db $F3, $00
	db $EF, $01
	db $FB
	db $E3
	db $02
	db $E2
	db $41
	db $52
	db $41
	db $E3
	db $42
	db $FD, $03
	db $FB
	db $E2
	db $B2
	db $41
	db $52
	db $41
	db $E3
	db $42
	db $FD, $03
	db $FB
	db $E2
	db $A2
	db $41
	db $52
	db $41
	db $E3
	db $42
	db $FD, $03
	db $C1
	db $F3, $03
	db $4C
	db $52
	db $2E
	db $EF, $00
	db $C2
	db $D6, $10, $A1, $25, $8A, $34, $A7
	db $E2
	db $58
	db $A8
	db $E2
	db $48
	db $98
	db $E2
	db $38
	db $88
	db $E3
	db $18
	db $E2
	db $94
	db $44
	db $E2
	db $58
	db $A8
	db $E2
	db $28
	db $52
	db $C2
	db $24
	db $E2
	db $A6
	db $76
	db $34
	db $9C
	db $C4
	db $FE, $00

Audio1_Mus_WilyC:
	db $D6, $05, $84, $80
	db $E1
	db $96
	db $96
	db $96
	db $96
	db $92
	db $92
	db $94
	db $96
	db $96
	db $92
	db $94
	db $96
	db $92
	db $92
	db $94
	db $FC
	db $FB
	db $E1
	db $96
	db $96
	db $96
	db $96
	db $92
	db $92
	db $94
	db $86
	db $86
	db $82
	db $84
	db $86
	db $82
	db $82
	db $84
	db $76
	db $76
	db $76
	db $76
	db $72
	db $72
	db $74
	db $56
	db $56
	db $52
	db $54
	db $56
	db $52
	db $54
	db $52
	db $FD, $01
	db $FB
	db $42
	db $FD, $0F
	db $FB
	db $92
	db $FD, $0F
	db $FB
	db $A2
	db $FD, $0F
	db $42
	db $CA
	db $42
	db $E2
	db $02
	db $E1
	db $B2
	db $92
	db $82
	db $42
	db $C2
	db $42
	db $42
	db $42
	db $FB
	db $92
	db $FD, $0F
	db $FB
	db $82
	db $FD, $0F
	db $FB
	db $72
	db $FD, $0F
	db $FB
	db $52
	db $FD, $0F
	db $FB
	db $A2
	db $A1
	db $A1
	db $FD, $03
	db $FB
	db $92
	db $91
	db $91
	db $FD, $03
	db $FB
	db $82
	db $81
	db $81
	db $FD, $03
	db $FB
	db $92
	db $91
	db $91
	db $FD, $03
	db $FB
	db $A2
	db $A1
	db $A1
	db $FD, $03
	db $FB
	db $92
	db $91
	db $91
	db $FD, $03
	db $FB
	db $32
	db $31
	db $31
	db $FD, $03
	db $22
	db $21
	db $21
	db $22
	db $24
	db $24
	db $22
	db $FE, $00

Audio1_Mus_WilyD:
	db $D6
	db $26
	db $12
	db $34
	db $26
	db $12
	db $34
	db $12
	db $12
	db $34
	db $26
	db $12
	db $34
	db $12
	db $24
	db $12
	db $34
	db $12
	db $12
	db $34
	db $FC
	db $F7
	dw Audio1_Mus_WilyD_1
	db $F7
	dw Audio1_Mus_WilyD_1
	db $FB
	db $12
	db $12
	db $32
	db $24
	db $22
	db $32
	db $12
	db $FD, $04
	db $12
	db $12
	db $32
	db $24
	db $22
	db $32
	db $32
	db $52
	db $32
	db $32
	db $32
	db $32
	db $32
	db $52
	db $32
	db $32
	db $32
	db $32
	db $32
	db $52
	db $32
	db $32
	db $52
	db $FB
	db $12
	db $11
	db $11
	db $32
	db $24
	db $11
	db $11
	db $32
	db $12
	db $FD, $06
	db $12
	db $12
	db $32
	db $24
	db $22
	db $32
	db $31
	db $31
	db $FB
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $22
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FD, $06
	db $22
	db $11
	db $11
	db $32
	db $24
	db $22
	db $31
	db $31
	db $32
	db $FE, $00
	db $FF

Audio1_Mus_WilyD_1:
	db $26
	db $12
	db $34
	db $26
	db $12
	db $34
	db $12
	db $12
	db $34
	db $26
	db $12
	db $34
	db $12
	db $24
	db $12
	db $34
	db $12
	db $12
	db $34
	db $26
	db $12
	db $34
	db $26
	db $12
	db $34
	db $12
	db $12
	db $34
	db $26
	db $12
	db $34
	db $12
	db $24
	db $12
	db $34
	db $12
	db $32
	db $32
	db $32
	db $F9

;Unused space (676 bytes)
	ds 676

SECTION "Audio RAM", WRAMX[AudioRAM]

CurTrack: ds 1			;$DB02
CurTrackCheck: ds 1			;$DB03
SFXNum: ds 1			;$DB04
Temp1: ds 1			;$DB05
Temp2: ds 1			;$DB06
Output: ds 1			;$DB07
WaveformMus: ds 1			;$DB08
WaveformSFX: ds 1			;$DB09
NewWave: ds 1			;$DB0A
Fade: ds 1			;$DB0B
FadeTime: ds 1			;$DB0C
MusPlaying: ds 1			;$DB0D

MusC1MusNum: ds 1		;$DB0E = $00
MusC1Priority: ds 1		;$DB0F = $01
MusC1Sweep: ds 1		;$DB10 = $02
MusC1Transpose: ds 1		;$DB11 = $03
MusC1Tuning: ds 1		;$DB12 = $04
MusC1VolFinal: ds 1		;$DB13 = $05
MusC1VolOutput: ds 1		;$DB14 = $06
MusC1NoteDelay: ds 1		;$DB15 = $07
MusC1NoteTime: ds 1		;$DB16 = $08
MusC1EnvOn: ds 1		;$DB17 = $09
MusC1EnvTime: ds 1		;$DB18 = $0A
MusC1Speed: ds 1		;$DB19 = $0B
MusC1DutyVol: ds 1		;$DB1A = $0C
MusC1Decay: ds 1		;$DB1B = $0D
MusC1EnvLen: ds 1		;$DB1C = $0E
MusC1Vibrato: ds 2		;$DB1D = $0F
MusC1EnvVal: ds 1		;$DB1F = $11
MusC1Decay2: ds 1		;$DB20 = $12
MusC1Decay3: ds 1		;$DB21 = $13
MusC1EnvSeqPtr: ds 2		;$DB22 = $14
MusC1VibStep: ds 1		;$DB24 = $16
MusC1EnvSeqPos: ds 1		;$DB25 = $17
MusC1EnvStep: ds 1		;$DB26 = $18
MusC1VibSeqDelay: ds 1		;$DB27 = $19
MusC1EnvDur: ds 1		;$DB28 = $1A
MusC1Octave: ds 1		;$DB29 = $1B
MusC1VibVal: ds 1		;$DB2A = $1C
MusC1Freq: ds 2		;$DB2B = $1D
MusC1VolCur: ds 1		;$DB2D = $1F
MusC1SongPos: ds 2		;$DB2E = $20
MusC1Repeat1Start: ds 2		;$DB30 = $22
MusC1Repeat2Start: ds 2		;$DB32 = $24
MusC1Macro1Pos: ds 2		;$DB34 = $26
MusC1Macro2Pos: ds 2		;$DB36 = $28
MusC1Repeat1Times: ds 1		;$DB38 = $2A
MusC1Repeat2Times: ds 1		;$DB39 = $2B

MusC2MusNum: ds 1		;$DB3A = $00
MusC2Priority: ds 1		;$DB3B = $01
MusC2Sweep: ds 1		;$DB3C = $02
MusC2Transpose: ds 1		;$DB3D = $03
MusC2Tuning: ds 1		;$DB3E = $04
MusC2VolFinal: ds 1		;$DB3F = $05
MusC2VolOutput: ds 1		;$DB40 = $06
MusC2NoteDelay: ds 1		;$DB41 = $07
MusC2NoteTime: ds 1		;$DB42 = $08
MusC2EnvOn: ds 1		;$DB43 = $09
MusC2EnvTime: ds 1		;$DB44 = $0A
MusC2Speed: ds 1		;$DB45 = $0B
MusC2DutyVol: ds 1		;$DB46 = $0C
MusC2Decay: ds 1		;$DB47 = $0D
MusC2EnvLen: ds 1		;$DB48 = $0E
MusC2Vibrato: ds 2		;$DB49 = $0F
MusC2EnvVal: ds 1		;$DB4B = $11
MusC2Decay2: ds 1		;$DB4C = $12
MusC2Decay3: ds 1		;$DB4D = $13
MusC2EnvSeqPtr: ds 2		;$DB4E = $14
MusC2VibStep: ds 1		;$DB50 = $16
MusC2EnvSeqPos: ds 1		;$DB51 = $17
MusC2EnvStep: ds 1		;$DB52 = $18
MusC2VibSeqDelay: ds 1		;$DB53 = $19
MusC2EnvDur: ds 1		;$DB54 = $1A
MusC2Octave: ds 1		;$DB55 = $1B
MusC2VibVal: ds 1		;$DB56 = $1C
MusC2Freq: ds 2		;$DB57 = $1D
MusC2VolCur: ds 1		;$DB59 = $1F
MusC2SongPos: ds 2		;$DB5A = $20
MusC2Repeat1Start: ds 2		;$DB5C = $22
MusC2Repeat2Start: ds 2		;$DB5E = $24
MusC2Macro1Pos: ds 2		;$DB60 = $26
MusC2Macro2Pos: ds 2		;$DB62 = $28
MusC2Repeat1Times: ds 1		;$DB64 = $2A
MusC2Repeat2Times: ds 1		;$DB65 = $2B

MusC3MusNum: ds 1		;$DB66 = $00
MusC3Priority: ds 1		;$DB67 = $01
MusC3Sweep: ds 1		;$DB68 = $02
MusC3Transpose: ds 1		;$DB69 = $03
MusC3Tuning: ds 1		;$DB6A = $04
MusC3VolFinal: ds 1		;$DB6B = $05
MusC3VolOutput: ds 1		;$DB6C = $06
MusC3NoteDelay: ds 1		;$DB6D = $07
MusC3NoteTime: ds 1		;$DB6E = $08
MusC3EnvOn: ds 1		;$DB6F = $09
MusC3EnvTime: ds 1		;$DB70 = $0A
MusC3Speed: ds 1		;$DB71 = $0B
MusC3DutyVol: ds 1		;$DB72 = $0C
MusC3Decay: ds 1		;$DB73 = $0D
MusC3EnvLen: ds 1		;$DB74 = $0E
MusC3Vibrato: ds 2		;$DB75 = $0F
MusC3EnvVal: ds 1		;$DB77 = $11
MusC3Decay2: ds 1		;$DB78 = $12
MusC3Decay3: ds 1		;$DB79 = $13
MusC3EnvSeqPtr: ds 2		;$DB7A = $14
MusC3VibStep: ds 1		;$DB7C = $16
MusC3EnvSeqPos: ds 1		;$DB7D = $17
MusC3EnvStep: ds 1		;$DB7E = $18
MusC3VibSeqDelay: ds 1		;$DB7F = $19
MusC3EnvDur: ds 1		;$DB80 = $1A
MusC3Octave: ds 1		;$DB81 = $1B
MusC3VibVal: ds 1		;$DB82 = $1C
MusC3Freq: ds 2		;$DB83 = $1D
MusC3VolCur: ds 1		;$DB85 = $1F
MusC3SongPos: ds 2		;$DB86 = $20
MusC3Repeat1Start: ds 2		;$DB88 = $22
MusC3Repeat2Start: ds 2		;$DB8A = $24
MusC3Macro1Pos: ds 2		;$DB8C = $26
MusC3Macro2Pos: ds 2		;$DB8E = $28
MusC3Repeat1Times: ds 1		;$DB90 = $2A
MusC3Repeat2Times: ds 1		;$DB91 = $2B

MusC4MusNum: ds 1		;$DB92 = $00
MusC4Priority: ds 1		;$DB93 = $01
MusC4Sweep: ds 1		;$DB94 = $02
MusC4Transpose: ds 1		;$DB95 = $03
MusC4Tuning: ds 1		;$DB96 = $04
MusC4VolFinal: ds 1		;$DB97 = $05
MusC4VolOutput: ds 1		;$DB98 = $06
MusC4NoteDelay: ds 1		;$DB99 = $07
MusC4NoteTime: ds 1		;$DB9A = $08
MusC4EnvOn: ds 1		;$DB9B = $09
MusC4EnvTime: ds 1		;$DB9C = $0A
MusC4Speed: ds 1		;$DB9D = $0B
MusC4DutyVol: ds 1		;$DB9E = $0C
MusC4Decay: ds 1		;$DB9F = $0D
MusC4EnvLen: ds 1		;$DBA0 = $0E
MusC4Vibrato: ds 2		;$DBA1 = $0F
MusC4EnvVal: ds 1		;$DBA3 = $11
MusC4Decay2: ds 1		;$DBA4 = $12
MusC4Decay3: ds 1		;$DBA5 = $13
MusC4EnvSeqPtr: ds 2		;$DBA6 = $14
MusC4VibStep: ds 1		;$DBA8 = $16
MusC4EnvSeqPos: ds 1		;$DBA9 = $17
MusC4EnvStep: ds 1		;$DBAA = $18
MusC4VibSeqDelay: ds 1		;$DBAB = $19
MusC4EnvDur: ds 1		;$DBAC = $1A
MusC4Octave: ds 1		;$DBAD = $1B
MusC4VibVal: ds 1		;$DBAE = $1C
MusC4Freq: ds 2		;$DBAF = $1D
MusC4VolCur: ds 1		;$DBB1 = $1F
MusC4SongPos: ds 2		;$DBB2 = $20
MusC4Repeat1Start: ds 2		;$DBB4 = $22
MusC4Repeat2Start: ds 2		;$DBB6 = $24
MusC4Macro1Pos: ds 2		;$DBB8 = $26
MusC4Macro2Pos: ds 2		;$DBBA = $28
MusC4Repeat1Times: ds 1		;$DBBC = $2A
MusC4Repeat2Times: ds 1		;$DBBD = $2B

SFXC1MusNum: ds 1		;$DBBE = $00
SFXC1Priority: ds 1		;$DBBF = $01
SFXC1Sweep: ds 1		;$DBC0 = $02
SFXC1Transpose: ds 1		;$DBC1 = $03
SFXC1Tuning: ds 1		;$DBC2 = $04
SFXC1VolFinal: ds 1		;$DBC3 = $05
SFXC1VolOutput: ds 1		;$DBC4 = $06
SFXC1NoteDelay: ds 1		;$DBC5 = $07
SFXC1NoteTime: ds 1		;$DBC6 = $08
SFXC1EnvOn: ds 1		;$DBC7 = $09
SFXC1EnvTime: ds 1		;$DBC8 = $0A
SFXC1Speed: ds 1		;$DBC9 = $0B
SFXC1DutyVol: ds 1		;$DBCA = $0C
SFXC1Decay: ds 1		;$DBCB = $0D
SFXC1EnvLen: ds 1		;$DBCC = $0E
SFXC1Vibrato: ds 2		;$DBCD = $0F
SFXC1EnvVal: ds 1		;$DBCF = $11
SFXC1Decay2: ds 1		;$DBD0 = $12
SFXC1Decay3: ds 1		;$DBD1 = $13
SFXC1EnvSeqPtr: ds 2		;$DBD2 = $14
SFXC1VibStep: ds 1		;$DBD4 = $16
SFXC1EnvSeqPos: ds 1		;$DBD5 = $17
SFXC1EnvStep: ds 1		;$DBD6 = $18
SFXC1VibSeqDelay: ds 1		;$DBD7 = $19
SFXC1EnvDur: ds 1		;$DBD8 = $1A
SFXC1Octave: ds 1		;$DBD9 = $1B
SFXC1VibVal: ds 1		;$DBDA = $1C
SFXC1Freq: ds 2		;$DBDB = $1D
SFXC1VolCur: ds 1		;$DBDD = $1F
SFXC1SongPos: ds 2		;$DBDE = $20
SFXC1Repeat1Start: ds 2		;$DBE0 = $22
SFXC1Repeat2Start: ds 2		;$DBE2 = $24
SFXC1Macro1Pos: ds 2		;$DBE4 = $26
SFXC1Macro2Pos: ds 2		;$DBE6 = $28
SFXC1Repeat1Times: ds 1		;$DBE8 = $2A
SFXC1Repeat2Times: ds 1		;$DBE9 = $2B

SFXC2MusNum: ds 1		;$DBEA = $00
SFXC2Priority: ds 1		;$DBEB = $01
SFXC2Sweep: ds 1		;$DBEC = $02
SFXC2Transpose: ds 1		;$DBED = $03
SFXC2Tuning: ds 1		;$DBEE = $04
SFXC2VolFinal: ds 1		;$DBEF = $05
SFXC2VolOutput: ds 1		;$DBF0 = $06
SFXC2NoteDelay: ds 1		;$DBF1 = $07
SFXC2NoteTime: ds 1		;$DBF2 = $08
SFXC2EnvOn: ds 1		;$DBF3 = $09
SFXC2EnvTime: ds 1		;$DBF4 = $0A
SFXC2Speed: ds 1		;$DBF5 = $0B
SFXC2DutyVol: ds 1		;$DBF6 = $0C
SFXC2Decay: ds 1		;$DBF7 = $0D
SFXC2EnvLen: ds 1		;$DBF8 = $0E
SFXC2Vibrato: ds 2		;$DBF9 = $0F
SFXC2EnvVal: ds 1		;$DBFB = $11
SFXC2Decay2: ds 1		;$DBFC = $12
SFXC2Decay3: ds 1		;$DBFD = $13
SFXC2EnvSeqPtr: ds 2		;$DBFE = $14
SFXC2VibStep: ds 1		;$DC00 = $16
SFXC2EnvSeqPos: ds 1		;$DC01 = $17
SFXC2EnvStep: ds 1		;$DC02 = $18
SFXC2VibSeqDelay: ds 1		;$DC03 = $19
SFXC2EnvDur: ds 1		;$DC04 = $1A
SFXC2Octave: ds 1		;$DC05 = $1B
SFXC2VibVal: ds 1		;$DC06 = $1C
SFXC2Freq: ds 2		;$DC07 = $1D
SFXC2VolCur: ds 1		;$DC09 = $1F
SFXC2SongPos: ds 2		;$DC0A = $20
SFXC2Repeat1Start: ds 2		;$DC0C = $22
SFXC2Repeat2Start: ds 2		;$DC0E = $24
SFXC2Macro1Pos: ds 2		;$DC10 = $26
SFXC2Macro2Pos: ds 2		;$DC12 = $28
SFXC2Repeat1Times: ds 1		;$DC14 = $2A
SFXC2Repeat2Times: ds 1		;$DC15 = $2B

SFXC3MusNum: ds 1		;$DC16 = $00
SFXC3Priority: ds 1		;$DC17 = $01
SFXC3Sweep: ds 1		;$DC18 = $02
SFXC3Transpose: ds 1		;$DC19 = $03
SFXC3Tuning: ds 1		;$DC1A = $04
SFXC3VolFinal: ds 1		;$DC1B = $05
SFXC3VolOutput: ds 1		;$DC1C = $06
SFXC3NoteDelay: ds 1		;$DC1D = $07
SFXC3NoteTime: ds 1		;$DC1E = $08
SFXC3EnvOn: ds 1		;$DC1F = $09
SFXC3EnvTime: ds 1		;$DC20 = $0A
SFXC3Speed: ds 1		;$DC21 = $0B
SFXC3DutyVol: ds 1		;$DC22 = $0C
SFXC3Decay: ds 1		;$DC23 = $0D
SFXC3EnvLen: ds 1		;$DC24 = $0E
SFXC3Vibrato: ds 2		;$DC25 = $0F
SFXC3EnvVal: ds 1		;$DC27 = $11
SFXC3Decay2: ds 1		;$DC28 = $12
SFXC3Decay3: ds 1		;$DC29 = $13
SFXC3EnvSeqPtr: ds 2		;$DC2A = $14
SFXC3VibStep: ds 1		;$DC2C = $16
SFXC3EnvSeqPos: ds 1		;$DC2D = $17
SFXC3EnvStep: ds 1		;$DC2E = $18
SFXC3VibSeqDelay: ds 1		;$DC2F = $19
SFXC3EnvDur: ds 1		;$DC30 = $1A
SFXC3Octave: ds 1		;$DC31 = $1B
SFXC3VibVal: ds 1		;$DC32 = $1C
SFXC3Freq: ds 2		;$DC33 = $1D
SFXC3VolCur: ds 1		;$DC35 = $1F
SFXC3SongPos: ds 2		;$DC36 = $20
SFXC3Repeat1Start: ds 2		;$DC38 = $22
SFXC3Repeat2Start: ds 2		;$DC3A = $24
SFXC3Macro1Pos: ds 2		;$DC3C = $26
SFXC3Macro2Pos: ds 2		;$DC3E = $28
SFXC3Repeat1Times: ds 1		;$DC40 = $2A
SFXC3Repeat2Times: ds 1		;$DC41 = $2B

SFXC4MusNum: ds 1		;$DC42 = $00
SFXC4Priority: ds 1		;$DC43 = $01
SFXC4Sweep: ds 1		;$DC44 = $02
SFXC4Transpose: ds 1		;$DC45 = $03
SFXC4Tuning: ds 1		;$DC46 = $04
SFXC4VolFinal: ds 1		;$DC47 = $05
SFXC4VolOutput: ds 1		;$DC48 = $06
SFXC4NoteDelay: ds 1		;$DC49 = $07
SFXC4NoteTime: ds 1		;$DC4A = $08
SFXC4EnvOn: ds 1		;$DC4B = $09
SFXC4EnvTime: ds 1		;$DC4C = $0A
SFXC4Speed: ds 1		;$DC4D = $0B
SFXC4DutyVol: ds 1		;$DC4E = $0C
SFXC4Decay: ds 1		;$DC4F = $0D
SFXC4EnvLen: ds 1		;$DC50 = $0E
SFXC4Vibrato: ds 2		;$DC51 = $0F
SFXC4EnvVal: ds 1		;$DC53 = $11
SFXC4Decay2: ds 1		;$DC54 = $12
SFXC4Decay3: ds 1		;$DC55 = $13
SFXC4EnvSeqPtr: ds 2		;$DC56 = $14
SFXC4VibStep: ds 1		;$DC58 = $16
SFXC4EnvSeqPos: ds 1		;$DC59 = $17
SFXC4EnvStep: ds 1		;$DC5A = $18
SFXC4VibSeqDelay: ds 1		;$DC5B = $19
SFXC4EnvDur: ds 1		;$DC5C = $1A
SFXC4Octave: ds 1		;$DC5D = $1B
SFXC4VibVal: ds 1		;$DC5E = $1C
SFXC4Freq: ds 2		;$DC5F = $1D
SFXC4VolCur: ds 1		;$DC61 = $1F
SFXC4SongPos: ds 2		;$DC62 = $20
SFXC4Repeat1Start: ds 2		;$DC64 = $22
SFXC4Repeat2Start: ds 2		;$DC66 = $24
SFXC4Macro1Pos: ds 2		;$DC68 = $26
SFXC4Macro2Pos: ds 2		;$DC6A = $28
SFXC4Repeat1Times: ds 1		;$DC6C = $2A
SFXC4Repeat2Times: ds 1		;$DC6D = $2B

NR10Val: ds 1			;$DC6E
NR11Val: ds 1			;$DC6F
NR12Val: ds 1			;$DC70
NR13Val: ds 1			;$DC71
NR14Val: ds 1			;$DC72
NR21Val: ds 1			;$DC73
NR22Val: ds 1			;$DC74
NR23Val: ds 1			;$DC75
NR24Val: ds 1			;$DC76
NR30Val: ds 1			;$DC77
NR31Val: ds 1			;$DC78
NR32Val: ds 1			;$DC79
NR33Val: ds 1			;$DC7A
NR34Val: ds 1			;$DC7B
NR41Val: ds 1			;$DC7C
NR42Val: ds 1			;$DC7D
NR43Val: ds 1			;$DC7E
NR44Val: ds 1			;$DC7F
NR50Val: ds 1			;$DC80
NR51Val: ds 1			;$DC81
NR52Val: ds 1			;$DC82
NR10ValCopy: ds 1			;$DC83
NR11ValCopy: ds 1			;$DC84
NR12ValCopy: ds 1			;$DC85
NR13ValCopy: ds 1			;$DC86
NR14ValCopy: ds 1			;$DC87
NR21ValCopy: ds 1			;$DC88
NR22ValCopy: ds 1			;$DC89
NR23ValCopy: ds 1			;$DC8A
NR24ValCopy: ds 1			;$DC8B
NR30ValCopy: ds 1			;$DC8C
NR31ValCopy: ds 1			;$DC8D
NR32ValCopy: ds 1			;$DC8E
NR33ValCopy: ds 1			;$DC8F
NR34ValCopy: ds 1			;$DC90
NR41ValCopy: ds 1			;$DC91
NR42ValCopy: ds 1			;$DC92
NR43ValCopy: ds 1			;$DC93
NR44ValCopy: ds 1			;$DC94
NR50ValCopy: ds 1			;$DC95
NR51ValCopy: ds 1			;$DC96
NR52ValCopy: ds 1			;$DC97
Gate1Off: ds 1			;$DC98
Gate2Off: ds 1			;$DC99
Gate3Off: ds 1			;$DC9A
Gate4Off: ds 1			;$DC9B
