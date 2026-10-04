@ --------------------------------------------------------------------------------------
@ sma2_sound.s - sound driver of Super Mario Advance 2 (E), main program
@ Thumb code 0809C5A0-0809E8D4, ARM mixing loops 0809E8D4-0809EBB4 (copied to IWRAM by sndInit).
@ Generated from the ROM by gen_sources.py; names and comments from the analysis.
@ The pseudo-C above each function describes the Super Mario Advance 4 build; where this
@ build differs, the difference is given after "In this build".
@ Rebuilds byte-identical: see Makefile.
@ --------------------------------------------------------------------------------------
	.syntax unified
	.equ GEN_A, 1
	.include "nsnd.inc"
	.include "sma2_ram.inc"
	.section .snd_code, "ax"
	.thumb

@ ======================================================================================
@ sndInit   (0809C5A0)
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
	ldr	r1, .P0809C62C	@ =gCfg
	str	r0, [r1]
	ldr	r1, .P0809C630	@ =REG_SOUNDCNT_X
	movs	r0, #0
	strb	r0, [r1]
	movs	r0, #0x80
	strb	r0, [r1]
	subs	r1, #4
	ldr	r2, .P0809C634	@ =0x0000FF77
	adds	r0, r2, #0
	strh	r0, [r1]
	adds	r1, #2
	movs	r0, #0xd
	strb	r0, [r1]
	ldr	r2, .P0809C638	@ =REG_SOUNDBIAS
	ldrh	r1, [r2]
	ldr	r0, .P0809C63C	@ =0x00003FFF
	ands	r0, r1
	movs	r3, #0x80
	lsls	r3, r3, #7
	adds	r1, r3, #0
	orrs	r0, r1
	strh	r0, [r2]
	ldr	r1, .P0809C640	@ =REG_NR10
	movs	r0, #8
	strh	r0, [r1]
	adds	r1, #2
	movs	r2, #0xf0
	lsls	r2, r2, #8
	adds	r0, r2, #0
	strh	r0, [r1]
	ldr	r5, .P0809C644	@ =armDownmix
	ldr	r4, .P0809C648	@ =gIwramCode
	adds	r0, r5, #0
	adds	r1, r4, #0
	movs	r2, #0xd8
	bl	CpuFastSet
	ldr	r0, .P0809C64C	@ =gFnDownmix
	str	r4, [r0]
	ldr	r1, .P0809C650	@ =gFnMixVoice
	ldr	r0, .P0809C654	@ =armMixVoice
	subs	r0, r0, r5
	adds	r0, r0, r4
	str	r0, [r1]
	ldr	r1, .P0809C658	@ =gFnEcho
	ldr	r0, .P0809C65C	@ =armEcho
	subs	r0, r0, r5
	adds	r0, r0, r4
	str	r0, [r1]
	ldr	r1, .P0809C660	@ =gEchoHistory
	ldr	r0, .P0809C664	@ =0x02036000
	str	r0, [r1]
	ldr	r0, .P0809C668	@ =gDmaBuffers
	bl	mixInit
	bl	cmdInit
	bl	kitInstInit
	bl	voiceInitAll
	bl	trackInitAll
	bl	playerInitAll
	pop	{r4, r5}
	pop	{r0}
	bx	r0
.P0809C62C:	.word gCfg
.P0809C630:	.word REG_SOUNDCNT_X
.P0809C634:	.word 0x0000FF77
.P0809C638:	.word REG_SOUNDBIAS
.P0809C63C:	.word 0x00003FFF
.P0809C640:	.word REG_NR10
.P0809C644:	.word armDownmix
.P0809C648:	.word gIwramCode
.P0809C64C:	.word gFnDownmix
.P0809C650:	.word gFnMixVoice
.P0809C654:	.word armMixVoice
.P0809C658:	.word gFnEcho
.P0809C65C:	.word armEcho
.P0809C660:	.word gEchoHistory
.P0809C664:	.word 0x02036000
.P0809C668:	.word gDmaBuffers

@ ======================================================================================
@ sndVSync   (0809C66C)
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
@ sndMain   (0809C678)
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
	ldr	r0, .P0809C698	@ =gMixEnabled
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L0809C692
	bl	mixFrame
.L0809C692:
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0809C698:	.word gMixEnabled

@ ======================================================================================
@ mixInit   (0809C69C)
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
@
@   In this build: Same, but only the echo history is cleared; the DMA buffer is not (the first frame can play
@   whatever was in IWRAM).
@ ======================================================================================
	.global mixInit
	.thumb_func
