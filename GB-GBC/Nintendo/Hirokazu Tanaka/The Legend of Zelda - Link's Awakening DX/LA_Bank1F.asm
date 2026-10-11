; Link's Awakening DX: SFX bank $1F
INCLUDE "GB_Hardware.inc"
INCLUDE "LA_RAM.inc"

SECTION "LA sound bank $1F", ROMX[$4000], BANK[$1F]
INCLUDE "LA_1F_Main.inc"
INCLUDE "LA_1F_Sfx1.inc"
INCLUDE "LA_1F_Sfx3.inc"
INCLUDE "LA_1F_Sfx4.inc"
INCLUDE "LA_1F_Common.inc"
