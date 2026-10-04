@ ============================================================================
@ et_sfxwav.s -- WAV sound-effect player and music glue, E.T.: The
@                Extra-Terrestrial (GBA, 2001)
@
@ Reconstructed from "E.T. - The Extra-Terrestrial (E) (M6).gba", ROM range
@ 0x08004944-0x08004DBC (1 144 bytes); reassembles byte for byte with
@ et_sound.ld.
@
@ This is a separate translation unit from the music driver.  It reads the
@ game's state struct (gGame) and plays the game's sound effects, which are
@ complete RIFF/WAV files stored in ROM, on the two DirectSound FIFOs.  It
@ uses the same DMA idioms as the music driver, so it may be Cooksey's too,
@ but that is not proven -- it could equally be game-side code.
@
@ Hardware: DMA1 -> FIFO A clocked by Timer 0, DMA2 -> FIFO B clocked by
@ Timer 1 (the same resources as music channels 5/6), plus Timer 2 / Timer 3
@ as one-shot length counters that raise an IRQ when the sample is over.
@ IntrTable[5] = SfxTimer2IRQ and IntrTable[6] = SfxTimer3IRQ are installed
@ by main (0x08005430).
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

	.section .text.et_sfxwav, "ax", %progbits
	.balign 4
	@ linked at 0x08004944 by et_sound.ld
	.extern mcPlaySong

@ --------------------------------------------------------------------------
@ PlayMusic  (0x08004944)
@   Remember song r0 in game state and start it unless music is disabled
@   void PlayMusic(u16 song) { gGame.curSong = song; if (!gGame.musicOff) mcPlaySong(song); }
@ --------------------------------------------------------------------------
	.thumb_func
	.global PlayMusic
