@ ============================================================================
@ gbamod1_rodata.s -- GBAModPlay version 1 constant data (Pinball, ROM 0x083C27C8-0x083C28B4)
@ Vibrato sine and the two switch tables.  The step table the player uses is in each module.
@ ============================================================================
	.syntax unified

	.section .gmp1_rodata, "a", %progbits
	.global gmpVibratoSine
gmpVibratoSine:                                        @ 083C27C8  s16[64]
	.hword	0, 24, 49, 74, 97, 120, 141, 161                    @ 083C27C8
	.hword	180, 197, 212, 224, 235, 244, 250, 253              @ 083C27D8
	.hword	255, 253, 250, 244, 235, 224, 212, 197              @ 083C27E8
	.hword	180, 161, 141, 120, 97, 74, 49, 24                  @ 083C27F8
	.hword	0, -24, -49, -74, -97, -120, -141, -161             @ 083C2808
	.hword	-180, -197, -212, -224, -235, -244, -250, -253      @ 083C2818
	.hword	-255, -253, -250, -244, -235, -224, -212, -197      @ 083C2828
	.hword	-180, -161, -141, -120, -97, -74, -49, -24          @ 083C2838
	.global gmpTickSwitch
gmpTickSwitch:                                        @ 083C2848
	.word	0x08004D00                          @ case 0x0
	.word	0x08004D48                          @ case 0x1
	.word	0x08004D48                          @ case 0x2
	.word	0x08004D52                          @ case 0x3
	.word	0x08004DB8                          @ case 0x4
	.word	0x08004E2E                          @ case 0x5
	.word	0x08004E2E                          @ case 0x6
	.word	0x08004E2E                          @ case 0x7
	.word	0x08004E2E                          @ case 0x8
	.word	0x08004E2E                          @ case 0x9
	.word	0x08004DF0                          @ case 0xA
	.global gmpRowSwitch
gmpRowSwitch:                                        @ 083C2874
	.word	0x08005020                          @ case 0x0
	.word	0x08005038                          @ case 0x1
	.word	0x0800504C                          @ case 0x2
	.word	0x08005064                          @ case 0x3
	.word	0x080050A2                          @ case 0x4
	.word	0x08005190                          @ case 0x5
	.word	0x08005190                          @ case 0x6
	.word	0x08005190                          @ case 0x7
	.word	0x08005190                          @ case 0x8
	.word	0x08005190                          @ case 0x9
	.word	0x080050BC                          @ case 0xA
	.word	0x080050CE                          @ case 0xB
	.word	0x08005124                          @ case 0xC
	.word	0x0800512C                          @ case 0xD
	.word	0x08005190                          @ case 0xE
	.word	0x08005158                          @ case 0xF
