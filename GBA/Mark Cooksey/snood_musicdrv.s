@ ============================================================================
@ snood_musicdrv.s -- Mark Cooksey's GBA sound driver, "Build A", as used in Snood (GBA)
@
@ Reconstructed from "Snood (E) (M5).gba" (ASQP), ROM range
@ 0x08024AFC-0x08025CA0 (4516 bytes).  Assembling this file and linking it with snood_sound.ld
@ reproduces that range byte for byte (make -f snood_sound.mk).
@
@ This is E.T.'s driver (et_musicdrv.s, claude/cooksey-et-technical-reference.md) rebuilt with
@ the DirectSound music channels removed: 4 PSG channels only, a fixed note-length table, no
@ mcUpdateSamples and no stream player.  The built-in DirectSound SFX player, dead in E.T., is
@ Snood's real SFX system.  Compiled Thumb (early GCC), same idioms as E.T.
@ Differences are documented in claude/cooksey-gba-variants-comparison.md.
@ There are no symbols in the ROM; every name here was assigned during the analysis.
@
@ Channel numbering in comments is 1-4 (SOUND1-4); in the code the loop counter runs 0-3.
@
@ Host integration:
@   VBlank handler (0x08000C38): mcUpdate()
@   game: mcSoundInit() is called before every mcPlaySong (11 call sites); all 166 SFX calls go
@         straight to mcDsSfxStart(idx, slot 0/1, vol)
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
	.equ	mcPsgSfxCur,       0x03006640   @     4 B  last PSG SFX number passed to mcPlayPsgSfx
	.equ	mcDsSfxFrames,     0x03006648   @     8 B  DS SFX slot: frames left, [2]
	.equ	mcDsSfxAddr,       0x03006650   @     8 B  DS SFX slot: PCM address, [2]
	.equ	mcTempo,           0x03006658   @     4 B  tempo: ticks per frame in 8.8 fixed point
	.equ	mcPaused,          0x0300665C   @     4 B  non-zero = sequencer frozen
	.equ	mcTempoAcc,        0x03006660   @     4 B  tempo accumulator
	.equ	mcMasterPan,       0x03006664   @     4 B  SOUNDCNT_L shadow (init stores 7 and uses it as the master volume)
	.equ	mcPsgSfx,          0x03006670   @    48 B  PSG SFX slots [4] x {ptr, index, timer}
	.equ	mcDsSfxPending,    0x030066A0   @     8 B  DS SFX slot: start the DMA on the next mcUpdate, [2]
	.equ	mcDsSfxLoopFrames, 0x030066A8   @     8 B  DS SFX slot: frames per loop (0 = one-shot), [2]
	.equ	mcChan,            0x030066B0   @   288 B  music channel state [4] x 0x48 bytes
	.equ	mcCondFlag,        0x03006860   @     4 B  SEQ_CONDFLAG value; never read
	.equ	mcDsSfxIndex,      0x03006868   @     8 B  DS SFX slot: table index, [2]
@ ---- music channel struct (0x48 bytes each, 4 channels)
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
	.equ	CH_envIdx, 0x30
	.equ	CH_envTimer, 0x34
	.equ	CH_pitchIdx, 0x38
	.equ	CH_pitchTimer, 0x3C
	.equ	CH_arpIdx, 0x40
	.equ	CH_arpTimer, 0x44
@ ---- ROM data (see snood_sound_data.s)
	.equ	mcDsSfxTable, 0x083FBEC8
	.equ	mcPsgSfxMap, 0x083FC378
	.equ	mcPsgSfxScripts, 0x083FC6F8
	.equ	mcDurTable, 0x083FC738
	.equ	mcFreqLo, 0x083FF24C
	.equ	mcFreqHi, 0x083FF2AD
	.equ	mcSongTable, 0x083FF310
	.equ	mcInstTable, 0x083FF834

	.section .text.snood_musicdrv, "ax", %progbits
	.balign 4
	@ linked at 0x08024AFC by snood_sound.ld

