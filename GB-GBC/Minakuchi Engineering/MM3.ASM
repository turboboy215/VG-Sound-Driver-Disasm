;Mega Man III audio disassembly
;Disassembly by Will Trowbridge

include "HARDWARE.INC"

def AudioROM equ $4000
def AudioRAM equ $DB02
def WaveRAM equ $FF30
def TrackRAMSize equ $2C

def MusC1RAM equ $DB0D
def MusC2RAM equ $DB39
def MusC3RAM equ $DB65
def MusC4RAM equ $DB91
def SFXC1RAM equ $DBBD
def SFXC2RAM equ $DBE9
def SFXC3RAM equ $DC15
def SFXC4RAM equ $DC41

def StageMus equ $D160
def CurStage equ $DF08
def BossMus equ $DF12

SECTION "Audio", ROMX[AudioROM], BANK[$1]

	jp PlayAudio


	jp LoadSong


	jp InitSound


	;Game-specific function
	jp SetStageMus


	;Additional game-specific function (unknown)
	jp Extra


SetStageMus:
	ld a, [CurStage]
	ld e, a
	;If stage is above 4, then use second boss theme
	ld d, $44	;Boss battle 2 (from MM4 NES)
	cp 5
	jr nc, .SetStageMus2

	;Otherwise, use first boss theme
	ld d, $3e	;Boss battle 1 (from MM3 NES)

.SetStageMus2
	;Set boss music
	ld a, d
	ld [BossMus], a
	;Set stage music from table
	ld a, e
	ld hl, StageMusIDs-1
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
	ld a, [hl]
	ld [StageMus], a
	;Go to game-specific routine
	jp StageMacro
	
StageMusIDs:
	db $41		;Spark Man
	db $3F		;Gemini Man
	db $40		;Snake Man
	db $3D		;Shadow Man
	db $48		;Dive Man
	db $49		;Skull Man
	db $4A		;Drill Man
	db $47		;Dust Man
	db $4D		;Dr. Wily 1
	db $4D		;Dr. Wily 2
	db $4E		;Dr. Wily 3
	db $42		;Ending
	
SongTab:
	;Percussion
	dw Perc_Empty
	dw Perc01
	dw Perc02
	dw Perc03
	dw Perc04
	dw Perc05
	dw Perc06
	dw Perc07
	dw Perc08
	dw Perc09
	dw FadeOutTrack
	;SFX
	dw SFX_Empty1
	dw SFX_Empty2
	dw SFX_Shot
	dw SFX_ChargeShotSmall
	dw SFX_ChargeShotLarge
	dw SFX_Charge
	dw SFX_Land
	dw SFX_ExtraLife
	dw SFX_Hurt
	dw SFX_PlayerExplode
	dw SFX_EnemyHit
	dw SFX_BossExplode
	dw SFX_Health
	dw SFX_Shing
	dw SFX_Select
	dw SFX_Pause
	dw SFX_TeleportIn
	dw SFX_TeleportOut
	dw SFX_Deflect
	dw SFX_Door
	dw SFX_ShadowBlade
	dw SFX_Explode
	dw SFX_Drill_Bomb
	dw SFX_Thunder
	dw SFX_Splash
	dw SFX_Enemy_Spark
	dw SFX_WilyUFO
	dw SFX_BigExplode1
	dw SFX_GeminiLaser
	dw SFX_SparkShock
	dw SFX_Error
	dw SFX_Accept
	dw SFX_Text
	dw SFX_Alarm
	dw SFX_FortressExplode
	dw SFX_LadderTrap
	dw SFX_Block
	dw SFX_Stomp
	dw SFX_GiantSuzy
	dw SFX_ScrewCrusher
	dw SFX_FortressAppear
	dw SFX_RushJetCharge
	dw SFX_WilyEscape1
	dw SFX_WilyEscape2
	dw SFX_Metall_Vehicle
	dw SFX_WilyUFOFall
	dw SFX_GetWeapon
	dw SFX_PunkRumble
	;Music
	dw Mus_StageSelect
	dw Mus_Start
	dw Mus_ShadowMan
	dw Mus_Boss1
	dw Mus_GeminiMan
	dw Mus_SnakeMan
	dw Mus_SparkMan
	dw Mus_EndGame
	dw Mus_GameOver
	dw Mus_Boss2
	dw Mus_Victory
	dw Mus_Credits
	dw Mus_DustMan
	dw Mus_DiveMan
	dw Mus_SkullMan
	dw Mus_DrillMan
	dw Mus_WilyIntro
	dw Mus_FinalVictory
	dw Mus_Wily1
	dw Mus_Wily2
	dw Mus_Punk
	dw Mus_GetWeapon
	dw Mus_Title
	dw Mus_Password

Perc_Empty:

FadeOutTrack:
	db %00000000
	db 0
	dw EmptySeq
	
Perc01:
	db %10000000
	db 0
	dw Perc01D
	
Perc02:
	db %10000000
	db 0
	dw Perc02D
	
Perc03:
	db %10000000
	db 0
	dw Perc03D
	
Perc04:
	db %11000000
	db 0
	dw Perc04C
	dw Perc03D
	
Perc05:
	db %10000000
	db 0
	dw Perc05D

Perc06:
	db %11000000
	db 0
	dw Perc06C
	dw Perc01D

Perc07:
	db %11000000
	db 0
	dw Perc07C
	dw Perc01D
	
Perc08:
	db %11000000
	db 0
	dw Perc08C
	dw Perc01D

Perc09:	
	db %11000000
	db 0
	dw Perc09C
	dw Perc01D

SFX_Shot:	
	db %00010000
	db 4
	dw SFX_ShotA
	
SFX_ChargeShotSmall:
	db %10000000
	db 4
	dw SFX_ChargeShotSmallD

SFX_ChargeShotLarge:
	db %10000000
	db 4
	dw SFX_ChargeShotLargeD

SFX_Charge:
	db %00010000
	db 3
	dw SFX_ChargeA

SFX_Land:
	db %00010000
	db 3
	dw SFX_LandA
	
SFX_ExtraLife:
	db %00010000
	db 10
	dw SFX_ExtraLifeA

SFX_Hurt:
	db %10010000
	db 11
	dw SFX_HurtA
	dw SFX_HurtD

SFX_PlayerExplode:
	db %00010000
	db 12
	dw SFX_PlayerExplodeA

SFX_EnemyHit:
	db %10000000
	db 5
	dw SFX_EnemyHitD

SFX_BossExplode:
	db %10000000
	db 6
	dw SFX_BossExplodeD

SFX_Health:
	db %00010000
	db 10
	dw SFX_HealthA

SFX_Shing:
	db %00110000
	db 10
	dw SFX_ShingA
	dw SFX_ShingB

SFX_Select:
	db %00010000
	db 10
	dw SFX_SelectA

SFX_Pause:
	db %00010000
	db 10
	dw SFX_PauseA

SFX_TeleportIn:
	db %00010000
	db 3
	dw SFX_TeleportInA

SFX_TeleportOut:
	db %00010000
	db 7
	dw SFX_TeleportOutA

SFX_Deflect:
	db %10000000
	db 4
	dw SFX_DeflectD

SFX_Door:
	db %10000000
	db 10
	dw SFX_DoorD

SFX_ShadowBlade:
	db %10000000
	db 4
	dw SFX_ShadowBladeD

SFX_Explode:
	db %10000000
	db 7
	dw SFX_ExplodeD

SFX_Drill_Bomb:
	db %10000000
	db 4
	dw SFX_Drill_BombD

SFX_Thunder:
	db %10010000
	db 9
	dw SFX_ThunderA
	dw SFX_ThunderD

SFX_Splash:
	db %10000000
	db 4
	dw SFX_SplashD

SFX_Enemy_Spark:
	db %10000000
	db 2
	dw SFX_Enemy_SparkD

SFX_WilyUFO:
	db %00010000
	db 1
	dw SFX_WilyUFOA

SFX_BigExplode1:
	db %10010000
	db 9
	dw SFX_BigExplode1A
	dw SFX_BigExplode1D

SFX_GeminiLaser:
	db %10010000
	db 4
	dw SFX_GeminiLaserA
	dw SFX_GeminiLaserD

SFX_SparkShock:
	db %10000000
	db 4
	dw SFX_SparkShockD

SFX_Error:
	db %00110000
	db 10
	dw SFX_ErrorA
	dw SFX_ErrorB

SFX_Accept:
	db %00110000
	db 10
	dw SFX_AcceptA
	dw SFX_AcceptB

SFX_Text:
	db %10000000
	db 10
	dw SFX_TextD

SFX_Alarm:
	db %01010000
	db 1
	dw SFX_AlarmA
	dw SFX_AlarmC

SFX_FortressExplode:
	db %10010000
	db 9
	dw SFX_FortressExplodeA
	dw SFX_FortressExplodeD

SFX_LadderTrap:
	db %10010000
	db 1
	dw SFX_LadderTrapA
	dw SFX_LadderTrapD

SFX_Block:
	db %10010000
	db 1
	dw SFX_BlockA
	dw SFX_BlockD

SFX_Stomp:
	db %00010000
	db 7
	dw SFX_StompA

SFX_GiantSuzy:
	db %00010000
	db 1
	dw SFX_GiantSuzyA

SFX_ScrewCrusher:
	db %00010000
	db 4
	dw SFX_ScrewCrusherA

SFX_FortressAppear:
	db %10010000
	db 7
	dw SFX_FortressAppearA
	dw SFX_FortressAppearD

SFX_RushJetCharge:
	db %00010000
	db 7
	dw SFX_RushJetChargeA

SFX_WilyEscape1:
	db %00010000
	db 7
	dw SFX_WilyEscape1A

SFX_WilyEscape2:
	db %10010000
	db 7
	dw SFX_WilyEscape2A
	dw SFX_WilyEscape2D

SFX_Metall_Vehicle:
	db %10000000
	db 1
	dw SFX_Metall_VehicleD

SFX_WilyUFOFall:
	db %00010000
	db 7
	dw SFX_WilyUFOFallD

SFX_GetWeapon:
	db %00110000
	db 3
	dw SFX_GetWeaponA
	dw SFX_GetWeaponB

SFX_PunkRumble:
	db %10010000
	db 9
	dw SFX_PunkRumbleA
	dw SFX_PunkRumbleD
	
SFX_Empty1:
	db %00001111
	db 2
	dw EmptySeq
	dw EmptySeq
	dw EmptySeq
	dw EmptySeq

SFX_Empty2:
	db %11110000
	db 15
	dw EmptySeq
	dw EmptySeq
	dw EmptySeq
	dw EmptySeq

;Music starts here
Mus_StageSelect:
	db %00001111
	db 1
	dw Mus_StageSelectA
	dw Mus_StageSelectB
	dw Mus_StageSelectC
	dw Mus_StageSelectD

Mus_Start:
	db %00001111
	db 1
	dw Mus_StartA
	dw Mus_StartB
	dw Mus_StartC
	dw Mus_StartD

Mus_ShadowMan:
	db %00001111
	db 1
	dw Mus_ShadowManA
	dw Mus_ShadowManB
	dw Mus_ShadowManC
	dw Mus_ShadowManD
	
Mus_GeminiMan:
	db %00001111
	db 1
	dw Mus_GeminiManA
	dw Mus_GeminiManB
	dw Mus_GeminiManC
	dw Mus_GeminiManD

Mus_SnakeMan:
	db %00001111
	db 1
	dw Mus_SnakeManA
	dw Mus_SnakeManB
	dw Mus_SnakeManC
	dw Mus_SnakeManD
	
Mus_SparkMan:	
	db %00001111
	db 1
	dw Mus_SparkManA
	dw Mus_SparkManB
	dw Mus_SparkManC
	dw Mus_SparkManD

Mus_Boss1:
	db %00001111
	db 1
	dw Mus_Boss1A
	dw Mus_Boss1B
	dw Mus_Boss1C
	dw Mus_Boss1D

Mus_EndGame:
	db %00001111
	db 1
	dw Mus_EndGameA
	dw Mus_EndGameB
	dw Mus_EndGameC
	dw Mus_EndGameD

Mus_GameOver:
	db %00001111
	db 1
	dw Mus_GameOverA
	dw Mus_GameOverB
	dw Mus_GameOverC
	dw Mus_GameOverD

Mus_Boss2:
	db %00001111
	db 1
	dw Mus_Boss2A
	dw Mus_Boss2B
	dw Mus_Boss2C
	dw Mus_Boss2D

Mus_Victory:
	db %00001111
	db 1
	dw Mus_VictoryA
	dw Mus_VictoryB
	dw Mus_VictoryC
	dw Mus_VictoryD

Mus_Credits:
	db %00001111
	db 1
	dw Mus_CreditsA
	dw Mus_CreditsB
	dw Mus_CreditsC
	dw Mus_CreditsD

Mus_DustMan:
	db %00001111
	db 1
	dw Mus_DustManA
	dw Mus_DustManB
	dw Mus_DustManC
	dw Mus_DustManD

Mus_DiveMan:
	db %00001111
	db 1
	dw Mus_DiveManA
	dw Mus_DiveManB
	dw Mus_DiveManC
	dw Mus_DiveManD

Mus_SkullMan:
	db %00001111
	db 1
	dw Mus_SkullManA
	dw Mus_SkullManB
	dw Mus_SkullManC
	dw Mus_SkullManD

Mus_DrillMan:
	db %00001111
	db 1
	dw Mus_DrillManA
	dw Mus_DrillManB
	dw Mus_DrillManC
	dw Mus_DrillManD

Mus_WilyIntro:
	db %00001111
	db 1
	dw Mus_WilyIntroA
	dw Mus_WilyIntroB
	dw Mus_WilyIntroC
	dw Mus_WilyIntroD

Mus_FinalVictory:
	db %00001111
	db 1
	dw Mus_FinalVictoryA
	dw Mus_FinalVictoryB
	dw Mus_FinalVictoryC
	dw Mus_FinalVictoryD

Mus_Wily1:
	db %00001111
	db 1
	dw Mus_Wily1A
	dw Mus_Wily1B
	dw Mus_Wily1C
	dw Mus_Wily1D

Mus_Wily2:
	db %00001111
	db 1
	dw Mus_Wily2A
	dw Mus_Wily2B
	dw Mus_Wily2C
	dw Mus_Wily2D

Mus_Punk:
	db %00001111
	db 1
	dw Mus_PunkA
	dw Mus_PunkB
	dw Mus_PunkC
	dw Mus_PunkD

Mus_GetWeapon:	
	db %00001111
	db 1
	dw Mus_GetWeaponA
	dw Mus_GetWeaponB
	dw Mus_GetWeaponC
	dw Mus_GetWeaponD

Mus_Title:
	db %00001111
	db 1
	dw Mus_TitleA
	dw Mus_TitleB
	dw Mus_TitleC
	dw Mus_TitleD

Mus_Password:
	db %00001111
	db 1
	dw Mus_PasswordA
	dw Mus_PasswordB
	dw Mus_PasswordC
	dw Mus_PasswordD

EmptySeq:
	db $FF

Perc01D:
	db $D1, $00, $90, $89, $11, $81
	db $E0
	db $15
	db $FF

Perc02D:
	db $D2, $00, $A0, $8A, $31, $F4
	db $E0
	db $1E
	db $FF

Perc03D:
	db $D1, $00, $90, $89, $11, $B1
	db $E1
	db $B7
	db $FF

Perc04C:
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

Perc05D:
	db $D1, $11, $00, $09
	db $E5
	db $32
	db $EE, $06
	db $31
	db $EE, $02
	db $31
	db $FF

Perc06C:
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

Perc07C:
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

Perc08C:
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

Perc09C:
	db $D1
	db $10
	db $0E
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

	db $D7, $10, $90, $0A
	db $E5
	db $04
	db $14
	db $24
	db $34
	db $44
	db $54
	db $64
	db $74
	db $FF
	
	db $FF

EnvSeqTab:
	dw EnvSeq00
	dw EnvSeq01
	dw EnvSeq02
	dw EnvSeq03
	dw EnvSeq04
	dw EnvSeq05
	dw EnvSeq06
	dw EnvSeq07
	dw EnvSeq08
	dw EnvSeq09
	dw EnvSeq0A
	dw EnvSeq0B
	dw EnvSeq0C
	dw EnvSeq0D
	dw EnvSeq0E
	dw EnvSeq0F
	dw EnvSeq10
	dw EnvSeq11
EnvSeq00:
	db $8F
	db $FF
EnvSeq01:
	db $1F
	db $FF
EnvSeq02:
	db $2F
	db $FF
EnvSeq03:
	db $3F
	db $FF
EnvSeq04:
	db $4F
	db $FF
EnvSeq05:
	db $5F
	db $FF
EnvSeq06:
	db $6F
	db $FF
EnvSeq07:
	db $7F
	db $FF
EnvSeq08:
	db $8F
	db $FF
EnvSeq09:
	db $9F
	db $FF
EnvSeq0A:
	db $AF
	db $FF
EnvSeq0B:
	db $BF
	db $FF
EnvSeq0C:
	db $CF
	db $FF
EnvSeq0D:
	db $DF
	db $FF
EnvSeq0E:
	db $EF
	db $FF
EnvSeq0F:
	db $FE
	db $FF
EnvSeq10:
	db $22, $82, $43, $2F
	db $FF
EnvSeq11:
	db $92, $42, $62, $5F
	db $FF
	
VibTab:
	dw Vibrato0
	dw Vibrato1
	dw Vibrato2
	dw Vibrato3
	dw Vibrato4
	dw Vibrato5
	dw Vibrato6
	dw Vibrato7
	dw Vibrato8
	dw Vibrato9
	dw VibratoA
	dw VibratoB
	dw VibratoC
	dw VibratoD
	dw VibratoE
	dw VibratoF

Vibrato0:
	db $0F
	db $FF
Vibrato1:
	db $14, $03, $F4, $03
	db $FF
Vibrato2:
	db $11, $22, $11, $02
	db $F1, $E2, $F1, $02
	db $FF
Vibrato3:
	db $21, $32, $21, $02
	db $E1, $D2, $E1, $02
	db $FF
Vibrato4:
	db $21, $42, $21, $02
	db $E1, $C2, $E1, $02
	db $FF
Vibrato5:
	db $31, $52, $31, $02
	db $D1, $B2, $D1, $02
	db $FF
Vibrato6:
	db $31, $62, $31, $02
	db $D1, $A2, $D1, $02
	db $FF
Vibrato7:
	db $32, $72, $32, $02
	db $D2, $92, $D2, $02
	db $FF
Vibrato8:
Vibrato9:
VibratoA:
VibratoB:
VibratoC:
VibratoD:
VibratoE:
VibratoF:
	db $03, $13, $23, $13
	db $FF

WaveTab:
	dw Waveform00
	dw Waveform01
	dw Waveform02
	dw Waveform03
	dw Waveform04
	dw Waveform05
	dw Waveform06
	dw Waveform07
	dw Waveform08
	dw Waveform09
	dw Waveform0A
	dw Waveform0B
	dw Waveform0C
	dw Waveform0D
	dw Waveform0E
	dw Waveform0F
	dw Waveform10
Waveform00:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $ED, $CB, $A9, $87, $65, $43, $21, $00
Waveform01:
	db $02, $46, $8A, $CE, $FF, $FF, $FF, $FF, $EC, $A8, $64, $20, $00, $44, $88, $44
Waveform02:
	db $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
Waveform03:
	db $35, $22, $4A, $00, $0A, $34, $05, $00, $FA, $FF, $0F, $FA, $FC, $F0, $00, $F0
Waveform04:
	db $FE, $DC, $BA, $98, $76, $54, $32, $10, $76, $54, $32, $10, $44, $00, $22, $00
Waveform05:
	db $79, $8F, $FC, $CF, $FD, $B9, $75, $31, $76, $54, $32, $10, $44, $00, $22, $00
Waveform06:
	db $03, $69, $CF, $FC, $96, $30, $03, $56, $77, $65, $44, $33, $20, $00, $52, $00
Waveform07:
	db $01, $21, $45, $67, $01, $21, $45, $67, $FE, $DC, $BA, $98, $76, $54, $32, $10
Waveform08:
	db $01, $11, $12, $23, $34, $45, $56, $67, $78, $89, $9A, $AB, $BC, $CD, $DD, $D0
Waveform09:
Waveform0A:
Waveform0B:
Waveform0C:
Waveform0D:
Waveform0E:
Waveform0F:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $ED, $CB, $A9, $87, $65, $43, $21, $00
Waveform10:
	db $02, $34, $67, $9A, $CD, $FF, $FF, $EE, $EE, $FF, $FF, $DC, $A9, $76, $43, $10

SFX_ShotA:
	db $D1, $22, $F0, $00, $0F
	db $EA, $25
	db $E2
	db $38
	db $EE, $02
	db $E3
	db $34
	db $FF
	
SFX_ChargeShotSmallD:
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
	
SFX_ChargeShotLargeD:
	db $D2, $11, $F0, $0F
	db $E5, $72
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
	
SFX_ChargeA:
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
	
SFX_LandA:
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
	
SFX_ExtraLifeA:
	db $D3, $22, $F0, $00, $0F
	db $FB
	db $E4
	db $11, $31, $51, $61, $81, $A1
	db $E5
	db $01, $11
	db $EE, $08
	db $FD, $01
	db $FF

SFX_HurtA:
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
SFX_HurtD:	
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

SFX_PlayerExplodeA:
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
	
SFX_EnemyHitD:
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

SFX_BossExplodeD:
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

SFX_HealthA:
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

SFX_ShingA:
	db $D2, $22, $F0, $00, $9F, $21, $F2
	db $E4
	db $82
	db $E5
	db $50
	db $FF
SFX_ShingB:
	db $D2, $22, $F0, $00, $9F, $21, $F2
	db $EF, $02
	db $E4
	db $82
	db $E5
	db $50
	db $FF

SFX_SelectA:
	db $D1, $01, $E0, $00, $9E, $21, $81
	db $E3
	db $87
	db $17
	db $FF

SFX_PauseA:
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

SFX_TeleportInA:
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

SFX_TeleportOutA:
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

SFX_DeflectD:
	db $D1, $11, $C0, $0E
	db $E1
	db $12
	db $EE, $8C
	db $10
	db $11
	db $04
	db $FF

SFX_DoorD:
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

SFX_ShadowBladeD:
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
	
SFX_ExplodeD:
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
	db $EE
	db $0C
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

SFX_Drill_BombD:	
	db $D1, $11, $F0, $8F, $11, $B1
	db $E7
	db $FB
	db $13
	db $C2
	db $FD, $05
	db $FF

SFX_ThunderA:
	db $D2, $00, $80, $00, $98, $21, $F2
	db $E6
	db $12
	db $24
	db $EA, $1B
	db $F3, $00
	db $E3
	db $EE, $0F
	db $74
	db $74
	db $EE, $0C
	db $74
	db $EE, $08
	db $74
	db $EE, $04
	db $74
	db $FF
SFX_ThunderD:
	db $D1, $00, $F0, $0F
	db $E1
	db $32
	db $EE, $0D
	db $22
	db $EE, $0B
	db $12
	db $E8, $11
	db $EE, $0F
	db $E5
	db $72
	db $51
	db $71
	db $C2
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
	db $EE, $06,
	db $72
	db $51
	db $21
	db $72
	db $51
	db $21
	db $EE, $04
	db $72
	db $51
	db $21
	db $72
	db $51
	db $21
	db $EE, $02
	db $72
	db $51
	db $21
	db $72
	db $51
	db $21
	db $FF

SFX_SplashD:
	db $D1, $00, $F0, $0F
	db $E3
	db $01
	db $21
	db $41
	db $61
	db $E8
	db $0B
	db $71
	db $C3
	db $D2, $00, $F0, $8F, $23, $F4
	db $E3
	db $2C
	db $FF

SFX_Enemy_SparkD:
	db $D1, $11, $F0, $0F
	db $E3
	db $56
	db $FF

SFX_WilyUFOA:
	db $D1, $22, $00, $17, $08
	db $E4
	db $20
	db $FF

SFX_BigExplode1A:
	db $D2, $00, $40, $00, $0F
	db $EA, $1B
	db $F3, $00
	db $E2
	db $FB
	db $74
	db $FD, $07
	db $FF
SFX_BigExplode1D:
	db $D1, $11, $F0, $0F
	db $E5
	db $FB
	db $74
	db $53
	db $C1
	db $FD, $07
	db $FF

SFX_GeminiLaserA:
	db $D2, $00, $40, $15, $07
	db $EF, $07
	db $E3
	db $27
	db $FF
SFX_GeminiLaserD:
	db $D2, $11, $F0, $0F
	db $E1, $27
	db $FF

SFX_SparkShockD:
	db $D1, $11, $F0, $0F
	db $E2
	db $34
	db $C1
	db $44
	db $C1
	db $34
	db $C1
	db $44
	db $C1
	db $FF
	
SFX_ErrorB:
	db $D8, $33, $00, $00, $0E
	db $E1
	db $34
	db $EE, $02
	db $31
	db $FF
SFX_ErrorA:
	db $D8, $33, $00, $00, $0E
	db $E0
	db $B4
	db $EE, $02
	db $B1
	db $FF

SFX_AcceptB:
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
SFX_AcceptA:
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

SFX_TextD:
	db $D1, $00, $00, $0E
	db $E3
	db $71
	db $E8, $11
	db $EE, $08
	db $E0, $01
	db $E8, $00
	db $EE, $04
	db $E3
	db $73
	db $EE, $02
	db $73
	db $FF

