@ --------------------------------------------------------------------------------------
@ sma2_mb_sound.s - sound driver of Super Mario Advance 2 (E), Mario Bros. multiboot image
@ Thumb code 0201C0D0-0201E2D8, ARM mixing loops 0201E2D8-0201E5B8 (copied to IWRAM by sndInit).
@ Generated from the ROM by gen_sources.py; names and comments from the analysis.
@ The pseudo-C above each function describes the Super Mario Advance 4 build; where this
@ build differs, the difference is given after "In this build".
@ Rebuilds byte-identical: see Makefile.
@ --------------------------------------------------------------------------------------
	.syntax unified
	.equ GEN_A, 1
	.include "nsnd.inc"
	.include "sma2_mb_ram.inc"
	.section .snd_code, "ax"
	.thumb

@ ======================================================================================
@ sndInit   (0201C0D0)
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
	ldr	r1, .P0201C158	@ =gCfg
	str	r0, [r1]
	ldr	r1, .P0201C15C	@ =REG_SOUNDCNT_X
	movs	r0, #0
	strb	r0, [r1]
	movs	r0, #0x80
	strb	r0, [r1]
	subs	r1, #4
	ldr	r2, .P0201C160	@ =0x0000FF77
	adds	r0, r2, #0
	strh	r0, [r1]
	adds	r1, #2
	movs	r0, #0xd
	strb	r0, [r1]
	ldr	r2, .P0201C164	@ =REG_SOUNDBIAS
	ldrh	r1, [r2]
	ldr	r0, .P0201C168	@ =0x00003FFF
	ands	r0, r1
	movs	r3, #0x80
	lsls	r3, r3, #7
	adds	r1, r3, #0
	orrs	r0, r1
	strh	r0, [r2]
	ldr	r1, .P0201C16C	@ =REG_NR10
	movs	r0, #8
	strh	r0, [r1]
	adds	r1, #2
	movs	r2, #0xf0
	lsls	r2, r2, #8
	adds	r0, r2, #0
	strh	r0, [r1]
	ldr	r5, .P0201C170	@ =armDownmix
	ldr	r4, .P0201C174	@ =gIwramCode
	adds	r0, r5, #0
	adds	r1, r4, #0
	movs	r2, #0xd8
	bl	CpuFastSet
	ldr	r0, .P0201C178	@ =gFnDownmix
	str	r4, [r0]
	ldr	r1, .P0201C17C	@ =gFnMixVoice
	ldr	r0, .P0201C180	@ =armMixVoice
	subs	r0, r0, r5
	adds	r0, r0, r4
	str	r0, [r1]
	ldr	r1, .P0201C184	@ =gFnEcho
	ldr	r0, .P0201C188	@ =armEcho
	subs	r0, r0, r5
	adds	r0, r0, r4
	str	r0, [r1]
	ldr	r0, .P0201C18C	@ =gDmaBuffers
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
.P0201C158:	.word gCfg
.P0201C15C:	.word REG_SOUNDCNT_X
.P0201C160:	.word 0x0000FF77
.P0201C164:	.word REG_SOUNDBIAS
.P0201C168:	.word 0x00003FFF
.P0201C16C:	.word REG_NR10
.P0201C170:	.word armDownmix
.P0201C174:	.word gIwramCode
.P0201C178:	.word gFnDownmix
.P0201C17C:	.word gFnMixVoice
.P0201C180:	.word armMixVoice
.P0201C184:	.word gFnEcho
.P0201C188:	.word armEcho
.P0201C18C:	.word gDmaBuffers

@ ======================================================================================
@ sndVSync   (0201C190)
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
@ sndMain   (0201C19C)
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
	ldr	r0, .P0201C1BC	@ =gMixEnabled
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L0201C1B6
	bl	mixFrame
.L0201C1B6:
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201C1BC:	.word gMixEnabled

@ ======================================================================================
@ mixInit   (0201C1C0)
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
	ldr	r1, .P0201C210	@ =gMixEnabled
	movs	r0, #1
	strb	r0, [r1]
	ldr	r1, .P0201C214	@ =gDmaBufA
	str	r3, [r1]
	ldr	r2, .P0201C218	@ =gDmaBufB
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
	ldr	r1, .P0201C21C	@ =gTimerReload
	ldr	r2, .P0201C220	@ =0x0000F9C4
	adds	r0, r2, #0
	strh	r0, [r1]
	ldr	r1, .P0201C224	@ =gDmaBufIdx
	movs	r0, #0
	strb	r0, [r1]
	ldr	r1, .P0201C228	@ =REG_SOUNDCNT_H+1
	movs	r0, #0x9a
	strb	r0, [r1]
	ldr	r0, .P0201C22C	@ =REG_FIFO_A
	movs	r1, #0
	str	r1, [r0]
	adds	r0, #4
	str	r1, [r0]
	add	sp, #4
	pop	{r4}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201C210:	.word gMixEnabled
.P0201C214:	.word gDmaBufA
.P0201C218:	.word gDmaBufB
.P0201C21C:	.word gTimerReload
.P0201C220:	.word 0x0000F9C4
.P0201C224:	.word gDmaBufIdx
.P0201C228:	.word REG_SOUNDCNT_H+1
.P0201C22C:	.word REG_FIFO_A

