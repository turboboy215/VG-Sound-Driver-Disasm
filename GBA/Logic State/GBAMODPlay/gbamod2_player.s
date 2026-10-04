@ ============================================================================
@ gbamod2_player.s -- GBAModPlay version 2 (module id "GBAMOD2."), Thumb part
@ Logik State; the game credits "LOGIK STATE".
@
@ Reconstructed from "Aero the Acro-Bat - Rascal Rival Revenge (E).gba", ROM range
@ 0x081036C4-0x08104980 (4 796 bytes).  Rebuilt byte for byte by gbamod2.mk.
@
@ GCC-compiled Thumb, like v3, but all state lives in fixed IWRAM variables (0x030066D0-
@ 0x03006B6C) instead of a host-supplied block.  The ARM mixer and DMA routine are in
@ gbamod2_arm.s, the tables in gbamod2_rodata.s.  The code before 0x081036C4 is Nintendo's
@ EEPROM_V122 library, not part of the player.
@
@ Host integration in Aero:
@   0x0802C61E  gmpInit(0x03005D50); gmpPlaySong(module, 0, 0x0809B410);
@               gmpSetMasterVolume(0); gmpLoadSfxBank(0x080A6040); gmpSoundOn()
@   0x08029702  gmpVBlank() once per frame
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
@ ---- player globals (IWRAM) and ROM symbols
	.equ	gmpPlayer, 0x030066D0                 @ GmpPlayer {module; patPtr[64]; smpPtr[31]} (0x180 bytes)
	.equ	gmpMasterVol, 0x03006850              @ 0..64
	.equ	gmpMusicVol, 0x03006854               @ 0..64
	.equ	gmpSfxVol, 0x03006858                 @ 0..64
	.equ	gmpBuf, 0x03006860                    @ u32[2] mix buffers (IWRAM)
	.equ	gmpCur, 0x03006868                    @ buffer DMA is playing
	.equ	gmpBufFree, 0x03006870                @ u32[2] buffer has been played and may be refilled
	.equ	gmpIwramPtr, 0x03006878               @ IWRAM bump allocator
	.equ	gmpMixer, 0x0300687C                  @ -> mixer copied to IWRAM (0x258 bytes)
	.equ	gmpPatRows, 0x03006880                @ -> module+0x18F4, rows stored per pattern
	.equ	gmpChannels, 0x03006884               @ module channels
	.equ	gmpSpeed, 0x03006888
	.equ	gmpBPM, 0x0300688C
	.equ	gmpRate, 0x03006890                   @ mix rate from the module (21024)
	.equ	gmpLoopMark, 0x03006894               @ u16 E6x state (0xFFFF = none)
	.equ	gmpTickHz, 0x03006898                 @ BPM*2/5
	.equ	gmpStepTab, 0x0300689C                @ -> module+0x1C (u32[976] 20.12 steps)
	.equ	gmpPeriodTab, 0x030068A0              @ -> module+0xF5C (u16[976] periods)
	.equ	gmpOrder, 0x030068A4                  @ u16
	.equ	gmpCell, 0x030068A8                   @ u16 row * channels
	.equ	gmpRowLen, 0x030068AC                 @ samples per row
	.equ	gmpRowLeft, 0x030068B0
	.equ	gmpTickLen, 0x030068B4                @ samples per tick
	.equ	gmpTickLeft, 0x030068B8
	.equ	gmpChan, 0x030068C0                   @ GmpChannel[8] (0x4C bytes): music first, SFX in the last two
	.equ	gmpJumped, 0x03006B20                 @ u8 Bxx/Dxx taken this row
	.equ	gmpTick, 0x03006B24                   @ u16 tick within the row
	.equ	gmpJinglePri, 0x03006B28              @ s16
	.equ	gmpSkipSaved, 0x03006B2C
	.equ	gmpSkip, 0x03006B30                   @ next Bxx goes to the next order
	.equ	gmpQueued, 0x03006B34                 @ queued jingle waiting for a row
	.equ	gmpQueuedSaved, 0x03006B38
	.equ	gmpDmaOn, 0x03006B3C
	.equ	gmpPriSaved, 0x03006B40               @ u16
	.equ	gmpJingleOn, 0x03006B44               @ u8
	.equ	gmpReturnOrder, 0x03006B48            @ u16 order to resume after the jingle
	.equ	gmpQueuedPri, 0x03006B4C
	.equ	gmpQueuedOrder, 0x03006B50
	.equ	gmpPauseAfterJingleFlag, 0x03006B54
	.equ	gmpPaused, 0x03006B58
	.equ	gmpArpTick, 0x03006B5C                @ u16
	.equ	gmpSfxCount, 0x03006B60
	.equ	gmpSfxEntries, 0x03006B64             @ 20-byte entries
	.equ	gmpSfxData, 0x03006B68
	.equ	gmpVibratoSine, 0x08356E5C            @ s16[64] sine, +-255
	.equ	gmpAmigaPeriods, 0x08356EDC           @ u16[960], never referenced
	.equ	gmpBufBytes, 0x08357AB0               @ const u32 352 = samples per frame
	.equ	gmpDmaRestartAB, 0x08104980           @ Thumb->ARM
	.equ	gmpCallR3, 0x081049C0                 @ bx r3
	.equ	gmpMixChannelRom, 0x081049E4          @ ARM mixer (copied to IWRAM)
	.equ	memcpy, 0x08104B00                    @ libc
	.equ	memset, 0x08104B64                    @ libc
	.equ	__divsi3, 0x08104BF8                  @ libgcc
	.equ	__udivsi3, 0x08104D60                 @ libgcc
@ ---- GmpChannel (0x4C bytes, gmpChan[8])
	.equ	CH_ptr, 0x0
	.equ	CH_pos, 0x4                           @ 20.12
	.equ	CH_step, 0x8                          @ 20.12
	.equ	CH_end, 0xC                           @ u16 length; 2 = stopped
	.equ	CH_loopStart, 0xE                     @ u16, added once
	.equ	CH_loopLen, 0x10                      @ u16
	.equ	CH_vol, 0x14                          @ 0..64
	.equ	CH_ins, 0x18                          @ u16
	.equ	CH_fine, 0x1C                         @ u16
	.equ	CH_note, 0x1E                         @ u16 period-table index
	.equ	CH_tickFx, 0x20                       @ -1 none
	.equ	CH_vsUp, 0x24                         @ u16
	.equ	CH_vsDown, 0x26                       @ u16
	.equ	CH_arpX, 0x28                         @ u16 x*8
	.equ	CH_arpY, 0x2A                         @ u16 y*8
	.equ	CH_vibOfs, 0x2C                       @ s16
	.equ	CH_vibDepth, 0x2E                     @ u16
	.equ	CH_vibSpeed, 0x30                     @ u16
	.equ	CH_vibPos, 0x32                       @ u16
	.equ	CH_portaOfs, 0x34                     @ s16 period offset
	.equ	CH_tpSpeed, 0x36                      @ u16
	.equ	CH_portaStep, 0x38                    @ s16
	.equ	CH_tpTarget, 0x3A                     @ u16

	.section .text.gmp2_player, "ax", %progbits
	.balign 4
@ --------------------------------------------------------------------------
@ gmpWaitLine(n) / gmpWaitLineLeave(n)  (0x081036C4, 0x081036D0)
@   while (*(u16 *)r2 != n) ;   /   while (*(u16 *)r2 == n) ;
@   The VCOUNT address never gets loaded: the loop reads through whatever r2 holds.
@   gmpStartDma calls gmpWaitLineLeave(0x3E/0x3D) with r2 = 0xFCE2 (the timer reload it has
@   just written), so it reads address 0x0000FCE2 in the BIOS.  Read from ROM code, the BIOS
@   returns its protected open-bus value, not 0x3E/0x3D, so the scanline wait does nothing.  (v1 used a correct assembler routine; v3 reads DISPCNT.)
@ --------------------------------------------------------------------------
	.thumb
	.thumb_func
	.global gmpWaitLine
gmpWaitLine:
	adds	r1, r0, #0                            @ 081036C4
.L081036C6:
	ldrh	r0, [r2]                              @ 081036C6
	cmp	r0, r1                                 @ 081036C8
	bne	.L081036C6                             @ 081036CA
	bx	lr                                      @ 081036CC
	.hword	0x0000                              @ 081036CE  (padding)
	.thumb_func
	.global gmpWaitLineLeave
gmpWaitLineLeave:
	adds	r1, r0, #0                            @ 081036D0
.L081036D2:
	ldrh	r0, [r2]                              @ 081036D2
	cmp	r0, r1                                 @ 081036D4
	beq	.L081036D2                             @ 081036D6
	bx	lr                                      @ 081036D8
	.hword	0x0000                              @ 081036DA  (padding)
@ --------------------------------------------------------------------------
@ gmpStartDma(buffer)  (0x081036DC)
@   Fixed 21024 Hz, both FIFOs from one buffer:
@     DMA1CNT_H = DMA2CNT_H = SOUNDCNT_X = 0; SOUNDCNT_H = 0xFB0E (A on Timer 0, B on Timer 1,
@     both to L+R); DMA1 -> FIFO_A, DMA2 -> FIFO_B, source = buffer
@     TM0 and TM1 reload = 0xFCE2 (16777216 / 798 = 21024 Hz); gmpWaitLineLeave x2 (no effect)
@     DMAxCNT_H = 0xB600; TM0CNT_H = TM1CNT_H = 0x80
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpStartDma
gmpStartDma:
	push	{r4, r5, r6, lr}                      @ 081036DC
	mov	r6, r8                                 @ 081036DE
	push	{r6}                                  @ 081036E0
	ldr	r1, .Llit0810374C                      @ 081036E2  =REG_DMA1CNT_H
	mov	r8, r1                                 @ 081036E4
	movs	r3, #0                                @ 081036E6
	strh	r3, [r1]                              @ 081036E8
	ldr	r6, .Llit08103750                      @ 081036EA  =REG_DMA2CNT_H
	strh	r3, [r6]                              @ 081036EC
	subs	r1, #0x42                             @ 081036EE
	strh	r3, [r1]                              @ 081036F0
	ldr	r2, .Llit08103754                      @ 081036F2  =REG_SOUNDCNT_H
	ldr	r4, .Llit08103758                      @ 081036F4  =0x0000FB0E
	adds	r1, r4, #0                            @ 081036F6
	strh	r1, [r2]                              @ 081036F8  SOUNDCNT_H = 0xFB0E
	ldr	r1, .Llit0810375C                      @ 081036FA  =REG_DMA1SAD
	str	r0, [r1]                               @ 081036FC
	adds	r2, #0x3e                             @ 081036FE
	subs	r1, #0x1c                             @ 08103700
	str	r1, [r2]                               @ 08103702
	adds	r1, #0x28                             @ 08103704
	str	r0, [r1]                               @ 08103706
	adds	r1, #4                                @ 08103708
	ldr	r0, .Llit08103760                      @ 0810370A  =REG_FIFO_B
	str	r0, [r1]                               @ 0810370C
	ldr	r5, .Llit08103764                      @ 0810370E  =REG_TM0CNT_H
	strh	r3, [r5]                              @ 08103710
	ldr	r4, .Llit08103768                      @ 08103712  =REG_TM1CNT_H
	strh	r3, [r4]                              @ 08103714
	adds	r0, #0x5c                             @ 08103716
	ldr	r2, .Llit0810376C                      @ 08103718  =0x0000FCE2
	adds	r1, r2, #0                            @ 0810371A
	strh	r1, [r0]                              @ 0810371C  TM0CNT_L = 0xFCE2 (21024 Hz)
	adds	r0, #4                                @ 0810371E
	strh	r1, [r0]                              @ 08103720  TM1CNT_L = 0xFCE2
	movs	r0, #0x3e                             @ 08103722
	bl	gmpWaitLineLeave                        @ 08103724  r2 = 0xFCE2 here: the wait reads the BIOS area
	movs	r0, #0x3d                             @ 08103728
	bl	gmpWaitLineLeave                        @ 0810372A
	movs	r1, #0xb6                             @ 0810372E
	lsls	r1, r1, #8                            @ 08103730
	adds	r0, r1, #0                            @ 08103732
	mov	r2, r8                                 @ 08103734
	strh	r0, [r2]                              @ 08103736
	strh	r0, [r6]                              @ 08103738
	movs	r0, #0x80                             @ 0810373A
	strh	r0, [r5]                              @ 0810373C
	strh	r0, [r4]                              @ 0810373E
	pop	{r3}                                   @ 08103740
	mov	r8, r3                                 @ 08103742
	pop	{r4, r5, r6}                           @ 08103744
	pop	{r0}                                   @ 08103746
	bx	r0                                      @ 08103748
	.hword	0x0000                              @ 0810374A  (padding)
.Llit0810374C:
	.word	REG_DMA1CNT_H                        @ 0810374C
.Llit08103750:
	.word	REG_DMA2CNT_H                        @ 08103750
.Llit08103754:
	.word	REG_SOUNDCNT_H                       @ 08103754
.Llit08103758:
	.word	0x0000FB0E                           @ 08103758
.Llit0810375C:
	.word	REG_DMA1SAD                          @ 0810375C
.Llit08103760:
	.word	REG_FIFO_B                           @ 08103760
.Llit08103764:
	.word	REG_TM0CNT_H                         @ 08103764
.Llit08103768:
	.word	REG_TM1CNT_H                         @ 08103768
.Llit0810376C:
	.word	0x0000FCE2                           @ 0810376C
@ --------------------------------------------------------------------------
@ gmpPlaySong(module, order, sampleBank)  (0x08103770)
@   gmpClearChannels(); if (gmpLoadModule(&gmpPlayer, module, sampleBank)) gmpStartSong(order)
@   Aero passes the one shared bank at 0x0809B410 with every module.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpPlaySong
gmpPlaySong:
	push	{r4, r5, r6, lr}                      @ 08103770
	adds	r5, r0, #0                            @ 08103772
	adds	r6, r1, #0                            @ 08103774
	adds	r4, r2, #0                            @ 08103776
	bl	gmpClearChannels                        @ 08103778
	ldr	r0, .Llit08103798                      @ 0810377C  =gmpPlayer
	adds	r1, r5, #0                            @ 0810377E
	adds	r2, r4, #0                            @ 08103780
	bl	gmpLoadModule                           @ 08103782
	cmp	r0, #0                                 @ 08103786
	beq	.L08103792                             @ 08103788
	lsls	r0, r6, #0x10                         @ 0810378A
	asrs	r0, r0, #0x10                         @ 0810378C
	bl	gmpStartSong                            @ 0810378E
.L08103792:
	pop	{r4, r5, r6}                           @ 08103792
	pop	{r0}                                   @ 08103794
	bx	r0                                      @ 08103796
.Llit08103798:
	.word	gmpPlayer                            @ 08103798
@ --------------------------------------------------------------------------
@ gmpSoundOff() / gmpSoundOn()  (0x0810379C, 0x081037A8)
@   SOUNDCNT_X = 0 / 0x80
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpSoundOff
gmpSoundOff:
	ldr	r1, .Llit081037A4                      @ 0810379C  =REG_SOUNDCNT_X
	movs	r0, #0                                @ 0810379E
	strh	r0, [r1]                              @ 081037A0
	bx	lr                                      @ 081037A2
.Llit081037A4:
	.word	REG_SOUNDCNT_X                       @ 081037A4
	.thumb_func
	.global gmpSoundOn
gmpSoundOn:
	ldr	r1, .Llit081037B0                      @ 081037A8  =REG_SOUNDCNT_X
	movs	r0, #0x80                             @ 081037AA
	strh	r0, [r1]                              @ 081037AC
	bx	lr                                      @ 081037AE
.Llit081037B0:
	.word	REG_SOUNDCNT_X                       @ 081037B0
@ --------------------------------------------------------------------------
@ gmpSetMasterVolume / gmpSetMusicVolume / gmpSetSfxVolume(v)  (0x081037B4..0x081037CC)
@   0..64.  gmpMix turns them into *attenuations*: music channels play at
@   CH_vol - (64 - min(master, music)), SFX at CH_vol - (64 - min(master, sfx)), floored at 0.
@   So volume 32 does not halve a channel: it removes 32 steps from it.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpSetMasterVolume
gmpSetMasterVolume:
	ldr	r1, .Llit081037BC                      @ 081037B4  =gmpMasterVol
	str	r0, [r1]                               @ 081037B6  gmpMasterVol
	bx	lr                                      @ 081037B8
	.hword	0x0000                              @ 081037BA  (padding)
.Llit081037BC:
	.word	gmpMasterVol                         @ 081037BC
	.thumb_func
	.global gmpSetMusicVolume
gmpSetMusicVolume:
	ldr	r1, .Llit081037C8                      @ 081037C0  =gmpMusicVol
	str	r0, [r1]                               @ 081037C2  gmpMusicVol
	bx	lr                                      @ 081037C4
	.hword	0x0000                              @ 081037C6  (padding)
.Llit081037C8:
	.word	gmpMusicVol                          @ 081037C8
	.thumb_func
	.global gmpSetSfxVolume
gmpSetSfxVolume:
	ldr	r1, .Llit081037D4                      @ 081037CC  =gmpSfxVol
	str	r0, [r1]                               @ 081037CE  gmpSfxVol
	bx	lr                                      @ 081037D0
	.hword	0x0000                              @ 081037D2  (padding)
.Llit081037D4:
	.word	gmpSfxVol                            @ 081037D4
@ --------------------------------------------------------------------------
@ gmpVBlank()  (0x081037D8)
@   Host calls it once per frame (Aero: 0x08029702).
@     gmpDmaRestartAB(gmpBuf[gmpCur]);
@     if (gmpMixNext() == 0) { gmpBufFree[gmpCur] = 1; gmpCur ^= 1 }
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpVBlank
gmpVBlank:
	push	{r4, lr}                              @ 081037D8
	ldr	r1, .Llit0810380C                      @ 081037DA  =gmpBuf
	ldr	r4, .Llit08103810                      @ 081037DC  =gmpCur
	ldr	r0, [r4]                               @ 081037DE  gmpCur
	lsls	r0, r0, #2                            @ 081037E0
	adds	r0, r0, r1                            @ 081037E2
	ldr	r0, [r0]                               @ 081037E4
	movs	r1, #0x3d                             @ 081037E6
	bl	gmpDmaRestartAB                         @ 081037E8
	bl	gmpMixNext                              @ 081037EC
	cmp	r0, #0                                 @ 081037F0
	bne	.L08103804                             @ 081037F2
	ldr	r2, .Llit08103814                      @ 081037F4  =gmpBufFree
	ldr	r1, [r4]                               @ 081037F6  gmpCur
	lsls	r0, r1, #2                            @ 081037F8
	adds	r0, r0, r2                            @ 081037FA
	movs	r2, #1                                @ 081037FC
	str	r2, [r0]                               @ 081037FE
	eors	r1, r2                                @ 08103800
	str	r1, [r4]                               @ 08103802  gmpCur
.L08103804:
	pop	{r4}                                   @ 08103804
	pop	{r0}                                   @ 08103806
	bx	r0                                      @ 08103808
	.hword	0x0000                              @ 0810380A  (padding)
.Llit0810380C:
	.word	gmpBuf                               @ 0810380C
.Llit08103810:
	.word	gmpCur                               @ 08103810
.Llit08103814:
	.word	gmpBufFree                           @ 08103814
