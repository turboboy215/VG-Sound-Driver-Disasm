@ ============================================================================
@ gbamod1_player.s -- GBAModPlay version 1 (module id "GBAMOD1."), Thumb part
@ Logik State; the game's credits say "MUSIC REPLAY LICENSED FROM LOGIK STATE".
@
@ Reconstructed from "Pinball Challenge Deluxe (E).gba", ROM range 0x08004234-0x0800519C
@ (3 944 bytes).  Rebuilt byte for byte by gbamod1.mk.
@
@ GCC-compiled Thumb built into the game image (globals in EWRAM, some with .data initial
@ values).  Four music channels and two SFX channels, 21024 Hz, mono mix into two 352-byte
@ buffers.  The ARM mixers are in gbamod1_arm.s; the DMA start and SOUNDCNT_X helpers are game
@ code (0x0800DD60-0x0800DDDC, documented in the reference).
@ ============================================================================
	.syntax unified
	.cpu arm7tdmi
@ ---- hardware registers
	.equ	REG_DISPCNT, 0x04000000
	.equ	REG_VCOUNT, 0x04000006
	.equ	REG_SOUNDCNT_L, 0x04000080
	.equ	REG_SOUNDCNT_H, 0x04000082
	.equ	REG_SOUNDCNT_X, 0x04000084
	.equ	REG_SOUNDBIAS, 0x04000088
	.equ	REG_FIFO_A, 0x040000A0
	.equ	REG_FIFO_B, 0x040000A4
	.equ	REG_DMA1SAD, 0x040000BC
	.equ	REG_DMA1DAD, 0x040000C0
	.equ	REG_DMA1CNT, 0x040000C4
	.equ	REG_DMA1CNT_H, 0x040000C6
	.equ	REG_DMA2SAD, 0x040000C8
	.equ	REG_DMA2DAD, 0x040000CC
	.equ	REG_DMA2CNT, 0x040000D0
	.equ	REG_DMA2CNT_H, 0x040000D2
	.equ	REG_DMA3SAD, 0x040000D4
	.equ	REG_DMA3DAD, 0x040000D8
	.equ	REG_DMA3CNT, 0x040000DC
	.equ	REG_DMA3CNT_H, 0x040000DE
	.equ	REG_TM0CNT_L, 0x04000100
	.equ	REG_TM0CNT_H, 0x04000102
	.equ	REG_TM1CNT_L, 0x04000104
	.equ	REG_TM1CNT_H, 0x04000106
	.equ	REG_IE, 0x04000200
	.equ	REG_IF, 0x04000202
	.equ	REG_WAITCNT, 0x04000204
	.equ	REG_IME, 0x04000208
@ ---- player globals (EWRAM) and other symbols
	.equ	gmpMixing, 0x020006C0                 @ u8 1 while the ARM mixer runs
	.equ	gmpQueuedSaved, 0x020006C4
	.equ	gmpQueued, 0x020006C8                 @ order change waiting for a row
	.equ	gmpQueuedPri, 0x020006CC              @ never read
	.equ	gmpQueuedOrder, 0x020006D0
	.equ	gmpQueuedLoopStart, 0x020006D4
	.equ	gmpQueuedLoopEnd, 0x020006D8
	.equ	gmpSkipSaved, 0x020006DC
	.equ	gmpSkip, 0x020006E0                   @ next Bxx goes to the next order
	.equ	gmpPaused, 0x020006E4
	.equ	gmpPauseAfterJingleFlag, 0x020006E8
	.equ	gmpPortaScale, 0x020006EC             @ 1xx/2xx step multiplier (.data: 4)
	.equ	gmpTonePortaScale, 0x020006F0         @ 3xx step multiplier (.data: 40)
	.equ	gmpJingleOn, 0x020006F4               @ u8
	.equ	gmpJinglePri, 0x020006F6              @ s16
	.equ	gmpPriSaved, 0x020006F8               @ u16
	.equ	gmpRate, 0x020006FC                   @ mix rate from the module (21024)
	.equ	gmpTick, 0x02000700                   @ u16
	.equ	gmpArpTick, 0x02000702                @ u16
	.equ	gmpReturnLoopStart, 0x02000704        @ u16
	.equ	gmpReturnLoopEnd, 0x02000706          @ u16
	.equ	gmpLoopStart, 0x02000708              @ u16 first order of the loop range
	.equ	gmpLoopEnd, 0x0200070A                @ s16 last order, -1 = no range
	.equ	gmpMasterVol, 0x0200070C              @ (.data: 64)
	.equ	gmpMusicVol, 0x02000710
	.equ	gmpSfxVol, 0x02000714
	.equ	gmpJumped, 0x02000718                 @ u8
	.equ	gameMusicVol, 0x02000434              @ game option, copied by gmpStartSong
	.equ	gameSfxVol, 0x02000438                @ game option
	.equ	gmpMixerCode, 0x020029E0              @ -> EWRAM copy of gmpMixChannelUnrolled (0xA00 bytes)
	.equ	gmpMixerCode2, 0x020029E4             @ -> EWRAM copy of gmpMixChannelNoVol (unused)
	.equ	gmpBuf, 0x020029E8                    @ u32[2] mix buffers (352 bytes each)
	.equ	gmpSpare, 0x020029F0                  @ 0x2C0-byte block, never used
	.equ	gmpPatRows, 0x020029F4                @ -> module+0x6B0, u8 rows per pattern
	.equ	gmpPlayer, 0x02002A00                 @ GmpPlayer {module; patPtr[64]; smpPtr[31]}
	.equ	gmpStepTab, 0x02002B80                @ -> module+0x18
	.equ	gmpOrder, 0x02002B84                  @ u16
	.equ	gmpCell, 0x02002B88                   @ u16 row * 4
	.equ	gmpRowLen, 0x02002B8C
	.equ	gmpRowLeft, 0x02002B90
	.equ	gmpTickLen, 0x02002B94
	.equ	gmpTickLeft, 0x02002B98
	.equ	gmpChan, 0x02002BA0                   @ GmpChannel[6] (0x3C): 4 music + 2 SFX
	.equ	gmpReturnOrder, 0x02002D08            @ u16
	.equ	gmpBufFree, 0x02002D10                @ u32[2]
	.equ	gmpCur, 0x02002D18
	.equ	gmpVibratoSine, 0x083C27C8            @ s16[64]
	.equ	gmpCallR3, 0x080CE0C0                 @ bx r3
	.equ	gmpMixChannelUnrolled, 0x080CE184     @ ARM, copied to EWRAM
	.equ	gmpMixChannelNoVol, 0x080CE414        @ ARM, copied to EWRAM, unused
	.equ	malloc, 0x0800D8D8                    @ game allocator
	.equ	hostSoundOff, 0x0800DDC4              @ game: SOUNDCNT_X = 0
	.equ	hostSoundOn, 0x0800DDD0               @ game: SOUNDCNT_X = 0x80
	.equ	memcpy, 0x083C0094                    @ libc
	.equ	memset, 0x083C00F8                    @ libc
	.equ	__divsi3, 0x083C022C                  @ libgcc
	.equ	__udivsi3, 0x083C02C4                 @ libgcc
@ ---- GmpChannel (0x3C bytes, gmpChan[6])
	.equ	CH_ptr, 0x0
	.equ	CH_pos, 0x4                           @ 20.12
	.equ	CH_step, 0x8                          @ 20.12
	.equ	CH_end, 0xC                           @ u16; 2 = stopped
	.equ	CH_loopStart, 0xE                     @ u16
	.equ	CH_loopLen, 0x10                      @ u16
	.equ	CH_vol, 0x14
	.equ	CH_ins, 0x18                          @ u16
	.equ	CH_fine, 0x1C                         @ u16
	.equ	CH_note, 0x1E                         @ u16 step-table index
	.equ	CH_tickFx, 0x20                       @ -1 none
	.equ	CH_vsUp, 0x24                         @ u16
	.equ	CH_vsDown, 0x26                       @ u16
	.equ	CH_arpX, 0x28                         @ u16 x
	.equ	CH_arpY, 0x2A                         @ u16 y
	.equ	CH_vibOfs, 0x2C                       @ s16
	.equ	CH_vibDepth, 0x2E                     @ u16
	.equ	CH_vibSpeed, 0x30                     @ u16
	.equ	CH_vibPos, 0x32                       @ u16
	.equ	CH_portaOfs, 0x34                     @ s16 step offset
	.equ	CH_tpSpeed, 0x36                      @ u16
	.equ	CH_portaStep, 0x38                    @ s16
	.equ	CH_tpTarget, 0x3A                     @ u16

	.section .text.gmp1_player, "ax", %progbits
	.balign 4
@ --------------------------------------------------------------------------
@ gmpInit()  (0x08004234)
@   gmpMixerCode = malloc(0xA00); gmpMixerCode2 = malloc(0xA00); gmpBuf[0..1] = malloc(352);
@   gmpSpare = malloc(0x2C0); gmpCopyMixers()        (Pinball: 0x080075C2, at boot)
@ --------------------------------------------------------------------------
	.thumb
	.thumb_func
	.global gmpInit
