@ ============================================================================
@ gbamod3_arm.s -- GBAModPlay version 3, ARM/assembler module
@ Reconstructed from NFSU2 ROM range 0x08141300-0x081418DB (1 499 bytes).
@
@ Holds the BIOS stubs, the DMA restart routine and the two mixers.  The mixers are stored
@ LZ77-compressed (BIOS format 0x10) and unpacked into IWRAM by gmpUnpackMixer:
@     gmpMixerMonoLZ  -> 160 bytes   source: gbamod3_mixer_mono.s   (mixer mode 0, NFSU2)
@     gmpMixerMultiLZ -> 1004 bytes  source: gbamod3_mixer_multi.s  (mixer mode 1)
@ The packed images are included with .incbin; gbamod3.mk also rebuilds the unpacked mixers
@ from source and compares them with the decompressed images (lz77check.py).
@ ============================================================================
	.equ	gmpState, 0x030065D0
	.syntax unified
	.cpu arm7tdmi


	.section .text.gmp3_arm, "ax", %progbits
	.balign 4
@ --------------------------------------------------------------------------
@ swiDiv / swiDivArm / swiMod / swiModArm  (0x08141300-0x08141313)
@   Thumb BIOS call stubs: SWI 6 Div (r0/r1), SWI 7 DivArm (r1/r0), SWI 6 returning r1 (mod).
@   Only swiDiv and swiMod are called.
@ --------------------------------------------------------------------------
	.thumb
	.thumb_func
	.global swiDiv
swiDiv:
	svc	#6                                     @ 08141300
	bx	lr                                      @ 08141302
	.thumb_func
	.global swiDivArm
swiDivArm:
	svc	#7                                     @ 08141304
	bx	lr                                      @ 08141306
	.thumb_func
	.global swiMod
swiMod:
	svc	#6                                     @ 08141308
	adds	r0, r1, #0                            @ 0814130A
	bx	lr                                      @ 0814130C
	.thumb_func
	.global swiModArm
swiModArm:
	svc	#7                                     @ 0814130E
	adds	r0, r1, #0                            @ 08141310
	bx	lr                                      @ 08141312
	.word	0x00000000, 0x00000000, 0x00000000   @ 08141314