SFX_AlarmA:
	db $D5, $22, $00, $00, $0F
	db $EA, $17
	db $E0
	db $59
	db $FF
SFX_AlarmC:
	db $D5, $10, $0E
	db $E1
	db $51
	db $61
	db $71
	db $81
	db $91
	db $A1
	db $B1
	db $E2
	db $01
	db $11
	db $FF

SFX_FortressExplodeA:
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
SFX_FortressExplodeD:
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

SFX_LadderTrapA:
	db $D1, $22, $00, $00, $0F
	db $EA, $14
	db $E0
	db $55
	db $FF
SFX_LadderTrapD:
	db $D3, $00, $C0, $8C, $10, $F0
	db $C2
	db $E3
	db $24
	db $FF

SFX_BlockA:
	db $D6, $22, $F0, $00, $8F, $40, $F0
	db $EA, $67
	db $E1
	db $87
	db $FF
SFX_BlockD:
	db $D6, $00, $C0, $8C, $40, $F0
	db $E3
	db $27
	db $FF

SFX_StompA:
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

SFX_GiantSuzyA:
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

SFX_ScrewCrusherA:
	db $D1, $00, $F0, $00, $0F
	db $EA, $16
	db $E4
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $41
	db $51
	db $61
	db $71
	db $81
	db $91
	db $91
	db $EE, $08
	db $91
	db $91
	db $91
	db $91
	db $EE, $04
	db $91
	db $91
	db $91
	db $91
	db $EE, $02
	db $91
	db $91
	db $FF

SFX_FortressAppearA:
	db $D1, $22, $F0, $00, $05
	db $EA, $15
	db $E1
	db $16
	db $36
	db $EE, $07
	db $46
	db $36
	db $EE, $08
	db $16
	db $36
	db $46
	db $36
	db $EE, $05
	db $16
	db $36
	db $46
	db $36
	db $EE, $03
	db $16
	db $36
	db $46
	db $36
	db $FF
SFX_FortressAppearD:
	db $DF, $00, $F1, $F1, $71, $F0
	db $E3
	db $3D
	db $FF

SFX_RushJetChargeA:
	db $D1, $22, $F0, $00, $0C
	db $EA, $17
	db $E2
	db $05
	db $25
	db $45
	db $65
	db $85
	db $A5
	db $E3
	db $EE, $0A
	db $04
	db $24
	db $EE, $08
	db $44
	db $64
	db $EE, $06
	db $84
	db $A4
	db $EE, $02
	db $84
	db $A4
	db $EE, $01
	db $84
	db $A4
	db $FF

SFX_WilyEscape1A:
	db $D1, $22, $F0, $00, $0C
	db $E2
	db $72
	db $E3
	db $71
	db $E3
	db $42
	db $E4
	db $41
	db $FF

SFX_WilyEscape2A:
	db $D6, $22, $F0, $00, $8F, $70, $F0
	db $EA, $7E
	db $E1
	db $80
	db $FF
SFX_WilyEscape2D:
	db $D1, $00, $F0, $08
	db $E2
	db $F7
	dw SFX_WilyEscape2D_1
	db $EE, $07
	db $F7
	dw SFX_WilyEscape2D_1
	db $EE, $06
	db $F7
	dw SFX_WilyEscape2D_1
	db $EE, $04
	db $F7
	dw SFX_WilyEscape2D_1
	db $EE, $02
	db $F7
	dw SFX_WilyEscape2D_1
	db $EE, $01
	db $F7
	dw SFX_WilyEscape2D_1
	db $FF
SFX_WilyEscape2D_1:
	db $02
	db $12
	db $22
	db $32
	db $42
	db $52
	db $62
	db $72
	db $F9

SFX_Metall_VehicleD:
	db $D1, $11, $00, $0F
	db $E5
	db $73
	db $EE, $08
	db $E8, $11
	db $41
	db $EE, $02
	db $42
	db $FF

SFX_WilyUFOFallD:
	db $D6, $22, $00, $00, $06
	db $EA, $3F
	db $E5
	db $B1
	db $A1
	db $EE, $09
	db $91
	db $81
	db $EE, $0C
	db $71
	db $61
	db $EE, $0B
	db $51
	db $41
	db $EE, $0A
	db $31
	db $21
	db $EE, $09
	db $11, $01
	db $E4
	db $EE, $08
	db $B1
	db $A1
	db $EE, $06
	db $91
	db $81
	db $EE, $04
	db $71
	db $61
	db $EE, $03
	db $51
	db $41
	db $EE, $02
	db $31
	db $21
	db $EE, $01
	db $11
	db $01
	db $FF

SFX_GetWeaponB:
	db $D4, $22, $F0, $00, $02
	db $E5
	db $B1
	db $A1
	db $EE, $04
	db $91
	db $81
	db $EE, $08
	db $71
	db $61
	db $EE, $06
	db $51
	db $41
	db $EE, $04
	db $31
	db $21
	db $EE, $02
	db $11
	db $01
	db $EE, $01
	db $E4
	db $B1
	db $A1
	db $FF
SFX_GetWeaponA:
	db $EF, $01
	db $D2, $22, $F0, $00, $02
	db $E5
	db $C3
	db $B2
	db $A2
	db $EE, $04
	db $92
	db $82
	db $EE
	db $08
	db $72
	db $62
	db $EE, $06
	db $52
	db $42
	db $EE, $04
	db $32
	db $22
	db $EE, $02
	db $12
	db $02
	db $EE, $01
	db $E4
	db $B1
	db $FF

SFX_PunkRumbleA:
	db $D2, $00, $40, $00, $0F
	db $EA, $1B
	db $E2
	db $73
	db $FF
SFX_PunkRumbleD:
	db $D1, $11, $F0, $0F
	db $E5
	db $74
	db $52
	db $EE, $04
	db $42
	db $EE, $02
	db $32
	db $FF

Mus_StageSelectB:
	db $D6, $33, $A1, $43, $9A, $56, $F7
Mus_StageSelectA_1:
	db $EC, $01
	db $FB
	db $F8
	dw Mus_StageSelectB_1
	db $4F
	db $C1
	db $F8
	dw Mus_StageSelectB_1
	db $9F
	db $C1
	db $FD, $00
Mus_StageSelectB_1:
	db $E2
	db $46
	db $91
	db $E3
	db $01
	db $46
	db $21
	db $01
	db $26
	db $01
	db $E2
	db $B1
	db $E3
	db $01
	db $E2
	db $B1
	db $93
	db $C1
	db $91
	db $B1
	db $E3
	db $06
	db $E2
	db $B1
	db $E3
	db $01
	db $E2
	db $B4
	db $74
	db $FA
Mus_StageSelectA:
	db $D6, $33, $61, $43, $96, $72, $F7
	db $C2
	db $EF, $02
	db $F7
	dw Mus_StageSelectA_1
Mus_StageSelectC:
	db $D6, $06, $88, $A4
	db $EC, $01
	db $E1
	db $FB
	db $91
	db $91
	db $71
	db $91
	db $41
	db $71
	db $C1
	db $91
	db $91
	db $71
	db $91
	db $41
	db $71
	db $41
	db $42
	db $91
	db $91
	db $71
	db $91
	db $41
	db $71
	db $C1
	db $41
	db $91
	db $91
	db $71
	db $91
	db $41
	db $71
	db $42
	db $FD, $00
Mus_StageSelectD:
	db $D6
	db $FB
	db $F7
	dw Mus_StageSelectD_1
	db $31
	db $31
	db $22
	db $F7
	dw Mus_StageSelectD_1
	db $11
	db $31
	db $11
	db $11
	db $FD, $00
Mus_StageSelectD_1:
	db $11
	db $11
	db $11
	db $11
	db $31
	db $11
	db $11
	db $11
	db $11
	db $11
	db $31
	db $11
	db $F9
	
Mus_StartB:
	db $D6, $01, $B1, $43, $9A, $16, $F7
	db $E3
	db $01
	db $02
	db $01
	db $E2
	db $A2
	db $E3
	db $0A
	db $21
	db $21
	db $22
	db $21
	db $02
	db $29
	db $31
	db $31
	db $C1
	db $31
	db $C4
	db $61
	db $61
	db $C1
	db $61
	db $C4
	db $C1
	db $72
	db $52
	db $31
	db $51
	db $61
	db $7C
	db $FF
Mus_StartA:
	db $D6, $00, $A1, $43, $9A, $16, $F7
	db $E2
	db $71
	db $72
	db $71
	db $72
	db $7A
	db $A1
	db $A1
	db $A2
	db $A1
	db $82
	db $A9
	db $A1
	db $A1
	db $C1
	db $A1
	db $C4
	db $E3
	db $21
	db $21
	db $C1
	db $21
	db $C4
	db $C1
	db $22
	db $02
	db $E2
	db $A1
	db $E3
	db $01
	db $11
	db $2C
	db $FF
Mus_StartC:
	db $D6, $04, $8A, $B0
	db $E2
	db $08
	db $C2
	db $01
	db $01
	db $01
	db $01
	db $E1
	db $B2
	db $A8
	db $C2
	db $A1
	db $A1
	db $A1
	db $A1
	db $92
	db $61
	db $61
	db $C1
	db $61
	db $C4
	db $91
	db $91
	db $C1
	db $91
	db $C4
	db $F6, $0C
	db $7D
	db $FF
Mus_StartD:
	db $D6
	db $FB
	db $11
	db $11
	db $11
	db $11
	db $31
	db $11
	db $11
	db $11
	db $11
	db $11
	db $11
	db $11
	db $31
	db $31
	db $22
	db $FD, $01
	db $31
	db $32
	db $32
	db $61
	db $72
	db $31
	db $32
	db $32
	db $81
	db $92
	db $11
	db $32
	db $32
	db $31
	db $31
	db $31
	db $38
	db $FF

Mus_ShadowManB:
	db $FC
	db $D6, $01, $B1, $45, $9B, $26, $A5
	db $F7
	dw Mus_ShadowManB_1
	db $F7
	dw Mus_ShadowManB_2
	db $EF, $01
	db $FB
	db $E0
	db $64
	db $94
	db $B8
	db $E1
	db $C2
	db $02
	db $E0
	db $B2
	db $9A
	db $FD, $01
	db $EF, $00
	db $E8, $12
	db $FB
	db $E3
	db $C4
	db $B2
	db $C2
	db $B2
	db $96
	db $B2
	db $E4
	db $12
	db $C2
	db $E3
	db $B2
	db $C2
	db $96
	db $C4
	db $B2
	db $C2
	db $B2
	db $96
	db $E4
	db $32
	db $C4
	db $E3
	db $9A
	db $FD, $01
	db $E8, $01
	db $FB
	db $E1
	db $B2
	db $B2
	db $92
	db $B2
	db $C2
	db $B2
	db $92
	db $B2
	db $F6, $01
	db $E2
	db $02
	db $1A
	db $F6, $06
	db $E1
	db $B2
	db $92
	db $6A
	db $B2
	db $B2
	db $92
	db $B2
	db $C2
	db $F6, $01
	db $E2
	db $52
	db $6A
	db $F6, $06
	db $52
	db $4E
	db $C4
	db $92
	db $92
	db $62
	db $92
	db $C2
	db $92
	db $62
	db $92
	db $F6, $02
	db $A1
	db $BB
	db $F6, $06
	db $E3
	db $14
	db $E2
	db $B2
	db $66
	db $42
	db $42
	db $12
	db $42
	db $C2
	db $F6, $01
	db $82
	db $9A
	db $F6, $06
	db $82
	db $6E
	db $C4
	db $FD, $01
	db $E8, $11
	db $E1
	db $61, $41
	db $62
	db $92
	db $B1
	db $91
	db $B2
	db $E2
	db $12
	db $41
	db $11
	db $42
	db $62
	db $92
	db $B2
	db $E3
	db $1A
	db $FB
	db $E2
	db $81
	db $61
	db $82
	db $62
	db $92
	db $F6, $01
	db $72, $80
	db $F6, $06
	db $41, $C3
	db $E3
	db $13
	db $E2
	db $B2
	db $92
	db $82
	db $F6, $01
	db $52
	db $60
	db $F6, $06
	db $81
	db $C3
	db $41
	db $B4
	db $94
	db $84
	db $63
	db $61
	db $C1
	db $43
	db $42
	db $02
	db $44
	db $64
	db $FD, $01
	db $FE, $00
	db $FF
Mus_ShadowManB_1:
	db $E1
	db $91
	db $61
	db $91
	db $B1
	db $E2
	db $21
	db $01
	db $11
	db $21
	db $C1
	db $61
	db $C1
	db $91
	db $C1
	db $B1
	db $C1
	db $E3
	db $01
	db $F9
Mus_ShadowManB_2:
	db $12
	db $C2
	db $12
	db $C2
	db $12
	db $C2
	db $12
	db $C2
	db $F9
Mus_ShadowManA:
	db $FC
	db $D3, $11, $61, $45, $96, $24, $A5
	db $C1
	db $F6, $06
	db $EF, $01
	db $F7
	dw Mus_ShadowManB_1
	db $F7
	dw Mus_ShadowManB_2
	db $EF, $00
	db $C0
	db $C0
	db $C0
	db $CF
	db $F6, $03
	db $C1
	db $F6, $06
	db $FB
	db $E3
	db $C4
	db $62
	db $C2
	db $62
	db $66
	db $62
	db $62
	db $C2
	db $62
	db $C2
	db $66
	db $C4
	db $62
	db $C2
	db $62
	db $66
	db $32
	db $C4
	db $3A
	db $FD, $01
	db $E3
	db $30
	db $E2
	db $90
	db $E3
	db $3C
	db $E2
	db $94
	db $60
	db $E3
	db $30
	db $E2
	db $90
	db $BC
	db $94
	db $60
	db $EE, $10
	db $FB
	db $F7
	dw Mus_ShadowManA_1
	db $F7
	dw Mus_ShadowManA_1
	db $F7
	dw Mus_ShadowManA_1
	db $E4
	db $41
	db $31
	db $21
	db $11
	db $01
	db $E3
	db $B1
	db $A1
	db $91
	db $FD, $03
	db $EE, $96
	db $26
	db $C4
	db $FB
	db $61
	db $11
	db $41
	db $FD, $08
	db $61
	db $B1
	db $91
	db $81
	db $61
	db $FB
	db $E2
	db $42
	db $42
	db $32
	db $62
	db $43
	db $E1
	db $B1
	db $C3
	db $E2
	db $93
	db $82
	db $62
	db $32
	db $33
	db $41
	db $C3
	db $E1
	db $B1
	db $E2
	db $84
	db $64
	db $44
	db $33
	db $11
	db $C1
	db $03
	db $02
	db $E1
	db $72
	db $E2
	db $04
	db $24
	db $FD, $01
	db $FE, $00
Mus_ShadowManA_1:
	db $E3
	db $61
	db $41
	db $61
	db $91
	db $E4
	db $11
	db $E3
	db $91
	db $61
	db $41
	db $F9
Mus_ShadowManC:
	db $D6
	db $01
	db $8A
	db $B0
	db $FC
	db $F7
	dw Mus_ShadowManB_1
	db $E1
	db $B2
	db $C2
	db $B2
	db $C2
	db $B2
	db $C2
	db $B2
	db $C2
	db $FB
	db $E1
	db $64
	db $94
	db $B8
	db $E2
	db $C2
	db $02
	db $E1
	db $B2
	db $9A
	db $FD, $05
	db $FB
	db $F7
	dw Mus_ShadowManC_1
	db $92
	db $92
	db $E2
	db $42
	db $E1
	db $92
	db $E2
	db $72
	db $62
	db $42
	db $E1
	db $92
	db $F7
	dw Mus_ShadowManC_1
	db $62
	db $62
	db $B2
	db $62
	db $E2
	db $12
	db $E1
	db $B2
	db $92
	db $62
	db $FD, $01
	db $B0
	db $90
	db $FB
	db $F7
	dw Mus_ShadowManC_3
	db $F7
	dw Mus_ShadowManC_3
	db $E1
	db $92
	db $92
	db $61
	db $91
	db $C1
	db $B3
	db $B2
	db $B2
	db $C2
	db $E2
	db $02
	db $02
	db $E1
	db $91
	db $E2
	db $01
	db $C2
	db $24
	db $24
	db $FD, $01
	db $FE, $00
Mus_ShadowManC_1:
	db $E1
	db $F8
	dw Mus_ShadowManC_2
	db $F8
	dw Mus_ShadowManC_2
	db $F8
	dw Mus_ShadowManC_2
	db $F9
Mus_ShadowManC_2:
	db $62
	db $62
	db $B2
	db $62
	db $C2
	db $62
	db $B2
	db $C2
	db $FA
Mus_ShadowManC_3:
	db $E2
	db $42
	db $42
	db $E1
	db $B1
	db $E2
	db $11
	db $C1
	db $23
	db $22
	db $22
	db $C2
	db $F9
Mus_ShadowManD:
	db $D6
	db $FC
	db $31
	db $11
	db $11
	db $11
	db $31
	db $11
	db $11
	db $32
	db $32
	db $32
	db $32
	db $31
	db $34
	db $34
	db $34
	db $34
	db $FB
	db $11
	db $11
	db $22
	db $FD, $0F
	db $FB
	db $11
	db $11
	db $22
	db $32
	db $11
	db $11
	db $FD
	db $2F
	db $FB
	db $34
	db $FD
	db $07
	db $FB
	db $11
	db $11
	db $12
	db $32
	db $11
	db $11
	db $11
	db $11
	db $12
	db $32
	db $12
	db $FD, $07
	db $FE, $00

Mus_Boss1B:
	db $D6, $22, $51, $45, $95, $44, $87
	db $E3
	db $FB
	db $31
	db $41
	db $31
	db $21
	db $FD, $0F
	db $FC
	db $D6, $22, $61, $45, $96, $14, $83
	db $FB
	db $F7
	dw Mus_Boss1B_1
	db $FD, $01
	db $D6, $22, $91, $45, $95, $55, $C7
	db $FB
	db $E2
	db $AC
	db $32
	db $9E
	db $A2
	db $92
	db $8C
	db $32
	db $60
	db $C2
	db $FD, $01
	db $E3
	db $3C
	db $E2
	db $82
	db $E3
	db $10
	db $31
	db $11
	db $E2
	db $BE
	db $B1
	db $A1
	db $74
	db $84
	db $A4
	db $B4
	db $E3
	db $3C
	db $E2
	db $82
	db $E3
	db $40
	db $41
	db $31
	db $1E
	db $11
	db $31
	db $44
	db $74
	db $84
	db $A4
	db $FE, $00
Mus_Boss1B_1:
	db $21
	db $21
	db $C1
	db $31
	db $31
	db $C1
	db $41
	db $41
	db $C1
	db $31
	db $31
	db $C1
	db $21
	db $31
	db $41
	db $C1
	db $F9
Mus_Boss1A:
	db $D6, $11, $A1, $15, $9A, $16, $87
	db $E2
	db $30
	db $A0
	db $90
	db $50
	db $EB, $00
	db $FC
	db $F3, $03
	db $EE, $99, $15, $84
	db $E1
	db $EC, $06
	db $FB
	db $F7
	dw Mus_Boss1B_1
	db $FD, $01
	db $EC, $00
	db $F3, $00
	db $FB
	db $C2
	db $E1
	db $32
	db $52
	db $E0
	db $A2
	db $E1
	db $52
	db $62
	db $32
	db $E0
	db $A2
	db $FD, $07
	db $E1
	db $FB
	db $C2
	db $82
	db $A2
	db $32
	db $A2
	db $B2
	db $82
	db $32
	db $FD, $07
	db $FE, $00
Mus_Boss1C:
	db $D6, $04, $84, $F9
	db $E1
	db $30
	db $A0
	db $90
	db $50
	db $F0, $80
	db $F2, $90
	db $FC
	db $E1
	db $FB
	db $F7
	dw Mus_Boss1B_1
	db $FD, $01
	db $FB
	db $E1
	db $32
	db $32
	db $12
	db $E0
	db $A2
	db $C2
	db $E1
	db $32
	db $12
	db $E0
	db $A2
	db $FD, $07
	db $E1
	db $FB
	db $82
	db $82
	db $62
	db $82
	db $C2
	db $82
	db $62
	db $82
	db $FD, $07
	db $FE, $00
Mus_Boss1D:
	db $D8
	db $FB
	db $21
	db $FD, $17
	db $F6, $06
	db $FB
	db $34
	db $FD, $05
	db $FB
	db $31
	db $FD, $07
	db $FC
	db $FB
	db $31
	db $32
	db $31
	db $32
	db $31
	db $32
	db $31
	db $32
	db $31
	db $31
	db $32
	db $FD, $01
	db $FB
	db $12
	db $12
	db $33
	db $11
	db $12
	db $12
	db $34
	db $FD, $0F
	db $FE, $00

Mus_GeminiManB:
	db $D4, $22, $B1, $45, $9B, $26, $E5
	db $FC
	db $FB
	db $E3
	db $02
	db $C2
	db $32
	db $72
	db $C2
	db $72
	db $C2
	db $02
	db $E2
	db $B2
	db $C2
	db $E3
	db $22
	db $82
	db $C2
	db $82
	db $C2
	db $E2
	db $B2
	db $FD, $01
	db $FB
	db $F7
	dw Mus_GeminiManB_1
	db $F6, $01
	db $33
	db $5D
	db $F6, $04
	db $52
	db $D4, $11, $B6, $45, $9B, $26, $F7
	db $3E
	db $D2, $11, $B6, $45, $06
	db $21
	db $11
	db $01
	db $E2
	db $B1
	db $A1
	db $91
	db $81
	db $71
	db $FD, $02
	db $F7
	dw Mus_GeminiManB_1
	db $F6, $01
	db $73
	db $8D
	db $F6, $04
	db $82
	db $70
	db $C2
	db $F6, $08
	db $FB
	db $E3
	db $08
	db $38
	db $5E
	db $31
	db $51
	db $C1
	db $E2
	db $71
	db $81
	db $B1
	db $E3
	db $01
	db $22
	db $33
	db $F6, $01
	db $26
	db $35
	db $25
	db $F6, $08
	db $02
	db $E2
	db $B1
	db $E3
	db $01
	db $E2
	db $70
	db $FD, $01
	db $E3
	db $58
	db $F6, $0C
	db $80
	db $F6, $04
	db $C2
	db $E2
	db $72
	db $82
	db $A2
	db $E3
	db $04
	db $E2
	db $A2
	db $8E
	db $F6, $08
	db $7A
	db $34
	db $04
	db $F6, $04
	db $C4
	db $54
	db $74
	db $84
	db $A2
	db $E3
	db $04
	db $14
	db $34
	db $54
	db $32
	db $54
	db $32
	db $54
	db $32
	db $5C
	db $A2
	db $82
	db $73
	db $C1
	db $02
	db $F7
	dw Mus_GeminiManB_2
	db $E4
	db $03
	db $C1
	db $32
	db $F7
	dw Mus_GeminiManB_2
	db $E8, $22
	db $FE, $00
Mus_GeminiManB_1:
	db $D4, $11, $B1, $45, $9B, $26, $E5
	db $E3
	db $C2
	db $02
	db $32
	db $53
	db $C1
	db $53
	db $C1
	db $53
	db $C1
	db $71
	db $51
	db $33
	db $C1
	db $54
	db $32
	db $54
	db $36
	db $F9
Mus_GeminiManB_2:
	db $53
	db $C1
	db $53
	db $C1
	db $02
	db $32
	db $51
	db $31
	db $02
	db $53
	db $C1
	db $53
	db $C1
	db $02
	db $F9
Mus_GeminiManA:
	db $FC
	db $D4, $22, $91, $44, $97, $25, $E5
	db $E3
	db $FB
	db $70
	db $60
	db $FD, $01
	db $FB
	db $F7
	dw Mus_GeminiManA_1
	db $D4, $11, $96, $44, $99, $24, $F7
	db $0E
	db $D2, $11, $96, $44, $04
	db $E2
	db $B1
	db $A1
	db $91
	db $81
	db $71
	db $61
	db $51
	db $41
	db $FD, $02
	db $F7
	dw Mus_GeminiManA_1
	db $E2
	db $B0
	db $C2
	db $D8, $11, $91, $23, $97, $25, $E5
	db $FB
	db $E2
	db $70
	db $E3
	db $10
	db $30
	db $00
	db $FD, $01
	db $08
	db $58
	db $6F
	db $B1
	db $E4
	db $0C
	db $34
	db $28
	db $E3
	db $A8
	db $F6, $0C
	db $E4
	db $00
	db $F6, $08
	db $E3
	db $56
	db $51
	db $51
	db $00
	db $D4, $11, $B1, $45, $9B, $26, $E5
	db $E2
	db $03
	db $C1
	db $32
	db $F7
	dw Mus_GeminiManB_2
	db $FE, $00
Mus_GeminiManA_1:
	db $D4, $11, $91, $44, $99, $24, $E5
	db $E2
	db $C2
	db $72
	db $E3
	db $02
	db $03
	db $C1
	db $03
	db $C1
	db $03
	db $C1
	db $31
	db $21
	db $03
	db $C1
	db $04
	db $02
	db $04
	db $06
	db $04
	db $02
	db $F9