@ --------------------------------------------------------------------------
@ gmpIwramAlloc(size)  (0x08103818)
@   size rounded to 4; p = gmpIwramPtr; gmpIwramPtr += size; memset(p, 0, size); return p
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpIwramAlloc
gmpIwramAlloc:
	push	{r4, lr}                              @ 08103818
	adds	r2, r0, #0                            @ 0810381A
	ldr	r1, .Llit0810383C                      @ 0810381C  =gmpIwramPtr
	ldr	r4, [r1]                               @ 0810381E  gmpIwramPtr
	adds	r2, #3                                @ 08103820
	movs	r0, #4                                @ 08103822
	rsbs	r0, r0, #0                            @ 08103824
	ands	r2, r0                                @ 08103826
	adds	r0, r4, r2                            @ 08103828
	str	r0, [r1]                               @ 0810382A  gmpIwramPtr
	adds	r0, r4, #0                            @ 0810382C
	movs	r1, #0                                @ 0810382E
	bl	memset                                  @ 08103830
	adds	r0, r4, #0                            @ 08103834
	pop	{r4}                                   @ 08103836
	pop	{r1}                                   @ 08103838
	bx	r1                                      @ 0810383A
.Llit0810383C:
	.word	gmpIwramPtr                          @ 0810383C
@ --------------------------------------------------------------------------
@ gmpInit(iwram)  (0x08103840)
@   gmpIwramPtr = iwram; gmpMixer = alloc(0x258); gmpBuf[0] = alloc(352); gmpBuf[1] = alloc(352);
@   gmpCopyMixer()      (Aero: gmpInit(0x03005D50) at 0x0802C61E)
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpInit
gmpInit:
	push	{r4, r5, lr}                          @ 08103840
	ldr	r1, .Llit08103870                      @ 08103842  =gmpIwramPtr
	str	r0, [r1]                               @ 08103844  gmpIwramPtr
	ldr	r4, .Llit08103874                      @ 08103846  =gmpMixer
	movs	r0, #0x96                             @ 08103848
	lsls	r0, r0, #2                            @ 0810384A
	bl	gmpIwramAlloc                           @ 0810384C
	str	r0, [r4]                               @ 08103850  gmpMixer
	ldr	r5, .Llit08103878                      @ 08103852  =gmpBufBytes
	ldr	r0, [r5]                               @ 08103854  gmpBufBytes
	bl	gmpIwramAlloc                           @ 08103856
	ldr	r4, .Llit0810387C                      @ 0810385A  =gmpBuf
	str	r0, [r4]                               @ 0810385C  gmpBuf
	ldr	r0, [r5]                               @ 0810385E  gmpBufBytes
	bl	gmpIwramAlloc                           @ 08103860
	str	r0, [r4, #4]                           @ 08103864
	bl	gmpCopyMixer                            @ 08103866
	pop	{r4, r5}                               @ 0810386A
	pop	{r0}                                   @ 0810386C
	bx	r0                                      @ 0810386E
.Llit08103870:
	.word	gmpIwramPtr                          @ 08103870
.Llit08103874:
	.word	gmpMixer                             @ 08103874
.Llit08103878:
	.word	gmpBufBytes                          @ 08103878
.Llit0810387C:
	.word	gmpBuf                               @ 0810387C
@ --------------------------------------------------------------------------
@ gmpSetupPatterns(player, npat, base)  (0x08103880)
@   gmpPatRows = module + 0x18F4;
@   patPtr[i] = base + 4 * (sum of rows[j] * gmpChannels for j < i) for i < npat, else 0 (64 slots)
@   Patterns store only their used rows; missing rows play as empty.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpSetupPatterns
gmpSetupPatterns:
	push	{r4, r5, r6, r7, lr}                  @ 08103880
	mov	r7, sl                                 @ 08103882
	mov	r6, sb                                 @ 08103884
	mov	r5, r8                                 @ 08103886
	push	{r5, r6, r7}                          @ 08103888
	mov	ip, r1                                 @ 0810388A
	mov	sl, r2                                 @ 0810388C
	ldr	r2, .Llit081038B0                      @ 0810388E  =gmpPatRows
	ldm	r0!, {r1}                              @ 08103890
	ldr	r3, .Llit081038B4                      @ 08103892  =0x000018F4
	adds	r1, r1, r3                            @ 08103894
	str	r1, [r2]                               @ 08103896  gmpPatRows
	movs	r6, #0                                @ 08103898
	movs	r4, #0                                @ 0810389A
	ldr	r7, .Llit081038B8                      @ 0810389C  =gmpChannels
	mov	sb, r7                                 @ 0810389E
	adds	r3, r0, #0                            @ 081038A0
	movs	r5, #0                                @ 081038A2
	mov	r8, r5                                 @ 081038A4
.L081038A6:
	cmp	r4, ip                                 @ 081038A6
	blt	.L081038BC                             @ 081038A8
	mov	r0, r8                                 @ 081038AA
	str	r0, [r3]                               @ 081038AC
	b	.L081038D0                               @ 081038AE
.Llit081038B0:
	.word	gmpPatRows                           @ 081038B0
.Llit081038B4:
	.word	0x000018F4                           @ 081038B4
.Llit081038B8:
	.word	gmpChannels                          @ 081038B8
.L081038BC:
	lsls	r0, r6, #2                            @ 081038BC
	add	r0, sl                                 @ 081038BE
	str	r0, [r3]                               @ 081038C0
	ldr	r0, [r2]                               @ 081038C2
	adds	r0, r5, r0                            @ 081038C4
	ldr	r1, [r0]                               @ 081038C6
	mov	r7, sb                                 @ 081038C8
	ldr	r0, [r7]                               @ 081038CA
	muls	r0, r1, r0                            @ 081038CC
	adds	r6, r6, r0                            @ 081038CE
.L081038D0:
	adds	r3, #4                                @ 081038D0
	adds	r5, #4                                @ 081038D2
	adds	r4, #1                                @ 081038D4
	cmp	r4, #0x3f                              @ 081038D6
	ble	.L081038A6                             @ 081038D8
	pop	{r3, r4, r5}                           @ 081038DA
	mov	r8, r3                                 @ 081038DC
	mov	sb, r4                                 @ 081038DE
	mov	sl, r5                                 @ 081038E0
	pop	{r4, r5, r6, r7}                       @ 081038E2
	pop	{r0}                                   @ 081038E4
	bx	r0                                      @ 081038E6
@ --------------------------------------------------------------------------
@ gmpCheckMixer()  (0x081038E8)  -- unused
@   return memcmp(gmpMixer, gmpMixChannelRom, 0x258) != 0
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpCheckMixer
gmpCheckMixer:
	push	{r4, r5, lr}                          @ 081038E8
	movs	r5, #0                                @ 081038EA
	ldr	r4, .Llit08103914                      @ 081038EC  =gmpMixChannelRom
	ldr	r0, .Llit08103918                      @ 081038EE  =gmpMixer
	ldr	r2, [r0]                               @ 081038F0  gmpMixer
	movs	r3, #0x96                             @ 081038F2
	lsls	r3, r3, #2                            @ 081038F4
.L081038F6:
	ldrb	r1, [r2]                              @ 081038F6
	ldrb	r0, [r4]                              @ 081038F8
	adds	r4, #1                                @ 081038FA
	adds	r2, #1                                @ 081038FC
	cmp	r1, r0                                 @ 081038FE
	beq	.L08103904                             @ 08103900
	movs	r5, #1                                @ 08103902
.L08103904:
	subs	r3, #1                                @ 08103904
	cmp	r3, #0                                 @ 08103906
	bne	.L081038F6                             @ 08103908
	adds	r0, r5, #0                            @ 0810390A
	pop	{r4, r5}                               @ 0810390C
	pop	{r1}                                   @ 0810390E
	bx	r1                                      @ 08103910
	.hword	0x0000                              @ 08103912  (padding)
.Llit08103914:
	.word	gmpMixChannelRom                     @ 08103914
.Llit08103918:
	.word	gmpMixer                             @ 08103918
@ --------------------------------------------------------------------------
@ gmpCopyMixer()  (0x0810391C)
@   memset(gmpMixer, 0, 0x258); memcpy(gmpMixer, gmpMixChannelRom, 0x258); then a 599-iteration
@   delay loop.  The ARM mixer is 0x118 bytes long, so the copy also takes 0x140 bytes of the
@   libc code that follows it.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpCopyMixer
gmpCopyMixer:
	push	{r4, r5, r6, lr}                      @ 0810391C
	ldr	r6, .Llit0810394C                      @ 0810391E  =gmpMixChannelRom
	ldr	r0, .Llit08103950                      @ 08103920  =gmpMixer
	ldr	r4, [r0]                               @ 08103922  gmpMixer
	movs	r5, #0x96                             @ 08103924
	lsls	r5, r5, #2                            @ 08103926
	adds	r0, r4, #0                            @ 08103928
	movs	r1, #0                                @ 0810392A
	adds	r2, r5, #0                            @ 0810392C
	bl	memset                                  @ 0810392E
	adds	r0, r4, #0                            @ 08103932
	adds	r1, r6, #0                            @ 08103934
	adds	r2, r5, #0                            @ 08103936
	bl	memcpy                                  @ 08103938
	ldr	r0, .Llit08103954                      @ 0810393C  =0x00000257
.L0810393E:
	subs	r0, #1                                @ 0810393E
	cmp	r0, #0                                 @ 08103940
	bgt	.L0810393E                             @ 08103942
	pop	{r4, r5, r6}                           @ 08103944
	pop	{r0}                                   @ 08103946
	bx	r0                                      @ 08103948
	.hword	0x0000                              @ 0810394A  (padding)
.Llit0810394C:
	.word	gmpMixChannelRom                     @ 0810394C
.Llit08103950:
	.word	gmpMixer                             @ 08103950
.Llit08103954:
	.word	0x00000257                           @ 08103954
@ --------------------------------------------------------------------------
@ gmpLoadModule(player, module, bank)  (0x08103958)
@   gmpSpeed = 6; gmpBPM = 125; gmpRate = 0; gmpLoopMark = 0xFFFF;
@   if (module[0..7] != "GBAMOD2.") return 0;
@   if (module[0x1AF4] < 0) bank = 0;                         (a negative flag forces own samples)
@   if (bank) { headers = bank; pcm = bank + 0x174 } else { headers = module + 0x16FC;
@               pcm = module + 0x1AF8 + module[0x0C] }
@   gmpChannels = module[8]; smpPtr[i] = headers[i].len ? pcm + (sum of earlier lengths) : 0 (31 slots)
@   player->module = module; gmpRate = module[0x14]; gmpSetupPatterns(player, module[0x1870], module + 0x1AF8)
@   Note: the play-time sample parameters (length, loop, volume, finetune) always come from the
@   module's own headers at +0x16FC; only the data pointers come from the bank.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpLoadModule
gmpLoadModule:
	push	{r4, r5, r6, r7, lr}                  @ 08103958
	mov	r7, sb                                 @ 0810395A
	mov	r6, r8                                 @ 0810395C
	push	{r6, r7}                              @ 0810395E
	mov	sb, r0                                 @ 08103960
	adds	r3, r1, #0                            @ 08103962
	ldr	r1, .Llit08103994                      @ 08103964  =gmpSpeed
	movs	r0, #6                                @ 08103966
	str	r0, [r1]                               @ 08103968  gmpSpeed
	ldr	r1, .Llit08103998                      @ 0810396A  =gmpBPM
	movs	r0, #0x7d                             @ 0810396C
	str	r0, [r1]                               @ 0810396E  gmpBPM
	ldr	r1, .Llit0810399C                      @ 08103970  =gmpRate
	movs	r0, #0                                @ 08103972
	str	r0, [r1]                               @ 08103974  gmpRate
	ldr	r1, .Llit081039A0                      @ 08103976  =gmpLoopMark
	ldr	r4, .Llit081039A4                      @ 08103978  =0x0000FFFF
	adds	r0, r4, #0                            @ 0810397A
	strh	r0, [r1]                              @ 0810397C  gmpLoopMark
	ldr	r1, [r3]                               @ 0810397E
	ldr	r4, [r3, #4]                           @ 08103980
	ldr	r0, .Llit081039A8                      @ 08103982  =0x4D414247
	cmp	r1, r0                                 @ 08103984  "GBAM"
	bne	.L0810398E                             @ 08103986
	ldr	r0, .Llit081039AC                      @ 08103988  =0x2E32444F
	cmp	r4, r0                                 @ 0810398A  "OD2."
	beq	.L081039B0                             @ 0810398C
.L0810398E:
	movs	r0, #0                                @ 0810398E
	b	.L08103A3E                               @ 08103990
	.hword	0x0000                              @ 08103992  (padding)
.Llit08103994:
	.word	gmpSpeed                             @ 08103994
.Llit08103998:
	.word	gmpBPM                               @ 08103998
.Llit0810399C:
	.word	gmpRate                              @ 0810399C
.Llit081039A0:
	.word	gmpLoopMark                          @ 081039A0
.Llit081039A4:
	.word	0x0000FFFF                           @ 081039A4
.Llit081039A8:
	.word	0x4D414247                           @ 081039A8
.Llit081039AC:
	.word	0x2E32444F                           @ 081039AC
.L081039B0:
	ldr	r7, .Llit081039D8                      @ 081039B0  =0x00001870
	adds	r0, r3, r7                            @ 081039B2
	ldr	r0, [r0]                               @ 081039B4
	mov	r8, r0                                 @ 081039B6
	ldr	r0, .Llit081039DC                      @ 081039B8  =0x00001AF8
	adds	r0, r0, r3                            @ 081039BA
	mov	ip, r0                                 @ 081039BC
	ldr	r1, .Llit081039E0                      @ 081039BE  =0x00001AF4
	adds	r0, r3, r1                            @ 081039C0
	ldr	r0, [r0]                               @ 081039C2
	cmp	r0, #0                                 @ 081039C4
	bge	.L081039CA                             @ 081039C6
	movs	r2, #0                                @ 081039C8
.L081039CA:
	cmp	r2, #0                                 @ 081039CA
	beq	.L081039E4                             @ 081039CC
	movs	r4, #0xba                             @ 081039CE
	lsls	r4, r4, #1                            @ 081039D0
	adds	r5, r2, r4                            @ 081039D2
	b	.L081039EE                               @ 081039D4
	.hword	0x0000                              @ 081039D6  (padding)
.Llit081039D8:
	.word	0x00001870                           @ 081039D8
.Llit081039DC:
	.word	0x00001AF8                           @ 081039DC
.Llit081039E0:
	.word	0x00001AF4                           @ 081039E0
.L081039E4:
	ldr	r7, .Llit08103A0C                      @ 081039E4  =0x000016FC
	adds	r2, r3, r7                            @ 081039E6
	ldr	r0, [r3, #0xc]                         @ 081039E8
	mov	r1, ip                                 @ 081039EA
	adds	r5, r1, r0                            @ 081039EC
.L081039EE:
	movs	r6, #0                                @ 081039EE
	ldr	r1, .Llit08103A10                      @ 081039F0  =gmpChannels
	ldr	r0, [r3, #8]                           @ 081039F2
	str	r0, [r1]                               @ 081039F4  gmpChannels
	movs	r1, #0x82                             @ 081039F6
	lsls	r1, r1, #1                            @ 081039F8
	add	r1, sb                                 @ 081039FA
	movs	r4, #0x1e                             @ 081039FC
.L081039FE:
	movs	r7, #0                                @ 081039FE
	ldrsh	r0, [r2, r7]                         @ 08103A00
	cmp	r0, #0                                 @ 08103A02
	bne	.L08103A14                             @ 08103A04
	str	r0, [r1]                               @ 08103A06
	b	.L08103A1E                               @ 08103A08
	.hword	0x0000                              @ 08103A0A  (padding)
.Llit08103A0C:
	.word	0x000016FC                           @ 08103A0C
.Llit08103A10:
	.word	gmpChannels                          @ 08103A10
.L08103A14:
	adds	r0, r5, r6                            @ 08103A14
	str	r0, [r1]                               @ 08103A16
	movs	r7, #0                                @ 08103A18
	ldrsh	r0, [r2, r7]                         @ 08103A1A
	adds	r6, r6, r0                            @ 08103A1C
.L08103A1E:
	adds	r2, #0xc                              @ 08103A1E
	adds	r1, #4                                @ 08103A20
	subs	r4, #1                                @ 08103A22
	cmp	r4, #0                                 @ 08103A24
	bge	.L081039FE                             @ 08103A26
	mov	r0, sb                                 @ 08103A28
	str	r3, [r0]                               @ 08103A2A
	ldr	r1, .Llit08103A4C                      @ 08103A2C  =gmpRate
	ldr	r0, [r3, #0x14]                        @ 08103A2E
	str	r0, [r1]                               @ 08103A30  gmpRate
	mov	r0, sb                                 @ 08103A32
	mov	r1, r8                                 @ 08103A34
	mov	r2, ip                                 @ 08103A36
	bl	gmpSetupPatterns                        @ 08103A38
	movs	r0, #1                                @ 08103A3C
.L08103A3E:
	pop	{r3, r4}                               @ 08103A3E
	mov	r8, r3                                 @ 08103A40
	mov	sb, r4                                 @ 08103A42
	pop	{r4, r5, r6, r7}                       @ 08103A44
	pop	{r1}                                   @ 08103A46
	bx	r1                                      @ 08103A48
	.hword	0x0000                              @ 08103A4A  (padding)
.Llit08103A4C:
	.word	gmpRate                              @ 08103A4C
@ --------------------------------------------------------------------------
@ gmpStartSong(order)  (0x08103A50)
@   if (!gmpRate || order >= songLen) return;
@   gmpSpeed = 6; gmpBPM = 125; gmpTickHz = 50; gmpStepTab = module + 0x1C; gmpPeriodTab = module + 0xF5C
@   gmpOrder = order; gmpCell = 0; gmpRowLen = rate * 6 / 50; gmpTickLen = rate / 50; counters = 0
@   clear all 8 channels (the SFX ones too); gmpJumped = gmpTick = 0; volumes = 64; clear buffers
@   gmpJinglePri = 0; skip/queue flags = 0; if (!gmpDmaOn) { gmpStartDma(gmpBuf[gmpCur]); gmpDmaOn = 1 }
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpStartSong
gmpStartSong:
	push	{r4, r5, r6, lr}                      @ 08103A50
	lsls	r0, r0, #0x10                         @ 08103A52
	lsrs	r4, r0, #0x10                         @ 08103A54
	ldr	r0, .Llit08103B3C                      @ 08103A56  =gmpRate
	ldr	r6, [r0]                               @ 08103A58  gmpRate
	cmp	r6, #0                                 @ 08103A5A
	beq	.L08103B34                             @ 08103A5C
	lsls	r0, r4, #0x10                         @ 08103A5E
	asrs	r0, r0, #0x10                         @ 08103A60
	ldr	r1, .Llit08103B40                      @ 08103A62  =gmpPlayer
	ldr	r3, [r1]                               @ 08103A64  gmpPlayer
	ldr	r1, [r3, #0x18]                        @ 08103A66
	cmp	r0, r1                                 @ 08103A68
	bge	.L08103B34                             @ 08103A6A
	ldr	r0, .Llit08103B44                      @ 08103A6C  =gmpSpeed
	movs	r2, #6                                @ 08103A6E
	str	r2, [r0]                               @ 08103A70  gmpSpeed
	ldr	r1, .Llit08103B48                      @ 08103A72  =gmpBPM
	movs	r0, #0x7d                             @ 08103A74
	str	r0, [r1]                               @ 08103A76  gmpBPM
	ldr	r1, .Llit08103B4C                      @ 08103A78  =gmpTickHz
	movs	r0, #0x32                             @ 08103A7A
	str	r0, [r1]                               @ 08103A7C  gmpTickHz
	ldr	r1, .Llit08103B50                      @ 08103A7E  =gmpStepTab
	adds	r0, r3, #0                            @ 08103A80
	adds	r0, #0x1c                             @ 08103A82
	str	r0, [r1]                               @ 08103A84  gmpStepTab
	ldr	r1, .Llit08103B54                      @ 08103A86  =gmpPeriodTab
	ldr	r5, .Llit08103B58                      @ 08103A88  =0x00000F5C
	adds	r0, r3, r5                            @ 08103A8A
	str	r0, [r1]                               @ 08103A8C  gmpPeriodTab
	ldr	r0, .Llit08103B5C                      @ 08103A8E  =gmpOrder
	strh	r4, [r0]                              @ 08103A90  gmpOrder
	ldr	r1, .Llit08103B60                      @ 08103A92  =gmpCell
	movs	r0, #0                                @ 08103A94
	strh	r0, [r1]                              @ 08103A96  gmpCell
	ldr	r4, .Llit08103B64                      @ 08103A98  =gmpRowLen
	adds	r0, r6, #0                            @ 08103A9A
	muls	r0, r2, r0                            @ 08103A9C
	movs	r1, #0x32                             @ 08103A9E
	bl	__udivsi3                               @ 08103AA0
	str	r0, [r4]                               @ 08103AA4  gmpRowLen
	ldr	r0, .Llit08103B68                      @ 08103AA6  =gmpRowLeft
	movs	r5, #0                                @ 08103AA8
	str	r5, [r0]                               @ 08103AAA  gmpRowLeft
	ldr	r4, .Llit08103B6C                      @ 08103AAC  =gmpTickLen
	adds	r0, r6, #0                            @ 08103AAE
	movs	r1, #0x32                             @ 08103AB0
	bl	__udivsi3                               @ 08103AB2
	str	r0, [r4]                               @ 08103AB6  gmpTickLen
	ldr	r0, .Llit08103B70                      @ 08103AB8  =gmpTickLeft
	str	r5, [r0]                               @ 08103ABA  gmpTickLeft
	ldr	r6, .Llit08103B74                      @ 08103ABC  =gmpChan
	movs	r4, #7                                @ 08103ABE
.L08103AC0:
	adds	r0, r5, r6                            @ 08103AC0
	movs	r1, #0                                @ 08103AC2
	movs	r2, #0x4c                             @ 08103AC4
	bl	memset                                  @ 08103AC6
	adds	r5, #0x4c                             @ 08103ACA
	subs	r4, #1                                @ 08103ACC
	cmp	r4, #0                                 @ 08103ACE
	bge	.L08103AC0                             @ 08103AD0
	ldr	r1, .Llit08103B78                      @ 08103AD2  =gmpJumped
	movs	r0, #0                                @ 08103AD4
	strb	r0, [r1]                              @ 08103AD6  gmpJumped
	ldr	r0, .Llit08103B7C                      @ 08103AD8  =gmpTick
	movs	r5, #0                                @ 08103ADA
	strh	r5, [r0]                              @ 08103ADC  gmpTick
	ldr	r0, .Llit08103B80                      @ 08103ADE  =gmpMasterVol
	movs	r1, #0x40                             @ 08103AE0
	str	r1, [r0]                               @ 08103AE2  gmpMasterVol
	ldr	r0, .Llit08103B84                      @ 08103AE4  =gmpMusicVol
	str	r1, [r0]                               @ 08103AE6  gmpMusicVol
	ldr	r0, .Llit08103B88                      @ 08103AE8  =gmpSfxVol
	str	r1, [r0]                               @ 08103AEA  gmpSfxVol
	ldr	r6, .Llit08103B8C                      @ 08103AEC  =gmpBuf
	ldr	r0, [r6]                               @ 08103AEE  gmpBuf
	ldr	r4, .Llit08103B90                      @ 08103AF0  =gmpBufBytes
	ldr	r2, [r4]                               @ 08103AF2  gmpBufBytes
	movs	r1, #0                                @ 08103AF4
	bl	memset                                  @ 08103AF6
	ldr	r0, [r6, #4]                           @ 08103AFA
	ldr	r2, [r4]                               @ 08103AFC  gmpBufBytes
	movs	r1, #0                                @ 08103AFE
	bl	memset                                  @ 08103B00
	ldr	r0, .Llit08103B94                      @ 08103B04  =gmpJinglePri
	strh	r5, [r0]                              @ 08103B06  gmpJinglePri
	ldr	r0, .Llit08103B98                      @ 08103B08  =gmpSkipSaved
	movs	r1, #0                                @ 08103B0A
	str	r1, [r0]                               @ 08103B0C  gmpSkipSaved
	ldr	r0, .Llit08103B9C                      @ 08103B0E  =gmpSkip
	str	r1, [r0]                               @ 08103B10  gmpSkip
	ldr	r0, .Llit08103BA0                      @ 08103B12  =gmpQueued
	str	r1, [r0]                               @ 08103B14  gmpQueued
	ldr	r0, .Llit08103BA4                      @ 08103B16  =gmpQueuedSaved
	str	r1, [r0]                               @ 08103B18  gmpQueuedSaved
	ldr	r4, .Llit08103BA8                      @ 08103B1A  =gmpDmaOn
	ldr	r0, [r4]                               @ 08103B1C  gmpDmaOn
	cmp	r0, #0                                 @ 08103B1E
	bne	.L08103B34                             @ 08103B20
	ldr	r0, .Llit08103BAC                      @ 08103B22  =gmpCur
	ldr	r0, [r0]                               @ 08103B24  gmpCur
	lsls	r0, r0, #2                            @ 08103B26
	adds	r0, r0, r6                            @ 08103B28
	ldr	r0, [r0]                               @ 08103B2A
	bl	gmpStartDma                             @ 08103B2C  first song: start the DMA
	movs	r0, #1                                @ 08103B30
	str	r0, [r4]                               @ 08103B32  gmpDmaOn
.L08103B34:
	pop	{r4, r5, r6}                           @ 08103B34
	pop	{r0}                                   @ 08103B36
	bx	r0                                      @ 08103B38
	.hword	0x0000                              @ 08103B3A  (padding)
.Llit08103B3C:
	.word	gmpRate                              @ 08103B3C
.Llit08103B40:
	.word	gmpPlayer                            @ 08103B40
.Llit08103B44:
	.word	gmpSpeed                             @ 08103B44
.Llit08103B48:
	.word	gmpBPM                               @ 08103B48
.Llit08103B4C:
	.word	gmpTickHz                            @ 08103B4C
.Llit08103B50:
	.word	gmpStepTab                           @ 08103B50
.Llit08103B54:
	.word	gmpPeriodTab                         @ 08103B54
.Llit08103B58:
	.word	0x00000F5C                           @ 08103B58
.Llit08103B5C:
	.word	gmpOrder                             @ 08103B5C
.Llit08103B60:
	.word	gmpCell                              @ 08103B60
.Llit08103B64:
	.word	gmpRowLen                            @ 08103B64
.Llit08103B68:
	.word	gmpRowLeft                           @ 08103B68
.Llit08103B6C:
	.word	gmpTickLen                           @ 08103B6C
.Llit08103B70:
	.word	gmpTickLeft                          @ 08103B70
.Llit08103B74:
	.word	gmpChan                              @ 08103B74
.Llit08103B78:
	.word	gmpJumped                            @ 08103B78
.Llit08103B7C:
	.word	gmpTick                              @ 08103B7C
.Llit08103B80:
	.word	gmpMasterVol                         @ 08103B80
.Llit08103B84:
	.word	gmpMusicVol                          @ 08103B84
.Llit08103B88:
	.word	gmpSfxVol                            @ 08103B88
.Llit08103B8C:
	.word	gmpBuf                               @ 08103B8C
.Llit08103B90:
	.word	gmpBufBytes                          @ 08103B90
.Llit08103B94:
	.word	gmpJinglePri                         @ 08103B94
.Llit08103B98:
	.word	gmpSkipSaved                         @ 08103B98
.Llit08103B9C:
	.word	gmpSkip                              @ 08103B9C
.Llit08103BA0:
	.word	gmpQueued                            @ 08103BA0
.Llit08103BA4:
	.word	gmpQueuedSaved                       @ 08103BA4
.Llit08103BA8:
	.word	gmpDmaOn                             @ 08103BA8
.Llit08103BAC:
	.word	gmpCur                               @ 08103BAC
@ --------------------------------------------------------------------------
@ gmpJumpOrder(order)  (0x08103BB0)
@   Like gmpStartSong without the volume and DMA set-up: gmpOrder = order, gmpCell = 0,
@   gmpRowLen = rate*6/50 and gmpTickLen = rate/50 (speed 6 / 125 BPM timing, although gmpSpeed
@   and gmpBPM keep their values until the next Fxx), clears gmpSkip and gmpQueued, and clears
@   channels 0 .. gmpChannels-3 only: two music channels keep sounding across the jump.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpJumpOrder
gmpJumpOrder:
	push	{r4, r5, r6, lr}                      @ 08103BB0
	lsls	r0, r0, #0x10                         @ 08103BB2
	lsrs	r3, r0, #0x10                         @ 08103BB4
	ldr	r0, .Llit08103BD0                      @ 08103BB6  =gmpRate
	ldr	r6, [r0]                               @ 08103BB8  gmpRate
	cmp	r6, #0                                 @ 08103BBA
	beq	.L08103BCC                             @ 08103BBC
	lsls	r0, r3, #0x10                         @ 08103BBE
	asrs	r0, r0, #0x10                         @ 08103BC0
	ldr	r1, .Llit08103BD4                      @ 08103BC2  =gmpPlayer
	ldr	r2, [r1]                               @ 08103BC4  gmpPlayer
	ldr	r1, [r2, #0x18]                        @ 08103BC6
	cmp	r0, r1                                 @ 08103BC8
	blt	.L08103BD8                             @ 08103BCA
.L08103BCC:
	movs	r0, #0                                @ 08103BCC
	b	.L08103C64                               @ 08103BCE
.Llit08103BD0:
	.word	gmpRate                              @ 08103BD0
.Llit08103BD4:
	.word	gmpPlayer                            @ 08103BD4
.L08103BD8:
	ldr	r1, .Llit08103C14                      @ 08103BD8  =gmpStepTab
	adds	r0, r2, #0                            @ 08103BDA
	adds	r0, #0x1c                             @ 08103BDC
	str	r0, [r1]                               @ 08103BDE  gmpStepTab
	ldr	r0, .Llit08103C18                      @ 08103BE0  =gmpOrder
	strh	r3, [r0]                              @ 08103BE2  gmpOrder
	ldr	r1, .Llit08103C1C                      @ 08103BE4  =gmpCell
	movs	r0, #0                                @ 08103BE6
	strh	r0, [r1]                              @ 08103BE8  gmpCell
	ldr	r4, .Llit08103C20                      @ 08103BEA  =gmpRowLen
	lsls	r0, r6, #1                            @ 08103BEC
	adds	r0, r0, r6                            @ 08103BEE
	lsls	r0, r0, #1                            @ 08103BF0
	movs	r1, #0x32                             @ 08103BF2
	bl	__udivsi3                               @ 08103BF4
	str	r0, [r4]                               @ 08103BF8  gmpRowLen
	ldr	r0, .Llit08103C24                      @ 08103BFA  =gmpRowLeft
	movs	r5, #0                                @ 08103BFC
	str	r5, [r0]                               @ 08103BFE  gmpRowLeft
	ldr	r4, .Llit08103C28                      @ 08103C00  =gmpTickLen
	adds	r0, r6, #0                            @ 08103C02
	movs	r1, #0x32                             @ 08103C04
	bl	__udivsi3                               @ 08103C06
	str	r0, [r4]                               @ 08103C0A  gmpTickLen
	ldr	r0, .Llit08103C2C                      @ 08103C0C  =gmpTickLeft
	str	r5, [r0]                               @ 08103C0E  gmpTickLeft
	movs	r4, #0                                @ 08103C10
	b	.L08103C42                               @ 08103C12
.Llit08103C14:
	.word	gmpStepTab                           @ 08103C14
.Llit08103C18:
	.word	gmpOrder                             @ 08103C18
.Llit08103C1C:
	.word	gmpCell                              @ 08103C1C
.Llit08103C20:
	.word	gmpRowLen                            @ 08103C20
.Llit08103C24:
	.word	gmpRowLeft                           @ 08103C24
.Llit08103C28:
	.word	gmpTickLen                           @ 08103C28
.Llit08103C2C:
	.word	gmpTickLeft                          @ 08103C2C
.L08103C30:
	movs	r0, #0x4c                             @ 08103C30
	muls	r0, r4, r0                            @ 08103C32
	ldr	r1, .Llit08103C6C                      @ 08103C34  =gmpChan
	adds	r0, r0, r1                            @ 08103C36
	movs	r1, #0                                @ 08103C38
	movs	r2, #0x4c                             @ 08103C3A
	bl	memset                                  @ 08103C3C
	adds	r4, #1                                @ 08103C40
.L08103C42:
	ldr	r0, .Llit08103C70                      @ 08103C42  =gmpChannels
	ldr	r0, [r0]                               @ 08103C44  gmpChannels
	subs	r0, #2                                @ 08103C46
	cmp	r4, r0                                 @ 08103C48
	blt	.L08103C30                             @ 08103C4A
	ldr	r1, .Llit08103C74                      @ 08103C4C  =gmpJumped
	movs	r0, #0                                @ 08103C4E
	strb	r0, [r1]                              @ 08103C50  gmpJumped
	ldr	r1, .Llit08103C78                      @ 08103C52  =gmpTick
	movs	r0, #0                                @ 08103C54
	strh	r0, [r1]                              @ 08103C56  gmpTick
	ldr	r0, .Llit08103C7C                      @ 08103C58  =gmpSkip
	movs	r1, #0                                @ 08103C5A
	str	r1, [r0]                               @ 08103C5C  gmpSkip
	ldr	r0, .Llit08103C80                      @ 08103C5E  =gmpQueued
	str	r1, [r0]                               @ 08103C60  gmpQueued
	movs	r0, #1                                @ 08103C62
.L08103C64:
	pop	{r4, r5, r6}                           @ 08103C64
	pop	{r1}                                   @ 08103C66
	bx	r1                                      @ 08103C68
	.hword	0x0000                              @ 08103C6A  (padding)
.Llit08103C6C:
	.word	gmpChan                              @ 08103C6C
.Llit08103C70:
	.word	gmpChannels                          @ 08103C70
.Llit08103C74:
	.word	gmpJumped                            @ 08103C74
.Llit08103C78:
	.word	gmpTick                              @ 08103C78
.Llit08103C7C:
	.word	gmpSkip                              @ 08103C7C
.Llit08103C80:
	.word	gmpQueued                            @ 08103C80
@ --------------------------------------------------------------------------
@ gmpPlayJingle(order, priority)  (0x08103C84)  -- unused by Aero
@   A "jingle" here is another position in the *same* module, ended by a Bxx.
@   if (order out of range || (priority && priority <= gmpJinglePri)) return;
@   gmpPriSaved = gmpJinglePri;
@   if (!gmpJingleOn || !priority) { save gmpSkip, gmpQueued, gmpReturnOrder = gmpOrder }
@   gmpJingleOn = 1; gmpJinglePri = priority; gmpJumpOrder(order)
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpPlayJingle
gmpPlayJingle:
	push	{r4, r5, lr}                          @ 08103C84
	lsls	r0, r0, #0x10                         @ 08103C86
	lsls	r1, r1, #0x10                         @ 08103C88
	lsrs	r4, r1, #0x10                         @ 08103C8A
	lsrs	r5, r0, #0x10                         @ 08103C8C
	asrs	r1, r0, #0x10                         @ 08103C8E
	cmp	r1, #0                                 @ 08103C90
	blt	.L08103CEC                             @ 08103C92
	ldr	r0, .Llit08103CF4                      @ 08103C94  =gmpPlayer
	ldr	r0, [r0]                               @ 08103C96  gmpPlayer
	ldr	r0, [r0, #0x18]                        @ 08103C98
	cmp	r1, r0                                 @ 08103C9A
	bge	.L08103CEC                             @ 08103C9C
	lsls	r0, r4, #0x10                         @ 08103C9E
	asrs	r2, r0, #0x10                         @ 08103CA0
	ldr	r3, .Llit08103CF8                      @ 08103CA2  =gmpJinglePri
	cmp	r2, #0                                 @ 08103CA4
	beq	.L08103CB0                             @ 08103CA6
	movs	r1, #0                                @ 08103CA8
	ldrsh	r0, [r3, r1]                         @ 08103CAA
	cmp	r2, r0                                 @ 08103CAC
	ble	.L08103CEC                             @ 08103CAE
.L08103CB0:
	ldr	r1, .Llit08103CFC                      @ 08103CB0  =gmpPriSaved
	ldrh	r0, [r3]                              @ 08103CB2
	strh	r0, [r1]                              @ 08103CB4  gmpPriSaved
	ldr	r0, .Llit08103D00                      @ 08103CB6  =gmpJingleOn
	ldrb	r0, [r0]                              @ 08103CB8  gmpJingleOn
	cmp	r0, #0                                 @ 08103CBA
	beq	.L08103CC2                             @ 08103CBC
	cmp	r2, #0                                 @ 08103CBE
	bne	.L08103CDA                             @ 08103CC0
.L08103CC2:
	ldr	r1, .Llit08103D04                      @ 08103CC2  =gmpSkipSaved
	ldr	r0, .Llit08103D08                      @ 08103CC4  =gmpSkip
	ldr	r0, [r0]                               @ 08103CC6  gmpSkip
	str	r0, [r1]                               @ 08103CC8  gmpSkipSaved
	ldr	r1, .Llit08103D0C                      @ 08103CCA  =gmpQueuedSaved
	ldr	r0, .Llit08103D10                      @ 08103CCC  =gmpQueued
	ldr	r0, [r0]                               @ 08103CCE  gmpQueued
	str	r0, [r1]                               @ 08103CD0  gmpQueuedSaved
	ldr	r1, .Llit08103D14                      @ 08103CD2  =gmpReturnOrder
	ldr	r0, .Llit08103D18                      @ 08103CD4  =gmpOrder
	ldrh	r0, [r0]                              @ 08103CD6  gmpOrder
	strh	r0, [r1]                              @ 08103CD8  gmpReturnOrder
.L08103CDA:
	ldr	r1, .Llit08103D00                      @ 08103CDA  =gmpJingleOn
	movs	r0, #1                                @ 08103CDC
	strb	r0, [r1]                              @ 08103CDE  gmpJingleOn
	ldr	r0, .Llit08103CF8                      @ 08103CE0  =gmpJinglePri
	strh	r4, [r0]                              @ 08103CE2  gmpJinglePri
	lsls	r0, r5, #0x10                         @ 08103CE4
	asrs	r0, r0, #0x10                         @ 08103CE6
	bl	gmpJumpOrder                            @ 08103CE8
.L08103CEC:
	pop	{r4, r5}                               @ 08103CEC
	pop	{r0}                                   @ 08103CEE
	bx	r0                                      @ 08103CF0
	.hword	0x0000                              @ 08103CF2  (padding)
.Llit08103CF4:
	.word	gmpPlayer                            @ 08103CF4
.Llit08103CF8:
	.word	gmpJinglePri                         @ 08103CF8
.Llit08103CFC:
	.word	gmpPriSaved                          @ 08103CFC
.Llit08103D00:
	.word	gmpJingleOn                          @ 08103D00
.Llit08103D04:
	.word	gmpSkipSaved                         @ 08103D04
.Llit08103D08:
	.word	gmpSkip                              @ 08103D08
.Llit08103D0C:
	.word	gmpQueuedSaved                       @ 08103D0C
.Llit08103D10:
	.word	gmpQueued                            @ 08103D10
.Llit08103D14:
	.word	gmpReturnOrder                       @ 08103D14
.Llit08103D18:
	.word	gmpOrder                             @ 08103D18
@ --------------------------------------------------------------------------
@ gmpQueueOrder(order, priority)  (0x08103D1C)  -- unused
@   if (order in range && !(priority && priority <= gmpJinglePri)) {
@       gmpQueuedPri = priority (never read); gmpQueuedOrder = order; gmpQueued = 1 }
@   gmpProcessRow then calls gmpStartSong(gmpQueuedOrder): a full restart at that order.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpQueueOrder
gmpQueueOrder:
	lsls	r1, r1, #0x10                         @ 08103D1C
	lsrs	r1, r1, #0x10                         @ 08103D1E
	lsls	r0, r0, #0x10                         @ 08103D20
	asrs	r2, r0, #0x10                         @ 08103D22
	cmp	r2, #0                                 @ 08103D24
	blt	.L08103D52                             @ 08103D26
	ldr	r0, .Llit08103D54                      @ 08103D28  =gmpPlayer
	ldr	r0, [r0]                               @ 08103D2A  gmpPlayer
	ldr	r0, [r0, #0x18]                        @ 08103D2C
	cmp	r2, r0                                 @ 08103D2E
	bge	.L08103D52                             @ 08103D30
	lsls	r0, r1, #0x10                         @ 08103D32
	asrs	r1, r0, #0x10                         @ 08103D34
	cmp	r1, #0                                 @ 08103D36
	beq	.L08103D44                             @ 08103D38
	ldr	r0, .Llit08103D58                      @ 08103D3A  =gmpJinglePri
	movs	r3, #0                                @ 08103D3C
	ldrsh	r0, [r0, r3]                         @ 08103D3E
	cmp	r1, r0                                 @ 08103D40
	ble	.L08103D52                             @ 08103D42
.L08103D44:
	ldr	r0, .Llit08103D5C                      @ 08103D44  =gmpQueuedPri
	str	r1, [r0]                               @ 08103D46  gmpQueuedPri
	ldr	r0, .Llit08103D60                      @ 08103D48  =gmpQueuedOrder
	str	r2, [r0]                               @ 08103D4A  gmpQueuedOrder
	ldr	r1, .Llit08103D64                      @ 08103D4C  =gmpQueued
	movs	r0, #1                                @ 08103D4E
	str	r0, [r1]                               @ 08103D50  gmpQueued
.L08103D52:
	bx	lr                                      @ 08103D52
.Llit08103D54:
	.word	gmpPlayer                            @ 08103D54
.Llit08103D58:
	.word	gmpJinglePri                         @ 08103D58
.Llit08103D5C:
	.word	gmpQueuedPri                         @ 08103D5C
.Llit08103D60:
	.word	gmpQueuedOrder                       @ 08103D60
.Llit08103D64:
	.word	gmpQueued                            @ 08103D64
@ --------------------------------------------------------------------------
@ gmpSetReturnOrder(order)  (0x08103D68)  -- unused
@   gmpReturnOrder = order; gmpPriSaved = 0
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpSetReturnOrder
gmpSetReturnOrder:
	ldr	r1, .Llit08103D74                      @ 08103D68  =gmpReturnOrder
	strh	r0, [r1]                              @ 08103D6A  gmpReturnOrder
	ldr	r1, .Llit08103D78                      @ 08103D6C  =gmpPriSaved
	movs	r0, #0                                @ 08103D6E
	strh	r0, [r1]                              @ 08103D70  gmpPriSaved
	bx	lr                                      @ 08103D72
.Llit08103D74:
	.word	gmpReturnOrder                       @ 08103D74
.Llit08103D78:
	.word	gmpPriSaved                          @ 08103D78
@ --------------------------------------------------------------------------
@ gmpEndJingle()  (0x08103D7C)
@   gmpJingleOn = 0; gmpJinglePri = 0; gmpJumpOrder(gmpReturnOrder); restore gmpSkip and
@   gmpQueued; if (gmpPauseAfterJingle) { gmpPauseAfterJingle = 0; gmpPause() }
@   Called by Bxx while a jingle plays.  The music resumes at the start of the saved order.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpEndJingle
gmpEndJingle:
	push	{lr}                                  @ 08103D7C
	ldr	r1, .Llit08103DBC                      @ 08103D7E  =gmpJingleOn
	movs	r0, #0                                @ 08103D80
	strb	r0, [r1]                              @ 08103D82  gmpJingleOn
	ldr	r1, .Llit08103DC0                      @ 08103D84  =gmpJinglePri
	movs	r0, #0                                @ 08103D86
	strh	r0, [r1]                              @ 08103D88  gmpJinglePri
	ldr	r0, .Llit08103DC4                      @ 08103D8A  =gmpReturnOrder
	movs	r1, #0                                @ 08103D8C
	ldrsh	r0, [r0, r1]                         @ 08103D8E
	bl	gmpJumpOrder                            @ 08103D90
	ldr	r1, .Llit08103DC8                      @ 08103D94  =gmpSkip
	ldr	r3, .Llit08103DCC                      @ 08103D96  =gmpSkipSaved
	ldr	r0, [r3]                               @ 08103D98  gmpSkipSaved
	str	r0, [r1]                               @ 08103D9A  gmpSkip
	ldr	r1, .Llit08103DD0                      @ 08103D9C  =gmpQueued
	ldr	r2, .Llit08103DD4                      @ 08103D9E  =gmpQueuedSaved
	ldr	r0, [r2]                               @ 08103DA0  gmpQueuedSaved
	str	r0, [r1]                               @ 08103DA2  gmpQueued
	movs	r1, #0                                @ 08103DA4
	str	r1, [r3]                               @ 08103DA6  gmpSkipSaved
	str	r1, [r2]                               @ 08103DA8  gmpQueuedSaved
	ldr	r2, .Llit08103DD8                      @ 08103DAA  =gmpPauseAfterJingleFlag
	ldr	r0, [r2]                               @ 08103DAC  gmpPauseAfterJingleFlag
	cmp	r0, #0                                 @ 08103DAE
	beq	.L08103DB8                             @ 08103DB0
	str	r1, [r2]                               @ 08103DB2  gmpPauseAfterJingleFlag
	bl	gmpPause                                @ 08103DB4
.L08103DB8:
	pop	{r0}                                   @ 08103DB8
	bx	r0                                      @ 08103DBA
.Llit08103DBC:
	.word	gmpJingleOn                          @ 08103DBC
.Llit08103DC0:
	.word	gmpJinglePri                         @ 08103DC0
.Llit08103DC4:
	.word	gmpReturnOrder                       @ 08103DC4
.Llit08103DC8:
	.word	gmpSkip                              @ 08103DC8
.Llit08103DCC:
	.word	gmpSkipSaved                         @ 08103DCC
.Llit08103DD0:
	.word	gmpQueued                            @ 08103DD0
.Llit08103DD4:
	.word	gmpQueuedSaved                       @ 08103DD4
.Llit08103DD8:
	.word	gmpPauseAfterJingleFlag              @ 08103DD8
@ --------------------------------------------------------------------------
@ gmpSkipPattern()  (0x08103DDC)  -- unused
@   gmpSkip = 1: the next Bxx goes to the next order
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpSkipPattern
gmpSkipPattern:
	ldr	r1, .Llit08103DE4                      @ 08103DDC  =gmpSkip
	movs	r0, #1                                @ 08103DDE
	str	r0, [r1]                               @ 08103DE0  gmpSkip
	bx	lr                                      @ 08103DE2
.Llit08103DE4:
	.word	gmpSkip                              @ 08103DE4
@ --------------------------------------------------------------------------
@ gmpPause()  (0x08103DE8)
@   gmpPaused = 1; gmpSoundOff()
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpPause
gmpPause:
	push	{lr}                                  @ 08103DE8
	ldr	r1, .Llit08103DF8                      @ 08103DEA  =gmpPaused
	movs	r0, #1                                @ 08103DEC
	str	r0, [r1]                               @ 08103DEE  gmpPaused
	bl	gmpSoundOff                             @ 08103DF0
	pop	{r0}                                   @ 08103DF4
	bx	r0                                      @ 08103DF6
.Llit08103DF8:
	.word	gmpPaused                            @ 08103DF8
@ --------------------------------------------------------------------------
@ gmpPauseAfterJingle()  (0x08103DFC)  -- unused
@   gmpPauseAfterJingle = 1
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpPauseAfterJingle
gmpPauseAfterJingle:
	ldr	r1, .Llit08103E04                      @ 08103DFC  =gmpPauseAfterJingleFlag
	movs	r0, #1                                @ 08103DFE
	str	r0, [r1]                               @ 08103E00  gmpPauseAfterJingleFlag
	bx	lr                                      @ 08103E02
.Llit08103E04:
	.word	gmpPauseAfterJingleFlag              @ 08103E04
@ --------------------------------------------------------------------------
@ gmpResume()  (0x08103E08)
@   gmpPaused = 0; gmpSoundOn()
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpResume
gmpResume:
	push	{lr}                                  @ 08103E08
	ldr	r1, .Llit08103E18                      @ 08103E0A  =gmpPaused
	movs	r0, #0                                @ 08103E0C
	str	r0, [r1]                               @ 08103E0E  gmpPaused
	bl	gmpSoundOn                              @ 08103E10
	pop	{r0}                                   @ 08103E14
	bx	r0                                      @ 08103E16
.Llit08103E18:
	.word	gmpPaused                            @ 08103E18
@ --------------------------------------------------------------------------
@ gmpClearChannels()  (0x08103E1C)
@   memset the first gmpChannels channel structs
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpClearChannels
gmpClearChannels:
	push	{r4, r5, r6, lr}                      @ 08103E1C
	movs	r4, #0                                @ 08103E1E
	ldr	r0, .Llit08103E48                      @ 08103E20  =gmpChannels
	ldr	r0, [r0]                               @ 08103E22  gmpChannels
	cmp	r4, r0                                 @ 08103E24
	bge	.L08103E42                             @ 08103E26
	movs	r5, #0                                @ 08103E28
	ldr	r6, .Llit08103E4C                      @ 08103E2A  =gmpChan
.L08103E2C:
	adds	r0, r5, r6                            @ 08103E2C
	movs	r1, #0                                @ 08103E2E
	movs	r2, #0x4c                             @ 08103E30
	bl	memset                                  @ 08103E32
	adds	r5, #0x4c                             @ 08103E36
	adds	r4, #1                                @ 08103E38
	ldr	r0, .Llit08103E48                      @ 08103E3A  =gmpChannels
	ldr	r0, [r0]                               @ 08103E3C  gmpChannels
	cmp	r4, r0                                 @ 08103E3E
	blt	.L08103E2C                             @ 08103E40
.L08103E42:
	pop	{r4, r5, r6}                           @ 08103E42
	pop	{r0}                                   @ 08103E44
	bx	r0                                      @ 08103E46
.Llit08103E48:
	.word	gmpChannels                          @ 08103E48
.Llit08103E4C:
	.word	gmpChan                              @ 08103E4C
@ --------------------------------------------------------------------------
@ gmpMixNext()  (0x08103E50)
@   if (gmpPaused) return 0; if (!gmpRate) return 1;
@   b = gmpCur ^ 1; if (gmpBufFree[b]) { gmpBufFree[b] = 0; gmpMix(gmpBuf[b]) }  return 0
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpMixNext
gmpMixNext:
	push	{r4, lr}                              @ 08103E50
	ldr	r0, .Llit08103E68                      @ 08103E52  =gmpPaused
	ldr	r4, [r0]                               @ 08103E54  gmpPaused
	cmp	r4, #0                                 @ 08103E56
	bne	.L08103E90                             @ 08103E58
	ldr	r0, .Llit08103E6C                      @ 08103E5A  =gmpRate
	ldr	r0, [r0]                               @ 08103E5C  gmpRate
	cmp	r0, #0                                 @ 08103E5E
	bne	.L08103E70                             @ 08103E60
	movs	r0, #1                                @ 08103E62
	b	.L08103E92                               @ 08103E64
	.hword	0x0000                              @ 08103E66  (padding)
.Llit08103E68:
	.word	gmpPaused                            @ 08103E68
.Llit08103E6C:
	.word	gmpRate                              @ 08103E6C
.L08103E70:
	ldr	r2, .Llit08103E98                      @ 08103E70  =gmpBufFree
	ldr	r0, .Llit08103E9C                      @ 08103E72  =gmpCur
	ldr	r0, [r0]                               @ 08103E74  gmpCur
	movs	r1, #1                                @ 08103E76
	eors	r0, r1                                @ 08103E78
	lsls	r3, r0, #2                            @ 08103E7A
	adds	r1, r3, r2                            @ 08103E7C
	ldr	r0, [r1]                               @ 08103E7E
	cmp	r0, #0                                 @ 08103E80
	beq	.L08103E90                             @ 08103E82
	str	r4, [r1]                               @ 08103E84
	ldr	r0, .Llit08103EA0                      @ 08103E86  =gmpBuf
	adds	r0, r3, r0                            @ 08103E88
	ldr	r0, [r0]                               @ 08103E8A
	bl	gmpMix                                  @ 08103E8C
.L08103E90:
	movs	r0, #0                                @ 08103E90
.L08103E92:
	pop	{r4}                                   @ 08103E92
	pop	{r1}                                   @ 08103E94
	bx	r1                                      @ 08103E96
.Llit08103E98:
	.word	gmpBufFree                           @ 08103E98
.Llit08103E9C:
	.word	gmpCur                               @ 08103E9C
.Llit08103EA0:
	.word	gmpBuf                               @ 08103EA0
@ --------------------------------------------------------------------------
@ gmpProcessRow()  (0x08103EA4)
@   if (gmpQueued && ((gmpCell / gmpChannels) & 3) != 0) { gmpQueued = 0; gmpStartSong(gmpQueuedOrder) }
@       -- the test looks inverted: the queued change happens on any row that is NOT a multiple
@          of 4 (v3's jingle switch waits for a multiple of 4)
@   p = patPtr[orders[gmpOrder]] + gmpCell * 4; last = gmpCell >= rows[pat] * gmpChannels
@   gmpCell += gmpChannels; gmpTick = gmpArpTick = 0; gmpJumped = 0
@   for each channel: gmpRowEffects(p, &gmpChan[i], last)   (last: the row is not stored = empty)
@   if (gmpCell == gmpChannels * 64) { gmpOrder++; if (gmpOrder >= songLen) gmpOrder = 0; gmpCell = 0 }
@   The song always loops; there is no end-of-song stop in this version.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpProcessRow
gmpProcessRow:
	push	{r4, r5, r6, r7, lr}                  @ 08103EA4
	ldr	r4, .Llit08103F68                      @ 08103EA6  =gmpQueued
	ldr	r0, [r4]                               @ 08103EA8  gmpQueued
	cmp	r0, #0                                 @ 08103EAA
	beq	.L08103ED0                             @ 08103EAC
	ldr	r0, .Llit08103F6C                      @ 08103EAE  =gmpCell
	ldrh	r0, [r0]                              @ 08103EB0  gmpCell
	ldr	r1, .Llit08103F70                      @ 08103EB2  =gmpChannels
	ldr	r1, [r1]                               @ 08103EB4  gmpChannels
	bl	__divsi3                                @ 08103EB6
	movs	r1, #3                                @ 08103EBA
	ands	r1, r0                                @ 08103EBC
	cmp	r1, #0                                 @ 08103EBE
	beq	.L08103ED0                             @ 08103EC0
	movs	r0, #0                                @ 08103EC2  jingle starts when (row & 3) != 0
	str	r0, [r4]                               @ 08103EC4  gmpQueued
	ldr	r0, .Llit08103F74                      @ 08103EC6  =gmpQueuedOrder
	movs	r1, #0                                @ 08103EC8
	ldrsh	r0, [r0, r1]                         @ 08103ECA
	bl	gmpStartSong                            @ 08103ECC
.L08103ED0:
	ldr	r1, .Llit08103F78                      @ 08103ED0  =gmpPlayer
	ldm	r1!, {r0}                              @ 08103ED2
	ldr	r2, .Llit08103F7C                      @ 08103ED4  =gmpOrder
	ldr	r3, .Llit08103F80                      @ 08103ED6  =0x00001874
	adds	r0, r0, r3                            @ 08103ED8
	ldrh	r2, [r2]                              @ 08103EDA  gmpOrder
	adds	r0, r2, r0                            @ 08103EDC
	ldr	r6, .Llit08103F84                      @ 08103EDE  =gmpChan
	ldrb	r0, [r0]                              @ 08103EE0
	lsls	r2, r0, #2                            @ 08103EE2
	adds	r1, r2, r1                            @ 08103EE4
	ldr	r4, [r1]                               @ 08103EE6
	ldr	r5, .Llit08103F6C                      @ 08103EE8  =gmpCell
	ldrh	r3, [r5]                              @ 08103EEA  gmpCell
	lsls	r0, r3, #2                            @ 08103EEC
	adds	r4, r4, r0                            @ 08103EEE
	ldr	r0, .Llit08103F88                      @ 08103EF0  =gmpPatRows
	ldr	r0, [r0]                               @ 08103EF2  gmpPatRows
	adds	r2, r2, r0                            @ 08103EF4
	ldr	r0, .Llit08103F70                      @ 08103EF6  =gmpChannels
	ldr	r1, [r2]                               @ 08103EF8
	ldr	r2, [r0]                               @ 08103EFA  gmpChannels
	adds	r0, r1, #0                            @ 08103EFC
	muls	r0, r2, r0                            @ 08103EFE
	movs	r7, #0                                @ 08103F00
	cmp	r3, r0                                 @ 08103F02
	blo	.L08103F08                             @ 08103F04
	movs	r7, #1                                @ 08103F06
.L08103F08:
	adds	r0, r3, r2                            @ 08103F08
	strh	r0, [r5]                              @ 08103F0A
	ldr	r0, .Llit08103F8C                      @ 08103F0C  =gmpTick
	movs	r1, #0                                @ 08103F0E
	strh	r1, [r0]                              @ 08103F10  gmpTick
	ldr	r0, .Llit08103F90                      @ 08103F12  =gmpArpTick
	strh	r1, [r0]                              @ 08103F14  gmpArpTick
	ldr	r0, .Llit08103F94                      @ 08103F16  =gmpJumped
	strb	r1, [r0]                              @ 08103F18  gmpJumped
	movs	r5, #0                                @ 08103F1A
	cmp	r5, r2                                 @ 08103F1C
	bge	.L08103F38                             @ 08103F1E
.L08103F20:
	adds	r0, r4, #0                            @ 08103F20
	adds	r1, r6, #0                            @ 08103F22
	adds	r2, r7, #0                            @ 08103F24
	bl	gmpRowEffects                           @ 08103F26
	adds	r4, #4                                @ 08103F2A
	adds	r6, #0x4c                             @ 08103F2C
	adds	r5, #1                                @ 08103F2E
	ldr	r0, .Llit08103F70                      @ 08103F30  =gmpChannels
	ldr	r0, [r0]                               @ 08103F32  gmpChannels
	cmp	r5, r0                                 @ 08103F34
	blt	.L08103F20                             @ 08103F36
.L08103F38:
	ldr	r2, .Llit08103F6C                      @ 08103F38  =gmpCell
	ldrh	r1, [r2]                              @ 08103F3A  gmpCell
	ldr	r0, .Llit08103F70                      @ 08103F3C  =gmpChannels
	ldr	r0, [r0]                               @ 08103F3E  gmpChannels
	lsls	r0, r0, #6                            @ 08103F40
	cmp	r1, r0                                 @ 08103F42
	bne	.L08103F62                             @ 08103F44
	ldr	r1, .Llit08103F7C                      @ 08103F46  =gmpOrder
	ldrh	r0, [r1]                              @ 08103F48  gmpOrder
	adds	r0, #1                                @ 08103F4A
	strh	r0, [r1]                              @ 08103F4C  gmpOrder
	ldr	r0, .Llit08103F78                      @ 08103F4E  =gmpPlayer
	ldr	r0, [r0]                               @ 08103F50  gmpPlayer
	ldr	r0, [r0, #0x18]                        @ 08103F52
	ldrh	r3, [r1]                              @ 08103F54  gmpOrder
	cmp	r3, r0                                 @ 08103F56
	blt	.L08103F5E                             @ 08103F58
	movs	r0, #0                                @ 08103F5A
	strh	r0, [r1]                              @ 08103F5C  gmpOrder
.L08103F5E:
	movs	r0, #0                                @ 08103F5E
	strh	r0, [r2]                              @ 08103F60
.L08103F62:
	pop	{r4, r5, r6, r7}                       @ 08103F62
	pop	{r0}                                   @ 08103F64
	bx	r0                                      @ 08103F66
.Llit08103F68:
	.word	gmpQueued                            @ 08103F68
.Llit08103F6C:
	.word	gmpCell                              @ 08103F6C
.Llit08103F70:
	.word	gmpChannels                          @ 08103F70
.Llit08103F74:
	.word	gmpQueuedOrder                       @ 08103F74
.Llit08103F78:
	.word	gmpPlayer                            @ 08103F78
.Llit08103F7C:
	.word	gmpOrder                             @ 08103F7C
.Llit08103F80:
	.word	0x00001874                           @ 08103F80
.Llit08103F84:
	.word	gmpChan                              @ 08103F84
.Llit08103F88:
	.word	gmpPatRows                           @ 08103F88
.Llit08103F8C:
	.word	gmpTick                              @ 08103F8C
.Llit08103F90:
	.word	gmpArpTick                           @ 08103F90
.Llit08103F94:
	.word	gmpJumped                            @ 08103F94
@ --------------------------------------------------------------------------
@ gmpMixChannelC(ch, dst, n)  (0x08103F98)  -- unused
@   C version of the ARM mixer (8-bit destination, loop handling identical).
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpMixChannelC
gmpMixChannelC:
	push	{r4, r5, r6, r7, lr}                  @ 08103F98
	mov	r7, sl                                 @ 08103F9A
	mov	r6, sb                                 @ 08103F9C
	mov	r5, r8                                 @ 08103F9E
	push	{r5, r6, r7}                          @ 08103FA0
	adds	r4, r0, #0                            @ 08103FA2
	adds	r5, r1, #0                            @ 08103FA4
	ldrh	r6, [r4, #0xc]                        @ 08103FA6  CH_end
	cmp	r6, #2                                 @ 08103FA8
	beq	.L08104000                             @ 08103FAA
	ldr	r0, [r4, #0x14]                        @ 08103FAC  CH_vol
	mov	ip, r0                                 @ 08103FAE
	ldr	r1, [r4]                               @ 08103FB0  CH_ptr
	ldr	r3, [r4, #4]                           @ 08103FB2  CH_pos
	ldr	r7, [r4, #8]                           @ 08103FB4  CH_step
	mov	sl, r7                                 @ 08103FB6
	cmp	r2, #0                                 @ 08103FB8
	ble	.L08103FFA                             @ 08103FBA
	movs	r0, #0                                @ 08103FBC
	mov	sb, r0                                 @ 08103FBE
	ldr	r7, .Llit08104010                      @ 08103FC0  =0x00000FFF
	mov	r8, r7                                 @ 08103FC2
.L08103FC4:
	lsrs	r0, r3, #0xc                          @ 08103FC4
	add	r3, sl                                 @ 08103FC6
	cmp	r0, r6                                 @ 08103FC8
	blo	.L08103FDC                             @ 08103FCA
	ldrh	r0, [r4, #0xe]                        @ 08103FCC
	adds	r1, r0, r1                            @ 08103FCE
	ldrh	r6, [r4, #0x10]                       @ 08103FD0
	mov	r7, sb                                 @ 08103FD2
	strh	r7, [r4, #0xe]                        @ 08103FD4
	mov	r0, r8                                 @ 08103FD6
	ands	r3, r0                                @ 08103FD8
	lsrs	r0, r3, #0xc                          @ 08103FDA
.L08103FDC:
	adds	r0, r1, r0                            @ 08103FDC
	ldrb	r0, [r0]                              @ 08103FDE
	lsls	r0, r0, #0x18                         @ 08103FE0
	asrs	r0, r0, #0x18                         @ 08103FE2
	mov	r7, ip                                 @ 08103FE4
	muls	r7, r0, r7                            @ 08103FE6
	adds	r0, r7, #0                            @ 08103FE8
	asrs	r0, r0, #8                            @ 08103FEA
	ldrb	r7, [r5]                              @ 08103FEC
	adds	r0, r7, r0                            @ 08103FEE
	strb	r0, [r5]                              @ 08103FF0
	adds	r5, #1                                @ 08103FF2
	subs	r2, #1                                @ 08103FF4
	cmp	r2, #0                                 @ 08103FF6
	bgt	.L08103FC4                             @ 08103FF8
.L08103FFA:
	str	r1, [r4]                               @ 08103FFA
	str	r3, [r4, #4]                           @ 08103FFC
	strh	r6, [r4, #0xc]                        @ 08103FFE
.L08104000:
	pop	{r3, r4, r5}                           @ 08104000
	mov	r8, r3                                 @ 08104002
	mov	sb, r4                                 @ 08104004
	mov	sl, r5                                 @ 08104006
	pop	{r4, r5, r6, r7}                       @ 08104008
	pop	{r0}                                   @ 0810400A
	bx	r0                                      @ 0810400C
	.hword	0x0000                              @ 0810400E  (padding)
.Llit08104010:
	.word	0x00000FFF                           @ 08104010
@ --------------------------------------------------------------------------
@ gmpMixChannelC32(ch, dst, n)  (0x08104014)  -- unused
@   Same, but adds into a 32-bit accumulator buffer: an unused higher-precision path.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpMixChannelC32
gmpMixChannelC32:
	push	{r4, r5, r6, r7, lr}                  @ 08104014
	mov	r7, sl                                 @ 08104016
	mov	r6, sb                                 @ 08104018
	mov	r5, r8                                 @ 0810401A
	push	{r5, r6, r7}                          @ 0810401C
	adds	r4, r0, #0                            @ 0810401E
	adds	r7, r1, #0                            @ 08104020
	ldrh	r6, [r4, #0xc]                        @ 08104022  CH_end
	cmp	r6, #2                                 @ 08104024
	beq	.L08104078                             @ 08104026
	ldr	r0, [r4, #0x14]                        @ 08104028  CH_vol
	mov	r8, r0                                 @ 0810402A
	ldr	r5, [r4]                               @ 0810402C  CH_ptr
	ldr	r3, [r4, #4]                           @ 0810402E  CH_pos
	ldr	r0, [r4, #8]                           @ 08104030  CH_step
	mov	ip, r0                                 @ 08104032
	cmp	r2, #0                                 @ 08104034
	ble	.L08104072                             @ 08104036
	movs	r0, #0                                @ 08104038
	mov	sl, r0                                 @ 0810403A
	ldr	r0, .Llit08104088                      @ 0810403C  =0x00000FFF
	mov	sb, r0                                 @ 0810403E
.L08104040:
	lsrs	r0, r3, #0xc                          @ 08104040
	add	r3, ip                                 @ 08104042
	cmp	r0, r6                                 @ 08104044
	blo	.L08104058                             @ 08104046
	ldrh	r0, [r4, #0xe]                        @ 08104048
	adds	r5, r0, r5                            @ 0810404A
	ldrh	r6, [r4, #0x10]                       @ 0810404C
	mov	r0, sl                                 @ 0810404E
	strh	r0, [r4, #0xe]                        @ 08104050
	mov	r0, sb                                 @ 08104052
	ands	r3, r0                                @ 08104054
	lsrs	r0, r3, #0xc                          @ 08104056
.L08104058:
	adds	r0, r5, r0                            @ 08104058
	movs	r1, #0                                @ 0810405A
	ldrsb	r1, [r0, r1]                         @ 0810405C
	mov	r0, r8                                 @ 0810405E
	muls	r0, r1, r0                            @ 08104060
	adds	r1, r0, #0                            @ 08104062
	asrs	r1, r1, #8                            @ 08104064
	ldr	r0, [r7]                               @ 08104066
	adds	r0, r0, r1                            @ 08104068
	stm	r7!, {r0}                              @ 0810406A
	subs	r2, #1                                @ 0810406C
	cmp	r2, #0                                 @ 0810406E
	bgt	.L08104040                             @ 08104070
.L08104072:
	str	r5, [r4]                               @ 08104072
	str	r3, [r4, #4]                           @ 08104074
	strh	r6, [r4, #0xc]                        @ 08104076
.L08104078:
	pop	{r3, r4, r5}                           @ 08104078
	mov	r8, r3                                 @ 0810407A
	mov	sb, r4                                 @ 0810407C
	mov	sl, r5                                 @ 0810407E
	pop	{r4, r5, r6, r7}                       @ 08104080
	pop	{r0}                                   @ 08104082
	bx	r0                                      @ 08104084
	.hword	0x0000                              @ 08104086  (padding)
.Llit08104088:
	.word	0x00000FFF                           @ 08104088
@ --------------------------------------------------------------------------
@ gmpMix(dst)  (0x0810408C)
@   attM = clamp(max(64 - master, 64 - music), 0, 64); attS = clamp(max(64 - master, 64 - sfx), 0, 64)
@   memset(dst, 0, 352)
@   do { if (!gmpRowLeft) { gmpProcessRow(); gmpRowLeft = gmpRowLen }
@        if (!gmpTickLeft) { if (gmpRowLeft != gmpRowLen) gmpProcessTick(); gmpTickLeft = gmpTickLen }
@             (no tick processing on a row's first tick, as in ProTracker)
@        n = min(gmpRowLeft, gmpTickLeft, 352 - done)
@        for the 8 channels: if (CH_ptr && CH_end != 2) { v = CH_vol - (first six ? attM : attS);
@            if (v > 0 && CH_end > 2) mixer(ch, dst, n) with CH_vol = v }
@        dst += n; counters -= n } while (done < 352)
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpMix
gmpMix:
	push	{r4, r5, r6, r7, lr}                  @ 0810408C
	mov	r7, sl                                 @ 0810408E
	mov	r6, sb                                 @ 08104090
	mov	r5, r8                                 @ 08104092
	push	{r5, r6, r7}                          @ 08104094
	sub	sp, #0x5c                              @ 08104096
	adds	r1, r0, #0                            @ 08104098
	ldr	r0, .Llit08104180                      @ 0810409A  =gmpMasterVol
	ldr	r3, [r0]                               @ 0810409C  gmpMasterVol
	movs	r2, #0x40                             @ 0810409E
	subs	r0, r2, r3                            @ 081040A0
	mov	sl, r0                                 @ 081040A2
	ldr	r0, .Llit08104184                      @ 081040A4  =gmpMusicVol
	ldr	r0, [r0]                               @ 081040A6  gmpMusicVol
	subs	r0, r2, r0                            @ 081040A8
	cmp	sl, r0                                 @ 081040AA
	bge	.L081040B0                             @ 081040AC
	mov	sl, r0                                 @ 081040AE
.L081040B0:
	mov	r0, sl                                 @ 081040B0
	cmp	r0, #0                                 @ 081040B2
	bge	.L081040BA                             @ 081040B4
	movs	r0, #0                                @ 081040B6
	mov	sl, r0                                 @ 081040B8
.L081040BA:
	mov	r0, sl                                 @ 081040BA
	cmp	r0, #0x40                              @ 081040BC
	ble	.L081040C4                             @ 081040BE
	movs	r0, #0x40                             @ 081040C0
	mov	sl, r0                                 @ 081040C2
.L081040C4:
	subs	r3, r2, r3                            @ 081040C4
	mov	sb, r3                                 @ 081040C6
	ldr	r0, .Llit08104188                      @ 081040C8  =gmpSfxVol
	ldr	r0, [r0]                               @ 081040CA  gmpSfxVol
	subs	r0, r2, r0                            @ 081040CC
	cmp	sb, r0                                 @ 081040CE
	bge	.L081040D4                             @ 081040D0
	mov	sb, r0                                 @ 081040D2
.L081040D4:
	mov	r2, sb                                 @ 081040D4
	cmp	r2, #0                                 @ 081040D6
	bge	.L081040DE                             @ 081040D8
	movs	r0, #0                                @ 081040DA
	mov	sb, r0                                 @ 081040DC
.L081040DE:
	mov	r2, sb                                 @ 081040DE
	cmp	r2, #0x40                              @ 081040E0
	ble	.L081040E8                             @ 081040E2
	movs	r0, #0x40                             @ 081040E4
	mov	sb, r0                                 @ 081040E6
.L081040E8:
	movs	r2, #0                                @ 081040E8
	str	r2, [sp, #0x4c]                        @ 081040EA
	mov	r8, r1                                 @ 081040EC
	ldr	r4, .Llit0810418C                      @ 081040EE  =gmpBufBytes
	ldr	r2, [r4]                               @ 081040F0  gmpBufBytes
	mov	r0, r8                                 @ 081040F2
	movs	r1, #0                                @ 081040F4
	bl	memset                                  @ 081040F6
	ldr	r6, [r4]                               @ 081040FA  gmpBufBytes
	cmp	r6, #0                                 @ 081040FC
	ble	.L081041F8                             @ 081040FE
.L08104100:
	ldr	r1, .Llit08104190                      @ 08104100  =gmpRowLeft
	ldr	r0, [r1]                               @ 08104102  gmpRowLeft
	cmp	r0, #0                                 @ 08104104
	bne	.L08104114                             @ 08104106
	bl	gmpProcessRow                           @ 08104108
	ldr	r0, .Llit08104194                      @ 0810410C  =gmpRowLen
	ldr	r0, [r0]                               @ 0810410E  gmpRowLen
	ldr	r2, .Llit08104190                      @ 08104110  =gmpRowLeft
	str	r0, [r2]                               @ 08104112  gmpRowLeft
.L08104114:
	ldr	r4, .Llit08104198                      @ 08104114  =gmpTickLeft
	ldr	r0, [r4]                               @ 08104116  gmpTickLeft
	cmp	r0, #0                                 @ 08104118
	bne	.L08104132                             @ 0810411A
	ldr	r0, .Llit08104194                      @ 0810411C  =gmpRowLen
	ldr	r2, .Llit08104190                      @ 0810411E  =gmpRowLeft
	ldr	r1, [r2]                               @ 08104120  gmpRowLeft
	ldr	r0, [r0]                               @ 08104122  gmpRowLen
	cmp	r1, r0                                 @ 08104124
	beq	.L0810412C                             @ 08104126
	bl	gmpProcessTick                          @ 08104128
.L0810412C:
	ldr	r0, .Llit0810419C                      @ 0810412C  =gmpTickLen
	ldr	r0, [r0]                               @ 0810412E  gmpTickLen
	str	r0, [r4]                               @ 08104130
.L08104132:
	ldr	r1, .Llit08104190                      @ 08104132  =gmpRowLeft
	ldr	r0, [r1]                               @ 08104134  gmpRowLeft
	ldr	r2, .Llit08104198                      @ 08104136  =gmpTickLeft
	ldr	r5, [r2]                               @ 08104138  gmpTickLeft
	cmp	r0, r5                                 @ 0810413A
	bge	.L08104140                             @ 0810413C
	adds	r5, r0, #0                            @ 0810413E
.L08104140:
	ldr	r0, .Llit0810418C                      @ 08104140  =gmpBufBytes
	ldr	r1, [r0]                               @ 08104142  gmpBufBytes
	cmp	r5, r1                                 @ 08104144
	ble	.L0810414A                             @ 08104146
	adds	r5, r1, #0                            @ 08104148
.L0810414A:
	ldr	r2, [sp, #0x4c]                        @ 0810414A
	adds	r0, r2, r5                            @ 0810414C
	cmp	r0, r1                                 @ 0810414E
	ble	.L08104154                             @ 08104150
	subs	r5, r1, r2                            @ 08104152
.L08104154:
	ldr	r4, .Llit081041A0                      @ 08104154  =gmpChan
	movs	r7, #8                                @ 08104156
	ldr	r0, [sp, #0x4c]                        @ 08104158
	adds	r0, r0, r5                            @ 0810415A
	str	r0, [sp, #0x58]                        @ 0810415C
	mov	r1, r8                                 @ 0810415E
	adds	r1, r1, r5                            @ 08104160
	str	r1, [sp, #0x54]                        @ 08104162
	subs	r6, r6, r5                            @ 08104164
	str	r6, [sp, #0x50]                        @ 08104166
.L08104168:
	ldr	r0, [r4]                               @ 08104168
	cmp	r0, #0                                 @ 0810416A
	beq	.L081041D0                             @ 0810416C
	ldrh	r2, [r4, #0xc]                        @ 0810416E
	cmp	r2, #2                                 @ 08104170
	beq	.L081041D0                             @ 08104172
	ldr	r6, [r4, #0x14]                        @ 08104174
	cmp	r7, #2                                 @ 08104176
	ble	.L081041A4                             @ 08104178
	mov	r1, sl                                 @ 0810417A
	subs	r0, r6, r1                            @ 0810417C
	b	.L081041A8                               @ 0810417E
.Llit08104180:
	.word	gmpMasterVol                         @ 08104180
.Llit08104184:
	.word	gmpMusicVol                          @ 08104184
.Llit08104188:
	.word	gmpSfxVol                            @ 08104188
.Llit0810418C:
	.word	gmpBufBytes                          @ 0810418C
.Llit08104190:
	.word	gmpRowLeft                           @ 08104190
.Llit08104194:
	.word	gmpRowLen                            @ 08104194
.Llit08104198:
	.word	gmpTickLeft                          @ 08104198
.Llit0810419C:
	.word	gmpTickLen                           @ 0810419C
.Llit081041A0:
	.word	gmpChan                              @ 081041A0
.L081041A4:
	mov	r2, sb                                 @ 081041A4
	subs	r0, r6, r2                            @ 081041A6
.L081041A8:
	str	r0, [r4, #0x14]                        @ 081041A8
	ldr	r0, [r4, #0x14]                        @ 081041AA
	cmp	r0, #0                                 @ 081041AC
	bge	.L081041B4                             @ 081041AE
	movs	r0, #0                                @ 081041B0
	str	r0, [r4, #0x14]                        @ 081041B2
.L081041B4:
	ldr	r0, [r4, #0x14]                        @ 081041B4
	cmp	r0, #0                                 @ 081041B6
	beq	.L081041CE                             @ 081041B8
	ldrh	r0, [r4, #0xc]                        @ 081041BA
	cmp	r0, #2                                 @ 081041BC
	bls	.L081041CE                             @ 081041BE
	ldr	r0, .Llit08104208                      @ 081041C0  =gmpMixer
	ldr	r3, [r0]                               @ 081041C2  gmpMixer
	adds	r0, r4, #0                            @ 081041C4
	mov	r1, r8                                 @ 081041C6
	adds	r2, r5, #0                            @ 081041C8
	bl	gmpCallR3                               @ 081041CA
.L081041CE:
	str	r6, [r4, #0x14]                        @ 081041CE
.L081041D0:
	adds	r4, #0x4c                             @ 081041D0
	subs	r7, #1                                @ 081041D2
	cmp	r7, #0                                 @ 081041D4
	bgt	.L08104168                             @ 081041D6
	ldr	r1, [sp, #0x54]                        @ 081041D8
	mov	r8, r1                                 @ 081041DA
	ldr	r2, [sp, #0x58]                        @ 081041DC
	str	r2, [sp, #0x4c]                        @ 081041DE
	ldr	r1, .Llit0810420C                      @ 081041E0  =gmpRowLeft
	ldr	r0, [r1]                               @ 081041E2  gmpRowLeft
	subs	r0, r0, r5                            @ 081041E4
	str	r0, [r1]                               @ 081041E6  gmpRowLeft
	ldr	r2, .Llit08104210                      @ 081041E8  =gmpTickLeft
	ldr	r0, [r2]                               @ 081041EA  gmpTickLeft
	subs	r0, r0, r5                            @ 081041EC
	str	r0, [r2]                               @ 081041EE  gmpTickLeft
	ldr	r6, [sp, #0x50]                        @ 081041F0
	subs	r6, #1                                @ 081041F2
	cmp	r6, #0                                 @ 081041F4
	bgt	.L08104100                             @ 081041F6
.L081041F8:
	add	sp, #0x5c                              @ 081041F8
	pop	{r3, r4, r5}                           @ 081041FA
	mov	r8, r3                                 @ 081041FC
	mov	sb, r4                                 @ 081041FE
	mov	sl, r5                                 @ 08104200
	pop	{r4, r5, r6, r7}                       @ 08104202
	pop	{r0}                                   @ 08104204
	bx	r0                                      @ 08104206
.Llit08104208:
	.word	gmpMixer                             @ 08104208
.Llit0810420C:
	.word	gmpRowLeft                           @ 0810420C
.Llit08104210:
	.word	gmpTickLeft                          @ 08104210
@ --------------------------------------------------------------------------
@ gmpPlayNote(player, ins, note, channel)  (0x08104214)  -- unused
@   Starts a module sample on channel 0..7 (instrument ins, period index note): the same fields
@   as a row note-on.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpPlayNote
gmpPlayNote:
	push	{r4, r5, r6, lr}                      @ 08104214
	adds	r6, r0, #0                            @ 08104216
	lsls	r1, r1, #0x10                         @ 08104218
	lsrs	r4, r1, #0x10                         @ 0810421A
	lsls	r2, r2, #0x10                         @ 0810421C
	lsrs	r5, r2, #0x10                         @ 0810421E
	lsls	r3, r3, #0x10                         @ 08104220
	lsrs	r1, r3, #0x10                         @ 08104222
	cmp	r1, #7                                 @ 08104224
	bhi	.L08104284                             @ 08104226
	movs	r0, #0x4c                             @ 08104228
	muls	r1, r0, r1                            @ 0810422A
	ldr	r0, .Llit0810428C                      @ 0810422C  =gmpChan
	adds	r3, r1, r0                            @ 0810422E
	ldr	r2, [r6]                               @ 08104230
	ldr	r0, .Llit08104290                      @ 08104232  =0x0000FFFF
	cmp	r5, r0                                 @ 08104234
	beq	.L08104284                             @ 08104236
	cmp	r4, #0                                 @ 08104238
	beq	.L08104244                             @ 0810423A
	subs	r1, r4, #1                            @ 0810423C
	lsls	r0, r1, #0x10                         @ 0810423E
	lsrs	r4, r0, #0x10                         @ 08104240
	strh	r1, [r3, #0x18]                       @ 08104242
.L08104244:
	lsls	r1, r4, #1                            @ 08104244
	adds	r1, r1, r4                            @ 08104246
	lsls	r1, r1, #2                            @ 08104248
	ldr	r0, .Llit08104294                      @ 0810424A  =0x000016FC
	adds	r1, r1, r0                            @ 0810424C
	adds	r1, r2, r1                            @ 0810424E
	lsls	r2, r4, #2                            @ 08104250
	movs	r4, #0x82                             @ 08104252
	lsls	r4, r4, #1                            @ 08104254
	adds	r0, r6, r4                            @ 08104256
	adds	r0, r0, r2                            @ 08104258
	ldr	r0, [r0]                               @ 0810425A
	str	r0, [r3]                               @ 0810425C
	ldrh	r0, [r1]                              @ 0810425E
	movs	r2, #0                                @ 08104260
	strh	r0, [r3, #0xc]                        @ 08104262
	ldrh	r0, [r1, #6]                          @ 08104264
	strh	r0, [r3, #0xe]                        @ 08104266
	ldrh	r0, [r1, #8]                          @ 08104268
	strh	r0, [r3, #0x10]                       @ 0810426A
	ldrh	r0, [r1, #4]                          @ 0810426C
	str	r0, [r3, #0x14]                        @ 0810426E
	strh	r5, [r3, #0x1e]                       @ 08104270
	str	r2, [r3, #4]                           @ 08104272
	strh	r2, [r3, #0x1c]                       @ 08104274
	strh	r2, [r3, #0x2c]                       @ 08104276
	ldr	r0, .Llit08104298                      @ 08104278  =gmpStepTab
	ldr	r1, [r0]                               @ 0810427A  gmpStepTab
	lsls	r0, r5, #2                            @ 0810427C
	adds	r0, r0, r1                            @ 0810427E
	ldr	r0, [r0]                               @ 08104280
	str	r0, [r3, #8]                           @ 08104282
.L08104284:
	pop	{r4, r5, r6}                           @ 08104284
	pop	{r0}                                   @ 08104286
	bx	r0                                      @ 08104288
	.hword	0x0000                              @ 0810428A  (padding)
.Llit0810428C:
	.word	gmpChan                              @ 0810428C
.Llit08104290:
	.word	0x0000FFFF                           @ 08104290
.Llit08104294:
	.word	0x000016FC                           @ 08104294
.Llit08104298:
	.word	gmpStepTab                           @ 08104298
@ --------------------------------------------------------------------------
@ gmpLoadSfxBank(bank)  (0x0810429C)
@   gmpSfxCount = bank[0]; gmpSfxEntries = bank + 4; gmpSfxData = bank + 4 + count * 20
@   Entry: {u32 offset, u32 length, u16 ?, u16 volume, u16 loopStart, u16 loopLen, u32 ?}
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpLoadSfxBank
gmpLoadSfxBank:
	ldr	r1, .Llit081042B4                      @ 0810429C  =gmpSfxCount
	ldm	r0!, {r2}                              @ 0810429E
	str	r2, [r1]                               @ 081042A0  gmpSfxCount
	ldr	r1, .Llit081042B8                      @ 081042A2  =gmpSfxEntries
	str	r0, [r1]                               @ 081042A4  gmpSfxEntries
	ldr	r3, .Llit081042BC                      @ 081042A6  =gmpSfxData
	lsls	r1, r2, #2                            @ 081042A8
	adds	r1, r1, r2                            @ 081042AA
	lsls	r1, r1, #2                            @ 081042AC
	adds	r0, r0, r1                            @ 081042AE
	str	r0, [r3]                               @ 081042B0  gmpSfxData
	bx	lr                                      @ 081042B2
.Llit081042B4:
	.word	gmpSfxCount                          @ 081042B4
.Llit081042B8:
	.word	gmpSfxEntries                        @ 081042B8
.Llit081042BC:
	.word	gmpSfxData                           @ 081042BC
@ --------------------------------------------------------------------------
@ gmpPlaySfx(sfx, note, channel, volume)  (0x081042C0)
@   c = channel + gmpChannels, must be <= 7; sfx < gmpSfxCount; note != 0xFFFF
@   CH_ins = sfx; CH_ptr = gmpSfxData + e.offset; CH_end = (u16)e.length; CH_loopStart = e.loopStart;
@   CH_loopLen = e.loopLen; CH_vol = volume; CH_note = note; CH_step = gmpStepTab[note]
@   Two problems: CH_end is 16 bits, so SFX 25 of Aero (68 027 bytes) is cut to 2 491 bytes; and
@   the pitch comes from the step table of whichever module is loaded.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpPlaySfx
gmpPlaySfx:
	push	{r4, r5, r6, r7, lr}                  @ 081042C0
	adds	r7, r3, #0                            @ 081042C2
	lsls	r0, r0, #0x10                         @ 081042C4
	lsrs	r5, r0, #0x10                         @ 081042C6
	lsls	r1, r1, #0x10                         @ 081042C8
	lsrs	r6, r1, #0x10                         @ 081042CA
	lsls	r2, r2, #0x10                         @ 081042CC
	lsrs	r2, r2, #0x10                         @ 081042CE
	ldr	r0, .Llit08104338                      @ 081042D0  =gmpChannels
	ldr	r0, [r0]                               @ 081042D2  gmpChannels
	adds	r2, r2, r0                            @ 081042D4
	lsls	r2, r2, #0x10                         @ 081042D6
	lsrs	r1, r2, #0x10                         @ 081042D8
	cmp	r1, #7                                 @ 081042DA
	bhi	.L08104330                             @ 081042DC
	ldr	r0, .Llit0810433C                      @ 081042DE  =gmpSfxCount
	ldr	r0, [r0]                               @ 081042E0  gmpSfxCount
	cmp	r5, r0                                 @ 081042E2
	bge	.L08104330                             @ 081042E4
	movs	r0, #0x4c                             @ 081042E6
	muls	r1, r0, r1                            @ 081042E8
	ldr	r0, .Llit08104340                      @ 081042EA  =gmpChan
	adds	r4, r1, r0                            @ 081042EC
	ldr	r0, .Llit08104344                      @ 081042EE  =0x0000FFFF
	cmp	r6, r0                                 @ 081042F0
	beq	.L08104330                             @ 081042F2
	movs	r3, #0                                @ 081042F4
	strh	r5, [r4, #0x18]                       @ 081042F6
	ldr	r1, .Llit08104348                      @ 081042F8  =gmpSfxEntries
	lsls	r0, r5, #2                            @ 081042FA
	adds	r0, r0, r5                            @ 081042FC
	lsls	r0, r0, #2                            @ 081042FE
	ldr	r2, [r1]                               @ 08104300  gmpSfxEntries
	adds	r2, r2, r0                            @ 08104302
	ldr	r0, .Llit0810434C                      @ 08104304  =gmpSfxData
	ldr	r0, [r0]                               @ 08104306  gmpSfxData
	ldr	r1, [r2]                               @ 08104308
	adds	r0, r0, r1                            @ 0810430A
	str	r0, [r4]                               @ 0810430C
	ldr	r0, [r2, #4]                           @ 0810430E
	strh	r0, [r4, #0xc]                        @ 08104310  CH_end is 16 bits: long SFX are truncated
	ldrh	r0, [r2, #0xc]                        @ 08104312
	strh	r0, [r4, #0xe]                        @ 08104314
	ldrh	r0, [r2, #0xe]                        @ 08104316
	strh	r0, [r4, #0x10]                       @ 08104318
	str	r7, [r4, #0x14]                        @ 0810431A
	strh	r6, [r4, #0x1e]                       @ 0810431C
	str	r3, [r4, #4]                           @ 0810431E
	strh	r3, [r4, #0x1c]                       @ 08104320
	strh	r3, [r4, #0x2c]                       @ 08104322
	ldr	r0, .Llit08104350                      @ 08104324  =gmpStepTab
	ldr	r1, [r0]                               @ 08104326  gmpStepTab
	lsls	r0, r6, #2                            @ 08104328
	adds	r0, r0, r1                            @ 0810432A
	ldr	r0, [r0]                               @ 0810432C
	str	r0, [r4, #8]                           @ 0810432E
.L08104330:
	pop	{r4, r5, r6, r7}                       @ 08104330
	pop	{r0}                                   @ 08104332
	bx	r0                                      @ 08104334
	.hword	0x0000                              @ 08104336  (padding)
.Llit08104338:
	.word	gmpChannels                          @ 08104338
.Llit0810433C:
	.word	gmpSfxCount                          @ 0810433C
.Llit08104340:
	.word	gmpChan                              @ 08104340
.Llit08104344:
	.word	0x0000FFFF                           @ 08104344
.Llit08104348:
	.word	gmpSfxEntries                        @ 08104348
.Llit0810434C:
	.word	gmpSfxData                           @ 0810434C
.Llit08104350:
	.word	gmpStepTab                           @ 08104350
@ --------------------------------------------------------------------------
@ gmpStopSfx(channel)  (0x08104354)
@   gmpChan[channel + gmpChannels].CH_end = 2
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpStopSfx
gmpStopSfx:
	lsls	r0, r0, #0x10                         @ 08104354
	lsrs	r0, r0, #0x10                         @ 08104356
	ldr	r1, .Llit08104374                      @ 08104358  =gmpChannels
	ldr	r1, [r1]                               @ 0810435A  gmpChannels
	adds	r0, r0, r1                            @ 0810435C
	lsls	r0, r0, #0x10                         @ 0810435E
	lsrs	r1, r0, #0x10                         @ 08104360
	cmp	r1, #7                                 @ 08104362
	bhi	.L08104372                             @ 08104364
	movs	r0, #0x4c                             @ 08104366
	muls	r0, r1, r0                            @ 08104368
	ldr	r1, .Llit08104378                      @ 0810436A  =gmpChan
	adds	r0, r0, r1                            @ 0810436C
	movs	r1, #2                                @ 0810436E
	strh	r1, [r0, #0xc]                        @ 08104370
.L08104372:
	bx	lr                                      @ 08104372
.Llit08104374:
	.word	gmpChannels                          @ 08104374
.Llit08104378:
	.word	gmpChan                              @ 08104378
@ --------------------------------------------------------------------------
@ fxVolumeSlide(ch)  (0x0810437C)
@   if (gmpTick && (up|down)) CH_vol += up ? up : -down; clamp 0..64
@ --------------------------------------------------------------------------
	.thumb_func
	.global fxVolumeSlide
fxVolumeSlide:
	push	{r4, lr}                              @ 0810437C
	adds	r1, r0, #0                            @ 0810437E
	ldrh	r2, [r1, #0x24]                       @ 08104380  CH_vsUp
	ldrh	r3, [r1, #0x26]                       @ 08104382  CH_vsDown
	ldr	r0, .Llit0810439C                      @ 08104384  =gmpTick
	movs	r4, #0                                @ 08104386
	ldrsh	r0, [r0, r4]                         @ 08104388
	cmp	r0, #0                                 @ 0810438A
	beq	.L081043BA                             @ 0810438C
	cmn	r2, r3                                 @ 0810438E
	beq	.L081043BA                             @ 08104390
	cmp	r2, #0                                 @ 08104392
	beq	.L081043A0                             @ 08104394
	ldr	r0, [r1, #0x14]                        @ 08104396  CH_vol
	adds	r0, r0, r2                            @ 08104398
	b	.L081043A4                               @ 0810439A
.Llit0810439C:
	.word	gmpTick                              @ 0810439C
.L081043A0:
	ldr	r0, [r1, #0x14]                        @ 081043A0
	subs	r0, r0, r3                            @ 081043A2
.L081043A4:
	str	r0, [r1, #0x14]                        @ 081043A4
	ldr	r0, [r1, #0x14]                        @ 081043A6
	cmp	r0, #0                                 @ 081043A8
	bge	.L081043B0                             @ 081043AA
	movs	r0, #0                                @ 081043AC
	str	r0, [r1, #0x14]                        @ 081043AE
.L081043B0:
	ldr	r0, [r1, #0x14]                        @ 081043B0
	cmp	r0, #0x40                              @ 081043B2
	ble	.L081043BA                             @ 081043B4
	movs	r0, #0x40                             @ 081043B6
	str	r0, [r1, #0x14]                        @ 081043B8
.L081043BA:
	pop	{r4}                                   @ 081043BA
	pop	{r0}                                   @ 081043BC
	bx	r0                                      @ 081043BE
@ --------------------------------------------------------------------------
@ fxTonePorta(ch)  (0x081043C0)
@   CH_portaOfs += CH_portaStep;
@   done = CH_portaStep > 0 ? !(gmpStepTab[note] + ofs < gmpStepTab[target])
@                           : !(gmpStepTab[note] + ofs > gmpStepTab[target]);
@   if (done) { CH_note = target; CH_portaStep = CH_portaOfs = 0 }
@   The offset is a *period* offset but is added to a *step* here.  Sliding down, the current
@   step is already above the target step, and sliding up below it, so the test is true on the
@   first tick: tone portamento jumps straight to the target note.  (v3 has the same code in its
@   Amiga-period mode; v1 keeps everything in steps and slides correctly.)
@ --------------------------------------------------------------------------
	.thumb_func
	.global fxTonePorta
fxTonePorta:
	push	{r4, r5, lr}                          @ 081043C0
	adds	r4, r0, #0                            @ 081043C2
	ldrh	r0, [r4, #0x38]                       @ 081043C4  CH_portaStep
	ldrh	r2, [r4, #0x34]                       @ 081043C6  CH_portaOfs
	adds	r1, r0, r2                            @ 081043C8
	movs	r5, #0                                @ 081043CA
	strh	r1, [r4, #0x34]                       @ 081043CC  CH_portaOfs
	lsls	r0, r0, #0x10                         @ 081043CE
	cmp	r0, #0                                 @ 081043D0
	ble	.L081043FC                             @ 081043D2
	ldr	r0, .Llit081043F8                      @ 081043D4  =gmpStepTab
	ldr	r3, [r0]                               @ 081043D6  gmpStepTab
	ldrh	r1, [r4, #0x1e]                       @ 081043D8  CH_note
	lsls	r0, r1, #2                            @ 081043DA
	adds	r0, r0, r3                            @ 081043DC
	movs	r1, #0x34                             @ 081043DE
	ldrsh	r2, [r4, r1]                         @ 081043E0  CH_portaOfs
	ldr	r1, [r0]                               @ 081043E2
	adds	r1, r1, r2                            @ 081043E4
	movs	r2, #0x3a                             @ 081043E6
	ldrsh	r0, [r4, r2]                         @ 081043E8  CH_tpTarget
	lsls	r0, r0, #2                            @ 081043EA
	adds	r0, r0, r3                            @ 081043EC
	ldr	r0, [r0]                               @ 081043EE
	cmp	r1, r0                                 @ 081043F0
	blo	.L08104424                             @ 081043F2
	b	.L0810441C                               @ 081043F4
	.hword	0x0000                              @ 081043F6  (padding)
.Llit081043F8:
	.word	gmpStepTab                           @ 081043F8
.L081043FC:
	ldr	r0, .Llit0810442C                      @ 081043FC  =gmpStepTab
	ldr	r3, [r0]                               @ 081043FE  gmpStepTab
	ldrh	r1, [r4, #0x1e]                       @ 08104400
	lsls	r0, r1, #2                            @ 08104402
	adds	r0, r0, r3                            @ 08104404
	movs	r1, #0x34                             @ 08104406
	ldrsh	r2, [r4, r1]                         @ 08104408
	ldr	r1, [r0]                               @ 0810440A
	adds	r1, r1, r2                            @ 0810440C
	movs	r2, #0x3a                             @ 0810440E
	ldrsh	r0, [r4, r2]                         @ 08104410
	lsls	r0, r0, #2                            @ 08104412
	adds	r0, r0, r3                            @ 08104414
	ldr	r0, [r0]                               @ 08104416
	cmp	r1, r0                                 @ 08104418
	bhi	.L08104424                             @ 0810441A
.L0810441C:
	ldrh	r0, [r4, #0x3a]                       @ 0810441C
	strh	r0, [r4, #0x1e]                       @ 0810441E
	strh	r5, [r4, #0x38]                       @ 08104420
	strh	r5, [r4, #0x34]                       @ 08104422
.L08104424:
	pop	{r4, r5}                               @ 08104424
	pop	{r0}                                   @ 08104426
	bx	r0                                      @ 08104428
	.hword	0x0000                              @ 0810442A  (padding)
.Llit0810442C:
	.word	gmpStepTab                           @ 0810442C
@ --------------------------------------------------------------------------
@ fxVibrato(ch)  (0x08104430)
@   if (!gmpTick) CH_vibPos = 0;  CH_vibOfs = gmpVibratoSine[CH_vibPos] * depth >> 7;
@   CH_vibPos = (CH_vibPos + speed) & 63
@   gmpTick is 0 on the first tick handled after a row, so the waveform restarts on every row:
@   at speed 6 a slow vibrato never gets past the first part of its cycle.
@ --------------------------------------------------------------------------
	.thumb_func
	.global fxVibrato
fxVibrato:
	adds	r2, r0, #0                            @ 08104430
	ldr	r0, .Llit08104460                      @ 08104432  =gmpTick
	movs	r1, #0                                @ 08104434
	ldrsh	r0, [r0, r1]                         @ 08104436
	cmp	r0, #0                                 @ 08104438
	bne	.L0810443E                             @ 0810443A
	strh	r0, [r2, #0x32]                       @ 0810443C  CH_vibPos
.L0810443E:
	ldr	r1, .Llit08104464                      @ 0810443E  =gmpVibratoSine
	ldrh	r3, [r2, #0x32]                       @ 08104440
	lsls	r0, r3, #1                            @ 08104442
	adds	r0, r0, r1                            @ 08104444
	movs	r1, #0                                @ 08104446
	ldrsh	r0, [r0, r1]                         @ 08104448
	ldrh	r3, [r2, #0x2e]                       @ 0810444A
	muls	r0, r3, r0                            @ 0810444C
	asrs	r0, r0, #7                            @ 0810444E
	strh	r0, [r2, #0x2c]                       @ 08104450
	ldrh	r1, [r2, #0x32]                       @ 08104452
	ldrh	r3, [r2, #0x30]                       @ 08104454
	adds	r0, r1, r3                            @ 08104456
	movs	r1, #0x3f                             @ 08104458
	ands	r0, r1                                @ 0810445A
	strh	r0, [r2, #0x32]                       @ 0810445C
	bx	lr                                      @ 0810445E
.Llit08104460:
	.word	gmpTick                              @ 08104460
.Llit08104464:
	.word	gmpVibratoSine                       @ 08104464
@ --------------------------------------------------------------------------
@ gmpProcessTick()  (0x08104468)
@   Only the first FOUR channels are processed (loop bound "cmp r5, #3" at 0x0810459C), although
@   modules have up to 8 and all of Aero's have 6: channels 5 and 6 never get portamento,
@   vibrato, volume slides or arpeggio.
@   switch (CH_tickFx) {                                 (jump table at 0x0835765C)
@    0 arpeggio: if (gmpArpTick && (x|y)) { if (gmpArpTick == 4) gmpArpTick = 1;
@                ofs = (gmpArpTick & 3) == 1 ? x : y  -- so the sequence is x, y, y, x, y, y...
@                instead of base, x, y; step = 0x6C3E1D / ((period[fine+note+ofs] + vib) * 2) }
@    1/2 portamento: CH_portaOfs += CH_portaStep     3 fxTonePorta   4 fxVibrato
@    5 tone porta + slide  6 vibrato + slide  0xA fxVolumeSlide }
@   then (no arpeggio): step = porta|vib|fine ? (0x6C3E1D / ((period[fine+note]+porta+vib)*2) << 12) / rate
@                                              : gmpStepTab[note]
@   gmpTick++; gmpArpTick++
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpProcessTick
gmpProcessTick:
	push	{r4, r5, lr}                          @ 08104468
	ldr	r4, .Llit08104480                      @ 0810446A  =gmpChan
	movs	r5, #0                                @ 0810446C
.L0810446E:
	ldr	r0, [r4, #0x20]                        @ 0810446E
	cmp	r0, #0xa                               @ 08104470
	bhi	.L0810452E                             @ 08104472
	lsls	r0, r0, #2                            @ 08104474
	ldr	r1, .Llit08104484                      @ 08104476  =0x0835765C
	adds	r0, r0, r1                            @ 08104478
	ldr	r0, [r0]                               @ 0810447A
	mov	pc, r0                                 @ 0810447C  switch (CH_tickFx)
	.hword	0x0000                              @ 0810447E  (padding)
.Llit08104480:
	.word	gmpChan                              @ 08104480
.Llit08104484:
	.word	0x0835765C                           @ 08104484
.L08104488:
	ldr	r1, .Llit081044E8                      @ 08104488  =gmpArpTick
	movs	r2, #0                                @ 0810448A
	ldrsh	r0, [r1, r2]                         @ 0810448C
	cmp	r0, #0                                 @ 0810448E
	beq	.L0810452E                             @ 08104490
	ldrh	r3, [r4, #0x28]                       @ 08104492
	ldrh	r2, [r4, #0x2a]                       @ 08104494
	cmn	r3, r2                                 @ 08104496
	beq	.L0810452E                             @ 08104498
	cmp	r0, #4                                 @ 0810449A
	bne	.L081044A2                             @ 0810449C
	movs	r0, #1                                @ 0810449E
	strh	r0, [r1]                              @ 081044A0  gmpArpTick
.L081044A2:
	movs	r0, #3                                @ 081044A2
	ldrh	r1, [r1]                              @ 081044A4
	ands	r0, r1                                @ 081044A6
	movs	r1, #0                                @ 081044A8
	cmp	r0, #0                                 @ 081044AA
	beq	.L081044B6                             @ 081044AC
	adds	r1, r2, #0                            @ 081044AE
	cmp	r0, #1                                 @ 081044B0
	bne	.L081044B6                             @ 081044B2
	adds	r1, r3, #0                            @ 081044B4
.L081044B6:
	ldrh	r3, [r4, #0x1c]                       @ 081044B6
	ldrh	r2, [r4, #0x1e]                       @ 081044B8
	adds	r0, r3, r2                            @ 081044BA
	adds	r0, r0, r1                            @ 081044BC
	ldr	r1, .Llit081044EC                      @ 081044BE  =gmpPeriodTab
	ldr	r1, [r1]                               @ 081044C0  gmpPeriodTab
	lsls	r0, r0, #1                            @ 081044C2
	adds	r0, r0, r1                            @ 081044C4
	movs	r3, #0x2c                             @ 081044C6
	ldrsh	r1, [r4, r3]                         @ 081044C8
	ldrh	r0, [r0]                              @ 081044CA
	adds	r1, r0, r1                            @ 081044CC
	lsls	r1, r1, #1                            @ 081044CE
	ldr	r0, .Llit081044F0                      @ 081044D0  =0x006C3E1D
	bl	__divsi3                                @ 081044D2
	str	r0, [r4, #8]                           @ 081044D6
	lsls	r0, r0, #0xc                          @ 081044D8
	ldr	r1, .Llit081044F4                      @ 081044DA  =gmpRate
	ldr	r1, [r1]                               @ 081044DC  gmpRate
	bl	__udivsi3                               @ 081044DE
	str	r0, [r4, #8]                           @ 081044E2
	b	.L0810452E                               @ 081044E4
	.hword	0x0000                              @ 081044E6  (padding)
.Llit081044E8:
	.word	gmpArpTick                           @ 081044E8
.Llit081044EC:
	.word	gmpPeriodTab                         @ 081044EC
.Llit081044F0:
	.word	0x006C3E1D                           @ 081044F0
.Llit081044F4:
	.word	gmpRate                              @ 081044F4
.L081044F8:
	ldrh	r1, [r4, #0x34]                       @ 081044F8
	ldrh	r2, [r4, #0x38]                       @ 081044FA
	adds	r0, r1, r2                            @ 081044FC
	strh	r0, [r4, #0x34]                       @ 081044FE
	b	.L0810452E                               @ 08104500
.L08104502:
	adds	r0, r4, #0                            @ 08104502
	bl	fxTonePorta                             @ 08104504
	b	.L0810452E                               @ 08104508
.L0810450A:
	adds	r0, r4, #0                            @ 0810450A
	bl	fxVibrato                               @ 0810450C
	b	.L0810452E                               @ 08104510
.L08104512:
	adds	r0, r4, #0                            @ 08104512
	bl	fxTonePorta                             @ 08104514
	b	.L08104520                               @ 08104518
.L0810451A:
	adds	r0, r4, #0                            @ 0810451A
	bl	fxVibrato                               @ 0810451C
.L08104520:
	adds	r0, r4, #0                            @ 08104520
	bl	fxVolumeSlide                           @ 08104522
	b	.L0810452E                               @ 08104526
.L08104528:
	adds	r0, r4, #0                            @ 08104528
	bl	fxVolumeSlide                           @ 0810452A
.L0810452E:
	ldrh	r2, [r4, #0x1e]                       @ 0810452E
	ldrh	r3, [r4, #0x2a]                       @ 08104530
	ldrh	r1, [r4, #0x28]                       @ 08104532
	adds	r0, r3, r1                            @ 08104534
	cmp	r0, #0                                 @ 08104536
	bne	.L08104598                             @ 08104538
	movs	r3, #0x34                             @ 0810453A
	ldrsh	r0, [r4, r3]                         @ 0810453C
	cmp	r0, #0                                 @ 0810453E
	bne	.L08104550                             @ 08104540
	movs	r1, #0x2c                             @ 08104542
	ldrsh	r0, [r4, r1]                         @ 08104544
	cmp	r0, #0                                 @ 08104546
	bne	.L08104550                             @ 08104548
	ldrh	r0, [r4, #0x1c]                       @ 0810454A
	cmp	r0, #0                                 @ 0810454C
	beq	.L0810458C                             @ 0810454E
.L08104550:
	ldrh	r3, [r4, #0x1c]                       @ 08104550
	adds	r2, r3, r2                            @ 08104552
	ldr	r0, .Llit08104580                      @ 08104554  =gmpPeriodTab
	ldr	r0, [r0]                               @ 08104556  gmpPeriodTab
	lsls	r2, r2, #1                            @ 08104558
	adds	r2, r2, r0                            @ 0810455A
	movs	r0, #0x34                             @ 0810455C
	ldrsh	r1, [r4, r0]                         @ 0810455E
	ldrh	r2, [r2]                              @ 08104560
	adds	r1, r2, r1                            @ 08104562
	movs	r2, #0x2c                             @ 08104564
	ldrsh	r0, [r4, r2]                         @ 08104566
	adds	r1, r1, r0                            @ 08104568
	lsls	r1, r1, #1                            @ 0810456A
	ldr	r0, .Llit08104584                      @ 0810456C  =0x006C3E1D
	bl	__divsi3                                @ 0810456E
	str	r0, [r4, #8]                           @ 08104572
	lsls	r0, r0, #0xc                          @ 08104574
	ldr	r1, .Llit08104588                      @ 08104576  =gmpRate
	ldr	r1, [r1]                               @ 08104578  gmpRate
	bl	__udivsi3                               @ 0810457A
	b	.L08104596                               @ 0810457E
.Llit08104580:
	.word	gmpPeriodTab                         @ 08104580
.Llit08104584:
	.word	0x006C3E1D                           @ 08104584
.Llit08104588:
	.word	gmpRate                              @ 08104588
.L0810458C:
	ldr	r0, .Llit081045B8                      @ 0810458C  =gmpStepTab
	ldr	r1, [r0]                               @ 0810458E  gmpStepTab
	lsls	r0, r2, #2                            @ 08104590
	adds	r0, r0, r1                            @ 08104592
	ldr	r0, [r0]                               @ 08104594
.L08104596:
	str	r0, [r4, #8]                           @ 08104596
.L08104598:
	adds	r4, #0x4c                             @ 08104598
	adds	r5, #1                                @ 0810459A
	cmp	r5, #3                                 @ 0810459C  only 4 channels get tick effects
	bgt	.L081045A2                             @ 0810459E
	b	.L0810446E                               @ 081045A0
.L081045A2:
	ldr	r1, .Llit081045BC                      @ 081045A2  =gmpTick
	ldrh	r0, [r1]                              @ 081045A4  gmpTick
	adds	r0, #1                                @ 081045A6
	strh	r0, [r1]                              @ 081045A8  gmpTick
	ldr	r1, .Llit081045C0                      @ 081045AA  =gmpArpTick
	ldrh	r0, [r1]                              @ 081045AC  gmpArpTick
	adds	r0, #1                                @ 081045AE
	strh	r0, [r1]                              @ 081045B0  gmpArpTick
	pop	{r4, r5}                               @ 081045B2
	pop	{r0}                                   @ 081045B4
	bx	r0                                      @ 081045B6
.Llit081045B8:
	.word	gmpStepTab                           @ 081045B8
.Llit081045BC:
	.word	gmpTick                              @ 081045BC
.Llit081045C0:
	.word	gmpArpTick                           @ 081045C0
@ --------------------------------------------------------------------------
@ gmpRowEffects(cell, ch, empty)  (0x081045C4)
@   cell = {u16 ins << 9 | note, u16 cmd << 8 | par}; empty: treat as no note, no effect.
@   3xx: note becomes the target, no retrigger; ins only sets the volume
@   CH_tickFx = -1; CH_vibOfs = 0
@   note != 0x1FF: ins -> CH_ins, CH_vol = header.volume; sample from player->smpPtr and module
@      headers (+0x16FC); CH_fine = header.finetune; CH_note = note; CH_pos = 0; step as in the tick
@      code; CH_portaOfs = 0 unless 3xx
@   no note, ins: new sample pointer and volume only
@   CH_arpX = CH_arpY = 0 ... switch (cmd) {           (jump table at 0x08357688)
@    0 arpeggio x*8, y*8   1 CH_portaStep = -par   2 = +par   3 tone porta (target, speed)
@    4 vibrato (speed x, depth y)  5/6/A volume slide x/y   B order jump (see gmpEndJingle)
@    C volume = par (no clamp)  D gmpCell = par * 4 -- row par only when there are 4 channels;
@      with 6 it lands mid-row and shifts the channels   E only E6x:
@      E60 stores the row in gmpLoopMark; E6x with x != 0 clears a stored mark and *does not*
@      jump, and jumps to row 0 when no mark is stored -- so marked loops never repeat and
@      unmarked ones repeat forever
@    F par < 32: speed, else BPM; recomputes gmpTickHz and gmpRowLen but not gmpTickLen, so tick
@      effects keep running at 50 Hz after a BPM change }   7, 8, 9: nothing
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpRowEffects
gmpRowEffects:
	push	{r4, r5, r6, r7, lr}                  @ 081045C4
	adds	r5, r0, #0                            @ 081045C6
	adds	r4, r1, #0                            @ 081045C8
	ldr	r0, .Llit081045DC                      @ 081045CA  =gmpPlayer
	ldr	r3, [r0]                               @ 081045CC  gmpPlayer
	cmp	r2, #0                                 @ 081045CE
	beq	.L081045E4                             @ 081045D0
	movs	r2, #0                                @ 081045D2
	ldr	r7, .Llit081045E0                      @ 081045D4  =0x000001FF
	movs	r5, #0                                @ 081045D6
	b	.L081045F2                               @ 081045D8
	.hword	0x0000                              @ 081045DA  (padding)
.Llit081045DC:
	.word	gmpPlayer                            @ 081045DC
.Llit081045E0:
	.word	0x000001FF                           @ 081045E0
.L081045E4:
	ldrh	r1, [r5]                              @ 081045E4
	lsrs	r2, r1, #9                            @ 081045E6
	movs	r0, #0x1f                             @ 081045E8
	ands	r2, r0                                @ 081045EA
	ldr	r7, .Llit081046F8                      @ 081045EC  =0x000001FF
	ands	r7, r1                                @ 081045EE
	ldrh	r5, [r5, #2]                          @ 081045F0
.L081045F2:
	movs	r0, #0xf0                             @ 081045F2
	lsls	r0, r0, #4                            @ 081045F4
	ands	r0, r5                                @ 081045F6
	movs	r1, #0xc0                             @ 081045F8
	lsls	r1, r1, #2                            @ 081045FA
	cmp	r0, r1                                 @ 081045FC
	bne	.L08104624                             @ 081045FE
	ldr	r0, .Llit081046F8                      @ 08104600  =0x000001FF
	cmp	r7, r0                                 @ 08104602
	beq	.L08104608                             @ 08104604
	strh	r7, [r4, #0x3a]                       @ 08104606
.L08104608:
	adds	r7, r0, #0                            @ 08104608
	cmp	r2, #0                                 @ 0810460A
	beq	.L08104622                             @ 0810460C
	subs	r0, r2, #1                            @ 0810460E
	lsls	r1, r0, #1                            @ 08104610
	adds	r1, r1, r0                            @ 08104612
	lsls	r1, r1, #2                            @ 08104614
	adds	r1, r3, r1                            @ 08104616
	movs	r0, #0xb8                             @ 08104618
	lsls	r0, r0, #5                            @ 0810461A
	adds	r1, r1, r0                            @ 0810461C
	ldrh	r0, [r1]                              @ 0810461E
	str	r0, [r4, #0x14]                        @ 08104620
.L08104622:
	movs	r2, #0                                @ 08104622
.L08104624:
	lsrs	r6, r5, #8                            @ 08104624
	movs	r0, #1                                @ 08104626
	rsbs	r0, r0, #0                            @ 08104628
	str	r0, [r4, #0x20]                        @ 0810462A
	movs	r1, #0                                @ 0810462C
	mov	ip, r1                                 @ 0810462E
	mov	r0, ip                                 @ 08104630
	strh	r0, [r4, #0x2c]                       @ 08104632
	ldr	r0, .Llit081046F8                      @ 08104634  =0x000001FF
	cmp	r7, r0                                 @ 08104636
	beq	.L0810472C                             @ 08104638
	cmp	r2, #0                                 @ 0810463A
	beq	.L08104656                             @ 0810463C
	subs	r0, r2, #1                            @ 0810463E
	strh	r0, [r4, #0x18]                       @ 08104640
	lsls	r0, r0, #1                            @ 08104642
	ldrh	r1, [r4, #0x18]                       @ 08104644
	adds	r0, r0, r1                            @ 08104646
	lsls	r0, r0, #2                            @ 08104648
	adds	r0, r3, r0                            @ 0810464A
	movs	r2, #0xb8                             @ 0810464C
	lsls	r2, r2, #5                            @ 0810464E
	adds	r0, r0, r2                            @ 08104650
	ldrh	r0, [r0]                              @ 08104652
	str	r0, [r4, #0x14]                        @ 08104654
.L08104656:
	ldr	r0, .Llit081046FC                      @ 08104656  =gmpPlayer
	ldrh	r2, [r4, #0x18]                       @ 08104658
	lsls	r1, r2, #2                            @ 0810465A
	movs	r2, #0x82                             @ 0810465C
	lsls	r2, r2, #1                            @ 0810465E
	adds	r0, r0, r2                            @ 08104660
	adds	r1, r1, r0                            @ 08104662
	ldr	r0, [r1]                               @ 08104664
	str	r0, [r4]                               @ 08104666
	ldrh	r1, [r4, #0x18]                       @ 08104668
	lsls	r0, r1, #1                            @ 0810466A
	adds	r0, r0, r1                            @ 0810466C
	lsls	r0, r0, #2                            @ 0810466E
	adds	r0, r3, r0                            @ 08104670
	ldr	r2, .Llit08104700                      @ 08104672  =0x000016FC
	adds	r0, r0, r2                            @ 08104674
	ldrh	r0, [r0]                              @ 08104676
	strh	r0, [r4, #0xc]                        @ 08104678
	lsls	r0, r1, #1                            @ 0810467A
	adds	r0, r0, r1                            @ 0810467C
	lsls	r0, r0, #2                            @ 0810467E
	adds	r0, r3, r0                            @ 08104680
	adds	r2, #6                                @ 08104682
	adds	r0, r0, r2                            @ 08104684
	ldrh	r0, [r0]                              @ 08104686
	strh	r0, [r4, #0xe]                        @ 08104688
	lsls	r0, r1, #1                            @ 0810468A
	adds	r0, r0, r1                            @ 0810468C
	lsls	r0, r0, #2                            @ 0810468E
	adds	r0, r3, r0                            @ 08104690
	adds	r2, #2                                @ 08104692
	adds	r0, r0, r2                            @ 08104694
	ldrh	r0, [r0]                              @ 08104696
	strh	r0, [r4, #0x10]                       @ 08104698
	lsls	r0, r1, #1                            @ 0810469A
	adds	r0, r0, r1                            @ 0810469C
	lsls	r0, r0, #2                            @ 0810469E
	adds	r0, r3, r0                            @ 081046A0
	subs	r2, #6                                @ 081046A2
	adds	r0, r0, r2                            @ 081046A4
	ldrh	r1, [r0]                              @ 081046A6
	strh	r1, [r4, #0x1c]                       @ 081046A8
	strh	r7, [r4, #0x1e]                       @ 081046AA
	mov	r0, ip                                 @ 081046AC
	str	r0, [r4, #4]                           @ 081046AE
	movs	r2, #0x34                             @ 081046B0
	ldrsh	r0, [r4, r2]                         @ 081046B2
	cmp	r0, #0                                 @ 081046B4
	bne	.L081046C6                             @ 081046B6
	movs	r2, #0x2c                             @ 081046B8
	ldrsh	r0, [r4, r2]                         @ 081046BA
	cmp	r0, #0                                 @ 081046BC
	bne	.L081046C6                             @ 081046BE
	lsls	r0, r1, #0x10                         @ 081046C0
	cmp	r0, #0                                 @ 081046C2
	beq	.L08104710                             @ 081046C4
.L081046C6:
	ldrh	r1, [r4, #0x1c]                       @ 081046C6
	adds	r0, r1, r7                            @ 081046C8
	ldr	r1, .Llit08104704                      @ 081046CA  =gmpPeriodTab
	ldr	r1, [r1]                               @ 081046CC  gmpPeriodTab
	lsls	r0, r0, #1                            @ 081046CE
	adds	r0, r0, r1                            @ 081046D0
	movs	r2, #0x34                             @ 081046D2
	ldrsh	r1, [r4, r2]                         @ 081046D4
	ldrh	r0, [r0]                              @ 081046D6
	adds	r1, r0, r1                            @ 081046D8
	movs	r2, #0x2c                             @ 081046DA
	ldrsh	r0, [r4, r2]                         @ 081046DC
	adds	r1, r1, r0                            @ 081046DE
	lsls	r1, r1, #1                            @ 081046E0
	ldr	r0, .Llit08104708                      @ 081046E2  =0x006C3E1D
	bl	__divsi3                                @ 081046E4
	str	r0, [r4, #8]                           @ 081046E8
	lsls	r0, r0, #0xc                          @ 081046EA
	ldr	r1, .Llit0810470C                      @ 081046EC  =gmpRate
	ldr	r1, [r1]                               @ 081046EE  gmpRate
	bl	__udivsi3                               @ 081046F0
	b	.L0810471A                               @ 081046F4
	.hword	0x0000                              @ 081046F6  (padding)
.Llit081046F8:
	.word	0x000001FF                           @ 081046F8
.Llit081046FC:
	.word	gmpPlayer                            @ 081046FC
.Llit08104700:
	.word	0x000016FC                           @ 08104700
.Llit08104704:
	.word	gmpPeriodTab                         @ 08104704
.Llit08104708:
	.word	0x006C3E1D                           @ 08104708
.Llit0810470C:
	.word	gmpRate                              @ 0810470C
.L08104710:
	ldr	r0, .Llit08104728                      @ 08104710  =gmpStepTab
	ldr	r1, [r0]                               @ 08104712  gmpStepTab
	lsls	r0, r7, #2                            @ 08104714
	adds	r0, r0, r1                            @ 08104716
	ldr	r0, [r0]                               @ 08104718
.L0810471A:
	str	r0, [r4, #8]                           @ 0810471A
	cmp	r6, #3                                 @ 0810471C
	beq	.L0810475A                             @ 0810471E
	movs	r0, #0                                @ 08104720
	strh	r0, [r4, #0x34]                       @ 08104722
	b	.L0810475A                               @ 08104724
	.hword	0x0000                              @ 08104726  (padding)
.Llit08104728:
	.word	gmpStepTab                           @ 08104728
.L0810472C:
	cmp	r2, #0                                 @ 0810472C
	beq	.L0810475A                             @ 0810472E
	subs	r0, r2, #1                            @ 08104730
	strh	r0, [r4, #0x18]                       @ 08104732
	ldr	r0, .Llit08104770                      @ 08104734  =gmpPlayer
	ldrh	r2, [r4, #0x18]                       @ 08104736
	lsls	r1, r2, #2                            @ 08104738
	movs	r2, #0x82                             @ 0810473A
	lsls	r2, r2, #1                            @ 0810473C
	adds	r0, r0, r2                            @ 0810473E
	adds	r1, r1, r0                            @ 08104740
	ldr	r0, [r1]                               @ 08104742
	str	r0, [r4]                               @ 08104744
	ldrh	r1, [r4, #0x18]                       @ 08104746
	lsls	r0, r1, #1                            @ 08104748
	adds	r0, r0, r1                            @ 0810474A
	lsls	r0, r0, #2                            @ 0810474C
	adds	r0, r3, r0                            @ 0810474E
	movs	r2, #0xb8                             @ 08104750
	lsls	r2, r2, #5                            @ 08104752
	adds	r0, r0, r2                            @ 08104754
	ldrh	r0, [r0]                              @ 08104756
	str	r0, [r4, #0x14]                        @ 08104758
.L0810475A:
	movs	r0, #0                                @ 0810475A
	strh	r0, [r4, #0x28]                       @ 0810475C
	strh	r0, [r4, #0x2a]                       @ 0810475E
	cmp	r6, #0xf                               @ 08104760
	bls	.L08104766                             @ 08104762
	b	.L0810495E                               @ 08104764
.L08104766:
	lsls	r0, r6, #2                            @ 08104766
	ldr	r1, .Llit08104774                      @ 08104768  =0x08357688
	adds	r0, r0, r1                            @ 0810476A
	ldr	r0, [r0]                               @ 0810476C
	mov	pc, r0                                 @ 0810476E  switch (cmd)
.Llit08104770:
	.word	gmpPlayer                            @ 08104770
.Llit08104774:
	.word	0x08357688                           @ 08104774
.L08104778:
	movs	r0, #0xf0                             @ 08104778
	ands	r0, r5                                @ 0810477A
	movs	r1, #0xf                              @ 0810477C
	str	r6, [r4, #0x20]                        @ 0810477E
	lsrs	r0, r0, #1                            @ 08104780
	strh	r0, [r4, #0x28]                       @ 08104782
	ands	r5, r1                                @ 08104784
	lsls	r0, r5, #3                            @ 08104786
	strh	r0, [r4, #0x2a]                       @ 08104788
	b	.L0810495E                               @ 0810478A
.L0810478C:
	movs	r0, #0xff                             @ 0810478C
	str	r6, [r4, #0x20]                        @ 0810478E
	ands	r5, r0                                @ 08104790
	rsbs	r0, r5, #0                            @ 08104792
	strh	r0, [r4, #0x38]                       @ 08104794
	b	.L0810495E                               @ 08104796
.L08104798:
	movs	r0, #0xff                             @ 08104798
	ands	r5, r0                                @ 0810479A
	str	r6, [r4, #0x20]                        @ 0810479C
	strh	r5, [r4, #0x38]                       @ 0810479E
	b	.L0810495E                               @ 081047A0
.L081047A2:
	movs	r1, #0xff                             @ 081047A2
	ands	r1, r5                                @ 081047A4
	str	r6, [r4, #0x20]                        @ 081047A6
	cmp	r1, #0                                 @ 081047A8
	beq	.L081047AE                             @ 081047AA
	strh	r1, [r4, #0x36]                       @ 081047AC
.L081047AE:
	movs	r0, #0x3a                             @ 081047AE
	ldrsh	r1, [r4, r0]                         @ 081047B0
	ldrh	r0, [r4, #0x1e]                       @ 081047B2
	cmp	r1, r0                                 @ 081047B4
	beq	.L081047CA                             @ 081047B6
	cmp	r1, r0                                 @ 081047B8
	ble	.L081047C4                             @ 081047BA
	ldrh	r1, [r4, #0x36]                       @ 081047BC
	rsbs	r0, r1, #0                            @ 081047BE
	strh	r0, [r4, #0x38]                       @ 081047C0
	b	.L0810495E                               @ 081047C2
.L081047C4:
	ldrh	r0, [r4, #0x36]                       @ 081047C4
	strh	r0, [r4, #0x38]                       @ 081047C6
	b	.L0810495E                               @ 081047C8
.L081047CA:
	movs	r0, #0                                @ 081047CA
	strh	r0, [r4, #0x38]                       @ 081047CC
	b	.L0810495E                               @ 081047CE
.L081047D0:
	movs	r0, #0xf0                             @ 081047D0
	ands	r0, r5                                @ 081047D2
	lsrs	r1, r0, #4                            @ 081047D4
	movs	r0, #0xf                              @ 081047D6
	ands	r0, r5                                @ 081047D8
	str	r6, [r4, #0x20]                        @ 081047DA
	cmp	r1, #0                                 @ 081047DC
	bne	.L081047E6                             @ 081047DE
	cmp	r0, #0                                 @ 081047E0
	bne	.L081047E6                             @ 081047E2
	b	.L0810495E                               @ 081047E4
.L081047E6:
	strh	r1, [r4, #0x30]                       @ 081047E6
	strh	r0, [r4, #0x2e]                       @ 081047E8
	b	.L0810495E                               @ 081047EA
.L081047EC:
	movs	r0, #0xf0                             @ 081047EC
	ands	r0, r5                                @ 081047EE
	lsrs	r1, r0, #4                            @ 081047F0
	movs	r0, #0xf                              @ 081047F2
	ands	r5, r0                                @ 081047F4
	str	r6, [r4, #0x20]                        @ 081047F6
	strh	r1, [r4, #0x24]                       @ 081047F8
	strh	r5, [r4, #0x26]                       @ 081047FA
	b	.L0810495E                               @ 081047FC
.L081047FE:
	ldr	r2, .Llit08104818                      @ 081047FE  =gmpSkip
	ldr	r0, [r2]                               @ 08104800  gmpSkip
	cmp	r0, #0                                 @ 08104802
	beq	.L08104824                             @ 08104804
	ldr	r1, .Llit0810481C                      @ 08104806  =gmpCell
	ldr	r0, .Llit08104820                      @ 08104808  =gmpChannels
	ldr	r0, [r0]                               @ 0810480A  gmpChannels
	lsls	r0, r0, #6                            @ 0810480C
	strh	r0, [r1]                              @ 0810480E  gmpCell
	movs	r0, #0                                @ 08104810
	str	r0, [r2]                               @ 08104812  gmpSkip
	b	.L0810495E                               @ 08104814
	.hword	0x0000                              @ 08104816  (padding)
.Llit08104818:
	.word	gmpSkip                              @ 08104818
.Llit0810481C:
	.word	gmpCell                              @ 0810481C
.Llit08104820:
	.word	gmpChannels                          @ 08104820
.L08104824:
	ldr	r0, .Llit08104834                      @ 08104824  =gmpJingleOn
	ldrb	r0, [r0]                              @ 08104826  gmpJingleOn
	cmp	r0, #0                                 @ 08104828
	beq	.L08104838                             @ 0810482A
	bl	gmpEndJingle                            @ 0810482C
	b	.L0810495E                               @ 08104830
	.hword	0x0000                              @ 08104832  (padding)
.Llit08104834:
	.word	gmpJingleOn                          @ 08104834
.L08104838:
	ldr	r1, .Llit08104850                      @ 08104838  =gmpOrder
	movs	r0, #0xff                             @ 0810483A
	ands	r5, r0                                @ 0810483C
	subs	r0, r5, #1                            @ 0810483E
	strh	r0, [r1]                              @ 08104840  gmpOrder
	ldr	r1, .Llit08104854                      @ 08104842  =gmpCell
	ldr	r0, .Llit08104858                      @ 08104844  =gmpChannels
	ldr	r0, [r0]                               @ 08104846  gmpChannels
	lsls	r0, r0, #6                            @ 08104848
.L0810484A:
	strh	r0, [r1]                              @ 0810484A
	b	.L0810495E                               @ 0810484C
	.hword	0x0000                              @ 0810484E  (padding)
.Llit08104850:
	.word	gmpOrder                             @ 08104850
.Llit08104854:
	.word	gmpCell                              @ 08104854
.Llit08104858:
	.word	gmpChannels                          @ 08104858
.L0810485C:
	movs	r0, #0xff                             @ 0810485C
	ands	r5, r0                                @ 0810485E
	str	r5, [r4, #0x14]                        @ 08104860
	b	.L0810495E                               @ 08104862
.L08104864:
	ldr	r3, .Llit08104894                      @ 08104864  =gmpJumped
	ldrb	r2, [r3]                              @ 08104866  gmpJumped
	cmp	r2, #0                                 @ 08104868
	beq	.L0810486E                             @ 0810486A
	b	.L0810495E                               @ 0810486C
.L0810486E:
	ldr	r1, .Llit08104898                      @ 0810486E  =gmpCell
	movs	r0, #0xff                             @ 08104870
	ands	r5, r0                                @ 08104872
	lsls	r0, r5, #2                            @ 08104874  Dxx: gmpCell = par * 4
	strh	r0, [r1]                              @ 08104876  gmpCell
	ldr	r1, .Llit0810489C                      @ 08104878  =gmpOrder
	ldrh	r0, [r1]                              @ 0810487A  gmpOrder
	adds	r0, #1                                @ 0810487C
	strh	r0, [r1]                              @ 0810487E  gmpOrder
	ldr	r0, .Llit081048A0                      @ 08104880  =gmpPlayer
	ldr	r0, [r0]                               @ 08104882  gmpPlayer
	ldr	r0, [r0, #0x18]                        @ 08104884
	ldrh	r4, [r1]                              @ 08104886  gmpOrder
	cmp	r4, r0                                 @ 08104888
	blt	.L0810488E                             @ 0810488A
	strh	r2, [r1]                              @ 0810488C  gmpOrder
.L0810488E:
	movs	r0, #1                                @ 0810488E
	strb	r0, [r3]                              @ 08104890
	b	.L0810495E                               @ 08104892
.Llit08104894:
	.word	gmpJumped                            @ 08104894
.Llit08104898:
	.word	gmpCell                              @ 08104898
.Llit0810489C:
	.word	gmpOrder                             @ 0810489C
.Llit081048A0:
	.word	gmpPlayer                            @ 081048A0
.L081048A4:
	movs	r0, #0xf0                             @ 081048A4
	ands	r0, r5                                @ 081048A6
	cmp	r0, #0x70                              @ 081048A8
	beq	.L0810495E                             @ 081048AA
	cmp	r0, #0x70                              @ 081048AC
	bgt	.L0810495E                             @ 081048AE
	cmp	r0, #0x30                              @ 081048B0
	beq	.L0810495E                             @ 081048B2
	cmp	r0, #0x30                              @ 081048B4
	ble	.L0810495E                             @ 081048B6
	cmp	r0, #0x50                              @ 081048B8
	beq	.L0810495E                             @ 081048BA
	cmp	r0, #0x50                              @ 081048BC
	ble	.L0810495E                             @ 081048BE
	cmp	r0, #0x60                              @ 081048C0
	bne	.L0810495E                             @ 081048C2
	movs	r0, #0xf                              @ 081048C4
	ands	r5, r0                                @ 081048C6
	cmp	r5, #0                                 @ 081048C8
	bne	.L08104904                             @ 081048CA
	ldr	r2, .Llit081048E0                      @ 081048CC  =gmpLoopMark
	ldr	r0, .Llit081048E4                      @ 081048CE  =0x0000FFFE
	ldrh	r1, [r2]                              @ 081048D0  gmpLoopMark
	cmp	r1, r0                                 @ 081048D2
	bne	.L081048EC                             @ 081048D4
	ldr	r4, .Llit081048E8                      @ 081048D6  =0x0000FFFD
	adds	r0, r4, #0                            @ 081048D8
	strh	r0, [r2]                              @ 081048DA  gmpLoopMark
	b	.L0810495E                               @ 081048DC
	.hword	0x0000                              @ 081048DE  (padding)
.Llit081048E0:
	.word	gmpLoopMark                          @ 081048E0
.Llit081048E4:
	.word	0x0000FFFE                           @ 081048E4
.Llit081048E8:
	.word	0x0000FFFD                           @ 081048E8
.L081048EC:
	ldr	r0, .Llit081048FC                      @ 081048EC  =gmpCell
	ldr	r1, .Llit08104900                      @ 081048EE  =gmpChannels
	ldrh	r0, [r0]                              @ 081048F0  gmpCell
	ldrh	r1, [r1]                              @ 081048F2  gmpChannels
	subs	r0, r0, r1                            @ 081048F4
	strh	r0, [r2]                              @ 081048F6
	b	.L0810495E                               @ 081048F8
	.hword	0x0000                              @ 081048FA  (padding)
.Llit081048FC:
	.word	gmpCell                              @ 081048FC
.Llit08104900:
	.word	gmpChannels                          @ 08104900
.L08104904:
	ldr	r1, .Llit08104914                      @ 08104904  =gmpLoopMark
	ldr	r0, .Llit08104918                      @ 08104906  =0x0000FFFF
	ldrh	r2, [r1]                              @ 08104908  gmpLoopMark
	cmp	r2, r0                                 @ 0810490A
	bne	.L0810484A                             @ 0810490C
	ldr	r1, .Llit0810491C                      @ 0810490E  =gmpCell
	movs	r0, #0                                @ 08104910
	b	.L0810484A                               @ 08104912
.Llit08104914:
	.word	gmpLoopMark                          @ 08104914
.Llit08104918:
	.word	0x0000FFFF                           @ 08104918
.Llit0810491C:
	.word	gmpCell                              @ 0810491C
.L08104920:
	movs	r1, #0xff                             @ 08104920
	ands	r1, r5                                @ 08104922
	cmp	r1, #0x1f                              @ 08104924
	bgt	.L08104930                             @ 08104926
	ldr	r0, .Llit0810492C                      @ 08104928  =gmpSpeed
	b	.L08104932                               @ 0810492A
.Llit0810492C:
	.word	gmpSpeed                             @ 0810492C
.L08104930:
	ldr	r0, .Llit08104964                      @ 08104930  =gmpBPM
.L08104932:
	str	r1, [r0]                               @ 08104932
	ldr	r4, .Llit08104968                      @ 08104934  =gmpTickHz
	ldr	r0, .Llit08104964                      @ 08104936  =gmpBPM
	ldr	r1, [r0]                               @ 08104938  gmpBPM
	movs	r0, #0x32                             @ 0810493A
	muls	r0, r1, r0                            @ 0810493C
	lsls	r0, r0, #0x10                         @ 0810493E
	movs	r1, #0x7d                             @ 08104940
	bl	__divsi3                                @ 08104942  gmpTickHz = BPM*2/5
	adds	r1, r0, #0                            @ 08104946
	asrs	r1, r1, #0x10                         @ 08104948
	str	r1, [r4]                               @ 0810494A  gmpTickHz
	ldr	r4, .Llit0810496C                      @ 0810494C  =gmpRowLen
	ldr	r0, .Llit08104970                      @ 0810494E  =gmpSpeed
	ldr	r2, .Llit08104974                      @ 08104950  =gmpRate
	ldr	r3, [r0]                               @ 08104952  gmpSpeed
	ldr	r0, [r2]                               @ 08104954  gmpRate
	muls	r0, r3, r0                            @ 08104956
	bl	__udivsi3                               @ 08104958
	str	r0, [r4]                               @ 0810495C  gmpRowLen (gmpTickLen unchanged)
.L0810495E:
	pop	{r4, r5, r6, r7}                       @ 0810495E
	pop	{r0}                                   @ 08104960
	bx	r0                                      @ 08104962
.Llit08104964:
	.word	gmpBPM                               @ 08104964
.Llit08104968:
	.word	gmpTickHz                            @ 08104968
.Llit0810496C:
	.word	gmpRowLen                            @ 0810496C
.Llit08104970:
	.word	gmpSpeed                             @ 08104970
.Llit08104974:
	.word	gmpRate                              @ 08104974
	.word	0x00000000, 0x00000000               @ 08104978
