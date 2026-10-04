@ zelda_ram.inc: RAM and external addresses of the A Link to the Past & Four Swords (E), ALttP program build
	.equ gDmaBufA, 0x03000140
	.equ gDmaBufB, 0x03000148
	.equ gTimerReload, 0x03000150
	.equ gDmaBufIdx, 0x03000152
	.equ gMixEnabled, 0x03000153
	.equ gKitInst, 0x03000158
	.equ gEchoShift, 0x03000160
	.equ gLastWave, 0x03000164
	.equ gActiveVoices, 0x03000168
	.equ gFreeVoices, 0x0300016C
	.equ gReservedVoices, 0x03000170
	.equ gVoiceCount, 0x03000174
	.equ gEchoPos, 0x03000175
	.equ gEchoLen, 0x03000176
	.equ gEchoShiftTarget, 0x03000177
	.equ gEchoTail, 0x03000178
	.equ gHookNote, 0x03000180
	.equ gHookCA, 0x03000184
	.equ gCmdQueue, 0x03000188
	.equ gCmdRead, 0x030003BC
	.equ gCmdWrite, 0x030003C0
	.equ gCmdCommitted, 0x030003C4
	.equ gCmdEnd, 0x030003C8
	.equ gCfg, 0x030003CC
	.equ gFnDownmix, 0x030003D0
	.equ gFnMixVoice, 0x030003D4
	.equ gFnEcho, 0x030003D8
	.equ gDmaBuffers, 0x030003DC
	.equ gMixDry, 0x0300069C
	.equ gMixWet, 0x0300095C
	.equ gEchoHistory, 0x03000C1C
	.equ gTracks, 0x03000C20
	.equ gIwramCode, 0x03001400
	.equ gDsVoices, 0x03001760
	.equ gPsgVoices, 0x03001AA8
	.equ gPlayers, 0x03001C88
	.equ MemClear, 0x08069F24	@ outside the driver
	.equ CpuFastSet, 0x08136E40	@ outside the driver
	.equ CpuSet, 0x08136E44	@ outside the driver
	.equ Div, 0x08136E48	@ outside the driver
	.equ _call_via_r1, 0x081372B4	@ outside the driver
	.equ _call_via_r2, 0x081372B8	@ outside the driver
	.equ _call_via_r3, 0x081372BC	@ outside the driver
	.equ _call_via_r4, 0x081372C0	@ outside the driver
	.equ _call_via_r7, 0x081372CC	@ outside the driver
	.equ __divsi3, 0x081372EC	@ outside the driver
	.equ __udivsi3, 0x08137488	@ outside the driver
