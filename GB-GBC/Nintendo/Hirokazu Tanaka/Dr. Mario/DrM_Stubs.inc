; padding and the driver entry stubs, bank 1 $7FD1-$7FFF

	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
Sound_UpdateStub:
	jp Sound_Update

Sound_StopStub:
	jp Sound_Stop

Sound_InitStub:
	jp Sound_Init

	db $00, $00, $00, $00, $00, $5a, $00
