; Super Mario Land 2 (GB) sound driver, bank 4 $4000-$7FFF
; Rebuilds byte-exact with RGBDS 0.9 (see build_check.sh).
INCLUDE "GB_Hardware.inc"
INCLUDE "SML2_RAM.inc"
INCLUDE "SML2_Macros.inc"

SECTION "Super Mario Land 2 sound", ROMX[$4000], BANK[4]
INCLUDE "SML2_SFX.inc"
INCLUDE "SML2_Music.inc"
INCLUDE "SML2_Tables.inc"
INCLUDE "SML2_Songs.inc"
INCLUDE "SML2_Stop.inc"