Mus_GeminiManC:
	db $D4, $01, $81, $C9
	db $FC
	db $FB
	db $F7
	dw Mus_GeminiManC_1
	db $FD, $08
	db $C2
	db $E1
	db $B6
	db $E2
	db $04
	db $02
	db $F2, $F9
	db $20
	db $C2
	db $F2, $C9
	db $FB
	db $F7
	dw Mus_GeminiManC_1
	db $FD, $07
	db $E2
	db $52
	db $C2
	db $82
	db $E3
	db $02
	db $C2
	db $02
	db $C2
	db $E2
	db $52
	db $42
	db $C2
	db $82
	db $E3
	db $02
	db $C2
	db $02
	db $C2
	db $E2
	db $42
	db $FB
	db $12
	db $C2
	db $52
	db $A2
	db $C2
	db $A2
	db $C2
	db $12
	db $FD, $01
	db $FB
	db $E2
	db $52
	db $C2
	db $82
	db $E3
	db $02
	db $C2
	db $02
	db $C2
	db $E2
	db $52
	db $FD, $01
	db $FB
	db $42
	db $C2
	db $82
	db $E3
	db $02
	db $C2
	db $02
	db $C2
	db $E2
	db $42
	db $FD, $01
	db $FB
	db $12
	db $C2
	db $52
	db $82
	db $C2
	db $82
	db $C2
	db $12
	db $FD, $03
	db $FB
	db $F7
	dw Mus_GeminiManC_1
	db $FD, $01
	db $FE, $00
Mus_GeminiManC_1:
	db $E2
	db $02
	db $C2
	db $32
	db $72
	db $C2
	db $72
	db $C2
	db $02
	db $E1
	db $B2
	db $E2
	db $C2
	db $22
	db $82
	db $C2
	db $82
	db $C2
	db $E1
	db $B2
	db $F9
Mus_GeminiManD:
	db $D4
	db $FC
	db $FB
	db $52
	db $12
	db $32
	db $12
	db $52
	db $12
	db $34
	db $52
	db $12
	db $32
	db $12
	db $52
	db $52
	db $34
	db $FD, $01
	db $FB
	db $F7
	dw Mus_GeminiManD_1
	db $FD, $06
	db $C2
	db $34
	db $32
	db $34
	db $32
	db $32
	db $C2
	db $31
	db $31
	db $32
	db $32
	db $32
	db $32
	db $32
	db $32
	db $FB
	db $F7
	dw Mus_GeminiManD_1
	db $FD, $0E
	db $12
	db $12
	db $32
	db $54
	db $52
	db $32
	db $12
	db $52
	db $12
	db $32
	db $52
	db $32
	db $32
	db $32
	db $32
	db $FE, $00
Mus_GeminiManD_1:
	db $12
	db $12
	db $32
	db $54
	db $52
	db $32
	db $12
	db $52
	db $12
	db $32
	db $52
	db $52
	db $52
	db $32
	db $52
	db $F9

Mus_SnakeManB:
	db $D6, $10, $B1, $45, $9B, $26, $E5
	db $E3
	db $FB
	db $F7
	dw Mus_SnakeManB_2
	db $FD, $01
	db $FC
	db $D6, $10, $B1, $45, $9B, $26, $E5
	db $F7
	dw Mus_SnakeManB_1
	db $83
	db $81
	db $71
	db $C1
	db $54
	db $01
	db $C1
	db $31
	db $C1
	db $51
	db $C1
	db $53
	db $51
	db $31
	db $C1
	db $04
	db $E2
	db $A1
	db $C1
	db $81
	db $C1
	db $71
	db $C1
	db $F7
	dw Mus_SnakeManB_1
	db $53
	db $51
	db $31
	db $C1
	db $54
	db $81
	db $C1
	db $71
	db $C1
	db $51
	db $C1
	db $53
	db $51
	db $31
	db $C1
	db $53
	db $51
	db $31
	db $C1
	db $51
	db $C1
	db $31
	db $C1
	db $D6, $12, $B1, $45, $9B, $36, $E5
	db $E2
	db $52
	db $51
	db $81
	db $51
	db $32
	db $51
	db $C2
	db $84
	db $51
	db $31
	db $52
	db $51
	db $81
	db $51
	db $32
	db $51
	db $C2
	db $84
	db $51
	db $81
	db $E3
	db $02
	db $E2
	db $A1
	db $A1
	db $C1
	db $81
	db $C1
	db $81
	db $C1
	db $51
	db $C1
	db $51
	db $82
	db $A2
	db $A2
	db $52
	db $51
	db $32
	db $59
	db $82
	db $72
	db $71
	db $32
	db $05
	db $32
	db $52
	db $82
	db $72
	db $71
	db $32
	db $01
	db $C1
	db $A3
	db $82
	db $72
	db $82
	db $72
	db $51
	db $32
	db $51
	db $C1
	db $E3
	db $83
	db $72
	db $52
	db $72
	db $52
	db $71
	db $82
	db $59
	db $E8, $22
	db $E2
	db $33
	db $32
	db $C1
	db $02
	db $72
	db $82
	db $72
	db $32
	db $53
	db $52
	db $C1
	db $32
	db $58
	db $73
	db $72
	db $C1
	db $72
	db $72
	db $82
	db $A2
	db $72
	db $E3
	db $13
	db $12
	db $C1
	db $02
	db $08
	db $E2
	db $A3
	db $A2
	db $C1
	db $82
	db $72
	db $E3
	db $12
	db $02
	db $E2
	db $72
	db $84
	db $A4
	db $E3
	db $08
	db $59
	db $41
	db $31
	db $21
	db $11
	db $01
	db $E2
	db $A1
	db $81
	db $E3
	db $13
	db $12
	db $C1
	db $02
	db $08
	db $FE, $00
Mus_SnakeManB_1:
	db $E2
	db $53
	db $51
	db $71
	db $C1
	db $84
	db $A1
	db $C1
	db $E3
	db $01
	db $C1
	db $21
	db $C1
	db $33
	db $31
	db $C2
	db $2A
	db $F9
Mus_SnakeManB_2:
	db $61
	db $61
	db $C1
	db $61
	db $61
	db $C1
	db $61
	db $61
	db $C1
	db $61
	db $61
	db $C1
	db $71
	db $C1
	db $71
	db $C1
	db $F9
Mus_SnakeManA:
	db $D6, $10, $B1, $45, $9B, $16, $E5
	db $E3
	db $EC, $FB
	db $FB
	db $F7
	dw Mus_SnakeManB_2
	db $FD, $01
	db $EC, $00
	db $EF, $01
	db $FC
	db $D6, $00, $81, $45, $98, $16, $E5
	db $C1
	db $F7
	dw Mus_SnakeManA_1
	db $83
	db $81
	db $72
	db $54
	db $02
	db $32
	db $52
	db $53
	db $51
	db $32
	db $04
	db $E2
	db $A2
	db $82
	db $72
	db $F7
	dw Mus_SnakeManA_1
	db $53
	db $51
	db $32
	db $54
	db $82
	db $72
	db $52
	db $53
	db $51
	db $32
	db $53
	db $51
	db $32
	db $52
	db $31
	db $D6, $22, $81, $45, $11
	db $F3, $00
	db $E2
	db $FB
	db $52
	db $51
	db $82
	db $81
	db $A2
	db $FD, $07
	db $FB
	db $02
	db $01
	db $32
	db $31
	db $52
	db $FD, $03
	db $FB
	db $52
	db $51
	db $82
	db $81
	db $A2
	db $FD, $03
	db $F3, $03
	db $D6, $11, $81, $45, $96, $14, $E5
	db $E2
	db $AC
	db $E3
	db $04
	db $E2
	db $50
	db $E2
	db $AC
	db $74
	db $30
	db $06
	db $01
	db $21
	db $46
	db $51
	db $71
	db $86
	db $81
	db $A1
	db $E3
	db $08
	db $E2
	db $56
	db $52
	db $52
	db $72
	db $82
	db $52
	db $E3
	db $16
	db $02
	db $08
	db $FE, $00
Mus_SnakeManA_1:
	db $E2
	db $53
	db $51
	db $72
	db $84
	db $A2
	db $E3
	db $02
	db $22
	db $33
	db $31
	db $C2
	db $2A
	db $F9
Mus_SnakeManC:
	db $D6, $01, $81, $89
	db $E2
	db $FB
	db $61
	db $61
	db $C1
	db $61
	db $61
	db $C1
	db $61
	db $61
	db $C1
	db $61
	db $61
	db $C1
	db $51
	db $C1
	db $51
	db $C1
	db $FD, $01
	db $FC
	db $F2, $A9
	db $FB
	db $52
	db $51
	db $32
	db $31
	db $02
	db $52
	db $51
	db $32
	db $31
	db $02
	db $A2
	db $A1
	db $82
	db $81
	db $52
	db $A2
	db $A1
	db $82
	db $81
	db $52
	db $12
	db $11
	db $52
	db $51
	db $82
	db $12
	db $11
	db $52
	db $51
	db $82
	db $32
	db $31
	db $72
	db $71
	db $A2
	db $32
	db $31
	db $72
	db $71
	db $A2
	db $FD, $01
	db $FB
	db $53
	db $51
	db $C2
	db $52
	db $52
	db $72
	db $82
	db $A2
	db $FD, $01
	db $FB
	db $13
	db $11
	db $C2
	db $12
	db $12
	db $32
	db $52
	db $82
	db $FD, $01
	db $FB
	db $33
	db $31
	db $C2
	db $32
	db $32
	db $52
	db $72
	db $A2
	db $FD, $01
	db $FB
	db $53
	db $51
	db $C2
	db $52
	db $52
	db $72
	db $82
	db $A2
	db $FD, $01
	db $F2, $C9
	db $03
	db $01
	db $C2
	db $02
	db $03
	db $01
	db $C2
	db $02
	db $53
	db $51
	db $C2
	db $52
	db $52
	db $82
	db $72
	db $52
	db $33
	db $31
	db $C2
	db $32
	db $33
	db $31
	db $C2
	db $32
	db $83
	db $81
	db $C2
	db $82
	db $82
	db $E3
	db $02
	db $E2
	db $A2
	db $82
	db $73
	db $71
	db $C2
	db $72
	db $73
	db $71
	db $C2
	db $72
	db $54
	db $44
	db $34
	db $24
	db $13
	db $11
	db $C2
	db $12
	db $13
	db $11
	db $C2
	db $12
	db $03
	db $01
	db $C2
	db $A2
	db $E3
	db $02
	db $E2
	db $A2
	db $82
	db $A2
	db $FE, $00
Mus_SnakeManD:
	db $D6
	db $FB
	db $31
	db $32
	db $31
	db $32
	db $31
	db $32
	db $31
	db $32
	db $32
	db $32
	db $FD, $01
	db $FC
	db $FB
	db $51
	db $11
	db $12
	db $31
	db $11
	db $12
	db $FD, $0F
	db $FB
	db $51
	db $11
	db $11
	db $51
	db $31
	db $11
	db $11
	db $51
	db $51
	db $11
	db $51
	db $11
	db $31
	db $11
	db $11
	db $11
	db $FD, $07
	db $FB
	db $51
	db $11
	db $12
	db $31
	db $11
	db $12
	db $FD, $0F
	db $FE, $00

Mus_SparkManB:
	db $D6, $12, $B1, $25, $9B, $26, $95
	db $FB
	db $E2
	db $26
	db $21
	db $51
	db $A4
	db $93
	db $51
	db $76
	db $51
	db $41
	db $52
	db $41
	db $21
	db $42
	db $21
	db $01
	db $76
	db $71
	db $91
	db $A4
	db $93
	db $A1
	db $E3
	db $06
	db $E2
	db $A1
	db $E3
	db $01
	db $22
	db $02
	db $E2
	db $A2
	db $92
	db $FD, $01
	db $E8, $11
	db $FC
	db $FB
	db $E2
	db $74
	db $73
	db $51
	db $72
	db $A4
	db $21
	db $51
	db $74
	db $73
	db $51
	db $72
	db $A4
	db $71
	db $A1
	db $E3
	db $02
	db $02
	db $01
	db $E2
	db $A2
	db $E3
	db $09
	db $33
	db $43
	db $51
	db $C1
	db $63
	db $73
	db $81
	db $C1
	db $FD, $01
	db $E8, $22
	db $F7
	dw Mus_SparkManB_1
	db $33
	db $53
	db $72
	db $52
	db $32
	db $21
	db $E2
	db $B3
	db $E3
	db $F7
	dw Mus_SparkManB_1
	db $E8, $11
	db $E2
	db $A1
	db $C1
	db $A1
	db $C1
	db $A1
	db $A1
	db $C1
	db $A1
	db $A4
	db $B4
	db $FE, $00
Mus_SparkManB_1:
	db $72
	db $51
	db $C1
	db $32
	db $21
	db $C1
	db $31
	db $21
	db $C1
	db $05
	db $52
	db $31
	db $C1
	db $22
	db $01
	db $C1
	db $01
	db $E2
	db $B1
	db $C1
	db $E3
	db $23
	db $E2
	db $72
	db $E3
	db $33
	db $53
	db $72
	db $33
	db $53
	db $72
	db $F9
Mus_SparkManA:
	db $D6, $22, $B1, $45, $11
	db $EF, $01
	db $E2
	db $FB
	db $91
	db $A1
	db $91
	db $71
	db $FD, $1D
	db $91
	db $A1
	db $E3
	db $01
	db $21
	db $31
	db $51
	db $71
	db $91
	db $D6, $00, $A1, $45, $9A, $25, $A5
	db $FC
	db $F7
	dw Mus_SparkManA_1
	db $F7
	dw Mus_SparkManA_1
	db $F3, $03
	db $D6, $11, $91, $45, $95, $15, $C5
	db $00
	db $3C
	db $24
	db $E2
	db $70
	db $E3
	db $5C
	db $34
	db $00
	db $3C
	db $24
	db $E2
	db $70
	db $D6, $00, $91, $45, $99, $15, $A5
	db $E2
	db $51
	db $C1
	db $51
	db $C1
	db $51
	db $51
	db $C1
	db $51
	db $54
	db $64
	db $FE, $00
Mus_SparkManA_1:
	db $F3, $00
	db $FB
	db $E2
	db $72
	db $22
	db $51
	db $72
	db $71
	db $FD, $05
	db $F3, $02
	db $A3
	db $B3
	db $E3
	db $01
	db $C1
	db $F3, $01
	db $13
	db $23
	db $31
	db $C1
	db $F9
Mus_SparkManC:
	db $D6, $01, $81, $89
	db $E2
	db $FC
	db $FB
	db $72
	db $71
	db $71
	db $FD, $03
	db $FB
	db $02
	db $01
	db $01
	db $FD, $03
	db $FB
	db $32
	db $31
	db $31
	db $FD, $03
	db $FB
	db $52
	db $51
	db $51
	db $FD, $03
	db $FE, $01
	db $FC
	db $F7
	dw Mus_SparkManC_2
	db $EC, $01
	db $F7
	dw Mus_SparkManC_2
	db $EC, $00
	db $F7
	dw Mus_SparkManC_2
	db $EC, $01
	db $F7
	dw Mus_SparkManC_2
	db $EC, $00
	db $F7
	dw Mus_SparkManC_1
	db $82
	db $81
	db $81
	db $82
	db $81
	db $81
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $F7
	dw Mus_SparkManC_1
	db $A2
	db $A2
	db $A1
	db $A2
	db $A1
	db $F2, $C9
	db $A4
	db $B4
	db $F2, $89
	db $FE, $00
Mus_SparkManC_1:
	db $02
	db $01
	db $01
	db $02
	db $01
	db $01
	db $52
	db $51
	db $51
	db $52
	db $51
	db $51
	db $22
	db $21
	db $21
	db $22
	db $21
	db $21
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $E3
	db $02
	db $01
	db $01
	db $02
	db $01
	db $01
	db $E2
	db $A2
	db $A1
	db $A1
	db $A2
	db $A1
	db $A1
	db $F9
Mus_SparkManC_2:
	db $FB
	db $72
	db $71
	db $71
	db $C2
	db $71
	db $71
	db $FD, $03
	db $F9
Mus_SparkManD:
	db $D6
	db $FB
	db $32
	db $11
	db $11
	db $FD, $0F
	db $61
	db $61
	db $82
	db $92
	db $11
	db $11
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $32
	db $63
	db $83
	db $61
	db $61
	db $82
	db $61
	db $61
	db $82
	db $FB
	db $32
	db $11
	db $11
	db $FD, $03
	db $61
	db $61
	db $82
	db $61
	db $61
	db $82
	db $81
	db $61
	db $61
	db $81
	db $81
	db $61
	db $81
	db $31
	db $FC
	db $FB
	db $32
	db $11
	db $11
	db $42
	db $11
	db $11
	db $FD, $0F
	db $FB
	db $52
	db $11
	db $11
	db $32
	db $11
	db $51
	db $11
	db $51
	db $12
	db $32
	db $11
	db $11
	db $FD, $06
	db $32
	db $32
	db $31
	db $32
	db $31
	db $31
	db $11
	db $11
	db $31
	db $31
	db $11
	db $11
	db $31
	db $FE, $00

Mus_EndGameB:
	db $F6, $09
	db $C0
	db $CC
	db $EC, $02
	db $FB
	db $D9, $01, $B2, $23, $98, $26, $C2
	db $F7
	dw Mus_EndGameB_1
	db $9C
	db $E8, $22
	db $F7
	dw Mus_EndGameB_1
	db $90
	db $D9, $11, $B2, $23, $9A, $36, $B3
	db $E3
	db $0C
	db $03
	db $21
	db $E2
	db $B1
	db $91
	db $7E
	db $AC
	db $A3
	db $E3
	db $01
	db $E2
	db $91
	db $71
	db $5A
	db $91
	db $B3
	db $E3
	db $0C
	db $01
	db $23
	db $3C
	db $31
	db $53
	db $73
	db $73
	db $72
	db $73
	db $73
	db $72
	db $74
	db $C8
	db $FD, $00
Mus_EndGameB_1:
	db $E3
	db $42
	db $52
	db $E2
	db $94
	db $E3
	db $22
	db $02
	db $E2
	db $B2
	db $72
	db $E3
	db $03
	db $21
	db $4C
	db $42
	db $52
	db $E2
	db $94
	db $E3
	db $22
	db $02
	db $E2
	db $B2
	db $72
	db $E3
	db $53
	db $71
	db $4C
	db $42
	db $52
	db $E2
	db $94
	db $E3
	db $22
	db $02
	db $E2
	db $B2
	db $72
	db $E3
	db $02
	db $22
	db $44
	db $24
	db $14
	db $42
	db $52
	db $E2
	db $94
	db $E3
	db $22
	db $02
	db $E2
	db $B2
	db $92
	db $73
	db $41
	db $F9
Mus_EndGameA:
	db $F6, $09
	db $C0
	db $CC
	db $EC, $02
	db $FB
	db $D9, $11, $81, $23, $96, $26, $C2
	db $EF, $01
	db $C1
	db $F7
	dw Mus_EndGameB_1
	db $9C
	db $E8, $22
	db $F7
	dw Mus_EndGameB_1
	db $9F
	db $EF, $00
	db $D9, $22, $A2, $23, $99, $36, $B3
	db $E2
	db $94
	db $58
	db $93
	db $91
	db $42
	db $4E
	db $54
	db $28
	db $23
	db $51
	db $02
	db $0A
	db $01
	db $23
	db $4C
	db $41
	db $53
	db $7C
	db $71
	db $93
	db $B3
	db $B3
	db $B2
	db $B3
	db $B3
	db $B2
	db $B4
	db $C8
	db $FD, $00
Mus_EndGameC:
	db $EC, $02
	db $D9, $06, $88, $8F
	db $C0
	db $C0
	db $FC
	db $FB
	db $E1
	db $54
	db $54
	db $74
	db $74
	db $94
	db $94
	db $94
	db $C4
	db $54
	db $54
	db $74
	db $74
	db $E2
	db $04
	db $04
	db $04
	db $C4
	db $E1
	db $54
	db $54
	db $74
	db $74
	db $F2, $C9
	db $E2
	db $04
	db $E1
	db $A4
	db $98
	db $F2, $8F
	db $24
	db $24
	db $44
	db $44
	db $94
	db $94
	db $94
	db $C4
	db $FD, $01
	db $E2
	db $24
	db $24
	db $24
	db $24
	db $04
	db $04
	db $04
	db $04
	db $E1
	db $A4
	db $A4
	db $A4
	db $A4
	db $54
	db $54
	db $54
	db $51
	db $F2, $C9
	db $73
	db $F2, $8F
	db $94
	db $94
	db $94
	db $91
	db $F2, $C9
	db $A3
	db $F2, $8F
	db $34
	db $34
	db $34
	db $31
	db $F2, $C9
	db $53
	db $F2, $8F
	db $73
	db $73
	db $72
	db $73
	db $73
	db $72
	db $74
	db $CC
	db $FE, $00
Mus_EndGameD:
	db $D3
	db $36
	db $36
	db $31
	db $31
	db $31
	db $31
	db $32
	db $33
	db $33
	db $33
	db $33
	db $36
	db $31
	db $31
	db $31
	db $31
	db $32
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $3C
	db $CC
	db $FC
	db $F7
	dw Mus_EndGameD_1
	db $F7
	dw Mus_EndGameD_1
	db $D9
	db $FB
	db $32
	db $31
	db $31
	db $32
	db $31
	db $31
	db $32
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $FD, $02
	db $32
	db $31
	db $31
	db $32
	db $31
	db $31
	db $34
	db $31
	db $23
	db $32
	db $31
	db $31
	db $32
	db $31
	db $31
	db $34
	db $31
	db $23
	db $32
	db $31
	db $31
	db $32
	db $31
	db $31
	db $34
	db $31
	db $23
	db $22
	db $31
	db $22
	db $31
	db $22
	db $22
	db $31
	db $22
	db $31
	db $22
	db $24
	db $14
	db $14
	db $14
	db $D3
	db $FE, $00
Mus_EndGameD_1:
	db $FB
	db $F8
	dw Mus_EndGameD_2
	db $36
	db $36
	db $CC
	db $FD, $01
	db $FB
	db $36
	db $36
	db $31
	db $31
	db $31
	db $31
	db $32
	db $33
	db $33
	db $FD, $01
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $3C
	db $CC
	db $F8
	dw Mus_EndGameD_2
	db $3C
	db $CC
	db $F9
Mus_EndGameD_2:
	db $36
	db $36
	db $31
	db $31
	db $31
	db $31
	db $32
	db $33
	db $33
	db $36
	db $36
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $32
	db $33
	db $36
	db $36
	db $31
	db $31
	db $31
	db $31
	db $32
	db $33
	db $33
	db $FA

Mus_GameOverB:
	db $D6, $21, $B2, $25, $9B, $26, $C2
	db $EC, $01
	db $E2
	db $92
	db $42
	db $92
	db $E3
	db $4A
	db $C2
	db $E2
	db $B2
	db $C2
	db $E3
	db $02
	db $E2
	db $C2
	db $B2
	db $C2
	db $72
	db $E3
	db $04
	db $02
	db $24
	db $22
	db $40
	db $FF
Mus_GameOverA:
	db $D6, $11, $A2, $25, $9A, $25, $C2
	db $EC, $01
	db $F3, $00
	db $EF, $01
	db $E2
	db $C1
	db $92
	db $42
	db $92
	db $E3
	db $43
	db $EF, $00
	db $E2
	db $92
	db $42
	db $92
	db $E3
	db $42
	db $F3, $03
	db $E2
	db $72
	db $C2
	db $72
	db $C2
	db $72
	db $C2
	db $22
	db $94
	db $92
	db $B4
	db $B2
	db $E3
	db $00
	db $FF
Mus_GameOverC:
	db $D6, $04, $84, $C8
	db $EC, $01
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
	db $91
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $71
	db $71
	db $72
	db $54
	db $52
	db $74
	db $72
	db $F2, $F8
	db $90
	db $FF
Mus_GameOverD:
	db $D6
	db $FB
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FD, $02
	db $12
	db $11
	db $11
	db $31
	db $31
	db $32
	db $32
	db $12
	db $12
	db $32
	db $12
	db $12
	db $34
	db $FF

Mus_Boss2B:
	db $FC
	db $DB, $12, $B3, $43, $9B, $13, $F1
	db $E3
	db $FB
	db $31
	db $01
	db $31
	db $01
	db $31
	db $01
	db $31
	db $01
	db $61
	db $31
	db $61
	db $31
	db $61
	db $31
	db $61
	db $31
	db $FD, $01
	db $DB, $11, $B1, $14, $95, $46, $C4
	db $F7
	dw Mus_Boss2B_1
	db $E2
	db $64
	db $E3
	db $F6, $04
	db $61
	db $7A
	db $F6, $0B
	db $E2
	db $74
	db $F7
	dw Mus_Boss2B_1
	db $74
	db $84
	db $94
	db $FE, $00
Mus_Boss2B_1:
	db $E2
	db $63
	db $F6, $01
	db $96
	db $E3
	db $35
	db $F6, $0B
	db $04
	db $14
	db $34
	db $64
	db $F9
Mus_Boss2A:
	db $DB, $11, $92, $43, $99, $12, $F1
	db $EC, $04
	db $FC
	db $E2
	db $FB
	db $81
	db $51
	db $81
	db $51
	db $81
	db $51
	db $81
	db $51
	db $B1
	db $81
	db $B1
	db $81
	db $B1
	db $81
	db $B1
	db $81
	db $FD, $01
	db $E1
	db $FB
	db $81
	db $51
	db $81
	db $51
	db $81
	db $51
	db $81
	db $51
	db $91
	db $61
	db $91
	db $61
	db $91
	db $61
	db $91
	db $61
	db $FD, $03
	db $FE, $00
