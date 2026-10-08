; Mole Mania sound bank $0B

INCLUDE "GB_Hardware.inc"
INCLUDE "MM_RAM.inc"
INCLUDE "MM_Macros.inc"

SECTION "Mole Mania sound bank $0B", ROMX[$4000], BANK[$0B]

INCLUDE "MM_Driver.inc"
INCLUDE "MM_Tables.inc"
INCLUDE "MM_Bank0B_SongTable.inc"
INCLUDE "MM_Common.inc"
INCLUDE "MM_Bank0B_Songs.inc"
ASSERT @ == $8000
