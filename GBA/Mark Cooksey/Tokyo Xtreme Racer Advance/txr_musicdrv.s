@ ============================================================================
@ txr_musicdrv.s -- Mark Cooksey's GBA sound driver, "Build B" (software-mixer version),
@                  as used in Tokyo Xtreme Racer Advance (GBA)
@
@ Reconstructed from "Tokyo Xtreme Racer Advance (E) (M5).gba" (BTZP), ROM range
@ 0x08005EEC-0x08007A88 (7068 bytes).  Assembling this file and linking it with txr_sound.ld
@ reproduces that range byte for byte (make -f txr_sound.mk).
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
@   VBlank: mcSwapBuffers() and mcUpdate() are called by the game every frame (as in Snood 2).
@   Engine sound: the game writes gEngineStep each frame at 0x0800A558 (speed>>6 + gear offset)
@   and starts SFX 31/32 on voice 0; SFX 0 on voice 0 mutes it.
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
@ ---- driver RAM (IWRAM)  -- every address is Snood 2's + 0x21B0
	.equ	mcPsgSfxCur,       0x03006880   @     4 B  last PSG SFX number passed to mcPlayPsgSfx
	.equ	mcSaveSfxId,       0x03006888   @     8 B  mcPause copy of mcSfxId[2]
	.equ	mcSfxFrames,       0x03006890   @     8 B  SFX voice: 176-byte chunks left, [2]
	.equ	mcSaveSfxLoop,     0x03006898   @     8 B  mcPause copy of mcSfxLoop[2]
	.equ	IWRAM_mcSfxMix,    0x030068A0   @   480 B  mcSfxMix is copied here by mcSoundInit (0x78 words)
	.equ	gEngineStep,       0x03006A80   @     4 B  TXR only: engine voice step (4-bit fraction), written by the game
	.equ	mcSfxPtr,          0x03006A88   @     8 B  SFX voice: current PCM pointer (0 = idle), [2]
	.equ	mcSaveSfxFrames,   0x03006A90   @     8 B  mcPause copy of mcSfxFrames[2]
	.equ	mcBufIndex,        0x03006A98   @     4 B  double-buffer index (0/1) of the buffer the FIFOs are playing
	.equ	IWRAM_mcMixMusic,  0x03006AA0   @  2400 B  mcMixMusic (ARM) is copied here by mcSoundInit (0x258 words)
	.equ	mcFadeCounter,     0x03007400   @     4 B  fade: frame counter (step every 16 frames)
	.equ	mcTempo,           0x03007404   @     4 B  tempo: ticks per frame in 8.8 fixed point
	.equ	mcSaveSfxPending,  0x03007408   @     8 B  mcPause copy of mcSfxPending[2]
	.equ	mcMusicBuf,        0x03007410   @   352 B  music mix buffers [2][176] -> FIFO A
	.equ	mcPaused,          0x03007570   @     4 B  non-zero = sequencer frozen
	.equ	mcTempoAcc,        0x03007574   @     4 B  tempo accumulator
	.equ	mcMasterPan,       0x03007578   @     4 B  SOUNDCNT_L shadow
	.equ	mcEnginePos,       0x0300757C   @     4 B  TXR only: engine voice position (4-bit fraction)
	.equ	mcDurTable,        0x03007580   @     4 B  pointer to the current song's note-length table
	.equ	mcPsgSfx,          0x03007590   @    72 B  PSG SFX slots [6] x {ptr, index, timer} (4 used)
	.equ	mcSfxPending,      0x030075D8   @     8 B  set by mcDsSfxStart, only read by mcPause, [2]
	.equ	mcSaveSfxPtr,      0x030075E0   @     8 B  mcPause copy of mcSfxPtr[2]
	.equ	mcSfxLoop,         0x030075E8   @     8 B  SFX voice: loop flag from the table (0 = one-shot), [2]
	.equ	mcCurSong,         0x030075F0   @     4 B  song number (written, never read)
	.equ	mcSfxBuf,          0x03007600   @   352 B  SFX mix buffers [2][176] -> FIFO B
	.equ	mcSfxActive,       0x03007760   @     8 B  set to 1 by mcDsSfxStart; saved by mcPause; otherwise unread, [2]
	.equ	mcChan,            0x03007770   @   576 B  music channel state [8] x 0x48 bytes
	.equ	mcFadeLevel,       0x030079B0   @     4 B  fade level 7..0 (7 = full)
	.equ	mcFading,          0x030079B4   @     4 B  non-zero = fade-out running
	.equ	mcSaveSfxActive,   0x030079B8   @     8 B  mcPause copy of mcSfxActive[2]
	.equ	mcCondFlag,        0x030079C0   @     4 B  SEQ_CONDFLAG value; never read
	.equ	mcSaveFading,      0x030079C4   @     4 B  mcPause copy of mcFading
	.equ	mcSaveFadeLevel,   0x030079C8   @     4 B  mcPause copy of mcFadeLevel
	.equ	mcSfxId,           0x030079D0   @     8 B  SFX voice: table index playing, [2]
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
@ ---- ROM data (see txr_sound_data.s)
	.equ	mcFadeTable, 0x0803AE58
	.equ	mcMixerFuncs, 0x083466F0
	.equ	mcStepTable, 0x08346B78
	.equ	pcm_08346CF8, 0x08346CF8
	.equ	mcSfxTable, 0x083CBBCC
	.equ	mcSmpInstTable, 0x083CBEEC
	.equ	mcPsgSfxMap, 0x083CC0EC
	.equ	mcPsgSfxScripts, 0x083CC26C
	.equ	mcFreqLo, 0x083D4800
	.equ	mcFreqHi, 0x083D4861
	.equ	mcSongTable, 0x083D48C4
	.equ	mcInstTable, 0x083D5214
@ ---- libgcc
	.equ	_call_via_r1, 0x08018E94

	.section .text.txr_musicdrv, "ax", %progbits
	.balign 4
	@ linked at 0x08005EEC by txr_sound.ld

@ --------------------------------------------------------------------------
@ mcPlaySong  (0x08005EEC)
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
	push	{r4, r5, r6, r7, lr}                  @ 08005EEC
	mov	r7, r10                                @ 08005EEE
	mov	r6, r9                                 @ 08005EF0
	mov	r5, r8                                 @ 08005EF2
	push	{r5, r6, r7}                          @ 08005EF4
	sub	sp, #4                                 @ 08005EF6
	str	r0, [sp]                               @ 08005EF8
	ldr	r0, .Llit08005FB4                      @ 08005EFA  =mcSongTable
	mov	r10, r0                                @ 08005EFC
	ldr	r2, .Llit08005FB8                      @ 08005EFE  =mcChan
	ldr	r3, [sp]                               @ 08005F00
	lsls	r1, r3, #3                            @ 08005F02
	adds	r0, r1, r3                            @ 08005F04
	lsls	r0, r0, #2                            @ 08005F06
	movs	r5, #0                                @ 08005F08
	adds	r4, r2, #0                            @ 08005F0A
	add	r0, r10                                @ 08005F0C
	mov	r8, r0                                 @ 08005F0E
	movs	r3, #0                                @ 08005F10
	movs	r7, #1                                @ 08005F12
	mov	r12, r7                                @ 08005F14
	mov	r9, r1                                 @ 08005F16
	movs	r6, #7                                @ 08005F18