PlayMusic:
	push	{lr}                              @ 08004944
	lsls	r0, r0, #0x10                     @ 08004946
	lsrs	r1, r0, #0x10                     @ 08004948
	ldr	r0, .Llit08004960                  @ 0800494A  =gGame
	strb	r1, [r0, #0x13]                   @ 0800494C
	ldrb	r0, [r0, #0x14]                   @ 0800494E
	cmp	r0, #0                             @ 08004950
	bne	.L0800495A                         @ 08004952
	adds	r0, r1, #0                        @ 08004954
	bl	mcPlaySong                          @ 08004956
.L0800495A:
	pop	{r0}                               @ 0800495A
	bx	r0                                  @ 0800495C
	.hword	0x0000                          @ 0800495E  (padding)
.Llit08004960:
	.word	gGame                            @ 08004960  = 0x03002CE0

@ --------------------------------------------------------------------------
@ StopMusic  (0x08004964)
@   Kill the DMA sample channels if song 15 was playing, then start song 0 (silence)
@   void StopMusic(void)
@     if (gGame.curSong == 15) { stop DMA1 and DMA2 }   song 15 is the only song
@                                                        with sample channels, and
@                                                        the driver never stops them
@     mcPlaySong(0)                                      song 0 = one silent note
@ --------------------------------------------------------------------------
	.thumb_func
	.global StopMusic
StopMusic:
	push	{lr}                              @ 08004964
	ldr	r0, .Llit08004994                  @ 08004966  =gGame
	ldrb	r0, [r0, #0x13]                   @ 08004968
	cmp	r0, #0xf                           @ 0800496A
	bne	.L0800498A                         @ 0800496C
	ldr	r0, .Llit08004998                  @ 0800496E  =REG_DMA1CNT
	ldr	r2, .Llit0800499C                  @ 08004970  =DMA_STOP_TRICK
	str	r2, [r0]                           @ 08004972
	ldr	r0, [r0]                           @ 08004974
	ldr	r0, .Llit080049A0                  @ 08004976  =REG_DMA1CNT_H
	movs	r3, #0x88                         @ 08004978
	lsls	r3, r3, #3                        @ 0800497A
	adds	r1, r3, #0                        @ 0800497C
	strh	r1, [r0]                          @ 0800497E
	adds	r0, #0xa                          @ 08004980
	str	r2, [r0]                           @ 08004982
	ldr	r0, [r0]                           @ 08004984
	ldr	r0, .Llit080049A4                  @ 08004986  =REG_DMA2CNT_H
	strh	r1, [r0]                          @ 08004988
.L0800498A:
	movs	r0, #0                            @ 0800498A
	bl	mcPlaySong                          @ 0800498C
	pop	{r0}                               @ 08004990
	bx	r0                                  @ 08004992
.Llit08004994:
	.word	gGame                            @ 08004994  = 0x03002CE0
.Llit08004998:
	.word	REG_DMA1CNT                      @ 08004998  = 0x040000C4
.Llit0800499C:
	.word	DMA_STOP_TRICK                   @ 0800499C  = 0x84400004
.Llit080049A0:
	.word	REG_DMA1CNT_H                    @ 080049A0  = 0x040000C6
.Llit080049A4:
	.word	REG_DMA2CNT_H                    @ 080049A4  = 0x040000D2

@ --------------------------------------------------------------------------
@ PlaySfxUnique  (0x080049A8)
@   Request SFX r0 unless it is already playing on either channel
@   void PlaySfxUnique(int n)
@     if (!gGame.sfxOff && n != gSfx.idA && n != gSfx.idB) PlaySfx(n)
@ --------------------------------------------------------------------------
	.thumb_func
	.global PlaySfxUnique
PlaySfxUnique:
	push	{lr}                              @ 080049A8
	adds	r1, r0, #0                        @ 080049AA
	ldr	r0, .Llit080049CC                  @ 080049AC  =gGame
	ldrb	r0, [r0, #0x15]                   @ 080049AE
	cmp	r0, #0                             @ 080049B0
	bne	.L080049C8                         @ 080049B2
	ldr	r0, .Llit080049D0                  @ 080049B4  =gSfx
	ldrh	r2, [r0, #4]                      @ 080049B6
	cmp	r1, r2                             @ 080049B8
	beq	.L080049C8                         @ 080049BA
	ldrh	r0, [r0, #6]                      @ 080049BC
	cmp	r1, r0                             @ 080049BE
	beq	.L080049C8                         @ 080049C0
	adds	r0, r1, #0                        @ 080049C2
	bl	PlaySfx                             @ 080049C4
.L080049C8:
	pop	{r0}                               @ 080049C8
	bx	r0                                  @ 080049CA
.Llit080049CC:
	.word	gGame                            @ 080049CC  = 0x03002CE0
.Llit080049D0:
	.word	gSfx                             @ 080049D0  = 0x03002CB0

@ --------------------------------------------------------------------------
@ PlaySfx  (0x080049D4)
@   Request SFX r0 (latched, started on next VBlank; highest priority wins)
@   void PlaySfx(int n)            -- only latches a request; SfxVBlank starts it
@     if (gGame.sfxOff || gGame.curSong == 15) return
@     p = SfxTable[n].priority
@     if (gSfx.reqPrioA <= gSfx.reqPrioB) { if (p > reqPrioA) { reqPrioA = p; reqIdA = n } }
@     else                                { if (p > reqPrioB) { reqPrioB = p; reqIdB = n } }
@ --------------------------------------------------------------------------
	.thumb_func
	.global PlaySfx
PlaySfx:
	push	{r4, r5, lr}                      @ 080049D4
	adds	r4, r0, #0                        @ 080049D6
	ldr	r1, .Llit08004A04                  @ 080049D8  =gGame
	ldrb	r0, [r1, #0x15]                   @ 080049DA
	cmp	r0, #0                             @ 080049DC
	bne	.L08004A20                         @ 080049DE
	ldrb	r1, [r1, #0x13]                   @ 080049E0
	cmp	r1, #0xf                           @ 080049E2
	beq	.L08004A20                         @ 080049E4
	ldr	r5, .Llit08004A08                  @ 080049E6  =gSfx
	ldrb	r3, [r5, #2]                      @ 080049E8
	ldrb	r2, [r5, #3]                      @ 080049EA
	cmp	r3, r2                             @ 080049EC
	bhi	.L08004A10                         @ 080049EE
	ldr	r1, .Llit08004A0C                  @ 080049F0  =SfxTable
	lsls	r0, r4, #3                        @ 080049F2
	adds	r0, r0, r1                        @ 080049F4
	ldrb	r0, [r0]                          @ 080049F6
	cmp	r0, r3                             @ 080049F8
	bls	.L08004A20                         @ 080049FA
	strb	r0, [r5, #2]                      @ 080049FC
	strh	r4, [r5, #8]                      @ 080049FE
	b	.L08004A20                           @ 08004A00
	.hword	0x0000                          @ 08004A02  (padding)
.Llit08004A04:
	.word	gGame                            @ 08004A04  = 0x03002CE0
.Llit08004A08:
	.word	gSfx                             @ 08004A08  = 0x03002CB0
.Llit08004A0C:
	.word	SfxTable                         @ 08004A0C  = 0x080284FC
.L08004A10:
	ldr	r1, .Llit08004A28                  @ 08004A10  =SfxTable
	lsls	r0, r4, #3                        @ 08004A12
	adds	r0, r0, r1                        @ 08004A14
	ldrb	r0, [r0]                          @ 08004A16
	cmp	r0, r2                             @ 08004A18
	bls	.L08004A20                         @ 08004A1A
	strb	r0, [r5, #3]                      @ 08004A1C
	strh	r4, [r5, #0xa]                    @ 08004A1E
.L08004A20:
	pop	{r4, r5}                           @ 08004A20
	pop	{r0}                               @ 08004A22
	bx	r0                                  @ 08004A24
	.hword	0x0000                          @ 08004A26  (padding)
.Llit08004A28:
	.word	SfxTable                         @ 08004A28  = 0x080284FC

@ --------------------------------------------------------------------------
@ SfxVBlank  (0x08004A2C)
@   Per-frame: start the (up to two) SFX requested this frame
@   for each of the two requests with a non-zero priority:
@     *SfxStartWav(SfxTable[id].wav, SfxTable[id].pitch, SfxTable[id].pan, prio) = id
@   then clear both requests.
@ --------------------------------------------------------------------------
	.thumb_func
	.global SfxVBlank
SfxVBlank:
	push	{r4, lr}                          @ 08004A2C
	ldr	r4, .Llit08004A84                  @ 08004A2E  =gSfx
	ldrb	r0, [r4, #2]                      @ 08004A30
	cmp	r0, #0                             @ 08004A32
	beq	.L08004A54                         @ 08004A34
	ldr	r1, .Llit08004A88                  @ 08004A36  =SfxTable
	ldrh	r0, [r4, #8]                      @ 08004A38
	lsls	r2, r0, #3                        @ 08004A3A
	adds	r0, r1, #4                        @ 08004A3C
	adds	r0, r2, r0                        @ 08004A3E
	ldr	r0, [r0]                           @ 08004A40
	adds	r2, r2, r1                        @ 08004A42
	ldrh	r1, [r2, #2]                      @ 08004A44
	ldrb	r2, [r2, #1]                      @ 08004A46
	ldrb	r3, [r4, #2]                      @ 08004A48
	bl	SfxStartWav                         @ 08004A4A  r0=wav r1=pitch r2=pan r3=prio
	adds	r1, r0, #0                        @ 08004A4E
	ldrh	r0, [r4, #8]                      @ 08004A50
	strh	r0, [r1]                          @ 08004A52  *slot = sfx id
.L08004A54:
	ldrb	r0, [r4, #3]                      @ 08004A54
	cmp	r0, #0                             @ 08004A56
	beq	.L08004A78                         @ 08004A58
	ldr	r1, .Llit08004A88                  @ 08004A5A  =SfxTable
	ldrh	r0, [r4, #0xa]                    @ 08004A5C
	lsls	r2, r0, #3                        @ 08004A5E
	adds	r0, r1, #4                        @ 08004A60
	adds	r0, r2, r0                        @ 08004A62
	ldr	r0, [r0]                           @ 08004A64
	adds	r2, r2, r1                        @ 08004A66
	ldrh	r1, [r2, #2]                      @ 08004A68
	ldrb	r2, [r2, #1]                      @ 08004A6A
	ldrb	r3, [r4, #3]                      @ 08004A6C
	bl	SfxStartWav                         @ 08004A6E
	adds	r1, r0, #0                        @ 08004A72
	ldrh	r0, [r4, #0xa]                    @ 08004A74
	strh	r0, [r1]                          @ 08004A76
.L08004A78:
	movs	r0, #0                            @ 08004A78
	strb	r0, [r4, #3]                      @ 08004A7A
	strb	r0, [r4, #2]                      @ 08004A7C
	pop	{r4}                               @ 08004A7E
	pop	{r0}                               @ 08004A80
	bx	r0                                  @ 08004A82
.Llit08004A84:
	.word	gSfx                             @ 08004A84  = 0x03002CB0
.Llit08004A88:
	.word	SfxTable                         @ 08004A88  = 0x080284FC

@ --------------------------------------------------------------------------
@ SfxTimer2IRQ  (0x08004A8C)
@   Timer 2 IRQ: length counter for WAV channel A (DirectSound A)
@   IME = 0; TM2CNT = 0
@   gSfx.ticksA -= 0x10000
@   if (ticksA <= 0)        stop TM0 + DMA1, prioA = 0, idA = 0      (sample finished)
@   else if (<= 0x10000)    TM2CNT = 0xC40000 - ticksA   (= 0xC3 control, reload 0x10000-ticksA)
@   else                    TM2CNT = 0x00C30002
@   IME = 1
@ --------------------------------------------------------------------------
	.thumb_func
	.global SfxTimer2IRQ
SfxTimer2IRQ:
	push	{r4, r5, r6, lr}                  @ 08004A8C
	ldr	r0, .Llit08004AC4                  @ 08004A8E  =REG_IME
	movs	r5, #0                            @ 08004A90
	strh	r5, [r0]                          @ 08004A92
	ldr	r3, .Llit08004AC8                  @ 08004A94  =REG_TM2CNT
	movs	r4, #0                            @ 08004A96
	str	r4, [r3]                           @ 08004A98
	ldr	r2, .Llit08004ACC                  @ 08004A9A  =gSfx
	ldr	r0, [r2, #0xc]                     @ 08004A9C
	ldr	r6, .Llit08004AD0                  @ 08004A9E  =0xFFFF0000
	adds	r1, r0, r6                        @ 08004AA0  ticksA -= 0x10000
	str	r1, [r2, #0xc]                     @ 08004AA2
	cmp	r1, #0                             @ 08004AA4
	bgt	.L08004AE0                         @ 08004AA6
	ldr	r0, .Llit08004AD4                  @ 08004AA8  =REG_TM0CNT
	str	r4, [r0]                           @ 08004AAA
	ldr	r1, .Llit08004AD8                  @ 08004AAC  =REG_DMA1CNT
	ldr	r0, .Llit08004ADC                  @ 08004AAE  =DMA_STOP_TRICK
	str	r0, [r1]                           @ 08004AB0
	ldr	r0, [r1]                           @ 08004AB2
	adds	r1, #2                            @ 08004AB4
	movs	r3, #0x88                         @ 08004AB6
	lsls	r3, r3, #3                        @ 08004AB8
	adds	r0, r3, #0                        @ 08004ABA
	strh	r0, [r1]                          @ 08004ABC
	strb	r5, [r2]                          @ 08004ABE
	strh	r4, [r2, #4]                      @ 08004AC0
	b	.L08004AF4                           @ 08004AC2
.Llit08004AC4:
	.word	REG_IME                          @ 08004AC4  = 0x04000208
.Llit08004AC8:
	.word	REG_TM2CNT                       @ 08004AC8  = 0x04000108
.Llit08004ACC:
	.word	gSfx                             @ 08004ACC  = 0x03002CB0
.Llit08004AD0:
	.word	0xFFFF0000                       @ 08004AD0
.Llit08004AD4:
	.word	REG_TM0CNT                       @ 08004AD4  = 0x04000100
.Llit08004AD8:
	.word	REG_DMA1CNT                      @ 08004AD8  = 0x040000C4
.Llit08004ADC:
	.word	DMA_STOP_TRICK                   @ 08004ADC  = 0x84400004
.L08004AE0:
	movs	r0, #0x80                         @ 08004AE0
	lsls	r0, r0, #9                        @ 08004AE2
	cmp	r1, r0                             @ 08004AE4
	bgt	.L08004AF0                         @ 08004AE6
	movs	r0, #0xc4                         @ 08004AE8
	lsls	r0, r0, #0x10                     @ 08004AEA
	subs	r0, r0, r1                        @ 08004AEC  TM2CNT = 0xC40000 - ticks
	b	.L08004AF2                           @ 08004AEE
.L08004AF0:
	ldr	r0, .Llit08004B00                  @ 08004AF0  =0xC30002
.L08004AF2:
	str	r0, [r3]                           @ 08004AF2
.L08004AF4:
	ldr	r1, .Llit08004B04                  @ 08004AF4  =REG_IME
	movs	r0, #1                            @ 08004AF6
	strh	r0, [r1]                          @ 08004AF8
	pop	{r4, r5, r6}                       @ 08004AFA
	pop	{r0}                               @ 08004AFC
	bx	r0                                  @ 08004AFE
.Llit08004B00:
	.word	0x00C30002                       @ 08004B00
.Llit08004B04:
	.word	REG_IME                          @ 08004B04  = 0x04000208

@ --------------------------------------------------------------------------
@ SfxTimer3IRQ  (0x08004B08)
@   Timer 3 IRQ: length counter for WAV channel B (DirectSound B)
@   Timer 3 twin of SfxTimer2IRQ for channel B (TM1 / DMA2 / ticksB).
@ --------------------------------------------------------------------------
	.thumb_func
	.global SfxTimer3IRQ
SfxTimer3IRQ:
	push	{r4, r5, r6, lr}                  @ 08004B08
	ldr	r0, .Llit08004B40                  @ 08004B0A  =REG_IME
	movs	r5, #0                            @ 08004B0C
	strh	r5, [r0]                          @ 08004B0E
	ldr	r3, .Llit08004B44                  @ 08004B10  =REG_TM3CNT
	movs	r4, #0                            @ 08004B12
	str	r4, [r3]                           @ 08004B14
	ldr	r2, .Llit08004B48                  @ 08004B16  =gSfx
	ldr	r0, [r2, #0x10]                    @ 08004B18
	ldr	r6, .Llit08004B4C                  @ 08004B1A  =0xFFFF0000
	adds	r1, r0, r6                        @ 08004B1C
	str	r1, [r2, #0x10]                    @ 08004B1E
	cmp	r1, #0                             @ 08004B20
	bgt	.L08004B5C                         @ 08004B22
	ldr	r0, .Llit08004B50                  @ 08004B24  =REG_TM1CNT
	str	r4, [r0]                           @ 08004B26
	ldr	r1, .Llit08004B54                  @ 08004B28  =REG_DMA2CNT
	ldr	r0, .Llit08004B58                  @ 08004B2A  =DMA_STOP_TRICK
	str	r0, [r1]                           @ 08004B2C
	ldr	r0, [r1]                           @ 08004B2E
	adds	r1, #2                            @ 08004B30
	movs	r3, #0x88                         @ 08004B32
	lsls	r3, r3, #3                        @ 08004B34
	adds	r0, r3, #0                        @ 08004B36
	strh	r0, [r1]                          @ 08004B38
	strb	r5, [r2, #1]                      @ 08004B3A
	strh	r4, [r2, #6]                      @ 08004B3C
	b	.L08004B70                           @ 08004B3E
.Llit08004B40:
	.word	REG_IME                          @ 08004B40  = 0x04000208
.Llit08004B44:
	.word	REG_TM3CNT                       @ 08004B44  = 0x0400010C
.Llit08004B48:
	.word	gSfx                             @ 08004B48  = 0x03002CB0
.Llit08004B4C:
	.word	0xFFFF0000                       @ 08004B4C
.Llit08004B50:
	.word	REG_TM1CNT                       @ 08004B50  = 0x04000104
.Llit08004B54:
	.word	REG_DMA2CNT                      @ 08004B54  = 0x040000D0
.Llit08004B58:
	.word	DMA_STOP_TRICK                   @ 08004B58  = 0x84400004
.L08004B5C:
	movs	r0, #0x80                         @ 08004B5C
	lsls	r0, r0, #9                        @ 08004B5E
	cmp	r1, r0                             @ 08004B60
	bgt	.L08004B6C                         @ 08004B62
	movs	r0, #0xc4                         @ 08004B64
	lsls	r0, r0, #0x10                     @ 08004B66
	subs	r0, r0, r1                        @ 08004B68
	b	.L08004B6E                           @ 08004B6A
.L08004B6C:
	ldr	r0, .Llit08004B7C                  @ 08004B6C  =0xC30002
.L08004B6E:
	str	r0, [r3]                           @ 08004B6E
.L08004B70:
	ldr	r1, .Llit08004B80                  @ 08004B70  =REG_IME
	movs	r0, #1                            @ 08004B72
	strh	r0, [r1]                          @ 08004B74
	pop	{r4, r5, r6}                       @ 08004B76
	pop	{r0}                               @ 08004B78
	bx	r0                                  @ 08004B7A
.Llit08004B7C:
	.word	0x00C30002                       @ 08004B7C
.Llit08004B80:
	.word	REG_IME                          @ 08004B80  = 0x04000208

@ --------------------------------------------------------------------------
@ SfxInit  (0x08004B84)
@   Set SOUNDBIAS and final SOUNDCNT_H mixing (called from main after mcSoundInit)
@   SOUNDBIAS  = (SOUNDBIAS & 0x3FF) | 0x4000     8-bit resolution, 65.536 kHz PWM
@   SOUNDCNT_H = 0x8800 (reset both FIFOs), then 0x7301:
@                PSG 50%, DSA 50% L+R Timer0, DSB 50% L+R Timer1
@   This overrides the 0xFB0E written by mcSoundInit.
@ --------------------------------------------------------------------------
	.thumb_func
	.global SfxInit
SfxInit:
	ldr	r2, .Llit08004BA8                  @ 08004B84  =REG_SOUNDBIAS
	ldrh	r1, [r2]                          @ 08004B86
	ldr	r0, .Llit08004BAC                  @ 08004B88  =0x3FF
	ands	r0, r1                            @ 08004B8A
	movs	r3, #0x80                         @ 08004B8C
	lsls	r3, r3, #7                        @ 08004B8E
	adds	r1, r3, #0                        @ 08004B90
	orrs	r0, r1                            @ 08004B92
	strh	r0, [r2]                          @ 08004B94
	ldr	r1, .Llit08004BB0                  @ 08004B96  =REG_SOUNDCNT_H
	movs	r2, #0x88                         @ 08004B98
	lsls	r2, r2, #8                        @ 08004B9A
	adds	r0, r2, #0                        @ 08004B9C
	strh	r0, [r1]                          @ 08004B9E
	ldr	r3, .Llit08004BB4                  @ 08004BA0  =0x7301
	adds	r0, r3, #0                        @ 08004BA2
	strh	r0, [r1]                          @ 08004BA4
	bx	lr                                  @ 08004BA6
.Llit08004BA8:
	.word	REG_SOUNDBIAS                    @ 08004BA8  = 0x04000088
.Llit08004BAC:
	.word	0x000003FF                       @ 08004BAC
.Llit08004BB0:
	.word	REG_SOUNDCNT_H                   @ 08004BB0  = 0x04000082
.Llit08004BB4:
	.word	0x00007301                       @ 08004BB4

@ --------------------------------------------------------------------------
@ SfxStartWav  (0x08004BB8)
@   Allocate a DirectSound channel and start an embedded RIFF/WAV file on it
@   u16 *SfxStartWav(u8 *wav, int pitch, int pan, int prio)
@     channel steal: the lower-priority busy channel is freed if prio >= its priority
@     if (prioA == 0) use A  else if (prioB == 0) use B  else return &gSfxDummySlot
@     stop Tn, T(n+2), DMA; SOUNDCNT_H: DSx L/R bits = pan (0 both, 1 left, 2 right) + FIFO reset
@     prioX = prio
@     DMA SAD = wav + 0x2C (start of the 'data' payload), DAD = FIFO, CNT = 0xB6400004
@     rate   = (wav.sampleRate(+0x18) * pitch) >> 8
@     period = 0x1000000 / rate;  rate' = 0x1000000 / period
@     ticks  = wav.dataSize(+0x28) * 15800 / rate'   (length in 1024-cycle timer ticks)
@     T(n+2) = one-shot IRQ timer for 'ticks' (chunks of 0x10000)
@     Tn     = 0x810000 - period  (enable, reload 0x10000-period)
@     return &idA or &idB
@ --------------------------------------------------------------------------
	.thumb_func
	.global SfxStartWav
SfxStartWav:
	push	{r4, r5, r6, r7, lr}              @ 08004BB8
	adds	r7, r0, #0                        @ 08004BBA
	adds	r5, r1, #0                        @ 08004BBC
	ldr	r0, .Llit08004BD4                  @ 08004BBE  =gSfx
	adds	r6, r0, #0                        @ 08004BC0
	ldrb	r0, [r6]                          @ 08004BC2
	ldrb	r1, [r6, #1]                      @ 08004BC4
	cmp	r0, r1                             @ 08004BC6
	bhi	.L08004BD8                         @ 08004BC8  prioA <= prioB ?
	cmp	r3, r0                             @ 08004BCA
	blo	.L08004BE2                         @ 08004BCC
	movs	r0, #0                            @ 08004BCE  evict A
	strb	r0, [r6]                          @ 08004BD0
	b	.L08004BE2                           @ 08004BD2
.Llit08004BD4:
	.word	gSfx                             @ 08004BD4  = 0x03002CB0
.L08004BD8:
	ldrb	r4, [r6, #1]                      @ 08004BD8
	cmp	r3, r4                             @ 08004BDA
	blo	.L08004BE2                         @ 08004BDC
	movs	r0, #0                            @ 08004BDE
	strb	r0, [r6, #1]                      @ 08004BE0  evict B
.L08004BE2:
	ldrb	r1, [r6]                          @ 08004BE2
	cmp	r1, #0                             @ 08004BE4
	bne	.L08004CC8                         @ 08004BE6
	ldr	r0, .Llit08004C14                  @ 08004BE8  =REG_TM0CNT
	str	r1, [r0]                           @ 08004BEA
	adds	r0, #8                            @ 08004BEC
	str	r1, [r0]                           @ 08004BEE
	ldr	r1, .Llit08004C18                  @ 08004BF0  =REG_DMA1CNT
	ldr	r0, .Llit08004C1C                  @ 08004BF2  =DMA_STOP_TRICK
	str	r0, [r1]                           @ 08004BF4
	ldr	r0, [r1]                           @ 08004BF6
	adds	r1, #2                            @ 08004BF8
	movs	r4, #0x88                         @ 08004BFA
	lsls	r4, r4, #3                        @ 08004BFC
	adds	r0, r4, #0                        @ 08004BFE
	strh	r0, [r1]                          @ 08004C00
	subs	r1, #0x44                         @ 08004C02
	ldrh	r0, [r1]                          @ 08004C04
	ldr	r4, .Llit08004C20                  @ 08004C06  =0xFFFFFCFF
	ands	r4, r0                            @ 08004C08
	cmp	r2, #0                             @ 08004C0A
	bne	.L08004C24                         @ 08004C0C
	movs	r2, #0xb0                         @ 08004C0E
	lsls	r2, r2, #4                        @ 08004C10
	b	.L08004C32                           @ 08004C12
.Llit08004C14:
	.word	REG_TM0CNT                       @ 08004C14  = 0x04000100
.Llit08004C18:
	.word	REG_DMA1CNT                      @ 08004C18  = 0x040000C4
.Llit08004C1C:
	.word	DMA_STOP_TRICK                   @ 08004C1C  = 0x84400004
.Llit08004C20:
	.word	0xFFFFFCFF                       @ 08004C20
.L08004C24:
	cmp	r2, #1                             @ 08004C24
	bne	.L08004C2E                         @ 08004C26
	movs	r2, #0xa0                         @ 08004C28
	lsls	r2, r2, #4                        @ 08004C2A
	b	.L08004C32                           @ 08004C2C
.L08004C2E:
	movs	r2, #0x90                         @ 08004C2E
	lsls	r2, r2, #4                        @ 08004C30
.L08004C32:
	adds	r0, r2, #0                        @ 08004C32
	orrs	r4, r0                            @ 08004C34
	strh	r4, [r1]                          @ 08004C36  SOUNDCNT_H: DSA pan bits + FIFO A reset
	strb	r3, [r6]                          @ 08004C38
	ldr	r1, .Llit08004C90                  @ 08004C3A  =REG_DMA1SAD
	adds	r0, r7, #0                        @ 08004C3C
	adds	r0, #0x2c                         @ 08004C3E
	str	r0, [r1]                           @ 08004C40  DMA1SAD = wav + 0x2C
	adds	r1, #4                            @ 08004C42
	ldr	r0, .Llit08004C94                  @ 08004C44  =REG_FIFO_A
	str	r0, [r1]                           @ 08004C46
	adds	r1, #4                            @ 08004C48
	ldr	r0, .Llit08004C98                  @ 08004C4A  =DMA_FIFO_START_B
	str	r0, [r1]                           @ 08004C4C  DMA1CNT = 0xB6400004
	ldr	r0, [r7, #0x18]                    @ 08004C4E
	adds	r1, r0, #0                        @ 08004C50
	muls	r1, r5, r1                        @ 08004C52
	lsrs	r1, r1, #8                        @ 08004C54  rate = sampleRate * pitch >> 8
	movs	r4, #0x80                         @ 08004C56
	lsls	r4, r4, #0x11                     @ 08004C58
	adds	r0, r4, #0                        @ 08004C5A
	bl	__udivsi3                           @ 08004C5C  period = 0x1000000 / rate
	adds	r5, r0, #0                        @ 08004C60
	adds	r0, r4, #0                        @ 08004C62
	adds	r1, r5, #0                        @ 08004C64
	bl	__udivsi3                           @ 08004C66  rate' = 0x1000000 / period
	adds	r4, r0, #0                        @ 08004C6A
	ldr	r1, [r7, #0x28]                    @ 08004C6C
	ldr	r0, .Llit08004C9C                  @ 08004C6E  =0x3DB8
	muls	r0, r1, r0                        @ 08004C70
	adds	r1, r4, #0                        @ 08004C72
	bl	__udivsi3                           @ 08004C74  ticks = dataSize * 15800 / rate'
	adds	r2, r0, #0                        @ 08004C78
	str	r2, [r6, #0xc]                     @ 08004C7A
	movs	r0, #0x80                         @ 08004C7C
	lsls	r0, r0, #9                        @ 08004C7E
	cmp	r2, r0                             @ 08004C80
	bgt	.L08004CA4                         @ 08004C82
	ldr	r1, .Llit08004CA0                  @ 08004C84  =REG_TM2CNT
	movs	r0, #0xc4                         @ 08004C86
	lsls	r0, r0, #0x10                     @ 08004C88
	subs	r0, r0, r2                        @ 08004C8A
	b	.L08004CAA                           @ 08004C8C
	.hword	0x0000                          @ 08004C8E  (padding)
.Llit08004C90:
	.word	REG_DMA1SAD                      @ 08004C90  = 0x040000BC
.Llit08004C94:
	.word	REG_FIFO_A                       @ 08004C94  = 0x040000A0
.Llit08004C98:
	.word	DMA_FIFO_START_B                 @ 08004C98  = 0xB6400004
.Llit08004C9C:
	.word	0x00003DB8                       @ 08004C9C
.Llit08004CA0:
	.word	REG_TM2CNT                       @ 08004CA0  = 0x04000108
.L08004CA4:
	ldr	r1, .Llit08004CBC                  @ 08004CA4  =REG_TM2CNT
	movs	r0, #0xc3                         @ 08004CA6
	lsls	r0, r0, #0x10                     @ 08004CA8
.L08004CAA:
	str	r0, [r1]                           @ 08004CAA
	ldr	r1, .Llit08004CC0                  @ 08004CAC  =REG_TM0CNT
	movs	r0, #0x81                         @ 08004CAE
	lsls	r0, r0, #0x10                     @ 08004CB0
	subs	r0, r0, r5                        @ 08004CB2
	str	r0, [r1]                           @ 08004CB4  TM0CNT = 0x810000 - period
	ldr	r0, .Llit08004CC4                  @ 08004CB6  =gSfx+0x4
	b	.L08004DB2                           @ 08004CB8
	.hword	0x0000                          @ 08004CBA  (padding)
.Llit08004CBC:
	.word	REG_TM2CNT                       @ 08004CBC  = 0x04000108
.Llit08004CC0:
	.word	REG_TM0CNT                       @ 08004CC0  = 0x04000100
.Llit08004CC4:
	.word	gSfx+0x4                         @ 08004CC4  = 0x03002CB4
.L08004CC8:
	ldrb	r1, [r6, #1]                      @ 08004CC8
	cmp	r1, #0                             @ 08004CCA
	bne	.L08004DB0                         @ 08004CCC
	ldr	r0, .Llit08004CFC                  @ 08004CCE  =REG_TM1CNT
	str	r1, [r0]                           @ 08004CD0
	adds	r0, #8                            @ 08004CD2
	str	r1, [r0]                           @ 08004CD4
	ldr	r1, .Llit08004D00                  @ 08004CD6  =REG_DMA2CNT
	ldr	r0, .Llit08004D04                  @ 08004CD8  =DMA_STOP_TRICK
	str	r0, [r1]                           @ 08004CDA
	ldr	r0, [r1]                           @ 08004CDC
	adds	r1, #2                            @ 08004CDE
	movs	r4, #0x88                         @ 08004CE0
	lsls	r4, r4, #3                        @ 08004CE2
	adds	r0, r4, #0                        @ 08004CE4
	strh	r0, [r1]                          @ 08004CE6
	subs	r1, #0x50                         @ 08004CE8
	ldrh	r0, [r1]                          @ 08004CEA
	ldr	r4, .Llit08004D08                  @ 08004CEC  =0xFFFFCFFF
	ands	r4, r0                            @ 08004CEE
	cmp	r2, #0                             @ 08004CF0
	bne	.L08004D0C                         @ 08004CF2
	movs	r2, #0xb0                         @ 08004CF4
	lsls	r2, r2, #8                        @ 08004CF6
	b	.L08004D1A                           @ 08004CF8
	.hword	0x0000                          @ 08004CFA  (padding)
.Llit08004CFC:
	.word	REG_TM1CNT                       @ 08004CFC  = 0x04000104
.Llit08004D00:
	.word	REG_DMA2CNT                      @ 08004D00  = 0x040000D0
.Llit08004D04:
	.word	DMA_STOP_TRICK                   @ 08004D04  = 0x84400004
.Llit08004D08:
	.word	0xFFFFCFFF                       @ 08004D08
.L08004D0C:
	cmp	r2, #1                             @ 08004D0C
	bne	.L08004D16                         @ 08004D0E
	movs	r2, #0xa0                         @ 08004D10
	lsls	r2, r2, #8                        @ 08004D12
	b	.L08004D1A                           @ 08004D14
.L08004D16:
	movs	r2, #0x90                         @ 08004D16
	lsls	r2, r2, #8                        @ 08004D18
.L08004D1A:
	adds	r0, r2, #0                        @ 08004D1A
	orrs	r4, r0                            @ 08004D1C
	strh	r4, [r1]                          @ 08004D1E
	strb	r3, [r6, #1]                      @ 08004D20
	ldr	r1, .Llit08004D78                  @ 08004D22  =REG_DMA2SAD
	adds	r0, r7, #0                        @ 08004D24
	adds	r0, #0x2c                         @ 08004D26
	str	r0, [r1]                           @ 08004D28
	adds	r1, #4                            @ 08004D2A
	ldr	r0, .Llit08004D7C                  @ 08004D2C  =REG_FIFO_B
	str	r0, [r1]                           @ 08004D2E
	adds	r1, #4                            @ 08004D30
	ldr	r0, .Llit08004D80                  @ 08004D32  =DMA_FIFO_START_B
	str	r0, [r1]                           @ 08004D34
	ldr	r0, [r7, #0x18]                    @ 08004D36
	adds	r1, r0, #0                        @ 08004D38
	muls	r1, r5, r1                        @ 08004D3A
	lsrs	r1, r1, #8                        @ 08004D3C
	movs	r4, #0x80                         @ 08004D3E
	lsls	r4, r4, #0x11                     @ 08004D40
	adds	r0, r4, #0                        @ 08004D42
	bl	__udivsi3                           @ 08004D44
	adds	r5, r0, #0                        @ 08004D48
	adds	r0, r4, #0                        @ 08004D4A
	adds	r1, r5, #0                        @ 08004D4C
	bl	__udivsi3                           @ 08004D4E
	adds	r4, r0, #0                        @ 08004D52
	ldr	r1, [r7, #0x28]                    @ 08004D54
	ldr	r0, .Llit08004D84                  @ 08004D56  =0x3DB8
	muls	r0, r1, r0                        @ 08004D58
	adds	r1, r4, #0                        @ 08004D5A
	bl	__udivsi3                           @ 08004D5C
	adds	r2, r0, #0                        @ 08004D60
	str	r2, [r6, #0x10]                    @ 08004D62
	movs	r0, #0x80                         @ 08004D64
	lsls	r0, r0, #9                        @ 08004D66
	cmp	r2, r0                             @ 08004D68
	bgt	.L08004D8C                         @ 08004D6A
	ldr	r1, .Llit08004D88                  @ 08004D6C  =REG_TM3CNT
	movs	r0, #0xc4                         @ 08004D6E
	lsls	r0, r0, #0x10                     @ 08004D70
	subs	r0, r0, r2                        @ 08004D72
	b	.L08004D92                           @ 08004D74
	.hword	0x0000                          @ 08004D76  (padding)
.Llit08004D78:
	.word	REG_DMA2SAD                      @ 08004D78  = 0x040000C8
.Llit08004D7C:
	.word	REG_FIFO_B                       @ 08004D7C  = 0x040000A4
.Llit08004D80:
	.word	DMA_FIFO_START_B                 @ 08004D80  = 0xB6400004
.Llit08004D84:
	.word	0x00003DB8                       @ 08004D84
.Llit08004D88:
	.word	REG_TM3CNT                       @ 08004D88  = 0x0400010C
.L08004D8C:
	ldr	r1, .Llit08004DA4                  @ 08004D8C  =REG_TM3CNT
	movs	r0, #0xc3                         @ 08004D8E
	lsls	r0, r0, #0x10                     @ 08004D90
.L08004D92:
	str	r0, [r1]                           @ 08004D92
	ldr	r1, .Llit08004DA8                  @ 08004D94  =REG_TM1CNT
	movs	r0, #0x81                         @ 08004D96
	lsls	r0, r0, #0x10                     @ 08004D98
	subs	r0, r0, r5                        @ 08004D9A
	str	r0, [r1]                           @ 08004D9C
	ldr	r0, .Llit08004DAC                  @ 08004D9E  =gSfx+0x6
	b	.L08004DB2                           @ 08004DA0
	.hword	0x0000                          @ 08004DA2  (padding)
.Llit08004DA4:
	.word	REG_TM3CNT                       @ 08004DA4  = 0x0400010C
.Llit08004DA8:
	.word	REG_TM1CNT                       @ 08004DA8  = 0x04000104
.Llit08004DAC:
	.word	gSfx+0x6                         @ 08004DAC  = 0x03002CB6
.L08004DB0:
	ldr	r0, .Llit08004DB8                  @ 08004DB0  =gSfxDummySlot
.L08004DB2:
	pop	{r4, r5, r6, r7}                   @ 08004DB2
	pop	{r1}                               @ 08004DB4
	bx	r1                                  @ 08004DB6
.Llit08004DB8:
	.word	gSfxDummySlot                    @ 08004DB8  = 0x03002004
