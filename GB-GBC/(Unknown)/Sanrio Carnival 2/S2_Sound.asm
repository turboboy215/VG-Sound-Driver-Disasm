; Sanrio Carnival 2 (J): sound driver and data, bank $01 $6000-$7FFF
INCLUDE "GB_Hardware.inc"
INCLUDE "S2_RAM.inc"
INCLUDE "S2_Macros.inc"

SECTION "Sanrio Carnival 2 sound", ROMX[$6000], BANK[1]
	ASSERT @ == $6000
INCLUDE "S2_Driver.inc"
	ASSERT @ == $69EF
INCLUDE "S2_Tables.inc"
	ASSERT @ == $6AD9
INCLUDE "S2_Sfx.inc"
	ASSERT @ == $6D00
INCLUDE "S2_Data.inc"
	ASSERT @ == $6E32
INCLUDE "S2_Songs.inc"
	ASSERT @ == $8000