Mus_Boss2C:
	db $DB, $01, $88, $A8
	db $E2
	db $FC
	db $FB
	db $F7
	dw Mus_Boss2C_1
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $F7
	dw Mus_Boss2C_1
	db $91
	db $91
	db $91
	db $91
	db $91
	db $91
	db $91
	db $91
	db $FD, $01
	db $F7
	dw Mus_Boss2C_1
	db $FB
	db $31
	db $FD, $07
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
	db $81
	db $81
	db $91
	db $91
	db $91
	db $91
	db $FE, $00
Mus_Boss2C_1:
	db $61
	db $61
	db $61
	db $61
	db $61
	db $61
	db $61
	db $61
	db $F9
Mus_Boss2D:
	db $DB
	db $FC
	db $FB
	db $12
	db $FD, $07
	db $32
	db $32
	db $32
	db $32
	db $F6, $01
	db $36
	db $35
	db $3B
	db $36
	db $35
	db $3B
	db $FB
	db $36
	db $35
	db $FD, $03
	db $F6, $0B
	db $FB
	db $31
	db $21
	db $FD, $1B
	db $F6, $01
	db $FB
	db $36
	db $35
	db $FD, $07
	db $F6, $0B
	db $FE, $00

Mus_VictoryB:
	db $D6, $01, $B2, $33, $9B, $26, $A4
	db $F7
	dw Mus_VictoryC_1
	db $AD
	db $FF
Mus_VictoryA:
	db $D6, $11, $A2, $33, $9A, $25, $A4
	db $E2
	db $B1
	db $B1
	db $E3
	db $C2
	db $11
	db $11
	db $C2
	db $31
	db $31
	db $C2
	db $51
	db $31
	db $51
	db $7D
	db $FF
Mus_VictoryC:
	db $D6, $06, $86, $A0
	db $EC, $ED
	db $F7
	dw Mus_VictoryC_1
	db $F2, $E0
	db $AD
	db $FF
Mus_VictoryC_1:
	db $E3
	db $31
	db $31
	db $C2
	db $51
	db $51
	db $C2
	db $61
	db $61
	db $C2
	db $81
	db $61
	db $81
	db $F9
Mus_VictoryD:
	db $D6
	db $FB
	db $31
	db $31
	db $62
	db $FD, $02
	db $31
	db $31
	db $31
	db $31
	db $D4
	db $FB
	db $11
	db $FD, $0C
	db $FF

Mus_CreditsB:
	db $D6, $01, $B3, $43, $9B, $26, $A4
	db $FC
	db $E3
	db $C0
	db $FB
	db $F7
	dw Mus_CreditsB_1
	db $44
	db $42
	db $62
	db $C2
	db $62
	db $C2
	db $80
	db $C2
	db $FD, $01
	db $E8, $22
	db $F7
	dw Mus_CreditsB_2
	db $C3
	db $F6, $06
	db $E8, $01
	db $E3
	db $F7
	dw Mus_CreditsB_1
	db $32
	db $32
	db $12
	db $32
	db $C2
	db $32
	db $62
	db $82
	db $C2
	db $32
	db $62
	db $82
	db $C2
	db $32
	db $62
	db $82
	db $FE, $00
Mus_CreditsB_1:
	db $82
	db $81
	db $81
	db $82
	db $81
	db $81
	db $82
	db $A2
	db $C2
	db $6E
	db $C2
	db $62
	db $44
	db $42
	db $12
	db $C2
	db $12
	db $C2
	db $38
	db $32
	db $42
	db $66
	db $82
	db $81
	db $81
	db $82
	db $81
	db $81
	db $82
	db $A2
	db $C2
	db $6E
	db $C2
	db $62
	db $F9
Mus_CreditsB_2:
	db $C2
	db $82
	db $32
	db $02
	db $E4
	db $02
	db $E3
	db $82
	db $32
	db $E4
	db $34
	db $12
	db $02
	db $E3
	db $A2
	db $E4
	db $02
	db $12
	db $C2
	db $E3
	db $62
	db $C2
	db $62
	db $12
	db $E2
	db $A2
	db $E3
	db $A4
	db $62
	db $32
	db $61
	db $51
	db $11
	db $A1
	db $61
	db $31
	db $E4
	db $11
	db $01
	db $E3
	db $A8
	db $C2
	db $51
	db $81
	db $51
	db $01
	db $E2
	db $82
	db $E3
	db $51
	db $81
	db $51
	db $01
	db $E2
	db $82
	db $E3
	db $51
	db $81
	db $E4
	db $41
	db $51
	db $41
	db $51
	db $41
	db $51
	db $41
	db $01
	db $E3
	db $88
	db $F6, $08
	db $E2
	db $B1
	db $E3
	db $41
	db $81
	db $41
	db $81
	db $B1
	db $81
	db $B1
	db $E4
	db $4D
	db $F9
Mus_CreditsA:
	db $D6, $01, $A3, $43, $9A, $25, $A5
	db $FC
	db $E3
	db $C0
	db $FB
	db $F7
	dw Mus_CreditsA_1
	db $E2
	db $B4
	db $B2
	db $A2
	db $E3
	db $C2
	db $12
	db $C2
	db $00
	db $C2
	db $FD, $01
	db $E8, $22
	db $EF, $01
	db $C1
	db $F7
	dw Mus_CreditsB_2
	db $F6, $06
	db $C3
	db $EF, $00
	db $E8, $11
	db $E3
	db $F7
	dw Mus_CreditsA_1
	db $EF, $01
	db $32
	db $32
	db $12
	db $32
	db $EF, $00
	db $C2
	db $02
	db $12
	db $32
	db $C2
	db $02
	db $12
	db $32
	db $C2
	db $02
	db $12
	db $32
	db $FE, $00
Mus_CreditsA_1:
	db $32
	db $31
	db $31
	db $32
	db $31
	db $31
	db $32
	db $52
	db $C2
	db $1E
	db $C2
	db $12
	db $E2
	db $B4
	db $B2
	db $82
	db $C2
	db $A2
	db $C2
	db $E3
	db $08
	db $02
	db $12
	db $36
	db $32
	db $31
	db $31
	db $32
	db $31
	db $31
	db $32
	db $52
	db $C2
	db $1E
	db $C2
	db $12
	db $F9
Mus_CreditsC:
	db $D6, $01, $82, $A0
	db $EC, $0C
	db $FC
	db $C0
	db $E1
	db $FB
	db $82
	db $81
	db $81
	db $FD, $18
	db $82
	db $A1
	db $A1
	db $A2
	db $A1
	db $A1
	db $A2
	db $F2, $D0
	db $84
	db $F2, $A0
	db $81
	db $81
	db $FB
	db $82
	db $81
	db $81
	db $FD, $1B
	db $82
	db $A2
	db $A2
	db $A1
	db $A1
	db $A2
	db $E2
	db $F2, $D0
	db $04
	db $F2, $A0
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
	db $01
	db $E1
	db $F2, $D0
	db $82
	db $CE
	db $CA
	db $86
	db $62
	db $CE
	db $CA
	db $66
	db $52
	db $CE
	db $CA
	db $56
	db $F2, $A0
	db $FB
	db $42
	db $41
	db $41
	db $FD, $05
	db $F2, $D0
	db $C2
	db $66
	db $F2, $A0
	db $FB
	db $82
	db $81
	db $81
	db $FD, $17
	db $82
	db $82
	db $82
	db $82
	db $FB
	db $C2
	db $82
	db $82
	db $82
	db $FD, $02
	db $FE, $00
Mus_CreditsD:
	db $D6
	db $FC
	db $74
	db $72
	db $61
	db $61
	db $61
	db $61
	db $71
	db $71
	db $81
	db $81
	db $91
	db $C1
	db $FB
	db $F7
	dw Mus_CreditsD_1
	db $FD, $07
	db $FB
	db $22
	db $11
	db $11
	db $62
	db $11
	db $11
	db $22
	db $11
	db $11
	db $82
	db $11
	db $11
	db $22
	db $11
	db $11
	db $62
	db $11
	db $11
	db $22
	db $11
	db $11
	db $22
	db $11
	db $11
	db $FD, $02
	db $32
	db $31
	db $31
	db $52
	db $31
	db $51
	db $51
	db $31
	db $51
	db $51
	db $32
	db $51
	db $51
	db $51
	db $51
	db $31
	db $31
	db $31
	db $31
	db $51
	db $51
	db $52
	db $53
	db $31
	db $31
	db $31
	db $FB
	db $F7
	dw Mus_CreditsD_1
	db $FD, $02
	db $32
	db $12
	db $32
	db $12
	db $32
	db $32
	db $32
	db $32
	db $32
	db $32
	db $32
	db $32
	db $32
	db $32
	db $32
	db $32
	db $FE, $00
Mus_CreditsD_1:
	db $54
	db $34
	db $52
	db $52
	db $32
	db $54
	db $52
	db $34
	db $51
	db $51
	db $51
	db $51
	db $34
	db $F9

Mus_DustManB:
	db $DC, $22, $A5, $00, $A5, $25, $F0
	db $E3
	db $11
	db $12
	db $12
	db $12
	db $11
	db $01
	db $02
	db $02
	db $02
	db $01
	db $61
	db $62
	db $62
	db $62
	db $62
	db $62
	db $E9, $B1
	db $F2, $12
	db $63
	db $D6, $22, $B1, $43, $9B, $26, $A4
	db $61
	db $03
	db $D6, $22, $B1, $43, $98, $26, $A4
	db $C2
	db $12
	db $01
	db $11
	db $C1
	db $11
	db $C2
	db $13
	db $01
	db $12
	db $C2
	db $12
	db $01
	db $11
	db $C2
	db $31
	db $C2
	db $32
	db $11
	db $02
	db $C2
	db $12
	db $01
	db $11
	db $C2
	db $01
	db $C2
	db $01
	db $11
	db $33
	db $12
	db $C2
	db $3C
	db $D6, $22, $B1, $43, $9B, $26, $A4
	db $FC
	db $C2
	db $52
	db $31
	db $12
	db $33
	db $12
	db $02
	db $E2
	db $82
	db $61
	db $82
	db $A5
	db $C2
	db $A2
	db $92
	db $E3
	db $02
	db $C2
	db $12
	db $01
	db $12
	db $36
	db $01
	db $E2
	db $82
	db $E3
	db $5C
	db $C2
	db $31
	db $51
	db $65
	db $81
	db $62
	db $51
	db $32
	db $51
	db $C4
	db $35
	db $51
	db $32
	db $11
	db $31
	db $C1
	db $55
	db $F6, $04
	db $E2
	db $AC
	db $A2
	db $E3
	db $02
	db $12
	db $32
	db $42
	db $52
	db $F6, $06
	db $6C
	db $54
	db $4C
	db $04
	db $51
	db $51
	db $C1
	db $61
	db $C1
	db $61
	db $C1
	db $31
	db $54
	db $F6, $01
	db $53
	db $33
	db $13
	db $03
	db $E2
	db $A3
	db $83
	db $63
	db $53
	db $D4, $22, $B6, $00, $9B, $26, $F0
	db $E3
	db $5E
	db $32
	db $12
	db $02
	db $12
	db $E2
	db $A2
	db $E3
	db $6E
	db $52
	db $32
	db $12
	db $32
	db $62
	db $04
	db $14
	db $34
	db $54
	db $84
	db $94
	db $D6, $22, $B1, $43, $9B, $26, $A4
	db $FB
	db $A1
	db $A1
	db $81
	db $A1
	db $C2
	db $83
	db $A2
	db $C5
	db $FD, $02
	db $A1
	db $A1
	db $81
	db $A1
	db $C1
	db $A1
	db $81
	db $A1
	db $C3
	db $E4
	db $11
	db $01
	db $E3
	db $83
	db $FE, $00
Mus_DustManA:
	db $DC, $22, $A5, $00, $A5, $25, $F0
	db $E2
	db $A1
	db $A2
	db $A2
	db $A2
	db $A1
	db $81
	db $82
	db $82
	db $82
	db $81
	db $A1
	db $A2
	db $A2
	db $A2
	db $A2
	db $A2
	db $E9, $B1
	db $F2, $12
	db $A3
	db $D6, $22, $A1, $43, $9A, $25, $A4
	db $A1
	db $83
	db $A0
	db $80
	db $F6, $0C
	db $69
	db $F6, $06
	db $C2
	db $9C
	db $FC
	db $EF, $01
	db $E3
	db $C2
	db $12
	db $01
	db $E2
	db $A3
	db $E3
	db $03
	db $03
	db $02
	db $E2
	db $C2
	db $A2
	db $91
	db $A3
	db $A3
	db $A3
	db $E3
	db $02
	db $E2
	db $C2
	db $52
	db $31
	db $62
	db $67
	db $52
	db $E3
	db $18
	db $08
	db $38
	db $18
	db $00
	db $E2
	db $50
	db $60
	db $70
	db $91
	db $91
	db $C1
	db $A1
	db $C1
	db $A1
	db $C1
	db $71
	db $94
	db $F6, $01
	db $93
	db $73
	db $53
	db $43
	db $23
	db $03
	db $E1
	db $A3
	db $93
	db $EF, $00
	db $D4, $22, $B1, $00, $06
	db $E2
	db $AE
	db $E3
	db $5A
	db $1E
	db $6A
	db $F6, $06
	db $51
	db $41
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
	db $31
	db $21
	db $D6, $22, $A1, $43, $9A, $25, $A4
	db $E3
	db $FB
	db $51
	db $51
	db $31
	db $51
	db $C2
	db $33
	db $52
	db $C5
	db $FD, $02
	db $51
	db $51
	db $31
	db $51
	db $C1
	db $51
	db $31
	db $51
	db $C3
	db $A1
	db $81
	db $33
	db $FE, $00
Mus_DustManC:
	db $D6, $01, $84, $80
	db $E2
	db $A1
	db $A1
	db $A2
	db $C2
	db $A1
	db $A1
	db $A2
	db $C6
	db $81
	db $81
	db $82
	db $C2
	db $81
	db $81
	db $82
	db $C6
	db $61
	db $61
	db $62
	db $C2
	db $61
	db $61
	db $62
	db $C6
	db $61
	db $61
	db $62
	db $C2
	db $61
	db $61
	db $62
	db $C2
	db $61
	db $83
	db $F7
	dw Mus_DustManC_1
	db $81
	db $81
	db $82
	db $E3
	db $31
	db $E2
	db $82
	db $81
	db $C1
	db $81
	db $C1
	db $81
	db $E3
	db $32
	db $E2
	db $82
	db $61
	db $61
	db $62
	db $E3
	db $11
	db $E2
	db $62
	db $61
	db $C1
	db $61
	db $C1
	db $61
	db $E3
	db $12
	db $E2
	db $62
	db $51
	db $51
	db $52
	db $E3
	db $01
	db $E2
	db $52
	db $51
	db $C1
	db $51
	db $C1
	db $51
	db $51
	db $61
	db $71
	db $91
	db $FC
	db $FB
	db $A1
	db $A1
	db $A2
	db $E3
	db $51
	db $E2
	db $A2
	db $81
	db $C1
	db $81
	db $C1
	db $81
	db $E3
	db $32
	db $E2
	db $82
	db $61
	db $61
	db $62
	db $E3
	db $11
	db $E2
	db $62
	db $51
	db $C1
	db $51
	db $C1
	db $51
	db $E3
	db $02
	db $E2
	db $52
	db $FD, $01
	db $FB
	db $31
	db $31
	db $32
	db $31
	db $E3
	db $32
	db $E2
	db $11
	db $C1
	db $11
	db $C1
	db $11
	db $E3
	db $12
	db $E2
	db $11
	db $11
	db $FD, $01
	db $11
	db $E3
	db $11
	db $E2
	db $12
	db $11
	db $11
	db $12
	db $21
	db $E3
	db $21
	db $E2
	db $22
	db $21
	db $21
	db $22
	db $31
	db $31
	db $32
	db $A1
	db $32
	db $41
	db $C1
	db $41
	db $C1
	db $41
	db $52
	db $62
	db $71
	db $02
	db $72
	db $71
	db $01
	db $71
	db $81
	db $02
	db $82
	db $81
	db $01
	db $81
	db $91
	db $91
	db $92
	db $E3
	db $61
	db $E2
	db $92
	db $91
	db $C1
	db $91
	db $C1
	db $91
	db $A2
	db $E3
	db $02
	db $E2
	db $F7
	dw Mus_DustManC_1
	db $FB
	db $61
	db $61
	db $62
	db $E3
	db $11
	db $E2
	db $62
	db $51
	db $C1
	db $51
	db $C1
	db $51
	db $E3
	db $02
	db $E2
	db $52
	db $FD, $01
	db $E2
	db $A1
	db $A1
	db $A2
	db $C2
	db $A1
	db $A1
	db $A2
	db $C6
	db $81
	db $81
	db $82
	db $C2
	db $81
	db $81
	db $82
	db $C6
	db $61
	db $61
	db $62
	db $C2
	db $61
	db $61
	db $62
	db $C6
	db $61
	db $61
	db $62
	db $C2
	db $61
	db $61
	db $62
	db $C2
	db $61
	db $83
	db $FE, $00
Mus_DustManC_1:
	db $A1
	db $A1
	db $A2
	db $E3
	db $51
	db $E2
	db $A2
	db $A1
	db $C1
	db $A1
	db $C1
	db $A1
	db $E3
	db $52
	db $E2
	db $A2
	db $F9
Mus_DustManD:
	db $D6
	db $FB
	db $22
	db $11
	db $11
	db $FD, $0F
	db $FB
	db $22
	db $11
	db $11
	db $22
	db $11
	db $11
	db $22
	db $11
	db $11
	db $31
	db $11
	db $11
	db $11
	db $FD, $03
	db $FC
	db $FB
	db $31
	db $11
	db $11
	db $11
	db $FD, $33
	db $FB
	db $22
	db $11
	db $11
	db $22
	db $11
	db $11
	db $22
	db $11
	db $11
	db $31
	db $11
	db $11
	db $11
	db $FD, $03
	db $FE, $00

Mus_DiveManB:
	db $DA, $11, $B1, $23, $8B, $26, $C3
	db $FC
	db $FB
	db $E3
	db $62
	db $62
	db $41
	db $61
	db $C1
	db $61
	db $C1
	db $61
	db $C1
	db $F6, $01
	db $68
	db $62
	db $F6, $0A
	db $91
	db $61
	db $41
	db $61
	db $FD, $01
	db $81
	db $C6
	db $94
	db $83
	db $C1
	db $6D
	db $C1
	db $E8, $22
	db $F7
	dw Mus_DiveManB_1
	db $FB
	db $C1
	db $81
	db $91
	db $81
	db $FD, $02
	db $B1
	db $51
	db $C1
	db $69
	db $C1
	db $E8, $01
	db $E2
	db $52
	db $51
	db $51
	db $E3
	db $F7
	dw Mus_DiveManB_1
	db $FB
	db $C1
	db $81
	db $91
	db $B1
	db $FD, $02
	db $E4
	db $11
	db $41
	db $C1
	db $6F
	db $C1
	db $E8, $22
	db $E3
	db $45
	db $41
	db $62
	db $32
	db $11
	db $E2
	db $B2
	db $C1
	db $E3
	db $21
	db $C1
	db $25
	db $21
	db $42
	db $12
	db $E2
	db $B1
	db $92
	db $C1
	db $91
	db $C1
	db $B7
	db $C1
	db $E3
	db $07
	db $C1
	db $19
	db $C1
	db $52
	db $51
	db $52
	db $C2
	db $E8, $11
	db $FE, $00
Mus_DiveManB_1:
	db $01
	db $11
	db $65
	db $81
	db $61
	db $C1
	db $96
	db $01
	db $11
	db $65
	db $81
	db $61
	db $C1
	db $81
	db $C1
	db $97
	db $F9
Mus_DiveManA:
	db $DA, $21, $A1, $23, $8A, $25, $B5
	db $FC
	db $FB
	db $E3
	db $12
	db $12
	db $E2
	db $B1
	db $E3
	db $11
	db $C1
	db $11
	db $C1
	db $11
	db $C1
	db $11
	db $41
	db $11
	db $E2
	db $B1
	db $E3
	db $11
	db $FD, $01
	db $41
	db $C6
	db $44
	db $43
	db $C1
	db $1D
	db $C1
	db $EF, $01
	db $D1, $22, $71, $21, $97, $34, $A5
	db $C6
	db $F6, $0A
	db $01
	db $11
	db $65
	db $81
	db $62
	db $96
	db $01
	db $11
	db $65
	db $81
	db $62
	db $82
	db $98
	db $81
	db $91
	db $82
	db $81
	db $91
	db $82
	db $81
	db $91
	db $81
	db $B1
	db $52
	db $69
	db $F6, $01
	db $C4
	db $EF, $00
	db $DA, $11, $A1, $23, $8A, $25, $B5
	db $E2
	db $12
	db $11
	db $11
	db $81
	db $51
	db $95
	db $B1
	db $91
	db $C1
	db $E3
	db $16
	db $E2
	db $81
	db $51
	db $95
	db $B1
	db $91
	db $C1
	db $B1
	db $C1
	db $E3
	db $17
	db $FB
	db $C1
	db $51
	db $61
	db $81
	db $FD, $02
	db $81
	db $B1
	db $C1
	db $E4
	db $1F
	db $C1
	db $E8, $22
	db $E2
	db $82
	db $81
	db $82
	db $81
	db $81
	db $81
	db $62
	db $61
	db $62
	db $61
	db $61
	db $61
	db $52
	db $51
	db $52
	db $51
	db $51
	db $51
	db $42
	db $41
	db $42
	db $41
	db $41
	db $41
	db $32
	db $31
	db $32
	db $31
	db $31
	db $31
	db $42
	db $41
	db $42
	db $41
	db $41
	db $41
	db $52
	db $51
	db $52
	db $51
	db $51
	db $51
	db $52
	db $E3
	db $12
	db $11
	db $12
	db $C2
	db $E8, $21
	db $FE, $00
Mus_DiveManC:
	db $DA, $01, $84, $C0
	db $FC
	db $E2
	db $61
	db $61
	db $41
	db $61
	db $C1
	db $61
	db $41
	db $61
	db $C1
	db $61
	db $41
	db $61
	db $91
	db $61
	db $41
	db $62
	db $61
	db $41
	db $61
	db $C1
	db $61
	db $41
	db $61
	db $C1
	db $61
	db $41
	db $61
	db $91
	db $61
	db $41
	db $61
	db $CF
	db $FB
	db $F7
	dw Mus_DiveManC_1
	db $FD, $02
	db $61
	db $FB
	db $C1
	db $81
	db $81
	db $81
	db $FD, $02
	db $C3
	db $62
	db $61
	db $91
	db $91
	db $B1
	db $E3
	db $11
	db $E2
	db $C1
	db $62
	db $B2
	db $B1
	db $B1
	db $E3
	db $11
	db $E2
	db $91
	db $FB
	db $F7
	dw Mus_DiveManC_1
	db $FD, $01
	db $61
	db $FB
	db $C1
	db $81
	db $61
	db $81
	db $FD, $02
	db $C3
	db $62
	db $61
	db $91
	db $91
	db $B1
	db $E3
	db $11
	db $C1
	db $E2
	db $62
	db $B2
	db $B1
	db $B1
	db $E3
	db $01
	db $E2
	db $91
	db $82
	db $E3
	db $11
	db $12
	db $11
	db $11
	db $11
	db $E2
	db $B2
	db $B1
	db $B2
	db $B1
	db $B1
	db $B1
	db $A2
	db $A1
	db $A2
	db $A1
	db $A1
	db $A1
	db $92
	db $91
	db $92
	db $91
	db $91
	db $91
	db $82
	db $81
	db $81
	db $81
	db $81
	db $81
	db $81
	db $92
	db $91
	db $91
	db $91
	db $91
	db $91
	db $91
	db $A2
	db $A1
	db $A1
	db $A1
	db $A1
	db $A1
	db $B1
	db $E3
	db $02
	db $12
	db $11
	db $12
	db $E2
	db $52
	db $FE, $00
Mus_DiveManC_1:
	db $62
	db $61
	db $91
	db $91
	db $B1
	db $E3
	db $11
	db $C1
	db $E2
	db $62
	db $61
	db $91
	db $61
	db $91
	db $61
	db $41
	db $F9
Mus_DiveManD:
	db $D5
	db $FC
	db $FB
	db $34
	db $FD, $0F
	db $94
	db $64
	db $82
	db $82
	db $62
	db $96
	db $64
	db $61
	db $61
	db $61
	db $61
	db $72
	db $32
	db $C2
	db $52
	db $34
	db $34
	db $34
	db $34
	db $34
	db $32
	db $22
	db $32
	db $22
	db $F7
	dw Mus_DiveManD_1
	db $54
	db $34
	db $54
	db $32
	db $52
	db $F7
	dw Mus_DiveManD_1
	db $C2
	db $52
	db $34
	db $32
	db $32
	db $32
	db $24
	db $FB
	db $12
	db $22
	db $FD, $0E
	db $12
	db $F8
	dw Mus_DiveManD_2
	db $C4
	db $34
	db $54
	db $32
	db $52
	db $FE, $00