@ --------------------------------------------------------------------------
@ gmpDmaRestartAB(buffer)  (0x08141320)
@   Thumb "bx pc" veneer into ARM.  Restarts both sound DMAs at `buffer`:
@     DMA1CNT_H = 0; DMA1SAD = buffer; DMA1CNT_H = 0xB600;  same for DMA2 (FIFO_B).
@   Called by gmpDmaRestart every frame; the DMA destination and Timer 0 stay as set up.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpDmaRestartAB
gmpDmaRestartAB:
	bx	pc                                      @ 08141320
	.hword	0x0000                              @ 08141322  (padding)
	.arm
	push	{r0, r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 08141324
	mov	r5, #0x4000000                         @ 08141328
	mov	r4, #0                                 @ 0814132C
	mov	r6, #0xb600                            @ 08141330
	strh	r4, [r5, #0xc6]                       @ 08141334  DMA1CNT_H = 0
	str	r0, [r5, #0xbc]                        @ 08141338  DMA1SAD = buffer
	strh	r6, [r5, #0xc6]                       @ 0814133C  DMA1CNT_H = 0xB600
	strh	r4, [r5, #0xd2]                       @ 08141340  DMA2CNT_H = 0
	str	r0, [r5, #0xc8]                        @ 08141344  DMA2SAD = buffer
	strh	r6, [r5, #0xd2]                       @ 08141348  DMA2CNT_H = 0xB600
	pop	{r0, r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 0814134C
	bx	lr                                      @ 08141350
	.word	0x00000000, 0x00000000, 0x00000000   @ 08141354
@ --------------------------------------------------------------------------
@ gmpCallR3  (0x08141360)
@   bx r3 -- Thumb code calls the IWRAM mixer with bl gmpCallR3 and r3 = ST_mixer.
@ --------------------------------------------------------------------------
	.thumb
	.thumb_func
	.global gmpCallR3
gmpCallR3:
	bx	r3                                      @ 08141360
	.hword	0x0000                              @ 08141362
	.word	0x00000000, 0x00000000, 0x00000000   @ 08141364
@ --------------------------------------------------------------------------
@ gmpDmaRestartA(buffer) / gmpDmaRestartB(buffer)  (0x08141370, 0x081413A0)  -- unused
@   Single-channel variants of gmpDmaRestartAB.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpDmaRestartA
gmpDmaRestartA:
	bx	pc                                      @ 08141370
	.hword	0x0000                              @ 08141372  (padding)
	.arm
	push	{r0, r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 08141374
	mov	r5, #0x4000000                         @ 08141378
	mov	r4, #0                                 @ 0814137C
	mov	r6, #0xb600                            @ 08141380
	strh	r4, [r5, #0xc6]                       @ 08141384
	str	r0, [r5, #0xbc]                        @ 08141388
	strh	r6, [r5, #0xc6]                       @ 0814138C
	pop	{r0, r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 08141390
	bx	lr                                      @ 08141394
	.word	0x00000000, 0x00000000               @ 08141398
	.thumb
	.thumb_func
	.global gmpDmaRestartB
gmpDmaRestartB:
	bx	pc                                      @ 081413A0
	.hword	0x0000                              @ 081413A2  (padding)
	.arm
	push	{r0, r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 081413A4
	mov	r5, #0x4000000                         @ 081413A8
	mov	r4, #0                                 @ 081413AC
	mov	r6, #0xb600                            @ 081413B0
	strh	r4, [r5, #0xd2]                       @ 081413B4
	str	r0, [r5, #0xc8]                        @ 081413B8
	strh	r6, [r5, #0xd2]                       @ 081413BC
	pop	{r0, r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 081413C0
	bx	lr                                      @ 081413C4
	.word	0x00000000, 0x00000000               @ 081413C8
@ --------------------------------------------------------------------------
@ gmpDmaRestartCur()  (0x081413D0)  -- unused
@   ARM code that starts with "bx pc": executed in ARM state that jumps to 0x081413D8 and skips
@   the push at 0x081413D4, so the pop at the end would unbalance the stack.  It reloads both
@   DMAs from (&ST_buf0)[ST_cur].  Nothing calls it.
@ --------------------------------------------------------------------------
	.global gmpDmaRestartCur
gmpDmaRestartCur:
	.word	0xE12FFF1F                           @ 081413D0  bx pc
	.global gmpDmaRestartCur_body
gmpDmaRestartCur_body:
	push	{r0, r1, r2, r3}                      @ 081413D4
	ldr	r0, .Llit081414C8                      @ 081413D8  =gmpState
	ldr	r0, [r0]                               @ 081413DC
	ldr	r1, [r0, #8]                           @ 081413E0
	ldr	r0, [r0, r1, lsl #2]                   @ 081413E4
	mov	r2, #0x4000000                         @ 081413E8
	mov	r1, #0                                 @ 081413EC
	mov	r3, #0xb600                            @ 081413F0
	strh	r1, [r2, #0xc6]                       @ 081413F4
	str	r0, [r2, #0xbc]                        @ 081413F8
	strh	r3, [r2, #0xc6]                       @ 081413FC
	strh	r1, [r2, #0xd2]                       @ 08141400
	str	r0, [r2, #0xc8]                        @ 08141404
	strh	r3, [r2, #0xd2]                       @ 08141408
	pop	{r0, r1, r2, r3}                       @ 0814140C
	bx	lr                                      @ 08141410
	.word	0x12345676, 0x12345676, 0x12345676   @ 08141414
.Llit08141420:
	.word	0x00000FFF                           @ 08141420
	.word	0x12345676                           @ 08141424
@ --------------------------------------------------------------------------
@ gmpMixerMonoOld  (0x08141428)  -- unused
@   Uncompressed older build of the mode-0 mixer (gbamod3_mixer_mono.s); identical except that
@   it loads 0xFFF from a literal where the packed version uses mvn fp, #0.  Runs from ROM if
@   called; nothing calls it.  The 0x12345676 words before it look like section markers.
@ --------------------------------------------------------------------------
	.global gmpMixerMonoOld
gmpMixerMonoOld:
	push	{r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 08141428
	stmdb	sp!, {r0}                            @ 0814142C
	ldr	sl, [r0, #0xc]                         @ 08141430
	tst	sl, sl                                 @ 08141434
	beq	.L081414A0                             @ 08141438
	ldr	sb, [r0, #0x18]                        @ 0814143C
	ldr	r3, [r0]                               @ 08141440
	ldr	r4, [r0, #4]                           @ 08141444
	ldr	r5, [r0, #8]                           @ 08141448
	ldr	fp, .Llit08141420                      @ 0814144C  =0x00000FFF
	ldr	ip, [r0, #0x10]                        @ 08141450
	ldr	r0, [r0, #0x14]                        @ 08141454
.L08141458:
	cmp	r4, sl                                 @ 08141458
	bge	.L081414AC                             @ 0814145C
.L08141460:
	asr	r6, r4, #0xc                           @ 08141460
	add	r4, r4, r5                             @ 08141464
	ldrsb	r7, [r3, r6]                         @ 08141468  sample = src[pos >> 12]
	ldrsb	r8, [r1]                             @ 0814146C
	mul	r7, sb, r7                             @ 08141470
	add	r7, r8, r7, asr #8                     @ 08141474  dst += sample * vol >> 8 (no clipping)
	strb	r7, [r1], #1                          @ 08141478
	subs	r2, r2, #1                            @ 0814147C
	bne	.L08141458                             @ 08141480
.L08141484:
	ldm	sp!, {r0}                              @ 08141484
	str	r3, [r0]                               @ 08141488
	str	r4, [r0, #4]                           @ 0814148C
	str	sl, [r0, #0xc]                         @ 08141490
	str	ip, [r0, #0x10]                        @ 08141494
	pop	{r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 08141498
	bx	lr                                      @ 0814149C
.L081414A0:
	ldm	sp!, {r0}                              @ 081414A0
	pop	{r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 081414A4
	bx	lr                                      @ 081414A8
.L081414AC:
	add	r3, r3, ip                             @ 081414AC
	mov	ip, #0                                 @ 081414B0
	sub	r4, r4, sl                             @ 081414B4
	mov	sl, r0                                 @ 081414B8
	tst	sl, sl                                 @ 081414BC
	beq	.L08141484                             @ 081414C0
	b	.L08141460                               @ 081414C4
.Llit081414C8:
	.word	gmpState                             @ 081414C8
@ --------------------------------------------------------------------------
@ gmpWaitVCountLeave(n) / gmpWaitVCount(n)  (0x081414CC, 0x081414DA)  -- unused
@   Correct scanline waits on REG_VCOUNT (0x04000000 + 6):
@     gmpWaitVCountLeave: while (VCOUNT == n) ;     gmpWaitVCount: while (VCOUNT != n) ;
@   The C code uses its own copies (gmpWaitLine / gmpWaitLineLeave), which read DISPCNT.
@ --------------------------------------------------------------------------
	.thumb
	.thumb_func
	.global gmpWaitVCountLeave
gmpWaitVCountLeave:
	push	{r0, r1, r5}                          @ 081414CC
	ldr	r5, .Llit081414E8                      @ 081414CE  =0x04000000
.L081414D0:
	ldrh	r1, [r5, #6]                          @ 081414D0
	cmp	r1, r0                                 @ 081414D2
	beq	.L081414D0                             @ 081414D4
	pop	{r0, r1, r5}                           @ 081414D6
	bx	lr                                      @ 081414D8
	.thumb_func
	.global gmpWaitVCount
gmpWaitVCount:
	push	{r0, r1, r5}                          @ 081414DA
	ldr	r5, .Llit081414E8                      @ 081414DC  =0x04000000
.L081414DE:
	ldrh	r1, [r5, #6]                          @ 081414DE
	cmp	r1, r0                                 @ 081414E0
	bne	.L081414DE                             @ 081414E2
	pop	{r0, r1, r5}                           @ 081414E4
	bx	lr                                      @ 081414E6
.Llit081414E8:
	.word	0x04000000                           @ 081414E8
@ --------------------------------------------------------------------------
@ gmpCallR3b / gmpRleFill  (0x081414EC, 0x081414F0)  -- unused
@   Another bx r3 veneer and an ARM routine that expands {count, value} byte runs into a
@   window [r2, r2+0x11) of a destination buffer (clipped).  Not referenced by the player.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpCallR3b
gmpCallR3b:
	bx	r3                                      @ 081414EC
	.hword	0x0000                              @ 081414EE  (padding)
	.arm
	.global gmpRleFill
gmpRleFill:
	push	{r0, r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 081414F0
	mov	fp, #0                                 @ 081414F4
	mov	r5, #0                                 @ 081414F8
	mov	r8, r2                                 @ 081414FC
	add	r8, r2, #0x11                          @ 08141500
	ldrb	r3, [r0], #1                          @ 08141504
.L08141508:
	cmp	r3, fp                                 @ 08141508
	beq	.L0814157C                             @ 0814150C
	ldrb	r4, [r0], #1                          @ 08141510
	cmp	r4, fp                                 @ 08141514
	beq	.L08141564                             @ 08141518
	add	r6, r5, r3                             @ 0814151C
	cmp	r2, r6                                 @ 08141520
	bge	.L08141564                             @ 08141524
	cmp	r2, r5                                 @ 08141528
	blt	sub_08141540                           @ 0814152C
	sub	r7, r2, r5                             @ 08141530
	add	r1, r1, r7                             @ 08141534
	sub	r3, r3, r7                             @ 08141538
	mov	r5, r2                                 @ 0814153C
	.global sub_08141540
sub_08141540:
	cmp	r6, r8                                 @ 08141540
	blt	sub_08141550                           @ 08141544
	sub	sl, r6, r8                             @ 08141548
	sub	r3, r3, sl                             @ 0814154C
	.global sub_08141550
sub_08141550:
	mov	sb, r3                                 @ 08141550
.L08141554:
	strb	r4, [r1], #1                          @ 08141554
	subs	sb, sb, #1                            @ 08141558
	bne	.L08141554                             @ 0814155C
	sub	r1, r1, r3                             @ 08141560
.L08141564:
	add	r1, r1, r3                             @ 08141564
	add	r5, r5, r3                             @ 08141568
	cmp	r5, r8                                 @ 0814156C
	bge	.L0814157C                             @ 08141570
	ldrb	r3, [r0], #1                          @ 08141574
	b	.L08141508                               @ 08141578
.L0814157C:
	pop	{r0, r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ 0814157C
	bx	lr                                      @ 08141580
@ --------------------------------------------------------------------------
@ swiLZ77UnCompWram / swiLZ77UnCompVram  (0x08141584, 0x08141588)
@   SWI 0x11 / 0x12 stubs.  gmpUnpackMixer uses the WRAM one.
@ --------------------------------------------------------------------------
	.thumb
	.thumb_func
	.global swiLZ77UnCompWram
swiLZ77UnCompWram:
	svc	#0x11                                  @ 08141584
	bx	lr                                      @ 08141586
	.thumb_func
	.global swiLZ77UnCompVram
swiLZ77UnCompVram:
	svc	#0x12                                  @ 08141588
	bx	lr                                      @ 0814158A

@ --------------------------------------------------------------------------
@ Packed mixers (BIOS LZ77, header 0x10 + 24-bit size)
@ --------------------------------------------------------------------------
	.global gmpMixerMonoLZ
gmpMixerMonoLZ:                                     @ 0814158C  unpacks to 0xA0 bytes
	.incbin	"gbamod3_mixer_mono.lz"
	.global gmpMixerMultiLZ
gmpMixerMultiLZ:                                    @ 08141634  unpacks to 0x3EC bytes
	.incbin	"gbamod3_mixer_multi.lz"
