; Super Mario Land (GB) sound driver, bank 3 $6700-$7FFF
; Rebuilds byte-exact with RGBDS 0.9 (see build_check.sh).
INCLUDE "GB_Hardware.inc"
INCLUDE "SML_RAM.inc"
INCLUDE "SML_Macros.inc"

SECTION "Super Mario Land sound", ROMX[$6700], BANK[3]
INCLUDE "SML_Driver.inc"
INCLUDE "SML_Tables.inc"
INCLUDE "SML_Songs.inc"
INCLUDE "SML_Tail.inc"