Mus_DiveManD_1:
	db $F8
	dw Mus_DiveManD_2
	db $C2
	db $52
	db $34
	db $54
	db $32
	db $52
	db $62
	db $C2
	db $34
	db $62
	db $C2
	db $34
	db $62
	db $C2
	db $34
	db $62
	db $62
	db $32
	db $52
	db $C4
	db $34
	db $54
	db $34
	db $F9
Mus_DiveManD_2:
	db $54
	db $34
	db $54
	db $34
	db $C2
	db $52
	db $34
	db $54
	db $32
	db $52
	db $C4
	db $34
	db $54
	db $34
	db $FA

Mus_SkullManB:
	db $D5, $11, $B1, $43, $8B, $26, $C3
	db $FB
	db $E2
	db $C4
	db $B4
	db $B2
	db $A2
	db $C2
	db $82
	db $C2
	db $B2
	db $C2
	db $B2
	db $A2
	db $C2
	db $82
	db $C2
	db $C4
	db $A4
	db $A2
	db $82
	db $C2
	db $62
	db $C2
	db $A6
	db $B4
	db $A2
	db $B2
	db $C4
	db $B4
	db $B2
	db $A2
	db $C2
	db $82
	db $C2
	db $B2
	db $C2
	db $B2
	db $A2
	db $C2
	db $82
	db $C2
	db $C4
	db $A4
	db $A2
	db $82
	db $C2
	db $62
	db $C2
	db $A2
	db $C2
	db $A2
	db $B2
	db $C2
	db $A2
	db $82
	db $CA
	db $62
	db $72
	db $82
	db $C4
	db $E3
	db $3C
	db $E8, $22
	db $C4
	db $34
	db $12
	db $E2
	db $B2
	db $C2
	db $82
	db $C2
	db $82
	db $C2
	db $82
	db $A2
	db $64
	db $82
	db $E3
	db $C4
	db $34
	db $12
	db $E2
	db $B2
	db $C2
	db $E3
	db $44
	db $34
	db $14
	db $E2
	db $B4
	db $A4
	db $8E
	db $E8, $11
	db $C2
	db $82
	db $A2
	db $B2
	db $A2
	db $64
	db $82
	db $C4
	db $B4
	db $B2
	db $A2
	db $C2
	db $82
	db $C2
	db $B2
	db $C2
	db $B2
	db $A2
	db $C2
	db $82
	db $C2
	db $C4
	db $A4
	db $A2
	db $82
	db $C2
	db $62
	db $C2
	db $A6
	db $B4
	db $A2
	db $B2
	db $E1
	db $C2
	db $62
	db $72
	db $82
	db $B2
	db $E2
	db $32
	db $C2
	db $D5, $22, $B5, $43, $8B, $26, $F0
	db $E3
	db $1A
	db $12
	db $E2
	db $B2
	db $A2
	db $64
	db $F6, $01
	db $EE, $06
	db $61
	db $71
	db $81
	db $91
	db $A1
	db $B1
	db $E3
	db $01
	db $11
	db $21
	db $31
	db $F6, $05
	db $46
	db $F0, $8B
	db $14
	db $3A
	db $32
	db $12
	db $E2
	db $B2
	db $E3
	db $30
	db $C2
	db $58
	db $52
	db $32
	db $22
	db $E2
	db $A4
	db $F6, $01
	db $EE, $06
	db $A1
	db $B1
	db $E3
	db $01
	db $11
	db $21
	db $31
	db $41
	db $51
	db $61
	db $71
	db $F6, $05
	db $88
	db $F0, $8B
	db $54
	db $68
	db $62
	db $52
	db $62
	db $38
	db $E2
	db $A2
	db $A2
	db $32
	db $52
	db $68
	db $E1
	db $B6
	db $E2
	db $64
	db $C0
	db $86
	db $16
	db $84
	db $C0
	db $D5, $11, $B1, $43, $8B, $26, $C3
	db $C2
	db $72
	db $82
	db $A2
	db $C2
	db $72
	db $82
	db $A2
	db $C2
	db $72
	db $82
	db $A2
	db $C2
	db $E3
	db $12
	db $12
	db $C2
	db $FE, $00
Mus_SkullManA:
	db $D5, $11, $A1, $43, $8A, $25, $C3
	db $FB
	db $E2
	db $C4
	db $84
	db $82
	db $62
	db $C2
	db $32
	db $C2
	db $82
	db $C2
	db $82
	db $62
	db $C2
	db $32
	db $C2
	db $C4
	db $64
	db $62
	db $12
	db $C2
	db $12
	db $C2
	db $66
	db $84
	db $62
	db $82
	db $C4
	db $84
	db $82
	db $62
	db $C2
	db $32
	db $C2
	db $82
	db $C2
	db $82
	db $62
	db $C2
	db $32
	db $C2
	db $C4
	db $64
	db $62
	db $12
	db $C2
	db $12
	db $C2
	db $62
	db $C2
	db $62
	db $82
	db $C2
	db $62
	db $32
	db $CA
	db $12
	db $22
	db $32
	db $C4
	db $7C
	db $E8, $22
	db $C4
	db $B4
	db $A2
	db $82
	db $C2
	db $32
	db $C2
	db $32
	db $C2
	db $32
	db $32
	db $14
	db $E1
	db $B2
	db $C4
	db $E2
	db $A4
	db $A2
	db $82
	db $C2
	db $64
	db $44
	db $34
	db $14
	db $34
	db $4E
	db $C2
	db $32
	db $62
	db $82
	db $62
	db $34
	db $32
	db $E8, $11
	db $C4
	db $84
	db $82
	db $62
	db $C2
	db $32
	db $C2
	db $82
	db $C2
	db $82
	db $62
	db $C2
	db $32
	db $C2
	db $C4
	db $64
	db $62
	db $12
	db $C2
	db $12
	db $C2
	db $66
	db $84
	db $62
	db $82
	db $EF, $02
	db $E1
	db $C2
	db $62
	db $72
	db $82
	db $B2
	db $E2
	db $32
	db $C2
	db $EF, $00
	db $D5, $11, $A1, $43, $98, $25, $C3
	db $E1
	db $6E
	db $82
	db $A4
	db $B2
	db $E2
	db $16
	db $E1
	db $A6
	db $B8
	db $60
	db $E2
	db $62
	db $66
	db $E1
	db $8A
	db $92
	db $82
	db $2E
	db $84
	db $F6, $0A
	db $AC
	db $F6, $05
	db $C2
	db $E0
	db $B2
	db $E1
	db $12
	db $38
	db $EF, $01
	db $BA
	db $C0
	db $E2
	db $10
	db $EF, $00
	db $C0
	db $D5, $11, $A1, $43, $8A, $25, $C3
	db $C2
	db $32
	db $52
	db $72
	db $C2
	db $32
	db $52
	db $72
	db $C2
	db $32
	db $52
	db $72
	db $C2
	db $A2
	db $A2
	db $C2
	db $FE, $00
Mus_SkullManC:
	db $FC
	db $D5, $01, $83, $90
	db $E2
	db $FB
	db $82
	db $81
	db $81
	db $FD, $07
	db $FB
	db $62
	db $61
	db $61
	db $FD, $07
	db $FB
	db $82
	db $81
	db $81
	db $FD, $07
	db $FB
	db $62
	db $61
	db $61
	db $FD, $06
	db $62
	db $81
	db $81
	db $84
	db $84
	db $C8
	db $F2, $C0
	db $C4
	db $BC
	db $F2, $90
	db $FB
	db $82
	db $81
	db $81
	db $FD, $07
	db $FB
	db $62
	db $61
	db $61
	db $FD, $07
	db $32
	db $31
	db $31
	db $FB
	db $42
	db $41
	db $41
	db $FD, $02
	db $E1
	db $82
	db $E2
	db $82
	db $A2
	db $B2
	db $34
	db $62
	db $82
	db $FB
	db $82
	db $81
	db $81
	db $FD, $07
	db $FB
	db $62
	db $61
	db $61
	db $FD, $06
	db $62
	db $81
	db $81
	db $CE
	db $F2, $C0
	db $A4
	db $A2
	db $C4
	db $A2
	db $A2
	db $C4
	db $A2
	db $A2
	db $C4
	db $A2
	db $A2
	db $C4
	db $B2
	db $B2
	db $C4
	db $B2
	db $B2
	db $C4
	db $B2
	db $B2
	db $C4
	db $B2
	db $B2
	db $C4
	db $E3
	db $22
	db $22
	db $C4
	db $22
	db $22
	db $C4
	db $22
	db $22
	db $C4
	db $22
	db $22
	db $C4
	db $32
	db $32
	db $C4
	db $32
	db $32
	db $C4
	db $32
	db $32
	db $C4
	db $32
	db $32
	db $C4
	db $F2, $90
	db $E2
	db $FB
	db $32
	db $31
	db $31
	db $FD, $07
	db $FB
	db $52
	db $51
	db $51
	db $FD, $06
	db $51
	db $51
	db $51
	db $51
	db $F2, $C0
	db $32
	db $32
	db $C4
	db $32
	db $32
	db $C4
	db $32
	db $32
	db $C4
	db $62
	db $62
	db $62
	db $72
	db $FE, $00
Mus_SkullManD:
	db $D5
	db $FC
	db $FB
	db $54
	db $34
	db $52
	db $52
	db $34
	db $54
	db $34
	db $52
	db $51
	db $51
	db $34
	db $54
	db $34
	db $52
	db $52
	db $34
	db $54
	db $34
	db $52
	db $52
	db $34
	db $FD, $01
	db $34
	db $34
	db $32
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $FB
	db $34
	db $54
	db $32
	db $32
	db $54
	db $FD, $05
	db $FB
	db $12
	db $11
	db $11
	db $FD, $03
	db $FB
	db $54
	db $34
	db $52
	db $52
	db $34
	db $FD, $03
	db $54
	db $34
	db $52
	db $52
	db $32
	db $26
	db $64
	db $FB
	db $24
	db $64
	db $FD, $0E
	db $54
	db $34
	db $52
	db $52
	db $34
	db $32
	db $52
	db $32
	db $52
	db $32
	db $32
	db $32
	db $32
	db $54
	db $34
	db $52
	db $52
	db $34
	db $32
	db $52
	db $32
	db $52
	db $32
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $FB
	db $24
	db $64
	db $FD, $02
	db $22
	db $32
	db $32
	db $32
	db $FE, $00

Mus_DrillManB:
	db $D6, $00, $B1, $44, $8B, $26, $C3
	db $FB
	db $E2
	db $C2
	db $A2
	db $81
	db $A2
	db $E3
	db $13
	db $E2
	db $A2
	db $81
	db $92
	db $A1
	db $E3
	db $C2
	db $22
	db $11
	db $22
	db $73
	db $72
	db $51
	db $12
	db $E2
	db $A1
	db $91
	db $91
	db $81
	db $92
	db $A1
	db $E3
	db $01
	db $E2
	db $A1
	db $94
	db $C2
	db $E8, $11
	db $81
	db $91
	db $A8
	db $A3
	db $E3
	db $03
	db $12
	db $53
	db $39
	db $E2
	db $82
	db $91
	db $A0
	db $C1
	db $E3
	db $13
	db $33
	db $42
	db $53
	db $E2
	db $A3
	db $81
	db $91
	db $A8
	db $A3
	db $E3
	db $03
	db $12
	db $88
	db $81
	db $A2
	db $82
	db $51
	db $31
	db $41
	db $F6, $0C
	db $50
	db $F6, $06
	db $33
	db $53
	db $62
	db $61
	db $C1
	db $61
	db $C2
	db $52
	db $31
	db $13
	db $33
	db $52
	db $51
	db $C1
	db $51
	db $C2
	db $32
	db $11
	db $01
	db $11
	db $01
	db $37
	db $C1
	db $11
	db $31
	db $11
	db $62
	db $50
	db $E2
	db $A3
	db $E3
	db $03
	db $22
	db $23
	db $33
	db $52
	db $60
	db $E2
	db $83
	db $A3
	db $E3
	db $02
	db $03
	db $13
	db $32
	db $5E
	db $31
	db $51
	db $6C
	db $32
	db $62
	db $8C
	db $54
	db $9C
	db $E4
	db $04
	db $E3
	db $A1
	db $91
	db $C1
	db $A2
	db $81
	db $A1
	db $82
	db $51
	db $31
	db $61
	db $51
	db $11
	db $E2
	db $81
	db $51
	db $61
	db $82
	db $AD
	db $91
	db $A2
	db $E3
	db $09
	db $34
	db $20
	db $C1
	db $21
	db $11
	db $21
	db $61
	db $21
	db $11
	db $21
	db $02
	db $E2
	db $91
	db $61
	db $51
	db $61
	db $71
	db $91
	db $FD, $00
Mus_DrillManA:
	db $FC
	db $D6, $01, $B1, $44, $8B, $26, $C3
	db $EF, $01
	db $E2
	db $C2
	db $A2
	db $81
	db $A2
	db $E3
	db $13
	db $E2
	db $A2
	db $81
	db $92
	db $A1
	db $EF, $00
	db $C2
	db $A2
	db $91
	db $A2
	db $E3
	db $33
	db $32
	db $11
	db $E2
	db $A2
	db $51
	db $51
	db $51
	db $31
	db $52
	db $61
	db $81
	db $61
	db $54
	db $C4
	db $D6, $22, $91, $44, $89, $35, $C3
	db $FB
	db $E1
	db $A1
	db $E2
	db $11
	db $51
	db $81
	db $FD, $03
	db $FB
	db $E1
	db $81
	db $E2
	db $01
	db $31
	db $81
	db $FD, $03
	db $FB
	db $E1
	db $A1
	db $E2
	db $11
	db $51
	db $81
	db $FD, $03
	db $13
	db $33
	db $42
	db $53
	db $E1
	db $A3
	db $81
	db $91
	db $FB
	db $E1
	db $A1
	db $E2
	db $11
	db $51
	db $81
	db $FD, $03
	db $FB
	db $E1
	db $81
	db $E2
	db $01
	db $31
	db $81
	db $FD, $03
	db $FB
	db $E1
	db $A1
	db $E2
	db $11
	db $51
	db $81
	db $FD, $03
	db $F0, $97
	db $E3
	db $52
	db $42
	db $32
	db $22
	db $12
	db $02
	db $E2
	db $B2
	db $A2
	db $F0, $89
	db $A3
	db $E3
	db $13
	db $32
	db $31
	db $C1
	db $31
	db $C2
	db $12
	db $E2
	db $A1
	db $A3
	db $E3
	db $03
	db $12
	db $11
	db $C1
	db $11
	db $C2
	db $02
	db $E2
	db $A1
	db $C5
	db $01
	db $11
	db $01
	db $34
	db $C2
	db $62
	db $E3
	db $00
	db $EF, $01
	db $E2
	db $A3
	db $93
	db $A2
	db $A3
	db $E3
	db $03
	db $22
	db $30
	db $E2
	db $83
	db $73
	db $82
	db $83
	db $A3
	db $E3
	db $02
	db $10
	db $F0, $97
	db $C4
	db $E1
	db $61
	db $A1
	db $E2
	db $11
	db $61
	db $E1
	db $A1
	db $E2
	db $31
	db $61
	db $A1
	db $E3
	db $32
	db $62
	db $C4
	db $E1
	db $81
	db $E2
	db $01
	db $31
	db $51
	db $61
	db $81
	db $E3
	db $01
	db $31
	db $51
	db $81
	db $61
	db $11
	db $C4
	db $E1
	db $51
	db $91
	db $E2
	db $01
	db $51
	db $E1
	db $91
	db $E2
	db $01
	db $31
	db $51
	db $01
	db $31
	db $51
	db $91
	db $F0, $89
	db $51
	db $91
	db $C1
	db $A2
	db $E3
	db $81
	db $A1
	db $82
	db $51
	db $31
	db $61
	db $51
	db $11
	db $E2
	db $81
	db $51
	db $61
	db $82
	db $A1
	db $31
	db $52
	db $6D
	db $81
	db $A2
	db $E3
	db $05
	db $34
	db $20
	db $E2
	db $22
	db $42
	db $62
	db $72
	db $92
	db $82
	db $31
	db $21
	db $11
	db $01
	db $FE, $00
Mus_DrillManC:
	db $D6, $01, $83, $A0
	db $FC
	db $C2
	db $E2
	db $A2
	db $81
	db $A1
	db $C1
	db $E3
	db $13
	db $E2
	db $A2
	db $81
	db $91
	db $C1
	db $A1
	db $C2
	db $A2
	db $81
	db $A1
	db $C1
	db $E3
	db $33
	db $12
	db $E2
	db $A1
	db $81
	db $C1
	db $A1
	db $E3
	db $51
	db $51
	db $31
	db $51
	db $E2
	db $51
	db $E3
	db $61
	db $81
	db $61
	db $52
	db $C2
	db $E2
	db $54
	db $A2
	db $A2
	db $E3
	db $12
	db $E2
	db $A1
	db $A1
	db $C1
	db $A1
	db $C1
	db $A1
	db $E3
	db $12
	db $E2
	db $A2
	db $82
	db $82
	db $E3
	db $02
	db $E2
	db $81
	db $81
	db $C1
	db $81
	db $C1
	db $81
	db $E3
	db $02
	db $E2
	db $82
	db $A2
	db $A2
	db $E3
	db $12
	db $E2
	db $A1
	db $A1
	db $C1
	db $A1
	db $C1
	db $E3
	db $11
	db $32
	db $52
	db $13
	db $33
	db $42
	db $53
	db $E2
	db $A3
	db $81
	db $91
	db $A2
	db $A2
	db $E3
	db $12
	db $E2
	db $A1
	db $A1
	db $C1
	db $A1
	db $C1
	db $A1
	db $E3
	db $12
	db $E2
	db $A2
	db $82
	db $82
	db $E3
	db $02
	db $E2
	db $81
	db $81
	db $C1
	db $81
	db $C1
	db $81
	db $E3
	db $02
	db $E2
	db $82
	db $A2
	db $A2
	db $E3
	db $12
	db $E2
	db $A1
	db $A1
	db $C1
	db $A1
	db $C1
	db $E3
	db $11
	db $32
	db $52
	db $C0
	db $33
	db $A3
	db $C7
	db $E2
	db $A3
	db $C1
	db $A1
	db $E3
	db $11
	db $51
	db $81
	db $81
	db $61
	db $51
	db $C1
	db $E2
	db $A1
	db $E3
	db $11
	db $51
	db $81
	db $81
	db $61
	db $51
	db $03
	db $01
	db $33
	db $31
	db $63
	db $61
	db $93
	db $91
	db $E2
	db $51
	db $E3
	db $51
	db $E2
	db $51
	db $51
	db $E3
	db $51
	db $E2
	db $51
	db $E3
	db $51
	db $51
	db $E2
	db $51
	db $E3
	db $51
	db $E2
	db $51
	db $51
	db $E3
	db $51
	db $E2
	db $51
	db $E3
	db $51
	db $51
	db $E2
	db $A3
	db $51
	db $C1
	db $A1
	db $A1
	db $A1
	db $E3
	db $53
	db $33
	db $22
	db $34
	db $E2
	db $A4
	db $E3
	db $83
	db $63
	db $52
	db $34
	db $E2
	db $84
	db $E3
	db $33
	db $13
	db $02
	db $14
	db $E2
	db $14
	db $E3
	db $13
	db $03
	db $E2
	db $A2
	db $D6, $01, $84, $F0
	db $6C
	db $C4
	db $8C
	db $C4
	db $9C
	db $C4
	db $D6, $01, $8D, $A0
	db $C0
	db $E3
	db $32
	db $32
	db $12
	db $31
	db $31
	db $C1
	db $31
	db $C1
	db $31
	db $12
	db $32
	db $52
	db $52
	db $32
	db $51
	db $51
	db $C1
	db $51
	db $C1
	db $51
	db $32
	db $52
	db $C0
	db $C0
	db $FE, $00
Mus_DrillManD:
	db $D6
	db $51
	db $11
	db $FC
	db $11
	db $51
	db $51
	db $11
	db $51
	db $11
	db $11
	db $51
	db $11
	db $51
	db $51
	db $11
	db $11
	db $51
	db $51
	db $11
	db $11
	db $51
	db $51
	db $11
	db $51
	db $11
	db $11
	db $51
	db $11
	db $51
	db $51
	db $11
	db $11
	db $51
	db $51
	db $11
	db $11
	db $51
	db $31
	db $11
	db $11
	db $51
	db $51
	db $11
	db $11
	db $51
	db $31
	db $11
	db $11
	db $51
	db $FB
	db $51
	db $11
	db $11
	db $51
	db $31
	db $11
	db $11
	db $51
	db $11
	db $51
	db $11
	db $51
	db $31
	db $11
	db $12
	db $FD, $06
	db $62
	db $62
	db $72
	db $72
	db $82
	db $82
	db $92
	db $92
	db $51
	db $11
	db $11
	db $51
	db $31
	db $11
	db $11
	db $51
	db $62
	db $62
	db $71
	db $13
	db $FB
	db $51
	db $11
	db $11
	db $51
	db $31
	db $11
	db $11
	db $51
	db $51
	db $11
	db $51
	db $11
	db $31
	db $11
	db $12
	db $FD, $06
	db $FB
	db $51
	db $11
	db $11
	db $51
	db $31
	db $11
	db $11
	db $51
	db $11
	db $51
	db $11
	db $51
	db $63
	db $11
	db $FD, $02
	db $FB
	db $51
	db $11
	db $11
	db $51
	db $31
	db $11
	db $11
	db $51
	db $11
	db $51
	db $11
	db $51
	db $31
	db $11
	db $12
	db $FD, $02
	db $81
	db $81
	db $62
	db $81
	db $81
	db $62
	db $D3
	db $C1
	db $61
	db $61
	db $61
	db $D6
	db $71
	db $81
	db $61
	db $71
	db $81
	db $91
	db $72
	db $72
	db $61
	db $72
	db $72
	db $71
	db $71
	db $71
	db $71
	db $71
	db $71
	db $71
	db $62
	db $FE, $00

Mus_WilyIntroB:
	db $D8, $21, $B1, $24, $8B, $26, $C3
	db $EC, $FC
	db $E2
	db $41
	db $91
	db $41
	db $91
	db $47
	db $41
	db $91
	db $41
	db $91
	db $E3
	db $01
	db $31
	db $E2
	db $81
	db $E3
	db $31
	db $E2
	db $81
	db $E3
	db $37
	db $E2
	db $81
	db $E3
	db $31
	db $E2
	db $81
	db $E3
	db $31
	db $01
	db $F7
	dw Mus_WilyIntroB_1
	db $44
	db $3C
	db $FF
Mus_WilyIntroB_1:
	db $E2
	db $B1
	db $22
	db $B1
	db $E3
	db $01
	db $E2
	db $32
	db $E3
	db $01
	db $E3
	db $11
	db $E2
	db $42
	db $E3
	db $11
	db $E3
	db $21
	db $E2
	db $52
	db $E3
	db $21
	db $F9
Mus_WilyIntroA:
	db $D8, $11, $B1, $24, $8B, $26, $C3
	db $E2
	db $C1
	db $EC, $FC
	db $EF, $01
	db $F3, $00
	db $41
	db $91
	db $41
	db $91
	db $42
	db $FB
	db $91
	db $41
	db $FD, $04
	db $FB
	db $E3
	db $31
	db $E2
	db $81
	db $FD, $07
	db $F7
	dw Mus_WilyIntroB_1
	db $D8, $11, $91, $24, $89, $25, $C3
	db $F3, $03
	db $44
	db $3C
	db $FF
Mus_WilyIntroC:
	db $D8, $07, $87, $D0
	db $EC, $FC
	db $E2
	db $96
	db $E3
	db $01
	db $41
	db $74
	db $E2
	db $94
	db $86
	db $B1
	db $E3
	db $31
	db $64
	db $E2
	db $84
	db $74
	db $84
	db $94
	db $A4
	db $B4
	db $BC
	db $FF
Mus_WilyIntroD:
	db $D8
	db $FB
	db $FC
	db $12
	db $11
	db $11
	db $FE, $02
	db $11
	db $11
	db $22
	db $FD, $01
	db $FB
	db $11
	db $22
	db $11
	db $FD, $03
	db $24
	db $2C
	db $FF

Mus_FinalVictoryB:
	db $D7, $01, $B1, $44, $8B, $56, $C3
	db $E2
	db $96
	db $41
	db $91
	db $E3
	db $14
	db $E2
	db $93
	db $E3
	db $41
	db $F7
	dw Mus_FinalVictoryB_1
	db $EC, $02
	db $F7
	dw Mus_FinalVictoryB_1
	db $40
	db $FF
Mus_FinalVictoryB_1:
	db $26
	db $E2
	db $51
	db $A1
	db $E3
	db $24
	db $53
	db $21
	db $F9
Mus_FinalVictoryA:
	db $D7, $00, $A1, $44, $8A, $44, $C3
	db $E2
	db $44
	db $12
	db $E1
	db $91
	db $E2
	db $41
	db $94
	db $43
	db $E3
	db $11
	db $F7
	dw Mus_FinalVictoryA_1
	db $EC, $02
	db $F7
	dw Mus_FinalVictoryA_1
	db $00
	db $FF
Mus_FinalVictoryA_1:
	db $E2
	db $A4
	db $52
	db $21
	db $51
	db $A4
	db $E3
	db $23
	db $E2
	db $A1
	db $F9
Mus_FinalVictoryC:
	db $D7, $01, $86, $A0
	db $E1
	db $94
	db $94
	db $94
	db $93
	db $91
	db $A4
	db $A4
	db $A4
	db $A3
	db $A1
	db $E2
	db $04
	db $04
	db $04
	db $03
	db $01
	db $20
	db $FF
