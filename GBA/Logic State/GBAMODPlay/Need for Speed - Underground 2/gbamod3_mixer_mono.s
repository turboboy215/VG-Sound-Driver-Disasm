@ ============================================================================
@ gbamod3_mixer_mono.s -- GBAModPlay v3 per-channel mixer (mixer mode 0), ARM, 160 bytes
@ Source of the image packed at gmpMixerMonoLZ (0x0814158C).  gmpUnpackMixer unpacks it into
@ IWRAM; the code is position-independent.  Assemble at 0: the result equals the unpacked
@ bytes (checked by lz77check.py).
@
@ Entry (via gmpCallR3): r0 = GmpChannel*, r1 = dst (s8 samples), r2 = count
@   if (CH_end == 0) return;
@   for count samples: if (pos >= end) { ptr += loopStart; loopStart = 0; pos -= end;
@                                        end = loopLen; if (end == 0) stop }
@                      *dst++ += src[pos >> 12] * CH_vol >> 8;  pos += step
@   Stores ptr, pos, end, loopStart back into the channel.
@ The add wraps at 8 bits: nothing clips, so loud mixes overflow.
@ ============================================================================
	.syntax unified
	.cpu arm7tdmi


	.section .text, "ax", %progbits
	.balign 4
	.arm
	.global gmpMixMono
gmpMixMono:
	push	{r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ +000
	stmdb	sp!, {r0}                            @ +004
	ldr	sl, [r0, #0xc]                         @ +008  end
	tst	sl, sl                                 @ +00C  end == 0: channel finished
	beq	.Lm078                             @ +010
	ldr	sb, [r0, #0x18]                        @ +014  volume
	ldr	r3, [r0]                               @ +018  src
	ldr	r4, [r0, #4]                           @ +01C  pos (20.12)
	ldr	r5, [r0, #8]                           @ +020  step
	mvn	fp, #0                                 @ +024  fp = -1 (unused; the ROM copy loads 0xFFF here)
	ldr	ip, [r0, #0x10]                        @ +028  loopStart (bytes, applied once)
	ldr	r0, [r0, #0x14]                        @ +02C  loopLen << 12
.Lm030:
	cmp	r4, sl                                 @ +030  pos >= end ?
	bge	.Lm084                             @ +034
.Lm038:
	asr	r6, r4, #0xc                           @ +038
	add	r4, r4, r5                             @ +03C
	ldrsb	r7, [r3, r6]                         @ +040  sample
	ldrsb	r8, [r1]                             @ +044  dst sample
	mul	r7, sb, r7                             @ +048
	add	r7, r8, r7, asr #8                     @ +04C  dst += s * vol >> 8
	strb	r7, [r1], #1                          @ +050
	subs	r2, r2, #1                            @ +054
	bne	.Lm030                             @ +058
.Lm05C:
	ldm	sp!, {r0}                              @ +05C
	str	r3, [r0]                               @ +060
	str	r4, [r0, #4]                           @ +064
	str	sl, [r0, #0xc]                         @ +068
	str	ip, [r0, #0x10]                        @ +06C
	pop	{r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ +070
	bx	lr                                      @ +074
.Lm078:
	ldm	sp!, {r0}                              @ +078
	pop	{r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip}@ +07C
	bx	lr                                      @ +080
.Lm084:
	add	r3, r3, ip                             @ +084  wrap: src += loopStart
	mov	ip, #0                                 @ +088
	sub	r4, r4, sl                             @ +08C  pos -= end
	mov	sl, r0                                 @ +090  end = loopLen
	tst	sl, sl                                 @ +094  loopLen == 0: stop
	beq	.Lm05C                             @ +098
	b	.Lm038                               @ +09C
