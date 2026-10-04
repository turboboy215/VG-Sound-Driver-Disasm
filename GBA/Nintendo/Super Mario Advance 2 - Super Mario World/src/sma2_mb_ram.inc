@ sma2_mb_ram.inc: RAM and external addresses of the Super Mario Advance 2 (E), Mario Bros. multiboot image build
	.equ gDmaBufA, 0x03000030
	.equ gDmaBufB, 0x03000038
	.equ gTimerReload, 0x03000040
	.equ gDmaBufIdx, 0x03000042
	.equ gMixEnabled, 0x03000043
	.equ gLastWave, 0x03000048
	.equ gActiveHead, 0x0300004C
	.equ gActiveTail, 0x030000C4
	.equ gFreeHead, 0x0300013C
	.equ gFreeTail, 0x030001B4
	.equ gKitInst, 0x03000230
	.equ gHookNote, 0x03000238
	.equ gHookCA, 0x0300023C
	.equ gCmdQueue, 0x03000240
	.equ gCmdRead, 0x0300048C
	.equ gCmdWrite, 0x03000490
	.equ gCmdCommitted, 0x03000494
	.equ gCmdEnd, 0x03000498
	.equ gCfg, 0x0300049C
	.equ gFnDownmix, 0x030004A0
	.equ gFnMixVoice, 0x030004A4
	.equ gFnEcho, 0x030004A8
	.equ gDmaBuffers, 0x030004AC
	.equ gMixDry, 0x0300076C
	.equ gTracks, 0x03000A2C
	.equ gIwramCode, 0x0300120C
	.equ gDsVoices, 0x0300156C
	.equ gPsgVoices, 0x030018B4
	.equ gPlayers, 0x03001A94
	.equ CpuFastSet, 0x0201E5B8	@ outside the driver
	.equ CpuSet, 0x0201E5BC	@ outside the driver
	.equ _call_via_r1, 0x0201E5E4	@ outside the driver
	.equ _call_via_r2, 0x0201E5E8	@ outside the driver
	.equ _call_via_r3, 0x0201E5EC	@ outside the driver
	.equ _call_via_r4, 0x0201E5F0	@ outside the driver
	.equ _call_via_r7, 0x0201E5FC	@ outside the driver
	.equ __divsi3, 0x0201E61C	@ outside the driver
	.equ __udivsi3, 0x0201E6B4	@ outside the driver
	.equ MemClear, 0x0201E7EC	@ outside the driver
