@ --------------------------------------------------------------------------------------
@ sma4_sound.s - sound driver of Super Mario Advance 4 (E) v1.0, main program
@ Thumb code 080E8204-080EA7C8, ARM mixing loops 080EA7C8-080EAA80 (copied to IWRAM by sndInit).
@ Generated from the ROM by gen_sources.py; names and comments from the analysis.
@ The pseudo-C above each function describes the Super Mario Advance 4 build; where this
@ build differs, the difference is given after "In this build".
@ Rebuilds byte-identical: see Makefile.
@ --------------------------------------------------------------------------------------
	.syntax unified
	.include "nsnd.inc"
	.include "sma4_ram.inc"
	.section .snd_code, "ax"
	.thumb

@ ======================================================================================
@ sndInit   (080E8204)
@
@   void sndInit(const SndConfig *cfg)          /* the game calls this once at boot */
@   {
@       REG_SOUNDCNT_X = 0; REG_SOUNDCNT_X = 0x80;          /* reset all sound registers, master on */
@       REG_SOUNDCNT_L = 0xFF77;                           /* PSG 7/7 volume, ch1-4 on both sides   */
@       REG_SOUNDCNT_H_lo = 0x0D;                          /* PSG 50 %, FIFO A/B 100 %              */
@       REG_SOUNDBIAS = (REG_SOUNDBIAS & 0x3FFF) | 0x4000; /* 8-bit / 65.536 kHz PWM                */
@       REG_SOUND1CNT_L = 8;  REG_SOUND1CNT_H = 0xF000;    /* sweep off                             */
@       gCfg = cfg;
@       CpuFastSet(armDownmix, gIwramCode, 0xD8);          /* copy the three ARM loops to IWRAM     */
@       gFnDownmix  = gIwramCode;
@       gFnMixVoice = gIwramCode + (armMixVoice - armDownmix);
@       gFnEcho     = gIwramCode + (armEcho     - armDownmix);
@       gEchoHistory = (s16 *)0x02036000;                  /* 18 frames x 0x2C0 bytes in EWRAM       */
@       mixInit(gDmaBuffers);
@       cmdInit(); kitInstInit(); voiceInitAll(); trackInitAll(); playerInitAll();
@   }
@ ======================================================================================
	.global sndInit
	.thumb_func
sndInit:
	push	{r4, r5, lr}
	ldr	r1, .P080E8290	@ =gCfg
	str	r0, [r1]
	ldr	r1, .P080E8294	@ =REG_SOUNDCNT_X
	movs	r0, #0
	strb	r0, [r1]
	movs	r0, #0x80
	strb	r0, [r1]
	subs	r1, #4
	ldr	r2, .P080E8298	@ =0x0000FF77
	adds	r0, r2, #0
	strh	r0, [r1]
	adds	r1, #2
	movs	r0, #0xd
	strb	r0, [r1]
	ldr	r2, .P080E829C	@ =REG_SOUNDBIAS
	ldrh	r1, [r2]
	ldr	r0, .P080E82A0	@ =0x00003FFF
	ands	r0, r1
	movs	r3, #0x80
	lsls	r3, r3, #7
	adds	r1, r3, #0
	orrs	r0, r1
	strh	r0, [r2]
	ldr	r1, .P080E82A4	@ =REG_NR10
	movs	r0, #8
	strh	r0, [r1]
	adds	r1, #2
	movs	r2, #0xf0
	lsls	r2, r2, #8
	adds	r0, r2, #0
	strh	r0, [r1]
	ldr	r5, .P080E82A8	@ =armDownmix
	ldr	r4, .P080E82AC	@ =gIwramCode
	adds	r0, r5, #0
	adds	r1, r4, #0
	movs	r2, #0xd8
	bl	CpuFastSet
	ldr	r0, .P080E82B0	@ =gFnDownmix
	str	r4, [r0]
	ldr	r1, .P080E82B4	@ =gFnMixVoice
	ldr	r0, .P080E82B8	@ =armMixVoice
	subs	r0, r0, r5
	adds	r0, r0, r4
	str	r0, [r1]
	ldr	r1, .P080E82BC	@ =gFnEcho
	ldr	r0, .P080E82C0	@ =armEcho
	subs	r0, r0, r5
	adds	r0, r0, r4
	str	r0, [r1]
	ldr	r1, .P080E82C4	@ =gEchoHistory
	ldr	r0, .P080E82C8	@ =0x02036000
	str	r0, [r1]
	ldr	r0, .P080E82CC	@ =gDmaBuffers
	bl	mixInit
	bl	cmdInit
	bl	kitInstInit
	bl	voiceInitAll
	bl	trackInitAll
	bl	playerInitAll
	pop	{r4, r5}
	pop	{r0}
	bx	r0
.P080E8290:	.word gCfg
.P080E8294:	.word REG_SOUNDCNT_X
.P080E8298:	.word 0x0000FF77
.P080E829C:	.word REG_SOUNDBIAS
.P080E82A0:	.word 0x00003FFF
.P080E82A4:	.word REG_NR10
.P080E82A8:	.word armDownmix
.P080E82AC:	.word gIwramCode
.P080E82B0:	.word gFnDownmix
.P080E82B4:	.word gFnMixVoice
.P080E82B8:	.word armMixVoice
.P080E82BC:	.word gFnEcho
.P080E82C0:	.word armEcho
.P080E82C4:	.word gEchoHistory
.P080E82C8:	.word 0x02036000
.P080E82CC:	.word gDmaBuffers

@ ======================================================================================
@ sndVSync   (080E82D0)
@
@   void sndVSync(void)        /* the game calls this first thing in its V-blank handler */
@   {
@       mixDmaRestart();
@   }
@ ======================================================================================
	.global sndVSync
	.thumb_func
sndVSync:
	push	{lr}
	bl	mixDmaRestart
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ sndMain   (080E82DC)
@
@   void sndMain(void)          /* the game calls this once per frame, after sndVSync */
@   {
@       cmdProcess();           /* apply the commands queued by the snd* API          */
@       playerTickAll();        /* sequencer: fades, then every track of every player */
@       psgUpdate();            /* the four Game Boy channels                         */
@       if (gMixEnabled)
@           mixFrame();         /* render 176 samples into the buffer DMA plays next  */
@   }
@ ======================================================================================
	.global sndMain
	.thumb_func
sndMain:
	push	{lr}
	bl	cmdProcess
	bl	playerTickAll
	bl	psgUpdate
	ldr	r0, .P080E82FC	@ =gMixEnabled
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L080E82F6
	bl	mixFrame
.L080E82F6:
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080E82FC:	.word gMixEnabled

@ ======================================================================================
@ mixInit   (080E8300)
@
@   void mixInit(u8 *dmaBuf)    /* dmaBuf: 4 x 176 bytes */
@   {
@       gMixEnabled = 1;
@       CpuFastSet(&zero, gEchoHistory, FILL | 0xC60);     /* 18 x 0x2C0 bytes                      */
@       CpuFastSet(&zero, dmaBuf, FILL | 0xB0);
@       gDmaBufA[0] = dmaBuf;          gDmaBufB[0] = dmaBuf + 0xB0;
@       gDmaBufA[1] = dmaBuf + 0x160;  gDmaBufB[1] = dmaBuf + 0x210;
@       gTimerReload = 0xF9C4;                             /* 65536-1596: 16777216/1596 = 10512 Hz  */
@       gDmaBufIdx = 0;
@       REG_SOUNDCNT_H_hi = 0x9A;      /* FIFO A -> left, FIFO B -> right, both timer 0, reset both */
@       REG_FIFO_A = 0; REG_FIFO_B = 0;
@   }
@ ======================================================================================
	.global mixInit
	.thumb_func
