; Mole Mania sound bank $07

INCLUDE "GB_Hardware.inc"
INCLUDE "MM_RAM.inc"
INCLUDE "MM_Macros.inc"

SECTION "Mole Mania sound bank $07", ROMX[$4000], BANK[$07]

INCLUDE "MM_Driver.inc"
INCLUDE "MM_Tables.inc"
INCLUDE "MM_Bank07_SongTable.inc"
INCLUDE "MM_Common.inc"
INCLUDE "MM_Bank07_Songs.inc"
ASSERT @ == $8000
