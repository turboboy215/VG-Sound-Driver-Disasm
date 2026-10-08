; Star Wars Episode I: Racer sound driver, bank $03

INCLUDE "GB_Hardware.inc"
INCLUDE "SWR_RAM.inc"
INCLUDE "SWR_Macros.inc"

SECTION "SWR sound", ROMX[$4000], BANK[$03]

INCLUDE "SWR_Driver.inc"
INCLUDE "SWR_Data.inc"
ASSERT @ == $76AA
