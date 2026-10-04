@ sma2_ram.inc: RAM and external addresses of the Super Mario Advance 2 (E), main program build
	.equ gDmaBufA, 0x03000090
	.equ gDmaBufB, 0x03000098
	.equ gTimerReload, 0x030000A0
	.equ gDmaBufIdx, 0x030000A2
	.equ gMixEnabled, 0x030000A3
	.equ gKitInst, 0x030000A8
	.equ gLastWave, 0x030000B0
	.equ gActiveHead, 0x030000B4
	.equ gActiveTail, 0x0300012C
	.equ gFreeHead, 0x030001A4
	.equ gFreeTail, 0x0300021C
	.equ gEchoPos, 0x03000294
	.equ gEchoLen, 0x03000295
	.equ gEchoShift, 0x03000296
	.equ gEchoShiftTarget, 0x03000297
	.equ gHookNote, 0x03000298
	.equ gHookCA, 0x0300029C
	.equ gCmdQueue, 0x030002A0
	.equ gCmdRead, 0x030004D4
	.equ gCmdWrite, 0x030004D8
	.equ gCmdCommitted, 0x030004DC
	.equ gCmdEnd, 0x030004E0
	.equ gCfg, 0x030004E4
	.equ gFnDownmix, 0x030004E8
	.equ gFnMixVoice, 0x030004EC
	.equ gFnEcho, 0x030004F0
	.equ gDmaBuffers, 0x030004F4
	.equ gMixDry, 0x030007B4
	.equ gMixWet, 0x03000A74
	.equ gEchoHistory, 0x03000D34
	.equ gTracks, 0x03000D38
	.equ gIwramCode, 0x03001518
	.equ gDsVoices, 0x03001878
	.equ gPsgVoices, 0x03001BC0
	.equ gPlayers, 0x03001DA0
	.equ MemClear, 0x08005540	@ outside the driver
	.equ CpuFastSet, 0x0809EBB4	@ outside the driver
	.equ CpuSet, 0x0809EBB8	@ outside the driver
	.equ _call_via_r1, 0x0809F038	@ outside the driver
	.equ _call_via_r2, 0x0809F03C	@ outside the driver
	.equ _call_via_r3, 0x0809F040	@ outside the driver
	.equ _call_via_r4, 0x0809F044	@ outside the driver
	.equ _call_via_r7, 0x0809F050	@ outside the driver
	.equ __divsi3, 0x0809F070	@ outside the driver
	.equ __udivsi3, 0x0809F108	@ outside the driver
