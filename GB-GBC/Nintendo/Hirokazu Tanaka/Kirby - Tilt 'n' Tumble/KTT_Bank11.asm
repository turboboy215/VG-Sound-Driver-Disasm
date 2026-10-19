; Kirby Tilt 'n' Tumble: SFX bank $11 (effects $01-$7F)
INCLUDE "GB_Hardware.inc"
INCLUDE "KTT_RAM.inc"

SECTION "KTT sound bank $11", ROMX[$4000], BANK[$11]
	ASSERT @ == $4000
INCLUDE "KTT_11_Main.inc"
	ASSERT @ == $454A
INCLUDE "KTT_11_Effects.inc"
	ASSERT @ == $788D
INCLUDE "KTT_11_Common.inc"
