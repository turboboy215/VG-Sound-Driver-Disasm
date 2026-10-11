; Link's Awakening DX music, bank $1E (songs $11-$30, $41-$60)
INCLUDE "GB_Hardware.inc"
INCLUDE "LA_RAM.inc"
INCLUDE "LA_Macros.inc"

SECTION "LA sound bank $1E", ROMX[$4000], BANK[$1E]
INCLUDE "LA_1E_Driver.inc"
INCLUDE "LA_1E_Songs1.inc"
INCLUDE "LA_1E_Stop.inc"
INCLUDE "LA_1E_Songs2.inc"
