@ --------------------------------------------------------------------------------------
@ sma3_mb_sound.s - sound driver of Super Mario Advance 3 (E), Mario Bros. multiboot image
@ Thumb code 0201C0F0-0201E2F8, ARM mixing loops 0201E2F8-0201E5D8 (copied to IWRAM by sndInit).
@ Generated from the ROM by gen_sources.py; names and comments from the analysis.
@ The pseudo-C above each function describes the Super Mario Advance 4 build; where this
@ build differs, the difference is given after "In this build".
@ Rebuilds byte-identical: see Makefile.
@ --------------------------------------------------------------------------------------
	.syntax unified
	.equ GEN_A, 1
	.include "nsnd.inc"
	.include "sma3_mb_ram.inc"
	.section .snd_code, "ax"
	.thumb

@ ======================================================================================
@ sndInit   (0201C0F0)
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
	ldr	r1, .P0201C178	@ =gCfg
	str	r0, [r1]
	ldr	r1, .P0201C17C	@ =REG_SOUNDCNT_X
	movs	r0, #0
	strb	r0, [r1]
	movs	r0, #0x80
	strb	r0, [r1]
	subs	r1, #4
	ldr	r2, .P0201C180	@ =0x0000FF77
	adds	r0, r2, #0
	strh	r0, [r1]
	adds	r1, #2
	movs	r0, #0xd
	strb	r0, [r1]
	ldr	r2, .P0201C184	@ =REG_SOUNDBIAS
	ldrh	r1, [r2]
	ldr	r0, .P0201C188	@ =0x00003FFF
	ands	r0, r1
	movs	r3, #0x80
	lsls	r3, r3, #7
	adds	r1, r3, #0
	orrs	r0, r1
	strh	r0, [r2]
	ldr	r1, .P0201C18C	@ =REG_NR10
	movs	r0, #8
	strh	r0, [r1]
	adds	r1, #2
	movs	r2, #0xf0
	lsls	r2, r2, #8
	adds	r0, r2, #0
	strh	r0, [r1]
	ldr	r5, .P0201C190	@ =armDownmix
	ldr	r4, .P0201C194	@ =gIwramCode
	adds	r0, r5, #0
	adds	r1, r4, #0
	movs	r2, #0xd8
	bl	CpuFastSet
	ldr	r0, .P0201C198	@ =gFnDownmix
	str	r4, [r0]
	ldr	r1, .P0201C19C	@ =gFnMixVoice
	ldr	r0, .P0201C1A0	@ =armMixVoice
	subs	r0, r0, r5
	adds	r0, r0, r4
	str	r0, [r1]
	ldr	r1, .P0201C1A4	@ =gFnEcho
	ldr	r0, .P0201C1A8	@ =armEcho
	subs	r0, r0, r5
	adds	r0, r0, r4
	str	r0, [r1]
	ldr	r0, .P0201C1AC	@ =gDmaBuffers
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
.P0201C178:	.word gCfg
.P0201C17C:	.word REG_SOUNDCNT_X
.P0201C180:	.word 0x0000FF77
.P0201C184:	.word REG_SOUNDBIAS
.P0201C188:	.word 0x00003FFF
.P0201C18C:	.word REG_NR10
.P0201C190:	.word armDownmix
.P0201C194:	.word gIwramCode
.P0201C198:	.word gFnDownmix
.P0201C19C:	.word gFnMixVoice
.P0201C1A0:	.word armMixVoice
.P0201C1A4:	.word gFnEcho
.P0201C1A8:	.word armEcho
.P0201C1AC:	.word gDmaBuffers

@ ======================================================================================
@ sndVSync   (0201C1B0)
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
@ sndMain   (0201C1BC)
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
	ldr	r0, .P0201C1DC	@ =gMixEnabled
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L0201C1D6
	bl	mixFrame
.L0201C1D6:
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201C1DC:	.word gMixEnabled

@ ======================================================================================
@ mixInit   (0201C1E0)
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
	ldr	r1, .P0201C230	@ =gMixEnabled
	movs	r0, #1
	strb	r0, [r1]
	ldr	r1, .P0201C234	@ =gDmaBufA
	str	r3, [r1]
	ldr	r2, .P0201C238	@ =gDmaBufB
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
	ldr	r1, .P0201C23C	@ =gTimerReload
	ldr	r2, .P0201C240	@ =0x0000F9C4
	adds	r0, r2, #0
	strh	r0, [r1]
	ldr	r1, .P0201C244	@ =gDmaBufIdx
	movs	r0, #0
	strb	r0, [r1]
	ldr	r1, .P0201C248	@ =REG_SOUNDCNT_H+1
	movs	r0, #0x9a
	strb	r0, [r1]
	ldr	r0, .P0201C24C	@ =REG_FIFO_A
	movs	r1, #0
	str	r1, [r0]
	adds	r0, #4
	str	r1, [r0]
	add	sp, #4
	pop	{r4}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201C230:	.word gMixEnabled
.P0201C234:	.word gDmaBufA
.P0201C238:	.word gDmaBufB
.P0201C23C:	.word gTimerReload
.P0201C240:	.word 0x0000F9C4
.P0201C244:	.word gDmaBufIdx
.P0201C248:	.word REG_SOUNDCNT_H+1
.P0201C24C:	.word REG_FIFO_A

