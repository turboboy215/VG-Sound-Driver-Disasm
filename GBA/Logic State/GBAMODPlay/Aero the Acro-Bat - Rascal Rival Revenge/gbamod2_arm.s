@ ============================================================================
@ gbamod2_arm.s -- GBAModPlay version 2, ARM module (Aero, ROM 0x08104980-0x08104B00)
@ DMA restart veneer, the "call through r3" veneer and the per-channel mixer.  The 0x12345676
@ words are the same markers as in v1 and v3.  Rebuilt byte for byte by gbamod2.mk.
@ ============================================================================
	.syntax unified
	.cpu arm7tdmi


	.section .text.gmp2_arm, "ax", %progbits
	.balign 4
@ --------------------------------------------------------------------------
@ gmpDmaRestartAB(buffer)  (0x08104980)
@   Thumb "bx pc" veneer into ARM: DMA1CNT_H = 0; DMA1SAD = buffer; DMA1CNT_H = 0xB600; same for
@   DMA2.  Called by gmpVBlank every frame.
@ --------------------------------------------------------------------------
	.thumb
	.thumb_func
	.global gmpDmaRestartAB
gmpDmaRestartAB:
	bx	pc                                      @ 08104980
	.hword	0x0000                              @ 08104982  (padding)
	.arm
	push	{r0, r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 08104984
	mov	r5, #0x4000000                         @ 08104988
	mov	r4, #0                                 @ 0810498C
	mov	r6, #0xb600                            @ 08104990
	strh	r4, [r5, #0xc6]                       @ 08104994
	str	r0, [r5, #0xbc]                        @ 08104998
	strh	r6, [r5, #0xc6]                       @ 0810499C
	strh	r4, [r5, #0xd2]                       @ 081049A0
	str	r0, [r5, #0xc8]                        @ 081049A4
	strh	r6, [r5, #0xd2]                       @ 081049A8
	pop	{r0, r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 081049AC
	bx	lr                                      @ 081049B0
	.word	0x00000000, 0x00000000, 0x00000000   @ 081049B4
@ --------------------------------------------------------------------------
@ gmpCallR3  (0x081049C0)
@   bx r3: gmpMix calls the IWRAM copy of the mixer through it.
@ --------------------------------------------------------------------------
	.thumb
	.thumb_func
	.global gmpCallR3
gmpCallR3:
	bx	r3                                      @ 081049C0
	.hword	0x0000                              @ 081049C2
	.word	0x00000000, 0x00000000, 0x00000000, 0x12345676@ 081049C4
	.word	0x12345676, 0x12345676               @ 081049D4
.Llit081049DC:
	.word	0x00000FFF                           @ 081049DC
	.word	0x12345676                           @ 081049E0
@ --------------------------------------------------------------------------
@ gmpMixChannel(ch, dst, n)  (0x081049E4)
@   Copied to IWRAM by gmpCopyMixer (600 bytes are copied; the routine is 0x118).
@     if (CH_end == 2) return;                                   stopped
@     vol == 64: fast path without the multiply (sample >> 2 = sample * 64 >> 8)
@     for n samples: i = pos >> 12; if (i >= end) { ptr += loopStart; loopStart = 0; end = loopLen;
@                     pos &= 0xFFF }   -- keeps only the fraction, so a step > 1 drops samples
@                    *dst++ += ptr[i] * vol >> 8; pos += step
@     A one-shot sample has loopLen 0: after its end the rest of the call replays ptr[0] of the
@     sample (end = 0, i = 0), and the C side skips it from the next frame on (CH_end <= 2).
@     No clipping: the 8-bit add wraps.
@ --------------------------------------------------------------------------
	.arm
	.global gmpMixChannel
gmpMixChannel:
	push	{r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 081049E4
	stmdb	sp!, {r0}                            @ 081049E8
	ldrh	sl, [r0, #0xc]                        @ 081049EC
	cmp	sl, #2                                 @ 081049F0  CH_end == 2: stopped
	beq	.L08104A64                             @ 081049F4
	ldr	sb, [r0, #0x14]                        @ 081049F8
	cmp	sb, #0x40                              @ 081049FC  volume 64: skip the multiply
	beq	.L08104A88                             @ 08104A00
	ldr	r3, [r0]                               @ 08104A04
	ldr	r4, [r0, #4]                           @ 08104A08
	ldr	r5, [r0, #8]                           @ 08104A0C
	ldr	fp, .Llit081049DC                      @ 08104A10  =0x00000FFF
	ldrh	ip, [r0, #0xe]                        @ 08104A14
	ldrh	r0, [r0, #0x10]                       @ 08104A18
.L08104A1C:
	asr	r6, r4, #0xc                           @ 08104A1C
	cmp	r6, sl                                 @ 08104A20
	bge	.L08104A70                             @ 08104A24
.L08104A28:
	add	r4, r4, r5                             @ 08104A28
	ldrsb	r7, [r3, r6]                         @ 08104A2C  sample
	ldrsb	r8, [r1]                             @ 08104A30
	mul	r7, sb, r7                             @ 08104A34
	add	r7, r8, r7, asr #8                     @ 08104A38  dst += s * vol >> 8
	strb	r7, [r1], #1                          @ 08104A3C
	subs	r2, r2, #1                            @ 08104A40
	bne	.L08104A1C                             @ 08104A44
	ldm	sp!, {r0}                              @ 08104A48
	str	r3, [r0]                               @ 08104A4C
	str	r4, [r0, #4]                           @ 08104A50
	str	sl, [r0, #0xc]                         @ 08104A54
	strh	ip, [r0, #0xe]                        @ 08104A58
	pop	{r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 08104A5C
	bx	lr                                      @ 08104A60
.L08104A64:
	ldm	sp!, {r0}                              @ 08104A64
	pop	{r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 08104A68
	bx	lr                                      @ 08104A6C
.L08104A70:
	add	r3, r3, ip                             @ 08104A70  end reached: ptr += loopStart
	mov	ip, #0                                 @ 08104A74
	mov	sl, r0                                 @ 08104A78
	and	r4, r4, fp                             @ 08104A7C  pos &= 0xFFF
	asr	r6, r4, #0xc                           @ 08104A80
	b	.L08104A28                               @ 08104A84
.L08104A88:
	ldr	r3, [r0]                               @ 08104A88
	ldr	r4, [r0, #4]                           @ 08104A8C
	ldr	r5, [r0, #8]                           @ 08104A90
	ldr	fp, .Llit081049DC                      @ 08104A94  =0x00000FFF
	ldrh	ip, [r0, #0xe]                        @ 08104A98
	ldrh	r0, [r0, #0x10]                       @ 08104A9C
.L08104AA0:
	asr	r6, r4, #0xc                           @ 08104AA0
	cmp	r6, sl                                 @ 08104AA4
	bge	.L08104AE4                             @ 08104AA8
	add	r4, r4, r5                             @ 08104AAC
	ldrsb	r7, [r3, r6]                         @ 08104AB0
	ldrsb	r8, [r1]                             @ 08104AB4
	add	r7, r8, r7, asr #2                     @ 08104AB8  dst += s >> 2 (vol 64)
	strb	r7, [r1], #1                          @ 08104ABC
	subs	r2, r2, #1                            @ 08104AC0
	bne	.L08104AA0                             @ 08104AC4
	ldm	sp!, {r0}                              @ 08104AC8
	str	r3, [r0]                               @ 08104ACC
	str	r4, [r0, #4]                           @ 08104AD0
	str	sl, [r0, #0xc]                         @ 08104AD4
	strh	ip, [r0, #0xe]                        @ 08104AD8
	pop	{r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 08104ADC
	bx	lr                                      @ 08104AE0
.L08104AE4:
	add	r3, r3, ip                             @ 08104AE4
	mov	ip, #0                                 @ 08104AE8
	mov	sl, r0                                 @ 08104AEC
	and	r4, r4, fp                             @ 08104AF0
	asr	r6, r4, #0xc                           @ 08104AF4
	b	.L08104A28                               @ 08104AF8
	.word	0x00000000                           @ 08104AFC
