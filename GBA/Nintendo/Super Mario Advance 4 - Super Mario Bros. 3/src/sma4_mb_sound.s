@ --------------------------------------------------------------------------------------
@ sma4_mb_sound.s - sound driver of Super Mario Advance 4 (E) v1.0, Mario Bros. multiboot image
@ Thumb code 0201BF78-0201E384, ARM mixing loops 0201E384-0201E63C (copied to IWRAM by sndInit).
@ Generated from the ROM by gen_sources.py; names and comments from the analysis.
@ The pseudo-C above each function describes the Super Mario Advance 4 build; where this
@ build differs, the difference is given after "In this build".
@ Rebuilds byte-identical: see Makefile.
@ --------------------------------------------------------------------------------------
	.syntax unified
	.include "nsnd.inc"
	.include "sma4_mb_ram.inc"
	.section .snd_code, "ax"
	.thumb

@ ======================================================================================
@ sndInit   (0201BF78)
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
@
@   In this build: Same, but there is no echo: gEchoHistory is not set up.
@ ======================================================================================
	.global sndInit
	.thumb_func
sndInit:
	push	{r4, r5, lr}
	ldr	r1, .P0201C000	@ =gCfg
	str	r0, [r1]
	ldr	r1, .P0201C004	@ =REG_SOUNDCNT_X
	movs	r0, #0
	strb	r0, [r1]
	movs	r0, #0x80
	strb	r0, [r1]
	subs	r1, #4
	ldr	r2, .P0201C008	@ =0x0000FF77
	adds	r0, r2, #0
	strh	r0, [r1]
	adds	r1, #2
	movs	r0, #0xd
	strb	r0, [r1]
	ldr	r2, .P0201C00C	@ =REG_SOUNDBIAS
	ldrh	r1, [r2]
	ldr	r0, .P0201C010	@ =0x00003FFF
	ands	r0, r1
	movs	r3, #0x80
	lsls	r3, r3, #7
	adds	r1, r3, #0
	orrs	r0, r1
	strh	r0, [r2]
	ldr	r1, .P0201C014	@ =REG_NR10
	movs	r0, #8
	strh	r0, [r1]
	adds	r1, #2
	movs	r2, #0xf0
	lsls	r2, r2, #8
	adds	r0, r2, #0
	strh	r0, [r1]
	ldr	r5, .P0201C018	@ =armDownmix
	ldr	r4, .P0201C01C	@ =gIwramCode
	adds	r0, r5, #0
	adds	r1, r4, #0
	movs	r2, #0xd8
	bl	CpuFastSet
	ldr	r0, .P0201C020	@ =gFnDownmix
	str	r4, [r0]
	ldr	r1, .P0201C024	@ =gFnMixVoice
	ldr	r0, .P0201C028	@ =armMixVoice
	subs	r0, r0, r5
	adds	r0, r0, r4
	str	r0, [r1]
	ldr	r1, .P0201C02C	@ =gFnEcho
	ldr	r0, .P0201C030	@ =armEcho
	subs	r0, r0, r5
	adds	r0, r0, r4
	str	r0, [r1]
	ldr	r0, .P0201C034	@ =gDmaBuffers
	bl	mixInit
	bl	cmdInit
	bl	kitInstInit
	bl	voiceInitAll
	bl	trackInitAll
	bl	playerInitAll
	pop	{r4, r5}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201C000:	.word gCfg
.P0201C004:	.word REG_SOUNDCNT_X
.P0201C008:	.word 0x0000FF77
.P0201C00C:	.word REG_SOUNDBIAS
.P0201C010:	.word 0x00003FFF
.P0201C014:	.word REG_NR10
.P0201C018:	.word armDownmix
.P0201C01C:	.word gIwramCode
.P0201C020:	.word gFnDownmix
.P0201C024:	.word gFnMixVoice
.P0201C028:	.word armMixVoice
.P0201C02C:	.word gFnEcho
.P0201C030:	.word armEcho
.P0201C034:	.word gDmaBuffers

@ ======================================================================================
@ sndVSync   (0201C038)
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
@ sndMain   (0201C044)
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
	ldr	r0, .P0201C064	@ =gMixEnabled
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L0201C05E
	bl	mixFrame
.L0201C05E:
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201C064:	.word gMixEnabled

@ ======================================================================================
@ mixInit   (0201C068)
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
@   In this build: Same, but nothing is cleared (no echo history; the DMA buffer is not cleared either).
@ ======================================================================================
	.global mixInit
	.thumb_func