@ --------------------------------------------------------------------------
@ mcSoundInit  (0x08024AFC)
@   Reset hardware and driver state (the game also uses it as "stop everything" before each song)
@       mcChan[0..3].active = 0; mcTempo = 0x100; mcTempoAcc = 0; mcMasterPan = 7; mcPaused = 0
@       wave RAM bank = FF x 8, 00 x 8; SOUNDCNT_L = mcMasterPan * 0x11 + 0xFF00 (= 0xFF77)
@       SOUNDCNT_X = 0x8F; SOUNDCNT_H = 0xFB0E; SOUND3CNT_L = 0xC0; wave RAM (other bank) = FF x 8, 00 x 8
@       SOUND1CNT_L = 8; PSG SFX slots 0-3 ptr = 0; mcDsSfxPending[] = mcDsSfxLoopFrames[] = 0
@     Same as E.T. but only 4 channel structs and no stream-player variables.
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcSoundInit
mcSoundInit:
	push	{r4, lr}                              @ 08024AFC
	ldr	r0, .Llit08024BB4                      @ 08024AFE  =mcChan
	movs	r2, #0                                @ 08024B00
	str	r2, [r0]                               @ 08024B02
	str	r2, [r0, #0x48]                        @ 08024B04
	adds	r1, r0, #0                            @ 08024B06
	adds	r1, #0x90                             @ 08024B08
	str	r2, [r1]                               @ 08024B0A
	adds	r0, #0xd8                             @ 08024B0C
	str	r2, [r0]                               @ 08024B0E
	ldr	r1, .Llit08024BB8                      @ 08024B10  =mcTempo
	movs	r0, #0x80                             @ 08024B12
	lsls	r0, r0, #1                            @ 08024B14
	str	r0, [r1]                               @ 08024B16
	ldr	r0, .Llit08024BBC                      @ 08024B18  =mcTempoAcc
	str	r2, [r0]                               @ 08024B1A
	ldr	r1, .Llit08024BC0                      @ 08024B1C  =mcMasterPan
	movs	r0, #7                                @ 08024B1E
	str	r0, [r1]                               @ 08024B20
	ldr	r0, .Llit08024BC4                      @ 08024B22  =mcPaused
	str	r2, [r0]                               @ 08024B24
	ldr	r3, .Llit08024BC8                      @ 08024B26  =REG_WAVE_RAM
	ldr	r4, .Llit08024BCC                      @ 08024B28  =mcPsgSfx
	ldr	r2, .Llit08024BD0                      @ 08024B2A  =0xFFFF
	adds	r0, r2, #0                            @ 08024B2C
	adds	r2, r3, #6                            @ 08024B2E
.L08024B30:
	strh	r0, [r2]                              @ 08024B30
	subs	r2, #2                                @ 08024B32
	cmp	r2, r3                                 @ 08024B34
	bge	.L08024B30                             @ 08024B36
	movs	r0, #0                                @ 08024B38
	adds	r3, #8                                @ 08024B3A
	movs	r2, #3                                @ 08024B3C
.L08024B3E:
	strh	r0, [r3]                              @ 08024B3E
	adds	r3, #2                                @ 08024B40
	subs	r2, #1                                @ 08024B42
	cmp	r2, #0                                 @ 08024B44
	bge	.L08024B3E                             @ 08024B46
	ldr	r2, .Llit08024BD4                      @ 08024B48  =REG_SOUNDCNT_L
	ldr	r0, [r1]                               @ 08024B4A
	lsls	r1, r0, #4                            @ 08024B4C
	adds	r0, r0, r1                            @ 08024B4E
	movs	r1, #0xff                             @ 08024B50
	lsls	r1, r1, #8                            @ 08024B52
	adds	r0, r0, r1                            @ 08024B54
	strh	r0, [r2]                              @ 08024B56
	ldr	r1, .Llit08024BD8                      @ 08024B58  =REG_SOUNDCNT_X
	movs	r0, #0x8f                             @ 08024B5A
	strh	r0, [r1]                              @ 08024B5C
	subs	r1, #2                                @ 08024B5E
	ldr	r2, .Llit08024BDC                      @ 08024B60  =0xFB0E
	adds	r0, r2, #0                            @ 08024B62
	strh	r0, [r1]                              @ 08024B64
	subs	r1, #0x12                             @ 08024B66
	movs	r0, #0xc0                             @ 08024B68
	strh	r0, [r1]                              @ 08024B6A
	ldr	r3, .Llit08024BC8                      @ 08024B6C  =REG_WAVE_RAM
	ldr	r0, .Llit08024BD0                      @ 08024B6E  =0xFFFF
	adds	r1, r0, #0                            @ 08024B70
	adds	r0, r3, #6                            @ 08024B72
.L08024B74:
	strh	r1, [r0]                              @ 08024B74
	subs	r0, #2                                @ 08024B76
	cmp	r0, r3                                 @ 08024B78
	bge	.L08024B74                             @ 08024B7A
	movs	r1, #0                                @ 08024B7C
	adds	r0, r3, #0                            @ 08024B7E
	adds	r0, #8                                @ 08024B80
	movs	r2, #3                                @ 08024B82
.L08024B84:
	strh	r1, [r0]                              @ 08024B84
	adds	r0, #2                                @ 08024B86
	subs	r2, #1                                @ 08024B88
	cmp	r2, #0                                 @ 08024B8A
	bge	.L08024B84                             @ 08024B8C
	movs	r2, #8                                @ 08024B8E
	ldr	r0, .Llit08024BE0                      @ 08024B90  =REG_SOUND1CNT_L
	strh	r2, [r0]                              @ 08024B92
	movs	r0, #0                                @ 08024B94
	str	r0, [r4]                               @ 08024B96
	str	r0, [r4, #0xc]                         @ 08024B98
	str	r0, [r4, #0x18]                        @ 08024B9A
	str	r0, [r4, #0x24]                        @ 08024B9C
	ldr	r3, .Llit08024BE4                      @ 08024B9E  =mcDsSfxLoopFrames
	ldr	r1, .Llit08024BE8                      @ 08024BA0  =mcDsSfxPending
	movs	r2, #1                                @ 08024BA2
.L08024BA4:
	stm	r1!, {r0}                              @ 08024BA4
	stm	r3!, {r0}                              @ 08024BA6
	subs	r2, #1                                @ 08024BA8
	cmp	r2, #0                                 @ 08024BAA
	bge	.L08024BA4                             @ 08024BAC
	pop	{r4}                                   @ 08024BAE
	pop	{r0}                                   @ 08024BB0
	bx	r0                                      @ 08024BB2
.Llit08024BB4:
	.word	mcChan                         @ 08024BB4  = 0x030066B0
.Llit08024BB8:
	.word	mcTempo                        @ 08024BB8  = 0x03006658
.Llit08024BBC:
	.word	mcTempoAcc                     @ 08024BBC  = 0x03006660
.Llit08024BC0:
	.word	mcMasterPan                    @ 08024BC0  = 0x03006664
.Llit08024BC4:
	.word	mcPaused                       @ 08024BC4  = 0x0300665C
.Llit08024BC8:
	.word	REG_WAVE_RAM                   @ 08024BC8  = 0x04000090
.Llit08024BCC:
	.word	mcPsgSfx                       @ 08024BCC  = 0x03006670
.Llit08024BD0:
	.word	0x0000FFFF                     @ 08024BD0
.Llit08024BD4:
	.word	REG_SOUNDCNT_L                 @ 08024BD4  = 0x04000080
.Llit08024BD8:
	.word	REG_SOUNDCNT_X                 @ 08024BD8  = 0x04000084
.Llit08024BDC:
	.word	0x0000FB0E                     @ 08024BDC
.Llit08024BE0:
	.word	REG_SOUND1CNT_L                @ 08024BE0  = 0x04000060
.Llit08024BE4:
	.word	mcDsSfxLoopFrames              @ 08024BE4  = 0x030066A8
.Llit08024BE8:
	.word	mcDsSfxPending                 @ 08024BE8  = 0x030066A0
@ --------------------------------------------------------------------------
@ mcDsSfxStart  (0x08024BEC)
@   void mcDsSfxStart(int idx, int slot, int vol): queue DirectSound SFX idx on slot 0 (FIFO A) or 1 (FIFO B)
@       mcDsSfxIndex[slot] = idx; mcDsSfxAddr[slot] = mcDsSfxTable[idx].pcm
@       mcDsSfxFrames[slot] = .frames; mcDsSfxLoopFrames[slot] = .loopFrames; mcDsSfxPending[slot] = 1
@       SOUNDCNT_H: DS A (slot 0) / DS B (slot 1) volume bit = vol   (1 = 100 %, 0 = 50 %)
@     E.T.'s code with 12-byte table entries (E.T.: 16).  Snood's only SFX path: 166 call sites.
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcDsSfxStart
mcDsSfxStart:
	push	{r4, r5, r6, lr}                      @ 08024BEC
	adds	r6, r2, #0                            @ 08024BEE
	ldr	r2, .Llit08024C3C                      @ 08024BF0  =mcDsSfxIndex
	lsls	r4, r1, #2                            @ 08024BF2
	adds	r2, r4, r2                            @ 08024BF4
	str	r0, [r2]                               @ 08024BF6
	ldr	r3, .Llit08024C40                      @ 08024BF8  =mcDsSfxAddr
	adds	r3, r4, r3                            @ 08024BFA
	ldr	r5, .Llit08024C44                      @ 08024BFC  =mcDsSfxTable
	lsls	r2, r0, #1                            @ 08024BFE
	adds	r2, r2, r0                            @ 08024C00
	lsls	r2, r2, #2                            @ 08024C02
	adds	r0, r2, r5                            @ 08024C04
	ldr	r0, [r0]                               @ 08024C06
	str	r0, [r3]                               @ 08024C08
	ldr	r3, .Llit08024C48                      @ 08024C0A  =mcDsSfxFrames
	adds	r3, r4, r3                            @ 08024C0C
	adds	r0, r5, #4                            @ 08024C0E
	adds	r0, r2, r0                            @ 08024C10
	ldr	r0, [r0]                               @ 08024C12
	str	r0, [r3]                               @ 08024C14
	ldr	r3, .Llit08024C4C                      @ 08024C16  =mcDsSfxLoopFrames
	adds	r3, r4, r3                            @ 08024C18
	adds	r5, #8                                @ 08024C1A
	adds	r2, r2, r5                            @ 08024C1C
	ldr	r0, [r2]                               @ 08024C1E
	str	r0, [r3]                               @ 08024C20
	ldr	r0, .Llit08024C50                      @ 08024C22  =mcDsSfxPending
	adds	r4, r4, r0                            @ 08024C24
	movs	r0, #1                                @ 08024C26
	str	r0, [r4]                               @ 08024C28
	cmp	r1, #0                                 @ 08024C2A
	bne	.L08024C5C                             @ 08024C2C
	ldr	r2, .Llit08024C54                      @ 08024C2E  =REG_SOUNDCNT_H
	ldrh	r1, [r2]                              @ 08024C30
	ldr	r0, .Llit08024C58                      @ 08024C32  =0xFFFB
	ands	r0, r1                                @ 08024C34
	lsls	r1, r6, #2                            @ 08024C36
	b	.L08024C66                               @ 08024C38
	.hword	0x0000                          @ 08024C3A  (padding)
.Llit08024C3C:
	.word	mcDsSfxIndex                   @ 08024C3C  = 0x03006868
.Llit08024C40:
	.word	mcDsSfxAddr                    @ 08024C40  = 0x03006650
.Llit08024C44:
	.word	mcDsSfxTable                   @ 08024C44  = 0x083FBEC8
.Llit08024C48:
	.word	mcDsSfxFrames                  @ 08024C48  = 0x03006648
.Llit08024C4C:
	.word	mcDsSfxLoopFrames              @ 08024C4C  = 0x030066A8
.Llit08024C50:
	.word	mcDsSfxPending                 @ 08024C50  = 0x030066A0
.Llit08024C54:
	.word	REG_SOUNDCNT_H                 @ 08024C54  = 0x04000082
.Llit08024C58:
	.word	0x0000FFFB                     @ 08024C58
.L08024C5C:
	ldr	r2, .Llit08024C70                      @ 08024C5C  =REG_SOUNDCNT_H
	ldrh	r1, [r2]                              @ 08024C5E
	ldr	r0, .Llit08024C74                      @ 08024C60  =0xFFF7
	ands	r0, r1                                @ 08024C62
	lsls	r1, r6, #3                            @ 08024C64
.L08024C66:
	orrs	r0, r1                                @ 08024C66
	strh	r0, [r2]                              @ 08024C68
	pop	{r4, r5, r6}                           @ 08024C6A
	pop	{r0}                                   @ 08024C6C
	bx	r0                                      @ 08024C6E
.Llit08024C70:
	.word	REG_SOUNDCNT_H                 @ 08024C70  = 0x04000082
.Llit08024C74:
	.word	0x0000FFF7                     @ 08024C74
@ --------------------------------------------------------------------------
@ mcPlaySong  (0x08024C78)
@   Start song n: channels 1-4 only
@       e = &mcSongTable[n]   (28-byte entries; only words 0-3 are read; no note-length table pointer is
@                              stored: mcUpdate always uses mcDurTable)
@       for ch in 0..3: seqPtr = e->seq[ch]; seqIdx = patPtr = patPos = ticks = 0; active = owned = 1
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcPlaySong
mcPlaySong:
	push	{r4, r5, lr}                          @ 08024C78
	ldr	r1, .Llit08024D04                      @ 08024C7A  =mcChan
	mov	r12, r1                                @ 08024C7C
	ldr	r5, .Llit08024D08                      @ 08024C7E  =mcSongTable
	lsls	r2, r0, #3                            @ 08024C80
	subs	r2, r2, r0                            @ 08024C82
	lsls	r2, r2, #2                            @ 08024C84
	adds	r0, r2, r5                            @ 08024C86
	ldr	r0, [r0]                               @ 08024C88
	str	r0, [r1, #0x20]                        @ 08024C8A
	movs	r1, #0                                @ 08024C8C
	mov	r4, r12                                @ 08024C8E
	str	r1, [r4, #8]                           @ 08024C90
	str	r1, [r4, #0x24]                        @ 08024C92
	str	r1, [r4, #0xc]                         @ 08024C94
	str	r1, [r4, #0x10]                        @ 08024C96
	movs	r3, #1                                @ 08024C98
	str	r3, [r4]                               @ 08024C9A
	str	r3, [r4, #4]                           @ 08024C9C
	adds	r0, r5, #4                            @ 08024C9E
	adds	r0, r2, r0                            @ 08024CA0
	ldr	r0, [r0]                               @ 08024CA2
	str	r0, [r4, #0x68]                        @ 08024CA4
	str	r1, [r4, #0x50]                        @ 08024CA6
	str	r1, [r4, #0x6c]                        @ 08024CA8
	str	r1, [r4, #0x54]                        @ 08024CAA
	str	r1, [r4, #0x58]                        @ 08024CAC
	str	r3, [r4, #0x48]                        @ 08024CAE
	str	r3, [r4, #0x4c]                        @ 08024CB0
	adds	r4, #0xb0                             @ 08024CB2
	adds	r0, r5, #0                            @ 08024CB4
	adds	r0, #8                                @ 08024CB6
	adds	r0, r2, r0                            @ 08024CB8
	ldr	r0, [r0]                               @ 08024CBA
	str	r0, [r4]                               @ 08024CBC
	mov	r0, r12                                @ 08024CBE
	adds	r0, #0x98                             @ 08024CC0
	str	r1, [r0]                               @ 08024CC2
	adds	r0, #0x1c                             @ 08024CC4
	str	r1, [r0]                               @ 08024CC6
	subs	r0, #0x18                             @ 08024CC8
	str	r1, [r0]                               @ 08024CCA
	adds	r0, #4                                @ 08024CCC
	str	r1, [r0]                               @ 08024CCE
	subs	r0, #0x10                             @ 08024CD0
	str	r3, [r0]                               @ 08024CD2
	adds	r0, #4                                @ 08024CD4
	str	r3, [r0]                               @ 08024CD6
	adds	r4, #0x48                             @ 08024CD8
	adds	r5, #0xc                              @ 08024CDA
	adds	r2, r2, r5                            @ 08024CDC
	ldr	r0, [r2]                               @ 08024CDE
	str	r0, [r4]                               @ 08024CE0
	mov	r0, r12                                @ 08024CE2
	adds	r0, #0xe0                             @ 08024CE4
	str	r1, [r0]                               @ 08024CE6
	adds	r0, #0x1c                             @ 08024CE8
	str	r1, [r0]                               @ 08024CEA
	subs	r0, #0x18                             @ 08024CEC
	str	r1, [r0]                               @ 08024CEE
	adds	r0, #4                                @ 08024CF0
	str	r1, [r0]                               @ 08024CF2
	subs	r0, #0x10                             @ 08024CF4
	str	r3, [r0]                               @ 08024CF6
	adds	r0, #4                                @ 08024CF8
	str	r3, [r0]                               @ 08024CFA
	pop	{r4, r5}                               @ 08024CFC
	pop	{r0}                                   @ 08024CFE
	bx	r0                                      @ 08024D00
	.hword	0x0000                          @ 08024D02  (padding)
.Llit08024D04:
	.word	mcChan                         @ 08024D04  = 0x030066B0
.Llit08024D08:
	.word	mcSongTable                    @ 08024D08  = 0x083FF310
@ --------------------------------------------------------------------------
@ mcPlayPsgSfx  (0x08024D0C)
@   PSG register-script SFX, unchanged from E.T. (NO CALLERS)
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcPlayPsgSfx
mcPlayPsgSfx:
	push	{r4, r5, r6, r7, lr}                  @ 08024D0C
	mov	r7, r10                                @ 08024D0E
	mov	r6, r9                                 @ 08024D10
	mov	r5, r8                                 @ 08024D12
	push	{r5, r6, r7}                          @ 08024D14
	adds	r5, r0, #0                            @ 08024D16
	ldr	r0, .Llit08024D80                      @ 08024D18  =mcPsgSfxCur
	str	r5, [r0]                               @ 08024D1A
	movs	r4, #0                                @ 08024D1C
	ldr	r0, .Llit08024D84                      @ 08024D1E  =mcPsgSfxMap
	mov	r10, r0                                @ 08024D20
	ldr	r0, .Llit08024D88                      @ 08024D22  =mcPsgSfxScripts
	mov	r9, r0                                 @ 08024D24
	ldr	r6, .Llit08024D8C                      @ 08024D26  =mcPsgSfx
	movs	r0, #8                                @ 08024D28
	adds	r0, r0, r6                            @ 08024D2A
	mov	r8, r0                                 @ 08024D2C
	movs	r7, #0                                @ 08024D2E
	ldr	r0, .Llit08024D90                      @ 08024D30  =mcChan+CH_owned
	mov	r12, r0                                @ 08024D32
.L08024D34:
	lsls	r0, r5, #2                            @ 08024D34
	adds	r0, r4, r0                            @ 08024D36
	add	r0, r10                                @ 08024D38
	ldrb	r0, [r0]                              @ 08024D3A
	cmp	r0, #0xff                              @ 08024D3C
	beq	.L08024D6C                             @ 08024D3E
	lsls	r0, r0, #2                            @ 08024D40
	add	r0, r9                                 @ 08024D42
	ldr	r2, [r0]                               @ 08024D44
	ldrh	r3, [r2]                              @ 08024D46
	adds	r2, #2                                @ 08024D48
	lsls	r0, r3, #1                            @ 08024D4A
	adds	r0, r0, r3                            @ 08024D4C
	lsls	r0, r0, #2                            @ 08024D4E
	adds	r1, r0, r6                            @ 08024D50
	str	r2, [r1]                               @ 08024D52
	adds	r1, r6, #4                            @ 08024D54
	adds	r1, r0, r1                            @ 08024D56
	movs	r2, #5                                @ 08024D58
	rsbs	r2, r2, #0                            @ 08024D5A
	str	r2, [r1]                               @ 08024D5C
	add	r0, r8                                 @ 08024D5E
	str	r7, [r0]                               @ 08024D60
	lsls	r0, r3, #3                            @ 08024D62
	adds	r0, r0, r3                            @ 08024D64
	lsls	r0, r0, #3                            @ 08024D66
	add	r0, r12                                @ 08024D68
	str	r7, [r0]                               @ 08024D6A
.L08024D6C:
	adds	r4, #1                                @ 08024D6C
	cmp	r4, #3                                 @ 08024D6E
	ble	.L08024D34                             @ 08024D70
	pop	{r3, r4, r5}                           @ 08024D72
	mov	r8, r3                                 @ 08024D74
	mov	r9, r4                                 @ 08024D76
	mov	r10, r5                                @ 08024D78
	pop	{r4, r5, r6, r7}                       @ 08024D7A
	pop	{r0}                                   @ 08024D7C
	bx	r0                                      @ 08024D7E
.Llit08024D80:
	.word	mcPsgSfxCur                    @ 08024D80  = 0x03006640
.Llit08024D84:
	.word	mcPsgSfxMap                    @ 08024D84  = 0x083FC378
.Llit08024D88:
	.word	mcPsgSfxScripts                @ 08024D88  = 0x083FC6F8
.Llit08024D8C:
	.word	mcPsgSfx                       @ 08024D8C  = 0x03006670
.Llit08024D90:
	.word	mcChan+CH_owned                @ 08024D90  = 0x030066B4
@ --------------------------------------------------------------------------
@ mcPause  (0x08024D94)
@   mcPaused = 1; silence each PSG channel whose SFX slot is idle (NO CALLERS)
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcPause
mcPause:
	ldr	r1, .Llit08024DD8                      @ 08024D94  =mcPaused
	movs	r0, #1                                @ 08024D96
	str	r0, [r1]                               @ 08024D98
	ldr	r2, .Llit08024DDC                      @ 08024D9A  =mcPsgSfx
	ldr	r1, [r2]                               @ 08024D9C
	cmp	r1, #0                                 @ 08024D9E
	bne	.L08024DAA                             @ 08024DA0
	ldr	r0, .Llit08024DE0                      @ 08024DA2  =REG_SOUND1CNT_H
	strh	r1, [r0]                              @ 08024DA4
	adds	r0, #2                                @ 08024DA6
	strh	r1, [r0]                              @ 08024DA8
.L08024DAA:
	ldr	r1, [r2, #0xc]                         @ 08024DAA
	cmp	r1, #0                                 @ 08024DAC
	bne	.L08024DB8                             @ 08024DAE
	ldr	r0, .Llit08024DE4                      @ 08024DB0  =REG_SOUND2CNT_L
	strh	r1, [r0]                              @ 08024DB2
	adds	r0, #4                                @ 08024DB4
	strh	r1, [r0]                              @ 08024DB6
.L08024DB8:
	ldr	r1, [r2, #0x18]                        @ 08024DB8
	cmp	r1, #0                                 @ 08024DBA
	bne	.L08024DC6                             @ 08024DBC
	ldr	r0, .Llit08024DE8                      @ 08024DBE  =REG_SOUND3CNT_H
	strh	r1, [r0]                              @ 08024DC0
	adds	r0, #2                                @ 08024DC2
	strh	r1, [r0]                              @ 08024DC4
.L08024DC6:
	ldr	r1, [r2, #0x24]                        @ 08024DC6
	cmp	r1, #0                                 @ 08024DC8
	bne	.L08024DD4                             @ 08024DCA
	ldr	r0, .Llit08024DEC                      @ 08024DCC  =REG_SOUND4CNT_L
	strh	r1, [r0]                              @ 08024DCE
	adds	r0, #4                                @ 08024DD0
	strh	r1, [r0]                              @ 08024DD2
.L08024DD4:
	bx	lr                                      @ 08024DD4
	.hword	0x0000                          @ 08024DD6  (padding)
.Llit08024DD8:
	.word	mcPaused                       @ 08024DD8  = 0x0300665C
.Llit08024DDC:
	.word	mcPsgSfx                       @ 08024DDC  = 0x03006670
.Llit08024DE0:
	.word	REG_SOUND1CNT_H                @ 08024DE0  = 0x04000062
.Llit08024DE4:
	.word	REG_SOUND2CNT_L                @ 08024DE4  = 0x04000068
.Llit08024DE8:
	.word	REG_SOUND3CNT_H                @ 08024DE8  = 0x04000072
.Llit08024DEC:
	.word	REG_SOUND4CNT_L                @ 08024DEC  = 0x04000078
@ --------------------------------------------------------------------------
@ mcResume  (0x08024DF0)
@   mcPaused = 0 (NO CALLERS)
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcResume
mcResume:
	ldr	r1, .Llit08024DF8                      @ 08024DF0  =mcPaused
	movs	r0, #0                                @ 08024DF2
	str	r0, [r1]                               @ 08024DF4
	bx	lr                                      @ 08024DF6
.Llit08024DF8:
	.word	mcPaused                       @ 08024DF8  = 0x0300665C
@ --------------------------------------------------------------------------
@ mcDsSfxStop  (0x08024DFC)
@   void mcDsSfxStop(int slot): DMAxCNT = 0, mcDsSfxPending[slot] = mcDsSfxLoopFrames[slot] = 0
@     The timer and mcDsSfxFrames are left running; when the count reaches 0, mcUpdate stops the DMA again.
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcDsSfxStop
mcDsSfxStop:
	adds	r1, r0, #0                            @ 08024DFC
	cmp	r1, #0                                 @ 08024DFE
	bne	.L08024E1C                             @ 08024E00
	ldr	r0, .Llit08024E10                      @ 08024E02  =REG_DMA1CNT
	str	r1, [r0]                               @ 08024E04
	ldr	r0, .Llit08024E14                      @ 08024E06  =mcDsSfxPending
	str	r1, [r0]                               @ 08024E08
	ldr	r0, .Llit08024E18                      @ 08024E0A  =mcDsSfxLoopFrames
	str	r1, [r0]                               @ 08024E0C
	b	.L08024E30                               @ 08024E0E
.Llit08024E10:
	.word	REG_DMA1CNT                    @ 08024E10  = 0x040000C4
.Llit08024E14:
	.word	mcDsSfxPending                 @ 08024E14  = 0x030066A0
.Llit08024E18:
	.word	mcDsSfxLoopFrames              @ 08024E18  = 0x030066A8
.L08024E1C:
	ldr	r0, .Llit08024E34                      @ 08024E1C  =REG_DMA2CNT
	movs	r2, #0                                @ 08024E1E
	str	r2, [r0]                               @ 08024E20
	ldr	r0, .Llit08024E38                      @ 08024E22  =mcDsSfxPending
	lsls	r1, r1, #2                            @ 08024E24
	adds	r0, r1, r0                            @ 08024E26
	str	r2, [r0]                               @ 08024E28
	ldr	r0, .Llit08024E3C                      @ 08024E2A  =mcDsSfxLoopFrames
	adds	r1, r1, r0                            @ 08024E2C
	str	r2, [r1]                               @ 08024E2E
.L08024E30:
	bx	lr                                      @ 08024E30
	.hword	0x0000                          @ 08024E32  (padding)
.Llit08024E34:
	.word	REG_DMA2CNT                    @ 08024E34  = 0x040000D0
.Llit08024E38:
	.word	mcDsSfxPending                 @ 08024E38  = 0x030066A0
.Llit08024E3C:
	.word	mcDsSfxLoopFrames              @ 08024E3C  = 0x030066A8
@ --------------------------------------------------------------------------
@ mcUpdate  (0x08024E40)
@   Once per frame, from the VBlank handler:
@     1  DS SFX slots 0-1:
@          if (mcDsSfxFrames[s] && --mcDsSfxFrames[s] == 0):
@              loopFrames ? restart DMA at mcDsSfxAddr[s], frames = loopFrames - 1 : DMAxCNT = 0
@          if (mcDsSfxPending[s]): DMAxCNT = 0; SAD = mcDsSfxAddr[s]; DAD = FIFO; DMAxCNT = 0xBE400000;
@              TMxCNT = 0x0080FA2F (11 268 Hz, ~188.6 bytes per frame); pending = 0
@     2  PSG SFX scripts on channels 1-4 (unchanged from E.T., never triggered)
@     3  if (mcPaused) return
@        mcTempoAcc += mcTempo; if (mcTempoAcc < 0x100) return; mcTempoAcc -= 0x100
@     4  for ch in 0..3: E.T.'s sequencer, table effects and note-on, except that the length index is
@        looked up in the fixed mcDurTable.  E.T.'s bugs are unchanged: the noise walker ignores 0xFE,
@        the first pitch delta is ORed in at note-on, effects run at tempo rate, rests are notes 0x30.
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcUpdate
mcUpdate:
	push	{r4, r5, r6, r7, lr}                  @ 08024E40
	mov	r7, r10                                @ 08024E42
	mov	r6, r9                                 @ 08024E44
	mov	r5, r8                                 @ 08024E46
	push	{r5, r6, r7}                          @ 08024E48
	sub	sp, #0x38                              @ 08024E4A
	movs	r0, #0                                @ 08024E4C
	mov	r9, r0                                 @ 08024E4E
	ldr	r1, .Llit08024EB0                      @ 08024E50  =mcPsgSfx
	str	r1, [sp, #0x30]                        @ 08024E52
	ldr	r7, .Llit08024EB4                      @ 08024E54  =REG_DMA1CNT
	ldr	r2, .Llit08024EB8                      @ 08024E56  =mcDsSfxAddr
	mov	r12, r2                                @ 08024E58
	ldr	r3, .Llit08024EBC                      @ 08024E5A  =0xBE400000
	mov	r10, r3                                @ 08024E5C
	ldr	r4, .Llit08024EC0                      @ 08024E5E  =0x80FA2F
	mov	r8, r4                                 @ 08024E60
	ldr	r5, .Llit08024EC4                      @ 08024E62  =REG_DMA2CNT
	ldr	r6, .Llit08024EC8                      @ 08024E64  =mcDsSfxFrames
	mov	r0, r12                                @ 08024E66
	str	r0, [sp, #0x34]                        @ 08024E68
	movs	r4, #0                                @ 08024E6A
.L08024E6C:
	ldr	r0, [r6]                               @ 08024E6C
	cmp	r0, #0                                 @ 08024E6E
	beq	.L08024F1C                             @ 08024E70
	subs	r0, #1                                @ 08024E72
	str	r0, [r6]                               @ 08024E74
	cmp	r0, #0                                 @ 08024E76
	bne	.L08024F1C                             @ 08024E78
	ldr	r3, .Llit08024ECC                      @ 08024E7A  =mcDsSfxLoopFrames
	adds	r2, r4, r3                            @ 08024E7C
	ldr	r1, [r2]                               @ 08024E7E
	cmp	r1, #0                                 @ 08024E80
	beq	.L08024F10                             @ 08024E82
	mov	r1, r9                                 @ 08024E84
	cmp	r1, #0                                 @ 08024E86
	bne	.L08024EDC                             @ 08024E88
	str	r1, [r7]                               @ 08024E8A
	mov	r2, r12                                @ 08024E8C
	ldr	r0, [r2]                               @ 08024E8E
	ldr	r1, .Llit08024ED0                      @ 08024E90  =REG_DMA1SAD
	str	r0, [r1]                               @ 08024E92
	ldr	r2, .Llit08024ED4                      @ 08024E94  =REG_FIFO_A
	ldr	r0, .Llit08024ED8                      @ 08024E96  =REG_DMA1DAD
	str	r2, [r0]                               @ 08024E98
	mov	r1, r10                                @ 08024E9A  loop: restart slot 0 DMA at the same address
	str	r1, [r7]                               @ 08024E9C
	mov	r2, r8                                 @ 08024E9E
	adds	r0, #0x40                             @ 08024EA0
	str	r2, [r0]                               @ 08024EA2
	ldr	r0, [r3]                               @ 08024EA4
	subs	r0, #1                                @ 08024EA6
	ldr	r1, .Llit08024EC8                      @ 08024EA8  =mcDsSfxFrames
	str	r0, [r1]                               @ 08024EAA
	b	.L08024F1C                               @ 08024EAC
	.hword	0x0000                          @ 08024EAE  (padding)
.Llit08024EB0:
	.word	mcPsgSfx                       @ 08024EB0  = 0x03006670
.Llit08024EB4:
	.word	REG_DMA1CNT                    @ 08024EB4  = 0x040000C4
.Llit08024EB8:
	.word	mcDsSfxAddr                    @ 08024EB8  = 0x03006650
.Llit08024EBC:
	.word	0xBE400000                     @ 08024EBC
.Llit08024EC0:
	.word	0x0080FA2F                     @ 08024EC0
.Llit08024EC4:
	.word	REG_DMA2CNT                    @ 08024EC4  = 0x040000D0
.Llit08024EC8:
	.word	mcDsSfxFrames                  @ 08024EC8  = 0x03006648
.Llit08024ECC:
	.word	mcDsSfxLoopFrames              @ 08024ECC  = 0x030066A8
.Llit08024ED0:
	.word	REG_DMA1SAD                    @ 08024ED0  = 0x040000BC
.Llit08024ED4:
	.word	REG_FIFO_A                     @ 08024ED4  = 0x040000A0
.Llit08024ED8:
	.word	REG_DMA1DAD                    @ 08024ED8  = 0x040000C0
.L08024EDC:
	str	r0, [r5]                               @ 08024EDC
	ldr	r3, [sp, #0x34]                        @ 08024EDE
	ldr	r0, [r3]                               @ 08024EE0
	ldr	r1, .Llit08024F00                      @ 08024EE2  =REG_DMA2SAD
	str	r0, [r1]                               @ 08024EE4
	ldr	r0, .Llit08024F04                      @ 08024EE6  =REG_FIFO_B
	ldr	r3, .Llit08024F08                      @ 08024EE8  =REG_DMA2DAD
	str	r0, [r3]                               @ 08024EEA
	mov	r0, r10                                @ 08024EEC
	str	r0, [r5]                               @ 08024EEE
	ldr	r0, .Llit08024F0C                      @ 08024EF0  =REG_TM1CNT
	mov	r1, r8                                 @ 08024EF2
	str	r1, [r0]                               @ 08024EF4
	ldr	r0, [r2]                               @ 08024EF6
	subs	r0, #1                                @ 08024EF8
	str	r0, [r6]                               @ 08024EFA
	b	.L08024F1C                               @ 08024EFC
	.hword	0x0000                          @ 08024EFE  (padding)
.Llit08024F00:
	.word	REG_DMA2SAD                    @ 08024F00  = 0x040000C8
.Llit08024F04:
	.word	REG_FIFO_B                     @ 08024F04  = 0x040000A4
.Llit08024F08:
	.word	REG_DMA2DAD                    @ 08024F08  = 0x040000CC
.Llit08024F0C:
	.word	REG_TM1CNT                     @ 08024F0C  = 0x04000104
.L08024F10:
	mov	r2, r9                                 @ 08024F10
	cmp	r2, #0                                 @ 08024F12
	bne	.L08024F1A                             @ 08024F14
	str	r2, [r7]                               @ 08024F16
	b	.L08024F1C                               @ 08024F18
.L08024F1A:
	str	r1, [r5]                               @ 08024F1A
.L08024F1C:
	ldr	r3, .Llit08024F50                      @ 08024F1C  =mcDsSfxPending
	adds	r1, r4, r3                            @ 08024F1E
	ldr	r0, [r1]                               @ 08024F20
	cmp	r0, #0                                 @ 08024F22
	beq	.L08024F82                             @ 08024F24
	mov	r0, r9                                 @ 08024F26
	cmp	r0, #0                                 @ 08024F28
	bne	.L08024F60                             @ 08024F2A
	str	r0, [r7]                               @ 08024F2C
	mov	r1, r12                                @ 08024F2E
	ldr	r0, [r1]                               @ 08024F30
	ldr	r2, .Llit08024F54                      @ 08024F32  =REG_DMA1SAD
	str	r0, [r2]                               @ 08024F34
	ldr	r3, .Llit08024F58                      @ 08024F36  =REG_FIFO_A
	ldr	r0, .Llit08024F5C                      @ 08024F38  =REG_DMA1DAD
	str	r3, [r0]                               @ 08024F3A
	mov	r1, r10                                @ 08024F3C
	str	r1, [r7]                               @ 08024F3E  pending: DMA1CNT = FIFO | repeat | 32-bit
	mov	r2, r8                                 @ 08024F40
	adds	r3, #0x60                             @ 08024F42
	str	r2, [r3]                               @ 08024F44  TM0CNT = 0x0080FA2F: 11 268 Hz
	mov	r0, r9                                 @ 08024F46
	ldr	r1, .Llit08024F50                      @ 08024F48  =mcDsSfxPending
	str	r0, [r1]                               @ 08024F4A
	b	.L08024F82                               @ 08024F4C
	.hword	0x0000                          @ 08024F4E  (padding)
.Llit08024F50:
	.word	mcDsSfxPending                 @ 08024F50  = 0x030066A0
.Llit08024F54:
	.word	REG_DMA1SAD                    @ 08024F54  = 0x040000BC
.Llit08024F58:
	.word	REG_FIFO_A                     @ 08024F58  = 0x040000A0
.Llit08024F5C:
	.word	REG_DMA1DAD                    @ 08024F5C  = 0x040000C0
.L08024F60:
	movs	r2, #0                                @ 08024F60
	str	r2, [r5]                               @ 08024F62
	mov	r3, r12                                @ 08024F64
	adds	r0, r4, r3                            @ 08024F66
	ldr	r0, [r0]                               @ 08024F68
	ldr	r2, .Llit08024FE0                      @ 08024F6A  =REG_DMA2SAD
	str	r0, [r2]                               @ 08024F6C
	ldr	r0, .Llit08024FE4                      @ 08024F6E  =REG_FIFO_B
	ldr	r3, .Llit08024FE8                      @ 08024F70  =REG_DMA2DAD
	str	r0, [r3]                               @ 08024F72
	mov	r0, r10                                @ 08024F74
	str	r0, [r5]                               @ 08024F76  pending: DMA2CNT
	ldr	r0, .Llit08024FEC                      @ 08024F78  =REG_TM1CNT
	mov	r2, r8                                 @ 08024F7A
	str	r2, [r0]                               @ 08024F7C  TM1CNT = 0x0080FA2F
	movs	r3, #0                                @ 08024F7E
	str	r3, [r1]                               @ 08024F80
.L08024F82:
	adds	r6, #4                                @ 08024F82
	ldr	r0, [sp, #0x34]                        @ 08024F84
	adds	r0, #4                                @ 08024F86
	str	r0, [sp, #0x34]                        @ 08024F88
	adds	r4, #4                                @ 08024F8A
	movs	r1, #1                                @ 08024F8C
	add	r9, r1                                 @ 08024F8E
	mov	r2, r9                                 @ 08024F90
	cmp	r2, #1                                 @ 08024F92
	bgt	.L08024F98                             @ 08024F94
	b	.L08024E6C                               @ 08024F96
.L08024F98:
	movs	r3, #0                                @ 08024F98
	mov	r9, r3                                 @ 08024F9A
	ldr	r1, .Llit08024FF0                      @ 08024F9C  =mcPsgSfx
	ldr	r0, .Llit08024FF4                      @ 08024F9E  =mcChan
	adds	r0, #4                                @ 08024FA0
	mov	r8, r0                                 @ 08024FA2
	adds	r7, r1, #4                            @ 08024FA4
	movs	r6, #0                                @ 08024FA6
	adds	r5, r1, #0                            @ 08024FA8
.L08024FAA:
	ldr	r4, [r5]                               @ 08024FAA
	cmp	r4, #0                                 @ 08024FAC
	beq	.L08025082                             @ 08024FAE
	ldr	r0, [sp, #0x30]                        @ 08024FB0
	adds	r0, #8                                @ 08024FB2
	adds	r1, r6, r0                            @ 08024FB4
	ldr	r0, [r1]                               @ 08024FB6
	cmp	r0, #0                                 @ 08024FB8
	beq	.L08024FC4                             @ 08024FBA
	subs	r0, #1                                @ 08024FBC
	str	r0, [r1]                               @ 08024FBE
	cmp	r0, #0                                 @ 08024FC0
	bne	.L08025082                             @ 08024FC2
.L08024FC4:
	ldr	r0, [r5, #4]                           @ 08024FC4
	adds	r0, #5                                @ 08024FC6
	str	r0, [r5, #4]                           @ 08024FC8
	movs	r2, #0                                @ 08024FCA
	lsls	r0, r0, #1                            @ 08024FCC
	adds	r0, r0, r4                            @ 08024FCE
	ldrh	r1, [r0]                              @ 08024FD0
	cmp	r1, #0xfe                              @ 08024FD2
	bne	.L08024FFE                             @ 08024FD4
	ldrh	r3, [r0, #2]                          @ 08024FD6
	cmp	r3, #0xfd                              @ 08024FD8
	bne	.L08024FF8                             @ 08024FDA
	movs	r2, #0xff                             @ 08024FDC
	b	.L08024FFE                               @ 08024FDE
.Llit08024FE0:
	.word	REG_DMA2SAD                    @ 08024FE0  = 0x040000C8
.Llit08024FE4:
	.word	REG_FIFO_B                     @ 08024FE4  = 0x040000A4
.Llit08024FE8:
	.word	REG_DMA2DAD                    @ 08024FE8  = 0x040000CC
.Llit08024FEC:
	.word	REG_TM1CNT                     @ 08024FEC  = 0x04000104
.Llit08024FF0:
	.word	mcPsgSfx                       @ 08024FF0  = 0x03006670
.Llit08024FF4:
	.word	mcChan                         @ 08024FF4  = 0x030066B0
.L08024FF8:
	ldrh	r0, [r0, #2]                          @ 08024FF8
	subs	r0, #1                                @ 08024FFA
	str	r0, [r7]                               @ 08024FFC
.L08024FFE:
	ldr	r3, [sp, #0x30]                        @ 08024FFE
	ldr	r0, [r5, #4]                           @ 08025000
	lsls	r0, r0, #1                            @ 08025002
	adds	r1, r0, r4                            @ 08025004
	ldrh	r0, [r1]                              @ 08025006
	cmp	r0, #0xff                              @ 08025008
	bne	.L0802500E                             @ 0802500A
	movs	r2, #0xff                             @ 0802500C
.L0802500E:
	cmp	r2, #0xff                              @ 0802500E
	bne	.L08025022                             @ 08025010
	adds	r0, r6, r3                            @ 08025012
	movs	r1, #0                                @ 08025014
	str	r1, [r0]                               @ 08025016
	movs	r2, #0                                @ 08025018
	movs	r0, #1                                @ 0802501A
	mov	r3, r8                                 @ 0802501C
	str	r0, [r3]                               @ 0802501E
	b	.L0802504A                               @ 08025020
.L08025022:
	ldr	r0, [sp, #0x30]                        @ 08025022
	adds	r0, #8                                @ 08025024
	adds	r0, r6, r0                            @ 08025026
	ldrh	r1, [r1]                              @ 08025028
	str	r1, [r0]                               @ 0802502A
	ldr	r1, [r7]                               @ 0802502C
	lsls	r1, r1, #1                            @ 0802502E
	adds	r1, r1, r4                            @ 08025030
	ldrh	r4, [r1, #4]                          @ 08025032
	lsls	r0, r4, #8                            @ 08025034
	ldrh	r2, [r1, #2]                          @ 08025036
	orrs	r0, r2                                @ 08025038
	lsls	r0, r0, #0x10                         @ 0802503A
	lsrs	r2, r0, #0x10                         @ 0802503C
	ldrh	r3, [r1, #6]                          @ 0802503E
	lsls	r0, r3, #8                            @ 08025040
	ldrh	r1, [r1, #8]                          @ 08025042
	orrs	r0, r1                                @ 08025044
	lsls	r0, r0, #0x10                         @ 08025046
	lsrs	r1, r0, #0x10                         @ 08025048
.L0802504A:
	mov	r4, r9                                 @ 0802504A
	cmp	r4, #0                                 @ 0802504C
	bne	.L08025058                             @ 0802504E
	ldr	r0, .Llit080253C0                      @ 08025050  =REG_SOUND1CNT_H
	strh	r2, [r0]                              @ 08025052
	adds	r0, #2                                @ 08025054
	strh	r1, [r0]                              @ 08025056
.L08025058:
	mov	r0, r9                                 @ 08025058
	cmp	r0, #1                                 @ 0802505A
	bne	.L08025066                             @ 0802505C
	ldr	r0, .Llit080253C4                      @ 0802505E  =REG_SOUND2CNT_L
	strh	r2, [r0]                              @ 08025060
	adds	r0, #4                                @ 08025062
	strh	r1, [r0]                              @ 08025064
.L08025066:
	mov	r3, r9                                 @ 08025066
	cmp	r3, #2                                 @ 08025068
	bne	.L08025074                             @ 0802506A
	ldr	r0, .Llit080253C8                      @ 0802506C  =REG_SOUND3CNT_H
	strh	r2, [r0]                              @ 0802506E
	adds	r0, #2                                @ 08025070
	strh	r1, [r0]                              @ 08025072
.L08025074:
	mov	r4, r9                                 @ 08025074
	cmp	r4, #3                                 @ 08025076
	bne	.L08025082                             @ 08025078
	ldr	r0, .Llit080253CC                      @ 0802507A  =REG_SOUND4CNT_L
	strh	r2, [r0]                              @ 0802507C
	adds	r0, #4                                @ 0802507E
	strh	r1, [r0]                              @ 08025080
.L08025082:
	movs	r0, #0x48                             @ 08025082
	add	r8, r0                                 @ 08025084
	adds	r7, #0xc                              @ 08025086
	adds	r6, #0xc                              @ 08025088
	adds	r5, #0xc                              @ 0802508A
	movs	r1, #1                                @ 0802508C
	add	r9, r1                                 @ 0802508E
	mov	r2, r9                                 @ 08025090
	cmp	r2, #3                                 @ 08025092
	ble	.L08024FAA                             @ 08025094
	ldr	r3, .Llit080253D0                      @ 08025096  =mcPaused
	ldr	r0, [r3]                               @ 08025098
	cmp	r0, #0                                 @ 0802509A
	beq	.L080250A2                             @ 0802509C
	bl	.L08025C78                              @ 0802509E  long branch
.L080250A2:
	ldr	r2, .Llit080253D4                      @ 080250A2  =mcTempoAcc
	ldr	r0, .Llit080253D8                      @ 080250A4  =mcTempo
	ldr	r1, [r2]                               @ 080250A6
	ldr	r0, [r0]                               @ 080250A8
	adds	r0, r1, r0                            @ 080250AA
	str	r0, [r2]                               @ 080250AC
	cmp	r0, #0xff                              @ 080250AE
	bhi	.L080250B6                             @ 080250B0
	bl	.L08025C78                              @ 080250B2  long branch
.L080250B6:
	ldr	r4, .Llit080253DC                      @ 080250B6  =0xFFFFFF00
	adds	r0, r0, r4                            @ 080250B8
	str	r0, [r2]                               @ 080250BA
	movs	r5, #0                                @ 080250BC
	mov	r9, r5                                 @ 080250BE
	ldr	r6, .Llit080253E0                      @ 080250C0  =mcChan
	mov	r12, r6                                @ 080250C2
.L080250C4:
	mov	r7, r9                                 @ 080250C4
	lsls	r0, r7, #3                            @ 080250C6
	adds	r1, r0, r7                            @ 080250C8
	lsls	r1, r1, #3                            @ 080250CA
	add	r1, r12                                @ 080250CC
	ldr	r1, [r1]                               @ 080250CE
	adds	r2, r7, #0                            @ 080250D0
	adds	r2, #1                                @ 080250D2
	str	r2, [sp, #0x28]                        @ 080250D4
	str	r0, [sp, #0x2c]                        @ 080250D6
	cmp	r1, #1                                 @ 080250D8
	beq	.L080250E0                             @ 080250DA
	bl	.L08025C6C                              @ 080250DC  long branch
.L080250E0:
	ldr	r3, .Llit080253E0                      @ 080250E0  =mcChan
	mov	r10, r3                                @ 080250E2
	ldr	r4, [sp, #0x2c]                        @ 080250E4
	add	r4, r9                                 @ 080250E6
	str	r4, [sp, #4]                           @ 080250E8
	lsls	r5, r4, #3                            @ 080250EA
	str	r5, [sp, #8]                           @ 080250EC
	mov	r0, r10                                @ 080250EE
	adds	r0, #0x10                             @ 080250F0
	adds	r0, r5, r0                            @ 080250F2
	str	r0, [sp, #0xc]                         @ 080250F4
	ldr	r6, .Llit080253E4                      @ 080250F6  =mcChan+CH_patPtr
	adds	r6, r5, r6                            @ 080250F8
	str	r6, [sp, #0x10]                        @ 080250FA
	ldr	r7, .Llit080253E8                      @ 080250FC  =mcChan+CH_freq
	adds	r7, r5, r7                            @ 080250FE
	str	r7, [sp, #0x20]                        @ 08025100
	ldr	r0, .Llit080253EC                      @ 08025102  =mcChan+CH_patPos
	adds	r0, r5, r0                            @ 08025104
	str	r0, [sp, #0x24]                        @ 08025106
.L08025108:
	movs	r1, #0x60                             @ 08025108
	str	r1, [sp]                               @ 0802510A
	ldr	r2, [sp, #0xc]                         @ 0802510C
	ldr	r0, [r2]                               @ 0802510E
	cmp	r0, #0                                 @ 08025110
	bne	.L08025116                             @ 08025112
	b	.L080256FA                               @ 08025114
.L08025116:
	subs	r0, #1                                @ 08025116
	str	r0, [r2]                               @ 08025118
	mov	r0, r12                                @ 0802511A
	adds	r0, #4                                @ 0802511C
	ldr	r3, [sp, #8]                           @ 0802511E
	adds	r0, r3, r0                            @ 08025120
	ldr	r0, [r0]                               @ 08025122
	cmp	r0, #0                                 @ 08025124
	bne	.L0802512A                             @ 08025126
	b	.L080256F0                               @ 08025128
.L0802512A:
	mov	r4, r9                                 @ 0802512A
	cmp	r4, #0                                 @ 0802512C
	beq	.L08025132                             @ 0802512E
	b	.L080252B0                               @ 08025130
.L08025132:
	mov	r5, r10                                @ 08025132
	ldr	r0, [r5, #0x1c]                        @ 08025134
	lsls	r0, r0, #2                            @ 08025136
	ldr	r6, .Llit080253F0                      @ 08025138  =mcInstTable
	adds	r0, r0, r6                            @ 0802513A
	ldr	r5, [r0]                               @ 0802513C
	ldr	r3, [r5, #0x20]                        @ 0802513E
	cmp	r3, #0                                 @ 08025140
	beq	.L080251B0                             @ 08025142
	mov	r7, r10                                @ 08025144
	ldr	r0, [r7, #0x44]                        @ 08025146
	subs	r0, #1                                @ 08025148
	str	r0, [r7, #0x44]                        @ 0802514A
	cmp	r0, #0                                 @ 0802514C
	bne	.L080251B0                             @ 0802514E
	ldr	r0, [r7, #0x40]                        @ 08025150
	adds	r0, #2                                @ 08025152
	str	r0, [r7, #0x40]                        @ 08025154
	lsls	r0, r0, #1                            @ 08025156
	adds	r0, r0, r3                            @ 08025158
	ldrh	r1, [r0]                              @ 0802515A
	cmp	r1, #0xfe                              @ 0802515C
	bne	.L08025166                             @ 0802515E
	movs	r2, #2                                @ 08025160
	ldrsh	r0, [r0, r2]                         @ 08025162
	str	r0, [r7, #0x40]                        @ 08025164
.L08025166:
	mov	r6, r10                                @ 08025166
	ldr	r4, [r6, #0x40]                        @ 08025168
	lsls	r0, r4, #1                            @ 0802516A
	adds	r3, r0, r3                            @ 0802516C
	movs	r7, #0                                @ 0802516E
	ldrsh	r0, [r3, r7]                         @ 08025170
	cmp	r0, #0xfd                              @ 08025172
	bgt	.L080251A4                             @ 08025174
	movs	r0, #2                                @ 08025176
	ldrsh	r1, [r3, r0]                         @ 08025178
	ldr	r0, [r6, #0x14]                        @ 0802517A
	adds	r0, r0, r1                            @ 0802517C
	ldr	r2, .Llit080253F4                      @ 0802517E  =mcFreqHi
	adds	r1, r0, r2                            @ 08025180
	ldrb	r1, [r1]                              @ 08025182
	lsls	r2, r1, #8                            @ 08025184
	ldr	r1, .Llit080253F8                      @ 08025186  =mcFreqLo
	adds	r0, r0, r1                            @ 08025188
	ldrb	r0, [r0]                              @ 0802518A
	orrs	r2, r0                                @ 0802518C
	str	r2, [r6, #0x18]                        @ 0802518E
	movs	r6, #0                                @ 08025190
	ldrsh	r0, [r3, r6]                         @ 08025192
	mov	r7, r10                                @ 08025194
	str	r0, [r7, #0x44]                        @ 08025196
	ldr	r0, [r5]                               @ 08025198
	lsls	r0, r0, #0x18                         @ 0802519A
	lsrs	r0, r0, #0x10                         @ 0802519C
	orrs	r0, r2                                @ 0802519E
	ldr	r1, .Llit080253FC                      @ 080251A0  =REG_SOUND1CNT_X
	strh	r0, [r1]                              @ 080251A2
.L080251A4:
	ldrh	r3, [r3]                              @ 080251A4
	cmp	r3, #0xff                              @ 080251A6
	bne	.L080251B0                             @ 080251A8
	subs	r0, r4, #2                            @ 080251AA
	mov	r2, r10                                @ 080251AC
	str	r0, [r2, #0x40]                        @ 080251AE
.L080251B0:
	ldr	r3, [r5, #0x18]                        @ 080251B0
	cmp	r3, #0                                 @ 080251B2
	beq	.L0802522C                             @ 080251B4
	ldr	r4, [sp, #4]                           @ 080251B6
	lsls	r1, r4, #3                            @ 080251B8
	mov	r0, r12                                @ 080251BA
	adds	r0, #0x3c                             @ 080251BC
	adds	r6, r1, r0                            @ 080251BE
	ldr	r0, [r6]                               @ 080251C0
	subs	r0, #1                                @ 080251C2
	str	r0, [r6]                               @ 080251C4
	cmp	r0, #0                                 @ 080251C6
	bne	.L0802522C                             @ 080251C8
	mov	r0, r12                                @ 080251CA
	adds	r0, #0x38                             @ 080251CC
	adds	r4, r1, r0                            @ 080251CE
	ldr	r0, [r4]                               @ 080251D0
	adds	r0, #2                                @ 080251D2
	str	r0, [r4]                               @ 080251D4
	lsls	r0, r0, #1                            @ 080251D6
	adds	r0, r0, r3                            @ 080251D8
	ldrh	r7, [r0]                              @ 080251DA
	cmp	r7, #0xfe                              @ 080251DC
	bne	.L080251E6                             @ 080251DE
	movs	r2, #2                                @ 080251E0
	ldrsh	r0, [r0, r2]                         @ 080251E2
	str	r0, [r4]                               @ 080251E4
.L080251E6:
	ldr	r0, [r4]                               @ 080251E6
	lsls	r0, r0, #1                            @ 080251E8
	adds	r2, r0, r3                            @ 080251EA
	movs	r7, #0                                @ 080251EC
	ldrsh	r0, [r2, r7]                         @ 080251EE
	cmp	r0, #0xfd                              @ 080251F0
	bgt	.L0802521C                             @ 080251F2
	movs	r7, #2                                @ 080251F4
	ldrsh	r0, [r2, r7]                         @ 080251F6
	str	r0, [r6]                               @ 080251F8
	ldr	r0, .Llit080253E8                      @ 080251FA  =mcChan+CH_freq
	adds	r1, r1, r0                            @ 080251FC
	ldr	r2, [r1]                               @ 080251FE
	ldr	r0, [r4]                               @ 08025200
	lsls	r0, r0, #1                            @ 08025202
	adds	r0, r0, r3                            @ 08025204
	movs	r6, #0                                @ 08025206
	ldrsh	r0, [r0, r6]                         @ 08025208
	adds	r2, r2, r0                            @ 0802520A
	str	r2, [r1]                               @ 0802520C
	lsls	r1, r2, #0x10                         @ 0802520E
	ldr	r0, [r5]                               @ 08025210
	lsls	r0, r0, #0x18                         @ 08025212
	orrs	r0, r1                                @ 08025214
	lsrs	r2, r0, #0x10                         @ 08025216
	ldr	r7, .Llit080253FC                      @ 08025218  =REG_SOUND1CNT_X
	strh	r2, [r7]                              @ 0802521A
.L0802521C:
	ldr	r1, [r4]                               @ 0802521C
	lsls	r0, r1, #1                            @ 0802521E
	adds	r0, r0, r3                            @ 08025220
	ldrh	r0, [r0]                              @ 08025222
	cmp	r0, #0xff                              @ 08025224
	bne	.L0802522C                             @ 08025226
	subs	r0, r1, #2                            @ 08025228
	str	r0, [r4]                               @ 0802522A
.L0802522C:
	ldr	r3, [r5, #0x10]                        @ 0802522C
	cmp	r3, #0                                 @ 0802522E
	beq	.L080252B0                             @ 08025230
	ldr	r0, [sp, #4]                           @ 08025232
	lsls	r7, r0, #3                            @ 08025234
	mov	r0, r12                                @ 08025236
	adds	r0, #0x34                             @ 08025238
	adds	r6, r7, r0                            @ 0802523A
	ldr	r0, [r6]                               @ 0802523C
	subs	r0, #1                                @ 0802523E
	str	r0, [r6]                               @ 08025240
	cmp	r0, #0                                 @ 08025242
	bne	.L080252B0                             @ 08025244
	mov	r0, r12                                @ 08025246
	adds	r0, #0x30                             @ 08025248
	adds	r4, r7, r0                            @ 0802524A
	ldr	r0, [r4]                               @ 0802524C
	adds	r0, #2                                @ 0802524E
	str	r0, [r4]                               @ 08025250
	lsls	r0, r0, #1                            @ 08025252
	adds	r0, r0, r3                            @ 08025254
	ldrh	r1, [r0]                              @ 08025256
	cmp	r1, #0xfe                              @ 08025258
	bne	.L08025262                             @ 0802525A
	movs	r2, #2                                @ 0802525C
	ldrsh	r0, [r0, r2]                         @ 0802525E
	str	r0, [r4]                               @ 08025260
.L08025262:
	ldr	r0, [r4]                               @ 08025262
	lsls	r0, r0, #1                            @ 08025264
	adds	r1, r0, r3                            @ 08025266
	ldrh	r0, [r1]                              @ 08025268
	mov	r8, r0                                 @ 0802526A
	movs	r2, #0                                @ 0802526C
	ldrsh	r0, [r1, r2]                         @ 0802526E
	cmp	r0, #0xfd                              @ 08025270
	bgt	.L080252A0                             @ 08025272
	mov	r2, r8                                 @ 08025274
	lsls	r0, r2, #8                            @ 08025276
	ldrh	r2, [r5, #4]                          @ 08025278
	orrs	r0, r2                                @ 0802527A
	lsls	r0, r0, #0x10                         @ 0802527C
	lsrs	r2, r0, #0x10                         @ 0802527E
	ldr	r0, .Llit080253C0                      @ 08025280  =REG_SOUND1CNT_H
	strh	r2, [r0]                              @ 08025282
	movs	r2, #2                                @ 08025284
	ldrsh	r0, [r1, r2]                         @ 08025286
	str	r0, [r6]                               @ 08025288
	ldr	r1, [r5]                               @ 0802528A
	lsls	r1, r1, #8                            @ 0802528C
	ldr	r5, .Llit080253E8                      @ 0802528E  =mcChan+CH_freq
	adds	r0, r7, r5                            @ 08025290
	ldr	r0, [r0]                               @ 08025292
	orrs	r0, r1                                @ 08025294
	movs	r6, #0x80                             @ 08025296
	lsls	r6, r6, #8                            @ 08025298
	orrs	r0, r6                                @ 0802529A
	ldr	r7, .Llit080253FC                      @ 0802529C  =REG_SOUND1CNT_X
	strh	r0, [r7]                              @ 0802529E
.L080252A0:
	ldr	r1, [r4]                               @ 080252A0
	lsls	r0, r1, #1                            @ 080252A2
	adds	r0, r0, r3                            @ 080252A4
	ldrh	r0, [r0]                              @ 080252A6
	cmp	r0, #0xff                              @ 080252A8
	bne	.L080252B0                             @ 080252AA
	subs	r0, r1, #2                            @ 080252AC
	str	r0, [r4]                               @ 080252AE
.L080252B0:
	mov	r0, r9                                 @ 080252B0
	cmp	r0, #1                                 @ 080252B2
	beq	.L080252B8                             @ 080252B4
	b	.L08025488                               @ 080252B6
.L080252B8:
	mov	r1, r12                                @ 080252B8
	ldr	r0, [r1, #0x64]                        @ 080252BA
	lsls	r0, r0, #2                            @ 080252BC
	ldr	r2, .Llit080253F0                      @ 080252BE  =mcInstTable
	adds	r0, r0, r2                            @ 080252C0
	ldr	r5, [r0]                               @ 080252C2
	ldr	r3, [r5, #0x20]                        @ 080252C4
	cmp	r3, #0                                 @ 080252C6
	beq	.L08025340                             @ 080252C8
	mov	r7, r12                                @ 080252CA
	adds	r7, #0x8c                             @ 080252CC
	ldr	r0, [r7]                               @ 080252CE
	subs	r0, #1                                @ 080252D0
	str	r0, [r7]                               @ 080252D2
	cmp	r0, #0                                 @ 080252D4
	bne	.L08025340                             @ 080252D6
	mov	r6, r12                                @ 080252D8
	adds	r6, #0x88                             @ 080252DA
	ldr	r0, [r6]                               @ 080252DC
	adds	r0, #2                                @ 080252DE
	str	r0, [r6]                               @ 080252E0
	lsls	r0, r0, #1                            @ 080252E2
	adds	r0, r0, r3                            @ 080252E4
	ldrh	r4, [r0]                              @ 080252E6
	cmp	r4, #0xfe                              @ 080252E8
	bne	.L080252F2                             @ 080252EA
	movs	r1, #2                                @ 080252EC
	ldrsh	r0, [r0, r1]                         @ 080252EE
	str	r0, [r6]                               @ 080252F0
.L080252F2:
	ldr	r4, [r6]                               @ 080252F2
	lsls	r0, r4, #1                            @ 080252F4
	adds	r3, r0, r3                            @ 080252F6
	movs	r2, #0                                @ 080252F8
	ldrsh	r0, [r3, r2]                         @ 080252FA
	cmp	r0, #0xfd                              @ 080252FC
	bgt	.L08025336                             @ 080252FE
	movs	r0, #2                                @ 08025300
	ldrsh	r1, [r3, r0]                         @ 08025302
	mov	r2, r12                                @ 08025304
	ldr	r0, [r2, #0x5c]                        @ 08025306
	adds	r0, r0, r1                            @ 08025308
	ldr	r2, .Llit080253F4                      @ 0802530A  =mcFreqHi
	adds	r1, r0, r2                            @ 0802530C
	ldrb	r1, [r1]                              @ 0802530E
	lsls	r2, r1, #8                            @ 08025310
	ldr	r1, .Llit080253F8                      @ 08025312  =mcFreqLo
	adds	r0, r0, r1                            @ 08025314
	ldrb	r0, [r0]                              @ 08025316
	orrs	r2, r0                                @ 08025318
	mov	r0, r12                                @ 0802531A
	str	r2, [r0, #0x60]                        @ 0802531C
	movs	r1, #0                                @ 0802531E
	ldrsh	r0, [r3, r1]                         @ 08025320
	str	r0, [r7]                               @ 08025322
	mov	r2, r12                                @ 08025324
	ldr	r1, [r2, #0x60]                        @ 08025326
	lsls	r1, r1, #0x10                         @ 08025328
	ldr	r0, [r5]                               @ 0802532A
	lsls	r0, r0, #0x18                         @ 0802532C
	orrs	r0, r1                                @ 0802532E
	lsrs	r2, r0, #0x10                         @ 08025330
	ldr	r7, .Llit08025400                      @ 08025332  =REG_SOUND2CNT_H
	strh	r2, [r7]                              @ 08025334
.L08025336:
	ldrh	r3, [r3]                              @ 08025336
	cmp	r3, #0xff                              @ 08025338
	bne	.L08025340                             @ 0802533A
	subs	r0, r4, #2                            @ 0802533C
	str	r0, [r6]                               @ 0802533E
.L08025340:
	ldr	r3, [r5, #0x18]                        @ 08025340
	cmp	r3, #0                                 @ 08025342
	beq	.L08025404                             @ 08025344
	ldr	r0, [sp, #4]                           @ 08025346
	lsls	r1, r0, #3                            @ 08025348
	mov	r0, r12                                @ 0802534A
	adds	r0, #0x3c                             @ 0802534C
	adds	r6, r1, r0                            @ 0802534E
	ldr	r0, [r6]                               @ 08025350
	subs	r0, #1                                @ 08025352
	str	r0, [r6]                               @ 08025354
	cmp	r0, #0                                 @ 08025356
	bne	.L08025404                             @ 08025358
	mov	r0, r12                                @ 0802535A
	adds	r0, #0x38                             @ 0802535C
	adds	r4, r1, r0                            @ 0802535E
	ldr	r0, [r4]                               @ 08025360
	adds	r0, #2                                @ 08025362
	str	r0, [r4]                               @ 08025364
	lsls	r0, r0, #1                            @ 08025366
	adds	r0, r0, r3                            @ 08025368
	ldrh	r2, [r0]                              @ 0802536A
	cmp	r2, #0xfe                              @ 0802536C
	bne	.L08025376                             @ 0802536E
	movs	r7, #2                                @ 08025370
	ldrsh	r0, [r0, r7]                         @ 08025372
	str	r0, [r4]                               @ 08025374
.L08025376:
	ldr	r0, [r4]                               @ 08025376
	lsls	r0, r0, #1                            @ 08025378
	adds	r2, r0, r3                            @ 0802537A
	movs	r7, #0                                @ 0802537C
	ldrsh	r0, [r2, r7]                         @ 0802537E
	cmp	r0, #0xfd                              @ 08025380
	bgt	.L080253AC                             @ 08025382
	movs	r7, #2                                @ 08025384
	ldrsh	r0, [r2, r7]                         @ 08025386
	str	r0, [r6]                               @ 08025388
	ldr	r0, .Llit080253E8                      @ 0802538A  =mcChan+CH_freq
	adds	r1, r1, r0                            @ 0802538C
	ldr	r2, [r1]                               @ 0802538E
	ldr	r0, [r4]                               @ 08025390
	lsls	r0, r0, #1                            @ 08025392
	adds	r0, r0, r3                            @ 08025394
	movs	r6, #0                                @ 08025396
	ldrsh	r0, [r0, r6]                         @ 08025398
	adds	r2, r2, r0                            @ 0802539A
	str	r2, [r1]                               @ 0802539C
	lsls	r1, r2, #0x10                         @ 0802539E
	ldr	r0, [r5]                               @ 080253A0
	lsls	r0, r0, #0x18                         @ 080253A2
	orrs	r0, r1                                @ 080253A4
	lsrs	r2, r0, #0x10                         @ 080253A6
	ldr	r7, .Llit08025400                      @ 080253A8  =REG_SOUND2CNT_H
	strh	r2, [r7]                              @ 080253AA
.L080253AC:
	ldr	r1, [r4]                               @ 080253AC
	lsls	r0, r1, #1                            @ 080253AE
	adds	r0, r0, r3                            @ 080253B0
	ldrh	r0, [r0]                              @ 080253B2
	cmp	r0, #0xff                              @ 080253B4
	bne	.L08025404                             @ 080253B6
	subs	r0, r1, #2                            @ 080253B8
	str	r0, [r4]                               @ 080253BA
	b	.L08025404                               @ 080253BC
	.hword	0x0000                          @ 080253BE  (padding)
.Llit080253C0:
	.word	REG_SOUND1CNT_H                @ 080253C0  = 0x04000062
.Llit080253C4:
	.word	REG_SOUND2CNT_L                @ 080253C4  = 0x04000068
.Llit080253C8:
	.word	REG_SOUND3CNT_H                @ 080253C8  = 0x04000072
.Llit080253CC:
	.word	REG_SOUND4CNT_L                @ 080253CC  = 0x04000078
.Llit080253D0:
	.word	mcPaused                       @ 080253D0  = 0x0300665C
.Llit080253D4:
	.word	mcTempoAcc                     @ 080253D4  = 0x03006660
.Llit080253D8:
	.word	mcTempo                        @ 080253D8  = 0x03006658
.Llit080253DC:
	.word	0xFFFFFF00                     @ 080253DC
.Llit080253E0:
	.word	mcChan                         @ 080253E0  = 0x030066B0
.Llit080253E4:
	.word	mcChan+CH_patPtr               @ 080253E4  = 0x030066D4
.Llit080253E8:
	.word	mcChan+CH_freq                 @ 080253E8  = 0x030066C8
.Llit080253EC:
	.word	mcChan+CH_patPos               @ 080253EC  = 0x030066BC
.Llit080253F0:
	.word	mcInstTable                    @ 080253F0  = 0x083FF834
.Llit080253F4:
	.word	mcFreqHi                       @ 080253F4  = 0x083FF2AD
.Llit080253F8:
	.word	mcFreqLo                       @ 080253F8  = 0x083FF24C
.Llit080253FC:
	.word	REG_SOUND1CNT_X                @ 080253FC  = 0x04000064
.Llit08025400:
	.word	REG_SOUND2CNT_H                @ 08025400  = 0x0400006C
.L08025404:
	ldr	r3, [r5, #0x10]                        @ 08025404
	cmp	r3, #0                                 @ 08025406
	beq	.L08025488                             @ 08025408
	ldr	r0, [sp, #4]                           @ 0802540A
	lsls	r7, r0, #3                            @ 0802540C
	mov	r0, r12                                @ 0802540E
	adds	r0, #0x34                             @ 08025410
	adds	r6, r7, r0                            @ 08025412
	ldr	r0, [r6]                               @ 08025414
	subs	r0, #1                                @ 08025416
	str	r0, [r6]                               @ 08025418
	cmp	r0, #0                                 @ 0802541A
	bne	.L08025488                             @ 0802541C
	mov	r0, r12                                @ 0802541E
	adds	r0, #0x30                             @ 08025420
	adds	r4, r7, r0                            @ 08025422
	ldr	r0, [r4]                               @ 08025424
	adds	r0, #2                                @ 08025426
	str	r0, [r4]                               @ 08025428
	lsls	r0, r0, #1                            @ 0802542A
	adds	r0, r0, r3                            @ 0802542C
	ldrh	r1, [r0]                              @ 0802542E
	cmp	r1, #0xfe                              @ 08025430
	bne	.L0802543A                             @ 08025432
	movs	r2, #2                                @ 08025434
	ldrsh	r0, [r0, r2]                         @ 08025436
	str	r0, [r4]                               @ 08025438
.L0802543A:
	ldr	r0, [r4]                               @ 0802543A
	lsls	r0, r0, #1                            @ 0802543C
	adds	r1, r0, r3                            @ 0802543E
	ldrh	r0, [r1]                              @ 08025440
	mov	r8, r0                                 @ 08025442
	movs	r2, #0                                @ 08025444
	ldrsh	r0, [r1, r2]                         @ 08025446
	cmp	r0, #0xfd                              @ 08025448
	bgt	.L08025478                             @ 0802544A
	mov	r2, r8                                 @ 0802544C
	lsls	r0, r2, #8                            @ 0802544E
	ldrh	r2, [r5, #4]                          @ 08025450
	orrs	r0, r2                                @ 08025452
	lsls	r0, r0, #0x10                         @ 08025454
	lsrs	r2, r0, #0x10                         @ 08025456
	ldr	r0, .Llit0802565C                      @ 08025458  =REG_SOUND2CNT_L
	strh	r2, [r0]                              @ 0802545A
	movs	r2, #2                                @ 0802545C
	ldrsh	r0, [r1, r2]                         @ 0802545E
	str	r0, [r6]                               @ 08025460
	ldr	r1, [r5]                               @ 08025462
	lsls	r1, r1, #8                            @ 08025464
	ldr	r5, .Llit08025660                      @ 08025466  =mcChan+CH_freq
	adds	r0, r7, r5                            @ 08025468
	ldr	r0, [r0]                               @ 0802546A
	orrs	r0, r1                                @ 0802546C
	movs	r6, #0x80                             @ 0802546E
	lsls	r6, r6, #8                            @ 08025470
	orrs	r0, r6                                @ 08025472
	ldr	r7, .Llit08025664                      @ 08025474  =REG_SOUND2CNT_H
	strh	r0, [r7]                              @ 08025476
.L08025478:
	ldr	r1, [r4]                               @ 08025478
	lsls	r0, r1, #1                            @ 0802547A
	adds	r0, r0, r3                            @ 0802547C
	ldrh	r0, [r0]                              @ 0802547E
	cmp	r0, #0xff                              @ 08025480
	bne	.L08025488                             @ 08025482
	subs	r0, r1, #2                            @ 08025484
	str	r0, [r4]                               @ 08025486
.L08025488:
	mov	r0, r9                                 @ 08025488
	cmp	r0, #2                                 @ 0802548A
	beq	.L08025490                             @ 0802548C
	b	.L08025616                               @ 0802548E
.L08025490:
	mov	r0, r12                                @ 08025490
	adds	r0, #0xac                             @ 08025492
	ldr	r0, [r0]                               @ 08025494
	lsls	r0, r0, #2                            @ 08025496
	ldr	r1, .Llit08025668                      @ 08025498  =mcInstTable
	adds	r0, r0, r1                            @ 0802549A
	ldr	r5, [r0]                               @ 0802549C
	ldr	r3, [r5, #0x20]                        @ 0802549E
	cmp	r3, #0                                 @ 080254A0
	beq	.L08025516                             @ 080254A2
	mov	r7, r12                                @ 080254A4
	adds	r7, #0xd4                             @ 080254A6
	ldr	r0, [r7]                               @ 080254A8
	subs	r0, #1                                @ 080254AA
	str	r0, [r7]                               @ 080254AC
	cmp	r0, #0                                 @ 080254AE
	bne	.L08025516                             @ 080254B0
	mov	r6, r12                                @ 080254B2
	adds	r6, #0xd0                             @ 080254B4
	ldr	r0, [r6]                               @ 080254B6
	adds	r0, #2                                @ 080254B8
	str	r0, [r6]                               @ 080254BA
	lsls	r0, r0, #1                            @ 080254BC
	adds	r0, r0, r3                            @ 080254BE
	ldrh	r2, [r0]                              @ 080254C0
	cmp	r2, #0xfe                              @ 080254C2
	bne	.L080254CC                             @ 080254C4
	movs	r4, #2                                @ 080254C6
	ldrsh	r0, [r0, r4]                         @ 080254C8
	str	r0, [r6]                               @ 080254CA
.L080254CC:
	ldr	r4, [r6]                               @ 080254CC
	lsls	r0, r4, #1                            @ 080254CE
	adds	r3, r0, r3                            @ 080254D0
	movs	r1, #0                                @ 080254D2
	ldrsh	r0, [r3, r1]                         @ 080254D4
	cmp	r0, #0xfd                              @ 080254D6
	bgt	.L0802550C                             @ 080254D8
	mov	r0, r12                                @ 080254DA
	adds	r0, #0xa4                             @ 080254DC
	movs	r2, #2                                @ 080254DE
	ldrsh	r1, [r3, r2]                         @ 080254E0
	ldr	r0, [r0]                               @ 080254E2
	adds	r0, r0, r1                            @ 080254E4
	ldr	r2, .Llit0802566C                      @ 080254E6  =mcFreqHi
	adds	r1, r0, r2                            @ 080254E8
	ldrb	r1, [r1]                              @ 080254EA
	lsls	r2, r1, #8                            @ 080254EC
	ldr	r1, .Llit08025670                      @ 080254EE  =mcFreqLo
	adds	r0, r0, r1                            @ 080254F0
	ldrb	r0, [r0]                              @ 080254F2
	orrs	r2, r0                                @ 080254F4
	ldr	r0, .Llit08025674                      @ 080254F6  =mcChan+0x90+CH_freq
	str	r2, [r0]                               @ 080254F8
	movs	r1, #0                                @ 080254FA
	ldrsh	r0, [r3, r1]                         @ 080254FC
	str	r0, [r7]                               @ 080254FE
	ldr	r0, [r5]                               @ 08025500
	lsls	r0, r0, #0x18                         @ 08025502
	lsrs	r0, r0, #0x10                         @ 08025504
	orrs	r0, r2                                @ 08025506
	ldr	r2, .Llit08025678                      @ 08025508  =REG_SOUND3CNT_X
	strh	r0, [r2]                              @ 0802550A
.L0802550C:
	ldrh	r3, [r3]                              @ 0802550C
	cmp	r3, #0xff                              @ 0802550E
	bne	.L08025516                             @ 08025510
	subs	r0, r4, #2                            @ 08025512
	str	r0, [r6]                               @ 08025514
.L08025516:
	ldr	r3, [r5, #0x18]                        @ 08025516
	cmp	r3, #0                                 @ 08025518
	beq	.L08025592                             @ 0802551A
	ldr	r4, [sp, #4]                           @ 0802551C
	lsls	r1, r4, #3                            @ 0802551E
	mov	r0, r12                                @ 08025520
	adds	r0, #0x3c                             @ 08025522
	adds	r6, r1, r0                            @ 08025524
	ldr	r0, [r6]                               @ 08025526
	subs	r0, #1                                @ 08025528
	str	r0, [r6]                               @ 0802552A
	cmp	r0, #0                                 @ 0802552C
	bne	.L08025592                             @ 0802552E
	mov	r0, r12                                @ 08025530
	adds	r0, #0x38                             @ 08025532
	adds	r4, r1, r0                            @ 08025534
	ldr	r0, [r4]                               @ 08025536
	adds	r0, #2                                @ 08025538
	str	r0, [r4]                               @ 0802553A
	lsls	r0, r0, #1                            @ 0802553C
	adds	r0, r0, r3                            @ 0802553E
	ldrh	r7, [r0]                              @ 08025540
	cmp	r7, #0xfe                              @ 08025542
	bne	.L0802554C                             @ 08025544
	movs	r2, #2                                @ 08025546
	ldrsh	r0, [r0, r2]                         @ 08025548
	str	r0, [r4]                               @ 0802554A
.L0802554C:
	ldr	r0, [r4]                               @ 0802554C
	lsls	r0, r0, #1                            @ 0802554E
	adds	r2, r0, r3                            @ 08025550
	movs	r7, #0                                @ 08025552
	ldrsh	r0, [r2, r7]                         @ 08025554
	cmp	r0, #0xfd                              @ 08025556
	bgt	.L08025582                             @ 08025558
	movs	r7, #2                                @ 0802555A
	ldrsh	r0, [r2, r7]                         @ 0802555C
	str	r0, [r6]                               @ 0802555E
	ldr	r0, .Llit08025660                      @ 08025560  =mcChan+CH_freq
	adds	r1, r1, r0                            @ 08025562
	ldr	r2, [r1]                               @ 08025564
	ldr	r0, [r4]                               @ 08025566
	lsls	r0, r0, #1                            @ 08025568
	adds	r0, r0, r3                            @ 0802556A
	movs	r6, #0                                @ 0802556C
	ldrsh	r0, [r0, r6]                         @ 0802556E
	adds	r2, r2, r0                            @ 08025570
	str	r2, [r1]                               @ 08025572
	lsls	r1, r2, #0x10                         @ 08025574
	ldr	r0, [r5]                               @ 08025576
	lsls	r0, r0, #0x18                         @ 08025578
	orrs	r0, r1                                @ 0802557A
	lsrs	r2, r0, #0x10                         @ 0802557C
	ldr	r7, .Llit08025678                      @ 0802557E  =REG_SOUND3CNT_X
	strh	r2, [r7]                              @ 08025580
.L08025582:
	ldr	r1, [r4]                               @ 08025582
	lsls	r0, r1, #1                            @ 08025584
	adds	r0, r0, r3                            @ 08025586
	ldrh	r0, [r0]                              @ 08025588
	cmp	r0, #0xff                              @ 0802558A
	bne	.L08025592                             @ 0802558C
	subs	r0, r1, #2                            @ 0802558E
	str	r0, [r4]                               @ 08025590
.L08025592:
	ldr	r3, [r5, #0x10]                        @ 08025592
	cmp	r3, #0                                 @ 08025594
	beq	.L08025616                             @ 08025596
	ldr	r0, [sp, #4]                           @ 08025598
	lsls	r7, r0, #3                            @ 0802559A
	mov	r0, r12                                @ 0802559C
	adds	r0, #0x34                             @ 0802559E
	adds	r6, r7, r0                            @ 080255A0
	ldr	r0, [r6]                               @ 080255A2
	subs	r0, #1                                @ 080255A4
	str	r0, [r6]                               @ 080255A6
	cmp	r0, #0                                 @ 080255A8
	bne	.L08025616                             @ 080255AA
	mov	r0, r12                                @ 080255AC
	adds	r0, #0x30                             @ 080255AE
	adds	r4, r7, r0                            @ 080255B0
	ldr	r0, [r4]                               @ 080255B2
	adds	r0, #2                                @ 080255B4
	str	r0, [r4]                               @ 080255B6
	lsls	r0, r0, #1                            @ 080255B8
	adds	r0, r0, r3                            @ 080255BA
	ldrh	r1, [r0]                              @ 080255BC
	cmp	r1, #0xfe                              @ 080255BE
	bne	.L080255C8                             @ 080255C0
	movs	r2, #2                                @ 080255C2
	ldrsh	r0, [r0, r2]                         @ 080255C4
	str	r0, [r4]                               @ 080255C6
.L080255C8:
	ldr	r0, [r4]                               @ 080255C8
	lsls	r0, r0, #1                            @ 080255CA
	adds	r1, r0, r3                            @ 080255CC
	ldrh	r0, [r1]                              @ 080255CE
	mov	r8, r0                                 @ 080255D0
	movs	r2, #0                                @ 080255D2
	ldrsh	r0, [r1, r2]                         @ 080255D4
	cmp	r0, #0xfd                              @ 080255D6
	bgt	.L08025606                             @ 080255D8
	mov	r2, r8                                 @ 080255DA
	lsls	r0, r2, #8                            @ 080255DC
	ldrh	r2, [r5, #4]                          @ 080255DE
	orrs	r0, r2                                @ 080255E0
	lsls	r0, r0, #0x10                         @ 080255E2
	lsrs	r2, r0, #0x10                         @ 080255E4
	ldr	r0, .Llit0802567C                      @ 080255E6  =REG_SOUND3CNT_H
	strh	r2, [r0]                              @ 080255E8
	movs	r2, #2                                @ 080255EA
	ldrsh	r0, [r1, r2]                         @ 080255EC
	str	r0, [r6]                               @ 080255EE
	ldr	r1, [r5]                               @ 080255F0
	lsls	r1, r1, #8                            @ 080255F2
	ldr	r5, .Llit08025660                      @ 080255F4  =mcChan+CH_freq
	adds	r0, r7, r5                            @ 080255F6
	ldr	r0, [r0]                               @ 080255F8
	orrs	r0, r1                                @ 080255FA
	movs	r6, #0x80                             @ 080255FC
	lsls	r6, r6, #8                            @ 080255FE
	orrs	r0, r6                                @ 08025600
	ldr	r7, .Llit08025678                      @ 08025602  =REG_SOUND3CNT_X
	strh	r0, [r7]                              @ 08025604
.L08025606:
	ldr	r1, [r4]                               @ 08025606
	lsls	r0, r1, #1                            @ 08025608
	adds	r0, r0, r3                            @ 0802560A
	ldrh	r0, [r0]                              @ 0802560C
	cmp	r0, #0xff                              @ 0802560E
	bne	.L08025616                             @ 08025610
	subs	r0, r1, #2                            @ 08025612
	str	r0, [r4]                               @ 08025614
.L08025616:
	mov	r0, r9                                 @ 08025616
	cmp	r0, #3                                 @ 08025618
	bne	.L080256F0                             @ 0802561A
	mov	r0, r12                                @ 0802561C
	adds	r0, #0xf4                             @ 0802561E
	ldr	r0, [r0]                               @ 08025620
	lsls	r0, r0, #2                            @ 08025622
	ldr	r1, .Llit08025668                      @ 08025624  =mcInstTable
	adds	r0, r0, r1                            @ 08025626
	ldr	r5, [r0]                               @ 08025628
	ldr	r3, [r5, #0x18]                        @ 0802562A
	cmp	r3, #0                                 @ 0802562C
	beq	.L08025696                             @ 0802562E
	movs	r6, #0x8a                             @ 08025630
	lsls	r6, r6, #1                            @ 08025632
	add	r6, r12                                @ 08025634
	ldr	r0, [r6]                               @ 08025636
	subs	r0, #1                                @ 08025638
	str	r0, [r6]                               @ 0802563A
	cmp	r0, #0                                 @ 0802563C
	bne	.L08025696                             @ 0802563E
	movs	r4, #0x88                             @ 08025640
	lsls	r4, r4, #1                            @ 08025642
	add	r4, r12                                @ 08025644
	ldr	r2, [r4]                               @ 08025646
	adds	r0, r2, #2                            @ 08025648
	str	r0, [r4]                               @ 0802564A
	lsls	r0, r0, #1                            @ 0802564C
	adds	r1, r0, r3                            @ 0802564E
	ldrh	r3, [r1]                              @ 08025650
	cmp	r3, #0xff                              @ 08025652
	bne	.L08025680                             @ 08025654
	str	r2, [r4]                               @ 08025656
	b	.L08025696                               @ 08025658
	.hword	0x0000                          @ 0802565A  (padding)
.Llit0802565C:
	.word	REG_SOUND2CNT_L                @ 0802565C  = 0x04000068
.Llit08025660:
	.word	mcChan+CH_freq                 @ 08025660  = 0x030066C8
.Llit08025664:
	.word	REG_SOUND2CNT_H                @ 08025664  = 0x0400006C
.Llit08025668:
	.word	mcInstTable                    @ 08025668  = 0x083FF834
.Llit0802566C:
	.word	mcFreqHi                       @ 0802566C  = 0x083FF2AD
.Llit08025670:
	.word	mcFreqLo                       @ 08025670  = 0x083FF24C
.Llit08025674:
	.word	mcChan+0x90+CH_freq            @ 08025674  = 0x03006758
.Llit08025678:
	.word	REG_SOUND3CNT_X                @ 08025678  = 0x04000074
.Llit0802567C:
	.word	REG_SOUND3CNT_H                @ 0802567C  = 0x04000072
.L08025680:
	ldr	r0, [r5]                               @ 08025680
	lsls	r0, r0, #8                            @ 08025682
	ldrh	r4, [r1]                              @ 08025684
	orrs	r0, r4                                @ 08025686
	lsls	r0, r0, #0x10                         @ 08025688
	lsrs	r2, r0, #0x10                         @ 0802568A
	movs	r7, #2                                @ 0802568C
	ldrsh	r0, [r1, r7]                         @ 0802568E
	str	r0, [r6]                               @ 08025690
	ldr	r0, .Llit080256CC                      @ 08025692  =REG_SOUND4CNT_H
	strh	r2, [r0]                              @ 08025694
.L08025696:
	ldr	r3, [r5, #0x10]                        @ 08025696
	cmp	r3, #0                                 @ 08025698
	beq	.L080256F0                             @ 0802569A
	ldr	r0, [sp, #4]                           @ 0802569C
	lsls	r1, r0, #3                            @ 0802569E
	mov	r0, r10                                @ 080256A0
	adds	r0, #0x34                             @ 080256A2
	adds	r6, r1, r0                            @ 080256A4
	ldr	r0, [r6]                               @ 080256A6
	subs	r0, #1                                @ 080256A8
	str	r0, [r6]                               @ 080256AA
	cmp	r0, #0                                 @ 080256AC
	bne	.L080256F0                             @ 080256AE
	mov	r0, r12                                @ 080256B0
	adds	r0, #0x30                             @ 080256B2
	adds	r2, r1, r0                            @ 080256B4
	ldr	r1, [r2]                               @ 080256B6
	adds	r0, r1, #2                            @ 080256B8
	str	r0, [r2]                               @ 080256BA
	lsls	r0, r0, #1                            @ 080256BC
	adds	r3, r0, r3                            @ 080256BE
	ldrh	r4, [r3]                              @ 080256C0
	cmp	r4, #0xff                              @ 080256C2
	bne	.L080256D0                             @ 080256C4
	str	r1, [r2]                               @ 080256C6
	b	.L080256F0                               @ 080256C8
	.hword	0x0000                          @ 080256CA  (padding)
.Llit080256CC:
	.word	REG_SOUND4CNT_H                @ 080256CC  = 0x0400007C
.L080256D0:
	ldr	r0, [r5, #4]                           @ 080256D0
	lsls	r1, r4, #8                            @ 080256D2
	orrs	r0, r1                                @ 080256D4
	lsls	r0, r0, #0x10                         @ 080256D6
	lsrs	r2, r0, #0x10                         @ 080256D8
	ldr	r0, .Llit08025730                      @ 080256DA  =REG_SOUND4CNT_L
	strh	r2, [r0]                              @ 080256DC
	movs	r1, #2                                @ 080256DE
	ldrsh	r0, [r3, r1]                         @ 080256E0
	str	r0, [r6]                               @ 080256E2
	ldr	r1, .Llit08025734                      @ 080256E4  =REG_SOUND4CNT_H
	ldrh	r0, [r1]                              @ 080256E6
	movs	r2, #0x80                             @ 080256E8
	lsls	r2, r2, #8                            @ 080256EA
	orrs	r0, r2                                @ 080256EC
	strh	r0, [r1]                              @ 080256EE
.L080256F0:
	ldr	r3, [sp, #0xc]                         @ 080256F0
	ldr	r0, [r3]                               @ 080256F2
	cmp	r0, #0                                 @ 080256F4
	beq	.L080256FA                             @ 080256F6
	b	.L08025C62                               @ 080256F8
.L080256FA:
	ldr	r4, [sp, #0x10]                        @ 080256FA
	ldr	r0, [r4]                               @ 080256FC
	cmp	r0, #0                                 @ 080256FE
	beq	.L08025704                             @ 08025700
	b	.L0802583A                               @ 08025702
.L08025704:
	ldr	r7, .Llit08025738                      @ 08025704  =mcChan
	ldr	r0, [sp, #0x2c]                        @ 08025706
	add	r0, r9                                 @ 08025708
	lsls	r6, r0, #3                            @ 0802570A
	adds	r0, r7, #0                            @ 0802570C
	adds	r0, #8                                @ 0802570E
	adds	r3, r6, r0                            @ 08025710
	adds	r0, r7, #4                            @ 08025712
	adds	r0, r6, r0                            @ 08025714
	str	r0, [sp, #0x14]                        @ 08025716
	adds	r0, r7, #0                            @ 08025718
	adds	r0, #0x10                             @ 0802571A
	adds	r0, r6, r0                            @ 0802571C
	str	r0, [sp, #0x1c]                        @ 0802571E
	movs	r5, #0                                @ 08025720
	mov	r8, r5                                 @ 08025722
	adds	r0, r7, #0                            @ 08025724
	adds	r0, #0x28                             @ 08025726
	adds	r0, r6, r0                            @ 08025728
	str	r0, [sp, #0x18]                        @ 0802572A
	b	.L08025740                               @ 0802572C
	.hword	0x0000                          @ 0802572E  (padding)
.Llit08025730:
	.word	REG_SOUND4CNT_L                @ 08025730  = 0x04000078
.Llit08025734:
	.word	REG_SOUND4CNT_H                @ 08025734  = 0x0400007C
.Llit08025738:
	.word	mcChan                         @ 08025738  = 0x030066B0
.L0802573C:
	cmp	r4, #0x61                              @ 0802573C  SEQ_END
	beq	.L08025830                             @ 0802573E
.L08025740:
	adds	r0, r7, #0                            @ 08025740
	adds	r0, #0x20                             @ 08025742
	adds	r0, r6, r0                            @ 08025744
	ldr	r5, [r0]                               @ 08025746
	ldr	r2, [r3]                               @ 08025748
	lsls	r0, r2, #2                            @ 0802574A
	adds	r0, r0, r5                            @ 0802574C
	ldr	r4, [r0]                               @ 0802574E
	cmp	r4, #0x67                              @ 08025750  SEQ_PAN
	bne	.L08025766                             @ 08025752
	ldr	r0, [r0, #4]                           @ 08025754
	lsls	r0, r0, #8                            @ 08025756
	adds	r0, #0x77                             @ 08025758
	ldr	r1, .Llit08025874                      @ 0802575A  =mcMasterPan
	str	r0, [r1]                               @ 0802575C
	ldr	r1, .Llit08025878                      @ 0802575E  =REG_SOUNDCNT_L
	strh	r0, [r1]                              @ 08025760
	adds	r0, r2, #2                            @ 08025762
	str	r0, [r3]                               @ 08025764
.L08025766:
	cmp	r4, #0x69                              @ 08025766  SEQ_TEMPO
	bne	.L0802577A                             @ 08025768
	ldr	r0, [r3]                               @ 0802576A
	lsls	r1, r0, #2                            @ 0802576C
	adds	r1, r1, r5                            @ 0802576E
	ldr	r1, [r1, #4]                           @ 08025770
	ldr	r2, .Llit0802587C                      @ 08025772  =mcTempo
	str	r1, [r2]                               @ 08025774
	adds	r0, #2                                @ 08025776
	str	r0, [r3]                               @ 08025778
.L0802577A:
	cmp	r4, #0x60                              @ 0802577A  rest / cmd 0x60
	bne	.L08025784                             @ 0802577C
	ldr	r0, [r3]                               @ 0802577E
	adds	r0, #3                                @ 08025780
	str	r0, [r3]                               @ 08025782
.L08025784:
	cmp	r4, #0x66                              @ 08025784  SEQ_CONDFLAG
	bne	.L08025798                             @ 08025786
	ldr	r0, [r3]                               @ 08025788
	lsls	r1, r0, #2                            @ 0802578A
	adds	r1, r1, r5                            @ 0802578C
	ldr	r1, [r1, #4]                           @ 0802578E
	ldr	r2, .Llit08025880                      @ 08025790  =mcCondFlag
	str	r1, [r2]                               @ 08025792
	adds	r0, #2                                @ 08025794
	str	r0, [r3]                               @ 08025796
.L08025798:
	cmp	r4, #0x61                              @ 08025798  SEQ_END
	bne	.L080257E4                             @ 0802579A
	ldr	r1, [sp, #0x14]                        @ 0802579C
	ldr	r0, [r1]                               @ 0802579E
	cmp	r0, #0                                 @ 080257A0
	beq	.L080257E4                             @ 080257A2
	mov	r2, r9                                 @ 080257A4
	cmp	r2, #0                                 @ 080257A6
	bne	.L080257B4                             @ 080257A8
	ldr	r0, .Llit08025884                      @ 080257AA  =REG_SOUND1CNT_H
	strh	r2, [r0]                              @ 080257AC
	mov	r1, r9                                 @ 080257AE
	adds	r0, #2                                @ 080257B0
	strh	r1, [r0]                              @ 080257B2
.L080257B4:
	mov	r2, r9                                 @ 080257B4
	cmp	r2, #1                                 @ 080257B6
	bne	.L080257C4                             @ 080257B8
	ldr	r0, .Llit08025888                      @ 080257BA  =REG_SOUND2CNT_L
	mov	r1, r8                                 @ 080257BC
	strh	r1, [r0]                              @ 080257BE
	ldr	r2, .Llit0802588C                      @ 080257C0  =REG_SOUND2CNT_H
	strh	r1, [r2]                              @ 080257C2
.L080257C4:
	mov	r0, r9                                 @ 080257C4
	cmp	r0, #2                                 @ 080257C6
	bne	.L080257D4                             @ 080257C8
	ldr	r0, .Llit08025890                      @ 080257CA  =REG_SOUND3CNT_H
	mov	r1, r8                                 @ 080257CC
	strh	r1, [r0]                              @ 080257CE
	ldr	r2, .Llit08025894                      @ 080257D0  =REG_SOUND3CNT_X
	strh	r1, [r2]                              @ 080257D2
.L080257D4:
	mov	r0, r9                                 @ 080257D4
	cmp	r0, #3                                 @ 080257D6
	bne	.L080257E4                             @ 080257D8
	ldr	r0, .Llit08025898                      @ 080257DA  =REG_SOUND4CNT_L
	mov	r1, r8                                 @ 080257DC
	strh	r1, [r0]                              @ 080257DE
	adds	r0, #4                                @ 080257E0
	strh	r1, [r0]                              @ 080257E2
.L080257E4:
	cmp	r4, #0x64                              @ 080257E4  SEQ_PAT
	bne	.L0802581E                             @ 080257E6
	ldr	r0, [r3]                               @ 080257E8
	lsls	r0, r0, #2                            @ 080257EA
	adds	r0, r0, r5                            @ 080257EC
	ldr	r0, [r0, #8]                           @ 080257EE
	ldr	r2, [sp, #0x18]                        @ 080257F0
	str	r0, [r2]                               @ 080257F2
	ldr	r0, .Llit0802589C                      @ 080257F4  =mcChan+CH_patPtr
	adds	r1, r6, r0                            @ 080257F6
	ldr	r2, [r3]                               @ 080257F8
	lsls	r2, r2, #2                            @ 080257FA
	adds	r2, r2, r5                            @ 080257FC
	ldr	r0, [r2, #4]                           @ 080257FE
	str	r0, [r1]                               @ 08025800
	adds	r1, r7, #0                            @ 08025802
	adds	r1, #0x2c                             @ 08025804
	adds	r1, r6, r1                            @ 08025806
	ldr	r0, [r2, #0xc]                         @ 08025808
	str	r0, [r1]                               @ 0802580A
	ldr	r1, .Llit080258A0                      @ 0802580C  =mcChan+CH_patPos
	adds	r0, r6, r1                            @ 0802580E
	movs	r2, #0                                @ 08025810
	str	r2, [r0]                               @ 08025812
	ldr	r0, [sp, #0x1c]                        @ 08025814
	str	r2, [r0]                               @ 08025816
	ldr	r0, [r3]                               @ 08025818
	adds	r0, #4                                @ 0802581A
	str	r0, [r3]                               @ 0802581C
.L0802581E:
	cmp	r4, #0x62                              @ 0802581E  SEQ_JUMP
	bne	.L0802582C                             @ 08025820
	ldr	r0, [r3]                               @ 08025822
	lsls	r0, r0, #2                            @ 08025824
	adds	r0, r0, r5                            @ 08025826
	ldr	r0, [r0, #4]                           @ 08025828
	str	r0, [r3]                               @ 0802582A
.L0802582C:
	cmp	r4, #0x64                              @ 0802582C  SEQ_PAT
	bne	.L0802573C                             @ 0802582E
.L08025830:
	ldr	r1, [sp, #0x10]                        @ 08025830
	ldr	r0, [r1]                               @ 08025832
	cmp	r0, #0                                 @ 08025834
	bne	.L0802583A                             @ 08025836
	b	.L08025C62                               @ 08025838
.L0802583A:
	ldr	r2, [sp, #4]                           @ 0802583A
	lsls	r1, r2, #3                            @ 0802583C
	ldr	r4, .Llit0802589C                      @ 0802583E  =mcChan+CH_patPtr
	adds	r3, r1, r4                            @ 08025840
	ldr	r4, [r3]                               @ 08025842
	ldr	r5, .Llit080258A0                      @ 08025844  =mcChan+CH_patPos
	adds	r2, r1, r5                            @ 08025846
	ldr	r0, [r2]                               @ 08025848
	adds	r0, r4, r0                            @ 0802584A
	ldrb	r0, [r0]                              @ 0802584C
	str	r0, [sp]                               @ 0802584E
	cmp	r0, #0x65                              @ 08025850  pattern end
	bne	.L080258B0                             @ 08025852
	mov	r0, r12                                @ 08025854
	adds	r0, #0x2c                             @ 08025856
	adds	r1, r1, r0                            @ 08025858
	ldr	r0, [r1]                               @ 0802585A
	cmp	r0, #0                                 @ 0802585C
	beq	.L080258A4                             @ 0802585E
	subs	r0, #1                                @ 08025860
	str	r0, [r1]                               @ 08025862
	cmp	r0, #0                                 @ 08025864
	beq	.L080258A4                             @ 08025866
	movs	r6, #0                                @ 08025868
	str	r6, [r2]                               @ 0802586A
	ldrb	r7, [r4]                              @ 0802586C
	str	r7, [sp]                               @ 0802586E
	b	.L080258A8                               @ 08025870
	.hword	0x0000                          @ 08025872  (padding)
.Llit08025874:
	.word	mcMasterPan                    @ 08025874  = 0x03006664
.Llit08025878:
	.word	REG_SOUNDCNT_L                 @ 08025878  = 0x04000080
.Llit0802587C:
	.word	mcTempo                        @ 0802587C  = 0x03006658
.Llit08025880:
	.word	mcCondFlag                     @ 08025880  = 0x03006860
.Llit08025884:
	.word	REG_SOUND1CNT_H                @ 08025884  = 0x04000062
.Llit08025888:
	.word	REG_SOUND2CNT_L                @ 08025888  = 0x04000068
.Llit0802588C:
	.word	REG_SOUND2CNT_H                @ 0802588C  = 0x0400006C
.Llit08025890:
	.word	REG_SOUND3CNT_H                @ 08025890  = 0x04000072
.Llit08025894:
	.word	REG_SOUND3CNT_X                @ 08025894  = 0x04000074
.Llit08025898:
	.word	REG_SOUND4CNT_L                @ 08025898  = 0x04000078
.Llit0802589C:
	.word	mcChan+CH_patPtr               @ 0802589C  = 0x030066D4
.Llit080258A0:
	.word	mcChan+CH_patPos               @ 080258A0  = 0x030066BC
.L080258A4:
	str	r0, [r3]                               @ 080258A4
	str	r0, [r2]                               @ 080258A6
.L080258A8:
	ldr	r0, [sp]                               @ 080258A8
	cmp	r0, #0x65                              @ 080258AA  pattern end
	bne	.L080258B0                             @ 080258AC
	b	.L080250E0                               @ 080258AE
.L080258B0:
	ldr	r2, [sp, #4]                           @ 080258B0
	lsls	r1, r2, #3                            @ 080258B2
	ldr	r3, .Llit080258D4                      @ 080258B4  =mcChan+CH_patPos
	adds	r0, r1, r3                            @ 080258B6
	ldr	r0, [r0]                               @ 080258B8
	adds	r0, r4, r0                            @ 080258BA
	ldrb	r6, [r0]                              @ 080258BC
	cmp	r6, #0x60                              @ 080258BE  rest / cmd 0x60
	beq	.L080258D8                             @ 080258C0
	mov	r0, r12                                @ 080258C2
	adds	r0, #0x28                             @ 080258C4
	adds	r0, r1, r0                            @ 080258C6
	ldr	r0, [r0]                               @ 080258C8
	adds	r0, r6, r0                            @ 080258CA
	lsls	r0, r0, #0x18                         @ 080258CC
	lsrs	r6, r0, #0x18                         @ 080258CE
	b	.L080258DA                               @ 080258D0
	.hword	0x0000                          @ 080258D2  (padding)
.Llit080258D4:
	.word	mcChan+CH_patPos               @ 080258D4  = 0x030066BC
.L080258D8:
	movs	r6, #0x30                             @ 080258D8
.L080258DA:
	mov	r0, r12                                @ 080258DA
	adds	r0, #0x14                             @ 080258DC
	ldr	r5, [sp, #8]                           @ 080258DE
	adds	r0, r5, r0                            @ 080258E0
	str	r6, [r0]                               @ 080258E2
	ldr	r7, .Llit080259C4                      @ 080258E4  =mcFreqHi
	adds	r0, r6, r7                            @ 080258E6
	ldrb	r0, [r0]                              @ 080258E8
	lsls	r1, r0, #8                            @ 080258EA
	ldr	r2, .Llit080259C8                      @ 080258EC  =mcFreqLo
	adds	r0, r6, r2                            @ 080258EE
	ldrb	r0, [r0]                              @ 080258F0
	orrs	r1, r0                                @ 080258F2
	ldr	r0, [sp, #0x20]                        @ 080258F4
	str	r1, [r0]                               @ 080258F6
	mov	r1, r12                                @ 080258F8
	adds	r1, #0x1c                             @ 080258FA
	adds	r1, r5, r1                            @ 080258FC
	ldr	r3, [sp, #0x24]                        @ 080258FE
	ldr	r0, [r3]                               @ 08025900
	adds	r0, r4, r0                            @ 08025902
	ldrb	r0, [r0, #1]                          @ 08025904
	str	r0, [r1]                               @ 08025906
	ldr	r1, .Llit080259CC                      @ 08025908  =mcDurTable  fixed note-length table (E.T. reads mcDurTable through a pointer)
	ldr	r0, [r3]                               @ 0802590A
	adds	r0, r4, r0                            @ 0802590C
	ldrb	r0, [r0, #2]                          @ 0802590E
	lsls	r0, r0, #2                            @ 08025910
	adds	r0, r0, r1                            @ 08025912
	ldr	r0, [r0]                               @ 08025914
	ldr	r4, [sp, #0xc]                         @ 08025916
	str	r0, [r4]                               @ 08025918
	ldr	r0, [r3]                               @ 0802591A
	adds	r0, #3                                @ 0802591C
	str	r0, [r3]                               @ 0802591E
	mov	r8, r2                                 @ 08025920
	mov	r5, r9                                 @ 08025922
	cmp	r5, #0                                 @ 08025924
	bne	.L080259F8                             @ 08025926
	mov	r1, r12                                @ 08025928
	ldr	r0, [r1, #0x1c]                        @ 0802592A
	lsls	r0, r0, #2                            @ 0802592C
	ldr	r2, .Llit080259D0                      @ 0802592E  =mcInstTable
	adds	r0, r0, r2                            @ 08025930
	ldr	r5, [r0]                               @ 08025932
	ldr	r1, [r5, #4]                           @ 08025934
	ldr	r0, [r5, #8]                           @ 08025936
	lsls	r0, r0, #8                            @ 08025938
	adds	r1, r1, r0                            @ 0802593A
	lsls	r1, r1, #0x10                         @ 0802593C
	lsrs	r2, r1, #0x10                         @ 0802593E
	ldr	r3, [r5, #0x10]                        @ 08025940
	cmp	r3, #0                                 @ 08025942
	beq	.L08025960                             @ 08025944
	movs	r0, #0xff                             @ 08025946
	ands	r2, r0                                @ 08025948
	ldrh	r4, [r3]                              @ 0802594A
	lsls	r0, r4, #8                            @ 0802594C
	orrs	r2, r0                                @ 0802594E
	lsls	r0, r2, #0x10                         @ 08025950
	lsrs	r2, r0, #0x10                         @ 08025952
	mov	r0, r9                                 @ 08025954
	mov	r1, r12                                @ 08025956
	str	r0, [r1, #0x30]                        @ 08025958
	movs	r4, #2                                @ 0802595A
	ldrsh	r0, [r3, r4]                         @ 0802595C
	str	r0, [r1, #0x34]                        @ 0802595E
.L08025960:
	mov	r0, r12                                @ 08025960
	ldr	r4, [r0, #4]                           @ 08025962
	cmp	r4, #0                                 @ 08025964
	beq	.L0802596C                             @ 08025966
	ldr	r0, .Llit080259D4                      @ 08025968  =REG_SOUND1CNT_H
	strh	r2, [r0]                              @ 0802596A
.L0802596C:
	ldr	r3, [r5, #0x20]                        @ 0802596C
	cmp	r3, #0                                 @ 0802596E
	beq	.L08025992                             @ 08025970
	movs	r1, #2                                @ 08025972
	ldrsh	r0, [r3, r1]                         @ 08025974
	adds	r0, r6, r0                            @ 08025976
	adds	r1, r0, r7                            @ 08025978
	ldrb	r1, [r1]                              @ 0802597A
	lsls	r1, r1, #8                            @ 0802597C
	add	r0, r8                                 @ 0802597E
	ldrb	r0, [r0]                              @ 08025980
	orrs	r1, r0                                @ 08025982
	mov	r2, r12                                @ 08025984
	str	r1, [r2, #0x18]                        @ 08025986
	mov	r7, r9                                 @ 08025988
	str	r7, [r2, #0x40]                        @ 0802598A
	movs	r1, #0                                @ 0802598C
	ldrsh	r0, [r3, r1]                         @ 0802598E
	str	r0, [r2, #0x44]                        @ 08025990
.L08025992:
	ldr	r0, [r5]                               @ 08025992
	lsls	r0, r0, #0x18                         @ 08025994
	lsrs	r2, r0, #0x10                         @ 08025996
	ldr	r3, [r5, #0x18]                        @ 08025998
	cmp	r3, #0                                 @ 0802599A
	beq	.L080259E0                             @ 0802599C
	ldrh	r5, [r3]                              @ 0802599E
	ldr	r7, .Llit080259D8                      @ 080259A0  =0xFFFF8000
	adds	r0, r5, r7                            @ 080259A2
	orrs	r2, r0                                @ 080259A4
	mov	r0, r9                                 @ 080259A6
	mov	r1, r12                                @ 080259A8
	str	r0, [r1, #0x38]                        @ 080259AA
	movs	r5, #2                                @ 080259AC
	ldrsh	r0, [r3, r5]                         @ 080259AE
	str	r0, [r1, #0x3c]                        @ 080259B0
	ldr	r0, [r1, #0x18]                        @ 080259B2
	orrs	r0, r2                                @ 080259B4
	lsls	r0, r0, #0x10                         @ 080259B6
	lsrs	r2, r0, #0x10                         @ 080259B8
	cmp	r4, #0                                 @ 080259BA
	beq	.L080259F8                             @ 080259BC
	ldr	r7, .Llit080259DC                      @ 080259BE  =REG_SOUND1CNT_X
	strh	r2, [r7]                              @ 080259C0
	b	.L080259F8                               @ 080259C2
.Llit080259C4:
	.word	mcFreqHi                       @ 080259C4  = 0x083FF2AD
.Llit080259C8:
	.word	mcFreqLo                       @ 080259C8  = 0x083FF24C
.Llit080259CC:
	.word	mcDurTable                     @ 080259CC  = 0x083FC738
.Llit080259D0:
	.word	mcInstTable                    @ 080259D0  = 0x083FF834
.Llit080259D4:
	.word	REG_SOUND1CNT_H                @ 080259D4  = 0x04000062
.Llit080259D8:
	.word	0xFFFF8000                     @ 080259D8
.Llit080259DC:
	.word	REG_SOUND1CNT_X                @ 080259DC  = 0x04000064
.L080259E0:
	movs	r0, #0x80                             @ 080259E0
	lsls	r0, r0, #8                            @ 080259E2
	orrs	r2, r0                                @ 080259E4
	mov	r1, r12                                @ 080259E6
	ldr	r0, [r1, #0x18]                        @ 080259E8
	orrs	r0, r2                                @ 080259EA
	lsls	r0, r0, #0x10                         @ 080259EC
	lsrs	r2, r0, #0x10                         @ 080259EE
	cmp	r4, #0                                 @ 080259F0
	beq	.L080259F8                             @ 080259F2
	ldr	r3, .Llit08025AB0                      @ 080259F4  =REG_SOUND1CNT_X
	strh	r2, [r3]                              @ 080259F6
.L080259F8:
	mov	r4, r9                                 @ 080259F8
	cmp	r4, #1                                 @ 080259FA
	bne	.L08025ADC                             @ 080259FC
	mov	r5, r12                                @ 080259FE
	ldr	r0, [r5, #0x64]                        @ 08025A00
	lsls	r0, r0, #2                            @ 08025A02
	ldr	r7, .Llit08025AB4                      @ 08025A04  =mcInstTable
	adds	r0, r0, r7                            @ 08025A06
	ldr	r5, [r0]                               @ 08025A08
	ldr	r1, [r5, #4]                           @ 08025A0A
	ldr	r0, [r5, #8]                           @ 08025A0C
	lsls	r0, r0, #8                            @ 08025A0E
	adds	r1, r1, r0                            @ 08025A10
	lsls	r1, r1, #0x10                         @ 08025A12
	lsrs	r2, r1, #0x10                         @ 08025A14
	ldr	r3, [r5, #0x10]                        @ 08025A16
	cmp	r3, #0                                 @ 08025A18
	beq	.L08025A36                             @ 08025A1A
	movs	r0, #0xff                             @ 08025A1C
	ands	r2, r0                                @ 08025A1E
	ldrh	r1, [r3]                              @ 08025A20
	lsls	r0, r1, #8                            @ 08025A22
	orrs	r2, r0                                @ 08025A24
	lsls	r0, r2, #0x10                         @ 08025A26
	lsrs	r2, r0, #0x10                         @ 08025A28
	movs	r4, #0                                @ 08025A2A
	mov	r7, r12                                @ 08025A2C
	str	r4, [r7, #0x78]                        @ 08025A2E
	movs	r1, #2                                @ 08025A30
	ldrsh	r0, [r3, r1]                         @ 08025A32
	str	r0, [r7, #0x7c]                        @ 08025A34
.L08025A36:
	mov	r3, r12                                @ 08025A36
	ldr	r4, [r3, #0x4c]                        @ 08025A38
	cmp	r4, #0                                 @ 08025A3A
	beq	.L08025A42                             @ 08025A3C
	ldr	r0, .Llit08025AB8                      @ 08025A3E  =REG_SOUND2CNT_L
	strh	r2, [r0]                              @ 08025A40
.L08025A42:
	ldr	r3, [r5, #0x20]                        @ 08025A42
	cmp	r3, #0                                 @ 08025A44
	beq	.L08025A72                             @ 08025A46
	movs	r7, #2                                @ 08025A48
	ldrsh	r0, [r3, r7]                         @ 08025A4A
	adds	r0, r6, r0                            @ 08025A4C
	ldr	r2, .Llit08025ABC                      @ 08025A4E  =mcFreqHi
	adds	r1, r0, r2                            @ 08025A50
	ldrb	r1, [r1]                              @ 08025A52
	lsls	r1, r1, #8                            @ 08025A54
	add	r0, r8                                 @ 08025A56
	ldrb	r0, [r0]                              @ 08025A58
	orrs	r1, r0                                @ 08025A5A
	mov	r7, r12                                @ 08025A5C
	str	r1, [r7, #0x60]                        @ 08025A5E
	mov	r0, r12                                @ 08025A60
	adds	r0, #0x88                             @ 08025A62
	movs	r1, #0                                @ 08025A64
	str	r1, [r0]                               @ 08025A66
	mov	r1, r12                                @ 08025A68
	adds	r1, #0x8c                             @ 08025A6A
	movs	r2, #0                                @ 08025A6C
	ldrsh	r0, [r3, r2]                         @ 08025A6E
	str	r0, [r1]                               @ 08025A70
.L08025A72:
	ldr	r0, [r5]                               @ 08025A72
	lsls	r0, r0, #0x18                         @ 08025A74
	lsrs	r2, r0, #0x10                         @ 08025A76
	ldr	r3, [r5, #0x18]                        @ 08025A78
	cmp	r3, #0                                 @ 08025A7A
	beq	.L08025AC4                             @ 08025A7C
	movs	r0, #0x80                             @ 08025A7E
	lsls	r0, r0, #8                            @ 08025A80
	ldrh	r5, [r3]                              @ 08025A82
	orrs	r0, r5                                @ 08025A84
	orrs	r2, r0                                @ 08025A86
	mov	r0, r12                                @ 08025A88
	adds	r0, #0x80                             @ 08025A8A
	movs	r7, #0                                @ 08025A8C
	str	r7, [r0]                               @ 08025A8E
	mov	r1, r12                                @ 08025A90
	adds	r1, #0x84                             @ 08025A92
	movs	r5, #2                                @ 08025A94
	ldrsh	r0, [r3, r5]                         @ 08025A96
	str	r0, [r1]                               @ 08025A98
	mov	r7, r12                                @ 08025A9A
	ldr	r0, [r7, #0x60]                        @ 08025A9C
	orrs	r2, r0                                @ 08025A9E
	lsls	r0, r2, #0x10                         @ 08025AA0
	lsrs	r2, r0, #0x10                         @ 08025AA2
	cmp	r4, #0                                 @ 08025AA4
	beq	.L08025ADC                             @ 08025AA6
	ldr	r0, .Llit08025AC0                      @ 08025AA8  =REG_SOUND2CNT_H
	strh	r2, [r0]                              @ 08025AAA
	b	.L08025ADC                               @ 08025AAC
	.hword	0x0000                          @ 08025AAE  (padding)
.Llit08025AB0:
	.word	REG_SOUND1CNT_X                @ 08025AB0  = 0x04000064
.Llit08025AB4:
	.word	mcInstTable                    @ 08025AB4  = 0x083FF834
.Llit08025AB8:
	.word	REG_SOUND2CNT_L                @ 08025AB8  = 0x04000068
.Llit08025ABC:
	.word	mcFreqHi                       @ 08025ABC  = 0x083FF2AD
.Llit08025AC0:
	.word	REG_SOUND2CNT_H                @ 08025AC0  = 0x0400006C
.L08025AC4:
	movs	r1, #0x80                             @ 08025AC4
	lsls	r1, r1, #8                            @ 08025AC6
	orrs	r2, r1                                @ 08025AC8
	mov	r3, r12                                @ 08025ACA
	ldr	r0, [r3, #0x60]                        @ 08025ACC
	orrs	r0, r2                                @ 08025ACE
	lsls	r0, r0, #0x10                         @ 08025AD0
	lsrs	r2, r0, #0x10                         @ 08025AD2
	cmp	r4, #0                                 @ 08025AD4
	beq	.L08025ADC                             @ 08025AD6
	ldr	r4, .Llit08025BA0                      @ 08025AD8  =REG_SOUND2CNT_H
	strh	r2, [r4]                              @ 08025ADA
.L08025ADC:
	mov	r5, r9                                 @ 08025ADC
	cmp	r5, #2                                 @ 08025ADE
	bne	.L08025BD2                             @ 08025AE0
	mov	r0, r12                                @ 08025AE2
	adds	r0, #0xac                             @ 08025AE4
	ldr	r0, [r0]                               @ 08025AE6
	lsls	r0, r0, #2                            @ 08025AE8
	ldr	r7, .Llit08025BA4                      @ 08025AEA  =mcInstTable
	adds	r0, r0, r7                            @ 08025AEC
	ldr	r5, [r0]                               @ 08025AEE
	ldr	r1, [r5, #4]                           @ 08025AF0
	ldr	r0, [r5, #8]                           @ 08025AF2
	lsls	r0, r0, #8                            @ 08025AF4
	adds	r1, r1, r0                            @ 08025AF6
	lsls	r1, r1, #0x10                         @ 08025AF8
	lsrs	r2, r1, #0x10                         @ 08025AFA
	ldr	r3, [r5, #0x10]                        @ 08025AFC
	cmp	r3, #0                                 @ 08025AFE
	beq	.L08025B22                             @ 08025B00
	movs	r0, #0xff                             @ 08025B02
	ands	r2, r0                                @ 08025B04
	ldrh	r1, [r3]                              @ 08025B06
	lsls	r0, r1, #8                            @ 08025B08
	orrs	r2, r0                                @ 08025B0A
	lsls	r0, r2, #0x10                         @ 08025B0C
	lsrs	r2, r0, #0x10                         @ 08025B0E
	mov	r0, r12                                @ 08025B10
	adds	r0, #0xc0                             @ 08025B12
	movs	r4, #0                                @ 08025B14
	str	r4, [r0]                               @ 08025B16
	mov	r1, r12                                @ 08025B18
	adds	r1, #0xc4                             @ 08025B1A
	movs	r7, #2                                @ 08025B1C
	ldrsh	r0, [r3, r7]                         @ 08025B1E
	str	r0, [r1]                               @ 08025B20
.L08025B22:
	mov	r4, r12                                @ 08025B22
	adds	r4, #0x94                             @ 08025B24
	ldr	r0, [r4]                               @ 08025B26
	cmp	r0, #0                                 @ 08025B28
	beq	.L08025B30                             @ 08025B2A
	ldr	r0, .Llit08025BA8                      @ 08025B2C  =REG_SOUND3CNT_H
	strh	r2, [r0]                              @ 08025B2E
.L08025B30:
	ldr	r3, [r5, #0x20]                        @ 08025B30
	cmp	r3, #0                                 @ 08025B32
	beq	.L08025B60                             @ 08025B34
	movs	r1, #2                                @ 08025B36
	ldrsh	r0, [r3, r1]                         @ 08025B38
	adds	r0, r6, r0                            @ 08025B3A
	ldr	r2, .Llit08025BAC                      @ 08025B3C  =mcFreqHi
	adds	r1, r0, r2                            @ 08025B3E
	ldrb	r1, [r1]                              @ 08025B40
	lsls	r1, r1, #8                            @ 08025B42
	add	r0, r8                                 @ 08025B44
	ldrb	r0, [r0]                              @ 08025B46
	orrs	r1, r0                                @ 08025B48
	ldr	r6, .Llit08025BB0                      @ 08025B4A  =mcChan+0x90+CH_freq
	str	r1, [r6]                               @ 08025B4C
	mov	r0, r12                                @ 08025B4E
	adds	r0, #0xd0                             @ 08025B50
	movs	r7, #0                                @ 08025B52
	str	r7, [r0]                               @ 08025B54
	mov	r1, r12                                @ 08025B56
	adds	r1, #0xd4                             @ 08025B58
	movs	r2, #0                                @ 08025B5A
	ldrsh	r0, [r3, r2]                         @ 08025B5C
	str	r0, [r1]                               @ 08025B5E
.L08025B60:
	ldr	r0, [r5]                               @ 08025B60
	lsls	r0, r0, #0x18                         @ 08025B62
	lsrs	r2, r0, #0x10                         @ 08025B64
	ldr	r3, [r5, #0x18]                        @ 08025B66
	cmp	r3, #0                                 @ 08025B68
	beq	.L08025BB8                             @ 08025B6A
	movs	r0, #0x80                             @ 08025B6C
	lsls	r0, r0, #8                            @ 08025B6E
	ldrh	r5, [r3]                              @ 08025B70
	orrs	r0, r5                                @ 08025B72
	orrs	r2, r0                                @ 08025B74
	mov	r0, r12                                @ 08025B76
	adds	r0, #0xc8                             @ 08025B78
	movs	r6, #0                                @ 08025B7A
	str	r6, [r0]                               @ 08025B7C
	mov	r1, r12                                @ 08025B7E
	adds	r1, #0xcc                             @ 08025B80
	movs	r7, #2                                @ 08025B82
	ldrsh	r0, [r3, r7]                         @ 08025B84
	str	r0, [r1]                               @ 08025B86
	ldr	r1, .Llit08025BB0                      @ 08025B88  =mcChan+0x90+CH_freq
	ldr	r0, [r1]                               @ 08025B8A
	orrs	r2, r0                                @ 08025B8C
	lsls	r0, r2, #0x10                         @ 08025B8E
	lsrs	r2, r0, #0x10                         @ 08025B90
	ldr	r0, [r4]                               @ 08025B92
	cmp	r0, #0                                 @ 08025B94
	beq	.L08025BD2                             @ 08025B96
	ldr	r3, .Llit08025BB4                      @ 08025B98  =REG_SOUND3CNT_X
	strh	r2, [r3]                              @ 08025B9A
	b	.L08025BD2                               @ 08025B9C
	.hword	0x0000                          @ 08025B9E  (padding)
.Llit08025BA0:
	.word	REG_SOUND2CNT_H                @ 08025BA0  = 0x0400006C
.Llit08025BA4:
	.word	mcInstTable                    @ 08025BA4  = 0x083FF834
.Llit08025BA8:
	.word	REG_SOUND3CNT_H                @ 08025BA8  = 0x04000072
.Llit08025BAC:
	.word	mcFreqHi                       @ 08025BAC  = 0x083FF2AD
.Llit08025BB0:
	.word	mcChan+0x90+CH_freq            @ 08025BB0  = 0x03006758
.Llit08025BB4:
	.word	REG_SOUND3CNT_X                @ 08025BB4  = 0x04000074
.L08025BB8:
	movs	r5, #0x80                             @ 08025BB8
	lsls	r5, r5, #8                            @ 08025BBA
	orrs	r2, r5                                @ 08025BBC
	ldr	r6, .Llit08025C88                      @ 08025BBE  =mcChan+0x90+CH_freq
	ldr	r0, [r6]                               @ 08025BC0
	orrs	r0, r2                                @ 08025BC2
	lsls	r0, r0, #0x10                         @ 08025BC4
	lsrs	r2, r0, #0x10                         @ 08025BC6
	ldr	r0, [r4]                               @ 08025BC8
	cmp	r0, #0                                 @ 08025BCA
	beq	.L08025BD2                             @ 08025BCC
	ldr	r7, .Llit08025C8C                      @ 08025BCE  =REG_SOUND3CNT_X
	strh	r2, [r7]                              @ 08025BD0
.L08025BD2:
	mov	r0, r9                                 @ 08025BD2
	cmp	r0, #3                                 @ 08025BD4
	bne	.L08025C62                             @ 08025BD6
	mov	r4, r12                                @ 08025BD8
	adds	r0, r4, #0                            @ 08025BDA
	adds	r0, #0xf4                             @ 08025BDC
	ldr	r0, [r0]                               @ 08025BDE
	lsls	r0, r0, #2                            @ 08025BE0
	ldr	r1, .Llit08025C90                      @ 08025BE2  =mcInstTable
	adds	r0, r0, r1                            @ 08025BE4
	ldr	r5, [r0]                               @ 08025BE6
	ldr	r1, [r5, #4]                           @ 08025BE8
	ldr	r0, [r5, #8]                           @ 08025BEA
	lsls	r0, r0, #8                            @ 08025BEC
	adds	r1, r1, r0                            @ 08025BEE
	lsls	r1, r1, #0x10                         @ 08025BF0
	lsrs	r2, r1, #0x10                         @ 08025BF2
	ldr	r3, [r5, #0x10]                        @ 08025BF4
	cmp	r3, #0                                 @ 08025BF6
	beq	.L08025C1E                             @ 08025BF8
	movs	r0, #0xff                             @ 08025BFA
	ands	r2, r0                                @ 08025BFC
	ldrh	r6, [r3]                              @ 08025BFE
	lsls	r0, r6, #8                            @ 08025C00
	orrs	r2, r0                                @ 08025C02
	lsls	r0, r2, #0x10                         @ 08025C04
	lsrs	r2, r0, #0x10                         @ 08025C06
	movs	r7, #0x84                             @ 08025C08
	lsls	r7, r7, #1                            @ 08025C0A
	adds	r0, r4, r7                            @ 08025C0C
	movs	r1, #0                                @ 08025C0E
	str	r1, [r0]                               @ 08025C10
	movs	r6, #0x86                             @ 08025C12
	lsls	r6, r6, #1                            @ 08025C14
	adds	r1, r4, r6                            @ 08025C16
	movs	r7, #2                                @ 08025C18
	ldrsh	r0, [r3, r7]                         @ 08025C1A
	str	r0, [r1]                               @ 08025C1C
.L08025C1E:
	adds	r4, #0xdc                             @ 08025C1E
	ldr	r0, [r4]                               @ 08025C20
	cmp	r0, #0                                 @ 08025C22
	beq	.L08025C2A                             @ 08025C24
	ldr	r0, .Llit08025C94                      @ 08025C26  =REG_SOUND4CNT_L
	strh	r2, [r0]                              @ 08025C28
.L08025C2A:
	ldr	r0, [r5]                               @ 08025C2A
	lsls	r0, r0, #0x18                         @ 08025C2C
	lsrs	r2, r0, #0x10                         @ 08025C2E
	ldr	r3, [r5, #0x18]                        @ 08025C30
	cmp	r3, #0                                 @ 08025C32
	beq	.L08025C62                             @ 08025C34
	ldrh	r1, [r3]                              @ 08025C36
	ldr	r5, .Llit08025C98                      @ 08025C38  =0xFFFF8000
	adds	r0, r1, r5                            @ 08025C3A
	orrs	r2, r0                                @ 08025C3C
	lsls	r0, r2, #0x10                         @ 08025C3E
	lsrs	r2, r0, #0x10                         @ 08025C40
	movs	r0, #0x88                             @ 08025C42
	lsls	r0, r0, #1                            @ 08025C44
	add	r0, r12                                @ 08025C46
	movs	r6, #0                                @ 08025C48
	str	r6, [r0]                               @ 08025C4A
	movs	r1, #0x8a                             @ 08025C4C
	lsls	r1, r1, #1                            @ 08025C4E
	add	r1, r12                                @ 08025C50
	movs	r7, #2                                @ 08025C52
	ldrsh	r0, [r3, r7]                         @ 08025C54
	str	r0, [r1]                               @ 08025C56
	ldr	r0, [r4]                               @ 08025C58
	cmp	r0, #0                                 @ 08025C5A
	beq	.L08025C62                             @ 08025C5C
	ldr	r0, .Llit08025C9C                      @ 08025C5E  =REG_SOUND4CNT_H
	strh	r2, [r0]                              @ 08025C60
.L08025C62:
	ldr	r0, [sp]                               @ 08025C62
	cmp	r0, #0x65                              @ 08025C64  pattern end
	bne	.L08025C6C                             @ 08025C66
	bl	.L08025108                              @ 08025C68  long branch
.L08025C6C:
	ldr	r1, [sp, #0x28]                        @ 08025C6C
	mov	r9, r1                                 @ 08025C6E
	cmp	r1, #3                                 @ 08025C70
	bgt	.L08025C78                             @ 08025C72
	bl	.L080250C4                              @ 08025C74  long branch
.L08025C78:
	add	sp, #0x38                              @ 08025C78
	pop	{r3, r4, r5}                           @ 08025C7A
	mov	r8, r3                                 @ 08025C7C
	mov	r9, r4                                 @ 08025C7E
	mov	r10, r5                                @ 08025C80
	pop	{r4, r5, r6, r7}                       @ 08025C82
	pop	{r0}                                   @ 08025C84
	bx	r0                                      @ 08025C86
.Llit08025C88:
	.word	mcChan+0x90+CH_freq            @ 08025C88  = 0x03006758
.Llit08025C8C:
	.word	REG_SOUND3CNT_X                @ 08025C8C  = 0x04000074
.Llit08025C90:
	.word	mcInstTable                    @ 08025C90  = 0x083FF834
.Llit08025C94:
	.word	REG_SOUND4CNT_L                @ 08025C94  = 0x04000078
.Llit08025C98:
	.word	0xFFFF8000                     @ 08025C98
.Llit08025C9C:
	.word	REG_SOUND4CNT_H                @ 08025C9C  = 0x0400007C