Mus_FinalVictoryD:
	db $D7
	db $34
	db $F7
	dw Mus_FinalVictoryD_1
	db $34
	db $34
	db $34
	db $31
	db $31
	db $31
	db $31
	db $F7
	dw Mus_FinalVictoryD_1
	db $31
	db $31
	db $31
	db $31
	db $32
	db $FF
Mus_FinalVictoryD_1:
	db $34
	db $34
	db $32
	db $31
	db $31
	db $F9

Mus_PunkB:
	db $D6, $01, $B1, $36, $8B, $16, $C3
	db $C0
	db $EC, $04
	db $FC
	db $F7
	dw Mus_PunkB_1
	db $E1
	db $A0
	db $C2
	db $F7
	dw Mus_PunkB_1
	db $20
	db $C2
	db $F7
	dw Mus_PunkB_1
	db $E1
	db $AC
	db $E2
	db $22
	db $C2
	db $0C
	db $42
	db $C2
	db $70
	db $C2
	db $E8, $12
	db $F7
	dw Mus_PunkB_2
	db $E2
	db $A0
	db $C2
	db $F7
	dw Mus_PunkB_2
	db $20
	db $C2
	db $E8, $01
	db $FE, $00
Mus_PunkB_1:
	db $E1
	db $91
	db $91
	db $91
	db $91
	db $92
	db $41
	db $41
	db $92
	db $E2
	db $02
	db $C2
	db $F9
Mus_PunkB_2:
	db $E2
	db $9A
	db $E3
	db $02
	db $C2
	db $E2
	db $AC
	db $E3
	db $24
	db $52
	db $4A
	db $02
	db $C2
	db $F9
Mus_PunkA:
	db $D6, $10, $91, $36, $89, $15, $C3
	db $C0
	db $EC, $04
	db $FC
	db $F7
	dw Mus_PunkA_1
	db $50
	db $C2
	db $F7
	dw Mus_PunkA_1
	db $A0
	db $C2
	db $F7
	dw Mus_PunkA_1
	db $5C
	db $A2
	db $C2
	db $7C
	db $E2
	db $02
	db $C2
	db $40
	db $C2
	db $E8, $12
	db $F7
	dw Mus_PunkA_2
	db $50
	db $C2
	db $F7
	dw Mus_PunkA_2
	db $A0
	db $C2
	db $E8, $10
	db $FE, $00
Mus_PunkA_1:
	db $E1
	db $41
	db $41
	db $41
	db $41
	db $42
	db $EF, $01
	db $41
	db $41
	db $92
	db $EF, $00
	db $92
	db $C2
	db $F9
Mus_PunkA_2:
	db $E2
	db $4A
	db $92
	db $C2
	db $7C
	db $A4
	db $E3
	db $22
	db $0A
	db $E2
	db $92
	db $C2
	db $F9
Mus_PunkC:
	db $D6, $01, $85, $B0
	db $C0
	db $EC, $04
	db $FC
	db $E1
	db $F7
	dw Mus_PunkC_1
	db $F7
	dw Mus_PunkC_1
	db $F7
	dw Mus_PunkC_1
	db $FB
	db $72
	db $71
	db $71
	db $FD, $07
	db $F8
	dw Mus_PunkC_3
	db $F8
	dw Mus_PunkC_3
	db $FE, $00
Mus_PunkC_1:
	db $41
	db $41
	db $FB
	db $41
	db $41
	db $42
	db $FD, $02
	db $54
	db $51
	db $51
	db $FB
	db $52
	db $51
	db $51
	db $FD, $02
	db $F9
Mus_PunkC_2:
	db $FB
	db $91
	db $91
	db $92
	db $FD, $02
	db $F9
Mus_PunkC_3:
	db $92
	db $F7
	dw Mus_PunkC_2
	db $EC, $05
	db $94
	db $F7
	dw Mus_PunkC_2
	db $EC, $07
	db $94
	db $F7
	dw Mus_PunkC_2
	db $EC, $05
	db $94
	db $F7
	dw Mus_PunkC_2
	db $91
	db $91
	db $EC, $04
	db $FA
Mus_PunkD:
	db $D6
	db $71
	db $72
	db $81
	db $82
	db $91
	db $92
	db $71
	db $72
	db $41
	db $41
	db $41
	db $41
	db $FC
	db $F7
	dw Mus_PunkD_1
	db $F7
	dw Mus_PunkD_1
	db $F7
	dw Mus_PunkD_1
	db $F7
	dw Mus_PunkD_1
	db $F7
	dw Mus_PunkD_2
	db $F7
	dw Mus_PunkD_2
	db $FE, $00
	db $FF
Mus_PunkD_1:
	db $11
	db $11
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
	db $FD, $02
	db $F9
Mus_PunkD_2:
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
	db $22
	db $FD, $02
	db $FB
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FD, $01
	db $F9

Mus_Wily2B:
	db $EC, $01
	db $D6, $11, $81, $00, $88, $13, $C3
	db $FB
	db $E2
	db $B1
	db $E3
	db $01
	db $41
	db $71
	db $FD, $0F
	db $FC
	db $D6, $12, $B1, $33, $8B, $36, $C3
	db $FB
	db $E2
	db $9A
	db $E3
	db $04
	db $E2
	db $B2
	db $40
	db $5A
	db $94
	db $72
	db $00
	db $2A
	db $44
	db $52
	db $7A
	db $92
	db $B2
	db $E3
	db $02
	db $26
	db $E2
	db $96
	db $E3
	db $24
	db $40
	db $FD, $01
	db $E8, $11
	db $EB, $31
	db $E3
	db $16
	db $E2
	db $41
	db $91
	db $E3
	db $13
	db $21
	db $11
	db $E2
	db $91
	db $E3
	db $11
	db $21
	db $4E
	db $21
	db $41
	db $66
	db $E2
	db $91
	db $E3
	db $21
	db $63
	db $71
	db $61
	db $21
	db $61
	db $71
	db $9E
	db $71
	db $91
	db $A6
	db $26
	db $A4
	db $96
	db $26
	db $94
	db $76
	db $16
	db $44
	db $20
	db $FE, $00
Mus_Wily2A:
	db $EC, $01
	db $D1, $11, $81, $00, $88, $13, $C3
	db $EF, $02
	db $F3, $00
	db $C3
	db $F6, $06
	db $FB
	db $E2
	db $B1
	db $E3
	db $01
	db $41
	db $71
	db $FD, $0E
	db $E2
	db $B1
	db $E3
	db $01
	db $41
	db $F6, $01
	db $73
	db $F3, $03
	db $FC
	db $D1, $22, $A1, $33, $8A, $35, $C3
	db $C9
	db $F6, $06
	db $E2
	db $9A
	db $E3
	db $04
	db $E2
	db $B2
	db $40
	db $5A
	db $94
	db $72
	db $00
	db $2A
	db $44
	db $52
	db $7A
	db $92
	db $B2
	db $E3
	db $02
	db $26
	db $E2
	db $96
	db $E3
	db $24
	db $4E
	db $F6, $01
	db $C3
	db $F6, $06
	db $EF, $00
	db $E8, $11
	db $E2
	db $4A
	db $94
	db $42
	db $E1
	db $B0
	db $E2
	db $0A
	db $54
	db $02
	db $E1
	db $70
	db $9A
	db $E2
	db $04
	db $22
	db $4A
	db $42
	db $72
	db $92
	db $96
	db $56
	db $94
	db $B0
	db $EF, $01
	db $EB, $31
	db $E2
	db $96
	db $11
	db $41
	db $93
	db $91
	db $91
	db $41
	db $91
	db $B1
	db $E3
	db $14
	db $11
	db $E2
	db $91
	db $E3
	db $11
	db $21
	db $46
	db $E2
	db $91
	db $E3
	db $11
	db $26
	db $E2
	db $61
	db $91
	db $E3
	db $23
	db $21
	db $21
	db $E2
	db $91
	db $E3
	db $21
	db $41
	db $64
	db $61
	db $21
	db $61
	db $71
	db $96
	db $41
	db $51
	db $EF, $00
	db $26
	db $E2
	db $A6
	db $E3
	db $24
	db $26
	db $E2
	db $96
	db $E3
	db $24
	db $46
	db $E2
	db $96
	db $E3
	db $14
	db $E2
	db $60
	db $EF, $02
	db $FE, $00
Mus_Wily2C:
	db $EC, $01
	db $D6, $05, $83, $A0
	db $E1
	db $91
	db $91
	db $92
	db $C2
	db $91
	db $91
	db $92
	db $C2
	db $91
	db $91
	db $92
	db $71
	db $71
	db $72
	db $C2
	db $71
	db $71
	db $72
	db $C2
	db $71
	db $71
	db $72
	db $51
	db $51
	db $52
	db $C2
	db $51
	db $51
	db $52
	db $C2
	db $51
	db $51
	db $52
	db $71
	db $71
	db $72
	db $C8
	db $F2, $F0
	db $74
	db $F2, $A0
	db $FC
	db $F7
	dw Mus_Wily2C_1
	db $42
	db $41
	db $41
	db $E1
	db $B2
	db $B1
	db $B1
	db $82
	db $81
	db $81
	db $42
	db $41
	db $41
	db $F7
	dw Mus_Wily2C_1
	db $42
	db $41
	db $41
	db $22
	db $21
	db $21
	db $02
	db $01
	db $01
	db $E1
	db $B2
	db $B1
	db $B1
	db $E1
	db $FB
	db $92
	db $91
	db $91
	db $FD, $07
	db $E2
	db $FB
	db $22
	db $21
	db $21
	db $FD, $07
	db $E1
	db $FB
	db $72
	db $71
	db $71
	db $FD, $03
	db $E2
	db $FB
	db $22
	db $21
	db $21
	db $FD, $03
	db $E1
	db $FB
	db $92
	db $91
	db $91
	db $FD, $03
	db $E2
	db $FB
	db $22
	db $21
	db $21
	db $FD, $03
	db $FE, $00
Mus_Wily2C_1:
	db $E1
	db $FB
	db $92
	db $91
	db $91
	db $FD, $03
	db $FB
	db $72
	db $71
	db $71
	db $FD, $03
	db $FB
	db $52
	db $51
	db $51
	db $FD, $03
	db $E2
	db $FB
	db $02
	db $01
	db $01
	db $FD, $03
	db $FB
	db $22
	db $21
	db $21
	db $FD, $03
	db $FB
	db $02
	db $01
	db $01
	db $FD, $03
	db $FB
	db $22
	db $21
	db $21
	db $FD, $03
	db $F9
Mus_Wily2D:
	db $D6
	db $FB
	db $31
	db $31
	db $34
	db $31
	db $31
	db $34
	db $31
	db $31
	db $32
	db $FD, $02
	db $31
	db $31
	db $32
	db $71
	db $71
	db $81
	db $81
	db $94
	db $24
	db $FC
	db $FB
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FD, $0E
	db $12
	db $11
	db $11
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
	db $FD, $0E
	db $32
	db $11
	db $11
	db $31
	db $31
	db $31
	db $31
	db $22
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
	db $FD, $02
	db $22
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
	db $FD, $02
	db $FB
	db $22
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
	db $FD, $03
	db $FE, $00

Mus_Wily1B:
	db $D6, $01, $B1, $43, $8B, $16, $C3
	db $E1
	db $42
	db $42
	db $E2
	db $92
	db $E3
	db $02
	db $C2
	db $62
	db $C2
	db $50
	db $C2
	db $E1
	db $42
	db $42
	db $E2
	db $92
	db $E3
	db $02
	db $C2
	db $72
	db $C2
	db $6E
	db $D6, $22, $B1, $43, $8B, $16, $C3
	db $FC
	db $FB
	db $E2
	db $91
	db $E3
	db $01
	db $21
	db $4D
	db $E2
	db $91
	db $E3
	db $01
	db $41
	db $3D
	db $E2
	db $91
	db $E3
	db $01
	db $31
	db $2D
	db $E2
	db $91
	db $E3
	db $01
	db $21
	db $33
	db $21
	db $01
	db $21
	db $01
	db $E2
	db $91
	db $83
	db $92
	db $FD, $01
	db $C4
	db $E8, $01
	db $E1
	db $32
	db $42
	db $92
	db $82
	db $31
	db $41
	db $91
	db $82
	db $82
	db $81
	db $92
	db $E2
	db $02
	db $42
	db $32
	db $E1
	db $91
	db $E2
	db $01
	db $41
	db $32
	db $32
	db $31
	db $42
	db $52
	db $92
	db $82
	db $41
	db $51
	db $91
	db $82
	db $82
	db $81
	db $B1
	db $B1
	db $C4
	db $B1
	db $B1
	db $C4
	db $E8, $22
	db $FE, $00
Mus_Wily1A:
	db $D6, $11, $91, $43, $89, $15, $C3
	db $E0
	db $92
	db $92
	db $E2
	db $42
	db $92
	db $C2
	db $E3
	db $22
	db $C2
	db $20
	db $C2
	db $E0
	db $92
	db $92
	db $E2
	db $42
	db $92
	db $C2
	db $E3
	db $22
	db $C2
	db $2E
	db $E2
	db $D6, $11, $91, $43, $89, $15, $C3
	db $FC
	db $FB
	db $E2
	db $41
	db $91
	db $91
	db $9D
	db $41
	db $91
	db $E3
	db $01
	db $0D
	db $E2
	db $41
	db $91
	db $E3
	db $01
	db $E2
	db $9D
	db $41
	db $91
	db $B1
	db $E3
	db $03
	db $E2
	db $B1
	db $91
	db $B1
	db $91
	db $41
	db $33
	db $42
	db $FD, $01
	db $C4
	db $E0
	db $B2
	db $B2
	db $E1
	db $42
	db $42
	db $E0
	db $B1
	db $B1
	db $E1
	db $41
	db $42
	db $42
	db $41
	db $42
	db $92
	db $E2
	db $02
	db $02
	db $E1
	db $41
	db $91
	db $E2
	db $01
	db $02
	db $02
	db $01
	db $E1
	db $B2
	db $B2
	db $E2
	db $42
	db $42
	db $E1
	db $B1
	db $B1
	db $E2
	db $41
	db $42
	db $42
	db $41
	db $41
	db $41
	db $C4
	db $41
	db $41
	db $C4
	db $FE, $00
Mus_Wily1C:
	db $D6, $06, $82, $B0
	db $E1
	db $92
	db $92
	db $CC
	db $C0
	db $92
	db $92
	db $CC
	db $CC
	db $FC
	db $FB
	db $42
	db $41
	db $93
	db $92
	db $92
	db $92
	db $92
	db $92
	db $92
	db $91
	db $E2
	db $33
	db $E1
	db $92
	db $92
	db $92
	db $92
	db $92
	db $92
	db $91
	db $E2
	db $23
	db $E1
	db $92
	db $92
	db $92
	db $92
	db $92
	db $92
	db $91
	db $E2
	db $03
	db $E1
	db $B1
	db $91
	db $B1
	db $91
	db $91
	db $83
	db $92
	db $FD, $01
	db $C4
	db $32
	db $42
	db $C9
	db $42
	db $41
	db $92
	db $92
	db $C9
	db $92
	db $91
	db $42
	db $42
	db $C9
	db $42
	db $41
	db $41
	db $41
	db $C4
	db $41
	db $41
	db $C4
	db $FE, $00
Mus_Wily1D:
	db $D6
	db $32
	db $32
	db $FB
	db $14
	db $FD, $06
	db $32
	db $32
	db $FB
	db $14
	db $FD, $05
Mus_Wily1D_1:
	db $FB
	db $31
	db $31
	db $31
	db $FC
	db $23
	db $12
	db $32
	db $12
	db $12
	db $12
	db $32
	db $11
	db $FE, $02
	db $23
	db $12
	db $31
	db $31
	db $31
	db $33
	db $32
	db $FD, $01
	db $C4
	db $FB
	db $32
	db $32
	db $22
	db $12
	db $22
	db $11
	db $22
	db $31
	db $31
	db $31
	db $FD, $02
	db $31
	db $31
	db $12
	db $12
	db $31
	db $31
	db $12
	db $12
	db $F7
	dw Mus_Wily1D_1

Mus_GetWeaponB:
	db $D5, $22, $91, $00, $89, $11, $F0
	db $EC, $03
	db $FB
	db $E5
	db $41
	db $31
	db $21
	db $11
	db $01
	db $E4
	db $B1
	db $A1
	db $91
	db $FD, $03
	db $D5, $10, $B1, $42, $8B, $26, $C5
	db $FB
	db $E1
	db $94
	db $E2
	db $04
	db $E1
	db $B2
	db $74
	db $94
	db $92
	db $E2
	db $24
	db $E1
	db $B2
	db $76
	db $E2
	db $06
	db $2A
	db $56
	db $74
	db $E8, $01
	db $44
	db $72
	db $EC, $0F
	db $FD, $01
	db $90
	db $D5, $01, $81, $42, $88, $25, $C7
	db $FB
	db $90
	db $FD, $00
Mus_GetWeaponA:
	db $D5, $22, $91, $00, $89, $11, $F0
	db $EC, $03
	db $F3, $00
	db $FB
	db $E5
	db $01
	db $E4
	db $B1
	db $A1
	db $91
	db $E5
	db $41
	db $31
	db $21
	db $11
	db $FD, $03
	db $F3, $03
	db $D5, $10, $A1, $43, $8A, $26, $C5
	db $FB
	db $E1
	db $44
	db $94
	db $72
	db $24
	db $44
	db $42
	db $94
	db $72
	db $26
	db $96
	db $BA
	db $E2
	db $06
	db $24
	db $E8, $01
	db $E1
	db $B4
	db $E2
	db $22
	db $EC, $0F
	db $FD, $01
	db $FB
	db $40
	db $D5, $01, $61, $42, $86, $23, $C7
	db $20
	db $00
	db $E1
	db $B0
	db $E2
	db $FD, $00
Mus_GetWeaponC:
	db $D5, $06, $84, $C0
	db $EC, $03
	db $C0
	db $CC
	db $E1
	db $41
	db $41
	db $41
	db $41
	db $FB
	db $92
	db $92
	db $E2
	db $92
	db $E1
	db $92
	db $72
	db $E2
	db $74
	db $E1
	db $94
	db $92
	db $E2
	db $92
	db $E1
	db $92
	db $72
	db $E2
	db $74
	db $E1
	db $72
	db $54
	db $E2
	db $02
	db $E1
	db $74
	db $E2
	db $24
	db $E1
	db $72
	db $54
	db $E2
	db $02
	db $E1
	db $74
	db $E2
	db $24
	db $E1
	db $72
	db $FD, $01
	db $F2, $B0
	db $FC
	db $FB
	db $92
	db $91
	db $91
	db $FD, $03
	db $FB
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
	db $72
	db $71
	db $71
	db $FD, $03
	db $FE, $00
	db $FF
Mus_GetWeaponD:
	db $D5
	db $C4
	db $14
	db $C4
	db $14
	db $C4
	db $14
	db $C4
	db $31
	db $31
	db $31
	db $31
	db $FB
	db $24
	db $34
	db $12
	db $12
	db $32
	db $24
	db $12
	db $34
	db $12
	db $12
	db $32
	db $12
	db $32
	db $12
	db $12
	db $24
	db $32
	db $12
	db $32
	db $32
	db $12
	db $12
	db $24
	db $32
	db $32
	db $31
	db $31
	db $FD, $01
	db $FB
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FD, $00
	db $FF

Mus_TitleB:
	db $EC, $06
	db $DC, $22, $B1, $22, $98, $26, $C5
	db $E1
	db $93
	db $E2
	db $43
	db $22
	db $72
	db $62
	db $41
	db $22
	db $40
	db $C1
	db $E1
	db $93
	db $E2
	db $43
	db $22
	db $72
	db $62
	db $41
	db $72
	db $90
	db $C1
	db $F6, $0A
	db $C8
	db $FC
	db $DA, $01, $B1, $23, $8B, $16, $C3
	db $E1
	db $C2
	db $92
	db $E2
	db $41
	db $22
	db $71
	db $C1
	db $72
	db $61
	db $41
	db $22
	db $40
	db $C1
	db $E1
	db $C2
	db $92
	db $E2
	db $41
	db $22
	db $71
	db $C1
	db $72
	db $61
	db $41
	db $72
	db $90
	db $C1
	db $C2
	db $E3
	db $02
	db $E2
	db $92
	db $C1
	db $E3
	db $01
	db $C1
	db $02
	db $E2
	db $91
	db $B1
	db $E3
	db $03
	db $E2
	db $B3
	db $7D
	db $C2
	db $A2
	db $52
	db $C1
	db $A1
	db $C1
	db $A2
	db $71
	db $91
	db $A2
	db $90
	db $C1
	db $E8, $22
	db $FB
	db $E2
	db $23
	db $95
	db $C2
	db $62
	db $72
	db $92
	db $93
	db $A1
	db $AC
	db $A3
	db $E3
	db $25
	db $C2
	db $E2
	db $A2
	db $E3
	db $22
	db $52
	db $53
	db $71
	db $7C
	db $FD, $01
	db $FE, $00
Mus_TitleA:
	db $EC, $06
	db $D6, $22, $A1, $22, $97, $25, $C6
	db $C1
	db $EF, $01
	db $E1
	db $96
	db $E2
	db $46
	db $24
	db $74
	db $64
	db $42
	db $24
	db $41
	db $D6, $22, $81, $22, $95, $25, $C6
	db $E1
	db $96
	db $E2
	db $46
	db $24
	db $74
	db $64
	db $42
	db $24
	db $43
	db $D6, $22, $A1, $22, $97, $25, $C6
	db $E1
	db $96
	db $E2
	db $46
	db $24
	db $74
	db $64
	db $42
	db $74
	db $91
	db $D6, $22, $81, $22, $95, $25, $C6
	db $E1
	db $96
	db $E2
	db $46
	db $24
	db $74
	db $64
	db $42
	db $74
	db $92
	db $F6, $0A
	db $C8
	db $EF, $00
	db $FC
	db $DA, $11, $B1, $23, $8B, $16, $C3
	db $E1
	db $C2
	db $42
	db $E2
	db $01
	db $E1
	db $92
	db $E2
	db $21
	db $C1
	db $22
	db $21
	db $E1
	db $B1
	db $B2
	db $E2
	db $09
	db $E1
	db $B5
	db $E2
	db $01
	db $E1
	db $B1
	db $71
	db $92
	db $42
	db $E2
	db $01
	db $E1
	db $92
	db $E2
	db $21
	db $C1
	db $22
	db $21
	db $E1
	db $B1
	db $E2
	db $22
	db $49
	db $25
	db $01
	db $E1
	db $B1
	db $71
	db $52
	db $E2
	db $92
	db $52
	db $C1
	db $91
	db $C1
	db $92
	db $51
	db $71
	db $93
	db $73
	db $45
	db $03
	db $E1
	db $75
	db $52
	db $E2
	db $52
	db $22
	db $C1
	db $51
	db $C1
	db $52
	db $21
	db $41
	db $52
	db $49
	db $F6, $05
	db $E0
	db $91
	db $81
	db $91
	db $B1
	db $E1
	db $11
	db $01
	db $11
	db $21
	db $41
	db $31
	db $41
	db $61
	db $71
	db $91
	db $B1
	db $E2
	db $11
	db $F6, $0A
	db $E8, $01
	db $FB
	db $E1
	db $93
	db $E2
	db $65
	db $C2
	db $22
	db $42
	db $62
	db $33
	db $71
	db $7C
	db $53
	db $A5
	db $C2
	db $52
	db $A2
	db $E3
	db $22
	db $03
	db $41
	db $4C
	db $FD, $01
	db $FE, $00
Mus_TitleC:
	db $EC, $06
	db $DC, $06, $86, $A0
	db $FB
	db $E1
	db $93
	db $95
	db $E2
	db $23
	db $25
	db $FD, $02
	db $E1
	db $93
	db $95
	db $E2
	db $23
	db $25
	db $F6, $0A
	db $C8
	db $FC
	db $DA, $01, $83, $B0
	db $E1
	db $FB
	db $91
	db $91
	db $91
	db $92
	db $91
	db $91
	db $91
	db $71
	db $71
	db $71
	db $72
	db $71
	db $71
	db $71
	db $FD, $03
	db $FB
	db $51
	db $51
	db $51
	db $52
	db $51
	db $51
	db $51
	db $FD, $01
	db $E2
	db $FB
	db $01
	db $01
	db $01
	db $02
	db $01
	db $01
	db $01
	db $FD, $01
	db $E1
	db $FB
	db $A1
	db $A1
	db $A1
	db $A2
	db $A1
	db $A1
	db $A1
	db $FD, $01
	db $91
	db $91
	db $91
	db $92
	db $91
	db $91
	db $91
	db $91
	db $91
	db $91
	db $92
	db $91
	db $B1
	db $E2
	db $11
	db $F7
	dw Mus_TitleC_1
	db $F7
	dw Mus_TitleC_1
	db $FE, $00
Mus_TitleC_1:
	db $E2
	db $FB
	db $21
	db $FD, $0F
	db $FB
	db $31
	db $FD, $0F
	db $E1
	db $FB
	db $A1
	db $FD, $0F
	db $E2
	db $FB
	db $01
	db $FD, $0F
	db $F9
