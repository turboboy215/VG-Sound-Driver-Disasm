; Kirby's Dream Land 2 - HAL sound driver

INCLUDE "KDL2_RAM.inc"
INCLUDE "KDL2_Macros.inc"

SECTION "Sound Interpreter", ROM0[$2B97]
INCLUDE "KDL2_Bank0.inc"

SECTION "Sound Periods", ROM0[$3F56]
INCLUDE "KDL2_Periods.inc"

SECTION "Sound Engine and SFX", ROMX[$4000], BANK[$1E]
INCLUDE "KDL2_SfxBank.inc"

SECTION "Sound Music", ROMX[$4000], BANK[$1F]
INCLUDE "KDL2_MusicBank.inc"
