@ ============================================================================
@ snood2_musicdrv.s -- Mark Cooksey's GBA sound driver, "Build B" (software-mixer version),
@                  as used in Snood 2: Snoods on Vacation (GBA)
@
@ Reconstructed from "Snood 2 - Snoods on Vacation (E) (M5).gba" (B2VP), ROM range
@ 0x0800097C-0x080024AC (6960 bytes).  Assembling this file and linking it with snood2_sound.ld
@ reproduces that range byte for byte (make -f snood2_sound.mk).
@
@ Same compiler as E.T. (early GCC, Thumb), plus one function compiled as ARM, mcMixMusic (APCS
@ frame: mov ip, sp / push {..., fp, ip, lr, pc} / sub fp, ip, #4).  mcSfxMix and mcMixMusic run
@ from IWRAM: mcSoundInit copies them there with DMA3.
@ The sequencer, pattern/instrument formats and PSG code are E.T.'s (see et_musicdrv.s and
@ claude/cooksey-et-technical-reference.md); this build adds 4 software-mixed PCM channels
@ (channels 5-8), a 2-voice SFX mixer, fade-out and a pause that saves SFX state.
@ Differences are documented in claude/cooksey-gba-variants-comparison.md.
@ There are no symbols in the ROM; every name here was assigned during the analysis.
@
@ Channel numbering in comments is 1-8:  1-4 = SOUND1-4 (PSG),  5-8 = mixed PCM -> FIFO A.
@ In the code the loop counter runs 0-7.
@
@ Host integration:
@   VBlank IRQ (0x0800BB80): mcSwapBuffers();  then, unless the game flag 0x03000E14 is set,
@           0x0800C758 -> mcUpdate()   (that wrapper is also called directly from 17 places)
@   main:   mcSoundInit() at 0x0800032E and 0x08000346; mcPlaySong from 0x0800C916/0x0800C926;
@           all SFX go through one wrapper, mcDsSfxStart(id, voice & 1) at 0x0800C8E8
@ ============================================================================

	.syntax unified
	.cpu arm7tdmi
	.thumb

@ ---- hardware registers
	.equ	REG_SOUND1CNT_L, 0x04000060
	.equ	REG_SOUND1CNT_H, 0x04000062
	.equ	REG_SOUND1CNT_X, 0x04000064
	.equ	REG_SOUND2CNT_L, 0x04000068
	.equ	REG_SOUND2CNT_H, 0x0400006C
	.equ	REG_SOUND3CNT_L, 0x04000070
	.equ	REG_SOUND3CNT_H, 0x04000072
	.equ	REG_SOUND3CNT_X, 0x04000074
	.equ	REG_SOUND4CNT_L, 0x04000078
	.equ	REG_SOUND4CNT_H, 0x0400007C
	.equ	REG_SOUNDCNT_L, 0x04000080
	.equ	REG_SOUNDCNT_H, 0x04000082
	.equ	REG_SOUNDCNT_X, 0x04000084
	.equ	REG_WAVE_RAM, 0x04000090
	.equ	REG_FIFO_A, 0x040000A0
	.equ	REG_FIFO_B, 0x040000A4
	.equ	REG_DMA1SAD, 0x040000BC
	.equ	REG_DMA1DAD, 0x040000C0
	.equ	REG_DMA1CNT, 0x040000C4
	.equ	REG_DMA2SAD, 0x040000C8
	.equ	REG_DMA2DAD, 0x040000CC
	.equ	REG_DMA2CNT, 0x040000D0
	.equ	REG_DMA3SAD, 0x040000D4
	.equ	REG_DMA3DAD, 0x040000D8
	.equ	REG_DMA3CNT, 0x040000DC
	.equ	REG_TM0CNT, 0x04000100
	.equ	REG_TM1CNT, 0x04000104
@ ---- driver RAM (IWRAM)
	.equ	mcPsgSfxCur,       0x030046D0   @     4 B  last PSG SFX number passed to mcPlayPsgSfx
	.equ	mcSaveSfxId,       0x030046D8   @     8 B  mcPause copy of mcSfxId[2]
	.equ	mcSfxFrames,       0x030046E0   @     8 B  SFX voice: 176-byte chunks left, [2]
	.equ	mcSaveSfxLoop,     0x030046E8   @     8 B  mcPause copy of mcSfxLoop[2]
	.equ	IWRAM_mcSfxMix,    0x030046F0   @   480 B  mcSfxMix is copied here by mcSoundInit (0x78 words)
	.equ	mcSfxPtr,          0x030048D8   @     8 B  SFX voice: current PCM pointer (0 = idle), [2]
	.equ	mcSaveSfxFrames,   0x030048E0   @     8 B  mcPause copy of mcSfxFrames[2]
	.equ	mcBufIndex,        0x030048E8   @     4 B  double-buffer index (0/1) of the buffer the FIFOs are playing
	.equ	IWRAM_mcMixMusic,  0x030048F0   @  2400 B  mcMixMusic (ARM) is copied here by mcSoundInit (0x258 words)
	.equ	mcFadeCounter,     0x03005250   @     4 B  fade: frame counter (step every 16 frames)
	.equ	mcTempo,           0x03005254   @     4 B  tempo: ticks per frame in 8.8 fixed point
	.equ	mcSaveSfxPending,  0x03005258   @     8 B  mcPause copy of mcSfxPending[2]
	.equ	mcMusicBuf,        0x03005260   @   352 B  music mix buffers [2][176] -> FIFO A
	.equ	mcPaused,          0x030053C0   @     4 B  non-zero = sequencer frozen
	.equ	mcTempoAcc,        0x030053C4   @     4 B  tempo accumulator
	.equ	mcMasterPan,       0x030053C8   @     4 B  SOUNDCNT_L shadow
	.equ	mcDurTable,        0x030053D0   @     4 B  pointer to the current song's note-length table
	.equ	mcPsgSfx,          0x030053E0   @    72 B  PSG SFX slots [6] x {ptr, index, timer} (4 used)
	.equ	mcSfxPending,      0x03005428   @     8 B  set by mcDsSfxStart, only read by mcPause, [2]
	.equ	mcSaveSfxPtr,      0x03005430   @     8 B  mcPause copy of mcSfxPtr[2]
	.equ	mcSfxLoop,         0x03005438   @     8 B  SFX voice: loop flag from the table (0 = one-shot), [2]
	.equ	mcCurSong,         0x03005440   @     4 B  song number (written, never read)
	.equ	mcSfxBuf,          0x03005450   @   352 B  SFX mix buffers [2][176] -> FIFO B
	.equ	mcSfxActive,       0x030055B0   @     8 B  set to 1 by mcDsSfxStart; saved by mcPause; otherwise unread, [2]
	.equ	mcChan,            0x030055C0   @   576 B  music channel state [8] x 0x48 bytes
	.equ	mcFadeLevel,       0x03005800   @     4 B  fade level 7..0 (7 = full)
	.equ	mcFading,          0x03005804   @     4 B  non-zero = fade-out running
	.equ	mcSaveSfxActive,   0x03005808   @     8 B  mcPause copy of mcSfxActive[2]
	.equ	mcCondFlag,        0x03005810   @     4 B  SEQ_CONDFLAG value; never read
	.equ	mcSaveFading,      0x03005814   @     4 B  mcPause copy of mcFading
	.equ	mcSaveFadeLevel,   0x03005818   @     4 B  mcPause copy of mcFadeLevel
	.equ	mcSfxId,           0x03005820   @     8 B  SFX voice: table index playing, [2]
@ ---- music channel struct (0x48 bytes each, 8 channels)
	.equ	CHAN_SIZE, 0x48
	.equ	CH_active, 0x00
	.equ	CH_owned, 0x04
	.equ	CH_seqIdx, 0x08
	.equ	CH_patPos, 0x0C
	.equ	CH_ticks, 0x10
	.equ	CH_note, 0x14
	.equ	CH_freq, 0x18
	.equ	CH_inst, 0x1C
	.equ	CH_seqPtr, 0x20
	.equ	CH_patPtr, 0x24
	.equ	CH_transpose, 0x28
	.equ	CH_patRepeat, 0x2C
	.equ	CH_envIdx, 0x30		@ PCM channels: step (18.14)
	.equ	CH_envTimer, 0x34		@ PCM channels: 1 at note-on
	.equ	CH_pitchIdx, 0x38		@ PCM channels: position (18.14), -1 = stopped
	.equ	CH_pitchTimer, 0x3C		@ PCM channels: end = (length-4)<<14
	.equ	CH_arpIdx, 0x40
	.equ	CH_arpTimer, 0x44
@ ---- ROM data (see snood2_sound_data.s)
	.equ	mcStepTable, 0x0800FFE0
	.equ	mcFadeTable, 0x08010160
	.equ	mcMixerFuncs, 0x080128B4
	.equ	pcm_080128BC, 0x080128BC
	.equ	mcSfxTable, 0x0808223C
	.equ	mcSmpInstTable, 0x0808233C
	.equ	mcPsgSfxMap, 0x0808253C
	.equ	mcPsgSfxScripts, 0x080826BC
	.equ	mcFreqLo, 0x080914B4
	.equ	mcFreqHi, 0x08091515
	.equ	mcSongTable, 0x08091578
	.equ	mcInstTable, 0x08091F94
@ ---- libgcc
	.equ	_call_via_r1, 0x0800FAE8

	.section .text.snood2_musicdrv, "ax", %progbits
	.balign 4
	@ linked at 0x0800097C by snood2_sound.ld

@ --------------------------------------------------------------------------
@ mcPlaySong  (0x0800097C)
@   Start song n (also used to stop: song 0 is a single silent note)
@     void mcPlaySong(int n)
@       e = &mcSongTable[n]            36-byte entries: 8 sequence pointers + note-length table
@       for ch in 0..7:
@         c = &mcChan[ch]; c->seqPtr = e->seq[ch]; c->active = 1; c->owned = 1
@         c->seqIdx = c->patPos = c->ticks = c->patPtr = 0; c->note = 0x60; c->pitchIdx(pos) = -1
@       mcDurTable = e->durTable; mcTempoAcc = 0; mcCurSong = n
@       mcFadeLevel = 7; mcFading = 0; mcCondFlag = 0
@     Unlike E.T. there is no special case for the PCM channels: they are silenced by note = 0x60.
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcPlaySong
mcPlaySong:
	push	{r4, r5, r6, r7, lr}                  @ 0800097C
	mov	r7, r10                                @ 0800097E
	mov	r6, r9                                 @ 08000980
	mov	r5, r8                                 @ 08000982
	push	{r5, r6, r7}                          @ 08000984
	sub	sp, #4                                 @ 08000986
	str	r0, [sp]                               @ 08000988
	ldr	r0, .Llit08000A44                      @ 0800098A  =mcSongTable
	mov	r10, r0                                @ 0800098C
	ldr	r2, .Llit08000A48                      @ 0800098E  =mcChan
	ldr	r3, [sp]                               @ 08000990
	lsls	r1, r3, #3                            @ 08000992
	adds	r0, r1, r3                            @ 08000994
	lsls	r0, r0, #2                            @ 08000996
	movs	r5, #0                                @ 08000998
	adds	r4, r2, #0                            @ 0800099A
	add	r0, r10                                @ 0800099C
	mov	r8, r0                                 @ 0800099E
	movs	r3, #0                                @ 080009A0
	movs	r7, #1                                @ 080009A2
	mov	r12, r7                                @ 080009A4
	mov	r9, r1                                 @ 080009A6
	movs	r6, #7                                @ 080009A8
