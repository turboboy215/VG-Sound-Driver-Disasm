; Tetris (GB, V1.1) sound driver, $6480-$7FFF
INCLUDE "GB_Hardware.inc"
INCLUDE "Tet_RAM.inc"
INCLUDE "Tet_Macros.inc"

SECTION "Tetris sound", ROMX[$6480], BANK[1]
	ASSERT @ == $6480
INCLUDE "Tet_Driver.inc"
	ASSERT @ == $6DCB
INCLUDE "Tet_Tables.inc"
	ASSERT @ == $6F3F
INCLUDE "Tet_Songs.inc"
	ASSERT @ == $7FF0
INCLUDE "Tet_Stubs.inc"
