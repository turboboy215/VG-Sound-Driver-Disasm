@ ============================================================================
@ gbamod3_player.s -- GBAModPlay version 3 (module id "GBAMOD30"), Thumb part
@                     GBAModPlay (C) Logik State 2003 www.LogikState.com
@
@ Reconstructed from "Need for Speed - Underground 2 (U) (M4).gba", ROM range
@ 0x08135C84-0x08138220 (9 628 bytes).  Assembling this file and linking it with
@ gbamod3.ld reproduces that range byte for byte (make -f gbamod3.mk).
@
@ The code is C compiled by GCC for Thumb (adds rX, rY, #0 register moves,
@ push {..}/pop {r0}/bx r0 epilogues, "mov pc, r0" switch tables).  There are no
@ symbols in the ROM; every name here was assigned during the analysis.
@
@ The ARM half of the library (DMA restart, SWI stubs, two LZ77-packed mixers) is in
@ gbamod3_arm.s; the tables are in gbamod3_rodata.s.
@
@ Host integration in NFSU2 (0x080FC2D8, called once per frame):
@     gmpDmaRestart(); ...; gmpFrame(); gmpFlip();
@ and at start-up (0x080FCD2C): gmpInit(&params, 4, 4, 2); gmpSetMasterVolume(64); ...
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
@ ---- library globals and ROM symbols
	.equ	gmpState, 0x030065D0                  @ u32  -> GmpState (work RAM block supplied by the host, >= 0x1E4C bytes)
	.equ	gmpMixCount, 0x030065D8               @ u32  number of gmpMix calls (debug counter, never read)
	.equ	gmpPlayer, 0x030065DC                 @ u32  -> current GmpPlayer (&state->player[0] or &state->player[1])
	.equ	gmpAmigaPeriods, 0x08138220           @ u16[976] Amiga period table, 8 finetune steps per semitone
	.equ	gmpStepTables, 0x081389C0             @ u32[9][976] period -> 20.12 step, one table per mix rate
	.equ	gmpVibratoSine, 0x08756E8C            @ u8[32] ProTracker half-sine
	.equ	gmpLinearFreq, 0x08756EAC             @ u16[768] 2^(i/768) frequency mantissa (XM linear periods)
	.equ	gmpCopyright, 0x087574AC              @ "GBAModPlay (C) Logik State 2003 www.LogikState.com"
	.equ	gmpRateTimer, 0x087574E0              @ u16[9] Timer 0 reload per mix-rate index
	.equ	gmpRateBufBytes, 0x087574F2           @ u16[9] samples per frame per mix-rate index
	.equ	gmpRateHz, 0x08757504                 @ u32[9] mix rate in Hz
	.equ	gmpRateStepTab, 0x0878E7AC            @ u32[9] -> gmpStepTables[i]
	.equ	gmpMixerMonoLZ, 0x0814158C            @ LZ77 image of the per-channel mixer (mixer mode 0)
	.equ	gmpMixerMultiLZ, 0x08141634           @ LZ77 image of the all-channel mixer (mixer mode 1)
	.equ	swiDiv, 0x08141300                    @ Thumb: SWI 6 (Div), r0 = r0 / r1
	.equ	swiMod, 0x08141308                    @ Thumb: SWI 6, r0 = r0 % r1
	.equ	gmpDmaRestartAB, 0x08141320           @ Thumb->ARM: restart DMA1+DMA2 from r0
	.equ	gmpCallR3, 0x08141360                 @ Thumb: bx r3 (call the IWRAM mixer)
	.equ	swiLZ77UnCompWram, 0x08141584         @ Thumb: SWI 0x11
	.equ	memcpy, 0x08150038                    @ libc
	.equ	memset, 0x08150098                    @ libc
@ ---- GmpState (work block, *gmpState)
	.equ	ST_buf0, 0x0                          @ mix buffer 0 (IWRAM)
	.equ	ST_buf1, 0x4                          @ mix buffer 1
	.equ	ST_cur, 0x8                           @ index of the buffer DMA is playing
	.equ	ST_prev, 0xC                          @ previous value of ST_cur
	.equ	ST_sameBuf, 0x10                      @ set by gmpDmaRestart when ST_cur == ST_prev (gates the test tone)
	.equ	ST_toneOn, 0x14                       @ A440 test tone enable (never set)
	.equ	ST_tonePhase, 0x18                    @ test tone phase accumulator
	.equ	ST_toneFrame, 0x1C                    @ test tone frame counter 0..59
	.equ	ST_rateIdx, 0x20                      @ current mix-rate index
	.equ	ST_newRate, 0x24                      @ requested mix-rate index
	.equ	ST_stepTab, 0x28                      @ -> step table for the current rate
	.equ	ST_periods, 0x2C                      @ -> gmpAmigaPeriods
	.equ	ST_iwramPtr, 0x30                     @ IWRAM bump allocator
	.equ	ST_dmaOn, 0x34                        @ DMA/timer have been started
	.equ	ST_mixer, 0x38                        @ -> decompressed mixer in IWRAM
	.equ	ST_echoWork, 0x3C                     @ optional 0x2E4-byte IWRAM block (never allocated)
	.equ	ST_jingleSync, 0x40                   @ pending jingle waits for a row that is a multiple of 4
	.equ	ST_paused, 0x44                       @ mixing paused
	.equ	ST_rateHz, 0x48                       @ mix rate in Hz
	.equ	ST_jinglePri, 0x4C                    @ s16 priority of the running jingle
	.equ	ST_fade, 0x50                         @ global fade 0..64 (ramps in by 3/frame)
	.equ	ST_jingleOn, 0x54                     @ u8 a jingle is playing
	.equ	ST_player0, 0x5C                      @ GmpPlayer for the music
	.equ	ST_player1, 0xBFC                     @ GmpPlayer for jingles
	.equ	ST_smpHeaders, 0x179C                 @ -> sample bank headers (12 bytes each)
	.equ	ST_smpPtr, 0x17A0                     @ u32[256] sample data pointers
	.equ	ST_sfxData, 0x1BA4                    @ -> SFX bank PCM
	.equ	ST_masterVol, 0x1BA8                  @ 0..64
	.equ	ST_musicVol, 0x1BAC                   @ 0..64
	.equ	ST_sfxVol, 0x1BB0                     @ 0..64
	.equ	ST_sfxCount, 0x1BB8                   @ entries in the SFX bank
	.equ	ST_playing, 0x1BBC                    @ s16 sequencer running
	.equ	ST_loop, 0x1BC0                       @ song loops at its end
	.equ	ST_maxSfx, 0x1BC4                     @ SFX channels requested at init
	.equ	ST_maxRate, 0x1BC8                    @ highest rate index the buffers were sized for
	.equ	ST_maxBufBytes, 0x1BCC                @ buffer size at ST_maxRate
	.equ	ST_bufBytes, 0x1BD0                   @ buffer size at the current rate
	.equ	ST_iwramUsed, 0x1BD4                  @ bytes taken from the IWRAM block
	.equ	ST_size, 0x1BD8                       @ 0x1E4C, size of this block
	.equ	ST_echoLenA, 0x1BDC                   @ echo tap A length
	.equ	ST_echoLenB, 0x1BE0                   @ echo tap B length
	.equ	ST_echoBuf, 0x1BE4                    @ echo delay line
	.equ	ST_echoPosA, 0x1BE8
	.equ	ST_echoPosB, 0x1BEC
	.equ	ST_echoLevel, 0x1BF0                  @ 0 = echo off
	.equ	ST_mixMode, 0x1BF4                    @ 0 = per-channel mixer, 1 = all-channel mixer
	.equ	ST_songReq, 0x1BF8                    @ module queued by gmpRequestSong
	.equ	ST_jingleReq, 0x1BFC                  @ module queued as a jingle
	.equ	ST_jingleDone, 0x1C00                 @ u8 jingle finished, switch back
	.equ	ST_lastBuf, 0x1C04                    @ mode 1: last mix destination
	.equ	ST_lastLen, 0x1C08                    @ mode 1: last mix length
@ ---- GmpPlayer (at ST_player0 / ST_player1; *gmpPlayer)
	.equ	PL_module, 0x0                        @ -> module
	.equ	PL_amiga, 0x4                         @ module+0x140: 1 = Amiga periods, 0 = XM linear periods
	.equ	PL_rows, 0x8                          @ module+0x13C: rows per pattern
	.equ	PL_skip, 0xC                          @ next Bxx jumps to the next order
	.equ	PL_unused10, 0x10                     @ set by gmpSetFlag10, never read
	.equ	PL_speed, 0x14                        @ ticks per row
	.equ	PL_tempoLock, 0x18                    @ u16 set by gmpSetBPM: ignore Fxx
	.equ	PL_tickHz, 0x1C                       @ ticks per second = BPM*2/5
	.equ	PL_rowLeft, 0x20                      @ samples until the next row
	.equ	PL_rowLen, 0x24                       @ samples per row
	.equ	PL_tickLeft, 0x2C                     @ samples until the next tick
	.equ	PL_tickLen, 0x30                      @ samples per tick
	.equ	PL_tick, 0x38                         @ u16 tick within the row
	.equ	PL_arpTick, 0x3A                      @ u16 arpeggio phase 1..3
	.equ	PL_bpm, 0x3C
	.equ	PL_row, 0x40
	.equ	PL_order, 0x44
	.equ	PL_loops, 0x48                        @ times the song wrapped
	.equ	PL_jumped, 0x4C                       @ u8 Dxx already taken this row
	.equ	PL_patBase, 0x50                      @ module+0x650
	.equ	PL_chan, 0x54                         @ GmpChannel[12] (0x98 bytes each)
	.equ	PL_rowState, 0x774                    @ GmpRowState[12] (0x58 bytes each)
	.equ	PL_nMusic, 0xB94                      @ music channels (module+0x28, max 12)
	.equ	PL_nSfx, 0xB98                        @ SFX channels
	.equ	PL_nChan, 0xB9C                       @ music + SFX
@ ---- GmpChannel (0x98 bytes)
	.equ	CH_ptr, 0x0                           @ sample data
	.equ	CH_pos, 0x4                           @ 20.12 position
	.equ	CH_step, 0x8                          @ 20.12 step
	.equ	CH_end, 0xC                           @ end (<<12); <=2 means silent
	.equ	CH_loopStart, 0x10                    @ bytes added to CH_ptr at the first wrap
	.equ	CH_loopLen, 0x14                      @ loop length <<12 (0 = one-shot)
	.equ	CH_vol, 0x18                          @ 0..64
	.equ	CH_sfxVol, 0x1C                       @ SFX base volume
	.equ	CH_adpcm, 0x20                        @ 0x20..0x2F: state for compressed SFX, written but never used
	.equ	CH_relNote, 0x3C                      @ s16 sample transpose
	.equ	CH_ins, 0x40                          @ u16 instrument / SFX number
	.equ	CH_fine, 0x44                         @ s16 finetune
	.equ	CH_note, 0x46                         @ u16 note, or linear period after note-on
	.equ	CH_tickFx, 0x48                       @ effect run on ticks (-1 none)
	.equ	CH_vsUp, 0x4C                         @ u16
	.equ	CH_vsDown, 0x4E                       @ u16
	.equ	CH_arpX, 0x50                         @ u16 x*8
	.equ	CH_arpY, 0x52                         @ u16 y*8
	.equ	CH_vibOfs, 0x54                       @ s16
	.equ	CH_vibDepth, 0x56                     @ u16
	.equ	CH_vibSpeed, 0x58                     @ u16
	.equ	CH_vibPos, 0x5A                       @ u16
	.equ	CH_portaOfs, 0x5E                     @ s16 Amiga-mode period offset
	.equ	CH_tpSpeed, 0x60                      @ u16
	.equ	CH_portaStep, 0x62                    @ s16
	.equ	CH_tpTarget, 0x64                     @ u16 target note
	.equ	CH_loopRow, 0x78                      @ u16 E60 row
	.equ	CH_loopCnt, 0x7A                      @ u16
	.equ	CH_compressed, 0x7C                   @ u16 SFX flag
	.equ	CH_linPorta, 0x80                     @ s32 linear period offset
	.equ	CH_linVib, 0x84                       @ s32 linear vibrato offset
	.equ	CH_portaMem, 0x88                     @ last 1xx/2xx parameter
	.equ	CH_volCol, 0x8C                       @ volume column (0 = none, v+1)
	.equ	CH_sfxPri, 0x90                       @ s16 SFX priority
	.equ	CH_tpTargetLin, 0x94                  @ linear target period

	.section .text.gmp3_player, "ax", %progbits
	.balign 4
@ --------------------------------------------------------------------------
@ gmpLinearFreq_(period)  (0x08135C84)
@   XM linear frequency.  x = 7680 - period
@     return (gmpLinearFreq[x % 768] * 4) >> (7 - x / 768)       (8363 Hz at period 4608)
@   Divisions go through swiDiv / swiMod (SWI 6).
@ --------------------------------------------------------------------------
	.thumb
	.thumb_func
	.global gmpLinearFreq_
gmpLinearFreq_:
	push	{r4, r5, r6, lr}                      @ 08135C84
	mov	r6, r8                                 @ 08135C86
	push	{r6}                                  @ 08135C88
	adds	r4, r0, #0                            @ 08135C8A
	movs	r0, #0xf0                             @ 08135C8C
	lsls	r0, r0, #5                            @ 08135C8E
	subs	r4, r0, r4                            @ 08135C90  x = 7680 - period
	movs	r5, #0xc0                             @ 08135C92
	lsls	r5, r5, #2                            @ 08135C94
	adds	r0, r4, #0                            @ 08135C96
	adds	r1, r5, #0                            @ 08135C98
	bl	swiDiv                                  @ 08135C9A
	mov	r8, r0                                 @ 08135C9E
	ldr	r6, .Llit08135CC4                      @ 08135CA0  =gmpLinearFreq
	adds	r0, r4, #0                            @ 08135CA2
	adds	r1, r5, #0                            @ 08135CA4
	bl	swiMod                                  @ 08135CA6  x % 768
	lsls	r0, r0, #1                            @ 08135CAA
	adds	r0, r0, r6                            @ 08135CAC
	ldrh	r0, [r0]                              @ 08135CAE
	lsls	r0, r0, #2                            @ 08135CB0
	movs	r1, #7                                @ 08135CB2
	mov	r2, r8                                 @ 08135CB4
	subs	r1, r1, r2                            @ 08135CB6
	lsrs	r0, r1                                @ 08135CB8
	pop	{r3}                                   @ 08135CBA
	mov	r8, r3                                 @ 08135CBC
	pop	{r4, r5, r6}                           @ 08135CBE
	pop	{r1}                                   @ 08135CC0
	bx	r1                                      @ 08135CC2  return
.Llit08135CC4:
	.word	gmpLinearFreq                        @ 08135CC4
