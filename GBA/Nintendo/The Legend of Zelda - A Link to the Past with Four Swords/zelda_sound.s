@ --------------------------------------------------------------------------------------
@ zelda_sound.s - sound driver of A Link to the Past & Four Swords (E), ALttP program
@ Thumb code 0812B714-0812DCA0, ARM mixing loops 0812DCA0-0812DF58 (copied to IWRAM by sndInit).
@ Generated from the ROM by gen_sources.py; names and comments from the analysis.
@ The pseudo-C above each function describes the Super Mario Advance 4 build; where this
@ build differs, the difference is given after "In this build".
@ Rebuilds byte-identical: see Makefile.
@ --------------------------------------------------------------------------------------
	.syntax unified
	.include "nsnd.inc"
	.include "zelda_ram.inc"
	.section .snd_code, "ax"
	.thumb

@ ======================================================================================
@ sndInit   (0812B714)
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
	ldr	r1, .P0812B7A0	@ =gCfg
	str	r0, [r1]
	ldr	r1, .P0812B7A4	@ =REG_SOUNDCNT_X
	movs	r0, #0
	strb	r0, [r1]
	movs	r0, #0x80
	strb	r0, [r1]
	subs	r1, #4
	ldr	r2, .P0812B7A8	@ =0x0000FF77
	adds	r0, r2, #0
	strh	r0, [r1]
	adds	r1, #2
	movs	r0, #0xd
	strb	r0, [r1]
	ldr	r2, .P0812B7AC	@ =REG_SOUNDBIAS
	ldrh	r1, [r2]
	ldr	r0, .P0812B7B0	@ =0x00003FFF
	ands	r0, r1
	movs	r3, #0x80
	lsls	r3, r3, #7
	adds	r1, r3, #0
	orrs	r0, r1
	strh	r0, [r2]
	ldr	r1, .P0812B7B4	@ =REG_NR10
	movs	r0, #8
	strh	r0, [r1]
	adds	r1, #2
	movs	r2, #0xf0
	lsls	r2, r2, #8
	adds	r0, r2, #0
	strh	r0, [r1]
	ldr	r5, .P0812B7B8	@ =armDownmix
	ldr	r4, .P0812B7BC	@ =gIwramCode
	adds	r0, r5, #0
	adds	r1, r4, #0
	movs	r2, #0xd8
	bl	CpuFastSet
	ldr	r0, .P0812B7C0	@ =gFnDownmix
	str	r4, [r0]
	ldr	r1, .P0812B7C4	@ =gFnMixVoice
	ldr	r0, .P0812B7C8	@ =armMixVoice
	subs	r0, r0, r5
	adds	r0, r0, r4
	str	r0, [r1]
	ldr	r1, .P0812B7CC	@ =gFnEcho
	ldr	r0, .P0812B7D0	@ =armEcho
	subs	r0, r0, r5
	adds	r0, r0, r4
	str	r0, [r1]
	ldr	r1, .P0812B7D4	@ =gEchoHistory
	ldr	r0, .P0812B7D8	@ =0x02036000
	str	r0, [r1]
	ldr	r0, .P0812B7DC	@ =gDmaBuffers
	bl	mixInit
	bl	cmdInit
	bl	kitInstInit
	bl	voiceInitAll
	bl	trackInitAll
	bl	playerInitAll
	pop	{r4, r5}
	pop	{r0}
	bx	r0
.P0812B7A0:	.word gCfg
.P0812B7A4:	.word REG_SOUNDCNT_X
.P0812B7A8:	.word 0x0000FF77
.P0812B7AC:	.word REG_SOUNDBIAS
.P0812B7B0:	.word 0x00003FFF
.P0812B7B4:	.word REG_NR10
.P0812B7B8:	.word armDownmix
.P0812B7BC:	.word gIwramCode
.P0812B7C0:	.word gFnDownmix
.P0812B7C4:	.word gFnMixVoice
.P0812B7C8:	.word armMixVoice
.P0812B7CC:	.word gFnEcho
.P0812B7D0:	.word armEcho
.P0812B7D4:	.word gEchoHistory
.P0812B7D8:	.word 0x02036000
.P0812B7DC:	.word gDmaBuffers

@ ======================================================================================
@ sndVSync   (0812B7E0)
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
@ sndMain   (0812B7EC)
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
	ldr	r0, .P0812B80C	@ =gMixEnabled
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L0812B806
	bl	mixFrame
.L0812B806:
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0812B80C:	.word gMixEnabled