.L080009AA:
	adds	r0, r2, #0                            @ 080009AA
	adds	r0, #0x20                             @ 080009AC
	adds	r0, r3, r0                            @ 080009AE
	mov	r7, r8                                 @ 080009B0
	adds	r7, #4                                @ 080009B2
	mov	r8, r7                                 @ 080009B4
	subs	r7, #4                                @ 080009B6
	ldm	r7!, {r1}                              @ 080009B8
	str	r1, [r0]                               @ 080009BA
	adds	r0, r2, #0                            @ 080009BC
	adds	r0, #8                                @ 080009BE
	adds	r0, r3, r0                            @ 080009C0
	str	r5, [r0]                               @ 080009C2
	adds	r0, r2, #0                            @ 080009C4
	adds	r0, #0x24                             @ 080009C6
	adds	r0, r3, r0                            @ 080009C8
	str	r5, [r0]                               @ 080009CA
	adds	r0, r2, #0                            @ 080009CC
	adds	r0, #0xc                              @ 080009CE
	adds	r0, r3, r0                            @ 080009D0
	str	r5, [r0]                               @ 080009D2
	adds	r0, r2, #0                            @ 080009D4
	adds	r0, #0x14                             @ 080009D6
	adds	r0, r3, r0                            @ 080009D8
	movs	r1, #0x60                             @ 080009DA
	str	r1, [r0]                               @ 080009DC
	adds	r0, r2, #0                            @ 080009DE
	adds	r0, #0x10                             @ 080009E0
	adds	r0, r3, r0                            @ 080009E2
	str	r5, [r0]                               @ 080009E4
	mov	r0, r12                                @ 080009E6
	str	r0, [r4]                               @ 080009E8
	adds	r0, r2, #4                            @ 080009EA
	adds	r0, r3, r0                            @ 080009EC
	mov	r1, r12                                @ 080009EE
	str	r1, [r0]                               @ 080009F0
	adds	r0, r2, #0                            @ 080009F2
	adds	r0, #0x38                             @ 080009F4
	adds	r0, r3, r0                            @ 080009F6
	movs	r1, #1                                @ 080009F8
	rsbs	r1, r1, #0                            @ 080009FA
	str	r1, [r0]                               @ 080009FC
	str	r5, [r4, #0x30]                        @ 080009FE
	adds	r4, #0x48                             @ 08000A00
	adds	r3, #0x48                             @ 08000A02
	subs	r6, #1                                @ 08000A04
	cmp	r6, #0                                 @ 08000A06
	bge	.L080009AA                             @ 08000A08
	movs	r2, #0                                @ 08000A0A
	ldr	r0, [sp]                               @ 08000A0C
	add	r0, r9                                 @ 08000A0E
	lsls	r0, r0, #2                            @ 08000A10
	mov	r1, r10                                @ 08000A12
	adds	r1, #0x20                             @ 08000A14
	adds	r0, r0, r1                            @ 08000A16
	ldr	r0, [r0]                               @ 08000A18
	ldr	r3, .Llit08000A4C                      @ 08000A1A  =mcDurTable
	str	r0, [r3]                               @ 08000A1C
	ldr	r7, .Llit08000A50                      @ 08000A1E  =mcCondFlag
	str	r2, [r7]                               @ 08000A20
	ldr	r0, [sp]                               @ 08000A22
	ldr	r1, .Llit08000A54                      @ 08000A24  =mcCurSong
	str	r0, [r1]                               @ 08000A26
	movs	r0, #7                                @ 08000A28
	ldr	r3, .Llit08000A58                      @ 08000A2A  =mcFadeLevel
	str	r0, [r3]                               @ 08000A2C
	ldr	r7, .Llit08000A5C                      @ 08000A2E  =mcFading
	str	r2, [r7]                               @ 08000A30
	add	sp, #4                                 @ 08000A32
	pop	{r3, r4, r5}                           @ 08000A34
	mov	r8, r3                                 @ 08000A36
	mov	r9, r4                                 @ 08000A38
	mov	r10, r5                                @ 08000A3A
	pop	{r4, r5, r6, r7}                       @ 08000A3C
	pop	{r0}                                   @ 08000A3E
	bx	r0                                      @ 08000A40
	.hword	0x0000                          @ 08000A42  (padding)
.Llit08000A44:
	.word	mcSongTable                    @ 08000A44  = 0x08091578
.Llit08000A48:
	.word	mcChan                         @ 08000A48  = 0x030055C0
.Llit08000A4C:
	.word	mcDurTable                     @ 08000A4C  = 0x030053D0
.Llit08000A50:
	.word	mcCondFlag                     @ 08000A50  = 0x03005810
.Llit08000A54:
	.word	mcCurSong                      @ 08000A54  = 0x03005440
.Llit08000A58:
	.word	mcFadeLevel                    @ 08000A58  = 0x03005800
.Llit08000A5C:
	.word	mcFading                       @ 08000A5C  = 0x03005804
@ --------------------------------------------------------------------------
@ mcPause  (0x08000A60)
@   Freeze the sequencer and SFX (NO CALLERS in Snood 2 or TXR)
@       mcPaused = 1
@       silence every PSG channel that no PSG SFX slot owns
@       for v in 0..1: save mcSfxPending/Loop/Ptr/Id/Frames/Active[v]; mcSfxPtr[v] = 0
@       mcSaveFadeLevel = mcFadeLevel; mcSaveFading = mcFading; mcFadeLevel = 7; mcFading = 0
@     While paused, mcUpdate zeroes the music buffer instead of mixing.
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcPause
mcPause:
	push	{r4, r5, r6, r7, lr}                  @ 08000A60
	mov	r7, r10                                @ 08000A62
	mov	r6, r9                                 @ 08000A64
	mov	r5, r8                                 @ 08000A66
	push	{r5, r6, r7}                          @ 08000A68
	ldr	r1, .Llit08000B34                      @ 08000A6A  =mcPaused
	movs	r0, #1                                @ 08000A6C
	str	r0, [r1]                               @ 08000A6E
	ldr	r2, .Llit08000B38                      @ 08000A70  =mcPsgSfx
	ldr	r1, [r2]                               @ 08000A72
	cmp	r1, #0                                 @ 08000A74
	bne	.L08000A80                             @ 08000A76
	ldr	r0, .Llit08000B3C                      @ 08000A78  =REG_SOUND1CNT_H
	strh	r1, [r0]                              @ 08000A7A
	adds	r0, #2                                @ 08000A7C
	strh	r1, [r0]                              @ 08000A7E
.L08000A80:
	ldr	r1, [r2, #0xc]                         @ 08000A80
	cmp	r1, #0                                 @ 08000A82
	bne	.L08000A8E                             @ 08000A84
	ldr	r0, .Llit08000B40                      @ 08000A86  =REG_SOUND2CNT_L
	strh	r1, [r0]                              @ 08000A88
	adds	r0, #4                                @ 08000A8A
	strh	r1, [r0]                              @ 08000A8C
.L08000A8E:
	ldr	r1, [r2, #0x18]                        @ 08000A8E
	cmp	r1, #0                                 @ 08000A90
	bne	.L08000A9C                             @ 08000A92
	ldr	r0, .Llit08000B44                      @ 08000A94  =REG_SOUND3CNT_H
	strh	r1, [r0]                              @ 08000A96
	adds	r0, #2                                @ 08000A98
	strh	r1, [r0]                              @ 08000A9A
.L08000A9C:
	ldr	r1, [r2, #0x24]                        @ 08000A9C
	cmp	r1, #0                                 @ 08000A9E
	bne	.L08000AAA                             @ 08000AA0
	ldr	r0, .Llit08000B48                      @ 08000AA2  =REG_SOUND4CNT_L
	strh	r1, [r0]                              @ 08000AA4
	adds	r0, #4                                @ 08000AA6
	strh	r1, [r0]                              @ 08000AA8
.L08000AAA:
	movs	r4, #0                                @ 08000AAA
	ldr	r0, .Llit08000B4C                      @ 08000AAC  =mcSfxId
	mov	r10, r0                                @ 08000AAE
	ldr	r2, .Llit08000B50                      @ 08000AB0  =mcSaveSfxFrames
	mov	r9, r2                                 @ 08000AB2
	ldr	r3, .Llit08000B54                      @ 08000AB4  =mcSfxFrames
	mov	r12, r3                                @ 08000AB6
	ldr	r6, .Llit08000B58                      @ 08000AB8  =mcSfxActive
	ldr	r7, .Llit08000B5C                      @ 08000ABA  =mcFading
	mov	r8, r7                                 @ 08000ABC
	ldr	r5, .Llit08000B60                      @ 08000ABE  =mcSaveSfxPending
.L08000AC0:
	lsls	r1, r4, #2                            @ 08000AC0
	ldr	r2, .Llit08000B64                      @ 08000AC2  =mcSfxPending
	adds	r0, r1, r2                            @ 08000AC4
	ldr	r0, [r0]                               @ 08000AC6
	stm	r5!, {r0}                              @ 08000AC8
	ldr	r3, .Llit08000B68                      @ 08000ACA  =mcSaveSfxLoop
	adds	r2, r1, r3                            @ 08000ACC
	ldr	r7, .Llit08000B6C                      @ 08000ACE  =mcSfxLoop
	adds	r0, r1, r7                            @ 08000AD0
	ldr	r0, [r0]                               @ 08000AD2
	str	r0, [r2]                               @ 08000AD4
	ldr	r0, .Llit08000B70                      @ 08000AD6  =mcSaveSfxPtr
	adds	r2, r1, r0                            @ 08000AD8
	ldr	r7, .Llit08000B74                      @ 08000ADA  =mcSfxPtr
	adds	r3, r1, r7                            @ 08000ADC
	ldr	r0, [r3]                               @ 08000ADE
	str	r0, [r2]                               @ 08000AE0
	ldr	r0, .Llit08000B78                      @ 08000AE2  =mcSaveSfxId
	adds	r2, r1, r0                            @ 08000AE4
	mov	r7, r10                                @ 08000AE6
	adds	r0, r1, r7                            @ 08000AE8
	ldr	r0, [r0]                               @ 08000AEA
	str	r0, [r2]                               @ 08000AEC
	mov	r0, r9                                 @ 08000AEE
	adds	r2, r1, r0                            @ 08000AF0
	mov	r7, r12                                @ 08000AF2
	adds	r0, r1, r7                            @ 08000AF4
	ldr	r0, [r0]                               @ 08000AF6
	str	r0, [r2]                               @ 08000AF8
	ldr	r0, .Llit08000B7C                      @ 08000AFA  =mcSaveSfxActive
	adds	r2, r1, r0                            @ 08000AFC
	adds	r1, r1, r6                            @ 08000AFE
	ldr	r0, [r1]                               @ 08000B00
	str	r0, [r2]                               @ 08000B02
	movs	r1, #0                                @ 08000B04
	str	r1, [r3]                               @ 08000B06
	adds	r4, #1                                @ 08000B08
	cmp	r4, #1                                 @ 08000B0A
	ble	.L08000AC0                             @ 08000B0C
	ldr	r2, .Llit08000B80                      @ 08000B0E  =mcFadeLevel
	ldr	r0, [r2]                               @ 08000B10
	ldr	r3, .Llit08000B84                      @ 08000B12  =mcSaveFadeLevel
	str	r0, [r3]                               @ 08000B14
	mov	r7, r8                                 @ 08000B16
	ldr	r0, [r7]                               @ 08000B18
	ldr	r2, .Llit08000B88                      @ 08000B1A  =mcSaveFading
	str	r0, [r2]                               @ 08000B1C
	movs	r0, #7                                @ 08000B1E
	ldr	r3, .Llit08000B80                      @ 08000B20  =mcFadeLevel
	str	r0, [r3]                               @ 08000B22
	str	r1, [r7]                               @ 08000B24
	pop	{r3, r4, r5}                           @ 08000B26
	mov	r8, r3                                 @ 08000B28
	mov	r9, r4                                 @ 08000B2A
	mov	r10, r5                                @ 08000B2C
	pop	{r4, r5, r6, r7}                       @ 08000B2E
	pop	{r0}                                   @ 08000B30
	bx	r0                                      @ 08000B32
.Llit08000B34:
	.word	mcPaused                       @ 08000B34  = 0x030053C0
.Llit08000B38:
	.word	mcPsgSfx                       @ 08000B38  = 0x030053E0
.Llit08000B3C:
	.word	REG_SOUND1CNT_H                @ 08000B3C  = 0x04000062
.Llit08000B40:
	.word	REG_SOUND2CNT_L                @ 08000B40  = 0x04000068
.Llit08000B44:
	.word	REG_SOUND3CNT_H                @ 08000B44  = 0x04000072
.Llit08000B48:
	.word	REG_SOUND4CNT_L                @ 08000B48  = 0x04000078
.Llit08000B4C:
	.word	mcSfxId                        @ 08000B4C  = 0x03005820
.Llit08000B50:
	.word	mcSaveSfxFrames                @ 08000B50  = 0x030048E0
.Llit08000B54:
	.word	mcSfxFrames                    @ 08000B54  = 0x030046E0
.Llit08000B58:
	.word	mcSfxActive                    @ 08000B58  = 0x030055B0
.Llit08000B5C:
	.word	mcFading                       @ 08000B5C  = 0x03005804
.Llit08000B60:
	.word	mcSaveSfxPending               @ 08000B60  = 0x03005258
.Llit08000B64:
	.word	mcSfxPending                   @ 08000B64  = 0x03005428
.Llit08000B68:
	.word	mcSaveSfxLoop                  @ 08000B68  = 0x030046E8
.Llit08000B6C:
	.word	mcSfxLoop                      @ 08000B6C  = 0x03005438
.Llit08000B70:
	.word	mcSaveSfxPtr                   @ 08000B70  = 0x03005430
.Llit08000B74:
	.word	mcSfxPtr                       @ 08000B74  = 0x030048D8
.Llit08000B78:
	.word	mcSaveSfxId                    @ 08000B78  = 0x030046D8
.Llit08000B7C:
	.word	mcSaveSfxActive                @ 08000B7C  = 0x03005808
.Llit08000B80:
	.word	mcFadeLevel                    @ 08000B80  = 0x03005800
.Llit08000B84:
	.word	mcSaveFadeLevel                @ 08000B84  = 0x03005818
.Llit08000B88:
	.word	mcSaveFading                   @ 08000B88  = 0x03005814
@ --------------------------------------------------------------------------
@ mcResume  (0x08000B8C)
@   Undo mcPause: restore the saved SFX voices and fade state, mcPaused = 0 (NO CALLERS)
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcResume
mcResume:
	push	{r4, r5, r6, r7, lr}                  @ 08000B8C
	mov	r7, r10                                @ 08000B8E
	mov	r6, r9                                 @ 08000B90
	mov	r5, r8                                 @ 08000B92
	push	{r5, r6, r7}                          @ 08000B94
	ldr	r1, .Llit08000C1C                      @ 08000B96  =mcPaused
	movs	r0, #0                                @ 08000B98
	str	r0, [r1]                               @ 08000B9A
	movs	r3, #0                                @ 08000B9C
	ldr	r0, .Llit08000C20                      @ 08000B9E  =mcSaveSfxPtr
	mov	r10, r0                                @ 08000BA0
	ldr	r1, .Llit08000C24                      @ 08000BA2  =mcSfxId
	mov	r9, r1                                 @ 08000BA4
	ldr	r2, .Llit08000C28                      @ 08000BA6  =mcSaveSfxId
	mov	r8, r2                                 @ 08000BA8
	ldr	r7, .Llit08000C2C                      @ 08000BAA  =mcSfxFrames
	mov	r12, r7                                @ 08000BAC
	ldr	r6, .Llit08000C30                      @ 08000BAE  =mcSfxActive
	ldr	r5, .Llit08000C34                      @ 08000BB0  =mcSaveSfxActive
	ldr	r4, .Llit08000C38                      @ 08000BB2  =mcSfxPending
.L08000BB4:
	lsls	r1, r3, #2                            @ 08000BB4
	ldr	r2, .Llit08000C3C                      @ 08000BB6  =mcSaveSfxPending
	adds	r0, r1, r2                            @ 08000BB8
	ldr	r0, [r0]                               @ 08000BBA
	stm	r4!, {r0}                              @ 08000BBC
	ldr	r7, .Llit08000C40                      @ 08000BBE  =mcSfxLoop
	adds	r2, r1, r7                            @ 08000BC0
	ldr	r7, .Llit08000C44                      @ 08000BC2  =mcSaveSfxLoop
	adds	r0, r1, r7                            @ 08000BC4
	ldr	r0, [r0]                               @ 08000BC6
	str	r0, [r2]                               @ 08000BC8
	ldr	r0, .Llit08000C48                      @ 08000BCA  =mcSfxPtr
	adds	r2, r1, r0                            @ 08000BCC
	mov	r7, r10                                @ 08000BCE
	adds	r0, r1, r7                            @ 08000BD0
	ldr	r0, [r0]                               @ 08000BD2
	str	r0, [r2]                               @ 08000BD4
	mov	r0, r9                                 @ 08000BD6
	adds	r2, r1, r0                            @ 08000BD8
	mov	r7, r8                                 @ 08000BDA
	adds	r0, r1, r7                            @ 08000BDC
	ldr	r0, [r0]                               @ 08000BDE
	str	r0, [r2]                               @ 08000BE0
	mov	r0, r12                                @ 08000BE2
	adds	r2, r1, r0                            @ 08000BE4
	ldr	r7, .Llit08000C4C                      @ 08000BE6  =mcSaveSfxFrames
	adds	r0, r1, r7                            @ 08000BE8
	ldr	r0, [r0]                               @ 08000BEA
	str	r0, [r2]                               @ 08000BEC
	adds	r2, r1, r6                            @ 08000BEE
	adds	r1, r1, r5                            @ 08000BF0
	ldr	r0, [r1]                               @ 08000BF2
	str	r0, [r2]                               @ 08000BF4
	adds	r3, #1                                @ 08000BF6
	cmp	r3, #1                                 @ 08000BF8
	ble	.L08000BB4                             @ 08000BFA
	ldr	r1, .Llit08000C50                      @ 08000BFC  =mcSaveFadeLevel
	ldr	r0, [r1]                               @ 08000BFE
	ldr	r2, .Llit08000C54                      @ 08000C00  =mcFadeLevel
	str	r0, [r2]                               @ 08000C02
	ldr	r7, .Llit08000C58                      @ 08000C04  =mcSaveFading
	ldr	r0, [r7]                               @ 08000C06
	ldr	r1, .Llit08000C5C                      @ 08000C08  =mcFading
	str	r0, [r1]                               @ 08000C0A
	pop	{r3, r4, r5}                           @ 08000C0C
	mov	r8, r3                                 @ 08000C0E
	mov	r9, r4                                 @ 08000C10
	mov	r10, r5                                @ 08000C12
	pop	{r4, r5, r6, r7}                       @ 08000C14
	pop	{r0}                                   @ 08000C16
	bx	r0                                      @ 08000C18
	.hword	0x0000                          @ 08000C1A  (padding)
.Llit08000C1C:
	.word	mcPaused                       @ 08000C1C  = 0x030053C0
.Llit08000C20:
	.word	mcSaveSfxPtr                   @ 08000C20  = 0x03005430
.Llit08000C24:
	.word	mcSfxId                        @ 08000C24  = 0x03005820
.Llit08000C28:
	.word	mcSaveSfxId                    @ 08000C28  = 0x030046D8
.Llit08000C2C:
	.word	mcSfxFrames                    @ 08000C2C  = 0x030046E0
.Llit08000C30:
	.word	mcSfxActive                    @ 08000C30  = 0x030055B0
.Llit08000C34:
	.word	mcSaveSfxActive                @ 08000C34  = 0x03005808
.Llit08000C38:
	.word	mcSfxPending                   @ 08000C38  = 0x03005428
.Llit08000C3C:
	.word	mcSaveSfxPending               @ 08000C3C  = 0x03005258
.Llit08000C40:
	.word	mcSfxLoop                      @ 08000C40  = 0x03005438
.Llit08000C44:
	.word	mcSaveSfxLoop                  @ 08000C44  = 0x030046E8
.Llit08000C48:
	.word	mcSfxPtr                       @ 08000C48  = 0x030048D8
.Llit08000C4C:
	.word	mcSaveSfxFrames                @ 08000C4C  = 0x030048E0
.Llit08000C50:
	.word	mcSaveFadeLevel                @ 08000C50  = 0x03005818
.Llit08000C54:
	.word	mcFadeLevel                    @ 08000C54  = 0x03005800
.Llit08000C58:
	.word	mcSaveFading                   @ 08000C58  = 0x03005814
.Llit08000C5C:
	.word	mcFading                       @ 08000C5C  = 0x03005804
@ --------------------------------------------------------------------------
@ mcSfxMix  (0x08000C60)
@   Mix one SFX voice into the next FIFO B buffer (Thumb; mcSoundInit copies this function to
@   IWRAM_mcSfxMix and mcUpdate calls it there through mcMixerFuncs[1], once per voice per frame)
@     void mcSfxMix(int v)
@       if (mcSfxPtr[v]) {
@         if (--mcSfxFrames[v] == 0)            restart from the table if mcSfxLoop[v], else stop
@             { if (mcSfxLoop[v]) { ptr = mcSfxTable[id].pcm; frames = mcSfxTable[id].frames - 1 } else ptr = 0 }
@       }
@       buf = mcSfxBuf[(mcBufIndex + 1) & 1]
@       voice 0: if active copy 176 bytes (ldm/stm, PCM must be word-aligned)
@       voice 1: if active buf[i] = (buf[i] + pcm[i]) >> 1, else buf[i] >>= 1
@       mcSfxPtr[v] += 176
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcSfxMix
mcSfxMix:
	push	{r4, r5, r6, r7, lr}                  @ 08000C60
	adds	r7, r0, #0                            @ 08000C62
	ldr	r0, .Llit08000C8C                      @ 08000C64  =mcSfxPtr
	lsls	r3, r7, #2                            @ 08000C66
	adds	r6, r3, r0                            @ 08000C68
	ldr	r4, [r6]                               @ 08000C6A
	mov	r12, r0                                @ 08000C6C
	cmp	r4, #0                                 @ 08000C6E
	beq	.L08000CC8                             @ 08000C70
	ldr	r0, .Llit08000C90                      @ 08000C72  =mcSfxFrames
	adds	r5, r3, r0                            @ 08000C74
	ldr	r0, [r5]                               @ 08000C76
	cmp	r0, #0                                 @ 08000C78
	bne	.L08000CC4                             @ 08000C7A
	ldr	r0, .Llit08000C94                      @ 08000C7C  =mcSfxLoop
	adds	r0, r3, r0                            @ 08000C7E
	ldr	r0, [r0]                               @ 08000C80
	cmp	r0, #0                                 @ 08000C82
	bne	.L08000C98                             @ 08000C84
	movs	r4, #0                                @ 08000C86
	str	r4, [r6]                               @ 08000C88
	b	.L08000CC8                               @ 08000C8A
.Llit08000C8C:
	.word	mcSfxPtr                       @ 08000C8C  = 0x030048D8
.Llit08000C90:
	.word	mcSfxFrames                    @ 08000C90  = 0x030046E0
.Llit08000C94:
	.word	mcSfxLoop                      @ 08000C94  = 0x03005438
.L08000C98:
	ldr	r2, .Llit08000CBC                      @ 08000C98  =mcSfxTable
	ldr	r1, .Llit08000CC0                      @ 08000C9A  =mcSfxId
	adds	r1, r3, r1                            @ 08000C9C
	ldr	r0, [r1]                               @ 08000C9E
	lsls	r0, r0, #4                            @ 08000CA0
	adds	r0, r0, r2                            @ 08000CA2
	ldr	r0, [r0]                               @ 08000CA4
	str	r0, [r6]                               @ 08000CA6
	ldr	r0, [r1]                               @ 08000CA8
	lsls	r0, r0, #4                            @ 08000CAA
	adds	r2, #4                                @ 08000CAC
	adds	r0, r0, r2                            @ 08000CAE
	ldr	r0, [r0]                               @ 08000CB0
	subs	r0, #1                                @ 08000CB2
	str	r0, [r5]                               @ 08000CB4
	ldr	r4, [r6]                               @ 08000CB6
	b	.L08000CC8                               @ 08000CB8
	.hword	0x0000                          @ 08000CBA  (padding)
.Llit08000CBC:
	.word	mcSfxTable                     @ 08000CBC  = 0x0808223C
.Llit08000CC0:
	.word	mcSfxId                        @ 08000CC0  = 0x03005820
.L08000CC4:
	subs	r0, #1                                @ 08000CC4
	str	r0, [r5]                               @ 08000CC6
.L08000CC8:
	ldr	r0, .Llit08000CF8                      @ 08000CC8  =mcBufIndex
	ldr	r0, [r0]                               @ 08000CCA
	adds	r2, r0, #1                            @ 08000CCC
	movs	r0, #1                                @ 08000CCE
	ands	r2, r0                                @ 08000CD0
	cmp	r7, #0                                 @ 08000CD2
	bne	.L08000D00                             @ 08000CD4
	cmp	r4, #0                                 @ 08000CD6
	beq	.L08000D52                             @ 08000CD8
	movs	r0, #0xb0                             @ 08000CDA
	adds	r1, r2, #0                            @ 08000CDC
	muls	r1, r0, r1                            @ 08000CDE
	ldr	r0, .Llit08000CFC                      @ 08000CE0  =mcSfxBuf
	adds	r1, r1, r0                            @ 08000CE2
	adds	r2, r4, #0                            @ 08000CE4
	movs	r5, #0                                @ 08000CE6
	movs	r3, #0x2b                             @ 08000CE8
.L08000CEA:
	ldm	r2!, {r0}                              @ 08000CEA
	stm	r1!, {r0}                              @ 08000CEC
	subs	r3, #1                                @ 08000CEE
	cmp	r3, #0                                 @ 08000CF0
	bge	.L08000CEA                             @ 08000CF2
	adds	r4, r2, #0                            @ 08000CF4
	b	.L08000D4C                               @ 08000CF6
.Llit08000CF8:
	.word	mcBufIndex                     @ 08000CF8  = 0x030048E8
.Llit08000CFC:
	.word	mcSfxBuf                       @ 08000CFC  = 0x03005450
.L08000D00:
	cmp	r4, #0                                 @ 08000D00
	beq	.L08000D30                             @ 08000D02
	lsls	r5, r7, #2                            @ 08000D04
	ldr	r0, .Llit08000D2C                      @ 08000D06  =mcSfxBuf
	movs	r1, #0xb0                             @ 08000D08
	muls	r1, r2, r1                            @ 08000D0A
	adds	r2, r1, r0                            @ 08000D0C
	movs	r3, #0xaf                             @ 08000D0E
.L08000D10:
	movs	r1, #0                                @ 08000D10
	ldrsb	r1, [r2, r1]                         @ 08000D12
	movs	r0, #0                                @ 08000D14
	ldrsb	r0, [r4, r0]                         @ 08000D16
	adds	r1, r1, r0                            @ 08000D18
	adds	r4, #1                                @ 08000D1A
	asrs	r1, r1, #1                            @ 08000D1C
	strb	r1, [r2]                              @ 08000D1E
	adds	r2, #1                                @ 08000D20
	subs	r3, #1                                @ 08000D22
	cmp	r3, #0                                 @ 08000D24
	bge	.L08000D10                             @ 08000D26
	b	.L08000D4C                               @ 08000D28
	.hword	0x0000                          @ 08000D2A  (padding)
.Llit08000D2C:
	.word	mcSfxBuf                       @ 08000D2C  = 0x03005450
.L08000D30:
	lsls	r5, r7, #2                            @ 08000D30
	ldr	r0, .Llit08000D58                      @ 08000D32  =mcSfxBuf
	movs	r1, #0xb0                             @ 08000D34
	muls	r1, r2, r1                            @ 08000D36
	adds	r0, r1, r0                            @ 08000D38
	movs	r3, #0xaf                             @ 08000D3A
.L08000D3C:
	movs	r1, #0                                @ 08000D3C
	ldrsb	r1, [r0, r1]                         @ 08000D3E
	asrs	r1, r1, #1                            @ 08000D40
	strb	r1, [r0]                              @ 08000D42
	adds	r0, #1                                @ 08000D44
	subs	r3, #1                                @ 08000D46
	cmp	r3, #0                                 @ 08000D48
	bge	.L08000D3C                             @ 08000D4A
.L08000D4C:
	mov	r1, r12                                @ 08000D4C
	adds	r0, r5, r1                            @ 08000D4E
	str	r4, [r0]                               @ 08000D50
.L08000D52:
	pop	{r4, r5, r6, r7}                       @ 08000D52
	pop	{r0}                                   @ 08000D54
	bx	r0                                      @ 08000D56
.Llit08000D58:
	.word	mcSfxBuf                       @ 08000D58  = 0x03005450
@ --------------------------------------------------------------------------
@ mcSwapBuffers  (0x08000D5C)
@   Called from the VBlank IRQ: flip the double buffers and restart both FIFO streams
@       mcBufIndex ^= 1
@       TM0CNT = 0; DMA1CNT = 0; DMA1SAD = mcMusicBuf[mcBufIndex]; DMA1DAD = REG_FIFO_A
@       TM0CNT = 0x0080F9C4  (10 512 Hz = 176 samples per frame); DMA1CNT = 0xBE400000 (FIFO, repeat, 32-bit)
@       TM1CNT = 0; DMA2CNT = 0; DMA2SAD = mcSfxBuf[mcBufIndex]; DMA2DAD = REG_FIFO_B
@       TM1CNT = 0x0080F99D  (10 261 Hz, ~171.8 samples per frame: see the comparison doc §4.5)
@       clear mcMusicBuf[next] and mcSfxBuf[next] (176 bytes each)
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcSwapBuffers
mcSwapBuffers:
	push	{r4, r5, r6, r7, lr}                  @ 08000D5C
	mov	r7, r10                                @ 08000D5E
	mov	r6, r9                                 @ 08000D60
	mov	r5, r8                                 @ 08000D62
	push	{r5, r6, r7}                          @ 08000D64
	ldr	r0, .Llit08000DFC                      @ 08000D66  =mcBufIndex
	ldr	r3, [r0]                               @ 08000D68
	adds	r3, #1                                @ 08000D6A
	movs	r1, #1                                @ 08000D6C
	mov	r12, r1                                @ 08000D6E
	ands	r3, r1                                @ 08000D70
	str	r3, [r0]                               @ 08000D72
	ldr	r6, .Llit08000E00                      @ 08000D74  =REG_TM0CNT
	movs	r5, #0                                @ 08000D76
	str	r5, [r6]                               @ 08000D78
	ldr	r2, .Llit08000E04                      @ 08000D7A  =REG_DMA1CNT
	str	r5, [r2]                               @ 08000D7C
	ldr	r1, .Llit08000E08                      @ 08000D7E  =REG_DMA1DAD
	ldr	r0, .Llit08000E0C                      @ 08000D80  =REG_FIFO_A
	str	r0, [r1]                               @ 08000D82
	subs	r1, #4                                @ 08000D84
	movs	r7, #0xb0                             @ 08000D86
	mov	r10, r7                                @ 08000D88
	mov	r4, r10                                @ 08000D8A
	muls	r4, r3, r4                            @ 08000D8C
	ldr	r0, .Llit08000E10                      @ 08000D8E  =mcMusicBuf
	mov	r9, r0                                 @ 08000D90
	adds	r0, r4, r0                            @ 08000D92
	str	r0, [r1]                               @ 08000D94
	ldr	r0, .Llit08000E14                      @ 08000D96  =0x80F9C4
	str	r0, [r6]                               @ 08000D98
	ldr	r1, .Llit08000E18                      @ 08000D9A  =0xBE400000
	mov	r8, r1                                 @ 08000D9C
	str	r1, [r2]                               @ 08000D9E
	ldr	r0, [r2]                               @ 08000DA0
	adds	r6, #4                                @ 08000DA2
	str	r5, [r6]                               @ 08000DA4
	adds	r2, #0xc                              @ 08000DA6
	str	r5, [r2]                               @ 08000DA8
	ldr	r1, .Llit08000E1C                      @ 08000DAA  =REG_DMA2DAD
	ldr	r0, .Llit08000E20                      @ 08000DAC  =REG_FIFO_B
	str	r0, [r1]                               @ 08000DAE
	adds	r0, #0x24                             @ 08000DB0
	ldr	r1, .Llit08000E24                      @ 08000DB2  =mcSfxBuf
	adds	r4, r4, r1                            @ 08000DB4
	str	r4, [r0]                               @ 08000DB6
	ldr	r0, .Llit08000E28                      @ 08000DB8  =0x80F99D
	str	r0, [r6]                               @ 08000DBA
	mov	r7, r8                                 @ 08000DBC
	str	r7, [r2]                               @ 08000DBE
	ldr	r0, [r2]                               @ 08000DC0
	adds	r3, #1                                @ 08000DC2
	mov	r0, r12                                @ 08000DC4
	ands	r3, r0                                @ 08000DC6
	mov	r0, r10                                @ 08000DC8
	muls	r0, r3, r0                            @ 08000DCA
	add	r0, r9                                 @ 08000DCC
	movs	r4, #0                                @ 08000DCE
	movs	r2, #0x2b                             @ 08000DD0
.L08000DD2:
	stm	r0!, {r4}                              @ 08000DD2
	subs	r2, #1                                @ 08000DD4
	cmp	r2, #0                                 @ 08000DD6
	bge	.L08000DD2                             @ 08000DD8
	movs	r0, #0xb0                             @ 08000DDA
	muls	r0, r3, r0                            @ 08000DDC
	adds	r0, r0, r1                            @ 08000DDE
	movs	r1, #0                                @ 08000DE0
	movs	r2, #0x2b                             @ 08000DE2
.L08000DE4:
	stm	r0!, {r1}                              @ 08000DE4
	subs	r2, #1                                @ 08000DE6
	cmp	r2, #0                                 @ 08000DE8
	bge	.L08000DE4                             @ 08000DEA
	pop	{r3, r4, r5}                           @ 08000DEC
	mov	r8, r3                                 @ 08000DEE
	mov	r9, r4                                 @ 08000DF0
	mov	r10, r5                                @ 08000DF2
	pop	{r4, r5, r6, r7}                       @ 08000DF4
	pop	{r0}                                   @ 08000DF6
	bx	r0                                      @ 08000DF8
	.hword	0x0000                          @ 08000DFA  (padding)
.Llit08000DFC:
	.word	mcBufIndex                     @ 08000DFC  = 0x030048E8
.Llit08000E00:
	.word	REG_TM0CNT                     @ 08000E00  = 0x04000100
.Llit08000E04:
	.word	REG_DMA1CNT                    @ 08000E04  = 0x040000C4
.Llit08000E08:
	.word	REG_DMA1DAD                    @ 08000E08  = 0x040000C0
.Llit08000E0C:
	.word	REG_FIFO_A                     @ 08000E0C  = 0x040000A0
.Llit08000E10:
	.word	mcMusicBuf                     @ 08000E10  = 0x03005260
.Llit08000E14:
	.word	0x0080F9C4                     @ 08000E14
.Llit08000E18:
	.word	0xBE400000                     @ 08000E18
.Llit08000E1C:
	.word	REG_DMA2DAD                    @ 08000E1C  = 0x040000CC
.Llit08000E20:
	.word	REG_FIFO_B                     @ 08000E20  = 0x040000A4
.Llit08000E24:
	.word	mcSfxBuf                       @ 08000E24  = 0x03005450
.Llit08000E28:
	.word	0x0080F99D                     @ 08000E28
@ --------------------------------------------------------------------------
@ mcUpdate  (0x08000E2C)
@   Once per frame (from the VBlank path):
@     1  fade:  if (mcFading) every 16 frames mcFadeLevel--, SOUNDCNT_L low byte = level * 0x11;
@               at level 0: mcPlaySong(0), mcFading = 0, mcFadeLevel = 7
@     2  music mix: unless (mcFading && mcFadeLevel == 0):
@               if (mcPaused) clear the next music buffer
@               else _call_via_r1(4, mcMixerFuncs[0])  -> mcMixMusic(4), channels 5-8
@               if (mcFading && level 1..6) scale the next music buffer by mcFadeTable[level] >> 8
@     3  SFX mix: mcSfxMix(0); mcSfxMix(1)  via mcMixerFuncs[1]
@     4  PSG SFX scripts on channels 1-4 (unchanged from E.T., never triggered)
@     5  if (mcPaused) return
@        mcTempoAcc += mcTempo; if (mcTempoAcc < 0x100) return; mcTempoAcc -= 0x100
@     6  for ch in 0..7: E.T.'s sequencer (SEQ_PAT/JUMP/END/PAN/TEMPO/CONDFLAG, 3-byte events,
@        note-length table), PSG table effects for ch 0-3 only, and at note-on:
@          ch 0-3: PSG register writes exactly as in E.T. (same bugs: noise ignores 0xFE, pitch[0] ORed)
@          ch 4-7: step = mcStepTable[0x5F - note]; pos = 0; end = (mcSmpInstTable[inst].length - 4) << 14;
@                  rest -> pos = -1.  BUG: the rest test keeps note 0x60 only for (ch - 4) <= 1, so
@                  rests on channels 7/8 key note 0x30 (silent only because they use instrument 0)
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcUpdate
mcUpdate:
	push	{r4, r5, r6, r7, lr}                  @ 08000E2C
	mov	r7, r10                                @ 08000E2E
	mov	r6, r9                                 @ 08000E30
	mov	r5, r8                                 @ 08000E32
	push	{r5, r6, r7}                          @ 08000E34
	sub	sp, #0x6c                              @ 08000E36
	movs	r7, #0                                @ 08000E38
	ldr	r6, .Llit08000EFC                      @ 08000E3A  =mcFading
	ldr	r0, [r6]                               @ 08000E3C
	cmp	r0, #1                                 @ 08000E3E
	bne	.L08000E86                             @ 08000E40
	ldr	r0, .Llit08000F00                      @ 08000E42  =mcFadeCounter
	ldr	r1, [r0]                               @ 08000E44
	adds	r1, #1                                @ 08000E46
	movs	r2, #0xf                              @ 08000E48
	ands	r1, r2                                @ 08000E4A
	str	r1, [r0]                               @ 08000E4C
	cmp	r1, #0                                 @ 08000E4E
	bne	.L08000E86                             @ 08000E50
	ldr	r5, .Llit08000F04                      @ 08000E52  =mcFadeLevel
	ldr	r0, [r5]                               @ 08000E54
	cmp	r0, #0                                 @ 08000E56
	beq	.L08000E5E                             @ 08000E58
	subs	r0, #1                                @ 08000E5A
	str	r0, [r5]                               @ 08000E5C
.L08000E5E:
	ldr	r3, .Llit08000F08                      @ 08000E5E  =REG_SOUNDCNT_L
	ldrh	r0, [r3]                              @ 08000E60
	movs	r1, #0xff                             @ 08000E62
	lsls	r1, r1, #8                            @ 08000E64
	ands	r1, r0                                @ 08000E66
	ldr	r2, [r5]                               @ 08000E68
	lsls	r0, r2, #4                            @ 08000E6A
	adds	r0, r2, r0                            @ 08000E6C
	orrs	r1, r0                                @ 08000E6E
	lsls	r1, r1, #0x10                         @ 08000E70
	lsrs	r4, r1, #0x10                         @ 08000E72
	strh	r4, [r3]                              @ 08000E74  SOUNDCNT_L low byte = mcFadeLevel * 0x11 (PSG master volume)
	cmp	r2, #0                                 @ 08000E76
	bne	.L08000E86                             @ 08000E78
	movs	r0, #0                                @ 08000E7A
	bl	mcPlaySong                              @ 08000E7C  fade reached 0: mcPlaySong(0)
	str	r7, [r6]                               @ 08000E80
	movs	r0, #7                                @ 08000E82
	str	r0, [r5]                               @ 08000E84
.L08000E86:
	ldr	r0, .Llit08000F0C                      @ 08000E86  =mcPaused
	ldr	r0, [r0]                               @ 08000E88
	cmp	r0, #0                                 @ 08000E8A
	bne	.L08000F20                             @ 08000E8C
	ldr	r0, .Llit08000EFC                      @ 08000E8E  =mcFading
	ldr	r0, [r0]                               @ 08000E90
	cmp	r0, #0                                 @ 08000E92
	beq	.L08000E9E                             @ 08000E94
	ldr	r0, .Llit08000F04                      @ 08000E96  =mcFadeLevel
	ldr	r0, [r0]                               @ 08000E98
	cmp	r0, #0                                 @ 08000E9A
	beq	.L08000EA8                             @ 08000E9C
.L08000E9E:
	ldr	r0, .Llit08000F10                      @ 08000E9E  =mcMixerFuncs
	ldr	r1, [r0]                               @ 08000EA0
	movs	r0, #4                                @ 08000EA2
	bl	_call_via_r1                            @ 08000EA4  mcMixMusic(4) through mcMixerFuncs[0] (IWRAM, ARM)
.L08000EA8:
	ldr	r0, .Llit08000EFC                      @ 08000EA8  =mcFading
	ldr	r0, [r0]                               @ 08000EAA
	cmp	r0, #0                                 @ 08000EAC
	beq	.L08000F4A                             @ 08000EAE
	ldr	r0, .Llit08000F04                      @ 08000EB0  =mcFadeLevel
	ldr	r2, [r0]                               @ 08000EB2
	cmp	r2, #0                                 @ 08000EB4
	beq	.L08000F4A                             @ 08000EB6
	cmp	r2, #7                                 @ 08000EB8
	beq	.L08000F4A                             @ 08000EBA
	mov	r1, sp                                 @ 08000EBC
	ldr	r0, .Llit08000F14                      @ 08000EBE  =mcFadeTable
	ldm	r0!, {r3, r4, r5}                      @ 08000EC0
	stm	r1!, {r3, r4, r5}                      @ 08000EC2
	ldm	r0!, {r3, r6, r7}                      @ 08000EC4
	stm	r1!, {r3, r6, r7}                      @ 08000EC6
	ldm	r0!, {r4, r5, r6}                      @ 08000EC8
	stm	r1!, {r4, r5, r6}                      @ 08000ECA
	lsls	r0, r2, #2                            @ 08000ECC
	add	r0, sp                                 @ 08000ECE
	ldr	r3, [r0]                               @ 08000ED0
	ldr	r0, .Llit08000F18                      @ 08000ED2  =mcBufIndex
	ldr	r0, [r0]                               @ 08000ED4
	adds	r0, #1                                @ 08000ED6
	movs	r1, #1                                @ 08000ED8
	ands	r0, r1                                @ 08000EDA
	ldr	r2, .Llit08000F1C                      @ 08000EDC  =mcMusicBuf
	movs	r1, #0xb0                             @ 08000EDE
	muls	r0, r1, r0                            @ 08000EE0
	adds	r1, r0, r2                            @ 08000EE2
	movs	r2, #0xaf                             @ 08000EE4
.L08000EE6:
	movs	r0, #0                                @ 08000EE6
	ldrsb	r0, [r1, r0]                         @ 08000EE8
	muls	r0, r3, r0                            @ 08000EEA
	asrs	r0, r0, #8                            @ 08000EEC  fade: sample = sample * mcFadeTable[level] >> 8
	strb	r0, [r1]                              @ 08000EEE
	adds	r1, #1                                @ 08000EF0
	subs	r2, #1                                @ 08000EF2
	cmp	r2, #0                                 @ 08000EF4
	bge	.L08000EE6                             @ 08000EF6
	b	.L08000F4A                               @ 08000EF8
	.hword	0x0000                          @ 08000EFA  (padding)
.Llit08000EFC:
	.word	mcFading                       @ 08000EFC  = 0x03005804
.Llit08000F00:
	.word	mcFadeCounter                  @ 08000F00  = 0x03005250
.Llit08000F04:
	.word	mcFadeLevel                    @ 08000F04  = 0x03005800
.Llit08000F08:
	.word	REG_SOUNDCNT_L                 @ 08000F08  = 0x04000080
.Llit08000F0C:
	.word	mcPaused                       @ 08000F0C  = 0x030053C0
.Llit08000F10:
	.word	mcMixerFuncs                   @ 08000F10  = 0x080128B4
.Llit08000F14:
	.word	mcFadeTable                    @ 08000F14  = 0x08010160
.Llit08000F18:
	.word	mcBufIndex                     @ 08000F18  = 0x030048E8
.Llit08000F1C:
	.word	mcMusicBuf                     @ 08000F1C  = 0x03005260
.L08000F20:
	ldr	r0, .Llit08000FB0                      @ 08000F20  =mcBufIndex
	ldr	r1, [r0]                               @ 08000F22
	adds	r1, #1                                @ 08000F24
	movs	r0, #1                                @ 08000F26
	ands	r1, r0                                @ 08000F28
	ldr	r2, .Llit08000FB4                      @ 08000F2A  =mcMusicBuf
	movs	r3, #0                                @ 08000F2C
	movs	r7, #0xaf                             @ 08000F2E
	mov	r10, r7                                @ 08000F30
	movs	r0, #0xb0                             @ 08000F32
	muls	r0, r1, r0                            @ 08000F34
	adds	r0, r0, r2                            @ 08000F36
	adds	r0, #0xaf                             @ 08000F38
.L08000F3A:
	strb	r3, [r0]                              @ 08000F3A  paused: clear the next music buffer
	subs	r0, #1                                @ 08000F3C
	movs	r1, #1                                @ 08000F3E
	rsbs	r1, r1, #0                            @ 08000F40
	add	r10, r1                                @ 08000F42
	mov	r2, r10                                @ 08000F44
	cmp	r2, #0                                 @ 08000F46
	bge	.L08000F3A                             @ 08000F48
.L08000F4A:
	movs	r3, #0                                @ 08000F4A
	mov	r10, r3                                @ 08000F4C
	ldr	r4, .Llit08000FB8                      @ 08000F4E  =mcMixerFuncs+4
.L08000F50:
	ldr	r1, [r4]                               @ 08000F50
	mov	r0, r10                                @ 08000F52
	bl	_call_via_r1                            @ 08000F54  mcSfxMix(voice) through mcMixerFuncs[1], voices 0 and 1
	movs	r5, #1                                @ 08000F58
	add	r10, r5                                @ 08000F5A
	mov	r6, r10                                @ 08000F5C
	cmp	r6, #1                                 @ 08000F5E
	ble	.L08000F50                             @ 08000F60
	movs	r7, #0                                @ 08000F62
	mov	r10, r7                                @ 08000F64
	ldr	r0, .Llit08000FBC                      @ 08000F66  =mcPaused
	mov	r12, r0                                @ 08000F68
	ldr	r0, .Llit08000FC0                      @ 08000F6A  =mcPsgSfx
	adds	r6, r0, #0                            @ 08000F6C
	ldr	r0, .Llit08000FC4                      @ 08000F6E  =mcChan
	adds	r0, #4                                @ 08000F70
	mov	r9, r0                                 @ 08000F72
	adds	r1, r6, #4                            @ 08000F74
	mov	r8, r1                                 @ 08000F76
	adds	r5, r6, #0                            @ 08000F78
.L08000F7A:
	ldr	r4, [r5]                               @ 08000F7A
	cmp	r4, #0                                 @ 08000F7C
	beq	.L08001056                             @ 08000F7E
	adds	r0, r6, #0                            @ 08000F80
	adds	r0, #8                                @ 08000F82
	adds	r1, r7, r0                            @ 08000F84
	ldr	r0, [r1]                               @ 08000F86
	cmp	r0, #0                                 @ 08000F88
	beq	.L08000F94                             @ 08000F8A
	subs	r0, #1                                @ 08000F8C
	str	r0, [r1]                               @ 08000F8E
	cmp	r0, #0                                 @ 08000F90
	bne	.L08001056                             @ 08000F92
.L08000F94:
	ldr	r0, [r5, #4]                           @ 08000F94
	adds	r0, #5                                @ 08000F96
	str	r0, [r5, #4]                           @ 08000F98
	movs	r3, #0                                @ 08000F9A
	lsls	r0, r0, #1                            @ 08000F9C
	adds	r0, r0, r4                            @ 08000F9E
	ldrh	r2, [r0]                              @ 08000FA0
	cmp	r2, #0xfe                              @ 08000FA2
	bne	.L08000FD0                             @ 08000FA4
	ldrh	r1, [r0, #2]                          @ 08000FA6
	cmp	r1, #0xfd                              @ 08000FA8
	bne	.L08000FC8                             @ 08000FAA
	movs	r3, #0xff                             @ 08000FAC
	b	.L08000FD0                               @ 08000FAE
.Llit08000FB0:
	.word	mcBufIndex                     @ 08000FB0  = 0x030048E8
.Llit08000FB4:
	.word	mcMusicBuf                     @ 08000FB4  = 0x03005260
.Llit08000FB8:
	.word	mcMixerFuncs+4                 @ 08000FB8  = 0x080128B8
.Llit08000FBC:
	.word	mcPaused                       @ 08000FBC  = 0x030053C0
.Llit08000FC0:
	.word	mcPsgSfx                       @ 08000FC0  = 0x030053E0
.Llit08000FC4:
	.word	mcChan                         @ 08000FC4  = 0x030055C0
.L08000FC8:
	ldrh	r0, [r0, #2]                          @ 08000FC8
	subs	r0, #1                                @ 08000FCA
	mov	r2, r8                                 @ 08000FCC
	str	r0, [r2]                               @ 08000FCE
.L08000FD0:
	adds	r2, r6, #0                            @ 08000FD0
	ldr	r0, [r5, #4]                           @ 08000FD2
	lsls	r0, r0, #1                            @ 08000FD4
	adds	r1, r0, r4                            @ 08000FD6
	ldrh	r0, [r1]                              @ 08000FD8
	cmp	r0, #0xff                              @ 08000FDA
	bne	.L08000FE0                             @ 08000FDC
	movs	r3, #0xff                             @ 08000FDE
.L08000FE0:
	cmp	r3, #0xff                              @ 08000FE0
	bne	.L08000FF4                             @ 08000FE2
	adds	r0, r7, r2                            @ 08000FE4
	movs	r1, #0                                @ 08000FE6
	str	r1, [r0]                               @ 08000FE8
	movs	r4, #0                                @ 08000FEA
	movs	r0, #1                                @ 08000FEC
	mov	r2, r9                                 @ 08000FEE
	str	r0, [r2]                               @ 08000FF0
	b	.L0800101E                               @ 08000FF2
.L08000FF4:
	adds	r0, r6, #0                            @ 08000FF4
	adds	r0, #8                                @ 08000FF6
	adds	r0, r7, r0                            @ 08000FF8
	ldrh	r1, [r1]                              @ 08000FFA
	str	r1, [r0]                               @ 08000FFC
	mov	r3, r8                                 @ 08000FFE
	ldr	r1, [r3]                               @ 08001000
	lsls	r1, r1, #1                            @ 08001002
	adds	r1, r1, r4                            @ 08001004
	ldrh	r4, [r1, #4]                          @ 08001006
	lsls	r0, r4, #8                            @ 08001008
	ldrh	r2, [r1, #2]                          @ 0800100A
	orrs	r0, r2                                @ 0800100C
	lsls	r0, r0, #0x10                         @ 0800100E
	lsrs	r4, r0, #0x10                         @ 08001010
	ldrh	r3, [r1, #6]                          @ 08001012
	lsls	r0, r3, #8                            @ 08001014
	ldrh	r1, [r1, #8]                          @ 08001016
	orrs	r0, r1                                @ 08001018
	lsls	r0, r0, #0x10                         @ 0800101A
	lsrs	r1, r0, #0x10                         @ 0800101C
.L0800101E:
	mov	r0, r10                                @ 0800101E
	cmp	r0, #0                                 @ 08001020
	bne	.L0800102C                             @ 08001022
	ldr	r0, .Llit08001398                      @ 08001024  =REG_SOUND1CNT_H
	strh	r4, [r0]                              @ 08001026
	adds	r0, #2                                @ 08001028
	strh	r1, [r0]                              @ 0800102A
.L0800102C:
	mov	r2, r10                                @ 0800102C
	cmp	r2, #1                                 @ 0800102E
	bne	.L0800103A                             @ 08001030
	ldr	r0, .Llit0800139C                      @ 08001032  =REG_SOUND2CNT_L
	strh	r4, [r0]                              @ 08001034
	adds	r0, #4                                @ 08001036
	strh	r1, [r0]                              @ 08001038
.L0800103A:
	mov	r3, r10                                @ 0800103A
	cmp	r3, #2                                 @ 0800103C
	bne	.L08001048                             @ 0800103E
	ldr	r0, .Llit080013A0                      @ 08001040  =REG_SOUND3CNT_H
	strh	r4, [r0]                              @ 08001042
	adds	r0, #2                                @ 08001044
	strh	r1, [r0]                              @ 08001046
.L08001048:
	mov	r0, r10                                @ 08001048
	cmp	r0, #3                                 @ 0800104A
	bne	.L08001056                             @ 0800104C
	ldr	r0, .Llit080013A4                      @ 0800104E  =REG_SOUND4CNT_L
	strh	r4, [r0]                              @ 08001050
	adds	r0, #4                                @ 08001052
	strh	r1, [r0]                              @ 08001054
.L08001056:
	movs	r1, #0x48                             @ 08001056
	add	r9, r1                                 @ 08001058
	movs	r2, #0xc                              @ 0800105A
	add	r8, r2                                 @ 0800105C
	adds	r7, #0xc                              @ 0800105E
	adds	r5, #0xc                              @ 08001060
	movs	r3, #1                                @ 08001062
	add	r10, r3                                @ 08001064
	mov	r4, r10                                @ 08001066
	cmp	r4, #3                                 @ 08001068
	ble	.L08000F7A                             @ 0800106A
	mov	r5, r12                                @ 0800106C
	ldr	r0, [r5]                               @ 0800106E
	cmp	r0, #0                                 @ 08001070
	beq	.L08001078                             @ 08001072
	bl	.L08001CF0                              @ 08001074  long branch
.L08001078:
	ldr	r3, .Llit080013A8                      @ 08001078  =mcTempoAcc
	ldr	r2, .Llit080013AC                      @ 0800107A  =mcTempo
	ldr	r1, [r3]                               @ 0800107C
	ldr	r0, [r2]                               @ 0800107E
	adds	r0, r1, r0                            @ 08001080
	str	r0, [r3]                               @ 08001082
	cmp	r0, #0xff                              @ 08001084  tempo gate: at most one tick per frame
	bhi	.L0800108C                             @ 08001086
	bl	.L08001CF0                              @ 08001088  long branch
.L0800108C:
	ldr	r6, .Llit080013B0                      @ 0800108C  =0xFFFFFF00
	adds	r0, r0, r6                            @ 0800108E
	str	r0, [r3]                               @ 08001090
	movs	r7, #0                                @ 08001092
	mov	r10, r7                                @ 08001094
	ldr	r0, .Llit080013B4                      @ 08001096  =mcChan
	mov	r12, r0                                @ 08001098
.L0800109A:
	mov	r2, r10                                @ 0800109A
	lsls	r1, r2, #3                            @ 0800109C
	adds	r0, r1, r2                            @ 0800109E
	lsls	r2, r0, #3                            @ 080010A0
	mov	r3, r12                                @ 080010A2
	adds	r0, r2, r3                            @ 080010A4
	ldr	r0, [r0]                               @ 080010A6
	mov	r4, r10                                @ 080010A8
	adds	r4, #1                                @ 080010AA
	str	r4, [sp, #0x58]                        @ 080010AC
	str	r1, [sp, #0x5c]                        @ 080010AE
	cmp	r0, #1                                 @ 080010B0
	beq	.L080010B8                             @ 080010B2
	bl	.L08001CE4                              @ 080010B4  long branch
.L080010B8:
	mov	r0, r12                                @ 080010B8
	adds	r0, #0x20                             @ 080010BA
	adds	r0, r2, r0                            @ 080010BC
	ldr	r0, [r0]                               @ 080010BE
	cmp	r0, #0                                 @ 080010C0
	bne	.L080010C8                             @ 080010C2
	bl	.L08001CE4                              @ 080010C4  long branch
.L080010C8:
	ldr	r5, .Llit080013B4                      @ 080010C8  =mcChan
	mov	r9, r5                                 @ 080010CA
	ldr	r6, [sp, #0x5c]                        @ 080010CC
	add	r6, r10                                @ 080010CE
	str	r6, [sp, #0x28]                        @ 080010D0
	lsls	r7, r6, #3                            @ 080010D2
	str	r7, [sp, #0x2c]                        @ 080010D4
	mov	r0, r9                                 @ 080010D6
	adds	r0, #0x10                             @ 080010D8
	adds	r0, r7, r0                            @ 080010DA
	str	r0, [sp, #0x30]                        @ 080010DC
	ldr	r0, .Llit080013B8                      @ 080010DE  =mcChan+CH_patPtr
	adds	r0, r7, r0                            @ 080010E0
	str	r0, [sp, #0x34]                        @ 080010E2
	mov	r0, r9                                 @ 080010E4
	adds	r0, #0x14                             @ 080010E6
	adds	r0, r7, r0                            @ 080010E8
	str	r0, [sp, #0x44]                        @ 080010EA
	ldr	r1, .Llit080013BC                      @ 080010EC  =mcChan+CH_freq
	adds	r1, r7, r1                            @ 080010EE
	str	r1, [sp, #0x48]                        @ 080010F0
	ldr	r2, .Llit080013C0                      @ 080010F2  =mcChan+CH_envIdx
	adds	r2, r7, r2                            @ 080010F4
	str	r2, [sp, #0x4c]                        @ 080010F6
	ldr	r3, .Llit080013C4                      @ 080010F8  =mcChan+CH_pitchTimer
	adds	r3, r7, r3                            @ 080010FA
	str	r3, [sp, #0x50]                        @ 080010FC
.L080010FE:
	movs	r4, #0x60                             @ 080010FE
	str	r4, [sp, #0x24]                        @ 08001100
	ldr	r5, [sp, #0x30]                        @ 08001102
	ldr	r0, [r5]                               @ 08001104
	cmp	r0, #0                                 @ 08001106
	bne	.L0800110C                             @ 08001108
	b	.L080016EA                               @ 0800110A
.L0800110C:
	subs	r0, #1                                @ 0800110C
	str	r0, [r5]                               @ 0800110E
	mov	r0, r12                                @ 08001110
	adds	r0, #4                                @ 08001112
	ldr	r6, [sp, #0x2c]                        @ 08001114
	adds	r0, r6, r0                            @ 08001116
	ldr	r0, [r0]                               @ 08001118
	cmp	r0, #0                                 @ 0800111A
	bne	.L08001120                             @ 0800111C
	b	.L080016E0                               @ 0800111E
.L08001120:
	mov	r7, r10                                @ 08001120
	cmp	r7, #0                                 @ 08001122
	beq	.L08001128                             @ 08001124
	b	.L080012A0                               @ 08001126
.L08001128:
	mov	r1, r9                                 @ 08001128
	ldr	r0, [r1, #0x1c]                        @ 0800112A
	lsls	r0, r0, #2                            @ 0800112C
	ldr	r2, .Llit080013C8                      @ 0800112E  =mcInstTable
	adds	r0, r0, r2                            @ 08001130
	ldr	r6, [r0]                               @ 08001132
	ldr	r2, [r6, #0x20]                        @ 08001134
	cmp	r2, #0                                 @ 08001136
	beq	.L080011A4                             @ 08001138
	ldr	r0, [r1, #0x44]                        @ 0800113A
	subs	r0, #1                                @ 0800113C
	str	r0, [r1, #0x44]                        @ 0800113E
	cmp	r0, #0                                 @ 08001140
	bne	.L080011A4                             @ 08001142
	ldr	r0, [r1, #0x40]                        @ 08001144
	adds	r0, #2                                @ 08001146
	str	r0, [r1, #0x40]                        @ 08001148
	lsls	r0, r0, #1                            @ 0800114A
	adds	r0, r0, r2                            @ 0800114C
	ldrh	r3, [r0]                              @ 0800114E
	cmp	r3, #0xfe                              @ 08001150
	bne	.L0800115A                             @ 08001152
	movs	r4, #2                                @ 08001154
	ldrsh	r0, [r0, r4]                         @ 08001156
	str	r0, [r1, #0x40]                        @ 08001158
.L0800115A:
	mov	r5, r9                                 @ 0800115A
	ldr	r4, [r5, #0x40]                        @ 0800115C
	lsls	r0, r4, #1                            @ 0800115E
	adds	r3, r0, r2                            @ 08001160
	movs	r7, #0                                @ 08001162
	ldrsh	r0, [r3, r7]                         @ 08001164
	cmp	r0, #0xfd                              @ 08001166
	bgt	.L08001198                             @ 08001168
	movs	r0, #2                                @ 0800116A
	ldrsh	r1, [r3, r0]                         @ 0800116C
	ldr	r0, [r5, #0x14]                        @ 0800116E
	adds	r0, r0, r1                            @ 08001170
	ldr	r2, .Llit080013CC                      @ 08001172  =mcFreqHi
	adds	r1, r0, r2                            @ 08001174
	ldrb	r1, [r1]                              @ 08001176
	lsls	r2, r1, #8                            @ 08001178
	ldr	r1, .Llit080013D0                      @ 0800117A  =mcFreqLo
	adds	r0, r0, r1                            @ 0800117C
	ldrb	r0, [r0]                              @ 0800117E
	orrs	r2, r0                                @ 08001180
	str	r2, [r5, #0x18]                        @ 08001182
	movs	r5, #0                                @ 08001184
	ldrsh	r0, [r3, r5]                         @ 08001186
	mov	r7, r9                                 @ 08001188
	str	r0, [r7, #0x44]                        @ 0800118A
	ldr	r0, [r6]                               @ 0800118C
	lsls	r0, r0, #0x18                         @ 0800118E
	lsrs	r0, r0, #0x10                         @ 08001190
	orrs	r0, r2                                @ 08001192
	ldr	r1, .Llit080013D4                      @ 08001194  =REG_SOUND1CNT_X
	strh	r0, [r1]                              @ 08001196
.L08001198:
	ldrh	r3, [r3]                              @ 08001198
	cmp	r3, #0xff                              @ 0800119A
	bne	.L080011A4                             @ 0800119C
	subs	r0, r4, #2                            @ 0800119E
	mov	r2, r9                                 @ 080011A0
	str	r0, [r2, #0x40]                        @ 080011A2
.L080011A4:
	ldr	r2, [r6, #0x18]                        @ 080011A4
	cmp	r2, #0                                 @ 080011A6
	beq	.L0800121E                             @ 080011A8
	ldr	r3, [sp, #0x28]                        @ 080011AA
	lsls	r1, r3, #3                            @ 080011AC
	ldr	r5, .Llit080013C4                      @ 080011AE  =mcChan+CH_pitchTimer
	adds	r4, r1, r5                            @ 080011B0
	ldr	r0, [r4]                               @ 080011B2
	subs	r0, #1                                @ 080011B4
	str	r0, [r4]                               @ 080011B6
	cmp	r0, #0                                 @ 080011B8
	bne	.L0800121E                             @ 080011BA
	mov	r0, r12                                @ 080011BC
	adds	r0, #0x38                             @ 080011BE
	adds	r5, r1, r0                            @ 080011C0
	ldr	r0, [r5]                               @ 080011C2
	adds	r0, #2                                @ 080011C4
	str	r0, [r5]                               @ 080011C6
	lsls	r0, r0, #1                            @ 080011C8
	adds	r0, r0, r2                            @ 080011CA
	ldrh	r7, [r0]                              @ 080011CC
	cmp	r7, #0xfe                              @ 080011CE
	bne	.L080011D8                             @ 080011D0
	movs	r3, #2                                @ 080011D2
	ldrsh	r0, [r0, r3]                         @ 080011D4
	str	r0, [r5]                               @ 080011D6
.L080011D8:
	ldr	r0, [r5]                               @ 080011D8
	lsls	r0, r0, #1                            @ 080011DA
	adds	r3, r0, r2                            @ 080011DC
	movs	r7, #0                                @ 080011DE
	ldrsh	r0, [r3, r7]                         @ 080011E0
	cmp	r0, #0xfd                              @ 080011E2
	bgt	.L0800120E                             @ 080011E4
	movs	r7, #2                                @ 080011E6
	ldrsh	r0, [r3, r7]                         @ 080011E8
	str	r0, [r4]                               @ 080011EA
	ldr	r0, .Llit080013BC                      @ 080011EC  =mcChan+CH_freq
	adds	r1, r1, r0                            @ 080011EE
	ldr	r3, [r1]                               @ 080011F0
	ldr	r0, [r5]                               @ 080011F2
	lsls	r0, r0, #1                            @ 080011F4
	adds	r0, r0, r2                            @ 080011F6
	movs	r4, #0                                @ 080011F8
	ldrsh	r0, [r0, r4]                         @ 080011FA
	adds	r3, r3, r0                            @ 080011FC
	str	r3, [r1]                               @ 080011FE
	lsls	r1, r3, #0x10                         @ 08001200
	ldr	r0, [r6]                               @ 08001202
	lsls	r0, r0, #0x18                         @ 08001204
	orrs	r0, r1                                @ 08001206
	lsrs	r4, r0, #0x10                         @ 08001208
	ldr	r7, .Llit080013D4                      @ 0800120A  =REG_SOUND1CNT_X
	strh	r4, [r7]                              @ 0800120C
.L0800120E:
	ldr	r1, [r5]                               @ 0800120E
	lsls	r0, r1, #1                            @ 08001210
	adds	r0, r0, r2                            @ 08001212
	ldrh	r0, [r0]                              @ 08001214
	cmp	r0, #0xff                              @ 08001216
	bne	.L0800121E                             @ 08001218
	subs	r0, r1, #2                            @ 0800121A
	str	r0, [r5]                               @ 0800121C
.L0800121E:
	ldr	r2, [r6, #0x10]                        @ 0800121E
	cmp	r2, #0                                 @ 08001220
	beq	.L080012A0                             @ 08001222
	ldr	r0, [sp, #0x28]                        @ 08001224
	lsls	r7, r0, #3                            @ 08001226
	mov	r0, r12                                @ 08001228
	adds	r0, #0x34                             @ 0800122A
	adds	r5, r7, r0                            @ 0800122C
	ldr	r0, [r5]                               @ 0800122E
	subs	r0, #1                                @ 08001230
	str	r0, [r5]                               @ 08001232
	cmp	r0, #0                                 @ 08001234
	bne	.L080012A0                             @ 08001236
	ldr	r1, .Llit080013C0                      @ 08001238  =mcChan+CH_envIdx
	adds	r3, r7, r1                            @ 0800123A
	ldr	r0, [r3]                               @ 0800123C
	adds	r0, #2                                @ 0800123E
	str	r0, [r3]                               @ 08001240
	lsls	r0, r0, #1                            @ 08001242
	adds	r0, r0, r2                            @ 08001244
	ldrh	r4, [r0]                              @ 08001246
	cmp	r4, #0xfe                              @ 08001248
	bne	.L08001252                             @ 0800124A
	movs	r1, #2                                @ 0800124C
	ldrsh	r0, [r0, r1]                         @ 0800124E
	str	r0, [r3]                               @ 08001250
.L08001252:
	ldr	r0, [r3]                               @ 08001252
	lsls	r0, r0, #1                            @ 08001254
	adds	r1, r0, r2                            @ 08001256
	ldrh	r4, [r1]                              @ 08001258
	mov	r8, r4                                 @ 0800125A
	movs	r4, #0                                @ 0800125C
	ldrsh	r0, [r1, r4]                         @ 0800125E
	cmp	r0, #0xfd                              @ 08001260
	bgt	.L08001290                             @ 08001262
	mov	r4, r8                                 @ 08001264
	lsls	r0, r4, #8                            @ 08001266
	ldrh	r4, [r6, #4]                          @ 08001268
	orrs	r0, r4                                @ 0800126A
	lsls	r0, r0, #0x10                         @ 0800126C
	lsrs	r4, r0, #0x10                         @ 0800126E
	ldr	r0, .Llit08001398                      @ 08001270  =REG_SOUND1CNT_H
	strh	r4, [r0]                              @ 08001272
	movs	r4, #2                                @ 08001274
	ldrsh	r0, [r1, r4]                         @ 08001276
	str	r0, [r5]                               @ 08001278
	ldr	r1, [r6]                               @ 0800127A
	lsls	r1, r1, #8                            @ 0800127C
	ldr	r5, .Llit080013BC                      @ 0800127E  =mcChan+CH_freq
	adds	r0, r7, r5                            @ 08001280
	ldr	r0, [r0]                               @ 08001282
	orrs	r0, r1                                @ 08001284
	movs	r6, #0x80                             @ 08001286
	lsls	r6, r6, #8                            @ 08001288
	orrs	r0, r6                                @ 0800128A
	ldr	r7, .Llit080013D4                      @ 0800128C  =REG_SOUND1CNT_X
	strh	r0, [r7]                              @ 0800128E
.L08001290:
	ldr	r1, [r3]                               @ 08001290
	lsls	r0, r1, #1                            @ 08001292
	adds	r0, r0, r2                            @ 08001294
	ldrh	r0, [r0]                              @ 08001296
	cmp	r0, #0xff                              @ 08001298
	bne	.L080012A0                             @ 0800129A
	subs	r0, r1, #2                            @ 0800129C
	str	r0, [r3]                               @ 0800129E
.L080012A0:
	mov	r0, r10                                @ 080012A0
	cmp	r0, #1                                 @ 080012A2
	beq	.L080012A8                             @ 080012A4
	b	.L08001474                               @ 080012A6
.L080012A8:
	mov	r1, r12                                @ 080012A8
	ldr	r0, [r1, #0x64]                        @ 080012AA
	lsls	r0, r0, #2                            @ 080012AC
	ldr	r2, .Llit080013C8                      @ 080012AE  =mcInstTable
	adds	r0, r0, r2                            @ 080012B0
	ldr	r6, [r0]                               @ 080012B2
	ldr	r2, [r6, #0x20]                        @ 080012B4
	cmp	r2, #0                                 @ 080012B6
	beq	.L08001330                             @ 080012B8
	mov	r4, r12                                @ 080012BA
	adds	r4, #0x8c                             @ 080012BC
	ldr	r0, [r4]                               @ 080012BE
	subs	r0, #1                                @ 080012C0
	str	r0, [r4]                               @ 080012C2
	cmp	r0, #0                                 @ 080012C4
	bne	.L08001330                             @ 080012C6
	mov	r7, r12                                @ 080012C8
	adds	r7, #0x88                             @ 080012CA
	ldr	r0, [r7]                               @ 080012CC
	adds	r0, #2                                @ 080012CE
	str	r0, [r7]                               @ 080012D0
	lsls	r0, r0, #1                            @ 080012D2
	adds	r0, r0, r2                            @ 080012D4
	ldrh	r3, [r0]                              @ 080012D6
	cmp	r3, #0xfe                              @ 080012D8
	bne	.L080012E2                             @ 080012DA
	movs	r5, #2                                @ 080012DC
	ldrsh	r0, [r0, r5]                         @ 080012DE
	str	r0, [r7]                               @ 080012E0
.L080012E2:
	ldr	r5, [r7]                               @ 080012E2
	lsls	r0, r5, #1                            @ 080012E4
	adds	r3, r0, r2                            @ 080012E6
	movs	r1, #0                                @ 080012E8
	ldrsh	r0, [r3, r1]                         @ 080012EA
	cmp	r0, #0xfd                              @ 080012EC
	bgt	.L08001326                             @ 080012EE
	movs	r2, #2                                @ 080012F0
	ldrsh	r1, [r3, r2]                         @ 080012F2
	mov	r2, r12                                @ 080012F4
	ldr	r0, [r2, #0x5c]                        @ 080012F6
	adds	r0, r0, r1                            @ 080012F8
	ldr	r2, .Llit080013CC                      @ 080012FA  =mcFreqHi
	adds	r1, r0, r2                            @ 080012FC
	ldrb	r1, [r1]                              @ 080012FE
	lsls	r2, r1, #8                            @ 08001300
	ldr	r1, .Llit080013D0                      @ 08001302  =mcFreqLo
	adds	r0, r0, r1                            @ 08001304
	ldrb	r0, [r0]                              @ 08001306
	orrs	r2, r0                                @ 08001308
	mov	r0, r12                                @ 0800130A
	str	r2, [r0, #0x60]                        @ 0800130C
	movs	r1, #0                                @ 0800130E
	ldrsh	r0, [r3, r1]                         @ 08001310
	str	r0, [r4]                               @ 08001312
	mov	r2, r12                                @ 08001314
	ldr	r1, [r2, #0x60]                        @ 08001316
	lsls	r1, r1, #0x10                         @ 08001318
	ldr	r0, [r6]                               @ 0800131A
	lsls	r0, r0, #0x18                         @ 0800131C
	orrs	r0, r1                                @ 0800131E
	lsrs	r4, r0, #0x10                         @ 08001320
	ldr	r0, .Llit080013D8                      @ 08001322  =REG_SOUND2CNT_H
	strh	r4, [r0]                              @ 08001324
.L08001326:
	ldrh	r3, [r3]                              @ 08001326
	cmp	r3, #0xff                              @ 08001328
	bne	.L08001330                             @ 0800132A
	subs	r0, r5, #2                            @ 0800132C
	str	r0, [r7]                               @ 0800132E
.L08001330:
	ldr	r2, [r6, #0x18]                        @ 08001330
	cmp	r2, #0                                 @ 08001332
	beq	.L080013F2                             @ 08001334
	ldr	r3, [sp, #0x28]                        @ 08001336
	lsls	r1, r3, #3                            @ 08001338
	ldr	r5, .Llit080013C4                      @ 0800133A  =mcChan+CH_pitchTimer
	adds	r4, r1, r5                            @ 0800133C
	ldr	r0, [r4]                               @ 0800133E
	subs	r0, #1                                @ 08001340
	str	r0, [r4]                               @ 08001342
	cmp	r0, #0                                 @ 08001344
	bne	.L080013F2                             @ 08001346
	mov	r0, r12                                @ 08001348
	adds	r0, #0x38                             @ 0800134A
	adds	r5, r1, r0                            @ 0800134C
	ldr	r0, [r5]                               @ 0800134E
	adds	r0, #2                                @ 08001350
	str	r0, [r5]                               @ 08001352
	lsls	r0, r0, #1                            @ 08001354
	adds	r0, r0, r2                            @ 08001356
	ldrh	r7, [r0]                              @ 08001358
	cmp	r7, #0xfe                              @ 0800135A
	bne	.L08001364                             @ 0800135C
	movs	r3, #2                                @ 0800135E
	ldrsh	r0, [r0, r3]                         @ 08001360
	str	r0, [r5]                               @ 08001362
.L08001364:
	ldr	r0, [r5]                               @ 08001364
	lsls	r0, r0, #1                            @ 08001366
	adds	r3, r0, r2                            @ 08001368
	movs	r7, #0                                @ 0800136A
	ldrsh	r0, [r3, r7]                         @ 0800136C
	cmp	r0, #0xfd                              @ 0800136E
	bgt	.L080013E2                             @ 08001370
	movs	r7, #2                                @ 08001372
	ldrsh	r0, [r3, r7]                         @ 08001374
	str	r0, [r4]                               @ 08001376
	ldr	r0, .Llit080013BC                      @ 08001378  =mcChan+CH_freq
	adds	r1, r1, r0                            @ 0800137A
	ldr	r3, [r1]                               @ 0800137C
	ldr	r0, [r5]                               @ 0800137E
	lsls	r0, r0, #1                            @ 08001380
	adds	r0, r0, r2                            @ 08001382
	movs	r4, #0                                @ 08001384
	ldrsh	r0, [r0, r4]                         @ 08001386
	adds	r3, r3, r0                            @ 08001388
	str	r3, [r1]                               @ 0800138A
	lsls	r1, r3, #0x10                         @ 0800138C
	ldr	r0, [r6]                               @ 0800138E
	lsls	r0, r0, #0x18                         @ 08001390
	orrs	r0, r1                                @ 08001392
	b	.L080013DC                               @ 08001394
	.hword	0x0000                          @ 08001396  (padding)
.Llit08001398:
	.word	REG_SOUND1CNT_H                @ 08001398  = 0x04000062
.Llit0800139C:
	.word	REG_SOUND2CNT_L                @ 0800139C  = 0x04000068
.Llit080013A0:
	.word	REG_SOUND3CNT_H                @ 080013A0  = 0x04000072
.Llit080013A4:
	.word	REG_SOUND4CNT_L                @ 080013A4  = 0x04000078
.Llit080013A8:
	.word	mcTempoAcc                     @ 080013A8  = 0x030053C4
.Llit080013AC:
	.word	mcTempo                        @ 080013AC  = 0x03005254
.Llit080013B0:
	.word	0xFFFFFF00                     @ 080013B0
.Llit080013B4:
	.word	mcChan                         @ 080013B4  = 0x030055C0
.Llit080013B8:
	.word	mcChan+CH_patPtr               @ 080013B8  = 0x030055E4
.Llit080013BC:
	.word	mcChan+CH_freq                 @ 080013BC  = 0x030055D8
.Llit080013C0:
	.word	mcChan+CH_envIdx               @ 080013C0  = 0x030055F0
.Llit080013C4:
	.word	mcChan+CH_pitchTimer           @ 080013C4  = 0x030055FC
.Llit080013C8:
	.word	mcInstTable                    @ 080013C8  = 0x08091F94
.Llit080013CC:
	.word	mcFreqHi                       @ 080013CC  = 0x08091515
.Llit080013D0:
	.word	mcFreqLo                       @ 080013D0  = 0x080914B4
.Llit080013D4:
	.word	REG_SOUND1CNT_X                @ 080013D4  = 0x04000064
.Llit080013D8:
	.word	REG_SOUND2CNT_H                @ 080013D8  = 0x0400006C
.L080013DC:
	lsrs	r4, r0, #0x10                         @ 080013DC
	ldr	r7, .Llit08001644                      @ 080013DE  =REG_SOUND2CNT_H
	strh	r4, [r7]                              @ 080013E0
.L080013E2:
	ldr	r1, [r5]                               @ 080013E2
	lsls	r0, r1, #1                            @ 080013E4
	adds	r0, r0, r2                            @ 080013E6
	ldrh	r0, [r0]                              @ 080013E8
	cmp	r0, #0xff                              @ 080013EA
	bne	.L080013F2                             @ 080013EC
	subs	r0, r1, #2                            @ 080013EE
	str	r0, [r5]                               @ 080013F0
.L080013F2:
	ldr	r2, [r6, #0x10]                        @ 080013F2
	cmp	r2, #0                                 @ 080013F4
	beq	.L08001474                             @ 080013F6
	ldr	r0, [sp, #0x28]                        @ 080013F8
	lsls	r7, r0, #3                            @ 080013FA
	mov	r0, r12                                @ 080013FC
	adds	r0, #0x34                             @ 080013FE
	adds	r5, r7, r0                            @ 08001400
	ldr	r0, [r5]                               @ 08001402
	subs	r0, #1                                @ 08001404
	str	r0, [r5]                               @ 08001406
	cmp	r0, #0                                 @ 08001408
	bne	.L08001474                             @ 0800140A
	ldr	r1, .Llit08001648                      @ 0800140C  =mcChan+CH_envIdx
	adds	r3, r7, r1                            @ 0800140E
	ldr	r0, [r3]                               @ 08001410
	adds	r0, #2                                @ 08001412
	str	r0, [r3]                               @ 08001414
	lsls	r0, r0, #1                            @ 08001416
	adds	r0, r0, r2                            @ 08001418
	ldrh	r4, [r0]                              @ 0800141A
	cmp	r4, #0xfe                              @ 0800141C
	bne	.L08001426                             @ 0800141E
	movs	r1, #2                                @ 08001420
	ldrsh	r0, [r0, r1]                         @ 08001422
	str	r0, [r3]                               @ 08001424
.L08001426:
	ldr	r0, [r3]                               @ 08001426
	lsls	r0, r0, #1                            @ 08001428
	adds	r1, r0, r2                            @ 0800142A
	ldrh	r4, [r1]                              @ 0800142C
	mov	r8, r4                                 @ 0800142E
	movs	r4, #0                                @ 08001430
	ldrsh	r0, [r1, r4]                         @ 08001432
	cmp	r0, #0xfd                              @ 08001434
	bgt	.L08001464                             @ 08001436
	mov	r4, r8                                 @ 08001438
	lsls	r0, r4, #8                            @ 0800143A
	ldrh	r4, [r6, #4]                          @ 0800143C
	orrs	r0, r4                                @ 0800143E
	lsls	r0, r0, #0x10                         @ 08001440
	lsrs	r4, r0, #0x10                         @ 08001442
	ldr	r0, .Llit0800164C                      @ 08001444  =REG_SOUND2CNT_L
	strh	r4, [r0]                              @ 08001446
	movs	r4, #2                                @ 08001448
	ldrsh	r0, [r1, r4]                         @ 0800144A
	str	r0, [r5]                               @ 0800144C
	ldr	r1, [r6]                               @ 0800144E
	lsls	r1, r1, #8                            @ 08001450
	ldr	r5, .Llit08001650                      @ 08001452  =mcChan+CH_freq
	adds	r0, r7, r5                            @ 08001454
	ldr	r0, [r0]                               @ 08001456
	orrs	r0, r1                                @ 08001458
	movs	r6, #0x80                             @ 0800145A
	lsls	r6, r6, #8                            @ 0800145C
	orrs	r0, r6                                @ 0800145E
	ldr	r7, .Llit08001644                      @ 08001460  =REG_SOUND2CNT_H
	strh	r0, [r7]                              @ 08001462
.L08001464:
	ldr	r1, [r3]                               @ 08001464
	lsls	r0, r1, #1                            @ 08001466
	adds	r0, r0, r2                            @ 08001468
	ldrh	r0, [r0]                              @ 0800146A
	cmp	r0, #0xff                              @ 0800146C
	bne	.L08001474                             @ 0800146E
	subs	r0, r1, #2                            @ 08001470
	str	r0, [r3]                               @ 08001472
.L08001474:
	mov	r0, r10                                @ 08001474
	cmp	r0, #2                                 @ 08001476
	beq	.L0800147C                             @ 08001478
	b	.L080015FE                               @ 0800147A
.L0800147C:
	mov	r0, r12                                @ 0800147C
	adds	r0, #0xac                             @ 0800147E
	ldr	r0, [r0]                               @ 08001480
	lsls	r0, r0, #2                            @ 08001482
	ldr	r1, .Llit08001654                      @ 08001484  =mcInstTable
	adds	r0, r0, r1                            @ 08001486
	ldr	r6, [r0]                               @ 08001488
	ldr	r2, [r6, #0x20]                        @ 0800148A
	cmp	r2, #0                                 @ 0800148C
	beq	.L08001502                             @ 0800148E
	mov	r7, r12                                @ 08001490
	adds	r7, #0xd4                             @ 08001492
	ldr	r0, [r7]                               @ 08001494
	subs	r0, #1                                @ 08001496
	str	r0, [r7]                               @ 08001498
	cmp	r0, #0                                 @ 0800149A
	bne	.L08001502                             @ 0800149C
	mov	r5, r12                                @ 0800149E
	adds	r5, #0xd0                             @ 080014A0
	ldr	r0, [r5]                               @ 080014A2
	adds	r0, #2                                @ 080014A4
	str	r0, [r5]                               @ 080014A6
	lsls	r0, r0, #1                            @ 080014A8
	adds	r0, r0, r2                            @ 080014AA
	ldrh	r3, [r0]                              @ 080014AC
	cmp	r3, #0xfe                              @ 080014AE
	bne	.L080014B8                             @ 080014B0
	movs	r4, #2                                @ 080014B2
	ldrsh	r0, [r0, r4]                         @ 080014B4
	str	r0, [r5]                               @ 080014B6
.L080014B8:
	ldr	r4, [r5]                               @ 080014B8
	lsls	r0, r4, #1                            @ 080014BA
	adds	r3, r0, r2                            @ 080014BC
	movs	r1, #0                                @ 080014BE
	ldrsh	r0, [r3, r1]                         @ 080014C0
	cmp	r0, #0xfd                              @ 080014C2
	bgt	.L080014F8                             @ 080014C4
	mov	r0, r12                                @ 080014C6
	adds	r0, #0xa4                             @ 080014C8
	movs	r2, #2                                @ 080014CA
	ldrsh	r1, [r3, r2]                         @ 080014CC
	ldr	r0, [r0]                               @ 080014CE
	adds	r0, r0, r1                            @ 080014D0
	ldr	r2, .Llit08001658                      @ 080014D2  =mcFreqHi
	adds	r1, r0, r2                            @ 080014D4
	ldrb	r1, [r1]                              @ 080014D6
	lsls	r2, r1, #8                            @ 080014D8
	ldr	r1, .Llit0800165C                      @ 080014DA  =mcFreqLo
	adds	r0, r0, r1                            @ 080014DC
	ldrb	r0, [r0]                              @ 080014DE
	orrs	r2, r0                                @ 080014E0
	ldr	r0, .Llit08001660                      @ 080014E2  =mcChan+0x90+CH_freq
	str	r2, [r0]                               @ 080014E4
	movs	r1, #0                                @ 080014E6
	ldrsh	r0, [r3, r1]                         @ 080014E8
	str	r0, [r7]                               @ 080014EA
	ldr	r0, [r6]                               @ 080014EC
	lsls	r0, r0, #0x18                         @ 080014EE
	lsrs	r0, r0, #0x10                         @ 080014F0
	orrs	r0, r2                                @ 080014F2
	ldr	r2, .Llit08001664                      @ 080014F4  =REG_SOUND3CNT_X
	strh	r0, [r2]                              @ 080014F6
.L080014F8:
	ldrh	r3, [r3]                              @ 080014F8
	cmp	r3, #0xff                              @ 080014FA
	bne	.L08001502                             @ 080014FC
	subs	r0, r4, #2                            @ 080014FE
	str	r0, [r5]                               @ 08001500
.L08001502:
	ldr	r2, [r6, #0x18]                        @ 08001502
	cmp	r2, #0                                 @ 08001504
	beq	.L0800157C                             @ 08001506
	ldr	r3, [sp, #0x28]                        @ 08001508
	lsls	r1, r3, #3                            @ 0800150A
	ldr	r5, .Llit08001668                      @ 0800150C  =mcChan+CH_pitchTimer
	adds	r4, r1, r5                            @ 0800150E
	ldr	r0, [r4]                               @ 08001510
	subs	r0, #1                                @ 08001512
	str	r0, [r4]                               @ 08001514
	cmp	r0, #0                                 @ 08001516
	bne	.L0800157C                             @ 08001518
	mov	r0, r12                                @ 0800151A
	adds	r0, #0x38                             @ 0800151C
	adds	r5, r1, r0                            @ 0800151E
	ldr	r0, [r5]                               @ 08001520
	adds	r0, #2                                @ 08001522
	str	r0, [r5]                               @ 08001524
	lsls	r0, r0, #1                            @ 08001526
	adds	r0, r0, r2                            @ 08001528
	ldrh	r7, [r0]                              @ 0800152A
	cmp	r7, #0xfe                              @ 0800152C
	bne	.L08001536                             @ 0800152E
	movs	r3, #2                                @ 08001530
	ldrsh	r0, [r0, r3]                         @ 08001532
	str	r0, [r5]                               @ 08001534
.L08001536:
	ldr	r0, [r5]                               @ 08001536
	lsls	r0, r0, #1                            @ 08001538
	adds	r3, r0, r2                            @ 0800153A
	movs	r7, #0                                @ 0800153C
	ldrsh	r0, [r3, r7]                         @ 0800153E
	cmp	r0, #0xfd                              @ 08001540
	bgt	.L0800156C                             @ 08001542
	movs	r7, #2                                @ 08001544
	ldrsh	r0, [r3, r7]                         @ 08001546
	str	r0, [r4]                               @ 08001548
	ldr	r0, .Llit08001650                      @ 0800154A  =mcChan+CH_freq
	adds	r1, r1, r0                            @ 0800154C
	ldr	r3, [r1]                               @ 0800154E
	ldr	r0, [r5]                               @ 08001550
	lsls	r0, r0, #1                            @ 08001552
	adds	r0, r0, r2                            @ 08001554
	movs	r4, #0                                @ 08001556
	ldrsh	r0, [r0, r4]                         @ 08001558
	adds	r3, r3, r0                            @ 0800155A
	str	r3, [r1]                               @ 0800155C
	lsls	r1, r3, #0x10                         @ 0800155E
	ldr	r0, [r6]                               @ 08001560
	lsls	r0, r0, #0x18                         @ 08001562
	orrs	r0, r1                                @ 08001564
	lsrs	r4, r0, #0x10                         @ 08001566
	ldr	r7, .Llit08001664                      @ 08001568  =REG_SOUND3CNT_X
	strh	r4, [r7]                              @ 0800156A
.L0800156C:
	ldr	r1, [r5]                               @ 0800156C
	lsls	r0, r1, #1                            @ 0800156E
	adds	r0, r0, r2                            @ 08001570
	ldrh	r0, [r0]                              @ 08001572
	cmp	r0, #0xff                              @ 08001574
	bne	.L0800157C                             @ 08001576
	subs	r0, r1, #2                            @ 08001578
	str	r0, [r5]                               @ 0800157A
.L0800157C:
	ldr	r2, [r6, #0x10]                        @ 0800157C
	cmp	r2, #0                                 @ 0800157E
	beq	.L080015FE                             @ 08001580
	ldr	r0, [sp, #0x28]                        @ 08001582
	lsls	r7, r0, #3                            @ 08001584
	mov	r0, r12                                @ 08001586
	adds	r0, #0x34                             @ 08001588
	adds	r5, r7, r0                            @ 0800158A
	ldr	r0, [r5]                               @ 0800158C
	subs	r0, #1                                @ 0800158E
	str	r0, [r5]                               @ 08001590
	cmp	r0, #0                                 @ 08001592
	bne	.L080015FE                             @ 08001594
	ldr	r1, .Llit08001648                      @ 08001596  =mcChan+CH_envIdx
	adds	r3, r7, r1                            @ 08001598
	ldr	r0, [r3]                               @ 0800159A
	adds	r0, #2                                @ 0800159C
	str	r0, [r3]                               @ 0800159E
	lsls	r0, r0, #1                            @ 080015A0
	adds	r0, r0, r2                            @ 080015A2
	ldrh	r4, [r0]                              @ 080015A4
	cmp	r4, #0xfe                              @ 080015A6
	bne	.L080015B0                             @ 080015A8
	movs	r1, #2                                @ 080015AA
	ldrsh	r0, [r0, r1]                         @ 080015AC
	str	r0, [r3]                               @ 080015AE
.L080015B0:
	ldr	r0, [r3]                               @ 080015B0
	lsls	r0, r0, #1                            @ 080015B2
	adds	r1, r0, r2                            @ 080015B4
	ldrh	r4, [r1]                              @ 080015B6
	mov	r8, r4                                 @ 080015B8
	movs	r4, #0                                @ 080015BA
	ldrsh	r0, [r1, r4]                         @ 080015BC
	cmp	r0, #0xfd                              @ 080015BE
	bgt	.L080015EE                             @ 080015C0
	mov	r4, r8                                 @ 080015C2
	lsls	r0, r4, #8                            @ 080015C4
	ldrh	r4, [r6, #4]                          @ 080015C6
	orrs	r0, r4                                @ 080015C8
	lsls	r0, r0, #0x10                         @ 080015CA
	lsrs	r4, r0, #0x10                         @ 080015CC
	ldr	r0, .Llit0800166C                      @ 080015CE  =REG_SOUND3CNT_H
	strh	r4, [r0]                              @ 080015D0
	movs	r4, #2                                @ 080015D2
	ldrsh	r0, [r1, r4]                         @ 080015D4
	str	r0, [r5]                               @ 080015D6
	ldr	r1, [r6]                               @ 080015D8
	lsls	r1, r1, #8                            @ 080015DA
	ldr	r5, .Llit08001650                      @ 080015DC  =mcChan+CH_freq
	adds	r0, r7, r5                            @ 080015DE
	ldr	r0, [r0]                               @ 080015E0
	orrs	r0, r1                                @ 080015E2
	movs	r6, #0x80                             @ 080015E4
	lsls	r6, r6, #8                            @ 080015E6
	orrs	r0, r6                                @ 080015E8
	ldr	r7, .Llit08001664                      @ 080015EA  =REG_SOUND3CNT_X
	strh	r0, [r7]                              @ 080015EC
.L080015EE:
	ldr	r1, [r3]                               @ 080015EE
	lsls	r0, r1, #1                            @ 080015F0
	adds	r0, r0, r2                            @ 080015F2
	ldrh	r0, [r0]                              @ 080015F4
	cmp	r0, #0xff                              @ 080015F6
	bne	.L080015FE                             @ 080015F8
	subs	r0, r1, #2                            @ 080015FA
	str	r0, [r3]                               @ 080015FC
.L080015FE:
	mov	r0, r10                                @ 080015FE
	cmp	r0, #3                                 @ 08001600
	bne	.L080016E0                             @ 08001602
	mov	r0, r12                                @ 08001604
	adds	r0, #0xf4                             @ 08001606
	ldr	r0, [r0]                               @ 08001608
	lsls	r0, r0, #2                            @ 0800160A
	ldr	r1, .Llit08001654                      @ 0800160C  =mcInstTable
	adds	r0, r0, r1                            @ 0800160E
	ldr	r6, [r0]                               @ 08001610
	ldr	r2, [r6, #0x18]                        @ 08001612
	cmp	r2, #0                                 @ 08001614
	beq	.L08001686                             @ 08001616
	movs	r5, #0x8a                             @ 08001618
	lsls	r5, r5, #1                            @ 0800161A
	add	r5, r12                                @ 0800161C
	ldr	r0, [r5]                               @ 0800161E
	subs	r0, #1                                @ 08001620
	str	r0, [r5]                               @ 08001622
	cmp	r0, #0                                 @ 08001624
	bne	.L08001686                             @ 08001626
	movs	r4, #0x88                             @ 08001628
	lsls	r4, r4, #1                            @ 0800162A
	add	r4, r12                                @ 0800162C
	ldr	r3, [r4]                               @ 0800162E
	adds	r0, r3, #2                            @ 08001630
	str	r0, [r4]                               @ 08001632
	lsls	r0, r0, #1                            @ 08001634
	adds	r1, r0, r2                            @ 08001636
	ldrh	r2, [r1]                              @ 08001638
	cmp	r2, #0xff                              @ 0800163A
	bne	.L08001670                             @ 0800163C
	str	r3, [r4]                               @ 0800163E
	b	.L08001686                               @ 08001640
	.hword	0x0000                          @ 08001642  (padding)
.Llit08001644:
	.word	REG_SOUND2CNT_H                @ 08001644  = 0x0400006C
.Llit08001648:
	.word	mcChan+CH_envIdx               @ 08001648  = 0x030055F0
.Llit0800164C:
	.word	REG_SOUND2CNT_L                @ 0800164C  = 0x04000068
.Llit08001650:
	.word	mcChan+CH_freq                 @ 08001650  = 0x030055D8
.Llit08001654:
	.word	mcInstTable                    @ 08001654  = 0x08091F94
.Llit08001658:
	.word	mcFreqHi                       @ 08001658  = 0x08091515
.Llit0800165C:
	.word	mcFreqLo                       @ 0800165C  = 0x080914B4
.Llit08001660:
	.word	mcChan+0x90+CH_freq            @ 08001660  = 0x03005668
.Llit08001664:
	.word	REG_SOUND3CNT_X                @ 08001664  = 0x04000074
.Llit08001668:
	.word	mcChan+CH_pitchTimer           @ 08001668  = 0x030055FC
.Llit0800166C:
	.word	REG_SOUND3CNT_H                @ 0800166C  = 0x04000072
.L08001670:
	ldr	r0, [r6]                               @ 08001670
	lsls	r0, r0, #8                            @ 08001672
	ldrh	r3, [r1]                              @ 08001674
	orrs	r0, r3                                @ 08001676
	lsls	r0, r0, #0x10                         @ 08001678
	lsrs	r4, r0, #0x10                         @ 0800167A
	movs	r7, #2                                @ 0800167C
	ldrsh	r0, [r1, r7]                         @ 0800167E
	str	r0, [r5]                               @ 08001680
	ldr	r0, .Llit080016B8                      @ 08001682  =REG_SOUND4CNT_H
	strh	r4, [r0]                              @ 08001684
.L08001686:
	ldr	r2, [r6, #0x10]                        @ 08001686
	cmp	r2, #0                                 @ 08001688
	beq	.L080016E0                             @ 0800168A
	ldr	r0, [sp, #0x28]                        @ 0800168C
	lsls	r1, r0, #3                            @ 0800168E
	mov	r0, r9                                 @ 08001690
	adds	r0, #0x34                             @ 08001692
	adds	r5, r1, r0                            @ 08001694
	ldr	r0, [r5]                               @ 08001696
	subs	r0, #1                                @ 08001698
	str	r0, [r5]                               @ 0800169A
	cmp	r0, #0                                 @ 0800169C
	bne	.L080016E0                             @ 0800169E
	ldr	r4, .Llit080016BC                      @ 080016A0  =mcChan+CH_envIdx
	adds	r3, r1, r4                            @ 080016A2
	ldr	r4, [r3]                               @ 080016A4
	adds	r0, r4, #2                            @ 080016A6
	str	r0, [r3]                               @ 080016A8
	lsls	r0, r0, #1                            @ 080016AA
	adds	r2, r0, r2                            @ 080016AC
	ldrh	r1, [r2]                              @ 080016AE
	cmp	r1, #0xff                              @ 080016B0
	bne	.L080016C0                             @ 080016B2
	str	r4, [r3]                               @ 080016B4
	b	.L080016E0                               @ 080016B6
.Llit080016B8:
	.word	REG_SOUND4CNT_H                @ 080016B8  = 0x0400007C
.Llit080016BC:
	.word	mcChan+CH_envIdx               @ 080016BC  = 0x030055F0
.L080016C0:
	ldr	r0, [r6, #4]                           @ 080016C0
	lsls	r1, r1, #8                            @ 080016C2
	orrs	r0, r1                                @ 080016C4
	lsls	r0, r0, #0x10                         @ 080016C6
	lsrs	r4, r0, #0x10                         @ 080016C8
	ldr	r0, .Llit08001720                      @ 080016CA  =REG_SOUND4CNT_L
	strh	r4, [r0]                              @ 080016CC
	movs	r6, #2                                @ 080016CE
	ldrsh	r0, [r2, r6]                         @ 080016D0
	str	r0, [r5]                               @ 080016D2
	ldr	r1, .Llit08001724                      @ 080016D4  =REG_SOUND4CNT_H
	ldrh	r0, [r1]                              @ 080016D6
	movs	r7, #0x80                             @ 080016D8
	lsls	r7, r7, #8                            @ 080016DA
	orrs	r0, r7                                @ 080016DC
	strh	r0, [r1]                              @ 080016DE
.L080016E0:
	ldr	r1, [sp, #0x30]                        @ 080016E0
	ldr	r0, [r1]                               @ 080016E2
	cmp	r0, #0                                 @ 080016E4
	beq	.L080016EA                             @ 080016E6
	b	.L08001CDA                               @ 080016E8
.L080016EA:
	ldr	r2, [sp, #0x34]                        @ 080016EA
	ldr	r0, [r2]                               @ 080016EC
	cmp	r0, #0                                 @ 080016EE
	beq	.L080016F4                             @ 080016F0
	b	.L08001854                               @ 080016F2
.L080016F4:
	ldr	r6, .Llit08001728                      @ 080016F4  =mcChan
	ldr	r0, [sp, #0x5c]                        @ 080016F6
	add	r0, r10                                @ 080016F8
	lsls	r4, r0, #3                            @ 080016FA
	adds	r0, r6, #0                            @ 080016FC
	adds	r0, #8                                @ 080016FE
	adds	r3, r4, r0                            @ 08001700
	movs	r5, #0                                @ 08001702
	mov	r8, r5                                 @ 08001704
	adds	r0, #0x30                             @ 08001706
	adds	r0, r4, r0                            @ 08001708
	str	r0, [sp, #0x38]                        @ 0800170A
	adds	r0, r6, #0                            @ 0800170C
	adds	r0, #0x10                             @ 0800170E
	adds	r0, r4, r0                            @ 08001710
	str	r0, [sp, #0x40]                        @ 08001712
	adds	r0, r6, #0                            @ 08001714
	adds	r0, #0x28                             @ 08001716
	adds	r0, r4, r0                            @ 08001718
	str	r0, [sp, #0x3c]                        @ 0800171A
	b	.L08001732                               @ 0800171C
	.hword	0x0000                          @ 0800171E  (padding)
.Llit08001720:
	.word	REG_SOUND4CNT_L                @ 08001720  = 0x04000078
.Llit08001724:
	.word	REG_SOUND4CNT_H                @ 08001724  = 0x0400007C
.Llit08001728:
	.word	mcChan                         @ 08001728  = 0x030055C0
.L0800172C:
	cmp	r7, #0x61                              @ 0800172C  SEQ_END
	bne	.L08001732                             @ 0800172E
	b	.L0800184A                               @ 08001730
.L08001732:
	adds	r0, r6, #0                            @ 08001732
	adds	r0, #0x20                             @ 08001734
	adds	r0, r4, r0                            @ 08001736
	ldr	r5, [r0]                               @ 08001738
	ldr	r7, [r3]                               @ 0800173A
	str	r7, [sp, #0x68]                        @ 0800173C
	lsls	r0, r7, #2                            @ 0800173E
	adds	r0, r0, r5                            @ 08001740
	ldr	r7, [r0]                               @ 08001742
	cmp	r7, #0x67                              @ 08001744  SEQ_PAN
	bne	.L0800176A                             @ 08001746
	ldr	r1, [r0, #4]                           @ 08001748
	lsls	r1, r1, #8                            @ 0800174A
	str	r1, [sp, #0x60]                        @ 0800174C
	ldr	r1, .Llit08001890                      @ 0800174E  =mcFadeLevel
	ldr	r0, [r1]                               @ 08001750
	ldr	r2, [sp, #0x60]                        @ 08001752
	adds	r2, r2, r0                            @ 08001754
	str	r2, [sp, #0x60]                        @ 08001756
	lsls	r0, r0, #4                            @ 08001758
	adds	r1, r2, r0                            @ 0800175A
	ldr	r0, .Llit08001894                      @ 0800175C  =mcMasterPan
	str	r1, [r0]                               @ 0800175E
	ldr	r0, .Llit08001898                      @ 08001760  =REG_SOUNDCNT_L
	strh	r1, [r0]                              @ 08001762
	ldr	r0, [sp, #0x68]                        @ 08001764
	adds	r0, #2                                @ 08001766
	str	r0, [r3]                               @ 08001768
.L0800176A:
	cmp	r7, #0x69                              @ 0800176A  SEQ_TEMPO
	bne	.L0800177E                             @ 0800176C
	ldr	r0, [r3]                               @ 0800176E
	lsls	r1, r0, #2                            @ 08001770
	adds	r1, r1, r5                            @ 08001772
	ldr	r1, [r1, #4]                           @ 08001774
	ldr	r2, .Llit0800189C                      @ 08001776  =mcTempo
	str	r1, [r2]                               @ 08001778
	adds	r0, #2                                @ 0800177A
	str	r0, [r3]                               @ 0800177C
.L0800177E:
	cmp	r7, #0x60                              @ 0800177E  rest / cmd 0x60
	bne	.L08001788                             @ 08001780
	ldr	r0, [r3]                               @ 08001782
	adds	r0, #3                                @ 08001784
	str	r0, [r3]                               @ 08001786
.L08001788:
	cmp	r7, #0x66                              @ 08001788  SEQ_CONDFLAG
	bne	.L0800179C                             @ 0800178A
	ldr	r0, [r3]                               @ 0800178C
	lsls	r1, r0, #2                            @ 0800178E
	adds	r1, r1, r5                            @ 08001790
	ldr	r1, [r1, #4]                           @ 08001792
	ldr	r2, .Llit080018A0                      @ 08001794  =mcCondFlag
	str	r1, [r2]                               @ 08001796
	adds	r0, #2                                @ 08001798
	str	r0, [r3]                               @ 0800179A
.L0800179C:
	cmp	r7, #0x61                              @ 0800179C  SEQ_END
	bne	.L080017FA                             @ 0800179E
	adds	r0, r6, #4                            @ 080017A0
	adds	r0, r4, r0                            @ 080017A2
	ldr	r0, [r0]                               @ 080017A4
	cmp	r0, #0                                 @ 080017A6
	beq	.L080017FA                             @ 080017A8
	mov	r0, r10                                @ 080017AA
	cmp	r0, #0                                 @ 080017AC
	bne	.L080017BA                             @ 080017AE
	ldr	r0, .Llit080018A4                      @ 080017B0  =REG_SOUND1CNT_H
	mov	r1, r10                                @ 080017B2
	strh	r1, [r0]                              @ 080017B4
	ldr	r2, .Llit080018A8                      @ 080017B6  =REG_SOUND1CNT_X
	strh	r1, [r2]                              @ 080017B8
.L080017BA:
	mov	r0, r10                                @ 080017BA
	cmp	r0, #1                                 @ 080017BC
	bne	.L080017CA                             @ 080017BE
	ldr	r0, .Llit080018AC                      @ 080017C0  =REG_SOUND2CNT_L
	mov	r1, r8                                 @ 080017C2
	strh	r1, [r0]                              @ 080017C4
	ldr	r2, .Llit080018B0                      @ 080017C6  =REG_SOUND2CNT_H
	strh	r1, [r2]                              @ 080017C8
.L080017CA:
	mov	r0, r10                                @ 080017CA
	cmp	r0, #2                                 @ 080017CC
	bne	.L080017DA                             @ 080017CE
	ldr	r0, .Llit080018B4                      @ 080017D0  =REG_SOUND3CNT_H
	mov	r1, r8                                 @ 080017D2
	strh	r1, [r0]                              @ 080017D4
	ldr	r2, .Llit080018B8                      @ 080017D6  =REG_SOUND3CNT_X
	strh	r1, [r2]                              @ 080017D8
.L080017DA:
	mov	r0, r10                                @ 080017DA
	cmp	r0, #3                                 @ 080017DC
	bne	.L080017EA                             @ 080017DE
	ldr	r0, .Llit080018BC                      @ 080017E0  =REG_SOUND4CNT_L
	mov	r1, r8                                 @ 080017E2
	strh	r1, [r0]                              @ 080017E4
	adds	r0, #4                                @ 080017E6
	strh	r1, [r0]                              @ 080017E8
.L080017EA:
	mov	r2, r10                                @ 080017EA
	subs	r2, #4                                @ 080017EC
	cmp	r2, #1                                 @ 080017EE
	bhi	.L080017FA                             @ 080017F0
	movs	r0, #1                                @ 080017F2
	rsbs	r0, r0, #0                            @ 080017F4
	ldr	r1, [sp, #0x38]                        @ 080017F6
	str	r0, [r1]                               @ 080017F8
.L080017FA:
	cmp	r7, #0x64                              @ 080017FA  SEQ_PAT
	bne	.L08001836                             @ 080017FC
	ldr	r0, [r3]                               @ 080017FE
	lsls	r0, r0, #2                            @ 08001800
	adds	r0, r0, r5                            @ 08001802
	ldr	r0, [r0, #8]                           @ 08001804
	ldr	r2, [sp, #0x3c]                        @ 08001806
	str	r0, [r2]                               @ 08001808
	ldr	r0, .Llit080018C0                      @ 0800180A  =mcChan+CH_patPtr
	adds	r1, r4, r0                            @ 0800180C
	ldr	r2, [r3]                               @ 0800180E
	lsls	r2, r2, #2                            @ 08001810
	adds	r2, r2, r5                            @ 08001812
	ldr	r0, [r2, #4]                           @ 08001814
	str	r0, [r1]                               @ 08001816
	adds	r1, r6, #0                            @ 08001818
	adds	r1, #0x2c                             @ 0800181A
	adds	r1, r4, r1                            @ 0800181C
	ldr	r0, [r2, #0xc]                         @ 0800181E
	str	r0, [r1]                               @ 08001820
	adds	r0, r6, #0                            @ 08001822
	adds	r0, #0xc                              @ 08001824
	adds	r0, r4, r0                            @ 08001826
	movs	r1, #0                                @ 08001828
	str	r1, [r0]                               @ 0800182A
	ldr	r2, [sp, #0x40]                        @ 0800182C
	str	r1, [r2]                               @ 0800182E
	ldr	r0, [r3]                               @ 08001830
	adds	r0, #4                                @ 08001832
	str	r0, [r3]                               @ 08001834
.L08001836:
	cmp	r7, #0x62                              @ 08001836  SEQ_JUMP
	bne	.L08001844                             @ 08001838
	ldr	r0, [r3]                               @ 0800183A
	lsls	r0, r0, #2                            @ 0800183C
	adds	r0, r0, r5                            @ 0800183E
	ldr	r0, [r0, #4]                           @ 08001840
	str	r0, [r3]                               @ 08001842
.L08001844:
	cmp	r7, #0x64                              @ 08001844  SEQ_PAT
	beq	.L0800184A                             @ 08001846
	b	.L0800172C                               @ 08001848
.L0800184A:
	ldr	r3, [sp, #0x34]                        @ 0800184A
	ldr	r0, [r3]                               @ 0800184C
	cmp	r0, #0                                 @ 0800184E
	bne	.L08001854                             @ 08001850
	b	.L08001CDA                               @ 08001852
.L08001854:
	ldr	r4, [sp, #0x28]                        @ 08001854
	lsls	r1, r4, #3                            @ 08001856
	ldr	r5, .Llit080018C0                      @ 08001858  =mcChan+CH_patPtr
	adds	r3, r1, r5                            @ 0800185A
	ldr	r5, [r3]                               @ 0800185C
	mov	r0, r9                                 @ 0800185E
	adds	r0, #0xc                              @ 08001860
	adds	r2, r1, r0                            @ 08001862
	ldr	r0, [r2]                               @ 08001864
	adds	r0, r5, r0                            @ 08001866
	ldrb	r0, [r0]                              @ 08001868
	str	r0, [sp, #0x24]                        @ 0800186A
	cmp	r0, #0x65                              @ 0800186C  pattern end
	bne	.L080018D2                             @ 0800186E
	mov	r0, r12                                @ 08001870
	adds	r0, #0x2c                             @ 08001872
	adds	r1, r1, r0                            @ 08001874
	ldr	r0, [r1]                               @ 08001876
	cmp	r0, #0                                 @ 08001878
	beq	.L080018C4                             @ 0800187A
	subs	r0, #1                                @ 0800187C
	str	r0, [r1]                               @ 0800187E
	cmp	r0, #0                                 @ 08001880
	beq	.L080018C4                             @ 08001882
	movs	r6, #0                                @ 08001884
	str	r6, [r2]                               @ 08001886
	ldrb	r7, [r5]                              @ 08001888
	str	r7, [sp, #0x24]                        @ 0800188A
	b	.L080018C8                               @ 0800188C
	.hword	0x0000                          @ 0800188E  (padding)
.Llit08001890:
	.word	mcFadeLevel                    @ 08001890  = 0x03005800
.Llit08001894:
	.word	mcMasterPan                    @ 08001894  = 0x030053C8
.Llit08001898:
	.word	REG_SOUNDCNT_L                 @ 08001898  = 0x04000080
.Llit0800189C:
	.word	mcTempo                        @ 0800189C  = 0x03005254
.Llit080018A0:
	.word	mcCondFlag                     @ 080018A0  = 0x03005810
.Llit080018A4:
	.word	REG_SOUND1CNT_H                @ 080018A4  = 0x04000062
.Llit080018A8:
	.word	REG_SOUND1CNT_X                @ 080018A8  = 0x04000064
.Llit080018AC:
	.word	REG_SOUND2CNT_L                @ 080018AC  = 0x04000068
.Llit080018B0:
	.word	REG_SOUND2CNT_H                @ 080018B0  = 0x0400006C
.Llit080018B4:
	.word	REG_SOUND3CNT_H                @ 080018B4  = 0x04000072
.Llit080018B8:
	.word	REG_SOUND3CNT_X                @ 080018B8  = 0x04000074
.Llit080018BC:
	.word	REG_SOUND4CNT_L                @ 080018BC  = 0x04000078
.Llit080018C0:
	.word	mcChan+CH_patPtr               @ 080018C0  = 0x030055E4
.L080018C4:
	str	r0, [r3]                               @ 080018C4
	str	r0, [r2]                               @ 080018C6
.L080018C8:
	ldr	r0, [sp, #0x24]                        @ 080018C8
	cmp	r0, #0x65                              @ 080018CA  pattern end
	bne	.L080018D2                             @ 080018CC
	bl	.L080010C8                              @ 080018CE  long branch
.L080018D2:
	ldr	r2, [sp, #0x28]                        @ 080018D2
	lsls	r1, r2, #3                            @ 080018D4
	mov	r0, r9                                 @ 080018D6
	adds	r0, #0xc                              @ 080018D8
	adds	r0, r1, r0                            @ 080018DA
	ldr	r0, [r0]                               @ 080018DC
	adds	r0, r5, r0                            @ 080018DE
	ldrb	r7, [r0]                              @ 080018E0
	cmp	r7, #0x60                              @ 080018E2  rest / cmd 0x60
	beq	.L080018FC                             @ 080018E4
	mov	r0, r12                                @ 080018E6
	adds	r0, #0x28                             @ 080018E8
	adds	r0, r1, r0                            @ 080018EA
	ldr	r0, [r0]                               @ 080018EC
	adds	r0, r7, r0                            @ 080018EE
	lsls	r0, r0, #0x18                         @ 080018F0
	lsrs	r7, r0, #0x18                         @ 080018F2
	mov	r3, r10                                @ 080018F4
	subs	r3, #4                                @ 080018F6
	str	r3, [sp, #0x54]                        @ 080018F8
	b	.L0800190A                               @ 080018FA
.L080018FC:
	movs	r7, #0x30                             @ 080018FC  rest: note = 0x30 ...
	mov	r4, r10                                @ 080018FE
	subs	r4, #4                                @ 08001900
	str	r4, [sp, #0x54]                        @ 08001902
	cmp	r4, #1                                 @ 08001904  ... but kept at 0x60 only if (ch - 4) <= 1: BUG, rests on ch 7/8 key note 0x30
	bhi	.L0800190A                             @ 08001906
	movs	r7, #0x60                             @ 08001908
.L0800190A:
	ldr	r0, .Llit080019FC                      @ 0800190A  =mcDurTable
	ldr	r4, [r0]                               @ 0800190C
	ldr	r6, [sp, #0x44]                        @ 0800190E
	str	r7, [r6]                               @ 08001910
	ldr	r0, .Llit08001A00                      @ 08001912  =mcFreqHi
	mov	r8, r0                                 @ 08001914
	adds	r0, r7, r0                            @ 08001916
	ldrb	r0, [r0]                              @ 08001918
	lsls	r1, r0, #8                            @ 0800191A
	ldr	r3, .Llit08001A04                      @ 0800191C  =mcFreqLo
	adds	r0, r7, r3                            @ 0800191E
	ldrb	r0, [r0]                              @ 08001920
	orrs	r1, r0                                @ 08001922
	ldr	r2, [sp, #0x48]                        @ 08001924
	str	r1, [r2]                               @ 08001926
	mov	r2, r12                                @ 08001928
	adds	r2, #0x1c                             @ 0800192A
	ldr	r6, [sp, #0x2c]                        @ 0800192C
	adds	r2, r6, r2                            @ 0800192E
	mov	r1, r12                                @ 08001930
	adds	r1, #0xc                              @ 08001932
	adds	r1, r6, r1                            @ 08001934
	ldr	r0, [r1]                               @ 08001936
	adds	r0, r5, r0                            @ 08001938
	ldrb	r0, [r0, #1]                          @ 0800193A
	str	r0, [r2]                               @ 0800193C
	ldr	r0, [r1]                               @ 0800193E
	adds	r0, r5, r0                            @ 08001940
	ldrb	r0, [r0, #2]                          @ 08001942
	lsls	r0, r0, #2                            @ 08001944
	adds	r0, r0, r4                            @ 08001946
	ldr	r0, [r0]                               @ 08001948
	ldr	r2, [sp, #0x30]                        @ 0800194A
	str	r0, [r2]                               @ 0800194C
	ldr	r0, [r1]                               @ 0800194E
	adds	r0, #3                                @ 08001950
	str	r0, [r1]                               @ 08001952
	mov	r4, r10                                @ 08001954
	cmp	r4, #0                                 @ 08001956
	bne	.L08001A30                             @ 08001958
	mov	r5, r12                                @ 0800195A
	ldr	r0, [r5, #0x1c]                        @ 0800195C
	lsls	r0, r0, #2                            @ 0800195E
	ldr	r6, .Llit08001A08                      @ 08001960  =mcInstTable
	adds	r0, r0, r6                            @ 08001962
	ldr	r6, [r0]                               @ 08001964
	ldr	r1, [r6, #4]                           @ 08001966
	ldr	r0, [r6, #8]                           @ 08001968
	lsls	r0, r0, #8                            @ 0800196A
	adds	r1, r1, r0                            @ 0800196C
	lsls	r1, r1, #0x10                         @ 0800196E
	lsrs	r4, r1, #0x10                         @ 08001970
	ldr	r2, [r6, #0x10]                        @ 08001972
	cmp	r2, #0                                 @ 08001974
	beq	.L08001990                             @ 08001976
	movs	r0, #0xff                             @ 08001978
	ands	r4, r0                                @ 0800197A
	ldrh	r1, [r2]                              @ 0800197C
	lsls	r0, r1, #8                            @ 0800197E
	orrs	r4, r0                                @ 08001980
	lsls	r0, r4, #0x10                         @ 08001982
	lsrs	r4, r0, #0x10                         @ 08001984
	mov	r0, r10                                @ 08001986
	str	r0, [r5, #0x30]                        @ 08001988
	movs	r1, #2                                @ 0800198A
	ldrsh	r0, [r2, r1]                         @ 0800198C
	str	r0, [r5, #0x34]                        @ 0800198E
.L08001990:
	mov	r2, r12                                @ 08001990
	ldr	r5, [r2, #4]                           @ 08001992
	cmp	r5, #0                                 @ 08001994
	beq	.L0800199C                             @ 08001996
	ldr	r0, .Llit08001A0C                      @ 08001998  =REG_SOUND1CNT_H
	strh	r4, [r0]                              @ 0800199A
.L0800199C:
	ldr	r2, [r6, #0x20]                        @ 0800199C
	cmp	r2, #0                                 @ 0800199E
	beq	.L080019C6                             @ 080019A0
	movs	r4, #2                                @ 080019A2
	ldrsh	r0, [r2, r4]                         @ 080019A4
	adds	r0, r7, r0                            @ 080019A6
	mov	r4, r8                                 @ 080019A8
	adds	r1, r0, r4                            @ 080019AA
	ldrb	r1, [r1]                              @ 080019AC
	lsls	r1, r1, #8                            @ 080019AE
	adds	r0, r0, r3                            @ 080019B0
	ldrb	r0, [r0]                              @ 080019B2
	orrs	r1, r0                                @ 080019B4
	mov	r0, r12                                @ 080019B6
	str	r1, [r0, #0x18]                        @ 080019B8
	mov	r1, r10                                @ 080019BA
	str	r1, [r0, #0x40]                        @ 080019BC
	movs	r4, #0                                @ 080019BE
	ldrsh	r0, [r2, r4]                         @ 080019C0
	mov	r1, r12                                @ 080019C2
	str	r0, [r1, #0x44]                        @ 080019C4
.L080019C6:
	ldr	r0, [r6]                               @ 080019C6
	lsls	r0, r0, #0x18                         @ 080019C8
	lsrs	r4, r0, #0x10                         @ 080019CA
	ldr	r2, [r6, #0x18]                        @ 080019CC
	cmp	r2, #0                                 @ 080019CE
	beq	.L08001A18                             @ 080019D0
	ldrh	r6, [r2]                              @ 080019D2
	ldr	r1, .Llit08001A10                      @ 080019D4  =0xFFFF8000
	adds	r0, r6, r1                            @ 080019D6
	orrs	r4, r0                                @ 080019D8
	mov	r6, r10                                @ 080019DA
	mov	r0, r12                                @ 080019DC
	str	r6, [r0, #0x38]                        @ 080019DE
	movs	r1, #2                                @ 080019E0
	ldrsh	r0, [r2, r1]                         @ 080019E2
	mov	r2, r12                                @ 080019E4
	str	r0, [r2, #0x3c]                        @ 080019E6
	ldr	r0, [r2, #0x18]                        @ 080019E8
	orrs	r0, r4                                @ 080019EA
	lsls	r0, r0, #0x10                         @ 080019EC
	lsrs	r4, r0, #0x10                         @ 080019EE
	cmp	r5, #0                                 @ 080019F0
	beq	.L08001A30                             @ 080019F2
	ldr	r5, .Llit08001A14                      @ 080019F4  =REG_SOUND1CNT_X
	strh	r4, [r5]                              @ 080019F6
	b	.L08001A30                               @ 080019F8
	.hword	0x0000                          @ 080019FA  (padding)
.Llit080019FC:
	.word	mcDurTable                     @ 080019FC  = 0x030053D0
.Llit08001A00:
	.word	mcFreqHi                       @ 08001A00  = 0x08091515
.Llit08001A04:
	.word	mcFreqLo                       @ 08001A04  = 0x080914B4
.Llit08001A08:
	.word	mcInstTable                    @ 08001A08  = 0x08091F94
.Llit08001A0C:
	.word	REG_SOUND1CNT_H                @ 08001A0C  = 0x04000062
.Llit08001A10:
	.word	0xFFFF8000                     @ 08001A10
.Llit08001A14:
	.word	REG_SOUND1CNT_X                @ 08001A14  = 0x04000064
.L08001A18:
	movs	r6, #0x80                             @ 08001A18
	lsls	r6, r6, #8                            @ 08001A1A
	orrs	r4, r6                                @ 08001A1C
	mov	r1, r12                                @ 08001A1E
	ldr	r0, [r1, #0x18]                        @ 08001A20
	orrs	r0, r4                                @ 08001A22
	lsls	r0, r0, #0x10                         @ 08001A24
	lsrs	r4, r0, #0x10                         @ 08001A26
	cmp	r5, #0                                 @ 08001A28
	beq	.L08001A30                             @ 08001A2A
	ldr	r2, .Llit08001AD8                      @ 08001A2C  =REG_SOUND1CNT_X
	strh	r4, [r2]                              @ 08001A2E
.L08001A30:
	mov	r4, r10                                @ 08001A30
	cmp	r4, #1                                 @ 08001A32
	bne	.L08001B00                             @ 08001A34
	mov	r5, r12                                @ 08001A36
	ldr	r0, [r5, #0x64]                        @ 08001A38
	lsls	r0, r0, #2                            @ 08001A3A
	ldr	r6, .Llit08001ADC                      @ 08001A3C  =mcInstTable
	adds	r0, r0, r6                            @ 08001A3E
	ldr	r6, [r0]                               @ 08001A40
	ldr	r1, [r6, #4]                           @ 08001A42
	ldr	r0, [r6, #8]                           @ 08001A44
	lsls	r0, r0, #8                            @ 08001A46
	adds	r1, r1, r0                            @ 08001A48
	lsls	r1, r1, #0x10                         @ 08001A4A
	lsrs	r4, r1, #0x10                         @ 08001A4C
	ldr	r2, [r6, #0x10]                        @ 08001A4E
	cmp	r2, #0                                 @ 08001A50
	beq	.L08001A6C                             @ 08001A52
	movs	r0, #0xff                             @ 08001A54
	ands	r4, r0                                @ 08001A56
	ldrh	r1, [r2]                              @ 08001A58
	lsls	r0, r1, #8                            @ 08001A5A
	orrs	r4, r0                                @ 08001A5C
	lsls	r0, r4, #0x10                         @ 08001A5E
	lsrs	r4, r0, #0x10                         @ 08001A60
	movs	r0, #0                                @ 08001A62
	str	r0, [r5, #0x78]                        @ 08001A64
	movs	r1, #2                                @ 08001A66
	ldrsh	r0, [r2, r1]                         @ 08001A68
	str	r0, [r5, #0x7c]                        @ 08001A6A
.L08001A6C:
	mov	r2, r12                                @ 08001A6C
	ldr	r5, [r2, #0x4c]                        @ 08001A6E
	cmp	r5, #0                                 @ 08001A70
	beq	.L08001A78                             @ 08001A72
	ldr	r0, .Llit08001AE0                      @ 08001A74  =REG_SOUND2CNT_L
	strh	r4, [r0]                              @ 08001A76
.L08001A78:
	ldr	r2, [r6, #0x20]                        @ 08001A78
	cmp	r2, #0                                 @ 08001A7A
	beq	.L08001AA6                             @ 08001A7C
	movs	r4, #2                                @ 08001A7E
	ldrsh	r0, [r2, r4]                         @ 08001A80
	adds	r0, r7, r0                            @ 08001A82
	ldr	r4, .Llit08001AE4                      @ 08001A84  =mcFreqHi
	adds	r1, r0, r4                            @ 08001A86
	ldrb	r1, [r1]                              @ 08001A88
	lsls	r1, r1, #8                            @ 08001A8A
	adds	r0, r0, r3                            @ 08001A8C
	ldrb	r0, [r0]                              @ 08001A8E
	orrs	r1, r0                                @ 08001A90
	mov	r0, r12                                @ 08001A92
	str	r1, [r0, #0x60]                        @ 08001A94
	adds	r0, #0x88                             @ 08001A96
	movs	r1, #0                                @ 08001A98
	str	r1, [r0]                               @ 08001A9A
	mov	r1, r12                                @ 08001A9C
	adds	r1, #0x8c                             @ 08001A9E
	movs	r4, #0                                @ 08001AA0
	ldrsh	r0, [r2, r4]                         @ 08001AA2
	str	r0, [r1]                               @ 08001AA4
.L08001AA6:
	ldr	r0, [r6]                               @ 08001AA6
	lsls	r0, r0, #0x18                         @ 08001AA8
	lsrs	r4, r0, #0x10                         @ 08001AAA
	ldr	r2, [r6, #0x18]                        @ 08001AAC
	cmp	r2, #0                                 @ 08001AAE
	beq	.L08001AE8                             @ 08001AB0
	movs	r0, #0x80                             @ 08001AB2
	lsls	r0, r0, #8                            @ 08001AB4
	ldrh	r6, [r2]                              @ 08001AB6
	orrs	r0, r6                                @ 08001AB8
	orrs	r4, r0                                @ 08001ABA
	mov	r0, r12                                @ 08001ABC
	adds	r0, #0x80                             @ 08001ABE
	movs	r1, #0                                @ 08001AC0
	str	r1, [r0]                               @ 08001AC2
	mov	r1, r12                                @ 08001AC4
	adds	r1, #0x84                             @ 08001AC6
	movs	r6, #2                                @ 08001AC8
	ldrsh	r0, [r2, r6]                         @ 08001ACA
	str	r0, [r1]                               @ 08001ACC
	mov	r1, r12                                @ 08001ACE
	ldr	r0, [r1, #0x60]                        @ 08001AD0
	orrs	r4, r0                                @ 08001AD2
	lsls	r0, r4, #0x10                         @ 08001AD4
	b	.L08001AF6                               @ 08001AD6
.Llit08001AD8:
	.word	REG_SOUND1CNT_X                @ 08001AD8  = 0x04000064
.Llit08001ADC:
	.word	mcInstTable                    @ 08001ADC  = 0x08091F94
.Llit08001AE0:
	.word	REG_SOUND2CNT_L                @ 08001AE0  = 0x04000068
.Llit08001AE4:
	.word	mcFreqHi                       @ 08001AE4  = 0x08091515
.L08001AE8:
	movs	r6, #0x80                             @ 08001AE8
	lsls	r6, r6, #8                            @ 08001AEA
	orrs	r4, r6                                @ 08001AEC
	mov	r1, r12                                @ 08001AEE
	ldr	r0, [r1, #0x60]                        @ 08001AF0
	orrs	r0, r4                                @ 08001AF2
	lsls	r0, r0, #0x10                         @ 08001AF4
.L08001AF6:
	lsrs	r4, r0, #0x10                         @ 08001AF6
	cmp	r5, #0                                 @ 08001AF8
	beq	.L08001B00                             @ 08001AFA
	ldr	r2, .Llit08001BC4                      @ 08001AFC  =REG_SOUND2CNT_H
	strh	r4, [r2]                              @ 08001AFE
.L08001B00:
	mov	r4, r10                                @ 08001B00
	cmp	r4, #2                                 @ 08001B02
	bne	.L08001BF6                             @ 08001B04
	mov	r0, r12                                @ 08001B06
	adds	r0, #0xac                             @ 08001B08
	ldr	r0, [r0]                               @ 08001B0A
	lsls	r0, r0, #2                            @ 08001B0C
	ldr	r5, .Llit08001BC8                      @ 08001B0E  =mcInstTable
	adds	r0, r0, r5                            @ 08001B10
	ldr	r6, [r0]                               @ 08001B12
	ldr	r1, [r6, #4]                           @ 08001B14
	ldr	r0, [r6, #8]                           @ 08001B16
	lsls	r0, r0, #8                            @ 08001B18
	adds	r1, r1, r0                            @ 08001B1A
	lsls	r1, r1, #0x10                         @ 08001B1C
	lsrs	r4, r1, #0x10                         @ 08001B1E
	ldr	r2, [r6, #0x10]                        @ 08001B20
	cmp	r2, #0                                 @ 08001B22
	beq	.L08001B46                             @ 08001B24
	movs	r0, #0xff                             @ 08001B26
	ands	r4, r0                                @ 08001B28
	ldrh	r1, [r2]                              @ 08001B2A
	lsls	r0, r1, #8                            @ 08001B2C
	orrs	r4, r0                                @ 08001B2E
	lsls	r0, r4, #0x10                         @ 08001B30
	lsrs	r4, r0, #0x10                         @ 08001B32
	mov	r0, r12                                @ 08001B34
	adds	r0, #0xc0                             @ 08001B36
	movs	r5, #0                                @ 08001B38
	str	r5, [r0]                               @ 08001B3A
	mov	r1, r12                                @ 08001B3C
	adds	r1, #0xc4                             @ 08001B3E
	movs	r5, #2                                @ 08001B40
	ldrsh	r0, [r2, r5]                         @ 08001B42
	str	r0, [r1]                               @ 08001B44
.L08001B46:
	mov	r5, r12                                @ 08001B46
	adds	r5, #0x94                             @ 08001B48
	ldr	r0, [r5]                               @ 08001B4A
	cmp	r0, #0                                 @ 08001B4C
	beq	.L08001B54                             @ 08001B4E
	ldr	r0, .Llit08001BCC                      @ 08001B50  =REG_SOUND3CNT_H
	strh	r4, [r0]                              @ 08001B52
.L08001B54:
	ldr	r2, [r6, #0x20]                        @ 08001B54
	cmp	r2, #0                                 @ 08001B56
	beq	.L08001B84                             @ 08001B58
	movs	r1, #2                                @ 08001B5A
	ldrsh	r0, [r2, r1]                         @ 08001B5C
	adds	r0, r7, r0                            @ 08001B5E
	ldr	r4, .Llit08001BD0                      @ 08001B60  =mcFreqHi
	adds	r1, r0, r4                            @ 08001B62
	ldrb	r1, [r1]                              @ 08001B64
	lsls	r1, r1, #8                            @ 08001B66
	adds	r0, r0, r3                            @ 08001B68
	ldrb	r0, [r0]                              @ 08001B6A
	orrs	r1, r0                                @ 08001B6C
	ldr	r7, .Llit08001BD4                      @ 08001B6E  =mcChan+0x90+CH_freq
	str	r1, [r7]                               @ 08001B70
	mov	r0, r12                                @ 08001B72
	adds	r0, #0xd0                             @ 08001B74
	movs	r1, #0                                @ 08001B76
	str	r1, [r0]                               @ 08001B78
	mov	r1, r12                                @ 08001B7A
	adds	r1, #0xd4                             @ 08001B7C
	movs	r3, #0                                @ 08001B7E
	ldrsh	r0, [r2, r3]                         @ 08001B80
	str	r0, [r1]                               @ 08001B82
.L08001B84:
	ldr	r0, [r6]                               @ 08001B84
	lsls	r0, r0, #0x18                         @ 08001B86
	lsrs	r4, r0, #0x10                         @ 08001B88
	ldr	r2, [r6, #0x18]                        @ 08001B8A
	cmp	r2, #0                                 @ 08001B8C
	beq	.L08001BDC                             @ 08001B8E
	movs	r0, #0x80                             @ 08001B90
	lsls	r0, r0, #8                            @ 08001B92
	ldrh	r6, [r2]                              @ 08001B94
	orrs	r0, r6                                @ 08001B96
	orrs	r4, r0                                @ 08001B98
	mov	r0, r12                                @ 08001B9A
	adds	r0, #0xc8                             @ 08001B9C
	movs	r7, #0                                @ 08001B9E
	str	r7, [r0]                               @ 08001BA0
	mov	r1, r12                                @ 08001BA2
	adds	r1, #0xcc                             @ 08001BA4
	movs	r3, #2                                @ 08001BA6
	ldrsh	r0, [r2, r3]                         @ 08001BA8
	str	r0, [r1]                               @ 08001BAA
	ldr	r6, .Llit08001BD4                      @ 08001BAC  =mcChan+0x90+CH_freq
	ldr	r0, [r6]                               @ 08001BAE
	orrs	r4, r0                                @ 08001BB0
	lsls	r0, r4, #0x10                         @ 08001BB2
	lsrs	r4, r0, #0x10                         @ 08001BB4
	ldr	r0, [r5]                               @ 08001BB6
	cmp	r0, #0                                 @ 08001BB8
	beq	.L08001BF6                             @ 08001BBA
	ldr	r7, .Llit08001BD8                      @ 08001BBC  =REG_SOUND3CNT_X
	strh	r4, [r7]                              @ 08001BBE
	b	.L08001BF6                               @ 08001BC0
	.hword	0x0000                          @ 08001BC2  (padding)
.Llit08001BC4:
	.word	REG_SOUND2CNT_H                @ 08001BC4  = 0x0400006C
.Llit08001BC8:
	.word	mcInstTable                    @ 08001BC8  = 0x08091F94
.Llit08001BCC:
	.word	REG_SOUND3CNT_H                @ 08001BCC  = 0x04000072
.Llit08001BD0:
	.word	mcFreqHi                       @ 08001BD0  = 0x08091515
.Llit08001BD4:
	.word	mcChan+0x90+CH_freq            @ 08001BD4  = 0x03005668
.Llit08001BD8:
	.word	REG_SOUND3CNT_X                @ 08001BD8  = 0x04000074
.L08001BDC:
	movs	r0, #0x80                             @ 08001BDC
	lsls	r0, r0, #8                            @ 08001BDE
	orrs	r4, r0                                @ 08001BE0
	ldr	r1, .Llit08001D00                      @ 08001BE2  =mcChan+0x90+CH_freq
	ldr	r0, [r1]                               @ 08001BE4
	orrs	r0, r4                                @ 08001BE6
	lsls	r0, r0, #0x10                         @ 08001BE8
	lsrs	r4, r0, #0x10                         @ 08001BEA
	ldr	r0, [r5]                               @ 08001BEC
	cmp	r0, #0                                 @ 08001BEE
	beq	.L08001BF6                             @ 08001BF0
	ldr	r2, .Llit08001D04                      @ 08001BF2  =REG_SOUND3CNT_X
	strh	r4, [r2]                              @ 08001BF4
.L08001BF6:
	mov	r3, r10                                @ 08001BF6
	cmp	r3, #3                                 @ 08001BF8
	bne	.L08001C86                             @ 08001BFA
	mov	r3, r12                                @ 08001BFC
	adds	r0, r3, #0                            @ 08001BFE
	adds	r0, #0xf4                             @ 08001C00
	ldr	r0, [r0]                               @ 08001C02
	lsls	r0, r0, #2                            @ 08001C04
	ldr	r4, .Llit08001D08                      @ 08001C06  =mcInstTable
	adds	r0, r0, r4                            @ 08001C08
	ldr	r6, [r0]                               @ 08001C0A
	ldr	r1, [r6, #4]                           @ 08001C0C
	ldr	r0, [r6, #8]                           @ 08001C0E
	lsls	r0, r0, #8                            @ 08001C10
	adds	r1, r1, r0                            @ 08001C12
	lsls	r1, r1, #0x10                         @ 08001C14
	lsrs	r4, r1, #0x10                         @ 08001C16
	ldr	r2, [r6, #0x10]                        @ 08001C18
	cmp	r2, #0                                 @ 08001C1A
	beq	.L08001C42                             @ 08001C1C
	movs	r0, #0xff                             @ 08001C1E
	ands	r4, r0                                @ 08001C20
	ldrh	r5, [r2]                              @ 08001C22
	lsls	r0, r5, #8                            @ 08001C24
	orrs	r4, r0                                @ 08001C26
	lsls	r0, r4, #0x10                         @ 08001C28
	lsrs	r4, r0, #0x10                         @ 08001C2A
	movs	r7, #0x84                             @ 08001C2C
	lsls	r7, r7, #1                            @ 08001C2E
	adds	r0, r3, r7                            @ 08001C30
	movs	r1, #0                                @ 08001C32
	str	r1, [r0]                               @ 08001C34
	movs	r5, #0x86                             @ 08001C36
	lsls	r5, r5, #1                            @ 08001C38
	adds	r1, r3, r5                            @ 08001C3A
	movs	r7, #2                                @ 08001C3C
	ldrsh	r0, [r2, r7]                         @ 08001C3E
	str	r0, [r1]                               @ 08001C40
.L08001C42:
	adds	r3, #0xdc                             @ 08001C42
	ldr	r0, [r3]                               @ 08001C44
	cmp	r0, #0                                 @ 08001C46
	beq	.L08001C4E                             @ 08001C48
	ldr	r0, .Llit08001D0C                      @ 08001C4A  =REG_SOUND4CNT_L
	strh	r4, [r0]                              @ 08001C4C
.L08001C4E:
	ldr	r0, [r6]                               @ 08001C4E
	lsls	r0, r0, #0x18                         @ 08001C50
	lsrs	r4, r0, #0x10                         @ 08001C52
	ldr	r2, [r6, #0x18]                        @ 08001C54
	cmp	r2, #0                                 @ 08001C56
	beq	.L08001C86                             @ 08001C58
	ldrh	r1, [r2]                              @ 08001C5A
	ldr	r5, .Llit08001D10                      @ 08001C5C  =0xFFFF8000
	adds	r0, r1, r5                            @ 08001C5E
	orrs	r4, r0                                @ 08001C60
	lsls	r0, r4, #0x10                         @ 08001C62
	lsrs	r4, r0, #0x10                         @ 08001C64
	movs	r0, #0x88                             @ 08001C66
	lsls	r0, r0, #1                            @ 08001C68
	add	r0, r12                                @ 08001C6A
	movs	r6, #0                                @ 08001C6C
	str	r6, [r0]                               @ 08001C6E
	movs	r1, #0x8a                             @ 08001C70
	lsls	r1, r1, #1                            @ 08001C72
	add	r1, r12                                @ 08001C74
	movs	r7, #2                                @ 08001C76
	ldrsh	r0, [r2, r7]                         @ 08001C78
	str	r0, [r1]                               @ 08001C7A
	ldr	r0, [r3]                               @ 08001C7C
	cmp	r0, #0                                 @ 08001C7E
	beq	.L08001C86                             @ 08001C80
	ldr	r0, .Llit08001D14                      @ 08001C82  =REG_SOUND4CNT_H
	strh	r4, [r0]                              @ 08001C84
.L08001C86:
	ldr	r0, [sp, #0x54]                        @ 08001C86
	cmp	r0, #3                                 @ 08001C88  (ch - 4) <= 3: PCM channel note-on
	bhi	.L08001CDA                             @ 08001C8A
	ldr	r2, .Llit08001D18                      @ 08001C8C  =mcStepTable
	ldr	r3, [sp, #0x44]                        @ 08001C8E
	ldr	r1, [r3]                               @ 08001C90
	movs	r0, #0x5f                             @ 08001C92  step = mcStepTable[0x5F - note]
	subs	r0, r0, r1                            @ 08001C94
	lsls	r0, r0, #2                            @ 08001C96
	adds	r0, r0, r2                            @ 08001C98
	ldr	r0, [r0]                               @ 08001C9A
	ldr	r4, [sp, #0x4c]                        @ 08001C9C
	str	r0, [r4]                               @ 08001C9E
	mov	r0, r9                                 @ 08001CA0
	adds	r0, #0x34                             @ 08001CA2
	ldr	r5, [sp, #0x2c]                        @ 08001CA4
	adds	r0, r5, r0                            @ 08001CA6
	movs	r1, #1                                @ 08001CA8
	str	r1, [r0]                               @ 08001CAA  +0x34 = 1
	mov	r0, r9                                 @ 08001CAC
	adds	r0, #0x38                             @ 08001CAE
	adds	r2, r5, r0                            @ 08001CB0
	movs	r6, #0                                @ 08001CB2
	str	r6, [r2]                               @ 08001CB4  pos = 0
	ldr	r1, .Llit08001D1C                      @ 08001CB6  =mcSmpInstTable
	subs	r0, #0x1c                             @ 08001CB8
	adds	r0, r5, r0                            @ 08001CBA
	ldr	r0, [r0]                               @ 08001CBC
	lsls	r0, r0, #4                            @ 08001CBE
	adds	r1, #4                                @ 08001CC0
	adds	r0, r0, r1                            @ 08001CC2
	ldr	r0, [r0]                               @ 08001CC4
	subs	r0, #4                                @ 08001CC6
	lsls	r0, r0, #0xe                          @ 08001CC8
	ldr	r7, [sp, #0x50]                        @ 08001CCA
	str	r0, [r7]                               @ 08001CCC  end = (mcSmpInstTable[inst].length - 4) << 14
	ldr	r0, [r3]                               @ 08001CCE
	cmp	r0, #0x60                              @ 08001CD0  rest / cmd 0x60
	bne	.L08001CDA                             @ 08001CD2
	movs	r0, #1                                @ 08001CD4
	rsbs	r0, r0, #0                            @ 08001CD6
	str	r0, [r2]                               @ 08001CD8  rest: pos = -1 (stopped)
.L08001CDA:
	ldr	r0, [sp, #0x24]                        @ 08001CDA
	cmp	r0, #0x65                              @ 08001CDC  pattern end
	bne	.L08001CE4                             @ 08001CDE
	bl	.L080010FE                              @ 08001CE0  long branch
.L08001CE4:
	ldr	r1, [sp, #0x58]                        @ 08001CE4
	mov	r10, r1                                @ 08001CE6
	cmp	r1, #7                                 @ 08001CE8
	bgt	.L08001CF0                             @ 08001CEA
	bl	.L0800109A                              @ 08001CEC  long branch
.L08001CF0:
	add	sp, #0x6c                              @ 08001CF0
	pop	{r3, r4, r5}                           @ 08001CF2
	mov	r8, r3                                 @ 08001CF4
	mov	r9, r4                                 @ 08001CF6
	mov	r10, r5                                @ 08001CF8
	pop	{r4, r5, r6, r7}                       @ 08001CFA
	pop	{r0}                                   @ 08001CFC
	bx	r0                                      @ 08001CFE
.Llit08001D00:
	.word	mcChan+0x90+CH_freq            @ 08001D00  = 0x03005668
.Llit08001D04:
	.word	REG_SOUND3CNT_X                @ 08001D04  = 0x04000074
.Llit08001D08:
	.word	mcInstTable                    @ 08001D08  = 0x08091F94
.Llit08001D0C:
	.word	REG_SOUND4CNT_L                @ 08001D0C  = 0x04000078
.Llit08001D10:
	.word	0xFFFF8000                     @ 08001D10
.Llit08001D14:
	.word	REG_SOUND4CNT_H                @ 08001D14  = 0x0400007C
.Llit08001D18:
	.word	mcStepTable                    @ 08001D18  = 0x0800FFE0
.Llit08001D1C:
	.word	mcSmpInstTable                 @ 08001D1C  = 0x0808233C
@ --------------------------------------------------------------------------
@ mcSoundInit  (0x08001D20)
@   Reset hardware and driver state; copy the mixers to IWRAM
@       mcChan[0..7].active = 0; mcTempo = 0x100; mcTempoAcc = 0; mcMasterPan = 7; mcPaused = 0
@       wave RAM (both banks) = FF x 8, 00 x 8
@       SOUNDCNT_L = 0xFF0E   (constant; E.T. computed 0xFF77.  Overwritten by the first SEQ_PAN)
@       SOUNDCNT_X = 0x8F; SOUNDCNT_H = 0xFB0E; SOUND3CNT_L = 0xC0; SOUND1CNT_L = 8
@       PSG SFX slots, mcSfxPending[], mcSfxLoop[], mcSfxPtr[] = 0
@       DMA3: mcMixMusic (ROM) -> IWRAM_mcMixMusic, 0x258 words  (CNT 0x84000258)
@       DMA3: mcSfxMix   (ROM) -> IWRAM_mcSfxMix,   0x78 words   (CNT 0x84000078; source given as
@             mcSfxMix|1, the DMA ignores bit 0)
@       mcFadeLevel = 7; mcFading = 0
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcSoundInit
mcSoundInit:
	push	{r4, r5, r6, r7, lr}                  @ 08001D20
	mov	r7, r9                                 @ 08001D22
	mov	r6, r8                                 @ 08001D24
	push	{r6, r7}                              @ 08001D26
	ldr	r2, .Llit08001E38                      @ 08001D28  =mcChan
	movs	r1, #0                                @ 08001D2A
	str	r1, [r2]                               @ 08001D2C
	str	r1, [r2, #0x48]                        @ 08001D2E
	adds	r0, r2, #0                            @ 08001D30
	adds	r0, #0x90                             @ 08001D32
	str	r1, [r0]                               @ 08001D34
	adds	r0, #0x48                             @ 08001D36
	str	r1, [r0]                               @ 08001D38
	movs	r3, #0x90                             @ 08001D3A
	lsls	r3, r3, #1                            @ 08001D3C
	adds	r0, r2, r3                            @ 08001D3E
	str	r1, [r0]                               @ 08001D40
	adds	r3, #0x48                             @ 08001D42
	adds	r0, r2, r3                            @ 08001D44
	str	r1, [r0]                               @ 08001D46
	adds	r3, #0x48                             @ 08001D48
	adds	r0, r2, r3                            @ 08001D4A
	str	r1, [r0]                               @ 08001D4C
	adds	r3, #0x48                             @ 08001D4E
	adds	r0, r2, r3                            @ 08001D50
	str	r1, [r0]                               @ 08001D52
	ldr	r2, .Llit08001E3C                      @ 08001D54  =mcTempo
	movs	r0, #0x80                             @ 08001D56
	lsls	r0, r0, #1                            @ 08001D58
	str	r0, [r2]                               @ 08001D5A
	ldr	r0, .Llit08001E40                      @ 08001D5C  =mcTempoAcc
	str	r1, [r0]                               @ 08001D5E
	ldr	r2, .Llit08001E44                      @ 08001D60  =mcMasterPan
	movs	r0, #7                                @ 08001D62
	str	r0, [r2]                               @ 08001D64
	ldr	r0, .Llit08001E48                      @ 08001D66  =mcPaused
	str	r1, [r0]                               @ 08001D68
	ldr	r1, .Llit08001E4C                      @ 08001D6A  =REG_WAVE_RAM
	ldr	r3, .Llit08001E50                      @ 08001D6C  =mcPsgSfx
	ldr	r5, .Llit08001E54                      @ 08001D6E  =mcMixMusic
	ldr	r6, .Llit08001E58                      @ 08001D70  =IWRAM_mcMixMusic
	ldr	r7, .Llit08001E5C                      @ 08001D72  =mcSfxMix+1
	ldr	r0, .Llit08001E60                      @ 08001D74  =IWRAM_mcSfxMix
	mov	r12, r0                                @ 08001D76
	ldr	r2, .Llit08001E64                      @ 08001D78  =mcFadeLevel
	mov	r8, r2                                 @ 08001D7A
	ldr	r0, .Llit08001E68                      @ 08001D7C  =mcFading
	mov	r9, r0                                 @ 08001D7E
	ldr	r0, .Llit08001E6C                      @ 08001D80  =0xFFFF
	adds	r2, r0, #0                            @ 08001D82
	adds	r0, r1, #6                            @ 08001D84
.L08001D86:
	strh	r2, [r0]                              @ 08001D86
	subs	r0, #2                                @ 08001D88
	cmp	r0, r1                                 @ 08001D8A
	bge	.L08001D86                             @ 08001D8C
	movs	r2, #0                                @ 08001D8E
	adds	r0, r1, #0                            @ 08001D90
	adds	r0, #8                                @ 08001D92
	movs	r1, #3                                @ 08001D94
.L08001D96:
	strh	r2, [r0]                              @ 08001D96
	adds	r0, #2                                @ 08001D98
	subs	r1, #1                                @ 08001D9A
	cmp	r1, #0                                 @ 08001D9C
	bge	.L08001D96                             @ 08001D9E
	ldr	r1, .Llit08001E70                      @ 08001DA0  =REG_SOUNDCNT_L
	ldr	r2, .Llit08001E74                      @ 08001DA2  =0xFF0E
	adds	r0, r2, #0                            @ 08001DA4
	strh	r0, [r1]                              @ 08001DA6
	adds	r1, #4                                @ 08001DA8
	movs	r0, #0x8f                             @ 08001DAA
	strh	r0, [r1]                              @ 08001DAC
	subs	r1, #2                                @ 08001DAE
	ldr	r2, .Llit08001E78                      @ 08001DB0  =0xFB0E
	adds	r0, r2, #0                            @ 08001DB2
	strh	r0, [r1]                              @ 08001DB4
	subs	r1, #0x12                             @ 08001DB6
	movs	r0, #0xc0                             @ 08001DB8
	strh	r0, [r1]                              @ 08001DBA
	adds	r1, #0x20                             @ 08001DBC
	ldr	r0, .Llit08001E6C                      @ 08001DBE  =0xFFFF
	adds	r2, r0, #0                            @ 08001DC0
	adds	r0, r1, #6                            @ 08001DC2
.L08001DC4:
	strh	r2, [r0]                              @ 08001DC4
	subs	r0, #2                                @ 08001DC6
	cmp	r0, r1                                 @ 08001DC8
	bge	.L08001DC4                             @ 08001DCA
	movs	r2, #0                                @ 08001DCC
	adds	r0, r1, #0                            @ 08001DCE
	adds	r0, #8                                @ 08001DD0
	movs	r1, #3                                @ 08001DD2
.L08001DD4:
	strh	r2, [r0]                              @ 08001DD4
	adds	r0, #2                                @ 08001DD6
	subs	r1, #1                                @ 08001DD8
	cmp	r1, #0                                 @ 08001DDA
	bge	.L08001DD4                             @ 08001DDC
	movs	r1, #8                                @ 08001DDE
	ldr	r0, .Llit08001E7C                      @ 08001DE0  =REG_SOUND1CNT_L
	strh	r1, [r0]                              @ 08001DE2
	movs	r0, #0                                @ 08001DE4
	str	r0, [r3]                               @ 08001DE6
	str	r0, [r3, #0xc]                         @ 08001DE8
	str	r0, [r3, #0x18]                        @ 08001DEA
	str	r0, [r3, #0x24]                        @ 08001DEC
	str	r0, [r3, #0x30]                        @ 08001DEE
	str	r0, [r3, #0x3c]                        @ 08001DF0
	ldr	r4, .Llit08001E80                      @ 08001DF2  =mcSfxLoop
	ldr	r3, .Llit08001E84                      @ 08001DF4  =mcSfxPending
	ldr	r2, .Llit08001E88                      @ 08001DF6  =mcSfxPtr
	movs	r1, #1                                @ 08001DF8
.L08001DFA:
	stm	r2!, {r0}                              @ 08001DFA
	stm	r3!, {r0}                              @ 08001DFC
	stm	r4!, {r0}                              @ 08001DFE
	subs	r1, #1                                @ 08001E00
	cmp	r1, #0                                 @ 08001E02
	bge	.L08001DFA                             @ 08001E04
	ldr	r0, .Llit08001E8C                      @ 08001E06  =REG_DMA3SAD
	str	r5, [r0]                               @ 08001E08
	str	r6, [r0, #4]                           @ 08001E0A
	ldr	r1, .Llit08001E90                      @ 08001E0C  =0x84000258
	str	r1, [r0, #8]                           @ 08001E0E
	ldr	r1, [r0, #8]                           @ 08001E10
	str	r7, [r0]                               @ 08001E12
	mov	r1, r12                                @ 08001E14
	str	r1, [r0, #4]                           @ 08001E16
	ldr	r1, .Llit08001E94                      @ 08001E18  =0x84000078
	str	r1, [r0, #8]                           @ 08001E1A
	ldr	r0, [r0, #8]                           @ 08001E1C
	movs	r0, #7                                @ 08001E1E
	mov	r2, r8                                 @ 08001E20
	str	r0, [r2]                               @ 08001E22
	movs	r0, #0                                @ 08001E24
	mov	r3, r9                                 @ 08001E26
	str	r0, [r3]                               @ 08001E28
	pop	{r3, r4}                               @ 08001E2A
	mov	r8, r3                                 @ 08001E2C
	mov	r9, r4                                 @ 08001E2E
	pop	{r4, r5, r6, r7}                       @ 08001E30
	pop	{r0}                                   @ 08001E32
	bx	r0                                      @ 08001E34
	.hword	0x0000                          @ 08001E36  (padding)
.Llit08001E38:
	.word	mcChan                         @ 08001E38  = 0x030055C0
.Llit08001E3C:
	.word	mcTempo                        @ 08001E3C  = 0x03005254
.Llit08001E40:
	.word	mcTempoAcc                     @ 08001E40  = 0x030053C4
.Llit08001E44:
	.word	mcMasterPan                    @ 08001E44  = 0x030053C8
.Llit08001E48:
	.word	mcPaused                       @ 08001E48  = 0x030053C0
.Llit08001E4C:
	.word	REG_WAVE_RAM                   @ 08001E4C  = 0x04000090
.Llit08001E50:
	.word	mcPsgSfx                       @ 08001E50  = 0x030053E0
.Llit08001E54:
	.word	mcMixMusic                     @ 08001E54  = 0x08002078
.Llit08001E58:
	.word	IWRAM_mcMixMusic               @ 08001E58  = 0x030048F0
.Llit08001E5C:
	.word	mcSfxMix+1                     @ 08001E5C  = 0x08000C61
.Llit08001E60:
	.word	IWRAM_mcSfxMix                 @ 08001E60  = 0x030046F0
.Llit08001E64:
	.word	mcFadeLevel                    @ 08001E64  = 0x03005800
.Llit08001E68:
	.word	mcFading                       @ 08001E68  = 0x03005804
.Llit08001E6C:
	.word	0x0000FFFF                     @ 08001E6C
.Llit08001E70:
	.word	REG_SOUNDCNT_L                 @ 08001E70  = 0x04000080
.Llit08001E74:
	.word	0x0000FF0E                     @ 08001E74
.Llit08001E78:
	.word	0x0000FB0E                     @ 08001E78
.Llit08001E7C:
	.word	REG_SOUND1CNT_L                @ 08001E7C  = 0x04000060
.Llit08001E80:
	.word	mcSfxLoop                      @ 08001E80  = 0x03005438
.Llit08001E84:
	.word	mcSfxPending                   @ 08001E84  = 0x03005428
.Llit08001E88:
	.word	mcSfxPtr                       @ 08001E88  = 0x030048D8
.Llit08001E8C:
	.word	REG_DMA3SAD                    @ 08001E8C  = 0x040000D4
.Llit08001E90:
	.word	0x84000258                     @ 08001E90
.Llit08001E94:
	.word	0x84000078                     @ 08001E94
@ --------------------------------------------------------------------------
@ mcSfxStopById  (0x08001E98)
@   void mcSfxStopById(int id): stop any SFX voice playing table entry id (mcSfxPtr = 0)
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcSfxStopById
mcSfxStopById:
	push	{r4, r5, lr}                          @ 08001E98
	adds	r4, r0, #0                            @ 08001E9A
	movs	r5, #0                                @ 08001E9C
	ldr	r3, .Llit08001EBC                      @ 08001E9E  =mcSfxPtr
	ldr	r2, .Llit08001EC0                      @ 08001EA0  =mcSfxId
	movs	r1, #1                                @ 08001EA2
.L08001EA4:
	ldr	r0, [r2]                               @ 08001EA4
	cmp	r0, r4                                 @ 08001EA6
	bne	.L08001EAC                             @ 08001EA8
	str	r5, [r3]                               @ 08001EAA
.L08001EAC:
	adds	r3, #4                                @ 08001EAC
	adds	r2, #4                                @ 08001EAE
	subs	r1, #1                                @ 08001EB0
	cmp	r1, #0                                 @ 08001EB2
	bge	.L08001EA4                             @ 08001EB4
	pop	{r4, r5}                               @ 08001EB6
	pop	{r0}                                   @ 08001EB8
	bx	r0                                      @ 08001EBA
.Llit08001EBC:
	.word	mcSfxPtr                       @ 08001EBC  = 0x030048D8
.Llit08001EC0:
	.word	mcSfxId                        @ 08001EC0  = 0x03005820
@ --------------------------------------------------------------------------
@ mcFadeOut  (0x08001EC4)
@   Start the music fade-out: mcFading = 1; mcFadeCounter = 0 (NO CALLERS)
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcFadeOut
mcFadeOut:
	ldr	r1, .Llit08001ED4                      @ 08001EC4  =mcFading
	movs	r0, #1                                @ 08001EC6
	str	r0, [r1]                               @ 08001EC8
	ldr	r1, .Llit08001ED8                      @ 08001ECA  =mcFadeCounter
	movs	r0, #0                                @ 08001ECC
	str	r0, [r1]                               @ 08001ECE
	bx	lr                                      @ 08001ED0
	.hword	0x0000                          @ 08001ED2  (padding)
.Llit08001ED4:
	.word	mcFading                       @ 08001ED4  = 0x03005804
.Llit08001ED8:
	.word	mcFadeCounter                  @ 08001ED8  = 0x03005250
@ --------------------------------------------------------------------------
@ mcPlayPsgSfx  (0x08001EDC)
@   PSG register-script SFX, unchanged from E.T. (NO CALLERS)
@       for each of the 4 entries in mcPsgSfxMap[n] != 0xFF: script = mcPsgSfxScripts[x];
@       slot[script->channel] = {script+2, -5, 0}; mcChan[channel].owned = 0
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcPlayPsgSfx
mcPlayPsgSfx:
	push	{r4, r5, r6, r7, lr}                  @ 08001EDC
	mov	r7, r10                                @ 08001EDE
	mov	r6, r9                                 @ 08001EE0
	mov	r5, r8                                 @ 08001EE2
	push	{r5, r6, r7}                          @ 08001EE4
	adds	r5, r0, #0                            @ 08001EE6
	ldr	r0, .Llit08001F50                      @ 08001EE8  =mcPsgSfxCur
	str	r5, [r0]                               @ 08001EEA
	movs	r4, #0                                @ 08001EEC
	ldr	r0, .Llit08001F54                      @ 08001EEE  =mcPsgSfxMap
	mov	r10, r0                                @ 08001EF0
	ldr	r0, .Llit08001F58                      @ 08001EF2  =mcPsgSfxScripts
	mov	r9, r0                                 @ 08001EF4
	ldr	r6, .Llit08001F5C                      @ 08001EF6  =mcPsgSfx
	movs	r0, #8                                @ 08001EF8
	adds	r0, r0, r6                            @ 08001EFA
	mov	r8, r0                                 @ 08001EFC
	movs	r7, #0                                @ 08001EFE
	ldr	r0, .Llit08001F60                      @ 08001F00  =mcChan+CH_owned
	mov	r12, r0                                @ 08001F02
.L08001F04:
	lsls	r0, r5, #2                            @ 08001F04
	adds	r0, r4, r0                            @ 08001F06
	add	r0, r10                                @ 08001F08
	ldrb	r0, [r0]                              @ 08001F0A
	cmp	r0, #0xff                              @ 08001F0C
	beq	.L08001F3C                             @ 08001F0E
	lsls	r0, r0, #2                            @ 08001F10
	add	r0, r9                                 @ 08001F12
	ldr	r2, [r0]                               @ 08001F14
	ldrh	r3, [r2]                              @ 08001F16
	adds	r2, #2                                @ 08001F18
	lsls	r0, r3, #1                            @ 08001F1A
	adds	r0, r0, r3                            @ 08001F1C
	lsls	r0, r0, #2                            @ 08001F1E
	adds	r1, r0, r6                            @ 08001F20
	str	r2, [r1]                               @ 08001F22
	adds	r1, r6, #4                            @ 08001F24
	adds	r1, r0, r1                            @ 08001F26
	movs	r2, #5                                @ 08001F28
	rsbs	r2, r2, #0                            @ 08001F2A
	str	r2, [r1]                               @ 08001F2C
	add	r0, r8                                 @ 08001F2E
	str	r7, [r0]                               @ 08001F30
	lsls	r0, r3, #3                            @ 08001F32
	adds	r0, r0, r3                            @ 08001F34
	lsls	r0, r0, #3                            @ 08001F36
	add	r0, r12                                @ 08001F38
	str	r7, [r0]                               @ 08001F3A
.L08001F3C:
	adds	r4, #1                                @ 08001F3C
	cmp	r4, #3                                 @ 08001F3E
	ble	.L08001F04                             @ 08001F40
	pop	{r3, r4, r5}                           @ 08001F42
	mov	r8, r3                                 @ 08001F44
	mov	r9, r4                                 @ 08001F46
	mov	r10, r5                                @ 08001F48
	pop	{r4, r5, r6, r7}                       @ 08001F4A
	pop	{r0}                                   @ 08001F4C
	bx	r0                                      @ 08001F4E
.Llit08001F50:
	.word	mcPsgSfxCur                    @ 08001F50  = 0x030046D0
.Llit08001F54:
	.word	mcPsgSfxMap                    @ 08001F54  = 0x0808253C
.Llit08001F58:
	.word	mcPsgSfxScripts                @ 08001F58  = 0x080826BC
.Llit08001F5C:
	.word	mcPsgSfx                       @ 08001F5C  = 0x030053E0
.Llit08001F60:
	.word	mcChan+CH_owned                @ 08001F60  = 0x030055C4
@ --------------------------------------------------------------------------
@ mcUnpauseAndStopSfx  (0x08001F64)
@   (name inferred; NO CALLERS)
@       if (mcPaused) { mcFadeLevel = mcSaveFadeLevel; mcFading = mcSaveFading; mcPaused = 0 }
@       mcSfxPtr[0] = mcSfxPtr[1] = 0
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcUnpauseAndStopSfx
mcUnpauseAndStopSfx:
	ldr	r2, .Llit08001F8C                      @ 08001F64  =mcPaused
	ldr	r0, [r2]                               @ 08001F66
	cmp	r0, #0                                 @ 08001F68
	beq	.L08001F80                             @ 08001F6A
	ldr	r1, .Llit08001F90                      @ 08001F6C  =mcFadeLevel
	ldr	r0, .Llit08001F94                      @ 08001F6E  =mcSaveFadeLevel
	ldr	r0, [r0]                               @ 08001F70
	str	r0, [r1]                               @ 08001F72
	ldr	r1, .Llit08001F98                      @ 08001F74  =mcFading
	ldr	r0, .Llit08001F9C                      @ 08001F76  =mcSaveFading
	ldr	r0, [r0]                               @ 08001F78
	str	r0, [r1]                               @ 08001F7A
	movs	r0, #0                                @ 08001F7C
	str	r0, [r2]                               @ 08001F7E
.L08001F80:
	ldr	r1, .Llit08001FA0                      @ 08001F80  =mcSfxPtr
	movs	r0, #0                                @ 08001F82
	str	r0, [r1]                               @ 08001F84
	str	r0, [r1, #4]                           @ 08001F86
	bx	lr                                      @ 08001F88
	.hword	0x0000                          @ 08001F8A  (padding)
.Llit08001F8C:
	.word	mcPaused                       @ 08001F8C  = 0x030053C0
.Llit08001F90:
	.word	mcFadeLevel                    @ 08001F90  = 0x03005800
.Llit08001F94:
	.word	mcSaveFadeLevel                @ 08001F94  = 0x03005818
.Llit08001F98:
	.word	mcFading                       @ 08001F98  = 0x03005804
.Llit08001F9C:
	.word	mcSaveFading                   @ 08001F9C  = 0x03005814
.Llit08001FA0:
	.word	mcSfxPtr                       @ 08001FA0  = 0x030048D8
@ --------------------------------------------------------------------------
@ mcDsSfxStart  (0x08001FA4)
@   void mcDsSfxStart(int id, int v): start SFX table entry id on voice v (0/1)
@       mcSfxId[v] = id; mcSfxPtr[v] = mcSfxTable[id].pcm; mcSfxFrames[v] = .frames; mcSfxLoop[v] = .loop
@       mcSfxPending[v] = 1; mcSfxActive[v] = 1
@       SOUNDCNT_H |= 4      (DS A 100 %: left over from E.T.'s per-slot volume; the SFX play on FIFO B)
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcDsSfxStart
mcDsSfxStart:
	push	{r4, lr}                              @ 08001FA4
	ldr	r2, .Llit08001FF8                      @ 08001FA6  =mcSfxId
	lsls	r1, r1, #2                            @ 08001FA8
	adds	r2, r1, r2                            @ 08001FAA
	str	r0, [r2]                               @ 08001FAC
	ldr	r3, .Llit08001FFC                      @ 08001FAE  =mcSfxPtr
	adds	r3, r1, r3                            @ 08001FB0
	ldr	r4, .Llit08002000                      @ 08001FB2  =mcSfxTable
	lsls	r0, r0, #4                            @ 08001FB4
	adds	r2, r0, r4                            @ 08001FB6
	ldr	r2, [r2]                               @ 08001FB8
	str	r2, [r3]                               @ 08001FBA
	ldr	r3, .Llit08002004                      @ 08001FBC  =mcSfxFrames
	adds	r3, r1, r3                            @ 08001FBE
	adds	r2, r4, #4                            @ 08001FC0
	adds	r2, r0, r2                            @ 08001FC2
	ldr	r2, [r2]                               @ 08001FC4
	subs	r2, #1                                @ 08001FC6
	str	r2, [r3]                               @ 08001FC8
	ldr	r2, .Llit08002008                      @ 08001FCA  =mcSfxLoop
	adds	r2, r1, r2                            @ 08001FCC
	adds	r4, #8                                @ 08001FCE
	adds	r0, r0, r4                            @ 08001FD0
	ldr	r0, [r0]                               @ 08001FD2
	str	r0, [r2]                               @ 08001FD4
	ldr	r0, .Llit0800200C                      @ 08001FD6  =mcSfxPending
	adds	r0, r1, r0                            @ 08001FD8
	movs	r2, #1                                @ 08001FDA
	str	r2, [r0]                               @ 08001FDC
	ldr	r0, .Llit08002010                      @ 08001FDE  =mcSfxActive
	adds	r1, r1, r0                            @ 08001FE0
	str	r2, [r1]                               @ 08001FE2
	ldr	r2, .Llit08002014                      @ 08001FE4  =REG_SOUNDCNT_H
	ldrh	r1, [r2]                              @ 08001FE6
	ldr	r0, .Llit08002018                      @ 08001FE8  =0xFFFB
	ands	r0, r1                                @ 08001FEA
	movs	r1, #4                                @ 08001FEC
	orrs	r0, r1                                @ 08001FEE
	strh	r0, [r2]                              @ 08001FF0
	pop	{r4}                                   @ 08001FF2
	pop	{r0}                                   @ 08001FF4
	bx	r0                                      @ 08001FF6
.Llit08001FF8:
	.word	mcSfxId                        @ 08001FF8  = 0x03005820
.Llit08001FFC:
	.word	mcSfxPtr                       @ 08001FFC  = 0x030048D8
.Llit08002000:
	.word	mcSfxTable                     @ 08002000  = 0x0808223C
.Llit08002004:
	.word	mcSfxFrames                    @ 08002004  = 0x030046E0
.Llit08002008:
	.word	mcSfxLoop                      @ 08002008  = 0x03005438
.Llit0800200C:
	.word	mcSfxPending                   @ 0800200C  = 0x03005428
.Llit08002010:
	.word	mcSfxActive                    @ 08002010  = 0x030055B0
.Llit08002014:
	.word	REG_SOUNDCNT_H                 @ 08002014  = 0x04000082
.Llit08002018:
	.word	0x0000FFFB                     @ 08002018
@ --------------------------------------------------------------------------
@ mcApplyFade  (0x0800201C)
@   Scale the next music buffer by mcFadeTable[mcFadeLevel] >> 8 (NO CALLERS; mcUpdate has an inline copy)
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcApplyFade
mcApplyFade:
	push	{r4, lr}                              @ 0800201C
	sub	sp, #0x24                              @ 0800201E
	mov	r1, sp                                 @ 08002020
	ldr	r0, .Llit08002068                      @ 08002022  =mcFadeTable
	ldm	r0!, {r2, r3, r4}                      @ 08002024
	stm	r1!, {r2, r3, r4}                      @ 08002026
	ldm	r0!, {r2, r3, r4}                      @ 08002028
	stm	r1!, {r2, r3, r4}                      @ 0800202A
	ldm	r0!, {r2, r3, r4}                      @ 0800202C
	stm	r1!, {r2, r3, r4}                      @ 0800202E
	ldr	r0, .Llit0800206C                      @ 08002030  =mcFadeLevel
	ldr	r0, [r0]                               @ 08002032
	lsls	r0, r0, #2                            @ 08002034
	add	r0, sp                                 @ 08002036
	ldr	r3, [r0]                               @ 08002038
	ldr	r0, .Llit08002070                      @ 0800203A  =mcBufIndex
	ldr	r0, [r0]                               @ 0800203C
	adds	r0, #1                                @ 0800203E
	movs	r1, #1                                @ 08002040
	ands	r0, r1                                @ 08002042
	ldr	r2, .Llit08002074                      @ 08002044  =mcMusicBuf
	movs	r1, #0xb0                             @ 08002046
	muls	r0, r1, r0                            @ 08002048
	adds	r1, r0, r2                            @ 0800204A
	movs	r2, #0xaf                             @ 0800204C
.L0800204E:
	movs	r0, #0                                @ 0800204E
	ldrsb	r0, [r1, r0]                         @ 08002050
	muls	r0, r3, r0                            @ 08002052
	asrs	r0, r0, #8                            @ 08002054
	strb	r0, [r1]                              @ 08002056
	adds	r1, #1                                @ 08002058
	subs	r2, #1                                @ 0800205A
	cmp	r2, #0                                 @ 0800205C
	bge	.L0800204E                             @ 0800205E
	add	sp, #0x24                              @ 08002060
	pop	{r4}                                   @ 08002062
	pop	{r0}                                   @ 08002064
	bx	r0                                      @ 08002066
.Llit08002068:
	.word	mcFadeTable                    @ 08002068  = 0x08010160
.Llit0800206C:
	.word	mcFadeLevel                    @ 0800206C  = 0x03005800
.Llit08002070:
	.word	mcBufIndex                     @ 08002070  = 0x030048E8
.Llit08002074:
	.word	mcMusicBuf                     @ 08002074  = 0x03005260
@ --------------------------------------------------------------------------
@ mcMixMusic  (0x08002078)
@   ARM.  Resample and mix the 4 PCM channels (firstCh .. firstCh+3, always 4) into the next
@   FIFO A buffer.  mcSoundInit copies this code to IWRAM_mcMixMusic; mcUpdate calls it there via
@   mcMixerFuncs[0] (_call_via_r1).
@     void mcMixMusic(int firstCh)
@       for each channel c:   (fields reused: +0x30 step, +0x38 pos, +0x3C end, all 18.14)
@         if (c->note == 0x60 || !c->seqPtr || c->pos == -1) { src = silence (pcm_ silence block); step = 0 }
@         else src = mcSmpInstTable[c->inst].pcm
@       buf = mcMusicBuf[(mcBufIndex + 1) & 1]
@       for i in 0..175, 2 samples per iteration:
@         buf[i] = (s0[pos0>>14] + s1[pos1>>14] + s2[pos2>>14] + s3[pos3>>14]) >> 2    (ldrsb)
@         posN += stepN
@       for each channel: if ((u32)pos >= end) pos = (mcSmpInstTable[inst].flag == 1) ? -1 : 0
@     The end test runs once per frame, so a one-shot sample reads up to 176*step bytes past its end
@     (comparison doc §4.3).
@ --------------------------------------------------------------------------
	.arm
	.balign 4
	.global mcMixMusic
mcMixMusic:
	mov	r12, sp                                @ 08002078
	push	{r4, r5, r6, r7, r8, r9, r10, r11, r12, lr, pc} @ 0800207C
	sub	r11, r12, #4                           @ 08002080
	sub	sp, sp, #0x3c                          @ 08002084
	str	r0, [r11, #-0x2c]                      @ 08002088
	ldr	r5, .Llit08002454                      @ 0800208C  =mcChan
	add	r3, r0, r0, lsl #3                     @ 08002090
	lsl	r9, r3, #3                             @ 08002094
	add	r2, r5, #0x38                          @ 08002098
	add	r3, r5, #0x30                          @ 0800209C
	ldr	r10, [r2, r9]                          @ 080020A0
	add	r12, r0, #1                            @ 080020A4
	ldr	r1, [r3, r9]                           @ 080020A8
	add	r12, r12, r12, lsl #3                  @ 080020AC
	str	r1, [r11, #-0x40]                      @ 080020B0
	lsl	r12, r12, #3                           @ 080020B4
	ldr	r8, [r2, r12]                          @ 080020B8
	ldr	lr, [r3, r12]                          @ 080020BC
	add	r0, r0, #2                             @ 080020C0
	str	lr, [r11, #-0x44]                      @ 080020C4
	add	r0, r0, r0, lsl #3                     @ 080020C8
	ldr	lr, [r11, #-0x2c]                      @ 080020CC
	lsl	r0, r0, #3                             @ 080020D0
	ldr	r1, [r3, r0]                           @ 080020D4
	ldr	r7, [r2, r0]                           @ 080020D8
	str	r1, [r11, #-0x48]                      @ 080020DC
	ldr	r4, .Llit08002458                      @ 080020E0  =mcSmpInstTable
	add	r1, lr, #3                             @ 080020E4
	add	r1, r1, r1, lsl #3                     @ 080020E8
	lsl	r1, r1, #3                             @ 080020EC
	ldr	r3, [r3, r1]                           @ 080020F0
	ldr	r6, [r2, r1]                           @ 080020F4
	str	r3, [r11, #-0x4c]                      @ 080020F8
	add	lr, r5, #0x1c                          @ 080020FC
	ldr	r3, [lr, r9]                           @ 08002100
	ldr	r3, [r4, r3, lsl #4]                   @ 08002104
	str	r3, [r11, #-0x30]                      @ 08002108
	ldr	r2, [lr, r12]                          @ 0800210C
	ldr	r2, [r4, r2, lsl #4]                   @ 08002110
	str	r2, [r11, #-0x34]                      @ 08002114
	ldr	r3, [lr, r0]                           @ 08002118
	ldr	r3, [r4, r3, lsl #4]                   @ 0800211C
	str	r3, [r11, #-0x38]                      @ 08002120
	ldr	r0, [lr, r1]                           @ 08002124
	add	r2, r5, #0x14                          @ 08002128
	ldr	r3, [r2, r9]                           @ 0800212C
	ldr	r0, [r4, r0, lsl #4]                   @ 08002130
	str	r0, [r11, #-0x3c]                      @ 08002134
	cmp	r3, #0x60                              @ 08002138
	beq	.L08002154                             @ 0800213C
	add	r3, r5, #0x20                          @ 08002140
	ldr	r2, [r3, r9]                           @ 08002144
	cmn	r10, #1                                @ 08002148
	cmpne	r2, #0                               @ 0800214C
	bne	.L08002168                             @ 08002150
.L08002154:
	mov	r1, #0                                 @ 08002154
	str	r1, [r11, #-0x40]                      @ 08002158
	ldr	r2, .Llit0800245C                      @ 0800215C  =pcm_080128BC+4
	mvn	r10, #0                                @ 08002160
	str	r2, [r11, #-0x30]                      @ 08002164
.L08002168:
	ldr	r3, [r11, #-0x2c]                      @ 08002168
	ldr	r12, .Llit08002454                     @ 0800216C  =mcChan
	add	r1, r3, #1                             @ 08002170
	add	r3, r1, r1, lsl #3                     @ 08002174
	lsl	r0, r3, #3                             @ 08002178
	add	r2, r12, #0x14                         @ 0800217C
	ldr	r3, [r2, r0]                           @ 08002180
	str	r1, [r11, #-0x54]                      @ 08002184
	cmp	r3, #0x60                              @ 08002188
	beq	.L080021A4                             @ 0800218C
	add	r3, r12, #0x20                         @ 08002190
	ldr	r2, [r3, r0]                           @ 08002194
	cmn	r8, #1                                 @ 08002198
	cmpne	r2, #0                               @ 0800219C
	bne	.L080021B8                             @ 080021A0
.L080021A4:
	mov	lr, #0                                 @ 080021A4
	str	lr, [r11, #-0x44]                      @ 080021A8
	ldr	r1, .Llit0800245C                      @ 080021AC  =pcm_080128BC+4
	mvn	r8, #0                                 @ 080021B0
	str	r1, [r11, #-0x34]                      @ 080021B4
.L080021B8:
	ldr	r2, [r11, #-0x2c]                      @ 080021B8
	add	r1, r2, #2                             @ 080021BC
	add	r3, r1, r1, lsl #3                     @ 080021C0
	lsl	r0, r3, #3                             @ 080021C4
	ldr	r3, .Llit08002454                      @ 080021C8  =mcChan
	add	r2, r3, #0x14                          @ 080021CC
	ldr	r3, [r2, r0]                           @ 080021D0
	str	r1, [r11, #-0x58]                      @ 080021D4
	cmp	r3, #0x60                              @ 080021D8
	beq	.L080021F8                             @ 080021DC
	ldr	r12, .Llit08002454                     @ 080021E0  =mcChan
	add	r3, r12, #0x20                         @ 080021E4
	ldr	r2, [r3, r0]                           @ 080021E8
	cmn	r7, #1                                 @ 080021EC
	cmpne	r2, #0                               @ 080021F0
	bne	.L0800220C                             @ 080021F4
.L080021F8:
	mov	lr, #0                                 @ 080021F8
	str	lr, [r11, #-0x48]                      @ 080021FC
	ldr	r1, .Llit0800245C                      @ 08002200  =pcm_080128BC+4
	mvn	r7, #0                                 @ 08002204
	str	r1, [r11, #-0x38]                      @ 08002208
.L0800220C:
	ldr	r2, [r11, #-0x2c]                      @ 0800220C
	add	r1, r2, #3                             @ 08002210
	add	r3, r1, r1, lsl #3                     @ 08002214
	lsl	r0, r3, #3                             @ 08002218
	ldr	r3, .Llit08002454                      @ 0800221C  =mcChan
	add	r2, r3, #0x14                          @ 08002220
	ldr	r3, [r2, r0]                           @ 08002224
	str	r1, [r11, #-0x5c]                      @ 08002228
	cmp	r3, #0x60                              @ 0800222C
	beq	.L0800224C                             @ 08002230
	ldr	r12, .Llit08002454                     @ 08002234  =mcChan
	add	r3, r12, #0x20                         @ 08002238
	ldr	r2, [r3, r0]                           @ 0800223C
	cmn	r6, #1                                 @ 08002240  pos == -1 or seqPtr == 0 (or note == 0x60 above) ->
	cmpne	r2, #0                               @ 08002244
	bne	.L08002260                             @ 08002248
.L0800224C:
	mov	lr, #0                                 @ 0800224C  silent: step = 0, source = silence block, pos = -1
	str	lr, [r11, #-0x4c]                      @ 08002250
	ldr	r1, .Llit0800245C                      @ 08002254  =pcm_080128BC+4
	mvn	r6, #0                                 @ 08002258
	str	r1, [r11, #-0x3c]                      @ 0800225C
.L08002260:
	ldr	r2, .Llit08002460                      @ 08002260  =mcBufIndex
	ldr	r3, [r2]                               @ 08002264
	mov	r4, #0                                 @ 08002268
	ldr	r5, .Llit08002464                      @ 0800226C  =mcMusicBuf
	add	r3, r3, #1                             @ 08002270
	and	r3, r3, #1                             @ 08002274
	cmp	r3, r4                                 @ 08002278
	movne	r9, #0xb0                            @ 0800227C
	moveq	r9, r4                               @ 08002280
	ldr	r2, [r11, #-0x2c]                      @ 08002284
	add	r3, r9, #1                             @ 08002288
	str	r3, [r11, #-0x50]                      @ 0800228C
	lsl	r2, r2, #3                             @ 08002290
	str	r2, [r11, #-0x60]                      @ 08002294
.L08002298:
	ldr	lr, [r11, #-0x30]                      @ 08002298  mix loop: 2 output samples per iteration, 88 iterations
	ldr	r2, [r11, #-0x50]                      @ 0800229C
	ldr	r3, [r11, #-0x3c]                      @ 080022A0
	add	r1, lr, r10, asr #14                   @ 080022A4  s0 = src0[pos0 >> 14]  (signed 8-bit)
	ldrsb	r1, [r1]                             @ 080022A8
	add	r2, r4, r2                             @ 080022AC
	ldr	lr, [r11, #-0x38]                      @ 080022B0
	add	r0, r3, r6, asr #14                    @ 080022B4
	str	r2, [r11, #-0x64]                      @ 080022B8
	add	r3, lr, r7, asr #14                    @ 080022BC
	ldr	lr, [r11, #-0x34]                      @ 080022C0
	ldrsb	r0, [r0]                             @ 080022C4
	add	r12, r4, r9                            @ 080022C8
	ldrsb	r3, [r3]                             @ 080022CC
	add	r2, lr, r8, asr #14                    @ 080022D0
	ldrsb	r2, [r2]                             @ 080022D4
	add	r1, r1, r0                             @ 080022D8
	add	r3, r3, r2                             @ 080022DC
	add	r1, r1, r3                             @ 080022E0
	asr	r1, r1, #2                             @ 080022E4  (s0 + s1 + s2 + s3) >> 2
	strb	r1, [r5, r12]                         @ 080022E8
	ldr	r1, [r11, #-0x40]                      @ 080022EC
	ldr	r2, [r11, #-0x30]                      @ 080022F0
	ldr	r3, [r11, #-0x4c]                      @ 080022F4
	ldr	r12, [r11, #-0x3c]                     @ 080022F8
	ldr	lr, [r11, #-0x48]                      @ 080022FC
	add	r10, r10, r1                           @ 08002300
	add	r1, r2, r10, asr #14                   @ 08002304
	add	r6, r6, r3                             @ 08002308
	ldrsb	r1, [r1]                             @ 0800230C
	add	r0, r12, r6, asr #14                   @ 08002310
	ldrsb	r0, [r0]                             @ 08002314
	add	r4, r4, #2                             @ 08002318
	ldr	r2, [r11, #-0x38]                      @ 0800231C
	cmp	r4, #0xaf                              @ 08002320
	ldr	r12, [r11, #-0x44]                     @ 08002324
	add	r7, r7, lr                             @ 08002328
	ldr	lr, [r11, #-0x34]                      @ 0800232C
	add	r3, r2, r7, asr #14                    @ 08002330
	add	r8, r8, r12                            @ 08002334
	add	r2, lr, r8, asr #14                    @ 08002338
	ldrsb	r3, [r3]                             @ 0800233C
	add	r1, r1, r0                             @ 08002340
	ldrsb	r2, [r2]                             @ 08002344
	add	r8, r8, r12                            @ 08002348
	ldr	r12, [r11, #-0x64]                     @ 0800234C
	add	r3, r3, r2                             @ 08002350
	ldr	r2, [r11, #-0x40]                      @ 08002354
	add	r1, r1, r3                             @ 08002358
	ldr	r3, [r11, #-0x48]                      @ 0800235C
	asr	r1, r1, #2                             @ 08002360
	strb	r1, [r5, r12]                         @ 08002364
	add	r10, r10, r2                           @ 08002368
	ldr	lr, [r11, #-0x4c]                      @ 0800236C
	add	r7, r7, r3                             @ 08002370
	add	r6, r6, lr                             @ 08002374
	ble	.L08002298                             @ 08002378
	ldr	r1, [r11, #-0x60]                      @ 0800237C
	ldr	r2, [r11, #-0x2c]                      @ 08002380
	ldr	r4, .Llit08002454                      @ 08002384  =mcChan
	add	r3, r1, r2                             @ 08002388
	lsl	r12, r3, #3                            @ 0800238C
	add	r5, r4, #0x3c                          @ 08002390
	ldr	r3, [r5, r12]                          @ 08002394
	cmp	r10, r3                                @ 08002398  end test once per frame, after 176 samples: one-shots overrun by up to 176*step bytes
	blo	.L080023C0                             @ 0800239C
	add	r3, r4, #0x1c                          @ 080023A0
	ldr	r1, [r3, r12]                          @ 080023A4
	ldr	r3, .Llit08002458                      @ 080023A8  =mcSmpInstTable
	add	r2, r3, #8                             @ 080023AC
	ldr	r3, [r2, r1, lsl #4]                   @ 080023B0  mcSmpInstTable[inst].flag
	cmp	r3, #1                                 @ 080023B4
	movne	r10, #0                              @ 080023B8  flag == 1: pos = -1 (one-shot); else pos = 0 (loop from the start)
	mvneq	r10, #0                              @ 080023BC
.L080023C0:
	ldr	lr, [r11, #-0x54]                      @ 080023C0
	add	r3, lr, lr, lsl #3                     @ 080023C4
	lsl	r9, r3, #3                             @ 080023C8
	ldr	r2, [r5, r9]                           @ 080023CC
	cmp	r8, r2                                 @ 080023D0
	blo	.L080023F8                             @ 080023D4
	add	r3, r4, #0x1c                          @ 080023D8
	ldr	r1, [r3, r9]                           @ 080023DC
	ldr	r3, .Llit08002458                      @ 080023E0  =mcSmpInstTable
	add	r2, r3, #8                             @ 080023E4
	ldr	r3, [r2, r1, lsl #4]                   @ 080023E8
	cmp	r3, #1                                 @ 080023EC
	movne	r8, #0                               @ 080023F0
	mvneq	r8, #0                               @ 080023F4
.L080023F8:
	ldr	lr, [r11, #-0x58]                      @ 080023F8
	add	r3, lr, lr, lsl #3                     @ 080023FC
	lsl	r0, r3, #3                             @ 08002400
	ldr	r2, [r5, r0]                           @ 08002404
	cmp	r7, r2                                 @ 08002408
	blo	.L08002430                             @ 0800240C
	add	r3, r4, #0x1c                          @ 08002410
	ldr	r1, [r3, r0]                           @ 08002414
	ldr	r3, .Llit08002458                      @ 08002418  =mcSmpInstTable
	add	r2, r3, #8                             @ 0800241C
	ldr	r3, [r2, r1, lsl #4]                   @ 08002420
	cmp	r3, #1                                 @ 08002424
	movne	r7, #0                               @ 08002428
	mvneq	r7, #0                               @ 0800242C
.L08002430:
	ldr	lr, [r11, #-0x5c]                      @ 08002430
	add	r3, lr, lr, lsl #3                     @ 08002434
	lsl	lr, r3, #3                             @ 08002438
	ldr	r2, [r5, lr]                           @ 0800243C
	cmp	r6, r2                                 @ 08002440
	blo	.L08002480                             @ 08002444
	add	r3, r4, #0x1c                          @ 08002448
	ldr	r1, [r3, lr]                           @ 0800244C
	b	.L08002468                               @ 08002450
.Llit08002454:
	.word	mcChan                         @ 08002454  = 0x030055C0
.Llit08002458:
	.word	mcSmpInstTable                 @ 08002458  = 0x0808233C
.Llit0800245C:
	.word	pcm_080128BC+4                 @ 0800245C  = 0x080128C0
.Llit08002460:
	.word	mcBufIndex                     @ 08002460  = 0x030048E8
.Llit08002464:
	.word	mcMusicBuf                     @ 08002464  = 0x03005260
.L08002468:
	ldr	r3, .Llit0800249C                      @ 08002468  =mcSmpInstTable
	add	r2, r3, #8                             @ 0800246C
	ldr	r3, [r2, r1, lsl #4]                   @ 08002470
	cmp	r3, #1                                 @ 08002474
	movne	r6, #0                               @ 08002478
	mvneq	r6, #0                               @ 0800247C
.L08002480:
	ldr	r1, .Llit080024A0                      @ 08002480  =mcChan
	add	r3, r1, #0x38                          @ 08002484
	str	r10, [r3, r12]                         @ 08002488
	str	r8, [r3, r9]                           @ 0800248C
	str	r7, [r3, r0]                           @ 08002490
	str	r6, [r3, lr]                           @ 08002494
	b	.L080024A4                               @ 08002498
.Llit0800249C:
	.word	mcSmpInstTable                 @ 0800249C  = 0x0808233C
.Llit080024A0:
	.word	mcChan                         @ 080024A0  = 0x030055C0
.L080024A4:
	ldmdb	r11, {r4, r5, r6, r7, r8, r9, r10, r11, sp, lr} @ 080024A4
	bx	lr                                      @ 080024A8