Mus_TitleD:
	db $D6
	db $FB
	db $26
	db $26
	db $34
	db $FD, $07
	db $D5
	db $12
	db $42
	db $42
	db $42
	db $82
	db $82
	db $92
	db $92
	db $FC
	db $FB
	db $12
	db $12
	db $32
	db $24
	db $12
	db $32
	db $12
	db $FD, $0E
	db $12
	db $12
	db $32
	db $24
	db $32
	db $32
	db $31
	db $31
	db $FB
	db $12
	db $12
	db $32
	db $12
	db $FD, $0E
	db $12
	db $32
	db $32
	db $32
	db $FB
	db $12
	db $12
	db $32
	db $12
	db $FD, $0E
	db $12
	db $32
	db $32
	db $31
	db $31
	db $FE, $00

Mus_PasswordB:
	db $EC, $02
	db $FC
	db $D7, $01, $71, $44, $97, $24, $A7
	db $E2
	db $FB
	db $90
	db $70
	db $60
	db $52
	db $52
	db $C8
	db $51
	db $73
	db $FD, $01
	db $D7, $21, $B1, $44, $9B, $26, $A7
	db $FB
	db $E3
	db $0E
	db $E2
	db $B1
	db $91
	db $4E
	db $41
	db $B1
	db $E3
	db $0E
	db $E2
	db $B1
	db $71
	db $9C
	db $91
	db $B3
	db $FD, $01
	db $E8, $01
	db $FE, $00
Mus_PasswordA:
	db $EC, $02
	db $D7, $01, $71, $44, $97, $24, $A7
	db $E2
	db $FC
	db $FB
	db $40
	db $20
	db $10
	db $02
	db $02
	db $C8
	db $01
	db $23
	db $FD, $01
	db $FB
	db $90
	db $70
	db $60
	db $5C
	db $51
	db $73
	db $FD, $01
	db $FE, $00
Mus_PasswordC:
	db $EC, $02
	db $D7, $05, $83, $A0
	db $E1
	db $FC
	db $FB
	db $92
	db $92
	db $42
	db $41
	db $32
	db $32
	db $31
	db $42
	db $72
	db $FD, $02
	db $92
	db $92
	db $42
	db $41
	db $32
	db $32
	db $31
	db $41
	db $73
	db $FE, $00
Mus_PasswordD:
	db $D7
	db $FC
	db $FB
	db $12
	db $12
	db $32
	db $11
	db $22
	db $22
	db $11
	db $32
	db $12
	db $FD, $02
	db $32
	db $32
	db $C8
	db $31
	db $23
	db $FB
	db $12
	db $12
	db $32
	db $11
	db $22
	db $22
	db $11
	db $32
	db $12
	db $FD, $02
	db $32
	db $32
	db $C8
	db $31
	db $23
	db $FB
	db $12
	db $12
	db $32
	db $11
	db $22
	db $22
	db $11
	db $32
	db $12
	db $FD, $02
	db $12
	db $12
	db $32
	db $11
	db $22
	db $22
	db $11
	db $31
	db $23
	db $FB
	db $12
	db $12
	db $32
	db $11
	db $22
	db $22
	db $11
	db $32
	db $12
	db $FD, $02
	db $12
	db $12
	db $32
	db $11
	db $22
	db $22
	db $11
	db $31
	db $23
	db $FE, $00

FreqTab:
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

;Load song/sound effect
LoadSong:
	;If song is 0
	or a
	jp z, NoAudio

	;If song is $0A, then fade out current music
	cp $0A
	jp z, FadeOutMus

	push bc
	push de
	;Load number to SFX number RAM variable
	ld [SFXNum], a
	;Get pointer from song table
	add a
	add LOW(SongTab)
	ld l, a
	ld a, HIGH(SongTab)
	adc 0
	ld h, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	
	;Load header values into RAM
	ld a, [hl+]
	ld [Temp1], a		;Byte 1 = Channel mask
	ld a, [hl+]
	ld [Temp2], a		;Byte 2 = priority
	ld b, h
	ld c, l
	;Set channel number to 0
	xor a
	ld [CurTrack], a
	ld de, MusC1RAM

GetTracks:
	;Check if each track (SFX 4-1, then music 4-1) is present
	ld hl, Temp1
	srl [hl]
	;If track present
	jr c, .InitTrackRAM

	;When finished
	jr z, .LoadSongRet

.NextTrack
	;Advance channel
	ld hl, CurTrack
	inc [hl]
	;Skip to next channel area in RAM
	ld hl, TrackRAMSize
	add hl, de
	ld d, h
	ld e, l
	jr GetTracks

.LoadSongRet
;Return from routine
	pop de
	pop bc
	ret


.InitTrackRAM
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
	jr .NextTrack

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
	ld a, LOW(Vibrato0)
	ld [hl+], a
	ld a, HIGH(Vibrato0)
	ld [hl], a
	pop bc
	;Add current channel mask to output value
	ld a, [CurTrack]
	add LOW(TrackMaskVals)
	ld l, a
	ld a, HIGH(TrackMaskVals)
	adc 0
	ld h, a
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
	jr .NextTrack

;Call sound effect with music
CallSFX:
	;Get sound effect number called
	push bc
	push de
	ld [SFXNum], a
	;Get sound effect pointer from RAM
	add a
	add LOW(SongTab)
	ld l, a
	ld a, HIGH(SongTab)
	adc 0
	ld h, a
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
	ld de, SFXC1RAM
	jp GetTracks


FadeOutMus:
	ld a, 7
	ld [Fade], a
	ld [FadeTime], a
	ret


PlayAudio:
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
	jp z, NoAudio

	sub %00010001
	ld [hl], a

.PlayAudio2
	call CheckAllTracks
	jp OutputTracks


CheckAllTracks:
	;Check all tracks to see if they are playing
	xor a
	ld [CurTrackCheck], a
	ld de, MusC1MusNum

CheckTrack:
	;Check if track is on (with song number)
	ld hl, $00
	add hl, de
	ld a, [hl]
	or a
	;If 0, then skip to next track
	jr z, NextTrack

	;Process the track
	call ProcTrack
	;Copy values to register RAM values
	call ProcTrackRegVals

NextTrack:
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
	jr nz, CheckTrack

	ret


ProcTrack:
	;Process note length
	ld hl, $08
	add hl, de								;Increase time
	inc [hl]
	dec hl
	dec [hl]								;Decrease delay
	;If delay is complete, then get next command
	call z, NextCommand
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
	jp nc, ProcVibrato

	;Check if wave channel
	ld a, [CurTrackCheck]
	and %00000011
	cp 2
	;If so, then perform special envelope handler
	jp z, ProcEnvStateCh3

ProcEnvState:
	;Otherwise, this is a decaying (CH1/CH2) envelope.
	;Wait out the current envelope stage.
	ld hl, $1A
	add hl, de
	dec [hl]
	;If not 0, then skip
	jp nz, EnvSustain

	;Stage expired: pick the handler for the current envelope state.
	;State # is kept in +$18 and indexes the table below.
	ld hl, $18
	add hl, de
	ld a, [hl]
	add a
	add LOW(EnvStates)
	ld l, a
	ld a, HIGH(EnvStates)
	adc 0
	ld h, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	jp hl

EnvStates:
	dw EnvState0
	dw EnvState1
	dw EnvState2
	dw EnvState3
	dw EnvState4
	dw EnvSustain
	dw EnvSustain
	dw EnvSustain
	
EnvState0:
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
	jr c, EnvState1_2

	;Otherwise, multiply the volume by decay
	call Multiply
	;If result is 0, then skip to next state
	or a
	jr z, EnvState1_2

	;Otherwise, then save stage duration into RAM
	pop bc
	jp SaveStageDur

EnvState1:
	push bc

EnvState1_2:
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
	jr c, EnvState2_1

	call Multiply
	or a
	;If result is 0, then skip to next state
	jr z, EnvState2_1

	pop bc
	jp SaveStageDur

EnvState2:
	push bc

EnvState2_1:
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
	jr c, EnvState3_2

	jr z, EnvState3_2

	;Otherwise, then save stage duration into RAM
	pop bc
	jp SaveStageDur

EnvState3:
	push bc

EnvState3_2:
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
	jr c, EnvState4_1

	;Multiply values otherwise
	call Multiply
	or a
	;If 0, then go to next stage
	jr z, EnvState4_1

	;Otherwise, then save stage duration into RAM 
	pop bc
	jp SaveStageDur


EnvState4_1:
	pop bc
EnvState4:
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
	jp SaveStageDur


ProcEnvStateCh3:
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
	jr c, EnvState1Ch3

	cp 2
	jr c, EnvState2Ch3

	cp 3
	jr c, EnvState3Ch3

	cp 4
	jr c, EnvState4Ch3

	;If none of the above, then return
	ret


EnvState1Ch3:
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


EnvState2Ch3:
	;Get new volume
	ld a, %01010000

EnvState2Ch3_2:
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


EnvState3Ch3:
	;Get new volume
	ld a, %00010000
	;Rest of state is same as 2
	jr EnvState2Ch3_2

EnvState4Ch3:
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
ProcVibrato:
	ld hl, $1A
	add hl, de
	dec [hl]
	;If not done, then sustain
	jr nz, EnvSustain

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
	jr nz, GetVol

	;Decrement sequence position
	ld hl, $17
	add hl, de
	dec [hl]
	;Restart envelope duration
	ld hl, $1A
	add hl, de
	ld [hl], a
	jr EnvSustain

GetVol:
	;Get volume from upper 4 bits of envelope
	ld hl, $1F
	add hl, de
	push af
	and %11110000
	ld [hl], a
	;Then get duration from lower 4 bits of envelope
	pop af
	and %00001111

SaveStageDur:
	;Load stage duration into RAM value
	ld hl, $1A
	add hl, de
	ld [hl], a

;After envelope is finished...
EnvSustain:
	;If channel is 2, then return
	ld a, [CurTrackCheck]
	and 2
	jr nz, ProcNextVibratoRet

	;Otherwise, decrease vibrato sequence delay
	ld hl, $19
	add hl, de
	dec [hl]
	;If not done, then return
	jp nz, ProcNextVibratoRet

	;Increase vibrato sequence
	ld hl, $16
	add hl, de
	inc [hl]
	ld a, [hl]

ProcNextVibrato:
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
	jr ProcNextVibrato

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

ProcNextVibratoRet:
	ret


NextCommand:
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
	call ParamsOrVCMD
	;Repeat
	jr .NextCommand2

.NoteOrRest
	;Check if track is 3 (music 4)
	ld a, [CurTrackCheck]
	cp 3
	;If so, then use special handler
	jp z, ProcNoteMusC4

	;Otherwise, load envelope on/off address value into HL
	ld hl, $09
	add hl, de
	;Check current command
	ld a, [bc]
	cp $C0
	;If less than C0, then is a note
	jr c, ProcNote

	;Otherwise, is a rest
	ld [hl], 0
	jp ProcNoteMusC4_3


;It is a note
ProcNote:
	;Set envelope on/off value to on
	ld [hl], $FF
	push bc
	push af
	;Check if track is SFX 4
	ld a, [CurTrackCheck]
	cp 7
	;If so, then perform special handler
	jr z, ProcNoteSFXCh4

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
	
	;Get frequency from table
	add a
	add LOW(FreqTab)
	ld c, a
	ld a, HIGH(FreqTab)
	adc 0
	ld b, a
	
	;Load frequency into RAM
	ld hl, $1D
	add hl, de
	ld a, [bc]
	ld [hl+], a
	inc bc
	ld a, [bc]
	ld [hl], a
	pop bc
	jr ProcNote2

ProcNoteSFXCh4:
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

ProcNote2:
	;Reset note time
	ld hl, $08
	add hl, de
	xor a
	ld [hl], a
	
	;Get note length value
	ld a, [bc]
	and %00001111
	;Convert to actual note length with speed
	call ProcNoteLen
	
	;Set delay to result
	ld hl, $07
	add hl, de
	ld [hl], a
	
	;Advance pointer
	call AdvChanPos
	
	;Check for duty/volume flag
	ld hl, $11
	add hl, de
	;If highest bit not set, then skip processing delay
	bit 7, [hl]
	jr z, ProcDelay
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
	call Multiply
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
	call Multiply
	add [hl]
	ld [hl], a

ProcDelay:
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


ProcNoteMusC4:
	;Get channel 3 SFX number
	ld a, [SFXC3MusNum]
	
	;If between $06 and $12, cue a tom-tom drum
	cp $06
	jr c, ProcNoteMusC4_2

	cp $0C
	jr nc, ProcNoteMusC4_2

	;Set pointer to "empty sequence"
	ld a, LOW(EmptySeq)
	ld [SFXC3SongPos], a
	ld a, HIGH(EmptySeq)
	ld [SFXC3SongPos+1], a
	
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

ProcNoteMusC4_2:
	;Get current note value from upper 4 bits of sequence byte
	ld a, [bc]
	swap a
	;If less than $0C, then use the value to play SFX as "percussion"
	and %00001111
	cp $0C
	call nz, CallSFX

ProcNoteMusC4_3:
	;Get length as lower 4 bits and process the note length
	ld a, [bc]
	and %00001111
	call ProcNoteLen
	
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
AdvChanPos:
	ld hl, $20
	add hl, de
	inc bc
	ld [hl], c
	inc hl
	ld [hl], b
	ret


ProcNoteLen:
	;Check if note length is 0
	ld hl, $0B
	add hl, de
	or a
	;If so, then set to maximum speed value
	jr z, ProcNoteLenMax

	;Otherwise, check if less than speed
	cp [hl]
	;If not, then multiply (same as otherwise?)
	jr nc, ProcNoteLenMult2

	;Otherwise, multiply value
	push bc
	ld c, a
	ld b, [hl]
	xor a

ProcNoteLenMult:
	add b
	dec c
	jr nz, ProcNoteLenMult

	pop bc
	ret


;Multiply value (same as before?)
ProcNoteLenMult2:
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


ProcNoteLenMax:
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
Multiply:
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


ParamsOrVCMD:
	;If Dx, is parameters
	sub $E0
	jr c, GetParams

	;Otherwise, is a VCMD - get pointer to jump to from table
	add a
	add LOW(VCMDTab)
	ld l, a
	ld a, HIGH(VCMDTab)
	adc 0
	ld h, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	jp hl


GetParams:
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
	jr z, GetParamsSFX4

	;If current track is 2 or 6 (music/SFX 3, then perform special handler)
	and %00000011
	cp 2
	jr z, GetParams3

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
	call EventVibrato
	;Final bytes are envelope and decay (if envelope is signed)
	jp GetEnvVal


GetParamsSFX4:
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
	jp EventEnvDecay


GetParams3:
	;Current byte is waveform
	dec bc
	call EventWaveform
	;Next byte is envelope value
	ld a, [bc]
	ld hl, $11
	add hl, de
	ld [hl+], a
	;Check if envelope is at max
	add a
	;If not, then set envelope sequence
	jp nc, GetEnvSeq

	;Otherwise, next byte is secondary decay
	inc bc
	inc hl
	ld a, [bc]
	ld [hl], a
	inc bc
	ret

VCMDTab:
	dw EventOctave			;E0
	dw EventOctave			;E1
	dw EventOctave			;E2
	dw EventOctave			;E3
	dw EventOctave			;E4
	dw EventOctave			;E5
	dw EventOctave			;E6
	dw EventOctave			;E7
	dw EventDutyVol			;E8
	dw EventDecay			;E9
	dw EventSweep			;EA
	dw EventVibrato			;EB
	dw EventTranspose		;EC
	dw EventWaveform		;ED
	dw EventEnvDecay		;EE
	dw EventTuning			;EF
	dw EventEnvVal			;F0
	dw EventDecay2			;F1
	dw EventDecay3			;F2
	dw EventFinalVol		;F3
	dw EventNop				;F4
	dw EventNop				;F5
	dw EventSpeed			;F6
	dw EventMacro1			;F7
	dw EventMacro2			;F8
	dw EventMacro1Ret		;F9
	dw EventMacro2Ret		;FA
	dw EventRepeat1Start	;FB
	dw EventRepeat2Start	;FC
	dw EventRepeat1End		;FD
	dw EventRepeat2End		;FE
	dw EventEnd				;FF
	
EventOctave:
;Set the current octave (0-7)
	;Get lower 3 bits of command byte
	ld a, [bc]
	and a, %00000111
	;Store as octave in RAM
	ld hl, $1B
	add hl, de
	jr StoreVal
	
EventDutyVol:
;Set duty/volume
;Parameters: xxxxxxxx (x = value)
	inc bc
	;If track is SFX 4, then perform separate handler
	ld a, [CurTrackCheck]
	cp a, 7
	jr z, .EventDutyVol_SFX4
	ld a, [bc]
	;Mask out bits and multiply to get final value
	and %00110011
	add a
	add a
	ld hl, $0C
	add hl, de
	jr StoreVal

.EventDutyVol_SFX4
	ld a, [bc]
	or a
	jr z, .EventDutyVol_2

	ld a, 8

.EventDutyVol_2
	;Store final value in RAM
	ld hl, $0C
	add hl, de
	jr StoreVal

EventDecay:
;Set decay
;Parameters: xxxxxxxx (x = value)
	ld hl, $0D
	add hl, de
	inc bc
	ld a, [bc]

StoreVal:
	ld [hl], a

EventNop:
;Do nothing but skip a byte
;Parameters: -------- (- = unused)
NextByte:
	inc bc
	ret

EventSweep:
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


EventVibrato:
;Set vibrato
;Parameters: xxxxxxxx (x = value)
	;First, get note envelope length from upper 4 bits
	inc bc
	ld a, [bc]
	swap a
	and %00001111
	call ProcNoteLen
	;Then, get vibrato
	ld hl, $0E
	add hl, de
	inc a
	ld [hl+], a
	ld a, [bc]
	and %00001111
	push bc
	add a
	add LOW(VibTab)
	ld c, a
	ld a, HIGH (VibTab)
	adc 0
	ld b, a

StorePtr:
	;Store pointer into RAM
	ld a, [bc]
	ld [hl+], a
	inc bc
	ld a, [bc]
	ld [hl], a
	pop bc
	inc bc
	ret


EventTranspose:
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


EventWaveform:
;Set waveform
;Parameters: xxxxxxxx (x = value)
	;Check current track and set its respective waveform
	ld a, [CurTrackCheck]
	cp 2
	jr z, .EventWaveform2

	cp 6
	;If neither channel 3 tracks, then do nothing
	jr nz, EventNop

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


EventEnvDecay:
;Set duty/volume and decay 2/3
;Parameters: xyyyyyyy (zzzzzzzz aaaaaaaa)  (x = if set, z and a are used, z = decay 2, a = decay 3)
	inc bc

GetEnvVal:
	;Get envelope value from byte
	ld a, [bc]
	ld hl, $11
	add hl, de
	ld [hl+], a
	;If signed, then get decay parameters from next 2 bytes
	add a
	jr c, GetDecay

GetEnvSeq:
	;Get envelope sequence number from parameter
	ld a, [bc]
	push bc
	;Get envelope sequence pointer from table
	add a
	add LOW(EnvSeqTab)
	ld c, a
	ld a, HIGH(EnvSeqTab)
	adc 0
	;Load pointer into RAM
	ld b, a
	ld hl, $14
	add hl, de
	jr StorePtr

;Get decay parameters
GetDecay:
	inc bc
	ld a, [bc]
	ld [hl+], a
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret


EventTuning:
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


EventEnvVal:
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


EventDecay2:
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


EventDecay3:
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


EventFinalVol:
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


EventSpeed:
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


EventMacro1:
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


EventMacro2:
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


EventMacro1Ret:
;Return from macro (subroutine) (1)
	;Go to position in RAM
	ld hl, $26
	add hl, de
	ld a, [hl+]
	ld b, [hl]
	ld c, a
	ret


EventMacro2Ret:
;Return from macro (subroutine) (2)
	;Go to position in RAM
	ld hl, $28
	add hl, de
	ld a, [hl+]
	ld b, [hl]
	ld c, a
	ret


EventRepeat1Start:
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


EventRepeat2Start:
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


EventRepeat1End:
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
	jr z, EventRepeatEnd_Done

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
EventRepeatEnd_Done:
	ld [hl], 0
	jp EventNop


EventRepeat2End:
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
	jr z, EventRepeatEnd_Done

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


EventEnd:
;End of track
	;Get channel mask and add to output
	ld a, [CurTrackCheck]
	add LOW(ChanMaskVals)
	ld c, a
	ld a, HIGH(ChanMaskVals)
	adc 0
	ld b, a
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

ChanMaskVals:
	db $FE, $FD, $FB, $F7, $EF, $DF, $BF, $7F
	
TrackMaskVals:
	db $01, $02, $04, $08, $10, $20, $40, $80

ProcTrackRegVals:
	;Get pointer for track routine
	ld a, [CurTrackCheck]
	add a
	add LOW(PrepStates)
	ld l, a
	ld a, HIGH(PrepStates)
	adc 0
	ld h, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	jp hl

PrepStates:
	dw MusC1Prep
	dw MusC2Prep
	dw MusC3Prep
	dw MusC4Prep
	dw SFXC1Prep
	dw SFXC2Prep
	dw SFXC3Prep
	dw SFXC4Prep

MusC1Prep:
	;Check if SFX is playing in channel 1
	ld hl, SFXC1MusNum
	ld a, [hl]
	or a
	;Return if so
	ret nz

;Otherwise, get duty/pan value from table
SFXC1Prep:
	ld hl, $06
	add hl, de
	ld a, [hl]
	and %00000011
	add LOW(Duty1PanTab)
	ld l, a
	ld a, HIGH(Duty1PanTab)
	adc 0
	ld h, a
	
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

MusC1Prep_2:
	;If note time is 0, then set duty/volume value to it
	or a
	jr z, MusC1Prep_3A

	;Otherwise, set it and swap
	ld hl, $0C
	add hl, de
	ld a, [hl]
	swap a
	jr MusC1Prep_3B

MusC1Prep_3A:
	ld hl, $0C
	add hl, de
	ld a, [hl]

MusC1Prep_3B:
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
	jr nz, MusC1Prep_4

	;If not, then use empty value
	ld a, %00001000
	jr MusC1Prep_5

MusC1Prep_4:
	;Get hardware volume
	ld hl, $1F
	add hl, de
	ld a, [hl]

MusC1Prep_5:
	;Set NR12 value to it
	ld [bc], a
	inc bc

MusC1Prep_6:
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
	jr nz, MusC1Prep_Neg

	;If positive, then add to frequency
	add [hl]
	inc hl
	;And set NR13 value to it
	ld [bc], a
	ld a, [hl]
	adc 0

MusC1Prep_7:
	;Set NR14 value
	inc bc
	and %00000111
	ld [bc], a
MusC4Prep:
	;Do nothing
	ret


MusC1Prep_Neg:
	;If negative, then add negative to frequency
	add [hl]
	push af
	inc hl
	ld [bc], a
	pop af
	ld a, [hl]
	adc -1
	jr MusC1Prep_7

MusC2Prep:
	;Check if SFX is playing in channel 2
	ld hl, SFXC2MusNum
	ld a, [hl]
	or a
	;Return if so
	ret nz

;Otherwise, get duty/pan value from table
SFXC2Prep:
	ld hl, $06
	add hl, de
	ld a, [hl]
	and %00000011
	add LOW(Duty2PanTab)
	ld l, a
	ld a, HIGH(Duty2PanTab)
	adc 0
	ld h, a
	
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
	jr MusC1Prep_2

MusC3Prep:
	;Check if music is playing in SFX channel 3
	ld hl, SFXC3MusNum
	ld a, [hl]
	or a
	;Return if so
	ret nz

;Otherwise, get duty/pan value from table
SFXC3Prep:
	ld hl, $06
	add hl, de
	ld a, [hl]
	and %00000011
	add LOW(Duty3PanTab)
	ld l, a
	ld a, HIGH(Duty3PanTab)
	adc 0
	ld h, a
	
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
	jr z, SFXC3Prep_2

	;Otherwise, get hardware volume
	ld hl, $1F
	add hl, de
	ld a, [hl]
	
	;Get volume from look-up table
	swap a
	and %00001111
	push bc
	add LOW(Vol3LUT)
	ld c, a
	ld a, HIGH(Vol3LUT)
	adc 0
	ld b, a
	ld a, [bc]
	pop bc

;Set NR33
SFXC3Prep_2:
	ld [bc], a
	inc bc
	jp MusC1Prep_6


SFXC4Prep:
	;Get duty/pan value from table
	ld hl, $06
	add hl, de
	ld a, [hl]
	and %00000011
	add LOW(Duty4PanTab)
	ld l, a
	ld a, HIGH(Duty4PanTab)
	adc 0
	ld h, a
	
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
	jr nz, SFXC4Prep_2

	;If not, then use empty value
	ld a, %00001000
	jr SFXC4Prep_3

SFXC4Prep_2:
	;Get hardware volume
	ld hl, $1F
	add hl, de
	ld a, [hl]

SFXC4Prep_3:
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


Vol3LUT:
	db $00, $60, $40, $40
	db $40, $40, $40, $40
	db $20, $20, $20, $20
	db $20, $20, $20, $20

Duty1PanTab:
	db $11, $01, $10, $11
Duty2PanTab:
	db $22, $02, $20, $22
Duty3PanTab:
	db $44, $04, $40, $44
Duty4PanTab:
	db $88, $08, $80, $88

OutputTracks:
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

