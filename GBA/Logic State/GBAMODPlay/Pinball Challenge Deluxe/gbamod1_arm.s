@ ============================================================================
@ gbamod1_arm.s -- GBAModPlay version 1, ARM/assembler module (Pinball, ROM 0x080CE0C0-0x080CE758)
@ Veneers, three mixers, correct VCOUNT waits, the DMA restart, an RLE fill and the LZ77 SWI
@ stubs.  v3's ARM module is a descendant of this file.  Rebuilt byte for byte by gbamod1.mk.
@ ============================================================================
	.syntax unified
	.cpu arm7tdmi


	.section .text.gmp1_arm, "ax", %progbits
	.balign 4
@ --------------------------------------------------------------------------
@ gmpCallR3 / gmpCallR3b  (0x080CE0C0, 0x080CE0C2)
@   bx r3 veneers; gmpMix calls the EWRAM mixer through the first.  The 0x12345676 words are markers.
@ --------------------------------------------------------------------------
	.thumb
	.thumb_func
	.global gmpCallR3
gmpCallR3:
	bx	r3                                      @ 080CE0C0
	.thumb_func
	.global gmpCallR3b
gmpCallR3b:
	bx	r3                                      @ 080CE0C2
	.word	0x12345676, 0x12345676, 0x12345676   @ 080CE0C4
.Llit080CE0D0:
	.word	0x00000FFF                           @ 080CE0D0
	.word	0x12345676                           @ 080CE0D4
@ --------------------------------------------------------------------------
@ gmpMixChannel(ch, dst, n)  (0x080CE0D8)  -- unused
@   Plain per-channel mixer (ROM copy, not called): as in v2, with lsr instead of asr for
@   pos >> 12 and the product >> 8 (harmless: only the low byte is stored).
@ --------------------------------------------------------------------------
	.arm
	.global gmpMixChannel