@ ======================================================================================
@ mixInit   (0812B810)
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
	ldr	r1, .P0812B878	@ =gMixEnabled
	movs	r0, #1
	strb	r0, [r1]
	movs	r5, #0
	str	r5, [sp, #4]
	add	r0, sp, #4
	ldr	r1, .P0812B87C	@ =gEchoHistory
	ldr	r1, [r1]
	ldr	r2, .P0812B880	@ =0x01000C60
	bl	CpuFastSet
	str	r5, [sp, #8]
	add	r0, sp, #8
	ldr	r2, .P0812B884	@ =0x010000B0
	adds	r1, r4, #0
	bl	CpuFastSet
	ldr	r1, .P0812B888	@ =gDmaBufA
	str	r4, [r1]
	ldr	r2, .P0812B88C	@ =gDmaBufB
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
	ldr	r1, .P0812B890	@ =gTimerReload
	ldr	r2, .P0812B894	@ =0x0000F9C4
	adds	r0, r2, #0
	strh	r0, [r1]
	ldr	r0, .P0812B898	@ =gDmaBufIdx
	strb	r5, [r0]
	ldr	r1, .P0812B89C	@ =REG_SOUNDCNT_H+1
	movs	r0, #0x9a
	strb	r0, [r1]
	ldr	r0, .P0812B8A0	@ =REG_FIFO_A
	str	r5, [r0]
	adds	r0, #4
	str	r5, [r0]
	add	sp, #0xc
	pop	{r4, r5}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0812B878:	.word gMixEnabled
.P0812B87C:	.word gEchoHistory
.P0812B880:	.word 0x01000C60
.P0812B884:	.word 0x010000B0
.P0812B888:	.word gDmaBufA
.P0812B88C:	.word gDmaBufB
.P0812B890:	.word gTimerReload
.P0812B894:	.word 0x0000F9C4
.P0812B898:	.word gDmaBufIdx
.P0812B89C:	.word REG_SOUNDCNT_H+1
.P0812B8A0:	.word REG_FIFO_A

@ ======================================================================================
@ mixDmaRestart   (0812B8A4)
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
	ldr	r2, .P0812B920	@ =REG_TM0CNT
	ldr	r0, .P0812B924	@ =gTimerReload
	ldrh	r0, [r0]
	movs	r1, #0x80
	lsls	r1, r1, #0x10
	orrs	r0, r1
	str	r0, [r2]
	ldr	r0, .P0812B928	@ =gMixEnabled
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L0812B918
	ldr	r4, .P0812B92C	@ =REG_DMA1SAD
	ldrh	r1, [r4, #0xa]
	ldr	r2, .P0812B930	@ =0x0000C5FF
	adds	r0, r2, #0
	ands	r0, r1
	strh	r0, [r4, #0xa]
	ldrh	r3, [r4, #0xa]
	ldr	r1, .P0812B934	@ =0x00007FFF
	adds	r0, r1, #0
	ands	r0, r3
	strh	r0, [r4, #0xa]
	ldrh	r0, [r4, #0xa]
	ldr	r3, .P0812B938	@ =REG_DMA2SAD
	ldrh	r0, [r3, #0xa]
	ands	r2, r0
	strh	r2, [r3, #0xa]
	ldrh	r0, [r3, #0xa]
	ands	r1, r0
	strh	r1, [r3, #0xa]
	ldrh	r0, [r3, #0xa]
	ldr	r1, .P0812B93C	@ =gDmaBufA
	ldr	r2, .P0812B940	@ =gDmaBufIdx
	ldrb	r0, [r2]
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r0, [r0]
	str	r0, [r4]
	ldr	r0, .P0812B944	@ =REG_FIFO_A
	str	r0, [r4, #4]
	ldr	r5, .P0812B948	@ =0xB6400004
	str	r5, [r4, #8]
	ldr	r0, [r4, #8]
	ldr	r1, .P0812B94C	@ =gDmaBufB
	ldrb	r0, [r2]
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r0, [r0]
	str	r0, [r3]
	ldr	r0, .P0812B950	@ =REG_FIFO_B
	str	r0, [r3, #4]
	str	r5, [r3, #8]
	ldr	r0, [r3, #8]
	ldrb	r1, [r2]
	movs	r0, #1
	subs	r0, r0, r1
	strb	r0, [r2]
.L0812B918:
	pop	{r4, r5}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0812B920:	.word REG_TM0CNT
.P0812B924:	.word gTimerReload
.P0812B928:	.word gMixEnabled
.P0812B92C:	.word REG_DMA1SAD
.P0812B930:	.word 0x0000C5FF
.P0812B934:	.word 0x00007FFF
.P0812B938:	.word REG_DMA2SAD
.P0812B93C:	.word gDmaBufA
.P0812B940:	.word gDmaBufIdx
.P0812B944:	.word REG_FIFO_A
.P0812B948:	.word 0xB6400004
.P0812B94C:	.word gDmaBufB
.P0812B950:	.word REG_FIFO_B

@ ======================================================================================
@ sndStopOutput   (0812B954)
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
	ldr	r1, .P0812B98C	@ =gMixEnabled
	movs	r0, #0
	strb	r0, [r1]
	ldr	r1, .P0812B990	@ =REG_DMA1SAD
	ldrh	r2, [r1, #0xa]
	ldr	r3, .P0812B994	@ =0x0000C5FF
	adds	r0, r3, #0
	ands	r0, r2
	strh	r0, [r1, #0xa]
	ldrh	r4, [r1, #0xa]
	ldr	r2, .P0812B998	@ =0x00007FFF
	adds	r0, r2, #0
	ands	r0, r4
	strh	r0, [r1, #0xa]
	ldrh	r0, [r1, #0xa]
	ldr	r0, .P0812B99C	@ =REG_DMA2SAD
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
.P0812B98C:	.word gMixEnabled
.P0812B990:	.word REG_DMA1SAD
.P0812B994:	.word 0x0000C5FF
.P0812B998:	.word 0x00007FFF
.P0812B99C:	.word REG_DMA2SAD

@ ======================================================================================
@ sndStartOutput   (0812B9A0)
@
@   void sndStartOutput(void)
@   {
@       gMixEnabled = 1;        /* DMA restarts at the next sndVSync */
@   }
@ ======================================================================================
	.global sndStartOutput
	.thumb_func
sndStartOutput:
	ldr	r1, .P0812B9A8	@ =gMixEnabled
	movs	r0, #1
	strb	r0, [r1]
	bx	lr
.P0812B9A8:	.word gMixEnabled

@ ======================================================================================
@ mixVoice   (0812B9AC)
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
	ldr	r2, .P0812BA34	@ =gMixDry
	str	r2, [sp, #0x14]
	ldr	r0, .P0812BA38	@ =gEchoShift
	ldrb	r0, [r0]
	cmp	r0, #0xf
	bhi	.L0812B9F2
	ldrb	r0, [r1, #0x1a]
	cmp	r0, #0
	beq	.L0812B9F2
	ldr	r0, .P0812BA3C	@ =gMixWet
	str	r0, [sp, #0x14]
.L0812B9F2:
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
	bne	.L0812BA20
	ldr	r7, [r0]
.L0812BA20:
	ldr	r1, [sp, #0x1c]
	adds	r0, r6, #0
	muls	r0, r1, r0
	adds	r0, r4, r0
	lsrs	r0, r0, #8
	cmp	r0, r7
	bhs	.L0812BA40
	mov	r5, r8
	b	.L0812BA58
	.hword 0x0000
.P0812BA34:	.word gMixDry
.P0812BA38:	.word gEchoShift
.P0812BA3C:	.word gMixWet
.L0812BA40:
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
.L0812BA58:
	ldr	r1, [sp, #0x10]
	ldr	r0, [r1, #0x5c]
	ldr	r1, [r0, #0xc]
	cmp	r1, #0
	beq	.L0812BA68
	mov	r2, sb
	cmp	r2, #0
	bne	.L0812BA94
.L0812BA68:
	ldr	r0, .P0812BA90	@ =gFnMixVoice
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
	beq	.L0812BB42
	movs	r0, #1
	b	.L0812BB48
.P0812BA90:	.word gFnMixVoice
.L0812BA94:
	ldr	r0, [r0, #8]
	subs	r1, r1, r0
	lsls	r1, r1, #8
	str	r1, [sp, #0x24]
	ldr	r1, .P0812BAF0	@ =gFnMixVoice
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
	beq	.L0812BB42
.L0812BACE:
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
	bhs	.L0812BAF4
	lsls	r0, r1, #1
	adds	r5, r5, r0
	movs	r2, #0
	mov	sb, r2
	b	.L0812BB0A
.P0812BAF0:	.word gFnMixVoice
.L0812BAF4:
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
.L0812BB0A:
	str	r4, [sp]
	str	r6, [sp, #4]
	ldr	r1, [sp, #0x18]
	str	r1, [sp, #8]
	mov	r2, sl
	str	r2, [sp, #0xc]
	ldr	r0, .P0812BB58	@ =gFnMixVoice
	ldr	r4, [r0]
	ldr	r0, [sp, #0x20]
	ldr	r1, [sp, #0x14]
	mov	r2, r8
	adds	r3, r5, #0
	bl	_call_via_r4
	adds	r4, r0, #0
	mov	r1, sb
	cmp	r1, #0
	beq	.L0812BB32
	ldr	r2, [sp, #0x24]
	subs	r4, r4, r2
.L0812BB32:
	ldr	r1, [sp, #0x14]
	subs	r0, r5, r1
	asrs	r0, r0, #1
	ldr	r2, [sp, #0x1c]
	subs	r2, r2, r0
	str	r2, [sp, #0x1c]
	cmp	r2, #0
	bne	.L0812BACE
.L0812BB42:
	ldr	r0, [sp, #0x10]
	str	r4, [r0, #0x60]
	movs	r0, #0
.L0812BB48:
	add	sp, #0x28
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	sb, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1
.P0812BB58:	.word gFnMixVoice

@ ======================================================================================
@ kitInstInit   (0812BB5C)
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
	ldr	r1, .P0812BB74	@ =gKitInst
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
.P0812BB74:	.word gKitInst

@ ======================================================================================
@ instLookup   (0812BB78)
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
	ldr	r1, .P0812BBE0	@ =gCfg
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
	beq	.L0812BC28
	adds	r0, r1, #0
	cmp	r0, #0x10
	bne	.L0812BBE4
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
	b	.L0812BC2C
.P0812BBE0:	.word gCfg
.L0812BBE4:
	cmp	r0, #0x11
	bne	.L0812BC0C
	ldrh	r1, [r5, #2]
	adds	r1, r3, r1
	ldr	r2, .P0812BC04	@ =gKitInst
	lsls	r0, r6, #1
	adds	r0, r0, r1
	ldrh	r0, [r0]
	strh	r0, [r2, #2]
	str	r2, [r4]
	ldr	r0, .P0812BC08	@ =kFlatEnvelope
	str	r0, [r4, #4]
	movs	r0, #1
	strb	r0, [r4, #0x12]
	b	.L0812BC30
	.hword 0x0000
.P0812BC04:	.word gKitInst
.P0812BC08:	.word kFlatEnvelope
.L0812BC0C:
	cmp	r0, #0x12
	bne	.L0812BC30
	ldrh	r0, [r5, #2]
	adds	r0, r3, r0
	b	.L0812BC18
.L0812BC16:
	adds	r0, #4
.L0812BC18:
	ldrb	r1, [r0]
	cmp	r6, r1
	bhi	.L0812BC16
	ldrh	r0, [r0, #2]
	adds	r0, r3, r0
	str	r0, [r4]
	ldrh	r0, [r0, #4]
	b	.L0812BC2C
.L0812BC28:
	str	r5, [r4]
	ldrh	r0, [r5, #4]
.L0812BC2C:
	adds	r0, r3, r0
	str	r0, [r4, #4]
.L0812BC30:
	ldr	r2, [r4]
	ldrb	r0, [r2]
	cmp	r0, #3
	bne	.L0812BC3E
	ldrh	r0, [r5, #2]
	adds	r0, r3, r0
	str	r0, [r4, #0xc]
.L0812BC3E:
	ldrb	r1, [r2, #1]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0812BC4E
	ldrh	r0, [r2, #2]
	adds	r0, r3, r0
	str	r0, [r4, #8]
.L0812BC4E:
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ voiceInitAll   (0812BC54)
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
	ldr	r1, .P0812BDC0	@ =gLastWave
	movs	r0, #0
	str	r0, [r1]
	ldr	r2, .P0812BDC4	@ =gPsgVoices
	ldr	r0, .P0812BDC8	@ =gDsVoices
	mov	ip, r0
	ldr	r3, .P0812BDCC	@ =gVoiceCount
	ldr	r5, .P0812BDD0	@ =gFreeVoices
	ldr	r1, .P0812BDD4	@ =gActiveVoices
	mov	r8, r1
	ldr	r0, .P0812BDD8	@ =gReservedVoices
	mov	sb, r0
	ldr	r1, .P0812BDDC	@ =gEchoPos
	mov	sl, r1
	movs	r1, #0
	adds	r0, r2, #1
	movs	r4, #3
.L0812BC80:
	strb	r1, [r0]
	strb	r1, [r0, #3]
	strb	r1, [r0, #4]
	strb	r1, [r0, #5]
	strb	r1, [r0, #6]
	adds	r0, #0x78
	subs	r4, #1
	cmp	r4, #0
	bge	.L0812BC80
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
	ldr	r0, .P0812BDC8	@ =gDsVoices
	movs	r4, #6
.L0812BCB4:
	strb	r1, [r0, #1]
	strb	r1, [r0]
	strb	r1, [r0, #4]
	strb	r1, [r0, #5]
	strb	r1, [r0, #6]
	strb	r1, [r0, #7]
	adds	r0, #0x78
	subs	r4, #1
	cmp	r4, #0
	bge	.L0812BCB4
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
.L0812BD10:
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
	bge	.L0812BD10
	movs	r3, #0
	movs	r1, #0x96
	lsls	r1, r1, #2
	add	r1, ip
	movs	r0, #0xce
	lsls	r0, r0, #2
	add	r0, ip
	strb	r1, [r0]
	lsrs	r2, r1, #8
	ldr	r0, .P0812BDE0	@ =0x00000339
	add	r0, ip
	strb	r2, [r0]
	lsrs	r2, r1, #0x10
	ldr	r0, .P0812BDE4	@ =0x0000033A
	add	r0, ip
	strb	r2, [r0]
	lsrs	r1, r1, #0x18
	ldr	r0, .P0812BDE8	@ =0x0000033B
	add	r0, ip
	strb	r1, [r0]
	movs	r0, #0xcf
	lsls	r0, r0, #2
	add	r0, ip
	strb	r3, [r0]
	ldr	r0, .P0812BDEC	@ =0x0000033D
	add	r0, ip
	strb	r3, [r0]
	ldr	r0, .P0812BDF0	@ =0x0000033E
	add	r0, ip
	strb	r3, [r0]
	ldr	r0, .P0812BDF4	@ =0x0000033F
	add	r0, ip
	strb	r3, [r0]
	mov	r1, r8
	str	r3, [r1]
	mov	r0, sb
	str	r3, [r0]
	mov	r1, sl
	strb	r3, [r1]
	movs	r0, #0x12
	ldr	r1, .P0812BDF8	@ =gEchoLen
	strb	r0, [r1]
	movs	r0, #0x10
	ldr	r1, .P0812BDFC	@ =gEchoShift
	strb	r0, [r1]
	ldr	r1, .P0812BE00	@ =gEchoShiftTarget
	strb	r0, [r1]
	ldr	r0, .P0812BE04	@ =gEchoTail
	strb	r3, [r0]
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	sb, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0812BDC0:	.word gLastWave
.P0812BDC4:	.word gPsgVoices
.P0812BDC8:	.word gDsVoices
.P0812BDCC:	.word gVoiceCount
.P0812BDD0:	.word gFreeVoices
.P0812BDD4:	.word gActiveVoices
.P0812BDD8:	.word gReservedVoices
.P0812BDDC:	.word gEchoPos
.P0812BDE0:	.word 0x00000339
.P0812BDE4:	.word 0x0000033A
.P0812BDE8:	.word 0x0000033B
.P0812BDEC:	.word 0x0000033D
.P0812BDF0:	.word 0x0000033E
.P0812BDF4:	.word 0x0000033F
.P0812BDF8:	.word gEchoLen
.P0812BDFC:	.word gEchoShift
.P0812BE00:	.word gEchoShiftTarget
.P0812BE04:	.word gEchoTail

@ ======================================================================================
@ voiceListRemove   (0812BE08)
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
	beq	.L0812BE16
	str	r0, [r2, #0x6c]
	b	.L0812BE18
.L0812BE16:
	str	r0, [r1]
.L0812BE18:
	cmp	r0, #0
	beq	.L0812BE1E
	str	r2, [r0, #0x68]
.L0812BE1E:
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ voiceListPush   (0812BE24)
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
	beq	.L0812BE36
	str	r3, [r2, #0x68]
.L0812BE36:
	str	r3, [r1]
	pop	{r0}
	bx	r0

@ ======================================================================================
@ voiceListInsertActive   (0812BE3C)
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
	ldr	r0, .P0812BE78	@ =gActiveVoices
	ldr	r1, [r0]
	ldrb	r2, [r3, #1]
	adds	r5, r0, #0
	cmp	r2, #1
	bne	.L0812BE7C
	cmp	r1, #0
	beq	.L0812BEA8
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	bne	.L0812BE60
	ldrb	r0, [r3, #8]
	ldrb	r2, [r1, #8]
	cmp	r0, r2
	blo	.L0812BEA8
.L0812BE60:
	adds	r4, r1, #0
	ldr	r1, [r4, #0x6c]
	cmp	r1, #0
	beq	.L0812BEA8
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	bne	.L0812BE60
	ldrb	r0, [r3, #8]
	ldrb	r2, [r1, #8]
	cmp	r0, r2
	bhs	.L0812BE60
	b	.L0812BEA8
.P0812BE78:	.word gActiveVoices
.L0812BE7C:
	cmp	r2, #2
	bne	.L0812BEBC
	cmp	r1, #0
	beq	.L0812BEA8
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	beq	.L0812BEA8
	ldrb	r0, [r3, #8]
	ldrb	r2, [r1, #8]
	cmp	r0, r2
	blo	.L0812BEA8
	adds	r2, r0, #0
.L0812BE94:
	adds	r4, r1, #0
	ldr	r1, [r4, #0x6c]
	cmp	r1, #0
	beq	.L0812BEA8
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	beq	.L0812BEA8
	ldrb	r0, [r1, #8]
	cmp	r2, r0
	bhs	.L0812BE94
.L0812BEA8:
	str	r1, [r3, #0x6c]
	cmp	r1, #0
	beq	.L0812BEB0
	str	r3, [r1, #0x68]
.L0812BEB0:
	str	r4, [r3, #0x68]
	cmp	r4, #0
	beq	.L0812BEBA
	str	r3, [r4, #0x6c]
	b	.L0812BEBC
.L0812BEBA:
	str	r3, [r5]
.L0812BEBC:
	pop	{r4, r5}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ keyToFreq   (0812BEC4)
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
	bge	.L0812BEE0
	movs	r2, #0
	b	.L0812BEE6
.L0812BEE0:
	cmp	r1, #0x77
	ble	.L0812BEE6
	movs	r2, #0x78
.L0812BEE6:
	ldrb	r0, [r0]
	cmp	r0, #0
	bne	.L0812BEFC
	ldr	r0, .P0812BEF8	@ =kDsPitch
	lsls	r1, r2, #0x10
	asrs	r1, r1, #0xe
	adds	r1, r1, r0
	ldr	r0, [r1]
	b	.L0812BF14
.P0812BEF8:	.word kDsPitch
.L0812BEFC:
	cmp	r0, #4
	beq	.L0812BF10
	ldr	r0, .P0812BF0C	@ =kPsgFreq
	lsls	r1, r2, #0x10
	asrs	r1, r1, #0xf
	adds	r1, r1, r0
	ldrh	r0, [r1]
	b	.L0812BF14
.P0812BF0C:	.word kPsgFreq
.L0812BF10:
	lsls	r0, r2, #0x10
	asrs	r0, r0, #0x10
.L0812BF14:
	pop	{r1}
	bx	r1

@ ======================================================================================
@ noiseDivider   (0812BF18)
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
	bls	.L0812BF24
	movs	r1, #0x77
.L0812BF24:
	ldr	r0, .P0812BF30	@ =kNoiseTable
	adds	r0, r1, r0
	ldrb	r0, [r0]
	pop	{r1}
	bx	r1
	.hword 0x0000
.P0812BF30:	.word kNoiseTable

@ ======================================================================================
@ envStep   (0812BF34)
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
	bne	.L0812BF8E
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
	bge	.L0812BF60
	strb	r1, [r4, #0x10]
.L0812BF60:
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
.L0812BF8E:
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
@ echoSetFeedback   (0812BFA4)
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
	ldr	r1, .P0812BFB0	@ =gEchoShiftTarget
	strb	r0, [r1]
	bx	lr
	.hword 0x0000
.P0812BFB0:	.word gEchoShiftTarget

@ ======================================================================================
@ voiceSetCount   (0812BFB4)
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
	ldr	r2, .P0812C008	@ =gVoiceCount
	ldrb	r1, [r2]
	subs	r0, r0, r1
	lsls	r0, r0, #0x18
	lsrs	r5, r0, #0x18
	asrs	r0, r0, #0x18
	cmp	r0, #0
	beq	.L0812C054
	cmp	r0, #0
	ble	.L0812C014
	ldr	r0, .P0812C00C	@ =gReservedVoices
	ldr	r6, [r0]
	cmp	r6, #0
	beq	.L0812C054
	adds	r7, r2, #0
.L0812BFD8:
	adds	r4, r6, #0
	ldr	r6, [r4, #0x6c]
	adds	r0, r4, #0
	ldr	r1, .P0812C00C	@ =gReservedVoices
	bl	voiceListRemove
	adds	r0, r4, #0
	ldr	r1, .P0812C010	@ =gFreeVoices
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
	beq	.L0812C054
	lsls	r0, r5, #0x18
	cmp	r0, #0
	bgt	.L0812BFD8
	b	.L0812C054
.P0812C008:	.word gVoiceCount
.P0812C00C:	.word gReservedVoices
.P0812C010:	.word gFreeVoices
.L0812C014:
	rsbs	r0, r0, #0
	lsls	r0, r0, #0x18
	lsrs	r5, r0, #0x18
	adds	r6, r2, #0
	b	.L0812C03E
.L0812C01E:
	adds	r0, r4, #0
	ldr	r1, .P0812C05C	@ =gActiveVoices
	bl	voiceListRemove
	movs	r0, #0
	strb	r0, [r4, #1]
	adds	r0, r4, #0
	ldr	r1, .P0812C060	@ =gReservedVoices
	bl	voiceListPush
	subs	r0, r5, #1
	lsls	r0, r0, #0x18
	lsrs	r5, r0, #0x18
	ldrb	r0, [r6]
	subs	r0, #1
	strb	r0, [r6]
.L0812C03E:
	lsls	r0, r5, #0x18
	asrs	r5, r0, #0x18
	cmp	r5, #0
	ble	.L0812C054
	movs	r0, #0
	movs	r1, #0xff
	bl	voiceAlloc
	adds	r4, r0, #0
	cmp	r4, #0
	bne	.L0812C01E
.L0812C054:
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0812C05C:	.word gActiveVoices
.P0812C060:	.word gReservedVoices

@ ======================================================================================
@ dsVolume   (0812C064)
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
@   In this build: Same, but returns v->volume * 3 >> 9 instead of v->volume >> 8: every sampled voice is 25 %
@   quieter than in SMA3 and SMA4.
@ ======================================================================================
	.global dsVolume
	.thumb_func
dsVolume:
	push	{r4, r5, lr}
	adds	r5, r0, #0
	ldrb	r0, [r5, #1]
	cmp	r0, #1
	bne	.L0812C0AE
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
	b	.L0812C0C0
.L0812C0AE:
	adds	r0, r5, #0
	adds	r0, #0x58
	ldrb	r0, [r0]
	adds	r0, #0xe6
	ldr	r1, [r5, #0x14]
	muls	r0, r1, r0
	lsrs	r0, r0, #9
	str	r0, [r5, #0x14]
	adds	r4, r0, #0
.L0812C0C0:
	lsls	r0, r4, #1
	adds	r4, r0, r4
	lsrs	r4, r4, #9
	adds	r0, r4, #0
	pop	{r4, r5}
	pop	{r1}
	bx	r1
	movs	r0, r0

@ ======================================================================================
@ psgEnvelope   (0812C0D0)
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
	bne	.L0812C0EE
	movs	r6, #1
.L0812C0EE:
	adds	r0, r5, #0
	bl	envStep
	cmp	r6, #0
	bne	.L0812C0FC
	movs	r0, #8
	b	.L0812C1CC
.L0812C0FC:
	cmp	r7, #0
	beq	.L0812C102
	lsls	r4, r4, #1
.L0812C102:
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
	bne	.L0812C150
	lsrs	r4, r4, #0x16
	str	r4, [r5, #0x14]
	lsls	r0, r4, #2
	adds	r4, r0, r4
	lsrs	r4, r4, #7
	cmp	r4, #4
	bls	.L0812C14A
	movs	r4, #4
.L0812C14A:
	lsls	r0, r4, #0x18
	lsrs	r0, r0, #0x18
	b	.L0812C1CC
.L0812C150:
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
	beq	.L0812C168
	movs	r4, #0xf
.L0812C168:
	ldr	r1, [r5, #0x14]
	ldr	r0, [r5, #0x44]
	muls	r0, r1, r0
	lsrs	r0, r0, #0x19
	str	r0, [r5, #0x14]
	ands	r0, r2
	cmp	r0, #0
	beq	.L0812C17C
	movs	r0, #0xf
	str	r0, [r5, #0x14]
.L0812C17C:
	ldr	r5, [r5, #0x14]
	cmp	r5, r4
	beq	.L0812C1A4
	mov	r1, r8
	ldrh	r2, [r1]
	adds	r0, r2, #0
	adds	r0, #0xf
	lsls	r0, r0, #0x10
	lsrs	r2, r0, #0x10
	subs	r1, r5, r4
	cmp	r1, #0
	bge	.L0812C196
	rsbs	r1, r1, #0
.L0812C196:
	adds	r0, r2, #0
	bl	__divsi3
	lsls	r0, r0, #0x10
	lsrs	r2, r0, #0x10
	cmp	r2, #0
	bne	.L0812C1B0
.L0812C1A4:
	lsls	r0, r4, #4
	movs	r1, #8
	orrs	r0, r1
	lsls	r0, r0, #0x18
	lsrs	r6, r0, #0x18
	b	.L0812C1CA
.L0812C1B0:
	ldr	r0, .P0812C1D8	@ =0x0000FFF8
	ands	r0, r2
	cmp	r0, #0
	beq	.L0812C1BA
	movs	r2, #7
.L0812C1BA:
	lsls	r0, r4, #4
	orrs	r0, r2
	lsls	r0, r0, #0x18
	lsrs	r6, r0, #0x18
	cmp	r4, r5
	bhs	.L0812C1CA
	movs	r0, #8
	orrs	r6, r0
.L0812C1CA:
	adds	r0, r6, #0
.L0812C1CC:
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1
	.hword 0x0000
.P0812C1D8:	.word 0x0000FFF8

@ ======================================================================================
@ voicePitch   (0812C1DC)
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
	beq	.L0812C1F4
	subs	r0, #1
	str	r0, [r5, #0x2c]
	b	.L0812C20E
.L0812C1F4:
	ldr	r4, [r3, #4]
	cmp	r4, #0
	beq	.L0812C20E
	ldr	r0, [r3, #8]
	ldr	r1, [r3, #0x10]
	adds	r0, r0, r1
	str	r0, [r3, #8]
	subs	r0, r4, #1
	str	r0, [r3, #4]
	cmp	r0, #0
	bne	.L0812C20E
	ldr	r0, [r3, #0xc]
	str	r0, [r3, #8]
.L0812C20E:
	ldr	r0, [r3, #8]
	adds	r2, r2, r0
	adds	r0, r6, #0
	adds	r0, #0x4f
	movs	r1, #0
	ldrsb	r1, [r0, r1]
	cmp	r1, #0
	beq	.L0812C2BA
	cmp	r1, #0
	ble	.L0812C262
	adds	r3, r1, #0
	ldr	r1, .P0812C248	@ =kDsPitch
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
	bne	.L0812C24C
	lsrs	r3, r3, #7
	muls	r2, r3, r2
	lsrs	r2, r2, #0xf
	b	.L0812C2BA
.P0812C248:	.word kDsPitch
.L0812C24C:
	movs	r4, #0x80
	lsls	r4, r4, #4
	subs	r2, r4, r2
	lsls	r2, r2, #0x16
	adds	r0, r2, #0
	adds	r1, r3, #0
	bl	__udivsi3
	adds	r2, r0, #0
	subs	r2, r4, r2
	b	.L0812C2BA
.L0812C262:
	ldrb	r0, [r0]
	lsls	r0, r0, #0x18
	asrs	r0, r0, #0x18
	rsbs	r3, r0, #0
	ldr	r1, .P0812C298	@ =kDsPitch
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
	bne	.L0812C29C
	lsls	r2, r2, #0xf
	lsrs	r3, r3, #7
	adds	r0, r2, #0
	adds	r1, r3, #0
	bl	__udivsi3
	adds	r2, r0, #0
	b	.L0812C2BA
.P0812C298:	.word kDsPitch
.L0812C29C:
	movs	r1, #0x80
	lsls	r1, r1, #4
	subs	r2, r1, r2
	lsrs	r3, r3, #7
	muls	r2, r3, r2
	lsrs	r2, r2, #0xf
	ldr	r0, .P0812C2B4	@ =0x000007FF
	cmp	r2, r0
	bhi	.L0812C2B8
	subs	r2, r1, r2
	b	.L0812C2BA
	.hword 0x0000
.P0812C2B4:	.word 0x000007FF
.L0812C2B8:
	movs	r2, #0
.L0812C2BA:
	adds	r4, r5, #0
	adds	r4, #0x20
	ldr	r0, [r4, #8]
	ldr	r3, [r0, #8]
	cmp	r3, #0
	beq	.L0812C368
	ldr	r0, [r4, #4]
	cmp	r0, #0
	bne	.L0812C364
	ldr	r0, .P0812C2F0	@ =kLfoSine
	ldr	r1, [r5, #0x20]
	lsrs	r1, r1, #1
	adds	r1, r1, r0
	ldrb	r1, [r1]
	ldrb	r0, [r5]
	cmp	r0, #0
	bne	.L0812C310
	lsls	r0, r1, #0x18
	asrs	r0, r0, #0x18
	cmp	r0, #0
	blt	.L0812C2F4
	muls	r0, r2, r0
	muls	r0, r3, r0
	lsrs	r0, r0, #0x13
	adds	r2, r2, r0
	b	.L0812C348
	.hword 0x0000
.P0812C2F0:	.word kLfoSine
.L0812C2F4:
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
	b	.L0812C348
.L0812C310:
	lsls	r0, r1, #0x18
	asrs	r1, r0, #0x18
	cmp	r1, #0
	blt	.L0812C32E
	movs	r0, #0x80
	lsls	r0, r0, #4
	subs	r0, r0, r2
	lsls	r0, r0, #0x13
	muls	r1, r3, r1
	movs	r2, #0x80
	lsls	r2, r2, #0xc
	adds	r1, r1, r2
	bl	__udivsi3
	b	.L0812C342
.L0812C32E:
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
.L0812C342:
	movs	r2, #0x80
	lsls	r2, r2, #4
	subs	r2, r2, r0
.L0812C348:
	ldr	r0, [r4, #8]
	ldr	r1, [r4]
	ldr	r0, [r0, #4]
	adds	r1, r1, r0
	str	r1, [r4]
	lsrs	r0, r1, #1
	cmp	r0, #0xff
	bls	.L0812C368
	ldr	r3, .P0812C360	@ =0xFFFFFE00
	adds	r0, r1, r3
	str	r0, [r4]
	b	.L0812C368
.P0812C360:	.word 0xFFFFFE00
.L0812C364:
	subs	r0, #1
	str	r0, [r4, #4]
.L0812C368:
	adds	r0, r2, #0
	pop	{r4, r5, r6}
	pop	{r1}
	bx	r1

@ ======================================================================================
@ mixFrame   (0812C370)
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
@   In this build: Same, but without the pause test: voices of paused players keep playing (their notes are
@   released by trackTick instead, see there).
@ ======================================================================================
	.global mixFrame
	.thumb_func
mixFrame:
	push	{r4, r5, r6, r7, lr}
	mov	r7, r8
	push	{r7}
	sub	sp, #4
	ldr	r0, .P0812C3D8	@ =gActiveVoices
	ldr	r7, [r0]
	ldr	r0, .P0812C3DC	@ =gEchoShift
	ldrb	r0, [r0]
	cmp	r0, #0xf
	bhi	.L0812C3A0
	ldr	r2, .P0812C3E0	@ =gEchoHistory
	ldr	r0, .P0812C3E4	@ =gEchoPos
	ldrb	r0, [r0]
	lsls	r1, r0, #1
	adds	r1, r1, r0
	lsls	r1, r1, #2
	subs	r1, r1, r0
	lsls	r1, r1, #6
	ldr	r0, [r2]
	adds	r0, r0, r1
	ldr	r1, .P0812C3E8	@ =gMixWet
	movs	r2, #0xb0
	bl	CpuFastSet
.L0812C3A0:
	movs	r0, #0
	str	r0, [sp]
	ldr	r1, .P0812C3EC	@ =gMixDry
	ldr	r2, .P0812C3F0	@ =0x010000B0
	mov	r0, sp
	bl	CpuFastSet
.L0812C3AE:
	cmp	r7, #0
	beq	.L0812C454
	adds	r4, r7, #0
	ldr	r7, [r7, #0x6c]
	adds	r0, r4, #0
	bl	dsVolume
	mov	r8, r0
	ldrb	r0, [r4, #1]
	cmp	r0, #1
	bne	.L0812C410
	ldrh	r0, [r4, #0x18]
	subs	r0, #1
	strh	r0, [r4, #0x18]
	ldr	r5, [r4, #4]
	ldrb	r0, [r4, #0x1b]
	cmp	r0, #0
	beq	.L0812C3F4
	ldrb	r3, [r4, #0x1c]
	b	.L0812C3FA
	.hword 0x0000
.P0812C3D8:	.word gActiveVoices
.P0812C3DC:	.word gEchoShift
.P0812C3E0:	.word gEchoHistory
.P0812C3E4:	.word gEchoPos
.P0812C3E8:	.word gMixWet
.P0812C3EC:	.word gMixDry
.P0812C3F0:	.word 0x010000B0
.L0812C3F4:
	adds	r0, r5, #0
	adds	r0, #0x4b
	ldrb	r3, [r0]
.L0812C3FA:
	adds	r6, r3, #0
	adds	r0, r4, #0
	bl	voicePitch
	adds	r2, r0, #0
	str	r2, [r4, #0x10]
	adds	r0, r5, #0
	adds	r0, #0x4c
	ldrb	r0, [r0]
	strb	r0, [r4, #0x1a]
	b	.L0812C422
.L0812C410:
	mov	r0, r8
	cmp	r0, #0
	bne	.L0812C41E
	adds	r0, r4, #0
	bl	voiceStop
	b	.L0812C3AE
.L0812C41E:
	ldrb	r6, [r4, #0x1c]
	ldr	r2, [r4, #0x10]
.L0812C422:
	lsrs	r2, r2, #2
	ldr	r0, [r4, #0x5c]
	ldr	r0, [r0, #4]
	muls	r2, r0, r2
	adds	r0, r2, #0
	ldr	r1, .P0812C450	@ =0x00002910
	bl	__udivsi3
	adds	r2, r0, #0
	lsrs	r2, r2, #5
	adds	r0, r4, #0
	mov	r1, r8
	adds	r3, r6, #0
	bl	mixVoice
	lsls	r0, r0, #0x18
	lsrs	r0, r0, #0x18
	cmp	r0, #1
	bne	.L0812C3AE
	adds	r0, r4, #0
	bl	voiceStop
	b	.L0812C3AE
.P0812C450:	.word 0x00002910
.L0812C454:
	movs	r5, #0
	movs	r4, #6
.L0812C458:
	ldr	r0, .P0812C48C	@ =gDsVoices
	adds	r1, r5, r0
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	bne	.L0812C46E
	ldrh	r0, [r1, #0x18]
	cmp	r0, #0
	bne	.L0812C46E
	adds	r0, r1, #0
	bl	noteOff
.L0812C46E:
	adds	r5, #0x78
	subs	r4, #1
	cmp	r4, #0
	bge	.L0812C458
	ldr	r4, .P0812C490	@ =gEchoShiftTarget
	ldr	r0, .P0812C494	@ =gEchoShift
	ldrb	r1, [r4]
	ldrb	r2, [r0]
	adds	r3, r2, #0
	adds	r6, r0, #0
	cmp	r1, r3
	bhs	.L0812C498
	subs	r0, r2, #1
	b	.L0812C4A0
	.hword 0x0000
.P0812C48C:	.word gDsVoices
.P0812C490:	.word gEchoShiftTarget
.P0812C494:	.word gEchoShift
.L0812C498:
	ldrb	r0, [r4]
	cmp	r0, r3
	bls	.L0812C4A2
	adds	r0, r2, #1
.L0812C4A0:
	strb	r0, [r6]
.L0812C4A2:
	ldrb	r0, [r6]
	cmp	r0, #0xf
	bls	.L0812C4BC
	ldr	r0, .P0812C4B8	@ =gEchoTail
	ldrb	r1, [r0]
	adds	r2, r0, #0
	cmp	r1, #0
	beq	.L0812C4FE
	subs	r0, r1, #1
	strb	r0, [r2]
	b	.L0812C4C6
.P0812C4B8:	.word gEchoTail
.L0812C4BC:
	ldr	r0, .P0812C540	@ =gEchoTail
	ldr	r1, .P0812C544	@ =gEchoLen
	ldrb	r1, [r1]
	strb	r1, [r0]
	adds	r2, r0, #0
.L0812C4C6:
	ldrb	r0, [r2]
	cmp	r0, #0
	beq	.L0812C4FE
	ldr	r1, .P0812C548	@ =gFnEcho
	ldr	r0, .P0812C54C	@ =gMixDry
	ldr	r5, .P0812C550	@ =gMixWet
	movs	r3, #0xb0
	lsls	r3, r3, #2
	adds	r2, r0, r3
	ldrb	r3, [r6]
	ldr	r4, [r1]
	adds	r1, r5, #0
	bl	_call_via_r4
	ldr	r2, .P0812C554	@ =gEchoHistory
	ldr	r0, .P0812C558	@ =gEchoPos
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
.L0812C4FE:
	ldr	r2, .P0812C558	@ =gEchoPos
	ldrb	r0, [r2]
	adds	r0, #1
	strb	r0, [r2]
	ldr	r1, .P0812C544	@ =gEchoLen
	lsls	r0, r0, #0x18
	lsrs	r0, r0, #0x18
	ldrb	r1, [r1]
	cmp	r0, r1
	blo	.L0812C516
	movs	r0, #0
	strb	r0, [r2]
.L0812C516:
	ldr	r3, .P0812C55C	@ =gFnDownmix
	ldr	r0, .P0812C54C	@ =gMixDry
	ldr	r2, .P0812C560	@ =gDmaBufA
	ldr	r1, .P0812C564	@ =gDmaBufIdx
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
.P0812C540:	.word gEchoTail
.P0812C544:	.word gEchoLen
.P0812C548:	.word gFnEcho
.P0812C54C:	.word gMixDry
.P0812C550:	.word gMixWet
.P0812C554:	.word gEchoHistory
.P0812C558:	.word gEchoPos
.P0812C55C:	.word gFnDownmix
.P0812C560:	.word gDmaBufA
.P0812C564:	.word gDmaBufIdx

@ ======================================================================================
@ psgUpdate   (0812C568)
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
.L0812C576:
	mov	r1, sl
	lsls	r0, r1, #4
	subs	r0, r0, r1
	lsls	r0, r0, #3
	ldr	r1, .P0812C5B4	@ =gPsgVoices
	adds	r4, r0, r1
	ldrb	r0, [r4, #1]
	cmp	r0, #1
	bne	.L0812C594
	ldrh	r0, [r4, #0x18]
	cmp	r0, #0
	bne	.L0812C594
	adds	r0, r4, #0
	bl	noteOff
.L0812C594:
	ldrb	r0, [r4, #1]
	cmp	r0, #0
	bne	.L0812C59C
	b	.L0812C7DC
.L0812C59C:
	cmp	r0, #1
	bne	.L0812C5C2
	adds	r0, r4, #0
	bl	voicePitch
	adds	r6, r0, #0
	str	r6, [r4, #0x10]
	ldrb	r0, [r4, #0x1b]
	cmp	r0, #0
	beq	.L0812C5B8
	ldrb	r0, [r4, #0x1c]
	b	.L0812C5BE
.P0812C5B4:	.word gPsgVoices
.L0812C5B8:
	ldr	r0, [r4, #4]
	adds	r0, #0x4b
	ldrb	r0, [r0]
.L0812C5BE:
	mov	r8, r0
	b	.L0812C5C8
.L0812C5C2:
	ldr	r6, [r4, #0x10]
	ldrb	r2, [r4, #0x1c]
	mov	r8, r2
.L0812C5C8:
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
	ldr	r0, .P0812C60C	@ =REG_NR51
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
	bne	.L0812C610
	mov	r3, ip
	ldrb	r1, [r3]
	adds	r0, r2, #0
	ands	r0, r1
	orrs	r0, r5
	strb	r0, [r3]
	b	.L0812C63A
.P0812C60C:	.word REG_NR51
.L0812C610:
	mov	r0, r8
	cmp	r0, #0x3f
	bhi	.L0812C62A
	mov	r1, ip
	ldrb	r0, [r1]
	adds	r1, r2, #0
	ands	r1, r0
	movs	r0, #0x10
	lsls	r0, r3
	orrs	r1, r0
	mov	r2, ip
	strb	r1, [r2]
	b	.L0812C63A
.L0812C62A:
	mov	r3, ip
	ldrb	r0, [r3]
	ands	r1, r0
	movs	r0, #1
	mov	r2, sb
	lsls	r0, r2
	orrs	r1, r0
	strb	r1, [r3]
.L0812C63A:
	ldrb	r5, [r4, #1]
	cmp	r5, #1
	bne	.L0812C664
	ldr	r0, [r4, #0x60]
	cmp	r0, #0
	bne	.L0812C658
	adds	r0, r4, #0
	adds	r1, r7, #0
	bl	psgKeyOn
	str	r5, [r4, #0x60]
	ldrh	r0, [r4, #0x18]
	subs	r0, #1
	strh	r0, [r4, #0x18]
	b	.L0812C7DC
.L0812C658:
	adds	r0, #1
	str	r0, [r4, #0x60]
	ldrh	r0, [r4, #0x18]
	subs	r0, #1
	strh	r0, [r4, #0x18]
	b	.L0812C6B4
.L0812C664:
	ldrb	r0, [r4]
	cmp	r0, #3
	bne	.L0812C6B4
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
	beq	.L0812C684
	lsls	r1, r1, #1
.L0812C684:
	lsls	r0, r1, #2
	adds	r1, r0, r1
	lsrs	r1, r1, #7
	cmp	r1, #0
	beq	.L0812C6AC
	cmp	r1, #4
	bls	.L0812C694
	movs	r1, #4
.L0812C694:
	lsls	r1, r1, #0x18
	lsrs	r1, r1, #0x18
	ldr	r2, .P0812C6A4	@ =REG_NR32
	ldr	r0, .P0812C6A8	@ =kWaveVolume
	adds	r1, r1, r0
	ldrb	r0, [r1]
	strb	r0, [r2]
	b	.L0812C7DC
.P0812C6A4:	.word REG_NR32
.P0812C6A8:	.word kWaveVolume
.L0812C6AC:
	adds	r0, r4, #0
	bl	voiceStop
	b	.L0812C7DC
.L0812C6B4:
	ldr	r2, [r4, #0x54]
	ldrb	r1, [r2, #1]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0812C6D6
	ldr	r0, [r4, #0x64]
	ldrh	r3, [r0]
	ldr	r1, [r4, #0x60]
	cmp	r1, r3
	bhs	.L0812C6D0
	adds	r0, r0, r1
	ldrb	r5, [r0, #2]
	b	.L0812C6D8
.L0812C6D0:
	adds	r0, r3, r0
	ldrb	r5, [r0, #1]
	b	.L0812C6D8
.L0812C6D6:
	movs	r5, #0xff
.L0812C6D8:
	ldrb	r0, [r4]
	cmp	r0, #2
	beq	.L0812C728
	cmp	r0, #2
	bgt	.L0812C6E8
	cmp	r0, #1
	beq	.L0812C6F2
	b	.L0812C7DC
.L0812C6E8:
	cmp	r0, #3
	beq	.L0812C768
	cmp	r0, #4
	beq	.L0812C790
	b	.L0812C7DC
.L0812C6F2:
	cmp	r7, #8
	beq	.L0812C710
	ldr	r0, .P0812C708	@ =REG_NR12
	strb	r7, [r0]
	ldr	r1, .P0812C70C	@ =REG_SOUND1CNT_X
	movs	r2, #0x80
	lsls	r2, r2, #8
	adds	r0, r2, #0
	orrs	r6, r0
	strh	r6, [r1]
	b	.L0812C71A
.P0812C708:	.word REG_NR12
.P0812C70C:	.word REG_SOUND1CNT_X
.L0812C710:
	ldrb	r0, [r2, #8]
	cmp	r0, #8
	bne	.L0812C71A
	ldr	r0, .P0812C720	@ =REG_SOUND1CNT_X
	strh	r6, [r0]
.L0812C71A:
	ldr	r2, .P0812C724	@ =REG_NR11
	b	.L0812C74E
	.hword 0x0000
.P0812C720:	.word REG_SOUND1CNT_X
.P0812C724:	.word REG_NR11
.L0812C728:
	cmp	r7, #8
	beq	.L0812C748
	ldr	r0, .P0812C740	@ =REG_NR22
	strb	r7, [r0]
	ldr	r1, .P0812C744	@ =REG_SOUND2CNT_H
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r0, r3, #0
	orrs	r6, r0
	strh	r6, [r1]
	b	.L0812C74C
	.hword 0x0000
.P0812C740:	.word REG_NR22
.P0812C744:	.word REG_SOUND2CNT_H
.L0812C748:
	ldr	r0, .P0812C760	@ =REG_SOUND2CNT_H
	strh	r6, [r0]
.L0812C74C:
	ldr	r2, .P0812C764	@ =REG_NR21
.L0812C74E:
	ldrb	r1, [r2]
	movs	r0, #0xc0
	ands	r0, r1
	strb	r0, [r2]
	cmp	r5, #0xff
	beq	.L0812C7DC
	lsls	r0, r5, #6
	strb	r0, [r2]
	b	.L0812C7DC
.P0812C760:	.word REG_SOUND2CNT_H
.P0812C764:	.word REG_NR21
.L0812C768:
	ldr	r0, .P0812C788	@ =REG_SOUND3CNT_X
	ldrh	r1, [r0]
	movs	r3, #0x80
	lsls	r3, r3, #7
	adds	r2, r3, #0
	ands	r1, r2
	orrs	r1, r6
	strh	r1, [r0]
	cmp	r7, #8
	beq	.L0812C7DC
	subs	r0, #1
	ldr	r1, .P0812C78C	@ =kWaveVolume
	adds	r1, r7, r1
	ldrb	r1, [r1]
	strb	r1, [r0]
	b	.L0812C7DC
.P0812C788:	.word REG_SOUND3CNT_X
.P0812C78C:	.word kWaveVolume
.L0812C790:
	cmp	r7, #8
	beq	.L0812C79E
	ldr	r0, .P0812C7BC	@ =REG_NR42
	strb	r7, [r0]
	ldr	r1, .P0812C7C0	@ =REG_NR44
	movs	r0, #0x80
	strb	r0, [r1]
.L0812C79E:
	cmp	r5, #0xff
	beq	.L0812C7C8
	ldr	r4, .P0812C7C4	@ =REG_NR43
	lsls	r0, r6, #0x10
	lsrs	r0, r0, #0x10
	bl	noiseDivider
	lsls	r0, r0, #0x18
	lsrs	r1, r0, #0x18
	cmp	r5, #0
	beq	.L0812C7B8
	movs	r0, #8
	orrs	r1, r0
.L0812C7B8:
	strb	r1, [r4]
	b	.L0812C7DC
.P0812C7BC:	.word REG_NR42
.P0812C7C0:	.word REG_NR44
.P0812C7C4:	.word REG_NR43
.L0812C7C8:
	lsls	r0, r6, #0x10
	lsrs	r0, r0, #0x10
	bl	noiseDivider
	ldr	r3, .P0812C7F8	@ =REG_NR43
	ldrb	r2, [r3]
	movs	r1, #8
	ands	r1, r2
	orrs	r1, r0
	strb	r1, [r3]
.L0812C7DC:
	movs	r0, #1
	add	sl, r0
	mov	r1, sl
	cmp	r1, #3
	bgt	.L0812C7E8
	b	.L0812C576
.L0812C7E8:
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	sb, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0812C7F8:	.word REG_NR43

@ ======================================================================================
@ noteOn   (0812C7FC)
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
	beq	.L0812C824
	b	.L0812C9B8
.L0812C824:
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
	beq	.L0812C84A
	ldrh	r1, [r4, #0x30]
	b	.L0812C852
.L0812C84A:
	movs	r0, #0x32
	ldrsh	r1, [r4, r0]
	ldrh	r4, [r4, #0x30]
	adds	r1, r1, r4
.L0812C852:
	mov	r0, r8
	bl	__udivsi3
	mov	r8, r0
	adds	r0, r5, #0
	adds	r0, #0x49
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L0812C86E
	ldr	r0, [r5, #0xc]
	cmp	r0, #0
	beq	.L0812C86E
	adds	r4, r0, #0
	b	.L0812C8C4
.L0812C86E:
	ldr	r1, .P0812C8DC	@ =kVoiceForType
	ldrb	r0, [r6]
	adds	r0, r0, r1
	ldrb	r0, [r0]
	adds	r1, r5, #0
	adds	r1, #0x52
	ldrb	r1, [r1]
	bl	voiceAlloc
	adds	r4, r0, #0
	cmp	r4, #0
	bne	.L0812C888
	b	.L0812C9B8
.L0812C888:
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
.L0812C8C4:
	mov	r0, sp
	ldrb	r0, [r0, #0x11]
	strb	r0, [r4, #0x1b]
	lsls	r0, r0, #0x18
	cmp	r0, #0
	beq	.L0812C8E0
	movs	r7, #0x30
	mov	r0, sp
	ldrb	r0, [r0, #0x10]
	strb	r0, [r4, #0x1c]
	b	.L0812C8EA
	.hword 0x0000
.P0812C8DC:	.word kVoiceForType
.L0812C8E0:
	mov	r0, sp
	ldrb	r0, [r0, #0x12]
	cmp	r0, #0
	beq	.L0812C8EA
	movs	r7, #0x30
.L0812C8EA:
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
	bne	.L0812C91C
	adds	r0, r4, #0
	adds	r0, #0x2c
	movs	r1, #0x14
	bl	MemClear
	b	.L0812C976
.L0812C91C:
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
	beq	.L0812C94A
	ldr	r0, [r4, #0xc]
	subs	r0, r2, r0
	str	r0, [r4, #0x38]
	b	.L0812C952
.L0812C94A:
	ldr	r0, [r4, #0xc]
	subs	r0, r0, r2
	str	r0, [r4, #0x38]
	str	r2, [r4, #0xc]
.L0812C952:
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
	beq	.L0812C970
	strb	r7, [r5, #0x1e]
	b	.L0812C972
.L0812C970:
	strb	r0, [r5, #0x1c]
.L0812C972:
	movs	r0, #0
	str	r0, [r4, #0x34]
.L0812C976:
	ldrb	r0, [r4]
	cmp	r0, #0
	bne	.L0812C98C
	ldrh	r0, [r6, #2]
	ldr	r1, [r5, #4]
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r0, [r0]
	adds	r1, r1, r0
	str	r1, [r4, #0x5c]
	b	.L0812C9AC
.L0812C98C:
	cmp	r0, #3
	beq	.L0812C9A8
	ldrb	r1, [r6, #1]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0812C99E
	ldr	r0, [sp, #8]
	b	.L0812C9AA
.L0812C99E:
	ldrh	r1, [r6, #2]
	adds	r0, r4, #0
	adds	r0, #0x64
	strb	r1, [r0]
	b	.L0812C9AC
.L0812C9A8:
	ldr	r0, [sp, #0xc]
.L0812C9AA:
	str	r0, [r4, #0x64]
.L0812C9AC:
	mov	r0, r8
	cmp	r0, #0
	bne	.L0812C9B8
	adds	r0, r4, #0
	bl	noteOff
.L0812C9B8:
	add	sp, #0x14
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	sb, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ noteOff   (0812C9C8)
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
	bne	.L0812CAA6
	ldr	r0, [r4, #4]
	adds	r0, #0x49
	ldrb	r0, [r0]
	cmp	r0, #0
	bne	.L0812CAA6
	ldrb	r3, [r4]
	cmp	r3, #0
	bne	.L0812C9FC
	ldr	r1, .P0812C9F8	@ =gActiveVoices
	adds	r0, r4, #0
	bl	voiceListRemove
	movs	r0, #2
	strb	r0, [r4, #1]
	adds	r0, r4, #0
	bl	voiceListInsertActive
	b	.L0812CA8E
	.hword 0x0000
.P0812C9F8:	.word gActiveVoices
.L0812C9FC:
	ldrh	r2, [r4, #0x10]
	adds	r0, r4, #0
	adds	r0, #0x58
	ldrb	r1, [r0]
	cmp	r3, #3
	bne	.L0812CA0C
	movs	r0, #2
	b	.L0812CA8C
.L0812CA0C:
	lsrs	r1, r1, #5
	cmp	r1, #0
	bne	.L0812CA16
	movs	r1, #0
	b	.L0812CA20
.L0812CA16:
	ldr	r0, [r4, #0x14]
	lsls	r0, r0, #4
	orrs	r1, r0
	lsls	r0, r1, #0x18
	lsrs	r1, r0, #0x18
.L0812CA20:
	ldrb	r0, [r4]
	cmp	r0, #2
	beq	.L0812CA58
	cmp	r0, #2
	bgt	.L0812CA30
	cmp	r0, #1
	beq	.L0812CA36
	b	.L0812CA8A
.L0812CA30:
	cmp	r0, #4
	beq	.L0812CA80
	b	.L0812CA8A
.L0812CA36:
	ldr	r0, .P0812CA4C	@ =REG_NR12
	strb	r1, [r0]
	ldr	r1, .P0812CA50	@ =REG_SOUND1CNT_X
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r0, r3, #0
	orrs	r2, r0
	strh	r2, [r1]
	ldr	r2, .P0812CA54	@ =REG_NR11
	b	.L0812CA6A
	.hword 0x0000
.P0812CA4C:	.word REG_NR12
.P0812CA50:	.word REG_SOUND1CNT_X
.P0812CA54:	.word REG_NR11
.L0812CA58:
	ldr	r0, .P0812CA74	@ =REG_NR22
	strb	r1, [r0]
	ldr	r1, .P0812CA78	@ =REG_SOUND2CNT_H
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r0, r3, #0
	orrs	r2, r0
	strh	r2, [r1]
	ldr	r2, .P0812CA7C	@ =REG_NR21
.L0812CA6A:
	ldrb	r1, [r2]
	movs	r0, #0xc0
	ands	r0, r1
	strb	r0, [r2]
	b	.L0812CA8A
.P0812CA74:	.word REG_NR22
.P0812CA78:	.word REG_SOUND2CNT_H
.P0812CA7C:	.word REG_NR21
.L0812CA80:
	ldr	r0, .P0812CAAC	@ =REG_NR42
	strb	r1, [r0]
	ldr	r1, .P0812CAB0	@ =REG_NR44
	movs	r0, #0x80
	strb	r0, [r1]
.L0812CA8A:
	movs	r0, #0
.L0812CA8C:
	strb	r0, [r4, #1]
.L0812CA8E:
	ldrb	r0, [r4, #0x1b]
	ldr	r1, [r4, #4]
	cmp	r0, #0
	bne	.L0812CA9E
	adds	r0, r1, #0
	adds	r0, #0x4b
	ldrb	r0, [r0]
	strb	r0, [r4, #0x1c]
.L0812CA9E:
	adds	r0, r1, #0
	adds	r1, r4, #0
	bl	trackRemoveVoice
.L0812CAA6:
	pop	{r4}
	pop	{r0}
	bx	r0
.P0812CAAC:	.word REG_NR42
.P0812CAB0:	.word REG_NR44

@ ======================================================================================
@ voiceStop   (0812CAB4)
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
	beq	.L0812CB40
	ldrb	r0, [r4]
	cmp	r0, #4
	bhi	.L0812CB34
	lsls	r0, r0, #2
	ldr	r1, .P0812CAD0	@ =0x0812CAD4
	adds	r0, r0, r1
	ldr	r0, [r0]
	mov	pc, r0
	.hword 0x0000
.P0812CAD0:	.word 0x0812CAD4
	.word .L0812CAE8
	.word .L0812CB04
	.word .L0812CB14
	.word .L0812CB1C
	.word .L0812CB28
.L0812CAE8:
	ldr	r1, .P0812CAFC	@ =gActiveVoices
	adds	r0, r4, #0
	bl	voiceListRemove
	ldr	r1, .P0812CB00	@ =gFreeVoices
	adds	r0, r4, #0
	bl	voiceListPush
	b	.L0812CB34
	.hword 0x0000
.P0812CAFC:	.word gActiveVoices
.P0812CB00:	.word gFreeVoices
.L0812CB04:
	ldr	r1, .P0812CB10	@ =REG_NR12
	movs	r0, #8
	strb	r0, [r1]
	adds	r1, #2
	b	.L0812CB30
	.hword 0x0000
.P0812CB10:	.word REG_NR12
.L0812CB14:
	ldr	r1, .P0812CB18	@ =REG_NR22
	b	.L0812CB2A
.P0812CB18:	.word REG_NR22
.L0812CB1C:
	ldr	r1, .P0812CB24	@ =REG_NR30
	movs	r0, #0
	b	.L0812CB32
	.hword 0x0000
.P0812CB24:	.word REG_NR30
.L0812CB28:
	ldr	r1, .P0812CB48	@ =REG_NR42
.L0812CB2A:
	movs	r0, #8
	strb	r0, [r1]
	adds	r1, #4
.L0812CB30:
	movs	r0, #0xc0
.L0812CB32:
	strb	r0, [r1]
.L0812CB34:
	ldr	r0, [r4, #4]
	adds	r1, r4, #0
	bl	trackRemoveVoice
	movs	r0, #0
	strb	r0, [r4, #1]
.L0812CB40:
	pop	{r4}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0812CB48:	.word REG_NR42

@ ======================================================================================
@ psgKeyOn   (0812CB4C)
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
	beq	.L0812CBD0
	cmp	r3, #2
	bgt	.L0812CB64
	cmp	r3, #1
	beq	.L0812CB6E
	b	.L0812CC9C
.L0812CB64:
	cmp	r3, #3
	beq	.L0812CBFC
	cmp	r3, #4
	beq	.L0812CC50
	b	.L0812CC9C
.L0812CB6E:
	ldr	r1, .P0812CB9C	@ =REG_NR10
	ldr	r0, [r4, #0x54]
	ldrb	r0, [r0, #8]
	strb	r0, [r1]
	ldr	r2, .P0812CBA0	@ =REG_SOUND1CNT_X
	ldr	r0, [r4, #0xc]
	movs	r6, #0x80
	lsls	r6, r6, #8
	adds	r1, r6, #0
	orrs	r0, r1
	strh	r0, [r2]
	ldr	r0, .P0812CBA4	@ =REG_NR12
	strb	r5, [r0]
	ldr	r0, [r4, #0x54]
	ldrb	r0, [r0, #1]
	ands	r3, r0
	cmp	r3, #0
	beq	.L0812CBAC
	ldr	r1, .P0812CBA8	@ =REG_NR11
	ldr	r0, [r4, #0x64]
	ldrb	r0, [r0, #2]
	b	.L0812CBB4
	.hword 0x0000
.P0812CB9C:	.word REG_NR10
.P0812CBA0:	.word REG_SOUND1CNT_X
.P0812CBA4:	.word REG_NR12
.P0812CBA8:	.word REG_NR11
.L0812CBAC:
	ldr	r1, .P0812CBC8	@ =REG_NR11
	adds	r0, r4, #0
	adds	r0, #0x64
	ldrb	r0, [r0]
.L0812CBB4:
	lsls	r0, r0, #6
	strb	r0, [r1]
	ldr	r0, .P0812CBCC	@ =REG_SOUND1CNT_X
	ldr	r1, [r4, #0xc]
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r2, r3, #0
	orrs	r1, r2
	strh	r1, [r0]
	b	.L0812CC9C
.P0812CBC8:	.word REG_NR11
.P0812CBCC:	.word REG_SOUND1CNT_X
.L0812CBD0:
	ldr	r0, .P0812CBF0	@ =REG_NR22
	strb	r5, [r0]
	ldr	r2, .P0812CBF4	@ =REG_SOUND2CNT_H
	ldr	r0, [r4, #0xc]
	movs	r6, #0x80
	lsls	r6, r6, #8
	adds	r1, r6, #0
	orrs	r0, r1
	strh	r0, [r2]
	ldr	r1, .P0812CBF8	@ =REG_NR21
	adds	r0, r4, #0
	adds	r0, #0x64
	ldrb	r0, [r0]
	lsls	r0, r0, #6
	b	.L0812CC9A
	.hword 0x0000
.P0812CBF0:	.word REG_NR22
.P0812CBF4:	.word REG_SOUND2CNT_H
.P0812CBF8:	.word REG_NR21
.L0812CBFC:
	ldr	r6, .P0812CC3C	@ =gLastWave
	ldr	r1, [r4, #0x64]
	ldr	r0, [r6]
	cmp	r1, r0
	beq	.L0812CC1A
	ldr	r1, .P0812CC40	@ =REG_NR30
	movs	r0, #0
	strb	r0, [r1]
	ldr	r0, [r4, #0x64]
	adds	r1, #0x20
	movs	r2, #8
	bl	CpuSet
	ldr	r0, [r4, #0x64]
	str	r0, [r6]
.L0812CC1A:
	ldr	r1, .P0812CC40	@ =REG_NR30
	movs	r0, #0xc0
	strb	r0, [r1]
	ldr	r2, .P0812CC44	@ =REG_SOUND3CNT_X
	ldr	r0, [r4, #0xc]
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r1, r3, #0
	orrs	r0, r1
	strh	r0, [r2]
	ldr	r1, .P0812CC48	@ =REG_NR32
	ldr	r0, .P0812CC4C	@ =kWaveVolume
	adds	r0, r5, r0
	ldrb	r0, [r0]
	strb	r0, [r1]
	subs	r1, #1
	b	.L0812CC98
.P0812CC3C:	.word gLastWave
.P0812CC40:	.word REG_NR30
.P0812CC44:	.word REG_SOUND3CNT_X
.P0812CC48:	.word REG_NR32
.P0812CC4C:	.word kWaveVolume
.L0812CC50:
	ldr	r0, .P0812CC70	@ =REG_NR42
	strb	r5, [r0]
	ldr	r0, [r4, #0x54]
	ldrb	r1, [r0, #1]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0812CC74
	ldrh	r0, [r4, #0xc]
	bl	noiseDivider
	lsls	r0, r0, #0x18
	lsrs	r1, r0, #0x18
	ldr	r0, [r4, #0x64]
	ldrb	r0, [r0, #2]
	b	.L0812CC84
.P0812CC70:	.word REG_NR42
.L0812CC74:
	ldrh	r0, [r4, #0xc]
	bl	noiseDivider
	lsls	r0, r0, #0x18
	lsrs	r1, r0, #0x18
	adds	r0, r4, #0
	adds	r0, #0x64
	ldrb	r0, [r0]
.L0812CC84:
	cmp	r0, #0
	beq	.L0812CC8C
	movs	r0, #8
	orrs	r1, r0
.L0812CC8C:
	ldr	r0, .P0812CCA4	@ =REG_NR43
	strb	r1, [r0]
	ldr	r1, .P0812CCA8	@ =REG_NR44
	movs	r0, #0x80
	strb	r0, [r1]
	subs	r1, #5
.L0812CC98:
	movs	r0, #0
.L0812CC9A:
	strb	r0, [r1]
.L0812CC9C:
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0812CCA4:	.word REG_NR43
.P0812CCA8:	.word REG_NR44

@ ======================================================================================
@ voiceAlloc   (0812CCAC)
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
	bne	.L0812CD08
	ldr	r0, .P0812CCC8	@ =gFreeVoices
	ldr	r0, [r0]
	cmp	r0, #0
	beq	.L0812CCCC
	adds	r4, r0, #0
	b	.L0812CCE8
	.hword 0x0000
.P0812CCC8:	.word gFreeVoices
.L0812CCCC:
	ldr	r0, .P0812CD00	@ =gActiveVoices
	ldr	r1, [r0]
	cmp	r1, #0
	beq	.L0812CD1E
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	bne	.L0812CCE0
	ldrb	r0, [r1, #8]
	cmp	r5, r0
	blo	.L0812CD1E
.L0812CCE0:
	adds	r4, r1, #0
	adds	r0, r4, #0
	bl	voiceStop
.L0812CCE8:
	ldr	r1, .P0812CD04	@ =gFreeVoices
	adds	r0, r4, #0
	bl	voiceListRemove
	movs	r0, #1
	strb	r0, [r4, #1]
	strb	r5, [r4, #8]
	adds	r0, r4, #0
	bl	voiceListInsertActive
	b	.L0812CD3A
	.hword 0x0000
.P0812CD00:	.word gActiveVoices
.P0812CD04:	.word gFreeVoices
.L0812CD08:
	lsls	r0, r2, #4
	subs	r0, r0, r2
	lsls	r0, r0, #3
	ldr	r1, .P0812CD24	@ =gDsVoices+0x2D0
	adds	r4, r0, r1
	ldrb	r0, [r4, #1]
	cmp	r0, #1
	bne	.L0812CD28
	ldrb	r0, [r4, #8]
	cmp	r5, r0
	bhs	.L0812CD28
.L0812CD1E:
	movs	r0, #0
	b	.L0812CD3C
	.hword 0x0000
.P0812CD24:	.word gDsVoices+0x2D0
.L0812CD28:
	ldrb	r0, [r4, #1]
	cmp	r0, #0
	beq	.L0812CD34
	adds	r0, r4, #0
	bl	voiceStop
.L0812CD34:
	movs	r0, #1
	strb	r0, [r4, #1]
	strb	r5, [r4, #8]
.L0812CD3A:
	adds	r0, r4, #0
.L0812CD3C:
	pop	{r4, r5}
	pop	{r1}
	bx	r1
	movs	r0, r0

@ ======================================================================================
@ trackInitAll   (0812CD44)
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
	ldr	r0, .P0812CD6C	@ =gTracks
	movs	r1, #0
	adds	r0, #8
	movs	r2, #0x17
.L0812CD4E:
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
	bge	.L0812CD4E
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0812CD6C:	.word gTracks

@ ======================================================================================
@ trackAlloc   (0812CD70)
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
	ldr	r1, .P0812CD84	@ =gTracks
	ldr	r0, .P0812CD88	@ =0x0000078C
	adds	r2, r1, r0
.L0812CD78:
	ldr	r0, [r1, #8]
	cmp	r0, #0
	bne	.L0812CD8C
	adds	r0, r1, #0
	b	.L0812CD94
	.hword 0x0000
.P0812CD84:	.word gTracks
.P0812CD88:	.word 0x0000078C
.L0812CD8C:
	adds	r1, #0x54
	cmp	r1, r2
	ble	.L0812CD78
	movs	r0, #0
.L0812CD94:
	pop	{r1}
	bx	r1

@ ======================================================================================
@ trackStart   (0812CD98)
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
	beq	.L0812CE4E
	ldr	r0, [r5, #8]
	cmp	r0, #0
	beq	.L0812CDB0
	adds	r0, r5, #0
	bl	trackStop
.L0812CDB0:
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
	bne	.L0812CE22
	adds	r1, #2
	movs	r0, #0xc
	strb	r0, [r1]
	subs	r1, #6
	movs	r0, #0x7f
	strb	r0, [r1]
	adds	r0, r5, #0
	adds	r0, #0x53
	strb	r3, [r0]
	b	.L0812CE34
.L0812CE22:
	adds	r1, r5, #0
	adds	r1, #0x52
	movs	r0, #3
	strb	r0, [r1]
	adds	r0, r5, #0
	adds	r0, #0x4c
	strb	r2, [r0]
	adds	r0, #7
	strb	r2, [r0]
.L0812CE34:
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
.L0812CE4E:
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ trackReleaseAll   (0812CE54)
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
	beq	.L0812CE7C
	adds	r1, r4, #0
	adds	r1, #0x49
	ldrb	r6, [r1]
	movs	r0, #0
	strb	r0, [r1]
	ldr	r0, [r4, #0xc]
	adds	r5, r1, #0
	cmp	r0, #0
	beq	.L0812CE7A
.L0812CE6E:
	ldr	r4, [r0, #0x74]
	bl	noteOff
	adds	r0, r4, #0
	cmp	r0, #0
	bne	.L0812CE6E
.L0812CE7A:
	strb	r6, [r5]
.L0812CE7C:
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ trackStop   (0812CE84)
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
	beq	.L0812CE94
	bl	trackReleaseAll
	movs	r0, #0
	str	r0, [r4, #8]
.L0812CE94:
	pop	{r4}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ trackTick   (0812CE9C)
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
@   In this build: Same, but while the player is paused every frame releases all notes of the track
@   (trackReleaseAll); the track does not advance.
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
	beq	.L0812CEB0
	ldr	r1, [r5, #8]
	cmp	r1, #0
	bne	.L0812CEB4
.L0812CEB0:
	movs	r0, #1
	b	.L0812D300
.L0812CEB4:
	mov	r8, r1
	mov	r0, r8
	adds	r0, #0x3c
	ldrb	r1, [r0]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	bne	.L0812CEC6
	b	.L0812D2E6
.L0812CEC6:
	adds	r0, r5, #0
	bl	trackReleaseAll
	b	.L0812D2FE
.L0812CECE:
	adds	r0, r5, #0
	bl	trackStop
	movs	r0, #2
	b	.L0812D300
.L0812CED8:
	ldr	r2, [r5]
	ldrb	r6, [r2]
	adds	r2, #1
	str	r2, [r5]
	cmp	r6, #0xbf
	bhi	.L0812CF5C
	cmp	r6, #0x5f
	bhi	.L0812CEF4
	adds	r0, r5, #0
	adds	r0, #0x44
	ldrh	r4, [r0]
	adds	r0, #4
	ldrb	r2, [r0]
	b	.L0812CF1A
.L0812CEF4:
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
.L0812CF1A:
	movs	r0, #0x96
	muls	r4, r0, r4
	ldr	r0, .P0812CF40	@ =gHookNote
	ldr	r7, [r0]
	cmp	r7, #0
	beq	.L0812CF44
	mov	r0, r8
	adds	r0, #0x44
	ldrb	r1, [r0]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0812CF44
	adds	r0, r5, #0
	adds	r1, r6, #0
	adds	r3, r4, #0
	bl	_call_via_r7
	b	.L0812CF4E
.P0812CF40:	.word gHookNote
.L0812CF44:
	adds	r0, r5, #0
	adds	r1, r6, #0
	adds	r3, r4, #0
	bl	noteOn
.L0812CF4E:
	adds	r0, r5, #0
	adds	r0, #0x53
	ldrb	r0, [r0]
	cmp	r0, #1
	beq	.L0812CF5A
	b	.L0812D2E6
.L0812CF5A:
	b	.L0812CF80
.L0812CF5C:
	cmp	r6, #0xc0
	bne	.L0812CF68
	adds	r0, r5, #0
	adds	r0, #0x46
	ldrh	r4, [r0]
	b	.L0812CF7C
.L0812CF68:
	cmp	r6, #0xc1
	bne	.L0812CF88
	adds	r0, r5, #0
	bl	readVarLen
	lsls	r0, r0, #0x10
	lsrs	r4, r0, #0x10
	adds	r0, r5, #0
	adds	r0, #0x46
	strh	r4, [r0]
.L0812CF7C:
	movs	r0, #0x96
	muls	r4, r0, r4
.L0812CF80:
	ldr	r0, [r5, #0x34]
	adds	r0, r0, r4
	str	r0, [r5, #0x34]
	b	.L0812D2E6
.L0812CF88:
	movs	r0, #0xf0
	ands	r0, r6
	cmp	r0, #0xd0
	bne	.L0812CFC8
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
	beq	.L0812CFC0
	ldrb	r0, [r3, #1]
	strh	r0, [r5, #0x20]
	adds	r0, r2, #1
	str	r0, [r5]
	b	.L0812CFC2
.L0812CFC0:
	strh	r1, [r5, #0x20]
.L0812CFC2:
	movs	r0, #1
	strb	r0, [r5, #0x1c]
	b	.L0812D2E6
.L0812CFC8:
	adds	r0, r6, #0
	subs	r0, #0xc2
	cmp	r0, #0x3d
	bls	.L0812CFD2
	b	.L0812D2E6
.L0812CFD2:
	lsls	r0, r0, #2
	ldr	r1, .P0812CFDC	@ =0x0812CFE0
	adds	r0, r0, r1
	ldr	r0, [r0]
	mov	pc, r0
.P0812CFDC:	.word 0x0812CFE0
	.word .L0812D136
	.word .L0812D152
	.word .L0812D15E
	.word .L0812D1B2
	.word .L0812D1B2
	.word .L0812D142
	.word .L0812D1C6
	.word .L0812D1D0
	.word .L0812D1DA
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D16A
	.word .L0812D182
	.word .L0812D18E
	.word .L0812D1A6
	.word .L0812D200
	.word .L0812D20C
	.word .L0812D21C
	.word .L0812D214
	.word .L0812D0EE
	.word .L0812D19A
	.word .L0812D176
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D0F4
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D10E
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D228
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D2E6
	.word .L0812D0D8
.L0812D0D8:
	adds	r0, r5, #0
	adds	r0, #0x24
	ldr	r1, [r5, #0x30]
	cmp	r1, r0
	bne	.L0812D0E4
	b	.L0812CECE
.L0812D0E4:
	subs	r0, r1, #4
	str	r0, [r5, #0x30]
	ldr	r0, [r0]
	str	r0, [r5]
	b	.L0812D2E6
.L0812D0EE:
	movs	r0, #0
	strb	r0, [r5, #0x1c]
	b	.L0812D2E6
.L0812D0F4:
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
	b	.L0812D12C
.L0812D10E:
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
.L0812D12C:
	mov	r0, sp
	ldrh	r0, [r0]
	adds	r1, r1, r0
	str	r1, [r5]
	b	.L0812D2E6
.L0812D136:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x42
	strh	r1, [r2]
	b	.L0812D1FA
.L0812D142:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r0, #1
	str	r0, [r5]
	adds	r0, r5, #0
	bl	trackSetBank
	b	.L0812D2E6
.L0812D152:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x4b
	strb	r1, [r2]
	b	.L0812D1FA
.L0812D15E:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x52
	strb	r1, [r2]
	b	.L0812D1FA
.L0812D16A:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x4d
	strb	r1, [r2]
	b	.L0812D1FA
.L0812D176:
	ldr	r0, [r5, #8]
	ldr	r1, [r5]
	ldrb	r2, [r1]
	adds	r0, #0x40
	strb	r2, [r0]
	b	.L0812D222
.L0812D182:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x4f
	strb	r1, [r2]
	b	.L0812D1FA
.L0812D18E:
	ldr	r0, [r5]
	ldrb	r2, [r0]
	adds	r1, r5, #0
	adds	r1, #0x50
	strb	r2, [r1]
	b	.L0812D1FA
.L0812D19A:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x51
	strb	r1, [r2]
	b	.L0812D1FA
.L0812D1A6:
	ldr	r0, [r5]
	ldrb	r2, [r0]
	adds	r1, r5, #0
	adds	r1, #0x4c
	strb	r2, [r1]
	b	.L0812D1FA
.L0812D1B2:
	adds	r0, r5, #0
	bl	trackReleaseAll
	movs	r1, #0
	cmp	r6, #0xc5
	bne	.L0812D1C0
	movs	r1, #1
.L0812D1C0:
	adds	r0, r5, #0
	adds	r0, #0x49
	b	.L0812D2E4
.L0812D1C6:
	adds	r1, r5, #0
	adds	r1, #0x53
	movs	r0, #1
	strb	r0, [r1]
	b	.L0812D2E6
.L0812D1D0:
	adds	r1, r5, #0
	adds	r1, #0x53
	movs	r0, #0
	strb	r0, [r1]
	b	.L0812D2E6
.L0812D1DA:
	ldr	r0, .P0812D1F4	@ =gHookCA
	ldr	r2, [r0]
	cmp	r2, #0
	beq	.L0812D1F8
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r0, #1
	str	r0, [r5]
	adds	r0, r5, #0
	bl	_call_via_r2
	b	.L0812D2E6
	.hword 0x0000
.P0812D1F4:	.word gHookCA
.L0812D1F8:
	ldr	r0, [r5]
.L0812D1FA:
	adds	r0, #1
	str	r0, [r5]
	b	.L0812D2E6
.L0812D200:
	adds	r0, r5, #0
	bl	readVarLen
	mov	r3, r8
	strh	r0, [r3, #0x30]
	b	.L0812D2E6
.L0812D20C:
	ldr	r1, [r5]
	ldrb	r0, [r1]
	strh	r0, [r5, #0x10]
	b	.L0812D222
.L0812D214:
	ldr	r1, [r5]
	ldrb	r0, [r1]
	str	r0, [r5, #0x18]
	b	.L0812D222
.L0812D21C:
	ldr	r1, [r5]
	ldrb	r0, [r1]
	str	r0, [r5, #0x14]
.L0812D222:
	adds	r1, #1
	str	r1, [r5]
	b	.L0812D2E6
.L0812D228:
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
	bne	.L0812D25C
	bl	trackAlloc
	adds	r4, r0, #0
	str	r4, [r6]
	b	.L0812D262
.L0812D25C:
	adds	r4, r0, #0
	bl	trackStop
.L0812D262:
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
.L0812D2E4:
	strb	r1, [r0]
.L0812D2E6:
	ldr	r1, [r5, #0x34]
	cmp	r1, #0
	bgt	.L0812D2EE
	b	.L0812CED8
.L0812D2EE:
	mov	r2, r8
	ldrh	r0, [r2, #0x30]
	subs	r0, r1, r0
	str	r0, [r5, #0x34]
	movs	r3, #0x32
	ldrsh	r1, [r2, r3]
	subs	r0, r0, r1
	str	r0, [r5, #0x34]
.L0812D2FE:
	movs	r0, #0
.L0812D300:
	add	sp, #4
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1

@ ======================================================================================
@ trackAddVoice   (0812D30C)
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
	bne	.L0812D324
	str	r0, [r1, #4]
	str	r2, [r1, #0x70]
	ldr	r2, [r0, #0xc]
	str	r2, [r1, #0x74]
	str	r1, [r0, #0xc]
	cmp	r2, #0
	beq	.L0812D324
	str	r1, [r2, #0x70]
.L0812D324:
	pop	{r0}
	bx	r0

@ ======================================================================================
@ trackRemoveVoice   (0812D328)
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
	beq	.L0812D350
	movs	r0, #0
	str	r0, [r1, #4]
	ldr	r2, [r1, #0x74]
	cmp	r2, #0
	beq	.L0812D340
	ldr	r0, [r1, #0x70]
	str	r0, [r2, #0x70]
.L0812D340:
	ldr	r2, [r1, #0x70]
	cmp	r2, #0
	beq	.L0812D34C
	ldr	r0, [r1, #0x74]
	str	r0, [r2, #0x74]
	b	.L0812D350
.L0812D34C:
	ldr	r0, [r1, #0x74]
	str	r0, [r3, #0xc]
.L0812D350:
	pop	{r0}
	bx	r0

@ ======================================================================================
@ readVarLen   (0812D354)
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
	beq	.L0812D376
	movs	r0, #0x7f
	ands	r1, r0
	lsls	r1, r1, #8
	ldrb	r0, [r2]
	orrs	r1, r0
	adds	r0, r2, #1
	str	r0, [r3]
.L0812D376:
	adds	r0, r1, #0
	pop	{r1}
	bx	r1

@ ======================================================================================
@ trackSetBank   (0812D37C)
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
	ldr	r0, .P0812D3AC	@ =gCfg
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
.P0812D3AC:	.word gCfg

@ ======================================================================================
@ playerInitAll   (0812D3B0)
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
	ldr	r4, .P0812D3E0	@ =gPlayers
	movs	r3, #0
.L0812D3B8:
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
.L0812D3CC:
	str	r3, [r0]
	subs	r0, #4
	subs	r1, #1
	cmp	r1, #0
	bge	.L0812D3CC
	cmp	r2, #0x13
	ble	.L0812D3B8
	pop	{r4}
	pop	{r0}
	bx	r0
.P0812D3E0:	.word gPlayers

@ ======================================================================================
@ playerReset   (0812D3E4)
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
@ playerTickAll   (0812D424)
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
.L0812D42A:
	lsls	r0, r6, #3
	adds	r0, r0, r6
	lsls	r0, r0, #3
	ldr	r1, .P0812D454	@ =gPlayers
	adds	r1, r0, r1
	adds	r0, r1, #0
	adds	r0, #0x42
	ldrb	r0, [r0]
	adds	r7, r6, #1
	cmp	r0, #0
	beq	.L0812D4A6
	ldrh	r2, [r1, #0x3a]
	cmp	r2, #0
	bne	.L0812D458
	cmp	r0, #2
	bne	.L0812D46E
	adds	r0, r6, #0
	bl	playerStop
	b	.L0812D4A6
	.hword 0x0000
.P0812D454:	.word gPlayers
.L0812D458:
	ldrh	r0, [r1, #0x36]
	ldrh	r3, [r1, #0x34]
	adds	r0, r0, r3
	strh	r0, [r1, #0x34]
	subs	r0, r2, #1
	strh	r0, [r1, #0x3a]
	lsls	r0, r0, #0x10
	cmp	r0, #0
	bne	.L0812D46E
	ldrh	r0, [r1, #0x38]
	strh	r0, [r1, #0x34]
.L0812D46E:
	movs	r2, #0
	adds	r7, r6, #1
	adds	r4, r1, #0
	adds	r4, #8
	movs	r5, #9
.L0812D478:
	ldr	r0, [r4]
	cmp	r0, #0
	beq	.L0812D494
	str	r2, [sp]
	bl	trackTick
	lsls	r0, r0, #0x18
	ldr	r2, [sp]
	cmp	r0, #0
	bne	.L0812D490
	movs	r2, #1
	b	.L0812D494
.L0812D490:
	movs	r0, #0
	str	r0, [r4]
.L0812D494:
	adds	r4, #4
	subs	r5, #1
	cmp	r5, #0
	bge	.L0812D478
	cmp	r2, #0
	bne	.L0812D4A6
	adds	r0, r6, #0
	bl	playerStop
.L0812D4A6:
	adds	r6, r7, #0
	cmp	r6, #0x13
	ble	.L0812D42A
	add	sp, #4
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ doPlaySong   (0812D4B4)
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
	ldr	r2, .P0812D4D8	@ =gCfg
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
.P0812D4D8:	.word gCfg

@ ======================================================================================
@ doPlaySfx   (0812D4DC)
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
	ldr	r2, .P0812D504	@ =gCfg
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
.P0812D504:	.word gCfg

@ ======================================================================================
@ playerStartSong   (0812D508)
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
	ldr	r1, .P0812D58C	@ =gPlayers
	adds	r5, r0, r1
	adds	r4, r5, #0
	adds	r4, #0x42
	ldrb	r0, [r4]
	cmp	r0, #0
	beq	.L0812D52E
	adds	r0, r3, #0
	bl	playerStop
.L0812D52E:
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
	bge	.L0812D57A
	adds	r4, r0, #0
.L0812D552:
	ldrh	r0, [r4]
	cmp	r0, #0
	beq	.L0812D572
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
.L0812D572:
	adds	r4, #2
	adds	r6, #1
	cmp	r6, r7
	blt	.L0812D552
.L0812D57A:
	movs	r0, #1
	mov	r1, r8
	strb	r0, [r1]
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0812D58C:	.word gPlayers

@ ======================================================================================
@ playerStartSfx   (0812D590)
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
	ldr	r1, .P0812D5F8	@ =gPlayers
	adds	r5, r0, r1
	movs	r0, #0x42
	adds	r0, r0, r5
	mov	r8, r0
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L0812D5BC
	adds	r0, r4, #0
	bl	playerStop
.L0812D5BC:
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
.P0812D5F8:	.word gPlayers

@ ======================================================================================
@ playerStop   (0812D5FC)
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
	ldr	r0, .P0812D634	@ =gPlayers
	adds	r1, r1, r0
	adds	r2, r1, #0
	adds	r2, #0x42
	ldrb	r0, [r2]
	cmp	r0, #0
	beq	.L0812D62E
	adds	r7, r2, #0
	movs	r6, #0
	adds	r4, r1, #0
	adds	r4, #8
	movs	r5, #9
.L0812D61C:
	ldr	r0, [r4]
	bl	trackStop
	stm	r4!, {r6}
	subs	r5, #1
	cmp	r5, #0
	bge	.L0812D61C
	movs	r0, #0
	strb	r0, [r7]
.L0812D62E:
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
.P0812D634:	.word gPlayers

@ ======================================================================================
@ playerFadeOut   (0812D638)
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
	ldr	r0, .P0812D66C	@ =gPlayers
	adds	r4, r1, r0
	adds	r2, r4, #0
	adds	r2, #0x42
	ldrb	r0, [r2]
	cmp	r0, #0
	beq	.L0812D666
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
.L0812D666:
	pop	{r4}
	pop	{r0}
	bx	r0
.P0812D66C:	.word gPlayers

@ ======================================================================================
@ playerSetPause   (0812D670)
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
	ldr	r3, .P0812D690	@ =gPlayers
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
.P0812D690:	.word gPlayers

@ ======================================================================================
@ sndGetPlayerState   (0812D694)
@
@   u32 sndGetPlayerState(u32 pl)       /* 0 idle, 1 playing, 2 fading out (read directly) */
@   {
@       return gPlayers[pl].state;
@   }
@ ======================================================================================
	.global sndGetPlayerState
	.thumb_func
sndGetPlayerState:
	ldr	r2, .P0812D6A4	@ =gPlayers
	lsls	r1, r0, #3
	adds	r1, r1, r0
	lsls	r1, r1, #3
	adds	r2, #0x42
	adds	r1, r1, r2
	ldrb	r0, [r1]
	bx	lr
.P0812D6A4:	.word gPlayers

@ ======================================================================================
@ cmdNext   (0812D6A8)
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
	ldr	r2, .P0812D6C4	@ =gCmdWrite
	ldr	r0, [r2]
	adds	r0, #0xc
	str	r0, [r2]
	ldr	r1, .P0812D6C8	@ =gCmdEnd
	ldr	r1, [r1]
	cmp	r0, r1
	bne	.L0812D6BE
	ldr	r0, .P0812D6CC	@ =gCmdQueue
	str	r0, [r2]
.L0812D6BE:
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0812D6C4:	.word gCmdWrite
.P0812D6C8:	.word gCmdEnd
.P0812D6CC:	.word gCmdQueue

@ ======================================================================================
@ cmdInit   (0812D6D0)
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
	ldr	r0, .P0812D6F4	@ =gCmdRead
	ldr	r1, .P0812D6F8	@ =gCmdQueue
	str	r1, [r0]
	ldr	r0, .P0812D6FC	@ =gCmdWrite
	str	r1, [r0]
	ldr	r0, .P0812D700	@ =gCmdCommitted
	str	r1, [r0]
	ldr	r0, .P0812D704	@ =gCmdEnd
	movs	r2, #0x8a
	lsls	r2, r2, #2
	adds	r1, r1, r2
	str	r1, [r0]
	ldr	r0, .P0812D708	@ =gHookNote
	movs	r1, #0
	str	r1, [r0]
	ldr	r0, .P0812D70C	@ =gHookCA
	str	r1, [r0]
	bx	lr
.P0812D6F4:	.word gCmdRead
.P0812D6F8:	.word gCmdQueue
.P0812D6FC:	.word gCmdWrite
.P0812D700:	.word gCmdCommitted
.P0812D704:	.word gCmdEnd
.P0812D708:	.word gHookNote
.P0812D70C:	.word gHookCA

@ ======================================================================================
@ cmdPop   (0812D710)
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
	ldr	r3, .P0812D724	@ =gCmdRead
	ldr	r2, [r3]
	ldr	r0, .P0812D728	@ =gCmdCommitted
	ldr	r0, [r0]
	cmp	r2, r0
	bne	.L0812D72C
	movs	r0, #0
	b	.L0812D740
	.hword 0x0000
.P0812D724:	.word gCmdRead
.P0812D728:	.word gCmdCommitted
.L0812D72C:
	adds	r0, r2, #0
	adds	r0, #0xc
	str	r0, [r3]
	ldr	r1, .P0812D744	@ =gCmdEnd
	ldr	r1, [r1]
	cmp	r0, r1
	bne	.L0812D73E
	ldr	r0, .P0812D748	@ =gCmdQueue
	str	r0, [r3]
.L0812D73E:
	adds	r0, r2, #0
.L0812D740:
	pop	{r1}
	bx	r1
.P0812D744:	.word gCmdEnd
.P0812D748:	.word gCmdQueue

@ ======================================================================================
@ sndCommit   (0812D74C)
@
@   void sndCommit(void)                /* make the commands queued since the last call visible */
@   {
@       gCmdCommitted = gCmdWrite;      /* no overflow check: 47 queued commands lose 46         */
@   }
@ ======================================================================================
	.global sndCommit
	.thumb_func
sndCommit:
	ldr	r0, .P0812D758	@ =gCmdCommitted
	ldr	r1, .P0812D75C	@ =gCmdWrite
	ldr	r1, [r1]
	str	r1, [r0]
	bx	lr
	.hword 0x0000
.P0812D758:	.word gCmdCommitted
.P0812D75C:	.word gCmdWrite

@ ======================================================================================
@ sndPlaySong   (0812D760)
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
	ldr	r2, .P0812D780	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #0
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0812D780:	.word gCmdWrite

@ ======================================================================================
@ sndPlaySfx   (0812D784)
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
	ldr	r3, .P0812D7A8	@ =gCmdWrite
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
.P0812D7A8:	.word gCmdWrite

@ ======================================================================================
@ sndFadeOut   (0812D7AC)
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
	ldr	r2, .P0812D7CC	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #2
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0812D7CC:	.word gCmdWrite

@ ======================================================================================
@ sndPause   (0812D7D0)
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
	ldr	r2, .P0812D7F0	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #3
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0812D7F0:	.word gCmdWrite

@ ======================================================================================
@ sndFadeOutMask   (0812D7F4)
@
@   void sndFadeOutMask(u32 mask, u32 frames)      { queue(0x200, frames, mask); }
@ ======================================================================================
	.global sndFadeOutMask
	.thumb_func
sndFadeOutMask:
	push	{lr}
	lsls	r1, r1, #0x10
	lsrs	r1, r1, #0x10
	ldr	r2, .P0812D810	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #0x80
	lsls	r3, r3, #2
	strh	r3, [r2]
	str	r1, [r2, #4]
	str	r0, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
.P0812D810:	.word gCmdWrite

@ ======================================================================================
@ sndPauseMask   (0812D814)
@
@   void sndPauseMask(u32 mask, u32 on)            { queue(0x201, on, mask); }
@ ======================================================================================
	.global sndPauseMask
	.thumb_func
sndPauseMask:
	push	{lr}
	lsls	r1, r1, #0x18
	lsrs	r1, r1, #0x18
	ldr	r2, .P0812D830	@ =gCmdWrite
	ldr	r2, [r2]
	ldr	r3, .P0812D834	@ =0x00000201
	strh	r3, [r2]
	str	r1, [r2, #4]
	str	r0, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0812D830:	.word gCmdWrite
.P0812D834:	.word 0x00000201

@ ======================================================================================
@ sndSetTempo   (0812D838)
@
@   void sndSetTempo(u32 pl, s32 ofs)              { queue(0x004, pl, ofs); }   /* tempo offset   */
@ ======================================================================================
	.global sndSetTempo
	.thumb_func
sndSetTempo:
	push	{lr}
	lsls	r0, r0, #0x10
	lsrs	r0, r0, #0x10
	ldr	r2, .P0812D858	@ =gCmdWrite
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
.P0812D858:	.word gCmdWrite

@ ======================================================================================
@ sndSetVolume2   (0812D85C)
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
	ldr	r2, .P0812D87C	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #5
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0812D87C:	.word gCmdWrite

@ ======================================================================================
@ sndSetHookFlags   (0812D880)
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
	ldr	r2, .P0812D8A0	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #6
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0812D8A0:	.word gCmdWrite

@ ======================================================================================
@ sndMuteTracks   (0812D8A4)
@
@   void sndMuteTracks(u32 pl, u32 mask, u32 on)   { queue(0x100, pl << 16 | on, mask); }
@ ======================================================================================
	.global sndMuteTracks
	.thumb_func
sndMuteTracks:
	push	{r4, lr}
	lsls	r2, r2, #0x18
	lsrs	r2, r2, #0x18
	ldr	r3, .P0812D8C8	@ =gCmdWrite
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
.P0812D8C8:	.word gCmdWrite

@ ======================================================================================
@ sndSetTrackExpr   (0812D8CC)
@
@   void sndSetTrackExpr(u32 pl, u32 mask, u32 v)  { queue(0x102, pl << 16 | v, mask); }
@ ======================================================================================
	.global sndSetTrackExpr
	.thumb_func
sndSetTrackExpr:
	push	{r4, lr}
	lsls	r2, r2, #0x18
	lsrs	r2, r2, #0x18
	ldr	r3, .P0812D8F0	@ =gCmdWrite
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
.P0812D8F0:	.word gCmdWrite

@ ======================================================================================
@ sndSetTrackBend   (0812D8F4)
@
@   void sndSetTrackBend(u32 pl, u32 mask, u32 range, u32 bend) { queue(0x103, pl << 16 | range << 8 | bend, mask); }
@ ======================================================================================
	.global sndSetTrackBend
	.thumb_func
sndSetTrackBend:
	push	{r4, r5, lr}
	lsls	r0, r0, #0x10
	lsls	r2, r2, #0x18
	ldr	r4, .P0812D91C	@ =gCmdWrite
	ldr	r5, [r4]
	ldr	r4, .P0812D920	@ =0x00000103
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
.P0812D91C:	.word gCmdWrite
.P0812D920:	.word 0x00000103

@ ======================================================================================
@ sndSetTrackPan   (0812D924)
@
@   void sndSetTrackPan(u32 pl, u32 mask, u32 pan) { queue(0x101, pl << 16 | pan, mask); }
@ ======================================================================================
	.global sndSetTrackPan
	.thumb_func
sndSetTrackPan:
	push	{r4, lr}
	lsls	r2, r2, #0x18
	lsrs	r2, r2, #0x18
	ldr	r3, .P0812D944	@ =gCmdWrite
	ldr	r4, [r3]
	ldr	r3, .P0812D948	@ =0x00000101
	strh	r3, [r4]
	lsls	r0, r0, #0x10
	orrs	r0, r2
	str	r0, [r4, #4]
	str	r1, [r4, #8]
	bl	cmdNext
	pop	{r4}
	pop	{r0}
	bx	r0
.P0812D944:	.word gCmdWrite
.P0812D948:	.word 0x00000101

@ ======================================================================================
@ sndSetEcho   (0812D94C)
@
@   void sndSetEcho(u32 shift)                     { queue(0x300, shift); }     /* 16 = off       */
@ ======================================================================================
	.global sndSetEcho
	.thumb_func
sndSetEcho:
	push	{lr}
	lsls	r0, r0, #0x18
	lsrs	r0, r0, #0x18
	ldr	r1, .P0812D968	@ =gCmdWrite
	ldr	r2, [r1]
	movs	r1, #0xc0
	lsls	r1, r1, #2
	strh	r1, [r2]
	str	r0, [r2, #4]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0812D968:	.word gCmdWrite

@ ======================================================================================
@ sndSetVoices   (0812D96C)
@
@   void sndSetVoices(u32 n)                       { queue(0x304, n); }
@ ======================================================================================
	.global sndSetVoices
	.thumb_func
sndSetVoices:
	push	{lr}
	lsls	r0, r0, #0x18
	lsrs	r0, r0, #0x18
	ldr	r1, .P0812D988	@ =gCmdWrite
	ldr	r2, [r1]
	movs	r1, #0xc1
	lsls	r1, r1, #2
	strh	r1, [r2]
	str	r0, [r2, #4]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0812D988:	.word gCmdWrite

@ ======================================================================================
@ sndCallback   (0812D98C)
@
@   void sndCallback(void (*fn)(u32), u32 arg)     { queue(0x301, fn, arg); }   /* run fn(arg) in sndMain */
@ ======================================================================================
	.global sndCallback
	.thumb_func
sndCallback:
	push	{lr}
	ldr	r2, .P0812D9A4	@ =gCmdWrite
	ldr	r2, [r2]
	ldr	r3, .P0812D9A8	@ =0x00000301
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0812D9A4:	.word gCmdWrite
.P0812D9A8:	.word 0x00000301

@ ======================================================================================
@ sndSetHookCA   (0812D9AC)
@
@   void sndSetHookCA(void *fn)                    { queue(0x302, fn); }
@ ======================================================================================
	.global sndSetHookCA
	.thumb_func
sndSetHookCA:
	push	{lr}
	ldr	r1, .P0812D9C0	@ =gCmdWrite
	ldr	r2, [r1]
	ldr	r1, .P0812D9C4	@ =0x00000302
	strh	r1, [r2]
	str	r0, [r2, #4]
	bl	cmdNext
	pop	{r0}
	bx	r0
.P0812D9C0:	.word gCmdWrite
.P0812D9C4:	.word 0x00000302

@ ======================================================================================
@ sndSetHookNote   (0812D9C8)
@
@   void sndSetHookNote(void *fn)                  { queue(0x303, fn); }
@ ======================================================================================
	.global sndSetHookNote
	.thumb_func
sndSetHookNote:
	push	{lr}
	ldr	r1, .P0812D9DC	@ =gCmdWrite
	ldr	r2, [r1]
	ldr	r1, .P0812D9E0	@ =0x00000303
	strh	r1, [r2]
	str	r0, [r2, #4]
	bl	cmdNext
	pop	{r0}
	bx	r0
.P0812D9DC:	.word gCmdWrite
.P0812D9E0:	.word 0x00000303

@ ======================================================================================
@ cmdPlayer   (0812D9E4)
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
	ldr	r0, .P0812DA04	@ =gPlayers
	adds	r2, r1, r0
	ldrh	r0, [r3]
	cmp	r0, #6
	bhi	.L0812DA72
	lsls	r0, r0, #2
	ldr	r1, .P0812DA08	@ =0x0812DA0C
	adds	r0, r0, r1
	ldr	r0, [r0]
	mov	pc, r0
.P0812DA04:	.word gPlayers
.P0812DA08:	.word 0x0812DA0C
	.word .L0812DA28
	.word .L0812DA32
	.word .L0812DA48
	.word .L0812DA52
	.word .L0812DA64
	.word .L0812DA6A
	.word .L0812DA5C
.L0812DA28:
	ldr	r0, [r3, #4]
	ldr	r1, [r3, #8]
	bl	doPlaySong
	b	.L0812DA72
.L0812DA32:
	ldr	r1, [r3, #4]
	lsrs	r0, r1, #0x10
	ldr	r2, .P0812DA44	@ =0x0000FFFF
	ands	r1, r2
	ldr	r2, [r3, #8]
	bl	doPlaySfx
	b	.L0812DA72
	.hword 0x0000
.P0812DA44:	.word 0x0000FFFF
.L0812DA48:
	ldr	r0, [r3, #4]
	ldr	r1, [r3, #8]
	bl	playerFadeOut
	b	.L0812DA72
.L0812DA52:
	ldr	r0, [r3, #4]
	ldrb	r1, [r3, #8]
	bl	playerSetPause
	b	.L0812DA72
.L0812DA5C:
	ldr	r1, [r3, #8]
	adds	r0, r2, #0
	adds	r0, #0x44
	b	.L0812DA70
.L0812DA64:
	ldr	r0, [r3, #8]
	strh	r0, [r2, #0x32]
	b	.L0812DA72
.L0812DA6A:
	ldr	r1, [r3, #8]
	adds	r0, r2, #0
	adds	r0, #0x41
.L0812DA70:
	strb	r1, [r0]
.L0812DA72:
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ cmdTrack   (0812DA78)
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
	ldr	r0, .P0812DAA0	@ =gPlayers
	adds	r1, r1, r0
	movs	r5, #0
	ldrh	r2, [r3]
	ldr	r0, .P0812DAA4	@ =0x00000101
	cmp	r2, r0
	beq	.L0812DB5C
	cmp	r2, r0
	bgt	.L0812DAA8
	subs	r0, #1
	cmp	r2, r0
	beq	.L0812DAB8
	b	.L0812DB8C
.P0812DAA0:	.word gPlayers
.P0812DAA4:	.word 0x00000101
.L0812DAA8:
	movs	r0, #0x81
	lsls	r0, r0, #1
	cmp	r2, r0
	beq	.L0812DAEA
	adds	r0, #1
	cmp	r2, r0
	beq	.L0812DB1C
	b	.L0812DB8C
.L0812DAB8:
	lsls	r0, r4, #0x18
	lsrs	r2, r0, #0x18
	ldr	r0, [r3, #8]
	cmp	r0, #0
	beq	.L0812DB8C
	movs	r4, #1
	adds	r1, #8
.L0812DAC6:
	ands	r0, r4
	cmp	r0, #0
	beq	.L0812DAD6
	ldr	r0, [r1]
	cmp	r0, #0
	beq	.L0812DAD6
	adds	r0, #0x4a
	strb	r2, [r0]
.L0812DAD6:
	adds	r1, #4
	adds	r5, #1
	ldr	r0, [r3, #8]
	lsrs	r0, r0, #1
	str	r0, [r3, #8]
	cmp	r0, #0
	beq	.L0812DB8C
	cmp	r5, #9
	ble	.L0812DAC6
	b	.L0812DB8C
.L0812DAEA:
	lsls	r0, r4, #0x18
	lsrs	r2, r0, #0x18
	ldr	r0, [r3, #8]
	cmp	r0, #0
	beq	.L0812DB8C
	movs	r4, #1
	adds	r1, #8
.L0812DAF8:
	ands	r0, r4
	cmp	r0, #0
	beq	.L0812DB08
	ldr	r0, [r1]
	cmp	r0, #0
	beq	.L0812DB08
	adds	r0, #0x4e
	strb	r2, [r0]
.L0812DB08:
	adds	r1, #4
	adds	r5, #1
	ldr	r0, [r3, #8]
	lsrs	r0, r0, #1
	str	r0, [r3, #8]
	cmp	r0, #0
	beq	.L0812DB8C
	cmp	r5, #9
	ble	.L0812DAF8
	b	.L0812DB8C
.L0812DB1C:
	movs	r0, #0xff
	lsls	r0, r0, #8
	ands	r0, r4
	lsrs	r2, r0, #8
	lsls	r0, r4, #0x18
	lsrs	r4, r0, #0x18
	ldr	r0, [r3, #8]
	cmp	r0, #0
	beq	.L0812DB8C
	movs	r6, #1
	adds	r1, #8
.L0812DB32:
	ands	r0, r6
	cmp	r0, #0
	beq	.L0812DB48
	ldr	r0, [r1]
	cmp	r0, #0
	beq	.L0812DB48
	adds	r0, #0x50
	strb	r2, [r0]
	ldr	r0, [r1]
	adds	r0, #0x4f
	strb	r4, [r0]
.L0812DB48:
	adds	r1, #4
	adds	r5, #1
	ldr	r0, [r3, #8]
	lsrs	r0, r0, #1
	str	r0, [r3, #8]
	cmp	r0, #0
	beq	.L0812DB8C
	cmp	r5, #9
	ble	.L0812DB32
	b	.L0812DB8C
.L0812DB5C:
	lsls	r0, r4, #0x18
	lsrs	r2, r0, #0x18
	ldr	r0, [r3, #8]
	cmp	r0, #0
	beq	.L0812DB8C
	movs	r4, #1
	adds	r1, #8
.L0812DB6A:
	ands	r0, r4
	cmp	r0, #0
	beq	.L0812DB7A
	ldr	r0, [r1]
	cmp	r0, #0
	beq	.L0812DB7A
	adds	r0, #0x4b
	strb	r2, [r0]
.L0812DB7A:
	adds	r1, #4
	adds	r5, #1
	ldr	r0, [r3, #8]
	lsrs	r0, r0, #1
	str	r0, [r3, #8]
	cmp	r0, #0
	beq	.L0812DB8C
	cmp	r5, #9
	ble	.L0812DB6A
.L0812DB8C:
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ cmdMask   (0812DB94)
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
	beq	.L0812DBAC
	adds	r0, #1
	cmp	r1, r0
	beq	.L0812DBD6
	b	.L0812DBFE
.L0812DBAC:
	ldr	r1, [r4, #8]
	cmp	r1, #0
	beq	.L0812DBFE
.L0812DBB2:
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0812DBC2
	ldr	r1, [r4, #4]
	adds	r0, r5, #0
	bl	playerFadeOut
.L0812DBC2:
	adds	r5, #1
	ldr	r0, [r4, #8]
	lsrs	r0, r0, #1
	str	r0, [r4, #8]
	adds	r1, r0, #0
	cmp	r1, #0
	beq	.L0812DBFE
	cmp	r5, #0x13
	ble	.L0812DBB2
	b	.L0812DBFE
.L0812DBD6:
	ldr	r1, [r4, #8]
	cmp	r1, #0
	beq	.L0812DBFE
.L0812DBDC:
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0812DBEC
	ldrb	r1, [r4, #4]
	adds	r0, r5, #0
	bl	playerSetPause
.L0812DBEC:
	adds	r5, #1
	ldr	r0, [r4, #8]
	lsrs	r0, r0, #1
	str	r0, [r4, #8]
	adds	r1, r0, #0
	cmp	r1, #0
	beq	.L0812DBFE
	cmp	r5, #0x13
	ble	.L0812DBDC
.L0812DBFE:
	pop	{r4, r5}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ cmdGlobal   (0812DC04)
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
	ldr	r1, .P0812DC1C	@ =0xFFFFFD00
	adds	r0, r0, r1
	cmp	r0, #4
	bhi	.L0812DC66
	lsls	r0, r0, #2
	ldr	r1, .P0812DC20	@ =0x0812DC24
	adds	r0, r0, r1
	ldr	r0, [r0]
	mov	pc, r0
.P0812DC1C:	.word 0xFFFFFD00
.P0812DC20:	.word 0x0812DC24
	.word .L0812DC58
	.word .L0812DC38
	.word .L0812DC42
	.word .L0812DC4C
	.word .L0812DC60
.L0812DC38:
	ldr	r0, [r2, #8]
	ldr	r1, [r2, #4]
	bl	_call_via_r1
	b	.L0812DC66
.L0812DC42:
	ldr	r1, .P0812DC48	@ =gHookCA
	b	.L0812DC4E
	.hword 0x0000
.P0812DC48:	.word gHookCA
.L0812DC4C:
	ldr	r1, .P0812DC54	@ =gHookNote
.L0812DC4E:
	ldr	r0, [r2, #4]
	str	r0, [r1]
	b	.L0812DC66
.P0812DC54:	.word gHookNote
.L0812DC58:
	ldrb	r0, [r2, #4]
	bl	echoSetFeedback
	b	.L0812DC66
.L0812DC60:
	ldrb	r0, [r2, #4]
	bl	voiceSetCount
.L0812DC66:
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ cmdProcess   (0812DC6C)
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
	beq	.L0812DC94
	ldr	r4, .P0812DC9C	@ =kCmdHandlers
.L0812DC7A:
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
	bne	.L0812DC7A
.L0812DC94:
	pop	{r4}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0812DC9C:	.word kCmdHandlers
	.arm

@ ======================================================================================
@ armDownmix   (0812DCA0)
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
.L0812DCB0:
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
	bne	.L0812DCB0
	pop	{r4, r5}
	bx	lr

@ ======================================================================================
@ armMixVoice   (0812DDC0)
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
	bne	.L0812DE80
.L0812DDDC:
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
	blo	.L0812DDDC
	mov	r0, r4
	pop	{r4, r5, r6, r7, r8}
	bx	lr
.L0812DE80:
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
	blo	.L0812DE80
	mov	r0, r4
	pop	{r4, r5, r6, r7, r8}
	bx	lr

@ ======================================================================================
@ armEcho   (0812DEB8)
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
.L0812DEC8:
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
	blo	.L0812DEC8
	pop	{r4, r5}
	bx	lr