@ ======================================================================================
@ mixDmaRestart   (0201C230)
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
	ldr	r2, .P0201C2AC	@ =REG_TM0CNT
	ldr	r0, .P0201C2B0	@ =gTimerReload
	ldrh	r0, [r0]
	movs	r1, #0x80
	lsls	r1, r1, #0x10
	orrs	r0, r1
	str	r0, [r2]
	ldr	r0, .P0201C2B4	@ =gMixEnabled
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L0201C2A4
	ldr	r4, .P0201C2B8	@ =REG_DMA1SAD
	ldrh	r1, [r4, #0xa]
	ldr	r2, .P0201C2BC	@ =0x0000C5FF
	adds	r0, r2, #0
	ands	r0, r1
	strh	r0, [r4, #0xa]
	ldrh	r3, [r4, #0xa]
	ldr	r1, .P0201C2C0	@ =0x00007FFF
	adds	r0, r1, #0
	ands	r0, r3
	strh	r0, [r4, #0xa]
	ldrh	r0, [r4, #0xa]
	ldr	r3, .P0201C2C4	@ =REG_DMA2SAD
	ldrh	r0, [r3, #0xa]
	ands	r2, r0
	strh	r2, [r3, #0xa]
	ldrh	r0, [r3, #0xa]
	ands	r1, r0
	strh	r1, [r3, #0xa]
	ldrh	r0, [r3, #0xa]
	ldr	r1, .P0201C2C8	@ =gDmaBufA
	ldr	r2, .P0201C2CC	@ =gDmaBufIdx
	ldrb	r0, [r2]
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r0, [r0]
	str	r0, [r4]
	ldr	r0, .P0201C2D0	@ =REG_FIFO_A
	str	r0, [r4, #4]
	ldr	r5, .P0201C2D4	@ =0xB6400004
	str	r5, [r4, #8]
	ldr	r0, [r4, #8]
	ldr	r1, .P0201C2D8	@ =gDmaBufB
	ldrb	r0, [r2]
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r0, [r0]
	str	r0, [r3]
	ldr	r0, .P0201C2DC	@ =REG_FIFO_B
	str	r0, [r3, #4]
	str	r5, [r3, #8]
	ldr	r0, [r3, #8]
	ldrb	r1, [r2]
	movs	r0, #1
	subs	r0, r0, r1
	strb	r0, [r2]
.L0201C2A4:
	pop	{r4, r5}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201C2AC:	.word REG_TM0CNT
.P0201C2B0:	.word gTimerReload
.P0201C2B4:	.word gMixEnabled
.P0201C2B8:	.word REG_DMA1SAD
.P0201C2BC:	.word 0x0000C5FF
.P0201C2C0:	.word 0x00007FFF
.P0201C2C4:	.word REG_DMA2SAD
.P0201C2C8:	.word gDmaBufA
.P0201C2CC:	.word gDmaBufIdx
.P0201C2D0:	.word REG_FIFO_A
.P0201C2D4:	.word 0xB6400004
.P0201C2D8:	.word gDmaBufB
.P0201C2DC:	.word REG_FIFO_B

@ ======================================================================================
@ sndStopOutput   (0201C2E0)
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
	ldr	r1, .P0201C318	@ =gMixEnabled
	movs	r0, #0
	strb	r0, [r1]
	ldr	r1, .P0201C31C	@ =REG_DMA1SAD
	ldrh	r2, [r1, #0xa]
	ldr	r3, .P0201C320	@ =0x0000C5FF
	adds	r0, r3, #0
	ands	r0, r2
	strh	r0, [r1, #0xa]
	ldrh	r4, [r1, #0xa]
	ldr	r2, .P0201C324	@ =0x00007FFF
	adds	r0, r2, #0
	ands	r0, r4
	strh	r0, [r1, #0xa]
	ldrh	r0, [r1, #0xa]
	ldr	r0, .P0201C328	@ =REG_DMA2SAD
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
.P0201C318:	.word gMixEnabled
.P0201C31C:	.word REG_DMA1SAD
.P0201C320:	.word 0x0000C5FF
.P0201C324:	.word 0x00007FFF
.P0201C328:	.word REG_DMA2SAD

@ ======================================================================================
@ sndStartOutput   (0201C32C)
@
@   void sndStartOutput(void)
@   {
@       gMixEnabled = 1;        /* DMA restarts at the next sndVSync */
@   }
@ ======================================================================================
	.global sndStartOutput
	.thumb_func
sndStartOutput:
	ldr	r1, .P0201C334	@ =gMixEnabled
	movs	r0, #1
	strb	r0, [r1]
	bx	lr
.P0201C334:	.word gMixEnabled

@ ======================================================================================
@ voiceInitAll   (0201C338)
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
	ldr	r1, .P0201C490	@ =gLastWave
	movs	r0, #0
	str	r0, [r1]
	adds	r3, r1, #0
	ldr	r2, .P0201C494	@ =gPsgVoices
	ldr	r0, .P0201C498	@ =gDsVoices
	mov	ip, r0
	movs	r1, #0xb6
	lsls	r1, r1, #1
	adds	r7, r3, r1
	movs	r1, #0
	movs	r4, #3
	ldr	r5, .P0201C49C	@ =0x00000169
	adds	r0, r2, r5
.L0201C35A:
	strb	r1, [r0]
	subs	r0, #0x78
	subs	r4, #1
	cmp	r4, #0
	bge	.L0201C35A
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
	ldr	r0, .P0201C498	@ =gDsVoices
	movs	r4, #6
.L0201C386:
	strb	r1, [r0, #1]
	strb	r1, [r0]
	adds	r0, #0x78
	subs	r4, #1
	cmp	r4, #0
	bge	.L0201C386
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
.L0201C3E4:
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
	bge	.L0201C3E4
	movs	r0, #0xcf
	lsls	r0, r0, #2
	add	r0, ip
	strb	r7, [r0]
	lsrs	r1, r7, #8
	ldr	r0, .P0201C4A0	@ =0x0000033D
	add	r0, ip
	strb	r1, [r0]
	lsrs	r1, r7, #0x10
	ldr	r0, .P0201C4A4	@ =0x0000033E
	add	r0, ip
	strb	r1, [r0]
	lsrs	r1, r7, #0x18
	ldr	r0, .P0201C4A8	@ =0x0000033F
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
	ldr	r0, .P0201C4AC	@ =0x00000339
	add	r0, ip
	strb	r2, [r0]
	lsrs	r2, r1, #0x10
	ldr	r0, .P0201C4B0	@ =0x0000033A
	add	r0, ip
	strb	r2, [r0]
	lsrs	r1, r1, #0x18
	ldr	r0, .P0201C4B4	@ =0x0000033B
	add	r0, ip
	strb	r1, [r0]
	ldr	r0, .P0201C4B8	@ =0xFFFFFE94
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
	ldr	r2, .P0201C4BC	@ =0xFFFFFE98
	adds	r0, r7, r2
	str	r0, [r1]
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201C490:	.word gLastWave
.P0201C494:	.word gPsgVoices
.P0201C498:	.word gDsVoices
.P0201C49C:	.word 0x00000169
.P0201C4A0:	.word 0x0000033D
.P0201C4A4:	.word 0x0000033E
.P0201C4A8:	.word 0x0000033F
.P0201C4AC:	.word 0x00000339
.P0201C4B0:	.word 0x0000033A
.P0201C4B4:	.word 0x0000033B
.P0201C4B8:	.word 0xFFFFFE94
.P0201C4BC:	.word 0xFFFFFE98

@ ======================================================================================
@ voiceUnlink   (0201C4C0)
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
@ voiceListInsertActive   (0201C4D0)
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
	ldr	r0, .P0201C50C	@ =gLastWave
	ldr	r1, [r0, #0x70]
	ldrb	r2, [r3, #1]
	cmp	r2, #1
	bne	.L0201C514
	adds	r0, #0x7c
	cmp	r1, r0
	beq	.L0201C544
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	bne	.L0201C4F2
	ldrb	r0, [r3, #8]
	ldrb	r2, [r1, #8]
	cmp	r0, r2
	blo	.L0201C544
.L0201C4F2:
	ldr	r1, [r1, #0x6c]
	ldr	r0, .P0201C510	@ =gActiveTail
	cmp	r1, r0
	beq	.L0201C544
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	bne	.L0201C4F2
	ldrb	r0, [r3, #8]
	ldrb	r4, [r1, #8]
	cmp	r0, r4
	bhs	.L0201C4F2
	b	.L0201C544
	.hword 0x0000
.P0201C50C:	.word gLastWave
.P0201C510:	.word gActiveTail
.L0201C514:
	cmp	r2, #2
	bne	.L0201C550
	adds	r2, r0, #0
	adds	r2, #0x7c
	cmp	r1, r2
	beq	.L0201C544
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	beq	.L0201C544
	ldrb	r0, [r3, #8]
	ldrb	r4, [r1, #8]
	cmp	r0, r4
	blo	.L0201C544
	adds	r4, r2, #0
	adds	r2, r0, #0
.L0201C532:
	ldr	r1, [r1, #0x6c]
	cmp	r1, r4
	beq	.L0201C544
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	beq	.L0201C544
	ldrb	r0, [r1, #8]
	cmp	r2, r0
	bhs	.L0201C532
.L0201C544:
	str	r1, [r3, #0x6c]
	ldr	r0, [r1, #0x68]
	str	r0, [r3, #0x68]
	ldr	r0, [r1, #0x68]
	str	r3, [r0, #0x6c]
	str	r3, [r1, #0x68]
.L0201C550:
	pop	{r4}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ keyToFreq   (0201C558)
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
	bge	.L0201C572
	movs	r2, #0
	b	.L0201C578
.L0201C572:
	cmp	r1, #0x77
	ble	.L0201C578
	movs	r2, #0x78
.L0201C578:
	ldrb	r0, [r0]
	cmp	r0, #0
	bne	.L0201C590
	ldr	r0, .P0201C58C	@ =kDsPitch
	lsls	r1, r2, #0x10
	asrs	r1, r1, #0xe
	adds	r1, r1, r0
	ldr	r0, [r1]
	b	.L0201C5A8
	.hword 0x0000
.P0201C58C:	.word kDsPitch
.L0201C590:
	cmp	r0, #4
	beq	.L0201C5A4
	ldr	r0, .P0201C5A0	@ =kPsgFreq
	lsls	r1, r2, #0x10
	asrs	r1, r1, #0xf
	adds	r1, r1, r0
	ldrh	r0, [r1]
	b	.L0201C5A8
.P0201C5A0:	.word kPsgFreq
.L0201C5A4:
	lsls	r0, r2, #0x10
	asrs	r0, r0, #0x10
.L0201C5A8:
	bx	lr
	movs	r0, r0

@ ======================================================================================
@ noiseDivider   (0201C5AC)
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
	bls	.L0201C5B6
	movs	r1, #0x77
.L0201C5B6:
	ldr	r0, .P0201C5C0	@ =kNoiseTable
	adds	r0, r1, r0
	ldrb	r0, [r0]
	bx	lr
	.hword 0x0000
.P0201C5C0:	.word kNoiseTable

@ ======================================================================================
@ envStep   (0201C5C4)
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
	bne	.L0201C61E
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
	bge	.L0201C5F0
	strb	r1, [r4, #0x10]
.L0201C5F0:
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
.L0201C61E:
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
@ echoSetFeedback   (0201C634)
@
@   void echoSetFeedback(u32 shift) { }  /* empty: this build has no echo */
@ ======================================================================================
	.global echoSetFeedback
	.thumb_func
echoSetFeedback:
	bx	lr
	movs	r0, r0

@ ======================================================================================
@ dsVolume   (0201C638)
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
	bne	.L0201C678
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
	b	.L0201C68A
.L0201C678:
	adds	r0, r5, #0
	adds	r0, #0x58
	ldrb	r0, [r0]
	adds	r0, #0xe6
	ldr	r1, [r5, #0x14]
	muls	r0, r1, r0
	lsrs	r0, r0, #9
	str	r0, [r5, #0x14]
	adds	r4, r0, #0
.L0201C68A:
	lsrs	r4, r4, #8
	adds	r0, r4, #0
	pop	{r4, r5}
	pop	{r1}
	bx	r1

@ ======================================================================================
@ psgEnvelope   (0201C694)
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
	bne	.L0201C6B2
	movs	r6, #1
.L0201C6B2:
	adds	r0, r5, #0
	bl	envStep
	cmp	r6, #0
	bne	.L0201C6C0
	movs	r0, #8
	b	.L0201C786
.L0201C6C0:
	cmp	r7, #0
	beq	.L0201C6C6
	lsls	r4, r4, #1
.L0201C6C6:
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
	bne	.L0201C70A
	lsrs	r4, r4, #0x16
	str	r4, [r5, #0x14]
	lsls	r0, r4, #2
	adds	r4, r0, r4
	lsrs	r4, r4, #7
	cmp	r4, #4
	bls	.L0201C704
	movs	r4, #4
.L0201C704:
	lsls	r0, r4, #0x18
	lsrs	r0, r0, #0x18
	b	.L0201C786
.L0201C70A:
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
	beq	.L0201C722
	movs	r4, #0xf
.L0201C722:
	ldr	r1, [r5, #0x14]
	ldr	r0, [r5, #0x44]
	muls	r0, r1, r0
	lsrs	r0, r0, #0x19
	str	r0, [r5, #0x14]
	ands	r0, r2
	cmp	r0, #0
	beq	.L0201C736
	movs	r0, #0xf
	str	r0, [r5, #0x14]
.L0201C736:
	ldr	r5, [r5, #0x14]
	cmp	r5, r4
	beq	.L0201C75E
	mov	r1, r8
	ldrh	r2, [r1]
	adds	r0, r2, #0
	adds	r0, #0xf
	lsls	r0, r0, #0x10
	lsrs	r2, r0, #0x10
	subs	r1, r5, r4
	cmp	r1, #0
	bge	.L0201C750
	rsbs	r1, r1, #0
.L0201C750:
	adds	r0, r2, #0
	bl	__divsi3
	lsls	r0, r0, #0x10
	lsrs	r2, r0, #0x10
	cmp	r2, #0
	bne	.L0201C76A
.L0201C75E:
	lsls	r0, r4, #4
	movs	r1, #8
	orrs	r0, r1
	lsls	r0, r0, #0x18
	lsrs	r6, r0, #0x18
	b	.L0201C784
.L0201C76A:
	ldr	r0, .P0201C790	@ =0x0000FFF8
	ands	r0, r2
	cmp	r0, #0
	beq	.L0201C774
	movs	r2, #7
.L0201C774:
	lsls	r0, r4, #4
	orrs	r0, r2
	lsls	r0, r0, #0x18
	lsrs	r6, r0, #0x18
	cmp	r4, r5
	bhs	.L0201C784
	movs	r0, #8
	orrs	r6, r0
.L0201C784:
	adds	r0, r6, #0
.L0201C786:
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1
.P0201C790:	.word 0x0000FFF8

@ ======================================================================================
@ voicePitch   (0201C794)
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
	beq	.L0201C7AC
	subs	r0, #1
	str	r0, [r5, #0x2c]
	b	.L0201C7C6
.L0201C7AC:
	ldr	r4, [r2, #4]
	cmp	r4, #0
	beq	.L0201C7C6
	ldr	r0, [r2, #8]
	ldr	r1, [r2, #0x10]
	adds	r0, r0, r1
	str	r0, [r2, #8]
	subs	r0, r4, #1
	str	r0, [r2, #4]
	cmp	r0, #0
	bne	.L0201C7C6
	ldr	r0, [r2, #0xc]
	str	r0, [r2, #8]
.L0201C7C6:
	ldr	r0, [r2, #8]
	adds	r3, r3, r0
	adds	r2, r6, #0
	adds	r2, #0x4f
	movs	r0, #0
	ldrsb	r0, [r2, r0]
	cmp	r0, #0
	beq	.L0201C81E
	ldr	r1, .P0201C804	@ =kDsPitch
	adds	r0, r6, #0
	adds	r0, #0x50
	ldrb	r0, [r0]
	adds	r0, #0x30
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r1, [r0]
	ldr	r0, .P0201C808	@ =0xFFFF8000
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
	bne	.L0201C80C
	muls	r3, r1, r3
	lsrs	r3, r3, #8
	b	.L0201C81E
.P0201C804:	.word kDsPitch
.P0201C808:	.word 0xFFFF8000
.L0201C80C:
	movs	r4, #0x80
	lsls	r4, r4, #4
	subs	r3, r4, r3
	lsls	r3, r3, #8
	adds	r0, r3, #0
	bl	__udivsi3
	adds	r3, r0, #0
	subs	r3, r4, r3
.L0201C81E:
	adds	r4, r5, #0
	adds	r4, #0x20
	ldr	r0, [r4, #8]
	ldr	r2, [r0, #8]
	cmp	r2, #0
	beq	.L0201C8CC
	ldr	r0, [r4, #4]
	cmp	r0, #0
	bne	.L0201C8C8
	ldr	r0, .P0201C854	@ =kLfoSine
	ldr	r1, [r5, #0x20]
	lsrs	r1, r1, #1
	adds	r1, r1, r0
	ldrb	r1, [r1]
	ldrb	r0, [r5]
	cmp	r0, #0
	bne	.L0201C874
	lsls	r0, r1, #0x18
	asrs	r0, r0, #0x18
	cmp	r0, #0
	blt	.L0201C858
	muls	r0, r3, r0
	muls	r0, r2, r0
	lsrs	r0, r0, #0x13
	adds	r3, r3, r0
	b	.L0201C8AC
	.hword 0x0000
.P0201C854:	.word kLfoSine
.L0201C858:
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
	b	.L0201C8AC
.L0201C874:
	lsls	r0, r1, #0x18
	asrs	r1, r0, #0x18
	cmp	r1, #0
	blt	.L0201C892
	movs	r0, #0x80
	lsls	r0, r0, #4
	subs	r0, r0, r3
	lsls	r0, r0, #0x13
	muls	r1, r2, r1
	movs	r2, #0x80
	lsls	r2, r2, #0xc
	adds	r1, r1, r2
	bl	__udivsi3
	b	.L0201C8A6
.L0201C892:
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
.L0201C8A6:
	movs	r3, #0x80
	lsls	r3, r3, #4
	subs	r3, r3, r0
.L0201C8AC:
	ldr	r0, [r4, #8]
	ldr	r1, [r4]
	ldr	r0, [r0, #4]
	adds	r1, r1, r0
	str	r1, [r4]
	lsrs	r0, r1, #1
	cmp	r0, #0xff
	bls	.L0201C8CC
	ldr	r2, .P0201C8C4	@ =0xFFFFFE00
	adds	r0, r1, r2
	str	r0, [r4]
	b	.L0201C8CC
.P0201C8C4:	.word 0xFFFFFE00
.L0201C8C8:
	subs	r0, #1
	str	r0, [r4, #4]
.L0201C8CC:
	adds	r0, r3, #0
	pop	{r4, r5, r6}
	pop	{r1}
	bx	r1

@ ======================================================================================
@ mixFrame   (0201C8D4)
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
	ldr	r4, .P0201C910	@ =gLastWave
	ldr	r5, [r4, #0x70]
	movs	r0, #0
	str	r0, [sp]
	ldr	r1, .P0201C914	@ =gMixDry
	ldr	r2, .P0201C918	@ =0x010000B0
	mov	r0, sp
	bl	CpuFastSet
	adds	r4, #0x7c
	cmp	r5, r4
	beq	.L0201C98C
.L0201C8F0:
	adds	r0, r5, #0
	bl	dsVolume
	adds	r7, r0, #0
	ldrb	r0, [r5, #1]
	cmp	r0, #1
	bne	.L0201C938
	ldrh	r0, [r5, #0x18]
	subs	r0, #1
	strh	r0, [r5, #0x18]
	ldr	r4, [r5, #4]
	ldrb	r0, [r5, #0x1b]
	cmp	r0, #0
	beq	.L0201C91C
	ldrb	r3, [r5, #0x1c]
	b	.L0201C922
.P0201C910:	.word gLastWave
.P0201C914:	.word gMixDry
.P0201C918:	.word 0x010000B0
.L0201C91C:
	adds	r0, r4, #0
	adds	r0, #0x4b
	ldrb	r3, [r0]
.L0201C922:
	adds	r6, r3, #0
	adds	r0, r5, #0
	bl	voicePitch
	adds	r2, r0, #0
	str	r2, [r5, #0x10]
	adds	r0, r4, #0
	adds	r0, #0x4c
	ldrb	r0, [r0]
	strb	r0, [r5, #0x1a]
	b	.L0201C940
.L0201C938:
	cmp	r7, #0
	beq	.L0201C974
	ldrb	r6, [r5, #0x1c]
	ldr	r2, [r5, #0x10]
.L0201C940:
	lsrs	r2, r2, #2
	ldr	r0, [r5, #0x5c]
	ldr	r0, [r0, #4]
	muls	r2, r0, r2
	adds	r0, r2, #0
	ldr	r1, .P0201C980	@ =0x00002910
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
	bne	.L0201C984
.L0201C974:
	ldr	r5, [r5, #0x6c]
	ldr	r0, [r5, #0x68]
	bl	voiceStop
	b	.L0201C986
	.hword 0x0000
.P0201C980:	.word 0x00002910
.L0201C984:
	ldr	r5, [r5, #0x6c]
.L0201C986:
	ldr	r0, .P0201C9D4	@ =gActiveTail
	cmp	r5, r0
	bne	.L0201C8F0
.L0201C98C:
	movs	r5, #0
	movs	r4, #6
.L0201C990:
	ldr	r0, .P0201C9D8	@ =gDsVoices
	adds	r1, r5, r0
	ldrb	r0, [r1, #1]
	cmp	r0, #1
	bne	.L0201C9A6
	ldrh	r0, [r1, #0x18]
	cmp	r0, #0
	bne	.L0201C9A6
	adds	r0, r1, #0
	bl	noteOff
.L0201C9A6:
	adds	r5, #0x78
	subs	r4, #1
	cmp	r4, #0
	bge	.L0201C990
	ldr	r3, .P0201C9DC	@ =gFnDownmix
	ldr	r0, .P0201C9E0	@ =gMixDry
	ldr	r2, .P0201C9E4	@ =gDmaBufA
	ldr	r1, .P0201C9E8	@ =gDmaBufIdx
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
.P0201C9D4:	.word gActiveTail
.P0201C9D8:	.word gDsVoices
.P0201C9DC:	.word gFnDownmix
.P0201C9E0:	.word gMixDry
.P0201C9E4:	.word gDmaBufA
.P0201C9E8:	.word gDmaBufIdx

@ ======================================================================================
@ psgUpdate   (0201C9EC)
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
.L0201C9FA:
	mov	r1, sl
	lsls	r0, r1, #4
	subs	r0, r0, r1
	lsls	r0, r0, #3
	ldr	r1, .P0201CA38	@ =gPsgVoices
	adds	r4, r0, r1
	ldrb	r0, [r4, #1]
	cmp	r0, #1
	bne	.L0201CA18
	ldrh	r0, [r4, #0x18]
	cmp	r0, #0
	bne	.L0201CA18
	adds	r0, r4, #0
	bl	noteOff
.L0201CA18:
	ldrb	r0, [r4, #1]
	cmp	r0, #0
	bne	.L0201CA20
	b	.L0201CC60
.L0201CA20:
	cmp	r0, #1
	bne	.L0201CA46
	adds	r0, r4, #0
	bl	voicePitch
	adds	r6, r0, #0
	str	r6, [r4, #0x10]
	ldrb	r0, [r4, #0x1b]
	cmp	r0, #0
	beq	.L0201CA3C
	ldrb	r0, [r4, #0x1c]
	b	.L0201CA42
.P0201CA38:	.word gPsgVoices
.L0201CA3C:
	ldr	r0, [r4, #4]
	adds	r0, #0x4b
	ldrb	r0, [r0]
.L0201CA42:
	mov	r8, r0
	b	.L0201CA4C
.L0201CA46:
	ldr	r6, [r4, #0x10]
	ldrb	r2, [r4, #0x1c]
	mov	r8, r2
.L0201CA4C:
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
	ldr	r0, .P0201CA90	@ =REG_NR51
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
	bne	.L0201CA94
	mov	r3, ip
	ldrb	r1, [r3]
	adds	r0, r2, #0
	ands	r0, r1
	orrs	r0, r5
	strb	r0, [r3]
	b	.L0201CABE
.P0201CA90:	.word REG_NR51
.L0201CA94:
	mov	r0, r8
	cmp	r0, #0x3f
	bhi	.L0201CAAE
	mov	r1, ip
	ldrb	r0, [r1]
	adds	r1, r2, #0
	ands	r1, r0
	movs	r0, #0x10
	lsls	r0, r3
	orrs	r1, r0
	mov	r2, ip
	strb	r1, [r2]
	b	.L0201CABE
.L0201CAAE:
	mov	r3, ip
	ldrb	r0, [r3]
	ands	r1, r0
	movs	r0, #1
	mov	r2, sb
	lsls	r0, r2
	orrs	r1, r0
	strb	r1, [r3]
.L0201CABE:
	ldrb	r5, [r4, #1]
	cmp	r5, #1
	bne	.L0201CAE8
	ldr	r0, [r4, #0x60]
	cmp	r0, #0
	bne	.L0201CADC
	adds	r0, r4, #0
	adds	r1, r7, #0
	bl	psgKeyOn
	str	r5, [r4, #0x60]
	ldrh	r0, [r4, #0x18]
	subs	r0, #1
	strh	r0, [r4, #0x18]
	b	.L0201CC60
.L0201CADC:
	adds	r0, #1
	str	r0, [r4, #0x60]
	ldrh	r0, [r4, #0x18]
	subs	r0, #1
	strh	r0, [r4, #0x18]
	b	.L0201CB38
.L0201CAE8:
	ldrb	r0, [r4]
	cmp	r0, #3
	bne	.L0201CB38
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
	beq	.L0201CB08
	lsls	r1, r1, #1
.L0201CB08:
	lsls	r0, r1, #2
	adds	r1, r0, r1
	lsrs	r1, r1, #7
	cmp	r1, #0
	beq	.L0201CB30
	cmp	r1, #4
	bls	.L0201CB18
	movs	r1, #4
.L0201CB18:
	lsls	r1, r1, #0x18
	lsrs	r1, r1, #0x18
	ldr	r2, .P0201CB28	@ =REG_NR32
	ldr	r0, .P0201CB2C	@ =kWaveVolume
	adds	r1, r1, r0
	ldrb	r0, [r1]
	strb	r0, [r2]
	b	.L0201CC60
.P0201CB28:	.word REG_NR32
.P0201CB2C:	.word kWaveVolume
.L0201CB30:
	adds	r0, r4, #0
	bl	voiceStop
	b	.L0201CC60
.L0201CB38:
	ldr	r2, [r4, #0x54]
	ldrb	r1, [r2, #1]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0201CB5A
	ldr	r0, [r4, #0x64]
	ldrh	r3, [r0]
	ldr	r1, [r4, #0x60]
	cmp	r1, r3
	bhs	.L0201CB54
	adds	r0, r0, r1
	ldrb	r5, [r0, #2]
	b	.L0201CB5C
.L0201CB54:
	adds	r0, r3, r0
	ldrb	r5, [r0, #1]
	b	.L0201CB5C
.L0201CB5A:
	movs	r5, #0xff
.L0201CB5C:
	ldrb	r0, [r4]
	cmp	r0, #2
	beq	.L0201CBAC
	cmp	r0, #2
	bgt	.L0201CB6C
	cmp	r0, #1
	beq	.L0201CB76
	b	.L0201CC60
.L0201CB6C:
	cmp	r0, #3
	beq	.L0201CBEC
	cmp	r0, #4
	beq	.L0201CC14
	b	.L0201CC60
.L0201CB76:
	cmp	r7, #8
	beq	.L0201CB94
	ldr	r0, .P0201CB8C	@ =REG_NR12
	strb	r7, [r0]
	ldr	r1, .P0201CB90	@ =REG_SOUND1CNT_X
	movs	r2, #0x80
	lsls	r2, r2, #8
	adds	r0, r2, #0
	orrs	r6, r0
	strh	r6, [r1]
	b	.L0201CB9E
.P0201CB8C:	.word REG_NR12
.P0201CB90:	.word REG_SOUND1CNT_X
.L0201CB94:
	ldrb	r0, [r2, #8]
	cmp	r0, #8
	bne	.L0201CB9E
	ldr	r0, .P0201CBA4	@ =REG_SOUND1CNT_X
	strh	r6, [r0]
.L0201CB9E:
	ldr	r2, .P0201CBA8	@ =REG_NR11
	b	.L0201CBD2
	.hword 0x0000
.P0201CBA4:	.word REG_SOUND1CNT_X
.P0201CBA8:	.word REG_NR11
.L0201CBAC:
	cmp	r7, #8
	beq	.L0201CBCC
	ldr	r0, .P0201CBC4	@ =REG_NR22
	strb	r7, [r0]
	ldr	r1, .P0201CBC8	@ =REG_SOUND2CNT_H
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r0, r3, #0
	orrs	r6, r0
	strh	r6, [r1]
	b	.L0201CBD0
	.hword 0x0000
.P0201CBC4:	.word REG_NR22
.P0201CBC8:	.word REG_SOUND2CNT_H
.L0201CBCC:
	ldr	r0, .P0201CBE4	@ =REG_SOUND2CNT_H
	strh	r6, [r0]
.L0201CBD0:
	ldr	r2, .P0201CBE8	@ =REG_NR21
.L0201CBD2:
	ldrb	r1, [r2]
	movs	r0, #0xc0
	ands	r0, r1
	strb	r0, [r2]
	cmp	r5, #0xff
	beq	.L0201CC60
	lsls	r0, r5, #6
	strb	r0, [r2]
	b	.L0201CC60
.P0201CBE4:	.word REG_SOUND2CNT_H
.P0201CBE8:	.word REG_NR21
.L0201CBEC:
	ldr	r0, .P0201CC0C	@ =REG_SOUND3CNT_X
	ldrh	r1, [r0]
	movs	r3, #0x80
	lsls	r3, r3, #7
	adds	r2, r3, #0
	ands	r1, r2
	orrs	r1, r6
	strh	r1, [r0]
	cmp	r7, #8
	beq	.L0201CC60
	subs	r0, #1
	ldr	r1, .P0201CC10	@ =kWaveVolume
	adds	r1, r7, r1
	ldrb	r1, [r1]
	strb	r1, [r0]
	b	.L0201CC60
.P0201CC0C:	.word REG_SOUND3CNT_X
.P0201CC10:	.word kWaveVolume
.L0201CC14:
	cmp	r7, #8
	beq	.L0201CC22
	ldr	r0, .P0201CC40	@ =REG_NR42
	strb	r7, [r0]
	ldr	r1, .P0201CC44	@ =REG_NR44
	movs	r0, #0x80
	strb	r0, [r1]
.L0201CC22:
	cmp	r5, #0xff
	beq	.L0201CC4C
	ldr	r4, .P0201CC48	@ =REG_NR43
	lsls	r0, r6, #0x10
	lsrs	r0, r0, #0x10
	bl	noiseDivider
	lsls	r0, r0, #0x18
	lsrs	r1, r0, #0x18
	cmp	r5, #0
	beq	.L0201CC3C
	movs	r0, #8
	orrs	r1, r0
.L0201CC3C:
	strb	r1, [r4]
	b	.L0201CC60
.P0201CC40:	.word REG_NR42
.P0201CC44:	.word REG_NR44
.P0201CC48:	.word REG_NR43
.L0201CC4C:
	lsls	r0, r6, #0x10
	lsrs	r0, r0, #0x10
	bl	noiseDivider
	ldr	r3, .P0201CC7C	@ =REG_NR43
	ldrb	r2, [r3]
	movs	r1, #8
	ands	r1, r2
	orrs	r1, r0
	strb	r1, [r3]
.L0201CC60:
	movs	r0, #1
	add	sl, r0
	mov	r1, sl
	cmp	r1, #3
	bgt	.L0201CC6C
	b	.L0201C9FA
.L0201CC6C:
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	sb, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201CC7C:	.word REG_NR43

@ ======================================================================================
@ noteOn   (0201CC80)
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
	beq	.L0201CCA8
	b	.L0201CE44
.L0201CCA8:
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
	beq	.L0201CCD4
	ldrh	r1, [r4, #0x30]
	mov	r0, r8
	bl	__udivsi3
	b	.L0201CCE2
.L0201CCD4:
	movs	r0, #0x32
	ldrsh	r1, [r4, r0]
	ldrh	r4, [r4, #0x30]
	adds	r1, r1, r4
	mov	r0, r8
	bl	__divsi3
.L0201CCE2:
	lsls	r0, r0, #0x10
	lsrs	r0, r0, #0x10
	mov	r8, r0
	adds	r0, r5, #0
	adds	r0, #0x49
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L0201CCFC
	ldr	r0, [r5, #0xc]
	cmp	r0, #0
	beq	.L0201CCFC
	adds	r4, r0, #0
	b	.L0201CD50
.L0201CCFC:
	ldr	r1, .P0201CD68	@ =kVoiceForType
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
	bne	.L0201CD18
	b	.L0201CE44
.L0201CD18:
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
.L0201CD50:
	mov	r0, sp
	ldrb	r0, [r0, #0x11]
	strb	r0, [r4, #0x1b]
	lsls	r0, r0, #0x18
	cmp	r0, #0
	beq	.L0201CD6C
	movs	r7, #0x30
	mov	r0, sp
	ldrb	r0, [r0, #0x10]
	strb	r0, [r4, #0x1c]
	b	.L0201CD76
	.hword 0x0000
.P0201CD68:	.word kVoiceForType
.L0201CD6C:
	mov	r0, sp
	ldrb	r0, [r0, #0x12]
	cmp	r0, #0
	beq	.L0201CD76
	movs	r7, #0x30
.L0201CD76:
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
	bne	.L0201CDA8
	adds	r0, r4, #0
	adds	r0, #0x2c
	movs	r1, #0x14
	bl	MemClear
	b	.L0201CE02
.L0201CDA8:
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
	beq	.L0201CDD6
	ldr	r0, [r4, #0xc]
	subs	r0, r2, r0
	str	r0, [r4, #0x38]
	b	.L0201CDDE
.L0201CDD6:
	ldr	r0, [r4, #0xc]
	subs	r0, r0, r2
	str	r0, [r4, #0x38]
	str	r2, [r4, #0xc]
.L0201CDDE:
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
	beq	.L0201CDFC
	strb	r7, [r5, #0x1e]
	b	.L0201CDFE
.L0201CDFC:
	strb	r0, [r5, #0x1c]
.L0201CDFE:
	movs	r0, #0
	str	r0, [r4, #0x34]
.L0201CE02:
	ldrb	r0, [r4]
	cmp	r0, #0
	bne	.L0201CE18
	ldrh	r0, [r6, #2]
	ldr	r1, [r5, #4]
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r0, [r0]
	adds	r1, r1, r0
	str	r1, [r4, #0x5c]
	b	.L0201CE38
.L0201CE18:
	cmp	r0, #3
	beq	.L0201CE34
	ldrb	r1, [r6, #1]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0201CE2A
	ldr	r0, [sp, #8]
	b	.L0201CE36
.L0201CE2A:
	ldrh	r1, [r6, #2]
	adds	r0, r4, #0
	adds	r0, #0x64
	strb	r1, [r0]
	b	.L0201CE38
.L0201CE34:
	ldr	r0, [sp, #0xc]
.L0201CE36:
	str	r0, [r4, #0x64]
.L0201CE38:
	mov	r0, r8
	cmp	r0, #0
	bne	.L0201CE44
	adds	r0, r4, #0
	bl	noteOff
.L0201CE44:
	add	sp, #0x14
	pop	{r3, r4}
	mov	r8, r3
	mov	sb, r4
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ noteOff   (0201CE54)
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
	bne	.L0201CF2A
	ldr	r0, [r4, #4]
	adds	r0, #0x49
	ldrb	r0, [r0]
	cmp	r0, #0
	bne	.L0201CF2A
	ldrb	r3, [r4]
	cmp	r3, #0
	bne	.L0201CE80
	adds	r0, r4, #0
	bl	voiceUnlink
	movs	r0, #2
	strb	r0, [r4, #1]
	adds	r0, r4, #0
	bl	voiceListInsertActive
	b	.L0201CF12
.L0201CE80:
	ldrh	r2, [r4, #0x10]
	adds	r0, r4, #0
	adds	r0, #0x58
	ldrb	r1, [r0]
	cmp	r3, #3
	bne	.L0201CE90
	movs	r0, #2
	b	.L0201CF10
.L0201CE90:
	lsrs	r1, r1, #5
	cmp	r1, #0
	bne	.L0201CE9A
	movs	r1, #0
	b	.L0201CEA4
.L0201CE9A:
	ldr	r0, [r4, #0x14]
	lsls	r0, r0, #4
	orrs	r1, r0
	lsls	r0, r1, #0x18
	lsrs	r1, r0, #0x18
.L0201CEA4:
	ldrb	r0, [r4]
	cmp	r0, #2
	beq	.L0201CEDC
	cmp	r0, #2
	bgt	.L0201CEB4
	cmp	r0, #1
	beq	.L0201CEBA
	b	.L0201CF0E
.L0201CEB4:
	cmp	r0, #4
	beq	.L0201CF04
	b	.L0201CF0E
.L0201CEBA:
	ldr	r0, .P0201CED0	@ =REG_NR12
	strb	r1, [r0]
	ldr	r1, .P0201CED4	@ =REG_SOUND1CNT_X
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r0, r3, #0
	orrs	r2, r0
	strh	r2, [r1]
	ldr	r2, .P0201CED8	@ =REG_NR11
	b	.L0201CEEE
	.hword 0x0000
.P0201CED0:	.word REG_NR12
.P0201CED4:	.word REG_SOUND1CNT_X
.P0201CED8:	.word REG_NR11
.L0201CEDC:
	ldr	r0, .P0201CEF8	@ =REG_NR22
	strb	r1, [r0]
	ldr	r1, .P0201CEFC	@ =REG_SOUND2CNT_H
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r0, r3, #0
	orrs	r2, r0
	strh	r2, [r1]
	ldr	r2, .P0201CF00	@ =REG_NR21
.L0201CEEE:
	ldrb	r1, [r2]
	movs	r0, #0xc0
	ands	r0, r1
	strb	r0, [r2]
	b	.L0201CF0E
.P0201CEF8:	.word REG_NR22
.P0201CEFC:	.word REG_SOUND2CNT_H
.P0201CF00:	.word REG_NR21
.L0201CF04:
	ldr	r0, .P0201CF30	@ =REG_NR42
	strb	r1, [r0]
	ldr	r1, .P0201CF34	@ =REG_NR44
	movs	r0, #0x80
	strb	r0, [r1]
.L0201CF0E:
	movs	r0, #0
.L0201CF10:
	strb	r0, [r4, #1]
.L0201CF12:
	ldrb	r0, [r4, #0x1b]
	ldr	r1, [r4, #4]
	cmp	r0, #0
	bne	.L0201CF22
	adds	r0, r1, #0
	adds	r0, #0x4b
	ldrb	r0, [r0]
	strb	r0, [r4, #0x1c]
.L0201CF22:
	adds	r0, r1, #0
	adds	r1, r4, #0
	bl	trackRemoveVoice
.L0201CF2A:
	pop	{r4}
	pop	{r0}
	bx	r0
.P0201CF30:	.word REG_NR42
.P0201CF34:	.word REG_NR44

@ ======================================================================================
@ voiceStop   (0201CF38)
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
	beq	.L0201CFC8
	ldrb	r0, [r4]
	cmp	r0, #4
	bhi	.L0201CFBC
	lsls	r0, r0, #2
	ldr	r1, .P0201CF54	@ =0x0201CF58
	adds	r0, r0, r1
	ldr	r0, [r0]
	mov	pc, r0
	.hword 0x0000
.P0201CF54:	.word 0x0201CF58
	.word .L0201CF6C
	.word .L0201CF8C
	.word .L0201CF9C
	.word .L0201CFA4
	.word .L0201CFB0
.L0201CF6C:
	adds	r0, r4, #0
	bl	voiceUnlink
	ldr	r0, .P0201CF88	@ =gLastWave
	movs	r1, #0xb0
	lsls	r1, r1, #1
	adds	r2, r0, r1
	ldr	r1, [r2]
	str	r1, [r4, #0x6c]
	adds	r0, #0xf4
	str	r0, [r4, #0x68]
	str	r4, [r1, #0x68]
	str	r4, [r2]
	b	.L0201CFBC
.P0201CF88:	.word gLastWave
.L0201CF8C:
	ldr	r1, .P0201CF98	@ =REG_NR12
	movs	r0, #8
	strb	r0, [r1]
	adds	r1, #2
	b	.L0201CFB8
	.hword 0x0000
.P0201CF98:	.word REG_NR12
.L0201CF9C:
	ldr	r1, .P0201CFA0	@ =REG_NR22
	b	.L0201CFB2
.P0201CFA0:	.word REG_NR22
.L0201CFA4:
	ldr	r1, .P0201CFAC	@ =REG_NR30
	movs	r0, #0
	b	.L0201CFBA
	.hword 0x0000
.P0201CFAC:	.word REG_NR30
.L0201CFB0:
	ldr	r1, .P0201CFD0	@ =REG_NR42
.L0201CFB2:
	movs	r0, #8
	strb	r0, [r1]
	adds	r1, #4
.L0201CFB8:
	movs	r0, #0xc0
.L0201CFBA:
	strb	r0, [r1]
.L0201CFBC:
	ldr	r0, [r4, #4]
	adds	r1, r4, #0
	bl	trackRemoveVoice
	movs	r0, #0
	strb	r0, [r4, #1]
.L0201CFC8:
	pop	{r4}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201CFD0:	.word REG_NR42

@ ======================================================================================
@ psgKeyOn   (0201CFD4)
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
	beq	.L0201D058
	cmp	r3, #2
	bgt	.L0201CFEC
	cmp	r3, #1
	beq	.L0201CFF6
	b	.L0201D124
.L0201CFEC:
	cmp	r3, #3
	beq	.L0201D084
	cmp	r3, #4
	beq	.L0201D0D8
	b	.L0201D124
.L0201CFF6:
	ldr	r1, .P0201D024	@ =REG_NR10
	ldr	r0, [r4, #0x54]
	ldrb	r0, [r0, #8]
	strb	r0, [r1]
	ldr	r2, .P0201D028	@ =REG_SOUND1CNT_X
	ldr	r0, [r4, #0xc]
	movs	r6, #0x80
	lsls	r6, r6, #8
	adds	r1, r6, #0
	orrs	r0, r1
	strh	r0, [r2]
	ldr	r0, .P0201D02C	@ =REG_NR12
	strb	r5, [r0]
	ldr	r0, [r4, #0x54]
	ldrb	r0, [r0, #1]
	ands	r3, r0
	cmp	r3, #0
	beq	.L0201D034
	ldr	r1, .P0201D030	@ =REG_NR11
	ldr	r0, [r4, #0x64]
	ldrb	r0, [r0, #2]
	b	.L0201D03C
	.hword 0x0000
.P0201D024:	.word REG_NR10
.P0201D028:	.word REG_SOUND1CNT_X
.P0201D02C:	.word REG_NR12
.P0201D030:	.word REG_NR11
.L0201D034:
	ldr	r1, .P0201D050	@ =REG_NR11
	adds	r0, r4, #0
	adds	r0, #0x64
	ldrb	r0, [r0]
.L0201D03C:
	lsls	r0, r0, #6
	strb	r0, [r1]
	ldr	r0, .P0201D054	@ =REG_SOUND1CNT_X
	ldr	r1, [r4, #0xc]
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r2, r3, #0
	orrs	r1, r2
	strh	r1, [r0]
	b	.L0201D124
.P0201D050:	.word REG_NR11
.P0201D054:	.word REG_SOUND1CNT_X
.L0201D058:
	ldr	r0, .P0201D078	@ =REG_NR22
	strb	r5, [r0]
	ldr	r2, .P0201D07C	@ =REG_SOUND2CNT_H
	ldr	r0, [r4, #0xc]
	movs	r6, #0x80
	lsls	r6, r6, #8
	adds	r1, r6, #0
	orrs	r0, r1
	strh	r0, [r2]
	ldr	r1, .P0201D080	@ =REG_NR21
	adds	r0, r4, #0
	adds	r0, #0x64
	ldrb	r0, [r0]
	lsls	r0, r0, #6
	b	.L0201D122
	.hword 0x0000
.P0201D078:	.word REG_NR22
.P0201D07C:	.word REG_SOUND2CNT_H
.P0201D080:	.word REG_NR21
.L0201D084:
	ldr	r6, .P0201D0C4	@ =gLastWave
	ldr	r1, [r4, #0x64]
	ldr	r0, [r6]
	cmp	r1, r0
	beq	.L0201D0A2
	ldr	r1, .P0201D0C8	@ =REG_NR30
	movs	r0, #0
	strb	r0, [r1]
	ldr	r0, [r4, #0x64]
	adds	r1, #0x20
	movs	r2, #8
	bl	CpuSet
	ldr	r0, [r4, #0x64]
	str	r0, [r6]
.L0201D0A2:
	ldr	r1, .P0201D0C8	@ =REG_NR30
	movs	r0, #0xc0
	strb	r0, [r1]
	ldr	r2, .P0201D0CC	@ =REG_SOUND3CNT_X
	ldr	r0, [r4, #0xc]
	movs	r3, #0x80
	lsls	r3, r3, #8
	adds	r1, r3, #0
	orrs	r0, r1
	strh	r0, [r2]
	ldr	r1, .P0201D0D0	@ =REG_NR32
	ldr	r0, .P0201D0D4	@ =kWaveVolume
	adds	r0, r5, r0
	ldrb	r0, [r0]
	strb	r0, [r1]
	subs	r1, #1
	b	.L0201D120
.P0201D0C4:	.word gLastWave
.P0201D0C8:	.word REG_NR30
.P0201D0CC:	.word REG_SOUND3CNT_X
.P0201D0D0:	.word REG_NR32
.P0201D0D4:	.word kWaveVolume
.L0201D0D8:
	ldr	r0, .P0201D0F8	@ =REG_NR42
	strb	r5, [r0]
	ldr	r0, [r4, #0x54]
	ldrb	r1, [r0, #1]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0201D0FC
	ldrh	r0, [r4, #0xc]
	bl	noiseDivider
	lsls	r0, r0, #0x18
	lsrs	r1, r0, #0x18
	ldr	r0, [r4, #0x64]
	ldrb	r0, [r0, #2]
	b	.L0201D10C
.P0201D0F8:	.word REG_NR42
.L0201D0FC:
	ldrh	r0, [r4, #0xc]
	bl	noiseDivider
	lsls	r0, r0, #0x18
	lsrs	r1, r0, #0x18
	adds	r0, r4, #0
	adds	r0, #0x64
	ldrb	r0, [r0]
.L0201D10C:
	cmp	r0, #0
	beq	.L0201D114
	movs	r0, #8
	orrs	r1, r0
.L0201D114:
	ldr	r0, .P0201D12C	@ =REG_NR43
	strb	r1, [r0]
	ldr	r1, .P0201D130	@ =REG_NR44
	movs	r0, #0x80
	strb	r0, [r1]
	subs	r1, #5
.L0201D120:
	movs	r0, #0
.L0201D122:
	strb	r0, [r1]
.L0201D124:
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201D12C:	.word REG_NR43
.P0201D130:	.word REG_NR44

@ ======================================================================================
@ voiceAlloc   (0201D134)
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
	bne	.L0201D192
	ldr	r1, .P0201D15C	@ =gLastWave
	movs	r2, #0xb0
	lsls	r2, r2, #1
	adds	r0, r1, r2
	ldr	r2, [r0]
	movs	r3, #0xb6
	lsls	r3, r3, #1
	adds	r0, r1, r3
	cmp	r2, r0
	beq	.L0201D160
	adds	r4, r2, #0
	b	.L0201D17E
	.hword 0x0000
.P0201D15C:	.word gLastWave
.L0201D160:
	ldr	r2, [r1, #0x70]
	adds	r0, r1, #0
	adds	r0, #0x7c
	cmp	r2, r0
	beq	.L0201D1A8
	ldrb	r0, [r2, #1]
	cmp	r0, #1
	bne	.L0201D176
	ldrb	r0, [r2, #8]
	cmp	r5, r0
	blo	.L0201D1A8
.L0201D176:
	adds	r4, r2, #0
	adds	r0, r4, #0
	bl	voiceStop
.L0201D17E:
	adds	r0, r4, #0
	bl	voiceUnlink
	movs	r0, #1
	strb	r0, [r4, #1]
	strb	r5, [r4, #8]
	adds	r0, r4, #0
	bl	voiceListInsertActive
	b	.L0201D1C2
.L0201D192:
	lsls	r0, r1, #4
	subs	r0, r0, r1
	lsls	r0, r0, #3
	ldr	r1, .P0201D1AC	@ =gDsVoices+0x2D0
	adds	r4, r0, r1
	ldrb	r0, [r4, #1]
	cmp	r0, #1
	bne	.L0201D1B0
	ldrb	r2, [r4, #8]
	cmp	r5, r2
	bhs	.L0201D1B0
.L0201D1A8:
	movs	r0, #0
	b	.L0201D1C4
.P0201D1AC:	.word gDsVoices+0x2D0
.L0201D1B0:
	ldrb	r0, [r4, #1]
	cmp	r0, #0
	beq	.L0201D1BC
	adds	r0, r4, #0
	bl	voiceStop
.L0201D1BC:
	movs	r0, #1
	strb	r0, [r4, #1]
	strb	r5, [r4, #8]
.L0201D1C2:
	adds	r0, r4, #0
.L0201D1C4:
	pop	{r4, r5}
	pop	{r1}
	bx	r1
	movs	r0, r0

@ ======================================================================================
@ mixVoice   (0201D1CC)
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
	ldr	r2, .P0201D238	@ =gMixDry
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
	bne	.L0201D228
	ldr	r7, [r1]
.L0201D228:
	mov	r0, sl
	muls	r0, r6, r0
	adds	r0, r4, r0
	lsrs	r0, r0, #8
	cmp	r0, r7
	bhs	.L0201D23C
	ldr	r5, [sp, #0x18]
	b	.L0201D254
.P0201D238:	.word gMixDry
.L0201D23C:
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
.L0201D254:
	ldr	r1, [sp, #0x10]
	ldr	r0, [r1, #0x5c]
	ldr	r1, [r0, #0xc]
	cmp	r1, #0
	beq	.L0201D264
	mov	r2, r8
	cmp	r2, #0
	bne	.L0201D290
.L0201D264:
	ldr	r0, .P0201D28C	@ =gFnMixVoice
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
	beq	.L0201D33E
	movs	r0, #1
	b	.L0201D344
.P0201D28C:	.word gFnMixVoice
.L0201D290:
	ldr	r0, [r0, #8]
	subs	r1, r1, r0
	lsls	r1, r1, #8
	str	r1, [sp, #0x24]
	ldr	r1, .P0201D2EC	@ =gFnMixVoice
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
	beq	.L0201D33E
.L0201D2CA:
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
	bhs	.L0201D2F0
	mov	r1, sl
	lsls	r0, r1, #1
	adds	r5, r5, r0
	movs	r2, #0
	mov	r8, r2
	b	.L0201D306
.P0201D2EC:	.word gFnMixVoice
.L0201D2F0:
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
.L0201D306:
	str	r4, [sp]
	str	r6, [sp, #4]
	ldr	r1, [sp, #0x1c]
	str	r1, [sp, #8]
	mov	r2, sb
	str	r2, [sp, #0xc]
	ldr	r0, .P0201D354	@ =gFnMixVoice
	ldr	r4, [r0]
	ldr	r0, [sp, #0x20]
	ldr	r1, [sp, #0x14]
	ldr	r2, [sp, #0x18]
	adds	r3, r5, #0
	bl	_call_via_r4
	adds	r4, r0, #0
	mov	r1, r8
	cmp	r1, #0
	beq	.L0201D32E
	ldr	r2, [sp, #0x24]
	subs	r4, r4, r2
.L0201D32E:
	ldr	r1, [sp, #0x14]
	subs	r0, r5, r1
	asrs	r0, r0, #1
	mov	r2, sl
	subs	r2, r2, r0
	mov	sl, r2
	cmp	r2, #0
	bne	.L0201D2CA
.L0201D33E:
	ldr	r0, [sp, #0x10]
	str	r4, [r0, #0x60]
	movs	r0, #0
.L0201D344:
	add	sp, #0x28
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	sb, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1
.P0201D354:	.word gFnMixVoice

@ ======================================================================================
@ kitInstInit   (0201D358)
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
	ldr	r1, .P0201D370	@ =gKitInst
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
.P0201D370:	.word gKitInst

@ ======================================================================================
@ instLookup   (0201D374)
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
	ldr	r1, .P0201D3DC	@ =gCfg
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
	beq	.L0201D424
	adds	r0, r1, #0
	cmp	r0, #0x10
	bne	.L0201D3E0
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
	b	.L0201D428
.P0201D3DC:	.word gCfg
.L0201D3E0:
	cmp	r0, #0x11
	bne	.L0201D408
	ldrh	r1, [r5, #2]
	adds	r1, r3, r1
	ldr	r2, .P0201D400	@ =gKitInst
	lsls	r0, r6, #1
	adds	r0, r0, r1
	ldrh	r0, [r0]
	strh	r0, [r2, #2]
	str	r2, [r4]
	ldr	r0, .P0201D404	@ =kFlatEnvelope
	str	r0, [r4, #4]
	movs	r0, #1
	strb	r0, [r4, #0x12]
	b	.L0201D42C
	.hword 0x0000
.P0201D400:	.word gKitInst
.P0201D404:	.word kFlatEnvelope
.L0201D408:
	cmp	r0, #0x12
	bne	.L0201D42C
	ldrh	r0, [r5, #2]
	adds	r0, r3, r0
	b	.L0201D414
.L0201D412:
	adds	r0, #4
.L0201D414:
	ldrb	r1, [r0]
	cmp	r6, r1
	bhi	.L0201D412
	ldrh	r0, [r0, #2]
	adds	r0, r3, r0
	str	r0, [r4]
	ldrh	r0, [r0, #4]
	b	.L0201D428
.L0201D424:
	str	r5, [r4]
	ldrh	r0, [r5, #4]
.L0201D428:
	adds	r0, r3, r0
	str	r0, [r4, #4]
.L0201D42C:
	ldr	r2, [r4]
	ldrb	r0, [r2]
	cmp	r0, #3
	bne	.L0201D43A
	ldrh	r0, [r5, #2]
	adds	r0, r3, r0
	str	r0, [r4, #0xc]
.L0201D43A:
	ldrb	r1, [r2, #1]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0201D44A
	ldrh	r0, [r2, #2]
	adds	r0, r3, r0
	str	r0, [r4, #8]
.L0201D44A:
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ playerInitAll   (0201D450)
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
	ldr	r4, .P0201D480	@ =gPlayers
	movs	r3, #0
.L0201D458:
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
.L0201D46C:
	str	r3, [r0]
	subs	r0, #4
	subs	r1, #1
	cmp	r1, #0
	bge	.L0201D46C
	cmp	r2, #0x13
	ble	.L0201D458
	pop	{r4}
	pop	{r0}
	bx	r0
.P0201D480:	.word gPlayers

@ ======================================================================================
@ playerReset   (0201D484)
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
@ playerTickAll   (0201D4BC)
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
.L0201D4C2:
	lsls	r0, r6, #4
	adds	r0, r0, r6
	lsls	r0, r0, #2
	ldr	r1, .P0201D4EC	@ =gPlayers
	adds	r1, r0, r1
	adds	r0, r1, #0
	adds	r0, #0x41
	ldrb	r0, [r0]
	adds	r7, r6, #1
	cmp	r0, #0
	beq	.L0201D53E
	ldrh	r2, [r1, #0x3a]
	cmp	r2, #0
	bne	.L0201D4F0
	cmp	r0, #2
	bne	.L0201D506
	adds	r0, r6, #0
	bl	playerStop
	b	.L0201D53E
	.hword 0x0000
.P0201D4EC:	.word gPlayers
.L0201D4F0:
	ldrh	r0, [r1, #0x36]
	ldrh	r3, [r1, #0x34]
	adds	r0, r0, r3
	strh	r0, [r1, #0x34]
	subs	r0, r2, #1
	strh	r0, [r1, #0x3a]
	lsls	r0, r0, #0x10
	cmp	r0, #0
	bne	.L0201D506
	ldrh	r0, [r1, #0x38]
	strh	r0, [r1, #0x34]
.L0201D506:
	movs	r2, #0
	adds	r7, r6, #1
	adds	r4, r1, #0
	adds	r4, #8
	movs	r5, #9
.L0201D510:
	ldr	r0, [r4]
	cmp	r0, #0
	beq	.L0201D52C
	str	r2, [sp]
	bl	trackTick
	lsls	r0, r0, #0x18
	ldr	r2, [sp]
	cmp	r0, #0
	bne	.L0201D528
	movs	r2, #1
	b	.L0201D52C
.L0201D528:
	movs	r0, #0
	str	r0, [r4]
.L0201D52C:
	adds	r4, #4
	subs	r5, #1
	cmp	r5, #0
	bge	.L0201D510
	cmp	r2, #0
	bne	.L0201D53E
	adds	r0, r6, #0
	bl	playerStop
.L0201D53E:
	adds	r6, r7, #0
	cmp	r6, #0x13
	ble	.L0201D4C2
	add	sp, #4
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ doPlaySong   (0201D54C)
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
	ldr	r2, .P0201D570	@ =gCfg
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
.P0201D570:	.word gCfg

@ ======================================================================================
@ doPlaySfx   (0201D574)
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
	ldr	r2, .P0201D59C	@ =gCfg
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
.P0201D59C:	.word gCfg

@ ======================================================================================
@ playerStartSong   (0201D5A0)
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
	ldr	r1, .P0201D624	@ =gPlayers
	adds	r5, r0, r1
	adds	r4, r5, #0
	adds	r4, #0x41
	ldrb	r0, [r4]
	cmp	r0, #0
	beq	.L0201D5C6
	adds	r0, r3, #0
	bl	playerStop
.L0201D5C6:
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
	bge	.L0201D612
	adds	r4, r0, #0
.L0201D5EA:
	ldrh	r0, [r4]
	cmp	r0, #0
	beq	.L0201D60A
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
.L0201D60A:
	adds	r4, #2
	adds	r6, #1
	cmp	r6, r7
	blt	.L0201D5EA
.L0201D612:
	movs	r0, #1
	mov	r1, r8
	strb	r0, [r1]
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201D624:	.word gPlayers

@ ======================================================================================
@ playerStartSfx   (0201D628)
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
	ldr	r1, .P0201D690	@ =gPlayers
	adds	r5, r0, r1
	movs	r0, #0x41
	adds	r0, r0, r5
	mov	r8, r0
	ldrb	r0, [r0]
	cmp	r0, #0
	beq	.L0201D654
	adds	r0, r4, #0
	bl	playerStop
.L0201D654:
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
.P0201D690:	.word gPlayers

@ ======================================================================================
@ playerStop   (0201D694)
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
	ldr	r0, .P0201D6CC	@ =gPlayers
	adds	r1, r1, r0
	adds	r2, r1, #0
	adds	r2, #0x41
	ldrb	r0, [r2]
	cmp	r0, #0
	beq	.L0201D6C6
	adds	r7, r2, #0
	movs	r6, #0
	adds	r4, r1, #0
	adds	r4, #8
	movs	r5, #9
.L0201D6B4:
	ldr	r0, [r4]
	bl	trackStop
	stm	r4!, {r6}
	subs	r5, #1
	cmp	r5, #0
	bge	.L0201D6B4
	movs	r0, #0
	strb	r0, [r7]
.L0201D6C6:
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
.P0201D6CC:	.word gPlayers

@ ======================================================================================
@ playerFadeOut   (0201D6D0)
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
	ldr	r0, .P0201D704	@ =gPlayers
	adds	r4, r1, r0
	adds	r2, r4, #0
	adds	r2, #0x41
	ldrb	r0, [r2]
	cmp	r0, #0
	beq	.L0201D6FE
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
.L0201D6FE:
	pop	{r4}
	pop	{r0}
	bx	r0
.P0201D704:	.word gPlayers

@ ======================================================================================
@ playerSetPause   (0201D708)
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
	ldr	r3, .P0201D728	@ =gPlayers
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
.P0201D728:	.word gPlayers

@ ======================================================================================
@ sndGetPlayerState   (0201D72C)
@
@   u32 sndGetPlayerState(u32 pl)       /* 0 idle, 1 playing, 2 fading out (read directly) */
@   {
@       return gPlayers[pl].state;
@   }
@ ======================================================================================
	.global sndGetPlayerState
	.thumb_func
sndGetPlayerState:
	ldr	r2, .P0201D73C	@ =gPlayers
	lsls	r1, r0, #4
	adds	r1, r1, r0
	lsls	r1, r1, #2
	adds	r2, #0x41
	adds	r1, r1, r2
	ldrb	r0, [r1]
	bx	lr
.P0201D73C:	.word gPlayers

@ ======================================================================================
@ trackInitAll   (0201D740)
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
	ldr	r0, .P0201D75C	@ =gTracks
	movs	r1, #0
	adds	r0, #8
	movs	r2, #0x17
.L0201D748:
	strb	r1, [r0]
	strb	r1, [r0, #1]
	strb	r1, [r0, #2]
	strb	r1, [r0, #3]
	adds	r0, #0x54
	subs	r2, #1
	cmp	r2, #0
	bge	.L0201D748
	bx	lr
	.hword 0x0000
.P0201D75C:	.word gTracks

@ ======================================================================================
@ trackAlloc   (0201D760)
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
	ldr	r1, .P0201D770	@ =gTracks
	ldr	r0, .P0201D774	@ =0x0000078C
	adds	r2, r1, r0
.L0201D766:
	ldr	r0, [r1, #8]
	cmp	r0, #0
	bne	.L0201D778
	adds	r0, r1, #0
	b	.L0201D780
.P0201D770:	.word gTracks
.P0201D774:	.word 0x0000078C
.L0201D778:
	adds	r1, #0x54
	cmp	r1, r2
	ble	.L0201D766
	movs	r0, #0
.L0201D780:
	bx	lr
	movs	r0, r0

@ ======================================================================================
@ trackStart   (0201D784)
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
	beq	.L0201D83A
	ldr	r0, [r5, #8]
	cmp	r0, #0
	beq	.L0201D79C
	adds	r0, r5, #0
	bl	trackStop
.L0201D79C:
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
	bne	.L0201D80E
	adds	r1, #2
	movs	r0, #0xc
	strb	r0, [r1]
	subs	r1, #6
	movs	r0, #0x7f
	strb	r0, [r1]
	adds	r0, r5, #0
	adds	r0, #0x53
	strb	r3, [r0]
	b	.L0201D820
.L0201D80E:
	adds	r1, r5, #0
	adds	r1, #0x52
	movs	r0, #3
	strb	r0, [r1]
	adds	r0, r5, #0
	adds	r0, #0x4c
	strb	r2, [r0]
	adds	r0, #7
	strb	r2, [r0]
.L0201D820:
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
.L0201D83A:
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ trackReleaseAll   (0201D840)
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
	beq	.L0201D868
	adds	r1, r4, #0
	adds	r1, #0x49
	ldrb	r6, [r1]
	movs	r0, #0
	strb	r0, [r1]
	ldr	r0, [r4, #0xc]
	adds	r5, r1, #0
	cmp	r0, #0
	beq	.L0201D866
.L0201D85A:
	ldr	r4, [r0, #0x74]
	bl	noteOff
	adds	r0, r4, #0
	cmp	r0, #0
	bne	.L0201D85A
.L0201D866:
	strb	r6, [r5]
.L0201D868:
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ trackStop   (0201D870)
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
	beq	.L0201D880
	bl	trackReleaseAll
	movs	r0, #0
	str	r0, [r4, #8]
.L0201D880:
	pop	{r4}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ trackTick   (0201D888)
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
	beq	.L0201D89C
	ldr	r1, [r5, #8]
	cmp	r1, #0
	bne	.L0201D8A0
.L0201D89C:
	movs	r0, #1
	b	.L0201DCE6
.L0201D8A0:
	mov	r8, r1
	mov	r0, r8
	adds	r0, #0x3c
	ldrb	r1, [r0]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	bne	.L0201D8B2
	b	.L0201DCCC
.L0201D8B2:
	adds	r0, r5, #0
	bl	trackReleaseAll
	b	.L0201DCE4
.L0201D8BA:
	adds	r0, r5, #0
	bl	trackStop
	movs	r0, #2
	b	.L0201DCE6
.L0201D8C4:
	ldr	r2, [r5]
	ldrb	r6, [r2]
	adds	r2, #1
	str	r2, [r5]
	cmp	r6, #0xbf
	bhi	.L0201D94E
	cmp	r6, #0x5f
	bhi	.L0201D8E0
	adds	r0, r5, #0
	adds	r0, #0x44
	ldrh	r4, [r0]
	adds	r0, #4
	ldrb	r2, [r0]
	b	.L0201D906
.L0201D8E0:
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
.L0201D906:
	movs	r0, #0x96
	muls	r4, r0, r4
	ldr	r0, .P0201D930	@ =gHookNote
	ldr	r7, [r0]
	cmp	r7, #0
	beq	.L0201D934
	mov	r0, r8
	adds	r0, #0x43
	ldrb	r1, [r0]
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0201D934
	lsls	r3, r4, #0x10
	lsrs	r3, r3, #0x10
	adds	r0, r5, #0
	adds	r1, r6, #0
	bl	_call_via_r7
	b	.L0201D940
	.hword 0x0000
.P0201D930:	.word gHookNote
.L0201D934:
	lsls	r3, r4, #0x10
	lsrs	r3, r3, #0x10
	adds	r0, r5, #0
	adds	r1, r6, #0
	bl	noteOn
.L0201D940:
	adds	r0, r5, #0
	adds	r0, #0x53
	ldrb	r0, [r0]
	cmp	r0, #1
	beq	.L0201D94C
	b	.L0201DCCC
.L0201D94C:
	b	.L0201D972
.L0201D94E:
	cmp	r6, #0xc0
	bne	.L0201D95A
	adds	r0, r5, #0
	adds	r0, #0x46
	ldrh	r4, [r0]
	b	.L0201D96E
.L0201D95A:
	cmp	r6, #0xc1
	bne	.L0201D97A
	adds	r0, r5, #0
	bl	readVarLen
	lsls	r0, r0, #0x10
	lsrs	r4, r0, #0x10
	adds	r0, r5, #0
	adds	r0, #0x46
	strh	r4, [r0]
.L0201D96E:
	movs	r0, #0x96
	muls	r4, r0, r4
.L0201D972:
	ldr	r0, [r5, #0x34]
	adds	r0, r0, r4
	str	r0, [r5, #0x34]
	b	.L0201DCCC
.L0201D97A:
	movs	r0, #0xf0
	ands	r0, r6
	cmp	r0, #0xd0
	bne	.L0201D9BA
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
	beq	.L0201D9B2
	ldrb	r0, [r3, #1]
	strh	r0, [r5, #0x20]
	adds	r0, r2, #1
	str	r0, [r5]
	b	.L0201D9B4
.L0201D9B2:
	strh	r1, [r5, #0x20]
.L0201D9B4:
	movs	r0, #1
	strb	r0, [r5, #0x1c]
	b	.L0201DCCC
.L0201D9BA:
	adds	r0, r6, #0
	subs	r0, #0xc2
	cmp	r0, #0x3d
	bls	.L0201D9C4
	b	.L0201DCCC
.L0201D9C4:
	lsls	r0, r0, #2
	ldr	r1, .P0201D9D0	@ =0x0201D9D4
	adds	r0, r0, r1
	ldr	r0, [r0]
	mov	pc, r0
	.hword 0x0000
.P0201D9D0:	.word 0x0201D9D4
	.word .L0201DB2A
	.word .L0201DB46
	.word .L0201DB52
	.word .L0201DB9A
	.word .L0201DB9A
	.word .L0201DB36
	.word .L0201DBAE
	.word .L0201DBB8
	.word .L0201DBC2
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DB5E
	.word .L0201DB6A
	.word .L0201DB76
	.word .L0201DB8E
	.word .L0201DBE8
	.word .L0201DBF2
	.word .L0201DC02
	.word .L0201DBFA
	.word .L0201DAE2
	.word .L0201DB82
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DAE8
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DB02
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DC0E
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DCCC
	.word .L0201DACC
.L0201DACC:
	adds	r0, r5, #0
	adds	r0, #0x24
	ldr	r1, [r5, #0x30]
	cmp	r1, r0
	bne	.L0201DAD8
	b	.L0201D8BA
.L0201DAD8:
	subs	r0, r1, #4
	str	r0, [r5, #0x30]
	ldr	r0, [r0]
	str	r0, [r5]
	b	.L0201DCCC
.L0201DAE2:
	movs	r0, #0
	strb	r0, [r5, #0x1c]
	b	.L0201DCCC
.L0201DAE8:
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
	b	.L0201DB20
.L0201DB02:
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
.L0201DB20:
	mov	r0, sp
	ldrh	r0, [r0]
	adds	r1, r1, r0
	str	r1, [r5]
	b	.L0201DCCC
.L0201DB2A:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x42
	strh	r1, [r2]
	b	.L0201DBE2
.L0201DB36:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r0, #1
	str	r0, [r5]
	adds	r0, r5, #0
	bl	trackSetBank
	b	.L0201DCCC
.L0201DB46:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x4b
	strb	r1, [r2]
	b	.L0201DBE2
.L0201DB52:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x52
	strb	r1, [r2]
	b	.L0201DBE2
.L0201DB5E:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x4d
	strb	r1, [r2]
	b	.L0201DBE2
.L0201DB6A:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x4f
	strb	r1, [r2]
	b	.L0201DBE2
.L0201DB76:
	ldr	r0, [r5]
	ldrb	r2, [r0]
	adds	r1, r5, #0
	adds	r1, #0x50
	strb	r2, [r1]
	b	.L0201DBE2
.L0201DB82:
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r2, r5, #0
	adds	r2, #0x51
	strb	r1, [r2]
	b	.L0201DBE2
.L0201DB8E:
	ldr	r0, [r5]
	ldrb	r2, [r0]
	adds	r1, r5, #0
	adds	r1, #0x4c
	strb	r2, [r1]
	b	.L0201DBE2
.L0201DB9A:
	adds	r0, r5, #0
	bl	trackReleaseAll
	movs	r1, #0
	cmp	r6, #0xc5
	bne	.L0201DBA8
	movs	r1, #1
.L0201DBA8:
	adds	r0, r5, #0
	adds	r0, #0x49
	b	.L0201DCCA
.L0201DBAE:
	adds	r1, r5, #0
	adds	r1, #0x53
	movs	r0, #1
	strb	r0, [r1]
	b	.L0201DCCC
.L0201DBB8:
	adds	r1, r5, #0
	adds	r1, #0x53
	movs	r0, #0
	strb	r0, [r1]
	b	.L0201DCCC
.L0201DBC2:
	ldr	r0, .P0201DBDC	@ =gHookCA
	ldr	r2, [r0]
	cmp	r2, #0
	beq	.L0201DBE0
	ldr	r0, [r5]
	ldrb	r1, [r0]
	adds	r0, #1
	str	r0, [r5]
	adds	r0, r5, #0
	bl	_call_via_r2
	b	.L0201DCCC
	.hword 0x0000
.P0201DBDC:	.word gHookCA
.L0201DBE0:
	ldr	r0, [r5]
.L0201DBE2:
	adds	r0, #1
	str	r0, [r5]
	b	.L0201DCCC
.L0201DBE8:
	ldr	r1, [r5]
	ldrb	r0, [r1]
	mov	r3, r8
	strh	r0, [r3, #0x30]
	b	.L0201DC08
.L0201DBF2:
	ldr	r1, [r5]
	ldrb	r0, [r1]
	strh	r0, [r5, #0x10]
	b	.L0201DC08
.L0201DBFA:
	ldr	r1, [r5]
	ldrb	r0, [r1]
	str	r0, [r5, #0x18]
	b	.L0201DC08
.L0201DC02:
	ldr	r1, [r5]
	ldrb	r0, [r1]
	str	r0, [r5, #0x14]
.L0201DC08:
	adds	r1, #1
	str	r1, [r5]
	b	.L0201DCCC
.L0201DC0E:
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
	bne	.L0201DC42
	bl	trackAlloc
	adds	r4, r0, #0
	str	r4, [r6]
	b	.L0201DC48
.L0201DC42:
	adds	r4, r0, #0
	bl	trackStop
.L0201DC48:
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
.L0201DCCA:
	strb	r1, [r0]
.L0201DCCC:
	ldr	r1, [r5, #0x34]
	cmp	r1, #0
	bgt	.L0201DCD4
	b	.L0201D8C4
.L0201DCD4:
	mov	r2, r8
	ldrh	r0, [r2, #0x30]
	subs	r0, r1, r0
	str	r0, [r5, #0x34]
	movs	r3, #0x32
	ldrsh	r1, [r2, r3]
	subs	r0, r0, r1
	str	r0, [r5, #0x34]
.L0201DCE4:
	movs	r0, #0
.L0201DCE6:
	add	sp, #4
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1
	movs	r0, r0

@ ======================================================================================
@ trackAddVoice   (0201DCF4)
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
	bne	.L0201DD0A
	str	r0, [r1, #4]
	str	r2, [r1, #0x70]
	ldr	r2, [r0, #0xc]
	str	r2, [r1, #0x74]
	str	r1, [r0, #0xc]
	cmp	r2, #0
	beq	.L0201DD0A
	str	r1, [r2, #0x70]
.L0201DD0A:
	bx	lr

@ ======================================================================================
@ trackRemoveVoice   (0201DD0C)
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
	beq	.L0201DD32
	movs	r0, #0
	str	r0, [r1, #4]
	ldr	r2, [r1, #0x74]
	cmp	r2, #0
	beq	.L0201DD22
	ldr	r0, [r1, #0x70]
	str	r0, [r2, #0x70]
.L0201DD22:
	ldr	r2, [r1, #0x70]
	cmp	r2, #0
	beq	.L0201DD2E
	ldr	r0, [r1, #0x74]
	str	r0, [r2, #0x74]
	b	.L0201DD32
.L0201DD2E:
	ldr	r0, [r1, #0x74]
	str	r0, [r3, #0xc]
.L0201DD32:
	bx	lr

@ ======================================================================================
@ readVarLen   (0201DD34)
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
	beq	.L0201DD54
	movs	r0, #0x7f
	ands	r1, r0
	lsls	r1, r1, #8
	ldrb	r0, [r2]
	orrs	r1, r0
	adds	r0, r2, #1
	str	r0, [r3]
.L0201DD54:
	adds	r0, r1, #0
	bx	lr

@ ======================================================================================
@ trackSetBank   (0201DD58)
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
	ldr	r0, .P0201DD88	@ =gCfg
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
.P0201DD88:	.word gCfg

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
	ldr	r2, .P0201DDA4	@ =gCmdWrite
	ldr	r0, [r2]
	adds	r0, #0xc
	str	r0, [r2]
	ldr	r1, .P0201DDA8	@ =gCmdEnd
	ldr	r1, [r1]
	cmp	r0, r1
	bne	.L0201DDA0
	ldr	r0, .P0201DDAC	@ =gCmdQueue
	str	r0, [r2]
.L0201DDA0:
	bx	lr
	.hword 0x0000
.P0201DDA4:	.word gCmdWrite
.P0201DDA8:	.word gCmdEnd
.P0201DDAC:	.word gCmdQueue

@ ======================================================================================
@ cmdInit   (0201DDB0)
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
	ldr	r0, .P0201DDD4	@ =gCmdRead
	ldr	r1, .P0201DDD8	@ =gCmdQueue
	str	r1, [r0]
	ldr	r0, .P0201DDDC	@ =gCmdWrite
	str	r1, [r0]
	ldr	r0, .P0201DDE0	@ =gCmdCommitted
	str	r1, [r0]
	ldr	r0, .P0201DDE4	@ =gCmdEnd
	movs	r2, #0x90
	lsls	r2, r2, #2
	adds	r1, r1, r2
	str	r1, [r0]
	ldr	r0, .P0201DDE8	@ =gHookNote
	movs	r1, #0
	str	r1, [r0]
	ldr	r0, .P0201DDEC	@ =gHookCA
	str	r1, [r0]
	bx	lr
.P0201DDD4:	.word gCmdRead
.P0201DDD8:	.word gCmdQueue
.P0201DDDC:	.word gCmdWrite
.P0201DDE0:	.word gCmdCommitted
.P0201DDE4:	.word gCmdEnd
.P0201DDE8:	.word gHookNote
.P0201DDEC:	.word gHookCA

@ ======================================================================================
@ cmdPop   (0201DDF0)
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
	ldr	r3, .P0201DE00	@ =gCmdRead
	ldr	r2, [r3]
	ldr	r0, .P0201DE04	@ =gCmdCommitted
	ldr	r0, [r0]
	cmp	r2, r0
	bne	.L0201DE08
	movs	r0, #0
	b	.L0201DE1C
.P0201DE00:	.word gCmdRead
.P0201DE04:	.word gCmdCommitted
.L0201DE08:
	adds	r0, r2, #0
	adds	r0, #0xc
	str	r0, [r3]
	ldr	r1, .P0201DE20	@ =gCmdEnd
	ldr	r1, [r1]
	cmp	r0, r1
	bne	.L0201DE1A
	ldr	r0, .P0201DE24	@ =gCmdQueue
	str	r0, [r3]
.L0201DE1A:
	adds	r0, r2, #0
.L0201DE1C:
	bx	lr
	.hword 0x0000
.P0201DE20:	.word gCmdEnd
.P0201DE24:	.word gCmdQueue

@ ======================================================================================
@ sndCommit   (0201DE28)
@
@   void sndCommit(void)                /* make the commands queued since the last call visible */
@   {
@       gCmdCommitted = gCmdWrite;      /* no overflow check: 47 queued commands lose 46         */
@   }
@ ======================================================================================
	.global sndCommit
	.thumb_func
sndCommit:
	ldr	r0, .P0201DE34	@ =gCmdCommitted
	ldr	r1, .P0201DE38	@ =gCmdWrite
	ldr	r1, [r1]
	str	r1, [r0]
	bx	lr
	.hword 0x0000
.P0201DE34:	.word gCmdCommitted
.P0201DE38:	.word gCmdWrite

@ ======================================================================================
@ sndPlaySong   (0201DE3C)
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
	ldr	r2, .P0201DE5C	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #0
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201DE5C:	.word gCmdWrite

@ ======================================================================================
@ sndPlaySfx   (0201DE60)
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
	ldr	r3, .P0201DE84	@ =gCmdWrite
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
.P0201DE84:	.word gCmdWrite

@ ======================================================================================
@ sndFadeOut   (0201DE88)
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
	ldr	r2, .P0201DEA8	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #2
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201DEA8:	.word gCmdWrite

@ ======================================================================================
@ sndPause   (0201DEAC)
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
	ldr	r2, .P0201DECC	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #3
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201DECC:	.word gCmdWrite

@ ======================================================================================
@ sndFadeOutMask   (0201DED0)
@
@   void sndFadeOutMask(u32 mask, u32 frames)      { queue(0x200, frames, mask); }
@ ======================================================================================
	.global sndFadeOutMask
	.thumb_func
sndFadeOutMask:
	push	{lr}
	lsls	r1, r1, #0x10
	lsrs	r1, r1, #0x10
	ldr	r2, .P0201DEEC	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #0x80
	lsls	r3, r3, #2
	strh	r3, [r2]
	str	r1, [r2, #4]
	str	r0, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
.P0201DEEC:	.word gCmdWrite

@ ======================================================================================
@ sndPauseMask   (0201DEF0)
@
@   void sndPauseMask(u32 mask, u32 on)            { queue(0x201, on, mask); }
@ ======================================================================================
	.global sndPauseMask
	.thumb_func
sndPauseMask:
	push	{lr}
	lsls	r1, r1, #0x18
	lsrs	r1, r1, #0x18
	ldr	r2, .P0201DF0C	@ =gCmdWrite
	ldr	r2, [r2]
	ldr	r3, .P0201DF10	@ =0x00000201
	strh	r3, [r2]
	str	r1, [r2, #4]
	str	r0, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201DF0C:	.word gCmdWrite
.P0201DF10:	.word 0x00000201

@ ======================================================================================
@ sndSetTempo   (0201DF14)
@
@   void sndSetTempo(u32 pl, s32 ofs)              { queue(0x004, pl, ofs); }   /* tempo offset   */
@ ======================================================================================
	.global sndSetTempo
	.thumb_func
sndSetTempo:
	push	{lr}
	lsls	r0, r0, #0x10
	lsrs	r0, r0, #0x10
	ldr	r2, .P0201DF34	@ =gCmdWrite
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
.P0201DF34:	.word gCmdWrite

@ ======================================================================================
@ sndSetVolume2   (0201DF38)
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
	ldr	r2, .P0201DF58	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #5
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201DF58:	.word gCmdWrite

@ ======================================================================================
@ sndSetHookFlags   (0201DF5C)
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
	ldr	r2, .P0201DF7C	@ =gCmdWrite
	ldr	r2, [r2]
	movs	r3, #6
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201DF7C:	.word gCmdWrite

@ ======================================================================================
@ sndMuteTracks   (0201DF80)
@
@   void sndMuteTracks(u32 pl, u32 mask, u32 on)   { queue(0x100, pl << 16 | on, mask); }
@ ======================================================================================
	.global sndMuteTracks
	.thumb_func
sndMuteTracks:
	push	{r4, lr}
	lsls	r2, r2, #0x18
	lsrs	r2, r2, #0x18
	ldr	r3, .P0201DFA4	@ =gCmdWrite
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
.P0201DFA4:	.word gCmdWrite

@ ======================================================================================
@ sndSetTrackExpr   (0201DFA8)
@
@   void sndSetTrackExpr(u32 pl, u32 mask, u32 v)  { queue(0x102, pl << 16 | v, mask); }
@ ======================================================================================
	.global sndSetTrackExpr
	.thumb_func
sndSetTrackExpr:
	push	{r4, lr}
	lsls	r2, r2, #0x18
	lsrs	r2, r2, #0x18
	ldr	r3, .P0201DFCC	@ =gCmdWrite
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
.P0201DFCC:	.word gCmdWrite

@ ======================================================================================
@ sndSetTrackPan   (0201DFD0)
@
@   void sndSetTrackPan(u32 pl, u32 mask, u32 pan) { queue(0x101, pl << 16 | pan, mask); }
@ ======================================================================================
	.global sndSetTrackPan
	.thumb_func
sndSetTrackPan:
	push	{r4, lr}
	lsls	r2, r2, #0x18
	lsrs	r2, r2, #0x18
	ldr	r3, .P0201DFF0	@ =gCmdWrite
	ldr	r4, [r3]
	ldr	r3, .P0201DFF4	@ =0x00000101
	strh	r3, [r4]
	lsls	r0, r0, #0x10
	orrs	r0, r2
	str	r0, [r4, #4]
	str	r1, [r4, #8]
	bl	cmdNext
	pop	{r4}
	pop	{r0}
	bx	r0
.P0201DFF0:	.word gCmdWrite
.P0201DFF4:	.word 0x00000101

@ ======================================================================================
@ sndSetEcho   (0201DFF8)
@
@   void sndSetEcho(u32 shift)                     { queue(0x300, shift); }     /* 16 = off       */
@ ======================================================================================
	.global sndSetEcho
	.thumb_func
sndSetEcho:
	push	{lr}
	lsls	r0, r0, #0x18
	lsrs	r0, r0, #0x18
	ldr	r1, .P0201E014	@ =gCmdWrite
	ldr	r2, [r1]
	movs	r1, #0xc0
	lsls	r1, r1, #2
	strh	r1, [r2]
	str	r0, [r2, #4]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201E014:	.word gCmdWrite

@ ======================================================================================
@ sndCallback   (0201E018)
@
@   void sndCallback(void (*fn)(u32), u32 arg)     { queue(0x301, fn, arg); }   /* run fn(arg) in sndMain */
@ ======================================================================================
	.global sndCallback
	.thumb_func
sndCallback:
	push	{lr}
	ldr	r2, .P0201E030	@ =gCmdWrite
	ldr	r2, [r2]
	ldr	r3, .P0201E034	@ =0x00000301
	strh	r3, [r2]
	str	r0, [r2, #4]
	str	r1, [r2, #8]
	bl	cmdNext
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201E030:	.word gCmdWrite
.P0201E034:	.word 0x00000301

@ ======================================================================================
@ sndSetHookCA   (0201E038)
@
@   void sndSetHookCA(void *fn)                    { queue(0x302, fn); }
@ ======================================================================================
	.global sndSetHookCA
	.thumb_func
sndSetHookCA:
	push	{lr}
	ldr	r1, .P0201E04C	@ =gCmdWrite
	ldr	r2, [r1]
	ldr	r1, .P0201E050	@ =0x00000302
	strh	r1, [r2]
	str	r0, [r2, #4]
	bl	cmdNext
	pop	{r0}
	bx	r0
.P0201E04C:	.word gCmdWrite
.P0201E050:	.word 0x00000302

@ ======================================================================================
@ sndSetHookNote   (0201E054)
@
@   void sndSetHookNote(void *fn)                  { queue(0x303, fn); }
@ ======================================================================================
	.global sndSetHookNote
	.thumb_func
sndSetHookNote:
	push	{lr}
	ldr	r1, .P0201E068	@ =gCmdWrite
	ldr	r2, [r1]
	ldr	r1, .P0201E06C	@ =0x00000303
	strh	r1, [r2]
	str	r0, [r2, #4]
	bl	cmdNext
	pop	{r0}
	bx	r0
.P0201E068:	.word gCmdWrite
.P0201E06C:	.word 0x00000303

@ ======================================================================================
@ cmdPlayer   (0201E070)
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
	ldr	r0, .P0201E090	@ =gPlayers
	adds	r2, r1, r0
	ldrh	r0, [r3]
	cmp	r0, #6
	bhi	.L0201E0FE
	lsls	r0, r0, #2
	ldr	r1, .P0201E094	@ =0x0201E098
	adds	r0, r0, r1
	ldr	r0, [r0]
	mov	pc, r0
.P0201E090:	.word gPlayers
.P0201E094:	.word 0x0201E098
	.word .L0201E0B4
	.word .L0201E0BE
	.word .L0201E0D4
	.word .L0201E0DE
	.word .L0201E0F0
	.word .L0201E0F6
	.word .L0201E0E8
.L0201E0B4:
	ldr	r0, [r3, #4]
	ldr	r1, [r3, #8]
	bl	doPlaySong
	b	.L0201E0FE
.L0201E0BE:
	ldr	r1, [r3, #4]
	lsrs	r0, r1, #0x10
	ldr	r2, .P0201E0D0	@ =0x0000FFFF
	ands	r1, r2
	ldr	r2, [r3, #8]
	bl	doPlaySfx
	b	.L0201E0FE
	.hword 0x0000
.P0201E0D0:	.word 0x0000FFFF
.L0201E0D4:
	ldr	r0, [r3, #4]
	ldr	r1, [r3, #8]
	bl	playerFadeOut
	b	.L0201E0FE
.L0201E0DE:
	ldr	r0, [r3, #4]
	ldrb	r1, [r3, #8]
	bl	playerSetPause
	b	.L0201E0FE
.L0201E0E8:
	ldr	r1, [r3, #8]
	adds	r0, r2, #0
	adds	r0, #0x43
	b	.L0201E0FC
.L0201E0F0:
	ldr	r0, [r3, #8]
	strh	r0, [r2, #0x32]
	b	.L0201E0FE
.L0201E0F6:
	ldr	r1, [r3, #8]
	adds	r0, r2, #0
	adds	r0, #0x40
.L0201E0FC:
	strb	r1, [r0]
.L0201E0FE:
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ cmdTrack   (0201E104)
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
	ldr	r0, .P0201E12C	@ =gPlayers
	adds	r1, r1, r0
	movs	r4, #0
	ldrh	r3, [r2]
	ldr	r0, .P0201E130	@ =0x00000101
	cmp	r3, r0
	beq	.L0201E1A2
	cmp	r3, r0
	bgt	.L0201E134
	subs	r0, #1
	cmp	r3, r0
	beq	.L0201E13E
	b	.L0201E1D2
	.hword 0x0000
.P0201E12C:	.word gPlayers
.P0201E130:	.word 0x00000101
.L0201E134:
	movs	r0, #0x81
	lsls	r0, r0, #1
	cmp	r3, r0
	beq	.L0201E170
	b	.L0201E1D2
.L0201E13E:
	ldr	r0, [r2, #8]
	cmp	r0, #0
	beq	.L0201E1D2
	movs	r5, #1
	adds	r3, r1, #0
	adds	r3, #8
.L0201E14A:
	ands	r0, r5
	cmp	r0, #0
	beq	.L0201E15C
	ldr	r0, [r3]
	cmp	r0, #0
	beq	.L0201E15C
	ldr	r1, [r2, #4]
	adds	r0, #0x4a
	strb	r1, [r0]
.L0201E15C:
	adds	r3, #4
	adds	r4, #1
	ldr	r0, [r2, #8]
	lsrs	r0, r0, #1
	str	r0, [r2, #8]
	cmp	r0, #0
	beq	.L0201E1D2
	cmp	r4, #9
	ble	.L0201E14A
	b	.L0201E1D2
.L0201E170:
	ldr	r0, [r2, #8]
	cmp	r0, #0
	beq	.L0201E1D2
	movs	r5, #1
	adds	r3, r1, #0
	adds	r3, #8
.L0201E17C:
	ands	r0, r5
	cmp	r0, #0
	beq	.L0201E18E
	ldr	r0, [r3]
	cmp	r0, #0
	beq	.L0201E18E
	ldr	r1, [r2, #4]
	adds	r0, #0x4e
	strb	r1, [r0]
.L0201E18E:
	adds	r3, #4
	adds	r4, #1
	ldr	r0, [r2, #8]
	lsrs	r0, r0, #1
	str	r0, [r2, #8]
	cmp	r0, #0
	beq	.L0201E1D2
	cmp	r4, #9
	ble	.L0201E17C
	b	.L0201E1D2
.L0201E1A2:
	ldr	r0, [r2, #8]
	cmp	r0, #0
	beq	.L0201E1D2
	movs	r5, #1
	adds	r3, r1, #0
	adds	r3, #8
.L0201E1AE:
	ands	r0, r5
	cmp	r0, #0
	beq	.L0201E1C0
	ldr	r0, [r3]
	cmp	r0, #0
	beq	.L0201E1C0
	ldr	r1, [r2, #4]
	adds	r0, #0x4b
	strb	r1, [r0]
.L0201E1C0:
	adds	r3, #4
	adds	r4, #1
	ldr	r0, [r2, #8]
	lsrs	r0, r0, #1
	str	r0, [r2, #8]
	cmp	r0, #0
	beq	.L0201E1D2
	cmp	r4, #9
	ble	.L0201E1AE
.L0201E1D2:
	pop	{r4, r5}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ cmdMask   (0201E1D8)
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
	beq	.L0201E1F0
	adds	r0, #1
	cmp	r1, r0
	beq	.L0201E21A
	b	.L0201E242
.L0201E1F0:
	ldr	r1, [r4, #8]
	cmp	r1, #0
	beq	.L0201E242
.L0201E1F6:
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0201E206
	ldr	r1, [r4, #4]
	adds	r0, r5, #0
	bl	playerFadeOut
.L0201E206:
	adds	r5, #1
	ldr	r0, [r4, #8]
	lsrs	r0, r0, #1
	str	r0, [r4, #8]
	adds	r1, r0, #0
	cmp	r1, #0
	beq	.L0201E242
	cmp	r5, #0x13
	ble	.L0201E1F6
	b	.L0201E242
.L0201E21A:
	ldr	r1, [r4, #8]
	cmp	r1, #0
	beq	.L0201E242
.L0201E220:
	movs	r0, #1
	ands	r0, r1
	cmp	r0, #0
	beq	.L0201E230
	ldrb	r1, [r4, #4]
	adds	r0, r5, #0
	bl	playerSetPause
.L0201E230:
	adds	r5, #1
	ldr	r0, [r4, #8]
	lsrs	r0, r0, #1
	str	r0, [r4, #8]
	adds	r1, r0, #0
	cmp	r1, #0
	beq	.L0201E242
	cmp	r5, #0x13
	ble	.L0201E220
.L0201E242:
	pop	{r4, r5}
	pop	{r0}
	bx	r0

@ ======================================================================================
@ cmdGlobal   (0201E248)
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
	ldr	r0, .P0201E260	@ =0x00000301
	cmp	r1, r0
	beq	.L0201E278
	cmp	r1, r0
	bgt	.L0201E264
	subs	r0, #1
	cmp	r1, r0
	beq	.L0201E298
	b	.L0201E29E
.P0201E260:	.word 0x00000301
.L0201E264:
	ldr	r0, .P0201E274	@ =0x00000302
	cmp	r1, r0
	beq	.L0201E282
	adds	r0, #1
	cmp	r1, r0
	beq	.L0201E28C
	b	.L0201E29E
	.hword 0x0000
.P0201E274:	.word 0x00000302
.L0201E278:
	ldr	r0, [r2, #8]
	ldr	r1, [r2, #4]
	bl	_call_via_r1
	b	.L0201E29E
.L0201E282:
	ldr	r1, .P0201E288	@ =gHookCA
	b	.L0201E28E
	.hword 0x0000
.P0201E288:	.word gHookCA
.L0201E28C:
	ldr	r1, .P0201E294	@ =gHookNote
.L0201E28E:
	ldr	r0, [r2, #4]
	str	r0, [r1]
	b	.L0201E29E
.P0201E294:	.word gHookNote
.L0201E298:
	ldrb	r0, [r2, #4]
	bl	echoSetFeedback
.L0201E29E:
	pop	{r0}
	bx	r0
	movs	r0, r0

@ ======================================================================================
@ cmdProcess   (0201E2A4)
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
	beq	.L0201E2CC
	ldr	r4, .P0201E2D4	@ =kCmdHandlers
.L0201E2B2:
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
	bne	.L0201E2B2
.L0201E2CC:
	pop	{r4}
	pop	{r0}
	bx	r0
	.hword 0x0000
.P0201E2D4:	.word kCmdHandlers
	.arm

@ ======================================================================================
@ armDownmix   (0201E2D8)
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
.L0201E2E8:
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
	bne	.L0201E2E8
	pop	{r4, r5}
	bx	lr

@ ======================================================================================
@ armMixVoice   (0201E398)
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
	bne	.L0201E478
.L0201E3B4:
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
	blo	.L0201E3B4
	mov	r0, r4
	pop	{r4, r5, r6, r7, r8, sb}
	bx	lr
.L0201E478:
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
	blo	.L0201E478
	mov	r0, r4
	pop	{r4, r5, r6, r7, r8, sb}
	bx	lr

@ ======================================================================================
@ armEcho   (0201E4B8)
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
.L0201E4C8:
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
	blo	.L0201E4C8
	pop	{r4, r5}
	bx	lr
