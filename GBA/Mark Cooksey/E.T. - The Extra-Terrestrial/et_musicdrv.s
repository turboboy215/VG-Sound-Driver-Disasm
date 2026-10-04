@ ============================================================================
@ et_musicdrv.s -- Mark Cooksey's GBA music driver, as used in
@                  E.T.: The Extra-Terrestrial (GBA, NewKidCo / Universal, 2001)
@
@ Reconstructed from "E.T. - The Extra-Terrestrial (E) (M6).gba", ROM range
@ 0x080025EC-0x08003CE8 (5 884 bytes).  Assembling this file and linking it
@ with et_sound.ld reproduces that range byte for byte (make -f et_sound.mk).
@
@ The driver is C compiled by an early GCC for Thumb (the "adds rX, rY, #0"
@ register moves, "bl" used as a long branch inside mcUpdate, and the
@ push {..}/pop {r0}/bx r0 epilogues are all GCC 2.9x idioms).  There are no
@ symbols in the ROM; every name here was assigned during the analysis.
@
@ Lineage: this is a C port of Cooksey's Game Boy (Color) driver (compare the
@ Earthworm Jim: Menace 2 the Galaxy disassembly, EWJ2A.ASM).  The frequency
@ table, song-table layout, sequence command numbers ($61 stop, $62 jump,
@ $64 macro/pattern, $65 return, $66 conditional flag, $67 global pan,
@ $69 tempo), the tempo accumulator, the {value,delay} / {delay,semitone}
@ table layouts and the PSG SFX record {delay, NRx1, NRx2, NRx4, NRx3} all
@ carry over.  The GB dispatch table ($60-$6D) became if-chains here and
@ $63, $68 and $6A-$6D were dropped.
@
@ Channel numbering in comments is 1-6 (as in the reference doc):
@   ch1 square 1 (SOUND1)   ch2 square 2 (SOUND2)   ch3 wave (SOUND3)
@   ch4 noise (SOUND4)      ch5 DirectSound A       ch6 DirectSound B
@ In the code the loop counter runs 0-5.
@
@ Host integration (all in game code):
@   main:   mcSoundInit(); SfxInit();          (0x0800546A, 0x0800546E)
@   VBlank: SfxVBlank(); mcUpdateSamples(); mcUpdate();   (0x08001B1E..)
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
	.equ	REG_SOUNDBIAS, 0x04000088
	.equ	REG_WAVE_RAM, 0x04000090
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
	.equ	REG_TM0CNT, 0x04000100
	.equ	REG_TM1CNT, 0x04000104
	.equ	REG_TM2CNT, 0x04000108
	.equ	REG_TM3CNT, 0x0400010C
	.equ	REG_IME, 0x04000208
@ ---- literal constants
	.equ	TM_DSSFX_11K, 0x0080FA2F
	.equ	DMA_STOP_TRICK, 0x84400004
	.equ	DMA_FIFO_START_B, 0xB6400004
	.equ	DMA_FIFO_START_A, 0xBE400000
@ ---- driver / game RAM (IWRAM)
	.equ	mcPsgSfxCur, 0x03000000           @    4 B  last PSG SFX number passed to mcPlayPsgSfx
	.equ	mcStreamIndex, 0x03000004         @    4 B  stream player: entry in mcDsSfxTable
	.equ	mcDsSfxFrames, 0x03000008         @    8 B  DS SFX: frames left, [2]
	.equ	mcDsSfxAddr, 0x03000010           @    8 B  DS SFX: PCM start address, [2]
	.equ	mcStreamActive, 0x03000018        @    4 B  stream player running flag
	.equ	mcTempo, 0x0300001C               @    4 B  tempo: ticks per frame in 8.8 fixed point (0x100 = 1)
	.equ	mcPaused, 0x03000020              @    4 B  non-zero = sequencer frozen
	.equ	mcStreamPeriod, 0x03000024        @    4 B  stream player: timer period copied from table header
	.equ	mcTempoAcc, 0x03000028            @    4 B  tempo accumulator
	.equ	mcMasterPan, 0x0300002C           @    4 B  SOUNDCNT_L shadow (GB MasterPan): 7 at init, v<<8|0x77 after SEQ_PAN
	.equ	mcDurTable, 0x03000030            @    4 B  pointer to the current song's note-length table
	.equ	mcPsgSfx, 0x03000040              @   72 B  PSG SFX slots [6] x 12 bytes {ptr, index, timer} (4 used)
	.equ	mcDsSfxPending, 0x03000088        @    8 B  DS SFX: start request flag, [2]
	.equ	mcDsSfxLoopFrames, 0x03000090     @    8 B  DS SFX: loop length in frames (0 = one-shot), [2]
	.equ	mcChan, 0x030000A0                @  432 B  music channel state [6] x 0x48 bytes
	.equ	mcCondFlag, 0x03000250            @    4 B  conditional/end-of-song flag set by SEQ_CONDFLAG (GB LoopFlag); never read
	.equ	mcStreamParam, 0x03000254         @    4 B  stream parameter (written, never read)
	.equ	mcStreamOffset, 0x03000258        @    4 B  stream player: byte offset into current entry
	.equ	mcDsSfxIndex, 0x03000260          @    8 B  DS SFX: table index, [2]
	.equ	gSfx, 0x03002CB0                  @   20 B  WAV SFX state (see doc)
	.equ	gGame, 0x03002CE0                 @   32 B  game state struct (only +0x13/+0x14/+0x15 used here)
	.equ	gSfxDummySlot, 0x03002004         @    2 B  scratch halfword SfxStartWav returns when no channel is free
@ ---- music channel struct (0x48 bytes each, 6 channels)
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
@ ---- ROM data tables (see et_sound_data.s)
	.equ	mcSmpNoteTable, 0x08016790
	.equ	mcDsSfxTable, 0x0801A5C8
	.equ	mcSmpInstTable, 0x0801AB68
	.equ	mcPsgSfxMap, 0x0801AB78
	.equ	mcPsgSfxScripts, 0x0801B1C4
	.equ	mcFreqLo, 0x08026E34
	.equ	mcFreqHi, 0x08026E95
	.equ	mcSongTable, 0x08026EF8
	.equ	mcInstTable, 0x08027A74
	.equ	SfxTable, 0x080284FC
@ ---- libgcc
	.equ	__udivsi3, 0x080108A4

	.section .text.et_musicdrv, "ax", %progbits
	.balign 4
	@ linked at 0x080025EC by et_sound.ld

