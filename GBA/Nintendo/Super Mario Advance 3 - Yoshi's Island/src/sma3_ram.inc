@ sma3_ram.inc: RAM and external addresses of the Super Mario Advance 3 (E), main program build
	.equ gDmaBufA, 0x030000A8
	.equ gDmaBufB, 0x030000B0
	.equ gTimerReload, 0x030000B8
	.equ gDmaBufIdx, 0x030000BA
	.equ gMixEnabled, 0x030000BB
	.equ gKitInst, 0x030000C0
	.equ gEchoShift, 0x030000C8
	.equ gLastWave, 0x030000CC
	.equ gActiveVoices, 0x030000D0
	.equ gFreeVoices, 0x030000D4
	.equ gReservedVoices, 0x030000D8
	.equ gVoiceCount, 0x030000DC
	.equ gEchoPos, 0x030000DD
	.equ gEchoLen, 0x030000DE
	.equ gEchoShiftTarget, 0x030000DF
	.equ gEchoTail, 0x030000E0
	.equ gHookNote, 0x030000E8
	.equ gHookCA, 0x030000EC
	.equ gCmdQueue, 0x030000F0
	.equ gCmdRead, 0x03000324
	.equ gCmdWrite, 0x03000328
	.equ gCmdCommitted, 0x0300032C
	.equ gCmdEnd, 0x03000330
	.equ gCfg, 0x03000334
	.equ gFnDownmix, 0x03000338
	.equ gFnMixVoice, 0x0300033C
	.equ gFnEcho, 0x03000340
	.equ gDmaBuffers, 0x03000344
	.equ gMixDry, 0x03000604
	.equ gMixWet, 0x030008C4
	.equ gEchoHistory, 0x03000B84
	.equ gTracks, 0x03000B88
	.equ gIwramCode, 0x03001368
	.equ gDsVoices, 0x030016C8
	.equ gPsgVoices, 0x03001A10
	.equ gPlayers, 0x03001BF0
	.equ CpuFastSet, 0x08132244	@ outside the driver
	.equ CpuSet, 0x08132248	@ outside the driver
	.equ Div, 0x0813224C	@ outside the driver
	.equ _call_via_r1, 0x081326C4	@ outside the driver
	.equ _call_via_r2, 0x081326C8	@ outside the driver
	.equ _call_via_r3, 0x081326CC	@ outside the driver
	.equ _call_via_r4, 0x081326D0	@ outside the driver
	.equ _call_via_r7, 0x081326DC	@ outside the driver
	.equ __divsi3, 0x081326FC	@ outside the driver
	.equ __udivsi3, 0x08132794	@ outside the driver
	.equ MemClear, 0x081328CC	@ outside the driver
