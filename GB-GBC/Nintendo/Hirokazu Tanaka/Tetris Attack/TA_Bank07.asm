; Tetris Attack: bank $07, SFX engine and music driver copy B (songs $1D-$23)
INCLUDE "GB_Hardware.inc"
INCLUDE "TA_RAM.inc"
INCLUDE "TA_Macros.inc"

SECTION "TA sound bank $07", ROMX[$4000], BANK[$07]
	ASSERT @ == $4000
INCLUDE "TA_07_Engine.inc"
	ASSERT @ == $4255
INCLUDE "TA_07_SfxInit.inc"
	ASSERT @ == $4FC2
INCLUDE "TA_07_SfxData.inc"
	ASSERT @ == $67A3
INCLUDE "TA_07_Driver.inc"
	ASSERT @ == $7031
INCLUDE "TA_07_Songs.inc"