@ --------------------------------------------------------------------------
@ mcSoundInit  (0x080025EC)
@   Initialise sound hardware and all driver state (called once from main)
@   mcChan[0..5].active = 0
@   mcTempo = 0x100; mcTempoAcc = 0; mcMasterPan = 7; mcPaused = 0
@   wave RAM (both banks) = FF FF FF FF FF FF FF FF 00 00 00 00 00 00 00 00  (square)
@   SOUNDCNT_L = 0xFF77   all PSG to both sides, volume 7/7
@   SOUNDCNT_X = 0x008F   master enable
@   SOUNDCNT_H = 0xFB0E   PSG 100%, DSA/DSB 100%, both L+R, A=Timer0, B=Timer1, FIFO resets
@   SOUND3CNT_L = 0xC0    wave channel on, bank 1 playing
@   SOUND1CNT_L = 0x0008  sweep off
@   mcPsgSfx[0..5].ptr = 0; mcDsSfxPending[] = mcDsSfxLoopFrames[] = 0
@   mcStreamParam = 0x2B11; mcStreamOffset = 0
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcSoundInit
mcSoundInit:
	push	{r4, r5, r6, r7, lr}              @ 080025EC
	ldr	r2, .Llit080026C8                  @ 080025EE  =mcChan+CH_active
	movs	r1, #0                            @ 080025F0
	str	r1, [r2]                           @ 080025F2
	str	r1, [r2, #0x48]                    @ 080025F4
	adds	r0, r2, #0                        @ 080025F6
	adds	r0, #0x90                         @ 080025F8
	str	r1, [r0]                           @ 080025FA
	adds	r0, #0x48                         @ 080025FC
	str	r1, [r0]                           @ 080025FE
	movs	r3, #0x90                         @ 08002600
	lsls	r3, r3, #1                        @ 08002602
	adds	r0, r2, r3                        @ 08002604
	str	r1, [r0]                           @ 08002606
	adds	r3, #0x48                         @ 08002608
	adds	r0, r2, r3                        @ 0800260A
	str	r1, [r0]                           @ 0800260C
	ldr	r2, .Llit080026CC                  @ 0800260E  =mcTempo
	movs	r0, #0x80                         @ 08002610
	lsls	r0, r0, #1                        @ 08002612
	str	r0, [r2]                           @ 08002614
	ldr	r0, .Llit080026D0                  @ 08002616  =mcTempoAcc
	str	r1, [r0]                           @ 08002618
	ldr	r2, .Llit080026D4                  @ 0800261A  =mcMasterPan
	movs	r0, #7                            @ 0800261C
	str	r0, [r2]                           @ 0800261E
	ldr	r0, .Llit080026D8                  @ 08002620  =mcPaused
	str	r1, [r0]                           @ 08002622
	ldr	r3, .Llit080026DC                  @ 08002624  =REG_WAVE_RAM
	adds	r5, r2, #0                        @ 08002626
	ldr	r4, .Llit080026E0                  @ 08002628  =mcPsgSfx
	ldr	r6, .Llit080026E4                  @ 0800262A  =mcStreamParam
	ldr	r7, .Llit080026E8                  @ 0800262C  =mcStreamOffset
	ldr	r0, .Llit080026EC                  @ 0800262E  =0xFFFF
	adds	r2, r0, #0                        @ 08002630
	adds	r1, r3, #6                        @ 08002632
.L08002634:
	strh	r2, [r1]                          @ 08002634  wave RAM words 0-3 = 0xFFFF
	subs	r1, #2                            @ 08002636
	cmp	r1, r3                             @ 08002638
	bge	.L08002634                         @ 0800263A
	movs	r0, #0                            @ 0800263C
	adds	r2, r3, #0                        @ 0800263E
	adds	r2, #8                            @ 08002640
	movs	r1, #3                            @ 08002642
.L08002644:
	strh	r0, [r2]                          @ 08002644  wave RAM words 4-7 = 0
	adds	r2, #2                            @ 08002646
	subs	r1, #1                            @ 08002648
	cmp	r1, #0                             @ 0800264A
	bge	.L08002644                         @ 0800264C
	ldr	r2, .Llit080026F0                  @ 0800264E  =REG_SOUNDCNT_L
	ldr	r0, [r5]                           @ 08002650
	lsls	r1, r0, #4                        @ 08002652
	adds	r0, r0, r1                        @ 08002654
	movs	r1, #0xff                         @ 08002656
	lsls	r1, r1, #8                        @ 08002658
	adds	r0, r0, r1                        @ 0800265A
	strh	r0, [r2]                          @ 0800265C  SOUNDCNT_L = 7 | 7<<4 | 0xFF00 (mcMasterPan used as a volume here)
	ldr	r1, .Llit080026F4                  @ 0800265E  =REG_SOUNDCNT_X
	movs	r0, #0x8f                         @ 08002660
	strh	r0, [r1]                          @ 08002662  SOUNDCNT_X = 0x8F
	subs	r1, #2                            @ 08002664
	ldr	r2, .Llit080026F8                  @ 08002666  =0xFB0E
	adds	r0, r2, #0                        @ 08002668
	strh	r0, [r1]                          @ 0800266A  SOUNDCNT_H = 0xFB0E
	subs	r1, #0x12                         @ 0800266C
	movs	r0, #0xc0                         @ 0800266E
	strh	r0, [r1]                          @ 08002670  SOUND3CNT_L = 0xC0 -> now write the other wave bank
	ldr	r3, .Llit080026DC                  @ 08002672  =REG_WAVE_RAM
	ldr	r0, .Llit080026EC                  @ 08002674  =0xFFFF
	adds	r1, r0, #0                        @ 08002676
	adds	r0, r3, #6                        @ 08002678
.L0800267A:
	strh	r1, [r0]                          @ 0800267A
	subs	r0, #2                            @ 0800267C
	cmp	r0, r3                             @ 0800267E
	bge	.L0800267A                         @ 08002680
	movs	r2, #0                            @ 08002682
	adds	r0, r3, #0                        @ 08002684
	adds	r0, #8                            @ 08002686
	movs	r1, #3                            @ 08002688
.L0800268A:
	strh	r2, [r0]                          @ 0800268A
	adds	r0, #2                            @ 0800268C
	subs	r1, #1                            @ 0800268E
	cmp	r1, #0                             @ 08002690
	bge	.L0800268A                         @ 08002692
	movs	r1, #8                            @ 08002694
	ldr	r0, .Llit080026FC                  @ 08002696  =REG_SOUND1CNT_L
	strh	r1, [r0]                          @ 08002698  SOUND1CNT_L = 8 (sweep off)
	movs	r0, #0                            @ 0800269A
	str	r0, [r4]                           @ 0800269C
	str	r0, [r4, #0xc]                     @ 0800269E
	str	r0, [r4, #0x18]                    @ 080026A0
	str	r0, [r4, #0x24]                    @ 080026A2
	str	r0, [r4, #0x30]                    @ 080026A4
	str	r0, [r4, #0x3c]                    @ 080026A6
	ldr	r3, .Llit08002700                  @ 080026A8  =mcDsSfxLoopFrames
	ldr	r2, .Llit08002704                  @ 080026AA  =mcDsSfxPending
	movs	r1, #1                            @ 080026AC
.L080026AE:
	stm	r2!, {r0}                          @ 080026AE
	stm	r3!, {r0}                          @ 080026B0
	subs	r1, #1                            @ 080026B2
	cmp	r1, #0                             @ 080026B4
	bge	.L080026AE                         @ 080026B6
	ldr	r0, .Llit08002708                  @ 080026B8  =0x2B11
	str	r0, [r6]                           @ 080026BA
	movs	r0, #0                            @ 080026BC
	str	r0, [r7]                           @ 080026BE
	pop	{r4, r5, r6, r7}                   @ 080026C0
	pop	{r0}                               @ 080026C2
	bx	r0                                  @ 080026C4
	.hword	0x0000                          @ 080026C6  (padding)
.Llit080026C8:
	.word	mcChan+CH_active                 @ 080026C8  = 0x030000A0
.Llit080026CC:
	.word	mcTempo                          @ 080026CC  = 0x0300001C
.Llit080026D0:
	.word	mcTempoAcc                       @ 080026D0  = 0x03000028
.Llit080026D4:
	.word	mcMasterPan                      @ 080026D4  = 0x0300002C
.Llit080026D8:
	.word	mcPaused                         @ 080026D8  = 0x03000020
.Llit080026DC:
	.word	REG_WAVE_RAM                     @ 080026DC  = 0x04000090
.Llit080026E0:
	.word	mcPsgSfx                         @ 080026E0  = 0x03000040
.Llit080026E4:
	.word	mcStreamParam                    @ 080026E4  = 0x03000254
.Llit080026E8:
	.word	mcStreamOffset                   @ 080026E8  = 0x03000258
.Llit080026EC:
	.word	0x0000FFFF                       @ 080026EC
.Llit080026F0:
	.word	REG_SOUNDCNT_L                   @ 080026F0  = 0x04000080
.Llit080026F4:
	.word	REG_SOUNDCNT_X                   @ 080026F4  = 0x04000084
.Llit080026F8:
	.word	0x0000FB0E                       @ 080026F8
.Llit080026FC:
	.word	REG_SOUND1CNT_L                  @ 080026FC  = 0x04000060
.Llit08002700:
	.word	mcDsSfxLoopFrames                @ 08002700  = 0x03000090
.Llit08002704:
	.word	mcDsSfxPending                   @ 08002704  = 0x03000088
.Llit08002708:
	.word	0x00002B11                       @ 08002708

@ --------------------------------------------------------------------------
@ mcDsSfxStart  (0x0800270C)
@   Start a DirectSound one-shot/looped sample SFX (UNUSED in E.T.)
@   void mcDsSfxStart(int idx, int chan, int vol)
@     mcDsSfxIndex[chan] = idx
@     mcDsSfxAddr[chan]  = mcDsSfxTable[idx].addr
@     mcDsSfxFrames[chan] = mcDsSfxTable[idx].frames
@     mcDsSfxLoopFrames[chan] = mcDsSfxTable[idx].loopFrames
@     mcDsSfxPending[chan] = 1                      (started by mcUpdate)
@     SOUNDCNT_H bit 2 (chan 0) or bit 3 (chan 1) = vol   (DirectSound 50%/100%)
@   No callers, and mcDsSfxTable is all zeros in this ROM.
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcDsSfxStart
mcDsSfxStart:
	push	{r4, r5, r6, lr}                  @ 0800270C
	adds	r6, r2, #0                        @ 0800270E
	ldr	r2, .Llit08002758                  @ 08002710  =mcDsSfxIndex
	lsls	r4, r1, #2                        @ 08002712
	adds	r2, r4, r2                        @ 08002714
	str	r0, [r2]                           @ 08002716
	ldr	r3, .Llit0800275C                  @ 08002718  =mcDsSfxAddr
	adds	r3, r4, r3                        @ 0800271A
	ldr	r5, .Llit08002760                  @ 0800271C  =mcDsSfxTable
	lsls	r0, r0, #4                        @ 0800271E
	adds	r2, r0, r5                        @ 08002720
	ldr	r2, [r2]                           @ 08002722
	str	r2, [r3]                           @ 08002724
	ldr	r3, .Llit08002764                  @ 08002726  =mcDsSfxFrames
	adds	r3, r4, r3                        @ 08002728
	adds	r2, r5, #4                        @ 0800272A
	adds	r2, r0, r2                        @ 0800272C
	ldr	r2, [r2]                           @ 0800272E
	str	r2, [r3]                           @ 08002730
	ldr	r2, .Llit08002768                  @ 08002732  =mcDsSfxLoopFrames
	adds	r2, r4, r2                        @ 08002734
	adds	r5, #8                            @ 08002736
	adds	r0, r0, r5                        @ 08002738
	ldr	r0, [r0]                           @ 0800273A
	str	r0, [r2]                           @ 0800273C
	ldr	r0, .Llit0800276C                  @ 0800273E  =mcDsSfxPending
	adds	r4, r4, r0                        @ 08002740
	movs	r0, #1                            @ 08002742
	str	r0, [r4]                           @ 08002744
	cmp	r1, #0                             @ 08002746
	bne	.L08002778                         @ 08002748
	ldr	r2, .Llit08002770                  @ 0800274A  =REG_SOUNDCNT_H
	ldrh	r1, [r2]                          @ 0800274C
	ldr	r0, .Llit08002774                  @ 0800274E  =0xFFFB
	ands	r0, r1                            @ 08002750
	lsls	r1, r6, #2                        @ 08002752
	b	.L08002782                           @ 08002754
	.hword	0x0000                          @ 08002756  (padding)
.Llit08002758:
	.word	mcDsSfxIndex                     @ 08002758  = 0x03000260
.Llit0800275C:
	.word	mcDsSfxAddr                      @ 0800275C  = 0x03000010
.Llit08002760:
	.word	mcDsSfxTable                     @ 08002760  = 0x0801A5C8
.Llit08002764:
	.word	mcDsSfxFrames                    @ 08002764  = 0x03000008
.Llit08002768:
	.word	mcDsSfxLoopFrames                @ 08002768  = 0x03000090
.Llit0800276C:
	.word	mcDsSfxPending                   @ 0800276C  = 0x03000088
.Llit08002770:
	.word	REG_SOUNDCNT_H                   @ 08002770  = 0x04000082
.Llit08002774:
	.word	0x0000FFFB                       @ 08002774
.L08002778:
	ldr	r2, .Llit0800278C                  @ 08002778  =REG_SOUNDCNT_H
	ldrh	r1, [r2]                          @ 0800277A
	ldr	r0, .Llit08002790                  @ 0800277C  =0xFFF7
	ands	r0, r1                            @ 0800277E
	lsls	r1, r6, #3                        @ 08002780
.L08002782:
	orrs	r0, r1                            @ 08002782
	strh	r0, [r2]                          @ 08002784
	pop	{r4, r5, r6}                       @ 08002786
	pop	{r0}                               @ 08002788
	bx	r0                                  @ 0800278A
.Llit0800278C:
	.word	REG_SOUNDCNT_H                   @ 0800278C  = 0x04000082
.Llit08002790:
	.word	0x0000FFF7                       @ 08002790

@ --------------------------------------------------------------------------
@ mcPlaySong  (0x08002794)
@   Start song r0 on all six channels
@   void mcPlaySong(int song)
@     e = &mcSongTable[song]                        (28-byte entries, no bounds check)
@     for ch in 0..5:
@        seqPtr = e->seq[ch]; seqIdx = patPtr = patPos = ticks = 0
@        active = 1; owned = 1
@     mcDurTable = e->durTable
@   Tempo, panning and the pause flag are NOT reset; the song's first
@   sequence commands normally set them.
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcPlaySong
mcPlaySong:
	push	{r4, r5, lr}                      @ 08002794
	ldr	r1, .Llit080028AC                  @ 08002796  =mcChan+CH_active
	mov	ip, r1                             @ 08002798
	ldr	r5, .Llit080028B0                  @ 0800279A  =mcSongTable
	lsls	r4, r0, #3                        @ 0800279C  r4 = song * 28
	subs	r4, r4, r0                        @ 0800279E
	lsls	r4, r4, #2                        @ 080027A0
	adds	r0, r4, r5                        @ 080027A2
	ldr	r0, [r0]                           @ 080027A4
	str	r0, [r1, #0x20]                    @ 080027A6
	movs	r1, #0                            @ 080027A8
	mov	r2, ip                             @ 080027AA
	str	r1, [r2, #8]                       @ 080027AC
	str	r1, [r2, #0x24]                    @ 080027AE
	str	r1, [r2, #0xc]                     @ 080027B0
	str	r1, [r2, #0x10]                    @ 080027B2
	movs	r3, #1                            @ 080027B4
	str	r3, [r2]                           @ 080027B6
	str	r3, [r2, #4]                       @ 080027B8
	adds	r0, r5, #4                        @ 080027BA
	adds	r0, r4, r0                        @ 080027BC
	ldr	r0, [r0]                           @ 080027BE
	str	r0, [r2, #0x68]                    @ 080027C0
	str	r1, [r2, #0x50]                    @ 080027C2
	str	r1, [r2, #0x6c]                    @ 080027C4
	str	r1, [r2, #0x54]                    @ 080027C6
	str	r1, [r2, #0x58]                    @ 080027C8
	str	r3, [r2, #0x48]                    @ 080027CA
	str	r3, [r2, #0x4c]                    @ 080027CC
	adds	r2, #0xb0                         @ 080027CE
	adds	r0, r5, #0                        @ 080027D0
	adds	r0, #8                            @ 080027D2
	adds	r0, r4, r0                        @ 080027D4
	ldr	r0, [r0]                           @ 080027D6
	str	r0, [r2]                           @ 080027D8
	mov	r0, ip                             @ 080027DA
	adds	r0, #0x98                         @ 080027DC
	str	r1, [r0]                           @ 080027DE
	adds	r0, #0x1c                         @ 080027E0
	str	r1, [r0]                           @ 080027E2
	subs	r0, #0x18                         @ 080027E4
	str	r1, [r0]                           @ 080027E6
	adds	r0, #4                            @ 080027E8
	str	r1, [r0]                           @ 080027EA
	subs	r0, #0x10                         @ 080027EC
	str	r3, [r0]                           @ 080027EE
	adds	r0, #4                            @ 080027F0
	str	r3, [r0]                           @ 080027F2
	adds	r2, #0x48                         @ 080027F4
	adds	r0, r5, #0                        @ 080027F6
	adds	r0, #0xc                          @ 080027F8
	adds	r0, r4, r0                        @ 080027FA
	ldr	r0, [r0]                           @ 080027FC
	str	r0, [r2]                           @ 080027FE
	mov	r0, ip                             @ 08002800
	adds	r0, #0xe0                         @ 08002802
	str	r1, [r0]                           @ 08002804
	adds	r0, #0x1c                         @ 08002806
	str	r1, [r0]                           @ 08002808
	subs	r0, #0x18                         @ 0800280A
	str	r1, [r0]                           @ 0800280C
	adds	r0, #4                            @ 0800280E
	str	r1, [r0]                           @ 08002810
	subs	r0, #0x10                         @ 08002812
	str	r3, [r0]                           @ 08002814
	adds	r0, #4                            @ 08002816
	str	r3, [r0]                           @ 08002818
	movs	r2, #0xa0                         @ 0800281A
	lsls	r2, r2, #1                        @ 0800281C
	add	r2, ip                             @ 0800281E
	adds	r0, r5, #0                        @ 08002820
	adds	r0, #0x10                         @ 08002822
	adds	r0, r4, r0                        @ 08002824
	ldr	r0, [r0]                           @ 08002826
	str	r0, [r2]                           @ 08002828
	movs	r0, #0x94                         @ 0800282A
	lsls	r0, r0, #1                        @ 0800282C
	add	r0, ip                             @ 0800282E
	str	r1, [r0]                           @ 08002830
	movs	r0, #0xa2                         @ 08002832
	lsls	r0, r0, #1                        @ 08002834
	add	r0, ip                             @ 08002836
	str	r1, [r0]                           @ 08002838
	movs	r0, #0x96                         @ 0800283A
	lsls	r0, r0, #1                        @ 0800283C
	add	r0, ip                             @ 0800283E
	str	r1, [r0]                           @ 08002840
	movs	r0, #0x98                         @ 08002842
	lsls	r0, r0, #1                        @ 08002844
	add	r0, ip                             @ 08002846
	str	r1, [r0]                           @ 08002848
	movs	r0, #0x90                         @ 0800284A
	lsls	r0, r0, #1                        @ 0800284C
	add	r0, ip                             @ 0800284E
	str	r3, [r0]                           @ 08002850
	movs	r0, #0x92                         @ 08002852
	lsls	r0, r0, #1                        @ 08002854
	add	r0, ip                             @ 08002856
	str	r3, [r0]                           @ 08002858
	movs	r2, #0xc4                         @ 0800285A
	lsls	r2, r2, #1                        @ 0800285C
	add	r2, ip                             @ 0800285E
	adds	r0, r5, #0                        @ 08002860
	adds	r0, #0x14                         @ 08002862
	adds	r0, r4, r0                        @ 08002864
	ldr	r0, [r0]                           @ 08002866
	str	r0, [r2]                           @ 08002868
	movs	r0, #0xb8                         @ 0800286A
	lsls	r0, r0, #1                        @ 0800286C
	add	r0, ip                             @ 0800286E
	str	r1, [r0]                           @ 08002870
	movs	r0, #0xc6                         @ 08002872
	lsls	r0, r0, #1                        @ 08002874
	add	r0, ip                             @ 08002876
	str	r1, [r0]                           @ 08002878
	movs	r0, #0xba                         @ 0800287A
	lsls	r0, r0, #1                        @ 0800287C
	add	r0, ip                             @ 0800287E
	str	r1, [r0]                           @ 08002880
	movs	r0, #0xbc                         @ 08002882
	lsls	r0, r0, #1                        @ 08002884
	add	r0, ip                             @ 08002886
	str	r1, [r0]                           @ 08002888
	movs	r0, #0xb4                         @ 0800288A
	lsls	r0, r0, #1                        @ 0800288C
	add	r0, ip                             @ 0800288E
	str	r3, [r0]                           @ 08002890
	movs	r0, #0xb6                         @ 08002892
	lsls	r0, r0, #1                        @ 08002894
	add	r0, ip                             @ 08002896
	str	r3, [r0]                           @ 08002898
	ldr	r1, .Llit080028B4                  @ 0800289A  =mcDurTable
	adds	r0, r5, #0                        @ 0800289C
	adds	r0, #0x18                         @ 0800289E
	adds	r4, r4, r0                        @ 080028A0
	ldr	r0, [r4]                           @ 080028A2
	str	r0, [r1]                           @ 080028A4  mcDurTable = songtab[song].durTable
	pop	{r4, r5}                           @ 080028A6
	pop	{r0}                               @ 080028A8
	bx	r0                                  @ 080028AA
.Llit080028AC:
	.word	mcChan+CH_active                 @ 080028AC  = 0x030000A0
.Llit080028B0:
	.word	mcSongTable                      @ 080028B0  = 0x08026EF8
.Llit080028B4:
	.word	mcDurTable                       @ 080028B4  = 0x03000030

@ --------------------------------------------------------------------------
@ mcPlayPsgSfx  (0x080028B8)
@   Start a PSG register-script sound effect (UNUSED in E.T.)
@   void mcPlayPsgSfx(int n)
@     mcPsgSfxCur = n
@     for i in 0..3:
@        s = mcPsgSfxMap[n][i]; if (s == 0xFF) continue
@        p = mcPsgSfxScripts[s]; ch = *(u16*)p         (script header = PSG channel)
@        mcPsgSfx[ch] = { ptr = p + 2, index = -5, timer = 0 }
@        mcChan[ch].owned = 0                        (music stops writing that channel)
@   No callers in E.T.
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcPlayPsgSfx
mcPlayPsgSfx:
	push	{r4, r5, r6, r7, lr}              @ 080028B8
	mov	r7, sl                             @ 080028BA
	mov	r6, sb                             @ 080028BC
	mov	r5, r8                             @ 080028BE
	push	{r5, r6, r7}                      @ 080028C0
	adds	r5, r0, #0                        @ 080028C2
	ldr	r0, .Llit0800292C                  @ 080028C4  =mcPsgSfxCur
	str	r5, [r0]                           @ 080028C6
	movs	r4, #0                            @ 080028C8
	ldr	r0, .Llit08002930                  @ 080028CA  =mcPsgSfxMap
	mov	sl, r0                             @ 080028CC
	ldr	r0, .Llit08002934                  @ 080028CE  =mcPsgSfxScripts
	mov	sb, r0                             @ 080028D0
	ldr	r6, .Llit08002938                  @ 080028D2  =mcPsgSfx
	movs	r0, #8                            @ 080028D4
	adds	r0, r0, r6                        @ 080028D6
	mov	r8, r0                             @ 080028D8
	movs	r7, #0                            @ 080028DA
	ldr	r0, .Llit0800293C                  @ 080028DC  =mcChan+CH_owned
	mov	ip, r0                             @ 080028DE
.L080028E0:
	lsls	r0, r5, #2                        @ 080028E0
	adds	r0, r4, r0                        @ 080028E2
	add	r0, sl                             @ 080028E4
	ldrb	r0, [r0]                          @ 080028E6
	cmp	r0, #0xff                          @ 080028E8
	beq	.L08002918                         @ 080028EA
	lsls	r0, r0, #2                        @ 080028EC
	add	r0, sb                             @ 080028EE
	ldr	r2, [r0]                           @ 080028F0
	ldrh	r3, [r2]                          @ 080028F2
	adds	r2, #2                            @ 080028F4
	lsls	r0, r3, #1                        @ 080028F6
	adds	r0, r0, r3                        @ 080028F8
	lsls	r0, r0, #2                        @ 080028FA
	adds	r1, r0, r6                        @ 080028FC
	str	r2, [r1]                           @ 080028FE
	adds	r1, r6, #4                        @ 08002900
	adds	r1, r0, r1                        @ 08002902
	movs	r2, #5                            @ 08002904
	rsbs	r2, r2, #0                        @ 08002906
	str	r2, [r1]                           @ 08002908
	add	r0, r8                             @ 0800290A
	str	r7, [r0]                           @ 0800290C
	lsls	r0, r3, #3                        @ 0800290E
	adds	r0, r0, r3                        @ 08002910
	lsls	r0, r0, #3                        @ 08002912
	add	r0, ip                             @ 08002914
	str	r7, [r0]                           @ 08002916
.L08002918:
	adds	r4, #1                            @ 08002918
	cmp	r4, #3                             @ 0800291A
	ble	.L080028E0                         @ 0800291C
	pop	{r3, r4, r5}                       @ 0800291E
	mov	r8, r3                             @ 08002920
	mov	sb, r4                             @ 08002922
	mov	sl, r5                             @ 08002924
	pop	{r4, r5, r6, r7}                   @ 08002926
	pop	{r0}                               @ 08002928
	bx	r0                                  @ 0800292A
.Llit0800292C:
	.word	mcPsgSfxCur                      @ 0800292C  = 0x03000000
.Llit08002930:
	.word	mcPsgSfxMap                      @ 08002930  = 0x0801AB78
.Llit08002934:
	.word	mcPsgSfxScripts                  @ 08002934  = 0x0801B1C4
.Llit08002938:
	.word	mcPsgSfx                         @ 08002938  = 0x03000040
.Llit0800293C:
	.word	mcChan+CH_owned                  @ 0800293C  = 0x030000A4

@ --------------------------------------------------------------------------
@ mcPause  (0x08002940)
@   Freeze the sequencer and silence PSG channels not owned by an SFX
@   mcPaused = 1; for each PSG channel with no SFX running, zero its two
@   envelope/frequency registers (silences it).
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcPause
mcPause:
	ldr	r1, .Llit08002984                  @ 08002940  =mcPaused
	movs	r0, #1                            @ 08002942
	str	r0, [r1]                           @ 08002944
	ldr	r2, .Llit08002988                  @ 08002946  =mcPsgSfx
	ldr	r1, [r2]                           @ 08002948
	cmp	r1, #0                             @ 0800294A
	bne	.L08002956                         @ 0800294C
	ldr	r0, .Llit0800298C                  @ 0800294E  =REG_SOUND1CNT_H
	strh	r1, [r0]                          @ 08002950
	adds	r0, #2                            @ 08002952
	strh	r1, [r0]                          @ 08002954
.L08002956:
	ldr	r1, [r2, #0xc]                     @ 08002956
	cmp	r1, #0                             @ 08002958
	bne	.L08002964                         @ 0800295A
	ldr	r0, .Llit08002990                  @ 0800295C  =REG_SOUND2CNT_L
	strh	r1, [r0]                          @ 0800295E
	adds	r0, #4                            @ 08002960
	strh	r1, [r0]                          @ 08002962
.L08002964:
	ldr	r1, [r2, #0x18]                    @ 08002964
	cmp	r1, #0                             @ 08002966
	bne	.L08002972                         @ 08002968
	ldr	r0, .Llit08002994                  @ 0800296A  =REG_SOUND3CNT_H
	strh	r1, [r0]                          @ 0800296C
	adds	r0, #2                            @ 0800296E
	strh	r1, [r0]                          @ 08002970
.L08002972:
	ldr	r1, [r2, #0x24]                    @ 08002972
	cmp	r1, #0                             @ 08002974
	bne	.L08002980                         @ 08002976
	ldr	r0, .Llit08002998                  @ 08002978  =REG_SOUND4CNT_L
	strh	r1, [r0]                          @ 0800297A
	adds	r0, #4                            @ 0800297C
	strh	r1, [r0]                          @ 0800297E
.L08002980:
	bx	lr                                  @ 08002980
	.hword	0x0000                          @ 08002982  (padding)
.Llit08002984:
	.word	mcPaused                         @ 08002984  = 0x03000020
.Llit08002988:
	.word	mcPsgSfx                         @ 08002988  = 0x03000040
.Llit0800298C:
	.word	REG_SOUND1CNT_H                  @ 0800298C  = 0x04000062
.Llit08002990:
	.word	REG_SOUND2CNT_L                  @ 08002990  = 0x04000068
.Llit08002994:
	.word	REG_SOUND3CNT_H                  @ 08002994  = 0x04000072
.Llit08002998:
	.word	REG_SOUND4CNT_L                  @ 08002998  = 0x04000078

@ --------------------------------------------------------------------------
@ mcResume  (0x0800299C)
@   Un-freeze the sequencer
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcResume
mcResume:
	ldr	r1, .Llit080029A4                  @ 0800299C  =mcPaused
	movs	r0, #0                            @ 0800299E
	str	r0, [r1]                           @ 080029A0
	bx	lr                                  @ 080029A2
.Llit080029A4:
	.word	mcPaused                         @ 080029A4  = 0x03000020

@ --------------------------------------------------------------------------
@ mcDsSfxStop  (0x080029A8)
@   Stop DirectSound SFX channel r0 (UNUSED in E.T.)
@   void mcDsSfxStop(int chan): stop timer + DMA, clear pending and loop length.
@   Channel 1 path writes TM1CNT = 0; channel 0 path TM0CNT = 0.  No callers.
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcDsSfxStop
mcDsSfxStop:
	push	{r4, lr}                          @ 080029A8
	adds	r3, r0, #0                        @ 080029AA
	cmp	r3, #0                             @ 080029AC
	bne	.L080029E4                         @ 080029AE
	ldr	r0, .Llit080029D0                  @ 080029B0  =REG_TM0CNT
	str	r3, [r0]                           @ 080029B2
	ldr	r1, .Llit080029D4                  @ 080029B4  =REG_DMA1CNT
	ldr	r0, .Llit080029D8                  @ 080029B6  =DMA_STOP_TRICK
	str	r0, [r1]                           @ 080029B8
	ldr	r0, [r1]                           @ 080029BA
	adds	r1, #2                            @ 080029BC
	movs	r2, #0x88                         @ 080029BE
	lsls	r2, r2, #3                        @ 080029C0
	adds	r0, r2, #0                        @ 080029C2
	strh	r0, [r1]                          @ 080029C4
	ldr	r0, .Llit080029DC                  @ 080029C6  =mcDsSfxPending
	str	r3, [r0]                           @ 080029C8
	ldr	r0, .Llit080029E0                  @ 080029CA  =mcDsSfxLoopFrames
	str	r3, [r0]                           @ 080029CC
	b	.L08002A0A                           @ 080029CE
.Llit080029D0:
	.word	REG_TM0CNT                       @ 080029D0  = 0x04000100
.Llit080029D4:
	.word	REG_DMA1CNT                      @ 080029D4  = 0x040000C4
.Llit080029D8:
	.word	DMA_STOP_TRICK                   @ 080029D8  = 0x84400004
.Llit080029DC:
	.word	mcDsSfxPending                   @ 080029DC  = 0x03000088
.Llit080029E0:
	.word	mcDsSfxLoopFrames                @ 080029E0  = 0x03000090
.L080029E4:
	ldr	r0, .Llit08002A10                  @ 080029E4  =REG_TM1CNT
	movs	r2, #0                            @ 080029E6
	str	r2, [r0]                           @ 080029E8
	ldr	r1, .Llit08002A14                  @ 080029EA  =REG_DMA2CNT
	ldr	r0, .Llit08002A18                  @ 080029EC  =DMA_STOP_TRICK
	str	r0, [r1]                           @ 080029EE
	ldr	r0, [r1]                           @ 080029F0
	adds	r1, #2                            @ 080029F2
	movs	r4, #0x88                         @ 080029F4
	lsls	r4, r4, #3                        @ 080029F6
	adds	r0, r4, #0                        @ 080029F8
	strh	r0, [r1]                          @ 080029FA
	ldr	r0, .Llit08002A1C                  @ 080029FC  =mcDsSfxPending
	lsls	r1, r3, #2                        @ 080029FE
	adds	r0, r1, r0                        @ 08002A00
	str	r2, [r0]                           @ 08002A02
	ldr	r0, .Llit08002A20                  @ 08002A04  =mcDsSfxLoopFrames
	adds	r1, r1, r0                        @ 08002A06
	str	r2, [r1]                           @ 08002A08
.L08002A0A:
	pop	{r4}                               @ 08002A0A
	pop	{r0}                               @ 08002A0C
	bx	r0                                  @ 08002A0E
.Llit08002A10:
	.word	REG_TM1CNT                       @ 08002A10  = 0x04000104
.Llit08002A14:
	.word	REG_DMA2CNT                      @ 08002A14  = 0x040000D0
.Llit08002A18:
	.word	DMA_STOP_TRICK                   @ 08002A18  = 0x84400004
.Llit08002A1C:
	.word	mcDsSfxPending                   @ 08002A1C  = 0x03000088
.Llit08002A20:
	.word	mcDsSfxLoopFrames                @ 08002A20  = 0x03000090

@ --------------------------------------------------------------------------
@ mcStreamStart  (0x08002A24)
@   Start the looping "stream" sample player (UNUSED in E.T.)
@   void mcStreamStart(int idx, int param, int vol)
@     mcStreamIndex = idx; mcStreamParam = param; mcStreamOffset = 0
@     SOUNDCNT_H bit 2 = vol; mcStreamActive = 1
@   No callers.
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcStreamStart
mcStreamStart:
	ldr	r3, .Llit08002A48                  @ 08002A24  =mcStreamIndex
	str	r0, [r3]                           @ 08002A26
	ldr	r0, .Llit08002A4C                  @ 08002A28  =mcStreamParam
	str	r1, [r0]                           @ 08002A2A
	ldr	r1, .Llit08002A50                  @ 08002A2C  =mcStreamOffset
	movs	r0, #0                            @ 08002A2E
	str	r0, [r1]                           @ 08002A30
	ldr	r3, .Llit08002A54                  @ 08002A32  =REG_SOUNDCNT_H
	ldrh	r1, [r3]                          @ 08002A34
	ldr	r0, .Llit08002A58                  @ 08002A36  =0xFFFB
	ands	r0, r1                            @ 08002A38
	lsls	r2, r2, #2                        @ 08002A3A
	orrs	r0, r2                            @ 08002A3C
	strh	r0, [r3]                          @ 08002A3E
	ldr	r1, .Llit08002A5C                  @ 08002A40  =mcStreamActive
	movs	r0, #1                            @ 08002A42
	str	r0, [r1]                           @ 08002A44
	bx	lr                                  @ 08002A46
.Llit08002A48:
	.word	mcStreamIndex                    @ 08002A48  = 0x03000004
.Llit08002A4C:
	.word	mcStreamParam                    @ 08002A4C  = 0x03000254
.Llit08002A50:
	.word	mcStreamOffset                   @ 08002A50  = 0x03000258
.Llit08002A54:
	.word	REG_SOUNDCNT_H                   @ 08002A54  = 0x04000082
.Llit08002A58:
	.word	0x0000FFFB                       @ 08002A58
.Llit08002A5C:
	.word	mcStreamActive                   @ 08002A5C  = 0x03000018

@ --------------------------------------------------------------------------
@ mcStreamStop  (0x08002A60)
@   Stop the stream sample player (UNUSED in E.T.)
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcStreamStop
mcStreamStop:
	ldr	r0, .Llit08002A80                  @ 08002A60  =mcStreamActive
	movs	r1, #0                            @ 08002A62
	str	r1, [r0]                           @ 08002A64
	ldr	r0, .Llit08002A84                  @ 08002A66  =REG_TM0CNT
	str	r1, [r0]                           @ 08002A68
	ldr	r1, .Llit08002A88                  @ 08002A6A  =REG_DMA1CNT
	ldr	r0, .Llit08002A8C                  @ 08002A6C  =DMA_STOP_TRICK
	str	r0, [r1]                           @ 08002A6E
	ldr	r0, [r1]                           @ 08002A70
	adds	r1, #2                            @ 08002A72
	movs	r2, #0x88                         @ 08002A74
	lsls	r2, r2, #3                        @ 08002A76
	adds	r0, r2, #0                        @ 08002A78
	strh	r0, [r1]                          @ 08002A7A
	bx	lr                                  @ 08002A7C
	.hword	0x0000                          @ 08002A7E  (padding)
.Llit08002A80:
	.word	mcStreamActive                   @ 08002A80  = 0x03000018
.Llit08002A84:
	.word	REG_TM0CNT                       @ 08002A84  = 0x04000100
.Llit08002A88:
	.word	REG_DMA1CNT                      @ 08002A88  = 0x040000C4
.Llit08002A8C:
	.word	DMA_STOP_TRICK                   @ 08002A8C  = 0x84400004

@ --------------------------------------------------------------------------
@ mcStreamSetParam  (0x08002A90)
@   Store a stream parameter that nothing reads (UNUSED in E.T.)
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcStreamSetParam
mcStreamSetParam:
	ldr	r1, .Llit08002A98                  @ 08002A90  =mcStreamParam
	str	r0, [r1]                           @ 08002A92
	bx	lr                                  @ 08002A94
	.hword	0x0000                          @ 08002A96  (padding)
.Llit08002A98:
	.word	mcStreamParam                    @ 08002A98  = 0x03000254

@ --------------------------------------------------------------------------
@ mcUpdateSamples  (0x08002A9C)
@   Per-frame: re-trigger looping music samples on channels 5/6, feed the stream player
@   Part 1 -- music channels 5 and 6 (samples loop by re-triggering):
@     for ch in 4..5:
@       if (active == 1 && seqPtr && owned)
@         if (--smpFramesLeft <= 1)                 (CH_envIdx reused as a frame counter)
@            restart DMA from mcSmpInstTable[inst].addr at mcSmpNoteTable[note] rate
@            smpFramesLeft = smpFrameReload         (CH_envTimer reused)
@   Part 2 -- the "stream" player (never started in E.T.):
@     if (mcStreamActive)
@       period = mcDsSfxTable[0].word0; step = mcDsSfxTable[0].word1
@       e = &mcDsSfxTable[mcStreamIndex]
@       play from e->addr + mcStreamOffset at 16.78 MHz / period
@       mcStreamOffset += step; wrap at e->length / 2
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcUpdateSamples
mcUpdateSamples:
	push	{r4, r5, r6, r7, lr}              @ 08002A9C
	mov	r7, sl                             @ 08002A9E
	mov	r6, sb                             @ 08002AA0
	mov	r5, r8                             @ 08002AA2
	push	{r5, r6, r7}                      @ 08002AA4
	movs	r6, #4                            @ 08002AA6
	ldr	r4, .Llit08002C6C                  @ 08002AA8  =mcChan+CH_active
	adds	r5, r4, #0                        @ 08002AAA
	ldr	r0, .Llit08002C70                  @ 08002AAC  =REG_DMA1CNT
	mov	sl, r0                             @ 08002AAE
	ldr	r1, .Llit08002C74                  @ 08002AB0  =REG_DMA2CNT
	mov	sb, r1                             @ 08002AB2
	movs	r0, #0x90                         @ 08002AB4
	lsls	r0, r0, #1                        @ 08002AB6
	adds	r2, r4, r0                        @ 08002AB8
	mov	r8, r2                             @ 08002ABA
	adds	r7, r0, #0                        @ 08002ABC
	ldr	r0, .Llit08002C78                  @ 08002ABE  =REG_TM1CNT
	mov	ip, r0                             @ 08002AC0
mcUpdateSamples_loop:
	mov	r1, r8                             @ 08002AC2
	ldr	r0, [r1]                           @ 08002AC4
	cmp	r0, #1                             @ 08002AC6
	beq	.L08002ACC                         @ 08002AC8
	b	.L08002BD2                           @ 08002ACA
.L08002ACC:
	adds	r0, r4, #0                        @ 08002ACC
	adds	r0, #0x20                         @ 08002ACE
	adds	r0, r7, r0                        @ 08002AD0
	ldr	r0, [r0]                           @ 08002AD2
	cmp	r0, #0                             @ 08002AD4
	beq	.L08002BD2                         @ 08002AD6
	adds	r0, r5, #4                        @ 08002AD8
	adds	r0, r7, r0                        @ 08002ADA
	ldr	r0, [r0]                           @ 08002ADC
	cmp	r0, #0                             @ 08002ADE
	beq	.L08002BD2                         @ 08002AE0
	cmp	r6, #4                             @ 08002AE2
	bne	.L08002B58                         @ 08002AE4
	movs	r0, #0xa8                         @ 08002AE6
	lsls	r0, r0, #1                        @ 08002AE8
	adds	r2, r5, r0                        @ 08002AEA
	ldr	r0, [r2]                           @ 08002AEC
	subs	r0, #1                            @ 08002AEE  smpFramesLeft--
	str	r0, [r2]                           @ 08002AF0
	cmp	r0, #1                             @ 08002AF2
	bhi	.L08002B58                         @ 08002AF4  still > 1 frame left: nothing to do
	movs	r1, #0x9a                         @ 08002AF6
	lsls	r1, r1, #1                        @ 08002AF8
	adds	r0, r5, r1                        @ 08002AFA
	ldr	r1, [r0]                           @ 08002AFC
	lsls	r0, r1, #1                        @ 08002AFE
	adds	r0, r0, r1                        @ 08002B00
	lsls	r0, r0, #2                        @ 08002B02
	ldr	r1, .Llit08002C7C                  @ 08002B04  =mcSmpNoteTable+0x8
	adds	r0, r0, r1                        @ 08002B06
	ldr	r3, [r0]                           @ 08002B08
	ldr	r0, .Llit08002C80                  @ 08002B0A  =DMA_STOP_TRICK
	mov	r1, sl                             @ 08002B0C
	str	r0, [r1]                           @ 08002B0E  stop DMA1 (immediate 4-word dummy transfer)
	ldr	r0, [r1]                           @ 08002B10
	movs	r1, #0x88                         @ 08002B12
	lsls	r1, r1, #3                        @ 08002B14
	adds	r0, r1, #0                        @ 08002B16
	ldr	r1, .Llit08002C84                  @ 08002B18  =REG_DMA1CNT_H
	strh	r0, [r1]                          @ 08002B1A  DMA1CNT_H = 0x0440 (disabled)
	movs	r0, #0                            @ 08002B1C
	adds	r1, #0x3a                         @ 08002B1E
	str	r0, [r1]                           @ 08002B20  TM0CNT = 0
	movs	r1, #0x9e                         @ 08002B22
	lsls	r1, r1, #1                        @ 08002B24
	adds	r0, r5, r1                        @ 08002B26
	ldr	r0, [r0]                           @ 08002B28
	lsls	r0, r0, #3                        @ 08002B2A
	ldr	r1, .Llit08002C88                  @ 08002B2C  =mcSmpInstTable
	adds	r0, r0, r1                        @ 08002B2E
	ldr	r0, [r0]                           @ 08002B30
	ldr	r1, .Llit08002C8C                  @ 08002B32  =REG_DMA1SAD
	str	r0, [r1]                           @ 08002B34  DMA1SAD = sample address
	adds	r1, #4                            @ 08002B36
	ldr	r0, .Llit08002C90                  @ 08002B38  =REG_FIFO_A
	str	r0, [r1]                           @ 08002B3A  DMA1DAD = FIFO_A
	movs	r0, #0x80                         @ 08002B3C
	lsls	r0, r0, #9                        @ 08002B3E
	subs	r0, r0, r3                        @ 08002B40
	movs	r1, #0x80                         @ 08002B42
	lsls	r1, r1, #0x10                     @ 08002B44
	orrs	r0, r1                            @ 08002B46
	ldr	r1, .Llit08002C94                  @ 08002B48  =REG_TM0CNT
	str	r0, [r1]                           @ 08002B4A  TM0CNT = enable | (0x10000 - period)
	ldr	r0, .Llit08002C98                  @ 08002B4C  =DMA_FIFO_START_A
	mov	r1, sl                             @ 08002B4E
	str	r0, [r1]                           @ 08002B50  DMA1CNT = FIFO mode, start
	ldr	r1, .Llit08002C9C                  @ 08002B52  =mcChan+4*CHAN_SIZE+CH_envTimer
	ldr	r0, [r1]                           @ 08002B54
	str	r0, [r2]                           @ 08002B56  smpFramesLeft = smpFrameReload
.L08002B58:
	cmp	r6, #5                             @ 08002B58
	bne	.L08002BD2                         @ 08002B5A
	movs	r0, #0xcc                         @ 08002B5C
	lsls	r0, r0, #1                        @ 08002B5E
	adds	r2, r5, r0                        @ 08002B60
	ldr	r0, [r2]                           @ 08002B62
	subs	r0, #1                            @ 08002B64
	str	r0, [r2]                           @ 08002B66
	cmp	r0, #1                             @ 08002B68
	bhi	.L08002BD2                         @ 08002B6A
	movs	r1, #0xbe                         @ 08002B6C
	lsls	r1, r1, #1                        @ 08002B6E
	adds	r0, r4, r1                        @ 08002B70
	ldr	r1, [r0]                           @ 08002B72
	lsls	r0, r1, #1                        @ 08002B74
	adds	r0, r0, r1                        @ 08002B76
	lsls	r0, r0, #2                        @ 08002B78
	ldr	r1, .Llit08002C7C                  @ 08002B7A  =mcSmpNoteTable+0x8
	adds	r0, r0, r1                        @ 08002B7C
	ldr	r3, [r0]                           @ 08002B7E
	ldr	r0, .Llit08002C80                  @ 08002B80  =DMA_STOP_TRICK
	mov	r1, sb                             @ 08002B82
	str	r0, [r1]                           @ 08002B84
	ldr	r0, [r1]                           @ 08002B86
	movs	r1, #0x88                         @ 08002B88
	lsls	r1, r1, #3                        @ 08002B8A
	adds	r0, r1, #0                        @ 08002B8C
	ldr	r1, .Llit08002CA0                  @ 08002B8E  =REG_DMA2CNT_H
	strh	r0, [r1]                          @ 08002B90
	movs	r0, #0                            @ 08002B92
	mov	r1, ip                             @ 08002B94
	str	r0, [r1]                           @ 08002B96
	movs	r1, #0xc2                         @ 08002B98
	lsls	r1, r1, #1                        @ 08002B9A
	adds	r0, r4, r1                        @ 08002B9C
	ldr	r0, [r0]                           @ 08002B9E
	lsls	r0, r0, #3                        @ 08002BA0
	ldr	r1, .Llit08002C88                  @ 08002BA2  =mcSmpInstTable
	adds	r0, r0, r1                        @ 08002BA4
	ldr	r0, [r0]                           @ 08002BA6
	ldr	r1, .Llit08002CA4                  @ 08002BA8  =REG_DMA2SAD
	str	r0, [r1]                           @ 08002BAA
	adds	r1, #4                            @ 08002BAC
	ldr	r0, .Llit08002CA8                  @ 08002BAE  =REG_FIFO_B
	str	r0, [r1]                           @ 08002BB0
	movs	r0, #0x80                         @ 08002BB2
	lsls	r0, r0, #9                        @ 08002BB4
	subs	r0, r0, r3                        @ 08002BB6
	movs	r1, #0x80                         @ 08002BB8
	lsls	r1, r1, #0x10                     @ 08002BBA
	orrs	r0, r1                            @ 08002BBC
	mov	r1, ip                             @ 08002BBE
	str	r0, [r1]                           @ 08002BC0
	ldr	r0, .Llit08002C98                  @ 08002BC2  =DMA_FIFO_START_A
	mov	r1, sb                             @ 08002BC4
	str	r0, [r1]                           @ 08002BC6
	movs	r1, #0xce                         @ 08002BC8
	lsls	r1, r1, #1                        @ 08002BCA
	adds	r0, r4, r1                        @ 08002BCC
	ldr	r0, [r0]                           @ 08002BCE
	str	r0, [r2]                           @ 08002BD0
.L08002BD2:
	movs	r2, #0x48                         @ 08002BD2
	add	r8, r2                             @ 08002BD4
	adds	r7, #0x48                         @ 08002BD6
	adds	r6, #1                            @ 08002BD8
	cmp	r6, #5                             @ 08002BDA
	bgt	mcUpdateSamples_stream             @ 08002BDC
	b	mcUpdateSamples_loop                 @ 08002BDE
mcUpdateSamples_stream:
	ldr	r6, .Llit08002CAC                  @ 08002BE0  =mcStreamActive
	ldr	r0, [r6]                           @ 08002BE2
	cmp	r0, #0                             @ 08002BE4
	beq	.L08002C5E                         @ 08002BE6
	ldr	r0, .Llit08002CB0                  @ 08002BE8  =mcStreamPeriod
	ldr	r1, .Llit08002CB4                  @ 08002BEA  =mcDsSfxTable
	mov	sl, r1                             @ 08002BEC
	ldr	r2, [r1]                           @ 08002BEE
	mov	sb, r2                             @ 08002BF0
	str	r2, [r0]                           @ 08002BF2
	ldr	r5, .Llit08002CB8                  @ 08002BF4  =mcDsSfxTable
	ldr	r0, .Llit08002CBC                  @ 08002BF6  =mcStreamIndex
	ldr	r4, [r0]                           @ 08002BF8
	lsls	r4, r4, #4                        @ 08002BFA
	adds	r0, r4, r5                        @ 08002BFC
	ldr	r2, [r0]                           @ 08002BFE
	ldr	r7, .Llit08002CC0                  @ 08002C00  =mcStreamOffset
	ldr	r6, [r7]                           @ 08002C02
	mov	r8, r6                             @ 08002C04
	add	r2, r8                             @ 08002C06
	ldr	r0, .Llit08002C94                  @ 08002C08  =REG_TM0CNT
	mov	ip, r0                             @ 08002C0A
	movs	r0, #0                            @ 08002C0C
	mov	r1, ip                             @ 08002C0E
	str	r0, [r1]                           @ 08002C10
	ldr	r3, .Llit08002C70                  @ 08002C12  =REG_DMA1CNT
	ldr	r0, .Llit08002C80                  @ 08002C14  =DMA_STOP_TRICK
	str	r0, [r3]                           @ 08002C16
	ldr	r0, [r3]                           @ 08002C18
	ldr	r1, .Llit08002C84                  @ 08002C1A  =REG_DMA1CNT_H
	movs	r6, #0x88                         @ 08002C1C
	lsls	r6, r6, #3                        @ 08002C1E
	adds	r0, r6, #0                        @ 08002C20
	strh	r0, [r1]                          @ 08002C22
	ldr	r0, .Llit08002C8C                  @ 08002C24  =REG_DMA1SAD
	str	r2, [r0]                           @ 08002C26
	subs	r1, #6                            @ 08002C28
	subs	r0, #0x1c                         @ 08002C2A
	str	r0, [r1]                           @ 08002C2C
	movs	r0, #0x80                         @ 08002C2E
	lsls	r0, r0, #9                        @ 08002C30
	mov	r1, sb                             @ 08002C32
	subs	r0, r0, r1                        @ 08002C34
	movs	r1, #0x80                         @ 08002C36
	lsls	r1, r1, #0x10                     @ 08002C38
	orrs	r0, r1                            @ 08002C3A
	mov	r2, ip                             @ 08002C3C
	str	r0, [r2]                           @ 08002C3E
	ldr	r0, .Llit08002C98                  @ 08002C40  =DMA_FIFO_START_A
	str	r0, [r3]                           @ 08002C42
	mov	r6, sl                             @ 08002C44
	ldr	r0, [r6, #4]                       @ 08002C46
	mov	r2, r8                             @ 08002C48
	adds	r1, r2, r0                        @ 08002C4A
	str	r1, [r7]                           @ 08002C4C
	adds	r5, #0xc                          @ 08002C4E
	adds	r4, r4, r5                        @ 08002C50
	ldr	r0, [r4]                           @ 08002C52
	lsrs	r0, r0, #1                        @ 08002C54
	cmp	r1, r0                             @ 08002C56
	blo	.L08002C5E                         @ 08002C58
	subs	r0, r1, r0                        @ 08002C5A
	str	r0, [r7]                           @ 08002C5C
.L08002C5E:
	pop	{r3, r4, r5}                       @ 08002C5E
	mov	r8, r3                             @ 08002C60
	mov	sb, r4                             @ 08002C62
	mov	sl, r5                             @ 08002C64
	pop	{r4, r5, r6, r7}                   @ 08002C66
	pop	{r0}                               @ 08002C68
	bx	r0                                  @ 08002C6A
.Llit08002C6C:
	.word	mcChan+CH_active                 @ 08002C6C  = 0x030000A0
.Llit08002C70:
	.word	REG_DMA1CNT                      @ 08002C70  = 0x040000C4
.Llit08002C74:
	.word	REG_DMA2CNT                      @ 08002C74  = 0x040000D0
.Llit08002C78:
	.word	REG_TM1CNT                       @ 08002C78  = 0x04000104
.Llit08002C7C:
	.word	mcSmpNoteTable+0x8               @ 08002C7C  = 0x08016798
.Llit08002C80:
	.word	DMA_STOP_TRICK                   @ 08002C80  = 0x84400004
.Llit08002C84:
	.word	REG_DMA1CNT_H                    @ 08002C84  = 0x040000C6
.Llit08002C88:
	.word	mcSmpInstTable                   @ 08002C88  = 0x0801AB68
.Llit08002C8C:
	.word	REG_DMA1SAD                      @ 08002C8C  = 0x040000BC
.Llit08002C90:
	.word	REG_FIFO_A                       @ 08002C90  = 0x040000A0
.Llit08002C94:
	.word	REG_TM0CNT                       @ 08002C94  = 0x04000100
.Llit08002C98:
	.word	DMA_FIFO_START_A                 @ 08002C98  = 0xBE400000
.Llit08002C9C:
	.word	mcChan+4*CHAN_SIZE+CH_envTimer   @ 08002C9C  = 0x030001F4
.Llit08002CA0:
	.word	REG_DMA2CNT_H                    @ 08002CA0  = 0x040000D2
.Llit08002CA4:
	.word	REG_DMA2SAD                      @ 08002CA4  = 0x040000C8
.Llit08002CA8:
	.word	REG_FIFO_B                       @ 08002CA8  = 0x040000A4
.Llit08002CAC:
	.word	mcStreamActive                   @ 08002CAC  = 0x03000018
.Llit08002CB0:
	.word	mcStreamPeriod                   @ 08002CB0  = 0x03000024
.Llit08002CB4:
	.word	mcDsSfxTable                     @ 08002CB4  = 0x0801A5C8
.Llit08002CB8:
	.word	mcDsSfxTable                     @ 08002CB8  = 0x0801A5C8
.Llit08002CBC:
	.word	mcStreamIndex                    @ 08002CBC  = 0x03000004
.Llit08002CC0:
	.word	mcStreamOffset                   @ 08002CC0  = 0x03000258

@ --------------------------------------------------------------------------
@ mcUpdate  (0x08002CC4)
@   Per-frame: DirectSound SFX, PSG SFX scripts, tempo and the 6-channel sequencer
@   1. DirectSound SFX slots [0..1]     (mcDsSfx*, unused in E.T.)
@        frames countdown -> loop (restart, frames = loopFrames-1) or stop;
@        pending -> start at a fixed 0xFA2F timer reload (~11.27 kHz)
@   2. PSG SFX slots [0..3]             (mcPsgSfx, unused in E.T.)
@        each record = {frames, v1lo, v1hi, v2hi, v2lo}: after 'frames' frames
@        write v1 -> SOUNDnCNT_L/H and v2 -> SOUNDnCNT_X/H; 0xFF or 0xFE,0xFD
@        ends (registers zeroed, music gets the channel back); 0xFE,n loops
@   3. if (mcPaused) return
@   4. mcTempoAcc += mcTempo; if (mcTempoAcc <= 0xFF) return; mcTempoAcc -= 0x100
@      (so the sequencer ticks at most once per frame)
@   5. for ch in 0..5 (mcUpdate_seqChanLoop):
@        skip unless active == 1 and seqPtr != 0
@        if (ticks) { ticks--; if (owned) run the channel's table effects }
@        if (ticks == 0) {                               (mcUpdate_seqFetch)
@           if (!patPtr) read sequence commands until a SEQ_PAT or SEQ_END
@           read the next pattern event (mcUpdate_patFetch); 0x65 ends the
@           pattern (repeat or fall back to the sequence)
@           note-on: set note/freq/inst/ticks and write the channel registers
@        }
@   The body is fully unrolled per channel type, so the six channels share
@   the loop but each takes its own branch ("if (ch == 0) ... if (ch == 1)").
@ --------------------------------------------------------------------------
	.thumb_func
	.global mcUpdate
mcUpdate:
	push	{r4, r5, r6, r7, lr}              @ 08002CC4
	mov	r7, sl                             @ 08002CC6
	mov	r6, sb                             @ 08002CC8
	mov	r5, r8                             @ 08002CCA
	push	{r5, r6, r7}                      @ 08002CCC
	sub	sp, #0x30                          @ 08002CCE
	movs	r0, #0                            @ 08002CD0
	mov	sl, r0                             @ 08002CD2
	ldr	r1, .Llit08002D40                  @ 08002CD4  =mcPsgSfx
	str	r1, [sp, #0x20]                    @ 08002CD6
	ldr	r2, .Llit08002D44                  @ 08002CD8  =REG_TM0CNT
	mov	sb, r2                             @ 08002CDA
	ldr	r5, .Llit08002D48                  @ 08002CDC  =REG_DMA1CNT
	ldr	r3, .Llit08002D4C                  @ 08002CDE  =REG_TM1CNT
	mov	r8, r3                             @ 08002CE0
	ldr	r4, .Llit08002D50                  @ 08002CE2  =REG_DMA2CNT
	ldr	r7, .Llit08002D54                  @ 08002CE4  =mcDsSfxFrames
	movs	r6, #0                            @ 08002CE6
	ldr	r0, .Llit08002D58                  @ 08002CE8  =DMA_FIFO_START_A
	mov	ip, r0                             @ 08002CEA
mcUpdate_dsSfxLoop:
	ldr	r0, [r7]                           @ 08002CEC
	cmp	r0, #0                             @ 08002CEE
	beq	.L08002DDE                         @ 08002CF0  no SFX sample running on this slot
	subs	r0, #1                            @ 08002CF2
	str	r0, [r7]                           @ 08002CF4
	cmp	r0, #0                             @ 08002CF6
	bne	.L08002DDE                         @ 08002CF8
	ldr	r3, .Llit08002D5C                  @ 08002CFA  =mcDsSfxLoopFrames
	adds	r2, r6, r3                        @ 08002CFC
	ldr	r1, [r2]                           @ 08002CFE
	cmp	r1, #0                             @ 08002D00
	beq	.L08002DC8                         @ 08002D02  one-shot: stop
	mov	r1, sl                             @ 08002D04
	cmp	r1, #0                             @ 08002D06
	bne	.L08002D7C                         @ 08002D08
	mov	r2, sb                             @ 08002D0A
	str	r1, [r2]                           @ 08002D0C
	ldr	r0, .Llit08002D60                  @ 08002D0E  =DMA_STOP_TRICK
	str	r0, [r5]                           @ 08002D10
	ldr	r0, [r5]                           @ 08002D12
	ldr	r0, .Llit08002D64                  @ 08002D14  =REG_DMA1CNT_H
	movs	r1, #0x88                         @ 08002D16
	lsls	r1, r1, #3                        @ 08002D18
	strh	r1, [r0]                          @ 08002D1A
	ldr	r2, .Llit08002D68                  @ 08002D1C  =mcDsSfxAddr
	ldr	r0, [r2]                           @ 08002D1E
	ldr	r1, .Llit08002D6C                  @ 08002D20  =REG_DMA1SAD
	str	r0, [r1]                           @ 08002D22
	ldr	r0, .Llit08002D70                  @ 08002D24  =REG_FIFO_A
	ldr	r2, .Llit08002D74                  @ 08002D26  =REG_DMA1DAD
	str	r0, [r2]                           @ 08002D28
	ldr	r0, .Llit08002D78                  @ 08002D2A  =TM_DSSFX_11K
	mov	r1, sb                             @ 08002D2C
	str	r0, [r1]                           @ 08002D2E
	mov	r2, ip                             @ 08002D30
	str	r2, [r5]                           @ 08002D32
	ldr	r0, [r3]                           @ 08002D34
	subs	r0, #1                            @ 08002D36
	ldr	r3, .Llit08002D54                  @ 08002D38  =mcDsSfxFrames
	str	r0, [r3]                           @ 08002D3A  looped: frames = loopFrames - 1
	b	.L08002DDE                           @ 08002D3C
	.hword	0x0000                          @ 08002D3E  (padding)
.Llit08002D40:
	.word	mcPsgSfx                         @ 08002D40  = 0x03000040
.Llit08002D44:
	.word	REG_TM0CNT                       @ 08002D44  = 0x04000100
.Llit08002D48:
	.word	REG_DMA1CNT                      @ 08002D48  = 0x040000C4
.Llit08002D4C:
	.word	REG_TM1CNT                       @ 08002D4C  = 0x04000104
.Llit08002D50:
	.word	REG_DMA2CNT                      @ 08002D50  = 0x040000D0
.Llit08002D54:
	.word	mcDsSfxFrames                    @ 08002D54  = 0x03000008
.Llit08002D58:
	.word	DMA_FIFO_START_A                 @ 08002D58  = 0xBE400000
.Llit08002D5C:
	.word	mcDsSfxLoopFrames                @ 08002D5C  = 0x03000090
.Llit08002D60:
	.word	DMA_STOP_TRICK                   @ 08002D60  = 0x84400004
.Llit08002D64:
	.word	REG_DMA1CNT_H                    @ 08002D64  = 0x040000C6
.Llit08002D68:
	.word	mcDsSfxAddr                      @ 08002D68  = 0x03000010
.Llit08002D6C:
	.word	REG_DMA1SAD                      @ 08002D6C  = 0x040000BC
.Llit08002D70:
	.word	REG_FIFO_A                       @ 08002D70  = 0x040000A0
.Llit08002D74:
	.word	REG_DMA1DAD                      @ 08002D74  = 0x040000C0
.Llit08002D78:
	.word	TM_DSSFX_11K                     @ 08002D78  = 0x0080FA2F
.L08002D7C:
	mov	r1, r8                             @ 08002D7C
	str	r0, [r1]                           @ 08002D7E
	ldr	r3, .Llit08002DB0                  @ 08002D80  =DMA_STOP_TRICK
	str	r3, [r4]                           @ 08002D82
	ldr	r0, [r4]                           @ 08002D84
	ldr	r0, .Llit08002DB4                  @ 08002D86  =REG_DMA2CNT_H
	movs	r1, #0x88                         @ 08002D88
	lsls	r1, r1, #3                        @ 08002D8A
	strh	r1, [r0]                          @ 08002D8C
	ldr	r3, .Llit08002DB8                  @ 08002D8E  =mcDsSfxAddr
	adds	r0, r6, r3                        @ 08002D90
	ldr	r0, [r0]                           @ 08002D92
	ldr	r1, .Llit08002DBC                  @ 08002D94  =REG_DMA2SAD
	str	r0, [r1]                           @ 08002D96
	adds	r1, #4                            @ 08002D98
	ldr	r0, .Llit08002DC0                  @ 08002D9A  =REG_FIFO_B
	str	r0, [r1]                           @ 08002D9C
	ldr	r3, .Llit08002DC4                  @ 08002D9E  =TM_DSSFX_11K
	mov	r0, r8                             @ 08002DA0
	str	r3, [r0]                           @ 08002DA2
	mov	r1, ip                             @ 08002DA4
	str	r1, [r4]                           @ 08002DA6
	ldr	r0, [r2]                           @ 08002DA8
	subs	r0, #1                            @ 08002DAA
	str	r0, [r7]                           @ 08002DAC
	b	.L08002DDE                           @ 08002DAE
.Llit08002DB0:
	.word	DMA_STOP_TRICK                   @ 08002DB0  = 0x84400004
.Llit08002DB4:
	.word	REG_DMA2CNT_H                    @ 08002DB4  = 0x040000D2
.Llit08002DB8:
	.word	mcDsSfxAddr                      @ 08002DB8  = 0x03000010
.Llit08002DBC:
	.word	REG_DMA2SAD                      @ 08002DBC  = 0x040000C8
.Llit08002DC0:
	.word	REG_FIFO_B                       @ 08002DC0  = 0x040000A4
.Llit08002DC4:
	.word	TM_DSSFX_11K                     @ 08002DC4  = 0x0080FA2F
.L08002DC8:
	mov	r2, sl                             @ 08002DC8
	cmp	r2, #0                             @ 08002DCA
	bne	.L08002DD6                         @ 08002DCC
	mov	r3, sb                             @ 08002DCE
	str	r2, [r3]                           @ 08002DD0
	str	r2, [r5]                           @ 08002DD2
	b	.L08002DDE                           @ 08002DD4
.L08002DD6:
	movs	r0, #1                            @ 08002DD6
	mov	r2, r8                             @ 08002DD8
	str	r0, [r2]                           @ 08002DDA  TM1CNT = 1 (other slot writes 0)
	str	r1, [r4]                           @ 08002DDC
.L08002DDE:
	ldr	r3, .Llit08002E20                  @ 08002DDE  =mcDsSfxPending
	adds	r2, r6, r3                        @ 08002DE0
	ldr	r0, [r2]                           @ 08002DE2
	cmp	r0, #0                             @ 08002DE4
	beq	.L08002E72                         @ 08002DE6  start request pending?
	mov	r0, sl                             @ 08002DE8
	cmp	r0, #0                             @ 08002DEA
	bne	.L08002E40                         @ 08002DEC
	mov	r1, sb                             @ 08002DEE
	str	r0, [r1]                           @ 08002DF0
	ldr	r2, .Llit08002E24                  @ 08002DF2  =DMA_STOP_TRICK
	str	r2, [r5]                           @ 08002DF4
	ldr	r0, [r5]                           @ 08002DF6
	ldr	r0, .Llit08002E28                  @ 08002DF8  =REG_DMA1CNT_H
	movs	r3, #0x88                         @ 08002DFA
	lsls	r3, r3, #3                        @ 08002DFC
	strh	r3, [r0]                          @ 08002DFE
	ldr	r1, .Llit08002E2C                  @ 08002E00  =mcDsSfxAddr
	ldr	r0, [r1]                           @ 08002E02
	ldr	r2, .Llit08002E30                  @ 08002E04  =REG_DMA1SAD
	str	r0, [r2]                           @ 08002E06
	ldr	r0, .Llit08002E34                  @ 08002E08  =REG_FIFO_A
	ldr	r3, .Llit08002E38                  @ 08002E0A  =REG_DMA1DAD
	str	r0, [r3]                           @ 08002E0C
	ldr	r0, .Llit08002E3C                  @ 08002E0E  =TM_DSSFX_11K
	mov	r1, sb                             @ 08002E10
	str	r0, [r1]                           @ 08002E12
	mov	r2, ip                             @ 08002E14
	str	r2, [r5]                           @ 08002E16
	mov	r3, sl                             @ 08002E18
	ldr	r0, .Llit08002E20                  @ 08002E1A  =mcDsSfxPending
	str	r3, [r0]                           @ 08002E1C
	b	.L08002E72                           @ 08002E1E
.Llit08002E20:
	.word	mcDsSfxPending                   @ 08002E20  = 0x03000088
.Llit08002E24:
	.word	DMA_STOP_TRICK                   @ 08002E24  = 0x84400004
.Llit08002E28:
	.word	REG_DMA1CNT_H                    @ 08002E28  = 0x040000C6
.Llit08002E2C:
	.word	mcDsSfxAddr                      @ 08002E2C  = 0x03000010
.Llit08002E30:
	.word	REG_DMA1SAD                      @ 08002E30  = 0x040000BC
.Llit08002E34:
	.word	REG_FIFO_A                       @ 08002E34  = 0x040000A0
.Llit08002E38:
	.word	REG_DMA1DAD                      @ 08002E38  = 0x040000C0
.Llit08002E3C:
	.word	TM_DSSFX_11K                     @ 08002E3C  = 0x0080FA2F
.L08002E40:
	ldr	r1, .Llit08002ECC                  @ 08002E40  =DMA_STOP_TRICK
	str	r1, [r4]                           @ 08002E42
	ldr	r0, [r4]                           @ 08002E44
	ldr	r0, .Llit08002ED0                  @ 08002E46  =REG_DMA2CNT_H
	movs	r3, #0x88                         @ 08002E48
	lsls	r3, r3, #3                        @ 08002E4A
	strh	r3, [r0]                          @ 08002E4C
	movs	r0, #0                            @ 08002E4E
	mov	r1, r8                             @ 08002E50
	str	r0, [r1]                           @ 08002E52
	ldr	r3, .Llit08002ED4                  @ 08002E54  =mcDsSfxAddr
	adds	r0, r6, r3                        @ 08002E56
	ldr	r0, [r0]                           @ 08002E58
	ldr	r1, .Llit08002ED8                  @ 08002E5A  =REG_DMA2SAD
	str	r0, [r1]                           @ 08002E5C
	adds	r1, #4                            @ 08002E5E
	ldr	r0, .Llit08002EDC                  @ 08002E60  =REG_FIFO_B
	str	r0, [r1]                           @ 08002E62
	ldr	r3, .Llit08002EE0                  @ 08002E64  =TM_DSSFX_11K
	mov	r0, r8                             @ 08002E66
	str	r3, [r0]                           @ 08002E68
	mov	r1, ip                             @ 08002E6A
	str	r1, [r4]                           @ 08002E6C
	movs	r3, #0                            @ 08002E6E
	str	r3, [r2]                           @ 08002E70
.L08002E72:
	adds	r7, #4                            @ 08002E72
	adds	r6, #4                            @ 08002E74
	movs	r0, #1                            @ 08002E76
	add	sl, r0                             @ 08002E78
	mov	r1, sl                             @ 08002E7A
	cmp	r1, #1                             @ 08002E7C
	bgt	.L08002E82                         @ 08002E7E
	b	mcUpdate_dsSfxLoop                   @ 08002E80
.L08002E82:
	movs	r2, #0                            @ 08002E82
	mov	sl, r2                             @ 08002E84
	ldr	r1, .Llit08002EE4                  @ 08002E86  =mcPsgSfx
	ldr	r0, .Llit08002EE8                  @ 08002E88  =mcChan+CH_active
	adds	r0, #4                            @ 08002E8A
	mov	r8, r0                             @ 08002E8C
	adds	r7, r1, #4                        @ 08002E8E
	movs	r6, #0                            @ 08002E90
	adds	r5, r1, #0                        @ 08002E92
mcUpdate_psgSfxLoop:
	ldr	r4, [r5]                           @ 08002E94
	cmp	r4, #0                             @ 08002E96
	beq	.L08002F76                         @ 08002E98  no PSG SFX on this channel
	ldr	r0, [sp, #0x20]                    @ 08002E9A
	adds	r0, #8                            @ 08002E9C
	adds	r1, r6, r0                        @ 08002E9E
	ldr	r0, [r1]                           @ 08002EA0
	cmp	r0, #0                             @ 08002EA2
	beq	.L08002EAE                         @ 08002EA4
	subs	r0, #1                            @ 08002EA6
	str	r0, [r1]                           @ 08002EA8
	cmp	r0, #0                             @ 08002EAA
	bne	.L08002F76                         @ 08002EAC
.L08002EAE:
	ldr	r0, [r5, #4]                       @ 08002EAE
	adds	r0, #5                            @ 08002EB0  index += 5 halfwords (next record)
	str	r0, [r5, #4]                       @ 08002EB2
	movs	r2, #0                            @ 08002EB4
	lsls	r0, r0, #1                        @ 08002EB6
	adds	r0, r0, r4                        @ 08002EB8
	ldrh	r3, [r0]                          @ 08002EBA
	cmp	r3, #0xfe                          @ 08002EBC  0xFE = loop / end marker
	bne	.L08002EF2                         @ 08002EBE
	ldrh	r1, [r0, #2]                      @ 08002EC0
	cmp	r1, #0xfd                          @ 08002EC2  0xFE,0xFD = end
	bne	.L08002EEC                         @ 08002EC4
	movs	r2, #0xff                         @ 08002EC6
	b	.L08002EF2                           @ 08002EC8
	.hword	0x0000                          @ 08002ECA  (padding)
.Llit08002ECC:
	.word	DMA_STOP_TRICK                   @ 08002ECC  = 0x84400004
.Llit08002ED0:
	.word	REG_DMA2CNT_H                    @ 08002ED0  = 0x040000D2
.Llit08002ED4:
	.word	mcDsSfxAddr                      @ 08002ED4  = 0x03000010
.Llit08002ED8:
	.word	REG_DMA2SAD                      @ 08002ED8  = 0x040000C8
.Llit08002EDC:
	.word	REG_FIFO_B                       @ 08002EDC  = 0x040000A4
.Llit08002EE0:
	.word	TM_DSSFX_11K                     @ 08002EE0  = 0x0080FA2F
.Llit08002EE4:
	.word	mcPsgSfx                         @ 08002EE4  = 0x03000040
.Llit08002EE8:
	.word	mcChan+CH_active                 @ 08002EE8  = 0x030000A0
.L08002EEC:
	ldrh	r0, [r0, #2]                      @ 08002EEC
	subs	r0, #1                            @ 08002EEE
	str	r0, [r7]                           @ 08002EF0  0xFE,n: index = n-1 (from ptr = script+2)
.L08002EF2:
	ldr	r3, [sp, #0x20]                    @ 08002EF2
	ldr	r0, [r5, #4]                       @ 08002EF4
	lsls	r0, r0, #1                        @ 08002EF6
	adds	r1, r0, r4                        @ 08002EF8
	ldrh	r0, [r1]                          @ 08002EFA
	cmp	r0, #0xff                          @ 08002EFC  0xFF = end
	bne	.L08002F02                         @ 08002EFE
	movs	r2, #0xff                         @ 08002F00
.L08002F02:
	cmp	r2, #0xff                          @ 08002F02
	bne	.L08002F16                         @ 08002F04
	adds	r0, r6, r3                        @ 08002F06
	movs	r1, #0                            @ 08002F08
	str	r1, [r0]                           @ 08002F0A  end: slot.ptr = 0, registers <- 0
	movs	r2, #0                            @ 08002F0C
	movs	r0, #1                            @ 08002F0E
	mov	r3, r8                             @ 08002F10
	str	r0, [r3]                           @ 08002F12  mcChan[ch].owned = 1 (give channel back to music)
	b	.L08002F3E                           @ 08002F14
.L08002F16:
	ldr	r0, [sp, #0x20]                    @ 08002F16
	adds	r0, #8                            @ 08002F18
	adds	r0, r6, r0                        @ 08002F1A
	ldrh	r1, [r1]                          @ 08002F1C
	str	r1, [r0]                           @ 08002F1E  timer = frames
	ldr	r1, [r7]                           @ 08002F20
	lsls	r1, r1, #1                        @ 08002F22
	adds	r1, r1, r4                        @ 08002F24
	ldrh	r4, [r1, #4]                      @ 08002F26
	lsls	r0, r4, #8                        @ 08002F28
	ldrh	r2, [r1, #2]                      @ 08002F2A
	orrs	r0, r2                            @ 08002F2C
	lsls	r0, r0, #0x10                     @ 08002F2E
	lsrs	r2, r0, #0x10                     @ 08002F30
	ldrh	r3, [r1, #6]                      @ 08002F32
	lsls	r0, r3, #8                        @ 08002F34
	ldrh	r1, [r1, #8]                      @ 08002F36
	orrs	r0, r1                            @ 08002F38
	lsls	r0, r0, #0x10                     @ 08002F3A
	lsrs	r1, r0, #0x10                     @ 08002F3C
.L08002F3E:
	mov	r4, sl                             @ 08002F3E
	cmp	r4, #0                             @ 08002F40
	bne	.L08002F4C                         @ 08002F42
	ldr	r0, .Llit080032B8                  @ 08002F44  =REG_SOUND1CNT_H
	strh	r2, [r0]                          @ 08002F46
	adds	r0, #2                            @ 08002F48
	strh	r1, [r0]                          @ 08002F4A
.L08002F4C:
	mov	r0, sl                             @ 08002F4C
	cmp	r0, #1                             @ 08002F4E
	bne	.L08002F5A                         @ 08002F50
	ldr	r0, .Llit080032BC                  @ 08002F52  =REG_SOUND2CNT_L
	strh	r2, [r0]                          @ 08002F54
	adds	r0, #4                            @ 08002F56
	strh	r1, [r0]                          @ 08002F58
.L08002F5A:
	mov	r3, sl                             @ 08002F5A
	cmp	r3, #2                             @ 08002F5C
	bne	.L08002F68                         @ 08002F5E
	ldr	r0, .Llit080032C0                  @ 08002F60  =REG_SOUND3CNT_H
	strh	r2, [r0]                          @ 08002F62
	adds	r0, #2                            @ 08002F64
	strh	r1, [r0]                          @ 08002F66
.L08002F68:
	mov	r4, sl                             @ 08002F68
	cmp	r4, #3                             @ 08002F6A
	bne	.L08002F76                         @ 08002F6C
	ldr	r0, .Llit080032C4                  @ 08002F6E  =REG_SOUND4CNT_L
	strh	r2, [r0]                          @ 08002F70
	adds	r0, #4                            @ 08002F72
	strh	r1, [r0]                          @ 08002F74
.L08002F76:
	movs	r0, #0x48                         @ 08002F76
	add	r8, r0                             @ 08002F78
	adds	r7, #0xc                          @ 08002F7A
	adds	r6, #0xc                          @ 08002F7C
	adds	r5, #0xc                          @ 08002F7E
	movs	r1, #1                            @ 08002F80
	add	sl, r1                             @ 08002F82
	mov	r2, sl                             @ 08002F84
	cmp	r2, #3                             @ 08002F86
	ble	mcUpdate_psgSfxLoop                @ 08002F88
	ldr	r3, .Llit080032C8                  @ 08002F8A  =mcPaused
	ldr	r0, [r3]                           @ 08002F8C
	cmp	r0, #0                             @ 08002F8E
	beq	mcUpdate_tempo                     @ 08002F90  paused: skip the sequencer
	bl	mcUpdate_exit                       @ 08002F92
mcUpdate_tempo:
	ldr	r3, .Llit080032CC                  @ 08002F96  =mcTempoAcc
	ldr	r2, .Llit080032D0                  @ 08002F98  =mcTempo
	ldr	r1, [r3]                           @ 08002F9A
	ldr	r0, [r2]                           @ 08002F9C
	adds	r0, r1, r0                        @ 08002F9E
	str	r0, [r3]                           @ 08002FA0  mcTempoAcc += mcTempo
	cmp	r0, #0xff                          @ 08002FA2
	bhi	.L08002FAA                         @ 08002FA4  at least 0x100: run one tick
	bl	mcUpdate_exit                       @ 08002FA6
.L08002FAA:
	ldr	r4, .Llit080032D4                  @ 08002FAA  =0xFFFFFF00
	adds	r0, r0, r4                        @ 08002FAC
	str	r0, [r3]                           @ 08002FAE  mcTempoAcc -= 0x100
	movs	r5, #0                            @ 08002FB0
	mov	sl, r5                             @ 08002FB2
	ldr	r6, .Llit080032D8                  @ 08002FB4  =mcChan+CH_active
mcUpdate_seqChanLoop:
	mov	r7, sl                             @ 08002FB6
	lsls	r1, r7, #3                        @ 08002FB8
	adds	r0, r1, r7                        @ 08002FBA
	lsls	r2, r0, #3                        @ 08002FBC
	adds	r0, r2, r6                        @ 08002FBE
	ldr	r0, [r0]                           @ 08002FC0
	adds	r3, r7, #0                        @ 08002FC2
	adds	r3, #1                            @ 08002FC4
	str	r3, [sp, #0x24]                    @ 08002FC6
	str	r1, [sp, #0x28]                    @ 08002FC8
	cmp	r0, #1                             @ 08002FCA  active == 1 ?
	beq	.L08002FD2                         @ 08002FCC
	bl	mcUpdate_seqNextChan                @ 08002FCE
.L08002FD2:
	adds	r0, r6, #0                        @ 08002FD2
	adds	r0, #0x20                         @ 08002FD4
	adds	r0, r2, r0                        @ 08002FD6
	ldr	r0, [r0]                           @ 08002FD8
	cmp	r0, #0                             @ 08002FDA  seqPtr != 0 ?
	bne	mcUpdate_seqChanTop                @ 08002FDC
	bl	mcUpdate_seqNextChan                @ 08002FDE
mcUpdate_seqChanTop:
	ldr	r4, .Llit080032D8                  @ 08002FE2  =mcChan+CH_active
	str	r4, [sp, #4]                       @ 08002FE4
	ldr	r5, [sp, #0x28]                    @ 08002FE6
	add	r5, sl                             @ 08002FE8
	str	r5, [sp, #8]                       @ 08002FEA
	lsls	r7, r5, #3                        @ 08002FEC
	str	r7, [sp, #0xc]                     @ 08002FEE
	ldr	r0, .Llit080032DC                  @ 08002FF0  =mcChan+CH_ticks
	adds	r0, r7, r0                        @ 08002FF2
	str	r0, [sp, #0x10]                    @ 08002FF4
mcUpdate_seqChanRetry:
	movs	r1, #0x60                         @ 08002FF6
	str	r1, [sp]                           @ 08002FF8  [sp] = last pattern byte (0x60 default)
	ldr	r2, [sp, #0x10]                    @ 08002FFA
	ldr	r0, [r2]                           @ 08002FFC
	cmp	r0, #0                             @ 08002FFE
	bne	.L08003004                         @ 08003000
	b	mcUpdate_seqFetch                    @ 08003002
.L08003004:
	subs	r0, #1                            @ 08003004
	str	r0, [r2]                           @ 08003006  ticks--
	adds	r0, r6, #4                        @ 08003008
	ldr	r3, [sp, #0xc]                     @ 0800300A
	adds	r0, r3, r0                        @ 0800300C
	ldr	r0, [r0]                           @ 0800300E
	cmp	r0, #0                             @ 08003010  owned == 0 (an SFX has the channel): skip effects
	bne	.L08003016                         @ 08003012
	b	mcUpdate_fxDone                      @ 08003014
.L08003016:
	mov	r4, sl                             @ 08003016
	cmp	r4, #0                             @ 08003018
	beq	mcUpdate_fx_ch1                    @ 0800301A
	b	.L080031A8                           @ 0800301C
mcUpdate_fx_ch1:
	ldr	r5, [sp, #4]                       @ 0800301E
	ldr	r0, [r5, #0x1c]                    @ 08003020
	lsls	r0, r0, #2                        @ 08003022
	ldr	r7, .Llit080032E0                  @ 08003024  =mcInstTable
	adds	r0, r0, r7                        @ 08003026
	ldr	r7, [r0]                           @ 08003028
	ldr	r5, [r7, #0x20]                    @ 0800302A  arp table (inst+0x20)
	cmp	r5, #0                             @ 0800302C
	beq	.L0800309C                         @ 0800302E
	ldr	r1, [sp, #4]                       @ 08003030
	ldr	r0, [r1, #0x44]                    @ 08003032
	subs	r0, #1                            @ 08003034
	str	r0, [r1, #0x44]                    @ 08003036  arpTimer--
	cmp	r0, #0                             @ 08003038
	bne	.L0800309C                         @ 0800303A
	ldr	r0, [r1, #0x40]                    @ 0800303C
	adds	r0, #2                            @ 0800303E
	str	r0, [r1, #0x40]                    @ 08003040
	lsls	r0, r0, #1                        @ 08003042  arpIdx += 2
	adds	r0, r0, r5                        @ 08003044
	ldrh	r2, [r0]                          @ 08003046
	cmp	r2, #0xfe                          @ 08003048
	bne	.L08003052                         @ 0800304A  0xFE,n: arpIdx = n
	movs	r3, #2                            @ 0800304C
	ldrsh	r0, [r0, r3]                     @ 0800304E
	str	r0, [r1, #0x40]                    @ 08003050
.L08003052:
	ldr	r0, [sp, #4]                       @ 08003052
	ldr	r4, [r0, #0x40]                    @ 08003054
	lsls	r0, r4, #1                        @ 08003056
	adds	r3, r0, r5                        @ 08003058
	movs	r1, #0                            @ 0800305A
	ldrsh	r0, [r3, r1]                     @ 0800305C
	cmp	r0, #0xfd                          @ 0800305E
	bgt	.L08003090                         @ 08003060  > 0xFD: 0xFF hold
	ldr	r1, .Llit080032E4                  @ 08003062  =mcFreqHi
	movs	r5, #2                            @ 08003064
	ldrsh	r2, [r3, r5]                     @ 08003066
	ldr	r5, [sp, #4]                       @ 08003068
	ldr	r0, [r5, #0x14]                    @ 0800306A
	adds	r0, r0, r2                        @ 0800306C
	adds	r1, r0, r1                        @ 0800306E
	ldrb	r1, [r1]                          @ 08003070
	lsls	r2, r1, #8                        @ 08003072
	ldr	r1, .Llit080032E8                  @ 08003074  =mcFreqLo
	adds	r0, r0, r1                        @ 08003076
	ldrb	r0, [r0]                          @ 08003078
	orrs	r2, r0                            @ 0800307A
	str	r2, [r5, #0x18]                    @ 0800307C  freq = Freq[note + semitones]
	movs	r1, #0                            @ 0800307E
	ldrsh	r0, [r3, r1]                     @ 08003080
	str	r0, [r5, #0x44]                    @ 08003082  arpTimer = frames
	ldr	r0, [r7]                           @ 08003084
	lsls	r0, r0, #0x18                     @ 08003086
	lsrs	r0, r0, #0x10                     @ 08003088
	orrs	r0, r2                            @ 0800308A
	ldr	r1, .Llit080032EC                  @ 0800308C  =REG_SOUND1CNT_X
	strh	r0, [r1]                          @ 0800308E  SOUND1CNT_X = b0<<8 | freq  (no restart)
.L08003090:
	ldrh	r3, [r3]                          @ 08003090
	cmp	r3, #0xff                          @ 08003092
	bne	.L0800309C                         @ 08003094
	subs	r0, r4, #2                        @ 08003096  0xFF: step back so it is read again (hold)
	ldr	r2, [sp, #4]                       @ 08003098
	str	r0, [r2, #0x40]                    @ 0800309A
.L0800309C:
	ldr	r5, [r7, #0x18]                    @ 0800309C  pitch table (inst+0x18)
	cmp	r5, #0                             @ 0800309E
	beq	.L0800311C                         @ 080030A0
	ldr	r3, [sp, #8]                       @ 080030A2
	lsls	r3, r3, #3                        @ 080030A4
	mov	sb, r3                             @ 080030A6
	adds	r0, r6, #0                        @ 080030A8
	adds	r0, #0x3c                         @ 080030AA
	adds	r2, r3, r0                        @ 080030AC
	ldr	r0, [r2]                           @ 080030AE
	subs	r0, #1                            @ 080030B0
	str	r0, [r2]                           @ 080030B2
	cmp	r0, #0                             @ 080030B4
	bne	.L0800311C                         @ 080030B6
	adds	r0, r6, #0                        @ 080030B8
	adds	r0, #0x38                         @ 080030BA
	adds	r3, r3, r0                        @ 080030BC
	ldr	r0, [r3]                           @ 080030BE
	adds	r0, #2                            @ 080030C0
	str	r0, [r3]                           @ 080030C2
	lsls	r0, r0, #1                        @ 080030C4
	adds	r0, r0, r5                        @ 080030C6
	ldrh	r4, [r0]                          @ 080030C8
	cmp	r4, #0xfe                          @ 080030CA
	bne	.L080030D4                         @ 080030CC
	movs	r1, #2                            @ 080030CE
	ldrsh	r0, [r0, r1]                     @ 080030D0
	str	r0, [r3]                           @ 080030D2
.L080030D4:
	ldr	r0, [r3]                           @ 080030D4
	lsls	r0, r0, #1                        @ 080030D6
	adds	r1, r0, r5                        @ 080030D8
	movs	r0, #0                            @ 080030DA
	ldrsh	r4, [r1, r0]                     @ 080030DC
	cmp	r4, #0xfd                          @ 080030DE
	bgt	.L0800310C                         @ 080030E0
	movs	r4, #2                            @ 080030E2
	ldrsh	r1, [r1, r4]                     @ 080030E4
	str	r1, [r2]                           @ 080030E6
	adds	r1, r6, #0                        @ 080030E8
	adds	r1, #0x18                         @ 080030EA
	add	r1, sb                             @ 080030EC
	ldr	r2, [r1]                           @ 080030EE
	ldr	r0, [r3]                           @ 080030F0
	lsls	r0, r0, #1                        @ 080030F2
	adds	r0, r0, r5                        @ 080030F4
	movs	r4, #0                            @ 080030F6
	ldrsh	r0, [r0, r4]                     @ 080030F8
	adds	r2, r2, r0                        @ 080030FA
	str	r2, [r1]                           @ 080030FC  freq += delta
	lsls	r1, r2, #0x10                     @ 080030FE
	ldr	r0, [r7]                           @ 08003100
	lsls	r0, r0, #0x18                     @ 08003102
	orrs	r0, r1                            @ 08003104
	lsrs	r2, r0, #0x10                     @ 08003106
	ldr	r0, .Llit080032EC                  @ 08003108  =REG_SOUND1CNT_X
	strh	r2, [r0]                          @ 0800310A  SOUND1CNT_X = b0<<8 | freq
.L0800310C:
	ldr	r1, [r3]                           @ 0800310C
	lsls	r0, r1, #1                        @ 0800310E
	adds	r0, r0, r5                        @ 08003110
	ldrh	r0, [r0]                          @ 08003112
	cmp	r0, #0xff                          @ 08003114
	bne	.L0800311C                         @ 08003116
	subs	r0, r1, #2                        @ 08003118
	str	r0, [r3]                           @ 0800311A
.L0800311C:
	ldr	r5, [r7, #0x10]                    @ 0800311C  volume envelope table (inst+0x10)
	cmp	r5, #0                             @ 0800311E
	beq	.L080031A8                         @ 08003120
	ldr	r0, [sp, #8]                       @ 08003122
	lsls	r0, r0, #3                        @ 08003124
	mov	ip, r0                             @ 08003126
	adds	r0, r6, #0                        @ 08003128
	adds	r0, #0x34                         @ 0800312A
	mov	r1, ip                             @ 0800312C
	adds	r4, r1, r0                        @ 0800312E
	ldr	r0, [r4]                           @ 08003130
	subs	r0, #1                            @ 08003132
	str	r0, [r4]                           @ 08003134
	cmp	r0, #0                             @ 08003136
	bne	.L080031A8                         @ 08003138
	adds	r0, r6, #0                        @ 0800313A
	adds	r0, #0x30                         @ 0800313C
	adds	r3, r1, r0                        @ 0800313E
	ldr	r0, [r3]                           @ 08003140
	adds	r0, #2                            @ 08003142
	str	r0, [r3]                           @ 08003144
	lsls	r0, r0, #1                        @ 08003146
	adds	r0, r0, r5                        @ 08003148
	ldrh	r2, [r0]                          @ 0800314A
	cmp	r2, #0xfe                          @ 0800314C
	bne	.L08003156                         @ 0800314E
	movs	r1, #2                            @ 08003150
	ldrsh	r0, [r0, r1]                     @ 08003152
	str	r0, [r3]                           @ 08003154
.L08003156:
	ldr	r0, [r3]                           @ 08003156
	lsls	r0, r0, #1                        @ 08003158
	adds	r1, r0, r5                        @ 0800315A
	ldrh	r2, [r1]                          @ 0800315C
	mov	r8, r2                             @ 0800315E
	movs	r2, #0                            @ 08003160
	ldrsh	r0, [r1, r2]                     @ 08003162
	cmp	r0, #0xfd                          @ 08003164
	bgt	.L08003198                         @ 08003166
	mov	r2, r8                             @ 08003168
	lsls	r0, r2, #8                        @ 0800316A
	ldrh	r2, [r7, #4]                      @ 0800316C
	orrs	r0, r2                            @ 0800316E
	lsls	r0, r0, #0x10                     @ 08003170
	lsrs	r2, r0, #0x10                     @ 08003172
	ldr	r0, .Llit080032B8                  @ 08003174  =REG_SOUND1CNT_H
	strh	r2, [r0]                          @ 08003176  SOUND1CNT_H = value<<8 | inst.lo
	movs	r2, #2                            @ 08003178
	ldrsh	r0, [r1, r2]                     @ 0800317A
	str	r0, [r4]                           @ 0800317C
	ldr	r2, .Llit080032EC                  @ 0800317E  =REG_SOUND1CNT_X
	ldr	r1, [r7]                           @ 08003180
	lsls	r1, r1, #8                        @ 08003182
	adds	r0, r6, #0                        @ 08003184
	adds	r0, #0x18                         @ 08003186
	add	r0, ip                             @ 08003188
	ldr	r0, [r0]                           @ 0800318A
	orrs	r0, r1                            @ 0800318C
	movs	r4, #0x80                         @ 0800318E
	lsls	r4, r4, #8                        @ 08003190
	adds	r1, r4, #0                        @ 08003192
	orrs	r0, r1                            @ 08003194
	strh	r0, [r2]                          @ 08003196  SOUND1CNT_X = b0<<8 | freq | 0x8000 (restart)
.L08003198:
	ldr	r1, [r3]                           @ 08003198
	lsls	r0, r1, #1                        @ 0800319A
	adds	r0, r0, r5                        @ 0800319C
	ldrh	r0, [r0]                          @ 0800319E
	cmp	r0, #0xff                          @ 080031A0
	bne	.L080031A8                         @ 080031A2
	subs	r0, r1, #2                        @ 080031A4
	str	r0, [r3]                           @ 080031A6
.L080031A8:
	mov	r5, sl                             @ 080031A8
	cmp	r5, #1                             @ 080031AA
	beq	mcUpdate_fx_ch2                    @ 080031AC
	b	.L08003388                           @ 080031AE
mcUpdate_fx_ch2:
	ldr	r0, [r6, #0x64]                    @ 080031B0
	lsls	r0, r0, #2                        @ 080031B2
	ldr	r7, .Llit080032E0                  @ 080031B4  =mcInstTable
	adds	r0, r0, r7                        @ 080031B6
	ldr	r7, [r0]                           @ 080031B8
	ldr	r5, [r7, #0x20]                    @ 080031BA
	cmp	r5, #0                             @ 080031BC
	beq	.L0800323C                         @ 080031BE
	movs	r0, #0x8c                         @ 080031C0
	adds	r0, r0, r6                        @ 080031C2
	mov	r8, r0                             @ 080031C4
	ldr	r0, [r0]                           @ 080031C6
	subs	r0, #1                            @ 080031C8
	mov	r1, r8                             @ 080031CA
	str	r0, [r1]                           @ 080031CC
	cmp	r0, #0                             @ 080031CE
	bne	.L0800323C                         @ 080031D0
	movs	r2, #0x88                         @ 080031D2
	adds	r2, r2, r6                        @ 080031D4
	mov	ip, r2                             @ 080031D6
	ldr	r0, [r2]                           @ 080031D8
	adds	r0, #2                            @ 080031DA
	str	r0, [r2]                           @ 080031DC
	lsls	r0, r0, #1                        @ 080031DE
	adds	r0, r0, r5                        @ 080031E0
	ldrh	r3, [r0]                          @ 080031E2
	cmp	r3, #0xfe                          @ 080031E4
	bne	.L080031EE                         @ 080031E6
	movs	r4, #2                            @ 080031E8
	ldrsh	r0, [r0, r4]                     @ 080031EA
	str	r0, [r2]                           @ 080031EC
.L080031EE:
	mov	r0, ip                             @ 080031EE
	ldr	r4, [r0]                           @ 080031F0
	lsls	r0, r4, #1                        @ 080031F2
	adds	r3, r0, r5                        @ 080031F4
	movs	r1, #0                            @ 080031F6
	ldrsh	r0, [r3, r1]                     @ 080031F8
	cmp	r0, #0xfd                          @ 080031FA
	bgt	.L08003230                         @ 080031FC
	ldr	r1, .Llit080032E4                  @ 080031FE  =mcFreqHi
	movs	r5, #2                            @ 08003200
	ldrsh	r2, [r3, r5]                     @ 08003202
	ldr	r0, [r6, #0x5c]                    @ 08003204
	adds	r0, r0, r2                        @ 08003206
	adds	r1, r0, r1                        @ 08003208
	ldrb	r1, [r1]                          @ 0800320A
	lsls	r2, r1, #8                        @ 0800320C
	ldr	r1, .Llit080032E8                  @ 0800320E  =mcFreqLo
	adds	r0, r0, r1                        @ 08003210
	ldrb	r0, [r0]                          @ 08003212
	orrs	r2, r0                            @ 08003214
	str	r2, [r6, #0x60]                    @ 08003216
	movs	r1, #0                            @ 08003218
	ldrsh	r0, [r3, r1]                     @ 0800321A
	mov	r2, r8                             @ 0800321C
	str	r0, [r2]                           @ 0800321E
	ldr	r1, [r6, #0x60]                    @ 08003220
	lsls	r1, r1, #0x10                     @ 08003222
	ldr	r0, [r7]                           @ 08003224
	lsls	r0, r0, #0x18                     @ 08003226
	orrs	r0, r1                            @ 08003228
	lsrs	r2, r0, #0x10                     @ 0800322A
	ldr	r0, .Llit080032F0                  @ 0800322C  =REG_SOUND2CNT_H
	strh	r2, [r0]                          @ 0800322E
.L08003230:
	ldrh	r3, [r3]                          @ 08003230
	cmp	r3, #0xff                          @ 08003232
	bne	.L0800323C                         @ 08003234
	subs	r0, r4, #2                        @ 08003236
	mov	r3, ip                             @ 08003238
	str	r0, [r3]                           @ 0800323A
.L0800323C:
	ldr	r5, [r7, #0x18]                    @ 0800323C
	cmp	r5, #0                             @ 0800323E
	beq	.L080032FC                         @ 08003240
	ldr	r4, [sp, #8]                       @ 08003242
	lsls	r4, r4, #3                        @ 08003244
	mov	sb, r4                             @ 08003246
	adds	r0, r6, #0                        @ 08003248
	adds	r0, #0x3c                         @ 0800324A
	adds	r2, r4, r0                        @ 0800324C
	ldr	r0, [r2]                           @ 0800324E
	subs	r0, #1                            @ 08003250
	str	r0, [r2]                           @ 08003252
	cmp	r0, #0                             @ 08003254
	bne	.L080032FC                         @ 08003256
	adds	r0, r6, #0                        @ 08003258
	adds	r0, #0x38                         @ 0800325A
	adds	r3, r4, r0                        @ 0800325C
	ldr	r0, [r3]                           @ 0800325E
	adds	r0, #2                            @ 08003260
	str	r0, [r3]                           @ 08003262
	lsls	r0, r0, #1                        @ 08003264
	adds	r0, r0, r5                        @ 08003266
	ldrh	r1, [r0]                          @ 08003268
	cmp	r1, #0xfe                          @ 0800326A
	bne	.L08003274                         @ 0800326C
	movs	r4, #2                            @ 0800326E
	ldrsh	r0, [r0, r4]                     @ 08003270
	str	r0, [r3]                           @ 08003272
.L08003274:
	ldr	r0, [r3]                           @ 08003274
	lsls	r0, r0, #1                        @ 08003276
	adds	r1, r0, r5                        @ 08003278
	movs	r4, #0                            @ 0800327A
	ldrsh	r0, [r1, r4]                     @ 0800327C
	cmp	r0, #0xfd                          @ 0800327E
	bgt	.L080032AC                         @ 08003280
	movs	r0, #2                            @ 08003282
	ldrsh	r1, [r1, r0]                     @ 08003284
	str	r1, [r2]                           @ 08003286
	adds	r1, r6, #0                        @ 08003288
	adds	r1, #0x18                         @ 0800328A
	add	r1, sb                             @ 0800328C
	ldr	r2, [r1]                           @ 0800328E
	ldr	r0, [r3]                           @ 08003290
	lsls	r0, r0, #1                        @ 08003292
	adds	r0, r0, r5                        @ 08003294
	movs	r4, #0                            @ 08003296
	ldrsh	r0, [r0, r4]                     @ 08003298
	adds	r2, r2, r0                        @ 0800329A
	str	r2, [r1]                           @ 0800329C
	lsls	r1, r2, #0x10                     @ 0800329E
	ldr	r0, [r7]                           @ 080032A0
	lsls	r0, r0, #0x18                     @ 080032A2
	orrs	r0, r1                            @ 080032A4
	lsrs	r2, r0, #0x10                     @ 080032A6
	ldr	r0, .Llit080032F0                  @ 080032A8  =REG_SOUND2CNT_H
	strh	r2, [r0]                          @ 080032AA
.L080032AC:
	ldr	r1, [r3]                           @ 080032AC
	lsls	r0, r1, #1                        @ 080032AE
	adds	r0, r0, r5                        @ 080032B0
	ldrh	r0, [r0]                          @ 080032B2
	b	.L080032F4                           @ 080032B4
	.hword	0x0000                          @ 080032B6  (padding)
.Llit080032B8:
	.word	REG_SOUND1CNT_H                  @ 080032B8  = 0x04000062
.Llit080032BC:
	.word	REG_SOUND2CNT_L                  @ 080032BC  = 0x04000068
.Llit080032C0:
	.word	REG_SOUND3CNT_H                  @ 080032C0  = 0x04000072
.Llit080032C4:
	.word	REG_SOUND4CNT_L                  @ 080032C4  = 0x04000078
.Llit080032C8:
	.word	mcPaused                         @ 080032C8  = 0x03000020
.Llit080032CC:
	.word	mcTempoAcc                       @ 080032CC  = 0x03000028
.Llit080032D0:
	.word	mcTempo                          @ 080032D0  = 0x0300001C
.Llit080032D4:
	.word	0xFFFFFF00                       @ 080032D4
.Llit080032D8:
	.word	mcChan+CH_active                 @ 080032D8  = 0x030000A0
.Llit080032DC:
	.word	mcChan+CH_ticks                  @ 080032DC  = 0x030000B0
.Llit080032E0:
	.word	mcInstTable                      @ 080032E0  = 0x08027A74
.Llit080032E4:
	.word	mcFreqHi                         @ 080032E4  = 0x08026E95
.Llit080032E8:
	.word	mcFreqLo                         @ 080032E8  = 0x08026E34
.Llit080032EC:
	.word	REG_SOUND1CNT_X                  @ 080032EC  = 0x04000064
.Llit080032F0:
	.word	REG_SOUND2CNT_H                  @ 080032F0  = 0x0400006C
.L080032F4:
	cmp	r0, #0xff                          @ 080032F4
	bne	.L080032FC                         @ 080032F6
	subs	r0, r1, #2                        @ 080032F8
	str	r0, [r3]                           @ 080032FA
.L080032FC:
	ldr	r5, [r7, #0x10]                    @ 080032FC
	cmp	r5, #0                             @ 080032FE
	beq	.L08003388                         @ 08003300
	ldr	r0, [sp, #8]                       @ 08003302
	lsls	r0, r0, #3                        @ 08003304
	mov	ip, r0                             @ 08003306
	adds	r0, r6, #0                        @ 08003308
	adds	r0, #0x34                         @ 0800330A
	mov	r1, ip                             @ 0800330C
	adds	r4, r1, r0                        @ 0800330E
	ldr	r0, [r4]                           @ 08003310
	subs	r0, #1                            @ 08003312
	str	r0, [r4]                           @ 08003314
	cmp	r0, #0                             @ 08003316
	bne	.L08003388                         @ 08003318
	adds	r0, r6, #0                        @ 0800331A
	adds	r0, #0x30                         @ 0800331C
	adds	r3, r1, r0                        @ 0800331E
	ldr	r0, [r3]                           @ 08003320
	adds	r0, #2                            @ 08003322
	str	r0, [r3]                           @ 08003324
	lsls	r0, r0, #1                        @ 08003326
	adds	r0, r0, r5                        @ 08003328
	ldrh	r2, [r0]                          @ 0800332A
	cmp	r2, #0xfe                          @ 0800332C
	bne	.L08003336                         @ 0800332E
	movs	r1, #2                            @ 08003330
	ldrsh	r0, [r0, r1]                     @ 08003332
	str	r0, [r3]                           @ 08003334
.L08003336:
	ldr	r0, [r3]                           @ 08003336
	lsls	r0, r0, #1                        @ 08003338
	adds	r1, r0, r5                        @ 0800333A
	ldrh	r2, [r1]                          @ 0800333C
	mov	r8, r2                             @ 0800333E
	movs	r2, #0                            @ 08003340
	ldrsh	r0, [r1, r2]                     @ 08003342
	cmp	r0, #0xfd                          @ 08003344
	bgt	.L08003378                         @ 08003346
	mov	r2, r8                             @ 08003348
	lsls	r0, r2, #8                        @ 0800334A
	ldrh	r2, [r7, #4]                      @ 0800334C
	orrs	r0, r2                            @ 0800334E
	lsls	r0, r0, #0x10                     @ 08003350
	lsrs	r2, r0, #0x10                     @ 08003352
	ldr	r0, .Llit0800357C                  @ 08003354  =REG_SOUND2CNT_L
	strh	r2, [r0]                          @ 08003356
	movs	r2, #2                            @ 08003358
	ldrsh	r0, [r1, r2]                     @ 0800335A
	str	r0, [r4]                           @ 0800335C
	ldr	r2, .Llit08003580                  @ 0800335E  =REG_SOUND2CNT_H
	ldr	r1, [r7]                           @ 08003360
	lsls	r1, r1, #8                        @ 08003362
	adds	r0, r6, #0                        @ 08003364
	adds	r0, #0x18                         @ 08003366
	add	r0, ip                             @ 08003368
	ldr	r0, [r0]                           @ 0800336A
	orrs	r0, r1                            @ 0800336C
	movs	r4, #0x80                         @ 0800336E
	lsls	r4, r4, #8                        @ 08003370
	adds	r1, r4, #0                        @ 08003372
	orrs	r0, r1                            @ 08003374
	strh	r0, [r2]                          @ 08003376
.L08003378:
	ldr	r1, [r3]                           @ 08003378
	lsls	r0, r1, #1                        @ 0800337A
	adds	r0, r0, r5                        @ 0800337C
	ldrh	r0, [r0]                          @ 0800337E
	cmp	r0, #0xff                          @ 08003380
	bne	.L08003388                         @ 08003382
	subs	r0, r1, #2                        @ 08003384
	str	r0, [r3]                           @ 08003386
.L08003388:
	mov	r5, sl                             @ 08003388
	cmp	r5, #2                             @ 0800338A
	beq	mcUpdate_fx_ch3                    @ 0800338C
	b	.L08003536                           @ 0800338E
mcUpdate_fx_ch3:
	adds	r0, r6, #0                        @ 08003390
	adds	r0, #0xac                         @ 08003392
	ldr	r0, [r0]                           @ 08003394
	lsls	r0, r0, #2                        @ 08003396
	ldr	r7, .Llit08003584                  @ 08003398  =mcInstTable
	adds	r0, r0, r7                        @ 0800339A
	ldr	r7, [r0]                           @ 0800339C
	ldr	r5, [r7, #0x20]                    @ 0800339E
	cmp	r5, #0                             @ 080033A0
	beq	.L08003428                         @ 080033A2
	movs	r0, #0xd4                         @ 080033A4
	adds	r0, r0, r6                        @ 080033A6
	mov	sb, r0                             @ 080033A8
	ldr	r0, [r0]                           @ 080033AA
	subs	r0, #1                            @ 080033AC
	mov	r1, sb                             @ 080033AE
	str	r0, [r1]                           @ 080033B0
	cmp	r0, #0                             @ 080033B2
	bne	.L08003428                         @ 080033B4
	movs	r2, #0xd0                         @ 080033B6
	adds	r2, r2, r6                        @ 080033B8
	mov	r8, r2                             @ 080033BA
	ldr	r0, [r2]                           @ 080033BC
	adds	r0, #2                            @ 080033BE
	str	r0, [r2]                           @ 080033C0
	lsls	r0, r0, #1                        @ 080033C2
	adds	r0, r0, r5                        @ 080033C4
	ldrh	r3, [r0]                          @ 080033C6
	cmp	r3, #0xfe                          @ 080033C8
	bne	.L080033D2                         @ 080033CA
	movs	r4, #2                            @ 080033CC
	ldrsh	r0, [r0, r4]                     @ 080033CE
	str	r0, [r2]                           @ 080033D0
.L080033D2:
	mov	r0, r8                             @ 080033D2
	ldr	r0, [r0]                           @ 080033D4
	mov	ip, r0                             @ 080033D6
	lsls	r0, r0, #1                        @ 080033D8
	adds	r4, r0, r5                        @ 080033DA
	movs	r1, #0                            @ 080033DC
	ldrsh	r0, [r4, r1]                     @ 080033DE
	cmp	r0, #0xfd                          @ 080033E0
	bgt	.L0800341A                         @ 080033E2
	adds	r3, r6, #0                        @ 080033E4
	adds	r3, #0xa8                         @ 080033E6
	ldr	r1, .Llit08003588                  @ 080033E8  =mcFreqHi
	adds	r0, r6, #0                        @ 080033EA
	adds	r0, #0xa4                         @ 080033EC
	movs	r5, #2                            @ 080033EE
	ldrsh	r2, [r4, r5]                     @ 080033F0
	ldr	r0, [r0]                           @ 080033F2
	adds	r0, r0, r2                        @ 080033F4
	adds	r1, r0, r1                        @ 080033F6
	ldrb	r1, [r1]                          @ 080033F8
	lsls	r2, r1, #8                        @ 080033FA
	ldr	r1, .Llit0800358C                  @ 080033FC  =mcFreqLo
	adds	r0, r0, r1                        @ 080033FE
	ldrb	r0, [r0]                          @ 08003400
	orrs	r2, r0                            @ 08003402
	str	r2, [r3]                           @ 08003404
	movs	r1, #0                            @ 08003406
	ldrsh	r0, [r4, r1]                     @ 08003408
	mov	r3, sb                             @ 0800340A
	str	r0, [r3]                           @ 0800340C
	ldr	r0, [r7]                           @ 0800340E
	lsls	r0, r0, #0x18                     @ 08003410
	lsrs	r0, r0, #0x10                     @ 08003412
	orrs	r0, r2                            @ 08003414
	ldr	r1, .Llit08003590                  @ 08003416  =REG_SOUND3CNT_X
	strh	r0, [r1]                          @ 08003418
.L0800341A:
	ldrh	r4, [r4]                          @ 0800341A
	cmp	r4, #0xff                          @ 0800341C
	bne	.L08003428                         @ 0800341E
	mov	r0, ip                             @ 08003420
	subs	r0, #2                            @ 08003422
	mov	r4, r8                             @ 08003424
	str	r0, [r4]                           @ 08003426
.L08003428:
	ldr	r5, [r7, #0x18]                    @ 08003428
	cmp	r5, #0                             @ 0800342A
	beq	.L080034AA                         @ 0800342C
	ldr	r0, [sp, #8]                       @ 0800342E
	lsls	r0, r0, #3                        @ 08003430
	mov	sb, r0                             @ 08003432
	adds	r0, r6, #0                        @ 08003434
	adds	r0, #0x3c                         @ 08003436
	mov	r1, sb                             @ 08003438
	adds	r2, r1, r0                        @ 0800343A
	ldr	r0, [r2]                           @ 0800343C
	subs	r0, #1                            @ 0800343E
	str	r0, [r2]                           @ 08003440
	cmp	r0, #0                             @ 08003442
	bne	.L080034AA                         @ 08003444
	adds	r0, r6, #0                        @ 08003446
	adds	r0, #0x38                         @ 08003448
	adds	r3, r1, r0                        @ 0800344A
	ldr	r0, [r3]                           @ 0800344C
	adds	r0, #2                            @ 0800344E
	str	r0, [r3]                           @ 08003450
	lsls	r0, r0, #1                        @ 08003452
	adds	r0, r0, r5                        @ 08003454
	ldrh	r4, [r0]                          @ 08003456
	cmp	r4, #0xfe                          @ 08003458
	bne	.L08003462                         @ 0800345A
	movs	r1, #2                            @ 0800345C
	ldrsh	r0, [r0, r1]                     @ 0800345E
	str	r0, [r3]                           @ 08003460
.L08003462:
	ldr	r0, [r3]                           @ 08003462
	lsls	r0, r0, #1                        @ 08003464
	adds	r1, r0, r5                        @ 08003466
	movs	r0, #0                            @ 08003468
	ldrsh	r4, [r1, r0]                     @ 0800346A
	cmp	r4, #0xfd                          @ 0800346C
	bgt	.L0800349A                         @ 0800346E
	movs	r4, #2                            @ 08003470
	ldrsh	r1, [r1, r4]                     @ 08003472
	str	r1, [r2]                           @ 08003474
	adds	r1, r6, #0                        @ 08003476
	adds	r1, #0x18                         @ 08003478
	add	r1, sb                             @ 0800347A
	ldr	r2, [r1]                           @ 0800347C
	ldr	r0, [r3]                           @ 0800347E
	lsls	r0, r0, #1                        @ 08003480
	adds	r0, r0, r5                        @ 08003482
	movs	r4, #0                            @ 08003484
	ldrsh	r0, [r0, r4]                     @ 08003486
	adds	r2, r2, r0                        @ 08003488
	str	r2, [r1]                           @ 0800348A
	lsls	r1, r2, #0x10                     @ 0800348C
	ldr	r0, [r7]                           @ 0800348E
	lsls	r0, r0, #0x18                     @ 08003490
	orrs	r0, r1                            @ 08003492
	lsrs	r2, r0, #0x10                     @ 08003494
	ldr	r0, .Llit08003590                  @ 08003496  =REG_SOUND3CNT_X
	strh	r2, [r0]                          @ 08003498
.L0800349A:
	ldr	r1, [r3]                           @ 0800349A
	lsls	r0, r1, #1                        @ 0800349C
	adds	r0, r0, r5                        @ 0800349E
	ldrh	r0, [r0]                          @ 080034A0
	cmp	r0, #0xff                          @ 080034A2
	bne	.L080034AA                         @ 080034A4
	subs	r0, r1, #2                        @ 080034A6
	str	r0, [r3]                           @ 080034A8
.L080034AA:
	ldr	r5, [r7, #0x10]                    @ 080034AA
	cmp	r5, #0                             @ 080034AC
	beq	.L08003536                         @ 080034AE
	ldr	r0, [sp, #8]                       @ 080034B0
	lsls	r0, r0, #3                        @ 080034B2
	mov	ip, r0                             @ 080034B4
	adds	r0, r6, #0                        @ 080034B6
	adds	r0, #0x34                         @ 080034B8
	mov	r1, ip                             @ 080034BA
	adds	r4, r1, r0                        @ 080034BC
	ldr	r0, [r4]                           @ 080034BE
	subs	r0, #1                            @ 080034C0
	str	r0, [r4]                           @ 080034C2
	cmp	r0, #0                             @ 080034C4
	bne	.L08003536                         @ 080034C6
	adds	r0, r6, #0                        @ 080034C8
	adds	r0, #0x30                         @ 080034CA
	adds	r3, r1, r0                        @ 080034CC
	ldr	r0, [r3]                           @ 080034CE
	adds	r0, #2                            @ 080034D0
	str	r0, [r3]                           @ 080034D2
	lsls	r0, r0, #1                        @ 080034D4
	adds	r0, r0, r5                        @ 080034D6
	ldrh	r2, [r0]                          @ 080034D8
	cmp	r2, #0xfe                          @ 080034DA
	bne	.L080034E4                         @ 080034DC
	movs	r1, #2                            @ 080034DE
	ldrsh	r0, [r0, r1]                     @ 080034E0
	str	r0, [r3]                           @ 080034E2
.L080034E4:
	ldr	r0, [r3]                           @ 080034E4
	lsls	r0, r0, #1                        @ 080034E6
	adds	r1, r0, r5                        @ 080034E8
	ldrh	r2, [r1]                          @ 080034EA
	mov	r8, r2                             @ 080034EC
	movs	r2, #0                            @ 080034EE
	ldrsh	r0, [r1, r2]                     @ 080034F0
	cmp	r0, #0xfd                          @ 080034F2
	bgt	.L08003526                         @ 080034F4
	mov	r2, r8                             @ 080034F6
	lsls	r0, r2, #8                        @ 080034F8
	ldrh	r2, [r7, #4]                      @ 080034FA
	orrs	r0, r2                            @ 080034FC
	lsls	r0, r0, #0x10                     @ 080034FE
	lsrs	r2, r0, #0x10                     @ 08003500
	ldr	r0, .Llit08003594                  @ 08003502  =REG_SOUND3CNT_H
	strh	r2, [r0]                          @ 08003504
	movs	r2, #2                            @ 08003506
	ldrsh	r0, [r1, r2]                     @ 08003508
	str	r0, [r4]                           @ 0800350A
	ldr	r2, .Llit08003590                  @ 0800350C  =REG_SOUND3CNT_X
	ldr	r1, [r7]                           @ 0800350E
	lsls	r1, r1, #8                        @ 08003510
	adds	r0, r6, #0                        @ 08003512
	adds	r0, #0x18                         @ 08003514
	add	r0, ip                             @ 08003516
	ldr	r0, [r0]                           @ 08003518
	orrs	r0, r1                            @ 0800351A
	movs	r4, #0x80                         @ 0800351C
	lsls	r4, r4, #8                        @ 0800351E
	adds	r1, r4, #0                        @ 08003520
	orrs	r0, r1                            @ 08003522
	strh	r0, [r2]                          @ 08003524
.L08003526:
	ldr	r1, [r3]                           @ 08003526
	lsls	r0, r1, #1                        @ 08003528
	adds	r0, r0, r5                        @ 0800352A
	ldrh	r0, [r0]                          @ 0800352C
	cmp	r0, #0xff                          @ 0800352E
	bne	.L08003536                         @ 08003530
	subs	r0, r1, #2                        @ 08003532
	str	r0, [r3]                           @ 08003534
.L08003536:
	mov	r5, sl                             @ 08003536
	cmp	r5, #3                             @ 08003538
	bne	mcUpdate_fxDone                    @ 0800353A
mcUpdate_fx_ch4:
	adds	r0, r6, #0                        @ 0800353C
	adds	r0, #0xf4                         @ 0800353E
	ldr	r0, [r0]                           @ 08003540
	lsls	r0, r0, #2                        @ 08003542
	ldr	r7, .Llit08003584                  @ 08003544  =mcInstTable
	adds	r0, r0, r7                        @ 08003546
	ldr	r7, [r0]                           @ 08003548
	ldr	r5, [r7, #0x18]                    @ 0800354A  noise-parameter table (inst+0x18); no 0xFE loop support
	cmp	r5, #0                             @ 0800354C
	beq	.L080035AE                         @ 0800354E
	movs	r0, #0x8a                         @ 08003550
	lsls	r0, r0, #1                        @ 08003552
	adds	r4, r6, r0                        @ 08003554
	ldr	r0, [r4]                           @ 08003556
	subs	r0, #1                            @ 08003558
	str	r0, [r4]                           @ 0800355A
	cmp	r0, #0                             @ 0800355C
	bne	.L080035AE                         @ 0800355E
	movs	r1, #0x88                         @ 08003560
	lsls	r1, r1, #1                        @ 08003562
	adds	r3, r6, r1                        @ 08003564
	ldr	r2, [r3]                           @ 08003566
	adds	r0, r2, #2                        @ 08003568
	str	r0, [r3]                           @ 0800356A
	lsls	r0, r0, #1                        @ 0800356C
	adds	r1, r0, r5                        @ 0800356E
	ldrh	r5, [r1]                          @ 08003570
	cmp	r5, #0xff                          @ 08003572  0xFF: hold
	bne	.L08003598                         @ 08003574
	str	r2, [r3]                           @ 08003576
	b	.L080035AE                           @ 08003578
	.hword	0x0000                          @ 0800357A  (padding)
.Llit0800357C:
	.word	REG_SOUND2CNT_L                  @ 0800357C  = 0x04000068
.Llit08003580:
	.word	REG_SOUND2CNT_H                  @ 08003580  = 0x0400006C
.Llit08003584:
	.word	mcInstTable                      @ 08003584  = 0x08027A74
.Llit08003588:
	.word	mcFreqHi                         @ 08003588  = 0x08026E95
.Llit0800358C:
	.word	mcFreqLo                         @ 0800358C  = 0x08026E34
.Llit08003590:
	.word	REG_SOUND3CNT_X                  @ 08003590  = 0x04000074
.Llit08003594:
	.word	REG_SOUND3CNT_H                  @ 08003594  = 0x04000072
.L08003598:
	ldr	r0, [r7]                           @ 08003598
	lsls	r0, r0, #8                        @ 0800359A
	ldrh	r2, [r1]                          @ 0800359C
	orrs	r0, r2                            @ 0800359E
	lsls	r0, r0, #0x10                     @ 080035A0
	lsrs	r2, r0, #0x10                     @ 080035A2
	movs	r3, #2                            @ 080035A4
	ldrsh	r0, [r1, r3]                     @ 080035A6
	str	r0, [r4]                           @ 080035A8
	ldr	r0, .Llit080035E8                  @ 080035AA  =REG_SOUND4CNT_H
	strh	r2, [r0]                          @ 080035AC  SOUND4CNT_H = b0<<8 | value
.L080035AE:
	ldr	r5, [r7, #0x10]                    @ 080035AE  envelope table (inst+0x10); no 0xFE loop support
	cmp	r5, #0                             @ 080035B0
	beq	mcUpdate_fxDone                    @ 080035B2
	ldr	r4, [sp, #8]                       @ 080035B4
	lsls	r1, r4, #3                        @ 080035B6
	adds	r0, r6, #0                        @ 080035B8
	adds	r0, #0x34                         @ 080035BA
	adds	r0, r0, r1                        @ 080035BC
	mov	ip, r0                             @ 080035BE
	ldr	r0, [r0]                           @ 080035C0
	subs	r0, #1                            @ 080035C2
	mov	r2, ip                             @ 080035C4
	str	r0, [r2]                           @ 080035C6
	cmp	r0, #0                             @ 080035C8
	bne	mcUpdate_fxDone                    @ 080035CA
	adds	r0, r6, #0                        @ 080035CC
	adds	r0, #0x30                         @ 080035CE
	adds	r2, r1, r0                        @ 080035D0
	ldr	r4, [r2]                           @ 080035D2
	adds	r0, r4, #2                        @ 080035D4
	str	r0, [r2]                           @ 080035D6
	lsls	r0, r0, #1                        @ 080035D8
	adds	r3, r0, r5                        @ 080035DA
	ldrh	r1, [r3]                          @ 080035DC
	cmp	r1, #0xff                          @ 080035DE
	bne	.L080035EC                         @ 080035E0
	str	r4, [r2]                           @ 080035E2
	b	mcUpdate_fxDone                      @ 080035E4
	.hword	0x0000                          @ 080035E6  (padding)
.Llit080035E8:
	.word	REG_SOUND4CNT_H                  @ 080035E8  = 0x0400007C
.L080035EC:
	ldr	r0, [r7, #4]                       @ 080035EC
	lsls	r1, r1, #8                        @ 080035EE
	orrs	r0, r1                            @ 080035F0
	lsls	r0, r0, #0x10                     @ 080035F2
	lsrs	r2, r0, #0x10                     @ 080035F4
	ldr	r0, .Llit0800365C                  @ 080035F6  =REG_SOUND4CNT_L
	strh	r2, [r0]                          @ 080035F8  SOUND4CNT_L = value<<8 | inst.lo
	movs	r4, #2                            @ 080035FA
	ldrsh	r0, [r3, r4]                     @ 080035FC
	mov	r5, ip                             @ 080035FE
	str	r0, [r5]                           @ 08003600
	ldr	r2, .Llit08003660                  @ 08003602  =REG_SOUND4CNT_H
	ldrh	r0, [r2]                          @ 08003604
	movs	r7, #0x80                         @ 08003606
	lsls	r7, r7, #8                        @ 08003608
	adds	r1, r7, #0                        @ 0800360A
	orrs	r0, r1                            @ 0800360C
	strh	r0, [r2]                          @ 0800360E  SOUND4CNT_H |= 0x8000 (restart)
mcUpdate_fxDone:
	ldr	r1, [sp, #0x10]                    @ 08003610
	ldr	r0, [r1]                           @ 08003612
	cmp	r0, #0                             @ 08003614
	beq	mcUpdate_seqFetch                  @ 08003616
	b	mcUpdate_chanTail                    @ 08003618
mcUpdate_seqFetch:
	adds	r1, r6, #0                        @ 0800361A
	adds	r1, #0x24                         @ 0800361C
	ldr	r2, [sp, #0xc]                     @ 0800361E
	adds	r0, r2, r1                        @ 08003620
	ldr	r0, [r0]                           @ 08003622
	cmp	r0, #0                             @ 08003624
	beq	.L0800362A                         @ 08003626  pattern still active?
	b	mcUpdate_patFetch                    @ 08003628
.L0800362A:
	movs	r3, #0x24                         @ 0800362A
	rsbs	r3, r3, #0                        @ 0800362C
	adds	r3, r3, r1                        @ 0800362E
	mov	sb, r3                             @ 08003630
	ldr	r0, [sp, #0x28]                    @ 08003632
	add	r0, sl                             @ 08003634
	lsls	r7, r0, #3                        @ 08003636
	mov	r0, sb                             @ 08003638
	adds	r0, #8                            @ 0800363A
	adds	r3, r7, r0                        @ 0800363C
	subs	r0, #4                            @ 0800363E
	adds	r0, r7, r0                        @ 08003640
	str	r0, [sp, #0x14]                    @ 08003642
	ldr	r4, .Llit08003664                  @ 08003644  =mcChan+CH_ticks
	adds	r4, r7, r4                        @ 08003646
	str	r4, [sp, #0x1c]                    @ 08003648
	movs	r5, #0                            @ 0800364A
	mov	r8, r5                             @ 0800364C
	mov	r0, sb                             @ 0800364E
	adds	r0, #0x28                         @ 08003650
	adds	r0, r7, r0                        @ 08003652
	str	r0, [sp, #0x18]                    @ 08003654
	adds	r1, r1, r7                        @ 08003656
	mov	ip, r1                             @ 08003658
	b	mcUpdate_seqCmdLoop                  @ 0800365A
.Llit0800365C:
	.word	REG_SOUND4CNT_L                  @ 0800365C  = 0x04000078
.Llit08003660:
	.word	REG_SOUND4CNT_H                  @ 08003660  = 0x0400007C
.Llit08003664:
	.word	mcChan+CH_ticks                  @ 08003664  = 0x030000B0
.L08003668:
	cmp	r4, #0x61                          @ 08003668
	beq	mcUpdate_seqCmdDone                @ 0800366A
mcUpdate_seqCmdLoop:
	mov	r0, sb                             @ 0800366C
	adds	r0, #0x20                         @ 0800366E
	adds	r0, r7, r0                        @ 08003670
	ldr	r5, [r0]                           @ 08003672
	ldr	r2, [r3]                           @ 08003674
	lsls	r0, r2, #2                        @ 08003676
	adds	r0, r0, r5                        @ 08003678
	ldr	r4, [r0]                           @ 0800367A
	cmp	r4, #0x67                          @ 0800367C  0x67 v: global panning (GB NR51 equivalent)
	bne	.L08003692                         @ 0800367E
	ldr	r0, [r0, #4]                       @ 08003680
	lsls	r0, r0, #8                        @ 08003682
	adds	r0, #0x77                         @ 08003684
	ldr	r1, .Llit080037A8                  @ 08003686  =mcMasterPan
	str	r0, [r1]                           @ 08003688
	ldr	r1, .Llit080037AC                  @ 0800368A  =REG_SOUNDCNT_L
	strh	r0, [r1]                          @ 0800368C  SOUNDCNT_L = v<<8 (L/R enables) | 0x77 (volume 7/7)
	adds	r0, r2, #2                        @ 0800368E
	str	r0, [r3]                           @ 08003690
.L08003692:
	cmp	r4, #0x69                          @ 08003692  0x69 t: tempo
	bne	.L080036A6                         @ 08003694
	ldr	r0, [r3]                           @ 08003696
	lsls	r1, r0, #2                        @ 08003698
	adds	r1, r1, r5                        @ 0800369A
	ldr	r1, [r1, #4]                       @ 0800369C
	ldr	r2, .Llit080037B0                  @ 0800369E  =mcTempo
	str	r1, [r2]                           @ 080036A0
	adds	r0, #2                            @ 080036A2
	str	r0, [r3]                           @ 080036A4
.L080036A6:
	cmp	r4, #0x60                          @ 080036A6  0x60 a b: skip 3 words (GB $60 = tie; no effect here)
	bne	.L080036B0                         @ 080036A8
	ldr	r0, [r3]                           @ 080036AA
	adds	r0, #3                            @ 080036AC
	str	r0, [r3]                           @ 080036AE
.L080036B0:
	cmp	r4, #0x66                          @ 080036B0  0x66 v: conditional (end-of-song) flag, not read by the driver
	bne	.L080036C4                         @ 080036B2
	ldr	r0, [r3]                           @ 080036B4
	lsls	r1, r0, #2                        @ 080036B6
	adds	r1, r1, r5                        @ 080036B8
	ldr	r1, [r1, #4]                       @ 080036BA
	ldr	r2, .Llit080037B4                  @ 080036BC  =mcCondFlag
	str	r1, [r2]                           @ 080036BE
	adds	r0, #2                            @ 080036C0
	str	r0, [r3]                           @ 080036C2
.L080036C4:
	cmp	r4, #0x61                          @ 080036C4  0x61: end -- silence channel, index not advanced
	bne	.L08003710                         @ 080036C6
	ldr	r1, [sp, #0x14]                    @ 080036C8
	ldr	r0, [r1]                           @ 080036CA
	cmp	r0, #0                             @ 080036CC
	beq	.L08003710                         @ 080036CE
	mov	r2, sl                             @ 080036D0
	cmp	r2, #0                             @ 080036D2
	bne	.L080036E0                         @ 080036D4
	ldr	r0, .Llit080037B8                  @ 080036D6  =REG_SOUND1CNT_H
	strh	r2, [r0]                          @ 080036D8
	adds	r0, #2                            @ 080036DA
	mov	r1, sl                             @ 080036DC
	strh	r1, [r0]                          @ 080036DE
.L080036E0:
	mov	r2, sl                             @ 080036E0
	cmp	r2, #1                             @ 080036E2
	bne	.L080036F0                         @ 080036E4
	ldr	r0, .Llit080037BC                  @ 080036E6  =REG_SOUND2CNT_L
	mov	r1, r8                             @ 080036E8
	strh	r1, [r0]                          @ 080036EA
	adds	r0, #4                            @ 080036EC
	strh	r1, [r0]                          @ 080036EE
.L080036F0:
	mov	r2, sl                             @ 080036F0
	cmp	r2, #2                             @ 080036F2
	bne	.L08003700                         @ 080036F4
	ldr	r0, .Llit080037C0                  @ 080036F6  =REG_SOUND3CNT_H
	mov	r1, r8                             @ 080036F8
	strh	r1, [r0]                          @ 080036FA
	adds	r0, #2                            @ 080036FC
	strh	r1, [r0]                          @ 080036FE
.L08003700:
	mov	r2, sl                             @ 08003700
	cmp	r2, #3                             @ 08003702
	bne	.L08003710                         @ 08003704
	ldr	r0, .Llit080037C4                  @ 08003706  =REG_SOUND4CNT_L
	mov	r1, r8                             @ 08003708
	strh	r1, [r0]                          @ 0800370A
	adds	r0, #4                            @ 0800370C
	strh	r1, [r0]                          @ 0800370E
.L08003710:
	cmp	r4, #0x64                          @ 08003710  0x64 pat transpose repeat
	bne	.L0800374A                         @ 08003712
	ldr	r0, [r3]                           @ 08003714
	lsls	r0, r0, #2                        @ 08003716
	adds	r0, r0, r5                        @ 08003718
	ldr	r0, [r0, #8]                       @ 0800371A
	ldr	r2, [sp, #0x18]                    @ 0800371C
	str	r0, [r2]                           @ 0800371E
	ldr	r2, [r3]                           @ 08003720
	lsls	r2, r2, #2                        @ 08003722
	adds	r2, r2, r5                        @ 08003724
	ldr	r0, [r2, #4]                       @ 08003726
	mov	r1, ip                             @ 08003728
	str	r0, [r1]                           @ 0800372A
	mov	r1, sb                             @ 0800372C
	adds	r1, #0x2c                         @ 0800372E
	adds	r1, r7, r1                        @ 08003730
	ldr	r0, [r2, #0xc]                     @ 08003732
	str	r0, [r1]                           @ 08003734
	mov	r0, sb                             @ 08003736
	adds	r0, #0xc                          @ 08003738
	adds	r0, r7, r0                        @ 0800373A
	movs	r2, #0                            @ 0800373C
	str	r2, [r0]                           @ 0800373E
	ldr	r0, [sp, #0x1c]                    @ 08003740
	str	r2, [r0]                           @ 08003742
	ldr	r0, [r3]                           @ 08003744
	adds	r0, #4                            @ 08003746
	str	r0, [r3]                           @ 08003748
.L0800374A:
	cmp	r4, #0x62                          @ 0800374A  0x62 n: jump to word n
	bne	.L08003758                         @ 0800374C
	ldr	r0, [r3]                           @ 0800374E
	lsls	r0, r0, #2                        @ 08003750
	adds	r0, r0, r5                        @ 08003752
	ldr	r0, [r0, #4]                       @ 08003754
	str	r0, [r3]                           @ 08003756
.L08003758:
	cmp	r4, #0x64                          @ 08003758  loop until 0x64 (0x61 exits at the top)
	bne	.L08003668                         @ 0800375A
mcUpdate_seqCmdDone:
	adds	r0, r6, #0                        @ 0800375C
	adds	r0, #0x24                         @ 0800375E
	ldr	r1, [sp, #0xc]                     @ 08003760
	adds	r0, r1, r0                        @ 08003762
	ldr	r0, [r0]                           @ 08003764
	cmp	r0, #0                             @ 08003766
	bne	mcUpdate_patFetch                  @ 08003768
	b	mcUpdate_chanTail                    @ 0800376A
mcUpdate_patFetch:
	ldr	r2, [sp, #8]                       @ 0800376C
	lsls	r1, r2, #3                        @ 0800376E
	ldr	r0, [sp, #4]                       @ 08003770
	adds	r0, #0x24                         @ 08003772
	adds	r3, r1, r0                        @ 08003774
	ldr	r7, [r3]                           @ 08003776
	ldr	r0, [sp, #4]                       @ 08003778
	adds	r0, #0xc                          @ 0800377A
	adds	r2, r1, r0                        @ 0800377C
	ldr	r0, [r2]                           @ 0800377E
	adds	r0, r7, r0                        @ 08003780
	ldrb	r0, [r0]                          @ 08003782
	str	r0, [sp]                           @ 08003784
	cmp	r0, #0x65                          @ 08003786  0x65: end of pattern
	bne	mcUpdate_noteEvent                 @ 08003788
	adds	r0, r6, #0                        @ 0800378A
	adds	r0, #0x2c                         @ 0800378C
	adds	r1, r1, r0                        @ 0800378E
	ldr	r0, [r1]                           @ 08003790
	cmp	r0, #0                             @ 08003792
	beq	.L080037C8                         @ 08003794  patRepeat == 0: done
	subs	r0, #1                            @ 08003796
	str	r0, [r1]                           @ 08003798
	cmp	r0, #0                             @ 0800379A
	beq	.L080037C8                         @ 0800379C
	movs	r3, #0                            @ 0800379E
	str	r3, [r2]                           @ 080037A0  repeat: patPos = 0
	ldrb	r4, [r7]                          @ 080037A2
	str	r4, [sp]                           @ 080037A4
	b	.L080037CC                           @ 080037A6
.Llit080037A8:
	.word	mcMasterPan                      @ 080037A8  = 0x0300002C
.Llit080037AC:
	.word	REG_SOUNDCNT_L                   @ 080037AC  = 0x04000080
.Llit080037B0:
	.word	mcTempo                          @ 080037B0  = 0x0300001C
.Llit080037B4:
	.word	mcCondFlag                       @ 080037B4  = 0x03000250
.Llit080037B8:
	.word	REG_SOUND1CNT_H                  @ 080037B8  = 0x04000062
.Llit080037BC:
	.word	REG_SOUND2CNT_L                  @ 080037BC  = 0x04000068
.Llit080037C0:
	.word	REG_SOUND3CNT_H                  @ 080037C0  = 0x04000072
.Llit080037C4:
	.word	REG_SOUND4CNT_L                  @ 080037C4  = 0x04000078
.L080037C8:
	str	r0, [r3]                           @ 080037C8  patPtr = patPos = 0
	str	r0, [r2]                           @ 080037CA
.L080037CC:
	ldr	r5, [sp]                           @ 080037CC
	cmp	r5, #0x65                          @ 080037CE
	bne	mcUpdate_noteEvent                 @ 080037D0
	b	mcUpdate_seqChanTop                  @ 080037D2  back to the sequence (far branch)
mcUpdate_noteEvent:
	ldr	r0, [sp, #8]                       @ 080037D4
	lsls	r1, r0, #3                        @ 080037D6
	adds	r0, r6, #0                        @ 080037D8
	adds	r0, #0xc                          @ 080037DA
	adds	r0, r1, r0                        @ 080037DC
	ldr	r0, [r0]                           @ 080037DE
	adds	r0, r7, r0                        @ 080037E0
	ldrb	r0, [r0]                          @ 080037E2
	mov	ip, r0                             @ 080037E4
	cmp	r0, #0x60                          @ 080037E6  0x60 = rest
	beq	.L080037FC                         @ 080037E8
	adds	r0, r6, #0                        @ 080037EA
	adds	r0, #0x28                         @ 080037EC
	adds	r0, r1, r0                        @ 080037EE
	ldr	r0, [r0]                           @ 080037F0
	add	r0, ip                             @ 080037F2  note += transpose (8-bit wrap)
	lsls	r0, r0, #0x18                     @ 080037F4
	lsrs	r0, r0, #0x18                     @ 080037F6
	mov	ip, r0                             @ 080037F8
	b	mcUpdate_noteHaveNote                @ 080037FA
.L080037FC:
	mov	r0, sl                             @ 080037FC  rest: note 0x30 on PSG, 0x60 (no trigger) on ch5/6
	subs	r0, #4                            @ 080037FE
	movs	r1, #0x30                         @ 08003800
	mov	ip, r1                             @ 08003802
	cmp	r0, #1                             @ 08003804
	bhi	mcUpdate_noteHaveNote              @ 08003806
	movs	r2, #0x60                         @ 08003808
	mov	ip, r2                             @ 0800380A
mcUpdate_noteHaveNote:
	ldr	r0, .Llit080038F0                  @ 0800380C  =mcDurTable
	ldr	r0, [r0]                           @ 0800380E
	mov	r8, r0                             @ 08003810
	adds	r0, r6, #0                        @ 08003812
	adds	r0, #0x14                         @ 08003814
	ldr	r3, [sp, #0xc]                     @ 08003816
	adds	r0, r3, r0                        @ 08003818
	mov	r4, ip                             @ 0800381A
	str	r4, [r0]                           @ 0800381C  chan.note
	adds	r2, r6, #0                        @ 0800381E
	adds	r2, #0x18                         @ 08003820
	adds	r2, r3, r2                        @ 08003822
	ldr	r4, .Llit080038F4                  @ 08003824  =mcFreqHi
	mov	r5, ip                             @ 08003826
	adds	r0, r5, r4                        @ 08003828
	ldrb	r0, [r0]                          @ 0800382A
	lsls	r1, r0, #8                        @ 0800382C
	ldr	r3, .Llit080038F8                  @ 0800382E  =mcFreqLo
	adds	r0, r5, r3                        @ 08003830
	ldrb	r0, [r0]                          @ 08003832
	orrs	r1, r0                            @ 08003834
	str	r1, [r2]                           @ 08003836  chan.freq = FreqHi[n]<<8 | FreqLo[n]
	adds	r2, r6, #0                        @ 08003838
	adds	r2, #0x1c                         @ 0800383A
	ldr	r0, [sp, #0xc]                     @ 0800383C
	adds	r2, r0, r2                        @ 0800383E
	adds	r1, r6, #0                        @ 08003840
	adds	r1, #0xc                          @ 08003842
	adds	r1, r0, r1                        @ 08003844
	ldr	r0, [r1]                           @ 08003846
	adds	r0, r7, r0                        @ 08003848
	ldrb	r0, [r0, #1]                      @ 0800384A
	str	r0, [r2]                           @ 0800384C  chan.inst = byte 1
	ldr	r0, [r1]                           @ 0800384E
	adds	r0, r7, r0                        @ 08003850
	ldrb	r0, [r0, #2]                      @ 08003852
	lsls	r0, r0, #2                        @ 08003854
	add	r0, r8                             @ 08003856
	ldr	r0, [r0]                           @ 08003858
	ldr	r2, [sp, #0x10]                    @ 0800385A
	str	r0, [r2]                           @ 0800385C  chan.ticks = mcDurTable[byte 2]
	ldr	r0, [r1]                           @ 0800385E
	adds	r0, #3                            @ 08003860
	str	r0, [r1]                           @ 08003862  patPos += 3
	mov	r8, r4                             @ 08003864
	mov	sb, r3                             @ 08003866
	mov	r3, sl                             @ 08003868
	cmp	r3, #0                             @ 0800386A
	bne	mcUpdate_noteOn_ch2                @ 0800386C
	ldr	r0, [r6, #0x1c]                    @ 0800386E
	lsls	r0, r0, #2                        @ 08003870
	ldr	r4, .Llit080038FC                  @ 08003872  =mcInstTable
	adds	r0, r0, r4                        @ 08003874
	ldr	r7, [r0]                           @ 08003876
	ldr	r1, [r7, #4]                       @ 08003878
	ldr	r0, [r7, #8]                       @ 0800387A
	lsls	r0, r0, #8                        @ 0800387C
	adds	r1, r1, r0                        @ 0800387E  v = inst.lo | inst.hi<<8
	lsls	r1, r1, #0x10                     @ 08003880
	lsrs	r2, r1, #0x10                     @ 08003882
	ldr	r5, [r7, #0x10]                    @ 08003884
	cmp	r5, #0                             @ 08003886
	beq	.L080038A0                         @ 08003888
	movs	r0, #0xff                         @ 0800388A
	ands	r2, r0                            @ 0800388C
	ldrh	r1, [r5]                          @ 0800388E
	lsls	r0, r1, #8                        @ 08003890
	orrs	r2, r0                            @ 08003892
	lsls	r0, r2, #0x10                     @ 08003894
	lsrs	r2, r0, #0x10                     @ 08003896  v = inst.lo | env[0]<<8
	str	r3, [r6, #0x30]                    @ 08003898
	movs	r3, #2                            @ 0800389A
	ldrsh	r0, [r5, r3]                     @ 0800389C
	str	r0, [r6, #0x34]                    @ 0800389E  envTimer = env[1]
.L080038A0:
	ldr	r3, [r6, #4]                       @ 080038A0
	cmp	r3, #0                             @ 080038A2
	beq	.L080038AA                         @ 080038A4
	ldr	r0, .Llit08003900                  @ 080038A6  =REG_SOUND1CNT_H
	strh	r2, [r0]                          @ 080038A8  SOUND1CNT_H = v   (if owned)
.L080038AA:
	ldr	r5, [r7, #0x20]                    @ 080038AA
	cmp	r5, #0                             @ 080038AC
	beq	.L080038D0                         @ 080038AE
	movs	r4, #2                            @ 080038B0
	ldrsh	r0, [r5, r4]                     @ 080038B2
	add	r0, ip                             @ 080038B4
	mov	r2, r8                             @ 080038B6
	adds	r1, r0, r2                        @ 080038B8
	ldrb	r1, [r1]                          @ 080038BA
	lsls	r1, r1, #8                        @ 080038BC
	add	r0, sb                             @ 080038BE
	ldrb	r0, [r0]                          @ 080038C0
	orrs	r1, r0                            @ 080038C2
	str	r1, [r6, #0x18]                    @ 080038C4  freq = Freq[note + arp[1]]
	mov	r4, sl                             @ 080038C6
	str	r4, [r6, #0x40]                    @ 080038C8
	movs	r1, #0                            @ 080038CA
	ldrsh	r0, [r5, r1]                     @ 080038CC
	str	r0, [r6, #0x44]                    @ 080038CE  arpTimer = arp[0]
.L080038D0:
	ldr	r0, [r7]                           @ 080038D0
	lsls	r0, r0, #0x18                     @ 080038D2
	lsrs	r2, r0, #0x10                     @ 080038D4
	ldr	r5, [r7, #0x18]                    @ 080038D6
	cmp	r5, #0                             @ 080038D8
	beq	.L08003908                         @ 080038DA
	ldrh	r4, [r5]                          @ 080038DC
	ldr	r7, .Llit08003904                  @ 080038DE  =0xFFFF8000
	adds	r0, r4, r7                        @ 080038E0
	orrs	r2, r0                            @ 080038E2  x |= pitch[0] + 0x8000 (OR, not add)
	mov	r0, sl                             @ 080038E4
	str	r0, [r6, #0x38]                    @ 080038E6
	movs	r1, #2                            @ 080038E8
	ldrsh	r0, [r5, r1]                     @ 080038EA
	str	r0, [r6, #0x3c]                    @ 080038EC  pitchTimer = pitch[1]
	b	.L08003910                           @ 080038EE
.Llit080038F0:
	.word	mcDurTable                       @ 080038F0  = 0x03000030
.Llit080038F4:
	.word	mcFreqHi                         @ 080038F4  = 0x08026E95
.Llit080038F8:
	.word	mcFreqLo                         @ 080038F8  = 0x08026E34
.Llit080038FC:
	.word	mcInstTable                      @ 080038FC  = 0x08027A74
.Llit08003900:
	.word	REG_SOUND1CNT_H                  @ 08003900  = 0x04000062
.Llit08003904:
	.word	0xFFFF8000                       @ 08003904
.L08003908:
	movs	r4, #0x80                         @ 08003908
	lsls	r4, r4, #8                        @ 0800390A
	adds	r0, r4, #0                        @ 0800390C
	orrs	r2, r0                            @ 0800390E  no pitch table: x |= 0x8000
.L08003910:
	ldr	r0, [r6, #0x18]                    @ 08003910
	orrs	r0, r2                            @ 08003912
	lsls	r0, r0, #0x10                     @ 08003914
	lsrs	r2, r0, #0x10                     @ 08003916
	cmp	r3, #0                             @ 08003918
	beq	mcUpdate_noteOn_ch2                @ 0800391A
	ldr	r0, .Llit080039C4                  @ 0800391C  =REG_SOUND1CNT_X
	strh	r2, [r0]                          @ 0800391E  SOUND1CNT_X = x | freq   (if owned)
mcUpdate_noteOn_ch2:
	mov	r5, sl                             @ 08003920
	cmp	r5, #1                             @ 08003922
	bne	mcUpdate_noteOn_ch3                @ 08003924
	ldr	r0, [r6, #0x64]                    @ 08003926
	lsls	r0, r0, #2                        @ 08003928
	ldr	r7, .Llit080039C8                  @ 0800392A  =mcInstTable
	adds	r0, r0, r7                        @ 0800392C
	ldr	r7, [r0]                           @ 0800392E
	ldr	r1, [r7, #4]                       @ 08003930
	ldr	r0, [r7, #8]                       @ 08003932
	lsls	r0, r0, #8                        @ 08003934
	adds	r1, r1, r0                        @ 08003936
	lsls	r1, r1, #0x10                     @ 08003938
	lsrs	r2, r1, #0x10                     @ 0800393A
	ldr	r5, [r7, #0x10]                    @ 0800393C
	cmp	r5, #0                             @ 0800393E
	beq	.L0800395A                         @ 08003940
	movs	r0, #0xff                         @ 08003942
	ands	r2, r0                            @ 08003944
	ldrh	r1, [r5]                          @ 08003946
	lsls	r0, r1, #8                        @ 08003948
	orrs	r2, r0                            @ 0800394A
	lsls	r0, r2, #0x10                     @ 0800394C
	lsrs	r2, r0, #0x10                     @ 0800394E
	movs	r3, #0                            @ 08003950
	str	r3, [r6, #0x78]                    @ 08003952
	movs	r4, #2                            @ 08003954
	ldrsh	r0, [r5, r4]                     @ 08003956
	str	r0, [r6, #0x7c]                    @ 08003958
.L0800395A:
	ldr	r3, [r6, #0x4c]                    @ 0800395A
	cmp	r3, #0                             @ 0800395C
	beq	.L08003964                         @ 0800395E
	ldr	r0, .Llit080039CC                  @ 08003960  =REG_SOUND2CNT_L
	strh	r2, [r0]                          @ 08003962
.L08003964:
	ldr	r5, [r7, #0x20]                    @ 08003964
	cmp	r5, #0                             @ 08003966
	beq	.L08003992                         @ 08003968
	movs	r1, #2                            @ 0800396A
	ldrsh	r0, [r5, r1]                     @ 0800396C
	add	r0, ip                             @ 0800396E
	mov	r2, r8                             @ 08003970
	adds	r1, r0, r2                        @ 08003972
	ldrb	r1, [r1]                          @ 08003974
	lsls	r1, r1, #8                        @ 08003976
	add	r0, sb                             @ 08003978
	ldrb	r0, [r0]                          @ 0800397A
	orrs	r1, r0                            @ 0800397C
	str	r1, [r6, #0x60]                    @ 0800397E
	adds	r0, r6, #0                        @ 08003980
	adds	r0, #0x88                         @ 08003982
	movs	r4, #0                            @ 08003984
	str	r4, [r0]                           @ 08003986
	adds	r1, r6, #0                        @ 08003988
	adds	r1, #0x8c                         @ 0800398A
	movs	r2, #0                            @ 0800398C
	ldrsh	r0, [r5, r2]                     @ 0800398E
	str	r0, [r1]                           @ 08003990
.L08003992:
	ldr	r0, [r7]                           @ 08003992
	lsls	r0, r0, #0x18                     @ 08003994
	lsrs	r2, r0, #0x10                     @ 08003996
	ldr	r5, [r7, #0x18]                    @ 08003998
	cmp	r5, #0                             @ 0800399A
	beq	.L080039D0                         @ 0800399C
	movs	r4, #0x80                         @ 0800399E
	lsls	r4, r4, #8                        @ 080039A0
	adds	r0, r4, #0                        @ 080039A2
	ldrh	r7, [r5]                          @ 080039A4
	orrs	r0, r7                            @ 080039A6
	orrs	r2, r0                            @ 080039A8
	adds	r0, r6, #0                        @ 080039AA
	adds	r0, #0x80                         @ 080039AC
	movs	r1, #0                            @ 080039AE
	str	r1, [r0]                           @ 080039B0
	adds	r1, r6, #0                        @ 080039B2
	adds	r1, #0x84                         @ 080039B4
	movs	r4, #2                            @ 080039B6
	ldrsh	r0, [r5, r4]                     @ 080039B8
	str	r0, [r1]                           @ 080039BA
	ldr	r0, [r6, #0x60]                    @ 080039BC
	orrs	r2, r0                            @ 080039BE
	lsls	r0, r2, #0x10                     @ 080039C0
	b	.L080039DE                           @ 080039C2
.Llit080039C4:
	.word	REG_SOUND1CNT_X                  @ 080039C4  = 0x04000064
.Llit080039C8:
	.word	mcInstTable                      @ 080039C8  = 0x08027A74
.Llit080039CC:
	.word	REG_SOUND2CNT_L                  @ 080039CC  = 0x04000068
.L080039D0:
	movs	r5, #0x80                         @ 080039D0
	lsls	r5, r5, #8                        @ 080039D2
	adds	r0, r5, #0                        @ 080039D4
	orrs	r2, r0                            @ 080039D6
	ldr	r0, [r6, #0x60]                    @ 080039D8
	orrs	r0, r2                            @ 080039DA
	lsls	r0, r0, #0x10                     @ 080039DC
.L080039DE:
	lsrs	r2, r0, #0x10                     @ 080039DE
	cmp	r3, #0                             @ 080039E0
	beq	mcUpdate_noteOn_ch3                @ 080039E2
	ldr	r0, .Llit08003AA0                  @ 080039E4  =REG_SOUND2CNT_H
	strh	r2, [r0]                          @ 080039E6
mcUpdate_noteOn_ch3:
	mov	r7, sl                             @ 080039E8
	cmp	r7, #2                             @ 080039EA
	bne	mcUpdate_noteOn_ch4                @ 080039EC
	adds	r0, r6, #0                        @ 080039EE
	adds	r0, #0xac                         @ 080039F0
	ldr	r0, [r0]                           @ 080039F2
	lsls	r0, r0, #2                        @ 080039F4
	ldr	r1, .Llit08003AA4                  @ 080039F6  =mcInstTable
	adds	r0, r0, r1                        @ 080039F8
	ldr	r7, [r0]                           @ 080039FA
	ldr	r1, [r7, #4]                       @ 080039FC
	ldr	r0, [r7, #8]                       @ 080039FE
	lsls	r0, r0, #8                        @ 08003A00
	adds	r1, r1, r0                        @ 08003A02
	lsls	r1, r1, #0x10                     @ 08003A04
	lsrs	r2, r1, #0x10                     @ 08003A06
	ldr	r5, [r7, #0x10]                    @ 08003A08
	cmp	r5, #0                             @ 08003A0A
	beq	.L08003A2E                         @ 08003A0C
	movs	r0, #0xff                         @ 08003A0E
	ands	r2, r0                            @ 08003A10
	ldrh	r3, [r5]                          @ 08003A12
	lsls	r0, r3, #8                        @ 08003A14
	orrs	r2, r0                            @ 08003A16
	lsls	r0, r2, #0x10                     @ 08003A18
	lsrs	r2, r0, #0x10                     @ 08003A1A
	adds	r0, r6, #0                        @ 08003A1C
	adds	r0, #0xc0                         @ 08003A1E
	movs	r4, #0                            @ 08003A20
	str	r4, [r0]                           @ 08003A22
	adds	r1, r6, #0                        @ 08003A24
	adds	r1, #0xc4                         @ 08003A26
	movs	r3, #2                            @ 08003A28
	ldrsh	r0, [r5, r3]                     @ 08003A2A
	str	r0, [r1]                           @ 08003A2C
.L08003A2E:
	adds	r4, r6, #0                        @ 08003A2E
	adds	r4, #0x94                         @ 08003A30
	ldr	r0, [r4]                           @ 08003A32
	cmp	r0, #0                             @ 08003A34
	beq	.L08003A3C                         @ 08003A36
	ldr	r0, .Llit08003AA8                  @ 08003A38  =REG_SOUND3CNT_H
	strh	r2, [r0]                          @ 08003A3A
.L08003A3C:
	ldr	r5, [r7, #0x20]                    @ 08003A3C
	adds	r3, r6, #0                        @ 08003A3E
	adds	r3, #0xa8                         @ 08003A40
	cmp	r5, #0                             @ 08003A42
	beq	.L08003A6E                         @ 08003A44
	movs	r1, #2                            @ 08003A46
	ldrsh	r0, [r5, r1]                     @ 08003A48
	add	r0, ip                             @ 08003A4A
	mov	r2, r8                             @ 08003A4C
	adds	r1, r0, r2                        @ 08003A4E
	ldrb	r1, [r1]                          @ 08003A50
	lsls	r1, r1, #8                        @ 08003A52
	add	r0, sb                             @ 08003A54
	ldrb	r0, [r0]                          @ 08003A56
	orrs	r1, r0                            @ 08003A58
	str	r1, [r3]                           @ 08003A5A
	adds	r0, r6, #0                        @ 08003A5C
	adds	r0, #0xd0                         @ 08003A5E
	movs	r1, #0                            @ 08003A60
	str	r1, [r0]                           @ 08003A62
	adds	r1, r6, #0                        @ 08003A64
	adds	r1, #0xd4                         @ 08003A66
	movs	r2, #0                            @ 08003A68
	ldrsh	r0, [r5, r2]                     @ 08003A6A
	str	r0, [r1]                           @ 08003A6C
.L08003A6E:
	ldr	r0, [r7]                           @ 08003A6E
	lsls	r0, r0, #0x18                     @ 08003A70
	lsrs	r2, r0, #0x10                     @ 08003A72
	ldr	r5, [r7, #0x18]                    @ 08003A74
	cmp	r5, #0                             @ 08003A76
	beq	.L08003AAC                         @ 08003A78
	movs	r7, #0x80                         @ 08003A7A
	lsls	r7, r7, #8                        @ 08003A7C
	adds	r0, r7, #0                        @ 08003A7E
	ldrh	r1, [r5]                          @ 08003A80
	orrs	r0, r1                            @ 08003A82
	orrs	r2, r0                            @ 08003A84
	adds	r0, r6, #0                        @ 08003A86
	adds	r0, #0xc8                         @ 08003A88
	movs	r7, #0                            @ 08003A8A
	str	r7, [r0]                           @ 08003A8C
	adds	r1, r6, #0                        @ 08003A8E
	adds	r1, #0xcc                         @ 08003A90
	movs	r7, #2                            @ 08003A92
	ldrsh	r0, [r5, r7]                     @ 08003A94
	str	r0, [r1]                           @ 08003A96
	ldr	r0, [r3]                           @ 08003A98
	orrs	r2, r0                            @ 08003A9A
	lsls	r0, r2, #0x10                     @ 08003A9C
	b	.L08003ABA                           @ 08003A9E
.Llit08003AA0:
	.word	REG_SOUND2CNT_H                  @ 08003AA0  = 0x0400006C
.Llit08003AA4:
	.word	mcInstTable                      @ 08003AA4  = 0x08027A74
.Llit08003AA8:
	.word	REG_SOUND3CNT_H                  @ 08003AA8  = 0x04000072
.L08003AAC:
	movs	r1, #0x80                         @ 08003AAC
	lsls	r1, r1, #8                        @ 08003AAE
	adds	r0, r1, #0                        @ 08003AB0
	orrs	r2, r0                            @ 08003AB2
	ldr	r0, [r3]                           @ 08003AB4
	orrs	r0, r2                            @ 08003AB6
	lsls	r0, r0, #0x10                     @ 08003AB8
.L08003ABA:
	lsrs	r2, r0, #0x10                     @ 08003ABA
	ldr	r0, [r4]                           @ 08003ABC
	cmp	r0, #0                             @ 08003ABE
	beq	mcUpdate_noteOn_ch4                @ 08003AC0
	ldr	r0, .Llit08003CA0                  @ 08003AC2  =REG_SOUND3CNT_X
	strh	r2, [r0]                          @ 08003AC4
mcUpdate_noteOn_ch4:
	mov	r2, sl                             @ 08003AC6
	cmp	r2, #3                             @ 08003AC8
	bne	mcUpdate_noteOn_ch5                @ 08003ACA
	adds	r0, r6, #0                        @ 08003ACC
	adds	r0, #0xf4                         @ 08003ACE
	ldr	r0, [r0]                           @ 08003AD0
	lsls	r0, r0, #2                        @ 08003AD2
	ldr	r3, .Llit08003CA4                  @ 08003AD4  =mcInstTable
	adds	r0, r0, r3                        @ 08003AD6
	ldr	r7, [r0]                           @ 08003AD8
	ldr	r1, [r7, #4]                       @ 08003ADA
	ldr	r0, [r7, #8]                       @ 08003ADC
	lsls	r0, r0, #8                        @ 08003ADE
	adds	r1, r1, r0                        @ 08003AE0
	lsls	r1, r1, #0x10                     @ 08003AE2
	lsrs	r2, r1, #0x10                     @ 08003AE4
	ldr	r5, [r7, #0x10]                    @ 08003AE6
	cmp	r5, #0                             @ 08003AE8
	beq	.L08003B10                         @ 08003AEA
	movs	r0, #0xff                         @ 08003AEC
	ands	r2, r0                            @ 08003AEE
	ldrh	r4, [r5]                          @ 08003AF0
	lsls	r0, r4, #8                        @ 08003AF2
	orrs	r2, r0                            @ 08003AF4
	lsls	r0, r2, #0x10                     @ 08003AF6
	lsrs	r2, r0, #0x10                     @ 08003AF8
	movs	r1, #0x84                         @ 08003AFA
	lsls	r1, r1, #1                        @ 08003AFC
	adds	r0, r6, r1                        @ 08003AFE
	movs	r3, #0                            @ 08003B00
	str	r3, [r0]                           @ 08003B02
	movs	r4, #0x86                         @ 08003B04
	lsls	r4, r4, #1                        @ 08003B06
	adds	r1, r6, r4                        @ 08003B08
	movs	r3, #2                            @ 08003B0A
	ldrsh	r0, [r5, r3]                     @ 08003B0C
	str	r0, [r1]                           @ 08003B0E
.L08003B10:
	adds	r3, r6, #0                        @ 08003B10
	adds	r3, #0xdc                         @ 08003B12
	ldr	r0, [r3]                           @ 08003B14
	cmp	r0, #0                             @ 08003B16
	beq	.L08003B1E                         @ 08003B18
	ldr	r0, .Llit08003CA8                  @ 08003B1A  =REG_SOUND4CNT_L
	strh	r2, [r0]                          @ 08003B1C
.L08003B1E:
	ldr	r0, [r7]                           @ 08003B1E
	lsls	r0, r0, #0x18                     @ 08003B20
	lsrs	r2, r0, #0x10                     @ 08003B22
	ldr	r5, [r7, #0x18]                    @ 08003B24
	cmp	r5, #0                             @ 08003B26
	beq	mcUpdate_noteOn_ch5                @ 08003B28
	ldrh	r4, [r5]                          @ 08003B2A
	ldr	r7, .Llit08003CAC                  @ 08003B2C  =0xFFFF8000
	adds	r0, r4, r7                        @ 08003B2E
	orrs	r2, r0                            @ 08003B30
	lsls	r0, r2, #0x10                     @ 08003B32
	lsrs	r2, r0, #0x10                     @ 08003B34
	movs	r1, #0x88                         @ 08003B36
	lsls	r1, r1, #1                        @ 08003B38
	adds	r0, r6, r1                        @ 08003B3A
	movs	r4, #0                            @ 08003B3C
	str	r4, [r0]                           @ 08003B3E
	movs	r7, #0x8a                         @ 08003B40
	lsls	r7, r7, #1                        @ 08003B42
	adds	r1, r6, r7                        @ 08003B44
	movs	r4, #2                            @ 08003B46
	ldrsh	r0, [r5, r4]                     @ 08003B48
	str	r0, [r1]                           @ 08003B4A
	ldr	r0, [r3]                           @ 08003B4C
	cmp	r0, #0                             @ 08003B4E
	beq	mcUpdate_noteOn_ch5                @ 08003B50
	ldr	r0, .Llit08003CB0                  @ 08003B52  =REG_SOUND4CNT_H
	strh	r2, [r0]                          @ 08003B54
mcUpdate_noteOn_ch5:
	mov	r5, sl                             @ 08003B56
	cmp	r5, #4                             @ 08003B58
	bne	mcUpdate_noteOn_ch6                @ 08003B5A
	movs	r7, #0x9a                         @ 08003B5C
	lsls	r7, r7, #1                        @ 08003B5E
	adds	r3, r6, r7                        @ 08003B60
	ldr	r2, [r3]                           @ 08003B62
	cmp	r2, #0x5f                          @ 08003B64
	bhi	mcUpdate_noteOn_ch6                @ 08003B66  note > 0x5F (rest): no trigger
	movs	r0, #0x9e                         @ 08003B68
	lsls	r0, r0, #1                        @ 08003B6A
	adds	r5, r6, r0                        @ 08003B6C
	ldr	r0, [r5]                           @ 08003B6E
	lsls	r0, r0, #3                        @ 08003B70
	ldr	r1, .Llit08003CB4                  @ 08003B72  =mcSmpInstTable
	adds	r1, #4                            @ 08003B74
	adds	r0, r0, r1                        @ 08003B76
	ldr	r7, [r0]                           @ 08003B78
	lsls	r0, r2, #1                        @ 08003B7A
	adds	r0, r0, r2                        @ 08003B7C
	lsls	r0, r0, #2                        @ 08003B7E
	ldr	r1, .Llit08003CB8                  @ 08003B80  =mcSmpNoteTable
	adds	r1, #4                            @ 08003B82
	adds	r0, r0, r1                        @ 08003B84
	ldr	r1, [r0]                           @ 08003B86
	movs	r2, #0xa8                         @ 08003B88
	lsls	r2, r2, #1                        @ 08003B8A
	adds	r4, r6, r2                        @ 08003B8C
	adds	r0, r7, #0                        @ 08003B8E
	str	r3, [sp, #0x2c]                    @ 08003B90
	bl	__udivsi3                           @ 08003B92  frames = length / samplesPerFrame
	str	r0, [r4]                           @ 08003B96
	movs	r4, #0xaa                         @ 08003B98
	lsls	r4, r4, #1                        @ 08003B9A
	adds	r1, r6, r4                        @ 08003B9C
	str	r0, [r1]                           @ 08003B9E
	ldr	r3, [sp, #0x2c]                    @ 08003BA0
	ldr	r1, [r3]                           @ 08003BA2
	lsls	r0, r1, #1                        @ 08003BA4
	adds	r0, r0, r1                        @ 08003BA6
	lsls	r0, r0, #2                        @ 08003BA8
	ldr	r7, .Llit08003CBC                  @ 08003BAA  =mcSmpNoteTable+0x8
	adds	r0, r0, r7                        @ 08003BAC
	ldr	r7, [r0]                           @ 08003BAE
	ldr	r3, .Llit08003CC0                  @ 08003BB0  =REG_TM0CNT
	movs	r0, #0                            @ 08003BB2
	str	r0, [r3]                           @ 08003BB4
	ldr	r2, .Llit08003CC4                  @ 08003BB6  =REG_DMA1CNT
	ldr	r0, .Llit08003CC8                  @ 08003BB8  =DMA_STOP_TRICK
	str	r0, [r2]                           @ 08003BBA
	ldr	r0, [r2]                           @ 08003BBC
	ldr	r1, .Llit08003CCC                  @ 08003BBE  =REG_DMA1CNT_H
	movs	r4, #0x88                         @ 08003BC0
	lsls	r4, r4, #3                        @ 08003BC2
	adds	r0, r4, #0                        @ 08003BC4
	strh	r0, [r1]                          @ 08003BC6
	subs	r1, #0xa                          @ 08003BC8
	ldr	r0, [r5]                           @ 08003BCA
	lsls	r0, r0, #3                        @ 08003BCC
	ldr	r5, .Llit08003CB4                  @ 08003BCE  =mcSmpInstTable
	adds	r0, r0, r5                        @ 08003BD0
	ldr	r0, [r0]                           @ 08003BD2
	str	r0, [r1]                           @ 08003BD4
	adds	r1, #4                            @ 08003BD6
	ldr	r0, .Llit08003CD0                  @ 08003BD8  =REG_FIFO_A
	str	r0, [r1]                           @ 08003BDA
	ldr	r0, .Llit08003CD4                  @ 08003BDC  =DMA_FIFO_START_A
	str	r0, [r2]                           @ 08003BDE
	movs	r0, #0x81                         @ 08003BE0
	lsls	r0, r0, #0x10                     @ 08003BE2
	subs	r0, r0, r7                        @ 08003BE4
	str	r0, [r3]                           @ 08003BE6  TM0CNT = 0x810000 - period
mcUpdate_noteOn_ch6:
	mov	r7, sl                             @ 08003BE8
	cmp	r7, #5                             @ 08003BEA
	bne	mcUpdate_chanTail                  @ 08003BEC
	movs	r0, #0xbe                         @ 08003BEE
	lsls	r0, r0, #1                        @ 08003BF0
	adds	r3, r6, r0                        @ 08003BF2
	ldr	r2, [r3]                           @ 08003BF4
	cmp	r2, #0x5f                          @ 08003BF6
	bhi	mcUpdate_chanTail                  @ 08003BF8  note > 0x5F (rest): no trigger
	movs	r1, #0xc2                         @ 08003BFA
	lsls	r1, r1, #1                        @ 08003BFC
	adds	r5, r6, r1                        @ 08003BFE
	ldr	r0, [r5]                           @ 08003C00
	lsls	r0, r0, #3                        @ 08003C02
	ldr	r1, .Llit08003CB4                  @ 08003C04  =mcSmpInstTable
	adds	r1, #4                            @ 08003C06
	adds	r0, r0, r1                        @ 08003C08
	ldr	r7, [r0]                           @ 08003C0A
	lsls	r0, r2, #1                        @ 08003C0C
	adds	r0, r0, r2                        @ 08003C0E
	lsls	r0, r0, #2                        @ 08003C10
	ldr	r1, .Llit08003CB8                  @ 08003C12  =mcSmpNoteTable
	adds	r1, #4                            @ 08003C14
	adds	r0, r0, r1                        @ 08003C16
	ldr	r1, [r0]                           @ 08003C18
	movs	r2, #0xcc                         @ 08003C1A
	lsls	r2, r2, #1                        @ 08003C1C
	adds	r4, r6, r2                        @ 08003C1E
	adds	r0, r7, #0                        @ 08003C20
	str	r3, [sp, #0x2c]                    @ 08003C22
	bl	__udivsi3                           @ 08003C24  frames = length / samplesPerFrame
	str	r0, [r4]                           @ 08003C28
	movs	r4, #0xce                         @ 08003C2A
	lsls	r4, r4, #1                        @ 08003C2C
	adds	r1, r6, r4                        @ 08003C2E
	str	r0, [r1]                           @ 08003C30
	ldr	r3, [sp, #0x2c]                    @ 08003C32
	ldr	r1, [r3]                           @ 08003C34
	lsls	r0, r1, #1                        @ 08003C36
	adds	r0, r0, r1                        @ 08003C38
	lsls	r0, r0, #2                        @ 08003C3A
	ldr	r7, .Llit08003CBC                  @ 08003C3C  =mcSmpNoteTable+0x8
	adds	r0, r0, r7                        @ 08003C3E
	ldr	r7, [r0]                           @ 08003C40
	ldr	r3, .Llit08003CD8                  @ 08003C42  =REG_TM1CNT
	movs	r0, #0                            @ 08003C44
	str	r0, [r3]                           @ 08003C46
	ldr	r2, .Llit08003CDC                  @ 08003C48  =REG_DMA2CNT
	ldr	r0, .Llit08003CC8                  @ 08003C4A  =DMA_STOP_TRICK
	str	r0, [r2]                           @ 08003C4C
	ldr	r0, [r2]                           @ 08003C4E
	ldr	r1, .Llit08003CE0                  @ 08003C50  =REG_DMA2CNT_H
	movs	r4, #0x88                         @ 08003C52
	lsls	r4, r4, #3                        @ 08003C54
	adds	r0, r4, #0                        @ 08003C56
	strh	r0, [r1]                          @ 08003C58
	subs	r1, #0xa                          @ 08003C5A
	ldr	r0, [r5]                           @ 08003C5C
	lsls	r0, r0, #3                        @ 08003C5E
	ldr	r5, .Llit08003CB4                  @ 08003C60  =mcSmpInstTable
	adds	r0, r0, r5                        @ 08003C62
	ldr	r0, [r0]                           @ 08003C64
	str	r0, [r1]                           @ 08003C66
	adds	r1, #4                            @ 08003C68
	ldr	r0, .Llit08003CE4                  @ 08003C6A  =REG_FIFO_B
	str	r0, [r1]                           @ 08003C6C
	ldr	r0, .Llit08003CD4                  @ 08003C6E  =DMA_FIFO_START_A
	str	r0, [r2]                           @ 08003C70
	movs	r0, #0x81                         @ 08003C72
	lsls	r0, r0, #0x10                     @ 08003C74
	subs	r0, r0, r7                        @ 08003C76
	str	r0, [r3]                           @ 08003C78  TM1CNT = 0x810000 - period
mcUpdate_chanTail:
	ldr	r7, [sp]                           @ 08003C7A
	cmp	r7, #0x65                          @ 08003C7C
	bne	mcUpdate_seqNextChan               @ 08003C7E
	bl	mcUpdate_seqChanRetry               @ 08003C80  far branch: re-run this channel
mcUpdate_seqNextChan:
	ldr	r0, [sp, #0x24]                    @ 08003C84
	mov	sl, r0                             @ 08003C86
	cmp	r0, #5                             @ 08003C88
	bgt	mcUpdate_exit                      @ 08003C8A
	bl	mcUpdate_seqChanLoop                @ 08003C8C  far branch: next channel
mcUpdate_exit:
	add	sp, #0x30                          @ 08003C90
	pop	{r3, r4, r5}                       @ 08003C92
	mov	r8, r3                             @ 08003C94
	mov	sb, r4                             @ 08003C96
	mov	sl, r5                             @ 08003C98
	pop	{r4, r5, r6, r7}                   @ 08003C9A
	pop	{r0}                               @ 08003C9C
	bx	r0                                  @ 08003C9E
.Llit08003CA0:
	.word	REG_SOUND3CNT_X                  @ 08003CA0  = 0x04000074
.Llit08003CA4:
	.word	mcInstTable                      @ 08003CA4  = 0x08027A74
.Llit08003CA8:
	.word	REG_SOUND4CNT_L                  @ 08003CA8  = 0x04000078
.Llit08003CAC:
	.word	0xFFFF8000                       @ 08003CAC
.Llit08003CB0:
	.word	REG_SOUND4CNT_H                  @ 08003CB0  = 0x0400007C
.Llit08003CB4:
	.word	mcSmpInstTable                   @ 08003CB4  = 0x0801AB68
.Llit08003CB8:
	.word	mcSmpNoteTable                   @ 08003CB8  = 0x08016790
.Llit08003CBC:
	.word	mcSmpNoteTable+0x8               @ 08003CBC  = 0x08016798
.Llit08003CC0:
	.word	REG_TM0CNT                       @ 08003CC0  = 0x04000100
.Llit08003CC4:
	.word	REG_DMA1CNT                      @ 08003CC4  = 0x040000C4
.Llit08003CC8:
	.word	DMA_STOP_TRICK                   @ 08003CC8  = 0x84400004
.Llit08003CCC:
	.word	REG_DMA1CNT_H                    @ 08003CCC  = 0x040000C6
.Llit08003CD0:
	.word	REG_FIFO_A                       @ 08003CD0  = 0x040000A0
.Llit08003CD4:
	.word	DMA_FIFO_START_A                 @ 08003CD4  = 0xBE400000
.Llit08003CD8:
	.word	REG_TM1CNT                       @ 08003CD8  = 0x04000104
.Llit08003CDC:
	.word	REG_DMA2CNT                      @ 08003CDC  = 0x040000D0
.Llit08003CE0:
	.word	REG_DMA2CNT_H                    @ 08003CE0  = 0x040000D2
.Llit08003CE4:
	.word	REG_FIFO_B                       @ 08003CE4  = 0x040000A4
