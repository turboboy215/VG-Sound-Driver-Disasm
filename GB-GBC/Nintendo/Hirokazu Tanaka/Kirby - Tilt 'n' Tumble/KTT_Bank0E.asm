; Kirby Tilt 'n' Tumble: music bank $0E (songs $01-$3F)
INCLUDE "GB_Hardware.inc"
INCLUDE "KTT_RAM.inc"
INCLUDE "KTT_Macros.inc"

SECTION "KTT sound bank $0E", ROMX[$4000], BANK[$0E]
	ASSERT @ == $4000
INCLUDE "KTT_0E_Driver.inc"
	ASSERT @ == $5000
INCLUDE "KTT_0E_Songs.inc"
