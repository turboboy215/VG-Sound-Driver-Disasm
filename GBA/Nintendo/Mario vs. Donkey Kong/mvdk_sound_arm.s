@ ===========================================================================
@  mvdk_sound_arm.s  -  Mario vs. Donkey Kong (E) sound driver, ARM part
@  Module A: ROM 0x0800023C-0x080003D0 (in the crt0 area). sndInit copies its first
@            0xE8 bytes to SndState+0xB50 (IWRAM): Clear32, Downmix, DmaIrq.
@  Module B: ROM 0x08001840-0x08001BA4. sndInit copies 0x390 bytes (this plus 0x2C bytes
@            of the following, unrelated Thumb code) to SndState+0xC38: MixSpan, MixChannel.
@  Both only ever run from the RAM copies (called through the gSnd*Fn pointers).
@ ===========================================================================
	.include "mvdk_sound.inc"
	.syntax unified
	.section .snd_arm_a, "ax", %progbits
	.arm

@ ============================================================================
@ void sndArmA_Clear32(u32 *p, int nWords)     runs from RAM (gSndClearFn); nWords multiple of 4
@ ============================================================================
	arm_func_start sndArmA_Clear32
sndArmA_Clear32: @ 0x0800023C
	add r1, r0, r1, lsl #2               @ 0800023C
	mov r2, #0                           @ 08000240
.L08000244:
	str r2, [r0], #4                     @ 08000244
	str r2, [r0], #4                     @ 08000248
	str r2, [r0], #4                     @ 0800024C
	str r2, [r0], #4                     @ 08000250
	cmp r0, r1                           @ 08000254
	bne .L08000244                       @ 08000258
	bx lr                                @ 0800025C

@ ============================================================================
@ void sndArmA_Downmix(s16 *mix, s8 *left, s8 *right, int n)     runs from RAM (gSndDownmixFn)
@   for (i = 0; i < n; i++) { left[i] = clamp(mix[2*i], -127, 127); right[i] = clamp(mix[2*i+1], -127, 127); }
@ ============================================================================
	arm_func_start sndArmA_Downmix
sndArmA_Downmix: @ 0x08000260
	add r3, r0, r3, lsl #2               @ 08000260
.L08000264:
	ldrsh ip, [r0], #2                   @ 08000264
	cmn ip, #0x7f                        @ 08000268
	mvnle ip, #0x7e                      @ 0800026C
	cmp ip, #0x7f                        @ 08000270
	movge ip, #0x7f                      @ 08000274
	strb ip, [r1], #1                    @ 08000278
	ldrsh ip, [r0], #2                   @ 0800027C
	cmn ip, #0x7f                        @ 08000280
	mvnle ip, #0x7e                      @ 08000284
	cmp ip, #0x7f                        @ 08000288
	movge ip, #0x7f                      @ 0800028C
	strb ip, [r2], #1                    @ 08000290
	cmp r0, r3                           @ 08000294
	blt .L08000264                       @ 08000298
	bx lr                                @ 0800029C

@ ============================================================================
@ void sndArmA_DmaIrq(void)                   runs from RAM (gSndDmaIrqFn), every 16 samples (DMA1 IRQ)
@   s = gSnd;
@   if (--s->irqCount > 0) return;
@   DMA1CNT = DMA2CNT = 0;
@   s->playBuf = s->nextBuf;
@   DMA1SAD = s->buffers[s->nextBuf].L; DMA2SAD = s->buffers[s->nextBuf].R;
@   DMA1CNT = DMA2CNT = 0xF6600004;
@   s->irqCount = 18; s->flags |= 2;
@ ============================================================================
	arm_func_start sndArmA_DmaIrq
