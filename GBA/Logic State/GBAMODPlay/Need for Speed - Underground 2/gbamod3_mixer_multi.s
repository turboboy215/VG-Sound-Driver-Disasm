@ ============================================================================
@ gbamod3_mixer_multi.s -- GBAModPlay v3 all-channel mixer (mixer mode 1), ARM, 1004 bytes
@ Source of the image packed at gmpMixerMultiLZ (0x08141634).  Not used by NFSU2 (mode 0).
@
@ Entry: r0 = record list built by gmpMix, r1 = dst, r2 = count.  The list starts with 7 words
@ of scratch space, then one 5-word record per channel
@     { src pointer, volume, position fraction << 20, step fraction << 20, step integer }
@ and an end record whose volume is 0xFF and whose first word is the byte distance back to the
@ first record (the code does "sub r0, r0, r3" to rewind).  Volume 0 records are skipped.
@ Positions advance with adcs: the fraction carry goes into the pointer.
@
@   1. up to 3 samples one at a time until dst is word aligned
@   2. main loop, 16 output samples per pass: for every channel, 16 products are summed as
@      16-bit pairs in r6-r12 and sp (two samples per register; sp is used as a data register,
@      so an interrupt handler that runs on the user/system stack would crash); the high byte
@      of each 16-bit sum is packed and stored with stm r1!, {r6-r9}
@   3. the last partial group of 4/8/12 is done by patching the code: a branch from the
@      table at +0x3D0 is written into the unrolled loop and the stm is swapped for the
@      1-, 2- or 3-word store at +0x3E0; both are restored afterwards
@   4. the last count & 3 samples one at a time
@ Results are the sum >> 8, truncated to 8 bits (wraps, no clipping).  In the paired sums a
@ negative low half borrows from the high half, so odd samples can be off by one LSB.
@ Returns r0 = dst end.
@ ============================================================================
	.syntax unified
	.cpu arm7tdmi


	.section .text, "ax", %progbits
	.balign 4
	.arm
	.global gmpMixMulti
gmpMixMulti:
	push	{r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip, lr}@ +000
	cmp	r2, #0                                 @ +004
	beq	.Lm3B0                             @ +008
	add	r0, r0, #0x1c                          @ +00C  skip the 7 scratch words
	and	r6, r1, #3                             @ +010  dst & 3
	cmp	r6, #0                                 @ +014
	beq	.Lm088                             @ +018
	mov	r7, #4                                 @ +01C
	sub	r6, r7, r6                             @ +020
	cmp	r6, r2                                 @ +024
	movgt	r6, r2                               @ +028
	sub	r2, r2, r6                             @ +02C
.Lm030:
	mov	r7, #0                                 @ +030
