; Tetris Attack: home-bank sound routine
INCLUDE "GB_Hardware.inc"
INCLUDE "TA_RAM.inc"
DEF rROMB0 EQU $2100
DEF hRomBank EQU $FFFD

SECTION "TA sound home", ROM0[$1500]
INCLUDE "TA_Home.inc"
	ASSERT @ == $1645
