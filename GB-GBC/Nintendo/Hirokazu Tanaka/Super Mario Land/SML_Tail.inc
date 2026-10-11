; bank 3 $7FED-$7FFF: free space and the driver entry stubs

	db $ff, $ff, $ff
Sound_UpdateStub:
	jp Sound_Update

Sound_StopStub:
	jp Sound_Stop

	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