@ ======================================================================================
@ mixDmaRestart   (0201C250)
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
	ldr	r2, .P0201C2CC	@ =REG_TM0CNT
	ldr	r0, .P0201C2D0	@ =gTimerReload
	ldrh	r0, [r0]
	movs	r1, #0x80
	lsls	r1, r1, #0x10
	orrs	r0, r1
	str	r0, [r2]
	ldr	r0, .P0201C2D4	@ =gMixEnabled
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L0201C2C4
	ldr	r4, .P0201C2D8	@ =REG_DMA1SAD
	ldrh	r1, [r4, #0xa]
	ldr	r2, .P0201C2DC	@ =0x0000C5FF
	adds	r0, r2, #0
	ands	r0, r1
	strh	r0, [r4, #0xa]
	ldrh	r3, [r4, #0xa]
	ldr	r1, .P0201C2E0	@ =0x00007FFF
	adds	r0, r1, #0
	ands	r0, r3
	strh	r0, [r4, #0xa]
	ldrh	r0, [r4, #0xa]
	ldr	r3, .P0201C2E4	@ =REG_DMA2SAD
	ldrh	r0, [r3, #0xa]
	ands	r2, r0
	strh	r2, [r3, #0xa]
	ldrh	r0, [r3, #0xa]
	ands	r1, r0
	strh	r1, [r3, #0xa]
	ldrh	r0, [r3, #0xa]
	ldr	r1, .P0201C2E8	@ =gDmaBufA
	ldr	r2, .P0201C2EC	@ =gDmaBufIdx
	ldrb	r0, [r2]
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r0, [r0]
	str	r0, [r4]
	ldr	r0, .P0201C2F0	@ =REG_FIFO_A
	str	r0, [r4, #4]
	ldr	r5, .P0201C2F4	@ =0xB6400004
	str	r5, [r4, #8]
	ldr	r0, [r4, #8]
	ldr	r1, .P0201C2F8	@ =gDmaBufB
	ldrb	r0, [r2]
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r0, [r0]
	str	r0, [r3]
	ldr	r0, .P0201C2FC	@ =REG_FIFO_B
	str	r0, [r3, #4]
	str	r5, [r3, #8]
	ldr	r0, [r3, #8]
	ldrb	r1, [r2]
	movs	r0, #1
	subs	r0, r0, r1
	strb	r0, [r2]
.L0201C2C4:
	pop	{r4, r5}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201C2CC:	.word REG_TM0CNT
.P0201C2D0:	.word gTimerReload
.P0201C2D4:	.word gMixEnabled
.P0201C2D8:	.word REG_DMA1SAD
.P0201C2DC:	.word 0x0000C5FF
.P0201C2E0:	.word 0x00007FFF
.P0201C2E4:	.word REG_DMA2SAD
.P0201C2E8:	.word gDmaBufA
.P0201C2EC:	.word gDmaBufIdx
.P0201C2F0:	.word REG_FIFO_A
.P0201C2F4:	.word 0xB6400004
.P0201C2F8:	.word gDmaBufB
.P0201C2FC:	.word REG_FIFO_B

@ ======================================================================================
@ sndStopOutput   (0201C300)
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
	ldr	r1, .P0201C338	@ =gMixEnabled
	movs	r0, #0
	strb	r0, [r1]
	ldr	r1, .P0201C33C	@ =REG_DMA1SAD
	ldrh	r2, [r1, #0xa]
	ldr	r3, .P0201C340	@ =0x0000C5FF
	adds	r0, r3, #0
	ands	r0, r2
	strh	r0, [r1, #0xa]
	ldrh	r4, [r1, #0xa]
	ldr	r2, .P0201C344	@ =0x00007FFF
	adds	r0, r2, #0
	ands	r0, r4
	strh	r0, [r1, #0xa]
	ldrh	r0, [r1, #0xa]
	ldr	r0, .P0201C348	@ =REG_DMA2SAD
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
.P0201C338:	.word gMixEnabled
.P0201C33C:	.word REG_DMA1SAD
.P0201C340:	.word 0x0000C5FF
.P0201C344:	.word 0x00007FFF
.P0201C348:	.word REG_DMA2SAD

@ ======================================================================================
@ sndStartOutput   (0201C34C)
@
@   void sndStartOutput(void)
@   {
@       gMixEnabled = 1;        /* DMA restarts at the next sndVSync */
@   }
@ ======================================================================================
	.global sndStartOutput
	.thumb_func
sndStartOutput:
	ldr	r1, .P0201C354	@ =gMixEnabled
	movs	r0, #1
	strb	r0, [r1]
	bx	lr
.P0201C354:	.word gMixEnabled

@ ======================================================================================
@ voiceInitAll   (0201C358)
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
	mov	r7, r8
	push	{r7}
	ldr	r1, .P0201C4B0	@ =gLastWave
	movs	r0, #0
	str	r0, [r1]
	adds	r3, r1, #0
	ldr	r2, .P0201C4B4	@ =gPsgVoices
	ldr	r0, .P0201C4B8	@ =gDsVoices
	mov	ip, r0
	movs	r1, #0xb6
	lsls	r1, r1, #1
	adds	r7, r3, r1
	movs	r1, #0
	movs	r4, #3
	ldr	r5, .P0201C4BC	@ =0x00000169
	adds	r0, r2, r5
.L0201C37A:
	strb	r1, [r0]
	subs	r0, #0x78
	subs	r4, #1
	cmp	r4, #0
	bge	.L0201C37A
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
	ldr	r0, .P0201C4B8	@ =gDsVoices
	movs	r4, #6
.L0201C3A6:
	strb	r1, [r0, #1]
	strb	r1, [r0]
	adds	r0, #0x78
	subs	r4, #1
	cmp	r4, #0
	bge	.L0201C3A6
	movs	r2, #0xb0
	lsls	r2, r2, #1
	adds	r0, r3, r2
	mov	r5, ip
	str	r5, [r0]
	mov	r1, ip
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
.L0201C404:
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
	bge	.L0201C404
	movs	r0, #0xcf
	lsls	r0, r0, #2
	add	r0, ip
	strb	r7, [r0]
	lsrs	r1, r7, #8
	ldr	r0, .P0201C4C0	@ =0x0000033D
	add	r0, ip
	strb	r1, [r0]
	lsrs	r1, r7, #0x10
	ldr	r0, .P0201C4C4	@ =0x0000033E
	add	r0, ip
	strb	r1, [r0]
	lsrs	r1, r7, #0x18
	ldr	r0, .P0201C4C8	@ =0x0000033F
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
	ldr	r0, .P0201C4CC	@ =0x00000339
	add	r0, ip
	strb	r2, [r0]
	lsrs	r2, r1, #0x10
	ldr	r0, .P0201C4D0	@ =0x0000033A
	add	r0, ip
	strb	r2, [r0]
	lsrs	r1, r1, #0x18
	ldr	r0, .P0201C4D4	@ =0x0000033B
	add	r0, ip
	strb	r1, [r0]
	ldr	r0, .P0201C4D8	@ =0xFFFFFE94
	adds	r1, r7, r0
	movs	r0, #0xb4
	lsls	r0, r0, #2
	add	r0, ip
	str	r0, [r7, #0x68]
	adds	r0, r7, #0
	subs	r0, #0xf0
	str	r0, [r1, #0x70]
	adds	r1, r7, #0
	subs	r1, #0x88
	ldr	r2, .P0201C4DC	@ =0xFFFFFE98
	adds	r0, r7, r2
	str	r0, [r1]
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201C4B0:	.word gLastWave
.P0201C4B4:	.word gPsgVoices
.P0201C4B8:	.word gDsVoices
.P0201C4BC:	.word 0x00000169
.P0201C4C0:	.word 0x0000033D
.P0201C4C4:	.word 0x0000033E
.P0201C4C8:	.word 0x0000033F
.P0201C4CC:	.word 0x00000339
.P0201C4D0:	.word 0x0000033A
.P0201C4D4:	.word 0x0000033B
.P0201C4D8:	.word 0xFFFFFE94
.P0201C4DC:	.word 0xFFFFFE98

@ ======================================================================================
@ voiceUnlink   (0201C4E0)
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
@ voiceListInsertActive   (0201C4F0)
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
	ldr	r0, .P0201C52C	@ =gLastWave
	ldr	r1, [r0, #0x70]
	ldrb	r2, [r3, #1]
	cmp	r2, #1
	bne	.L0201C534
	adds	r0, #0x7c
	cmp	r1, r0
	beq	.L0201C564
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	bne	.L0201C512
	ldrb	r0, [r3, #8]
	ldrb	r2, [r1, #8]
	cmp	r0, r2
	blo	.L0201C564
.L0201C512:
	ldr	r1, [r1, #0x6c]
	ldr	r0, .P0201C530	@ =gActiveTail
	cmp	r1, r0
	beq	.L0201C564
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	bne	.L0201C512
	ldrb	r0, [r3, #8]
	ldrb	r4, [r1, #8]
	cmp	r0, r4
	bhs	.L0201C512
	b	.L0201C564
	.hword 0x0000
.P0201C52C:	.word gLastWave
.P0201C530:	.word gActiveTail
.L0201C534:
	cmp	r2, #2
	bne	.L0201C570
	adds	r2, r0, #0
	adds	r2, #0x7c
	cmp	r1, r2
	beq	.L0201C564
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	beq	.L0201C564
	ldrb	r0, [r3, #8]
	ldrb	r4, [r1, #8]
	cmp	r0, r4
	blo	.L0201C564
	adds	r4, r2, #0
	adds	r2, r0, #0
.L0201C552:
	ldr	r1, [r1, #0x6c]
	cmp	r1, r4
	beq	.L0201C564
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	beq	.L0201C564
	ldrb	r0, [r1, #8]
	cmp	r2, r0
	bhs	.L0201C552
.L0201C564:
	str	r1, [r3, #0x6c]
	ldr	r0, [r1, #0x68]
	str	r0, [r3, #0x68]
	ldr	r0, [r1, #0x68]
	str	r3, [r0, #0x6c]
	str	r3, [r1, #0x68]
.L0201C570:
	pop	{r4}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ keyToFreq   (0201C578)
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
	bge	.L0201C592
	movs	r2, #0
	b	.L0201C598
.L0201C592:
	cmp	r1, #0x77
	ble	.L0201C598
	movs	r2, #0x78
.L0201C598:
	ldrb	r0, [r0]
	cmp	r0, #0
	bne	.L0201C5B0
	ldr	r0, .P0201C5AC	@ =kDsPitch
	lsls	r1, r2, #0x10
	asrs	r1, r1, #0xe
	adds	r1, r1, r0
	ldr	r0, [r1]
	b	.L0201C5C8
	.hword 0x0000
.P0201C5AC:	.word kDsPitch
.L0201C5B0:
	cmp	r0, #4
	beq	.L0201C5C4
	ldr	r0, .P0201C5C0	@ =kPsgFreq
	lsls	r1, r2, #0x10
	asrs	r1, r1, #0xf
	adds	r1, r1, r0
	ldrh	r0, [r1]
	b	.L0201C5C8
.P0201C5C0:	.word kPsgFreq
.L0201C5C4:
	lsls	r0, r2, #0x10
	asrs	r0, r0, #0x10
.L0201C5C8:
	bx	lr
	movs	r0, r0

@ ======================================================================================
@ noiseDivider   (0201C5CC)
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
	bls	.L0201C5D6
	movs	r1, #0x77
.L0201C5D6:
	ldr	r0, .P0201C5E0	@ =kNoiseTable
	adds	r0, r1, r0
	ldrb	r0, [r0]
	bx	lr
	.hword 0x0000
.P0201C5E0:	.word kNoiseTable

@ ======================================================================================
@ envStep   (0201C5E4)
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
	bne	.L0201C63E
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
	bge	.L0201C610
	strb	r1, [r4, #0x10]
.L0201C610:
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
.L0201C63E:
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
@ echoSetFeedback   (0201C654)
@
@   void echoSetFeedback(u32 shift) { }  /* empty: this build has no echo */
@ ======================================================================================
	.global echoSetFeedback
	.thumb_func
echoSetFeedback:
	bx	lr
	movs	r0, r0

@ ======================================================================================
@ dsVolume   (0201C658)
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
	bne	.L0201C698
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
	b	.L0201C6AA
.L0201C698:
	adds	r0, r5, #0
	adds	r0, #0x58
	ldrb	r0, [r0]
	adds	r0, #0xe6
	ldr	r1, [r5, #0x14]
	muls	r0, r1, r0
	lsrs	r0, r0, #9
	str	r0, [r5, #0x14]
	adds	r4, r0, #0
.L0201C6AA:
	lsrs	r4, r4, #8
	adds	r0, r4, #0
	pop	{r4, r5}
	pop	{r1}
	bx	r1

@ ======================================================================================
@ psgEnvelope   (0201C6B4)
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
	bne	.L0201C6D2
	movs	r6, #1
.L0201C6D2:
	adds	r0, r5, #0
	bl	envStep
	cmp	r6, #0
	bne	.L0201C6E0
	movs	r0, #8
	b	.L0201C7A6
.L0201C6E0:
	cmp	r7, #0
	beq	.L0201C6E6
	lsls	r4, r4, #1
.L0201C6E6:
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
	bne	.L0201C72A
	lsrs	r4, r4, #0x16
	str	r4, [r5, #0x14]
	lsls	r0, r4, #2
	adds	r4, r0, r4
	lsrs	r4, r4, #7
	cmp	r4, #4
	bls	.L0201C724
	movs	r4, #4
.L0201C724:
	lsls	r0, r4, #0x18
	lsrs	r0, r0, #0x18
	b	.L0201C7A6
.L0201C72A:
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
	beq	.L0201C742
	movs	r4, #0xf
.L0201C742:
	ldr	r1, [r5, #0x14]
	ldr	r0, [r5, #0x44]
	muls	r0, r1, r0
	lsrs	r0, r0, #0x19
	str	r0, [r5, #0x14]
	ands	r0, r2
	cmp	r0, #0
	beq	.L0201C756
	movs	r0, #0xf
	str	r0, [r5, #0x14]
.L0201C756:
	ldr	r5, [r5, #0x14]
	cmp	r5, r4
	beq	.L0201C77E
	mov	r1, r8
	ldrh	r2, [r1]
	adds	r0, r2, #0
	adds	r0, #0xf
	lsls	r0, r0, #0x10
	lsrs	r2, r0, #0x10
	subs	r1, r5, r4
	cmp	r1, #0
	bge	.L0201C770
	rsbs	r1, r1, #0
.L0201C770:
	adds	r0, r2, #0
	bl	__divsi3
	lsls	r0, r0, #0x10
	lsrs	r2, r0, #0x10
	cmp	r2, #0
	bne	.L0201C78A
.L0201C77E:
	lsls	r0, r4, #4
	movs	r1, #8
	orrs	r0, r1
	lsls	r0, r0, #0x18
	lsrs	r6, r0, #0x18
	b	.L0201C7A4
.L0201C78A:
	ldr	r0, .P0201C7B0	@ =0x0000FFF8
	ands	r0, r2
	cmp	r0, #0
	beq	.L0201C794
	movs	r2, #7
.L0201C794:
	lsls	r0, r4, #4
	orrs	r0, r2
	lsls	r0, r0, #0x18
	lsrs	r6, r0, #0x18
	cmp	r4, r5
	bhs	.L0201C7A4
	movs	r0, #8
	orrs	r6, r0
.L0201C7A4:
	adds	r0, r6, #0
.L0201C7A6:
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1
.P0201C7B0:	.word 0x0000FFF8

@ ======================================================================================
@ voicePitch   (0201C7B4)
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
	beq	.L0201C7CC
	subs	r0, #1
	str	r0, [r5, #0x2c]
	b	.L0201C7E6
.L0201C7CC:
	ldr	r4, [r2, #4]
	cmp	r4, #0
	beq	.L0201C7E6
	ldr	r0, [r2, #8]
	ldr	r1, [r2, #0x10]
	adds	r0, r0, r1
	str	r0, [r2, #8]
	subs	r0, r4, #1
	str	r0, [r2, #4]
	cmp	r0, #0
	bne	.L0201C7E6
	ldr	r0, [r2, #0xc]
	str	r0, [r2, #8]
.L0201C7E6:
	ldr	r0, [r2, #8]
	adds	r3, r3, r0
	adds	r2, r6, #0
	adds	r2, #0x4f
	movs	r0, #0
	ldrsb	r0, [r2, r0]
	cmp	r0, #0
	beq	.L0201C83E
	ldr	r1, .P0201C824	@ =kDsPitch
	adds	r0, r6, #0
	adds	r0, #0x50
	ldrb	r0, [r0]
	adds	r0, #0x30
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r1, [r0]
	ldr	r0, .P0201C828	@ =0xFFFF8000
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
	bne	.L0201C82C
	muls	r3, r1, r3
	lsrs	r3, r3, #8
	b	.L0201C83E
.P0201C824:	.word kDsPitch
.P0201C828:	.word 0xFFFF8000
.L0201C82C:
	movs	r4, #0x80
	lsls	r4, r4, #4
	subs	r3, r4, r3
	lsls	r3, r3, #8
	adds	r0, r3, #0
	bl	__udivsi3
	adds	r3, r0, #0
	subs	r3, r4, r3
.L0201C83E:
	adds	r4, r5, #0
	adds	r4, #0x20
	ldr	r0, [r4, #8]
	ldr	r2, [r0, #8]
	cmp	r2, #0
	beq	.L0201C8EC
	ldr	r0, [r4, #4]
	cmp	r0, #0
	bne	.L0201C8E8
	ldr	r0, .P0201C874	@ =kLfoSine
	ldr	r1, [r5, #0x20]
	lsrs	r1, r1, #1
	adds	r1, r1, r0
	ldrb	r1, [r1]
	ldrb	r0, [r5]
	cmp	r0, #0
	bne	.L0201C894
	lsls	r0, r1, #0x18
	asrs	r0, r0, #0x18
	cmp	r0, #0
	blt	.L0201C878
	muls	r0, r3, r0
	muls	r0, r2, r0
	lsrs	r0, r0, #0x13
	adds	r3, r3, r0
	b	.L0201C8CC
	.hword 0x0000
.P0201C874:	.word kLfoSine
.L0201C878:
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
	b	.L0201C8CC
.L0201C894:
	lsls	r0, r1, #0x18
	asrs	r1, r0, #0x18
	cmp	r1, #0
	blt	.L0201C8B2
	movs	r0, #0x80
	lsls	r0, r0, #4
	subs	r0, r0, r3
	lsls	r0, r0, #0x13
	muls	r1, r2, r1
	movs	r2, #0x80
	lsls	r2, r2, #0xc
	adds	r1, r1, r2
	bl	__udivsi3
	b	.L0201C8C6
.L0201C8B2:
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
.L0201C8C6:
	movs	r3, #0x80
	lsls	r3, r3, #4
	subs	r3, r3, r0
.L0201C8CC:
	ldr	r0, [r4, #8]
	ldr	r1, [r4]
	ldr	r0, [r0, #4]
	adds	r1, r1, r0
	str	r1, [r4]
	lsrs	r0, r1, #1
	cmp	r0, #0xff
	bls	.L0201C8EC
	ldr	r2, .P0201C8E4	@ =0xFFFFFE00
	adds	r0, r1, r2
	str	r0, [r4]
	b	.L0201C8EC
.P0201C8E4:	.word 0xFFFFFE00
.L0201C8E8:
	subs	r0, #1
	str	r0, [r4, #4]
.L0201C8EC:
	adds	r0, r3, #0
	pop	{r4, r5, r6}
	pop	{r1}
	bx	r1

@ ======================================================================================
@ mixFrame   (0201C8F4)
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
@   In this build: As in the SMA2 build, but without any echo: only gMixDry is used.
@ ======================================================================================
	.global mixFrame
	.thumb_func
mixFrame:
	push	{r4, r5, r6, r7, lr}
	sub	sp, #4
	ldr	r4, .P0201C930	@ =gLastWave
	ldr	r5, [r4, #0x70]
	movs	r0, #0
	str	r0, [sp]
	ldr	r1, .P0201C934	@ =gMixDry
	ldr	r2, .P0201C938	@ =0x010000B0
	mov	r0, sp
	bl	CpuFastSet
	adds	r4, #0x7c
	cmp	r5, r4
	beq	.L0201C9AC
.L0201C910:
	adds	r0, r5, #0
	bl	dsVolume
	adds	r7, r0, #0
	ldrb	r0, [r5, #1]
	cmp	r0, #1
	bne	.L0201C958
	ldrh	r0, [r5, #0x18]
	subs	r0, #1
	strh	r0, [r5, #0x18]
	ldr	r4, [r5, #4]
	ldrb	r0, [r5, #0x1b]
	cmp	r0, #0
	beq	.L0201C93C
	ldrb	r3, [r5, #0x1c]
	b	.L0201C942
.P0201C930:	.word gLastWave
.P0201C934:	.word gMixDry
.P0201C938:	.word 0x010000B0
.L0201C93C:
	adds	r0, r4, #0
	adds	r0, #0x4b
	ldrb	r3, [r0]
.L0201C942:
	adds	r6, r3, #0
	adds	r0, r5, #0
	bl	voicePitch
	adds	r2, r0, #0
	str	r2, [r5, #0x10]
	adds	r0, r4, #0
	adds	r0, #0x4c
	ldrb	r0, [r0]
	strb	r0, [r5, #0x1a]
	b	.L0201C960
.L0201C958:
	cmp	r7, #0
	beq	.L0201C994
	ldrb	r6, [r5, #0x1c]
	ldr	r2, [r5, #0x10]
.L0201C960:
	lsrs	r2, r2, #2
	ldr	r0, [r5, #0x5c]
	ldr	r0, [r0, #4]
	muls	r2, r0, r2
	adds	r0, r2, #0
	ldr	r1, .P0201C9A0	@ =0x00002910
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
	bne	.L0201C9A4
.L0201C994:
	ldr	r5, [r5, #0x6c]
	ldr	r0, [r5, #0x68]
	bl	voiceStop
	b	.L0201C9A6
	.hword 0x0000
.P0201C9A0:	.word 0x00002910
.L0201C9A4:
	ldr	r5, [r5, #0x6c]
.L0201C9A6:
	ldr	r0, .P0201C9F4	@ =gActiveTail
	cmp	r5, r0
	bne	.L0201C910
.L0201C9AC:
	movs	r5, #0
	movs	r4, #6
.L0201C9B0:
	ldr	r0, .P0201C9F8	@ =gDsVoices
	adds	r1, r5, r0
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	bne	.L0201C9C6
	ldrh	r0, [r1, #0x18]
	cmp	r0, #0
	bne	.L0201C9C6
	adds	r0, r1, #0
	bl	noteOff
.L0201C9C6:
	adds	r5, #0x78
	subs	r4, #1
	cmp	r4, #0
	bge	.L0201C9B0
	ldr	r3, .P0201C9FC	@ =gFnDownmix
	ldr	r0, .P0201CA00	@ =gMixDry
	ldr	r2, .P0201CA04	@ =gDmaBufA
	ldr	r1, .P0201CA08	@ =gDmaBufIdx
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
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201C9F4:	.word gActiveTail
.P0201C9F8:	.word gDsVoices
.P0201C9FC:	.word gFnDownmix
.P0201CA00:	.word gMixDry
.P0201CA04:	.word gDmaBufA
.P0201CA08:	.word gDmaBufIdx

@ ======================================================================================
@ psgUpdate   (0201CA0C)
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
.L0201CA1A:
	mov	r1, sl
	lsls	r0, r1, #4
	subs	r0, r0, r1
	lsls	r0, r0, #3
	ldr	r1, .P0201CA58	@ =gPsgVoices
	adds	r4, r0, r1
	ldrb	r0, [r4, #1]
	cmp	r0, #1
	bne	.L0201CA38
	ldrh	r0, [r4, #0x18]
	cmp	r0, #0
	bne	.L0201CA38
	adds	r0, r4, #0
	bl	noteOff
.L0201CA38:
	ldrb	r0, [r4, #1]
	cmp	r0, #0
	bne	.L0201CA40
	b	.L0201CC80
.L0201CA40:
	cmp	r0, #1
	bne	.L0201CA66
	adds	r0, r4, #0
	bl	voicePitch
	adds	r6, r0, #0
	str	r6, [r4, #0x10]
	ldrb	r0, [r4, #0x1b]
	cmp	r0, #0
	beq	.L0201CA5C
	ldrb	r0, [r4, #0x1c]
	b	.L0201CA62
.P0201CA58:	.word gPsgVoices
.L0201CA5C:
	ldr	r0, [r4, #4]
	adds	r0, #0x4b
	ldrb	r0, [r0]
.L0201CA62:
	mov	r8, r0
	b	.L0201CA6C
.L0201CA66:
	ldr	r6, [r4, #0x10]
	ldrb	r2, [r4, #0x1c]
	mov	r8, r2
.L0201CA6C:
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
	ldr	r0, .P0201CAB0	@ =REG_NR51
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
	bne	.L0201CAB4
	mov	r3, ip
	ldrb	r1, [r3]
	adds	r0, r2, #0
	ands	r0, r1
	orrs	r0, r5
	strb	r0, [r3]
	b	.L0201CADE
.P0201CAB0:	.word REG_NR51
.L0201CAB4:
	mov	r0, r8
	cmp	r0, #0x3f
	bhi	.L0201CACE
	mov	r1, ip
	ldrb	r0, [r1]
	adds	r1, r2, #0
	ands	r1, r0
	movs	r0, #0x10
	lsls	r0, r3
	orrs	r1, r0
	mov	r2, ip
	strb	r1, [r2]
	b	.L0201CADE
.L0201CACE:
	mov	r3, ip
	ldrb	r0, [r3]
	ands	r1, r0
	movs	r0, #1
	mov	r2, sb
	lsls	r0, r2
	orrs	r1, r0
	strb	r1, [r3]
.L0201CADE:
	ldrb	r5, [r4, #1]
	cmp	r5, #1
	bne	.L0201CB08
	ldr	r0, [r4, #0x60]
	cmp	r0, #0
	bne	.L0201CAFC
	adds	r0, r4, #0
	adds	r1, r7, #0
	bl	psgKeyOn
	str	r5, [r4, #0x60]
	ldrh	r0, [r4, #0x18]
	subs	r0, #1
	strh	r0, [r4, #0x18]
	b	.L0201CC80
.L0201CAFC:
	adds	r0, #1
	str	r0, [r4, #0x60]
	ldrh	r0, [r4, #0x18]
	subs	r0, #1
	strh	r0, [r4, #0x18]
	b	.L0201CB58
.L0201CB08:
	ldrb	r0, [r4]
	cmp	r0, #3
	bne	.L0201CB58
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
	beq	.L0201CB28
	lsls	r1, r1, #1
.L0201CB28:
	lsls	r0, r1, #2
	adds	r1, r0, r1
	lsrs	r1, r1, #7
	cmp	r1, #0
	beq	.L0201CB50
	cmp	r1, #4
	bls	.L0201CB38
	movs	r1, #4
.L0201CB38:
	lsls	r1, r1, #0x18
	lsrs	r1, r1, #0x18
	ldr	r2, .P0201CB48	@ =REG_NR32
	ldr	r0, .P0201CB4C	@ =kWaveVolume
	adds	r1, r1, r0
	ldrb	r0, [r1]
	strb	r0, [r2]
	b	.L0201CC80
.P0201CB48:	.word REG_NR32
.P0201CB4C:	.word kWaveVolume
.L0201CB50:
	adds	r0, r4, #0
	bl	voiceStop
	b	.L0201CC80
.L0201CB58:
	ldr	r2, [r4, #0x54]
	ldrb	r1, [r2, #1]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0201CB7A
	ldr	r0, [r4, #0x64]
	ldrh	r3, [r0]
	ldr	r1, [r4, #0x60]
	cmp	r1, r3
	bhs	.L0201CB74
	adds	r0, r0, r1
	ldrb	r5, [r0, #2]
	b	.L0201CB7C
.L0201CB74:
	adds	r0, r3, r0
	ldrb	r5, [r0, #1]
	b	.L0201CB7C
.L0201CB7A:
	movs	r5, #0xff
.L0201CB7C:
	ldrb	r0, [r4]
	cmp	r0, #2
	beq	.L0201CBCC
	cmp	r0, #2
	bgt	.L0201CB8C
	cmp	r0, #1
	beq	.L0201CB96
	b	.L0201CC80
.L0201CB8C:
	cmp	r0, #3
	beq	.L0201CC0C
	cmp	r0, #4
	beq	.L0201CC34
	b	.L0201CC80
.L0201CB96:
	cmp	r7, #8
	beq	.L0201CBB4
	ldr	r0, .P0201CBAC	@ =REG_NR12
	strb	r7, [r0]
	ldr	r1, .P0201CBB0	@ =REG_SOUND1CNT_X
	movs	r2, #0x80
	lsls	r2, r2, #8
	adds	r0, r2, #0
	orrs	r6, r0
	strh	r6, [r1]
	b	.L0201CBBE
.P0201CBAC:	.word REG_NR12
.P0201CBB0:	.word REG_SOUND1CNT_X
.L0201CBB4:
	ldrb	r0, [r2, #8]
	cmp	r0, #8
	bne	.L0201CBBE
	ldr	r0, .P0201CBC4	@ =REG_SOUND1CNT_X
	strh	r6, [r0]
.L0201CBBE:
	ldr	r2, .P0201CBC8	@ =REG_NR11
	b	.L0201CBF2
	.hword 0x0000
.P0201CBC4:	.word REG_SOUND1CNT_X
.P0201CBC8:	.word REG_NR11
.L0201CBCC:
	cmp	r7, #8
	beq	.L0201CBEC
	ldr	r0, .P0201CBE4	@ =REG_NR22
	strb	r7, [r0]
	ldr	r1, .P0201CBE8	@ =REG_SOUND2CNT_H
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r0, r3, #0
	orrs	r6, r0
	strh	r6, [r1]
	b	.L0201CBF0
	.hword 0x0000
.P0201CBE4:	.word REG_NR22
.P0201CBE8:	.word REG_SOUND2CNT_H
.L0201CBEC:
	ldr	r0, .P0201CC04	@ =REG_SOUND2CNT_H
	strh	r6, [r0]
.L0201CBF0:
	ldr	r2, .P0201CC08	@ =REG_NR21
.L0201CBF2:
	ldrb	r1, [r2]
	movs	r0, #0xc0
	ands	r0, r1
	strb	r0, [r2]
	cmp	r5, #0xff
	beq	.L0201CC80
	lsls	r0, r5, #6
	strb	r0, [r2]
	b	.L0201CC80
.P0201CC04:	.word REG_SOUND2CNT_H
.P0201CC08:	.word REG_NR21
.L0201CC0C:
	ldr	r0, .P0201CC2C	@ =REG_SOUND3CNT_X
	ldrh	r1, [r0]
	movs	r3, #0x80
	lsls	r3, r3, #7
	adds	r2, r3, #0
	ands	r1, r2
	orrs	r1, r6
	strh	r1, [r0]
	cmp	r7, #8
	beq	.L0201CC80
	subs	r0, #1
	ldr	r1, .P0201CC30	@ =kWaveVolume
	adds	r1, r7, r1
	ldrb	r1, [r1]
	strb	r1, [r0]
	b	.L0201CC80
.P0201CC2C:	.word REG_SOUND3CNT_X
.P0201CC30:	.word kWaveVolume
.L0201CC34:
	cmp	r7, #8
	beq	.L0201CC42
	ldr	r0, .P0201CC60	@ =REG_NR42
	strb	r7, [r0]
	ldr	r1, .P0201CC64	@ =REG_NR44
	movs	r0, #0x80
	strb	r0, [r1]
.L0201CC42:
	cmp	r5, #0xff
	beq	.L0201CC6C
	ldr	r4, .P0201CC68	@ =REG_NR43
	lsls	r0, r6, #0x10
	lsrs	r0, r0, #0x10
	bl	noiseDivider
	lsls	r0, r0, #0x18
	lsrs	r1, r0, #0x18
	cmp	r5, #0
	beq	.L0201CC5C
	movs	r0, #8
	orrs	r1, r0
.L0201CC5C:
	strb	r1, [r4]
	b	.L0201CC80
.P0201CC60:	.word REG_NR42
.P0201CC64:	.word REG_NR44
.P0201CC68:	.word REG_NR43
.L0201CC6C:
	lsls	r0, r6, #0x10
	lsrs	r0, r0, #0x10
	bl	noiseDivider
	ldr	r3, .P0201CC9C	@ =REG_NR43
	ldrb	r2, [r3]
	movs	r1, #8
	ands	r1, r2
	orrs	r1, r0
	strb	r1, [r3]
.L0201CC80:
	movs	r0, #1
	add	sl, r0
	mov	r1, sl
	cmp	r1, #3
	bgt	.L0201CC8C
	b	.L0201CA1A
.L0201CC8C:
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	sb, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201CC9C:	.word REG_NR43

@ ======================================================================================
@ noteOn   (0201CCA0)
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
	beq	.L0201CCC8
	b	.L0201CE64
.L0201CCC8:
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
	beq	.L0201CCF4
	ldrh	r1, [r4, #0x30]
	mov	r0, r8
	bl	__udivsi3
	b	.L0201CD02
.L0201CCF4:
	movs	r0, #0x32
	ldrsh	r1, [r4, r0]
	ldrh	r4, [r4, #0x30]
	adds	r1, r1, r4
	mov	r0, r8
	bl	__divsi3
.L0201CD02:
	lsls	r0, r0, #0x10
	lsrs	r0, r0, #0x10
	mov	r8, r0
	adds	r0, r5, #0
	adds	r0, #0x49
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L0201CD1C
	ldr	r0, [r5, #0xc]
	cmp	r0, #0
	beq	.L0201CD1C
	adds	r4, r0, #0
	b	.L0201CD70
.L0201CD1C:
	ldr	r1, .P0201CD88	@ =kVoiceForType
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
	bne	.L0201CD38
	b	.L0201CE64
.L0201CD38:
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
.L0201CD70:
	mov	r0, sp
	ldrb	r0, [r0, #0x11]
	strb	r0, [r4, #0x1b]
	lsls	r0, r0, #0x18
	cmp	r0, #0
	beq	.L0201CD8C
	movs	r7, #0x30
	mov	r0, sp
	ldrb	r0, [r0, #0x10]
	strb	r0, [r4, #0x1c]
	b	.L0201CD96
	.hword 0x0000
.P0201CD88:	.word kVoiceForType
.L0201CD8C:
	mov	r0, sp
	ldrb	r0, [r0, #0x12]
	cmp	r0, #0
	beq	.L0201CD96
	movs	r7, #0x30
.L0201CD96:
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
	bne	.L0201CDC8
	adds	r0, r4, #0
	adds	r0, #0x2c
	movs	r1, #0x14
	bl	MemClear
	b	.L0201CE22
.L0201CDC8:
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
	beq	.L0201CDF6
	ldr	r0, [r4, #0xc]
	subs	r0, r2, r0
	str	r0, [r4, #0x38]
	b	.L0201CDFE
.L0201CDF6:
	ldr	r0, [r4, #0xc]
	subs	r0, r0, r2
	str	r0, [r4, #0x38]
	str	r2, [r4, #0xc]
.L0201CDFE:
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
	beq	.L0201CE1C
	strb	r7, [r5, #0x1e]
	b	.L0201CE1E
.L0201CE1C:
	strb	r0, [r5, #0x1c]
.L0201CE1E:
	movs	r0, #0
	str	r0, [r4, #0x34]
.L0201CE22:
	ldrb	r0, [r4]
	cmp	r0, #0
	bne	.L0201CE38
	ldrh	r0, [r6, #2]
	ldr	r1, [r5, #4]
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r0, [r0]
	adds	r1, r1, r0
	str	r1, [r4, #0x5c]
	b	.L0201CE58
.L0201CE38:
	cmp	r0, #3
	beq	.L0201CE54
	ldrb	r1, [r6, #1]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0201CE4A
	ldr	r0, [sp, #8]
	b	.L0201CE56
.L0201CE4A:
	ldrh	r1, [r6, #2]
	adds	r0, r4, #0
	adds	r0, #0x64
	strb	r1, [r0]
	b	.L0201CE58
.L0201CE54:
	ldr	r0, [sp, #0xc]
.L0201CE56:
	str	r0, [r4, #0x64]
.L0201CE58:
	mov	r0, r8
	cmp	r0, #0
	bne	.L0201CE64
	adds	r0, r4, #0
	bl	noteOff
.L0201CE64:
	add	sp, #0x14
	pop	{r3, r4}
	mov	r8, r3
	mov	sb, r4
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ noteOff   (0201CE74)
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
	bne	.L0201CF4A
	ldr	r0, [r4, #4]
	adds	r0, #0x49
	ldrb	r0, [r0]
	cmp	r0, #0
	bne	.L0201CF4A
	ldrb	r3, [r4]
	cmp	r3, #0
	bne	.L0201CEA0
	adds	r0, r4, #0
	bl	voiceUnlink
	movs	r0, #2
	strb	r0, [r4, #1]
	adds	r0, r4, #0
	bl	voiceListInsertActive
	b	.L0201CF32
.L0201CEA0:
	ldrh	r2, [r4, #0x10]
	adds	r0, r4, #0
	adds	r0, #0x58
	ldrb	r1, [r0]
	cmp	r3, #3
	bne	.L0201CEB0
	movs	r0, #2
	b	.L0201CF30
.L0201CEB0:
	lsrs	r1, r1, #5
	cmp	r1, #0
	bne	.L0201CEBA
	movs	r1, #0
	b	.L0201CEC4
.L0201CEBA:
	ldr	r0, [r4, #0x14]
	lsls	r0, r0, #4
	orrs	r1, r0
	lsls	r0, r1, #0x18
	lsrs	r1, r0, #0x18
.L0201CEC4:
	ldrb	r0, [r4]
	cmp	r0, #2
	beq	.L0201CEFC
	cmp	r0, #2
	bgt	.L0201CED4
	cmp	r0, #1
	beq	.L0201CEDA
	b	.L0201CF2E
.L0201CED4:
	cmp	r0, #4
	beq	.L0201CF24
	b	.L0201CF2E
.L0201CEDA:
	ldr	r0, .P0201CEF0	@ =REG_NR12
	strb	r1, [r0]
	ldr	r1, .P0201CEF4	@ =REG_SOUND1CNT_X
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r0, r3, #0
	orrs	r2, r0
	strh	r2, [r1]
	ldr	r2, .P0201CEF8	@ =REG_NR11
	b	.L0201CF0E
	.hword 0x0000
.P0201CEF0:	.word REG_NR12
.P0201CEF4:	.word REG_SOUND1CNT_X
.P0201CEF8:	.word REG_NR11
.L0201CEFC:
	ldr	r0, .P0201CF18	@ =REG_NR22
	strb	r1, [r0]
	ldr	r1, .P0201CF1C	@ =REG_SOUND2CNT_H
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r0, r3, #0
	orrs	r2, r0
	strh	r2, [r1]
	ldr	r2, .P0201CF20	@ =REG_NR21
.L0201CF0E:
	ldrb	r1, [r2]
	movs	r0, #0xc0
	ands	r0, r1
	strb	r0, [r2]
	b	.L0201CF2E
.P0201CF18:	.word REG_NR22
.P0201CF1C:	.word REG_SOUND2CNT_H
.P0201CF20:	.word REG_NR21
.L0201CF24:
	ldr	r0, .P0201CF50	@ =REG_NR42
	strb	r1, [r0]
	ldr	r1, .P0201CF54	@ =REG_NR44
	movs	r0, #0x80
	strb	r0, [r1]
.L0201CF2E:
	movs	r0, #0
.L0201CF30:
	strb	r0, [r4, #1]
.L0201CF32:
	ldrb	r0, [r4, #0x1b]
	ldr	r1, [r4, #4]
	cmp	r0, #0
	bne	.L0201CF42
	adds	r0, r1, #0
	adds	r0, #0x4b
	ldrb	r0, [r0]
	strb	r0, [r4, #0x1c]
.L0201CF42:
	adds	r0, r1, #0
	adds	r1, r4, #0
	bl	trackRemoveVoice
.L0201CF4A:
	pop	{r4}
	pop	{r0}
	bx	r0
.P0201CF50:	.word REG_NR42
.P0201CF54:	.word REG_NR44

@ ======================================================================================
@ voiceStop   (0201CF58)
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
	beq	.L0201CFE8
	ldrb	r0, [r4]
	cmp	r0, #4
	bhi	.L0201CFDC
	lsls	r0, r0, #2
	ldr	r1, .P0201CF74	@ =0x0201CF78
	adds	r0, r0, r1
	ldr	r0, [r0]
	mov	pc, r0
	.hword 0x0000
.P0201CF74:	.word 0x0201CF78
	.word .L0201CF8C
	.word .L0201CFAC
	.word .L0201CFBC
	.word .L0201CFC4
	.word .L0201CFD0
.L0201CF8C:
	adds	r0, r4, #0
	bl	voiceUnlink
	ldr	r0, .P0201CFA8	@ =gLastWave
	movs	r1, #0xb0
	lsls	r1, r1, #1
	adds	r2, r0, r1
	ldr	r1, [r2]
	str	r1, [r4, #0x6c]
	adds	r0, #0xf4
	str	r0, [r4, #0x68]
	str	r4, [r1, #0x68]
	str	r4, [r2]
	b	.L0201CFDC
.P0201CFA8:	.word gLastWave
.L0201CFAC:
	ldr	r1, .P0201CFB8	@ =REG_NR12
	movs	r0, #8
	strb	r0, [r1]
	adds	r1, #2
	b	.L0201CFD8
	.hword 0x0000
.P0201CFB8:	.word REG_NR12
.L0201CFBC:
	ldr	r1, .P0201CFC0	@ =REG_NR22
	b	.L0201CFD2
.P0201CFC0:	.word REG_NR22
.L0201CFC4:
	ldr	r1, .P0201CFCC	@ =REG_NR30
	movs	r0, #0
	b	.L0201CFDA
	.hword 0x0000
.P0201CFCC:	.word REG_NR30
.L0201CFD0:
	ldr	r1, .P0201CFF0	@ =REG_NR42
.L0201CFD2:
	movs	r0, #8
	strb	r0, [r1]
	adds	r1, #4
.L0201CFD8:
	movs	r0, #0xc0
.L0201CFDA:
	strb	r0, [r1]
.L0201CFDC:
	ldr	r0, [r4, #4]
	adds	r1, r4, #0
	bl	trackRemoveVoice
	movs	r0, #0
	strb	r0, [r4, #1]
.L0201CFE8:
	pop	{r4}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201CFF0:	.word REG_NR42

@ ======================================================================================
@ psgKeyOn   (0201CFF4)
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
	beq	.L0201D078
	cmp	r3, #2
	bgt	.L0201D00C
	cmp	r3, #1
	beq	.L0201D016
	b	.L0201D144
.L0201D00C:
	cmp	r3, #3
	beq	.L0201D0A4
	cmp	r3, #4
	beq	.L0201D0F8
	b	.L0201D144
.L0201D016:
	ldr	r1, .P0201D044	@ =REG_NR10
	ldr	r0, [r4, #0x54]
	ldrb	r0, [r0, #8]
	strb	r0, [r1]
	ldr	r2, .P0201D048	@ =REG_SOUND1CNT_X
	ldr	r0, [r4, #0xc]
	movs	r6, #0x80
	lsls	r6, r6, #8
	adds	r1, r6, #0
	orrs	r0, r1
	strh	r0, [r2]
	ldr	r0, .P0201D04C	@ =REG_NR12
	strb	r5, [r0]
	ldr	r0, [r4, #0x54]
	ldrb	r0, [r0, #1]
	ands	r3, r0
	cmp	r3, #0
	beq	.L0201D054
	ldr	r1, .P0201D050	@ =REG_NR11
	ldr	r0, [r4, #0x64]
	ldrb	r0, [r0, #2]
	b	.L0201D05C
	.hword 0x0000
.P0201D044:	.word REG_NR10
.P0201D048:	.word REG_SOUND1CNT_X
.P0201D04C:	.word REG_NR12
.P0201D050:	.word REG_NR11
.L0201D054:
	ldr	r1, .P0201D070	@ =REG_NR11
	adds	r0, r4, #0
	adds	r0, #0x64
	ldrb	r0, [r0]
.L0201D05C:
	lsls	r0, r0, #6
	strb	r0, [r1]
	ldr	r0, .P0201D074	@ =REG_SOUND1CNT_X
	ldr	r1, [r4, #0xc]
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r2, r3, #0
	orrs	r1, r2
	strh	r1, [r0]
	b	.L0201D144
.P0201D070:	.word REG_NR11
.P0201D074:	.word REG_SOUND1CNT_X
.L0201D078:
	ldr	r0, .P0201D098	@ =REG_NR22
	strb	r5, [r0]
	ldr	r2, .P0201D09C	@ =REG_SOUND2CNT_H
	ldr	r0, [r4, #0xc]
	movs	r6, #0x80
	lsls	r6, r6, #8
	adds	r1, r6, #0
	orrs	r0, r1
	strh	r0, [r2]
	ldr	r1, .P0201D0A0	@ =REG_NR21
	adds	r0, r4, #0
	adds	r0, #0x64
	ldrb	r0, [r0]
	lsls	r0, r0, #6
	b	.L0201D142
	.hword 0x0000
.P0201D098:	.word REG_NR22
.P0201D09C:	.word REG_SOUND2CNT_H
.P0201D0A0:	.word REG_NR21
.L0201D0A4:
	ldr	r6, .P0201D0E4	@ =gLastWave
	ldr	r1, [r4, #0x64]
	ldr	r0, [r6]
	cmp	r1, r0
	beq	.L0201D0C2
	ldr	r1, .P0201D0E8	@ =REG_NR30
	movs	r0, #0
	strb	r0, [r1]
	ldr	r0, [r4, #0x64]
	adds	r1, #0x20
	movs	r2, #8
	bl	CpuSet
	ldr	r0, [r4, #0x64]
	str	r0, [r6]
.L0201D0C2:
	ldr	r1, .P0201D0E8	@ =REG_NR30
	movs	r0, #0xc0
	strb	r0, [r1]
	ldr	r2, .P0201D0EC	@ =REG_SOUND3CNT_X
	ldr	r0, [r4, #0xc]
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r1, r3, #0
	orrs	r0, r1
	strh	r0, [r2]
	ldr	r1, .P0201D0F0	@ =REG_NR32
	ldr	r0, .P0201D0F4	@ =kWaveVolume
	adds	r0, r5, r0
	ldrb	r0, [r0]
	strb	r0, [r1]
	subs	r1, #1
	b	.L0201D140
.P0201D0E4:	.word gLastWave
.P0201D0E8:	.word REG_NR30
.P0201D0EC:	.word REG_SOUND3CNT_X
.P0201D0F0:	.word REG_NR32
.P0201D0F4:	.word kWaveVolume
.L0201D0F8:
	ldr	r0, .P0201D118	@ =REG_NR42
	strb	r5, [r0]
	ldr	r0, [r4, #0x54]
	ldrb	r1, [r0, #1]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0201D11C
	ldrh	r0, [r4, #0xc]
	bl	noiseDivider
	lsls	r0, r0, #0x18
	lsrs	r1, r0, #0x18
	ldr	r0, [r4, #0x64]
	ldrb	r0, [r0, #2]
	b	.L0201D12C
.P0201D118:	.word REG_NR42
.L0201D11C:
	ldrh	r0, [r4, #0xc]
	bl	noiseDivider
	lsls	r0, r0, #0x18
	lsrs	r1, r0, #0x18
	adds	r0, r4, #0
	adds	r0, #0x64
	ldrb	r0, [r0]
.L0201D12C:
	cmp	r0, #0
	beq	.L0201D134
	movs	r0, #8
	orrs	r1, r0
.L0201D134:
	ldr	r0, .P0201D14C	@ =REG_NR43
	strb	r1, [r0]
	ldr	r1, .P0201D150	@ =REG_NR44
	movs	r0, #0x80
	strb	r0, [r1]
	subs	r1, #5
.L0201D140:
	movs	r0, #0
.L0201D142:
	strb	r0, [r1]
.L0201D144:
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201D14C:	.word REG_NR43
.P0201D150:	.word REG_NR44

@ ======================================================================================
@ voiceAlloc   (0201D154)
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
	bne	.L0201D1B2
	ldr	r1, .P0201D17C	@ =gLastWave
	movs	r2, #0xb0
	lsls	r2, r2, #1
	adds	r0, r1, r2
	ldr	r2, [r0]
	movs	r3, #0xb6
	lsls	r3, r3, #1
	adds	r0, r1, r3
	cmp	r2, r0
	beq	.L0201D180
	adds	r4, r2, #0
	b	.L0201D19E
	.hword 0x0000
.P0201D17C:	.word gLastWave
.L0201D180:
	ldr	r2, [r1, #0x70]
	adds	r0, r1, #0
	adds	r0, #0x7c
	cmp	r2, r0
	beq	.L0201D1C8
	ldrb	r0, [r2, #1]
	cmp	r0, #1
	bne	.L0201D196
	ldrb	r0, [r2, #8]
	cmp	r5, r0
	blo	.L0201D1C8
.L0201D196:
	adds	r4, r2, #0
	adds	r0, r4, #0
	bl	voiceStop
.L0201D19E:
	adds	r0, r4, #0
	bl	voiceUnlink
	movs	r0, #1
	strb	r0, [r4, #1]
	strb	r5, [r4, #8]
	adds	r0, r4, #0
	bl	voiceListInsertActive
	b	.L0201D1E2
.L0201D1B2:
	lsls	r0, r1, #4
	subs	r0, r0, r1
	lsls	r0, r0, #3
	ldr	r1, .P0201D1CC	@ =gDsVoices+0x2D0
	adds	r4, r0, r1
	ldrb	r0, [r4, #1]
	cmp	r0, #1
	bne	.L0201D1D0
	ldrb	r2, [r4, #8]
	cmp	r5, r2
	bhs	.L0201D1D0
.L0201D1C8:
	movs	r0, #0
	b	.L0201D1E4
.P0201D1CC:	.word gDsVoices+0x2D0
.L0201D1D0:
	ldrb	r0, [r4, #1]
	cmp	r0, #0
	beq	.L0201D1DC
	adds	r0, r4, #0
	bl	voiceStop
.L0201D1DC:
	movs	r0, #1
	strb	r0, [r4, #1]
	strb	r5, [r4, #8]
.L0201D1E2:
	adds	r0, r4, #0
.L0201D1E4:
	pop	{r4, r5}
	pop	{r1}
	bx	r1
	movs	r0, r0

@ ======================================================================================
@ mixVoice   (0201D1EC)
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
@   In this build: As in the SMA2 build, but there is no wet bus: every voice goes to gMixDry.
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
	ldr	r2, .P0201D258	@ =gMixDry
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
	lsrs	r0, r0, #0x17
	str	r0, [sp, #0x1c]
	mov	r0, sb
	muls	r0, r3, r0
	lsls	r0, r0, #0x10
	lsrs	r0, r0, #0x17
	mov	sb, r0
	ldr	r7, [r1, #0xc]
	cmp	r7, #0
	bne	.L0201D248
	ldr	r7, [r1]
.L0201D248:
	mov	r0, sl
	muls	r0, r6, r0
	adds	r0, r4, r0
	lsrs	r0, r0, #8
	cmp	r0, r7
	bhs	.L0201D25C
	ldr	r5, [sp, #0x18]
	b	.L0201D274
.P0201D258:	.word gMixDry
.L0201D25C:
	lsls	r0, r7, #8
	subs	r0, r0, r4
	subs	r0, #1
	adds	r0, r0, r6
	adds	r1, r6, #0
	bl	__udivsi3
	lsls	r0, r0, #1
	ldr	r1, [sp, #0x14]
	adds	r5, r0, r1
	movs	r2, #1
	mov	r8, r2
.L0201D274:
	ldr	r1, [sp, #0x10]
	ldr	r0, [r1, #0x5c]
	ldr	r1, [r0, #0xc]
	cmp	r1, #0
	beq	.L0201D284
	mov	r2, r8
	cmp	r2, #0
	bne	.L0201D2B0
.L0201D284:
	ldr	r0, .P0201D2AC	@ =gFnMixVoice
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
	beq	.L0201D35E
	movs	r0, #1
	b	.L0201D364
.P0201D2AC:	.word gFnMixVoice
.L0201D2B0:
	ldr	r0, [r0, #8]
	subs	r1, r1, r0
	lsls	r1, r1, #8
	str	r1, [sp, #0x24]
	ldr	r1, .P0201D30C	@ =gFnMixVoice
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
	beq	.L0201D35E
.L0201D2EA:
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
	bhs	.L0201D310
	mov	r1, sl
	lsls	r0, r1, #1
	adds	r5, r5, r0
	movs	r2, #0
	mov	r8, r2
	b	.L0201D326
.P0201D30C:	.word gFnMixVoice
.L0201D310:
	lsls	r0, r7, #8
	subs	r0, r0, r4
	subs	r0, #1
	adds	r0, r0, r6
	adds	r1, r6, #0
	bl	__udivsi3
	lsls	r0, r0, #1
	adds	r5, r5, r0
	movs	r0, #1
	mov	r8, r0
.L0201D326:
	str	r4, [sp]
	str	r6, [sp, #4]
	ldr	r1, [sp, #0x1c]
	str	r1, [sp, #8]
	mov	r2, sb
	str	r2, [sp, #0xc]
	ldr	r0, .P0201D374	@ =gFnMixVoice
	ldr	r4, [r0]
	ldr	r0, [sp, #0x20]
	ldr	r1, [sp, #0x14]
	ldr	r2, [sp, #0x18]
	adds	r3, r5, #0
	bl	_call_via_r4
	adds	r4, r0, #0
	mov	r1, r8
	cmp	r1, #0
	beq	.L0201D34E
	ldr	r2, [sp, #0x24]
	subs	r4, r4, r2
.L0201D34E:
	ldr	r1, [sp, #0x14]
	subs	r0, r5, r1
	asrs	r0, r0, #1
	mov	r2, sl
	subs	r2, r2, r0
	mov	sl, r2
	cmp	r2, #0
	bne	.L0201D2EA
.L0201D35E:
	ldr	r0, [sp, #0x10]
	str	r4, [r0, #0x60]
	movs	r0, #0
.L0201D364:
	add	sp, #0x28
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	sb, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1
.P0201D374:	.word gFnMixVoice

@ ======================================================================================
@ kitInstInit   (0201D378)
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
	ldr	r1, .P0201D390	@ =gKitInst
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
.P0201D390:	.word gKitInst

@ ======================================================================================
@ instLookup   (0201D394)
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
	ldr	r1, .P0201D3FC	@ =gCfg
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
	beq	.L0201D444
	adds	r0, r1, #0
	cmp	r0, #0x10
	bne	.L0201D400
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
	b	.L0201D448
.P0201D3FC:	.word gCfg
.L0201D400:
	cmp	r0, #0x11
	bne	.L0201D428
	ldrh	r1, [r5, #2]
	adds	r1, r3, r1
	ldr	r2, .P0201D420	@ =gKitInst
	lsls	r0, r6, #1
	adds	r0, r0, r1
	ldrh	r0, [r0]
	strh	r0, [r2, #2]
	str	r2, [r4]
	ldr	r0, .P0201D424	@ =kFlatEnvelope
	str	r0, [r4, #4]
	movs	r0, #1
	strb	r0, [r4, #0x12]
	b	.L0201D44C
	.hword 0x0000
.P0201D420:	.word gKitInst
.P0201D424:	.word kFlatEnvelope
.L0201D428:
	cmp	r0, #0x12
	bne	.L0201D44C
	ldrh	r0, [r5, #2]
	adds	r0, r3, r0
	b	.L0201D434
.L0201D432:
	adds	r0, #4
.L0201D434:
	ldrb	r1, [r0]
	cmp	r6, r1
	bhi	.L0201D432
	ldrh	r0, [r0, #2]
	adds	r0, r3, r0
	str	r0, [r4]
	ldrh	r0, [r0, #4]
	b	.L0201D448
.L0201D444:
	str	r5, [r4]
	ldrh	r0, [r5, #4]
.L0201D448:
	adds	r0, r3, r0
	str	r0, [r4, #4]
.L0201D44C:
	ldr	r2, [r4]
	ldrb	r0, [r2]
	cmp	r0, #3
	bne	.L0201D45A
	ldrh	r0, [r5, #2]
	adds	r0, r3, r0
	str	r0, [r4, #0xc]
.L0201D45A:
	ldrb	r1, [r2, #1]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0201D46A
	ldrh	r0, [r2, #2]
	adds	r0, r3, r0
	str	r0, [r4, #8]
.L0201D46A:
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ playerInitAll   (0201D470)
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
	ldr	r4, .P0201D4A0	@ =gPlayers
	movs	r3, #0
.L0201D478:
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
.L0201D48C:
	str	r3, [r0]
	subs	r0, #4
	subs	r1, #1
	cmp	r1, #0
	bge	.L0201D48C
	cmp	r2, #0x13
	ble	.L0201D478
	pop	{r4}
	pop	{r0}
	bx	r0
.P0201D4A0:	.word gPlayers

@ ======================================================================================
@ playerReset   (0201D4A4)
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
@ playerTickAll   (0201D4DC)
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
.L0201D4E2:
	lsls	r0, r6, #4
	adds	r0, r0, r6
	lsls	r0, r0, #2
	ldr	r1, .P0201D50C	@ =gPlayers
	adds	r1, r0, r1
	adds	r0, r1, #0
	adds	r0, #0x41
	ldrb	r0, [r0]
	adds	r7, r6, #1
	cmp	r0, #0
	beq	.L0201D55E
	ldrh	r2, [r1, #0x3a]
	cmp	r2, #0
	bne	.L0201D510
	cmp	r0, #2
	bne	.L0201D526
	adds	r0, r6, #0
	bl	playerStop
	b	.L0201D55E
	.hword 0x0000
.P0201D50C:	.word gPlayers
.L0201D510:
	ldrh	r0, [r1, #0x36]
	ldrh	r3, [r1, #0x34]
	adds	r0, r0, r3
	strh	r0, [r1, #0x34]
	subs	r0, r2, #1
	strh	r0, [r1, #0x3a]
	lsls	r0, r0, #0x10
	cmp	r0, #0
	bne	.L0201D526
	ldrh	r0, [r1, #0x38]
	strh	r0, [r1, #0x34]
.L0201D526:
	movs	r2, #0
	adds	r7, r6, #1
	adds	r4, r1, #0
	adds	r4, #8
	movs	r5, #9
.L0201D530:
	ldr	r0, [r4]
	cmp	r0, #0
	beq	.L0201D54C
	str	r2, [sp]
	bl	trackTick
	lsls	r0, r0, #0x18
	ldr	r2, [sp]
	cmp	r0, #0
	bne	.L0201D548
	movs	r2, #1
	b	.L0201D54C
.L0201D548:
	movs	r0, #0
	str	r0, [r4]
.L0201D54C:
	adds	r4, #4
	subs	r5, #1
	cmp	r5, #0
	bge	.L0201D530
	cmp	r2, #0
	bne	.L0201D55E
	adds	r0, r6, #0
	bl	playerStop
.L0201D55E:
	adds	r6, r7, #0
	cmp	r6, #0x13
	ble	.L0201D4E2
	add	sp, #4
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ doPlaySong   (0201D56C)
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
	ldr	r2, .P0201D590	@ =gCfg
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
.P0201D590:	.word gCfg

@ ======================================================================================
@ doPlaySfx   (0201D594)
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
	ldr	r2, .P0201D5BC	@ =gCfg
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
.P0201D5BC:	.word gCfg

@ ======================================================================================
@ playerStartSong   (0201D5C0)
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
	ldr	r1, .P0201D644	@ =gPlayers
	adds	r5, r0, r1
	adds	r4, r5, #0
	adds	r4, #0x41
	ldrb	r0, [r4]
	cmp	r0, #0
	beq	.L0201D5E6
	adds	r0, r3, #0
	bl	playerStop
.L0201D5E6:
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
	bge	.L0201D632
	adds	r4, r0, #0
.L0201D60A:
	ldrh	r0, [r4]
	cmp	r0, #0
	beq	.L0201D62A
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
.L0201D62A:
	adds	r4, #2
	adds	r6, #1
	cmp	r6, r7
	blt	.L0201D60A
.L0201D632:
	movs	r0, #1
	mov	r1, r8
	strb	r0, [r1]
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201D644:	.word gPlayers

@ ======================================================================================
@ playerStartSfx   (0201D648)
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
	ldr	r1, .P0201D6B0	@ =gPlayers
	adds	r5, r0, r1
	movs	r0, #0x41
	adds	r0, r0, r5
	mov	r8, r0
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L0201D674
	adds	r0, r4, #0
	bl	playerStop
.L0201D674:
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
.P0201D6B0:	.word gPlayers

@ ======================================================================================
@ playerStop   (0201D6B4)
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
	ldr	r0, .P0201D6EC	@ =gPlayers
	adds	r1, r1, r0
	adds	r2, r1, #0
	adds	r2, #0x41
	ldrb	r0, [r2]
	cmp	r0, #0
	beq	.L0201D6E6
	adds	r7, r2, #0
	movs	r6, #0
	adds	r4, r1, #0
	adds	r4, #8
	movs	r5, #9
.L0201D6D4:
	ldr	r0, [r4]
	bl	trackStop
	stm	r4!, {r6}
	subs	r5, #1
	cmp	r5, #0
	bge	.L0201D6D4
	movs	r0, #0
	strb	r0, [r7]
.L0201D6E6:
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
.P0201D6EC:	.word gPlayers

@ ======================================================================================
@ playerFadeOut   (0201D6F0)
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
	ldr	r0, .P0201D724	@ =gPlayers
	adds	r4, r1, r0
	adds	r2, r4, #0
	adds	r2, #0x41
	ldrb	r0, [r2]
	cmp	r0, #0
	beq	.L0201D71E
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
.L0201D71E:
	pop	{r4}
	pop	{r0}
	bx	r0
.P0201D724:	.word gPlayers

@ ======================================================================================
@ playerSetPause   (0201D728)
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
	ldr	r3, .P0201D748	@ =gPlayers
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
.P0201D748:	.word gPlayers

@ ======================================================================================
@ sndGetPlayerState   (0201D74C)
@
@   u32 sndGetPlayerState(u32 pl)       /* 0 idle, 1 playing, 2 fading out (read directly) */
@   {
@       return gPlayers[pl].state;
@   }
@ ======================================================================================
	.global sndGetPlayerState
	.thumb_func
sndGetPlayerState:
	ldr	r2, .P0201D75C	@ =gPlayers
	lsls	r1, r0, #4
	adds	r1, r1, r0
	lsls	r1, r1, #2
	adds	r2, #0x41
	adds	r1, r1, r2
	ldrb	r0, [r1]
	bx	lr
.P0201D75C:	.word gPlayers

@ ======================================================================================
@ trackInitAll   (0201D760)
@
@   void trackInitAll(void)
@   {
@       for (i = 0; i < 24; i++) gTracks[i].player = NULL, gTracks[i].voices = NULL;
@   }
@
@   In this build: Same, but only 'player' is cleared.
@ ======================================================================================
	.global trackInitAll
	.thumb_func
trackInitAll:
	ldr	r0, .P0201D77C	@ =gTracks
	movs	r1, #0
	adds	r0, #8
	movs	r2, #0x17
.L0201D768:
	strb	r1, [r0]
	strb	r1, [r0, #1]
	strb	r1, [r0, #2]
	strb	r1, [r0, #3]
	adds	r0, #0x54
	subs	r2, #1
	cmp	r2, #0
	bge	.L0201D768
	bx	lr
	.hword 0x0000
.P0201D77C:	.word gTracks

@ ======================================================================================
@ trackAlloc   (0201D780)
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
	ldr	r1, .P0201D790	@ =gTracks
	ldr	r0, .P0201D794	@ =0x0000078C
	adds	r2, r1, r0
.L0201D786:
	ldr	r0, [r1, #8]
	cmp	r0, #0
	bne	.L0201D798
	adds	r0, r1, #0
	b	.L0201D7A0
.P0201D790:	.word gTracks
.P0201D794:	.word 0x0000078C
.L0201D798:
	adds	r1, #0x54
	cmp	r1, r2
	ble	.L0201D786
	movs	r0, #0
.L0201D7A0:
	bx	lr
	movs	r0, r0

@ ======================================================================================
@ trackStart   (0201D7A4)
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
	beq	.L0201D85A
	ldr	r0, [r5, #8]
	cmp	r0, #0
	beq	.L0201D7BC
	adds	r0, r5, #0
	bl	trackStop
.L0201D7BC:
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
	bne	.L0201D82E
	adds	r1, #2
	movs	r0, #0xc
	strb	r0, [r1]
	subs	r1, #6
	movs	r0, #0x7f
	strb	r0, [r1]
	adds	r0, r5, #0
	adds	r0, #0x53
	strb	r3, [r0]
	b	.L0201D840
.L0201D82E:
	adds	r1, r5, #0
	adds	r1, #0x52
	movs	r0, #3
	strb	r0, [r1]
	adds	r0, r5, #0
	adds	r0, #0x4c
	strb	r2, [r0]
	adds	r0, #7
	strb	r2, [r0]
.L0201D840:
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
.L0201D85A:
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ trackReleaseAll   (0201D860)
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
	beq	.L0201D888
	adds	r1, r4, #0
	adds	r1, #0x49
	ldrb	r6, [r1]
	movs	r0, #0
	strb	r0, [r1]
	ldr	r0, [r4, #0xc]
	adds	r5, r1, #0
	cmp	r0, #0
	beq	.L0201D886
.L0201D87A:
	ldr	r4, [r0, #0x74]
	bl	noteOff
	adds	r0, r4, #0
	cmp	r0, #0
	bne	.L0201D87A
.L0201D886:
	strb	r6, [r5]
.L0201D888:
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ trackStop   (0201D890)
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
	beq	.L0201D8A0
	bl	trackReleaseAll
	movs	r0, #0
	str	r0, [r4, #8]
.L0201D8A0:
	pop	{r4}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ trackTick   (0201D8A8)
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
	beq	.L0201D8BC
	ldr	r1, [r5, #8]
	cmp	r1, #0
	bne	.L0201D8C0
.L0201D8BC:
	movs	r0, #1
	b	.L0201DD06
.L0201D8C0:
	mov	r8, r1
	mov	r0, r8
	adds	r0, #0x3c
	ldrb	r1, [r0]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	bne	.L0201D8D2
	b	.L0201DCEC
.L0201D8D2:
	adds	r0, r5, #0
	bl	trackReleaseAll
	b	.L0201DD04
.L0201D8DA:
	adds	r0, r5, #0
	bl	trackStop
	movs	r0, #2
	b	.L0201DD06
.L0201D8E4:
	ldr	r2, [r5]
	ldrb	r6, [r2]
	adds	r2, #1
	str	r2, [r5]
	cmp	r6, #0xbf
	bhi	.L0201D96E
	cmp	r6, #0x5f
	bhi	.L0201D900
	adds	r0, r5, #0
	adds	r0, #0x44
	ldrh	r4, [r0]
	adds	r0, #4
	ldrb	r2, [r0]
	b	.L0201D926
.L0201D900:
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
.L0201D926:
	movs	r0, #0x96
	muls	r4, r0, r4
	ldr	r0, .P0201D950	@ =gHookNote
	ldr	r7, [r0]
	cmp	r7, #0
	beq	.L0201D954
	mov	r0, r8
	adds	r0, #0x43
	ldrb	r1, [r0]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0201D954
	lsls	r3, r4, #0x10
	lsrs	r3, r3, #0x10
	adds	r0, r5, #0
	adds	r1, r6, #0
	bl	_call_via_r7
	b	.L0201D960
	.hword 0x0000
.P0201D950:	.word gHookNote
.L0201D954:
	lsls	r3, r4, #0x10
	lsrs	r3, r3, #0x10
	adds	r0, r5, #0
	adds	r1, r6, #0
	bl	noteOn
.L0201D960:
	adds	r0, r5, #0
	adds	r0, #0x53
	ldrb	r0, [r0]
	cmp	r0, #1
	beq	.L0201D96C
	b	.L0201DCEC
.L0201D96C:
	b	.L0201D992
.L0201D96E:
	cmp	r6, #0xc0
	bne	.L0201D97A
	adds	r0, r5, #0
	adds	r0, #0x46
	ldrh	r4, [r0]
	b	.L0201D98E
.L0201D97A:
	cmp	r6, #0xc1
	bne	.L0201D99A
	adds	r0, r5, #0
	bl	readVarLen
	lsls	r0, r0, #0x10
	lsrs	r4, r0, #0x10
	adds	r0, r5, #0
	adds	r0, #0x46
	strh	r4, [r0]
.L0201D98E:
	movs	r0, #0x96
	muls	r4, r0, r4
.L0201D992:
	ldr	r0, [r5, #0x34]
	adds	r0, r0, r4
	str	r0, [r5, #0x34]
	b	.L0201DCEC
.L0201D99A:
	movs	r0, #0xf0
	ands	r0, r6
	cmp	r0, #0xd0
	bne	.L0201D9DA
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
	beq	.L0201D9D2
	ldrb	r0, [r3, #1]
	strh	r0, [r5, #0x20]
	adds	r0, r2, #1
	str	r0, [r5]
	b	.L0201D9D4
.L0201D9D2:
	strh	r1, [r5, #0x20]
.L0201D9D4:
	movs	r0, #1
	strb	r0, [r5, #0x1c]
	b	.L0201DCEC
.L0201D9DA:
	adds	r0, r6, #0
	subs	r0, #0xc2
	cmp	r0, #0x3d
	bls	.L0201D9E4
	b	.L0201DCEC
.L0201D9E4:
	lsls	r0, r0, #2
	ldr	r1, .P0201D9F0	@ =0x0201D9F4
	adds	r0, r0, r1
	ldr	r0, [r0]
	mov	pc, r0
	.hword 0x0000
.P0201D9F0:	.word 0x0201D9F4
	.word .L0201DB4A
	.word .L0201DB66
	.word .L0201DB72
	.word .L0201DBBA
	.word .L0201DBBA
	.word .L0201DB56
	.word .L0201DBCE
	.word .L0201DBD8
	.word .L0201DBE2
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DB7E
	.word .L0201DB8A
	.word .L0201DB96
	.word .L0201DBAE
	.word .L0201DC08
	.word .L0201DC12
	.word .L0201DC22
	.word .L0201DC1A
	.word .L0201DB02
	.word .L0201DBA2
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DB08
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DB22
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DC2E
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DCEC
	.word .L0201DAEC
.L0201DAEC:
	adds	r0, r5, #0
	adds	r0, #0x24
	ldr	r1, [r5, #0x30]
	cmp	r1, r0
	bne	.L0201DAF8
	b	.L0201D8DA
.L0201DAF8:
	subs	r0, r1, #4
	str	r0, [r5, #0x30]
	ldr	r0, [r0]
	str	r0, [r5]
	b	.L0201DCEC
.L0201DB02:
	movs	r0, #0
	strb	r0, [r5, #0x1c]
	b	.L0201DCEC
.L0201DB08:
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
	b	.L0201DB40
.L0201DB22:
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
.L0201DB40:
	mov	r0, sp
	ldrh	r0, [r0]
	adds	r1, r1, r0
	str	r1, [r5]
	b	.L0201DCEC
.L0201DB4A:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x42
	strh	r1, [r2]
	b	.L0201DC02
.L0201DB56:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r0, #1
	str	r0, [r5]
	adds	r0, r5, #0
	bl	trackSetBank
	b	.L0201DCEC
.L0201DB66:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x4b
	strb	r1, [r2]
	b	.L0201DC02
.L0201DB72:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x52
	strb	r1, [r2]
	b	.L0201DC02
.L0201DB7E:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x4d
	strb	r1, [r2]
	b	.L0201DC02
.L0201DB8A:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x4f
	strb	r1, [r2]
	b	.L0201DC02
.L0201DB96:
	ldr	r0, [r5]
	ldrb	r2, [r0]
	adds	r1, r5, #0
	adds	r1, #0x50
	strb	r2, [r1]
	b	.L0201DC02
.L0201DBA2:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x51
	strb	r1, [r2]
	b	.L0201DC02
.L0201DBAE:
	ldr	r0, [r5]
	ldrb	r2, [r0]
	adds	r1, r5, #0
	adds	r1, #0x4c
	strb	r2, [r1]
	b	.L0201DC02
.L0201DBBA:
	adds	r0, r5, #0
	bl	trackReleaseAll
	movs	r1, #0
	cmp	r6, #0xc5
	bne	.L0201DBC8
	movs	r1, #1
.L0201DBC8:
	adds	r0, r5, #0
	adds	r0, #0x49
	b	.L0201DCEA
.L0201DBCE:
	adds	r1, r5, #0
	adds	r1, #0x53
	movs	r0, #1
	strb	r0, [r1]
	b	.L0201DCEC
.L0201DBD8:
	adds	r1, r5, #0
	adds	r1, #0x53
	movs	r0, #0
	strb	r0, [r1]
	b	.L0201DCEC
.L0201DBE2:
	ldr	r0, .P0201DBFC	@ =gHookCA
	ldr	r2, [r0]
	cmp	r2, #0
	beq	.L0201DC00
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r0, #1
	str	r0, [r5]
	adds	r0, r5, #0
	bl	_call_via_r2
	b	.L0201DCEC
	.hword 0x0000
.P0201DBFC:	.word gHookCA
.L0201DC00:
	ldr	r0, [r5]
.L0201DC02:
	adds	r0, #1
	str	r0, [r5]
	b	.L0201DCEC
.L0201DC08:
	ldr	r1, [r5]
	ldrb	r0, [r1]
	mov	r3, r8
	strh	r0, [r3, #0x30]
	b	.L0201DC28
.L0201DC12:
	ldr	r1, [r5]
	ldrb	r0, [r1]
	strh	r0, [r5, #0x10]
	b	.L0201DC28
.L0201DC1A:
	ldr	r1, [r5]
	ldrb	r0, [r1]
	str	r0, [r5, #0x18]
	b	.L0201DC28
.L0201DC22:
	ldr	r1, [r5]
	ldrb	r0, [r1]
	str	r0, [r5, #0x14]
.L0201DC28:
	adds	r1, #1
	str	r1, [r5]
	b	.L0201DCEC
.L0201DC2E:
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
	bne	.L0201DC62
	bl	trackAlloc
	adds	r4, r0, #0
	str	r4, [r6]
	b	.L0201DC68
.L0201DC62:
	adds	r4, r0, #0
	bl	trackStop
.L0201DC68:
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
.L0201DCEA:
	strb	r1, [r0]
.L0201DCEC:
	ldr	r1, [r5, #0x34]
	cmp	r1, #0
	bgt	.L0201DCF4
	b	.L0201D8E4
.L0201DCF4:
	mov	r2, r8
	ldrh	r0, [r2, #0x30]
	subs	r0, r1, r0
	str	r0, [r5, #0x34]
	movs	r3, #0x32
	ldrsh	r1, [r2, r3]
	subs	r0, r0, r1
	str	r0, [r5, #0x34]
.L0201DD04:
	movs	r0, #0
.L0201DD06:
	add	sp, #4
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1
	movs	r0, r0

@ ======================================================================================
@ trackAddVoice   (0201DD14)
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
	bne	.L0201DD2A
	str	r0, [r1, #4]
	str	r2, [r1, #0x70]
	ldr	r2, [r0, #0xc]
	str	r2, [r1, #0x74]
	str	r1, [r0, #0xc]
	cmp	r2, #0
	beq	.L0201DD2A
	str	r1, [r2, #0x70]
.L0201DD2A:
	bx	lr

@ ======================================================================================
@ trackRemoveVoice   (0201DD2C)
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
	beq	.L0201DD52
	movs	r0, #0
	str	r0, [r1, #4]
	ldr	r2, [r1, #0x74]
	cmp	r2, #0
	beq	.L0201DD42
	ldr	r0, [r1, #0x70]
	str	r0, [r2, #0x70]
.L0201DD42:
	ldr	r2, [r1, #0x70]
	cmp	r2, #0
	beq	.L0201DD4E
	ldr	r0, [r1, #0x74]
	str	r0, [r2, #0x74]
	b	.L0201DD52
.L0201DD4E:
	ldr	r0, [r1, #0x74]
	str	r0, [r3, #0xc]
.L0201DD52:
	bx	lr

@ ======================================================================================
@ readVarLen   (0201DD54)
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
	beq	.L0201DD74
	movs	r0, #0x7f
	ands	r1, r0
	lsls	r1, r1, #8
	ldrb	r0, [r2]
	orrs	r1, r0
	adds	r0, r2, #1
	str	r0, [r3]
.L0201DD74:
	adds	r0, r1, #0
	bx	lr

@ ======================================================================================
@ trackSetBank   (0201DD78)
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
	ldr	r0, .P0201DDA8	@ =gCfg
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
.P0201DDA8:	.word gCfg

@ ======================================================================================
@ cmdNext   (0201DDAC)
@
@   void cmdNext(void)                  /* advance the write pointer (wraps at 46 entries) */
@   {
@       if (++gCmdWrite == gCmdEnd) gCmdWrite = gCmdQueue;
@   }
@ ======================================================================================
	.global cmdNext
	.thumb_func
cmdNext:
	ldr	r2, .P0201DDC4	@ =gCmdWrite
	ldr	r0, [r2]
	adds	r0, #0xc
	str	r0, [r2]
	ldr	r1, .P0201DDC8	@ =gCmdEnd
	ldr	r1, [r1]
	cmp	r0, r1
	bne	.L0201DDC0
	ldr	r0, .P0201DDCC	@ =gCmdQueue
	str	r0, [r2]
.L0201DDC0:
	bx	lr
	.hword 0x0000
.P0201DDC4:	.word gCmdWrite
.P0201DDC8:	.word gCmdEnd
.P0201DDCC:	.word gCmdQueue

@ ======================================================================================
@ cmdInit   (0201DDD0)
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
	ldr	r0, .P0201DDF4	@ =gCmdRead
	ldr	r1, .P0201DDF8	@ =gCmdQueue
	str	r1, [r0]
	ldr	r0, .P0201DDFC	@ =gCmdWrite
	str	r1, [r0]
	ldr	r0, .P0201DE00	@ =gCmdCommitted
	str	r1, [r0]
	ldr	r0, .P0201DE04	@ =gCmdEnd
	movs	r2, #0x90
	lsls	r2, r2, #2
	adds	r1, r1, r2
	str	r1, [r0]
	ldr	r0, .P0201DE08	@ =gHookNote
	movs	r1, #0
	str	r1, [r0]
	ldr	r0, .P0201DE0C	@ =gHookCA
	str	r1, [r0]
	bx	lr
.P0201DDF4:	.word gCmdRead
.P0201DDF8:	.word gCmdQueue
.P0201DDFC:	.word gCmdWrite
.P0201DE00:	.word gCmdCommitted
.P0201DE04:	.word gCmdEnd
.P0201DE08:	.word gHookNote
.P0201DE0C:	.word gHookCA

@ ======================================================================================
@ cmdPop   (0201DE10)
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
	ldr	r3, .P0201DE20	@ =gCmdRead
	ldr	r2, [r3]
	ldr	r0, .P0201DE24	@ =gCmdCommitted
	ldr	r0, [r0]
	cmp	r2, r0
	bne	.L0201DE28
	movs	r0, #0
	b	.L0201DE3C
.P0201DE20:	.word gCmdRead
.P0201DE24:	.word gCmdCommitted
.L0201DE28:
	adds	r0, r2, #0
	adds	r0, #0xc
	str	r0, [r3]
	ldr	r1, .P0201DE40	@ =gCmdEnd
	ldr	r1, [r1]
	cmp	r0, r1
	bne	.L0201DE3A
	ldr	r0, .P0201DE44	@ =gCmdQueue
	str	r0, [r3]
.L0201DE3A:
	adds	r0, r2, #0
.L0201DE3C:
	bx	lr
	.hword 0x0000
.P0201DE40:	.word gCmdEnd
.P0201DE44:	.word gCmdQueue

@ ======================================================================================
@ sndCommit   (0201DE48)
@
@   void sndCommit(void)                /* make the commands queued since the last call visible */
@   {
@       gCmdCommitted = gCmdWrite;      /* no overflow check: 47 queued commands lose 46         */
@   }
@ ======================================================================================
	.global sndCommit
	.thumb_func
sndCommit:
	ldr	r0, .P0201DE54	@ =gCmdCommitted
	ldr	r1, .P0201DE58	@ =gCmdWrite
	ldr	r1, [r1]
	str	r1, [r0]
	bx	lr
	.hword 0x0000
.P0201DE54:	.word gCmdCommitted
.P0201DE58:	.word gCmdWrite

@ ======================================================================================
@ sndPlaySong   (0201DE5C)
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
	ldr	r2, .P0201DE7C	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #0
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201DE7C:	.word gCmdWrite

@ ======================================================================================
@ sndPlaySfx   (0201DE80)
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
	ldr	r3, .P0201DEA4	@ =gCmdWrite
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
.P0201DEA4:	.word gCmdWrite

@ ======================================================================================
@ sndFadeOut   (0201DEA8)
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
	ldr	r2, .P0201DEC8	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #2
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201DEC8:	.word gCmdWrite

@ ======================================================================================
@ sndPause   (0201DECC)
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
	ldr	r2, .P0201DEEC	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #3
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201DEEC:	.word gCmdWrite

@ ======================================================================================
@ sndFadeOutMask   (0201DEF0)
@
@   void sndFadeOutMask(u32 mask, u32 frames)      { queue(0x200, frames, mask); }
@ ======================================================================================
	.global sndFadeOutMask
	.thumb_func
sndFadeOutMask:
	push	{lr}
	lsls	r1, r1, #0x10
	lsrs	r1, r1, #0x10
	ldr	r2, .P0201DF0C	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #0x80
	lsls	r3, r3, #2
	strh	r3, [r2]
	str	r1, [r2, #4]
	str	r0, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
.P0201DF0C:	.word gCmdWrite

@ ======================================================================================
@ sndPauseMask   (0201DF10)
@
@   void sndPauseMask(u32 mask, u32 on)            { queue(0x201, on, mask); }
@ ======================================================================================
	.global sndPauseMask
	.thumb_func
sndPauseMask:
	push	{lr}
	lsls	r1, r1, #0x18
	lsrs	r1, r1, #0x18
	ldr	r2, .P0201DF2C	@ =gCmdWrite
	ldr	r2, [r2]
	ldr	r3, .P0201DF30	@ =0x00000201
	strh	r3, [r2]
	str	r1, [r2, #4]
	str	r0, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201DF2C:	.word gCmdWrite
.P0201DF30:	.word 0x00000201

@ ======================================================================================
@ sndSetTempo   (0201DF34)
@
@   void sndSetTempo(u32 pl, s32 ofs)              { queue(0x004, pl, ofs); }   /* tempo offset   */
@ ======================================================================================
	.global sndSetTempo
	.thumb_func
sndSetTempo:
	push	{lr}
	lsls	r0, r0, #0x10
	lsrs	r0, r0, #0x10
	ldr	r2, .P0201DF54	@ =gCmdWrite
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
.P0201DF54:	.word gCmdWrite

@ ======================================================================================
@ sndSetVolume2   (0201DF58)
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
	ldr	r2, .P0201DF78	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #5
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201DF78:	.word gCmdWrite

@ ======================================================================================
@ sndSetHookFlags   (0201DF7C)
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
	ldr	r2, .P0201DF9C	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #6
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201DF9C:	.word gCmdWrite

@ ======================================================================================
@ sndMuteTracks   (0201DFA0)
@
@   void sndMuteTracks(u32 pl, u32 mask, u32 on)   { queue(0x100, pl << 16 | on, mask); }
@ ======================================================================================
	.global sndMuteTracks
	.thumb_func
sndMuteTracks:
	push	{r4, lr}
	lsls	r2, r2, #0x18
	lsrs	r2, r2, #0x18
	ldr	r3, .P0201DFC4	@ =gCmdWrite
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
.P0201DFC4:	.word gCmdWrite

@ ======================================================================================
@ sndSetTrackExpr   (0201DFC8)
@
@   void sndSetTrackExpr(u32 pl, u32 mask, u32 v)  { queue(0x102, pl << 16 | v, mask); }
@ ======================================================================================
	.global sndSetTrackExpr
	.thumb_func
sndSetTrackExpr:
	push	{r4, lr}
	lsls	r2, r2, #0x18
	lsrs	r2, r2, #0x18
	ldr	r3, .P0201DFEC	@ =gCmdWrite
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
.P0201DFEC:	.word gCmdWrite

@ ======================================================================================
@ sndSetTrackPan   (0201DFF0)
@
@   void sndSetTrackPan(u32 pl, u32 mask, u32 pan) { queue(0x101, pl << 16 | pan, mask); }
@ ======================================================================================
	.global sndSetTrackPan
	.thumb_func
sndSetTrackPan:
	push	{r4, lr}
	lsls	r2, r2, #0x18
	lsrs	r2, r2, #0x18
	ldr	r3, .P0201E010	@ =gCmdWrite
	ldr	r4, [r3]
	ldr	r3, .P0201E014	@ =0x00000101
	strh	r3, [r4]
	lsls	r0, r0, #0x10
	orrs	r0, r2
	str	r0, [r4, #4]
	str	r1, [r4, #8]
	bl	cmdNext
	pop	{r4}
	pop	{r0}
	bx	r0
.P0201E010:	.word gCmdWrite
.P0201E014:	.word 0x00000101

@ ======================================================================================
@ sndSetEcho   (0201E018)
@
@   void sndSetEcho(u32 shift)                     { queue(0x300, shift); }     /* 16 = off       */
@ ======================================================================================
	.global sndSetEcho
	.thumb_func
sndSetEcho:
	push	{lr}
	lsls	r0, r0, #0x18
	lsrs	r0, r0, #0x18
	ldr	r1, .P0201E034	@ =gCmdWrite
	ldr	r2, [r1]
	movs	r1, #0xc0
	lsls	r1, r1, #2
	strh	r1, [r2]
	str	r0, [r2, #4]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201E034:	.word gCmdWrite

@ ======================================================================================
@ sndCallback   (0201E038)
@
@   void sndCallback(void (*fn)(u32), u32 arg)     { queue(0x301, fn, arg); }   /* run fn(arg) in sndMain */
@ ======================================================================================
	.global sndCallback
	.thumb_func
sndCallback:
	push	{lr}
	ldr	r2, .P0201E050	@ =gCmdWrite
	ldr	r2, [r2]
	ldr	r3, .P0201E054	@ =0x00000301
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201E050:	.word gCmdWrite
.P0201E054:	.word 0x00000301

@ ======================================================================================
@ sndSetHookCA   (0201E058)
@
@   void sndSetHookCA(void *fn)                    { queue(0x302, fn); }
@ ======================================================================================
	.global sndSetHookCA
	.thumb_func
sndSetHookCA:
	push	{lr}
	ldr	r1, .P0201E06C	@ =gCmdWrite
	ldr	r2, [r1]
	ldr	r1, .P0201E070	@ =0x00000302
	strh	r1, [r2]
	str	r0, [r2, #4]
	bl	cmdNext
	pop	{r0}
	bx	r0
.P0201E06C:	.word gCmdWrite
.P0201E070:	.word 0x00000302

@ ======================================================================================
@ sndSetHookNote   (0201E074)
@
@   void sndSetHookNote(void *fn)                  { queue(0x303, fn); }
@ ======================================================================================
	.global sndSetHookNote
	.thumb_func
sndSetHookNote:
	push	{lr}
	ldr	r1, .P0201E088	@ =gCmdWrite
	ldr	r2, [r1]
	ldr	r1, .P0201E08C	@ =0x00000303
	strh	r1, [r2]
	str	r0, [r2, #4]
	bl	cmdNext
	pop	{r0}
	bx	r0
.P0201E088:	.word gCmdWrite
.P0201E08C:	.word 0x00000303

@ ======================================================================================
@ cmdPlayer   (0201E090)
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
	ldr	r0, .P0201E0B0	@ =gPlayers
	adds	r2, r1, r0
	ldrh	r0, [r3]
	cmp	r0, #6
	bhi	.L0201E11E
	lsls	r0, r0, #2
	ldr	r1, .P0201E0B4	@ =0x0201E0B8
	adds	r0, r0, r1
	ldr	r0, [r0]
	mov	pc, r0
.P0201E0B0:	.word gPlayers
.P0201E0B4:	.word 0x0201E0B8
	.word .L0201E0D4
	.word .L0201E0DE
	.word .L0201E0F4
	.word .L0201E0FE
	.word .L0201E110
	.word .L0201E116
	.word .L0201E108
.L0201E0D4:
	ldr	r0, [r3, #4]
	ldr	r1, [r3, #8]
	bl	doPlaySong
	b	.L0201E11E
.L0201E0DE:
	ldr	r1, [r3, #4]
	lsrs	r0, r1, #0x10
	ldr	r2, .P0201E0F0	@ =0x0000FFFF
	ands	r1, r2
	ldr	r2, [r3, #8]
	bl	doPlaySfx
	b	.L0201E11E
	.hword 0x0000
.P0201E0F0:	.word 0x0000FFFF
.L0201E0F4:
	ldr	r0, [r3, #4]
	ldr	r1, [r3, #8]
	bl	playerFadeOut
	b	.L0201E11E
.L0201E0FE:
	ldr	r0, [r3, #4]
	ldrb	r1, [r3, #8]
	bl	playerSetPause
	b	.L0201E11E
.L0201E108:
	ldr	r1, [r3, #8]
	adds	r0, r2, #0
	adds	r0, #0x43
	b	.L0201E11C
.L0201E110:
	ldr	r0, [r3, #8]
	strh	r0, [r2, #0x32]
	b	.L0201E11E
.L0201E116:
	ldr	r1, [r3, #8]
	adds	r0, r2, #0
	adds	r0, #0x40
.L0201E11C:
	strb	r1, [r0]
.L0201E11E:
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ cmdTrack   (0201E124)
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
	ldr	r0, .P0201E14C	@ =gPlayers
	adds	r1, r1, r0
	movs	r4, #0
	ldrh	r3, [r2]
	ldr	r0, .P0201E150	@ =0x00000101
	cmp	r3, r0
	beq	.L0201E1C2
	cmp	r3, r0
	bgt	.L0201E154
	subs	r0, #1
	cmp	r3, r0
	beq	.L0201E15E
	b	.L0201E1F2
	.hword 0x0000
.P0201E14C:	.word gPlayers
.P0201E150:	.word 0x00000101
.L0201E154:
	movs	r0, #0x81
	lsls	r0, r0, #1
	cmp	r3, r0
	beq	.L0201E190
	b	.L0201E1F2
.L0201E15E:
	ldr	r0, [r2, #8]
	cmp	r0, #0
	beq	.L0201E1F2
	movs	r5, #1
	adds	r3, r1, #0
	adds	r3, #8
.L0201E16A:
	ands	r0, r5
	cmp	r0, #0
	beq	.L0201E17C
	ldr	r0, [r3]
	cmp	r0, #0
	beq	.L0201E17C
	ldr	r1, [r2, #4]
	adds	r0, #0x4a
	strb	r1, [r0]
.L0201E17C:
	adds	r3, #4
	adds	r4, #1
	ldr	r0, [r2, #8]
	lsrs	r0, r0, #1
	str	r0, [r2, #8]
	cmp	r0, #0
	beq	.L0201E1F2
	cmp	r4, #9
	ble	.L0201E16A
	b	.L0201E1F2
.L0201E190:
	ldr	r0, [r2, #8]
	cmp	r0, #0
	beq	.L0201E1F2
	movs	r5, #1
	adds	r3, r1, #0
	adds	r3, #8
.L0201E19C:
	ands	r0, r5
	cmp	r0, #0
	beq	.L0201E1AE
	ldr	r0, [r3]
	cmp	r0, #0
	beq	.L0201E1AE
	ldr	r1, [r2, #4]
	adds	r0, #0x4e
	strb	r1, [r0]
.L0201E1AE:
	adds	r3, #4
	adds	r4, #1
	ldr	r0, [r2, #8]
	lsrs	r0, r0, #1
	str	r0, [r2, #8]
	cmp	r0, #0
	beq	.L0201E1F2
	cmp	r4, #9
	ble	.L0201E19C
	b	.L0201E1F2
.L0201E1C2:
	ldr	r0, [r2, #8]
	cmp	r0, #0
	beq	.L0201E1F2
	movs	r5, #1
	adds	r3, r1, #0
	adds	r3, #8
.L0201E1CE:
	ands	r0, r5
	cmp	r0, #0
	beq	.L0201E1E0
	ldr	r0, [r3]
	cmp	r0, #0
	beq	.L0201E1E0
	ldr	r1, [r2, #4]
	adds	r0, #0x4b
	strb	r1, [r0]
.L0201E1E0:
	adds	r3, #4
	adds	r4, #1
	ldr	r0, [r2, #8]
	lsrs	r0, r0, #1
	str	r0, [r2, #8]
	cmp	r0, #0
	beq	.L0201E1F2
	cmp	r4, #9
	ble	.L0201E1CE
.L0201E1F2:
	pop	{r4, r5}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ cmdMask   (0201E1F8)
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
	beq	.L0201E210
	adds	r0, #1
	cmp	r1, r0
	beq	.L0201E23A
	b	.L0201E262
.L0201E210:
	ldr	r1, [r4, #8]
	cmp	r1, #0
	beq	.L0201E262
.L0201E216:
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0201E226
	ldr	r1, [r4, #4]
	adds	r0, r5, #0
	bl	playerFadeOut
.L0201E226:
	adds	r5, #1
	ldr	r0, [r4, #8]
	lsrs	r0, r0, #1
	str	r0, [r4, #8]
	adds	r1, r0, #0
	cmp	r1, #0
	beq	.L0201E262
	cmp	r5, #0x13
	ble	.L0201E216
	b	.L0201E262
.L0201E23A:
	ldr	r1, [r4, #8]
	cmp	r1, #0
	beq	.L0201E262
.L0201E240:
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0201E250
	ldrb	r1, [r4, #4]
	adds	r0, r5, #0
	bl	playerSetPause
.L0201E250:
	adds	r5, #1
	ldr	r0, [r4, #8]
	lsrs	r0, r0, #1
	str	r0, [r4, #8]
	adds	r1, r0, #0
	cmp	r1, #0
	beq	.L0201E262
	cmp	r5, #0x13
	ble	.L0201E240
.L0201E262:
	pop	{r4, r5}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ cmdGlobal   (0201E268)
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
	ldr	r0, .P0201E280	@ =0x00000301
	cmp	r1, r0
	beq	.L0201E298
	cmp	r1, r0
	bgt	.L0201E284
	subs	r0, #1
	cmp	r1, r0
	beq	.L0201E2B8
	b	.L0201E2BE
.P0201E280:	.word 0x00000301
.L0201E284:
	ldr	r0, .P0201E294	@ =0x00000302
	cmp	r1, r0
	beq	.L0201E2A2
	adds	r0, #1
	cmp	r1, r0
	beq	.L0201E2AC
	b	.L0201E2BE
	.hword 0x0000
.P0201E294:	.word 0x00000302
.L0201E298:
	ldr	r0, [r2, #8]
	ldr	r1, [r2, #4]
	bl	_call_via_r1
	b	.L0201E2BE
.L0201E2A2:
	ldr	r1, .P0201E2A8	@ =gHookCA
	b	.L0201E2AE
	.hword 0x0000
.P0201E2A8:	.word gHookCA
.L0201E2AC:
	ldr	r1, .P0201E2B4	@ =gHookNote
.L0201E2AE:
	ldr	r0, [r2, #4]
	str	r0, [r1]
	b	.L0201E2BE
.P0201E2B4:	.word gHookNote
.L0201E2B8:
	ldrb	r0, [r2, #4]
	bl	echoSetFeedback
.L0201E2BE:
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ cmdProcess   (0201E2C4)
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
	beq	.L0201E2EC
	ldr	r4, .P0201E2F4	@ =kCmdHandlers
.L0201E2D2:
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
	bne	.L0201E2D2
.L0201E2EC:
	pop	{r4}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201E2F4:	.word kCmdHandlers
	.arm

@ ======================================================================================
@ armDownmix   (0201E2F8)
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
.L0201E308:
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
	bne	.L0201E308
	pop	{r4, r5}
	bx	lr

@ ======================================================================================
@ armMixVoice   (0201E3B8)
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
	bne	.L0201E498
.L0201E3D4:
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
	blo	.L0201E3D4
	mov	r0, r4
	pop	{r4, r5, r6, r7, r8, sb}
	bx	lr
.L0201E498:
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
	blo	.L0201E498
	mov	r0, r4
	pop	{r4, r5, r6, r7, r8, sb}
	bx	lr

@ ======================================================================================
@ armEcho   (0201E4D8)
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
.L0201E4E8:
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
	blo	.L0201E4E8
	pop	{r4, r5}
	bx	lr