.L08005F1A:
	adds	r0, r2, #0                            @ 08005F1A
	adds	r0, #0x20                             @ 08005F1C
	adds	r0, r3, r0                            @ 08005F1E
	mov	r7, r8                                 @ 08005F20
	adds	r7, #4                                @ 08005F22
	mov	r8, r7                                 @ 08005F24
	subs	r7, #4                                @ 08005F26
	ldm	r7!, {r1}                              @ 08005F28
	str	r1, [r0]                               @ 08005F2A
	adds	r0, r2, #0                            @ 08005F2C
	adds	r0, #8                                @ 08005F2E
	adds	r0, r3, r0                            @ 08005F30
	str	r5, [r0]                               @ 08005F32
	adds	r0, r2, #0                            @ 08005F34
	adds	r0, #0x24                             @ 08005F36
	adds	r0, r3, r0                            @ 08005F38
	str	r5, [r0]                               @ 08005F3A
	adds	r0, r2, #0                            @ 08005F3C
	adds	r0, #0xc                              @ 08005F3E
	adds	r0, r3, r0                            @ 08005F40
	str	r5, [r0]                               @ 08005F42
	adds	r0, r2, #0                            @ 08005F44
	adds	r0, #0x14                             @ 08005F46
	adds	r0, r3, r0                            @ 08005F48
	movs	r1, #0x60                             @ 08005F4A
	str	r1, [r0]                               @ 08005F4C
	adds	r0, r2, #0                            @ 08005F4E
	adds	r0, #0x10                             @ 08005F50
	adds	r0, r3, r0                            @ 08005F52
	str	r5, [r0]                               @ 08005F54
	mov	r0, r12                                @ 08005F56
	str	r0, [r4]                               @ 08005F58
	adds	r0, r2, #4                            @ 08005F5A
	adds	r0, r3, r0                            @ 08005F5C
	mov	r1, r12                                @ 08005F5E
	str	r1, [r0]                               @ 08005F60
	adds	r0, r2, #0                            @ 08005F62
	adds	r0, #0x38                             @ 08005F64
	adds	r0, r3, r0                            @ 08005F66
	movs	r1, #1                                @ 08005F68
	rsbs	r1, r1, #0                            @ 08005F6A
	str	r1, [r0]                               @ 08005F6C
	str	r5, [r4, #0x30]                        @ 08005F6E
	adds	r4, #0x48                             @ 08005F70
	adds	r3, #0x48                             @ 08005F72
	subs	r6, #1                                @ 08005F74
	cmp	r6, #0                                 @ 08005F76
	bge	.L08005F1A                             @ 08005F78
	movs	r2, #0                                @ 08005F7A
	ldr	r0, [sp]                               @ 08005F7C
	add	r0, r9                                 @ 08005F7E
	lsls	r0, r0, #2                            @ 08005F80
	mov	r1, r10                                @ 08005F82
	adds	r1, #0x20                             @ 08005F84
	adds	r0, r0, r1                            @ 08005F86
	ldr	r0, [r0]                               @ 08005F88
	ldr	r3, .Llit08005FBC                      @ 08005F8A  =mcDurTable
	str	r0, [r3]                               @ 08005F8C
	ldr	r7, .Llit08005FC0                      @ 08005F8E  =mcCondFlag
	str	r2, [r7]                               @ 08005F90
	ldr	r0, [sp]                               @ 08005F92
	ldr	r1, .Llit08005FC4                      @ 08005F94  =mcCurSong
	str	r0, [r1]                               @ 08005F96
	movs	r0, #7                                @ 08005F98
	ldr	r3, .Llit08005FC8                      @ 08005F9A  =mcFadeLevel
	str	r0, [r3]                               @ 08005F9C
	ldr	r7, .Llit08005FCC                      @ 08005F9E  =mcFading
	str	r2, [r7]                               @ 08005FA0
	add	sp, #4                                 @ 08005FA2
	pop	{r3, r4, r5}                           @ 08005FA4
	mov	r8, r3                                 @ 08005FA6
	mov	r9, r4                                 @ 08005FA8
	mov	r10, r5                                @ 08005FAA
	pop	{r4, r5, r6, r7}                       @ 08005FAC
	pop	{r0}                                   @ 08005FAE
	bx	r0                                      @ 08005FB0
	.hword	0x0000                          @ 08005FB2  (padding)
.Llit08005FB4:
	.word	mcSongTable                    @ 08005FB4  = 0x083D48C4
.Llit08005FB8:
	.word	mcChan                         @ 08005FB8  = 0x03007770
.Llit08005FBC:
	.word	mcDurTable                     @ 08005FBC  = 0x03007580
.Llit08005FC0:
	.word	mcCondFlag                     @ 08005FC0  = 0x030079C0
.Llit08005FC4:
	.word	mcCurSong                      @ 08005FC4  = 0x030075F0
.Llit08005FC8:
	.word	mcFadeLevel                    @ 08005FC8  = 0x030079B0
.Llit08005FCC:
	.word	mcFading                       @ 08005FCC  = 0x030079B4
@ --------------------------------------------------------------------------
@ mcPause  (0x08005FD0)
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
	push	{r4, r5, r6, r7, lr}                  @ 08005FD0
	mov	r7, r10                                @ 08005FD2
	mov	r6, r9                                 @ 08005FD4
	mov	r5, r8                                 @ 08005FD6
	push	{r5, r6, r7}                          @ 08005FD8
	ldr	r1, .Llit080060A4                      @ 08005FDA  =mcPaused
	movs	r0, #1                                @ 08005FDC
	str	r0, [r1]                               @ 08005FDE
	ldr	r2, .Llit080060A8                      @ 08005FE0  =mcPsgSfx
	ldr	r1, [r2]                               @ 08005FE2
	cmp	r1, #0                                 @ 08005FE4
	bne	.L08005FF0                             @ 08005FE6
	ldr	r0, .Llit080060AC                      @ 08005FE8  =REG_SOUND1CNT_H
	strh	r1, [r0]                              @ 08005FEA
	adds	r0, #2                                @ 08005FEC
	strh	r1, [r0]                              @ 08005FEE
.L08005FF0:
	ldr	r1, [r2, #0xc]                         @ 08005FF0
	cmp	r1, #0                                 @ 08005FF2
	bne	.L08005FFE                             @ 08005FF4
	ldr	r0, .Llit080060B0                      @ 08005FF6  =REG_SOUND2CNT_L
	strh	r1, [r0]                              @ 08005FF8
	adds	r0, #4                                @ 08005FFA
	strh	r1, [r0]                              @ 08005FFC
.L08005FFE:
	ldr	r1, [r2, #0x18]                        @ 08005FFE
	cmp	r1, #0                                 @ 08006000
	bne	.L0800600C                             @ 08006002
	ldr	r0, .Llit080060B4                      @ 08006004  =REG_SOUND3CNT_H
	strh	r1, [r0]                              @ 08006006
	adds	r0, #2                                @ 08006008
	strh	r1, [r0]                              @ 0800600A
.L0800600C:
	ldr	r1, [r2, #0x24]                        @ 0800600C
	cmp	r1, #0                                 @ 0800600E
	bne	.L0800601A                             @ 08006010
	ldr	r0, .Llit080060B8                      @ 08006012  =REG_SOUND4CNT_L
	strh	r1, [r0]                              @ 08006014
	adds	r0, #4                                @ 08006016
	strh	r1, [r0]                              @ 08006018
.L0800601A:
	movs	r4, #0                                @ 0800601A
	ldr	r0, .Llit080060BC                      @ 0800601C  =mcSfxId
	mov	r10, r0                                @ 0800601E
	ldr	r2, .Llit080060C0                      @ 08006020  =mcSaveSfxFrames
	mov	r9, r2                                 @ 08006022
	ldr	r3, .Llit080060C4                      @ 08006024  =mcSfxFrames
	mov	r12, r3                                @ 08006026
	ldr	r6, .Llit080060C8                      @ 08006028  =mcSfxActive
	ldr	r7, .Llit080060CC                      @ 0800602A  =mcFading
	mov	r8, r7                                 @ 0800602C
	ldr	r5, .Llit080060D0                      @ 0800602E  =mcSaveSfxPending
.L08006030:
	lsls	r1, r4, #2                            @ 08006030
	ldr	r2, .Llit080060D4                      @ 08006032  =mcSfxPending
	adds	r0, r1, r2                            @ 08006034
	ldr	r0, [r0]                               @ 08006036
	stm	r5!, {r0}                              @ 08006038
	ldr	r3, .Llit080060D8                      @ 0800603A  =mcSaveSfxLoop
	adds	r2, r1, r3                            @ 0800603C
	ldr	r7, .Llit080060DC                      @ 0800603E  =mcSfxLoop
	adds	r0, r1, r7                            @ 08006040
	ldr	r0, [r0]                               @ 08006042
	str	r0, [r2]                               @ 08006044
	ldr	r0, .Llit080060E0                      @ 08006046  =mcSaveSfxPtr
	adds	r2, r1, r0                            @ 08006048
	ldr	r7, .Llit080060E4                      @ 0800604A  =mcSfxPtr
	adds	r3, r1, r7                            @ 0800604C
	ldr	r0, [r3]                               @ 0800604E
	str	r0, [r2]                               @ 08006050
	ldr	r0, .Llit080060E8                      @ 08006052  =mcSaveSfxId
	adds	r2, r1, r0                            @ 08006054
	mov	r7, r10                                @ 08006056
	adds	r0, r1, r7                            @ 08006058
	ldr	r0, [r0]                               @ 0800605A
	str	r0, [r2]                               @ 0800605C
	mov	r0, r9                                 @ 0800605E
	adds	r2, r1, r0                            @ 08006060
	mov	r7, r12                                @ 08006062
	adds	r0, r1, r7                            @ 08006064
	ldr	r0, [r0]                               @ 08006066
	str	r0, [r2]                               @ 08006068
	ldr	r0, .Llit080060EC                      @ 0800606A  =mcSaveSfxActive
	adds	r2, r1, r0                            @ 0800606C
	adds	r1, r1, r6                            @ 0800606E
	ldr	r0, [r1]                               @ 08006070
	str	r0, [r2]                               @ 08006072
	movs	r1, #0                                @ 08006074
	str	r1, [r3]                               @ 08006076
	adds	r4, #1                                @ 08006078
	cmp	r4, #1                                 @ 0800607A
	ble	.L08006030                             @ 0800607C
	ldr	r2, .Llit080060F0                      @ 0800607E  =mcFadeLevel
	ldr	r0, [r2]                               @ 08006080
	ldr	r3, .Llit080060F4                      @ 08006082  =mcSaveFadeLevel
	str	r0, [r3]                               @ 08006084
	mov	r7, r8                                 @ 08006086
	ldr	r0, [r7]                               @ 08006088
	ldr	r2, .Llit080060F8                      @ 0800608A  =mcSaveFading
	str	r0, [r2]                               @ 0800608C
	movs	r0, #7                                @ 0800608E
	ldr	r3, .Llit080060F0                      @ 08006090  =mcFadeLevel
	str	r0, [r3]                               @ 08006092
	str	r1, [r7]                               @ 08006094
	pop	{r3, r4, r5}                           @ 08006096
	mov	r8, r3                                 @ 08006098
	mov	r9, r4                                 @ 0800609A
	mov	r10, r5                                @ 0800609C
	pop	{r4, r5, r6, r7}                       @ 0800609E
	pop	{r0}                                   @ 080060A0
	bx	r0                                      @ 080060A2
.Llit080060A4:
	.word	mcPaused                       @ 080060A4  = 0x03007570
.Llit080060A8:
	.word	mcPsgSfx                       @ 080060A8  = 0x03007590
.Llit080060AC:
	.word	REG_SOUND1CNT_H                @ 080060AC  = 0x04000062
.Llit080060B0:
	.word	REG_SOUND2CNT_L                @ 080060B0  = 0x04000068
.Llit080060B4:
	.word	REG_SOUND3CNT_H                @ 080060B4  = 0x04000072
.Llit080060B8:
	.word	REG_SOUND4CNT_L                @ 080060B8  = 0x04000078
.Llit080060BC:
	.word	mcSfxId                        @ 080060BC  = 0x030079D0
.Llit080060C0:
	.word	mcSaveSfxFrames                @ 080060C0  = 0x03006A90
.Llit080060C4:
	.word	mcSfxFrames                    @ 080060C4  = 0x03006890
.Llit080060C8:
	.word	mcSfxActive                    @ 080060C8  = 0x03007760
.Llit080060CC:
	.word	mcFading                       @ 080060CC  = 0x030079B4
.Llit080060D0:
	.word	mcSaveSfxPending               @ 080060D0  = 0x03007408
.Llit080060D4:
	.word	mcSfxPending                   @ 080060D4  = 0x030075D8
.Llit080060D8:
	.word	mcSaveSfxLoop                  @ 080060D8  = 0x03006898
.Llit080060DC:
	.word	mcSfxLoop                      @ 080060DC  = 0x030075E8
.Llit080060E0:
	.word	mcSaveSfxPtr                   @ 080060E0  = 0x030075E0
.Llit080060E4:
	.word	mcSfxPtr                       @ 080060E4  = 0x03006A88
.Llit080060E8:
	.word	mcSaveSfxId                    @ 080060E8  = 0x03006888
.Llit080060EC:
	.word	mcSaveSfxActive                @ 080060EC  = 0x030079B8
.Llit080060F0:
	.word	mcFadeLevel                    @ 080060F0  = 0x030079B0
.Llit080060F4:
	.word	mcSaveFadeLevel                @ 080060F4  = 0x030079C8
.Llit080060F8:
	.word	mcSaveFading                   @ 080060F8  = 0x030079C4
@ --------------------------------------------------------------------------
@ mcResume  (0x080060FC)
@   Undo mcPause: restore the saved SFX voices and fade state, mcPaused = 0 (NO CALLERS)
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcResume
mcResume:
	push	{r4, r5, r6, r7, lr}                  @ 080060FC
	mov	r7, r10                                @ 080060FE
	mov	r6, r9                                 @ 08006100
	mov	r5, r8                                 @ 08006102
	push	{r5, r6, r7}                          @ 08006104
	ldr	r1, .Llit0800618C                      @ 08006106  =mcPaused
	movs	r0, #0                                @ 08006108
	str	r0, [r1]                               @ 0800610A
	movs	r3, #0                                @ 0800610C
	ldr	r0, .Llit08006190                      @ 0800610E  =mcSaveSfxPtr
	mov	r10, r0                                @ 08006110
	ldr	r1, .Llit08006194                      @ 08006112  =mcSfxId
	mov	r9, r1                                 @ 08006114
	ldr	r2, .Llit08006198                      @ 08006116  =mcSaveSfxId
	mov	r8, r2                                 @ 08006118
	ldr	r7, .Llit0800619C                      @ 0800611A  =mcSfxFrames
	mov	r12, r7                                @ 0800611C
	ldr	r6, .Llit080061A0                      @ 0800611E  =mcSfxActive
	ldr	r5, .Llit080061A4                      @ 08006120  =mcSaveSfxActive
	ldr	r4, .Llit080061A8                      @ 08006122  =mcSfxPending
.L08006124:
	lsls	r1, r3, #2                            @ 08006124
	ldr	r2, .Llit080061AC                      @ 08006126  =mcSaveSfxPending
	adds	r0, r1, r2                            @ 08006128
	ldr	r0, [r0]                               @ 0800612A
	stm	r4!, {r0}                              @ 0800612C
	ldr	r7, .Llit080061B0                      @ 0800612E  =mcSfxLoop
	adds	r2, r1, r7                            @ 08006130
	ldr	r7, .Llit080061B4                      @ 08006132  =mcSaveSfxLoop
	adds	r0, r1, r7                            @ 08006134
	ldr	r0, [r0]                               @ 08006136
	str	r0, [r2]                               @ 08006138
	ldr	r0, .Llit080061B8                      @ 0800613A  =mcSfxPtr
	adds	r2, r1, r0                            @ 0800613C
	mov	r7, r10                                @ 0800613E
	adds	r0, r1, r7                            @ 08006140
	ldr	r0, [r0]                               @ 08006142
	str	r0, [r2]                               @ 08006144
	mov	r0, r9                                 @ 08006146
	adds	r2, r1, r0                            @ 08006148
	mov	r7, r8                                 @ 0800614A
	adds	r0, r1, r7                            @ 0800614C
	ldr	r0, [r0]                               @ 0800614E
	str	r0, [r2]                               @ 08006150
	mov	r0, r12                                @ 08006152
	adds	r2, r1, r0                            @ 08006154
	ldr	r7, .Llit080061BC                      @ 08006156  =mcSaveSfxFrames
	adds	r0, r1, r7                            @ 08006158
	ldr	r0, [r0]                               @ 0800615A
	str	r0, [r2]                               @ 0800615C
	adds	r2, r1, r6                            @ 0800615E
	adds	r1, r1, r5                            @ 08006160
	ldr	r0, [r1]                               @ 08006162
	str	r0, [r2]                               @ 08006164
	adds	r3, #1                                @ 08006166
	cmp	r3, #1                                 @ 08006168
	ble	.L08006124                             @ 0800616A
	ldr	r1, .Llit080061C0                      @ 0800616C  =mcSaveFadeLevel
	ldr	r0, [r1]                               @ 0800616E
	ldr	r2, .Llit080061C4                      @ 08006170  =mcFadeLevel
	str	r0, [r2]                               @ 08006172
	ldr	r7, .Llit080061C8                      @ 08006174  =mcSaveFading
	ldr	r0, [r7]                               @ 08006176
	ldr	r1, .Llit080061CC                      @ 08006178  =mcFading
	str	r0, [r1]                               @ 0800617A
	pop	{r3, r4, r5}                           @ 0800617C
	mov	r8, r3                                 @ 0800617E
	mov	r9, r4                                 @ 08006180
	mov	r10, r5                                @ 08006182
	pop	{r4, r5, r6, r7}                       @ 08006184
	pop	{r0}                                   @ 08006186
	bx	r0                                      @ 08006188
	.hword	0x0000                          @ 0800618A  (padding)
.Llit0800618C:
	.word	mcPaused                       @ 0800618C  = 0x03007570
.Llit08006190:
	.word	mcSaveSfxPtr                   @ 08006190  = 0x030075E0
.Llit08006194:
	.word	mcSfxId                        @ 08006194  = 0x030079D0
.Llit08006198:
	.word	mcSaveSfxId                    @ 08006198  = 0x03006888
.Llit0800619C:
	.word	mcSfxFrames                    @ 0800619C  = 0x03006890
.Llit080061A0:
	.word	mcSfxActive                    @ 080061A0  = 0x03007760
.Llit080061A4:
	.word	mcSaveSfxActive                @ 080061A4  = 0x030079B8
.Llit080061A8:
	.word	mcSfxPending                   @ 080061A8  = 0x030075D8
.Llit080061AC:
	.word	mcSaveSfxPending               @ 080061AC  = 0x03007408
.Llit080061B0:
	.word	mcSfxLoop                      @ 080061B0  = 0x030075E8
.Llit080061B4:
	.word	mcSaveSfxLoop                  @ 080061B4  = 0x03006898
.Llit080061B8:
	.word	mcSfxPtr                       @ 080061B8  = 0x03006A88
.Llit080061BC:
	.word	mcSaveSfxFrames                @ 080061BC  = 0x03006A90
.Llit080061C0:
	.word	mcSaveFadeLevel                @ 080061C0  = 0x030079C8
.Llit080061C4:
	.word	mcFadeLevel                    @ 080061C4  = 0x030079B0
.Llit080061C8:
	.word	mcSaveFading                   @ 080061C8  = 0x030079C4
.Llit080061CC:
	.word	mcFading                       @ 080061CC  = 0x030079B4
@ --------------------------------------------------------------------------
@ mcSfxMix  (0x080061D0)
@   TXR version.  Voice 1 is unchanged (average into the buffer).  Voice 0 is the ENGINE voice:
@       for i in 0..175: buf[i] = pcm[mcEnginePos >> 4]; mcEnginePos += gEngineStep;
@                        if (mcEnginePos >= mcSfxTable[id].wrapLen) mcEnginePos = 0
@       mcSfxFrames[0] = 4          (so voice 0 never times out)
@     SFX table entries are 20 bytes here: {pcm, frames, loop, unused, wrapLen}.
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcSfxMix
mcSfxMix:
	push	{r4, r5, r6, r7, lr}                  @ 080061D0
	mov	r7, r10                                @ 080061D2
	mov	r6, r9                                 @ 080061D4
	mov	r5, r8                                 @ 080061D6
	push	{r5, r6, r7}                          @ 080061D8
	adds	r7, r0, #0                            @ 080061DA
	ldr	r0, .Llit08006204                      @ 080061DC  =mcSfxPtr
	lsls	r1, r7, #2                            @ 080061DE
	adds	r5, r1, r0                            @ 080061E0
	ldr	r4, [r5]                               @ 080061E2
	cmp	r4, #0                                 @ 080061E4
	beq	.L08006248                             @ 080061E6
	ldr	r0, .Llit08006208                      @ 080061E8  =mcSfxFrames
	adds	r6, r1, r0                            @ 080061EA
	ldr	r0, [r6]                               @ 080061EC
	cmp	r0, #0                                 @ 080061EE
	bne	.L08006244                             @ 080061F0
	ldr	r0, .Llit0800620C                      @ 080061F2  =mcSfxLoop
	adds	r0, r1, r0                            @ 080061F4
	ldr	r0, [r0]                               @ 080061F6
	cmp	r0, #0                                 @ 080061F8
	bne	.L08006210                             @ 080061FA
	movs	r4, #0                                @ 080061FC
	str	r4, [r5]                               @ 080061FE
	b	.L08006248                               @ 08006200
	.hword	0x0000                          @ 08006202  (padding)
.Llit08006204:
	.word	mcSfxPtr                       @ 08006204  = 0x03006A88
.Llit08006208:
	.word	mcSfxFrames                    @ 08006208  = 0x03006890
.Llit0800620C:
	.word	mcSfxLoop                      @ 0800620C  = 0x030075E8
.L08006210:
	ldr	r3, .Llit0800623C                      @ 08006210  =mcSfxTable
	ldr	r2, .Llit08006240                      @ 08006212  =mcSfxId
	adds	r2, r1, r2                            @ 08006214
	ldr	r1, [r2]                               @ 08006216
	lsls	r0, r1, #2                            @ 08006218
	adds	r0, r0, r1                            @ 0800621A
	lsls	r0, r0, #2                            @ 0800621C
	adds	r0, r0, r3                            @ 0800621E
	ldr	r0, [r0]                               @ 08006220
	str	r0, [r5]                               @ 08006222
	ldr	r1, [r2]                               @ 08006224
	lsls	r0, r1, #2                            @ 08006226
	adds	r0, r0, r1                            @ 08006228
	lsls	r0, r0, #2                            @ 0800622A
	adds	r3, #4                                @ 0800622C
	adds	r0, r0, r3                            @ 0800622E
	ldr	r0, [r0]                               @ 08006230
	subs	r0, #1                                @ 08006232
	str	r0, [r6]                               @ 08006234
	ldr	r4, [r5]                               @ 08006236
	b	.L08006248                               @ 08006238
	.hword	0x0000                          @ 0800623A  (padding)
.Llit0800623C:
	.word	mcSfxTable                     @ 0800623C  = 0x083CBBCC
.Llit08006240:
	.word	mcSfxId                        @ 08006240  = 0x030079D0
.L08006244:
	subs	r0, #1                                @ 08006244
	str	r0, [r6]                               @ 08006246
.L08006248:
	ldr	r0, .Llit080062B0                      @ 08006248  =mcBufIndex
	ldr	r0, [r0]                               @ 0800624A
	adds	r3, r0, #1                            @ 0800624C
	movs	r0, #1                                @ 0800624E
	ands	r3, r0                                @ 08006250
	cmp	r7, #0                                 @ 08006252
	bne	.L080062CC                             @ 08006254
	cmp	r4, #0                                 @ 08006256
	beq	.L0800631E                             @ 08006258
	ldr	r0, .Llit080062B4                      @ 0800625A  =mcEnginePos
	ldr	r2, [r0]                               @ 0800625C
	movs	r6, #0                                @ 0800625E
	ldr	r1, .Llit080062B8                      @ 08006260  =mcSfxFrames
	mov	r10, r1                                @ 08006262
	mov	r9, r0                                 @ 08006264
	ldr	r1, .Llit080062BC                      @ 08006266  =mcSfxBuf
	ldr	r0, .Llit080062C0                      @ 08006268  =mcSfxId
	mov	r8, r0                                 @ 0800626A
	ldr	r0, .Llit080062C4                      @ 0800626C  =0x83CBBDC
	mov	r12, r0                                @ 0800626E
	movs	r0, #0xb0                             @ 08006270
	muls	r0, r3, r0                            @ 08006272
	adds	r5, r0, r1                            @ 08006274
	ldr	r7, .Llit080062C8                      @ 08006276  =gEngineStep
	movs	r3, #0xaf                             @ 08006278
.L0800627A:
	asrs	r0, r2, #4                            @ 0800627A
	adds	r0, r4, r0                            @ 0800627C
	ldrb	r0, [r0]                              @ 0800627E
	strb	r0, [r5]                              @ 08006280
	ldr	r0, [r7]                               @ 08006282
	adds	r2, r2, r0                            @ 08006284
	mov	r0, r8                                 @ 08006286
	ldr	r1, [r0]                               @ 08006288
	lsls	r0, r1, #2                            @ 0800628A
	adds	r0, r0, r1                            @ 0800628C
	lsls	r0, r0, #2                            @ 0800628E
	add	r0, r12                                @ 08006290
	ldr	r0, [r0]                               @ 08006292
	cmp	r2, r0                                 @ 08006294
	blo	.L0800629A                             @ 08006296
	movs	r2, #0                                @ 08006298
.L0800629A:
	adds	r5, #1                                @ 0800629A
	subs	r3, #1                                @ 0800629C
	cmp	r3, #0                                 @ 0800629E
	bge	.L0800627A                             @ 080062A0
	mov	r1, r9                                 @ 080062A2
	str	r2, [r1]                               @ 080062A4
	mov	r0, r10                                @ 080062A6
	adds	r1, r6, r0                            @ 080062A8
	movs	r0, #4                                @ 080062AA
	str	r0, [r1]                               @ 080062AC
	b	.L08006318                               @ 080062AE
.Llit080062B0:
	.word	mcBufIndex                     @ 080062B0  = 0x03006A98
.Llit080062B4:
	.word	mcEnginePos                    @ 080062B4  = 0x0300757C
.Llit080062B8:
	.word	mcSfxFrames                    @ 080062B8  = 0x03006890
.Llit080062BC:
	.word	mcSfxBuf                       @ 080062BC  = 0x03007600
.Llit080062C0:
	.word	mcSfxId                        @ 080062C0  = 0x030079D0
.Llit080062C4:
	.word	0x083CBBDC                     @ 080062C4
.Llit080062C8:
	.word	gEngineStep                    @ 080062C8  = 0x03006A80
.L080062CC:
	cmp	r4, #0                                 @ 080062CC
	beq	.L080062FC                             @ 080062CE
	lsls	r6, r7, #2                            @ 080062D0
	ldr	r0, .Llit080062F8                      @ 080062D2  =mcSfxBuf
	movs	r1, #0xb0                             @ 080062D4
	muls	r1, r3, r1                            @ 080062D6
	adds	r2, r1, r0                            @ 080062D8
	movs	r3, #0xaf                             @ 080062DA
.L080062DC:
	movs	r1, #0                                @ 080062DC
	ldrsb	r1, [r2, r1]                         @ 080062DE
	movs	r0, #0                                @ 080062E0
	ldrsb	r0, [r4, r0]                         @ 080062E2
	adds	r1, r1, r0                            @ 080062E4
	adds	r4, #1                                @ 080062E6
	asrs	r1, r1, #1                            @ 080062E8
	strb	r1, [r2]                              @ 080062EA
	adds	r2, #1                                @ 080062EC
	subs	r3, #1                                @ 080062EE
	cmp	r3, #0                                 @ 080062F0
	bge	.L080062DC                             @ 080062F2
	b	.L08006318                               @ 080062F4
	.hword	0x0000                          @ 080062F6  (padding)
.Llit080062F8:
	.word	mcSfxBuf                       @ 080062F8  = 0x03007600
.L080062FC:
	lsls	r6, r7, #2                            @ 080062FC
	ldr	r0, .Llit0800632C                      @ 080062FE  =mcSfxBuf
	movs	r1, #0xb0                             @ 08006300
	muls	r1, r3, r1                            @ 08006302
	adds	r0, r1, r0                            @ 08006304
	movs	r3, #0xaf                             @ 08006306
.L08006308:
	movs	r1, #0                                @ 08006308
	ldrsb	r1, [r0, r1]                         @ 0800630A
	asrs	r1, r1, #1                            @ 0800630C
	strb	r1, [r0]                              @ 0800630E
	adds	r0, #1                                @ 08006310
	subs	r3, #1                                @ 08006312
	cmp	r3, #0                                 @ 08006314
	bge	.L08006308                             @ 08006316
.L08006318:
	ldr	r1, .Llit08006330                      @ 08006318  =mcSfxPtr
	adds	r0, r6, r1                            @ 0800631A
	str	r4, [r0]                               @ 0800631C
.L0800631E:
	pop	{r3, r4, r5}                           @ 0800631E
	mov	r8, r3                                 @ 08006320
	mov	r9, r4                                 @ 08006322
	mov	r10, r5                                @ 08006324
	pop	{r4, r5, r6, r7}                       @ 08006326
	pop	{r0}                                   @ 08006328
	bx	r0                                      @ 0800632A
.Llit0800632C:
	.word	mcSfxBuf                       @ 0800632C  = 0x03007600
.Llit08006330:
	.word	mcSfxPtr                       @ 08006330  = 0x03006A88
@ --------------------------------------------------------------------------
@ mcSwapBuffers  (0x08006334)
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
	push	{r4, r5, r6, r7, lr}                  @ 08006334
	mov	r7, r10                                @ 08006336
	mov	r6, r9                                 @ 08006338
	mov	r5, r8                                 @ 0800633A
	push	{r5, r6, r7}                          @ 0800633C
	ldr	r0, .Llit080063D4                      @ 0800633E  =mcBufIndex
	ldr	r3, [r0]                               @ 08006340
	adds	r3, #1                                @ 08006342
	movs	r1, #1                                @ 08006344
	mov	r12, r1                                @ 08006346
	ands	r3, r1                                @ 08006348
	str	r3, [r0]                               @ 0800634A
	ldr	r6, .Llit080063D8                      @ 0800634C  =REG_TM0CNT
	movs	r5, #0                                @ 0800634E
	str	r5, [r6]                               @ 08006350
	ldr	r2, .Llit080063DC                      @ 08006352  =REG_DMA1CNT
	str	r5, [r2]                               @ 08006354
	ldr	r1, .Llit080063E0                      @ 08006356  =REG_DMA1DAD
	ldr	r0, .Llit080063E4                      @ 08006358  =REG_FIFO_A
	str	r0, [r1]                               @ 0800635A
	subs	r1, #4                                @ 0800635C
	movs	r7, #0xb0                             @ 0800635E
	mov	r10, r7                                @ 08006360
	mov	r4, r10                                @ 08006362
	muls	r4, r3, r4                            @ 08006364
	ldr	r0, .Llit080063E8                      @ 08006366  =mcMusicBuf
	mov	r9, r0                                 @ 08006368
	adds	r0, r4, r0                            @ 0800636A
	str	r0, [r1]                               @ 0800636C
	ldr	r0, .Llit080063EC                      @ 0800636E  =0x80F9C4
	str	r0, [r6]                               @ 08006370
	ldr	r1, .Llit080063F0                      @ 08006372  =0xBE400000
	mov	r8, r1                                 @ 08006374
	str	r1, [r2]                               @ 08006376
	ldr	r0, [r2]                               @ 08006378
	adds	r6, #4                                @ 0800637A
	str	r5, [r6]                               @ 0800637C
	adds	r2, #0xc                              @ 0800637E
	str	r5, [r2]                               @ 08006380
	ldr	r1, .Llit080063F4                      @ 08006382  =REG_DMA2DAD
	ldr	r0, .Llit080063F8                      @ 08006384  =REG_FIFO_B
	str	r0, [r1]                               @ 08006386
	adds	r0, #0x24                             @ 08006388
	ldr	r1, .Llit080063FC                      @ 0800638A  =mcSfxBuf
	adds	r4, r4, r1                            @ 0800638C
	str	r4, [r0]                               @ 0800638E
	ldr	r0, .Llit08006400                      @ 08006390  =0x80F99D
	str	r0, [r6]                               @ 08006392
	mov	r7, r8                                 @ 08006394
	str	r7, [r2]                               @ 08006396
	ldr	r0, [r2]                               @ 08006398
	adds	r3, #1                                @ 0800639A
	mov	r0, r12                                @ 0800639C
	ands	r3, r0                                @ 0800639E
	mov	r0, r10                                @ 080063A0
	muls	r0, r3, r0                            @ 080063A2
	add	r0, r9                                 @ 080063A4
	movs	r4, #0                                @ 080063A6
	movs	r2, #0x2b                             @ 080063A8
.L080063AA:
	stm	r0!, {r4}                              @ 080063AA
	subs	r2, #1                                @ 080063AC
	cmp	r2, #0                                 @ 080063AE
	bge	.L080063AA                             @ 080063B0
	movs	r0, #0xb0                             @ 080063B2
	muls	r0, r3, r0                            @ 080063B4
	adds	r0, r0, r1                            @ 080063B6
	movs	r1, #0                                @ 080063B8
	movs	r2, #0x2b                             @ 080063BA
.L080063BC:
	stm	r0!, {r1}                              @ 080063BC
	subs	r2, #1                                @ 080063BE
	cmp	r2, #0                                 @ 080063C0
	bge	.L080063BC                             @ 080063C2
	pop	{r3, r4, r5}                           @ 080063C4
	mov	r8, r3                                 @ 080063C6
	mov	r9, r4                                 @ 080063C8
	mov	r10, r5                                @ 080063CA
	pop	{r4, r5, r6, r7}                       @ 080063CC
	pop	{r0}                                   @ 080063CE
	bx	r0                                      @ 080063D0
	.hword	0x0000                          @ 080063D2  (padding)
.Llit080063D4:
	.word	mcBufIndex                     @ 080063D4  = 0x03006A98
.Llit080063D8:
	.word	REG_TM0CNT                     @ 080063D8  = 0x04000100
.Llit080063DC:
	.word	REG_DMA1CNT                    @ 080063DC  = 0x040000C4
.Llit080063E0:
	.word	REG_DMA1DAD                    @ 080063E0  = 0x040000C0
.Llit080063E4:
	.word	REG_FIFO_A                     @ 080063E4  = 0x040000A0
.Llit080063E8:
	.word	mcMusicBuf                     @ 080063E8  = 0x03007410
.Llit080063EC:
	.word	0x0080F9C4                     @ 080063EC
.Llit080063F0:
	.word	0xBE400000                     @ 080063F0
.Llit080063F4:
	.word	REG_DMA2DAD                    @ 080063F4  = 0x040000CC
.Llit080063F8:
	.word	REG_FIFO_B                     @ 080063F8  = 0x040000A4
.Llit080063FC:
	.word	mcSfxBuf                       @ 080063FC  = 0x03007600
.Llit08006400:
	.word	0x0080F99D                     @ 08006400
@ --------------------------------------------------------------------------
@ mcUpdate  (0x08006404)
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
	push	{r4, r5, r6, r7, lr}                  @ 08006404
	mov	r7, r10                                @ 08006406
	mov	r6, r9                                 @ 08006408
	mov	r5, r8                                 @ 0800640A
	push	{r5, r6, r7}                          @ 0800640C
	sub	sp, #0x6c                              @ 0800640E
	movs	r7, #0                                @ 08006410
	ldr	r6, .Llit080064D4                      @ 08006412  =mcFading
	ldr	r0, [r6]                               @ 08006414
	cmp	r0, #1                                 @ 08006416
	bne	.L0800645E                             @ 08006418
	ldr	r0, .Llit080064D8                      @ 0800641A  =mcFadeCounter
	ldr	r1, [r0]                               @ 0800641C
	adds	r1, #1                                @ 0800641E
	movs	r2, #0xf                              @ 08006420
	ands	r1, r2                                @ 08006422
	str	r1, [r0]                               @ 08006424
	cmp	r1, #0                                 @ 08006426
	bne	.L0800645E                             @ 08006428
	ldr	r5, .Llit080064DC                      @ 0800642A  =mcFadeLevel
	ldr	r0, [r5]                               @ 0800642C
	cmp	r0, #0                                 @ 0800642E
	beq	.L08006436                             @ 08006430
	subs	r0, #1                                @ 08006432
	str	r0, [r5]                               @ 08006434
.L08006436:
	ldr	r3, .Llit080064E0                      @ 08006436  =REG_SOUNDCNT_L
	ldrh	r0, [r3]                              @ 08006438
	movs	r1, #0xff                             @ 0800643A
	lsls	r1, r1, #8                            @ 0800643C
	ands	r1, r0                                @ 0800643E
	ldr	r2, [r5]                               @ 08006440
	lsls	r0, r2, #4                            @ 08006442
	adds	r0, r2, r0                            @ 08006444
	orrs	r1, r0                                @ 08006446
	lsls	r1, r1, #0x10                         @ 08006448
	lsrs	r4, r1, #0x10                         @ 0800644A
	strh	r4, [r3]                              @ 0800644C  SOUNDCNT_L low byte = mcFadeLevel * 0x11 (PSG master volume)
	cmp	r2, #0                                 @ 0800644E
	bne	.L0800645E                             @ 08006450
	movs	r0, #0                                @ 08006452
	bl	mcPlaySong                              @ 08006454  fade reached 0: mcPlaySong(0)
	str	r7, [r6]                               @ 08006458
	movs	r0, #7                                @ 0800645A
	str	r0, [r5]                               @ 0800645C
.L0800645E:
	ldr	r0, .Llit080064E4                      @ 0800645E  =mcPaused
	ldr	r0, [r0]                               @ 08006460
	cmp	r0, #0                                 @ 08006462
	bne	.L080064F8                             @ 08006464
	ldr	r0, .Llit080064D4                      @ 08006466  =mcFading
	ldr	r0, [r0]                               @ 08006468
	cmp	r0, #0                                 @ 0800646A
	beq	.L08006476                             @ 0800646C
	ldr	r0, .Llit080064DC                      @ 0800646E  =mcFadeLevel
	ldr	r0, [r0]                               @ 08006470
	cmp	r0, #0                                 @ 08006472
	beq	.L08006480                             @ 08006474
.L08006476:
	ldr	r0, .Llit080064E8                      @ 08006476  =mcMixerFuncs
	ldr	r1, [r0]                               @ 08006478
	movs	r0, #4                                @ 0800647A
	bl	_call_via_r1                            @ 0800647C  mcMixMusic(4) through mcMixerFuncs[0] (IWRAM, ARM)
.L08006480:
	ldr	r0, .Llit080064D4                      @ 08006480  =mcFading
	ldr	r0, [r0]                               @ 08006482
	cmp	r0, #0                                 @ 08006484
	beq	.L08006522                             @ 08006486
	ldr	r0, .Llit080064DC                      @ 08006488  =mcFadeLevel
	ldr	r2, [r0]                               @ 0800648A
	cmp	r2, #0                                 @ 0800648C
	beq	.L08006522                             @ 0800648E
	cmp	r2, #7                                 @ 08006490
	beq	.L08006522                             @ 08006492
	mov	r1, sp                                 @ 08006494
	ldr	r0, .Llit080064EC                      @ 08006496  =mcFadeTable
	ldm	r0!, {r3, r4, r5}                      @ 08006498
	stm	r1!, {r3, r4, r5}                      @ 0800649A
	ldm	r0!, {r3, r6, r7}                      @ 0800649C
	stm	r1!, {r3, r6, r7}                      @ 0800649E
	ldm	r0!, {r4, r5, r6}                      @ 080064A0
	stm	r1!, {r4, r5, r6}                      @ 080064A2
	lsls	r0, r2, #2                            @ 080064A4
	add	r0, sp                                 @ 080064A6
	ldr	r3, [r0]                               @ 080064A8
	ldr	r0, .Llit080064F0                      @ 080064AA  =mcBufIndex
	ldr	r0, [r0]                               @ 080064AC
	adds	r0, #1                                @ 080064AE
	movs	r1, #1                                @ 080064B0
	ands	r0, r1                                @ 080064B2
	ldr	r2, .Llit080064F4                      @ 080064B4  =mcMusicBuf
	movs	r1, #0xb0                             @ 080064B6
	muls	r0, r1, r0                            @ 080064B8
	adds	r1, r0, r2                            @ 080064BA
	movs	r2, #0xaf                             @ 080064BC
.L080064BE:
	movs	r0, #0                                @ 080064BE
	ldrsb	r0, [r1, r0]                         @ 080064C0
	muls	r0, r3, r0                            @ 080064C2
	asrs	r0, r0, #8                            @ 080064C4  fade: sample = sample * mcFadeTable[level] >> 8
	strb	r0, [r1]                              @ 080064C6
	adds	r1, #1                                @ 080064C8
	subs	r2, #1                                @ 080064CA
	cmp	r2, #0                                 @ 080064CC
	bge	.L080064BE                             @ 080064CE
	b	.L08006522                               @ 080064D0
	.hword	0x0000                          @ 080064D2  (padding)
.Llit080064D4:
	.word	mcFading                       @ 080064D4  = 0x030079B4
.Llit080064D8:
	.word	mcFadeCounter                  @ 080064D8  = 0x03007400
.Llit080064DC:
	.word	mcFadeLevel                    @ 080064DC  = 0x030079B0
.Llit080064E0:
	.word	REG_SOUNDCNT_L                 @ 080064E0  = 0x04000080
.Llit080064E4:
	.word	mcPaused                       @ 080064E4  = 0x03007570
.Llit080064E8:
	.word	mcMixerFuncs                   @ 080064E8  = 0x083466F0
.Llit080064EC:
	.word	mcFadeTable                    @ 080064EC  = 0x0803AE58
.Llit080064F0:
	.word	mcBufIndex                     @ 080064F0  = 0x03006A98
.Llit080064F4:
	.word	mcMusicBuf                     @ 080064F4  = 0x03007410
.L080064F8:
	ldr	r0, .Llit08006588                      @ 080064F8  =mcBufIndex
	ldr	r1, [r0]                               @ 080064FA
	adds	r1, #1                                @ 080064FC
	movs	r0, #1                                @ 080064FE
	ands	r1, r0                                @ 08006500
	ldr	r2, .Llit0800658C                      @ 08006502  =mcMusicBuf
	movs	r3, #0                                @ 08006504
	movs	r7, #0xaf                             @ 08006506
	mov	r10, r7                                @ 08006508
	movs	r0, #0xb0                             @ 0800650A
	muls	r0, r1, r0                            @ 0800650C
	adds	r0, r0, r2                            @ 0800650E
	adds	r0, #0xaf                             @ 08006510
.L08006512:
	strb	r3, [r0]                              @ 08006512  paused: clear the next music buffer
	subs	r0, #1                                @ 08006514
	movs	r1, #1                                @ 08006516
	rsbs	r1, r1, #0                            @ 08006518
	add	r10, r1                                @ 0800651A
	mov	r2, r10                                @ 0800651C
	cmp	r2, #0                                 @ 0800651E
	bge	.L08006512                             @ 08006520
.L08006522:
	movs	r3, #0                                @ 08006522
	mov	r10, r3                                @ 08006524
	ldr	r4, .Llit08006590                      @ 08006526  =mcMixerFuncs+4
.L08006528:
	ldr	r1, [r4]                               @ 08006528
	mov	r0, r10                                @ 0800652A
	bl	_call_via_r1                            @ 0800652C  mcSfxMix(voice) through mcMixerFuncs[1], voices 0 and 1
	movs	r5, #1                                @ 08006530
	add	r10, r5                                @ 08006532
	mov	r6, r10                                @ 08006534
	cmp	r6, #1                                 @ 08006536
	ble	.L08006528                             @ 08006538
	movs	r7, #0                                @ 0800653A
	mov	r10, r7                                @ 0800653C
	ldr	r0, .Llit08006594                      @ 0800653E  =mcPaused
	mov	r12, r0                                @ 08006540
	ldr	r0, .Llit08006598                      @ 08006542  =mcPsgSfx
	adds	r6, r0, #0                            @ 08006544
	ldr	r0, .Llit0800659C                      @ 08006546  =mcChan
	adds	r0, #4                                @ 08006548
	mov	r9, r0                                 @ 0800654A
	adds	r1, r6, #4                            @ 0800654C
	mov	r8, r1                                 @ 0800654E
	adds	r5, r6, #0                            @ 08006550
.L08006552:
	ldr	r4, [r5]                               @ 08006552
	cmp	r4, #0                                 @ 08006554
	beq	.L0800662E                             @ 08006556
	adds	r0, r6, #0                            @ 08006558
	adds	r0, #8                                @ 0800655A
	adds	r1, r7, r0                            @ 0800655C
	ldr	r0, [r1]                               @ 0800655E
	cmp	r0, #0                                 @ 08006560
	beq	.L0800656C                             @ 08006562
	subs	r0, #1                                @ 08006564
	str	r0, [r1]                               @ 08006566
	cmp	r0, #0                                 @ 08006568
	bne	.L0800662E                             @ 0800656A
.L0800656C:
	ldr	r0, [r5, #4]                           @ 0800656C
	adds	r0, #5                                @ 0800656E
	str	r0, [r5, #4]                           @ 08006570
	movs	r3, #0                                @ 08006572
	lsls	r0, r0, #1                            @ 08006574
	adds	r0, r0, r4                            @ 08006576
	ldrh	r2, [r0]                              @ 08006578
	cmp	r2, #0xfe                              @ 0800657A
	bne	.L080065A8                             @ 0800657C
	ldrh	r1, [r0, #2]                          @ 0800657E
	cmp	r1, #0xfd                              @ 08006580
	bne	.L080065A0                             @ 08006582
	movs	r3, #0xff                             @ 08006584
	b	.L080065A8                               @ 08006586
.Llit08006588:
	.word	mcBufIndex                     @ 08006588  = 0x03006A98
.Llit0800658C:
	.word	mcMusicBuf                     @ 0800658C  = 0x03007410
.Llit08006590:
	.word	mcMixerFuncs+4                 @ 08006590  = 0x083466F4
.Llit08006594:
	.word	mcPaused                       @ 08006594  = 0x03007570
.Llit08006598:
	.word	mcPsgSfx                       @ 08006598  = 0x03007590
.Llit0800659C:
	.word	mcChan                         @ 0800659C  = 0x03007770
.L080065A0:
	ldrh	r0, [r0, #2]                          @ 080065A0
	subs	r0, #1                                @ 080065A2
	mov	r2, r8                                 @ 080065A4
	str	r0, [r2]                               @ 080065A6
.L080065A8:
	adds	r2, r6, #0                            @ 080065A8
	ldr	r0, [r5, #4]                           @ 080065AA
	lsls	r0, r0, #1                            @ 080065AC
	adds	r1, r0, r4                            @ 080065AE
	ldrh	r0, [r1]                              @ 080065B0
	cmp	r0, #0xff                              @ 080065B2
	bne	.L080065B8                             @ 080065B4
	movs	r3, #0xff                             @ 080065B6
.L080065B8:
	cmp	r3, #0xff                              @ 080065B8
	bne	.L080065CC                             @ 080065BA
	adds	r0, r7, r2                            @ 080065BC
	movs	r1, #0                                @ 080065BE
	str	r1, [r0]                               @ 080065C0
	movs	r4, #0                                @ 080065C2
	movs	r0, #1                                @ 080065C4
	mov	r2, r9                                 @ 080065C6
	str	r0, [r2]                               @ 080065C8
	b	.L080065F6                               @ 080065CA
.L080065CC:
	adds	r0, r6, #0                            @ 080065CC
	adds	r0, #8                                @ 080065CE
	adds	r0, r7, r0                            @ 080065D0
	ldrh	r1, [r1]                              @ 080065D2
	str	r1, [r0]                               @ 080065D4
	mov	r3, r8                                 @ 080065D6
	ldr	r1, [r3]                               @ 080065D8
	lsls	r1, r1, #1                            @ 080065DA
	adds	r1, r1, r4                            @ 080065DC
	ldrh	r4, [r1, #4]                          @ 080065DE
	lsls	r0, r4, #8                            @ 080065E0
	ldrh	r2, [r1, #2]                          @ 080065E2
	orrs	r0, r2                                @ 080065E4
	lsls	r0, r0, #0x10                         @ 080065E6
	lsrs	r4, r0, #0x10                         @ 080065E8
	ldrh	r3, [r1, #6]                          @ 080065EA
	lsls	r0, r3, #8                            @ 080065EC
	ldrh	r1, [r1, #8]                          @ 080065EE
	orrs	r0, r1                                @ 080065F0
	lsls	r0, r0, #0x10                         @ 080065F2
	lsrs	r1, r0, #0x10                         @ 080065F4
.L080065F6:
	mov	r0, r10                                @ 080065F6
	cmp	r0, #0                                 @ 080065F8
	bne	.L08006604                             @ 080065FA
	ldr	r0, .Llit08006970                      @ 080065FC  =REG_SOUND1CNT_H
	strh	r4, [r0]                              @ 080065FE
	adds	r0, #2                                @ 08006600
	strh	r1, [r0]                              @ 08006602
.L08006604:
	mov	r2, r10                                @ 08006604
	cmp	r2, #1                                 @ 08006606
	bne	.L08006612                             @ 08006608
	ldr	r0, .Llit08006974                      @ 0800660A  =REG_SOUND2CNT_L
	strh	r4, [r0]                              @ 0800660C
	adds	r0, #4                                @ 0800660E
	strh	r1, [r0]                              @ 08006610
.L08006612:
	mov	r3, r10                                @ 08006612
	cmp	r3, #2                                 @ 08006614
	bne	.L08006620                             @ 08006616
	ldr	r0, .Llit08006978                      @ 08006618  =REG_SOUND3CNT_H
	strh	r4, [r0]                              @ 0800661A
	adds	r0, #2                                @ 0800661C
	strh	r1, [r0]                              @ 0800661E
.L08006620:
	mov	r0, r10                                @ 08006620
	cmp	r0, #3                                 @ 08006622
	bne	.L0800662E                             @ 08006624
	ldr	r0, .Llit0800697C                      @ 08006626  =REG_SOUND4CNT_L
	strh	r4, [r0]                              @ 08006628
	adds	r0, #4                                @ 0800662A
	strh	r1, [r0]                              @ 0800662C
.L0800662E:
	movs	r1, #0x48                             @ 0800662E
	add	r9, r1                                 @ 08006630
	movs	r2, #0xc                              @ 08006632
	add	r8, r2                                 @ 08006634
	adds	r7, #0xc                              @ 08006636
	adds	r5, #0xc                              @ 08006638
	movs	r3, #1                                @ 0800663A
	add	r10, r3                                @ 0800663C
	mov	r4, r10                                @ 0800663E
	cmp	r4, #3                                 @ 08006640
	ble	.L08006552                             @ 08006642
	mov	r5, r12                                @ 08006644
	ldr	r0, [r5]                               @ 08006646
	cmp	r0, #0                                 @ 08006648
	beq	.L08006650                             @ 0800664A
	bl	.L080072C8                              @ 0800664C  long branch
.L08006650:
	ldr	r3, .Llit08006980                      @ 08006650  =mcTempoAcc
	ldr	r2, .Llit08006984                      @ 08006652  =mcTempo
	ldr	r1, [r3]                               @ 08006654
	ldr	r0, [r2]                               @ 08006656
	adds	r0, r1, r0                            @ 08006658
	str	r0, [r3]                               @ 0800665A
	cmp	r0, #0xff                              @ 0800665C  tempo gate: at most one tick per frame
	bhi	.L08006664                             @ 0800665E
	bl	.L080072C8                              @ 08006660  long branch
.L08006664:
	ldr	r6, .Llit08006988                      @ 08006664  =0xFFFFFF00
	adds	r0, r0, r6                            @ 08006666
	str	r0, [r3]                               @ 08006668
	movs	r7, #0                                @ 0800666A
	mov	r10, r7                                @ 0800666C
	ldr	r0, .Llit0800698C                      @ 0800666E  =mcChan
	mov	r12, r0                                @ 08006670
.L08006672:
	mov	r2, r10                                @ 08006672
	lsls	r1, r2, #3                            @ 08006674
	adds	r0, r1, r2                            @ 08006676
	lsls	r2, r0, #3                            @ 08006678
	mov	r3, r12                                @ 0800667A
	adds	r0, r2, r3                            @ 0800667C
	ldr	r0, [r0]                               @ 0800667E
	mov	r4, r10                                @ 08006680
	adds	r4, #1                                @ 08006682
	str	r4, [sp, #0x58]                        @ 08006684
	str	r1, [sp, #0x5c]                        @ 08006686
	cmp	r0, #1                                 @ 08006688
	beq	.L08006690                             @ 0800668A
	bl	.L080072BC                              @ 0800668C  long branch
.L08006690:
	mov	r0, r12                                @ 08006690
	adds	r0, #0x20                             @ 08006692
	adds	r0, r2, r0                            @ 08006694
	ldr	r0, [r0]                               @ 08006696
	cmp	r0, #0                                 @ 08006698
	bne	.L080066A0                             @ 0800669A
	bl	.L080072BC                              @ 0800669C  long branch
.L080066A0:
	ldr	r5, .Llit0800698C                      @ 080066A0  =mcChan
	mov	r9, r5                                 @ 080066A2
	ldr	r6, [sp, #0x5c]                        @ 080066A4
	add	r6, r10                                @ 080066A6
	str	r6, [sp, #0x28]                        @ 080066A8
	lsls	r7, r6, #3                            @ 080066AA
	str	r7, [sp, #0x2c]                        @ 080066AC
	mov	r0, r9                                 @ 080066AE
	adds	r0, #0x10                             @ 080066B0
	adds	r0, r7, r0                            @ 080066B2
	str	r0, [sp, #0x30]                        @ 080066B4
	ldr	r0, .Llit08006990                      @ 080066B6  =mcChan+CH_patPtr
	adds	r0, r7, r0                            @ 080066B8
	str	r0, [sp, #0x34]                        @ 080066BA
	mov	r0, r9                                 @ 080066BC
	adds	r0, #0x14                             @ 080066BE
	adds	r0, r7, r0                            @ 080066C0
	str	r0, [sp, #0x44]                        @ 080066C2
	ldr	r1, .Llit08006994                      @ 080066C4  =mcChan+CH_freq
	adds	r1, r7, r1                            @ 080066C6
	str	r1, [sp, #0x48]                        @ 080066C8
	ldr	r2, .Llit08006998                      @ 080066CA  =mcChan+CH_envIdx
	adds	r2, r7, r2                            @ 080066CC
	str	r2, [sp, #0x4c]                        @ 080066CE
	ldr	r3, .Llit0800699C                      @ 080066D0  =mcChan+CH_pitchTimer
	adds	r3, r7, r3                            @ 080066D2
	str	r3, [sp, #0x50]                        @ 080066D4
.L080066D6:
	movs	r4, #0x60                             @ 080066D6
	str	r4, [sp, #0x24]                        @ 080066D8
	ldr	r5, [sp, #0x30]                        @ 080066DA
	ldr	r0, [r5]                               @ 080066DC
	cmp	r0, #0                                 @ 080066DE
	bne	.L080066E4                             @ 080066E0
	b	.L08006CC2                               @ 080066E2
.L080066E4:
	subs	r0, #1                                @ 080066E4
	str	r0, [r5]                               @ 080066E6
	mov	r0, r12                                @ 080066E8
	adds	r0, #4                                @ 080066EA
	ldr	r6, [sp, #0x2c]                        @ 080066EC
	adds	r0, r6, r0                            @ 080066EE
	ldr	r0, [r0]                               @ 080066F0
	cmp	r0, #0                                 @ 080066F2
	bne	.L080066F8                             @ 080066F4
	b	.L08006CB8                               @ 080066F6
.L080066F8:
	mov	r7, r10                                @ 080066F8
	cmp	r7, #0                                 @ 080066FA
	beq	.L08006700                             @ 080066FC
	b	.L08006878                               @ 080066FE
.L08006700:
	mov	r1, r9                                 @ 08006700
	ldr	r0, [r1, #0x1c]                        @ 08006702
	lsls	r0, r0, #2                            @ 08006704
	ldr	r2, .Llit080069A0                      @ 08006706  =mcInstTable
	adds	r0, r0, r2                            @ 08006708
	ldr	r6, [r0]                               @ 0800670A
	ldr	r2, [r6, #0x20]                        @ 0800670C
	cmp	r2, #0                                 @ 0800670E
	beq	.L0800677C                             @ 08006710
	ldr	r0, [r1, #0x44]                        @ 08006712
	subs	r0, #1                                @ 08006714
	str	r0, [r1, #0x44]                        @ 08006716
	cmp	r0, #0                                 @ 08006718
	bne	.L0800677C                             @ 0800671A
	ldr	r0, [r1, #0x40]                        @ 0800671C
	adds	r0, #2                                @ 0800671E
	str	r0, [r1, #0x40]                        @ 08006720
	lsls	r0, r0, #1                            @ 08006722
	adds	r0, r0, r2                            @ 08006724
	ldrh	r3, [r0]                              @ 08006726
	cmp	r3, #0xfe                              @ 08006728
	bne	.L08006732                             @ 0800672A
	movs	r4, #2                                @ 0800672C
	ldrsh	r0, [r0, r4]                         @ 0800672E
	str	r0, [r1, #0x40]                        @ 08006730
.L08006732:
	mov	r5, r9                                 @ 08006732
	ldr	r4, [r5, #0x40]                        @ 08006734
	lsls	r0, r4, #1                            @ 08006736
	adds	r3, r0, r2                            @ 08006738
	movs	r7, #0                                @ 0800673A
	ldrsh	r0, [r3, r7]                         @ 0800673C
	cmp	r0, #0xfd                              @ 0800673E
	bgt	.L08006770                             @ 08006740
	movs	r0, #2                                @ 08006742
	ldrsh	r1, [r3, r0]                         @ 08006744
	ldr	r0, [r5, #0x14]                        @ 08006746
	adds	r0, r0, r1                            @ 08006748
	ldr	r2, .Llit080069A4                      @ 0800674A  =mcFreqHi
	adds	r1, r0, r2                            @ 0800674C
	ldrb	r1, [r1]                              @ 0800674E
	lsls	r2, r1, #8                            @ 08006750
	ldr	r1, .Llit080069A8                      @ 08006752  =mcFreqLo
	adds	r0, r0, r1                            @ 08006754
	ldrb	r0, [r0]                              @ 08006756
	orrs	r2, r0                                @ 08006758
	str	r2, [r5, #0x18]                        @ 0800675A
	movs	r5, #0                                @ 0800675C
	ldrsh	r0, [r3, r5]                         @ 0800675E
	mov	r7, r9                                 @ 08006760
	str	r0, [r7, #0x44]                        @ 08006762
	ldr	r0, [r6]                               @ 08006764
	lsls	r0, r0, #0x18                         @ 08006766
	lsrs	r0, r0, #0x10                         @ 08006768
	orrs	r0, r2                                @ 0800676A
	ldr	r1, .Llit080069AC                      @ 0800676C  =REG_SOUND1CNT_X
	strh	r0, [r1]                              @ 0800676E
.L08006770:
	ldrh	r3, [r3]                              @ 08006770
	cmp	r3, #0xff                              @ 08006772
	bne	.L0800677C                             @ 08006774
	subs	r0, r4, #2                            @ 08006776
	mov	r2, r9                                 @ 08006778
	str	r0, [r2, #0x40]                        @ 0800677A
.L0800677C:
	ldr	r2, [r6, #0x18]                        @ 0800677C
	cmp	r2, #0                                 @ 0800677E
	beq	.L080067F6                             @ 08006780
	ldr	r3, [sp, #0x28]                        @ 08006782
	lsls	r1, r3, #3                            @ 08006784
	ldr	r5, .Llit0800699C                      @ 08006786  =mcChan+CH_pitchTimer
	adds	r4, r1, r5                            @ 08006788
	ldr	r0, [r4]                               @ 0800678A
	subs	r0, #1                                @ 0800678C
	str	r0, [r4]                               @ 0800678E
	cmp	r0, #0                                 @ 08006790
	bne	.L080067F6                             @ 08006792
	mov	r0, r12                                @ 08006794
	adds	r0, #0x38                             @ 08006796
	adds	r5, r1, r0                            @ 08006798
	ldr	r0, [r5]                               @ 0800679A
	adds	r0, #2                                @ 0800679C
	str	r0, [r5]                               @ 0800679E
	lsls	r0, r0, #1                            @ 080067A0
	adds	r0, r0, r2                            @ 080067A2
	ldrh	r7, [r0]                              @ 080067A4
	cmp	r7, #0xfe                              @ 080067A6
	bne	.L080067B0                             @ 080067A8
	movs	r3, #2                                @ 080067AA
	ldrsh	r0, [r0, r3]                         @ 080067AC
	str	r0, [r5]                               @ 080067AE
.L080067B0:
	ldr	r0, [r5]                               @ 080067B0
	lsls	r0, r0, #1                            @ 080067B2
	adds	r3, r0, r2                            @ 080067B4
	movs	r7, #0                                @ 080067B6
	ldrsh	r0, [r3, r7]                         @ 080067B8
	cmp	r0, #0xfd                              @ 080067BA
	bgt	.L080067E6                             @ 080067BC
	movs	r7, #2                                @ 080067BE
	ldrsh	r0, [r3, r7]                         @ 080067C0
	str	r0, [r4]                               @ 080067C2
	ldr	r0, .Llit08006994                      @ 080067C4  =mcChan+CH_freq
	adds	r1, r1, r0                            @ 080067C6
	ldr	r3, [r1]                               @ 080067C8
	ldr	r0, [r5]                               @ 080067CA
	lsls	r0, r0, #1                            @ 080067CC
	adds	r0, r0, r2                            @ 080067CE
	movs	r4, #0                                @ 080067D0
	ldrsh	r0, [r0, r4]                         @ 080067D2
	adds	r3, r3, r0                            @ 080067D4
	str	r3, [r1]                               @ 080067D6
	lsls	r1, r3, #0x10                         @ 080067D8
	ldr	r0, [r6]                               @ 080067DA
	lsls	r0, r0, #0x18                         @ 080067DC
	orrs	r0, r1                                @ 080067DE
	lsrs	r4, r0, #0x10                         @ 080067E0
	ldr	r7, .Llit080069AC                      @ 080067E2  =REG_SOUND1CNT_X
	strh	r4, [r7]                              @ 080067E4
.L080067E6:
	ldr	r1, [r5]                               @ 080067E6
	lsls	r0, r1, #1                            @ 080067E8
	adds	r0, r0, r2                            @ 080067EA
	ldrh	r0, [r0]                              @ 080067EC
	cmp	r0, #0xff                              @ 080067EE
	bne	.L080067F6                             @ 080067F0
	subs	r0, r1, #2                            @ 080067F2
	str	r0, [r5]                               @ 080067F4
.L080067F6:
	ldr	r2, [r6, #0x10]                        @ 080067F6
	cmp	r2, #0                                 @ 080067F8
	beq	.L08006878                             @ 080067FA
	ldr	r0, [sp, #0x28]                        @ 080067FC
	lsls	r7, r0, #3                            @ 080067FE
	mov	r0, r12                                @ 08006800
	adds	r0, #0x34                             @ 08006802
	adds	r5, r7, r0                            @ 08006804
	ldr	r0, [r5]                               @ 08006806
	subs	r0, #1                                @ 08006808
	str	r0, [r5]                               @ 0800680A
	cmp	r0, #0                                 @ 0800680C
	bne	.L08006878                             @ 0800680E
	ldr	r1, .Llit08006998                      @ 08006810  =mcChan+CH_envIdx
	adds	r3, r7, r1                            @ 08006812
	ldr	r0, [r3]                               @ 08006814
	adds	r0, #2                                @ 08006816
	str	r0, [r3]                               @ 08006818
	lsls	r0, r0, #1                            @ 0800681A
	adds	r0, r0, r2                            @ 0800681C
	ldrh	r4, [r0]                              @ 0800681E
	cmp	r4, #0xfe                              @ 08006820
	bne	.L0800682A                             @ 08006822
	movs	r1, #2                                @ 08006824
	ldrsh	r0, [r0, r1]                         @ 08006826
	str	r0, [r3]                               @ 08006828
.L0800682A:
	ldr	r0, [r3]                               @ 0800682A
	lsls	r0, r0, #1                            @ 0800682C
	adds	r1, r0, r2                            @ 0800682E
	ldrh	r4, [r1]                              @ 08006830
	mov	r8, r4                                 @ 08006832
	movs	r4, #0                                @ 08006834
	ldrsh	r0, [r1, r4]                         @ 08006836
	cmp	r0, #0xfd                              @ 08006838
	bgt	.L08006868                             @ 0800683A
	mov	r4, r8                                 @ 0800683C
	lsls	r0, r4, #8                            @ 0800683E
	ldrh	r4, [r6, #4]                          @ 08006840
	orrs	r0, r4                                @ 08006842
	lsls	r0, r0, #0x10                         @ 08006844
	lsrs	r4, r0, #0x10                         @ 08006846
	ldr	r0, .Llit08006970                      @ 08006848  =REG_SOUND1CNT_H
	strh	r4, [r0]                              @ 0800684A
	movs	r4, #2                                @ 0800684C
	ldrsh	r0, [r1, r4]                         @ 0800684E
	str	r0, [r5]                               @ 08006850
	ldr	r1, [r6]                               @ 08006852
	lsls	r1, r1, #8                            @ 08006854
	ldr	r5, .Llit08006994                      @ 08006856  =mcChan+CH_freq
	adds	r0, r7, r5                            @ 08006858
	ldr	r0, [r0]                               @ 0800685A
	orrs	r0, r1                                @ 0800685C
	movs	r6, #0x80                             @ 0800685E
	lsls	r6, r6, #8                            @ 08006860
	orrs	r0, r6                                @ 08006862
	ldr	r7, .Llit080069AC                      @ 08006864  =REG_SOUND1CNT_X
	strh	r0, [r7]                              @ 08006866
.L08006868:
	ldr	r1, [r3]                               @ 08006868
	lsls	r0, r1, #1                            @ 0800686A
	adds	r0, r0, r2                            @ 0800686C
	ldrh	r0, [r0]                              @ 0800686E
	cmp	r0, #0xff                              @ 08006870
	bne	.L08006878                             @ 08006872
	subs	r0, r1, #2                            @ 08006874
	str	r0, [r3]                               @ 08006876
.L08006878:
	mov	r0, r10                                @ 08006878
	cmp	r0, #1                                 @ 0800687A
	beq	.L08006880                             @ 0800687C
	b	.L08006A4C                               @ 0800687E
.L08006880:
	mov	r1, r12                                @ 08006880
	ldr	r0, [r1, #0x64]                        @ 08006882
	lsls	r0, r0, #2                            @ 08006884
	ldr	r2, .Llit080069A0                      @ 08006886  =mcInstTable
	adds	r0, r0, r2                            @ 08006888
	ldr	r6, [r0]                               @ 0800688A
	ldr	r2, [r6, #0x20]                        @ 0800688C
	cmp	r2, #0                                 @ 0800688E
	beq	.L08006908                             @ 08006890
	mov	r4, r12                                @ 08006892
	adds	r4, #0x8c                             @ 08006894
	ldr	r0, [r4]                               @ 08006896
	subs	r0, #1                                @ 08006898
	str	r0, [r4]                               @ 0800689A
	cmp	r0, #0                                 @ 0800689C
	bne	.L08006908                             @ 0800689E
	mov	r7, r12                                @ 080068A0
	adds	r7, #0x88                             @ 080068A2
	ldr	r0, [r7]                               @ 080068A4
	adds	r0, #2                                @ 080068A6
	str	r0, [r7]                               @ 080068A8
	lsls	r0, r0, #1                            @ 080068AA
	adds	r0, r0, r2                            @ 080068AC
	ldrh	r3, [r0]                              @ 080068AE
	cmp	r3, #0xfe                              @ 080068B0
	bne	.L080068BA                             @ 080068B2
	movs	r5, #2                                @ 080068B4
	ldrsh	r0, [r0, r5]                         @ 080068B6
	str	r0, [r7]                               @ 080068B8
.L080068BA:
	ldr	r5, [r7]                               @ 080068BA
	lsls	r0, r5, #1                            @ 080068BC
	adds	r3, r0, r2                            @ 080068BE
	movs	r1, #0                                @ 080068C0
	ldrsh	r0, [r3, r1]                         @ 080068C2
	cmp	r0, #0xfd                              @ 080068C4
	bgt	.L080068FE                             @ 080068C6
	movs	r2, #2                                @ 080068C8
	ldrsh	r1, [r3, r2]                         @ 080068CA
	mov	r2, r12                                @ 080068CC
	ldr	r0, [r2, #0x5c]                        @ 080068CE
	adds	r0, r0, r1                            @ 080068D0
	ldr	r2, .Llit080069A4                      @ 080068D2  =mcFreqHi
	adds	r1, r0, r2                            @ 080068D4
	ldrb	r1, [r1]                              @ 080068D6
	lsls	r2, r1, #8                            @ 080068D8
	ldr	r1, .Llit080069A8                      @ 080068DA  =mcFreqLo
	adds	r0, r0, r1                            @ 080068DC
	ldrb	r0, [r0]                              @ 080068DE
	orrs	r2, r0                                @ 080068E0
	mov	r0, r12                                @ 080068E2
	str	r2, [r0, #0x60]                        @ 080068E4
	movs	r1, #0                                @ 080068E6
	ldrsh	r0, [r3, r1]                         @ 080068E8
	str	r0, [r4]                               @ 080068EA
	mov	r2, r12                                @ 080068EC
	ldr	r1, [r2, #0x60]                        @ 080068EE
	lsls	r1, r1, #0x10                         @ 080068F0
	ldr	r0, [r6]                               @ 080068F2
	lsls	r0, r0, #0x18                         @ 080068F4
	orrs	r0, r1                                @ 080068F6
	lsrs	r4, r0, #0x10                         @ 080068F8
	ldr	r0, .Llit080069B0                      @ 080068FA  =REG_SOUND2CNT_H
	strh	r4, [r0]                              @ 080068FC
.L080068FE:
	ldrh	r3, [r3]                              @ 080068FE
	cmp	r3, #0xff                              @ 08006900
	bne	.L08006908                             @ 08006902
	subs	r0, r5, #2                            @ 08006904
	str	r0, [r7]                               @ 08006906
.L08006908:
	ldr	r2, [r6, #0x18]                        @ 08006908
	cmp	r2, #0                                 @ 0800690A
	beq	.L080069CA                             @ 0800690C
	ldr	r3, [sp, #0x28]                        @ 0800690E
	lsls	r1, r3, #3                            @ 08006910
	ldr	r5, .Llit0800699C                      @ 08006912  =mcChan+CH_pitchTimer
	adds	r4, r1, r5                            @ 08006914
	ldr	r0, [r4]                               @ 08006916
	subs	r0, #1                                @ 08006918
	str	r0, [r4]                               @ 0800691A
	cmp	r0, #0                                 @ 0800691C
	bne	.L080069CA                             @ 0800691E
	mov	r0, r12                                @ 08006920
	adds	r0, #0x38                             @ 08006922
	adds	r5, r1, r0                            @ 08006924
	ldr	r0, [r5]                               @ 08006926
	adds	r0, #2                                @ 08006928
	str	r0, [r5]                               @ 0800692A
	lsls	r0, r0, #1                            @ 0800692C
	adds	r0, r0, r2                            @ 0800692E
	ldrh	r7, [r0]                              @ 08006930
	cmp	r7, #0xfe                              @ 08006932
	bne	.L0800693C                             @ 08006934
	movs	r3, #2                                @ 08006936
	ldrsh	r0, [r0, r3]                         @ 08006938
	str	r0, [r5]                               @ 0800693A
.L0800693C:
	ldr	r0, [r5]                               @ 0800693C
	lsls	r0, r0, #1                            @ 0800693E
	adds	r3, r0, r2                            @ 08006940
	movs	r7, #0                                @ 08006942
	ldrsh	r0, [r3, r7]                         @ 08006944
	cmp	r0, #0xfd                              @ 08006946
	bgt	.L080069BA                             @ 08006948
	movs	r7, #2                                @ 0800694A
	ldrsh	r0, [r3, r7]                         @ 0800694C
	str	r0, [r4]                               @ 0800694E
	ldr	r0, .Llit08006994                      @ 08006950  =mcChan+CH_freq
	adds	r1, r1, r0                            @ 08006952
	ldr	r3, [r1]                               @ 08006954
	ldr	r0, [r5]                               @ 08006956
	lsls	r0, r0, #1                            @ 08006958
	adds	r0, r0, r2                            @ 0800695A
	movs	r4, #0                                @ 0800695C
	ldrsh	r0, [r0, r4]                         @ 0800695E
	adds	r3, r3, r0                            @ 08006960
	str	r3, [r1]                               @ 08006962
	lsls	r1, r3, #0x10                         @ 08006964
	ldr	r0, [r6]                               @ 08006966
	lsls	r0, r0, #0x18                         @ 08006968
	orrs	r0, r1                                @ 0800696A
	b	.L080069B4                               @ 0800696C
	.hword	0x0000                          @ 0800696E  (padding)
.Llit08006970:
	.word	REG_SOUND1CNT_H                @ 08006970  = 0x04000062
.Llit08006974:
	.word	REG_SOUND2CNT_L                @ 08006974  = 0x04000068
.Llit08006978:
	.word	REG_SOUND3CNT_H                @ 08006978  = 0x04000072
.Llit0800697C:
	.word	REG_SOUND4CNT_L                @ 0800697C  = 0x04000078
.Llit08006980:
	.word	mcTempoAcc                     @ 08006980  = 0x03007574
.Llit08006984:
	.word	mcTempo                        @ 08006984  = 0x03007404
.Llit08006988:
	.word	0xFFFFFF00                     @ 08006988
.Llit0800698C:
	.word	mcChan                         @ 0800698C  = 0x03007770
.Llit08006990:
	.word	mcChan+CH_patPtr               @ 08006990  = 0x03007794
.Llit08006994:
	.word	mcChan+CH_freq                 @ 08006994  = 0x03007788
.Llit08006998:
	.word	mcChan+CH_envIdx               @ 08006998  = 0x030077A0
.Llit0800699C:
	.word	mcChan+CH_pitchTimer           @ 0800699C  = 0x030077AC
.Llit080069A0:
	.word	mcInstTable                    @ 080069A0  = 0x083D5214
.Llit080069A4:
	.word	mcFreqHi                       @ 080069A4  = 0x083D4861
.Llit080069A8:
	.word	mcFreqLo                       @ 080069A8  = 0x083D4800
.Llit080069AC:
	.word	REG_SOUND1CNT_X                @ 080069AC  = 0x04000064
.Llit080069B0:
	.word	REG_SOUND2CNT_H                @ 080069B0  = 0x0400006C
.L080069B4:
	lsrs	r4, r0, #0x10                         @ 080069B4
	ldr	r7, .Llit08006C1C                      @ 080069B6  =REG_SOUND2CNT_H
	strh	r4, [r7]                              @ 080069B8
.L080069BA:
	ldr	r1, [r5]                               @ 080069BA
	lsls	r0, r1, #1                            @ 080069BC
	adds	r0, r0, r2                            @ 080069BE
	ldrh	r0, [r0]                              @ 080069C0
	cmp	r0, #0xff                              @ 080069C2
	bne	.L080069CA                             @ 080069C4
	subs	r0, r1, #2                            @ 080069C6
	str	r0, [r5]                               @ 080069C8
.L080069CA:
	ldr	r2, [r6, #0x10]                        @ 080069CA
	cmp	r2, #0                                 @ 080069CC
	beq	.L08006A4C                             @ 080069CE
	ldr	r0, [sp, #0x28]                        @ 080069D0
	lsls	r7, r0, #3                            @ 080069D2
	mov	r0, r12                                @ 080069D4
	adds	r0, #0x34                             @ 080069D6
	adds	r5, r7, r0                            @ 080069D8
	ldr	r0, [r5]                               @ 080069DA
	subs	r0, #1                                @ 080069DC
	str	r0, [r5]                               @ 080069DE
	cmp	r0, #0                                 @ 080069E0
	bne	.L08006A4C                             @ 080069E2
	ldr	r1, .Llit08006C20                      @ 080069E4  =mcChan+CH_envIdx
	adds	r3, r7, r1                            @ 080069E6
	ldr	r0, [r3]                               @ 080069E8
	adds	r0, #2                                @ 080069EA
	str	r0, [r3]                               @ 080069EC
	lsls	r0, r0, #1                            @ 080069EE
	adds	r0, r0, r2                            @ 080069F0
	ldrh	r4, [r0]                              @ 080069F2
	cmp	r4, #0xfe                              @ 080069F4
	bne	.L080069FE                             @ 080069F6
	movs	r1, #2                                @ 080069F8
	ldrsh	r0, [r0, r1]                         @ 080069FA
	str	r0, [r3]                               @ 080069FC
.L080069FE:
	ldr	r0, [r3]                               @ 080069FE
	lsls	r0, r0, #1                            @ 08006A00
	adds	r1, r0, r2                            @ 08006A02
	ldrh	r4, [r1]                              @ 08006A04
	mov	r8, r4                                 @ 08006A06
	movs	r4, #0                                @ 08006A08
	ldrsh	r0, [r1, r4]                         @ 08006A0A
	cmp	r0, #0xfd                              @ 08006A0C
	bgt	.L08006A3C                             @ 08006A0E
	mov	r4, r8                                 @ 08006A10
	lsls	r0, r4, #8                            @ 08006A12
	ldrh	r4, [r6, #4]                          @ 08006A14
	orrs	r0, r4                                @ 08006A16
	lsls	r0, r0, #0x10                         @ 08006A18
	lsrs	r4, r0, #0x10                         @ 08006A1A
	ldr	r0, .Llit08006C24                      @ 08006A1C  =REG_SOUND2CNT_L
	strh	r4, [r0]                              @ 08006A1E
	movs	r4, #2                                @ 08006A20
	ldrsh	r0, [r1, r4]                         @ 08006A22
	str	r0, [r5]                               @ 08006A24
	ldr	r1, [r6]                               @ 08006A26
	lsls	r1, r1, #8                            @ 08006A28
	ldr	r5, .Llit08006C28                      @ 08006A2A  =mcChan+CH_freq
	adds	r0, r7, r5                            @ 08006A2C
	ldr	r0, [r0]                               @ 08006A2E
	orrs	r0, r1                                @ 08006A30
	movs	r6, #0x80                             @ 08006A32
	lsls	r6, r6, #8                            @ 08006A34
	orrs	r0, r6                                @ 08006A36
	ldr	r7, .Llit08006C1C                      @ 08006A38  =REG_SOUND2CNT_H
	strh	r0, [r7]                              @ 08006A3A
.L08006A3C:
	ldr	r1, [r3]                               @ 08006A3C
	lsls	r0, r1, #1                            @ 08006A3E
	adds	r0, r0, r2                            @ 08006A40
	ldrh	r0, [r0]                              @ 08006A42
	cmp	r0, #0xff                              @ 08006A44
	bne	.L08006A4C                             @ 08006A46
	subs	r0, r1, #2                            @ 08006A48
	str	r0, [r3]                               @ 08006A4A
.L08006A4C:
	mov	r0, r10                                @ 08006A4C
	cmp	r0, #2                                 @ 08006A4E
	beq	.L08006A54                             @ 08006A50
	b	.L08006BD6                               @ 08006A52
.L08006A54:
	mov	r0, r12                                @ 08006A54
	adds	r0, #0xac                             @ 08006A56
	ldr	r0, [r0]                               @ 08006A58
	lsls	r0, r0, #2                            @ 08006A5A
	ldr	r1, .Llit08006C2C                      @ 08006A5C  =mcInstTable
	adds	r0, r0, r1                            @ 08006A5E
	ldr	r6, [r0]                               @ 08006A60
	ldr	r2, [r6, #0x20]                        @ 08006A62
	cmp	r2, #0                                 @ 08006A64
	beq	.L08006ADA                             @ 08006A66
	mov	r7, r12                                @ 08006A68
	adds	r7, #0xd4                             @ 08006A6A
	ldr	r0, [r7]                               @ 08006A6C
	subs	r0, #1                                @ 08006A6E
	str	r0, [r7]                               @ 08006A70
	cmp	r0, #0                                 @ 08006A72
	bne	.L08006ADA                             @ 08006A74
	mov	r5, r12                                @ 08006A76
	adds	r5, #0xd0                             @ 08006A78
	ldr	r0, [r5]                               @ 08006A7A
	adds	r0, #2                                @ 08006A7C
	str	r0, [r5]                               @ 08006A7E
	lsls	r0, r0, #1                            @ 08006A80
	adds	r0, r0, r2                            @ 08006A82
	ldrh	r3, [r0]                              @ 08006A84
	cmp	r3, #0xfe                              @ 08006A86
	bne	.L08006A90                             @ 08006A88
	movs	r4, #2                                @ 08006A8A
	ldrsh	r0, [r0, r4]                         @ 08006A8C
	str	r0, [r5]                               @ 08006A8E
.L08006A90:
	ldr	r4, [r5]                               @ 08006A90
	lsls	r0, r4, #1                            @ 08006A92
	adds	r3, r0, r2                            @ 08006A94
	movs	r1, #0                                @ 08006A96
	ldrsh	r0, [r3, r1]                         @ 08006A98
	cmp	r0, #0xfd                              @ 08006A9A
	bgt	.L08006AD0                             @ 08006A9C
	mov	r0, r12                                @ 08006A9E
	adds	r0, #0xa4                             @ 08006AA0
	movs	r2, #2                                @ 08006AA2
	ldrsh	r1, [r3, r2]                         @ 08006AA4
	ldr	r0, [r0]                               @ 08006AA6
	adds	r0, r0, r1                            @ 08006AA8
	ldr	r2, .Llit08006C30                      @ 08006AAA  =mcFreqHi
	adds	r1, r0, r2                            @ 08006AAC
	ldrb	r1, [r1]                              @ 08006AAE
	lsls	r2, r1, #8                            @ 08006AB0
	ldr	r1, .Llit08006C34                      @ 08006AB2  =mcFreqLo
	adds	r0, r0, r1                            @ 08006AB4
	ldrb	r0, [r0]                              @ 08006AB6
	orrs	r2, r0                                @ 08006AB8
	ldr	r0, .Llit08006C38                      @ 08006ABA  =mcChan+0x90+CH_freq
	str	r2, [r0]                               @ 08006ABC
	movs	r1, #0                                @ 08006ABE
	ldrsh	r0, [r3, r1]                         @ 08006AC0
	str	r0, [r7]                               @ 08006AC2
	ldr	r0, [r6]                               @ 08006AC4
	lsls	r0, r0, #0x18                         @ 08006AC6
	lsrs	r0, r0, #0x10                         @ 08006AC8
	orrs	r0, r2                                @ 08006ACA
	ldr	r2, .Llit08006C3C                      @ 08006ACC  =REG_SOUND3CNT_X
	strh	r0, [r2]                              @ 08006ACE
.L08006AD0:
	ldrh	r3, [r3]                              @ 08006AD0
	cmp	r3, #0xff                              @ 08006AD2
	bne	.L08006ADA                             @ 08006AD4
	subs	r0, r4, #2                            @ 08006AD6
	str	r0, [r5]                               @ 08006AD8
.L08006ADA:
	ldr	r2, [r6, #0x18]                        @ 08006ADA
	cmp	r2, #0                                 @ 08006ADC
	beq	.L08006B54                             @ 08006ADE
	ldr	r3, [sp, #0x28]                        @ 08006AE0
	lsls	r1, r3, #3                            @ 08006AE2
	ldr	r5, .Llit08006C40                      @ 08006AE4  =mcChan+CH_pitchTimer
	adds	r4, r1, r5                            @ 08006AE6
	ldr	r0, [r4]                               @ 08006AE8
	subs	r0, #1                                @ 08006AEA
	str	r0, [r4]                               @ 08006AEC
	cmp	r0, #0                                 @ 08006AEE
	bne	.L08006B54                             @ 08006AF0
	mov	r0, r12                                @ 08006AF2
	adds	r0, #0x38                             @ 08006AF4
	adds	r5, r1, r0                            @ 08006AF6
	ldr	r0, [r5]                               @ 08006AF8
	adds	r0, #2                                @ 08006AFA
	str	r0, [r5]                               @ 08006AFC
	lsls	r0, r0, #1                            @ 08006AFE
	adds	r0, r0, r2                            @ 08006B00
	ldrh	r7, [r0]                              @ 08006B02
	cmp	r7, #0xfe                              @ 08006B04
	bne	.L08006B0E                             @ 08006B06
	movs	r3, #2                                @ 08006B08
	ldrsh	r0, [r0, r3]                         @ 08006B0A
	str	r0, [r5]                               @ 08006B0C
.L08006B0E:
	ldr	r0, [r5]                               @ 08006B0E
	lsls	r0, r0, #1                            @ 08006B10
	adds	r3, r0, r2                            @ 08006B12
	movs	r7, #0                                @ 08006B14
	ldrsh	r0, [r3, r7]                         @ 08006B16
	cmp	r0, #0xfd                              @ 08006B18
	bgt	.L08006B44                             @ 08006B1A
	movs	r7, #2                                @ 08006B1C
	ldrsh	r0, [r3, r7]                         @ 08006B1E
	str	r0, [r4]                               @ 08006B20
	ldr	r0, .Llit08006C28                      @ 08006B22  =mcChan+CH_freq
	adds	r1, r1, r0                            @ 08006B24
	ldr	r3, [r1]                               @ 08006B26
	ldr	r0, [r5]                               @ 08006B28
	lsls	r0, r0, #1                            @ 08006B2A
	adds	r0, r0, r2                            @ 08006B2C
	movs	r4, #0                                @ 08006B2E
	ldrsh	r0, [r0, r4]                         @ 08006B30
	adds	r3, r3, r0                            @ 08006B32
	str	r3, [r1]                               @ 08006B34
	lsls	r1, r3, #0x10                         @ 08006B36
	ldr	r0, [r6]                               @ 08006B38
	lsls	r0, r0, #0x18                         @ 08006B3A
	orrs	r0, r1                                @ 08006B3C
	lsrs	r4, r0, #0x10                         @ 08006B3E
	ldr	r7, .Llit08006C3C                      @ 08006B40  =REG_SOUND3CNT_X
	strh	r4, [r7]                              @ 08006B42
.L08006B44:
	ldr	r1, [r5]                               @ 08006B44
	lsls	r0, r1, #1                            @ 08006B46
	adds	r0, r0, r2                            @ 08006B48
	ldrh	r0, [r0]                              @ 08006B4A
	cmp	r0, #0xff                              @ 08006B4C
	bne	.L08006B54                             @ 08006B4E
	subs	r0, r1, #2                            @ 08006B50
	str	r0, [r5]                               @ 08006B52
.L08006B54:
	ldr	r2, [r6, #0x10]                        @ 08006B54
	cmp	r2, #0                                 @ 08006B56
	beq	.L08006BD6                             @ 08006B58
	ldr	r0, [sp, #0x28]                        @ 08006B5A
	lsls	r7, r0, #3                            @ 08006B5C
	mov	r0, r12                                @ 08006B5E
	adds	r0, #0x34                             @ 08006B60
	adds	r5, r7, r0                            @ 08006B62
	ldr	r0, [r5]                               @ 08006B64
	subs	r0, #1                                @ 08006B66
	str	r0, [r5]                               @ 08006B68
	cmp	r0, #0                                 @ 08006B6A
	bne	.L08006BD6                             @ 08006B6C
	ldr	r1, .Llit08006C20                      @ 08006B6E  =mcChan+CH_envIdx
	adds	r3, r7, r1                            @ 08006B70
	ldr	r0, [r3]                               @ 08006B72
	adds	r0, #2                                @ 08006B74
	str	r0, [r3]                               @ 08006B76
	lsls	r0, r0, #1                            @ 08006B78
	adds	r0, r0, r2                            @ 08006B7A
	ldrh	r4, [r0]                              @ 08006B7C
	cmp	r4, #0xfe                              @ 08006B7E
	bne	.L08006B88                             @ 08006B80
	movs	r1, #2                                @ 08006B82
	ldrsh	r0, [r0, r1]                         @ 08006B84
	str	r0, [r3]                               @ 08006B86
.L08006B88:
	ldr	r0, [r3]                               @ 08006B88
	lsls	r0, r0, #1                            @ 08006B8A
	adds	r1, r0, r2                            @ 08006B8C
	ldrh	r4, [r1]                              @ 08006B8E
	mov	r8, r4                                 @ 08006B90
	movs	r4, #0                                @ 08006B92
	ldrsh	r0, [r1, r4]                         @ 08006B94
	cmp	r0, #0xfd                              @ 08006B96
	bgt	.L08006BC6                             @ 08006B98
	mov	r4, r8                                 @ 08006B9A
	lsls	r0, r4, #8                            @ 08006B9C
	ldrh	r4, [r6, #4]                          @ 08006B9E
	orrs	r0, r4                                @ 08006BA0
	lsls	r0, r0, #0x10                         @ 08006BA2
	lsrs	r4, r0, #0x10                         @ 08006BA4
	ldr	r0, .Llit08006C44                      @ 08006BA6  =REG_SOUND3CNT_H
	strh	r4, [r0]                              @ 08006BA8
	movs	r4, #2                                @ 08006BAA
	ldrsh	r0, [r1, r4]                         @ 08006BAC
	str	r0, [r5]                               @ 08006BAE
	ldr	r1, [r6]                               @ 08006BB0
	lsls	r1, r1, #8                            @ 08006BB2
	ldr	r5, .Llit08006C28                      @ 08006BB4  =mcChan+CH_freq
	adds	r0, r7, r5                            @ 08006BB6
	ldr	r0, [r0]                               @ 08006BB8
	orrs	r0, r1                                @ 08006BBA
	movs	r6, #0x80                             @ 08006BBC
	lsls	r6, r6, #8                            @ 08006BBE
	orrs	r0, r6                                @ 08006BC0
	ldr	r7, .Llit08006C3C                      @ 08006BC2  =REG_SOUND3CNT_X
	strh	r0, [r7]                              @ 08006BC4
.L08006BC6:
	ldr	r1, [r3]                               @ 08006BC6
	lsls	r0, r1, #1                            @ 08006BC8
	adds	r0, r0, r2                            @ 08006BCA
	ldrh	r0, [r0]                              @ 08006BCC
	cmp	r0, #0xff                              @ 08006BCE
	bne	.L08006BD6                             @ 08006BD0
	subs	r0, r1, #2                            @ 08006BD2
	str	r0, [r3]                               @ 08006BD4
.L08006BD6:
	mov	r0, r10                                @ 08006BD6
	cmp	r0, #3                                 @ 08006BD8
	bne	.L08006CB8                             @ 08006BDA
	mov	r0, r12                                @ 08006BDC
	adds	r0, #0xf4                             @ 08006BDE
	ldr	r0, [r0]                               @ 08006BE0
	lsls	r0, r0, #2                            @ 08006BE2
	ldr	r1, .Llit08006C2C                      @ 08006BE4  =mcInstTable
	adds	r0, r0, r1                            @ 08006BE6
	ldr	r6, [r0]                               @ 08006BE8
	ldr	r2, [r6, #0x18]                        @ 08006BEA
	cmp	r2, #0                                 @ 08006BEC
	beq	.L08006C5E                             @ 08006BEE
	movs	r5, #0x8a                             @ 08006BF0
	lsls	r5, r5, #1                            @ 08006BF2
	add	r5, r12                                @ 08006BF4
	ldr	r0, [r5]                               @ 08006BF6
	subs	r0, #1                                @ 08006BF8
	str	r0, [r5]                               @ 08006BFA
	cmp	r0, #0                                 @ 08006BFC
	bne	.L08006C5E                             @ 08006BFE
	movs	r4, #0x88                             @ 08006C00
	lsls	r4, r4, #1                            @ 08006C02
	add	r4, r12                                @ 08006C04
	ldr	r3, [r4]                               @ 08006C06
	adds	r0, r3, #2                            @ 08006C08
	str	r0, [r4]                               @ 08006C0A
	lsls	r0, r0, #1                            @ 08006C0C
	adds	r1, r0, r2                            @ 08006C0E
	ldrh	r2, [r1]                              @ 08006C10
	cmp	r2, #0xff                              @ 08006C12
	bne	.L08006C48                             @ 08006C14
	str	r3, [r4]                               @ 08006C16
	b	.L08006C5E                               @ 08006C18
	.hword	0x0000                          @ 08006C1A  (padding)
.Llit08006C1C:
	.word	REG_SOUND2CNT_H                @ 08006C1C  = 0x0400006C
.Llit08006C20:
	.word	mcChan+CH_envIdx               @ 08006C20  = 0x030077A0
.Llit08006C24:
	.word	REG_SOUND2CNT_L                @ 08006C24  = 0x04000068
.Llit08006C28:
	.word	mcChan+CH_freq                 @ 08006C28  = 0x03007788
.Llit08006C2C:
	.word	mcInstTable                    @ 08006C2C  = 0x083D5214
.Llit08006C30:
	.word	mcFreqHi                       @ 08006C30  = 0x083D4861
.Llit08006C34:
	.word	mcFreqLo                       @ 08006C34  = 0x083D4800
.Llit08006C38:
	.word	mcChan+0x90+CH_freq            @ 08006C38  = 0x03007818
.Llit08006C3C:
	.word	REG_SOUND3CNT_X                @ 08006C3C  = 0x04000074
.Llit08006C40:
	.word	mcChan+CH_pitchTimer           @ 08006C40  = 0x030077AC
.Llit08006C44:
	.word	REG_SOUND3CNT_H                @ 08006C44  = 0x04000072
.L08006C48:
	ldr	r0, [r6]                               @ 08006C48
	lsls	r0, r0, #8                            @ 08006C4A
	ldrh	r3, [r1]                              @ 08006C4C
	orrs	r0, r3                                @ 08006C4E
	lsls	r0, r0, #0x10                         @ 08006C50
	lsrs	r4, r0, #0x10                         @ 08006C52
	movs	r7, #2                                @ 08006C54
	ldrsh	r0, [r1, r7]                         @ 08006C56
	str	r0, [r5]                               @ 08006C58
	ldr	r0, .Llit08006C90                      @ 08006C5A  =REG_SOUND4CNT_H
	strh	r4, [r0]                              @ 08006C5C
.L08006C5E:
	ldr	r2, [r6, #0x10]                        @ 08006C5E
	cmp	r2, #0                                 @ 08006C60
	beq	.L08006CB8                             @ 08006C62
	ldr	r0, [sp, #0x28]                        @ 08006C64
	lsls	r1, r0, #3                            @ 08006C66
	mov	r0, r9                                 @ 08006C68
	adds	r0, #0x34                             @ 08006C6A
	adds	r5, r1, r0                            @ 08006C6C
	ldr	r0, [r5]                               @ 08006C6E
	subs	r0, #1                                @ 08006C70
	str	r0, [r5]                               @ 08006C72
	cmp	r0, #0                                 @ 08006C74
	bne	.L08006CB8                             @ 08006C76
	ldr	r4, .Llit08006C94                      @ 08006C78  =mcChan+CH_envIdx
	adds	r3, r1, r4                            @ 08006C7A
	ldr	r4, [r3]                               @ 08006C7C
	adds	r0, r4, #2                            @ 08006C7E
	str	r0, [r3]                               @ 08006C80
	lsls	r0, r0, #1                            @ 08006C82
	adds	r2, r0, r2                            @ 08006C84
	ldrh	r1, [r2]                              @ 08006C86
	cmp	r1, #0xff                              @ 08006C88
	bne	.L08006C98                             @ 08006C8A
	str	r4, [r3]                               @ 08006C8C
	b	.L08006CB8                               @ 08006C8E
.Llit08006C90:
	.word	REG_SOUND4CNT_H                @ 08006C90  = 0x0400007C
.Llit08006C94:
	.word	mcChan+CH_envIdx               @ 08006C94  = 0x030077A0
.L08006C98:
	ldr	r0, [r6, #4]                           @ 08006C98
	lsls	r1, r1, #8                            @ 08006C9A
	orrs	r0, r1                                @ 08006C9C
	lsls	r0, r0, #0x10                         @ 08006C9E
	lsrs	r4, r0, #0x10                         @ 08006CA0
	ldr	r0, .Llit08006CF8                      @ 08006CA2  =REG_SOUND4CNT_L
	strh	r4, [r0]                              @ 08006CA4
	movs	r6, #2                                @ 08006CA6
	ldrsh	r0, [r2, r6]                         @ 08006CA8
	str	r0, [r5]                               @ 08006CAA
	ldr	r1, .Llit08006CFC                      @ 08006CAC  =REG_SOUND4CNT_H
	ldrh	r0, [r1]                              @ 08006CAE
	movs	r7, #0x80                             @ 08006CB0
	lsls	r7, r7, #8                            @ 08006CB2
	orrs	r0, r7                                @ 08006CB4
	strh	r0, [r1]                              @ 08006CB6
.L08006CB8:
	ldr	r1, [sp, #0x30]                        @ 08006CB8
	ldr	r0, [r1]                               @ 08006CBA
	cmp	r0, #0                                 @ 08006CBC
	beq	.L08006CC2                             @ 08006CBE
	b	.L080072B2                               @ 08006CC0
.L08006CC2:
	ldr	r2, [sp, #0x34]                        @ 08006CC2
	ldr	r0, [r2]                               @ 08006CC4
	cmp	r0, #0                                 @ 08006CC6
	beq	.L08006CCC                             @ 08006CC8
	b	.L08006E2C                               @ 08006CCA
.L08006CCC:
	ldr	r6, .Llit08006D00                      @ 08006CCC  =mcChan
	ldr	r0, [sp, #0x5c]                        @ 08006CCE
	add	r0, r10                                @ 08006CD0
	lsls	r4, r0, #3                            @ 08006CD2
	adds	r0, r6, #0                            @ 08006CD4
	adds	r0, #8                                @ 08006CD6
	adds	r3, r4, r0                            @ 08006CD8
	movs	r5, #0                                @ 08006CDA
	mov	r8, r5                                 @ 08006CDC
	adds	r0, #0x30                             @ 08006CDE
	adds	r0, r4, r0                            @ 08006CE0
	str	r0, [sp, #0x38]                        @ 08006CE2
	adds	r0, r6, #0                            @ 08006CE4
	adds	r0, #0x10                             @ 08006CE6
	adds	r0, r4, r0                            @ 08006CE8
	str	r0, [sp, #0x40]                        @ 08006CEA
	adds	r0, r6, #0                            @ 08006CEC
	adds	r0, #0x28                             @ 08006CEE
	adds	r0, r4, r0                            @ 08006CF0
	str	r0, [sp, #0x3c]                        @ 08006CF2
	b	.L08006D0A                               @ 08006CF4
	.hword	0x0000                          @ 08006CF6  (padding)
.Llit08006CF8:
	.word	REG_SOUND4CNT_L                @ 08006CF8  = 0x04000078
.Llit08006CFC:
	.word	REG_SOUND4CNT_H                @ 08006CFC  = 0x0400007C
.Llit08006D00:
	.word	mcChan                         @ 08006D00  = 0x03007770
.L08006D04:
	cmp	r7, #0x61                              @ 08006D04  SEQ_END
	bne	.L08006D0A                             @ 08006D06
	b	.L08006E22                               @ 08006D08
.L08006D0A:
	adds	r0, r6, #0                            @ 08006D0A
	adds	r0, #0x20                             @ 08006D0C
	adds	r0, r4, r0                            @ 08006D0E
	ldr	r5, [r0]                               @ 08006D10
	ldr	r7, [r3]                               @ 08006D12
	str	r7, [sp, #0x68]                        @ 08006D14
	lsls	r0, r7, #2                            @ 08006D16
	adds	r0, r0, r5                            @ 08006D18
	ldr	r7, [r0]                               @ 08006D1A
	cmp	r7, #0x67                              @ 08006D1C  SEQ_PAN
	bne	.L08006D42                             @ 08006D1E
	ldr	r1, [r0, #4]                           @ 08006D20
	lsls	r1, r1, #8                            @ 08006D22
	str	r1, [sp, #0x60]                        @ 08006D24
	ldr	r1, .Llit08006E68                      @ 08006D26  =mcFadeLevel
	ldr	r0, [r1]                               @ 08006D28
	ldr	r2, [sp, #0x60]                        @ 08006D2A
	adds	r2, r2, r0                            @ 08006D2C
	str	r2, [sp, #0x60]                        @ 08006D2E
	lsls	r0, r0, #4                            @ 08006D30
	adds	r1, r2, r0                            @ 08006D32
	ldr	r0, .Llit08006E6C                      @ 08006D34  =mcMasterPan
	str	r1, [r0]                               @ 08006D36
	ldr	r0, .Llit08006E70                      @ 08006D38  =REG_SOUNDCNT_L
	strh	r1, [r0]                              @ 08006D3A
	ldr	r0, [sp, #0x68]                        @ 08006D3C
	adds	r0, #2                                @ 08006D3E
	str	r0, [r3]                               @ 08006D40
.L08006D42:
	cmp	r7, #0x69                              @ 08006D42  SEQ_TEMPO
	bne	.L08006D56                             @ 08006D44
	ldr	r0, [r3]                               @ 08006D46
	lsls	r1, r0, #2                            @ 08006D48
	adds	r1, r1, r5                            @ 08006D4A
	ldr	r1, [r1, #4]                           @ 08006D4C
	ldr	r2, .Llit08006E74                      @ 08006D4E  =mcTempo
	str	r1, [r2]                               @ 08006D50
	adds	r0, #2                                @ 08006D52
	str	r0, [r3]                               @ 08006D54
.L08006D56:
	cmp	r7, #0x60                              @ 08006D56  rest / cmd 0x60
	bne	.L08006D60                             @ 08006D58
	ldr	r0, [r3]                               @ 08006D5A
	adds	r0, #3                                @ 08006D5C
	str	r0, [r3]                               @ 08006D5E
.L08006D60:
	cmp	r7, #0x66                              @ 08006D60  SEQ_CONDFLAG
	bne	.L08006D74                             @ 08006D62
	ldr	r0, [r3]                               @ 08006D64
	lsls	r1, r0, #2                            @ 08006D66
	adds	r1, r1, r5                            @ 08006D68
	ldr	r1, [r1, #4]                           @ 08006D6A
	ldr	r2, .Llit08006E78                      @ 08006D6C  =mcCondFlag
	str	r1, [r2]                               @ 08006D6E
	adds	r0, #2                                @ 08006D70
	str	r0, [r3]                               @ 08006D72
.L08006D74:
	cmp	r7, #0x61                              @ 08006D74  SEQ_END
	bne	.L08006DD2                             @ 08006D76
	adds	r0, r6, #4                            @ 08006D78
	adds	r0, r4, r0                            @ 08006D7A
	ldr	r0, [r0]                               @ 08006D7C
	cmp	r0, #0                                 @ 08006D7E
	beq	.L08006DD2                             @ 08006D80
	mov	r0, r10                                @ 08006D82
	cmp	r0, #0                                 @ 08006D84
	bne	.L08006D92                             @ 08006D86
	ldr	r0, .Llit08006E7C                      @ 08006D88  =REG_SOUND1CNT_H
	mov	r1, r10                                @ 08006D8A
	strh	r1, [r0]                              @ 08006D8C
	ldr	r2, .Llit08006E80                      @ 08006D8E  =REG_SOUND1CNT_X
	strh	r1, [r2]                              @ 08006D90
.L08006D92:
	mov	r0, r10                                @ 08006D92
	cmp	r0, #1                                 @ 08006D94
	bne	.L08006DA2                             @ 08006D96
	ldr	r0, .Llit08006E84                      @ 08006D98  =REG_SOUND2CNT_L
	mov	r1, r8                                 @ 08006D9A
	strh	r1, [r0]                              @ 08006D9C
	ldr	r2, .Llit08006E88                      @ 08006D9E  =REG_SOUND2CNT_H
	strh	r1, [r2]                              @ 08006DA0
.L08006DA2:
	mov	r0, r10                                @ 08006DA2
	cmp	r0, #2                                 @ 08006DA4
	bne	.L08006DB2                             @ 08006DA6
	ldr	r0, .Llit08006E8C                      @ 08006DA8  =REG_SOUND3CNT_H
	mov	r1, r8                                 @ 08006DAA
	strh	r1, [r0]                              @ 08006DAC
	ldr	r2, .Llit08006E90                      @ 08006DAE  =REG_SOUND3CNT_X
	strh	r1, [r2]                              @ 08006DB0
.L08006DB2:
	mov	r0, r10                                @ 08006DB2
	cmp	r0, #3                                 @ 08006DB4
	bne	.L08006DC2                             @ 08006DB6
	ldr	r0, .Llit08006E94                      @ 08006DB8  =REG_SOUND4CNT_L
	mov	r1, r8                                 @ 08006DBA
	strh	r1, [r0]                              @ 08006DBC
	adds	r0, #4                                @ 08006DBE
	strh	r1, [r0]                              @ 08006DC0
.L08006DC2:
	mov	r2, r10                                @ 08006DC2
	subs	r2, #4                                @ 08006DC4
	cmp	r2, #1                                 @ 08006DC6
	bhi	.L08006DD2                             @ 08006DC8
	movs	r0, #1                                @ 08006DCA
	rsbs	r0, r0, #0                            @ 08006DCC
	ldr	r1, [sp, #0x38]                        @ 08006DCE
	str	r0, [r1]                               @ 08006DD0
.L08006DD2:
	cmp	r7, #0x64                              @ 08006DD2  SEQ_PAT
	bne	.L08006E0E                             @ 08006DD4
	ldr	r0, [r3]                               @ 08006DD6
	lsls	r0, r0, #2                            @ 08006DD8
	adds	r0, r0, r5                            @ 08006DDA
	ldr	r0, [r0, #8]                           @ 08006DDC
	ldr	r2, [sp, #0x3c]                        @ 08006DDE
	str	r0, [r2]                               @ 08006DE0
	ldr	r0, .Llit08006E98                      @ 08006DE2  =mcChan+CH_patPtr
	adds	r1, r4, r0                            @ 08006DE4
	ldr	r2, [r3]                               @ 08006DE6
	lsls	r2, r2, #2                            @ 08006DE8
	adds	r2, r2, r5                            @ 08006DEA
	ldr	r0, [r2, #4]                           @ 08006DEC
	str	r0, [r1]                               @ 08006DEE
	adds	r1, r6, #0                            @ 08006DF0
	adds	r1, #0x2c                             @ 08006DF2
	adds	r1, r4, r1                            @ 08006DF4
	ldr	r0, [r2, #0xc]                         @ 08006DF6
	str	r0, [r1]                               @ 08006DF8
	adds	r0, r6, #0                            @ 08006DFA
	adds	r0, #0xc                              @ 08006DFC
	adds	r0, r4, r0                            @ 08006DFE
	movs	r1, #0                                @ 08006E00
	str	r1, [r0]                               @ 08006E02
	ldr	r2, [sp, #0x40]                        @ 08006E04
	str	r1, [r2]                               @ 08006E06
	ldr	r0, [r3]                               @ 08006E08
	adds	r0, #4                                @ 08006E0A
	str	r0, [r3]                               @ 08006E0C
.L08006E0E:
	cmp	r7, #0x62                              @ 08006E0E  SEQ_JUMP
	bne	.L08006E1C                             @ 08006E10
	ldr	r0, [r3]                               @ 08006E12
	lsls	r0, r0, #2                            @ 08006E14
	adds	r0, r0, r5                            @ 08006E16
	ldr	r0, [r0, #4]                           @ 08006E18
	str	r0, [r3]                               @ 08006E1A
.L08006E1C:
	cmp	r7, #0x64                              @ 08006E1C  SEQ_PAT
	beq	.L08006E22                             @ 08006E1E
	b	.L08006D04                               @ 08006E20
.L08006E22:
	ldr	r3, [sp, #0x34]                        @ 08006E22
	ldr	r0, [r3]                               @ 08006E24
	cmp	r0, #0                                 @ 08006E26
	bne	.L08006E2C                             @ 08006E28
	b	.L080072B2                               @ 08006E2A
.L08006E2C:
	ldr	r4, [sp, #0x28]                        @ 08006E2C
	lsls	r1, r4, #3                            @ 08006E2E
	ldr	r5, .Llit08006E98                      @ 08006E30  =mcChan+CH_patPtr
	adds	r3, r1, r5                            @ 08006E32
	ldr	r5, [r3]                               @ 08006E34
	mov	r0, r9                                 @ 08006E36
	adds	r0, #0xc                              @ 08006E38
	adds	r2, r1, r0                            @ 08006E3A
	ldr	r0, [r2]                               @ 08006E3C
	adds	r0, r5, r0                            @ 08006E3E
	ldrb	r0, [r0]                              @ 08006E40
	str	r0, [sp, #0x24]                        @ 08006E42
	cmp	r0, #0x65                              @ 08006E44  pattern end
	bne	.L08006EAA                             @ 08006E46
	mov	r0, r12                                @ 08006E48
	adds	r0, #0x2c                             @ 08006E4A
	adds	r1, r1, r0                            @ 08006E4C
	ldr	r0, [r1]                               @ 08006E4E
	cmp	r0, #0                                 @ 08006E50
	beq	.L08006E9C                             @ 08006E52
	subs	r0, #1                                @ 08006E54
	str	r0, [r1]                               @ 08006E56
	cmp	r0, #0                                 @ 08006E58
	beq	.L08006E9C                             @ 08006E5A
	movs	r6, #0                                @ 08006E5C
	str	r6, [r2]                               @ 08006E5E
	ldrb	r7, [r5]                              @ 08006E60
	str	r7, [sp, #0x24]                        @ 08006E62
	b	.L08006EA0                               @ 08006E64
	.hword	0x0000                          @ 08006E66  (padding)
.Llit08006E68:
	.word	mcFadeLevel                    @ 08006E68  = 0x030079B0
.Llit08006E6C:
	.word	mcMasterPan                    @ 08006E6C  = 0x03007578
.Llit08006E70:
	.word	REG_SOUNDCNT_L                 @ 08006E70  = 0x04000080
.Llit08006E74:
	.word	mcTempo                        @ 08006E74  = 0x03007404
.Llit08006E78:
	.word	mcCondFlag                     @ 08006E78  = 0x030079C0
.Llit08006E7C:
	.word	REG_SOUND1CNT_H                @ 08006E7C  = 0x04000062
.Llit08006E80:
	.word	REG_SOUND1CNT_X                @ 08006E80  = 0x04000064
.Llit08006E84:
	.word	REG_SOUND2CNT_L                @ 08006E84  = 0x04000068
.Llit08006E88:
	.word	REG_SOUND2CNT_H                @ 08006E88  = 0x0400006C
.Llit08006E8C:
	.word	REG_SOUND3CNT_H                @ 08006E8C  = 0x04000072
.Llit08006E90:
	.word	REG_SOUND3CNT_X                @ 08006E90  = 0x04000074
.Llit08006E94:
	.word	REG_SOUND4CNT_L                @ 08006E94  = 0x04000078
.Llit08006E98:
	.word	mcChan+CH_patPtr               @ 08006E98  = 0x03007794
.L08006E9C:
	str	r0, [r3]                               @ 08006E9C
	str	r0, [r2]                               @ 08006E9E
.L08006EA0:
	ldr	r0, [sp, #0x24]                        @ 08006EA0
	cmp	r0, #0x65                              @ 08006EA2  pattern end
	bne	.L08006EAA                             @ 08006EA4
	bl	.L080066A0                              @ 08006EA6  long branch
.L08006EAA:
	ldr	r2, [sp, #0x28]                        @ 08006EAA
	lsls	r1, r2, #3                            @ 08006EAC
	mov	r0, r9                                 @ 08006EAE
	adds	r0, #0xc                              @ 08006EB0
	adds	r0, r1, r0                            @ 08006EB2
	ldr	r0, [r0]                               @ 08006EB4
	adds	r0, r5, r0                            @ 08006EB6
	ldrb	r7, [r0]                              @ 08006EB8
	cmp	r7, #0x60                              @ 08006EBA  rest / cmd 0x60
	beq	.L08006ED4                             @ 08006EBC
	mov	r0, r12                                @ 08006EBE
	adds	r0, #0x28                             @ 08006EC0
	adds	r0, r1, r0                            @ 08006EC2
	ldr	r0, [r0]                               @ 08006EC4
	adds	r0, r7, r0                            @ 08006EC6
	lsls	r0, r0, #0x18                         @ 08006EC8
	lsrs	r7, r0, #0x18                         @ 08006ECA
	mov	r3, r10                                @ 08006ECC
	subs	r3, #4                                @ 08006ECE
	str	r3, [sp, #0x54]                        @ 08006ED0
	b	.L08006EE2                               @ 08006ED2
.L08006ED4:
	movs	r7, #0x30                             @ 08006ED4  rest: note = 0x30 ...
	mov	r4, r10                                @ 08006ED6
	subs	r4, #4                                @ 08006ED8
	str	r4, [sp, #0x54]                        @ 08006EDA
	cmp	r4, #1                                 @ 08006EDC  ... but kept at 0x60 only if (ch - 4) <= 1: BUG, rests on ch 7/8 key note 0x30
	bhi	.L08006EE2                             @ 08006EDE
	movs	r7, #0x60                             @ 08006EE0
.L08006EE2:
	ldr	r0, .Llit08006FD4                      @ 08006EE2  =mcDurTable
	ldr	r4, [r0]                               @ 08006EE4
	ldr	r6, [sp, #0x44]                        @ 08006EE6
	str	r7, [r6]                               @ 08006EE8
	ldr	r0, .Llit08006FD8                      @ 08006EEA  =mcFreqHi
	mov	r8, r0                                 @ 08006EEC
	adds	r0, r7, r0                            @ 08006EEE
	ldrb	r0, [r0]                              @ 08006EF0
	lsls	r1, r0, #8                            @ 08006EF2
	ldr	r3, .Llit08006FDC                      @ 08006EF4  =mcFreqLo
	adds	r0, r7, r3                            @ 08006EF6
	ldrb	r0, [r0]                              @ 08006EF8
	orrs	r1, r0                                @ 08006EFA
	ldr	r2, [sp, #0x48]                        @ 08006EFC
	str	r1, [r2]                               @ 08006EFE
	mov	r2, r12                                @ 08006F00
	adds	r2, #0x1c                             @ 08006F02
	ldr	r6, [sp, #0x2c]                        @ 08006F04
	adds	r2, r6, r2                            @ 08006F06
	mov	r1, r12                                @ 08006F08
	adds	r1, #0xc                              @ 08006F0A
	adds	r1, r6, r1                            @ 08006F0C
	ldr	r0, [r1]                               @ 08006F0E
	adds	r0, r5, r0                            @ 08006F10
	ldrb	r0, [r0, #1]                          @ 08006F12
	str	r0, [r2]                               @ 08006F14
	ldr	r0, [r1]                               @ 08006F16
	adds	r0, r5, r0                            @ 08006F18
	ldrb	r0, [r0, #2]                          @ 08006F1A
	lsls	r0, r0, #2                            @ 08006F1C
	adds	r0, r0, r4                            @ 08006F1E
	ldr	r0, [r0]                               @ 08006F20
	ldr	r2, [sp, #0x30]                        @ 08006F22
	str	r0, [r2]                               @ 08006F24
	ldr	r0, [r1]                               @ 08006F26
	adds	r0, #3                                @ 08006F28
	str	r0, [r1]                               @ 08006F2A
	mov	r4, r10                                @ 08006F2C
	cmp	r4, #0                                 @ 08006F2E
	bne	.L08007008                             @ 08006F30
	mov	r5, r12                                @ 08006F32
	ldr	r0, [r5, #0x1c]                        @ 08006F34
	lsls	r0, r0, #2                            @ 08006F36
	ldr	r6, .Llit08006FE0                      @ 08006F38  =mcInstTable
	adds	r0, r0, r6                            @ 08006F3A
	ldr	r6, [r0]                               @ 08006F3C
	ldr	r1, [r6, #4]                           @ 08006F3E
	ldr	r0, [r6, #8]                           @ 08006F40
	lsls	r0, r0, #8                            @ 08006F42
	adds	r1, r1, r0                            @ 08006F44
	lsls	r1, r1, #0x10                         @ 08006F46
	lsrs	r4, r1, #0x10                         @ 08006F48
	ldr	r2, [r6, #0x10]                        @ 08006F4A
	cmp	r2, #0                                 @ 08006F4C
	beq	.L08006F68                             @ 08006F4E
	movs	r0, #0xff                             @ 08006F50
	ands	r4, r0                                @ 08006F52
	ldrh	r1, [r2]                              @ 08006F54
	lsls	r0, r1, #8                            @ 08006F56
	orrs	r4, r0                                @ 08006F58
	lsls	r0, r4, #0x10                         @ 08006F5A
	lsrs	r4, r0, #0x10                         @ 08006F5C
	mov	r0, r10                                @ 08006F5E
	str	r0, [r5, #0x30]                        @ 08006F60
	movs	r1, #2                                @ 08006F62
	ldrsh	r0, [r2, r1]                         @ 08006F64
	str	r0, [r5, #0x34]                        @ 08006F66
.L08006F68:
	mov	r2, r12                                @ 08006F68
	ldr	r5, [r2, #4]                           @ 08006F6A
	cmp	r5, #0                                 @ 08006F6C
	beq	.L08006F74                             @ 08006F6E
	ldr	r0, .Llit08006FE4                      @ 08006F70  =REG_SOUND1CNT_H
	strh	r4, [r0]                              @ 08006F72
.L08006F74:
	ldr	r2, [r6, #0x20]                        @ 08006F74
	cmp	r2, #0                                 @ 08006F76
	beq	.L08006F9E                             @ 08006F78
	movs	r4, #2                                @ 08006F7A
	ldrsh	r0, [r2, r4]                         @ 08006F7C
	adds	r0, r7, r0                            @ 08006F7E
	mov	r4, r8                                 @ 08006F80
	adds	r1, r0, r4                            @ 08006F82
	ldrb	r1, [r1]                              @ 08006F84
	lsls	r1, r1, #8                            @ 08006F86
	adds	r0, r0, r3                            @ 08006F88
	ldrb	r0, [r0]                              @ 08006F8A
	orrs	r1, r0                                @ 08006F8C
	mov	r0, r12                                @ 08006F8E
	str	r1, [r0, #0x18]                        @ 08006F90
	mov	r1, r10                                @ 08006F92
	str	r1, [r0, #0x40]                        @ 08006F94
	movs	r4, #0                                @ 08006F96
	ldrsh	r0, [r2, r4]                         @ 08006F98
	mov	r1, r12                                @ 08006F9A
	str	r0, [r1, #0x44]                        @ 08006F9C
.L08006F9E:
	ldr	r0, [r6]                               @ 08006F9E
	lsls	r0, r0, #0x18                         @ 08006FA0
	lsrs	r4, r0, #0x10                         @ 08006FA2
	ldr	r2, [r6, #0x18]                        @ 08006FA4
	cmp	r2, #0                                 @ 08006FA6
	beq	.L08006FF0                             @ 08006FA8
	ldrh	r6, [r2]                              @ 08006FAA
	ldr	r1, .Llit08006FE8                      @ 08006FAC  =0xFFFF8000
	adds	r0, r6, r1                            @ 08006FAE
	orrs	r4, r0                                @ 08006FB0
	mov	r6, r10                                @ 08006FB2
	mov	r0, r12                                @ 08006FB4
	str	r6, [r0, #0x38]                        @ 08006FB6
	movs	r1, #2                                @ 08006FB8
	ldrsh	r0, [r2, r1]                         @ 08006FBA
	mov	r2, r12                                @ 08006FBC
	str	r0, [r2, #0x3c]                        @ 08006FBE
	ldr	r0, [r2, #0x18]                        @ 08006FC0
	orrs	r0, r4                                @ 08006FC2
	lsls	r0, r0, #0x10                         @ 08006FC4
	lsrs	r4, r0, #0x10                         @ 08006FC6
	cmp	r5, #0                                 @ 08006FC8
	beq	.L08007008                             @ 08006FCA
	ldr	r5, .Llit08006FEC                      @ 08006FCC  =REG_SOUND1CNT_X
	strh	r4, [r5]                              @ 08006FCE
	b	.L08007008                               @ 08006FD0
	.hword	0x0000                          @ 08006FD2  (padding)
.Llit08006FD4:
	.word	mcDurTable                     @ 08006FD4  = 0x03007580
.Llit08006FD8:
	.word	mcFreqHi                       @ 08006FD8  = 0x083D4861
.Llit08006FDC:
	.word	mcFreqLo                       @ 08006FDC  = 0x083D4800
.Llit08006FE0:
	.word	mcInstTable                    @ 08006FE0  = 0x083D5214
.Llit08006FE4:
	.word	REG_SOUND1CNT_H                @ 08006FE4  = 0x04000062
.Llit08006FE8:
	.word	0xFFFF8000                     @ 08006FE8
.Llit08006FEC:
	.word	REG_SOUND1CNT_X                @ 08006FEC  = 0x04000064
.L08006FF0:
	movs	r6, #0x80                             @ 08006FF0
	lsls	r6, r6, #8                            @ 08006FF2
	orrs	r4, r6                                @ 08006FF4
	mov	r1, r12                                @ 08006FF6
	ldr	r0, [r1, #0x18]                        @ 08006FF8
	orrs	r0, r4                                @ 08006FFA
	lsls	r0, r0, #0x10                         @ 08006FFC
	lsrs	r4, r0, #0x10                         @ 08006FFE
	cmp	r5, #0                                 @ 08007000
	beq	.L08007008                             @ 08007002
	ldr	r2, .Llit080070B0                      @ 08007004  =REG_SOUND1CNT_X
	strh	r4, [r2]                              @ 08007006
.L08007008:
	mov	r4, r10                                @ 08007008
	cmp	r4, #1                                 @ 0800700A
	bne	.L080070D8                             @ 0800700C
	mov	r5, r12                                @ 0800700E
	ldr	r0, [r5, #0x64]                        @ 08007010
	lsls	r0, r0, #2                            @ 08007012
	ldr	r6, .Llit080070B4                      @ 08007014  =mcInstTable
	adds	r0, r0, r6                            @ 08007016
	ldr	r6, [r0]                               @ 08007018
	ldr	r1, [r6, #4]                           @ 0800701A
	ldr	r0, [r6, #8]                           @ 0800701C
	lsls	r0, r0, #8                            @ 0800701E
	adds	r1, r1, r0                            @ 08007020
	lsls	r1, r1, #0x10                         @ 08007022
	lsrs	r4, r1, #0x10                         @ 08007024
	ldr	r2, [r6, #0x10]                        @ 08007026
	cmp	r2, #0                                 @ 08007028
	beq	.L08007044                             @ 0800702A
	movs	r0, #0xff                             @ 0800702C
	ands	r4, r0                                @ 0800702E
	ldrh	r1, [r2]                              @ 08007030
	lsls	r0, r1, #8                            @ 08007032
	orrs	r4, r0                                @ 08007034
	lsls	r0, r4, #0x10                         @ 08007036
	lsrs	r4, r0, #0x10                         @ 08007038
	movs	r0, #0                                @ 0800703A
	str	r0, [r5, #0x78]                        @ 0800703C
	movs	r1, #2                                @ 0800703E
	ldrsh	r0, [r2, r1]                         @ 08007040
	str	r0, [r5, #0x7c]                        @ 08007042
.L08007044:
	mov	r2, r12                                @ 08007044
	ldr	r5, [r2, #0x4c]                        @ 08007046
	cmp	r5, #0                                 @ 08007048
	beq	.L08007050                             @ 0800704A
	ldr	r0, .Llit080070B8                      @ 0800704C  =REG_SOUND2CNT_L
	strh	r4, [r0]                              @ 0800704E
.L08007050:
	ldr	r2, [r6, #0x20]                        @ 08007050
	cmp	r2, #0                                 @ 08007052
	beq	.L0800707E                             @ 08007054
	movs	r4, #2                                @ 08007056
	ldrsh	r0, [r2, r4]                         @ 08007058
	adds	r0, r7, r0                            @ 0800705A
	ldr	r4, .Llit080070BC                      @ 0800705C  =mcFreqHi
	adds	r1, r0, r4                            @ 0800705E
	ldrb	r1, [r1]                              @ 08007060
	lsls	r1, r1, #8                            @ 08007062
	adds	r0, r0, r3                            @ 08007064
	ldrb	r0, [r0]                              @ 08007066
	orrs	r1, r0                                @ 08007068
	mov	r0, r12                                @ 0800706A
	str	r1, [r0, #0x60]                        @ 0800706C
	adds	r0, #0x88                             @ 0800706E
	movs	r1, #0                                @ 08007070
	str	r1, [r0]                               @ 08007072
	mov	r1, r12                                @ 08007074
	adds	r1, #0x8c                             @ 08007076
	movs	r4, #0                                @ 08007078
	ldrsh	r0, [r2, r4]                         @ 0800707A
	str	r0, [r1]                               @ 0800707C
.L0800707E:
	ldr	r0, [r6]                               @ 0800707E
	lsls	r0, r0, #0x18                         @ 08007080
	lsrs	r4, r0, #0x10                         @ 08007082
	ldr	r2, [r6, #0x18]                        @ 08007084
	cmp	r2, #0                                 @ 08007086
	beq	.L080070C0                             @ 08007088
	movs	r0, #0x80                             @ 0800708A
	lsls	r0, r0, #8                            @ 0800708C
	ldrh	r6, [r2]                              @ 0800708E
	orrs	r0, r6                                @ 08007090
	orrs	r4, r0                                @ 08007092
	mov	r0, r12                                @ 08007094
	adds	r0, #0x80                             @ 08007096
	movs	r1, #0                                @ 08007098
	str	r1, [r0]                               @ 0800709A
	mov	r1, r12                                @ 0800709C
	adds	r1, #0x84                             @ 0800709E
	movs	r6, #2                                @ 080070A0
	ldrsh	r0, [r2, r6]                         @ 080070A2
	str	r0, [r1]                               @ 080070A4
	mov	r1, r12                                @ 080070A6
	ldr	r0, [r1, #0x60]                        @ 080070A8
	orrs	r4, r0                                @ 080070AA
	lsls	r0, r4, #0x10                         @ 080070AC
	b	.L080070CE                               @ 080070AE
.Llit080070B0:
	.word	REG_SOUND1CNT_X                @ 080070B0  = 0x04000064
.Llit080070B4:
	.word	mcInstTable                    @ 080070B4  = 0x083D5214
.Llit080070B8:
	.word	REG_SOUND2CNT_L                @ 080070B8  = 0x04000068
.Llit080070BC:
	.word	mcFreqHi                       @ 080070BC  = 0x083D4861
.L080070C0:
	movs	r6, #0x80                             @ 080070C0
	lsls	r6, r6, #8                            @ 080070C2
	orrs	r4, r6                                @ 080070C4
	mov	r1, r12                                @ 080070C6
	ldr	r0, [r1, #0x60]                        @ 080070C8
	orrs	r0, r4                                @ 080070CA
	lsls	r0, r0, #0x10                         @ 080070CC
.L080070CE:
	lsrs	r4, r0, #0x10                         @ 080070CE
	cmp	r5, #0                                 @ 080070D0
	beq	.L080070D8                             @ 080070D2
	ldr	r2, .Llit0800719C                      @ 080070D4  =REG_SOUND2CNT_H
	strh	r4, [r2]                              @ 080070D6
.L080070D8:
	mov	r4, r10                                @ 080070D8
	cmp	r4, #2                                 @ 080070DA
	bne	.L080071CE                             @ 080070DC
	mov	r0, r12                                @ 080070DE
	adds	r0, #0xac                             @ 080070E0
	ldr	r0, [r0]                               @ 080070E2
	lsls	r0, r0, #2                            @ 080070E4
	ldr	r5, .Llit080071A0                      @ 080070E6  =mcInstTable
	adds	r0, r0, r5                            @ 080070E8
	ldr	r6, [r0]                               @ 080070EA
	ldr	r1, [r6, #4]                           @ 080070EC
	ldr	r0, [r6, #8]                           @ 080070EE
	lsls	r0, r0, #8                            @ 080070F0
	adds	r1, r1, r0                            @ 080070F2
	lsls	r1, r1, #0x10                         @ 080070F4
	lsrs	r4, r1, #0x10                         @ 080070F6
	ldr	r2, [r6, #0x10]                        @ 080070F8
	cmp	r2, #0                                 @ 080070FA
	beq	.L0800711E                             @ 080070FC
	movs	r0, #0xff                             @ 080070FE
	ands	r4, r0                                @ 08007100
	ldrh	r1, [r2]                              @ 08007102
	lsls	r0, r1, #8                            @ 08007104
	orrs	r4, r0                                @ 08007106
	lsls	r0, r4, #0x10                         @ 08007108
	lsrs	r4, r0, #0x10                         @ 0800710A
	mov	r0, r12                                @ 0800710C
	adds	r0, #0xc0                             @ 0800710E
	movs	r5, #0                                @ 08007110
	str	r5, [r0]                               @ 08007112
	mov	r1, r12                                @ 08007114
	adds	r1, #0xc4                             @ 08007116
	movs	r5, #2                                @ 08007118
	ldrsh	r0, [r2, r5]                         @ 0800711A
	str	r0, [r1]                               @ 0800711C
.L0800711E:
	mov	r5, r12                                @ 0800711E
	adds	r5, #0x94                             @ 08007120
	ldr	r0, [r5]                               @ 08007122
	cmp	r0, #0                                 @ 08007124
	beq	.L0800712C                             @ 08007126
	ldr	r0, .Llit080071A4                      @ 08007128  =REG_SOUND3CNT_H
	strh	r4, [r0]                              @ 0800712A
.L0800712C:
	ldr	r2, [r6, #0x20]                        @ 0800712C
	cmp	r2, #0                                 @ 0800712E
	beq	.L0800715C                             @ 08007130
	movs	r1, #2                                @ 08007132
	ldrsh	r0, [r2, r1]                         @ 08007134
	adds	r0, r7, r0                            @ 08007136
	ldr	r4, .Llit080071A8                      @ 08007138  =mcFreqHi
	adds	r1, r0, r4                            @ 0800713A
	ldrb	r1, [r1]                              @ 0800713C
	lsls	r1, r1, #8                            @ 0800713E
	adds	r0, r0, r3                            @ 08007140
	ldrb	r0, [r0]                              @ 08007142
	orrs	r1, r0                                @ 08007144
	ldr	r7, .Llit080071AC                      @ 08007146  =mcChan+0x90+CH_freq
	str	r1, [r7]                               @ 08007148
	mov	r0, r12                                @ 0800714A
	adds	r0, #0xd0                             @ 0800714C
	movs	r1, #0                                @ 0800714E
	str	r1, [r0]                               @ 08007150
	mov	r1, r12                                @ 08007152
	adds	r1, #0xd4                             @ 08007154
	movs	r3, #0                                @ 08007156
	ldrsh	r0, [r2, r3]                         @ 08007158
	str	r0, [r1]                               @ 0800715A
.L0800715C:
	ldr	r0, [r6]                               @ 0800715C
	lsls	r0, r0, #0x18                         @ 0800715E
	lsrs	r4, r0, #0x10                         @ 08007160
	ldr	r2, [r6, #0x18]                        @ 08007162
	cmp	r2, #0                                 @ 08007164
	beq	.L080071B4                             @ 08007166
	movs	r0, #0x80                             @ 08007168
	lsls	r0, r0, #8                            @ 0800716A
	ldrh	r6, [r2]                              @ 0800716C
	orrs	r0, r6                                @ 0800716E
	orrs	r4, r0                                @ 08007170
	mov	r0, r12                                @ 08007172
	adds	r0, #0xc8                             @ 08007174
	movs	r7, #0                                @ 08007176
	str	r7, [r0]                               @ 08007178
	mov	r1, r12                                @ 0800717A
	adds	r1, #0xcc                             @ 0800717C
	movs	r3, #2                                @ 0800717E
	ldrsh	r0, [r2, r3]                         @ 08007180
	str	r0, [r1]                               @ 08007182
	ldr	r6, .Llit080071AC                      @ 08007184  =mcChan+0x90+CH_freq
	ldr	r0, [r6]                               @ 08007186
	orrs	r4, r0                                @ 08007188
	lsls	r0, r4, #0x10                         @ 0800718A
	lsrs	r4, r0, #0x10                         @ 0800718C
	ldr	r0, [r5]                               @ 0800718E
	cmp	r0, #0                                 @ 08007190
	beq	.L080071CE                             @ 08007192
	ldr	r7, .Llit080071B0                      @ 08007194  =REG_SOUND3CNT_X
	strh	r4, [r7]                              @ 08007196
	b	.L080071CE                               @ 08007198
	.hword	0x0000                          @ 0800719A  (padding)
.Llit0800719C:
	.word	REG_SOUND2CNT_H                @ 0800719C  = 0x0400006C
.Llit080071A0:
	.word	mcInstTable                    @ 080071A0  = 0x083D5214
.Llit080071A4:
	.word	REG_SOUND3CNT_H                @ 080071A4  = 0x04000072
.Llit080071A8:
	.word	mcFreqHi                       @ 080071A8  = 0x083D4861
.Llit080071AC:
	.word	mcChan+0x90+CH_freq            @ 080071AC  = 0x03007818
.Llit080071B0:
	.word	REG_SOUND3CNT_X                @ 080071B0  = 0x04000074
.L080071B4:
	movs	r0, #0x80                             @ 080071B4
	lsls	r0, r0, #8                            @ 080071B6
	orrs	r4, r0                                @ 080071B8
	ldr	r1, .Llit080072D8                      @ 080071BA  =mcChan+0x90+CH_freq
	ldr	r0, [r1]                               @ 080071BC
	orrs	r0, r4                                @ 080071BE
	lsls	r0, r0, #0x10                         @ 080071C0
	lsrs	r4, r0, #0x10                         @ 080071C2
	ldr	r0, [r5]                               @ 080071C4
	cmp	r0, #0                                 @ 080071C6
	beq	.L080071CE                             @ 080071C8
	ldr	r2, .Llit080072DC                      @ 080071CA  =REG_SOUND3CNT_X
	strh	r4, [r2]                              @ 080071CC
.L080071CE:
	mov	r3, r10                                @ 080071CE
	cmp	r3, #3                                 @ 080071D0
	bne	.L0800725E                             @ 080071D2
	mov	r3, r12                                @ 080071D4
	adds	r0, r3, #0                            @ 080071D6
	adds	r0, #0xf4                             @ 080071D8
	ldr	r0, [r0]                               @ 080071DA
	lsls	r0, r0, #2                            @ 080071DC
	ldr	r4, .Llit080072E0                      @ 080071DE  =mcInstTable
	adds	r0, r0, r4                            @ 080071E0
	ldr	r6, [r0]                               @ 080071E2
	ldr	r1, [r6, #4]                           @ 080071E4
	ldr	r0, [r6, #8]                           @ 080071E6
	lsls	r0, r0, #8                            @ 080071E8
	adds	r1, r1, r0                            @ 080071EA
	lsls	r1, r1, #0x10                         @ 080071EC
	lsrs	r4, r1, #0x10                         @ 080071EE
	ldr	r2, [r6, #0x10]                        @ 080071F0
	cmp	r2, #0                                 @ 080071F2
	beq	.L0800721A                             @ 080071F4
	movs	r0, #0xff                             @ 080071F6
	ands	r4, r0                                @ 080071F8
	ldrh	r5, [r2]                              @ 080071FA
	lsls	r0, r5, #8                            @ 080071FC
	orrs	r4, r0                                @ 080071FE
	lsls	r0, r4, #0x10                         @ 08007200
	lsrs	r4, r0, #0x10                         @ 08007202
	movs	r7, #0x84                             @ 08007204
	lsls	r7, r7, #1                            @ 08007206
	adds	r0, r3, r7                            @ 08007208
	movs	r1, #0                                @ 0800720A
	str	r1, [r0]                               @ 0800720C
	movs	r5, #0x86                             @ 0800720E
	lsls	r5, r5, #1                            @ 08007210
	adds	r1, r3, r5                            @ 08007212
	movs	r7, #2                                @ 08007214
	ldrsh	r0, [r2, r7]                         @ 08007216
	str	r0, [r1]                               @ 08007218
.L0800721A:
	adds	r3, #0xdc                             @ 0800721A
	ldr	r0, [r3]                               @ 0800721C
	cmp	r0, #0                                 @ 0800721E
	beq	.L08007226                             @ 08007220
	ldr	r0, .Llit080072E4                      @ 08007222  =REG_SOUND4CNT_L
	strh	r4, [r0]                              @ 08007224
.L08007226:
	ldr	r0, [r6]                               @ 08007226
	lsls	r0, r0, #0x18                         @ 08007228
	lsrs	r4, r0, #0x10                         @ 0800722A
	ldr	r2, [r6, #0x18]                        @ 0800722C
	cmp	r2, #0                                 @ 0800722E
	beq	.L0800725E                             @ 08007230
	ldrh	r1, [r2]                              @ 08007232
	ldr	r5, .Llit080072E8                      @ 08007234  =0xFFFF8000
	adds	r0, r1, r5                            @ 08007236
	orrs	r4, r0                                @ 08007238
	lsls	r0, r4, #0x10                         @ 0800723A
	lsrs	r4, r0, #0x10                         @ 0800723C
	movs	r0, #0x88                             @ 0800723E
	lsls	r0, r0, #1                            @ 08007240
	add	r0, r12                                @ 08007242
	movs	r6, #0                                @ 08007244
	str	r6, [r0]                               @ 08007246
	movs	r1, #0x8a                             @ 08007248
	lsls	r1, r1, #1                            @ 0800724A
	add	r1, r12                                @ 0800724C
	movs	r7, #2                                @ 0800724E
	ldrsh	r0, [r2, r7]                         @ 08007250
	str	r0, [r1]                               @ 08007252
	ldr	r0, [r3]                               @ 08007254
	cmp	r0, #0                                 @ 08007256
	beq	.L0800725E                             @ 08007258
	ldr	r0, .Llit080072EC                      @ 0800725A  =REG_SOUND4CNT_H
	strh	r4, [r0]                              @ 0800725C
.L0800725E:
	ldr	r0, [sp, #0x54]                        @ 0800725E
	cmp	r0, #3                                 @ 08007260  (ch - 4) <= 3: PCM channel note-on
	bhi	.L080072B2                             @ 08007262
	ldr	r2, .Llit080072F0                      @ 08007264  =mcStepTable
	ldr	r3, [sp, #0x44]                        @ 08007266
	ldr	r1, [r3]                               @ 08007268
	movs	r0, #0x5f                             @ 0800726A  step = mcStepTable[0x5F - note]
	subs	r0, r0, r1                            @ 0800726C
	lsls	r0, r0, #2                            @ 0800726E
	adds	r0, r0, r2                            @ 08007270
	ldr	r0, [r0]                               @ 08007272
	ldr	r4, [sp, #0x4c]                        @ 08007274
	str	r0, [r4]                               @ 08007276
	mov	r0, r9                                 @ 08007278
	adds	r0, #0x34                             @ 0800727A
	ldr	r5, [sp, #0x2c]                        @ 0800727C
	adds	r0, r5, r0                            @ 0800727E
	movs	r1, #1                                @ 08007280
	str	r1, [r0]                               @ 08007282  +0x34 = 1
	mov	r0, r9                                 @ 08007284
	adds	r0, #0x38                             @ 08007286
	adds	r2, r5, r0                            @ 08007288
	movs	r6, #0                                @ 0800728A
	str	r6, [r2]                               @ 0800728C  pos = 0
	ldr	r1, .Llit080072F4                      @ 0800728E  =mcSmpInstTable
	subs	r0, #0x1c                             @ 08007290
	adds	r0, r5, r0                            @ 08007292
	ldr	r0, [r0]                               @ 08007294
	lsls	r0, r0, #4                            @ 08007296
	adds	r1, #4                                @ 08007298
	adds	r0, r0, r1                            @ 0800729A
	ldr	r0, [r0]                               @ 0800729C
	subs	r0, #4                                @ 0800729E
	lsls	r0, r0, #0xe                          @ 080072A0
	ldr	r7, [sp, #0x50]                        @ 080072A2
	str	r0, [r7]                               @ 080072A4  end = (mcSmpInstTable[inst].length - 4) << 14
	ldr	r0, [r3]                               @ 080072A6
	cmp	r0, #0x60                              @ 080072A8  rest / cmd 0x60
	bne	.L080072B2                             @ 080072AA
	movs	r0, #1                                @ 080072AC
	rsbs	r0, r0, #0                            @ 080072AE
	str	r0, [r2]                               @ 080072B0  rest: pos = -1 (stopped)
.L080072B2:
	ldr	r0, [sp, #0x24]                        @ 080072B2
	cmp	r0, #0x65                              @ 080072B4  pattern end
	bne	.L080072BC                             @ 080072B6
	bl	.L080066D6                              @ 080072B8  long branch
.L080072BC:
	ldr	r1, [sp, #0x58]                        @ 080072BC
	mov	r10, r1                                @ 080072BE
	cmp	r1, #7                                 @ 080072C0
	bgt	.L080072C8                             @ 080072C2
	bl	.L08006672                              @ 080072C4  long branch
.L080072C8:
	add	sp, #0x6c                              @ 080072C8
	pop	{r3, r4, r5}                           @ 080072CA
	mov	r8, r3                                 @ 080072CC
	mov	r9, r4                                 @ 080072CE
	mov	r10, r5                                @ 080072D0
	pop	{r4, r5, r6, r7}                       @ 080072D2
	pop	{r0}                                   @ 080072D4
	bx	r0                                      @ 080072D6
.Llit080072D8:
	.word	mcChan+0x90+CH_freq            @ 080072D8  = 0x03007818
.Llit080072DC:
	.word	REG_SOUND3CNT_X                @ 080072DC  = 0x04000074
.Llit080072E0:
	.word	mcInstTable                    @ 080072E0  = 0x083D5214
.Llit080072E4:
	.word	REG_SOUND4CNT_L                @ 080072E4  = 0x04000078
.Llit080072E8:
	.word	0xFFFF8000                     @ 080072E8
.Llit080072EC:
	.word	REG_SOUND4CNT_H                @ 080072EC  = 0x0400007C
.Llit080072F0:
	.word	mcStepTable                    @ 080072F0  = 0x08346B78
.Llit080072F4:
	.word	mcSmpInstTable                 @ 080072F4  = 0x083CBEEC
@ --------------------------------------------------------------------------
@ mcSoundInit  (0x080072F8)
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
	push	{r4, r5, r6, r7, lr}                  @ 080072F8
	mov	r7, r9                                 @ 080072FA
	mov	r6, r8                                 @ 080072FC
	push	{r6, r7}                              @ 080072FE
	ldr	r2, .Llit08007410                      @ 08007300  =mcChan
	movs	r1, #0                                @ 08007302
	str	r1, [r2]                               @ 08007304
	str	r1, [r2, #0x48]                        @ 08007306
	adds	r0, r2, #0                            @ 08007308
	adds	r0, #0x90                             @ 0800730A
	str	r1, [r0]                               @ 0800730C
	adds	r0, #0x48                             @ 0800730E
	str	r1, [r0]                               @ 08007310
	movs	r3, #0x90                             @ 08007312
	lsls	r3, r3, #1                            @ 08007314
	adds	r0, r2, r3                            @ 08007316
	str	r1, [r0]                               @ 08007318
	adds	r3, #0x48                             @ 0800731A
	adds	r0, r2, r3                            @ 0800731C
	str	r1, [r0]                               @ 0800731E
	adds	r3, #0x48                             @ 08007320
	adds	r0, r2, r3                            @ 08007322
	str	r1, [r0]                               @ 08007324
	adds	r3, #0x48                             @ 08007326
	adds	r0, r2, r3                            @ 08007328
	str	r1, [r0]                               @ 0800732A
	ldr	r2, .Llit08007414                      @ 0800732C  =mcTempo
	movs	r0, #0x80                             @ 0800732E
	lsls	r0, r0, #1                            @ 08007330
	str	r0, [r2]                               @ 08007332
	ldr	r0, .Llit08007418                      @ 08007334  =mcTempoAcc
	str	r1, [r0]                               @ 08007336
	ldr	r2, .Llit0800741C                      @ 08007338  =mcMasterPan
	movs	r0, #7                                @ 0800733A
	str	r0, [r2]                               @ 0800733C
	ldr	r0, .Llit08007420                      @ 0800733E  =mcPaused
	str	r1, [r0]                               @ 08007340
	ldr	r1, .Llit08007424                      @ 08007342  =REG_WAVE_RAM
	ldr	r3, .Llit08007428                      @ 08007344  =mcPsgSfx
	ldr	r5, .Llit0800742C                      @ 08007346  =mcMixMusic
	ldr	r6, .Llit08007430                      @ 08007348  =IWRAM_mcMixMusic
	ldr	r7, .Llit08007434                      @ 0800734A  =mcSfxMix+1
	ldr	r0, .Llit08007438                      @ 0800734C  =IWRAM_mcSfxMix
	mov	r12, r0                                @ 0800734E
	ldr	r2, .Llit0800743C                      @ 08007350  =mcFadeLevel
	mov	r8, r2                                 @ 08007352
	ldr	r0, .Llit08007440                      @ 08007354  =mcFading
	mov	r9, r0                                 @ 08007356
	ldr	r0, .Llit08007444                      @ 08007358  =0xFFFF
	adds	r2, r0, #0                            @ 0800735A
	adds	r0, r1, #6                            @ 0800735C
.L0800735E:
	strh	r2, [r0]                              @ 0800735E
	subs	r0, #2                                @ 08007360
	cmp	r0, r1                                 @ 08007362
	bge	.L0800735E                             @ 08007364
	movs	r2, #0                                @ 08007366
	adds	r0, r1, #0                            @ 08007368
	adds	r0, #8                                @ 0800736A
	movs	r1, #3                                @ 0800736C
.L0800736E:
	strh	r2, [r0]                              @ 0800736E
	adds	r0, #2                                @ 08007370
	subs	r1, #1                                @ 08007372
	cmp	r1, #0                                 @ 08007374
	bge	.L0800736E                             @ 08007376
	ldr	r1, .Llit08007448                      @ 08007378  =REG_SOUNDCNT_L
	ldr	r2, .Llit0800744C                      @ 0800737A  =0xFF0E
	adds	r0, r2, #0                            @ 0800737C
	strh	r0, [r1]                              @ 0800737E
	adds	r1, #4                                @ 08007380
	movs	r0, #0x8f                             @ 08007382
	strh	r0, [r1]                              @ 08007384
	subs	r1, #2                                @ 08007386
	ldr	r2, .Llit08007450                      @ 08007388  =0xFB0E
	adds	r0, r2, #0                            @ 0800738A
	strh	r0, [r1]                              @ 0800738C
	subs	r1, #0x12                             @ 0800738E
	movs	r0, #0xc0                             @ 08007390
	strh	r0, [r1]                              @ 08007392
	adds	r1, #0x20                             @ 08007394
	ldr	r0, .Llit08007444                      @ 08007396  =0xFFFF
	adds	r2, r0, #0                            @ 08007398
	adds	r0, r1, #6                            @ 0800739A
.L0800739C:
	strh	r2, [r0]                              @ 0800739C
	subs	r0, #2                                @ 0800739E
	cmp	r0, r1                                 @ 080073A0
	bge	.L0800739C                             @ 080073A2
	movs	r2, #0                                @ 080073A4
	adds	r0, r1, #0                            @ 080073A6
	adds	r0, #8                                @ 080073A8
	movs	r1, #3                                @ 080073AA
.L080073AC:
	strh	r2, [r0]                              @ 080073AC
	adds	r0, #2                                @ 080073AE
	subs	r1, #1                                @ 080073B0
	cmp	r1, #0                                 @ 080073B2
	bge	.L080073AC                             @ 080073B4
	movs	r1, #8                                @ 080073B6
	ldr	r0, .Llit08007454                      @ 080073B8  =REG_SOUND1CNT_L
	strh	r1, [r0]                              @ 080073BA
	movs	r0, #0                                @ 080073BC
	str	r0, [r3]                               @ 080073BE
	str	r0, [r3, #0xc]                         @ 080073C0
	str	r0, [r3, #0x18]                        @ 080073C2
	str	r0, [r3, #0x24]                        @ 080073C4
	str	r0, [r3, #0x30]                        @ 080073C6
	str	r0, [r3, #0x3c]                        @ 080073C8
	ldr	r4, .Llit08007458                      @ 080073CA  =mcSfxLoop
	ldr	r3, .Llit0800745C                      @ 080073CC  =mcSfxPending
	ldr	r2, .Llit08007460                      @ 080073CE  =mcSfxPtr
	movs	r1, #1                                @ 080073D0
.L080073D2:
	stm	r2!, {r0}                              @ 080073D2
	stm	r3!, {r0}                              @ 080073D4
	stm	r4!, {r0}                              @ 080073D6
	subs	r1, #1                                @ 080073D8
	cmp	r1, #0                                 @ 080073DA
	bge	.L080073D2                             @ 080073DC
	ldr	r0, .Llit08007464                      @ 080073DE  =REG_DMA3SAD
	str	r5, [r0]                               @ 080073E0
	str	r6, [r0, #4]                           @ 080073E2
	ldr	r1, .Llit08007468                      @ 080073E4  =0x84000258
	str	r1, [r0, #8]                           @ 080073E6
	ldr	r1, [r0, #8]                           @ 080073E8
	str	r7, [r0]                               @ 080073EA
	mov	r1, r12                                @ 080073EC
	str	r1, [r0, #4]                           @ 080073EE
	ldr	r1, .Llit0800746C                      @ 080073F0  =0x84000078
	str	r1, [r0, #8]                           @ 080073F2
	ldr	r0, [r0, #8]                           @ 080073F4
	movs	r0, #7                                @ 080073F6
	mov	r2, r8                                 @ 080073F8
	str	r0, [r2]                               @ 080073FA
	movs	r0, #0                                @ 080073FC
	mov	r3, r9                                 @ 080073FE
	str	r0, [r3]                               @ 08007400
	pop	{r3, r4}                               @ 08007402
	mov	r8, r3                                 @ 08007404
	mov	r9, r4                                 @ 08007406
	pop	{r4, r5, r6, r7}                       @ 08007408
	pop	{r0}                                   @ 0800740A
	bx	r0                                      @ 0800740C
	.hword	0x0000                          @ 0800740E  (padding)
.Llit08007410:
	.word	mcChan                         @ 08007410  = 0x03007770
.Llit08007414:
	.word	mcTempo                        @ 08007414  = 0x03007404
.Llit08007418:
	.word	mcTempoAcc                     @ 08007418  = 0x03007574
.Llit0800741C:
	.word	mcMasterPan                    @ 0800741C  = 0x03007578
.Llit08007420:
	.word	mcPaused                       @ 08007420  = 0x03007570
.Llit08007424:
	.word	REG_WAVE_RAM                   @ 08007424  = 0x04000090
.Llit08007428:
	.word	mcPsgSfx                       @ 08007428  = 0x03007590
.Llit0800742C:
	.word	mcMixMusic                     @ 0800742C  = 0x08007654
.Llit08007430:
	.word	IWRAM_mcMixMusic               @ 08007430  = 0x03006AA0
.Llit08007434:
	.word	mcSfxMix+1                     @ 08007434  = 0x080061D1
.Llit08007438:
	.word	IWRAM_mcSfxMix                 @ 08007438  = 0x030068A0
.Llit0800743C:
	.word	mcFadeLevel                    @ 0800743C  = 0x030079B0
.Llit08007440:
	.word	mcFading                       @ 08007440  = 0x030079B4
.Llit08007444:
	.word	0x0000FFFF                     @ 08007444
.Llit08007448:
	.word	REG_SOUNDCNT_L                 @ 08007448  = 0x04000080
.Llit0800744C:
	.word	0x0000FF0E                     @ 0800744C
.Llit08007450:
	.word	0x0000FB0E                     @ 08007450
.Llit08007454:
	.word	REG_SOUND1CNT_L                @ 08007454  = 0x04000060
.Llit08007458:
	.word	mcSfxLoop                      @ 08007458  = 0x030075E8
.Llit0800745C:
	.word	mcSfxPending                   @ 0800745C  = 0x030075D8
.Llit08007460:
	.word	mcSfxPtr                       @ 08007460  = 0x03006A88
.Llit08007464:
	.word	REG_DMA3SAD                    @ 08007464  = 0x040000D4
.Llit08007468:
	.word	0x84000258                     @ 08007468
.Llit0800746C:
	.word	0x84000078                     @ 0800746C
@ --------------------------------------------------------------------------
@ mcSfxStopById  (0x08007470)
@   void mcSfxStopById(int id): stop any SFX voice playing table entry id (mcSfxPtr = 0)
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcSfxStopById
mcSfxStopById:
	push	{r4, r5, lr}                          @ 08007470
	adds	r4, r0, #0                            @ 08007472
	movs	r5, #0                                @ 08007474
	ldr	r3, .Llit08007494                      @ 08007476  =mcSfxPtr
	ldr	r2, .Llit08007498                      @ 08007478  =mcSfxId
	movs	r1, #1                                @ 0800747A
.L0800747C:
	ldr	r0, [r2]                               @ 0800747C
	cmp	r0, r4                                 @ 0800747E
	bne	.L08007484                             @ 08007480
	str	r5, [r3]                               @ 08007482
.L08007484:
	adds	r3, #4                                @ 08007484
	adds	r2, #4                                @ 08007486
	subs	r1, #1                                @ 08007488
	cmp	r1, #0                                 @ 0800748A
	bge	.L0800747C                             @ 0800748C
	pop	{r4, r5}                               @ 0800748E
	pop	{r0}                                   @ 08007490
	bx	r0                                      @ 08007492
.Llit08007494:
	.word	mcSfxPtr                       @ 08007494  = 0x03006A88
.Llit08007498:
	.word	mcSfxId                        @ 08007498  = 0x030079D0
@ --------------------------------------------------------------------------
@ mcFadeOut  (0x0800749C)
@   Start the music fade-out: mcFading = 1; mcFadeCounter = 0 (NO CALLERS)
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcFadeOut
mcFadeOut:
	ldr	r1, .Llit080074AC                      @ 0800749C  =mcFading
	movs	r0, #1                                @ 0800749E
	str	r0, [r1]                               @ 080074A0
	ldr	r1, .Llit080074B0                      @ 080074A2  =mcFadeCounter
	movs	r0, #0                                @ 080074A4
	str	r0, [r1]                               @ 080074A6
	bx	lr                                      @ 080074A8
	.hword	0x0000                          @ 080074AA  (padding)
.Llit080074AC:
	.word	mcFading                       @ 080074AC  = 0x030079B4
.Llit080074B0:
	.word	mcFadeCounter                  @ 080074B0  = 0x03007400
@ --------------------------------------------------------------------------
@ mcPlayPsgSfx  (0x080074B4)
@   PSG register-script SFX, unchanged from E.T. (NO CALLERS)
@       for each of the 4 entries in mcPsgSfxMap[n] != 0xFF: script = mcPsgSfxScripts[x];
@       slot[script->channel] = {script+2, -5, 0}; mcChan[channel].owned = 0
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcPlayPsgSfx
mcPlayPsgSfx:
	push	{r4, r5, r6, r7, lr}                  @ 080074B4
	mov	r7, r10                                @ 080074B6
	mov	r6, r9                                 @ 080074B8
	mov	r5, r8                                 @ 080074BA
	push	{r5, r6, r7}                          @ 080074BC
	adds	r5, r0, #0                            @ 080074BE
	ldr	r0, .Llit08007528                      @ 080074C0  =mcPsgSfxCur
	str	r5, [r0]                               @ 080074C2
	movs	r4, #0                                @ 080074C4
	ldr	r0, .Llit0800752C                      @ 080074C6  =mcPsgSfxMap
	mov	r10, r0                                @ 080074C8
	ldr	r0, .Llit08007530                      @ 080074CA  =mcPsgSfxScripts
	mov	r9, r0                                 @ 080074CC
	ldr	r6, .Llit08007534                      @ 080074CE  =mcPsgSfx
	movs	r0, #8                                @ 080074D0
	adds	r0, r0, r6                            @ 080074D2
	mov	r8, r0                                 @ 080074D4
	movs	r7, #0                                @ 080074D6
	ldr	r0, .Llit08007538                      @ 080074D8  =mcChan+CH_owned
	mov	r12, r0                                @ 080074DA
.L080074DC:
	lsls	r0, r5, #2                            @ 080074DC
	adds	r0, r4, r0                            @ 080074DE
	add	r0, r10                                @ 080074E0
	ldrb	r0, [r0]                              @ 080074E2
	cmp	r0, #0xff                              @ 080074E4
	beq	.L08007514                             @ 080074E6
	lsls	r0, r0, #2                            @ 080074E8
	add	r0, r9                                 @ 080074EA
	ldr	r2, [r0]                               @ 080074EC
	ldrh	r3, [r2]                              @ 080074EE
	adds	r2, #2                                @ 080074F0
	lsls	r0, r3, #1                            @ 080074F2
	adds	r0, r0, r3                            @ 080074F4
	lsls	r0, r0, #2                            @ 080074F6
	adds	r1, r0, r6                            @ 080074F8
	str	r2, [r1]                               @ 080074FA
	adds	r1, r6, #4                            @ 080074FC
	adds	r1, r0, r1                            @ 080074FE
	movs	r2, #5                                @ 08007500
	rsbs	r2, r2, #0                            @ 08007502
	str	r2, [r1]                               @ 08007504
	add	r0, r8                                 @ 08007506
	str	r7, [r0]                               @ 08007508
	lsls	r0, r3, #3                            @ 0800750A
	adds	r0, r0, r3                            @ 0800750C
	lsls	r0, r0, #3                            @ 0800750E
	add	r0, r12                                @ 08007510
	str	r7, [r0]                               @ 08007512
.L08007514:
	adds	r4, #1                                @ 08007514
	cmp	r4, #3                                 @ 08007516
	ble	.L080074DC                             @ 08007518
	pop	{r3, r4, r5}                           @ 0800751A
	mov	r8, r3                                 @ 0800751C
	mov	r9, r4                                 @ 0800751E
	mov	r10, r5                                @ 08007520
	pop	{r4, r5, r6, r7}                       @ 08007522
	pop	{r0}                                   @ 08007524
	bx	r0                                      @ 08007526
.Llit08007528:
	.word	mcPsgSfxCur                    @ 08007528  = 0x03006880
.Llit0800752C:
	.word	mcPsgSfxMap                    @ 0800752C  = 0x083CC0EC
.Llit08007530:
	.word	mcPsgSfxScripts                @ 08007530  = 0x083CC26C
.Llit08007534:
	.word	mcPsgSfx                       @ 08007534  = 0x03007590
.Llit08007538:
	.word	mcChan+CH_owned                @ 08007538  = 0x03007774
@ --------------------------------------------------------------------------
@ mcUnpauseAndStopSfx  (0x0800753C)
@   (name inferred; NO CALLERS)
@       if (mcPaused) { mcFadeLevel = mcSaveFadeLevel; mcFading = mcSaveFading; mcPaused = 0 }
@       mcSfxPtr[0] = mcSfxPtr[1] = 0
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcUnpauseAndStopSfx
mcUnpauseAndStopSfx:
	ldr	r2, .Llit08007564                      @ 0800753C  =mcPaused
	ldr	r0, [r2]                               @ 0800753E
	cmp	r0, #0                                 @ 08007540
	beq	.L08007558                             @ 08007542
	ldr	r1, .Llit08007568                      @ 08007544  =mcFadeLevel
	ldr	r0, .Llit0800756C                      @ 08007546  =mcSaveFadeLevel
	ldr	r0, [r0]                               @ 08007548
	str	r0, [r1]                               @ 0800754A
	ldr	r1, .Llit08007570                      @ 0800754C  =mcFading
	ldr	r0, .Llit08007574                      @ 0800754E  =mcSaveFading
	ldr	r0, [r0]                               @ 08007550
	str	r0, [r1]                               @ 08007552
	movs	r0, #0                                @ 08007554
	str	r0, [r2]                               @ 08007556
.L08007558:
	ldr	r1, .Llit08007578                      @ 08007558  =mcSfxPtr
	movs	r0, #0                                @ 0800755A
	str	r0, [r1]                               @ 0800755C
	str	r0, [r1, #4]                           @ 0800755E
	bx	lr                                      @ 08007560
	.hword	0x0000                          @ 08007562  (padding)
.Llit08007564:
	.word	mcPaused                       @ 08007564  = 0x03007570
.Llit08007568:
	.word	mcFadeLevel                    @ 08007568  = 0x030079B0
.Llit0800756C:
	.word	mcSaveFadeLevel                @ 0800756C  = 0x030079C8
.Llit08007570:
	.word	mcFading                       @ 08007570  = 0x030079B4
.Llit08007574:
	.word	mcSaveFading                   @ 08007574  = 0x030079C4
.Llit08007578:
	.word	mcSfxPtr                       @ 08007578  = 0x03006A88
@ --------------------------------------------------------------------------
@ mcDsSfxStart  (0x0800757C)
@   void mcDsSfxStart(int id, int v): as in Snood 2, but with 20-byte mcSfxTable entries
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcDsSfxStart
mcDsSfxStart:
	push	{r4, lr}                              @ 0800757C
	ldr	r2, .Llit080075D4                      @ 0800757E  =mcSfxId
	lsls	r1, r1, #2                            @ 08007580
	adds	r2, r1, r2                            @ 08007582
	str	r0, [r2]                               @ 08007584
	ldr	r3, .Llit080075D8                      @ 08007586  =mcSfxPtr
	adds	r3, r1, r3                            @ 08007588
	ldr	r4, .Llit080075DC                      @ 0800758A  =mcSfxTable
	lsls	r2, r0, #2                            @ 0800758C
	adds	r2, r2, r0                            @ 0800758E
	lsls	r2, r2, #2                            @ 08007590
	adds	r0, r2, r4                            @ 08007592
	ldr	r0, [r0]                               @ 08007594
	str	r0, [r3]                               @ 08007596
	ldr	r3, .Llit080075E0                      @ 08007598  =mcSfxFrames
	adds	r3, r1, r3                            @ 0800759A
	adds	r0, r4, #4                            @ 0800759C
	adds	r0, r2, r0                            @ 0800759E
	ldr	r0, [r0]                               @ 080075A0
	subs	r0, #1                                @ 080075A2
	str	r0, [r3]                               @ 080075A4
	ldr	r3, .Llit080075E4                      @ 080075A6  =mcSfxLoop
	adds	r3, r1, r3                            @ 080075A8
	adds	r4, #8                                @ 080075AA
	adds	r2, r2, r4                            @ 080075AC
	ldr	r0, [r2]                               @ 080075AE
	str	r0, [r3]                               @ 080075B0
	ldr	r0, .Llit080075E8                      @ 080075B2  =mcSfxPending
	adds	r0, r1, r0                            @ 080075B4
	movs	r2, #1                                @ 080075B6
	str	r2, [r0]                               @ 080075B8
	ldr	r0, .Llit080075EC                      @ 080075BA  =mcSfxActive
	adds	r1, r1, r0                            @ 080075BC
	str	r2, [r1]                               @ 080075BE
	ldr	r2, .Llit080075F0                      @ 080075C0  =REG_SOUNDCNT_H
	ldrh	r1, [r2]                              @ 080075C2
	ldr	r0, .Llit080075F4                      @ 080075C4  =0xFFFB
	ands	r0, r1                                @ 080075C6
	movs	r1, #4                                @ 080075C8
	orrs	r0, r1                                @ 080075CA
	strh	r0, [r2]                              @ 080075CC
	pop	{r4}                                   @ 080075CE
	pop	{r0}                                   @ 080075D0
	bx	r0                                      @ 080075D2
.Llit080075D4:
	.word	mcSfxId                        @ 080075D4  = 0x030079D0
.Llit080075D8:
	.word	mcSfxPtr                       @ 080075D8  = 0x03006A88
.Llit080075DC:
	.word	mcSfxTable                     @ 080075DC  = 0x083CBBCC
.Llit080075E0:
	.word	mcSfxFrames                    @ 080075E0  = 0x03006890
.Llit080075E4:
	.word	mcSfxLoop                      @ 080075E4  = 0x030075E8
.Llit080075E8:
	.word	mcSfxPending                   @ 080075E8  = 0x030075D8
.Llit080075EC:
	.word	mcSfxActive                    @ 080075EC  = 0x03007760
.Llit080075F0:
	.word	REG_SOUNDCNT_H                 @ 080075F0  = 0x04000082
.Llit080075F4:
	.word	0x0000FFFB                     @ 080075F4
@ --------------------------------------------------------------------------
@ mcApplyFade  (0x080075F8)
@   Scale the next music buffer by mcFadeTable[mcFadeLevel] >> 8 (NO CALLERS; mcUpdate has an inline copy)
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcApplyFade
mcApplyFade:
	push	{r4, lr}                              @ 080075F8
	sub	sp, #0x24                              @ 080075FA
	mov	r1, sp                                 @ 080075FC
	ldr	r0, .Llit08007644                      @ 080075FE  =mcFadeTable
	ldm	r0!, {r2, r3, r4}                      @ 08007600
	stm	r1!, {r2, r3, r4}                      @ 08007602
	ldm	r0!, {r2, r3, r4}                      @ 08007604
	stm	r1!, {r2, r3, r4}                      @ 08007606
	ldm	r0!, {r2, r3, r4}                      @ 08007608
	stm	r1!, {r2, r3, r4}                      @ 0800760A
	ldr	r0, .Llit08007648                      @ 0800760C  =mcFadeLevel
	ldr	r0, [r0]                               @ 0800760E
	lsls	r0, r0, #2                            @ 08007610
	add	r0, sp                                 @ 08007612
	ldr	r3, [r0]                               @ 08007614
	ldr	r0, .Llit0800764C                      @ 08007616  =mcBufIndex
	ldr	r0, [r0]                               @ 08007618
	adds	r0, #1                                @ 0800761A
	movs	r1, #1                                @ 0800761C
	ands	r0, r1                                @ 0800761E
	ldr	r2, .Llit08007650                      @ 08007620  =mcMusicBuf
	movs	r1, #0xb0                             @ 08007622
	muls	r0, r1, r0                            @ 08007624
	adds	r1, r0, r2                            @ 08007626
	movs	r2, #0xaf                             @ 08007628
.L0800762A:
	movs	r0, #0                                @ 0800762A
	ldrsb	r0, [r1, r0]                         @ 0800762C
	muls	r0, r3, r0                            @ 0800762E
	asrs	r0, r0, #8                            @ 08007630
	strb	r0, [r1]                              @ 08007632
	adds	r1, #1                                @ 08007634
	subs	r2, #1                                @ 08007636
	cmp	r2, #0                                 @ 08007638
	bge	.L0800762A                             @ 0800763A
	add	sp, #0x24                              @ 0800763C
	pop	{r4}                                   @ 0800763E
	pop	{r0}                                   @ 08007640
	bx	r0                                      @ 08007642
.Llit08007644:
	.word	mcFadeTable                    @ 08007644  = 0x0803AE58
.Llit08007648:
	.word	mcFadeLevel                    @ 08007648  = 0x030079B0
.Llit0800764C:
	.word	mcBufIndex                     @ 0800764C  = 0x03006A98
.Llit08007650:
	.word	mcMusicBuf                     @ 08007650  = 0x03007410
@ --------------------------------------------------------------------------
@ mcMixMusic  (0x08007654)
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
	mov	r12, sp                                @ 08007654
	push	{r4, r5, r6, r7, r8, r9, r10, r11, r12, lr, pc} @ 08007658
	sub	r11, r12, #4                           @ 0800765C
	sub	sp, sp, #0x3c                          @ 08007660
	str	r0, [r11, #-0x2c]                      @ 08007664
	ldr	r5, .Llit08007A30                      @ 08007668  =mcChan
	add	r3, r0, r0, lsl #3                     @ 0800766C
	lsl	r9, r3, #3                             @ 08007670
	add	r2, r5, #0x38                          @ 08007674
	add	r3, r5, #0x30                          @ 08007678
	ldr	r10, [r2, r9]                          @ 0800767C
	add	r12, r0, #1                            @ 08007680
	ldr	r1, [r3, r9]                           @ 08007684
	add	r12, r12, r12, lsl #3                  @ 08007688
	str	r1, [r11, #-0x40]                      @ 0800768C
	lsl	r12, r12, #3                           @ 08007690
	ldr	r8, [r2, r12]                          @ 08007694
	ldr	lr, [r3, r12]                          @ 08007698
	add	r0, r0, #2                             @ 0800769C
	str	lr, [r11, #-0x44]                      @ 080076A0
	add	r0, r0, r0, lsl #3                     @ 080076A4
	ldr	lr, [r11, #-0x2c]                      @ 080076A8
	lsl	r0, r0, #3                             @ 080076AC
	ldr	r1, [r3, r0]                           @ 080076B0
	ldr	r7, [r2, r0]                           @ 080076B4
	str	r1, [r11, #-0x48]                      @ 080076B8
	ldr	r4, .Llit08007A34                      @ 080076BC  =mcSmpInstTable
	add	r1, lr, #3                             @ 080076C0
	add	r1, r1, r1, lsl #3                     @ 080076C4
	lsl	r1, r1, #3                             @ 080076C8
	ldr	r3, [r3, r1]                           @ 080076CC
	ldr	r6, [r2, r1]                           @ 080076D0
	str	r3, [r11, #-0x4c]                      @ 080076D4
	add	lr, r5, #0x1c                          @ 080076D8
	ldr	r3, [lr, r9]                           @ 080076DC
	ldr	r3, [r4, r3, lsl #4]                   @ 080076E0
	str	r3, [r11, #-0x30]                      @ 080076E4
	ldr	r2, [lr, r12]                          @ 080076E8
	ldr	r2, [r4, r2, lsl #4]                   @ 080076EC
	str	r2, [r11, #-0x34]                      @ 080076F0
	ldr	r3, [lr, r0]                           @ 080076F4
	ldr	r3, [r4, r3, lsl #4]                   @ 080076F8
	str	r3, [r11, #-0x38]                      @ 080076FC
	ldr	r0, [lr, r1]                           @ 08007700
	add	r2, r5, #0x14                          @ 08007704
	ldr	r3, [r2, r9]                           @ 08007708
	ldr	r0, [r4, r0, lsl #4]                   @ 0800770C
	str	r0, [r11, #-0x3c]                      @ 08007710
	cmp	r3, #0x60                              @ 08007714
	beq	.L08007730                             @ 08007718
	add	r3, r5, #0x20                          @ 0800771C
	ldr	r2, [r3, r9]                           @ 08007720
	cmn	r10, #1                                @ 08007724
	cmpne	r2, #0                               @ 08007728
	bne	.L08007744                             @ 0800772C
.L08007730:
	mov	r1, #0                                 @ 08007730
	str	r1, [r11, #-0x40]                      @ 08007734
	ldr	r2, .Llit08007A38                      @ 08007738  =pcm_08346CF8+4
	mvn	r10, #0                                @ 0800773C
	str	r2, [r11, #-0x30]                      @ 08007740
.L08007744:
	ldr	r3, [r11, #-0x2c]                      @ 08007744
	ldr	r12, .Llit08007A30                     @ 08007748  =mcChan
	add	r1, r3, #1                             @ 0800774C
	add	r3, r1, r1, lsl #3                     @ 08007750
	lsl	r0, r3, #3                             @ 08007754
	add	r2, r12, #0x14                         @ 08007758
	ldr	r3, [r2, r0]                           @ 0800775C
	str	r1, [r11, #-0x54]                      @ 08007760
	cmp	r3, #0x60                              @ 08007764
	beq	.L08007780                             @ 08007768
	add	r3, r12, #0x20                         @ 0800776C
	ldr	r2, [r3, r0]                           @ 08007770
	cmn	r8, #1                                 @ 08007774
	cmpne	r2, #0                               @ 08007778
	bne	.L08007794                             @ 0800777C
.L08007780:
	mov	lr, #0                                 @ 08007780
	str	lr, [r11, #-0x44]                      @ 08007784
	ldr	r1, .Llit08007A38                      @ 08007788  =pcm_08346CF8+4
	mvn	r8, #0                                 @ 0800778C
	str	r1, [r11, #-0x34]                      @ 08007790
.L08007794:
	ldr	r2, [r11, #-0x2c]                      @ 08007794
	add	r1, r2, #2                             @ 08007798
	add	r3, r1, r1, lsl #3                     @ 0800779C
	lsl	r0, r3, #3                             @ 080077A0
	ldr	r3, .Llit08007A30                      @ 080077A4  =mcChan
	add	r2, r3, #0x14                          @ 080077A8
	ldr	r3, [r2, r0]                           @ 080077AC
	str	r1, [r11, #-0x58]                      @ 080077B0
	cmp	r3, #0x60                              @ 080077B4
	beq	.L080077D4                             @ 080077B8
	ldr	r12, .Llit08007A30                     @ 080077BC  =mcChan
	add	r3, r12, #0x20                         @ 080077C0
	ldr	r2, [r3, r0]                           @ 080077C4
	cmn	r7, #1                                 @ 080077C8
	cmpne	r2, #0                               @ 080077CC
	bne	.L080077E8                             @ 080077D0
.L080077D4:
	mov	lr, #0                                 @ 080077D4
	str	lr, [r11, #-0x48]                      @ 080077D8
	ldr	r1, .Llit08007A38                      @ 080077DC  =pcm_08346CF8+4
	mvn	r7, #0                                 @ 080077E0
	str	r1, [r11, #-0x38]                      @ 080077E4
.L080077E8:
	ldr	r2, [r11, #-0x2c]                      @ 080077E8
	add	r1, r2, #3                             @ 080077EC
	add	r3, r1, r1, lsl #3                     @ 080077F0
	lsl	r0, r3, #3                             @ 080077F4
	ldr	r3, .Llit08007A30                      @ 080077F8  =mcChan
	add	r2, r3, #0x14                          @ 080077FC
	ldr	r3, [r2, r0]                           @ 08007800
	str	r1, [r11, #-0x5c]                      @ 08007804
	cmp	r3, #0x60                              @ 08007808
	beq	.L08007828                             @ 0800780C
	ldr	r12, .Llit08007A30                     @ 08007810  =mcChan
	add	r3, r12, #0x20                         @ 08007814
	ldr	r2, [r3, r0]                           @ 08007818
	cmn	r6, #1                                 @ 0800781C  pos == -1 or seqPtr == 0 (or note == 0x60 above) ->
	cmpne	r2, #0                               @ 08007820
	bne	.L0800783C                             @ 08007824
.L08007828:
	mov	lr, #0                                 @ 08007828  silent: step = 0, source = silence block, pos = -1
	str	lr, [r11, #-0x4c]                      @ 0800782C
	ldr	r1, .Llit08007A38                      @ 08007830  =pcm_08346CF8+4
	mvn	r6, #0                                 @ 08007834
	str	r1, [r11, #-0x3c]                      @ 08007838
.L0800783C:
	ldr	r2, .Llit08007A3C                      @ 0800783C  =mcBufIndex
	ldr	r3, [r2]                               @ 08007840
	mov	r4, #0                                 @ 08007844
	ldr	r5, .Llit08007A40                      @ 08007848  =mcMusicBuf
	add	r3, r3, #1                             @ 0800784C
	and	r3, r3, #1                             @ 08007850
	cmp	r3, r4                                 @ 08007854
	movne	r9, #0xb0                            @ 08007858
	moveq	r9, r4                               @ 0800785C
	ldr	r2, [r11, #-0x2c]                      @ 08007860
	add	r3, r9, #1                             @ 08007864
	str	r3, [r11, #-0x50]                      @ 08007868
	lsl	r2, r2, #3                             @ 0800786C
	str	r2, [r11, #-0x60]                      @ 08007870
.L08007874:
	ldr	lr, [r11, #-0x30]                      @ 08007874  mix loop: 2 output samples per iteration, 88 iterations
	ldr	r2, [r11, #-0x50]                      @ 08007878
	ldr	r3, [r11, #-0x3c]                      @ 0800787C
	add	r1, lr, r10, asr #14                   @ 08007880  s0 = src0[pos0 >> 14]  (signed 8-bit)
	ldrsb	r1, [r1]                             @ 08007884
	add	r2, r4, r2                             @ 08007888
	ldr	lr, [r11, #-0x38]                      @ 0800788C
	add	r0, r3, r6, asr #14                    @ 08007890
	str	r2, [r11, #-0x64]                      @ 08007894
	add	r3, lr, r7, asr #14                    @ 08007898
	ldr	lr, [r11, #-0x34]                      @ 0800789C
	ldrsb	r0, [r0]                             @ 080078A0
	add	r12, r4, r9                            @ 080078A4
	ldrsb	r3, [r3]                             @ 080078A8
	add	r2, lr, r8, asr #14                    @ 080078AC
	ldrsb	r2, [r2]                             @ 080078B0
	add	r1, r1, r0                             @ 080078B4
	add	r3, r3, r2                             @ 080078B8
	add	r1, r1, r3                             @ 080078BC
	asr	r1, r1, #2                             @ 080078C0  (s0 + s1 + s2 + s3) >> 2
	strb	r1, [r5, r12]                         @ 080078C4
	ldr	r1, [r11, #-0x40]                      @ 080078C8
	ldr	r2, [r11, #-0x30]                      @ 080078CC
	ldr	r3, [r11, #-0x4c]                      @ 080078D0
	ldr	r12, [r11, #-0x3c]                     @ 080078D4
	ldr	lr, [r11, #-0x48]                      @ 080078D8
	add	r10, r10, r1                           @ 080078DC
	add	r1, r2, r10, asr #14                   @ 080078E0
	add	r6, r6, r3                             @ 080078E4
	ldrsb	r1, [r1]                             @ 080078E8
	add	r0, r12, r6, asr #14                   @ 080078EC
	ldrsb	r0, [r0]                             @ 080078F0
	add	r4, r4, #2                             @ 080078F4
	ldr	r2, [r11, #-0x38]                      @ 080078F8
	cmp	r4, #0xaf                              @ 080078FC
	ldr	r12, [r11, #-0x44]                     @ 08007900
	add	r7, r7, lr                             @ 08007904
	ldr	lr, [r11, #-0x34]                      @ 08007908
	add	r3, r2, r7, asr #14                    @ 0800790C
	add	r8, r8, r12                            @ 08007910
	add	r2, lr, r8, asr #14                    @ 08007914
	ldrsb	r3, [r3]                             @ 08007918
	add	r1, r1, r0                             @ 0800791C
	ldrsb	r2, [r2]                             @ 08007920
	add	r8, r8, r12                            @ 08007924
	ldr	r12, [r11, #-0x64]                     @ 08007928
	add	r3, r3, r2                             @ 0800792C
	ldr	r2, [r11, #-0x40]                      @ 08007930
	add	r1, r1, r3                             @ 08007934
	ldr	r3, [r11, #-0x48]                      @ 08007938
	asr	r1, r1, #2                             @ 0800793C
	strb	r1, [r5, r12]                         @ 08007940
	add	r10, r10, r2                           @ 08007944
	ldr	lr, [r11, #-0x4c]                      @ 08007948
	add	r7, r7, r3                             @ 0800794C
	add	r6, r6, lr                             @ 08007950
	ble	.L08007874                             @ 08007954
	ldr	r1, [r11, #-0x60]                      @ 08007958
	ldr	r2, [r11, #-0x2c]                      @ 0800795C
	ldr	r4, .Llit08007A30                      @ 08007960  =mcChan
	add	r3, r1, r2                             @ 08007964
	lsl	r12, r3, #3                            @ 08007968
	add	r5, r4, #0x3c                          @ 0800796C
	ldr	r3, [r5, r12]                          @ 08007970
	cmp	r10, r3                                @ 08007974  end test once per frame, after 176 samples: one-shots overrun by up to 176*step bytes
	blo	.L0800799C                             @ 08007978
	add	r3, r4, #0x1c                          @ 0800797C
	ldr	r1, [r3, r12]                          @ 08007980
	ldr	r3, .Llit08007A34                      @ 08007984  =mcSmpInstTable
	add	r2, r3, #8                             @ 08007988
	ldr	r3, [r2, r1, lsl #4]                   @ 0800798C  mcSmpInstTable[inst].flag
	cmp	r3, #1                                 @ 08007990
	movne	r10, #0                              @ 08007994  flag == 1: pos = -1 (one-shot); else pos = 0 (loop from the start)
	mvneq	r10, #0                              @ 08007998
.L0800799C:
	ldr	lr, [r11, #-0x54]                      @ 0800799C
	add	r3, lr, lr, lsl #3                     @ 080079A0
	lsl	r9, r3, #3                             @ 080079A4
	ldr	r2, [r5, r9]                           @ 080079A8
	cmp	r8, r2                                 @ 080079AC
	blo	.L080079D4                             @ 080079B0
	add	r3, r4, #0x1c                          @ 080079B4
	ldr	r1, [r3, r9]                           @ 080079B8
	ldr	r3, .Llit08007A34                      @ 080079BC  =mcSmpInstTable
	add	r2, r3, #8                             @ 080079C0
	ldr	r3, [r2, r1, lsl #4]                   @ 080079C4
	cmp	r3, #1                                 @ 080079C8
	movne	r8, #0                               @ 080079CC
	mvneq	r8, #0                               @ 080079D0
.L080079D4:
	ldr	lr, [r11, #-0x58]                      @ 080079D4
	add	r3, lr, lr, lsl #3                     @ 080079D8
	lsl	r0, r3, #3                             @ 080079DC
	ldr	r2, [r5, r0]                           @ 080079E0
	cmp	r7, r2                                 @ 080079E4
	blo	.L08007A0C                             @ 080079E8
	add	r3, r4, #0x1c                          @ 080079EC
	ldr	r1, [r3, r0]                           @ 080079F0
	ldr	r3, .Llit08007A34                      @ 080079F4  =mcSmpInstTable
	add	r2, r3, #8                             @ 080079F8
	ldr	r3, [r2, r1, lsl #4]                   @ 080079FC
	cmp	r3, #1                                 @ 08007A00
	movne	r7, #0                               @ 08007A04
	mvneq	r7, #0                               @ 08007A08
.L08007A0C:
	ldr	lr, [r11, #-0x5c]                      @ 08007A0C
	add	r3, lr, lr, lsl #3                     @ 08007A10
	lsl	lr, r3, #3                             @ 08007A14
	ldr	r2, [r5, lr]                           @ 08007A18
	cmp	r6, r2                                 @ 08007A1C
	blo	.L08007A5C                             @ 08007A20
	add	r3, r4, #0x1c                          @ 08007A24
	ldr	r1, [r3, lr]                           @ 08007A28
	b	.L08007A44                               @ 08007A2C
.Llit08007A30:
	.word	mcChan                         @ 08007A30  = 0x03007770
.Llit08007A34:
	.word	mcSmpInstTable                 @ 08007A34  = 0x083CBEEC
.Llit08007A38:
	.word	pcm_08346CF8+4                 @ 08007A38  = 0x08346CFC
.Llit08007A3C:
	.word	mcBufIndex                     @ 08007A3C  = 0x03006A98
.Llit08007A40:
	.word	mcMusicBuf                     @ 08007A40  = 0x03007410
.L08007A44:
	ldr	r3, .Llit08007A78                      @ 08007A44  =mcSmpInstTable
	add	r2, r3, #8                             @ 08007A48
	ldr	r3, [r2, r1, lsl #4]                   @ 08007A4C
	cmp	r3, #1                                 @ 08007A50
	movne	r6, #0                               @ 08007A54
	mvneq	r6, #0                               @ 08007A58
.L08007A5C:
	ldr	r1, .Llit08007A7C                      @ 08007A5C  =mcChan
	add	r3, r1, #0x38                          @ 08007A60
	str	r10, [r3, r12]                         @ 08007A64
	str	r8, [r3, r9]                           @ 08007A68
	str	r7, [r3, r0]                           @ 08007A6C
	str	r6, [r3, lr]                           @ 08007A70
	b	.L08007A80                               @ 08007A74
.Llit08007A78:
	.word	mcSmpInstTable                 @ 08007A78  = 0x083CBEEC
.Llit08007A7C:
	.word	mcChan                         @ 08007A7C  = 0x03007770
.L08007A80:
	ldmdb	r11, {r4, r5, r6, r7, r8, r9, r10, r11, sp, lr} @ 08007A80
	bx	lr                                      @ 08007A84