mixInit:
	push	{r4, r5, lr}
	sub	sp, #8
	adds	r5, r0, #0
	ldr	r1, .P0809C6F8	@ =gMixEnabled
	movs	r0, #1
	strb	r0, [r1]
	movs	r4, #0
	str	r4, [sp, #4]
	add	r0, sp, #4
	ldr	r1, .P0809C6FC	@ =gEchoHistory
	ldr	r1, [r1]
	ldr	r2, .P0809C700	@ =0x01000C60
	bl	CpuFastSet
	ldr	r1, .P0809C704	@ =gDmaBufA
	str	r5, [r1]
	ldr	r2, .P0809C708	@ =gDmaBufB
	adds	r0, r5, #0
	adds	r0, #0xb0
	str	r0, [r2]
	movs	r3, #0xb0
	lsls	r3, r3, #1
	adds	r0, r5, r3
	str	r0, [r1, #4]
	movs	r1, #0x84
	lsls	r1, r1, #2
	adds	r0, r5, r1
	str	r0, [r2, #4]
	ldr	r1, .P0809C70C	@ =gTimerReload
	ldr	r2, .P0809C710	@ =0x0000F9C4
	adds	r0, r2, #0
	strh	r0, [r1]
	ldr	r0, .P0809C714	@ =gDmaBufIdx
	strb	r4, [r0]
	ldr	r1, .P0809C718	@ =REG_SOUNDCNT_H+1
	movs	r0, #0x9a
	strb	r0, [r1]
	ldr	r0, .P0809C71C	@ =REG_FIFO_A
	str	r4, [r0]
	adds	r0, #4
	str	r4, [r0]
	add	sp, #8
	pop	{r4, r5}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0809C6F8:	.word gMixEnabled
.P0809C6FC:	.word gEchoHistory
.P0809C700:	.word 0x01000C60
.P0809C704:	.word gDmaBufA
.P0809C708:	.word gDmaBufB
.P0809C70C:	.word gTimerReload
.P0809C710:	.word 0x0000F9C4
.P0809C714:	.word gDmaBufIdx
.P0809C718:	.word REG_SOUNDCNT_H+1
.P0809C71C:	.word REG_FIFO_A

@ ======================================================================================
@ mixDmaRestart   (0809C720)
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
	ldr	r2, .P0809C79C	@ =REG_TM0CNT
	ldr	r0, .P0809C7A0	@ =gTimerReload
	ldrh	r0, [r0]
	movs	r1, #0x80
	lsls	r1, r1, #0x10
	orrs	r0, r1
	str	r0, [r2]
	ldr	r0, .P0809C7A4	@ =gMixEnabled
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L0809C794
	ldr	r4, .P0809C7A8	@ =REG_DMA1SAD
	ldrh	r1, [r4, #0xa]
	ldr	r2, .P0809C7AC	@ =0x0000C5FF
	adds	r0, r2, #0
	ands	r0, r1
	strh	r0, [r4, #0xa]
	ldrh	r3, [r4, #0xa]
	ldr	r1, .P0809C7B0	@ =0x00007FFF
	adds	r0, r1, #0
	ands	r0, r3
	strh	r0, [r4, #0xa]
	ldrh	r0, [r4, #0xa]
	ldr	r3, .P0809C7B4	@ =REG_DMA2SAD
	ldrh	r0, [r3, #0xa]
	ands	r2, r0
	strh	r2, [r3, #0xa]
	ldrh	r0, [r3, #0xa]
	ands	r1, r0
	strh	r1, [r3, #0xa]
	ldrh	r0, [r3, #0xa]
	ldr	r1, .P0809C7B8	@ =gDmaBufA
	ldr	r2, .P0809C7BC	@ =gDmaBufIdx
	ldrb	r0, [r2]
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r0, [r0]
	str	r0, [r4]
	ldr	r0, .P0809C7C0	@ =REG_FIFO_A
	str	r0, [r4, #4]
	ldr	r5, .P0809C7C4	@ =0xB6400004
	str	r5, [r4, #8]
	ldr	r0, [r4, #8]
	ldr	r1, .P0809C7C8	@ =gDmaBufB
	ldrb	r0, [r2]
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r0, [r0]
	str	r0, [r3]
	ldr	r0, .P0809C7CC	@ =REG_FIFO_B
	str	r0, [r3, #4]
	str	r5, [r3, #8]
	ldr	r0, [r3, #8]
	ldrb	r1, [r2]
	movs	r0, #1
	subs	r0, r0, r1
	strb	r0, [r2]
.L0809C794:
	pop	{r4, r5}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0809C79C:	.word REG_TM0CNT
.P0809C7A0:	.word gTimerReload
.P0809C7A4:	.word gMixEnabled
.P0809C7A8:	.word REG_DMA1SAD
.P0809C7AC:	.word 0x0000C5FF
.P0809C7B0:	.word 0x00007FFF
.P0809C7B4:	.word REG_DMA2SAD
.P0809C7B8:	.word gDmaBufA
.P0809C7BC:	.word gDmaBufIdx
.P0809C7C0:	.word REG_FIFO_A
.P0809C7C4:	.word 0xB6400004
.P0809C7C8:	.word gDmaBufB
.P0809C7CC:	.word REG_FIFO_B

@ ======================================================================================
@ sndStopOutput   (0809C7D0)
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
	ldr	r1, .P0809C808	@ =gMixEnabled
	movs	r0, #0
	strb	r0, [r1]
	ldr	r1, .P0809C80C	@ =REG_DMA1SAD
	ldrh	r2, [r1, #0xa]
	ldr	r3, .P0809C810	@ =0x0000C5FF
	adds	r0, r3, #0
	ands	r0, r2
	strh	r0, [r1, #0xa]
	ldrh	r4, [r1, #0xa]
	ldr	r2, .P0809C814	@ =0x00007FFF
	adds	r0, r2, #0
	ands	r0, r4
	strh	r0, [r1, #0xa]
	ldrh	r0, [r1, #0xa]
	ldr	r0, .P0809C818	@ =REG_DMA2SAD
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
.P0809C808:	.word gMixEnabled
.P0809C80C:	.word REG_DMA1SAD
.P0809C810:	.word 0x0000C5FF
.P0809C814:	.word 0x00007FFF
.P0809C818:	.word REG_DMA2SAD

@ ======================================================================================
@ sndStartOutput   (0809C81C)
@
@   void sndStartOutput(void)
@   {
@       gMixEnabled = 1;        /* DMA restarts at the next sndVSync */
@   }
@ ======================================================================================
	.global sndStartOutput
	.thumb_func
sndStartOutput:
	ldr	r1, .P0809C824	@ =gMixEnabled
	movs	r0, #1
	strb	r0, [r1]
	bx	lr
.P0809C824:	.word gMixEnabled

@ ======================================================================================
@ mixVoice   (0809C828)
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
@
@   In this build: Differences:
@     * The wet bus is used whenever the track has echo on (the echo is always running).
@     * Gains are twice as large: volL = vol * (127 - pan) >> 7, volR = vol * pan >> 7; the ARM loop
@       then shifts each product right by 8 (see armMixVoice).
@     * Counts are divided with __udivsi3 instead of the BIOS Div call.
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
	movs	r0, #0
	mov	sb, r0
	movs	r1, #0xb0
	str	r1, [sp, #0x1c]
	ldr	r2, [sp, #0x10]
	ldr	r1, [r2, #0x5c]
	adds	r0, r1, #0
	adds	r0, #0x10
	str	r0, [sp, #0x20]
	ldrb	r0, [r2, #0x1a]
	ldr	r2, .P0809C8A4	@ =gMixDry
	str	r2, [sp, #0x14]
	cmp	r0, #0
	beq	.L0809C864
	ldr	r0, .P0809C8A8	@ =gMixWet
	str	r0, [sp, #0x14]
.L0809C864:
	ldr	r2, [sp, #0x14]
	movs	r0, #0xb0
	lsls	r0, r0, #1
	adds	r2, r2, r0
	mov	r8, r2
	movs	r0, #0x7f
	subs	r0, r0, r3
	mov	r2, sl
	muls	r2, r0, r2
	adds	r0, r2, #0
	lsls	r0, r0, #0x10
	lsrs	r0, r0, #0x17
	str	r0, [sp, #0x18]
	mov	r0, sl
	muls	r0, r3, r0
	lsls	r0, r0, #0x10
	lsrs	r0, r0, #0x17
	mov	sl, r0
	ldr	r7, [r1, #0xc]
	cmp	r7, #0
	bne	.L0809C890
	ldr	r7, [r1]
.L0809C890:
	ldr	r1, [sp, #0x1c]
	adds	r0, r6, #0
	muls	r0, r1, r0
	adds	r0, r4, r0
	lsrs	r0, r0, #8
	cmp	r0, r7
	bhs	.L0809C8AC
	mov	r5, r8
	b	.L0809C8C4
	.hword 0x0000
.P0809C8A4:	.word gMixDry
.P0809C8A8:	.word gMixWet
.L0809C8AC:
	lsls	r0, r7, #8
	subs	r0, r0, r4
	subs	r0, #1
	adds	r0, r0, r6
	adds	r1, r6, #0
	bl	__udivsi3
	lsls	r0, r0, #1
	ldr	r2, [sp, #0x14]
	adds	r5, r2, r0
	movs	r0, #1
	mov	sb, r0
.L0809C8C4:
	ldr	r1, [sp, #0x10]
	ldr	r0, [r1, #0x5c]
	ldr	r1, [r0, #0xc]
	cmp	r1, #0
	beq	.L0809C8D4
	mov	r2, sb
	cmp	r2, #0
	bne	.L0809C900
.L0809C8D4:
	ldr	r0, .P0809C8FC	@ =gFnMixVoice
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
	beq	.L0809C9AE
	movs	r0, #1
	b	.L0809C9B4
.P0809C8FC:	.word gFnMixVoice
.L0809C900:
	ldr	r0, [r0, #8]
	subs	r1, r1, r0
	lsls	r1, r1, #8
	str	r1, [sp, #0x24]
	ldr	r1, .P0809C95C	@ =gFnMixVoice
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
	beq	.L0809C9AE
.L0809C93A:
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
	bhs	.L0809C960
	lsls	r0, r1, #1
	adds	r5, r5, r0
	movs	r2, #0
	mov	sb, r2
	b	.L0809C976
.P0809C95C:	.word gFnMixVoice
.L0809C960:
	lsls	r0, r7, #8
	subs	r0, r0, r4
	subs	r0, #1
	adds	r0, r0, r6
	adds	r1, r6, #0
	bl	__udivsi3
	lsls	r0, r0, #1
	adds	r5, r5, r0
	movs	r0, #1
	mov	sb, r0
.L0809C976:
	str	r4, [sp]
	str	r6, [sp, #4]
	ldr	r1, [sp, #0x18]
	str	r1, [sp, #8]
	mov	r2, sl
	str	r2, [sp, #0xc]
	ldr	r0, .P0809C9C4	@ =gFnMixVoice
	ldr	r4, [r0]
	ldr	r0, [sp, #0x20]
	ldr	r1, [sp, #0x14]
	mov	r2, r8
	adds	r3, r5, #0
	bl	_call_via_r4
	adds	r4, r0, #0
	mov	r1, sb
	cmp	r1, #0
	beq	.L0809C99E
	ldr	r2, [sp, #0x24]
	subs	r4, r4, r2
.L0809C99E:
	ldr	r1, [sp, #0x14]
	subs	r0, r5, r1
	asrs	r0, r0, #1
	ldr	r2, [sp, #0x1c]
	subs	r2, r2, r0
	str	r2, [sp, #0x1c]
	cmp	r2, #0
	bne	.L0809C93A
.L0809C9AE:
	ldr	r0, [sp, #0x10]
	str	r4, [r0, #0x60]
	movs	r0, #0
.L0809C9B4:
	add	sp, #0x28
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	sb, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1
.P0809C9C4:	.word gFnMixVoice

@ ======================================================================================
@ kitInstInit   (0809C9C8)
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
	ldr	r1, .P0809C9E0	@ =gKitInst
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
.P0809C9E0:	.word gKitInst

@ ======================================================================================
@ instLookup   (0809C9E4)
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
	ldr	r1, .P0809CA4C	@ =gCfg
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
	beq	.L0809CA94
	adds	r0, r1, #0
	cmp	r0, #0x10
	bne	.L0809CA50
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
	b	.L0809CA98
.P0809CA4C:	.word gCfg
.L0809CA50:
	cmp	r0, #0x11
	bne	.L0809CA78
	ldrh	r1, [r5, #2]
	adds	r1, r3, r1
	ldr	r2, .P0809CA70	@ =gKitInst
	lsls	r0, r6, #1
	adds	r0, r0, r1
	ldrh	r0, [r0]
	strh	r0, [r2, #2]
	str	r2, [r4]
	ldr	r0, .P0809CA74	@ =kFlatEnvelope
	str	r0, [r4, #4]
	movs	r0, #1
	strb	r0, [r4, #0x12]
	b	.L0809CA9C
	.hword 0x0000
.P0809CA70:	.word gKitInst
.P0809CA74:	.word kFlatEnvelope
.L0809CA78:
	cmp	r0, #0x12
	bne	.L0809CA9C
	ldrh	r0, [r5, #2]
	adds	r0, r3, r0
	b	.L0809CA84
.L0809CA82:
	adds	r0, #4
.L0809CA84:
	ldrb	r1, [r0]
	cmp	r6, r1
	bhi	.L0809CA82
	ldrh	r0, [r0, #2]
	adds	r0, r3, r0
	str	r0, [r4]
	ldrh	r0, [r0, #4]
	b	.L0809CA98
.L0809CA94:
	str	r5, [r4]
	ldrh	r0, [r5, #4]
.L0809CA98:
	adds	r0, r3, r0
	str	r0, [r4, #4]
.L0809CA9C:
	ldr	r2, [r4]
	ldrb	r0, [r2]
	cmp	r0, #3
	bne	.L0809CAAA
	ldrh	r0, [r5, #2]
	adds	r0, r3, r0
	str	r0, [r4, #0xc]
.L0809CAAA:
	ldrb	r1, [r2, #1]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0809CABA
	ldrh	r0, [r2, #2]
	adds	r0, r3, r0
	str	r0, [r4, #8]
.L0809CABA:
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ voiceInitAll   (0809CAC0)
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
@
@   In this build: The voice lists are circular with sentinel nodes: gActiveHead/gActiveTail and gFreeHead/gFreeTail
@   are whole (unused) Voice structures, so every list operation is two pointer writes and no NULL
@   tests.  All seven voices start on the free list.  There is no gReservedVoices and no voice count.
@   Echo: gEchoLen = 18, gEchoShift = gEchoShiftTarget = 31 (see armEcho: a shift of 31 makes the
@   feedback zero, so the echo is inaudible until a game command lowers it).
@ ======================================================================================
	.global voiceInitAll
	.thumb_func
voiceInitAll:
	push	{r4, r5, r6, r7, lr}
	mov	r7, sl
	mov	r6, sb
	mov	r5, r8
	push	{r5, r6, r7}
	ldr	r1, .P0809CC48	@ =gLastWave
	movs	r0, #0
	str	r0, [r1]
	adds	r3, r1, #0
	ldr	r2, .P0809CC4C	@ =gPsgVoices
	ldr	r0, .P0809CC50	@ =gDsVoices
	mov	ip, r0
	movs	r1, #0xb6
	lsls	r1, r1, #1
	adds	r7, r3, r1
	ldr	r0, .P0809CC54	@ =gEchoPos
	mov	sb, r0
	ldr	r1, .P0809CC58	@ =gEchoLen
	mov	sl, r1
	movs	r1, #0
	adds	r0, r2, #1
	movs	r4, #3
.L0809CAEC:
	strb	r1, [r0]
	strb	r1, [r0, #3]
	strb	r1, [r0, #4]
	strb	r1, [r0, #5]
	strb	r1, [r0, #6]
	adds	r0, #0x78
	subs	r4, #1
	cmp	r4, #0
	bge	.L0809CAEC
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
	ldr	r0, .P0809CC50	@ =gDsVoices
	movs	r4, #6
.L0809CB20:
	strb	r1, [r0, #1]
	strb	r1, [r0]
	strb	r1, [r0, #4]
	strb	r1, [r0, #5]
	strb	r1, [r0, #6]
	strb	r1, [r0, #7]
	adds	r0, #0x78
	subs	r4, #1
	cmp	r4, #0
	bge	.L0809CB20
	movs	r2, #0xb0
	lsls	r2, r2, #1
	adds	r0, r3, r2
	mov	r1, ip
	str	r1, [r0]
	adds	r1, #0x78
	mov	r0, ip
	adds	r0, #0x6c
	strb	r1, [r0]
	lsrs	r0, r1, #8
	mov	r2, ip
	adds	r2, #0x6d
	strb	r0, [r2]
	lsrs	r0, r1, #0x10
	adds	r2, #1
	strb	r0, [r2]
	lsrs	r1, r1, #0x18
	mov	r0, ip
	adds	r0, #0x6f
	strb	r1, [r0]
	adds	r1, r3, #0
	adds	r1, #0xf4
	subs	r0, #7
	strb	r1, [r0]
	lsrs	r0, r1, #8
	subs	r2, #5
	strb	r0, [r2]
	lsrs	r0, r1, #0x10
	adds	r2, #1
	strb	r0, [r2]
	lsrs	r1, r1, #0x18
	mov	r0, ip
	adds	r0, #0x6b
	strb	r1, [r0]
	mov	r8, ip
	movs	r5, #0xff
	adds	r2, #0x76
	mov	r3, ip
	movs	r6, #0x78
	movs	r4, #4
.L0809CB84:
	mov	r1, r8
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
	bge	.L0809CB84
	movs	r3, #0
	movs	r0, #0xcf
	lsls	r0, r0, #2
	add	r0, ip
	strb	r7, [r0]
	lsrs	r1, r7, #8
	ldr	r0, .P0809CC5C	@ =0x0000033D
	add	r0, ip
	strb	r1, [r0]
	lsrs	r1, r7, #0x10
	ldr	r0, .P0809CC60	@ =0x0000033E
	add	r0, ip
	strb	r1, [r0]
	lsrs	r1, r7, #0x18
	ldr	r0, .P0809CC64	@ =0x0000033F
	add	r0, ip
	strb	r1, [r0]
	movs	r1, #0x96
	lsls	r1, r1, #2
	add	r1, ip
	movs	r0, #0xce
	lsls	r0, r0, #2
	add	r0, ip
	strb	r1, [r0]
	lsrs	r2, r1, #8
	ldr	r0, .P0809CC68	@ =0x00000339
	add	r0, ip
	strb	r2, [r0]
	lsrs	r2, r1, #0x10
	ldr	r0, .P0809CC6C	@ =0x0000033A
	add	r0, ip
	strb	r2, [r0]
	lsrs	r1, r1, #0x18
	ldr	r0, .P0809CC70	@ =0x0000033B
	add	r0, ip
	strb	r1, [r0]
	ldr	r2, .P0809CC74	@ =0xFFFFFE94
	adds	r1, r7, r2
	movs	r0, #0xb4
	lsls	r0, r0, #2
	add	r0, ip
	str	r0, [r7, #0x68]
	adds	r0, r7, #0
	subs	r0, #0xf0
	str	r0, [r1, #0x70]
	adds	r1, r7, #0
	subs	r1, #0x88
	adds	r2, #4
	adds	r0, r7, r2
	str	r0, [r1]
	mov	r0, sb
	strb	r3, [r0]
	movs	r0, #0x12
	mov	r1, sl
	strb	r0, [r1]
	movs	r0, #0x1f
	ldr	r2, .P0809CC78	@ =gEchoShift
	strb	r0, [r2]
	ldr	r1, .P0809CC7C	@ =gEchoShiftTarget
	strb	r0, [r1]
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	sb, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
.P0809CC48:	.word gLastWave
.P0809CC4C:	.word gPsgVoices
.P0809CC50:	.word gDsVoices
.P0809CC54:	.word gEchoPos
.P0809CC58:	.word gEchoLen
.P0809CC5C:	.word 0x0000033D
.P0809CC60:	.word 0x0000033E
.P0809CC64:	.word 0x0000033F
.P0809CC68:	.word 0x00000339
.P0809CC6C:	.word 0x0000033A
.P0809CC70:	.word 0x0000033B
.P0809CC74:	.word 0xFFFFFE94
.P0809CC78:	.word gEchoShift
.P0809CC7C:	.word gEchoShiftTarget

@ ======================================================================================
@ voiceUnlink   (0809CC80)
@
@   void voiceUnlink(Voice *v)          /* remove from whichever sentinel list holds it */
@   {
@       v->prev->next = v->next;
@       v->next->prev = v->prev;
@   }
@ ======================================================================================
	.global voiceUnlink
	.thumb_func
voiceUnlink:
	ldr	r2, [r0, #0x68]
	ldr	r1, [r0, #0x6c]
	str	r1, [r2, #0x6c]
	ldr	r1, [r0, #0x6c]
	ldr	r0, [r0, #0x68]
	str	r0, [r1, #0x68]
	bx	lr
	movs	r0, r0

@ ======================================================================================
@ voiceListInsertActive   (0809CC90)
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
@
@   In this build: Same ordering rule, written for the sentinel list: the new voice is inserted before the first
@   node that is past it (or before gActiveTail).
@ ======================================================================================
	.global voiceListInsertActive
	.thumb_func
voiceListInsertActive:
	push	{r4, lr}
	adds	r3, r0, #0
	ldr	r0, .P0809CCCC	@ =gLastWave
	ldr	r1, [r0, #0x70]
	ldrb	r2, [r3, #1]
	cmp	r2, #1
	bne	.L0809CCD4
	adds	r0, #0x7c
	cmp	r1, r0
	beq	.L0809CD04
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	bne	.L0809CCB2
	ldrb	r0, [r3, #8]
	ldrb	r2, [r1, #8]
	cmp	r0, r2
	blo	.L0809CD04
.L0809CCB2:
	ldr	r1, [r1, #0x6c]
	ldr	r0, .P0809CCD0	@ =gActiveTail
	cmp	r1, r0
	beq	.L0809CD04
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	bne	.L0809CCB2
	ldrb	r0, [r3, #8]
	ldrb	r4, [r1, #8]
	cmp	r0, r4
	bhs	.L0809CCB2
	b	.L0809CD04
	.hword 0x0000
.P0809CCCC:	.word gLastWave
.P0809CCD0:	.word gActiveTail
.L0809CCD4:
	cmp	r2, #2
	bne	.L0809CD10
	adds	r2, r0, #0
	adds	r2, #0x7c
	cmp	r1, r2
	beq	.L0809CD04
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	beq	.L0809CD04
	ldrb	r0, [r3, #8]
	ldrb	r4, [r1, #8]
	cmp	r0, r4
	blo	.L0809CD04
	adds	r4, r2, #0
	adds	r2, r0, #0
.L0809CCF2:
	ldr	r1, [r1, #0x6c]
	cmp	r1, r4
	beq	.L0809CD04
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	beq	.L0809CD04
	ldrb	r0, [r1, #8]
	cmp	r2, r0
	bhs	.L0809CCF2
.L0809CD04:
	str	r1, [r3, #0x6c]
	ldr	r0, [r1, #0x68]
	str	r0, [r3, #0x68]
	ldr	r0, [r1, #0x68]
	str	r3, [r0, #0x6c]
	str	r3, [r1, #0x68]
.L0809CD10:
	pop	{r4}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ keyToFreq   (0809CD18)
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
	bge	.L0809CD32
	movs	r2, #0
	b	.L0809CD38
.L0809CD32:
	cmp	r1, #0x77
	ble	.L0809CD38
	movs	r2, #0x78
.L0809CD38:
	ldrb	r0, [r0]
	cmp	r0, #0
	bne	.L0809CD50
	ldr	r0, .P0809CD4C	@ =kDsPitch
	lsls	r1, r2, #0x10
	asrs	r1, r1, #0xe
	adds	r1, r1, r0
	ldr	r0, [r1]
	b	.L0809CD68
	.hword 0x0000
.P0809CD4C:	.word kDsPitch
.L0809CD50:
	cmp	r0, #4
	beq	.L0809CD64
	ldr	r0, .P0809CD60	@ =kPsgFreq
	lsls	r1, r2, #0x10
	asrs	r1, r1, #0xf
	adds	r1, r1, r0
	ldrh	r0, [r1]
	b	.L0809CD68
.P0809CD60:	.word kPsgFreq
.L0809CD64:
	lsls	r0, r2, #0x10
	asrs	r0, r0, #0x10
.L0809CD68:
	bx	lr
	movs	r0, r0

@ ======================================================================================
@ noiseDivider   (0809CD6C)
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
	lsls	r0, r0, #0x10
	lsrs	r1, r0, #0x10
	cmp	r1, #0x77
	bls	.L0809CD76
	movs	r1, #0x77
.L0809CD76:
	ldr	r0, .P0809CD80	@ =kNoiseTable
	adds	r0, r1, r0
	ldrb	r0, [r0]
	bx	lr
	.hword 0x0000
.P0809CD80:	.word kNoiseTable

@ ======================================================================================
@ envStep   (0809CD84)
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
	bne	.L0809CDDE
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
	bge	.L0809CDB0
	strb	r1, [r4, #0x10]
.L0809CDB0:
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
.L0809CDDE:
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
@ echoSetFeedback   (0809CDF4)
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
	ldr	r1, .P0809CE00	@ =gEchoShiftTarget
	strb	r0, [r1]
	bx	lr
	.hword 0x0000
.P0809CE00:	.word gEchoShiftTarget

@ ======================================================================================
@ dsVolume   (0809CE04)
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
@
@   In this build: The player has no song volume (command EA does not exist) and the scaling differs:
@       x = (p->volume * v->velocity * 256) >> 7;
@       x = (x * p->volume2) >> 7;
@       x = (x * t->volume) >> 15;
@       x = (x * t->expression) >> 7;
@       v->volume = (envStep(v) * x) >> 15;
@   The release decay is the same.  v->velocity is at offset 9 in this build.
@ ======================================================================================
	.global dsVolume
	.thumb_func
dsVolume:
	push	{r4, r5, lr}
	adds	r5, r0, #0
	ldrb	r0, [r5, #1]
	cmp	r0, #1
	bne	.L0809CE44
	ldrb	r4, [r5, #9]
	lsls	r4, r4, #8
	ldr	r2, [r5, #4]
	ldr	r0, [r2, #8]
	ldrh	r1, [r0, #0x34]
	muls	r4, r1, r4
	lsrs	r4, r4, #7
	adds	r0, #0x40
	ldrb	r0, [r0]
	muls	r4, r0, r4
	lsrs	r4, r4, #7
	adds	r0, r2, #0
	adds	r0, #0x4d
	ldrb	r0, [r0]
	muls	r4, r0, r4
	lsrs	r4, r4, #0xf
	adds	r2, #0x4e
	ldrb	r0, [r2]
	muls	r4, r0, r4
	lsrs	r4, r4, #7
	adds	r0, r5, #0
	bl	envStep
	muls	r4, r0, r4
	lsrs	r4, r4, #0xf
	str	r4, [r5, #0x14]
	b	.L0809CE56
.L0809CE44:
	adds	r0, r5, #0
	adds	r0, #0x58
	ldrb	r0, [r0]
	adds	r0, #0xe6
	ldr	r1, [r5, #0x14]
	muls	r0, r1, r0
	lsrs	r0, r0, #9
	str	r0, [r5, #0x14]
	adds	r4, r0, #0
.L0809CE56:
	lsrs	r4, r4, #8
	adds	r0, r4, #0
	pop	{r4, r5}
	pop	{r1}
	bx	r1

@ ======================================================================================
@ psgEnvelope   (0809CE60)
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
@
@   In this build: Same, without the song-volume factor.
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
	ldrb	r4, [r5, #9]
	movs	r0, #0x48
	adds	r0, r0, r5
	mov	r8, r0
	ldrh	r0, [r0]
	cmp	r0, #0
	bne	.L0809CE7E
	movs	r6, #1
.L0809CE7E:
	adds	r0, r5, #0
	bl	envStep
	cmp	r6, #0
	bne	.L0809CE8C
	movs	r0, #8
	b	.L0809CF52
.L0809CE8C:
	cmp	r7, #0
	beq	.L0809CE92
	lsls	r4, r4, #1
.L0809CE92:
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
	lsrs	r4, r4, #8
	ldrh	r0, [r1, #0x34]
	muls	r4, r0, r4
	ldrb	r0, [r5]
	cmp	r0, #3
	bne	.L0809CED6
	lsrs	r4, r4, #0x16
	str	r4, [r5, #0x14]
	lsls	r0, r4, #2
	adds	r4, r0, r4
	lsrs	r4, r4, #7
	cmp	r4, #4
	bls	.L0809CED0
	movs	r4, #4
.L0809CED0:
	lsls	r0, r4, #0x18
	lsrs	r0, r0, #0x18
	b	.L0809CF52
.L0809CED6:
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
	beq	.L0809CEEE
	movs	r4, #0xf
.L0809CEEE:
	ldr	r1, [r5, #0x14]
	ldr	r0, [r5, #0x44]
	muls	r0, r1, r0
	lsrs	r0, r0, #0x19
	str	r0, [r5, #0x14]
	ands	r0, r2
	cmp	r0, #0
	beq	.L0809CF02
	movs	r0, #0xf
	str	r0, [r5, #0x14]
.L0809CF02:
	ldr	r5, [r5, #0x14]
	cmp	r5, r4
	beq	.L0809CF2A
	mov	r1, r8
	ldrh	r2, [r1]
	adds	r0, r2, #0
	adds	r0, #0xf
	lsls	r0, r0, #0x10
	lsrs	r2, r0, #0x10
	subs	r1, r5, r4
	cmp	r1, #0
	bge	.L0809CF1C
	rsbs	r1, r1, #0
.L0809CF1C:
	adds	r0, r2, #0
	bl	__divsi3
	lsls	r0, r0, #0x10
	lsrs	r2, r0, #0x10
	cmp	r2, #0
	bne	.L0809CF36
.L0809CF2A:
	lsls	r0, r4, #4
	movs	r1, #8
	orrs	r0, r1
	lsls	r0, r0, #0x18
	lsrs	r6, r0, #0x18
	b	.L0809CF50
.L0809CF36:
	ldr	r0, .P0809CF5C	@ =0x0000FFF8
	ands	r0, r2
	cmp	r0, #0
	beq	.L0809CF40
	movs	r2, #7
.L0809CF40:
	lsls	r0, r4, #4
	orrs	r0, r2
	lsls	r0, r0, #0x18
	lsrs	r6, r0, #0x18
	cmp	r4, r5
	bhs	.L0809CF50
	movs	r0, #8
	orrs	r6, r0
.L0809CF50:
	adds	r0, r6, #0
.L0809CF52:
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1
.P0809CF5C:	.word 0x0000FFF8

@ ======================================================================================
@ voicePitch   (0809CF60)
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
@
@   In this build: Pitch bend is a linear interpolation of the semitone range, applied as a multiplication:
@       b = (bend * (kDsPitch[range + 48] - 0x8000) + 0x400000) >> 14;   /* 256 = 1.0 */
@       sampled: f = b * f >> 8;             PSG: f = 0x800 - (0x800 - f) * 256 / b;
@   i.e. factor = 1 + bend/128 * (2^(range/12) - 1): bend +-128 reaches +-range semitones (up
@   exactly, down slightly less).  Portamento and vibrato are the same as in SMA4.
@ ======================================================================================
	.global voicePitch
	.thumb_func
voicePitch:
	push	{r4, r5, r6, lr}
	adds	r5, r0, #0
	ldr	r3, [r5, #0xc]
	ldr	r6, [r5, #4]
	adds	r2, r5, #0
	adds	r2, #0x2c
	ldr	r0, [r5, #0x2c]
	cmp	r0, #0
	beq	.L0809CF78
	subs	r0, #1
	str	r0, [r5, #0x2c]
	b	.L0809CF92
.L0809CF78:
	ldr	r4, [r2, #4]
	cmp	r4, #0
	beq	.L0809CF92
	ldr	r0, [r2, #8]
	ldr	r1, [r2, #0x10]
	adds	r0, r0, r1
	str	r0, [r2, #8]
	subs	r0, r4, #1
	str	r0, [r2, #4]
	cmp	r0, #0
	bne	.L0809CF92
	ldr	r0, [r2, #0xc]
	str	r0, [r2, #8]
.L0809CF92:
	ldr	r0, [r2, #8]
	adds	r3, r3, r0
	adds	r2, r6, #0
	adds	r2, #0x4f
	movs	r0, #0
	ldrsb	r0, [r2, r0]
	cmp	r0, #0
	beq	.L0809CFEA
	ldr	r1, .P0809CFD0	@ =kDsPitch
	adds	r0, r6, #0
	adds	r0, #0x50
	ldrb	r0, [r0]
	adds	r0, #0x30
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r1, [r0]
	ldr	r0, .P0809CFD4	@ =0xFFFF8000
	adds	r1, r1, r0
	movs	r0, #0
	ldrsb	r0, [r2, r0]
	muls	r1, r0, r1
	movs	r2, #0x80
	lsls	r2, r2, #0xf
	adds	r1, r1, r2
	asrs	r1, r1, #0xe
	ldrb	r0, [r5]
	cmp	r0, #0
	bne	.L0809CFD8
	muls	r3, r1, r3
	lsrs	r3, r3, #8
	b	.L0809CFEA
.P0809CFD0:	.word kDsPitch
.P0809CFD4:	.word 0xFFFF8000
.L0809CFD8:
	movs	r4, #0x80
	lsls	r4, r4, #4
	subs	r3, r4, r3
	lsls	r3, r3, #8
	adds	r0, r3, #0
	bl	__udivsi3
	adds	r3, r0, #0
	subs	r3, r4, r3
.L0809CFEA:
	adds	r4, r5, #0
	adds	r4, #0x20
	ldr	r0, [r4, #8]
	ldr	r2, [r0, #8]
	cmp	r2, #0
	beq	.L0809D098
	ldr	r0, [r4, #4]
	cmp	r0, #0
	bne	.L0809D094
	ldr	r0, .P0809D020	@ =kLfoSine
	ldr	r1, [r5, #0x20]
	lsrs	r1, r1, #1
	adds	r1, r1, r0
	ldrb	r1, [r1]
	ldrb	r0, [r5]
	cmp	r0, #0
	bne	.L0809D040
	lsls	r0, r1, #0x18
	asrs	r0, r0, #0x18
	cmp	r0, #0
	blt	.L0809D024
	muls	r0, r3, r0
	muls	r0, r2, r0
	lsrs	r0, r0, #0x13
	adds	r3, r3, r0
	b	.L0809D078
	.hword 0x0000
.P0809D020:	.word kLfoSine
.L0809D024:
	lsls	r3, r3, #0xc
	rsbs	r0, r0, #0
	adds	r1, r0, #0
	muls	r1, r2, r1
	lsrs	r1, r1, #3
	movs	r0, #0x80
	lsls	r0, r0, #9
	adds	r1, r1, r0
	adds	r0, r3, #0
	bl	__udivsi3
	adds	r3, r0, #0
	lsls	r3, r3, #4
	b	.L0809D078
.L0809D040:
	lsls	r0, r1, #0x18
	asrs	r1, r0, #0x18
	cmp	r1, #0
	blt	.L0809D05E
	movs	r0, #0x80
	lsls	r0, r0, #4
	subs	r0, r0, r3
	lsls	r0, r0, #0x13
	muls	r1, r2, r1
	movs	r2, #0x80
	lsls	r2, r2, #0xc
	adds	r1, r1, r2
	bl	__udivsi3
	b	.L0809D072
.L0809D05E:
	movs	r0, #0x80
	lsls	r0, r0, #4
	rsbs	r1, r1, #0
	subs	r0, r0, r3
	muls	r1, r2, r1
	movs	r2, #0x80
	lsls	r2, r2, #0xc
	adds	r1, r1, r2
	muls	r0, r1, r0
	lsrs	r0, r0, #0x13
.L0809D072:
	movs	r3, #0x80
	lsls	r3, r3, #4
	subs	r3, r3, r0
.L0809D078:
	ldr	r0, [r4, #8]
	ldr	r1, [r4]
	ldr	r0, [r0, #4]
	adds	r1, r1, r0
	str	r1, [r4]
	lsrs	r0, r1, #1
	cmp	r0, #0xff
	bls	.L0809D098
	ldr	r2, .P0809D090	@ =0xFFFFFE00
	adds	r0, r1, r2
	str	r0, [r4]
	b	.L0809D098
.P0809D090:	.word 0xFFFFFE00
.L0809D094:
	subs	r0, #1
	str	r0, [r4, #4]
.L0809D098:
	adds	r0, r3, #0
	pop	{r4, r5, r6}
	pop	{r1}
	bx	r1

@ ======================================================================================
@ mixFrame   (0809D0A0)
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
@
@   In this build: Differences:
@     * The echo is always on: the wet bus is loaded from the history every frame, armEcho always
@       runs and the history is always written (gEchoShift only moves towards its target).
@     * A voice that finishes or is silent is freed after the list pointer has moved on
@       (v = v->next; voiceStop(v->prev)), because voiceStop relinks it into the free list.
@     * step = __udivsi3(rate * (f >> 2), 10512), then multiplied by 176 and divided by 176 again
@       (a no-op left over from a variable frame length).
@     * No pause test.
@ ======================================================================================
	.global mixFrame
	.thumb_func
mixFrame:
	push	{r4, r5, r6, r7, lr}
	sub	sp, #4
	ldr	r4, .P0809D0F8	@ =gLastWave
	ldr	r5, [r4, #0x70]
	ldr	r2, .P0809D0FC	@ =gEchoHistory
	ldr	r0, .P0809D100	@ =gEchoPos
	ldrb	r0, [r0]
	lsls	r1, r0, #1
	adds	r1, r1, r0
	lsls	r1, r1, #2
	subs	r1, r1, r0
	lsls	r1, r1, #6
	ldr	r0, [r2]
	adds	r0, r0, r1
	ldr	r1, .P0809D104	@ =gMixWet
	movs	r2, #0xb0
	bl	CpuFastSet
	movs	r0, #0
	str	r0, [sp]
	ldr	r1, .P0809D108	@ =gMixDry
	ldr	r2, .P0809D10C	@ =0x010000B0
	mov	r0, sp
	bl	CpuFastSet
	adds	r4, #0x7c
	cmp	r5, r4
	beq	.L0809D180
.L0809D0D8:
	adds	r0, r5, #0
	bl	dsVolume
	adds	r7, r0, #0
	ldrb	r0, [r5, #1]
	cmp	r0, #1
	bne	.L0809D12C
	ldrh	r0, [r5, #0x18]
	subs	r0, #1
	strh	r0, [r5, #0x18]
	ldr	r4, [r5, #4]
	ldrb	r0, [r5, #0x1b]
	cmp	r0, #0
	beq	.L0809D110
	ldrb	r3, [r5, #0x1c]
	b	.L0809D116
.P0809D0F8:	.word gLastWave
.P0809D0FC:	.word gEchoHistory
.P0809D100:	.word gEchoPos
.P0809D104:	.word gMixWet
.P0809D108:	.word gMixDry
.P0809D10C:	.word 0x010000B0
.L0809D110:
	adds	r0, r4, #0
	adds	r0, #0x4b
	ldrb	r3, [r0]
.L0809D116:
	adds	r6, r3, #0
	adds	r0, r5, #0
	bl	voicePitch
	adds	r2, r0, #0
	str	r2, [r5, #0x10]
	adds	r0, r4, #0
	adds	r0, #0x4c
	ldrb	r0, [r0]
	strb	r0, [r5, #0x1a]
	b	.L0809D134
.L0809D12C:
	cmp	r7, #0
	beq	.L0809D168
	ldrb	r6, [r5, #0x1c]
	ldr	r2, [r5, #0x10]
.L0809D134:
	lsrs	r2, r2, #2
	ldr	r0, [r5, #0x5c]
	ldr	r0, [r0, #4]
	muls	r2, r0, r2
	adds	r0, r2, #0
	ldr	r1, .P0809D174	@ =0x00002910
	bl	__udivsi3
	adds	r2, r0, #0
	movs	r0, #0xb0
	muls	r2, r0, r2
	adds	r0, r2, #0
	movs	r1, #0xb0
	bl	__udivsi3
	adds	r2, r0, #0
	lsrs	r2, r2, #5
	adds	r0, r5, #0
	adds	r1, r7, #0
	adds	r3, r6, #0
	bl	mixVoice
	lsls	r0, r0, #0x18
	lsrs	r0, r0, #0x18
	cmp	r0, #1
	bne	.L0809D178
.L0809D168:
	ldr	r5, [r5, #0x6c]
	ldr	r0, [r5, #0x68]
	bl	voiceStop
	b	.L0809D17A
	.hword 0x0000
.P0809D174:	.word 0x00002910
.L0809D178:
	ldr	r5, [r5, #0x6c]
.L0809D17A:
	ldr	r0, .P0809D1B8	@ =gActiveTail
	cmp	r5, r0
	bne	.L0809D0D8
.L0809D180:
	movs	r5, #0
	movs	r4, #6
.L0809D184:
	ldr	r0, .P0809D1BC	@ =gDsVoices
	adds	r1, r5, r0
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	bne	.L0809D19A
	ldrh	r0, [r1, #0x18]
	cmp	r0, #0
	bne	.L0809D19A
	adds	r0, r1, #0
	bl	noteOff
.L0809D19A:
	adds	r5, #0x78
	subs	r4, #1
	cmp	r4, #0
	bge	.L0809D184
	ldr	r5, .P0809D1C0	@ =gEchoShiftTarget
	ldr	r0, .P0809D1C4	@ =gEchoShift
	ldrb	r1, [r5]
	ldrb	r2, [r0]
	adds	r3, r2, #0
	adds	r4, r0, #0
	cmp	r1, r3
	bhs	.L0809D1C8
	subs	r0, r2, #1
	b	.L0809D1D0
	.hword 0x0000
.P0809D1B8:	.word gActiveTail
.P0809D1BC:	.word gDsVoices
.P0809D1C0:	.word gEchoShiftTarget
.P0809D1C4:	.word gEchoShift
.L0809D1C8:
	ldrb	r0, [r5]
	cmp	r0, r3
	bls	.L0809D1D2
	adds	r0, r2, #1
.L0809D1D0:
	strb	r0, [r4]
.L0809D1D2:
	ldr	r0, .P0809D240	@ =gFnEcho
	ldr	r6, .P0809D244	@ =gMixDry
	ldr	r5, .P0809D248	@ =gMixWet
	movs	r1, #0xb0
	lsls	r1, r1, #2
	adds	r7, r6, r1
	ldrb	r3, [r4]
	ldr	r4, [r0]
	adds	r0, r6, #0
	adds	r1, r5, #0
	adds	r2, r7, #0
	bl	_call_via_r4
	ldr	r2, .P0809D24C	@ =gEchoHistory
	ldr	r4, .P0809D250	@ =gEchoPos
	ldrb	r1, [r4]
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
	ldrb	r0, [r4]
	adds	r0, #1
	strb	r0, [r4]
	ldr	r1, .P0809D254	@ =gEchoLen
	lsls	r0, r0, #0x18
	lsrs	r0, r0, #0x18
	ldrb	r1, [r1]
	cmp	r0, r1
	blo	.L0809D21E
	movs	r0, #0
	strb	r0, [r4]
.L0809D21E:
	ldr	r2, .P0809D258	@ =gFnDownmix
	ldr	r1, .P0809D25C	@ =gDmaBufA
	ldr	r0, .P0809D260	@ =gDmaBufIdx
	ldrb	r0, [r0]
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r1, [r0]
	ldr	r3, [r2]
	adds	r0, r6, #0
	adds	r2, r7, #0
	bl	_call_via_r3
	add	sp, #4
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0809D240:	.word gFnEcho
.P0809D244:	.word gMixDry
.P0809D248:	.word gMixWet
.P0809D24C:	.word gEchoHistory
.P0809D250:	.word gEchoPos
.P0809D254:	.word gEchoLen
.P0809D258:	.word gFnDownmix
.P0809D25C:	.word gDmaBufA
.P0809D260:	.word gDmaBufIdx

@ ======================================================================================
@ psgUpdate   (0809D264)
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
@
@   In this build: Same, but without the pause test (the PSG notes of a paused player are released by trackTick).
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
.L0809D272:
	mov	r1, sl
	lsls	r0, r1, #4
	subs	r0, r0, r1
	lsls	r0, r0, #3
	ldr	r1, .P0809D2B0	@ =gPsgVoices
	adds	r4, r0, r1
	ldrb	r0, [r4, #1]
	cmp	r0, #1
	bne	.L0809D290
	ldrh	r0, [r4, #0x18]
	cmp	r0, #0
	bne	.L0809D290
	adds	r0, r4, #0
	bl	noteOff
.L0809D290:
	ldrb	r0, [r4, #1]
	cmp	r0, #0
	bne	.L0809D298
	b	.L0809D4D8
.L0809D298:
	cmp	r0, #1
	bne	.L0809D2BE
	adds	r0, r4, #0
	bl	voicePitch
	adds	r6, r0, #0
	str	r6, [r4, #0x10]
	ldrb	r0, [r4, #0x1b]
	cmp	r0, #0
	beq	.L0809D2B4
	ldrb	r0, [r4, #0x1c]
	b	.L0809D2BA
.P0809D2B0:	.word gPsgVoices
.L0809D2B4:
	ldr	r0, [r4, #4]
	adds	r0, #0x4b
	ldrb	r0, [r0]
.L0809D2BA:
	mov	r8, r0
	b	.L0809D2C4
.L0809D2BE:
	ldr	r6, [r4, #0x10]
	ldrb	r2, [r4, #0x1c]
	mov	r8, r2
.L0809D2C4:
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
	ldr	r0, .P0809D308	@ =REG_NR51
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
	bne	.L0809D30C
	mov	r3, ip
	ldrb	r1, [r3]
	adds	r0, r2, #0
	ands	r0, r1
	orrs	r0, r5
	strb	r0, [r3]
	b	.L0809D336
.P0809D308:	.word REG_NR51
.L0809D30C:
	mov	r0, r8
	cmp	r0, #0x3f
	bhi	.L0809D326
	mov	r1, ip
	ldrb	r0, [r1]
	adds	r1, r2, #0
	ands	r1, r0
	movs	r0, #0x10
	lsls	r0, r3
	orrs	r1, r0
	mov	r2, ip
	strb	r1, [r2]
	b	.L0809D336
.L0809D326:
	mov	r3, ip
	ldrb	r0, [r3]
	ands	r1, r0
	movs	r0, #1
	mov	r2, sb
	lsls	r0, r2
	orrs	r1, r0
	strb	r1, [r3]
.L0809D336:
	ldrb	r5, [r4, #1]
	cmp	r5, #1
	bne	.L0809D360
	ldr	r0, [r4, #0x60]
	cmp	r0, #0
	bne	.L0809D354
	adds	r0, r4, #0
	adds	r1, r7, #0
	bl	psgKeyOn
	str	r5, [r4, #0x60]
	ldrh	r0, [r4, #0x18]
	subs	r0, #1
	strh	r0, [r4, #0x18]
	b	.L0809D4D8
.L0809D354:
	adds	r0, #1
	str	r0, [r4, #0x60]
	ldrh	r0, [r4, #0x18]
	subs	r0, #1
	strh	r0, [r4, #0x18]
	b	.L0809D3B0
.L0809D360:
	ldrb	r0, [r4]
	cmp	r0, #3
	bne	.L0809D3B0
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
	beq	.L0809D380
	lsls	r1, r1, #1
.L0809D380:
	lsls	r0, r1, #2
	adds	r1, r0, r1
	lsrs	r1, r1, #7
	cmp	r1, #0
	beq	.L0809D3A8
	cmp	r1, #4
	bls	.L0809D390
	movs	r1, #4
.L0809D390:
	lsls	r1, r1, #0x18
	lsrs	r1, r1, #0x18
	ldr	r2, .P0809D3A0	@ =REG_NR32
	ldr	r0, .P0809D3A4	@ =kWaveVolume
	adds	r1, r1, r0
	ldrb	r0, [r1]
	strb	r0, [r2]
	b	.L0809D4D8
.P0809D3A0:	.word REG_NR32
.P0809D3A4:	.word kWaveVolume
.L0809D3A8:
	adds	r0, r4, #0
	bl	voiceStop
	b	.L0809D4D8
.L0809D3B0:
	ldr	r2, [r4, #0x54]
	ldrb	r1, [r2, #1]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0809D3D2
	ldr	r0, [r4, #0x64]
	ldrh	r3, [r0]
	ldr	r1, [r4, #0x60]
	cmp	r1, r3
	bhs	.L0809D3CC
	adds	r0, r0, r1
	ldrb	r5, [r0, #2]
	b	.L0809D3D4
.L0809D3CC:
	adds	r0, r3, r0
	ldrb	r5, [r0, #1]
	b	.L0809D3D4
.L0809D3D2:
	movs	r5, #0xff
.L0809D3D4:
	ldrb	r0, [r4]
	cmp	r0, #2
	beq	.L0809D424
	cmp	r0, #2
	bgt	.L0809D3E4
	cmp	r0, #1
	beq	.L0809D3EE
	b	.L0809D4D8
.L0809D3E4:
	cmp	r0, #3
	beq	.L0809D464
	cmp	r0, #4
	beq	.L0809D48C
	b	.L0809D4D8
.L0809D3EE:
	cmp	r7, #8
	beq	.L0809D40C
	ldr	r0, .P0809D404	@ =REG_NR12
	strb	r7, [r0]
	ldr	r1, .P0809D408	@ =REG_SOUND1CNT_X
	movs	r2, #0x80
	lsls	r2, r2, #8
	adds	r0, r2, #0
	orrs	r6, r0
	strh	r6, [r1]
	b	.L0809D416
.P0809D404:	.word REG_NR12
.P0809D408:	.word REG_SOUND1CNT_X
.L0809D40C:
	ldrb	r0, [r2, #8]
	cmp	r0, #8
	bne	.L0809D416
	ldr	r0, .P0809D41C	@ =REG_SOUND1CNT_X
	strh	r6, [r0]
.L0809D416:
	ldr	r2, .P0809D420	@ =REG_NR11
	b	.L0809D44A
	.hword 0x0000
.P0809D41C:	.word REG_SOUND1CNT_X
.P0809D420:	.word REG_NR11
.L0809D424:
	cmp	r7, #8
	beq	.L0809D444
	ldr	r0, .P0809D43C	@ =REG_NR22
	strb	r7, [r0]
	ldr	r1, .P0809D440	@ =REG_SOUND2CNT_H
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r0, r3, #0
	orrs	r6, r0
	strh	r6, [r1]
	b	.L0809D448
	.hword 0x0000
.P0809D43C:	.word REG_NR22
.P0809D440:	.word REG_SOUND2CNT_H
.L0809D444:
	ldr	r0, .P0809D45C	@ =REG_SOUND2CNT_H
	strh	r6, [r0]
.L0809D448:
	ldr	r2, .P0809D460	@ =REG_NR21
.L0809D44A:
	ldrb	r1, [r2]
	movs	r0, #0xc0
	ands	r0, r1
	strb	r0, [r2]
	cmp	r5, #0xff
	beq	.L0809D4D8
	lsls	r0, r5, #6
	strb	r0, [r2]
	b	.L0809D4D8
.P0809D45C:	.word REG_SOUND2CNT_H
.P0809D460:	.word REG_NR21
.L0809D464:
	ldr	r0, .P0809D484	@ =REG_SOUND3CNT_X
	ldrh	r1, [r0]
	movs	r3, #0x80
	lsls	r3, r3, #7
	adds	r2, r3, #0
	ands	r1, r2
	orrs	r1, r6
	strh	r1, [r0]
	cmp	r7, #8
	beq	.L0809D4D8
	subs	r0, #1
	ldr	r1, .P0809D488	@ =kWaveVolume
	adds	r1, r7, r1
	ldrb	r1, [r1]
	strb	r1, [r0]
	b	.L0809D4D8
.P0809D484:	.word REG_SOUND3CNT_X
.P0809D488:	.word kWaveVolume
.L0809D48C:
	cmp	r7, #8
	beq	.L0809D49A
	ldr	r0, .P0809D4B8	@ =REG_NR42
	strb	r7, [r0]
	ldr	r1, .P0809D4BC	@ =REG_NR44
	movs	r0, #0x80
	strb	r0, [r1]
.L0809D49A:
	cmp	r5, #0xff
	beq	.L0809D4C4
	ldr	r4, .P0809D4C0	@ =REG_NR43
	lsls	r0, r6, #0x10
	lsrs	r0, r0, #0x10
	bl	noiseDivider
	lsls	r0, r0, #0x18
	lsrs	r1, r0, #0x18
	cmp	r5, #0
	beq	.L0809D4B4
	movs	r0, #8
	orrs	r1, r0
.L0809D4B4:
	strb	r1, [r4]
	b	.L0809D4D8
.P0809D4B8:	.word REG_NR42
.P0809D4BC:	.word REG_NR44
.P0809D4C0:	.word REG_NR43
.L0809D4C4:
	lsls	r0, r6, #0x10
	lsrs	r0, r0, #0x10
	bl	noiseDivider
	ldr	r3, .P0809D4F4	@ =REG_NR43
	ldrb	r2, [r3]
	movs	r1, #8
	ands	r1, r2
	orrs	r1, r0
	strb	r1, [r3]
.L0809D4D8:
	movs	r0, #1
	add	sl, r0
	mov	r1, sl
	cmp	r1, #3
	bgt	.L0809D4E4
	b	.L0809D272
.L0809D4E4:
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	sb, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0809D4F4:	.word REG_NR43

@ ======================================================================================
@ noteOn   (0809D4F8)
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
@
@   In this build: Differences:
@     * The length in frames is computed from (u16)len, so notes longer than 436 ticks
@       (len * 150 > 65535) wrap around.
@     * voiceAlloc takes the track as an extra, unused argument.
@     * The voice's key is not stored (the Voice has no key field in this build).
@ ======================================================================================
	.global noteOn
	.thumb_func
noteOn:
	push	{r4, r5, r6, r7, lr}
	mov	r7, sb
	mov	r6, r8
	push	{r6, r7}
	sub	sp, #0x14
	adds	r5, r0, #0
	lsls	r1, r1, #0x18
	lsrs	r7, r1, #0x18
	lsls	r2, r2, #0x18
	lsrs	r2, r2, #0x18
	mov	sb, r2
	lsls	r3, r3, #0x10
	lsrs	r3, r3, #0x10
	mov	r8, r3
	ldr	r4, [r5, #8]
	adds	r0, #0x4a
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L0809D520
	b	.L0809D6BC
.L0809D520:
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
	beq	.L0809D54C
	ldrh	r1, [r4, #0x30]
	mov	r0, r8
	bl	__udivsi3
	b	.L0809D55A
.L0809D54C:
	movs	r0, #0x32
	ldrsh	r1, [r4, r0]
	ldrh	r4, [r4, #0x30]
	adds	r1, r1, r4
	mov	r0, r8
	bl	__divsi3
.L0809D55A:
	lsls	r0, r0, #0x10
	lsrs	r0, r0, #0x10
	mov	r8, r0
	adds	r0, r5, #0
	adds	r0, #0x49
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L0809D574
	ldr	r0, [r5, #0xc]
	cmp	r0, #0
	beq	.L0809D574
	adds	r4, r0, #0
	b	.L0809D5C8
.L0809D574:
	ldr	r1, .P0809D5E0	@ =kVoiceForType
	ldrb	r0, [r6]
	adds	r0, r0, r1
	ldrb	r0, [r0]
	adds	r1, r5, #0
	adds	r1, #0x52
	ldrb	r2, [r1]
	adds	r1, r5, #0
	bl	voiceAlloc
	adds	r4, r0, #0
	cmp	r4, #0
	bne	.L0809D590
	b	.L0809D6BC
.L0809D590:
	adds	r0, r5, #0
	adds	r1, r4, #0
	bl	trackAddVoice
	movs	r1, #0
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
.L0809D5C8:
	mov	r0, sp
	ldrb	r0, [r0, #0x11]
	strb	r0, [r4, #0x1b]
	lsls	r0, r0, #0x18
	cmp	r0, #0
	beq	.L0809D5E4
	movs	r7, #0x30
	mov	r0, sp
	ldrb	r0, [r0, #0x10]
	strb	r0, [r4, #0x1c]
	b	.L0809D5EE
	.hword 0x0000
.P0809D5E0:	.word kVoiceForType
.L0809D5E4:
	mov	r0, sp
	ldrb	r0, [r0, #0x12]
	cmp	r0, #0
	beq	.L0809D5EE
	movs	r7, #0x30
.L0809D5EE:
	movs	r0, #0
	mov	r1, sb
	strb	r1, [r4, #9]
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
	bne	.L0809D620
	adds	r0, r4, #0
	adds	r0, #0x2c
	movs	r1, #0x14
	bl	MemClear
	b	.L0809D67A
.L0809D620:
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
	beq	.L0809D64E
	ldr	r0, [r4, #0xc]
	subs	r0, r2, r0
	str	r0, [r4, #0x38]
	b	.L0809D656
.L0809D64E:
	ldr	r0, [r4, #0xc]
	subs	r0, r0, r2
	str	r0, [r4, #0x38]
	str	r2, [r4, #0xc]
.L0809D656:
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
	beq	.L0809D674
	strb	r7, [r5, #0x1e]
	b	.L0809D676
.L0809D674:
	strb	r0, [r5, #0x1c]
.L0809D676:
	movs	r0, #0
	str	r0, [r4, #0x34]
.L0809D67A:
	ldrb	r0, [r4]
	cmp	r0, #0
	bne	.L0809D690
	ldrh	r0, [r6, #2]
	ldr	r1, [r5, #4]
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r0, [r0]
	adds	r1, r1, r0
	str	r1, [r4, #0x5c]
	b	.L0809D6B0
.L0809D690:
	cmp	r0, #3
	beq	.L0809D6AC
	ldrb	r1, [r6, #1]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0809D6A2
	ldr	r0, [sp, #8]
	b	.L0809D6AE
.L0809D6A2:
	ldrh	r1, [r6, #2]
	adds	r0, r4, #0
	adds	r0, #0x64
	strb	r1, [r0]
	b	.L0809D6B0
.L0809D6AC:
	ldr	r0, [sp, #0xc]
.L0809D6AE:
	str	r0, [r4, #0x64]
.L0809D6B0:
	mov	r0, r8
	cmp	r0, #0
	bne	.L0809D6BC
	adds	r0, r4, #0
	bl	noteOff
.L0809D6BC:
	add	sp, #0x14
	pop	{r3, r4}
	mov	r8, r3
	mov	sb, r4
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ noteOff   (0809D6CC)
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
@
@   In this build: Same, with voiceUnlink instead of voiceListRemove.
@ ======================================================================================
	.global noteOff
	.thumb_func
noteOff:
	push	{r4, lr}
	adds	r4, r0, #0
	ldrb	r0, [r4, #1]
	cmp	r0, #1
	bne	.L0809D7A2
	ldr	r0, [r4, #4]
	adds	r0, #0x49
	ldrb	r0, [r0]
	cmp	r0, #0
	bne	.L0809D7A2
	ldrb	r3, [r4]
	cmp	r3, #0
	bne	.L0809D6F8
	adds	r0, r4, #0
	bl	voiceUnlink
	movs	r0, #2
	strb	r0, [r4, #1]
	adds	r0, r4, #0
	bl	voiceListInsertActive
	b	.L0809D78A
.L0809D6F8:
	ldrh	r2, [r4, #0x10]
	adds	r0, r4, #0
	adds	r0, #0x58
	ldrb	r1, [r0]
	cmp	r3, #3
	bne	.L0809D708
	movs	r0, #2
	b	.L0809D788
.L0809D708:
	lsrs	r1, r1, #5
	cmp	r1, #0
	bne	.L0809D712
	movs	r1, #0
	b	.L0809D71C
.L0809D712:
	ldr	r0, [r4, #0x14]
	lsls	r0, r0, #4
	orrs	r1, r0
	lsls	r0, r1, #0x18
	lsrs	r1, r0, #0x18
.L0809D71C:
	ldrb	r0, [r4]
	cmp	r0, #2
	beq	.L0809D754
	cmp	r0, #2
	bgt	.L0809D72C
	cmp	r0, #1
	beq	.L0809D732
	b	.L0809D786
.L0809D72C:
	cmp	r0, #4
	beq	.L0809D77C
	b	.L0809D786
.L0809D732:
	ldr	r0, .P0809D748	@ =REG_NR12
	strb	r1, [r0]
	ldr	r1, .P0809D74C	@ =REG_SOUND1CNT_X
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r0, r3, #0
	orrs	r2, r0
	strh	r2, [r1]
	ldr	r2, .P0809D750	@ =REG_NR11
	b	.L0809D766
	.hword 0x0000
.P0809D748:	.word REG_NR12
.P0809D74C:	.word REG_SOUND1CNT_X
.P0809D750:	.word REG_NR11
.L0809D754:
	ldr	r0, .P0809D770	@ =REG_NR22
	strb	r1, [r0]
	ldr	r1, .P0809D774	@ =REG_SOUND2CNT_H
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r0, r3, #0
	orrs	r2, r0
	strh	r2, [r1]
	ldr	r2, .P0809D778	@ =REG_NR21
.L0809D766:
	ldrb	r1, [r2]
	movs	r0, #0xc0
	ands	r0, r1
	strb	r0, [r2]
	b	.L0809D786
.P0809D770:	.word REG_NR22
.P0809D774:	.word REG_SOUND2CNT_H
.P0809D778:	.word REG_NR21
.L0809D77C:
	ldr	r0, .P0809D7A8	@ =REG_NR42
	strb	r1, [r0]
	ldr	r1, .P0809D7AC	@ =REG_NR44
	movs	r0, #0x80
	strb	r0, [r1]
.L0809D786:
	movs	r0, #0
.L0809D788:
	strb	r0, [r4, #1]
.L0809D78A:
	ldrb	r0, [r4, #0x1b]
	ldr	r1, [r4, #4]
	cmp	r0, #0
	bne	.L0809D79A
	adds	r0, r1, #0
	adds	r0, #0x4b
	ldrb	r0, [r0]
	strb	r0, [r4, #0x1c]
.L0809D79A:
	adds	r0, r1, #0
	adds	r1, r4, #0
	bl	trackRemoveVoice
.L0809D7A2:
	pop	{r4}
	pop	{r0}
	bx	r0
.P0809D7A8:	.word REG_NR42
.P0809D7AC:	.word REG_NR44

@ ======================================================================================
@ voiceStop   (0809D7B0)
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
@
@   In this build: Same; a sampled voice is unlinked and pushed at the head of the free list (after gFreeHead).
@ ======================================================================================
	.global voiceStop
	.thumb_func
voiceStop:
	push	{r4, lr}
	adds	r4, r0, #0
	ldrb	r0, [r4, #1]
	cmp	r0, #0
	beq	.L0809D840
	ldrb	r0, [r4]
	cmp	r0, #4
	bhi	.L0809D834
	lsls	r0, r0, #2
	ldr	r1, .P0809D7CC	@ =0x0809D7D0
	adds	r0, r0, r1
	ldr	r0, [r0]
	mov	pc, r0
	.hword 0x0000
.P0809D7CC:	.word 0x0809D7D0
	.word .L0809D7E4
	.word .L0809D804
	.word .L0809D814
	.word .L0809D81C
	.word .L0809D828
.L0809D7E4:
	adds	r0, r4, #0
	bl	voiceUnlink
	ldr	r0, .P0809D800	@ =gLastWave
	movs	r1, #0xb0
	lsls	r1, r1, #1
	adds	r2, r0, r1
	ldr	r1, [r2]
	str	r1, [r4, #0x6c]
	adds	r0, #0xf4
	str	r0, [r4, #0x68]
	str	r4, [r1, #0x68]
	str	r4, [r2]
	b	.L0809D834
.P0809D800:	.word gLastWave
.L0809D804:
	ldr	r1, .P0809D810	@ =REG_NR12
	movs	r0, #8
	strb	r0, [r1]
	adds	r1, #2
	b	.L0809D830
	.hword 0x0000
.P0809D810:	.word REG_NR12
.L0809D814:
	ldr	r1, .P0809D818	@ =REG_NR22
	b	.L0809D82A
.P0809D818:	.word REG_NR22
.L0809D81C:
	ldr	r1, .P0809D824	@ =REG_NR30
	movs	r0, #0
	b	.L0809D832
	.hword 0x0000
.P0809D824:	.word REG_NR30
.L0809D828:
	ldr	r1, .P0809D848	@ =REG_NR42
.L0809D82A:
	movs	r0, #8
	strb	r0, [r1]
	adds	r1, #4
.L0809D830:
	movs	r0, #0xc0
.L0809D832:
	strb	r0, [r1]
.L0809D834:
	ldr	r0, [r4, #4]
	adds	r1, r4, #0
	bl	trackRemoveVoice
	movs	r0, #0
	strb	r0, [r4, #1]
.L0809D840:
	pop	{r4}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0809D848:	.word REG_NR42

@ ======================================================================================
@ psgKeyOn   (0809D84C)
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
	beq	.L0809D8D0
	cmp	r3, #2
	bgt	.L0809D864
	cmp	r3, #1
	beq	.L0809D86E
	b	.L0809D99C
.L0809D864:
	cmp	r3, #3
	beq	.L0809D8FC
	cmp	r3, #4
	beq	.L0809D950
	b	.L0809D99C
.L0809D86E:
	ldr	r1, .P0809D89C	@ =REG_NR10
	ldr	r0, [r4, #0x54]
	ldrb	r0, [r0, #8]
	strb	r0, [r1]
	ldr	r2, .P0809D8A0	@ =REG_SOUND1CNT_X
	ldr	r0, [r4, #0xc]
	movs	r6, #0x80
	lsls	r6, r6, #8
	adds	r1, r6, #0
	orrs	r0, r1
	strh	r0, [r2]
	ldr	r0, .P0809D8A4	@ =REG_NR12
	strb	r5, [r0]
	ldr	r0, [r4, #0x54]
	ldrb	r0, [r0, #1]
	ands	r3, r0
	cmp	r3, #0
	beq	.L0809D8AC
	ldr	r1, .P0809D8A8	@ =REG_NR11
	ldr	r0, [r4, #0x64]
	ldrb	r0, [r0, #2]
	b	.L0809D8B4
	.hword 0x0000
.P0809D89C:	.word REG_NR10
.P0809D8A0:	.word REG_SOUND1CNT_X
.P0809D8A4:	.word REG_NR12
.P0809D8A8:	.word REG_NR11
.L0809D8AC:
	ldr	r1, .P0809D8C8	@ =REG_NR11
	adds	r0, r4, #0
	adds	r0, #0x64
	ldrb	r0, [r0]
.L0809D8B4:
	lsls	r0, r0, #6
	strb	r0, [r1]
	ldr	r0, .P0809D8CC	@ =REG_SOUND1CNT_X
	ldr	r1, [r4, #0xc]
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r2, r3, #0
	orrs	r1, r2
	strh	r1, [r0]
	b	.L0809D99C
.P0809D8C8:	.word REG_NR11
.P0809D8CC:	.word REG_SOUND1CNT_X
.L0809D8D0:
	ldr	r0, .P0809D8F0	@ =REG_NR22
	strb	r5, [r0]
	ldr	r2, .P0809D8F4	@ =REG_SOUND2CNT_H
	ldr	r0, [r4, #0xc]
	movs	r6, #0x80
	lsls	r6, r6, #8
	adds	r1, r6, #0
	orrs	r0, r1
	strh	r0, [r2]
	ldr	r1, .P0809D8F8	@ =REG_NR21
	adds	r0, r4, #0
	adds	r0, #0x64
	ldrb	r0, [r0]
	lsls	r0, r0, #6
	b	.L0809D99A
	.hword 0x0000
.P0809D8F0:	.word REG_NR22
.P0809D8F4:	.word REG_SOUND2CNT_H
.P0809D8F8:	.word REG_NR21
.L0809D8FC:
	ldr	r6, .P0809D93C	@ =gLastWave
	ldr	r1, [r4, #0x64]
	ldr	r0, [r6]
	cmp	r1, r0
	beq	.L0809D91A
	ldr	r1, .P0809D940	@ =REG_NR30
	movs	r0, #0
	strb	r0, [r1]
	ldr	r0, [r4, #0x64]
	adds	r1, #0x20
	movs	r2, #8
	bl	CpuSet
	ldr	r0, [r4, #0x64]
	str	r0, [r6]
.L0809D91A:
	ldr	r1, .P0809D940	@ =REG_NR30
	movs	r0, #0xc0
	strb	r0, [r1]
	ldr	r2, .P0809D944	@ =REG_SOUND3CNT_X
	ldr	r0, [r4, #0xc]
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r1, r3, #0
	orrs	r0, r1
	strh	r0, [r2]
	ldr	r1, .P0809D948	@ =REG_NR32
	ldr	r0, .P0809D94C	@ =kWaveVolume
	adds	r0, r5, r0
	ldrb	r0, [r0]
	strb	r0, [r1]
	subs	r1, #1
	b	.L0809D998
.P0809D93C:	.word gLastWave
.P0809D940:	.word REG_NR30
.P0809D944:	.word REG_SOUND3CNT_X
.P0809D948:	.word REG_NR32
.P0809D94C:	.word kWaveVolume
.L0809D950:
	ldr	r0, .P0809D970	@ =REG_NR42
	strb	r5, [r0]
	ldr	r0, [r4, #0x54]
	ldrb	r1, [r0, #1]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0809D974
	ldrh	r0, [r4, #0xc]
	bl	noiseDivider
	lsls	r0, r0, #0x18
	lsrs	r1, r0, #0x18
	ldr	r0, [r4, #0x64]
	ldrb	r0, [r0, #2]
	b	.L0809D984
.P0809D970:	.word REG_NR42
.L0809D974:
	ldrh	r0, [r4, #0xc]
	bl	noiseDivider
	lsls	r0, r0, #0x18
	lsrs	r1, r0, #0x18
	adds	r0, r4, #0
	adds	r0, #0x64
	ldrb	r0, [r0]
.L0809D984:
	cmp	r0, #0
	beq	.L0809D98C
	movs	r0, #8
	orrs	r1, r0
.L0809D98C:
	ldr	r0, .P0809D9A4	@ =REG_NR43
	strb	r1, [r0]
	ldr	r1, .P0809D9A8	@ =REG_NR44
	movs	r0, #0x80
	strb	r0, [r1]
	subs	r1, #5
.L0809D998:
	movs	r0, #0
.L0809D99A:
	strb	r0, [r1]
.L0809D99C:
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0809D9A4:	.word REG_NR43
.P0809D9A8:	.word REG_NR44

@ ======================================================================================
@ voiceAlloc   (0809D9AC)
@
@   Voice *voiceAlloc(u32 type, Track *t, u32 prio)   /* t is not used */
@   Same as SMA4 with the sentinel lists: the free list is empty when gFreeHead.next == &gFreeTail,
@   the active list when gActiveHead.next == &gActiveTail.
@ ======================================================================================
	.global voiceAlloc
	.thumb_func
voiceAlloc:
	push	{r4, r5, lr}
	lsls	r0, r0, #0x18
	lsrs	r1, r0, #0x18
	lsls	r2, r2, #0x18
	lsrs	r5, r2, #0x18
	cmp	r1, #0
	bne	.L0809DA0A
	ldr	r1, .P0809D9D4	@ =gLastWave
	movs	r2, #0xb0
	lsls	r2, r2, #1
	adds	r0, r1, r2
	ldr	r2, [r0]
	movs	r3, #0xb6
	lsls	r3, r3, #1
	adds	r0, r1, r3
	cmp	r2, r0
	beq	.L0809D9D8
	adds	r4, r2, #0
	b	.L0809D9F6
	.hword 0x0000
.P0809D9D4:	.word gLastWave
.L0809D9D8:
	ldr	r2, [r1, #0x70]
	adds	r0, r1, #0
	adds	r0, #0x7c
	cmp	r2, r0
	beq	.L0809DA20
	ldrb	r0, [r2, #1]
	cmp	r0, #1
	bne	.L0809D9EE
	ldrb	r0, [r2, #8]
	cmp	r5, r0
	blo	.L0809DA20
.L0809D9EE:
	adds	r4, r2, #0
	adds	r0, r4, #0
	bl	voiceStop
.L0809D9F6:
	adds	r0, r4, #0
	bl	voiceUnlink
	movs	r0, #1
	strb	r0, [r4, #1]
	strb	r5, [r4, #8]
	adds	r0, r4, #0
	bl	voiceListInsertActive
	b	.L0809DA3A
.L0809DA0A:
	lsls	r0, r1, #4
	subs	r0, r0, r1
	lsls	r0, r0, #3
	ldr	r1, .P0809DA24	@ =gDsVoices+0x2D0
	adds	r4, r0, r1
	ldrb	r0, [r4, #1]
	cmp	r0, #1
	bne	.L0809DA28
	ldrb	r2, [r4, #8]
	cmp	r5, r2
	bhs	.L0809DA28
.L0809DA20:
	movs	r0, #0
	b	.L0809DA3C
.P0809DA24:	.word gDsVoices+0x2D0
.L0809DA28:
	ldrb	r0, [r4, #1]
	cmp	r0, #0
	beq	.L0809DA34
	adds	r0, r4, #0
	bl	voiceStop
.L0809DA34:
	movs	r0, #1
	strb	r0, [r4, #1]
	strb	r5, [r4, #8]
.L0809DA3A:
	adds	r0, r4, #0
.L0809DA3C:
	pop	{r4, r5}
	pop	{r1}
	bx	r1
	movs	r0, r0

@ ======================================================================================
@ trackInitAll   (0809DA44)
@
@   void trackInitAll(void)
@   {
@       for (i = 0; i < 24; i++) gTracks[i].player = NULL, gTracks[i].voices = NULL;
@   }
@ ======================================================================================
	.global trackInitAll
	.thumb_func
trackInitAll:
	ldr	r0, .P0809DA68	@ =gTracks
	movs	r1, #0
	adds	r0, #8
	movs	r2, #0x17
.L0809DA4C:
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
	bge	.L0809DA4C
	bx	lr
	.hword 0x0000
.P0809DA68:	.word gTracks

@ ======================================================================================
@ trackAlloc   (0809DA6C)
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
	ldr	r1, .P0809DA7C	@ =gTracks
	ldr	r0, .P0809DA80	@ =0x0000078C
	adds	r2, r1, r0
.L0809DA72:
	ldr	r0, [r1, #8]
	cmp	r0, #0
	bne	.L0809DA84
	adds	r0, r1, #0
	b	.L0809DA8C
.P0809DA7C:	.word gTracks
.P0809DA80:	.word 0x0000078C
.L0809DA84:
	adds	r1, #0x54
	cmp	r1, r2
	ble	.L0809DA72
	movs	r0, #0
.L0809DA8C:
	bx	lr
	movs	r0, r0

@ ======================================================================================
@ trackStart   (0809DA90)
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
	beq	.L0809DB46
	ldr	r0, [r5, #8]
	cmp	r0, #0
	beq	.L0809DAA8
	adds	r0, r5, #0
	bl	trackStop
.L0809DAA8:
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
	adds	r0, #0x42
	ldrb	r3, [r0]
	cmp	r3, #1
	bne	.L0809DB1A
	adds	r1, #2
	movs	r0, #0xc
	strb	r0, [r1]
	subs	r1, #6
	movs	r0, #0x7f
	strb	r0, [r1]
	adds	r0, r5, #0
	adds	r0, #0x53
	strb	r3, [r0]
	b	.L0809DB2C
.L0809DB1A:
	adds	r1, r5, #0
	adds	r1, #0x52
	movs	r0, #3
	strb	r0, [r1]
	adds	r0, r5, #0
	adds	r0, #0x4c
	strb	r2, [r0]
	adds	r0, #7
	strb	r2, [r0]
.L0809DB2C:
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
.L0809DB46:
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ trackReleaseAll   (0809DB4C)
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
	beq	.L0809DB74
	adds	r1, r4, #0
	adds	r1, #0x49
	ldrb	r6, [r1]
	movs	r0, #0
	strb	r0, [r1]
	ldr	r0, [r4, #0xc]
	adds	r5, r1, #0
	cmp	r0, #0
	beq	.L0809DB72
.L0809DB66:
	ldr	r4, [r0, #0x74]
	bl	noteOff
	adds	r0, r4, #0
	cmp	r0, #0
	bne	.L0809DB66
.L0809DB72:
	strb	r6, [r5]
.L0809DB74:
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ trackStop   (0809DB7C)
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
	beq	.L0809DB8C
	bl	trackReleaseAll
	movs	r0, #0
	str	r0, [r4, #8]
.L0809DB8C:
	pop	{r4}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ trackTick   (0809DB94)
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
@
@   In this build: Differences:
@     * E4 (tempo) takes one byte, not a variable-length number.
@     * There is no EA (song volume): EA is a one-byte no-op.
@     * Note lengths are passed to noteOn as (u16)(ticks * 150).
@     * While the player is paused, every frame releases all notes of the track
@       (trackReleaseAll) and the track does not advance.
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
	beq	.L0809DBA8
	ldr	r1, [r5, #8]
	cmp	r1, #0
	bne	.L0809DBAC
.L0809DBA8:
	movs	r0, #1
	b	.L0809DFF2
.L0809DBAC:
	mov	r8, r1
	mov	r0, r8
	adds	r0, #0x3c
	ldrb	r1, [r0]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	bne	.L0809DBBE
	b	.L0809DFD8
.L0809DBBE:
	adds	r0, r5, #0
	bl	trackReleaseAll
	b	.L0809DFF0
.L0809DBC6:
	adds	r0, r5, #0
	bl	trackStop
	movs	r0, #2
	b	.L0809DFF2
.L0809DBD0:
	ldr	r2, [r5]
	ldrb	r6, [r2]
	adds	r2, #1
	str	r2, [r5]
	cmp	r6, #0xbf
	bhi	.L0809DC5A
	cmp	r6, #0x5f
	bhi	.L0809DBEC
	adds	r0, r5, #0
	adds	r0, #0x44
	ldrh	r4, [r0]
	adds	r0, #4
	ldrb	r2, [r0]
	b	.L0809DC12
.L0809DBEC:
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
.L0809DC12:
	movs	r0, #0x96
	muls	r4, r0, r4
	ldr	r0, .P0809DC3C	@ =gHookNote
	ldr	r7, [r0]
	cmp	r7, #0
	beq	.L0809DC40
	mov	r0, r8
	adds	r0, #0x43
	ldrb	r1, [r0]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0809DC40
	lsls	r3, r4, #0x10
	lsrs	r3, r3, #0x10
	adds	r0, r5, #0
	adds	r1, r6, #0
	bl	_call_via_r7
	b	.L0809DC4C
	.hword 0x0000
.P0809DC3C:	.word gHookNote
.L0809DC40:
	lsls	r3, r4, #0x10
	lsrs	r3, r3, #0x10
	adds	r0, r5, #0
	adds	r1, r6, #0
	bl	noteOn
.L0809DC4C:
	adds	r0, r5, #0
	adds	r0, #0x53
	ldrb	r0, [r0]
	cmp	r0, #1
	beq	.L0809DC58
	b	.L0809DFD8
.L0809DC58:
	b	.L0809DC7E
.L0809DC5A:
	cmp	r6, #0xc0
	bne	.L0809DC66
	adds	r0, r5, #0
	adds	r0, #0x46
	ldrh	r4, [r0]
	b	.L0809DC7A
.L0809DC66:
	cmp	r6, #0xc1
	bne	.L0809DC86
	adds	r0, r5, #0
	bl	readVarLen
	lsls	r0, r0, #0x10
	lsrs	r4, r0, #0x10
	adds	r0, r5, #0
	adds	r0, #0x46
	strh	r4, [r0]
.L0809DC7A:
	movs	r0, #0x96
	muls	r4, r0, r4
.L0809DC7E:
	ldr	r0, [r5, #0x34]
	adds	r0, r0, r4
	str	r0, [r5, #0x34]
	b	.L0809DFD8
.L0809DC86:
	movs	r0, #0xf0
	ands	r0, r6
	cmp	r0, #0xd0
	bne	.L0809DCC6
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
	beq	.L0809DCBE
	ldrb	r0, [r3, #1]
	strh	r0, [r5, #0x20]
	adds	r0, r2, #1
	str	r0, [r5]
	b	.L0809DCC0
.L0809DCBE:
	strh	r1, [r5, #0x20]
.L0809DCC0:
	movs	r0, #1
	strb	r0, [r5, #0x1c]
	b	.L0809DFD8
.L0809DCC6:
	adds	r0, r6, #0
	subs	r0, #0xc2
	cmp	r0, #0x3d
	bls	.L0809DCD0
	b	.L0809DFD8
.L0809DCD0:
	lsls	r0, r0, #2
	ldr	r1, .P0809DCDC	@ =0x0809DCE0
	adds	r0, r0, r1
	ldr	r0, [r0]
	mov	pc, r0
	.hword 0x0000
.P0809DCDC:	.word 0x0809DCE0
	.word .L0809DE36
	.word .L0809DE52
	.word .L0809DE5E
	.word .L0809DEA6
	.word .L0809DEA6
	.word .L0809DE42
	.word .L0809DEBA
	.word .L0809DEC4
	.word .L0809DECE
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DE6A
	.word .L0809DE76
	.word .L0809DE82
	.word .L0809DE9A
	.word .L0809DEF4
	.word .L0809DEFE
	.word .L0809DF0E
	.word .L0809DF06
	.word .L0809DDEE
	.word .L0809DE8E
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DDF4
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DE0E
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DF1A
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DFD8
	.word .L0809DDD8
.L0809DDD8:
	adds	r0, r5, #0
	adds	r0, #0x24
	ldr	r1, [r5, #0x30]
	cmp	r1, r0
	bne	.L0809DDE4
	b	.L0809DBC6
.L0809DDE4:
	subs	r0, r1, #4
	str	r0, [r5, #0x30]
	ldr	r0, [r0]
	str	r0, [r5]
	b	.L0809DFD8
.L0809DDEE:
	movs	r0, #0
	strb	r0, [r5, #0x1c]
	b	.L0809DFD8
.L0809DDF4:
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
	b	.L0809DE2C
.L0809DE0E:
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
.L0809DE2C:
	mov	r0, sp
	ldrh	r0, [r0]
	adds	r1, r1, r0
	str	r1, [r5]
	b	.L0809DFD8
.L0809DE36:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x42
	strh	r1, [r2]
	b	.L0809DEEE
.L0809DE42:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r0, #1
	str	r0, [r5]
	adds	r0, r5, #0
	bl	trackSetBank
	b	.L0809DFD8
.L0809DE52:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x4b
	strb	r1, [r2]
	b	.L0809DEEE
.L0809DE5E:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x52
	strb	r1, [r2]
	b	.L0809DEEE
.L0809DE6A:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x4d
	strb	r1, [r2]
	b	.L0809DEEE
.L0809DE76:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x4f
	strb	r1, [r2]
	b	.L0809DEEE
.L0809DE82:
	ldr	r0, [r5]
	ldrb	r2, [r0]
	adds	r1, r5, #0
	adds	r1, #0x50
	strb	r2, [r1]
	b	.L0809DEEE
.L0809DE8E:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x51
	strb	r1, [r2]
	b	.L0809DEEE
.L0809DE9A:
	ldr	r0, [r5]
	ldrb	r2, [r0]
	adds	r1, r5, #0
	adds	r1, #0x4c
	strb	r2, [r1]
	b	.L0809DEEE
.L0809DEA6:
	adds	r0, r5, #0
	bl	trackReleaseAll
	movs	r1, #0
	cmp	r6, #0xc5
	bne	.L0809DEB4
	movs	r1, #1
.L0809DEB4:
	adds	r0, r5, #0
	adds	r0, #0x49
	b	.L0809DFD6
.L0809DEBA:
	adds	r1, r5, #0
	adds	r1, #0x53
	movs	r0, #1
	strb	r0, [r1]
	b	.L0809DFD8
.L0809DEC4:
	adds	r1, r5, #0
	adds	r1, #0x53
	movs	r0, #0
	strb	r0, [r1]
	b	.L0809DFD8
.L0809DECE:
	ldr	r0, .P0809DEE8	@ =gHookCA
	ldr	r2, [r0]
	cmp	r2, #0
	beq	.L0809DEEC
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r0, #1
	str	r0, [r5]
	adds	r0, r5, #0
	bl	_call_via_r2
	b	.L0809DFD8
	.hword 0x0000
.P0809DEE8:	.word gHookCA
.L0809DEEC:
	ldr	r0, [r5]
.L0809DEEE:
	adds	r0, #1
	str	r0, [r5]
	b	.L0809DFD8
.L0809DEF4:
	ldr	r1, [r5]
	ldrb	r0, [r1]
	mov	r3, r8
	strh	r0, [r3, #0x30]
	b	.L0809DF14
.L0809DEFE:
	ldr	r1, [r5]
	ldrb	r0, [r1]
	strh	r0, [r5, #0x10]
	b	.L0809DF14
.L0809DF06:
	ldr	r1, [r5]
	ldrb	r0, [r1]
	str	r0, [r5, #0x18]
	b	.L0809DF14
.L0809DF0E:
	ldr	r1, [r5]
	ldrb	r0, [r1]
	str	r0, [r5, #0x14]
.L0809DF14:
	adds	r1, #1
	str	r1, [r5]
	b	.L0809DFD8
.L0809DF1A:
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
	bne	.L0809DF4E
	bl	trackAlloc
	adds	r4, r0, #0
	str	r4, [r6]
	b	.L0809DF54
.L0809DF4E:
	adds	r4, r0, #0
	bl	trackStop
.L0809DF54:
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
.L0809DFD6:
	strb	r1, [r0]
.L0809DFD8:
	ldr	r1, [r5, #0x34]
	cmp	r1, #0
	bgt	.L0809DFE0
	b	.L0809DBD0
.L0809DFE0:
	mov	r2, r8
	ldrh	r0, [r2, #0x30]
	subs	r0, r1, r0
	str	r0, [r5, #0x34]
	movs	r3, #0x32
	ldrsh	r1, [r2, r3]
	subs	r0, r0, r1
	str	r0, [r5, #0x34]
.L0809DFF0:
	movs	r0, #0
.L0809DFF2:
	add	sp, #4
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1
	movs	r0, r0

@ ======================================================================================
@ trackAddVoice   (0809E000)
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
	ldr	r2, [r1, #4]
	cmp	r2, #0
	bne	.L0809E016
	str	r0, [r1, #4]
	str	r2, [r1, #0x70]
	ldr	r2, [r0, #0xc]
	str	r2, [r1, #0x74]
	str	r1, [r0, #0xc]
	cmp	r2, #0
	beq	.L0809E016
	str	r1, [r2, #0x70]
.L0809E016:
	bx	lr

@ ======================================================================================
@ trackRemoveVoice   (0809E018)
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
	adds	r3, r0, #0
	ldr	r0, [r1, #4]
	cmp	r0, #0
	beq	.L0809E03E
	movs	r0, #0
	str	r0, [r1, #4]
	ldr	r2, [r1, #0x74]
	cmp	r2, #0
	beq	.L0809E02E
	ldr	r0, [r1, #0x70]
	str	r0, [r2, #0x70]
.L0809E02E:
	ldr	r2, [r1, #0x70]
	cmp	r2, #0
	beq	.L0809E03A
	ldr	r0, [r1, #0x74]
	str	r0, [r2, #0x74]
	b	.L0809E03E
.L0809E03A:
	ldr	r0, [r1, #0x74]
	str	r0, [r3, #0xc]
.L0809E03E:
	bx	lr

@ ======================================================================================
@ readVarLen   (0809E040)
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
	adds	r3, r0, #0
	ldr	r2, [r3]
	ldrb	r1, [r2]
	adds	r2, #1
	str	r2, [r3]
	movs	r0, #0x80
	ands	r0, r1
	cmp	r0, #0
	beq	.L0809E060
	movs	r0, #0x7f
	ands	r1, r0
	lsls	r1, r1, #8
	ldrb	r0, [r2]
	orrs	r1, r0
	adds	r0, r2, #1
	str	r0, [r3]
.L0809E060:
	adds	r0, r1, #0
	bx	lr

@ ======================================================================================
@ trackSetBank   (0809E064)
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
	ldr	r0, .P0809E094	@ =gCfg
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
.P0809E094:	.word gCfg

@ ======================================================================================
@ playerInitAll   (0809E098)
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
	ldr	r4, .P0809E0C8	@ =gPlayers
	movs	r3, #0
.L0809E0A0:
	lsls	r0, r2, #4
	adds	r0, r0, r2
	lsls	r0, r0, #2
	adds	r0, r0, r4
	adds	r1, r0, #0
	adds	r1, #0x41
	strb	r3, [r1]
	adds	r2, #1
	movs	r1, #9
	adds	r0, #0x2c
.L0809E0B4:
	str	r3, [r0]
	subs	r0, #4
	subs	r1, #1
	cmp	r1, #0
	bge	.L0809E0B4
	cmp	r2, #0x13
	ble	.L0809E0A0
	pop	{r4}
	pop	{r0}
	bx	r0
.P0809E0C8:	.word gPlayers

@ ======================================================================================
@ playerReset   (0809E0CC)
@
@   void playerReset(Player *p)
@   {
@       p->flags &= ~PAUSED; p->tempo = 150; p->tempoOfs = 0;
@       p->songVolume = 128; p->volume2 = 128; p->volume = 0x8000;
@       p->fadeStep = 0; p->fadeCount = 0; p->fadeTarget = 0; p->flags44 = 0;
@   }
@
@   In this build: Same without the song volume (the Player is 0x44 bytes: volume2 at +0x40, state +0x41,
@   isSfx +0x42, hookFlags +0x43).
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
	adds	r1, #0x40
	movs	r0, #0x80
	strb	r0, [r1]
	movs	r0, #0x80
	lsls	r0, r0, #8
	mov	r1, ip
	strh	r0, [r1, #0x34]
	strh	r2, [r1, #0x36]
	strh	r2, [r1, #0x3a]
	strh	r2, [r1, #0x38]
	mov	r0, ip
	adds	r0, #0x43
	strb	r3, [r0]
	bx	lr

@ ======================================================================================
@ playerTickAll   (0809E104)
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
.L0809E10A:
	lsls	r0, r6, #4
	adds	r0, r0, r6
	lsls	r0, r0, #2
	ldr	r1, .P0809E134	@ =gPlayers
	adds	r1, r0, r1
	adds	r0, r1, #0
	adds	r0, #0x41
	ldrb	r0, [r0]
	adds	r7, r6, #1
	cmp	r0, #0
	beq	.L0809E186
	ldrh	r2, [r1, #0x3a]
	cmp	r2, #0
	bne	.L0809E138
	cmp	r0, #2
	bne	.L0809E14E
	adds	r0, r6, #0
	bl	playerStop
	b	.L0809E186
	.hword 0x0000
.P0809E134:	.word gPlayers
.L0809E138:
	ldrh	r0, [r1, #0x36]
	ldrh	r3, [r1, #0x34]
	adds	r0, r0, r3
	strh	r0, [r1, #0x34]
	subs	r0, r2, #1
	strh	r0, [r1, #0x3a]
	lsls	r0, r0, #0x10
	cmp	r0, #0
	bne	.L0809E14E
	ldrh	r0, [r1, #0x38]
	strh	r0, [r1, #0x34]
.L0809E14E:
	movs	r2, #0
	adds	r7, r6, #1
	adds	r4, r1, #0
	adds	r4, #8
	movs	r5, #9
.L0809E158:
	ldr	r0, [r4]
	cmp	r0, #0
	beq	.L0809E174
	str	r2, [sp]
	bl	trackTick
	lsls	r0, r0, #0x18
	ldr	r2, [sp]
	cmp	r0, #0
	bne	.L0809E170
	movs	r2, #1
	b	.L0809E174
.L0809E170:
	movs	r0, #0
	str	r0, [r4]
.L0809E174:
	adds	r4, #4
	subs	r5, #1
	cmp	r5, #0
	bge	.L0809E158
	cmp	r2, #0
	bne	.L0809E186
	adds	r0, r6, #0
	bl	playerStop
.L0809E186:
	adds	r6, r7, #0
	cmp	r6, #0x13
	ble	.L0809E10A
	add	sp, #4
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ doPlaySong   (0809E194)
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
	ldr	r2, .P0809E1B8	@ =gCfg
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
.P0809E1B8:	.word gCfg

@ ======================================================================================
@ doPlaySfx   (0809E1BC)
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
	ldr	r2, .P0809E1E4	@ =gCfg
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
.P0809E1E4:	.word gCfg

@ ======================================================================================
@ playerStartSong   (0809E1E8)
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
	lsls	r0, r3, #4
	adds	r0, r0, r3
	lsls	r0, r0, #2
	ldr	r1, .P0809E26C	@ =gPlayers
	adds	r5, r0, r1
	adds	r4, r5, #0
	adds	r4, #0x41
	ldrb	r0, [r4]
	cmp	r0, #0
	beq	.L0809E20E
	adds	r0, r3, #0
	bl	playerStop
.L0809E20E:
	str	r6, [r5, #4]
	str	r7, [r5]
	adds	r1, r5, #0
	adds	r1, #0x42
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
	bge	.L0809E25A
	adds	r4, r0, #0
.L0809E232:
	ldrh	r0, [r4]
	cmp	r0, #0
	beq	.L0809E252
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
.L0809E252:
	adds	r4, #2
	adds	r6, #1
	cmp	r6, r7
	blt	.L0809E232
.L0809E25A:
	movs	r0, #1
	mov	r1, r8
	strb	r0, [r1]
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0809E26C:	.word gPlayers

@ ======================================================================================
@ playerStartSfx   (0809E270)
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
	lsls	r0, r4, #4
	adds	r0, r0, r4
	lsls	r0, r0, #2
	ldr	r1, .P0809E2D8	@ =gPlayers
	adds	r5, r0, r1
	movs	r0, #0x41
	adds	r0, r0, r5
	mov	r8, r0
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L0809E29C
	adds	r0, r4, #0
	bl	playerStop
.L0809E29C:
	str	r6, [r5, #4]
	str	r7, [r5]
	adds	r0, r5, #0
	adds	r0, #0x42
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
.P0809E2D8:	.word gPlayers

@ ======================================================================================
@ playerStop   (0809E2DC)
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
	lsls	r1, r0, #4
	adds	r1, r1, r0
	lsls	r1, r1, #2
	ldr	r0, .P0809E314	@ =gPlayers
	adds	r1, r1, r0
	adds	r2, r1, #0
	adds	r2, #0x41
	ldrb	r0, [r2]
	cmp	r0, #0
	beq	.L0809E30E
	adds	r7, r2, #0
	movs	r6, #0
	adds	r4, r1, #0
	adds	r4, #8
	movs	r5, #9
.L0809E2FC:
	ldr	r0, [r4]
	bl	trackStop
	stm	r4!, {r6}
	subs	r5, #1
	cmp	r5, #0
	bge	.L0809E2FC
	movs	r0, #0
	strb	r0, [r7]
.L0809E30E:
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
.P0809E314:	.word gPlayers

@ ======================================================================================
@ playerFadeOut   (0809E318)
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
	lsls	r1, r0, #4
	adds	r1, r1, r0
	lsls	r1, r1, #2
	ldr	r0, .P0809E34C	@ =gPlayers
	adds	r4, r1, r0
	adds	r2, r4, #0
	adds	r2, #0x41
	ldrb	r0, [r2]
	cmp	r0, #0
	beq	.L0809E346
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
.L0809E346:
	pop	{r4}
	pop	{r0}
	bx	r0
.P0809E34C:	.word gPlayers

@ ======================================================================================
@ playerSetPause   (0809E350)
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
	ldr	r3, .P0809E370	@ =gPlayers
	lsls	r2, r0, #4
	adds	r2, r2, r0
	lsls	r2, r2, #2
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
.P0809E370:	.word gPlayers

@ ======================================================================================
@ sndGetPlayerState   (0809E374)
@
@   u32 sndGetPlayerState(u32 pl)       /* 0 idle, 1 playing, 2 fading out (read directly) */
@   {
@       return gPlayers[pl].state;
@   }
@ ======================================================================================
	.global sndGetPlayerState
	.thumb_func
sndGetPlayerState:
	ldr	r2, .P0809E384	@ =gPlayers
	lsls	r1, r0, #4
	adds	r1, r1, r0
	lsls	r1, r1, #2
	adds	r2, #0x41
	adds	r1, r1, r2
	ldrb	r0, [r1]
	bx	lr
.P0809E384:	.word gPlayers

@ ======================================================================================
@ cmdNext   (0809E388)
@
@   void cmdNext(void)                  /* advance the write pointer (wraps at 46 entries) */
@   {
@       if (++gCmdWrite == gCmdEnd) gCmdWrite = gCmdQueue;
@   }
@ ======================================================================================
	.global cmdNext
	.thumb_func
cmdNext:
	ldr	r2, .P0809E3A0	@ =gCmdWrite
	ldr	r0, [r2]
	adds	r0, #0xc
	str	r0, [r2]
	ldr	r1, .P0809E3A4	@ =gCmdEnd
	ldr	r1, [r1]
	cmp	r0, r1
	bne	.L0809E39C
	ldr	r0, .P0809E3A8	@ =gCmdQueue
	str	r0, [r2]
.L0809E39C:
	bx	lr
	.hword 0x0000
.P0809E3A0:	.word gCmdWrite
.P0809E3A4:	.word gCmdEnd
.P0809E3A8:	.word gCmdQueue

@ ======================================================================================
@ cmdInit   (0809E3AC)
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
	ldr	r0, .P0809E3D0	@ =gCmdRead
	ldr	r1, .P0809E3D4	@ =gCmdQueue
	str	r1, [r0]
	ldr	r0, .P0809E3D8	@ =gCmdWrite
	str	r1, [r0]
	ldr	r0, .P0809E3DC	@ =gCmdCommitted
	str	r1, [r0]
	ldr	r0, .P0809E3E0	@ =gCmdEnd
	movs	r2, #0x8a
	lsls	r2, r2, #2
	adds	r1, r1, r2
	str	r1, [r0]
	ldr	r0, .P0809E3E4	@ =gHookNote
	movs	r1, #0
	str	r1, [r0]
	ldr	r0, .P0809E3E8	@ =gHookCA
	str	r1, [r0]
	bx	lr
.P0809E3D0:	.word gCmdRead
.P0809E3D4:	.word gCmdQueue
.P0809E3D8:	.word gCmdWrite
.P0809E3DC:	.word gCmdCommitted
.P0809E3E0:	.word gCmdEnd
.P0809E3E4:	.word gHookNote
.P0809E3E8:	.word gHookCA

@ ======================================================================================
@ cmdPop   (0809E3EC)
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
	ldr	r3, .P0809E3FC	@ =gCmdRead
	ldr	r2, [r3]
	ldr	r0, .P0809E400	@ =gCmdCommitted
	ldr	r0, [r0]
	cmp	r2, r0
	bne	.L0809E404
	movs	r0, #0
	b	.L0809E418
.P0809E3FC:	.word gCmdRead
.P0809E400:	.word gCmdCommitted
.L0809E404:
	adds	r0, r2, #0
	adds	r0, #0xc
	str	r0, [r3]
	ldr	r1, .P0809E41C	@ =gCmdEnd
	ldr	r1, [r1]
	cmp	r0, r1
	bne	.L0809E416
	ldr	r0, .P0809E420	@ =gCmdQueue
	str	r0, [r3]
.L0809E416:
	adds	r0, r2, #0
.L0809E418:
	bx	lr
	.hword 0x0000
.P0809E41C:	.word gCmdEnd
.P0809E420:	.word gCmdQueue

@ ======================================================================================
@ sndCommit   (0809E424)
@
@   void sndCommit(void)                /* make the commands queued since the last call visible */
@   {
@       gCmdCommitted = gCmdWrite;      /* no overflow check: 47 queued commands lose 46         */
@   }
@ ======================================================================================
	.global sndCommit
	.thumb_func
sndCommit:
	ldr	r0, .P0809E430	@ =gCmdCommitted
	ldr	r1, .P0809E434	@ =gCmdWrite
	ldr	r1, [r1]
	str	r1, [r0]
	bx	lr
	.hword 0x0000
.P0809E430:	.word gCmdCommitted
.P0809E434:	.word gCmdWrite

@ ======================================================================================
@ sndPlaySong   (0809E438)
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
	ldr	r2, .P0809E458	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #0
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0809E458:	.word gCmdWrite

@ ======================================================================================
@ sndPlaySfx   (0809E45C)
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
	ldr	r3, .P0809E480	@ =gCmdWrite
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
.P0809E480:	.word gCmdWrite

@ ======================================================================================
@ sndFadeOut   (0809E484)
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
	ldr	r2, .P0809E4A4	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #2
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0809E4A4:	.word gCmdWrite

@ ======================================================================================
@ sndPause   (0809E4A8)
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
	ldr	r2, .P0809E4C8	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #3
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0809E4C8:	.word gCmdWrite

@ ======================================================================================
@ sndFadeOutMask   (0809E4CC)
@
@   void sndFadeOutMask(u32 mask, u32 frames)      { queue(0x200, frames, mask); }
@ ======================================================================================
	.global sndFadeOutMask
	.thumb_func
sndFadeOutMask:
	push	{lr}
	lsls	r1, r1, #0x10
	lsrs	r1, r1, #0x10
	ldr	r2, .P0809E4E8	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #0x80
	lsls	r3, r3, #2
	strh	r3, [r2]
	str	r1, [r2, #4]
	str	r0, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
.P0809E4E8:	.word gCmdWrite

@ ======================================================================================
@ sndPauseMask   (0809E4EC)
@
@   void sndPauseMask(u32 mask, u32 on)            { queue(0x201, on, mask); }
@ ======================================================================================
	.global sndPauseMask
	.thumb_func
sndPauseMask:
	push	{lr}
	lsls	r1, r1, #0x18
	lsrs	r1, r1, #0x18
	ldr	r2, .P0809E508	@ =gCmdWrite
	ldr	r2, [r2]
	ldr	r3, .P0809E50C	@ =0x00000201
	strh	r3, [r2]
	str	r1, [r2, #4]
	str	r0, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0809E508:	.word gCmdWrite
.P0809E50C:	.word 0x00000201

@ ======================================================================================
@ sndSetTempo   (0809E510)
@
@   void sndSetTempo(u32 pl, s32 ofs)              { queue(0x004, pl, ofs); }   /* tempo offset   */
@ ======================================================================================
	.global sndSetTempo
	.thumb_func
sndSetTempo:
	push	{lr}
	lsls	r0, r0, #0x10
	lsrs	r0, r0, #0x10
	ldr	r2, .P0809E530	@ =gCmdWrite
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
.P0809E530:	.word gCmdWrite

@ ======================================================================================
@ sndSetVolume2   (0809E534)
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
	ldr	r2, .P0809E554	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #5
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0809E554:	.word gCmdWrite

@ ======================================================================================
@ sndSetHookFlags   (0809E558)
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
	ldr	r2, .P0809E578	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #6
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0809E578:	.word gCmdWrite

@ ======================================================================================
@ sndMuteTracks   (0809E57C)
@
@   void sndMuteTracks(u32 pl, u32 mask, u32 on)   { queue(0x100, pl << 16 | on, mask); }
@ ======================================================================================
	.global sndMuteTracks
	.thumb_func
sndMuteTracks:
	push	{r4, lr}
	lsls	r2, r2, #0x18
	lsrs	r2, r2, #0x18
	ldr	r3, .P0809E5A0	@ =gCmdWrite
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
.P0809E5A0:	.word gCmdWrite

@ ======================================================================================
@ sndSetTrackExpr   (0809E5A4)
@
@   void sndSetTrackExpr(u32 pl, u32 mask, u32 v)  { queue(0x102, pl << 16 | v, mask); }
@ ======================================================================================
	.global sndSetTrackExpr
	.thumb_func
sndSetTrackExpr:
	push	{r4, lr}
	lsls	r2, r2, #0x18
	lsrs	r2, r2, #0x18
	ldr	r3, .P0809E5C8	@ =gCmdWrite
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
.P0809E5C8:	.word gCmdWrite

@ ======================================================================================
@ sndSetTrackPan   (0809E5CC)
@
@   void sndSetTrackPan(u32 pl, u32 mask, u32 pan) { queue(0x101, pl << 16 | pan, mask); }
@ ======================================================================================
	.global sndSetTrackPan
	.thumb_func
sndSetTrackPan:
	push	{r4, lr}
	lsls	r2, r2, #0x18
	lsrs	r2, r2, #0x18
	ldr	r3, .P0809E5EC	@ =gCmdWrite
	ldr	r4, [r3]
	ldr	r3, .P0809E5F0	@ =0x00000101
	strh	r3, [r4]
	lsls	r0, r0, #0x10
	orrs	r0, r2
	str	r0, [r4, #4]
	str	r1, [r4, #8]
	bl	cmdNext
	pop	{r4}
	pop	{r0}
	bx	r0
.P0809E5EC:	.word gCmdWrite
.P0809E5F0:	.word 0x00000101

@ ======================================================================================
@ sndSetEcho   (0809E5F4)
@
@   void sndSetEcho(u32 shift)                     { queue(0x300, shift); }     /* 16 = off       */
@ ======================================================================================
	.global sndSetEcho
	.thumb_func
sndSetEcho:
	push	{lr}
	lsls	r0, r0, #0x18
	lsrs	r0, r0, #0x18
	ldr	r1, .P0809E610	@ =gCmdWrite
	ldr	r2, [r1]
	movs	r1, #0xc0
	lsls	r1, r1, #2
	strh	r1, [r2]
	str	r0, [r2, #4]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0809E610:	.word gCmdWrite

@ ======================================================================================
@ sndCallback   (0809E614)
@
@   void sndCallback(void (*fn)(u32), u32 arg)     { queue(0x301, fn, arg); }   /* run fn(arg) in sndMain */
@ ======================================================================================
	.global sndCallback
	.thumb_func
sndCallback:
	push	{lr}
	ldr	r2, .P0809E62C	@ =gCmdWrite
	ldr	r2, [r2]
	ldr	r3, .P0809E630	@ =0x00000301
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0809E62C:	.word gCmdWrite
.P0809E630:	.word 0x00000301

@ ======================================================================================
@ sndSetHookCA   (0809E634)
@
@   void sndSetHookCA(void *fn)                    { queue(0x302, fn); }
@ ======================================================================================
	.global sndSetHookCA
	.thumb_func
sndSetHookCA:
	push	{lr}
	ldr	r1, .P0809E648	@ =gCmdWrite
	ldr	r2, [r1]
	ldr	r1, .P0809E64C	@ =0x00000302
	strh	r1, [r2]
	str	r0, [r2, #4]
	bl	cmdNext
	pop	{r0}
	bx	r0
.P0809E648:	.word gCmdWrite
.P0809E64C:	.word 0x00000302

@ ======================================================================================
@ sndSetHookNote   (0809E650)
@
@   void sndSetHookNote(void *fn)                  { queue(0x303, fn); }
@ ======================================================================================
	.global sndSetHookNote
	.thumb_func
sndSetHookNote:
	push	{lr}
	ldr	r1, .P0809E664	@ =gCmdWrite
	ldr	r2, [r1]
	ldr	r1, .P0809E668	@ =0x00000303
	strh	r1, [r2]
	str	r0, [r2, #4]
	bl	cmdNext
	pop	{r0}
	bx	r0
.P0809E664:	.word gCmdWrite
.P0809E668:	.word 0x00000303

@ ======================================================================================
@ cmdPlayer   (0809E66C)
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
@
@   In this build: Same: command 5 writes volume2 (+0x40), command 6 hookFlags (+0x43).
@ ======================================================================================
	.global cmdPlayer
	.thumb_func
cmdPlayer:
	push	{lr}
	adds	r3, r0, #0
	ldr	r0, [r3, #4]
	lsls	r1, r0, #4
	adds	r1, r1, r0
	lsls	r1, r1, #2
	ldr	r0, .P0809E68C	@ =gPlayers
	adds	r2, r1, r0
	ldrh	r0, [r3]
	cmp	r0, #6
	bhi	.L0809E6FA
	lsls	r0, r0, #2
	ldr	r1, .P0809E690	@ =0x0809E694
	adds	r0, r0, r1
	ldr	r0, [r0]
	mov	pc, r0
.P0809E68C:	.word gPlayers
.P0809E690:	.word 0x0809E694
	.word .L0809E6B0
	.word .L0809E6BA
	.word .L0809E6D0
	.word .L0809E6DA
	.word .L0809E6EC
	.word .L0809E6F2
	.word .L0809E6E4
.L0809E6B0:
	ldr	r0, [r3, #4]
	ldr	r1, [r3, #8]
	bl	doPlaySong
	b	.L0809E6FA
.L0809E6BA:
	ldr	r1, [r3, #4]
	lsrs	r0, r1, #0x10
	ldr	r2, .P0809E6CC	@ =0x0000FFFF
	ands	r1, r2
	ldr	r2, [r3, #8]
	bl	doPlaySfx
	b	.L0809E6FA
	.hword 0x0000
.P0809E6CC:	.word 0x0000FFFF
.L0809E6D0:
	ldr	r0, [r3, #4]
	ldr	r1, [r3, #8]
	bl	playerFadeOut
	b	.L0809E6FA
.L0809E6DA:
	ldr	r0, [r3, #4]
	ldrb	r1, [r3, #8]
	bl	playerSetPause
	b	.L0809E6FA
.L0809E6E4:
	ldr	r1, [r3, #8]
	adds	r0, r2, #0
	adds	r0, #0x43
	b	.L0809E6F8
.L0809E6EC:
	ldr	r0, [r3, #8]
	strh	r0, [r2, #0x32]
	b	.L0809E6FA
.L0809E6F2:
	ldr	r1, [r3, #8]
	adds	r0, r2, #0
	adds	r0, #0x40
.L0809E6F8:
	strb	r1, [r0]
.L0809E6FA:
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ cmdTrack   (0809E700)
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
@
@   In this build: Same without command 0x103 (pitch bend).
@ ======================================================================================
	.global cmdTrack
	.thumb_func
cmdTrack:
	push	{r4, r5, lr}
	adds	r2, r0, #0
	ldrh	r0, [r2, #6]
	lsls	r1, r0, #4
	adds	r1, r1, r0
	lsls	r1, r1, #2
	ldr	r0, .P0809E728	@ =gPlayers
	adds	r1, r1, r0
	movs	r4, #0
	ldrh	r3, [r2]
	ldr	r0, .P0809E72C	@ =0x00000101
	cmp	r3, r0
	beq	.L0809E79E
	cmp	r3, r0
	bgt	.L0809E730
	subs	r0, #1
	cmp	r3, r0
	beq	.L0809E73A
	b	.L0809E7CE
	.hword 0x0000
.P0809E728:	.word gPlayers
.P0809E72C:	.word 0x00000101
.L0809E730:
	movs	r0, #0x81
	lsls	r0, r0, #1
	cmp	r3, r0
	beq	.L0809E76C
	b	.L0809E7CE
.L0809E73A:
	ldr	r0, [r2, #8]
	cmp	r0, #0
	beq	.L0809E7CE
	movs	r5, #1
	adds	r3, r1, #0
	adds	r3, #8
.L0809E746:
	ands	r0, r5
	cmp	r0, #0
	beq	.L0809E758
	ldr	r0, [r3]
	cmp	r0, #0
	beq	.L0809E758
	ldr	r1, [r2, #4]
	adds	r0, #0x4a
	strb	r1, [r0]
.L0809E758:
	adds	r3, #4
	adds	r4, #1
	ldr	r0, [r2, #8]
	lsrs	r0, r0, #1
	str	r0, [r2, #8]
	cmp	r0, #0
	beq	.L0809E7CE
	cmp	r4, #9
	ble	.L0809E746
	b	.L0809E7CE
.L0809E76C:
	ldr	r0, [r2, #8]
	cmp	r0, #0
	beq	.L0809E7CE
	movs	r5, #1
	adds	r3, r1, #0
	adds	r3, #8
.L0809E778:
	ands	r0, r5
	cmp	r0, #0
	beq	.L0809E78A
	ldr	r0, [r3]
	cmp	r0, #0
	beq	.L0809E78A
	ldr	r1, [r2, #4]
	adds	r0, #0x4e
	strb	r1, [r0]
.L0809E78A:
	adds	r3, #4
	adds	r4, #1
	ldr	r0, [r2, #8]
	lsrs	r0, r0, #1
	str	r0, [r2, #8]
	cmp	r0, #0
	beq	.L0809E7CE
	cmp	r4, #9
	ble	.L0809E778
	b	.L0809E7CE
.L0809E79E:
	ldr	r0, [r2, #8]
	cmp	r0, #0
	beq	.L0809E7CE
	movs	r5, #1
	adds	r3, r1, #0
	adds	r3, #8
.L0809E7AA:
	ands	r0, r5
	cmp	r0, #0
	beq	.L0809E7BC
	ldr	r0, [r3]
	cmp	r0, #0
	beq	.L0809E7BC
	ldr	r1, [r2, #4]
	adds	r0, #0x4b
	strb	r1, [r0]
.L0809E7BC:
	adds	r3, #4
	adds	r4, #1
	ldr	r0, [r2, #8]
	lsrs	r0, r0, #1
	str	r0, [r2, #8]
	cmp	r0, #0
	beq	.L0809E7CE
	cmp	r4, #9
	ble	.L0809E7AA
.L0809E7CE:
	pop	{r4, r5}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ cmdMask   (0809E7D4)
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
	beq	.L0809E7EC
	adds	r0, #1
	cmp	r1, r0
	beq	.L0809E816
	b	.L0809E83E
.L0809E7EC:
	ldr	r1, [r4, #8]
	cmp	r1, #0
	beq	.L0809E83E
.L0809E7F2:
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0809E802
	ldr	r1, [r4, #4]
	adds	r0, r5, #0
	bl	playerFadeOut
.L0809E802:
	adds	r5, #1
	ldr	r0, [r4, #8]
	lsrs	r0, r0, #1
	str	r0, [r4, #8]
	adds	r1, r0, #0
	cmp	r1, #0
	beq	.L0809E83E
	cmp	r5, #0x13
	ble	.L0809E7F2
	b	.L0809E83E
.L0809E816:
	ldr	r1, [r4, #8]
	cmp	r1, #0
	beq	.L0809E83E
.L0809E81C:
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0809E82C
	ldrb	r1, [r4, #4]
	adds	r0, r5, #0
	bl	playerSetPause
.L0809E82C:
	adds	r5, #1
	ldr	r0, [r4, #8]
	lsrs	r0, r0, #1
	str	r0, [r4, #8]
	adds	r1, r0, #0
	cmp	r1, #0
	beq	.L0809E83E
	cmp	r5, #0x13
	ble	.L0809E81C
.L0809E83E:
	pop	{r4, r5}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ cmdGlobal   (0809E844)
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
@
@   In this build: Same without command 0x304 (voice count); 0x300 passes the low byte only.
@ ======================================================================================
	.global cmdGlobal
	.thumb_func
cmdGlobal:
	push	{lr}
	adds	r2, r0, #0
	ldrh	r1, [r2]
	ldr	r0, .P0809E85C	@ =0x00000301
	cmp	r1, r0
	beq	.L0809E874
	cmp	r1, r0
	bgt	.L0809E860
	subs	r0, #1
	cmp	r1, r0
	beq	.L0809E894
	b	.L0809E89A
.P0809E85C:	.word 0x00000301
.L0809E860:
	ldr	r0, .P0809E870	@ =0x00000302
	cmp	r1, r0
	beq	.L0809E87E
	adds	r0, #1
	cmp	r1, r0
	beq	.L0809E888
	b	.L0809E89A
	.hword 0x0000
.P0809E870:	.word 0x00000302
.L0809E874:
	ldr	r0, [r2, #8]
	ldr	r1, [r2, #4]
	bl	_call_via_r1
	b	.L0809E89A
.L0809E87E:
	ldr	r1, .P0809E884	@ =gHookCA
	b	.L0809E88A
	.hword 0x0000
.P0809E884:	.word gHookCA
.L0809E888:
	ldr	r1, .P0809E890	@ =gHookNote
.L0809E88A:
	ldr	r0, [r2, #4]
	str	r0, [r1]
	b	.L0809E89A
.P0809E890:	.word gHookNote
.L0809E894:
	ldrb	r0, [r2, #4]
	bl	echoSetFeedback
.L0809E89A:
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ cmdProcess   (0809E8A0)
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
	beq	.L0809E8C8
	ldr	r4, .P0809E8D0	@ =kCmdHandlers
.L0809E8AE:
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
	bne	.L0809E8AE
.L0809E8C8:
	pop	{r4}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0809E8D0:	.word kCmdHandlers
	.arm

@ ======================================================================================
@ armDownmix   (0809E8D4)
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
@
@   In this build: /* 16-bit accumulator -> 8-bit output with saturation, no shift: the gains were already
@      applied with a >> 8 in armMixVoice. */
@   void armDownmix(const s16 *src, s8 *dst, const s16 *end)
@   {
@       do {                                   /* unrolled x8 */
@           s32 x = *src++;
@           if ((x & 0xFF80) && (x & 0xFF80) != 0xFF80) x = 127 + ((u32)x >> 31);
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
.L0809E8E4:
	ldrsh	r3, [r0], #2
	ands	ip, r3, r5
	cmpne	ip, r5
	addne	r3, r4, r3, lsr #31
	strb	r3, [r1], #1
	ldrsh	r3, [r0], #2
	ands	ip, r3, r5
	cmpne	ip, r5
	addne	r3, r4, r3, lsr #31
	strb	r3, [r1], #1
	ldrsh	r3, [r0], #2
	ands	ip, r3, r5
	cmpne	ip, r5
	addne	r3, r4, r3, lsr #31
	strb	r3, [r1], #1
	ldrsh	r3, [r0], #2
	ands	ip, r3, r5
	cmpne	ip, r5
	addne	r3, r4, r3, lsr #31
	strb	r3, [r1], #1
	ldrsh	r3, [r0], #2
	ands	ip, r3, r5
	cmpne	ip, r5
	addne	r3, r4, r3, lsr #31
	strb	r3, [r1], #1
	ldrsh	r3, [r0], #2
	ands	ip, r3, r5
	cmpne	ip, r5
	addne	r3, r4, r3, lsr #31
	strb	r3, [r1], #1
	ldrsh	r3, [r0], #2
	ands	ip, r3, r5
	cmpne	ip, r5
	addne	r3, r4, r3, lsr #31
	strb	r3, [r1], #1
	ldrsh	r3, [r0], #2
	ands	ip, r3, r5
	cmpne	ip, r5
	addne	r3, r4, r3, lsr #31
	strb	r3, [r1], #1
	cmp	r0, r2
	bne	.L0809E8E4
	pop	{r4, r5}
	bx	lr

@ ======================================================================================
@ armMixVoice   (0809E994)
@
@   u32 armMixVoice(const s8 *pcm, s16 *l, s16 *r, s16 *lEnd, u32 pos, u32 step, u32 vl, u32 vr)
@   {
@       while (l < lEnd) {                     /* unrolled x4 when the count allows */
@           s32 s = pcm[pos >> 8];
@           *l++ += (s * vl) >> 8;  *r++ += (s * vr) >> 8;     /* rounding towards -infinity */
@           pos += step;
@       }
@       return pos;
@   }
@ ======================================================================================
	.global armMixVoice
	.type armMixVoice, %function
armMixVoice:
	mov	ip, sp
	push	{r4, r5, r6, r7, r8, sb}
	ldm	ip, {r4, r5, r6, r7}
	sub	ip, r3, r1
	and	ip, ip, #7
	cmp	ip, #0
	bne	.L0809EA74
.L0809E9B0:
	add	ip, r0, r4, lsr #8
	ldrsb	r8, [ip]
	mul	sb, r8, r6
	ldrsh	ip, [r1]
	add	ip, ip, sb, asr #8
	strh	ip, [r1], #2
	mul	sb, r8, r7
	ldrsh	ip, [r2]
	add	ip, ip, sb, asr #8
	strh	ip, [r2], #2
	add	r4, r4, r5
	add	ip, r0, r4, lsr #8
	ldrsb	r8, [ip]
	mul	sb, r8, r6
	ldrsh	ip, [r1]
	add	ip, ip, sb, asr #8
	strh	ip, [r1], #2
	mul	sb, r8, r7
	ldrsh	ip, [r2]
	add	ip, ip, sb, asr #8
	strh	ip, [r2], #2
	add	r4, r4, r5
	add	ip, r0, r4, lsr #8
	ldrsb	r8, [ip]
	mul	sb, r8, r6
	ldrsh	ip, [r1]
	add	ip, ip, sb, asr #8
	strh	ip, [r1], #2
	mul	sb, r8, r7
	ldrsh	ip, [r2]
	add	ip, ip, sb, asr #8
	strh	ip, [r2], #2
	add	r4, r4, r5
	add	ip, r0, r4, lsr #8
	ldrsb	r8, [ip]
	mul	sb, r8, r6
	ldrsh	ip, [r1]
	add	ip, ip, sb, asr #8
	strh	ip, [r1], #2
	mul	sb, r8, r7
	ldrsh	ip, [r2]
	add	ip, ip, sb, asr #8
	strh	ip, [r2], #2
	add	r4, r4, r5
	cmp	r1, r3
	blo	.L0809E9B0
	mov	r0, r4
	pop	{r4, r5, r6, r7, r8, sb}
	bx	lr
.L0809EA74:
	add	ip, r0, r4, lsr #8
	ldrsb	r8, [ip]
	mul	sb, r8, r6
	ldrsh	ip, [r1]
	add	ip, ip, sb, asr #8
	strh	ip, [r1], #2
	mul	sb, r8, r7
	ldrsh	ip, [r2]
	add	ip, ip, sb, asr #8
	strh	ip, [r2], #2
	add	r4, r4, r5
	cmp	r1, r3
	blo	.L0809EA74
	mov	r0, r4
	pop	{r4, r5, r6, r7, r8, sb}
	bx	lr

@ ======================================================================================
@ armEcho   (0809EAB4)
@
@   /* ARM, runs from IWRAM.  dry += wet; wet = wet >> shift (rounding towards zero). */
@   void armEcho(s16 *dry, s16 *wet, const s16 *dryEnd, u32 shift)
@   {
@       do { s16 w = *wet; *dry++ += w; *wet++ = (w < 0 ? w + (1 << shift) - 1 : w) >> shift; }
@       while (dry < dryEnd);          /* unrolled x4 */
@   }
@
@   In this build: /* dry += wet; wet = (wet + 2^(shift-1)) >> shift  (rounded to nearest).  With the default
@      shift of 31 the result is always 0 or -1. */
@   void armEcho(s16 *dry, s16 *wet, const s16 *dryEnd, u32 shift)
@   {
@       s32 round = 1 << (shift - 1);
@       do { s16 w = *wet; *dry++ += w; *wet++ = (w + round) >> shift; } while (dry < dryEnd);
@   }
@ ======================================================================================
	.global armEcho
	.type armEcho, %function
armEcho:
	push	{r4, r5}
	mov	r4, #1
	sub	ip, r3, #1
	lsl	r4, r4, ip
.L0809EAC4:
	ldrsh	r5, [r0]
	ldrsh	ip, [r1]
	add	r5, r5, ip
	strh	r5, [r0], #2
	add	ip, ip, r4
	asr	ip, ip, r3
	strh	ip, [r1], #2
	ldrsh	r5, [r0]
	ldrsh	ip, [r1]
	add	r5, r5, ip
	strh	r5, [r0], #2
	add	ip, ip, r4
	asr	ip, ip, r3
	strh	ip, [r1], #2
	ldrsh	r5, [r0]
	ldrsh	ip, [r1]
	add	r5, r5, ip
	strh	r5, [r0], #2
	add	ip, ip, r4
	asr	ip, ip, r3
	strh	ip, [r1], #2
	ldrsh	r5, [r0]
	ldrsh	ip, [r1]
	add	r5, r5, ip
	strh	r5, [r0], #2
	add	ip, ip, r4
	asr	ip, ip, r3
	strh	ip, [r1], #2
	ldrsh	r5, [r0]
	ldrsh	ip, [r1]
	add	r5, r5, ip
	strh	r5, [r0], #2
	add	ip, ip, r4
	asr	ip, ip, r3
	strh	ip, [r1], #2
	ldrsh	r5, [r0]
	ldrsh	ip, [r1]
	add	r5, r5, ip
	strh	r5, [r0], #2
	add	ip, ip, r4
	asr	ip, ip, r3
	strh	ip, [r1], #2
	ldrsh	r5, [r0]
	ldrsh	ip, [r1]
	add	r5, r5, ip
	strh	r5, [r0], #2
	add	ip, ip, r4
	asr	ip, ip, r3
	strh	ip, [r1], #2
	ldrsh	r5, [r0]
	ldrsh	ip, [r1]
	add	r5, r5, ip
	strh	r5, [r0], #2
	add	ip, ip, r4
	asr	ip, ip, r3
	strh	ip, [r1], #2
	cmp	r0, r2
	blo	.L0809EAC4
	pop	{r4, r5}
	bx	lr
