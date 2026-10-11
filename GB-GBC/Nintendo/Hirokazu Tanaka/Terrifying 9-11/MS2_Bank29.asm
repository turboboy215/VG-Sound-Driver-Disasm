; Metal Slug 2: SFX bank $29
INCLUDE "GB_Hardware.inc"
INCLUDE "MS2_RAM.inc"

SECTION "MS2 sound bank $29", ROMX[$4000], BANK[$29]
	ASSERT @ == $4000
INCLUDE "MS2_29_Main.inc"
	ASSERT @ == $411C
INCLUDE "MS2_29_Sfx1.inc"
	ASSERT @ == $5338
INCLUDE "MS2_29_Sfx3.inc"
	ASSERT @ == $6433
INCLUDE "MS2_29_Sfx4.inc"
	ASSERT @ == $799C
INCLUDE "MS2_29_Common.inc"
