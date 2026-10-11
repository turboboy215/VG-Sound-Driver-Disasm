; Tetris Attack: bank $08, music driver copy A (songs $01-$1C)
INCLUDE "GB_Hardware.inc"
INCLUDE "TA_RAM.inc"
INCLUDE "TA_Macros.inc"

SECTION "TA sound bank $08", ROMX[$4000], BANK[$08]
	ASSERT @ == $4000
INCLUDE "TA_08_Driver.inc"
	ASSERT @ == $495C
INCLUDE "TA_08_Songs.inc"
