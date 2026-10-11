; Super Mario Bros. Deluxe: music bank $1D (songs $62-$7F)
INCLUDE "GB_Hardware.inc"
INCLUDE "SMB_RAM.inc"
INCLUDE "SMB_Macros.inc"

SECTION "SMB DX sound bank $1D", ROMX[$4000], BANK[$1D]
	ASSERT @ == $4000
INCLUDE "SMB_1D_Driver.inc"
	ASSERT @ == $4D96
INCLUDE "SMB_1D_Songs1.inc"
	ASSERT @ == $4DA2
INCLUDE "SMB_1D_Stop.inc"
	ASSERT @ == $5000
INCLUDE "SMB_1D_Songs2.inc"