mixInit:
	push	{r4, lr}
	sub	sp, #4
	adds	r3, r0, #0
	ldr	r1, .P0201C0B8	@ =gMixEnabled
	movs	r0, #1
	strb	r0, [r1]
	ldr	r1, .P0201C0BC	@ =gDmaBufA
	str	r3, [r1]
	ldr	r2, .P0201C0C0	@ =gDmaBufB
	adds	r0, r3, #0
	adds	r0, #0xb0
	str	r0, [r2]
	movs	r4, #0xb0
	lsls	r4, r4, #1
	adds	r0, r3, r4
	str	r0, [r1, #4]
	movs	r1, #0x84
	lsls	r1, r1, #2
	adds	r0, r3, r1
	str	r0, [r2, #4]
	ldr	r1, .P0201C0C4	@ =gTimerReload
	ldr	r2, .P0201C0C8	@ =0x0000F9C4
	adds	r0, r2, #0
	strh	r0, [r1]
	ldr	r1, .P0201C0CC	@ =gDmaBufIdx
	movs	r0, #0
	strb	r0, [r1]
	ldr	r1, .P0201C0D0	@ =REG_SOUNDCNT_H+1
	movs	r0, #0x9a
	strb	r0, [r1]
	ldr	r0, .P0201C0D4	@ =REG_FIFO_A
	movs	r1, #0
	str	r1, [r0]
	adds	r0, #4
	str	r1, [r0]
	add	sp, #4
	pop	{r4}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201C0B8:	.word gMixEnabled
.P0201C0BC:	.word gDmaBufA
.P0201C0C0:	.word gDmaBufB
.P0201C0C4:	.word gTimerReload
.P0201C0C8:	.word 0x0000F9C4
.P0201C0CC:	.word gDmaBufIdx
.P0201C0D0:	.word REG_SOUNDCNT_H+1
.P0201C0D4:	.word REG_FIFO_A

@ ======================================================================================
@ mixDmaRestart   (0201C0D8)
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
	ldr	r2, .P0201C154	@ =REG_TM0CNT
	ldr	r0, .P0201C158	@ =gTimerReload
	ldrh	r0, [r0]
	movs	r1, #0x80
	lsls	r1, r1, #0x10
	orrs	r0, r1
	str	r0, [r2]
	ldr	r0, .P0201C15C	@ =gMixEnabled
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L0201C14C
	ldr	r4, .P0201C160	@ =REG_DMA1SAD
	ldrh	r1, [r4, #0xa]
	ldr	r2, .P0201C164	@ =0x0000C5FF
	adds	r0, r2, #0
	ands	r0, r1
	strh	r0, [r4, #0xa]
	ldrh	r3, [r4, #0xa]
	ldr	r1, .P0201C168	@ =0x00007FFF
	adds	r0, r1, #0
	ands	r0, r3
	strh	r0, [r4, #0xa]
	ldrh	r0, [r4, #0xa]
	ldr	r3, .P0201C16C	@ =REG_DMA2SAD
	ldrh	r0, [r3, #0xa]
	ands	r2, r0
	strh	r2, [r3, #0xa]
	ldrh	r0, [r3, #0xa]
	ands	r1, r0
	strh	r1, [r3, #0xa]
	ldrh	r0, [r3, #0xa]
	ldr	r1, .P0201C170	@ =gDmaBufA
	ldr	r2, .P0201C174	@ =gDmaBufIdx
	ldrb	r0, [r2]
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r0, [r0]
	str	r0, [r4]
	ldr	r0, .P0201C178	@ =REG_FIFO_A
	str	r0, [r4, #4]
	ldr	r5, .P0201C17C	@ =0xB6400004
	str	r5, [r4, #8]
	ldr	r0, [r4, #8]
	ldr	r1, .P0201C180	@ =gDmaBufB
	ldrb	r0, [r2]
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r0, [r0]
	str	r0, [r3]
	ldr	r0, .P0201C184	@ =REG_FIFO_B
	str	r0, [r3, #4]
	str	r5, [r3, #8]
	ldr	r0, [r3, #8]
	ldrb	r1, [r2]
	movs	r0, #1
	subs	r0, r0, r1
	strb	r0, [r2]
.L0201C14C:
	pop	{r4, r5}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201C154:	.word REG_TM0CNT
.P0201C158:	.word gTimerReload
.P0201C15C:	.word gMixEnabled
.P0201C160:	.word REG_DMA1SAD
.P0201C164:	.word 0x0000C5FF
.P0201C168:	.word 0x00007FFF
.P0201C16C:	.word REG_DMA2SAD
.P0201C170:	.word gDmaBufA
.P0201C174:	.word gDmaBufIdx
.P0201C178:	.word REG_FIFO_A
.P0201C17C:	.word 0xB6400004
.P0201C180:	.word gDmaBufB
.P0201C184:	.word REG_FIFO_B

@ ======================================================================================
@ sndStopOutput   (0201C188)
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
	ldr	r1, .P0201C1C0	@ =gMixEnabled
	movs	r0, #0
	strb	r0, [r1]
	ldr	r1, .P0201C1C4	@ =REG_DMA1SAD
	ldrh	r2, [r1, #0xa]
	ldr	r3, .P0201C1C8	@ =0x0000C5FF
	adds	r0, r3, #0
	ands	r0, r2
	strh	r0, [r1, #0xa]
	ldrh	r4, [r1, #0xa]
	ldr	r2, .P0201C1CC	@ =0x00007FFF
	adds	r0, r2, #0
	ands	r0, r4
	strh	r0, [r1, #0xa]
	ldrh	r0, [r1, #0xa]
	ldr	r0, .P0201C1D0	@ =REG_DMA2SAD
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
.P0201C1C0:	.word gMixEnabled
.P0201C1C4:	.word REG_DMA1SAD
.P0201C1C8:	.word 0x0000C5FF
.P0201C1CC:	.word 0x00007FFF
.P0201C1D0:	.word REG_DMA2SAD

@ ======================================================================================
@ sndStartOutput   (0201C1D4)
@
@   void sndStartOutput(void)
@   {
@       gMixEnabled = 1;        /* DMA restarts at the next sndVSync */
@   }
@ ======================================================================================
	.global sndStartOutput
	.thumb_func
sndStartOutput:
	ldr	r1, .P0201C1DC	@ =gMixEnabled
	movs	r0, #1
	strb	r0, [r1]
	bx	lr
.P0201C1DC:	.word gMixEnabled

@ ======================================================================================
@ mixVoice   (0201C1E0)
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
@   In this build: As in SMA4, but there is no wet bus: every voice goes to gMixDry.
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
	mov	sb, r1
	movs	r0, #0
	mov	r8, r0
	movs	r1, #0xb0
	mov	sl, r1
	ldr	r2, [sp, #0x10]
	ldr	r1, [r2, #0x5c]
	adds	r0, r1, #0
	adds	r0, #0x10
	str	r0, [sp, #0x20]
	ldr	r2, .P0201C24C	@ =gMixDry
	str	r2, [sp, #0x14]
	movs	r0, #0xb0
	lsls	r0, r0, #1
	adds	r0, r2, r0
	str	r0, [sp, #0x18]
	movs	r0, #0x7f
	subs	r0, r0, r3
	mov	r2, sb
	muls	r2, r0, r2
	adds	r0, r2, #0
	lsls	r0, r0, #0x10
	lsrs	r0, r0, #0x18
	str	r0, [sp, #0x1c]
	mov	r0, sb
	muls	r0, r3, r0
	lsls	r0, r0, #0x10
	lsrs	r0, r0, #0x18
	mov	sb, r0
	ldr	r7, [r1, #0xc]
	cmp	r7, #0
	bne	.L0201C23C
	ldr	r7, [r1]
.L0201C23C:
	mov	r0, sl
	muls	r0, r6, r0
	adds	r0, r4, r0
	lsrs	r0, r0, #8
	cmp	r0, r7
	bhs	.L0201C250
	ldr	r5, [sp, #0x18]
	b	.L0201C268
.P0201C24C:	.word gMixDry
.L0201C250:
	lsls	r0, r7, #8
	subs	r0, r0, r4
	subs	r0, #1
	adds	r0, r0, r6
	adds	r1, r6, #0
	bl	Div
	lsls	r0, r0, #1
	ldr	r1, [sp, #0x14]
	adds	r5, r0, r1
	movs	r2, #1
	mov	r8, r2
.L0201C268:
	ldr	r1, [sp, #0x10]
	ldr	r0, [r1, #0x5c]
	ldr	r1, [r0, #0xc]
	cmp	r1, #0
	beq	.L0201C278
	mov	r2, r8
	cmp	r2, #0
	bne	.L0201C2A4
.L0201C278:
	ldr	r0, .P0201C2A0	@ =gFnMixVoice
	str	r4, [sp]
	str	r6, [sp, #4]
	ldr	r1, [sp, #0x1c]
	str	r1, [sp, #8]
	mov	r2, sb
	str	r2, [sp, #0xc]
	ldr	r4, [r0]
	ldr	r0, [sp, #0x20]
	ldr	r1, [sp, #0x14]
	ldr	r2, [sp, #0x18]
	adds	r3, r5, #0
	bl	_call_via_r4
	adds	r4, r0, #0
	mov	r0, r8
	cmp	r0, #0
	beq	.L0201C352
	movs	r0, #1
	b	.L0201C358
.P0201C2A0:	.word gFnMixVoice
.L0201C2A4:
	ldr	r0, [r0, #8]
	subs	r1, r1, r0
	lsls	r1, r1, #8
	str	r1, [sp, #0x24]
	ldr	r1, .P0201C300	@ =gFnMixVoice
	str	r4, [sp]
	str	r6, [sp, #4]
	ldr	r2, [sp, #0x1c]
	str	r2, [sp, #8]
	mov	r0, sb
	str	r0, [sp, #0xc]
	ldr	r4, [r1]
	ldr	r0, [sp, #0x20]
	ldr	r1, [sp, #0x14]
	ldr	r2, [sp, #0x18]
	adds	r3, r5, #0
	bl	_call_via_r4
	adds	r4, r0, #0
	ldr	r1, [sp, #0x24]
	subs	r4, r4, r1
	ldr	r2, [sp, #0x14]
	subs	r0, r5, r2
	asrs	r0, r0, #1
	mov	r1, sl
	subs	r1, r1, r0
	mov	sl, r1
	cmp	r1, #0
	beq	.L0201C352
.L0201C2DE:
	str	r5, [sp, #0x14]
	movs	r2, #0xb0
	lsls	r2, r2, #1
	adds	r2, r5, r2
	str	r2, [sp, #0x18]
	mov	r0, sl
	muls	r0, r6, r0
	adds	r0, r4, r0
	lsrs	r0, r0, #8
	cmp	r0, r7
	bhs	.L0201C304
	mov	r1, sl
	lsls	r0, r1, #1
	adds	r5, r5, r0
	movs	r2, #0
	mov	r8, r2
	b	.L0201C31A
.P0201C300:	.word gFnMixVoice
.L0201C304:
	lsls	r0, r7, #8
	subs	r0, r0, r4
	subs	r0, #1
	adds	r0, r0, r6
	adds	r1, r6, #0
	bl	Div
	lsls	r0, r0, #1
	adds	r5, r5, r0
	movs	r0, #1
	mov	r8, r0
.L0201C31A:
	str	r4, [sp]
	str	r6, [sp, #4]
	ldr	r1, [sp, #0x1c]
	str	r1, [sp, #8]
	mov	r2, sb
	str	r2, [sp, #0xc]
	ldr	r0, .P0201C368	@ =gFnMixVoice
	ldr	r4, [r0]
	ldr	r0, [sp, #0x20]
	ldr	r1, [sp, #0x14]
	ldr	r2, [sp, #0x18]
	adds	r3, r5, #0
	bl	_call_via_r4
	adds	r4, r0, #0
	mov	r1, r8
	cmp	r1, #0
	beq	.L0201C342
	ldr	r2, [sp, #0x24]
	subs	r4, r4, r2
.L0201C342:
	ldr	r1, [sp, #0x14]
	subs	r0, r5, r1
	asrs	r0, r0, #1
	mov	r2, sl
	subs	r2, r2, r0
	mov	sl, r2
	cmp	r2, #0
	bne	.L0201C2DE
.L0201C352:
	ldr	r0, [sp, #0x10]
	str	r4, [r0, #0x60]
	movs	r0, #0
.L0201C358:
	add	sp, #0x28
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	sb, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1
.P0201C368:	.word gFnMixVoice

@ ======================================================================================
@ kitInstInit   (0201C36C)
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
	ldr	r1, .P0201C384	@ =gKitInst
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
.P0201C384:	.word gKitInst

@ ======================================================================================
@ instLookup   (0201C388)
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
	ldr	r1, .P0201C3F0	@ =gCfg
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
	beq	.L0201C438
	adds	r0, r1, #0
	cmp	r0, #0x10
	bne	.L0201C3F4
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
	b	.L0201C43C
.P0201C3F0:	.word gCfg
.L0201C3F4:
	cmp	r0, #0x11
	bne	.L0201C41C
	ldrh	r1, [r5, #2]
	adds	r1, r3, r1
	ldr	r2, .P0201C414	@ =gKitInst
	lsls	r0, r6, #1
	adds	r0, r0, r1
	ldrh	r0, [r0]
	strh	r0, [r2, #2]
	str	r2, [r4]
	ldr	r0, .P0201C418	@ =kFlatEnvelope
	str	r0, [r4, #4]
	movs	r0, #1
	strb	r0, [r4, #0x12]
	b	.L0201C440
	.hword 0x0000
.P0201C414:	.word gKitInst
.P0201C418:	.word kFlatEnvelope
.L0201C41C:
	cmp	r0, #0x12
	bne	.L0201C440
	ldrh	r0, [r5, #2]
	adds	r0, r3, r0
	b	.L0201C428
.L0201C426:
	adds	r0, #4
.L0201C428:
	ldrb	r1, [r0]
	cmp	r6, r1
	bhi	.L0201C426
	ldrh	r0, [r0, #2]
	adds	r0, r3, r0
	str	r0, [r4]
	ldrh	r0, [r0, #4]
	b	.L0201C43C
.L0201C438:
	str	r5, [r4]
	ldrh	r0, [r5, #4]
.L0201C43C:
	adds	r0, r3, r0
	str	r0, [r4, #4]
.L0201C440:
	ldr	r2, [r4]
	ldrb	r0, [r2]
	cmp	r0, #3
	bne	.L0201C44E
	ldrh	r0, [r5, #2]
	adds	r0, r3, r0
	str	r0, [r4, #0xc]
.L0201C44E:
	ldrb	r1, [r2, #1]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0201C45E
	ldrh	r0, [r2, #2]
	adds	r0, r3, r0
	str	r0, [r4, #8]
.L0201C45E:
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ voiceInitAll   (0201C464)
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
@   In this build: Same, but no echo variables.
@ ======================================================================================
	.global voiceInitAll
	.thumb_func
voiceInitAll:
	push	{r4, r5, r6, r7, lr}
	mov	r7, sb
	mov	r6, r8
	push	{r6, r7}
	ldr	r1, .P0201C5B0	@ =gLastWave
	movs	r0, #0
	str	r0, [r1]
	ldr	r2, .P0201C5B4	@ =gPsgVoices
	ldr	r0, .P0201C5B8	@ =gDsVoices
	mov	ip, r0
	ldr	r3, .P0201C5BC	@ =gVoiceCount
	ldr	r5, .P0201C5C0	@ =gFreeVoices
	ldr	r1, .P0201C5C4	@ =gActiveVoices
	mov	r8, r1
	ldr	r0, .P0201C5C8	@ =gReservedVoices
	mov	sb, r0
	movs	r1, #0
	adds	r0, r2, #1
	movs	r4, #3
.L0201C48A:
	strb	r1, [r0]
	strb	r1, [r0, #3]
	strb	r1, [r0, #4]
	strb	r1, [r0, #5]
	strb	r1, [r0, #6]
	adds	r0, #0x78
	subs	r4, #1
	cmp	r4, #0
	bge	.L0201C48A
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
	ldr	r0, .P0201C5B8	@ =gDsVoices
	movs	r4, #6
.L0201C4BE:
	strb	r1, [r0, #1]
	strb	r1, [r0]
	strb	r1, [r0, #4]
	strb	r1, [r0, #5]
	strb	r1, [r0, #6]
	strb	r1, [r0, #7]
	adds	r0, #0x78
	subs	r4, #1
	cmp	r4, #0
	bge	.L0201C4BE
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
.L0201C51A:
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
	bge	.L0201C51A
	movs	r3, #0
	movs	r1, #0x96
	lsls	r1, r1, #2
	add	r1, ip
	movs	r0, #0xce
	lsls	r0, r0, #2
	add	r0, ip
	strb	r1, [r0]
	lsrs	r2, r1, #8
	ldr	r0, .P0201C5CC	@ =0x00000339
	add	r0, ip
	strb	r2, [r0]
	lsrs	r2, r1, #0x10
	ldr	r0, .P0201C5D0	@ =0x0000033A
	add	r0, ip
	strb	r2, [r0]
	lsrs	r1, r1, #0x18
	ldr	r0, .P0201C5D4	@ =0x0000033B
	add	r0, ip
	strb	r1, [r0]
	movs	r0, #0xcf
	lsls	r0, r0, #2
	add	r0, ip
	strb	r3, [r0]
	ldr	r0, .P0201C5D8	@ =0x0000033D
	add	r0, ip
	strb	r3, [r0]
	ldr	r0, .P0201C5DC	@ =0x0000033E
	add	r0, ip
	strb	r3, [r0]
	ldr	r0, .P0201C5E0	@ =0x0000033F
	add	r0, ip
	strb	r3, [r0]
	mov	r1, r8
	str	r3, [r1]
	mov	r0, sb
	str	r3, [r0]
	pop	{r3, r4}
	mov	r8, r3
	mov	sb, r4
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201C5B0:	.word gLastWave
.P0201C5B4:	.word gPsgVoices
.P0201C5B8:	.word gDsVoices
.P0201C5BC:	.word gVoiceCount
.P0201C5C0:	.word gFreeVoices
.P0201C5C4:	.word gActiveVoices
.P0201C5C8:	.word gReservedVoices
.P0201C5CC:	.word 0x00000339
.P0201C5D0:	.word 0x0000033A
.P0201C5D4:	.word 0x0000033B
.P0201C5D8:	.word 0x0000033D
.P0201C5DC:	.word 0x0000033E
.P0201C5E0:	.word 0x0000033F

@ ======================================================================================
@ voiceListRemove   (0201C5E4)
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
	beq	.L0201C5F2
	str	r0, [r2, #0x6c]
	b	.L0201C5F4
.L0201C5F2:
	str	r0, [r1]
.L0201C5F4:
	cmp	r0, #0
	beq	.L0201C5FA
	str	r2, [r0, #0x68]
.L0201C5FA:
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ voiceListPush   (0201C600)
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
	beq	.L0201C612
	str	r3, [r2, #0x68]
.L0201C612:
	str	r3, [r1]
	pop	{r0}
	bx	r0

@ ======================================================================================
@ voiceListInsertActive   (0201C618)
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
	ldr	r0, .P0201C654	@ =gActiveVoices
	ldr	r1, [r0]
	ldrb	r2, [r3, #1]
	adds	r5, r0, #0
	cmp	r2, #1
	bne	.L0201C658
	cmp	r1, #0
	beq	.L0201C684
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	bne	.L0201C63C
	ldrb	r0, [r3, #8]
	ldrb	r2, [r1, #8]
	cmp	r0, r2
	blo	.L0201C684
.L0201C63C:
	adds	r4, r1, #0
	ldr	r1, [r4, #0x6c]
	cmp	r1, #0
	beq	.L0201C684
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	bne	.L0201C63C
	ldrb	r0, [r3, #8]
	ldrb	r2, [r1, #8]
	cmp	r0, r2
	bhs	.L0201C63C
	b	.L0201C684
.P0201C654:	.word gActiveVoices
.L0201C658:
	cmp	r2, #2
	bne	.L0201C698
	cmp	r1, #0
	beq	.L0201C684
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	beq	.L0201C684
	ldrb	r0, [r3, #8]
	ldrb	r2, [r1, #8]
	cmp	r0, r2
	blo	.L0201C684
	adds	r2, r0, #0
.L0201C670:
	adds	r4, r1, #0
	ldr	r1, [r4, #0x6c]
	cmp	r1, #0
	beq	.L0201C684
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	beq	.L0201C684
	ldrb	r0, [r1, #8]
	cmp	r2, r0
	bhs	.L0201C670
.L0201C684:
	str	r1, [r3, #0x6c]
	cmp	r1, #0
	beq	.L0201C68C
	str	r3, [r1, #0x68]
.L0201C68C:
	str	r4, [r3, #0x68]
	cmp	r4, #0
	beq	.L0201C696
	str	r3, [r4, #0x6c]
	b	.L0201C698
.L0201C696:
	str	r3, [r5]
.L0201C698:
	pop	{r4, r5}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ keyToFreq   (0201C6A0)
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
	bge	.L0201C6BC
	movs	r2, #0
	b	.L0201C6C2
.L0201C6BC:
	cmp	r1, #0x77
	ble	.L0201C6C2
	movs	r2, #0x78
.L0201C6C2:
	ldrb	r0, [r0]
	cmp	r0, #0
	bne	.L0201C6D8
	ldr	r0, .P0201C6D4	@ =kDsPitch
	lsls	r1, r2, #0x10
	asrs	r1, r1, #0xe
	adds	r1, r1, r0
	ldr	r0, [r1]
	b	.L0201C6F0
.P0201C6D4:	.word kDsPitch
.L0201C6D8:
	cmp	r0, #4
	beq	.L0201C6EC
	ldr	r0, .P0201C6E8	@ =kPsgFreq
	lsls	r1, r2, #0x10
	asrs	r1, r1, #0xf
	adds	r1, r1, r0
	ldrh	r0, [r1]
	b	.L0201C6F0
.P0201C6E8:	.word kPsgFreq
.L0201C6EC:
	lsls	r0, r2, #0x10
	asrs	r0, r0, #0x10
.L0201C6F0:
	pop	{r1}
	bx	r1

@ ======================================================================================
@ noiseDivider   (0201C6F4)
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
	bls	.L0201C700
	movs	r1, #0x77
.L0201C700:
	ldr	r0, .P0201C70C	@ =kNoiseTable
	adds	r0, r1, r0
	ldrb	r0, [r0]
	pop	{r1}
	bx	r1
	.hword 0x0000
.P0201C70C:	.word kNoiseTable

@ ======================================================================================
@ envStep   (0201C710)
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
	bne	.L0201C76A
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
	bge	.L0201C73C
	strb	r1, [r4, #0x10]
.L0201C73C:
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
.L0201C76A:
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
@ echoSetFeedback   (0201C780)
@
@   void echoSetFeedback(u32 shift) { }  /* empty: this build has no echo */
@ ======================================================================================
	.global echoSetFeedback
	.thumb_func
echoSetFeedback:
	bx	lr
	movs	r0, r0

@ ======================================================================================
@ voiceSetCount   (0201C784)
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
	ldr	r2, .P0201C7D8	@ =gVoiceCount
	ldrb	r1, [r2]
	subs	r0, r0, r1
	lsls	r0, r0, #0x18
	lsrs	r5, r0, #0x18
	asrs	r0, r0, #0x18
	cmp	r0, #0
	beq	.L0201C824
	cmp	r0, #0
	ble	.L0201C7E4
	ldr	r0, .P0201C7DC	@ =gReservedVoices
	ldr	r6, [r0]
	cmp	r6, #0
	beq	.L0201C824
	adds	r7, r2, #0
.L0201C7A8:
	adds	r4, r6, #0
	ldr	r6, [r4, #0x6c]
	adds	r0, r4, #0
	ldr	r1, .P0201C7DC	@ =gReservedVoices
	bl	voiceListRemove
	adds	r0, r4, #0
	ldr	r1, .P0201C7E0	@ =gFreeVoices
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
	beq	.L0201C824
	lsls	r0, r5, #0x18
	cmp	r0, #0
	bgt	.L0201C7A8
	b	.L0201C824
.P0201C7D8:	.word gVoiceCount
.P0201C7DC:	.word gReservedVoices
.P0201C7E0:	.word gFreeVoices
.L0201C7E4:
	rsbs	r0, r0, #0
	lsls	r0, r0, #0x18
	lsrs	r5, r0, #0x18
	adds	r6, r2, #0
	b	.L0201C80E
.L0201C7EE:
	adds	r0, r4, #0
	ldr	r1, .P0201C82C	@ =gActiveVoices
	bl	voiceListRemove
	movs	r0, #0
	strb	r0, [r4, #1]
	adds	r0, r4, #0
	ldr	r1, .P0201C830	@ =gReservedVoices
	bl	voiceListPush
	subs	r0, r5, #1
	lsls	r0, r0, #0x18
	lsrs	r5, r0, #0x18
	ldrb	r0, [r6]
	subs	r0, #1
	strb	r0, [r6]
.L0201C80E:
	lsls	r0, r5, #0x18
	asrs	r5, r0, #0x18
	cmp	r5, #0
	ble	.L0201C824
	movs	r0, #0
	movs	r1, #0xff
	bl	voiceAlloc
	adds	r4, r0, #0
	cmp	r4, #0
	bne	.L0201C7EE
.L0201C824:
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201C82C:	.word gActiveVoices
.P0201C830:	.word gReservedVoices

@ ======================================================================================
@ dsVolume   (0201C834)
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
	bne	.L0201C87E
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
	b	.L0201C890
.L0201C87E:
	adds	r0, r5, #0
	adds	r0, #0x58
	ldrb	r0, [r0]
	adds	r0, #0xe6
	ldr	r1, [r5, #0x14]
	muls	r0, r1, r0
	lsrs	r0, r0, #9
	str	r0, [r5, #0x14]
	adds	r4, r0, #0
.L0201C890:
	lsrs	r4, r4, #8
	adds	r0, r4, #0
	pop	{r4, r5}
	pop	{r1}
	bx	r1
	movs	r0, r0

@ ======================================================================================
@ psgEnvelope   (0201C89C)
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
	bne	.L0201C8BA
	movs	r6, #1
.L0201C8BA:
	adds	r0, r5, #0
	bl	envStep
	cmp	r6, #0
	bne	.L0201C8C8
	movs	r0, #8
	b	.L0201C998
.L0201C8C8:
	cmp	r7, #0
	beq	.L0201C8CE
	lsls	r4, r4, #1
.L0201C8CE:
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
	bne	.L0201C91C
	lsrs	r4, r4, #0x16
	str	r4, [r5, #0x14]
	lsls	r0, r4, #2
	adds	r4, r0, r4
	lsrs	r4, r4, #7
	cmp	r4, #4
	bls	.L0201C916
	movs	r4, #4
.L0201C916:
	lsls	r0, r4, #0x18
	lsrs	r0, r0, #0x18
	b	.L0201C998
.L0201C91C:
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
	beq	.L0201C934
	movs	r4, #0xf
.L0201C934:
	ldr	r1, [r5, #0x14]
	ldr	r0, [r5, #0x44]
	muls	r0, r1, r0
	lsrs	r0, r0, #0x19
	str	r0, [r5, #0x14]
	ands	r0, r2
	cmp	r0, #0
	beq	.L0201C948
	movs	r0, #0xf
	str	r0, [r5, #0x14]
.L0201C948:
	ldr	r5, [r5, #0x14]
	cmp	r5, r4
	beq	.L0201C970
	mov	r1, r8
	ldrh	r2, [r1]
	adds	r0, r2, #0
	adds	r0, #0xf
	lsls	r0, r0, #0x10
	lsrs	r2, r0, #0x10
	subs	r1, r5, r4
	cmp	r1, #0
	bge	.L0201C962
	rsbs	r1, r1, #0
.L0201C962:
	adds	r0, r2, #0
	bl	__divsi3
	lsls	r0, r0, #0x10
	lsrs	r2, r0, #0x10
	cmp	r2, #0
	bne	.L0201C97C
.L0201C970:
	lsls	r0, r4, #4
	movs	r1, #8
	orrs	r0, r1
	lsls	r0, r0, #0x18
	lsrs	r6, r0, #0x18
	b	.L0201C996
.L0201C97C:
	ldr	r0, .P0201C9A4	@ =0x0000FFF8
	ands	r0, r2
	cmp	r0, #0
	beq	.L0201C986
	movs	r2, #7
.L0201C986:
	lsls	r0, r4, #4
	orrs	r0, r2
	lsls	r0, r0, #0x18
	lsrs	r6, r0, #0x18
	cmp	r4, r5
	bhs	.L0201C996
	movs	r0, #8
	orrs	r6, r0
.L0201C996:
	adds	r0, r6, #0
.L0201C998:
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1
	.hword 0x0000
.P0201C9A4:	.word 0x0000FFF8

@ ======================================================================================
@ voicePitch   (0201C9A8)
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
	beq	.L0201C9C0
	subs	r0, #1
	str	r0, [r5, #0x2c]
	b	.L0201C9DA
.L0201C9C0:
	ldr	r4, [r3, #4]
	cmp	r4, #0
	beq	.L0201C9DA
	ldr	r0, [r3, #8]
	ldr	r1, [r3, #0x10]
	adds	r0, r0, r1
	str	r0, [r3, #8]
	subs	r0, r4, #1
	str	r0, [r3, #4]
	cmp	r0, #0
	bne	.L0201C9DA
	ldr	r0, [r3, #0xc]
	str	r0, [r3, #8]
.L0201C9DA:
	ldr	r0, [r3, #8]
	adds	r2, r2, r0
	adds	r0, r6, #0
	adds	r0, #0x4f
	movs	r1, #0
	ldrsb	r1, [r0, r1]
	cmp	r1, #0
	beq	.L0201CA86
	cmp	r1, #0
	ble	.L0201CA2E
	adds	r3, r1, #0
	ldr	r1, .P0201CA14	@ =kDsPitch
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
	bne	.L0201CA18
	lsrs	r3, r3, #7
	muls	r2, r3, r2
	lsrs	r2, r2, #0xf
	b	.L0201CA86
.P0201CA14:	.word kDsPitch
.L0201CA18:
	movs	r4, #0x80
	lsls	r4, r4, #4
	subs	r2, r4, r2
	lsls	r2, r2, #0x16
	adds	r0, r2, #0
	adds	r1, r3, #0
	bl	__udivsi3
	adds	r2, r0, #0
	subs	r2, r4, r2
	b	.L0201CA86
.L0201CA2E:
	ldrb	r0, [r0]
	lsls	r0, r0, #0x18
	asrs	r0, r0, #0x18
	rsbs	r3, r0, #0
	ldr	r1, .P0201CA64	@ =kDsPitch
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
	bne	.L0201CA68
	lsls	r2, r2, #0xf
	lsrs	r3, r3, #7
	adds	r0, r2, #0
	adds	r1, r3, #0
	bl	__udivsi3
	adds	r2, r0, #0
	b	.L0201CA86
.P0201CA64:	.word kDsPitch
.L0201CA68:
	movs	r1, #0x80
	lsls	r1, r1, #4
	subs	r2, r1, r2
	lsrs	r3, r3, #7
	muls	r2, r3, r2
	lsrs	r2, r2, #0xf
	ldr	r0, .P0201CA80	@ =0x000007FF
	cmp	r2, r0
	bhi	.L0201CA84
	subs	r2, r1, r2
	b	.L0201CA86
	.hword 0x0000
.P0201CA80:	.word 0x000007FF
.L0201CA84:
	movs	r2, #0
.L0201CA86:
	adds	r4, r5, #0
	adds	r4, #0x20
	ldr	r0, [r4, #8]
	ldr	r3, [r0, #8]
	cmp	r3, #0
	beq	.L0201CB34
	ldr	r0, [r4, #4]
	cmp	r0, #0
	bne	.L0201CB30
	ldr	r0, .P0201CABC	@ =kLfoSine
	ldr	r1, [r5, #0x20]
	lsrs	r1, r1, #1
	adds	r1, r1, r0
	ldrb	r1, [r1]
	ldrb	r0, [r5]
	cmp	r0, #0
	bne	.L0201CADC
	lsls	r0, r1, #0x18
	asrs	r0, r0, #0x18
	cmp	r0, #0
	blt	.L0201CAC0
	muls	r0, r2, r0
	muls	r0, r3, r0
	lsrs	r0, r0, #0x13
	adds	r2, r2, r0
	b	.L0201CB14
	.hword 0x0000
.P0201CABC:	.word kLfoSine
.L0201CAC0:
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
	b	.L0201CB14
.L0201CADC:
	lsls	r0, r1, #0x18
	asrs	r1, r0, #0x18
	cmp	r1, #0
	blt	.L0201CAFA
	movs	r0, #0x80
	lsls	r0, r0, #4
	subs	r0, r0, r2
	lsls	r0, r0, #0x13
	muls	r1, r3, r1
	movs	r2, #0x80
	lsls	r2, r2, #0xc
	adds	r1, r1, r2
	bl	__udivsi3
	b	.L0201CB0E
.L0201CAFA:
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
.L0201CB0E:
	movs	r2, #0x80
	lsls	r2, r2, #4
	subs	r2, r2, r0
.L0201CB14:
	ldr	r0, [r4, #8]
	ldr	r1, [r4]
	ldr	r0, [r0, #4]
	adds	r1, r1, r0
	str	r1, [r4]
	lsrs	r0, r1, #1
	cmp	r0, #0xff
	bls	.L0201CB34
	ldr	r3, .P0201CB2C	@ =0xFFFFFE00
	adds	r0, r1, r3
	str	r0, [r4]
	b	.L0201CB34
.P0201CB2C:	.word 0xFFFFFE00
.L0201CB30:
	subs	r0, #1
	str	r0, [r4, #4]
.L0201CB34:
	adds	r0, r2, #0
	pop	{r4, r5, r6}
	pop	{r1}
	bx	r1

@ ======================================================================================
@ mixFrame   (0201CB3C)
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
@   In this build: As in SMA3, but without any echo: only gMixDry is used.
@ ======================================================================================
	.global mixFrame
	.thumb_func
mixFrame:
	push	{r4, r5, r6, r7, lr}
	mov	r7, r8
	push	{r7}
	sub	sp, #4
	ldr	r0, .P0201CB80	@ =gActiveVoices
	ldr	r7, [r0]
	movs	r0, #0
	str	r0, [sp]
	ldr	r1, .P0201CB84	@ =gMixDry
	ldr	r2, .P0201CB88	@ =0x010000B0
	mov	r0, sp
	bl	CpuFastSet
.L0201CB56:
	cmp	r7, #0
	beq	.L0201CBEC
	adds	r4, r7, #0
	ldr	r7, [r7, #0x6c]
	adds	r0, r4, #0
	bl	dsVolume
	mov	r8, r0
	ldrb	r0, [r4, #1]
	cmp	r0, #1
	bne	.L0201CBA8
	ldrh	r0, [r4, #0x18]
	subs	r0, #1
	strh	r0, [r4, #0x18]
	ldr	r5, [r4, #4]
	ldrb	r0, [r4, #0x1b]
	cmp	r0, #0
	beq	.L0201CB8C
	ldrb	r3, [r4, #0x1c]
	b	.L0201CB92
	.hword 0x0000
.P0201CB80:	.word gActiveVoices
.P0201CB84:	.word gMixDry
.P0201CB88:	.word 0x010000B0
.L0201CB8C:
	adds	r0, r5, #0
	adds	r0, #0x4b
	ldrb	r3, [r0]
.L0201CB92:
	adds	r6, r3, #0
	adds	r0, r4, #0
	bl	voicePitch
	adds	r2, r0, #0
	str	r2, [r4, #0x10]
	adds	r0, r5, #0
	adds	r0, #0x4c
	ldrb	r0, [r0]
	strb	r0, [r4, #0x1a]
	b	.L0201CBBA
.L0201CBA8:
	mov	r0, r8
	cmp	r0, #0
	bne	.L0201CBB6
	adds	r0, r4, #0
	bl	voiceStop
	b	.L0201CB56
.L0201CBB6:
	ldrb	r6, [r4, #0x1c]
	ldr	r2, [r4, #0x10]
.L0201CBBA:
	lsrs	r2, r2, #2
	ldr	r0, [r4, #0x5c]
	ldr	r0, [r0, #4]
	muls	r2, r0, r2
	adds	r0, r2, #0
	ldr	r1, .P0201CBE8	@ =0x00002910
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
	bne	.L0201CB56
	adds	r0, r4, #0
	bl	voiceStop
	b	.L0201CB56
.P0201CBE8:	.word 0x00002910
.L0201CBEC:
	movs	r5, #0
	movs	r4, #6
.L0201CBF0:
	ldr	r0, .P0201CC38	@ =gDsVoices
	adds	r1, r5, r0
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	bne	.L0201CC06
	ldrh	r0, [r1, #0x18]
	cmp	r0, #0
	bne	.L0201CC06
	adds	r0, r1, #0
	bl	noteOff
.L0201CC06:
	adds	r5, #0x78
	subs	r4, #1
	cmp	r4, #0
	bge	.L0201CBF0
	ldr	r3, .P0201CC3C	@ =gFnDownmix
	ldr	r0, .P0201CC40	@ =gMixDry
	ldr	r2, .P0201CC44	@ =gDmaBufA
	ldr	r1, .P0201CC48	@ =gDmaBufIdx
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
.P0201CC38:	.word gDsVoices
.P0201CC3C:	.word gFnDownmix
.P0201CC40:	.word gMixDry
.P0201CC44:	.word gDmaBufA
.P0201CC48:	.word gDmaBufIdx

@ ======================================================================================
@ psgUpdate   (0201CC4C)
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
.L0201CC5A:
	mov	r1, sl
	lsls	r0, r1, #4
	subs	r0, r0, r1
	lsls	r0, r0, #3
	ldr	r1, .P0201CC98	@ =gPsgVoices
	adds	r4, r0, r1
	ldrb	r0, [r4, #1]
	cmp	r0, #1
	bne	.L0201CC78
	ldrh	r0, [r4, #0x18]
	cmp	r0, #0
	bne	.L0201CC78
	adds	r0, r4, #0
	bl	noteOff
.L0201CC78:
	ldrb	r0, [r4, #1]
	cmp	r0, #0
	bne	.L0201CC80
	b	.L0201CEC0
.L0201CC80:
	cmp	r0, #1
	bne	.L0201CCA6
	adds	r0, r4, #0
	bl	voicePitch
	adds	r6, r0, #0
	str	r6, [r4, #0x10]
	ldrb	r0, [r4, #0x1b]
	cmp	r0, #0
	beq	.L0201CC9C
	ldrb	r0, [r4, #0x1c]
	b	.L0201CCA2
.P0201CC98:	.word gPsgVoices
.L0201CC9C:
	ldr	r0, [r4, #4]
	adds	r0, #0x4b
	ldrb	r0, [r0]
.L0201CCA2:
	mov	r8, r0
	b	.L0201CCAC
.L0201CCA6:
	ldr	r6, [r4, #0x10]
	ldrb	r2, [r4, #0x1c]
	mov	r8, r2
.L0201CCAC:
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
	ldr	r0, .P0201CCF0	@ =REG_NR51
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
	bne	.L0201CCF4
	mov	r3, ip
	ldrb	r1, [r3]
	adds	r0, r2, #0
	ands	r0, r1
	orrs	r0, r5
	strb	r0, [r3]
	b	.L0201CD1E
.P0201CCF0:	.word REG_NR51
.L0201CCF4:
	mov	r0, r8
	cmp	r0, #0x3f
	bhi	.L0201CD0E
	mov	r1, ip
	ldrb	r0, [r1]
	adds	r1, r2, #0
	ands	r1, r0
	movs	r0, #0x10
	lsls	r0, r3
	orrs	r1, r0
	mov	r2, ip
	strb	r1, [r2]
	b	.L0201CD1E
.L0201CD0E:
	mov	r3, ip
	ldrb	r0, [r3]
	ands	r1, r0
	movs	r0, #1
	mov	r2, sb
	lsls	r0, r2
	orrs	r1, r0
	strb	r1, [r3]
.L0201CD1E:
	ldrb	r5, [r4, #1]
	cmp	r5, #1
	bne	.L0201CD48
	ldr	r0, [r4, #0x60]
	cmp	r0, #0
	bne	.L0201CD3C
	adds	r0, r4, #0
	adds	r1, r7, #0
	bl	psgKeyOn
	str	r5, [r4, #0x60]
	ldrh	r0, [r4, #0x18]
	subs	r0, #1
	strh	r0, [r4, #0x18]
	b	.L0201CEC0
.L0201CD3C:
	adds	r0, #1
	str	r0, [r4, #0x60]
	ldrh	r0, [r4, #0x18]
	subs	r0, #1
	strh	r0, [r4, #0x18]
	b	.L0201CD98
.L0201CD48:
	ldrb	r0, [r4]
	cmp	r0, #3
	bne	.L0201CD98
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
	beq	.L0201CD68
	lsls	r1, r1, #1
.L0201CD68:
	lsls	r0, r1, #2
	adds	r1, r0, r1
	lsrs	r1, r1, #7
	cmp	r1, #0
	beq	.L0201CD90
	cmp	r1, #4
	bls	.L0201CD78
	movs	r1, #4
.L0201CD78:
	lsls	r1, r1, #0x18
	lsrs	r1, r1, #0x18
	ldr	r2, .P0201CD88	@ =REG_NR32
	ldr	r0, .P0201CD8C	@ =kWaveVolume
	adds	r1, r1, r0
	ldrb	r0, [r1]
	strb	r0, [r2]
	b	.L0201CEC0
.P0201CD88:	.word REG_NR32
.P0201CD8C:	.word kWaveVolume
.L0201CD90:
	adds	r0, r4, #0
	bl	voiceStop
	b	.L0201CEC0
.L0201CD98:
	ldr	r2, [r4, #0x54]
	ldrb	r1, [r2, #1]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0201CDBA
	ldr	r0, [r4, #0x64]
	ldrh	r3, [r0]
	ldr	r1, [r4, #0x60]
	cmp	r1, r3
	bhs	.L0201CDB4
	adds	r0, r0, r1
	ldrb	r5, [r0, #2]
	b	.L0201CDBC
.L0201CDB4:
	adds	r0, r3, r0
	ldrb	r5, [r0, #1]
	b	.L0201CDBC
.L0201CDBA:
	movs	r5, #0xff
.L0201CDBC:
	ldrb	r0, [r4]
	cmp	r0, #2
	beq	.L0201CE0C
	cmp	r0, #2
	bgt	.L0201CDCC
	cmp	r0, #1
	beq	.L0201CDD6
	b	.L0201CEC0
.L0201CDCC:
	cmp	r0, #3
	beq	.L0201CE4C
	cmp	r0, #4
	beq	.L0201CE74
	b	.L0201CEC0
.L0201CDD6:
	cmp	r7, #8
	beq	.L0201CDF4
	ldr	r0, .P0201CDEC	@ =REG_NR12
	strb	r7, [r0]
	ldr	r1, .P0201CDF0	@ =REG_SOUND1CNT_X
	movs	r2, #0x80
	lsls	r2, r2, #8
	adds	r0, r2, #0
	orrs	r6, r0
	strh	r6, [r1]
	b	.L0201CDFE
.P0201CDEC:	.word REG_NR12
.P0201CDF0:	.word REG_SOUND1CNT_X
.L0201CDF4:
	ldrb	r0, [r2, #8]
	cmp	r0, #8
	bne	.L0201CDFE
	ldr	r0, .P0201CE04	@ =REG_SOUND1CNT_X
	strh	r6, [r0]
.L0201CDFE:
	ldr	r2, .P0201CE08	@ =REG_NR11
	b	.L0201CE32
	.hword 0x0000
.P0201CE04:	.word REG_SOUND1CNT_X
.P0201CE08:	.word REG_NR11
.L0201CE0C:
	cmp	r7, #8
	beq	.L0201CE2C
	ldr	r0, .P0201CE24	@ =REG_NR22
	strb	r7, [r0]
	ldr	r1, .P0201CE28	@ =REG_SOUND2CNT_H
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r0, r3, #0
	orrs	r6, r0
	strh	r6, [r1]
	b	.L0201CE30
	.hword 0x0000
.P0201CE24:	.word REG_NR22
.P0201CE28:	.word REG_SOUND2CNT_H
.L0201CE2C:
	ldr	r0, .P0201CE44	@ =REG_SOUND2CNT_H
	strh	r6, [r0]
.L0201CE30:
	ldr	r2, .P0201CE48	@ =REG_NR21
.L0201CE32:
	ldrb	r1, [r2]
	movs	r0, #0xc0
	ands	r0, r1
	strb	r0, [r2]
	cmp	r5, #0xff
	beq	.L0201CEC0
	lsls	r0, r5, #6
	strb	r0, [r2]
	b	.L0201CEC0
.P0201CE44:	.word REG_SOUND2CNT_H
.P0201CE48:	.word REG_NR21
.L0201CE4C:
	ldr	r0, .P0201CE6C	@ =REG_SOUND3CNT_X
	ldrh	r1, [r0]
	movs	r3, #0x80
	lsls	r3, r3, #7
	adds	r2, r3, #0
	ands	r1, r2
	orrs	r1, r6
	strh	r1, [r0]
	cmp	r7, #8
	beq	.L0201CEC0
	subs	r0, #1
	ldr	r1, .P0201CE70	@ =kWaveVolume
	adds	r1, r7, r1
	ldrb	r1, [r1]
	strb	r1, [r0]
	b	.L0201CEC0
.P0201CE6C:	.word REG_SOUND3CNT_X
.P0201CE70:	.word kWaveVolume
.L0201CE74:
	cmp	r7, #8
	beq	.L0201CE82
	ldr	r0, .P0201CEA0	@ =REG_NR42
	strb	r7, [r0]
	ldr	r1, .P0201CEA4	@ =REG_NR44
	movs	r0, #0x80
	strb	r0, [r1]
.L0201CE82:
	cmp	r5, #0xff
	beq	.L0201CEAC
	ldr	r4, .P0201CEA8	@ =REG_NR43
	lsls	r0, r6, #0x10
	lsrs	r0, r0, #0x10
	bl	noiseDivider
	lsls	r0, r0, #0x18
	lsrs	r1, r0, #0x18
	cmp	r5, #0
	beq	.L0201CE9C
	movs	r0, #8
	orrs	r1, r0
.L0201CE9C:
	strb	r1, [r4]
	b	.L0201CEC0
.P0201CEA0:	.word REG_NR42
.P0201CEA4:	.word REG_NR44
.P0201CEA8:	.word REG_NR43
.L0201CEAC:
	lsls	r0, r6, #0x10
	lsrs	r0, r0, #0x10
	bl	noiseDivider
	ldr	r3, .P0201CEDC	@ =REG_NR43
	ldrb	r2, [r3]
	movs	r1, #8
	ands	r1, r2
	orrs	r1, r0
	strb	r1, [r3]
.L0201CEC0:
	movs	r0, #1
	add	sl, r0
	mov	r1, sl
	cmp	r1, #3
	bgt	.L0201CECC
	b	.L0201CC5A
.L0201CECC:
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	sb, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201CEDC:	.word REG_NR43

@ ======================================================================================
@ noteOn   (0201CEE0)
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
	beq	.L0201CF08
	b	.L0201D09C
.L0201CF08:
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
	beq	.L0201CF2E
	ldrh	r1, [r4, #0x30]
	b	.L0201CF36
.L0201CF2E:
	movs	r0, #0x32
	ldrsh	r1, [r4, r0]
	ldrh	r4, [r4, #0x30]
	adds	r1, r1, r4
.L0201CF36:
	mov	r0, r8
	bl	__udivsi3
	mov	r8, r0
	adds	r0, r5, #0
	adds	r0, #0x49
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L0201CF52
	ldr	r0, [r5, #0xc]
	cmp	r0, #0
	beq	.L0201CF52
	adds	r4, r0, #0
	b	.L0201CFA8
.L0201CF52:
	ldr	r1, .P0201CFC0	@ =kVoiceForType
	ldrb	r0, [r6]
	adds	r0, r0, r1
	ldrb	r0, [r0]
	adds	r1, r5, #0
	adds	r1, #0x52
	ldrb	r1, [r1]
	bl	voiceAlloc
	adds	r4, r0, #0
	cmp	r4, #0
	bne	.L0201CF6C
	b	.L0201D09C
.L0201CF6C:
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
.L0201CFA8:
	mov	r0, sp
	ldrb	r0, [r0, #0x11]
	strb	r0, [r4, #0x1b]
	lsls	r0, r0, #0x18
	cmp	r0, #0
	beq	.L0201CFC4
	movs	r7, #0x30
	mov	r0, sp
	ldrb	r0, [r0, #0x10]
	strb	r0, [r4, #0x1c]
	b	.L0201CFCE
	.hword 0x0000
.P0201CFC0:	.word kVoiceForType
.L0201CFC4:
	mov	r0, sp
	ldrb	r0, [r0, #0x12]
	cmp	r0, #0
	beq	.L0201CFCE
	movs	r7, #0x30
.L0201CFCE:
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
	bne	.L0201D000
	adds	r0, r4, #0
	adds	r0, #0x2c
	movs	r1, #0x14
	bl	MemClear
	b	.L0201D05A
.L0201D000:
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
	beq	.L0201D02E
	ldr	r0, [r4, #0xc]
	subs	r0, r2, r0
	str	r0, [r4, #0x38]
	b	.L0201D036
.L0201D02E:
	ldr	r0, [r4, #0xc]
	subs	r0, r0, r2
	str	r0, [r4, #0x38]
	str	r2, [r4, #0xc]
.L0201D036:
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
	beq	.L0201D054
	strb	r7, [r5, #0x1e]
	b	.L0201D056
.L0201D054:
	strb	r0, [r5, #0x1c]
.L0201D056:
	movs	r0, #0
	str	r0, [r4, #0x34]
.L0201D05A:
	ldrb	r0, [r4]
	cmp	r0, #0
	bne	.L0201D070
	ldrh	r0, [r6, #2]
	ldr	r1, [r5, #4]
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r0, [r0]
	adds	r1, r1, r0
	str	r1, [r4, #0x5c]
	b	.L0201D090
.L0201D070:
	cmp	r0, #3
	beq	.L0201D08C
	ldrb	r1, [r6, #1]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0201D082
	ldr	r0, [sp, #8]
	b	.L0201D08E
.L0201D082:
	ldrh	r1, [r6, #2]
	adds	r0, r4, #0
	adds	r0, #0x64
	strb	r1, [r0]
	b	.L0201D090
.L0201D08C:
	ldr	r0, [sp, #0xc]
.L0201D08E:
	str	r0, [r4, #0x64]
.L0201D090:
	mov	r0, r8
	cmp	r0, #0
	bne	.L0201D09C
	adds	r0, r4, #0
	bl	noteOff
.L0201D09C:
	add	sp, #0x14
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	sb, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ noteOff   (0201D0AC)
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
	bne	.L0201D18A
	ldr	r0, [r4, #4]
	adds	r0, #0x49
	ldrb	r0, [r0]
	cmp	r0, #0
	bne	.L0201D18A
	ldrb	r3, [r4]
	cmp	r3, #0
	bne	.L0201D0E0
	ldr	r1, .P0201D0DC	@ =gActiveVoices
	adds	r0, r4, #0
	bl	voiceListRemove
	movs	r0, #2
	strb	r0, [r4, #1]
	adds	r0, r4, #0
	bl	voiceListInsertActive
	b	.L0201D172
	.hword 0x0000
.P0201D0DC:	.word gActiveVoices
.L0201D0E0:
	ldrh	r2, [r4, #0x10]
	adds	r0, r4, #0
	adds	r0, #0x58
	ldrb	r1, [r0]
	cmp	r3, #3
	bne	.L0201D0F0
	movs	r0, #2
	b	.L0201D170
.L0201D0F0:
	lsrs	r1, r1, #5
	cmp	r1, #0
	bne	.L0201D0FA
	movs	r1, #0
	b	.L0201D104
.L0201D0FA:
	ldr	r0, [r4, #0x14]
	lsls	r0, r0, #4
	orrs	r1, r0
	lsls	r0, r1, #0x18
	lsrs	r1, r0, #0x18
.L0201D104:
	ldrb	r0, [r4]
	cmp	r0, #2
	beq	.L0201D13C
	cmp	r0, #2
	bgt	.L0201D114
	cmp	r0, #1
	beq	.L0201D11A
	b	.L0201D16E
.L0201D114:
	cmp	r0, #4
	beq	.L0201D164
	b	.L0201D16E
.L0201D11A:
	ldr	r0, .P0201D130	@ =REG_NR12
	strb	r1, [r0]
	ldr	r1, .P0201D134	@ =REG_SOUND1CNT_X
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r0, r3, #0
	orrs	r2, r0
	strh	r2, [r1]
	ldr	r2, .P0201D138	@ =REG_NR11
	b	.L0201D14E
	.hword 0x0000
.P0201D130:	.word REG_NR12
.P0201D134:	.word REG_SOUND1CNT_X
.P0201D138:	.word REG_NR11
.L0201D13C:
	ldr	r0, .P0201D158	@ =REG_NR22
	strb	r1, [r0]
	ldr	r1, .P0201D15C	@ =REG_SOUND2CNT_H
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r0, r3, #0
	orrs	r2, r0
	strh	r2, [r1]
	ldr	r2, .P0201D160	@ =REG_NR21
.L0201D14E:
	ldrb	r1, [r2]
	movs	r0, #0xc0
	ands	r0, r1
	strb	r0, [r2]
	b	.L0201D16E
.P0201D158:	.word REG_NR22
.P0201D15C:	.word REG_SOUND2CNT_H
.P0201D160:	.word REG_NR21
.L0201D164:
	ldr	r0, .P0201D190	@ =REG_NR42
	strb	r1, [r0]
	ldr	r1, .P0201D194	@ =REG_NR44
	movs	r0, #0x80
	strb	r0, [r1]
.L0201D16E:
	movs	r0, #0
.L0201D170:
	strb	r0, [r4, #1]
.L0201D172:
	ldrb	r0, [r4, #0x1b]
	ldr	r1, [r4, #4]
	cmp	r0, #0
	bne	.L0201D182
	adds	r0, r1, #0
	adds	r0, #0x4b
	ldrb	r0, [r0]
	strb	r0, [r4, #0x1c]
.L0201D182:
	adds	r0, r1, #0
	adds	r1, r4, #0
	bl	trackRemoveVoice
.L0201D18A:
	pop	{r4}
	pop	{r0}
	bx	r0
.P0201D190:	.word REG_NR42
.P0201D194:	.word REG_NR44

@ ======================================================================================
@ voiceStop   (0201D198)
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
	beq	.L0201D224
	ldrb	r0, [r4]
	cmp	r0, #4
	bhi	.L0201D218
	lsls	r0, r0, #2
	ldr	r1, .P0201D1B4	@ =0x0201D1B8
	adds	r0, r0, r1
	ldr	r0, [r0]
	mov	pc, r0
	.hword 0x0000
.P0201D1B4:	.word 0x0201D1B8
	.word .L0201D1CC
	.word .L0201D1E8
	.word .L0201D1F8
	.word .L0201D200
	.word .L0201D20C
.L0201D1CC:
	ldr	r1, .P0201D1E0	@ =gActiveVoices
	adds	r0, r4, #0
	bl	voiceListRemove
	ldr	r1, .P0201D1E4	@ =gFreeVoices
	adds	r0, r4, #0
	bl	voiceListPush
	b	.L0201D218
	.hword 0x0000
.P0201D1E0:	.word gActiveVoices
.P0201D1E4:	.word gFreeVoices
.L0201D1E8:
	ldr	r1, .P0201D1F4	@ =REG_NR12
	movs	r0, #8
	strb	r0, [r1]
	adds	r1, #2
	b	.L0201D214
	.hword 0x0000
.P0201D1F4:	.word REG_NR12
.L0201D1F8:
	ldr	r1, .P0201D1FC	@ =REG_NR22
	b	.L0201D20E
.P0201D1FC:	.word REG_NR22
.L0201D200:
	ldr	r1, .P0201D208	@ =REG_NR30
	movs	r0, #0
	b	.L0201D216
	.hword 0x0000
.P0201D208:	.word REG_NR30
.L0201D20C:
	ldr	r1, .P0201D22C	@ =REG_NR42
.L0201D20E:
	movs	r0, #8
	strb	r0, [r1]
	adds	r1, #4
.L0201D214:
	movs	r0, #0xc0
.L0201D216:
	strb	r0, [r1]
.L0201D218:
	ldr	r0, [r4, #4]
	adds	r1, r4, #0
	bl	trackRemoveVoice
	movs	r0, #0
	strb	r0, [r4, #1]
.L0201D224:
	pop	{r4}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201D22C:	.word REG_NR42

@ ======================================================================================
@ psgKeyOn   (0201D230)
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
	beq	.L0201D2B4
	cmp	r3, #2
	bgt	.L0201D248
	cmp	r3, #1
	beq	.L0201D252
	b	.L0201D380
.L0201D248:
	cmp	r3, #3
	beq	.L0201D2E0
	cmp	r3, #4
	beq	.L0201D334
	b	.L0201D380
.L0201D252:
	ldr	r1, .P0201D280	@ =REG_NR10
	ldr	r0, [r4, #0x54]
	ldrb	r0, [r0, #8]
	strb	r0, [r1]
	ldr	r2, .P0201D284	@ =REG_SOUND1CNT_X
	ldr	r0, [r4, #0xc]
	movs	r6, #0x80
	lsls	r6, r6, #8
	adds	r1, r6, #0
	orrs	r0, r1
	strh	r0, [r2]
	ldr	r0, .P0201D288	@ =REG_NR12
	strb	r5, [r0]
	ldr	r0, [r4, #0x54]
	ldrb	r0, [r0, #1]
	ands	r3, r0
	cmp	r3, #0
	beq	.L0201D290
	ldr	r1, .P0201D28C	@ =REG_NR11
	ldr	r0, [r4, #0x64]
	ldrb	r0, [r0, #2]
	b	.L0201D298
	.hword 0x0000
.P0201D280:	.word REG_NR10
.P0201D284:	.word REG_SOUND1CNT_X
.P0201D288:	.word REG_NR12
.P0201D28C:	.word REG_NR11
.L0201D290:
	ldr	r1, .P0201D2AC	@ =REG_NR11
	adds	r0, r4, #0
	adds	r0, #0x64
	ldrb	r0, [r0]
.L0201D298:
	lsls	r0, r0, #6
	strb	r0, [r1]
	ldr	r0, .P0201D2B0	@ =REG_SOUND1CNT_X
	ldr	r1, [r4, #0xc]
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r2, r3, #0
	orrs	r1, r2
	strh	r1, [r0]
	b	.L0201D380
.P0201D2AC:	.word REG_NR11
.P0201D2B0:	.word REG_SOUND1CNT_X
.L0201D2B4:
	ldr	r0, .P0201D2D4	@ =REG_NR22
	strb	r5, [r0]
	ldr	r2, .P0201D2D8	@ =REG_SOUND2CNT_H
	ldr	r0, [r4, #0xc]
	movs	r6, #0x80
	lsls	r6, r6, #8
	adds	r1, r6, #0
	orrs	r0, r1
	strh	r0, [r2]
	ldr	r1, .P0201D2DC	@ =REG_NR21
	adds	r0, r4, #0
	adds	r0, #0x64
	ldrb	r0, [r0]
	lsls	r0, r0, #6
	b	.L0201D37E
	.hword 0x0000
.P0201D2D4:	.word REG_NR22
.P0201D2D8:	.word REG_SOUND2CNT_H
.P0201D2DC:	.word REG_NR21
.L0201D2E0:
	ldr	r6, .P0201D320	@ =gLastWave
	ldr	r1, [r4, #0x64]
	ldr	r0, [r6]
	cmp	r1, r0
	beq	.L0201D2FE
	ldr	r1, .P0201D324	@ =REG_NR30
	movs	r0, #0
	strb	r0, [r1]
	ldr	r0, [r4, #0x64]
	adds	r1, #0x20
	movs	r2, #8
	bl	CpuSet
	ldr	r0, [r4, #0x64]
	str	r0, [r6]
.L0201D2FE:
	ldr	r1, .P0201D324	@ =REG_NR30
	movs	r0, #0xc0
	strb	r0, [r1]
	ldr	r2, .P0201D328	@ =REG_SOUND3CNT_X
	ldr	r0, [r4, #0xc]
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r1, r3, #0
	orrs	r0, r1
	strh	r0, [r2]
	ldr	r1, .P0201D32C	@ =REG_NR32
	ldr	r0, .P0201D330	@ =kWaveVolume
	adds	r0, r5, r0
	ldrb	r0, [r0]
	strb	r0, [r1]
	subs	r1, #1
	b	.L0201D37C
.P0201D320:	.word gLastWave
.P0201D324:	.word REG_NR30
.P0201D328:	.word REG_SOUND3CNT_X
.P0201D32C:	.word REG_NR32
.P0201D330:	.word kWaveVolume
.L0201D334:
	ldr	r0, .P0201D354	@ =REG_NR42
	strb	r5, [r0]
	ldr	r0, [r4, #0x54]
	ldrb	r1, [r0, #1]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0201D358
	ldrh	r0, [r4, #0xc]
	bl	noiseDivider
	lsls	r0, r0, #0x18
	lsrs	r1, r0, #0x18
	ldr	r0, [r4, #0x64]
	ldrb	r0, [r0, #2]
	b	.L0201D368
.P0201D354:	.word REG_NR42
.L0201D358:
	ldrh	r0, [r4, #0xc]
	bl	noiseDivider
	lsls	r0, r0, #0x18
	lsrs	r1, r0, #0x18
	adds	r0, r4, #0
	adds	r0, #0x64
	ldrb	r0, [r0]
.L0201D368:
	cmp	r0, #0
	beq	.L0201D370
	movs	r0, #8
	orrs	r1, r0
.L0201D370:
	ldr	r0, .P0201D388	@ =REG_NR43
	strb	r1, [r0]
	ldr	r1, .P0201D38C	@ =REG_NR44
	movs	r0, #0x80
	strb	r0, [r1]
	subs	r1, #5
.L0201D37C:
	movs	r0, #0
.L0201D37E:
	strb	r0, [r1]
.L0201D380:
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201D388:	.word REG_NR43
.P0201D38C:	.word REG_NR44

@ ======================================================================================
@ voiceAlloc   (0201D390)
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
	bne	.L0201D3EC
	ldr	r0, .P0201D3AC	@ =gFreeVoices
	ldr	r0, [r0]
	cmp	r0, #0
	beq	.L0201D3B0
	adds	r4, r0, #0
	b	.L0201D3CC
	.hword 0x0000
.P0201D3AC:	.word gFreeVoices
.L0201D3B0:
	ldr	r0, .P0201D3E4	@ =gActiveVoices
	ldr	r1, [r0]
	cmp	r1, #0
	beq	.L0201D402
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	bne	.L0201D3C4
	ldrb	r0, [r1, #8]
	cmp	r5, r0
	blo	.L0201D402
.L0201D3C4:
	adds	r4, r1, #0
	adds	r0, r4, #0
	bl	voiceStop
.L0201D3CC:
	ldr	r1, .P0201D3E8	@ =gFreeVoices
	adds	r0, r4, #0
	bl	voiceListRemove
	movs	r0, #1
	strb	r0, [r4, #1]
	strb	r5, [r4, #8]
	adds	r0, r4, #0
	bl	voiceListInsertActive
	b	.L0201D41E
	.hword 0x0000
.P0201D3E4:	.word gActiveVoices
.P0201D3E8:	.word gFreeVoices
.L0201D3EC:
	lsls	r0, r2, #4
	subs	r0, r0, r2
	lsls	r0, r0, #3
	ldr	r1, .P0201D408	@ =gDsVoices+0x2D0
	adds	r4, r0, r1
	ldrb	r0, [r4, #1]
	cmp	r0, #1
	bne	.L0201D40C
	ldrb	r0, [r4, #8]
	cmp	r5, r0
	bhs	.L0201D40C
.L0201D402:
	movs	r0, #0
	b	.L0201D420
	.hword 0x0000
.P0201D408:	.word gDsVoices+0x2D0
.L0201D40C:
	ldrb	r0, [r4, #1]
	cmp	r0, #0
	beq	.L0201D418
	adds	r0, r4, #0
	bl	voiceStop
.L0201D418:
	movs	r0, #1
	strb	r0, [r4, #1]
	strb	r5, [r4, #8]
.L0201D41E:
	adds	r0, r4, #0
.L0201D420:
	pop	{r4, r5}
	pop	{r1}
	bx	r1
	movs	r0, r0

@ ======================================================================================
@ trackInitAll   (0201D428)
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
	ldr	r0, .P0201D450	@ =gTracks
	movs	r1, #0
	adds	r0, #8
	movs	r2, #0x17
.L0201D432:
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
	bge	.L0201D432
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201D450:	.word gTracks

@ ======================================================================================
@ trackAlloc   (0201D454)
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
	ldr	r1, .P0201D468	@ =gTracks
	ldr	r0, .P0201D46C	@ =0x0000078C
	adds	r2, r1, r0
.L0201D45C:
	ldr	r0, [r1, #8]
	cmp	r0, #0
	bne	.L0201D470
	adds	r0, r1, #0
	b	.L0201D478
	.hword 0x0000
.P0201D468:	.word gTracks
.P0201D46C:	.word 0x0000078C
.L0201D470:
	adds	r1, #0x54
	cmp	r1, r2
	ble	.L0201D45C
	movs	r0, #0
.L0201D478:
	pop	{r1}
	bx	r1

@ ======================================================================================
@ trackStart   (0201D47C)
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
	beq	.L0201D532
	ldr	r0, [r5, #8]
	cmp	r0, #0
	beq	.L0201D494
	adds	r0, r5, #0
	bl	trackStop
.L0201D494:
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
	bne	.L0201D506
	adds	r1, #2
	movs	r0, #0xc
	strb	r0, [r1]
	subs	r1, #6
	movs	r0, #0x7f
	strb	r0, [r1]
	adds	r0, r5, #0
	adds	r0, #0x53
	strb	r3, [r0]
	b	.L0201D518
.L0201D506:
	adds	r1, r5, #0
	adds	r1, #0x52
	movs	r0, #3
	strb	r0, [r1]
	adds	r0, r5, #0
	adds	r0, #0x4c
	strb	r2, [r0]
	adds	r0, #7
	strb	r2, [r0]
.L0201D518:
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
.L0201D532:
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ trackReleaseAll   (0201D538)
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
	beq	.L0201D560
	adds	r1, r4, #0
	adds	r1, #0x49
	ldrb	r6, [r1]
	movs	r0, #0
	strb	r0, [r1]
	ldr	r0, [r4, #0xc]
	adds	r5, r1, #0
	cmp	r0, #0
	beq	.L0201D55E
.L0201D552:
	ldr	r4, [r0, #0x74]
	bl	noteOff
	adds	r0, r4, #0
	cmp	r0, #0
	bne	.L0201D552
.L0201D55E:
	strb	r6, [r5]
.L0201D560:
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ trackStop   (0201D568)
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
	beq	.L0201D578
	bl	trackReleaseAll
	movs	r0, #0
	str	r0, [r4, #8]
.L0201D578:
	pop	{r4}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ trackTick   (0201D580)
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
	beq	.L0201D594
	ldr	r1, [r5, #8]
	cmp	r1, #0
	bne	.L0201D598
.L0201D594:
	movs	r0, #1
	b	.L0201D9E4
.L0201D598:
	mov	r8, r1
	mov	r0, r8
	adds	r0, #0x3c
	ldrb	r1, [r0]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	bne	.L0201D5AA
	b	.L0201D9CA
.L0201D5AA:
	adds	r0, r5, #0
	bl	trackReleaseAll
	b	.L0201D9E2
.L0201D5B2:
	adds	r0, r5, #0
	bl	trackStop
	movs	r0, #2
	b	.L0201D9E4
.L0201D5BC:
	ldr	r2, [r5]
	ldrb	r6, [r2]
	adds	r2, #1
	str	r2, [r5]
	cmp	r6, #0xbf
	bhi	.L0201D640
	cmp	r6, #0x5f
	bhi	.L0201D5D8
	adds	r0, r5, #0
	adds	r0, #0x44
	ldrh	r4, [r0]
	adds	r0, #4
	ldrb	r2, [r0]
	b	.L0201D5FE
.L0201D5D8:
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
.L0201D5FE:
	movs	r0, #0x96
	muls	r4, r0, r4
	ldr	r0, .P0201D624	@ =gHookNote
	ldr	r7, [r0]
	cmp	r7, #0
	beq	.L0201D628
	mov	r0, r8
	adds	r0, #0x44
	ldrb	r1, [r0]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0201D628
	adds	r0, r5, #0
	adds	r1, r6, #0
	adds	r3, r4, #0
	bl	_call_via_r7
	b	.L0201D632
.P0201D624:	.word gHookNote
.L0201D628:
	adds	r0, r5, #0
	adds	r1, r6, #0
	adds	r3, r4, #0
	bl	noteOn
.L0201D632:
	adds	r0, r5, #0
	adds	r0, #0x53
	ldrb	r0, [r0]
	cmp	r0, #1
	beq	.L0201D63E
	b	.L0201D9CA
.L0201D63E:
	b	.L0201D664
.L0201D640:
	cmp	r6, #0xc0
	bne	.L0201D64C
	adds	r0, r5, #0
	adds	r0, #0x46
	ldrh	r4, [r0]
	b	.L0201D660
.L0201D64C:
	cmp	r6, #0xc1
	bne	.L0201D66C
	adds	r0, r5, #0
	bl	readVarLen
	lsls	r0, r0, #0x10
	lsrs	r4, r0, #0x10
	adds	r0, r5, #0
	adds	r0, #0x46
	strh	r4, [r0]
.L0201D660:
	movs	r0, #0x96
	muls	r4, r0, r4
.L0201D664:
	ldr	r0, [r5, #0x34]
	adds	r0, r0, r4
	str	r0, [r5, #0x34]
	b	.L0201D9CA
.L0201D66C:
	movs	r0, #0xf0
	ands	r0, r6
	cmp	r0, #0xd0
	bne	.L0201D6AC
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
	beq	.L0201D6A4
	ldrb	r0, [r3, #1]
	strh	r0, [r5, #0x20]
	adds	r0, r2, #1
	str	r0, [r5]
	b	.L0201D6A6
.L0201D6A4:
	strh	r1, [r5, #0x20]
.L0201D6A6:
	movs	r0, #1
	strb	r0, [r5, #0x1c]
	b	.L0201D9CA
.L0201D6AC:
	adds	r0, r6, #0
	subs	r0, #0xc2
	cmp	r0, #0x3d
	bls	.L0201D6B6
	b	.L0201D9CA
.L0201D6B6:
	lsls	r0, r0, #2
	ldr	r1, .P0201D6C0	@ =0x0201D6C4
	adds	r0, r0, r1
	ldr	r0, [r0]
	mov	pc, r0
.P0201D6C0:	.word 0x0201D6C4
	.word .L0201D81A
	.word .L0201D836
	.word .L0201D842
	.word .L0201D896
	.word .L0201D896
	.word .L0201D826
	.word .L0201D8AA
	.word .L0201D8B4
	.word .L0201D8BE
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D84E
	.word .L0201D866
	.word .L0201D872
	.word .L0201D88A
	.word .L0201D8E4
	.word .L0201D8F0
	.word .L0201D900
	.word .L0201D8F8
	.word .L0201D7D2
	.word .L0201D87E
	.word .L0201D85A
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D7D8
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D7F2
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D90C
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D9CA
	.word .L0201D7BC
.L0201D7BC:
	adds	r0, r5, #0
	adds	r0, #0x24
	ldr	r1, [r5, #0x30]
	cmp	r1, r0
	bne	.L0201D7C8
	b	.L0201D5B2
.L0201D7C8:
	subs	r0, r1, #4
	str	r0, [r5, #0x30]
	ldr	r0, [r0]
	str	r0, [r5]
	b	.L0201D9CA
.L0201D7D2:
	movs	r0, #0
	strb	r0, [r5, #0x1c]
	b	.L0201D9CA
.L0201D7D8:
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
	b	.L0201D810
.L0201D7F2:
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
.L0201D810:
	mov	r0, sp
	ldrh	r0, [r0]
	adds	r1, r1, r0
	str	r1, [r5]
	b	.L0201D9CA
.L0201D81A:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x42
	strh	r1, [r2]
	b	.L0201D8DE
.L0201D826:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r0, #1
	str	r0, [r5]
	adds	r0, r5, #0
	bl	trackSetBank
	b	.L0201D9CA
.L0201D836:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x4b
	strb	r1, [r2]
	b	.L0201D8DE
.L0201D842:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x52
	strb	r1, [r2]
	b	.L0201D8DE
.L0201D84E:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x4d
	strb	r1, [r2]
	b	.L0201D8DE
.L0201D85A:
	ldr	r0, [r5, #8]
	ldr	r1, [r5]
	ldrb	r2, [r1]
	adds	r0, #0x40
	strb	r2, [r0]
	b	.L0201D906
.L0201D866:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x4f
	strb	r1, [r2]
	b	.L0201D8DE
.L0201D872:
	ldr	r0, [r5]
	ldrb	r2, [r0]
	adds	r1, r5, #0
	adds	r1, #0x50
	strb	r2, [r1]
	b	.L0201D8DE
.L0201D87E:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x51
	strb	r1, [r2]
	b	.L0201D8DE
.L0201D88A:
	ldr	r0, [r5]
	ldrb	r2, [r0]
	adds	r1, r5, #0
	adds	r1, #0x4c
	strb	r2, [r1]
	b	.L0201D8DE
.L0201D896:
	adds	r0, r5, #0
	bl	trackReleaseAll
	movs	r1, #0
	cmp	r6, #0xc5
	bne	.L0201D8A4
	movs	r1, #1
.L0201D8A4:
	adds	r0, r5, #0
	adds	r0, #0x49
	b	.L0201D9C8
.L0201D8AA:
	adds	r1, r5, #0
	adds	r1, #0x53
	movs	r0, #1
	strb	r0, [r1]
	b	.L0201D9CA
.L0201D8B4:
	adds	r1, r5, #0
	adds	r1, #0x53
	movs	r0, #0
	strb	r0, [r1]
	b	.L0201D9CA
.L0201D8BE:
	ldr	r0, .P0201D8D8	@ =gHookCA
	ldr	r2, [r0]
	cmp	r2, #0
	beq	.L0201D8DC
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r0, #1
	str	r0, [r5]
	adds	r0, r5, #0
	bl	_call_via_r2
	b	.L0201D9CA
	.hword 0x0000
.P0201D8D8:	.word gHookCA
.L0201D8DC:
	ldr	r0, [r5]
.L0201D8DE:
	adds	r0, #1
	str	r0, [r5]
	b	.L0201D9CA
.L0201D8E4:
	adds	r0, r5, #0
	bl	readVarLen
	mov	r3, r8
	strh	r0, [r3, #0x30]
	b	.L0201D9CA
.L0201D8F0:
	ldr	r1, [r5]
	ldrb	r0, [r1]
	strh	r0, [r5, #0x10]
	b	.L0201D906
.L0201D8F8:
	ldr	r1, [r5]
	ldrb	r0, [r1]
	str	r0, [r5, #0x18]
	b	.L0201D906
.L0201D900:
	ldr	r1, [r5]
	ldrb	r0, [r1]
	str	r0, [r5, #0x14]
.L0201D906:
	adds	r1, #1
	str	r1, [r5]
	b	.L0201D9CA
.L0201D90C:
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
	bne	.L0201D940
	bl	trackAlloc
	adds	r4, r0, #0
	str	r4, [r6]
	b	.L0201D946
.L0201D940:
	adds	r4, r0, #0
	bl	trackStop
.L0201D946:
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
.L0201D9C8:
	strb	r1, [r0]
.L0201D9CA:
	ldr	r1, [r5, #0x34]
	cmp	r1, #0
	bgt	.L0201D9D2
	b	.L0201D5BC
.L0201D9D2:
	mov	r2, r8
	ldrh	r0, [r2, #0x30]
	subs	r0, r1, r0
	str	r0, [r5, #0x34]
	movs	r3, #0x32
	ldrsh	r1, [r2, r3]
	subs	r0, r0, r1
	str	r0, [r5, #0x34]
.L0201D9E2:
	movs	r0, #0
.L0201D9E4:
	add	sp, #4
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1

@ ======================================================================================
@ trackAddVoice   (0201D9F0)
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
	bne	.L0201DA08
	str	r0, [r1, #4]
	str	r2, [r1, #0x70]
	ldr	r2, [r0, #0xc]
	str	r2, [r1, #0x74]
	str	r1, [r0, #0xc]
	cmp	r2, #0
	beq	.L0201DA08
	str	r1, [r2, #0x70]
.L0201DA08:
	pop	{r0}
	bx	r0

@ ======================================================================================
@ trackRemoveVoice   (0201DA0C)
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
	beq	.L0201DA34
	movs	r0, #0
	str	r0, [r1, #4]
	ldr	r2, [r1, #0x74]
	cmp	r2, #0
	beq	.L0201DA24
	ldr	r0, [r1, #0x70]
	str	r0, [r2, #0x70]
.L0201DA24:
	ldr	r2, [r1, #0x70]
	cmp	r2, #0
	beq	.L0201DA30
	ldr	r0, [r1, #0x74]
	str	r0, [r2, #0x74]
	b	.L0201DA34
.L0201DA30:
	ldr	r0, [r1, #0x74]
	str	r0, [r3, #0xc]
.L0201DA34:
	pop	{r0}
	bx	r0

@ ======================================================================================
@ readVarLen   (0201DA38)
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
	beq	.L0201DA5A
	movs	r0, #0x7f
	ands	r1, r0
	lsls	r1, r1, #8
	ldrb	r0, [r2]
	orrs	r1, r0
	adds	r0, r2, #1
	str	r0, [r3]
.L0201DA5A:
	adds	r0, r1, #0
	pop	{r1}
	bx	r1

@ ======================================================================================
@ trackSetBank   (0201DA60)
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
	ldr	r0, .P0201DA90	@ =gCfg
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
.P0201DA90:	.word gCfg

@ ======================================================================================
@ playerInitAll   (0201DA94)
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
	ldr	r4, .P0201DAC4	@ =gPlayers
	movs	r3, #0
.L0201DA9C:
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
.L0201DAB0:
	str	r3, [r0]
	subs	r0, #4
	subs	r1, #1
	cmp	r1, #0
	bge	.L0201DAB0
	cmp	r2, #0x13
	ble	.L0201DA9C
	pop	{r4}
	pop	{r0}
	bx	r0
.P0201DAC4:	.word gPlayers

@ ======================================================================================
@ playerReset   (0201DAC8)
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
@ playerTickAll   (0201DB08)
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
.L0201DB0E:
	lsls	r0, r6, #3
	adds	r0, r0, r6
	lsls	r0, r0, #3
	ldr	r1, .P0201DB38	@ =gPlayers
	adds	r1, r0, r1
	adds	r0, r1, #0
	adds	r0, #0x42
	ldrb	r0, [r0]
	adds	r7, r6, #1
	cmp	r0, #0
	beq	.L0201DB8A
	ldrh	r2, [r1, #0x3a]
	cmp	r2, #0
	bne	.L0201DB3C
	cmp	r0, #2
	bne	.L0201DB52
	adds	r0, r6, #0
	bl	playerStop
	b	.L0201DB8A
	.hword 0x0000
.P0201DB38:	.word gPlayers
.L0201DB3C:
	ldrh	r0, [r1, #0x36]
	ldrh	r3, [r1, #0x34]
	adds	r0, r0, r3
	strh	r0, [r1, #0x34]
	subs	r0, r2, #1
	strh	r0, [r1, #0x3a]
	lsls	r0, r0, #0x10
	cmp	r0, #0
	bne	.L0201DB52
	ldrh	r0, [r1, #0x38]
	strh	r0, [r1, #0x34]
.L0201DB52:
	movs	r2, #0
	adds	r7, r6, #1
	adds	r4, r1, #0
	adds	r4, #8
	movs	r5, #9
.L0201DB5C:
	ldr	r0, [r4]
	cmp	r0, #0
	beq	.L0201DB78
	str	r2, [sp]
	bl	trackTick
	lsls	r0, r0, #0x18
	ldr	r2, [sp]
	cmp	r0, #0
	bne	.L0201DB74
	movs	r2, #1
	b	.L0201DB78
.L0201DB74:
	movs	r0, #0
	str	r0, [r4]
.L0201DB78:
	adds	r4, #4
	subs	r5, #1
	cmp	r5, #0
	bge	.L0201DB5C
	cmp	r2, #0
	bne	.L0201DB8A
	adds	r0, r6, #0
	bl	playerStop
.L0201DB8A:
	adds	r6, r7, #0
	cmp	r6, #0x13
	ble	.L0201DB0E
	add	sp, #4
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ doPlaySong   (0201DB98)
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
	ldr	r2, .P0201DBBC	@ =gCfg
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
.P0201DBBC:	.word gCfg

@ ======================================================================================
@ doPlaySfx   (0201DBC0)
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
	ldr	r2, .P0201DBE8	@ =gCfg
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
.P0201DBE8:	.word gCfg

@ ======================================================================================
@ playerStartSong   (0201DBEC)
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
	ldr	r1, .P0201DC70	@ =gPlayers
	adds	r5, r0, r1
	adds	r4, r5, #0
	adds	r4, #0x42
	ldrb	r0, [r4]
	cmp	r0, #0
	beq	.L0201DC12
	adds	r0, r3, #0
	bl	playerStop
.L0201DC12:
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
	bge	.L0201DC5E
	adds	r4, r0, #0
.L0201DC36:
	ldrh	r0, [r4]
	cmp	r0, #0
	beq	.L0201DC56
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
.L0201DC56:
	adds	r4, #2
	adds	r6, #1
	cmp	r6, r7
	blt	.L0201DC36
.L0201DC5E:
	movs	r0, #1
	mov	r1, r8
	strb	r0, [r1]
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201DC70:	.word gPlayers

@ ======================================================================================
@ playerStartSfx   (0201DC74)
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
	ldr	r1, .P0201DCDC	@ =gPlayers
	adds	r5, r0, r1
	movs	r0, #0x42
	adds	r0, r0, r5
	mov	r8, r0
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L0201DCA0
	adds	r0, r4, #0
	bl	playerStop
.L0201DCA0:
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
.P0201DCDC:	.word gPlayers

@ ======================================================================================
@ playerStop   (0201DCE0)
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
	ldr	r0, .P0201DD18	@ =gPlayers
	adds	r1, r1, r0
	adds	r2, r1, #0
	adds	r2, #0x42
	ldrb	r0, [r2]
	cmp	r0, #0
	beq	.L0201DD12
	adds	r7, r2, #0
	movs	r6, #0
	adds	r4, r1, #0
	adds	r4, #8
	movs	r5, #9
.L0201DD00:
	ldr	r0, [r4]
	bl	trackStop
	stm	r4!, {r6}
	subs	r5, #1
	cmp	r5, #0
	bge	.L0201DD00
	movs	r0, #0
	strb	r0, [r7]
.L0201DD12:
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
.P0201DD18:	.word gPlayers

@ ======================================================================================
@ playerFadeOut   (0201DD1C)
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
	ldr	r0, .P0201DD50	@ =gPlayers
	adds	r4, r1, r0
	adds	r2, r4, #0
	adds	r2, #0x42
	ldrb	r0, [r2]
	cmp	r0, #0
	beq	.L0201DD4A
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
.L0201DD4A:
	pop	{r4}
	pop	{r0}
	bx	r0
.P0201DD50:	.word gPlayers

@ ======================================================================================
@ playerSetPause   (0201DD54)
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
	ldr	r3, .P0201DD74	@ =gPlayers
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
.P0201DD74:	.word gPlayers

@ ======================================================================================
@ sndGetPlayerState   (0201DD78)
@
@   u32 sndGetPlayerState(u32 pl)       /* 0 idle, 1 playing, 2 fading out (read directly) */
@   {
@       return gPlayers[pl].state;
@   }
@ ======================================================================================
	.global sndGetPlayerState
	.thumb_func
sndGetPlayerState:
	ldr	r2, .P0201DD88	@ =gPlayers
	lsls	r1, r0, #3
	adds	r1, r1, r0
	lsls	r1, r1, #3
	adds	r2, #0x42
	adds	r1, r1, r2
	ldrb	r0, [r1]
	bx	lr
.P0201DD88:	.word gPlayers

@ ======================================================================================
@ cmdNext   (0201DD8C)
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
	ldr	r2, .P0201DDA8	@ =gCmdWrite
	ldr	r0, [r2]
	adds	r0, #0xc
	str	r0, [r2]
	ldr	r1, .P0201DDAC	@ =gCmdEnd
	ldr	r1, [r1]
	cmp	r0, r1
	bne	.L0201DDA2
	ldr	r0, .P0201DDB0	@ =gCmdQueue
	str	r0, [r2]
.L0201DDA2:
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201DDA8:	.word gCmdWrite
.P0201DDAC:	.word gCmdEnd
.P0201DDB0:	.word gCmdQueue

@ ======================================================================================
@ cmdInit   (0201DDB4)
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
	ldr	r0, .P0201DDD8	@ =gCmdRead
	ldr	r1, .P0201DDDC	@ =gCmdQueue
	str	r1, [r0]
	ldr	r0, .P0201DDE0	@ =gCmdWrite
	str	r1, [r0]
	ldr	r0, .P0201DDE4	@ =gCmdCommitted
	str	r1, [r0]
	ldr	r0, .P0201DDE8	@ =gCmdEnd
	movs	r2, #0x90
	lsls	r2, r2, #2
	adds	r1, r1, r2
	str	r1, [r0]
	ldr	r0, .P0201DDEC	@ =gHookNote
	movs	r1, #0
	str	r1, [r0]
	ldr	r0, .P0201DDF0	@ =gHookCA
	str	r1, [r0]
	bx	lr
.P0201DDD8:	.word gCmdRead
.P0201DDDC:	.word gCmdQueue
.P0201DDE0:	.word gCmdWrite
.P0201DDE4:	.word gCmdCommitted
.P0201DDE8:	.word gCmdEnd
.P0201DDEC:	.word gHookNote
.P0201DDF0:	.word gHookCA

@ ======================================================================================
@ cmdPop   (0201DDF4)
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
	ldr	r3, .P0201DE08	@ =gCmdRead
	ldr	r2, [r3]
	ldr	r0, .P0201DE0C	@ =gCmdCommitted
	ldr	r0, [r0]
	cmp	r2, r0
	bne	.L0201DE10
	movs	r0, #0
	b	.L0201DE24
	.hword 0x0000
.P0201DE08:	.word gCmdRead
.P0201DE0C:	.word gCmdCommitted
.L0201DE10:
	adds	r0, r2, #0
	adds	r0, #0xc
	str	r0, [r3]
	ldr	r1, .P0201DE28	@ =gCmdEnd
	ldr	r1, [r1]
	cmp	r0, r1
	bne	.L0201DE22
	ldr	r0, .P0201DE2C	@ =gCmdQueue
	str	r0, [r3]
.L0201DE22:
	adds	r0, r2, #0
.L0201DE24:
	pop	{r1}
	bx	r1
.P0201DE28:	.word gCmdEnd
.P0201DE2C:	.word gCmdQueue

@ ======================================================================================
@ sndCommit   (0201DE30)
@
@   void sndCommit(void)                /* make the commands queued since the last call visible */
@   {
@       gCmdCommitted = gCmdWrite;      /* no overflow check: 47 queued commands lose 46         */
@   }
@ ======================================================================================
	.global sndCommit
	.thumb_func
sndCommit:
	ldr	r0, .P0201DE3C	@ =gCmdCommitted
	ldr	r1, .P0201DE40	@ =gCmdWrite
	ldr	r1, [r1]
	str	r1, [r0]
	bx	lr
	.hword 0x0000
.P0201DE3C:	.word gCmdCommitted
.P0201DE40:	.word gCmdWrite

@ ======================================================================================
@ sndPlaySong   (0201DE44)
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
	ldr	r2, .P0201DE64	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #0
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201DE64:	.word gCmdWrite

@ ======================================================================================
@ sndPlaySfx   (0201DE68)
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
	ldr	r3, .P0201DE8C	@ =gCmdWrite
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
.P0201DE8C:	.word gCmdWrite

@ ======================================================================================
@ sndFadeOut   (0201DE90)
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
	ldr	r2, .P0201DEB0	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #2
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201DEB0:	.word gCmdWrite

@ ======================================================================================
@ sndPause   (0201DEB4)
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
	ldr	r2, .P0201DED4	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #3
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201DED4:	.word gCmdWrite

@ ======================================================================================
@ sndFadeOutMask   (0201DED8)
@
@   void sndFadeOutMask(u32 mask, u32 frames)      { queue(0x200, frames, mask); }
@ ======================================================================================
	.global sndFadeOutMask
	.thumb_func
sndFadeOutMask:
	push	{lr}
	lsls	r1, r1, #0x10
	lsrs	r1, r1, #0x10
	ldr	r2, .P0201DEF4	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #0x80
	lsls	r3, r3, #2
	strh	r3, [r2]
	str	r1, [r2, #4]
	str	r0, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
.P0201DEF4:	.word gCmdWrite

@ ======================================================================================
@ sndPauseMask   (0201DEF8)
@
@   void sndPauseMask(u32 mask, u32 on)            { queue(0x201, on, mask); }
@ ======================================================================================
	.global sndPauseMask
	.thumb_func
sndPauseMask:
	push	{lr}
	lsls	r1, r1, #0x18
	lsrs	r1, r1, #0x18
	ldr	r2, .P0201DF14	@ =gCmdWrite
	ldr	r2, [r2]
	ldr	r3, .P0201DF18	@ =0x00000201
	strh	r3, [r2]
	str	r1, [r2, #4]
	str	r0, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201DF14:	.word gCmdWrite
.P0201DF18:	.word 0x00000201

@ ======================================================================================
@ sndSetTempo   (0201DF1C)
@
@   void sndSetTempo(u32 pl, s32 ofs)              { queue(0x004, pl, ofs); }   /* tempo offset   */
@ ======================================================================================
	.global sndSetTempo
	.thumb_func
sndSetTempo:
	push	{lr}
	lsls	r0, r0, #0x10
	lsrs	r0, r0, #0x10
	ldr	r2, .P0201DF3C	@ =gCmdWrite
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
.P0201DF3C:	.word gCmdWrite

@ ======================================================================================
@ sndSetVolume2   (0201DF40)
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
	ldr	r2, .P0201DF60	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #5
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201DF60:	.word gCmdWrite

@ ======================================================================================
@ sndSetHookFlags   (0201DF64)
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
	ldr	r2, .P0201DF84	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #6
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201DF84:	.word gCmdWrite

@ ======================================================================================
@ sndMuteTracks   (0201DF88)
@
@   void sndMuteTracks(u32 pl, u32 mask, u32 on)   { queue(0x100, pl << 16 | on, mask); }
@ ======================================================================================
	.global sndMuteTracks
	.thumb_func
sndMuteTracks:
	push	{r4, lr}
	lsls	r2, r2, #0x18
	lsrs	r2, r2, #0x18
	ldr	r3, .P0201DFAC	@ =gCmdWrite
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
.P0201DFAC:	.word gCmdWrite

@ ======================================================================================
@ sndSetTrackExpr   (0201DFB0)
@
@   void sndSetTrackExpr(u32 pl, u32 mask, u32 v)  { queue(0x102, pl << 16 | v, mask); }
@ ======================================================================================
	.global sndSetTrackExpr
	.thumb_func
sndSetTrackExpr:
	push	{r4, lr}
	lsls	r2, r2, #0x18
	lsrs	r2, r2, #0x18
	ldr	r3, .P0201DFD4	@ =gCmdWrite
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
.P0201DFD4:	.word gCmdWrite

@ ======================================================================================
@ sndSetTrackBend   (0201DFD8)
@
@   void sndSetTrackBend(u32 pl, u32 mask, u32 range, u32 bend) { queue(0x103, pl << 16 | range << 8 | bend, mask); }
@ ======================================================================================
	.global sndSetTrackBend
	.thumb_func
sndSetTrackBend:
	push	{r4, r5, lr}
	lsls	r0, r0, #0x10
	lsls	r2, r2, #0x18
	ldr	r4, .P0201E000	@ =gCmdWrite
	ldr	r5, [r4]
	ldr	r4, .P0201E004	@ =0x00000103
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
.P0201E000:	.word gCmdWrite
.P0201E004:	.word 0x00000103

@ ======================================================================================
@ sndSetTrackPan   (0201E008)
@
@   void sndSetTrackPan(u32 pl, u32 mask, u32 pan) { queue(0x101, pl << 16 | pan, mask); }
@ ======================================================================================
	.global sndSetTrackPan
	.thumb_func
sndSetTrackPan:
	push	{r4, lr}
	lsls	r2, r2, #0x18
	lsrs	r2, r2, #0x18
	ldr	r3, .P0201E028	@ =gCmdWrite
	ldr	r4, [r3]
	ldr	r3, .P0201E02C	@ =0x00000101
	strh	r3, [r4]
	lsls	r0, r0, #0x10
	orrs	r0, r2
	str	r0, [r4, #4]
	str	r1, [r4, #8]
	bl	cmdNext
	pop	{r4}
	pop	{r0}
	bx	r0
.P0201E028:	.word gCmdWrite
.P0201E02C:	.word 0x00000101

@ ======================================================================================
@ sndSetEcho   (0201E030)
@
@   void sndSetEcho(u32 shift)                     { queue(0x300, shift); }     /* 16 = off       */
@ ======================================================================================
	.global sndSetEcho
	.thumb_func
sndSetEcho:
	push	{lr}
	lsls	r0, r0, #0x18
	lsrs	r0, r0, #0x18
	ldr	r1, .P0201E04C	@ =gCmdWrite
	ldr	r2, [r1]
	movs	r1, #0xc0
	lsls	r1, r1, #2
	strh	r1, [r2]
	str	r0, [r2, #4]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201E04C:	.word gCmdWrite

@ ======================================================================================
@ sndSetVoices   (0201E050)
@
@   void sndSetVoices(u32 n)                       { queue(0x304, n); }
@ ======================================================================================
	.global sndSetVoices
	.thumb_func
sndSetVoices:
	push	{lr}
	lsls	r0, r0, #0x18
	lsrs	r0, r0, #0x18
	ldr	r1, .P0201E06C	@ =gCmdWrite
	ldr	r2, [r1]
	movs	r1, #0xc1
	lsls	r1, r1, #2
	strh	r1, [r2]
	str	r0, [r2, #4]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201E06C:	.word gCmdWrite

@ ======================================================================================
@ sndCallback   (0201E070)
@
@   void sndCallback(void (*fn)(u32), u32 arg)     { queue(0x301, fn, arg); }   /* run fn(arg) in sndMain */
@ ======================================================================================
	.global sndCallback
	.thumb_func
sndCallback:
	push	{lr}
	ldr	r2, .P0201E088	@ =gCmdWrite
	ldr	r2, [r2]
	ldr	r3, .P0201E08C	@ =0x00000301
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201E088:	.word gCmdWrite
.P0201E08C:	.word 0x00000301

@ ======================================================================================
@ sndSetHookCA   (0201E090)
@
@   void sndSetHookCA(void *fn)                    { queue(0x302, fn); }
@ ======================================================================================
	.global sndSetHookCA
	.thumb_func
sndSetHookCA:
	push	{lr}
	ldr	r1, .P0201E0A4	@ =gCmdWrite
	ldr	r2, [r1]
	ldr	r1, .P0201E0A8	@ =0x00000302
	strh	r1, [r2]
	str	r0, [r2, #4]
	bl	cmdNext
	pop	{r0}
	bx	r0
.P0201E0A4:	.word gCmdWrite
.P0201E0A8:	.word 0x00000302

@ ======================================================================================
@ sndSetHookNote   (0201E0AC)
@
@   void sndSetHookNote(void *fn)                  { queue(0x303, fn); }
@ ======================================================================================
	.global sndSetHookNote
	.thumb_func
sndSetHookNote:
	push	{lr}
	ldr	r1, .P0201E0C0	@ =gCmdWrite
	ldr	r2, [r1]
	ldr	r1, .P0201E0C4	@ =0x00000303
	strh	r1, [r2]
	str	r0, [r2, #4]
	bl	cmdNext
	pop	{r0}
	bx	r0
.P0201E0C0:	.word gCmdWrite
.P0201E0C4:	.word 0x00000303

@ ======================================================================================
@ cmdPlayer   (0201E0C8)
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
	ldr	r0, .P0201E0E8	@ =gPlayers
	adds	r2, r1, r0
	ldrh	r0, [r3]
	cmp	r0, #6
	bhi	.L0201E156
	lsls	r0, r0, #2
	ldr	r1, .P0201E0EC	@ =0x0201E0F0
	adds	r0, r0, r1
	ldr	r0, [r0]
	mov	pc, r0
.P0201E0E8:	.word gPlayers
.P0201E0EC:	.word 0x0201E0F0
	.word .L0201E10C
	.word .L0201E116
	.word .L0201E12C
	.word .L0201E136
	.word .L0201E148
	.word .L0201E14E
	.word .L0201E140
.L0201E10C:
	ldr	r0, [r3, #4]
	ldr	r1, [r3, #8]
	bl	doPlaySong
	b	.L0201E156
.L0201E116:
	ldr	r1, [r3, #4]
	lsrs	r0, r1, #0x10
	ldr	r2, .P0201E128	@ =0x0000FFFF
	ands	r1, r2
	ldr	r2, [r3, #8]
	bl	doPlaySfx
	b	.L0201E156
	.hword 0x0000
.P0201E128:	.word 0x0000FFFF
.L0201E12C:
	ldr	r0, [r3, #4]
	ldr	r1, [r3, #8]
	bl	playerFadeOut
	b	.L0201E156
.L0201E136:
	ldr	r0, [r3, #4]
	ldrb	r1, [r3, #8]
	bl	playerSetPause
	b	.L0201E156
.L0201E140:
	ldr	r1, [r3, #8]
	adds	r0, r2, #0
	adds	r0, #0x44
	b	.L0201E154
.L0201E148:
	ldr	r0, [r3, #8]
	strh	r0, [r2, #0x32]
	b	.L0201E156
.L0201E14E:
	ldr	r1, [r3, #8]
	adds	r0, r2, #0
	adds	r0, #0x41
.L0201E154:
	strb	r1, [r0]
.L0201E156:
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ cmdTrack   (0201E15C)
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
	ldr	r0, .P0201E184	@ =gPlayers
	adds	r1, r1, r0
	movs	r5, #0
	ldrh	r2, [r3]
	ldr	r0, .P0201E188	@ =0x00000101
	cmp	r2, r0
	beq	.L0201E240
	cmp	r2, r0
	bgt	.L0201E18C
	subs	r0, #1
	cmp	r2, r0
	beq	.L0201E19C
	b	.L0201E270
.P0201E184:	.word gPlayers
.P0201E188:	.word 0x00000101
.L0201E18C:
	movs	r0, #0x81
	lsls	r0, r0, #1
	cmp	r2, r0
	beq	.L0201E1CE
	adds	r0, #1
	cmp	r2, r0
	beq	.L0201E200
	b	.L0201E270
.L0201E19C:
	lsls	r0, r4, #0x18
	lsrs	r2, r0, #0x18
	ldr	r0, [r3, #8]
	cmp	r0, #0
	beq	.L0201E270
	movs	r4, #1
	adds	r1, #8
.L0201E1AA:
	ands	r0, r4
	cmp	r0, #0
	beq	.L0201E1BA
	ldr	r0, [r1]
	cmp	r0, #0
	beq	.L0201E1BA
	adds	r0, #0x4a
	strb	r2, [r0]
.L0201E1BA:
	adds	r1, #4
	adds	r5, #1
	ldr	r0, [r3, #8]
	lsrs	r0, r0, #1
	str	r0, [r3, #8]
	cmp	r0, #0
	beq	.L0201E270
	cmp	r5, #9
	ble	.L0201E1AA
	b	.L0201E270
.L0201E1CE:
	lsls	r0, r4, #0x18
	lsrs	r2, r0, #0x18
	ldr	r0, [r3, #8]
	cmp	r0, #0
	beq	.L0201E270
	movs	r4, #1
	adds	r1, #8
.L0201E1DC:
	ands	r0, r4
	cmp	r0, #0
	beq	.L0201E1EC
	ldr	r0, [r1]
	cmp	r0, #0
	beq	.L0201E1EC
	adds	r0, #0x4e
	strb	r2, [r0]
.L0201E1EC:
	adds	r1, #4
	adds	r5, #1
	ldr	r0, [r3, #8]
	lsrs	r0, r0, #1
	str	r0, [r3, #8]
	cmp	r0, #0
	beq	.L0201E270
	cmp	r5, #9
	ble	.L0201E1DC
	b	.L0201E270
.L0201E200:
	movs	r0, #0xff
	lsls	r0, r0, #8
	ands	r0, r4
	lsrs	r2, r0, #8
	lsls	r0, r4, #0x18
	lsrs	r4, r0, #0x18
	ldr	r0, [r3, #8]
	cmp	r0, #0
	beq	.L0201E270
	movs	r6, #1
	adds	r1, #8
.L0201E216:
	ands	r0, r6
	cmp	r0, #0
	beq	.L0201E22C
	ldr	r0, [r1]
	cmp	r0, #0
	beq	.L0201E22C
	adds	r0, #0x50
	strb	r2, [r0]
	ldr	r0, [r1]
	adds	r0, #0x4f
	strb	r4, [r0]
.L0201E22C:
	adds	r1, #4
	adds	r5, #1
	ldr	r0, [r3, #8]
	lsrs	r0, r0, #1
	str	r0, [r3, #8]
	cmp	r0, #0
	beq	.L0201E270
	cmp	r5, #9
	ble	.L0201E216
	b	.L0201E270
.L0201E240:
	lsls	r0, r4, #0x18
	lsrs	r2, r0, #0x18
	ldr	r0, [r3, #8]
	cmp	r0, #0
	beq	.L0201E270
	movs	r4, #1
	adds	r1, #8
.L0201E24E:
	ands	r0, r4
	cmp	r0, #0
	beq	.L0201E25E
	ldr	r0, [r1]
	cmp	r0, #0
	beq	.L0201E25E
	adds	r0, #0x4b
	strb	r2, [r0]
.L0201E25E:
	adds	r1, #4
	adds	r5, #1
	ldr	r0, [r3, #8]
	lsrs	r0, r0, #1
	str	r0, [r3, #8]
	cmp	r0, #0
	beq	.L0201E270
	cmp	r5, #9
	ble	.L0201E24E
.L0201E270:
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ cmdMask   (0201E278)
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
	beq	.L0201E290
	adds	r0, #1
	cmp	r1, r0
	beq	.L0201E2BA
	b	.L0201E2E2
.L0201E290:
	ldr	r1, [r4, #8]
	cmp	r1, #0
	beq	.L0201E2E2
.L0201E296:
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0201E2A6
	ldr	r1, [r4, #4]
	adds	r0, r5, #0
	bl	playerFadeOut
.L0201E2A6:
	adds	r5, #1
	ldr	r0, [r4, #8]
	lsrs	r0, r0, #1
	str	r0, [r4, #8]
	adds	r1, r0, #0
	cmp	r1, #0
	beq	.L0201E2E2
	cmp	r5, #0x13
	ble	.L0201E296
	b	.L0201E2E2
.L0201E2BA:
	ldr	r1, [r4, #8]
	cmp	r1, #0
	beq	.L0201E2E2
.L0201E2C0:
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0201E2D0
	ldrb	r1, [r4, #4]
	adds	r0, r5, #0
	bl	playerSetPause
.L0201E2D0:
	adds	r5, #1
	ldr	r0, [r4, #8]
	lsrs	r0, r0, #1
	str	r0, [r4, #8]
	adds	r1, r0, #0
	cmp	r1, #0
	beq	.L0201E2E2
	cmp	r5, #0x13
	ble	.L0201E2C0
.L0201E2E2:
	pop	{r4, r5}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ cmdGlobal   (0201E2E8)
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
	ldr	r1, .P0201E300	@ =0xFFFFFD00
	adds	r0, r0, r1
	cmp	r0, #4
	bhi	.L0201E34A
	lsls	r0, r0, #2
	ldr	r1, .P0201E304	@ =0x0201E308
	adds	r0, r0, r1
	ldr	r0, [r0]
	mov	pc, r0
.P0201E300:	.word 0xFFFFFD00
.P0201E304:	.word 0x0201E308
	.word .L0201E33C
	.word .L0201E31C
	.word .L0201E326
	.word .L0201E330
	.word .L0201E344
.L0201E31C:
	ldr	r0, [r2, #8]
	ldr	r1, [r2, #4]
	bl	_call_via_r1
	b	.L0201E34A
.L0201E326:
	ldr	r1, .P0201E32C	@ =gHookCA
	b	.L0201E332
	.hword 0x0000
.P0201E32C:	.word gHookCA
.L0201E330:
	ldr	r1, .P0201E338	@ =gHookNote
.L0201E332:
	ldr	r0, [r2, #4]
	str	r0, [r1]
	b	.L0201E34A
.P0201E338:	.word gHookNote
.L0201E33C:
	ldrb	r0, [r2, #4]
	bl	echoSetFeedback
	b	.L0201E34A
.L0201E344:
	ldrb	r0, [r2, #4]
	bl	voiceSetCount
.L0201E34A:
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ cmdProcess   (0201E350)
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
	beq	.L0201E378
	ldr	r4, .P0201E380	@ =kCmdHandlers
.L0201E35E:
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
	bne	.L0201E35E
.L0201E378:
	pop	{r4}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201E380:	.word kCmdHandlers
	.arm

@ ======================================================================================
@ armDownmix   (0201E384)
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
.L0201E394:
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
	bne	.L0201E394
	pop	{r4, r5}
	bx	lr

@ ======================================================================================
@ armMixVoice   (0201E4A4)
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
	bne	.L0201E564
.L0201E4C0:
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
	blo	.L0201E4C0
	mov	r0, r4
	pop	{r4, r5, r6, r7, r8}
	bx	lr
.L0201E564:
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
	blo	.L0201E564
	mov	r0, r4
	pop	{r4, r5, r6, r7, r8}
	bx	lr

@ ======================================================================================
@ armEcho   (0201E59C)
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
.L0201E5AC:
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
	blo	.L0201E5AC
	pop	{r4, r5}
	bx	lr
