; Super Mario Bros. Deluxe: SFX bank $1F
INCLUDE "GB_Hardware.inc"
INCLUDE "SMB_RAM.inc"

SECTION "SMB DX sound bank $1F", ROMX[$4000], BANK[$1F]
	ASSERT @ == $4000
INCLUDE "SMB_1F_Main.inc"
	ASSERT @ == $43A2
INCLUDE "SMB_1F_Sfx1Start.inc"
	ASSERT @ == $448C
INCLUDE "SMB_1F_Sfx2Start.inc"
	ASSERT @ == $4737
INCLUDE "SMB_1F_Sfx4Start.inc"
	ASSERT @ == $485A
INCLUDE "SMB_1F_Effects.inc"
	ASSERT @ == $67F1
INCLUDE "SMB_1F_Common.inc"
