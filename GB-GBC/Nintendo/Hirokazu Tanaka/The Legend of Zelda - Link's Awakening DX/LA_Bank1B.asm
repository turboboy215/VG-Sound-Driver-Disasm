; Link's Awakening DX music, bank $1B (songs $01-$10, $31-$40, $61-$6F)
INCLUDE "GB_Hardware.inc"
INCLUDE "LA_RAM.inc"
INCLUDE "LA_Macros.inc"

SECTION "LA sound bank $1B", ROMX[$4000], BANK[$1B]
INCLUDE "LA_1B_Driver.inc"
INCLUDE "LA_1B_Songs1.inc"
INCLUDE "LA_1B_Stop.inc"
INCLUDE "LA_1B_Songs2.inc"
