; Dr. Mario (GB) sound driver, bank 1 $6000-$7FFF
; Rebuilds byte-exact with RGBDS 0.9 (see build_check.sh).
INCLUDE "GB_Hardware.inc"
INCLUDE "DrM_RAM.inc"
INCLUDE "DrM_Macros.inc"

SECTION "Dr. Mario sound", ROMX[$6000], BANK[1]
INCLUDE "DrM_Driver.inc"
INCLUDE "DrM_Tables.inc"
INCLUDE "DrM_Songs.inc"
INCLUDE "DrM_Stubs.inc"
