; Kirby Tilt 'n' Tumble: music bank $0F (songs $40-$7F)
INCLUDE "GB_Hardware.inc"
INCLUDE "KTT_RAM.inc"
INCLUDE "KTT_Macros.inc"

SECTION "KTT sound bank $0F", ROMX[$4000], BANK[$0F]
	ASSERT @ == $4000
INCLUDE "KTT_0F_Driver.inc"
	ASSERT @ == $5000
INCLUDE "KTT_0F_Songs.inc"
