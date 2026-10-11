; Metal Slug 2: music bank $28 (songs 1-10)
INCLUDE "GB_Hardware.inc"
INCLUDE "MS2_RAM.inc"
INCLUDE "MS2_Macros.inc"

SECTION "MS2 sound bank $28", ROMX[$4000], BANK[$28]
	ASSERT @ == $4000
INCLUDE "MS2_28_Driver.inc"
	ASSERT @ == $4A28
INCLUDE "MS2_28_Songs.inc"