DoAllRegs:
	;Copy all register values in RAM to actual values and set appropriately
	call OutputReg
	ld a, b
	call OutputRegTrig
	ld a, b
	call OutputRegCheck
	call OutputRegWithTrig
	inc c
	call OutputReg
	ld a, [Gate2Off]
	call OutputRegTrig
	call OutputReg
	call OutputRegWithTrig
	call OutputReg
	inc hl
	inc de
	inc c
	call OutputReg
	call OutputReg
	call OutputRegWithTrig
	inc c
	inc hl
	inc de
	inc c
	ld a, [Gate4Off]
	call OutputRegTrig
	call OutputReg
	call OutputRegWithTrig
	
	;Output NR50 and NR51 values
	ld hl, rNR50
	ld a, [NR50Val]
	ld [hl+], a
	ld a, [NR51Val]
	ld [hl+], a
	
	;Check if SFX on channel 3 is playing
	ld a, [SFXC3MusNum]
	or a
	;If so, set SFX waveform
	jr nz, SetSFXWaveform

;Otherwise, set music waveform
SetMusWaveform:
	ld a, [WaveformMus]
	jr LoadWaveform

SetSFXWaveform:
	ld a, [WaveformSFX]

LoadWaveform:
	;If waveform is same, then return
	ld hl, NewWave
	cp [hl]
	ret z

	;Otherwise, load new waveform - get pointer to waveform from table
	ld [hl], a
	add a
	add LOW(WaveTab)
	ld l, a
	ld a, HIGH(WaveTab)
	adc 0
	ld h, a
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


OutputRegTrig:
	;Check "gate off" value
	or a
	;If gate off, get new value and set trigger
	jr z, .OutputRegTrig_2

	;Otherwise, check if copy register variable is the same as register value
	ld a, [de]
	cp [hl]
	jr z, OutputReg_Ret

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


OutputRegCheck:
	;Check "gate off" value
	or a
	;If gate off, get new value
	jr z, OutputReg2

OutputReg:
;Get copy value and compare to main register value
	ld a, [de]
	cp [hl]
	;If same, then return
	jr z, OutputReg_Ret

;Otherwise, load to main register value and actual register 
OutputReg2:
	ld a, [hl]
	ld [de], a
	ldh [c], a

OutputReg_Ret:
	inc hl
	inc de
	inc c
	ret


OutputRegWithTrig:
	;Check "trigger" bit of copy value
	ld a, [de]
	bit 7, a
	;If set, then output new value
	jr nz, .OutputRegWithTrig2

	;Otherwise, check if main value is the same
	cp [hl]
	;If so, then return
	jr z, OutputReg_Ret

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


;Initialize audio with no music/SFX
NoAudio:
	push bc
	push de
	call ClearCh1
	ld a, %01110111
	ld [NR50Val], a
	jr InitSoundRAM

;Initialize audio
InitSound:
	push bc
	push de
	call AudioOff
	ld a, %01110111
	ldh [rNR50], a
	ld [NR50Val], a

;Initialize RAM variables
InitSoundRAM:
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
	ld hl, MusC1NoteTime	;Set note time flag to 1
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
	ld [Output], a			;Set output flag to 0
	ld [Fade], a			;Disable fade out routine
	ld [FadeTime], a
	ld a, $FF
	ld [NewWave], a			;Set (new) waveform value
	pop de
	pop bc
	ret


AudioOff:
	;Turn off audio
	xor a
	ldh [rNR50], a
	ld a, %10000000
	ldh [rNR52], a

ClearCh1:
	;Reset NR10 (sweep)
	ld a, %00001000
	ldh [rNR10], a
	ld [NR10Val], a
	;Check if channel is on
	ldh a, [rNR52]
	bit 0, a
	;If not, then skip
	jr z, ClearCh2

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

ClearCh2:
	;Check if channel is on
	ldh a, [rNR52]
	bit 1, a
	;If not, then skip
	jr z, ClearCh3

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

ClearCh3:
	;Check if channel is on
	ldh a, [rNR52]
	bit 2, a
	;If not, then skip
	jr z, ClearCh4

	xor a
	;Clear NR32 and NR34
	ldh [rNR32], a
	ld [NR32Val], a
	ld [NR34Val], a
	;Set trigger bit
	ld a, %10000000
	ldh [rNR34], a

ClearCh4:
	;Check if channel is on
	ldh a, [rNR52]
	bit 3, a
	;If not, then return
	jr z, AudioOffRet

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

AudioOffRet:
	ret


Extra:
	ret

SECTION "Audio RAM", WRAMX[AudioRAM]

CurTrack: ds 1			;$DB02
CurTrackCheck: ds 1		;$DB03
SFXNum: ds 1			;$DB04
Temp1: ds 1				;$DB05
Temp2: ds 1				;$DB06
Output: ds 1			;$DB07
WaveformMus: ds 1		;$DB08
WaveformSFX: ds 1		;$DB09
NewWave: ds 1			;$DB0A
Fade: ds 1				;$DB0B
FadeTime: ds 1			;$DB0C

;Music channel 1 RAM
MusC1MusNum: ds 1		;$DB0D = $00
MusC1Priority: ds 1		;$DB0E = $01
MusC1Sweep: ds 1		;$DB0F = $02
MusC1Transpose: ds 1	;$DB10 = $03
MusC1Tuning: ds 1		;$DB11 = $04
MusC1VolFinal: ds 1		;$DB12 = $05
MusC1VolOutput: ds 1	;$DB13 = $06
MusC1NoteDelay: ds 1	;$DB14 = $07
MusC1NoteTime: ds 1		;$DB15 = $08
MusC1EnvOn: ds 1		;$DB16 = $09
MusC1EnvTime: ds 1		;$DB17 = $0A
MusC1Speed: ds 1		;$DB18 = $0B
MusC1DutyVol: ds 1		;$DB19 = $0C
MusC1Decay: ds 1		;$DB1A = $0D
MusC1EnvLen: ds 1		;$DB1B = $0E
MusC1Vibrato: ds 2		;$DB1C = $0F
MusC1EnvVal: ds 1		;$DB1E = $11
MusC1Decay2: ds 1		;$DB1F = $12
MusC1Decay3: ds 1		;$DB20 = $13
MusC1EnvSeqPtr: ds 2	;$DB21 = $14
MusC1VibStep: ds 1		;$DB22 = $16
MusC1EnvSeqPos: ds 1	;$DB23 = $17
MusC1EnvStep: ds 1		;$DB25 = $18
MusC1VibSeqDelay: ds 1	;$DB26 = $19
MusC1EnvDur: ds 1		;$DB27 = $1A
MusC1Octave: ds 1		;$DB28 = $1B
MusC1VibVal: ds 1		;$DB29 = $1C
MusC1Freq: ds 2			;$DB2A = $1D
MusC1VolCur: ds 1		;$DB2C = $1F
MusC1SongPos: ds 2		;$DB2D = $20
MusC1Repeat1Start: ds 2	;$DB2F = $22
MusC1Repeat2Start: ds 2	;$DB31 = $24
MusC1Macro1Pos: ds 2	;$DB33 = $26
MusC1Macro2Pos: ds 2	;$DB35 = $28
MusC1Repeat1Times: ds 1	;$DB37 = $2A
MusC1Repeat2Times: ds 1	;$DB38 = $2B

;Music channel 2 RAM
MusC2MusNum: ds 1		;$DB39 = $00
MusC2Priority: ds 1		;$DB3A = $01
MusC2Sweep: ds 1		;$DB3B = $02
MusC2Transpose: ds 1	;$DB3C = $03
MusC2Tuning: ds 1		;$DB3D = $04
MusC2VolFinal: ds 1		;$DB3E = $05
MusC2VolOutput: ds 1	;$DB3F = $06
MusC2NoteDelay: ds 1	;$DB40 = $07
MusC2NoteTime: ds 1		;$DB41 = $08
MusC2EnvOn: ds 1		;$DB42 = $09
MusC2EnvTime: ds 1		;$DB43 = $0A
MusC2Speed: ds 1		;$DB44 = $0B
MusC2DutyVol: ds 1		;$DB45 = $0C
MusC2Decay: ds 1		;$DB46 = $0D
MusC2EnvLen: ds 1		;$DB47 = $0E
MusC2Vibrato: ds 2		;$DB48 = $0F
MusC2EnvVal: ds 1		;$DB4A = $11
MusC2Decay2: ds 1		;$DB4B = $12
MusC2Decay3: ds 1		;$DB4C = $13
MusC2EnvSeqPtr: ds 2	;$DB4D = $14
MusC2VibStep: ds 1		;$DB4F = $16
MusC2EnvSeqPos: ds 1	;$DB50 = $17
MusC2EnvStep: ds 1		;$DB51 = $18
MusC2VibSeqDelay: ds 1	;$DB52 = $19
MusC2EnvDur: ds 1		;$DB53 = $1A
MusC2Octave: ds 1		;$DB54 = $1B
MusC2VibVal: ds 1		;$DB55 = $1C
MusC2Freq: ds 2			;$DB56 = $1D
MusC2VolCur: ds 1		;$DB58 = $1F
MusC2SongPos: ds 2		;$DB59 = $20
MusC2Repeat1Start: ds 2	;$DB5B = $22
MusC2Repeat2Start: ds 2	;$DB5D = $24
MusC2Macro1Pos: ds 2	;$DB5F = $26
MusC2Macro2Pos: ds 2	;$DB61 = $28
MusC2Repeat1Times: ds 1	;$DB63 = $2A
MusC2Repeat2Times: ds 1	;$DB64 = $2B

;Music channel 3 RAM
MusC3MusNum: ds 1		;$DB65 = $00
MusC3Priority: ds 1		;$DB66 = $01
MusC3Sweep: ds 1		;$DB67 = $02
MusC3Transpose: ds 1	;$DB68 = $03
MusC3Tuning: ds 1		;$DB69 = $04
MusC3VolFinal: ds 1		;$DB6A = $05
MusC3VolOutput: ds 1	;$DB6B = $06
MusC3NoteDelay: ds 1	;$DB6C = $07
MusC3NoteTime: ds 1		;$DB6D = $08
MusC3EnvOn: ds 1		;$DB6E = $09
MusC3EnvTime: ds 1		;$DB6F = $0A
MusC3Speed: ds 1		;$DB70 = $0B
MusC3DutyVol: ds 1		;$DB71 = $0C
MusC3Decay: ds 1		;$DB72 = $0D
MusC3EnvLen: ds 1		;$DB73 = $0E
MusC3Vibrato: ds 2		;$DB74 = $0F
MusC3EnvVal: ds 1		;$DB76 = $11
MusC3Decay2: ds 1		;$DB77 = $12
MusC3Decay3: ds 1		;$DB78 = $13
MusC3EnvSeqPtr: ds 2	;$DB79 = $14
MusC3VibStep: ds 1		;$DB7B = $16
MusC3EnvSeqPos: ds 1	;$DB7C = $17
MusC3EnvStep: ds 1		;$DB7D = $18
MusC3VibSeqDelay: ds 1	;$DB7E = $19
MusC3EnvDur: ds 1		;$DB7F = $1A
MusC3Octave: ds 1		;$DB80 = $1B
MusC3VibVal: ds 1		;$DB81 = $1C
MusC3Freq: ds 2			;$DB82 = $1D
MusC3VolCur: ds 1		;$DB84 = $1F
MusC3SongPos: ds 2		;$DB85 = $20
MusC3Repeat1Start: ds 2	;$DB87 = $22
MusC3Repeat2Start: ds 2	;$DB89 = $24
MusC3Macro1Pos: ds 2	;$DB8B = $26
MusC3Macro2Pos: ds 2	;$DB8D = $28
MusC3Repeat1Times: ds 1	;$DB8F = $2A
MusC3Repeat2Times: ds 1	;$DB90 = $2B

;Music channel 4 RAM
MusC4MusNum: ds 1		;$DB91 = $00
MusC4Priority: ds 1		;$DB92 = $01
MusC4Sweep: ds 1		;$DB93 = $02
MusC4Transpose: ds 1	;$DB94 = $03
MusC4Tuning: ds 1		;$DB95 = $04
MusC4VolFinal: ds 1		;$DB96 = $05
MusC4VolOutput: ds 1	;$DB97 = $06
MusC4NoteDelay: ds 1	;$DB98 = $07
MusC4NoteTime: ds 1		;$DB99 = $08
MusC4EnvOn: ds 1		;$DB9A = $09
MusC4EnvTime: ds 1		;$DB9B = $0A
MusC4Speed: ds 1		;$DB9C = $0B
MusC4DutyVol: ds 1		;$DB9D = $0C
MusC4Decay: ds 1		;$DB9E = $0D
MusC4EnvLen: ds 1		;$DB9F = $0E
MusC4Vibrato: ds 2		;$DBA0 = $0F
MusC4EnvVal: ds 1		;$DBA2 = $11
MusC4Decay2: ds 1		;$DBA3 = $12
MusC4Decay3: ds 1		;$DBA4 = $13
MusC4EnvSeqPtr: ds 2	;$DBA5 = $14
MusC4VibStep: ds 1		;$DBA7 = $16
MusC4EnvSeqPos: ds 1	;$DBA8 = $17
MusC4EnvStep: ds 1		;$DBA9 = $18
MusC4VibSeqDelay: ds 1	;$DBAA = $19
MusC4EnvDur: ds 1		;$DBAB = $1A
MusC4Octave: ds 1		;$DBAC = $1B
MusC4VibVal: ds 1		;$DBAD = $1C
MusC4Freq: ds 2			;$DBAE = $1D
MusC4VolCur: ds 1		;$DBB0 = $1F
MusC4SongPos: ds 2		;$DBB1 = $20
MusC4Repeat1Start: ds 2	;$DBB3 = $22
MusC4Repeat2Start: ds 2	;$DBB5 = $24
MusC4Macro1Pos: ds 2	;$DBB7 = $26
MusC4Macro2Pos: ds 2	;$DBB9 = $28
MusC4Repeat1Times: ds 1	;$DBBB = $2A
MusC4Repeat2Times: ds 1	;$DBBC = $2B

;SFX channel 1 RAM
SFXC1MusNum: ds 1		;$DBBD = $00
SFXC1Priority: ds 1		;$DBBE = $01
SFXC1Sweep: ds 1		;$DBBF = $02
SFXC1Transpose: ds 1	;$DBC0 = $03
SFXC1Tuning: ds 1		;$DBC1 = $04
SFXC1VolFinal: ds 1		;$DBC2 = $05
SFXC1VolOutput: ds 1	;$DBC3 = $06
SFXC1NoteDelay: ds 1	;$DBC4 = $07
SFXC1NoteTime: ds 1		;$DBC5 = $08
SFXC1EnvOn: ds 1		;$DBC6 = $09
SFXC1EnvTime: ds 1		;$DBC7 = $0A
SFXC1Speed: ds 1		;$DBC8 = $0B
SFXC1DutyVol: ds 1		;$DBC9 = $0C
SFXC1Decay: ds 1		;$DBCA = $0D
SFXC1EnvLen: ds 1		;$DBCB = $0E
SFXC1Vibrato: ds 2		;$DBCC = $0F
SFXC1EnvVal: ds 1		;$DBCE = $11
SFXC1Decay2: ds 1		;$DBCF = $12
SFXC1Decay3: ds 1		;$DBD0 = $13
SFXC1EnvSeqPtr: ds 2	;$DBD1 = $14
SFXC1VibStep: ds 1		;$DBD2 = $16
SFXC1EnvSeqPos: ds 1	;$DBD3 = $17
SFXC1EnvStep: ds 1		;$DBD5 = $18
SFXC1VibSeqDelay: ds 1	;$DBD6 = $19
SFXC1EnvDur: ds 1		;$DBD7 = $1A
SFXC1Octave: ds 1		;$DBD8 = $1B
SFXC1VibVal: ds 1		;$DBD9 = $1C
SFXC1Freq: ds 2			;$DBDA = $1D
SFXC1VolCur: ds 1		;$DBDC = $1F
SFXC1SongPos: ds 2		;$DBDD = $20
SFXC1Repeat1Start: ds 2	;$DBDF = $22
SFXC1Repeat2Start: ds 2	;$DBE1 = $24
SFXC1Macro1Pos: ds 2	;$DBE3 = $26
SFXC1Macro2Pos: ds 2	;$DBE5 = $28
SFXC1Repeat1Times: ds 1	;$DBE7 = $2A
SFXC1Repeat2Times: ds 1	;$DBE8 = $2B

;SFX channel 2 RAM
SFXC2MusNum: ds 1		;$DBE9 = $00
SFXC2Priority: ds 1		;$DBEA = $01
SFXC2Sweep: ds 1		;$DBEB = $02
SFXC2Transpose: ds 1	;$DBEC = $03
SFXC2Tuning: ds 1		;$DBED = $04
SFXC2VolFinal: ds 1		;$DBEE = $05
SFXC2VolOutput: ds 1	;$DBEF = $06
SFXC2NoteDelay: ds 1	;$DBF0 = $07
SFXC2NoteTime: ds 1		;$DBF1 = $08
SFXC2EnvOn: ds 1		;$DBF2 = $09
SFXC2EnvTime: ds 1		;$DBF3 = $0A
SFXC2Speed: ds 1		;$DBF4 = $0B
SFXC2DutyVol: ds 1		;$DBF5 = $0C
SFXC2Decay: ds 1		;$DBF6 = $0D
SFXC2EnvLen: ds 1		;$DBF7 = $0E
SFXC2Vibrato: ds 2		;$DBF8 = $0F
SFXC2EnvVal: ds 1		;$DBFA = $11
SFXC2Decay2: ds 1		;$DBFB = $12
SFXC2Decay3: ds 1		;$DBFC = $13
SFXC2EnvSeqPtr: ds 2	;$DBFD = $14
SFXC2VibStep: ds 1		;$DBFF = $16
SFXC2EnvSeqPos: ds 1	;%DC00 = $17
SFXC2EnvStep: ds 1		;$DC01 = $18
SFXC2VibSeqDelay: ds 1	;$DC02 = $19
SFXC2EnvDur: ds 1		;$DC03 = $1A
SFXC2Octave: ds 1		;$DC04 = $1B
SFXC2VibVal: ds 1		;$DC05 = $1C
SFXC2Freq: ds 2			;$DC06 = $1D
SFXC2VolCur: ds 1		;$DC08 = $1F
SFXC2SongPos: ds 2		;$DC09 = $20
SFXC2Repeat1Start: ds 2	;$DC0B = $22
SFXC2Repeat2Start: ds 2	;$DC0D = $24
SFXC2Macro1Pos: ds 2	;$DC0F = $26
SFXC2Macro2Pos: ds 2	;$DC11 = $28
SFXC2Repeat1Times: ds 1	;$DC13 = $2A
SFXC2Repeat2Times: ds 1	;$DC14 = $2B

;SFX channel 3 RAM
SFXC3MusNum: ds 1		;$DC15 = $00
SFXC3Priority: ds 1		;$DC16 = $01
SFXC3Sweep: ds 1		;$DC17 = $02
SFXC3Transpose: ds 1	;$DC18 = $03
SFXC3Tuning: ds 1		;$DC19 = $04
SFXC3VolFinal: ds 1		;$DC1A = $05
SFXC3VolOutput: ds 1	;$DC1B = $06
SFXC3NoteDelay: ds 1	;$DC1C = $07
SFXC3NoteTime: ds 1		;$DC1D = $08
SFXC3EnvOn: ds 1		;$DC1E = $09
SFXC3EnvTime: ds 1		;$DC1F = $0A
SFXC3Speed: ds 1		;$DC20 = $0B
SFXC3DutyVol: ds 1		;$DC21 = $0C
SFXC3Decay: ds 1		;$DC22 = $0D
SFXC3EnvLen: ds 1		;$DC23 = $0E
SFXC3Vibrato: ds 2		;$DC24 = $0F
SFXC3EnvVal: ds 1		;$DC26 = $11
SFXC3Decay2: ds 1		;$DC27 = $12
SFXC3Decay3: ds 1		;$DC28 = $13
SFXC3EnvSeqPtr: ds 2	;$DC29 = $14
SFXC3VibStep: ds 1		;$DC2B = $16
SFXC3EnvSeqPos: ds 1	;$DC2C = $17
SFXC3EnvStep: ds 1		;$DC2D = $18
SFXC3VibSeqDelay: ds 1	;$DC2E = $19
SFXC3EnvDur: ds 1		;$DC2F = $1A
SFXC3Octave: ds 1		;$DC30 = $1B
SFXC3VibVal: ds 1		;$DC31 = $1C
SFXC3Freq: ds 2			;$DC32 = $1D
SFXC3VolCur: ds 1		;$DC34 = $1F
SFXC3SongPos: ds 2		;$DC35 = $20
SFXC3Repeat1Start: ds 2	;$DC37 = $22
SFXC3Repeat2Start: ds 2	;$DC39 = $24
SFXC3Macro1Pos: ds 2	;$DC3B = $26
SFXC3Macro2Pos: ds 2	;$DC3D = $28
SFXC3Repeat1Times: ds 1	;$DC3F = $2A
SFXC3Repeat2Times: ds 1	;$DC40 = $2B

;SFX channel 4 RAM
SFXC4MusNum: ds 1		;$DC41 = $00
SFXC4Priority: ds 1		;$DC42 = $01
SFXC4Sweep: ds 1		;$DC43 = $02
SFXC4Transpose: ds 1	;$DC44 = $03
SFXC4Tuning: ds 1		;$DC45 = $04
SFXC4VolFinal: ds 1		;$DC46 = $05
SFXC4VolOutput: ds 1	;$DC47 = $06
SFXC4NoteDelay: ds 1	;$DC48 = $07
SFXC4NoteTime: ds 1		;$DC49 = $08
SFXC4EnvOn: ds 1		;$DC4A = $09
SFXC4EnvTime: ds 1		;$DC4B = $0A
SFXC4Speed: ds 1		;$DC4C = $0B
SFXC4DutyVol: ds 1		;$DC4D = $0C
SFXC4Decay: ds 1		;$DC4E = $0D
SFXC4EnvLen: ds 1		;$DC4F = $0E
SFXC4Vibrato: ds 2		;$DC50 = $0F
SFXC4EnvVal: ds 1		;$DC52 = $11
SFXC4Decay2: ds 1		;$DC53 = $12
SFXC4Decay3: ds 1		;$DC54 = $13
SFXC4EnvSeqPtr: ds 2	;$DC55 = $14
SFXC4VibStep: ds 1		;$DC57 = $16
SFXC4EnvSeqPos: ds 1	;$DC58 = $17
SFXC4EnvStep: ds 1		;$DC59 = $18
SFXC4VibSeqDelay: ds 1	;$DC5A = $19
SFXC4EnvDur: ds 1		;$DC5B = $1A
SFXC4Octave: ds 1		;$DC5C = $1B
SFXC4VibVal: ds 1		;$DC5D = $1C
SFXC4Freq: ds 2			;$DC5E = $1D
SFXC4VolCur: ds 1		;$DC60 = $1F
SFXC4SongPos: ds 2		;$DC61 = $20
SFXC4Repeat1Start: ds 2	;$DC63 = $22
SFXC4Repeat2Start: ds 2	;$DC65 = $24
SFXC4Macro1Pos: ds 2	;$DC67 = $26
SFXC4Macro2Pos: ds 2	;$DC69 = $28
SFXC4Repeat1Times: ds 1	;$DC6B = $2A
SFXC4Repeat2Times: ds 1	;$DC6C = $2B

NR10Val: ds 1			;$DC6D
NR11Val: ds 1			;$DC6E
NR12Val: ds 1			;$DC6F
NR13Val: ds 1			;$DC70
NR14Val: ds 1			;$DC71
NR21Val: ds 1			;$DC72
NR22Val: ds 1			;$DC73
NR23Val: ds 1			;$DC74
NR24Val: ds 1			;$DC75
NR30Val: ds 1			;$DC76
NR31Val: ds 1			;$DC77
NR32Val: ds 1			;$DC78
NR33Val: ds 1			;$DC79
NR34Val: ds 1			;$DC7A
NR41Val: ds 1			;$DC7B
NR42Val: ds 1			;$DC7C
NR43Val: ds 1			;$DC7D
NR44Val: ds 1			;$DC7E
NR50Val: ds 1			;$DC7F
NR51Val: ds 1			;$DC80
NR52Val: ds 1			;$DC81

NR10ValCopy: ds 1		;$DC82
NR11ValCopy: ds 1		;$DC83
NR12ValCopy: ds 1		;$DC84
NR13ValCopy: ds 1		;$DC85
NR14ValCopy: ds 1		;$DC86
NR21ValCopy: ds 1		;$DC87
NR22ValCopy: ds 1		;$DC88
NR23ValCopy: ds 1		;$DC89
NR24ValCopy: ds 1		;$DC8A
NR30ValCopy: ds 1		;$DC8B
NR31ValCopy: ds 1		;$DC8C
NR32ValCopy: ds 1		;$DC8D
NR33ValCopy: ds 1		;$DC8E
NR34ValCopy: ds 1		;$DC8F
NR41ValCopy: ds 1		;$DC90
NR42ValCopy: ds 1		;$DC91
NR43ValCopy: ds 1		;$DC92
NR44ValCopy: ds 1		;$DC93
NR50ValCopy: ds 1		;$DC94
NR51ValCopy: ds 1		;$DC95
NR52ValCopy: ds 1		;$DC96

Gate1Off: ds 1			;$DC97
Gate2Off: ds 1			;$DC98
Gate3Off: ds 1			;$DC99
Gate4Off: ds 1			;$DC9A