gmpInit:
	push	{r4, r5, lr}                          @ 08004234
	ldr	r5, .Llit0800427C                      @ 08004236  =gmpMixerCode
	movs	r4, #0xa0                             @ 08004238
	lsls	r4, r4, #4                            @ 0800423A
	adds	r0, r4, #0                            @ 0800423C
	bl	malloc                                  @ 0800423E
	str	r0, [r5]                               @ 08004242  gmpMixerCode
	ldr	r5, .Llit08004280                      @ 08004244  =gmpMixerCode2
	adds	r0, r4, #0                            @ 08004246
	bl	malloc                                  @ 08004248
	str	r0, [r5]                               @ 0800424C  gmpMixerCode2
	movs	r5, #0xb0                             @ 0800424E
	lsls	r5, r5, #1                            @ 08004250
	adds	r0, r5, #0                            @ 08004252
	bl	malloc                                  @ 08004254
	ldr	r4, .Llit08004284                      @ 08004258  =gmpBuf
	str	r0, [r4]                               @ 0800425A  gmpBuf
	adds	r0, r5, #0                            @ 0800425C
	bl	malloc                                  @ 0800425E
	str	r0, [r4, #4]                           @ 08004262
	ldr	r4, .Llit08004288                      @ 08004264  =gmpSpare
	movs	r0, #0xb0                             @ 08004266
	lsls	r0, r0, #2                            @ 08004268
	bl	malloc                                  @ 0800426A
	str	r0, [r4]                               @ 0800426E  gmpSpare
	bl	gmpCopyMixers                           @ 08004270
	pop	{r4, r5}                               @ 08004274
	pop	{r0}                                   @ 08004276
	bx	r0                                      @ 08004278
	.hword	0x0000                              @ 0800427A  (padding)
.Llit0800427C:
	.word	gmpMixerCode                         @ 0800427C
.Llit08004280:
	.word	gmpMixerCode2                        @ 08004280
.Llit08004284:
	.word	gmpBuf                               @ 08004284
.Llit08004288:
	.word	gmpSpare                             @ 08004288
@ --------------------------------------------------------------------------
@ gmpSetupPatterns(player, npat, base)  (0x0800428C)
@   gmpPatRows = module + 0x6B0 (u8 per pattern);
@   patPtr[i] = base + 16 * (sum of rows[j] for j < i) for i < npat, else 0 (64 slots)
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpSetupPatterns
gmpSetupPatterns:
	push	{r4, r5, r6, r7, lr}                  @ 0800428C
	adds	r6, r1, #0                            @ 0800428E
	adds	r5, r2, #0                            @ 08004290
	ldr	r2, .Llit080042B0                      @ 08004292  =gmpPatRows
	ldm	r0!, {r1}                              @ 08004294
	movs	r3, #0xd6                             @ 08004296
	lsls	r3, r3, #3                            @ 08004298
	adds	r1, r1, r3                            @ 0800429A
	str	r1, [r2]                               @ 0800429C  gmpPatRows
	movs	r4, #0                                @ 0800429E
	movs	r3, #0                                @ 080042A0
	movs	r7, #0                                @ 080042A2
	adds	r1, r0, #0                            @ 080042A4
.L080042A6:
	cmp	r3, r6                                 @ 080042A6
	blt	.L080042B4                             @ 080042A8
	str	r7, [r1]                               @ 080042AA
	b	.L080042C4                               @ 080042AC
	.hword	0x0000                              @ 080042AE  (padding)
.Llit080042B0:
	.word	gmpPatRows                           @ 080042B0
.L080042B4:
	lsls	r0, r4, #2                            @ 080042B4
	adds	r0, r5, r0                            @ 080042B6
	str	r0, [r1]                               @ 080042B8
	ldr	r0, [r2]                               @ 080042BA
	adds	r0, r0, r3                            @ 080042BC
	ldrb	r0, [r0]                              @ 080042BE
	lsls	r0, r0, #2                            @ 080042C0
	adds	r4, r4, r0                            @ 080042C2
.L080042C4:
	adds	r1, #4                                @ 080042C4
	adds	r3, #1                                @ 080042C6
	cmp	r3, #0x3f                              @ 080042C8
	ble	.L080042A6                             @ 080042CA
	pop	{r4, r5, r6, r7}                       @ 080042CC
	pop	{r0}                                   @ 080042CE
	bx	r0                                      @ 080042D0
	.hword	0x0000                              @ 080042D2  (padding)
@ --------------------------------------------------------------------------
@ gmpCheckMixers()  (0x080042D4)  -- unused
@   Compares both EWRAM copies with ROM (0xA00 bytes each); returns 1 if either differs.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpCheckMixers
gmpCheckMixers:
	push	{r4, r5, r6, r7, lr}                  @ 080042D4
	movs	r5, #0                                @ 080042D6
	ldr	r4, .Llit08004320                      @ 080042D8  =gmpMixChannelUnrolled
	ldr	r0, .Llit08004324                      @ 080042DA  =gmpMixerCode
	ldr	r2, [r0]                               @ 080042DC  gmpMixerCode
	ldr	r6, .Llit08004328                      @ 080042DE  =gmpMixChannelNoVol
	ldr	r7, .Llit0800432C                      @ 080042E0  =gmpMixerCode2
	movs	r3, #0xa0                             @ 080042E2
	lsls	r3, r3, #4                            @ 080042E4
.L080042E6:
	ldrb	r1, [r2]                              @ 080042E6
	ldrb	r0, [r4]                              @ 080042E8
	adds	r4, #1                                @ 080042EA
	adds	r2, #1                                @ 080042EC
	cmp	r1, r0                                 @ 080042EE
	beq	.L080042F4                             @ 080042F0
	movs	r5, #1                                @ 080042F2
.L080042F4:
	subs	r3, #1                                @ 080042F4
	cmp	r3, #0                                 @ 080042F6
	bne	.L080042E6                             @ 080042F8
	adds	r4, r6, #0                            @ 080042FA
	ldr	r2, [r7]                               @ 080042FC
	movs	r3, #0xa0                             @ 080042FE
	lsls	r3, r3, #4                            @ 08004300
.L08004302:
	ldrb	r1, [r2]                              @ 08004302
	ldrb	r0, [r4]                              @ 08004304
	adds	r4, #1                                @ 08004306
	adds	r2, #1                                @ 08004308
	cmp	r1, r0                                 @ 0800430A
	beq	.L08004310                             @ 0800430C
	movs	r5, #1                                @ 0800430E
.L08004310:
	subs	r3, #1                                @ 08004310
	cmp	r3, #0                                 @ 08004312
	bne	.L08004302                             @ 08004314
	adds	r0, r5, #0                            @ 08004316
	pop	{r4, r5, r6, r7}                       @ 08004318
	pop	{r1}                                   @ 0800431A
	bx	r1                                      @ 0800431C
	.hword	0x0000                              @ 0800431E  (padding)
.Llit08004320:
	.word	gmpMixChannelUnrolled                @ 08004320
.Llit08004324:
	.word	gmpMixerCode                         @ 08004324
.Llit08004328:
	.word	gmpMixChannelNoVol                   @ 08004328
.Llit0800432C:
	.word	gmpMixerCode2                        @ 0800432C
@ --------------------------------------------------------------------------
@ gmpCopyMixers()  (0x08004330)
@   memset + memcpy 0xA00 bytes from gmpMixChannelNoVol and gmpMixChannelUnrolled into the
@   two EWRAM blocks.  The routines are 0x290 (unrolled) and 0x254 (no volume) bytes long, so
@   both copies run on into the code that follows them.  The unrolled mixer's jump table holds absolute ROM addresses,
@   so the copy returns into ROM for the last 1..7 samples of every call.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpCopyMixers
gmpCopyMixers:
	push	{r4, r5, r6, lr}                      @ 08004330
	ldr	r6, .Llit08004370                      @ 08004332  =gmpMixChannelNoVol
	ldr	r0, .Llit08004374                      @ 08004334  =gmpMixerCode2
	ldr	r5, [r0]                               @ 08004336  gmpMixerCode2
	movs	r4, #0xa0                             @ 08004338
	lsls	r4, r4, #4                            @ 0800433A
	adds	r0, r5, #0                            @ 0800433C
	movs	r1, #0                                @ 0800433E
	adds	r2, r4, #0                            @ 08004340
	bl	memset                                  @ 08004342
	adds	r0, r5, #0                            @ 08004346
	adds	r1, r6, #0                            @ 08004348
	adds	r2, r4, #0                            @ 0800434A
	bl	memcpy                                  @ 0800434C
	ldr	r6, .Llit08004378                      @ 08004350  =gmpMixChannelUnrolled
	ldr	r0, .Llit0800437C                      @ 08004352  =gmpMixerCode
	ldr	r5, [r0]                               @ 08004354  gmpMixerCode
	adds	r0, r5, #0                            @ 08004356
	movs	r1, #0                                @ 08004358
	adds	r2, r4, #0                            @ 0800435A
	bl	memset                                  @ 0800435C
	adds	r0, r5, #0                            @ 08004360
	adds	r1, r6, #0                            @ 08004362
	adds	r2, r4, #0                            @ 08004364
	bl	memcpy                                  @ 08004366
	pop	{r4, r5, r6}                           @ 0800436A
	pop	{r0}                                   @ 0800436C
	bx	r0                                      @ 0800436E
.Llit08004370:
	.word	gmpMixChannelNoVol                   @ 08004370
.Llit08004374:
	.word	gmpMixerCode2                        @ 08004374
.Llit08004378:
	.word	gmpMixChannelUnrolled                @ 08004378
.Llit0800437C:
	.word	gmpMixerCode                         @ 0800437C
@ --------------------------------------------------------------------------
@ gmpLoadModule(player, module)  (0x08004380)
@   gmpRate = 0; if (module[0..7] != "GBAMOD1.") return 0;
@   smpPtr[i] = len ? module + 0x730 + module[8] + (sum of earlier lengths) : 0   (31 samples)
@   player->module = module; gmpRate = module[0x10];
@   gmpSetupPatterns(player, module[0x62C], module + 0x730); return 1
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpLoadModule
gmpLoadModule:
	push	{r4, r5, r6, r7, lr}                  @ 08004380
	mov	r7, sb                                 @ 08004382
	mov	r6, r8                                 @ 08004384
	push	{r6, r7}                              @ 08004386
	adds	r6, r0, #0                            @ 08004388
	adds	r2, r1, #0                            @ 0800438A
	ldr	r1, .Llit080043A8                      @ 0800438C  =gmpRate
	movs	r0, #0                                @ 0800438E
	str	r0, [r1]                               @ 08004390  gmpRate
	ldr	r1, [r2]                               @ 08004392
	ldr	r3, [r2, #4]                           @ 08004394
	ldr	r0, .Llit080043AC                      @ 08004396  =0x4D414247
	cmp	r1, r0                                 @ 08004398  "GBAM"
	bne	.L080043A2                             @ 0800439A
	ldr	r0, .Llit080043B0                      @ 0800439C  =0x2E31444F
	cmp	r3, r0                                 @ 0800439E  "OD1."
	beq	.L080043B4                             @ 080043A0
.L080043A2:
	movs	r0, #0                                @ 080043A2
	b	.L08004416                               @ 080043A4
	.hword	0x0000                              @ 080043A6  (padding)
.Llit080043A8:
	.word	gmpRate                              @ 080043A8
.Llit080043AC:
	.word	0x4D414247                           @ 080043AC
.Llit080043B0:
	.word	0x2E31444F                           @ 080043B0
.L080043B4:
	ldr	r1, .Llit080043E8                      @ 080043B4  =0x0000062C
	adds	r0, r2, r1                            @ 080043B6
	ldr	r0, [r0]                               @ 080043B8
	mov	r8, r0                                 @ 080043BA
	movs	r7, #0xe6                             @ 080043BC
	lsls	r7, r7, #3                            @ 080043BE
	adds	r7, r7, r2                            @ 080043C0
	mov	ip, r7                                 @ 080043C2
	movs	r0, #0x97                             @ 080043C4
	lsls	r0, r0, #3                            @ 080043C6
	adds	r1, r2, r0                            @ 080043C8
	ldr	r0, [r2, #8]                           @ 080043CA
	add	r0, ip                                 @ 080043CC
	mov	sb, r0                                 @ 080043CE
	movs	r5, #0                                @ 080043D0
	movs	r7, #0x82                             @ 080043D2
	lsls	r7, r7, #1                            @ 080043D4
	adds	r3, r6, r7                            @ 080043D6
	movs	r4, #0x1e                             @ 080043D8
.L080043DA:
	movs	r7, #0                                @ 080043DA
	ldrsh	r0, [r1, r7]                         @ 080043DC
	cmp	r0, #0                                 @ 080043DE
	bne	.L080043EC                             @ 080043E0
	str	r0, [r3]                               @ 080043E2
	b	.L080043F8                               @ 080043E4
	.hword	0x0000                              @ 080043E6  (padding)
.Llit080043E8:
	.word	0x0000062C                           @ 080043E8
.L080043EC:
	mov	r7, sb                                 @ 080043EC
	adds	r0, r7, r5                            @ 080043EE
	str	r0, [r3]                               @ 080043F0
	movs	r7, #0                                @ 080043F2
	ldrsh	r0, [r1, r7]                         @ 080043F4
	adds	r5, r5, r0                            @ 080043F6
.L080043F8:
	adds	r1, #0xc                              @ 080043F8
	adds	r3, #4                                @ 080043FA
	subs	r4, #1                                @ 080043FC
	cmp	r4, #0                                 @ 080043FE
	bge	.L080043DA                             @ 08004400
	str	r2, [r6]                               @ 08004402
	ldr	r1, .Llit08004424                      @ 08004404  =gmpRate
	ldr	r0, [r2, #0x10]                        @ 08004406
	str	r0, [r1]                               @ 08004408  gmpRate
	adds	r0, r6, #0                            @ 0800440A
	mov	r1, r8                                 @ 0800440C
	mov	r2, ip                                 @ 0800440E
	bl	gmpSetupPatterns                        @ 08004410
	movs	r0, #1                                @ 08004414
.L08004416:
	pop	{r3, r4}                               @ 08004416
	mov	r8, r3                                 @ 08004418
	mov	sb, r4                                 @ 0800441A
	pop	{r4, r5, r6, r7}                       @ 0800441C
	pop	{r1}                                   @ 0800441E
	bx	r1                                      @ 08004420
	.hword	0x0000                              @ 08004422  (padding)
.Llit08004424:
	.word	gmpRate                              @ 08004424
@ --------------------------------------------------------------------------
@ gmpStartSong(order, loopStart, loopEnd)  (0x08004428)
@   if (!gmpRate || order >= songLen) return 0;
@   gmpStepTab = module + 0x18; gmpLoopStart/End = loopStart/End; gmpOrder = order; gmpCell = 0
@   gmpRowLen = rate*6/50; gmpTickLen = rate/50; counters 0; clear 6 channels; gmpJumped = gmpTick = 0
@   gmpMasterVol = 64; gmpMusicVol = gameMusicVol; gmpSfxVol = gameSfxVol; clear both buffers
@   gmpJinglePri = 0; skip and queue flags = 0; return 1
@   Pinball's call at 0x080055CC passes (order, order, -1): no loop range.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpStartSong
gmpStartSong:
	push	{r4, r5, r6, lr}                      @ 08004428
	lsls	r0, r0, #0x10                         @ 0800442A
	lsrs	r4, r0, #0x10                         @ 0800442C
	lsls	r1, r1, #0x10                         @ 0800442E
	lsrs	r5, r1, #0x10                         @ 08004430
	lsls	r2, r2, #0x10                         @ 08004432
	lsrs	r2, r2, #0x10                         @ 08004434
	ldr	r0, .Llit08004450                      @ 08004436  =gmpRate
	ldr	r6, [r0]                               @ 08004438  gmpRate
	cmp	r6, #0                                 @ 0800443A
	beq	.L0800444C                             @ 0800443C
	lsls	r0, r4, #0x10                         @ 0800443E
	asrs	r0, r0, #0x10                         @ 08004440
	ldr	r1, .Llit08004454                      @ 08004442  =gmpPlayer
	ldr	r3, [r1]                               @ 08004444  gmpPlayer
	ldr	r1, [r3, #0x14]                        @ 08004446
	cmp	r0, r1                                 @ 08004448
	blt	.L08004458                             @ 0800444A
.L0800444C:
	movs	r0, #0                                @ 0800444C
	b	.L080044FE                               @ 0800444E
.Llit08004450:
	.word	gmpRate                              @ 08004450
.Llit08004454:
	.word	gmpPlayer                            @ 08004454
.L08004458:
	ldr	r1, .Llit08004504                      @ 08004458  =gmpStepTab
	adds	r0, r3, #0                            @ 0800445A
	adds	r0, #0x18                             @ 0800445C
	str	r0, [r1]                               @ 0800445E  gmpStepTab
	ldr	r0, .Llit08004508                      @ 08004460  =gmpLoopStart
	strh	r5, [r0]                              @ 08004462  gmpLoopStart
	ldr	r0, .Llit0800450C                      @ 08004464  =gmpLoopEnd
	strh	r2, [r0]                              @ 08004466  gmpLoopEnd
	ldr	r0, .Llit08004510                      @ 08004468  =gmpOrder
	strh	r4, [r0]                              @ 0800446A  gmpOrder
	ldr	r1, .Llit08004514                      @ 0800446C  =gmpCell
	movs	r0, #0                                @ 0800446E
	strh	r0, [r1]                              @ 08004470  gmpCell
	ldr	r4, .Llit08004518                      @ 08004472  =gmpRowLen
	lsls	r0, r6, #1                            @ 08004474
	adds	r0, r0, r6                            @ 08004476
	lsls	r0, r0, #1                            @ 08004478
	movs	r1, #0x32                             @ 0800447A
	bl	__udivsi3                               @ 0800447C
	str	r0, [r4]                               @ 08004480  gmpRowLen
	ldr	r0, .Llit0800451C                      @ 08004482  =gmpRowLeft
	movs	r5, #0                                @ 08004484
	str	r5, [r0]                               @ 08004486  gmpRowLeft
	ldr	r4, .Llit08004520                      @ 08004488  =gmpTickLen
	adds	r0, r6, #0                            @ 0800448A
	movs	r1, #0x32                             @ 0800448C
	bl	__udivsi3                               @ 0800448E
	str	r0, [r4]                               @ 08004492  gmpTickLen
	ldr	r0, .Llit08004524                      @ 08004494  =gmpTickLeft
	str	r5, [r0]                               @ 08004496  gmpTickLeft
	ldr	r5, .Llit08004528                      @ 08004498  =gmpChan
	movs	r4, #5                                @ 0800449A
.L0800449C:
	adds	r0, r5, #0                            @ 0800449C
	movs	r1, #0                                @ 0800449E
	movs	r2, #0x3c                             @ 080044A0
	bl	memset                                  @ 080044A2
	adds	r5, #0x3c                             @ 080044A6
	subs	r4, #1                                @ 080044A8
	cmp	r4, #0                                 @ 080044AA
	bge	.L0800449C                             @ 080044AC
	movs	r4, #0                                @ 080044AE
	ldr	r0, .Llit0800452C                      @ 080044B0  =gmpJumped
	strb	r4, [r0]                              @ 080044B2  gmpJumped
	ldr	r0, .Llit08004530                      @ 080044B4  =gmpTick
	strh	r4, [r0]                              @ 080044B6  gmpTick
	ldr	r1, .Llit08004534                      @ 080044B8  =gmpMasterVol
	movs	r0, #0x40                             @ 080044BA
	str	r0, [r1]                               @ 080044BC  gmpMasterVol
	ldr	r1, .Llit08004538                      @ 080044BE  =gmpMusicVol
	ldr	r0, .Llit0800453C                      @ 080044C0  =gameMusicVol
	ldr	r0, [r0]                               @ 080044C2  gameMusicVol
	str	r0, [r1]                               @ 080044C4  gmpMusicVol
	ldr	r1, .Llit08004540                      @ 080044C6  =gmpSfxVol
	ldr	r0, .Llit08004544                      @ 080044C8  =gameSfxVol
	ldr	r0, [r0]                               @ 080044CA  gameSfxVol
	str	r0, [r1]                               @ 080044CC  gmpSfxVol
	ldr	r5, .Llit08004548                      @ 080044CE  =gmpBuf
	ldr	r0, [r5]                               @ 080044D0  gmpBuf
	movs	r6, #0xb0                             @ 080044D2
	lsls	r6, r6, #1                            @ 080044D4
	movs	r1, #0                                @ 080044D6
	adds	r2, r6, #0                            @ 080044D8
	bl	memset                                  @ 080044DA
	ldr	r0, [r5, #4]                           @ 080044DE
	movs	r1, #0                                @ 080044E0
	adds	r2, r6, #0                            @ 080044E2
	bl	memset                                  @ 080044E4
	ldr	r0, .Llit0800454C                      @ 080044E8  =gmpJinglePri
	strh	r4, [r0]                              @ 080044EA  gmpJinglePri
	ldr	r0, .Llit08004550                      @ 080044EC  =gmpSkipSaved
	str	r4, [r0]                               @ 080044EE  gmpSkipSaved
	ldr	r0, .Llit08004554                      @ 080044F0  =gmpSkip
	str	r4, [r0]                               @ 080044F2  gmpSkip
	ldr	r0, .Llit08004558                      @ 080044F4  =gmpQueued
	str	r4, [r0]                               @ 080044F6  gmpQueued
	ldr	r0, .Llit0800455C                      @ 080044F8  =gmpQueuedSaved
	str	r4, [r0]                               @ 080044FA  gmpQueuedSaved
	movs	r0, #1                                @ 080044FC
.L080044FE:
	pop	{r4, r5, r6}                           @ 080044FE
	pop	{r1}                                   @ 08004500
	bx	r1                                      @ 08004502
.Llit08004504:
	.word	gmpStepTab                           @ 08004504
.Llit08004508:
	.word	gmpLoopStart                         @ 08004508
.Llit0800450C:
	.word	gmpLoopEnd                           @ 0800450C
.Llit08004510:
	.word	gmpOrder                             @ 08004510
.Llit08004514:
	.word	gmpCell                              @ 08004514
.Llit08004518:
	.word	gmpRowLen                            @ 08004518
.Llit0800451C:
	.word	gmpRowLeft                           @ 0800451C
.Llit08004520:
	.word	gmpTickLen                           @ 08004520
.Llit08004524:
	.word	gmpTickLeft                          @ 08004524
.Llit08004528:
	.word	gmpChan                              @ 08004528
.Llit0800452C:
	.word	gmpJumped                            @ 0800452C
.Llit08004530:
	.word	gmpTick                              @ 08004530
.Llit08004534:
	.word	gmpMasterVol                         @ 08004534
.Llit08004538:
	.word	gmpMusicVol                          @ 08004538
.Llit0800453C:
	.word	gameMusicVol                         @ 0800453C
.Llit08004540:
	.word	gmpSfxVol                            @ 08004540
.Llit08004544:
	.word	gameSfxVol                           @ 08004544
.Llit08004548:
	.word	gmpBuf                               @ 08004548
.Llit0800454C:
	.word	gmpJinglePri                         @ 0800454C
.Llit08004550:
	.word	gmpSkipSaved                         @ 08004550
.Llit08004554:
	.word	gmpSkip                              @ 08004554
.Llit08004558:
	.word	gmpQueued                            @ 08004558
.Llit0800455C:
	.word	gmpQueuedSaved                       @ 0800455C
@ --------------------------------------------------------------------------
@ gmpJumpSong(order, loopStart, loopEnd)  (0x08004560)
@   Same without the volume/SFX reset: clears the 4 music channels only; tempo back to speed 6.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpJumpSong
gmpJumpSong:
	push	{r4, r5, r6, r7, lr}                  @ 08004560
	lsls	r0, r0, #0x10                         @ 08004562
	lsrs	r4, r0, #0x10                         @ 08004564
	lsls	r1, r1, #0x10                         @ 08004566
	lsrs	r5, r1, #0x10                         @ 08004568
	lsls	r2, r2, #0x10                         @ 0800456A
	lsrs	r2, r2, #0x10                         @ 0800456C
	ldr	r0, .Llit08004608                      @ 0800456E  =gmpRate
	ldr	r7, [r0]                               @ 08004570  gmpRate
	cmp	r7, #0                                 @ 08004572
	beq	.L08004648                             @ 08004574
	lsls	r0, r4, #0x10                         @ 08004576
	asrs	r0, r0, #0x10                         @ 08004578
	ldr	r1, .Llit0800460C                      @ 0800457A  =gmpPlayer
	ldr	r3, [r1]                               @ 0800457C  gmpPlayer
	ldr	r1, [r3, #0x14]                        @ 0800457E
	cmp	r0, r1                                 @ 08004580
	bge	.L08004648                             @ 08004582
	ldr	r1, .Llit08004610                      @ 08004584  =gmpStepTab
	adds	r0, r3, #0                            @ 08004586
	adds	r0, #0x18                             @ 08004588
	str	r0, [r1]                               @ 0800458A  gmpStepTab
	ldr	r0, .Llit08004614                      @ 0800458C  =gmpLoopStart
	strh	r5, [r0]                              @ 0800458E  gmpLoopStart
	ldr	r0, .Llit08004618                      @ 08004590  =gmpLoopEnd
	strh	r2, [r0]                              @ 08004592  gmpLoopEnd
	ldr	r0, .Llit0800461C                      @ 08004594  =gmpOrder
	strh	r4, [r0]                              @ 08004596  gmpOrder
	ldr	r0, .Llit08004620                      @ 08004598  =gmpCell
	movs	r6, #0                                @ 0800459A
	strh	r6, [r0]                              @ 0800459C  gmpCell
	ldr	r4, .Llit08004624                      @ 0800459E  =gmpRowLen
	lsls	r0, r7, #1                            @ 080045A0
	adds	r0, r0, r7                            @ 080045A2
	lsls	r0, r0, #1                            @ 080045A4
	movs	r1, #0x32                             @ 080045A6
	bl	__udivsi3                               @ 080045A8
	str	r0, [r4]                               @ 080045AC  gmpRowLen
	ldr	r0, .Llit08004628                      @ 080045AE  =gmpRowLeft
	movs	r5, #0                                @ 080045B0
	str	r5, [r0]                               @ 080045B2  gmpRowLeft
	ldr	r4, .Llit0800462C                      @ 080045B4  =gmpTickLen
	adds	r0, r7, #0                            @ 080045B6
	movs	r1, #0x32                             @ 080045B8
	bl	__udivsi3                               @ 080045BA
	str	r0, [r4]                               @ 080045BE  gmpTickLen
	ldr	r0, .Llit08004630                      @ 080045C0  =gmpTickLeft
	str	r5, [r0]                               @ 080045C2  gmpTickLeft
	ldr	r4, .Llit08004634                      @ 080045C4  =gmpChan
	adds	r0, r4, #0                            @ 080045C6
	movs	r1, #0                                @ 080045C8
	movs	r2, #0x3c                             @ 080045CA
	bl	memset                                  @ 080045CC
	adds	r0, r4, #0                            @ 080045D0
	adds	r0, #0x3c                             @ 080045D2
	movs	r1, #0                                @ 080045D4
	movs	r2, #0x3c                             @ 080045D6
	bl	memset                                  @ 080045D8
	adds	r0, r4, #0                            @ 080045DC
	adds	r0, #0x78                             @ 080045DE
	movs	r1, #0                                @ 080045E0
	movs	r2, #0x3c                             @ 080045E2
	bl	memset                                  @ 080045E4
	adds	r4, #0xb4                             @ 080045E8
	adds	r0, r4, #0                            @ 080045EA
	movs	r1, #0                                @ 080045EC
	movs	r2, #0x3c                             @ 080045EE
	bl	memset                                  @ 080045F0
	ldr	r0, .Llit08004638                      @ 080045F4  =gmpJumped
	strb	r6, [r0]                              @ 080045F6  gmpJumped
	ldr	r0, .Llit0800463C                      @ 080045F8  =gmpTick
	strh	r5, [r0]                              @ 080045FA  gmpTick
	ldr	r0, .Llit08004640                      @ 080045FC  =gmpSkip
	str	r5, [r0]                               @ 080045FE  gmpSkip
	ldr	r0, .Llit08004644                      @ 08004600  =gmpQueued
	str	r5, [r0]                               @ 08004602  gmpQueued
	movs	r0, #1                                @ 08004604
	b	.L0800464A                               @ 08004606
.Llit08004608:
	.word	gmpRate                              @ 08004608
.Llit0800460C:
	.word	gmpPlayer                            @ 0800460C
.Llit08004610:
	.word	gmpStepTab                           @ 08004610
.Llit08004614:
	.word	gmpLoopStart                         @ 08004614
.Llit08004618:
	.word	gmpLoopEnd                           @ 08004618
.Llit0800461C:
	.word	gmpOrder                             @ 0800461C
.Llit08004620:
	.word	gmpCell                              @ 08004620
.Llit08004624:
	.word	gmpRowLen                            @ 08004624
.Llit08004628:
	.word	gmpRowLeft                           @ 08004628
.Llit0800462C:
	.word	gmpTickLen                           @ 0800462C
.Llit08004630:
	.word	gmpTickLeft                          @ 08004630
.Llit08004634:
	.word	gmpChan                              @ 08004634
.Llit08004638:
	.word	gmpJumped                            @ 08004638
.Llit0800463C:
	.word	gmpTick                              @ 0800463C
.Llit08004640:
	.word	gmpSkip                              @ 08004640
.Llit08004644:
	.word	gmpQueued                            @ 08004644
.L08004648:
	movs	r0, #0                                @ 08004648
.L0800464A:
	pop	{r4, r5, r6, r7}                       @ 0800464A
	pop	{r1}                                   @ 0800464C
	bx	r1                                      @ 0800464E
@ --------------------------------------------------------------------------
@ gmpPlayJingle(order, loopStart, loopEnd, priority)  (0x08004650)
@   A jingle is another range of orders in the current module.
@   if (order out of range || (priority && priority <= gmpJinglePri)) return;
@   gmpPriSaved = gmpJinglePri;
@   if (!gmpJingleOn || !priority) save skip/queue flags, gmpReturnOrder = gmpOrder and the loop range
@   gmpJingleOn = 1; gmpJinglePri = priority; gmpJumpSong(order, loopStart, loopEnd)
@   Pinball calls it from several places, some with loop ranges read from its own tables.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpPlayJingle
gmpPlayJingle:
	push	{r4, r5, r6, r7, lr}                  @ 08004650
	lsls	r0, r0, #0x10                         @ 08004652
	lsls	r1, r1, #0x10                         @ 08004654
	lsrs	r6, r1, #0x10                         @ 08004656
	lsls	r2, r2, #0x10                         @ 08004658
	lsrs	r7, r2, #0x10                         @ 0800465A
	lsls	r3, r3, #0x10                         @ 0800465C
	lsrs	r4, r3, #0x10                         @ 0800465E
	lsrs	r5, r0, #0x10                         @ 08004660
	asrs	r1, r0, #0x10                         @ 08004662
	cmp	r1, #0                                 @ 08004664
	blt	.L080046D8                             @ 08004666
	ldr	r0, .Llit080046E0                      @ 08004668  =gmpPlayer
	ldr	r0, [r0]                               @ 0800466A  gmpPlayer
	ldr	r0, [r0, #0x14]                        @ 0800466C
	cmp	r1, r0                                 @ 0800466E
	bge	.L080046D8                             @ 08004670
	lsls	r0, r4, #0x10                         @ 08004672
	asrs	r2, r0, #0x10                         @ 08004674
	ldr	r3, .Llit080046E4                      @ 08004676  =gmpJinglePri
	cmp	r2, #0                                 @ 08004678
	beq	.L08004684                             @ 0800467A
	movs	r1, #0                                @ 0800467C
	ldrsh	r0, [r3, r1]                         @ 0800467E
	cmp	r2, r0                                 @ 08004680
	ble	.L080046D8                             @ 08004682
.L08004684:
	ldr	r1, .Llit080046E8                      @ 08004684  =gmpPriSaved
	ldrh	r0, [r3]                              @ 08004686
	strh	r0, [r1]                              @ 08004688  gmpPriSaved
	ldr	r0, .Llit080046EC                      @ 0800468A  =gmpJingleOn
	ldrb	r0, [r0]                              @ 0800468C  gmpJingleOn
	cmp	r0, #0                                 @ 0800468E
	beq	.L08004696                             @ 08004690
	cmp	r2, #0                                 @ 08004692
	bne	.L080046BE                             @ 08004694
.L08004696:
	ldr	r1, .Llit080046F0                      @ 08004696  =gmpSkipSaved
	ldr	r0, .Llit080046F4                      @ 08004698  =gmpSkip
	ldr	r0, [r0]                               @ 0800469A  gmpSkip
	str	r0, [r1]                               @ 0800469C  gmpSkipSaved
	ldr	r1, .Llit080046F8                      @ 0800469E  =gmpQueuedSaved
	ldr	r0, .Llit080046FC                      @ 080046A0  =gmpQueued
	ldr	r0, [r0]                               @ 080046A2  gmpQueued
	str	r0, [r1]                               @ 080046A4  gmpQueuedSaved
	ldr	r1, .Llit08004700                      @ 080046A6  =gmpReturnOrder
	ldr	r0, .Llit08004704                      @ 080046A8  =gmpOrder
	ldrh	r0, [r0]                              @ 080046AA  gmpOrder
	strh	r0, [r1]                              @ 080046AC  gmpReturnOrder
	ldr	r1, .Llit08004708                      @ 080046AE  =gmpReturnLoopStart
	ldr	r0, .Llit0800470C                      @ 080046B0  =gmpLoopStart
	ldrh	r0, [r0]                              @ 080046B2  gmpLoopStart
	strh	r0, [r1]                              @ 080046B4  gmpReturnLoopStart
	ldr	r1, .Llit08004710                      @ 080046B6  =gmpReturnLoopEnd
	ldr	r0, .Llit08004714                      @ 080046B8  =gmpLoopEnd
	ldrh	r0, [r0]                              @ 080046BA  gmpLoopEnd
	strh	r0, [r1]                              @ 080046BC  gmpReturnLoopEnd
.L080046BE:
	ldr	r1, .Llit080046EC                      @ 080046BE  =gmpJingleOn
	movs	r0, #1                                @ 080046C0
	strb	r0, [r1]                              @ 080046C2  gmpJingleOn
	ldr	r0, .Llit080046E4                      @ 080046C4  =gmpJinglePri
	strh	r4, [r0]                              @ 080046C6  gmpJinglePri
	lsls	r0, r5, #0x10                         @ 080046C8
	asrs	r0, r0, #0x10                         @ 080046CA
	lsls	r1, r6, #0x10                         @ 080046CC
	asrs	r1, r1, #0x10                         @ 080046CE
	lsls	r2, r7, #0x10                         @ 080046D0
	asrs	r2, r2, #0x10                         @ 080046D2
	bl	gmpJumpSong                             @ 080046D4
.L080046D8:
	pop	{r4, r5, r6, r7}                       @ 080046D8
	pop	{r0}                                   @ 080046DA
	bx	r0                                      @ 080046DC
	.hword	0x0000                              @ 080046DE  (padding)
.Llit080046E0:
	.word	gmpPlayer                            @ 080046E0
.Llit080046E4:
	.word	gmpJinglePri                         @ 080046E4
.Llit080046E8:
	.word	gmpPriSaved                          @ 080046E8
.Llit080046EC:
	.word	gmpJingleOn                          @ 080046EC
.Llit080046F0:
	.word	gmpSkipSaved                         @ 080046F0
.Llit080046F4:
	.word	gmpSkip                              @ 080046F4
.Llit080046F8:
	.word	gmpQueuedSaved                       @ 080046F8
.Llit080046FC:
	.word	gmpQueued                            @ 080046FC
.Llit08004700:
	.word	gmpReturnOrder                       @ 08004700
.Llit08004704:
	.word	gmpOrder                             @ 08004704
.Llit08004708:
	.word	gmpReturnLoopStart                   @ 08004708
.Llit0800470C:
	.word	gmpLoopStart                         @ 0800470C
.Llit08004710:
	.word	gmpReturnLoopEnd                     @ 08004710
.Llit08004714:
	.word	gmpLoopEnd                           @ 08004714
@ --------------------------------------------------------------------------
@ gmpQueueOrder(order, loopStart, loopEnd, priority)  (0x08004718)
@   Stores the arguments and sets gmpQueued; gmpProcessRow calls gmpStartSong with them on
@   the next row that is not a multiple of 4 (same inverted test as v2).
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpQueueOrder
gmpQueueOrder:
	push	{r4, r5, lr}                          @ 08004718
	lsls	r1, r1, #0x10                         @ 0800471A
	lsrs	r4, r1, #0x10                         @ 0800471C
	lsls	r2, r2, #0x10                         @ 0800471E
	lsrs	r2, r2, #0x10                         @ 08004720
	lsls	r3, r3, #0x10                         @ 08004722
	lsrs	r3, r3, #0x10                         @ 08004724
	lsls	r0, r0, #0x10                         @ 08004726
	asrs	r1, r0, #0x10                         @ 08004728
	cmp	r1, #0                                 @ 0800472A
	blt	.L08004768                             @ 0800472C
	ldr	r0, .Llit08004770                      @ 0800472E  =gmpPlayer
	ldr	r0, [r0]                               @ 08004730  gmpPlayer
	ldr	r0, [r0, #0x14]                        @ 08004732
	cmp	r1, r0                                 @ 08004734
	bge	.L08004768                             @ 08004736
	lsls	r0, r3, #0x10                         @ 08004738
	asrs	r3, r0, #0x10                         @ 0800473A
	cmp	r3, #0                                 @ 0800473C
	beq	.L0800474A                             @ 0800473E
	ldr	r0, .Llit08004774                      @ 08004740  =gmpJinglePri
	movs	r5, #0                                @ 08004742
	ldrsh	r0, [r0, r5]                         @ 08004744
	cmp	r3, r0                                 @ 08004746
	ble	.L08004768                             @ 08004748
.L0800474A:
	ldr	r0, .Llit08004778                      @ 0800474A  =gmpQueuedPri
	str	r3, [r0]                               @ 0800474C  gmpQueuedPri
	ldr	r0, .Llit0800477C                      @ 0800474E  =gmpQueuedOrder
	str	r1, [r0]                               @ 08004750  gmpQueuedOrder
	ldr	r1, .Llit08004780                      @ 08004752  =gmpQueuedLoopStart
	lsls	r0, r4, #0x10                         @ 08004754
	asrs	r0, r0, #0x10                         @ 08004756
	str	r0, [r1]                               @ 08004758  gmpQueuedLoopStart
	ldr	r1, .Llit08004784                      @ 0800475A  =gmpQueuedLoopEnd
	lsls	r0, r2, #0x10                         @ 0800475C
	asrs	r0, r0, #0x10                         @ 0800475E
	str	r0, [r1]                               @ 08004760  gmpQueuedLoopEnd
	ldr	r1, .Llit08004788                      @ 08004762  =gmpQueued
	movs	r0, #1                                @ 08004764
	str	r0, [r1]                               @ 08004766  gmpQueued
.L08004768:
	pop	{r4, r5}                               @ 08004768
	pop	{r0}                                   @ 0800476A
	bx	r0                                      @ 0800476C
	.hword	0x0000                              @ 0800476E  (padding)
.Llit08004770:
	.word	gmpPlayer                            @ 08004770
.Llit08004774:
	.word	gmpJinglePri                         @ 08004774
.Llit08004778:
	.word	gmpQueuedPri                         @ 08004778
.Llit0800477C:
	.word	gmpQueuedOrder                       @ 0800477C
.Llit08004780:
	.word	gmpQueuedLoopStart                   @ 08004780
.Llit08004784:
	.word	gmpQueuedLoopEnd                     @ 08004784
.Llit08004788:
	.word	gmpQueued                            @ 08004788
@ --------------------------------------------------------------------------
@ gmpSetReturn(order, loopStart, loopEnd)  (0x0800478C)
@   where gmpEndJingle goes back to; gmpPriSaved = 0
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpSetReturn
gmpSetReturn:
	ldr	r3, .Llit080047A0                      @ 0800478C  =gmpReturnOrder
	strh	r0, [r3]                              @ 0800478E  gmpReturnOrder
	ldr	r0, .Llit080047A4                      @ 08004790  =gmpReturnLoopStart
	strh	r1, [r0]                              @ 08004792  gmpReturnLoopStart
	ldr	r0, .Llit080047A8                      @ 08004794  =gmpReturnLoopEnd
	strh	r2, [r0]                              @ 08004796  gmpReturnLoopEnd
	ldr	r1, .Llit080047AC                      @ 08004798  =gmpPriSaved
	movs	r0, #0                                @ 0800479A
	strh	r0, [r1]                              @ 0800479C  gmpPriSaved
	bx	lr                                      @ 0800479E
.Llit080047A0:
	.word	gmpReturnOrder                       @ 080047A0
.Llit080047A4:
	.word	gmpReturnLoopStart                   @ 080047A4
.Llit080047A8:
	.word	gmpReturnLoopEnd                     @ 080047A8
.Llit080047AC:
	.word	gmpPriSaved                          @ 080047AC
@ --------------------------------------------------------------------------
@ gmpEndJingle()  (0x080047B0)
@   gmpJingleOn = 0; gmpJinglePri = 0; gmpJumpSong(gmpReturnOrder, return loop range);
@   restore skip/queue flags; if (gmpPauseAfterJingleFlag) { clear it; gmpPause() }
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpEndJingle
gmpEndJingle:
	push	{lr}                                  @ 080047B0
	ldr	r1, .Llit080047FC                      @ 080047B2  =gmpJingleOn
	movs	r0, #0                                @ 080047B4
	strb	r0, [r1]                              @ 080047B6  gmpJingleOn
	ldr	r1, .Llit08004800                      @ 080047B8  =gmpJinglePri
	movs	r0, #0                                @ 080047BA
	strh	r0, [r1]                              @ 080047BC  gmpJinglePri
	ldr	r0, .Llit08004804                      @ 080047BE  =gmpReturnOrder
	movs	r1, #0                                @ 080047C0
	ldrsh	r0, [r0, r1]                         @ 080047C2
	ldr	r1, .Llit08004808                      @ 080047C4  =gmpReturnLoopStart
	movs	r2, #0                                @ 080047C6
	ldrsh	r1, [r1, r2]                         @ 080047C8
	ldr	r2, .Llit0800480C                      @ 080047CA  =gmpReturnLoopEnd
	movs	r3, #0                                @ 080047CC
	ldrsh	r2, [r2, r3]                         @ 080047CE
	bl	gmpJumpSong                             @ 080047D0
	ldr	r1, .Llit08004810                      @ 080047D4  =gmpSkip
	ldr	r3, .Llit08004814                      @ 080047D6  =gmpSkipSaved
	ldr	r0, [r3]                               @ 080047D8  gmpSkipSaved
	str	r0, [r1]                               @ 080047DA  gmpSkip
	ldr	r1, .Llit08004818                      @ 080047DC  =gmpQueued
	ldr	r2, .Llit0800481C                      @ 080047DE  =gmpQueuedSaved
	ldr	r0, [r2]                               @ 080047E0  gmpQueuedSaved
	str	r0, [r1]                               @ 080047E2  gmpQueued
	movs	r1, #0                                @ 080047E4
	str	r1, [r3]                               @ 080047E6  gmpSkipSaved
	str	r1, [r2]                               @ 080047E8  gmpQueuedSaved
	ldr	r2, .Llit08004820                      @ 080047EA  =gmpPauseAfterJingleFlag
	ldr	r0, [r2]                               @ 080047EC  gmpPauseAfterJingleFlag
	cmp	r0, #0                                 @ 080047EE
	beq	.L080047F8                             @ 080047F0
	str	r1, [r2]                               @ 080047F2  gmpPauseAfterJingleFlag
	bl	gmpPause                                @ 080047F4
.L080047F8:
	pop	{r0}                                   @ 080047F8
	bx	r0                                      @ 080047FA
.Llit080047FC:
	.word	gmpJingleOn                          @ 080047FC
.Llit08004800:
	.word	gmpJinglePri                         @ 08004800
.Llit08004804:
	.word	gmpReturnOrder                       @ 08004804
.Llit08004808:
	.word	gmpReturnLoopStart                   @ 08004808
.Llit0800480C:
	.word	gmpReturnLoopEnd                     @ 0800480C
.Llit08004810:
	.word	gmpSkip                              @ 08004810
.Llit08004814:
	.word	gmpSkipSaved                         @ 08004814
.Llit08004818:
	.word	gmpQueued                            @ 08004818
.Llit0800481C:
	.word	gmpQueuedSaved                       @ 0800481C
.Llit08004820:
	.word	gmpPauseAfterJingleFlag              @ 08004820
@ --------------------------------------------------------------------------
@ gmpSkipPattern()  (0x08004824)
@   gmpSkip = 1
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpSkipPattern
gmpSkipPattern:
	ldr	r1, .Llit0800482C                      @ 08004824  =gmpSkip
	movs	r0, #1                                @ 08004826
	str	r0, [r1]                               @ 08004828  gmpSkip
	bx	lr                                      @ 0800482A
.Llit0800482C:
	.word	gmpSkip                              @ 0800482C
@ --------------------------------------------------------------------------
@ gmpPause() / gmpPauseAfterJingle() / gmpResume()  (0x08004830, 0x08004844, 0x08004850)
@   gmpPaused = 1, hostSoundOff() / gmpPauseAfterJingleFlag = 1 / gmpPaused = 0, hostSoundOn()
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpPause
gmpPause:
	push	{lr}                                  @ 08004830
	ldr	r1, .Llit08004840                      @ 08004832  =gmpPaused
	movs	r0, #1                                @ 08004834
	str	r0, [r1]                               @ 08004836  gmpPaused
	bl	hostSoundOff                            @ 08004838
	pop	{r0}                                   @ 0800483C
	bx	r0                                      @ 0800483E
.Llit08004840:
	.word	gmpPaused                            @ 08004840
	.thumb_func
	.global gmpPauseAfterJingle
gmpPauseAfterJingle:
	ldr	r1, .Llit0800484C                      @ 08004844  =gmpPauseAfterJingleFlag
	movs	r0, #1                                @ 08004846
	str	r0, [r1]                               @ 08004848  gmpPauseAfterJingleFlag
	bx	lr                                      @ 0800484A
.Llit0800484C:
	.word	gmpPauseAfterJingleFlag              @ 0800484C
	.thumb_func
	.global gmpResume
gmpResume:
	push	{lr}                                  @ 08004850
	ldr	r1, .Llit08004860                      @ 08004852  =gmpPaused
	movs	r0, #0                                @ 08004854
	str	r0, [r1]                               @ 08004856  gmpPaused
	bl	hostSoundOn                             @ 08004858
	pop	{r0}                                   @ 0800485C
	bx	r0                                      @ 0800485E
.Llit08004860:
	.word	gmpPaused                            @ 08004860
@ --------------------------------------------------------------------------
@ gmpClearMusic()  (0x08004864)
@   memset the four music channels
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpClearMusic
gmpClearMusic:
	push	{r4, lr}                              @ 08004864
	ldr	r4, .Llit0800489C                      @ 08004866  =gmpChan
	adds	r0, r4, #0                            @ 08004868
	movs	r1, #0                                @ 0800486A
	movs	r2, #0x3c                             @ 0800486C
	bl	memset                                  @ 0800486E
	adds	r0, r4, #0                            @ 08004872
	adds	r0, #0x3c                             @ 08004874
	movs	r1, #0                                @ 08004876
	movs	r2, #0x3c                             @ 08004878
	bl	memset                                  @ 0800487A
	adds	r0, r4, #0                            @ 0800487E
	adds	r0, #0x78                             @ 08004880
	movs	r1, #0                                @ 08004882
	movs	r2, #0x3c                             @ 08004884
	bl	memset                                  @ 08004886
	adds	r4, #0xb4                             @ 0800488A
	adds	r0, r4, #0                            @ 0800488C
	movs	r1, #0                                @ 0800488E
	movs	r2, #0x3c                             @ 08004890
	bl	memset                                  @ 08004892
	pop	{r4}                                   @ 08004896
	pop	{r0}                                   @ 08004898
	bx	r0                                      @ 0800489A
.Llit0800489C:
	.word	gmpChan                              @ 0800489C
@ --------------------------------------------------------------------------
@ gmpMixNext()  (0x080048A0)
@   if (gmpPaused) return 0; if (!gmpRate) return 1;
@   if (gmpOrder >= songLen) gmpClearMusic();                   (song over: silence)
@   b = gmpCur ^ 1; if (gmpBufFree[b]) { gmpBufFree[b] = 0; gmpMix(gmpBuf[b]) }  return 0
@   The game's frame code at 0x080088E2 restarts DMA1 (gmpDmaRestart in gbamod1_arm.s), calls
@   this, and on 0 marks the buffer free and flips gmpCur, like v2's gmpVBlank.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpMixNext
gmpMixNext:
	push	{r4, lr}                              @ 080048A0
	ldr	r0, .Llit080048B8                      @ 080048A2  =gmpPaused
	ldr	r4, [r0]                               @ 080048A4  gmpPaused
	cmp	r4, #0                                 @ 080048A6
	bne	.L080048F2                             @ 080048A8
	ldr	r0, .Llit080048BC                      @ 080048AA  =gmpRate
	ldr	r0, [r0]                               @ 080048AC  gmpRate
	cmp	r0, #0                                 @ 080048AE
	bne	.L080048C0                             @ 080048B0
	movs	r0, #1                                @ 080048B2
	b	.L080048F4                               @ 080048B4
	.hword	0x0000                              @ 080048B6  (padding)
.Llit080048B8:
	.word	gmpPaused                            @ 080048B8
.Llit080048BC:
	.word	gmpRate                              @ 080048BC
.L080048C0:
	ldr	r1, .Llit080048FC                      @ 080048C0  =gmpOrder
	ldr	r0, .Llit08004900                      @ 080048C2  =gmpPlayer
	ldr	r0, [r0]                               @ 080048C4  gmpPlayer
	ldr	r0, [r0, #0x14]                        @ 080048C6
	ldrh	r1, [r1]                              @ 080048C8  gmpOrder
	cmp	r1, r0                                 @ 080048CA
	blt	.L080048D2                             @ 080048CC
	bl	gmpClearMusic                           @ 080048CE
.L080048D2:
	ldr	r2, .Llit08004904                      @ 080048D2  =gmpBufFree
	ldr	r0, .Llit08004908                      @ 080048D4  =gmpCur
	ldr	r0, [r0]                               @ 080048D6  gmpCur
	movs	r1, #1                                @ 080048D8
	eors	r0, r1                                @ 080048DA
	lsls	r3, r0, #2                            @ 080048DC
	adds	r1, r3, r2                            @ 080048DE
	ldr	r0, [r1]                               @ 080048E0
	cmp	r0, #0                                 @ 080048E2
	beq	.L080048F2                             @ 080048E4
	str	r4, [r1]                               @ 080048E6
	ldr	r0, .Llit0800490C                      @ 080048E8  =gmpBuf
	adds	r0, r3, r0                            @ 080048EA
	ldr	r0, [r0]                               @ 080048EC
	bl	gmpMix                                  @ 080048EE
.L080048F2:
	movs	r0, #0                                @ 080048F2
.L080048F4:
	pop	{r4}                                   @ 080048F4
	pop	{r1}                                   @ 080048F6
	bx	r1                                      @ 080048F8
	.hword	0x0000                              @ 080048FA  (padding)
.Llit080048FC:
	.word	gmpOrder                             @ 080048FC
.Llit08004900:
	.word	gmpPlayer                            @ 08004900
.Llit08004904:
	.word	gmpBufFree                           @ 08004904
.Llit08004908:
	.word	gmpCur                               @ 08004908
.Llit0800490C:
	.word	gmpBuf                               @ 0800490C
@ --------------------------------------------------------------------------
@ gmpProcessRow()  (0x08004910)
@   if (gmpQueued && ((gmpCell >> 2) & 3) != 0) { gmpQueued = 0; gmpStartSong(queued...) }
@   p = patPtr[orders[gmpOrder]] + gmpCell * 4; empty = gmpCell >= rows[pat] * 4
@   gmpCell += 4; gmpTick = gmpArpTick = gmpJumped = 0
@   gmpRowEffects() for the 4 music channels (fixed: v1 modules always have 4)
@   if (gmpCell == 256) {                                     64 rows
@      if (gmpLoopEnd == -1) gmpOrder++;
@      else if (gmpOrder > gmpLoopEnd) gmpOrder = gmpLoopStart;
@      gmpCell = 0 }
@   With a loop range the order is *not* advanced at a pattern end: the pattern repeats until a
@   Bxx moves on, and Bxx (which stores xx - 1 and relies on the increment) then lands one order
@   early.  A range therefore only behaves for single-pattern loops.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpProcessRow
gmpProcessRow:
	push	{r4, r5, r6, r7, lr}                  @ 08004910
	mov	r7, r8                                 @ 08004912
	push	{r7}                                  @ 08004914
	ldr	r2, .Llit080049EC                      @ 08004916  =gmpQueued
	ldr	r0, [r2]                               @ 08004918  gmpQueued
	cmp	r0, #0                                 @ 0800491A
	beq	.L08004946                             @ 0800491C
	ldr	r0, .Llit080049F0                      @ 0800491E  =gmpCell
	ldrh	r0, [r0]                              @ 08004920  gmpCell
	lsrs	r0, r0, #2                            @ 08004922
	movs	r1, #3                                @ 08004924
	ands	r0, r1                                @ 08004926
	cmp	r0, #0                                 @ 08004928
	beq	.L08004946                             @ 0800492A
	movs	r0, #0                                @ 0800492C
	str	r0, [r2]                               @ 0800492E  gmpQueued
	ldr	r0, .Llit080049F4                      @ 08004930  =gmpQueuedOrder
	movs	r1, #0                                @ 08004932
	ldrsh	r0, [r0, r1]                         @ 08004934
	ldr	r1, .Llit080049F8                      @ 08004936  =gmpQueuedLoopStart
	movs	r2, #0                                @ 08004938
	ldrsh	r1, [r1, r2]                         @ 0800493A
	ldr	r2, .Llit080049FC                      @ 0800493C  =gmpQueuedLoopEnd
	movs	r3, #0                                @ 0800493E
	ldrsh	r2, [r2, r3]                         @ 08004940
	bl	gmpStartSong                            @ 08004942
.L08004946:
	ldr	r1, .Llit08004A00                      @ 08004946  =gmpPlayer
	ldm	r1!, {r0}                              @ 08004948
	ldr	r2, .Llit08004A04                      @ 0800494A  =gmpOrder
	mov	r8, r2                                 @ 0800494C
	movs	r3, #0xc6                             @ 0800494E
	lsls	r3, r3, #3                            @ 08004950
	adds	r0, r0, r3                            @ 08004952
	ldrh	r2, [r2]                              @ 08004954  gmpOrder
	adds	r0, r2, r0                            @ 08004956
	ldrb	r2, [r0]                              @ 08004958
	lsls	r0, r2, #2                            @ 0800495A
	adds	r0, r0, r1                            @ 0800495C
	ldr	r4, [r0]                               @ 0800495E
	ldr	r7, .Llit080049F0                      @ 08004960  =gmpCell
	ldrh	r1, [r7]                              @ 08004962  gmpCell
	lsls	r0, r1, #2                            @ 08004964
	adds	r4, r4, r0                            @ 08004966
	ldr	r6, .Llit08004A08                      @ 08004968  =gmpChan
	ldr	r0, .Llit08004A0C                      @ 0800496A  =gmpPatRows
	ldr	r0, [r0]                               @ 0800496C  gmpPatRows
	adds	r0, r0, r2                            @ 0800496E
	ldrb	r0, [r0]                              @ 08004970
	lsls	r0, r0, #2                            @ 08004972
	movs	r5, #0                                @ 08004974
	cmp	r1, r0                                 @ 08004976
	blt	.L0800497C                             @ 08004978
	movs	r5, #1                                @ 0800497A
.L0800497C:
	adds	r0, r1, #4                            @ 0800497C
	strh	r0, [r7]                              @ 0800497E
	ldr	r0, .Llit08004A10                      @ 08004980  =gmpTick
	movs	r1, #0                                @ 08004982
	strh	r1, [r0]                              @ 08004984  gmpTick
	ldr	r0, .Llit08004A14                      @ 08004986  =gmpArpTick
	strh	r1, [r0]                              @ 08004988  gmpArpTick
	ldr	r0, .Llit08004A18                      @ 0800498A  =gmpJumped
	strb	r1, [r0]                              @ 0800498C  gmpJumped
	adds	r0, r4, #0                            @ 0800498E
	adds	r1, r6, #0                            @ 08004990
	adds	r2, r5, #0                            @ 08004992
	bl	gmpRowEffects                           @ 08004994
	adds	r0, r4, #4                            @ 08004998
	adds	r1, r6, #0                            @ 0800499A
	adds	r1, #0x3c                             @ 0800499C
	adds	r2, r5, #0                            @ 0800499E
	bl	gmpRowEffects                           @ 080049A0
	adds	r0, r4, #0                            @ 080049A4
	adds	r0, #8                                @ 080049A6
	adds	r1, r6, #0                            @ 080049A8
	adds	r1, #0x78                             @ 080049AA
	adds	r2, r5, #0                            @ 080049AC
	bl	gmpRowEffects                           @ 080049AE
	adds	r0, r4, #0                            @ 080049B2
	adds	r0, #0xc                              @ 080049B4
	adds	r1, r6, #0                            @ 080049B6
	adds	r1, #0xb4                             @ 080049B8
	adds	r2, r5, #0                            @ 080049BA
	bl	gmpRowEffects                           @ 080049BC
	movs	r0, #0x80                             @ 080049C0
	lsls	r0, r0, #1                            @ 080049C2
	ldrh	r7, [r7]                              @ 080049C4
	cmp	r7, r0                                 @ 080049C6
	bne	.L08004A32                             @ 080049C8
	ldr	r2, .Llit08004A1C                      @ 080049CA  =gmpLoopEnd
	movs	r3, #0                                @ 080049CC
	ldrsh	r1, [r2, r3]                         @ 080049CE
	movs	r0, #1                                @ 080049D0
	rsbs	r0, r0, #0                            @ 080049D2
	cmp	r1, r0                                 @ 080049D4  loopEnd == -1 ?
	beq	.L08004A24                             @ 080049D6
	adds	r0, r1, #0                            @ 080049D8
	mov	r2, r8                                 @ 080049DA
	ldrh	r2, [r2]                              @ 080049DC
	cmp	r2, r0                                 @ 080049DE  order > loopEnd ?
	ble	.L08004A2C                             @ 080049E0
	ldr	r0, .Llit08004A20                      @ 080049E2  =gmpLoopStart
	ldrh	r0, [r0]                              @ 080049E4  gmpLoopStart
	mov	r3, r8                                 @ 080049E6
	strh	r0, [r3]                              @ 080049E8
	b	.L08004A2C                               @ 080049EA
.Llit080049EC:
	.word	gmpQueued                            @ 080049EC
.Llit080049F0:
	.word	gmpCell                              @ 080049F0
.Llit080049F4:
	.word	gmpQueuedOrder                       @ 080049F4
.Llit080049F8:
	.word	gmpQueuedLoopStart                   @ 080049F8
.Llit080049FC:
	.word	gmpQueuedLoopEnd                     @ 080049FC
.Llit08004A00:
	.word	gmpPlayer                            @ 08004A00
.Llit08004A04:
	.word	gmpOrder                             @ 08004A04
.Llit08004A08:
	.word	gmpChan                              @ 08004A08
.Llit08004A0C:
	.word	gmpPatRows                           @ 08004A0C
.Llit08004A10:
	.word	gmpTick                              @ 08004A10
.Llit08004A14:
	.word	gmpArpTick                           @ 08004A14
.Llit08004A18:
	.word	gmpJumped                            @ 08004A18
.Llit08004A1C:
	.word	gmpLoopEnd                           @ 08004A1C
.Llit08004A20:
	.word	gmpLoopStart                         @ 08004A20
.L08004A24:
	mov	r1, r8                                 @ 08004A24
	ldrh	r0, [r1]                              @ 08004A26
	adds	r0, #1                                @ 08004A28  gmpOrder++
	strh	r0, [r1]                              @ 08004A2A
.L08004A2C:
	ldr	r1, .Llit08004A3C                      @ 08004A2C  =gmpCell
	movs	r0, #0                                @ 08004A2E
	strh	r0, [r1]                              @ 08004A30  gmpCell
.L08004A32:
	pop	{r3}                                   @ 08004A32
	mov	r8, r3                                 @ 08004A34
	pop	{r4, r5, r6, r7}                       @ 08004A36
	pop	{r0}                                   @ 08004A38
	bx	r0                                      @ 08004A3A
.Llit08004A3C:
	.word	gmpCell                              @ 08004A3C
@ --------------------------------------------------------------------------
@ gmpMixChannelC(ch, dst, n)  (0x08004A40)  -- unused
@   C version of the per-channel mixer.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpMixChannelC
gmpMixChannelC:
	push	{r4, r5, r6, r7, lr}                  @ 08004A40
	mov	r7, sl                                 @ 08004A42
	mov	r6, sb                                 @ 08004A44
	mov	r5, r8                                 @ 08004A46
	push	{r5, r6, r7}                          @ 08004A48
	adds	r4, r0, #0                            @ 08004A4A
	adds	r5, r1, #0                            @ 08004A4C
	ldrh	r6, [r4, #0xc]                        @ 08004A4E  CH_end
	cmp	r6, #2                                 @ 08004A50
	beq	.L08004AA8                             @ 08004A52
	ldr	r0, [r4, #0x14]                        @ 08004A54  CH_vol
	mov	ip, r0                                 @ 08004A56
	ldr	r1, [r4]                               @ 08004A58  CH_ptr
	ldr	r3, [r4, #4]                           @ 08004A5A  CH_pos
	ldr	r7, [r4, #8]                           @ 08004A5C  CH_step
	mov	sl, r7                                 @ 08004A5E
	cmp	r2, #0                                 @ 08004A60
	ble	.L08004AA2                             @ 08004A62
	movs	r0, #0                                @ 08004A64
	mov	sb, r0                                 @ 08004A66
	ldr	r7, .Llit08004AB8                      @ 08004A68  =0x00000FFF
	mov	r8, r7                                 @ 08004A6A
.L08004A6C:
	lsrs	r0, r3, #0xc                          @ 08004A6C
	add	r3, sl                                 @ 08004A6E
	cmp	r0, r6                                 @ 08004A70
	blo	.L08004A84                             @ 08004A72
	ldrh	r0, [r4, #0xe]                        @ 08004A74
	adds	r1, r0, r1                            @ 08004A76
	ldrh	r6, [r4, #0x10]                       @ 08004A78
	mov	r7, sb                                 @ 08004A7A
	strh	r7, [r4, #0xe]                        @ 08004A7C
	mov	r0, r8                                 @ 08004A7E
	ands	r3, r0                                @ 08004A80
	lsrs	r0, r3, #0xc                          @ 08004A82
.L08004A84:
	adds	r0, r1, r0                            @ 08004A84
	ldrb	r0, [r0]                              @ 08004A86
	lsls	r0, r0, #0x18                         @ 08004A88
	asrs	r0, r0, #0x18                         @ 08004A8A
	mov	r7, ip                                 @ 08004A8C
	muls	r7, r0, r7                            @ 08004A8E
	adds	r0, r7, #0                            @ 08004A90
	asrs	r0, r0, #8                            @ 08004A92
	ldrb	r7, [r5]                              @ 08004A94
	adds	r0, r7, r0                            @ 08004A96
	strb	r0, [r5]                              @ 08004A98
	adds	r5, #1                                @ 08004A9A
	subs	r2, #1                                @ 08004A9C
	cmp	r2, #0                                 @ 08004A9E
	bgt	.L08004A6C                             @ 08004AA0
.L08004AA2:
	str	r1, [r4]                               @ 08004AA2
	str	r3, [r4, #4]                           @ 08004AA4
	strh	r6, [r4, #0xc]                        @ 08004AA6
.L08004AA8:
	pop	{r3, r4, r5}                           @ 08004AA8
	mov	r8, r3                                 @ 08004AAA
	mov	sb, r4                                 @ 08004AAC
	mov	sl, r5                                 @ 08004AAE
	pop	{r4, r5, r6, r7}                       @ 08004AB0
	pop	{r0}                                   @ 08004AB2
	bx	r0                                      @ 08004AB4
	.hword	0x0000                              @ 08004AB6  (padding)
.Llit08004AB8:
	.word	0x00000FFF                           @ 08004AB8
@ --------------------------------------------------------------------------
@ gmpMix(dst)  (0x08004ABC)
@   Like v2: attenuations attM/attS = clamp(max(64 - master, 64 - music/sfx), 0, 64);
@   memset(dst, 0, 352); slices end at the next row or tick; the tick handler is skipped on a
@   row's first tick; for the 6 channels (music first): v = CH_vol - att, and if v > 0 and
@   CH_end > 2 the EWRAM mixer is called (gmpMixing = 1 around the call).
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpMix
gmpMix:
	push	{r4, r5, r6, r7, lr}                  @ 08004ABC
	mov	r7, sl                                 @ 08004ABE
	mov	r6, sb                                 @ 08004AC0
	mov	r5, r8                                 @ 08004AC2
	push	{r5, r6, r7}                          @ 08004AC4
	sub	sp, #0x14                              @ 08004AC6
	adds	r1, r0, #0                            @ 08004AC8
	ldr	r0, .Llit08004BB4                      @ 08004ACA  =gmpMasterVol
	ldr	r3, [r0]                               @ 08004ACC  gmpMasterVol
	movs	r2, #0x40                             @ 08004ACE
	subs	r0, r2, r3                            @ 08004AD0
	str	r0, [sp]                               @ 08004AD2
	ldr	r0, .Llit08004BB8                      @ 08004AD4  =gmpMusicVol
	ldr	r0, [r0]                               @ 08004AD6  gmpMusicVol
	subs	r0, r2, r0                            @ 08004AD8
	ldr	r4, [sp]                               @ 08004ADA
	cmp	r4, r0                                 @ 08004ADC
	bge	.L08004AE2                             @ 08004ADE
	str	r0, [sp]                               @ 08004AE0
.L08004AE2:
	ldr	r0, [sp]                               @ 08004AE2
	cmp	r0, #0                                 @ 08004AE4
	bge	.L08004AEC                             @ 08004AE6
	movs	r4, #0                                @ 08004AE8
	str	r4, [sp]                               @ 08004AEA
.L08004AEC:
	ldr	r0, [sp]                               @ 08004AEC
	cmp	r0, #0x40                              @ 08004AEE
	ble	.L08004AF6                             @ 08004AF0
	movs	r4, #0x40                             @ 08004AF2
	str	r4, [sp]                               @ 08004AF4
.L08004AF6:
	subs	r3, r2, r3                            @ 08004AF6
	str	r3, [sp, #4]                           @ 08004AF8
	ldr	r0, .Llit08004BBC                      @ 08004AFA  =gmpSfxVol
	ldr	r0, [r0]                               @ 08004AFC  gmpSfxVol
	subs	r0, r2, r0                            @ 08004AFE
	cmp	r3, r0                                 @ 08004B00
	bge	.L08004B06                             @ 08004B02
	str	r0, [sp, #4]                           @ 08004B04
.L08004B06:
	ldr	r0, [sp, #4]                           @ 08004B06
	cmp	r0, #0                                 @ 08004B08
	bge	.L08004B10                             @ 08004B0A
	movs	r2, #0                                @ 08004B0C
	str	r2, [sp, #4]                           @ 08004B0E
.L08004B10:
	ldr	r4, [sp, #4]                           @ 08004B10
	cmp	r4, #0x40                              @ 08004B12
	ble	.L08004B1A                             @ 08004B14
	movs	r0, #0x40                             @ 08004B16
	str	r0, [sp, #4]                           @ 08004B18
.L08004B1A:
	movs	r6, #0                                @ 08004B1A
	mov	sl, r1                                 @ 08004B1C
	movs	r4, #0xb0                             @ 08004B1E
	lsls	r4, r4, #1                            @ 08004B20
	mov	r0, sl                                 @ 08004B22
	movs	r1, #0                                @ 08004B24
	adds	r2, r4, #0                            @ 08004B26
	bl	memset                                  @ 08004B28
	mov	r8, r4                                 @ 08004B2C
.L08004B2E:
	ldr	r1, .Llit08004BC0                      @ 08004B2E  =gmpRowLeft
	ldr	r0, [r1]                               @ 08004B30  gmpRowLeft
	cmp	r0, #0                                 @ 08004B32
	bne	.L08004B42                             @ 08004B34
	bl	gmpProcessRow                           @ 08004B36
	ldr	r0, .Llit08004BC4                      @ 08004B3A  =gmpRowLen
	ldr	r0, [r0]                               @ 08004B3C  gmpRowLen
	ldr	r2, .Llit08004BC0                      @ 08004B3E  =gmpRowLeft
	str	r0, [r2]                               @ 08004B40  gmpRowLeft
.L08004B42:
	ldr	r5, .Llit08004BC8                      @ 08004B42  =gmpTickLeft
	ldr	r0, [r5]                               @ 08004B44  gmpTickLeft
	cmp	r0, #0                                 @ 08004B46
	bne	.L08004B60                             @ 08004B48
	ldr	r0, .Llit08004BC4                      @ 08004B4A  =gmpRowLen
	ldr	r4, .Llit08004BC0                      @ 08004B4C  =gmpRowLeft
	ldr	r1, [r4]                               @ 08004B4E  gmpRowLeft
	ldr	r0, [r0]                               @ 08004B50  gmpRowLen
	cmp	r1, r0                                 @ 08004B52
	beq	.L08004B5A                             @ 08004B54
	bl	gmpProcessTick                          @ 08004B56
.L08004B5A:
	ldr	r0, .Llit08004BCC                      @ 08004B5A  =gmpTickLen
	ldr	r0, [r0]                               @ 08004B5C  gmpTickLen
	str	r0, [r5]                               @ 08004B5E
.L08004B60:
	ldr	r1, .Llit08004BC0                      @ 08004B60  =gmpRowLeft
	ldr	r0, [r1]                               @ 08004B62  gmpRowLeft
	ldr	r2, .Llit08004BC8                      @ 08004B64  =gmpTickLeft
	ldr	r5, [r2]                               @ 08004B66  gmpTickLeft
	cmp	r0, r5                                 @ 08004B68
	bge	.L08004B6E                             @ 08004B6A
	adds	r5, r0, #0                            @ 08004B6C
.L08004B6E:
	movs	r1, #0xb0                             @ 08004B6E
	lsls	r1, r1, #1                            @ 08004B70
	cmp	r5, r1                                 @ 08004B72
	ble	.L08004B78                             @ 08004B74
	adds	r5, r1, #0                            @ 08004B76
.L08004B78:
	adds	r0, r6, r5                            @ 08004B78
	cmp	r0, r1                                 @ 08004B7A
	ble	.L08004B80                             @ 08004B7C
	subs	r5, r1, r6                            @ 08004B7E
.L08004B80:
	ldr	r4, .Llit08004BD0                      @ 08004B80  =gmpChan
	movs	r7, #6                                @ 08004B82
	adds	r6, r6, r5                            @ 08004B84
	str	r6, [sp, #0x10]                        @ 08004B86
	mov	r0, sl                                 @ 08004B88
	adds	r0, r0, r5                            @ 08004B8A
	str	r0, [sp, #0xc]                         @ 08004B8C
	mov	r1, r8                                 @ 08004B8E
	subs	r1, r1, r5                            @ 08004B90
	str	r1, [sp, #8]                           @ 08004B92
	movs	r2, #0                                @ 08004B94
	mov	sb, r2                                 @ 08004B96
	ldr	r0, .Llit08004BD4                      @ 08004B98  =gmpMixing
	mov	r8, r0                                 @ 08004B9A
.L08004B9C:
	ldr	r0, [r4]                               @ 08004B9C
	cmp	r0, #0                                 @ 08004B9E
	beq	.L08004C10                             @ 08004BA0
	ldrh	r1, [r4, #0xc]                        @ 08004BA2
	cmp	r1, #2                                 @ 08004BA4
	beq	.L08004C10                             @ 08004BA6
	ldr	r6, [r4, #0x14]                        @ 08004BA8
	cmp	r7, #2                                 @ 08004BAA
	ble	.L08004BD8                             @ 08004BAC
	ldr	r2, [sp]                               @ 08004BAE
	subs	r0, r6, r2                            @ 08004BB0
	b	.L08004BDC                               @ 08004BB2
.Llit08004BB4:
	.word	gmpMasterVol                         @ 08004BB4
.Llit08004BB8:
	.word	gmpMusicVol                          @ 08004BB8
.Llit08004BBC:
	.word	gmpSfxVol                            @ 08004BBC
.Llit08004BC0:
	.word	gmpRowLeft                           @ 08004BC0
.Llit08004BC4:
	.word	gmpRowLen                            @ 08004BC4
.Llit08004BC8:
	.word	gmpTickLeft                          @ 08004BC8
.Llit08004BCC:
	.word	gmpTickLen                           @ 08004BCC
.Llit08004BD0:
	.word	gmpChan                              @ 08004BD0
.Llit08004BD4:
	.word	gmpMixing                            @ 08004BD4
.L08004BD8:
	ldr	r1, [sp, #4]                           @ 08004BD8
	subs	r0, r6, r1                            @ 08004BDA
.L08004BDC:
	str	r0, [r4, #0x14]                        @ 08004BDC
	ldr	r0, [r4, #0x14]                        @ 08004BDE
	cmp	r0, #0                                 @ 08004BE0
	bge	.L08004BE8                             @ 08004BE2
	mov	r2, sb                                 @ 08004BE4
	str	r2, [r4, #0x14]                        @ 08004BE6
.L08004BE8:
	ldr	r0, [r4, #0x14]                        @ 08004BE8
	cmp	r0, #0                                 @ 08004BEA
	beq	.L08004C0E                             @ 08004BEC
	ldrh	r0, [r4, #0xc]                        @ 08004BEE
	cmp	r0, #2                                 @ 08004BF0
	beq	.L08004C0E                             @ 08004BF2
	movs	r0, #1                                @ 08004BF4
	mov	r1, r8                                 @ 08004BF6
	strb	r0, [r1]                              @ 08004BF8
	ldr	r0, .Llit08004C4C                      @ 08004BFA  =gmpMixerCode
	ldr	r3, [r0]                               @ 08004BFC  gmpMixerCode
	adds	r0, r4, #0                            @ 08004BFE
	mov	r1, sl                                 @ 08004C00
	adds	r2, r5, #0                            @ 08004C02
	bl	gmpCallR3                               @ 08004C04
	mov	r2, sb                                 @ 08004C08
	mov	r0, r8                                 @ 08004C0A
	strb	r2, [r0]                              @ 08004C0C
.L08004C0E:
	str	r6, [r4, #0x14]                        @ 08004C0E
.L08004C10:
	adds	r4, #0x3c                             @ 08004C10
	subs	r7, #1                                @ 08004C12
	cmp	r7, #0                                 @ 08004C14
	bgt	.L08004B9C                             @ 08004C16
	ldr	r1, [sp, #0xc]                         @ 08004C18
	mov	sl, r1                                 @ 08004C1A
	ldr	r6, [sp, #0x10]                        @ 08004C1C
	ldr	r2, .Llit08004C50                      @ 08004C1E  =gmpRowLeft
	ldr	r0, [r2]                               @ 08004C20  gmpRowLeft
	subs	r0, r0, r5                            @ 08004C22
	str	r0, [r2]                               @ 08004C24  gmpRowLeft
	ldr	r4, .Llit08004C54                      @ 08004C26  =gmpTickLeft
	ldr	r0, [r4]                               @ 08004C28  gmpTickLeft
	subs	r0, r0, r5                            @ 08004C2A
	str	r0, [r4]                               @ 08004C2C  gmpTickLeft
	ldr	r0, [sp, #8]                           @ 08004C2E
	subs	r0, #1                                @ 08004C30
	mov	r8, r0                                 @ 08004C32
	cmp	r0, #0                                 @ 08004C34
	ble	.L08004C3A                             @ 08004C36
	b	.L08004B2E                               @ 08004C38
.L08004C3A:
	add	sp, #0x14                              @ 08004C3A
	pop	{r3, r4, r5}                           @ 08004C3C
	mov	r8, r3                                 @ 08004C3E
	mov	sb, r4                                 @ 08004C40
	mov	sl, r5                                 @ 08004C42
	pop	{r4, r5, r6, r7}                       @ 08004C44
	pop	{r0}                                   @ 08004C46
	bx	r0                                      @ 08004C48
	.hword	0x0000                              @ 08004C4A  (padding)
.Llit08004C4C:
	.word	gmpMixerCode                         @ 08004C4C
.Llit08004C50:
	.word	gmpRowLeft                           @ 08004C50
.Llit08004C54:
	.word	gmpTickLeft                          @ 08004C54
@ --------------------------------------------------------------------------
@ gmpPlayNote(player, ins, note, channel)  (0x08004C58)
@   Starts module sample ins at step index note on channel 0..5.  Pinball uses it for its
@   sound effects: gmpPlayNote(&sfxPlayer, ins, 0x93, 5) plays from a separate module on the
@   second SFX channel, using its own player structure.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpPlayNote
gmpPlayNote:
	push	{r4, r5, r6, lr}                      @ 08004C58
	adds	r6, r0, #0                            @ 08004C5A
	lsls	r1, r1, #0x10                         @ 08004C5C
	lsrs	r4, r1, #0x10                         @ 08004C5E
	lsls	r2, r2, #0x10                         @ 08004C60
	lsrs	r5, r2, #0x10                         @ 08004C62
	lsls	r3, r3, #0x10                         @ 08004C64
	lsrs	r3, r3, #0x10                         @ 08004C66
	cmp	r3, #5                                 @ 08004C68
	bhi	.L08004CCC                             @ 08004C6A
	lsls	r0, r3, #4                            @ 08004C6C
	subs	r0, r0, r3                            @ 08004C6E
	lsls	r0, r0, #2                            @ 08004C70
	ldr	r1, .Llit08004CD4                      @ 08004C72  =gmpChan
	adds	r3, r0, r1                            @ 08004C74
	ldr	r2, [r6]                               @ 08004C76
	ldr	r0, .Llit08004CD8                      @ 08004C78  =0x0000FFFF
	cmp	r5, r0                                 @ 08004C7A
	beq	.L08004CCC                             @ 08004C7C
	cmp	r4, #0                                 @ 08004C7E
	beq	.L08004C8A                             @ 08004C80
	subs	r1, r4, #1                            @ 08004C82
	lsls	r0, r1, #0x10                         @ 08004C84
	lsrs	r4, r0, #0x10                         @ 08004C86
	strh	r1, [r3, #0x18]                       @ 08004C88
.L08004C8A:
	lsls	r1, r4, #1                            @ 08004C8A
	adds	r1, r1, r4                            @ 08004C8C
	lsls	r1, r1, #2                            @ 08004C8E
	movs	r0, #0x97                             @ 08004C90
	lsls	r0, r0, #3                            @ 08004C92
	adds	r1, r1, r0                            @ 08004C94
	adds	r1, r2, r1                            @ 08004C96
	lsls	r2, r4, #2                            @ 08004C98
	movs	r4, #0x82                             @ 08004C9A
	lsls	r4, r4, #1                            @ 08004C9C
	adds	r0, r6, r4                            @ 08004C9E
	adds	r0, r0, r2                            @ 08004CA0
	ldr	r0, [r0]                               @ 08004CA2
	str	r0, [r3]                               @ 08004CA4
	ldrh	r0, [r1]                              @ 08004CA6
	movs	r2, #0                                @ 08004CA8
	strh	r0, [r3, #0xc]                        @ 08004CAA
	ldrh	r0, [r1, #6]                          @ 08004CAC
	strh	r0, [r3, #0xe]                        @ 08004CAE
	ldrh	r0, [r1, #8]                          @ 08004CB0
	strh	r0, [r3, #0x10]                       @ 08004CB2
	ldrh	r0, [r1, #4]                          @ 08004CB4
	str	r0, [r3, #0x14]                        @ 08004CB6
	strh	r5, [r3, #0x1e]                       @ 08004CB8
	str	r2, [r3, #4]                           @ 08004CBA
	strh	r2, [r3, #0x1c]                       @ 08004CBC
	strh	r2, [r3, #0x2c]                       @ 08004CBE
	ldr	r0, .Llit08004CDC                      @ 08004CC0  =gmpStepTab
	ldr	r1, [r0]                               @ 08004CC2  gmpStepTab
	lsls	r0, r5, #2                            @ 08004CC4
	adds	r0, r0, r1                            @ 08004CC6
	ldr	r0, [r0]                               @ 08004CC8
	str	r0, [r3, #8]                           @ 08004CCA
.L08004CCC:
	pop	{r4, r5, r6}                           @ 08004CCC
	pop	{r0}                                   @ 08004CCE
	bx	r0                                      @ 08004CD0
	.hword	0x0000                              @ 08004CD2  (padding)
.Llit08004CD4:
	.word	gmpChan                              @ 08004CD4
.Llit08004CD8:
	.word	0x0000FFFF                           @ 08004CD8
.Llit08004CDC:
	.word	gmpStepTab                           @ 08004CDC
@ --------------------------------------------------------------------------
@ gmpProcessTick()  (0x08004CE0)
@   For the 4 music channels:  switch (CH_tickFx) {         (jump table at 0x083C2848)
@    0 arpeggio: if (gmpArpTick) step = gmpStepTab[note + 2 * (fine + vib + (gmpArpTick == 1 ? x : y))]
@                -- overwritten by the common code below, so arpeggio has no effect
@    1/2 CH_portaOfs += CH_portaStep       3 tone porta (steps compared with steps: works)
@    4 vibrato: if (!gmpTick) pos = 0; ofs = sine[pos] * depth >> 8; pos = (pos + speed) & 63
@    0xA volume slide: if (gmpTick) { if (up & down) goto next_channel_without_advancing;
@                vol += up ? up : -down; clamp 0..64 }  5, 6: nothing (unsupported) }
@   common: i = note + fine + vibOfs / 2; if (i < 0) i = 0; if (i > 296) i = 576;
@           CH_step = gmpStepTab[i] + CH_portaOfs
@   next_channel: ch++                                       (0x08004E64)
@   gmpTick++; if (++gmpArpTick == 3) gmpArpTick = 1
@   Two bugs in the common part and the slide:
@    - the clamp writes 576 instead of 296, reading far past the 296-entry step table
@      (only reached by very high notes with vibrato)
@    - Axy with (x & y) != 0 jumps past the "ch++" at 0x08004E64: the same channel is processed
@      again in place of the next one.  Pinball has A15 six times.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpProcessTick
gmpProcessTick:
	push	{r4, r5, r6, lr}                      @ 08004CE0
	ldr	r4, .Llit08004CF8                      @ 08004CE2  =gmpChan
	movs	r6, #0                                @ 08004CE4
.L08004CE6:
	ldr	r0, [r4, #0x20]                        @ 08004CE6
	cmp	r0, #0xa                               @ 08004CE8
	bls	.L08004CEE                             @ 08004CEA
	b	.L08004E2E                               @ 08004CEC
.L08004CEE:
	lsls	r0, r0, #2                            @ 08004CEE
	ldr	r1, .Llit08004CFC                      @ 08004CF0  =0x083C2848
	adds	r0, r0, r1                            @ 08004CF2
	ldr	r0, [r0]                               @ 08004CF4
	mov	pc, r0                                 @ 08004CF6  switch (CH_tickFx)
.Llit08004CF8:
	.word	gmpChan                              @ 08004CF8
.Llit08004CFC:
	.word	0x083C2848                           @ 08004CFC
.L08004D00:
	ldr	r0, .Llit08004D20                      @ 08004D00  =gmpArpTick
	movs	r1, #0                                @ 08004D02
	ldrsh	r0, [r0, r1]                         @ 08004D04
	cmp	r0, #0                                 @ 08004D06
	bne	.L08004D0C                             @ 08004D08
	b	.L08004E2E                               @ 08004D0A
.L08004D0C:
	ldrh	r1, [r4, #0x28]                       @ 08004D0C
	ldrh	r2, [r4, #0x2a]                       @ 08004D0E
	cmp	r0, #1                                 @ 08004D10
	bne	.L08004D24                             @ 08004D12
	movs	r2, #0x2c                             @ 08004D14
	ldrsh	r0, [r4, r2]                         @ 08004D16
	ldrh	r2, [r4, #0x1c]                       @ 08004D18
	adds	r0, r2, r0                            @ 08004D1A
	adds	r0, r0, r1                            @ 08004D1C
	b	.L08004D2E                               @ 08004D1E
.Llit08004D20:
	.word	gmpArpTick                           @ 08004D20
.L08004D24:
	movs	r1, #0x2c                             @ 08004D24
	ldrsh	r0, [r4, r1]                         @ 08004D26
	ldrh	r1, [r4, #0x1c]                       @ 08004D28
	adds	r0, r1, r0                            @ 08004D2A
	adds	r0, r0, r2                            @ 08004D2C
.L08004D2E:
	lsls	r0, r0, #1                            @ 08004D2E
	ldrh	r2, [r4, #0x1e]                       @ 08004D30
	adds	r0, r2, r0                            @ 08004D32
	ldr	r1, .Llit08004D44                      @ 08004D34  =gmpStepTab
	ldr	r1, [r1]                               @ 08004D36  gmpStepTab
	lsls	r0, r0, #2                            @ 08004D38
	adds	r0, r0, r1                            @ 08004D3A
	ldr	r0, [r0]                               @ 08004D3C
	str	r0, [r4, #8]                           @ 08004D3E  arpeggio step, overwritten at 0x08004E62
	b	.L08004E2E                               @ 08004D40
	.hword	0x0000                              @ 08004D42  (padding)
.Llit08004D44:
	.word	gmpStepTab                           @ 08004D44
.L08004D48:
	ldrh	r1, [r4, #0x34]                       @ 08004D48
	ldrh	r2, [r4, #0x38]                       @ 08004D4A
	adds	r0, r1, r2                            @ 08004D4C
	strh	r0, [r4, #0x34]                       @ 08004D4E
	b	.L08004E2E                               @ 08004D50
.L08004D52:
	ldrh	r0, [r4, #0x38]                       @ 08004D52
	ldrh	r2, [r4, #0x34]                       @ 08004D54
	adds	r1, r0, r2                            @ 08004D56
	movs	r5, #0                                @ 08004D58
	strh	r1, [r4, #0x34]                       @ 08004D5A
	lsls	r0, r0, #0x10                         @ 08004D5C
	cmp	r0, #0                                 @ 08004D5E
	ble	.L08004D88                             @ 08004D60
	ldr	r0, .Llit08004D84                      @ 08004D62  =gmpStepTab
	ldr	r3, [r0]                               @ 08004D64  gmpStepTab
	ldrh	r1, [r4, #0x1e]                       @ 08004D66
	lsls	r0, r1, #2                            @ 08004D68
	adds	r0, r0, r3                            @ 08004D6A
	movs	r2, #0x34                             @ 08004D6C
	ldrsh	r1, [r4, r2]                         @ 08004D6E
	ldr	r2, [r0]                               @ 08004D70
	adds	r2, r2, r1                            @ 08004D72
	movs	r1, #0x3a                             @ 08004D74
	ldrsh	r0, [r4, r1]                         @ 08004D76
	lsls	r0, r0, #2                            @ 08004D78
	adds	r0, r0, r3                            @ 08004D7A
	ldr	r0, [r0]                               @ 08004D7C
	cmp	r2, r0                                 @ 08004D7E
	blo	.L08004E2E                             @ 08004D80
	b	.L08004DA8                               @ 08004D82
.Llit08004D84:
	.word	gmpStepTab                           @ 08004D84
.L08004D88:
	ldr	r0, .Llit08004DB4                      @ 08004D88  =gmpStepTab
	ldr	r3, [r0]                               @ 08004D8A  gmpStepTab
	ldrh	r2, [r4, #0x1e]                       @ 08004D8C
	lsls	r0, r2, #2                            @ 08004D8E
	adds	r0, r0, r3                            @ 08004D90
	movs	r2, #0x34                             @ 08004D92
	ldrsh	r1, [r4, r2]                         @ 08004D94
	ldr	r2, [r0]                               @ 08004D96
	adds	r2, r2, r1                            @ 08004D98
	movs	r1, #0x3a                             @ 08004D9A
	ldrsh	r0, [r4, r1]                         @ 08004D9C
	lsls	r0, r0, #2                            @ 08004D9E
	adds	r0, r0, r3                            @ 08004DA0
	ldr	r0, [r0]                               @ 08004DA2
	cmp	r2, r0                                 @ 08004DA4
	bhi	.L08004E2E                             @ 08004DA6
.L08004DA8:
	ldrh	r0, [r4, #0x3a]                       @ 08004DA8
	strh	r0, [r4, #0x1e]                       @ 08004DAA
	strh	r5, [r4, #0x38]                       @ 08004DAC
	strh	r5, [r4, #0x34]                       @ 08004DAE
	b	.L08004E2E                               @ 08004DB0
	.hword	0x0000                              @ 08004DB2  (padding)
.Llit08004DB4:
	.word	gmpStepTab                           @ 08004DB4
.L08004DB8:
	ldr	r0, .Llit08004DE8                      @ 08004DB8  =gmpTick
	movs	r2, #0                                @ 08004DBA
	ldrsh	r0, [r0, r2]                         @ 08004DBC
	cmp	r0, #0                                 @ 08004DBE
	bne	.L08004DC4                             @ 08004DC0
	strh	r0, [r4, #0x32]                       @ 08004DC2
.L08004DC4:
	ldr	r1, .Llit08004DEC                      @ 08004DC4  =gmpVibratoSine
	ldrh	r2, [r4, #0x32]                       @ 08004DC6
	lsls	r0, r2, #1                            @ 08004DC8
	adds	r0, r0, r1                            @ 08004DCA
	movs	r1, #0                                @ 08004DCC
	ldrsh	r0, [r0, r1]                         @ 08004DCE
	ldrh	r2, [r4, #0x2e]                       @ 08004DD0
	muls	r0, r2, r0                            @ 08004DD2
	asrs	r0, r0, #8                            @ 08004DD4
	strh	r0, [r4, #0x2c]                       @ 08004DD6
	ldrh	r1, [r4, #0x32]                       @ 08004DD8
	ldrh	r2, [r4, #0x30]                       @ 08004DDA
	adds	r0, r1, r2                            @ 08004DDC
	movs	r1, #0x3f                             @ 08004DDE
	ands	r0, r1                                @ 08004DE0
	strh	r0, [r4, #0x32]                       @ 08004DE2
	b	.L08004E2E                               @ 08004DE4
	.hword	0x0000                              @ 08004DE6  (padding)
.Llit08004DE8:
	.word	gmpTick                              @ 08004DE8
.Llit08004DEC:
	.word	gmpVibratoSine                       @ 08004DEC
.L08004DF0:
	ldr	r0, .Llit08004E10                      @ 08004DF0  =gmpTick
	movs	r1, #0                                @ 08004DF2
	ldrsh	r0, [r0, r1]                         @ 08004DF4
	cmp	r0, #0                                 @ 08004DF6
	beq	.L08004E2E                             @ 08004DF8
	ldrh	r1, [r4, #0x24]                       @ 08004DFA
	ldrh	r2, [r4, #0x26]                       @ 08004DFC
	adds	r0, r1, #0                            @ 08004DFE
	ands	r0, r2                                @ 08004E00
	cmp	r0, #0                                 @ 08004E02
	bne	.L08004E66                             @ 08004E04  x & y != 0: skips the ch++ below
	cmp	r1, #0                                 @ 08004E06
	beq	.L08004E14                             @ 08004E08
	ldr	r0, [r4, #0x14]                        @ 08004E0A
	adds	r0, r0, r1                            @ 08004E0C
	b	.L08004E18                               @ 08004E0E
.Llit08004E10:
	.word	gmpTick                              @ 08004E10
.L08004E14:
	ldr	r0, [r4, #0x14]                        @ 08004E14
	subs	r0, r0, r2                            @ 08004E16
.L08004E18:
	str	r0, [r4, #0x14]                        @ 08004E18
	ldr	r0, [r4, #0x14]                        @ 08004E1A
	cmp	r0, #0                                 @ 08004E1C
	bge	.L08004E24                             @ 08004E1E
	movs	r0, #0                                @ 08004E20
	str	r0, [r4, #0x14]                        @ 08004E22
.L08004E24:
	ldr	r0, [r4, #0x14]                        @ 08004E24
	cmp	r0, #0x40                              @ 08004E26
	ble	.L08004E2E                             @ 08004E28
	movs	r0, #0x40                             @ 08004E2A
	str	r0, [r4, #0x14]                        @ 08004E2C
.L08004E2E:
	ldrh	r2, [r4, #0x1c]                       @ 08004E2E
	ldrh	r1, [r4, #0x1e]                       @ 08004E30
	adds	r0, r2, r1                            @ 08004E32
	movs	r2, #0x2c                             @ 08004E34
	ldrsh	r1, [r4, r2]                         @ 08004E36
	lsrs	r2, r1, #0x1f                         @ 08004E38
	adds	r1, r1, r2                            @ 08004E3A
	asrs	r1, r1, #1                            @ 08004E3C
	adds	r2, r0, r1                            @ 08004E3E
	cmp	r2, #0                                 @ 08004E40
	bge	.L08004E46                             @ 08004E42
	movs	r2, #0                                @ 08004E44
.L08004E46:
	movs	r0, #0x94                             @ 08004E46
	lsls	r0, r0, #1                            @ 08004E48
	cmp	r2, r0                                 @ 08004E4A
	ble	.L08004E52                             @ 08004E4C
	movs	r2, #0x90                             @ 08004E4E  clamp: 576, not 296
	lsls	r2, r2, #2                            @ 08004E50
.L08004E52:
	ldr	r0, .Llit08004E90                      @ 08004E52  =gmpStepTab
	ldr	r1, [r0]                               @ 08004E54  gmpStepTab
	lsls	r0, r2, #2                            @ 08004E56
	adds	r0, r0, r1                            @ 08004E58
	movs	r2, #0x34                             @ 08004E5A
	ldrsh	r1, [r4, r2]                         @ 08004E5C
	ldr	r0, [r0]                               @ 08004E5E
	adds	r0, r0, r1                            @ 08004E60
	str	r0, [r4, #8]                           @ 08004E62
	adds	r4, #0x3c                             @ 08004E64  next channel
.L08004E66:
	adds	r6, #1                                @ 08004E66
	cmp	r6, #3                                 @ 08004E68
	bgt	.L08004E6E                             @ 08004E6A
	b	.L08004CE6                               @ 08004E6C
.L08004E6E:
	ldr	r1, .Llit08004E94                      @ 08004E6E  =gmpTick
	ldrh	r0, [r1]                              @ 08004E70  gmpTick
	adds	r0, #1                                @ 08004E72
	strh	r0, [r1]                              @ 08004E74  gmpTick
	ldr	r1, .Llit08004E98                      @ 08004E76  =gmpArpTick
	ldrh	r0, [r1]                              @ 08004E78  gmpArpTick
	adds	r0, #1                                @ 08004E7A
	strh	r0, [r1]                              @ 08004E7C  gmpArpTick
	lsls	r0, r0, #0x10                         @ 08004E7E
	asrs	r0, r0, #0x10                         @ 08004E80
	cmp	r0, #3                                 @ 08004E82
	bne	.L08004E8A                             @ 08004E84
	movs	r0, #1                                @ 08004E86
	strh	r0, [r1]                              @ 08004E88  gmpArpTick
.L08004E8A:
	pop	{r4, r5, r6}                           @ 08004E8A
	pop	{r0}                                   @ 08004E8C
	bx	r0                                      @ 08004E8E
.Llit08004E90:
	.word	gmpStepTab                           @ 08004E90
.Llit08004E94:
	.word	gmpTick                              @ 08004E94
.Llit08004E98:
	.word	gmpArpTick                           @ 08004E98
@ --------------------------------------------------------------------------
@ gmpRowEffects(cell, ch, empty)  (0x08004E9C)
@   cell = {u16 ins << 9 | note, u16 cmd << 8 | par}; note is a step-table index (8 = C-1)
@   3xx: target, no retrigger.  CH_tickFx = -1; CH_vibOfs = 0; note-on as in v2 but the step is
@   gmpStepTab[note + fine + vib/2] + CH_portaOfs.
@   switch (cmd) {                                   (jump table at 0x083C2874)
@    0 arpeggio (x, y stored raw)   1 CH_portaStep = par * gmpPortaScale (4)   2 = -par * 4
@    3 tone porta: speed = par * gmpTonePortaScale (40), direction from the target step
@    4 vibrato     A volume slide    B order jump (xx - 1, then the row end adds 1), jingle end
@    C volume     D next order, row xx (hex, not BCD; no song-length check)
@    F xx < 32: speed (gmpRowLen = rate * xx / 50), else gmpRowLen = xx * 2 / 5 -- a BPM
@      parameter gives a row a few dozen samples long; Pinball only uses speeds
@    5, 6, 7, 8, 9, E: nothing }
@   Pinball's modules use 6xy 1 002 times, 9xx 36 times and E9x 364 times; all are ignored.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpRowEffects
gmpRowEffects:
	push	{r4, r5, r6, r7, lr}                  @ 08004E9C
	adds	r4, r0, #0                            @ 08004E9E
	adds	r3, r1, #0                            @ 08004EA0
	ldr	r0, .Llit08004EB4                      @ 08004EA2  =gmpPlayer
	ldr	r5, [r0]                               @ 08004EA4  gmpPlayer
	cmp	r2, #0                                 @ 08004EA6
	beq	.L08004EBC                             @ 08004EA8
	movs	r2, #0                                @ 08004EAA
	ldr	r7, .Llit08004EB8                      @ 08004EAC  =0x000001FF
	movs	r4, #0                                @ 08004EAE
	b	.L08004ECA                               @ 08004EB0
	.hword	0x0000                              @ 08004EB2  (padding)
.Llit08004EB4:
	.word	gmpPlayer                            @ 08004EB4
.Llit08004EB8:
	.word	0x000001FF                           @ 08004EB8
.L08004EBC:
	ldrh	r1, [r4]                              @ 08004EBC
	lsrs	r2, r1, #9                            @ 08004EBE
	movs	r0, #0x1f                             @ 08004EC0
	ands	r2, r0                                @ 08004EC2
	ldr	r7, .Llit08004FC4                      @ 08004EC4  =0x000001FF
	ands	r7, r1                                @ 08004EC6
	ldrh	r4, [r4, #2]                          @ 08004EC8
.L08004ECA:
	movs	r0, #0xf0                             @ 08004ECA
	lsls	r0, r0, #4                            @ 08004ECC
	ands	r0, r4                                @ 08004ECE
	movs	r1, #0xc0                             @ 08004ED0
	lsls	r1, r1, #2                            @ 08004ED2
	cmp	r0, r1                                 @ 08004ED4
	bne	.L08004EFA                             @ 08004ED6
	ldr	r0, .Llit08004FC4                      @ 08004ED8  =0x000001FF
	cmp	r7, r0                                 @ 08004EDA
	beq	.L08004EE0                             @ 08004EDC
	strh	r7, [r3, #0x3a]                       @ 08004EDE
.L08004EE0:
	adds	r7, r0, #0                            @ 08004EE0
	cmp	r2, #0                                 @ 08004EE2
	beq	.L08004EF8                             @ 08004EE4
	subs	r0, r2, #1                            @ 08004EE6
	lsls	r1, r0, #1                            @ 08004EE8
	adds	r1, r1, r0                            @ 08004EEA
	lsls	r1, r1, #2                            @ 08004EEC
	adds	r1, r5, r1                            @ 08004EEE
	ldr	r0, .Llit08004FC8                      @ 08004EF0  =0x000004BC
	adds	r1, r1, r0                            @ 08004EF2
	ldrh	r0, [r1]                              @ 08004EF4
	str	r0, [r3, #0x14]                        @ 08004EF6
.L08004EF8:
	movs	r2, #0                                @ 08004EF8
.L08004EFA:
	lsrs	r6, r4, #8                            @ 08004EFA
	movs	r0, #1                                @ 08004EFC
	rsbs	r0, r0, #0                            @ 08004EFE
	str	r0, [r3, #0x20]                        @ 08004F00
	movs	r1, #0                                @ 08004F02
	mov	ip, r1                                 @ 08004F04
	mov	r0, ip                                 @ 08004F06
	strh	r0, [r3, #0x2c]                       @ 08004F08
	ldr	r0, .Llit08004FC4                      @ 08004F0A  =0x000001FF
	cmp	r7, r0                                 @ 08004F0C
	beq	.L08004FD4                             @ 08004F0E
	cmp	r2, #0                                 @ 08004F10
	beq	.L08004F2A                             @ 08004F12
	subs	r0, r2, #1                            @ 08004F14
	strh	r0, [r3, #0x18]                       @ 08004F16
	lsls	r0, r0, #1                            @ 08004F18
	ldrh	r1, [r3, #0x18]                       @ 08004F1A
	adds	r0, r0, r1                            @ 08004F1C
	lsls	r0, r0, #2                            @ 08004F1E
	adds	r0, r5, r0                            @ 08004F20
	ldr	r2, .Llit08004FC8                      @ 08004F22  =0x000004BC
	adds	r0, r0, r2                            @ 08004F24
	ldrh	r0, [r0]                              @ 08004F26
	str	r0, [r3, #0x14]                        @ 08004F28
.L08004F2A:
	ldr	r0, .Llit08004FCC                      @ 08004F2A  =gmpPlayer
	ldrh	r2, [r3, #0x18]                       @ 08004F2C
	lsls	r1, r2, #2                            @ 08004F2E
	movs	r2, #0x82                             @ 08004F30
	lsls	r2, r2, #1                            @ 08004F32
	adds	r0, r0, r2                            @ 08004F34
	adds	r1, r1, r0                            @ 08004F36
	ldr	r0, [r1]                               @ 08004F38
	str	r0, [r3]                               @ 08004F3A
	ldrh	r1, [r3, #0x18]                       @ 08004F3C
	lsls	r0, r1, #1                            @ 08004F3E
	adds	r0, r0, r1                            @ 08004F40
	lsls	r0, r0, #2                            @ 08004F42
	adds	r0, r5, r0                            @ 08004F44
	movs	r2, #0x97                             @ 08004F46
	lsls	r2, r2, #3                            @ 08004F48
	adds	r0, r0, r2                            @ 08004F4A
	ldrh	r0, [r0]                              @ 08004F4C
	strh	r0, [r3, #0xc]                        @ 08004F4E
	lsls	r0, r1, #1                            @ 08004F50
	adds	r0, r0, r1                            @ 08004F52
	lsls	r0, r0, #2                            @ 08004F54
	adds	r0, r5, r0                            @ 08004F56
	adds	r2, #6                                @ 08004F58
	adds	r0, r0, r2                            @ 08004F5A
	ldrh	r0, [r0]                              @ 08004F5C
	strh	r0, [r3, #0xe]                        @ 08004F5E
	lsls	r0, r1, #1                            @ 08004F60
	adds	r0, r0, r1                            @ 08004F62
	lsls	r0, r0, #2                            @ 08004F64
	adds	r0, r5, r0                            @ 08004F66
	adds	r2, #2                                @ 08004F68
	adds	r0, r0, r2                            @ 08004F6A
	ldrh	r0, [r0]                              @ 08004F6C
	strh	r0, [r3, #0x10]                       @ 08004F6E
	lsls	r0, r1, #1                            @ 08004F70
	adds	r0, r0, r1                            @ 08004F72
	lsls	r0, r0, #2                            @ 08004F74
	adds	r0, r5, r0                            @ 08004F76
	subs	r2, #6                                @ 08004F78
	adds	r0, r0, r2                            @ 08004F7A
	ldrh	r0, [r0]                              @ 08004F7C
	strh	r0, [r3, #0x1c]                       @ 08004F7E
	strh	r7, [r3, #0x1e]                       @ 08004F80
	mov	r0, ip                                 @ 08004F82
	str	r0, [r3, #4]                           @ 08004F84
	ldrh	r1, [r3, #0x1c]                       @ 08004F86
	adds	r2, r1, r7                            @ 08004F88
	movs	r1, #0x2c                             @ 08004F8A
	ldrsh	r0, [r3, r1]                         @ 08004F8C
	lsrs	r1, r0, #0x1f                         @ 08004F8E
	adds	r0, r0, r1                            @ 08004F90
	asrs	r0, r0, #1                            @ 08004F92
	adds	r2, r2, r0                            @ 08004F94
	cmp	r2, #0                                 @ 08004F96
	bge	.L08004F9C                             @ 08004F98
	movs	r2, #0                                @ 08004F9A
.L08004F9C:
	movs	r0, #0x94                             @ 08004F9C
	lsls	r0, r0, #1                            @ 08004F9E
	cmp	r2, r0                                 @ 08004FA0
	ble	.L08004FA8                             @ 08004FA2
	movs	r2, #0x90                             @ 08004FA4
	lsls	r2, r2, #2                            @ 08004FA6
.L08004FA8:
	ldr	r0, .Llit08004FD0                      @ 08004FA8  =gmpStepTab
	ldr	r1, [r0]                               @ 08004FAA  gmpStepTab
	lsls	r0, r2, #2                            @ 08004FAC
	adds	r0, r0, r1                            @ 08004FAE
	movs	r2, #0x34                             @ 08004FB0
	ldrsh	r1, [r3, r2]                         @ 08004FB2
	ldr	r0, [r0]                               @ 08004FB4
	adds	r0, r0, r1                            @ 08004FB6
	str	r0, [r3, #8]                           @ 08004FB8
	cmp	r6, #3                                 @ 08004FBA
	beq	.L08005004                             @ 08004FBC
	mov	r0, ip                                 @ 08004FBE
	strh	r0, [r3, #0x34]                       @ 08004FC0
	b	.L08005004                               @ 08004FC2
.Llit08004FC4:
	.word	0x000001FF                           @ 08004FC4
.Llit08004FC8:
	.word	0x000004BC                           @ 08004FC8
.Llit08004FCC:
	.word	gmpPlayer                            @ 08004FCC
.Llit08004FD0:
	.word	gmpStepTab                           @ 08004FD0
.L08004FD4:
	cmp	r2, #0                                 @ 08004FD4
	beq	.L08005004                             @ 08004FD6
	subs	r0, r2, #1                            @ 08004FD8
	strh	r0, [r3, #0x18]                       @ 08004FDA
	ldr	r0, .Llit08005014                      @ 08004FDC  =gmpPlayer
	ldrh	r2, [r3, #0x18]                       @ 08004FDE
	lsls	r1, r2, #2                            @ 08004FE0
	movs	r2, #0x82                             @ 08004FE2
	lsls	r2, r2, #1                            @ 08004FE4
	adds	r0, r0, r2                            @ 08004FE6
	adds	r1, r1, r0                            @ 08004FE8
	ldr	r0, [r1]                               @ 08004FEA
	str	r0, [r3]                               @ 08004FEC
	ldrh	r1, [r3, #0x18]                       @ 08004FEE
	lsls	r0, r1, #1                            @ 08004FF0
	adds	r0, r0, r1                            @ 08004FF2
	lsls	r0, r0, #2                            @ 08004FF4
	adds	r0, r5, r0                            @ 08004FF6
	ldr	r2, .Llit08005018                      @ 08004FF8  =0x000004BC
	adds	r0, r0, r2                            @ 08004FFA
	ldrh	r0, [r0]                              @ 08004FFC
	str	r0, [r3, #0x14]                        @ 08004FFE
	mov	r0, ip                                 @ 08005000
	str	r0, [r3, #4]                           @ 08005002
.L08005004:
	cmp	r6, #0xf                               @ 08005004
	bls	.L0800500A                             @ 08005006
	b	.L08005190                               @ 08005008
.L0800500A:
	lsls	r0, r6, #2                            @ 0800500A
	ldr	r1, .Llit0800501C                      @ 0800500C  =0x083C2874
	adds	r0, r0, r1                            @ 0800500E
	ldr	r0, [r0]                               @ 08005010
	mov	pc, r0                                 @ 08005012  switch (cmd)
.Llit08005014:
	.word	gmpPlayer                            @ 08005014
.Llit08005018:
	.word	0x000004BC                           @ 08005018
.Llit0800501C:
	.word	0x083C2874                           @ 0800501C
.L08005020:
	movs	r0, #0xf0                             @ 08005020
	ands	r0, r4                                @ 08005022
	lsrs	r1, r0, #4                            @ 08005024
	movs	r0, #0xf                              @ 08005026
	ands	r0, r4                                @ 08005028
	cmn	r1, r0                                 @ 0800502A
	bne	.L08005030                             @ 0800502C
	b	.L08005190                               @ 0800502E
.L08005030:
	str	r6, [r3, #0x20]                        @ 08005030
	strh	r1, [r3, #0x28]                       @ 08005032
	strh	r0, [r3, #0x2a]                       @ 08005034
	b	.L08005190                               @ 08005036
.L08005038:
	movs	r0, #0xff                             @ 08005038
	str	r6, [r3, #0x20]                        @ 0800503A
	ands	r4, r0                                @ 0800503C
	ldr	r0, .Llit08005048                      @ 0800503E  =gmpPortaScale
	ldrh	r0, [r0]                              @ 08005040  gmpPortaScale
	muls	r0, r4, r0                            @ 08005042
	strh	r0, [r3, #0x38]                       @ 08005044
	b	.L08005190                               @ 08005046
.Llit08005048:
	.word	gmpPortaScale                        @ 08005048
.L0800504C:
	movs	r0, #0xff                             @ 0800504C
	str	r6, [r3, #0x20]                        @ 0800504E
	ands	r4, r0                                @ 08005050
	rsbs	r1, r4, #0                            @ 08005052
	ldr	r0, .Llit08005060                      @ 08005054  =gmpPortaScale
	ldrh	r0, [r0]                              @ 08005056  gmpPortaScale
	muls	r0, r1, r0                            @ 08005058
	strh	r0, [r3, #0x38]                       @ 0800505A
	b	.L08005190                               @ 0800505C
	.hword	0x0000                              @ 0800505E  (padding)
.Llit08005060:
	.word	gmpPortaScale                        @ 08005060
.L08005064:
	movs	r0, #0xff                             @ 08005064
	ands	r4, r0                                @ 08005066
	ldr	r0, .Llit08005090                      @ 08005068  =gmpTonePortaScale
	ldr	r0, [r0]                               @ 0800506A  gmpTonePortaScale
	muls	r0, r4, r0                            @ 0800506C
	lsls	r0, r0, #0x10                         @ 0800506E
	str	r6, [r3, #0x20]                        @ 08005070
	lsrs	r1, r0, #0x10                         @ 08005072
	cmp	r0, #0                                 @ 08005074
	beq	.L0800507A                             @ 08005076
	strh	r1, [r3, #0x36]                       @ 08005078
.L0800507A:
	movs	r2, #0x3a                             @ 0800507A
	ldrsh	r1, [r3, r2]                         @ 0800507C
	ldrh	r0, [r3, #0x1e]                       @ 0800507E
	cmp	r1, r0                                 @ 08005080
	beq	.L0800509C                             @ 08005082
	cmp	r1, r0                                 @ 08005084
	ble	.L08005094                             @ 08005086
	ldrh	r0, [r3, #0x36]                       @ 08005088
	strh	r0, [r3, #0x38]                       @ 0800508A
	b	.L08005190                               @ 0800508C
	.hword	0x0000                              @ 0800508E  (padding)
.Llit08005090:
	.word	gmpTonePortaScale                    @ 08005090
.L08005094:
	ldrh	r1, [r3, #0x36]                       @ 08005094
	rsbs	r0, r1, #0                            @ 08005096
	strh	r0, [r3, #0x38]                       @ 08005098
	b	.L08005190                               @ 0800509A
.L0800509C:
	movs	r0, #0                                @ 0800509C
	strh	r0, [r3, #0x38]                       @ 0800509E
	b	.L08005190                               @ 080050A0
.L080050A2:
	movs	r0, #0xf0                             @ 080050A2
	ands	r0, r4                                @ 080050A4
	lsrs	r1, r0, #4                            @ 080050A6
	movs	r0, #0xf                              @ 080050A8
	ands	r0, r4                                @ 080050AA
	str	r6, [r3, #0x20]                        @ 080050AC
	cmp	r1, #0                                 @ 080050AE
	bne	.L080050B6                             @ 080050B0
	cmp	r0, #0                                 @ 080050B2
	beq	.L08005190                             @ 080050B4
.L080050B6:
	strh	r1, [r3, #0x30]                       @ 080050B6
	strh	r0, [r3, #0x2e]                       @ 080050B8
	b	.L08005190                               @ 080050BA
.L080050BC:
	movs	r0, #0xf0                             @ 080050BC
	ands	r0, r4                                @ 080050BE
	lsrs	r1, r0, #4                            @ 080050C0
	movs	r0, #0xf                              @ 080050C2
	ands	r4, r0                                @ 080050C4
	str	r6, [r3, #0x20]                        @ 080050C6
	strh	r1, [r3, #0x24]                       @ 080050C8
	strh	r4, [r3, #0x26]                       @ 080050CA
	b	.L08005190                               @ 080050CC
.L080050CE:
	ldr	r2, .Llit080050E8                      @ 080050CE  =gmpSkip
	ldr	r0, [r2]                               @ 080050D0  gmpSkip
	cmp	r0, #0                                 @ 080050D2
	beq	.L080050F0                             @ 080050D4
	ldr	r0, .Llit080050EC                      @ 080050D6  =gmpCell
	movs	r3, #0x80                             @ 080050D8
	lsls	r3, r3, #1                            @ 080050DA
	adds	r1, r3, #0                            @ 080050DC
	strh	r1, [r0]                              @ 080050DE  gmpCell
	movs	r0, #0                                @ 080050E0
	str	r0, [r2]                               @ 080050E2  gmpSkip
	b	.L08005190                               @ 080050E4
	.hword	0x0000                              @ 080050E6  (padding)
.Llit080050E8:
	.word	gmpSkip                              @ 080050E8
.Llit080050EC:
	.word	gmpCell                              @ 080050EC
.L080050F0:
	ldr	r0, .Llit08005100                      @ 080050F0  =gmpJingleOn
	ldrb	r0, [r0]                              @ 080050F2  gmpJingleOn
	cmp	r0, #0                                 @ 080050F4
	beq	.L08005104                             @ 080050F6
	bl	gmpEndJingle                            @ 080050F8
	b	.L08005190                               @ 080050FC
	.hword	0x0000                              @ 080050FE  (padding)
.Llit08005100:
	.word	gmpJingleOn                          @ 08005100
.L08005104:
	ldr	r1, .Llit0800511C                      @ 08005104  =gmpOrder
	movs	r0, #0xff                             @ 08005106
	ands	r4, r0                                @ 08005108
	subs	r0, r4, #1                            @ 0800510A
	strh	r0, [r1]                              @ 0800510C  gmpOrder
	ldr	r1, .Llit08005120                      @ 0800510E  =gmpCell
	movs	r2, #0x80                             @ 08005110
	lsls	r2, r2, #1                            @ 08005112
	adds	r0, r2, #0                            @ 08005114
	strh	r0, [r1]                              @ 08005116  gmpCell
	b	.L08005190                               @ 08005118
	.hword	0x0000                              @ 0800511A  (padding)
.Llit0800511C:
	.word	gmpOrder                             @ 0800511C
.Llit08005120:
	.word	gmpCell                              @ 08005120
.L08005124:
	movs	r0, #0xff                             @ 08005124
	ands	r4, r0                                @ 08005126
	str	r4, [r3, #0x14]                        @ 08005128
	b	.L08005190                               @ 0800512A
.L0800512C:
	ldr	r2, .Llit0800514C                      @ 0800512C  =gmpJumped
	ldrb	r0, [r2]                              @ 0800512E  gmpJumped
	cmp	r0, #0                                 @ 08005130
	bne	.L08005190                             @ 08005132
	ldr	r1, .Llit08005150                      @ 08005134  =gmpCell
	movs	r0, #0xff                             @ 08005136
	ands	r4, r0                                @ 08005138
	lsls	r0, r4, #2                            @ 0800513A
	strh	r0, [r1]                              @ 0800513C  gmpCell
	ldr	r1, .Llit08005154                      @ 0800513E  =gmpOrder
	ldrh	r0, [r1]                              @ 08005140  gmpOrder
	adds	r0, #1                                @ 08005142
	strh	r0, [r1]                              @ 08005144  gmpOrder
	movs	r0, #1                                @ 08005146
	strb	r0, [r2]                              @ 08005148  gmpJumped
	b	.L08005190                               @ 0800514A
.Llit0800514C:
	.word	gmpJumped                            @ 0800514C
.Llit08005150:
	.word	gmpCell                              @ 08005150
.Llit08005154:
	.word	gmpOrder                             @ 08005154
.L08005158:
	movs	r1, #0xff                             @ 08005158
	ands	r1, r4                                @ 0800515A
	cmp	r1, #0x1f                              @ 0800515C
	bgt	.L08005184                             @ 0800515E
	ldr	r4, .Llit08005178                      @ 08005160  =gmpRowLen
	ldr	r0, .Llit0800517C                      @ 08005162  =gmpTickLen
	ldr	r0, [r0]                               @ 08005164  gmpTickLen
	muls	r0, r1, r0                            @ 08005166
	str	r0, [r4]                               @ 08005168  gmpRowLen
	ldr	r0, .Llit08005180                      @ 0800516A  =gmpRate
	ldr	r0, [r0]                               @ 0800516C  gmpRate
	muls	r0, r1, r0                            @ 0800516E
	movs	r1, #0x32                             @ 08005170
	bl	__udivsi3                               @ 08005172
	b	.L0800518E                               @ 08005176  speed: rate * xx / 50
.Llit08005178:
	.word	gmpRowLen                            @ 08005178
.Llit0800517C:
	.word	gmpTickLen                           @ 0800517C
.Llit08005180:
	.word	gmpRate                              @ 08005180
.L08005184:
	ldr	r4, .Llit08005198                      @ 08005184  =gmpRowLen
	lsls	r0, r1, #1                            @ 08005186
	movs	r1, #5                                @ 08005188
	bl	__divsi3                                @ 0800518A  BPM: xx * 2 / 5 samples per row
.L0800518E:
	str	r0, [r4]                               @ 0800518E
.L08005190:
	pop	{r4, r5, r6, r7}                       @ 08005190
	pop	{r0}                                   @ 08005192
	bx	r0                                      @ 08005194
	.hword	0x0000                              @ 08005196  (padding)
.Llit08005198:
	.word	gmpRowLen                            @ 08005198