sndArmA_DmaIrq: @ 0x080002A0
	ldr r0, .Lp08000314                  @ 080002A0
	ldr r0, [r0]                         @ 080002A4
	ldrb r1, [r0, #2]                    @ 080002A8
	subs r1, r1, #1                      @ 080002AC
	strb r1, [r0, #2]                    @ 080002B0
	bxgt lr                              @ 080002B4
	mov r2, #0x4000000                   @ 080002B8
	mov r3, #0                           @ 080002BC
	str r3, [r2, #0xc4]                  @ 080002C0
	str r3, [r2, #0xd0]                  @ 080002C4
	ldrb r1, [r0, #7]                    @ 080002C8
	strb r1, [r0, #6]                    @ 080002CC
	mov ip, #0x240                       @ 080002D0
	add r3, r0, #0x10                    @ 080002D4
	mla r1, ip, r1, r3                   @ 080002D8
	str r1, [r2, #0xbc]                  @ 080002DC
	add r1, r1, #0x120                   @ 080002E0
	str r1, [r2, #0xc8]                  @ 080002E4
	mov r1, #0xf6000000                  @ 080002E8
	orr r1, r1, #0x600000                @ 080002EC
	orr r1, r1, #4                       @ 080002F0
	str r1, [r2, #0xc4]                  @ 080002F4
	str r1, [r2, #0xd0]                  @ 080002F8
	mov r3, #0x12                        @ 080002FC
	strb r3, [r0, #2]                    @ 08000300
	ldrb r3, [r0, #1]                    @ 08000304
	orr r3, r3, #2                       @ 08000308
	strb r3, [r0, #1]                    @ 0800030C
	bx lr                                @ 08000310
.Lp08000314:	.word gSnd

@ ============================================================================
@ void sndArmA_OldMixSpan(OldMixArgs *a)      [unused; only its first 3 instructions are copied to RAM]
@ An older version of sndArmB_MixSpan: 8-bit position fraction, volumes >> 7, forward loops only.
@   {dst, src, pos, step, end, loopLen, volL, volR, n} = *a; mixes n stereo samples; a->pos = pos;
@ ============================================================================
	arm_func_start sndArmA_OldMixSpan
sndArmA_OldMixSpan: @ 0x08000318
	push {r3, r4, r5, r6, r7, r8, sb, sl, fp, ip} @ 08000318
	mov ip, r0                           @ 0800031C
	ldm ip, {r0, r1, r2, r3, r4, r5, r6, r7, fp} @ 08000320
	mla sb, r3, fp, r2                   @ 08000324
	add r8, r0, fp, lsl #2               @ 08000328
	cmp sb, r4                           @ 0800032C
	bge .L0800036C                       @ 08000330
.L08000334:
	lsr r5, r2, #8                       @ 08000334
	ldrsb sl, [r1, r5]                   @ 08000338
	ldrsh r5, [r0]                       @ 0800033C
	mul r4, r6, sl                       @ 08000340
	add r5, r5, r4, asr #7               @ 08000344
	strh r5, [r0], #2                    @ 08000348
	ldrsh r5, [r0]                       @ 0800034C
	mul r4, r7, sl                       @ 08000350
	add r5, r5, r4, asr #7               @ 08000354
	strh r5, [r0], #2                    @ 08000358
	add r2, r2, r3                       @ 0800035C
	cmp r0, r8                           @ 08000360
	blt .L08000334                       @ 08000364
	b .L080003C4                         @ 08000368
.L0800036C:
	orr r5, r5, r8, lsl #1               @ 0800036C
	cmp r2, r4                           @ 08000370
	bge .L080003AC                       @ 08000374
.L08000378:
	lsr sb, r2, #8                       @ 08000378
	ldrsb sl, [r1, sb]                   @ 0800037C
	ldrsh sb, [r0]                       @ 08000380
	mul r8, r6, sl                       @ 08000384
	add sb, sb, r8, asr #7               @ 08000388
	strh sb, [r0], #2                    @ 0800038C
	ldrsh sb, [r0]                       @ 08000390
	mul r8, r7, sl                       @ 08000394
	add sb, sb, r8, asr #7               @ 08000398
	strh sb, [r0], #2                    @ 0800039C
	add r2, r2, r3                       @ 080003A0
	cmp r2, r4                           @ 080003A4
	blt .L08000378                       @ 080003A8
.L080003AC:
	ands r8, r5, #1                      @ 080003AC
	beq .L080003C0                       @ 080003B0
	sub r2, r2, r4                       @ 080003B4
	lsr r8, r5, #1                       @ 080003B8
	b .L08000334                         @ 080003BC
.L080003C0:
	mov r2, r4                           @ 080003C0
.L080003C4:
	str r2, [ip, #8]                     @ 080003C4
	pop {r3, r4, r5, r6, r7, r8, sb, sl, fp, ip} @ 080003C8
	bx lr                                @ 080003CC

	.section .snd_arm_b, "ax", %progbits
	.arm

@ ============================================================================
@ void sndArmB_MixSpan(MixArgs *a)            runs from RAM (gSndMixSpanFn)
@ MixArgs: { s16 *dst; s8 *src; u32 pos; s32 step; u32 end; u32 loop; int n; int volL; int volR; }
@ pos/step/end are 18.14 fixed point; loop = loopLength << 1 | pingpong (0 = one-shot).
@   dstEnd = dst + 2 * n;
@   if (step >= 0 && pos + step * n < end)            // fast path, no end test
@       do { s = src[pos >> 14]; *dst++ += s * volL >> 6; *dst++ += s * volR >> 6; pos += step; } while (dst < dstEnd);
@   else loop with end test:
@       forward: at pos >= end: one-shot -> stop (rest of the span stays silent);
@                forward loop -> pos -= loopLength;
@                ping-pong -> pos = 2*end - pos; end -= loopLength; step = ~step; continue backwards
@       backward: at pos <= end (loop start): pos = 2*end - pos; end += loopLength; step = ~step
@   a->pos = pos; a->step = step;
@ Ping-pong bugs (no MvDK sample uses ping-pong loops): the backward loop reads src[pos >> 8] instead of
@ src[pos >> 14]; ~step is -step-1; and the direction is lost at the next call (step is recomputed).
@ ============================================================================
	arm_func_start sndArmB_MixSpan
sndArmB_MixSpan: @ 0x08001840
	push {r4, r5, r6, r7, r8, sb, sl, fp} @ 08001840
	mov ip, r0                           @ 08001844
	ldm ip, {r0, r1, r2, r3, r4, r5, r6, r7, r8} @ 08001848
	mla sl, r3, r6, r2                   @ 0800184C
	add r6, r0, r6, lsl #2               @ 08001850
	cmp r3, #0                           @ 08001854
	blt .L0800191C                       @ 08001858
	cmp sl, r4                           @ 0800185C
	bge .L080018C0                       @ 08001860
.L08001864:
	lsr sl, r2, #0xe                     @ 08001864
	ldrsb sb, [r1, sl]                   @ 08001868
	ldrsh sl, [r0]                       @ 0800186C
	mul fp, r7, sb                       @ 08001870
	add sl, sl, fp, asr #6               @ 08001874
	strh sl, [r0], #2                    @ 08001878
	ldrsh sl, [r0]                       @ 0800187C
	mul fp, r8, sb                       @ 08001880
	add sl, sl, fp, asr #6               @ 08001884
	strh sl, [r0], #2                    @ 08001888
	add r2, r2, r3                       @ 0800188C
	cmp r0, r6                           @ 08001890
	blt .L08001864                       @ 08001894
	b .L080018FC                         @ 08001898
.L0800189C:
	teq r5, #0                           @ 0800189C
	beq .L080018FC                       @ 080018A0
	tst r5, #1                           @ 080018A4
	subeq r2, r2, r5, asr #1             @ 080018A8
	beq .L080018C8                       @ 080018AC
	rsb r2, r2, r4, lsl #1               @ 080018B0
	sub r4, r4, r5, asr #1               @ 080018B4
	mvn r3, r3                           @ 080018B8
	b .L08001928                         @ 080018BC
.L080018C0:
	cmp r2, r4                           @ 080018C0
	bge .L0800189C                       @ 080018C4
.L080018C8:
	lsr sl, r2, #0xe                     @ 080018C8
	ldrsb sb, [r1, sl]                   @ 080018CC
	ldrsh sl, [r0]                       @ 080018D0
	mul fp, r7, sb                       @ 080018D4
	add sl, sl, fp, asr #6               @ 080018D8
	strh sl, [r0], #2                    @ 080018DC
	ldrsh sl, [r0]                       @ 080018E0
	mul fp, r8, sb                       @ 080018E4
	add sl, sl, fp, asr #6               @ 080018E8
	strh sl, [r0], #2                    @ 080018EC
	add r2, r2, r3                       @ 080018F0
	cmp r0, r6                           @ 080018F4
	blt .L080018C0                       @ 080018F8
.L080018FC:
	str r2, [ip, #8]                     @ 080018FC
	str r3, [ip, #0xc]                   @ 08001900
	pop {r4, r5, r6, r7, r8, sb, sl, fp} @ 08001904
	bx lr                                @ 08001908
.L0800190C:
	rsb r2, r2, r4, lsl #1               @ 0800190C
	add r4, r4, r5, asr #1               @ 08001910
	mvn r3, r3                           @ 08001914
	b .L080018C0                         @ 08001918
.L0800191C:
	sub r4, r4, r5, asr #1               @ 0800191C
	cmp sl, r4                           @ 08001920
	bgt .L08001864                       @ 08001924
.L08001928:
	cmp r2, r4                           @ 08001928
	ble .L0800190C                       @ 0800192C
	lsr sl, r2, #8                       @ 08001930
	ldrsb sb, [r1, sl]                   @ 08001934
	ldrsh sl, [r0]                       @ 08001938
	mul fp, r7, sb                       @ 0800193C
	add sl, sl, fp, asr #6               @ 08001940
	strh sl, [r0], #2                    @ 08001944
	ldrsh sl, [r0]                       @ 08001948
	mul fp, r8, sb                       @ 0800194C
	add sl, sl, fp, asr #6               @ 08001950
	strh sl, [r0], #2                    @ 08001954
	add r2, r2, r3                       @ 08001958
	cmp r0, r6                           @ 0800195C
	blt .L08001928                       @ 08001960
	b .L080018FC                         @ 08001964

@ ============================================================================
@ void sndArmB_MixChannel(MusChannel *c, s16 *mix, int n, int tickStart)   from RAM (gSndMixChannelFn)
@   S = c->smpPtr; period = c->period;
@   if (c->autoVib >= 0) {                                   // sample auto-vibrato (sweep is ignored)
@       period = clamp(period + (sndVibratoTables[0][S->vibType * 64 + (c->autoVib >> 2)] * S->vibDepth >> 16), 40, 7680);
@       if (tickStart) c->autoVib = (c->autoVib + S->vibRate) & 0xFF;
@   }
@   x = 7680 - period; o = sndOctaveTab[x >> 8];
@   step = sndLinearFreq[(x & 0xFF) | (o & 0x300)] * 4 >> (7 - (o & 15));   // Hz == step at 16384 Hz
@   vol = (c->vol * c->fade >> 16) * (c->volEnv.value >> 8) * c->mixVol >> 12;  vol = clamp(vol, 0, 64);
@   c->pan = pan = clamp(c->pan, 0, 64);
@   if (!S->loopType && c->pos >= S->length << 6) vol = 0;   // one-shot sample finished
@   if (!(c->voice & 1)) vol = 0;                            // no mixing voice
@   c->voice = c->voice & 1 | vol << 1;                      // loudness used by musAllocVoice
@   vol = vol * gMusVolume >> 7;
@   if (!vol) {                                              // silent: only advance the position
@       c->pos += step * n;
@       if (!S->loopType) c->pos = min(c->pos, S->length << 6);
@       else if (c->pos >= (S->loopStart + S->loopLen) << 6)
@           do c->pos -= S->loopLen << 6; while (c->pos >= S->loopStart + S->loopLen);   // compares
@       return;                                              // with the unshifted end (bug)
@   }
@   if (pan >= 0) { l = sndPanLaw[(64 - pan) * vol >> 5] >> 1; r = sndPanLaw[pan * vol >> 5] >> 1; }
@   else { l = vol; r = -vol; }                              // "surround" - dead, pan was clamped >= 0
@   MixArgs a = { mix, S->data, c->pos, step, (loopType ? loopStart + loopLen : length) << 6,
@                 loopType ? S->loopLen << 7 | (loopType != 1) : 0, n, l, r };
@   sndArmB_MixSpan(&a);                                     // direct BL, both run from RAM
@   c->dir = a.step >> 31; c->pos = a.pos;
@ ============================================================================
	arm_func_start sndArmB_MixChannel
sndArmB_MixChannel: @ 0x08001968
	push {r4, r5, r6, r7, r8, sb, sl, fp, lr} @ 08001968
	ldrsh r4, [r0, #0x26]                @ 0800196C
	ldr r5, [r0, #0x40]                  @ 08001970
	ldrsh sb, [r0, #0x46]                @ 08001974
	cmp sb, #0                           @ 08001978
	blt .L080019C8                       @ 0800197C
	ldr r6, .Lp08001B90                  @ 08001980
	ldrb r7, [r5, #0x28]                 @ 08001984
	lsr r8, sb, #2                       @ 08001988
	add r8, r8, r7, lsl #6               @ 0800198C
	ldrb r7, [r5, #0x2a]                 @ 08001990
	ldr r6, [r6, r8, lsl #2]             @ 08001994
	mul r6, r7, r6                       @ 08001998
	add r4, r4, r6, asr #16              @ 0800199C
	cmp r4, #0x28                        @ 080019A0
	movlt r4, #0x28                      @ 080019A4
	cmp r4, #0x1e00                      @ 080019A8
	movgt r4, #0x1e00                    @ 080019AC
	cmp r3, #0                           @ 080019B0
	beq .L080019C8                       @ 080019B4
	ldrb r7, [r5, #0x29]                 @ 080019B8
	add sb, sb, r7                       @ 080019BC
	and sb, sb, #0xff                    @ 080019C0
	strh sb, [r0, #0x46]                 @ 080019C4
.L080019C8:
	rsb r4, r4, #0x1e00                  @ 080019C8
	ldr r6, .Lp08001B94                  @ 080019CC
	lsr sb, r4, #8                       @ 080019D0
	ldr r6, [r6, sb, lsl #2]             @ 080019D4
	ldr r7, .Lp08001B98                  @ 080019D8
	and r8, r6, #0x300                   @ 080019DC
	and r4, r4, #0xff                    @ 080019E0
	orr r4, r4, r8                       @ 080019E4
	lsl r4, r4, #1                       @ 080019E8
	ldrh r4, [r7, r4]                    @ 080019EC
	and r6, r6, #0xf                     @ 080019F0
	rsb r6, r6, #7                       @ 080019F4
	lsl r4, r4, #2                       @ 080019F8
	lsr r4, r4, r6                       @ 080019FC
	mov r4, r4                           @ 08001A00
	ldrsb r6, [r0, #0x2c]                @ 08001A04
	ldrh r7, [r0, #0x30]                 @ 08001A08
	ldrb r8, [r0, #1]                    @ 08001A0C
	ldrsb sb, [r0, #0x2f]                @ 08001A10
	mul r6, r7, r6                       @ 08001A14
	asr r6, r6, #0x10                    @ 08001A18
	mul r6, r8, r6                       @ 08001A1C
	mul r6, sb, r6                       @ 08001A20
	asrs r6, r6, #0xc                    @ 08001A24
	movlt r6, #0                         @ 08001A28
	cmp r6, #0x40                        @ 08001A2C
	movgt r6, #0x40                      @ 08001A30
	ldrsb sb, [r0, #0x2d]                @ 08001A34
	cmp sb, #0                           @ 08001A38
	movlt sb, #0                         @ 08001A3C
	cmp sb, #0x40                        @ 08001A40
	movgt sb, #0x40                      @ 08001A44
	strb sb, [r0, #0x2d]                 @ 08001A48
	ldrb ip, [r5, #0xf]                  @ 08001A4C
	ldr r3, [r0, #0x20]                  @ 08001A50
	ldr r8, [r5]                         @ 08001A54
	mov sl, #2                           @ 08001A58
	cmp ip, #0                           @ 08001A5C
	subeq sl, sl, #1                     @ 08001A60
	cmp r3, r8, lsl #6                   @ 08001A64
	subge sl, sl, #1                     @ 08001A68
	cmp sl, #0                           @ 08001A6C
	moveq r6, #0                         @ 08001A70
	ldrb sl, [r0, #0x1d]                 @ 08001A74
	ands sl, sl, #1                      @ 08001A78
	moveq r6, #0                         @ 08001A7C
	orr sl, sl, r6, lsl #1               @ 08001A80
	strb sl, [r0, #0x1d]                 @ 08001A84
	ldr sl, .Lp08001B9C                  @ 08001A88
	ldr sl, [sl]                         @ 08001A8C
	mul r6, sl, r6                       @ 08001A90
	asrs r6, r6, #7                      @ 08001A94
	bne .L08001AD8                       @ 08001A98
	mla r3, r4, r2, r3                   @ 08001A9C
	cmp ip, #0                           @ 08001AA0
	bne .L08001AB4                       @ 08001AA4
	cmp r3, r8, lsl #6                   @ 08001AA8
	lslgt r3, r8, #6                     @ 08001AAC
	b .L08001B84                         @ 08001AB0
.L08001AB4:
	ldr r6, [r5, #8]                     @ 08001AB4
	ldr r7, [r5, #4]                     @ 08001AB8
	add r7, r7, r6                       @ 08001ABC
	cmp r3, r7, lsl #6                   @ 08001AC0
	blt .L08001B84                       @ 08001AC4
.L08001AC8:
	sub r3, r3, r6, lsl #6               @ 08001AC8
	cmp r3, r7                           @ 08001ACC
	bge .L08001AC8                       @ 08001AD0
	b .L08001B84                         @ 08001AD4
.L08001AD8:
	mov r7, r2                           @ 08001AD8
	mov r2, r5                           @ 08001ADC
	mov fp, r6                           @ 08001AE0
	cmp ip, #0                           @ 08001AE4
	bne .L08001AF8                       @ 08001AE8
	mov r5, r8                           @ 08001AEC
	mov r6, #0                           @ 08001AF0
	b .L08001B10                         @ 08001AF4
.L08001AF8:
	ldr r5, [r2, #4]                     @ 08001AF8
	ldr r6, [r2, #8]                     @ 08001AFC
	add r5, r5, r6                       @ 08001B00
	lsl r6, r6, #7                       @ 08001B04
	cmp ip, #1                           @ 08001B08
	orrne r6, r6, #1                     @ 08001B0C
.L08001B10:
	lsl r5, r5, #6                       @ 08001B10
	cmp sb, #0                           @ 08001B14
	blt .L08001B50                       @ 08001B18
	ldr sl, .Lp08001BA0                  @ 08001B1C
	rsb r8, sb, #0x40                    @ 08001B20
	mul r8, fp, r8                       @ 08001B24
	asr r8, r8, #5                       @ 08001B28
	lsl r8, r8, #1                       @ 08001B2C
	ldrh r8, [sl, r8]                    @ 08001B30
	mul sb, fp, sb                       @ 08001B34
	asr sb, sb, #5                       @ 08001B38
	lsl sb, sb, #1                       @ 08001B3C
	ldrh sb, [sl, sb]                    @ 08001B40
	asr r8, r8, #1                       @ 08001B44
	asr sb, sb, #1                       @ 08001B48
	b .L08001B58                         @ 08001B4C
.L08001B50:
	mov r8, fp                           @ 08001B50
	rsb sb, r8, #0                       @ 08001B54
.L08001B58:
	ldr r2, [r2, #0x2c]                  @ 08001B58
	push {r1, r2, r3, r4, r5, r6, r7, r8, sb} @ 08001B5C
	mov r4, r0                           @ 08001B60
	mov r0, sp                           @ 08001B64
	bl sndArmB_MixSpan                   @ 08001B68
	mov r0, r4                           @ 08001B6C
	ldr r3, [sp, #8]                     @ 08001B70
	ldr r4, [sp, #0xc]                   @ 08001B74
	asr r4, r4, #0x1f                    @ 08001B78
	strh r4, [r0, #0x1e]                 @ 08001B7C
	add sp, sp, #0x24                    @ 08001B80
.L08001B84:
	str r3, [r0, #0x20]                  @ 08001B84
	pop {r4, r5, r6, r7, r8, sb, sl, fp, lr} @ 08001B88
	bx lr                                @ 08001B8C
.Lp08001B90:	.word sndVibratoTables
.Lp08001B94:	.word sndOctaveTab
.Lp08001B98:	.word sndLinearFreq
.Lp08001B9C:	.word gMusVolume
.Lp08001BA0:	.word sndPanLaw