.Lm034:
	ldr	r3, [r0], #4                           @ +034
	ldr	r4, [r0], #4                           @ +038
	ldr	r8, [r0], #4                           @ +03C
	ldr	sb, [r0], #4                           @ +040
	ldr	sl, [r0], #4                           @ +044
	cmp	r4, #0                                 @ +048
	beq	.Lm034                             @ +04C
	cmp	r4, #0xff                              @ +050
	beq	.Lm074                             @ +054
	ldrsb	lr, [r3]                             @ +058
	adcs	r8, r8, sb                            @ +05C
	adcs	r3, r3, sl                            @ +060
	mlane	r7, lr, r4, r7                       @ +064
	str	r3, [r0, #-0x14]                       @ +068
	str	r8, [r0, #-0xc]                        @ +06C
	b	.Lm034                               @ +070
.Lm074:
	lsr	r7, r7, #8                             @ +074
	strb	r7, [r1], #1                          @ +078
	sub	r0, r0, r3                             @ +07C
	subs	r6, r6, #1                            @ +080
	bgt	.Lm030                             @ +084
.Lm088:
	cmp	r2, #0                                 @ +088  aligned: set up the 16-sample passes
	beq	.Lm3B0                             @ +08C
	and	r6, r2, #3                             @ +090
	str	r6, [r0, #-0x14]                       @ +094
	sub	r2, r2, r6                             @ +098
	mov	lr, r2                                 @ +09C
	lsr	r2, r2, #4                             @ +0A0
	sub	lr, lr, r2, lsl #4                     @ +0A4
	str	sp, [r0, #-0x10]                       @ +0A8  save sp in the scratch area
	str	lr, [r0, #-0xc]                        @ +0AC
	mov	r6, #0                                 @ +0B0
	str	r6, [r0, #-8]                          @ +0B4
	str	r6, [r0, #-4]                          @ +0B8
	str	r1, [r0, #-0x18]                       @ +0BC
	sub	r2, r2, #1                             @ +0C0
	lsl	r2, r2, #0x18                          @ +0C4
	add	r2, r2, #0xff                          @ +0C8
	add	r2, r2, r2, lsl #16                    @ +0CC
	str	r2, [r0, #-0x1c]                       @ +0D0  scratch[-0x1C] = pass count << 24 | 0x00FF00FF mask
	lsr	lr, r2, #0x18                          @ +0D4
	and	lr, lr, #0xff                          @ +0D8
	cmp	lr, #0xff                              @ +0DC
	beq	.Lm2C0                             @ +0E0
.Lm0E4:
	mov	r6, #0                                 @ +0E4
	mov	r7, #0                                 @ +0E8
	mov	r8, #0                                 @ +0EC
	mov	sb, #0                                 @ +0F0
	mov	sl, #0                                 @ +0F4
	mov	fp, #0                                 @ +0F8
	mov	ip, #0                                 @ +0FC
	mov	sp, #0                                 @ +100
	ldr	r3, [r0], #4                           @ +104  next channel record
	ldr	r4, [r0], #4                           @ +108
	ldr	r1, [r0], #4                           @ +10C
	ldr	r5, [r0], #4                           @ +110
	ldr	r2, [r0], #4                           @ +114
	cmp	r4, #0                                 @ +118  volume 0: skip
	beq	.Lm248                             @ +11C
.Lm120:
	ldrsb	lr, [r3]                             @ +120
	mlane	r6, lr, r4, r6                       @ +124
	adcs	r1, r1, r5                            @ +128
	adcs	r3, r3, r2                            @ +12C
	ldrsb	lr, [r3]                             @ +130
	mlane	r7, lr, r4, r7                       @ +134
	adcs	r1, r1, r5                            @ +138
	adcs	r3, r3, r2                            @ +13C
	ldrsb	lr, [r3]                             @ +140
	.word	0xE00E049E                           @ +144  mul lr, lr, r4  (Rd == Rm: UNPREDICTABLE on ARMv4, fine on the ARM7TDMI; kept as .word so gas does not warn)
	add	r6, r6, lr, lsl #16                    @ +148
	adcs	r1, r1, r5                            @ +14C
	adcs	r3, r3, r2                            @ +150
	ldrsb	lr, [r3]                             @ +154
	.word	0xE00E049E                           @ +158  mul lr, lr, r4  (Rd == Rm: UNPREDICTABLE on ARMv4, fine on the ARM7TDMI; kept as .word so gas does not warn)
	add	r7, r7, lr, lsl #16                    @ +15C
	adcs	r1, r1, r5                            @ +160
	adcs	r3, r3, r2                            @ +164
	ldrsb	lr, [r3]                             @ +168
	mlane	r8, lr, r4, r8                       @ +16C
	adcs	r1, r1, r5                            @ +170
	adcs	r3, r3, r2                            @ +174
	ldrsb	lr, [r3]                             @ +178
	mlane	sb, lr, r4, sb                       @ +17C
	adcs	r1, r1, r5                            @ +180
	adcs	r3, r3, r2                            @ +184
	ldrsb	lr, [r3]                             @ +188
	.word	0xE00E049E                           @ +18C  mul lr, lr, r4  (Rd == Rm: UNPREDICTABLE on ARMv4, fine on the ARM7TDMI; kept as .word so gas does not warn)
	adds	r8, r8, lr, lsl #16                   @ +190
	adcs	r1, r1, r5                            @ +194
	adcs	r3, r3, r2                            @ +198
	ldrsb	lr, [r3]                             @ +19C
	.word	0xE00E049E                           @ +1A0  mul lr, lr, r4  (Rd == Rm: UNPREDICTABLE on ARMv4, fine on the ARM7TDMI; kept as .word so gas does not warn)
	add	sb, sb, lr, lsl #16                    @ +1A4
	adcs	r1, r1, r5                            @ +1A8
	adcs	r3, r3, r2                            @ +1AC
	ldrsb	lr, [r3]                             @ +1B0
	mlane	sl, lr, r4, sl                       @ +1B4
	adcs	r1, r1, r5                            @ +1B8
	adcs	r3, r3, r2                            @ +1BC
	ldrsb	lr, [r3]                             @ +1C0
	mlane	fp, lr, r4, fp                       @ +1C4
	adcs	r1, r1, r5                            @ +1C8
	adcs	r3, r3, r2                            @ +1CC
	ldrsb	lr, [r3]                             @ +1D0
	.word	0xE00E049E                           @ +1D4  mul lr, lr, r4  (Rd == Rm: UNPREDICTABLE on ARMv4, fine on the ARM7TDMI; kept as .word so gas does not warn)
	add	sl, sl, lr, lsl #16                    @ +1D8
	adcs	r1, r1, r5                            @ +1DC
	adcs	r3, r3, r2                            @ +1E0
	ldrsb	lr, [r3]                             @ +1E4
	.word	0xE00E049E                           @ +1E8  mul lr, lr, r4  (Rd == Rm: UNPREDICTABLE on ARMv4, fine on the ARM7TDMI; kept as .word so gas does not warn)
	add	fp, fp, lr, lsl #16                    @ +1EC
	adcs	r1, r1, r5                            @ +1F0
	adcs	r3, r3, r2                            @ +1F4
	ldrsb	lr, [r3]                             @ +1F8
	mlane	ip, lr, r4, ip                       @ +1FC
	adds	r1, r1, r5                            @ +200
	adcs	r3, r3, r2                            @ +204
	ldrsb	lr, [r3]                             @ +208
	mlane	sp, lr, r4, sp                       @ +20C
	adcs	r1, r1, r5                            @ +210
	adcs	r3, r3, r2                            @ +214
	ldrsb	lr, [r3]                             @ +218
	.word	0xE00E049E                           @ +21C  mul lr, lr, r4  (Rd == Rm: UNPREDICTABLE on ARMv4, fine on the ARM7TDMI; kept as .word so gas does not warn)
	add	ip, ip, lr, lsl #16                    @ +220
	adds	r1, r1, r5                            @ +224
	adcs	r3, r3, r2                            @ +228
	ldrsb	lr, [r3]                             @ +22C
	.word	0xE00E049E                           @ +230  mul lr, lr, r4  (Rd == Rm: UNPREDICTABLE on ARMv4, fine on the ARM7TDMI; kept as .word so gas does not warn)
	add	sp, sp, lr, lsl #16                    @ +234
	adcs	r1, r1, r5                            @ +238
	adcs	r3, r3, r2                            @ +23C
	str	r3, [r0, #-0x14]                       @ +240
	str	r1, [r0, #-0xc]                        @ +244
.Lm248:
	ldr	r3, [r0], #4                           @ +248
	ldr	r4, [r0], #4                           @ +24C
	ldr	r1, [r0], #4                           @ +250
	ldr	r5, [r0], #4                           @ +254
	ldr	r2, [r0], #4                           @ +258
	cmp	r4, #0                                 @ +25C
	beq	.Lm248                             @ +260
	cmp	r4, #0xff                              @ +264  volume 0xFF: end record
	beq	.Lm270                             @ +268
	b	.Lm120                               @ +26C
.Lm270:
	sub	r0, r0, r3                             @ +270  rewind to the first record
	ldr	r2, [r0, #-0x1c]                       @ +274  mask 0x00FF00FF
	and	r6, r2, r6, lsr #8                     @ +278
	and	r7, r2, r7, lsr #8                     @ +27C
	add	r6, r6, r7, lsl #8                     @ +280
	and	r8, r2, r8, lsr #8                     @ +284
	and	sb, r2, sb, lsr #8                     @ +288
	add	r7, r8, sb, lsl #8                     @ +28C
	and	sl, r2, sl, lsr #8                     @ +290
	and	fp, r2, fp, lsr #8                     @ +294
	add	r8, sl, fp, lsl #8                     @ +298
	and	ip, r2, ip, lsr #8                     @ +29C
	and	sp, r2, sp, lsr #8                     @ +2A0
	add	sb, ip, sp, lsl #8                     @ +2A4
	ldr	r1, [r0, #-0x18]                       @ +2A8
	stm	r1!, {r6, r7, r8, sb}                  @ +2AC  store 16 samples
	str	r1, [r0, #-0x18]                       @ +2B0
	subs	r2, r2, #0x1000000                    @ +2B4  next pass
	str	r2, [r0, #-0x1c]                       @ +2B8
	bgt	.Lm0E4                             @ +2BC
.Lm2C0:
	ldr	lr, [r0, #-0xc]                        @ +2C0
	cmp	lr, #0                                 @ +2C4
	bne	.Lm348                             @ +2C8
	ldr	r6, [r0, #-0x14]                       @ +2CC
	cmp	r6, #0                                 @ +2D0
	beq	.Lm330                             @ +2D4
.Lm2D8:
	mov	r7, #0                                 @ +2D8
.Lm2DC:
	ldr	r3, [r0], #4                           @ +2DC
	ldr	r4, [r0], #4                           @ +2E0
	ldr	r8, [r0], #4                           @ +2E4
	ldr	sb, [r0], #4                           @ +2E8
	ldr	sl, [r0], #4                           @ +2EC
	cmp	r4, #0                                 @ +2F0
	beq	.Lm2DC                             @ +2F4
	cmp	r4, #0xff                              @ +2F8
	beq	.Lm31C                             @ +2FC
	ldrsb	lr, [r3], #1                         @ +300
	adcs	r8, r8, sb                            @ +304
	adcs	r3, r3, sl                            @ +308
	mlane	r7, lr, r4, r7                       @ +30C
	str	r3, [r0, #-0x14]                       @ +310
	str	r8, [r0, #-0xc]                        @ +314
	b	.Lm2DC                               @ +318
.Lm31C:
	lsr	r7, r7, #8                             @ +31C
	strb	r7, [r1], #1                          @ +320
	sub	r0, r0, r3                             @ +324
	subs	r6, r6, #1                            @ +328
	bgt	.Lm2D8                             @ +32C
.Lm330:
	ldr	lr, [r0, #-8]                          @ +330
	cmp	lr, #0                                 @ +334
	beq	.Lm39C                             @ +338
	ldr	ip, [r0, #-4]                          @ +33C
	str	lr, [ip]                               @ +340
	b	.Lm39C                               @ +344
.Lm348:
	mov	r2, #0xff                              @ +348  patch the loop for the last 4/8/12 samples
	add	r2, r2, r2, lsl #16                    @ +34C
	mov	sl, pc                                 @ +350
	add	r8, pc, #0x60                          @ +354
	lsr	lr, lr, #2                             @ +358
	add	r6, r8, lr, lsl #2                     @ +35C
	ldr	fp, [r6]                               @ +360
	sub	sb, sl, fp                             @ +364
	ldr	fp, [r6, #0x10]                        @ +368
	ldr	r7, [sb]                               @ +36C
	str	fp, [sb]                               @ +370
	str	r7, [r0, #-8]                          @ +374
	str	sb, [r0, #-4]                          @ +378
	add	r8, r8, #0x20                          @ +37C
	add	r6, r8, lr, lsl #2                     @ +380
	ldr	r7, [r6]                               @ +384
	sub	sb, pc, #0xe4                          @ +388
	str	r7, [sb]                               @ +38C
	mov	lr, #0                                 @ +390
	str	lr, [r0, #-0xc]                        @ +394
	b	.Lm0E4                               @ +398
.Lm39C:
	add	r8, pc, #0x38                          @ +39C  restore the 4-word stm
	sub	sb, pc, #0xfc                          @ +3A0
	ldr	r7, [r8]                               @ +3A4
	str	r7, [sb]                               @ +3A8
	ldr	sp, [r0, #-0x10]                       @ +3AC  restore sp
.Lm3B0:
	mov	r0, r1                                 @ +3B0
	pop	{r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip, lr}@ +3B4
	bx	lr                                      @ +3B8
gmpMixMultiTailOfs:
	.word	0x00000000, 0x000001F0, 0x000001A8, 0x00000160@ +3BC  tail offsets (patch position per remainder)
	.word	0x00000000                           @ +3CC
gmpMixMultiBranchTab:
	.word	0xEA000034, 0xEA000022, 0xEA000010   @ +3D0  branch templates written into the unrolled loop for a 4/8/12-sample tail
gmpMixMultiStoreTab:
	.word	0xE8A103C0, 0xE4816004, 0xE8A100C0, 0xE8A101C0@ +3DC  store templates: stm {r6-r9} / str r6 / stm {r6,r7} / stm {r6-r8}
