; Mole Mania sound bank $1A

INCLUDE "GB_Hardware.inc"
INCLUDE "MM_RAM.inc"
INCLUDE "MM_Macros.inc"

SECTION "Mole Mania sound bank $1A", ROMX[$4000], BANK[$1A]

INCLUDE "MM_Driver.inc"
INCLUDE "MM_Tables.inc"
INCLUDE "MM_Bank1A_SongTable.inc"
INCLUDE "MM_Common.inc"
INCLUDE "MM_Bank1A_Songs.inc"
ASSERT @ == $6900