mixInit:
	push	{r4, r5, lr}
	sub	sp, #0xc
	adds	r4, r0, #0
	ldr	r1, .P080E8368	@ =gMixEnabled
	movs	r0, #1
	strb	r0, [r1]
	movs	r5, #0
	str	r5, [sp, #4]
	add	r0, sp, #4
	ldr	r1, .P080E836C	@ =gEchoHistory
	ldr	r1, [r1]
	ldr	r2, .P080E8370	@ =0x01000C60
	bl	CpuFastSet
	str	r5, [sp, #8]
	add	r0, sp, #8
	ldr	r2, .P080E8374	@ =0x010000B0
	adds	r1, r4, #0
	bl	CpuFastSet
	ldr	r1, .P080E8378	@ =gDmaBufA
	str	r4, [r1]
	ldr	r2, .P080E837C	@ =gDmaBufB
	adds	r0, r4, #0
	adds	r0, #0xb0
	str	r0, [r2]
	movs	r3, #0xb0
	lsls	r3, r3, #1
	adds	r0, r4, r3
	str	r0, [r1, #4]
	movs	r0, #0x84
	lsls	r0, r0, #2
	adds	r4, r4, r0
	str	r4, [r2, #4]
	ldr	r1, .P080E8380	@ =gTimerReload
	ldr	r2, .P080E8384	@ =0x0000F9C4
	adds	r0, r2, #0
	strh	r0, [r1]
	ldr	r0, .P080E8388	@ =gDmaBufIdx
	strb	r5, [r0]
	ldr	r1, .P080E838C	@ =REG_SOUNDCNT_H+1
	movs	r0, #0x9a
	strb	r0, [r1]
	ldr	r0, .P080E8390	@ =REG_FIFO_A
	str	r5, [r0]
	adds	r0, #4
	str	r5, [r0]
	add	sp, #0xc
	pop	{r4, r5}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080E8368:	.word gMixEnabled
.P080E836C:	.word gEchoHistory
.P080E8370:	.word 0x01000C60
.P080E8374:	.word 0x010000B0
.P080E8378:	.word gDmaBufA
.P080E837C:	.word gDmaBufB
.P080E8380:	.word gTimerReload
.P080E8384:	.word 0x0000F9C4
.P080E8388:	.word gDmaBufIdx
.P080E838C:	.word REG_SOUNDCNT_H+1
.P080E8390:	.word REG_FIFO_A

@ ======================================================================================
@ mixDmaRestart   (080E8394)
@
@   void mixDmaRestart(void)    /* V-blank: restart DMA1/DMA2 on the buffer mixed last frame */
@   {
@       REG_TM0CNT = gTimerReload | TIMER_ENABLE;
@       if (!gMixEnabled) return;
@       REG_DMA1CNT_H &= 0xC5FF; REG_DMA1CNT_H &= 0x7FFF;  /* stop DMA1, clear repeat/timing bits  */
@       REG_DMA2CNT_H &= 0xC5FF; REG_DMA2CNT_H &= 0x7FFF;
@       REG_DMA1SAD = gDmaBufA[gDmaBufIdx]; REG_DMA1DAD = &REG_FIFO_A; REG_DMA1CNT = 0xB6400004;
@       REG_DMA2SAD = gDmaBufB[gDmaBufIdx]; REG_DMA2DAD = &REG_FIFO_B; REG_DMA2CNT = 0xB6400004;
@       gDmaBufIdx ^= 1;                                   /* mixFrame now fills the other half     */
@   }
@ ======================================================================================
	.global mixDmaRestart
	.thumb_func
mixDmaRestart:
	push	{r4, r5, lr}
	ldr	r2, .P080E8410	@ =REG_TM0CNT
	ldr	r0, .P080E8414	@ =gTimerReload
	ldrh	r0, [r0]
	movs	r1, #0x80
	lsls	r1, r1, #0x10
	orrs	r0, r1
	str	r0, [r2]
	ldr	r0, .P080E8418	@ =gMixEnabled
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L080E8408
	ldr	r4, .P080E841C	@ =REG_DMA1SAD
	ldrh	r1, [r4, #0xa]
	ldr	r2, .P080E8420	@ =0x0000C5FF
	adds	r0, r2, #0
	ands	r0, r1
	strh	r0, [r4, #0xa]
	ldrh	r3, [r4, #0xa]
	ldr	r1, .P080E8424	@ =0x00007FFF
	adds	r0, r1, #0
	ands	r0, r3
	strh	r0, [r4, #0xa]
	ldrh	r0, [r4, #0xa]
	ldr	r3, .P080E8428	@ =REG_DMA2SAD
	ldrh	r0, [r3, #0xa]
	ands	r2, r0
	strh	r2, [r3, #0xa]
	ldrh	r0, [r3, #0xa]
	ands	r1, r0
	strh	r1, [r3, #0xa]
	ldrh	r0, [r3, #0xa]
	ldr	r1, .P080E842C	@ =gDmaBufA
	ldr	r2, .P080E8430	@ =gDmaBufIdx
	ldrb	r0, [r2]
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r0, [r0]
	str	r0, [r4]
	ldr	r0, .P080E8434	@ =REG_FIFO_A
	str	r0, [r4, #4]
	ldr	r5, .P080E8438	@ =0xB6400004
	str	r5, [r4, #8]
	ldr	r0, [r4, #8]
	ldr	r1, .P080E843C	@ =gDmaBufB
	ldrb	r0, [r2]
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r0, [r0]
	str	r0, [r3]
	ldr	r0, .P080E8440	@ =REG_FIFO_B
	str	r0, [r3, #4]
	str	r5, [r3, #8]
	ldr	r0, [r3, #8]
	ldrb	r1, [r2]
	movs	r0, #1
	subs	r0, r0, r1
	strb	r0, [r2]
.L080E8408:
	pop	{r4, r5}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080E8410:	.word REG_TM0CNT
.P080E8414:	.word gTimerReload
.P080E8418:	.word gMixEnabled
.P080E841C:	.word REG_DMA1SAD
.P080E8420:	.word 0x0000C5FF
.P080E8424:	.word 0x00007FFF
.P080E8428:	.word REG_DMA2SAD
.P080E842C:	.word gDmaBufA
.P080E8430:	.word gDmaBufIdx
.P080E8434:	.word REG_FIFO_A
.P080E8438:	.word 0xB6400004
.P080E843C:	.word gDmaBufB
.P080E8440:	.word REG_FIFO_B

@ ======================================================================================
@ sndStopOutput   (080E8444)
@
@   void sndStopOutput(void)    /* stop mixing and DMA (the game calls it before e.g. saving) */
@   {
@       gMixEnabled = 0;
@       REG_DMA1CNT_H &= 0xC5FF; REG_DMA1CNT_H &= 0x7FFF;
@       REG_DMA2CNT_H &= 0xC5FF; REG_DMA2CNT_H &= 0x7FFF;
@   }
@ ======================================================================================
	.global sndStopOutput
	.thumb_func
sndStopOutput:
	push	{r4, lr}
	ldr	r1, .P080E847C	@ =gMixEnabled
	movs	r0, #0
	strb	r0, [r1]
	ldr	r1, .P080E8480	@ =REG_DMA1SAD
	ldrh	r2, [r1, #0xa]
	ldr	r3, .P080E8484	@ =0x0000C5FF
	adds	r0, r3, #0
	ands	r0, r2
	strh	r0, [r1, #0xa]
	ldrh	r4, [r1, #0xa]
	ldr	r2, .P080E8488	@ =0x00007FFF
	adds	r0, r2, #0
	ands	r0, r4
	strh	r0, [r1, #0xa]
	ldrh	r0, [r1, #0xa]
	ldr	r0, .P080E848C	@ =REG_DMA2SAD
	ldrh	r1, [r0, #0xa]
	ands	r3, r1
	strh	r3, [r0, #0xa]
	ldrh	r1, [r0, #0xa]
	ands	r2, r1
	strh	r2, [r0, #0xa]
	ldrh	r0, [r0, #0xa]
	pop	{r4}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080E847C:	.word gMixEnabled
.P080E8480:	.word REG_DMA1SAD
.P080E8484:	.word 0x0000C5FF
.P080E8488:	.word 0x00007FFF
.P080E848C:	.word REG_DMA2SAD

@ ======================================================================================
@ sndStartOutput   (080E8490)
@
@   void sndStartOutput(void)
@   {
@       gMixEnabled = 1;        /* DMA restarts at the next sndVSync */
@   }
@ ======================================================================================
	.global sndStartOutput
	.thumb_func
sndStartOutput:
	ldr	r1, .P080E8498	@ =gMixEnabled
	movs	r0, #1
	strb	r0, [r1]
	bx	lr
.P080E8498:	.word gMixEnabled

@ ======================================================================================
@ mixVoice   (080E849C)
@
@   /* Mix one frame (176 samples) of a sampled voice into gMixDry, or into gMixWet when the
@      echo is on and the voice's track has echo enabled.  Returns 1 when a one-shot sample
@      ended (the caller then frees the voice). */
@   u32 mixVoice(Voice *v, u32 vol, u32 step /* 24.8 */, u32 pan /* 0..127 */)
@   {
@       s16 *out = (gEchoShift < 16 && v->echo) ? gMixWet : gMixDry;
@       s16 *outEnd = out + 176;
@       u32  volL = (vol * (127 - pan)) >> 8 & 0xFF;       /* 8-bit gains                          */
@       u32  volR = (vol * pan) >> 8 & 0xFF;
@       u32  pos  = v->pos;                                /* 24.8 sample position                 */
@       u32  end  = v->sample->loopEnd ? v->sample->loopEnd : v->sample->length;
@       s16 *stop = outEnd;
@       int  hitEnd = end <= (pos + step * 176) >> 8;
@       if (hitEnd)                                        /* samples until the end is reached     */
@           stop = out + Div(end * 256 - pos - 1 + step, step);
@       if (!v->sample->loopEnd || !hitEnd) {
@           pos = gFnMixVoice(v->sample->pcm, out, out + 176, stop, pos, step, volL, volR);
@           if (hitEnd) return 1;                          /* one-shot sample finished             */
@       } else {
@           u32 loopLen = v->sample->loopEnd - v->sample->loopStart;
@           pos = gFnMixVoice(v->sample->pcm, out, out + 176, stop, pos, step, volL, volR) - loopLen * 256;
@           for (int left = 176 - (stop - out); left; ) {  /* keep wrapping until the frame is full */
@               out = stop;
@               int n = left; hitEnd = end <= (pos + left * step) >> 8;
@               if (hitEnd) n = Div(end * 256 - pos - 1 + step, step);
@               stop = out + n;
@               pos = gFnMixVoice(v->sample->pcm, out, out + 176, stop, pos, step, volL, volR);
@               if (hitEnd) pos -= loopLen * 256;
@               left -= stop - out;
@           }
@       }
@       v->pos = pos;
@       return 0;
@   }
@ ======================================================================================
	.global mixVoice
	.thumb_func
mixVoice:
	push	{r4, r5, r6, r7, lr}
	mov	r7, sl
	mov	r6, sb
	mov	r5, r8
	push	{r5, r6, r7}
	sub	sp, #0x28
	str	r0, [sp, #0x10]
	adds	r6, r2, #0
	lsls	r3, r3, #0x18
	lsrs	r3, r3, #0x18
	ldr	r4, [r0, #0x60]
	lsls	r1, r1, #0x10
	lsrs	r1, r1, #0x10
	mov	sl, r1
	mov	r0, sl
	str	r0, [sp, #0x18]
	movs	r1, #0
	mov	sb, r1
	movs	r2, #0xb0
	str	r2, [sp, #0x1c]
	ldr	r1, [sp, #0x10]
	ldr	r0, [r1, #0x5c]
	adds	r0, #0x10
	str	r0, [sp, #0x20]
	ldr	r2, .P080E8524	@ =gMixDry
	str	r2, [sp, #0x14]
	ldr	r0, .P080E8528	@ =gEchoShift
	ldrb	r0, [r0]
	cmp	r0, #0xf
	bhi	.L080E84E2
	ldrb	r0, [r1, #0x1a]
	cmp	r0, #0
	beq	.L080E84E2
	ldr	r0, .P080E852C	@ =gMixWet
	str	r0, [sp, #0x14]
.L080E84E2:
	ldr	r1, [sp, #0x14]
	movs	r2, #0xb0
	lsls	r2, r2, #1
	adds	r1, r1, r2
	mov	r8, r1
	movs	r0, #0x7f
	subs	r0, r0, r3
	ldr	r1, [sp, #0x18]
	muls	r0, r1, r0
	lsls	r0, r0, #0x10
	lsrs	r0, r0, #0x18
	str	r0, [sp, #0x18]
	mov	r0, sl
	muls	r0, r3, r0
	lsls	r0, r0, #0x10
	lsrs	r0, r0, #0x18
	mov	sl, r0
	ldr	r2, [sp, #0x10]
	ldr	r0, [r2, #0x5c]
	ldr	r7, [r0, #0xc]
	cmp	r7, #0
	bne	.L080E8510
	ldr	r7, [r0]
.L080E8510:
	ldr	r1, [sp, #0x1c]
	adds	r0, r6, #0
	muls	r0, r1, r0
	adds	r0, r4, r0
	lsrs	r0, r0, #8
	cmp	r0, r7
	bhs	.L080E8530
	mov	r5, r8
	b	.L080E8548
	.hword 0x0000
.P080E8524:	.word gMixDry
.P080E8528:	.word gEchoShift
.P080E852C:	.word gMixWet
.L080E8530:
	lsls	r0, r7, #8
	subs	r0, r0, r4
	subs	r0, #1
	adds	r0, r0, r6
	adds	r1, r6, #0
	bl	Div
	lsls	r0, r0, #1
	ldr	r2, [sp, #0x14]
	adds	r5, r2, r0
	movs	r0, #1
	mov	sb, r0
.L080E8548:
	ldr	r1, [sp, #0x10]
	ldr	r0, [r1, #0x5c]
	ldr	r1, [r0, #0xc]
	cmp	r1, #0
	beq	.L080E8558
	mov	r2, sb
	cmp	r2, #0
	bne	.L080E8584
.L080E8558:
	ldr	r0, .P080E8580	@ =gFnMixVoice
	str	r4, [sp]
	str	r6, [sp, #4]
	ldr	r1, [sp, #0x18]
	str	r1, [sp, #8]
	mov	r2, sl
	str	r2, [sp, #0xc]
	ldr	r4, [r0]
	ldr	r0, [sp, #0x20]
	ldr	r1, [sp, #0x14]
	mov	r2, r8
	adds	r3, r5, #0
	bl	_call_via_r4
	adds	r4, r0, #0
	mov	r0, sb
	cmp	r0, #0
	beq	.L080E8632
	movs	r0, #1
	b	.L080E8638
.P080E8580:	.word gFnMixVoice
.L080E8584:
	ldr	r0, [r0, #8]
	subs	r1, r1, r0
	lsls	r1, r1, #8
	str	r1, [sp, #0x24]
	ldr	r1, .P080E85E0	@ =gFnMixVoice
	str	r4, [sp]
	str	r6, [sp, #4]
	ldr	r2, [sp, #0x18]
	str	r2, [sp, #8]
	mov	r0, sl
	str	r0, [sp, #0xc]
	ldr	r4, [r1]
	ldr	r0, [sp, #0x20]
	ldr	r1, [sp, #0x14]
	mov	r2, r8
	adds	r3, r5, #0
	bl	_call_via_r4
	adds	r4, r0, #0
	ldr	r1, [sp, #0x24]
	subs	r4, r4, r1
	ldr	r2, [sp, #0x14]
	subs	r0, r5, r2
	asrs	r0, r0, #1
	ldr	r1, [sp, #0x1c]
	subs	r1, r1, r0
	str	r1, [sp, #0x1c]
	cmp	r1, #0
	beq	.L080E8632
.L080E85BE:
	str	r5, [sp, #0x14]
	movs	r2, #0xb0
	lsls	r2, r2, #1
	adds	r2, r2, r5
	mov	r8, r2
	ldr	r1, [sp, #0x1c]
	adds	r0, r6, #0
	muls	r0, r1, r0
	adds	r0, r4, r0
	lsrs	r0, r0, #8
	cmp	r0, r7
	bhs	.L080E85E4
	lsls	r0, r1, #1
	adds	r5, r5, r0
	movs	r2, #0
	mov	sb, r2
	b	.L080E85FA
.P080E85E0:	.word gFnMixVoice
.L080E85E4:
	lsls	r0, r7, #8
	subs	r0, r0, r4
	subs	r0, #1
	adds	r0, r0, r6
	adds	r1, r6, #0
	bl	Div
	lsls	r0, r0, #1
	adds	r5, r5, r0
	movs	r0, #1
	mov	sb, r0
.L080E85FA:
	str	r4, [sp]
	str	r6, [sp, #4]
	ldr	r1, [sp, #0x18]
	str	r1, [sp, #8]
	mov	r2, sl
	str	r2, [sp, #0xc]
	ldr	r0, .P080E8648	@ =gFnMixVoice
	ldr	r4, [r0]
	ldr	r0, [sp, #0x20]
	ldr	r1, [sp, #0x14]
	mov	r2, r8
	adds	r3, r5, #0
	bl	_call_via_r4
	adds	r4, r0, #0
	mov	r1, sb
	cmp	r1, #0
	beq	.L080E8622
	ldr	r2, [sp, #0x24]
	subs	r4, r4, r2
.L080E8622:
	ldr	r1, [sp, #0x14]
	subs	r0, r5, r1
	asrs	r0, r0, #1
	ldr	r2, [sp, #0x1c]
	subs	r2, r2, r0
	str	r2, [sp, #0x1c]
	cmp	r2, #0
	bne	.L080E85BE
.L080E8632:
	ldr	r0, [sp, #0x10]
	str	r4, [r0, #0x60]
	movs	r0, #0
.L080E8638:
	add	sp, #0x28
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	sb, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1
.P080E8648:	.word gFnMixVoice

@ ======================================================================================
@ kitInstInit   (080E864C)
@
@   void kitInstInit(void)      /* the RAM instrument used by type-0x11 "sample kit" instruments */
@   {
@       gKitInst.type = 0; gKitInst.flags = 0; gKitInst.data = 0;
@       gKitInst.envOfs = 0; gKitInst.release = 0; gKitInst.rootKey = 0x30;
@   }
@ ======================================================================================
	.global kitInstInit
	.thumb_func
kitInstInit:
	ldr	r1, .P080E8664	@ =gKitInst
	movs	r0, #0
	strb	r0, [r1]
	strb	r0, [r1, #1]
	movs	r2, #0
	strh	r0, [r1, #2]
	strh	r0, [r1, #4]
	strb	r2, [r1, #6]
	movs	r0, #0x30
	strb	r0, [r1, #7]
	bx	lr
	.hword 0x0000
.P080E8664:	.word gKitInst

@ ======================================================================================
@ instLookup   (080E8668)
@
@   /* Resolve the track's current bank/program for one key into an instrument record,
@      its envelope table and its optional PSG duty / wave data. */
@   void instLookup(Track *t, u32 key, NoteInfo *out)
@   {
@       u8 *bank = cfgTable(gCfg->instBanks, t->player->bankMap[t->bank]);  /* base + base[i]     */
@       InstRec *top = (InstRec *)(bank + ((u16 *)bank)[t->program]);
@       InstRec *ins;
@       out->isKit = 0; out->isSampleKit = 0;
@       switch (top->type) {
@       case 0x00 ... 0x0F:                    /* plain instrument                                  */
@           ins = top; break;
@       case 0x10: {                           /* drum kit: 4-byte entry per key from top->envOfs   */
@           KitEntry *e = (KitEntry *)(bank + top->data) + (u8)(key - (u8)top->envOfs);
@           out->isKit = 1;
@           out->kitPan = e->pan;
@           ins = (InstRec *)(bank + e->inst);
@           break; }
@       case 0x11:                             /* sample kit: one sample number per key             */
@           gKitInst.data = ((u16 *)(bank + top->data))[key];
@           out->inst = &gKitInst;
@           out->env  = kFlatEnvelope;         /* {1, 0x7FFF}, {0x7FFF, 0x7FFF}, {-1, 0}            */
@           out->isSampleKit = 1;
@           goto tail;
@       case 0x12: {                           /* key split: {u8 maxKey, u8 -, u16 inst} entries    */
@           u8 *e = bank + top->data;
@           while (e[0] < key) e += 4;
@           ins = (InstRec *)(bank + *(u16 *)(e + 2));
@           break; }
@       default:                               /* any other type: out->inst is left unset (bug)     */
@           goto tail;
@       }
@       out->inst = ins;
@       out->env  = (s16 *)(bank + ins->envOfs);
@   tail:
@       if (out->inst->type == 3)              /* wave channel: 16-byte wave at top->data           */
@           out->wave = bank + top->data;
@       if (out->inst->flags & 1)              /* PSG duty/noise-mode sequence at ins->data          */
@           out->duty = bank + out->inst->data;
@   }
@ ======================================================================================
	.global instLookup
	.thumb_func
instLookup:
	push	{r4, r5, r6, lr}
	adds	r4, r2, #0
	lsls	r1, r1, #0x18
	lsrs	r6, r1, #0x18
	ldr	r1, .P080E86D0	@ =gCfg
	ldr	r3, [r1]
	ldr	r2, [r0, #8]
	adds	r1, r0, #0
	adds	r1, #0x40
	ldrh	r1, [r1]
	ldr	r2, [r2]
	lsls	r1, r1, #1
	adds	r1, r1, r2
	ldrh	r1, [r1]
	ldr	r2, [r3, #4]
	lsls	r1, r1, #2
	adds	r1, r1, r2
	ldr	r1, [r1]
	adds	r3, r2, r1
	adds	r0, #0x42
	ldrh	r0, [r0]
	lsls	r0, r0, #1
	adds	r0, r3, r0
	ldrh	r0, [r0]
	adds	r5, r3, r0
	movs	r0, #0
	strb	r0, [r4, #0x11]
	strb	r0, [r4, #0x12]
	ldrb	r1, [r5]
	movs	r0, #0xf0
	ands	r0, r1
	cmp	r0, #0
	beq	.L080E8718
	adds	r0, r1, #0
	cmp	r0, #0x10
	bne	.L080E86D4
	ldrh	r2, [r5, #2]
	adds	r2, r3, r2
	ldrb	r0, [r5, #4]
	subs	r0, r6, r0
	lsls	r0, r0, #0x18
	movs	r1, #1
	strb	r1, [r4, #0x11]
	lsrs	r0, r0, #0x16
	adds	r0, r0, r2
	ldrb	r1, [r0, #2]
	strb	r1, [r4, #0x10]
	ldrh	r0, [r0]
	adds	r0, r3, r0
	str	r0, [r4]
	ldrh	r0, [r0, #4]
	b	.L080E871C
.P080E86D0:	.word gCfg
.L080E86D4:
	cmp	r0, #0x11
	bne	.L080E86FC
	ldrh	r1, [r5, #2]
	adds	r1, r3, r1
	ldr	r2, .P080E86F4	@ =gKitInst
	lsls	r0, r6, #1
	adds	r0, r0, r1
	ldrh	r0, [r0]
	strh	r0, [r2, #2]
	str	r2, [r4]
	ldr	r0, .P080E86F8	@ =kFlatEnvelope
	str	r0, [r4, #4]
	movs	r0, #1
	strb	r0, [r4, #0x12]
	b	.L080E8720
	.hword 0x0000
.P080E86F4:	.word gKitInst
.P080E86F8:	.word kFlatEnvelope
.L080E86FC:
	cmp	r0, #0x12
	bne	.L080E8720
	ldrh	r0, [r5, #2]
	adds	r0, r3, r0
	b	.L080E8708
.L080E8706:
	adds	r0, #4
.L080E8708:
	ldrb	r1, [r0]
	cmp	r6, r1
	bhi	.L080E8706
	ldrh	r0, [r0, #2]
	adds	r0, r3, r0
	str	r0, [r4]
	ldrh	r0, [r0, #4]
	b	.L080E871C
.L080E8718:
	str	r5, [r4]
	ldrh	r0, [r5, #4]
.L080E871C:
	adds	r0, r3, r0
	str	r0, [r4, #4]
.L080E8720:
	ldr	r2, [r4]
	ldrb	r0, [r2]
	cmp	r0, #3
	bne	.L080E872E
	ldrh	r0, [r5, #2]
	adds	r0, r3, r0
	str	r0, [r4, #0xc]
.L080E872E:
	ldrb	r1, [r2, #1]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L080E873E
	ldrh	r0, [r2, #2]
	adds	r0, r3, r0
	str	r0, [r4, #8]
.L080E873E:
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ voiceInitAll   (080E8744)
@
@   void voiceInitAll(void)
@   {
@       gLastWave = NULL;
@       for (i = 0; i < 4; i++) gPsgVoices[i].state = 0, ...;
@       gPsgVoices[0].type = 1; gPsgVoices[1].type = 2; gPsgVoices[2].type = 3; gPsgVoices[3].type = 4;
@       for (i = 0; i < 7; i++) gDsVoices[i].state = 0, gDsVoices[i].type = 0, gDsVoices[i].track = NULL;
@       gVoiceCount = 7;
@       gFreeVoices = &gDsVoices[0];                       /* doubly linked: 0 <-> 1 <-> ... <-> 6 */
@       for (i = 0; i < 7; i++) {
@           gDsVoices[i].prev = i ? &gDsVoices[i - 1] : NULL;
@           gDsVoices[i].next = i < 6 ? &gDsVoices[i + 1] : NULL;
@       }
@       gActiveVoices = NULL; gReservedVoices = NULL;
@       gEchoPos = 0; gEchoLen = 18; gEchoShift = 16; gEchoShiftTarget = 16; gEchoTail = 0;
@   }
@ ======================================================================================
	.global voiceInitAll
	.thumb_func
voiceInitAll:
	push	{r4, r5, r6, r7, lr}
	mov	r7, sl
	mov	r6, sb
	mov	r5, r8
	push	{r5, r6, r7}
	ldr	r1, .P080E88B0	@ =gLastWave
	movs	r0, #0
	str	r0, [r1]
	ldr	r2, .P080E88B4	@ =gPsgVoices
	ldr	r0, .P080E88B8	@ =gDsVoices
	mov	ip, r0
	ldr	r3, .P080E88BC	@ =gVoiceCount
	ldr	r5, .P080E88C0	@ =gFreeVoices
	ldr	r1, .P080E88C4	@ =gActiveVoices
	mov	r8, r1
	ldr	r0, .P080E88C8	@ =gReservedVoices
	mov	sb, r0
	ldr	r1, .P080E88CC	@ =gEchoPos
	mov	sl, r1
	movs	r1, #0
	adds	r0, r2, #1
	movs	r4, #3
.L080E8770:
	strb	r1, [r0]
	strb	r1, [r0, #3]
	strb	r1, [r0, #4]
	strb	r1, [r0, #5]
	strb	r1, [r0, #6]
	adds	r0, #0x78
	subs	r4, #1
	cmp	r4, #0
	bge	.L080E8770
	movs	r4, #4
	movs	r0, #1
	strb	r0, [r2]
	adds	r1, r2, #0
	adds	r1, #0x78
	movs	r0, #2
	strb	r0, [r1]
	adds	r1, #0x78
	movs	r0, #3
	strb	r0, [r1]
	movs	r1, #0xb4
	lsls	r1, r1, #1
	adds	r0, r2, r1
	strb	r4, [r0]
	movs	r1, #0
	ldr	r0, .P080E88B8	@ =gDsVoices
	movs	r4, #6
.L080E87A4:
	strb	r1, [r0, #1]
	strb	r1, [r0]
	strb	r1, [r0, #4]
	strb	r1, [r0, #5]
	strb	r1, [r0, #6]
	strb	r1, [r0, #7]
	adds	r0, #0x78
	subs	r4, #1
	cmp	r4, #0
	bge	.L080E87A4
	movs	r4, #7
	strb	r4, [r3]
	mov	r0, ip
	str	r0, [r5]
	adds	r0, #0x78
	mov	r1, ip
	adds	r1, #0x6c
	movs	r2, #0
	strb	r0, [r1]
	lsrs	r1, r0, #8
	mov	r3, ip
	adds	r3, #0x6d
	strb	r1, [r3]
	lsrs	r1, r0, #0x10
	adds	r3, #1
	strb	r1, [r3]
	lsrs	r0, r0, #0x18
	mov	r1, ip
	adds	r1, #0x6f
	strb	r0, [r1]
	mov	r0, ip
	adds	r0, #0x68
	strb	r2, [r0]
	adds	r0, #1
	strb	r2, [r0]
	adds	r0, #1
	strb	r2, [r0]
	adds	r0, #1
	strb	r2, [r0]
	mov	r7, ip
	movs	r5, #0xff
	mov	r2, ip
	adds	r2, #0xe0
	mov	r3, ip
	movs	r6, #0x78
	movs	r4, #4
.L080E8800:
	adds	r1, r7, #0
	adds	r1, #0x78
	adds	r1, r6, r1
	adds	r0, r1, #0
	ands	r0, r5
	strb	r0, [r2, #4]
	lsrs	r0, r1, #8
	ands	r0, r5
	strb	r0, [r2, #5]
	lsrs	r0, r1, #0x10
	ands	r0, r5
	strb	r0, [r2, #6]
	lsrs	r1, r1, #0x18
	strb	r1, [r2, #7]
	adds	r0, r3, #0
	ands	r0, r5
	strb	r0, [r2]
	lsrs	r0, r3, #8
	ands	r0, r5
	strb	r0, [r2, #1]
	lsrs	r0, r3, #0x10
	ands	r0, r5
	strb	r0, [r2, #2]
	lsrs	r0, r3, #0x18
	strb	r0, [r2, #3]
	adds	r2, #0x78
	adds	r3, #0x78
	adds	r6, #0x78
	subs	r4, #1
	cmp	r4, #0
	bge	.L080E8800
	movs	r3, #0
	movs	r1, #0x96
	lsls	r1, r1, #2
	add	r1, ip
	movs	r0, #0xce
	lsls	r0, r0, #2
	add	r0, ip
	strb	r1, [r0]
	lsrs	r2, r1, #8
	ldr	r0, .P080E88D0	@ =0x00000339
	add	r0, ip
	strb	r2, [r0]
	lsrs	r2, r1, #0x10
	ldr	r0, .P080E88D4	@ =0x0000033A
	add	r0, ip
	strb	r2, [r0]
	lsrs	r1, r1, #0x18
	ldr	r0, .P080E88D8	@ =0x0000033B
	add	r0, ip
	strb	r1, [r0]
	movs	r0, #0xcf
	lsls	r0, r0, #2
	add	r0, ip
	strb	r3, [r0]
	ldr	r0, .P080E88DC	@ =0x0000033D
	add	r0, ip
	strb	r3, [r0]
	ldr	r0, .P080E88E0	@ =0x0000033E
	add	r0, ip
	strb	r3, [r0]
	ldr	r0, .P080E88E4	@ =0x0000033F
	add	r0, ip
	strb	r3, [r0]
	mov	r1, r8
	str	r3, [r1]
	mov	r0, sb
	str	r3, [r0]
	mov	r1, sl
	strb	r3, [r1]
	movs	r0, #0x12
	ldr	r1, .P080E88E8	@ =gEchoLen
	strb	r0, [r1]
	movs	r0, #0x10
	ldr	r1, .P080E88EC	@ =gEchoShift
	strb	r0, [r1]
	ldr	r1, .P080E88F0	@ =gEchoShiftTarget
	strb	r0, [r1]
	ldr	r0, .P080E88F4	@ =gEchoTail
	strb	r3, [r0]
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	sb, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080E88B0:	.word gLastWave
.P080E88B4:	.word gPsgVoices
.P080E88B8:	.word gDsVoices
.P080E88BC:	.word gVoiceCount
.P080E88C0:	.word gFreeVoices
.P080E88C4:	.word gActiveVoices
.P080E88C8:	.word gReservedVoices
.P080E88CC:	.word gEchoPos
.P080E88D0:	.word 0x00000339
.P080E88D4:	.word 0x0000033A
.P080E88D8:	.word 0x0000033B
.P080E88DC:	.word 0x0000033D
.P080E88E0:	.word 0x0000033E
.P080E88E4:	.word 0x0000033F
.P080E88E8:	.word gEchoLen
.P080E88EC:	.word gEchoShift
.P080E88F0:	.word gEchoShiftTarget
.P080E88F4:	.word gEchoTail

@ ======================================================================================
@ voiceListRemove   (080E88F8)
@
@   void voiceListRemove(Voice *v, Voice **head)
@   {
@       if (v->prev) v->prev->next = v->next; else *head = v->next;
@       if (v->next) v->next->prev = v->prev;
@   }
@ ======================================================================================
	.global voiceListRemove
	.thumb_func
voiceListRemove:
	push	{lr}
	ldr	r2, [r0, #0x68]
	ldr	r0, [r0, #0x6c]
	cmp	r2, #0
	beq	.L080E8906
	str	r0, [r2, #0x6c]
	b	.L080E8908
.L080E8906:
	str	r0, [r1]
.L080E8908:
	cmp	r0, #0
	beq	.L080E890E
	str	r2, [r0, #0x68]
.L080E890E:
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ voiceListPush   (080E8914)
@
@   void voiceListPush(Voice *v, Voice **head)
@   {
@       v->next = *head; v->prev = NULL;
@       if (*head) (*head)->prev = v;
@       *head = v;
@   }
@ ======================================================================================
	.global voiceListPush
	.thumb_func
voiceListPush:
	push	{lr}
	adds	r3, r0, #0
	ldr	r2, [r1]
	str	r2, [r3, #0x6c]
	movs	r0, #0
	str	r0, [r3, #0x68]
	cmp	r2, #0
	beq	.L080E8926
	str	r3, [r2, #0x68]
.L080E8926:
	str	r3, [r1]
	pop	{r0}
	bx	r0

@ ======================================================================================
@ voiceListInsertActive   (080E892C)
@
@   /* The active list is kept sorted so that its head is the best voice to steal:
@      released voices first (by ascending priority), then playing voices by ascending priority.
@      Among equal priorities a new voice goes after the existing ones. */
@   void voiceListInsertActive(Voice *v)
@   {
@       Voice *before = NULL, *after = gActiveVoices;
@       if (v->state == 1) {                       /* skip all released voices and every playing   */
@           if (after && (after->state != 1 || after->priority <= v->priority))   /* voice of <= prio */
@               do { before = after; after = before->next; }
@               while (after && (after->state != 1 || after->priority <= v->priority));
@       } else if (v->state == 2) {                /* among the released voices, by priority       */
@           if (after && after->state != 1)
@               while (after->priority <= v->priority) {
@                   before = after; after = after->next;
@                   if (!after || after->state == 1) break;
@               }
@       } else return;
@       v->next = after; if (after) after->prev = v;
@       v->prev = before;
@       if (before) before->next = v; else gActiveVoices = v;
@   }
@ ======================================================================================
	.global voiceListInsertActive
	.thumb_func
voiceListInsertActive:
	push	{r4, r5, lr}
	adds	r3, r0, #0
	movs	r4, #0
	ldr	r0, .P080E8968	@ =gActiveVoices
	ldr	r1, [r0]
	ldrb	r2, [r3, #1]
	adds	r5, r0, #0
	cmp	r2, #1
	bne	.L080E896C
	cmp	r1, #0
	beq	.L080E8998
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	bne	.L080E8950
	ldrb	r0, [r3, #8]
	ldrb	r2, [r1, #8]
	cmp	r0, r2
	blo	.L080E8998
.L080E8950:
	adds	r4, r1, #0
	ldr	r1, [r4, #0x6c]
	cmp	r1, #0
	beq	.L080E8998
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	bne	.L080E8950
	ldrb	r0, [r3, #8]
	ldrb	r2, [r1, #8]
	cmp	r0, r2
	bhs	.L080E8950
	b	.L080E8998
.P080E8968:	.word gActiveVoices
.L080E896C:
	cmp	r2, #2
	bne	.L080E89AC
	cmp	r1, #0
	beq	.L080E8998
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	beq	.L080E8998
	ldrb	r0, [r3, #8]
	ldrb	r2, [r1, #8]
	cmp	r0, r2
	blo	.L080E8998
	adds	r2, r0, #0
.L080E8984:
	adds	r4, r1, #0
	ldr	r1, [r4, #0x6c]
	cmp	r1, #0
	beq	.L080E8998
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	beq	.L080E8998
	ldrb	r0, [r1, #8]
	cmp	r2, r0
	bhs	.L080E8984
.L080E8998:
	str	r1, [r3, #0x6c]
	cmp	r1, #0
	beq	.L080E89A0
	str	r3, [r1, #0x68]
.L080E89A0:
	str	r4, [r3, #0x68]
	cmp	r4, #0
	beq	.L080E89AA
	str	r3, [r4, #0x6c]
	b	.L080E89AC
.L080E89AA:
	str	r3, [r5]
.L080E89AC:
	pop	{r4, r5}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ keyToFreq   (080E89B4)
@
@   /* Key -> pitch value for the voice's channel type.  n = key + 48 - rootKey, clamped. */
@   s32 keyToFreq(Voice *v, u32 key, u32 root)
@   {
@       s16 n = (u8)key + 0x30 - (u8)root;
@       if (n < 0) n = 0; else if (n > 119) n = 120;     /* BUG: 120 is one past both tables     */
@       if (v->type == 0) return kDsPitch[n];            /* 32768 * 2^((n-48)/12), 32768 = 1.0   */
@       if (v->type == 4) return n;                      /* noise: index into kNoiseTable        */
@       return kPsgFreq[n];                              /* GB frequency register value          */
@   }
@ ======================================================================================
	.global keyToFreq
	.thumb_func
keyToFreq:
	push	{lr}
	lsls	r1, r1, #0x18
	lsrs	r1, r1, #0x18
	lsls	r2, r2, #0x18
	lsrs	r2, r2, #0x18
	adds	r1, #0x30
	subs	r1, r1, r2
	lsls	r1, r1, #0x10
	lsrs	r2, r1, #0x10
	asrs	r1, r1, #0x10
	cmp	r1, #0
	bge	.L080E89D0
	movs	r2, #0
	b	.L080E89D6
.L080E89D0:
	cmp	r1, #0x77
	ble	.L080E89D6
	movs	r2, #0x78
.L080E89D6:
	ldrb	r0, [r0]
	cmp	r0, #0
	bne	.L080E89EC
	ldr	r0, .P080E89E8	@ =kDsPitch
	lsls	r1, r2, #0x10
	asrs	r1, r1, #0xe
	adds	r1, r1, r0
	ldr	r0, [r1]
	b	.L080E8A04
.P080E89E8:	.word kDsPitch
.L080E89EC:
	cmp	r0, #4
	beq	.L080E8A00
	ldr	r0, .P080E89FC	@ =kPsgFreq
	lsls	r1, r2, #0x10
	asrs	r1, r1, #0xf
	adds	r1, r1, r0
	ldrh	r0, [r1]
	b	.L080E8A04
.P080E89FC:	.word kPsgFreq
.L080E8A00:
	lsls	r0, r2, #0x10
	asrs	r0, r0, #0x10
.L080E8A04:
	pop	{r1}
	bx	r1

@ ======================================================================================
@ noiseDivider   (080E8A08)
@
@   u8 noiseDivider(u32 n)
@   {
@       if ((u16)n > 119) n = 119;
@       return kNoiseTable[n];                           /* NR43 value: shift<<4 | ratio         */
@   }
@ ======================================================================================
	.global noiseDivider
	.thumb_func
noiseDivider:
	push	{lr}
	lsls	r0, r0, #0x10
	lsrs	r1, r0, #0x10
	cmp	r1, #0x77
	bls	.L080E8A14
	movs	r1, #0x77
.L080E8A14:
	ldr	r0, .P080E8A20	@ =kNoiseTable
	adds	r0, r1, r0
	ldrb	r0, [r0]
	pop	{r1}
	bx	r1
	.hword 0x0000
.P080E8A20:	.word kNoiseTable

@ ======================================================================================
@ envStep   (080E8A24)
@
@   /* Advance the voice's envelope by one frame and return the new level (0..0x7FFF).
@      The table is {s16 frames, s16 level} pairs; each segment moves linearly from the
@      current level to 'level' in 'frames' frames.  frames < 0 marks the last pair: the
@      envelope stays on the previous segment (i.e. holds its level) for ever. */
@   s32 envStep(Voice *v)
@   {
@       if (v->envCount == 0) {
@           v->envLevel = v->envTarget;
@           if (v->envTable[(v->envIndex + 1) * 2] >= 0) v->envIndex++;
@           s16 *seg = &v->envTable[v->envIndex * 2];
@           v->envTarget = seg[1];
@           v->envCount  = seg[0];
@           v->envStep   = (s16)(seg[1] - (s16)v->envLevel) / (u16)v->envCount;   /* __divsi3 */
@       }
@       v->envLevel += v->envStep;
@       v->envCount--;
@       return v->envLevel;
@   }
@ ======================================================================================
	.global envStep
	.thumb_func
envStep:
	push	{r4, r5, lr}
	adds	r3, r0, #0
	adds	r4, r3, #0
	adds	r4, #0x40
	ldrh	r0, [r4, #8]
	cmp	r0, #0
	bne	.L080E8A7E
	ldr	r0, [r4, #4]
	str	r0, [r3, #0x40]
	ldrb	r1, [r4, #0x10]
	adds	r0, r1, #1
	strb	r0, [r4, #0x10]
	movs	r0, #0x10
	ldrsb	r0, [r4, r0]
	ldr	r2, [r4, #0xc]
	lsls	r0, r0, #2
	adds	r0, r0, r2
	movs	r5, #0
	ldrsh	r0, [r0, r5]
	cmp	r0, #0
	bge	.L080E8A50
	strb	r1, [r4, #0x10]
.L080E8A50:
	movs	r0, #0x10
	ldrsb	r0, [r4, r0]
	lsls	r0, r0, #2
	adds	r0, r0, r2
	movs	r5, #2
	ldrsh	r1, [r0, r5]
	str	r1, [r4, #4]
	movs	r0, #0x10
	ldrsb	r0, [r4, r0]
	lsls	r0, r0, #2
	adds	r0, r0, r2
	ldrh	r0, [r0]
	strh	r0, [r4, #8]
	strh	r1, [r4, #0xa]
	ldr	r0, [r3, #0x40]
	subs	r1, r1, r0
	strh	r1, [r4, #0xa]
	movs	r1, #0xa
	ldrsh	r0, [r4, r1]
	ldrh	r1, [r4, #8]
	bl	__divsi3
	strh	r0, [r4, #0xa]
.L080E8A7E:
	movs	r5, #0xa
	ldrsh	r1, [r4, r5]
	ldr	r0, [r4]
	adds	r0, r0, r1
	str	r0, [r4]
	ldrh	r1, [r4, #8]
	subs	r1, #1
	strh	r1, [r4, #8]
	pop	{r4, r5}
	pop	{r1}
	bx	r1

@ ======================================================================================
@ echoSetFeedback   (080E8A94)
@
@   void echoSetFeedback(u32 shift)     /* command 0x300: 16 = echo off, n < 16: feedback 2^-n */
@   {
@       gEchoShiftTarget = shift;       /* mixFrame moves gEchoShift towards it by 1 per frame */
@   }
@ ======================================================================================
	.global echoSetFeedback
	.thumb_func
echoSetFeedback:
	lsls	r0, r0, #0x18
	lsrs	r0, r0, #0x18
	ldr	r1, .P080E8AA0	@ =gEchoShiftTarget
	strb	r0, [r1]
	bx	lr
	.hword 0x0000
.P080E8AA0:	.word gEchoShiftTarget

@ ======================================================================================
@ voiceSetCount   (080E8AA4)
@
@   /* Command 0x304: change the number of sampled voices (at most 7).  Fewer voices: steal
@      voices through voiceAlloc and park them on gReservedVoices; more: return them. */
@   void voiceSetCount(u32 n)
@   {
@       s8 d = (u8)n - gVoiceCount;
@       if (d > 0) {
@           for (Voice *v = gReservedVoices, *nx; v && d > 0; v = nx, d--) {
@               nx = v->next;
@               voiceListRemove(v, &gReservedVoices); voiceListPush(v, &gFreeVoices);
@               gVoiceCount++;
@           }
@       } else if (d < 0) {
@           for (d = -d; d > 0; d--) {
@               Voice *v = voiceAlloc(0, 0xFF);                /* priority 255 always succeeds */
@               if (!v) break;
@               voiceListRemove(v, &gActiveVoices); v->state = 0;
@               voiceListPush(v, &gReservedVoices);
@               gVoiceCount--;
@           }
@       }
@   }
@ ======================================================================================
	.global voiceSetCount
	.thumb_func
voiceSetCount:
	push	{r4, r5, r6, r7, lr}
	lsls	r0, r0, #0x18
	lsrs	r0, r0, #0x18
	ldr	r2, .P080E8AF8	@ =gVoiceCount
	ldrb	r1, [r2]
	subs	r0, r0, r1
	lsls	r0, r0, #0x18
	lsrs	r5, r0, #0x18
	asrs	r0, r0, #0x18
	cmp	r0, #0
	beq	.L080E8B44
	cmp	r0, #0
	ble	.L080E8B04
	ldr	r0, .P080E8AFC	@ =gReservedVoices
	ldr	r6, [r0]
	cmp	r6, #0
	beq	.L080E8B44
	adds	r7, r2, #0
.L080E8AC8:
	adds	r4, r6, #0
	ldr	r6, [r4, #0x6c]
	adds	r0, r4, #0
	ldr	r1, .P080E8AFC	@ =gReservedVoices
	bl	voiceListRemove
	adds	r0, r4, #0
	ldr	r1, .P080E8B00	@ =gFreeVoices
	bl	voiceListPush
	lsls	r0, r5, #0x18
	movs	r1, #0xff
	lsls	r1, r1, #0x18
	adds	r0, r0, r1
	lsrs	r5, r0, #0x18
	ldrb	r0, [r7]
	adds	r0, #1
	strb	r0, [r7]
	cmp	r6, #0
	beq	.L080E8B44
	lsls	r0, r5, #0x18
	cmp	r0, #0
	bgt	.L080E8AC8
	b	.L080E8B44
.P080E8AF8:	.word gVoiceCount
.P080E8AFC:	.word gReservedVoices
.P080E8B00:	.word gFreeVoices
.L080E8B04:
	rsbs	r0, r0, #0
	lsls	r0, r0, #0x18
	lsrs	r5, r0, #0x18
	adds	r6, r2, #0
	b	.L080E8B2E
.L080E8B0E:
	adds	r0, r4, #0
	ldr	r1, .P080E8B4C	@ =gActiveVoices
	bl	voiceListRemove
	movs	r0, #0
	strb	r0, [r4, #1]
	adds	r0, r4, #0
	ldr	r1, .P080E8B50	@ =gReservedVoices
	bl	voiceListPush
	subs	r0, r5, #1
	lsls	r0, r0, #0x18
	lsrs	r5, r0, #0x18
	ldrb	r0, [r6]
	subs	r0, #1
	strb	r0, [r6]
.L080E8B2E:
	lsls	r0, r5, #0x18
	asrs	r5, r0, #0x18
	cmp	r5, #0
	ble	.L080E8B44
	movs	r0, #0
	movs	r1, #0xff
	bl	voiceAlloc
	adds	r4, r0, #0
	cmp	r4, #0
	bne	.L080E8B0E
.L080E8B44:
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080E8B4C:	.word gActiveVoices
.P080E8B50:	.word gReservedVoices

@ ======================================================================================
@ dsVolume   (080E8B54)
@
@   /* Sampled voice: advance the envelope (key on) or the release, return the mix volume. */
@   u32 dsVolume(Voice *v)
@   {
@       if (v->state == 1) {
@           Track *t = v->track; Player *p = t->player;
@           u32 x = (p->volume * v->velocity * 128) >> 8;          /* player volume 0x8000 = 1.0 */
@           x = (x * p->songVolume) >> 7;                          /* 0x80 = 1.0 (command EA)    */
@           x = (x * p->volume2)    >> 8;                          /* 0x80 = 0.5 (command 5)     */
@           x = (x * t->volume)     >> 8;                          /* 0x80 = 0.5 (command E0)    */
@           x = (x * t->expression) >> 15;                         /* 0x80 = 1/256 (command 0x102)*/
@           v->volume = (envStep(v) * x) >> 11;
@       } else                                                     /* released: exponential decay */
@           v->volume = v->volume * (v->release + 230) >> 9;
@       return v->volume >> 8;
@   }
@ ======================================================================================
	.global dsVolume
	.thumb_func
dsVolume:
	push	{r4, r5, lr}
	adds	r5, r0, #0
	ldrb	r0, [r5, #1]
	cmp	r0, #1
	bne	.L080E8B9E
	ldrb	r4, [r5, #0xa]
	lsls	r4, r4, #7
	ldr	r2, [r5, #4]
	ldr	r1, [r2, #8]
	ldrh	r0, [r1, #0x34]
	muls	r4, r0, r4
	lsrs	r4, r4, #8
	adds	r0, r1, #0
	adds	r0, #0x40
	ldrb	r0, [r0]
	muls	r4, r0, r4
	lsrs	r4, r4, #7
	adds	r1, #0x41
	ldrb	r0, [r1]
	muls	r4, r0, r4
	lsrs	r4, r4, #8
	adds	r0, r2, #0
	adds	r0, #0x4d
	ldrb	r0, [r0]
	muls	r4, r0, r4
	lsrs	r4, r4, #8
	adds	r2, #0x4e
	ldrb	r0, [r2]
	muls	r4, r0, r4
	lsrs	r4, r4, #0xf
	adds	r0, r5, #0
	bl	envStep
	muls	r4, r0, r4
	lsrs	r4, r4, #0xb
	str	r4, [r5, #0x14]
	b	.L080E8BB0
.L080E8B9E:
	adds	r0, r5, #0
	adds	r0, #0x58
	ldrb	r0, [r0]
	adds	r0, #0xe6
	ldr	r1, [r5, #0x14]
	muls	r0, r1, r0
	lsrs	r0, r0, #9
	str	r0, [r5, #0x14]
	adds	r4, r0, #0
.L080E8BB0:
	lsrs	r4, r4, #8
	adds	r0, r4, #0
	pop	{r4, r5}
	pop	{r1}
	bx	r1
	movs	r0, r0

@ ======================================================================================
@ psgEnvelope   (080E8BBC)
@
@   /* PSG voice: advance the envelope and, at the start of each envelope segment, return a
@      new NRx2 value that lets the hardware envelope approximate the segment:
@      start volume = current level, direction up/down, step time = (frames+15)/|delta| (1..7).
@      Returns 8 ("no change") between segment starts.  For the wave channel (type 3) it
@      returns an index into kWaveVolume (0 = mute .. 4 = 100 %) instead.
@      'loud' doubles the velocity for voices panned hard left or right. */
@   u32 psgEnvelope(Voice *v, u32 loud)
@   {
@       u32 vel = v->velocity;
@       s16 wasCount = v->envCount;
@       envStep(v);
@       if (wasCount != 0) return 8;
@       if (loud) vel <<= 1;
@       Track *t = v->track; Player *p = t->player;
@       u32 x = (t->volume * vel * 0x8000) >> 14;
@       x = (x * t->expression) >> 7;  x = (x * p->songVolume) >> 7;
@       x = p->volume * ((x * p->volume2) >> 8);
@       if (v->type == 3) {
@           v->volume = x >> 22;
@           return min(v->volume * 5 >> 7, 4);
@       }
@       v->volume = x >> 15;
@       u32 from = min((v->envLevel  * v->volume) >> 25, 15);
@       v->volume = min((v->volume * v->envTarget) >> 25, 15);
@       u32 to = v->volume;
@       if (to != from) {
@           u16 st = (u16)(v->envCount + 15) / abs(to - from);
@           if (st) return from << 4 | min(st, 7) | (to > from ? 8 : 0);
@       }
@       return from << 4 | 8;            /* constant volume (direction 'up', step 0 = off)      */
@   }
@ ======================================================================================
	.global psgEnvelope
	.thumb_func
psgEnvelope:
	push	{r4, r5, r6, r7, lr}
	mov	r7, r8
	push	{r7}
	adds	r5, r0, #0
	lsls	r1, r1, #0x18
	lsrs	r7, r1, #0x18
	movs	r6, #0
	ldrb	r4, [r5, #0xa]
	movs	r0, #0x48
	adds	r0, r0, r5
	mov	r8, r0
	ldrh	r0, [r0]
	cmp	r0, #0
	bne	.L080E8BDA
	movs	r6, #1
.L080E8BDA:
	adds	r0, r5, #0
	bl	envStep
	cmp	r6, #0
	bne	.L080E8BE8
	movs	r0, #8
	b	.L080E8CB8
.L080E8BE8:
	cmp	r7, #0
	beq	.L080E8BEE
	lsls	r4, r4, #1
.L080E8BEE:
	lsls	r4, r4, #0xf
	ldr	r1, [r5, #4]
	adds	r0, r1, #0
	adds	r0, #0x4d
	ldrb	r0, [r0]
	muls	r4, r0, r4
	lsrs	r4, r4, #0xe
	adds	r0, r1, #0
	adds	r0, #0x4e
	ldrb	r0, [r0]
	muls	r4, r0, r4
	lsrs	r4, r4, #7
	ldr	r1, [r1, #8]
	adds	r0, r1, #0
	adds	r0, #0x40
	ldrb	r0, [r0]
	muls	r4, r0, r4
	lsrs	r4, r4, #7
	adds	r0, r1, #0
	adds	r0, #0x41
	ldrb	r0, [r0]
	muls	r4, r0, r4
	lsrs	r4, r4, #8
	ldrh	r0, [r1, #0x34]
	muls	r4, r0, r4
	ldrb	r0, [r5]
	cmp	r0, #3
	bne	.L080E8C3C
	lsrs	r4, r4, #0x16
	str	r4, [r5, #0x14]
	lsls	r0, r4, #2
	adds	r4, r0, r4
	lsrs	r4, r4, #7
	cmp	r4, #4
	bls	.L080E8C36
	movs	r4, #4
.L080E8C36:
	lsls	r0, r4, #0x18
	lsrs	r0, r0, #0x18
	b	.L080E8CB8
.L080E8C3C:
	lsrs	r4, r4, #0xf
	str	r4, [r5, #0x14]
	ldr	r0, [r5, #0x40]
	muls	r4, r0, r4
	lsrs	r4, r4, #0x19
	movs	r2, #0x10
	rsbs	r2, r2, #0
	adds	r0, r4, #0
	ands	r0, r2
	cmp	r0, #0
	beq	.L080E8C54
	movs	r4, #0xf
.L080E8C54:
	ldr	r1, [r5, #0x14]
	ldr	r0, [r5, #0x44]
	muls	r0, r1, r0
	lsrs	r0, r0, #0x19
	str	r0, [r5, #0x14]
	ands	r0, r2
	cmp	r0, #0
	beq	.L080E8C68
	movs	r0, #0xf
	str	r0, [r5, #0x14]
.L080E8C68:
	ldr	r5, [r5, #0x14]
	cmp	r5, r4
	beq	.L080E8C90
	mov	r1, r8
	ldrh	r2, [r1]
	adds	r0, r2, #0
	adds	r0, #0xf
	lsls	r0, r0, #0x10
	lsrs	r2, r0, #0x10
	subs	r1, r5, r4
	cmp	r1, #0
	bge	.L080E8C82
	rsbs	r1, r1, #0
.L080E8C82:
	adds	r0, r2, #0
	bl	__divsi3
	lsls	r0, r0, #0x10
	lsrs	r2, r0, #0x10
	cmp	r2, #0
	bne	.L080E8C9C
.L080E8C90:
	lsls	r0, r4, #4
	movs	r1, #8
	orrs	r0, r1
	lsls	r0, r0, #0x18
	lsrs	r6, r0, #0x18
	b	.L080E8CB6
.L080E8C9C:
	ldr	r0, .P080E8CC4	@ =0x0000FFF8
	ands	r0, r2
	cmp	r0, #0
	beq	.L080E8CA6
	movs	r2, #7
.L080E8CA6:
	lsls	r0, r4, #4
	orrs	r0, r2
	lsls	r0, r0, #0x18
	lsrs	r6, r0, #0x18
	cmp	r4, r5
	bhs	.L080E8CB6
	movs	r0, #8
	orrs	r6, r0
.L080E8CB6:
	adds	r0, r6, #0
.L080E8CB8:
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1
	.hword 0x0000
.P080E8CC4:	.word 0x0000FFF8

@ ======================================================================================
@ voicePitch   (080E8CC8)
@
@   /* Pitch for this frame: base + portamento, then pitch bend, then vibrato.
@      Sampled voices use kDsPitch units (bigger = higher); PSG voices use GB register
@      values (2048 - x is the period), so the maths is done on the period. */
@   u32 voicePitch(Voice *v)
@   {
@       Track *t = v->track;
@       if (v->portaDelay) v->portaDelay--;
@       else if (v->portaCount) {
@           v->portaOfs += v->portaStep;
@           if (--v->portaCount == 0) v->portaOfs = v->portaTotal;
@       }
@       u32 f = v->freq + v->portaOfs;
@       if (t->bend) {                   /* ratio = 1 + bend/128 * (2^(range/12) - ... ) (linear)  */
@           u32 r = kDsPitch[t->bendRange + 48] * abs(t->bend) + 0x400000;   /* 1.0 = 0x400000  */
@           if (t->bend > 0) f = v->type ? 0x800 - (0x800 - f) * 0x400000 / r : (r >> 7) * f >> 15;
@           else             f = v->type ? max(0x800 - ((r >> 7) * (0x800 - f) >> 15), 0)
@                                        : f * 0x8000 / (r >> 7);
@       }
@       if (t->lfoDepth) {               /* vibrato: sine table, depth in 1/256-ish units          */
@           if (v->lfoDelay) v->lfoDelay--;
@           else {
@               s32 s = kLfoSine[v->lfoPhase >> 1];                     /* -127..127              */
@               if (v->type == 0)
@                   f = s < 0 ? (f * 0x1000 / ((t->lfoDepth * -s >> 3) + 0x10000)) << 4
@                             : f + (t->lfoDepth * f * s >> 19);
@               else
@                   f = 0x800 - (s < 0 ? (t->lfoDepth * -s + 0x80000) * (0x800 - f) >> 19
@                                      : (0x800 - f) * 0x80000 / (t->lfoDepth * s + 0x80000));
@               v->lfoPhase += t->lfoSpeed;
@               if ((v->lfoPhase >> 1) > 255) v->lfoPhase -= 0x200;
@           }
@       }
@       return f;
@   }
@ ======================================================================================
	.global voicePitch
	.thumb_func
voicePitch:
	push	{r4, r5, r6, lr}
	adds	r5, r0, #0
	ldr	r2, [r5, #0xc]
	ldr	r6, [r5, #4]
	adds	r3, r5, #0
	adds	r3, #0x2c
	ldr	r0, [r5, #0x2c]
	cmp	r0, #0
	beq	.L080E8CE0
	subs	r0, #1
	str	r0, [r5, #0x2c]
	b	.L080E8CFA
.L080E8CE0:
	ldr	r4, [r3, #4]
	cmp	r4, #0
	beq	.L080E8CFA
	ldr	r0, [r3, #8]
	ldr	r1, [r3, #0x10]
	adds	r0, r0, r1
	str	r0, [r3, #8]
	subs	r0, r4, #1
	str	r0, [r3, #4]
	cmp	r0, #0
	bne	.L080E8CFA
	ldr	r0, [r3, #0xc]
	str	r0, [r3, #8]
.L080E8CFA:
	ldr	r0, [r3, #8]
	adds	r2, r2, r0
	adds	r0, r6, #0
	adds	r0, #0x4f
	movs	r1, #0
	ldrsb	r1, [r0, r1]
	cmp	r1, #0
	beq	.L080E8DA6
	cmp	r1, #0
	ble	.L080E8D4E
	adds	r3, r1, #0
	ldr	r1, .P080E8D34	@ =kDsPitch
	adds	r0, #1
	ldrb	r0, [r0]
	adds	r0, #0x30
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r0, [r0]
	muls	r3, r0, r3
	movs	r0, #0x80
	lsls	r0, r0, #0xf
	adds	r3, r3, r0
	ldrb	r0, [r5]
	cmp	r0, #0
	bne	.L080E8D38
	lsrs	r3, r3, #7
	muls	r2, r3, r2
	lsrs	r2, r2, #0xf
	b	.L080E8DA6
.P080E8D34:	.word kDsPitch
.L080E8D38:
	movs	r4, #0x80
	lsls	r4, r4, #4
	subs	r2, r4, r2
	lsls	r2, r2, #0x16
	adds	r0, r2, #0
	adds	r1, r3, #0
	bl	__udivsi3
	adds	r2, r0, #0
	subs	r2, r4, r2
	b	.L080E8DA6
.L080E8D4E:
	ldrb	r0, [r0]
	lsls	r0, r0, #0x18
	asrs	r0, r0, #0x18
	rsbs	r3, r0, #0
	ldr	r1, .P080E8D84	@ =kDsPitch
	adds	r0, r6, #0
	adds	r0, #0x50
	ldrb	r0, [r0]
	adds	r0, #0x30
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r0, [r0]
	muls	r3, r0, r3
	movs	r0, #0x80
	lsls	r0, r0, #0xf
	adds	r3, r3, r0
	ldrb	r0, [r5]
	cmp	r0, #0
	bne	.L080E8D88
	lsls	r2, r2, #0xf
	lsrs	r3, r3, #7
	adds	r0, r2, #0
	adds	r1, r3, #0
	bl	__udivsi3
	adds	r2, r0, #0
	b	.L080E8DA6
.P080E8D84:	.word kDsPitch
.L080E8D88:
	movs	r1, #0x80
	lsls	r1, r1, #4
	subs	r2, r1, r2
	lsrs	r3, r3, #7
	muls	r2, r3, r2
	lsrs	r2, r2, #0xf
	ldr	r0, .P080E8DA0	@ =0x000007FF
	cmp	r2, r0
	bhi	.L080E8DA4
	subs	r2, r1, r2
	b	.L080E8DA6
	.hword 0x0000
.P080E8DA0:	.word 0x000007FF
.L080E8DA4:
	movs	r2, #0
.L080E8DA6:
	adds	r4, r5, #0
	adds	r4, #0x20
	ldr	r0, [r4, #8]
	ldr	r3, [r0, #8]
	cmp	r3, #0
	beq	.L080E8E54
	ldr	r0, [r4, #4]
	cmp	r0, #0
	bne	.L080E8E50
	ldr	r0, .P080E8DDC	@ =kLfoSine
	ldr	r1, [r5, #0x20]
	lsrs	r1, r1, #1
	adds	r1, r1, r0
	ldrb	r1, [r1]
	ldrb	r0, [r5]
	cmp	r0, #0
	bne	.L080E8DFC
	lsls	r0, r1, #0x18
	asrs	r0, r0, #0x18
	cmp	r0, #0
	blt	.L080E8DE0
	muls	r0, r2, r0
	muls	r0, r3, r0
	lsrs	r0, r0, #0x13
	adds	r2, r2, r0
	b	.L080E8E34
	.hword 0x0000
.P080E8DDC:	.word kLfoSine
.L080E8DE0:
	lsls	r2, r2, #0xc
	rsbs	r0, r0, #0
	adds	r1, r0, #0
	muls	r1, r3, r1
	lsrs	r1, r1, #3
	movs	r3, #0x80
	lsls	r3, r3, #9
	adds	r1, r1, r3
	adds	r0, r2, #0
	bl	__udivsi3
	adds	r2, r0, #0
	lsls	r2, r2, #4
	b	.L080E8E34
.L080E8DFC:
	lsls	r0, r1, #0x18
	asrs	r1, r0, #0x18
	cmp	r1, #0
	blt	.L080E8E1A
	movs	r0, #0x80
	lsls	r0, r0, #4
	subs	r0, r0, r2
	lsls	r0, r0, #0x13
	muls	r1, r3, r1
	movs	r2, #0x80
	lsls	r2, r2, #0xc
	adds	r1, r1, r2
	bl	__udivsi3
	b	.L080E8E2E
.L080E8E1A:
	movs	r0, #0x80
	lsls	r0, r0, #4
	rsbs	r1, r1, #0
	subs	r0, r0, r2
	muls	r1, r3, r1
	movs	r3, #0x80
	lsls	r3, r3, #0xc
	adds	r1, r1, r3
	muls	r0, r1, r0
	lsrs	r0, r0, #0x13
.L080E8E2E:
	movs	r2, #0x80
	lsls	r2, r2, #4
	subs	r2, r2, r0
.L080E8E34:
	ldr	r0, [r4, #8]
	ldr	r1, [r4]
	ldr	r0, [r0, #4]
	adds	r1, r1, r0
	str	r1, [r4]
	lsrs	r0, r1, #1
	cmp	r0, #0xff
	bls	.L080E8E54
	ldr	r3, .P080E8E4C	@ =0xFFFFFE00
	adds	r0, r1, r3
	str	r0, [r4]
	b	.L080E8E54
.P080E8E4C:	.word 0xFFFFFE00
.L080E8E50:
	subs	r0, #1
	str	r0, [r4, #4]
.L080E8E54:
	adds	r0, r2, #0
	pop	{r4, r5, r6}
	pop	{r1}
	bx	r1

@ ======================================================================================
@ mixFrame   (080E8E5C)
@
@   /* Render one frame: 176 stereo samples at 10 512 Hz. */
@   void mixFrame(void)
@   {
@       if (gEchoShift < 16)             /* the wet bus starts with the output of 18 frames ago    */
@           CpuFastSet(gEchoHistory + gEchoPos * 0x160, gMixWet, 0xB0);
@       CpuFastSet(&zero, gMixDry, FILL | 0xB0);
@       for (Voice *v = gActiveVoices, *nx; v; v = nx) {
@           nx = v->next;
@           if (v->track && v->track->player && (v->track->player->flags & PAUSED))
@               continue;                                /* paused player: voice frozen          */
@           u32 vol = dsVolume(v), pan, f;
@           if (v->state == 1) {
@               v->length--;
@               pan = v->fixedPan ? v->pan : v->track->pan;
@               f = v->outFreq = voicePitch(v);
@               v->echo = v->track->echo;
@           } else {
@               if (vol == 0) { voiceStop(v); continue; }
@               pan = v->pan; f = v->outFreq;
@           }
@           u32 step = (v->sample->rate * (f >> 2) / 10512) >> 5;   /* 24.8 input samples/output */
@           if (mixVoice(v, vol, step, pan) == 1) voiceStop(v);
@       }
@       for (i = 0; i < 7; i++)                          /* notes whose length ran out          */
@           if (gDsVoices[i].state == 1 && gDsVoices[i].length == 0) noteOff(&gDsVoices[i]);
@       if (gEchoShift > gEchoShiftTarget) gEchoShift--;
@       else if (gEchoShift < gEchoShiftTarget) gEchoShift++;
@       if (gEchoShift < 16) gEchoTail = gEchoLen;       /* keep feeding the history for one     */
@       else if (gEchoTail) gEchoTail--;                 /* more round after the echo is turned off */
@       else goto out;
@       if (gEchoTail) {
@           gFnEcho(gMixDry, gMixWet, gMixDry + 352, gEchoShift);   /* dry += wet; wet >>= shift */
@           CpuFastSet(gMixWet, gEchoHistory + gEchoPos * 0x160, 0xB0);
@       }
@   out:
@       if (++gEchoPos >= gEchoLen) gEchoPos = 0;
@       gFnDownmix(gMixDry, gDmaBufA[gDmaBufIdx], gMixDry + 352);   /* L -> buffer A, R -> B      */
@   }
@ ======================================================================================
	.global mixFrame
	.thumb_func
mixFrame:
	push	{r4, r5, r6, r7, lr}
	mov	r7, r8
	push	{r7}
	sub	sp, #4
	ldr	r0, .P080E8EE0	@ =gActiveVoices
	ldr	r0, [r0]
	mov	r8, r0
	ldr	r0, .P080E8EE4	@ =gEchoShift
	ldrb	r0, [r0]
	cmp	r0, #0xf
	bhi	.L080E8E8E
	ldr	r2, .P080E8EE8	@ =gEchoHistory
	ldr	r0, .P080E8EEC	@ =gEchoPos
	ldrb	r0, [r0]
	lsls	r1, r0, #1
	adds	r1, r1, r0
	lsls	r1, r1, #2
	subs	r1, r1, r0
	lsls	r1, r1, #6
	ldr	r0, [r2]
	adds	r0, r0, r1
	ldr	r1, .P080E8EF0	@ =gMixWet
	movs	r2, #0xb0
	bl	CpuFastSet
.L080E8E8E:
	movs	r0, #0
	str	r0, [sp]
	ldr	r1, .P080E8EF4	@ =gMixDry
	ldr	r2, .P080E8EF8	@ =0x010000B0
	mov	r0, sp
	bl	CpuFastSet
	mov	r0, r8
	cmp	r0, #0
	beq	.L080E8F5A
.L080E8EA2:
	mov	r4, r8
	ldr	r1, [r4, #0x6c]
	mov	r8, r1
	ldr	r0, [r4, #4]
	cmp	r0, #0
	beq	.L080E8EC0
	ldr	r0, [r0, #8]
	cmp	r0, #0
	beq	.L080E8EC0
	adds	r0, #0x3c
	ldrb	r1, [r0]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	bne	.L080E8F54
.L080E8EC0:
	adds	r0, r4, #0
	bl	dsVolume
	adds	r7, r0, #0
	ldrb	r0, [r4, #1]
	cmp	r0, #1
	bne	.L080E8F18
	ldrh	r0, [r4, #0x18]
	subs	r0, #1
	strh	r0, [r4, #0x18]
	ldr	r5, [r4, #4]
	ldrb	r0, [r4, #0x1b]
	cmp	r0, #0
	beq	.L080E8EFC
	ldrb	r3, [r4, #0x1c]
	b	.L080E8F02
.P080E8EE0:	.word gActiveVoices
.P080E8EE4:	.word gEchoShift
.P080E8EE8:	.word gEchoHistory
.P080E8EEC:	.word gEchoPos
.P080E8EF0:	.word gMixWet
.P080E8EF4:	.word gMixDry
.P080E8EF8:	.word 0x010000B0
.L080E8EFC:
	adds	r0, r5, #0
	adds	r0, #0x4b
	ldrb	r3, [r0]
.L080E8F02:
	adds	r6, r3, #0
	adds	r0, r4, #0
	bl	voicePitch
	adds	r2, r0, #0
	str	r2, [r4, #0x10]
	adds	r0, r5, #0
	adds	r0, #0x4c
	ldrb	r0, [r0]
	strb	r0, [r4, #0x1a]
	b	.L080E8F28
.L080E8F18:
	cmp	r7, #0
	bne	.L080E8F24
	adds	r0, r4, #0
	bl	voiceStop
	b	.L080E8F54
.L080E8F24:
	ldrb	r6, [r4, #0x1c]
	ldr	r2, [r4, #0x10]
.L080E8F28:
	lsrs	r2, r2, #2
	ldr	r0, [r4, #0x5c]
	ldr	r0, [r0, #4]
	muls	r2, r0, r2
	adds	r0, r2, #0
	ldr	r1, .P080E8F90	@ =0x00002910
	bl	__udivsi3
	adds	r2, r0, #0
	lsrs	r2, r2, #5
	adds	r0, r4, #0
	adds	r1, r7, #0
	adds	r3, r6, #0
	bl	mixVoice
	lsls	r0, r0, #0x18
	lsrs	r0, r0, #0x18
	cmp	r0, #1
	bne	.L080E8F54
	adds	r0, r4, #0
	bl	voiceStop
.L080E8F54:
	mov	r3, r8
	cmp	r3, #0
	bne	.L080E8EA2
.L080E8F5A:
	movs	r5, #0
	movs	r4, #6
.L080E8F5E:
	ldr	r0, .P080E8F94	@ =gDsVoices
	adds	r1, r5, r0
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	bne	.L080E8F74
	ldrh	r0, [r1, #0x18]
	cmp	r0, #0
	bne	.L080E8F74
	adds	r0, r1, #0
	bl	noteOff
.L080E8F74:
	adds	r5, #0x78
	subs	r4, #1
	cmp	r4, #0
	bge	.L080E8F5E
	ldr	r4, .P080E8F98	@ =gEchoShiftTarget
	ldr	r0, .P080E8F9C	@ =gEchoShift
	ldrb	r1, [r4]
	ldrb	r2, [r0]
	adds	r3, r2, #0
	adds	r6, r0, #0
	cmp	r1, r3
	bhs	.L080E8FA0
	subs	r0, r2, #1
	b	.L080E8FA8
.P080E8F90:	.word 0x00002910
.P080E8F94:	.word gDsVoices
.P080E8F98:	.word gEchoShiftTarget
.P080E8F9C:	.word gEchoShift
.L080E8FA0:
	ldrb	r0, [r4]
	cmp	r0, r3
	bls	.L080E8FAA
	adds	r0, r2, #1
.L080E8FA8:
	strb	r0, [r6]
.L080E8FAA:
	ldrb	r0, [r6]
	cmp	r0, #0xf
	bls	.L080E8FC4
	ldr	r0, .P080E8FC0	@ =gEchoTail
	ldrb	r1, [r0]
	adds	r2, r0, #0
	cmp	r1, #0
	beq	.L080E9006
	subs	r0, r1, #1
	strb	r0, [r2]
	b	.L080E8FCE
.P080E8FC0:	.word gEchoTail
.L080E8FC4:
	ldr	r0, .P080E9048	@ =gEchoTail
	ldr	r1, .P080E904C	@ =gEchoLen
	ldrb	r1, [r1]
	strb	r1, [r0]
	adds	r2, r0, #0
.L080E8FCE:
	ldrb	r0, [r2]
	cmp	r0, #0
	beq	.L080E9006
	ldr	r1, .P080E9050	@ =gFnEcho
	ldr	r0, .P080E9054	@ =gMixDry
	ldr	r5, .P080E9058	@ =gMixWet
	movs	r4, #0xb0
	lsls	r4, r4, #2
	adds	r2, r0, r4
	ldrb	r3, [r6]
	ldr	r4, [r1]
	adds	r1, r5, #0
	bl	_call_via_r4
	ldr	r2, .P080E905C	@ =gEchoHistory
	ldr	r0, .P080E9060	@ =gEchoPos
	ldrb	r1, [r0]
	lsls	r0, r1, #1
	adds	r0, r0, r1
	lsls	r0, r0, #2
	subs	r0, r0, r1
	lsls	r0, r0, #6
	ldr	r1, [r2]
	adds	r1, r1, r0
	adds	r0, r5, #0
	movs	r2, #0xb0
	bl	CpuFastSet
.L080E9006:
	ldr	r2, .P080E9060	@ =gEchoPos
	ldrb	r0, [r2]
	adds	r0, #1
	strb	r0, [r2]
	ldr	r1, .P080E904C	@ =gEchoLen
	lsls	r0, r0, #0x18
	lsrs	r0, r0, #0x18
	ldrb	r1, [r1]
	cmp	r0, r1
	blo	.L080E901E
	movs	r0, #0
	strb	r0, [r2]
.L080E901E:
	ldr	r3, .P080E9064	@ =gFnDownmix
	ldr	r0, .P080E9054	@ =gMixDry
	ldr	r2, .P080E9068	@ =gDmaBufA
	ldr	r1, .P080E906C	@ =gDmaBufIdx
	ldrb	r1, [r1]
	lsls	r1, r1, #2
	adds	r1, r1, r2
	ldr	r1, [r1]
	movs	r4, #0xb0
	lsls	r4, r4, #2
	adds	r2, r0, r4
	ldr	r3, [r3]
	bl	_call_via_r3
	add	sp, #4
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080E9048:	.word gEchoTail
.P080E904C:	.word gEchoLen
.P080E9050:	.word gFnEcho
.P080E9054:	.word gMixDry
.P080E9058:	.word gMixWet
.P080E905C:	.word gEchoHistory
.P080E9060:	.word gEchoPos
.P080E9064:	.word gFnDownmix
.P080E9068:	.word gDmaBufA
.P080E906C:	.word gDmaBufIdx

@ ======================================================================================
@ psgUpdate   (080E9070)
@
@   /* Once per frame for the four Game Boy channels. */
@   void psgUpdate(void)
@   {
@       for (i = 0; i < 4; i++) {
@           Voice *v = &gPsgVoices[i];                     /* type 1..4 = square 1, square 2, wave, noise */
@           if (v->state == 1 && v->length == 0) noteOff(v);
@           else if (v->track && v->track->player && (v->track->player->flags & PAUSED)) noteOff(v);
@           if (v->state == 0) continue;
@           u32 f, pan;
@           if (v->state == 1) { f = v->outFreq = voicePitch(v); pan = v->fixedPan ? v->pan : v->track->pan; }
@           else               { f = v->outFreq; pan = v->pan; }
@           u32 env = psgEnvelope(v, pan != 64) & 0xFF;    /* 8 = keep the current envelope       */
@           u8 bit = 1 << (v->type - 1);                   /* hard pan: 64 = both, <64 left, >64 right */
@           REG_NR51 = (REG_NR51 & ~(bit * 0x11)) | (pan == 64 ? bit * 0x11 : pan < 64 ? bit << 4 : bit);
@           if (v->state == 1) {
@               if (v->pos == 0) {                         /* first frame of the note: trigger     */
@                   psgKeyOn(v, env); v->pos = 1; v->length--; continue;
@               }
@               v->pos++; v->length--;                     /* pos = frames since key-on            */
@           } else if (v->type == 3) {                     /* released wave voice: software fade   */
@               v->volume = v->volume * (v->release + 230) >> 9;
@               u32 x = (pan != 64 ? v->volume << 1 : v->volume) * 5 >> 7;
@               if (x == 0) voiceStop(v); else REG_NR32 = kWaveVolume[min(x, 4)];
@               continue;
@           }
@           /* duty / noise-mode sequence: u16 n, then n bytes; the last one is held */
@           u32 duty = 0xFF;
@           if (v->inst->flags & 1) {
@               u16 *seq = (u16 *)v->psgData;
@               duty = v->pos < seq[0] ? ((u8 *)seq)[2 + v->pos] : ((u8 *)seq)[1 + seq[0]];
@           }
@           switch (v->type) {
@           case 1: if (env == 8) { if (v->inst->sweep == 8) REG_SOUND1CNT_X = f; }   /* no sweep: glide */
@                   else { REG_NR12 = env; REG_SOUND1CNT_X = f | 0x8000; }
@                   REG_NR11 &= 0xC0; if (duty != 0xFF) REG_NR11 = duty << 6; break;
@           case 2: if (env == 8) REG_SOUND2CNT_H = f;
@                   else { REG_NR22 = env; REG_SOUND2CNT_H = f | 0x8000; }
@                   REG_NR21 &= 0xC0; if (duty != 0xFF) REG_NR21 = duty << 6; break;
@           case 3: REG_SOUND3CNT_X = (REG_SOUND3CNT_X & 0x4000) | f;
@                   if (env != 8) REG_NR32 = kWaveVolume[env]; break;
@           case 4: if (env != 8) { REG_NR42 = env; REG_NR44 = 0x80; }
@                   if (duty == 0xFF) REG_NR43 = (REG_NR43 & 8) | noiseDivider(f);
@                   else REG_NR43 = noiseDivider(f) | (duty ? 8 : 0);        /* duty != 0: 7-bit LFSR */
@                   break;
@           }
@       }
@   }
@ ======================================================================================
	.global psgUpdate
	.thumb_func
psgUpdate:
	push	{r4, r5, r6, r7, lr}
	mov	r7, sl
	mov	r6, sb
	mov	r5, r8
	push	{r5, r6, r7}
	movs	r0, #0
	mov	sl, r0
.L080E907E:
	mov	r1, sl
	lsls	r0, r1, #4
	subs	r0, r0, r1
	lsls	r0, r0, #3
	ldr	r1, .P080E90A0	@ =gPsgVoices
	adds	r4, r0, r1
	ldrb	r0, [r4, #1]
	cmp	r0, #1
	bne	.L080E90A4
	ldrh	r0, [r4, #0x18]
	cmp	r0, #0
	bne	.L080E90A4
	adds	r0, r4, #0
	bl	noteOff
	b	.L080E90C2
	.hword 0x0000
.P080E90A0:	.word gPsgVoices
.L080E90A4:
	ldr	r0, [r4, #4]
	cmp	r0, #0
	beq	.L080E90C2
	ldr	r0, [r0, #8]
	cmp	r0, #0
	beq	.L080E90C2
	adds	r0, #0x3c
	ldrb	r1, [r0]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L080E90C2
	adds	r0, r4, #0
	bl	noteOff
.L080E90C2:
	ldrb	r0, [r4, #1]
	cmp	r0, #0
	bne	.L080E90CA
	b	.L080E9308
.L080E90CA:
	cmp	r0, #1
	bne	.L080E90EC
	adds	r0, r4, #0
	bl	voicePitch
	adds	r6, r0, #0
	str	r6, [r4, #0x10]
	ldrb	r0, [r4, #0x1b]
	cmp	r0, #0
	beq	.L080E90E2
	ldrb	r0, [r4, #0x1c]
	b	.L080E90E8
.L080E90E2:
	ldr	r0, [r4, #4]
	adds	r0, #0x4b
	ldrb	r0, [r0]
.L080E90E8:
	mov	r8, r0
	b	.L080E90F2
.L080E90EC:
	ldr	r6, [r4, #0x10]
	ldrb	r2, [r4, #0x1c]
	mov	r8, r2
.L080E90F2:
	movs	r0, #0x40
	mov	r3, r8
	eors	r0, r3
	rsbs	r1, r0, #0
	orrs	r1, r0
	lsrs	r1, r1, #0x1f
	adds	r0, r4, #0
	bl	psgEnvelope
	lsls	r0, r0, #0x18
	lsrs	r7, r0, #0x18
	ldr	r0, .P080E9138	@ =REG_NR51
	mov	ip, r0
	ldrb	r0, [r4]
	subs	r0, #1
	lsls	r0, r0, #0x18
	lsrs	r3, r0, #0x18
	mov	sb, r3
	movs	r5, #0x11
	lsls	r5, r3
	mvns	r0, r5
	lsls	r0, r0, #0x18
	lsrs	r2, r0, #0x18
	adds	r1, r2, #0
	mov	r0, r8
	cmp	r0, #0x40
	bne	.L080E913C
	mov	r3, ip
	ldrb	r1, [r3]
	adds	r0, r2, #0
	ands	r0, r1
	orrs	r0, r5
	strb	r0, [r3]
	b	.L080E9166
	.hword 0x0000
.P080E9138:	.word REG_NR51
.L080E913C:
	mov	r0, r8
	cmp	r0, #0x3f
	bhi	.L080E9156
	mov	r1, ip
	ldrb	r0, [r1]
	adds	r1, r2, #0
	ands	r1, r0
	movs	r0, #0x10
	lsls	r0, r3
	orrs	r1, r0
	mov	r2, ip
	strb	r1, [r2]
	b	.L080E9166
.L080E9156:
	mov	r3, ip
	ldrb	r0, [r3]
	ands	r1, r0
	movs	r0, #1
	mov	r2, sb
	lsls	r0, r2
	orrs	r1, r0
	strb	r1, [r3]
.L080E9166:
	ldrb	r5, [r4, #1]
	cmp	r5, #1
	bne	.L080E9190
	ldr	r0, [r4, #0x60]
	cmp	r0, #0
	bne	.L080E9184
	adds	r0, r4, #0
	adds	r1, r7, #0
	bl	psgKeyOn
	str	r5, [r4, #0x60]
	ldrh	r0, [r4, #0x18]
	subs	r0, #1
	strh	r0, [r4, #0x18]
	b	.L080E9308
.L080E9184:
	adds	r0, #1
	str	r0, [r4, #0x60]
	ldrh	r0, [r4, #0x18]
	subs	r0, #1
	strh	r0, [r4, #0x18]
	b	.L080E91E0
.L080E9190:
	ldrb	r0, [r4]
	cmp	r0, #3
	bne	.L080E91E0
	adds	r0, r4, #0
	adds	r0, #0x58
	ldrb	r0, [r0]
	adds	r0, #0xe6
	ldr	r1, [r4, #0x14]
	muls	r0, r1, r0
	lsrs	r0, r0, #9
	str	r0, [r4, #0x14]
	adds	r1, r0, #0
	mov	r3, r8
	cmp	r3, #0x40
	beq	.L080E91B0
	lsls	r1, r1, #1
.L080E91B0:
	lsls	r0, r1, #2
	adds	r1, r0, r1
	lsrs	r1, r1, #7
	cmp	r1, #0
	beq	.L080E91D8
	cmp	r1, #4
	bls	.L080E91C0
	movs	r1, #4
.L080E91C0:
	lsls	r1, r1, #0x18
	lsrs	r1, r1, #0x18
	ldr	r2, .P080E91D0	@ =REG_NR32
	ldr	r0, .P080E91D4	@ =kWaveVolume
	adds	r1, r1, r0
	ldrb	r0, [r1]
	strb	r0, [r2]
	b	.L080E9308
.P080E91D0:	.word REG_NR32
.P080E91D4:	.word kWaveVolume
.L080E91D8:
	adds	r0, r4, #0
	bl	voiceStop
	b	.L080E9308
.L080E91E0:
	ldr	r2, [r4, #0x54]
	ldrb	r1, [r2, #1]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L080E9202
	ldr	r0, [r4, #0x64]
	ldrh	r3, [r0]
	ldr	r1, [r4, #0x60]
	cmp	r1, r3
	bhs	.L080E91FC
	adds	r0, r0, r1
	ldrb	r5, [r0, #2]
	b	.L080E9204
.L080E91FC:
	adds	r0, r3, r0
	ldrb	r5, [r0, #1]
	b	.L080E9204
.L080E9202:
	movs	r5, #0xff
.L080E9204:
	ldrb	r0, [r4]
	cmp	r0, #2
	beq	.L080E9254
	cmp	r0, #2
	bgt	.L080E9214
	cmp	r0, #1
	beq	.L080E921E
	b	.L080E9308
.L080E9214:
	cmp	r0, #3
	beq	.L080E9294
	cmp	r0, #4
	beq	.L080E92BC
	b	.L080E9308
.L080E921E:
	cmp	r7, #8
	beq	.L080E923C
	ldr	r0, .P080E9234	@ =REG_NR12
	strb	r7, [r0]
	ldr	r1, .P080E9238	@ =REG_SOUND1CNT_X
	movs	r2, #0x80
	lsls	r2, r2, #8
	adds	r0, r2, #0
	orrs	r6, r0
	strh	r6, [r1]
	b	.L080E9246
.P080E9234:	.word REG_NR12
.P080E9238:	.word REG_SOUND1CNT_X
.L080E923C:
	ldrb	r0, [r2, #8]
	cmp	r0, #8
	bne	.L080E9246
	ldr	r0, .P080E924C	@ =REG_SOUND1CNT_X
	strh	r6, [r0]
.L080E9246:
	ldr	r2, .P080E9250	@ =REG_NR11
	b	.L080E927A
	.hword 0x0000
.P080E924C:	.word REG_SOUND1CNT_X
.P080E9250:	.word REG_NR11
.L080E9254:
	cmp	r7, #8
	beq	.L080E9274
	ldr	r0, .P080E926C	@ =REG_NR22
	strb	r7, [r0]
	ldr	r1, .P080E9270	@ =REG_SOUND2CNT_H
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r0, r3, #0
	orrs	r6, r0
	strh	r6, [r1]
	b	.L080E9278
	.hword 0x0000
.P080E926C:	.word REG_NR22
.P080E9270:	.word REG_SOUND2CNT_H
.L080E9274:
	ldr	r0, .P080E928C	@ =REG_SOUND2CNT_H
	strh	r6, [r0]
.L080E9278:
	ldr	r2, .P080E9290	@ =REG_NR21
.L080E927A:
	ldrb	r1, [r2]
	movs	r0, #0xc0
	ands	r0, r1
	strb	r0, [r2]
	cmp	r5, #0xff
	beq	.L080E9308
	lsls	r0, r5, #6
	strb	r0, [r2]
	b	.L080E9308
.P080E928C:	.word REG_SOUND2CNT_H
.P080E9290:	.word REG_NR21
.L080E9294:
	ldr	r0, .P080E92B4	@ =REG_SOUND3CNT_X
	ldrh	r1, [r0]
	movs	r3, #0x80
	lsls	r3, r3, #7
	adds	r2, r3, #0
	ands	r1, r2
	orrs	r1, r6
	strh	r1, [r0]
	cmp	r7, #8
	beq	.L080E9308
	subs	r0, #1
	ldr	r1, .P080E92B8	@ =kWaveVolume
	adds	r1, r7, r1
	ldrb	r1, [r1]
	strb	r1, [r0]
	b	.L080E9308
.P080E92B4:	.word REG_SOUND3CNT_X
.P080E92B8:	.word kWaveVolume
.L080E92BC:
	cmp	r7, #8
	beq	.L080E92CA
	ldr	r0, .P080E92E8	@ =REG_NR42
	strb	r7, [r0]
	ldr	r1, .P080E92EC	@ =REG_NR44
	movs	r0, #0x80
	strb	r0, [r1]
.L080E92CA:
	cmp	r5, #0xff
	beq	.L080E92F4
	ldr	r4, .P080E92F0	@ =REG_NR43
	lsls	r0, r6, #0x10
	lsrs	r0, r0, #0x10
	bl	noiseDivider
	lsls	r0, r0, #0x18
	lsrs	r1, r0, #0x18
	cmp	r5, #0
	beq	.L080E92E4
	movs	r0, #8
	orrs	r1, r0
.L080E92E4:
	strb	r1, [r4]
	b	.L080E9308
.P080E92E8:	.word REG_NR42
.P080E92EC:	.word REG_NR44
.P080E92F0:	.word REG_NR43
.L080E92F4:
	lsls	r0, r6, #0x10
	lsrs	r0, r0, #0x10
	bl	noiseDivider
	ldr	r3, .P080E9324	@ =REG_NR43
	ldrb	r2, [r3]
	movs	r1, #8
	ands	r1, r2
	orrs	r1, r0
	strb	r1, [r3]
.L080E9308:
	movs	r0, #1
	add	sl, r0
	mov	r1, sl
	cmp	r1, #3
	bgt	.L080E9314
	b	.L080E907E
.L080E9314:
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	sb, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080E9324:	.word REG_NR43

@ ======================================================================================
@ noteOn   (080E9328)
@
@   /* Sequencer note event.  len = note length in ticks * 150. */
@   void noteOn(Track *t, u32 key, u32 vel, u32 len)
@   {
@       Player *p = t->player;
@       NoteInfo ni;
@       if (t->mute) return;
@       u8 k = key + t->transpose;
@       instLookup(t, k, &ni);
@       u32 frames = len / ((ni.inst->flags & 0x10) ? p->tempo : p->tempo + p->tempoOfs);
@       Voice *v;
@       if (!t->hold || !(v = t->voices)) {                /* tie (C5): keep the running voice      */
@           v = voiceAlloc(kVoiceForType[ni.inst->type], t->priority);   /* {0,1,2,3,4}            */
@           if (!v) return;
@           trackAddVoice(t, v);
@           v->key = key; v->pos = 0;
@           v->lfoParams = &t->lfoDelay; v->lfoPhase = 0; v->lfoDelay = t->lfoDelay;
@           v->envTable = ni.env; v->envLevel = 0; v->envTarget = 0; v->envCount = 0; v->envIndex = -1;
@           v->release = ni.inst->release;
@           v->inst = ni.inst;
@       }
@       v->fixedPan = ni.isKit;
@       if (ni.isKit) { k = 48; v->pan = ni.kitPan; }      /* kits play at the root key            */
@       else if (ni.isSampleKit) k = 48;
@       v->velocity = vel; v->volume = 0; v->length = frames;
@       v->echo = t->echo;
@       v->freq = keyToFreq(v, k, ni.inst->rootKey);
@       if (!t->portaOn)
@           gameMemClear(&v->portaDelay, 20);              /* no portamento                         */
@       else {
@           s32 from = keyToFreq(v, t->portaKey, ni.inst->rootKey);
@           v->portaDelay = t->portaDelay;
@           v->portaCount = t->portaLen * frames >> 8;     /* portaLen/256 of the note              */
@           if (t->portaMode & 2) v->portaTotal = from - v->freq;           /* slide away to portaKey */
@           else { v->portaTotal = v->freq - from; v->freq = from; }        /* slide from portaKey    */
@           v->portaStep = v->portaTotal / v->portaCount;  /* __divsi3; /0 if portaCount == 0        */
@           if (t->portaMode & 4) t->portaKey = k;         /* chain: next note slides from this one  */
@           else t->portaOn = 0;                           /* one note only                          */
@           v->portaOfs = 0;
@       }
@       if (v->type == 0)
@           v->sample = (SampleHdr *)(t->sampleBank + ((u32 *)t->sampleBank)[ni.inst->data]);
@       else if (v->type == 3 || (ni.inst->flags & 1))
@           v->psgData = v->type == 3 ? ni.wave : ni.duty;
@       else
@           *(u8 *)&v->psgData = ni.inst->data;            /* fixed duty / noise mode               */
@       if (frames == 0) noteOff(v);
@   }
@ ======================================================================================
	.global noteOn
	.thumb_func
noteOn:
	push	{r4, r5, r6, r7, lr}
	mov	r7, sl
	mov	r6, sb
	mov	r5, r8
	push	{r5, r6, r7}
	sub	sp, #0x14
	adds	r5, r0, #0
	mov	r8, r3
	lsls	r1, r1, #0x18
	lsrs	r7, r1, #0x18
	lsls	r2, r2, #0x18
	lsrs	r2, r2, #0x18
	mov	sl, r2
	ldr	r4, [r5, #8]
	mov	sb, r7
	adds	r0, #0x4a
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L080E9350
	b	.L080E94E4
.L080E9350:
	adds	r0, r5, #0
	adds	r0, #0x51
	ldrb	r0, [r0]
	adds	r0, r7, r0
	lsls	r0, r0, #0x18
	lsrs	r7, r0, #0x18
	adds	r0, r5, #0
	adds	r1, r7, #0
	mov	r2, sp
	bl	instLookup
	ldr	r6, [sp]
	ldrb	r1, [r6, #1]
	movs	r0, #0x10
	ands	r0, r1
	cmp	r0, #0
	beq	.L080E9376
	ldrh	r1, [r4, #0x30]
	b	.L080E937E
.L080E9376:
	movs	r0, #0x32
	ldrsh	r1, [r4, r0]
	ldrh	r4, [r4, #0x30]
	adds	r1, r1, r4
.L080E937E:
	mov	r0, r8
	bl	__udivsi3
	mov	r8, r0
	adds	r0, r5, #0
	adds	r0, #0x49
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L080E939A
	ldr	r0, [r5, #0xc]
	cmp	r0, #0
	beq	.L080E939A
	adds	r4, r0, #0
	b	.L080E93F0
.L080E939A:
	ldr	r1, .P080E9408	@ =kVoiceForType
	ldrb	r0, [r6]
	adds	r0, r0, r1
	ldrb	r0, [r0]
	adds	r1, r5, #0
	adds	r1, #0x52
	ldrb	r1, [r1]
	bl	voiceAlloc
	adds	r4, r0, #0
	cmp	r4, #0
	bne	.L080E93B4
	b	.L080E94E4
.L080E93B4:
	adds	r0, r5, #0
	adds	r1, r4, #0
	bl	trackAddVoice
	movs	r1, #0
	mov	r0, sb
	strb	r0, [r4, #9]
	str	r1, [r4, #0x60]
	adds	r0, r5, #0
	adds	r0, #0x10
	str	r0, [r4, #0x28]
	str	r1, [r4, #0x20]
	ldrh	r0, [r5, #0x10]
	str	r0, [r4, #0x24]
	ldr	r0, [sp, #4]
	str	r0, [r4, #0x4c]
	str	r1, [r4, #0x40]
	str	r1, [r4, #0x44]
	adds	r0, r4, #0
	adds	r0, #0x48
	strh	r1, [r0]
	adds	r1, r4, #0
	adds	r1, #0x50
	movs	r0, #0xff
	strb	r0, [r1]
	ldrb	r1, [r6, #6]
	adds	r0, r4, #0
	adds	r0, #0x58
	strb	r1, [r0]
	str	r6, [r4, #0x54]
.L080E93F0:
	mov	r0, sp
	ldrb	r0, [r0, #0x11]
	strb	r0, [r4, #0x1b]
	lsls	r0, r0, #0x18
	cmp	r0, #0
	beq	.L080E940C
	movs	r7, #0x30
	mov	r0, sp
	ldrb	r0, [r0, #0x10]
	strb	r0, [r4, #0x1c]
	b	.L080E9416
	.hword 0x0000
.P080E9408:	.word kVoiceForType
.L080E940C:
	mov	r0, sp
	ldrb	r0, [r0, #0x12]
	cmp	r0, #0
	beq	.L080E9416
	movs	r7, #0x30
.L080E9416:
	movs	r0, #0
	mov	r1, sl
	strb	r1, [r4, #0xa]
	str	r0, [r4, #0x14]
	mov	r0, r8
	strh	r0, [r4, #0x18]
	adds	r0, r5, #0
	adds	r0, #0x4c
	ldrb	r0, [r0]
	strb	r0, [r4, #0x1a]
	ldrb	r2, [r6, #7]
	adds	r0, r4, #0
	adds	r1, r7, #0
	bl	keyToFreq
	str	r0, [r4, #0xc]
	ldrb	r0, [r5, #0x1c]
	cmp	r0, #0
	bne	.L080E9448
	adds	r0, r4, #0
	adds	r0, #0x2c
	movs	r1, #0x14
	bl	MemClear
	b	.L080E94A2
.L080E9448:
	ldrb	r1, [r5, #0x1e]
	ldrb	r2, [r6, #7]
	adds	r0, r4, #0
	bl	keyToFreq
	adds	r2, r0, #0
	ldrh	r0, [r5, #0x20]
	str	r0, [r4, #0x2c]
	ldrh	r0, [r5, #0x22]
	mov	r1, r8
	muls	r1, r0, r1
	adds	r0, r1, #0
	lsrs	r0, r0, #8
	str	r0, [r4, #0x30]
	ldrb	r1, [r5, #0x1d]
	movs	r0, #2
	ands	r0, r1
	cmp	r0, #0
	beq	.L080E9476
	ldr	r0, [r4, #0xc]
	subs	r0, r2, r0
	str	r0, [r4, #0x38]
	b	.L080E947E
.L080E9476:
	ldr	r0, [r4, #0xc]
	subs	r0, r0, r2
	str	r0, [r4, #0x38]
	str	r2, [r4, #0xc]
.L080E947E:
	ldr	r0, [r4, #0x38]
	str	r0, [r4, #0x3c]
	ldr	r1, [r4, #0x30]
	bl	__divsi3
	str	r0, [r4, #0x3c]
	ldrb	r1, [r5, #0x1d]
	movs	r0, #4
	ands	r0, r1
	lsls	r0, r0, #0x18
	lsrs	r0, r0, #0x18
	cmp	r0, #0
	beq	.L080E949C
	strb	r7, [r5, #0x1e]
	b	.L080E949E
.L080E949C:
	strb	r0, [r5, #0x1c]
.L080E949E:
	movs	r0, #0
	str	r0, [r4, #0x34]
.L080E94A2:
	ldrb	r0, [r4]
	cmp	r0, #0
	bne	.L080E94B8
	ldrh	r0, [r6, #2]
	ldr	r1, [r5, #4]
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r0, [r0]
	adds	r1, r1, r0
	str	r1, [r4, #0x5c]
	b	.L080E94D8
.L080E94B8:
	cmp	r0, #3
	beq	.L080E94D4
	ldrb	r1, [r6, #1]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L080E94CA
	ldr	r0, [sp, #8]
	b	.L080E94D6
.L080E94CA:
	ldrh	r1, [r6, #2]
	adds	r0, r4, #0
	adds	r0, #0x64
	strb	r1, [r0]
	b	.L080E94D8
.L080E94D4:
	ldr	r0, [sp, #0xc]
.L080E94D6:
	str	r0, [r4, #0x64]
.L080E94D8:
	mov	r0, r8
	cmp	r0, #0
	bne	.L080E94E4
	adds	r0, r4, #0
	bl	noteOff
.L080E94E4:
	add	sp, #0x14
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	sb, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ noteOff   (080E94F4)
@
@   void noteOff(Voice *v)
@   {
@       if (v->state != 1 || v->track->hold) return;
@       if (v->type == 0) {                                /* sampled: re-sort as 'released'        */
@           voiceListRemove(v, &gActiveVoices); v->state = 2; voiceListInsertActive(v);
@       } else if (v->type == 3) v->state = 2;             /* wave: faded by psgUpdate              */
@       else {                                             /* squares, noise: hardware envelope     */
@           u8 env = (v->release >> 5) ? (v->volume & 15) << 4 | v->release >> 5 : 0;   /* decrease */
@           switch (v->type) {
@           case 1: REG_NR12 = env; REG_SOUND1CNT_X = v->outFreq | 0x8000; REG_NR11 &= 0xC0; break;
@           case 2: REG_NR22 = env; REG_SOUND2CNT_H = v->outFreq | 0x8000; REG_NR21 &= 0xC0; break;
@           case 4: REG_NR42 = env; REG_NR44 = 0x80; break;
@           }
@           v->state = 0;                                  /* the channel is free again at once     */
@       }
@       if (!v->fixedPan) v->pan = v->track->pan;          /* freeze the pan for the release        */
@       trackRemoveVoice(v->track, v);
@   }
@ ======================================================================================
	.global noteOff
	.thumb_func
noteOff:
	push	{r4, lr}
	adds	r4, r0, #0
	ldrb	r0, [r4, #1]
	cmp	r0, #1
	bne	.L080E95D2
	ldr	r0, [r4, #4]
	adds	r0, #0x49
	ldrb	r0, [r0]
	cmp	r0, #0
	bne	.L080E95D2
	ldrb	r3, [r4]
	cmp	r3, #0
	bne	.L080E9528
	ldr	r1, .P080E9524	@ =gActiveVoices
	adds	r0, r4, #0
	bl	voiceListRemove
	movs	r0, #2
	strb	r0, [r4, #1]
	adds	r0, r4, #0
	bl	voiceListInsertActive
	b	.L080E95BA
	.hword 0x0000
.P080E9524:	.word gActiveVoices
.L080E9528:
	ldrh	r2, [r4, #0x10]
	adds	r0, r4, #0
	adds	r0, #0x58
	ldrb	r1, [r0]
	cmp	r3, #3
	bne	.L080E9538
	movs	r0, #2
	b	.L080E95B8
.L080E9538:
	lsrs	r1, r1, #5
	cmp	r1, #0
	bne	.L080E9542
	movs	r1, #0
	b	.L080E954C
.L080E9542:
	ldr	r0, [r4, #0x14]
	lsls	r0, r0, #4
	orrs	r1, r0
	lsls	r0, r1, #0x18
	lsrs	r1, r0, #0x18
.L080E954C:
	ldrb	r0, [r4]
	cmp	r0, #2
	beq	.L080E9584
	cmp	r0, #2
	bgt	.L080E955C
	cmp	r0, #1
	beq	.L080E9562
	b	.L080E95B6
.L080E955C:
	cmp	r0, #4
	beq	.L080E95AC
	b	.L080E95B6
.L080E9562:
	ldr	r0, .P080E9578	@ =REG_NR12
	strb	r1, [r0]
	ldr	r1, .P080E957C	@ =REG_SOUND1CNT_X
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r0, r3, #0
	orrs	r2, r0
	strh	r2, [r1]
	ldr	r2, .P080E9580	@ =REG_NR11
	b	.L080E9596
	.hword 0x0000
.P080E9578:	.word REG_NR12
.P080E957C:	.word REG_SOUND1CNT_X
.P080E9580:	.word REG_NR11
.L080E9584:
	ldr	r0, .P080E95A0	@ =REG_NR22
	strb	r1, [r0]
	ldr	r1, .P080E95A4	@ =REG_SOUND2CNT_H
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r0, r3, #0
	orrs	r2, r0
	strh	r2, [r1]
	ldr	r2, .P080E95A8	@ =REG_NR21
.L080E9596:
	ldrb	r1, [r2]
	movs	r0, #0xc0
	ands	r0, r1
	strb	r0, [r2]
	b	.L080E95B6
.P080E95A0:	.word REG_NR22
.P080E95A4:	.word REG_SOUND2CNT_H
.P080E95A8:	.word REG_NR21
.L080E95AC:
	ldr	r0, .P080E95D8	@ =REG_NR42
	strb	r1, [r0]
	ldr	r1, .P080E95DC	@ =REG_NR44
	movs	r0, #0x80
	strb	r0, [r1]
.L080E95B6:
	movs	r0, #0
.L080E95B8:
	strb	r0, [r4, #1]
.L080E95BA:
	ldrb	r0, [r4, #0x1b]
	ldr	r1, [r4, #4]
	cmp	r0, #0
	bne	.L080E95CA
	adds	r0, r1, #0
	adds	r0, #0x4b
	ldrb	r0, [r0]
	strb	r0, [r4, #0x1c]
.L080E95CA:
	adds	r0, r1, #0
	adds	r1, r4, #0
	bl	trackRemoveVoice
.L080E95D2:
	pop	{r4}
	pop	{r0}
	bx	r0
.P080E95D8:	.word REG_NR42
.P080E95DC:	.word REG_NR44

@ ======================================================================================
@ voiceStop   (080E95E0)
@
@   void voiceStop(Voice *v)            /* immediate silence */
@   {
@       if (v->state == 0) return;
@       switch (v->type) {
@       case 0: voiceListRemove(v, &gActiveVoices); voiceListPush(v, &gFreeVoices); break;
@       case 1: REG_NR12 = 8; REG_NR14 = 0xC0; break;      /* volume 0, restart with length stop    */
@       case 2: REG_NR22 = 8; REG_NR24 = 0xC0; break;
@       case 3: REG_NR30 = 0; break;
@       case 4: REG_NR42 = 8; REG_NR44 = 0xC0; break;
@       }
@       trackRemoveVoice(v->track, v);
@       v->state = 0;
@   }
@ ======================================================================================
	.global voiceStop
	.thumb_func
voiceStop:
	push	{r4, lr}
	adds	r4, r0, #0
	ldrb	r0, [r4, #1]
	cmp	r0, #0
	beq	.L080E966C
	ldrb	r0, [r4]
	cmp	r0, #4
	bhi	.L080E9660
	lsls	r0, r0, #2
	ldr	r1, .P080E95FC	@ =0x080E9600
	adds	r0, r0, r1
	ldr	r0, [r0]
	mov	pc, r0
	.hword 0x0000
.P080E95FC:	.word 0x080E9600
	.word .L080E9614
	.word .L080E9630
	.word .L080E9640
	.word .L080E9648
	.word .L080E9654
.L080E9614:
	ldr	r1, .P080E9628	@ =gActiveVoices
	adds	r0, r4, #0
	bl	voiceListRemove
	ldr	r1, .P080E962C	@ =gFreeVoices
	adds	r0, r4, #0
	bl	voiceListPush
	b	.L080E9660
	.hword 0x0000
.P080E9628:	.word gActiveVoices
.P080E962C:	.word gFreeVoices
.L080E9630:
	ldr	r1, .P080E963C	@ =REG_NR12
	movs	r0, #8
	strb	r0, [r1]
	adds	r1, #2
	b	.L080E965C
	.hword 0x0000
.P080E963C:	.word REG_NR12
.L080E9640:
	ldr	r1, .P080E9644	@ =REG_NR22
	b	.L080E9656
.P080E9644:	.word REG_NR22
.L080E9648:
	ldr	r1, .P080E9650	@ =REG_NR30
	movs	r0, #0
	b	.L080E965E
	.hword 0x0000
.P080E9650:	.word REG_NR30
.L080E9654:
	ldr	r1, .P080E9674	@ =REG_NR42
.L080E9656:
	movs	r0, #8
	strb	r0, [r1]
	adds	r1, #4
.L080E965C:
	movs	r0, #0xc0
.L080E965E:
	strb	r0, [r1]
.L080E9660:
	ldr	r0, [r4, #4]
	adds	r1, r4, #0
	bl	trackRemoveVoice
	movs	r0, #0
	strb	r0, [r4, #1]
.L080E966C:
	pop	{r4}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080E9674:	.word REG_NR42

@ ======================================================================================
@ psgKeyOn   (080E9678)
@
@   void psgKeyOn(Voice *v, u32 env)
@   {
@       u8 duty = (v->inst->flags & 1) ? v->psgData[2] : (u8)(u32)v->psgData;
@       switch (v->type) {
@       case 1: REG_NR10 = v->inst->sweep; REG_SOUND1CNT_X = v->freq | 0x8000;
@               REG_NR12 = env; REG_NR11 = duty << 6; REG_SOUND1CNT_X = v->freq | 0x8000; break;
@       case 2: REG_NR22 = env; REG_SOUND2CNT_H = v->freq | 0x8000;
@               REG_NR21 = (u8)(u32)v->psgData << 6;       /* BUG: ignores a duty sequence          */
@               break;
@       case 3: if (v->psgData != gLastWave) {             /* upload the 16-byte wave               */
@                   REG_NR30 = 0; CpuSet(v->psgData, REG_WAVE_RAM, 8); gLastWave = v->psgData;
@               }
@               REG_NR30 = 0xC0;                           /* play the bank just written            */
@               REG_SOUND3CNT_X = v->freq | 0x8000; REG_NR32 = kWaveVolume[env]; REG_NR31 = 0; break;
@       case 4: REG_NR42 = env; REG_NR43 = noiseDivider(v->freq) | (duty ? 8 : 0);
@               REG_NR44 = 0x80; REG_NR41 = 0; break;
@       }
@   }
@ ======================================================================================
	.global psgKeyOn
	.thumb_func
psgKeyOn:
	push	{r4, r5, r6, lr}
	adds	r4, r0, #0
	lsls	r1, r1, #0x18
	lsrs	r5, r1, #0x18
	ldrb	r3, [r4]
	cmp	r3, #2
	beq	.L080E96FC
	cmp	r3, #2
	bgt	.L080E9690
	cmp	r3, #1
	beq	.L080E969A
	b	.L080E97C8
.L080E9690:
	cmp	r3, #3
	beq	.L080E9728
	cmp	r3, #4
	beq	.L080E977C
	b	.L080E97C8
.L080E969A:
	ldr	r1, .P080E96C8	@ =REG_NR10
	ldr	r0, [r4, #0x54]
	ldrb	r0, [r0, #8]
	strb	r0, [r1]
	ldr	r2, .P080E96CC	@ =REG_SOUND1CNT_X
	ldr	r0, [r4, #0xc]
	movs	r6, #0x80
	lsls	r6, r6, #8
	adds	r1, r6, #0
	orrs	r0, r1
	strh	r0, [r2]
	ldr	r0, .P080E96D0	@ =REG_NR12
	strb	r5, [r0]
	ldr	r0, [r4, #0x54]
	ldrb	r0, [r0, #1]
	ands	r3, r0
	cmp	r3, #0
	beq	.L080E96D8
	ldr	r1, .P080E96D4	@ =REG_NR11
	ldr	r0, [r4, #0x64]
	ldrb	r0, [r0, #2]
	b	.L080E96E0
	.hword 0x0000
.P080E96C8:	.word REG_NR10
.P080E96CC:	.word REG_SOUND1CNT_X
.P080E96D0:	.word REG_NR12
.P080E96D4:	.word REG_NR11
.L080E96D8:
	ldr	r1, .P080E96F4	@ =REG_NR11
	adds	r0, r4, #0
	adds	r0, #0x64
	ldrb	r0, [r0]
.L080E96E0:
	lsls	r0, r0, #6
	strb	r0, [r1]
	ldr	r0, .P080E96F8	@ =REG_SOUND1CNT_X
	ldr	r1, [r4, #0xc]
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r2, r3, #0
	orrs	r1, r2
	strh	r1, [r0]
	b	.L080E97C8
.P080E96F4:	.word REG_NR11
.P080E96F8:	.word REG_SOUND1CNT_X
.L080E96FC:
	ldr	r0, .P080E971C	@ =REG_NR22
	strb	r5, [r0]
	ldr	r2, .P080E9720	@ =REG_SOUND2CNT_H
	ldr	r0, [r4, #0xc]
	movs	r6, #0x80
	lsls	r6, r6, #8
	adds	r1, r6, #0
	orrs	r0, r1
	strh	r0, [r2]
	ldr	r1, .P080E9724	@ =REG_NR21
	adds	r0, r4, #0
	adds	r0, #0x64
	ldrb	r0, [r0]
	lsls	r0, r0, #6
	b	.L080E97C6
	.hword 0x0000
.P080E971C:	.word REG_NR22
.P080E9720:	.word REG_SOUND2CNT_H
.P080E9724:	.word REG_NR21
.L080E9728:
	ldr	r6, .P080E9768	@ =gLastWave
	ldr	r1, [r4, #0x64]
	ldr	r0, [r6]
	cmp	r1, r0
	beq	.L080E9746
	ldr	r1, .P080E976C	@ =REG_NR30
	movs	r0, #0
	strb	r0, [r1]
	ldr	r0, [r4, #0x64]
	adds	r1, #0x20
	movs	r2, #8
	bl	CpuSet
	ldr	r0, [r4, #0x64]
	str	r0, [r6]
.L080E9746:
	ldr	r1, .P080E976C	@ =REG_NR30
	movs	r0, #0xc0
	strb	r0, [r1]
	ldr	r2, .P080E9770	@ =REG_SOUND3CNT_X
	ldr	r0, [r4, #0xc]
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r1, r3, #0
	orrs	r0, r1
	strh	r0, [r2]
	ldr	r1, .P080E9774	@ =REG_NR32
	ldr	r0, .P080E9778	@ =kWaveVolume
	adds	r0, r5, r0
	ldrb	r0, [r0]
	strb	r0, [r1]
	subs	r1, #1
	b	.L080E97C4
.P080E9768:	.word gLastWave
.P080E976C:	.word REG_NR30
.P080E9770:	.word REG_SOUND3CNT_X
.P080E9774:	.word REG_NR32
.P080E9778:	.word kWaveVolume
.L080E977C:
	ldr	r0, .P080E979C	@ =REG_NR42
	strb	r5, [r0]
	ldr	r0, [r4, #0x54]
	ldrb	r1, [r0, #1]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L080E97A0
	ldrh	r0, [r4, #0xc]
	bl	noiseDivider
	lsls	r0, r0, #0x18
	lsrs	r1, r0, #0x18
	ldr	r0, [r4, #0x64]
	ldrb	r0, [r0, #2]
	b	.L080E97B0
.P080E979C:	.word REG_NR42
.L080E97A0:
	ldrh	r0, [r4, #0xc]
	bl	noiseDivider
	lsls	r0, r0, #0x18
	lsrs	r1, r0, #0x18
	adds	r0, r4, #0
	adds	r0, #0x64
	ldrb	r0, [r0]
.L080E97B0:
	cmp	r0, #0
	beq	.L080E97B8
	movs	r0, #8
	orrs	r1, r0
.L080E97B8:
	ldr	r0, .P080E97D0	@ =REG_NR43
	strb	r1, [r0]
	ldr	r1, .P080E97D4	@ =REG_NR44
	movs	r0, #0x80
	strb	r0, [r1]
	subs	r1, #5
.L080E97C4:
	movs	r0, #0
.L080E97C6:
	strb	r0, [r1]
.L080E97C8:
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080E97D0:	.word REG_NR43
.P080E97D4:	.word REG_NR44

@ ======================================================================================
@ voiceAlloc   (080E97D8)
@
@   /* type 0: take a free sampled voice, or steal the head of the active list (a released
@      voice, or the lowest-priority playing one if its priority is <= prio).
@      type 1..4: the PSG channel, if it is idle, released, or playing at priority <= prio. */
@   Voice *voiceAlloc(u32 type, u32 prio)
@   {
@       Voice *v;
@       if (type == 0) {
@           if (!(v = gFreeVoices)) {
@               v = gActiveVoices;
@               if (!v || (v->state == 1 && prio < v->priority)) return NULL;
@               voiceStop(v);                              /* moves it to gFreeVoices               */
@           }
@           voiceListRemove(v, &gFreeVoices);
@           v->state = 1; v->priority = prio;
@           voiceListInsertActive(v);
@           return v;
@       }
@       v = &gPsgVoices[type - 1];
@       if (v->state == 1 && prio < v->priority) return NULL;
@       if (v->state) voiceStop(v);
@       v->state = 1; v->priority = prio;
@       return v;
@   }
@ ======================================================================================
	.global voiceAlloc
	.thumb_func
voiceAlloc:
	push	{r4, r5, lr}
	lsls	r0, r0, #0x18
	lsrs	r2, r0, #0x18
	lsls	r1, r1, #0x18
	lsrs	r5, r1, #0x18
	cmp	r2, #0
	bne	.L080E9834
	ldr	r0, .P080E97F4	@ =gFreeVoices
	ldr	r0, [r0]
	cmp	r0, #0
	beq	.L080E97F8
	adds	r4, r0, #0
	b	.L080E9814
	.hword 0x0000
.P080E97F4:	.word gFreeVoices
.L080E97F8:
	ldr	r0, .P080E982C	@ =gActiveVoices
	ldr	r1, [r0]
	cmp	r1, #0
	beq	.L080E984A
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	bne	.L080E980C
	ldrb	r0, [r1, #8]
	cmp	r5, r0
	blo	.L080E984A
.L080E980C:
	adds	r4, r1, #0
	adds	r0, r4, #0
	bl	voiceStop
.L080E9814:
	ldr	r1, .P080E9830	@ =gFreeVoices
	adds	r0, r4, #0
	bl	voiceListRemove
	movs	r0, #1
	strb	r0, [r4, #1]
	strb	r5, [r4, #8]
	adds	r0, r4, #0
	bl	voiceListInsertActive
	b	.L080E9866
	.hword 0x0000
.P080E982C:	.word gActiveVoices
.P080E9830:	.word gFreeVoices
.L080E9834:
	lsls	r0, r2, #4
	subs	r0, r0, r2
	lsls	r0, r0, #3
	ldr	r1, .P080E9850	@ =gDsVoices+0x2D0
	adds	r4, r0, r1
	ldrb	r0, [r4, #1]
	cmp	r0, #1
	bne	.L080E9854
	ldrb	r0, [r4, #8]
	cmp	r5, r0
	bhs	.L080E9854
.L080E984A:
	movs	r0, #0
	b	.L080E9868
	.hword 0x0000
.P080E9850:	.word gDsVoices+0x2D0
.L080E9854:
	ldrb	r0, [r4, #1]
	cmp	r0, #0
	beq	.L080E9860
	adds	r0, r4, #0
	bl	voiceStop
.L080E9860:
	movs	r0, #1
	strb	r0, [r4, #1]
	strb	r5, [r4, #8]
.L080E9866:
	adds	r0, r4, #0
.L080E9868:
	pop	{r4, r5}
	pop	{r1}
	bx	r1
	movs	r0, r0

@ ======================================================================================
@ trackInitAll   (080E9870)
@
@   void trackInitAll(void)
@   {
@       for (i = 0; i < 24; i++) gTracks[i].player = NULL, gTracks[i].voices = NULL;
@   }
@ ======================================================================================
	.global trackInitAll
	.thumb_func
trackInitAll:
	push	{lr}
	ldr	r0, .P080E9898	@ =gTracks
	movs	r1, #0
	adds	r0, #8
	movs	r2, #0x17
.L080E987A:
	strb	r1, [r0]
	strb	r1, [r0, #1]
	strb	r1, [r0, #2]
	strb	r1, [r0, #3]
	strb	r1, [r0, #4]
	strb	r1, [r0, #5]
	strb	r1, [r0, #6]
	strb	r1, [r0, #7]
	adds	r0, #0x54
	subs	r2, #1
	cmp	r2, #0
	bge	.L080E987A
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080E9898:	.word gTracks

@ ======================================================================================
@ trackAlloc   (080E989C)
@
@   Track *trackAlloc(void)             /* first track not owned by a player, or NULL */
@   {
@       for (Track *t = gTracks; t < &gTracks[24]; t++) if (!t->player) return t;
@       return NULL;
@   }
@ ======================================================================================
	.global trackAlloc
	.thumb_func
trackAlloc:
	push	{lr}
	ldr	r1, .P080E98B0	@ =gTracks
	ldr	r0, .P080E98B4	@ =0x0000078C
	adds	r2, r1, r0
.L080E98A4:
	ldr	r0, [r1, #8]
	cmp	r0, #0
	bne	.L080E98B8
	adds	r0, r1, #0
	b	.L080E98C0
	.hword 0x0000
.P080E98B0:	.word gTracks
.P080E98B4:	.word 0x0000078C
.L080E98B8:
	adds	r1, #0x54
	cmp	r1, r2
	ble	.L080E98A4
	movs	r0, #0
.L080E98C0:
	pop	{r1}
	bx	r1

@ ======================================================================================
@ trackStart   (080E98C4)
@
@   void trackStart(Track *t, Player *p, u8 *data)
@   {
@       if (!t) return;                                    /* no free track: silently ignored       */
@       if (t->player) trackStop(t);
@       t->wait = 0; t->hold = 0; t->mute = 0;
@       t->ptr = data; t->player = p; t->voices = NULL;
@       trackSetBank(t, 0);
@       t->pan = 64; t->lfoDelay = 0; t->lfoSpeed = 34; t->lfoDepth = 0;
@       t->portaOn = t->portaMode = t->portaKey = 0; t->portaDelay = t->portaLen = 0;
@       t->volume = 128; t->expression = 128; t->bend = 0; t->bendRange = 2; t->transpose = 0;
@       if (p->isSfx == 1) { t->priority = 12; t->echo = 127; t->noteAdvances = 1; }
@       else               { t->priority = 3;  t->echo = 0;   t->noteAdvances = 0; }
@       t->noteLen = 127; t->velocity = 127; t->restLen = 0;
@       t->sp = t->stack;
@   }
@ ======================================================================================
	.global trackStart
	.thumb_func
trackStart:
	push	{r4, r5, r6, r7, lr}
	adds	r5, r0, #0
	adds	r7, r1, #0
	adds	r6, r2, #0
	cmp	r5, #0
	beq	.L080E997A
	ldr	r0, [r5, #8]
	cmp	r0, #0
	beq	.L080E98DC
	adds	r0, r5, #0
	bl	trackStop
.L080E98DC:
	movs	r4, #0
	str	r4, [r5, #0x34]
	adds	r0, r5, #0
	adds	r0, #0x49
	strb	r4, [r0]
	adds	r0, #1
	strb	r4, [r0]
	str	r6, [r5]
	str	r7, [r5, #8]
	str	r4, [r5, #0xc]
	adds	r0, r5, #0
	movs	r1, #0
	bl	trackSetBank
	adds	r1, r5, #0
	adds	r1, #0x4b
	movs	r0, #0x40
	strb	r0, [r1]
	movs	r2, #0
	strh	r4, [r5, #0x10]
	movs	r0, #0x22
	str	r0, [r5, #0x14]
	str	r4, [r5, #0x18]
	strb	r2, [r5, #0x1c]
	strb	r2, [r5, #0x1d]
	strb	r2, [r5, #0x1e]
	strh	r4, [r5, #0x20]
	strh	r4, [r5, #0x22]
	adds	r1, #2
	movs	r0, #0x80
	strb	r0, [r1]
	adds	r1, #1
	strb	r0, [r1]
	adds	r0, r5, #0
	adds	r0, #0x4f
	strb	r2, [r0]
	adds	r1, #2
	movs	r0, #2
	strb	r0, [r1]
	adds	r0, r5, #0
	adds	r0, #0x51
	strb	r2, [r0]
	adds	r0, r7, #0
	adds	r0, #0x43
	ldrb	r3, [r0]
	cmp	r3, #1
	bne	.L080E994E
	adds	r1, #2
	movs	r0, #0xc
	strb	r0, [r1]
	subs	r1, #6
	movs	r0, #0x7f
	strb	r0, [r1]
	adds	r0, r5, #0
	adds	r0, #0x53
	strb	r3, [r0]
	b	.L080E9960
.L080E994E:
	adds	r1, r5, #0
	adds	r1, #0x52
	movs	r0, #3
	strb	r0, [r1]
	adds	r0, r5, #0
	adds	r0, #0x4c
	strb	r2, [r0]
	adds	r0, #7
	strb	r2, [r0]
.L080E9960:
	adds	r1, r5, #0
	adds	r1, #0x44
	movs	r3, #0
	movs	r2, #0x7f
	movs	r0, #0x7f
	strh	r0, [r1]
	adds	r0, r5, #0
	adds	r0, #0x48
	strb	r2, [r0]
	subs	r0, #2
	strh	r3, [r0]
	subs	r0, #0x22
	str	r0, [r5, #0x30]
.L080E997A:
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ trackReleaseAll   (080E9980)
@
@   void trackReleaseAll(Track *t)      /* key-off every voice of the track, even in hold mode */
@   {
@       if (!t) return;
@       u8 h = t->hold; t->hold = 0;
@       for (Voice *v = t->voices, *nx; v; v = nx) { nx = v->tnext; noteOff(v); }
@       t->hold = h;
@   }
@ ======================================================================================
	.global trackReleaseAll
	.thumb_func
trackReleaseAll:
	push	{r4, r5, r6, lr}
	adds	r4, r0, #0
	cmp	r4, #0
	beq	.L080E99A8
	adds	r1, r4, #0
	adds	r1, #0x49
	ldrb	r6, [r1]
	movs	r0, #0
	strb	r0, [r1]
	ldr	r0, [r4, #0xc]
	adds	r5, r1, #0
	cmp	r0, #0
	beq	.L080E99A6
.L080E999A:
	ldr	r4, [r0, #0x74]
	bl	noteOff
	adds	r0, r4, #0
	cmp	r0, #0
	bne	.L080E999A
.L080E99A6:
	strb	r6, [r5]
.L080E99A8:
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ trackStop   (080E99B0)
@
@   void trackStop(Track *t)
@   {
@       if (!t) return;
@       trackReleaseAll(t);
@       t->player = NULL;                                  /* back to the free pool                 */
@   }
@ ======================================================================================
	.global trackStop
	.thumb_func
trackStop:
	push	{r4, lr}
	adds	r4, r0, #0
	cmp	r4, #0
	beq	.L080E99C0
	bl	trackReleaseAll
	movs	r0, #0
	str	r0, [r4, #8]
.L080E99C0:
	pop	{r4}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ trackTick   (080E99C8)
@
@   /* Run one frame of a track.  Returns 0 while it plays, 2 when it ended (FF at call
@      depth 0), 1 for a NULL track or one without a player.  Time: 'wait' counts in
@      ticks*150; every frame it drops by tempo (+ tempoOfs), so tempo 150 = 1 tick/frame. */
@   u32 trackTick(Track *t)
@   {
@       Player *p;
@       if (!t || !(p = t->player)) return 1;
@       if (p->flags & PAUSED) return 0;
@       while (t->wait <= 0) {
@           u8 c = *t->ptr++;
@           if (c < 0xC0) {                                /* ---- note ----                        */
@               u32 len, vel;
@               if (c < 0x60) { len = t->noteLen; vel = t->velocity; }
@               else { t->noteLen = len = readVarLen(t); t->velocity = vel = *t->ptr++; c -= 0x60; }
@               len *= 150;
@               if (gHookNote && (p->flags44 & 1)) gHookNote(t, c, vel, len);
@               else noteOn(t, c, vel, len);
@               if (t->noteAdvances == 1) t->wait += len;
@               continue;
@           }
@           switch (c) {
@           case 0xC0: t->wait += t->restLen * 150; break;                     /* rest            */
@           case 0xC1: t->wait += (t->restLen = readVarLen(t)) * 150; break;   /* rest n          */
@           case 0xC2: t->program   = *t->ptr++; break;
@           case 0xC3: t->pan       = *t->ptr++; break;
@           case 0xC4: t->priority  = *t->ptr++; break;
@           case 0xC5: case 0xC6: trackReleaseAll(t); t->hold = (c == 0xC5); break;   /* tie on/off */
@           case 0xC7: trackSetBank(t, *t->ptr++); break;
@           case 0xC8: t->noteAdvances = 1; break;
@           case 0xC9: t->noteAdvances = 0; break;
@           case 0xCA: if (gHookCA) gHookCA(t, *t->ptr++); else t->ptr++; break;
@           case 0xD0 ... 0xDF:                                                 /* portamento      */
@               t->portaMode = c & 15; t->portaKey = t->transpose + *t->ptr++;
@               t->portaLen = *t->ptr++;
@               t->portaDelay = (c & 1) ? *t->ptr++ : 0;
@               t->portaOn = 1; break;
@           case 0xE0: t->volume     = *t->ptr++; break;
@           case 0xE1: t->bend       = *t->ptr++; break;
@           case 0xE2: t->bendRange  = *t->ptr++; break;
@           case 0xE3: t->echo       = *t->ptr++; break;
@           case 0xE4: p->tempo      = readVarLen(t); break;
@           case 0xE5: t->lfoDelay   = *t->ptr++; break;
@           case 0xE6: t->lfoSpeed   = *t->ptr++; break;
@           case 0xE7: t->lfoDepth   = *t->ptr++; break;
@           case 0xE8: t->portaOn    = 0; break;
@           case 0xE9: t->transpose  = *t->ptr++; break;
@           case 0xEA: p->songVolume = *t->ptr++; break;
@           case 0xF0: t->ptr = p->base + read16(t); break;                     /* jump            */
@           case 0xF4: { u16 o = read16(t); *t->sp++ = t->ptr; t->ptr = p->base + o; break; } /* call */
@           case 0xF8: {                                                        /* start track n   */
@               u8 n = *t->ptr++; u16 o = read16(t);
@               Track *c2 = p->tracks[n];
@               if (!c2) p->tracks[n] = c2 = trackAlloc(); else trackStop(c2);
@               trackStart(c2, p, p->base + o);                 /* NULL c2 is not checked here:  */
@               c2->sampleBank = t->sampleBank; c2->bank = t->bank; c2->program = t->program;
@               c2->pan = t->pan; c2->echo = t->echo; c2->volume = t->volume;   /* writes to NULL */
@               c2->expression = t->expression; c2->priority = t->priority;
@               c2->bend = t->bend; c2->bendRange = t->bendRange; c2->transpose = t->transpose;
@               break; }
@           case 0xFF:                                                          /* return / end    */
@               if (t->sp == t->stack) { trackStop(t); return 2; }
@               t->ptr = *--t->sp; break;
@           default: break;              /* CB-CF, EB-EF, F1-F3, F5-F7, F9-FE: one-byte no-ops     */
@           }
@       }
@       t->wait -= p->tempo;
@       t->wait -= p->tempoOfs;
@       return 0;
@   }
@ ======================================================================================
	.global trackTick
	.thumb_func
trackTick:
	push	{r4, r5, r6, r7, lr}
	mov	r7, r8
	push	{r7}
	sub	sp, #4
	adds	r5, r0, #0
	cmp	r5, #0
	beq	.L080E99DC
	ldr	r1, [r5, #8]
	cmp	r1, #0
	bne	.L080E99E0
.L080E99DC:
	movs	r0, #1
	b	.L080E9E28
.L080E99E0:
	mov	r8, r1
	mov	r0, r8
	adds	r0, #0x3c
	ldrb	r1, [r0]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	bne	.L080E99F2
	b	.L080E9E0E
.L080E99F2:
	b	.L080E9E26
.L080E99F4:
	adds	r0, r5, #0
	bl	trackStop
	movs	r0, #2
	b	.L080E9E28
.L080E99FE:
	ldr	r2, [r5]
	ldrb	r6, [r2]
	adds	r2, #1
	str	r2, [r5]
	cmp	r6, #0xbf
	bhi	.L080E9A84
	cmp	r6, #0x5f
	bhi	.L080E9A1A
	adds	r0, r5, #0
	adds	r0, #0x44
	ldrh	r4, [r0]
	adds	r0, #4
	ldrb	r2, [r0]
	b	.L080E9A40
.L080E9A1A:
	adds	r0, r5, #0
	bl	readVarLen
	lsls	r0, r0, #0x10
	lsrs	r4, r0, #0x10
	adds	r0, r5, #0
	adds	r0, #0x44
	strh	r4, [r0]
	ldr	r0, [r5]
	ldrb	r2, [r0]
	adds	r0, #1
	str	r0, [r5]
	adds	r0, r5, #0
	adds	r0, #0x48
	strb	r2, [r0]
	adds	r0, r6, #0
	subs	r0, #0x60
	lsls	r0, r0, #0x18
	lsrs	r6, r0, #0x18
.L080E9A40:
	movs	r0, #0x96
	muls	r4, r0, r4
	ldr	r0, .P080E9A68	@ =gHookNote
	ldr	r7, [r0]
	cmp	r7, #0
	beq	.L080E9A6C
	mov	r0, r8
	adds	r0, #0x44
	ldrb	r1, [r0]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L080E9A6C
	adds	r0, r5, #0
	adds	r1, r6, #0
	adds	r3, r4, #0
	bl	_call_via_r7
	b	.L080E9A76
	.hword 0x0000
.P080E9A68:	.word gHookNote
.L080E9A6C:
	adds	r0, r5, #0
	adds	r1, r6, #0
	adds	r3, r4, #0
	bl	noteOn
.L080E9A76:
	adds	r0, r5, #0
	adds	r0, #0x53
	ldrb	r0, [r0]
	cmp	r0, #1
	beq	.L080E9A82
	b	.L080E9E0E
.L080E9A82:
	b	.L080E9AA8
.L080E9A84:
	cmp	r6, #0xc0
	bne	.L080E9A90
	adds	r0, r5, #0
	adds	r0, #0x46
	ldrh	r4, [r0]
	b	.L080E9AA4
.L080E9A90:
	cmp	r6, #0xc1
	bne	.L080E9AB0
	adds	r0, r5, #0
	bl	readVarLen
	lsls	r0, r0, #0x10
	lsrs	r4, r0, #0x10
	adds	r0, r5, #0
	adds	r0, #0x46
	strh	r4, [r0]
.L080E9AA4:
	movs	r0, #0x96
	muls	r4, r0, r4
.L080E9AA8:
	ldr	r0, [r5, #0x34]
	adds	r0, r0, r4
	str	r0, [r5, #0x34]
	b	.L080E9E0E
.L080E9AB0:
	movs	r0, #0xf0
	ands	r0, r6
	cmp	r0, #0xd0
	bne	.L080E9AF0
	movs	r0, #0xf
	ands	r0, r6
	strb	r0, [r5, #0x1d]
	adds	r1, r5, #0
	adds	r1, #0x51
	ldrb	r1, [r1]
	ldrb	r3, [r2]
	adds	r1, r1, r3
	strb	r1, [r5, #0x1e]
	adds	r3, r2, #1
	str	r3, [r5]
	ldrb	r1, [r2, #1]
	strh	r1, [r5, #0x22]
	adds	r2, r3, #1
	str	r2, [r5]
	movs	r1, #1
	ands	r1, r0
	cmp	r1, #0
	beq	.L080E9AE8
	ldrb	r0, [r3, #1]
	strh	r0, [r5, #0x20]
	adds	r0, r2, #1
	str	r0, [r5]
	b	.L080E9AEA
.L080E9AE8:
	strh	r1, [r5, #0x20]
.L080E9AEA:
	movs	r0, #1
	strb	r0, [r5, #0x1c]
	b	.L080E9E0E
.L080E9AF0:
	adds	r0, r6, #0
	subs	r0, #0xc2
	cmp	r0, #0x3d
	bls	.L080E9AFA
	b	.L080E9E0E
.L080E9AFA:
	lsls	r0, r0, #2
	ldr	r1, .P080E9B04	@ =0x080E9B08
	adds	r0, r0, r1
	ldr	r0, [r0]
	mov	pc, r0
.P080E9B04:	.word 0x080E9B08
	.word .L080E9C5E
	.word .L080E9C7A
	.word .L080E9C86
	.word .L080E9CDA
	.word .L080E9CDA
	.word .L080E9C6A
	.word .L080E9CEE
	.word .L080E9CF8
	.word .L080E9D02
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9C92
	.word .L080E9CAA
	.word .L080E9CB6
	.word .L080E9CCE
	.word .L080E9D28
	.word .L080E9D34
	.word .L080E9D44
	.word .L080E9D3C
	.word .L080E9C16
	.word .L080E9CC2
	.word .L080E9C9E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9C1C
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9C36
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9D50
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9E0E
	.word .L080E9C00
.L080E9C00:
	adds	r0, r5, #0
	adds	r0, #0x24
	ldr	r1, [r5, #0x30]
	cmp	r1, r0
	bne	.L080E9C0C
	b	.L080E99F4
.L080E9C0C:
	subs	r0, r1, #4
	str	r0, [r5, #0x30]
	ldr	r0, [r0]
	str	r0, [r5]
	b	.L080E9E0E
.L080E9C16:
	movs	r0, #0
	strb	r0, [r5, #0x1c]
	b	.L080E9E0E
.L080E9C1C:
	mov	r2, sp
	ldr	r0, [r5]
	ldrb	r1, [r0]
	strb	r1, [r2]
	adds	r0, #1
	str	r0, [r5]
	ldrb	r1, [r0]
	strb	r1, [r2, #1]
	adds	r0, #1
	str	r0, [r5]
	mov	r0, r8
	ldr	r1, [r0, #4]
	b	.L080E9C54
.L080E9C36:
	mov	r2, sp
	ldr	r1, [r5]
	ldrb	r0, [r1]
	strb	r0, [r2]
	adds	r1, #1
	str	r1, [r5]
	ldrb	r0, [r1]
	strb	r0, [r2, #1]
	adds	r1, #1
	str	r1, [r5]
	ldr	r0, [r5, #0x30]
	stm	r0!, {r1}
	str	r0, [r5, #0x30]
	mov	r2, r8
	ldr	r1, [r2, #4]
.L080E9C54:
	mov	r0, sp
	ldrh	r0, [r0]
	adds	r1, r1, r0
	str	r1, [r5]
	b	.L080E9E0E
.L080E9C5E:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x42
	strh	r1, [r2]
	b	.L080E9D22
.L080E9C6A:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r0, #1
	str	r0, [r5]
	adds	r0, r5, #0
	bl	trackSetBank
	b	.L080E9E0E
.L080E9C7A:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x4b
	strb	r1, [r2]
	b	.L080E9D22
.L080E9C86:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x52
	strb	r1, [r2]
	b	.L080E9D22
.L080E9C92:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x4d
	strb	r1, [r2]
	b	.L080E9D22
.L080E9C9E:
	ldr	r0, [r5, #8]
	ldr	r1, [r5]
	ldrb	r2, [r1]
	adds	r0, #0x40
	strb	r2, [r0]
	b	.L080E9D4A
.L080E9CAA:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x4f
	strb	r1, [r2]
	b	.L080E9D22
.L080E9CB6:
	ldr	r0, [r5]
	ldrb	r2, [r0]
	adds	r1, r5, #0
	adds	r1, #0x50
	strb	r2, [r1]
	b	.L080E9D22
.L080E9CC2:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x51
	strb	r1, [r2]
	b	.L080E9D22
.L080E9CCE:
	ldr	r0, [r5]
	ldrb	r2, [r0]
	adds	r1, r5, #0
	adds	r1, #0x4c
	strb	r2, [r1]
	b	.L080E9D22
.L080E9CDA:
	adds	r0, r5, #0
	bl	trackReleaseAll
	movs	r1, #0
	cmp	r6, #0xc5
	bne	.L080E9CE8
	movs	r1, #1
.L080E9CE8:
	adds	r0, r5, #0
	adds	r0, #0x49
	b	.L080E9E0C
.L080E9CEE:
	adds	r1, r5, #0
	adds	r1, #0x53
	movs	r0, #1
	strb	r0, [r1]
	b	.L080E9E0E
.L080E9CF8:
	adds	r1, r5, #0
	adds	r1, #0x53
	movs	r0, #0
	strb	r0, [r1]
	b	.L080E9E0E
.L080E9D02:
	ldr	r0, .P080E9D1C	@ =gHookCA
	ldr	r2, [r0]
	cmp	r2, #0
	beq	.L080E9D20
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r0, #1
	str	r0, [r5]
	adds	r0, r5, #0
	bl	_call_via_r2
	b	.L080E9E0E
	.hword 0x0000
.P080E9D1C:	.word gHookCA
.L080E9D20:
	ldr	r0, [r5]
.L080E9D22:
	adds	r0, #1
	str	r0, [r5]
	b	.L080E9E0E
.L080E9D28:
	adds	r0, r5, #0
	bl	readVarLen
	mov	r3, r8
	strh	r0, [r3, #0x30]
	b	.L080E9E0E
.L080E9D34:
	ldr	r1, [r5]
	ldrb	r0, [r1]
	strh	r0, [r5, #0x10]
	b	.L080E9D4A
.L080E9D3C:
	ldr	r1, [r5]
	ldrb	r0, [r1]
	str	r0, [r5, #0x18]
	b	.L080E9D4A
.L080E9D44:
	ldr	r1, [r5]
	ldrb	r0, [r1]
	str	r0, [r5, #0x14]
.L080E9D4A:
	adds	r1, #1
	str	r1, [r5]
	b	.L080E9E0E
.L080E9D50:
	ldr	r1, [r5]
	ldrb	r4, [r1]
	adds	r1, #1
	str	r1, [r5]
	mov	r2, sp
	ldrb	r0, [r1]
	strb	r0, [r2]
	adds	r2, r1, #1
	str	r2, [r5]
	mov	r3, sp
	ldrb	r0, [r1, #1]
	strb	r0, [r3, #1]
	adds	r2, #1
	str	r2, [r5]
	lsls	r4, r4, #2
	mov	r0, r8
	adds	r0, #8
	adds	r6, r0, r4
	ldr	r0, [r6]
	cmp	r0, #0
	bne	.L080E9D84
	bl	trackAlloc
	adds	r4, r0, #0
	str	r4, [r6]
	b	.L080E9D8A
.L080E9D84:
	adds	r4, r0, #0
	bl	trackStop
.L080E9D8A:
	mov	r0, sp
	ldrh	r0, [r0]
	mov	r1, r8
	ldr	r2, [r1, #4]
	adds	r2, r2, r0
	adds	r0, r4, #0
	bl	trackStart
	ldr	r0, [r5, #4]
	str	r0, [r4, #4]
	adds	r0, r5, #0
	adds	r0, #0x40
	ldrh	r1, [r0]
	adds	r0, r4, #0
	adds	r0, #0x40
	strh	r1, [r0]
	adds	r0, r5, #0
	adds	r0, #0x42
	ldrh	r0, [r0]
	adds	r1, r4, #0
	adds	r1, #0x42
	strh	r0, [r1]
	adds	r0, r5, #0
	adds	r0, #0x4b
	ldrb	r0, [r0]
	adds	r1, #9
	strb	r0, [r1]
	adds	r0, r5, #0
	adds	r0, #0x4c
	ldrb	r1, [r0]
	adds	r0, r4, #0
	adds	r0, #0x4c
	strb	r1, [r0]
	adds	r0, r5, #0
	adds	r0, #0x4d
	ldrb	r0, [r0]
	adds	r1, r4, #0
	adds	r1, #0x4d
	strb	r0, [r1]
	adds	r0, r5, #0
	adds	r0, #0x4e
	ldrb	r0, [r0]
	adds	r1, #1
	strb	r0, [r1]
	adds	r0, r5, #0
	adds	r0, #0x52
	ldrb	r0, [r0]
	adds	r1, #4
	strb	r0, [r1]
	adds	r0, r5, #0
	adds	r0, #0x4f
	ldrb	r0, [r0]
	subs	r1, #3
	strb	r0, [r1]
	adds	r0, r5, #0
	adds	r0, #0x50
	ldrb	r1, [r0]
	adds	r0, r4, #0
	adds	r0, #0x50
	strb	r1, [r0]
	adds	r0, r5, #0
	adds	r0, #0x51
	ldrb	r1, [r0]
	adds	r0, r4, #0
	adds	r0, #0x51
.L080E9E0C:
	strb	r1, [r0]
.L080E9E0E:
	ldr	r1, [r5, #0x34]
	cmp	r1, #0
	bgt	.L080E9E16
	b	.L080E99FE
.L080E9E16:
	mov	r2, r8
	ldrh	r0, [r2, #0x30]
	subs	r0, r1, r0
	str	r0, [r5, #0x34]
	movs	r3, #0x32
	ldrsh	r1, [r2, r3]
	subs	r0, r0, r1
	str	r0, [r5, #0x34]
.L080E9E26:
	movs	r0, #0
.L080E9E28:
	add	sp, #4
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1

@ ======================================================================================
@ trackAddVoice   (080E9E34)
@
@   void trackAddVoice(Track *t, Voice *v)
@   {
@       if (v->track) return;
@       v->track = t; v->tprev = NULL; v->tnext = t->voices;
@       t->voices = v;
@       if (v->tnext) v->tnext->tprev = v;
@   }
@ ======================================================================================
	.global trackAddVoice
	.thumb_func
trackAddVoice:
	push	{lr}
	ldr	r2, [r1, #4]
	cmp	r2, #0
	bne	.L080E9E4C
	str	r0, [r1, #4]
	str	r2, [r1, #0x70]
	ldr	r2, [r0, #0xc]
	str	r2, [r1, #0x74]
	str	r1, [r0, #0xc]
	cmp	r2, #0
	beq	.L080E9E4C
	str	r1, [r2, #0x70]
.L080E9E4C:
	pop	{r0}
	bx	r0

@ ======================================================================================
@ trackRemoveVoice   (080E9E50)
@
@   void trackRemoveVoice(Track *t, Voice *v)
@   {
@       if (!v->track) return;
@       v->track = NULL;
@       if (v->tnext) v->tnext->tprev = v->tprev;
@       if (v->tprev) v->tprev->tnext = v->tnext; else t->voices = v->tnext;
@   }
@ ======================================================================================
	.global trackRemoveVoice
	.thumb_func
trackRemoveVoice:
	push	{lr}
	adds	r3, r0, #0
	ldr	r0, [r1, #4]
	cmp	r0, #0
	beq	.L080E9E78
	movs	r0, #0
	str	r0, [r1, #4]
	ldr	r2, [r1, #0x74]
	cmp	r2, #0
	beq	.L080E9E68
	ldr	r0, [r1, #0x70]
	str	r0, [r2, #0x70]
.L080E9E68:
	ldr	r2, [r1, #0x70]
	cmp	r2, #0
	beq	.L080E9E74
	ldr	r0, [r1, #0x74]
	str	r0, [r2, #0x74]
	b	.L080E9E78
.L080E9E74:
	ldr	r0, [r1, #0x74]
	str	r0, [r3, #0xc]
.L080E9E78:
	pop	{r0}
	bx	r0

@ ======================================================================================
@ readVarLen   (080E9E7C)
@
@   u32 readVarLen(Track *t)            /* 1 byte 0..7F, or 2 bytes 1xxxxxxx yyyyyyyy = x<<8 | y */
@   {
@       u8 b = *t->ptr++;
@       if (b & 0x80) return (b & 0x7F) << 8 | *t->ptr++;
@       return b;
@   }
@ ======================================================================================
	.global readVarLen
	.thumb_func
readVarLen:
	push	{lr}
	adds	r3, r0, #0
	ldr	r2, [r3]
	ldrb	r1, [r2]
	adds	r2, #1
	str	r2, [r3]
	movs	r0, #0x80
	ands	r0, r1
	cmp	r0, #0
	beq	.L080E9E9E
	movs	r0, #0x7f
	ands	r1, r0
	lsls	r1, r1, #8
	ldrb	r0, [r2]
	orrs	r1, r0
	adds	r0, r2, #1
	str	r0, [r3]
.L080E9E9E:
	adds	r0, r1, #0
	pop	{r1}
	bx	r1

@ ======================================================================================
@ trackSetBank   (080E9EA4)
@
@   /* Command C7: select a bank.  The song's bank map turns the bank number into an
@      instrument bank index; gCfg->instToSampleBank maps that to the sample bank. */
@   void trackSetBank(Track *t, u32 bank)
@   {
@       t->bank = bank; t->program = 0;
@       t->sampleBank = cfgTable(gCfg->sampleBanks, gCfg->instToSampleBank[t->player->bankMap[bank]]);
@   }
@ ======================================================================================
	.global trackSetBank
	.thumb_func
trackSetBank:
	adds	r3, r0, #0
	adds	r0, #0x40
	movs	r2, #0
	strh	r1, [r0]
	adds	r0, #2
	strh	r2, [r0]
	ldr	r0, .P080E9ED4	@ =gCfg
	ldr	r2, [r0]
	ldr	r0, [r3, #8]
	ldr	r0, [r0]
	lsls	r1, r1, #1
	adds	r1, r1, r0
	ldrh	r0, [r1]
	ldr	r1, [r2, #0x10]
	lsls	r0, r0, #1
	adds	r0, r0, r1
	ldrh	r0, [r0]
	ldr	r1, [r2]
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r0, [r0]
	adds	r1, r1, r0
	str	r1, [r3, #4]
	bx	lr
.P080E9ED4:	.word gCfg

@ ======================================================================================
@ playerInitAll   (080E9ED8)
@
@   void playerInitAll(void)
@   {
@       for (i = 0; i < 20; i++) { gPlayers[i].state = 0; for (j = 0; j < 10; j++) gPlayers[i].tracks[j] = NULL; }
@   }
@ ======================================================================================
	.global playerInitAll
	.thumb_func
playerInitAll:
	push	{r4, lr}
	movs	r2, #0
	ldr	r4, .P080E9F08	@ =gPlayers
	movs	r3, #0
.L080E9EE0:
	lsls	r0, r2, #3
	adds	r0, r0, r2
	lsls	r0, r0, #3
	adds	r0, r0, r4
	adds	r1, r0, #0
	adds	r1, #0x42
	strb	r3, [r1]
	adds	r2, #1
	movs	r1, #9
	adds	r0, #0x2c
.L080E9EF4:
	str	r3, [r0]
	subs	r0, #4
	subs	r1, #1
	cmp	r1, #0
	bge	.L080E9EF4
	cmp	r2, #0x13
	ble	.L080E9EE0
	pop	{r4}
	pop	{r0}
	bx	r0
.P080E9F08:	.word gPlayers

@ ======================================================================================
@ playerReset   (080E9F0C)
@
@   void playerReset(Player *p)
@   {
@       p->flags &= ~PAUSED; p->tempo = 150; p->tempoOfs = 0;
@       p->songVolume = 128; p->volume2 = 128; p->volume = 0x8000;
@       p->fadeStep = 0; p->fadeCount = 0; p->fadeTarget = 0; p->flags44 = 0;
@   }
@ ======================================================================================
	.global playerReset
	.thumb_func
playerReset:
	mov	ip, r0
	mov	r2, ip
	adds	r2, #0x3c
	ldrb	r1, [r2]
	movs	r0, #2
	rsbs	r0, r0, #0
	ands	r0, r1
	strb	r0, [r2]
	movs	r3, #0
	movs	r2, #0
	movs	r0, #0x96
	mov	r1, ip
	strh	r0, [r1, #0x30]
	strh	r2, [r1, #0x32]
	mov	r0, ip
	adds	r0, #0x40
	movs	r1, #0x80
	strb	r1, [r0]
	adds	r0, #1
	strb	r1, [r0]
	movs	r0, #0x80
	lsls	r0, r0, #8
	mov	r1, ip
	strh	r0, [r1, #0x34]
	strh	r2, [r1, #0x36]
	strh	r2, [r1, #0x3a]
	strh	r2, [r1, #0x38]
	mov	r0, ip
	adds	r0, #0x44
	strb	r3, [r0]
	bx	lr
	movs	r0, r0

@ ======================================================================================
@ playerTickAll   (080E9F4C)
@
@   void playerTickAll(void)
@   {
@       for (u32 i = 0; i < 20; i++) {
@           Player *p = &gPlayers[i];
@           if (!p->state) continue;
@           if (p->fadeCount) {
@               p->volume += p->fadeStep;
@               if (--p->fadeCount == 0) p->volume = p->fadeTarget;
@           } else if (p->state == 2) { playerStop(i); continue; }   /* fade-out finished       */
@           int alive = 0;
@           for (j = 0; j < 10; j++)
@               if (p->tracks[j]) {
@                   if (trackTick(p->tracks[j]) == 0) alive = 1; else p->tracks[j] = NULL;
@               }
@           if (!alive) playerStop(i);
@       }
@   }
@ ======================================================================================
	.global playerTickAll
	.thumb_func
playerTickAll:
	push	{r4, r5, r6, r7, lr}
	sub	sp, #4
	movs	r6, #0
.L080E9F52:
	lsls	r0, r6, #3
	adds	r0, r0, r6
	lsls	r0, r0, #3
	ldr	r1, .P080E9F7C	@ =gPlayers
	adds	r1, r0, r1
	adds	r0, r1, #0
	adds	r0, #0x42
	ldrb	r0, [r0]
	adds	r7, r6, #1
	cmp	r0, #0
	beq	.L080E9FCE
	ldrh	r2, [r1, #0x3a]
	cmp	r2, #0
	bne	.L080E9F80
	cmp	r0, #2
	bne	.L080E9F96
	adds	r0, r6, #0
	bl	playerStop
	b	.L080E9FCE
	.hword 0x0000
.P080E9F7C:	.word gPlayers
.L080E9F80:
	ldrh	r0, [r1, #0x36]
	ldrh	r3, [r1, #0x34]
	adds	r0, r0, r3
	strh	r0, [r1, #0x34]
	subs	r0, r2, #1
	strh	r0, [r1, #0x3a]
	lsls	r0, r0, #0x10
	cmp	r0, #0
	bne	.L080E9F96
	ldrh	r0, [r1, #0x38]
	strh	r0, [r1, #0x34]
.L080E9F96:
	movs	r2, #0
	adds	r7, r6, #1
	adds	r4, r1, #0
	adds	r4, #8
	movs	r5, #9
.L080E9FA0:
	ldr	r0, [r4]
	cmp	r0, #0
	beq	.L080E9FBC
	str	r2, [sp]
	bl	trackTick
	lsls	r0, r0, #0x18
	ldr	r2, [sp]
	cmp	r0, #0
	bne	.L080E9FB8
	movs	r2, #1
	b	.L080E9FBC
.L080E9FB8:
	movs	r0, #0
	str	r0, [r4]
.L080E9FBC:
	adds	r4, #4
	subs	r5, #1
	cmp	r5, #0
	bge	.L080E9FA0
	cmp	r2, #0
	bne	.L080E9FCE
	adds	r0, r6, #0
	bl	playerStop
.L080E9FCE:
	adds	r6, r7, #0
	cmp	r6, #0x13
	ble	.L080E9F52
	add	sp, #4
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ doPlaySong   (080E9FDC)
@
@   void doPlaySong(u32 pl, u32 song)
@   {
@       playerStartSong(pl, cfgTable(gCfg->songs, song), cfgTable(gCfg->songBankMaps, song));
@   }
@ ======================================================================================
	.global doPlaySong
	.thumb_func
doPlaySong:
	push	{r4, lr}
	ldr	r2, .P080EA000	@ =gCfg
	ldr	r4, [r2]
	ldr	r3, [r4, #8]
	lsls	r1, r1, #2
	adds	r2, r1, r3
	ldr	r2, [r2]
	adds	r3, r3, r2
	ldr	r2, [r4, #0x14]
	adds	r1, r1, r2
	ldr	r1, [r1]
	adds	r2, r2, r1
	adds	r1, r3, #0
	bl	playerStartSong
	pop	{r4}
	pop	{r0}
	bx	r0
.P080EA000:	.word gCfg

@ ======================================================================================
@ doPlaySfx   (080EA004)
@
@   void doPlaySfx(u32 pl, u32 set, u32 idx)
@   {
@       playerStartSfx(pl, cfgTable(gCfg->sfxSets, set), cfgTable(gCfg->sfxBankMaps, set), idx);
@   }
@ ======================================================================================
	.global doPlaySfx
	.thumb_func
doPlaySfx:
	push	{r4, r5, lr}
	adds	r3, r2, #0
	ldr	r2, .P080EA02C	@ =gCfg
	ldr	r5, [r2]
	ldr	r4, [r5, #0xc]
	lsls	r1, r1, #2
	adds	r2, r1, r4
	ldr	r2, [r2]
	adds	r4, r4, r2
	ldr	r2, [r5, #0x18]
	adds	r1, r1, r2
	ldr	r1, [r1]
	adds	r2, r2, r1
	adds	r1, r4, #0
	bl	playerStartSfx
	pop	{r4, r5}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080EA02C:	.word gCfg

@ ======================================================================================
@ playerStartSong   (080EA030)
@
@   /* song: s8 trackCount, then u16 offsets (from the song header) of each track; 0 = none */
@   void playerStartSong(u32 pl, u8 *song, u16 *bankMap)
@   {
@       Player *p = &gPlayers[pl];
@       if (p->state) playerStop(pl);
@       p->base = song; p->bankMap = bankMap; p->isSfx = 0;
@       playerReset(p);
@       u16 *ofs = (u16 *)song;
@       for (int i = 0; i < (s8)song[0]; i++)             /* no check against the 10 slots        */
@           if (ofs[i + 1]) {
@               p->tracks[i] = trackAlloc();
@               trackStart(p->tracks[i], p, p->base + ofs[i + 1]);
@           }
@       p->state = 1;
@   }
@ ======================================================================================
	.global playerStartSong
	.thumb_func
playerStartSong:
	push	{r4, r5, r6, r7, lr}
	mov	r7, r8
	push	{r7}
	adds	r3, r0, #0
	adds	r6, r1, #0
	adds	r7, r2, #0
	lsls	r0, r3, #3
	adds	r0, r0, r3
	lsls	r0, r0, #3
	ldr	r1, .P080EA0B4	@ =gPlayers
	adds	r5, r0, r1
	adds	r4, r5, #0
	adds	r4, #0x42
	ldrb	r0, [r4]
	cmp	r0, #0
	beq	.L080EA056
	adds	r0, r3, #0
	bl	playerStop
.L080EA056:
	str	r6, [r5, #4]
	str	r7, [r5]
	adds	r1, r5, #0
	adds	r1, #0x43
	movs	r0, #0
	strb	r0, [r1]
	adds	r0, r5, #0
	bl	playerReset
	ldr	r0, [r5, #4]
	movs	r7, #0
	ldrsb	r7, [r0, r7]
	adds	r0, #2
	movs	r6, #0
	mov	r8, r4
	cmp	r6, r7
	bge	.L080EA0A2
	adds	r4, r0, #0
.L080EA07A:
	ldrh	r0, [r4]
	cmp	r0, #0
	beq	.L080EA09A
	bl	trackAlloc
	lsls	r2, r6, #2
	adds	r1, r5, #0
	adds	r1, #8
	adds	r1, r1, r2
	str	r0, [r1]
	ldrh	r1, [r4]
	ldr	r2, [r5, #4]
	adds	r2, r2, r1
	adds	r1, r5, #0
	bl	trackStart
.L080EA09A:
	adds	r4, #2
	adds	r6, #1
	cmp	r6, r7
	blt	.L080EA07A
.L080EA0A2:
	movs	r0, #1
	mov	r1, r8
	strb	r0, [r1]
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080EA0B4:	.word gPlayers

@ ======================================================================================
@ playerStartSfx   (080EA0B8)
@
@   /* set: u16 offsets (from the set) of single-track sequences */
@   void playerStartSfx(u32 pl, u8 *set, u16 *bankMap, u32 idx)
@   {
@       Player *p = &gPlayers[pl];
@       if (p->state) playerStop(pl);
@       p->base = set; p->bankMap = bankMap; p->isSfx = 1;
@       playerReset(p);
@       p->tracks[0] = trackAlloc();
@       trackStart(p->tracks[0], p, p->base + ((u16 *)p->base)[idx]);
@       p->state = 1;
@   }
@ ======================================================================================
	.global playerStartSfx
	.thumb_func
playerStartSfx:
	push	{r4, r5, r6, r7, lr}
	mov	r7, sb
	mov	r6, r8
	push	{r6, r7}
	adds	r4, r0, #0
	adds	r6, r1, #0
	adds	r7, r2, #0
	mov	sb, r3
	lsls	r0, r4, #3
	adds	r0, r0, r4
	lsls	r0, r0, #3
	ldr	r1, .P080EA120	@ =gPlayers
	adds	r5, r0, r1
	movs	r0, #0x42
	adds	r0, r0, r5
	mov	r8, r0
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L080EA0E4
	adds	r0, r4, #0
	bl	playerStop
.L080EA0E4:
	str	r6, [r5, #4]
	str	r7, [r5]
	adds	r0, r5, #0
	adds	r0, #0x43
	movs	r4, #1
	strb	r4, [r0]
	adds	r0, r5, #0
	bl	playerReset
	bl	trackAlloc
	str	r0, [r5, #8]
	ldr	r2, [r5, #4]
	mov	r3, sb
	lsls	r1, r3, #1
	adds	r1, r1, r2
	ldrh	r1, [r1]
	adds	r2, r2, r1
	adds	r1, r5, #0
	bl	trackStart
	mov	r0, r8
	strb	r4, [r0]
	pop	{r3, r4}
	mov	r8, r3
	mov	sb, r4
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080EA120:	.word gPlayers

@ ======================================================================================
@ playerStop   (080EA124)
@
@   void playerStop(u32 pl)
@   {
@       Player *p = &gPlayers[pl];
@       if (!p->state) return;
@       for (j = 0; j < 10; j++) { trackStop(p->tracks[j]); p->tracks[j] = NULL; }
@       p->state = 0;
@   }
@ ======================================================================================
	.global playerStop
	.thumb_func
playerStop:
	push	{r4, r5, r6, r7, lr}
	lsls	r1, r0, #3
	adds	r1, r1, r0
	lsls	r1, r1, #3
	ldr	r0, .P080EA15C	@ =gPlayers
	adds	r1, r1, r0
	adds	r2, r1, #0
	adds	r2, #0x42
	ldrb	r0, [r2]
	cmp	r0, #0
	beq	.L080EA156
	adds	r7, r2, #0
	movs	r6, #0
	adds	r4, r1, #0
	adds	r4, #8
	movs	r5, #9
.L080EA144:
	ldr	r0, [r4]
	bl	trackStop
	stm	r4!, {r6}
	subs	r5, #1
	cmp	r5, #0
	bge	.L080EA144
	movs	r0, #0
	strb	r0, [r7]
.L080EA156:
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
.P080EA15C:	.word gPlayers

@ ======================================================================================
@ playerFadeOut   (080EA160)
@
@   void playerFadeOut(u32 pl, u32 frames)
@   {
@       Player *p = &gPlayers[pl];
@       if (!p->state) return;
@       p->state = 2; p->fadeTarget = 0; p->fadeCount = frames;
@       p->fadeStep = -p->volume / frames;                 /* frames == 0 divides by zero          */
@   }
@ ======================================================================================
	.global playerFadeOut
	.thumb_func
playerFadeOut:
	push	{r4, lr}
	adds	r3, r1, #0
	lsls	r1, r0, #3
	adds	r1, r1, r0
	lsls	r1, r1, #3
	ldr	r0, .P080EA194	@ =gPlayers
	adds	r4, r1, r0
	adds	r2, r4, #0
	adds	r2, #0x42
	ldrb	r0, [r2]
	cmp	r0, #0
	beq	.L080EA18E
	movs	r1, #0
	movs	r0, #2
	strb	r0, [r2]
	strh	r1, [r4, #0x38]
	strh	r3, [r4, #0x3a]
	ldrh	r0, [r4, #0x34]
	rsbs	r0, r0, #0
	adds	r1, r3, #0
	bl	__divsi3
	strh	r0, [r4, #0x36]
.L080EA18E:
	pop	{r4}
	pop	{r0}
	bx	r0
.P080EA194:	.word gPlayers

@ ======================================================================================
@ playerSetPause   (080EA198)
@
@   void playerSetPause(u32 pl, u32 on)
@   {
@       gPlayers[pl].flags = (gPlayers[pl].flags & ~PAUSED) | (on & 1);
@   }
@ ======================================================================================
	.global playerSetPause
	.thumb_func
playerSetPause:
	lsls	r1, r1, #0x18
	lsrs	r1, r1, #0x18
	ldr	r3, .P080EA1B8	@ =gPlayers
	lsls	r2, r0, #3
	adds	r2, r2, r0
	lsls	r2, r2, #3
	adds	r2, r2, r3
	adds	r2, #0x3c
	movs	r0, #1
	ands	r1, r0
	ldrb	r3, [r2]
	subs	r0, #3
	ands	r0, r3
	orrs	r0, r1
	strb	r0, [r2]
	bx	lr
.P080EA1B8:	.word gPlayers

@ ======================================================================================
@ sndGetPlayerState   (080EA1BC)
@
@   u32 sndGetPlayerState(u32 pl)       /* 0 idle, 1 playing, 2 fading out (read directly) */
@   {
@       return gPlayers[pl].state;
@   }
@ ======================================================================================
	.global sndGetPlayerState
	.thumb_func
sndGetPlayerState:
	ldr	r2, .P080EA1CC	@ =gPlayers
	lsls	r1, r0, #3
	adds	r1, r1, r0
	lsls	r1, r1, #3
	adds	r2, #0x42
	adds	r1, r1, r2
	ldrb	r0, [r1]
	bx	lr
.P080EA1CC:	.word gPlayers

@ ======================================================================================
@ cmdNext   (080EA1D0)
@
@   void cmdNext(void)                  /* advance the write pointer (wraps at 46 entries) */
@   {
@       if (++gCmdWrite == gCmdEnd) gCmdWrite = gCmdQueue;
@   }
@ ======================================================================================
	.global cmdNext
	.thumb_func
cmdNext:
	push	{lr}
	ldr	r2, .P080EA1EC	@ =gCmdWrite
	ldr	r0, [r2]
	adds	r0, #0xc
	str	r0, [r2]
	ldr	r1, .P080EA1F0	@ =gCmdEnd
	ldr	r1, [r1]
	cmp	r0, r1
	bne	.L080EA1E6
	ldr	r0, .P080EA1F4	@ =gCmdQueue
	str	r0, [r2]
.L080EA1E6:
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080EA1EC:	.word gCmdWrite
.P080EA1F0:	.word gCmdEnd
.P080EA1F4:	.word gCmdQueue

@ ======================================================================================
@ cmdInit   (080EA1F8)
@
@   void cmdInit(void)
@   {
@       gCmdRead = gCmdWrite = gCmdCommitted = gCmdQueue; gCmdEnd = &gCmdQueue[46];
@       gHookNote = NULL; gHookCA = NULL;
@   }
@ ======================================================================================
	.global cmdInit
	.thumb_func
cmdInit:
	ldr	r0, .P080EA21C	@ =gCmdRead
	ldr	r1, .P080EA220	@ =gCmdQueue
	str	r1, [r0]
	ldr	r0, .P080EA224	@ =gCmdWrite
	str	r1, [r0]
	ldr	r0, .P080EA228	@ =gCmdCommitted
	str	r1, [r0]
	ldr	r0, .P080EA22C	@ =gCmdEnd
	movs	r2, #0x8a
	lsls	r2, r2, #2
	adds	r1, r1, r2
	str	r1, [r0]
	ldr	r0, .P080EA230	@ =gHookNote
	movs	r1, #0
	str	r1, [r0]
	ldr	r0, .P080EA234	@ =gHookCA
	str	r1, [r0]
	bx	lr
.P080EA21C:	.word gCmdRead
.P080EA220:	.word gCmdQueue
.P080EA224:	.word gCmdWrite
.P080EA228:	.word gCmdCommitted
.P080EA22C:	.word gCmdEnd
.P080EA230:	.word gHookNote
.P080EA234:	.word gHookCA

@ ======================================================================================
@ cmdPop   (080EA238)
@
@   SndCmd *cmdPop(void)                /* next committed command, or NULL */
@   {
@       if (gCmdRead == gCmdCommitted) return NULL;
@       SndCmd *c = gCmdRead;
@       if (++gCmdRead == gCmdEnd) gCmdRead = gCmdQueue;
@       return c;
@   }
@ ======================================================================================
	.global cmdPop
	.thumb_func
cmdPop:
	push	{lr}
	ldr	r3, .P080EA24C	@ =gCmdRead
	ldr	r2, [r3]
	ldr	r0, .P080EA250	@ =gCmdCommitted
	ldr	r0, [r0]
	cmp	r2, r0
	bne	.L080EA254
	movs	r0, #0
	b	.L080EA268
	.hword 0x0000
.P080EA24C:	.word gCmdRead
.P080EA250:	.word gCmdCommitted
.L080EA254:
	adds	r0, r2, #0
	adds	r0, #0xc
	str	r0, [r3]
	ldr	r1, .P080EA26C	@ =gCmdEnd
	ldr	r1, [r1]
	cmp	r0, r1
	bne	.L080EA266
	ldr	r0, .P080EA270	@ =gCmdQueue
	str	r0, [r3]
.L080EA266:
	adds	r0, r2, #0
.L080EA268:
	pop	{r1}
	bx	r1
.P080EA26C:	.word gCmdEnd
.P080EA270:	.word gCmdQueue

@ ======================================================================================
@ sndCommit   (080EA274)
@
@   void sndCommit(void)                /* make the commands queued since the last call visible */
@   {
@       gCmdCommitted = gCmdWrite;      /* no overflow check: 47 queued commands lose 46         */
@   }
@ ======================================================================================
	.global sndCommit
	.thumb_func
sndCommit:
	ldr	r0, .P080EA280	@ =gCmdCommitted
	ldr	r1, .P080EA284	@ =gCmdWrite
	ldr	r1, [r1]
	str	r1, [r0]
	bx	lr
	.hword 0x0000
.P080EA280:	.word gCmdCommitted
.P080EA284:	.word gCmdWrite

@ ======================================================================================
@ sndPlaySong   (080EA288)
@
@   void sndPlaySong(u32 pl, u32 song)             { queue(0x000, pl, song); }
@ ======================================================================================
	.global sndPlaySong
	.thumb_func
sndPlaySong:
	push	{lr}
	lsls	r0, r0, #0x10
	lsrs	r0, r0, #0x10
	lsls	r1, r1, #0x10
	lsrs	r1, r1, #0x10
	ldr	r2, .P080EA2A8	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #0
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080EA2A8:	.word gCmdWrite

@ ======================================================================================
@ sndPlaySfx   (080EA2AC)
@
@   void sndPlaySfx(u32 pl, u32 set, u32 idx)      { queue(0x001, pl << 16 | set, idx); }
@ ======================================================================================
	.global sndPlaySfx
	.thumb_func
sndPlaySfx:
	push	{r4, lr}
	lsls	r1, r1, #0x10
	lsrs	r1, r1, #0x10
	lsls	r2, r2, #0x10
	lsrs	r2, r2, #0x10
	ldr	r3, .P080EA2D0	@ =gCmdWrite
	ldr	r4, [r3]
	movs	r3, #1
	strh	r3, [r4]
	lsls	r0, r0, #0x10
	orrs	r0, r1
	str	r0, [r4, #4]
	str	r2, [r4, #8]
	bl	cmdNext
	pop	{r4}
	pop	{r0}
	bx	r0
.P080EA2D0:	.word gCmdWrite

@ ======================================================================================
@ sndFadeOut   (080EA2D4)
@
@   void sndFadeOut(u32 pl, u32 frames)            { queue(0x002, pl, frames); }
@ ======================================================================================
	.global sndFadeOut
	.thumb_func
sndFadeOut:
	push	{lr}
	lsls	r0, r0, #0x10
	lsrs	r0, r0, #0x10
	lsls	r1, r1, #0x10
	lsrs	r1, r1, #0x10
	ldr	r2, .P080EA2F4	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #2
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080EA2F4:	.word gCmdWrite

@ ======================================================================================
@ sndPause   (080EA2F8)
@
@   void sndPause(u32 pl, u32 on)                  { queue(0x003, pl, on); }
@ ======================================================================================
	.global sndPause
	.thumb_func
sndPause:
	push	{lr}
	lsls	r0, r0, #0x10
	lsrs	r0, r0, #0x10
	lsls	r1, r1, #0x18
	lsrs	r1, r1, #0x18
	ldr	r2, .P080EA318	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #3
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080EA318:	.word gCmdWrite

@ ======================================================================================
@ sndFadeOutMask   (080EA31C)
@
@   void sndFadeOutMask(u32 mask, u32 frames)      { queue(0x200, frames, mask); }
@ ======================================================================================
	.global sndFadeOutMask
	.thumb_func
sndFadeOutMask:
	push	{lr}
	lsls	r1, r1, #0x10
	lsrs	r1, r1, #0x10
	ldr	r2, .P080EA338	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #0x80
	lsls	r3, r3, #2
	strh	r3, [r2]
	str	r1, [r2, #4]
	str	r0, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
.P080EA338:	.word gCmdWrite

@ ======================================================================================
@ sndPauseMask   (080EA33C)
@
@   void sndPauseMask(u32 mask, u32 on)            { queue(0x201, on, mask); }
@ ======================================================================================
	.global sndPauseMask
	.thumb_func
sndPauseMask:
	push	{lr}
	lsls	r1, r1, #0x18
	lsrs	r1, r1, #0x18
	ldr	r2, .P080EA358	@ =gCmdWrite
	ldr	r2, [r2]
	ldr	r3, .P080EA35C	@ =0x00000201
	strh	r3, [r2]
	str	r1, [r2, #4]
	str	r0, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080EA358:	.word gCmdWrite
.P080EA35C:	.word 0x00000201

@ ======================================================================================
@ sndSetTempo   (080EA360)
@
@   void sndSetTempo(u32 pl, s32 ofs)              { queue(0x004, pl, ofs); }   /* tempo offset   */
@ ======================================================================================
	.global sndSetTempo
	.thumb_func
sndSetTempo:
	push	{lr}
	lsls	r0, r0, #0x10
	lsrs	r0, r0, #0x10
	ldr	r2, .P080EA380	@ =gCmdWrite
	ldr	r3, [r2]
	movs	r2, #4
	strh	r2, [r3]
	str	r0, [r3, #4]
	lsls	r1, r1, #0x10
	asrs	r1, r1, #0x10
	str	r1, [r3, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080EA380:	.word gCmdWrite

@ ======================================================================================
@ sndSetVolume2   (080EA384)
@
@   void sndSetVolume2(u32 pl, u32 v)              { queue(0x005, pl, v); }     /* 0x80 = default */
@ ======================================================================================
	.global sndSetVolume2
	.thumb_func
sndSetVolume2:
	push	{lr}
	lsls	r0, r0, #0x10
	lsrs	r0, r0, #0x10
	lsls	r1, r1, #0x18
	lsrs	r1, r1, #0x18
	ldr	r2, .P080EA3A4	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #5
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080EA3A4:	.word gCmdWrite

@ ======================================================================================
@ sndSetHookFlags   (080EA3A8)
@
@   void sndSetHookFlags(u32 pl, u32 v)            { queue(0x006, pl, v); }     /* bit 0: note hook */
@ ======================================================================================
	.global sndSetHookFlags
	.thumb_func
sndSetHookFlags:
	push	{lr}
	lsls	r0, r0, #0x10
	lsrs	r0, r0, #0x10
	lsls	r1, r1, #0x18
	lsrs	r1, r1, #0x18
	ldr	r2, .P080EA3C8	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #6
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080EA3C8:	.word gCmdWrite

@ ======================================================================================
@ sndMuteTracks   (080EA3CC)
@
@   void sndMuteTracks(u32 pl, u32 mask, u32 on)   { queue(0x100, pl << 16 | on, mask); }
@ ======================================================================================
	.global sndMuteTracks
	.thumb_func
sndMuteTracks:
	push	{r4, lr}
	lsls	r2, r2, #0x18
	lsrs	r2, r2, #0x18
	ldr	r3, .P080EA3F0	@ =gCmdWrite
	ldr	r4, [r3]
	movs	r3, #0x80
	lsls	r3, r3, #1
	strh	r3, [r4]
	lsls	r0, r0, #0x10
	orrs	r0, r2
	str	r0, [r4, #4]
	str	r1, [r4, #8]
	bl	cmdNext
	pop	{r4}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080EA3F0:	.word gCmdWrite

@ ======================================================================================
@ sndSetTrackExpr   (080EA3F4)
@
@   void sndSetTrackExpr(u32 pl, u32 mask, u32 v)  { queue(0x102, pl << 16 | v, mask); }
@ ======================================================================================
	.global sndSetTrackExpr
	.thumb_func
sndSetTrackExpr:
	push	{r4, lr}
	lsls	r2, r2, #0x18
	lsrs	r2, r2, #0x18
	ldr	r3, .P080EA418	@ =gCmdWrite
	ldr	r4, [r3]
	movs	r3, #0x81
	lsls	r3, r3, #1
	strh	r3, [r4]
	lsls	r0, r0, #0x10
	orrs	r0, r2
	str	r0, [r4, #4]
	str	r1, [r4, #8]
	bl	cmdNext
	pop	{r4}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080EA418:	.word gCmdWrite

@ ======================================================================================
@ sndSetTrackBend   (080EA41C)
@
@   void sndSetTrackBend(u32 pl, u32 mask, u32 range, u32 bend) { queue(0x103, pl << 16 | range << 8 | bend, mask); }
@ ======================================================================================
	.global sndSetTrackBend
	.thumb_func
sndSetTrackBend:
	push	{r4, r5, lr}
	lsls	r0, r0, #0x10
	lsls	r2, r2, #0x18
	ldr	r4, .P080EA444	@ =gCmdWrite
	ldr	r5, [r4]
	ldr	r4, .P080EA448	@ =0x00000103
	strh	r4, [r5]
	lsrs	r2, r2, #0x10
	orrs	r2, r0
	lsls	r3, r3, #0x18
	lsrs	r3, r3, #0x18
	orrs	r2, r3
	str	r2, [r5, #4]
	str	r1, [r5, #8]
	bl	cmdNext
	pop	{r4, r5}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080EA444:	.word gCmdWrite
.P080EA448:	.word 0x00000103

@ ======================================================================================
@ sndSetTrackPan   (080EA44C)
@
@   void sndSetTrackPan(u32 pl, u32 mask, u32 pan) { queue(0x101, pl << 16 | pan, mask); }
@ ======================================================================================
	.global sndSetTrackPan
	.thumb_func
sndSetTrackPan:
	push	{r4, lr}
	lsls	r2, r2, #0x18
	lsrs	r2, r2, #0x18
	ldr	r3, .P080EA46C	@ =gCmdWrite
	ldr	r4, [r3]
	ldr	r3, .P080EA470	@ =0x00000101
	strh	r3, [r4]
	lsls	r0, r0, #0x10
	orrs	r0, r2
	str	r0, [r4, #4]
	str	r1, [r4, #8]
	bl	cmdNext
	pop	{r4}
	pop	{r0}
	bx	r0
.P080EA46C:	.word gCmdWrite
.P080EA470:	.word 0x00000101

@ ======================================================================================
@ sndSetEcho   (080EA474)
@
@   void sndSetEcho(u32 shift)                     { queue(0x300, shift); }     /* 16 = off       */
@ ======================================================================================
	.global sndSetEcho
	.thumb_func
sndSetEcho:
	push	{lr}
	lsls	r0, r0, #0x18
	lsrs	r0, r0, #0x18
	ldr	r1, .P080EA490	@ =gCmdWrite
	ldr	r2, [r1]
	movs	r1, #0xc0
	lsls	r1, r1, #2
	strh	r1, [r2]
	str	r0, [r2, #4]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080EA490:	.word gCmdWrite

@ ======================================================================================
@ sndSetVoices   (080EA494)
@
@   void sndSetVoices(u32 n)                       { queue(0x304, n); }
@ ======================================================================================
	.global sndSetVoices
	.thumb_func
sndSetVoices:
	push	{lr}
	lsls	r0, r0, #0x18
	lsrs	r0, r0, #0x18
	ldr	r1, .P080EA4B0	@ =gCmdWrite
	ldr	r2, [r1]
	movs	r1, #0xc1
	lsls	r1, r1, #2
	strh	r1, [r2]
	str	r0, [r2, #4]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080EA4B0:	.word gCmdWrite

@ ======================================================================================
@ sndCallback   (080EA4B4)
@
@   void sndCallback(void (*fn)(u32), u32 arg)     { queue(0x301, fn, arg); }   /* run fn(arg) in sndMain */
@ ======================================================================================
	.global sndCallback
	.thumb_func
sndCallback:
	push	{lr}
	ldr	r2, .P080EA4CC	@ =gCmdWrite
	ldr	r2, [r2]
	ldr	r3, .P080EA4D0	@ =0x00000301
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080EA4CC:	.word gCmdWrite
.P080EA4D0:	.word 0x00000301

@ ======================================================================================
@ sndSetHookCA   (080EA4D4)
@
@   void sndSetHookCA(void *fn)                    { queue(0x302, fn); }
@ ======================================================================================
	.global sndSetHookCA
	.thumb_func
sndSetHookCA:
	push	{lr}
	ldr	r1, .P080EA4E8	@ =gCmdWrite
	ldr	r2, [r1]
	ldr	r1, .P080EA4EC	@ =0x00000302
	strh	r1, [r2]
	str	r0, [r2, #4]
	bl	cmdNext
	pop	{r0}
	bx	r0
.P080EA4E8:	.word gCmdWrite
.P080EA4EC:	.word 0x00000302

@ ======================================================================================
@ sndSetHookNote   (080EA4F0)
@
@   void sndSetHookNote(void *fn)                  { queue(0x303, fn); }
@ ======================================================================================
	.global sndSetHookNote
	.thumb_func
sndSetHookNote:
	push	{lr}
	ldr	r1, .P080EA504	@ =gCmdWrite
	ldr	r2, [r1]
	ldr	r1, .P080EA508	@ =0x00000303
	strh	r1, [r2]
	str	r0, [r2, #4]
	bl	cmdNext
	pop	{r0}
	bx	r0
.P080EA504:	.word gCmdWrite
.P080EA508:	.word 0x00000303

@ ======================================================================================
@ cmdPlayer   (080EA50C)
@
@   void cmdPlayer(SndCmd *c)           /* commands 0x000-0x006 */
@   {
@       Player *p = &gPlayers[c->a];
@       switch (c->op) {
@       case 0: doPlaySong(c->a, c->b); break;
@       case 1: doPlaySfx(c->a >> 16, c->a & 0xFFFF, c->b); break;
@       case 2: playerFadeOut(c->a, c->b); break;
@       case 3: playerSetPause(c->a, c->b); break;
@       case 4: p->tempoOfs = c->b; break;
@       case 5: p->volume2 = c->b; break;
@       case 6: p->flags44 = c->b; break;
@       }
@   }
@ ======================================================================================
	.global cmdPlayer
	.thumb_func
cmdPlayer:
	push	{lr}
	adds	r3, r0, #0
	ldr	r0, [r3, #4]
	lsls	r1, r0, #3
	adds	r1, r1, r0
	lsls	r1, r1, #3
	ldr	r0, .P080EA52C	@ =gPlayers
	adds	r2, r1, r0
	ldrh	r0, [r3]
	cmp	r0, #6
	bhi	.L080EA59A
	lsls	r0, r0, #2
	ldr	r1, .P080EA530	@ =0x080EA534
	adds	r0, r0, r1
	ldr	r0, [r0]
	mov	pc, r0
.P080EA52C:	.word gPlayers
.P080EA530:	.word 0x080EA534
	.word .L080EA550
	.word .L080EA55A
	.word .L080EA570
	.word .L080EA57A
	.word .L080EA58C
	.word .L080EA592
	.word .L080EA584
.L080EA550:
	ldr	r0, [r3, #4]
	ldr	r1, [r3, #8]
	bl	doPlaySong
	b	.L080EA59A
.L080EA55A:
	ldr	r1, [r3, #4]
	lsrs	r0, r1, #0x10
	ldr	r2, .P080EA56C	@ =0x0000FFFF
	ands	r1, r2
	ldr	r2, [r3, #8]
	bl	doPlaySfx
	b	.L080EA59A
	.hword 0x0000
.P080EA56C:	.word 0x0000FFFF
.L080EA570:
	ldr	r0, [r3, #4]
	ldr	r1, [r3, #8]
	bl	playerFadeOut
	b	.L080EA59A
.L080EA57A:
	ldr	r0, [r3, #4]
	ldrb	r1, [r3, #8]
	bl	playerSetPause
	b	.L080EA59A
.L080EA584:
	ldr	r1, [r3, #8]
	adds	r0, r2, #0
	adds	r0, #0x44
	b	.L080EA598
.L080EA58C:
	ldr	r0, [r3, #8]
	strh	r0, [r2, #0x32]
	b	.L080EA59A
.L080EA592:
	ldr	r1, [r3, #8]
	adds	r0, r2, #0
	adds	r0, #0x41
.L080EA598:
	strb	r1, [r0]
.L080EA59A:
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ cmdTrack   (080EA5A0)
@
@   void cmdTrack(SndCmd *c)            /* commands 0x100-0x103: a = player<<16 | value, b = track mask */
@   {
@       Player *p = &gPlayers[c->a >> 16];
@       for (i = 0; c->b && i < 10; i++, c->b >>= 1)
@           if ((c->b & 1) && p->tracks[i])
@               switch (c->op) {
@               case 0x100: p->tracks[i]->mute = c->a; break;
@               case 0x101: p->tracks[i]->pan = c->a; break;
@               case 0x102: p->tracks[i]->expression = c->a; break;
@               case 0x103: p->tracks[i]->bendRange = c->a >> 8; p->tracks[i]->bend = c->a; break;
@               }
@   }
@ ======================================================================================
	.global cmdTrack
	.thumb_func
cmdTrack:
	push	{r4, r5, r6, lr}
	adds	r3, r0, #0
	ldr	r4, [r3, #4]
	lsrs	r0, r4, #0x10
	lsls	r1, r0, #3
	adds	r1, r1, r0
	lsls	r1, r1, #3
	ldr	r0, .P080EA5C8	@ =gPlayers
	adds	r1, r1, r0
	movs	r5, #0
	ldrh	r2, [r3]
	ldr	r0, .P080EA5CC	@ =0x00000101
	cmp	r2, r0
	beq	.L080EA684
	cmp	r2, r0
	bgt	.L080EA5D0
	subs	r0, #1
	cmp	r2, r0
	beq	.L080EA5E0
	b	.L080EA6B4
.P080EA5C8:	.word gPlayers
.P080EA5CC:	.word 0x00000101
.L080EA5D0:
	movs	r0, #0x81
	lsls	r0, r0, #1
	cmp	r2, r0
	beq	.L080EA612
	adds	r0, #1
	cmp	r2, r0
	beq	.L080EA644
	b	.L080EA6B4
.L080EA5E0:
	lsls	r0, r4, #0x18
	lsrs	r2, r0, #0x18
	ldr	r0, [r3, #8]
	cmp	r0, #0
	beq	.L080EA6B4
	movs	r4, #1
	adds	r1, #8
.L080EA5EE:
	ands	r0, r4
	cmp	r0, #0
	beq	.L080EA5FE
	ldr	r0, [r1]
	cmp	r0, #0
	beq	.L080EA5FE
	adds	r0, #0x4a
	strb	r2, [r0]
.L080EA5FE:
	adds	r1, #4
	adds	r5, #1
	ldr	r0, [r3, #8]
	lsrs	r0, r0, #1
	str	r0, [r3, #8]
	cmp	r0, #0
	beq	.L080EA6B4
	cmp	r5, #9
	ble	.L080EA5EE
	b	.L080EA6B4
.L080EA612:
	lsls	r0, r4, #0x18
	lsrs	r2, r0, #0x18
	ldr	r0, [r3, #8]
	cmp	r0, #0
	beq	.L080EA6B4
	movs	r4, #1
	adds	r1, #8
.L080EA620:
	ands	r0, r4
	cmp	r0, #0
	beq	.L080EA630
	ldr	r0, [r1]
	cmp	r0, #0
	beq	.L080EA630
	adds	r0, #0x4e
	strb	r2, [r0]
.L080EA630:
	adds	r1, #4
	adds	r5, #1
	ldr	r0, [r3, #8]
	lsrs	r0, r0, #1
	str	r0, [r3, #8]
	cmp	r0, #0
	beq	.L080EA6B4
	cmp	r5, #9
	ble	.L080EA620
	b	.L080EA6B4
.L080EA644:
	movs	r0, #0xff
	lsls	r0, r0, #8
	ands	r0, r4
	lsrs	r2, r0, #8
	lsls	r0, r4, #0x18
	lsrs	r4, r0, #0x18
	ldr	r0, [r3, #8]
	cmp	r0, #0
	beq	.L080EA6B4
	movs	r6, #1
	adds	r1, #8
.L080EA65A:
	ands	r0, r6
	cmp	r0, #0
	beq	.L080EA670
	ldr	r0, [r1]
	cmp	r0, #0
	beq	.L080EA670
	adds	r0, #0x50
	strb	r2, [r0]
	ldr	r0, [r1]
	adds	r0, #0x4f
	strb	r4, [r0]
.L080EA670:
	adds	r1, #4
	adds	r5, #1
	ldr	r0, [r3, #8]
	lsrs	r0, r0, #1
	str	r0, [r3, #8]
	cmp	r0, #0
	beq	.L080EA6B4
	cmp	r5, #9
	ble	.L080EA65A
	b	.L080EA6B4
.L080EA684:
	lsls	r0, r4, #0x18
	lsrs	r2, r0, #0x18
	ldr	r0, [r3, #8]
	cmp	r0, #0
	beq	.L080EA6B4
	movs	r4, #1
	adds	r1, #8
.L080EA692:
	ands	r0, r4
	cmp	r0, #0
	beq	.L080EA6A2
	ldr	r0, [r1]
	cmp	r0, #0
	beq	.L080EA6A2
	adds	r0, #0x4b
	strb	r2, [r0]
.L080EA6A2:
	adds	r1, #4
	adds	r5, #1
	ldr	r0, [r3, #8]
	lsrs	r0, r0, #1
	str	r0, [r3, #8]
	cmp	r0, #0
	beq	.L080EA6B4
	cmp	r5, #9
	ble	.L080EA692
.L080EA6B4:
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ cmdMask   (080EA6BC)
@
@   void cmdMask(SndCmd *c)             /* commands 0x200-0x201: b = player mask */
@   {
@       for (i = 0; c->b && i < 20; i++, c->b >>= 1)
@           if (c->b & 1) {
@               if (c->op == 0x200) playerFadeOut(i, c->a);
@               else if (c->op == 0x201) playerSetPause(i, c->a);
@           }
@   }
@ ======================================================================================
	.global cmdMask
	.thumb_func
cmdMask:
	push	{r4, r5, lr}
	adds	r4, r0, #0
	movs	r5, #0
	ldrh	r1, [r4]
	movs	r0, #0x80
	lsls	r0, r0, #2
	cmp	r1, r0
	beq	.L080EA6D4
	adds	r0, #1
	cmp	r1, r0
	beq	.L080EA6FE
	b	.L080EA726
.L080EA6D4:
	ldr	r1, [r4, #8]
	cmp	r1, #0
	beq	.L080EA726
.L080EA6DA:
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L080EA6EA
	ldr	r1, [r4, #4]
	adds	r0, r5, #0
	bl	playerFadeOut
.L080EA6EA:
	adds	r5, #1
	ldr	r0, [r4, #8]
	lsrs	r0, r0, #1
	str	r0, [r4, #8]
	adds	r1, r0, #0
	cmp	r1, #0
	beq	.L080EA726
	cmp	r5, #0x13
	ble	.L080EA6DA
	b	.L080EA726
.L080EA6FE:
	ldr	r1, [r4, #8]
	cmp	r1, #0
	beq	.L080EA726
.L080EA704:
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L080EA714
	ldrb	r1, [r4, #4]
	adds	r0, r5, #0
	bl	playerSetPause
.L080EA714:
	adds	r5, #1
	ldr	r0, [r4, #8]
	lsrs	r0, r0, #1
	str	r0, [r4, #8]
	adds	r1, r0, #0
	cmp	r1, #0
	beq	.L080EA726
	cmp	r5, #0x13
	ble	.L080EA704
.L080EA726:
	pop	{r4, r5}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ cmdGlobal   (080EA72C)
@
@   void cmdGlobal(SndCmd *c)           /* commands 0x300-0x304 */
@   {
@       switch (c->op) {
@       case 0x300: echoSetFeedback(c->a); break;
@       case 0x301: ((void (*)(u32))c->a)(c->b); break;
@       case 0x302: gHookCA = (void *)c->a; break;
@       case 0x303: gHookNote = (void *)c->a; break;
@       case 0x304: voiceSetCount(c->a); break;
@       }
@   }
@ ======================================================================================
	.global cmdGlobal
	.thumb_func
cmdGlobal:
	push	{lr}
	adds	r2, r0, #0
	ldrh	r0, [r2]
	ldr	r1, .P080EA744	@ =0xFFFFFD00
	adds	r0, r0, r1
	cmp	r0, #4
	bhi	.L080EA78E
	lsls	r0, r0, #2
	ldr	r1, .P080EA748	@ =0x080EA74C
	adds	r0, r0, r1
	ldr	r0, [r0]
	mov	pc, r0
.P080EA744:	.word 0xFFFFFD00
.P080EA748:	.word 0x080EA74C
	.word .L080EA780
	.word .L080EA760
	.word .L080EA76A
	.word .L080EA774
	.word .L080EA788
.L080EA760:
	ldr	r0, [r2, #8]
	ldr	r1, [r2, #4]
	bl	_call_via_r1
	b	.L080EA78E
.L080EA76A:
	ldr	r1, .P080EA770	@ =gHookCA
	b	.L080EA776
	.hword 0x0000
.P080EA770:	.word gHookCA
.L080EA774:
	ldr	r1, .P080EA77C	@ =gHookNote
.L080EA776:
	ldr	r0, [r2, #4]
	str	r0, [r1]
	b	.L080EA78E
.P080EA77C:	.word gHookNote
.L080EA780:
	ldrb	r0, [r2, #4]
	bl	echoSetFeedback
	b	.L080EA78E
.L080EA788:
	ldrb	r0, [r2, #4]
	bl	voiceSetCount
.L080EA78E:
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ cmdProcess   (080EA794)
@
@   void cmdProcess(void)
@   {
@       for (SndCmd *c; (c = cmdPop()); )
@           kCmdHandlers[c->op >> 8](c);   /* cmdPlayer, cmdTrack, cmdMask, cmdGlobal (no range check) */
@   }
@ ======================================================================================
	.global cmdProcess
	.thumb_func
cmdProcess:
	push	{r4, lr}
	bl	cmdPop
	adds	r2, r0, #0
	cmp	r2, #0
	beq	.L080EA7BC
	ldr	r4, .P080EA7C4	@ =kCmdHandlers
.L080EA7A2:
	ldrh	r0, [r2]
	lsrs	r0, r0, #8
	lsls	r0, r0, #2
	adds	r0, r0, r4
	ldr	r1, [r0]
	adds	r0, r2, #0
	bl	_call_via_r1
	bl	cmdPop
	adds	r2, r0, #0
	cmp	r2, #0
	bne	.L080EA7A2
.L080EA7BC:
	pop	{r4}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P080EA7C4:	.word kCmdHandlers
	.arm

@ ======================================================================================
@ armDownmix   (080EA7C8)
@
@   /* ARM, runs from IWRAM.  16-bit mix accumulator -> 8-bit output, with saturation:
@      out = clamp(x / 128, -128, 127)   (division rounds towards zero) */
@   void armDownmix(const s16 *src, s8 *dst, const s16 *end)
@   {
@       do {                                   /* unrolled x8 */
@           s32 x = *src++;
@           x = (x < 0 ? x + 127 : x) >> 7;
@           if ((x & 0xFF80) && (x & 0xFF80) != 0xFF80) x = 127 + ((u32)x >> 31);   /* 127 / -128 */
@           *dst++ = x;
@       } while (src != end);
@   }
@ ======================================================================================
	.global armDownmix
	.type armDownmix, %function
armDownmix:
	push	{r4, r5}
	mov	r4, #0x7f
	mov	r5, #0xff00
	orr	r5, r5, #0x80
.L080EA7D8:
	ldrsh	r3, [r0], #2
	cmp	r3, #0
	addmi	r3, r3, #0x7f
	asr	r3, r3, #7
	ands	ip, r3, r5
	cmpne	ip, r5
	addne	r3, r4, r3, lsr #31
	strb	r3, [r1], #1
	ldrsh	r3, [r0], #2
	cmp	r3, #0
	addmi	r3, r3, #0x7f
	asr	r3, r3, #7
	ands	ip, r3, r5
	cmpne	ip, r5
	addne	r3, r4, r3, lsr #31
	strb	r3, [r1], #1
	ldrsh	r3, [r0], #2
	cmp	r3, #0
	addmi	r3, r3, #0x7f
	asr	r3, r3, #7
	ands	ip, r3, r5
	cmpne	ip, r5
	addne	r3, r4, r3, lsr #31
	strb	r3, [r1], #1
	ldrsh	r3, [r0], #2
	cmp	r3, #0
	addmi	r3, r3, #0x7f
	asr	r3, r3, #7
	ands	ip, r3, r5
	cmpne	ip, r5
	addne	r3, r4, r3, lsr #31
	strb	r3, [r1], #1
	ldrsh	r3, [r0], #2
	cmp	r3, #0
	addmi	r3, r3, #0x7f
	asr	r3, r3, #7
	ands	ip, r3, r5
	cmpne	ip, r5
	addne	r3, r4, r3, lsr #31
	strb	r3, [r1], #1
	ldrsh	r3, [r0], #2
	cmp	r3, #0
	addmi	r3, r3, #0x7f
	asr	r3, r3, #7
	ands	ip, r3, r5
	cmpne	ip, r5
	addne	r3, r4, r3, lsr #31
	strb	r3, [r1], #1
	ldrsh	r3, [r0], #2
	cmp	r3, #0
	addmi	r3, r3, #0x7f
	asr	r3, r3, #7
	ands	ip, r3, r5
	cmpne	ip, r5
	addne	r3, r4, r3, lsr #31
	strb	r3, [r1], #1
	ldrsh	r3, [r0], #2
	cmp	r3, #0
	addmi	r3, r3, #0x7f
	asr	r3, r3, #7
	ands	ip, r3, r5
	cmpne	ip, r5
	addne	r3, r4, r3, lsr #31
	strb	r3, [r1], #1
	cmp	r0, r2
	bne	.L080EA7D8
	pop	{r4, r5}
	bx	lr

@ ======================================================================================
@ armMixVoice   (080EA8E8)
@
@   /* ARM, runs from IWRAM.  Add a sample to the left and right accumulators without
@      interpolation: pos is 24.8, the sample is s8, gains are 8-bit.  Unrolled x4 when the
@      count is a multiple of 4.  Returns the new position. */
@   u32 armMixVoice(const s8 *pcm, s16 *l, s16 *r, s16 *lEnd, u32 pos, u32 step, u32 vl, u32 vr)
@   {
@       while (l < lEnd) {
@           s32 s = pcm[pos >> 8];
@           *l++ += vl * s;  *r++ += vr * s;
@           pos += step;
@       }
@       return pos;
@   }
@ ======================================================================================
	.global armMixVoice
	.type armMixVoice, %function
armMixVoice:
	mov	ip, sp
	push	{r4, r5, r6, r7, r8}
	ldm	ip, {r4, r5, r6, r7}
	sub	ip, r3, r1
	and	ip, ip, #7
	cmp	ip, #0
	bne	.L080EA9A8
.L080EA904:
	add	ip, r0, r4, lsr #8
	ldrsb	r8, [ip]
	ldrsh	ip, [r1]
	mla	ip, r6, r8, ip
	strh	ip, [r1], #2
	ldrsh	ip, [r2]
	mla	ip, r7, r8, ip
	strh	ip, [r2], #2
	add	r4, r4, r5
	add	ip, r0, r4, lsr #8
	ldrsb	r8, [ip]
	ldrsh	ip, [r1]
	mla	ip, r6, r8, ip
	strh	ip, [r1], #2
	ldrsh	ip, [r2]
	mla	ip, r7, r8, ip
	strh	ip, [r2], #2
	add	r4, r4, r5
	add	ip, r0, r4, lsr #8
	ldrsb	r8, [ip]
	ldrsh	ip, [r1]
	mla	ip, r6, r8, ip
	strh	ip, [r1], #2
	ldrsh	ip, [r2]
	mla	ip, r7, r8, ip
	strh	ip, [r2], #2
	add	r4, r4, r5
	add	ip, r0, r4, lsr #8
	ldrsb	r8, [ip]
	ldrsh	ip, [r1]
	mla	ip, r6, r8, ip
	strh	ip, [r1], #2
	ldrsh	ip, [r2]
	mla	ip, r7, r8, ip
	strh	ip, [r2], #2
	add	r4, r4, r5
	cmp	r1, r3
	blo	.L080EA904
	mov	r0, r4
	pop	{r4, r5, r6, r7, r8}
	bx	lr
.L080EA9A8:
	add	ip, r0, r4, lsr #8
	ldrsb	r8, [ip]
	ldrsh	ip, [r1]
	mla	ip, r6, r8, ip
	strh	ip, [r1], #2
	ldrsh	ip, [r2]
	mla	ip, r7, r8, ip
	strh	ip, [r2], #2
	add	r4, r4, r5
	cmp	r1, r3
	blo	.L080EA9A8
	mov	r0, r4
	pop	{r4, r5, r6, r7, r8}
	bx	lr

@ ======================================================================================
@ armEcho   (080EA9E0)
@
@   /* ARM, runs from IWRAM.  dry += wet; wet = wet >> shift (rounding towards zero). */
@   void armEcho(s16 *dry, s16 *wet, const s16 *dryEnd, u32 shift)
@   {
@       do { s16 w = *wet; *dry++ += w; *wet++ = (w < 0 ? w + (1 << shift) - 1 : w) >> shift; }
@       while (dry < dryEnd);          /* unrolled x4 */
@   }
@ ======================================================================================
	.global armEcho
	.type armEcho, %function
armEcho:
	push	{r4, r5}
	mov	r4, #1
	lsl	r4, r4, r3
	sub	r4, r4, #1
.L080EA9F0:
	ldrsh	r5, [r0]
	ldrsh	ip, [r1]
	add	r5, r5, ip
	strh	r5, [r0], #2
	cmp	ip, #0
	addmi	ip, ip, r4
	asr	ip, ip, r3
	strh	ip, [r1], #2
	ldrsh	r5, [r0]
	ldrsh	ip, [r1]
	add	r5, r5, ip
	strh	r5, [r0], #2
	cmp	ip, #0
	addmi	ip, ip, r4
	asr	ip, ip, r3
	strh	ip, [r1], #2
	ldrsh	r5, [r0]
	ldrsh	ip, [r1]
	add	r5, r5, ip
	strh	r5, [r0], #2
	cmp	ip, #0
	addmi	ip, ip, r4
	asr	ip, ip, r3
	strh	ip, [r1], #2
	ldrsh	r5, [r0]
	ldrsh	ip, [r1]
	add	r5, r5, ip
	strh	r5, [r0], #2
	cmp	ip, #0
	addmi	ip, ip, r4
	asr	ip, ip, r3
	strh	ip, [r1], #2
	cmp	r0, r2
	blo	.L080EA9F0
	pop	{r4, r5}
	bx	lr
