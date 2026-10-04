@ sma4_mb_ram.inc: RAM and external addresses of the Super Mario Advance 4 (E) v1.0, Mario Bros. multiboot image build
	.equ gDmaBufA, 0x03000030
	.equ gDmaBufB, 0x03000038
	.equ gTimerReload, 0x03000040
	.equ gDmaBufIdx, 0x03000042
	.equ gMixEnabled, 0x03000043
	.equ gKitInst, 0x03000048
	.equ gLastWave, 0x03000050
	.equ gActiveVoices, 0x03000054
	.equ gFreeVoices, 0x03000058
	.equ gReservedVoices, 0x0300005C
	.equ gVoiceCount, 0x03000060
	.equ gHookNote, 0x03000068
	.equ gHookCA, 0x0300006C
	.equ gCmdQueue, 0x03000070
	.equ gCmdRead, 0x030002BC
	.equ gCmdWrite, 0x030002C0
	.equ gCmdCommitted, 0x030002C4
	.equ gCmdEnd, 0x030002C8
	.equ gCfg, 0x030002CC
	.equ gFnDownmix, 0x030002D0
	.equ gFnMixVoice, 0x030002D4
	.equ gFnEcho, 0x030002D8
	.equ gDmaBuffers, 0x030002DC
	.equ gMixDry, 0x0300059C
	.equ gTracks, 0x0300085C
	.equ gIwramCode, 0x0300103C
	.equ gDsVoices, 0x0300139C
	.equ gPsgVoices, 0x030016E4
	.equ gPlayers, 0x030018C4
	.equ CpuFastSet, 0x0201E63C	@ outside the driver
	.equ CpuSet, 0x0201E640	@ outside the driver
	.equ Div, 0x0201E644	@ outside the driver
	.equ _call_via_r1, 0x0201E66C	@ outside the driver
	.equ _call_via_r2, 0x0201E670	@ outside the driver
	.equ _call_via_r3, 0x0201E674	@ outside the driver
	.equ _call_via_r4, 0x0201E678	@ outside the driver
	.equ _call_via_r7, 0x0201E684	@ outside the driver
	.equ __divsi3, 0x0201E6A4	@ outside the driver
	.equ __udivsi3, 0x0201E73C	@ outside the driver
	.equ MemClear, 0x0201E874	@ outside the driver
