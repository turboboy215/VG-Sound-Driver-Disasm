@ ============================================================================
@ gbamod1_host.s -- Pinball game code that drives GBAModPlay v1's hardware (ROM 0x0800DD60-0x0800DDDC)
@ ============================================================================
@ ---- hardware registers
	.equ	REG_DISPCNT, 0x04000000
	.equ	REG_VCOUNT, 0x04000006
	.equ	REG_SOUNDCNT_L, 0x04000080
	.equ	REG_SOUNDCNT_H, 0x04000082
	.equ	REG_SOUNDCNT_X, 0x04000084
	.equ	REG_SOUNDBIAS, 0x04000088
	.equ	REG_FIFO_A, 0x040000A0
	.equ	REG_FIFO_B, 0x040000A4
	.equ	REG_DMA1SAD, 0x040000BC
	.equ	REG_DMA1DAD, 0x040000C0
	.equ	REG_DMA1CNT, 0x040000C4
	.equ	REG_DMA1CNT_H, 0x040000C6
	.equ	REG_DMA2SAD, 0x040000C8
	.equ	REG_DMA2DAD, 0x040000CC
	.equ	REG_DMA2CNT, 0x040000D0
	.equ	REG_DMA2CNT_H, 0x040000D2
	.equ	REG_DMA3SAD, 0x040000D4
	.equ	REG_DMA3DAD, 0x040000D8
	.equ	REG_DMA3CNT, 0x040000DC
	.equ	REG_DMA3CNT_H, 0x040000DE
	.equ	REG_TM0CNT_L, 0x04000100
	.equ	REG_TM0CNT_H, 0x04000102
	.equ	REG_TM1CNT_L, 0x04000104
	.equ	REG_TM1CNT_H, 0x04000106
	.equ	REG_IE, 0x04000200
	.equ	REG_IF, 0x04000202
	.equ	REG_WAITCNT, 0x04000204
	.equ	REG_IME, 0x04000208
	.syntax unified
	.cpu arm7tdmi

	.equ	gmpWaitVCountLeave, 0x080CE668

	.section .text.gmp1_host, "ax", %progbits
	.balign 4
@ --------------------------------------------------------------------------
@ hostStartDma(?, ?, ?, buffer)  (0x0800DD60)
@   Game code, not part of the player, included because it sets up the player's output:
@   DMA1CNT_H = 0; SOUNDCNT_X = 0; SOUNDCNT_H = 0x8B0E (DMA A on L+R, Timer 0); DMA1SAD = r3;
@   DMA1DAD = FIFO_A; TM0CNT_H = 0; TM0CNT_L = 0xFCE2 (21024 Hz); gmpWaitVCountLeave(0x3E) and
@   (0x3D); DMA1CNT_H = 0xB600; TM0CNT_H = 0x80
@ --------------------------------------------------------------------------
	.thumb
	.thumb_func
	.global hostStartDma
hostStartDma:
	push	{r4, r5, lr}                          @ 0800DD60
	ldr	r5, .Llit0800DDA8                      @ 0800DD62  =REG_DMA1CNT_H
	movs	r2, #0                                @ 0800DD64
	strh	r2, [r5]                              @ 0800DD66
	ldr	r0, .Llit0800DDAC                      @ 0800DD68  =REG_SOUNDCNT_X
	strh	r2, [r0]                              @ 0800DD6A
	ldr	r1, .Llit0800DDB0                      @ 0800DD6C  =REG_SOUNDCNT_H
	ldr	r4, .Llit0800DDB4                      @ 0800DD6E  =0x00008B0E
	adds	r0, r4, #0                            @ 0800DD70
	strh	r0, [r1]                              @ 0800DD72
	ldr	r0, .Llit0800DDB8                      @ 0800DD74  =REG_DMA1SAD
	str	r3, [r0]                               @ 0800DD76
	adds	r1, #0x3e                             @ 0800DD78
	subs	r0, #0x1c                             @ 0800DD7A
	str	r0, [r1]                               @ 0800DD7C
	ldr	r4, .Llit0800DDBC                      @ 0800DD7E  =REG_TM0CNT_H
	strh	r2, [r4]                              @ 0800DD80
	adds	r1, #0x40                             @ 0800DD82
	ldr	r2, .Llit0800DDC0                      @ 0800DD84  =0x0000FCE2
	adds	r0, r2, #0                            @ 0800DD86
	strh	r0, [r1]                              @ 0800DD88
	movs	r0, #0x3e                             @ 0800DD8A
	bl	gmpWaitVCountLeave                      @ 0800DD8C
	movs	r0, #0x3d                             @ 0800DD90
	bl	gmpWaitVCountLeave                      @ 0800DD92
	movs	r1, #0xb6                             @ 0800DD96
	lsls	r1, r1, #8                            @ 0800DD98
	adds	r0, r1, #0                            @ 0800DD9A
	strh	r0, [r5]                              @ 0800DD9C
	movs	r0, #0x80                             @ 0800DD9E
	strh	r0, [r4]                              @ 0800DDA0
	pop	{r4, r5}                               @ 0800DDA2
	pop	{r0}                                   @ 0800DDA4
	bx	r0                                      @ 0800DDA6
.Llit0800DDA8:
	.word	REG_DMA1CNT_H                        @ 0800DDA8
.Llit0800DDAC:
	.word	REG_SOUNDCNT_X                       @ 0800DDAC
.Llit0800DDB0:
	.word	REG_SOUNDCNT_H                       @ 0800DDB0
.Llit0800DDB4:
	.word	0x00008B0E                           @ 0800DDB4
.Llit0800DDB8:
	.word	REG_DMA1SAD                          @ 0800DDB8
.Llit0800DDBC:
	.word	REG_TM0CNT_H                         @ 0800DDBC
.Llit0800DDC0:
	.word	0x0000FCE2                           @ 0800DDC0
@ --------------------------------------------------------------------------
@ hostSoundOff / hostSoundOn  (0x0800DDC4, 0x0800DDD0)
@   SOUNDCNT_X = 0 / 0x80 (called by gmpPause / gmpResume)
@ --------------------------------------------------------------------------
	.thumb_func
	.global hostSoundOff
hostSoundOff:
	ldr	r1, .Llit0800DDCC                      @ 0800DDC4  =REG_SOUNDCNT_X
	movs	r0, #0                                @ 0800DDC6
	strh	r0, [r1]                              @ 0800DDC8
	bx	lr                                      @ 0800DDCA
.Llit0800DDCC:
	.word	REG_SOUNDCNT_X                       @ 0800DDCC
	.thumb_func
	.global hostSoundOn
hostSoundOn:
	ldr	r1, .Llit0800DDD8                      @ 0800DDD0  =REG_SOUNDCNT_X
	movs	r0, #0x80                             @ 0800DDD2
	strh	r0, [r1]                              @ 0800DDD4
	bx	lr                                      @ 0800DDD6
.Llit0800DDD8:
	.word	REG_SOUNDCNT_X                       @ 0800DDD8