@ --------------------------------------------------------------------------
@ gmpNoteToLinear(ch)  (0x08135CC8)
@   Converts the note in CH_note into an XM linear period *in place* and sets the step:
@     CH_note = 7616 - (CH_relNote + CH_note - 2) * 64 - CH_fine / 2
@     CH_step = (gmpLinearFreq_(CH_note + CH_linPorta + CH_linVib) << 12) / state->ST_rateHz
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpNoteToLinear
gmpNoteToLinear:
	push	{r4, lr}                              @ 08135CC8
	adds	r4, r0, #0                            @ 08135CCA
	movs	r1, #0x3c                             @ 08135CCC
	ldrsh	r0, [r4, r1]                         @ 08135CCE  CH_relNote
	adds	r2, r4, #0                            @ 08135CD0
	adds	r2, #0x46                             @ 08135CD2
	subs	r0, #1                                @ 08135CD4
	ldrh	r3, [r2]                              @ 08135CD6  CH_note
	adds	r0, r0, r3                            @ 08135CD8
	subs	r1, r0, #1                            @ 08135CDA
	lsls	r1, r1, #0x10                         @ 08135CDC
	lsrs	r1, r1, #0xa                          @ 08135CDE
	movs	r3, #0xee                             @ 08135CE0  7616
	lsls	r3, r3, #5                            @ 08135CE2
	adds	r0, r3, #0                            @ 08135CE4
	subs	r0, r0, r1                            @ 08135CE6
	adds	r1, r4, #0                            @ 08135CE8
	adds	r1, #0x44                             @ 08135CEA
	ldrh	r1, [r1]                              @ 08135CEC  CH_fine
	lsls	r1, r1, #0x10                         @ 08135CEE
	asrs	r1, r1, #0x11                         @ 08135CF0
	subs	r0, r0, r1                            @ 08135CF2
	lsls	r0, r0, #0x10                         @ 08135CF4
	lsrs	r0, r0, #0x10                         @ 08135CF6
	strh	r0, [r2]                              @ 08135CF8  CH_note = linear period
	adds	r1, r4, #0                            @ 08135CFA
	adds	r1, #0x80                             @ 08135CFC
	ldr	r1, [r1]                               @ 08135CFE  CH_linPorta
	adds	r0, r0, r1                            @ 08135D00
	adds	r1, r4, #0                            @ 08135D02
	adds	r1, #0x84                             @ 08135D04
	ldr	r1, [r1]                               @ 08135D06  CH_linVib
	adds	r0, r0, r1                            @ 08135D08
	bl	gmpLinearFreq_                          @ 08135D0A
	lsls	r0, r0, #0xc                          @ 08135D0E
	ldr	r1, .Llit08135D24                      @ 08135D10  =gmpState
	ldr	r1, [r1]                               @ 08135D12
	ldr	r1, [r1, #0x48]                        @ 08135D14  ST_rateHz
	bl	swiDiv                                  @ 08135D16
	str	r0, [r4, #8]                           @ 08135D1A  CH_step
	pop	{r4}                                   @ 08135D1C
	pop	{r0}                                   @ 08135D1E
	bx	r0                                      @ 08135D20
	.hword	0x0000                              @ 08135D22  (padding)
.Llit08135D24:
	.word	gmpState                             @ 08135D24
@ --------------------------------------------------------------------------
@ gmpUpdateLinearStep(ch)  (0x08135D28)
@   CH_step = (gmpLinearFreq_(CH_note + CH_linPorta + CH_linVib) << 12) / ST_rateHz
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpUpdateLinearStep
gmpUpdateLinearStep:
	push	{r4, lr}                              @ 08135D28
	adds	r4, r0, #0                            @ 08135D2A
	adds	r0, #0x46                             @ 08135D2C
	ldrh	r0, [r0]                              @ 08135D2E  CH_note
	adds	r1, r4, #0                            @ 08135D30
	adds	r1, #0x80                             @ 08135D32
	ldr	r1, [r1]                               @ 08135D34  CH_linPorta
	adds	r0, r0, r1                            @ 08135D36
	adds	r1, r4, #0                            @ 08135D38
	adds	r1, #0x84                             @ 08135D3A
	ldr	r1, [r1]                               @ 08135D3C  CH_linVib
	adds	r0, r0, r1                            @ 08135D3E
	bl	gmpLinearFreq_                          @ 08135D40
	lsls	r0, r0, #0xc                          @ 08135D44
	ldr	r1, .Llit08135D58                      @ 08135D46  =gmpState
	ldr	r1, [r1]                               @ 08135D48
	ldr	r1, [r1, #0x48]                        @ 08135D4A  ST_rateHz
	bl	swiDiv                                  @ 08135D4C
	str	r0, [r4, #8]                           @ 08135D50  CH_step
	pop	{r4}                                   @ 08135D52
	pop	{r0}                                   @ 08135D54
	bx	r0                                      @ 08135D56
.Llit08135D58:
	.word	gmpState                             @ 08135D58
@ --------------------------------------------------------------------------
@ gmpWaitLine(n)  (0x08135D5C)  -- unused
@   while (*(u16 *)0x04000000 != n) ;
@   Meant to wait for REG_VCOUNT (0x04000006) but reads REG_DISPCNT.  The ARM module has
@   correct assembler versions (gmpWaitVCount, 0x081414DA) that are never called.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpWaitLine
gmpWaitLine:
	adds	r1, r0, #0                            @ 08135D5C
	movs	r2, #0x80                             @ 08135D5E
	lsls	r2, r2, #0x13                         @ 08135D60
.L08135D62:
	ldrh	r0, [r2]                              @ 08135D62
	cmp	r0, r1                                 @ 08135D64
	bne	.L08135D62                             @ 08135D66
	bx	lr                                      @ 08135D68
	.hword	0x0000                              @ 08135D6A  (padding)
@ --------------------------------------------------------------------------
@ gmpWaitLineLeave(n)  (0x08135D6C)
@   while (*(u16 *)0x04000000 == n) ;
@   Same wrong register: gmpStartDma calls it with 0x3E and 0x3D to leave scanlines 62 and
@   61, but DISPCNT never holds those values here, so it returns at once and the DMA start
@   is not synchronised to the display.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpWaitLineLeave
gmpWaitLineLeave:
	adds	r1, r0, #0                            @ 08135D6C
	movs	r2, #0x80                             @ 08135D6E
	lsls	r2, r2, #0x13                         @ 08135D70
.L08135D72:
	ldrh	r0, [r2]                              @ 08135D72
	cmp	r0, r1                                 @ 08135D74
	beq	.L08135D72                             @ 08135D76
	bx	lr                                      @ 08135D78
	.hword	0x0000                              @ 08135D7A  (padding)
@ --------------------------------------------------------------------------
@ gmpStartDma(buffer, rateIdx, mode)  (0x08135D7C)
@   mode 1 (mono):   DMA1 -> FIFO_A, SOUNDCNT_H = 0x0B0E (DMA A on L+R, Timer 0)
@   mode 2 (dual):   DMA1 -> FIFO_A and DMA2 -> FIFO_B from the *same* buffer,
@                    SOUNDCNT_H = 0xBB0E (A and B both on L+R) -- twice the level, still mono
@     ST_bufBytes = gmpRateBufBytes[rateIdx];  TM0CNT_L = gmpRateTimer[rateIdx]
@     gmpWaitLineLeave(0x3E); gmpWaitLineLeave(0x3D)   (no effect, see gmpWaitLineLeave)
@     DMAxCNT_H = 0xB600 (enable, FIFO timing, 32-bit, repeat); TM0CNT_H = 0x80
@   any mode:  ST_rateIdx = ST_newRate = rateIdx; ST_rateHz = gmpRateHz[i]; ST_stepTab = gmpRateStepTab[i]
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpStartDma
gmpStartDma:
	push	{r4, r5, r6, r7, lr}                  @ 08135D7C
	adds	r3, r0, #0                            @ 08135D7E
	adds	r7, r1, #0                            @ 08135D80
	cmp	r2, #1                                 @ 08135D82
	bne	.L08135E04                             @ 08135D84
	ldr	r5, .Llit08135DD8                      @ 08135D86  =REG_DMA1CNT_H
	movs	r2, #0                                @ 08135D88
	strh	r2, [r5]                              @ 08135D8A  DMA1CNT_H = 0
	ldr	r0, .Llit08135DDC                      @ 08135D8C  =REG_SOUNDCNT_X
	strh	r2, [r0]                              @ 08135D8E  SOUNDCNT_X = 0
	ldr	r1, .Llit08135DE0                      @ 08135D90  =REG_SOUNDCNT_H
	ldr	r4, .Llit08135DE4                      @ 08135D92  =0x00000B0E
	adds	r0, r4, #0                            @ 08135D94
	strh	r0, [r1]                              @ 08135D96  SOUNDCNT_H = 0x0B0E
	ldr	r0, .Llit08135DE8                      @ 08135D98  =REG_DMA1SAD
	str	r3, [r0]                               @ 08135D9A  DMA1SAD = buffer
	adds	r1, #0x3e                             @ 08135D9C
	subs	r0, #0x1c                             @ 08135D9E
	str	r0, [r1]                               @ 08135DA0  DMA1DAD = FIFO_A
	ldr	r4, .Llit08135DEC                      @ 08135DA2  =REG_TM0CNT_H
	strh	r2, [r4]                              @ 08135DA4  TM0CNT_H = 0
	ldr	r0, .Llit08135DF0                      @ 08135DA6  =gmpState
	ldr	r2, [r0]                               @ 08135DA8
	ldr	r0, .Llit08135DF4                      @ 08135DAA  =0x00001BD0
	adds	r2, r2, r0                            @ 08135DAC
	ldr	r0, .Llit08135DF8                      @ 08135DAE  =gmpRateBufBytes
	lsls	r1, r7, #1                            @ 08135DB0
	adds	r0, r1, r0                            @ 08135DB2
	ldrh	r0, [r0]                              @ 08135DB4
	str	r0, [r2]                               @ 08135DB6  ST_bufBytes
	ldr	r0, .Llit08135DFC                      @ 08135DB8  =gmpRateTimer
	adds	r1, r1, r0                            @ 08135DBA
	ldrh	r1, [r1]                              @ 08135DBC
	ldr	r0, .Llit08135E00                      @ 08135DBE  =REG_TM0CNT_L
	strh	r1, [r0]                              @ 08135DC0  TM0CNT_L = reload
	movs	r0, #0x3e                             @ 08135DC2
	bl	gmpWaitLineLeave                        @ 08135DC4
	movs	r0, #0x3d                             @ 08135DC8
	bl	gmpWaitLineLeave                        @ 08135DCA
	movs	r1, #0xb6                             @ 08135DCE
	lsls	r1, r1, #8                            @ 08135DD0
	adds	r0, r1, #0                            @ 08135DD2
	b	.L08135E66                               @ 08135DD4
	.hword	0x0000                              @ 08135DD6  (padding)
.Llit08135DD8:
	.word	REG_DMA1CNT_H                        @ 08135DD8
.Llit08135DDC:
	.word	REG_SOUNDCNT_X                       @ 08135DDC
.Llit08135DE0:
	.word	REG_SOUNDCNT_H                       @ 08135DE0
.Llit08135DE4:
	.word	0x00000B0E                           @ 08135DE4
.Llit08135DE8:
	.word	REG_DMA1SAD                          @ 08135DE8
.Llit08135DEC:
	.word	REG_TM0CNT_H                         @ 08135DEC
.Llit08135DF0:
	.word	gmpState                             @ 08135DF0
.Llit08135DF4:
	.word	0x00001BD0                           @ 08135DF4
.Llit08135DF8:
	.word	gmpRateBufBytes                      @ 08135DF8
.Llit08135DFC:
	.word	gmpRateTimer                         @ 08135DFC
.Llit08135E00:
	.word	REG_TM0CNT_L                         @ 08135E00
.L08135E04:
	cmp	r2, #2                                 @ 08135E04
	bne	.L08135E6C                             @ 08135E06
	ldr	r6, .Llit08135E8C                      @ 08135E08  =REG_DMA1CNT_H
	movs	r2, #0                                @ 08135E0A
	strh	r2, [r6]                              @ 08135E0C
	ldr	r5, .Llit08135E90                      @ 08135E0E  =REG_DMA2CNT_H
	strh	r2, [r5]                              @ 08135E10
	ldr	r0, .Llit08135E94                      @ 08135E12  =REG_SOUNDCNT_X
	strh	r2, [r0]                              @ 08135E14
	ldr	r1, .Llit08135E98                      @ 08135E16  =REG_SOUNDCNT_H
	ldr	r4, .Llit08135E9C                      @ 08135E18  =0x0000BB0E
	adds	r0, r4, #0                            @ 08135E1A
	strh	r0, [r1]                              @ 08135E1C  SOUNDCNT_H = 0xBB0E
	ldr	r0, .Llit08135EA0                      @ 08135E1E  =REG_DMA1SAD
	str	r3, [r0]                               @ 08135E20
	adds	r1, #0x3e                             @ 08135E22
	subs	r0, #0x1c                             @ 08135E24
	str	r0, [r1]                               @ 08135E26
	adds	r0, #0x28                             @ 08135E28
	str	r3, [r0]                               @ 08135E2A  DMA2SAD = buffer
	adds	r1, #0xc                              @ 08135E2C
	subs	r0, #0x24                             @ 08135E2E
	str	r0, [r1]                               @ 08135E30  DMA2DAD = FIFO_B
	ldr	r4, .Llit08135EA4                      @ 08135E32  =REG_TM0CNT_H
	strh	r2, [r4]                              @ 08135E34
	ldr	r0, .Llit08135EA8                      @ 08135E36  =gmpState
	ldr	r2, [r0]                               @ 08135E38
	ldr	r0, .Llit08135EAC                      @ 08135E3A  =0x00001BD0
	adds	r2, r2, r0                            @ 08135E3C
	ldr	r0, .Llit08135EB0                      @ 08135E3E  =gmpRateBufBytes
	lsls	r1, r7, #1                            @ 08135E40
	adds	r0, r1, r0                            @ 08135E42
	ldrh	r0, [r0]                              @ 08135E44
	str	r0, [r2]                               @ 08135E46  ST_bufBytes
	ldr	r0, .Llit08135EB4                      @ 08135E48  =gmpRateTimer
	adds	r1, r1, r0                            @ 08135E4A
	ldrh	r1, [r1]                              @ 08135E4C
	ldr	r0, .Llit08135EB8                      @ 08135E4E  =REG_TM0CNT_L
	strh	r1, [r0]                              @ 08135E50
	movs	r0, #0x3e                             @ 08135E52
	bl	gmpWaitLineLeave                        @ 08135E54
	movs	r0, #0x3d                             @ 08135E58
	bl	gmpWaitLineLeave                        @ 08135E5A
	movs	r1, #0xb6                             @ 08135E5E
	lsls	r1, r1, #8                            @ 08135E60
	adds	r0, r1, #0                            @ 08135E62
	strh	r0, [r6]                              @ 08135E64  DMA1CNT_H = 0xB600
.L08135E66:
	strh	r0, [r5]                              @ 08135E66  DMA2CNT_H = 0xB600
	movs	r0, #0x80                             @ 08135E68
	strh	r0, [r4]                              @ 08135E6A  TM0CNT_H = 0x80 (start)
.L08135E6C:
	ldr	r0, .Llit08135EA8                      @ 08135E6C  =gmpState
	ldr	r2, [r0]                               @ 08135E6E
	str	r7, [r2, #0x20]                        @ 08135E70  ST_rateIdx
	str	r7, [r2, #0x24]                        @ 08135E72  ST_newRate
	ldr	r0, .Llit08135EBC                      @ 08135E74  =gmpRateHz
	lsls	r1, r7, #2                            @ 08135E76
	adds	r0, r1, r0                            @ 08135E78
	ldr	r0, [r0]                               @ 08135E7A
	str	r0, [r2, #0x48]                        @ 08135E7C  ST_rateHz
	ldr	r0, .Llit08135EC0                      @ 08135E7E  =gmpRateStepTab
	adds	r1, r1, r0                            @ 08135E80
	ldr	r0, [r1]                               @ 08135E82
	str	r0, [r2, #0x28]                        @ 08135E84  ST_stepTab
	pop	{r4, r5, r6, r7}                       @ 08135E86
	pop	{r0}                                   @ 08135E88
	bx	r0                                      @ 08135E8A
.Llit08135E8C:
	.word	REG_DMA1CNT_H                        @ 08135E8C
.Llit08135E90:
	.word	REG_DMA2CNT_H                        @ 08135E90
.Llit08135E94:
	.word	REG_SOUNDCNT_X                       @ 08135E94
.Llit08135E98:
	.word	REG_SOUNDCNT_H                       @ 08135E98
.Llit08135E9C:
	.word	0x0000BB0E                           @ 08135E9C
.Llit08135EA0:
	.word	REG_DMA1SAD                          @ 08135EA0
.Llit08135EA4:
	.word	REG_TM0CNT_H                         @ 08135EA4
.Llit08135EA8:
	.word	gmpState                             @ 08135EA8
.Llit08135EAC:
	.word	0x00001BD0                           @ 08135EAC
.Llit08135EB0:
	.word	gmpRateBufBytes                      @ 08135EB0
.Llit08135EB4:
	.word	gmpRateTimer                         @ 08135EB4
.Llit08135EB8:
	.word	REG_TM0CNT_L                         @ 08135EB8
.Llit08135EBC:
	.word	gmpRateHz                            @ 08135EBC
.Llit08135EC0:
	.word	gmpRateStepTab                       @ 08135EC0
@ --------------------------------------------------------------------------
@ gmpStop()  (0x08135EC4)
@   Silence everything and switch the hardware off:
@     gmpSilenceMusic(); for each SFX channel gmpStopSfx(i)
@     DMA1CNT_L = DMA2CNT_L = 4: the E.T.-style "0x84400004 dummy transfer" constant is written
@     with strh, so only the word count lands; then DMA1CNT_H = DMA2CNT_H = TM0CNT_H = 0
@     ST_dmaOn = 0; clear all 12 channels of the current player; gmpClearBuffers()
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpStop
gmpStop:
	push	{r4, r5, r6, lr}                      @ 08135EC4
	bl	gmpSilenceMusic                         @ 08135EC6
	movs	r4, #0                                @ 08135ECA
	ldr	r1, .Llit08135F40                      @ 08135ECC  =gmpPlayer
	ldr	r0, [r1]                               @ 08135ECE
	ldr	r2, .Llit08135F44                      @ 08135ED0  =0x00000B98
	adds	r0, r0, r2                            @ 08135ED2
	ldr	r0, [r0]                               @ 08135ED4  PL_nSfx
	cmp	r4, r0                                 @ 08135ED6
	bhs	.L08135EF0                             @ 08135ED8
	adds	r5, r1, #0                            @ 08135EDA
.L08135EDC:
	adds	r0, r4, #0                            @ 08135EDC
	bl	gmpStopSfx                              @ 08135EDE
	adds	r4, #1                                @ 08135EE2
	ldr	r0, [r5]                               @ 08135EE4
	ldr	r1, .Llit08135F44                      @ 08135EE6  =0x00000B98
	adds	r0, r0, r1                            @ 08135EE8
	ldr	r0, [r0]                               @ 08135EEA
	cmp	r4, r0                                 @ 08135EEC
	blo	.L08135EDC                             @ 08135EEE
.L08135EF0:
	ldr	r2, .Llit08135F48                      @ 08135EF0  =REG_DMA1CNT
	ldr	r0, [r2]                               @ 08135EF2
	ldr	r1, .Llit08135F4C                      @ 08135EF4  =0x499F0000
	ands	r0, r1                                @ 08135EF6
	ldr	r1, .Llit08135F50                      @ 08135EF8  =0x84400004
	orrs	r0, r1                                @ 08135EFA
	strh	r0, [r2]                              @ 08135EFC
	ldr	r0, .Llit08135F54                      @ 08135EFE  =REG_DMA2CNT
	strh	r1, [r0]                              @ 08135F00
	ldr	r1, .Llit08135F58                      @ 08135F02  =REG_DMA1CNT_H
	adds	r2, #0xe                              @ 08135F04
	movs	r0, #0                                @ 08135F06
	strh	r0, [r1]                              @ 08135F08
	strh	r0, [r2]                              @ 08135F0A
	adds	r1, #0x3c                             @ 08135F0C
	strh	r0, [r1]                              @ 08135F0E
	ldr	r0, .Llit08135F5C                      @ 08135F10  =gmpState
	ldr	r1, [r0]                               @ 08135F12
	movs	r0, #0                                @ 08135F14
	str	r0, [r1, #0x34]                        @ 08135F16  ST_dmaOn
	movs	r4, #0                                @ 08135F18
	ldr	r6, .Llit08135F40                      @ 08135F1A  =gmpPlayer
	movs	r5, #0                                @ 08135F1C
.L08135F1E:
	ldr	r0, [r6]                               @ 08135F1E
	adds	r0, r5, r0                            @ 08135F20
	adds	r0, #0x54                             @ 08135F22
	movs	r1, #0                                @ 08135F24
	movs	r2, #0x98                             @ 08135F26
	bl	memset                                  @ 08135F28
	adds	r5, #0x98                             @ 08135F2C
	adds	r4, #1                                @ 08135F2E
	cmp	r4, #0xb                               @ 08135F30
	bls	.L08135F1E                             @ 08135F32
	bl	gmpClearBuffers                         @ 08135F34
	pop	{r4, r5, r6}                           @ 08135F38
	pop	{r0}                                   @ 08135F3A
	bx	r0                                      @ 08135F3C
	.hword	0x0000                              @ 08135F3E  (padding)
.Llit08135F40:
	.word	gmpPlayer                            @ 08135F40
.Llit08135F44:
	.word	0x00000B98                           @ 08135F44
.Llit08135F48:
	.word	REG_DMA1CNT                          @ 08135F48
.Llit08135F4C:
	.word	0x499F0000                           @ 08135F4C
.Llit08135F50:
	.word	0x84400004                           @ 08135F50
.Llit08135F54:
	.word	REG_DMA2CNT                          @ 08135F54
.Llit08135F58:
	.word	REG_DMA1CNT_H                        @ 08135F58
.Llit08135F5C:
	.word	gmpState                             @ 08135F5C
@ --------------------------------------------------------------------------
@ gmpRequestSong(module)  (0x08135F60)
@   ST_songReq = module   (started at the next gmpFrame; 0 = nothing)
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpRequestSong
gmpRequestSong:
	ldr	r1, .Llit08135F6C                      @ 08135F60  =gmpState
	ldr	r1, [r1]                               @ 08135F62
	ldr	r2, .Llit08135F70                      @ 08135F64  =0x00001BF8
	adds	r1, r1, r2                            @ 08135F66
	str	r0, [r1]                               @ 08135F68  ST_songReq
	bx	lr                                      @ 08135F6A
.Llit08135F6C:
	.word	gmpState                             @ 08135F6C
.Llit08135F70:
	.word	0x00001BF8                           @ 08135F70
@ --------------------------------------------------------------------------
@ gmpServiceSongRequest()  (0x08135F74)
@   if (ST_songReq) { m = ST_songReq; ST_songReq = 0;
@     gmpPlayer = &ST_player0; PL_loops = 0;
@     gmpSilenceMusic(); if (gmpLoadModule(gmpPlayer, m)) gmpStartSong(0); }
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpServiceSongRequest
gmpServiceSongRequest:
	push	{r4, r5, lr}                          @ 08135F74
	ldr	r0, .Llit08135FAC                      @ 08135F76  =gmpState
	ldr	r0, [r0]                               @ 08135F78
	ldr	r1, .Llit08135FB0                      @ 08135F7A  =0x00001BF8
	adds	r2, r0, r1                            @ 08135F7C
	ldr	r5, [r2]                               @ 08135F7E  ST_songReq
	cmp	r5, #0                                 @ 08135F80
	beq	.L08135FA6                             @ 08135F82
	movs	r1, #0                                @ 08135F84
	str	r1, [r2]                               @ 08135F86  ST_songReq
	ldr	r4, .Llit08135FB4                      @ 08135F88  =gmpPlayer
	adds	r0, #0x5c                             @ 08135F8A
	str	r0, [r4]                               @ 08135F8C
	str	r1, [r0, #0x48]                        @ 08135F8E  ST_player0.PL_loops
	bl	gmpSilenceMusic                         @ 08135F90
	ldr	r0, [r4]                               @ 08135F94
	adds	r1, r5, #0                            @ 08135F96
	bl	gmpLoadModule                           @ 08135F98
	cmp	r0, #0                                 @ 08135F9C
	beq	.L08135FA6                             @ 08135F9E
	movs	r0, #0                                @ 08135FA0
	bl	gmpStartSong                            @ 08135FA2
.L08135FA6:
	pop	{r4, r5}                               @ 08135FA6
	pop	{r0}                                   @ 08135FA8
	bx	r0                                      @ 08135FAA
.Llit08135FAC:
	.word	gmpState                             @ 08135FAC
.Llit08135FB0:
	.word	0x00001BF8                           @ 08135FB0
.Llit08135FB4:
	.word	gmpPlayer                            @ 08135FB4
@ --------------------------------------------------------------------------
@ gmpCopySfxChannels(dstPlayer, srcPlayer)  (0x08135FB8)
@   memcpy(&dst->chan[dst->PL_nMusic], &src->chan[src->PL_nMusic], src->PL_nSfx * 0x98)
@   Carries running sound effects across a switch between the music and jingle players.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpCopySfxChannels
gmpCopySfxChannels:
	push	{r4, lr}                              @ 08135FB8
	adds	r4, r0, #0                            @ 08135FBA
	adds	r2, r1, #0                            @ 08135FBC
	ldr	r1, .Llit08135FE8                      @ 08135FBE  =0x00000B94
	adds	r0, r4, r1                            @ 08135FC0
	ldr	r0, [r0]                               @ 08135FC2  PL_nMusic
	movs	r3, #0x98                             @ 08135FC4
	muls	r0, r3, r0                            @ 08135FC6
	adds	r0, r0, r4                            @ 08135FC8
	adds	r0, #0x54                             @ 08135FCA
	adds	r1, r2, r1                            @ 08135FCC
	ldr	r1, [r1]                               @ 08135FCE  PL_nMusic
	muls	r1, r3, r1                            @ 08135FD0
	adds	r1, r1, r2                            @ 08135FD2
	adds	r1, #0x54                             @ 08135FD4
	ldr	r4, .Llit08135FEC                      @ 08135FD6  =0x00000B98
	adds	r2, r2, r4                            @ 08135FD8
	ldr	r2, [r2]                               @ 08135FDA  PL_nSfx
	muls	r2, r3, r2                            @ 08135FDC
	bl	memcpy                                  @ 08135FDE
	pop	{r4}                                   @ 08135FE2
	pop	{r0}                                   @ 08135FE4
	bx	r0                                      @ 08135FE6
.Llit08135FE8:
	.word	0x00000B94                           @ 08135FE8
.Llit08135FEC:
	.word	0x00000B98                           @ 08135FEC
@ --------------------------------------------------------------------------
@ gmpServiceJingle()  (0x08135FF0)
@   if (ST_jingleSync && (gmpPlayer->PL_row & 3)) return;        wait for a beat
@   if (ST_jingleReq) { start it on ST_player1: gmpLoadModule, gmpStartSong(0),
@                       gmpCopySfxChannels(player1, player0) }
@   if (ST_jingleDone) { gmpPlayer = &ST_player0 (the music resumes where it stopped);
@                        gmpCopySfxChannels(player0, player1) }
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpServiceJingle
gmpServiceJingle:
	push	{r4, r5, r6, lr}                      @ 08135FF0
	ldr	r6, .Llit08136080                      @ 08135FF2  =gmpState
	ldr	r2, [r6]                               @ 08135FF4
	ldr	r0, [r2, #0x40]                        @ 08135FF6  ST_jingleSync
	cmp	r0, #0                                 @ 08135FF8
	beq	.L0813600A                             @ 08135FFA
	ldr	r0, .Llit08136084                      @ 08135FFC  =gmpPlayer
	ldr	r0, [r0]                               @ 08135FFE
	ldr	r0, [r0, #0x40]                        @ 08136000  PL_row
	movs	r1, #3                                @ 08136002
	ands	r0, r1                                @ 08136004
	cmp	r0, #0                                 @ 08136006
	bne	.L08136078                             @ 08136008
.L0813600A:
	ldr	r1, .Llit08136088                      @ 0813600A  =0x00001BFC
	adds	r0, r2, r1                            @ 0813600C
	ldr	r5, [r0]                               @ 0813600E
	cmp	r5, #0                                 @ 08136010
	beq	.L0813604E                             @ 08136012
	movs	r1, #0                                @ 08136014
	str	r1, [r0]                               @ 08136016
	movs	r3, #0xe0                             @ 08136018
	lsls	r3, r3, #5                            @ 0813601A
	adds	r0, r2, r3                            @ 0813601C
	strb	r1, [r0]                              @ 0813601E
	ldr	r4, .Llit08136084                      @ 08136020  =gmpPlayer
	ldr	r0, [r6]                               @ 08136022
	ldr	r2, .Llit0813608C                      @ 08136024  =0x00000BFC
	adds	r0, r0, r2                            @ 08136026
	str	r0, [r4]                               @ 08136028
	str	r1, [r0, #0x48]                        @ 0813602A
	bl	gmpSilenceMusic                         @ 0813602C
	ldr	r0, [r4]                               @ 08136030
	adds	r1, r5, #0                            @ 08136032
	bl	gmpLoadModule                           @ 08136034
	cmp	r0, #0                                 @ 08136038
	beq	.L0813604E                             @ 0813603A
	movs	r0, #0                                @ 0813603C
	bl	gmpStartSong                            @ 0813603E
	ldr	r1, [r6]                               @ 08136042
	ldr	r3, .Llit0813608C                      @ 08136044  =0x00000BFC
	adds	r0, r1, r3                            @ 08136046
	adds	r1, #0x5c                             @ 08136048
	bl	gmpCopySfxChannels                      @ 0813604A
.L0813604E:
	ldr	r4, .Llit08136080                      @ 0813604E  =gmpState
	ldr	r2, [r4]                               @ 08136050
	movs	r0, #0xe0                             @ 08136052
	lsls	r0, r0, #5                            @ 08136054
	adds	r3, r2, r0                            @ 08136056
	ldrb	r0, [r3]                              @ 08136058  ST_jingleDone
	cmp	r0, #0                                 @ 0813605A
	beq	.L08136078                             @ 0813605C
	ldr	r1, .Llit08136084                      @ 0813605E  =gmpPlayer
	adds	r0, r2, #0                            @ 08136060
	adds	r0, #0x5c                             @ 08136062
	str	r0, [r1]                               @ 08136064
	movs	r0, #0                                @ 08136066
	strb	r0, [r3]                              @ 08136068  ST_jingleDone
	ldr	r1, [r4]                               @ 0813606A
	adds	r0, r1, #0                            @ 0813606C
	adds	r0, #0x5c                             @ 0813606E
	ldr	r2, .Llit0813608C                      @ 08136070  =0x00000BFC
	adds	r1, r1, r2                            @ 08136072
	bl	gmpCopySfxChannels                      @ 08136074
.L08136078:
	pop	{r4, r5, r6}                           @ 08136078
	pop	{r0}                                   @ 0813607A
	bx	r0                                      @ 0813607C
	.hword	0x0000                              @ 0813607E  (padding)
.Llit08136080:
	.word	gmpState                             @ 08136080
.Llit08136084:
	.word	gmpPlayer                            @ 08136084
.Llit08136088:
	.word	0x00001BFC                           @ 08136088
.Llit0813608C:
	.word	0x00000BFC                           @ 0813608C
@ --------------------------------------------------------------------------
@ gmpClearBuffers()  (0x08136090)
@   SOUNDCNT_X = 0; memset(ST_buf0, 0, ST_bufBytes); memset(ST_buf1, 0, ST_bufBytes)
@   Note: turns the whole sound unit off; gmpSoundOn/gmpResume turn it on again.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpClearBuffers
gmpClearBuffers:
	push	{r4, r5, lr}                          @ 08136090
	ldr	r1, .Llit081360C0                      @ 08136092  =REG_SOUNDCNT_X
	movs	r0, #0                                @ 08136094
	strh	r0, [r1]                              @ 08136096
	ldr	r4, .Llit081360C4                      @ 08136098  =gmpState
	ldr	r1, [r4]                               @ 0813609A
	ldr	r5, .Llit081360C8                      @ 0813609C  =0x00001BD0
	ldr	r0, [r1]                               @ 0813609E  ST_buf0
	adds	r1, r1, r5                            @ 081360A0
	ldr	r2, [r1]                               @ 081360A2  ST_bufBytes
	movs	r1, #0                                @ 081360A4
	bl	memset                                  @ 081360A6
	ldr	r1, [r4]                               @ 081360AA
	ldr	r0, [r1, #4]                           @ 081360AC  ST_buf1
	adds	r1, r1, r5                            @ 081360AE
	ldr	r2, [r1]                               @ 081360B0  ST_bufBytes
	movs	r1, #0                                @ 081360B2
	bl	memset                                  @ 081360B4
	pop	{r4, r5}                               @ 081360B8
	pop	{r0}                                   @ 081360BA
	bx	r0                                      @ 081360BC
	.hword	0x0000                              @ 081360BE  (padding)
.Llit081360C0:
	.word	REG_SOUNDCNT_X                       @ 081360C0
.Llit081360C4:
	.word	gmpState                             @ 081360C4
.Llit081360C8:
	.word	0x00001BD0                           @ 081360C8
@ --------------------------------------------------------------------------
@ gmpSoundOn()  (0x081360CC)
@   SOUNDCNT_X = 0x80
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpSoundOn
gmpSoundOn:
	ldr	r1, .Llit081360D4                      @ 081360CC  =REG_SOUNDCNT_X
	movs	r0, #0x80                             @ 081360CE
	strh	r0, [r1]                              @ 081360D0
	bx	lr                                      @ 081360D2
.Llit081360D4:
	.word	REG_SOUNDCNT_X                       @ 081360D4
@ --------------------------------------------------------------------------
@ gmpSetMasterVolume(v)  (0x081360D8)
@   ST_masterVol = v   (0..64)
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpSetMasterVolume
gmpSetMasterVolume:
	ldr	r1, .Llit081360E4                      @ 081360D8  =gmpState
	ldr	r1, [r1]                               @ 081360DA
	ldr	r2, .Llit081360E8                      @ 081360DC  =0x00001BA8
	adds	r1, r1, r2                            @ 081360DE
	str	r0, [r1]                               @ 081360E0  ST_masterVol
	bx	lr                                      @ 081360E2
.Llit081360E4:
	.word	gmpState                             @ 081360E4
.Llit081360E8:
	.word	0x00001BA8                           @ 081360E8
@ --------------------------------------------------------------------------
@ gmpSetMusicVolume(v)  (0x081360EC)
@   ST_musicVol = v   (0..64)
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpSetMusicVolume
gmpSetMusicVolume:
	ldr	r1, .Llit081360F8                      @ 081360EC  =gmpState
	ldr	r1, [r1]                               @ 081360EE
	ldr	r2, .Llit081360FC                      @ 081360F0  =0x00001BAC
	adds	r1, r1, r2                            @ 081360F2
	str	r0, [r1]                               @ 081360F4  ST_musicVol
	bx	lr                                      @ 081360F6
.Llit081360F8:
	.word	gmpState                             @ 081360F8
.Llit081360FC:
	.word	0x00001BAC                           @ 081360FC
@ --------------------------------------------------------------------------
@ gmpSetSfxVolume(v)  (0x08136100)
@   ST_sfxVol = v   (0..64)
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpSetSfxVolume
gmpSetSfxVolume:
	ldr	r1, .Llit0813610C                      @ 08136100  =gmpState
	ldr	r1, [r1]                               @ 08136102
	ldr	r2, .Llit08136110                      @ 08136104  =0x00001BB0
	adds	r1, r1, r2                            @ 08136106
	str	r0, [r1]                               @ 08136108  ST_sfxVol
	bx	lr                                      @ 0813610A
.Llit0813610C:
	.word	gmpState                             @ 0813610C
.Llit08136110:
	.word	0x00001BB0                           @ 08136110
@ --------------------------------------------------------------------------
@ gmpSetRate(idx)  (0x08136114)  -- unused
@   if (idx <= ST_maxRate) ST_newRate = idx;     applied by gmpApplyRate in the next gmpFrame
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpSetRate
gmpSetRate:
	adds	r2, r0, #0                            @ 08136114
	ldr	r0, .Llit08136128                      @ 08136116  =gmpState
	ldr	r1, [r0]                               @ 08136118
	ldr	r3, .Llit0813612C                      @ 0813611A  =0x00001BC8
	adds	r0, r1, r3                            @ 0813611C
	ldr	r0, [r0]                               @ 0813611E  ST_maxRate
	cmp	r2, r0                                 @ 08136120
	bhi	.L08136126                             @ 08136122
	str	r2, [r1, #0x24]                        @ 08136124  ST_newRate
.L08136126:
	bx	lr                                      @ 08136126
.Llit08136128:
	.word	gmpState                             @ 08136128
.Llit0813612C:
	.word	0x00001BC8                           @ 0813612C
@ --------------------------------------------------------------------------
@ gmpDmaRestart()  (0x08136130)
@   Host calls this first thing every frame (NFSU2: from its VBlank handler).
@     b = (&ST_buf0)[ST_cur]; if (ST_prev == ST_cur) ST_sameBuf = 1;
@     gmpDmaRestartAB(b)  (ARM: re-arm DMA1 and DMA2 at b);  return b
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpDmaRestart
gmpDmaRestart:
	push	{r4, lr}                              @ 08136130
	ldr	r0, .Llit08136158                      @ 08136132  =gmpState
	ldr	r2, [r0]                               @ 08136134
	ldr	r1, [r2, #8]                           @ 08136136  ST_cur
	lsls	r0, r1, #2                            @ 08136138
	adds	r0, r2, r0                            @ 0813613A
	ldr	r4, [r0]                               @ 0813613C
	ldr	r0, [r2, #0xc]                         @ 0813613E  ST_prev
	cmp	r0, r1                                 @ 08136140
	bne	.L08136148                             @ 08136142
	movs	r0, #1                                @ 08136144
	str	r0, [r2, #0x10]                        @ 08136146  ST_sameBuf
.L08136148:
	adds	r0, r4, #0                            @ 08136148
	bl	gmpDmaRestartAB                         @ 0813614A
	adds	r0, r4, #0                            @ 0813614E
	pop	{r4}                                   @ 08136150
	pop	{r1}                                   @ 08136152
	bx	r1                                      @ 08136154
	.hword	0x0000                              @ 08136156  (padding)
.Llit08136158:
	.word	gmpState                             @ 08136158
@ --------------------------------------------------------------------------
@ gmpApplyRate()  (0x0813615C)
@   if (ST_rateIdx != ST_newRate) {
@     TM0CNT_L = gmpRateTimer[i]; ST_rateHz, ST_stepTab, ST_bufBytes from the tables;
@     PL_tickHz = BPM*50*65536/125 >> 16; PL_rowLen = ST_rateHz * PL_speed / PL_tickHz;
@     gmpUpdateLinearStep() on all 12 channels (Amiga-mode steps are not refreshed);
@     clear both buffers (ST_maxBufBytes each) }
@   In Amiga mode CH_note holds a note number, so the linear refresh gives wrong pitches
@   until the next note-on (rate changes are unused in NFSU2).
@   if (ST_fade != 64) ST_fade = min(ST_fade + 3, 64)                  fade-in after a jingle
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpApplyRate
gmpApplyRate:
	push	{r4, r5, r6, lr}                      @ 0813615C
	ldr	r5, .Llit08136210                      @ 0813615E  =gmpState
	ldr	r3, [r5]                               @ 08136160
	ldr	r0, [r3, #0x20]                        @ 08136162  ST_rateIdx
	ldr	r4, [r3, #0x24]                        @ 08136164  ST_newRate
	cmp	r0, r4                                 @ 08136166
	beq	.L081361F4                             @ 08136168
	ldr	r0, .Llit08136214                      @ 0813616A  =gmpRateTimer
	lsls	r2, r4, #1                            @ 0813616C
	adds	r0, r2, r0                            @ 0813616E
	ldrh	r1, [r0]                              @ 08136170
	ldr	r0, .Llit08136218                      @ 08136172  =REG_TM0CNT_L
	strh	r1, [r0]                              @ 08136174
	str	r4, [r3, #0x20]                        @ 08136176  ST_rateIdx
	ldr	r0, .Llit0813621C                      @ 08136178  =gmpRateHz
	lsls	r1, r4, #2                            @ 0813617A
	adds	r0, r1, r0                            @ 0813617C
	ldr	r0, [r0]                               @ 0813617E
	str	r0, [r3, #0x48]                        @ 08136180  ST_rateHz
	ldr	r0, .Llit08136220                      @ 08136182  =gmpRateStepTab
	adds	r1, r1, r0                            @ 08136184
	ldr	r0, [r1]                               @ 08136186
	str	r0, [r3, #0x28]                        @ 08136188  ST_stepTab
	ldr	r0, .Llit08136224                      @ 0813618A  =0x00001BD0
	adds	r1, r3, r0                            @ 0813618C
	ldr	r0, .Llit08136228                      @ 0813618E  =gmpRateBufBytes
	adds	r2, r2, r0                            @ 08136190
	ldrh	r0, [r2]                              @ 08136192
	str	r0, [r1]                               @ 08136194  ST_bufBytes
	ldr	r4, .Llit0813622C                      @ 08136196  =gmpPlayer
	ldr	r0, [r4]                               @ 08136198
	ldr	r1, [r0, #0x3c]                        @ 0813619A  PL_bpm
	movs	r0, #0x32                             @ 0813619C
	muls	r0, r1, r0                            @ 0813619E
	lsls	r0, r0, #0x10                         @ 081361A0
	movs	r1, #0x7d                             @ 081361A2
	bl	swiDiv                                  @ 081361A4
	adds	r1, r0, #0                            @ 081361A8
	ldr	r2, [r4]                               @ 081361AA
	asrs	r1, r1, #0x10                         @ 081361AC
	str	r1, [r2, #0x1c]                        @ 081361AE  PL_tickHz = BPM*2/5
	ldr	r0, [r5]                               @ 081361B0
	ldr	r2, [r2, #0x14]                        @ 081361B2  PL_speed
	ldr	r0, [r0, #0x48]                        @ 081361B4  ST_rateHz
	muls	r0, r2, r0                            @ 081361B6
	bl	swiDiv                                  @ 081361B8
	ldr	r1, [r4]                               @ 081361BC
	str	r0, [r1, #0x24]                        @ 081361BE  PL_rowLen
	movs	r6, #0                                @ 081361C0
	movs	r5, #0x54                             @ 081361C2
.L081361C4:
	ldr	r0, [r4]                               @ 081361C4
	adds	r0, r0, r5                            @ 081361C6
	bl	gmpUpdateLinearStep                     @ 081361C8
	adds	r5, #0x98                             @ 081361CC
	adds	r6, #1                                @ 081361CE
	cmp	r6, #0xb                               @ 081361D0
	ble	.L081361C4                             @ 081361D2
	ldr	r4, .Llit08136210                      @ 081361D4  =gmpState
	ldr	r1, [r4]                               @ 081361D6
	ldr	r5, .Llit08136230                      @ 081361D8  =0x00001BCC
	ldr	r0, [r1]                               @ 081361DA  ST_buf0
	adds	r1, r1, r5                            @ 081361DC
	ldr	r2, [r1]                               @ 081361DE  ST_maxBufBytes
	movs	r1, #0                                @ 081361E0
	bl	memset                                  @ 081361E2
	ldr	r1, [r4]                               @ 081361E6
	ldr	r0, [r1, #4]                           @ 081361E8  ST_buf1
	adds	r1, r1, r5                            @ 081361EA
	ldr	r2, [r1]                               @ 081361EC  ST_maxBufBytes
	movs	r1, #0                                @ 081361EE
	bl	memset                                  @ 081361F0
.L081361F4:
	ldr	r0, .Llit08136210                      @ 081361F4  =gmpState
	ldr	r1, [r0]                               @ 081361F6
	ldr	r0, [r1, #0x50]                        @ 081361F8  ST_fade
	cmp	r0, #0x40                              @ 081361FA
	beq	.L0813620A                             @ 081361FC
	adds	r0, #3                                @ 081361FE
	str	r0, [r1, #0x50]                        @ 08136200  ST_fade
	cmp	r0, #0x40                              @ 08136202
	ble	.L0813620A                             @ 08136204
	movs	r0, #0x40                             @ 08136206
	str	r0, [r1, #0x50]                        @ 08136208  ST_fade
.L0813620A:
	pop	{r4, r5, r6}                           @ 0813620A
	pop	{r0}                                   @ 0813620C
	bx	r0                                      @ 0813620E
.Llit08136210:
	.word	gmpState                             @ 08136210
.Llit08136214:
	.word	gmpRateTimer                         @ 08136214
.Llit08136218:
	.word	REG_TM0CNT_L                         @ 08136218
.Llit0813621C:
	.word	gmpRateHz                            @ 0813621C
.Llit08136220:
	.word	gmpRateStepTab                       @ 08136220
.Llit08136224:
	.word	0x00001BD0                           @ 08136224
.Llit08136228:
	.word	gmpRateBufBytes                      @ 08136228
.Llit0813622C:
	.word	gmpPlayer                            @ 0813622C
.Llit08136230:
	.word	0x00001BCC                           @ 08136230
@ --------------------------------------------------------------------------
@ gmpTestTone(buf, len)  (0x08136234)
@   if (!ST_toneOn || !ST_sameBuf) return 0;
@   ST_toneFrame = (ST_toneFrame + 1) % 60;
@   if (ST_toneFrame < 30) fill buf with a sawtooth: phase += 0x055B9156; *buf++ = phase >> 27
@                          (0x055B9156 / 2^32 * 21024 Hz = 440 Hz: an A440 beep, 0.5 s on / 0.5 s off)
@   else memset(buf, 0, len);  return 1
@   ST_toneOn is never set anywhere, so this is a disabled factory test.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpTestTone
gmpTestTone:
	push	{r4, r5, lr}                          @ 08136234
	adds	r4, r0, #0                            @ 08136236
	adds	r2, r1, #0                            @ 08136238
	ldr	r1, .Llit08136280                      @ 0813623A  =gmpState
	ldr	r3, [r1]                               @ 0813623C
	ldr	r0, [r3, #0x14]                        @ 0813623E  ST_toneOn
	cmp	r0, #0                                 @ 08136240
	beq	.L08136294                             @ 08136242
	ldr	r0, [r3, #0x10]                        @ 08136244  ST_sameBuf
	cmp	r0, #0                                 @ 08136246
	beq	.L08136294                             @ 08136248
	ldr	r0, [r3, #0x1c]                        @ 0813624A  ST_toneFrame
	adds	r0, #1                                @ 0813624C
	str	r0, [r3, #0x1c]                        @ 0813624E  ST_toneFrame
	cmp	r0, #0x3b                              @ 08136250
	ble	.L08136258                             @ 08136252
	movs	r0, #0                                @ 08136254
	str	r0, [r3, #0x1c]                        @ 08136256  ST_toneFrame
.L08136258:
	ldr	r0, [r1]                               @ 08136258
	ldr	r0, [r0, #0x1c]                        @ 0813625A
	cmp	r0, #0x1d                              @ 0813625C
	bgt	.L08136288                             @ 0813625E
	cmp	r2, #0                                 @ 08136260
	beq	.L08136290                             @ 08136262
	adds	r5, r1, #0                            @ 08136264
	ldr	r3, .Llit08136284                      @ 08136266  =0x055B9156
.L08136268:
	ldr	r1, [r5]                               @ 08136268
	ldr	r0, [r1, #0x18]                        @ 0813626A
	adds	r0, r0, r3                            @ 0813626C  + 0x055B9156 per sample (440 Hz at 21024 Hz)
	str	r0, [r1, #0x18]                        @ 0813626E
	asrs	r0, r0, #0x1b                         @ 08136270
	strb	r0, [r4]                              @ 08136272  sawtooth sample
	adds	r4, #1                                @ 08136274
	subs	r2, #1                                @ 08136276
	cmp	r2, #0                                 @ 08136278
	bne	.L08136268                             @ 0813627A
	b	.L08136290                               @ 0813627C
	.hword	0x0000                              @ 0813627E  (padding)
.Llit08136280:
	.word	gmpState                             @ 08136280
.Llit08136284:
	.word	0x055B9156                           @ 08136284
.L08136288:
	adds	r0, r4, #0                            @ 08136288
	movs	r1, #0                                @ 0813628A
	bl	memset                                  @ 0813628C
.L08136290:
	movs	r0, #1                                @ 08136290
	b	.L08136296                               @ 08136292
.L08136294:
	movs	r0, #0                                @ 08136294
.L08136296:
	pop	{r4, r5}                               @ 08136296
	pop	{r1}                                   @ 08136298
	bx	r1                                      @ 0813629A
@ --------------------------------------------------------------------------
@ gmpFrame()  (0x0813629C)
@   Once per frame, after gmpDmaRestart.  Mixes the next frame into the idle buffer.
@     gmpApplyRate(); gmpServiceSongRequest(); gmpServiceJingle();
@     back = (&ST_buf0)[ST_cur ^ 1];
@     if (ST_mixMode == 0 || !ST_playing) memset(back, 0, ST_bufBytes)   (mode 1 with music: mixer overwrites)
@     if (ST_paused || !ST_rateHz) return;
@     if (gmpTestTone(back, ST_bufBytes)) return;
@     if (ST_mixMode == 0) {
@        gmpMix(back, 0, PL_nMusic);                                   music only
@        if (ST_echoLevel && ST_echoBuf) gmpApplyEcho(back, ST_echoLevel, ST_bufBytes);
@     } else gmpMix(back, 0, PL_nChan);                                music + SFX in one pass
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpFrame
gmpFrame:
	push	{r4, r5, r6, lr}                      @ 0813629C
	bl	gmpApplyRate                            @ 0813629E
	bl	gmpServiceSongRequest                   @ 081362A2
	bl	gmpServiceJingle                        @ 081362A6
	ldr	r0, .Llit081362D4                      @ 081362AA  =gmpState
	ldr	r2, [r0]                               @ 081362AC
	ldr	r1, .Llit081362D8                      @ 081362AE  =0x00001BF4
	adds	r0, r2, r1                            @ 081362B0
	ldr	r0, [r0]                               @ 081362B2  ST_mixMode
	cmp	r0, #0                                 @ 081362B4
	bne	.L081362E0                             @ 081362B6
	ldr	r0, [r2, #8]                           @ 081362B8  ST_cur
	movs	r1, #1                                @ 081362BA
	eors	r0, r1                                @ 081362BC
	lsls	r0, r0, #2                            @ 081362BE
	adds	r0, r2, r0                            @ 081362C0
	ldr	r0, [r0]                               @ 081362C2
	ldr	r3, .Llit081362DC                      @ 081362C4  =0x00001BD0
	adds	r1, r2, r3                            @ 081362C6
	ldr	r2, [r1]                               @ 081362C8  ST_bufBytes
	movs	r1, #0                                @ 081362CA
	bl	memset                                  @ 081362CC
	b	.L08136304                               @ 081362D0
	.hword	0x0000                              @ 081362D2  (padding)
.Llit081362D4:
	.word	gmpState                             @ 081362D4
.Llit081362D8:
	.word	0x00001BF4                           @ 081362D8
.Llit081362DC:
	.word	0x00001BD0                           @ 081362DC
.L081362E0:
	ldr	r1, .Llit08136380                      @ 081362E0  =0x00001BBC
	adds	r0, r2, r1                            @ 081362E2
	movs	r3, #0                                @ 081362E4
	ldrsh	r0, [r0, r3]                         @ 081362E6
	cmp	r0, #0                                 @ 081362E8
	bne	.L08136304                             @ 081362EA
	ldr	r0, [r2, #8]                           @ 081362EC
	movs	r1, #1                                @ 081362EE
	eors	r0, r1                                @ 081362F0
	lsls	r0, r0, #2                            @ 081362F2
	adds	r0, r2, r0                            @ 081362F4
	ldr	r0, [r0]                               @ 081362F6
	ldr	r3, .Llit08136384                      @ 081362F8  =0x00001BD0
	adds	r1, r2, r3                            @ 081362FA
	ldr	r2, [r1]                               @ 081362FC
	movs	r1, #0                                @ 081362FE
	bl	memset                                  @ 08136300
.L08136304:
	ldr	r5, .Llit08136388                      @ 08136304  =gmpState
	ldr	r1, [r5]                               @ 08136306
	ldr	r0, [r1, #0x44]                        @ 08136308  ST_paused
	cmp	r0, #0                                 @ 0813630A
	bne	.L081363B6                             @ 0813630C
	ldr	r0, [r1, #0x48]                        @ 0813630E  ST_rateHz
	cmp	r0, #0                                 @ 08136310
	beq	.L081363B6                             @ 08136312
	ldr	r0, [r1, #8]                           @ 08136314  ST_cur
	movs	r4, #1                                @ 08136316
	eors	r0, r4                                @ 08136318
	lsls	r0, r0, #2                            @ 0813631A
	adds	r0, r1, r0                            @ 0813631C
	ldr	r0, [r0]                               @ 0813631E
	ldr	r6, .Llit08136384                      @ 08136320  =0x00001BD0
	adds	r1, r1, r6                            @ 08136322
	ldr	r1, [r1]                               @ 08136324  ST_bufBytes
	bl	gmpTestTone                             @ 08136326
	cmp	r0, #0                                 @ 0813632A
	bne	.L081363B6                             @ 0813632C
	ldr	r1, [r5]                               @ 0813632E
	ldr	r2, .Llit0813638C                      @ 08136330  =0x00001BF4
	adds	r0, r1, r2                            @ 08136332
	ldr	r0, [r0]                               @ 08136334  ST_mixMode
	cmp	r0, #0                                 @ 08136336
	bne	.L0813639C                             @ 08136338
	ldr	r0, [r1, #8]                           @ 0813633A  ST_cur
	eors	r0, r4                                @ 0813633C
	lsls	r0, r0, #2                            @ 0813633E
	adds	r0, r1, r0                            @ 08136340
	ldr	r0, [r0]                               @ 08136342
	ldr	r1, .Llit08136390                      @ 08136344  =gmpPlayer
	ldr	r1, [r1]                               @ 08136346
	ldr	r3, .Llit08136394                      @ 08136348  =0x00000B94
	adds	r1, r1, r3                            @ 0813634A
	ldr	r2, [r1]                               @ 0813634C  PL_nMusic
	movs	r1, #0                                @ 0813634E
	bl	gmpMix                                  @ 08136350
	ldr	r1, [r5]                               @ 08136354
	ldr	r2, .Llit08136398                      @ 08136356  =0x00001BF0
	adds	r0, r1, r2                            @ 08136358
	ldr	r3, [r0]                               @ 0813635A  ST_echoLevel
	cmp	r3, #0                                 @ 0813635C
	beq	.L081363B6                             @ 0813635E
	subs	r2, #0xc                              @ 08136360
	adds	r0, r1, r2                            @ 08136362
	ldr	r0, [r0]                               @ 08136364  ST_echoBuf
	cmp	r0, #0                                 @ 08136366
	beq	.L081363B6                             @ 08136368
	ldr	r0, [r1, #8]                           @ 0813636A  ST_cur
	eors	r0, r4                                @ 0813636C
	lsls	r0, r0, #2                            @ 0813636E
	adds	r0, r1, r0                            @ 08136370
	ldr	r0, [r0]                               @ 08136372
	adds	r1, r1, r6                            @ 08136374
	ldr	r2, [r1]                               @ 08136376  ST_bufBytes
	adds	r1, r3, #0                            @ 08136378
	bl	gmpApplyEcho                            @ 0813637A
	b	.L081363B6                               @ 0813637E
.Llit08136380:
	.word	0x00001BBC                           @ 08136380
.Llit08136384:
	.word	0x00001BD0                           @ 08136384
.Llit08136388:
	.word	gmpState                             @ 08136388
.Llit0813638C:
	.word	0x00001BF4                           @ 0813638C
.Llit08136390:
	.word	gmpPlayer                            @ 08136390
.Llit08136394:
	.word	0x00000B94                           @ 08136394
.Llit08136398:
	.word	0x00001BF0                           @ 08136398
.L0813639C:
	ldr	r0, [r1, #8]                           @ 0813639C
	eors	r0, r4                                @ 0813639E
	lsls	r0, r0, #2                            @ 081363A0
	adds	r0, r1, r0                            @ 081363A2
	ldr	r0, [r0]                               @ 081363A4
	ldr	r1, .Llit081363BC                      @ 081363A6  =gmpPlayer
	ldr	r1, [r1]                               @ 081363A8
	ldr	r3, .Llit081363C0                      @ 081363AA  =0x00000B9C
	adds	r1, r1, r3                            @ 081363AC
	ldr	r2, [r1]                               @ 081363AE  PL_nChan
	movs	r1, #0                                @ 081363B0
	bl	gmpMix                                  @ 081363B2
.L081363B6:
	pop	{r4, r5, r6}                           @ 081363B6
	pop	{r0}                                   @ 081363B8
	bx	r0                                      @ 081363BA
.Llit081363BC:
	.word	gmpPlayer                            @ 081363BC
.Llit081363C0:
	.word	0x00000B9C                           @ 081363C0
@ --------------------------------------------------------------------------
@ gmpFlip()  (0x081363C4)
@   Last call of the frame.  if (ST_mixMode == 0) gmpMixSfx(back)  -- SFX are added after the echo
@   ST_prev = ST_cur; ST_cur ^= 1
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpFlip
gmpFlip:
	push	{r4, lr}                              @ 081363C4
	ldr	r4, .Llit081363F8                      @ 081363C6  =gmpState
	ldr	r2, [r4]                               @ 081363C8
	ldr	r1, .Llit081363FC                      @ 081363CA  =0x00001BF4
	adds	r0, r2, r1                            @ 081363CC
	ldr	r0, [r0]                               @ 081363CE  ST_mixMode
	cmp	r0, #0                                 @ 081363D0
	bne	.L081363E4                             @ 081363D2
	ldr	r0, [r2, #8]                           @ 081363D4  ST_cur
	movs	r1, #1                                @ 081363D6
	eors	r0, r1                                @ 081363D8
	lsls	r0, r0, #2                            @ 081363DA
	adds	r0, r2, r0                            @ 081363DC
	ldr	r0, [r0]                               @ 081363DE
	bl	gmpMixSfx                               @ 081363E0
.L081363E4:
	ldr	r0, [r4]                               @ 081363E4
	ldr	r1, [r0, #8]                           @ 081363E6
	str	r1, [r0, #0xc]                         @ 081363E8
	movs	r2, #1                                @ 081363EA
	eors	r1, r2                                @ 081363EC
	str	r1, [r0, #8]                           @ 081363EE
	pop	{r4}                                   @ 081363F0
	pop	{r0}                                   @ 081363F2
	bx	r0                                      @ 081363F4
	.hword	0x0000                              @ 081363F6  (padding)
.Llit081363F8:
	.word	gmpState                             @ 081363F8
.Llit081363FC:
	.word	0x00001BF4                           @ 081363FC
@ --------------------------------------------------------------------------
@ gmpIwramAlloc(size, &used)  (0x08136400)
@   size = (size + 3) & ~3; p = ST_iwramPtr; ST_iwramPtr += size; memset(p, 0, size); *used += size; return p
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpIwramAlloc
gmpIwramAlloc:
	push	{r4, r5, r6, lr}                      @ 08136400
	adds	r4, r0, #0                            @ 08136402
	adds	r6, r1, #0                            @ 08136404
	ldr	r0, .Llit08136430                      @ 08136406  =gmpState
	ldr	r1, [r0]                               @ 08136408
	ldr	r5, [r1, #0x30]                        @ 0813640A  ST_iwramPtr
	adds	r4, #3                                @ 0813640C
	movs	r0, #4                                @ 0813640E
	rsbs	r0, r0, #0                            @ 08136410
	ands	r4, r0                                @ 08136412
	adds	r0, r5, r4                            @ 08136414
	str	r0, [r1, #0x30]                        @ 08136416  ST_iwramPtr
	adds	r0, r5, #0                            @ 08136418
	movs	r1, #0                                @ 0813641A
	adds	r2, r4, #0                            @ 0813641C
	bl	memset                                  @ 0813641E
	ldr	r0, [r6]                               @ 08136422
	adds	r0, r0, r4                            @ 08136424
	str	r0, [r6]                               @ 08136426
	adds	r0, r5, #0                            @ 08136428
	pop	{r4, r5, r6}                           @ 0813642A
	pop	{r1}                                   @ 0813642C
	bx	r1                                      @ 0813642E
.Llit08136430:
	.word	gmpState                             @ 08136430
@ --------------------------------------------------------------------------
@ gmpSetupIwram(params, withEchoWork)  (0x08136434)
@   Carves the host's IWRAM block (params->iwram):
@     ST_mixer   = alloc(params->mixMode ? 0x3EC : 0xA0)        decompressed mixer
@     ST_echoWork= alloc(0x2E4) if withEchoWork (always 0)
@     ST_buf0/1  = alloc(ST_maxBufBytes) each
@     gmpUnpackMixer(params)
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpSetupIwram
gmpSetupIwram:
	push	{r4, r5, r6, r7, lr}                  @ 08136434
	adds	r7, r0, #0                            @ 08136436
	adds	r5, r1, #0                            @ 08136438
	ldr	r4, .Llit0813645C                      @ 0813643A  =gmpState
	ldr	r1, [r4]                               @ 0813643C
	ldr	r0, [r7]                               @ 0813643E
	str	r0, [r1, #0x30]                        @ 08136440  ST_iwramPtr
	ldr	r0, .Llit08136460                      @ 08136442  =0x00001BD4
	adds	r2, r1, r0                            @ 08136444
	movs	r0, #0                                @ 08136446
	str	r0, [r2]                               @ 08136448  ST_iwramUsed
	ldr	r0, .Llit08136464                      @ 0813644A  =0x00001BD8
	adds	r1, r1, r0                            @ 0813644C
	ldr	r0, .Llit08136468                      @ 0813644E  =0x00001E4C
	str	r0, [r1]                               @ 08136450  ST_size
	ldr	r0, [r7, #0x18]                        @ 08136452
	cmp	r0, #0                                 @ 08136454
	bne	.L0813646C                             @ 08136456
	movs	r0, #0xa0                             @ 08136458
	b	.L08136474                               @ 0813645A
.Llit0813645C:
	.word	gmpState                             @ 0813645C
.Llit08136460:
	.word	0x00001BD4                           @ 08136460
.Llit08136464:
	.word	0x00001BD8                           @ 08136464
.Llit08136468:
	.word	0x00001E4C                           @ 08136468
.L0813646C:
	cmp	r0, #1                                 @ 0813646C
	bne	.L0813647E                             @ 0813646E
	movs	r0, #0xfb                             @ 08136470
	lsls	r0, r0, #2                            @ 08136472
.L08136474:
	adds	r1, r2, #0                            @ 08136474
	bl	gmpIwramAlloc                           @ 08136476
	ldr	r1, [r4]                               @ 0813647A
	str	r0, [r1, #0x38]                        @ 0813647C
.L0813647E:
	cmp	r5, #0                                 @ 0813647E
	beq	.L08136496                             @ 08136480
	movs	r0, #0xb9                             @ 08136482
	lsls	r0, r0, #2                            @ 08136484
	ldr	r4, .Llit081364C8                      @ 08136486  =gmpState
	ldr	r1, [r4]                               @ 08136488
	ldr	r2, .Llit081364CC                      @ 0813648A  =0x00001BD4
	adds	r1, r1, r2                            @ 0813648C
	bl	gmpIwramAlloc                           @ 0813648E
	ldr	r1, [r4]                               @ 08136492
	str	r0, [r1, #0x3c]                        @ 08136494  ST_echoWork
.L08136496:
	ldr	r5, .Llit081364C8                      @ 08136496  =gmpState
	ldr	r1, [r5]                               @ 08136498
	ldr	r4, .Llit081364D0                      @ 0813649A  =0x00001BCC
	adds	r0, r1, r4                            @ 0813649C
	ldr	r0, [r0]                               @ 0813649E  ST_maxBufBytes
	ldr	r6, .Llit081364CC                      @ 081364A0  =0x00001BD4
	adds	r1, r1, r6                            @ 081364A2
	bl	gmpIwramAlloc                           @ 081364A4
	ldr	r1, [r5]                               @ 081364A8
	str	r0, [r1]                               @ 081364AA  ST_buf0
	adds	r4, r1, r4                            @ 081364AC
	ldr	r0, [r4]                               @ 081364AE  ST_maxBufBytes
	adds	r1, r1, r6                            @ 081364B0
	bl	gmpIwramAlloc                           @ 081364B2
	ldr	r1, [r5]                               @ 081364B6
	str	r0, [r1, #4]                           @ 081364B8  ST_buf1
	adds	r0, r7, #0                            @ 081364BA
	bl	gmpUnpackMixer                          @ 081364BC
	pop	{r4, r5, r6, r7}                       @ 081364C0
	pop	{r0}                                   @ 081364C2
	bx	r0                                      @ 081364C4
	.hword	0x0000                              @ 081364C6  (padding)
.Llit081364C8:
	.word	gmpState                             @ 081364C8
.Llit081364CC:
	.word	0x00001BD4                           @ 081364CC
.Llit081364D0:
	.word	0x00001BCC                           @ 081364D0
@ --------------------------------------------------------------------------
@ gmpRle8Next(state, start)  (0x081364D4)
@   Byte RLE stream reader: runs of {count, value}.  start != 0 begins a new stream.
@   state = {ptr, left, value}.  Returns the value for this row.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpRle8Next
gmpRle8Next:
	adds	r3, r0, #0                            @ 081364D4
	cmp	r1, #0                                 @ 081364D6
	beq	.L081364E4                             @ 081364D8
	ldrb	r2, [r1]                              @ 081364DA
	adds	r1, #1                                @ 081364DC
	ldrb	r0, [r1]                              @ 081364DE
	adds	r1, #1                                @ 081364E0
	b	.L081364EA                               @ 081364E2
.L081364E4:
	ldr	r1, [r3]                               @ 081364E4
	ldr	r2, [r3, #4]                           @ 081364E6
	ldr	r0, [r3, #8]                           @ 081364E8
.L081364EA:
	cmp	r2, #0                                 @ 081364EA
	bgt	.L081364F6                             @ 081364EC
	ldrb	r2, [r1]                              @ 081364EE
	adds	r1, #1                                @ 081364F0
	ldrb	r0, [r1]                              @ 081364F2
	adds	r1, #1                                @ 081364F4
.L081364F6:
	subs	r2, #1                                @ 081364F6
	str	r1, [r3]                               @ 081364F8
	str	r2, [r3, #4]                           @ 081364FA
	str	r0, [r3, #8]                           @ 081364FC
	bx	lr                                      @ 081364FE
@ --------------------------------------------------------------------------
@ gmpRle16Next(state, start)  (0x08136500)
@   Word RLE stream reader: runs of {count, hi, lo} (big-endian value).  Same state layout.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpRle16Next
gmpRle16Next:
	push	{r4, lr}                              @ 08136500
	adds	r4, r0, #0                            @ 08136502
	cmp	r1, #0                                 @ 08136504
	beq	.L0813651A                             @ 08136506
	ldrb	r3, [r1]                              @ 08136508
	adds	r1, #1                                @ 0813650A
	ldrb	r0, [r1]                              @ 0813650C
	lsls	r2, r0, #8                            @ 0813650E
	adds	r1, #1                                @ 08136510
	ldrb	r0, [r1]                              @ 08136512
	orrs	r2, r0                                @ 08136514
	adds	r1, #1                                @ 08136516
	b	.L08136520                               @ 08136518
.L0813651A:
	ldr	r1, [r4]                               @ 0813651A
	ldr	r3, [r4, #4]                           @ 0813651C
	ldr	r2, [r4, #8]                           @ 0813651E
.L08136520:
	cmp	r3, #0                                 @ 08136520
	bgt	.L08136534                             @ 08136522
	ldrb	r3, [r1]                              @ 08136524
	adds	r1, #1                                @ 08136526
	ldrb	r0, [r1]                              @ 08136528
	lsls	r2, r0, #8                            @ 0813652A
	adds	r1, #1                                @ 0813652C
	ldrb	r0, [r1]                              @ 0813652E
	orrs	r2, r0                                @ 08136530
	adds	r1, #1                                @ 08136532
.L08136534:
	subs	r3, #1                                @ 08136534
	str	r1, [r4]                               @ 08136536
	str	r3, [r4, #4]                           @ 08136538
	str	r2, [r4, #8]                           @ 0813653A
	adds	r0, r2, #0                            @ 0813653C
	pop	{r4}                                   @ 0813653E
	pop	{r1}                                   @ 08136540
	bx	r1                                      @ 08136542
@ --------------------------------------------------------------------------
@ gmpUnpackMixer(params)  (0x08136544)
@   swiLZ77UnCompWram(params->mixMode ? gmpMixerMultiLZ : gmpMixerMonoLZ, ST_mixer)
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpUnpackMixer
gmpUnpackMixer:
	push	{lr}                                  @ 08136544
	ldr	r1, .Llit0813655C                      @ 08136546  =gmpState
	ldr	r1, [r1]                               @ 08136548
	ldr	r1, [r1, #0x38]                        @ 0813654A  ST_mixer
	ldr	r0, [r0, #0x18]                        @ 0813654C
	cmp	r0, #0                                 @ 0813654E
	bne	.L08136564                             @ 08136550
	ldr	r0, .Llit08136560                      @ 08136552  =gmpMixerMonoLZ
	bl	swiLZ77UnCompWram                       @ 08136554
	b	.L0813656E                               @ 08136558
	.hword	0x0000                              @ 0813655A  (padding)
.Llit0813655C:
	.word	gmpState                             @ 0813655C
.Llit08136560:
	.word	gmpMixerMonoLZ                       @ 08136560
.L08136564:
	cmp	r0, #1                                 @ 08136564
	bne	.L0813656E                             @ 08136566
	ldr	r0, .Llit08136574                      @ 08136568  =gmpMixerMultiLZ
	bl	swiLZ77UnCompWram                       @ 0813656A
.L0813656E:
	pop	{r0}                                   @ 0813656E
	bx	r0                                      @ 08136570
	.hword	0x0000                              @ 08136572  (padding)
.Llit08136574:
	.word	gmpMixerMultiLZ                      @ 08136574
@ --------------------------------------------------------------------------
@ gmpLoadModule(player, module)  (0x08136578)
@   PL_speed = module[0x148]; PL_bpm = module[0x144];
@   if (module[0..7] != "GBAMOD30") return 0;
@   PL_nMusic = min(module[0x28], 12);
@   PL_nSfx = min(12 - module[0x28], ST_maxSfx);   PL_nChan = PL_nMusic + PL_nSfx
@   PL_rows = module[0x13C]; PL_amiga = module[0x140]; PL_module = module; PL_patBase = module + 0x650
@   Note: PL_nSfx uses the unclamped channel count, so a 13+ channel module would give a
@   negative SFX count.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpLoadModule
gmpLoadModule:
	push	{r4, r5, r6, r7, lr}                  @ 08136578
	adds	r4, r0, #0                            @ 0813657A
	adds	r3, r1, #0                            @ 0813657C
	movs	r1, #0xa4                             @ 0813657E
	lsls	r1, r1, #1                            @ 08136580
	adds	r0, r3, r1                            @ 08136582
	ldr	r0, [r0]                               @ 08136584
	str	r0, [r4, #0x14]                        @ 08136586  PL_speed
	movs	r2, #0xa2                             @ 08136588
	lsls	r2, r2, #1                            @ 0813658A
	adds	r0, r3, r2                            @ 0813658C
	ldr	r0, [r0]                               @ 0813658E
	str	r0, [r4, #0x3c]                        @ 08136590  PL_bpm
	ldr	r1, [r3]                               @ 08136592
	ldr	r2, [r3, #4]                           @ 08136594
	ldr	r0, .Llit081365A8                      @ 08136596  =0x4D414247
	cmp	r1, r0                                 @ 08136598  "GBAM"
	bne	.L081365A2                             @ 0813659A
	ldr	r0, .Llit081365AC                      @ 0813659C  =0x3033444F
	cmp	r2, r0                                 @ 0813659E  "OD30"
	beq	.L081365B0                             @ 081365A0
.L081365A2:
	movs	r0, #0                                @ 081365A2
	b	.L0813661A                               @ 081365A4
	.hword	0x0000                              @ 081365A6  (padding)
.Llit081365A8:
	.word	0x4D414247                           @ 081365A8
.Llit081365AC:
	.word	0x3033444F                           @ 081365AC
.L081365B0:
	ldr	r5, .Llit08136620                      @ 081365B0  =gmpPlayer
	ldr	r0, [r5]                               @ 081365B2
	ldr	r7, .Llit08136624                      @ 081365B4  =0x00000B94
	mov	ip, r7                                 @ 081365B6
	mov	r2, ip                                 @ 081365B8
	adds	r1, r0, r2                            @ 081365BA
	ldr	r0, [r3, #0x28]                        @ 081365BC
	str	r0, [r1]                               @ 081365BE  PL_nMusic = module->channels
	cmp	r0, #0xc                               @ 081365C0
	ble	.L081365C8                             @ 081365C2
	movs	r0, #0xc                              @ 081365C4
	str	r0, [r1]                               @ 081365C6  PL_nMusic
.L081365C8:
	ldr	r0, [r5]                               @ 081365C8
	ldr	r6, .Llit08136628                      @ 081365CA  =0x00000B98
	adds	r2, r0, r6                            @ 081365CC
	ldr	r0, [r3, #0x28]                        @ 081365CE
	movs	r1, #0xc                              @ 081365D0
	subs	r1, r1, r0                            @ 081365D2
	str	r1, [r2]                               @ 081365D4  PL_nSfx
	ldr	r0, .Llit0813662C                      @ 081365D6  =gmpState
	ldr	r0, [r0]                               @ 081365D8
	ldr	r7, .Llit08136630                      @ 081365DA  =0x00001BC4
	adds	r0, r0, r7                            @ 081365DC
	ldr	r0, [r0]                               @ 081365DE  ST_maxSfx
	cmp	r1, r0                                 @ 081365E0
	ble	.L081365E6                             @ 081365E2
	str	r0, [r2]                               @ 081365E4
.L081365E6:
	ldr	r1, [r5]                               @ 081365E6
	ldr	r0, .Llit08136634                      @ 081365E8  =0x00000B9C
	adds	r2, r1, r0                            @ 081365EA
	mov	r5, ip                                 @ 081365EC
	adds	r0, r1, r5                            @ 081365EE
	adds	r1, r1, r6                            @ 081365F0
	ldr	r0, [r0]                               @ 081365F2
	ldr	r1, [r1]                               @ 081365F4
	adds	r0, r0, r1                            @ 081365F6
	str	r0, [r2]                               @ 081365F8
	movs	r7, #0x9e                             @ 081365FA
	lsls	r7, r7, #1                            @ 081365FC
	adds	r0, r3, r7                            @ 081365FE
	ldr	r0, [r0]                               @ 08136600
	str	r0, [r4, #8]                           @ 08136602  PL_rows
	movs	r1, #0xa0                             @ 08136604
	lsls	r1, r1, #1                            @ 08136606
	adds	r0, r3, r1                            @ 08136608
	ldr	r0, [r0]                               @ 0813660A
	str	r0, [r4, #4]                           @ 0813660C  PL_amiga
	str	r3, [r4]                               @ 0813660E
	movs	r2, #0xca                             @ 08136610
	lsls	r2, r2, #3                            @ 08136612
	adds	r0, r3, r2                            @ 08136614
	str	r0, [r4, #0x50]                        @ 08136616  PL_patBase = module + 0x650
	movs	r0, #1                                @ 08136618
.L0813661A:
	pop	{r4, r5, r6, r7}                       @ 0813661A
	pop	{r1}                                   @ 0813661C
	bx	r1                                      @ 0813661E
.Llit08136620:
	.word	gmpPlayer                            @ 08136620
.Llit08136624:
	.word	0x00000B94                           @ 08136624
.Llit08136628:
	.word	0x00000B98                           @ 08136628
.Llit0813662C:
	.word	gmpState                             @ 0813662C
.Llit08136630:
	.word	0x00001BC4                           @ 08136630
.Llit08136634:
	.word	0x00000B9C                           @ 08136634
@ --------------------------------------------------------------------------
@ gmpLoadSampleBank(bank)  (0x08136638)
@   bank = 256 headers of 12 bytes {len, finetune, volume, loopStart, loopLen, relNote} + PCM
@   for i in 0..255: ST_smpPtr[i] = len ? bank + 0xC00 + (sum of earlier lengths) : 0
@   ST_smpHeaders = bank
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpLoadSampleBank
gmpLoadSampleBank:
	push	{r4, r5, r6, r7, lr}                  @ 08136638
	mov	r7, sl                                 @ 0813663A
	mov	r6, sb                                 @ 0813663C
	mov	r5, r8                                 @ 0813663E
	push	{r5, r6, r7}                          @ 08136640
	mov	sl, r0                                 @ 08136642
	mov	r2, sl                                 @ 08136644
	movs	r0, #0xc0                             @ 08136646
	lsls	r0, r0, #4                            @ 08136648
	add	r0, sl                                 @ 0813664A
	mov	r8, r0                                 @ 0813664C
	movs	r5, #0                                @ 0813664E
	ldr	r1, .Llit08136670                      @ 08136650  =gmpState
	mov	sb, r1                                 @ 08136652
	mov	ip, sb                                 @ 08136654
	movs	r7, #0xbd                             @ 08136656
	lsls	r7, r7, #5                            @ 08136658
	movs	r3, #0                                @ 0813665A
	movs	r4, #0xff                             @ 0813665C
.L0813665E:
	ldrh	r1, [r2]                              @ 0813665E
	cmp	r1, #0                                 @ 08136660
	bne	.L08136674                             @ 08136662
	mov	r6, ip                                 @ 08136664
	ldr	r0, [r6]                               @ 08136666
	adds	r0, r0, r7                            @ 08136668
	adds	r0, r0, r3                            @ 0813666A
	str	r1, [r0]                               @ 0813666C
	b	.L08136686                               @ 0813666E
.Llit08136670:
	.word	gmpState                             @ 08136670
.L08136674:
	mov	r1, ip                                 @ 08136674
	ldr	r0, [r1]                               @ 08136676
	adds	r0, r0, r7                            @ 08136678
	adds	r0, r0, r3                            @ 0813667A
	mov	r6, r8                                 @ 0813667C
	adds	r1, r6, r5                            @ 0813667E
	str	r1, [r0]                               @ 08136680
	ldrh	r0, [r2]                              @ 08136682
	adds	r5, r5, r0                            @ 08136684
.L08136686:
	adds	r2, #0xc                              @ 08136686
	adds	r3, #4                                @ 08136688
	subs	r4, #1                                @ 0813668A
	cmp	r4, #0                                 @ 0813668C
	bge	.L0813665E                             @ 0813668E
	mov	r1, sb                                 @ 08136690
	ldr	r0, [r1]                               @ 08136692
	ldr	r6, .Llit081366AC                      @ 08136694  =0x0000179C
	adds	r0, r0, r6                            @ 08136696
	mov	r1, sl                                 @ 08136698
	str	r1, [r0]                               @ 0813669A
	pop	{r3, r4, r5}                           @ 0813669C
	mov	r8, r3                                 @ 0813669E
	mov	sb, r4                                 @ 081366A0
	mov	sl, r5                                 @ 081366A2
	pop	{r4, r5, r6, r7}                       @ 081366A4
	pop	{r0}                                   @ 081366A6
	bx	r0                                      @ 081366A8
	.hword	0x0000                              @ 081366AA  (padding)
.Llit081366AC:
	.word	0x0000179C                           @ 081366AC
@ --------------------------------------------------------------------------
@ gmpLoadSfxBank(bank)  (0x081366B0)
@   bank = {u32 count; 24-byte entries[count]; PCM}
@   ST_sfxCount = count; ST_sfxEntries(+0x1BA0) = bank + 4; ST_sfxData = bank + 4 + count * 24
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpLoadSfxBank
gmpLoadSfxBank:
	push	{r4, lr}                              @ 081366B0
	ldr	r1, .Llit081366DC                      @ 081366B2  =gmpState
	ldr	r3, [r1]                               @ 081366B4
	ldr	r2, .Llit081366E0                      @ 081366B6  =0x00001BB8
	adds	r1, r3, r2                            @ 081366B8
	ldm	r0!, {r2}                              @ 081366BA
	str	r2, [r1]                               @ 081366BC  ST_sfxCount
	movs	r4, #0xdd                             @ 081366BE
	lsls	r4, r4, #5                            @ 081366C0
	adds	r1, r3, r4                            @ 081366C2
	str	r0, [r1]                               @ 081366C4  ST_sfxEntries
	ldr	r1, .Llit081366E4                      @ 081366C6  =0x00001BA4
	adds	r3, r3, r1                            @ 081366C8
	lsls	r1, r2, #1                            @ 081366CA
	adds	r1, r1, r2                            @ 081366CC
	lsls	r1, r1, #3                            @ 081366CE
	adds	r0, r0, r1                            @ 081366D0
	str	r0, [r3]                               @ 081366D2  ST_sfxData
	pop	{r4}                                   @ 081366D4
	pop	{r0}                                   @ 081366D6
	bx	r0                                      @ 081366D8
	.hword	0x0000                              @ 081366DA  (padding)
.Llit081366DC:
	.word	gmpState                             @ 081366DC
.Llit081366E0:
	.word	0x00001BB8                           @ 081366E0
.Llit081366E4:
	.word	0x00001BA4                           @ 081366E4
@ --------------------------------------------------------------------------
@ gmpInit(params, rateIdx, maxSfx, dmaMode)  (0x081366E8)
@   params = {iwram, iwramSize, work, workSize, sampleBank, sfxBank, mixMode}
@     gmpState = params->work; rateIdx = min(rateIdx, 4)            (rates 5..8 unreachable)
@     if (params->workSize < 0x1E4C) return -2;  memset(work, 0, 0x1E4C)
@     ST_maxRate = rateIdx; ST_maxBufBytes = ST_bufBytes = gmpRateBufBytes[rateIdx];
@     ST_mixMode = params->mixMode;
@     need = 2 * bufBytes + (mixMode ? 0x3EC : 0xA0); if (params->iwramSize < need) return -1;
@     if (!params->sampleBank) return -3;
@     if (params->sfxBank) gmpLoadSfxBank();  gmpLoadSampleBank();  gmpSetupIwram(params, 0);
@     if (!ST_dmaOn) { gmpStartDma((&ST_buf0)[ST_cur], rateIdx, dmaMode); ST_dmaOn = 1 }
@     ST_maxSfx = maxSfx; gmpPlayer = &ST_player0; clear 12 channels;
@     ST_cur = 0; ST_prev = 1; ST_sameBuf = ST_toneFrame = ST_toneOn = 0
@     return ST_sfxCount
@   NFSU2: {0x03005B10, 0x54C, malloc(0x26AC), 0x2000, 0x080431FC, 0x08000210, 0}, rate 4, 4 SFX, mode 2
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpInit
gmpInit:
	push	{r4, r5, r6, r7, lr}                  @ 081366E8
	mov	r7, sl                                 @ 081366EA
	mov	r6, sb                                 @ 081366EC
	mov	r5, r8                                 @ 081366EE
	push	{r5, r6, r7}                          @ 081366F0
	adds	r4, r0, #0                            @ 081366F2
	adds	r7, r1, #0                            @ 081366F4
	mov	sb, r2                                 @ 081366F6
	mov	sl, r3                                 @ 081366F8
	movs	r0, #0                                @ 081366FA
	mov	r8, r0                                 @ 081366FC
	ldr	r5, .Llit08136734                      @ 081366FE  =gmpState
	ldr	r1, [r4, #8]                           @ 08136700
	str	r1, [r5]                               @ 08136702
	cmp	r7, #4                                 @ 08136704
	bls	.L0813670A                             @ 08136706  rateIdx = min(rateIdx, 4)
	movs	r7, #4                                @ 08136708
.L0813670A:
	ldr	r2, .Llit08136738                      @ 0813670A  =0x00001BF8
	adds	r0, r1, r2                            @ 0813670C
	mov	r2, r8                                 @ 0813670E
	str	r2, [r0]                               @ 08136710
	ldr	r2, .Llit0813673C                      @ 08136712  =0x00001BFC
	adds	r0, r1, r2                            @ 08136714
	mov	r2, r8                                 @ 08136716
	str	r2, [r0]                               @ 08136718
	movs	r2, #0xe0                             @ 0813671A
	lsls	r2, r2, #5                            @ 0813671C
	adds	r0, r1, r2                            @ 0813671E
	mov	r1, r8                                 @ 08136720
	strb	r1, [r0]                              @ 08136722
	ldr	r6, .Llit08136740                      @ 08136724  =0x00001E4C
	ldr	r0, [r4, #0xc]                         @ 08136726
	cmp	r6, r0                                 @ 08136728
	bls	.L08136744                             @ 0813672A
	movs	r0, #2                                @ 0813672C
	rsbs	r0, r0, #0                            @ 0813672E
	b	.L0813684A                               @ 08136730  return -2 (work block too small)
	.hword	0x0000                              @ 08136732  (padding)
.Llit08136734:
	.word	gmpState                             @ 08136734
.Llit08136738:
	.word	0x00001BF8                           @ 08136738
.Llit0813673C:
	.word	0x00001BFC                           @ 0813673C
.Llit08136740:
	.word	0x00001E4C                           @ 08136740
.L08136744:
	ldr	r0, [r5]                               @ 08136744
	movs	r1, #0                                @ 08136746
	adds	r2, r6, #0                            @ 08136748
	bl	memset                                  @ 0813674A
	ldr	r1, [r5]                               @ 0813674E
	ldr	r2, .Llit08136788                      @ 08136750  =0x00001BE4
	adds	r0, r1, r2                            @ 08136752
	mov	r5, r8                                 @ 08136754
	str	r5, [r0]                               @ 08136756
	subs	r2, #0x1c                             @ 08136758
	adds	r0, r1, r2                            @ 0813675A
	str	r7, [r0]                               @ 0813675C
	ldr	r5, .Llit0813678C                      @ 0813675E  =0x00001BCC
	adds	r3, r1, r5                            @ 08136760
	ldr	r2, .Llit08136790                      @ 08136762  =gmpRateBufBytes
	lsls	r0, r7, #1                            @ 08136764
	adds	r0, r0, r2                            @ 08136766
	ldrh	r2, [r0]                              @ 08136768
	str	r2, [r3]                               @ 0813676A
	adds	r5, #4                                @ 0813676C
	adds	r0, r1, r5                            @ 0813676E
	str	r2, [r0]                               @ 08136770
	ldr	r0, .Llit08136794                      @ 08136772  =0x00001BF4
	adds	r1, r1, r0                            @ 08136774
	ldr	r2, [r4, #0x18]                        @ 08136776
	str	r2, [r1]                               @ 08136778
	cmp	r2, #0                                 @ 0813677A
	bne	.L08136798                             @ 0813677C
	ldr	r0, [r3]                               @ 0813677E
	lsls	r0, r0, #1                            @ 08136780
	adds	r6, r0, #0                            @ 08136782
	adds	r6, #0xa0                             @ 08136784
	b	.L081367A6                               @ 08136786
.Llit08136788:
	.word	0x00001BE4                           @ 08136788
.Llit0813678C:
	.word	0x00001BCC                           @ 0813678C
.Llit08136790:
	.word	gmpRateBufBytes                      @ 08136790
.Llit08136794:
	.word	0x00001BF4                           @ 08136794
.L08136798:
	cmp	r2, #1                                 @ 08136798
	bne	.L081367A6                             @ 0813679A
	ldr	r0, [r3]                               @ 0813679C
	lsls	r0, r0, #1                            @ 0813679E
	movs	r1, #0xfb                             @ 081367A0
	lsls	r1, r1, #2                            @ 081367A2
	adds	r6, r0, r1                            @ 081367A4
.L081367A6:
	ldr	r0, [r4, #4]                           @ 081367A6
	cmp	r6, r0                                 @ 081367A8
	bls	.L081367B2                             @ 081367AA
	movs	r0, #1                                @ 081367AC
	rsbs	r0, r0, #0                            @ 081367AE
	b	.L0813684A                               @ 081367B0  return -1 (IWRAM block too small)
.L081367B2:
	ldr	r0, [r4, #0x10]                        @ 081367B2
	cmp	r0, #0                                 @ 081367B4
	bne	.L081367BE                             @ 081367B6
	movs	r0, #3                                @ 081367B8
	rsbs	r0, r0, #0                            @ 081367BA
	b	.L0813684A                               @ 081367BC  return -3 (no sample bank)
.L081367BE:
	ldr	r0, [r4, #0x14]                        @ 081367BE
	cmp	r0, #0                                 @ 081367C0
	beq	.L081367C8                             @ 081367C2
	bl	gmpLoadSfxBank                          @ 081367C4
.L081367C8:
	ldr	r0, [r4, #0x10]                        @ 081367C8
	bl	gmpLoadSampleBank                       @ 081367CA
	adds	r0, r4, #0                            @ 081367CE
	mov	r1, r8                                 @ 081367D0
	bl	gmpSetupIwram                           @ 081367D2
	ldr	r4, .Llit08136858                      @ 081367D6  =gmpState
	ldr	r1, [r4]                               @ 081367D8
	ldr	r0, [r1, #0x34]                        @ 081367DA  ST_dmaOn
	cmp	r0, #0                                 @ 081367DC
	bne	.L081367F6                             @ 081367DE
	ldr	r0, [r1, #8]                           @ 081367E0  ST_cur
	lsls	r0, r0, #2                            @ 081367E2
	adds	r0, r1, r0                            @ 081367E4
	ldr	r0, [r0]                               @ 081367E6
	adds	r1, r7, #0                            @ 081367E8
	mov	r2, sl                                 @ 081367EA
	bl	gmpStartDma                             @ 081367EC
	ldr	r1, [r4]                               @ 081367F0
	movs	r0, #1                                @ 081367F2
	str	r0, [r1, #0x34]                        @ 081367F4  ST_dmaOn
.L081367F6:
	ldr	r1, [r4]                               @ 081367F6
	ldr	r2, .Llit0813685C                      @ 081367F8  =0x00001BC4
	adds	r0, r1, r2                            @ 081367FA
	mov	r5, sb                                 @ 081367FC
	str	r5, [r0]                               @ 081367FE
	ldr	r2, .Llit08136860                      @ 08136800  =gmpPlayer
	adds	r0, r1, #0                            @ 08136802
	adds	r0, #0x5c                             @ 08136804
	str	r0, [r2]                               @ 08136806
	ldr	r0, .Llit08136864                      @ 08136808  =0x00000BF8
	adds	r1, r1, r0                            @ 0813680A
	str	r5, [r1]                               @ 0813680C
	movs	r5, #0                                @ 0813680E
	adds	r6, r2, #0                            @ 08136810
	movs	r4, #0                                @ 08136812
.L08136814:
	ldr	r0, [r6]                               @ 08136814
	adds	r0, r4, r0                            @ 08136816
	adds	r0, #0x54                             @ 08136818
	movs	r1, #0                                @ 0813681A
	movs	r2, #0x98                             @ 0813681C
	bl	memset                                  @ 0813681E
	adds	r4, #0x98                             @ 08136822
	adds	r5, #1                                @ 08136824
	cmp	r5, #0xb                               @ 08136826
	bls	.L08136814                             @ 08136828
	ldr	r2, .Llit08136860                      @ 0813682A  =gmpPlayer
	ldr	r0, .Llit08136858                      @ 0813682C  =gmpState
	ldr	r0, [r0]                               @ 0813682E
	adds	r1, r0, #0                            @ 08136830
	adds	r1, #0x5c                             @ 08136832
	str	r1, [r2]                               @ 08136834
	movs	r2, #0                                @ 08136836
	str	r2, [r0, #8]                           @ 08136838  ST_cur
	movs	r1, #1                                @ 0813683A
	str	r1, [r0, #0xc]                         @ 0813683C  ST_prev
	str	r2, [r0, #0x10]                        @ 0813683E  ST_sameBuf
	str	r2, [r0, #0x1c]                        @ 08136840  ST_toneFrame
	str	r2, [r0, #0x14]                        @ 08136842  ST_toneOn
	ldr	r1, .Llit08136868                      @ 08136844  =0x00001BB8
	adds	r0, r0, r1                            @ 08136846
	ldr	r0, [r0]                               @ 08136848  ST_sfxCount
.L0813684A:
	pop	{r3, r4, r5}                           @ 0813684A
	mov	r8, r3                                 @ 0813684C
	mov	sb, r4                                 @ 0813684E
	mov	sl, r5                                 @ 08136850
	pop	{r4, r5, r6, r7}                       @ 08136852
	pop	{r1}                                   @ 08136854
	bx	r1                                      @ 08136856
.Llit08136858:
	.word	gmpState                             @ 08136858
.Llit0813685C:
	.word	0x00001BC4                           @ 0813685C
.Llit08136860:
	.word	gmpPlayer                            @ 08136860
.Llit08136864:
	.word	0x00000BF8                           @ 08136864
.Llit08136868:
	.word	0x00001BB8                           @ 08136868
@ --------------------------------------------------------------------------
@ gmpGetRow()  (0x0813686C)  -- unused
@   return gmpPlayer->PL_row
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpGetRow
gmpGetRow:
	ldr	r0, .Llit08136874                      @ 0813686C  =gmpPlayer
	ldr	r0, [r0]                               @ 0813686E
	ldr	r0, [r0, #0x40]                        @ 08136870  PL_row
	bx	lr                                      @ 08136872
.Llit08136874:
	.word	gmpPlayer                            @ 08136874
@ --------------------------------------------------------------------------
@ gmpGetOrder()  (0x08136878)  -- unused
@   return gmpPlayer->PL_order
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpGetOrder
gmpGetOrder:
	ldr	r0, .Llit08136880                      @ 08136878  =gmpPlayer
	ldr	r0, [r0]                               @ 0813687A
	ldr	r0, [r0, #0x44]                        @ 0813687C  PL_order
	bx	lr                                      @ 0813687E
.Llit08136880:
	.word	gmpPlayer                            @ 08136880
@ --------------------------------------------------------------------------
@ gmpGetLoopCount()  (0x08136884)  -- unused
@   return gmpPlayer->PL_loops
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpGetLoopCount
gmpGetLoopCount:
	ldr	r0, .Llit0813688C                      @ 08136884  =gmpPlayer
	ldr	r0, [r0]                               @ 08136886
	ldr	r0, [r0, #0x48]                        @ 08136888  PL_loops
	bx	lr                                      @ 0813688A
.Llit0813688C:
	.word	gmpPlayer                            @ 0813688C
@ --------------------------------------------------------------------------
@ gmpStartSong(order)  (0x08136890)
@   if (!ST_rateHz || order >= module->songLen) return;
@   ST_fade = 64; PL_tickHz = BPM*2/5; PL_rowLen = rate*speed/tickHz; PL_tickLen = rate/tickHz
@   ST_periods = gmpAmigaPeriods; PL_order = order; PL_row = PL_rowLeft = PL_tickLeft = 0; PL_loops = 0
@   clear the effect state of all 12 channels; PL_jumped = 0; PL_tick = 0; clear both buffers
@   ST_jinglePri = 0; PL_skip = 0; ST_jingleSync = 0; PL_tempoLock = 0; ST_playing = 1
@   PL_nChan = PL_nMusic + PL_nSfx
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpStartSong
gmpStartSong:
	push	{r4, r5, r6, r7, lr}                  @ 08136890
	adds	r6, r0, #0                            @ 08136892
	ldr	r4, .Llit0813697C                      @ 08136894  =gmpState
	ldr	r1, [r4]                               @ 08136896
	ldr	r0, [r1, #0x48]                        @ 08136898  ST_rateHz
	cmp	r0, #0                                 @ 0813689A
	beq	.L08136974                             @ 0813689C
	ldr	r5, .Llit08136980                      @ 0813689E  =gmpPlayer
	ldr	r2, [r5]                               @ 081368A0
	ldr	r0, [r2]                               @ 081368A2  PL_module
	ldr	r0, [r0, #0x34]                        @ 081368A4
	cmp	r6, r0                                 @ 081368A6
	bge	.L08136974                             @ 081368A8
	movs	r0, #0x40                             @ 081368AA
	str	r0, [r1, #0x50]                        @ 081368AC  ST_fade
	movs	r1, #0x32                             @ 081368AE
	str	r1, [r2, #0x1c]                        @ 081368B0  PL_tickHz
	ldr	r0, [r2, #0x3c]                        @ 081368B2  PL_bpm
	muls	r0, r1, r0                            @ 081368B4
	lsls	r0, r0, #0x10                         @ 081368B6
	movs	r1, #0x7d                             @ 081368B8
	bl	swiDiv                                  @ 081368BA
	adds	r1, r0, #0                            @ 081368BE
	ldr	r2, [r5]                               @ 081368C0
	asrs	r1, r1, #0x10                         @ 081368C2
	str	r1, [r2, #0x1c]                        @ 081368C4  PL_tickHz
	ldr	r0, [r4]                               @ 081368C6
	ldr	r2, [r2, #0x14]                        @ 081368C8  PL_speed
	ldr	r0, [r0, #0x48]                        @ 081368CA  ST_rateHz
	muls	r0, r2, r0                            @ 081368CC
	bl	swiDiv                                  @ 081368CE
	ldr	r1, [r5]                               @ 081368D2
	str	r0, [r1, #0x24]                        @ 081368D4  PL_rowLen
	ldr	r2, [r4]                               @ 081368D6
	ldr	r0, .Llit08136984                      @ 081368D8  =gmpAmigaPeriods
	str	r0, [r2, #0x2c]                        @ 081368DA  ST_periods
	str	r6, [r1, #0x44]                        @ 081368DC  PL_order
	movs	r4, #0                                @ 081368DE
	str	r4, [r1, #0x40]                        @ 081368E0  PL_row
	str	r4, [r1, #0x20]                        @ 081368E2  PL_rowLeft
	ldr	r0, [r2, #0x48]                        @ 081368E4  ST_rateHz
	ldr	r1, [r1, #0x1c]                        @ 081368E6  PL_tickHz
	bl	swiDiv                                  @ 081368E8
	ldr	r1, [r5]                               @ 081368EC
	str	r0, [r1, #0x30]                        @ 081368EE  PL_tickLen
	str	r4, [r1, #0x2c]                        @ 081368F0  PL_tickLeft
	adds	r1, r5, #0                            @ 081368F2
	movs	r6, #0                                @ 081368F4
	adds	r7, r1, #0                            @ 081368F6
	movs	r5, #0xb                              @ 081368F8
.L081368FA:
	ldr	r3, [r1]                               @ 081368FA
	adds	r0, r3, #0                            @ 081368FC
	adds	r0, #0x6c                             @ 081368FE
	adds	r0, r0, r4                            @ 08136900
	str	r6, [r0]                               @ 08136902
	adds	r0, r3, #0                            @ 08136904
	adds	r0, #0x60                             @ 08136906
	adds	r0, r0, r4                            @ 08136908
	str	r6, [r0]                               @ 0813690A
	adds	r0, r3, #0                            @ 0813690C
	adds	r0, #0x68                             @ 0813690E
	adds	r0, r0, r4                            @ 08136910
	str	r6, [r0]                               @ 08136912
	adds	r4, #0x98                             @ 08136914
	subs	r5, #1                                @ 08136916
	cmp	r5, #0                                 @ 08136918
	bge	.L081368FA                             @ 0813691A
	ldr	r0, [r7]                               @ 0813691C
	adds	r0, #0x4c                             @ 0813691E
	movs	r4, #0                                @ 08136920
	strb	r4, [r0]                              @ 08136922
	ldr	r0, [r7]                               @ 08136924
	strh	r4, [r0, #0x38]                       @ 08136926
	ldr	r5, .Llit0813697C                      @ 08136928  =gmpState
	ldr	r1, [r5]                               @ 0813692A
	ldr	r6, .Llit08136988                      @ 0813692C  =0x00001BD0
	ldr	r0, [r1]                               @ 0813692E  ST_buf0
	adds	r1, r1, r6                            @ 08136930
	ldr	r2, [r1]                               @ 08136932  ST_bufBytes
	movs	r1, #0                                @ 08136934
	bl	memset                                  @ 08136936
	ldr	r1, [r5]                               @ 0813693A
	ldr	r0, [r1, #4]                           @ 0813693C  ST_buf1
	adds	r1, r1, r6                            @ 0813693E
	ldr	r2, [r1]                               @ 08136940  ST_bufBytes
	movs	r1, #0                                @ 08136942
	bl	memset                                  @ 08136944
	ldr	r2, [r5]                               @ 08136948
	adds	r0, r2, #0                            @ 0813694A
	adds	r0, #0x4c                             @ 0813694C
	strh	r4, [r0]                              @ 0813694E  ST_jinglePri
	ldr	r1, [r7]                               @ 08136950
	str	r4, [r1, #0xc]                         @ 08136952
	str	r4, [r2, #0x40]                        @ 08136954  ST_jingleSync
	strh	r4, [r1, #0x18]                       @ 08136956
	ldr	r0, .Llit0813698C                      @ 08136958  =0x00001BBC
	adds	r2, r2, r0                            @ 0813695A
	movs	r0, #1                                @ 0813695C
	strh	r0, [r2]                              @ 0813695E  ST_playing
	ldr	r3, .Llit08136990                      @ 08136960  =0x00000B9C
	adds	r2, r1, r3                            @ 08136962
	subs	r3, #8                                @ 08136964
	adds	r0, r1, r3                            @ 08136966
	adds	r3, #4                                @ 08136968
	adds	r1, r1, r3                            @ 0813696A
	ldr	r0, [r0]                               @ 0813696C
	ldr	r1, [r1]                               @ 0813696E
	adds	r0, r0, r1                            @ 08136970
	str	r0, [r2]                               @ 08136972
.L08136974:
	pop	{r4, r5, r6, r7}                       @ 08136974
	pop	{r0}                                   @ 08136976
	bx	r0                                      @ 08136978
	.hword	0x0000                              @ 0813697A  (padding)
.Llit0813697C:
	.word	gmpState                             @ 0813697C
.Llit08136980:
	.word	gmpPlayer                            @ 08136980
.Llit08136984:
	.word	gmpAmigaPeriods                      @ 08136984
.Llit08136988:
	.word	0x00001BD0                           @ 08136988
.Llit0813698C:
	.word	0x00001BBC                           @ 0813698C
.Llit08136990:
	.word	0x00000B9C                           @ 08136990
@ --------------------------------------------------------------------------
@ gmpPlayJingle(module, order, priority)  (0x08136994)  -- unused by NFSU2
@   if (order < 0 || order >= module->songLen) return;
@   if (priority && priority <= ST_jinglePri) return;
@   if (!ST_jingleOn || !priority) { ST_jingleReq = module; ST_jingleDone = 0; ST_jingleSync = 0 }
@   ST_jingleOn = 1
@   (The order argument is only range-checked: the jingle always starts at order 0.)
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpPlayJingle
gmpPlayJingle:
	push	{r4, lr}                              @ 08136994
	adds	r4, r0, #0                            @ 08136996
	cmp	r1, #0                                 @ 08136998
	blt	.L081369DE                             @ 0813699A
	ldr	r0, [r4, #0x34]                        @ 0813699C
	cmp	r1, r0                                 @ 0813699E
	bge	.L081369DE                             @ 081369A0
	ldr	r3, .Llit081369E4                      @ 081369A2  =gmpState
	cmp	r2, #0                                 @ 081369A4
	beq	.L081369B4                             @ 081369A6
	ldr	r0, [r3]                               @ 081369A8
	adds	r0, #0x4c                             @ 081369AA
	movs	r1, #0                                @ 081369AC
	ldrsh	r0, [r0, r1]                         @ 081369AE  ST_jinglePri
	cmp	r2, r0                                 @ 081369B0
	ble	.L081369DE                             @ 081369B2
.L081369B4:
	ldr	r1, [r3]                               @ 081369B4
	adds	r0, r1, #0                            @ 081369B6
	adds	r0, #0x54                             @ 081369B8
	ldrb	r0, [r0]                              @ 081369BA
	cmp	r0, #0                                 @ 081369BC
	beq	.L081369C4                             @ 081369BE
	cmp	r2, #0                                 @ 081369C0
	bne	.L081369D6                             @ 081369C2
.L081369C4:
	ldr	r2, .Llit081369E8                      @ 081369C4  =0x00001BFC
	adds	r0, r1, r2                            @ 081369C6
	str	r4, [r0]                               @ 081369C8
	adds	r2, #4                                @ 081369CA
	adds	r0, r1, r2                            @ 081369CC
	movs	r1, #0                                @ 081369CE
	strb	r1, [r0]                              @ 081369D0
	ldr	r0, [r3]                               @ 081369D2
	str	r1, [r0, #0x40]                        @ 081369D4
.L081369D6:
	ldr	r0, [r3]                               @ 081369D6
	adds	r0, #0x54                             @ 081369D8
	movs	r1, #1                                @ 081369DA
	strb	r1, [r0]                              @ 081369DC
.L081369DE:
	pop	{r4}                                   @ 081369DE
	pop	{r0}                                   @ 081369E0
	bx	r0                                      @ 081369E2
.Llit081369E4:
	.word	gmpState                             @ 081369E4
.Llit081369E8:
	.word	0x00001BFC                           @ 081369E8
@ --------------------------------------------------------------------------
@ gmpPlayJingleOnBeat(module, order, priority)  (0x081369EC)  -- unused
@   Same as gmpPlayJingle but sets ST_jingleSync = 1: the switch waits for a row that is a
@   multiple of 4.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpPlayJingleOnBeat
gmpPlayJingleOnBeat:
	push	{r4, lr}                              @ 081369EC
	adds	r4, r0, #0                            @ 081369EE
	cmp	r1, #0                                 @ 081369F0
	blt	.L08136A3A                             @ 081369F2
	ldr	r0, [r4, #0x34]                        @ 081369F4
	cmp	r1, r0                                 @ 081369F6
	bge	.L08136A3A                             @ 081369F8
	ldr	r3, .Llit08136A40                      @ 081369FA  =gmpState
	cmp	r2, #0                                 @ 081369FC
	beq	.L08136A0C                             @ 081369FE
	ldr	r0, [r3]                               @ 08136A00
	adds	r0, #0x4c                             @ 08136A02
	movs	r1, #0                                @ 08136A04
	ldrsh	r0, [r0, r1]                         @ 08136A06  ST_jinglePri
	cmp	r2, r0                                 @ 08136A08
	ble	.L08136A3A                             @ 08136A0A
.L08136A0C:
	ldr	r1, [r3]                               @ 08136A0C
	adds	r0, r1, #0                            @ 08136A0E
	adds	r0, #0x54                             @ 08136A10
	ldrb	r0, [r0]                              @ 08136A12
	cmp	r0, #0                                 @ 08136A14
	beq	.L08136A1C                             @ 08136A16
	cmp	r2, #0                                 @ 08136A18
	bne	.L08136A32                             @ 08136A1A
.L08136A1C:
	ldr	r2, .Llit08136A44                      @ 08136A1C  =0x00001BFC
	adds	r0, r1, r2                            @ 08136A1E
	str	r4, [r0]                               @ 08136A20
	movs	r0, #0xe0                             @ 08136A22
	lsls	r0, r0, #5                            @ 08136A24
	adds	r1, r1, r0                            @ 08136A26
	movs	r0, #0                                @ 08136A28
	strb	r0, [r1]                              @ 08136A2A
	ldr	r1, [r3]                               @ 08136A2C
	movs	r0, #1                                @ 08136A2E
	str	r0, [r1, #0x40]                        @ 08136A30
.L08136A32:
	ldr	r0, [r3]                               @ 08136A32
	adds	r0, #0x54                             @ 08136A34
	movs	r1, #1                                @ 08136A36
	strb	r1, [r0]                              @ 08136A38
.L08136A3A:
	pop	{r4}                                   @ 08136A3A
	pop	{r0}                                   @ 08136A3C
	bx	r0                                      @ 08136A3E
.Llit08136A40:
	.word	gmpState                             @ 08136A40
.Llit08136A44:
	.word	0x00001BFC                           @ 08136A44
@ --------------------------------------------------------------------------
@ gmpEndJingle()  (0x08136A48)
@   if (ST_jingleOn) { ST_jingleDone = 1; ST_fade = 0; ST_jingleOn = 0 }
@   Called by Bxx while a jingle plays.  The music comes back with a fade-in (gmpApplyRate).
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpEndJingle
gmpEndJingle:
	ldr	r3, .Llit08136A6C                      @ 08136A48  =gmpState
	ldr	r1, [r3]                               @ 08136A4A
	adds	r0, r1, #0                            @ 08136A4C
	adds	r0, #0x54                             @ 08136A4E
	ldrb	r0, [r0]                              @ 08136A50  ST_jingleOn
	cmp	r0, #0                                 @ 08136A52
	beq	.L08136A6A                             @ 08136A54
	movs	r0, #0xe0                             @ 08136A56
	lsls	r0, r0, #5                            @ 08136A58
	adds	r1, r1, r0                            @ 08136A5A
	movs	r2, #0                                @ 08136A5C
	movs	r0, #1                                @ 08136A5E
	strb	r0, [r1]                              @ 08136A60  ST_jingleDone
	ldr	r0, [r3]                               @ 08136A62
	str	r2, [r0, #0x50]                        @ 08136A64  ST_fade
	adds	r0, #0x54                             @ 08136A66
	strb	r2, [r0]                              @ 08136A68  ST_jingleOn
.L08136A6A:
	bx	lr                                      @ 08136A6A
.Llit08136A6C:
	.word	gmpState                             @ 08136A6C
@ --------------------------------------------------------------------------
@ gmpEndJingle2()  (0x08136A70)  -- unused
@   Byte-for-byte duplicate of gmpEndJingle.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpEndJingle2
gmpEndJingle2:
	ldr	r3, .Llit08136A94                      @ 08136A70  =gmpState
	ldr	r1, [r3]                               @ 08136A72
	adds	r0, r1, #0                            @ 08136A74
	adds	r0, #0x54                             @ 08136A76
	ldrb	r0, [r0]                              @ 08136A78  ST_jingleOn
	cmp	r0, #0                                 @ 08136A7A
	beq	.L08136A92                             @ 08136A7C
	movs	r0, #0xe0                             @ 08136A7E
	lsls	r0, r0, #5                            @ 08136A80
	adds	r1, r1, r0                            @ 08136A82
	movs	r2, #0                                @ 08136A84
	movs	r0, #1                                @ 08136A86
	strb	r0, [r1]                              @ 08136A88  ST_jingleDone
	ldr	r0, [r3]                               @ 08136A8A
	str	r2, [r0, #0x50]                        @ 08136A8C  ST_fade
	adds	r0, #0x54                             @ 08136A8E
	strb	r2, [r0]                              @ 08136A90  ST_jingleOn
.L08136A92:
	bx	lr                                      @ 08136A92
.Llit08136A94:
	.word	gmpState                             @ 08136A94
@ --------------------------------------------------------------------------
@ gmpSkipPattern()  (0x08136A98)  -- unused
@   gmpPlayer->PL_skip = 1  (the next Bxx goes to the next order instead)
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpSkipPattern
gmpSkipPattern:
	ldr	r0, .Llit08136AA4                      @ 08136A98  =gmpPlayer
	ldr	r1, [r0]                               @ 08136A9A
	movs	r0, #1                                @ 08136A9C
	str	r0, [r1, #0xc]                         @ 08136A9E  PL_skip
	bx	lr                                      @ 08136AA0
	.hword	0x0000                              @ 08136AA2  (padding)
.Llit08136AA4:
	.word	gmpPlayer                            @ 08136AA4
@ --------------------------------------------------------------------------
@ gmpPause()  (0x08136AA8)  -- unused
@   ST_paused = 1; gmpClearBuffers()
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpPause
gmpPause:
	push	{lr}                                  @ 08136AA8
	ldr	r0, .Llit08136ABC                      @ 08136AAA  =gmpState
	ldr	r1, [r0]                               @ 08136AAC
	movs	r0, #1                                @ 08136AAE
	str	r0, [r1, #0x44]                        @ 08136AB0  ST_paused
	bl	gmpClearBuffers                         @ 08136AB2
	pop	{r0}                                   @ 08136AB6
	bx	r0                                      @ 08136AB8
	.hword	0x0000                              @ 08136ABA  (padding)
.Llit08136ABC:
	.word	gmpState                             @ 08136ABC
@ --------------------------------------------------------------------------
@ gmpSetFlag10()  (0x08136AC0)  -- unused
@   gmpPlayer->PL_unused10 = 1 (never read)
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpSetFlag10
gmpSetFlag10:
	ldr	r0, .Llit08136ACC                      @ 08136AC0  =gmpPlayer
	ldr	r1, [r0]                               @ 08136AC2
	movs	r0, #1                                @ 08136AC4
	str	r0, [r1, #0x10]                        @ 08136AC6  PL_unused10
	bx	lr                                      @ 08136AC8
	.hword	0x0000                              @ 08136ACA  (padding)
.Llit08136ACC:
	.word	gmpPlayer                            @ 08136ACC
@ --------------------------------------------------------------------------
@ gmpResume()  (0x08136AD0)  -- unused
@   ST_paused = 0; gmpSoundOn()
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpResume
gmpResume:
	push	{lr}                                  @ 08136AD0
	ldr	r0, .Llit08136AE4                      @ 08136AD2  =gmpState
	ldr	r1, [r0]                               @ 08136AD4
	movs	r0, #0                                @ 08136AD6
	str	r0, [r1, #0x44]                        @ 08136AD8  ST_paused
	bl	gmpSoundOn                              @ 08136ADA
	pop	{r0}                                   @ 08136ADE
	bx	r0                                      @ 08136AE0
	.hword	0x0000                              @ 08136AE2  (padding)
.Llit08136AE4:
	.word	gmpState                             @ 08136AE4
@ --------------------------------------------------------------------------
@ gmpSilenceMusic()  (0x08136AE8)
@   ST_playing = 0; CH_end = 0 on every music channel
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpSilenceMusic
gmpSilenceMusic:
	push	{r4, r5, r6, lr}                      @ 08136AE8
	ldr	r0, .Llit08136B28                      @ 08136AEA  =gmpState
	ldr	r0, [r0]                               @ 08136AEC
	ldr	r1, .Llit08136B2C                      @ 08136AEE  =0x00001BBC
	adds	r0, r0, r1                            @ 08136AF0
	movs	r1, #0                                @ 08136AF2
	strh	r1, [r0]                              @ 08136AF4  ST_playing
	movs	r3, #0                                @ 08136AF6
	ldr	r1, .Llit08136B30                      @ 08136AF8  =gmpPlayer
	ldr	r0, [r1]                               @ 08136AFA
	ldr	r4, .Llit08136B34                      @ 08136AFC  =0x00000B94
	adds	r0, r0, r4                            @ 08136AFE
	ldr	r0, [r0]                               @ 08136B00  PL_nMusic
	cmp	r3, r0                                 @ 08136B02
	bhs	.L08136B22                             @ 08136B04
	adds	r6, r1, #0                            @ 08136B06
	movs	r5, #0                                @ 08136B08
	movs	r2, #0                                @ 08136B0A
.L08136B0C:
	ldr	r0, [r6]                               @ 08136B0C
	adds	r1, r0, #0                            @ 08136B0E
	adds	r1, #0x6c                             @ 08136B10
	adds	r1, r1, r2                            @ 08136B12
	str	r5, [r1]                               @ 08136B14
	adds	r2, #0x98                             @ 08136B16
	adds	r3, #1                                @ 08136B18
	adds	r0, r0, r4                            @ 08136B1A
	ldr	r0, [r0]                               @ 08136B1C
	cmp	r3, r0                                 @ 08136B1E
	blo	.L08136B0C                             @ 08136B20
.L08136B22:
	pop	{r4, r5, r6}                           @ 08136B22
	pop	{r0}                                   @ 08136B24
	bx	r0                                      @ 08136B26
.Llit08136B28:
	.word	gmpState                             @ 08136B28
.Llit08136B2C:
	.word	0x00001BBC                           @ 08136B2C
.Llit08136B30:
	.word	gmpPlayer                            @ 08136B30
.Llit08136B34:
	.word	0x00000B94                           @ 08136B34
@ --------------------------------------------------------------------------
@ gmpGetChannelVolume(i)  (0x08136B38)  -- unused
@   return i < PL_nChan ? chan[i].CH_vol : garbage (r0 = i)
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpGetChannelVolume
gmpGetChannelVolume:
	push	{r4, lr}                              @ 08136B38
	adds	r3, r0, #0                            @ 08136B3A
	ldr	r1, .Llit08136B60                      @ 08136B3C  =gmpPlayer
	ldr	r2, [r1]                               @ 08136B3E
	ldr	r4, .Llit08136B64                      @ 08136B40  =0x00000B9C
	adds	r1, r2, r4                            @ 08136B42
	ldr	r1, [r1]                               @ 08136B44  PL_nChan
	cmp	r3, r1                                 @ 08136B46
	bge	.L08136B58                             @ 08136B48
	movs	r0, #0x98                             @ 08136B4A
	adds	r1, r3, #0                            @ 08136B4C
	muls	r1, r0, r1                            @ 08136B4E
	adds	r0, r2, #0                            @ 08136B50
	adds	r0, #0x6c                             @ 08136B52
	adds	r0, r0, r1                            @ 08136B54
	ldr	r0, [r0]                               @ 08136B56
.L08136B58:
	pop	{r4}                                   @ 08136B58
	pop	{r1}                                   @ 08136B5A
	bx	r1                                      @ 08136B5C
	.hword	0x0000                              @ 08136B5E  (padding)
.Llit08136B60:
	.word	gmpPlayer                            @ 08136B60
.Llit08136B64:
	.word	0x00000B9C                           @ 08136B64
@ --------------------------------------------------------------------------
@ gmpDecodeRow(rs, blockPrev, row)  (0x08136B68)
@   Decodes one channel's row from its three RLE streams into rs->cell (+0x50, 6 bytes).
@   Pattern block per channel: {u32 len1, off2, off3, end3, blockLen; streams...}
@   row == 0: open the streams.  The first channel's block comes from
@             PL_patBase + module->patOffs[module->orders[PL_order]]; later channels use the
@             block that follows the previous one (the return value).
@   row != 0: just take the next value of each stream (no seeking).
@     w = rle16(notes);  cell[0] = w >> 7 (note low 8 bits); cell[1] = w >> 15; cell[2] = w & 0x7F (instrument)
@     cell[3] = rle8(volume column);  e = rle16(effects); cell[4] = e >> 8; cell[5] = e & 0xFF
@   Because the streams cannot seek, every jump to a row other than 0 (Dxx with x != 0,
@   E6x back to a row other than 0) keeps reading the old stream.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpDecodeRow
gmpDecodeRow:
	push	{r4, r5, r6, r7, lr}                  @ 08136B68
	adds	r5, r1, #0                            @ 08136B6A
	cmp	r2, #0                                 @ 08136B6C
	bne	.L08136BE8                             @ 08136B6E
	adds	r6, r0, #0                            @ 08136B70
	adds	r6, #0x50                             @ 08136B72
	adds	r7, r0, #0                            @ 08136B74
	cmp	r5, #0                                 @ 08136B76
	bne	.L08136B9C                             @ 08136B78
	ldr	r0, .Llit08136BE4                      @ 08136B7A  =gmpPlayer
	ldr	r2, [r0]                               @ 08136B7C
	ldr	r3, [r2]                               @ 08136B7E  PL_module
	movs	r1, #0xa6                             @ 08136B80
	lsls	r1, r1, #1                            @ 08136B82
	adds	r0, r3, r1                            @ 08136B84
	ldr	r1, [r2, #0x44]                        @ 08136B86  PL_order
	adds	r0, r0, r1                            @ 08136B88
	ldrb	r0, [r0]                              @ 08136B8A
	lsls	r0, r0, #2                            @ 08136B8C
	movs	r4, #0x93                             @ 08136B8E
	lsls	r4, r4, #2                            @ 08136B90
	adds	r1, r3, r4                            @ 08136B92
	adds	r1, r1, r0                            @ 08136B94
	ldr	r2, [r2, #0x50]                        @ 08136B96  PL_patBase
	ldr	r0, [r1]                               @ 08136B98
	adds	r5, r2, r0                            @ 08136B9A
.L08136B9C:
	adds	r4, r5, #0                            @ 08136B9C
	adds	r4, #0x14                             @ 08136B9E
	adds	r0, r7, #0                            @ 08136BA0
	adds	r1, r4, #0                            @ 08136BA2
	bl	gmpRle16Next                            @ 08136BA4
	adds	r1, r0, #0                            @ 08136BA8
	lsrs	r0, r1, #7                            @ 08136BAA  cell[0] = note low bits (w >> 7)
	strb	r0, [r6]                              @ 08136BAC
	lsrs	r0, r0, #8                            @ 08136BAE
	strb	r0, [r6, #1]                          @ 08136BB0  cell[1] = note bit 8
	movs	r0, #0x7f                             @ 08136BB2
	ands	r1, r0                                @ 08136BB4
	strb	r1, [r6, #2]                          @ 08136BB6  cell[2] = instrument
	ldr	r0, [r5, #4]                           @ 08136BB8
	adds	r1, r4, r0                            @ 08136BBA
	adds	r0, r7, #0                            @ 08136BBC
	adds	r0, #0x20                             @ 08136BBE
	bl	gmpRle8Next                             @ 08136BC0
	strb	r0, [r6, #3]                          @ 08136BC4  cell[3] = volume column
	ldr	r0, [r5, #8]                           @ 08136BC6
	adds	r1, r4, r0                            @ 08136BC8
	adds	r0, r7, #0                            @ 08136BCA
	adds	r0, #0x30                             @ 08136BCC
	bl	gmpRle16Next                            @ 08136BCE
	adds	r1, r0, #0                            @ 08136BD2
	lsrs	r0, r1, #8                            @ 08136BD4
	strb	r0, [r6, #4]                          @ 08136BD6  cell[4] = effect command
	strb	r1, [r6, #5]                          @ 08136BD8  cell[5] = parameter
	ldr	r0, [r5, #0x10]                        @ 08136BDA
	adds	r5, r4, r0                            @ 08136BDC
	adds	r0, r5, #0                            @ 08136BDE
	b	.L08136C24                               @ 08136BE0
	.hword	0x0000                              @ 08136BE2  (padding)
.Llit08136BE4:
	.word	gmpPlayer                            @ 08136BE4
.L08136BE8:
	adds	r6, r0, #0                            @ 08136BE8
	adds	r6, #0x50                             @ 08136BEA
	adds	r7, r0, #0                            @ 08136BEC
	movs	r1, #0                                @ 08136BEE
	bl	gmpRle16Next                            @ 08136BF0
	adds	r1, r0, #0                            @ 08136BF4
	lsrs	r0, r1, #7                            @ 08136BF6
	strb	r0, [r6]                              @ 08136BF8
	lsrs	r0, r0, #8                            @ 08136BFA
	strb	r0, [r6, #1]                          @ 08136BFC
	movs	r0, #0x7f                             @ 08136BFE
	ands	r1, r0                                @ 08136C00
	strb	r1, [r6, #2]                          @ 08136C02
	adds	r0, r7, #0                            @ 08136C04
	adds	r0, #0x20                             @ 08136C06
	movs	r1, #0                                @ 08136C08
	bl	gmpRle8Next                             @ 08136C0A
	strb	r0, [r6, #3]                          @ 08136C0E
	adds	r0, r7, #0                            @ 08136C10
	adds	r0, #0x30                             @ 08136C12
	movs	r1, #0                                @ 08136C14
	bl	gmpRle16Next                            @ 08136C16
	adds	r1, r0, #0                            @ 08136C1A
	lsrs	r0, r1, #8                            @ 08136C1C
	strb	r0, [r6, #4]                          @ 08136C1E
	strb	r1, [r6, #5]                          @ 08136C20
	movs	r0, #0                                @ 08136C22
.L08136C24:
	pop	{r4, r5, r6, r7}                       @ 08136C24
	pop	{r1}                                   @ 08136C26
	bx	r1                                      @ 08136C28
	.hword	0x0000                              @ 08136C2A  (padding)
@ --------------------------------------------------------------------------
@ gmpProcessRow()  (0x08136C2C)
@   if (!ST_playing) return;
@   PL_tick = PL_arpTick = 0; PL_jumped = 0;
@   for each music channel: gmpDecodeRow(rowState[i], prev, PL_row)
@   PL_row++;                                  (before the effects, so Dxx/Bxx overwrite it)
@   for each music channel: gmpRowEffects(rowState[i].cell, &chan[i])
@   if (PL_row == PL_rows) { PL_order++; if (PL_order >= songLen) { PL_order = 0; PL_loops++;
@                            if (!ST_loop) ST_playing = 0 }  PL_row = 0 }
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpProcessRow
gmpProcessRow:
	push	{r4, r5, r6, r7, lr}                  @ 08136C2C
	ldr	r0, .Llit08136D10                      @ 08136C2E  =gmpState
	ldr	r0, [r0]                               @ 08136C30
	ldr	r1, .Llit08136D14                      @ 08136C32  =0x00001BBC
	adds	r0, r0, r1                            @ 08136C34
	movs	r3, #0                                @ 08136C36
	ldrsh	r0, [r0, r3]                         @ 08136C38  ST_playing
	cmp	r0, #0                                 @ 08136C3A
	beq	.L08136D0A                             @ 08136C3C
	ldr	r3, .Llit08136D18                      @ 08136C3E  =gmpPlayer
	ldr	r0, [r3]                               @ 08136C40
	adds	r7, r0, #0                            @ 08136C42
	adds	r7, #0x54                             @ 08136C44
	movs	r2, #0                                @ 08136C46
	movs	r1, #0                                @ 08136C48
	strh	r1, [r0, #0x38]                       @ 08136C4A  PL_tick
	strh	r1, [r0, #0x3a]                       @ 08136C4C  PL_arpTick
	adds	r0, #0x4c                             @ 08136C4E
	strb	r2, [r0]                              @ 08136C50  PL_jumped
	movs	r2, #0                                @ 08136C52
	ldr	r0, [r3]                               @ 08136C54
	ldr	r6, [r0, #0x40]                        @ 08136C56  PL_row
	movs	r4, #0                                @ 08136C58
	ldr	r1, .Llit08136D1C                      @ 08136C5A  =0x00000B94
	adds	r0, r0, r1                            @ 08136C5C
	ldr	r0, [r0]                               @ 08136C5E  PL_nMusic
	cmp	r4, r0                                 @ 08136C60
	bge	.L08136C8C                             @ 08136C62
	adds	r5, r3, #0                            @ 08136C64
.L08136C66:
	movs	r0, #0x58                             @ 08136C66
	adds	r1, r4, #0                            @ 08136C68
	muls	r1, r0, r1                            @ 08136C6A
	ldr	r3, .Llit08136D20                      @ 08136C6C  =0x00000774
	adds	r1, r1, r3                            @ 08136C6E
	ldr	r0, [r5]                               @ 08136C70
	adds	r0, r0, r1                            @ 08136C72
	adds	r1, r2, #0                            @ 08136C74
	adds	r2, r6, #0                            @ 08136C76
	bl	gmpDecodeRow                            @ 08136C78
	adds	r2, r0, #0                            @ 08136C7C
	adds	r4, #1                                @ 08136C7E
	ldr	r0, [r5]                               @ 08136C80
	ldr	r1, .Llit08136D1C                      @ 08136C82  =0x00000B94
	adds	r0, r0, r1                            @ 08136C84
	ldr	r0, [r0]                               @ 08136C86
	cmp	r4, r0                                 @ 08136C88
	blt	.L08136C66                             @ 08136C8A
.L08136C8C:
	ldr	r2, .Llit08136D18                      @ 08136C8C  =gmpPlayer
	ldr	r0, [r2]                               @ 08136C8E
	ldr	r1, [r0, #0x40]                        @ 08136C90  PL_row
	adds	r1, #1                                @ 08136C92  PL_row++ (before the effects)
	str	r1, [r0, #0x40]                        @ 08136C94  PL_row
	movs	r4, #0                                @ 08136C96
	ldr	r3, .Llit08136D1C                      @ 08136C98  =0x00000B94
	adds	r0, r0, r3                            @ 08136C9A
	ldr	r0, [r0]                               @ 08136C9C  PL_nMusic
	cmp	r4, r0                                 @ 08136C9E
	bge	.L08136CC8                             @ 08136CA0
	adds	r5, r2, #0                            @ 08136CA2
.L08136CA4:
	movs	r0, #0x58                             @ 08136CA4
	muls	r0, r4, r0                            @ 08136CA6
	ldr	r1, [r5]                               @ 08136CA8
	adds	r0, r0, r1                            @ 08136CAA
	ldr	r1, .Llit08136D24                      @ 08136CAC  =0x000007C4
	adds	r0, r0, r1                            @ 08136CAE
	movs	r1, #0x98                             @ 08136CB0
	muls	r1, r4, r1                            @ 08136CB2
	adds	r1, r7, r1                            @ 08136CB4
	bl	gmpRowEffects                           @ 08136CB6
	adds	r4, #1                                @ 08136CBA
	ldr	r0, [r5]                               @ 08136CBC
	ldr	r3, .Llit08136D1C                      @ 08136CBE  =0x00000B94
	adds	r0, r0, r3                            @ 08136CC0
	ldr	r0, [r0]                               @ 08136CC2
	cmp	r4, r0                                 @ 08136CC4
	blt	.L08136CA4                             @ 08136CC6
.L08136CC8:
	ldr	r0, .Llit08136D18                      @ 08136CC8  =gmpPlayer
	ldr	r3, [r0]                               @ 08136CCA
	ldr	r2, [r3, #0x40]                        @ 08136CCC  PL_row
	ldr	r1, [r3, #8]                           @ 08136CCE  PL_rows
	adds	r4, r0, #0                            @ 08136CD0
	cmp	r2, r1                                 @ 08136CD2
	bne	.L08136D0A                             @ 08136CD4
	ldr	r0, [r3, #0x44]                        @ 08136CD6  PL_order
	adds	r0, #1                                @ 08136CD8
	str	r0, [r3, #0x44]                        @ 08136CDA  PL_order++
	ldr	r1, [r3]                               @ 08136CDC  PL_module
	ldr	r1, [r1, #0x34]                        @ 08136CDE
	cmp	r0, r1                                 @ 08136CE0
	blo	.L08136D04                             @ 08136CE2
	movs	r0, #0                                @ 08136CE4
	str	r0, [r3, #0x44]                        @ 08136CE6  PL_order
	ldr	r0, [r3, #0x48]                        @ 08136CE8  PL_loops
	adds	r0, #1                                @ 08136CEA
	str	r0, [r3, #0x48]                        @ 08136CEC  PL_loops++
	ldr	r0, .Llit08136D10                      @ 08136CEE  =gmpState
	ldr	r2, [r0]                               @ 08136CF0
	movs	r1, #0xde                             @ 08136CF2
	lsls	r1, r1, #5                            @ 08136CF4
	adds	r0, r2, r1                            @ 08136CF6
	ldr	r1, [r0]                               @ 08136CF8  ST_loop
	cmp	r1, #0                                 @ 08136CFA
	bne	.L08136D04                             @ 08136CFC
	ldr	r3, .Llit08136D14                      @ 08136CFE  =0x00001BBC
	adds	r0, r2, r3                            @ 08136D00
	strh	r1, [r0]                              @ 08136D02  ST_playing = 0 (song ended, no loop)
.L08136D04:
	ldr	r1, [r4]                               @ 08136D04
	movs	r0, #0                                @ 08136D06
	str	r0, [r1, #0x40]                        @ 08136D08
.L08136D0A:
	pop	{r4, r5, r6, r7}                       @ 08136D0A
	pop	{r0}                                   @ 08136D0C
	bx	r0                                      @ 08136D0E
.Llit08136D10:
	.word	gmpState                             @ 08136D10
.Llit08136D14:
	.word	0x00001BBC                           @ 08136D14
.Llit08136D18:
	.word	gmpPlayer                            @ 08136D18
.Llit08136D1C:
	.word	0x00000B94                           @ 08136D1C
.Llit08136D20:
	.word	0x00000774                           @ 08136D20
.Llit08136D24:
	.word	0x000007C4                           @ 08136D24
@ --------------------------------------------------------------------------
@ gmpSetLoop(on)  (0x08136D28)
@   ST_loop = on
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpSetLoop
gmpSetLoop:
	ldr	r1, .Llit08136D38                      @ 08136D28  =gmpState
	ldr	r1, [r1]                               @ 08136D2A
	movs	r2, #0xde                             @ 08136D2C
	lsls	r2, r2, #5                            @ 08136D2E
	adds	r1, r1, r2                            @ 08136D30
	str	r0, [r1]                               @ 08136D32  ST_loop
	bx	lr                                      @ 08136D34
	.hword	0x0000                              @ 08136D36  (padding)
.Llit08136D38:
	.word	gmpState                             @ 08136D38
@ --------------------------------------------------------------------------
@ gmpMix(dst, first, count)  (0x08136D3C)
@   Fills ST_bufBytes signed 8-bit samples.  Works in slices that end at the next row or tick:
@   while (done < ST_bufBytes) {
@     if (ST_playing) { if (!PL_rowLeft) { gmpProcessRow(); PL_rowLeft = PL_rowLen }
@                       if (!PL_tickLeft) { gmpProcessTick(); PL_tickLeft = PL_tickLen }
@                       n = min(PL_rowLeft, PL_tickLeft, bytes left) } else n = bytes left
@     mode 0: for each channel with CH_ptr && CH_end > 2:
@               v = CH_vol * (i < nMusic ? musicVol : sfxVol) / 64 * masterVol / 64 * ST_fade / 64
@               mixer(ch, dst, n) with v (ARM, adds into dst)
@     mode 1: build a 5-word record per channel on the stack {ptr+pos>>12, vol, pos<<20,
@             step<<20, step>>12}, shorten n so no channel passes its end, add a 0xFF end
@             record, call the mixer once, then advance positions and wrap loops here.
@     dst += n; done += n; PL_rowLeft -= n; PL_tickLeft -= n }
@   The row and tick counters run independently.  PL_rowLen = rate*speed/tickHz is not an exact
@   multiple of PL_tickLen, so the tick phase drifts against the rows (2 samples per row at
@   21024 Hz, speed 6, 125 BPM).
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpMix
gmpMix:
	push	{r4, r5, r6, r7, lr}                  @ 08136D3C
	mov	r7, sl                                 @ 08136D3E
	mov	r6, sb                                 @ 08136D40
	mov	r5, r8                                 @ 08136D42
	push	{r5, r6, r7}                          @ 08136D44
	ldr	r4, .Llit08136DD0                      @ 08136D46  =0xFFFFFDA0
	add	sp, r4                                 @ 08136D48
	str	r1, [sp, #0x240]                       @ 08136D4A
	str	r2, [sp, #0x244]                       @ 08136D4C
	ldr	r2, .Llit08136DD4                      @ 08136D4E  =gmpMixCount
	ldr	r1, [r2]                               @ 08136D50
	adds	r1, #1                                @ 08136D52
	str	r1, [r2]                               @ 08136D54
	mov	r1, sp                                 @ 08136D56
	str	r1, [sp, #0x258]                       @ 08136D58
	movs	r2, #0                                @ 08136D5A
	str	r2, [sp, #0x250]                       @ 08136D5C
	str	r0, [sp, #0x24c]                       @ 08136D5E
	movs	r3, #0                                @ 08136D60
	str	r3, [sp, #0x248]                       @ 08136D62
	ldr	r2, .Llit08136DD8                      @ 08136D64  =gmpState
	ldr	r0, [r2]                               @ 08136D66
	ldr	r5, .Llit08136DDC                      @ 08136D68  =0x00001BD0
	adds	r0, r0, r5                            @ 08136D6A
	ldr	r0, [r0]                               @ 08136D6C  ST_bufBytes
	ldr	r1, .Llit08136DE0                      @ 08136D6E  =gmpPlayer
	cmp	r3, r0                                 @ 08136D70
	blt	.L08136D76                             @ 08136D72
	b	.L081370DE                               @ 08136D74
.L08136D76:
	ldr	r2, [r2]                               @ 08136D76
	ldr	r3, .Llit08136DE4                      @ 08136D78  =0x00001BBC
	adds	r0, r2, r3                            @ 08136D7A
	movs	r5, #0                                @ 08136D7C
	ldrsh	r0, [r0, r5]                         @ 08136D7E
	cmp	r0, #0                                 @ 08136D80
	beq	.L08136DE8                             @ 08136D82
	ldr	r4, .Llit08136DE0                      @ 08136D84  =gmpPlayer
	ldr	r0, [r4]                               @ 08136D86
	ldr	r0, [r0, #0x20]                        @ 08136D88  PL_rowLeft
	cmp	r0, #0                                 @ 08136D8A
	bne	.L08136D98                             @ 08136D8C
	bl	gmpProcessRow                           @ 08136D8E
	ldr	r1, [r4]                               @ 08136D92
	ldr	r0, [r1, #0x24]                        @ 08136D94  PL_rowLen
	str	r0, [r1, #0x20]                        @ 08136D96  PL_rowLeft
.L08136D98:
	ldr	r0, [r4]                               @ 08136D98
	ldr	r0, [r0, #0x2c]                        @ 08136D9A
	cmp	r0, #0                                 @ 08136D9C
	bne	.L08136DAA                             @ 08136D9E
	bl	gmpProcessTick                          @ 08136DA0
	ldr	r1, [r4]                               @ 08136DA4
	ldr	r0, [r1, #0x30]                        @ 08136DA6
	str	r0, [r1, #0x2c]                        @ 08136DA8
.L08136DAA:
	ldr	r0, [r4]                               @ 08136DAA
	ldr	r1, [r0, #0x20]                        @ 08136DAC
	ldr	r6, [r0, #0x2c]                        @ 08136DAE
	cmp	r1, r6                                 @ 08136DB0
	bge	.L08136DB6                             @ 08136DB2
	adds	r6, r1, #0                            @ 08136DB4
.L08136DB6:
	ldr	r0, [sp, #0x250]                       @ 08136DB6
	adds	r2, r0, r6                            @ 08136DB8
	ldr	r1, .Llit08136DD8                      @ 08136DBA  =gmpState
	ldr	r0, [r1]                               @ 08136DBC
	ldr	r3, .Llit08136DDC                      @ 08136DBE  =0x00001BD0
	adds	r0, r0, r3                            @ 08136DC0
	ldr	r0, [r0]                               @ 08136DC2  ST_bufBytes
	adds	r1, r4, #0                            @ 08136DC4
	cmp	r2, r0                                 @ 08136DC6
	ble	.L08136DEE                             @ 08136DC8
	ldr	r5, [sp, #0x250]                       @ 08136DCA
	subs	r6, r0, r5                            @ 08136DCC
	b	.L08136DEE                               @ 08136DCE
.Llit08136DD0:
	.word	0xFFFFFDA0                           @ 08136DD0
.Llit08136DD4:
	.word	gmpMixCount                          @ 08136DD4
.Llit08136DD8:
	.word	gmpState                             @ 08136DD8
.Llit08136DDC:
	.word	0x00001BD0                           @ 08136DDC
.Llit08136DE0:
	.word	gmpPlayer                            @ 08136DE0
.Llit08136DE4:
	.word	0x00001BBC                           @ 08136DE4
.L08136DE8:
	ldr	r3, .Llit08136E98                      @ 08136DE8  =0x00001BD0
	adds	r0, r2, r3                            @ 08136DEA
	ldr	r6, [r0]                               @ 08136DEC
.L08136DEE:
	movs	r5, #7                                @ 08136DEE
	mov	sb, r5                                 @ 08136DF0
	ldr	r1, [r1]                               @ 08136DF2
	ldr	r2, .Llit08136E9C                      @ 08136DF4  =0x00000B9C
	adds	r0, r1, r2                            @ 08136DF6
	ldr	r2, [r0]                               @ 08136DF8
	ldr	r3, [sp, #0x240]                       @ 08136DFA
	cmp	r3, r2                                 @ 08136DFC
	blt	.L08136E02                             @ 08136DFE
	b	.L081370A8                               @ 08136E00
.L08136E02:
	movs	r0, #0x98                             @ 08136E02
	muls	r0, r3, r0                            @ 08136E04
	adds	r0, #0x54                             @ 08136E06
	adds	r4, r1, r0                            @ 08136E08
	ldr	r5, [sp, #0x244]                       @ 08136E0A
	str	r5, [sp, #0x254]                       @ 08136E0C
	adds	r0, r3, r5                            @ 08136E0E
	cmp	r0, r2                                 @ 08136E10
	ble	.L08136E1E                             @ 08136E12
	ldr	r2, .Llit08136EA0                      @ 08136E14  =0x00000B94
	adds	r0, r1, r2                            @ 08136E16
	ldr	r0, [r0]                               @ 08136E18
	subs	r0, r0, r3                            @ 08136E1A
	str	r0, [sp, #0x254]                       @ 08136E1C
.L08136E1E:
	ldr	r7, [sp, #0x240]                       @ 08136E1E
	ldr	r3, [sp, #0x254]                       @ 08136E20
	cmp	r7, r3                                 @ 08136E22
	blt	.L08136E28                             @ 08136E24
	b	.L08136FA8                               @ 08136E26
.L08136E28:
	movs	r5, #0                                @ 08136E28
	mov	sl, r5                                 @ 08136E2A
	ldr	r0, [sp, #0x258]                       @ 08136E2C
	adds	r0, #0x1c                             @ 08136E2E
	mov	r8, r0                                 @ 08136E30
.L08136E32:
	ldr	r2, [r4]                               @ 08136E32
	cmp	r2, #0                                 @ 08136E34
	bne	.L08136E3A                             @ 08136E36
	b	.L08136F9C                               @ 08136E38
.L08136E3A:
	ldr	r1, .Llit08136EA4                      @ 08136E3A  =gmpState
	mov	ip, r1                                 @ 08136E3C
	ldr	r3, [r1]                               @ 08136E3E
	ldr	r5, .Llit08136EA8                      @ 08136E40  =0x00001BF4
	adds	r0, r3, r5                            @ 08136E42
	ldr	r1, [r0]                               @ 08136E44  ST_mixMode
	cmp	r1, #0                                 @ 08136E46
	bne	.L08136EB4                             @ 08136E48
	ldr	r0, [r4, #0xc]                         @ 08136E4A
	cmp	r0, #2                                 @ 08136E4C
	bhi	.L08136E52                             @ 08136E4E
	b	.L08136F9C                               @ 08136E50
.L08136E52:
	ldr	r0, [r4, #0x18]                        @ 08136E52
	str	r0, [sp, #0x25c]                       @ 08136E54
	ldr	r2, .Llit08136EAC                      @ 08136E56  =0x00001BAC
	adds	r0, r3, r2                            @ 08136E58
	ldr	r0, [r0]                               @ 08136E5A
	ldr	r5, [sp, #0x25c]                       @ 08136E5C
	muls	r0, r5, r0                            @ 08136E5E
	asrs	r2, r0, #6                            @ 08136E60  * music volume / 64
	ldr	r5, .Llit08136EB0                      @ 08136E62  =0x00001BA8
	adds	r0, r3, r5                            @ 08136E64
	ldr	r0, [r0]                               @ 08136E66
	muls	r0, r2, r0                            @ 08136E68
	asrs	r2, r0, #6                            @ 08136E6A  * master volume / 64
	ldr	r0, [r3, #0x50]                        @ 08136E6C
	muls	r0, r2, r0                            @ 08136E6E
	asrs	r2, r0, #6                            @ 08136E70  * ST_fade / 64
	str	r2, [r4, #0x18]                        @ 08136E72
	cmp	r2, #0                                 @ 08136E74
	bge	.L08136E7A                             @ 08136E76
	str	r1, [r4, #0x18]                        @ 08136E78
.L08136E7A:
	ldr	r0, [r4, #0x18]                        @ 08136E7A
	cmp	r0, #0                                 @ 08136E7C
	beq	.L08136E90                             @ 08136E7E
	mov	r1, ip                                 @ 08136E80
	ldr	r0, [r1]                               @ 08136E82
	ldr	r3, [r0, #0x38]                        @ 08136E84
	adds	r0, r4, #0                            @ 08136E86
	ldr	r1, [sp, #0x24c]                       @ 08136E88
	adds	r2, r6, #0                            @ 08136E8A
	bl	gmpCallR3                               @ 08136E8C  mixer(ch, dst, n, ST_mixer)
.L08136E90:
	ldr	r2, [sp, #0x25c]                       @ 08136E90
	str	r2, [r4, #0x18]                        @ 08136E92
	b	.L08136F9C                               @ 08136E94
	.hword	0x0000                              @ 08136E96  (padding)
.Llit08136E98:
	.word	0x00001BD0                           @ 08136E98
.Llit08136E9C:
	.word	0x00000B9C                           @ 08136E9C
.Llit08136EA0:
	.word	0x00000B94                           @ 08136EA0
.Llit08136EA4:
	.word	gmpState                             @ 08136EA4
.Llit08136EA8:
	.word	0x00001BF4                           @ 08136EA8
.Llit08136EAC:
	.word	0x00001BAC                           @ 08136EAC
.Llit08136EB0:
	.word	0x00001BA8                           @ 08136EB0
.L08136EB4:
	cmp	r1, #1                                 @ 08136EB4
	bne	.L08136F9C                             @ 08136EB6
	ldr	r0, [r4, #4]                           @ 08136EB8
	lsrs	r0, r0, #0xc                          @ 08136EBA
	adds	r0, r2, r0                            @ 08136EBC
	mov	r3, r8                                 @ 08136EBE
	adds	r3, #4                                @ 08136EC0
	mov	r8, r3                                 @ 08136EC2
	subs	r3, #4                                @ 08136EC4
	stm	r3!, {r0}                              @ 08136EC6
	movs	r5, #1                                @ 08136EC8
	add	sb, r5                                 @ 08136ECA
	ldr	r0, [r4, #0xc]                         @ 08136ECC
	cmp	r0, #1                                 @ 08136ECE
	bhi	.L08136ED6                             @ 08136ED0
	mov	r0, sl                                 @ 08136ED2
	str	r0, [r4, #0x18]                        @ 08136ED4
.L08136ED6:
	ldr	r0, [r4, #0xc]                         @ 08136ED6
	cmp	r0, #0                                 @ 08136ED8
	beq	.L08136EE2                             @ 08136EDA
	ldr	r2, [r4, #0x18]                        @ 08136EDC
	cmp	r2, #0                                 @ 08136EDE
	bne	.L08136EFA                             @ 08136EE0
.L08136EE2:
	mov	r1, sl                                 @ 08136EE2
	mov	r2, r8                                 @ 08136EE4
	stm	r2!, {r1}                              @ 08136EE6
	stm	r2!, {r1}                              @ 08136EE8
	stm	r2!, {r1}                              @ 08136EEA
	adds	r2, #4                                @ 08136EEC
	mov	r8, r2                                 @ 08136EEE
	subs	r2, #4                                @ 08136EF0
	stm	r2!, {r1}                              @ 08136EF2
	movs	r3, #4                                @ 08136EF4
	add	sb, r3                                 @ 08136EF6
	b	.L08136F74                               @ 08136EF8
.L08136EFA:
	ldr	r5, .Llit08136F24                      @ 08136EFA  =gmpPlayer
	ldr	r0, [r5]                               @ 08136EFC
	ldr	r1, .Llit08136F28                      @ 08136EFE  =0x00000B94
	adds	r0, r0, r1                            @ 08136F00
	ldr	r0, [r0]                               @ 08136F02  PL_nMusic
	cmp	r7, r0                                 @ 08136F04
	bge	.L08136F34                             @ 08136F06
	mov	r3, ip                                 @ 08136F08
	ldr	r1, [r3]                               @ 08136F0A
	ldr	r5, .Llit08136F2C                      @ 08136F0C  =0x00001BAC
	adds	r0, r1, r5                            @ 08136F0E
	ldr	r0, [r0]                               @ 08136F10
	muls	r0, r2, r0                            @ 08136F12
	asrs	r2, r0, #6                            @ 08136F14
	ldr	r3, .Llit08136F30                      @ 08136F16  =0x00001BA8
	adds	r0, r1, r3                            @ 08136F18
	ldr	r0, [r0]                               @ 08136F1A
	muls	r0, r2, r0                            @ 08136F1C
	asrs	r2, r0, #6                            @ 08136F1E
	ldr	r0, [r1, #0x50]                        @ 08136F20
	b	.L08136F48                               @ 08136F22
.Llit08136F24:
	.word	gmpPlayer                            @ 08136F24
.Llit08136F28:
	.word	0x00000B94                           @ 08136F28
.Llit08136F2C:
	.word	0x00001BAC                           @ 08136F2C
.Llit08136F30:
	.word	0x00001BA8                           @ 08136F30
.L08136F34:
	mov	r5, ip                                 @ 08136F34
	ldr	r1, [r5]                               @ 08136F36
	ldr	r3, .Llit081370F4                      @ 08136F38  =0x00001BB0
	adds	r0, r1, r3                            @ 08136F3A
	ldr	r0, [r0]                               @ 08136F3C
	muls	r0, r2, r0                            @ 08136F3E
	asrs	r2, r0, #6                            @ 08136F40
	ldr	r5, .Llit081370F8                      @ 08136F42  =0x00001BA8
	adds	r1, r1, r5                            @ 08136F44
	ldr	r0, [r1]                               @ 08136F46
.L08136F48:
	muls	r0, r2, r0                            @ 08136F48
	asrs	r2, r0, #6                            @ 08136F4A
	mov	r0, r8                                 @ 08136F4C
	adds	r0, #4                                @ 08136F4E
	mov	r8, r0                                 @ 08136F50
	subs	r0, #4                                @ 08136F52
	stm	r0!, {r2}                              @ 08136F54
	ldr	r0, [r4, #4]                           @ 08136F56
	lsls	r0, r0, #0x14                         @ 08136F58
	mov	r1, r8                                 @ 08136F5A
	stm	r1!, {r0}                              @ 08136F5C
	ldr	r0, [r4, #8]                           @ 08136F5E
	lsls	r0, r0, #0x14                         @ 08136F60
	stm	r1!, {r0}                              @ 08136F62
	ldr	r0, [r4, #8]                           @ 08136F64
	lsrs	r0, r0, #0xc                          @ 08136F66
	adds	r1, #4                                @ 08136F68
	mov	r8, r1                                 @ 08136F6A
	subs	r1, #4                                @ 08136F6C
	stm	r1!, {r0}                              @ 08136F6E
	movs	r2, #4                                @ 08136F70
	add	sb, r2                                 @ 08136F72
.L08136F74:
	ldr	r3, [r4, #0xc]                         @ 08136F74
	cmp	r3, #0                                 @ 08136F76
	beq	.L08136F9C                             @ 08136F78
	ldr	r0, [r4, #0x18]                        @ 08136F7A
	cmp	r0, #0                                 @ 08136F7C
	beq	.L08136F9C                             @ 08136F7E
	ldr	r2, [r4, #8]                           @ 08136F80
	adds	r0, r2, #0                            @ 08136F82
	muls	r0, r6, r0                            @ 08136F84
	ldr	r1, [r4, #4]                           @ 08136F86
	adds	r1, r1, r0                            @ 08136F88
	ldr	r5, .Llit081370FC                      @ 08136F8A  =0xFFFFF000
	adds	r0, r3, r5                            @ 08136F8C
	cmp	r1, r0                                 @ 08136F8E
	bls	.L08136F9C                             @ 08136F90
	subs	r0, r1, r3                            @ 08136F92
	adds	r1, r2, #0                            @ 08136F94
	bl	swiDiv                                  @ 08136F96
	subs	r6, r6, r0                            @ 08136F9A
.L08136F9C:
	adds	r4, #0x98                             @ 08136F9C
	adds	r7, #1                                @ 08136F9E
	ldr	r0, [sp, #0x254]                       @ 08136FA0
	cmp	r7, r0                                 @ 08136FA2
	bge	.L08136FA8                             @ 08136FA4
	b	.L08136E32                               @ 08136FA6
.L08136FA8:
	ldr	r2, [sp, #0x250]                       @ 08136FA8
	adds	r1, r2, r6                            @ 08136FAA
	ldr	r3, .Llit08137100                      @ 08136FAC  =gmpState
	ldr	r2, [r3]                               @ 08136FAE
	ldr	r5, .Llit08137104                      @ 08136FB0  =0x00001BD0
	adds	r0, r2, r5                            @ 08136FB2
	ldr	r0, [r0]                               @ 08136FB4  ST_bufBytes
	cmp	r1, r0                                 @ 08136FB6
	ble	.L08136FBE                             @ 08136FB8
	ldr	r1, [sp, #0x250]                       @ 08136FBA
	subs	r6, r0, r1                            @ 08136FBC
.L08136FBE:
	ldr	r3, .Llit08137108                      @ 08136FBE  =0x00001BBC
	adds	r0, r2, r3                            @ 08136FC0
	movs	r5, #0                                @ 08136FC2
	ldrsh	r0, [r0, r5]                         @ 08136FC4
	cmp	r0, #0                                 @ 08136FC6
	beq	.L08136FDE                             @ 08136FC8
	ldr	r0, .Llit0813710C                      @ 08136FCA  =gmpPlayer
	ldr	r1, [r0]                               @ 08136FCC
	ldr	r0, [r1, #0x20]                        @ 08136FCE  PL_rowLeft
	cmp	r6, r0                                 @ 08136FD0
	ble	.L08136FD6                             @ 08136FD2
	adds	r6, r0, #0                            @ 08136FD4
.L08136FD6:
	ldr	r0, [r1, #0x2c]                        @ 08136FD6
	cmp	r6, r0                                 @ 08136FD8
	ble	.L08136FDE                             @ 08136FDA
	adds	r6, r0, #0                            @ 08136FDC
.L08136FDE:
	ldr	r1, .Llit08137100                      @ 08136FDE  =gmpState
	ldr	r2, [r1]                               @ 08136FE0
	ldr	r3, .Llit08137110                      @ 08136FE2  =0x00001BF4
	adds	r0, r2, r3                            @ 08136FE4
	ldr	r0, [r0]                               @ 08136FE6  ST_mixMode
	cmp	r0, #1                                 @ 08136FE8
	bne	.L081370A8                             @ 08136FEA
	mov	r5, sb                                 @ 08136FEC
	cmp	r5, #7                                 @ 08136FEE
	beq	.L081370A8                             @ 08136FF0
	lsls	r1, r5, #2                            @ 08136FF2
	ldr	r0, [sp, #0x258]                       @ 08136FF4
	adds	r1, r1, r0                            @ 08136FF6
	mov	r0, sb                                 @ 08136FF8
	subs	r0, #2                                @ 08136FFA
	lsls	r0, r0, #2                            @ 08136FFC
	str	r0, [r1]                               @ 08136FFE
	movs	r1, #1                                @ 08137000
	add	sb, r1                                 @ 08137002
	mov	r3, sb                                 @ 08137004
	lsls	r0, r3, #2                            @ 08137006
	ldr	r5, [sp, #0x258]                       @ 08137008
	adds	r0, r0, r5                            @ 0813700A
	movs	r1, #0xff                             @ 0813700C
	str	r1, [r0]                               @ 0813700E
	movs	r0, #1                                @ 08137010
	add	sb, r0                                 @ 08137012
	mov	r1, sb                                 @ 08137014
	lsls	r0, r1, #2                            @ 08137016
	adds	r0, r0, r5                            @ 08137018
	movs	r1, #0                                @ 0813701A
	str	r1, [r0]                               @ 0813701C
	movs	r3, #1                                @ 0813701E
	add	sb, r3                                 @ 08137020
	mov	r5, sb                                 @ 08137022
	lsls	r0, r5, #2                            @ 08137024
	ldr	r3, [sp, #0x258]                       @ 08137026
	adds	r0, r0, r3                            @ 08137028
	str	r1, [r0]                               @ 0813702A
	movs	r5, #1                                @ 0813702C
	add	sb, r5                                 @ 0813702E
	mov	r3, sb                                 @ 08137030
	lsls	r0, r3, #2                            @ 08137032
	ldr	r5, [sp, #0x258]                       @ 08137034
	adds	r0, r0, r5                            @ 08137036
	str	r1, [r0]                               @ 08137038
	cmp	r6, #0                                 @ 0813703A
	ble	.L08137058                             @ 0813703C
	ldr	r1, .Llit08137114                      @ 0813703E  =0x00001C04
	adds	r0, r2, r1                            @ 08137040
	ldr	r3, [sp, #0x24c]                       @ 08137042
	str	r3, [r0]                               @ 08137044  ST_lastBuf
	ldr	r5, .Llit08137118                      @ 08137046  =0x00001C08
	adds	r0, r2, r5                            @ 08137048
	str	r6, [r0]                               @ 0813704A  ST_lastLen
	ldr	r3, [r2, #0x38]                        @ 0813704C  ST_mixer
	mov	r0, sp                                 @ 0813704E
	ldr	r1, [sp, #0x24c]                       @ 08137050
	adds	r2, r6, #0                            @ 08137052
	bl	gmpCallR3                               @ 08137054  mode 1: one call for all channels
.L08137058:
	movs	r0, #0x98                             @ 08137058
	ldr	r1, [sp, #0x240]                       @ 0813705A
	muls	r0, r1, r0                            @ 0813705C
	adds	r0, #0x54                             @ 0813705E
	ldr	r2, .Llit0813710C                      @ 08137060  =gmpPlayer
	ldr	r1, [r2]                               @ 08137062
	adds	r4, r1, r0                            @ 08137064
	ldr	r7, [sp, #0x240]                       @ 08137066
	ldr	r3, [sp, #0x254]                       @ 08137068
	cmp	r7, r3                                 @ 0813706A
	bge	.L081370A8                             @ 0813706C
	subs	r7, r3, r7                            @ 0813706E
.L08137070:
	ldr	r2, [r4, #0xc]                         @ 08137070
	cmp	r2, #0                                 @ 08137072
	bne	.L0813707C                             @ 08137074
	ldr	r0, [r4, #0x18]                        @ 08137076
	cmp	r0, #0                                 @ 08137078
	beq	.L081370A0                             @ 0813707A
.L0813707C:
	ldr	r0, [r4, #8]                           @ 0813707C
	adds	r1, r0, #0                            @ 0813707E
	muls	r1, r6, r1                            @ 08137080
	ldr	r0, [r4, #4]                           @ 08137082
	adds	r0, r0, r1                            @ 08137084
	str	r0, [r4, #4]                           @ 08137086
	subs	r3, r0, r2                            @ 08137088
	cmp	r0, r2                                 @ 0813708A
	blo	.L081370A0                             @ 0813708C
	ldr	r0, [r4]                               @ 0813708E
	ldr	r1, [r4, #0x10]                        @ 08137090
	adds	r0, r0, r1                            @ 08137092
	str	r0, [r4]                               @ 08137094
	str	r3, [r4, #4]                           @ 08137096
	ldr	r0, [r4, #0x14]                        @ 08137098
	str	r0, [r4, #0xc]                         @ 0813709A
	movs	r0, #0                                @ 0813709C
	str	r0, [r4, #0x10]                        @ 0813709E
.L081370A0:
	adds	r4, #0x98                             @ 081370A0
	subs	r7, #1                                @ 081370A2
	cmp	r7, #0                                 @ 081370A4
	bne	.L08137070                             @ 081370A6
.L081370A8:
	ldr	r5, [sp, #0x24c]                       @ 081370A8
	adds	r5, r5, r6                            @ 081370AA
	str	r5, [sp, #0x24c]                       @ 081370AC
	ldr	r0, [sp, #0x250]                       @ 081370AE
	adds	r0, r0, r6                            @ 081370B0
	str	r0, [sp, #0x250]                       @ 081370B2
	ldr	r1, [sp, #0x248]                       @ 081370B4
	adds	r1, r1, r6                            @ 081370B6
	str	r1, [sp, #0x248]                       @ 081370B8
	ldr	r2, .Llit0813710C                      @ 081370BA  =gmpPlayer
	ldr	r1, [r2]                               @ 081370BC
	ldr	r0, [r1, #0x20]                        @ 081370BE  PL_rowLeft
	subs	r0, r0, r6                            @ 081370C0
	str	r0, [r1, #0x20]                        @ 081370C2  PL_rowLeft
	ldr	r0, [r1, #0x2c]                        @ 081370C4  PL_tickLeft
	subs	r0, r0, r6                            @ 081370C6
	str	r0, [r1, #0x2c]                        @ 081370C8  PL_tickLeft
	ldr	r2, .Llit08137100                      @ 081370CA  =gmpState
	ldr	r0, [r2]                               @ 081370CC
	ldr	r3, .Llit08137104                      @ 081370CE  =0x00001BD0
	adds	r0, r0, r3                            @ 081370D0
	ldr	r0, [r0]                               @ 081370D2  ST_bufBytes
	ldr	r1, .Llit0813710C                      @ 081370D4  =gmpPlayer
	ldr	r5, [sp, #0x248]                       @ 081370D6
	cmp	r5, r0                                 @ 081370D8
	bge	.L081370DE                             @ 081370DA
	b	.L08136D76                               @ 081370DC
.L081370DE:
	movs	r3, #0x98                             @ 081370DE
	lsls	r3, r3, #2                            @ 081370E0
	add	sp, r3                                 @ 081370E2
	pop	{r3, r4, r5}                           @ 081370E4
	mov	r8, r3                                 @ 081370E6
	mov	sb, r4                                 @ 081370E8
	mov	sl, r5                                 @ 081370EA
	pop	{r4, r5, r6, r7}                       @ 081370EC
	pop	{r0}                                   @ 081370EE
	bx	r0                                      @ 081370F0
	.hword	0x0000                              @ 081370F2  (padding)
.Llit081370F4:
	.word	0x00001BB0                           @ 081370F4
.Llit081370F8:
	.word	0x00001BA8                           @ 081370F8
.Llit081370FC:
	.word	0xFFFFF000                           @ 081370FC
.Llit08137100:
	.word	gmpState                             @ 08137100
.Llit08137104:
	.word	0x00001BD0                           @ 08137104
.Llit08137108:
	.word	0x00001BBC                           @ 08137108
.Llit0813710C:
	.word	gmpPlayer                            @ 0813710C
.Llit08137110:
	.word	0x00001BF4                           @ 08137110
.Llit08137114:
	.word	0x00001C04                           @ 08137114
.Llit08137118:
	.word	0x00001C08                           @ 08137118
@ --------------------------------------------------------------------------
@ gmpEchoInit(buf, size)  (0x0813711C)  -- unused
@   ST_echoLenA = 0x2C0, ST_echoLenB = 0x3AC; ST_echoBuf = buf; memset(buf, 0, size); positions and level = 0
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpEchoInit
gmpEchoInit:
	push	{r4, r5, r6, lr}                      @ 0813711C
	adds	r2, r1, #0                            @ 0813711E
	ldr	r6, .Llit08137170                      @ 08137120  =gmpState
	ldr	r5, [r6]                               @ 08137122
	ldr	r1, .Llit08137174                      @ 08137124  =0x00001BDC
	adds	r3, r5, r1                            @ 08137126
	movs	r1, #0xb0                             @ 08137128
	lsls	r1, r1, #1                            @ 0813712A
	str	r1, [r3]                               @ 0813712C  ST_echoLenA
	movs	r1, #0xdf                             @ 0813712E
	lsls	r1, r1, #5                            @ 08137130
	adds	r4, r5, r1                            @ 08137132
	movs	r1, #0xeb                             @ 08137134
	lsls	r1, r1, #1                            @ 08137136
	str	r1, [r4]                               @ 08137138  ST_echoLenB
	ldr	r1, [r3]                               @ 0813713A  ST_echoLenA
	lsls	r1, r1, #1                            @ 0813713C
	str	r1, [r3]                               @ 0813713E  ST_echoLenA
	ldr	r1, [r4]                               @ 08137140  ST_echoLenB
	lsls	r1, r1, #1                            @ 08137142
	str	r1, [r4]                               @ 08137144  ST_echoLenB
	ldr	r3, .Llit08137178                      @ 08137146  =0x00001BE4
	adds	r5, r5, r3                            @ 08137148
	str	r0, [r5]                               @ 0813714A  ST_echoBuf
	movs	r1, #0                                @ 0813714C
	bl	memset                                  @ 0813714E
	ldr	r1, [r6]                               @ 08137152
	ldr	r2, .Llit0813717C                      @ 08137154  =0x00001BE8
	adds	r0, r1, r2                            @ 08137156
	movs	r2, #0                                @ 08137158
	str	r2, [r0]                               @ 0813715A  ST_echoPosA
	ldr	r3, .Llit08137180                      @ 0813715C  =0x00001BEC
	adds	r0, r1, r3                            @ 0813715E
	str	r2, [r0]                               @ 08137160  ST_echoPosB
	ldr	r0, .Llit08137184                      @ 08137162  =0x00001BF0
	adds	r1, r1, r0                            @ 08137164
	str	r2, [r1]                               @ 08137166  ST_echoLevel
	movs	r0, #0                                @ 08137168
	pop	{r4, r5, r6}                           @ 0813716A
	pop	{r1}                                   @ 0813716C
	bx	r1                                      @ 0813716E
.Llit08137170:
	.word	gmpState                             @ 08137170
.Llit08137174:
	.word	0x00001BDC                           @ 08137174
.Llit08137178:
	.word	0x00001BE4                           @ 08137178
.Llit0813717C:
	.word	0x00001BE8                           @ 0813717C
.Llit08137180:
	.word	0x00001BEC                           @ 08137180
.Llit08137184:
	.word	0x00001BF0                           @ 08137184
@ --------------------------------------------------------------------------
@ gmpSetEcho(level)  (0x08137188)  -- unused
@   ST_echoLevel = level
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpSetEcho
gmpSetEcho:
	ldr	r1, .Llit08137194                      @ 08137188  =gmpState
	ldr	r1, [r1]                               @ 0813718A
	ldr	r2, .Llit08137198                      @ 0813718C  =0x00001BF0
	adds	r1, r1, r2                            @ 0813718E
	str	r0, [r1]                               @ 08137190  ST_echoLevel
	bx	lr                                      @ 08137192
.Llit08137194:
	.word	gmpState                             @ 08137194
.Llit08137198:
	.word	0x00001BF0                           @ 08137198
@ --------------------------------------------------------------------------
@ gmpApplyEcho(buf, level, len)  (0x0813719C)
@   Two-tap feedback delay on the mixed music (8-bit, in place):
@     level = min(level, 63) * 2
@     for each sample: e[b] = ((buf + e[b]) * level) >> 7; b++ (wrap at ST_echoLenA);
@                      a++ (wrap at ST_echoLenB); buf += e[b] - e[a]
@   Needs gmpEchoInit, which NFSU2 never calls.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpApplyEcho
gmpApplyEcho:
	push	{r4, r5, r6, r7, lr}                  @ 0813719C
	mov	r7, sl                                 @ 0813719E
	mov	r6, sb                                 @ 081371A0
	mov	r5, r8                                 @ 081371A2
	push	{r5, r6, r7}                          @ 081371A4
	adds	r6, r0, #0                            @ 081371A6
	adds	r7, r2, #0                            @ 081371A8
	cmp	r1, #0x3f                              @ 081371AA
	ble	.L081371B0                             @ 081371AC
	movs	r1, #0x3f                             @ 081371AE
.L081371B0:
	lsls	r1, r1, #1                            @ 081371B0
	mov	sl, r1                                 @ 081371B2
	ldr	r2, .Llit08137250                      @ 081371B4  =gmpState
	ldr	r0, [r2]                               @ 081371B6
	ldr	r3, .Llit08137254                      @ 081371B8  =0x00001BE8
	adds	r1, r0, r3                            @ 081371BA
	ldr	r4, [r1]                               @ 081371BC  ST_echoPosA
	adds	r3, #4                                @ 081371BE
	adds	r1, r0, r3                            @ 081371C0
	ldr	r5, [r1]                               @ 081371C2  ST_echoPosB
	subs	r3, #0x10                             @ 081371C4
	adds	r1, r0, r3                            @ 081371C6
	ldr	r1, [r1]                               @ 081371C8  ST_echoLenA
	mov	sb, r1                                 @ 081371CA
	adds	r3, #4                                @ 081371CC
	adds	r1, r0, r3                            @ 081371CE
	ldr	r1, [r1]                               @ 081371D0  ST_echoLenB
	mov	r8, r1                                 @ 081371D2
	ldr	r1, .Llit08137258                      @ 081371D4  =0x00001BE4
	adds	r0, r0, r1                            @ 081371D6
	ldr	r0, [r0]                               @ 081371D8  ST_echoBuf
	mov	ip, r0                                 @ 081371DA
	subs	r7, #1                                @ 081371DC
	movs	r0, #1                                @ 081371DE
	rsbs	r0, r0, #0                            @ 081371E0
	cmp	r7, r0                                 @ 081371E2
	beq	.L08137232                             @ 081371E4
	mov	r2, ip                                 @ 081371E6
	adds	r3, r5, r2                            @ 081371E8
.L081371EA:
	movs	r0, #0                                @ 081371EA
	ldrsb	r0, [r6, r0]                         @ 081371EC
	movs	r1, #0                                @ 081371EE
	ldrsb	r1, [r3, r1]                         @ 081371F0
	adds	r1, r1, r0                            @ 081371F2
	mov	r0, sl                                 @ 081371F4
	muls	r0, r1, r0                            @ 081371F6
	asrs	r0, r0, #7                            @ 081371F8
	strb	r0, [r3]                              @ 081371FA
	adds	r3, #1                                @ 081371FC
	adds	r5, #1                                @ 081371FE
	cmp	r5, r8                                 @ 08137200
	blt	.L08137208                             @ 08137202
	mov	r3, ip                                 @ 08137204
	movs	r5, #0                                @ 08137206
.L08137208:
	adds	r4, #1                                @ 08137208
	cmp	r4, sb                                 @ 0813720A
	blt	.L08137210                             @ 0813720C
	movs	r4, #0                                @ 0813720E
.L08137210:
	movs	r1, #0                                @ 08137210
	ldrsb	r1, [r3, r1]                         @ 08137212
	mov	r2, ip                                 @ 08137214
	adds	r0, r2, r4                            @ 08137216
	ldrb	r0, [r0]                              @ 08137218
	lsls	r0, r0, #0x18                         @ 0813721A
	asrs	r0, r0, #0x18                         @ 0813721C
	subs	r1, r1, r0                            @ 0813721E
	ldrb	r0, [r6]                              @ 08137220
	adds	r1, r1, r0                            @ 08137222
	strb	r1, [r6]                              @ 08137224
	adds	r6, #1                                @ 08137226
	subs	r7, #1                                @ 08137228
	movs	r0, #1                                @ 0813722A
	rsbs	r0, r0, #0                            @ 0813722C
	cmp	r7, r0                                 @ 0813722E
	bne	.L081371EA                             @ 08137230
.L08137232:
	ldr	r1, .Llit08137250                      @ 08137232  =gmpState
	ldr	r0, [r1]                               @ 08137234
	ldr	r2, .Llit08137254                      @ 08137236  =0x00001BE8
	adds	r1, r0, r2                            @ 08137238
	str	r4, [r1]                               @ 0813723A  ST_echoPosA
	ldr	r3, .Llit0813725C                      @ 0813723C  =0x00001BEC
	adds	r0, r0, r3                            @ 0813723E
	str	r5, [r0]                               @ 08137240  ST_echoPosB
	pop	{r3, r4, r5}                           @ 08137242
	mov	r8, r3                                 @ 08137244
	mov	sb, r4                                 @ 08137246
	mov	sl, r5                                 @ 08137248
	pop	{r4, r5, r6, r7}                       @ 0813724A
	pop	{r0}                                   @ 0813724C
	bx	r0                                      @ 0813724E
.Llit08137250:
	.word	gmpState                             @ 08137250
.Llit08137254:
	.word	0x00001BE8                           @ 08137254
.Llit08137258:
	.word	0x00001BE4                           @ 08137258
.Llit0813725C:
	.word	0x00001BEC                           @ 0813725C
@ --------------------------------------------------------------------------
@ gmpMixSfx(dst)  (0x08137260)
@   mode 0 only: for each SFX channel with CH_end > 2:
@     v = CH_vol * sfxVol / 64 * masterVol / 64; mixer(ch, dst, ST_bufBytes)
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpMixSfx
gmpMixSfx:
	push	{r4, r5, r6, r7, lr}                  @ 08137260
	ldr	r1, .Llit081372D8                      @ 08137262  =gmpPlayer
	ldr	r2, [r1]                               @ 08137264
	ldr	r3, .Llit081372DC                      @ 08137266  =0x00000B94
	adds	r1, r2, r3                            @ 08137268
	ldr	r1, [r1]                               @ 0813726A  PL_nMusic
	adds	r7, r0, #0                            @ 0813726C
	movs	r0, #0x98                             @ 0813726E
	muls	r0, r1, r0                            @ 08137270
	adds	r0, #0x54                             @ 08137272
	adds	r4, r2, r0                            @ 08137274
	adds	r5, r1, #0                            @ 08137276
	ldr	r0, .Llit081372E0                      @ 08137278  =0x00000B9C
	adds	r2, r2, r0                            @ 0813727A
	ldr	r0, [r2]                               @ 0813727C  PL_nChan
	cmp	r5, r0                                 @ 0813727E
	bge	.L081372D2                             @ 08137280
.L08137282:
	ldr	r0, [r4, #0xc]                         @ 08137282
	cmp	r0, #2                                 @ 08137284
	bls	.L081372C0                             @ 08137286
	ldr	r6, [r4, #0x18]                        @ 08137288
	ldr	r3, .Llit081372E4                      @ 0813728A  =gmpState
	ldr	r1, [r3]                               @ 0813728C
	ldr	r2, .Llit081372E8                      @ 0813728E  =0x00001BB0
	adds	r0, r1, r2                            @ 08137290
	ldr	r0, [r0]                               @ 08137292  ST_sfxVol
	muls	r0, r6, r0                            @ 08137294
	asrs	r2, r0, #6                            @ 08137296
	ldr	r0, .Llit081372EC                      @ 08137298  =0x00001BA8
	adds	r1, r1, r0                            @ 0813729A
	ldr	r0, [r1]                               @ 0813729C  ST_masterVol
	muls	r0, r2, r0                            @ 0813729E
	asrs	r2, r0, #6                            @ 081372A0
	str	r2, [r4, #0x18]                        @ 081372A2
	cmp	r2, #0                                 @ 081372A4
	bge	.L081372AC                             @ 081372A6
	movs	r0, #0                                @ 081372A8
	str	r0, [r4, #0x18]                        @ 081372AA
.L081372AC:
	ldr	r1, [r3]                               @ 081372AC
	ldr	r2, .Llit081372F0                      @ 081372AE  =0x00001BD0
	adds	r0, r1, r2                            @ 081372B0
	ldr	r2, [r0]                               @ 081372B2
	ldr	r3, [r1, #0x38]                        @ 081372B4
	adds	r0, r4, #0                            @ 081372B6
	adds	r1, r7, #0                            @ 081372B8
	bl	gmpCallR3                               @ 081372BA
	str	r6, [r4, #0x18]                        @ 081372BE
.L081372C0:
	adds	r4, #0x98                             @ 081372C0
	adds	r5, #1                                @ 081372C2
	ldr	r0, .Llit081372D8                      @ 081372C4  =gmpPlayer
	ldr	r0, [r0]                               @ 081372C6
	ldr	r3, .Llit081372E0                      @ 081372C8  =0x00000B9C
	adds	r0, r0, r3                            @ 081372CA
	ldr	r0, [r0]                               @ 081372CC  PL_nChan
	cmp	r5, r0                                 @ 081372CE
	blt	.L08137282                             @ 081372D0
.L081372D2:
	pop	{r4, r5, r6, r7}                       @ 081372D2
	pop	{r0}                                   @ 081372D4
	bx	r0                                      @ 081372D6
.Llit081372D8:
	.word	gmpPlayer                            @ 081372D8
.Llit081372DC:
	.word	0x00000B94                           @ 081372DC
.Llit081372E0:
	.word	0x00000B9C                           @ 081372E0
.Llit081372E4:
	.word	gmpState                             @ 081372E4
.Llit081372E8:
	.word	0x00001BB0                           @ 081372E8
.Llit081372EC:
	.word	0x00001BA8                           @ 081372EC
.Llit081372F0:
	.word	0x00001BD0                           @ 081372F0
@ --------------------------------------------------------------------------
@ gmpPlaySfxAuto(sfx, rate, priority, volume)  (0x081372F4)  -- unused by NFSU2
@   Channel allocation by priority:
@     1. a free SFX channel (CH_end <= 2 or CH_vol == 0 marks CH_sfxPri = -1)
@     2. else the first channel whose priority is lower than `priority`
@     3. else pick the non-looping channel (priority != 0x7FFF) that has played furthest...
@        but the code then tests the loop counter instead of the pick (cmp r5, PL_nChan at
@        0x08137442) and always returns -1.  Step 3 is dead.
@   The chosen channel gets CH_sfxPri = priority and starts like gmpPlaySfx; returns the SFX
@   channel number.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpPlaySfxAuto
gmpPlaySfxAuto:
	push	{r4, r5, r6, r7, lr}                  @ 081372F4
	mov	r7, sl                                 @ 081372F6
	mov	r6, sb                                 @ 081372F8
	mov	r5, r8                                 @ 081372FA
	push	{r5, r6, r7}                          @ 081372FC
	mov	r8, r0                                 @ 081372FE
	mov	sb, r1                                 @ 08137300
	adds	r7, r2, #0                            @ 08137302
	mov	sl, r3                                 @ 08137304
	ldr	r0, .Llit0813731C                      @ 08137306  =gmpState
	ldr	r1, [r0]                               @ 08137308
	ldr	r2, .Llit08137320                      @ 0813730A  =0x00001BB8
	adds	r1, r1, r2                            @ 0813730C
	ldr	r1, [r1]                               @ 0813730E  ST_sfxCount
	cmp	r8, r1                                 @ 08137310
	blo	.L08137328                             @ 08137312
.L08137314:
	movs	r0, #1                                @ 08137314
	rsbs	r0, r0, #0                            @ 08137316
	b	.L081374EA                               @ 08137318
	.hword	0x0000                              @ 0813731A  (padding)
.Llit0813731C:
	.word	gmpState                             @ 0813731C
.Llit08137320:
	.word	0x00001BB8                           @ 08137320
.L08137324:
	strh	r7, [r1]                              @ 08137324
	b	.L08137384                               @ 08137326
.L08137328:
	ldr	r3, .Llit081373A8                      @ 08137328  =gmpPlayer
	ldr	r1, [r3]                               @ 0813732A
	ldr	r6, .Llit081373AC                      @ 0813732C  =0x00000B94
	adds	r0, r1, r6                            @ 0813732E
	ldr	r2, [r0]                               @ 08137330  PL_nMusic
	movs	r0, #0x98                             @ 08137332
	muls	r0, r2, r0                            @ 08137334
	adds	r0, #0x54                             @ 08137336
	adds	r4, r1, r0                            @ 08137338
	adds	r5, r2, #0                            @ 0813733A
	ldr	r0, .Llit081373B0                      @ 0813733C  =0x00000B9C
	adds	r1, r1, r0                            @ 0813733E
	ldr	r0, [r1]                               @ 08137340  PL_nChan
	cmp	r5, r0                                 @ 08137342
	bge	.L08137384                             @ 08137344
	ldr	r1, .Llit081373B4                      @ 08137346  =0x0000FFFF
	adds	r2, r1, #0                            @ 08137348
	movs	r6, #1                                @ 0813734A
	rsbs	r6, r6, #0                            @ 0813734C
	mov	ip, r6                                 @ 0813734E
.L08137350:
	ldr	r0, [r4, #0xc]                         @ 08137350
	adds	r1, r4, #0                            @ 08137352
	adds	r1, #0x90                             @ 08137354
	cmp	r0, #2                                 @ 08137356
	bhi	.L08137360                             @ 08137358
	ldrh	r0, [r1]                              @ 0813735A
	orrs	r0, r2                                @ 0813735C
	strh	r0, [r1]                              @ 0813735E
.L08137360:
	ldr	r0, [r4, #0x18]                        @ 08137360
	cmp	r0, #0                                 @ 08137362
	bne	.L0813736C                             @ 08137364
	ldrh	r0, [r1]                              @ 08137366
	orrs	r0, r2                                @ 08137368
	strh	r0, [r1]                              @ 0813736A
.L0813736C:
	movs	r6, #0                                @ 0813736C
	ldrsh	r0, [r1, r6]                         @ 0813736E
	cmp	r0, ip                                 @ 08137370
	beq	.L08137324                             @ 08137372
	adds	r4, #0x98                             @ 08137374
	adds	r5, #1                                @ 08137376
	ldr	r0, [r3]                               @ 08137378
	ldr	r1, .Llit081373B0                      @ 0813737A  =0x00000B9C
	adds	r0, r0, r1                            @ 0813737C
	ldr	r0, [r0]                               @ 0813737E
	cmp	r5, r0                                 @ 08137380
	blt	.L08137350                             @ 08137382
.L08137384:
	ldr	r6, [r3]                               @ 08137384
	ldr	r2, .Llit081373B0                      @ 08137386  =0x00000B9C
	adds	r0, r6, r2                            @ 08137388
	ldr	r2, [r0]                               @ 0813738A
	cmp	r5, r2                                 @ 0813738C
	bne	.L08137448                             @ 0813738E
	ldr	r1, .Llit081373AC                      @ 08137390  =0x00000B94
	adds	r0, r6, r1                            @ 08137392
	ldr	r1, [r0]                               @ 08137394
	movs	r0, #0x98                             @ 08137396
	muls	r0, r1, r0                            @ 08137398
	adds	r0, #0x54                             @ 0813739A
	adds	r4, r6, r0                            @ 0813739C
	adds	r5, r1, #0                            @ 0813739E
	cmp	r5, r2                                 @ 081373A0
	bge	.L081373D6                             @ 081373A2
	b	.L081373C8                               @ 081373A4
	.hword	0x0000                              @ 081373A6  (padding)
.Llit081373A8:
	.word	gmpPlayer                            @ 081373A8
.Llit081373AC:
	.word	0x00000B94                           @ 081373AC
.Llit081373B0:
	.word	0x00000B9C                           @ 081373B0
.Llit081373B4:
	.word	0x0000FFFF                           @ 081373B4
.L081373B8:
	adds	r4, #0x98                             @ 081373B8
	adds	r5, #1                                @ 081373BA
	ldr	r0, [r3]                               @ 081373BC
	ldr	r6, .Llit081374F8                      @ 081373BE  =0x00000B9C
	adds	r0, r0, r6                            @ 081373C0
	ldr	r0, [r0]                               @ 081373C2
	cmp	r5, r0                                 @ 081373C4
	bge	.L081373D6                             @ 081373C6
.L081373C8:
	adds	r1, r4, #0                            @ 081373C8
	adds	r1, #0x90                             @ 081373CA
	movs	r2, #0                                @ 081373CC
	ldrsh	r0, [r1, r2]                         @ 081373CE
	cmp	r0, r7                                 @ 081373D0
	bge	.L081373B8                             @ 081373D2
	strh	r7, [r1]                              @ 081373D4
.L081373D6:
	ldr	r6, [r3]                               @ 081373D6
	ldr	r1, .Llit081374F8                      @ 081373D8  =0x00000B9C
	adds	r0, r6, r1                            @ 081373DA
	ldr	r2, [r0]                               @ 081373DC
	cmp	r5, r2                                 @ 081373DE
	bne	.L08137448                             @ 081373E0
	subs	r1, #8                                @ 081373E2
	adds	r0, r6, r1                            @ 081373E4
	ldr	r1, [r0]                               @ 081373E6
	movs	r0, #0x98                             @ 081373E8
	muls	r0, r1, r0                            @ 081373EA
	adds	r0, #0x54                             @ 081373EC
	adds	r4, r6, r0                            @ 081373EE
	movs	r6, #0                                @ 081373F0
	movs	r7, #1                                @ 081373F2
	rsbs	r7, r7, #0                            @ 081373F4
	adds	r5, r1, #0                            @ 081373F6
	cmp	r5, r2                                 @ 081373F8
	bge	.L08137426                             @ 081373FA
	ldr	r0, .Llit081374FC                      @ 081373FC  =0x00007FFF
	mov	ip, r0                                 @ 081373FE
	adds	r1, r2, #0                            @ 08137400
.L08137402:
	adds	r0, r4, #0                            @ 08137402
	adds	r0, #0x90                             @ 08137404
	movs	r2, #0                                @ 08137406
	ldrsh	r0, [r0, r2]                         @ 08137408
	cmp	r0, ip                                 @ 0813740A
	beq	.L0813741E                             @ 0813740C
	ldr	r0, [r4, #0x14]                        @ 0813740E
	cmp	r0, #0                                 @ 08137410
	bne	.L0813741E                             @ 08137412
	ldr	r0, [r4, #4]                           @ 08137414
	cmp	r0, r6                                 @ 08137416
	bls	.L0813741E                             @ 08137418
	adds	r7, r5, #0                            @ 0813741A
	adds	r6, r0, #0                            @ 0813741C
.L0813741E:
	adds	r4, #0x98                             @ 0813741E
	adds	r5, #1                                @ 08137420
	cmp	r5, r1                                 @ 08137422
	blt	.L08137402                             @ 08137424
.L08137426:
	movs	r2, #1                                @ 08137426
	rsbs	r2, r2, #0                            @ 08137428
	cmp	r7, r2                                 @ 0813742A
	bne	.L08137430                             @ 0813742C
	b	.L08137314                               @ 0813742E
.L08137430:
	movs	r0, #0x98                             @ 08137430
	adds	r1, r7, #0                            @ 08137432
	muls	r1, r0, r1                            @ 08137434
	adds	r1, #0x54                             @ 08137436
	ldr	r0, [r3]                               @ 08137438
	adds	r4, r0, r1                            @ 0813743A
	ldr	r6, .Llit081374F8                      @ 0813743C  =0x00000B9C
	adds	r0, r0, r6                            @ 0813743E
	ldr	r0, [r0]                               @ 08137440
	cmp	r5, r0                                 @ 08137442
	bne	.L08137448                             @ 08137444
	b	.L08137314                               @ 08137446
.L08137448:
	adds	r0, r4, #0                            @ 08137448
	adds	r0, #0x40                             @ 0813744A
	movs	r7, #0                                @ 0813744C
	mov	r1, r8                                 @ 0813744E
	strh	r1, [r0]                              @ 08137450
	ldr	r2, .Llit08137500                      @ 08137452  =gmpState
	ldr	r3, [r2]                               @ 08137454
	movs	r6, #0xdd                             @ 08137456
	lsls	r6, r6, #5                            @ 08137458
	adds	r1, r3, r6                            @ 0813745A
	mov	r2, r8                                 @ 0813745C
	lsls	r0, r2, #1                            @ 0813745E
	add	r0, r8                                 @ 08137460
	lsls	r0, r0, #3                            @ 08137462
	ldr	r1, [r1]                               @ 08137464  ST_sfxEntries
	adds	r6, r1, r0                            @ 08137466
	mov	r0, sb                                 @ 08137468
	cmp	r0, #0                                 @ 0813746A
	bne	.L08137472                             @ 0813746C
	ldr	r1, [r6, #0x10]                        @ 0813746E
	mov	sb, r1                                 @ 08137470
.L08137472:
	ldr	r2, .Llit08137504                      @ 08137472  =0x00001BA4
	adds	r0, r3, r2                            @ 08137474
	ldr	r0, [r0]                               @ 08137476
	ldr	r1, [r6]                               @ 08137478
	adds	r0, r0, r1                            @ 0813747A
	str	r0, [r4]                               @ 0813747C
	ldr	r0, [r6, #4]                           @ 0813747E
	lsls	r0, r0, #0xc                          @ 08137480
	str	r0, [r4, #0xc]                         @ 08137482
	ldrh	r0, [r6, #0xc]                        @ 08137484
	str	r0, [r4, #0x10]                        @ 08137486
	ldrh	r0, [r6, #0xe]                        @ 08137488
	lsls	r0, r0, #0xc                          @ 0813748A
	str	r0, [r4, #0x14]                        @ 0813748C
	mov	r0, sl                                 @ 0813748E
	str	r0, [r4, #0x18]                        @ 08137490
	str	r0, [r4, #0x1c]                        @ 08137492
	ldrh	r0, [r6, #8]                          @ 08137494
	adds	r1, r4, #0                            @ 08137496
	adds	r1, #0x44                             @ 08137498
	strh	r0, [r1]                              @ 0813749A
	adds	r2, r4, #0                            @ 0813749C
	adds	r2, #0x46                             @ 0813749E
	ldr	r0, .Llit08137508                      @ 081374A0  =0x0000FFFF
	strh	r0, [r2]                              @ 081374A2
	str	r7, [r4, #4]                           @ 081374A4
	strh	r7, [r1]                              @ 081374A6
	adds	r0, r4, #0                            @ 081374A8
	adds	r0, #0x54                             @ 081374AA
	strh	r7, [r0]                              @ 081374AC
	mov	r1, sb                                 @ 081374AE
	lsls	r0, r1, #0xc                          @ 081374B0
	ldr	r1, [r3, #0x48]                        @ 081374B2
	bl	swiDiv                                  @ 081374B4
	str	r0, [r4, #8]                           @ 081374B8  CH_step = (rate << 12) / ST_rateHz
	ldrb	r1, [r6, #0x14]                       @ 081374BA
	adds	r0, r4, #0                            @ 081374BC
	adds	r0, #0x7c                             @ 081374BE
	strh	r1, [r0]                              @ 081374C0
	ldrb	r0, [r6, #0x14]                       @ 081374C2
	cmp	r0, #0                                 @ 081374C4
	beq	.L081374DE                             @ 081374C6
	ldr	r0, [r6, #4]                           @ 081374C8
	lsls	r0, r0, #1                            @ 081374CA
	subs	r0, #0x40                             @ 081374CC
	str	r0, [r4, #0xc]                         @ 081374CE
	str	r7, [r4, #0x20]                        @ 081374D0
	str	r7, [r4, #0x24]                        @ 081374D2
	ldr	r0, [r4]                               @ 081374D4
	str	r0, [r4, #0x28]                        @ 081374D6
	movs	r0, #1                                @ 081374D8
	rsbs	r0, r0, #0                            @ 081374DA
	str	r0, [r4, #0x2c]                        @ 081374DC
.L081374DE:
	ldr	r0, .Llit0813750C                      @ 081374DE  =gmpPlayer
	ldr	r0, [r0]                               @ 081374E0
	ldr	r2, .Llit08137510                      @ 081374E2  =0x00000B94
	adds	r0, r0, r2                            @ 081374E4
	ldr	r0, [r0]                               @ 081374E6  PL_nMusic
	subs	r0, r5, r0                            @ 081374E8
.L081374EA:
	pop	{r3, r4, r5}                           @ 081374EA
	mov	r8, r3                                 @ 081374EC
	mov	sb, r4                                 @ 081374EE
	mov	sl, r5                                 @ 081374F0
	pop	{r4, r5, r6, r7}                       @ 081374F2
	pop	{r1}                                   @ 081374F4
	bx	r1                                      @ 081374F6
.Llit081374F8:
	.word	0x00000B9C                           @ 081374F8
.Llit081374FC:
	.word	0x00007FFF                           @ 081374FC
.Llit08137500:
	.word	gmpState                             @ 08137500
.Llit08137504:
	.word	0x00001BA4                           @ 08137504
.Llit08137508:
	.word	0x0000FFFF                           @ 08137508
.Llit0813750C:
	.word	gmpPlayer                            @ 0813750C
.Llit08137510:
	.word	0x00000B94                           @ 08137510
@ --------------------------------------------------------------------------
@ gmpPlaySfx(sfx, rate, sfxChannel, volume)  (0x08137514)
@   if (sfx >= ST_sfxCount) return -2; if (ch < 0) return -3; if (ch >= PL_nSfx) return -4;
@   e = sfxEntry[sfx] (24 bytes {offset, length, finetune, vol, loopStart, loopLen, rate, compressed});
@   if (!rate) rate = e.rate;
@   c = chan[PL_nMusic + ch]: CH_ptr = ST_sfxData + e.offset; CH_end = e.length << 12;
@     CH_loopStart = e.loopStart; CH_loopLen = e.loopLen << 12; CH_vol = CH_sfxVol = volume;
@     CH_fine = e.finetune; CH_note = 0xFFFF; CH_pos = 0; CH_step = (rate << 12) / ST_rateHz
@     if (e.compressed) { CH_end = e.length * 2 - 0x40; ADPCM state = 0 }   (no mixer decodes it)
@   return ch
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpPlaySfx
gmpPlaySfx:
	push	{r4, r5, r6, r7, lr}                  @ 08137514
	mov	r7, r8                                 @ 08137516
	push	{r7}                                  @ 08137518
	adds	r5, r0, #0                            @ 0813751A
	adds	r6, r1, #0                            @ 0813751C
	adds	r7, r2, #0                            @ 0813751E
	mov	ip, r3                                 @ 08137520
	ldr	r0, .Llit08137538                      @ 08137522  =gmpState
	ldr	r3, [r0]                               @ 08137524
	ldr	r1, .Llit0813753C                      @ 08137526  =0x00001BB8
	adds	r0, r3, r1                            @ 08137528
	ldr	r0, [r0]                               @ 0813752A  ST_sfxCount
	cmp	r5, r0                                 @ 0813752C
	blo	.L08137540                             @ 0813752E
	movs	r0, #2                                @ 08137530
	rsbs	r0, r0, #0                            @ 08137532
	b	.L0813760A                               @ 08137534
	.hword	0x0000                              @ 08137536  (padding)
.Llit08137538:
	.word	gmpState                             @ 08137538
.Llit0813753C:
	.word	0x00001BB8                           @ 0813753C
.L08137540:
	cmp	r7, #0                                 @ 08137540
	bge	.L0813754A                             @ 08137542
	movs	r0, #3                                @ 08137544
	rsbs	r0, r0, #0                            @ 08137546
	b	.L0813760A                               @ 08137548
.L0813754A:
	ldr	r0, .Llit08137560                      @ 0813754A  =gmpPlayer
	ldr	r2, [r0]                               @ 0813754C
	ldr	r1, .Llit08137564                      @ 0813754E  =0x00000B98
	adds	r0, r2, r1                            @ 08137550
	ldr	r0, [r0]                               @ 08137552  PL_nSfx
	cmp	r7, r0                                 @ 08137554
	blt	.L08137568                             @ 08137556
	movs	r0, #4                                @ 08137558
	rsbs	r0, r0, #0                            @ 0813755A
	b	.L0813760A                               @ 0813755C
	.hword	0x0000                              @ 0813755E  (padding)
.Llit08137560:
	.word	gmpPlayer                            @ 08137560
.Llit08137564:
	.word	0x00000B98                           @ 08137564
.L08137568:
	ldr	r1, .Llit08137614                      @ 08137568  =0x00000B94
	adds	r0, r2, r1                            @ 0813756A
	ldr	r0, [r0]                               @ 0813756C
	adds	r0, r0, r7                            @ 0813756E
	movs	r1, #0x98                             @ 08137570
	muls	r0, r1, r0                            @ 08137572
	adds	r0, #0x54                             @ 08137574
	adds	r4, r2, r0                            @ 08137576
	adds	r0, r4, #0                            @ 08137578
	adds	r0, #0x40                             @ 0813757A
	movs	r1, #0                                @ 0813757C
	mov	r8, r1                                 @ 0813757E
	strh	r5, [r0]                              @ 08137580
	movs	r0, #0xdd                             @ 08137582
	lsls	r0, r0, #5                            @ 08137584
	adds	r1, r3, r0                            @ 08137586
	lsls	r0, r5, #1                            @ 08137588
	adds	r0, r0, r5                            @ 0813758A
	lsls	r0, r0, #3                            @ 0813758C
	ldr	r1, [r1]                               @ 0813758E
	adds	r5, r1, r0                            @ 08137590
	cmp	r6, #0                                 @ 08137592
	bne	.L08137598                             @ 08137594
	ldr	r6, [r5, #0x10]                        @ 08137596
.L08137598:
	ldr	r1, .Llit08137618                      @ 08137598  =0x00001BA4
	adds	r0, r3, r1                            @ 0813759A
	ldr	r0, [r0]                               @ 0813759C
	ldr	r1, [r5]                               @ 0813759E
	adds	r0, r0, r1                            @ 081375A0
	str	r0, [r4]                               @ 081375A2
	ldr	r0, [r5, #4]                           @ 081375A4
	lsls	r0, r0, #0xc                          @ 081375A6
	str	r0, [r4, #0xc]                         @ 081375A8
	ldrh	r0, [r5, #0xc]                        @ 081375AA
	str	r0, [r4, #0x10]                        @ 081375AC
	ldrh	r0, [r5, #0xe]                        @ 081375AE
	lsls	r0, r0, #0xc                          @ 081375B0
	str	r0, [r4, #0x14]                        @ 081375B2
	mov	r0, ip                                 @ 081375B4
	str	r0, [r4, #0x18]                        @ 081375B6
	str	r0, [r4, #0x1c]                        @ 081375B8
	ldrh	r0, [r5, #8]                          @ 081375BA
	adds	r1, r4, #0                            @ 081375BC
	adds	r1, #0x44                             @ 081375BE
	strh	r0, [r1]                              @ 081375C0
	adds	r2, r4, #0                            @ 081375C2
	adds	r2, #0x46                             @ 081375C4
	ldr	r0, .Llit0813761C                      @ 081375C6  =0x0000FFFF
	strh	r0, [r2]                              @ 081375C8
	mov	r0, r8                                 @ 081375CA
	str	r0, [r4, #4]                           @ 081375CC
	strh	r0, [r1]                              @ 081375CE
	adds	r0, r4, #0                            @ 081375D0
	adds	r0, #0x54                             @ 081375D2
	mov	r1, r8                                 @ 081375D4
	strh	r1, [r0]                              @ 081375D6
	lsls	r0, r6, #0xc                          @ 081375D8
	ldr	r1, [r3, #0x48]                        @ 081375DA
	bl	swiDiv                                  @ 081375DC
	str	r0, [r4, #8]                           @ 081375E0  CH_step = (rate << 12) / ST_rateHz
	ldrb	r1, [r5, #0x14]                       @ 081375E2
	adds	r0, r4, #0                            @ 081375E4
	adds	r0, #0x7c                             @ 081375E6
	strh	r1, [r0]                              @ 081375E8
	ldrb	r0, [r5, #0x14]                       @ 081375EA
	cmp	r0, #0                                 @ 081375EC
	beq	.L08137608                             @ 081375EE
	ldr	r0, [r5, #4]                           @ 081375F0
	lsls	r0, r0, #1                            @ 081375F2
	subs	r0, #0x40                             @ 081375F4
	str	r0, [r4, #0xc]                         @ 081375F6
	mov	r0, r8                                 @ 081375F8
	str	r0, [r4, #0x20]                        @ 081375FA
	str	r0, [r4, #0x24]                        @ 081375FC
	ldr	r0, [r4]                               @ 081375FE
	str	r0, [r4, #0x28]                        @ 08137600
	movs	r0, #1                                @ 08137602
	rsbs	r0, r0, #0                            @ 08137604
	str	r0, [r4, #0x2c]                        @ 08137606
.L08137608:
	adds	r0, r7, #0                            @ 08137608
.L0813760A:
	pop	{r3}                                   @ 0813760A
	mov	r8, r3                                 @ 0813760C
	pop	{r4, r5, r6, r7}                       @ 0813760E
	pop	{r1}                                   @ 08137610
	bx	r1                                      @ 08137612
.Llit08137614:
	.word	0x00000B94                           @ 08137614
.Llit08137618:
	.word	0x00001BA4                           @ 08137618
.Llit0813761C:
	.word	0x0000FFFF                           @ 0813761C
@ --------------------------------------------------------------------------
@ gmpSetSfx(sfxChannel, rate, volume)  (0x08137620)
@   Change volume (and the rate, if non-zero) of a playing effect.  Bound is "index <= 11",
@   so it can also reach music channels.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpSetSfx
gmpSetSfx:
	push	{r4, r5, lr}                          @ 08137620
	adds	r3, r0, #0                            @ 08137622
	ldr	r0, .Llit08137658                      @ 08137624  =gmpPlayer
	ldr	r4, [r0]                               @ 08137626
	ldr	r5, .Llit0813765C                      @ 08137628  =0x00000B94
	adds	r0, r4, r5                            @ 0813762A
	ldr	r0, [r0]                               @ 0813762C  PL_nMusic
	adds	r3, r3, r0                            @ 0813762E
	cmp	r3, #0xb                               @ 08137630
	bhi	.L08137652                             @ 08137632
	movs	r0, #0x98                             @ 08137634
	muls	r0, r3, r0                            @ 08137636
	adds	r0, #0x54                             @ 08137638
	adds	r4, r4, r0                            @ 0813763A
	str	r2, [r4, #0x18]                        @ 0813763C
	str	r2, [r4, #0x1c]                        @ 0813763E
	cmp	r1, #0                                 @ 08137640
	beq	.L08137652                             @ 08137642
	lsls	r0, r1, #0xc                          @ 08137644
	ldr	r1, .Llit08137660                      @ 08137646  =gmpState
	ldr	r1, [r1]                               @ 08137648
	ldr	r1, [r1, #0x48]                        @ 0813764A  ST_rateHz
	bl	swiDiv                                  @ 0813764C
	str	r0, [r4, #8]                           @ 08137650
.L08137652:
	pop	{r4, r5}                               @ 08137652
	pop	{r0}                                   @ 08137654
	bx	r0                                      @ 08137656
.Llit08137658:
	.word	gmpPlayer                            @ 08137658
.Llit0813765C:
	.word	0x00000B94                           @ 0813765C
.Llit08137660:
	.word	gmpState                             @ 08137660
@ --------------------------------------------------------------------------
@ gmpStopSfx(sfxChannel)  (0x08137664)
@   CH_vol = CH_sfxVol = 0
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpStopSfx
gmpStopSfx:
	adds	r1, r0, #0                            @ 08137664
	ldr	r0, .Llit0813768C                      @ 08137666  =gmpPlayer
	ldr	r2, [r0]                               @ 08137668
	ldr	r3, .Llit08137690                      @ 0813766A  =0x00000B94
	adds	r0, r2, r3                            @ 0813766C
	ldr	r0, [r0]                               @ 0813766E  PL_nMusic
	adds	r1, r1, r0                            @ 08137670
	adds	r3, #8                                @ 08137672
	adds	r0, r2, r3                            @ 08137674
	ldr	r0, [r0]                               @ 08137676  PL_nChan
	cmp	r1, r0                                 @ 08137678
	bhs	.L0813768A                             @ 0813767A
	movs	r0, #0x98                             @ 0813767C
	muls	r0, r1, r0                            @ 0813767E
	adds	r0, #0x54                             @ 08137680
	adds	r0, r2, r0                            @ 08137682
	movs	r1, #0                                @ 08137684
	str	r1, [r0, #0x18]                        @ 08137686
	str	r1, [r0, #0x1c]                        @ 08137688
.L0813768A:
	bx	lr                                      @ 0813768A
.Llit0813768C:
	.word	gmpPlayer                            @ 0813768C
.Llit08137690:
	.word	0x00000B94                           @ 08137690
@ --------------------------------------------------------------------------
@ gmpClearSfxVol(sfxChannel)  (0x08137694)  -- unused
@   CH_sfxVol = 0
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpClearSfxVol
gmpClearSfxVol:
	adds	r1, r0, #0                            @ 08137694
	ldr	r0, .Llit081376B8                      @ 08137696  =gmpPlayer
	ldr	r2, [r0]                               @ 08137698
	ldr	r3, .Llit081376BC                      @ 0813769A  =0x00000B94
	adds	r0, r2, r3                            @ 0813769C
	ldr	r0, [r0]                               @ 0813769E  PL_nMusic
	adds	r1, r1, r0                            @ 081376A0
	adds	r3, #8                                @ 081376A2
	adds	r0, r2, r3                            @ 081376A4
	ldr	r0, [r0]                               @ 081376A6  PL_nChan
	cmp	r1, r0                                 @ 081376A8
	bhs	.L081376B6                             @ 081376AA
	movs	r0, #0x98                             @ 081376AC
	muls	r0, r1, r0                            @ 081376AE
	adds	r0, r0, r2                            @ 081376B0
	movs	r1, #0                                @ 081376B2
	str	r1, [r0, #0x70]                        @ 081376B4
.L081376B6:
	bx	lr                                      @ 081376B6
.Llit081376B8:
	.word	gmpPlayer                            @ 081376B8
.Llit081376BC:
	.word	0x00000B94                           @ 081376BC
@ --------------------------------------------------------------------------
@ gmpSfxPlaying(sfxChannel)  (0x081376C0)
@   return chan[nMusic + ch].CH_end > 2
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpSfxPlaying
gmpSfxPlaying:
	adds	r1, r0, #0                            @ 081376C0
	ldr	r0, .Llit081376E8                      @ 081376C2  =gmpPlayer
	ldr	r2, [r0]                               @ 081376C4
	ldr	r3, .Llit081376EC                      @ 081376C6  =0x00000B94
	adds	r0, r2, r3                            @ 081376C8
	ldr	r0, [r0]                               @ 081376CA  PL_nMusic
	adds	r1, r1, r0                            @ 081376CC
	cmp	r1, #0xb                               @ 081376CE
	bhi	.L081376E2                             @ 081376D0
	movs	r0, #0x98                             @ 081376D2
	muls	r1, r0, r1                            @ 081376D4
	adds	r0, r2, #0                            @ 081376D6
	adds	r0, #0x60                             @ 081376D8
	adds	r0, r0, r1                            @ 081376DA
	ldr	r0, [r0]                               @ 081376DC
	cmp	r0, #2                                 @ 081376DE
	bhi	.L081376F0                             @ 081376E0
.L081376E2:
	movs	r0, #0                                @ 081376E2
	b	.L081376F2                               @ 081376E4
	.hword	0x0000                              @ 081376E6  (padding)
.Llit081376E8:
	.word	gmpPlayer                            @ 081376E8
.Llit081376EC:
	.word	0x00000B94                           @ 081376EC
.L081376F0:
	movs	r0, #1                                @ 081376F0
.L081376F2:
	bx	lr                                      @ 081376F2
@ --------------------------------------------------------------------------
@ fxVolumeSlide(ch)  (0x081376F4)
@   if (PL_tick) CH_vol += CH_vsUp ? CH_vsUp : -CH_vsDown;  clamp 0..64
@ --------------------------------------------------------------------------
	.thumb_func
	.global fxVolumeSlide
fxVolumeSlide:
	push	{r4, lr}                              @ 081376F4
	adds	r1, r0, #0                            @ 081376F6
	adds	r0, #0x4c                             @ 081376F8
	ldrh	r2, [r0]                              @ 081376FA  CH_vsUp
	adds	r0, #2                                @ 081376FC
	ldrh	r3, [r0]                              @ 081376FE  CH_vsDown
	ldr	r0, .Llit08137718                      @ 08137700  =gmpPlayer
	ldr	r0, [r0]                               @ 08137702
	movs	r4, #0x38                             @ 08137704
	ldrsh	r0, [r0, r4]                         @ 08137706  PL_tick
	cmp	r0, #0                                 @ 08137708
	beq	.L08137722                             @ 0813770A
	cmp	r2, #0                                 @ 0813770C
	beq	.L0813771C                             @ 0813770E
	ldr	r0, [r1, #0x18]                        @ 08137710  CH_vol
	adds	r0, r0, r2                            @ 08137712
	b	.L08137720                               @ 08137714
	.hword	0x0000                              @ 08137716  (padding)
.Llit08137718:
	.word	gmpPlayer                            @ 08137718
.L0813771C:
	ldr	r0, [r1, #0x18]                        @ 0813771C
	subs	r0, r0, r3                            @ 0813771E
.L08137720:
	str	r0, [r1, #0x18]                        @ 08137720
.L08137722:
	ldr	r0, [r1, #0x18]                        @ 08137722
	cmp	r0, #0                                 @ 08137724
	bge	.L0813772C                             @ 08137726
	movs	r0, #0                                @ 08137728
	str	r0, [r1, #0x18]                        @ 0813772A
.L0813772C:
	ldr	r0, [r1, #0x18]                        @ 0813772C
	cmp	r0, #0x40                              @ 0813772E
	ble	.L08137736                             @ 08137730
	movs	r0, #0x40                             @ 08137732
	str	r0, [r1, #0x18]                        @ 08137734
.L08137736:
	pop	{r4}                                   @ 08137736
	pop	{r0}                                   @ 08137738
	bx	r0                                      @ 0813773A
@ --------------------------------------------------------------------------
@ fxTonePorta(ch)  (0x0813773C)
@   Amiga mode: CH_portaOfs += CH_portaStep; stop when the period passes the target period.
@   Linear mode: move CH_linPorta towards CH_tpTargetLin by CH_tpSpeed*4; on arrival
@                CH_note = target, CH_linPorta = 0.  Then gmpUpdateLinearStep.
@ --------------------------------------------------------------------------
	.thumb_func
	.global fxTonePorta
fxTonePorta:
	push	{r4, r5, r6, r7, lr}                  @ 0813773C
	mov	r7, sb                                 @ 0813773E
	mov	r6, r8                                 @ 08137740
	push	{r6, r7}                              @ 08137742
	mov	ip, r0                                 @ 08137744
	mov	r6, ip                                 @ 08137746
	adds	r6, #0x94                             @ 08137748
	ldr	r1, [r6]                               @ 0813774A  CH_tpTargetLin
	cmp	r1, #0                                 @ 0813774C
	bne	.L08137752                             @ 0813774E
	b	.L0813785A                               @ 08137750
.L08137752:
	ldr	r0, .Llit081377A4                      @ 08137752  =gmpPlayer
	ldr	r0, [r0]                               @ 08137754
	ldr	r7, [r0, #4]                           @ 08137756  PL_amiga
	cmp	r7, #0                                 @ 08137758
	beq	.L081377E8                             @ 0813775A
	mov	r4, ip                                 @ 0813775C
	adds	r4, #0x5e                             @ 0813775E
	mov	r5, ip                                 @ 08137760
	adds	r5, #0x62                             @ 08137762
	ldrh	r0, [r5]                              @ 08137764
	ldrh	r1, [r4]                              @ 08137766
	adds	r0, r0, r1                            @ 08137768
	movs	r7, #0                                @ 0813776A
	strh	r0, [r4]                              @ 0813776C
	movs	r2, #0                                @ 0813776E
	ldrsh	r0, [r5, r2]                         @ 08137770
	cmp	r0, #0                                 @ 08137772
	ble	.L081377AC                             @ 08137774
	ldr	r0, .Llit081377A8                      @ 08137776  =gmpState
	ldr	r1, [r0]                               @ 08137778
	movs	r6, #0x46                             @ 0813777A
	add	r6, ip                                 @ 0813777C
	mov	r8, r6                                 @ 0813777E
	ldrh	r0, [r6]                              @ 08137780
	ldr	r3, [r1, #0x28]                        @ 08137782  ST_stepTab
	lsls	r0, r0, #2                            @ 08137784
	adds	r0, r0, r3                            @ 08137786
	movs	r1, #0                                @ 08137788
	ldrsh	r2, [r4, r1]                         @ 0813778A
	ldr	r1, [r0]                               @ 0813778C
	adds	r1, r1, r2                            @ 0813778E
	mov	r2, ip                                 @ 08137790
	adds	r2, #0x64                             @ 08137792
	movs	r6, #0                                @ 08137794
	ldrsh	r0, [r2, r6]                         @ 08137796
	lsls	r0, r0, #2                            @ 08137798
	adds	r0, r0, r3                            @ 0813779A
	ldr	r0, [r0]                               @ 0813779C
	cmp	r1, r0                                 @ 0813779E
	blo	.L0813785A                             @ 081377A0
	b	.L081377D8                               @ 081377A2
.Llit081377A4:
	.word	gmpPlayer                            @ 081377A4
.Llit081377A8:
	.word	gmpState                             @ 081377A8
.L081377AC:
	ldr	r0, .Llit081377E4                      @ 081377AC  =gmpState
	ldr	r1, [r0]                               @ 081377AE
	movs	r2, #0x46                             @ 081377B0
	add	r2, ip                                 @ 081377B2
	mov	r8, r2                                 @ 081377B4
	ldrh	r0, [r2]                              @ 081377B6
	ldr	r3, [r1, #0x28]                        @ 081377B8  ST_stepTab
	lsls	r0, r0, #2                            @ 081377BA
	adds	r0, r0, r3                            @ 081377BC
	movs	r6, #0                                @ 081377BE
	ldrsh	r2, [r4, r6]                         @ 081377C0
	ldr	r1, [r0]                               @ 081377C2
	adds	r1, r1, r2                            @ 081377C4
	mov	r2, ip                                 @ 081377C6
	adds	r2, #0x64                             @ 081377C8
	movs	r6, #0                                @ 081377CA
	ldrsh	r0, [r2, r6]                         @ 081377CC
	lsls	r0, r0, #2                            @ 081377CE
	adds	r0, r0, r3                            @ 081377D0
	ldr	r0, [r0]                               @ 081377D2
	cmp	r1, r0                                 @ 081377D4
	bhi	.L0813785A                             @ 081377D6
.L081377D8:
	ldrh	r0, [r2]                              @ 081377D8
	mov	r1, r8                                 @ 081377DA
	strh	r0, [r1]                              @ 081377DC
	strh	r7, [r5]                              @ 081377DE
	strh	r7, [r4]                              @ 081377E0
	b	.L0813785A                               @ 081377E2
.Llit081377E4:
	.word	gmpState                             @ 081377E4
.L081377E8:
	mov	r5, ip                                 @ 081377E8
	adds	r5, #0x46                             @ 081377EA
	ldrh	r0, [r5]                              @ 081377EC
	mov	r4, ip                                 @ 081377EE
	adds	r4, #0x80                             @ 081377F0
	ldr	r3, [r4]                               @ 081377F2
	adds	r0, r0, r3                            @ 081377F4
	subs	r1, r0, r1                            @ 081377F6
	mov	r8, r5                                 @ 081377F8
	mov	sb, r4                                 @ 081377FA
	cmp	r1, #0                                 @ 081377FC
	beq	.L08137816                             @ 081377FE
	mov	r0, ip                                 @ 08137800
	adds	r0, #0x60                             @ 08137802
	movs	r2, #0                                @ 08137804
	ldrsh	r0, [r0, r2]                         @ 08137806
	lsls	r0, r0, #2                            @ 08137808
	adds	r2, r1, #0                            @ 0813780A
	cmp	r1, #0                                 @ 0813780C
	bge	.L08137812                             @ 0813780E
	rsbs	r2, r1, #0                            @ 08137810
.L08137812:
	cmp	r0, r2                                 @ 08137812
	ble	.L0813782C                             @ 08137814
.L08137816:
	mov	r2, ip                                 @ 08137816
	adds	r2, #0x94                             @ 08137818
	mov	r6, r8                                 @ 0813781A
	ldrh	r1, [r6]                              @ 0813781C
	ldr	r0, [r2]                               @ 0813781E
	subs	r0, r0, r1                            @ 08137820
	mov	r1, sb                                 @ 08137822
	str	r0, [r1]                               @ 08137824
	movs	r0, #0                                @ 08137826
	str	r0, [r2]                               @ 08137828
	b	.L08137854                               @ 0813782A
.L0813782C:
	cmp	r1, #0                                 @ 0813782C
	ble	.L08137840                             @ 0813782E
	subs	r0, r3, r0                            @ 08137830
	str	r0, [r4]                               @ 08137832
	ldrh	r2, [r5]                              @ 08137834
	adds	r0, r2, r0                            @ 08137836
	ldr	r1, [r6]                               @ 08137838
	cmp	r0, r1                                 @ 0813783A
	bgt	.L08137854                             @ 0813783C
	b	.L0813784E                               @ 0813783E
.L08137840:
	adds	r0, r3, r0                            @ 08137840
	str	r0, [r4]                               @ 08137842
	ldrh	r2, [r5]                              @ 08137844
	adds	r0, r2, r0                            @ 08137846
	ldr	r1, [r6]                               @ 08137848
	cmp	r0, r1                                 @ 0813784A
	blt	.L08137854                             @ 0813784C
.L0813784E:
	subs	r0, r1, r2                            @ 0813784E
	str	r0, [r4]                               @ 08137850
	str	r7, [r6]                               @ 08137852
.L08137854:
	mov	r0, ip                                 @ 08137854
	bl	gmpUpdateLinearStep                     @ 08137856
.L0813785A:
	pop	{r3, r4}                               @ 0813785A
	mov	r8, r3                                 @ 0813785C
	mov	sb, r4                                 @ 0813785E
	pop	{r4, r5, r6, r7}                       @ 08137860
	pop	{r0}                                   @ 08137862
	bx	r0                                      @ 08137864
	.hword	0x0000                              @ 08137866  (padding)
@ --------------------------------------------------------------------------
@ fxVibrato(ch)  (0x08137868)
@   Amiga: CH_vibOfs = sine[CH_vibPos] * depth >> 7 (only the positive half: no sign handling);
@          CH_vibPos = (CH_vibPos + speed) & 63.  Index CH_vibPos goes up to 63 but the table has
@          32 entries, so positions 32..63 read the next 32 bytes of ROM (gmpLinearFreq).
@   Linear: v = sine[(pos >> 2) & 31] * depth >> 5, negated for pos > 31;
@           pos = (pos + (speed + 4) / 2) & 63; gmpUpdateLinearStep
@ --------------------------------------------------------------------------
	.thumb_func
	.global fxVibrato
fxVibrato:
	push	{r4, lr}                              @ 08137868
	mov	ip, r0                                 @ 0813786A
	ldr	r0, .Llit081378A4                      @ 0813786C  =gmpPlayer
	ldr	r0, [r0]                               @ 0813786E
	ldr	r0, [r0, #4]                           @ 08137870  PL_amiga
	cmp	r0, #0                                 @ 08137872
	beq	.L081378AC                             @ 08137874
	mov	r0, ip                                 @ 08137876
	adds	r0, #0x56                             @ 08137878
	ldrh	r2, [r0]                              @ 0813787A  CH_vibDepth
	ldr	r1, .Llit081378A8                      @ 0813787C  =gmpVibratoSine
	mov	r3, ip                                 @ 0813787E
	adds	r3, #0x5a                             @ 08137880
	ldrh	r0, [r3]                              @ 08137882  CH_vibPos
	adds	r0, r0, r1                            @ 08137884
	ldrb	r0, [r0]                              @ 08137886
	muls	r0, r2, r0                            @ 08137888
	asrs	r0, r0, #7                            @ 0813788A
	mov	r1, ip                                 @ 0813788C
	adds	r1, #0x54                             @ 0813788E
	strh	r0, [r1]                              @ 08137890  CH_vibOfs
	mov	r0, ip                                 @ 08137892
	adds	r0, #0x58                             @ 08137894
	ldrh	r0, [r0]                              @ 08137896  CH_vibSpeed
	ldrh	r1, [r3]                              @ 08137898  CH_vibPos
	adds	r0, r0, r1                            @ 0813789A
	movs	r1, #0x3f                             @ 0813789C
	ands	r0, r1                                @ 0813789E
	strh	r0, [r3]                              @ 081378A0  CH_vibPos
	b	.L08137900                               @ 081378A2
.Llit081378A4:
	.word	gmpPlayer                            @ 081378A4
.Llit081378A8:
	.word	gmpVibratoSine                       @ 081378A8
.L081378AC:
	mov	r2, ip                                 @ 081378AC
	adds	r2, #0x5a                             @ 081378AE
	ldrh	r0, [r2]                              @ 081378B0
	lsls	r0, r0, #0x10                         @ 081378B2
	lsrs	r3, r0, #0x10                         @ 081378B4
	lsrs	r0, r0, #0x12                         @ 081378B6
	movs	r1, #0x1f                             @ 081378B8
	ands	r0, r1                                @ 081378BA
	ldr	r1, .Llit081378DC                      @ 081378BC  =gmpVibratoSine
	adds	r0, r0, r1                            @ 081378BE
	ldrb	r4, [r0]                              @ 081378C0
	mov	r0, ip                                 @ 081378C2
	adds	r0, #0x56                             @ 081378C4
	ldrh	r0, [r0]                              @ 081378C6
	muls	r4, r0, r4                            @ 081378C8
	asrs	r4, r4, #5                            @ 081378CA
	cmp	r3, #0x1f                              @ 081378CC
	bls	.L081378E0                             @ 081378CE
	mov	r1, ip                                 @ 081378D0
	adds	r1, #0x84                             @ 081378D2
	rsbs	r0, r4, #0                            @ 081378D4
	str	r0, [r1]                               @ 081378D6
	b	.L081378E6                               @ 081378D8
	.hword	0x0000                              @ 081378DA  (padding)
.Llit081378DC:
	.word	gmpVibratoSine                       @ 081378DC
.L081378E0:
	mov	r0, ip                                 @ 081378E0
	adds	r0, #0x84                             @ 081378E2
	str	r4, [r0]                               @ 081378E4
.L081378E6:
	mov	r0, ip                                 @ 081378E6
	adds	r0, #0x58                             @ 081378E8
	ldrh	r0, [r0]                              @ 081378EA
	adds	r0, #4                                @ 081378EC
	lsrs	r0, r0, #1                            @ 081378EE
	ldrh	r1, [r2]                              @ 081378F0
	adds	r0, r0, r1                            @ 081378F2
	movs	r1, #0x3f                             @ 081378F4
	ands	r0, r1                                @ 081378F6
	strh	r0, [r2]                              @ 081378F8
	mov	r0, ip                                 @ 081378FA
	bl	gmpUpdateLinearStep                     @ 081378FC
.L08137900:
	pop	{r4}                                   @ 08137900
	pop	{r0}                                   @ 08137902
	bx	r0                                      @ 08137904
	.hword	0x0000                              @ 08137906  (padding)
@ --------------------------------------------------------------------------
@ fxPortaDownLin(tick, ch, param)  (0x08137908)
@   Linear-period portamento down (period up), S3M style.  param 0 reuses CH_portaMem.
@     FFx on tick 0: CH_linPorta += x*4;  EEx on tick 0: += x;
@     any other xx on ticks != 0: += xx*4.  The row handler calls it with PL_tick = 0,
@     so fine slides happen on the row and normal slides on the following ticks.
@ --------------------------------------------------------------------------
	.thumb_func
	.global fxPortaDownLin
fxPortaDownLin:
	push	{r4, r5, lr}                          @ 08137908
	adds	r4, r0, #0                            @ 0813790A
	mov	ip, r1                                 @ 0813790C
	adds	r3, r2, #0                            @ 0813790E
	cmp	r3, #0                                 @ 08137910
	beq	.L0813791C                             @ 08137912
	mov	r0, ip                                 @ 08137914
	adds	r0, #0x88                             @ 08137916
	str	r3, [r0]                               @ 08137918  CH_portaMem
	b	.L08137922                               @ 0813791A
.L0813791C:
	mov	r0, ip                                 @ 0813791C
	adds	r0, #0x88                             @ 0813791E
	ldr	r3, [r0]                               @ 08137920
.L08137922:
	lsrs	r0, r3, #4                            @ 08137922
	lsls	r0, r0, #0x18                         @ 08137924
	lsrs	r2, r0, #0x18                         @ 08137926
	movs	r0, #0xf                              @ 08137928
	adds	r1, r3, #0                            @ 0813792A
	ands	r1, r0                                @ 0813792C
	adds	r5, r1, #0                            @ 0813792E
	cmp	r2, #0xf                               @ 08137930
	bne	.L08137940                             @ 08137932
	cmp	r4, #0                                 @ 08137934
	bne	.L08137966                             @ 08137936
	mov	r2, ip                                 @ 08137938
	adds	r2, #0x80                             @ 0813793A
	lsls	r1, r1, #2                            @ 0813793C
	b	.L08137960                               @ 0813793E
.L08137940:
	cmp	r2, #0xe                               @ 08137940
	bne	.L08137954                             @ 08137942
	cmp	r4, #0                                 @ 08137944
	bne	.L08137966                             @ 08137946
	mov	r1, ip                                 @ 08137948
	adds	r1, #0x80                             @ 0813794A
	ldr	r0, [r1]                               @ 0813794C
	adds	r0, r0, r5                            @ 0813794E
	str	r0, [r1]                               @ 08137950
	b	.L08137966                               @ 08137952
.L08137954:
	cmp	r4, #0                                 @ 08137954
	beq	.L08137966                             @ 08137956
	mov	r2, ip                                 @ 08137958
	adds	r2, #0x80                             @ 0813795A
	lsls	r1, r3, #0x10                         @ 0813795C
	lsrs	r1, r1, #0xe                          @ 0813795E
.L08137960:
	ldr	r0, [r2]                               @ 08137960
	adds	r0, r0, r1                            @ 08137962
	str	r0, [r2]                               @ 08137964
.L08137966:
	pop	{r4, r5}                               @ 08137966
	pop	{r0}                                   @ 08137968
	bx	r0                                      @ 0813796A
@ --------------------------------------------------------------------------
@ fxPortaUpLin(tick, ch, param)  (0x0813796C)
@   Mirror of fxPortaDownLin: subtracts from CH_linPorta (period down = pitch up).
@ --------------------------------------------------------------------------
	.thumb_func
	.global fxPortaUpLin
fxPortaUpLin:
	push	{r4, r5, lr}                          @ 0813796C
	adds	r4, r0, #0                            @ 0813796E
	mov	ip, r1                                 @ 08137970
	adds	r3, r2, #0                            @ 08137972
	cmp	r3, #0                                 @ 08137974
	beq	.L08137980                             @ 08137976
	mov	r0, ip                                 @ 08137978
	adds	r0, #0x88                             @ 0813797A
	str	r3, [r0]                               @ 0813797C  CH_portaMem
	b	.L08137986                               @ 0813797E
.L08137980:
	mov	r0, ip                                 @ 08137980
	adds	r0, #0x88                             @ 08137982
	ldr	r3, [r0]                               @ 08137984
.L08137986:
	lsrs	r0, r3, #4                            @ 08137986
	lsls	r0, r0, #0x18                         @ 08137988
	lsrs	r2, r0, #0x18                         @ 0813798A
	movs	r0, #0xf                              @ 0813798C
	adds	r1, r3, #0                            @ 0813798E
	ands	r1, r0                                @ 08137990
	adds	r5, r1, #0                            @ 08137992
	cmp	r2, #0xf                               @ 08137994
	bne	.L081379A4                             @ 08137996
	cmp	r4, #0                                 @ 08137998
	bne	.L081379CA                             @ 0813799A
	mov	r2, ip                                 @ 0813799C
	adds	r2, #0x80                             @ 0813799E
	lsls	r1, r1, #2                            @ 081379A0
	b	.L081379C4                               @ 081379A2
.L081379A4:
	cmp	r2, #0xe                               @ 081379A4
	bne	.L081379B8                             @ 081379A6
	cmp	r4, #0                                 @ 081379A8
	bne	.L081379CA                             @ 081379AA
	mov	r1, ip                                 @ 081379AC
	adds	r1, #0x80                             @ 081379AE
	ldr	r0, [r1]                               @ 081379B0
	subs	r0, r0, r5                            @ 081379B2
	str	r0, [r1]                               @ 081379B4
	b	.L081379CA                               @ 081379B6
.L081379B8:
	cmp	r4, #0                                 @ 081379B8
	beq	.L081379CA                             @ 081379BA
	mov	r2, ip                                 @ 081379BC
	adds	r2, #0x80                             @ 081379BE
	lsls	r1, r3, #0x10                         @ 081379C0
	lsrs	r1, r1, #0xe                          @ 081379C2
.L081379C4:
	ldr	r0, [r2]                               @ 081379C4
	subs	r0, r0, r1                            @ 081379C6
	str	r0, [r2]                               @ 081379C8
.L081379CA:
	pop	{r4, r5}                               @ 081379CA
	pop	{r0}                                   @ 081379CC
	bx	r0                                      @ 081379CE
@ --------------------------------------------------------------------------
@ fxVolumeColumn(ch)  (0x081379D0)
@   if (CH_volCol) CH_vol = CH_volCol - 1
@ --------------------------------------------------------------------------
	.thumb_func
	.global fxVolumeColumn
fxVolumeColumn:
	adds	r1, r0, #0                            @ 081379D0
	adds	r0, #0x8c                             @ 081379D2
	ldr	r0, [r0]                               @ 081379D4  CH_volCol
	cmp	r0, #0                                 @ 081379D6
	beq	.L081379DE                             @ 081379D8
	subs	r0, #1                                @ 081379DA
	str	r0, [r1, #0x18]                        @ 081379DC  CH_vol
.L081379DE:
	bx	lr                                      @ 081379DE
@ --------------------------------------------------------------------------
@ gmpProcessTick()  (0x081379E0)
@   if (!ST_playing) return;
@   for each music channel: switch (CH_tickFx) {        (jump table at 0x08137A38)
@     0 arpeggio:  if (PL_arpTick && (arpX|arpY)) { if (PL_arpTick == 4) PL_arpTick = 1;
@                  recompute the step of the *base* note }   -- arpX/arpY are never added:
@                  arpeggio has no audible effect in this version
@     1 porta up:  Amiga: CH_portaOfs += CH_portaStep (set to -xx by the row), else fxPortaUpLin
@     2 porta dn:  Amiga: CH_portaOfs += CH_portaStep (+xx), else fxPortaDownLin
@     (Amiga-mode slides run on every tick, the row tick included)
@     3 fxTonePorta  4 fxVibrato  5 tone porta + vol slide  6 vibrato + vol slide  0xA fxVolumeSlide }
@     Amiga mode, no arpeggio: step = (0x6C3E1D / (period[note+fine] + portaOfs + vibOfs)*2 << 12) / rate
@     (or the precomputed ST_stepTab[note] when all offsets are 0); then fxVolumeColumn
@   PL_tick++; PL_arpTick++
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpProcessTick
gmpProcessTick:
	push	{r4, r5, r6, r7, lr}                  @ 081379E0
	mov	r7, r8                                 @ 081379E2
	push	{r7}                                  @ 081379E4
	sub	sp, #4                                 @ 081379E6
	ldr	r0, .Llit08137A08                      @ 081379E8  =gmpState
	ldr	r0, [r0]                               @ 081379EA
	ldr	r1, .Llit08137A0C                      @ 081379EC  =0x00001BBC
	adds	r0, r0, r1                            @ 081379EE
	movs	r2, #0                                @ 081379F0
	ldrsh	r0, [r0, r2]                         @ 081379F2  ST_playing
	cmp	r0, #0                                 @ 081379F4
	bne	.L081379FA                             @ 081379F6
	b	.L08137C74                               @ 081379F8
.L081379FA:
	ldr	r0, .Llit08137A10                      @ 081379FA  =gmpPlayer
	ldr	r0, [r0]                               @ 081379FC
	adds	r4, r0, #0                            @ 081379FE
	adds	r4, #0x54                             @ 08137A00
	movs	r3, #0                                @ 08137A02
	mov	r8, r3                                 @ 08137A04
	b	.L08137C58                               @ 08137A06
.Llit08137A08:
	.word	gmpState                             @ 08137A08
.Llit08137A0C:
	.word	0x00001BBC                           @ 08137A0C
.Llit08137A10:
	.word	gmpPlayer                            @ 08137A10
.L08137A14:
	ldr	r0, [r4, #0x48]                        @ 08137A14
	adds	r7, r4, #0                            @ 08137A16
	adds	r7, #0x50                             @ 08137A18
	adds	r6, r4, #0                            @ 08137A1A
	adds	r6, #0x52                             @ 08137A1C
	adds	r5, r4, #0                            @ 08137A1E
	adds	r5, #0x46                             @ 08137A20
	cmp	r0, #0xa                               @ 08137A22
	bls	.L08137A28                             @ 08137A24
	b	.L08137BB6                               @ 08137A26
.L08137A28:
	lsls	r0, r0, #2                            @ 08137A28
	ldr	r1, .Llit08137A34                      @ 08137A2A  =0x08137A38
	adds	r0, r0, r1                            @ 08137A2C
	ldr	r0, [r0]                               @ 08137A2E
	mov	pc, r0                                 @ 08137A30  switch (CH_tickFx)
	.hword	0x0000                              @ 08137A32  (padding)
.Llit08137A34:
	.word	0x08137A38                           @ 08137A34
.Llit08137A38:
	.word	.L08137A64                           @ 08137A38
.Llit08137A3C:
	.word	.L08137B10                           @ 08137A3C
.Llit08137A40:
	.word	.L08137B44                           @ 08137A40
.Llit08137A44:
	.word	.L08137B78                           @ 08137A44
.Llit08137A48:
	.word	.L08137B80                           @ 08137A48
.Llit08137A4C:
	.word	.L08137B88                           @ 08137A4C
.Llit08137A50:
	.word	.L08137B96                           @ 08137A50
.Llit08137A54:
	.word	.L08137BB6                           @ 08137A54
.Llit08137A58:
	.word	.L08137BB6                           @ 08137A58
.Llit08137A5C:
	.word	.L08137BB6                           @ 08137A5C
.Llit08137A60:
	.word	.L08137BA4                           @ 08137A60
.L08137A64:
	ldr	r0, .Llit08137AEC                      @ 08137A64  =gmpPlayer
	mov	ip, r0                                 @ 08137A66
	ldr	r3, [r0]                               @ 08137A68
	movs	r1, #0x3a                             @ 08137A6A
	ldrsh	r2, [r3, r1]                         @ 08137A6C  PL_arpTick
	adds	r7, r4, #0                            @ 08137A6E
	adds	r7, #0x50                             @ 08137A70
	adds	r6, r4, #0                            @ 08137A72
	adds	r6, #0x52                             @ 08137A74
	adds	r5, r4, #0                            @ 08137A76
	adds	r5, #0x46                             @ 08137A78
	cmp	r2, #0                                 @ 08137A7A
	bne	.L08137A80                             @ 08137A7C
	b	.L08137BB6                               @ 08137A7E
.L08137A80:
	ldrh	r1, [r7]                              @ 08137A80
	ldrh	r0, [r6]                              @ 08137A82
	cmn	r1, r0                                 @ 08137A84
	bne	.L08137A8A                             @ 08137A86
	b	.L08137BB6                               @ 08137A88
.L08137A8A:
	cmp	r2, #4                                 @ 08137A8A
	bne	.L08137A92                             @ 08137A8C
	movs	r0, #1                                @ 08137A8E
	strh	r0, [r3, #0x3a]                       @ 08137A90
.L08137A92:
	mov	r2, ip                                 @ 08137A92
	ldr	r0, [r2]                               @ 08137A94
	ldr	r0, [r0, #4]                           @ 08137A96
	cmp	r0, #0                                 @ 08137A98
	beq	.L08137AF8                             @ 08137A9A
	ldr	r2, .Llit08137AF0                      @ 08137A9C  =gmpState
	ldr	r1, [r2]                               @ 08137A9E
	adds	r0, r4, #0                            @ 08137AA0
	adds	r0, #0x44                             @ 08137AA2
	movs	r3, #0                                @ 08137AA4
	ldrsh	r0, [r0, r3]                         @ 08137AA6
	ldrh	r3, [r5]                              @ 08137AA8
	adds	r0, r0, r3                            @ 08137AAA
	ldr	r1, [r1, #0x2c]                        @ 08137AAC  ST_periods
	lsls	r0, r0, #1                            @ 08137AAE
	adds	r0, r0, r1                            @ 08137AB0
	adds	r1, r4, #0                            @ 08137AB2
	adds	r1, #0x5e                             @ 08137AB4
	movs	r3, #0                                @ 08137AB6
	ldrsh	r1, [r1, r3]                         @ 08137AB8
	ldrh	r0, [r0]                              @ 08137ABA
	adds	r1, r1, r0                            @ 08137ABC
	adds	r0, r4, #0                            @ 08137ABE
	adds	r0, #0x54                             @ 08137AC0
	movs	r3, #0                                @ 08137AC2
	ldrsh	r0, [r0, r3]                         @ 08137AC4
	adds	r1, r1, r0                            @ 08137AC6
	lsls	r1, r1, #1                            @ 08137AC8
	cmp	r1, #0                                 @ 08137ACA
	bne	.L08137AD0                             @ 08137ACC
	movs	r1, #1                                @ 08137ACE
.L08137AD0:
	ldr	r0, .Llit08137AF4                      @ 08137AD0  =0x006C3E1D  Amiga clock * 2 (7093789)
	str	r2, [sp]                               @ 08137AD2
	bl	swiDiv                                  @ 08137AD4
	str	r0, [r4, #8]                           @ 08137AD8
	lsls	r0, r0, #0xc                          @ 08137ADA
	ldr	r2, [sp]                               @ 08137ADC
	ldr	r1, [r2]                               @ 08137ADE
	ldr	r1, [r1, #0x48]                        @ 08137AE0
	bl	swiDiv                                  @ 08137AE2
	str	r0, [r4, #8]                           @ 08137AE6
	b	.L08137BB6                               @ 08137AE8
	.hword	0x0000                              @ 08137AEA  (padding)
.Llit08137AEC:
	.word	gmpPlayer                            @ 08137AEC
.Llit08137AF0:
	.word	gmpState                             @ 08137AF0
.Llit08137AF4:
	.word	0x006C3E1D                           @ 08137AF4
.L08137AF8:
	ldr	r0, .Llit08137B0C                      @ 08137AF8  =gmpState
	ldr	r1, [r0]                               @ 08137AFA
	ldrh	r0, [r5]                              @ 08137AFC
	ldr	r1, [r1, #0x28]                        @ 08137AFE  ST_stepTab
	lsls	r0, r0, #2                            @ 08137B00
	adds	r0, r0, r1                            @ 08137B02
	ldr	r0, [r0]                               @ 08137B04
	str	r0, [r4, #8]                           @ 08137B06
	b	.L08137BB6                               @ 08137B08
	.hword	0x0000                              @ 08137B0A  (padding)
.Llit08137B0C:
	.word	gmpState                             @ 08137B0C
.L08137B10:
	ldr	r0, .Llit08137B2C                      @ 08137B10  =gmpPlayer
	ldr	r1, [r0]                               @ 08137B12
	ldr	r0, [r1, #4]                           @ 08137B14  PL_amiga
	cmp	r0, #0                                 @ 08137B16
	beq	.L08137B30                             @ 08137B18
	adds	r1, r4, #0                            @ 08137B1A
	adds	r1, #0x5e                             @ 08137B1C
	adds	r0, r4, #0                            @ 08137B1E
	adds	r0, #0x62                             @ 08137B20
	ldrh	r0, [r0]                              @ 08137B22
	ldrh	r7, [r1]                              @ 08137B24
	adds	r0, r0, r7                            @ 08137B26
	strh	r0, [r1]                              @ 08137B28
	b	.L08137BAA                               @ 08137B2A
.Llit08137B2C:
	.word	gmpPlayer                            @ 08137B2C
.L08137B30:
	movs	r2, #0x38                             @ 08137B30
	ldrsh	r0, [r1, r2]                         @ 08137B32
	adds	r1, r4, #0                            @ 08137B34
	movs	r2, #0                                @ 08137B36
	bl	fxPortaUpLin                            @ 08137B38
	adds	r0, r4, #0                            @ 08137B3C
	bl	gmpUpdateLinearStep                     @ 08137B3E
	b	.L08137BAA                               @ 08137B42
.L08137B44:
	ldr	r0, .Llit08137B60                      @ 08137B44  =gmpPlayer
	ldr	r1, [r0]                               @ 08137B46
	ldr	r0, [r1, #4]                           @ 08137B48  PL_amiga
	cmp	r0, #0                                 @ 08137B4A
	beq	.L08137B64                             @ 08137B4C
	adds	r1, r4, #0                            @ 08137B4E
	adds	r1, #0x5e                             @ 08137B50
	adds	r0, r4, #0                            @ 08137B52
	adds	r0, #0x62                             @ 08137B54
	ldrh	r0, [r0]                              @ 08137B56
	ldrh	r3, [r1]                              @ 08137B58
	adds	r0, r0, r3                            @ 08137B5A
	strh	r0, [r1]                              @ 08137B5C
	b	.L08137BAA                               @ 08137B5E
.Llit08137B60:
	.word	gmpPlayer                            @ 08137B60
.L08137B64:
	movs	r7, #0x38                             @ 08137B64
	ldrsh	r0, [r1, r7]                         @ 08137B66
	adds	r1, r4, #0                            @ 08137B68
	movs	r2, #0                                @ 08137B6A
	bl	fxPortaDownLin                          @ 08137B6C
	adds	r0, r4, #0                            @ 08137B70
	bl	gmpUpdateLinearStep                     @ 08137B72
	b	.L08137BAA                               @ 08137B76
.L08137B78:
	adds	r0, r4, #0                            @ 08137B78
	bl	fxTonePorta                             @ 08137B7A
	b	.L08137BAA                               @ 08137B7E
.L08137B80:
	adds	r0, r4, #0                            @ 08137B80
	bl	fxVibrato                               @ 08137B82
	b	.L08137BAA                               @ 08137B86
.L08137B88:
	adds	r0, r4, #0                            @ 08137B88
	bl	fxTonePorta                             @ 08137B8A
	adds	r0, r4, #0                            @ 08137B8E
	bl	fxVolumeSlide                           @ 08137B90
	b	.L08137BAA                               @ 08137B94
.L08137B96:
	adds	r0, r4, #0                            @ 08137B96
	bl	fxVibrato                               @ 08137B98
	adds	r0, r4, #0                            @ 08137B9C
	bl	fxVolumeSlide                           @ 08137B9E
	b	.L08137BAA                               @ 08137BA2
.L08137BA4:
	adds	r0, r4, #0                            @ 08137BA4
	bl	fxVolumeSlide                           @ 08137BA6
.L08137BAA:
	adds	r7, r4, #0                            @ 08137BAA
	adds	r7, #0x50                             @ 08137BAC
	adds	r6, r4, #0                            @ 08137BAE
	adds	r6, #0x52                             @ 08137BB0
	adds	r5, r4, #0                            @ 08137BB2
	adds	r5, #0x46                             @ 08137BB4
.L08137BB6:
	ldrh	r5, [r5]                              @ 08137BB6
	mov	ip, r5                                 @ 08137BB8
	ldrh	r1, [r7]                              @ 08137BBA
	ldrh	r0, [r6]                              @ 08137BBC
	cmn	r1, r0                                 @ 08137BBE
	bne	.L08137C48                             @ 08137BC0
	ldr	r0, .Llit08137C2C                      @ 08137BC2  =gmpPlayer
	ldr	r0, [r0]                               @ 08137BC4
	ldr	r0, [r0, #4]                           @ 08137BC6  PL_amiga
	cmp	r0, #0                                 @ 08137BC8
	beq	.L08137C48                             @ 08137BCA
	adds	r0, r4, #0                            @ 08137BCC
	adds	r0, #0x5e                             @ 08137BCE
	movs	r2, #0                                @ 08137BD0
	ldrsh	r1, [r0, r2]                         @ 08137BD2
	adds	r2, r4, #0                            @ 08137BD4
	adds	r2, #0x44                             @ 08137BD6
	adds	r5, r0, #0                            @ 08137BD8
	adds	r3, r4, #0                            @ 08137BDA
	adds	r3, #0x54                             @ 08137BDC
	cmp	r1, #0                                 @ 08137BDE
	bne	.L08137BF2                             @ 08137BE0
	movs	r7, #0                                @ 08137BE2
	ldrsh	r0, [r3, r7]                         @ 08137BE4
	cmp	r0, #0                                 @ 08137BE6
	bne	.L08137BF2                             @ 08137BE8
	movs	r1, #0                                @ 08137BEA
	ldrsh	r0, [r2, r1]                         @ 08137BEC
	cmp	r0, #0                                 @ 08137BEE
	beq	.L08137C38                             @ 08137BF0
.L08137BF2:
	ldr	r6, .Llit08137C30                      @ 08137BF2  =gmpState
	ldr	r1, [r6]                               @ 08137BF4
	movs	r7, #0                                @ 08137BF6
	ldrsh	r0, [r2, r7]                         @ 08137BF8
	add	r0, ip                                 @ 08137BFA
	ldr	r1, [r1, #0x2c]                        @ 08137BFC  ST_periods
	lsls	r0, r0, #1                            @ 08137BFE
	adds	r0, r0, r1                            @ 08137C00
	movs	r2, #0                                @ 08137C02
	ldrsh	r1, [r5, r2]                         @ 08137C04
	ldrh	r0, [r0]                              @ 08137C06
	adds	r1, r1, r0                            @ 08137C08
	movs	r7, #0                                @ 08137C0A
	ldrsh	r0, [r3, r7]                         @ 08137C0C
	adds	r1, r1, r0                            @ 08137C0E
	lsls	r1, r1, #1                            @ 08137C10
	cmp	r1, #0                                 @ 08137C12
	bne	.L08137C18                             @ 08137C14
	movs	r1, #1                                @ 08137C16
.L08137C18:
	ldr	r0, .Llit08137C34                      @ 08137C18  =0x006C3E1D
	bl	swiDiv                                  @ 08137C1A
	str	r0, [r4, #8]                           @ 08137C1E
	lsls	r0, r0, #0xc                          @ 08137C20
	ldr	r1, [r6]                               @ 08137C22
	ldr	r1, [r1, #0x48]                        @ 08137C24
	bl	swiDiv                                  @ 08137C26
	b	.L08137C46                               @ 08137C2A
.Llit08137C2C:
	.word	gmpPlayer                            @ 08137C2C
.Llit08137C30:
	.word	gmpState                             @ 08137C30
.Llit08137C34:
	.word	0x006C3E1D                           @ 08137C34
.L08137C38:
	ldr	r0, .Llit08137C80                      @ 08137C38  =gmpState
	ldr	r0, [r0]                               @ 08137C3A
	ldr	r1, [r0, #0x28]                        @ 08137C3C  ST_stepTab
	mov	r2, ip                                 @ 08137C3E
	lsls	r0, r2, #2                            @ 08137C40
	adds	r0, r0, r1                            @ 08137C42
	ldr	r0, [r0]                               @ 08137C44
.L08137C46:
	str	r0, [r4, #8]                           @ 08137C46
.L08137C48:
	adds	r0, r4, #0                            @ 08137C48
	bl	fxVolumeColumn                          @ 08137C4A
	adds	r4, #0x98                             @ 08137C4E
	movs	r3, #1                                @ 08137C50
	add	r8, r3                                 @ 08137C52
	ldr	r0, .Llit08137C84                      @ 08137C54  =gmpPlayer
	ldr	r0, [r0]                               @ 08137C56
.L08137C58:
	ldr	r7, .Llit08137C88                      @ 08137C58  =0x00000B94
	adds	r0, r0, r7                            @ 08137C5A
	ldr	r0, [r0]                               @ 08137C5C
	cmp	r8, r0                                 @ 08137C5E
	bge	.L08137C64                             @ 08137C60
	b	.L08137A14                               @ 08137C62
.L08137C64:
	ldr	r0, .Llit08137C84                      @ 08137C64  =gmpPlayer
	ldr	r1, [r0]                               @ 08137C66
	ldrh	r0, [r1, #0x38]                       @ 08137C68  PL_tick
	adds	r0, #1                                @ 08137C6A
	strh	r0, [r1, #0x38]                       @ 08137C6C  PL_tick
	ldrh	r0, [r1, #0x3a]                       @ 08137C6E  PL_arpTick
	adds	r0, #1                                @ 08137C70
	strh	r0, [r1, #0x3a]                       @ 08137C72  PL_arpTick
.L08137C74:
	add	sp, #4                                 @ 08137C74
	pop	{r3}                                   @ 08137C76
	mov	r8, r3                                 @ 08137C78
	pop	{r4, r5, r6, r7}                       @ 08137C7A
	pop	{r0}                                   @ 08137C7C
	bx	r0                                      @ 08137C7E
.Llit08137C80:
	.word	gmpState                             @ 08137C80
.Llit08137C84:
	.word	gmpPlayer                            @ 08137C84
.Llit08137C88:
	.word	0x00000B94                           @ 08137C88
@ --------------------------------------------------------------------------
@ gmpGetBPM()  (0x08137C8C)  -- unused
@   return PL_bpm
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpGetBPM
gmpGetBPM:
	ldr	r0, .Llit08137C94                      @ 08137C8C  =gmpPlayer
	ldr	r0, [r0]                               @ 08137C8E
	ldr	r0, [r0, #0x3c]                        @ 08137C90  PL_bpm
	bx	lr                                      @ 08137C92
.Llit08137C94:
	.word	gmpPlayer                            @ 08137C94
@ --------------------------------------------------------------------------
@ gmpSetBPM(bpm)  (0x08137C98)  -- unused
@   PL_tempoLock = 1 (Fxx is ignored from now on); if (bpm >= 32) { PL_bpm = bpm; recompute
@   PL_tickHz and PL_rowLen }   PL_tickLen is not recomputed.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpSetBPM
gmpSetBPM:
	push	{r4, lr}                              @ 08137C98
	adds	r1, r0, #0                            @ 08137C9A
	ldr	r4, .Llit08137CD8                      @ 08137C9C  =gmpPlayer
	ldr	r2, [r4]                               @ 08137C9E
	movs	r0, #1                                @ 08137CA0
	strh	r0, [r2, #0x18]                       @ 08137CA2  PL_tempoLock
	cmp	r1, #0x1f                              @ 08137CA4
	ble	.L08137CD0                             @ 08137CA6
	str	r1, [r2, #0x3c]                        @ 08137CA8  PL_bpm
	movs	r0, #0x32                             @ 08137CAA
	muls	r0, r1, r0                            @ 08137CAC
	lsls	r0, r0, #0x10                         @ 08137CAE
	movs	r1, #0x7d                             @ 08137CB0
	bl	swiDiv                                  @ 08137CB2
	adds	r1, r0, #0                            @ 08137CB6
	ldr	r2, [r4]                               @ 08137CB8
	asrs	r1, r1, #0x10                         @ 08137CBA
	str	r1, [r2, #0x1c]                        @ 08137CBC  PL_tickHz
	ldr	r0, .Llit08137CDC                      @ 08137CBE  =gmpState
	ldr	r0, [r0]                               @ 08137CC0
	ldr	r2, [r2, #0x14]                        @ 08137CC2  PL_speed
	ldr	r0, [r0, #0x48]                        @ 08137CC4  ST_rateHz
	muls	r0, r2, r0                            @ 08137CC6
	bl	swiDiv                                  @ 08137CC8
	ldr	r1, [r4]                               @ 08137CCC
	str	r0, [r1, #0x24]                        @ 08137CCE  PL_rowLen
.L08137CD0:
	pop	{r4}                                   @ 08137CD0
	pop	{r0}                                   @ 08137CD2
	bx	r0                                      @ 08137CD4
	.hword	0x0000                              @ 08137CD6  (padding)
.Llit08137CD8:
	.word	gmpPlayer                            @ 08137CD8
.Llit08137CDC:
	.word	gmpState                             @ 08137CDC
@ --------------------------------------------------------------------------
@ gmpRowEffects(cell, ch)  (0x08137CE0)
@   note = cell[0] | cell[1] << 8 (9 bits, 0x1FF = none); ins = cell[2]; CH_volCol = cell[3];
@   cmd = cell[4]; par = cell[5]
@   3xx: the note becomes the porta target, no retrigger; instrument only reloads the volume
@   CH_tickFx = -1; CH_vibOfs = 0
@   note present: if (ins) { CH_ins = ins-1; CH_vol = header.volume }
@      sample fields from ST_smpHeaders[CH_ins] and ST_smpPtr[CH_ins]; CH_pos = 0; CH_note = note
@      Amiga: step from the period table (or ST_stepTab[note]); linear: gmpNoteToLinear
@      clear CH_portaOfs unless cmd == 3
@   no note, ins: CH_ptr = ST_smpPtr[ins-1], CH_vol = header.volume (sample swap, keeps position)
@   switch (cmd) {                                        (jump table at 0x08137F0C)
@    0 arpeggio: CH_arpX = x*8, CH_arpY = y*8           1/2 portamento   3 tone porta
@    4 vibrato    5/6/A: volume slide x up / y down      B jump to order (see gmpEndJingle)
@    C set volume D pattern break to row xx (hex, not BCD)  E only E6x pattern loop
@    F xx < 32: speed, else BPM (ignored while PL_tempoLock)   7, 8, 9: nothing }
@   fxVolumeColumn(ch)
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpRowEffects
gmpRowEffects:
	push	{r4, r5, r6, r7, lr}                  @ 08137CE0
	mov	r7, sl                                 @ 08137CE2
	mov	r6, sb                                 @ 08137CE4
	mov	r5, r8                                 @ 08137CE6
	push	{r5, r6, r7}                          @ 08137CE8
	adds	r5, r1, #0                            @ 08137CEA
	ldrb	r4, [r0, #2]                          @ 08137CEC
	ldrb	r2, [r0]                              @ 08137CEE
	ldrb	r1, [r0, #1]                          @ 08137CF0
	lsls	r1, r1, #8                            @ 08137CF2
	mov	ip, r1                                 @ 08137CF4
	orrs	r1, r2                                @ 08137CF6
	mov	ip, r1                                 @ 08137CF8
	ldr	r2, .Llit08137E54                      @ 08137CFA  =0x000001FF
	adds	r1, r2, #0                            @ 08137CFC
	mov	r3, ip                                 @ 08137CFE
	ands	r3, r1                                @ 08137D00
	mov	ip, r3                                 @ 08137D02
	ldrb	r7, [r0, #4]                          @ 08137D04
	mov	r8, r7                                 @ 08137D06
	ldrb	r6, [r0, #5]                          @ 08137D08
	adds	r1, r5, #0                            @ 08137D0A
	adds	r1, #0x8c                             @ 08137D0C
	ldrb	r0, [r0, #3]                          @ 08137D0E
	str	r0, [r1]                               @ 08137D10  CH_volCol
	movs	r0, #0xf                              @ 08137D12
	ands	r0, r7                                @ 08137D14
	cmp	r0, #3                                 @ 08137D16
	bne	.L08137D46                             @ 08137D18
	adds	r1, r2, #0                            @ 08137D1A
	cmp	ip, r1                                 @ 08137D1C
	beq	.L08137D26                             @ 08137D1E
	adds	r0, r5, #0                            @ 08137D20
	adds	r0, #0x64                             @ 08137D22
	strh	r3, [r0]                              @ 08137D24  CH_tpTarget
.L08137D26:
	mov	ip, r1                                 @ 08137D26
	cmp	r4, #0                                 @ 08137D28
	beq	.L08137D44                             @ 08137D2A
	ldr	r0, .Llit08137E58                      @ 08137D2C  =gmpState
	ldr	r0, [r0]                               @ 08137D2E
	ldr	r1, .Llit08137E5C                      @ 08137D30  =0x0000179C
	adds	r0, r0, r1                            @ 08137D32
	ldr	r1, [r0]                               @ 08137D34  ST_smpHeaders
	lsls	r0, r4, #1                            @ 08137D36
	adds	r0, r0, r4                            @ 08137D38
	lsls	r0, r0, #2                            @ 08137D3A
	adds	r0, r0, r1                            @ 08137D3C
	subs	r0, #0xc                              @ 08137D3E
	ldrh	r0, [r0, #4]                          @ 08137D40
	str	r0, [r5, #0x18]                        @ 08137D42
.L08137D44:
	movs	r4, #0                                @ 08137D44
.L08137D46:
	movs	r0, #1                                @ 08137D46
	rsbs	r0, r0, #0                            @ 08137D48
	str	r0, [r5, #0x48]                        @ 08137D4A
	adds	r0, r5, #0                            @ 08137D4C
	adds	r0, #0x54                             @ 08137D4E
	movs	r2, #0                                @ 08137D50
	mov	sb, r2                                 @ 08137D52
	mov	r3, sb                                 @ 08137D54
	strh	r3, [r0]                              @ 08137D56
	mov	sl, r0                                 @ 08137D58
	mov	r7, r8                                 @ 08137D5A
	ldr	r0, .Llit08137E54                      @ 08137D5C  =0x000001FF
	cmp	ip, r0                                 @ 08137D5E
	bne	.L08137D64                             @ 08137D60
	b	.L08137E9E                               @ 08137D62
.L08137D64:
	adds	r7, r5, #0                            @ 08137D64
	adds	r7, #0x40                             @ 08137D66
	cmp	r4, #0                                 @ 08137D68
	beq	.L08137D88                             @ 08137D6A
	subs	r4, #1                                @ 08137D6C
	strh	r4, [r7]                              @ 08137D6E
	ldr	r1, .Llit08137E58                      @ 08137D70  =gmpState
	ldr	r0, [r1]                               @ 08137D72
	ldrh	r1, [r7]                              @ 08137D74
	ldr	r2, .Llit08137E5C                      @ 08137D76  =0x0000179C
	adds	r0, r0, r2                            @ 08137D78
	ldr	r2, [r0]                               @ 08137D7A  ST_smpHeaders
	lsls	r0, r1, #1                            @ 08137D7C
	adds	r0, r0, r1                            @ 08137D7E
	lsls	r0, r0, #2                            @ 08137D80
	adds	r0, r0, r2                            @ 08137D82
	ldrh	r0, [r0, #4]                          @ 08137D84
	str	r0, [r5, #0x18]                        @ 08137D86
.L08137D88:
	ldr	r4, .Llit08137E58                      @ 08137D88  =gmpState
	ldr	r3, [r4]                               @ 08137D8A
	ldr	r0, .Llit08137E5C                      @ 08137D8C  =0x0000179C
	adds	r1, r3, r0                            @ 08137D8E
	ldrh	r2, [r7]                              @ 08137D90
	lsls	r0, r2, #1                            @ 08137D92
	adds	r0, r0, r2                            @ 08137D94
	lsls	r0, r0, #2                            @ 08137D96
	ldr	r1, [r1]                               @ 08137D98  ST_smpHeaders
	adds	r1, r1, r0                            @ 08137D9A
	lsls	r2, r2, #2                            @ 08137D9C
	movs	r7, #0xbd                             @ 08137D9E
	lsls	r7, r7, #5                            @ 08137DA0
	adds	r3, r3, r7                            @ 08137DA2
	adds	r3, r3, r2                            @ 08137DA4
	ldr	r0, [r3]                               @ 08137DA6
	str	r0, [r5]                               @ 08137DA8
	mov	r0, sb                                 @ 08137DAA
	str	r0, [r5, #0xc]                         @ 08137DAC
	str	r0, [r5, #0x14]                        @ 08137DAE
	ldrh	r0, [r1]                              @ 08137DB0
	cmp	r0, #0                                 @ 08137DB2
	beq	.L08137DBA                             @ 08137DB4
	lsls	r0, r0, #0xc                          @ 08137DB6
	str	r0, [r5, #0xc]                         @ 08137DB8
.L08137DBA:
	ldrh	r0, [r1, #6]                          @ 08137DBA
	str	r0, [r5, #0x10]                        @ 08137DBC
	ldrh	r0, [r1, #8]                          @ 08137DBE
	cmp	r0, #0                                 @ 08137DC0
	beq	.L08137DC8                             @ 08137DC2
	lsls	r0, r0, #0xc                          @ 08137DC4
	str	r0, [r5, #0x14]                        @ 08137DC6
.L08137DC8:
	ldrh	r0, [r1, #6]                          @ 08137DC8
	str	r0, [r5, #0x10]                        @ 08137DCA
	ldrh	r0, [r1, #2]                          @ 08137DCC
	adds	r2, r5, #0                            @ 08137DCE
	adds	r2, #0x44                             @ 08137DD0
	strh	r0, [r2]                              @ 08137DD2
	ldrh	r0, [r1, #0xa]                        @ 08137DD4
	strh	r0, [r5, #0x3c]                       @ 08137DD6
	adds	r0, r5, #0                            @ 08137DD8
	adds	r0, #0x46                             @ 08137DDA
	mov	r1, ip                                 @ 08137DDC
	strh	r1, [r0]                              @ 08137DDE
	mov	r3, sb                                 @ 08137DE0
	str	r3, [r5, #4]                           @ 08137DE2
	adds	r0, #0x36                             @ 08137DE4
	strh	r3, [r0]                              @ 08137DE6
	mov	r7, r8                                 @ 08137DE8
	cmp	r7, #3                                 @ 08137DEA
	beq	.L08137DF2                             @ 08137DEC
	adds	r0, #4                                @ 08137DEE
	str	r3, [r0]                               @ 08137DF0
.L08137DF2:
	adds	r0, r5, #0                            @ 08137DF2
	adds	r0, #0x84                             @ 08137DF4
	mov	r1, sb                                 @ 08137DF6
	str	r1, [r0]                               @ 08137DF8
	adds	r0, #4                                @ 08137DFA
	str	r1, [r0]                               @ 08137DFC
	mov	r3, sl                                 @ 08137DFE
	strh	r1, [r3]                              @ 08137E00
	ldr	r0, .Llit08137E60                      @ 08137E02  =gmpPlayer
	ldr	r0, [r0]                               @ 08137E04
	ldr	r0, [r0, #4]                           @ 08137E06  PL_amiga
	cmp	r0, #0                                 @ 08137E08
	beq	.L08137E80                             @ 08137E0A
	adds	r3, r5, #0                            @ 08137E0C
	adds	r3, #0x5e                             @ 08137E0E
	movs	r7, #0                                @ 08137E10
	ldrsh	r0, [r3, r7]                         @ 08137E12
	cmp	r0, #0                                 @ 08137E14
	bne	.L08137E20                             @ 08137E16
	movs	r1, #0                                @ 08137E18
	ldrsh	r0, [r2, r1]                         @ 08137E1A
	cmp	r0, #0                                 @ 08137E1C
	beq	.L08137E68                             @ 08137E1E
.L08137E20:
	ldr	r1, [r4]                               @ 08137E20
	movs	r7, #0                                @ 08137E22
	ldrsh	r0, [r2, r7]                         @ 08137E24
	add	r0, ip                                 @ 08137E26
	ldr	r1, [r1, #0x2c]                        @ 08137E28
	lsls	r0, r0, #1                            @ 08137E2A
	adds	r0, r0, r1                            @ 08137E2C
	movs	r2, #0                                @ 08137E2E
	ldrsh	r1, [r3, r2]                         @ 08137E30
	ldrh	r0, [r0]                              @ 08137E32
	adds	r1, r1, r0                            @ 08137E34
	lsls	r1, r1, #1                            @ 08137E36
	cmp	r1, #0                                 @ 08137E38
	bne	.L08137E3E                             @ 08137E3A
	movs	r1, #1                                @ 08137E3C
.L08137E3E:
	ldr	r0, .Llit08137E64                      @ 08137E3E  =0x006C3E1D
	bl	swiDiv                                  @ 08137E40
	str	r0, [r5, #8]                           @ 08137E44
	lsls	r0, r0, #0xc                          @ 08137E46
	ldr	r1, [r4]                               @ 08137E48
	ldr	r1, [r1, #0x48]                        @ 08137E4A
	bl	swiDiv                                  @ 08137E4C
	str	r0, [r5, #8]                           @ 08137E50
	b	.L08137E8E                               @ 08137E52
.Llit08137E54:
	.word	0x000001FF                           @ 08137E54
.Llit08137E58:
	.word	gmpState                             @ 08137E58
.Llit08137E5C:
	.word	0x0000179C                           @ 08137E5C
.Llit08137E60:
	.word	gmpPlayer                            @ 08137E60
.Llit08137E64:
	.word	0x006C3E1D                           @ 08137E64
.L08137E68:
	ldr	r3, .Llit08137E7C                      @ 08137E68  =gmpState
	ldr	r0, [r3]                               @ 08137E6A
	ldr	r1, [r0, #0x28]                        @ 08137E6C  ST_stepTab
	mov	r4, ip                                 @ 08137E6E
	lsls	r0, r4, #2                            @ 08137E70
	adds	r0, r0, r1                            @ 08137E72
	ldr	r0, [r0]                               @ 08137E74
	str	r0, [r5, #8]                           @ 08137E76
	b	.L08137E8E                               @ 08137E78
	.hword	0x0000                              @ 08137E7A  (padding)
.Llit08137E7C:
	.word	gmpState                             @ 08137E7C
.L08137E80:
	adds	r0, r5, #0                            @ 08137E80
	bl	gmpNoteToLinear                         @ 08137E82
	adds	r0, r5, #0                            @ 08137E86
	adds	r0, #0x94                             @ 08137E88
	mov	r7, sb                                 @ 08137E8A
	str	r7, [r0]                               @ 08137E8C
.L08137E8E:
	mov	r0, r8                                 @ 08137E8E
	cmp	r0, #3                                 @ 08137E90
	beq	.L08137EDA                             @ 08137E92
	adds	r1, r5, #0                            @ 08137E94
	adds	r1, #0x5e                             @ 08137E96
	movs	r0, #0                                @ 08137E98
	strh	r0, [r1]                              @ 08137E9A
	b	.L08137EDA                               @ 08137E9C
.L08137E9E:
	cmp	r4, #0                                 @ 08137E9E
	beq	.L08137EDA                             @ 08137EA0
	subs	r4, #1                                @ 08137EA2
	adds	r3, r5, #0                            @ 08137EA4
	adds	r3, #0x40                             @ 08137EA6
	strh	r4, [r3]                              @ 08137EA8
	ldr	r0, .Llit08137F00                      @ 08137EAA  =gmpState
	ldr	r2, [r0]                               @ 08137EAC
	ldrh	r1, [r3]                              @ 08137EAE
	lsls	r1, r1, #2                            @ 08137EB0
	movs	r4, #0xbd                             @ 08137EB2
	lsls	r4, r4, #5                            @ 08137EB4
	adds	r0, r2, r4                            @ 08137EB6
	adds	r0, r0, r1                            @ 08137EB8
	ldr	r0, [r0]                               @ 08137EBA
	str	r0, [r5]                               @ 08137EBC
	ldrh	r1, [r3]                              @ 08137EBE
	ldr	r7, .Llit08137F04                      @ 08137EC0  =0x0000179C
	adds	r2, r2, r7                            @ 08137EC2
	ldr	r2, [r2]                               @ 08137EC4  ST_smpHeaders
	lsls	r0, r1, #1                            @ 08137EC6
	adds	r0, r0, r1                            @ 08137EC8
	lsls	r0, r0, #2                            @ 08137ECA
	adds	r0, r0, r2                            @ 08137ECC
	ldrh	r0, [r0, #4]                          @ 08137ECE
	str	r0, [r5, #0x18]                        @ 08137ED0
	adds	r0, r5, #0                            @ 08137ED2
	adds	r0, #0x7c                             @ 08137ED4
	mov	r1, sb                                 @ 08137ED6
	strh	r1, [r0]                              @ 08137ED8
.L08137EDA:
	adds	r0, r5, #0                            @ 08137EDA
	adds	r0, #0x50                             @ 08137EDC
	movs	r1, #0                                @ 08137EDE
	strh	r1, [r0]                              @ 08137EE0
	adds	r2, r5, #0                            @ 08137EE2
	adds	r2, #0x52                             @ 08137EE4
	strh	r1, [r2]                              @ 08137EE6
	adds	r3, r0, #0                            @ 08137EE8
	adds	r4, r2, #0                            @ 08137EEA
	mov	r2, r8                                 @ 08137EEC
	cmp	r2, #0xf                               @ 08137EEE
	bls	.L08137EF4                             @ 08137EF0
	b	.L081381CE                               @ 08137EF2
.L08137EF4:
	lsls	r0, r2, #2                            @ 08137EF4
	ldr	r1, .Llit08137F08                      @ 08137EF6  =0x08137F0C
	adds	r0, r0, r1                            @ 08137EF8
	ldr	r0, [r0]                               @ 08137EFA
	mov	pc, r0                                 @ 08137EFC  switch (cmd)
	.hword	0x0000                              @ 08137EFE  (padding)
.Llit08137F00:
	.word	gmpState                             @ 08137F00
.Llit08137F04:
	.word	0x0000179C                           @ 08137F04
.Llit08137F08:
	.word	0x08137F0C                           @ 08137F08
.Llit08137F0C:
	.word	.L08137F4C                           @ 08137F0C
.Llit08137F10:
	.word	.L08137F60                           @ 08137F10
.Llit08137F14:
	.word	.L08137F84                           @ 08137F14
.Llit08137F18:
	.word	.L08137FB8                           @ 08137F18
.Llit08137F1C:
	.word	.L0813803E                           @ 08137F1C
.Llit08137F20:
	.word	.L08138070                           @ 08137F20
.Llit08137F24:
	.word	.L0813807C                           @ 08137F24
.Llit08137F28:
	.word	.L081381CE                           @ 08137F28
.Llit08137F2C:
	.word	.L081381CE                           @ 08137F2C
.Llit08137F30:
	.word	.L081381CE                           @ 08137F30
.Llit08137F34:
	.word	.L08138088                           @ 08137F34
.Llit08137F38:
	.word	.L0813809E                           @ 08137F38
.Llit08137F3C:
	.word	.L081380DA                           @ 08137F3C
.Llit08137F40:
	.word	.L081380DE                           @ 08137F40
.Llit08137F44:
	.word	.L0813810C                           @ 08137F44
.Llit08137F48:
	.word	.L08138178                           @ 08137F48
.L08137F4C:
	lsrs	r2, r6, #4                            @ 08137F4C
	movs	r0, #0xf                              @ 08137F4E
	ands	r6, r0                                @ 08137F50
	mov	r7, r8                                 @ 08137F52
	str	r7, [r5, #0x48]                        @ 08137F54
	lsls	r0, r2, #3                            @ 08137F56
	strh	r0, [r3]                              @ 08137F58  CH_arpX = x * 8
	lsls	r0, r6, #3                            @ 08137F5A
	strh	r0, [r4]                              @ 08137F5C  CH_arpY = y * 8
	b	.L081381CE                               @ 08137F5E
.L08137F60:
	adds	r2, r6, #0                            @ 08137F60
	mov	r0, r8                                 @ 08137F62
	str	r0, [r5, #0x48]                        @ 08137F64
	ldr	r0, .Llit08137F74                      @ 08137F66  =gmpPlayer
	ldr	r1, [r0]                               @ 08137F68
	ldr	r0, [r1, #4]                           @ 08137F6A  PL_amiga
	cmp	r0, #0                                 @ 08137F6C
	beq	.L08137F78                             @ 08137F6E
	rsbs	r0, r2, #0                            @ 08137F70
	b	.L08137FFA                               @ 08137F72
.Llit08137F74:
	.word	gmpPlayer                            @ 08137F74
.L08137F78:
	movs	r3, #0x38                             @ 08137F78
	ldrsh	r0, [r1, r3]                         @ 08137F7A
	adds	r1, r5, #0                            @ 08137F7C
	bl	fxPortaUpLin                            @ 08137F7E
	b	.L08137FAA                               @ 08137F82
.L08137F84:
	adds	r2, r6, #0                            @ 08137F84
	mov	r4, r8                                 @ 08137F86
	str	r4, [r5, #0x48]                        @ 08137F88
	ldr	r0, .Llit08137F9C                      @ 08137F8A  =gmpPlayer
	ldr	r1, [r0]                               @ 08137F8C
	ldr	r0, [r1, #4]                           @ 08137F8E  PL_amiga
	cmp	r0, #0                                 @ 08137F90
	beq	.L08137FA0                             @ 08137F92
	adds	r0, r5, #0                            @ 08137F94
	adds	r0, #0x62                             @ 08137F96
	strh	r2, [r0]                              @ 08137F98
	b	.L081381CE                               @ 08137F9A
.Llit08137F9C:
	.word	gmpPlayer                            @ 08137F9C
.L08137FA0:
	movs	r7, #0x38                             @ 08137FA0
	ldrsh	r0, [r1, r7]                         @ 08137FA2
	adds	r1, r5, #0                            @ 08137FA4
	bl	fxPortaDownLin                          @ 08137FA6
.L08137FAA:
	adds	r0, r5, #0                            @ 08137FAA
	bl	gmpUpdateLinearStep                     @ 08137FAC
	adds	r0, r5, #0                            @ 08137FB0
	bl	fxVolumeColumn                          @ 08137FB2
	b	.L081381D4                               @ 08137FB6
.L08137FB8:
	adds	r2, r6, #0                            @ 08137FB8
	mov	r0, r8                                 @ 08137FBA
	str	r0, [r5, #0x48]                        @ 08137FBC
	cmp	r2, #0                                 @ 08137FBE
	beq	.L08137FC8                             @ 08137FC0
	adds	r0, r5, #0                            @ 08137FC2
	adds	r0, #0x60                             @ 08137FC4
	strh	r2, [r0]                              @ 08137FC6
.L08137FC8:
	ldr	r0, .Llit08137FF0                      @ 08137FC8  =gmpPlayer
	ldr	r0, [r0]                               @ 08137FCA
	ldr	r0, [r0, #4]                           @ 08137FCC  PL_amiga
	cmp	r0, #0                                 @ 08137FCE
	beq	.L08138008                             @ 08137FD0
	adds	r0, r5, #0                            @ 08137FD2
	adds	r0, #0x64                             @ 08137FD4
	movs	r2, #0                                @ 08137FD6
	ldrsh	r1, [r0, r2]                         @ 08137FD8
	subs	r0, #0x1e                             @ 08137FDA
	ldrh	r0, [r0]                              @ 08137FDC
	cmp	r1, r0                                 @ 08137FDE
	beq	.L08138002                             @ 08137FE0
	cmp	r1, r0                                 @ 08137FE2
	ble	.L08137FF4                             @ 08137FE4
	adds	r0, r5, #0                            @ 08137FE6
	adds	r0, #0x60                             @ 08137FE8
	ldrh	r0, [r0]                              @ 08137FEA
	rsbs	r0, r0, #0                            @ 08137FEC
	b	.L08137FFA                               @ 08137FEE
.Llit08137FF0:
	.word	gmpPlayer                            @ 08137FF0
.L08137FF4:
	adds	r0, r5, #0                            @ 08137FF4
	adds	r0, #0x60                             @ 08137FF6
	ldrh	r0, [r0]                              @ 08137FF8
.L08137FFA:
	adds	r1, r5, #0                            @ 08137FFA
	adds	r1, #0x62                             @ 08137FFC
	strh	r0, [r1]                              @ 08137FFE
	b	.L081381CE                               @ 08138000
.L08138002:
	adds	r1, r5, #0                            @ 08138002
	adds	r1, #0x62                             @ 08138004
	b	.L0813806A                               @ 08138006
.L08138008:
	movs	r3, #0x3c                             @ 08138008
	ldrsh	r0, [r5, r3]                         @ 0813800A
	subs	r1, r0, #1                            @ 0813800C
	adds	r0, r5, #0                            @ 0813800E
	adds	r0, #0x64                             @ 08138010
	movs	r4, #0                                @ 08138012
	ldrsh	r0, [r0, r4]                         @ 08138014
	adds	r0, r1, r0                            @ 08138016
	subs	r0, #1                                @ 08138018
	adds	r2, r5, #0                            @ 0813801A
	adds	r2, #0x94                             @ 0813801C
	lsls	r0, r0, #0x10                         @ 0813801E
	lsrs	r0, r0, #0xa                          @ 08138020
	movs	r7, #0xee                             @ 08138022
	lsls	r7, r7, #5                            @ 08138024
	adds	r1, r7, #0                            @ 08138026
	subs	r1, r1, r0                            @ 08138028
	adds	r0, r5, #0                            @ 0813802A
	adds	r0, #0x44                             @ 0813802C
	ldrh	r0, [r0]                              @ 0813802E
	lsls	r0, r0, #0x10                         @ 08138030
	asrs	r0, r0, #0x11                         @ 08138032
	subs	r1, r1, r0                            @ 08138034
	lsls	r1, r1, #0x10                         @ 08138036
	lsrs	r1, r1, #0x10                         @ 08138038
	str	r1, [r2]                               @ 0813803A
	b	.L081381CE                               @ 0813803C
.L0813803E:
	lsrs	r2, r6, #4                            @ 0813803E
	movs	r1, #0xf                              @ 08138040
	ands	r1, r6                                @ 08138042
	mov	r0, r8                                 @ 08138044
	str	r0, [r5, #0x48]                        @ 08138046
	cmp	r2, #0                                 @ 08138048
	beq	.L08138052                             @ 0813804A
	adds	r0, r5, #0                            @ 0813804C
	adds	r0, #0x58                             @ 0813804E
	strh	r2, [r0]                              @ 08138050
.L08138052:
	cmp	r1, #0                                 @ 08138052
	beq	.L0813805C                             @ 08138054
	adds	r0, r5, #0                            @ 08138056
	adds	r0, #0x56                             @ 08138058
	strh	r1, [r0]                              @ 0813805A
.L0813805C:
	cmp	r2, #0                                 @ 0813805C
	bne	.L08138066                             @ 0813805E
	cmp	r1, #0                                 @ 08138060
	bne	.L08138066                             @ 08138062
	b	.L081381CE                               @ 08138064
.L08138066:
	adds	r1, r5, #0                            @ 08138066
	adds	r1, #0x5a                             @ 08138068
.L0813806A:
	movs	r0, #0                                @ 0813806A
	strh	r0, [r1]                              @ 0813806C
	b	.L081381CE                               @ 0813806E
.L08138070:
	lsrs	r2, r6, #4                            @ 08138070
	movs	r0, #0xf                              @ 08138072
	ands	r6, r0                                @ 08138074
	mov	r1, r8                                 @ 08138076
	str	r1, [r5, #0x48]                        @ 08138078
	b	.L08138092                               @ 0813807A
.L0813807C:
	lsrs	r2, r6, #4                            @ 0813807C
	movs	r0, #0xf                              @ 0813807E
	ands	r6, r0                                @ 08138080
	mov	r3, r8                                 @ 08138082
	str	r3, [r5, #0x48]                        @ 08138084
	b	.L08138092                               @ 08138086
.L08138088:
	lsrs	r2, r6, #4                            @ 08138088
	movs	r0, #0xf                              @ 0813808A
	ands	r6, r0                                @ 0813808C
	mov	r4, r8                                 @ 0813808E
	str	r4, [r5, #0x48]                        @ 08138090
.L08138092:
	adds	r0, r5, #0                            @ 08138092
	adds	r0, #0x4c                             @ 08138094
	strh	r2, [r0]                              @ 08138096
	adds	r0, #2                                @ 08138098
	strh	r6, [r0]                              @ 0813809A
	b	.L081381CE                               @ 0813809C
.L0813809E:
	ldr	r0, .Llit081380B4                      @ 0813809E  =gmpPlayer
	ldr	r1, [r0]                               @ 081380A0
	ldr	r0, [r1, #0xc]                         @ 081380A2  PL_skip
	cmp	r0, #0                                 @ 081380A4
	beq	.L081380B8                             @ 081380A6
	ldr	r0, [r1, #8]                           @ 081380A8  PL_rows
	str	r0, [r1, #0x40]                        @ 081380AA  PL_row
	movs	r0, #0                                @ 081380AC
	str	r0, [r1, #0xc]                         @ 081380AE  PL_skip
	b	.L081381CE                               @ 081380B0
	.hword	0x0000                              @ 081380B2  (padding)
.Llit081380B4:
	.word	gmpPlayer                            @ 081380B4
.L081380B8:
	ldr	r0, .Llit081380CC                      @ 081380B8  =gmpState
	ldr	r0, [r0]                               @ 081380BA
	adds	r0, #0x54                             @ 081380BC
	ldrb	r0, [r0]                              @ 081380BE  ST_jingleOn
	cmp	r0, #0                                 @ 081380C0
	beq	.L081380D0                             @ 081380C2
	bl	gmpEndJingle                            @ 081380C4
	b	.L081381CE                               @ 081380C8
	.hword	0x0000                              @ 081380CA  (padding)
.Llit081380CC:
	.word	gmpState                             @ 081380CC
.L081380D0:
	subs	r0, r6, #1                            @ 081380D0
	str	r0, [r1, #0x44]                        @ 081380D2  Bxx: PL_order = xx - 1, PL_row = PL_rows below
	ldr	r0, [r1, #8]                           @ 081380D4
	str	r0, [r1, #0x40]                        @ 081380D6
	b	.L081381CE                               @ 081380D8
.L081380DA:
	str	r6, [r5, #0x18]                        @ 081380DA
	b	.L081381CE                               @ 081380DC
.L081380DE:
	ldr	r4, .Llit08138108                      @ 081380DE  =gmpPlayer
	ldr	r2, [r4]                               @ 081380E0
	adds	r0, r2, #0                            @ 081380E2
	adds	r0, #0x4c                             @ 081380E4
	ldrb	r3, [r0]                              @ 081380E6  PL_jumped
	cmp	r3, #0                                 @ 081380E8
	bne	.L081381CE                             @ 081380EA
	str	r6, [r2, #0x40]                        @ 081380EC  Dxx: PL_row = xx
	ldr	r0, [r2, #0x44]                        @ 081380EE  PL_order
	adds	r0, #1                                @ 081380F0
	str	r0, [r2, #0x44]                        @ 081380F2  PL_order
	ldr	r1, [r2]                               @ 081380F4  PL_module
	ldr	r1, [r1, #0x34]                        @ 081380F6
	cmp	r0, r1                                 @ 081380F8
	blo	.L081380FE                             @ 081380FA
	str	r3, [r2, #0x44]                        @ 081380FC  PL_order
.L081380FE:
	ldr	r0, [r4]                               @ 081380FE
	adds	r0, #0x4c                             @ 08138100
	movs	r1, #1                                @ 08138102
	strb	r1, [r0]                              @ 08138104
	b	.L081381CE                               @ 08138106
.Llit08138108:
	.word	gmpPlayer                            @ 08138108
.L0813810C:
	movs	r0, #0xf0                             @ 0813810C
	ands	r0, r6                                @ 0813810E
	cmp	r0, #0x70                              @ 08138110
	beq	.L081381CE                             @ 08138112
	cmp	r0, #0x70                              @ 08138114
	bhi	.L081381CE                             @ 08138116
	cmp	r0, #0x30                              @ 08138118
	beq	.L081381CE                             @ 0813811A
	cmp	r0, #0x30                              @ 0813811C
	bls	.L081381CE                             @ 0813811E
	cmp	r0, #0x50                              @ 08138120
	beq	.L081381CE                             @ 08138122
	cmp	r0, #0x50                              @ 08138124
	bls	.L081381CE                             @ 08138126
	cmp	r0, #0x60                              @ 08138128
	bne	.L081381CE                             @ 0813812A
	movs	r0, #0xf                              @ 0813812C
	ands	r0, r6                                @ 0813812E
	cmp	r0, #0                                 @ 08138130
	bne	.L08138148                             @ 08138132
	ldr	r0, .Llit08138144                      @ 08138134  =gmpPlayer
	ldr	r0, [r0]                               @ 08138136
	ldr	r0, [r0, #0x40]                        @ 08138138  PL_row
	subs	r0, #1                                @ 0813813A
	adds	r1, r5, #0                            @ 0813813C
	adds	r1, #0x78                             @ 0813813E
	strh	r0, [r1]                              @ 08138140
	b	.L081381CE                               @ 08138142
.Llit08138144:
	.word	gmpPlayer                            @ 08138144
.L08138148:
	adds	r0, r5, #0                            @ 08138148
	adds	r0, #0x7a                             @ 0813814A
	ldrh	r2, [r0]                              @ 0813814C
	adds	r1, r0, #0                            @ 0813814E
	cmp	r2, #0                                 @ 08138150
	beq	.L0813815A                             @ 08138152
	subs	r0, r2, #1                            @ 08138154
	strh	r0, [r1]                              @ 08138156
	b	.L08138160                               @ 08138158
.L0813815A:
	movs	r0, #0xf                              @ 0813815A
	ands	r6, r0                                @ 0813815C
	strh	r6, [r1]                              @ 0813815E
.L08138160:
	ldrh	r0, [r1]                              @ 08138160
	cmp	r0, #0                                 @ 08138162
	beq	.L081381CE                             @ 08138164
	ldr	r0, .Llit08138174                      @ 08138166  =gmpPlayer
	ldr	r1, [r0]                               @ 08138168
	adds	r0, r5, #0                            @ 0813816A
	adds	r0, #0x78                             @ 0813816C
	ldrh	r0, [r0]                              @ 0813816E
	str	r0, [r1, #0x40]                        @ 08138170  PL_row
	b	.L081381CE                               @ 08138172
.Llit08138174:
	.word	gmpPlayer                            @ 08138174
.L08138178:
	ldr	r0, .Llit08138190                      @ 08138178  =gmpPlayer
	ldr	r3, [r0]                               @ 0813817A
	movs	r7, #0x18                             @ 0813817C
	ldrsh	r1, [r3, r7]                         @ 0813817E  PL_tempoLock
	adds	r7, r0, #0                            @ 08138180
	cmp	r1, #0                                 @ 08138182
	bne	.L081381CE                             @ 08138184
	adds	r0, r6, #0                            @ 08138186
	cmp	r0, #0x1f                              @ 08138188
	bgt	.L08138194                             @ 0813818A  xx < 32: speed
	str	r0, [r3, #0x14]                        @ 0813818C  PL_speed
	b	.L08138196                               @ 0813818E
.Llit08138190:
	.word	gmpPlayer                            @ 08138190
.L08138194:
	str	r0, [r3, #0x3c]                        @ 08138194  else BPM
.L08138196:
	ldr	r0, [r7]                               @ 08138196
	ldr	r1, [r0, #0x3c]                        @ 08138198
	movs	r0, #0x32                             @ 0813819A
	muls	r0, r1, r0                            @ 0813819C
	lsls	r0, r0, #0x10                         @ 0813819E
	movs	r1, #0x7d                             @ 081381A0
	bl	swiDiv                                  @ 081381A2
	adds	r1, r0, #0                            @ 081381A6
	ldr	r2, [r7]                               @ 081381A8
	asrs	r1, r1, #0x10                         @ 081381AA
	str	r1, [r2, #0x1c]                        @ 081381AC
	ldr	r4, .Llit081381E4                      @ 081381AE  =gmpState
	ldr	r0, [r4]                               @ 081381B0
	ldr	r2, [r2, #0x14]                        @ 081381B2
	ldr	r0, [r0, #0x48]                        @ 081381B4  ST_rateHz
	muls	r0, r2, r0                            @ 081381B6
	bl	swiDiv                                  @ 081381B8
	ldr	r1, [r7]                               @ 081381BC
	str	r0, [r1, #0x24]                        @ 081381BE
	ldr	r0, [r4]                               @ 081381C0
	ldr	r0, [r0, #0x48]                        @ 081381C2  ST_rateHz
	ldr	r1, [r1, #0x1c]                        @ 081381C4
	bl	swiDiv                                  @ 081381C6
	ldr	r1, [r7]                               @ 081381CA
	str	r0, [r1, #0x30]                        @ 081381CC
.L081381CE:
	adds	r0, r5, #0                            @ 081381CE
	bl	fxVolumeColumn                          @ 081381D0
.L081381D4:
	pop	{r3, r4, r5}                           @ 081381D4
	mov	r8, r3                                 @ 081381D6
	mov	sb, r4                                 @ 081381D8
	mov	sl, r5                                 @ 081381DA
	pop	{r4, r5, r6, r7}                       @ 081381DC
	pop	{r0}                                   @ 081381DE
	bx	r0                                      @ 081381E0
	.hword	0x0000                              @ 081381E2  (padding)
.Llit081381E4:
	.word	gmpState                             @ 081381E4
@ --------------------------------------------------------------------------
@ gmpDeadTempoLoop()  (0x081381E8)  -- unreachable
@   Recomputes PL_tickHz and PL_rowLen in an endless loop.  Nothing calls it; it looks like the
@   body of a tempo function whose loop exit was lost.
@ --------------------------------------------------------------------------
	.thumb_func
	.global gmpDeadTempoLoop
gmpDeadTempoLoop:
	push	{r4, lr}                              @ 081381E8
	ldr	r4, .Llit08138218                      @ 081381EA  =gmpPlayer
.L081381EC:
	ldr	r0, [r4]                               @ 081381EC
	ldr	r1, [r0, #0x3c]                        @ 081381EE
	movs	r0, #0x32                             @ 081381F0
	muls	r0, r1, r0                            @ 081381F2
	lsls	r0, r0, #0x10                         @ 081381F4
	movs	r1, #0x7d                             @ 081381F6
	bl	swiDiv                                  @ 081381F8
	adds	r1, r0, #0                            @ 081381FC
	ldr	r2, [r4]                               @ 081381FE
	asrs	r1, r1, #0x10                         @ 08138200
	str	r1, [r2, #0x1c]                        @ 08138202
	ldr	r0, .Llit0813821C                      @ 08138204  =gmpState
	ldr	r0, [r0]                               @ 08138206
	ldr	r2, [r2, #0x14]                        @ 08138208
	ldr	r0, [r0, #0x48]                        @ 0813820A  ST_rateHz
	muls	r0, r2, r0                            @ 0813820C
	bl	swiDiv                                  @ 0813820E
	ldr	r1, [r4]                               @ 08138212
	str	r0, [r1, #0x24]                        @ 08138214
	b	.L081381EC                               @ 08138216
.Llit08138218:
	.word	gmpPlayer                            @ 08138218
.Llit0813821C:
	.word	gmpState                             @ 0813821C
