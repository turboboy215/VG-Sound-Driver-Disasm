; Adventures of Lolo - HAL sound driver

INCLUDE "Lolo_RAM.inc"
INCLUDE "Lolo_Macros.inc"

SECTION "Sound Driver", ROM0[$32AE]

INCLUDE "Lolo_Driver.inc"
INCLUDE "Lolo_Tables.inc"

SECTION "Sound Data", ROMX[$4000], BANK[$0F]

INCLUDE "Lolo_Data.inc"
