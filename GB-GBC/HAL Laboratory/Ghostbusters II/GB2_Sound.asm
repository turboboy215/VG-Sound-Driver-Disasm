; Ghostbusters II - HAL sound driver

INCLUDE "GB2_RAM.inc"
INCLUDE "GB2_Macros.inc"

SECTION "Sound Bank 0", ROM0[$07D4]
INCLUDE "GB2_Bank0.inc"

SECTION "Sound Driver", ROMX[$4000], BANK[7]
INCLUDE "GB2_Driver.inc"
INCLUDE "GB2_Data.inc"
