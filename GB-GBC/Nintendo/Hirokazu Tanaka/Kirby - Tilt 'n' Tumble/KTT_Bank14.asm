; Kirby Tilt 'n' Tumble: SFX bank $14 (effects $80-$97)
INCLUDE "GB_Hardware.inc"
INCLUDE "KTT_RAM.inc"

SECTION "KTT sound bank $14", ROMX[$4000], BANK[$14]
	ASSERT @ == $4000
INCLUDE "KTT_14_Main.inc"
	ASSERT @ == $4296
INCLUDE "KTT_14_Effects.inc"
	ASSERT @ == $5AFE
INCLUDE "KTT_14_Common.inc"
