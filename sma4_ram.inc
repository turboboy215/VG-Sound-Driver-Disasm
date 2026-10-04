@ sma4_ram.inc: RAM and external addresses of the Super Mario Advance 4 (E) v1.0, main program build
	.equ gDmaBufA, 0x03000118
	.equ gDmaBufB, 0x03000120
	.equ gTimerReload, 0x03000128
	.equ gDmaBufIdx, 0x0300012A
	.equ gMixEnabled, 0x0300012B
	.equ gKitInst, 0x03000130
	.equ gEchoShift, 0x03000138
	.equ gLastWave, 0x0300013C
	.equ gActiveVoices, 0x03000140
	.equ gFreeVoices, 0x03000144
	.equ gReservedVoices, 0x03000148
	.equ gVoiceCount, 0x0300014C
	.equ gEchoPos, 0x0300014D
	.equ gEchoLen, 0x0300014E
	.equ gEchoShiftTarget, 0x0300014F
	.equ gEchoTail, 0x03000150
	.equ gHookNote, 0x03000158
	.equ gHookCA, 0x0300015C
	.equ gCmdQueue, 0x03000160
	.equ gCmdRead, 0x03000394
	.equ gCmdWrite, 0x03000398
	.equ gCmdCommitted, 0x0300039C
	.equ gCmdEnd, 0x030003A0
	.equ gCfg, 0x030003A4
	.equ gFnDownmix, 0x030003A8
	.equ gFnMixVoice, 0x030003AC
	.equ gFnEcho, 0x030003B0
	.equ gDmaBuffers, 0x030003B4
	.equ gMixDry, 0x03000674
	.equ gMixWet, 0x03000934
	.equ gEchoHistory, 0x03000BF4
	.equ gTracks, 0x03000BF8
	.equ gIwramCode, 0x030013D8
	.equ gDsVoices, 0x03001738
	.equ gPsgVoices, 0x03001A80
	.equ gPlayers, 0x03001C60
	.equ MemClear, 0x08002D48	@ outside the driver
	.equ CpuFastSet, 0x080EAA84	@ outside the driver
	.equ CpuSet, 0x080EAA88	@ outside the driver
	.equ Div, 0x080EAA8C	@ outside the driver
	.equ _call_via_r1, 0x080EB34C	@ outside the driver
	.equ _call_via_r2, 0x080EB350	@ outside the driver
	.equ _call_via_r3, 0x080EB354	@ outside the driver
	.equ _call_via_r4, 0x080EB358	@ outside the driver
	.equ _call_via_r7, 0x080EB364	@ outside the driver
	.equ __divsi3, 0x080EB384	@ outside the driver
	.equ __udivsi3, 0x080EB530	@ outside the driver