gmpMixChannel:
	push	{r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 080CE0D8
	stmdb	sp!, {r0}                            @ 080CE0DC
	ldr	r3, [r0]                               @ 080CE0E0
	ldr	r4, [r0, #4]                           @ 080CE0E4
	ldr	r5, [r0, #8]                           @ 080CE0E8
	ldr	sb, [r0, #0x14]                        @ 080CE0EC
	ldrh	sl, [r0, #0xc]                        @ 080CE0F0
	ldr	fp, .Llit080CE0D0                      @ 080CE0F4  =0x00000FFF
	ldrh	ip, [r0, #0xe]                        @ 080CE0F8
	ldrh	r0, [r0, #0x10]                       @ 080CE0FC
.L080CE100:
	lsr	r6, r4, #0xc                           @ 080CE100
	cmp	r6, sl                                 @ 080CE104
	bge	.L080CE148                             @ 080CE108
.L080CE10C:
	add	r4, r4, r5                             @ 080CE10C
	ldrsb	r7, [r3, r6]                         @ 080CE110
	ldrsb	r8, [r1]                             @ 080CE114
	mul	r7, sb, r7                             @ 080CE118
	add	r7, r8, r7, lsr #8                     @ 080CE11C
	strb	r7, [r1], #1                          @ 080CE120
	subs	r2, r2, #1                            @ 080CE124
	bne	.L080CE100                             @ 080CE128
	ldm	sp!, {r0}                              @ 080CE12C
	str	r3, [r0]                               @ 080CE130
	str	r4, [r0, #4]                           @ 080CE134
	str	sl, [r0, #0xc]                         @ 080CE138
	strh	ip, [r0, #0xe]                        @ 080CE13C
	pop	{r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 080CE140
	bx	lr                                      @ 080CE144
.L080CE148:
	add	r3, r3, ip                             @ 080CE148
	mov	ip, #0                                 @ 080CE14C
	mov	sl, r0                                 @ 080CE150
	and	r4, r4, fp                             @ 080CE154
	lsr	r6, r4, #0xc                           @ 080CE158
	b	.L080CE10C                               @ 080CE15C
.Llit080CE160:
	.word	.L080CE30C                           @ 080CE160
.Llit080CE164:
	.word	.L080CE2B8                           @ 080CE164
.Llit080CE168:
	.word	.L080CE294                           @ 080CE168
.Llit080CE16C:
	.word	.L080CE270                           @ 080CE16C
.Llit080CE170:
	.word	.L080CE24C                           @ 080CE170
.Llit080CE174:
	.word	.L080CE228                           @ 080CE174
.Llit080CE178:
	.word	.L080CE204                           @ 080CE178
.Llit080CE17C:
	.word	.L080CE1E0                           @ 080CE17C
.Llit080CE180:
	.word	0x00000FFF                           @ 080CE180
@ --------------------------------------------------------------------------
@ gmpMixChannelUnrolled(ch, dst, n)  (0x080CE184)
@   The mixer v1 uses, copied to EWRAM by gmpCopyMixers.  Eight samples per loop pass (n >> 3
@   passes), then n & 7 samples by jumping into the unrolled body through the table at
@   0x080CE160 with a -1 sentinel pushed on the stack.  The table and the "ldr r8, =table" hold
@   absolute ROM addresses, so that last part runs from ROM even when called in EWRAM.
@   Per sample: if (pos >> 12 >= end) { ptr += loopStart; loopStart = 0; end = loopLen;
@   pos &= 0xFFF }; *dst++ += ptr[pos >> 12] * vol >> 8; pos += step.  No clipping.
@ --------------------------------------------------------------------------
	.global gmpMixChannelUnrolled
gmpMixChannelUnrolled:
	push	{r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 080CE184
	stmdb	sp!, {r0}                            @ 080CE188
	stmdb	sp!, {r2}                            @ 080CE18C
	lsr	r2, r2, #3                             @ 080CE190
	ldr	r3, [r0]                               @ 080CE194
	ldr	r4, [r0, #4]                           @ 080CE198
	ldr	r5, [r0, #8]                           @ 080CE19C
	ldr	sb, [r0, #0x14]                        @ 080CE1A0
	ldrh	sl, [r0, #0xc]                        @ 080CE1A4
	ldr	fp, .Llit080CE180                      @ 080CE1A8  =0x00000FFF
	ldrh	ip, [r0, #0xe]                        @ 080CE1AC
	ldrh	r0, [r0, #0x10]                       @ 080CE1B0
	cmp	r2, #0                                 @ 080CE1B4
	beq	.L080CE2E4                             @ 080CE1B8
.L080CE1BC:
	lsr	r6, r4, #0xc                           @ 080CE1BC
	cmp	r6, sl                                 @ 080CE1C0
	bge	.L080CE330                             @ 080CE1C4
.L080CE1C8:
	add	r4, r4, r5                             @ 080CE1C8
	ldrsb	r7, [r3, r6]                         @ 080CE1CC
	ldrsb	r8, [r1]                             @ 080CE1D0
	mul	r7, sb, r7                             @ 080CE1D4
	add	r7, r8, r7, lsr #8                     @ 080CE1D8
	strb	r7, [r1], #1                          @ 080CE1DC
.L080CE1E0:
	lsr	r6, r4, #0xc                           @ 080CE1E0
	cmp	r6, sl                                 @ 080CE1E4
	bge	.L080CE348                             @ 080CE1E8
.L080CE1EC:
	add	r4, r4, r5                             @ 080CE1EC
	ldrsb	r7, [r3, r6]                         @ 080CE1F0
	ldrsb	r8, [r1]                             @ 080CE1F4
	mul	r7, sb, r7                             @ 080CE1F8
	add	r7, r8, r7, lsr #8                     @ 080CE1FC
	strb	r7, [r1], #1                          @ 080CE200
.L080CE204:
	lsr	r6, r4, #0xc                           @ 080CE204
	cmp	r6, sl                                 @ 080CE208
	bge	.L080CE360                             @ 080CE20C
.L080CE210:
	add	r4, r4, r5                             @ 080CE210
	ldrsb	r7, [r3, r6]                         @ 080CE214
	ldrsb	r8, [r1]                             @ 080CE218
	mul	r7, sb, r7                             @ 080CE21C
	add	r7, r8, r7, lsr #8                     @ 080CE220
	strb	r7, [r1], #1                          @ 080CE224
.L080CE228:
	lsr	r6, r4, #0xc                           @ 080CE228
	cmp	r6, sl                                 @ 080CE22C
	bge	.L080CE378                             @ 080CE230
.L080CE234:
	add	r4, r4, r5                             @ 080CE234
	ldrsb	r7, [r3, r6]                         @ 080CE238
	ldrsb	r8, [r1]                             @ 080CE23C
	mul	r7, sb, r7                             @ 080CE240
	add	r7, r8, r7, lsr #8                     @ 080CE244
	strb	r7, [r1], #1                          @ 080CE248
.L080CE24C:
	lsr	r6, r4, #0xc                           @ 080CE24C
	cmp	r6, sl                                 @ 080CE250
	bge	.L080CE390                             @ 080CE254
.L080CE258:
	add	r4, r4, r5                             @ 080CE258
	ldrsb	r7, [r3, r6]                         @ 080CE25C
	ldrsb	r8, [r1]                             @ 080CE260
	mul	r7, sb, r7                             @ 080CE264
	add	r7, r8, r7, lsr #8                     @ 080CE268
	strb	r7, [r1], #1                          @ 080CE26C
.L080CE270:
	lsr	r6, r4, #0xc                           @ 080CE270
	cmp	r6, sl                                 @ 080CE274
	bge	.L080CE3A8                             @ 080CE278
.L080CE27C:
	add	r4, r4, r5                             @ 080CE27C
	ldrsb	r7, [r3, r6]                         @ 080CE280
	ldrsb	r8, [r1]                             @ 080CE284
	mul	r7, sb, r7                             @ 080CE288
	add	r7, r8, r7, lsr #8                     @ 080CE28C
	strb	r7, [r1], #1                          @ 080CE290
.L080CE294:
	lsr	r6, r4, #0xc                           @ 080CE294
	cmp	r6, sl                                 @ 080CE298
	bge	.L080CE3C0                             @ 080CE29C
.L080CE2A0:
	add	r4, r4, r5                             @ 080CE2A0
	ldrsb	r7, [r3, r6]                         @ 080CE2A4
	ldrsb	r8, [r1]                             @ 080CE2A8
	mul	r7, sb, r7                             @ 080CE2AC
	add	r7, r8, r7, lsr #8                     @ 080CE2B0
	strb	r7, [r1], #1                          @ 080CE2B4
.L080CE2B8:
	lsr	r6, r4, #0xc                           @ 080CE2B8
	cmp	r6, sl                                 @ 080CE2BC
	bge	.L080CE3D8                             @ 080CE2C0
.L080CE2C4:
	add	r4, r4, r5                             @ 080CE2C4
	ldrsb	r7, [r3, r6]                         @ 080CE2C8
	ldrsb	r8, [r1]                             @ 080CE2CC
	mul	r7, sb, r7                             @ 080CE2D0
	add	r7, r8, r7, lsr #8                     @ 080CE2D4
	strb	r7, [r1], #1                          @ 080CE2D8
	subs	r2, r2, #1                            @ 080CE2DC
	bne	.L080CE1BC                             @ 080CE2E0
.L080CE2E4:
	ldm	sp!, {r2}                              @ 080CE2E4
	cmp	r2, #0                                 @ 080CE2E8
	blt	sub_080CE310                           @ 080CE2EC
	and	r2, r2, #7                             @ 080CE2F0
	ldr	r7, .Llit080CE32C                      @ 080CE2F4  =0xFFFFFFFF
	stmdb	sp!, {r7}                            @ 080CE2F8
	ldr	r8, .Llit080CE660                      @ 080CE2FC  =0x080CE160  absolute ROM address
	lsl	r7, r2, #2                             @ 080CE300
	mov	r2, #1                                 @ 080CE304
	ldr	pc, [r8, r7]                           @ 080CE308  jump into the unrolled body for the last n & 7 samples
.L080CE30C:
	ldm	sp!, {r2}                              @ 080CE30C
	.global sub_080CE310
sub_080CE310:
	ldm	sp!, {r0}                              @ 080CE310
	str	r3, [r0]                               @ 080CE314
	str	r4, [r0, #4]                           @ 080CE318
	str	sl, [r0, #0xc]                         @ 080CE31C
	strh	ip, [r0, #0xe]                        @ 080CE320
	pop	{r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 080CE324
	bx	lr                                      @ 080CE328
.Llit080CE32C:
	.word	0xFFFFFFFF                           @ 080CE32C
.L080CE330:
	add	r3, r3, ip                             @ 080CE330
	mov	ip, #0                                 @ 080CE334
	mov	sl, r0                                 @ 080CE338
	and	r4, r4, fp                             @ 080CE33C
	lsr	r6, r4, #0xc                           @ 080CE340
	b	.L080CE1C8                               @ 080CE344
.L080CE348:
	add	r3, r3, ip                             @ 080CE348
	mov	ip, #0                                 @ 080CE34C
	mov	sl, r0                                 @ 080CE350
	and	r4, r4, fp                             @ 080CE354
	lsr	r6, r4, #0xc                           @ 080CE358
	b	.L080CE1EC                               @ 080CE35C
.L080CE360:
	add	r3, r3, ip                             @ 080CE360
	mov	ip, #0                                 @ 080CE364
	mov	sl, r0                                 @ 080CE368
	and	r4, r4, fp                             @ 080CE36C
	lsr	r6, r4, #0xc                           @ 080CE370
	b	.L080CE210                               @ 080CE374
.L080CE378:
	add	r3, r3, ip                             @ 080CE378
	mov	ip, #0                                 @ 080CE37C
	mov	sl, r0                                 @ 080CE380
	and	r4, r4, fp                             @ 080CE384
	lsr	r6, r4, #0xc                           @ 080CE388
	b	.L080CE234                               @ 080CE38C
.L080CE390:
	add	r3, r3, ip                             @ 080CE390
	mov	ip, #0                                 @ 080CE394
	mov	sl, r0                                 @ 080CE398
	and	r4, r4, fp                             @ 080CE39C
	lsr	r6, r4, #0xc                           @ 080CE3A0
	b	.L080CE258                               @ 080CE3A4
.L080CE3A8:
	add	r3, r3, ip                             @ 080CE3A8
	mov	ip, #0                                 @ 080CE3AC
	mov	sl, r0                                 @ 080CE3B0
	and	r4, r4, fp                             @ 080CE3B4
	lsr	r6, r4, #0xc                           @ 080CE3B8
	b	.L080CE27C                               @ 080CE3BC
.L080CE3C0:
	add	r3, r3, ip                             @ 080CE3C0
	mov	ip, #0                                 @ 080CE3C4
	mov	sl, r0                                 @ 080CE3C8
	and	r4, r4, fp                             @ 080CE3CC
	lsr	r6, r4, #0xc                           @ 080CE3D0
	b	.L080CE2A0                               @ 080CE3D4
.L080CE3D8:
	add	r3, r3, ip                             @ 080CE3D8
	mov	ip, #0                                 @ 080CE3DC
	mov	sl, r0                                 @ 080CE3E0
	and	r4, r4, fp                             @ 080CE3E4
	lsr	r6, r4, #0xc                           @ 080CE3E8
	b	.L080CE2C4                               @ 080CE3EC
.Llit080CE3F0:
	.word	.L080CE57C                           @ 080CE3F0
.Llit080CE3F4:
	.word	.L080CE52C                           @ 080CE3F4
.Llit080CE3F8:
	.word	.L080CE50C                           @ 080CE3F8
.Llit080CE3FC:
	.word	.L080CE4EC                           @ 080CE3FC
.Llit080CE400:
	.word	.L080CE4CC                           @ 080CE400
.Llit080CE404:
	.word	.L080CE4AC                           @ 080CE404
.Llit080CE408:
	.word	.L080CE48C                           @ 080CE408
.Llit080CE40C:
	.word	.L080CE46C                           @ 080CE40C
.Llit080CE410:
	.word	0x00000FFF                           @ 080CE410
@ --------------------------------------------------------------------------
@ gmpMixChannelNoVol(ch, dst, n)  (0x080CE414)  -- unused
@   Same structure without the multiply (adds sample >> 2, i.e. volume 64).  Copied to EWRAM by
@   gmpCopyMixers but never called; its remainder table is at 0x080CE3F0.
@ --------------------------------------------------------------------------
	.global gmpMixChannelNoVol
gmpMixChannelNoVol:
	push	{r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 080CE414
	stmdb	sp!, {r0}                            @ 080CE418
	stmdb	sp!, {r2}                            @ 080CE41C
	lsr	r2, r2, #3                             @ 080CE420
	ldr	r3, [r0]                               @ 080CE424
	ldr	r4, [r0, #4]                           @ 080CE428
	ldr	r5, [r0, #8]                           @ 080CE42C
	ldr	sb, [r0, #0x14]                        @ 080CE430
	ldrh	sl, [r0, #0xc]                        @ 080CE434
	ldr	fp, .Llit080CE410                      @ 080CE438  =0x00000FFF
	ldrh	ip, [r0, #0xe]                        @ 080CE43C
	ldrh	r0, [r0, #0x10]                       @ 080CE440
	cmp	r2, #0                                 @ 080CE444
	beq	.L080CE554                             @ 080CE448
.L080CE44C:
	lsr	r6, r4, #0xc                           @ 080CE44C
	cmp	r6, sl                                 @ 080CE450
	bge	.L080CE5A0                             @ 080CE454
.L080CE458:
	add	r4, r4, r5                             @ 080CE458
	ldrsb	r7, [r3, r6]                         @ 080CE45C
	ldrsb	r8, [r1]                             @ 080CE460
	add	r7, r8, r7, lsr #2                     @ 080CE464
	strb	r7, [r1], #1                          @ 080CE468
.L080CE46C:
	lsr	r6, r4, #0xc                           @ 080CE46C
	cmp	r6, sl                                 @ 080CE470
	bge	.L080CE5B8                             @ 080CE474
.L080CE478:
	add	r4, r4, r5                             @ 080CE478
	ldrsb	r7, [r3, r6]                         @ 080CE47C
	ldrsb	r8, [r1]                             @ 080CE480
	add	r7, r8, r7, lsr #2                     @ 080CE484
	strb	r7, [r1], #1                          @ 080CE488
.L080CE48C:
	lsr	r6, r4, #0xc                           @ 080CE48C
	cmp	r6, sl                                 @ 080CE490
	bge	.L080CE5D0                             @ 080CE494
.L080CE498:
	add	r4, r4, r5                             @ 080CE498
	ldrsb	r7, [r3, r6]                         @ 080CE49C
	ldrsb	r8, [r1]                             @ 080CE4A0
	add	r7, r8, r7, lsr #2                     @ 080CE4A4
	strb	r7, [r1], #1                          @ 080CE4A8
.L080CE4AC:
	lsr	r6, r4, #0xc                           @ 080CE4AC
	cmp	r6, sl                                 @ 080CE4B0
	bge	.L080CE5E8                             @ 080CE4B4
.L080CE4B8:
	add	r4, r4, r5                             @ 080CE4B8
	ldrsb	r7, [r3, r6]                         @ 080CE4BC
	ldrsb	r8, [r1]                             @ 080CE4C0
	add	r7, r8, r7, lsr #2                     @ 080CE4C4
	strb	r7, [r1], #1                          @ 080CE4C8
.L080CE4CC:
	lsr	r6, r4, #0xc                           @ 080CE4CC
	cmp	r6, sl                                 @ 080CE4D0
	bge	.L080CE600                             @ 080CE4D4
.L080CE4D8:
	add	r4, r4, r5                             @ 080CE4D8
	ldrsb	r7, [r3, r6]                         @ 080CE4DC
	ldrsb	r8, [r1]                             @ 080CE4E0
	add	r7, r8, r7, lsr #2                     @ 080CE4E4
	strb	r7, [r1], #1                          @ 080CE4E8
.L080CE4EC:
	lsr	r6, r4, #0xc                           @ 080CE4EC
	cmp	r6, sl                                 @ 080CE4F0
	bge	.L080CE618                             @ 080CE4F4
.L080CE4F8:
	add	r4, r4, r5                             @ 080CE4F8
	ldrsb	r7, [r3, r6]                         @ 080CE4FC
	ldrsb	r8, [r1]                             @ 080CE500
	add	r7, r8, r7, lsr #2                     @ 080CE504
	strb	r7, [r1], #1                          @ 080CE508
.L080CE50C:
	lsr	r6, r4, #0xc                           @ 080CE50C
	cmp	r6, sl                                 @ 080CE510
	bge	.L080CE630                             @ 080CE514
.L080CE518:
	add	r4, r4, r5                             @ 080CE518
	ldrsb	r7, [r3, r6]                         @ 080CE51C
	ldrsb	r8, [r1]                             @ 080CE520
	add	r7, r8, r7, lsr #2                     @ 080CE524
	strb	r7, [r1], #1                          @ 080CE528
.L080CE52C:
	lsr	r6, r4, #0xc                           @ 080CE52C
	cmp	r6, sl                                 @ 080CE530
	bge	.L080CE648                             @ 080CE534
.L080CE538:
	add	r4, r4, r5                             @ 080CE538
	ldrsb	r7, [r3, r6]                         @ 080CE53C
	ldrsb	r8, [r1]                             @ 080CE540
	add	r7, r8, r7, lsr #2                     @ 080CE544
	strb	r7, [r1], #1                          @ 080CE548
	subs	r2, r2, #1                            @ 080CE54C
	bne	.L080CE44C                             @ 080CE550
.L080CE554:
	ldm	sp!, {r2}                              @ 080CE554
	cmp	r2, #0                                 @ 080CE558
	blt	sub_080CE580                           @ 080CE55C
	and	r2, r2, #7                             @ 080CE560
	ldr	r7, .Llit080CE59C                      @ 080CE564  =0xFFFFFFFF
	stmdb	sp!, {r7}                            @ 080CE568
	ldr	r8, .Llit080CE664                      @ 080CE56C  =0x080CE3F0
	lsl	r7, r2, #2                             @ 080CE570
	mov	r2, #1                                 @ 080CE574
	ldr	pc, [r8, r7]                           @ 080CE578
.L080CE57C:
	ldm	sp!, {r2}                              @ 080CE57C
	.global sub_080CE580
sub_080CE580:
	ldm	sp!, {r0}                              @ 080CE580
	str	r3, [r0]                               @ 080CE584
	str	r4, [r0, #4]                           @ 080CE588
	str	sl, [r0, #0xc]                         @ 080CE58C
	strh	ip, [r0, #0xe]                        @ 080CE590
	pop	{r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 080CE594
	bx	lr                                      @ 080CE598
.Llit080CE59C:
	.word	0xFFFFFFFF                           @ 080CE59C
.L080CE5A0:
	add	r3, r3, ip                             @ 080CE5A0
	mov	ip, #0                                 @ 080CE5A4
	mov	sl, r0                                 @ 080CE5A8
	and	r4, r4, fp                             @ 080CE5AC
	lsr	r6, r4, #0xc                           @ 080CE5B0
	b	.L080CE458                               @ 080CE5B4
.L080CE5B8:
	add	r3, r3, ip                             @ 080CE5B8
	mov	ip, #0                                 @ 080CE5BC
	mov	sl, r0                                 @ 080CE5C0
	and	r4, r4, fp                             @ 080CE5C4
	lsr	r6, r4, #0xc                           @ 080CE5C8
	b	.L080CE478                               @ 080CE5CC
.L080CE5D0:
	add	r3, r3, ip                             @ 080CE5D0
	mov	ip, #0                                 @ 080CE5D4
	mov	sl, r0                                 @ 080CE5D8
	and	r4, r4, fp                             @ 080CE5DC
	lsr	r6, r4, #0xc                           @ 080CE5E0
	b	.L080CE498                               @ 080CE5E4
.L080CE5E8:
	add	r3, r3, ip                             @ 080CE5E8
	mov	ip, #0                                 @ 080CE5EC
	mov	sl, r0                                 @ 080CE5F0
	and	r4, r4, fp                             @ 080CE5F4
	lsr	r6, r4, #0xc                           @ 080CE5F8
	b	.L080CE4B8                               @ 080CE5FC
.L080CE600:
	add	r3, r3, ip                             @ 080CE600
	mov	ip, #0                                 @ 080CE604
	mov	sl, r0                                 @ 080CE608
	and	r4, r4, fp                             @ 080CE60C
	lsr	r6, r4, #0xc                           @ 080CE610
	b	.L080CE4D8                               @ 080CE614
.L080CE618:
	add	r3, r3, ip                             @ 080CE618
	mov	ip, #0                                 @ 080CE61C
	mov	sl, r0                                 @ 080CE620
	and	r4, r4, fp                             @ 080CE624
	lsr	r6, r4, #0xc                           @ 080CE628
	b	.L080CE4F8                               @ 080CE62C
.L080CE630:
	add	r3, r3, ip                             @ 080CE630
	mov	ip, #0                                 @ 080CE634
	mov	sl, r0                                 @ 080CE638
	and	r4, r4, fp                             @ 080CE63C
	lsr	r6, r4, #0xc                           @ 080CE640
	b	.L080CE518                               @ 080CE644
.L080CE648:
	add	r3, r3, ip                             @ 080CE648
	mov	ip, #0                                 @ 080CE64C
	mov	sl, r0                                 @ 080CE650
	and	r4, r4, fp                             @ 080CE654
	lsr	r6, r4, #0xc                           @ 080CE658
	b	.L080CE538                               @ 080CE65C
.Llit080CE660:
	.word	0x080CE160                           @ 080CE660
.Llit080CE664:
	.word	0x080CE3F0                           @ 080CE664
@ --------------------------------------------------------------------------
@ gmpWaitVCountLeave(n) / gmpWaitVCount(n)  (0x080CE668, 0x080CE67C)
@   while (REG_VCOUNT == n) ;  /  while (REG_VCOUNT != n) ;   -- correct in v1 (register 0x04000006).
@   The game's DMA start (0x0800DD60) calls the first with 0x3E and 0x3D.
@ --------------------------------------------------------------------------
	.thumb
	.thumb_func
	.global gmpWaitVCountLeave
gmpWaitVCountLeave:
	push	{r0, r1, r2, r3, r4, r5, r6, r7}      @ 080CE668
	ldr	r5, .Llit080CE66C                      @ 080CE66A  =0x0000E001
.Llit080CE66C:
	.word	0x0000E001                           @ 080CE66C
	.word	0x88E90400, 0xD0FC4281, 0x4770BCFF   @ 080CE670
	.thumb_func
	.global gmpWaitVCount
gmpWaitVCount:
	push	{r0, r1, r2, r3, r4, r5, r6, r7}      @ 080CE67C
	ldr	r5, .Llit080CE680                      @ 080CE67E  =0x0000E001
.Llit080CE680:
	.word	0x0000E001                           @ 080CE680
	.word	0x88E90400, 0xD1FC4281, 0x4770BCFF   @ 080CE684
@ --------------------------------------------------------------------------
@ gmpCallR2 / gmpDmaRestart(buffer)  (0x080CE690, 0x080CE694)
@   bx r2 veneer, and the ARM routine it reaches in Pinball: DMA1CNT_H = 0; DMA1SAD = buffer;
@   DMA1CNT_H = 0xB600.  v1 plays one FIFO only.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpCallR2
gmpCallR2:
	bx	r2                                      @ 080CE690
	.hword	0x0000                              @ 080CE692  (padding)
	.arm
	.global gmpDmaRestart
gmpDmaRestart:
	push	{r0, r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 080CE694
	mov	r5, #0x4000000                         @ 080CE698
	mov	r4, #0                                 @ 080CE69C
	mov	r6, #0xb600                            @ 080CE6A0
	strh	r4, [r5, #0xc6]                       @ 080CE6A4
	str	r0, [r5, #0xbc]                        @ 080CE6A8
	strh	r6, [r5, #0xc6]                       @ 080CE6AC
	pop	{r0, r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 080CE6B0
	bx	lr                                      @ 080CE6B4
@ --------------------------------------------------------------------------
@ gmpCallR3c / gmpRleFill  (0x080CE6B8, 0x080CE6BC)
@   Same RLE window fill as v3's gmpRleFill; Pinball's own code uses it (0x08001376).
@ --------------------------------------------------------------------------
	.thumb
	.thumb_func
	.global gmpCallR3c
gmpCallR3c:
	bx	r3                                      @ 080CE6B8
	.hword	0x0000                              @ 080CE6BA  (padding)
	.arm
	.global gmpRleFill
gmpRleFill:
	push	{r0, r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 080CE6BC
	mov	fp, #0                                 @ 080CE6C0
	mov	r5, #0                                 @ 080CE6C4
	mov	r8, r2                                 @ 080CE6C8
	add	r8, r2, #0x11                          @ 080CE6CC
	ldrb	r3, [r0], #1                          @ 080CE6D0
.L080CE6D4:
	cmp	r3, fp                                 @ 080CE6D4
	beq	.L080CE748                             @ 080CE6D8
	ldrb	r4, [r0], #1                          @ 080CE6DC
	cmp	r4, fp                                 @ 080CE6E0
	beq	.L080CE730                             @ 080CE6E4
	add	r6, r5, r3                             @ 080CE6E8
	cmp	r2, r6                                 @ 080CE6EC
	bge	.L080CE730                             @ 080CE6F0
	cmp	r2, r5                                 @ 080CE6F4
	blt	sub_080CE70C                           @ 080CE6F8
	sub	r7, r2, r5                             @ 080CE6FC
	add	r1, r1, r7                             @ 080CE700
	sub	r3, r3, r7                             @ 080CE704
	mov	r5, r2                                 @ 080CE708
	.global sub_080CE70C
sub_080CE70C:
	cmp	r6, r8                                 @ 080CE70C
	blt	sub_080CE71C                           @ 080CE710
	sub	sl, r6, r8                             @ 080CE714
	sub	r3, r3, sl                             @ 080CE718
	.global sub_080CE71C
sub_080CE71C:
	mov	sb, r3                                 @ 080CE71C
.L080CE720:
	strb	r4, [r1], #1                          @ 080CE720
	subs	sb, sb, #1                            @ 080CE724
	bne	.L080CE720                             @ 080CE728
	sub	r1, r1, r3                             @ 080CE72C
.L080CE730:
	add	r1, r1, r3                             @ 080CE730
	add	r5, r5, r3                             @ 080CE734
	cmp	r5, r8                                 @ 080CE738
	bge	.L080CE748                             @ 080CE73C
	ldrb	r3, [r0], #1                          @ 080CE740
	b	.L080CE6D4                               @ 080CE744
.L080CE748:
	pop	{r0, r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 080CE748
	bx	lr                                      @ 080CE74C
@ --------------------------------------------------------------------------
@ swiLZ77UnCompWram / swiLZ77UnCompVram  (0x080CE750, 0x080CE754)
@   SWI 0x11 / 0x12 stubs (v3 has the same pair).
@ --------------------------------------------------------------------------
	.thumb
	.thumb_func
	.global swiLZ77UnCompWram
swiLZ77UnCompWram:
	svc	#0x11                                  @ 080CE750
	bx	lr                                      @ 080CE752
	.thumb_func
	.global swiLZ77UnCompVram
swiLZ77UnCompVram:
	svc	#0x12                                  @ 080CE754
	bx	lr                                      @ 080CE756
